# **10. INTERFACES**

## **10.1 ATO-OB / ATO-TS interface**

### **10.1.1 Introduction**

10.1.1.1 **Note:** This section §10.1 gives only the requirements dedicated to the ATO-OB/ATO-TS interface application level. The requirements dedicated to the ATO-OB/ATO-TS transport and security layers are defined in [Ref 8].

10.1.1.2 The ATO-TS/ATO-OB interface shall be interoperable.

10.1.1.3 **Note:** The following packets are sent from the ATO-TS to ATO-OB:

- a) Segment Profiles (SP);

- b) Journey Profiles (JP);

- c) ATO Status Report Acknowledgement (STRAck);

- d) Handshake Acknowledgement (HSAck);

- e) Handshake Reject (HSRej);

- f) Session Termination Request (SESSTermReq).

10.1.1.4 **Note:** The following packets are sent from the ATO-OB to ATO-TS:

- a) Journey Profile Request (JPReq);

- b) Segment Profile Request (SPReq);

- c) Journey Profile Acknowledgement (JPAck);

- d) ATO Status Report (STR);

- e) Handshake Request (HSReq);

- f) Session Termination (SESSTerm).

### **10.1.2 Conditions for establishing a communication session**

10.1.2.1 The ATO-OB shall establish a communication session as soon as all the following conditions are fulfilled:

- a) The Cab is active;

- b) ATO-OB has received:

   - 1) A valid TRN;

   - 2) An ETCS identity;

   - 3) A valid train length;

- c) ETCS-OB is not in NL Mode or in SH Mode.

10.1.2.2 The ATO-OB shall establish a communication session with an ATO-TS identified by an ATO-TS Contact Information.

<!-- end of page 74 -->

10.1.2.3 The ATO-TS Contact Information shall be unique and composed of NID_C and NID_ATOTS.

10.1.2.4 **Note:** The value of the preconfigured ATO-TS Contact Information may be modified according to a maintenance procedure which is not harmonised.

### **10.1.3 Establishing communication sessions**

10.1.3.1 The ATO-OB shall have a preconfigured ATO-TS Contact Information corresponding to the ATO-TS to be initially contacted.

10.1.3.2 The ATO-OB shall send an HSReq to the ATO-TS corresponding to the preconfigured ATO-TS Contact Information including the list of ATO system versions that it supports.

10.1.3.3 The ATO-TS shall answer with an HSAck or with an HSRej.

10.1.3.4 If no feedback (HSAck or HSRej) has been received after ATO-OB has sent an HSReq to ATO-TS and ATO-OB repeats the HSReq, this repetition shall be done 30 seconds later, at the earliest.

10.1.3.5 When ATO-OB receives an HSAck, the communication session shall be considered established.

10.1.3.6 The HSAck sent by the ATO-TS to ATO-OB shall include:

- a) ATO-TS Identifier;

- b) ATO system version that will be used by the ATO-TS for the ATO-OB/ATO-TS communication;

- c) Timeout for ATO-TS response;

- d) Reporting time interval for triggering an STR;

10.1.3.7 **Note:** If there is no ATO major version supported by both ATO-OB and ATO-TS, the ATO-TS will not send an HSAck, but an HSRej asserting that there is no compatible ATO System versions.

10.1.3.8 **Note:** The values of the “Time-out for ATO-TS response” and the “Reporting time interval for triggering an STR” are ATO-TS application specific.

10.1.3.9 The “timeout for ATO-TS response” is used for two different purposes:

- a) It is the maximum time after which the ATO-OB must consider that a request has not been answered;

- b) For determining when the ATO-OB needs to send a JPReq to ensure that a JP is received in a timely manner for continued ATO operation.

10.1.3.10 If ATO-TS answers with an HSRej, the HSRej packet shall mention the following possible reasons for rejection:

<!-- end of page 75 -->

- a) ATO-OB and ATO-TS versions are not compatible;

- b) Another ATO-TS is in charge (ATO-TS Contact Information provided);

- c) ATO-TS in charge is unknown (ATO-TS Contact Information not provided).

10.1.3.11 An ATO-TS shall perform the version compatibility check only if it is in charge of the ATO-OB.

10.1.3.12 If the HSRej indicates that ATO-OB and ATO-TS are not compatible, ATO-OB shall stop trying to open a communication session until the TRN has changed.

10.1.3.13 If the HSRej indicates that ATO-TS in charge is not known, ATO-OB shall attempt to reestablish connection with the pre-configured ATO-TS Contact Information.

10.1.3.14 If the HSRej indicates that another ATO-TS is in charge, the ATO-TS Contact Information sent back in the HSRej is corresponding to the ATO-TS which is currently in charge of controlling the train. In this case, the ATO-OB shall release the communication and shall establish a new communication session with the ATO-TS Contact Information transmitted in the HSRej packet and start a new handshake process.

10.1.3.15 **Note:** TRN is also considered as changed when ETCS-OB reports that the set of ETCS Operational Data has changed to “Valid”.

### **10.1.4 Hand-over between two adjacent ATO-TS**

10.1.4.1 When the train already has an open communication session with an ATO-TS and it approaches the border of the area controlled by this ATO-TS (called ‘handing-over ATOTS’), the ATO-TS Contact Information of the adjacent ATO-TS (called ‘accepting ATOTS’) is given by the last SP referred to by the current JP.

10.1.4.2 The ATO-OB shall recover the ATO-TS Contact Information of the Accepting ATO-TS from the last SP referred to in the current JP.

