#!/usr/bin/env bash

for i in 1 2 3
do
  hcloud server delete talos-control-plane-${i} &
done

for i in 1 2 3
do
  hcloud server delete talos-worker-${i} &
done
wait

for i in 1 2 3
do
  hcloud volume delete talos-worker-${i}-pool-1 &
done
wait

hcloud load-balancer delete controlplane

rm kubeconfig
rm talosconfig
rm controlplane.yaml
rm worker.yaml
