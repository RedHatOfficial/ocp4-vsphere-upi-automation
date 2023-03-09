#!/usr/bin/sh

. $(pwd)/chk_creds.sh

echo "=== vCenter Version ==="
govc about

echo "=== Datacenter Name ==="
govc find . -type d

echo "=== Datastore Name ==="
govc find . -type s

echo "=== Network Name ==="
govc find . -type n
