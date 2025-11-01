#!/bin/bash
set -e
set -u

# Process CLI args
DO_BENCH=false
DO_LM_EVAL=false
DO_TEST_INIT=false
source cli.sh
do_what $@

timestamp=$(date +%s)

LAUNCH_DATA_JSON="./data/launch_data.json"
BENCH_DATA_JSON="./data/prefill_decode_mixed_bench_data.json"
#LAUNCH_DATA_JSON="./data/test_launch_data.json"
#BENCH_DATA_JSON="./data/test_bench_data.json"

RESULT_DIR="./bench_results"
SERVER_LOGS_DIR="./logs"
LM_EVAL_DIR="./lm_eval_results"

mkdir -p ${RESULT_DIR}
mkdir -p ${SERVER_LOGS_DIR}
mkdir -p ${LM_EVAL_DIR}

## Benchmark server stuff
server_pid=""
source vanilla_run_utils.sh
source utils.sh

# Server ARGS
SERVER_END_SLEEP=60
SERVER_PORT=9010

# DEFAULTS
DATA_PARALLEL_SIZE=1
TENSOR_PARALLEL_SIZE=1
EP=0
EAGER=0

DRY_RUN=false

if ${DRY_RUN};
then
	SERVER_END_SLEEP=1
	NUM_BENCH_RUNS=1
fi

set -x
## Nuke the torch.compile cache
rm -rf ~/.cache/vllm/torch_compile_cache
set +x

num_launches=$(jq '. | length' ${LAUNCH_DATA_JSON})
for ((i = 0 ; i < ${num_launches} ; i++ ));
do
	# extract server options
	model=$(jq -r ".[$i].model" ${LAUNCH_DATA_JSON})
	exit_if_null $model "model"

	dp_size=$(jq -r ".[$i].dp_size" ${LAUNCH_DATA_JSON})
    	if [ "$dp_size" = "null" ]
    	then
    	    dp_size=$DATA_PARALLEL_SIZE
    	fi

	tp_size=$(jq -r ".[$i].tp_size" ${LAUNCH_DATA_JSON})
    	if [ "$tp_size" = "null" ]
    	then
    	    tp_size=$TENSOR_PARALLEL_SIZE
    	fi

	ep=$(jq -r ".[$i].ep" ${LAUNCH_DATA_JSON})
    	if [ "$ep" = "null" ]
    	then
    	    ep=$EP
    	fi

	eager=$(jq -r ".[$i].eager" ${LAUNCH_DATA_JSON})
    	if [ "$eager" = "null" ]
    	then
    	    eager=$EAGER
    	fi

	envs=$(jq -r ".[$i].envs" ${LAUNCH_DATA_JSON})
	if [ "$envs" = "null" ]
	then
		envs=""
	fi

	echo "Process : model=${model}, dp_size=${dp_size}, tp_size=${tp_size}, ep=${ep}, eager=${eager}, envs=${envs} ..."

	export_envs "${envs}"

	# launch server
	if ! ${DRY_RUN};
	then
		launch_server $model ${dp_size} ${tp_size} ${ep} ${eager} ${SERVER_PORT} ${SERVER_LOGS_DIR}
		echo "server_pid=${server_pid}"
	fi

	server_description=""
	describe_server $model ${dp_size} ${tp_size} ${eager} "${envs}"
	SERVER_DESCRIPTION=${server_description}

	if ${DO_BENCH}; then
		run_bench ${model} ${SERVER_PORT} ${BENCH_DATA_JSON} ${RESULT_DIR} ${SERVER_DESCRIPTION} 
	fi

	if ${DO_LM_EVAL}; then
		run_lm_eval ${model} ${SERVER_PORT} ${LM_EVAL_DIR} ${SERVER_DESCRIPTION}
	fi

	if ${DO_TEST_INIT}; then
		run_test_init ${model} ${SERVER_PORT}
	fi

	unset_envs "${envs}"

	if ! ${DRY_RUN};
	then
		kill ${server_pid}
	fi

	echo "Waiting ${SERVER_END_SLEEP} secs for server end..."
	sleep ${SERVER_END_SLEEP}

done
