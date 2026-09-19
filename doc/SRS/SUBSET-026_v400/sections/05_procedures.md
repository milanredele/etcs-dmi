# **ERTMS/ETCS**

**System Requirements Specification Chapter 5 Procedures**

REF  : SUBSET-026-5 ISSUE :

4.0.0 DATE: 05/07/2023

<!-- end of page 1 -->

# **5.1 Modification History**

|Issue Number|Section Number<br>Modification / Description|Author / Editor|
|---|---|---|
|Date|||
|0.0.1|Update of Class P document (version 1.1.1) on basis<br>of Class 1 proposals|Kast, Hans|
|0.1.0<br>27.7.99|Update according to decisions of review July 22/23<br>(Stockholm)|Kast, Hans|
|1.0.0<br>29.7.99|Finalisation meeting in Stuttgart, 990729.|HE|
|1.2.0<br>990730|Version number updated, Release version|HE|
|1.2.1<br>991209|Updated according to proposals and comments from<br>the ECSA/UNISIG database classified as “general”|Kast, Hans|
|1.3.0<br>991221|Update according to decision of review meeting<br>15<sup>th</sup>/16<sup>th</sup>Dec. (Stockholm)|HK|
|2.0.0<br>991222|Release version|HK|
|2.0.1<br>000919|Debugging decisions (up to ...... ) included|HK|
|2.1.0<br>001017|Update according to decisions of review on 10/11 Oct<br>in Stuttgart|HK|
|2.2.0|Version number<br>UNISIG release|SAB|
|2.2.2<br>020201|Refer to document: SUBSET-026 Corrected<br>Paragraphs, Issue 2.2.2|HK|
|2.2.4 SG checked<br>28/05/04|Including all CLRs agreed with the EEIG (see “List of<br>CLRs agreed with EEIG for SRS v2.2.4” dated<br>28/05/04)<br>Affected clauses see change marks|H. Kast|
|2.2.5<br>21/01/05|Incorporation of solution proposal for CLR 007 with<br>EEIG users group comments<br>Corrections according to erratum list agreed in SG<br>meeting 170105|Hougardy A|
|2.2.6<br>31/01/05|Including all current CR decisions (CR status “EEIG<br>pending”)|H. Kast|
|2.2.7<br>22/07/05|Including all current CR decisions by the UNISIG SG<br>22/07/05 CR 126 added|H. Kast|
|2.2.8|Including all new CR decisions made since SRS|H. Kast|
|06/12/05|version 2.2.7 (i.e., since July ’05)||

<!-- end of page 2 -->

|2.2.9<br>24/02/06|Including all CRs that are classified as “IN” as per<br>SUBSET-108 version 1.0.0<br>Removal of all CRs that are not classified as “IN” as<br>per SUBSET-108 version 1.0.0, with the exception of<br>CRs 63,98,120,158,538|H. Kast|
|---|---|---|
|2.3.0<br>24/02/06|Release version|HK|
|2.3.1<br>15/06/06|Including SG CR decision made since SRS 2.2.8,<br>correct errors in 2.2.8 detected when creating SRS<br>2.3.0|H. Kast|
|2.3.2<br>17/03/08|Including all CRs that are classified as “IN” as per<br>SUBSET-108 version 1.2.0 and all CRs that are in<br>state “Analysis completed” according to ERA CCM|A. Hougardy|
|2.9.1<br>06/10/08|Including all enhancement CR’s retained for 3.0.0<br>baseline and all other error CR’s that are in state<br>“Analysis completed” according to ERA CCM<br>For editorial reasons, the following CR’s are also<br>included: CR656, CR804, CR821|A. Hougardy|
|3.0.0<br>23/12/08|Release version|A. Hougardy|
|3.0.1<br>22/12/09|Including the results of the editorial review of the SRS<br>3.0.0 and the other error CR’s that are in state<br>“Analysis completed” according to ERA CCM|A. Hougardy|
|3.1.0<br>22/02/10|Release version|A. Hougardy|
|3.1.1<br>08/11/10|Including all CR’s that are in state “Analysis<br>completed” according to ERA CCM, plus CR 731? 972<br>and 1000.|A. Hougardy|
|3.2.0<br>22/12/10|Release version|A. Hougardy|
|3.2.1<br>13/12/11|Including all CR’s that are in state “Analysis<br>completed” according to ERA CCM|A. Hougardy|
|3.3.0<br>07/03/12|Baseline 3 release version|A. Hougardy|
|3.3.1<br>04/04/14|CR’s 1109, 1124, 1185|O. Gemine|
|3.3.2<br>23/04/14|Baseline 3 1<sup>st</sup>maintenance pre-release version|O. Gemine|

<!-- end of page 3 -->

|3.3.3<br>06/05/14|No change<br>Baseline 3 1<sup>st</sup>maintenance 2<sup>nd</sup>pre-release version|O. Gemine|
|---|---|---|
|3.4.0<br>12/05/14|Baseline 3 1<sup>st</sup>maintenance release version|O. Gemine|
|3.4.1<br>23/06/15|CR’s 852, 1122, 1129, 1163, 1221|O. Gemine|
|3.4.2<br>17/11/15|CR’s 1084, 1087, 1128, 1163 (update), 1184, 1265,<br>1266|O. Gemine|
|3.4.3<br>16/12/15|1128 removed, 1283 plus update due to overall CR<br>consolation phase|O. Gemine|
|3.5.0<br>18/12/15|Baseline 3 2<sup>nd</sup>release version as recommended to EC<br>(see ERA-REC-123-2015/REC)|O. Gemine|
|3.5.1<br>28/04/16|No change|O. Gemine|
|3.6.0<br>13/05/16|Baseline 3 2<sup>nd</sup>release version|A. Hougardy|
|3.6.1<br>29/05/17|CR’s 940, 1166, 1264, 1288|O. Gemine|
|3.6.2<br>31/05/18|CR’s 940, 1306|O. Gemine|
|3.6.3<br>21/02/20|CR’s 1128, 1267, 1274, 1311, 1313, 1324, 1341,<br>1349, 1353|O. Gemine<br>A. Hougardy|
|3.6.4<br>22/06/20|CR 1274 implementation corrected|O. Gemine<br>A. Hougardy|
|3.6.5<br>22/12/21|CR’s 1021, 1238, 1358, 1370, 1376, 1377, 1387|O. Gemine<br>A. Hougardy|
|3.6.6<br>29/08/22|CR’s 940 (updated), 1342, 1350, 1367, 1408, 1413|O. Gemine<br>A. Hougardy|
|3.9.1<br>24/11/22|CR’s 988, 1307<br>Outcome of B4R1 1<sup>st</sup>consolidation phase|O. Gemine<br>A. Hougardy|
|3.9.2|CR 1370|O. Gemine|
|21/02/23|Outcome of B4R1 2<sup>nd</sup>consolidation phase|A. Hougardy|
|3.9.3|CR’s 1359, 1427|O. Gemine|
|31/05/23|Outcome of B4R1 3<sup>rd</sup>consolidation phase|A. Hougardy|

<!-- end of page 4 -->

|3.9.4<br>30/06/23|CR 1342 (updated)<br>Outcome of B4R1 4<sup>th</sup>consolidation phase|O. Gemine<br>A. Hougardy|
|---|---|---|
|4.0.0|Baseline 4 1<sup>st</sup>release version|O. Gemine|
|05/07/23||A. Hougardy|

<!-- end of page 5 -->

|**5.2**|**Table of Contents**|
|---|---|
|5.1<br>M|odification History ........................................................................................................... 2|
|5.2<br>T|able of Contents .............................................................................................................. 6|
|5.3<br>In|troduction ..................................................................................................................... 10|
||Scope and Purpose.................................................................................................. 10|
||Definitions ................................................................................................................ 10|
|5.4<br>Pr|ocedure Start of mission .............................................................................................. 12|
||Introduction .............................................................................................................. 12|
||Status of data stored in the ERTMS/ETCS on-board equipment .............................. 12|
||Table of requirements for “Start of Mission” procedure ............................................. 12|
||Flowchart ................................................................................................................. 24|
||Degraded Situations................................................................................................. 26|
||Entry to Mode Considered as a Mission ................................................................... 27|
|5.5<br>Pr|ocedure End of Mission ............................................................................................... 28|
||Introduction .............................................................................................................. 28|
||Entry to Mode Considered as an End of Mission: ..................................................... 28|
||End of Mission Procedure ........................................................................................ 28|
||Degraded Situation .................................................................................................. 29|
|5.6<br>S|hunting Initiated by Driver ............................................................................................. 30|
||Introduction .............................................................................................................. 30|
||Table of requirements for “Shunting Initiated by Driver” procedure ........................... 30|
||Flowchart ................................................................................................................. 31|
||Degraded Situation .................................................................................................. 32|
|5.7<br>E|ntry in Shunting with Order from Trackside ................................................................... 34|
||General Requirements ............................................................................................. 34|
||Shunting is requested for the current location (from modes different from Stand By and|
|Post T|rip) ............................................................................................................................... 34|
||Shunting is requested for a further location .............................................................. 34|
||Shunting from Stand By or Post Trip mode .............................................................. 35|
||Flowchart ................................................................................................................. 36|
|5.8<br>Pr|ocedure Override ......................................................................................................... 37|
||Introduction .............................................................................................................. 37|
||Selection of “Override” ............................................................................................. 38|
||Once the “Override” procedure has been triggered .................................................. 38|
||End of Override procedure ....................................................................................... 39|
|5.9<br>Pr|ocedure On-Sight ........................................................................................................ 41|
||General Requirements ............................................................................................. 41|

<!-- end of page 6 -->

||On Sight is requested for current location (from modes different from Stand By and|
|---|---|
|Post T|rip) ............................................................................................................................... 41|
||On Sight is requested for a further location .............................................................. 42|
||On Sight from Unfitted or SN mode .......................................................................... 43|
||On Sight from Stand By or Post Trip mode .............................................................. 43|
||Exit of On Sight mode .............................................................................................. 44|
||Flowchart ................................................................................................................. 45|
|5.10|Level Transitions ......................................................................................................... 46|
||General requirements .............................................................................................. 46|
||Table of priority of trackside supported levels........................................................... 47|
||Specific Additional Requirements ............................................................................. 49|
||Acknowledgement of the level transition ordered by trackside ................................. 56|
|5.11|Procedure Train Trip .................................................................................................... 57|
||Introduction .............................................................................................................. 57|
||Table of requirements for “Train Trip” procedure ...................................................... 57|
||Flowchart ................................................................................................................. 60|
||Degraded Situations................................................................................................. 62|
|5.12|Change of Train Orientation......................................................................................... 63|
||Introduction .............................................................................................................. 63|
||The driver uses the same engine (a mission is ongoing) .......................................... 63|
||The driver leaves the engine to go to another one ................................................... 63|
||The driver uses the same engine (a Shunting movement is ongoing) ...................... 65|
|5.13|Train Reversing ........................................................................................................... 66|
|5.14|Joining / Splitting ......................................................................................................... 67|
||Definitions ................................................................................................................ 67|
||Procedure “Splitting” ................................................................................................ 67|
||Procedure “Joining” .................................................................................................. 67|
|5.15|RBC/RBC Handover .................................................................................................... 69|
||Principles ................................................................................................................. 69|
||Procedure ................................................................................................................ 70|
||Degraded situation: Only one GSM-R communication session can be handled ....... 73|
||Other degraded Situations ....................................................................................... 74|
|5.16|Procedure passing a non protected Level Crossing ..................................................... 75|
||General Requirements ............................................................................................. 75|
||Stopping in rear of non protected LX is required ...................................................... 76|
||Stopping in rear of non protected LX is not required................................................. 76|
|5.17|Changing Train Data from sources different from the driver ......................................... 77|
||Introduction .............................................................................................................. 77|

<!-- end of page 7 -->

||Table of requirements for “Changing Train Data from sources different from the driver”|
|---|---|
|proced|ure ............................................................................................................................... 78|
||Flowchart ................................................................................................................. 80|
|5.18<br>I|ndication of Track Conditions ...................................................................................... 82|
||Introduction .............................................................................................................. 82|
||Passing a powerless section with pantograph to be lowered .................................... 82|
||Passing a powerless section with main power switch to be switched off .................. 83|
||Passing a non stopping area .................................................................................... 85|
||Passing a radio hole................................................................................................. 86|
||Passing an “air tightness” area ................................................................................. 87|
||Inhibition of a defined type of brake .......................................................................... 88|
||Advising a tunnel stopping area ............................................................................... 89|
||Sounding the horn .................................................................................................... 90|
||Changing the traction system ................................................................................... 91|
|5.19<br>|Procedure Limited Supervision .................................................................................... 93|
||General Requirements ............................................................................................. 93|
||Limited Supervision is requested for current location (from modes different from Stand|
|By and|Post Trip) ................................................................................................................... 93|
||Limited Supervision is requested for a further location ............................................. 94|
||Limited Supervision from Unfitted or SN mode ......................................................... 95|
||Limited Supervision from Stand By or Post Trip mode ............................................. 95|
||Exit of Limited Supervision mode ............................................................................. 96|
||Flowchart ................................................................................................................. 97|
|5.20<br>|Generation of Track Conditions related information to an ERTMS/ETCS external|
|function|98|
||Introduction .............................................................................................................. 98|
||Passing a powerless section with pantograph to be lowered .................................... 98|
||Passing a powerless section with main power switch to be switched off .................. 99|
||Passing an “air tightness” area ............................................................................... 101|
||Inhibition of a defined type of brake ........................................................................ 102|
||Changing the traction system ................................................................................. 103|
||Changing the allowed current consumption ............................................................ 104|
||Station platform ...................................................................................................... 105|
|5.21<br>|Procedure Supervised Manoeuvre............................................................................. 108|
||Introduction ............................................................................................................ 108|
||Table of requirements for “Supervised Manoeuvre” procedure ............................... 108|
||Flowchart ............................................................................................................... 109|
||Degraded Situation ................................................................................................ 110|

<!-- end of page 8 -->

|5.22|Procedure Inhibition of balise transmission alarm reaction ........................................ 111|
|---|---|
||Introduction ............................................................................................................ 111|
||Manual triggering of the procedure ......................................................................... 111|
||Automatic triggering of the procedure .................................................................... 112|
||Once the “Inhibition” procedure has been triggered................................................ 112|
||End of “Inhibition” procedure .................................................................................. 112|

<!-- end of page 9 -->

# **5.3 Introduction**

## **Scope and Purpose**

5.3.1.1 This document defines the procedures that are necessary for interoperability within the scope of ERTMS/ETCS.

5.3.1.2 Each procedure is defined by a set of mandatory requirements and, where convenient, is illustrated by a flowchart.

5.3.1.3 In case the condition(s) in chapter 4 triggering a mode transition is(are) fulfilled, this transition shall be executed even if not shown in the chapter 5 procedures.

5.3.1.3.1 Note: Such a mode transition could lead to exiting a procedure immediately (e. g. cut off power of on-board equipment, isolation of on-board equipment).

5.3.1.4 National operation rules (outside of ERTMS/ETCS) are also excluded, but may be applied by the railways in addition to the procedures as long as interoperability is retained.

## **Definitions**

5.3.2.1 Procedures A procedure defines the required reaction of the ERTMS/ETCS entities (subsystems and components) to either information exchanged between ERTMS/ETCS entities or events (triggered by external entities or internal events). The procedures focus on the required change in status and mode of the described ERTMS/ETCS entities.

5.3.2.2 Entities The procedures define the required system behaviour on a context level, i. e. the entities that are used to define the procedures are for example: the on-board equipment, the trackside equipment (RBC/Balise), the driver.

5.3.2.3 States States are situations of an ETCS subsystem with a specific set of available functions and a specific set of events that may start or terminate the state. A state remains active as long as the conditions to trigger the transition to a succeeding state are not completely satisfied. Note 1: one mode of operation may include several states for the on-board equipment. Note 2: A new state is only created, if the behaviour of the system differs from another one. Possession of information (e. g. location information) or not does not force branching in states.

5.3.2.4 Transitions Transitions define the rules for passing from one state to another. A transition is triggered by a set of conditions which has to be fulfilled in a defined order or at the same time.

<!-- end of page 10 -->

When a transition refers to a driver’s selection, it means that the conditions to enable the corresponding button on the DMI were fulfilled.

<!-- end of page 11 -->

# **5.4 Procedure Start of mission**

## **Introduction**

5.4.1.1 The driver may have to start a mission: a) Once the train is awake, OR b) Once shunting movements are finished, OR c) Once a mission is ended, OR d) Once a desk is opened (e.g. when a slave engine becomes a leading engine).

5.4.1.2 The common point of all these situations is that the ERTMS/ETCS on-board is in StandBy mode, but the Start of Mission will be different, since some data may be already stored on-board, depending on the previous situation.

5.4.1.3 Once the ERTMS/ETCS on-board equipment is in Stand-By mode, the start of mission is not the only possibility, the engine may become remote controlled (i.e. the on-board switches to Sleeping mode).

5.4.1.4 If, upon desk opening, there is an already established communication session for which no termination is ongoing, the ERTMS/ETCS on-board equipment shall first terminate this communication session.

## **Status of data stored in the ERTMS/ETCS on-board equipment**

5.4.2.1 At the beginning of the Start of Mission procedure, the data required may be in one of three states: a) “valid” (the stored value is known to be correct) b) “Invalid” (the stored value may be wrong) c) “Unknown” (no stored value available)

5.4.2.2 This refers to the following data: Driver ID, ERTMS/ETCS level, RBC contact information, Train Data, Train Running Number, Train Position (see 3.6.1.3).

5.4.2.3 Note 1: The status of data in relation to the previous and the actual mode is described in chapter 4, section "What happens to stored information when entering a mode".

5.4.2.4 Note 2: The change of status of data in course of the procedure is shown in the table in section 5.4.3.3.

## **Table of requirements for “Start of Mission” procedure**

5.4.3.1 The ID numbers in the table are used for the representation of the procedure in form of a flow chart in section 5.4.4.

<!-- end of page 12 -->

### **5.4.3.2 Procedure**

|**ID #**|**Requirements**|
|---|---|
|**S0**|The Start of Mission procedure shall be engaged when the ERTMS/ETCS on-board<br>equipment is in Stand-By mode with a desk open and no communication session is<br>established or is being established.|
|**S1**|Depending on the status of the Driver-ID, the ERTMS/ETCS on-board equipment shall<br>request the driver to enter the Driver-ID (if the Driver-ID is unknown) or shall request the<br>driver to revalidate or re-enter the Driver-ID (if the Driver-ID is invalid).<br>The ERTMS/ETCS on-board equipment shall offer the driver the possibility to enter/re-<br>validate (depending on the status) the Train running number.<br>The ERTMS/ETCS on-board equipment shall also offer the driver the possibility to<br>set/remove a Virtual Balise Cover.<br>Once the Driver-ID is entered or revalidated**(E1)**(possibly further to the Train running<br>number entry/revalidation and/or to Virtual Balise Cover setting/removal), the process<br>shall go to**D2**|
|**D2**|If both the stored position and the stored level are valid, the process shall go to**D3**<br>If the stored position or the stored level is “invalid” or “unknown”, the process shall go to<br>**S2**|
|**D3**|If the stored level is 2, the process shall go to**D7**<br>If the stored level is 0,1 or NTC, the process shall go to**S10**|
|**D7**|Depending on the stored Radio Network type, on the radio systems(s) installed on-board<br>and if one of the following conditions is fulfilled:<br>•<br>The Radio Network type is FRMCS or is FRMCS+GSM-R while FRMCS is<br>the only radio system installed on-board and the FRMCS on-board is<br>registered to the FRMCS Radio Network, OR<br>•<br>The Radio Network type is FRMCS+GSM-R while both radio systems are<br>installed on-board, and both the FRMCS on-board is registered to the<br>FRMCS Radio Network and at least one GSM-R Mobile Terminal is<br>registered to a GSM-R Radio Network, OR<br>•<br>The Radio Network type is GSM-R or is FRMCS+GSM-R while GSM-R is<br>the only radio system installed on-board and at least one Mobile Terminal is<br>registered to a GSM-R Radio Network<br>The process shall go to**A31.**|
||Otherwise, it shall go to**S4**|

<!-- end of page 13 -->

|**ID #**|**Requirements**|
|---|---|
|**S2**|If the status of the Level data is "unknown", the ERTMS/ETCS on-board equipment shall<br>request the driver to enter it.|
||If the status of the Level data is "invalid", the ERTMS/ETCS on-board equipment shall<br>request the driver to re-validate or re-enter the ERTMS/ETCS level.|
||If the entered / re-validated level is 2, the process shall go to**S3**|
||If the entered / re-validated level is 0, 1 or one of proposed NTC level(s) (see 3.18.4.2<br>for the levels the driver is allowed to select), the process shall go to**S10**|

<!-- end of page 14 -->

**S3** The ERTMS/ETCS on-board equipment shall offer the possibility to the driver to re-enter the Radio Network type.

If the driver selects a new Radio Network type (i.e. different from the previously stored one), the on-board equipment shall terminate the ongoing communication session (if any) and if not “unknown” the status of the RBC contact information shall be immediately set to “invalid”.

If the driver selects FRMCS or FRMCS+GSM-R while FRMCS is installed on-board and the FRMCS on-board is not registered to the FRMCS Radio Network ( **E4** ), the process shall go to **A41.**

If the Radio Network type is GSM-R or FRMCS+GSM-R while GSM-R is installed onboard, the ERTMS/ETCS on-board equipment shall also offer the possibility to the driver to re-enter the GSM-R Radio Network ID. If the driver elects to do so, the on-board equipment shall terminate the ongoing communication session, if any. As soon as the related safe connection is released, if any, the on-board equipment shall acquire an alphanumeric list of available and allowed GSM-R networks, based on a request to the GSM-R Mobile Terminal(s):

- If this list is empty ( **E3** ) the process shall go to **A29**

- If the driver selects a new GSM-R Radio Network ID from the proposed list, the registration of the GSM-R Mobile Terminal(s) to this new GSM-R Radio Network shall be ordered and if not “unknown” the status of the RBC contact information shall be immediately set to “invalid”.

If the Radio Network type is FRMCS+GSM-R while both radio systems are installed onboard, and either the FRMCS on-board is registered to the FRMCS Radio Network or at least one GSM-R Mobile Terminal is duly registered to a GSM-R Radio Network, the ERTMS/ETCS on-board equipment shall also offer the possibility to the driver to perform the mission with only one radio system. If the driver elects to do so ( **E17** ), the process shall go to **A43.**

Depending on the Radio Network type and only if any of the following sub-conditions is fulfilled,

- The Radio Network type is FRMCS or is FRMCS+GSM-R while FRMCS is the only radio system installed on-board, and the FRMCS on-board is registered to the FRMCS Radio Network, OR

- The Radio Network type is FRMCS+GSM-R while both radio systems are installed on-board, and both the FRMCS on-board is registered to the FRMCS Radio Network and at least one GSM-R Mobile Terminal is registered to a GSMR Radio Network, OR

- The Radio Network type is FRMCS+GSM-R while both radio systems are installed on-board, and the driver has elected to perform the mission with only one radio system

- The Radio Network type is GSM-R or is FRMCS+GSM-R while GSM-R is the only radio system installed on-board, and at least one Mobile Terminal is registered to a GSM-R Radio Network

<!-- end of page 15 -->

### **Requirements**

   - **ID # Requirements** the ERTMS/ETCS on-board equipment shall offer the following options to the driver for the RBC contact information:

   - • Only if the status of the RBC contact information is “invalid” or “valid”: order the ERTMS/ETCS on-board equipment to use the last stored RBC contact information

         - Only if the Radio Network type is FRMCS+GSM-R or GSM-R, and if at least one GSM-R Mobile Terminal is registered to a GSM-R Radio Network, order the ERTMS/ETCS on-board equipment to use the EIRENE short number (trackside call routing function)

- Enter the RBC contact information (if its status is "unknown"), or revalidate/reenter it (if its status is “invalid” or “valid”). If the Radio Network type is FRMCS or is FRMCS+GSM-R while FRMCS is the only radio system installed on-board, the RBC contact information shall only consist of the RBC ID. Otherwise it shall consist of the RBC ID and telephone number.

- Once the driver has selected the first or second option or once data is validated ( **E5** ), the process shall go to **A31**

- **S4** If the stored Radio Network type is FRMCS or is FRMCS+GSM-R while FRMCS is the only radio system installed on-board, the ERTMS/ETCS on-board equipment shall wait until: • the FRMCS on-board is registered to the FRMCS Radio Network ( **E61** ); in such case the process shall go to **A31** , OR

