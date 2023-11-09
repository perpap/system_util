# Awk script to obtain cumulative
# stats from /proc/diskstats entries
# Usage: accepts an input file containing
# joined diskstats before and after the run
# (in that order), calculates stats for
# all listed devices

function print_stat(which_stat, value)
{
	# Correctly interpret stat to print
	# In case of sectors stat calculate in
	# GBs
	if(which_stat == "read_secs" ||
	   which_stat == "write_secs") {
		   to_print = value / (2 * 1024.0 * 1024.0)
		   printf("%s: %.3f\n", stat_desc[which_stat],
			  to_print);
	} else {
		to_print = value
		printf("%s: %u\n", stat_desc[which_stat],
		       to_print)
	}
}

BEGIN {
	# Declare your devices here
	# Initialize entries in the devices_scanned array
	# with indices matching the devices for which you want
	# to obtain stats, and value 0. All other devices in the
	# diskstats file are ignored. The value is used to know
	# whether to just initialize the actual stats array or do subtraction.
	devices_scanned["md0"] = 0
	stat_desc["reads"] = "Reads"
	stat_desc["writes"] = "Writes"
	stat_desc["read_secs"] = "Read Traffic (GBs)"
	stat_desc["write_secs"] = "Write Traffic (GBs)"
}
{
	# Check if device is in our interest group
	if($3 in devices_scanned){
		# Just initialize values
		if(devices_scanned[$3] == 0){
			diskstats[$3, "reads"] = $4
			diskstats[$3, "read_secs"] = $6
			diskstats[$3, "writes"] = $8
			diskstats[$3, "write_secs"] = $10

			devices_scanned[$3] = 1
		}else{
			diskstats[$3, "reads"] = $4 - diskstats[$3, "reads"];
			diskstats[$3, "writes"] = $8 - diskstats[$3, "writes"];
			diskstats[$3, "read_secs"] = $6 - diskstats[$3, "read_secs"]
			diskstats[$3, "write_secs"] = $10 - diskstats[$3, "write_secs"]
		}
	}
}
END {
	for(device in devices_scanned){
		printf("Device %s Stats:\n", device)
		for(stat in stat_desc){
			#printf("\t");
			print_stat(stat, diskstats[device, stat])
		}
	}
}
