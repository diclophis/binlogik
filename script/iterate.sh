#!/bin/sh

set -e

kubectl delete -f kubernetes --wait=false || true

polly build

kubectl delete -f kubernetes || true
kubectl delete pod binlogik --wait || true

kubectl apply -f kubernetes

cleanup() {
  echo -n " ... please wait ... "
  kubectl delete pod binlogik
  exit
}

trap cleanup INT TERM

while ! kubectl logs binlogik -c binlogik -f --pod-running-timeout=60s
do
  sleep 1
  echo -n ","
done
