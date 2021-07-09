#!/usr/bin/sh

export GOVC_USERNAME=administrator@vsphere.local
export GOVC_PASSWORD=WeirdPassword
export GOVC_URL=https://192.168.86.100 # vCenter URL
export GOVC_INSECURE=1

echo "=== vCenter Version ==="
govc about

echo "=== Datacenter Name ==="
govc find . -type d

echo "=== Datastore Name ==="
govc find . -type s

echo "=== Network Name ==="
govc find . -type n