10.1.4.3 The ATO-OB shall establish a communication session with the Accepting ATO-TS, by indicating that it is due to a handing over procedure.

10.1.4.4 If the ATO-TS receives an HSReq indicating that it is due to a handing over procedure, the ATO-TS shall send an HSAck unless the ATO-OB and ATO-TS versions are not compatible (see 10.1.3.10 a).

10.1.4.5 Having established communication with the accepting ATO-TS on the approach to the border, ATO-OB shall maintain communication with the handing over ATO-TS until the rear end of the train has left the last SP referred to by the JP which ends at the boundary between the two adjacent ATO-TS.

10.1.4.6 Maximum two communication sessions for ATO OB implies that the area covered by one ATO TS shall be large enough that a previous hand over is complete before the next

<!-- end of page 76 -->

border is approached, i.e., large enough to cover the maximum train length plus the distance travelled while contacting the third ATO-TS.

10.1.4.7 If the last SP referred to by the current JP does not contain any ATO-TS Contact Information when the train is approaching the border of the area controlled by this ATOTS, this means that the adjacent area is not fitted for ATO. In this case, the ATO-OB will lose the ATO Operational Conditions when crossing the border according to §9.1.1.1.

10.1.4.8 For each border of an ATO-TS the associated list of SPs in the JP shall include at most one SP containing the ATO-TS contact Information, such SP shall be the one which ends at the border and is called “last SP”.

10.1.4.9 The ATO-OB shall terminate the communication session with the accepting ATO-TS when the handing over ATO-TS sends a JP update where the last SP contains deviating ATO-TS Contact Information (deleted or modified).

### **10.1.5 Maintaining communication sessions**

10.1.5.1 A communication session with an ATO-TS shall be considered as lost when:

- a) The ATO-OB sends an STR and no STRAck is received before the end of the “Timeout for ATO-TS response” mentioned in the HSAck;

- b) The ATO-OB sends a JPReq and no JP is received before the end of the “Timeout for ATO-TS response” mentioned in the HSAck;

- c) The ATO-OB sends a SPReq and no SP is received before the end of the “Timeout for ATO-TS response” mentioned in the HSAck.

10.1.5.2 If ATO-OB loses a communication session, the ATO-OB shall try to re-establish the communication session using the same ATO-TS Contact Information that was used when establishing the session with the ATO-TS, provided that a targeted TP is available.

10.1.5.3 Having reached the last targeted TP within the JP without having recovered the communication, the ATO-OB shall try to open a communication session with the preconfigured ATO-TS Contact Information.

10.1.5.4 The ATO-OB shall not send a new STR until the acknowledgement of the previous one has been received except if this is the first STR following a Communication Session establishment.

10.1.5.5 The ATO-OB shall not store STRs while the communication session is lost. After reestablishment of the communication session the ATO-OB shall send the latest status in the STR.

10.1.5.6 **Note:** A repetition of STR is not foreseen (done at TCP level).

10.1.5.7 If a STRAck is received before the “Timeout for ATO-TS response” time has elapsed, the ATO-OB shall continue to compose and send STR.

<!-- end of page 77 -->

### **10.1.6 Communication session termination**

10.1.6.1 ATO-OB shall terminate the communication session with a given ATO-TS when one of the following conditions is fulfilled:

- a) End of Journey is reached;

- b) ATO-TS sends a termination session request;

- c) The rear of the train has left this last SP referred to by the JP which ends at the boundary of the ATO-TS;

- d) Cab is closed;

- e) TRN or train length are not valid;

- f) ETCS-OB is in NL Mode or in SH Mode.

10.1.6.2 When terminating a communication session, the ATO-OB shall send a packet SESSTerm to the ATO-TS.

10.1.6.3 **Note** : This SESSTerm packet has not to be acknowledged.

### **10.1.7 Packet exchange requirements**

10.1.7.1 Any packet received by the ATO-OB or the ATO-TS shall be ignored if it is considered as not valid.

10.1.7.2 A packet shall be considered as not valid if one of the following conditions is fulfilled:

- a) Its number is unknown;

- b) Its timestamp is older than the timestamp of a previously received packet with the same number;

- c) Its packet counter has not changed compared to the last previously received packet with the same number;

- d) Any variable uses spare values;

- e) The TRN provided by the ATO-TS does not match the TRN provided by the ETCSOB;

- f) The ETCS Identity provided by the ATO-TS does not match the ETCS Identity provided by the ETCS-OB.

10.1.7.3 In addition to the previous clause, an acknowledgment packet shall be considered as not valid if the timestamp and the packet counter information is not equal to the corresponding values of the packet to be acknowledged.

10.1.7.4 If it has no JP stored on-board, the ATO-OB shall send a JPReq with an undefined SP as a reference.

<!-- end of page 78 -->

10.1.7.5 When it receives a JPReq with an undefined SP, the ATO-TS shall send the JP starting from the SP where the train is located (according to the train rear end), if the location of the train inside an SP is available on trackside, otherwise it shall send a JP containing the first SP of the journey.

10.1.7.5.1 **Note** : As a precondition it is expected that a Control Centre will always update the Journey Information if the current schedule for the train changes.

10.1.7.5.2 **Note** : It is the responsibility of the trackside to ensure that sufficient information is provided to the ATO-OB in the JP. For example, if rear alignment of the train is required at the last TP of the JP, then, as a minimum, the JP information must cover the required location of the train at this TP.

10.1.7.6 As long as the received JP does not contain a TP including the information “End of Journey” the ATO-OB shall request JPs from the ATO-TS in due time before reaching the end of the preceding JP according to the “Time-out for ATO-TS response” defined in the HSAck and the ATO-OB computation performances.

