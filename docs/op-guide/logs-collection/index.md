# Logs Collection

This section will be useful in cases were there is an issue to debug or just for cases where logs of a successful test run needs to be saved.

## 1. RU Logs

As part of radio related issues debugging. Please run below commands on the radio unit while the cell is active and send the output to Accelleran with other related logs and traces.

(Assuming the radio IP was 10.10.0.100.)
```bash
ssh root@10.10.0.100
cat /etc/benetel-rootfs-version
cat /tmp/radio_status
reportRuStatus
radiocontrol -o G a
radiocontrol -o D s
```

## 2. DU/L1 Logs

A directory in the DU machine with the DU/L1 logs and configuration files will be saved in the ```/run/``` directory with the name of the DU (which can be found from the dashboard -> RAN Overview -> 5G)

- Please compress this directory and share them with Accelleran in cases where debug is needed. Assuming du-1 was used: ```zip -r /run/du-1/ ~/du_logs.zip```


## 3. CU Logs and Traces

A tcpdump on the CU VM can be started before running the test case to save all the packets exchanged between the core <-> CU <-> DU.

- Below command can be used from within the CU VM.
tcpdump -i enp1s0 'sctp' -w cu_side_trace.pcap

> - This is assuming the interface the CU VM is using is "enp1s0", please change it according to your setup.
> - It is better to save only sctp data unless the test/debug case in question is related to user plane packets otherwise use "sctp or udp" in the command.

To save the CU logs:

- Create a file named collect_logs.sh with the content below.
- By default it will save the logs of the last 10minutes but to save the logs of the last 20mins for example, run: "``` ./collect_logs.sh 10```"
- The log files will be saved in below two files: ```/tmp/logs.tar.gz``` and ```/tmp/logs-previous.tar.gz```

```bash
PODS="$(kubectl get pods -o name)"
DATE="$(date +%F_%H-%M-%S%z)"
HOSTNAME="$(hostname)"

LOGDIR="logs-${HOSTNAME}-${DATE}"
mkdir -p "$LOGDIR"

set -x

for POD in $PODS
do
    CONTAINERS=$(kubectl get -o jsonpath='{range .spec.containers[*]}{.name}{"\n"}{end}{range .spec.initContainers[*]}{.name}{"\n"}{end}' $POD)
    for CONTAINER in $CONTAINERS
    do
        LOGFILE="${LOGDIR}/${POD#"pod/"}-$CONTAINER.log"
        if [[ "$#" -eq 0 ]]
        then
            echo "Taking last 10 minutes"
            kubectl logs --since=10m -c $CONTAINER $POD > "$LOGFILE"
        elif [[ "$#" -eq 1 ]]
        then
            echo "Taking last $1 minutes"
            kubectl logs --since=$1m-c $CONTAINER $POD > "$LOGFILE"
        else
            echo "Only 1 argument is supported: #minutes to take logs"
        fi
    done
done


LOGFILE="${LOGDIR}/version.txt"
helm list > "$LOGFILE"
{
kubectl get pods
helm status acc-5g-cu-cp
helm status acc-5g-cu-up
helm status ric
helm status cw
} > "$LOGFILE"

tar czf "$LOGDIR.tar.gz" "$LOGDIR"
rm -r "$LOGDIR"

cp "$LOGDIR.tar.gz" /tmp/logs.tar.gz


LOGDIR="logs-${HOSTNAME}-${DATE}-previous"
mkdir -p "$LOGDIR"

set -x

for POD in $PODS
do
    CONTAINERS=$(kubectl get -o jsonpath='{range .spec.containers[*]}{.name}{"\n"}{end}{range .spec.initContainers[*]}{.name}{"\n"}{end}' $POD)
    for CONTAINER in $CONTAINERS
    do
        LOGFILE="${LOGDIR}/${POD#"pod/"}-$CONTAINER.log"
        if [[ "$#" -eq 0 ]]
        then
            echo "Taking last 10 minutes"
            kubectl logs --since=10m -c $CONTAINER $POD --previous > "$LOGFILE"
        elif [[ "$#" -eq 1 ]]
        then
            echo "Taking last $1 minutes"
            kubectl logs --since=$1m -c $CONTAINER $POD --previous > "$LOGFILE"
        else
            echo "Only 1 argument is supported: #minutes to take logs"
        fi
    done
done


LOGFILE="${LOGDIR}/version.txt"
helm list > "$LOGFILE"
{
kubectl get pods
helm status acc-5g-cu-cp
helm status acc-5g-cu-up
helm status ric
helm status cw
} > "$LOGFILE"

tar czf "$LOGDIR.tar.gz" "$LOGDIR"
rm -r "$LOGDIR"

cp "$LOGDIR.tar.gz" /tmp/logs-previous.tar.gz
```
