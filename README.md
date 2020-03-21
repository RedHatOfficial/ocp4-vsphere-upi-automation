# OCP4 on VMware vSphere UPI Automation

The goal of this repo is to make deploying and redeploying a new OpenShift v4 cluster a snap. Using the same repo and with minor tweaks, it can be applied to any version of OpenShift higher than the current version of 4.3.

> This repo is most ideal for Home Lab and Proof-of-Concept scenarios. Having said that, if prerequistes (below) can be met and if the vCenter service account can be locked down to access only certain resources and perform only certain actions, the same repo can then be used for DEV or higher environments. Refer to this [link](https://vmware.github.io/vsphere-storage-for-kubernetes/documentation/vcp-roles.html) for more details on required permissions for a vCenter service account.

## Prerequisites

1. vSphere ESXi and vCenter 6.7 installed 
2. A datacenter created with a vSphere host added to it, a datastore exists and has adequate capacity
3. Strongly recommend having a [helper node](https://github.com/RedHatOfficial/ocp4-helpernode) running in the same network to provide all the necessary services such as [DHCP/DNS/HAProxy as LB]. If using **helper node**, the MAC addresses for the machines should match between repos.
   * The necessary services such as [DHCP/DNS/HAProxy as LB] must be up and running before this repo can be used
   * This repo/approach works only when DHCP provides IP addresses for VMs.
4. Ansible 2.8.5 or 2.9.3 installed, ideally with **Python 3** on the machine where this repo is cloned 
   * To install a specific version of Ansible you can run a command like: `sudo dnf -y install ansible-2.8.5`


## Automatic generation of ignition and other supporting files

### Prerequisites 
> Pre-populated entries in **group_vars/all.yml** are ready to be used unless you want to customize further
1. Get the ***pull secret*** from [here](https://cloud.redhat.com/OpenShift/install/vsphere/user-provisioned)
2. Get the vCenter details:
   1. IP address
   2. Service account username (can be the same as admin)
   3. Service account password (can be the same as admin)
   4. Admin account username 
   5. Admin account password
   6. Datacenter name *(created in the prerequisites mentioned above)*
   7. Datastore name
3. Actual links to the OpenShift Client, Install and .ova binaries *(pre-populated for 4.3.x)*
4. Downloadable link to `govc` (vSphere CLI, *pre-populated*)
5. OpenShift cluster 
   1. base domain *(pre-populated with **example.com**)*
   2. cluster name *(pre-populated with **ocp4**)*
6. HTTP URL of the ***bootstrap.ign*** file *(pre-populated with a example config pointing to helper node)*
7. Update the inventory file: **staging** and under the `webservers.hosts` entry, use one of the below : 
   * **localhost** : if the `ansible-playbook` is being run on the same host  as the webserver that would eventually host bootstrap.ign file
   * the IP address or FQDN of the machine that would run the webserver. 

The step **#6** needn't exist at the time of running the setup/installation step, so provide an accurate guess of where and at what context path **bootstrap.ign** will eventually be served 
   
### Setup and Installation

With all the details in hand from the prerequisites, populate the **group_vars/all.yml**, configure `ansible.cfg` based on your environment and then follow one of the three options listed below.

#### Update the `ansible.cfg` based on your needs

* Running the playbook as a **root** user
  * If the localhost runs the webserver
      ```
      [defaults]
      host_key_checking = False 
      ```
  * If the remote host runs the webserver
      ```
      [defaults]
      host_key_checking = False
      remote_user = root
      ask_pass = True 
      ```
* Running the playbook as a **non-root** user
  * If the localhost runs the webserver
      ```
      [defaults]
      host_key_checking = False 

      [privilege_escalation]
      become_ask_pass = True
      ```
  * If the remote host runs the webserver
      ```
      [defaults]
      host_key_checking = False 
      remote_user = root
      ask_pass = True

      [privilege_escalation]
      become_ask_pass = True
      ```

#### Option 1: DHCP + use of OVA template
```sh 
ansible-playbook -i staging dhcp_ova.yml
```
#### Option 2: DHCP + PXE boot
```sh 
ansible-playbook -i staging dhcp_pxe.yml
```
#### Option 3: ISO + Static IPs
```sh 
ansible-playbook -i staging static_ips.yml
```

#### Miscellaneous
* If vCenter folder already exists with the template because you set the vCenter the last time you ran the ansible playbook but want a fresh deployment of VMs **after** you have erased all the existing VMs in the folder, append the following to the command you chose in the above step

   ```sh 
   --extra-vars "vcenter_preqs_met=true"
   ```
* If would rather want to clean all folders `bin`, `downloads`, `install-dir` and re-download all the artifacts, append the following to the command you chose in the first step
   ```sh 
   --extra-vars "clean=true"
   ```
### Expected Outcome

1. Necessary Linux packages installed for the installation
2. SSH key-pair generated, with key `~/.ssh/ocp4` and public key `~/.ssh/ocp4.pub`
3. Necessary folders [bin, downloads, install-dir] created
4. OpenShift client, install and .ova binaries downloaded to the **downloads** folder
5. Unzipped versions of the binaries installed in the **bin** folder
6. In the **install-dir** folder:
   1. append-bootstrap.ign file with the HTTP URL of the **boostrap.ign** file
   2. master.ign and worker.ign
   3. base64 encoded files (append-bootstrap.64, master.64, worker.64) for (append-bootstrap.ign, master.ign, worker.ign) respectiviely. This step assumes you have **base64** installed and in your **$PATH**
7. The **bootstrap.ign** is copied over to the web server in the designated location
8. A folder is created in the vCenter under the mentioned datacenter and the template file is imported 
9. The template file is edited to carry certain default settings and runtime parameters common to all the VMs
10. VMs (bootstrap, master0-2, worker0-2) are generated in the designated folder and (in state of) **poweredon** 

## Final Check:

If everything goes well you should be able to log into all of the machines using the following command:

```sh
ssh -i ~/.ssh/ocp4 core@<IP_ADDRESS_OF_BOOTSTRAP_NODE>
```

Once logged in, on **bootstrap** node run the following command to understand if/how the masters are (being) setup:

```sh
journalctl -b -f -u bootkube.service
```
