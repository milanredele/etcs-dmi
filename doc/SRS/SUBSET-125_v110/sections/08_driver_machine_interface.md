# **8. DRIVER MACHINE INTERFACE**

## **8.1 Available Inputs from the driver**

8.1.1.1 ATO Engage: Used by the driver to request the start of automatic driving (departure of the train or engagement on the move).

8.1.1.2 The “ATO Engage” input is considered as enabled by the ETCS-OB when the “ATO ready for engagement” is displayed (see §8.2.1).

8.1.1.3 **Note:** When the driver selects “ATO Engage”, if it is not in AD Mode, the ETCS-OB will change to AD Mode if the ETCS-OB applicable conditions for ATO Operational are fulfilled (see §9.1.1.2).

8.1.1.4 ATO Disengage: Used by the driver to disengage ATO while the ATO-OB is engaged.

8.1.1.5 The “ATO Disengage” input is considered as enabled by the ETCS-OB when the "ATO engaged" or when the “ATO Disengaging” indication is displayed (see §8.2.1).

8.1.1.6 **Note:** When the driver selects “ATO Disengage”, the ETCS-OB will change from AD Mode to the applicable ETCS Mode according to the ETCS mode transition table as defined in [Ref 5] §4.6.

8.1.1.7 Skip Stopping Point Request/Revocation: Used by the driver to request a Stopping Point skip or to revoke a Stopping Point skip previously requested by himself/herself.

8.1.1.8 The “Skip Stopping Point Request” input is considered as enabled by the ETCS-OB while the “Skip Stopping Point Inactive” indication is displayed.

8.1.1.9 The “Skip Stopping Point Revocation” input is considered as enabled by the ETCS-OB while the “Skip Stopping Point requested by the driver” indication is displayed.

## **8.2 Information to be displayed to the driver**

### **8.2.1 ATO Status**

8.2.1.1 While the ATO-OB is in CO, NA or AV State, the ATO-OB shall request the ETCS-OB to display the “ATO Selected” indication.

8.2.1.2 While the ATO-OB is in RE State, the ATO-OB shall request the ETCS-OB to display the “ATO Ready for Engagement” indication.

8.2.1.3 While the ATO-OB is in EG State, the ATO-OB shall request the ETCS-OB to display the “ATO Engaged” indication.

<!-- end of page 57 -->

8.2.1.4 While the ATO-OB is in DE State, the ATO-OB shall request the ETCS-OB to display the “ATO Disengaging” indication.

8.2.1.5 When it enters in FA State, the ATO-OB should request where possible the ETCS-OB to display the “ATO Failure” indication until the ATO-OB is not in FA State.

8.2.1.6 While it displays the “ATO Failure” indication, the ETCS-OB shall display no other ATO related indication.

### **8.2.2 Stopping accuracy**

8.2.2.1 When a train comes to a stop and a Stopping Point is considered as reached, the ATOOB shall request the ETCS-OB to display an indication indicating if (taking into account the Timing Point alignment required in the JP):

- a) An accurate stop has been achieved or;

- b) The train has undershot the stopping window or;

- c) The train has overshot the stopping window.

8.2.2.2 While the train is moving, the ATO-OB shall stop requesting the ETCS-OB to display the stopping accuracy indication.

### **8.2.3 Dwell time**

8.2.3.1 When a train comes to a stop at a Stopping Point within the stopping window (taking into account the TP alignment required in the JP), the ATO-OB shall request the ETCS-OB to display the remaining dwell time.

8.2.3.2 While the train is stopped at a Stopping Point within the stopping window (taking into account the TP alignment required in the JP) and the ATO-TS requests the train to be held at that Stopping Point (see §7.4.1.1), the ATO-OB shall request the ETCS-OB to display the “Train Hold” indication.

8.2.3.2.1 While the computed dwell time value is equal to or higher than 100 minutes, the ATOOB shall request the ETCS-OB to display the “Train Hold” indication.

8.2.3.3 While the train is moving, the ATO-OB shall stop requesting the ETCS-OB to display the dwell time or the “Train Hold” indication.

<!-- end of page 58 -->

### **8.2.4 Door information**

