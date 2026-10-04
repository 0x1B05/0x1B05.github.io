#import "../../index.typ": *
#import "../series.typ": arch-notes-series
#import "../_defs.typ": *
#import "@preview/tablem:0.3.0": three-line-table
#show: series-chapter.with(
  arch-notes-series,
  route: "docs/arch-notes/09-systolic-array/",
  title: "Systolic Array Architectures",
)

== Systolic Array Motivation

Goal: design an accelerator with:
- A simple, regular design with few unique parts.
- High concurrency and high performance.
- Balanced computation and I/O (memory) bandwidth.

Replace a single processing element (PE) with a regular array of PEs and carefully orchestrate data flow between them. The PEs collectively transform input data before returning output to memory. This maximizes computation performed on each data element brought from memory.

Memory is the heart, data is the blood, PEs are cells, and memory pulses data through the PEs.

== Why Systolic Architectures?

Data flows rhythmically from memory through many PEs before returning to memory, like blood flowing from a heart through cells and back. Many veins operate simultaneously, and the array can be multidimensional.

Compared with a conventional pipeline:
- Systolic arrays use individual PEs.
- The array can be nonlinear and multidimensional.
- PE connections can be multidirectional and have different speeds.
- PEs can have local memory and execute kernels rather than one pipeline stage.

== Convolution Example

Convolution is used for filtering, pattern matching, correlation, polynomial evaluation, and image processing. Convolutional neural networks can contain hundreds of convolutional layers.

For a 2D convolution with a 5x5 input, 3x3 kernel, stride 1, and padding 1, the output dimension is:

`(input + 2 * padding - kernel) / stride + 1`

A convolutional layer can be transformed into matrix multiplication by unrolling input features into a matrix and arranging filters as matrix rows/columns.

== Matrix Multiplication on a Systolic Array

For matrices `P`, `Q`, and `R`, a 2D array can stream values through PEs and keep the final result in PE accumulators:

`R = R + P * Q`

Each PE receives operands from neighboring PEs, performs multiply-accumulate, and forwards values rhythmically. Data movement and computation are overlapped.

== TPU as a Modern Systolic Array

Google's Tensor Processing Unit is a modern systolic-array accelerator. Its matrix unit contains a large regular array of multiply-accumulate PEs.

#three-line-table(
  columns: (1.1fr, 1.45fr, 1.45fr),
  inset: 5pt,
  align: left,
)[
  | *Generation* | *Key feature* | *Comparison* |
  | :----------- | :------------ | :---------- |
  | TPU1 | Inference-oriented matrix unit | 23 TOPS |
  | TPU2 | Four chips, HBM, floating-point support | 45 TFLOPS/chip; training and inference |
  | TPU3 | More HBM and matrix units | 90 TFLOPS/chip |
  | TPU4 | New ML applications and larger system | 250 TFLOPS/chip; 1 exaFLOPS/board |
]

Systolic arrays are attractive for machine learning because their regular data movement and high PE reuse provide high throughput with predictable bandwidth.

== Scheduling Data Through a Systolic Array

Systolic performance depends on *when* each operand enters the array, not only on the PE function. Neighboring PEs consume different matrix indices in the same cycle, so inputs are normally skewed in time.

For matrix multiplication `C[i,j] += A[i,k] * B[k,j]` on a two-dimensional array:

- Values from a row of `A` enter from the left and move right.
- Values from a column of `B` enter from the top and move down.
- PE `(i,j)` multiplies operands with the same `k`, accumulates into `C[i,j]`, and forwards both operands.
- Row `i` of `A` and column `j` of `B` are delayed so their first matching pair reaches PE `(i,j)` in the same cycle.

After the wavefront fills the array, many PEs perform one multiply-accumulate per cycle. The beginning and end have lower utilization because the wavefront has not filled or is draining.

For an `R x C` array processing an inner dimension `K`, a simplified completion time is approximately

`fill + useful computation + drain ~= (R - 1) + K + (C - 1)` cycles,

assuming one new operand per edge per cycle and no stalls. The exact convention changes with whether inputs and outputs are counted on boundary cycles, but the important point is that fill/drain cost is amortized by a sufficiently large tile.

== Data Reuse and Bandwidth Balance

Each operand fetched from memory should participate in many operations before leaving the array. In a matrix-multiply dataflow, an `A` value can be reused across a PE row and a `B` value across a PE column. Partial sums can remain stationary in PE accumulators.

#three-line-table(
  columns: (1.35fr, 1.9fr, 2.1fr),
  inset: 5pt,
  align: left,
)[
  | *Dataflow* | *What stays in a PE* | *What moves* |
  | :--------- | :------------------ | :----------- |
  | Output-stationary | Partial or final output | Inputs/weights traverse the array |
  | Weight-stationary | Filter or matrix weight | Activations and partial sums move |
  | Input-stationary | Input activation | Weights and partial sums move |
]

Choosing a dataflow changes local-storage demand, network traffic, and reuse. A high arithmetic peak is useless if edge bandwidth cannot inject operands or drain results. Tiling maps a large problem onto the finite array and local SRAM so reused data remains close to the PEs.

== One-Dimensional Convolution Pipeline

For `y[n] = w0*x[n] + w1*x[n-1] + w2*x[n-2]`, a linear systolic pipeline can store one weight per PE. Samples stream through the PEs, and a partial sum advances after every multiply-add. Once filled, the array can produce one output per cycle even though each output needs three multiplies and additions.

Separating multiply and add stages can increase overlap: while one sample is being multiplied in a PE, the previous product can advance through the adder. Correct input delays are essential so each output combines matching samples and weights.

== Programmability and Mapping

A fixed-function PE is efficient but supports only one narrow kernel. Programmability can be added by allowing each PE to store several weights, select among operations, use a local register file, or communicate along configurable routes.

The costs are larger PEs, control storage, less regular timing, and more energy per operation. A practical accelerator therefore chooses a point between a hardwired datapath and a general-purpose core.

The WARP computer used a linear array of programmable cells, demonstrating that systolic organization is not limited to a single arithmetic kernel. Modern tensor accelerators combine regular matrix units with vector/scalar units and software-managed SRAM for unsupported operations.

== Systolic Array Tradeoffs

Advantages:

- Regular layout, short local wires, and repeated PEs simplify physical design.
- Data reuse provides many operations per memory access.
- Deterministic movement makes throughput and buffering predictable.
- Deep spatial pipelines can sustain very high arithmetic utilization.

Limitations:

- Irregular control, sparse/indirect access, and small problems underutilize the array.
- Fill and drain overhead matters for small tiles.
- Edge bandwidth and local-buffer capacity constrain the usable array size.
- Mapping, tiling, padding, and skewing become software responsibilities.
- A shape mismatch between workload and array leaves PEs idle.

Systolic arrays are therefore strongest when the application exposes regular producer-consumer structure and substantial reuse. They complement rather than replace vector, GPU, and general-purpose execution.

