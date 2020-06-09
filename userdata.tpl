#!/usr/bin/env bash

#####
echo "Starting deployment of uerdata"

log() {
  echo -e "$(date "+%Y-%m-%d %H:%M:%S") $1: $2"
}

#####
log "INFO" "Set hostname"

echo ${common_name} > /etc/hostname
hostname $(cat /etc/hostname)

#####
log "INFO" "Install Postgress"

apt update
apt install -y postgresql postgresql-contrib docker.io

#####
log "INFO" "Create concourse user"

useradd \
  --system \
  --home ${concourse_config_dir} \
  --shell /bin/bash \
  ${concourse_user}

#####
log "INFO" "Create concourse user in Postgres"

sudo -u postgres createuser ${concourse_user}
sudo -u postgres psql -c "ALTER USER ${concourse_user} WITH ENCRYPTED password '${postgres_password}';"

#####
log "INFO" "create air traffic control (atc) database owned by user concourse"

sudo -u postgres createdb --owner=${concourse_user} atc

#####
log "INFO" "Download and unpack concourse"

mkdir -p \
    ${src_dir} \
    ${concourse_config_dir} \
    ${concourse_config_dir}/ssl \
    ${top_dir} && \
  chown ${concourse_user}:${concourse_user} ${concourse_config_dir} && \
  cd ${src_dir} && \
  curl -sL -o concourse.tgz ${concourse_url} && \
  tar xfz ${src_dir}/concourse.tgz && \
  tar xfz ${src_dir}/concourse/fly-assets/fly-linux-amd64.tgz && \
  mv ${src_dir}/fly concourse/bin/fly && \
  mv ${src_dir}/concourse ${top_dir}/concourse

echo 'PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:${top_dir}/concourse/bin"' > /etc/environment

#####
log "INFO" "Generate SSH Keys"

cat << EOF > ${concourse_config_dir}/generate_keys
#!/bin/bash

cd ${concourse_config_dir}

for i in session_signing_key tsa_host_key worker_key
do
  ${top_dir}/concourse/bin/concourse generate-key \
    -t ssh \
    -f ${concourse_config_dir}/\$i
done

cp ${concourse_config_dir}/worker_key.pub \
  ${concourse_config_dir}/authorized_worker_keys
EOF

chown ${concourse_user}:${concourse_user} \
  ${concourse_config_dir}/generate_keys
chmod 0755 ${concourse_config_dir}/generate_keys

sudo -u ${concourse_user} ${concourse_config_dir}/generate_keys

#####
log "INFO" "Place PKI Certs"

cat << EOF > ${concourse_config_dir}/ssl/privkey.pem
${tls_private_key}
EOF

cat << EOF > ${concourse_config_dir}/ssl/fullchain.pem
${tls_fullchain}
EOF

#####
log "INFO" "Place env file for web"

cat << EOF > ${concourse_config_dir}/${web_env_file}
CONCOURSE_SESSION_SIGNING_KEY=${concourse_config_dir}/session_signing_key
CONCOURSE_TSA_HOST_KEY=${concourse_config_dir}/tsa_host_key
CONCOURSE_TSA_AUTHORIZED_KEYS=${concourse_config_dir}/authorized_worker_keys

CONCOURSE_ADD_LOCAL_USER=${concourse_username}:${concourse_password}
CONCOURSE_MAIN_TEAM_LOCAL_USER=${concourse_username}

CONCOURSE_POSTGRES_USER=concourse
CONCOURSE_POSTGRES_PASSWORD=${postgres_password}
CONCOURSE_POSTGRES_DATABASE=atc

CONCOURSE_TLS_KEY=${concourse_config_dir}/ssl/privkey.pem
CONCOURSE_TLS_CERT=${concourse_config_dir}/ssl/fullchain.pem

CONCOURSE_BIND_IP=0.0.0.0
CONCOURSE_TLS_BIND_PORT=${concourse_tls_bind_port}

CONCOURSE_EXTERNAL_URL=https://${common_name}:${concourse_tls_bind_port}
EOF

#####
log "INFO" "Place env file for worker"

cat << EOF > ${concourse_config_dir}/${worker_env_file}
CONCOURSE_WORK_DIR=/var/lib/concourse
CONCOURSE_TSA_WORKER_PRIVATE_KEY=${concourse_config_dir}/worker_key
CONCOURSE_TSA_PUBLIC_KEY=${concourse_config_dir}/tsa_host_key.pub
CONCOURSE_GARDEN_DNS_SERVER=${concourse_garden_dns_server}
EOF

#####
log "INFO" "Set permissions"

chown -R ${concourse_user}:${concourse_user} ${concourse_config_dir}
chmod 0600 \
  ${concourse_config_dir}/${web_env_file} \
  ${concourse_config_dir}/${worker_env_file} \
  ${concourse_config_dir}/*_key

#####
log "INFO" "Place systemd script for concourse web"

cat << EOF > /etc/systemd/system/concourse-web.service
[Unit]
Description=Concourse CI web process (ATC and TSA)
After=postgresql.service

[Service]
User=concourse
Restart=on-failure
EnvironmentFile=${concourse_config_dir}/${web_env_file}
ExecStart=${top_dir}/concourse/bin/concourse web

[Install]
WantedBy=multi-user.target
EOF

#####
log "INFO" "Place systemd script for concourse worker"

cat << EOF > /etc/systemd/system/concourse-worker.service
[Unit]
Description=Concourse CI worker process
After=concourse-web.service

[Service]
User=root
Restart=on-failure
EnvironmentFile=${concourse_config_dir}/${worker_env_file}
ExecStart=${top_dir}/concourse/bin/concourse worker

[Install]
WantedBy=multi-user.target
EOF

#####
log "INFO" "Enable and start services."

systemctl daemon-reload
systemctl enable concourse-web concourse-worker
systemctl start concourse-web
sleep 5
systemctl start concourse-worker

#####
log "INFO" "Finished running user data script."
#####
