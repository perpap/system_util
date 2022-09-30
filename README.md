## System Utilization Statistics

Collect and plot system statistics such as CPU utilization and disk utilization
metrics.

## Prerequisites
You need to install python3 and matplotlib
```
sudo yum install python3
sudo yum install python3-pip
pip3 install matplotlib
```

Edit the ./extract-data.sh and fix the path to the disk_util.sh file:
```sh
"$(pwd)"/system_util/disk_util.sh \
	-b "${RESULT_DIR}"/diskstats-before-* \
	-a "${RESULT_DIR}"/diskstats-after-* \
	-s "${RESULT_DIR}"/iostat-* \
  -r "${RESULT_DIR}" \
  "${DEVICES[@]}"
```

Edit the ./disk_util.sh and fix the path to the plot_iostat.sh file:
```sh
"$(pwd)"/system_util/plot_iostat.py \
  -i ${IOSTAT} \
  -o ${RESULT_DIR}/plots \
  -s ${DEVICES[0]}
```
## Configure
Before run set in disk_util.sh file the devices that you want to get metrics by
setting DEVICES variable.

## How to Run
```
./start_statistics.sh -d <directory/with/results>
....
your application
....
./stop_statistics.sh -d <directory/with/results>

./extract-data.sh -r <directory/with/results> -d <dev1> -d <dev2>

```

##TODO:
Add a configuration file

