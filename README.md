# CS683-project

Champsim Simulator and SPECCPU2017 traces used. 

/PMP/prefetcher has implementation of bingo and pmp L1D prefetchers.

/PMP/logs has simulation results for SPECCPU17 traces for bingo, pmp and baseline (no) prefetchers.

/plots has all the relavant plots shown in the presentation.

Build using `build_champsim.sh` and run using `bin/<binary> -warmup_instructions <num> -simulation_instructions <num> -traces <trace_path>`. Our simulation results were through 50M warmup instructions and 200M simulation instructions.

PCR and PDR values using (PC, Trigger Offset) as features can be found in the log files at /PMP/logs/metrics/.
PCR and PDR values after merging can be found in the log files at /PMP/logs/pmp_metrics/.

The implementations of these metrics can be found in the files - cache.cc, pmp.l1d_pref, patterns.h and main.cc.
The implementation of the PMP prefetcher at the L2 cache can be found in pmp.l2c_pref.
