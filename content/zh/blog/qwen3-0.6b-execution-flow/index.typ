#import "../index.typ": definition, example, note, template, tip
#import "../registry.typ": qwen3-0-6b-execution-flow
#import "@preview/tablem:0.3.0": three-line-table

#let post = qwen3-0-6b-execution-flow
#show: template.with(
  locale: "zh",
  route: post.route,
  title: post.title,
)

= #post.title

笔者最近在做一款基于 Tile 的 NPU（Tile-NPU），并为其设计了指令集#link("https://github.com/0x1B05/Tile-NPU-ISA")[Tile-NPU-ISA]和配套的功能模拟器#link("https://github.com/0x1B05/Tile-NPU-Sim")[Tile-NPU-Sim]。本文以 Qwen3-0.6B 为例，梳理它在 Tile-NPU 模拟器上的执行流程：从 guest 程序、模型权重与运行时 prompt 镜像的加载开始，沿着一次前向推理经过的计算步骤，说明这些计算如何转化为具体的 NPU 指令上。(目前的算子为ai生成的汇编指令, 流程仅供参考)

== 宿主机准备模型与 prompt

模拟器运行 Qwen3 前，宿主机上需要先准备好*模型权重*, *tokenizer*, *prompt*.

=== 量化模型权重

对于模型权重, 我们从#link("https://huggingface.co/Qwen/Qwen3-0.6B")[HuggingFace]下载. 执行 `scripts/qwen3/convert.py`把 HuggingFace 格式的 Qwen3 权重，量化成q8s32格式的blob(Binary Large OBject), 以适应Tile-NPU模拟器.

#definition(title: "q8s32 格式")[
  *q8s32* 指按输出行对称量化的 int8 权重(`q8`)，加上每行一个 32 位 scale(`s32`)。
  量化时取该行绝对值最大值 $"amax"$，令 $s = "amax" / 127$，再将 $w / s$ 按最近偶数舍入并饱和到 $[-127, 127]$。反量化时 $w approx w^q times s$；矩阵乘中 int8 点积累加为 i32，最后再乘回 activation scale 和该行的 weight scale。
]

`convert.py`会读取模型配置, 然后读取 BF16 权重, 并将其转换为q8s32格式:

```sh
python3 scripts/qwen3/convert.py real external/qwen3 model.q3b
```

`convert.py` 会把量化矩阵重排成 32×32 tile：$(d_"out"/32, d_"in"/32, 32, 32)$，每个 tile 内按 $(d_"out", d_"in")$ 存放。这样 `tload` 一次取 1 KiB tile，`bdot.nt` / `mma.nt` 直接消费，不需要在转换阶段预先转置。

#example(title: "线性层权重离线量化")[
  - Input: `W`，shape `(out_dim, in_dim)`，dtype `bf16`
  - Output:
    - `W_q`：shape `(out_dim, in_dim)`，dtype `int8`
    - `W_scale`：shape `(out_dim,)`，dtype `f32`

  每一行独立做对称 int8 量化： $ W_"scale"[j] = (max_c abs(W[j, c])) / 127, quad W_q[j, c] = "sat_rne"(W[j, c] / W_"scale"[j]) $
  反量化时：$ W[j, c] approx W_q[j, c] times W_"scale"[j] $

  #definition(title: "sat_rne")[
    $
      "sat_rne"(x) = cases(
        0 & x " is NaN",
        min(max("RNE"(x), -127), 127) & "otherwise",
      )
    $
    其中 $"RNE"(x)$ 表示最近偶数舍入。
  ]
]

接着，转换脚本根据模型参数中的 `max_pos`、`head_dim` 和 `rope_theta` 预计算 RoPE 表 `rope_cos`以及 `rope_sin`, 形状为 `(max_pos, head_dim / 2)`, 数据类型为`f32`.

=== 打包prompt镜像

prompt 由 tokenizer 转成 token id 后，单独打包成一个 Q3P 运行时镜像：

- header：魔数 `Q3P`、`n_prompt`、两个保留字（必须为 0）
- `tokens`：`n_prompt` 个 u32 token id

`scripts/qwen3/tokenize_prompt.py` 负责生成这个镜像：

```sh
python3 scripts/qwen3/tokenize_prompt.py "你好" --out build/apps/prompt.bin
```

它随后被加载到 guest 的固定地址 `0x80F00000`。

最终得到的 `Q3B` 模型 blob 包含：

- header：魔数 `Q3B`、模型维度、`max_pos`、`eps`、section 数量和 `layout`（1 表示 32×32 tiled 权重）
- section directory：每个 section 的名称、偏移和大小
- `rope_cos` / `rope_sin`：RoPE 表
- `embed` 和 `embed_s`：token embedding 的 `int8` 权重和 `f32` 行 scale
- 每层的 `qw` / `kw` / `vw` / `ow`，以及对应的 `qws` / `kws` / `vws` / `ows`：Q/K/V/O 投影的 `int8` 权重和 `f32` 行 scale
- 每层的 `inln` / `ptln` / `qn` / `kn`：RMSNorm 参数，`f32`
- 每层的 `gw` / `uw` / `dw`，以及对应的 `gws` / `uws` / `dws`：MLP 的 `int8` 权重和 `f32` 行 scale
- `fin_norm`：最终 RMSNorm 参数，`f32`

== 交叉编译

Qwen3 guest 由 `xmake build qwen3_app` 构建。`apps/qwen3/xmake.lua` 调用交叉工具链，把 `apps/qwen3/*.c` 和 `apps/qwen3/*.S` 一次性编译、链接成 ELF：

```sh
riscv64-linux-gnu-gcc -march=rv64im -mabi=lp64 -O2 \
    -ffreestanding -nostdlib -static -no-pie \
    -I apps/qwen3/include -I tests/guest/include \
    -T apps/qwen3/link.ld -o build/apps/qwen3.elf \
    apps/qwen3/*.c apps/qwen3/*.S
```

实际参与链接的源文件是 `blob.c`、`console.c`、`forward.c`、`main.c`、`probe.c`、`q3p.c`、`crt0.S` 和 `kernels.S`。

