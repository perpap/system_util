# Input csv file has
# column names on the first row,
# comma separated values
# Format:
# <configuration>,<execution time (s)>,<user%>,<system%>,<iowait%>,<idle%>,<Major faults>,<Minor faults>,<Read Traffic (GBs),<Write Traffic (GBs)>
set datafile columnheaders
set datafile separator ','

# Stacked bars style
set style data histogram
set style histogram rowstacked

#set key vertical outside left top
set key horizontal outside center bottom
set grid y

# Don't add tics opposite the axes
set xtics nomirror rotate by 30 right
set ytics nomirror

# Bar styles
set boxwidth 0.5
set style fill pattern border -1
# Grayscale, comment these out for colored bars
set linetype 1 lc rgb "gray"
set linetype 2 lc rgb "gray20"
set linetype 3 lc rgb "gray60"
set linetype 4 lc rgb "gray90"

# Set plot mode from command-line.
# Default is execution time breakdown
# Supported:
#	"breakdown" -> execution time breakdown
#	"faults" -> major + minor faults stacked bars
#	"traffic" -> read + write traffic stacked bars
if (!(exists("plot_mode"))) plot_mode = "breakdown"
# Set workload name for plot titles from command-line by invoking
# gnuplot -e 'workload_name="<workload>"' file.gnuplot
if (!(exists("workload_name"))) workload_name="UnknownWorkload"
# Set input file name from command line
if (!(exists("input_file"))) input_file = "data.csv"
# Write configuration names at xtics?
#if (!(exists("with_configs"))) with_configs=1;
## Write legend?
#if (!(exists("show_legend"))) show_legend=1;

output_file = sprintf("%s_%s.pdf", workload_name, plot_mode);
# Change (or comment) the following lines for different output format/file
set terminal pdf
set output output_file
set title sprintf("%s", workload_name)

#if (with_configs == 0) {
#	unset xtics
#}
#if (show_legend == 0) {
#	unset key
#}

if (plot_mode eq "breakdown") {
	set ylabel "Execution Time (s)"
	
	# Get max execution time from column 2,
	# use it to set the maximum ytic to draw
	stats input_file using 2 name 'ExecTime'
	set yrange [0:ExecTime_max + ExecTime_max * 0.06]
	
	# Plot user,system,iowait,idle time as calculated
	# over corresponding execution time, add a text label
	# with the configuration's total execution time above the bar
	plot input_file using ($2 * $3 / 100):xticlabels(1) title columnhead(3),\
	'' using ($2 * $4 / 100) title columnhead(4),\
	'' using ($2 * $5 / 100) title columnhead(5),\
	'' using ($2 * $6 / 100) title columnhead(6),\
	'' using 0:\
		 (($2 == 0) ? (ExecTime_max * 0.1) : ($2 + ExecTime_max * 0.03)):\
		 (($2 == 0) ? "TIMEOUT" : 2) with labels notitle
}
if (plot_mode eq "faults") {
	set ylabel "Page Faults"

	# Get max page faults from columns 7, 8
	stats input_file using ($7 + $8) name 'Faults'
	set yrange[0:Faults_max + Faults_max * 0.06]

	plot input_file using 7:xticlabels(1) title columnhead(7),\
	'' using 8 title columnhead(8),\
	'' using 0:\
		 (($7 + $8 == 0) ? (Faults_max * 0.1) : ($7 + $8 + Faults_max * 0.03)):\
		 (($7 + $8 == 0) ? "TIMEOUT" : sprintf("%d", ($7 + $8))) with labels notitle
}
if (plot_mode eq "traffic") {
	set ylabel "I/O Traffic (GBs)"

	# Get max traffic from columns 9, 10
	stats input_file using ($9 + $10) name 'Traffic'
	set yrange[0:Traffic_max + Traffic_max * 0.06]

	# Plot stacked bars for read and write traffic,
	# sum label on top
	plot input_file using 9:xticlabels(1) title columnhead(9),\
	'' using 10 title columnhead(10),\
	'' using 0:\
		 (($9 + $10 == 0) ? Traffic_max * 0.1 : $9 + $10 + Traffic_max * 0.03):\
		 (($9 + $10 == 0) ? "TIMEOUT" : sprintf("%d", ($9 + $10))) with labels notitle
}
