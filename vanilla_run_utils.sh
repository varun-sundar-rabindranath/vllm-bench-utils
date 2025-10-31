

launch_server() {
	model=$1
	dp_size=$2
	tp_size=$3
	ep=$4
	server_port=$5
	server_log_file=$6

	echo "Launching Server for ${model} - DP=${dp_size} TP=${tp_size} EP=${ep} ..."

	EP_ARGS=""
	if [ ${ep} -eq 1 ]; then
		EP_ARGS="--enable-expert-parallel"
	fi

	set -x 
	vllm serve  $model \
		--trust-remote-code \
		--tensor-parallel-size ${tp_size} \
		--data-parallel-size ${dp_size}  \
		${EP_ARGS} \
		--no-enable-prefix-caching \
		--port ${server_port} > ${server_log_file} 2>&1 &
	set +x
			
	#> server_log.txt 2>&1 &
	server_pid=$!
	# echo pid so the caller can capture it. 
	#echo "----${server_pid}----"
}

run_benchmark_serving_sharegpt() {

	model=$1
	num_prompts=$2
	request_rate=$3
	server_port=$4
	result_dir=$5
	result_filename=$6

	local FILE=ShareGPT_V3_unfiltered_cleaned_split.json
  	if [ ! -f "$FILE" ]; then
		echo "Downloading ShareGPT.."
		wget https://huggingface.co/datasets/anon8231489123/ShareGPT_Vicuna_unfiltered/resolve/main/ShareGPT_V3_unfiltered_cleaned_split.json
	fi

	set -x
	vllm bench serve \
	--model ${model} \
	--dataset-name sharegpt \
	--dataset-path ./ShareGPT_V3_unfiltered_cleaned_split.json \
	--num-prompts ${num_prompts} \
	--request-rate ${request_rate} \
	--ignore-eos \
	--port ${server_port} \
	--result-dir ${result_dir} \
	--result-filename ${result_filename} \
        --save-result
	set +x

}

run_benchmark_serving_random() {
	model=$1
	num_prompts=$2
	isl=$3
	osl=$4
	rr=$5
	server_port=$6
	result_dir=$7
	result_filename=$8

	set -x
	vllm bench serve \
		--model ${model} \
		--dataset-name random \
		--num-prompts ${num_prompts} \
		--random-input-len ${isl} \
		--random-output-len ${osl} \
		--request-rate ${rr} \
		--ignore-eos \
		--port ${server_port} \
		--backend vllm \
		--result-dir ${result_dir} \
		--result-filename ${result_filename} \
        	--save-result
	set +x
}

run_bench() {
	model=$1
	SERVER_PORT=$2
	BENCH_DATA_JSON=$3
	RESULT_DIR=$4
	SERVER_DESCRIPTION=$5

	num_benches=$(jq '. | length' ${BENCH_DATA_JSON})
	for ((j = 0 ; j < ${num_benches} ; j++ ));
	do
		bench_timestamp=$(date +%s)

		# extract bench options

		bench_type=$(jq -r ".[$j].type" ${BENCH_DATA_JSON})
		exit_if_null $bench_type "BenchType"

		num_prompts=$(jq -r ".[$j].num_prompts" ${BENCH_DATA_JSON})
		exit_if_null $num_prompts "num_prompts"

		rr=$(jq -r ".[$j].rr" ${BENCH_DATA_JSON})
		if [ "$rr" = "null" ]
		then
			rr=${num_prompts} # same as inf
		fi

		isl=$(jq -r ".[$j].isl" ${BENCH_DATA_JSON})

		osl=$(jq -r ".[$j].osl" ${BENCH_DATA_JSON})

		RESULT_FILENAME="${SERVER_DESCRIPTION}_${bench_type}_${num_prompts}_${rr}_${isl}_${osl}_${bench_timestamp}.json"

		echo " bench_type=${bench_type}, num_prompts=${num_prompts}, rr=${rr}, isl=${isl}, osl=${osl} -> ${RESULT_FILENAME} ..."

		if [ "$bench_type" == "sharegpt" ];
		then
			run_benchmark_serving_sharegpt  $model $num_prompts $rr $SERVER_PORT $RESULT_DIR $RESULT_FILENAME
		elif [ "$bench_type" == "random" ];
		then
			exit_if_null $isl "isl"
			exit_if_null $osl "osl"
			run_benchmark_serving_random  $model $num_prompts $isl $osl $rr $SERVER_PORT $RESULT_DIR $RESULT_FILENAME
		else
			echo "Invalid bench_type ${bench_type}"
		fi
	done

}

run_lm_eval() {

	model=$1
	SERVER_PORT=$2
	RESULT_DIR=$3
	SERVER_DESCRIPTION=$4

	RESULT_FILENAME="${RESULT_DIR}/eval_${SERVER_DESCRIPTION}.txt"

	endpoint="http://localhost:${SERVER_PORT}"

	timeout=600
	echo -n "Waiting for server to be up (timeout=${timeout}s): "
	while [ $timeout -gt 0 ]
	do
		set +e
		http_code=$(curl -s -o /dev/null -i  -w "%{http_code}" ${endpoint}/ping)
		set -e
		if [ "${http_code}" == "200" ]; then
			break
		else
			echo -n "."
			timeout=$(( $timeout - 2 ))
			sleep 2
		fi
	done
	echo ""

	set -x
	lm_eval \
		--model local-completions \
		--tasks gsm8k \
		--model_args model=${model},base_url=${endpoint}/v1/completions,num_concurrent=30,max_retries=3 \
		--limit 100 2>&1 | tee ${RESULT_FILENAME}
	set +x
}