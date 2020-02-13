# splunk-lab

Ansible build of splunk demo environment.

* DNS
* Domain Controller
* Enterprise PKI
* Windows Event Collector


**Usage**:

1. Ensure pywinrm is installed `pip3 install pywinrm`
2. Clone repo `git clone https://github.com/ps-sec-analytics/splunk-lab.git`
4. Change directory to `cd splunk-lab`
6. Change directory to ansible-deployment folder `cd lab-ansible`
7. Update `hosts` and `vars/vars.yml` as required
8. Update the `playbooks/build-env.yml` playbook as required
9. Run `anisble-playbook -i hosts playbooks/build-env.yml`

**Testing**:

In scenarios where ansible testing is taking place or where it cannot be installed via pacakge manager (e.g. yum), it is possible to run a _portable_ ansible installation. The following steps outline the requirements for setting this up:

1. Clone the ansible repo `git clone https://github.com/ansible/ansible.git`
2. Change director to ansible directory `cd ansible`
3. Install required python modules `pip3 install -r requirements.txt`
4. Setup ansible environment `source ./hacking/env-setup`