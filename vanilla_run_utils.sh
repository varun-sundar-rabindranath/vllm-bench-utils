

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
