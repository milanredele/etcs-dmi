## **3.5 Management of Radio Communication**

### **3.5.1 Introduction**

3.5.1.1 Note: the following section refers to the behaviour of the user application interacting with Euroradio protocols. How the messages are actually transported from the sender to the receiver user application is not relevant for this description.

3.5.1.2 Only communication sessions between an ERTMS/ETCS on-board equipment and a trackside equipment (RBC or Radio Infill Unit) are considered here.

**3.5.2 General**

3.5.2.1 Each communication session managed by an entity allows the exchange of data with only one other entity.

3.5.2.2 Note: in the following sections reference is made to safe radio connections, whose definition and management is contained in Euroradio specification.

<!-- end of page 19 -->

3.5.2.3 Note: The information Initiation of a Communication Session and Version not Compatible (see sections 3.5.2.4 and 3.17) are the same in every system version.

3.5.2.4 If the GSM-R radio system is installed on-board, the ERTMS/ETCS on-board equipment shall be able to manage simultaneous communication sessions established through GSM-R with at least two different entities.

3.5.2.5 Only the ERTMS/ETCS on-board equipment can initiate the establishment or the termination of a communication session.

3.5.2.6 The trackside has the following possibilities to order the initiation of establishment or termination of a communication session:

3.5.2.6.1 The session management order for RBC that includes: a) The identity of the RBC.

   - b) The telephone number of the RBC (only if interfaced to GSM-R).

   - c) The action to be performed (establish/terminate the session).

   - d) Whether the action applies also to Sleeping units.

3.5.2.6.2 The RBC transition order that embeds an order to establish a communication session with the Accepting RBC which includes: a) The identity of the Accepting RBC.

   - b) The telephone number of the Accepting RBC (only if interfaced to GSM-R).

   - c) Whether the action to establish a communication session applies also to Sleeping units.

3.5.2.6.3 The Radio infill area information that embeds a session management order for RIU which includes:

   - a) The identity of the Radio Infill Unit.

   - b) The telephone number of the Radio Infill Unit.

   - c) The action to be performed (establish/terminate the session).

3.5.2.6.4 The session management order for neighbouring RIU that includes:

   - a) The identity of the Radio Infill Unit.

   - b) The telephone number of the Radio Infill Unit.

   - c) The action to be performed (establish/terminate the session).

### **3.5.3 Establishing a communication session**

3.5.3.1 Intentionally deleted.

3.5.3.2 Intentionally deleted.

3.5.3.3 Intentionally deleted.

<!-- end of page 20 -->

3.5.3.4 The on-board shall establish a communication session

   - a) At Start of Mission (only if level 2).

   - b) If ordered from trackside.

   - c) If a mode change, neither considered as an End of Mission nor triggered from condition g) below, has to be reported to the RBC (only if level 2)

   - d) If the driver has manually changed the level to 2

   - e) When the engine rear end reaches the end of an announced radio hole

   - f) When the previous communication session is considered as terminated due to loss of safe radio connection (refer to 3.5.4.2.1)

   - g) When a Start of Mission procedure, during which no communication session could be established, is completed in level 2

   - h) When outside the Start of Mission procedure, the driver has manually selected the RBC contact information (only if level)

3.5.3.4.1 In respect of a), b), c), d), e) and h) of 3.5.3.4, the on-board shall not establish a new communication session with an RBC/RIU in case a communication session:

   - is currently being established with this RBC/RIU or

   - is already established with this RBC/RIU and no Termination of Communication Session message has been sent to this RBC/RIU.

3.5.3.4.2 In respect of b), c), d), e) and h) of 3.5.3.4, in case a communication session is already established with this RBC/RIU and a Termination of Communication Session message has been sent to this RBC/RIU the on-board shall establish a new communication session with this RBC/RIU as soon as the already established communication session is terminated and the safe radio connection is released.

3.5.3.5 Intentionally deleted.

3.5.3.5.1 Intentionally deleted.