`link.ld` 把入口固定在 `0x80000000`，并让 `crt0.S` 的 `.text.crt0` 排在最前面：

```ld
. = 0x80000000;
.text : { *(.text.crt0) *(.text*) }
```

另外 `ASSERT(__bss_end <= 0x80F00000, ...)` 保证 guest 镜像不会覆盖固定在 `0x80F00000` 的 prompt 镜像。

`crt0.S` 负责清零 `.bss`、把栈顶设为 `0xC0000000`、调用 `main()`，最后用 `ebreak` 停机。

=== 从宏到机器码

C 代码只会被编译成 RV64IM 指令；NPU 指令主要由 `kernels.S` 通过 `npu.inc` 里的宏生成。

#example(title: "TADD 5, 6, 7为例")[
  `npu.inc`中定义宏`EBIN`以及`TADD`
  ```asm
  .macro E_BIN sel3, funct4, dest, src1, src2
      .word ((\sel3 << 25) | (\funct4 << 21) | (\src2 << 12) | (\src1 << 7) | (\dest << 2))
  .endm

  .macro TADD dest, src1, src2
      E_BIN 0, 0, \dest, \src1, \src2
  .endm
  ```

  `TADD 5, 6, 7`汇编器会依次展开成：

  ```asm
  TADD 5, 6, 7
  # => E_BIN 0, 0, 5, 6, 7
  # => .word ((0 << 25) | (0 << 21) | (7 << 12) | (6 << 7) | (5 << 2))
  # => .word 0x00007314
  ```

  GNU as 会在当前 section 写入对应的 4 个字节（小端 `14 73 00 00`）。用 `objdump` 看，它会显示成 `.word`：

  ```text
  0000000000000000 <test_tadd>:
     0:   00007314    .word   0x00007314
     ...
  ```
]

`kernels.S` 的扩展名是大写 `.S`，GCC 因此按 `assembler-with-cpp` 处理：先做 C 预处理，再交给汇编器。若写成小写 `.s`，GCC 会直接调用汇编器，`#include`/`#define` 不会被展开（可用 `-x assembler-with-cpp` 显式指定）。`#include "dims.h"` 由预处理器处理，`.include "npu.inc"` 和 `.macro` 和 `.word` 由 GNU as 处理。内部大致相当于：

```sh
cc1 -E -lang-asm ... kernels.S -o kernels.s
riscv64-linux-gnu-as ... kernels.s -o kernels.o
```

=== 编译、链接与 objcopy

目前qwen3算子的汇编已经被编译成目标文件，再调用 `riscv64-linux-gnu-ld` 按 `link.ld` 链接成 `qwen3.elf`。C 和汇编之间仍可复用 RISC-V ABI。

#example(title: "qwen3_quant_act(x, k)")[
  `x` 和 `k` 分别放在 `a0`、`a1`，返回的 scale bits 放在 `a0`，调用是一条普通的 `call`；进入 `kernels.S` 后，指令流里开始出现 NPU 编码，NPU 指令使用自己的 tile/acc/vector 寄存器，指针和长度等标量参数仍通过 `x` 寄存器传递，执行完 `ret` 回到 C 代码。
]

最后用 `objcopy` 把 ELF 转成 flat binary：

```sh
riscv64-linux-gnu-objcopy -O binary build/apps/qwen3.elf build/apps/qwen3.bin
```

ELF 头、section table 和符号都会被去掉，只留下 loadable section 的内存镜像。

== 装载与内存映射

要在模拟器上运行一次推理, 需要把 guest 程序、模型 blob 和 prompt 镜像装进模拟器的 RAM(默认大小为1 GiB)。整个平台的地址布局定义在 `apps/qwen3/include/qwen3.h`, 如下表所示:

#figure(
  three-line-table([
    | 地址          | 用途                                      |
    | :------------ | :---------------------------------------- |
    | `0x80000000`  | `qwen3.bin`: guest 程序镜像（几 MiB）     |
    | `0x80F00000`  | `prompt.bin`: Q3P 运行时 prompt 镜像      |
    | `0x81000000`  | `model.q3b`: Q3B 模型 blob（约 598 MiB）  |
    | `0xB0000000`  | KV cache 区域（256 MiB）                  |
    | `0xC0000000`  | 栈顶                                      |
    | `0x10000000`  | 串口 MMIO                                 |
  ]),
  caption: [Qwen3 guest 的内存映射],
)

```sh
./build/linux/x86_64/release/sim_run \
    build/apps/qwen3/qwen3.bin \
    build/apps/qwen3/model.q3b@0x81000000 \
    build/apps/qwen3/prompt.bin@0x80F00000
```

如果不想手动准备两个镜像，可以运行以下两个命令

```sh
xmake build qwen3_run
xmake run qwen3_run "你好"
```

它会自动 tokenize prompt、生成临时 Q3P 镜像，并按同样的地址布局调用 `sim_run`。

== guest 程序启动

装载完成后模拟器从 `0x80000000` 即 `_start` 处开始取指执行: `_start` 起栈、调用 `main()`；`main` 返回后 crt0 把返回值放进 `a0` 并执行 `ebreak`(模拟器以 `ebreak` 为停机约定，`a0 = 0` 即成功)

=== `main()`

1. *验 blob 与 prompt image*：分别读取 Q3B 和 Q3P header，检查 magic、prompt 长度和 token id 范围；
2. *`qwen3_init(n_prompt)`*：把运行时 prompt 长度交给模型状态（probe 会用到），然后打印 prompt token 序列；
3. *`qwen3_prefill(tokens, n_prompt)`*：prefill 的缓冲区和 MMA 一次最多处理 32 行，所以按 `PREFILL_CHUNK_ROWS = 32` 分块；每块内的每个 token 都完整跑 transformer 层并把 K/V 写入 cache。所有块结束后，取最后一个 token 的 hidden state，跑 `fin_norm` → lm-head → argmax，返回第一个新 token。
4. *decode 循环*：每轮 `qwen3_forward(next, pos, 1)` 产生下一个 token 并打印，最多 32 个、遇 EOS(`<|im_end|>` / `<|endoftext|>`) 或超 `max_pos` 停。

