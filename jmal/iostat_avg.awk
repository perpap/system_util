# Optional variable to use when running:
# skip_intervals (awk -f iostat_avg.awk -v skip_intervals=<n>)
#     Skips the first n interval samples from iostat
BEGIN {
	# Set your device here
	# You could modify this for
	# multiple devices by using
	# an array indexed by device path.
	# And having awk ignore lines with
	# device IDs not in the array. See diskstats.awk
	# for such an example.
	DEVICE="md0"
	intervals_parsed = 0;
	samples=0
}

{
	# For iostat each interval sample begins with a
	# timestamp. Match the line against the timestamp
	# format regex (you may need to change this depending
	# on how iostat on the workload machine outputs timestamps)
	# to increment the sample number.
	# This regex matches against MM/DD/YYYY HH:MM:SS {AM/PM} timestamp format
	# but it should also match against DD/MM/YYYY HH:MM:SS {AM/PM} since we don't
	# actually care about the date representation.
	if ($0 ~ /^[0-9]{2}\/[0-9]{2}\/[0-9]{4} [0-9]{2}:[0-9]{2}:[0-9]{2} (AM|PM)$/) {
		intervals_parsed++;
		next
	}

	if( $0 !~ DEVICE || intervals_parsed < skip_intervals)
		next
	
	rd_traffic_mb += ($6 / 1024.0)
	wr_traffic_mb += ($7 / 1024.0)
	avg_rthrough = ($6 + samples * avg_rthrough) / (samples + 1);
	avg_wthrough = ($7 + samples * avg_wthrough) / (samples + 1);
	avg_reqsz = ($8 + samples * avg_reqsz) / (samples + 1);
	avg_qsz = ($9 + samples * avg_qsz) / (samples + 1);
	avg_util = ($14 + samples * avg_util) / (samples + 1);
	samples++
}

END {
	# Careful here, if you run iostat with an option like -m
	# output units for read/write throughput may be different than
	# KB/s
	printf("Read Traffic (GBs)             %.3f\n", rd_traffic_mb / 1024.0);
	printf("Write Traffic (GBs)            %.3f\n", wr_traffic_mb / 1024.0);
	printf("Read Throughput (KB/s)         %.3f\n", avg_rthrough);
	printf("Write Throughput (KB/s)        %.3f\n", avg_wthrough);
	printf("Average Request Size (Sectors) %.3f\n", avg_reqsz);
	printf("Average Queue Size (Requests)  %.3f\n", avg_qsz);
	printf("Utilization(%%)                %.3f\n", avg_util);
}