10.1.7.7 The ATO-TS shall answer to any JPReq received from ATO-OB with which a Communication session is established.

10.1.7.8 The ATO-OB shall send JPReqs indicating the SP from which a JP is requested.

10.1.7.9 Any “valid” JP sent by ATO-TS shall include at least all information to reach one TP.

10.1.7.10 **Note** : The purpose of the previous requirement is that each JP shall extend the Journey by, at least, one Timing Point.

10.1.7.11 The minimum JP shall contain at least the next Stopping Point. In case a non-stop travel does not fit into one JP, the minimum JP shall contain at least one Passing Point with requested passing time.

10.1.7.12 The ATO-TS shall provide JP with no multiple occurrences of the same Segment Profile ID in the associated list of SPs.

10.1.7.13 A JP shall include only the TPs not yet passed or departed by the train (see §7.7.1.7).

10.1.7.14 In case the train is scheduled to pass at least one Segment Profile ID several times, the ATO-TS shall not send a JP containing any Segment Profile ID that was included in a previous JP until the train has sent a STR from which the ATO-TS concludes that the previous occurrence of the SP has been passed by the rear of the train.

10.1.7.15 The ATO-TS shall not send a JP for which there is no existing SP at the ATO-TS level.

10.1.7.16 When a JP has already been sent to ATO-OB, the ATO-TS shall be able to update it if necessary by sending a JP with the status “Update”.

10.1.7.17 When it receives a “JP Update” from the ATO-TS, the ATO-OB shall discard any previously received JP information from the first SP of the update.

<!-- end of page 79 -->

10.1.7.18 When the JP Update affects any JP information starting from the current train position towards the targeted TP, the JP Update shall only be applied once all SP leading to the targeted TP are available on-board.

10.1.7.18.1 **Note** : the old JP stays in use until the updated JP is applied.

10.1.7.19 ATO-OB behaviour after receiving a JP depending on the JP Status:

- a) A “Valid” JP specifies that the data sent is up-to-date and corresponds to the latest JPReq:

   - 1) The ATO-OB shall use the data received from ATO-TS.

- b) An “Unavailable” JP specifies that the requested part of the JP is currently not available but may become available at some point during the journey:

   - 1) The ATO-OB shall use the data it already has stored operating in ATO and shall send no JPReq until it receives a JP with the status “Update” or a new handshake process is performed;

   - 2) The ATO-TS shall send the requested JP with the status “Update” when it is available.

- c) An “Invalid” JP specifies that the SP identifier asserted in the JPReq does not belong to the preceding JP already sent to the ATO-OB:

   - 1) If the ATO-OB is able to prepare a new JPReq with another SP, the ATO-OB shall send a JPReq with that SP identifier;

   - 2) If the ATO-OB is not able to prepare a new JPReq with another SP, the ATOOB shall send a JPReq with unknown SP identifier.

- d)  An “Update” JP specifies that the JP has been updated by the Control Centre modifying or adding information to previously transmitted ones:

   - 1) The ATO-OB shall use the data received from ATO-TS;

   - 2) The ATO-OB shall send the JPAck to the ATO-TS using the timestamp and packet counter information of that JP.

- e) An “Overwrite” JP specifies that the previous data sent from any JP has to be discarded and to be replaced with the data sent by that JP:

   - 1) The ATO-OB shall discard any stored JP information;

   - 2) The ATO-OB shall use the data received from ATO-TS;

   - 3) The ATO-OB shall send the JPAck to the ATO-TS using the timestamp and packet counter information of that JP.

10.1.7.20 When it receives a JP containing a TP including the information “End of Journey”, the ATO-OB shall not send JPReqs to this ATO-TS with the same TRN.

10.1.7.21 Upon receipt of a new JP that includes at least one SP (defined by the identifier and version) in the list of SPs that is not available on-board, the ATO-OB shall send SPReqs for those SPs.

10.1.7.22 **Note:** A single SPReq could include several SP_ID requests.

<!-- end of page 80 -->

10.1.7.23 The reply of the ATO-TS to an SPReq shall indicate the evaluation status of the request:

   - a) Valid: the requested SP is included;

   - b) Invalid: the requested SP is not available in the ATO-TS.

10.1.7.24 When an SP is received, the ATO-OB shall always be able to store it at least whilst it remains relevant for the current journey.

10.1.7.25 When it receives an SP, the ATO-OB shall compare the version number of the SP listed in the JP and the version number of the received one. If they are not the same the reaction described in §7.8.3.2 applies.

10.1.7.26 Hereafter are explained the acknowledgement procedures:

   - a) An HSReq sent by the ATO-OB shall be acknowledged by an HSAck sent by the ATO-TS;

   - b) A JPReq sent by the ATO-OB shall be acknowledged by reception of the corresponding JP coming from the ATO-TS;

   - c) A “JP Update” sent by the ATO-TS shall be acknowledged by a JPAck sent by the ATO-OB;

   - d) An SPReq sent by the ATO-OB shall be acknowledged by reception of the corresponding SP coming from the ATO-TS;

   - e) An STR packet sent by the ATO-OB shall be acknowledged by an STRAck;

   - f) A “JP Overwrite” sent by the ATO-TS shall be acknowledged by a JPAck sent by the ATO-OB.

10.1.7.27 The following diagram and description show an example of a communication sequence after the communication establishment.

<!-- Start of picture text -->
1<br>2<br>Communication<br>establishment 3<br>4 ATO-TRK ATO-TS<br>1 2 3 4<br>Timing Point A Timing Point B Timing Point C Timing Point D<br><!-- End of picture text -->

