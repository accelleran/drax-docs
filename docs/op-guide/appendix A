## Appendix A: Engineering tips and tricks

### pcscd debug
It occurs rarely that the du software throws
```
DU license check failed
```
when this happens you have to recreate the docker container and try again.
If this does not help increase the pcscd logging.

change 
```
ENTRYPOINT ["/usr/sbin/pcscd", "--foreground"]
```

into

```
ENTRYPOINT ["/usr/sbin/pcscd", "-d --foreground"]
```

and  use ``` docker logs ``` on the container to see more logging about what pcscd is doing

### Run RU in freerun mode
This is the mode where it does not need a GPS sync. By default a benetel only boots when a GPS signal is present which the RU can be synced with.
The boot process indicated this with ``Waiting for Sync``` in the ```/tmp/logs/radio_status``` file
The following steps make the benetel boot without needing GPS signal.

At boottime you kill the syncmon process
```
killall syncmon
```

and set the sync-state to succesfull manually 

```
echo 0 > /var/syncmon/sync-state
```

Now the boot process will continue. Wait at least a minute.

