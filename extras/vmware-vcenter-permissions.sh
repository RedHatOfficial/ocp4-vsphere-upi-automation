#!/usr/bin/sh

# The following are vSphere Administator creds
# Change the USER above and the Administrator creds below before executing

chk_creds () {
  . $(pwd)/chk_creds.sh
}

chk_objects () {
  if [ -n $DATACENTER ]; then echo -e "\n##### Datacenters #####\n$(govc find . -type d|awk -F/ '{print $2}')\n"; read -p "DATACENTER: " DATACENTER; export DATACENTER; fi
  if [ -n $DATASTORE ]; then echo -e "\n##### Datastores #####\n$(govc find . -type s|awk -F/ '{print $4}')\n"; read -p "DATASTORE: " DATASTORE; export DATASTORE; fi
  if [ -n $HOST ]; then echo -e "\n##### Hosts #####\n$(govc find . -type h|awk -F/ '{print $5}')\n"; read -p "HOST: " HOST; export HOST; fi
  if [ -n $USER ]; then echo -e "\n##### Users #####\n$(govc sso.user.ls)\n"; read -p "USER: " USER; export USER; fi
  if [ -n $FOLDER ]; then echo -e "\n##### Folders #####\n$(govc find . -type f|awk -F/ '{if ($4) print $4;}')\n"; read -p "FOLDER: " FOLDER; export FOLDER; fi
  if [ -n $NETWORK ]; then echo -e "\n##### Networks #####\n$(govc find . -type n|awk -F/ '{print $4}')\n"; read -p "NETWORK: " NETWORK; export NETWORK; fi
}

vars () {
  echo -e "\n################### Vars ###################"
  cat <<EOF
# The following are user and objects to add/revoke permissions on
export DATACENTER="${DATACENTER}"
export DATASTORE="${DATASTORE}"
export HOST="${HOST}"
export USER="${USER}"
export FOLDER="${FOLDER}"
export NETWORK="${NETWORK}"

# The following are vSphere Administator creds
export GOVC_USERNAME="${GOVC_USERNAME}"
export GOVC_PASSWORD="REDACTED"
export GOVC_URL="${GOVC_URL}"
export GOVC_INSECURE="${GOVC_INSECURE}"
EOF
}

revoke () {
    govc permissions.remove -principal ${USER}
    govc permissions.remove -principal ${USER} /${DATACENTER}
    govc permissions.remove -principal ${USER} /${DATACENTER}/datastore/${DATASTORE}
    govc permissions.remove -principal ${USER} /${DATACENTER}/host/${HOST}
    govc permissions.remove -principal ${USER} "/${DATACENTER}/network/${NETWORK}"
    govc permissions.remove -principal ${USER} /${DATACENTER}/vm/${FOLDER}
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
    govc permissions.set -principal ${USER} -role ReadOnly -propagate=false \
        /${DATACENTER} \
        /${DATACENTER}/datastore/${DATASTORE} \
        /${DATACENTER}/host/${HOST} \
        /${DATACENTER}/vm/${FOLDER} \
        "/${DATACENTER}/network/${NETWORK}"

    govc permissions.set -principal ${USER} \
        -role k8s-system-read-and-spbm-profile-view \
        -propagate=false
    govc permissions.set -principal ${USER} \
        -role manage-k8s-volumes \
        -propagate=false /${DATACENTER}/datastore/${DATASTORE}
    govc permissions.set -principal ${USER} \
        -role manage-k8s-node-vms \
        -propagate=true /${DATACENTER}/host/${HOST}
    govc permissions.set -principal ${USER} \
        -role manage-k8s-node-vms \
        -propagate=true /${DATACENTER}/vm/${FOLDER}

    #--------------------------------------------------------------------------
    # The following roles/permissions are in addition to the prerequistes
    # listed above and specific/needed for this repo function correctly
    #--------------------------------------------------------------------------
    govc role.create manage-k8s-network Network.Assign
    govc permissions.set -principal ${USER} \
        -role ReadOnly \
        -role manage-k8s-network \
        -propagate=false \
        "/${DATACENTER}/network/${NETWORK}"

    govc role.create manage-k8s-folder-permissions \
        $(govc role.ls Admin |
            egrep "VirtualMachine.Inventory|VirtualMachine.Provisioning|VirtualMachine.Interact|VirtualMachine.Config")
    govc permissions.set -principal ${USER} -role manage-k8s-folder-permissions \
        -propagate=true /${DATACENTER}/vm/${FOLDER}
}

consent () {
  echo -e "\nThese values can be saved and imported for later use...\n"
  read -p "Are these values correct?: " ans
  case "$ans" in
    y|Y|yes|Yes|YES)
      $1
      ;;
    n|N|no|No|NO)
      echo "Canceled by user, exiting..."
      exit 0
      ;;
    *)
      echo "Invalid response, exiting..."
      exit 1
      ;;
  esac
}

showhelp () {
    echo "Usage: $(basename $0) [add|revoke|vars|help|-h]"
}

case "$1" in
	add|revoke)
    chk_creds
    chk_objects
    vars
    consent $1
	  ;;
  vars)
    chk_creds
    chk_objects
    vars
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
