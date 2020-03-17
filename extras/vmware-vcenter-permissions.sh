#!/usr/bin/sh

export DATACENTER="dc"
export DATASTORE="datastore1"
export HOST="192.168.86.110" # ESXi Host
export USER=vchintal@vsphere.local # USER is the vSphere Service Account user
export FOLDER="ocp4"
export NETWORK="VM Network"

# The following are vSphere Administator creds
# Change the USER above and the Administrator creds below before executing
export GOVC_USERNAME=administrator@vsphere.local
export GOVC_PASSWORD=WeirdPassword
export GOVC_URL=https://192.168.86.100 # vCenter URL
export GOVC_INSECURE=1

revoke () {
    govc permissions.remove -principal $USER
    govc permissions.remove -principal $USER /$DATACENTER
    govc permissions.remove -principal $USER /$DATACENTER/datastore/$DATASTORE
    govc permissions.remove -principal $USER /$DATACENTER/host/$HOST
    govc permissions.remove -principal $USER "/$DATACENTER/network/$NETWORK"
    govc permissions.remove -principal $USER /$DATACENTER/vm/$FOLDER
    govc role.remove k8s-system-read-and-spbm-profile-view
    govc role.remove manage-k8s-volumes
    govc role.remove manage-k8s-node-vms
    govc role.remove manage-k8s-network
    govc role.remove manage-k8s-folder-permissions
}

add () {
    #------------------------------------------------------------------------------
    # As per the documentation provided here:
    # https://vmware.github.io/vsphere-storage-for-kubernetes/documentation/vcp-roles.html#static-provisioning
    #------------------------------------------------------------------------------

    # StorageProfile.View (Profile-driven storage view) at the vCenter level
    govc role.create k8s-system-read-and-spbm-profile-view StorageProfile.View

    # Low level file operations on the datastore
    govc role.create manage-k8s-volumes Datastore.AllocateSpace Datastore.FileManagement

    # Virtual Machine Privileges
    govc role.create manage-k8s-node-vms Resource.AssignVMToPool \
        VirtualMachine.Config.AddExistingDisk \
        VirtualMachine.Config.AddNewDisk \
        VirtualMachine.Config.AddRemoveDevice \
        VirtualMachine.Config.RemoveDisk \
        VirtualMachine.Inventory.Create \
        VirtualMachine.Inventory.Delete \
        VirtualMachine.Config.Settings

    # Read-only permissions
    govc permissions.set -principal $USER -role ReadOnly -propagate=false \
        /$DATACENTER \
        /$DATACENTER/datastore/$DATASTORE \
        /$DATACENTER/host/$HOST \
        /$DATACENTER/vm/$FOLDER \
        "/$DATACENTER/network/$NETWORK"

    govc permissions.set -principal $USER \
        -role k8s-system-read-and-spbm-profile-view \
        -propagate=false
    govc permissions.set -principal $USER \
        -role manage-k8s-volumes \
        -propagate=false /$DATACENTER/datastore/$DATASTORE
    govc permissions.set -principal $USER \
        -role manage-k8s-node-vms \
        -propagate=true /$DATACENTER/host/$HOST
    govc permissions.set -principal $USER \
        -role manage-k8s-node-vms \
        -propagate=true /$DATACENTER/vm/$FOLDER

    #--------------------------------------------------------------------------
    # The following roles/permissions are in addition to the prerequistes  
    # listed above and specific/needed for this repo function correctly
    #--------------------------------------------------------------------------
    govc role.create manage-k8s-network Network.Assign
    govc permissions.set -principal $USER \
        -role ReadOnly \
        -role manage-k8s-network \
        -propagate=false \
        "/$DATACENTER/network/$NETWORK"

    govc role.create manage-k8s-folder-permissions \
        $(govc role.ls Admin |
            egrep "VirtualMachine.Inventory|VirtualMachine.Provisioning|VirtualMachine.Interact|VirtualMachine.Config")
    govc permissions.set -principal $USER -role manage-k8s-folder-permissions \
        -propagate=true /$DATACENTER/vm/$FOLDER
}

showhelp () {
    echo "Usage: $(basename $0) [add|revoke|help]"
}

case "$1" in
	add)
	  add
	  ;;
	revoke)
	  revoke
	  ;;
	help|-h)
	  showhelp
	  ;;
	*)
	  echo "Operation failed! Required parameter to the script was not passed" 
	  showhelp
	  exit 254
	  ;;
esac
