# Appendix A
This appendix deals about some useful engineering tips and tricks

## pcscd debug
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

## Run RU in freerun mode
This is the mode where your Benetel Radio End does not need or does not have synchronisation. By default a Benetel only boots when such sync signal is present, be it GPS or PTP or 1 PPS sync as discussed in the previous sections. Again, this is not a way to cut corners, it is only a workaround for quick sanity checks of the end to end system and shall not replace the 3GPP compliant approach of having synchrised TDD devices whth appropriate infrastructures to guarantee the quality and effecitveness of the synchronisation. In no case it will work when more than one Cell or more than one UE are present.


Tha said, the following steps make the benetel RU boot complete without sync signal.


• setSyncModeGps.sh

–  Remove the GPS connection from the RAN650 or the PTP/1PPS connection from the B550

- The boot process stops indicated this with ``Waiting for Sync``` in the ```/tmp/logs/radio_status``` file

–  Run this command on the O-RU:  setSyncModeGps.sh

-- Reboot the RU

–  SSH back into the O-RU once the system is back

–  Monitor the boot procedure using ‘cat /tmp/logs/radio_status’

–  You will see that the O-RU is waiting to Sync and it has a 3 min time out on this before re-initializing

• killall syncmon
– without waiting 3 minutes, run this command to kill the sync application running in the background:

• echo “0” > /var/syncmon/sync-state

–  Run this command to set the flag which the initialization script is monitoring for successful sync

–  The radio will then continue with the bring up process

–  This can be seen by checking that the ‘cat /tmp/logs/radio_status’ has moved to RF Initialisation


Now the boot process will continue. Wait at least a minute and check the status till the "bringup complete" is reported and being the cell on air as usual 

