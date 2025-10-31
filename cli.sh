
do_what() {
    if [ $# -eq 0 ]
    then
    	echo "Provide an input arg bench / lm-eval; Example ./run.sh bench "
    	exit 1
    fi

    if [[ "$1" == "bench" ]]; then
    	DO_BENCH=true
    elif  [[ "$1" == "lm-eval" ]]; then
    	DO_LM_EVAL=true
    else
    	echo "Unrecognized option $1: Only bench / lm-eval allowed"
    	exit 0
    fi
}