**Figure 11 Communication sequence**

- 1) Train is at TP A:

   - a) The ATO-OB requests the JP from the ATO-TS.

   - b) The ATO-TS sends, at least, the JP until the next TP B to the ATO-OB.

   - c) The ATO-OB requests the corresponding SPs from the ATO-TS if not already in memory.

   - d) The ATO-TS sends the SPs to the ATO-OB if there is a request.

- 2) Train is running between TPs A and B:

<!-- end of page 81 -->

- a) If there is any updating in the JP, the ATO-TS sends the updated JP to the ATOOB that replies with a JPAck.

- b) At any time, the ATO-OB could request any upcoming JPs.

- c) The ATO-TS sends the requested JPs if available.

<!-- end of page 82 -->

- 3) Train is at TP B:

   - a) If the ATO-OB does not have the JP until the next TP C, it is requested from the ATO-TS.

   - b) If there is a request, the ATO-TS sends, at least, the JP until the next TP to the ATO-OB.

   - c) The ATO-OB requests the corresponding SPs from the ATO-TS if not already in memory.

   - d) The ATO-TS sends the SPs to the ATO-OB if there is a request.

- 4) Idem as “2)” but between TPs B and C.

### **10.1.8 Communication Session Transitions**

10.1.8.1 The “communication session management” is based on the following states:

- a) NCE (No Communication Established): in this state, the ATO-OB checks the conditions to start a communication session;

- b) CSR (Communication Session Requested): in this state, the ATO-OB sends an HSReq to the ATO-TS to be connected;

- c) CSE (Communication Session Established): the ATO-OB communicates with the ATO-TS checking conditions to maintain the session established;

- d) CST (Communication Session Terminated): The ATO-OB sends a packet SESSTerm.

10.1.8.2 ATO-OB shall request to establish a connection for any transition to CSR

10.1.8.3 ATO-OB shall release the connection for any transition to CST or NCE.

10.1.8.4 The following figure gives the State Machine Transition Diagram of ATO-OB communicating with one specific ATO-TS:

<!-- end of page 83 -->

<!-- Start of picture text -->
Communication<br>Session<br>Start Terminated<br>(CST)<br>[3] or [4] or [6] [3] or [4] or [9]<br>or [9] or [13] or [12] or [13]<br>[7] or [15]<br>[8] or [14]<br>No Communication Communication<br>[1] or [11]<br>Communication Session [2] Session<br>Established  Requested  Established<br>(NCE) (CSR) (CSE)<br>[5]<br>[10]<br>End<br><!-- End of picture text -->

**Figure 12 Communication Session State Transitions**

10.1.8.5 The table below defines the transitions between states:

<!-- Start of picture text -->
NCE <7,15  <7,15  <10<br>-p4-  -p4-  -p2-<br>1>, 11>  CSR <8,14<br>-p1-  -p3-<br>8,14>  CSR <5<br>-p3-  -p3-<br>2>  2>  CSE<br>-p2-  -p2-<br>3,4,6,9,13>  3,4,6,9,13>  3,4,9,12,13>  CST<br>-p1-  -p1-  -p1-<br>Any>  End<br>-p1-<br><!-- End of picture text -->

**Table 9 Transition table**

10.1.8.6 The indication “4>” means: The condition n°4 must be fulfilled to trigger the transition from the state located in the column to the state that is indicated by the arrow “>”.

10.1.8.7 Each transition from a given state receives a priority order (indicated by “-px-”, x is the priority order) to avoid a conflict between the different transitions when they occur at the same time (i.e. in the same clock cycle). P1 has a higher priority than P2.

10.1.8.8 "8, 10, 11" means "8 or 10 or 11".

<!-- end of page 84 -->

10.1.8.9 If several consecutive transition conditions are fulfilled at the same time, the ATO-OB State shall transition from the initial state to the final state without performing any action(s) linked to the intermediate state(s).

10.1.8.10 Communication session transition conditions table:

|**Condition**<br>**Id**|**Content of the conditions**|
|---|---|
|[1]|CAB is active<br>and TRN is available<br>and ETCS identity is available<br>and train length is available<br>and ETCS-OB is not in NL Mode or is not in SH Mode<br>and preconfigured ATO-TS Contact Information is to be used.|
|[2]|HSAck received|
|[3]|"End of Journey" reached (Stopping Point) or passed (Passing Point or Stopping Point to be<br>skipped)|
|[4]|TRN has changed|
|[5]|((ATO-OB sends STR with no STRAck before timeout)<br>or (ATO-OB sends JPReq with no JP before timeout)<br>or (ATO-OB sends SPReq with no SP before timeout))<br>and A targeted TP is available|
|[6]|HSRej indicating that ATO-OB and ATO-TS are not compatible|
|[7]|HSRej indicating that ATO-TS in charge is not known|
|[8]|HSRej indicating that another ATO-TS is in charge|
|[9]|CAB is inactive<br>or TRN is not valid<br>or train length is not valid<br>or ETCS-OB is in NL Mode<br>or ETCS-OB is in SH Mode|
|[10]|((ATO-OB sends STR with no STRAck before timeout)<br>or (ATO-OB sends JPReq with no JP before timeout)<br>or (ATO-OB sends SPReq with no SP before timeout))<br>and (NO targeted TP is available)|
|[11]|The JP includes an SP which contains an ATO-TS Contact Information of an adjacent ATO-TS and<br>the ATO-OB decides to establish a communication with the adjacent ATO-TS.|
|[12]|SESSTermReq sent by ATO-TS|
|[13]|Rear of the train has left the last SP in rear of the border|
|[14]|No feedback (HSAck or HSRej) received and, at least, 30 seconds have passed since ATO-OB has<br>sent an HSReq to ATO-TS and a targeted TP is available|

