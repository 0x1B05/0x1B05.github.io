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

笔者最近在做一款基于 Tile 的 NPU（Tile-NPU），并为其设计了指令集#link("https://github.com/0x1B05/Tile-NPU-ISA")[Tile-NPU-ISA]和配套的功能模拟器#link("https://github.com/0x1B05/Tile-NPU-Sim")[Tile-NPU-Sim]。本文以 Qwen3-0.6B 为例，梳理它在 Tile-NPU 模拟器上的执行流程：从 guest 程序与模型权重的加载开始，沿着一次前向推理经过的计算步骤，说明这些计算如何落到具体的 NPU 指令上。(目前的算子为ai生成的汇编指令, 流程仅供参考)

== 宿主机准备模型

运行 Qwen3 前，宿主机上需要先准备好*模型权重*, *tokenizer*, *prompt*, 然后执行 `scripts/qwen3/convert.py`把 HuggingFace 格式的 Qwen3 权重，转换成`q8s32`格式的blob(Binary Large OBject), 以适应Tile-NPU模拟器.

#definition(title: "q8s32 格式")[
  *q8s32* 指按输出行对称量化的 int8 权重，加上每行一个 32 位 scale。
  - `q8`：量化后的权重，每个元素是 8-bit 有符号整数，取值范围为 $[-127, 127]$。
  - `s32`：每行存放一个 f32 的 scale。对称量化把零点固定为 0，因此每行只需要保存一个 scale。
  量化时取该行绝对值最大值 $"amax"$，令 $s = "amax" / 127$，再将 $w / s$ 按最近偶数舍入并饱和到 $[-127, 127]$。反量化时 $w approx q times s$；矩阵乘中 int8 点积累加为 i32，最后再乘回 activation scale 和该行的 weight scale。
]

首先转换脚本会先读取模型配置, 然后读取 BF16 权重，并将权重转换为q8s32格式.

#example(title: "线性层权重离线量化")[
  - Input: `W`，shape `(out_dim, in_dim)`，dtype `bf16`
  - Output:
    - `W_q`：shape `(out_dim, in_dim)`，dtype `int8`
    - `W_scale`：shape `(out_dim,)`，dtype `f32`

  每一行独立做 symmetric int8 量化： $ W_"scale"[i] = (max_j abs(W[i, j])) / 127, quad W_q[i, j] = "sat_rne"(W[i, j] / W_"scale"[i]) $
  反量化时：$ W[i, j] approx W_q[i, j] times W_"scale"[i] $
]

在 q8s32 中，`sat_rne` 的输入是 $x = W[i, j] / W_"scale"[i]$。它的定义是：

$
  "sat_rne"(x) = cases(
    0 & x " is NaN",
    min(max("RNE"(x), -127), 127) & "otherwise",
  )
$

其中 $"RNE"(x)$ 表示最近偶数舍入。

接着，转换脚本根据 `max_pos`、`head_dim` 和 `rope_theta` 预计算 RoPE 表：

- `rope_cos`：shape `(max_pos, head_dim / 2)`，dtype `f32`
- `rope_sin`：shape `(max_pos, head_dim / 2)`，dtype `f32`

prompt 也会由 tokenizer 转成 token id，一起写入 blob：

- `tokens`：shape `(n_prompt,)`，dtype `u32`

最终得到的 `Q3B1` blob 主要包含：

- header：魔数 `Q3B1`、模型维度、`n_prompt`、`eps` 和 section 数量
- section directory：每个 section 的名称、偏移和大小
- `tokens`：prompt token ids
- `rope_cos` / `rope_sin`：RoPE 表
- `embed` 和 `embed_s`：token embedding 的 `int8` 权重和 `f32` 行 scale
- 每层的 `qw` / `kw` / `vw` / `ow`，以及对应的 `qws` / `kws` / `vws` / `ows`：Q/K/V/O 投影的 `int8` 权重和 `f32` 行 scale
- 每层的 `inln` / `ptln` / `qn` / `kn`：RMSNorm 参数，`f32`
- 每层的 `gw` / `uw` / `dw`，以及对应的 `gws` / `uws` / `dws`：MLP 的 `int8` 权重和 `f32` 行 scale
- `fin_norm`：最终 RMSNorm 参数，`f32`

== 交叉编译

Qwen3 guest 由 `xmake build qwen3_app` 构建。`xmake/apps.lua` 调用交叉工具链，把 `apps/qwen3/*.c` 和 `apps/qwen3/*.S` 一次性编译、链接成 ELF：

