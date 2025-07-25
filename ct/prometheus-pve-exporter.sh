#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/reyad010/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 community-scripts ORG
# Author: Andy Grunwald (andygrunwald)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/prometheus-pve/prometheus-pve-exporter

APP="Prometheus-PVE-Exporter"
var_tags="${var_tags:-monitoring}"
var_cpu="${var_cpu:-1}"
var_ram="${var_ram:-512}"
var_disk="${var_disk:-2}"
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
    if [[ ! -f /etc/systemd/system/prometheus-pve-exporter.service ]]; then
        msg_error "No ${APP} Installation Found!"
        exit
    fi
    msg_info "Stopping ${APP}"
    systemctl stop prometheus-pve-exporter
    msg_ok "Stopped ${APP}"

    msg_info "Updating ${APP}"
    $STD pip install prometheus-pve-exporter --default-timeout=300 --upgrade --root-user-action=ignore
    msg_ok "Updated ${APP}"

    msg_info "Starting ${APP}"
    systemctl start prometheus-pve-exporter
    msg_ok "Started ${APP}"
    msg_ok "Updated Successfully"
    exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:9221${CL}"
