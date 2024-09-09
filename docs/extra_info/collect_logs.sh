#!/bin/bash

PODS="$(kubectl get pods -o name)"
DATE="$(date +%F_%H-%M-%S%z)"
HOSTNAME="$(hostname)"

LOGDIR="logs-${HOSTNAME}-${DATE}"
mkdir -p "$LOGDIR"

#set -x

for POD in $PODS
do
    CONTAINERS=$(kubectl get -o jsonpath='{range .spec.containers[*]}{.name}{"\n"}{end}{range .spec.initContainers[*]}{.name}{"\n"}{end}' $POD)
    for CONTAINER in $CONTAINERS
    do
        LOGFILE="${LOGDIR}/${POD#"pod/"}-$CONTAINER.log"
        if [[ "$#" -eq 0 ]]
        then
            # echo "Taking last 10 minutes"
            kubectl logs --since=10m -c $CONTAINER $POD > "$LOGFILE"
        elif [[ "$#" -eq 1 ]]
        then
            # echo "Taking last $1 seconds"
            kubectl logs --since=$1s -c $CONTAINER $POD > "$LOGFILE"
        else
            echo "Only 1 argument is supported: #seconds to take logs"
        fi
    done
done


LOGFILE="${LOGDIR}/version.txt"
helm list > "$LOGFILE"
kubectl get pods -o wide >> "$LOGFILE"

tar czf "$LOGDIR.tar.gz" "$LOGDIR"
rm -r "$LOGDIR"

cp "$LOGDIR.tar.gz" /tmp/ric_cu_logs.tar.gz


LOGDIR="logs-${HOSTNAME}-${DATE}-previous"
mkdir -p "$LOGDIR"

#set -x

for POD in $PODS
do
    CONTAINERS=$(kubectl get -o jsonpath='{range .spec.containers[*]}{.name}{"\n"}{end}{range .spec.initContainers[*]}{.name}{"\n"}{end}' $POD)
    for CONTAINER in $CONTAINERS
    do
        LOGFILE="${LOGDIR}/${POD#"pod/"}-$CONTAINER.log"
        if [[ "$#" -eq 0 ]]
        then
            # echo "Taking last 10 seconds"
            kubectl logs --since=10m -c $CONTAINER $POD --previous > "$LOGFILE"
        elif [[ "$#" -eq 1 ]]
        then
            # echo "Taking last $1 seconds"
            kubectl logs --since=$1s -c $CONTAINER $POD --previous > "$LOGFILE"
        else
            echo "Only 1 argument is supported: #seconds to take logs"
        fi
    done
done


LOGFILE="${LOGDIR}/version.txt"
helm list > "$LOGFILE"
kubectl get pods -o wide >> "$LOGFILE"

tar czf "$LOGDIR.tar.gz" "$LOGDIR"
rm -r "$LOGDIR"

cp "$LOGDIR.tar.gz" /tmp/ric_cu_logs-previous.tar.gz
