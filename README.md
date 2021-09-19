## System Utilization Statistics

Collect and plot system statistics such as CPU utilization and disk utilization
metrics.

## Configure
Before run set in disk_util.sh file the devices that you want to get metrics by
setting DEVICES variable.

## How to Run
'''
./start_statistics.sh -d <directory/with/results>
....
your application
....
./stop_statistics.sh -d <directory/with/results>

./extract-data.sh -d <directory/with/results>

'''

##TODO:
Add a configuration file