=== prefill 与 decode

Decode 和 prefill 计算的是同一组公式，但是一次处理的 token 数量（单 token vs 最多 32 token）。核心差异在于投影算子：从 Prefill 阶段的 GEMM（GEneral Matrix-Matrix multiplication），变成了 Decode 阶段的 GEMV（GEneral Matrix-Vector multiplication，相当于 Batch=1 的退化 GEMM）。

#figure(
  three-line-table([
    | kernel               | *decode*（逐 token）                                | *prefill*（最多 32 token 一块）       |
    | :------------------- | :-------------------------------------------------- | :------------------------------------ |
    | 一次投影的 token 数  | 1 个 token（$1 times d_"in"$）                      | 最多 32 个（$"rows" times d_"in"$）   |
    | 激活量化             | `qwen3_quant_act`（全激活一个 scale）               | `qwen3_quant_rows`（每行一个 scale）  |
    | 投影 kernel          | `qwen3_matvec_q`（*bdot*）                          | `qwen3_matmul_q`（*mma*）             |
    | 输出 logits          | `fin_norm` + `matvec_q` + `argmax`                  | 只计算最后一个token的输出logits       |
    | 其余 kernel          | rmsnorm / rope / attention / silu / add 都按行调用  | 同左，逐行循环                        |
  ]),
  caption: [decode vs. prefill],
)

- *decode*（逐 token）：投影用 `quant_act` + `matvec_q`（GEMV）；
- *prefill*（最多 32 token 一块）：投影用 `quant_rows` + `matmul_q`（GEMM）；attention 仍然逐 token——因为第 t 个 token 的 KV 长度是 base+t+1；rmsnorm/rope/silu/add 这些逐行向量算子也只是循环 32 次。最后一块结束后，只对最后一行跑 `fin_norm`、lm-head 和 argmax，返回第一个新 token。

#tip(title: "记号与内存顺序")[
  PyTorch 按行主序存储张量，本文沿用这套约定：权重 $bold(W) in RR^(d_"out" times d_"in")$ 的第 $j$ 行对应输出通道 $j$，激活按行向量处理。单个 token 的线性层写成

  $ bold(y) = bold(x) bold(W)^top, $

  其中 $bold(x) in RR^(1 times d_"in")$、$bold(y) in RR^(1 times d_"out")$。

  批量输入只需要扩展 $bold(x)$ 的最外层维度：prefill 的 $B$ 个 token 写成 $bold(X) in RR^(B times d_"in")$，每一行是一个 token，和 $X_(r,c)$ 的下标约定一致。若改用列向量写法 $bold(y) = bold(W) bold(x)$，batch 维就要放到最后（$tilde(bold(X)) in RR^(d_"in" times B)$），token 不再按行连续存放，和本文的布局不一致，所以不采用。

  公式中 $dot.o$ 表示逐元素乘，$sum_i$ 表示沿对应维度求和。
]

== 从 embedding 到 logits 的数据流

下面先用 f32 写出每一步的数学定义。实际 kernel 中，权重以 q8s32 存放，激活在进入投影前也会量化；公式按反量化后的等价形式书写，量化细节见 q8s32 小节和各算子的实现。Qwen3-0.6B 的维度是 $D = 1024$、$d_"head" = 128$、$H_q = 16$、$H_"kv" = 8$、$D_"ff" = 3072$、$V = 151936$，共 28 层。

公式里的主要记号：

#three-line-table([
  | 记号                           | 含义                                                                                                                        |
  | :----------------------------- | :-------------------------------------------------------------------------------------------------------------------------- |
  | $d_"out", d_"in"$              | 输出/输入维度（输出/输入通道数）                                                                                            |
  | $j, c$                         | 输出/输入通道，$0 <= j < d_"out"$，$0 <= c < d_"in"$                                                                        |
  | $B, r$                         | prefill 本次 chunk 的 token 行数与行下标，$B <= 32$，$0 <= r < B$                                                           |
  | $p, t$                         | 当前 token 位置与 attention key 位置，$0 <= t <= p$                                                                         |
  | $H_q, H_"kv"$                  | query / KV head 总数，Qwen3-0.6B 为 16 / 8                                                                                  |
  | $h, G, h_"kv"$                 | query head 编号、每个 KV head 的 query head 数、KV head 编号：#linebreak() $G = H_q / H_"kv" = 2$，$h_"kv" = floor(h / G)$  |
  | $W_(j,c), W^q_(j,c), s_(W,j)$  | 逻辑权重、量化后的 int8 权重、第 $j$ 个输出行的 weight scale                                                                |
  | $x_c, x^q_c, s_x$              | decode 的 f32 激活、int8 激活、激活 scale                                                                                   |
  | $X_(r,c), X^q_(r,c), s_(x,r)$  | prefill 的 f32 激活、int8 激活、逐 token 行的激活 scale                                                                     |
  | $id_p, bold(E)$                | 位置 $p$ 的 token id 与 embedding 表                                                                                        |
  | $bold(gamma)$                  | RMSNorm 的逐元素 gain（Qwen3 里的 norm weight）                                                                             |
])

#note[代码里 GEMM 的 `n` / `k` 对应本文的 $d_"out"$ / $d_"in"$（其它 kernel 的 `n` 仍表示向量长度）；`h` / `kvh` 对应 $h$ / $h_"kv"$；32 宽的 tile 在投影里仍沿用代码的 `nblock` / `kblock`，embedding 小节按 $V$ / $D$ 方向叫 V-block / D-block。]

=== 实现约定

