#!/bin/bash

#!/bin/bash

echo "Starting Script..."

DIR="$(cd -P "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CENTOS=$(rpm --query centos-release > /dev/null 2>&1; echo $?)
REDHAT=$(rpm --query redhat-release > /dev/null 2>&1; echo $?)
SC4S_OPT="/opt/sc4s"

if [ ${CENTOS} -eq 0 ]; then
    echo "OS: CentOS"
elif [ ${REDHAT} -eq 0 ]; then
    echo "OS: Redhat"
else
    echo "OS: ERROR Unknown"
    exit 1
fi

# echo "Creating non-root syslog user..."
# adduser syslog && addgroup

echo "Creating sc4s directory: ${SC4S_OPT}/bin"
mkdir -p ${SC4S_OPT}/bin

# centos
if [ ${CENTOS} -eq 0 ]; then
    echo "Installing epel-release..."
    yum install -y epel-release
    echo "Installing wget curl and centos-release-scl..."
    yum install -y wget curl centos-release-scl
# redhat
else
    echo "Installing wget and curl..."
    yum install -y wget curl
    echo "Downloading epel rpm..."
    wget -O /tmp/epel-release-latest-7.noarch.rpm https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
    echo "Installing epel rpm..."
    yum -y install /tmp/epel-release-latest-*.noarch.rpm -y
    echo "Updating subscription..."
    subscription-manager repos --enable rhel-7-server-optional-rpms
fi

# stable release (at the time of writing this is only 3.25)
echo "Setup syslog-ng 3.25 repo..."
wget -O /etc/yum.repos.d/czanik-syslog-ng-stable-epel-7.repo https://copr.fedorainfracloud.org/coprs/czanik/syslog-ng-stable/repo/epel-7/czanik-syslog-ng-stable-epel-7.repo
echo "Installing syslog-ng syslog-ng-http syslog-ng-python and rh-python36"
yum install -y syslog-ng syslog-ng-http syslog-ng-python rh-python36

cat <<'EOF' > /etc/syslog-ng/syslog-ng.conf
@version:3.25

# syslog-ng configuration file.
#
#
options {
chain_hostnames(no);
create_dirs (yes);
dir_perm(0755);
dns_cache(yes);
keep_hostname(yes);
log_fifo_size(2048);
log_msg_size(8192);
perm(0644);
time_reopen (10);
use_dns(yes);
use_fqdn(yes);
};

source s_network {
udp(port(514));
tcp(port(514));
};

#Destinations
destination d_cisco_asa { file("/var/log/splunk-syslog/$HOST.log” create_dirs(yes)); };
destination d_palo_alto { file("/var/log/splunk-syslog/$HOST.log” create_dirs(yes)); };
destination d_all { file("/var/log/splunk-syslog/$HOST.log” create_dirs(yes)); };

# Filters
filter f_cisco_asa { match(“%ASA” value(“PROGRAM”)) or match(“%ASA” value(“MESSAGE”)); };
filter f_palo_alto { match(“009401000570” value(“PROGRAM”)) or match(“009401000570” value(“MESSAGE”)); };
filter f_all { not (
filter(f_cisco_asa) or
filter(f_palo_alto)
);
};
# Log
log { source(s_network); filter(f_cisco_asa); destination(d_cisco_asa); };
log { source(s_network); filter(f_palo_alto); destination(d_palo_alto); };
log { source(s_network); filter(f_all); destination(d_all); };
EOF

mkdir -p /var/log/splunk-syslog
chown -R splunk:splunk /var/log/splunk-syslog
chmod -R 0755 /var/log/splunk-syslog

systemctl restart rsyslog

cat <<'EOF' > /etc/logrotate.d/splunk-syslog
/var/log/splunk-syslog/*.log
{
    daily
    compress
    delaycompress
    rotate 4
    ifempty
    maxage 7
    nocreate
    missingok
    sharedscripts
    postrotate
    /bin/kill -HUP `cat /var/run/syslogd.pid 2> /dev/null` 2> /dev/null || true
    endscript
}
EOF

# alternative log rotation method is via cronjob

firewall-cmd --permanent --zone=public --add-port=514/tcp 
firewall-cmd --permanent --zone=public --add-port=514/udp
firewall-cmd --reload

logger -P 514 -T -n localhost "test TCP"
logger -P 514 -d -n localhost "test UDP"