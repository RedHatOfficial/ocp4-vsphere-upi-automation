Role Name
=========

A role for configuring the necessary components of an F5 Load Balancer for initial connectivity of an OpenShift 4 cluster in a UPI install.

Requirements
------------

Appropriate DNS entries for your cluster must resolve to the addresses you assign to the VIPs.

api.yourcluster.yourdomain.tld must resolve to the address assigned for the api_vip.vip_address variable

*.apps.yourcluster.yourdomain.tld must resolve to the address assigned for app_vip_https.vip_address

Role Variables
--------------

An example of the variables to be processed by this role:

# authentication information for the F5 device
provider:
  server: "192.168.122.203"
  server_port: 8443
  user: admin
  password: changeme123
  validate_certs: no

# a dictionary describing the API VIP and its dependencies
api_vip:
  vip_address: 9.9.9.9
  vip_name: "ocp4-api-vip"
  vip_snat: "automap"
  description: "VIP-for_OpenShift_API"
  pool_name: "ocp4-api-pool"
  nodes:
    node1:
      address: "1.1.1.1"
    node2:
      address: "2.2.2.2"
    node3:
      address: "3.3.3.3"

# a dictionary describing APPS VIP and its dependencies
app_vip:
  vip_address: 8.8.8.8
  vip_name: "ocp4-httpsapp-vip"
  vip_snat: "automap"
  description: "VIP-for_OpenShift_APPs_https"
  pool_name: "ocp4-https-app-pool"
  nodes:
    node1:
      address: "4.4.4.4"
    node2:
      address: "5.5.5.5"
    node3:
      address: "6.6.6.6"

# the configuration applied by this role can be rolled back by specifying the rollback variable
rollback: true

Dependencies
------------

This role requires the f5networks.f5_bigip collection.

The F5 devices require major version 12 or higher.


Example Playbook
----------------

Including an example of how to use your role (for instance, with variables passed in as parameters) is always nice for users too:

    - hosts: localhost
      gather_facts: false
      connection: local
      roles:
         - ocp4_lb_f5_init

License
-------

BSD

Author Information
------------------

Brandon Marlow - Red Hat
