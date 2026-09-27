## **3.9 Means to transmit Infill information (Level 1 only)**

### **3.9.1 General**

3.9.1.1 It shall be possible to transmit infill information to the on-board equipment using a) Balise groups

   - b) Euroloops

   - c) Radio infill units.

3.9.1.1.1 If the information transmitted by Balise groups, Euroloops, and Radio includes infill information, those devices are also identified as infill devices.

3.9.1.2 The principle used for the infill information is the same independent of transmission media.

3.9.1.3 If the on-board system is not equipped with the infill transmission media as requested by the announcement balise group, the announcement information shall be ignored by the on-board equipment and the train shall proceed according to the previously received information.

3.9.1.4 Note: No additional description is needed for infill by balise group (other than already covered in previous chapters).

### **3.9.2 Infill by loop**

3.9.2.1 Intentionally deleted.

3.9.2.2 Intentionally deleted.

3.9.2.3 Intentionally deleted.

3.9.2.4 Intentionally deleted.

3.9.2.5 Intentionally deleted.

<!-- end of page 92 -->

3.9.2.6 Intentionally deleted.

3.9.2.7 Intentionally deleted.

3.9.2.8 Intentionally deleted.

3.9.2.9 Intentionally deleted.

3.9.2.10 Intentionally deleted.

3.9.2.11 When the on-board equipment reads the next main signal balise group or when it detects that the next main signal balise group was missed, new infill information possibly received from the loop shall be ignored.

3.9.2.12 Intentionally deleted.

### **3.9.3 Infill by radio**

3.9.3.1 In level 1 areas it shall be possible to send to the on-board equipment orders to establish/terminate a communication session with a radio infill unit.

3.9.3.2 The orders shall be sent via balise groups or via Radio Infill units.

3.9.3.3 The order to establish a communication session shall be ignored: a) Intentionally deleted. b) If the GSM-R radio system is not installed on-board.

3.9.3.4 If the GSM-R radio system is installed on-board, the communication session shall be established using the same protocols and interfaces as for Level 2 operations.

3.9.3.5 If the order to establish a communication session with a radio infill unit sent via balise groups is received, the on-board equipment shall, once the location indicated in the order is reached: a) terminate any existing communication session(s) with RIU(s) not indicated in the order b) as soon as a new communication session can be handled, establish a communication session with the RIU indicated in the order

3.9.3.5.1 Intentionally deleted.

3.9.3.5.1.1 Intentionally deleted.

3.9.3.5.2 Intentionally deleted.

3.9.3.6 If the order to establish a communication session with a radio infill unit sent via Radio Infill unit is received, the on-board equipment shall: a) If only one RIU communication session is ongoing, maintain the existing communication session and establish a new one with the RIU indicated in the order.

<!-- end of page 93 -->

   - b) If two RIU communication sessions are ongoing, maintain the communication session related to the current infill area, terminate the other one and establish a new one with the RIU indicated in the order.

3.9.3.6.1 Exception (degraded situation): if the on-board can handle only one communication session established with the GSM-R radio system, the order shall be ignored.

3.9.3.7 A Radio Infill Unit shall not initiate a communication session with an on-board equipment.

3.9.3.8 The order to establish/terminate a communication session sent via balise groups shall be sent together with the following radio infill area information:

   - a) Location where to perform the action (referred to the balise group containing the order).Note: if the action is to establish a communication session, this location marks the beginning of the Radio Infill Area.

   - b) Next main signal balise group identifier (ignored by the on-board if the action is Terminate communication session).Note: the reference location of this balise group marks the end of the Radio Infill Area.

3.9.3.8.1 The order to establish/terminate a communication session sent via Radio Infill units (see 3.5.3.6) shall not be sent together with any radio infill area information.

3.9.3.9 The establishment of a communication session for radio infill shall not change the operational level of the on-board i.e. the information in the balise group shall be taken into account as usual in level 1.

3.9.3.10 The on-board equipment shall inform the radio infill unit

   - a) As soon as the location indicated in the order sent via balise groups is passed (i.e. entry of the train in the infill area)

   - b) As soon as the next main signal balise group indicated in the order sent via balise groups is read or the on-board equipment detects that it was missed.

3.9.3.11 The information sent to the radio infill unit by the on-board equipment shall include a) Train identity (ETCS-ID of the on-board equipment)

   - b) Position report

   - c) Identifier of the next main signal balise group

   - d) Time stamp

3.9.3.11.1 Justification:

   - a) The train identity is used for conformity with other train to track messages

   - b) The identifier of the next main signal balise group allows the radio infill unit to identify safely where the train is going, even in the case of a points area

3.9.3.12 As soon as the radio infill unit is informed that a train has entered an infill area under its responsibility, it shall

<!-- end of page 94 -->

   - a) Terminate a possible previous sending of infill information to the on-board equipment, AND

   - b) Send cyclically the infill information corresponding to the message currently sent by the next main signal balise group indicated in the information from the on-board equipment.

3.9.3.12.1 Justification: case a) refers to the possibility that a report from the on-board equipment, after having passed the previous main signal, was lost.

3.9.3.12.2 Note: A Radio infill unit may manage several signals, thus several Radio Infill Areas (see Figure 25a)

<!-- Start of picture text -->
RIU 1  RIU 2  RIU 3<br>Main  Main  Main  Main<br>Signal 1  Signal 2  Signal 3  Signal 4<br>BG0  BG1  BG2  BG3  BG4<br>Contact RIU1  Contact RIU2  Contact RIU2  Contact RIU3<br>NMBG = BG1  NMBG = BG2  NMBG = BG3  NMBG = BG4<br>Radio Infill Area 1  Radio Infill Area 2  Radio Infill Area 3  Radio Infill Area 4<br><!-- End of picture text -->

- NMBG = Next Main signal Balise Group

- RIU1 manages Radio Infill Area 1

- RIU2 manages Radio Infill Area 2 and 3

- RIU3 manages Radio Infill Area 4

#### **Figure 25a: Line equipped with radio infill. Example of radio infill area information transmitted by balise.**

3.9.3.13 The radio infill unit shall terminate the sending of infill information as soon as information is received, that the on-board equipment has read the next main signal balise group indicated in the order or that the on-board equipment has detected that it was missed.

3.9.3.14 The radio infill unit shall evaluate the time stamp according to the principles of section 3.16.3.2.

The on-board equipment shall check the consistency of radio infill data, according to the principles of section 3.16.3.1 and 3.16.3.3.

3.9.3.15 When the on-board equipment reads the next main signal balise group or when it detects that the next main signal balise group was missed, new infill information related to this balise group possibly received shall be ignored.

3.9.3.16 The ERTMS/ETCS on-board equipment shall terminate the communication session according to the orders received from the trackside (balise group or Radio Infill units) or when the level 1 is left.

<!-- end of page 95 -->

3.9.3.17 Intentionally deleted.
