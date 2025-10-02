

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

exit_if_null() {
    var=$1
    desc=$2
	if [ -z "$var" ]
	then
		echo "$desc is not provided -- got ${var}"
		exit 1
	fi
}