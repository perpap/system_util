#!/bin/bash

# Data parsing script. Move this, along with helper awk scripts into
# raw results directory. The script assumes that the results directory has one
# directory per evaluated configuration, with per workload output files within.
#
# The following files are assumed to be in the corresponding result directory for a configuration:
#	- A <workload>.out file with the output of time -v <workload>, used
#	  to extract execution time and page faults (in the case of non-xmap
#	  configurations)
#	- A <workload>.iostat file with iostat output. The command used for iostat is:
#	  	iostat -t -x -y ${DEVICE} 1 > ${RESULT_DIR}/${WORKLOAD}.iostat &
#	- A <workload>.mpstat file with mpstat output. The command used for mpstat is:
#		mpstat -P ALL 1 > ${RESULT_DIR}/${WORKLOAD}.mpstat &
#	- A <workload>.xmap file with xmap stats. Stats extracted once workload is finished with:
#		cat /proc/xmap/xmap_stats > ${RESULT_DIR}/${WORKLOAD}.xmap
#	- Two files with output from /proc/diskstats, before and after the workload, to calculate
#	  overall I/O traffic. Therefore run:
#		 cat /proc/diskstats > ${RESULT_DIR}/${WORKLOAD}_before.diskstats
#		 time -v <workload>
#		 cat /proc/diskstats > ${RESULT_DIR}/${WORKLOAD}_after.diskstats
# Output is one CSV file with parsed stats per workload, one line per configuration within
# each CSV file

# Workloads
declare -a workload_arr=("BARNES" "FFT" "FMM" "OCEAN" "LU" "RADIX")
# Workload file base name
WORKLOAD=(BARNES FFT FMM OCEAN LU RADIX )

# Configurations
declare -a config_arr=("Swap" "MMAP" "xmap Regular Pages" "xmap Hugepages" "xmap Promotions")
CONFIG=( swapper_boot_memlim_nothp_nora vanilla_mmap_bootlim_nora xmap_regular xmap_huge_sync xmap_promo )

BASE_DIR=`pwd`

# CSV output directory
CSV_DIR=${BASE_DIR}/parsed

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

		# CPU utilization statistics
		CPUSTATS_FILE=/tmp/`whoami`_${WORKLOAD[$i]}.cpustats
		awk -f ${BASE_DIR}/mpstat_cpuset.awk ${WORKLOAD[$i]}.mpstat > ${CPUSTATS_FILE}
		USR_UTIL=`grep User ${CPUSTATS_FILE} | awk '{ print $NF }'`
		SYS_UTIL=`grep System ${CPUSTATS_FILE} | awk '{ print $NF }'`
		IOW_UTIL=`grep IOwait ${CPUSTATS_FILE} | awk '{ print $NF }'`
		IDL_UTIL=`grep Idle ${CPUSTATS_FILE} | awk '{ print $NF }'`
		rm -f ${CPUSTATS_FILE}

		EXEC_TIME=`grep "Elapsed" ${WORKLOAD[$i]}.out | awk ' {print $NF }' | \
			awk -f ${BASE_DIR}/parse_exec_time.awk | head -n 1`
		WORKLOAD_TERMINATED=`grep "terminated" ${WORKLOAD[$i]}.out`
		# Timeout or error?
		# Write 0 so that the gnuplot script properly handles it
		if [[ -z "$EXEC_TIME" || -n "$WORKLOAD_TERMINATED" ]]; then
			EXEC_TIME="0"
		fi
		if [ -e *${WORKLOAD[$i]}.xmap ]; then
			FAULT_FILE=${WORKLOAD[$i]}.xmap
		else
			FAULT_FILE=${WORKLOAD[$i]}.out
		fi
		MAJOR_FAULTS=`grep "Major" ${FAULT_FILE} | awk '{print $NF}' | head -n 1`
		MINOR_FAULTS=`grep "Minor" ${FAULT_FILE} | awk '{print $NF}' | head -n 1`
		# Concatenate and parse diskstats
		cat ${WORKLOAD[$i]}_before.diskstats > /tmp/joined_diskstats
		cat ${WORKLOAD[$i]}_after.diskstats >> /tmp/joined_diskstats
		READ_TRAFFIC=`awk -f ${BASE_DIR}/diskstats.awk /tmp/joined_diskstats | grep "Read Traffic" | \
			awk '{print $NF}'`
		WRITE_TRAFFIC=`awk -f ${BASE_DIR}/diskstats.awk /tmp/joined_diskstats | grep "Write Traffic" | \
			awk '{print $NF}'`
		rm -f /tmp/joined_diskstats

		# Produce iostat statistics
		# I don't currently use the for plots but you could add them
		# to the CSV output by parsing the output of this awk script
		# with grep
		# awk -f iostat_avg.awk ${WORKLOAD[$element]}.iostat

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
