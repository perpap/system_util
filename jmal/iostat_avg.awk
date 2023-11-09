BEGIN {
	# Set your device here
	# You could modify this for
	# multiple devices by using
	# an array indexed by device path.
	# And having awk ignore lines with
	# device IDs not in the array. See diskstats.awk
	# for such an example.
	DEVICE="md0"
	samples=0
}

{
	if( $0 !~ DEVICE){
		next
	}else{
		avg_rthrough = ($6 + samples * avg_rthrough) / (samples + 1);
		avg_wthrough = ($7 + samples * avg_wthrough) / (samples + 1);
		avg_reqsz = ($8 + samples * avg_reqsz) / (samples + 1);
		avg_qsz = ($9 + samples * avg_qsz) / (samples + 1);
		avg_util = ($14 + samples * avg_util) / (samples + 1);
		samples++
	}
}

END {
	# Careful here, if you run iostat with an option like -m
	# output units for read/write throughput may be different than
	# KB/s
	printf("Read Throughput (KB/s)         %.3f\n", avg_rthrough);
	printf("Write Throughput (KB/s)        %.3f\n", avg_wthrough);
	printf("Average Request Size (Sectors) %.3f\n", avg_reqsz);
	printf("Average Queue Size (Requests)  %.3f\n", avg_qsz);
	printf("Utilization(%%)                %.3f\n", avg_util);
}
	