1. *配置先行*：每条 NPU 指令的 dtype/shape 都来自配置寄存器。核函数开头先通过 `cfg.seti` / `cfg.setx` 写配置；`npu.inc` 里的 `LI_CWV` / `LI_CWM` 只是把配置字拼在标量侧的辅助宏。这是"一次配置、循环复用"的模式——循环体里只有计算和访存指令。
2. *描述符自增*：`vload v1` 的意思是"从 vm1.base 读 vc1.len 个元素到 v1，然后 base += 32×stride"。所以流式扫描（rmsnorm、softmax、加法和 epilogue）的循环体里没有任何地址运算，回绕时才 `cfg.setx ... CF_BASE` 重写 base。
3. *标量↔向量摆渡*：`vinsert`（把一个 x 值塞进 lane）、`vbroadcast`（单 lane 铺全向量）负责标量进向量；`vreduce` 把归约结果直接广播到整条 Vec32；向量出标量走内存通道——把结果 `vstore` 落内存（常用 len-1 的"单 lane 存储"配置只写一个字），经 `fence.mem` 后由 `lw` 读回。`vextract` 只保留为低频调试通道。均值、scale、概率这类"标量"都按这套约定流动。
4. *标量与NPU的访存fence*：模拟器按程序序执行所以 `fence.mem` 实现为 no-op，但微架构上 NPU store 对标量 load 的可见性由 `fence.mem` 建立, kernel 里每处"NPU 写、标量读"之间都需要`fence.mem`。

寄存器名按 ISA 手册约定：`tN` 是 Tile，`aN` 是 Acc，`bN` 是 Vec8，`vN` 是 Vec32，`xN` 是 Scalar。RV64IM 标量一律写 `xN`，需要 ABI 名时写在注释里（如 `x5 = t0`、`x10 = a0`、`x22 = s6`），避免和 Tile 的 `tN`、Acc 的 `aN` 混淆。

=== Embedding

给定位置 $p$ 的 token id $id_p$，嵌入表 $bold(E) in ZZ^(V times D)$ 和逐行 scale $bold(s)_"emb" in RR^V$：

$
  bold(x)_0 = s_"emb"[id_p] bold(E)[id_p], quad bold(x)_0 in RR^D.
$

==== 实现

嵌入表是 q8s32 存的。Qwen3-0.6B 的 $D = 1024$，一个 32×32 tile 正好装下一个 token 的 hidden。blob 里按 $(V/32, D/32, 32, 32)$ 排列：外层是 V-block，内层是 D-block，最后是一个 $32 times 32$ 的 tile。每个 tile 行对应 $V$、列对应 $D$，按行主序存放；tile 内的 $v_"inner"$ 是 token 行，$d_"inner"$ 是 hidden 列。对 token id $i$，$v_"block" = i/32$ 选 V-block、$v_"inner" = i mod 32$ 选 tile 内行，$d_"block"$ 选 D-block，每个 D-block 取该行里一段 32 字节的连续 hidden。

#example(title: "V = D = 64")[
  一共有 $2 times 2 = 4$ 个 tile，每个 tile 1 KiB：

  - tile 0：$v_"block" = 0, d_"block" = 0$
  - tile 1：$v_"block" = 0, d_"block" = 1$
  - tile 2：$v_"block" = 1, d_"block" = 0$
  - tile 3：$v_"block" = 1, d_"block" = 1$

  tile 内的元素满足：

  $
    "tile"[v_"inner", d_"inner"] = E[v_"block" dot 32 + v_"inner", d_"block" dot 32 + d_"inner"].
  $

  对 token id 37：

  - $37/32 = 1$，所以 $v_"block" = 1$；$37 mod 32 = 5$，所以 $v_"inner" = 5$
  - $d_"block" = 0$ 对应 tile 2 的第 5 行，取出 `hidden[0:32]`
  - $d_"block" = 1$ 对应 tile 3 的第 5 行，取出 `hidden[32:64]`
]

```asm
# dblocks = D/32
# vblock = id/32, vinner = id%32
# tm0: base = table + vblock*(dblocks*1024) + vinner*32
#      row_stride = 1024   # 下一个 dblock
#      col_stride = 1
#      flags = 0           # 不自动递增
# am0: base = out
#      row_stride = 128    # 32 个 f32
#      col_stride = 4
#      flags = 0           # 不自动递增
# tc0/ac0: rows = dblocks，cols = 32
# vc0: len = dblocks

lw                 x6, 0(x5)          # x6 ← embed_s[id]
vfillx             v0, x6             # v0 ← s_i

tload               t0                # t0 ← dblocks×32 i8，一个 token
tdequant.rows.f32   a0, t0, v0        # a0 ← f32(t0) × s_i
astore              a0                # 写出 dblocks×32 个 f32
```

`tload` 按照上面的`tm0`配置：第 $r$ 行、第 $j$ 列访问

$
  "addr"(r,j) &= "base" + r dot "row_stride" + j dot "col_stride" \
  &= ("table" + v_"block" dot d_"blocks" dot 1024 + v_"inner" dot 32) + r dot 1024 + j,
$

其中 $0 <= r < d_"blocks"$ 是 dblock 下标，$0 <= j < 32$ 是 hidden 列。因此读进来的 tile 满足

$
  "tile"[r,j] = E[v_"block" dot 32 + v_"inner", r dot 32 + j].
$

`tdequant.rows.f32` 完成 int8→f32 并乘 scale；`vc0` 的 `len` 配成 $d_"blocks"$，`vfillx` 把同一个 $s_i$ 铺到所有 lane。

`astore` 按上面的 `am0` 配置，一次把 $d_"blocks" times 32$ 个 f32 按行连续写成完整 hidden 向量：

$
  "out"[r dot 32 + j] = "f32"("tile"[r,j]) dot s_i.
$

=== RMSNorm

对 $bold(x) in RR^n$、gain $bold(gamma) in RR^n$ 和 $epsilon > 0$：

$
  "RMSNorm"(bold(x); bold(gamma)) = bold(x) / sqrt(1/n sum_(i=1)^n x_i^2 + epsilon) dot.o bold(gamma).
$

$bold(gamma)$ 是 RMSNorm 的可学习 gain：先把 $bold(x)$ 归一到单位 RMS，再逐元素乘回 $bold(gamma)$，让每个通道保留自己的缩放。Qwen3 里对应 `inln` / `ptln` / `qn` / `kn` / `fin_norm` 这些 `f32` 参数。

Qwen3 的 $epsilon = 10^(-6)$。它用在四处：每层 input RMSNorm、逐头 Q/K RMSNorm、post-attention RMSNorm、最终 RMSNorm；对应 $n = 1024$ 或 $128$。

==== 实现

