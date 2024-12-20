#!/bin/bash

#if [ "$#" -ne 7 ]; then
#    echo "Illegal number of parameters"
#    echo "Usage: ./build_champsim.sh [branch_pred] [l1d_pref] [l2c_pref] [llc_pref] [llc_repl] [num_core]"
#    exit 1
#fi

# ChampSim configuration
BRANCH=bimodal           # branch/*.bpred
L1I_PREFETCHER=no   # prefetcher/*.l1i_pref
L1D_PREFETCHER=pmp   # prefetcher/*.l1d_pref
L2C_PREFETCHER=no  # prefetcher/*.l2c_pref
LLC_PREFETCHER=no   # prefetcher/*.llc_pref
	
L1I_REPLACEMENT=lru   # prefetcher/*.l1i_repl
L1D_REPLACEMENT=lru   # prefetcher/*.l1d_repl
L2C_REPLACEMENT=lru   # prefetcher/*.l2c_repl
LLC_REPLACEMENT=lru  # replacement/*.llc_repl
NUM_CORE=1         # tested up to 8-core system

BW=
LLC=
############## Some useful macros ###############
BOLD=$(tput bold)
NORMAL=$(tput sgr0)
#################################################

# Sanity check
if [ ! -f ./branch/${BRANCH}.bpred ]; then
    echo "[ERROR] Cannot find branch predictor"
	echo "[ERROR] Possible branch predictors from branch/*.bpred "
    find branch -name "*.bpred"
    exit 1
fi

if [ ! -f ./prefetcher/${L1I_PREFETCHER}.l1i_pref ]; then
    echo "[ERROR] Cannot find L1I prefetcher"
	echo "[ERROR] Possible L1I prefetchers from prefetcher/*.l1i_pref "
    find prefetcher -name "*.l1i_pref"
    exit 1
fi

if [ ! -f ./prefetcher/${L1D_PREFETCHER}.l1d_pref ]; then
    echo "[ERROR] Cannot find L1D prefetcher"
	echo "[ERROR] Possible L1D prefetchers from prefetcher/*.l1d_pref "
    find prefetcher -name "*.l1d_pref"
    exit 1
fi

if [ ! -f ./prefetcher/${L2C_PREFETCHER}.l2c_pref ]; then
    echo "[ERROR] Cannot find L2C prefetcher"
	echo "[ERROR] Possible L2C prefetchers from prefetcher/*.l2c_pref "
    find prefetcher -name "*.l2c_pref"
    exit 1
fi

if [ ! -f ./prefetcher/${LLC_PREFETCHER}.llc_pref ]; then
    echo "[ERROR] Cannot find LLC prefetcher"
	echo "[ERROR] Possible LLC prefetchers from prefetcher/*.llc_pref "
    find prefetcher -name "*.llc_pref"
    exit 1
fi

if [ ! -f ./replacement/${LLC_REPLACEMENT}.llc_repl ]; then
    echo "[ERROR] Cannot find LLC replacement policy"
	echo "[ERROR] Possible LLC replacement policy from replacement/*.llc_repl"
    find replacement -name "*.llc_repl"
    exit 1
fi

# Check num_core
re='^[0-9]+$'
if ! [[ $NUM_CORE =~ $re ]] ; then
    echo "[ERROR]: num_core is NOT a number" >&2;
    exit 1
fi

# Check for multi-core
if [ "$NUM_CORE" -gt "1" ]; then
    echo "Building multi-core ChampSim..."
    sed -i.bak 's/\<NUM_CPUS 1\>/NUM_CPUS '${NUM_CORE}'/g' inc/champsim.h
    # if [ "$NUM_CORE" -eq "8" ]; then
    #     echo "Enlarge memory for 8 cores"
	#     sed -i.bak 's/\<DRAM_CHANNELS 1\>/DRAM_CHANNELS 4/g' inc/champsim.h
	#     sed -i.bak 's/\<LOG2_DRAM_CHANNELS 0\>/LOG2_DRAM_CHANNELS 2/g' inc/champsim.h
    # else
	sed -i.bak 's/\<DRAM_CHANNELS 1\>/DRAM_CHANNELS 2/g' inc/champsim.h
	sed -i.bak 's/\<LOG2_DRAM_CHANNELS 0\>/LOG2_DRAM_CHANNELS 1/g' inc/champsim.h
    # fi
else
    if [ "$NUM_CORE" -lt "1" ]; then
        echo "Number of core: $NUM_CORE must be greater or equal than 1"
        exit 1
    else
        echo "Building single-core ChampSim..."
    fi
fi
echo

if [ "$BW" = "Low" ]; then
    echo "Building Low Bandwidth Model"
    sed -i.bak 's/\<DRAM_IO_FREQ 3200\>/DRAM_IO_FREQ 1600/g' inc/champsim.h