- • a sufficient time (refer to Appendix A.3.1) is elapsed since the FRMCS on-board equipment has been detected to be connected to the ETCS on-board equipment ( **E71** ); in such case the process shall go to **A42**

- If the stored Radio Network type is FRMCS+GSM-R while both radio systems are installed on-board, the ERTMS/ETCS on-board equipment shall wait until:

      - both the FRMCS on-board is registered to the FRMCS Radio Network and at least one GSM-R Mobile Terminal is registered to a GSM-R Radio Network( **E62** ); in such case the process shall go to **A31** , OR

      - • a sufficient time (refer to Appendix A.3.1) is elapsed since it has sent the latest GSM-R Radio Network registration order to a GSM-R Mobile Terminal ( **E72** ); in such case the process shall go to **A42**

      - If the stored Radio Network type is GSM-R or is FRMCS+GSM-R while GSM-R is the only radio system installed on-board, the ERTMS/ETCS on-board equipment shall wait until:

         - at least one GSM-R Mobile Terminal is registered to a GSM-R Radio Network ( **E6** ); in such case the process shall go to **A31** , OR

         - a sufficient time (refer to Appendix A.3.1) is elapsed since it has sent the latest GSM-R Radio Network registration order to a GSM-R Mobile Terminal ( **E7** ); in such case the process shall go to **A42**

<!-- end of page 16 -->

|**ID #**|**Requirements**|
|---|---|
|**A29**|The ERTMS/ETCS on-board equipment shall inform the driver that the GSM-R network<br>registration has failed<br>The process shall then go to**D8**|
|**A41**|The ERTMS/ETCS on-board equipment shall inform the driver that the FRMCS network<br>registration has failed<br>The process shall then go to**D8**|
|**A43**|If not already displayed through**A29**or**A41**, the ERTMS/ETCS on-board equipment<br>shall inform the driver that either the FRMCS network registration or the GSM-R network<br>registration has failed<br>The process shall then go to**S5**|
|**D8**|If the stored Radio Network type is FRMCS+GSM-R while both radio systems are<br>installed on-board, the process shall go back to**S3**<br>Otherwise, the process shall go to**S10**(the driver has to unlock the situation to continue<br>e.g. selection of new level)|
|**A42**|The ERTMS/ETCS on-board equipment shall inform the driver about the failed Radio<br>Network registration(s) as follows:<br>•<br>If the stored Radio Network type is FRMCS or is FRMCS+GSM-R while<br>FRMCS is the only radio system installed on-board, that the FRMCS network<br>registration has failed<br>•<br>If the stored Radio Network type is FRMCS+GSM-R while both radio systems<br>are installed on-board, that the FRMCS network registration and/or GSM-R<br>network registration have/has failed<br>•<br>If the stored Radio Network type is GSM-R or is FRMCS+GSM-R while GSM-R<br>is the only radio system installed on-board, that the GSM-R network<br>registration has failed|
||The process shall then go to**D9**|
|**D9**|If the stored Radio Network type is FRMCS+GSM-R while both radio systems are<br>installed on-board, and either the FRMCS on-board is registered to the FRMCS Radio<br>Network or at least one GSM-R Mobile Terminal is duly registered to a GSM-R Radio<br>Network, the process shall go to**S5**<br>Otherwise, the process shall go to**S10**(the driver has to unlock the situation to continue<br>e.g. selection of new level)|

<!-- end of page 17 -->

|**ID #**|**Requirements**|
|---|---|
|**S5**|The ERTMS/ETCS on-board equipment shall request the driver to choose whether to<br>perform the mission with only one radio system:|
||•<br>If the driver elects to perform the mission with only one radio system and the<br>RBC contact information is valid (**E8**), the process shall go to**A31**<br>•<br>If the driver elects to perform the mission with only one radio system and the<br>RBC contact information is not valid (**E9**), the process shall go to**S3**<br>If the driver elects to not perform the mission with only one radio system (**E15**), the<br>process shall go to**S10**(the driver has to unlock the situation to continue e.g. selection<br>of new level).|
|**S10**|The ERTMS/ETCS on-board equipment shall offer the possibility to the driver to select<br>SM (only in level 2, if the train position is valid and is referred to an LRBG, and if the<br>“safe consist length” information is available), SH, NL, or to select Train Data Entry.<br>•<br>If the driver selects SM (**E34**), the process shall continue in the same way as the<br>procedure “Supervised Manoeuvre”.<br>If the RBC rejects the request for Supervised Manoeuvre (**E35**), the process shall<br>go back to**S10**.<br>•<br>If the driver selects SH (**E12**), the process shall continue in the same way as the<br>procedure “Shunting initiated by the driver”.<br>If, in level 2, the RBC rejects the request for Shunting (**E13**), the process shall go<br>back to**S10**.<br>•<br>If the driver selects NL (**E10**) then the ERTMS/ETCS on-board equipment shall<br>immediately switch to Non Leading mode (refer to SRS chapter 4, transition between<br>modes: transition [46]). The mission starts in NL mode (if level is 2, the<br>ERTMS/ETCS on-board equipment also reports the change of mode to the RBC).<br>•<br>If the driver selects Train Data Entry (**E11**), the process shall go to**S12**<br>•<br>Following E10, E12, if the position is still invalid, the ERTMS/ETCS on-board shall<br>delete the train position data (new status: “unknown”)|
|**S12**|The ERTMS/ETCS on-board equipment shall request the driver to enter/revalidate the<br>Train Data that requires driver validation.<br>Once Train Data is stored and validated (**E16**), the process shall go to**D12**|
|**D12**|If Train running number is valid, the process shall go to**D10**<br>If Train running number is “unknown” or “invalid”, the process shall go to**S13**|
|**S13**|If the status of the Train running number is "unknown" or “invalid”, the ERTMS/ETCS<br>on-board equipment shall request the driver to enter/re-validate the Train running<br>number now.<br>Once Train running number is entered/re-validated (**E18**), the process shall go to**D10.**|
|**D10**|When the validated level is 2, the process shall go to**D11**<br>When the validated level is 0,1 or NTC, the process shall go to**S20**|

<!-- end of page 18 -->

|**ID #**|**Requirements**|
|---|---|
|**D11**|When the session is open, the process shall go to**D15**, otherwise it shall go to**S10**|
|**D15**|If the ERTMS/ETCS on-board equipment has already received the Train Data<br>acknowledgment from the RBC, the process shall go to**S20**, otherwise it shall go to<br>**S11**.<br>Note: the sending of Train Data to the RBC occurring at**E16**(as per clause 3.18.3.4),<br>the process goes systematically to**S11**in case a valid Train running number is already<br>stored on-board when Train Data is validated.|
|**S11**|The ERTMS/ETCS on-board equipment shall wait for the Train Data acknowledgement<br>from the RBC.<br>When the RBC acknowledges Train Data (**E14**), then the ERTMS/ETCS onboard<br>equipment shall go to the step**S20**.|
|**S20**|The ERTMS/ETCS on-board equipment shall offer the possibility to the driver to select<br>“Start”<br>a) When the validated level is NTC and the driver selects "start" (**E20**), the process<br>shall go to**S22**<br>b) When the validated level is 0 and the driver selects "start" (**E21**), the process shall<br>go to**S23**<br>c) When the validated level is 1 and the driver selects "start" (**E22**), the process shall<br>go to**S24**<br>d) When the validated level is 2 and the driver selects "start" (**E24**), the process shall<br>go to**S21**|
|**S21**|The ERTMS/ETCS on-board equipment shall send an MA request to the RBC and wait.<br>If an SR authorisation is received from RBC (**E26**), the process shall go to**S24**<br>If an MA allowing OS/LS/SH is received from RBC (**E27**), the process shall go to**S25**<br>If an MA allowing FS is received from RBC (**E29**), the mission starts in Full Supervision<br>mode (refer to SRS chapter 4, transitions between modes: transition from SB to FS)|
|**S22**|The ERTMS/ETCS on-board equipment shall request an acknowledgement from the<br>driver for running under supervision of the selected National System. When the driver<br>acknowledges (**E30**) , the mission starts in SN mode  (refer to SRS chapter 4, transitions<br>between modes).<br>Following E30, if the position is still invalid, the ERTMS/ETCS on-board shall delete the<br>train position data (new status: “unknown”)|
|**S23**|The ERTMS/ETCS on-board equipment shall require an acknowledgement from the<br>driver for running in Unfitted mode. When the driver acknowledges (**E31**), the mission<br>starts in Unfitted mode (refer to SRS chapter 4, transitions between modes: transition<br>from SB to UN)<br>Following E31, if the position is still invalid, the ERTMS/ETCS on-board shall delete the<br>train position data (new status: “unknown”)”|

<!-- end of page 19 -->

|**ID #**|**Requirements**|
|---|---|
|**S24**|The ERTMS/ETCS on-board equipment shall require an acknowledgement from the<br>driver for running in Staff Responsible mode. When the driver acknowledges (**E32**), the<br>mission starts in SR mode (refer to SRS chapter 4, transitions between modes: transition<br>from SB to SR)<br>Following E32, if the position is still invalid, the ERTMS/ETCS on-board shall delete the<br>train position data (new status: “unknown”)”|
|**S25**|The ERTMS/ETCS on-board equipment shall require an acknowledgement from the<br>driver for running in On Sight/Limited Supervision/Shunting mode. When the driver<br>acknowledges (**E33**), the mission starts in On Sight/Limited Supervision/Shunting mode<br>(refer to SRS chapter 4, transitions between modes: transition from SB to OS, LS or SH)|
|**A31**|The ERTMS/ETCS on-board equipment shall open the session with the RBC.|
|**D31**|If the opening of the session is successful, the process shall go to**D32**<br>If the opening of the session has failed, the process shall go to**A32**|
|**A32**|The driver shall be informed when the on-board equipment fails to open a radio session.<br>Opening  of a radio session has failed if<br>•<br>No connection to the RBC can be established (see section 3.5.3.7) OR<br>•<br>The ERTMS/ETCS on-board equipment, based on the system configuration<br>reported by the RBC, decides that compatibility is not ensured and terminates the<br>communication session<br>This condition leads to**S10**(The driver has to unlock the situation to continue e.g.<br>selection of new level).|
|**D32**|If the stored position is valid and refers to an LRBG, the process shall go to**A33**<br>Otherwise, the process shall go to**A34**|
|**A33**|The “SoM position report” message, marked as referring to a “valid train position referred<br>to an LRBG”, shall be transmitted to the RBC, together with valid Train Data and/or valid<br>Train running number, if already stored on-board, and, if available while no valid Train<br>Data is stored on-board, with safe consist length information.<br>This condition leads to**S10**.|
|**A34**|If the train position data stored in the on-board equipment is of status “invalid” and refers<br>to an LRBG, the “SoM position report” message, marked as referring to an “invalid train<br>position referred to an LRBG”, shall be transmitted to the RBC.<br>Otherwise the "SoM position report" message, marked as referring to "no train position<br>referred to an LRBG” and with the LRBG identity set to "unknown", shall be transmitted<br>to the RBC.<br>In both cases valid Train Data and/or valid Train running number, if already stored on-<br>board, and, if available while no valid Train Data is stored on-board, safe consist length<br>information, shall be included in the “SoM position report” message.<br>The process shall then go to**D33**|

<!-- end of page 20 -->

|**ID #**|**Requirements**|
|---|---|
|**D33**|When the position report marked as referring to an "invalid train position referred to an<br>LRBG" is received by the RBC, this latter shall check whether it can validate this position<br>report.<br>If the position report can be validated by the RBC, the process shall go to**A35**<br>Otherwise, if the position report was marked as referring to "no train position referred to<br>an LRBG", or if the position report that was marked as referring to an "invalid train<br>position referred to an LRBG" cannot be validated by the RBC, the process shall go to<br>**D22**<br>Note: How the RBC is able to validate the position report  is a national issue, out of the<br>scope for this specification|
|**A35**|The RBC shall inform the ERTMS/ETCS onboard equipment that the reported position<br>referred to an LRBG is valid.<br>When this message is received by the ERTMS/ETCS on-board equipment, the status<br>of the position shall be set to "valid"<br>The process shall go to**S10**.|
|**D22**|If the SoM position report is marked as referring to "no train position referred to an<br>LRBG", or if the RBC is not able to confirm a SoM position report marked as referring to<br>an "invalid train position referred to an LRBG", the RBC shall nevertheless decide<br>whether it accepts the train or not.<br>If yes, the process shall go to**A23**<br>If no, the process shall go to**A38**<br>Note: How the RBC assumes responsibility for the train is a national issue, out of the<br>scope for this specification|
|**A23**|The RBC shall inform the ERTMS/ETCS on-board equipment that it accepts the train<br>although the on-board has not reported a "valid train position referred to an LRBG"<br>information.|
|**D34**|When the ERTMS/ETCS on-board equipment is informed that the train is accepted<br>without "valid train position referred to an LRBG" information:<br>•<br>If a valid train position data referred to an unlinked balise group is stored on-<br>board, the status of the train position shall remain unchanged and the process<br>shall go to**S10**<br>•<br>Otherwise the process shall go to**A24**|
|**A24**|The ERTMS/ETCS on-board equipment shall delete the train position data (new status:<br>“unknown”) and the process shall go to**S10**.|
|**A38**|The RBC shall inform the ERTMS/ETCS on-board equipment that it rejects the train|

<!-- end of page 21 -->

|**ID #**|**Requirements**|
|---|---|
|**D35**|When the ERTMS/ETCS on-board equipment is informed that the train is rejected:<br>•<br>If a valid train position data referred to an unlinked balise group is stored on-<br>board, the status of the train position shall remain unchanged and the process<br>shall go to**A40**<br>•<br>Otherwise the process shall go to**A39**|
|**A39**|The ERTMS/ETCS on-board equipment shall delete the train position data (new status:<br>“unknown”) and the process shall go to**A40**|
|**A40**|The ERTMS/ETCS on-board equipment shall terminate the session with the RBC.<br>Once the session is terminated it shall inform the driver that the train is rejected and the<br>process shall go to**S10**(the driver has to unlock the situation to continue e.g. selection<br>of new level).|
|5.4.3.2.1|The SoM procedure shall end as soon as at least one of the following conditions is<br>fulfilled:<br>•<br>Transition to any mode other than SB<br>•<br>The desk is closed|

5.4.3.2.2 When the driver closes the desk, the ERTMS/ETCS on-board equipment shall terminate the communication session with the RBC, if any.

<!-- end of page 22 -->

### 5.4.3.3 Status of On-board Variables Affected by Start of Mission Procedure

||||||||**Stat**|**e of**|**On-b**|**oard**|**Vari**|**ables**|||||||
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
|**Transition conditions**|ER<br>n|TMS/E<br>Leve<br>d|TCS<br>l<br>|RB<br>inf<br>wn|C con<br>ormat<br>d|tact<br>ion<br>|Train<br>wn|pos<br>data<br>d|ition<br>|D<br>wn|river<br>d|ID<br>|Tr<br>wn|ain D<br>d|ata<br>|Trai<br>N<br>wn|n Ru<br>umb<br>d|nning<br>er<br>|
||Un-know|Invali|Valid|Un-kno|Invali|Valid|Un- kno|Invali|Valid|Un- kno|Invali|Valid|Un- kno|Invali|Valid|Un- kno|Invali|Valid|
|Following S1 : Driver has<br>entered driver ID||||||||||~~⚫~~|||||||||
|Following S1 : Driver has re-<br>validated/ re-entered driver<br>ID|||||||||||~~⚫~~||||||||
|Following S1 : Driver has<br>entered Train running<br>number||||||||||||||||~~•~~|||
|Following S1: Driver has re-<br>validated/ re-entered Train<br>running number|||||||||||||||||~~•~~||
|Following D2: stored<br>position is “invalid” or<br>“unknown”|||~~⚫~~|||~~⚫~~|||||||||||||
|Following D2: stored level is<br>“invalid” or “unknown”||||||~~⚫~~|||||||||||||
|Following S2 : driver has<br>entered level|~~⚫~~||||||||||||||||||
|Following S2 : driver has re-<br>validated/ re-entered level||~~⚫~~|||||||||||||||||
|S3: driver has re-entered a<br>new GSM-R Radio Network<br>ID or a new Radio Network<br>type||||||~~⚫~~|||||||||||||
|Following S3 : driver has<br>entered RBC contact<br>information||||~~⚫  ~~|||||||||||||||
|Following S3: driver has re-<br>validated/re-entered RBC<br>contact information|||||~~⚫~~||||||||||||||
|Following  D31: session has<br>been successfully opened|||||~~⚫~~||||||||||||||
|Following  D31: session has<br>been successfully opened||||~~⚫~~|||||||||||||||
|A35 : RBC reports to On-<br>board : position valid||||||||~~⚫~~|||||||||||
|A24 : On-board deletes<br>stored position data (no<br>valid position data vs.<br>unlinked BG was stored on-<br>board)||||||||~~⚫~~|||||||||||
|A39 : On-board terminates<br>session, deletes stored<br>position data (no valid<br>position data vs. unlinked<br>BG was stored on-board)||||||||~~⚫~~|||||||||||
|Following E10, E12, E30,<br>E31, E32, On-board deletes<br>stored position data||||||||~~⚫~~|||||||||||

<!-- end of page 23 -->

||||||||**Stat**|**e of**|**On-bo**|**ard**|**Vari**|**ables**|||||||
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
||ERT|MS/E<br>Leve|TCS<br>l|RB<br>inf|C con<br>ormat|tact<br>ion|Trai|n pos<br>data|ition|D|river|ID|Tr|ain Da|ta|Trai<br>N|n Ru<br>umb|nning<br>er|
|**Transition conditions**|Un-known|Invalid|Valid|Un-known|Invalid|Valid|Un- known|Invalid|Valid|Un- known|Invalid|Valid|Un- known|Invalid|Valid|Un- known|Invalid|Valid|
|Following 5.4.5.3 a), f), g),<br>On-board deletes stored<br>position data||||||||~~⚫~~|||||||||||
|Following S12: Train Data<br>have been entered|||||||||||||~~⚫~~||||||
|Following S12: Driver has<br>(re-) validatedTrain Data||||||||||||||~~⚫~~|||||
|Following S13: Driver has<br>entered train running<br>number||||||||||||||||~~⚫~~|||
|Following S13: Driver has<br>re-validated/re-entered train<br>running number|||||||||||||||||~~⚫~~||
|Following S10 or S20: Driver<br>chooses to re-enter the level|||~~⚫~~|||~~⚫~~|||||||||||||

## **Flowchart**

5.4.4.1 The ID numbers in the flowchart refer to the ID numbers of the table in section 5.4.3.

<!-- end of page 24 -->

<!-- Start of picture text -->
S0<br>Mode is SB and desk open and no communication session is established or is being established Yes<br>D7 S4<br>S1 Registration(s) to the  No Wait until registration(s) is<br>The on-board requests the driver to enter/re-validate Driver-ID, offers the driver the possibility to enter/re-validate the Train running number and offers the driver the possibility to set/remove a  Radio network(s) completed (are) completed or until a sufficient time is elapsed E6/E61/E62<br>Virtual Balise Cover<br>E1 E7/E71/E72<br>2<br>D9<br>D2<br>Stored  position &  Yes D3 Yes with 1oo2 radio Miss. poss.  Onboard informs Driver A42<br>stored level Level<br> are "valid" syst<br>No 0/1/NTC No Onboard contacts RBC A31<br>S2 S5<br>NTC0/1/ Onboard requests Driver to enter/re-validate level2 E9 choose mission with only one Onboard requests Driver to radio system E8E15 No Session with RBC can be  D31<br>opened<br>S3 A32<br>Onboard offers Driver possibility to re-enter  E17 A43 Onboard informs Driver Yes<br>Radio Network type & GSM-R Network ID & to  Onboard informs Driver<br>registration status of the FRMCS on-board and its GSM-R MTs to their respective Radio Networks, depending on the Radio Network type and the perform the mission with one radio system & E3E4 Onboard informs Driver A29A41 "valid position vs. LRBG"  Onboard reports to RBC A33 Yes "valid position vs. LRBG" D32<br>requests Driver to Onboard informs Driver<br>  - use last stored RBC contact information (if any) or No<br>  - use EIRENE short number or<br>  - to enter/re-enter RBC contact information D8 Onboard reports "invalid  A34<br>Yes Both radio  No position vs. LRBG"  or "no<br>E5 syst. trk & onboard position vs. LRBG" to RBC<br>D33<br>A35<br>Onboard requests  S13 E18 RBC reports to Onboard "valid" position Yes RBC is able to confirm<br>Driver to enter  Train running number position<br>No Train running number is entered/re-validated  No<br>D12<br>Train running number is  Yes Level D10 A23 D22<br>"valid" RBC reports to Onboard  Yes RBC accepts<br>2 "train accepted" train<br>No<br>D11 0/1/NTC<br>E16 Session is opened D34 A38<br>Train data is validated  Yes "valid position vs.  RBC reports to Onboard<br>Yes unlinked BG" "train rejected"<br>D15 No<br>No<br>Onboard requests Driver to enter/re- S12 Ack of Train Data received No Onboard deletes stored position data A24 Yes "valid position vs. unlinked BG" D35<br>validate Train data<br>No<br>Yes<br>S11<br>E11 Wait for ack of Train Data Onboard terminates  A40 A39<br>Train Data EntryDriver selects  Train data ack by RBC E14 session and informs Driver stored position dataOnboard deletes<br>S10 S20<br>Waiting for Driver selection Waiting for Driver selection of "Start"<br>E22 E24<br>E10 E34 E12 Driver selects  Driver selects<br>Driver selects Driver selects Driver selects "Start"  "Start"<br>NL SM SH and Level is 1 and Level is 2<br>E20 E21<br>S21 Driver selects  Driver selects<br>Send MA request to RBC and wait "Start" "Start"<br>and Level is NTC and Level is 0<br>E35 E13 E26 E27<br>SM  SH  SR mode  OS/LS/SH MA<br>refused  refused  authorised by RBC received from RBC<br>by RBC by RBC<br>E29<br>S24 FS MA  S25 S22 S23<br>SR mode  received from RBC OS/LS/SH mode  SN mode  UN mode<br>proposed to Driver proposed to Driver proposed to Driver proposed to Driver<br>E32 E33 E30 E31<br>Driver ack Driver ack Driver ack Driver ack<br>See procedure  See procedure<br>NL mode "Supervised  "Shunting initiated  SR mode  FS mode  OS/LS/SH mode  SN mode UN mode<br>Manoeuvre" by Driver"<br><!-- End of picture text -->

<!-- end of page 25 -->

### **Figure 1: Flowchart for “Start of Mission”**

## **Degraded Situations**

5.4.5.1 Nominally, accidental loss of an already open session (that can occur at any step) has not been taken into account for the design of the SoM flowchart. However, should such a fault occur above D11 the nominal procedure applies (refer to D11 in flowchart). On the other hand, if it occurs in any step further than D11, the process shall go to S10.

5.4.5.2 The SoM flowchart described in section 5.4.3 only includes the main paths and does not exhaustively cover the various operational situations, which could occur while performing the SoM procedure (e.g. when revised instructions are given to the driver or when the driver needs to re-enter already captured data).

5.4.5.3 The ERTMS/ETCS on-board equipment shall also offer the driver the following possibilities, in addition to the ones that are described in section 5.4.3:

   - a) only at S10 and S20 and if the conditions defined in 5.8.2.1 for Stand By are fulfilled, to select “Override”. If the driver chooses to do so, then the process shall go to the procedure “Override” and, if the position is still invalid, the ERTMS/ETCS on-board shall delete the train position data (new status: “unknown”)

   - b) only at S10 and S20, to re-enter the Driver-ID

   - c) only at S10 and S20,to re-enter the “Train running number”

   - d) only at S20, to re-enter the Train data. If the driver chooses to do so, then the process shall go to S12.

   - e) only at S10 and S20, to re-enter the Level. If the driver chooses to do so, then the process shall go to S2

   - f) only at S20, to select “Non Leading”. If the driver chooses to do so, then the ERTMS/ETCS on-board equipment shall immediately switch to Non Leading mode and, if the position is still invalid, the ERTMS/ETCS on-board shall delete the train position data (new status: “unknown”).

   - g) only at S20, to select “Shunting”. If the driver chooses to do so, then the process shall go to the procedure “Shunting initiated by driver” and, if the position is still invalid, the ERTMS/ETCS on-board shall delete the train position data (new status: “unknown”). If, in level 2, the RBC rejects the request for Shunting, the process shall go back to S20.

   - h) only at S10, if valid Train Data is available, to select “Start”. If the driver chooses to do so:

      - if the level is 0, then the process shall go to S23.

      - if the level is NTC, then the process shall go to S22.

      - if the level is 1, then the process shall go to S24.

      - if the level is 2 and a session is open, then the process shall go to S21.

      - if the level is 2 and no session is open, then the process shall go to S24.

