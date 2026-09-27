# **5. VALUES FOR TECHNICAL PERFORMANCES**

## **5.1 General considerations**

5.1.1.1 The following tables summarise the possible values for technical performance requirements of ERTMS on-board equipment. For each of them feasibility limits are indicated.

5.1.1.2 Technical performance requirements implying response times are defined according to a start event and a stop event which can be observed on interoperable interfaces.

5.1.1.3 If the start event defining the performance is the receiving of a message by the on-board ERTMS equipment, the value is valid if the actions due to previously received messages are completed (e.g., emergency brake order completely issued, communication session established, indication to driver updated).

5.1.1.4 If the end event defining the performance is the sending of a message by the on-board ERTMS equipment, the value is valid if the sending of previous messages is completed.

5.1.1.5 Note: according to SUBSET-026, in case of balise transmission “telegram” is the information sent by one balise and “message” is the whole set of “telegrams” sent by the balises of a group.

## **5.2 Response Times**

5.2.1.1 Delay between receiving of a balise message and applying the emergency brake

|**Description**|**delay between receiving of a balise message and applying the emergency**<br>**brake**|
|---|---|
|Start Event|The reference mark of the on-board antenna leaving the “side lobe zone” of the<br>last balise in the group (1.3 m from the reference mark of the balise)|
|Stop Event|Beginning of issuing of the braking order on the TIU-train interface|
|Value|< 1 sec|
|Notes|It is assumed that the activation of the emergency brake is required by the message<br>contained in the balise group.|

<!-- end of page 10 -->

#### 5.2.1.2 Delay between receiving of a balise message and initiating a communication session establishment

|**Description**|**delay between receiving of a balise message and initiating a communication**<br>**session establishment**|
|---|---|
|Start Event|The reference mark of the on-board antenna leaving the “side lobe zone” of the<br>last balise in the group (1.3 m from the reference mark of the balise)|
|Stop Event|Beginning of sending of the connection request to the FRMCS on-board<br>equipment/GSM-R mobile - ETCS on-board interface|
|Value|< 1.5 sec|
|Notes|It is assumed that the establishment of the communication session is required by<br>the message contained in the balise group.|

5.2.1.3 Delay between receiving of a balise message and reporting the resulting change of status on-board (e.g., update of EOA, level transition, mode change)

|**Description**|**delay between receiving of a balise message and reporting the resulting**<br>**change of status on-board**|
|---|---|
|Start Event|The reference mark of the on-board antenna leaving the “side lobe zone” of the<br>last balise in the group (1.3 m from the reference mark of the balise)|
|Stop Event|Indication to the driver|
|Value|< 1.5 sec|
|Notes|It is assumed that the change of status is required by the message contained in the<br>balise group.<br>The value indicated in this case includes additional delay for the display of the<br>information.|

5.2.1.4 Delay between receiving of a MA via radio (both from RBC and from radio in-fill) and the update of EOA/LOA on-board

|**Description**|**delay between receiving of a MA via radio (both from RBC and from radio in-**<br>**fill) and the update of EOA/LOA on-board**|
|---|---|
|Start Event|Reception of the complete MA message at the FRMCS on-board<br>equipment/GSM-R mobile - ETCS on-board interface|
|Stop Event|Indication to the driver|
|Value|< 1.5 sec|
|Notes|It is assumed that the update of the EOA/LOA is required by the message received.<br>The value indicated in this case includes additional delay for the display of the<br>information.|

5.2.1.5 Delay between receiving of a MA from Euroloop and the update of EOA/LOA on-board

<!-- end of page 11 -->

|**Description**|**delay between receiving of a MA from Euroloop** **and the update of EOA/LOA**<br>**on-board**|
|---|---|
|Start Event|A) On-board Euroloop receiver is synchronised, and<br>B) A complete MA message has been received at the Euroloop air gap<br>interface|
|Stop Event|Indication to the driver|
|Value|< 1.5 sec|
|Notes|It is assumed that the update of the EOA/LOA is required by the message received.<br>The value indicated in this case includes additional delay for the display of the<br>information.|

|**Description**|**delay between receiving of a MA from Euroloop** **and the update of EOA/LOA**<br>**on-board**|
|---|---|
|Start Event|A) On-board EUROLOOP receiver knows loop spectrum code, and<br>B) Loop signal becomes available to the on-board, and<br>C) On-board Euroloop receiver is not yet synchronised|
|Stop Event|Indication to the driver|
|Value|< 3.0 sec|
|Notes|It is assumed that the update of the EOA/LOA is required by the message received.<br>The value indicated in this case includes additional delay for the display of the<br>information.|