实现分两遍：第一遍累加平方和，第二遍乘 `rsqrt` 和 $bold(gamma)$。

```asm
vfill          v0, 0           # v0 ← 0
# 第一遍：n/32 次
vload          v1              # v1 ← x 的下一块
vfmadd         v0, v1, v1, v0  # v0 ← v0 + v1 · v1
vreduce.sum    v2, v0          # v2 全 lane ← sum(v0)（归约直接广播）
vmulx          v2, v2, x15     # v2 ← v2 × (1/n)   (x15 = a5)
vaddx          v2, v2, x14     # v2 ← v2 + eps     (x14 = a4)
vrsqrt.approx  v2, v2          # v2 ← 1/√v2
# 第二遍：n/32 次
vload          v1              # v1 ← x（回绕重读）
vload          v3              # v3 ← γ
vmul           v3, v3, v2      # v3 ← γ · rsqrt
vmul           v1, v1, v3      # v1 ← x · (γ · rsqrt)
vcopy          v4, v1          # v4 ← v1
vstore         v4              # memory[vm4] ← v4
```

=== q8s32 量化

权重在宿主机上按输出行量化：

$
  s_(W,j) = (max_c abs(W_(j,c))) / 127, quad
  W^q_(j,c) = "sat_rne"(W_(j,c) / s_(W,j)).
$

逻辑上 $bold(W) in RR^(d_"out" times d_"in")$。

激活在NPU硬件上动态量化。

- decode 时一整条激活共用一个 scale：
  $
    s_x = (max_c abs(x_c)) / 127, quad
    x^q_c = "sat_rne"(x_c / s_x).
  $

- prefill 时按 token 行量化：
  $
    s_(x,r) = (max_c abs(X_(r,c))) / 127, quad
    X^q_(r,c) = "sat_rne"(X_(r,c) / s_(x,r)).
  $

反量化后的矩阵乘写成：

$
  y_j = s_x s_(W,j) sum_c x^q_c W^q_(j,c).
$

==== 实现：prefill 激活量化

prefill 的 `quant_rows` 按 token 行量化：先求每行 absmax 得到 scale，再逐块量化。

```asm
# pass 1：逐块折叠每行 absmax
aload                    a0          # a0 ← 32×32 f32 块
areduce.rows.absmax      v0, a0      # v0 ← 每行 absmax
vmax                     v0, v0, v1  # v0 ← max(v0, v1)（后续块）
vmulx                    v0, v0, x5  # v0 ← v0 × (1/127)
vstore                   v0          # memory[vm0] ← 32 个 scale

# pass 2：用逐行 scale 量化
aload                    a0          # a0 ← 32×32 f32 块
aquant.rows.scale.q8s32  t0, a0, v0  # t0 ← quant(a0) with v0
tstore                   t0          # memory[tm0] ← t0
```

==== 实现：decode 激活量化

decode 的激活量化把整条激活压成一个 scale，结果留在 Tile 寄存器，直接给下一步 int8 matvec 用。

这里把内存里的 $d_"in"$ 个 f32 激活元素按 1024 个一组切成若干*输入激活块*；量化时每个输入块先 `aload` 到 Acc，再写成 Tile 里的 int8 *量化块*。输入块和量化块都对应一个 $32 times 32$ tile。块数 $n_"blocks" = ceil(d_"in"/1024)$。

```asm
vfill                    v0, 0         # v0 ← 0
# 第一遍：n_blocks × 32 次
vload                    v1            # v1 ← 下一块 x
vabs                     v1, v1        # v1 ← |v1|
vmax                     v0, v0, v1    # v0 ← max(v0, v1)
vreduce.max              v30, v0       # v30[0] ← max(v0)     (vc30 配成 len-1)
vmulx                    v30, v30, x6  # v30[0] ← absmax × (1/127)   (x6 = t1)
vbroadcast               v2, v30[0]    # v2 ← broadcast(scale)
vstore                   v30           # 单 lane 落栈
fence.mem                              # NPU store 对标量可见的边界
lw                       x7, 0(sp)     # x7 (t2) ← scale 位模式（经内存回标量）
# 第二遍：逐个激活块（每块 32×32）
aload                    a0            # a0 ← 32×32 f32 激活块（am0 沿行自增）
aquant.rows.scale.q8s32  t2, a0, v2    # t2 ← quant(a0) with v2
```

`aquant.rows.scale.q8s32` 是 QNT 族外部 scale 行量化：Acc 源逐行用 vScale 的对应 lane 量化。这里 v2 全部 lane 相同（均匀 scale）。

=== Q/K/V 投影

$
  bold(h)_1 = "RMSNorm"(bold(x)_0; bold(gamma)_1), quad
  bold(q) = bold(W)_Q bold(h)_1, quad
  bold(k) = bold(W)_K bold(h)_1, quad
  bold(v) = bold(W)_V bold(h)_1,
$

其中 $bold(W)_Q in RR^(2048 times 1024)$，$bold(W)_K, bold(W)_V in RR^(1024 times 1024)$。$bold(q)$ 按头切成 16 个 $RR^128$，$bold(k), bold(v)$ 切成 8 个 $RR^128$。实现里这三条投影分别走上一节的 q8s32 形式。

==== 实现：decode 投影（matvec）

给定 int8 激活 $bold(x)^q in ZZ^(d_"in")$、int8 权重 $bold(W)^q in ZZ^(d_"out" times d_"in")$、激活 scale $s_x in RR$ 和逐行权重 scale $bold(s)_W in RR^(d_"out")$，输出 $bold(o) in RR^(d_"out")$：

$
  o_j = s_x s_(W,j) sum_(c=0)^(d_"in"-1) x^q_c W^q_(j,c), quad 0 <= j < d_"out".
$

`W` 的逻辑形状是 $d_"out" times d_"in"$，但 q8s32 blob 里按 32×32 tile 存成 $(d_"out"/32, d_"in"/32, 32, 32)$，每个 tile 内按 $(d_"out", d_"in")$ 存放。`bdot.nt` 会把 tile 的 $(d_"out", d_"in")$ 布局逻辑转置成 $(d_"in", d_"out")$ 来用，所以转换阶段不需要预先转置。

