#!/bin/bash

yum-config-manager --enable rhel-7-server-extras-rpms
yum-config-manager --enable rhel-7-server-optional-rpms
for i in $(yum repolist | egrep -i '(source|debug)' | cut -d/ -f1); do yum-config-manager --disable $i; echo; done

yum update -y
yum install -y yum-utils device-mapper-persistent-data lvm2 yum-plugin-versionlock

DOCKER_EE_SUBSCRIPTION="{{ DOCKER_EE_SUBSCRIPTION }}"
REPOSITORY_URL="https://storebits.docker.com/ee/redhat/${DOCKER_EE_SUBSCRIPTION}/rhel"
curl -sSL ${REPOSITORY_URL}/gpg -o /tmp/storebits.gpg
rpm --import /tmp/storebits.gpg
cat <<EOF > /etc/yum.repos.d/docker-ee.repo
[docker-ee.repo]
baseurl = ${REPOSITORY_URL}/7/x86_64/stable-19.03
name = Docker EE repository
EOF
yum makecache
yum install -y docker-ee-19.03.8 docker-ee-cli-19.03.8

systemctl enable firewalld
systemctl start firewalld

firewall-cmd --permanent --add-port=22/tcp --add-port=80/tcp --add-port=179/tcp --add-port=443/tcp --add-port=2375/tcp --add-port=2376/tcp --add-port=2377/tcp --add-port=4789/udp --add-port=6443/tcp --add-port=6444/tcp --add-port=7946/udp --add-port=7946/tcp --add-port=10250/tcp --add-port=12376/tcp --add-port=12378/tcp --add-port=12379/tcp --add-port=12380-12388/tcp --add-port=9099/tcp --add-port=32768-32679/tcp

mkdir /etc/kubernetes

cat <<EOF > /etc/docker/daemon.json
{
  "bip": "10.115.12.1/24",
  "storage-driver": "overlay2",
  "log-driver": "journald"
}
EOF

systemctl enable docker.service
systemctl start docker.service

docker network create \
  --subnet 10.115.13.1/24 \
  --opt com.docker.network.bridge.name=docker_gwbridge \
  --opt com.docker.network.bridge.enable_icc=false \
  --opt com.docker.network.bridge.enable_ip_masquerade=true \
  docker_gwbridge

package-cleanup --oldkernels -y --count=1

