#!/bin/bash
cd /root
(
cat <<EOF
#!/bin/bash
# 兼容zsh
export DISABLE_AUTO_TITLE="true"
session="quil"
tmux has-session -t \$session
if [ \$? = 0 ];then
    tmux attach-session -t \$session
    exit
fi
tmux new-session -d -s \$session
tmux send-keys -t \$session:0 'cd /root/ceremonyclient/node/' C-m
tmux send-keys -t \$session:0 'gvm use go1.20.14' C-m
tmux send-keys -t \$session:0 'GOEXPERIMENT=arenas go run ./... ' C-m
EOF
) > /root/start_quil.sh

chmod +x  /root/start_quil.sh



(
cat <<EOF
session="quil"
tmux kill-session -t \$session
EOF
)> /root/stop_quil.sh
chmod +x  /root/stop_quil.sh

(
cat <<EOF
/bin/sh /root/stop_quil.sh
/bin/sh /root/start_quil.sh
EOF
)> /root/restart_quil.sh
chmod +x  /root/stop_quil.sh




pip3 install grpc_requests 


(
cat <<EOF
# -*- coding: utf-8 -*-
import os
import json
import time
import functools
import signal

'''
pip3 install grpc_requests
0 */4 * * * /bin/sh /root/quil_node_auto_restart.sh

'''
from grpc_requests import Client


def timeout(sec):
    """
    timeout decorator
    :param sec: function raise TimeoutError after ? seconds
    """

    def decorator(func):
        @functools.wraps(func)
        def wrapped_func(*args, **kwargs):

            def _handle_timeout(signum, frame):
                err_msg = f'Function {func.__name__} timed out after {sec} seconds'
                raise TimeoutError(err_msg)

            signal.signal(signal.SIGALRM, _handle_timeout)
            signal.alarm(sec)
            try:
                result = func(*args, **kwargs)
            finally:
                signal.alarm(0)
            return result

        return wrapped_func

    return decorator


class Manager:
    def __init__(self):
        pass

    @timeout(10)
    def getPeerInfo(self):
        client = Client.get_by_endpoint("localhost:8337")

        request_data = {}
        response = client.request("quilibrium.node.node.pb.NodeService", "GetNodeInfo", request_data)
        return response

    def write_max_frame(self, max_frame):
        with open("/root/.last_max_frame", 'w+') as f:
            print("{}".format(max_frame), file=f)

    def get_max_frame(self):
        try:
            with open("/root/.last_max_frame", 'r+') as f:
                max_frame = int(str(f.read()).strip())
                return max_frame
        except:
            return -1

    def start(self):
        try:
            last_max_frame = self.get_max_frame()
            info = self.getPeerInfo()
            max_frame = int(info["max_frame"])
            if max_frame > last_max_frame:
                print("node status is normal...")
                self.write_max_frame(max_frame)
                pass
            else:
                print("node status error...")
                os.system("/root/stop_quil.sh")
                os.system("/root/start_quil.sh")
        except Exception as e:
            print(e)
            print("node status error...")
            os.system("/root/stop_quil.sh")
            os.system("/root/start_quil.sh")


if __name__ == "__main__":
    manager = Manager()
    manager.start()

EOF
) >/root/quil_node_auto_restart.py

(
cat <<EOF
#!/bin/bash
cd /root
python3 quil_node_auto_restart.py
EOF
) >/root/quil_restart.sh
chmod +x /root/quil_restart.sh


(
cat <<EOF
@reboot /root/start.sh
# 00 00 * * * /usr/sbin/reboot
0 */4 * * * /bin/sh /root/quil_restart.sh
EOF
) >/var/spool/cron/crontabs/root

crontab -u root /var/spool/cron/crontabs/root
service cron restart