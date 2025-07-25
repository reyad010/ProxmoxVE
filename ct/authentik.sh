#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/reyad010/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 community-scripts ORG
# Author: remz1337
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://goauthentik.io/

APP="Authentik"
var_tags="${var_tags:-identity-provider}"
var_disk="${var_disk:-12}"
var_cpu="${var_cpu:-6}"
var_ram="${var_ram:-10240}"
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
  if [[ ! -f /etc/systemd/system/authentik-server.service ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi
  RELEASE=$(curl -fsSL https://api.github.com/repos/goauthentik/authentik/releases/latest | grep "tarball_url" | awk '{print substr($2, 2, length($2)-3)}')
  if [[ "${RELEASE}" != "$(cat /opt/${APP}_version.txt)" ]] || [[ ! -f /opt/${APP}_version.txt ]]; then
    NODE_VERSION="22"
    PG_VERSION="16"
    setup_uv
    install_postgresql
    install_node_and_modules
    install_go

    msg_info "Stopping ${APP}"
    systemctl stop authentik-server
    systemctl stop authentik-worker
    msg_ok "Stopped ${APP}"

    msg_info "Building ${APP} website"
    mkdir -p /opt/authentik
    curl -fsSL "${RELEASE}" -o "authentik.tar.gz"
    tar -xzf authentik.tar.gz -C /opt/authentik --strip-components 1 --overwrite
    rm -rf authentik.tar.gz
    cd /opt/authentik/website
    $STD npm install
    $STD npm run build-bundled
    cd /opt/authentik/web
    $STD npm install
    $STD npm run build
    msg_ok "Built ${APP} website"

    msg_info "Building ${APP} server"
    cd /opt/authentik
    go mod download
    go build -o /go/authentik ./cmd/server
    go build -o /opt/authentik/authentik-server /opt/authentik/cmd/server/
    msg_ok "Built ${APP} server"

    msg_info "Building Authentik"
    cd /opt/authentik
    $STD uv sync --frozen --no-install-project --no-dev
    uv run python -m lifecycle.migrate
    ln -s /opt/authentik/.venv/bin/gunicorn /usr/local/bin/gunicorn
    ln -s /opt/authentik/.venv/bin/celery /usr/local/bin/celery
    msg_ok "Authentik built"

    echo "${RELEASE}" >/opt/${APP}_version.txt
    msg_ok "Updated ${APP} to v${RELEASE}"

    msg_info "Starting ${APP}"
    systemctl start authentik-server
    systemctl start authentik-worker
    msg_ok "Started ${APP}"
  else
    msg_ok "No update required. ${APP} is already at v${RELEASE}"
  fi
  exit
}

start
build_container
description

echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:9000/if/flow/initial-setup/${CL}"