8.2.4.1 When a train comes to a stop at Stopping Point and the train is within the stopping window (taking into account the TP alignment required in the JP), the ATO-OB shall request the ETCS-OB to display either for Manual Door Opening (i.e. when no automatic door opening request has been sent to the train door management system): a) “Request driver to open doors on both sides” indication or; b) “Request driver to open right doors” indication or; c) “Request driver to open left doors” indication, or for Automatic Door Opening (i.e. when an automatic door opening request has been sent to the train door management system): a) "Doors are open" indication.

8.2.4.2 **Note:** For Automatic Door Opening, the command to open the doors is sent when the ATO-OB expects the train to stop within the stopping window of a Stopping Point and the train is at standstill, but the indication “Doors are open” is not displayed until the train comes to a stop.

8.2.4.3 For Manual Door Opening (i.e. when no automatic door opening request has been sent to the train door management system), the ATO-OB shall request the ETCS-OB to display the “Doors are open” indication when doors are no longer closed and locked.

8.2.4.4 When the remaining dwell time is equal to the time to close the doors and the doors are not closed and locked, the ATO-OB shall request the ETCS-OB to display either for Manual Door Closing (i.e. when no automatic door closing request has been sent to the train door management system): a) the “Request driver to close doors” indication, or for Automatic Door Closing (i.e. when an automatic door closing request has been sent to the train door management system): b) the “Doors are being closed by ATO” indication.

8.2.4.5 When doors are closed and locked, the ATO-OB shall request the ETCS-OB to display the “Doors are closed” indication.

8.2.3.1 While the train is moving, the ATO-OB shall stop requesting the ETCS-OB to display any door indication.

8.2.4.6 When the start condition is triggered for any door indication, this indication shall replace any previously displayed door indication.

### **8.2.5 Skip Stopping Point status**

8.2.5.1 When the ATO-OB receives a request to skip the next Stopping Point coming from the driver, the ATO-OB shall request the ETCS-OB to display the “Skip Stopping Point requested by the driver” indication until the request is deleted (see 7.3.1.7).

<!-- end of page 59 -->

8.2.5.2 When the ATO-OB receives a request to skip the next Stopping Point coming from the ATO-TS, the ATO-OB shall request the ETCS-OB to display the “Skip Stopping Point requested by the ATO-TS” indication until the “Stopping Point to be skipped” is passed or the request is revoked by ATO-TS.

8.2.5.3 While the next Stopping Point is not to be skipped and the doors are closed and locked, the ATO-OB shall request the ETCS-OB to display the “Skip Stopping Point Inactive” indication until the train has stopped at a Stopping Point considered as reached.

### **8.2.6 Stopping Points distance**

8.2.6.1 While the following conditions are fulfilled:

- a) The Operational Conditions except “The train is not located within an ATO Inhibition Zone” are fulfilled (see §9.1.1) and,

- b) The train is not located within a DAS Inhibition Zone,

the ATO-OB shall request the ETCS-OB to display the distances from the train (taking into account the TP alignment required in the JP) to the Stopping Points or Stopping Points to be skipped.

8.2.6.2 Before a Stopping Point is considered as reached or passed, the ATO-OB shall request the ETCS-OB to display a null distance in case its Stopping Point distance becomes negative (e.g. in case of overshoot).

8.2.6.3 Once a Stopping Point (including a Stopping Point to be skipped) is considered as reached or passed the ATO-OB shall no longer request the ETCS-OB to display the Stopping Point distance for that Stopping Point.

### **8.2.7 Stopping Point name and estimated arrival time**

8.2.7.1 While the following conditions are fulfilled:

- a) The Operational Conditions except “The train is not located within an ATO Inhibition Zone” are fulfilled (see §9.1.1);

b) The train is not located within a DAS Inhibition Zone,

- the ATO-OB shall request the ETCS-OB to display the name and the estimated arrival time at the next Stopping Point or Stopping Point to be skipped.

8.2.7.2 Once a Stopping Point (including a Stopping Point to be skipped) is considered as reached or passed the ATO-OB shall no longer request the ETCS-OB to display the Stopping Point name and estimated arrival time for that Stopping Point.

