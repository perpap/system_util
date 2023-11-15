#!/bin/awk

# WARNING: this script requires gawk
# as it uses arrays of arrays, not traditionally
# available in awk (where all arrays are 1D and you
# get the illusion of multiple dimension via index string
# concatenation. It should be easy to rewrite this so that
# the cpu_values array uses concatenated indices instead but
# this looks cleaner than separating with commas. On sith machines
# awk is a symlink to gawk so this should not be an issue

# To setup a number of interval entries to skip run
# with option -v skip_intervals=<num_to_skip>, otherwise
# no intervals are skipped
BEGIN {
	# Set your appropriate CPUs
	# here. CPU indices not set
	# in this array are ignored
	# when parsing mpstat logs. Hardcoded
	# for sith5 with 32 max logical CPUs,
	# just change this to match your machine.
	for (i = 0; i < 32; i++)
		valid_cpus[i] = 1;
	printf("Monitored CPUset is: {");
	for (cpu in valid_cpus) 
		printf(" %d ", cpu);
	printf("}\n");
	# Measure parsed interval samples
	# by counting the "all" lines. This
	# way we can skip as many interval samples
	# as necessary to avoid parsing utilization stats
	# from the initialization phase of a workload.
	#
	# The easy case (a.k.a. what I do): have mpstat
	# (and iostat) collect stats at 1-second intervals,
	# thus the number of intervals to skip matches the
	# duration in seconds of the initialization phase.
	intervals_parsed = 0;
}
# Skip header line (Linux ...)
FNR == 1 { next; }
{
	# Ignore per entry header line and empty line after
	# the per CPU lines for a single interval	
	if ($0 ~ "CPU" || NF == 0)
		next;

	# Skip the cumulative stats line
	# but count the interval in order
	# to check whether we parse the actual
	# per CPU lines afterwards
	if ($0 ~ "all") {
		intervals_parsed++;
		next;
	}

	# We're still skipping
	if (intervals_parsed < skip_intervals)
		next;

	# Check if CPU index for this line belongs
	# to the set we are monitoring
	if (!($3 in valid_cpus))
		next;

	# Record rolling averages. It would be faster to
	# just get the sum and do the average per cpu in
	# the end but I don't want to risk overflow for long
	# runs. Number of samples should be the same for all
	# cpus but the structure of mpstat's output makes it
	# difficult to know when to correctly increment the sample
	# count without first inferring the number of CPUs on the system
	# which executed the workload (which may be separate than the one
	# parsing the data).
	cpu_values[$3]["usr"] = ($4 + (cpu_values[$3]["usr"] * cpu_values[$3]["samples"])) / (cpu_values[$3]["samples"] + 1);
	cpu_values[$3]["sys"] = ($6 + (cpu_values[$3]["sys"] * cpu_values[$3]["samples"])) / (cpu_values[$3]["samples"] + 1);
	cpu_values[$3]["iow"] = ($7 + (cpu_values[$3]["iow"] * cpu_values[$3]["samples"])) / (cpu_values[$3]["samples"] + 1);
	cpu_values[$3]["idl"] = ($13 + (cpu_values[$3]["idl"] * cpu_values[$3]["samples"])) / (cpu_values[$3]["samples"] + 1);
	cpu_values[$3]["samples"]++;
}

END {
	num_cpus = avg_user = avg_sys = avg_iowait = avg_idle = 0;
	for (cpu in valid_cpus) {
		# Now do rolling averages across all CPUs
		avg_user = (cpu_values[cpu]["usr"] + (num_cpus * avg_user)) / (num_cpus + 1);
		avg_sys = (cpu_values[cpu]["sys"] + (num_cpus * avg_sys)) / (num_cpus + 1);
		avg_iowait = (cpu_values[cpu]["iow"] + (num_cpus * avg_iowait)) / (num_cpus + 1);
		avg_idle = (cpu_values[cpu]["idl"] + (num_cpus * avg_idle)) / (num_cpus + 1);
		num_cpus++;
	}
	printf("Average CPU Utilization for CPUset:\nUser: %.3lf\nSystem: %.3lf\nIOwait: %.3lf\nIdle: %.3lf\n",
	       avg_user, avg_sys, avg_iowait, avg_idle);
}