elif [ "$BW" = "High" ]; then
    echo "Building High Bandwidth Model"
    sed -i.bak 's/\<DRAM_IO_FREQ 3200\>/DRAM_IO_FREQ 4800/g' inc/champsim.h
elif [ "$BW" = "ExLow" ]; then
    echo "Building Extremely Low Bandwidth Model"
    sed -i.bak 's/\<DRAM_IO_FREQ 3200\>/DRAM_IO_FREQ 800/g' inc/champsim.h
elif [ "$BW" = "ExHigh" ]; then
    echo "Building Extremely High Bandwidth Model"
    sed -i.bak 's/\<DRAM_IO_FREQ 3200\>/DRAM_IO_FREQ 6400/g' inc/champsim.h
fi

if [ "$LLC" = "LLC_Low" ]; then
    echo "Building Low LLC Capacity Model"
    sed -i.bak "s/\<LLC_SET NUM_CPUS\*2048\>/LLC_SET NUM_CPUS*512/g" inc/cache.h
fi

# Change prefetchers and replacement policy
cp branch/${BRANCH}.bpred branch/branch_predictor.cc
cp prefetcher/${L1I_PREFETCHER}.l1i_pref prefetcher/l1i_prefetcher.cc
cp prefetcher/${L1D_PREFETCHER}.l1d_pref prefetcher/l1d_prefetcher.cc
cp prefetcher/${L2C_PREFETCHER}.l2c_pref prefetcher/l2c_prefetcher.cc
cp prefetcher/${LLC_PREFETCHER}.llc_pref prefetcher/llc_prefetcher.cc
cp replacement/${L1I_REPLACEMENT}.l1i_repl replacement/l1i_replacement.cc
cp replacement/${L1D_REPLACEMENT}.l1d_repl replacement/l1d_replacement.cc
cp replacement/${L2C_REPLACEMENT}.l2c_repl replacement/l2c_replacement.cc
cp replacement/${LLC_REPLACEMENT}.llc_repl replacement/llc_replacement.cc

# Build
mkdir -p bin
rm -f bin/champsim
make clean
make

# Sanity check
if [ "$?" != 0 ]; then
    echo "Fail to build ChampSim!"
    echo ""
    exit 1
fi

echo ""
if [ ! -f bin/champsim ]; then
    echo "${BOLD}ChampSim build FAILED!"
    echo ""
    exit 1
fi

# REPL="NotAffectRepl"

echo "${BOLD}ChampSim is successfully built"
echo "Branch Predictor: ${BRANCH}"
echo "L1I Prefetcher: ${L1I_PREFETCHER}"
echo "L1D Prefetcher: ${L1D_PREFETCHER}"
echo "L2C Prefetcher: ${L2C_PREFETCHER}"
echo "LLC Prefetcher: ${LLC_PREFETCHER}"
echo "LLC Replacement: ${LLC_REPLACEMENT}"
echo "Cores: ${NUM_CORE}"
BINARY_NAME="${BRANCH}-${L1I_PREFETCHER}-${L1D_PREFETCHER}-${L2C_PREFETCHER}-${LLC_PREFETCHER}-${LLC_REPLACEMENT}-${NUM_CORE}core${BW}${LLC}"
echo "Binary: bin/${BINARY_NAME}"
echo ""
mv bin/champsim bin/${BINARY_NAME}


# Restore to the default configuration
sed -i.bak 's/\<NUM_CPUS '${NUM_CORE}'\>/NUM_CPUS 1/g' inc/champsim.h
sed -i.bak 's/\<DRAM_CHANNELS 2\>/DRAM_CHANNELS 1/g' inc/champsim.h
sed -i.bak 's/\<LOG2_DRAM_CHANNELS 1\>/LOG2_DRAM_CHANNELS 0/g' inc/champsim.h
sed -i.bak 's/\<DRAM_IO_FREQ 1600\>/DRAM_IO_FREQ 3200/g' inc/champsim.h
sed -i.bak 's/\<DRAM_IO_FREQ 4800\>/DRAM_IO_FREQ 3200/g' inc/champsim.h
sed -i.bak 's/\<DRAM_IO_FREQ 800\>/DRAM_IO_FREQ 3200/g' inc/champsim.h
sed -i.bak 's/\<DRAM_IO_FREQ 6400\>/DRAM_IO_FREQ 3200/g' inc/champsim.h
sed -i.bak "s/\<LLC_SET NUM_CPUS\*512\>/LLC_SET NUM_CPUS*2048/g" inc/cache.h

#cp branch/bimodal.bpred branch/branch_predictor.cc
#cp prefetcher/no.l1i_pref prefetcher/l1i_prefetcher.cc
#cp prefetcher/no.l1d_pref prefetcher/l1d_prefetcher.cc
#cp prefetcher/no.l2c_pref prefetcher/l2c_prefetcher.cc
#cp prefetcher/no.llc_pref prefetcher/llc_prefetcher.cc
#cp replacement/lru.llc_repl replacement/llc_replacement.cc
