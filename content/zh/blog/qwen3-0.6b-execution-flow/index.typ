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

笔者最近在做一款基于 Tile 的 NPU（Tile-NPU），并为其设计了指令集#link("https://github.com/0x1B05/Tile-NPU-ISA")[Tile-NPU-ISA]和配套的功能模拟器#link("https://github.com/0x1B05/Tile-NPU-Sim")[Tile-NPU-Sim]。本文以 Qwen3-0.6B 为例，梳理它在 Tile-NPU 模拟器上的执行流程：从 guest 程序、模型权重与运行时 prompt 镜像的加载开始，沿着一次前向推理经过的计算步骤，说明这些计算如何转化为具体的 NPU 指令。(目前的算子为 AI 生成的汇编指令, 流程仅供参考)

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

`convert.py` 会把量化矩阵重排成 32×32 tile：$(d_"out"/32, d_"in"/32, 32, 32)$，每个 tile 内按 $(d_"out", d_"in")$ 存放。这样 `tload` 一次取 1 KiB tile，`vmma.nt` / `mma.nt` 直接按行消费。

```
W: d_out 行 × d_in 列

          kblock 0    kblock 1    kblock 2 ...
        ┌──────────┬──────────┬──────────┐
nblock 0│ tile(0,0)│ tile(0,1)│ tile(0,2)│  ← 32 行
        ├──────────┼──────────┼──────────┤
nblock 1│ tile(1,0)│ tile(1,1)│ tile(1,2)│  ← 32 行
        ├──────────┼──────────┼──────────┤
...     │          │          │          │
        └──────────┴──────────┴──────────┘
             ↑ 32 列
```

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

最终得到的 `Q3B` 模型 blob 包含：

- header：魔数 `Q3B`、模型维度、`max_pos`、`eps`、section 数量和 `layout`（1 表示 32×32 tiled 权重）
- section directory：每个 section 的名称、偏移和大小
- `rope_cos` / `rope_sin`：RoPE 表
- `embed` 和 `embed_s`：token embedding 的 `int8` 权重和 `f32` 行 scale
- 每层的 `qw` / `kw` / `vw` / `ow`，以及对应的 `qws` / `kws` / `vws` / `ows`：Q/K/V/O 投影的 `int8` 权重和 `f32` 行 scale
- 每层的 `inln` / `ptln` / `qn` / `kn`：RMSNorm 参数，`f32`
- 每层的 `gw` / `uw` / `dw`，以及对应的 `gws` / `uws` / `dws`：MLP 的 `int8` 权重和 `f32` 行 scale
- `fin_norm`：最终 RMSNorm 参数，`f32`

=== 打包prompt镜像

prompt 由 tokenizer 转成 token id 后，单独打包成一个 Q3P 运行时镜像：

- header：魔数 `Q3P`、`n_prompt`、两个保留字（必须为 0）
- `tokens`：`n_prompt` 个 u32 token id

`scripts/qwen3/tokenize_prompt.py` 负责生成这个镜像：

```sh
python3 scripts/qwen3/tokenize_prompt.py "你好" --out build/apps/prompt.bin
```

它随后被加载到 guest 的固定地址 `0x80F00000`。

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
  `npu.inc`中定义宏`E_BIN`以及`TADD`
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

`kernels.S` 的扩展名是大写 `.S`，GCC 因此按 `assembler-with-cpp` 处理：先做 C 预处理，再交给汇编器。若写成小写 `.s`，GCC 会直接调用汇编器，`#include`/`#define` 不会被展开（可用 `-x assembler-with-cpp` 显式指定）。`#include "dims.h"` 由预处理器处理，`.include "npu.inc"`、`.macro` 和 `.word` 由 GNU as 处理。内部大致相当于：

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

Decode 和 prefill 计算的是同一组公式，但是一次处理的 token 数量（单 token vs 最多 32 token）。核心差异在于投影算子：从 Prefill 阶段的 GEMM（General Matrix-Matrix multiplication），变成了 Decode 阶段的 GEMV（General Matrix-Vector multiplication，相当于 Batch=1 的退化 GEMM）。

