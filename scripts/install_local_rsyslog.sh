#!/bin/bash

cat <<'EOF' > /etc/rsyslog.d/splunk.conf
#
# Include all config files for splunk /etc/rsyslog.d/
#

module(load="imudp")
module(load="imtcp")

# ****************** TEMPLATES CONFIGURATION ************************
# Define the RSysLog logging format for writing events to syslog.
# template (name="rsyslog-fmt" type="string" string="%msg:::sp-if-no-1st-sp%%msg:::drop-last-lf%\n" )
# template (name="splunk" type="string" string="%TIMESTAMP% %HOSTNAME% %syslogtag%%msg:::sp-if-no-1st-sp%%msg:::drop-last-lf%\n")

# ****************** TEMPLATES FILE FORMAT CONFIGURATION ************************
template (name="msgFileFormat" type="string" string="%msg%\n" )
template (name="rawmsgFileFormat" type="string" string="%rawmsg%\n" )
template (name="rawmsgafterpriFileFormat" type="string" string="%rawmsg-after-pri%\n" )

# ****************** TEMPLATES DESTINATON CONFIGURATION ************************
template(name="TmplMsg" type="string"
    string="/var/log/splunk-syslog/%HOSTNAME%.log"
)

# ****************** FILTERS CONFIGURATION ************************
ruleset(name="default_file"){
     action(type="omfile" dynafile="TmplMsg" dirCreateMode="0755" FileCreateMode="0600" dirGroup="splunk" fileGroup="splunk" dirOwner="splunk" fileOwner="splunk" template="rawmsgafterpriFileFormat")
}


# inputs
input(type="imtcp" port="514" ruleset="default_file")
input(type="imudp" port="514" ruleset="default_file")
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

firewall-cmd --permanent --zone=public --add-port=514/tcp 
firewall-cmd --permanent --zone=public --add-port=514/udp
firewall-cmd --reload

logger -P 514 -T -n localhost "test TCP"
logger -P 514 -d -n localhost "test UDP"