<!-- end of page 26 -->

- i) only at S10 and S20, to set/remove a Virtual Balise Cover.

- j) only at S10 and S20, to re-enter the Radio data. If the driver chooses to do so:

   - If the level is 2, then the process shall go to S3.

   - If the level is 0/1/NTC, then the driver shall only have the possibility to modify the Radio Network information.

- k) only at S20, if the level is 2 and the “safe consist length” information is available, to select “Supervised Manoeuvre”. If the driver chooses to do so, then the process shall go to the procedure “Supervised Manoeuvre”. If the RBC rejects the request for “Supervised Manoeuvre”, the process shall go back to S20.

- l) only at S10 and S20, to initiate the procedure for “Inhibition of balise transmission alarm reaction” (see 5.22).

## **Entry to Mode Considered as a Mission**

5.4.6.1 A mission is considered as started as soon as the ERTMS/ETCS on-board equipment enters FS, LS, SR, OS, SM, NL, UN, or SN mode.

5.4.6.2 Entry in all other modes, from SB mode, is not considered as a mission.

<!-- end of page 27 -->

# **5.5 Procedure End of Mission**

## **Introduction**

5.5.1.1 End of mission refers to the situation where the trackside stops to authorise the movement of a unit. End of mission is initiated by the ERTMS/ETCS on-board equipment when entering specific modes (see below).

## **Entry to Mode Considered as an End of Mission:**

**5.5.2.1 Stand-By mode**

5.5.2.1.1 From FS, AD, LS, OS, SM, UN, NL, SR, PT, RV or SN mode, the entry of the ERTMS/ETCS on-board equipment into the Stand-by mode is considered as an End of Mission

5.5.2.1.2 Note: While in SN mode (level NTC), some other conditions to end the mission may depend on the National System.

5.5.2.1.3 The entry of the ERTMS/ETCS on-board equipment into the Stand-by mode, from PT mode, is only considered as an End of Mission if there was an ongoing mission.

**5.5.2.2 Intentionally deleted**

**5.5.2.3 Shunting mode**

5.5.2.3.1 The entry of the ERTMS/ETCS on-board equipment into the Shunting mode, from FS, AD, LS, OS, SR, SM, SN or UN mode, is considered as an End of Mission.

5.5.2.3.2 The entry of the ERTMS/ETCS on-board equipment into the Shunting mode, from PT mode, is only considered as an End of Mission if there was an ongoing mission.

5.5.2.3.3 Note: While in SN mode (level NTC), some other conditions to end the mission may depend on the National System.

## **End of Mission Procedure**

5.5.3.1 The procedure comprises the following steps

5.5.3.1.1 Step 1 - MA, Track Description Data and Train Data may be deleted (mode dependent, see Chapter 4, section "What happens to accepted and stored information when Entering a Mode").

End of Procedure, if there is no existing communication session.

5.5.3.1.2 If a communication session with an RIU exists: Step 2 - The ERTMS/ETCS on-board equipment shall terminate the communication session

End of procedure

<!-- end of page 28 -->

5.5.3.1.3 If a communication session with an RBC exists:

   - Step 2 - The end of mission shall be reported to the RBC by means of the message “End of Mission”.

End of Procedure, if the mode entered is Stand-By upon desk closure.

   - Note: it is a trackside implementation issue to decide when it is appropriate to send a session termination order to an ERTMS/ETCS on-board equipment having reported its end of mission further to a desk closure.

5.5.3.1.4 If the mode entered is Shunting or Stand-By while a desk is still open (e.g. after the driver has selected “Exit SM”) and a communication session with an RBC exists:

   - Step 3 - The RBC shall request to terminate the communication session. Step 4 - The ERTMS/ETCS on-board equipment shall terminate the communication session

End of procedure

- Note: For the termination of the communication session refer to chapter 3, Management of Radio Communication.

Note: The “End of Mission” message contains a position report.

5.5.3.2 Intentionally deleted.

## **Degraded Situation**

5.5.4.1.1 Mode entered Shunting or Stand-By with a desk open: In case a communication session is established and no request to terminate the communication session is received from the RBC within a fixed waiting time (see appendix to chapter 3, List of Fixed Value Data) after sending the “End of Mission” message, the message shall be repeated with the fixed waiting time after each repetition.

   - After a defined number of repetitions (see appendix to chapter 3, List of Fixed Value Data), and if no reply is received within the fixed waiting time from the time of the last sending of “End of Mission”, the ERTMS/ETCS onboard equipment shall terminate the communication session.

5.5.4.1.2 Level 2: In case no communication session is open, no communication session shall be established to report the end of mission.

<!-- end of page 29 -->

# **5.6 Shunting Initiated by Driver**

## **Introduction**

5.6.1.1 The procedure describes the selection of shunting by the driver.

5.6.1.2 Intentionally deleted.

## **Table of requirements for “Shunting Initiated by Driver” procedure**

5.6.2.1 The ID numbers in the table are used for the representation of the procedure in form of a flowchart in section 5.6.3.

### **5.6.2.2 Procedure**

|**ID #**|**Requirements**|
|---|---|
|S0|The train is at standstill and the ERTMS/ETCS on-board equipment is in FS,<br>LS, AD, OS, SM, SR, SN, UN, PT or SB mode.<br>When the driver selects Shunting (**E015**) the process shall go to**D020**.|
|D020|If the current ETCS Level of operation is 0 or 1, the process shall go to**A050**.<br>If the current ETCS Level of operation is 2, the process shall go to**A045**.<br>If the current ETCS Level of operation is NTC, the process shall go to**D030**|
|D030|If there is an ongoing National Trip procedure reported by the STM, the process<br>shall go to**A030**<br>Otherwise the process shall go to**A050**|
|A030|The process shall go to the “Train trip" procedure|
|A045|The ERTMS/ETCS on-board equipment shall send the “Request for Shunting”<br>message to the RBC together with a position report (with special value “position<br>unknown” if the position is not known)<br>The process shall go to**S050**.|
|S050|The ERTMS/ETCS on-board equipment awaits the reply to the SH request.<br>If SH authorised is received from the RBC (optionally with a list of balise groups<br>for SH area, which the train can pass when the ERTMS/ETCS onboard<br>equipment is in shunting mode) (**E090**), the process shall go to**A050**.<br>If “SH refused” is received from the RBC (**E215**), the process shall go to**A220**.|
|A050|The mode shall change to SH. Any previous list of balise groups for SH area<br>shall be deleted or replaced by a new list of balise groups for SH area.<br>The process shall go to**D040**.|
|D040|If there is an ongoing mission, the process shall go to**A100**.<br>If there is no ongoing mission, the process shall go to**D080**.|
|A100|The process shall go to the “End of Mission" procedure|

<!-- end of page 30 -->

|**ID #**|**Requirements**|
|---|---|
|D080|If the current ETCS Level of operation is 2, the process shall go to**A095**.<br>If the current ETCS Level of operation is 0, 1 or NTC the process shall**END**.|
|A095|The mode change shall be reported to the RBC.<br>The process shall go to**S100**.|
|S100|The ERTMS/ETCS on-board equipment awaits the RBC order to terminate the<br>communication session.<br>When an order to terminate the communication session is received from RBC<br>the process shall go to**A115**.|
|A115|The ERTMS/ETCS on-board equipment shall terminate the communication<br>session.<br>The process shall**END**.|
|A220|An indication shall be given to the driver that SH was refused by the RBC.<br>The process shall**END**.|

## **Flowchart**

5.6.3.1 The ID numbers in the flowchart refer to the ID numbers of the table in section 5.6.2.

<!-- end of page 31 -->

<!-- Start of picture text -->
S0:<br>Train is at standstill &<br>Mode is FS, AD, LS, OS, SM, SR, PT, SN, UN or SB<br>D020:<br>2<br>Level<br>NTC<br>A045:<br>Issue SH request<br>D030:<br>National trip  No<br>procedure<br>S050:<br>Wait for RBC reply<br>Yes<br>E090: E215:<br>SH authorised SH refused<br>A030:<br>"Train Trip" procedure<br>A220:<br>Inform Driver: SH refused<br>A050:<br>End<br>Transition to SH mode<br>Train in SH mode<br>D040:<br>No D080: 2 A095:<br>On-going Mission Level Report mode change to RBC<br>S100:<br>Wait for order to terminate session<br>A100: A115:<br>End<br>"End of Mission" procedure Terminate session<br><!-- End of picture text -->

**Figure 2: Flowchart for “Shunting Initiated by Driver”**

## **Degraded Situation**

5.6.4.1 ERTMS/ETCS level 2: no answer to Shunting request is received from the RBC

5.6.4.1.1 In case a communication session is established and no reply is received from the RBC within a fixed waiting time (see appendix to chapter 3, List of Fixed Value Data) after sending the “Request for Shunting” message, the message shall be repeated with the fixed waiting time after each repetition.

5.6.4.1.2 After a defined number of repetitions (see appendix to chapter 3, List of Fixed Value Data), and if no reply is received within the fixed waiting time from the time of the last

<!-- end of page 32 -->

sending of “Request for Shunting”, the ERTMS/ETCS onboard equipment shall inform the driver and shall terminate the communication session.

5.6.4.1.3 If no authorisation for SH mode can be received from the RBC while the mode is different from SM, refer to procedure “Override”.

5.6.4.2 ERTMS/ETCS level 2: in case a communication session is established and no order to terminate the session is received from the RBC within a fixed waiting time (see appendix to chapter 3, List of Fixed Value Data) after reporting the mode change, the report shall be repeated with the fixed waiting time after each repetition

5.6.4.3 After a defined number of repetitions (see appendix to chapter 3, List of Fixed Value Data), and if no reply is received within the fixed waiting time from the last sending of the mode change report, the ERTMS/ETCS onboard equipment shall terminate the communication session.

<!-- end of page 33 -->

# **5.7 Entry in Shunting with Order from Trackside**

## **General Requirements**

5.7.1.1 This procedure is used to allow the entry of a train into a shunting area.

5.7.1.2 Note: The shunting area, possibly including a “safety envelope”, can be already occupied by shunting units, not controlled by the trackside. It is therefore possible that the train shall enter into the shunting area in OS mode. The switch to OS is performed according to the relevant procedure.

5.7.1.3 The order to switch to SH mode shall be given by means of a mode profile, optionally with a list of balise groups, which the train can pass when the ERTMS/ETCS on-board equipment is in shunting mode.

5.7.1.4 The switch to shunting, if the transition to shunting was ordered by trackside, requires a driver acknowledgement, according to the specifications below.

5.7.1.5 When the ERTMS/ETCS on-board equipment has switched to Shunting mode, End of Mission, according to chapter 5.5.2.3, is performed.

## **Shunting is requested for the current location (from modes different from Stand By and Post Trip)**

5.7.2.1 In a level 1 area, or at the border from a level 0 to a level 1 area, the beginning of the shunting area can be the location where a balise group is installed. In level 2 it is possible to send an ERTMS/ETCS on-board equipment the order to switch to shunting at the current location.

5.7.2.2 Shunting is requested for the current location means that, according to the mode profile received the max safe front end of the train is at or in advance of the location for which switching to SH mode is requested.

5.7.2.3 The ERTMS/ETCS on-board equipment shall switch immediately to SH mode and a request for acknowledgement shall be displayed to the driver (refer to SRS chapter 4, transitions between modes).

5.7.2.4 If the driver does not acknowledge within the driver acknowledgement time (refer to Appendix A.3.1) after the change to SH mode, the service brake command shall be triggered.

## **Shunting is requested for a further location**

5.7.3.1 An order to switch to SH at a further location can be sent a) in a level 1 area by a balise group,

   - b) in a level 2 area by the RBC.

<!-- end of page 34 -->

5.7.3.2 A request for acknowledgement shall be displayed to the driver, when the following two conditions are fulfilled:

   - a) the distance between the estimated front end of the train and the beginning of shunting area is shorter than a value, contained in the mode profile

   - b) the speed is equal to or lower than the Shunting mode speed limit (National Value, or value given in the mode profile)

5.7.3.3 Once the request for acknowledgement is displayed, it shall not be taken back, even if the above conditions are no more fulfilled (e.g., the train accelerates).

5.7.3.4 Intentionally deleted.

5.7.3.5 When the driver acknowledges, the ERTMS/ETCS on-board equipment shall immediately switch to SH mode (refer to chapter 4, transitions between modes).

5.7.3.6 If the max safe front end of the train reaches the beginning of the shunting area according the mode profile and the driver has not yet acknowledged, the ERTMS/ETCS on-board equipment shall switch immediately to SH mode and a request for acknowledgement shall be displayed to the driver (refer to SRS chapter 4, transitions between modes).

5.7.3.7 If, in this case, the driver does not acknowledge within the driver acknowledgement time (refer to Appendix A.3.1) after the change to SH mode, the service brake command shall be triggered.

## **Shunting from Stand By or Post Trip mode**

5.7.4.1 When performing a SoM or a Train Trip procedure and when the current level is 2, the ERTMS/ETCS on-board equipment can receive a mode profile giving an Shunting area whose beginning has already been passed by the train with its max safe front end. In this case, the ERTMS/ETCS on-board equipment shall first require an acknowledgement from the driver.

5.7.4.2 When the driver acknowledges, the ERTMS/ETCS on-board equipment shall perform transition to Shunting mode.

<!-- end of page 35 -->

## **Flowchart**

<!-- Start of picture text -->
mode is FS, AD, LS, OS,<br>SR, SB, PT, UN or SN<br>A mode profile for SH area<br>has been received and is used<br>current location  further location<br>(max safe front end  beginning of  (max safe front  Transition to FS/LS/OS mode<br>in advance of  SH area vs  end in rear of<br>(if not yet in FS/AD/LS/OS)<br>beginning of SH  train position  beginning of SH<br>area)  area)<br>Max safe front overpasses<br>begin of SH area  - Start of SH mode profile<br>Mode is SB   YES  supervised as temporary EoA<br>or PT  - Waiting<br>estimated front and speed in<br>acknowledgement window<br>NO<br>- acknowledgement is<br>Transition to  requested to driver<br>SH mode  - Waiting for driver ackno<br>Max safe front overpasses<br>begin of SH area<br>Driver acknowledges<br>Transition to<br>- acknowledgement is<br>Driver acknowledges  SH mode<br>requested to driver  within 5sec<br>- Waiting for driver ackno<br>5 sec are elapsed &<br>no ack by driver<br>Service brake command<br>until driver acknowledges<br><!-- End of picture text -->

**Figure 3: Flowchart for “Entry in Shunting with Order from Trackside”**

<!-- end of page 36 -->

# **5.8 Procedure Override**

## **Introduction**

5.8.1.1 In specific degraded situations (for example in the case of a failed signal, failed track circuit, failed point…), railways allow a train to pass its End of Movement Authority.

5.8.1.2 For ERTMS/ETCS, passing an End of Movement Authority can be required in degraded situations, e.g.

   - In level 2, if a train is stopped without MA in a location where radio is unavailable (e.g. after having received an emergency message, or after a train trip).

   - In level 2, if a train is stopped at the border between two adjacent RBCs (e.g. the interface between RBCs is unavailable).

   - In level 2, if a train is stopped after having passed the border between two adjacent RBCs (e.g. the connection to the Accepting RBC cannot be established).

   - In level 2, if the RBC is unable to give a permission to run (e.g. lost connection with the interlocking)

   - In level 1, if a signal cannot show a proceed aspect (e.g., signal failure, route cannot be set)

   - In level 1, if a train is stopped without MA (e.g. after the MA has been shortened due to a time-out).

5.8.1.3 In level 0/NTC areas, passing a signal at danger is only a national procedure. The ERTMS/ETCS on-board equipment is not involved in this procedure, since it does not supervise the train movements.

5.8.1.4 In ERTMS equipped areas (level 1 or 2), locations where the train shall stop are supervised by the ERTMS/ETCS on-board equipment. Receiving an order from the signalman to pass the End of Movement Authority, the driver must then be able to inhibit this supervision.

5.8.1.4.1 Note: The driver must not use the “Override” procedure unless authorised by trackside personnel. This authorisation is covered by operational procedures.

5.8.1.5 If a signal at danger must be passed between announcement and execution of the level transition from an unfitted area (level 0) or from an area fitted with a National System (level NTC) to an ERTMS equipped area (level 1 or 2 ), the signalman gives the order to the driver to select “override”.

5.8.1.6 Note: By using this procedure the driver is fully responsible for the train driving. Therefore Staff Responsible mode is entered when the driver selects “override”.

5.8.1.7 In addition the procedure allows to avoid a train trip when passing a balise group:

   - a) transmitting "stop if in SR mode"

   - b) not contained in the list of expected balises in SR mode

<!-- end of page 37 -->

- c) transmitting "stop if in SH mode"

d) not contained in the list of expected balises in SH mode"

e) Intentionally deleted

5.8.1.8 Further, the Override procedure allows a train in SR mode reaching the end of the SR distance to proceed (see also 4.4.11.1.6.5)

5.8.1.9 In case the Override procedure is selected while the ERTMS/ETCS on-board equipment considers a temporary EOA (as per clause 3.12.2.4, 3.12.4.7 or 3.12.5.8) which is closer than the EOA, all the instances of the term EOA throughout this section 5.8 shall relate to this temporary EOA.

## **Selection of “Override”**

5.8.2.1 The ERTMS/ETCS on-board equipment shall allow the driver to select “Override” only when:

   - a) The train speed is under or equal to the speed limit for triggering the “override” function (national value) AND

   - b) The current mode is Full Supervision, Automatic Driving, Limited Supervision, On Sight, Staff Responsible, Shunting, Unfitted, Post Trip, Stand By (in level 2 only) or SN (National System) AND

   - c) Validated Train Data and Train running number are available (except when already in Shunting mode).

5.8.2.2 Intentionally deleted.

5.8.2.3 The “Override” procedure shall be triggered when selected by the driver.

## **Once the “Override” procedure has been triggered**

5.8.3.1 The mode shall change as follows:

   - a) If the current mode is Full Supervision, Automatic Driving, Limited Supervision, On Sight, Stand-By or Post Trip, the mode shall immediately switch to the Staff Responsible (SR) mode (if the mode is already SR it remains unchanged)

   - b) If the current mode is Shunting the mode shall remain unchanged

   - c) If the current mode is Unfitted (level 0 area) or SN (level NTC area) the mode shall only change to Staff Responsible when the level changes to 1 or 2 (refer to SRS chapter 4, transitions between modes)

5.8.3.1.1 If the mode, when activating Override, is OS, LS, FS or AD, the former EOA/LOA shall be retained. If the mode is SB or PT and there is a valid train position stored on-board, the current position of the train front shall be considered as the former EOA/LOA. If the mode is SB or PT and there is no valid train position stored on-board, the on-board shall

<!-- end of page 38 -->

supervise a zero distance from the virtual train front position (see section 3.6.7) to the former EOA/LOA.

|5.8.3.1.2|Note: This former EOA/LOA will be used as a Trip condition if the Override function is no<br>longer active. Any further activation of the Override in SR mode has no effect on the<br>former EOA/LOA.|
|---|---|
|5.8.3.1.3|The former EOA/LOA shall be deleted if:<br>a) the train reads the information “stop if in SR mode” from a balise group OR<br>b) SR mode is left.|
|5.8.3.2|Note 1: In level 2, if radio communication is available, the RBC is only informed that the<br>Override has been triggered by means of the reported mode change (if there is any)|
|5.8.3.3|Note 2: In level 2, if the ERTMS/ETCS- onboard equipment is able to report the mode<br>change to the RBC, the RBC may transmit limits for the distance to run in SR mode<br>(overriding the national value), a list of balise groups to be passed in SR mode (refer to<br>chapter 4, Staff Responsible mode)|
|5.8.3.4|Note 3: In level 2, the transition to SR mode triggered by selecting Override revokes all<br>emergency stop orders previously received.|
|5.8.3.5|In SR mode the driver may modify the value of the SR mode speed limit and of the<br>distance to run in SR mode (refer to chapter 4, Staff Responsible mode)|
|5.8.3.6|The train trip shall be inhibited (suppression of the transition to the Trip mode), and only<br>in level 0, 1 or 2, the MRSP shall include the Override function related Speed Restriction<br>(see 3.11.10) as long as the Override function is active.|
|5.8.3.7|The status “override active” shall be indicated to the driver.|
|5.8.3.7.1|Exception 1: In case the Override function has been activated by an STM (see SUBSET-<br>035) and as long as the on-board is in level NTC, the status “override active” shall not<br>be indicated to the driver.|
|5.8.3.7.2|Exception 2: In case the Override function has been activated by selection of “Override”<br>while being in level 0, 1 or 2, the status “override active” shall stop being indicated to the<br>driver on executing a transition to level NTC and shall remain unindicated as long as the<br>on-board is in level NTC.|
|5.8.3.8|As long as the Override function is active, new SR distance information received from<br>Euroloop shall be rejected.|
|5.8.3.9|When “Override” is selected and Override is already active, the supervision of the time<br>and distance (see 5.8.4.1 a) and b)) for train trip suppression shall be re-started.|
||**End of Override procedure**|
|5.8.4.1|The Override procedure shall end when at least one of the following conditions is fulfilled:|

<!-- end of page 39 -->

   - a) The "max. time for train trip suppression when Override function is triggered" (national value) elapses after Override has been selected

   - b) The train has run more than the "distance for train trip suppression when Override function is triggered" (national value) after Override has been selected

   - c) The former EOA/LOA has been passed with the min safe antenna position

   - d) The train passes a balise group giving “stop if in SR mode” or “stop if in SH mode” information

   - e) The train passes a balise group giving proceed information (i.e., MA with no signalling related speed restriction of value zero)

   - f) In level 2, an MA is received from the RBC

   - g) The train passes a balise group not in the list of expected balises in SR mode or the list of expected balises in SH mode

   - h) The train overpasses the SR distance supervised before overriding with its estimated front end

   - i) The ERTMS/ETCS on-board equipment switches to TR, LS, OS or SH mode.

5.8.4.1.1 Note: For modes UN and SN, only end conditions a) and b) are supervised.

5.8.4.2 The ERTMS/ETCS on-board equipment shall apply the conditions d) and g) (i.e. the Override function shall be considered as not active anymore) only once all the information received from the balise group has been evaluated.

5.8.4.3 Intentionally deleted.

<!-- end of page 40 -->

# **5.9 Procedure On-Sight**

## **General Requirements**

5.9.1.1 The ERTMS/ETCS on-board equipment shall be in On Sight mode before the train reaches the beginning of the On Sight area or, at the latest, when the train reaches the beginning of the On Sight area.

5.9.1.2 An acknowledgement for running in On Sight mode is requested from the driver. The conditions of the acknowledgement are specified below.

## **On Sight is requested for current location (from modes different from Stand By and Post Trip)**

5.9.2.1 In a level 1 area, the beginning of the On Sight area can be the balise (group) that gives the Mode Profile. When the train passes the balise group and receives this information, the ERTMS/ETCS on-board equipment shall immediately switch to On Sight mode.

5.9.2.2 In a level 2 area, the ERTMS/ETCS on-board equipment can receive a mode profile giving an On Sight area which the train position confidence interval already overlaps. If starting from the min safe front end of the train this On Sight area is the furthest area that the train position confidence interval overlaps within the mode profile, the ERTMS/ETCS on-board equipment shall immediately switch to On Sight mode.

5.9.2.3 The driver must acknowledge the On Sight mode. A request of acknowledgement shall be displayed to the driver.

5.9.2.4 If the driver has not acknowledged within the driver acknowledgement time (refer to Appendix A.3.1) after the change to OS mode, the service brake command shall be triggered.

5.9.2.5 Note: Once in On Sight mode, the speed supervision is such that the train speed cannot exceed the OS mode speed limit. If, when entering the On Sight mode, the train speed was higher than the OS mode speed limit (because a higher speed was allowed in Full Supervision mode, in Automatic Driving mode, in Limited Supervision mode or in Staff Responsible mode) then a service/emergency brake command could be immediately triggered, independently of the acknowledgement of the driver, but because of the On Sight supervision (see Figure 4).

<!-- end of page 41 -->

