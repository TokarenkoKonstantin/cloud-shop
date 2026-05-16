#!/bin/bash
# Запуск всех 5 нод K8s кластера через vmrun (VMware Workstation)
# Использование: ./start-cluster.sh

VMWARE_DIR="/mnt/c/Users/Konstantin/Documents/Virtual Machines"

VMS=(
  "k8s-master/k8s-master.vmx"
  "k8s-worker-1/k8s-worker-1.vmx"
  "k8s-worker-2/k8s-worker-2.vmx"
  "k8s-worker-3/k8s-worker-3.vmx"
  "k8s-worker-4/k8s-worker-4.vmx"
)

echo "Starting Kubernetes cluster nodes..."

for vm in "${VMS[@]}"; do
  echo "  Starting: $vm"
  vmrun -T ws start "$VMWARE_DIR/$vm" nogui
  sleep 2
done

echo ""
echo "All nodes started. Waiting 30 seconds for boot..."
sleep 30

echo ""
echo "Checking cluster status:"
ssh -o StrictHostKeyChecking=no neo@192.168.11.101 "kubectl get nodes -o wide"

