#!/bin/bash

# Custom
uuid=$(cat /proc/sys/kernel/random/uuid)
port=18080

# Download v2ray
tPath="/tmp/v2r1"
mkdir -p ${tPath}
curl -L -H "Cache-Control: no-cache" -o ${tPath}/v2ray.zip https://github.com/v2fly/v2ray-core/releases/download/v5.12.1/v2ray-linux-64.zip
unzip ${tPath}/v2ray.zip -d ${tPath}
chmod +x ${tPath}/v2ray

# Install v2ray
dPath="/usr/local/bin/v2ray"
mkdir -p ${dPath}
mkdir /var/log/v2ray/
cp ${tPath}/v2ray ${dPath}/
cp ${tPath}/geosite.dat ${dPath}/
cp ${tPath}/geoip.dat ${dPath}/
cp ${tPath}/geoip-only-cn-private.dat ${dPath}/

# Remove temporary directory
rm -fr ${tPath}

# Create v2ray configuration file
mkdir -p /usr/local/etc/v2ray
cat << EOF > /usr/local/etc/v2ray/config.json
{
  "log": {
    "access": "/var/log/v2ray/access.log",
    "error": "/var/log/v2ray/error.log",
    "loglevel": "warning"
  },
  "inbounds": [
  {
    "port": ${port},
    "listen": "127.0.0.1", 
    "tag": "VMESS-in", 
    "protocol": "VMESS", 
    "settings": {
      "clients": [
      {
        "id": "${uuid}",
        "alterId": 0
      }],
      "decryption": "none"
    },
    "streamSettings": {
      "network": "ws", 
      "wsSettings": {
	      "path": "/Admin"
      }
    }
  }],
  "outbounds": [
  {
    "protocol": "freedom", 
    "settings": { }, 
    "tag": "direct"
  },{
    "protocol": "blackhole", 
    "settings": { }, 
    "tag": "blocked"
  }],
  "dns": {
    "servers": [
      "https+local://1.1.1.1/dns-query",
      "1.1.1.1",
      "1.0.0.1",
      "8.8.8.8",
      "8.8.4.4",
      "localhost"
    ]
  },
  "routing": {
    "domainStrategy": "AsIs",
    "rules": [
    {
      "type": "field",
      "inboundTag": [
        "VMESS-in"
      ],
      "outboundTag": "direct"
    }]
  }
}
EOF

# Create service file
cat << EOF > /etc/systemd/system/v2ray.service
[Unit]
Description=V2Ray Service
Documentation=https://www.v2fly.org/
After=network.target nss-lookup.target

[Service]
User=root
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
NoNewPrivileges=true
ExecStart=${dPath}/v2ray run -config /usr/local/etc/v2ray/config.json
Restart=on-failure
RestartPreventExitStatus=23

[Install]
WantedBy=multi-user.target
EOF
chmod +x /etc/systemd/system/v2ray.service

# Run v2ray
systemctl enable v2ray
systemctl start v2ray