<!-- end of page 85 -->

|**Condition**<br>**Id**|**Content of the conditions**|
|---|---|
|[15]|No feedback (HSAck or HSRej) received|
||and, at least, 30 seconds have passed since ATO-OB has sent an HSReq to ATO-TS<br>and no targeted TP is available|

#### **Table 10 Transition conditions table**

## **10.2 ATO-OB / ETCS-OB interface**

### **10.2.1 Introduction**

10.2.1.1 The ATO-OB and the ETCS-OB are connected via an interface over which data is exchanged. The format (packets) of the data is described in [Ref 6], while the requirements about what and when to be exchanged is presented in the remainder of this section §10.2.

10.2.1.2 This section §10.2 also contains some specific requirements for the ATO-OB and ETCS- OB related to the exchange of data over that interface.

10.2.1.3 This section §10.2 is mainly related to data transmitted from ETCS-OB to ATO-OB. The requirements related to data transmitted from ATO-OB to ETCS-OB can be found in other sections of this document.

10.2.1.4 All the data is sent cyclically according to the transmitting cycles specified in [Ref 6], unless where otherwise stated (e.g. Specific ATO Data Entry packets as defined in §7.13.2).

### **10.2.2 Communication management**

10.2.2.1 The ETCS-OB and the ATO-OB shall exchange packets while the connection is established.

10.2.2.2 Both ETCS-OB and ATO-OB shall distinguish between “connection active” and “connection not active” states.

10.2.2.3 The initial state shall be “connection not active”.

10.2.2.4 The state shall change from “connection not active” to “connection active” when for each specified process data, valid packets are received.

10.2.2.5 Both ETCS-OB and ATO-OB shall maintain for each packet a timeout value specified in [Ref 6]. Whenever a valid packet is received the receiver shall reset the specific packet timeout counter.

10.2.2.6 The connection shall be considered as “not active” if one of the timeout counters is triggered.

<!-- end of page 86 -->

10.2.2.7 **Note:** When the ETCS-OB considers the connection as “not active”, it will change from AD Mode to the applicable ETCS Mode according to the ETCS mode transition table as defined in [Ref 5] §4.6.

10.2.2.8 If the timeout is triggered from the ETCS-OB side or if ATO-OB is going to "FA" State, the ETCS-OB shall:

- a) Start displaying the “ATO Failure” indication;

- b) Produce a warning sound for a duration of 5 seconds.

- c) Stop the communication with ATO-OB for 10 seconds.

10.2.2.9 The ATO-OB shall identify the recently active ETCS-OB by using the active cabin information provided through the train/ATO-OB interface and the ATO-OB specific configuration listing its associated ETCS-OB. Initially the recently active ETCS-OB is not known. Once a cabin is active the ETCS-OB associated to the active cabin becomes the recently active ETCS-OB until the active cabin information changes to a different associated ETCS-OB. Deactivation of a cabin will not change the recently active ETCSOB.

10.2.2.10 The ATO-OB shall transition to FA State if it considers the connection to the recently active ETCS-OB as “not active” while being in any ATO-OB State but CO.

10.2.2.11 When ATO-OB is connected to two ETCS-OB, the ATO-OB shall only evaluate information from the recently active ETCS-OB.

### **10.2.3 General requirements**

10.2.3.1 Any packet received by the ETCS-OB or the ATO-OB shall be ignored if it is considered as not valid.

10.2.3.2 A packet is considered as not valid if one of the following conditions is fulfilled:

- a) Its number is not known;

- b) Its timestamp is older than a previously received packet with the same number;

- c) Any variable uses spare values;

- d) The computed length of the packet does not correspond to the one indicated in the corresponding variable;

- e) The computed Checksum/CRC of the packet does not correspond to the one indicated in the corresponding packet.

10.2.3.3 The packets exchanged between the ETCS-OB and the ATO-OB shall include a header containing the following information:

- a) Packet Number;

- b) Packet Length;

- c) Timestamp identifying the time at which the packet is sent.

<!-- end of page 87 -->

10.2.3.4 The dynamic packet sent by the ETCS-OB to the ATO-OB shall contain a timestamp identifying the time at which the current position counter was determined.

10.2.3.5 The ETCS-OB shall set the packet timestamp and the timestamp identifying the time at which the current position counter was determined with an accuracy of 1 ms.

10.2.3.6 The ETCS-OB shall use the same source of time for the timestamp and the time at which the position counter is determined. As long as ETCS-OB being powered on, the source of time shall be continuously counting without adjustments (e.g. trainborne clock).

10.2.3.7 **Note:** The packet timestamp is used together with the time at which the position counter is determined to determine the time elapsed since the variables were composed (see §7.10.1.1 e) and §7.10.1.3 e)).

10.2.3.8 While low adhesion is selected by the driver, the ETCS-OB shall report the information “slippery rail” to the ATO-OB (see §7.5.1.1).

### **10.2.4 ETCS Data**

10.2.4.1 While no valid ETCS Train Data is available, the ETCS-OB shall send the information “ETCS Train Data not valid” to the ATO-OB and shall send no Train Data.

10.2.4.2 While valid ETCS Train Data is available, the ETCS-OB shall send the information “ETCS Train Data valid” and the data defined in §7.13.1.1 to the ATO-OB.