```sh
riscv64-linux-gnu-gcc -march=rv64im -mabi=lp64 -O2 \
    -ffreestanding -nostdlib -static -no-pie \
    -I apps/qwen3/include -I tests/guest/include \
    -T apps/qwen3/link.ld -o build/apps/qwen3.elf \
    apps/qwen3/*.c apps/qwen3/*.S
```

实际参与链接的源文件是 `blob.c`、`console.c`、`forward.c`、`main.c`、`probe.c`、`crt0.S` 和 `kernels.S`。

`link.ld` 把入口固定在 `0x80000000`，并让 `crt0.S` 的 `.text.crt0` 排在最前面：

```ld
. = 0x80000000;
.text : { *(.text.crt0) *(.text*) }
```

`crt0.S` 负责清零 `.bss`、把栈顶设为 `0xC0000000`、调用 `main()`，最后用 `ebreak` 停机。

=== 从宏到机器码

C 代码只生成 RV64IM；NPU 指令主要由 `kernels.S` 通过 `npu.inc` 里的宏生成。

#example(title: "TADD 5, 6, 7")[
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
     4:   00008067    ret
  ```
]

`kernels.S` 的扩展名是大写 `.S`，所以 GCC 会先做 C 预处理，再交给汇编器。`#include "dims.h"` 由预处理器处理，`.include "npu.inc"` 和 `.macro` 由 GNU as 处理，`.word` 也由 GNU as 计算常量并输出 4 字节。内部大致相当于：

```sh
cc1 -E -lang-asm ... kernels.S -o kernels.s
riscv64-linux-gnu-as ... kernels.s -o kernels.o
```

=== 编译、链接与 objcopy

上面那条 GCC 命令会把 `.c` 和 `.S` 分别编译成目标文件，再调用 `riscv64-linux-gnu-ld` 按 `link.ld` 链接成 `qwen3.elf`。C 和汇编之间仍然使用标准 RISC-V ABI。

#example(title: "qwen3_quant_act(x, k)")[
  `x` 和 `k` 分别放在 `a0`、`a1`，返回的 scale bits 放在 `a0`，调用是一条普通的 `call`；进入 `kernels.S` 后，指令流里开始出现 NPU 编码，NPU 指令使用自己的 tile/acc/vector 寄存器，指针和长度等标量参数仍通过 `x` 寄存器传递，执行完 `ret` 回到 C 代码。
]

最后用 `objcopy` 把 ELF 转成 flat binary：

```sh
riscv64-linux-gnu-objcopy -O binary build/apps/qwen3.elf build/apps/qwen3.bin
```

ELF 头、section table 和符号都会被去掉，只留下 loadable section 的内存镜像。

== 装载与内存映射

一次推理需要把guest程序镜像以及模型权重两个镜像交给 `sim_run`，按 `image[@0xADDR]` 形式装进同一块 RAM。整个平台的地址布局定义在 `apps/qwen3/qwen3.h`, 如下表所示:

#figure(
  three-line-table([
    | 地址          | 用途                                     |
    | :------------ | :--------------------------------------- |
    | `0x80000000`  | `qwen3.bin`:guest 程序镜像               |
    | `0x81000000`  | `model.q3b`:Q3B1 模型 blob（约 598 MB）  |
    | `0xB0000000`  | KV cache 区域（256 MiB）                 |
    | `0xC0000000`  | 栈顶                                     |
    | `0x10000000`  | 串口 MMIO                                |
  ]),
  caption: [Qwen3 guest 的内存映射],
  numbering: none,
)

```sh
./build/linux/x86_64/release/sim_run -m 1024 build/apps/qwen3.bin model.q3b@0x81000000
```

`-m 1024` 把 RAM 从默认的 128 MiB 扩到 1 GiB，否则模型 blob 放不下。装载完成后模拟器从 `0x80000000` 开始取指：`_start` 起栈、调用 `main()`；`main` 返回后 crt0 把返回值放进 `a0` 并执行 `ebreak` —— 模拟器以 `ebreak` 为停机约定，`a0 = 0` 即成功。

== guest 程序启动

```
_start: 清 .bss → sp = 0xC0000000 → call main → ebreak(a0=返回值)
```

=== `main()`(main.c:10)：四步

