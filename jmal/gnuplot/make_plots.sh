#!/bin/bash

# Example script to produce plots from CSVs
# produces by extract-data.sh
BASE_DIR=`pwd`
# Workloads
declare -a workload_arr=("BARNES" "FFT" "FMM" "OCEAN" "LU" "RADIX")
# Workload file base name
WORKLOAD=(BARNES FFT FMM OCEAN LU RADIX )

CSV_DIR=${BASE_DIR}/parsed
PLOT_DIR=${BASE_DIR}/plots

mkdir -p ${PLOT_DIR}

cd ${PLOT_DIR}
for ((i = 0; i < ${#WORKLOAD[@]}; i++)); do
	rm -f ${workload_arr[$i]}*

	CSV_FILE=${CSV_DIR}/${workload_arr[$i]}.csv

	for mode in breakdown faults traffic; do
		gnuplot -e 'plot_mode="'${mode}'";input_file="'${CSV_FILE}'";workload_name="'${workload_arr[$i]}'"' ${BASE_DIR}/plots_from_csv.gnuplot
	done
done
cd ${BASE_DIR}
