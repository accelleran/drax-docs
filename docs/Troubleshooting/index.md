
# Troubleshooting

## table of content

- [Troubleshooting](#troubleshooting)
  - [table of content](#table-of-content)
  - [using logging](#using-logging)
    - [how to provide logging to accelleran for support](#how-to-provide-logging-to-accelleran-for-support)
  - [Errors and Solutions](#errors-and-solutions)
    - [Fiber Port not showing up](#fiber-port-not-showing-up)
    - [L1 is not listening](#l1-is-not-listening)
    - [example](#example)


## using logging

### how to provide logging to accelleran for support

mahmoud has a markdown file on this we can paste here


## Errors and Solutions

### Fiber Port not showing up
https://www.serveradminz.com/blog/unsupported-sfp-linux/

### L1 is not listening
Check if L1 is listening on port 44000 by typing

```
$ netstat -ano | grep 44000
```

If nothing is shown L1 is not listening. In this case do a trace on the F1 port like this.

```
tcpdump -i any port 38472
18:26:30.940491 IP 10.244.0.208.38472 > bare-metal-node-cab-3.59910: sctp (1) [HB REQ] 
18:26:30.940491 IP 10.244.0.208.38472 > bare-metal-node-cab-3.maas.56153: sctp (1) [HB REQ] 
18:26:30.940530 IP bare-metal-node-cab-3.59910 > 10.244.0.208.38472: sctp (1) [HB ACK] 
18:26:30.940532 IP bare-metal-node-cab-3.59910 > 10.244.0.208.38472: sctp (1) [HB ACK] 
````
you should see the HB REQ and ACK messages. If not Check 
 * the docker-compose.yml file if the cu ip address matches the following bullet
 * check ```kubectl get services ``` if the F1 service is running with the that maches previous bullet 

### check SCTP connections
There are 3 UDP ports you can check. When the system starts up it will setup 3 SCTP connections on following ports in the order mentioned here :

* 38462 - E1 SCTP connection - SCTP between DU and CU
* 38472 - F1 SCTP connection - SCTP between CU UP and CU CP
* 38412 - NGAP SCTP connection - SCTP between CU CP and CORE

## Appendix: Engineering tips and tricks
### custatus
#### install
* unzip custatus.zip so you get create a directory ```$HOME/5g-engineering/utilities/custatus```
* ```sudo apt install tmux```
* create the ```.tmux.conf``` file with following content.
```
cat $HOME/.tmux.conf 
set -g mouse on
bind q killw
```
add this line in $HOME/.profile
```
export PATH=$HOME/5g-engineering/utilities/custatus:$PATH
```

#### use
to start 
```
custatus.sh tmux
```

to quit 
* type "CTRL-b" followed by "q"

> NOTE : you might need to quit the first time you have started. 
> Start a second time and see the difference.

### example

![image](https://user-images.githubusercontent.com/21971027/148368394-44fd92b2-d803-44ce-b20f-08475fb382cc.png)