<!-- Start of picture text -->
Transition to OS mode triggers<br>SB/EB command<br>speed<br>permitted speed  (even if driver acknowledges<br>in previous mode  within 5s)<br>Brake command revoked<br>(conditions see SRS chapter 3,<br>Speed & Distance Monitoring)<br>train speed<br>permitted speed in OS<br>mode<br> Location of: OS request for   location<br>current location<br><!-- End of picture text -->

### **Figure 4: Train enters OS area with too high speed**

5.9.2.6 Note: This sharp brake reaction can be avoided in Full Supervision, Automatic Driving or Limited Supervision mode by giving with the previous MA an EOA (or a LOA = OS mode speed limit) at the location of transition to On Sight mode. In Staff Responsible mode, lateral signals (if available) can also order the driver to decrease the train speed.

5.9.2.7 If the ERTMS/ETCS on-board equipment is already in OS mode when receiving the OS mode profile, no further acknowledgement shall be requested from the driver.

## **On Sight is requested for a further location**

5.9.3.1 The beginning of the On Sight area can be a location that the train has not reached yet. This occurs when:

   - a) In a level 1 area, a balise group gives a Mode Profile with an On Sight area that is located at a further location.

   - b) In a level 2 area, the RBC gives a Mode Profile with an On Sight area that is located at a further location.

5.9.3.2 A request for acknowledgement shall be displayed to the driver when the following conditions are fulfilled:

   - a) The distance between the estimated front end of the train and the beginning of On Sight area is shorter than a value, contained in the mode profile.

   - b) The speed is equal to or lower than the On Sight mode speed limit (national value, or value given in the mode profile).

   - c) The current mode is not On Sight

5.9.3.3 The conditions 5.9.3.2 a) and b) define the “rectangle of acknowledgement”.

5.9.3.4 Once the acknowledgement request is displayed, it shall not be taken back if the train leaves the “rectangle of acknowledgement” (for example: because the train accelerates).

5.9.3.5 Intentionally deleted.

<!-- end of page 42 -->

5.9.3.6 When the driver acknowledges the On Sight mode, the ERTMS/ETCS on-board equipment shall immediately switch to the On Sight mode.

<!-- Start of picture text -->
braking curve in FS/AD/LS<br>d<br>acknowledge request is<br>speed  displayed to the driver<br>driver acknowledges<br>train speed<br>Permitted Speed<br>In OS mode<br> location<br>Beginning of the<br>Acknowledgement<br>On Sight area<br>Area<br>Transition to<br>On Sight mode<br><!-- End of picture text -->

### **Figure 5: Transition from FS/AD/LS to OS mode after driver acknowledgement**

5.9.3.7 If the max safe front end of the train reaches the beginning of the On Sight area according to the mode profile and the driver has not yet acknowledged, the ERTMS/ETCS on-board equipment shall switch immediately to OS mode and a request for acknowledgement shall be displayed to the driver (refer to SRS chapter 4, transitions between modes).

5.9.3.8 If, in this case, the driver does not acknowledge within the driver acknowledgement time (refer to Appendix A.3.1) after the change to OS mode, the service brake command shall be triggered.

## **On Sight from Unfitted or SN mode**

5.9.4.1 The mode profile with regards to an OS area is only evaluated in level 1, R, although the mode profile may have been received in level 0 (Unfitted mode) or NTC (SN mode). A transition to On Sight mode can therefore earliest occur at a transition of level: from level 0 or NTC to level 1 or 2.

5.9.4.2 Requirements about the acknowledgement in section 5.9.2 shall apply.

## **On Sight from Stand By or Post Trip mode**

5.9.5.1 When performing a SoM or a Train Trip procedure and when the current level is 2, the ERTMS/ETCS on-board equipment can receive a mode profile giving an On Sight area which the train position confidence interval already overlaps. If starting from the min safe

<!-- end of page 43 -->

front end of the train this On Sight area is the furthest area that the train position confidence interval overlaps within the mode profile, the ERTMS/ETCS on-board equipment shall first require an OS acknowledgement from the driver.

5.9.5.2 When the driver acknowledges, the ERTMS/ETCS on-board equipment shall perform the transition to On Sight mode.”

## **Exit of On Sight mode**

**5.9.6.1 General rule**

5.9.6.1.1 The ERTMS/ETCS on-board equipment shall exit the On Sight mode when the min safe front end of the train passes the end of the On Sight area.

**5.9.6.2 First case: The On Sight area ends at the EOA/LOA of the current MA**

5.9.6.2.1 This occurs when the end of the On Sight area that is given by the Mode Profile has the same location as the EOA/LOA of the related MA.

5.9.6.2.2 In this case, the train must receive a new Movement Authority to be able to exit the On Sight area.

5.9.6.2.3 Note: In an On Sight area there is no guarantee for the RBC that the track in front of the supervised train is free. Therefore, if the next block section is free, the RBC has nevertheless to ensure that there is no train/vehicle between the train and the end of the On Sight area. This information

   - can be given to the RBC by the signalman or any other trackside means (outside scope of  ERTMS/ETCS), or

   - can be inquired by the RBC by means of the following mechanism: the RBC sends a “track ahead free” request which the ERTMS/ ETCS on-board equipment displays to the driver. If the driver confirms that the track is free up to the end of the current section, the ERTMS/ ETCS on-board equipment will transmit this information to the RBC.

5.9.6.2.4 Note: Receiving the “track ahead free” information, the RBC may be able to transmit an MA from the current position of the train, e.g., for Full Supervision (refer to SRS chapter 4, transitions between modes).

**5.9.6.3 Second case: The On Sight area ends before the EOA/LOA of the current MA**

5.9.6.3.1 In this case, the current Movement Authority already allows the train to exit the On Sight area.

5.9.6.3.2 When exiting the On Sight area, the ERTMS/ETCS on-board equipment switches either to Full Supervision, to Limited Supervision or to Shunting mode (refer to SRS chapter 4, transitions between modes).

<!-- end of page 44 -->

## **Flowchart**

<!-- Start of picture text -->
mode is FS, AD, LS, OS, SR,<br>SB, PT, UN or SN<br>A mode profile for OS area<br>has been received and is used<br>current location (train  further location<br>position confidence<br>OS area vs  (max safe front  Transition to FS/LS mode<br>interval overlaps OS  area, which is the  train position  end in rear of OS  (if not yet in FS/AD/LS)<br>area)<br>furthest one)<br>Max safe front overpasses<br>begin of OS area  - Start of OS mode profile<br>OS  Mode  SB,PT  supervised as temporary EoA<br>- Waiting<br>estimated front and speed in<br>acknowledgement window<br>FS,AD,LS,SR,UN,SN<br>- acknowledgement is<br>Transition to  requested to driver<br>OS mode  - Waiting for driver ackno<br>Max safe front overpasses<br>begin of OS area<br>Driver acknowledges<br>Transition to<br>- acknowledgement is<br>Driver acknowledges  OS mode<br>requested to driver  within 5sec<br>- Waiting for driver ackno<br>5 sec are elapsed &<br>no ack by driver<br>Service brake command<br>until driver acknowledges<br><!-- End of picture text -->

**Figure 6: Flowchart for “On-Sight”**

<!-- end of page 45 -->

# **5.10 Level Transitions**

## **General requirements**

5.10.1.1 Every level transition border to an area where operation in level 2 or NTC is supported shall be announced to the ERTMS/ETCS on-board equipment via balise group or via the RBC.

5.10.1.2 A level transition announcement to the ERTMS/ETCS on-board equipment shall consist of an order to execute the level transition at a further location corresponding to the border.

5.10.1.3 When the ERTMS/ETCS on-board equipment receives a level transition announcement, and if this announcement will result in a change of the on-board level, it shall immediately inform the driver about the announced level transition.

5.10.1.3.1 Note: In a mixed level area the actual level of the on-board equipment may remain unchanged even though a level transition boundary is passed.

5.10.1.4 At the level transition border a balise group shall be placed with an immediate level transition order or a conditional level transition order.

5.10.1.4.1 Note: Balise groups are read in all levels and level transition orders and conditional level transition orders from balises are accepted independent of the level of operation. Also sleeping units read balise groups.

<!-- Start of picture text -->
Announcement by RBC<br>possible if communication<br>session exists<br>Announcement by  Level<br>balise group transition<br>location<br>Level X area Level Y area<br><!-- End of picture text -->

**Figure 7: Transition from level X area to level Y area**

5.10.1.5 If the message from the border balise group is not received, the level transition shall still be executed when the estimated front end passes the location given in the announcement.

5.10.1.6 The on-board equipment shall manage only one level transition order at a time. Therefore a new level transition order shall replace a previously received order that has not yet been executed.

5.10.1.6.1 If a level transition order has not yet been executed but the driver changes the level manually (see 3.18.4.2.4) this shall delete the level transition order..

<!-- end of page 46 -->

5.10.1.7 As soon as the announcement of the level transition has been received, some data (mainly movement authority and track description data) from the transmission media of the new level shall be accepted, but shall not be used until the level transition is effective.

5.10.1.7.1 Note: for the exhaustive list of accepted/rejected information, please refer to SRS chapter 4.8.

5.10.1.7.2 Note: if only track description has been received from the new media without any movement authority, this track description still replaces the one previously received from the current media when the transition is performed.

5.10.1.8 When the onboard has performed the level transition, further data (mainly movement authority and track description data) received from the transmission media of the level being left shall be rejected.

5.10.1.8.1 Note: for the exhaustive list of accepted/rejected information, please refer to SRS chapter 4.8.

5.10.1.9 Intentionally deleted.

## **Table of priority of trackside supported levels**

5.10.2.1 Any combination of ERTMS/ETCS levels 0, NTC, 1 and 2 on a given area shall be possible.

5.10.2.2 The level transition announcement and the immediate or conditional level transition order at the border shall contain all the supported ERTMS/ETCS levels with a table of priority. Even if only one level is permitted this is considered as a table of priority.

5.10.2.2.1 Note: Level 0 is considered in the same way as the other levels. This means that, for example, when an area permits ERTMS/ETCS level 0, and is fitted with ERTMS/ETCS level 1 and 2, the track-side includes levels 0, 1 and 2 in a table of priority of supported levels in all level transition orders and conditional level transition orders applying to that area.

5.10.2.3 The table of priority shall list all the supported levels from the highest priority level to the lowest one.

5.10.2.3.1 Intentionally deleted.

5.10.2.4 When receiving the information about all ERTMS/ETCS levels that are supported by trackside, the ERTMS/ETCS on-board equipment shall select from the table the level with the highest priority, which is available for use by the onboard equipment.

5.10.2.4.1 The on-board equipment shall consider an ERTMS/ETCS level as “Available for use” according to the following conditions:

   - a) Level 2:

      - the FRMCS on-board equipment is available, i.e. the ETCS on-board has detected that it is in working condition, in case the stored Radio Network type

<!-- end of page 47 -->

is FRMCS or is FRMCS+GSM-R while FRMCS is the only radio system installed on-board, OR

   - unless the driver has elected to perform the mission with only one radio system, both the FRMCS on-board equipment and at least one GSM-R Mobile Terminal are available (i.e. the ETCS on-board has detected that the FRMCS on-board and at least one GSM-R Mobile Terminal are in working condition), in case the stored Radio Network type is FRMCS+GSM-R while both radio systems are installed on-board, OR

   - while the driver has elected to perform the mission with only one radio system, the concerned radio equipment is available on-board (i.e. the ETCS on-board has detected that it is in working condition), in case the stored Radio Network type is FRMCS+GSM-R while both radio systems are installed on-board, OR

   - at least one GSM-R Mobile Terminal is available on-board, i.e. the ETCS onboard has detected at least one Mobile Terminal in working condition, in case the stored Radio Network type is GSM-R or is FRMCS+GSM-R while GSM-R is the only radio system installed on-board,

      - independently whether the FRMCS on-board equipment and/or the GSM-R Mobile Terminals is (are) registered to their respective network or not.

- b) Level NTC: the concerned National System is available on-board (if an STM is used, refer to SUBSET-035 for further details).

- c) Level 0 or 1: always.

   - Note regarding a) and b): how the ERTMS/ETCS on-board equipment checks the

   - availability of the FRMCS on-board equipment, of the GSM-R Mobile Terminals or of the National System (in case no STM is used) is an implementation issue.

5.10.2.4.2 Examples: The table of trackside supported levels gives 2, NTC X, 1, NTC Y. If level 1, 0 and NTC X are “Available for use”, the ERTMS/ETCS on-board will select NTC X level. If level 1, 0 and NTC Y are “Available for use”, it will select level 1. If level 2, 1 and 0 are “Available for use”, it will select level 2.

5.10.2.5 When the onboard has selected the level it will switch to, it shall carry out the level transition as if it has received a level transition order to this level only i.e. it shall ignore the requirements related to transitions to the other levels.

5.10.2.6 The ERTMS/ETCS on-board equipment shall inform the driver about the selected level transition only.

5.10.2.7 If none of the ordered level(s) is available for use by the ERTMS/ETCS on-board equipment, it shall nevertheless make the transition, to the ordered level with the lowest priority.

5.10.2.7.1 Justification: The On-board equipment will then indicate the trackside level to the driver to allow him to select the correct procedures for degraded situations.

<!-- end of page 48 -->

5.10.2.8 After level transition information has been evaluated and regardless of whether it results in a change of the on-board level, the ERTMS/ETCS on-board equipment shall store its table of priority of trackside supported ERTMS/ETCS levels, for further driver selection (see 3.18.4.2.5).

5.10.2.9 Only one table of priority of trackside supported ERTMS/ETCS levels shall be applicable at a time. The table of priority of trackside supported ERTMS/ETCS levels included in level transition information shall become applicable:

   - a) in case of level transition announcement, when the estimated front end has passed the location given in the announcement;

   - b) in case of immediate level transition order or conditional level transition order, upon evaluation of the order.

5.10.2.10 A table of priority of trackside supported ERTMS/ETCS levels which is not yet applicable shall be deleted if:

   - a) new level transition information is received, or

   - b) the stored level transition announcement including it is deleted (see sections A.3.4, 4.10 and clause 5.10.1.6.1).

5.10.2.10.1 Intentionally deleted.

## **Specific Additional Requirements**

**5.10.3.1 Transition from Level 1 to Level 2 area**

5.10.3.1.1 An order to connect to the RBC shall be given via balise group in rear of the border location.

5.10.3.1.2 For the train to be able to enter the new area, the old area must possess information about at least the first section of the new area. The information shall be transmitted to the train either:

   - a) as an MA and track description information into the new area, or

   - b) as a target speed at the border location i.e. as an LOA.

5.10.3.1.3 When the ERTMS/ETCS communication session is open, Train Data shall be sent to the RBC (which acknowledges the data) unless the onboard equipment is in SL or NL mode.

5.10.3.1.4 If no Level 2 MA and track description has been received when entering the new area, the train shall still be supervised according to the level 1 MA previously received.

5.10.3.1.5 When the ERTMS/ETCS on-board equipment has switched to the new level, it shall report the new on-board level, including a position report.

5.10.3.1.6 If an order to connect to an RBC has been received and the train will not enter the announced RBC area, an order to terminate the session shall be sent either from balises or from the RBC for any route not leading to the RBC area. This is the case both if the train turns back and if the train continues in the same direction, but on another route.

<!-- end of page 49 -->

**5.10.3.2 Transition from Level 0 (Unfitted) to Level 2 area**

5.10.3.2.1 An order to connect to the RBC shall be given via balise group in rear of the border location.

5.10.3.2.2 When the ERTMS/ETCS communication session is open, Train Data shall be sent to the RBC (which acknowledges the data) unless the onboard equipment is in SL or NL mode.

5.10.3.2.3 A level 2 MA and track description information shall be received from the RBC before the level transition border. If not, the train will be tripped at passage of the border, i.e. after switching to level 2, movement is not allowed without a movement authority (refer to SRS chapter 4, transitions between modes).

5.10.3.2.4 The driver is responsible for entering the level 2 area at a speed not exceeding the speed limits of the unequipped line.

5.10.3.2.5 When the ERTMS/ETCS on-board equipment has switched to the new level, it shall report the new on-board level, including a position report.

5.10.3.2.6 If an order to connect to an RBC has been received and the train will not enter the announced RBC area, an order to terminate the session shall be sent either from balises or from the RBC for any route not leading to the RBC area. This is the case both if the train turns back and if the train continues in the same direction, but on another route.

### **5.10.3.3 Transition from Level 2 to Level 1 area**

5.10.3.3.1 For the train to be able to enter the new area, the old area must possess information about at least the first section of the new area. The information shall be transmitted to the train either

   - a) as an MA and track description information into the new area, or

   - b) as a target speed at the border location i.e. as an LOA.

5.10.3.3.2 If no Level 1 MA and track description has been received when entering the new area, the train shall still be supervised according to the level 2 MA previously received from the RBC.

5.10.3.3.3 When the train has passed the level transition border with its min safe rear end, the ERTMS/ETCS on-board equipment of the leading engine shall send a position report to the RBC.

5.10.3.3.4 After receiving this exit position report, the RBC can order the train to terminate the session (leading and non-leading engines).

5.10.3.3.5 In case the ERTMS/ETCS on-board equipment has reported that the train has passed with its min safe rear end the level transition border and no order to terminate the session is received within a fixed waiting time (see Appendix A.3.1) from the time the position report was sent, it shall repeatedly send a position report with the fixed waiting time after each repetition, until the order to terminate the session is received, or the defined number of repetitions (see Appendix A.3.1) has been reached. If no reply is received within the

<!-- end of page 50 -->

fixed waiting time after the last repetition, the ERTMS/ETCS on-board equipment shall terminate the communication session.

- Note: if, in order to send the session termination order, the RBC relies on a train

- integrity confirmation indicating that the confirmed rear end of the train has passed the border, it is assumed that this information is received by the trackside before the onboard terminates the session when the fixed waiting time after the last repetition elapses.

### **5.10.3.4 Transition from Level 0 (Unfitted) to Level 1 area**

5.10.3.4.1 A level 1 MA and track description information shall be received before or at the level transition border. If not, when the level transition is performed, the train will be tripped, i.e. after switching to level 1, movement is not allowed without a movement authority (refer to SRS chapter 4, transitions between modes).

5.10.3.4.2 The driver is responsible for entering the level 1 area at a speed not exceeding the speed limits of the unequipped line.

### **5.10.3.5 Transition from Level 1 to Level 0 (Unfitted) area**

5.10.3.5.1 For the train to be able to enter the new area, the old area must possess information about at least the first section of the new area. The information shall be transmitted to the train either

a) as an MA and track description information into the new area, or

b) as a target speed at the border location i.e. as an LOA.

5.10.3.5.2 Note: When entering UN mode, all MA and track description data is deleted (refer to SRS Chapter 4, What happens to stored data when entering a mode)

### **5.10.3.6 Transition from Level 2 to Level 0 (Unfitted) area**

5.10.3.6.1 For the train to be able to enter the new area, the old area must possess information about at least the first section of the new area. The information shall be transmitted to the train either

   - a) as an MA and track description information into the new area, or

   - b) as a target speed at the border location i.e. as an LOA.

5.10.3.6.2 When the train has passed the level transition border with its min safe rear end, the ERTMS/ETCS on-board equipment of the leading engine shall send a position report to the RBC.

5.10.3.6.3 After receiving this exit position report, the RBC can order the train to terminate the session (leading and non-leading engines).

5.10.3.6.4 Note: When entering UN mode, all MA and track description data is deleted (refer to SRS Chapter 4, What happens to stored data when entering a mode)

5.10.3.6.5 In case the ERTMS/ETCS on-board equipment has reported that the train has passed with its min safe rear end the level transition border and no order to terminate the session

<!-- end of page 51 -->

is received within a fixed waiting time (see Appendix A.3.1) from the time the position report was sent, it shall repeatedly send a position report with the fixed waiting time after each repetition, until the order to terminate the session is received, or the defined number of repetitions (see Appendix A.3.1) has been reached. If no reply is received within the fixed waiting time after the last repetition, the ERTMS/ETCS on-board equipment shall terminate the communication session.

   - Note: if, in order to send the session termination order, the RBC relies on a train

   - integrity confirmation indicating that the confirmed rear end of the train has passed the border, it is assumed that this information is received by the trackside before the onboard terminates the session when the fixed waiting time after the last repetition elapses.

**5.10.3.7 Transition from Level NTC to Level 2 area**

5.10.3.7.1 An order to connect to the RBC shall be given via balise group in rear of the border location.

5.10.3.7.2 When the ERTMS/ETCS communication session is open, Train Data shall be sent to the RBC (which acknowledges the data) unless the onboard equipment is in SL or NL mode.

5.10.3.7.3 A level 2 MA and track description information shall be received from the RBC before the level transition border. If not, the train will be tripped at passage of the border, i.e. after switching to level 2, movement is not allowed without a movement authority (refer to SRS chapter 4, transitions between modes).

5.10.3.7.4 The driver is responsible for entering the level 2 area at a speed not exceeding the speed limits of the level NTC line.

5.10.3.7.5 When the level transition location is passed with the estimated front end a position report shall be sent to the RBC. In case the ERTMS/ETCS on-board equipment is interfaced to the National System through an STM, please refer to SUBSET-035 for the STM state transition order.

5.10.3.7.6 If an order to connect to an RBC has been received and the train will not enter the announced RBC area, an order to disconnect shall be sent either from balises or from the RBC for any route not leading to the RBC area. This is the case both if the train turns back and if the train continues in the same direction, but on another route.

**5.10.3.8 Transition from Level NTC to Level 1 area**

5.10.3.8.1 A level 1 MA and track description information shall be received before or at the level transition border. If not, when the level transition is performed, the train will be tripped, i.e. after switching to level 1, movement is not allowed without a movement authority (refer to SRS chapter 4, transitions between modes).

5.10.3.8.2 The driver is responsible for entering the level 1 area at a speed not exceeding the speed limits of the Level NTC line.

<!-- end of page 52 -->

5.10.3.8.3 In case the ERTMS/ETCS on-board equipment is interfaced to the National System through an STM, please refer to SUBSET-035 for the STM state transition orders in relation to the level transition announcement and border.

**5.10.3.9 Transition from Level 1 to Level NTC area**

5.10.3.9.1 For the train to be able to enter the new area, the old area must possess information about at least the first section of the new area. The information shall be transmitted to the train either

   - a) as an MA and track description information into the new area, or

b) as a target speed at the border location i.e. as an LOA.

5.10.3.9.2 Intentionally deleted.

5.10.3.9.3 In case the ERTMS/ETCS on-board equipment is interfaced to the National System through an STM, please refer to SUBSET-035 for the STM state transition orders in relation to the level transition announcement and border.

**5.10.3.10 Transition from Level 2 to Level NTC area**

5.10.3.10.1 For the train to be able to enter the new area, the old area must possess information about at least the first section of the new area. The information shall be transmitted to the train either

   - a) as an MA and track description information into the new area, or

   - b) as a target speed at the border location i.e. as an LOA.

5.10.3.10.2 Intentionally deleted.

5.10.3.10.3 When the train has passed the level transition border with its min safe rear end, the ERTMS/ETCS on-board equipment of the leading engine shall send a position report to the RBC.

5.10.3.10.4 After receiving this exit position report, the RBC can order the train to terminate the session (leading and non-leading engines).

5.10.3.10.5 In case the ERTMS/ETCS on-board equipment is interfaced to the National System through an STM, please refer to SUBSET-035 for the STM state transition orders in relation to the level transition announcement and border.

5.10.3.10.6 In case the ERTMS/ETCS on-board equipment has reported that the train has passed with its min safe rear end the level transition border and no order to terminate the session is received within a fixed waiting time (see Appendix A.3.1) from the time the position report was sent, it shall repeatedly send a position report with the fixed waiting time after each repetition, until the order to terminate the session is received, or the defined number of repetitions (see Appendix A.3.1) has been reached. If no reply is received within the fixed waiting time after the last repetition, the ERTMS/ETCS on-board equipment shall terminate the communication session.

<!-- end of page 53 -->

- Note: if, in order to send the session termination order, the RBC relies on a train

- integrity confirmation indicating that the confirmed rear end of the train has passed the border, it is assumed that this information is received by the trackside before the onboard terminates the session when the fixed waiting time after the last repetition elapses.

### **5.10.3.11 Transition from Level NTC (National System X) to Level NTC (National System Y)**

5.10.3.11.1 Intentionally deleted.

5.10.3.11.2 In case the ERTMS/ETCS on-board equipment is interfaced to the National System through an STM, please refer to SUBSET-035 for the STM state transition orders in relation to the level transition announcement and border.

5.10.3.11.3 Intentionally deleted.

### **5.10.3.12 Transition from Level NTC to Level 0**