### **8.2.8 DAS information**

8.2.8.1 The ATO-OB shall request the ETCS-OB to display the following information:

- a) “Target Advice Speed” or the “Coasting advice” indication;

<!-- end of page 60 -->

- b) “Distance to next advice change”,

while the following conditions are fulfilled:

- a) The ETCS-OB is not in AD Mode;

- b) The Operational Conditions except “The train is not located within an ATO Inhibition Zone” are fulfilled (see §9.1.1);

- c) The train is not located within a DAS Inhibition Zone;

- d) The next “Target Advice Speed” is not zero.

### **8.2.9 Driver warning sounds**

8.2.9.1 If the TBL is in traction position when the ATO-OB enters EG State and the TBL does not leave the traction position within 5 seconds, the ATO-OB shall request the ETCSOB to produce a warning sound until the TBL is set to neutral position.

8.2.9.2 If the TBL is moved to traction position while the ATO-OB is in EG State, the ATO-OB shall request the ETCS-OB to produce a warning sound until the TBL is set to neutral position.

8.2.9.3 While the ATO-OB is in DE State, the ATO-OB shall request the ETCS-OB to produce a warning sound.

8.2.9.4 When the ATO-OB enters FA State (see §9.9), the ATO-OB should try to request the ETCS-OB to produce a warning sound for a duration of 5 seconds.

<!-- end of page 61 -->

### **8.2.10 ATO DMI inputs versus State Table**

8.2.10.1 X = This means that it shall be possible for the driver to enter this information when ATOOB is in the state indicated in the column.

Empty case = This means that it shall not be possible for the driver to enter this information when ATO-OB is in the state indicated in the column.

NApp = Not Applicable: This concerns the FA State in which the driver inputs cannot be determined.

|**Input information**|**Related SRS**<br>**§**|**NP**|**CO**|**NA**|**AV**|**RE**|**EG**|**DE**|**FA**|
|---|---|---|---|---|---|---|---|---|---|
|ATO Engage|8.1.1.1|||||X|||NApp|
|ATO Disengage|8.1.1.4||||||X|X|NApp|
|Skip Stopping Point Request|8.1.1.7, 7.3.1.5||||X|X|X|X|NApp|
|Skip<br>Stopping<br>Point<br>Revocation|8.1.1.7, 7.3.1.6||||X|X|X|X|NApp|

**Table 4 ATO DMI inputs versus State Table**

### **8.2.11 ATO DMI outputs versus State Table**

8.2.11.1 X = This means that the output information shall be sent to the ETCS-OB when the ATOOB is in the state indicated in the column.

Empty case = This means that the output information shall not be send to the ETCS-OB when the ATO-OB is in the state indicated in the column.

NApp = Not Applicable: This concerns the FA State in which the output information cannot be determined.

|**Output information**|**Related**<br>**SRS §**|**NP**|**CO**|**NA**|**AV**|**RE**|**EG**|**DE**|**FA**|
|---|---|---|---|---|---|---|---|---|---|
|ATO status|8.2.1||X|X|X|X|X|X|X|
|Dwell time|8.2.3|||X<sup>1</sup>|X|X|||NApp|
|Stopping accuracy|8.2.2|||X<sup>1</sup>|X|X|||NApp|
|Door information|8.2.4|||X<sup>1</sup>|X|X|||NApp|
|Skip Stopping Point status|8.2.5||||X|X|X|X|NApp|
|Stopping Points distance|8.2.6||||X|X|X|X|NApp|
|Stopping Point name and estimated<br>arrival time|8.2.7||||X|X|X|X|NApp|
|Target Advice Speed or Coasting<br>advice|8.2.8|||X<sup>2</sup>|X<sup>2</sup>|X<sup>2</sup>|||NApp|
|Distance to next advice change|8.2.8|||X<sup>2</sup>|X<sup>2</sup>|X<sup>2</sup>|||NApp|
|Driver warning sounds|8.2.9||||||X|X|NApp|

> 1 When the JP and SP information required is available.

> 2 When clause §8.2.8.1 is fulfilled.

#### **Table 5 ATO DMI outputs versus State table**

<!-- end of page 62 -->