#figure(
  three-line-table([
    | kernel               | *decode*（逐 token）                                | *prefill*（最多 32 token 一块）       |
    | :------------------- | :-------------------------------------------------- | :------------------------------------ |
    | 一次投影的 token 数  | 1 个 token（$1 times d_"in"$）                      | 最多 32 个（$"rows" times d_"in"$）   |
    | 激活量化             | `qwen3_quant_act`（全激活一个 scale）               | `qwen3_quant_rows`（每行一个 scale）  |
    | 投影 kernel          | `qwen3_matvec_q`（*vmma*）                          | `qwen3_matmul_q`（*mma*）             |
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
2. *描述符自增*：`vload v1` 的意思是"从 vm1.base 读 vc1.len 个元素到 v1，然后 base += 32×stride"。所以流式扫描（rmsnorm、softmax、加法和输出写回）的循环体里没有任何地址运算，回绕时才 `cfg.setx ... CF_BASE` 重写 base。
3. *标量↔向量摆渡*：`vinsert`（把一个 x 值塞进 lane）、`vbroadcast`（单 lane 铺全向量）负责标量进向量；`vreduce` 把归约结果直接广播到整条 Vec32；向量出标量走内存通道——把结果 `vstore` 落内存（常用 len-1 的"单 lane 存储"配置只写一个字），经 `fence.mem` 后由 `lw` 读回。`vextract` 只保留为低频调试通道。均值、scale、概率这类"标量"都按这套约定流动。
4. *标量与NPU的访存fence*：模拟器按程序序执行所以 `fence.mem` 实现为 no-op，但微架构上 NPU store 对标量 load 的可见性由 `fence.mem` 建立, kernel 里每处"NPU 写、标量读"之间都需要`fence.mem`。

寄存器名按 ISA 手册约定：`tN` 是 Tile，`aN` 是 Acc，`vN` 是 Vec32，`xN` 是 Scalar。RV64IM 标量一律写 `xN`，需要 ABI 名时写在注释里（如 `x5 = t0`、`x10 = a0`、`x22 = s6`），避免和 Tile 的 `tN`、Acc 的 `aN` 混淆。

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

prefill 的 `quant_rows` 按 token 行量化：先求每行 absmax 得到 scale，再逐块量化。这里一块是 `rows`×32（最多 32×32）；沿 $d_"in"$ 方向共有 $d_"in"/32$ 块，所以两遍各循环 `k/32` 次（`k` 就是这一层的 $d_"in"$）。

```asm
# pass 1：逐块折叠每行 absmax（共 k/32 块）
aload                    a0          # a0 ← 第一块 rows×32 f32（最多 32×32）
areduce.rows.absmax      v0, a0      # v0 ← 第一块每行 absmax

# 其余 k/32 - 1 块：循环
aload                    a0          # a0 ← 下一块
areduce.rows.absmax      v1, a0      # v1 ← 当前块每行 absmax
vmax                     v0, v0, v1  # v0 ← max(累计, 当前块)

# 循环结束后做一次
vmulx                    v0, v0, x5  # v0 ← absmax × (1/127)
vstore                   v0          # memory[vm0] ← 每行一个 scale（共 rows 个）

# pass 2：用逐行 scale 量化（同样 k/32 块）
aload                    a0          # a0 ← rows×32 f32 块（最多 32×32）
aquant.rows.q8s32        t0, a0, v0  # t0 ← quant(a0) with v0
tstore                   t0          # memory[tm0] ← t0
```

==== 实现：decode 激活量化

decode 的激活量化把整条激活压成一个 scale，结果留在 Tile 寄存器，直接给下一步 int8 matvec 用。

这里把内存里的 $d_"in"$ 个 f32 激活元素按 1024 个一组切成若干*输入激活块*（activation block）；量化时每个输入块先 `aload` 到 Acc，再写成 Tile 里的 int8 *量化块*（quant block）。输入块和量化块都对应一个 $32 times 32$ tile。块数 $n_"blocks" = ceil(d_"in"/1024)$。

```asm
vfill                    v0, 0         # v0 ← 0
# 第一遍：n_blocks × 32 次

# 求全局 absmax
vload                    v1            # v1 ← 下一块 x
vabs                     v1, v1        # v1 ← |v1|
vmax                     v0, v0, v1    # v0 ← max(v0, v1)
vreduce.max              v30, v0       # v30[0] ← max(v0)

# scale -> v2
vmulx                    v30, v30, x6  # v30[0] ← absmax × (1/127)
vbroadcast               v2, v30[0]    # v2 ← broadcast(scale)
vstore                   v30           # 单 lane 落栈
fence.mem                              # NPU store 对标量可见的边界
lw                       x7, 0(sp)     # x7 (t2) ← scale 位模式（经内存回标量）

# 第二遍：逐个激活块（每块 32×32）
# am0: row_stride = 128, col_stride = 4，访存后沿行自增
aload                    a0            # a0 ← 32×32 f32 激活块
aquant.rows.q8s32        t2, a0, v2    # t2 ← quant(a0) with v2
```

这段的输入、输出和寄存器：

#figure(
  three-line-table([
    | 对象                | 位置            | 作用                                      |
    | :------------------ | :-------------- | :---------------------------------------- |
    | $bold(x)$           | 内存，f32       | 输入激活，长度 $d_"in"$                   |
    | `v0` / `v1`         | Vec32           | 第一遍的逐 lane 最大值 / 当前 32-lane 块  |
    | `v30`               | Vec32，`len=1`  | 全局 absmax，之后变成 scale               |
    | `v2`                | Vec32           | broadcast 后的 scale，供 `aquant` 使用    |
    | `a0`                | Acc，32×32 f32  | 第二遍的临时输入块                        |
    | `t2` / `t3` / `t4`  | Tile，32×32 i8  | 量化块，留在寄存器                        |
    | `x6` / `x7`         | Scalar          | `1/127` 的位模式 / scale 的位模式         |
  ]),
  caption: [decode 激活量化的数据位置],
)

=== Q/K/V 投影

$
  bold(h)_1 = "RMSNorm"(bold(x)_0; bold(gamma)_1), quad
  bold(q) = bold(W)_Q bold(h)_1, quad
  bold(k) = bold(W)_K bold(h)_1, quad
  bold(v) = bold(W)_V bold(h)_1,
$

Qwen3-0.6B 中 $bold(W)_Q in RR^(2048 times 1024)$，$bold(W)_K, bold(W)_V in RR^(1024 times 1024)$。$bold(q)$ 按头切成 16 个 $RR^128$，$bold(k), bold(v)$ 切成 8 个 $RR^128$。

==== 实现：prefill 投影（`matmul`）

`matmul_q`：给定 $bold(X)^q in ZZ^(B times d_"in")$、$bold(W)^q in ZZ^(d_"out" times d_"in")$、逐行激活 scale $bold(s)_x in RR^B$ 和权重 scale $bold(s)_W in RR^(d_"out")$，输出

$ o_(r,j) = s_(x,r) s_(W,j) sum_(c=0)^(d_"in"-1) X^q_(r,c) W^q_(j,c). $

$W$ 在内存中以 $32 times 32$ tile 为粒度存放为 $(d_"out"/32, d_"in"/32, 32, 32)$，tile 内按 $(d_"out", d_"in")$ 存放, 这样`tload`一次取一个连续的1KiB tile, 直接得到了 `mma.nt` 需要的右操作数。

`X_tile(kblock)` 是 $X_q$ 的第 `kblock` 个 `rows × 32` 块（`kblock = 0` 覆盖输入通道 `0..31`）；`W_tile(nblock, kblock)` 是权重的 32×32 tile。以 Q 投影（$d_"out" = 2048$，$d_"in" = 1024$）为例：$W_q$被切分成$64 times 32$个tile, 行方向每 8 行一组，共8组`g = 0..7`,`g=0` 对应 `nb=0..7`，……，`g=7` 对应 `56..63`。

下面以 `g = 0` 为例，这一组是 `nb = 0..7`；先看第一个输出 tile `nb = 0`（累加器 `a0`）。

记 $X^q in RR^(B times 1024)$ 为量化激活，$W^q in RR^(2048 times 1024)$ 为量化权重($W^q$按行切分成$W^q_0, W^q_1, .., W^q_(63) in RR^(32 times 1024)$)。矩阵乘就是：

$
  a_0 = X^q (W^q_0)^top, quad a_0 in RR^(B times 32)
$

实现时沿 $d_"in"$ 每 32 列切一个 kblock，上式拆成 kblock 的累加：

$
  a_0 = sum_("kb"=0)^(31) X^q_("kb") (W^q_(0,"kb"))^top, quad X^q_("kb") in RR^(B times 32), quad W^q_(0,"kb") in RR^(32 times 32),
$

两个 scale 在最后一个（或唯一的）K 块上由 `adequant` 完成反量化：

$
  O_0 = "diag"(s_x) a_0 "diag"(s_(W,0)), quad O_0 in RR^(B times 32),
$

其中 $s_x$ 是 $B$ 个激活 scale(行激活)，$s_(W,0)$ 是输出通道 `0..31` 的 32 个 weight scale(列激活)。

循环外先 `vload v30`，把 `xs` 常驻在 `v30`。这里 `kblocks = d_in/32`，Q 投影是 32；循环嵌套：

```text
for g = 0..7:                    # Q: 8 组
  base = 8g                      # 本组第一个 nblock

  for kblock = 0..kblocks-2:     # 除最后一个 K 块
    t0 = X_tile(kblock)          # 每个 kblock 只加载一次

    for G = 0..7:                # 组内 8 个输出 tile（复用 t0）
      t1 = W_tile(base+G, kblock)

      if kblock == 0:
        aG = t0 * t1^T           # mma.nt.zero
      else:
        aG += t0 * t1^T          # mma.nt.acc
```

最后一个（或唯一的）K 块使用固定的 drain 序列：先 `vload v29`，再 `mma.nt.acc`（单 K 块用 `mma.nt.zero`），紧接着 `adequant`，最后 `astore`。scale 加载放在 MMA 前、MMA 与 `adequant` 相邻，便于微架构识别并融合：

```asm
# 最后一个/唯一的 K 块（aG 以 a0 为例）：
tload               t1
vload               v29                      # v29 ← 32 个 weight scale
mma.nt.acc          a0, t0, t1               # 单 K 块用 mma.nt.zero
adequant            a8, a0, v29, v30         # a8 ← f32(a0) * v29[j] * v30[t]
astore              a8
```

`group`（8 个 nblock 一组）和 `tail`（不足 8 个 nblock）都使用这个固定序列。

- MMA:            $8 × 32 × 8 = 2048$ 次
- X_tile 加载:    $8 × 32 = 256$ 次
- W_tile 加载:    $8 × 32 × 8 = 2048$ 次
- adequant:       $64$ 个输出 tile = $64$ 次
- astore:         $64$ 个输出 tile = $64$ 次

==== 实现：decode 投影（`matvec`）

给定 int8 激活 $bold(x)^q in ZZ^(d_"in")$、int8 权重 $bold(W)^q in ZZ^(d_"out" times d_"in")$、激活 scale $s_x in RR$ 和逐行权重 scale $bold(s)_W in RR^(d_"out")$，输出 $bold(o) in RR^(d_"out")$：

$
  o_j = s_x s_(W,j) sum_(c=0)^(d_"in"-1) x^q_c W^q_(j,c), quad 0 <= j < d_"out".
$

decode 的投影把跨 activation block 的 i32 部分和放在 `qwen3_accbuf`；非最后 kblock 用 `vmma.nt.acc` 累加，最后一个 activation block 的最后一个 kblock 用固定 drain 序列。

`quant_act` 把激活量化成 1–3 个 32×32 量化块（quant block，Tile t2/t3/t4）：每个 tile 有 32 行，第 R 行（`R = 0..31`）就是一个 kblock 的 32 个输入通道；`t2[R]` 取第 R 行。对每个 activation block 的每个 nblock、每个有效 R：

```asm
# 非最后 kblock：i32 累加
tload               t1                 # t1 ← W[nblock][kblock]
vmma.nt.acc          v4, t2[R], t1     # v4 ← v4 + t2[R] · t1^T

# 最后一个 activation block 的最后一个 kblock：
tload               t1
vload               v6                 # v6 ← 32 个 weight scale
vmma.nt.acc          v4, t2[R], t1     # v4 ← v4 + t2[R] · t1^T
vdequant            v8, v4, v6, v7     # v8 ← f32(v4) * v6[j] * v7[0]
vstore              v8                 # 写 f32 输出
```

decode 是单 token GEMV，所以用 `vmma`（一行激活 × 一个权重 tile）；一条 `vmma` 只覆盖一个 kblock，R 循环把部分和累加完。

`v6` 是当前 nblock 的 32 个 weight scale，`v7[0]` 是激活 scale；`vdequant` 把 i32 `v4` 反量化到独立的 f32 `v8`，直接写 `v8`。`v6` 在 `vmma.nt.acc` 前加载，`vdequant` 紧邻其后，便于微架构检测并融合。第一个 activation block 先 `vfill v4, 0`；后续 activation block 用 `vload v4` 从 `qwen3_accbuf` 续上；非最后 activation block 结束时 `vstore v4` 写回。

关键设计：反量化仍然推到最后——i8 域只做纯整数乘加，最后一个 kblock 的 `vdequant` 紧邻 MMA，乘 `v6`/`v7` 并写 f32。

=== QK-RMSNorm 与 RoPE

对每个 query head $h$ 的 $bold(q)_h$，以及每个 KV head $h_"kv"$ 里的 $bold(k)_(h_"kv")$，先做 head-dim RMSNorm：

$
  bold(q)'_h = "RMSNorm"(bold(q)_h; bold(gamma)_q), quad
  bold(k)'_(h_"kv") = "RMSNorm"(bold(k)_(h_"kv"); bold(gamma)_k).
$

然后按位置 $p$ 做 rotate-half RoPE。把一头的向量分成两半 $bold(x)_"a", bold(x)_"b" in RR^(d_"head"/2)$，cos/sin 表对应行分别为 $bold(c)_p, bold(s)_p$：

$
  "RoPE"(bold(x), p)_"a" = bold(x)_"a" dot.o bold(c)_p - bold(x)_"b" dot.o bold(s)_p,
$

$
  "RoPE"(bold(x), p)_"b" = bold(x)_"b" dot.o bold(c)_p + bold(x)_"a" dot.o bold(s)_p.
$

作用到 Q/K 上就是 $bold(q)_h^"rope" = "RoPE"(bold(q)'_h, p)$、$bold(k)_(h_"kv")^"rope" = "RoPE"(bold(k)'_(h_"kv"), p)$。

==== 实现：RoPE

实现上是一个纯向量流水线。`hd = 128` 时，每半 64 个 f32 分成 2 个 32-lane chunk；12 条描述符按 6 组分工如下（base 偏移按字节，`stride = 4`，`len = 32`）：

#figure(
  three-line-table([
    | 数据  | VM（c0/c1）      | base c0    | base c1        | inc  |
    | :---- | :--------------- | :--------- | :------------- | ---: |
    | cos   | `vm0` / `vm1`    | `cos_h`    | `cos_h + 128`  | 1    |
    | sin   | `vm2` / `vm3`    | `sin_h`    | `sin_h + 128`  | 1    |
    | x1    | `vm4` / `vm5`    | `x`        | `x + 128`      | 1    |
    | x2    | `vm6` / `vm7`    | `x + 256`  | `x + 384`      | 1    |
    | out1  | `vm12` / `vm13`  | `x`        | `x + 128`      | 0    |
    | out2  | `vm14` / `vm15`  | `x + 256`  | `x + 384`      | 0    |
  ]),
  caption: [RoPE 的描述符分配（`hd = 128`）],
)

