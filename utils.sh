

export_envs() {
	envs=$1

	keys=$(echo ${envs} | jq 'keys_unsorted')
	num_keys=$(echo ${envs} | jq '. | length')
	for ((key_idx = 0 ; key_idx < ${num_keys} ; key_idx++ ));
	do
		key=$keys[$key_idx]
		value=$(echo ${envs} | jq ".$key")
		export $key=$value
	done
}

unset_envs() {
	envs=$1

	keys=$(echo ${envs} | jq 'keys_unsorted')
	num_keys=$(echo ${envs} | jq '. | length')
	for ((key_idx = 0 ; key_idx < ${num_keys} ; key_idx++ ));
	do
		key=$keys[$key_idx]
		unset $key
	done
}

exit_if_null() {
    var=$1
    desc=$2
	if [ -z "$var" ]
	then
		echo "$desc is not provided -- got ${var}"
		exit 1
	fi
}