1. *验 blob*：检查 magic、prompt 长度（≤ max_pos)、token id 范围；打印 prompt token 序列；
2. *`qwen3_init()`*（见下）;
3. *prefill*:`qwen3_prefill(tokens, n_prompt-1)`——前 n−1 个 prompt token 只建 KV cache，不需要 logits;
4. *decode 循环*：最后一个 prompt token 先走一次 `qwen3_forward` 拿第 1 个生成 token；之后自回归：`qwen3_forward(next, pos, 1)` → 打印 → 最多 32 个 token、遇 EOS(151645/151643）或超 max_pos 停。`want_logits=1` 控制最后才算 logits(prefill 阶段省掉 lm-head 那趟 vocab 级 matvec)。

== 主循环：prefill 与 decode

`main` 的主线只有三步：打印 prompt token → `qwen3_prefill(tokens, n_prompt - 1)` 处理前 $n-1$ 个 prompt token → 对最后一个 prompt token 调 `qwen3_forward` 得到第一个新 token，然后进入 decode 循环：每轮 `qwen3_forward(next, pos, 1)` 产生下一个 token，直到达到 32 个新 token 或遇到 EOS(`<|im_end|>` / `<|endoftext|>`)。

两条路径的*数学完全相同*（`forward.c` 的注释承诺逐位一致：同样的逐行 scale、完全相同的 i32 累加、同样的 epilogue 顺序），区别只在批量化程度：

#figure(
  three-line-table([
    | kernel       | *decode*（逐 token）                                | *prefill*（32 token 一批）            |
    | :----------- | :-------------------------------------------------- | :------------------------------------ |
    | 投影粒度     | 向量（$1 times k$）                                 | 矩阵（$32 times k$）                  |
    | 激活量化     | `qwen3_quant_act`（全激活一个 scale）               | `qwen3_quant_rows`（每行一个 scale）  |
    | 投影 kernel  | `qwen3_matvec_q`（*bdot*）                          | `qwen3_matmul_q`（*mma*）             |
    | 其余 kernel  | rmsnorm / rope / attention / silu / add 都按行调用  | -                                     |
  ]),
  caption: [decode 与 prefill 的对应关系],
  numbering: none,
)

- *decode*（逐 token)：投影用 `quant_act` + `matvec_q`（向量×矩阵）;
- *prefill*(32 token 一批）：投影用 `quant_rows` + `matmul_q`（矩阵×矩阵，吃满 MMA);*attention 仍然逐 token*——因为第 t 个 token 的 KV 长度是 base+t+1，本来就逐个变长，没法批；rmsnorm/rope/silu/add 这些逐行向量算子也只是循环 32 次。

== 单层 transformer 的数据流

每层 transformer block 在 `qwen3_forward`(`apps/qwen3/forward.c`）按固定顺序：输入 RMSNorm → 激活动态量化（q/k/v 共享一次）→ Q/K/V 投影 → 逐头 QK-RMSNorm → RoPE → KV 追加 → 逐头注意力（scores → softmax → PV)→ O 投影 → 残差 → post-LN RMSNorm → gate/up 投影 → SiLU·up → down 投影 → 残差。prefill(`qwen3_prefill`）把同样的计算按 32 token 一批重排，量化和投影换成批量算子（见后文 `qwen3_quant_rows` 和 `qwen3_matmul_q`)，其余 kernel 逐行调用，数值与逐 token 路径逐位一致。

所有层走完后，是最终 RMSNorm(`fin_norm`)、lm_head（与嵌入表共享权重的一次 `matvec_q`，得到 `logits[151936]`）和 argmax 采样出下一个 token。

== 算子

=== 记号与形状

本文用 $bold(x) in RR^n$ 表示长度 $n$ 的向量，$bold(W) in RR^(n times k)$ 表示 $n$ 个输出行、$k$ 个输入列。$dot.o$ 是逐元素乘，$sum_i$ 沿对应维度求和；$s_x$ 是激活 scale，$bold(s)_W in RR^n$ 是权重逐行 scale。`q8s32` 中量化后的 int8 值记作 $q$，反量化后的 f32 值记作 $x$。

=== 算子共享的三种模式

1. *配置先行*：每条 NPU 指令的 dtype/shape 都来自配置寄存器。核函数开头先通过 `cfg.seti` / `cfg.setx` 写配置；`npu.inc` 里的 `LI_CWV` / `LI_CWM` 只是把配置字拼在标量侧的辅助宏。这是"一次配置、循环复用"的模式——循环体里只有计算和访存指令。
2. *描述符自增*：`vload v1` 的意思是"从 vm1.base 读 vc1.len 个元素到 v1，然后 base += 32×stride"。所以流式扫描（rmsnorm、softmax、加法和 epilogue）的循环体里没有任何地址运算，回绕时才 `cfg.setx ... CF_BASE` 重写 base。
3. *标量↔向量互转*：`vreduce`（向量归约成标量写 x 寄存器）、`vextract`（取一个 lane 到 x）、`vinsert`（把一个 x 值塞进 lane）、`vbroadcast`（单 lane 铺全向量）——均值、scale、概率这类"标量"都这样进出向量域。

