# Helper script to parse
# elapsed time output from
# gnu time into a single number of
# seconds
{
	split($1, time, ":");
	if (length(time) == 2) {
		# Minutes:Seconds.Hundredths format
		seconds = time[1] * 60 + time[2];
		split($2, hsec, ".");
		seconds += hsec[1] / 100;
	} else if (length(time) == 3) {
		# Hours:Minutes:Seconds format
		seconds = time[1] * 3600 + time[2] * 60 + time[3];
	}
	print seconds;
}