3.5.3.5.2 If the ERTMS/ETCS on-board equipment has to establish a communication session with an RBC whilst in session with one or more other RBC(s), the existing communication session(s) shall be terminated (see 3.5.5.2 for details) and the new one shall be established.

3.5.3.5.2.1 Exception: an order to establish a communication session with an Accepting RBC, which is embedded in the RBC transition order, shall not terminate the communication session with the currently supervising RBC, unless the on-board equipment is only able to handle one communication session through GSM-R and the situation is such that a session must be established with another RBC (see 3.15.1.3.2.4 for details).

3.5.3.5.3 Intentionally deleted.

3.5.3.6 Intentionally deleted.

<!-- end of page 21 -->

3.5.3.7 The establishment of a communication session shall be performed according to the following steps:

   - a) The on-board shall request the set-up of a safe radio connection with the trackside. If this request is part of an ongoing Start of Mission procedure or is related to the establishment of a communication session due to condition 3.5.3.4 c), it shall be repeated until successful or a defined number of times (see Appendix A.3.1).

If this request is not part of an ongoing Start of Mission procedure and is not related to the establishment of a communication session due to condition 3.5.3.4 c), it shall be repeated until successful.

A request shall be repeated immediately after EURORADIO has indicated that setting up the safe radio connection has failed.

- b) As soon as the safe radio connection is set-up, the on-board shall send the message Initiation of communication session to the trackside.

- c) As soon as the trackside receives the information, it shall send the system version.

- d) When the on-board receives the system version it shall consider the communication session established and:

   - If one of its supported system versions is compatible with the one sent by trackside, it shall send a session established report, including its supported system versions, to the trackside.

   - If none of its supported system versions is compatible with the one sent by trackside, it shall send a version independent message indicating “No compatible version supported”. It shall inform the driver and shall terminate the communication session.

- e) When the trackside receives the session established report or the information that no compatible system version is supported by the on-board, it shall consider the communication session established. Upon reception of a session established report, the trackside shall acknowledge the establishment of the communication session to the on-board.

<!-- end of page 22 -->

<!-- Start of picture text -->
On-Board  Trackside<br>Set-up of the safe connection<br>According to EURORADIO specifications<br>Initiation of a<br>communication<br>session<br>Communication<br>RBC/RIU<br>session<br>established for System Version<br>on-board<br>Session  Communication<br>established  session<br>established for<br>trackside<br>Acknowledgement of<br>Session Establishment<br><!-- End of picture text -->

#### **Figure 3: Establishment initiated by on-board**

3.5.3.7.1 Regarding a), if both radio systems are installed on-board it shall request the set-up of a safe radio connection according to the following (by priority order):

   - 1) In case of order received from trackside, depending on whether the order relates to an RBC interfaced with FRMCS only, OR

   - 2) If the stored Radio Network type is FRMCS+GSM-R and if during the SoM the driver has elected to perform the mission with only one radio system, by using either the FRMCS on-board equipment or a GSM-R Mobile Terminal, depending on the radio system to which the registration was successful during the SoM, OR

   - 3) According to the stored Radio Network information (Radio Network type and, if relevant, GSM-R Radio Network ID). If the Radio Network type is FRMCS+GSMR, the ERTMS/ETCS on-board shall use, if available, the preferred radio system stored when establishing the previous communication session with the RBC (see SUBSET-037-1 for details)

3.5.3.7.2 Regarding b), if both radio systems are installed on-board it shall store the radio system through which the safe radio connection is successfully set up.

3.5.3.7.3 Exception to d): when the on-board does not receive the system version within a fixed waiting time (see A.3.1) it shall request the release of the safe radio connection with the trackside and shall restart the establishment of the communication session with step a).

<!-- end of page 23 -->

3.5.3.7.4 Regarding e), in case the on-board has sent a session established report: when the onboard does not receive an acknowledgement of the establishment of the communication session within a fixed waiting time (see A.3.1), it shall again send a session established report to the trackside.

