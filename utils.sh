

export_envs() {
	envs=$1
    keys=()
    values=()
    eval $(echo $envs |jq -r 'to_entries[]| "keys+=(\(.key));"')
    eval $(echo $envs |jq -r 'to_entries[]| "values+=(\(.value));"')
	for ((idx = 0 ; idx < ${#keys[@]} ; idx++ ));
	do
		export ${keys[${idx}]}=${values[${idx}]}
	done
}

unset_envs() {
	envs=$1
    keys=()
    eval $(echo $envs |jq -r 'to_entries[]| "keys+=(\(.key));"')
	for ((idx = 0 ; idx < ${#keys[@]} ; idx++ ));
	do
		unset ${keys[${idx}]}
	done
}

envs_as_str() {
    envs_as_str_result=""
    envs=$1
    keys=()
    values=()
    eval $(echo $envs |jq -r 'to_entries[]| "keys+=(\(.key));"')
    eval $(echo $envs |jq -r 'to_entries[]| "values+=(\(.value));"')
    for ((idx = 0 ; idx < ${#keys[@]} ; idx++ ));
    do
        envs_as_str_result="${envs_as_str_result}_${keys[${idx}]}=${values[${idx}]}"
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

describe_server() {
	server_description=""

	model=$1
	dp_size=$2
	tp_size=$3
	eager=$4
	envs=$5
	ts=$(date +%s)

	# fix model. No forward slash in file name 
	model_name=${model/\//_}
	# get envs
	envs_as_str_result=""
	envs_as_str "${envs}"

	server_description="${model_name}_dp=${dp_size}_tp=${tp_size}_eager=${eager}_${envs_as_str_result}_ts=${ts}"
}