5.10.3.12.1 In case the ERTMS/ETCS on-board equipment is interfaced to the National System through an STM, please refer to SUBSET-035 for the STM state transition orders in relation to the level transition announcement and border.

5.10.3.12.2 The driver is responsible for entering the level 0 area at a speed not exceeding the maximum speed of the Level NTC line.

5.10.3.12.3 Intentionally deleted.

### **5.10.3.13 Transition from Level 0 to Level NTC**

5.10.3.13.1 Intentionally deleted.

5.10.3.13.2 In case the ERTMS/ETCS on-board equipment is interfaced to the National System through an STM, please refer to SUBSET-035 for the STM state transition orders in relation to the level transition announcement and border.

5.10.3.13.3 The driver is responsible for entering the level NTC area at a speed not exceeding the speed limits of the unequipped line.

### **5.10.3.14 Conditional level transition order**

5.10.3.14.1 When the ERTMS/ETCS on-board equipment accepts a conditional level transition order the onboard shall check whether the current level is contained in the priority list of the conditional level transition order.

5.10.3.14.2 If the current level is contained in the priority list of the conditional level transition order, the onboard shall not change the level.

5.10.3.14.3 If the current level is not contained in the priority list of the conditional level transition order, the onboard shall evaluate the conditional level transition order in the same way as an immediate level transition order (see section 5.10.2).

5.10.3.14.4 In the same way as for a level transition order, the ERTMS/ETCS on-board equipment shall store the table of ERTMS/ETCS levels supported by trackside.

<!-- end of page 54 -->

5.10.3.14.5 Note: The conditional level transition order allows to check, whether a train operates in a permitted level e.g. following a start of mission after a cold movement. The level of a train driving in a permitted level will not be changed, regardless of the priority of the current level operated by the train.

### **5.10.3.15 Transition initiated by driver**

5.10.3.15.1 In addition to the level transitions ordered by trackside, it is also possible, at standstill, for the driver to change the ERTMS/ETCS level (refer to section 3.18.4.2).

5.10.3.15.2 If the driver changes the level to 2, the ERTMS/ETCS on-board equipment shall establish a communication session with the RBC:

   - a) immediately if valid RBC contact information is available and

      - the FRMCS on-board is registered to the FRMCS Radio Network, in case the stored Radio Network type is FRMCS or is FRMCS+GSM-R while FRMCS is the only radio system installed on-board, OR

      - the FRMCS on-board is registered to the FRMCS Radio Network and at least one GSM-R Mobile Terminal is registered to a GSM-R Radio Network, in case the stored Radio Network type is FRMCS+GSM-R while both radio systems are installed on-board, OR

      - at least one GSM-R Mobile Terminal is registered to a Radio Network, in case the stored Radio Network type is GSM-R or is FRMCS+GSM-R while GSM-R is the only radio system installed on-board,

OR

- b) once the driver has selected the Radio data (by the same means as for Start of Mission), if the conditions listed in item a) are not fulfilled.

   - Note regarding b): If the level transition leads to TR mode, the request for RBC contact

   - information is only displayed once the ERTMS/ETCS on-board equipment is in PT mode.

5.10.3.15.3 If the driver changes the level from 2 to any other, the ERTMS/ETCS on-board equipment shall report the new level to the RBC if a communication session is established. When receiving the level change report, the RBC shall order the communication session to be terminated.

5.10.3.15.4 In case the ERTMS/ETCS on-board equipment has reported having changed from level 2 to any other and no order to terminate the session is received within a fixed waiting time (see Appendix A.3.1) from the time the position report was sent, it shall repeatedly send a position report with the fixed waiting time after each repetition, until the order to terminate the session is received, or the defined number of repetitions (see Appendix A.3.1) has been reached. If no reply is received within the fixed waiting time after the last repetition, the ERTMS/ETCS on-board equipment shall terminate the communication session.

<!-- end of page 55 -->

## **Acknowledgement of the level transition ordered by trackside**

5.10.4.1 If defined so for the level transition (see table below), the driver shall be requested to acknowledge the transition

   - a) when the max safe front end of the train has passed a trackside defined location in rear of the level transition border

   - b) upon receipt of the order to switch to the new level immediately

||||Ack|nowledgem|ent when ent|ering|
|---|---|---|---|---|---|---|
||||L 0|L 1|L 2|L NTC|
|||L 0|-|No|No|Yes|
|ing|...|L 1|Yes|-|No|Yes|
|Com|from|L 2|Yes|No|-|Yes|
|||L NTC|Yes|No|No|Yes|

5.10.4.1.1 Exception: An ERTMS/ETCS on-board equipment in NL mode shall not require an acknowledgement from the driver.

5.10.4.1.2 Exception 1 to 5.10.4.1.a): in SB mode, the driver shall be requested to acknowledge the level transition only when the level changes.

5.10.4.1.3 Exception 2 to 5.10.4.1.a): If the condition 5.10.4.1 a) is immediately fulfilled upon receipt of the order and if this order consists in switching to the same level as the one resulting from a previously received but not yet executed order that the driver had already acknowledged, the ERTMS/ETCS on-board equipment shall not request the driver to acknowledge this transition again.

5.10.4.1.4 Exception to 5.10.4.1.b): if the order consists in switching to the same level as the one resulting from a previously received but not yet executed level transition announcement that the driver had already acknowledged, the ERTMS/ETCS on-board equipment shall not request the driver to acknowledge this transition again.

5.10.4.2 If the driver has not yet acknowledged within the driver acknowledgement time (refer to Appendix A.3.1) after the level transition, a service brake command shall be initiated.

5.10.4.3 Intentionally deleted.

5.10.4.4 Intentionally deleted.

<!-- end of page 56 -->

# **5.11 Procedure Train Trip**

## **Introduction**

5.11.1.1 A train can be tripped for various reasons: refer to SRS chapter 4, mode transition table.

## **Table of requirements for “Train Trip” procedure**

5.11.2.1 The ID numbers in the table are used for the representation of the procedure in form of a flowchart in section 5.11.3.

### **5.11.2.2 Procedure**

|**ID #**|**Requirements**|
|---|---|
|S010|The ERTMS/ETCS on-board equipment is in one of the following<br>modes: FS, AD, LS, OS, SR, SB, SM, SH, SN or UN<br>When an event occurs, which leads to train trip reaction (**E015**– refer<br>to chapter 4, transitions between modes), the process shall go to<br>**A025**.|
|A025|The mode shall change to TR.<br>The process shall go to**D020**.|
|D020|If the level is 1, the process shall go to**A035**.<br>If the level is 2, the process shall go to**A030**.<br>If the level is 0/NTC, the process shall go to**S050**.|
|A030|The ERTMS/ETCS on-board equipment shall report the mode change<br>to the RBC<br>The process shall go to**A035**.|
|A035|All current MA and track description data (if any), except track<br>conditions, shall be deleted and new ones shall not be accepted<br>The process shall go to**S050**.|
|S050|The ERTMS/ETCS on-board equipment awaits standstill. While<br>braking a border to a level 0 or NTC area may be passed.<br>When the train has come to standstill (**E055**), the process shall go to<br>**S060**.|
|S060|The ERTMS/ETCS on-board equipment shall display the "Request for<br>driver acknowledgement to Train Trip" to the driver.<br>When the driver acknowledges the Train Trip (**E065**), the process<br>shall go to**D080**.|
|D080|If the level is 1 or 2 the process shall go to**A105**.<br>If the level is 0 or NTC, the process shall go to**D085**|

<!-- end of page 57 -->

|**ID #**|**Requirements**|
|---|---|
|A105|The mode shall change to PT and the ERTMS/ETCS on-board<br>equipment revokes the emergency brake command.<br>For the supervision provided by the PT mode refer to SRS chapter 4.<br>The process shall go to**D110**.|
|D085|If no valid Train Data is stored on-board, the process shall go to**A140**<br>If valid Train Data is stored on-board, the process shall go to**D090**|
|A140|The mode shall change to SH and the process shall**END**.|
|D090|If the level is 0, the process shall go to**A145**.<br>If the level is NTC, the process shall go to**A150**.|
|A145|The mode shall change to UN and the process shall**END**.|
|A150|The mode shall change to SN and the process shall**END**.|
|D110|If the level is 1, the process shall go to**S140**.<br>If the level is 2, the process shall go to**A115**.|
|A115|The mode change to PT shall be reported to the RBC which shall<br>acknowledge the mode report (Recognition of exit from TR).<br>The process shall go to**S120**.|
|S120|The ERTMS/ETCS on-board equipment waits for the RBC to<br>acknowledge the transition to PT.<br>When the acknowledgement is received from the RBC (**E125**), the<br>process shall go to**D130**.<br>Note: See 5.11.4 for degraded situation (no response received).|
|D130|If there is at least one pending emergency stop, the process shall go<br>to**S130**.<br>If there are no pending emergency stops the process shall go to<br>**S140**.|
|S130|The ERTMS/ETCS on-board equipment waits for the RBC to revoke<br>ALL pending emergency stops.<br>When all emergency stops are revoked (**E135**) the process shall go to<br>**S140**.|

<!-- end of page 58 -->

|**ID #**|**Requirements**|
|---|---|
|S140|The ERTMS/ETCS on-board equipment shall offer the possibility to<br>the driver to select "start" (only if train data has been previously<br>entered), to select “Supervised Manoeuvre” (only if the level is 2, if<br>the train position is valid and is referred to an LRBG, and if the safe<br>consist length information is available), or to select SH<br>a) If the driver selects "start" and the level is 1 (**E150**), the<br>process shall go to**S160**|
||b) If the driver selects "start" and the level is 2 (**E155**), the<br>process shall go to**S150**|
||c) If the driver selects “Supervised Manoeuvre”**(E190)**, the<br>process shall continue in the same way as the procedure<br>“Supervised Manoeuvre”. If the SM request is refused by the<br>RBC (**E200**) the process shall return to**S140**<br>d) If the driver selects SH (**E145**), the process shall continue in<br>the same ways as the procedure “Shunting initiated by the<br>driver”. If the SH request is refused by the RBC (**E165**) the<br>process shall return to**S140**.|
|S150|The ERTMS/ETCS on-board equipment shall send an MA request to<br>the RBC and wait.<br>a) If an SR authorisation is received from RBC (**E26**), the<br>process shall go to**S160**<br>b) If an MA allowing OS/LS/SH is received from RBC (**E175**),<br>the process shall go to**S170**<br>c) If an MA allowing FS is received from RBC (**E170**), the mode<br>shall change to FS (refer to SRS chapter 4, transitions<br>between modes: transition from PT to FS) and the process<br>shall**END**.|
|S160|The ERTMS/ETCS on-board equipment shall request an<br>acknowledgement from the driver for running in SR mode. When the<br>driver acknowledges (**E180**), the mode shall change to SR (refer to<br>SRS chapter 4, transitions between modes: transition from PT to SR)<br>and the process shall**END**.|
|S170|The ERTMS/ETCS on-board equipment shall request an<br>acknowledgement from the driver for running in OS/LS/SH mode.<br>When the driver acknowledges (**E185**), the mode shall change to<br>OS/LS/SH (refer to SRS chapter 4, transitions between modes:<br>transition from PT to OS/LS/SH) and the process shall**END**.|

<!-- end of page 59 -->

## **Flowchart**

5.11.3.1 The ID numbers in the flowchart refer to the ID numbers of the table in section 5.11.2.

<!-- end of page 60 -->

<!-- Start of picture text -->
S010 :<br>ERTMS/ETCS On-board<br>equipment in FS, AD, LS, OS, SR,<br>SB, SM, SH, SN or UN mode<br>TR mode<br>E015 : One of the Trip<br>conditions is fulfilled<br>A025 : D020 2 A030 :<br>Perform transition to TRIP Level Report mode change to RBC<br>A035 :<br>Delete MA and track<br>1<br>description data except track<br>conditions, do not accept<br>new ones<br>0/NTC S050 :<br>Wait for standstill<br>SH mode<br>E055 : Train comes to standstill<br>S060 : A140 :<br>Await driver  Perform transition to<br>E065 : Driver acknowledgement acknowledgement SHUNTING<br>to Train Trip<br>No<br>D085<br>D080 0/NTC Valid Train<br>Level data on-board<br>1/2 Yes<br>A105 : D090<br>Perform transition to 0 Level NTC<br>POST TRIP<br>A115 : PT mode<br>Report mode change<br>to RBC<br>A145 : A150 :<br>2 D110 1 Perform transition  Perform transition<br>Level to to NATIONAL<br>S120 : UNFITTED SYSTEM (SN)<br>Await RBC<br>acknowledgement<br>E125 : Recognition of exit from TR<br>UN mode SN mode<br>D130<br>Emergency  Yes S130 :<br>Wait for emergency stop<br>stop to be  revocation<br>revoked E165 : SH refused by RBC<br>No E135 : Emergency stop revoked<br>See<br>E190 : Driver S140 : E145 : Driver procedure<br>selects SM Waiting for Driver selection selects SH « SH initiated<br>by Driver »<br>See  E150 : E155 : Driver selects « Start »<br>procedure  Driver selects« Start » and Level is 2<br>« Supervised and Level is 1<br>Manoeuvre » E26 : SR mode S150 :<br>authorised by RBC Send MA request to RBC  E170 : FS MA receivedfrom RBC FS mode<br>E200 : SM refused and wait<br>by RBC<br>E175 : OS/LS/SH MA received from RBC<br>SR mode Driver ack E180 : SR mode proposed to Driver S160 : OS/LS/SH mode proposed to Driver S170 : Driver ack E185 : OS/LS/SH mode<br><!-- End of picture text -->

**Figure 8: Flowchart for “Train Trip”**

<!-- end of page 61 -->

## **Degraded Situations**

5.11.4.1 ERTMS/ETCS level 2: no acknowledge for PT mode is received from the RBC

5.11.4.1.1 In case a communication session is established and no reply is received from the RBC within a fixed waiting time (see appendix to chapter 3, List of Fixed Value Data) after reporting the mode change, the report shall be repeated with the fixed waiting time after each repetition.

5.11.4.1.2 After a defined number of repetitions(see appendix to chapter 3, List of Fixed Value Data) and if no reply is received within the fixed waiting time from the last sending of the mode change report, the ERTMS/ETCS onboard equipment shall terminate the communication session.

5.11.4.2 Nominally, accidental loss of an already open session (that can occur at any step) has not been taken into account for the design of the flowchart. However, should such a fault occur in any step while ERTMS/ETCS on-board equipment is in level 2 and in PT mode, the driver shall have the possibility to select "Override" if the conditions defined in 5.8.2.1 are fulfilled and the process shall go to the procedure "Override".

5.11.4.3 In case a transition to Level 0 or Level NTC occurs while in PT mode, the process shall go to D085.

<!-- end of page 62 -->

# **5.12 Change of Train Orientation**

## **Introduction**

5.12.1.1 The scope of this procedure is the supervision of a train where the driver controls the train from the cab in the front of the train with the direction controller in FORWARD position.

5.12.1.2 This implies that when the driver has to change the orientation of the train, he has to change the driving cab.

5.12.1.3 The scope of this procedure is NOT shunting movements, during which the driver changes the running direction of the train without leaving the cab, by changing the position of the direction controller from FORWARD to REVERSE.

5.12.1.4 The scope of this procedure is NOT the reverse movement that is allowed in Post Trip or in Reversing mode.

5.12.1.5 The scope of this procedure is NOT Supervised Manoeuvre movements, during which the train orientation can change according to the last received SM authorisation and the driver changes the running direction of the train without leaving the cab, by changing the position of the direction controller from FORWARD to REVERSE.

## **The driver uses the same engine (a mission is ongoing)**

5.12.2.1 The situation is the following: The driver closes the desk A and leaves the cab A of the leading engine of the train, to go to cab B and open desk B of this same engine.

5.12.2.2 Desk A and desk B are connected to the same ERTMS/ETCS on-board equipment.

5.12.2.3 When the driver closes the desk A, the ERTMS/ETCS on-board equipment immediately goes to Stand-By mode, which is considered as an end of mission (see “End of Mission” procedure).

5.12.2.4 When the driver opens the desk B, the “Start of Mission” procedure is triggered.

5.12.2.5 When the driver closes a desk and opens the other one of the same engine, the ERTMS/ETCS on-board equipment shall be able to calculate the new train position data (train front position, train orientation), by use of the previous data.

## **The driver leaves the engine to go to another one**

5.12.3.1 The described situation is the following: The train has two engines (engine A and engine B). The engine A is the leading engine. The engine B is a slave engine. Each engine has its own ERTMS/ETCS on-board equipment.

   - a) If engine B is remote controlled, its ETCS on-board equipment is in Sleeping mode. Note: The mode is entered when on-board equipment detects the presence of the "remote control" signal.

<!-- end of page 63 -->

   - b) If the slave engine is not remote controlled (Tandem operation) by the leading engine but there is a driver who controls the engine, then the on-board equipment is in Non leading mode.

   - c) If the engine B is not remote controlled (Tandem Shunting operation) by the leading engine and there is no driver who controls the engine, then the on-board equipment is in Passive Shunting mode.

5.12.3.2 Assumption: The train configuration does not change.

   - a) When changing the train orientation, the leading engine A will become the slave engine, and the slave engine B will become the leading engine.

   - b) If before the change of train orientation engine B was in SL, afterwards engine A will be in SL mode; If before the change of train orientation engine B was in NL, afterwards engine A will be in NL mode; If before the change of train orientation engine B was in PS, afterwards engine A will be in PS mode.

**5.12.3.3 Case "Engine B was in SL mode"**

5.12.3.3.1 The driver of engine A closes the desk, then the ERTMS/ETCS on-board equipment of engine A switches to Stand-By mode. If the train has a mission, this is a end of mission (see “End of Mission” procedure)

5.12.3.3.2 As soon as the remote control signal disappears, the ERTMS/ETCS on-board equipment of engine B switches to Stand-By mode.

5.12.3.3.3 Level 2: The ERTMS/ETCS on-board equipment of engine B opens a communication session (if possible) and reports the mode change to the RBC.

5.12.3.3.4 When the driver opens a desk of engine B he triggers the "Start of Mission" procedure.

**5.12.3.4 Case "Engine B was in NL mode"**

5.12.3.4.1 The driver of engine A selects "Non Leading". The ERTMS/ETCS equipment switches to Non Leading mode.

5.12.3.4.2 Once the non leading input signal is not received any more, the ERTMS/ETCS on-board equipment of engine B will switch to Stand-By mode (refer to SRS chapter 4, transitions between modes and chapter 5, “End of Mission” procedure).

5.12.3.4.3 Because the desk is open, when the ERTMS/ETCS on-board equipment enters StandBy mode, the “Start of Mission” procedure is triggered.

**5.12.3.5 Case "Engine B was in PS mode"**

5.12.3.5.1 The driver of engine A selects "Continue Shunting on desk closure". The ERTMS/ETCS equipment switches to Passive Shunting mode once the driver closes the desk of engine A.

5.12.3.5.2 The driver opens a desk in engine B, and ERTMS/ETCS equipment switches to Shunting mode.

<!-- end of page 64 -->

## **The driver uses the same engine (a Shunting movement is ongoing)**

5.12.4.1 The situation is the following: while the ERTMS/ETCS on-board equipment is in Shunting mode, the driver closes the desk A and leaves the cab A of the Shunting engine, to go to cab B and open desk B of this same engine.

5.12.4.2 Desk A and desk B are connected to the same ERTMS/ETCS on-board equipment.

5.12.4.2.1 Before closing the desk A, the driver enables the function “Continue Shunting on desk closure”. When the driver closes the desk A, the ERTMS/ETCS on-board equipment shall immediately go to Passive Shunting mode.

5.12.4.2.2 When the driver opens the desk B, the ERTMS/ETCS on-board equipment shall immediately switch back to Shunting mode.

5.12.4.3 When the driver closes a desk and opens the other one of the same engine, the ERTMS/ETCS on-board equipment shall be able to calculate the new train position data (train front position, train orientation), by use of the previous data.

<!-- end of page 65 -->

# **5.13 Train Reversing**

5.13.1.1 This procedure is intended to allow the fast reversal of movement of a train, to run away from a danger up to a “safe” location.

5.13.1.2 The area where initiation of reversing will be possible is announced to the ERTMS/ETCS on-board equipment by trackside (refer to 3.15.4.2 for details).

5.13.1.3 While the train front end is at standstill inside the reversing permitted area, the driver shall be informed that reversing is possible

5.13.1.4 If the ERTMS/ETCS onboard detects the driver’s intention to reverse (e.g. from a direction controller in reverse position), the ERTMS/ETCS on-board equipment shall ask the driver to acknowledge transition to RV mode.

5.13.1.5 If the driver acknowledges, the on-board equipment shall switch to RV mode

5.13.1.6 Once in RV mode, it shall be possible for the trackside to send a new permitted distance to run and a new maximum speed.

5.13.1.7 Once in RV mode, it shall also be possible for the trackside to send, together with the new permitted distance to run and the maximum speed, a new reference location for the new permitted distance to run.

5.13.1.8 Note: this new reference location is the end of a new reversing area given by trackside that the onboard will use only for the purpose of distance referencing.

<!-- end of page 66 -->

# **5.14 Joining / Splitting**

## **Definitions**

5.14.1.1 Definition for splitting: The “train to be split” is the train at standstill, waiting for being split. The “front train after splitting” refers to the front part of the train before splitting, the “new train after splitting”, refers to the other part.

5.14.1.2 Definitions for joining: The “train to be joined” is the train at standstill, waiting for being joined. The “joining train” is the train performing the joining operation.

## **Procedure “Splitting”**

5.14.2.1 Step 1 - The electrical and mechanical links between the two trains must be removed (this is a national operational procedure, out of the scope of the SRS).

5.14.2.1.1 Note: If splitting requires moving the two train parts apart from each other for a small distance, this can be done even in SB mode

5.14.2.2 Step 2a - If the ERTMS/ETCS onboard equipment which was supervising the train before splitting has not performed an end of mission for splitting, the Train Data must be modified (e.g. by the driver) such that it fits with the new train composition after splitting. For level 2, the new train data is sent to the RBC (see SRS chapter 3 – Data Entry / Modification Process)

5.14.2.3 Step 2b - If an ERTMS/ETCS on-board equipment of the "new train after splitting" was in SL mode before, it will switch to SB mode once the remote control signal is not received any more (refer to SRS chapter 4, transitions between modes). For Level 2: The ERTMS/ETCS on-board equipment opens a communication session (if possible) and reports the mode change to the RBC.

5.14.2.4 Step 2c - If an ERTMS/ETCS on-board equipment of the "new train after splitting" was in NL mode before, it will switch to SB mode once the non leading input signal is not received any more (refer to SRS chapter 4, transitions between modes and chapter 5, “end of mission” procedure).

5.14.2.5 The driver can then start a new mission with this “new train after splitting” (refer to the “Start of Mission” procedure). In all cases, to start a mission is not the only possibility. Shunting movements, or not moving the new train at all, are also possible.

## **Procedure “Joining”**

5.14.3.1 Step 1 - The “joining train” must approach the “train to be joined”. This can be performed in SR, OS, SM or SH mode (depending on the information available, and on the national procedure for joining).

<!-- end of page 67 -->

5.14.3.2 Step 2 - The electrical and mechanical links between the two trains must be closed (vehicle dependent, outside the scope of the ETCS).

5.14.3.3 Step 3a - If a former leading ERTMS/ETCS on-board equipment remains leading and there was no end of mission, the driver must modify the Train Data such that it fits with the new train composition. For level 2, the new train data is sent to the RBC (see SRS chapter 3 – Data Entry / Modification Process)

5.14.3.4 Step 3b - If a former leading ERTMS/ETCS on-board equipment is to become slave equipment in SL mode, when closing the desk, the ERTMS/ETCS on-board equipment will switch to SB mode (see SRS chapter 4, transitions between modes) and the end of mission procedure is executed (see “End of Mission” procedure). Transition to SL mode is from SB mode.

5.14.3.5 Step 3c - If a former leading ERTMS/ETCS on-board equipment is to become slave equipment in NL mode, the driver selects NL mode (see SRS chapter 4, transitions between modes).

5.14.3.6 For further steps after joining refer to procedures “Start of Mission” and “Change of Train Orientation”.

<!-- end of page 68 -->

# **5.15 RBC/RBC Handover**

## **Principles**

5.15.1.1 Every RBC/RBC handover shall be announced to the ERTMS/ETCS on-board equipment via a balise group or via the RBC.

