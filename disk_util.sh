#!/usr/bin/env bash

# Function to display usage information
usage() {
  echo "Usage: $0 [options]"
  echo "Options:"
  echo "  -b <dstats before file>"
  echo "  -a <dstats after file>"
  echo "  -s <iostat file>"
  echo "  -r <result directory>"
  echo "  -d <device>"
  echo "  -h Display this help message."
  exit 1
}

# Function to find header index based on header name
find_header_index() {
  : '
  # Example usage:
  iostat_headers=$(iostat -xd $dev | head -n 3 | tail -n 1)
  header_index=$(find_header_index "r/s" "$iostat_headers" "bash")
  echo "Bash index: $header_index"
  header_index_awk=$(find_header_index "r/s" "$iostat_headers" "awk")
  echo "Awk index: $header_index_awk"
  '
  # Parameters: $1 - header name to find, $2 - headers string
  local header_to_find="$1"
  local headers_string="$2"
  local index_type="$3"

  # Convert the headers string into an array using read and array syntax
  read -ra headers <<< "$headers_string"

  # Initialize header index
  local header_index=-1

  # Iterate through headers to find the index
  for i in "${!headers[@]}"; do
    if [[ "${headers[$i]}" == "$header_to_find" ]]; then
      header_index=$i
      break
    fi
  done

  # Adjusting index based on the requested index type
  if [[ "$index_type" == "awk" ]]; then
    # For awk, adjust index (arrays in awk start from 1)
    echo $((header_index + 1))
  elif [[ "$index_type" == "bash" ]]; then
    # For bash, return the index as is (0-based indexing)
    echo $header_index
  else
    echo "Invalid index type specified. Please use 'bash' or 'awk'."
    return 1
  fi
}


# Function to parse input arguments
parse_arguments() {
  while getopts "b:a:s:r:d:h" opt; do
    case "${opt}" in
      b) DSTATS_BEFORE="${OPTARG}" ;;
      a) DSTATS_AFTER="${OPTARG}" ;;
      s) IOSTAT="${OPTARG}" ;;
      r) RESULT_DIR="${OPTARG}" ;;
      d) DEVICES+=("${OPTARG}") ;;
      h|*) usage ;;
    esac
  done
}

