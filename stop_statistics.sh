#!/usr/bin/env bash

# Print error/usage script message
usage() {
    echo
    echo "Usage:"
    echo -n "      $0 [option ...] "
    echo
    echo "Options:"
    echo "      -d  Directory with results"
    echo "      -h  Show usage"
    echo

    exit 1
}

# Check the number of arguments
if [[ $# -ne 2 ]]; then
	usage
    exit 1
fi

# Check for the input arguments
while getopts "d:h" opt
do
    case "${opt}" in
        d)
            RESULT_DIR="${OPTARG}"
            ;;
        h)
            usage
            ;;
        *)
            usage
            ;;
    esac
done

# Get the end time of the experiment
TIME=$(date +"%T-%d-%m-%Y")
echo $TIME >> ${RESULT_DIR}/parsedate

# Kill iostat mpstat
killall -9 iostat mpstat

# Gett diskstat statistics
cat /proc/diskstats > ${RESULT_DIR}/diskstats-after-"$TIME" &