5.15.1.2 The handover announcement (i.e. RBC transition order) to the ERTMS/ETCS on-board equipment shall consist of an order to establish a communication session with the Accepting RBC (see 3.5.2.6.2) and to execute the handover at a further location corresponding to the border.

5.15.1.2.1 In case of RBC/RBC handover including a change of Radio Network type and/or a change of GSM-R Radio Network, ERTMS/ETCS trackside is responsible for the sequence of Radio Network transition order and order to establish a communication session with the "Accepting" RBC, according to the Radio Network’s configuration. The following Radio Network transitions are possible:

   - t1 GSM-R => FRMCS (for completeness reason, i.e. the on-board only stores the Radio Network type and does not order any radio network registration);

   - t2 FRMCS => GSM-R;

   - t3 GSM-Rx => FRMCS+GSM-Rx (for completeness reason, i.e. the on-board only stores the Radio Network type and does not order any radio network registration);

   - t4 GSM-Rx => FRMCS+GSM-Ry;

   - t5 FRMCS+GSM-Rx => GSM-Rx (for completeness reason, i.e. the on-board only stores the Radio Network type and does not order any radio network registration);

   - t6 FRMCS+GSM-Rx => GSM-Ry, communication session with “Handing Over” RBC through FRMCS;

   - t7 FRMCS+GSM-Rx => GSM-Ry, communication session with “Handing Over” RBC through GSM-Rx;

   - t8 FRMCS => FRMCS+GSM-R;

   - t9 FRMCS+GSM-R => FRMCS (for completeness reason, i.e. the on-board only stores the Radio Network type and does not order any radio network registration);

   - t10 FRMCS+GSM-Rx => FRMCS+GSM-Ry, communication session with “Handing Over” RBC through FRMCS;

   - t11 FRMCS+GSM-Rx => FRMCS+GSM-Ry, communication session with “Handing Over” RBC through GSM-Rx;

   - t12 GSM-Rx => GSM-Ry.

5.15.1.2.2 In the following sections, if both radio communication sessions with “Handing Over” RBC and “Accepting” RBC are established with GSM-R, "first" GSM-R Mobile Terminal refers to the one used for communication session with “Handing Over” RBC and "second" GSM-R Mobile Terminal to the one used for communication session with “Accepting” RBC.

<!-- end of page 69 -->

5.15.1.2.3 Note: In the following sections, Radio Networks (FRMCS and/or GSM-R) pertaining to the “Handing Over” RBC and “Accepting” RBC areas are supposed to be overlapped.

5.15.1.3 At the RBC/RBC border a balise group with an order to execute the handover immediately shall be placed.

5.15.1.3.1 Note: Balise groups are read in all levels and orders from balise groups are accepted independent of the level of operation. Also sleeping units read balise groups.

5.15.1.4 If the message from the border balise group is not (yet) received, the handover shall still be executed when the train with its max safe front end passes the border location according to the announcement information.

5.15.1.5 Intentionally deleted.

## **Procedure**

### **5.15.2.1 Overview**

5.15.2.1.1 In the normal operation, the main functional steps needed for running from one RBC area to another one are the following:

   - a) Pre-announcement of the transition by the “Handing Over” RBC;

   - b) Depending on the Radio Network transition and the radio system through which the “Handing Over” RBC communication session is established, registration to the FRMCS network of the FRMCS on-board equipment and/or registration to the new GSM-R Radio Network of second GSM-R Mobile Terminal & Establishment of the radio communication session with the “Accepting” RBC;

   - c) Generation of movement authorities including the border;

   - d) Announcement of the RBC transition

   - e) Transfer of train supervision to the “Accepting” RBC;

   - f) Termination of the session with “Handing Over” RBC.

   - g) Only in case of GSM-R Radio Network change and if the radio communication session with the “Handing over” RBC was established through GSM-R: Registration to the new GSM-R Radio Network of first GSM-R Mobile Terminal

### **5.15.2.2 Step by step description**

### **5.15.2.2.1 Pre-announcement**

- When the “Handing Over” RBC generates a movement authority which reaches the

- border to another RBC area, it initiates the processes associated to the transition.

The “Handing Over” RBC informs the “Accepting” RBC about the RBC/RBC handover.

<!-- end of page 70 -->

**5.15.2.2.2 Registration to the FRMCS network of the FRMCS on-board equipment and/or to the new GSM-R Radio Network of second GSM-R Mobile Terminal & Establishment of the radio communication session with “Accepting” RBC**

- A radio communication session with the Accepting RBC is opened by the on-board

- equipment based on the RBC transition order received from the “Handing Over” RBC or from balise group (refer to chapter 3, section "management of radio communication").

- In case of RBC/RBC handover including Radio Network change, the registration to

- the FRMCS network of the FRMCS on-board equipment (see t1, t3, t4 in 5.15.1.2.1), the registration to the new GSM-R radio network of the second GSM-R Mobile Terminal (see t2, t4, t6, t7, t8, t10, t11, t12 in 5.15.1.2.1), is completed before the RBC transition order is transmitted to the on-board equipment.

- Depending on whether the communication session with the “Handing Over” RBC is

- established with FRMCS (see t2, t6, t8, t10 in 5.15.1.2.1), the registration to the new GSM-R radio network of the first GSM-R Mobile Terminal can also be completed at the same time.

### **5.15.2.2.3 Generation of MAs including the border**

- The “Handing Over” RBC is responsible for establishing the movement authority

- based on:

- a) Information from the trackside equipment and interlocking of its own area (for the part of route related information up to the border),

- b) Information from the “Accepting RBC” for the part of route related information in advance of the border.

<mark>MA sent by “Handing Over” RBC</mark>

<!-- Start of picture text -->
MA sent by “Handing Over” RBC<br>Route related information from  Route related information from<br>“Handing Over” RBC  “Accepting” RBC<br>Balise group at<br>LRBG  MA  the  border<br>request route information<br>“Handing  “Accepting”<br>Over” RBC  RBC<br>route information<br><!-- End of picture text -->

**Figure 9: RBC to RBC transition: MA generation.**

<!-- end of page 71 -->

- When it is required to send a movement authority to the train, the “Handing Over”

- RBC will request from the “Accepting” RBC information needed for extending the MA in advance of the border.

### **5.15.2.2.4 Announcement**

- When the train reaches the border with its max safe front end, the ERTMS/ETCS on-

- board equipment sends a position report both to the “Handing Over” RBC and to the “Accepting” RBC.

   - The “Handing Over” RBC forwards the announcement information to the “Accepting”

   - RBC.

5.15.2.2.4.2.1 Note: The forwarding of the announcement information is executed because the “Handing Over” RBC has no knowledge if the ERTMS/ETCS on-board equipment is in a degraded situation or not i.e. whether it can handle one or two communication sessions.

### **5.15.2.2.5 Transfer of train supervision to “Accepting” RBC**

- As soon as the on-board has sent to the “Accepting” RBC the position report referred

- to in 5.15.2.2.4.1, it considers to be supervised by the “Accepting” RBC i.e. it uses information received from the “Accepting” RBC.

- When the “Accepting” RBC receives a position report from the on-board and detects

- that the max safe front end has passed the border, it takes over the responsibility and informs the “Handing Over” RBC.

### **5.15.2.2.6 Termination of the session with “Handing Over” RBC**

- When the min safe rear end of the train passes the location of the border, the

- ERTMS/ETCS on-board equipment sends a position report to the “Handing Over” RBC.

- It is a trackside implementation issue to decide when it is appropriate to send the

- session termination order to the on-board equipment, e.g. when the ”Handing Over” RBC receives a position report and detects that the minimum safe rear end of the train has passed the border, or after the RBC has received a train integrity confirmation indicating that the confirmed rear end of the train has passed the border.

### **5.15.2.2.7 Registration to the new GSM-R Radio Network of first GSM-R Mobile Terminal**

- In case of RBC/RBC handover including a GSM-R Radio Network change and if the

- communication session with the “Handing Over” RBC is established through GSM-R (see t4, t7, t11, t12 in 5.15.1.2.1), the registration to the new GSM-R Radio Network of the first GSM-R Mobile Terminal is initiated by the ERTMS/ETCS on-board equipment as soon as the communication session with the "Handing Over" RBC has been terminated and the safe radio connection has been released.

<!-- end of page 72 -->

## **Degraded situation: Only one GSM-R communication session can be handled**

### **5.15.3.1 Overview**

5.15.3.1.1 In case the radio communication session with the “Handing over” RBC was established through GSM-R and the RBC transition order does not relate to an RBC interfaced with FRMCS only, the main functional steps needed for running from one RBC area to another one are the following:

   - a) Pre-announcement of the transition by the “Handing Over” RBC;

   - b) Generation of movement authorities including the border;

   - c) Announcement of the RBC transition

   - d) Termination of the session with “Handing Over” RBC;

   - e) Registration to the new GSM-R Radio Network of the GSM-R Mobile Terminal (only in case of GSM-R Radio Network) & Establishment of the radio communication session with the “Accepting” RBC;

   - f) Transfer of train supervision to the “Accepting” RBC.

### **5.15.3.2 Step by step description**

### **5.15.3.2.1 Pre-announcement**

- When the “Handing over” RBC generates a movement authority which reaches the

- border to another RBC area, it initiates the processes associated to the transition.

- The “Handing Over” RBC informs the “Accepting” RBC about the RBC/RBC transition.

### **5.15.3.2.2 Generation of MAs including the border**

- The “Handing Over” RBC is responsible for establishing the movement authority

- based on (see Figure 9)

- a) Information from the trackside equipment and interlocking of its own area (for the part of route related information up to the border),

- b) Information from the “Accepting RBC” for the part of route related information in advance of the border.

- When it is required to send a movement authority to the train, the "Handing Over"

- RBC will request from the "Accepting RBC" information needed for extending the MA in advance of the border.

### **5.15.3.2.3 Announcement**

- When the train with its max safe front end reaches the border, the ERTMS/ETCS on-

- board equipment sends a position report to the “Handing Over” RBC.

- The “Handing Over” RBC forwards the announcement information to the “Accepting”

- RBC.

<!-- end of page 73 -->

**5.15.3.2.4 Termination of the session with “Handing Over” RBC**

- When the min safe rear end of the train passes the location of the border, the on-

- board equipment sends a position report to the “Handing Over” RBC.

   - It is a trackside implementation issue to decide when it is appropriate to send the

   - session termination order to the on-board equipment, e.g. when the “Handing Over” RBC receives a position report and detects that the minimum safe rear end of the train has passed the border, or after the RBC has received a train integrity confirmation indicating that the confirmed rear end of the train has passed the border.

**5.15.3.2.5 Registration to the new GSM-R Radio Network of the GSM-R Mobile Terminal (only in case of GSM-R Radio Network change) & Establishment of the radio communication session with “Accepting” RBC**

- When the ERTMS/ETCS on-board equipment receives the session termination order

- from the “Handing Over” RBC, it terminates the session with the “Handing over” RBC and opens a session with the “Accepting” RBC (refer to chapter 3, management of radio communication).

   - In case of RBC/RBC handover including a GSM-R Radio Network change towards a

   - GSM-R only area or an FRMCS+GSM-R area while the RBC transition order does not relate to an RBC interfaced with FRMCS only and if the communication session with the “Handing Over” RBC is established through GSM-R (see t4, t7, t11, t12 in 5.15.1.2.1): as soon as the session with the "Handing Over" RBC is terminated, the registration to the new GSM-R Radio Network of the GSM-R Mobile Terminal is enforced by the ERTMS/ETCS on-board equipment prior to the opening of a session with the “Accepting” RBC (refer to chapter 3, management of radio communication).

**5.15.3.2.6 Transfer of train supervision to “Accepting” RBC**

- When the ERTMS/ETCS on-board equipment has established a communication

- session with the “Accepting” RBC and sent to the “Accepting” RBC a position report, it considers to be supervised by the “Accepting” RBC, i.e. it accepts only information received from the “Accepting” RBC.

- When the “Accepting” RBC receives a position report from the on-board and detects

- that the max safe front end has passed the border, it takes over the responsibility and informs the “Handing Over” RBC.

## **Other degraded Situations**

5.15.4.1 Note: If the “Handing Over” RBC is not able to extend the MA into the area of the “Accepting RBC”, the driver may select "override", or manually change the level to move the train into the area of the “Accepting RBC”.

5.15.4.2 Note: If the ERTMS/ETCS on-board equipment cannot open a session with the “Accepting RBC”, the train is stopped at the latest when it has reached the EOA given

<!-- end of page 74 -->

by the “Handing Over” RBC. For passing the EOA the driver may select "override", or manually change the level.

5.15.4.3 If the ERTMS/ETCS on-board equipment is not able to terminate the session with the “Handing Over” RBC: In case a communication session is established and no request to terminate the session is received from the “Handing Over” RBC within a fixed waiting time (see appendix to chapter 3, List of Fixed Value Data) after sending the position report (see 5.15.2.2.6), the position report is repeated with the fixed waiting time after each repetition. After a defined number of repetitions (see appendix to chapter 3, List of Fixed Value Data), and if no reply is received within the fixed waiting time from the last sending of the position report, the ERTMS/ETCS on-board equipment terminates the communication session.

5.15.4.4 Intentionally deleted.

# **5.16 Procedure passing a non protected Level Crossing**

## **General Requirements**

5.16.1.1 In case the LX is not protected, the ERTMS/ETCS on-board equipment (in FS, AD, LS, OS or SM mode) first supervises the LX start location as both temporary EOA and SvL, with no release speed (see 3.12.5.8).

5.16.1.2 The supervision of the LX start location as both temporary EOA and SvL shall be substituted by the inclusion of the LX speed restriction in the MRSP under conditions depending on whether stopping in rear of the LX start location is required or not. The conditions of this substitution are specified in 5.16.2 or 5.16.3.

5.16.1.3 The start location of the LX speed restriction depends on the substitution conditions, which are specified in 5.16.2 or 5.16.3. The end location of the LX speed restriction shall be the LX end location.

5.16.1.4 When approaching a non protected LX, the on-board equipment shall inform the driver about the status of the LX, as soon as:

   - a) either the temporary EOA or the temporary SvL related to the LX start location becomes the Most Relevant Displayed Target (see 3.13.10.4.2), or

   - b) the ERTMS/ETCS on-board equipment substitutes the supervision of the LX start location as both temporary EOA and SvL by the inclusion of the LX speed restriction in the MRSP.

5.16.1.5 Unless the information “LX is protected” is received on-board, the indication given to the driver shall be displayed as long as the train min safe front end is in rear of the LX end location.

<!-- end of page 75 -->

## **Stopping in rear of non protected LX is required**

5.16.2.1 Once the train has stopped with its estimated front end inside the stopping area, given by trackside, the ERTMS/ETCS on-board equipment shall no longer supervise the LX start location as both temporary EOA and SvL and shall immediately include the LX speed restriction in the MRSP, starting from the estimated train front end.

braking curve in FS/AD/LS/OS/SM

<!-- Start of picture text -->
d<br>speed<br>Train at standstill<br>train speed  LX Speed<br>train front end location<br>LX start location<br>Stopping Area<br>LX speed is<br>supervised<br><!-- End of picture text -->

### **Figure 10: Approaching a non protected LX with stopping required**

## **Stopping in rear of non protected LX is not required**

5.16.3.1 In case stopping in rear of the non protected LX is not required, the LX start location shall be supervised as both temporary EOA and SvL until the train reaches the location of the braking to target Permitted speed supervision limit calculated for the LX speed (see 3.13.9.3.5.11&12 for the calculation of this location).

5.16.3.2 As soon as the estimated or the max safe front end (depending whether the most restrictive SBI supervision limit at LX speed is the SBI1 or the SBI2, see 3.13.9.3.5.11) has reached the location of the Permitted speed supervision limit calculated for the LX speed and the train speed is below or equal to the LX speed, the ERTMS/ETCS onboard equipment shall no longer supervise the LX start location as both temporary EOA and SvL and shall immediately include the LX speed restriction in the MRSP, starting from the location of the Permitted speed supervision limit calculated for the LX speed.

<!-- end of page 76 -->

<!-- Start of picture text -->
braking curve in FS/AD/LS/OS/SM<br>d<br>Permitted speed supervision limit at LX speed<br>speed<br>LX Speed<br>train speed<br>train front end location<br>Beginning of the<br>LX area<br>LX speed is<br>supervised<br><!-- End of picture text -->

### **Figure 11: Approaching a non protected LX with stopping not required**

5.16.3.3 Note: A braking curve to zero, instead of a braking curve to the LX speed at the LX start location, will ensure that the train is able to stop before the start location of the level crossing, in case this latter is not free for the train to pass. Close to the level crossing it is then the responsibility of the driver to proceed or not with LX speed as a maximum.

# **5.17 Changing Train Data from sources different from the driver**

## **Introduction**

5.17.1.1 When valid Train Data is stored on-board, input information acquired from ERTMS/ETCS external sources different from the driver may affect some of the Train Data, depending on the type of train (e.g. tilting input information from tilting external device may affect the train category and the loading gauge).

5.17.1.2 The procedure here below describes the necessary steps performed by the ERTMS/ETCS on-board equipment from the detection of an input information change on an external interface, to the effective encountering of the Train Data change by the ERTMS/ETCS on-board equipment.

5.17.1.3 This procedure is not applicable for trains running in RV mode: on leaving RV mode, the Train Data will always be invalidated or deleted.

<!-- end of page 77 -->

## **Table of requirements for “Changing Train Data from sources different from the driver” procedure**

5.17.2.1 The ID numbers in the table are used for the representation of the procedure in form of a flow chart in section 5.17.3.

### **5.17.2.2 Procedure**

|**ID #**|**Requirements**|
|---|---|
|**S0**|The ERTMS/ETCS on-board equipment is in one of the following modes: FS, AD, LS,<br>OS, SR, SB, SN, UN, TR, PT and valid Train Data is stored on-board.<br>If a change of input information, which affects Train Data, is detected on an<br>ERTMS/ETCS on-board external interface**(E0)**, the process shall go to**D0**|
|**D0**|According to the specific train implementation, Train Data which is/are affected by the<br>change of input information from the ERTMS/ETCS on-board equipment external<br>interface may require validation:<br>•<br>If the affected data requires driver validation, the process shall go to**D2**<br>•<br>If the affected data does not require driver validation, the process shall go to**D1**|
|**D1**|Depending on the type of Train Data which is/are affected by the change of input<br>information from the ERTMS/ETCS on-board external interface, the following shall<br>apply:<br>•<br>If the impacted Train Data regards either train category, or axle load category,<br>or traction system(s) accepted by the engine, or loading gauge, the process shall<br>go to**D3**<br>•<br>If the impacted Train Data regards any other type of Train Data, the process<br>shall go to**A1**|
|**D3**|Depending on the mode of the ERTMS/ETCS on-board equipment, the following shall<br>apply:<br>•<br>If mode is FS, AD, LS, or OS, the process shall go to**D7**<br>•<br>If mode is SB or PT, the process shall go to**A1**<br>•<br>If mode is UN, SN, SR, or TR the process shall go to**D5**|
|**D5**|The ERTMS/ETCS on-board equipment shall check whether MA and track description,<br>received from RBC, are stored on-board, in case a level 2 transition or an RBC transition<br>for a further location has been ordered:<br>•<br>If MA and track description are stored, the process shall go to**D7**<br>•<br>If MA and track description are not both stored, the process shall go to**A1**|
|**D7**|The ERTMS/ETCS on-board equipment shall check whether the train is at standstill:<br>•<br>If at standstill, the process shall go to**A1**|
||•<br>If not at standstill, the process shall go to**S2**|

<!-- end of page 78 -->

|**ID #**|**Requirements**|
|---|---|
|**A1**|The ERTMS/ETCS on-board equipment shall inform the driver that Train Data has been<br>changed and the process shall go to**A7**|
|**S2**|The ERTMS/ETCS on-board equipment shall command the service brake, inform the<br>driver about the reason of this brake command and waits for the train to be at standstill;<br>when the ERTMS/ETCS on-board equipment detects that the train is at standstill**(E2)**,<br>the process shall go to**S3**|
|**S3**|The ERTMS/ETCS on-board equipment shall request the driver to acknowledge the<br>brake command; when the driver acknowledges**(E3)**, the process shall go to**A5**|
|**A5**|The ERTMS/ETCS on-board equipment shall release the brake command and the<br>process shall go to**A7**|
|**D2**|Depending on the mode of the ERTMS/ETCS on-board equipment, the following shall<br>apply:<br>•<br>If mode is FS, AD, LS, OS, SR, SB, SN or UN the process shall go to**D9**<br>•<br>If mode is TR or PT, the process shall go to**S1**|
|**S1**|The ERTMS/ETCS on-board equipment shall wait for the end of the Train Trip<br>procedure (see section 5.11). When the Train Trip procedure is exited**(E1)**(i.e. there is<br>a mode transition to another mode than TR, PT), the process shall go to**D4**|
|**D4**|Depending on the mode of the ERTMS/ETCS on-board equipment, the following shall<br>apply:<br>•<br>If mode is FS, LS, OS, SR, SN or UN the process shall go to**S6**<br>•<br>If mode is SH, the Train Data are invalidated and the process shall**END**|
|**D9**|The ERTMS/ETCS on-board equipment shall check whether the train is at standstill:<br>•<br>If at standstill, the process shall go to**S6**<br>•<br>If not at standstill, the process shall go to**S4**|
|**S4**|The ERTMS/ETCS on-board equipment shall command the service brake, inform the<br>driver about the reason of this brake command and wait for the train to be at standstill;<br>when the ERTMS/ETCS on-board equipment detects that the train is at standstill**(E4)**,<br>the process shall go to**S5**|
|**S5**|The ERTMS/ETCS on-board equipment shall request the driver to acknowledge the<br>brake command; when the driver acknowledges**(E5)**, the process shall go to**A6**|
|**A6**|The ERTMS/ETCS on-board equipment shall release the brake command and the<br>process shall go to**S6**|
|**S6**|The ERTMS/ETCS on-board equipment shall request the driver to re-enter or re-validate<br>the Train Data.<br>Once Train Data is validated**(E6)**, the process shall go to**A7**|

<!-- end of page 79 -->

|**ID #**|**Requirements**|
|---|---|
|**A7**|The ERTMS/ETCS on-board equipment shall consider the Train Data as being changed<br>and shall apply, when relevant, the requirements regarding change of Train Data (refer<br>to clauses 3.18.3.4, 3.18.3.7 and 3.18.3.8).|
||The process shall**END**.|

## **Flowchart**

5.17.3.1 The ID numbers in the flowchart refer to the ID numbers of the table in section 5.17.2.

<!-- end of page 80 -->

<!-- Start of picture text -->
S0 :<br>Mode is FS, AD, LS, OS, SR, SB, SN, UN, TR, PT and<br>valid Train Data is stored on-board<br>E0 : New input information received<br>from external interface<br>D0 :<br>Yes Train data to be  No<br>validated by<br>driver<br>TR/PT D2 : D1 : others<br>Mode Train Data<br>impacted<br>Train category, Axle load,<br>FS/AD/LS/OS/ Loading gauge, Traction system<br>S1 :Wait exit from  SR/SB/SN/UN<br>Train Trip<br>procedure<br>FS/AD/LS/OS D3 : SB/PT<br>E1 : Train Trip Mode<br>Procedure exited<br>UN/SN/SR/TR<br>SH D4 :<br>Mode D5 :<br>MA and track   No A1 :<br>desc from RBC<br>On-board informs driver<br>stored on-board<br>FS/LS/OS/SR/SN/UN<br>Yes<br>D9 : D7 : Yes<br>Train at  Train at<br>standstill Yes standstill<br>No No<br>S4 :On-board commands service  S2 :On-board commands service<br>brake and informs driver brake and informs driver<br>E4 : Train is at standstill E2 : Train is at standstill<br>S5 :On-board requests driver to  S3 :On-board requests driver to<br>acknowledge acknowledge<br>E5 : Driver acknowledges E3 : Driver acknowledges<br>A6 :On-board releases brake  A5 :On-board releases brake<br>command command<br>S6 :On-board requests driver to<br> re-enter/re-validate Train data<br>E6 : Train data is validated<br>A7 :On-board considers<br>Train Data as changed<br>End<br><!-- End of picture text -->

**Figure 12: Flowchart for “Changing Train Data from sources different from the driver”**

<!-- end of page 81 -->

# **5.18 Indication of Track Conditions**

## **Introduction**

5.18.1.1 This set of procedures specifies the sequences of driver indications related to the following track-conditions:

   - a) powerless section with pantograph to be lowered

   - b) powerless section with main power switch to be switched off,

   - c) non-stopping area,

   - d) radio hole,

   - e) air tightness area,

   - f) Inhibition of a defined type of brake,

   - g) tunnel stopping area,

   - h) sound horn,

   - i) change of traction system.