3.5.3.7.4.1 If, following the repetition of the session established report, the acknowledgement of session establishment is still not received within the fixed waiting time, the on-board shall terminate the communication session and re-establish a new one.

3.5.3.7.5 Exception to e): If the trackside receives a "Termination of communication session" message, instead of a session established report or the information that no compatible system version is supported by the on-board, it shall abort the process of session establishment and proceed with clause 3.5.5.2 b).

3.5.3.8 When a communication session is currently being established (i.e. at any time from the first request the set-up of a safe radio connection to the reception of the system version from trackside), the on-board shall no longer apply 3.5.3.7 a), 3.5.3.7 b) and 3.5.3.7 d) (i.e. it aborts the process of establishing it) and shall release the safe radio connection (if any) if at least one of the following conditions is met:

   - a) The driver closes the desk during Start of Mission

   - b) End of Mission is performed

   - c) An order to terminate the communication session is received from trackside

   - d) The train passes with its min safe rear end a level transition border from a level 2 area to an area where level 2 operation is not supported

   - e) An order to establish a communication session with a different RBC is received from trackside and the order does not request to contact an Accepting RBC

   - f) The train passes an RBC/RBC border with its min safe rear end

   - g) The engine front end passes the start of an announced radio hole

   - h) Regards RIUs only: Level 1 is left

   - i) The driver elects to modify the Radio Network type or the GSM-R Radio Network ID

3.5.3.9 Intentionally deleted.

3.5.3.9.1 Intentionally deleted.

3.5.3.10 Intentionally deleted.

#### **Figure 4: Intentionally deleted**

3.5.3.11 If the driver selects “Use of EIRENE short number” to contact the RBC, the on-board shall not use the stored RBC ID/phone number, if any.

3.5.3.11.1 Note 1: The on-board stored short number for calling the “most appropriate RBC” is defined by EIRENE.

<!-- end of page 24 -->

3.5.3.11.2 Justification: In case of EIRENE short number selection by the driver, the termination of the connection if the “most appropriate RBC” does not match the one previously stored on-board (EURORADIO functionality) must not occur.

3.5.3.11.3 Note 2: the ‘EIRENE short number’ is a GSM-R only function. It is not used if the Radio Network type is FRMCS or is FRMCS+GSM-R while FRMCS is the only radio system installed on-board.

3.5.3.12 Intentionally deleted.

3.5.3.13 An order to establish a communication session with the RBC may contain a special value for the RBC identity indicating that the on-board shall contact the last known RBC (i.e., using the stored RBC contact information, if any); the phone number indicated in the order shall be ignored by the on-board equipment.

3.5.3.13.1 If there is no RBC contact information stored on-board, the order to establish a communication session with the last known RBC shall be ignored.

3.5.3.14 Note: If a short number is used (considering trackside call routing), that number can be programmed into the balise instead of the normal phone number.

3.5.3.15 An order to establish a communication session with the RBC may contain a special value for the RBC phone number indicating that the on-board shall use the on-board short number.

3.5.3.15.1 Intentionally deleted.

### **3.5.4 Maintaining a communication session**

3.5.4.1 When a communication session is established, in case of a loss of the safe radio connection, i.e., if the disconnection has not been ordered (see 3.5.5.1), the involved entities shall consider the communication session still established for a defined time. The defined time shall start as soon as EURORADIO has indicated the loss of the safe radio connection.

3.5.4.2 When EURORADIO indicates the loss of the safe radio connection, the ERTMS/ETCS on-board equipment shall immediately try to set-up a new safe radio connection using the radio system through which the safe radio connection was successfully set up beforehand (see SUBSET-037-1 for details).

3.5.4.2.1 If the safe radio connection is not re-established after the defined time (as defined in A.3.1), both, on-board equipment and trackside, shall consider the session as terminated.

3.5.4.3 The attempts shall be repeated, until at least one of the following conditions is met: • The safe radio connection is set-up.

   - The session is considered as terminated.