# Function to calculate metrics
calculate_metrics() {
  local device="$1"
  #########################################################################
  # remove suffix starting with "p"
  local RM_SF_DEV_NAME=${device%p*}

  cat ${IOSTAT} | grep $RM_SF_DEV_NAME > iostat.out.txt
  local iostat_headers=$(iostat -xdm $device | head -n 3 | tail -n 1)
  echo "iostat_headers=$iostat_headers"
  local R_PER_SEC_COL=$(find_header_index "r/s" "$iostat_headers" "awk")
  #echo "R_PER_SEC_COL=$R_PER_SEC_COL"
  local W_PER_SEC_COL=$(find_header_index "w/s" "$iostat_headers" "awk")
  #echo "W_PER_SEC_COL=$W_PER_SEC_COL"
  local R_MB_PER_SEC_COL=$(find_header_index "rMB/s" "$iostat_headers" "awk")
  #echo "R_MB_PER_SEC_COL=$R_MB_PER_SEC_COL"
  local W_MB_PER_SEC_COL=$(find_header_index "wMB/s" "$iostat_headers" "awk")
  #echo "W_MB_PER_SEC_COL=$W_MB_PER_SEC_COL"
  local AVG_QU_SZ_COL=$(find_header_index "aqu-sz" "$iostat_headers" "awk")
  if [[ -z "$AVG_QU_SZ_COL" ]]; then
    AVG_QU_SZ_COL=$(find_header_index "avgqu-sz" "$iostat_headers" "awk")
  fi
  local AVG_RQ_SZ_COL=$(find_header_index "rareq-sz" "$iostat_headers" "awk")
  if [[ -z "$AVG_RQ_SZ_COL" ]]; then
    AVG_RQ_SZ_COL=$(find_header_index "avgrq-sz" "$iostat_headers" "awk")
  fi
  local DEV_UTIL_COL=$(find_header_index "%util" "$iostat_headers" "awk")
  #########################################################################
  # Calculate device statistics
  local R_SEC_BEFORE=$(grep $dev ${DSTATS_BEFORE} | awk '{ print $6 }')
  local W_SEC_BEFORE=$(grep $dev ${DSTATS_BEFORE} | awk '{ print $10 }')

  local R_SEC_AFTER=$(grep $dev ${DSTATS_AFTER} | awk '{ print $6 }')
  local W_SEC_AFTER=$(grep $dev ${DSTATS_AFTER} | awk '{ print $10 }')

  local DIFF_SEC_READ=$(expr ${R_SEC_AFTER} - ${R_SEC_BEFORE})
  local DIFF_SEC_WRITE=$(expr ${W_SEC_AFTER} - ${W_SEC_BEFORE})
  local DIFF_BYTES_READ=$(expr ${DIFF_SEC_READ} \* 512)
  local DIFF_BYTES_WRITE=$(expr ${DIFF_SEC_WRITE} \* 512)

  local DIFF_KB_READ=$(expr ${DIFF_BYTES_READ} / 1024)
  local DIFF_KB_WRITE=$(expr ${DIFF_BYTES_WRITE} / 1024)

  local DIFF_MB_READ=$(expr ${DIFF_KB_READ} / 1024)
  local DIFF_MB_WRITE=$(expr ${DIFF_KB_WRITE} / 1024)

  local DIFF_GB_READ=$(expr ${DIFF_MB_READ} / 1024)
  local DIFF_GB_WRITE=$(expr ${DIFF_MB_WRITE} / 1024)

  # Output to CSV
  echo "${dev},TOTAL_READS(KB),${DIFF_KB_READ}" >> ${RESULT_DIR}/diskstat.csv
  echo "${dev},TOTAL_WRITES(KB),${DIFF_KB_WRITE}" >> ${RESULT_DIR}/diskstat.csv
  echo "${dev},TOTAL_READS(MB),${DIFF_MB_READ}" >> ${RESULT_DIR}/diskstat.csv
  echo "${dev},TOTAL_WRITES(MB),${DIFF_MB_WRITE}" >> ${RESULT_DIR}/diskstat.csv
  echo "${dev},TOTAL_READS(GB),${DIFF_GB_READ}" >> ${RESULT_DIR}/diskstat.csv
  echo "${dev},TOTAL_WRITES(GB),${DIFF_GB_WRITE}" >> ${RESULT_DIR}/diskstat.csv
  echo "," >> ${RESULT_DIR}/diskstat.csv  # Add two blank lines

  #################################################################################
  local R_PER_SEC=$(cat iostat.out.txt | awk -v col="$R_PER_SEC_COL" '{print $col}' | awk '{ sum += $1; n++ } END { if (n > 0) print (sum / n); }')
  local W_PER_SEC=$(cat iostat.out.txt | awk -v col="$W_PER_SEC_COL" '{print $col}' | awk '{ sum += $1; n++ } END { if (n > 0) print (sum / n); }')
  local R_MB_PER_SEC=$(cat iostat.out.txt | awk -v col="$R_MB_PER_SEC_COL" '{print $col}' | awk '{ sum += $1; n++ } END { if (n > 0) print (sum / n); }')
  local W_MB_PER_SEC=$(cat iostat.out.txt | awk -v col="$W_MB_PER_SEC_COL" '{print $col}' | awk '{ sum += $1; n++ } END { if (n > 0) print (sum / n); }')
  local AVG_RQ_SZ=$(cat iostat.out.txt | awk -v col="$AVG_RQ_SZ_COL" '{print $col}' | awk '{ sum += $1; n++ } END { if (n > 0) print (sum / n); }')
  local AVG_QU_SZ=$(cat iostat.out.txt | awk -v col="$AVG_QU_SZ_COL" '{print $col}' | awk '{ sum += $1; n++ } END { if (n > 0) print (sum / n); }')
  local DEV_UTIL=$(cat iostat.out.txt | awk -v col="$DEV_UTIL_COL" '{print $col}' | awk '{ sum += $1; n++ } END { if (n > 0) print (sum / n); }')

  echo "${dev},r/s,${R_PER_SEC}" >> ${RESULT_DIR}/diskstat.csv
  echo "${dev},w/s,${W_PER_SEC}" >> ${RESULT_DIR}/diskstat.csv
  echo "${dev},rMB/s,${R_MB_PER_SEC}" >> ${RESULT_DIR}/diskstat.csv
  echo "${dev},wMB/s,${W_MB_PER_SEC}" >> ${RESULT_DIR}/diskstat.csv
  echo "${dev},AVGRQ-SZ,${AVG_RQ_SZ}" >> ${RESULT_DIR}/diskstat.csv
  echo "${dev},AVGQU-SZ,${AVG_QU_SZ}" >> ${RESULT_DIR}/diskstat.csv
  echo "${dev},DEV_UTIL,${DEV_UTIL}"  >> ${RESULT_DIR}/diskstat.csv
  echo "," >> ${RESULT_DIR}/diskstat.csv  # Add two blank lines

  rm iostat.out.txt
}

# Function to process each device
process_devices() {
  for dev in "${DEVICES[@]}"; do
    calculate_metrics "$dev" "$DSTATS_BEFORE" "$DSTATS_AFTER" "$IOSTAT"
  done
}

parse_arguments "$@"
process_devices
# TODO Change script to plot the statistics for all devices
"$(pwd)"/system_util/plot_iostat.py -i ${IOSTAT} -o ${RESULT_DIR}/plots -s ${DEVICES[0]}

