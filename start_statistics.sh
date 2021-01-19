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

mkdir -p ${RESULT_DIR}

# Start time of the experiment
TIME=$(date +"%T-%d-%m-%Y")
echo $TIME > ${RESULT_DIR}/parsedate

# Get iostat, mpstat, and diskstats statistics
iostat -xm 1 > ${RESULT_DIR}/iostat-"$TIME" &
mpstat -P ALL 1 > ${RESULT_DIR}/mpstat-"$TIME" &
cat /proc/diskstats > ${RESULT_DIR}/diskstats-before-"$TIME" &