`inc = 1` 的 8 条是流式读入，`inc = 0` 的 4 条原地写回；`x2` 从 `x + hd*2` 字节开始（`hd = 128` 时是 `x + 256`）。内层计算：

```asm
# vm0..vm7: 自增流；vm12..vm15: 原地写回
vload         v0            # cos c0
vload         v1            # cos c1
vload         v2            # sin c0
vload         v3            # sin c1
vload         v4            # x1 c0
vload         v5            # x1 c1
vload         v6            # x2 c0
vload         v7            # x2 c1

# out1 = x1*cos - x2*sin
vmul          v8, v4, v0
vmul          v9, v6, v2
vsub          v12, v8, v9
vmul          v8, v5, v1
vmul          v9, v7, v3
vsub          v13, v8, v9

# out2 = x2*cos + x1*sin
vmul          v8, v6, v0
vmul          v9, v4, v2
vadd          v14, v8, v9
vmul          v8, v7, v1
vmul          v9, v5, v3
vadd          v15, v8, v9

vstore        v12           # x1 c0
vstore        v13           # x1 c1
vstore        v14           # x2 c0
vstore        v15           # x2 c1
```

=== KV cache 与 attention

第 $p$ 个 token 的 K/V 追加到 cache：

$
  bold(K)_(h_"kv",p) = bold(k)_(h_"kv")^"rope", quad
  bold(V)_(h_"kv",p) = bold(v)_(h_"kv").