寄存器名按 ISA 手册约定：`tN` 是 Tile，`aN` 是 Acc，`bN` 是 Vec8，`vN` 是 Vec32，`xN` 是 Scalar。RV64IM 标量一律写 `xN`，需要 ABI 名时写在注释里（如 `x5 = t0`、`x10 = a0`、`x22 = s6`），避免和 Tile 的 `tN`、Acc 的 `aN` 混淆。

=== `qwen3_embed` — 查表 + 反量化

给定 token id $i$，嵌入表 $bold(E) in ZZ^(V times D)$ 和逐行 scale $bold(s) in RR^V$.

输出$bold(o) = s_i bold(E)_i, quad bold(o) in RR^D.$

嵌入表也是 q8s32 存的，取出后要变回 f32。关键观察：一行嵌入有 $D$ 个元素，把内存里的嵌入行看成 $32 times 32$ 的二维视图（`row_stride = 32`、`col_stride = 1`)，一次 `tload` 就能取 1024 个 i8;$D < 1024$ 时把 `tc/ac` 的 `rows` 设成 $D/32$ 取部分块即可。

```asm
lw            x6, 0(x5)         # x6 (t1) ← embed_s[id]（x5 = t0）
vfillx        v0, x6            # v0 全 lane ← s_i
# 循环 hidden/1024 次（不足 1024 时单个部分块）：
tload         t0                # t0 ← 32x32 i8 块（tm0 自增）
tdequant.rows.f32 a0, t0, v0    # a0 ← f32(t0) × s_i
astore        a0                # memory[am0] ← a0
```

`tdequant.rows.f32` 一条指令完成"int8→f32 转换 + 逐行乘 scale"，是 QNT 族的反量化方向；它的语义是 `a0[i,j] = f32(t0[i,j]) × v0[i]`，即 scale 按行广播，而行嵌入的 scale 只有一个标量，所以 `vfillx` 把 `s_i` 铺进所有 lane 正好匹配。

==== 用 gather 批量查表

上面的循环逐 token 查表；如果一次性处理一批 token，可以用 gather 按索引批量取行。以 Qwen3 tiny 为例：词表 $V = 320$、hidden $D = 64$、一批 $B = 32$ 个 token；embedding 表是 $320 times 64$ 的 i8，每行一个 f32 scale。由于 Tile 是 $32 times 32$，一次只能装 32 列，64 维的 hidden 要拆成两个 32 列块。逻辑上希望得到：

```text
for i in 0 .. B-1:
    out[i, 0:64] = dequant(table[ids[i], 0:64], scale[ids[i]])
```

内存布局和描述符：

#three-line-table([
  | 对象         | 形状                | stride                                                       |
  | :----------- | :------------------ | :----------------------------------------------------------- |
  | embed table  | $V times 64$ 个 i8  | `row_stride = 64`（相邻 token 行 64 字节）,`col_stride = 1`  |
  | embed scale  | $V$ 个 f32          | `stride = 4`                                                 |
  | token ids    | $B$ 个 i32          | `stride = 4`                                                 |
])

寄存器与描述符配置：

#three-line-table([
  | 寄存器       | 配置                     | 用途                   |
  | :----------- | :----------------------- | :--------------------- |
  | `t0` / `t1`  | Tile,rows=32,cols=32,i8  | hidden 的两个 32 列块  |
  | `v1`         | Vec32,len=32,i32         | token IDs              |
  | `v2`         | Vec32,len=32,f32         | 每行 scale             |
  | `a0` / `a1`  | Acc,rows=32,cols=32,f32  | 反量化结果             |
])

```text
tm0: base = table,      row_stride = 64, col_stride = 1
tm1: base = table + 32, row_stride = 64, col_stride = 1   # 取每行第二个 32 列
vm1: base = ids,        stride = 4
vm2: base = scales,     stride = 4
```

指令序列：

```asm
vload              v1          # v1 ← 32 个 token ID
tload.gather       t0, v1      # t0 ← table[v1, 0:32]
tload.gather       t1, v1      # t1 ← table[v1, 32:64]
vload.gather       v2, v1      # v2 ← scale[v1]
tdequant.rows.f32  a0, t0, v2  # a0 ← f32(t0) × v2[i]
tdequant.rows.f32  a1, t1, v2  # a1 ← f32(t1) × v2[i]
```

每条指令具体做了什么：

