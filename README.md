# Utility scripts to benchmark vllm 

## Run benchmarks
- Update launch_data.json with server parameters
- Update random_bench_data.json with `vllm bench serve --dataset=random` parameters
- run.sh reads the JSONs using jq and essentially does,

  for server_config in read(launch_data.json)
	launch_server server_config # from vanilla_run_utils.sh
	for bench_config in read(random_bench_data.json)
		run_benchmark_serving_random bench_config # from vanilla_run_utils.sh
	kill server
	wait for 1 minute for the server to die
