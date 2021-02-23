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

# Calculate averages for user, systet, iowait, idle and cpu utilization
USR_UTIL=$(grep all ${RESULT_DIR}/mpstat-* | head -n -1 | awk '{ print $4 }' | awk '{ sum += $1; n++ } END { if (n > 0) print (sum / n); }')
SYS_UTIL=$(grep all ${RESULT_DIR}/mpstat-* | head -n -1 | awk '{ print $6 }' | awk '{ sum += $1; n++ } END { if (n > 0) print (sum / n); }')
IOW_UTIL=$(grep all ${RESULT_DIR}/mpstat-* | head -n -1 | awk '{ print $7 }' | awk '{ sum += $1; n++ } END { if (n > 0) print (sum / n); }')
IDL_UTIL=$(grep all ${RESULT_DIR}/mpstat-* | head -n -1 | awk '{ print $13 }'| awk '{ sum += $1; n++ } END { if (n > 0) print (sum / n); }')

CPU_UTIL=$(grep all ${RESULT_DIR}/mpstat-* | head -n -1 | awk '{ print $13 }' | awk '{ sum += $1; n++ } END { if (n > 0) print 100 - (sum / n); }')

echo "USR_UTIL(%),${USR_UTIL}" > ${RESULT_DIR}/system.csv
echo "SYS_UTIL(%),${SYS_UTIL}" >> ${RESULT_DIR}/system.csv
echo "IOW_UTIL(%),${IOW_UTIL}" >> ${RESULT_DIR}/system.csv
echo "IDL_UTIL(%),${IDL_UTIL}" >> ${RESULT_DIR}/system.csv
echo "CPU_UTIL(%),${CPU_UTIL}" >> ${RESULT_DIR}/system.csv

# Extract the statistics of storage devices utilization
~/system_util/disk_util.sh ${RESULT_DIR}/diskstats-before-* ${RESULT_DIR}/diskstats-after-* ${RESULT_DIR}/iostat-* ${RESULT_DIR}
