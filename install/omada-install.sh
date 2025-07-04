#!/usr/bin/env bash

# Copyright (c) 2021-2025 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://www.tp-link.com/us/support/download/omada-software-controller/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt-get install -y jsvc
msg_ok "Installed Dependencies"

msg_info "Installing Azul Zulu Java"
curl -fsSL "https://keyserver.ubuntu.com/pks/lookup?op=get&search=0xB1998361219BD9C9" -o "/etc/apt/trusted.gpg.d/zulu-repo.asc"
curl -fsSL "https://cdn.azul.com/zulu/bin/zulu-repo_1.0.0-3_all.deb" -o zulu-repo.deb
$STD dpkg -i zulu-repo.deb
$STD apt-get update
$STD apt-get -y install zulu21-jre-headless
msg_ok "Installed Azul Zulu Java"

msg_info "Installing libssl (if needed)"
if ! dpkg -l | grep -q 'libssl1.1'; then
  curl -fsSL "https://security.debian.org/debian-security/pool/updates/main/o/openssl/libssl1.1_1.1.1w-0+deb11u3_amd64.deb" -o "/tmp/libssl.deb"
  $STD dpkg -i /tmp/libssl.deb
  rm -f /tmp/libssl.deb
  msg_ok "Installed libssl1.1"
fi

msg_info "Installing MongoDB"
$STD apt-get update
$STD apt-get install -y curl gnupg
wget -qO - https://www.mongodb.org/static/pgp/server-4.4.asc | $STD apt-key add -
echo "deb [ arch=amd64 ] https://repo.mongodb.org/apt/ubuntu focal/mongodb-org/4.4 multiverse" |
  $STD tee /etc/apt/sources.list.d/mongodb-org-4.4.list
$STD apt-get update

$STD apt-get install -y \
  mongodb-org=4.4.24 \
  mongodb-org-server=4.4.24 \
  mongodb-org-shell=4.4.24 \
  mongodb-org-mongos=4.4.24 \
  mongodb-org-tools=4.4.24

msg_ok "Installed MongoDB"

msg_info "Installing Omada Controller"
OMADA_URL=$(curl -fsSL "https://support.omadanetworks.com/en/download/software/omada-controller/" |
  grep -o 'https://static\.tp-link\.com/upload/software/[^"]*linux_x64[^"]*\.deb' |
  head -n1)
OMADA_PKG=$(basename "$OMADA_URL")
curl -fsSL "$OMADA_URL" -o "$OMADA_PKG"
$STD dpkg -i "$OMADA_PKG"
msg_ok "Installed Omada Controller"

motd_ssh
customize

msg_info "Cleaning up"
rm -rf "$OMADA_PKG" zulu-repo.deb
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