分两个阶段。

*阶段 A：i8 乘加*。每个激活块（最多 32 个 kblock）先把激活行抽到 b0..b31；对每个 nblock：

```asm
# 每个激活块：R = 0..31 对应一个 kblock；t3/t4 对应后续激活块
textract.row        bR, t2[R]          # bR ← t2[R, :]
# 对每个 nblock：
tload               t1                 # t1 ← W[nblock][kblock] (d_out, d_in)
bdot.nt.acc.i8.i32  v4, bR, t1         # v4 ← v4 + bR · t1^T
```

`bdot.nt.acc.i8.i32` 是 MMA_BDOT 族的“向量×tile 点积，NT 表示右 tile 按 $(d_"out", d_"in")$ 存放、乘法时按转置形式使用，ACC 累加”：一条 = 32 输出 × 32 $d_"in"$ = 1024 次 MAC。一个激活块最多 32 个 kblock，所以是 32×1024。跨激活块的部分和存在内存 `qwen3_accbuf` (i32)，下个激活块用 `vload v4` 续上；新激活块第一块用 `vfill v4, 0` 清。i32 累加是精确的——int8 乘积求和不会溢出也不舍入，数值误差只在量化那一步引入。

*阶段 B：epilogue*（每 32 个输出）：

```asm
vload         v4           # v4 ← 读回 i32 部分和
vcvt.i32.f32  v4, v4       # v4 ← f32(v4)
vload         v6           # v6 ← 32 个权重行 scale
vmul          v4, v4, v6   # v4 ← v4 × ws[j]
vmulx         v4, v4, x22  # v4 ← v4 × xs   (x22 = s6，激活 scale)
vcopy         v8, v4       # v8 ← v4
vstore        v8           # memory[vm8] ← v8
```

关键设计：反量化的两个 scale 推到最后才乘——i8 域里只做纯整数乘加，f32 域只做三次乘法，顺序固定，所以和参考实现逐位对齐。

==== 实现：prefill 投影（matmul）

`matmul_q`：给定 $bold(X)^q in ZZ^(B times d_"in")$、$bold(W)^q in ZZ^(d_"out" times d_"in")$、逐行激活 scale $bold(s)_x in RR^B$ 和权重 scale $bold(s)_W in RR^(d_"out")$，输出

$ o_(r,j) = s_(x,r) s_(W,j) sum_(c=0)^(d_"in"-1) X^q_(r,c) W^q_(j,c). $

`W` 同样按 32×32 tile 存成 $(d_"out"/32, d_"in"/32, 32, 32)$，tile 内按 $(d_"out", d_"in")$ 存放；`tload` 直接得到 `mma.nt` 需要的右操作数（`mma.nt` 按转置形式使用这个 tile）。

真矩阵乘按每 8 个 nblock 一组处理，`a0..a7` 分别保持 8 个输出块的累加器；同一个 `xq` tile 只加载一次，被这 8 个块复用：

```asm
vload               v30          # v30 ← xs（有效行）
# 对每组 8 个 nblock：
tload               t0           # t0 ← xq 的 (rows, kblock) tile
tload               t1           # t1 ← W[nblock][kblock] (d_out, d_in)
mma.nt.zero.i8.i32  a0, t0, t1   # a0 ← t0 · t1^T
mma.nt.zero.i8.i32  a1, t0, t1   # a1 ← t0 · t1^T
# …… a2..a7 同理
# 后续 kblock：
mma.nt.acc.i8.i32   a0, t0, t1   # a0 ← a0 + t0 · t1^T
mma.nt.acc.i8.i32   a1, t0, t1   # a1 ← a1 + t0 · t1^T
# …… a2..a7 同理
# epilogue（每个 G = 0..7）：
acvt.i32.f32        a8, a0       # a8 ← f32(a0)
amulv.bycol         a8, a8, v29  # a8 ← a8 × ws[j]
amulv.byrow         a8, a8, v30  # a8 ← a8 × xs[t]
astore              a8           # memory[am8] ← a8
```

`rows < 32` 或不足 8 个 nblock 时走单累加器路径：`a0` 累加，`a8` 做 epilogue，逻辑相同。`rows` 由 `quant_rows` / `matmul_q` 的调用方传入，短 prompt 只计算有效行。

prefill 的收尾只处理最后一块的最后一行：取该行 hidden，跑 `fin_norm` → `quant_act` → `matvec_q`（与嵌入表共享权重）→ `argmax`，返回第一个新 token。

=== QK-RMSNorm 与 RoPE

每个 query head $h$ 和 KV head $h_"kv"$ 先做 head-dim RMSNorm：

$
  bold(q)_h' = "RMSNorm"(bold(q)_h; bold(gamma)_q), quad
  bold(k)_(h_"kv")' = "RMSNorm"(bold(k)_(h_"kv"); bold(gamma)_k).
$

然后按位置 $p$ 做 rotate-half RoPE。把一头的向量分成两半 $bold(x)_"a", bold(x)_"b" in RR^(d_"head"/2)$，cos/sin 表行为 $bold(c)_p, bold(s)_p$：

$
  "RoPE"(bold(x), p)_"a" = bold(x)_"a" dot.o bold(c)_p - bold(x)_"b" dot.o bold(s)_p,
$

$
  "RoPE"(bold(x), p)_"b" = bold(x)_"b" dot.o bold(c)_p + bold(x)_"a" dot.o bold(s)_p.
$

作用到 Q/K 上就是 $bold(q)_h^"rope" = "RoPE"(bold(q)_h', p)$、$bold(k)_(h_"kv")^"rope" = "RoPE"(bold(k)_(h_"kv")', p)$。

==== 实现：RoPE

实现上是一个纯向量流水线：8 条流描述符（cos/sin/x1/x2 各两个 chunk，hd=128 时每半 2 个 32-lane chunk），8 条 `vmul` 加 `vsub` / `vadd` 组合，4 条 `vstore` 原地写回。

=== KV cache 与 attention

第 $p$ 个 token 的 K/V 追加到 cache：

