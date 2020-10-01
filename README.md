# splunk-lab

Ansible build of splunk demo environment.

* DNS
* Domain Controller
* Enterprise PKI
* Windows Event Collector
* Certificate Creation


**Usage**:

1. Ensure Windows hosts have been prepared for ansible WinRM `Invoke-Expression ((New-Object System.Net.Webclient).DownloadString('https://raw.githubusercontent.com/ansible/ansible/devel/examples/scripts/ConfigureRemotingForAnsible.ps1'))`
2. Ensure pywinrm and requests is installed `pip3 install pywinrm requests`
3. Clone repo `git clone https://github.com/ps-sec-analytics/splunk-lab.git`
4. Change directory to `cd splunk-lab`
5. Change directory to ansible-deployment folder `cd lab-ansible`
6. Update `hosts` and `vars/vars.yml` as required
7. Update the `playbooks/build-env.yml` playbook as required
8. Run `anisble-playbook -i hosts playbooks/build-env.yml`

**Testing**:

In scenarios where ansible testing is taking place or where it cannot be installed via pacakge manager (e.g. yum), it is possible to run a _portable_ ansible installation. The following steps outline the requirements for setting this up:

1. Clone the ansible repo `git clone --branch stable-2.9 https://github.com/ansible/ansible.git`
2. Change director to ansible directory `cd ansible`
3. Install required python modules `pip3 install -r requirements.txt`
4. Install pywinrm and requests for Windows `pip3 install requests pywinrm`
5. Ensure ansible.windows modules are installed `ansible-galaxy collection install ansible.windows community.windows`
5. Setup ansible environment `source ./hacking/env-setup`