- `vload v1`：读 token IDs，即 `v1[i] = memory[ids + i*4]`（$i = 0..31$)。
- `tload.gather t0, v1`：对 $i, j = 0..31$ 取 `t0[i,j] = memory[table + v1[i]*64 + j]`——`t0` 的第 $i$ 行就是 token `v1[i]` 的 hidden[0:32]。索引可以重复，也可以乱序。
- `tload.gather t1, v1`：同理，但 `tm1` 的 base 是 `table + 32`——`t1[i,j] = memory[table + 32 + v1[i]*64 + j]`，即 hidden[32:64]。
- `vload.gather v2, v1`:`v2[i] = memory[scales + v1[i]*4]`，即 token `v1[i]` 对应 embedding 行的 scale，与 `t0`/`t1` 的第 $i$ 行对应。
- `tdequant.rows.f32 a0/a1, t, v2`：`a0[i,j] = f32(t0[i,j]) * v2[i]`、`a1[i,j] = f32(t1[i,j]) * v2[i]`。

合起来就是一个 $32 times 64$ 的 f32 embedding 结果。

形状和边界情况：

- hidden = 32：只需要 `t0`、`a0`；hidden = 64：像上面一样拆两块；hidden > 64：继续增加 `tm2`、`t2`，每 32 列一块。
- $B < 32$：把 `tc.rows`、`ac.rows`、`vc1.len`、`vc2.len` 都设为 $B$，只处理有效行；$B > 32$:Vec32 最多容纳 32 个索引，按每 32 个 token 一批循环。
- 索引重复：例如 `v1 = [5, 2, 5]`，第 0 行和第 2 行会取同一个 embedding 行。
- gather 不触发描述符自增，批量循环时改 `v1` 即可，`tm0`/`tm1` 的 base 不变。

和当前实现的区别：当前 `qwen3_embed` 没有用 gather，而是逐 token 把嵌入行看成 $32 times 32$ 的二维视图，用 `tload` → `tdequant.rows.f32` → `astore` 完成（见上一节）。上面给出的是"如果要用 gather 批量取 embedding"的完整流程；Qwen3 tiny 的 hidden=64，正好需要两次 `tload.gather` 和两次 `tdequant.rows.f32`。

=== `qwen3_rmsnorm`

给定 $bold(x) in RR^n$、$bold(gamma) in RR^n$ 和 $epsilon > 0$，输出 $bold(o) in RR^n$：

$
  bold(o) = bold(x) / sqrt((1/n) sum_(i=1)^n x_i^2 + epsilon) dot.o bold(gamma).
$

Qwen3 里用在三处：每层 input/post-attention layernorm(n=1024)、逐头 q/k norm(n=128)、最终 norm。