$

第 $h$ 个 query head 使用第 $h_"kv" = floor(h / G)$ 个 KV head；对 $t = 0, dots, p$：

$
  s_(h,t) = bold(q)_h^"rope" dot bold(K)_(h_"kv",t), quad
  alpha_(h,t) = "softmax"_t (s_(h,t) / sqrt(d_"head")),
$

$
  bold(o)_h = sum_(t=0)^p alpha_(h,t) bold(V)_(h_"kv",t).
$

下面三个实现小节都只描述一个 head，省略 head 下标：$s_t = s_(h,t)$、$bold(K)_t = bold(K)_(h_"kv",t)$、$bold(V)_t = bold(V)_(h_"kv",t)$、$bold(o) = bold(o)_h$。

==== 实现：scores

给定 query $bold(q) in RR^(d_"head")$ 和 key 矩阵 $bold(K) in RR^(n_"key" times d_"head")$，第 $t$ 个 key 的分数是

$ s_t = sum_(d=1)^(d_"head") K_(t,d) q_d. $

q 的 4 个 32-lane chunk 先驻留 v8..v11；对每个 key t:

```asm
vfill        v16, 0             # v16 ← 0
# vm12.base = K_t 行首（自增流）
vload        v12                # v12 ← K_t 的下一块
vfmadd       v16, v12, v8, v16  # v16 ← v16 + v12 · v8（v9..v11 同理）
vreduce.sum  v17, v16           # v17[0] ← sum(v16)（vc17 配成 len-1）
vstore       v17                # 单 lane 写到 scores[t]
```

