#!/bin/bash

# Workloads
declare -a workload_arr=("FMM" "FFT" "LU" "RADIX" "OCEAN")
# Workload file base name
WORKLOAD=(FMM FFT LU RADIX OCEAN)

# Configurations
declare -a config_arr=("Swap" "MMAP" "xmap Regular Pages" "xmap Hugepages" "xmap Promotions")
CONFIG=(swapper_boot_memlim_nothp_nora vanilla_mmap_bootlim_nora xmap_regular xmap_huge_sync xmap_promo)

BASE_DIR=`pwd`
CSV_DIR=${BASE_DIR}/parsed_computation

mkdir -p ${CSV_DIR}

# Loop over workloads
for ((i = 0; i < ${#WORKLOAD[@]}; i++)); do
	echo "Parsing workload ${workload_arr[$i]}"
	CSV_FILE="${workload_arr[$i]}.csv"
	rm -f ${CSV_DIR}/${CSV_FILE}
	# Print csv header row
	echo "Configuration,Execution Time,User,System,IOwait,Idle,Major Faults,Minor Faults,Read Traffic,Write Traffic" \
		>> ${CSV_DIR}/${CSV_FILE}
	# Loop over configurations
	for ((j = 0; j < ${#CONFIG[@]}; j++)); do
		cd ${CONFIG[$j]}

		# Timeout or error?
		# Write 0 so that the gnuplot script properly handles it
		EXEC_TIME=`grep "Elapsed" ${WORKLOAD[$i]}.out | awk ' {print $NF }' | \
			awk -f ${BASE_DIR}/parse_exec_time.awk | head -n 1`
		WORKLOAD_TERMINATED=`grep "terminated" ${WORKLOAD[$i]}.out`
		if [[ -z "$EXEC_TIME" || -n "$WORKLOAD_TERMINATED" ]]; then
			INIT_TIME="0"
			EXEC_TIME="0"
		else
			INIT_TIME=`${BASE_DIR}/splash_compute_duration.sh ${WORKLOAD[$i]}.out init`
			EXEC_TIME=`${BASE_DIR}/splash_compute_duration.sh ${WORKLOAD[$i]}.out compute`
		fi

		# CPU utilization statistics
		CPUSTATS_FILE=/tmp/`whoami`_${WORKLOAD[$i]}.cpustats
		awk -f ${BASE_DIR}/mpstat_cpuset.awk -v skip_intervals=${INIT_TIME} ${WORKLOAD[$i]}.mpstat > ${CPUSTATS_FILE}
		USR_UTIL=`grep User ${CPUSTATS_FILE} | awk '{ print $NF }'`
		SYS_UTIL=`grep System ${CPUSTATS_FILE} | awk '{ print $NF }'`
		IOW_UTIL=`grep IOwait ${CPUSTATS_FILE} | awk '{ print $NF }'`
		IDL_UTIL=`grep Idle ${CPUSTATS_FILE} | awk '{ print $NF }'`
		rm -f ${CPUSTATS_FILE}

		if [ -e *${WORKLOAD[$i]}.xmap ]; then
			FAULT_FILE=${WORKLOAD[$i]}.xmap
		else
			FAULT_FILE=${WORKLOAD[$i]}.out
		fi
		MAJOR_FAULTS=`grep "Major" ${FAULT_FILE} | awk '{print $NF}' | head -n 1`
		MINOR_FAULTS=`grep "Minor" ${FAULT_FILE} | awk '{print $NF}' | head -n 1`

		# Concatenate and parse diskstats
		#cat ${WORKLOAD[$i]}_before.diskstats > /tmp/joined_diskstats
		#cat ${WORKLOAD[$i]}_after.diskstats >> /tmp/joined_diskstats
		#READ_TRAFFIC=`awk -f ${BASE_DIR}/diskstats.awk /tmp/joined_diskstats | grep "Read Traffic" | \
		#	awk '{print $NF}'`
		#WRITE_TRAFFIC=`awk -f ${BASE_DIR}/diskstats.awk /tmp/joined_diskstats | grep "Write Traffic" | \
		#	awk '{print $NF}'`
		#rm -f /tmp/joined_diskstats

		# Produce iostat statistics for computation phase
		IOSTATS_FILE=/tmp/`whoami`_${WORKLOAD[$i]}.iostats
		awk -f ${BASE_DIR}/iostat_avg.awk -v skip_intervals=${INIT_TIME} ${WORKLOAD[$element]}.iostat > ${IOSTATS_FILE}
		READ_TRAFFIC=`grep "Read Traffic" ${IOSTATS_FILE} | awk '{ print $NF }'`
		WRITE_TRAFFIC=`grep "Write Traffic" ${IOSTATS_FILE} | awk '{ print $NF }'`
		rm -f ${IOSTATS_FILE}

		# If timeout/failure write 0 for faults and I/O traffic
		# to properly display timeout on gnuplot plots
		if [[ "$EXEC_TIME" == "0" ]]; then
			MAJOR_FAULTS="0"
			MINOR_FAULTS="0"
			READ_TRAFFIC="0"
			WRITE_TRAFFIC="0"
		fi
		# Now write the csv row for this configuration
		echo "${config_arr[$j]},${EXEC_TIME},${USR_UTIL},${SYS_UTIL},${IOW_UTIL},${IDL_UTIL},\
${MAJOR_FAULTS},${MINOR_FAULTS},${READ_TRAFFIC},${WRITE_TRAFFIC}" >> ${CSV_DIR}/${CSV_FILE}
		cd ${BASE_DIR}
	done
done