<!-- end of page 25 -->

   - The train passes the location indicated in the RIU order “Terminate the communication session”

3.5.4.3.1 Note: if the session is considered as terminated due to 3.5.4.2.1, the attempts will be resumed immediately according to 3.5.3.4 f).

3.5.4.4 Exception to 3.5.4.2 and 3.5.4.3: the on-board equipment shall not try to set up a new safe radio connection and shall stop any ongoing attempts if the engine, taking into account its front and rear ends, overlaps an announced radio hole (see 3.12.1.3). The on-board equipment shall try to set it up again when the  engine rear/front end reaches the end of the radio hole, depending on whether the train orientation is the same as/opposite to the active cab.

3.5.4.5 In case a message has to be sent during the loss of the safe radio connection, this message shall be considered as sent.

3.5.4.6 When the trackside receives a session established report inside an existing communication session it shall acknowledge the establishment of the communication session to the on-board.

3.5.4.7 When the on-board receives a system version message inside an existing communication session it shall send a session established report.

3.5.4.7.1 Note: An RBC could repeat the system version message if it assumes that the message was not received by the on-board.

### **3.5.5 Terminating a communication session**

3.5.5.1 The termination of a communication session shall be initiated only by the on-board and in the following cases:

   - a) If an order is received from trackside (RBC, RIU or balise groups) (see section 3.5.2 concerning the content of the order).

   - b) If a condition requiring the termination of the communication session is fulfilled without any explicit trackside order. The situations in which such condition is met are detailed in other sections of this specification.

   - c) Intentionally deleted.

   - d) Intentionally deleted.

   - e) Intentionally deleted.

   - f) Intentionally deleted.

3.5.5.2 In case a session is established, the on-board equipment shall terminate the communication session according to the following steps:

   - a) The on-board equipment shall send a Termination of communication session message.

<!-- end of page 26 -->

- b) As soon as this information is received, the trackside shall consider the communication session terminated and send an acknowledgement to the on-board.

- c) When the acknowledgement is received the on-board shall consider the communication session terminated and request the release of the safe radio connection with trackside.

<!-- Start of picture text -->
On-Board Trackside<br>Termination of<br>Communication<br>communication session<br>session terminated for<br>trackside<br>Communication<br>Acknowledgement of<br>session<br>termination of<br>terminated for<br>communication session<br>on-board<br>Release of the safe connection<br>According to EURORADIO specifications<br><!-- End of picture text -->

**Figure 5: Termination of a communication session**

3.5.5.3 No further message shall be sent by the on-board after the message Termination of communication session.

3.5.5.3.1 Exception: In case a communication session is established and no acknowledgement is received within a fixed waiting time (see Appendix A.3.1) after sending the “Termination of communication session” message, the message shall be repeated with the fixed waiting time after each repetition.

3.5.5.3.2 After a defined number of repetitions (see Appendix A.3.1), and if no acknowledgment is received within the fixed waiting time from the time of the last sending of “Termination of communication session”, the ERTMS/ETCS onboard equipment shall consider the communication session terminated.

3.5.5.4 No further message shall be sent by the trackside after the message Acknowledgement of the termination of communication session.

3.5.5.5 Note: The information Termination of Communication Session and corresponding Acknowledgement are the same in every system version.

3.5.5.6 Messages from the RBC received onboard after the message “Termination of communication session” has been sent shall be ignored with the exception of the Acknowledgement of the termination of communication session.

3.5.5.7 Intentionally deleted.

<!-- end of page 27 -->

### **3.5.6 Managing the Radio Networks**

3.5.6.1 ERTMS/ETCS on-board equipment shall order the registration of its connected GSM-R Mobile Terminal(s) to a GSM-R Radio Network:

   - a) At power-up

   - b) Following driver entry of a new GSM-R Radio Network identity

   - c) If ordered from the trackside

3.5.6.1.1 In order to manage the transitions between different Radio Networks, the trackside can transmit Radio Network transition orders, which include:

   - a) The Radio Network type (FRMCS, FRMCS+GSM-R, or GSM-R)

   - b) Only if the Radio Network type is FRMCS+GSM-R or GSM-R, the GSM-R Radio Network identity

