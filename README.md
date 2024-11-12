# CS683-project

Champsim Simulator and SPECCPU2017 traces used. 

/PMP/prefetcher has implementation of bingo and pmp L1D prefetchers.

/PMP/logs has simulation results for SPECCPU17 traces for bingo, pmp and baseline (no) prefetchers.

/plots has metrics plots for the results.

Build using `build_champsim.sh` and run using `bin/<binary> -warmup_instructions <num> -simulation_instructions <num> -traces <trace_path>`. Our simulation results were through 50M warmup instructions and 200M simulation instructions.

PCR and PDR values can be found now in the log files at /PMP/logs/metrics/.