==== 实现：softmax

给定分数向量 $bold(s) in RR^n$，先减去最大值再取指数：

$
  tilde(p)_t = exp((s_t - max_u s_u) / sqrt(d_"head")), quad r = 1 / (sum_t tilde(p)_t).
$

这里的 $tilde(p)_t$ 是未归一化概率，$r$ 是归一化因子的倒数；对应上面的 $alpha_(h,t) = r_h tilde(p)_(h,t)$。

由于 ISA 中只有 `vexp2.approx` 指令，这里用 $exp(z) = 2^(z log_2(e))$ 把以 e 为底的指数换成以 2 为底，并把 $1/sqrt(d_"head")$ 合进 $c = log_2(e) / sqrt(d_"head"),$

于是

$
  exp((s_t - max_u s_u) / sqrt(d_"head")) = 2^((s_t - max_u s_u) dot c).
$

kernel 里对应 `vsub` → `vmulx c` → `vexp2.approx`（`x12` 存的是 $c$ 的 f32 位模式）：

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

=== O 投影与残差

$
  bold(a) = bold(W)_O "concat"(bold(o)_1, dots, bold(o)_(H_q)), quad
  bold(x)_1 = bold(x)_0 + bold(a),
$

其中 $bold(W)_O in RR^(1024 times 2048)$。