10.2.4.3 While the TRN or the Driver ID is not validated, the ETCS-OB shall send the information “ETCS Operational Data not valid” to the ATO-OB and shall not send their values.

10.2.4.4 While the TRN and the Driver ID are validated, the ETCS-OB shall send the information “ETCS Operational Data valid” to the ATO-OB and shall send their values.

### **10.2.5 Position data**

10.2.5.1 The ETCS-OB shall send its raw position counter information.

10.2.5.2 The position counter shall be estimated less than 200 ms before the beginning of sending of the corresponding packet.

10.2.5.3 The position counter shall increase when the train is moving in positive movement direction. It shall decrease when the train is moving in negative movement direction. The ETCS-OB shall also indicate to the ATO-OB whether a movement in the direction of the train orientation corresponds to an increase or a decrease of the raw counter.

10.2.5.4 All the position counter values shall be such that the absolute value of the difference between the current position counter and the position counter at the time when the Location Reference Balise of the ETCS SOLR was detected corresponds to the estimated front end as used by the ETCS-OB, when it is augmented/diminished (depending whether a movement in the direction of the train orientation corresponds to an increase or a decrease of the raw counter respectively) by the distance between the

<!-- end of page 88 -->

antenna active at the time when the Location Reference Balise of the ETCS SOLR was detected and the front end of the train.

10.2.5.5 **Note:** Positive movement direction is defined as a movement in the forward direction in relation to cab A.

10.2.5.6 **Note:** Negative movement direction is defined as movements in the backwards direction in relation to cab A.

10.2.5.7 **Note:** Allocation of cab(s) on a specific train is a pure ETCS-OB implementation issue.

10.2.5.8 The ETCS-OB shall not reset the position counter as long as the ETCS-OB is poweredon.

10.2.5.9 The position counter shall not be decreased or increased in case of repositioning or relocation.

10.2.5.10 The position counter shall wrap around when exceeding the value range.

10.2.5.11 The maximum value of the position counter is a special value "NOT ALLOWED". This is used as an unknown value in other variables which depend on this counter and shall not be sent as a normal value, instead the maximum but one value shall be sent.

10.2.5.12 All the position counter related variables sent by the ETCS-OB (except the passed balise related ones) are obtained by adding/subtracting the distances to the relevant location items (possibly resulting from repositioning or relocation) to/from the position counter value of the SOLR, depending whether a movement in direction of the train orientation corresponds to an increase or a decrease of the raw counter respectively.

10.2.5.13 For all the variables sent by ETCS-OB and related to the position counter, instead of the maximum value, the maximum but one value shall be sent.

10.2.5.14 The ETCS-OB shall send to the ATO-OB the confidence interval to the train position from the SOLR (see [Ref 5] §3.6.4.1.1).

### **10.2.6 Balise information**

10.2.6.1 The ETCS-OB shall use the identification of a balise of a BG as the identification of the reference balise in the packets sent to the ATO-OB once the ETCS-OB considers the corresponding BG to be the SOLR.

10.2.6.2 The ETCS-OB shall send balise information (including balise identification, value of the position counter, time when the balise was passed and identification of the active antenna when the balise was passed) of the two last passed balises and of the LRBG to the ATO-OB.

10.2.6.3 The ETCS-OB shall send to the ATO-OB the information about passed balises within the first 1 second after a telegram is received from the balise and has passed the telegram consistency checks (see [Ref 5] §A.3.3.1) successfully.

<!-- end of page 89 -->

10.2.6.4 **Note:** In case more than two balises are passed within the cyclic transmission time, the ETCS-OB may not transmit some of them to the ATO-OB.

10.2.6.5 The ETCS-OB shall store the identifier and position of the two last balises passed and the SOLR as this information is cyclically transmitted to the ATO-OB. The information about the two last balises passed shall follow the same rules as the information "Train position" ([Ref 5] §3.6.1.3), e.g. when the ETCS-OB is powered off.

10.2.6.6 The ETCS-OB shall send to the ATO-OB the “orientation of the train in relation to the direction of the SOLR” and the “position of the front end of the train in relation to the SOLR” (defined for SOLR by analogy to LRBG as defined in [Ref 5] §3.6.5).

10.2.6.7 The ETCS-OB shall send linking information (including balise identification, and estimated value of the position counter at the announced balise group) for the next linked balise groups known by the ETCS-OB in the same order as received from ETCS Trackside.

### **10.2.7 Supervision information**

10.2.7.1 While being in AD, FS or OS, the ETCS-OB shall send supervision data to the ATO-OB.

10.2.7.2 The ETCS-OB shall send the location of the closest EBI supervision limit for the current speed of the train.

10.2.7.3 The ETCS-OB shall send to the ATO-OB the list of applicable A_GRADIENT (d) (determined as per [Ref 5] §3.13.6.2.1.3) and A_MAXREDADH (d) (see §10.2.7.6) over a distance range covering at least:

- a) In case of EOA/SvL, the distance from the max safe front end of train to the SvL;

- b) In case of LOA, the distance from the max safe front end of train to furthest location between the LOA and the furthest supervised target beyond the LOA whose speed value is lower than the LOA speed value, if any.

10.2.7.4 Over the distance range specified in §10.2.7.3, the ETCS-OB shall send up to 51 A_GRADIENT (d) including:

- a) Up to 50 gradient values as defined in [Ref 12] §4.3.2.1.1 f).

- b) A special value to close the profile.

10.2.7.5 A_GRADIENT (d) shall be equal to:

