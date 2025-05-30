#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/reyad010/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://www.tp-link.com/us/support/download/omada-software-controller/

APP="Omada"
var_tags="${var_tags:-tp-link;controller}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-3072}"
var_disk="${var_disk:-8}"
var_os="${var_os:-debian}"
var_version="${var_version:-12}"
var_unprivileged="${var_unprivileged:-1}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources
  if [[ ! -d /opt/tplink ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  msg_info "Updating MongoDB"
  $STD apt-get update
  $STD apt-get install -y curl gnupg
  wget -qO - https://www.mongodb.org/static/pgp/server-4.4.asc | $STD apt-key add -
  echo "deb [ arch=amd64 ] https://repo.mongodb.org/apt/ubuntu focal/mongodb-org/4.4 multiverse" \
  | $STD tee /etc/apt/sources.list.d/mongodb-org-4.4.list
  $STD apt-get update

  msg_ok "Updated MongoDB"

  msg_info "Checking if right Azul Zulu Java is installed"
  java_version=$(java -version 2>&1 | awk -F[\"_] '/version/ {print $2}')
  if [[ "$java_version" =~ ^1\.8\.* ]]; then
    $STD apt-get remove --purge -y zulu8-jdk
    $STD apt-get -y install zulu21-jre-headless
    msg_ok "Updated Azul Zulu Java to 21"
  else
    msg_ok "Azul Zulu Java 21 already installed"
  fi

  msg_info "Updating Omada Controller"
  OMADA_URL=$(curl -fsSL "https://support.omadanetworks.com/en/download/software/omada-controller/" |
    grep -o 'https://static\.tp-link\.com/upload/software/[^"]*linux_x64[^"]*\.deb' |
    head -n1)
  OMADA_PKG=$(basename "$OMADA_URL")
  if [ -z "$OMADA_PKG" ]; then
    msg_error "Could not retrieve Omada package – server may be down."
    exit 1
  fi
  curl -fsSL "$OMADA_URL" -o "$OMADA_PKG"
  export DEBIAN_FRONTEND=noninteractive
  $STD dpkg -i "$OMADA_PKG"
  rm -f "$OMADA_PKG"
  msg_ok "Updated Omada Controller"
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}https://${IP}:8043${CL}"
