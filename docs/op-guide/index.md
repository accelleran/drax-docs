new op guide

# DU Installation

    
## Introduction
The DU will be installed in several Docker containers that run on metal on the host machine. As mentioned in the introduction, a separate Virtual Machine will host the RIC and the CU and their relative pods will be handled by Kubernetes inside that VM. Here we focus on the steps to get DU and L1 up and running.

### Variables needed for this install
Before proceeding you may want to crosscheck and modify some paramters that caracterise each deployment and depends on the desired provisioning of the components. The parameters that should be considered for this purpose and can be safely modified are:


#### 5G variables
* plmn_identity      [ eg 235 88 ] 
* nr_cell_identity   [ eg 1  any number ]
* nr_pci             [ eg 1  not any number. Ask Accelleran to do the PCI planning ]
* 5gs_tac            [ eg 1 ] 

#### Frequency variables
* center_frequency_band   [ eg  3751.680 ] 
* point_a_arfcn           [ 648840 consistent with center freq, scs 30khz ]
* band               	  [ 77  consistent with center frequency ]


#### set softirq priorities to realtime	
In a normal setup, the softirq processes will run at priority 20, equal to all user processes. Here they need to run at -2, which corresponds to real time priority. They are scheduled on all cores but will get strict priority over any other user processes. To adapt the priority of the ksoft, you can use spcific commands:

to set to realtime priority 1 (lowest prio, but still "run to completion" before other default processes are executed):
``` bash
ps -A | grep ksoftirq | awk '{print $1}' | xargs -L1 sudo chrt -p 1
```

> NOTE: to revert the priority to "other policy":
> 
> 	
> ``` bash
> ps -A | grep ksoftirq | awk '{print $1}' | xargs -L1 sudo chrt --other -p 0
> ```

finally to check all the priorities set:

``` bash
ps -A | grep ksoftirq | awk '{print $1}' | xargs -L1 chrt -p
```
	
Use htop to verify the priorities of the softirq processes.	
The only thing remaining is now **prioritise the softirq processes**. One can use **htop** and work out the options to show priority and CPU ID 
	
	* Press F2 for ```Setup```, navigate to ```Columns```,  add ```PRIORITY```
	
	* Press F2 for ```Setup```, navigate to ```Display Options```, unselect ```Hide kernel threads```

<p align="center">
  <img width="500" height="300" src="htopPinning.png">
</p>



