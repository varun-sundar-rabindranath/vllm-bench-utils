#!/bin/bash
set -e
set -u

timestamp=$(date +%s)

LAUNCH_DATA_JSON="./launch_data.json"
BENCH_DATA_JSON="./random_bench_data.json"
#LAUNCH_DATA_JSON="./test_launch_data.json"
#BENCH_DATA_JSON="./test_bench_data.json"
RESULT_DIR="./bench_results"

## Benchmark server stuff
server_pid=""
source vanilla_run_utils.sh
source utils.sh

# Server ARGS
SERVER_END_SLEEP=60
SERVER_PORT=9010
SERVER_LOG_FILE="./logs/server_logs_${timestamp}.txt"

echo "Server logs stored at ${SERVER_LOG_FILE} ..."

# DEFAULTS
DATA_PARALLEL_SIZE=1
TENSOR_PARALLEL_SIZE=1
EP=0

DRY_RUN=false

if ${DRY_RUN};
then
	SERVER_END_SLEEP=1
	NUM_BENCH_RUNS=1
fi

num_launches=$(jq '. | length' ${LAUNCH_DATA_JSON})
num_benches=$(jq '. | length' ${BENCH_DATA_JSON})
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

	envs=$(jq -r ".[$i].envs" ${LAUNCH_DATA_JSON})
	if [ "$envs" = "null" ]
	then
		envs=""
	fi

	echo "Bench : model=${model}, dp_size=${dp_size}, tp_size=${tp_size}, ep=${ep}, envs=${envs} ..."

	export_envs "${envs}"

	# launch server
	launch_server $model ${dp_size} ${tp_size} ${ep} ${SERVER_PORT} ${SERVER_LOG_FILE}

	for ((j = 0 ; j < ${num_benches} ; j++ ));
	do
		# extract bench options
		num_prompts=$(jq ".[$j].num_prompts" ${BENCH_DATA_JSON})
		exit_if_null $num_prompts "num_prompts"

		isl=$(jq ".[$j].isl" ${BENCH_DATA_JSON})
		exit_if_null $isl "isl"

		osl=$(jq ".[$j].osl" ${BENCH_DATA_JSON})
		exit_if_null $osl "osl"

		rr=$(jq ".[$j].request_rate" ${BENCH_DATA_JSON})
		if [ "$rr" = "null" ]
		then
			rr=${num_prompts} # same as inf
		fi

		echo "	num_prompts=${num_prompts}, isl=${isl}, osl=${osl}, rr=${rr} ..."
		 
		run_benchmark_serving_random  $model $num_prompts $isl $osl $rr $SERVER_PORT $RESULT_DIR
	done

	unset_envs "${envs}"

	if ! ${DRY_RUN};
	then
		kill ${server_pid}
	fi

	echo "Waiting ${SERVER_END_SLEEP} secs for server end..."
	sleep ${SERVER_END_SLEEP}

done