==== 实现：残差加法（`qwen3_add`）

给定长度为 $n$ 的向量 $bold(x), bold(y)$，残差：

$ bold(o) = bold(x) + bold(y). $

```asm
vload   v0          # v0 ← dst
vload   v1          # v1 ← src
vadd    v0, v0, v1  # v0 ← v0 + v1
vcopy   v2, v0      # v2 ← v0
vstore  v2          # memory[vm2] ← v2
```

这个算子就是 `qwen3_add`。三个自增描述符，循环 n/32 次，全算子里最简单的一个。

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

其中 $bold(W)_"gate", bold(W)_"up" in RR^(3072 times 1024)$，$bold(W)_"down" in RR^(1024 times 3072)$，$"SiLU"(g) = g / (1 + e^(-g))$。这里的残差复用上面的 `qwen3_add`。

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

其中 $bold(W)_"embed" in RR^(151936 times 1024)$，$bold(z) in RR^151936$。

==== 实现：argmax

最终 logits 有 151936 个，按 1024 个一块切成 148 个 full block + 1 个 12 行 tail。每个 block 先 `aload` 成 32×32 f32 Acc tile，再用 `areduce.rows.argmax` 做行内归约，最后 `vreduce.argmax` 在 32 个行最大值里选最佳行：

```asm
# 每个 full block：
aload                  a0                    # a0 ← 32×32 f32（1024 个 logits）
areduce.rows.argmax    v3, v4, a0            # v3[i] = 第 i 行 argmax 列号
                                             # v4[i] = 第 i 行最大值
vreduce.argmax         v5, v6, v4            # v5 = 最佳行，v6 = block 最大值
```