5.18.1.2 Note: For every procedure a figure supports the textual description. The textual description of the procedures contains reference to the figures (point B, point F,…).

## **Passing a powerless section with pantograph to be lowered**

5.18.2.1 This procedure is dealing with the announcement and indication to the driver of a powerless section with the pantograph to be lowered.

5.18.2.1.1 Intentionally deleted.

5.18.2.2 “Lower pantograph announcement” shall be displayed to the driver when the max safe front end of the train reaches a location (point C) in rear of the beginning of the powerless section (point D).

5.18.2.2.1 This location (point C) shall be determined by the ERTMS/ETCS on-board equipment taking into account the time necessary for performing the required actions and the current train speed.

5.18.2.2.2 The displayed “Lower pantograph announcement” information shall also indicate if the related functionality is executed

   - automatically, or

   - if the driver is requested to act.

      - Note: Whether the operation is automatic or manual is application dependent.

5.18.2.3 When the max safe front end of the train reaches the start location (point D) of the powerless section:

   - “Lower pantograph announcement” shall no longer be displayed to the driver,

<!-- end of page 82 -->

   - “Lowered Pantograph” information shall be displayed to the driver.

5.18.2.4 Intentionally deleted.

5.18.2.4.1 Intentionally deleted.

5.18.2.5 When the min safe front end of the train reaches the “Powerless section” end location point E):

   - “Lowered Pantograph” information shall no longer be displayed to the driver

   - “Raise pantograph” information shall be displayed to the driver.

5.18.2.5.1 The displayed “Raise pantograph” information shall also indicate if the related functionality is executed

   - automatically, or

   - if the driver is requested to act.

   - Note: Whether the operation is automatic or manual is application dependent.

5.18.2.6 The “Raise pantograph” information shall remain displayed for a fixed time (see Appendix A.3.1) after the minimum safe rear end of the train has passed the end of the “Powerless section”.

5.18.2.6.1 Note: The train front end position when this information disappears is shown as point G in the Figure 13.

<!-- Start of picture text -->
running direction<br>Display: «Lower<br>A  C  D  E  G<br>pantograph  Display: «Lowered  Display: «Raise<br>announcement»  Pantograph»  pantograph»<br>LRBG/ORBG<br>Powerless section<br>Distance to begin of powerless section  Powerless section length<br><!-- End of picture text -->

**Figure 13: Passing a powerless section with pantograph to be lowered**

## **Passing a powerless section with main power switch to be switched off**

5.18.3.1 This procedure is dealing with the announcement and indication to the driver of a powerless section with main power switch to be switched off.

<!-- end of page 83 -->

5.18.3.2 “Neutral section announcement” shall be displayed to the driver when the max safe front end of the train reaches a location (point C) in rear of the beginning of the powerless section.

5.18.3.2.1 This location (point C) shall be determined by the ERTMS/ETCS on-board equipment taking into account the time necessary for performing the required actions and the current train speed.

5.18.3.2.2 The displayed “Neutral section announcement” information shall also indicate if the related functionality is executed

   - automatically, or

   - if the driver is requested to act.

      - Note: Whether the operation is automatic or manual is application dependent.

5.18.3.3 When the max safe front end of the train reaches the starting location (point D) of the powerless section:

   - “Neutral section announcement” shall no longer be displayed to the driver,

   - “Neutral section” information shall be displayed to the driver.

5.18.3.4 When the min safe front end of the train reaches the “Powerless section” end location point E):

   - “Neutral section” information shall no longer be displayed to the driver

   - “End of Neutral section” information shall be displayed to the driver.

5.18.3.4.1 The displayed “End of Neutral section” information shall also indicate if the related functionality is executed

   - Automatically, or

   - if the driver is requested to act.

   - Note: Whether the operation is automatic or manual is application dependent.

5.18.3.5 The “End of Neutral section” information shall remain displayed for a fixed time (see Appendix A.3.1) after the minimum safe rear end of the train has passed the end of the “Powerless section”.

5.18.3.5.1 Note: The train front end position, when this information disappears is shown as point G in the Figure 14.

<!-- end of page 84 -->

<!-- Start of picture text -->
running direction<br>Display: «End of<br>Neutral section»<br>A  C  Display: «Neutral  D  Display: «Neutral  E  G<br>section announcement»<br>section»<br>LRBG/ORBG<br>Powerless section<br>Distance to begin of powerless section  Powerless section length<br><!-- End of picture text -->

**Figure 14: Passing a powerless section with main power switch to be switched off**

## **Passing a non stopping area**

5.18.4.1 This procedure is dealing with the announcement and indication to the driver of an area where stopping is not permitted.

5.18.4.2 As long as there are non stopping areas stored on-board, the ERTMS/ETCS on-board equipment shall continuously check the current speed and position of the train whether a full service brake command would stop the train within any of the stored non stopping areas. This shall be achieved taking into account for each non stopping area, two virtual SBI supervision limits (SBID and SBIG), calculated at the estimated speed from two SBD curves of which the feet are the start location of the non stopping area (point D) and a location (point G) at train length distance in advance of the end location of the non stopping area:

   - a) If the max safe front end is in rear of the first SBI supervision limit (SBID) no information related to this non stopping area shall be displayed

   - b) If the max safe front end is in advance of the first SBI supervision limit (SBID) and the min safe front end in rear of the second SBI supervision limit (SBIG), the non stopping area related information shall be displayed to the driver according to the following clauses 5.18.4.3, 5.18.4.4.

   - c) If the min safe front end is in advance of the second SBI supervision limit (SBIG), no information related to this non stopping area shall be displayed.

5.18.4.3 When the max safe front end is in rear of the start location (point D) of the non stopping area, the “Non stopping area announcement” shall be displayed to the driver.

5.18.4.4 When the max safe front end is in advance of the start location (point D) of the non stopping area:

   - “Non stopping area announcement”, if any, shall no longer be displayed

   - “Non stopping area” information shall be displayed to the driver.

<!-- end of page 85 -->

5.18.4.5 Intentionally deleted.

5.18.4.6 Note: the display of the “Non stopping area” information will always end before the min safe rear end reaches the point E, because of the condition 5.18.4.2 c).

<!-- Start of picture text -->
speed  running direction<br>SBIG<br>No display of Non Stopping Area information<br>D<br>SBID Display: «Non Stopping  E  G<br>Area announcement»  Train speed<br>A<br>Display: «Non<br>Stopping Area»<br>No display of Non Stopping Area information<br>Non Stopping Area<br>LRBG/ORBG<br>Distance to begin of Non Stopping Area   Non Stopping Area length  Train length<br><!-- End of picture text -->

**Figure 15: Passing a non stopping area**

## **Passing a radio hole**

5.18.5.1 This procedure is dealing with the automatic deactivation of the safe radio connection supervision inside an announced radio hole area.

5.18.5.2 When the engine front/rear end, depending on whether the train orientation is the same as/opposite to the active cab, passes the start location (point D) of the radio hole area, the “radio hole” indication shall be displayed to the driver.

5.18.5.3 When the engine rear/front end ,depending on whether the train orientation is the same as/opposite to the active cab, passes the end location (point E) of the radio hole area, the “radio hole” indication to the driver shall be removed.

<!-- end of page 86 -->

<!-- Start of picture text -->
running direction<br>A  D  E<br>Display: «radio hole»<br>LRBG/ORBG<br>Radio hole area<br>Distance to begin of radio hole  Radio hole length<br><!-- End of picture text -->

**Figure 16: Passing an announced radio hole**

## **Passing an “air tightness” area**

5.18.6.1 This procedure is dealing with the announcement and indication to the driver of an air tightness area.

5.18.6.2 “Close air conditioning intake announcement” information shall be displayed to the driver when the max safe front end of the train reaches a location (point C) in rear of the beginning of the “air tightness” area.

5.18.6.2.1 This location (point C) shall be determined by the ERTMS/ETCS on-board equipment taking into account the time necessary for performing the required actions and the current train speed.

5.18.6.2.2 The displayed “Close air conditioning intake announcement” information shall also indicate if the related functionality is executed

   - automatically, or

   - if the driver is requested to act.

      - Note: Whether the operation is automatic or manual is application dependent.

5.18.6.3 When the max safe front end of the train reaches the start location (point D) of the air tightness area:

   - “Close air conditioning intake announcement” information shall no longer be displayed.

   - “Air conditioning intake closed” information shall be displayed to the driver.

5.18.6.4 When the min safe rear end of the train reaches the end location (point E) of the air tightness area:

   - “Air conditioning intake closed” information shall no longer be displayed;

   - “Open air conditioning intake” information shall be displayed to the driver.

<!-- end of page 87 -->

5.18.6.4.1 The displayed “Open air conditioning intake” information shall also indicate if the related functionality is executed

   - automatically, or

   - If the driver is requested to act.

   - Note: Whether the operation is automatic or manual is application dependent.

5.18.6.5 The “Open Air Conditioning intake” information shall remain displayed for a fixed time (see Appendix A.3.1) after the minimum safe rear end of the train has passed the end of the “Air tightness area”.

5.18.6.5.1 Note: The train front end position, when this information disappears, is shown as point G in the Figure 17.

<!-- Start of picture text -->
running direction<br>Display « Air<br>Display: « Close air<br>A  C  conditioning intake  D  conditioning intake  E  Display: «Open air  G<br>announcement »  closed»  conditioning intake»<br>LRBG/ORBG<br>Air tightness area<br>Distance to begin of air tightness area  Air tightness length<br><!-- End of picture text -->

**Figure 17: Passing an air tightness area**

## **Inhibition of a defined type of brake**

5.18.7.1 This procedure is dealing with the announcement and indication to the driver of the inhibition of defined types of brake systems.

5.18.7.2 The procedure shows the case of the regenerative brake. Regarding eddy current brake and magnetic shoe brake, the procedure is identical except that the displayed indications refer respectively eddy current brake or magnetic shoe brake.

5.18.7.3 “Inhibition of Regenerative Brake announcement” information shall be displayed to the driver when the max safe front end of the train reaches a location (Point C) in rear of the beginning of the regenerative brake inhibition area.

5.18.7.3.1 The displayed “Inhibition of Regenerative Brake announcement” information shall also indicate if the related functionality is executed

   - automatically, or

   - if the driver is requested to act.

<!-- end of page 88 -->

Note: Whether the operation is automatic or manual is application dependent.

5.18.7.3.2 This location (point C) shall be determined by the On-Board equipment taking into account the time necessary for performing the required actions and the current train speed.

5.18.7.4 When the max safe front end of the train reaches the start location (point D) of the regenerative brake inhibition area:

   - Indication “Inhibition of Regenerative Brake announcement” shall no longer be displayed,

   - Indication “Inhibition of Regenerative Brake” shall be displayed to the driver.

5.18.7.5 When the min safe rear end of the train reaches the end location (point E) of the regenerative brake inhibition area the indication “Inhibition of Regenerative Brake” information shall no longer be displayed.

<!-- Start of picture text -->
running direction<br>A  C  Display:  «Inhibition of  D  Display: «Inhibition of  E<br>Regenerative Brake  Regenerative Brake»<br>announcement»<br>LRBG/ORBG<br>Brake inhibition area<br>Distance to begin of brake inhibition area  Brake inhibition length<br><!-- End of picture text -->

**Figure 18: Passing an area where Regenerative Brake shall be inhibited**

## **Advising a tunnel stopping area**

5.18.8.1 This procedure is dealing with the indication to the driver of an area under a tunnel where stopping is permitted, and suitable escaping paths are provided.

5.18.8.1.1 Note: the tunnel stopping areas are designed in such a way that the passengers can step out, use a walkway along the track and reach the safe area, taking into account the longest admissible train in the tunnel stopped with its front end within the tunnel stopping area.

5.18.8.2 On driver request, the ERTMS/ETCS on-board equipment shall enable/disable the display of the tunnel stopping area related information (initial state: disabled).

5.18.8.3 As long as the display of the tunnel stopping areas is enabled (point C) and there are tunnel stopping areas stored on-board, the ERTMS/ETCS on-board equipment shall continuously check the current speed and position of the train to determine whether the

<!-- end of page 89 -->

driver can stop the train with the full service brake before reaching the end of the closest tunnel stopping area. This shall be achieved taking into account a virtual Permitted supervision limit (with no contribution of the GUI curve, if any), calculated at the estimated speed from an SBD curve of which the foot is the end location of the tunnel stopping area:

   - a) If the train front end is in rear of the Permitted supervision limit, the tunnel stopping area related information shall be displayed to the driver.

   - b) If the train front end is in advance of the Permitted supervision limit, no information related to this tunnel stopping area shall be displayed and the next tunnel stopping area stored on-board, if any, shall be checked.

5.18.8.4 Before the train reaches the start location (point D) of the tunnel stopping area, the “tunnel stopping area announcement” shall be displayed to the driver. This shall include the indication of the remaining distance to the start location of the tunnel stopping area.

5.18.8.5 When the train front end reaches the start location (point D) of the tunnel stopping area:

   - “Tunnel stopping area announcement” shall no longer be displayed

   - “Tunnel stopping area” information shall be displayed to the driver.

5.18.8.6 Note: the display of the “tunnel stopping area” information will always end before the point E is reached, because of the condition 5.18.8.3 b).

<!-- Start of picture text -->
speed<br>No display of Tunnel Stopping Area  running direction running direction<br>information<br>D  E<br>?<br>A  C  Display: «Tunnel Stopping<br>Area announcement»  Display: «Tunnel<br>Stopping Area»<br>LRBG/ORBG<br>Tunnel Stopping Area<br>Tunnel Stopping Area<br>display toggle on<br>Tunnel Stopping Area length<br>Distance to begin of Tunnel Stopping Area<br><!-- End of picture text -->

**Figure 19: Advising a tunnel stopping area**

## **Sounding the horn**

5.18.9.1 This procedure is dealing with the indication to the driver of a request to sound the horn.

5.18.9.2 “Sound horn” shall be displayed to the driver when the estimated front end of the train reaches a location (point C) in rear of the beginning of the “sound horn” area (point D).

<!-- end of page 90 -->

5.18.9.2.1 This location (point C) shall be determined by the ERTMS/ETCS on-board equipment taking into account the time necessary for the driver to perform the required action (see Appendix A.3.1) and the current train speed.

5.18.9.3 When the estimated front end of the train reaches the end location (point E) of the “sound horn” area, the indication “Sound horn” information shall no longer be displayed.

5.18.9.4 Note: In order not to encourage the driver to stop sounding the horn too early, the track condition “sound horn” is defined as an area so that the display of the indication “Sound horn” continues during a certain distance sent by trackside (i.e. until point E), after the theoretical location of the board on the line (i.e. point D).

<!-- Start of picture text -->
running direction<br>A  C  D  E<br>Display: «Sound Horn»<br>LRBG/ORBG<br>Sound Horn Area<br>Sound Horn length<br>Distance to begin of Sound Horn area<br><!-- End of picture text -->

**Figure 20: Sounding the Horn**

## **Changing the traction system**

5.18.10.1 This procedure is dealing with the announcement and indication to the driver of a change of traction system.

5.18.10.2 “Change of traction system announcement” shall be displayed to the driver when the max safe front end of the train reaches a location (point C) in rear of the location of change of traction system (point F).

5.18.10.3 This location (point C) shall be determined by the ERTMS/ETCS on-board equipment taking into account the time necessary for performing the required actions and the current train speed.

5.18.10.4 The displayed “Change of traction system announcement” information shall also indicate if the related functionality is executed

   - automatically, or

   - if the driver is requested to act.

5.18.10.4.1 Note: Whether the operation is automatic or manual is application dependent.

<!-- end of page 91 -->

5.18.10.5 When the max safe front end of the train reaches the “Change of traction system” location (point F):

   - the “Change of traction system announcement” information shall no longer be displayed to the driver,

   - the “New traction system” information shall be displayed to the driver.

5.18.10.6 The “New traction system” information shall remain displayed for a fixed time (see Appendix A.3.1) after the minimum safe rear end of the train has passed the “Change of traction system” location (point F).

5.18.10.6.1 Note: The train front end position when this information disappears is shown as point G in the Figure 21.

<!-- Start of picture text -->
running direction<br>Display: «Change of  F<br>A  C  G<br>traction system  Display: «New traction system»<br>announcement»<br>LRBG/ORBG<br>Distance to change of traction system<br><!-- End of picture text -->

**Figure 21: Changing the traction system**

<!-- end of page 92 -->

# **5.19 Procedure Limited Supervision**

## **General Requirements**

5.19.1.1 The order to switch to Limited Supervision mode shall be given by means of a mode profile.

5.19.1.2 An acknowledgement for running in Limited Supervision mode shall be requested from the driver. The conditions of the acknowledgement are specified below.

## **Limited Supervision is requested for current location (from modes different from Stand By and Post Trip)**

5.19.2.1 In a level 1 area, the beginning of the Limited Supervision area can be the balise (group) that gives the Mode Profile. When the train passes the balise group and receives this information, the ERTMS/ETCS on-board equipment shall immediately switch to Limited Supervision mode.

5.19.2.2 In a level 2 area, the ERTMS/ETCS on-board equipment can receive a mode profile giving a Limited Supervision area which the train position confidence interval already overlaps. If starting from the min safe front end of the train this Limited Supervision area is the furthest area that the train position confidence interval overlaps within the mode profile, the ERTMS/ETCS on-board equipment shall immediately switch to Limited Supervision mode.

5.19.2.3 The driver must acknowledge the Limited Supervision mode. A request of acknowledgement shall be displayed to the driver.

5.19.2.4 If the driver has not acknowledged within the driver acknowledgement time (refer to Appendix A.3.1) after the change to LS mode, the service brake command shall be triggered.

5.19.2.5 Note: Once in Limited Supervision mode, the speed supervision is such that the train speed cannot exceed the LS mode speed limit. If, when entering the Limited Supervision mode, the train speed was higher than the LS mode speed limit (because a higher speed was allowed in Full Supervision mode, in Automatic Driving mode, in On Sight mode or in Staff Responsible mode) then a service/emergency brake command could be immediately triggered, independently of the acknowledgement of the driver, but because of the LS supervision (see Figure 22).

<!-- end of page 93 -->

<!-- Start of picture text -->
Transition to LS mode triggers<br>SB/EB command<br>speed<br>permitted speed  (even if driver acknowledges<br>in previous mode  within 5s)<br>Brake command revoked<br>(conditions see SRS chapter 3,<br>Speed & Distance Monitoring)<br>train speed<br>permitted speed in LS<br>mode<br> Location of: LS request for   location<br>current location<br><!-- End of picture text -->

### **Figure 22: Train enters LS area with too high speed**

5.19.2.6 Note: This sharp brake reaction can be avoided in Full Supervision, Automatic Driving or On Sight mode by giving with the previous MA an EOA (or a LOA = LS mode speed limit) at the location of transition to Limited Supervision mode.

5.19.2.7 If the ERTMS/ETCS on-board equipment is already in LS mode when receiving the LS mode profile, no further acknowledgement shall be requested from the driver.

## **Limited Supervision is requested for a further location**

5.19.3.1 The beginning of the Limited Supervision area can be a location that the train has not reached yet. This occurs when:

   - a) In a level 1 area, a balise group gives a Mode Profile with an Limited Supervision area that is located at a further location.

   - b) In a level 2 area, the RBC gives a Mode Profile with an Limited Supervision area that is located at a further location.

5.19.3.2 A request for acknowledgement shall be displayed to the driver when the following conditions are fulfilled:

   - a) The distance between the estimated front end of the train and the beginning of Limited Supervision area is shorter than a value, contained in the mode profile.

   - b) The speed is equal to or lower than the Limited Supervision mode speed limit (national value, or value given in the mode profile).

   - c) The current mode is not Limited Supervision

- 5.19.3.3

   - Note: The first 2 conditions define the “rectangle of acknowledgement”.

5.19.3.4 Once the acknowledgement request is displayed, it shall not be taken back if the train leaves the “rectangle of acknowledgement” (for example: because the train accelerates).

5.19.3.5 Intentionally deleted.

<!-- end of page 94 -->

5.19.3.6 When the driver acknowledges the Limited Supervision mode, the ERTMS/ETCS onboard equipment shall immediately switch to the Limited Supervision mode.

<!-- Start of picture text -->
braking curve e.g. in FS<br>d<br>acknowledge request is<br>speed  displayed to the driver<br>driver acknowledges<br>train speed<br>Permitted Speed<br>In LS mode<br>location<br>Beginning of the<br>Acknowledgement<br> Limited Supervision area<br>Area<br>Transition to<br>Limited Supervision mode<br><!-- End of picture text -->

### **Figure 23: Transition to LS mode after driver acknowledgement**

5.19.3.7 If the max safe front end of the train reaches the beginning of the Limited Supervision area according the mode profile and the driver has not yet acknowledged, the ERTMS/ETCS on-board equipment shall switch immediately to LS mode and a request for acknowledgement shall be displayed to the driver (refer to SRS chapter 4, transitions between modes).

5.19.3.8 If, in this case, the driver does not acknowledge within the driver acknowledgement time (refer to Appendix A.3.1) after the change to LS mode, the service brake command shall be triggered.

## **Limited Supervision from Unfitted or SN mode**

5.19.4.1 The mode profile with regards to an LS area is only evaluated in level 1,2, although the mode profile may have been received in level 0 (Unfitted mode) or NTC (SN mode). A transition to Limited Supervision mode can therefore earliest occur at a transition of level: from level 0 or NTC to level 1 or 2.

5.19.4.2 Requirements about the acknowledgement in section 5.19.2 shall apply.

## **Limited Supervision from Stand By or Post Trip mode**

5.19.5.1 When performing a SoM or a Train Trip procedure and when the current level is 2, the ERTMS/ETCS on-board equipment can receive a mode profile giving an Limited Supervision area which the train position confidence interval already overlaps. If starting

<!-- end of page 95 -->

from the min safe front end of the train this Limited Supervision area is the furthest area that the train position confidence interval overlaps within the mode profile, the ERTMS/ETCS on-board equipment shall first require an LS acknowledgement from the driver.

5.19.5.2 When the driver acknowledges, the ERTMS/ETCS on-board equipment shall perform the transition to Limited Supervision mode.

## **Exit of Limited Supervision mode**

**5.19.6.1 General rule**

5.19.6.1.1 The ERTMS/ETCS on-board equipment shall exit the Limited Supervision mode when the min safe front end of the train passes the end of the Limited supervision area.

**5.19.6.2 First case: The Limited supervision area ends at the EOA/LOA of the current MA**

5.19.6.2.1 This occurs when the end of the Limited Supervision area that is given by the Mode Profile has the same location as the EOA/LOA of the related MA.

5.19.6.2.2 In this case, the train must receive a new Movement Authority to be able to exit the Limited Supervision area.

**5.19.6.3 Second case: The Limited Supervision area ends before the EOA/LOA of the current MA**

5.19.6.3.1 In this case, the current Movement Authority already allows the train to exit the Limited Supervision area.

5.19.6.3.2 When exiting the Limited Supervision area, the ERTMS/ETCS on-board equipment switches either to Full Supervision, On Sight or to Shunting mode (refer to SRS chapter 4, transitions between modes).

<!-- end of page 96 -->

## **Flowchart**

<!-- Start of picture text -->
mode is FS, AD, LS, OS,<br>SR, SB, PT, UN or SN<br>A mode profile for LS area<br>has been received and is used<br>current location (train<br>position confidence  further location  Transition to FS/OS mode<br>interval overlaps LS  LS area vs  (max safe front  (if not yet in one of<br>area, which is the  train position  end in rear of LS  FS/AD/OS)<br>furthest one)  area)<br>Max safe front overpasses<br>begin of LS area  - Start of LS mode profile<br>LS  Mode  SB,PT  supervised as temporary EoA<br>- Waiting<br>estimated front and speed in<br>acknowledgement window<br>FS,AD,OS,SR,UN,SN<br>- acknowledgement is<br>Transition to  requested to driver<br>LS mode  - Waiting for driver ackno<br>Max safe front overpasses<br>begin of LS area<br>Driver acknowledges<br>Transition to<br>- acknowledgement is<br>Driver acknowledges  LS mode<br>requested to driver  within 5sec<br>- Waiting for driver ackno<br>5 sec are elapsed &<br>no ack by driver<br>Service brake command<br>until driver acknowledges<br><!-- End of picture text -->

**Figure 24: Flowchart for “Limited Supervision”**

<!-- end of page 97 -->