<!-- end of page 12 -->

#### 5.2.1.6 Delay between receiving of an emergency message and applying the reaction on-board

|**Description**|**delay between receiving of an emergency message and applying the**<br>**reaction on-board**|
|---|---|
|Start Event|Reception of the complete message at the FRMCS on-board equipment/GSM-R<br>mobile - ETCS on-board interface|
|Stop Event|Indication to the driver and/or beginning of issuing of braking order, if required|
|Value|< 1 sec, for brake order<br>< 1.5 sec, for indication to the driver|
|Notes|The value given in the case of indication to the driver includes additional delay for<br>the display of the information.|

#### 5.2.1.7 Delay between receiving of a radio message and initiating a communication session establishment

|**Description**|**delay between receiving of a radio message and initiating a communication**<br>**session establishment**|
|---|---|
|Start Event|Reception of the complete message at the FRMCS on-board equipment/GSM-R<br>mobile - ETCS on-board interface|
|Stop Event|Beginning of sending of the connection request at the FRMCS on-board<br>equipment/GSM-R mobile - ETCS on-board interface|
|Value|< 1 sec|
|Notes|It is assumed that the establishment of the communication session is required by<br>the message received.<br>This performance applies in the case of RBC/RBC handover.|

<!-- end of page 13 -->

#### 5.2.1.8 Delay between passing an EOLM and decoding of the first loop message

|**Description**|**delay between passing an EOLM and decoding of the first loop message**|
|---|---|
|Start Event|The reference mark of the on-board antenna leaving the “side lobe zone” of the<br>last balise of the group giving the EOLM packet (1.3 m from the reference mark of<br>the balise)|
|Stop Event|Indication to the driver (update of EOA/LOA, according to the new MA received)|
|Value|4 sec|
|Notes|It is assumed that the loop signal is received latest 1.0 s after the defined start<br>event.<br>In case the signal is present earlier than the delay, the train will not exploit the full<br>length of the Euroloop cable.<br>The value indicated in this case includes additional delay for the display of the<br>information.|

5.2.1.9 Delay between receiving of a balise group message and taking into account its content

|**Description**|**delay between receiving of a balise group message and taking into account**<br>**its content, so as to avoid a trip due to the overpassing of the EOA (level 1**<br>**only), the LOA, or the former EOA/LOA**|
|---|---|
|Start Event|The min safe antenna position passes an EOA/LOA location or a former EOA/LOA<br>location a time Tn, calculated from the formulas in Subset-036 clause 4.2.9, after<br>the reference mark of the on-board antenna left the “side lobe zone” of the last<br>balise in the group (1.3 m from the reference mark of the balise)|
|Stop Event|1 sec after the min safe antenna position has passed the EOA/LOA (or the former<br>EOA/LOA) location, no issuance of the emergency braking order on the TIU-train<br>interface.|
|Value|Not relevant.|

<!-- end of page 14 -->

#### Notes

- It is assumed that:

- • The last balise in the group is placed in such a way that the start event is fulfilled regardless of the engineering rule SUBSET-040 § 4.1.1.4.

- • The train is operating in level 1/ FS mode (level 1 / SR mode for the case of the former EOA/LOA).

- • The balise group message includes an extension of MA, an immediate level transition order to level 0/NTC or a “Stop if in SR” information.

- The fulfilment of this performance requirement is obtained by checking that the emergency brake is not activated, as a result from the MA extension, the level transition to level 0/NTC or the deletion of the former EOA/LOA which takes precedence on the overpassing of the EOA/LOA / former EOA/LOA (by virtue of the clause SUBSET-026 § A.3.5.2) and which is taken into account by the on-board no later than the latest time when the emergency brake can be activated due to the overpassing of the EOA/LOA/former EOA/LOA, as per section 5.2.1.13.

#### 5.2.1.10 Delay between driver action and new window displayed to driver

|**Description**|**Delay between driver action and new window displayed**|
|---|---|
|Start Event|Driver action on DMI|
|Stop Event|New window is displayed|
|Value|2 sec|
|Notes|It is assumed that the desk has been open for sufficient time to ensure that there<br>are no running background tests still to be completed, see 5.2.1.12.<br>This requirement only applies to driver actions which directly (i.e. with no display<br>of hour glass) lead to a new window on the ETCS DMI (refer to<br>ERA_ERTMS_015560).|

