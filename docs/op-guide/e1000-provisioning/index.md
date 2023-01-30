
## 4G E1000 Provisioning

This section is dedicated to the provisioniing and the configuration of an E1000 Series 4G eNB. The provisioning of an E1000 unit in the dRAX allows the
dRAX to "remember" a certain Cell even after a software update of the system and or the cell itself, including a change of name, the so called Filter Id
in this document. Certificates get created and signed for this to happen so that only those cel that can show a signed certificate to dRAX get admitted 
to the system and served accrodingly. This part is beyond the scope of the Configuration, here we only describe how to provision the Cells who have
already been supplied by Accelleran with signed certficates, are DHCP enabled typicaly, and can reach out for dRAX tahnsk to the bootstrap file 

When you don't use 4G together with E1000 Cells you can skip this section

### Listing currently provisioned E1000s

The current list of provisioned E1000s can be retrieved with the following command:

``` bash
curl --cacert ca.crt https://$NODE_IP:31610/get/
```

### Provisioning additional Accelleran E1000 DUs

Each additional E1000 DU, which is to be used with this dRAX installation, needs to be provisioned.
This is only needed for E1000 DUs which were not pre-provisioned during the installation process.

#### Determine Unique Identifier

Each Accelleran E1000 has a Model, a Hardware Version, and a Serial Number - this information is displayed on the label attached to the unit, and is required in order to pre-provision the DUs.
A unique identifier is constructed from this information in the following format:

```
Model-HardwareVersion-SerialNumber
```

This identifier can also be determined automatically via SSH using the following command:

``` 
echo "$(eeprom_vars.sh -k)-$(eeprom_vars.sh -v)-$(eeprom_vars.sh -s)"
```

Each E1000 also needs to be given a unique name, also known as filter id.
This name could be as simple as "du-1" - all that matters is that it is unique in this dRAX installation.

#### Prepare configuration file

To provision a new E1000, create a new file called `cellconfig.yaml` with the following contents:

``` yaml
E1011-GC01-ACC000000000001:
     redis:
         hostname: NODE_IP
         port: 32000
     loki:
         hostname: NODE_IP
         port: 30302
     instance:
        filter: du-1
```

Replace the unique identifier based on the specific E1000, replace `NODE_IP` with the correct IP for your installation, and replace `du-1` with the chosen unique name for this E1000 unit.

If you'd like to provision multiple E1000s at once, duplicate the above snippet for each additional E1000, updating the unique identifier and the name in each case.
Make sure to match the indentation in each duplicated snippet - **incorrect indentation will result in an error.**
It's recommended to keep these snippets all in the same file so that we can push the new configuration with a single command.

#### Push new configuration

Now run the following command to push this configuration to the Provisioner:

``` bash
curl --cacert ca.crt --cert client.crt --key client.key https://NODE_IP:31610/push/ --data-binary @cellconfig.yaml
```

### Changing the name of an E1000

The name of a specific E1000 can be updated if required in a slightly more straightforward manner.
First determine the unique identifier - refer to the [Determine Unique Identifier section](#determine-unique-identifier) above for the exact instructions.
Use the following command, replacing `KUBE_IP` with the correct IP for your installation, the unique identifier with that just determined, and replacing `du-1` with the new name:

``` bash
curl --cacert ca.crt --cert admin.crt --key admin.key https://_$NODE_IP:31610_/set/E0123-GC01-ACC0123456978901/instance/filter -d du-1
```

### 4G RAN Configuration

Configuration of the 4G RAN is made simple, intuitive and efficient when using the dRAX Dashboard.

Note: all of these options require the Accelleran E1000s to already have been provisioned as described in the [E1000 Provisioning section](#e1000-provisioning) above, or during the installation process.

### eNB Configuration via eNB list

To access the configuration page for an eNB, first click on the **RAN Configuration** section, and then click on **eNB Configuration.**
From the displayed list of eNBs, click on the Cog icon in the Edit column corresponding to the eNB you'd like to reconfigure.

![eNB reconfiguration](../../drax-install/images/dashboard-manual-config.png)

From the following screen, the configuration of this eNB can be adjusted.
Once the configuration has been updated as desired, click on the **Create** button at the bottom left of the page:

![eNB configuration](../../drax-install/images/dashboard-enb-configuration.png)

Notes:

1. Make sure the Cell ID is a multiple of 256, you can submit Cell IDs that are not a multiple of 256, however this will result in a Macro eNB ID that looks different on the surface, 
2. There is no conflict or error check in manual mode, therefore for instance it is possible to configure two cells with the same ID, set an EARFCN that is out of band, and so on: it is assumed that the User is aware of what he/she tries to set up
3. The reference signal power is calculated automatically from the output power, please adjust the output power in dBm which represent the maximum power per channel at the exit without antenna gain

### eNB Configuration via Dashboard

An alternative way of configuring an individual eNB is to make use of the **Dashboard** initial page (click on **Dashboard** in the sidebar to return there).
Click on the eNB in the Network Topology, and then choose **Configure Cell** on the **Selected Node** window at the right: this will take you to the  **eNB Configuration** page and described in the previous section.

![Configure from Network Topology](images/dashboard-network-topology.png)