# **5.20 Generation of Track Conditions related information to an ERTMS/ETCS external function**

## **Introduction**

5.20.1.1 This set of procedures specifies the information generated by the ERTMS/ETCS onboard equipment to an ERTMS/ETCS external function in relation to the following trackconditions:

   - a) powerless section with pantograph to be lowered,

   - b) powerless section with main power switch to be switched off,

   - c) passing an “air tightness” area,

   - d) inhibition of a defined type of brake,

   - e) change of traction system,

   - f) change of allowed current consumption,

g) station platform.

5.20.1.2 In the following sections, the remaining distance from the concerned train end to the concerned track condition location shall be counted positive when the train end is in rear of the location and shall be counted negative when the train end is in advance of the location.

## **Passing a powerless section with pantograph to be lowered**

5.20.2.1 This procedure is dealing with the generation of the information related to a powerless section with the pantograph to be lowered.

5.20.2.2 The ERTMS/ETCS on-board equipment shall start the generation of the information to the ERTMS/ETCS external function when the max safe front end of the train reaches the point C in rear of the start location of the powerless section (see 5.18.2.2.1 for the definition of point C).

5.20.2.3 When the min safe rear end of the train is in rear of the start location (point D) of the powerless section, the ERTMS/ETCS on-board equipment shall provide the following information to the ERTMS/ETCS external function:

   - the remaining distance from the max safe front end of the train to the start location (point D) of the powerless section

   - the remaining distance from the min safe front end of the train to the end location (point E) of the powerless section

5.20.2.4 When the min safe rear end of the train reaches the start location (point D) of the powerless section, the remaining distance from the max safe front end of the train to point D shall no longer be generated. The remaining distance from the min safe front end

<!-- end of page 98 -->

of the train to the end location (point E) of the powerless section shall continue to be generated.

5.20.2.5 When the min safe rear end of the train reaches the end location (point E) of the powerless section, the remaining distance from the min safe front end of the train to point E shall no longer be generated.

5.20.2.6 Note: The remaining distance from the train max safe front end to point D and the remaining distance from the train min safe front end to point E are generated until the min safe rear end passes respectively the point D and the point E to allow the ERTMS/ETCS external function to manage each pantograph individually assuming that this function knows the distance between each pantograph and the train front end.

<!-- Start of picture text -->
running direction<br>A  Generate the remaining distance to point D  Generate the remaining<br>and the remaining distance to point E  distance to point E<br>C<br>D  E<br>LRBG/ORBG<br>Powerless section<br>Distance to start of powerless section  Powerless section length<br><!-- End of picture text -->

### **Figure 25: Generation of the information to an ERTMS/ETCS external function for a supervision of powerless section with pantograph to be lowered**

5.20.2.7 Note: When resuming the initial state or any other reason leads to the shortening of a powerless section with pantograph to be lowered, the ERTMS/ETCS on-board equipment considers the new end location (point E) of the powerless section for the calculation of the remaining distance from the min safe front end of the train to the point E.

5.20.2.8 If resuming the initial state or any other reason leads to the deletion of the powerless section, the ERTMS/ETCS on-board equipment shall stop providing information related to this powerless section to the ERTMS/ETCS external function.

## **Passing a powerless section with main power switch to be switched off**

5.20.3.1 This procedure is dealing with the generation of the information related to a powerless section with main power switch to be switched off.

5.20.3.2 The ERTMS/ETCS on-board equipment shall start the generation of the information to the ERTMS/ETCS external function when the max safe front end of the train reaches the

<!-- end of page 99 -->

point C in rear of the start location of the powerless section (see 5.18.3.2.1 for the definition of point C).

5.20.3.3 When the min safe rear end of the train is in rear of the start location (point D) of the powerless section, the ERTMS/ETCS on-board equipment shall provide the following information to the ERTMS/ETCS external function:

   - the remaining distance from the max safe front end of the train to the start location (point D) of the powerless section

   - the remaining distance from the min safe front end of the train to the end location (point E) of the powerless section

5.20.3.4 When the min safe rear end of the train reaches the start location (point D) of the powerless section, the remaining distance from the max safe front end of the train to point D shall no longer be generated. The remaining distance from the min safe front end of the train to the end location (point E) of the powerless section shall continue to be generated.

5.20.3.5 When the min safe rear end of the train reaches the end location (point E) of the powerless section, the remaining distance from the min safe front end of the train to point E shall no longer be generated.

5.20.3.6 Note: The remaining distance from the train max safe front end to point D and the remaining distance from the train min safe front end to point E are generated until the min safe rear end passes respectively the point D and the point E to allow the ERTMS/ETCS external function to manage the main power switch of each vehicle individually assuming that this function knows the distance between each vehicle and the train front end.

<!-- Start of picture text -->
running direction<br>A  Generate the remaining distance to point D  Generate the remaining<br>and the remaining distance to point E  distance to point E<br>C  D  E<br>LRBG/ORBG<br>Powerless section<br>Distance to start of powerless section  Powerless section length<br><!-- End of picture text -->

### **Figure 26: Generation of the information to an ERTMS/ETCS external function for a supervision of powerless section with main power switch to be switched off**

5.20.3.7 Note: When resuming the initial state or any other reason leads to the shortening of a powerless section with main power switch to be switched off, the ERTMS/ETCS onboard equipment considers the new end location (point E) of the powerless section for

<!-- end of page 100 -->

the calculation of the remaining distance from the min safe front end of the train to the point E.

5.20.3.8 If resuming the initial state or any other reason leads to the deletion of the powerless section, the ERTMS/ETCS on-board equipment shall stop providing information related to this powerless section to the ERTMS/ETCS external function.

## **Passing an “air tightness” area**

5.20.4.1 This procedure is dealing with the generation of the information related to an air tightness area.

5.20.4.2 The ERTMS/ETCS on-board equipment shall start the generation of the information to the ERTMS/ETCS external function when the max safe front end of the train reaches the point C in rear of the start location of the air tightness area (see 5.18.6.2.1 for the definition of point C).

5.20.4.3 When the max safe front end of the train is in rear of the start location (point D) of the air tightness area, the ERTMS/ETCS on-board equipment shall provide the following information to the ERTMS/ETCS external function:

   - the remaining distance from the max safe front end of the train to the start location (point D) of the air tightness area

   - the remaining distance from the min safe rear end of the train to the end location (point E) of the air tightness area

5.20.4.4 When the max safe front end of the train reaches the start location (point D) of the air tightness area, the remaining distance from the max safe front end of the train to point D shall no longer be generated. The remaining distance from the min safe rear end of the train to the end location (point E) of the air tightness area shall continue to be generated.

5.20.4.5 When the min safe rear end of the train reaches the end location (point E) of the air tightness area, the remaining distance from the min safe rear end of the train to point E shall no longer be generated.

<!-- end of page 101 -->

<!-- Start of picture text -->
running direction<br>Generate the remaining distance to point E<br>Generate the remaining distance to point D<br>A  and the remaining distance to point E<br>C  D  E<br>LRBG/ORBG<br>Air tightness area<br>Distance to start of air tightness area  Air tightness area length<br><!-- End of picture text -->

### **Figure 27: Generation of the information to an ERTMS/ETCS external function for an air tightness area**

5.20.4.6 Note: When resuming the initial state or any other reason leads to the shortening of an air tightness area, the ERTMS/ETCS on-board equipment considers the new end location (point E) of the air tightness area for the calculation of the remaining distance from the min safe rear end of the train to the point E.

5.20.4.7 If resuming the initial state or any other reason leads to the deletion of the air tightness area, the ERTMS/ETCS on-board equipment shall stop providing information related to this air tightness area to the ERTMS/ETCS external function.

## **Inhibition of a defined type of brake**

5.20.5.1 This procedure is dealing with the generation of the information related to the inhibition of defined types of brake systems.

5.20.5.2 The procedure shows the case of the regenerative brake. Regarding eddy current brake and magnetic shoe brake, the procedure is identical except that the generated information refers to respectively eddy current brake or magnetic shoe brake.

5.20.5.3 The ERTMS/ETCS on-board equipment shall start the generation of the information to the ERTMS/ETCS external function when the max safe front end of the train reaches the point C in rear of the start location of the regenerative brake inhibition area (see 5.18.7.3.2 for the definition of point C).

5.20.5.4 When the max safe front end of the train is in rear of the start location (point D) of the regenerative brake inhibition area, the ERTMS/ETCS on-board equipment shall provide the following information to the ERTMS/ETCS external function:

   - the remaining distance from the max safe front end of the train to the start location (point D) of the regenerative brake inhibition area

   - the remaining distance from the min safe rear end of the train to the end location (point E) of the regenerative brake inhibition area

<!-- end of page 102 -->

5.20.5.5 When the max safe front end of the train reaches the start location (point D) of the regenerative brake inhibition area, the remaining distance from the max safe front end of the train to point D shall no longer be generated. The remaining distance from the min safe rear end of the train to the end location (point E) of the regenerative brake inhibition area shall continue to be generated.

5.20.5.6 When the min safe rear end of the train reaches the end location (point E) of the regenerative brake inhibition area, the remaining distance from the min safe rear end of the train to point E shall no longer be generated.

<!-- Start of picture text -->
running direction<br>Generate the remaining distance to point E<br>Generate the remaining distance to point D<br>A  and the remaining distance to point E<br>C  D  E<br>LRBG/ORBG<br>Regenerative brake inhibition area<br>Distance to start of regenerative brake inhibition area  Regenerative brake inhibition area length<br><!-- End of picture text -->

### **Figure 28: Generation of the information to an ERTMS/ETCS external function for a supervision of regenerative brake inhibition area**

5.20.5.7 Note: When resuming the initial state or any other reason leads to the shortening of a regenerative brake inhibition area, the ERTMS/ETCS on-board equipment considers the new end location (point E) of the regenerative brake inhibition area for the calculation of the remaining distance from the min safe rear end of the train to the point E.

5.20.5.8 If resuming the initial state or any other reason leads to the deletion of the regenerative brake inhibition area, the ERTMS/ETCS on-board equipment shall stop providing information related to this regenerative brake inhibition area to the ERTMS/ETCS external function.

## **Changing the traction system**

5.20.6.1 This procedure is dealing with the generation of the information related to a change of traction system.

5.20.6.2 The ERTMS/ETCS on-board equipment shall start the generation of the information to the ERTMS/ETCS external function when the max safe front end of the train reaches the point C in rear of the location of change of traction system (see 5.18.10.3 for the definition of point C).

<!-- end of page 103 -->

5.20.6.3 When the min safe rear end of the train is in rear of the location of change of traction system (point F), the ERTMS/ETCS on-board equipment shall provide the following information to the ERTMS/ETCS external function:

   - the remaining distance from the max safe front end of the train to the location of change of traction system (point F)

   - the identity of the new traction system

5.20.6.4 When the min safe rear end of the train reaches the location of change of traction system (point F), the remaining distance from the max safe front end of the train to point F and the identity of the new traction system shall no longer be generated.

5.20.6.5 Note: The remaining distance from the train max safe front end to point F is generated until the min safe rear end passes the point F to allow the ERTMS/ETCS external function, in case the change of traction system involves several pantographs, to manage each pantograph individually assuming that this function knows the distance between each pantograph and the train front end.

<!-- Start of picture text -->
running direction<br>Generate the remaining distance to point F<br>A  and the identity of the new traction system<br>C  F<br>LRBG/ORBG<br>Distance to change of traction system<br><!-- End of picture text -->

### **Figure 29: Generation of the information to an ERTMS/ETCS external function for a supervision of change of traction system**

5.20.6.6 If resuming the initial state or any other reason leads to the deletion of the change of traction system, the ERTMS/ETCS on-board equipment shall stop providing information related to this change of traction system to the ERTMS/ETCS external function.

## **Changing the allowed current consumption**

5.20.7.1 This procedure is dealing with the generation of the information related to a change of allowed current consumption.

5.20.7.2 The ERTMS/ETCS on-board equipment shall start the generation of the information to the ERTMS/ETCS external function when the max safe front end of the train reaches a location (point C) in rear of the location of change of allowed current consumption (point F).

<!-- end of page 104 -->

5.20.7.3 This location (point C) shall be determined by the ERTMS/ETCS on-board equipment taking into account the time necessary for performing the required actions and the current train speed.

5.20.7.4 When the min safe rear end of the train is in rear of the location of change of allowed current consumption (point F), the ERTMS/ETCS on-board equipment shall provide the following information to the ERTMS/ETCS external function:

   - the remaining distance from the max safe front end of the train to the location of allowed current consumption (point F)

   - the new allowed current consumption

5.20.7.5 When the min safe rear end of the train reaches the location of change of allowed current consumption (point F), the remaining distance from the max safe front end of the train to point F and the new allowed current consumption shall no longer be generated.

5.20.7.6 Note: The remaining distance from the train max safe front end to point F is generated until the min safe rear end passes the point F to allow the ERTMS/ETCS external function, in case the change of allowed current consumption involves several pantographs, to manage each pantograph individually assuming that this function knows the distance between each pantograph and the train front end.

<!-- Start of picture text -->
running direction<br>Generate the remaining distance to point F<br>A  and the new allowed current consumption<br>C  F<br>LRBG/ORBG<br>Distance to change of allowed current<br>consumption<br><!-- End of picture text -->

### **Figure 30: Generation of the information to an ERTMS/ETCS external function for a supervision of change of allowed current consumption**

5.20.7.7 If any reason leads to the deletion of the change of allowed current consumption, the ERTMS/ETCS on-board equipment shall stop providing information related to this change of allowed current consumption to the ERTMS/ETCS external function.

## **Station platform**

5.20.8.1 This procedure is dealing with the generation of the information related to a station platform.

<!-- end of page 105 -->

5.20.8.2 The ERTMS/ETCS on-board equipment shall start the generation of the information to the ERTMS/ETCS external function when the max safe front end of the train reaches a location (point C) in rear of the start location of the station platform (point D).

5.20.8.3 This location (point C) shall be determined by the ERTMS/ETCS on-board equipment taking into account the time necessary for performing the required actions and the current train speed.

5.20.8.4 When the min safe rear end of the train is in rear of the start location (point D) of the station platform, the ERTMS/ETCS on-board equipment shall provide the following information to the ERTMS/ETCS external function:

   - the remaining distance from the max safe front end of the train to the start location (point D) of the station platform

   - the remaining distance from the min safe front end of the train to the end location (point E) of the station platform

   - the nominal height of platform above rail level (refer to TSI infrastructure)

   - the position of the station platform (left side, right side, both sides) in reference to the train orientation

5.20.8.5 When the min safe rear end of the train reaches the start location (point D) of the station platform, the remaining distance from the max safe front end of the train to point D shall no longer be generated. The remaining distance from the min safe front end of the train to the end location (point E) of the station platform as well as its nominal height above the rail level and its position shall continue to be generated.

5.20.8.6 When the min safe rear end of the train reaches the end location (point E) of the station platform, the remaining distance from the min safe front end of the train to point E, the position of the station platform and its nominal height above the rail level shall no longer be generated.

5.20.8.7 Note: The remaining distance from the train max safe front end to point D and the remaining distance from the train min safe front end to point E are generated until the min safe rear end passes respectively the point D and the point E to allow the ERTMS/ETCS external function to manage each door individually assuming that this function knows the distance between each door and the train front end.

<!-- end of page 106 -->

<!-- Start of picture text -->
running direction<br>Generate the remaining<br>A  Generate the remaining distance to point D,  distance to point E, the<br>the remaining distance to point E the  nominal height and the<br>nominal height and the position of the  position of the station platform<br>station platform<br>C  D  E<br>LRBG/ORBG<br>Station platform<br>Distance to start of station platform  Station platform length<br><!-- End of picture text -->

### **Figure 31: Generation of the information to ERTMS/ETCS external function for a supervision of station platform**

5.20.8.8 Note: When resuming the initial state or any other reason leads to the shortening of a station platform, the ERTMS/ETCS on-board equipment considers the new end location (point E) of the station platform for the calculation of the remaining distance from the min safe front end of the train to the point E.

5.20.8.9 If resuming the initial state or any other reason leads to the deletion of the station platform, the ERTMS/ETCS on-board equipment shall stop providing information related to this station platform to the ERTMS/ETCS external function.

<!-- end of page 107 -->

# **5.21 Procedure Supervised Manoeuvre**

## **Introduction**

5.21.1.1 The procedure describes the selection of Supervised Manoeuvre by the driver.

## **Table of requirements for “Supervised Manoeuvre” procedure**

5.21.2.1 The ID numbers in the table are used for the representation of the procedure in form of a flowchart in section 5.21.3.

### **5.21.2.2 Procedure**

|**ID #**|**Requirements**|
|---|---|
|S0|The level is 2, the train position is valid and is referred to an LRBG, the safe consist<br>length is available, the train is at standstill, and the ERTMS/ETCS on-board equipment<br>is in:<br>•<br>FS, AD, OS, LS, SR, PT or SB mode, while no RBC transition order is stored<br>on-board, OR<br>•<br>SM mode<br>When the driver selects Supervised Manoeuvre (**E015**) the process shall go to**A045**.|
|A045|The ERTMS/ETCS on-board equipment shall send the “Supervised Manoeuvre<br>Request” message to the RBC together with a position report and the safe consist length<br>information for Supervised Manoeuvre and, if the mode is different from SM, the<br>following default Train Data for Supervised Manoeuvre:<br>a) Train category(ies).<br>b) Maximum train speed.<br>c) Loading gauge.<br>d) Axle load category.<br>e) Traction system(s) accepted by the engine.<br>f) Train fitted with airtight system.<br>g) Axle number.<br>The content of the position report takes into account the safe consist length information<br>(in particular the train front end information is derived from the safe consist length values<br>in front of the engine).<br>If the mode is different from SB or SM, this first SM request will allow the RBC<br>determining the position of the engine and its active cab within the shunting consist.<br>The process shall go to**S050**.|
|S050|The ERTMS/ETCS on-board equipment awaits the reply to the SM request.<br>If an SM authorisation is received from the RBC (**E115**), the process shall go to**D080**.<br>If “SM refused” is received from the RBC (**E215**), the process shall go to**A220**.|

<!-- end of page 108 -->

|**ID #**|**Requirements**|
|---|---|
|D080|If the mode is different from SM, the process shall go to**A050**. Otherwise, it shall go to<br>**A075**.|
|A050|The mode shall change to SM.<br>The process shall go to**A075**.|
|A075|If the direction of the movement authority is opposite to the current train orientation, the<br>ERTMS/ETCS on-board adjusts its train position information according to the new train<br>orientation (see 4.4.21.1.7) and deletes all previously stored location based information<br>(see 3.7.3.4 b)).<br>The process shall go to**A095**.|
|A095|The train position shall be reported to the RBC.<br>The process shall**END**.|
|A220|An indication shall be given to the driver that SM was refused by the RBC.<br>The process shall**END**.|

## **Flowchart**

5.21.3.1 The ID numbers in the flowchart refer to the ID numbers of the table in section 5.21.2.

<!-- end of page 109 -->

<!-- Start of picture text -->
S0:<br>Train is at standstill &<br>Safe consist length info availaible &<br>Mode is FS, AD, OS, LS, SR, SB, PT or SM<br>E015:<br>Driver selects Supervised Manoeuvre<br>A045:<br>Issue SM request<br>S050: E215:<br>Wait for RBC reply SM refused<br>E115 :<br>SM Authorisation received<br>D080:<br>Mode0 A220:<br>Inform Driver: SM refused<br>FS, AD, OS, LS, SR,<br>SB, PT<br>SM<br>A050:<br>Transit to SM mode<br>End<br>A075:<br>If relevant:<br>Change train orientation, adjust<br>train position information and<br>delete all previously stored loc.<br>based info<br>A095:<br>Report position to RBC<br><!-- End of picture text -->

**Figure 32: Flowchart for “Supervised Manoeuvre”**

## **Degraded Situation**

5.21.4.1 In case a communication session is established and no answer to a Supervised Manoeuvre request is received from the RBC within a fixed waiting time (see appendix to chapter 3, List of Fixed Value Data) after sending the “Request for Supervised Manoeuvre” message, the message shall be repeated with the fixed waiting time after each repetition. After a defined number of repetitions (see appendix to chapter 3, List of Fixed Value Data), and if no reply is received within the fixed waiting time from the time of the last sending of “Request for Supervised Manoeuvre”, the ERTMS/ETCS onboard equipment shall inform the driver.

<!-- end of page 110 -->

# **5.22 Procedure Inhibition of balise transmission alarm reaction**

## **Introduction**

5.22.1.1 As explained in 3.15.7, when the balise reading antenna is over a large metallic object that exceeds the Subset-036 limits (something usually called “Big Metal Mass” and in the following referred to as “BMM”) an alarm may be generated by the balise transmission system, which in turn may trigger an on-board safe reaction.

5.22.1.2 Such “integrity check alarm of balise transmission” (in the following: “BTM alarm”) that may be generated when the balise antenna is over a BMM is not distinguishable from one that may be generated when the on-board balise reader system is in failure.

5.22.1.3 Since it is not possible for the on-board to know whether the alarm was generated by a failure (and therefore the on-board may be unable to read balises) or by the presence of a BMM under the balise antenna, it is possible that a safe reaction is taken by the onboard (for example switch to SF) when it is in fact still able to read balises.

5.22.1.4 The track condition “Big Metal Mass” provides a means for trackside to mark areas where BMMs are known to exist, and so to avoid that the on-board may take a safe reaction when there is no need to (the on-board is able to detect balises but the antenna is over a BMM).

5.22.1.5 However, there may be instances where the train is over a known BMM but the related track condition is not available on-board. For example, because the train is awakening on a metal covered area or because the driver had to select override and move the train over a metal covered area. This can result in deadlocks.

5.22.1.6 To avoid that, the procedure detailed in this section provides a means for the driver to inhibit the potential safe reaction to a BTM alarm. This in turn enables a SoM or a generic movement over a BMM in an ETCS equipped area (level 1 or 2) when no BMM track condition is stored on-board.

5.22.1.7 Note: The driver should use the “Inhibition” procedure only when authorised to do so. This authorisation should be covered by operational procedures because to inhibit a safe reaction may be detrimental to safety.

5.22.1.8 In addition, a provision is introduced to allow the procedure to be automatically triggered without driver intervention. This provision applies in case the train is in an area covered by a BMM track condition stored on board, and the track condition gets reset (for example because of a transition to SR mode caused by Override activation).

## **Manual triggering of the procedure**

5.22.2.1 The ERTMS/ETCS on-board equipment shall allow the driver to select “Inhibition of reaction to BTM alarm” only at standstill when the level is 1 or 2 and the current mode is Stand-By, Shunting, or Staff Responsible.

<!-- end of page 111 -->

5.22.2.2 As soon as the driver makes the selection, the “Inhibition” procedure shall be triggered.

## **Automatic triggering of the procedure**

5.22.3.1 As soon as a stored BMM track condition is reset, the “Inhibition” procedure shall be automatically triggered provided that at the time of the reset the Eurobalise antenna is in an area where that track condition is reset, taking into account the max and min safe antenna positions.

5.22.3.1.1 Exception: the automatic triggering of the “Inhibition” procedure shall not apply in case the reset is caused by a transition to NP or RV mode.

## **Once the “Inhibition” procedure has been triggered**

5.22.4.1 An indication shall be given to the driver, until the procedure is ended.

5.22.4.2 Any potential on-board reaction to a “BTM alarm” shall be inhibited.

## **End of “Inhibition” procedure**

5.22.5.1 The “Inhibition” procedure shall end when at least one of the following conditions is fulfilled:

   - a) The train has run more than the fixed distance defined in A.3.1 after the procedure was triggered, OR

   - b) The ERTMS/ETCS on-board equipment switches to a mode different than Standby, Shunting or Staff Responsible, OR

   - c) The driver ends the procedure, by revoking the inhibition.

5.22.5.2 Regarding a) above, the distance is the one travelled away from the location when the procedure was triggered and it shall be applicable in both directions.

5.22.5.2.1 Exception: if a BMM track condition which announces a BMM area within the remaining distance of the manual or automatic inhibition is received, the distance for ending the procedure shall be shortened to the start of the announced BMM area.

5.22.5.3 Note: the driver may revoke the inhibition following an operational procedure. For example, in the case of awakening over a BMM the train has moved past the limit of the metallic covered area and so there is no more need to have the inhibition active. Revoking the inhibition in turn increases safety, because it allows the on-board to have a safe reaction should there be a failure in the balise reader system that was until then “masked” by the inhibition set manually or automatically.

<!-- end of page 112 -->
