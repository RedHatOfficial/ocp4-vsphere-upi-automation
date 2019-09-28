# OCP4 on VMware vSphere UPI Automation

The goal of this repo is to make deploying and redeploying a new Openshift v4 cluster a snap. The document looks long but after you have used it till end once, you will appreciate how quickly VMs come up in vCenter for you to start working with. 

Using the same repo and with minor tweaks, it can be applied to any version of Oepnshift higher than the current version of 4.1.

## Prerequisites

1. vSphere ESXi and vCenter 6.7 installed 
2. A datacenter created with vSphere host added to it 
3. **VM and Template folder** created with the same name as the **Openshift cluster name** you would like to use, as described in the [documentation](https://docs.openshift.com/container-platform/4.1/installing/installing_vsphere/installing-vsphere.html#installation-vsphere-machines_installing-vsphere)
4. The OVF template deployed in the ***same folder*** from the OVA file [located here](https://mirror.openshift.com/pub/openshift-v4/dependencies/rhcos/4.1/latest/rhcos-4.1.0-x86_64-vmware.ova) using instructions from **#6** step of the same documentation as in the previous step. Once deployed, edit the template such that:
   * Under the VM Options 🠮 Advanced 🠮 Latency Sensitivity; set it to **High**
   * Under the VM Options 🠮 Advanced 🠮 Configuration Parameters 🠮 Edit Configuration; add the following param (name, value) respectively:
     1. disk.EnableUUID, TRUE
     2. guestinfo.ignition.config.data.encoding, base64
     3. guestinfo.ignition.config.data,  blah
     4. guestinfo.ovfEnv, blah
    * Save the template
5. Ideally have [helper node](https://github.com/christianh814/ocp4-upi-helpernode) running in the same network to provide all the necessary services such as [DHCP/DNS/HAProxy as LB/FTP Server]
6. Ansible 2.8.5 installed on the machine where this repo is cloned

## Automatic generation of ignition and other supporting files

### Prerequisites

1. Get the ***pull secret*** from [here](https://cloud.redhat.com/openshift/install/vsphere/user-provisioned)
2. Generate a ssh key pair as per [instructions](https://docs.openshift.com/container-platform/4.1/installing/installing_vsphere/installing-vsphere.html#ssh-agent-using_installing-vsphere). The private key will then be used to log into bootstrap/master and worker nodes 
3. Get the vcenter details:
   1. IP Address
   2. Username
   3. Password
   4. Datacenter name *(created in the earlier prerequisites)*
4. Actual links to the Openshift Client and Install binaries *(prepopulated for 4.1.x)*
5. Openshift cluster 
   1. base domain *(prepopulated with **example.com**)*
   2. cluster name *(prepopulated with **ocp4**)*
6. HTTP URL of the ***bootstrap.ign*** file *(prepopulated with a example config pointing to helper node)*

The step **#6** needn't exist at the time of running the setup/installation step, so provide an accurate guess of where and at what context path **bootstrap.ign** will eventually be served 
   
### Setup and Installation

With all the details in hand from the prerequisites, populate the **vars.yml** in the root folder of this repo and trigger the installation with the following command 

```sh 
# Make sure to run this command in the root folder of the repo
ansible-playbook -e @vars.yml setup-ocp-vsphere.yml
```

### Artifacts Generated 

1. Folders [bin, downloads, install-dir] created
2. Openshift client and install binaries downloaded to the **downloads** folder
3. Unzipped versions of the binaries installed in the **bin** folder
4. In the **install-dir** folder:
   1. append-bootstrap.ign file with the HTTP URL of the **boostrap.ign** file
   2. master.ign and worker.ign
   3. base64 encoded files (append-bootstrap.64, master.64, worker.64) for (append-bootstrap.ign, master.ign, worker.ign) respectiviely. This step assumes you have **base64** installed and in your **$PATH**
   4. vCenter configuration parameters in individual files :
      * append-bootstrap-vm-param.txt
      * master-vm-param.txt
      * worker-vm-param.txt

## Copy the bootstrap.ign file to the webserver 

> This is an important step before you deploy/power-on the VMs

If using the helper node, the following command might help!

```sh 
# Running from the root folder of this repo; below is just an example
scp install-dir/bootstrap.ign root@192.168.86.180:/var/www/html/ignition
```

## Automatic creation of VMs in vCenter

### Prereqisites

1. Get the name of the OVF template as deployed in the vCenter folder *(prepopulated with name **rhcos-4.1.0-x86_64-vmware**)*
2. Get the correct path of the vCenter folder *(prepopulated with an example path in **setup-vcenter-vms.yml**)*
3. Get the vCenter datastore you want the VMs to use *(prepopulated with **datastore1**)*

*All the prepopulated values are customizable and can be modified as required*

### Setup and Installation

With all the details in hand from the prerequisites, populate the **setup-vcenter-vms.yml** in the root folder of this repo and trigger the installation with the following command 

```sh 
# Make sure to run this command in the root folder of the repo
ansible-playbook -e @vars.yml setup-vcenter-vms.yml
```

### Artifacts Generated 

In vCenter all VMs (bootstrap, master0-2, worker0-2) generated in the designated folder but in **powered-off** state

## Final step: Power On

>Before this step is run, ensure that the dhcp server in your network (or on the helper node) uses the MAC addresses in the yaml file and maps them to the corresponding IP Addresses that you would like to use for each machine

In vCenter click on the ESXi Host (IP address) 🠮 Click on VMs tab 🠮 Cntrl-select all of the 7 machines 🠮 Right-click and choose Power 🠮 Power On

If everything goes well you should be able to log into all of the machines using the private key generated in prerequistes. On **bootstrap** node running the following command will help understand if the masters are (being) setup:

```sh
journalctl -b -f -u bootkube.service
```
