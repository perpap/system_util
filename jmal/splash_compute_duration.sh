#!/bin/bash

# Input argument: SPLASH
# workload output filename (currently covers
# FMM, FFT, BARNES, LU, RADIX, OCEAN)
#
# Output: initialization phase duration
OUTFILE=$1
WORKLOAD=`basename $OUTFILE .out`

if [[ "$2" = "init" ]]; then
	case $WORKLOAD in
		BARNES)
			INIT_DUR=`grep "INITTIME" $OUTFILE | awk '{ print $NF }'`
			echo $INIT_DUR
			;;
		OCEAN)
			# Fallthrough to FMM as they require the same handling
			;&
		RADIX)
			# Fallthrough to FMM as they require the same handling
			;&
		LU)
			# Fallthrough to FMM as they require the same handling
			;&
		FFT)
			# Fallthrough to FMM as they require the same handling
			;&
		FMM)
			INIT_START=`grep "Start time" $OUTFILE | awk '{ print $NF }'`
			INIT_END=`grep "Initialization finish time" $OUTFILE | awk '{ print $NF }'`
			INIT_DUR=$(( $INIT_END - $INIT_START ))
			echo $INIT_DUR
			;;
		*)
			echo "Unrecognized workload $WORKLOAD"
			;;
	esac
elif [[ "$2" = "compute" ]]; then
	case $WORKLOAD in
		BARNES)
			COMPUTE_DUR=`grep "COMPUTETIME" $OUTFILE | awk '{ print $NF }'`
			echo $COMPUTE_DUR
			;;
		OCEAN)
			# Fallthrough to FMM as they require the same handling
			;&
		RADIX)
			# Fallthrough to FMM as they require the same handling
			;&
		LU)
			# Fallthrough to FMM as they require the same handling
			;&
		FFT)
			# Fallthrough to FMM as they require the same handling
			;&
		FMM)
			COMPUTE_DUR=`grep "Total time without initialization" $OUTFILE | awk '{ print $NF }'`
			echo ${COMPUTE_DUR}
			;;
		*)
			echo "Unrecognized workload $WORKLOAD"
			;;
	esac
else
	echo "Unknown option $2"
fi