```asm
vfill          v0, 0           # v0 ← 0
# 第一遍：n/32 次
vload          v1              # v1 ← x 的下一块
vfmadd         v0, v1, v1, v0  # v0 ← v0 + v1 · v1
vreduce.sum    x5, v0          # x5 (t0) ← sum(v0)
vinsert        v2[0], x5       # v2[0] ← x5
vbroadcast     v2, v2[0]       # v2 ← broadcast(v2[0])
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

两个细节：`1/n` 不做除法——n 是 2 的幂，`inv_n_bits` 用 `(127−ctz(n))<<23` 直接拼出 f32 位模式；`rsqrt` 是硬件近似指令，所以这套实现的数值和参考 f32 的差异点被 probe/tiny 回归显式锁定。

=== `qwen3_quant_act` — 激活动态量化

给定一行激活 $bold(x) in RR^n$，动态量化得到 int8 向量 $bold(q)$ 和标量 scale $s$：

$ s = (max_i |x_i|) / 127, quad q_i = "sat_rne"(x_i / s). $

为下一步 int8 matvec 准备激活。均匀 scale（整个激活一个值），结果留在 Tile 寄存器不落内存。

```asm
vfill                    v0, 0       # v0 ← 0
# 第一遍：panels × 32 次
vload                    v1          # v1 ← 下一块 x
vabs                     v1, v1      # v1 ← |v1|
vmax                     v0, v0, v1  # v0 ← max(v0, v1)
vreduce.max              x5, v0      # x5 (t0) ← max(v0)
vinsert                  v2[0], x5   # v2[0] ← x5
vbroadcast               v2, v2[0]   # v2 ← broadcast(absmax)
vmulx                    v2, v2, x6  # v2 ← v2 × (1/127)   (x6 = t1)
vextract                 x7, v2[0]   # x7 (t2) ← v2[0]     (scale bits)
# 第二遍：每个 32×32 panel
aload                    a0          # a0 ← 32×32 f32 激活块（am0 沿行自增）
tquant.rows.scale.q8s32  t2, a0, v2  # t2 ← quant(a0) with v2
```

`tquant.rows.scale.q8s32` 是 QNT 族的外部 scale 行量化：Acc 源逐行用 vScale 的对应 lane 量化。这里 v2 全部 lane 相同（均匀 scale）。面板 t2/t3/t4 用标量 `t4` 计数器分支选择——量化完的激活驻留在 Tile 寄存器，下一个核函数直接消费，这是"寄存器驻留接力"，省一趟内存往返。k≤3072，所以最多 3 块 32×32(1024×3)。

=== `qwen3_matvec_q` — 解码期投影核心

给定 int8 激活 $bold(q) in ZZ^k$、int8 权重 $bold(W) in ZZ^(n times k)$、激活 scale $s_x in RR$ 和逐行权重 scale $bold(s)_W in RR^n$，输出 $bold(o) in RR^n$：

$ o_j = s_x s_(W,j) sum_(c=1)^k q_c W_(j,c), quad j = 1, dots, n. $

$bold(W)$ 是 convert 时量化好的 $[n,k]$ i8，逐行带 scale `ws`。Q/K/V/O/gate/up/down 投影 + logits 全走它。

分两个阶段。

*阶段 A：i8 乘加*。对每块 32 个输出（n-block）和每块 1024 个激活（panel），每个 `R = 0..31` 做：

```asm
# R 是 0..31 的循环变量；bR 表示第 R 个 Vec8 寄存器
textract.row        bR, t2[R]   # bR ← t2[R, :]
tload               t1          # t1 ← 下一个 32×32 权重块（tm1 自增）
bdot.nt.acc.i8.i32  v4, bR, t1  # v4 ← v4 + bR · t1ᵀ   (i8 × i8 → i32)
```

`bdot.nt.acc.i8.i32` 是 MMA_BDOT 族的“向量×tile 点积，NT 对右 tile 逻辑转置、ACC 累加”：一条 = 32 输出 × 32 k = 1024 次 MAC。32 行就是 32×1024。跨 panel 的部分和存在内存 `qwen3_accbuf` (i32)，下个 panel 用 `vload v4` 续上；新 panel 第一块用 `vfill v4, 0` 清。i32 累加是精确的——int8 乘积求和不会溢出也不舍入，数值误差只在量化那一步引入。

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

=== `qwen3_quant_rows` + `qwen3_matmul_q` — prefill 批量版

`quant_rows`：输入是 $bold(X) in RR^(B times k)$，对每一行 $t$ 独立量化：

$ s_t = (max_c |X_(t,c)|) / 127, quad q_(t,c) = "sat_rne"(X_(t,c) / s_t). $

```asm
# pass 1：逐块折叠每行 absmax
aload                    a0          # a0 ← 32×32 f32 块
areduce.rows.absmax      v0, a0      # v0 ← 每行 absmax
vmax                     v0, v0, v1  # v0 ← max(v0, v1)（后续块）
vmulx                    v0, v0, x5  # v0 ← v0 × (1/127)
vstore                   v0          # memory[vm0] ← 32 个 scale

