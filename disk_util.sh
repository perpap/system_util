#!/usr/bin/env bash

# Remember to set the debices
#DEVICES=( nvme2n1p1 )

# Check for the input arguments
while getopts "b:a:s:r:d:h" opt
do
    case "${opt}" in
        b)
            DSTATS_BEFORE="${OPTARG}"
            ;;
        a)
            DSTATS_AFTER="${OPTARG}"
            ;;
        s)
            IOSTAT="${OPTARG}"
            ;;
        r)
            RESULT_DIR="${OPTARG}"
            ;;
        d)
			DEVICES+=("${OPTARG}")
            ;;
        h)
            usage
            ;;
        *)
            usage
            ;;
    esac
done

for dev in "${DEVICES[@]}"
do
	echo $dev
	R_SEC_BEFORE=$(grep $dev ${DSTATS_BEFORE} | awk '{ print $6 }')
	W_SEC_BEFORE=$(grep $dev ${DSTATS_BEFORE} | awk '{ print $10 }')

	R_SEC_AFTER=$(grep $dev ${DSTATS_AFTER} | awk '{ print $6 }')
	W_SEC_AFTER=$(grep $dev ${DSTATS_AFTER} | awk '{ print $10 }')

	DIFF_SEC_READ=$(expr ${R_SEC_AFTER} - ${R_SEC_BEFORE})
	DIFF_SEC_WRITE=$(expr ${W_SEC_AFTER} - ${W_SEC_BEFORE})

	DIFF_BYTES_READ=$(expr ${DIFF_SEC_READ} \* 512)
	DIFF_BYTES_WRITE=$(expr ${DIFF_SEC_WRITE} \* 512)

	DIFF_GB_READ=$(expr ${DIFF_BYTES_READ} / 1024 / 1024 / 1024)
	DIFF_GB_WRITE=$(expr ${DIFF_BYTES_WRITE} / 1024 / 1024 / 1024)

	echo "${dev},TOTAL_READS(GB),${DIFF_GB_READ}" >> ${RESULT_DIR}/diskstat.csv
	echo "${dev},TOTAL_WRITES(GB),${DIFF_GB_WRITE}" >> ${RESULT_DIR}/diskstat.csv
	# Add two blank lines
	echo "," >> ${RESULT_DIR}/diskstat.csv
done

for dev in "${DEVICES[@]}"
do
	# remove suffix starting with "p"	
	RM_SF_DEV_NAME=${dev%p*}

	cat ${IOSTAT} | grep $RM_SF_DEV_NAME > iostat.out.txt

	R_MB_PER_SEC=$(cat iostat.out.txt | awk '{print $6 }' | awk '{ sum += $1; n++ } END { if (n > 0) print (sum / n); }')
	W_MB_PER_SEC=$(cat iostat.out.txt | awk '{print $7 }' | awk '{ sum += $1; n++ } END { if (n > 0) print (sum / n); }')
	AVG_RQ_SZ=$(cat iostat.out.txt | awk '{print $8 }' | awk '{ sum += $1; n++ } END { if (n > 0) print (sum / n); }')
	AVG_QU_SZ=$(cat iostat.out.txt | awk '{print $9 }' | awk '{ sum += $1; n++ } END { if (n > 0) print (sum / n); }')
	DEV_UTIL=$(cat iostat.out.txt | awk '{print $14 }' | awk '{ sum += $1; n++ } END { if (n > 0) print (sum / n); }')

	echo "${dev},rMB/s,${R_MB_PER_SEC}" >> ${RESULT_DIR}/diskstat.csv
	echo "${dev},wMB/s,${W_MB_PER_SEC}" >> ${RESULT_DIR}/diskstat.csv
	echo "${dev},AVGRQ-SZ,${AVG_RQ_SZ}" >> ${RESULT_DIR}/diskstat.csv
	echo "${dev},AVGQU-SZ,${AVG_QU_SZ}" >> ${RESULT_DIR}/diskstat.csv
	echo "${dev},DEV_UTIL,${DEV_UTIL}"  >> ${RESULT_DIR}/diskstat.csv
	echo "," >> ${RESULT_DIR}/diskstat.csv

	rm iostat.out.txt
done

# TODO Change script to plot the statistics for all devices
~/system_util/plot_iostat.py -i ${IOSTAT} -o ${RESULT_DIR}/plots -s ${DEVICES[0]}
