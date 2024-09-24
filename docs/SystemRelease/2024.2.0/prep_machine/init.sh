sudo tee /etc/systemd/system/rc-local.service << END
[Unit]
 Description=/etc/rc.local Compatibility
 ConditionPathExists=/etc/rc.local

[Service]
 Type=forking
 ExecStart=/etc/rc.local start
 TimeoutSec=0
 StandardOutput=tty
 RemainAfterExit=yes
 SysVStartPriority=99

[Install]
 WantedBy=multi-user.target
END

sudo tee /etc/rc.local << END
#!/bin/bash
# run systemd with CPU affinity
systemctl set-property init.scope AllowedCPUs=0,16

# srsRAN Performance script
sysctl -w net.core.wmem_max=33554432
sysctl -w net.core.rmem_max=33554432
sysctl -w net.core.wmem_default=33554432
sysctl -w net.core.rmem_default=33554432
echo N | tee /sys/module/drm_kms_helper/parameters/poll >/dev/null
echo performance | tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor >/dev/null

# Moving IRQs (rcuo, rcuc not moveable!)
tuna -t rcu* -c 0,16 -m

# Elevate RT prios
## ksoftirq
x=1
y=15
for i in $(seq $x $y) ; do tuna -t "ksoftirqd/$i" -p fifo:99; done
a=17
b=31
for i in $(seq $a $b) ; do tuna -t "ksoftirqd/$i" -p fifo:99; done
## kworker/u48
for i in `pgrep kworker/u48` ; do tuna -t "$i" -p fifo:99 ; done
exit 0

END

sudo chmod +x /etc/rc.local
sudo systemctl enable rc-local
sudo systemctl start rc-local.service
sudo systemctl status rc-local.service
