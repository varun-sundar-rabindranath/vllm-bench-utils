launch_server() {
    	mlr=$1
	engine=$2
	model=$3
	lora_adapter=$4
	server_port=$5
	dry_run=$6
    	export VLLM_USE_V1=$engine

	OPT_FLAGS=""
	if [ ${engine} -eq 1 ]; then
		OPT_FLAGS="-O 0"
	fi

	LORA_ARGS=""
	if ! [ ${mlr} -eq 0 ]; then
		LORA_ARGS=" --enable-lora "
		LORA_ARGS="${LORA_ARGS} --max-loras 4 "
		LORA_ARGS="${LORA_ARGS} --max-lora-rank ${mlr} "
		LORA_ARGS="${LORA_ARGS} --lora-modules lora0=${lora_adapter} lora1=${lora_adapter} lora2=${lora_adapter} lora3=${lora_adapter}"
	fi

	echo "Launching Server for V${engine}, max_lora_rank ${mlr} ..."

	if ${dry_run};
	then
		echo
		echo "Server command :"
		echo "vllm serve  ${model} \
		${LORA_ARGS} \
		${OPT_FLAGS} \
                --tensor-parallel-size 4 \
                --enable-expert-parallel \
		--no-enable-prefix-caching \
		--port ${server_port} \
		--disable-log-stats & "
		echo
		return
	fi

	vllm serve  ${model} \
		${LORA_ARGS} \
		${OPT_FLAGS} \
                --tensor-parallel-size 4 \
                --enable-expert-parallel \
		--no-enable-prefix-caching \
		--port ${server_port} \
		--disable-log-stats &
			
	#> server_log.txt 2>&1 &
	server_pid=$!
	# echo pid so the caller can capture it. 
	#echo "----${server_pid}----"
}

run_benchmark_serving() {

	mlr=$1
	model=$2
	num_prompts=$3
	request_rate=$4
	server_port=$5
	result_dir=$6
	num_bench_runs=$7
	dry_run=$8

	LORA_ARGS=""
	if ! [ ${mlr} -eq 0 ]; then
		LORA_ARGS="${LORA_ARGS} --lora-modules lora0 lora1 lora2 lora3 "
		#LORA_ARGS="${LORA_ARGS} --max-lora-rank ${mlr}"
	fi

	for (( i=1; i<=${num_bench_runs}; i++ ))
	do

		if $dry_run;
		then
			echo
			echo "	python3 benchmarks/benchmark_serving.py \
					--model ${model} \
					--dataset-name sharegpt \
					--dataset-path ./ShareGPT_V3_unfiltered_cleaned_split.json \
					--num-prompts ${num_prompts} \
					--request-rate ${request_rate} \
					${LORA_ARGS} \
					--seed ${i} \
					--port ${server_port} \
					--result-dir ${result_dir} \
					--save-result"
			continue
		fi

		python3 benchmarks/benchmark_serving.py \
				--model ${model} \
				--dataset-name sharegpt \
				--dataset-path ./ShareGPT_V3_unfiltered_cleaned_split.json \
				--num-prompts ${num_prompts} \
				--request-rate ${request_rate} \
				${LORA_ARGS} \
				--seed ${i} \
				--port ${server_port} \
				--result-dir ${result_dir} \
				--save-result
	done

}
