#!/bin/bash
set -e
set -u
set -x

## Benchmark server stuff
server_pid=""
source vanilla_run_utils.sh

SERVER_START_SLEEP=180
SERVER_END_SLEEP=60

#MODELS=("meta-llama/Llama-2-7b-hf" "meta-llama/Llama-2-7b-hf" "meta-llama/Llama-2-7b-chat-hf")
#LORA_ADAPTERS=("n/a" "yard1/llama-2-7b-sql-lora-test" "xtuner/Llama-2-7b-qlora-moss-003-sft")
#LORA_RANKS=(0 8 64)

MODELS=("meta-llama/Llama-4-Scout-17B-16E")
LORA_ADAPTERS=("n/a")
LORA_RANKS=(0)


# Server ARGS
MODEL_ID=0
SERVER_PORT=9010
ENGINE=1

# Benchmark ARGS
NUM_PROMPTS=1000
REQUEST_RATE="inf"
RESULT_DIR="./benchmark_serving_results"
NUM_BENCH_RUNS=2

MODEL=${MODELS[${MODEL_ID}]}
LORA_ADAPTER=${LORA_ADAPTERS[${MODEL_ID}]}
MAX_LORA_RANK=${LORA_RANKS[${MODEL_ID}]}

DRY_RUN=false

if ${DRY_RUN};
then
	SERVER_END_SLEEP=1
	SERVER_START_SLEEP=1
	NUM_BENCH_RUNS=1
fi

export RECORD_TIMES='1'
launch_server ${MAX_LORA_RANK} ${ENGINE} ${MODEL} ${LORA_ADAPTER} ${SERVER_PORT} ${DRY_RUN}


echo "Waiting ${SERVER_START_SLEEP} secs for server (${server_pid}) start..."
sleep ${SERVER_START_SLEEP}

run_benchmark_serving ${MAX_LORA_RANK} ${MODEL} ${NUM_PROMPTS} ${REQUEST_RATE} ${SERVER_PORT} ${RESULT_DIR} ${NUM_BENCH_RUNS} ${DRY_RUN}

if ! ${DRY_RUN};
then
	kill ${server_pid}
fi

echo "Waiting ${SERVER_END_SLEEP} secs for server end..."
sleep ${SERVER_END_SLEEP}