$
  bold(K)_(h_"kv",p) = bold(k)_(h_"kv")^"rope", quad
  bold(V)_(h_"kv",p) = bold(v)_(h_"kv").
$

第 $h$ 个 query head 使用第 $h_"kv" = floor(h / G)$ 个 KV head；对 $t = 0, dots, p$：

$
  s_(h,t) = (bold(q)_h^"rope" dot bold(K)_(h_"kv",t)) / sqrt(d_"head"), quad
  alpha_(h,t) = "softmax"_t (s_(h,t)),
$

$
  bold(o)_h = sum_(t=0)^p alpha_(h,t) bold(V)_(h_"kv",t).
$

==== 实现：scores

给定 query $bold(q) in RR^(d_"head")$ 和 key 矩阵 $bold(K) in RR^(n_"key" times d_"head")$，第 $t$ 个 key 的分数是

$ s_t = sum_(d=1)^(d_"head") K_(t,d) q_d. $

这里不除 $sqrt(d_"head")$——这个 scale 折进 softmax。

q 的 4 个 32-lane chunk 先驻留 v8..v11（描述符不自增）；对每个 key t:

```asm
vfill        v16, 0             # v16 ← 0
# vm12.base = K_t 行首（自增流）
vload        v12                # v12 ← K_t 的下一块
vfmadd       v16, v12, v8, v16  # v16 ← v16 + v12 · v8（v9..v11 同理）
vreduce.sum  v17, v16           # v17[0] ← sum(v16)（vc17 配成 len-1）
vstore       v17                # 单 lane 写到 scores[t]（vm17 不自增）
```

==== 实现：softmax

给定分数向量 $bold(s) in RR^n$，先减去最大值再取指数：

$
  tilde(p)_t = exp((s_t - max_u s_u) / sqrt(d_"head")), quad r = 1 / (sum_t tilde(p)_t).
$

$tilde(p)_t$ 原地写回，$r$ 作为标量返回。技巧是把 $1/sqrt(d_"head")$ 换成乘 `scale_log2e = log2(e)/√hd`，这样 `exp(z) = 2^(z·log2e)` 能用 `vexp2.approx`：

```asm
vfillx        v0, x5       # v0 ← -inf
# 第一遍：vmax 扫描
vload         v1           # v1 ← scores 的下一块
vmax          v0, v0, v1   # v0 ← max(v0, v1)
vreduce.max   v0, v0       # v0 全 lane ← max(v0)
vfill         v2, 0        # v2 ← 0（Σ 累加器）
# 第二遍：exp + sum
vload         v1           # v1 ← scores（回绕重读）
vsub          v1, v1, v0   # v1 ← v1 − max（向量减广播值）
vmulx         v1, v1, x12  # v1 ← v1 × scale_log2e
vexp2.approx  v1, v1       # v1 ← 2^v1
vadd          v2, v2, v1   # v2 ← v2 + v1
vcopy         v3, v1       # v3 ← v1
vstore        v3           # memory[vm3] ← v3
# 收尾：vc4 配成 len-1
vreduce.sum   v4, v2       # v4[0] ← sum(v2)
vrcp.approx   v4, v4       # v4[0] ← 1/sum
vstore        v4           # *rcp_out ← rcp(sum)
fence.mem                  # scores 和 rcp 之后由标量代码读取
```

除法被推迟：这里不做逐元素除法，只算一个倒数，留给 pv 最后乘。`−inf` 经 `vsub` / `vmulx` / `vexp2.approx` 自然变 0，所以 padding key 不进 softmax。

==== 实现：PV

给定未归一化概率 $tilde(p)_t$、value 向量 $bold(V)_t in RR^(d_"head")$ 和 softmax 返回的 $r = 1 / (sum_t tilde(p)_t)$，输出

$ bold(o) = r sum_t tilde(p)_t bold(V)_t. $

除法折成末尾乘一次倒数。

```asm
# 4 个 f32 累加器 v16..v19（对应 hd 的 4 个 chunk）
vfill       v16, 0              # v16 ← 0
vfill       v17, 0              # v17 ← 0
vfill       v18, 0              # v18 ← 0
vfill       v19, 0              # v19 ← 0
# 对每个 key t：
lw          x5, 0(x28)          # x5 (t0) ← probs[t]（x28 = t3）
vinsert     v20[0], x5          # v20[0] ← t0
vbroadcast  v20, v20[0]         # v20 ← broadcast(p_t)
vload       v12                 # v12 ← V_t 的下一块
vfmadd      v16, v12, v20, v16  # v16 ← v12 · v20 + v16
# v17..v19 同理
vmulx       v16, v16, x16       # v16 ← v16 × rcp   (x16 = a6)
vstore      v16                 # memory[vm16] ← v16
```

attention 的三个核函数（scores/softmax/pv）加起来就是标准 flash 式两遍结构，只不过按这个 ISA 的原语（fmadd/reduce/exp2/rcp）表达。

=== O 投影与残差

$
  bold(a) = bold(W)_O "concat"(bold(o)_1, dots, bold(o)_(H_q)), quad
  bold(x)_1 = bold(x)_0 + bold(a),
$

其中 $bold(W)_O in RR^(1024 times 2048)$。

==== 实现：残差加法

给定长度为 $n$ 的向量 $bold(x), bold(y)$，残差：

$ bold(o) = bold(x) + bold(y). $

```asm
vload   v0          # v0 ← dst
vload   v1          # v1 ← src
vadd    v0, v0, v1  # v0 ← v0 + v1
vcopy   v2, v0      # v2 ← v0
vstore  v2          # memory[vm2] ← v2
```

三个自增描述符，循环 n/32 次，全算子里最简单的一个。

=== Post-LN、MLP 与残差

$
  bold(h)_2 = "RMSNorm"(bold(x)_1; bold(gamma)_2),
$

$
  bold(g)_"gate" = bold(W)_"gate" bold(h)_2, quad
  bold(u) = bold(W)_"up" bold(h)_2,
$

$
  bold(m) = "SiLU"(bold(g)_"gate") dot.o bold(u), quad
  bold(d) = bold(W)_"down" bold(m),
$

