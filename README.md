# OCP4 on VMware vSphere UPI Automation

The goal of this repo is to make deploying and redeploying a new OpenShift v4 cluster a snap. The document looks long but after you have used it till the end once, you will appreciate how quickly VMs come up in vCenter for you to start working with. 

Using the same repo and with minor tweaks, it can be applied to any version of OpenShift higher than the current version of 4.3.

## Prerequisites

1. vSphere ESXi and vCenter 6.7 installed 
2. A datacenter created with a vSphere host added to it 
3. Ideally have [helper node](https://github.com/christianh814/ocp4-upi-helpernode) running in the same network to provide all the necessary services such as [DHCP/DNS/HAProxy as LB/FTP Server]
4. Ansible 2.8.5 or 2.9.3 installed on the machine where this repo is cloned 
   * To install a specific version of Ansible you can run a command like: `sudo dnf -y install ansible-2.8.5`

## Automatic generation of ignition and other supporting files

### Prerequisites 
> Pre-populated entries in **vars.yml** are ready to be used unless you want to customize further
1. Get the ***pull secret*** from [here](https://cloud.redhat.com/OpenShift/install/vsphere/user-provisioned)
2. Generate a SSH key pair as per [instructions](https://docs.OpenShift.com/container-platform/4.3/installing/installing_vsphere/installing-vsphere.html#ssh-agent-using_installing-vsphere). The private key will then be used to log into bootstrap/master and worker nodes 
3. Get the vCenter details:
   1. IP Address
   2. Username
   3. Password
   4. Datacenter name *(created in the prerequisites mentioned above)*
4. Actual links to the OpenShift Client, Install and .ova binaries *(pre-populated for 4.3.x)*
5. Downloadable link to `govc` (vSphere CLI, *pre-populated*)
6. OpenShift cluster 
   1. base domain *(pre-populated with **example.com**)*
   2. cluster name *(pre-populated with **ocp4**)*
7. HTTP URL of the ***bootstrap.ign*** file *(pre-populated with a example config pointing to helper node)*
8. Update the **inventory** file and under the `[webservers]` entry use : 
   * **localhost** : if this repo is being run on the same host  as the webserver that would eventually host **bootstrap.ign**,  
   * the IP address or FQDN of the machine that would run the webserver. 

The step **#7** needn't exist at the time of running the setup/installation step, so provide an accurate guess of where and at what context path **bootstrap.ign** will eventually be served 
   
### Setup and Installation

With all the details in hand from the prerequisites, populate the **vars.yml** in the root folder of this repo and trigger the installation with the following options:

* If running for the very first time **OR** If you have already run (at least) once and want to re-run again without recreating `bin` and `downloads` folders, choose (**only**) one of the following:
   ```sh 
   # When you have not done a sudo in the session yet 
   # The webserver is on localhost (as reflected by the entry in the inventory)
   ansible-playbook -e @vars.yml install.yml --connection=local -b --ask-become-pass

   # When you have done a sudo just recently 
   # The webserver is on localhost (as reflected by the entry in the inventory)
   ansible-playbook -e @vars.yml install.yml --connection=local -b     

  # This is prompt for the SSH password for the root account of the remote host
  # The webserver is on a remote host (as reflected by the entry in the inventory)
  ansible-playbook -e @vars.yml install.yml --ask-pass
  ```
* If vCenter folder already exists with the template because you set the vCenter the last time you ran the ansible playbook but want a fresh deployment of VMs after you have erased all the existing VMs in the folder, append the following to the command you chose in the above step

   ```sh 
   --extra-vars "vcenter_preqs_met=true"
   ```
* If would rather want to clean all folders `bin`, `downloads`, `install-dir` and re-download all the artifacts, append the following to the command you chose in the first step
   ```sh 
   --extra-vars "clean=true"
   ```
### Expected Outcome

1. Folders [bin, downloads, install-dir] created
2. OpenShift client, install and .ova binaries downloaded to the **downloads** folder
3. Unzipped versions of the binaries installed in the **bin** folder
4. In the **install-dir** folder:
   1. append-bootstrap.ign file with the HTTP URL of the **boostrap.ign** file
   2. master.ign and worker.ign
   3. base64 encoded files (append-bootstrap.64, master.64, worker.64) for (append-bootstrap.ign, master.ign, worker.ign) respectiviely. This step assumes you have **base64** installed and in your **$PATH**
5. The **bootstrap.ign** is copied over to the web server in the designated location
6. A folder is created in the vCenter under the mentioned datacenter and the template file is imported 
7. The template file is edited to carry certain default settings and runtime parameters common to all the VMs
8. VMs (bootstrap, master0-2, worker0-2) are generated in the designated folder but in **powered-off** state

## Final step: Power On

>Before this step is run, ensure that the dhcp server in your network (or on the helper node) uses the MAC addresses in the yaml file and maps them to the corresponding IP Addresses that you would like to use for each machine

In vCenter click on the ESXi Host (IP address) 🠮 Click on VMs tab 🠮 Cntrl-select all of the 7 machines 🠮 Right-click and choose Power 🠮 Power On

If everything goes well you should be able to log into all of the machines (from the machine which has the private key of the SSH key pair that was generated) using the private key generated in prerequistes. On **bootstrap** node running the following command will help understand if the masters are (being) setup:

```sh
journalctl -b -f -u bootkube.service
```
