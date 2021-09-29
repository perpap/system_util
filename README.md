## System Utilization Statistics

Collect and plot system statistics such as CPU utilization and disk utilization
metrics.

## Prerequisites
You need to install python3 and matplotlib

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

./extract-data.sh -r <directory/with/results> -d <dev1> -d <dev2>

'''

##TODO:
Add a configuration file

