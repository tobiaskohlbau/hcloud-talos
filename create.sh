#!/usr/bin/env bash

set -e

hcloud load-balancer create --name controlplane --network-zone eu-central --type lb11 --label 'type=controlplane'
hcloud load-balancer add-service controlplane \
    --listen-port 6443 --destination-port 6443 --protocol tcp
hcloud load-balancer add-target controlplane \
    --label-selector 'type=controlplane'

CONTROLPLANE_IP=$(hcloud load-balancer describe controlplane -o json | jq ".public_net.ipv4.ip" -r)

talosctl gen config talos-k8s-hcloud-tutorial https://${CONTROLPLANE_IP}:6443 --config-patch @talos-patch.yaml --config-patch-worker @talos-worker-patch.yaml

IMAGE_ID=$(hcloud image list -o columns=id,description | grep "talos-1_7_0" | cut -d ' ' -f1)

location=hel1

for i in 1 2 3
do
  case "${i}" in
    "1")
    location=hel1
    ;;
    "2")
    location=fsn1
    ;;
    "3")
    location=nbg1
    ;;
  esac

  hcloud server create --name talos-control-plane-${i} \
     --image ${IMAGE_ID} \
     --type cpx21 --location ${location} \
     --label 'type=controlplane' \
     --user-data-from-file controlplane.yaml &
done

for i in 1 2 3
do
  hcloud server create --name talos-worker-${i} \
     --image ${IMAGE_ID} \
     --type cpx31 --location hel1 \
     --label 'type=worker' \
     --user-data-from-file worker.yaml &
done
wait
sleep 20

IP=$(hcloud server ip talos-control-plane-1)

talosctl --talosconfig talosconfig config endpoint ${IP}
talosctl --talosconfig talosconfig config node ${IP}

export TALOSCONFIG=./talosconfig

talosctl bootstrap
sleep 60

talosctl kubeconfig .

export KUBECONFIG=./kubeconfig

helm install \
    cilium \
    cilium/cilium \
    --version 1.15.4 \
    --namespace kube-system \
    --set ipam.mode=kubernetes \
    --set=kubeProxyReplacement=true \
    --set=securityContext.capabilities.ciliumAgent="{CHOWN,KILL,NET_ADMIN,NET_RAW,IPC_LOCK,SYS_ADMIN,SYS_RESOURCE,DAC_OVERRIDE,FOWNER,SETGID,SETUID}" \
    --set=securityContext.capabilities.cleanCiliumState="{NET_ADMIN,SYS_ADMIN,SYS_RESOURCE}" \
    --set=cgroup.autoMount.enabled=false \
    --set=cgroup.hostRoot=/sys/fs/cgroup \
    --set=k8sServiceHost=localhost \
    --set=k8sServicePort=7445
sleep 60

kubectl create ns mayastor 2> /dev/null || true
kubectl label namespace mayastor pod-security.kubernetes.io/enforce=privileged

helm install mayastor mayastor/mayastor -n mayastor --create-namespace --version 2.6.1
sleep 120

for i in 1 2 3
do
  hcloud volume create --size 100 --server talos-worker-${i} --name talos-worker-${i}-pool-1
  device=$(hcloud volume describe talos-worker-${i}-pool-1 -o json | jq ".linux_device" -r)

  export NODE=talos-worker-${i}
  export DEVICE=${device}
  envsubst < diskpool.yaml | kubectl apply -f -
done

sleep 30

kubectl apply -f storageclass.yaml
kubectl apply -f mayastor-test.yaml

kubectl wait --for=condition=Ready pod/fio

kubectl exec -it fio -- fio --name=benchtest --size=800m --filename=/volume/test --direct=1 --rw=randrw --ioengine=libaio --bs=4k --iodepth=16 --numjobs=8 --time_based --runtime=60