3.5.6.1.2 Note 1: Unlike the GSM-R Radio Networks, the FRMCS Radio Network can be seen by ETCS as one single entity without the need for ETCS to order the registration of its connected FRMCS on-board equipment to the FRMCS Radio Network or to manage the transitions between networks, which permits e.g. to not interrupt a radio connection on passing an international border where FRMCS is installed on both sides of the border.

3.5.6.1.3 Note 2: As soon as it is powered-up, the FRMCS on-board equipment reports continuously to the ETCS on-board equipment whether it is registered or not to the FRMCS radio network, i.e. that it is ready or not to establish a radio connection with an RBC.

3.5.6.2 When powered-off, ERTMS/ETCS on-board equipment shall memorize the last received Radio Network type and GSM-R Radio Network identity if any (from trackside or from driver) and shall use it (them) when powered-up again.

3.5.6.3 If no GSM-R Radio Network identity received from trackside or from driver could have been memorized by ERTMS/ETCS on-board equipment (e.g. after a System Failure or at very first power-up), this latter shall nevertheless order the registration of its Mobile Terminal(s) to a default GSM-R Radio Network.

3.5.6.3.1 Note 1: the source used to retrieve the default GSM-R Radio Network identity (on-board equipment permanent storage, Mobile Terminal itself, or other external source) is implementation dependent.

3.5.6.3.2 Note 2: if ERTMS/ETCS on-board equipment is powered-up in an area not covered by the memorized or default GSM-R Radio Network, attempts to register to this Radio Network will be repeated unconditionally by the Mobile Terminal(s) until either an attempt is successful or a new GSM-R Radio Network identity is received from trackside or from driver, preventing Mobile Terminal(s) from registering to any unwanted GSM-R Radio Network.

<!-- end of page 28 -->

3.5.6.4 If no Radio Network type received from trackside or from driver could have been memorized by ERTMS/ETCS on-board equipment (e.g. after a System Failure or at very first power-up), this latter shall use a default value configured on-board.

3.5.6.5 On reception of the Radio Network transition order, ERTMS/ETCS on-board equipment shall store the Radio Network type and, if the Radio Network type included in the order is FRMCS+GSM-R or GSM-R, it shall immediately order the Radio Network registration of each GSM-R Mobile Terminal that fulfils the following conditions:

   - a) it is not yet registered to the ordered GSM-R Radio Network, AND

   - b) it is not used for an established communication session, AND

   - c) no safe radio connection is being set-up

3.5.6.6 If a GSM-R Mobile Terminal is not currently registered to the GSM-R Radio Network ordered by trackside and if one of the conditions b) or c) is not fulfilled, ERTMS/ETCS on-board equipment shall initiate the GSM-R Radio Network registration once communication session is terminated and safe radio connection is released.

3.5.6.7 Any order to establish a communication session with an RBC received from trackside shall not lead to any request to set-up a safe radio connection by ERTMS/ETCS onboard equipment if:

   - a) the stored Radio Network type is FRMCS or is FRMCS+GSM-R while FRMCS is the only radio system installed on-board and the FRMCS on-board is not registered to the FRMCS Radio Network, OR

   - b) the stored Radio Network type is FRMCS+GSM-R while both radio systems are installed on-board, and, unless the driver has elected to perform the mission with only one radio system, either the FRMCS on-board is not registered to the FRMCS Radio Network or no GSM-R Mobile Terminal is duly registered to a GSM-R Radio Network, OR

   - c) the stored Radio Network type is FRMCS+GSM-R while both radio systems are installed on-board, and, while the driver has elected to perform the mission with only one radio system, the concerned on-board radio system is no longer registered to the Radio Network, OR

   - d) the stored Radio Network type is GSM-R or is FRMCS+GSM-R while GSM-R is the only radio system installed on-board and no GSM-R Mobile Terminal is duly registered to a GSM-R Radio Network.