- A_GRADIENT1 when dmaxsafefront ≤ d ≤ N_LOC_GRADCHANGE1;

- A_GRADIENT2 when N_LOC_GRADCHANGE1 < d ≤ N_LOC_GRADCHANGE2;

A_GRADIENTn when N_LOC_GRADCHANGEn-1 < d ≤ N_LOC_GRADCHANGEn, Where:

A_GRADIENTx is the acceleration/deceleration value due to gradient;

N_LOC_GRADCHANGEx is the value of the position counter at the gradient change.

<!-- end of page 90 -->

10.2.7.6 In order to send to the ATO-OB a continuous profile A_MAXREDADH(d), the ETCS-OB shall take into account:

- a) The locations with reduced adhesion conditions and the locations with change of special brake(s) contribution (see [Ref 5] §3.13.5);

- b) The brake position and whether special/additional brakes independent from wheel/rail adhesion are active and it is allowed to take into account their contribution to the emergency braking effort (see [Ref 5] §3.13.6.2.1.6).

10.2.7.7 Over the distance range specified in §10.2.7.3, the ETCS-OB shall send up to 22 A_MAXREDADH (d) including:

- a) The adhesion conditions between the max safe front end of the train and the first adhesion conditions change;

- b) Up to 20 changes of adhesion conditions as defined in [Ref 12] §4.3.2.1.1 q) (the maximum would be 10 start locations plus 10 end locations);

- c) A special value to close the profile.

10.2.7.8 A_ MAXREDADH (d) shall be equal to:

A_MAXREDADH1 when dmaxsafefront ≤ d ≤ N_LOC_ADHCHANGE1;

A_MAXREDADH2 when N_LOC_ADHCHANGE1 < d ≤ N_LOC_ADHCHANGE2;

A_MAXREDADHn when N_LOC_ADHCHANGEn-1 < d ≤ N_LOC_ADHCHANGEn, Where:

A_MAXREDADHx is the maximum deceleration value due to adhesion conditions or specifies that there is no maximum deceleration due to reduced adhesion conditions;

N_LOC_ADHCHANGEx is the value of the position counter at the adhesion conditions change.

10.2.7.9 The ETCS-OB shall send to the ATO-OB the safe emergency brake deceleration (A_BRAKE_SAFE (d,V)) (see [Ref 5] 3.13.6.2.1.4) values over a speed and distance range covering at least:

- a) In case of EOA/SvL:

   - 1) The distance from the max safe front end of train to the SvL;

   - 2) The speeds from 0 to the maximum MRSP speed value encountered within the above distance, augmented by dv_EBI calculated for this MRSP max speed value, by V_DELTA0, by V_delta1 and by V_delta2.

- b) In case of LOA:

   - 1) The distance from the max safe front end of train to furthest location between the LOA and the furthest supervised target beyond the LOA whose speed value is lower than the LOA speed value, if any;

   - 2) The speeds from the lowest value between the LOA speed and the minimum MRSP speed value encountered within the above distance to the maximum MRSP speed value encountered within the above distance, augmented by

<!-- end of page 91 -->

dv_EBI calculated for this MRSP max speed value, by V_DELTA0, by V_delta1 and by V_delta2.

10.2.7.10 Over the speed range specified in §10.2.7.9, the ETCS-OB shall send up to 10 A_BRAKE_SAFE (V) values for the current applicable values and for each location with a change of the safe emergency brake deceleration model (see [Ref 5] §3.13.2.3.7.11, A.3.7.4&5).

10.2.7.11 Over the distance range specified in §10.2.7.9, the ETCS-OB shall send up to 40 changes of safe emergency brake deceleration models as defined in [Ref 12] § 4.3.2.1.1 l) (the maximum would be 20 start locations plus 20 end locations).

10.2.7.12 Based on the following example:

<!-- Start of picture text -->
V<br>A_BRAKE_SAFE3 A_BRAKE_SAFE6 A_BRAKE_SAFE9<br>A_BRAKE_SAFE2 A_BRAKE_SAFE5 A_BRAKE_SAFE8<br>A_BRAKE_SAFE1 A_BRAKE_SAFE4 A_BRAKE_SAFE7<br>d<br><!-- End of picture text -->

#### **Figure 13 Example for sending safe emergency brake deceleration values**

10.2.7.13 The ETCS-OB shall send to the ATO-OB the safe emergency brake deceleration as a function of the speed and the locations with change of special brake(s) contribution encountered. A_BRAKE_SAFE (V,d) shall be equal to:

A_BRAKE_SAFE1 when (0 ≤ V ≤ V_CHANGE_BRAKE1) AND

- (dmaxsafefront ≤ d ≤ N_LOC_SEBDM_CHANGE1)

A_BRAKE_SAFE2 when (V_CHANGE_BRAKE1 < V ≤ V_CHANGE_BRAKE2) AND

(dmaxsafefront ≤ d ≤ N_LOC_SEBDM_CHANGE1)

A_BRAKE_SAFE3 when (V_CHANGE_BRAKE2 < V) AND

- (dmaxsafefront ≤ d ≤ N_LOC_SEBDM_CHANGE1)

A_BRAKE_SAFE4 when (0 ≤ V ≤ V_CHANGE_BRAKE1) AND

- (N_LOC_SEBDM_CHANGE1 <d ≤ N_LOC_SEBDM_CHANGE2);

A_BRAKE_SAFE5 when (V_CHANGE_BRAKE1 < V ≤ V_CHANGE_BRAKE2) AND (N_LOC_SEBDM_CHANGE1 < d ≤ N_LOC_SEBDM_CHANGE2);