每个 block 算完后，和当前最优比较并更新。用到的状态是：

#figure(
  three-line-table([
    | 寄存器  | 含义                       | 类型  |
    | :------ | :------------------------- | :---- |
    | `v0`    | 当前最优值                 | f32   |
    | `v11`   | 最优 block 的行内下标向量  | u32   |
    | `v12`   | 最优行                     | u32   |
    | `v13`   | 最优 block 的 base         | u32   |
    | `v14`   | 当前 block 的 base         | u32   |
  ]),
  caption: [argmax 的状态寄存器],
)

更新逻辑：

```asm
# x29 = t4 = 当前 block base
vfillx         v14, x29          # v14 ← 当前 block base
vcmplt         v8, v0, v6        # 当前最优 < 候选
vcmpunord      v9, v0, v0        # 当前最优是 NaN
vcmpunord      v10, v6, v6       # 候选是 NaN
vnot           v10, v10          # 候选是数值
vand           v9, v9, v10       # 当前最优是 NaN 且候选是数值
vor            v8, v8, v9        # 更新掩码
vselect        v0, v8, v6, v0    # 当前最优值
vselect        v11, v8, v3, v11  # 最优 block 的行内下标
vselect        v12, v8, v5, v12  # 最优行
vselect        v13, v8, v14, v13 # 最优 block base
```

`v0` 初始化为全 NaN，`v11/v12/v13` 初始化为 0；第一个数值 block 会通过“当前最优是 NaN 且候选是数值”这个 mask 替换它。

tail 只有 12 行：把 `ac0.rows`、`vc3.len`、`vc4.len` 都设成 12，`areduce` 只写 12 个有效行；之后把 `vc3.len` 恢复成 32，供 `vselect` 复制整个行内下标向量。

收尾把最优行、base、行内下标向量写到栈上，再用标量算出全局下标：

```asm
# vc12/vc13 配成 len-1
vstore         v12           # row
vstore         v13           # base
vstore         v11           # 32 个行内列号
fence.mem
lwu            t0, 0(sp)     # row
lwu            t1, 4(sp)     # base
slli           t2, t0, 2
add            t2, sp, t2
lwu            t2, 16(t2)    # col = v11[row]
slli           t3, t0, 5
add            t1, t1, t3    # base + row*32
add            a0, t1, t2    # + col
```