3.5.6.8 Any order to establish a communication session with an RIU received from trackside shall not lead to any request to set-up a safe radio connection by ERTMS/ETCS onboard equipment if no GSM-R Mobile Terminal is duly registered to a GSM-R Radio Network.

<!-- end of page 29 -->

### **3.5.7 Safe Radio Connection Indication**

3.5.7.1 The ERTMS/ETCS on-board equipment shall inform the driver about the status of the safe radio connection. To that purpose, the following indication statuses of the safe radio connection are defined: “No Connection”, “Connection Lost/Set-Up failed”, “Connection Up”.

3.5.7.2 In addition, the ERTMS/ETCS on-board equipment shall use a “connection status” timer (see Appendix A.3.1), in order to manage properly the transitions to the indication status “Connection Lost/Set-Up failed”.

3.5.7.2.1 Note: The purpose of the “connection status” timer is to avoid distracting the driver for any short disturbance of the safe radio connection.

3.5.7.3 The ERTMS/ETCS on-board equipment shall start the “connection status” timer as soon as the first request to set-up a safe radio connection with the relevant RBC/RIU is sent: a) regarding the session establishment, see items b), c), d), e) in 3.5.3.4.

   - b) regarding maintaining a communication session, see 3.5.4.2 and 3.5.4.4

3.5.7.4 If the “connection status” timer is ongoing, it shall be stopped if the requests to set-up a safe radio connection are stopped with the relevant RBC/RIU.

3.5.7.5 The ERTMS/ETCS on-board equipment shall execute the transitions between the different indication statuses of the safe radio connection with the relevant RBC/RIU as described in Table 1 according to the conditions in Table 2 (see section 4.6.1 for details about the symbols).

|**No**|< 3|< 5, 6, 7|
|---|---|---|
|**Connection**|-p2-|-p1-|
|1, 2 ><br>-p2-|**Connection**<br>**Lost /**<br>**Set-Up failed**|<2<br>-p2-|
|4 ><br>-p1-|4 ><br>-p1-|**Connection**<br>**Up**|

**Table 1: Transitions between the indication statuses of the safe radio connection**

<!-- end of page 30 -->

|**Condition**<br>**Id**|**Content of the conditions**|
|---|---|
|[1]|(a Start of mission procedure is ongoing) AND (the final attempt to set-up the safe<br>radio connection failed)|
|[2]|(the “connection status” timer expires)|
|[3]|(no Start of mission procedure is ongoing) AND (the requests to set-up a safe radio<br>connection are stopped with the relevant RBC/RIU for reason other than the<br>successful set-up)|
|[4]|(the safe radio connection is set-up)|
|[5]|(the safe radio connection is released)|
|[6]|(the safe radio connection is lost) AND (the requests to set-up a safe radio connection<br>are stopped with the relevant RBC/RIU for reason other than the successful set-up)|
|[7]|(the safe radio connection is lost) AND (the engine, taking into account its front and<br>rear ends, overlaps an announced radio hole)|

#### **Table 2: Transition conditions for the indication statuses of the safe radio connection**

3.5.7.6 For the case of an RBC/RBC transition, the safe radio connection indicated to the driver shall switch from the indication status of the safe radio connection with the Handing over RBC to the one with the Accepting RBC as soon as one of the following conditions is met:

   - a) the ERTMS/ETCS on-board equipment sends a position report directly to the Accepting RBC with its maximum safe front end having passed the border, see 3.15.1.3.5 (i.e. the Accepting RBC becomes the supervising RBC),

   - b) the safe radio connection is released with the Handing over RBC and the minimum safe rear end of the train has passed the border.

3.5.7.6.1 Note: During an RBC/RBC handover procedure, an indication status transition table and a connection status timer might have to be managed at the same time, for each RBC.

3.5.7.7 For the case of safe radio connection with RIU’s, the safe radio connection indicated to the driver shall be the one related to the current infill area.
