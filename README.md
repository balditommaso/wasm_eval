# Real-Time Evaluation of WebAssembly Runtimes

This repository contains the benchmarking infrastructure for evaluating the performance overhead introduced by WebAssembly (WASM) runtimes in real-time Linux environments. The focus is on measuring latency jitter using a WASM-compiled version of `cyclictest`.

## Overview

The goal of this project is to quantify the impact of WASM runtimes (such as [WasmEdge](https://wasmedge.org/)) on the deterministic behavior required for real-time tasks. We measure the latency spikes (jitter) that occur when running periodic tasks within a WASM execution environment on a Linux kernel patched with `PREEMPT_RT`.

## Key Components

- **`cyclictest.c`**: A custom C-based latency measurement tool that simulates periodic task execution. It is compiled to `.wasm` using the `wasi-sdk`.
- **`parse_cyclictest.py`**: A utility to parse the raw text output from the `cyclictest` runs into structured CSV files for analysis.
- **`plot.ipynb`**: A Jupyter Notebook used to generate Cumulative Distribution Function (CDF) plots and other visualizations to compare the latency profiles of different runtimes and configurations.

## Prerequisites

- A Linux environment (preferably with access to `sudo` for kernel/mounting operations).
- **WASI SDK**: [wasi-sdk-34.0-x86_64-linux](https://github.com/WebAssembly/wasi-sdk) (included in this repo).
- **WebAssembly Runtime**: WasmEdge.
- **Tools**: `stress-ng`.

## Experimental env

Experiments have been accomplished on Ubuntu 24 with real-time kernel:
 `linux-image-realtime 6.8.1-1015.16 amd64`

## Getting Started

### 1. Prepare the Real-Time Environment

Run the provided script to intsall the stress tool used in our benchmarks.
```
sudo apt instal stress-ng
```

### 2. Compile the Baseline and WebAssembly Benchmark

The benchmark is written in C and must be compiled both with `gcc` and with the WASI SDK.

```
gcc cyclictest.c -o cyclictest --static 
```

```
./wasi-sdk-34.0-x86_64-linux/bin/clang \
  --sysroot=./wasi-sdk-34.0-x86_64-linux/share/wasi-sysroot \
  -o cyclictest_aot.wasm cyclictest.c
```

### 3. Running Experiments

Experiments are typically conducted by executing the `.wasm` module via a runtime (e.g., `wasmedge`) on the target RT-patched system. Different configurations are tested, including:
- **AOT (Ahead-of-Time) Compilation**
- **JIT (Just-in-Time) Compilation**

- **Baseline (Native/No WASM overhead)**
- **Stress testing**: Running the benchmark under system load to observe impact on determinism.


### 4. Data Analysis and Visualization

Once the results are extracted, you can process the raw trace files into CSV format:

```bash
python3 parse_cyclictest.py <path_to_trace_file> <output_file.csv>
```

Finally, open `plot.ipynb` in a Jupyter environment to generate the comparison plots.

## Results

The `results/` directory contains the processed data (CSV) and raw traces used for the final evaluation. 

```
sudo chrt -f 99 ./cyclictest 600000 1000 > results/baseline.txt
```

```
sudo chrt -f 99 wasmedge/bin/wasmedge --run-mode=jit cyclictest.wasm 600000 1000 > results/wasmedge_JIT.txt
```

```
sudo chrt -f 99 wasmedge/bin/wasmedge cyclictest.wasm 600000 1000 > results/wasmedge_AOT.txt
```

```
stress-ng --cpu $(nproc) --io 4 --vm 2 --vm-bytes 1G --timeout 15m & sudo chrt -f 99 ./cyclictest 600000 1000 > results/baseline_with_stress.txt
```

```
stress-ng --cpu $(nproc) --io 4 --vm 2 --vm-bytes 1G --timeout 15m & sudo chrt -f 99 wasmedge/bin/wasmedge --run-mode=jit cyclictest.wasm 600000 1000 > results/wasmedge_JIT_with_stress.txt
```

```
stress-ng --cpu $(nproc) --io 4 --vm 2 --vm-bytes 1G --timeout 15m & sudo chrt -f 99 wasmedge/bin/wasmedge cyclictest.wasm 600000 1000 > results/wasmedge_AOT_with_stress.txt
```

### convert the benchmarks in CSV 

```
python parse_cyclictest.py results/baseline.txt results/baseline.csv
python parse_cyclictest.py results/wasmedge_JIT.txt results/wasmedge_JIT.csv
python parse_cyclictest.py results/wasmedge_AOT.txt results/wasmedge_AOT.csv

python parse_cyclictest.py results/baseline_with_stress.txt results/baseline_with_stress.csv
python parse_cyclictest.py results/wasmedge_AOT_with_stress.txt results/wasmedge_AOT_with_stress.csv
python parse_cyclictest.py results/wasmedge_JIT_with_stress.txt results/wasmedge_JIT_with_stress.csv
```