$
  bold(x)_2 = bold(x)_1 + bold(d).
$

其中 $bold(W)_"gate", bold(W)_"up" in RR^(3072 times 1024)$，$bold(W)_"down" in RR^(1024 times 3072)$，$"SiLU"(g) = g / (1 + e^(-g))$。这里的残差仍然复用上面的 `qwen3_add`。

==== 实现：SiLU·up

`qwen3_silu_mul` 用 `vexp2` + `vrcp` 实现 sigmoid，再乘 gate 和 up。

```asm
vmulx         v1, v0, x5  # v1 ← v0 × (-log2(e))   (x5 = t0)
vexp2.approx  v1, v1      # v1 ← 2^v1 = e^(-v0)
vaddx         v1, v1, x6  # v1 ← v1 + 1            (x6 = t1)
vrcp.approx   v1, v1      # v1 ← 1 / v1 = σ(v0)
vmul          v0, v0, v1  # v0 ← v0 × σ(v0)
vload         v1          # v1 ← up
vmul          v0, v0, v1  # v0 ← v0 × up
vcopy         v2, v0      # v2 ← v0
vstore        v2          # memory[vm2] ← v2
```

=== 最终 logits

28 层之后，做最终 RMSNorm、lm-head（与 embedding 共享权重）和 argmax：

$
  bold(z) = bold(W)_"embed" "RMSNorm"(bold(x)_2; bold(gamma)_"fin"), quad
  i^* = arg max_i z_i.
$

其中 $bold(z) in RR^151936$。

==== 实现：argmax

难点是"跨 chunk 的全局 argmax"。chunk 内用 `vreduce.argmax`（双 Vec32 目的：索引广播到 `vIdx`、值广播到 `vVal`)；跨 chunk 用向量比较 + 选择做锦标赛，第一块直接做种子，免掉哨兵分支：

```asm
# chunk 0 做种子：
vload          v1
vreduce.argmax v2, v0, v1   # v2 全 lane ← 块内 argmax (i32)，v0 全 lane ← 块内最大值
# 后续每块（x29 = t4 = 块基址）：
vload          v1
vreduce.argmax v3, v4, v1   # 候选：v3 ← 块内 argmax，v4 ← 块内最大值
vaddx          v3, v3, x29  # v3 ← 全局下标
vcmplt         v5, v0, v4   # v5 ← (best < candidate)（有序比较）
vcmpunord      v6, v4, v4   # v6 ← candidate 是 NaN
vcmpunord      v7, v0, v0   # v7 ← best 是 NaN
vnot           v7, v7
vand           v6, v6, v7   # NaN 候选胜过数值 best
vor            v5, v5, v6   # 更新掩码（已有 NaN best 时全 0：不败）
vselect        v0, v5, v4, v0  # v0 ← mask ? candidate : best
vselect        v2, v5, v3, v2  # v2 ← mask ? candidate 下标 : best 下标
# 收尾：vc5 配成 len-1
vbroadcast     v5, v2[0]
vstore         v5           # 单 lane 落栈
fence.mem
lw             x10, 0(sp)   # a0 ← 全局 argmax
```

这套锦标赛完整保留了手册的 argmax 规则：数值相等时 `vcmplt` 为假、保留较小下标；NaN 候选胜过数值 incumbent；已有 NaN 不被取代——和 numpy 取第一个 NaN 的行为一致。

== 指令族落点总表

#figure(
  three-line-table([
    | *计算*                                                  | *kernel*                    | *主要 NPU 指令族*                                                                           |
    | :------------------------------------------------------ | :-------------------------- | :------------------------------------------------------------------------------------------ |
    | RMSNorm / 残差 / softmax / SiLU                         | 向量逐元素                  | `vload`/`vstore`, `vadd`/`vsub`/`vmul`, `vfmadd`, `vexp2`/`vrsqrt`/`vrcp`, `vfill`/`fillx`  |
    | 归约 (sumsq/max/sum)                                    | 同上                        | `vreduce.*`（广播到 Vec32）, `areduce.absmax`                                               |
    | 激活量化                                                | `quant_act` / `quant_rows`  | `aload`, `aquant.rows` 外部 scale (QNT)                                                     |
    | decode 投影（$1 times d_"in" times W$）                 | `matvec_q`                  | `tload`, `extract.row`, `bdot.nt.acc`, `vcvt`, `vmul(x)`                                    |
    | prefill 投影（$32 times d_"in" times W$）               | `matmul_q`                  | `tload`, `mma.nt.zero/acc`, `acvt`, `amulv.byrow/col`, `astore`                             |
    | prefill 最后一行 logits                                 | `matvec_q` + `argmax`       | 与 decode 收尾相同的 `fin_norm` / `bdot` / `argmax` 路径                                    |
    | 嵌入查表                                                | `embed`                     | `tload`, `tdequant.rows` (QNT), `astore`                                                    |
    | 采样                                                    | `argmax`                    | `vreduce.argmax`（双 Vec32 目的）, `vcmplt`/`vcmpunord` + `vselect` 跨块锦标赛              |
    | NPU store → 标量 load 的可见性边界                      | 各 kernel 收尾              | `fence.mem`                                                                                 |
    | 全部 kernel 的前奏                                      | 配置                        | `cfg.seti`/`setx`/`setw`/`copy`                                                             |
    | KV 追加、prompt 镜像解析、EOS 判断、掩码补 $-infinity$  | —                           | 标量 RV64（刻意留标量侧的小工作量）                                                         |
  ]),
  caption: [计算步骤到 NPU 指令族的映射],
)

#note[一个贯穿全局的设计要点：kernel 之间靠*寄存器驻留约定*协作（`t2..t4` 激活 tile、`v30` 的激活 scale、`tm1` 的权重 tile 布局），配置寄存器与访存描述符的自增模式（`inc_mode` 沿行/沿列）让一条 `tload`/`vload` 就把"加载下一块"的地址推进自动化；标量侧只做维度计算和循环控制，读 NPU 写出的结果时一律隔一条 `fence.mem` —— 这正是 ISA 设计里"配置与访存描述符绑定、访存自增、完成边界显式化"在真实负载上的用法。]