# pass 2：用逐行 scale 量化
aload                    a0          # a0 ← 32×32 f32 块
tquant.rows.scale.q8s32  t0, a0, v0  # t0 ← quant(a0) with v0
tstore                   t0          # memory[tm0] ← t0
```

`matmul_q`：给定 $bold(Q) in ZZ^(B times k)$、$bold(W) in ZZ^(n times k)$、逐行激活 scale $bold(s)_x in RR^B$ 和权重 scale $bold(s)_W in RR^n$，输出

$ o_(t,j) = s_x[t] s_(W,j) sum_(c=1)^k q_(t,c) W_(j,c). $

真矩阵乘：

```asm
vload               v30          # v30 ← xs（32 个激活 scale）
# 对每块 32 列输出：
tload               t0           # t0 ← xq 的 32×32 块
tload               t1           # t1 ← Wᵀ 的 32×32 块（tm1 transpose）
mma.nn.zero.i8.i32  a0, t0, t1   # a0 ← t0 · t1
mma.nn.acc.i8.i32   a0, t0, t1   # a0 ← a0 + t0 · t1
# epilogue
acvt.i32.f32        a1, a0       # a1 ← f32(a0)
amulv.bycol         a1, a1, v29  # a1 ← a1 × ws[j]
amulv.byrow         a1, a1, v30  # a1 ← a1 × xs[t]
astore              a1           # memory[am1] ← a1
```

注意 W^T 是靠描述符的 transpose transform 在 `tload` 时顺手完成的，不需要单独的转置指令；用完恢复 `CF_LAYOUT=0`，因为别的核函数复用 tm1。`amulv.byrow` / `amulv.bycol` 正好表达"逐行 scale / 逐列 scale"两种广播语义。

=== `qwen3_rope`

给定一头向量 $bold(x) in RR^(d_"head")$，把它分成两半 $bold(x)_1, bold(x)_2 in RR^(d_"head" / 2)$，rotate-half 形式是

$
  bold(o)_1 = bold(x)_1 dot.o bold(c) - bold(x)_2 dot.o bold(s), quad
  bold(o)_2 = bold(x)_2 dot.o bold(c) + bold(x)_1 dot.o bold(s)
$

其中 $bold(c), bold(s)$ 是当前位置的 cos/sin 表行。Qwen3 的 $d_"head" = 128$，每半 64 维；cos/sin 表 convert 时预计算，按 pos 取行。

纯向量流水线：8 条流描述符（cos/sin/x1/x2 各两个 chunk，hd=128 时每半 2 个 32-lane chunk），8 条 `vmul` 加 `vsub` / `vadd` 组合，4 条 `vstore` 原地写回。`cfg.copy` 把 vm0 的 stride/flags 批量复制给 vm1..vm7，省 14 条配置指令——配置指令本身也是开销，能省则省。

=== `qwen3_scores` — attention 的 QK^T

给定 query $bold(q) in RR^(d_"head")$ 和 key 矩阵 $bold(K) in RR^(n_"key" times d_"head")$，第 $j$ 个 key 的分数是

$ s_j = sum_(d=1)^(d_"head") K_(j,d) q_d. $

这里不除 $sqrt(d_"head")$——这个 scale 折进 softmax。

q 的 4 个 32-lane chunk 先驻留 v8..v11（描述符不自增）；对每个 key j:

```asm
vfill        v16, 0             # v16 ← 0
# vm12.base = K_j 行首（自增流）
vload        v12                # v12 ← K_j 的下一块
vfmadd       v16, v12, v8, v16  # v16 ← v16 + v12 · v8（v9..v11 同理）
vreduce.sum  x5, v16            # x5 (t0) ← sum(v16)
sw           x5, 0(x6)          # memory[x6] ← x5（x5 = t0，x6 = t1）
```

=== `qwen3_softmax_exp`

给定分数向量 $bold(s) in RR^n$，先减去最大值再取指数：

$
  tilde(p)_i = exp((s_i - max_j s_j) / sqrt(d_"head")), quad r = 1 / (sum_i tilde(p)_i).
$

$tilde(p)_i$ 原地写回，$r$ 作为标量返回。技巧是把 $1/sqrt(d_"head")$ 换成乘 `scale_log2e = log2(e)/√hd`，这样 `exp(z) = 2^(z·log2e)` 能用 `vexp2.approx`：

```asm
vfillx        v0, x5       # v0 ← -inf
# 第一遍：vmax 扫描
vload         v1           # v1 ← scores 的下一块
vmax          v0, v0, v1   # v0 ← max(v0, v1)
vreduce.max   x5, v0       # x5 (t0) ← max(v0)
vfill         v2, 0        # v2 ← 0（Σ 累加器）
# 第二遍：exp + sum
vload         v1           # v1 ← scores（回绕重读）
vsubx         v1, v1, x5   # v1 ← v1 − max
vmulx         v1, v1, x12  # v1 ← v1 × scale_log2e
vexp2.approx  v1, v1       # v1 ← 2^v1
vadd          v2, v2, v1   # v2 ← v2 + v1
vcopy         v3, v1       # v3 ← v1
vstore        v3           # memory[vm3] ← v3
# 收尾
vreduce.sum   x6, v2       # x6 (t1) ← sum(v2)
vinsert       v4[0], x6    # v4[0] ← x6
vbroadcast    v4, v4[0]    # v4 ← broadcast(sum)
vrcp.approx   v4, v4       # v4 ← 1/v4
vextract      x7, v4[0]    # x7 (t2) ← v4[0]
```

除法被推迟：这里不做逐元素除法，只算一个倒数，留给 pv 最后乘。−inf 经 `vsubx` / `vmulx` / `vexp2.approx` 自然变 0，所以 padding key 不进 softmax。

=== `qwen3_pv`

给定未归一化概率 $tilde(p)_j$、value 向量 $bold(V)_j in RR^(d_"head")$ 和 softmax 返回的 $r = 1 / (sum_j tilde(p)_j)$，输出

$ bold(o) = r sum_j tilde(p)_j bold(V)_j. $

除法折成末尾乘一次倒数。

```asm
# 4 个 f32 累加器 v16..v19（对应 hd 的 4 个 chunk）
vfill       v16, 0              # v16 ← 0
vfill       v17, 0              # v17 ← 0
vfill       v18, 0              # v18 ← 0
vfill       v19, 0              # v19 ← 0
# 对每个 key j：
lw          x5, 0(x28)          # x5 (t0) ← probs[j]（x28 = t3）
vinsert     v20[0], x5          # v20[0] ← t0
vbroadcast  v20, v20[0]         # v20 ← broadcast(p_j)
vload       v12                 # v12 ← V_j 的下一块
vfmadd      v16, v12, v20, v16  # v16 ← v12 · v20 + v16
# v17..v19 同理
vmulx       v16, v16, x16       # v16 ← v16 × rcp   (x16 = a6)
vstore      v16                 # memory[vm16] ← v16
```

attention 的三个核函数（scores/softmax/pv）加起来就是标准 flash 式两遍结构，只不过按这个 ISA 的原语（fmadd/reduce/exp2/rcp）表达。

=== `qwen3_silu_mul`

给定 $bold(g), bold(u) in RR^n$，输出 $bold(o) in RR^n$：

$
  bold(o) = bold(g) dot.o sigma(bold(g)) dot.o bold(u), quad sigma(g) = 1 / (1 + e^(-g)).
$

其中 $sigma$ 是 SiLU 的 sigmoid 部分。

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

=== `qwen3_add`

残差：

$ bold(o) = bold(x) + bold(y). $

```asm
vload   v0          # v0 ← dst
vload   v1          # v1 ← src
vadd    v0, v0, v1  # v0 ← v0 + v1
vcopy   v2, v0      # v2 ← v0
vstore  v2          # memory[vm2] ← v2
```

三个自增描述符，循环 n/32 次，全算子里最简单的一个。

=== `qwen3_argmax`

给定 logits $bold(z) in RR^V$，greedy 取样返回

$ i^* = arg max_i z_i. $

难点是"跨 chunk 的全局 argmax"用无分支方式做：

```asm
x18 = -inf, x19 = 0          # x18 (s2) ← 全局最优值，x19 (s3) ← 最优下标
# 对每 32 个 logits：
vreduce.argmax  x5, x6, v1    # x5 (t0) ← argmax(v1)，x6 (t1) ← max(v1)
vinsert         v2[0], x18    # v2[0] ← s2 (x18)
vinsert         v2[1], x6     # v2[1] ← x6
vreduce.argmax  x28, x30, v2  # x28 (t3) ← argmax(v2)，x30 (t5) ← max(v2)
beqz            x28, skip     # 本块没赢就跳过
x18 = x6; x19 = x29 + x5     # 本块赢：更新全局值和下标
```

用 2-lane 向量的 argmax 当"选择器",tie 时取下标小者（平局保旧值），这正是手册里 argmax 的 NaN/平局规则。

== 指令族落点总表

#figure(
  three-line-table([
    | *计算*                                        | *kernel*                    | *主要 NPU 指令族*                                                                           |
    | :-------------------------------------------- | :-------------------------- | :------------------------------------------------------------------------------------------ |
    | RMSNorm / 残差 / softmax / SiLU               | 向量逐元素                  | `vload`/`vstore`, `vadd`/`vsub`/`vmul`, `vfmadd`, `vexp2`/`vrsqrt`/`vrcp`, `vfill`/`fillx`  |
    | 归约 (sumsq/max/sum)                          | 同上                        | `vreduce.*`, `areduce.absmax`                                                               |
    | 激活量化                                      | `quant_act` / `quant_rows`  | `aload`, `tquant.rows` 外部 scale (QNT)                                                     |
    | decode 投影（$1 times k times W$）            | `matvec_q`                  | `tload`, `extract.row`, `bdot.nt.acc`, `vcvt`, `vmul(x)`                                    |
    | prefill 投影（$32 times k times W$）          | `matmul_q`                  | `tload`（含转置加载）, `mma.nn.zero/acc`, `acvt`, `amulv.row/col`, `astore`                 |
    | 嵌入查表                                      | `embed`                     | `tload`, `tdequant.rows` (QNT), `astore`                                                    |
    | 采样                                          | `argmax`                    | `vreduce.argmax`（双目的 R4 变体）                                                          |
    | 全部 kernel 的前奏                            | 配置                        | `cfg.seti`/`setx`/`setw`/`copy`                                                             |
    | KV 追加、prompt/EOS 判断、掩码补 $-infinity$  | —                           | 标量 RV64（刻意留标量侧的小工作量）                                                         |
  ]),
  caption: [计算步骤到 NPU 指令族的映射],
  numbering: none,
)

#note[一个贯穿全局的设计要点：kernel 之间靠*寄存器驻留约定*协作（`t2..t4` 激活 tile、`v30` 的激活 scale、`tm1` 的 transform 用毕恢复），配置寄存器与访存描述符的自增模式（`inc_mode` 沿行/沿列）让一条 `tload`/`vload` 就把"加载下一块"的地址推进自动化，标量侧只做维度计算和循环控制 —— 这正是 ISA 设计里"配置与访存描述符绑定、访存自增"在真实负载上的用法。]
