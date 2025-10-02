

launch_server() {
	model=$1
	dp_size=$2
	tp_size=$3
	ep=$4
	server_port=$5

	echo "Launching Server for ${model} - DP=${dp_size} TP=${tp_size} EP=${ep} ..."

	EP_ARGS=""
	if [ ${ep} -eq 1 ]; then
		EP_ARGS="--enable-expert-parallel"
	fi

    export VLLM_ALL2ALL_BACKEND=${vllm_all2all_backend}
	export VLLM_MXFP4_USE_MARLIN=${vllm_mxfp4_use_marlin}

	vllm serve  ${model} \
		--trust-remote-code \
		--tensor-parallel-size ${tp_size} \
		--data-parallel-size ${dp_size}  \
		${EP_ARGS} \
		--no-enable-prefix-caching \
		--port ${server_port}  &
			
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

	vllm bench serve
	--model ${model} \
	--dataset-name sharegpt \
	--dataset-path ./ShareGPT_V3_unfiltered_cleaned_split.json \
	--num-prompts ${num_prompts} \
	--request-rate ${request_rate} \
	--ignore-eos \
	--port ${server_port} \

}

run_benchmark_serving_random() {
	model=$1
	num_prompts=$2
	isl=$3
	osl=$4
	server_port=$5
	result_dir=$6

	vllm bench serve \
		--model ${model} \
		--dataset-name random \
		--num-prompts ${num_prompts} \
		--random-input-len ${isl} \
		--random-output-len ${osl} \
		--ignore-eos \
		--port ${server_port} \
		--backend vllm \
		--result-dir ${result_dir} \
        --save-result
}