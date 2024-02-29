#!/usr/bin/env bash

# Print error/usage script message
usage() {
    echo
    echo "Usage:"
    echo -n "      $0 [option ...] "
    echo
    echo "Options:"
    echo "      -r  Directory with results"
    echo "      -d  Devices to monitor"
    echo "      -h  Show usage"
    echo

    exit 1
}

# Function to parse input arguments
parse_arguments() {
  while getopts "r:d:h" opt; do
    case "${opt}" in
      r) RESULT_DIR="${OPTARG}" ;;
      d) DEVICES+=(-d "${OPTARG}") ;;
      h|*) usage ;;
    esac
  done
}

# Function to calculate averages for user, system, iowait, idle and cpu utilization
calculate_utilization_averages(){
  USR_UTIL=$(grep all "${RESULT_DIR}"/mpstat-* | head -n -1 | awk '{ print $4 }' \
	| grep -v "0,00" | awk -F ',' '{print $1"."$2}' \
	| awk '{ sum += $1; n++ } END { if (n > 0) print (sum / n); }')
  SYS_UTIL=$(grep all "${RESULT_DIR}"/mpstat-* | head -n -1 | awk '{ print $6 }' \
	| grep -v "0,00" | awk -F ',' '{print $1"."$2}' \
	| awk '{ sum += $1; n++ } END { if (n > 0) print (sum / n); }')
  IOW_UTIL=$(grep all "${RESULT_DIR}"/mpstat-* | head -n -1 | awk '{ print $7 }' \
	| grep -v "0,00" | awk -F ',' '{print $1"."$2}' \
	| awk '{ sum += $1; n++ } END { if (n > 0) print (sum / n); }')
  IDL_UTIL=$(grep all "${RESULT_DIR}"/mpstat-* | head -n -1 | awk '{ print $13 }'\
	| grep -v "0,00" | awk -F ',' '{print $1"."$2}' \
	| awk '{ sum += $1; n++ } END { if (n > 0) print (sum / n); }')

  CPU_UTIL=$(grep all "${RESULT_DIR}"/mpstat-* | head -n -1 | awk '{ print $13 }' \
	| grep -v "0,00" | awk -F ',' '{print $1"."$2}' \
	| awk '{ sum += $1; n++ } END { if (n > 0) print 100 - (sum / n); }')

  {
    echo "USR_UTIL(%),${USR_UTIL}"
    echo "SYS_UTIL(%),${SYS_UTIL}"
    echo "IOW_UTIL(%),${IOW_UTIL}"
    echo "IDL_UTIL(%),${IDL_UTIL}"
    echo "CPU_UTIL(%),${CPU_UTIL}"
  } >> "${RESULT_DIR}"/system.csv
}

# Function to extract the statistics of storage devices utilization
run_disk_util(){
  "$(pwd)"/system_util/disk_util.sh \
        -b "${RESULT_DIR}"/diskstats-before-* \
        -a "${RESULT_DIR}"/diskstats-after-* \
        -s "${RESULT_DIR}"/iostat-* \
        -r "${RESULT_DIR}" \
        "${DEVICES[@]}"
}

parse_arguments "$@"
calculate_utilization_averages
run_disk_util