A_BRAKE_SAFE6 when (V_CHANGE_BRAKE2 < V) AND

(N_LOC_SEBDM_CHANGE1 < d ≤ N_LOC_SEBDM_CHANGE2);

A_BRAKE_SAFE7 when (0 ≤ V ≤ V_CHANGE_BRAKE1) AND

(N_LOC_SEBDM_CHANGE2 < d);

<!-- end of page 92 -->

A_BRAKE_SAFE8 when (V_CHANGE_BRAKE1 < V ≤ V_CHANGE_BRAKE2) AND (N_LOC_SEBDM_CHANGE2 < d);

A_BRAKE_SAFE9 when (V_CHANGE_BRAKE2 < V) AND

(N_LOC_SEBDM_CHANGE2 < d),

Where:

A_BRAKE_SAFEx is the maximum deceleration value due to the safe emergency brake deceleration;

V_CHANGE_BRAKEx is the value of the safe emergency brake deceleration model change due to the speed;

N_LOC_SEBDEM_CHANGEx is the location of a safe emergency brake deceleration model change due to the location.

10.2.7.14 The ETCS-OB shall send to the ATO-OB the Most Restrictive Speed Profile (MRSP) computed by the ETCS-OB (see [Ref 5] §3.13.7) as a most restrictive speed depending on the location (V_MRSP(d)). The V_MRSP shall be equal to:

   - V_MRSP1 when dminsafefront ≤ d ≤ N_LOC_ MRSP1;

V_MRSP2 when N_LOC_ MRSP1 < d ≤ N_LOC_ MRSP2;

V_MRSPn when N_LOC_ MRSPn-1 < d ≤ N_LOC_ MRSPn,

Where:

V_MRSPx is the most restrictive speed restriction;

- N_LOC_MRSPx is the value of the position counter at the most restrictive speed change.

10.2.7.15 The ETCS-OB shall send to the ATO-OB the location and permitted speed of the most relevant EOA or LOA (including temporary EOAs) and the Supervised Location.

10.2.7.16 The ETCS-OB shall send to the ATO-OB the current applicable values of the:

- a) Time during which the traction effort is still present after the Emergency brake intervention;

- b) Brake reaction time during which the braking effort is not yet present after the Emergency brake intervention;

- c) Remaining time during which the traction effort is not present until the equivalent brake build up time elapses after the Emergency brake intervention;

- d) Compensation of the inaccuracy of the speed measurement;

- e) Current estimated train speed;

- f) Current estimated train acceleration.

10.2.7.17 In CSM, TSM and RSM, the ETCS-OB shall send to the ATO-OB the current permitted speed, the current release speed and the current RSM start location.

10.2.7.18 The estimated speed and the estimated acceleration shall be estimated less than 200ms before the beginning of the sending of the corresponding packet.

<!-- end of page 93 -->

### **10.2.8 Driver inputs**

10.2.8.1 If the ETCS-OB is in AD Mode, when the driver selects “ATO Engage”, the ETCS-OB shall increase the value of the “ATO Engage selection counter”.

10.2.8.2 If the ETCS-OB is not in AD Mode, when the driver selects “ATO Engage”, the ETCSOB shall increase the value of the “ATO Engage selection counter” only after changing to AD Mode.

10.2.8.3 When the driver selects “Skip Stopping Point Request”, the ETCS-OB shall increase the value of the “Skip Stopping Point Request selection counter”.

10.2.8.4 When the driver selects “Skip Stopping Point Revocation”, the ETCS-OB shall increase the value of the “Skip Stopping Point Revocation selection counter”.

10.2.8.5 The ETCS-OB shall increase the value of any driver input selection counter not later than 500 ms after the input is selected.

10.2.8.6 The ATO-OB shall consider that the driver has selected a DMI input when the value of the related counter is increased between two packets.

### **10.2.9 Configuration Management**

10.2.9.1 The following table lists the configuration data related to the ATO-OB/ETCS-OB interface, which shall be considered for offline agreement.

|**Nr.**|**Configuration Items**|**Description**|
|---|---|---|
|1.|Sets of full service brake models<br>and their corresponding indexes|See [Ref 5] §3.13.2.2.3.1<br>See §7.13.1.2 to §7.13.1.5.|
|2.|Normal service brake models<br>together with their corresponding<br>brake position and pivot values|See [Ref 5] §3.13.2.2.3.1.9 and<br>§3.13.2.2.3.1.10<br>See §7.13.1.5 b).|
|3.|List of cabins and their associated<br>ETCS-OB|See §10.2.2.9.|

#### **Table 11 Configuration Items**

<!-- end of page 94 -->

## **10.3 ATO-OB / Rolling Stock Interface**

### **10.3.1 Configuration management**

10.3.1.1 The following table lists the configuration data to be agreed between ATO supplier and Rolling Stock supplier related to the ATO-OB/RST interface, which shall be considered by the ATO supplier for offline agreement.

|**Nr.**|**Configuration Items**|**Description**|
|---|---|---|
|1.|Brake architecture category|C-type trains or S-type trains|
|2.|Direct brake control by ATO-OB|Used or not|
|3.|Train doors control by ATO-OB|Doors control available yes or no|
|4.|RST timeout response|Timeout to consider that feedback<br>signals are consistent with ATO-OB<br>control signals.|
|5.|Dynamic brake force limitation|Applied by the train or by ATO-OB<br>(see clause 7.1.5.9).|

#### **Table 12 Configuration Items**

<!-- end of page 95 -->
