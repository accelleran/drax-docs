## Remove existing deployment

This section is about upgrading your existing setup to a newer Release, as a rule Accelleran will regularly issue quarterly Releases with new features, 
bug fixes, etc and will therefore recommend to move forward to the new Release. The aim of this section is to take theminimal amount of steps to get 
the system back to operational: if you do not have an already operational System please contact Accelleran as the full installation from ground zero is
beyond the scope of this section.

Note that a SW upgrade will not remove the existing data, so any configured components should remain once the update is completed. Particularly, of course, 
if you wish to keep the previous configuration make sure the CU instance IDs are the same once you recreate them.

It may be that the previous versions used different names for the Helm deployments, so to check the correct names we can use the `helm list` command:

``` bash
helm list
#NAME        	NAMESPACE	REVISION	UPDATED                                	STATUS  	CHART             	APP VERSION               
#acc-5g-cu-cp	default  	1       	2022-01-21 15:16:35.893230618 +0000 UTC	deployed	acc-5g-cu-cp-3.0.0	release-2.3-duvel-8b8d7f05
#acc-5g-cu-up	default  	1       	2022-01-21 15:16:44.931753616 +0000 UTC	deployed	acc-5g-cu-up-3.0.0	release-2.3-duvel-8b8d7f05
#acc-helm-ric	default  	1       	2022-01-09 17:20:52.860528687 +0000 UTC	deployed  	ric-4.0.0         	4.0.0                     

```

In the above example, the installations are called `acc-5g-cu-cp` , acc-5g-cu-up and `ric`, so the required commands would be:

``` bash
helm uninstall acc-5g-cu-cp
helm uninstall acc-5g-cu-up
helm uninstall ric
```

Please wait until all the pods and resources of the previous dRAX installation are deleted.
You can view them by:

``` bash
watch kubectl get pods -A
```

You can now continue with the re-installation

## Install the new version

