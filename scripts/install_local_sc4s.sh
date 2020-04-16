#!/bin/bash

display_help() {
        echo "Usage: $(basename "$0") [option...]" >&2
        echo
        echo "  $(basename "$0") -s <SPLUNK HEC SERVER:PORT>     Splunk HEC Server"
        echo "  $(basename "$0") -t <SPLUNK HEC TOKEN>     Splunk HEC Token"
        echo "  $(basename "$0") -h                       Display this help message"
        echo
        exit 1
}

while getopts s:t:h opt
do
    case "${opt}" in
        s)
            SPLUNK_HEC_SERVER=${OPTARG}
            ;;
        t)
            SPLUNK_HEC_TOKEN=${OPTARG}
            ;;
        h)
            display_help
            ;;
        \?)
            echo "Invalid Option: -$OPTARG" 1>&2
            echo
            display_help
            ;;
    esac
done

if [[ -z "$SPLUNK_HEC_SERVER" ]]
then
        echo "Required Option: -s not set" 1>&2
    echo
    display_help
fi

if [[ -z "$SPLUNK_HEC_TOKEN" ]]
then
        echo "Required Option: -t not set" 1>&2
    echo
    display_help
fi

# export splunk password and deployment server for ansible usage
export SPLUNK_HEC_SERVER=$SPLUNK_HEC_SERVER
export SPLUNK_HEC_TOKEN=$SPLUNK_HEC_TOKEN

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
#wget -O /etc/yum.repos.d/czanik-syslog-ng-stable-epel-7.repo https://copr.fedorainfracloud.org/coprs/czanik/syslog-ng-stable/repo/epel-7/czanik-syslog-ng-stable-epel-7.repo

# current config requires 3.26
echo "Setup syslog-ng 3.26 repo..."
wget -O /etc/yum.repos.d/czanik-syslog-ng326-epel-7.repo https://copr.fedorainfracloud.org/coprs/czanik/syslog-ng326/repo/epel-7/czanik-syslog-ng326-epel-7.repo
echo "Installing syslog-ng syslog-ng-http syslog-ng-python and rh-python36"
yum install -y syslog-ng syslog-ng-http syslog-ng-python rh-python36

echo "Disabling any existing syslog-ng services..."
systemctl stop syslog-ng
systemctl disable syslog-ng

# echo "Updating permission for syslog-ng user..."
# chown syslog /var/lib/syslog-ng /etc/syslog-ng

echo "Downloading latest sc4s..."
wget -c https://github.com/splunk/splunk-connect-for-syslog/releases/latest/download/baremetal.tar -O - | sudo tar -x -C /etc/syslog-ng

echo "Downloading gomplate..."
curl -o /usr/local/bin/gomplate -sSL https://github.com/hairyhenderson/gomplate/releases/download/v3.5.0/gomplate_linux-amd64
chmod 755 /usr/local/bin/gomplate

echo "Sourcing rh-python36 environment..."
source /opt/rh/rh-python36/enable
#scl enable rh-python36

echo "Creating sc4s service..."
cat <<'EOF' > /etc/systemd/system/sc4s.service 
[Unit]
Description=SC4S Syslog Daemon
Documentation=man:syslog-ng(8)
Wants=network.target network-online.target
After=network.target network-online.target

[Service]
Type=notify
ExecStartPre=/opt/sc4s/bin/preconfig.sh
ExecStart=/usr/sbin/syslog-ng -F $SYSLOGNG_OPTS -p /var/run/syslogd.pid
ExecReload=/bin/kill -HUP $MAINPID
EnvironmentFile=-/etc/default/syslog-ng
EnvironmentFile=-/etc/sysconfig/syslog-ng
EnvironmentFile=/opt/sc4s/env_file
StandardOutput=journal
StandardError=journal
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

echo "Creating sc4s service preconfig..."
cat <<'EOF' > /opt/sc4s/bin/preconfig.sh
#!/usr/bin/bash
source scl_source enable rh-python36

cd /etc/syslog-ng
#The following is no longer needed but retained as a comment just in case we run into command line length issues
#for d in $(find /opt/syslog-ng/etc -type d)
#do
#  echo Templating conf for $d
#  gomplate \
#    --input-dir=$d \
#    --template t=etc/go_templates/  \
#    --exclude=*.conf --exclude=*.csv --exclude=*.t --exclude=.*\
#    --output-map="$d/{{ .in | strings.ReplaceAll \".conf.tmpl\" \".conf\" }}"
#done

gomplate $(find . -name *.tmpl | sed -E 's/^(\/.*\/)*(.*)\..*$/--file=\2.tmpl --out=\2/') --template t=go_templates/

mkdir -p /etc/syslog-ng/conf.d/local/context/
mkdir -p /etc/syslog-ng/conf.d/local/config/
cp /etc/syslog-ng/context_templates/* /etc/syslog-ng/conf.d/local/context/
for file in /etc/syslog-ng/conf.d/local/context/*.example ; do cp -v -n $file ${file%.example}; done
cp -f -v -R /etc/syslog-ng/local_config/* /etc/syslog-ng/conf.d/local/config/
EOF

echo "Update permission for preconfig..."
chmod 755 /opt/sc4s/bin/preconfig.sh

echo "Execute first-time run preconfig..."
/opt/sc4s/bin/preconfig.sh
#ln -sf /opt/sc4s/bin/preconfig.sh /usr/local/bin/

echo "Create sc4s env file..."
cat <<EOF > /opt/sc4s/env_file
SYSLOGNG_OPTS=-f /etc/syslog-ng/syslog-ng.conf 
SPLUNK_HEC_URL=https://${SPLUNK_HEC_SERVER}
SPLUNK_HEC_TOKEN=${SPLUNK_HEC_TOKEN}
SC4S_DEST_SPLUNK_HEC_WORKERS=6
#Uncomment the following line if using untrusted SSL certificates
#SC4S_DEST_SPLUNK_HEC_TLS_VERIFY=no
SC4S_LISTEN_DEFAULT_TCP_PORT=514
SC4S_LISTEN_DEFAULT_UDP_PORT=514
#SC4S_LISTEN_DEFAULT_TLS_PORT=6514
EOF

echo "Starting daemon-reload"
systemctl daemon-reload
echo "Enabling sc4s"
systemctl enable sc4s
echo "Starting sc4s"
systemctl start sc4s

logger -P 514 -T -n localhost "test TCP"
logger -P 514 -d -n localhost "test UDP"

echo "Script complete."