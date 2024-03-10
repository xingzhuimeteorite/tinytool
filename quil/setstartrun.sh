cd  /etc/systemd/system
echo '#!/bin/bash' > start_quil.sh
echo '' >> start_quil.sh
echo '# 检查是否存在 screen 会话' >> start_quil.sh
echo 'if screen -list | grep -q "node"; then' >> start_quil.sh
echo '  echo "Screen session '\''node'\'' already exists."' >> start_quil.sh
echo '  exit 1' >> start_quil.sh
echo 'fi' >> start_quil.sh
echo '' >> start_quil.sh
echo '# 启动 screen 会话并执行命令' >> start_quil.sh
echo 'cd /quilibrium/ceremonyclient/node/' >> start_quil.sh
echo 'screen -dmS node bash -c "/quilibrium/ceremonyclient/node/poor_mans_cd.sh"' >> start_quil.sh
echo '' >> start_quil.sh
echo 'echo "Screen session '\''node'\'' started."' >> start_quil.sh
chmod +x start_quil.sh
bash start_quil.sh

UNIT_FILE="/etc/systemd/system/start_quil.service"
USERNAME="root"
GROUPNAME="root"

cat <<EOF | sudo tee $UNIT_FILE
[Unit]
Description=Start Quil Script
After=network.target

[Service]
ExecStart=/etc/systemd/system/start_quil.sh
WorkingDirectory=/etc/systemd/system/
Restart=always
User=$USERNAME
Group=$GROUPNAME
StandardOutput=syslog

[Install]
WantedBy=default.target
EOF
echo "Systemd unit file created: $UNIT_FILE"