<!-- end of page 15 -->

#### 5.2.1.11 Awakening performance parameter #1

|**Description**|**Awakening performance parameter #1**|
|---|---|
|Start Event|Desk becomes open|
|Stop Event|“enter Driver ID” is displayed|
|Value|3 sec|
|Notes|“Desk becomes open” means that the information is available on the Train<br>Interface.|

#### 5.2.1.12 Awakening performance parameter #2

|**Description**|**Awakening performance parameter #2**|
|---|---|
|Start Event|Desk becomes open|
|Stop Event|SH mode is displayed|
|Value|15 sec|
|Notes|“Desk becomes open” means that the information is available on the Train<br>Interface.<br>Using the shortest path through the SoM procedure:<br>•<br>Train is in Level 1;<br>•<br>Level and stored position are valid;<br>•<br>Driver data entries are limited to Driver ID and SH request.<br>The performance value stated above excludes the time taken by the driver to<br>complete the 2 data entries.<br>This parameter quantifies by how much any background tests can affect the Start<br>of Mission performance (in this case the time to display a new window further to a<br>driver data entry could be longer than the performance parameter specified in<br>5.2.1.10)|

<!-- end of page 16 -->

#### 5.2.1.13 Delay between passing an EOA (level 1 only), an LOA, or a former EOA/LOA and applying the emergency brake

|**Description**|**delay between passing an EOA (level 1 only), an LOA, or a former EOA/LOA**<br>**and applying the emergency brake**|
|---|---|
|Start Event|The min safe antenna position (level 1) has passed an EOA/LOA location or a<br>former EOA/LOA location, or the min safe front end position (level 2) has passed<br>an LOA location or a former EOA/LOA location|
|Stop Event|Beginning of issuing of the braking order on the TIU-train interface|
|Value|< 1 sec|
|Notes|The activation of the emergency brake results from the transition to the Trip mode.|

## **5.3 Accuracy**

#### 5.3.1.1 Accuracy of distances measured on-board

|**Description**|**Accuracy of distances measured on-board**|
|---|---|
|Start Event|not applicable|
|Stop Event|not applicable|
|Value|for every measured distance s the accuracy shall be better or equal to ± (5m + 5%<br>s), i.e. the over reading amount and the under reading amount shall be equal to or<br>lower than (5m + 5% s).|
||measured distance (s)<br>Front end<br>Reference point (normally a balise group location reference)|
||under-<br>reading<br>amount<br>over-<br>reading<br>amount|
|Notes|This performance requirement includes the error for the detection of a balise<br>location, as defined in the Eurobalise specifications.<br>Also in case of malfunctioning the on-board equipment shall evaluate a safe<br>confidence interval.|

<!-- end of page 17 -->

#### 5.3.1.2 Accuracy of speed known on-board

|**Description**|**accuracy of speed known on-board**|
|---|---|
|Start Event|not applicable|
|Stop Event|not applicable|
|Value|± 2 km/h for speed lower than 30 km/h, then increasing linearly up to ± 12 km/h at<br>500 km/h.|
|Notes|Only in target speed monitoring when the compensation of the speed measurement<br>inaccuracy is not inhibited: the on-board equipment shall also evaluate a safe<br>confidence interval in case of malfunctioning.|

#### 5.3.1.3 Age of speed and position measurement for position report to trackside

|**Description**|**age of speed and position measurement for position report to trackside**|
|---|---|
|Start Event|not applicable|
|Stop Event|not applicable|
|Value|The speed and the position of the train front indicated in a position report shall be<br>estimated less than 1 sec before the beginning of sending of the corresponding<br>position report.|
|Notes||

### **5.3.2 Clock**

#### 5.3.2.1 Safe clock drift

|**Description**|**safe clock drift**|
|---|---|
|Start Event|not applicable|
|Stop Event|not applicable|
|Value|0.1 %|
|Notes|This value is not only a performance but also a safety related requirement as it<br>refers to clock information used for time-stamping of messages and for supervision<br>of time-outs, the magnitude of which is a few minutes.<br>Time Stamp resolution is defined in SUBSET-026.|

<!-- end of page 18 -->
