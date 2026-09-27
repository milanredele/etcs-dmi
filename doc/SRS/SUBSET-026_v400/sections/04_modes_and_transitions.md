# **ERTMS/ETCS**

**System Requirements Specification Chapter 4 Modes and Transitions**

REF  :  SUBSET-026-4 ISSUE :

4.0.0 DATE : 05/07/2023

<!-- end of page 1 -->

# **4.1 Modification History**

|Issue Number<br>Date|Section Number|Modification / Description|Author|
|---|---|---|---|
|Issue 0.0.1<br>1999-07-05|/|This document is based on<br>“SRS Class P – Modes and<br>Transitions” issue 1.1.2  (ref.<br>Subset-006-4)|Laffineur J.C.|
|Issue 0.0.2<br>1999-07-16|/|New<br>modes/functions/transitions<br>due to Class 1 scope, and<br>impact from WPs (of 1999-<br>07-13).|Laffineur J.C.|
|Issue 0.1.0<br>1999-07-23|/|Unisig Review – Stockholm –<br>22 & 23 July 1999|Laffineur J.C.|
|1.0.0<br>1999-07-29|Version<br>number,<br>editorial changes.|Finalisation<br>meeting,<br>Stuttgart 990729.|HE|
|1.2.0<br>990730|Version number|Release version|HE|
|1.3.0<br>991209|/|Modifications due to Work<br>Packages on SRS Class 1 v<br>1.0.0|Laffineur J.C.|
|1.4.0<br>991220|/|Modifications due to review<br>meeting<br>in<br>Stockholm<br>(991215 and 991216)|Laffineur J.C.|
|1.4.1<br>991221|/|Presentation changes|Laffineur J.C.|
|2.0.0<br>991222|Minor editing|Release version|Laffineur J.C.|
|2.0.1|All|Modifications<br>respect<br>to<br>Unisig<br>review<br>(doc.<br>Unisig_all_com_SRS_2.0.0<br>_2)|Laffineur J.C.|
|2.1.0|All|Modifications<br>respect<br>to<br>Unisig<br>review<br>(doc.<br>Unisig_all_com_SRS_2.0.1)|Laffineur J.C.|
|2.2.0|Version number|UNISIG release|SAB|

<!-- end of page 2 -->

|2.2.2<br>02 02 01|/<br>SUBSET-026<br>Corrected<br>Paragraphs, Issue 2.2.2|Laffineur J.C.|
|---|---|---|
|2.2.4|Including all CLRs being in state “EEIG” as per list of<br>CLRs agreed by EEIG on 06/05/04.|Hougardy A.|
|2.2.4 SG checked<br>28/05/04|Including all CLRs agreed with the EEIG (see “List of<br>CLRs agreed with EEIG for SRS v2.2.4” dated<br>28/05/04)<br>Affected clauses see change marks|H. Kast|
|2.2.5<br>21/01/05|Incorporation of solution proposal for CLR 007 with<br>EEIG users group comments<br>Corrections according to erratum list agreed in SG<br>meeting 170105|Hougardy A.|
|2.2.6<br>04/02/05|Including all CLRs being in state “EEIG pending” as per<br>list of CLRs extracted on 28/01/05.|Hougardy A.|
|2.2.7<br>16/06/05|Including all CLRs extracted from “CR-Report_10.6.05-<br>by number.rtf” and mentioned in column 2.2.7 in “CR<br>status 13.6.05.xls”|Hougardy A.|
|2.2.8<br>29/11/05|Change marks cleaned up and updated according to<br>last CRs decisions (including split of CRs7&126)|Hougardy A.|
|2.2.9<br>24/02/06|Including all CRs that are classified as “IN” as per<br>SUBSET-108 version 1.0.0<br>Removal of all CRs that are not classified as “IN” as per<br>SUBSET-108 version 1.0.0, with the exception of CRs<br>63,98,120,158,538|Hougardy A.|
|2.3.0<br>24/02/06|Release version|HK|
|2.3.1<br>15/06/06|Including SG CR decision made since SRS 2.2.8,<br>correct errors in 2.2.8 detected when creating SRS<br>2.3.0|Hougardy A.|
|2.3.2<br>17/03/08|Including all CRs that are classified as “IN” as per<br>SUBSET-108 version 1.2.0 and all CRs that are in state<br>“Analysis completed” according to ERA CCM|Hougardy A.|
|2.9.1<br>06/10/08|Including all enhancement CR’s retained for 3.0.0<br>baseline and all other error CR’s that are in state<br>“Analysis completed” according to ERA CCM<br>For editorial reasons, the following CR’s are also<br>included: CR656, CR804, CR821|Hougardy A.|

<!-- end of page 3 -->

|3.0.0<br>23/12/08|Release version|Hougardy A.|
|---|---|---|
|3.0.1<br>22/12/09|Including the results of the editorial review of the SRS<br>3.0.0 and the other error CR’s that are in state “Analysis<br>completed” according to ERA CCM|Hougardy A.|
|3.1.0<br>22/02/10|Release version|Hougardy A.|
|3.1.1<br>08/11/10|Including all CR’s that are in state “Analysis completed”<br>according to ERA CCM, plus CR972 and 1000.|Hougardy A.|
|3.2.0<br>22/12/10|Release version|Hougardy A.|
|3.2.1<br>13/12/11|Including all CR’s that are in state “Analysis completed”<br>according to ERA CCM, plus CR772|Hougardy A.|
|3.3.0<br>07/03/12|Baseline 3 release version|Hougardy A.|
|3.3.1<br>04/04/14|CR’s 944, 1124, 1176, 1183, 1185|Gemine O.|
|3.3.2<br>23/04/14|Baseline 3 1<sup>st</sup>maintenance pre-release version|Gemine O.|
|3.3.3<br>06/05/14|CR 1223<br>Baseline 3 1<sup>st</sup>maintenance 2<sup>nd</sup>pre-release version|Gemine O.|
|3.4.0<br>12/05/14|Baseline 3 1<sup>st</sup>maintenance release version|Gemine O.|
|3.4.1<br>23/06/15|CR’s 1033, 1094|Gemine O.|
|3.4.2<br>17/11/15|CR’s 539, 740, 933, 1087, 1089, 1091, 1107, 1128,<br>1187, 1190, 1197, 1249, 1262, 1265, 1266|Gemine O.|
|3.4.3<br>16/12/15|1128 removed, 1117, 1283 plus update due to overall<br>CR consolation phase|Gemine O.|
|3.5.0<br>18/12/15|Baseline 3 2<sup>nd</sup>release version as recommended to EC<br>(see ERA-REC-123-2015/REC)|Gemine O.|
|3.5.1<br>28/04/16|CR 1249 reopening following RISC #75|Gemine O.|
|3.6.0<br>13/05/16|Baseline 3 2<sup>nd</sup>release version|Hougardy A.|
|3.6.1<br>29/05/17|CR’s 940, 1120, 1251, 1288, 1295|Gemine O.|

<!-- end of page 4 -->

|3.6.2<br>31/05/18|CR’s 1120 (bad implementation), 1306|Gemine O.|
|---|---|---|
|3.6.3<br>21/02/20|CR’s 1128, 1274, 1282, 1311, 1312, 1313, 1320, 1321,<br>1325, 1327, 1341, 1345|Gemine O.<br>Hougardy A.|
|3.6.4<br>22/06/20|CR 1312|Gemine O.<br>Hougardy A.|
|3.6.5<br>22/12/21|CR’s 1021, 1162, 1238, 1240, 1292, 1312 (bad<br>implementation), 1346, 1354, 1358, 1370, 1374, 1376,<br>1377, 1387|Gemine O.<br>Hougardy A.|
|3.6.6<br>29/08/22|CR’s 940 (updated), 1238 (updated), 1312 (updated),<br>1342, 1350, 1363, 1367, 1389|Gemine O.<br>Hougardy A.|
|3.9.1<br>24/11/22|CR’s 988, 1307, 1367 (updated)<br>Outcome of B4R1 1<sup>st</sup>consolidation phase|Gemine O.<br>Hougardy A.|
|3.9.2<br>21/02/23|CR’s 1367, 1370<br>Outcome of B4R1 2<sup>nd</sup>consolidation phase|Gemine O.<br>Hougardy A.|
|3.9.3<br>31/05/23|CR 1359<br>Outcome of B4R1 3<sup>rd</sup>consolidation phase|Gemine O.<br>Hougardy A.|
|3.9.4<br>30/06/23|CR’s 1342 (updated), 1431<br>Outcome of B4R1 4<sup>th</sup>consolidation phase|Gemine O.<br>Hougardy A.|
|4.0.0<br>05/07/23|Baseline 4 1<sup>st</sup>release version|Gemine O.<br>Hougardy A.|

<!-- end of page 5 -->

|**4.2**<br>|**Table of Contents**|
|---|---|
|4.1<br>Mo|dification History ........................................................................................................... 2|
|4.2<br>Ta|ble of Contents .............................................................................................................. 6|
|4.3<br>Int|roduction ....................................................................................................................... 8|
|4.3.1|Presentation of the document .................................................................................... 8|
|4.3.2|Identification of the possible modes ........................................................................... 8|
|4.4<br>De|finition of the modes ................................................................................................... 10|
|4.4.1|Introduction .............................................................................................................. 10|
|4.4.2|General Requirements ............................................................................................. 10|
|4.4.3|ISOLATION .............................................................................................................. 11|
|4.4.4|NO POWER ............................................................................................................. 12|
|4.4.5|SYSTEM FAILURE .................................................................................................. 13|
|4.4.6|SLEEPING ............................................................................................................... 14|
|4.4.7|STAND BY ............................................................................................................... 16|
|4.4.8|SHUNTING .............................................................................................................. 18|
|4.4.9|FULL SUPERVISION ............................................................................................... 20|
|4.4.10|UNFITTED ............................................................................................................... 21|
|4.4.11|STAFF RESPONSIBLE ........................................................................................... 22|
|4.4.12|ON SIGHT ............................................................................................................... 25|
|4.4.13|TRIP ........................................................................................................................ 26|
|4.4.14|POST TRIP .............................................................................................................. 27|
|4.4.15|NON LEADING ........................................................................................................ 29|
|4.4.16|AUTOMATIC DRIVING ............................................................................................ 31|
|4.4.17|NATIONAL SYSTEM (SN) ....................................................................................... 32|
|4.4.18|REVERSING ............................................................................................................ 33|
|4.4.19|LIMITED SUPERVISION ......................................................................................... 35|
|4.4.20|PASSIVE SHUNTING .............................................................................................. 37|
|4.4.21|SUPERVISED MANOEUVRE .................................................................................. 39|
|4.5<br>Mo|des and on-board functions ........................................................................................ 42|
|4.5.1|Introduction .............................................................................................................. 42|
|4.5.2|Active Functions Table ............................................................................................. 42|
|4.6<br>Tra|nsitions between modes ............................................................................................ 47|
|4.6.1|Symbols ................................................................................................................... 47|
|4.6.2|Transitions Table ..................................................................................................... 48|
|4.6.3|Transitions Conditions Table .................................................................................... 49|
|4.7<br>DM|I depending on modes ............................................................................................... 55|
|4.7.1|Introduction .............................................................................................................. 55|
|4.7.2|DMI versus Mode Table ........................................................................................... 55|

<!-- end of page 6 -->

|4.8<br>|Acceptance of received information ................................................................................ 60|
|---|---|
|4.8.1|Introduction .............................................................................................................. 60|
|4.8.2|Assumptions ............................................................................................................ 61|
|4.8.3|Accepted information depending on the level, the origin and the type of information 63|
|4.8.4|Accepted Information depending on the mode and the type of information .............. 71|
|4.8.5|Handling of transition buffer in case of level transition announcement or RBC/RBC|
|hand|over ................................................................................................................................ 78|
|4.9<br>|What happens to accepted and stored information when entering a given level .............. 80|
|4.9.1|Introduction .............................................................................................................. 80|
|4.10|What happens to accepted and stored information when entering a given mode ......... 81|
|4.10.|1<br>Introduction .............................................................................................................. 81|
|4.11|What happens to stored information when exiting NP mode ........................................ 89|
|4.12|What happens to an ongoing brake command when entering a given mode ............... 90|

<!-- end of page 7 -->

# **4.3 Introduction**

## **4.3.1 Presentation of the document**

4.3.1.1 This document defines the modes of the ERTMS/ETCS on-board equipment (see chapter 4.4 “Definition of the modes” and chapter 4.5 “Modes and on-board functions”).

4.3.1.2 This document gives all transitions between modes (see chapter 4.6 “Transitions between modes”).

4.3.1.3 This document describes the possible exchanged information between the driver and the ERTMS/ETCS on-board equipment, respect to the mode (see chapter 4.7 “DMI depending on modes”).

4.3.1.4 This document describes how the received information is filtered, respect to several criteria such as the level, the mode, etc. (see chapter 4.8 “Acceptance of received information”).

4.3.1.5 This document describes how the stored information is handled, respect to several criteria such as the level, the mode, etc. (see chapter 4.9 “What happens to accepted and stored information when entering a given level”, and chapter 4.10 “What happens to accepted and stored information when entering a given mode”).

4.3.1.6 All the tables that are included in this document shall be considered as mandatory requirements.

4.3.1.7 Some notes appear in this document. These notes are here to help the reader to understand the specifications, or to explain the reason(s) of a requirement.

## **4.3.2 Identification of the possible modes**

|4.3.2.1|List of the modes:||
|---|---|---|
||Full Supervision|(FS)|
||Automatic Driving|(AD)|
||Limited Supervision|(LS)|
||On Sight|(OS)|
||Staff Responsible|(SR)|
||Supervised Manoeuvre|(SM)|
||Shunting|(SH)|
||Unfitted|(UN)|
||Passive Shunting|(PS)|
||Sleeping|(SL)|
||Stand By|(SB)|

<!-- end of page 8 -->

|Trip|(TR)|
|---|---|
|Post Trip|(PT)|
|System Failure|(SF)|
|Isolation|(IS)|
|No Power|(NP)|
|Non Leading|(NL)|
|National System|(SN)|
|Reversing|(RV)|

<!-- end of page 9 -->

# **4.4 Definition of the modes**

## **4.4.1 Introduction**

- 4.4.1.1

   - For each mode the following information is given:

   - a) The context of utilisation of the mode and the functions that characterise the mode (chapter “Description”).

   - b) The ERTMS/ETCS levels in which the mode can be used (chapter “Used in levels”).

   - c) The related responsibility of the ERTMS/ETCS on-board equipment and of the driver, once the equipment is in this mode (chapter “Responsibilities”).

4.4.1.2 A complete list of transitions to and from each mode is given in the section 4.6.2 “Transitions Table”).

## **4.4.2 General Requirements**

4.4.2.1 When the desk is open, a clear indication of the ERTMS/ETCS mode shall be shown to the driver.

4.4.2.2 Intentionally deleted.

<!-- end of page 10 -->

**4.4.3 ISOLATION**

**4.4.3.1 Description**

4.4.3.1.1 In Isolation mode, the ERTMS/ETCS on-board equipment shall be physically isolated from the brakes and can be isolated from other on-board equipments/systems depending on the specific on-board implementation.

4.4.3.1.2 There shall be a clear indication to the driver that the ERTMS/ETCS on-board equipment is isolated.

4.4.3.1.3 To leave Isolation mode, a special operating procedure is needed (no transition from Isolation is specified). This procedure shall ensure that the on-board equipment is only put back into service when it has been proven that this is safe for operation.

4.4.3.1.4 Intentionally deleted.

**4.4.3.2 Used in levels**

4.4.3.2.1 Used in all levels: Level 0, level 1, level 2 and level NTC.

**4.4.3.3 Responsibilities**

4.4.3.3.1 Isolation of the ERTMS/ETCS on-board equipment is performed by the driver under his complete responsibility.

4.4.3.3.2 Once the ERTMS/ETCS on-board equipment is isolated, the ERTMS/ETCS on-board equipment has no more responsibility.

<!-- end of page 11 -->

## **4.4.4 NO POWER**

**4.4.4.1 Description**

4.4.4.1.1 When the ERTMS/ETCS on-board equipment is not powered, the equipment is in the No Power mode.

4.4.4.1.1.1 Note: in order to ensure cold movement detection function, some parts of the ERTMS/ETCS on-board equipment may be fed by an auxiliary power supply.

4.4.4.1.2 The ERTMS/ETCS on-board equipment shall permanently command the emergency brake.

4.4.4.1.3 Intentionally deleted.

### **4.4.4.2 Used in levels**

4.4.4.2.1 Used in all levels: Level 0, level 1, level 2 and level NTC.

### **4.4.4.3 Responsibilities**

4.4.4.3.1 The ERTMS/ETCS on-board equipment has no responsibility in this mode, except commanding the emergency brake and (optionally) monitoring cold movements.

4.4.4.3.2 The notion of responsibility of the driver is not relevant for the No Power mode.

4.4.4.3.3 If it is required to move a loco in NP mode as a wagon, ETCS brake command must be overridden by external means.

<!-- end of page 12 -->

## **4.4.5 SYSTEM FAILURE**

**4.4.5.1 Description**

4.4.5.1.1 The ERTMS/ETCS on-board equipment shall switch to the System Failure mode in case of a fault, which affects safety.

4.4.5.1.2 The ERTMS/ETCS on-board equipment shall permanently command the Emergency Brakes.

4.4.5.1.3 Intentionally deleted.

**4.4.5.2 Used in levels**

4.4.5.2.1 Used in all levels: Level 0, level 1, level 2 and level NTC.

**4.4.5.3 Responsibilities**

4.4.5.3.1 The ERTMS/ETCS on-board equipment is responsible for commanding the Emergency Brakes.

4.4.5.3.2 No responsibility of the driver.

<!-- end of page 13 -->

## **4.4.6 SLEEPING**

**4.4.6.1 Description**

4.4.6.1.1 The Sleeping mode is defined to manage the ERTMS/ETCS on-board equipment of a slave engine that is remote controlled.

4.4.6.1.2 The desk(s) of a sleeping engine must be closed (since there is no driver, no information shall be shown).

4.4.6.1.3 As the engine is remote controlled by the leading engine, its ERTMS/ETCS on-board equipment shall not perform any train movement supervision.

4.4.6.1.4 The ERTMS/ETCS on-board equipment shall perform the Train Position function; in particular, the front/rear end of the engine (i.e., not the train) shall be used to refer to train front/rear end.

4.4.6.1.5 Sleeping mode shall be automatically detected on-board via the train interface.

4.4.6.1.6 If possible, the train must not be stopped due to a safety critical fault in a sleeping engine. The ERTMS/ETCS on-board equipment should therefore try to memorise the occurrence of such fault(s), which should be handled when the engine leaves the Sleeping mode. The ERTMS/ETCS on-board equipment should also try to send an error information to the RBC.

4.4.6.1.7 If a desk of the sleeping engine is opened while the train is running (this is an abnormal operation), the ERTMS/ETCS on-board equipment shall switch to Stand-By mode.

4.4.6.1.8 If the sleeping input information is set to "sleeping not requested" (no more detection of the remote control), the switch to Stand-By mode shall be made only if the train is at standstill.

4.4.6.1.9 Intentionally deleted.

4.4.6.1.10 The ERTMS/ETCS on-board equipment shall open a communication session with the RBC when at least one of the following events occurs:

   - a) in all levels, on receipt of the order to establish a communication session with the RBC.

   - b) In level 2, when entering or exiting Sleeping mode (to report the change of mode to the RBC).

   - c) In level 2, when a safety critical fault of the ERTMS/ETCS on-board equipment occurs (to report the fault to the RBC).

4.4.6.1.11 Intentionally deleted.

4.4.6.1.12 In case of balise group message consistency error (refer to 3.16.2.4.4 and 3.16.2.5.1), the ERTMS/ETCS onboard equipment shall not command the service brake.

<!-- end of page 14 -->

4.4.6.1.13 When in level 2, if no compatible version has been established between the on-board equipment in Sleeping mode and the RBC, the ERTMS/ETCS onboard equipment shall react as specified in 3.5.3.7 d) 2<sup>nd</sup> bullet but no driver’s indication shall be given.

**4.4.6.2 Used in levels**

4.4.6.2.1 Used in all levels: Level 0, level 1, level 2 and level NTC.

### **4.4.6.3 Responsibilities**

4.4.6.3.1 The ERTMS/ETCS on-board equipment of an engine in Sleeping mode has no responsibility for the train protection.

4.4.6.3.2 The notion of responsibility of the driver is not relevant for the Sleeping mode.

4.4.6.3.2.1 Note: The leading engine is responsible for the movement of the train. It is then the ERTMS/ETCS on-board equipment of the leading engine that is fully/partially/not responsible for the train protection, with respect to its mode.

<!-- end of page 15 -->

## **4.4.7 STAND BY**

**4.4.7.1 Description**

4.4.7.1.1 The Stand-By mode is a default mode and cannot be selected by the driver.

4.4.7.1.2 It is in the Stand-By mode that the ERTMS/ETCS on-board equipment awakes.

4.4.7.1.3 Data for mission are collected in Stand-By (see SRS-chapter 5: “Start of Mission” procedure).

4.4.7.1.4 In Stand-By mode, the desk of the engine can be open or closed. No interaction with the driver shall be possible as long as the desk is closed, except isolation of the ERTMS/ETCS on-board equipment.

4.4.7.1.5 The ERTMS/ETCS on-board equipment shall perform the Standstill Supervision, in order to prevent the train from moving.

4.4.7.1.5.1 As soon as a movement is detected, the ERTMS/ETCS on-board shall start supervising (see section 3.6.7) whether the train travels away, from the location when the movement was detected, over a distance longer than a distance specified by the National Value. In case this distance is exceeded, the brake command shall be triggered.

4.4.7.1.5.2 Refer to section 3.14.1 for the revocation of the brake command.

4.4.7.1.5.3 After revocation of the brake command, the Standstill Supervision shall be re-initialised, i.e. the clause 4.4.7.1.5.1 shall be applied again.

4.4.7.1.5.4 If a desk is open, an indication shall be given to the driver showing when the Standstill Supervision is commanding the brakes.

4.4.7.1.6 The ERTMS/ETCS on-board equipment shall perform the Train Position function; in particular, the front/rear end of the engine shall be used to refer to train front/rear end and no train integrity information shall be reported to the RBC, with the following exceptions:

   - a) If valid Train Data is available, the Train Data “train length” can be used to report train integrity information in case other preconditions are fulfilled (see chapter 3 Table 2c for details), OR

   - b) If no valid Train Data is available but the safe consist length information is available, the train front/rear is determined as per clauses 3.6.1.3.4 and 3.18.3.2.4 and train integrity information can be reported to the RBC in case other preconditions are fulfilled (see chapter 3 Table 2c for details).

**4.4.7.2 Used in levels**

4.4.7.2.1 Used in all levels: Level 0, level 1, level 2 and level NTC.

### **4.4.7.3 Responsibilities**

<!-- end of page 16 -->

4.4.7.3.1 The ERTMS/ETCS on-board equipment is responsible for maintaining the train at standstill.

4.4.7.3.2 The driver has no responsibility for train movements.

<!-- end of page 17 -->

## **4.4.8 SHUNTING**

**4.4.8.1 Description**

4.4.8.1.1 The purpose of the Shunting mode is to enable shunting movements. In Shunting mode, the ERTMS/ETCS on-board equipment shall supervise the train movements against:

   - a) a ceiling speed: the shunting mode speed limit

   - b) a list of expected balise groups (if such list was sent by the trackside equipment). The train shall be tripped if a balise group, not contained in the list, is passed (When an empty list is sent, no balise group can be passed. When no list is sent, all balise groups can be passed)

   - c) “stop if in shunting mode” information. The train is tripped if such information is received from balise groups

   - d) Intentionally deleted

4.4.8.1.2 The Shunting mode shall not require Train Data.

4.4.8.1.3 The ERTMS/ETCS on-board equipment shall perform the Train Position function; in particular, the front/rear end of the engine shall be used to refer to train front/rear end.

4.4.8.1.4 The ERTMS/ETCS on-board equipment shall generate the information to the train interface that it is ready for remote shunting.

4.4.8.1.5 While the ERTMS/ETCS on-board is in Shunting mode, the reception of level transition orders has no immediate effect. The level transition announcements shall be rejected and, upon reception of the order while already in Shunting mode, an immediate level transition order or a conditional level transition order shall be stored but evaluated only when another mode than Shunting or Passive Shunting has been entered (i.e. when the Shunting movement is terminated).

4.4.8.1.5.1 Note: in case the Shunting movement is terminated through a direct transition to No Power mode, see clause 4.11.1.4.

4.4.8.1.5.2 When receiving a communication session establishment order, the ERTMS/ETCS onboard in Shunting mode shall not establish the communication session, but shall store the RBC contact information.

4.4.8.1.5.3 When in Shunting mode, the ERTMS/ETCS on-board shall not manage RBC-RBC handover, except for storing the RBC contact information given at the RBC/RBC border.

4.4.8.1.6 Shunting mode can be selected by the driver, only accepted when the train is at standstill, or ordered by the trackside.

4.4.8.1.7 In case of selection of Shunting mode by the driver:

   - in level 1 operations, the switch to shunting is always accepted by the on-board equipment

<!-- end of page 18 -->

   - in level 2 areas, the on-board asks the trackside for an authorisation. The switch to shunting is possible only after receiving such authorisation. The trackside can send a list of balise groups, that the train is allowed to pass while in SH, together with the authorisation

4.4.8.1.8 In case of order to switch to Shunting mode from trackside, the order:

   - in level 1 is given by a balise group. A list of balise groups, that the train is allowed to pass after the entry in Shunting, can be sent together with the order

   - in level 2 is sent via radio. A list of balise groups, that the train is allowed to pass after the entry in Shunting, can be sent together with the order

4.4.8.1.9 When the switch to shunting is ordered by trackside, a driver acknowledgement is requested.

4.4.8.1.9.1 Note: in Shunting mode the train is only partially supervised, therefore it is necessary that the driver takes the responsibility.

4.4.8.1.10 The ERTMS/ETCS on-board equipment shall display the train speed and, only on driver request, the permitted speed. The display of the permitted speed shall also be stopped on driver request.

4.4.8.1.11 Intentionally deleted.

4.4.8.1.12 Intentionally deleted.

**4.4.8.2 Used in levels**

4.4.8.2.1 Used in level 0, NTC, 1 and 2.

### **4.4.8.3 Responsibilities**

4.4.8.3.1 The ERTMS/ETCS on-board equipment is responsible for the supervision of the shunting mode speed limit, and that the engine with the active antenna is tripped when passing the defined border of the shunting area (only if there is a defined border: balise group not in the list given by trackside, or balise group giving the information “stop if in shunting”).

4.4.8.3.2 The driver is responsible for:

   - a) Remaining inside the shunting area defined by a procedure or an external system outside ERTMS/ETCS (also when the shunting area is protected by balises)

   - b) Train/engine movements and shunting operations

<!-- end of page 19 -->

## **4.4.9 FULL SUPERVISION**

**4.4.9.1 Description**

4.4.9.1.1 The ERTMS/ETCS on-board equipment shall be in the Full Supervision mode when all train and track data, which is required for a complete supervision of the train, is available on board.

4.4.9.1.2 Full supervision cannot be selected by the driver, but is entered automatically when all necessary conditions are fulfilled.

4.4.9.1.3 To be in Full Supervision mode, SSP and gradient are not required for the whole length of the train, but must be available at least from the FRONT END of the train.

4.4.9.1.4 Once in Full Supervision mode, if SSP and gradient are not known for the whole length of the train, an indication “ENTERINGFS” shall be clearly displayed to the driver until SSP and gradient are known for the whole length of the train.

4.4.9.1.4.1 Note: this indication may also be displayed in case the train length has been increased, see 3.18.3.8.

4.4.9.1.5 The ERTMS/ETCS on-board equipment shall supervise train movements against a dynamic speed profile.

4.4.9.1.6 The ERTMS/ETCS on-board equipment shall display the train speed, the permitted speed, the target distance and the target speed to the driver (this list is not exhaustive – refer to chapter 4.7 “DMI depending on modes”).

4.4.9.1.7 Intentionally deleted.

**4.4.9.2 Used in levels**

4.4.9.2.1 Used in level 1 and 2.

### **4.4.9.3 Responsibilities**

4.4.9.3.1 The ERTMS/ETCS on-board equipment is fully responsible for the train protection (except for the 2 situations described below).

4.4.9.3.2 The driver is responsible for respecting the EOA when approaching an EOA with a release speed.

4.4.9.3.3 When “ENTERING FS” is displayed to the driver, the driver is responsible for respecting speed restrictions that apply for the part of the train that is not covered by SSP and gradient data.

<!-- end of page 20 -->

## **4.4.10 UNFITTED**

### **4.4.10.1 Description**

4.4.10.1.1 The Unfitted mode is used to allow train movements in either:

   - a) Areas that are equipped neither with ERTMS/ETCS track-side equipment nor with national train control system

   - b) Intentionally deleted

   - c) Areas that are equipped with ERTMS/ETCS trackside equipment and/or national train control system(s), but operation under their supervision is currently not possible

4.4.10.1.2 The ERTMS/ETCS on-board equipment shall supervise train movements against a ceiling speed: the lowest of the maximum train speed and the Unfitted mode speed limit for unfitted area (national value).

4.4.10.1.2.1 Intentionally deleted.

4.4.10.1.3 The ERTMS/ETCS on-board equipment shall also supervise temporary speed restrictions.

4.4.10.1.4 The ERTMS/ETCS on-board equipment shall display the train speed to the driver.

4.4.10.1.5 Intentionally deleted.

### **4.4.10.2 Used in levels**

4.4.10.2.1 Used in level 0.

### **4.4.10.3 Responsibilities**

4.4.10.3.1 The ERTMS/ETCS on-board equipment supervises a ceiling speed and (if available) temporary speed restrictions.

4.4.10.3.2 The driver must respect the existing line-side signals and is fully responsible for train movements.

<!-- end of page 21 -->

## **4.4.11 STAFF RESPONSIBLE**

**4.4.11.1 Description**

4.4.11.1.1 The Staff Responsible mode allows the driver to move the train under his own responsibility in an ERTMS/ETCS equipped area.

4.4.11.1.2 This mode is used when the system does not know the route. For example:

   - a) After the ERTMS/ETCS on-board equipment starts-up (awakening of the train).

   - b) To pass a signal at danger / override an EOA.

   - c) After a trackside failure (for example: loss of radio contact).

4.4.11.1.3 The ERTMS/ETCS on-board equipment shall supervise train movements against:

   - a) a ceiling speed: the staff responsible mode speed limit

   - b) a given distance (regarding its supervision starting time/start location see 4.4.11.1.3.1). The ERTMS/ETCS on-board equipment shall supervise braking curves with a target speed of zero to the end of this distance. If the train overpasses this distance (see next note) the ERTMS/ETCS on-board equipment shall trip the train

   - c) a list of expected balise groups, if this list has been sent by the RBC. The train shall be tripped if overpassing a balise group that is not in the list. (When an empty list is sent, no balise group can be passed. When no list is sent, all balise groups can be passed)

   - d) balise groups giving the order ‘stop if in SR’. This order shall immediately trip the train, unless the overpassed balise group is included in a list of expected balises as defined in item c)

   - e) running in the direction opposite to the train orientation (Unauthorised Direction Movement Protection)

4.4.11.1.3.1 The ERTMS/ETCS on-board shall supervise the SR distance as follows:

   - a) If the National/Default Value determines the max permitted distance to run in SR mode, the calculation of the remaining distance from the virtual train position to the end of the SR distance (see section 3.6.7) shall be based on a supervision starting when SR mode is entered, or, already in Staff Responsible mode, when Override is activated.

   - b) If the max permitted distance to run in SR mode is determined by the value transmitted by the RBC, or entered by the driver, the calculation of the remaining distance from the virtual train position to the end of the SR distance (see section 3.6.7) shall be based on a supervision starting when the distance information is received or entered.

   - c) If the max permitted distance to run in SR mode is determined by the value transmitted by Euroloop, the distance information transmitted by Euroloop shall be referred to one or more reference balise groups. On-board shall evaluate the distance to run in SR mode by matching the reference balise groups given with the LRBG.

<!-- end of page 22 -->

4.4.11.1.3.1.1 Note: the end of the SR distance determined from Euroloop, which is originally referred to the LRBG at the time of the reception of the Euroloop information, can be afterwards relocated to the SOLR that is different from any of the original reference balise groups transmitted by Euroloop.

4.4.11.1.4 Note: Since the gradient profile may not be available, the supervision of the braking curves in Staff Responsible mode does not ensure that the train will not pass the given distance.

4.4.11.1.5 The ERTMS/ETCS on-board equipment shall give the possibility to the driver to modify the value of the SR mode speed limit and of the given distance. This shall be possible only at standstill.

4.4.11.1.5.1 If a train movement is detected while the driver is entering the SR speed/distance limits, the ERTMS/ETCS on-board equipment shall trigger the brake command.

4.4.11.1.5.2 The unit, range and resolution of the SR mode speed limit and distance entered by the driver shall be as specified in A.3.11.

4.4.11.1.6 If the level is 2 and a communication session is open, the driver shall have the possibility to request a new distance to run in Staff Responsible, by selecting "Start". This triggers an MA request.

4.4.11.1.6.1 Note: Once the SR distance is covered, the driver may have to go further.

4.4.11.1.6.2 When entering SR mode, the value applicable for SR mode speed limit and the value applicable for SR distance shall be the corresponding National/Default values. Exception for SR distance: SR mode is authorised by RBC giving an SR distance.

4.4.11.1.6.3 While in SR mode, the value applicable for the SR mode speed limit shall be, if available, the last value entered by the driver.

4.4.11.1.6.4 While in SR mode, the value applicable for the SR distance shall be, if available, the last value received by the ERTMS/ETCS on-board equipment amongst:

   - a) the distance to run in SR entered by the driver;

   - b) the distance to run in SR given by trackside.

4.4.11.1.6.5 When "Override" is selected, the SR mode speed limit value and the SR distance value previously entered by driver or given by trackside, if any, shall be deleted. The corresponding National/Default values shall enter in force.

4.4.11.1.6.6 If the train is in SR and receives a new distance to run in SR mode from the RBC, the stored list of expected balise groups, if any, shall be deleted or shall be replaced by the list of expected balise groups sent together with the distance to run in SR.

4.4.11.1.6.7 If an ERTMS/ETCS on-board equipment in SR mode, after having received from Euroloop max permitted distance to run in SR mode information, detects the main signal

<!-- end of page 23 -->

balise group being part of this information then it shall ignore any new max permitted distance to run in SR mode information from that loop.

4.4.11.1.7 The ERTMS/ETCS on-board equipment shall display the train speed and the (when active) override (permission to pass a signal at danger, trip inhibited). The permitted speed, target distance and the target speed shall be displayed only on driver request, until the driver requests to stop their display.

4.4.11.1.8 If a virtual train position is supervised as per clause 3.6.7.1 f) or g), the clauses mentioning the train position shall apply by analogy.

4.4.11.1.9 If receiving a "track ahead free" request from the RBC, the ERTMS/ETCS on-board equipment requests the driver to enter the "track ahead free" information.

4.4.11.1.10 Intentionally deleted.

4.4.11.1.11 Intentionally deleted.

### **4.4.11.2 Used in levels**

4.4.11.2.1 Level 1 and 2.

### **4.4.11.3 Responsibilities**

4.4.11.3.1 The ERTMS/ETCS on-board equipment supervises a ceiling speed, a SR distance if finite and, if available, a list of balise groups.

4.4.11.3.2 The driver must check if the track is free, if points are correctly positioned, and must respect the existing line-side information (signals, speed boards etc.).

4.4.11.3.3 When using the possibility to modify the value of the SR mode speed limit and of the given distance, the driver is responsible for entering reasonable values.

<!-- end of page 24 -->

## **4.4.12 ON SIGHT**

### **4.4.12.1 Description**

4.4.12.1.1 The On Sight mode enables the train to enter into a track section that could be already occupied by another train, or obstructed by any kind of obstacle.

4.4.12.1.2 On Sight mode cannot be selected by the driver, but shall be entered automatically when commanded by trackside and all necessary conditions are fulfilled.

4.4.12.1.3 The ERTMS/ETCS on-board equipment shall supervise train movements against a dynamic speed profile.

4.4.12.1.4 The ERTMS/ETCS on-board equipment shall display the train speed to the driver. The permitted speed, target distance, target speed and release speed (if any) shall be displayed only on driver request, until the driver requests to stop their display (this list is not exhaustive – refer to chapter 4.7 “DMI depending on modes”).

4.4.12.1.5 If receiving a "track ahead free" request from the RBC, the ERTMS/ETCS on-board equipment requests the driver to enter the "track ahead free" information.

4.4.12.1.6 To be in On Sight mode, SSP and gradient are not required for the whole length of the train, but must be available at least from the FRONT END of the train.

4.4.12.1.7 Once in On Sight mode, if SSP and gradient are not known for the whole length of the train, an indication “ENTERING OS” shall be clearly displayed to the driver until SSP and gradient are known for the whole length of the train.

4.4.12.1.7.1 Note: this indication may also be displayed in case the train length has been increased, see 3.18.3.8.

4.4.12.1.8 Deleted

4.4.12.1.9 Intentionally deleted.

### **4.4.12.2 Used in levels**

4.4.12.2.1 Used in level 1 and 2.

### **4.4.12.3 Responsibilities**

4.4.12.3.1 The ERTMS/ETCS on-board equipment is responsible for the supervision of the train movements.

4.4.12.3.2 The driver is responsible for checking the track occupancy when moving the train, because the track may be occupied.

<!-- end of page 25 -->

## **4.4.13 TRIP**

**4.4.13.1 Description**

4.4.13.1.1 Deleted

4.4.13.1.1.1 Note: Application of emergency brakes and train trip are two different things. For example, exceeding the permitted speed leads to application of the emergency brakes, but as long as the train does not pass the EOA/LOA, it is not a train trip.

4.4.13.1.2 The ERTMS/ETCS on-board equipment shall command the emergency brakes (no brake release is possible in Trip mode).

4.4.13.1.3 The ERTMS/ETCS on-board equipment shall indicate to the driver the reason of the train trip.

4.4.13.1.4 The ERTMS/ETCS on-board equipment shall request an acknowledgement from the driver once train is at standstill (to allow the driver to acknowledge the train trip).

4.4.13.1.4.1 Note: This acknowledgement is mandatory to exit from Trip mode.

4.4.13.1.5 Intentionally deleted.

4.4.13.1.6 Closing the desk while being in Trip mode will not cause a mode change but no interaction with the driver shall be possible as long as the desk is closed, except isolation of the ERTMS/ETCS on-board equipment

### **4.4.13.2 Used in levels**

4.4.13.2.1 Used in level 0, NTC, 1 and 2.

### **4.4.13.3 Responsibilities**

4.4.13.3.1 The ERTMS/ETCS on-board equipment is responsible for stopping the train and for maintaining the train at standstill.

4.4.13.3.2 The driver has no responsibility for train movements.

<!-- end of page 26 -->

## **4.4.14 POST TRIP**

**4.4.14.1 Description**

4.4.14.1.1 The Post Trip mode shall be entered immediately after the driver acknowledges the trip.

4.4.14.1.2 Once in post trip mode, the onboard equipment shall release the Command of the emergency brake.

4.4.14.1.2.1 The ERTMS/ETCS on-board equipment shall keep on indicating to the driver the reason of the train trip.

4.4.14.1.3 The train shall only be authorised to perform a reverse movement over a given distance (national value), which is counted opposite to the train orientation from the estimated train front end when the Post Trip mode is entered. The ERTMS/ETCS on-board equipment shall command the service brake if this distance is overpassed. The driver shall be informed about the reason for the brake application.

4.4.14.1.3.1 The ERTMS/ETCS onboard equipment shall perform the Unauthorised Direction Movement Protection. As in PT mode, the allowed movement is a reverse movement, then the Unauthorised Direction Movement Protection avoids the train running in forward direction.

4.4.14.1.3.2 After the release of a brake command initiated due to an overpassed distance allowed for reverse movement in Post Trip mode, the ERTMS/ETCS on-board equipment shall command the service brake for any further movement in the direction opposite to the train orientation.

4.4.14.1.4 When performing a reverse movement in Post Trip mode, the train trip shall be inhibited.

4.4.14.1.5 Intentionally deleted.

4.4.14.1.6 When ERTMS/ETCS level is 1, if the driver selects “Start” the onboard equipment proposes Staff Responsible. When ERTMS/ETCS level is 2, the selection of Start leads to an MA Request to the RBC. It is the RBC responsibility to give an SR authorisation, or a Full Supervision MA or an On Sight/Shunting MA to an ERTMS/ETCS equipment that is in Post Trip mode.

4.4.14.1.7 Intentionally deleted.

4.4.14.1.8 Intentionally deleted.

4.4.14.1.9 In case of balise group message consistency error (refer to 3.16.2.4.4 and 3.16.2.5.1), the ERTMS/ETCS onboard equipment shall not command the service brake.

### **4.4.14.2 Used in levels**

4.4.14.2.1 Used in level 1 and 2.

### **4.4.14.3 Responsibilities**

<!-- end of page 27 -->

4.4.14.3.1 The ERTMS/ETCS on-board equipment is responsible for supervising that the train only performs a reverse movement and that this movement does not exceed the maximum permitted distance (national value).

4.4.14.3.2 The driver is responsible not to overpass the maximum permitted distance when performing the reverse movement.

<!-- end of page 28 -->

## **4.4.15 NON LEADING**

**4.4.15.1 Description**

4.4.15.1.1 The Non-Leading mode is defined to manage the ERTMS/ETCS on-board equipment of a slave engine that is NOT electrically coupled to the leading engine (and so, not remote controlled) but has its own driver.

4.4.15.1.1.1 Note: This operating situation is called Tandem.

4.4.15.1.1.2 The ERTMS/ETCS on-board equipment shall use, as a necessary condition to enter in Non-Leading mode, a non-leading input information from the train interface.

4.4.15.1.1.3 Upon the detection that the non-leading input information is set to "Non-leading not permitted", the ERTMS/ETCS on-board equipment shall inform the driver that the nonleading operation is no longer permitted and shall request an acknowledgement from the driver. However, the switch to Stand-By mode shall be made only if the train is at standstill.

4.4.15.1.2 The ERTMS/ETCS on-board equipment shall not perform any train movement supervision in Non-Leading mode.

4.4.15.1.3 The ERTMS/ETCS on-board equipment shall perform the Train Position function; in particular, the front/rear end of the engine (i.e., not the train) shall be used to refer to train front/rear end and no train integrity information shall be reported to the RBC, regardless of whether the train integrity and/or the safe consist length information is available on-board.

4.4.15.1.4 When level is 2, the ERTMS/ETCS on-board equipment shall report its position to the RBC, according to the previously received parameters.

4.4.15.1.5 If possible, the train must not be stopped due to a safety critical fault in a non-leading engine. The ERTMS/ETCS on-board equipment should therefore try to memorise the occurrence of such fault(s), which should be handled when the engine leaves Non Leading mode. The ERTMS/ETCS on-board equipment should also try to send an error information to the RBC.

4.4.15.1.6 The ERTMS/ETCS on-board equipment shall display the train speed to the driver.

4.4.15.1.7 Intentionally deleted

4.4.15.1.8 Intentionally deleted.

4.4.15.1.9 Intentionally deleted.

4.4.15.1.10 In case of balise group message consistency error (refer to 3.16.2.4.4 and 3.16.2.5.1), the ERTMS/ETCS onboard equipment shall not command the service brake.

### **4.4.15.2 Used in levels**

<!-- end of page 29 -->

4.4.15.2.1 Used in all levels: Level 0, level 1, level 2 and level NTC.

### **4.4.15.3 Responsibilities**

4.4.15.3.1 The ERTMS/ETCS on-board equipment performs NO protection functions, except forwarding track conditions associated orders through DMI or train interface.

4.4.15.3.2 The driver is responsible for obeying the orders associated to track conditions, when they are displayed by the DMI.

<!-- end of page 30 -->

## **4.4.16 AUTOMATIC DRIVING**

**4.4.16.1 Description**

4.4.16.1.1  If it is interfaced to an ERTMS/ATO on-board and if the ATO selector is in position "On", the ERTMS/ETCS on-board equipment is in Automatic Driving mode when the ERTMS/ATO on-board drives the train according to a journey profile provided by the ERTMS/ATO trackside.

4.4.16.1.2  The Automatic Driving mode can only be entered upon a driver action, i.e. selecting "ATO engage" when all necessary conditions are fulfilled (see SUBSET-125 for details).

4.4.16.1.3  Once in Automatic Driving mode, the driver can at any time take back the control of the train driving by acting on the brakes or by selecting "ATO disengage".

4.4.16.1.4  The ERTMS/ETCS on-board equipment shall supervise train movements in the same way as in Full Supervision mode, except that for the speed and distance target speed monitoring when an SBI supervision limit is exceeded neither a brake command nor the intervention status shall be triggered.

4.4.16.1.5  The ERTMS/ETCS on-board equipment shall display the train speed, the permitted speed and the SBI speed (whenever the ERTMS/ATO on-board drives over the permitted speed) to the driver (this list is not exhaustive – refer to chapter 4.7 “DMI depending on modes”).

4.4.16.1.6 The ERTMS/ETCS on-board equipment shall generate the information to the train interface that it is in Automatic Driving mode.

**4.4.16.2 Used in levels**

4.4.16.2.1  Used in level 1 and 2.

### **4.4.16.3 Responsibilities**

4.4.16.3.1  The ERTMS/ETCS on-board equipment is fully responsible for the train protection, except for the following situation: the ERTMS/ATO on-board is responsible for respecting the EOA when approaching an EOA with a release speed.

4.4.16.3.2  Substituting the driver for acting on the traction/brakes of the train, the ERTMS/ATO onboard is responsible to drive the train according to the ATO journey profile. However each time the "ATO ready" information is displayed to the driver (e.g. after the ERTMS/ATO on-board has stopped the train at an operational stopping point), the driver is responsible for resuming the automatic driving by selecting "ATO Engage".

4.4.16.3.2.1 Note: While in Automatic Driving mode, the ERTMS/ATO on-board disengages itself (i.e. it stops acting on the traction/brakes of the train) after it has stopped the train at an operational stopping point included in the ATO journey profile.

<!-- end of page 31 -->

## **4.4.17 NATIONAL SYSTEM (SN)**

### **4.4.17.1 Description**

4.4.17.1.1 In SN mode, according to the specific on-board implementation, the National System may access the following resources via the ERTMS/ETCS on-board equipment: DMI, Juridical Recording interface, odometer, train interface and brakes. This can be achieved through the STM interface.

4.4.17.1.2 A limited set of data coming from balises shall be used by the ERTMS/ETCS on-board equipment, refer to SRS chapter 4.8 “Use of received information”.

4.4.17.1.3 Intentionally deleted.

### **4.4.17.2 Used in levels**

4.4.17.2.1 Level NTC.

### **4.4.17.3 Responsibilities of ERTMS/ETCS Onboard**

4.4.17.3.1 No train supervision functionality is provided by the ERTMS/ETCS on-board equipment. In case the ERTMS/ETCS on-board equipment is interfaced to the National System through an STM, refer to the FFFIS STM (Subset 035) for the functionality provided by ERTMS/ETCS on-board.

4.4.17.3.2 Intentionally deleted.

### **4.4.17.4 Responsibilities of the National System**

4.4.17.4.1 The National System is responsible for all train supervision and protection functions.

4.4.17.4.2 The National System is responsible for issuing and revoking brake command.

4.4.17.4.3 The National System is responsible for maintaining national system behaviour and interact with national trackside equipment.

4.4.17.4.4 The National System is responsible for interaction with the driver.

### **4.4.17.5 Responsibilities of the driver**

4.4.17.5.1 The responsibility of the driver depends on the National System in use.

<!-- end of page 32 -->

## **4.4.18 REVERSING**

**4.4.18.1 Description**

4.4.18.1.1 The Reversing mode allows the driver to change the direction of movement of the train and drive from the same cab, i.e. the train orientation remains unchanged. This is possible only in areas so marked by trackside.

4.4.18.1.2 Note: This mode is used to allow the train to escape from a dangerous situation and to reach as fast as possible a “safer” location.

4.4.18.1.3 The ERTMS/ETCS on-board equipment shall supervise train movements against:

   - a) a ceiling speed: the Reversing mode speed limit given from trackside

   - b) a distance to run in the direction opposite to the train orientation, given from trackside. The emergency brake shall be commanded if overpassing this distance

4.4.18.1.4 After the release of a brake command initiated due to an overpassed reversing distance, and while the reversing distance is still overpassed, the ERTMS/ETCS on-board equipment shall command the emergency brake for any further movement in the direction opposite to the train orientation.

4.4.18.1.5 The ERTMS/ETCS on-board equipment shall display the train speed, the permitted speed and the remaining distance to run.

4.4.18.1.6 In case the SBI supervision limit is exceeded (refer to chapter 3 table 5, triggering condition t4), the ERTMS/ETCS on-board equipment shall command the emergency brake instead of the service brake. For the revocation of the brake command, refer to 3.13.10.2.4.

4.4.18.1.7 The position reports sent when in reversing mode shall refer to the location of the driving cab (as before reversing).

4.4.18.1.8 The ERTMS/ETCS onboard equipment shall perform the Unauthorised Direction Movement Protection. As in RV mode, the allowed movement is a reverse movement, then the Unauthorised Direction Movement Protection avoids the train running in forward direction.

4.4.18.1.9 Intentionally deleted.

4.4.18.1.10 In case of balise group message consistency error (refer to 3.16.2.4.4 and 3.16.2.5.1), the ERTMS/ETCS onboard equipment shall not command the service brake.

4.4.18.1.11 In case there is an alarm reporting a malfunction for the onboard balise transmission function, the ERTMS/ETCS onboard equipment shall ignore this alarm.

4.4.18.1.12 In case the ERTMS/ETCS system version number X transmitted by any balise is greater than the highest version X supported by the onboard equipment (refer to 3.17.3.5), the information from this balise shall be ignored, the train shall not be tripped and the driver shall not be informed.

<!-- end of page 33 -->

### **4.4.18.2 Used in levels**

4.4.18.2.1 Level 1 and 2.

### **4.4.18.3 Responsibilities**

4.4.18.3.1 The ERTMS/ETCS on-board equipment supervises a ceiling speed and a distance to run in the direction opposite to the train orientation.

4.4.18.3.2 The driver must keep the train movement inside the received distance to run.

<!-- end of page 34 -->

## **4.4.19 LIMITED SUPERVISION**

### **4.4.19.1 Description**

4.4.19.1.1 The Limited Supervision mode enables the train to be operated in areas where trackside information can be supplied to realise background supervision of the train.

4.4.19.1.2 Limited supervision can not be selected by the driver, but shall be entered automatically when commanded by trackside and all necessary conditions are fulfilled.

4.4.19.1.3 The ERTMS/ETCS on-board equipment shall supervise train movements against a dynamic speed profile.

4.4.19.1.4 The ERTMS/ETCS on-board equipment shall display the train speed and the release speed, if any (this list is not exhaustive – refer to chapter 4.7 “DMI depending on modes”). Upon request by trackside (refer to clauses 4.4.19.1.4.2 to 4.4.19.1.4.6) if the generic LS function marker is stored on-board or if the conditions in clause 4.4.19.1.4.7 are fulfilled, the ERTMS/ETCS on-board equipment shall also display the lowest speed amongst:

   - a) the lowest MRSP element between the minimum safe front end of the train and the EOA/LOA, AND

   - b) the target speed at the EOA/LOA

4.4.19.1.4.1 The speed resulting from 4.4.19.1.4 a) and b) is called the Lowest Supervised Speed within the Movement Authority (LSSMA)

4.4.19.1.4.2 Upon an order to toggle on the LSSMA display, the ERTMS/ETCS on-board equipment shall start a delay timer:

   - a) For order received from RBC/RIU: at the value of the time stamp of the message including the order.

   - b) For order received from balise group: at the time of passage over the first encountered balise of the balise group giving the order.

   - c) Exception to a) and b): for order that has been stored in the level transition buffer (see section 4.8.3): at the time the level transition is performed.

4.4.19.1.4.3 When the delay timer value becomes greater than the time-out value given by trackside, the ERTMS/ETCS on-board equipment shall display the LSSMA.

4.4.19.1.4.4 On reception of an order to toggle (on or off) the LSSMA display, a toggle on order which has not been executed yet (because the on-board delay timer has not reached the delay time-out value) shall be deleted by the on-board equipment.

4.4.19.1.4.5 If the LSSMA display is already toggled on, the ERTMS/ETCS on-board equipment shall toggle off the LSSMA display in case:

   - a) the clause 4.4.19.1.4.3 is not immediately fulfilled upon reception of a new order to toggle on the LSSMA display

   - b) an order to toggle off the LSSMA display is received.

<!-- end of page 35 -->

4.4.19.1.4.6 When entering the Limited Supervision mode, the LSSMA display shall be toggled off by the ERTMS/ETCS on-board equipment, unless a toggle on order is received and leads immediately to the display of the LSSMA as per clauses 4.4.19.1.4.2 and 4.4.19.1.4.3.

4.4.19.1.4.7 If the generic LS function marker is not stored on-board, the clauses 4.4.19.1.4.2 to 4.4.19.1.4.6 shall not apply and the LSSMA shall be displayed if:

   - a) the target speed at the EOA/LOA is lower than the Limited Supervision mode speed limit, AND

   - b) the LSSMA is lower than the maximum train speed.

4.4.19.1.4.8 The generic LS function marker shall be deleted by the ERTMS/ETCS on-board equipment as soon as a Limited Supervision mode profile is received without it in the same balise group message.

4.4.19.1.5 If receiving a "track ahead free" request from the RBC, the ERTMS/ETCS on-board equipment requests the driver to enter the "track ahead free" information.

4.4.19.1.6 To be in Limited Supervision mode, SSP and gradient are not required for the whole length of the train, but shall be at least available from the FRONT END of the train.

4.4.19.1.7 Intentionally deleted.

**4.4.19.2 Used in levels**

4.4.19.2.1 Used in levels 1 and 2.

### **4.4.19.3 Responsibilities**

4.4.19.3.1 The ERTMS/ETCS on-board equipment is responsible for the background supervision of the train movement to the extent permitted by the information provided by trackside.

4.4.19.3.1.1 Note: The Limited Supervision mode enables the train to be operated in areas equipped with lineside signals where ETCS does not have information regarding the status of some signals, i.e. not all signals are fitted with LEUs or connected to an RBC.

4.4.19.3.2 The driver must always observe the existing line-side information (signals, speed boards etc.) and National operating rules.

4.4.19.3.2.1 Note: the indications given to the driver by the ERTMS/ETCS on-board equipment do not substitute the observance of the line-side information. In particular the display of the LSSMA, if deemed necessary by the trackside, only complements the line-side information, e.g. in case there could be a discrepancy between this latter and the background supervision.

<!-- end of page 36 -->

## **4.4.20 PASSIVE SHUNTING**

### **4.4.20.1 Description**

4.4.20.1.1 The Passive Shunting mode is defined to manage the ERTMS/ETCS on-board equipment of a slave engine (NOT remote controlled, but mechanically coupled to the leading engine), being part of a shunting consist. This mode can also be used to carry on a shunting movement with a single engine fitted with one on-board equipment and two cabs, when the driver has to change the driving cab.

4.4.20.1.2 The desk of a Passive Shunting engine must be closed (since there is no driver, no information shall be shown).

4.4.20.1.3 As the engine is coupled to a leading engine, its ERTMS/ETCS on-board equipment shall not perform any train movement supervision.

4.4.20.1.4 The ERTMS/ETCS on-board equipment shall perform Train Position function; in particular, the front/rear end of the engine (i.e., not the train) shall be used to refer to train front/rear end.

4.4.20.1.5 It shall only be possible to enter in Passive Shunting mode from the Shunting mode; while in Shunting mode, the driver shall have the possibility to enable the function “Continue Shunting on desk closure”.

4.4.20.1.6 When the active desk is closed, the ERTMS/ETCS on-board equipment shall switch to Passive Shunting mode if the function “Continue Shunting on desk closure” is active and the passive shunting input information is set to "Passive shunting permitted" on the train interface. If the function “Continue Shunting on desk closure” is not active or the passive shunting input information is set to "Passive shunting not permitted", the ERTMS/ETCS on-board equipment shall switch to Stand-By mode instead.

4.4.20.1.7 The special function “Continue Shunting on desk closure” shall allow one and only one transition from Shunting mode to Passive Shunting mode. The special function shall be inactive once the Shunting mode is left.

4.4.20.1.8 If a desk of the Passive Shunting engine is opened and no “Stop Shunting on desk opening” information previously received from balise group is stored onboard, the ERTMS/ETCS on-board equipment shall switch to Shunting mode.

4.4.20.1.9 If a desk of the Passive Shunting engine is opened and “Stop Shunting on desk opening” information previously received from balise group is stored onboard, the ERTMS/ETCS on-board equipment shall switch to Stand By mode.

4.4.20.1.10 If possible, the train must not be stopped due to a safety critical fault in a Passive Shunting engine. The ERTMS/ETCS on-board equipment should therefore try to memorise the occurrence of such fault(s), which should be handled when the engine leaves the Passive Shunting mode.

4.4.20.1.11 While the ERTMS/ETCS on-board is in Passive Shunting mode, the reception of level transition orders has no immediate effect. The level transition announcements shall be

<!-- end of page 37 -->

rejected and an immediate level transition order or a conditional level transition order shall be stored but evaluated only when another mode than Shunting or Passive Shunting has been entered (i.e. when the Shunting movement is terminated).

4.4.20.1.11.1 Note: in case the Shunting movement is terminated through a direct transition to No Power mode, see clause 4.11.1.4.

4.4.20.1.12 When receiving a communication session establishment order, the ERTMS/ETCS onboard in Passive Shunting mode shall not establish the communication session, but shall store the RBC contact information.

4.4.20.1.13 When in Passive Shunting mode, the ERTMS/ETCS on-board shall not manage RBCRBC hand-over, except for storing the RBC contact information given at the RBC/RBC border.

4.4.20.1.14 Intentionally deleted.

4.4.20.1.15 In case of balise group message consistency error (refer to 3.16.2.4.4 and 3.16.2.5.1), the ERTMS/ETCS onboard equipment shall not command the service brake.

### **4.4.20.2 Used in levels**

4.4.20.2.1 Used in all levels: Level 0, level 1, level 2 and level NTC

**4.4.20.3 Responsibilities**

4.4.20.3.1 The ERTMS/ETCS on-board equipment of an engine in Passive Shunting mode has no responsibility for the train protection.

4.4.20.3.2 The notion of responsibility of the driver is not relevant for the Passive Shunting mode.

4.4.20.3.3 Note: The leading engine is responsible for the movement of the train. It is then the ERTMS/ETCS on-board equipment of the leading engine that is fully/partially/not responsible for the train protection, with respect to its mode.

<!-- end of page 38 -->

## **4.4.21 SUPERVISED MANOEUVRE**

**4.4.21.1 Description**

4.4.21.1.1 The purpose of the Supervised Manoeuvre mode is to enable an enhanced supervision of shunting movements similar to the Full Supervision mode, while the cab is not necessarily at the front of the shunting consist.

4.4.21.1.2 The Supervised Manoeuvre mode can only be entered upon the reception of an authorisation from the RBC, which is preceded by a driver action (i.e. at standstill selecting "Supervised Manoeuvre").

4.4.21.1.3 The selection of "Supervised Manoeuvre" by the driver shall only be possible if the “safe consist length” information is available on-board.

4.4.21.1.4 However, the Supervised Manoeuvre mode does not require that the Train Data set as listed in 3.18.3.2, which would fully correspond to the composition of the shunting consist, is captured by the ERTMS/ETCS on-board equipment. With the exception of 3.18.3.2 b), preconfigured default Train Data shall be used by the on-board.

4.4.21.1.5 To be in Supervised Manoeuvre mode, SSP and gradient are not required for the whole length of the consist, but shall be at least available from the front end of the consist.

4.4.21.1.6 Once in Supervised Manoeuvre mode, if SSP and gradient are not known for the whole length of the consist, an indication “ENTERING SM” shall be clearly displayed to the driver until SSP and gradient are known for the whole length of the consist.

4.4.21.1.6.1 Note: this indication may also be displayed in case the safe consist length information has been changed.

4.4.21.1.7  The ERTMS/ETCS on-board equipment shall perform the Train Position function, taking into account the clauses 3.6.1.3.4, 3.6.1.5.1, 3.6.4.1.5, 3.18.3.2.4 and the Train Data “safe consist length”. In case, upon reception of a Supervised Manoeuvre authorisation, the direction of its Movement Authority is opposite to the current train orientation, the following shall apply:

   - a) The new estimated train front end shall be obtained by shifting the current one in direction of the new authorisation, with a distance equal to the sum of the nominal consist lengths in front of and in rear of the engine respectively.

   - b) The new min safe front end shall be obtained by shifting the current max safe front end in direction of the new authorisation, with a distance equal to the sum of:

      - the max safe consist length in front of the engine and the min safe consist length in rear of the engine, if the train orientation was the same as the active cab, or

      - the max safe consist length in rear of the engine and the min safe consist length in front of the engine, if the train orientation was opposite to the active cab.

   - c) The new max safe front end shall be obtained by shifting the current min safe front end in direction of the new authorisation, with a distance equal to the sum of:

<!-- end of page 39 -->

   - the min safe consist length in front of the engine and the max safe consist length in rear of the engine, if the train orientation was the same as the active cab, or

   - the min safe consist length in rear of the engine and the max safe consist length in front of the engine, if the train orientation was opposite to the active cab

4.4.21.1.8  The ERTMS/ETCS on-board equipment shall supervise train movements against a dynamic speed profile.

4.4.21.1.9  The ERTMS/ETCS on-board equipment shall display the train speed, the permitted speed, the target distance, and the target speed to the driver (this list is not exhaustive – refer to chapter 4.7 “DMI depending on modes”). The ERTMS/ETCS on-board equipment shall also indicate whether a movement of the train corresponding to the direction of the Supervised Manoeuvre Movement Authority is obtained through traction applied with the direction controller in position forward or backward.

4.4.21.1.10  At standstill, the ERTMS/ETCS on-board equipment shall give the possibility to the driver to request a new Supervised Manoeuvre authorisation (e.g. in case of zig-zag movements when the end of a Movement Authority is reached).

4.4.21.1.11  While the ERTMS/ETCS on-board is in Supervised Manoeuvre mode, the reception of level transitions orders has no immediate effect. The level transition announcements shall be rejected and, upon reception of the order while already in Supervised Manoeuvre mode, an immediate level transition order or a conditional level transition order shall be stored but evaluated only when another mode than Supervised Manoeuvre or Shunting has been entered (i.e. when the Supervised Manoeuvre movement, possibly followed by a Shunting one, is terminated).

4.4.21.1.11.1 Note: in case the Supervised Manoeuvre movement is terminated through a direct transition to No Power mode, see clause 4.11.1.4.

4.4.21.1.12  If the safe consist length information is acquired from an external source and it becomes unavailable, the ERTMS/ETCS on-board equipment shall inform the driver and the trackside and, if the train is not at standstill, it shall command the service brake. The location based information stored on-board shall be shortened to the current position either immediately or, if the train was not at standstill, only when it has reached standstill. Refer to appendix A.3.4 for the exhaustive list of information, which shall be shortened.

4.4.21.1.13  The ERTMS/ETCS on-board equipment shall generate the information to the train interface that it is ready for remote shunting and that the engine orientation is either the same as or opposite to the direction of its Movement Authority.

### **4.4.21.2 Used in levels**

4.4.21.2.1  Used in level 2.

### **4.4.21.3 Responsibilities**

4.4.21.3.1  The ERTMS/ETCS on-board equipment is responsible for the train protection. However, the speed and distance monitoring function will rely on default Train Data.

<!-- end of page 40 -->

4.4.21.3.2  When approaching an EOA with a release speed, the driver is responsible for respecting the EOA, possibly in collaboration with other staff on site or on-board the shunting consist.

4.4.21.3.3  When performing e.g. a joining operation, the driver is responsible for checking the track occupancy, possibly in collaboration with other staff on site or on-board the shunting consist.

<!-- end of page 41 -->

# **4.5 Modes and on-board functions**

## **4.5.1 Introduction**

4.5.1.1 The following table specifies for each mode, which on-board functions are active or not, when it cannot be derived from the specific provisions of the mode itself (see § 4.4), from the mode transitions (see § 4.6), from the display of information according to the mode (see §4.7), from the acceptance criteria of trackside information according to the level and mode (see §4.8), from the handling of accepted and stored information upon a mode transition (see §4.10 and 4.11) and from any other explicit mode specific provision in the specifications. The term “function” in this section must be understood as an individual clause classified as on-board requirement or definition, or as a group of clauses classified as on-board requirement or definition, which is/are referred to in the “Related SRS §” (second column of the table).

4.5.1.2 Note: This table must be understood as a complement to all other SRS chapters. Conversely when a clause is not referred to in this table, it means that there are no additional requirements on the applicability of the clause depending on the mode to the ones, if any, that can be found in the rest of the SRS.

4.5.1.3 Note: for DMI depending on modes, refer to §4.7.

4.5.1.4 Unless stated otherwise, the clauses not referred to in this table shall not be applicable in NP mode.

4.5.1.5 With the exception of the clauses stipulated in the sections 4.4.3 and 4.4.5 respectively, the applicability of any other clause of the SRS is irrelevant in modes IS and SF.

## **4.5.2 Active Functions Table**

   - 4.5.2.1 X = functions shall be active, i.e. their corresponding on-board requirements and/or definitions shall apply

      - Empty case = functions shall be inactive, i.e. their corresponding on-board requirements and/or definitions shall not apply

      - NR = Not Relevant: This concerns the modes SF and IS in which the on-board behaviour cannot be harmonised

   - 4.5.2.2 Whenever a section number is referred to in the second column of the table, it means that all the clauses classified as on-board requirement belonging to this section are applicable/not applicable for the concerned mode, depending whether the corresponding function is marked as active/not active.

- **ONBOARD-FUNCTIONS RELATED N S P S S F A L S O S N U T P S I S R SRS § P B S H M S D S R S L L N R T F S N V**

- **Check Data Consistency**

<!-- end of page 42 -->

|**ONBOARD-FUNCTIONS**|**RELATED**<br>**SRS §**|**N**<br>**P**<br>**S**<br>**B**<br>**P**<br>**S**|**S**<br>**H**|**S**<br>**M**|**F**<br>**S**|**A**<br>**D**|**L**<br>**S**|**S**<br>**R**|<br> <br>**O**<br>**S**|**S**<br>**L**|<br> <br>**N**<br>**L**|**U**<br>**N**|<br> <br>**T**<br>**R**<br>|**P**<br>**T**|**S**<br>**F**|**I**<br>**S**|**S**<br>**N**|**R**<br>**V**|
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
|Check linking consistency|3.16.2.3<br>3.4.4.2.1.1<br>3.4.4.4|||X|X|X|X||X||||||<sup>NR</sup>|<sup>NR</sup>|||
|Check message consistency<br>for balise groups announced<br>by linking and for other balise<br>groups marked as linked while<br>the linking consistency is<br>checked|3.16.2.4.1<br>3.16.2.4.2<br>3.16.2.4.3<br>3.16.2.4.3.1|||X|X|X|X||X||||||<sup>NR</sup>|<sup>NR</sup>|||
|Check balise detection<br>degradation|3.16.2.7.1|||X|X|X|X||X||||||<sup>NR</sup>|<sup>NR</sup>|||
|Check balise cross-talk while<br>expecting repositioning<br>information|3.16.2.7.2||||X|X|X||X||||||<sup>NR</sup>|<sup>NR</sup>|||
|Check safe radio connection<br>(only level 2)|3.16.3.4|||X|X|X|X||X||||||<sup>NR</sup>|<sup>NR</sup>|||
|**Report Train Position:**|||||||||||||||||||
|When train reaches or leaves<br>standstill|3.6.5.1.4 a)<br>3.6.5.1.4 i)|X<br>{5}||X|X|X|X|X|X||||||<sup>NR</sup>|<sup>NR</sup>||X|
|When mode changes to…<sup>{1}</sup>|3.6.5.1.4 b)|X|X<br>{2}|X|X|X|X|X|X|X|X|X|X|X|<sup>NR</sup>|<sup>NR</sup>|X|X|
|When train integrity confirmed<br>by driver|3.6.5.1.4 c)|X||X|X|X|X|X|X|||X|<br>|X|<sup>NR</sup>|<sup>NR</sup>|X||
|When loss of train integrity is<br>detected|3.6.5.1.4 d)|X||X|X|X|X|X|X|||X|X|X|<sup>NR</sup>|<sup>NR</sup>|X|X|
|When train front/rear passes<br>an RBC/RBC border (only<br>level 2)|3.6.5.1.4 e)<br>3.6.5.1.4 k)|||X|X|X|X|X|X|X<br>{5}|<br>X||X||<sup>NR</sup>|<sup>NR</sup>|||
|When train rear passes a level<br>transition border (from level 2<br>to 0, NTC, 1)|3.6.5.1.4 f)||||X|X|X|X|X|X<br>{5}||X|X||<sup>NR</sup>|<sup>NR</sup>|X||
|When change of level due to<br>trackside order|3.6.5.1.4 g)||||X|X|X|X|X|X<br>{5}|<br>X||X||<sup>NR</sup>|<sup>NR</sup>|||
|When change of level due to<br>driver request|3.6.5.1.4 g)|X|||X|X|X|X|X||X||||<sup>NR</sup>|<sup>NR</sup>|||
|When establishing a session<br>with RBC|3.6.5.1.4 h)|X|X|X|X|X|X|X|X|X|X|X|X|X|<sup>NR</sup>|<sup>NR</sup>|X|X|
|When a data consistency error<br>is detected (only level 2)|3.6.5.1.4 l)|X||X|X|X|X|X|X|X|X|X|X|X|<sup>NR</sup>|<sup>NR</sup>|X|X|
|As requested by RBC…|3.6.5.1.4|X||X|X|X|X|X|X|X<br>{5}|<br>X|X|X|X|<sup>NR</sup>|<sup>NR</sup>|X|X|
|… or at every passage of an<br>LRBG compliant balise group|3.6.5.1.4 j)|X<br>{5}||X|X|X|X|X|X|X<br>{5}|<br>X|X|X|X|<sup>NR</sup>|<sup>NR</sup>|X|X|

<!-- end of page 43 -->

|**ONBOARD-FUNCTIONS**|**RELATED**<br>**SRS §**|**N**<br>**P**<br>**S**<br>**B**<br>**P**<br>**S**|**S**<br>**H**|**S**<br>**M**|**F**<br>**S**|**A**<br>**D**|**L**<br>**S**|**S**<br>**R**|<br> <br>**O**<br>**S**<br>**S**<br>**L**|**N**<br>**L**|<br>**U**<br>**N**|<br> <br>**T**<br>**R**<br>**P**<br>**T**|<br> <br>**S**<br>**F**|**I**<br>**S**|**S**<br>**N**|**R**<br>**V**|
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
|**Manage MA**|||||||||||||||||
|Request MA Cyclically with<br>respect to perturbation location<br>(T_MAR) or MA timer elapsing<br>(T_TIMEOUTRQST) (only<br>level 2)|3.8.2.2||||X|X|X||X||||<sup>NR</sup>|<sup>NR</sup>|||
|Request MA Cyclically when<br>“Start” is selected (only level 2)|3.8.2.3<br>4.4.11<br>5.4, 5.11|X||||||X||||X|<sup>NR</sup>|<sup>NR</sup>|||
|Request MA on reception of<br>"track ahead free up to the<br>level 2 transition location"|3.8.2.4|X|||X|X|X|X|X||X|X X|<sup>NR</sup>|<sup>NR</sup>|X||
|Request MA Cyclically on track<br>description deletion (only level<br>2)|3.8.2.5|||X|X|X|X||X||||<sup>NR</sup>|<sup>NR</sup>|||
|Determine EOA/LOA, SvL,<br>Danger Point, etc…|3.8.4<br>3.8.5|||X|X|X|X||X||||<sup>NR</sup>|<sup>NR</sup>|||
|**Determine Most Restrictive**<br>**Speed Profile, based on :**|||||||||||||||||
|SSP|3.13.7.2<br>3.11.2.2 a)|||X|X|X|X||X||||<sup>NR</sup>|<sup>NR</sup>|||
|ASP|3.13.7.2<br>3.11.2.2 b)|||X|X|X|X||X||||<sup>NR</sup>|<sup>NR</sup>|||
|TSR|3.13.7.2<br>3.11.2.2 c)|||X|X|X|X|X|X||X|<br>|<sup>NR</sup>|<sup>NR</sup>|||
|Signalling related speed<br>restriction when evaluated as a<br>speed limit|3.13.7.2<br>3.11.2.2 e)||||X|X|X||X||||<sup>NR</sup>|<sup>NR</sup>|||
|Mode related speed restriction|3.13.7.2<br>3.11.2.2 f)||X|X|||X|X|X||X|<br>|<sup>NR</sup>|<sup>NR</sup>||X|
|Train related speed restriction|3.13.7.2<br>3.11.2.2 d)|||X|X|X|X|X|X||X|<br>|<sup>NR</sup>|<sup>NR</sup>||X|
|STM max speed|3.13.7.2<br>3.11.2.2 g)||||X|X|X|X|X||X|<br>|<sup>NR</sup>|<sup>NR</sup>|X||
|STM system speed|3.13.7.2<br>3.11.2.2 h)||||X|X|X|X|X||X|<br>|<sup>NR</sup>|<sup>NR</sup>|||
|LX speed|3.13.7.2<br>3.11.2.2 i)|||X|X|X|X||X||||<sup>NR</sup>|<sup>NR</sup>|||
|Speed restriction to ensure a<br>given permitted braking<br>distance|3.13.7.2<br>3.11.2.2 k)||||X|X|X||X||||<sup>NR</sup>|<sup>NR</sup>|||

<!-- end of page 44 -->

|**ONBOARD-FUNCTIONS**|**RELATED**<br>**SRS §**|**N**<br>**P**<br> <br>|**S**<br>**B**|<br> <br>**P**<br>**S**|**S**<br>**H**|**S**<br>**M**|<br> <br>**F**<br>**S**|**A**<br>**D**|**L**<br>**S**<br> <br>|**S**<br>**R**|<br> <br>**O**<br>**S**<br>**S**<br>**L**|<br> <br>**N**<br>**L**|<br> <br>**U**<br>**N**|<br> <br>**T**<br>**R**<br>|**P**<br>**T**|**S**<br>**F**|**I**<br>**S**|**S**<br>**N**|**R**<br>**V**|
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
|Override related speed<br>restriction|3.13.7.2<br>3.11.2.2 j)||||X|||||X|||X|||<sup>NR</sup>|<sup>NR</sup>|||
|**Monitor speed and distance,**<br>**based on:**||||||||||||||||||||
|MA, release speed, mode<br>profile, non protected LX start<br>location, and route unsuitability<br>location|3.13.2.3.6.1<br>a)<br>3.13.8.2.1<br>b)&c)<br>3.13.9.4<br>3.13.10.5<br>3.13.1.5||||||X|X|X||X|||||<sup>NR</sup>|<sup>NR</sup>|||
|Gradient|3.13.4|||||X|X|X|X|X|X||X|||<sup>NR</sup>|<sup>NR</sup>|||
|MRSP|3.13.7||||X<br>{4}|X|X|X|X|X|X||X|||<sup>NR</sup>|<sup>NR</sup>|X<br>{3}<br>{4}|X<br>{4}|
|Allowed distance to run in Staff<br>Resp. mode|3.13.2.3.6.1<br>b)<br>3.13.8.2.1 d)<br>3.13.10.4.13.<br>1|||||||||X||||||<sup>NR</sup>|<sup>NR</sup>|||
|Supervised Manoeuvre MA,<br>release speed, non-protected<br>LX start location||||||X||||||||||<sup>NR</sup>|<sup>NR</sup>|||
|**Protect against Undesirable**<br>**Train Movements**||||||||||||||||||||
|Roll Away Protection|3.14.2||||X|X|X|X|X|X|X||X|<br>|X|<sup>NR</sup>|<sup>NR</sup>||X|
|Unauthorised Direction<br>Movement Protection|3.14.3|||||X|X|X|X|X|X||||X|<sup>NR</sup>|<sup>NR</sup>||X|
|**Other functions**||||||||||||||||||||
|Manage RBC/RBC Handover<br>(only level 2)|3.15.1, 5.15|||||X|X|X|X|X|X X|X||X||<sup>NR</sup>|<sup>NR</sup>|||
|Check of odometer accuracy<br>thresholds|3.6.8.5,<br>3.6.8.6,<br>3.6.8.7|||||X|X|X|X|X|X|||||<sup>NR</sup>|<sup>NR</sup>|||
|Storage of accumulated<br>underestimation /<br>overestimation in measuring<br>the movements over a defined<br>total distance|3.6.8.2 to 4|||X|X|X|X|X|X|X|X X|X|X|X|X|<sup>NR</sup>|<sup>NR</sup>|X|X|

### **Figure 1: Active Functions table**

<!-- end of page 45 -->

{1} For ETCS level 2 this may imply establishing a radio communication session if none is established

- {2} Exception: the transition PS => SH shall not be reported

- {3} In case the ERTMS on-board equipment is interfaced to the National System through an STM, refer to SUBSET-035 for details

- {4} Ceiling Speed Monitoring only (no braking curve)

- {5} Only if a radio communication session is already established

<!-- end of page 46 -->

# **4.6 Transitions between modes**

## **4.6.1 Symbols**

4.6.1.1 The indication “ **4>** ” means: The condition n°4 must be fulfilled to trigger the transition

4.6.1.2 From the mode located in the column

4.6.1.3 To the mode that is indicated by the arrow “ **>** ”.

4.6.1.4 Each transition from a given mode receives a priority order (indicated by “ **-px-** ”, x is the priority order) to avoid a conflict between the different transitions when they occur at the same time (i.e. in the same clock cycle). P1 has a higher priority than P2.

4.6.1.5 Some transitions have received the same priority order. This has been decided when it is obvious that these transitions cannot occur at the same time, and so can never lead to a conflicting situation (for example, the RBC cannot give in the same time a MA for FS and a MA for OS to a given engine, this is why the transition “from SR to FS” and the transition “from SR to OS” have the same priority order).

4.6.1.6 "16, 17, 18" means "16 or 17 or 18".

<!-- end of page 47 -->

## **4.6.2 Transitions Table**

<!-- rebuilt from the word positions on page 48 of the PDF; a transition goes from the mode of the column to the mode of the row, empty cells are the shaded ones -->

| |from NP|from SB|from PS|from SH|from SM|from FS|from AD|from LS|from SR|from OS|from SL|from NL|from UN|from TR|from PT|from SF|from IS|from SN|from RV|
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
|**to NP**|**NP**|<29<br>-p2-|<29<br>-p2-|<29<br>-p2-|<29<br>-p2-|<29<br>-p2-|<29<br>-p2-|<29<br>-p2-|<29<br>-p2-|<29<br>-p2-|<29<br>-p2-|<29<br>-p2-|<29<br>-p2-|<29<br>-p2-|<29<br>-p2-|<29<br>-p2-||<29<br>-p2-|<29<br>-p2-|
|**to SB**|4><br>-p2-|**SB**|<22<br>-p4-|<19, 27, 30<br>-p5-|<28, 82<br>-p4-|<28, 83<br>-p5-|<28, 83<br>-p5-|<28, 83<br>-p5-|<28, 83<br>-p5-|<28, 83<br>-p5-|<2, 3<br>-p3-|<28, 47<br>-p3-|<28, 83<br>-p6-||<28, 83<br>-p4|||<28, 83<br>-p6-|<28<br>-p4-|
|**to PS**|||**PS**|<26<br>-p5-||||||||||||||||
|**to SH**||5, 6, 50><br>-p7-|23><br>-p4|**SH**|<6<br>-p6-|<5, 6, 50, 51<br>-p6-|<5, 6, 50, 51<br>-p6|<5, 6, 50, 51<br>-p6-|<5, 6, 51<br>-p6-|<5, 6, 50, 51<br>-p6-|||<5, 61<br>-p7-|<68<br>-p4|<5, 6, 50, 78<br>-p5-|||<5, 61<br>-p7||
|**to SM**||81><br>-p8-|||**SM**|<81<br>-p7-|<81<br>-p7-|<81<br>-p7-|<81<br>-p7-|<81<br>-p7-|||||<81<br>-p6-|||||
|**to FS**||10><br>-p7-||||**FS**|<9, 24, 33, 48, 53<br>-p7-|<76<br>-p6-|<31, 32<br>-p6-|<75<br>-p6-|||<25<br>-p7-||<31<br>-p5-|||<25<br>-p7-||
|**to AD**||||||80><br>-p7-|**AD**|||||||||||||
|**to LS**||70><br>-p7-||||70, 72><br>-p6-|70, 72><br>-p6-|**LS**|<72<br>-p6-|<70, 74<br>-p6-|||<71<br>-p7-||<70<br>-p5-|||<71<br>-p7-||
|**to SR**||8, 37><br>-p7-||||37><br>-p6-|37><br>-p6-|37><br>-p6-|**SR**|<37<br>-p6-|||<44, 45<br>-p4-||<8, 37<br>-p5-|||<44, 45<br>-p4-||
|**to OS**||15><br>-p7-||||15, 40><br>-p6-|15, 40><br>-p6-|15, 73><br>-p6-|40><br>-p6-|**OS**|||<34<br>-p7-||<15<br>-p5-|||<34<br>-p7-||
|**to SL**||14><br>-p5-|14><br>-p4||||||||**SL**|||||||||
|**to NL**||46><br>-p6-||46><br>-p5-|46><br>-p6-|46><br>-p6-|46><br>-p6-|46><br>-p6-|46><br>-p6-|46><br>-p6-||**NL**||||||||
|**to UN**||60><br>-p7-||||21><br>-p6-|21><br>-p6-|21><br>-p6-|21><br>-p6-|21><br>-p6-|||**UN**|<62<br>-p4-|<77<br>-p5-|||<21<br>-p7-||
|**to TR**||20><br>-p4-||49, 52, 65><br>-p4-|16, 17, 20, 41, 65, 66, 69><br>-p5-|11, 12, 16, 17, 18, 20, 41, 65, 66, 69><br>-p4-|11, 12, 16, 17, 18, 20, 41, 65, 66, 69><br>-p4-|11, 12, 16, 17, 18, 20, 41, 65, 66, 69><br>-p4-|18, 20, 42, 43, 36, 54, 65><br>-p4-|11, 12, 16, 17, 18, 20, 41, 65, 66, 69><br>-p4-|||67, 39, 20><br>-p5-|**TR**||||<67, 39, 38, 35, 20<br>-p5-||
|**to PT**||||||||||||||7><br>-p4-|**PT**|||||
|**to SF**||13><br>-p3-||13><br>-p3-|13, 84><br>-p3-|13, 84><br>-p3-|13, 84><br>-p3-|13, 84><br>-p3-|13, 84><br>-p3-|13, 84><br>-p3-|||13><br>-p3-|13><br>-p3-|13><br>-p3-|**SF**||<13<br>-p3-|<13<br>-p3-|
|**to IS**|1><br>-p1-|1><br>-p1-|1><br>-p1-|1><br>-p1-|1><br>-p1-|1><br>-p1-|1><br>-p1-|1><br>-p1-|1><br>-p1-|1><br>-p1-|1><br>-p1-|1><br>-p1-|1><br>-p1-|1><br>-p1-|1><br>-p1-|1><br>-p1-|**IS**|<1<br>-p1-|<1<br>-p1-|
|**to SN**||58><br>-p7-||||56><br>-p6-|56><br>-p6-|56><br>-p6-|56><br>-p6-|56><br>-p6-|||56><br>-p7-|63><br>-p4-|79><br>-p5-|||**SN**||
|**to RV**||||||59><br>-p6-|59><br>-p6-|59><br>-p6-||59><br>-p6-|||||||||**RV**|

**Figure 2: Transition table.**

<!-- derived from the matrix above, not part of SUBSET-026: the same transitions as a list -->

|From|To|Conditions (any of)|Priority|
|---|---|---|---|
|NP|SB|4|p2|
|NP|IS|1|p1|
|SB|NP|29|p2|
|SB|SH|5, 6, 50|p7|
|SB|SM|81|p8|
|SB|FS|10|p7|
|SB|LS|70|p7|
|SB|SR|8, 37|p7|
|SB|OS|15|p7|
|SB|SL|14|p5|
|SB|NL|46|p6|
|SB|UN|60|p7|
|SB|TR|20|p4|
|SB|SF|13|p3|
|SB|IS|1|p1|
|SB|SN|58|p7|
|PS|NP|29|p2|
|PS|SB|22|p4|
|PS|SH|23|p4|
|PS|SL|14|p4|
|PS|IS|1|p1|
|SH|NP|29|p2|
|SH|SB|19, 27, 30|p5|
|SH|PS|26|p5|
|SH|NL|46|p5|
|SH|TR|49, 52, 65|p4|
|SH|SF|13|p3|
|SH|IS|1|p1|
|SM|NP|29|p2|
|SM|SB|28, 82|p4|
|SM|SH|6|p6|
|SM|NL|46|p6|
|SM|TR|16, 17, 20, 41, 65, 66, 69|p5|
|SM|SF|13, 84|p3|
|SM|IS|1|p1|
|FS|NP|29|p2|
|FS|SB|28, 83|p5|
|FS|SH|5, 6, 50, 51|p6|
|FS|SM|81|p7|
|FS|AD|80|p7|
|FS|LS|70, 72|p6|
|FS|SR|37|p6|
|FS|OS|15, 40|p6|
|FS|NL|46|p6|
|FS|UN|21|p6|
|FS|TR|11, 12, 16, 17, 18, 20, 41, 65, 66, 69|p4|
|FS|SF|13, 84|p3|
|FS|IS|1|p1|
|FS|SN|56|p6|
|FS|RV|59|p6|
|AD|NP|29|p2|
|AD|SB|28, 83|p5|
|AD|SH|5, 6, 50, 51|p6|
|AD|SM|81|p7|
|AD|FS|9, 24, 33, 48, 53|p7|
|AD|LS|70, 72|p6|
|AD|SR|37|p6|
|AD|OS|15, 40|p6|
|AD|NL|46|p6|
|AD|UN|21|p6|
|AD|TR|11, 12, 16, 17, 18, 20, 41, 65, 66, 69|p4|
|AD|SF|13, 84|p3|
|AD|IS|1|p1|
|AD|SN|56|p6|
|AD|RV|59|p6|
|LS|NP|29|p2|
|LS|SB|28, 83|p5|
|LS|SH|5, 6, 50, 51|p6|
|LS|SM|81|p7|
|LS|FS|76|p6|
|LS|SR|37|p6|
|LS|OS|15, 73|p6|
|LS|NL|46|p6|
|LS|UN|21|p6|
|LS|TR|11, 12, 16, 17, 18, 20, 41, 65, 66, 69|p4|
|LS|SF|13, 84|p3|
|LS|IS|1|p1|
|LS|SN|56|p6|
|LS|RV|59|p6|
|SR|NP|29|p2|
|SR|SB|28, 83|p5|
|SR|SH|5, 6, 51|p6|
|SR|SM|81|p7|
|SR|FS|31, 32|p6|
|SR|LS|72|p6|
|SR|OS|40|p6|
|SR|NL|46|p6|
|SR|UN|21|p6|
|SR|TR|18, 20, 42, 43, 36, 54, 65|p4|
|SR|SF|13, 84|p3|
|SR|IS|1|p1|
|SR|SN|56|p6|
|OS|NP|29|p2|
|OS|SB|28, 83|p5|
|OS|SH|5, 6, 50, 51|p6|
|OS|SM|81|p7|
|OS|FS|75|p6|
|OS|LS|70, 74|p6|
|OS|SR|37|p6|
|OS|NL|46|p6|
|OS|UN|21|p6|
|OS|TR|11, 12, 16, 17, 18, 20, 41, 65, 66, 69|p4|
|OS|SF|13, 84|p3|
|OS|IS|1|p1|
|OS|SN|56|p6|
|OS|RV|59|p6|
|SL|NP|29|p2|
|SL|SB|2, 3|p3|
|SL|IS|1|p1|
|NL|NP|29|p2|
|NL|SB|28, 47|p3|
|NL|IS|1|p1|
|UN|NP|29|p2|
|UN|SB|28, 83|p6|
|UN|SH|5, 61|p7|
|UN|FS|25|p7|
|UN|LS|71|p7|
|UN|SR|44, 45|p4|
|UN|OS|34|p7|
|UN|TR|67, 39, 20|p5|
|UN|SF|13|p3|
|UN|IS|1|p1|
|UN|SN|56|p7|
|TR|NP|29|p2|
|TR|SH|68|p4|
|TR|UN|62|p4|
|TR|PT|7|p4|
|TR|SF|13|p3|
|TR|IS|1|p1|
|TR|SN|63|p4|
|PT|NP|29|p2|
|PT|SB|28, 83|p4|
|PT|SH|5, 6, 50, 78|p5|
|PT|SM|81|p6|
|PT|FS|31|p5|
|PT|LS|70|p5|
|PT|SR|8, 37|p5|
|PT|OS|15|p5|
|PT|UN|77|p5|
|PT|SF|13|p3|
|PT|IS|1|p1|
|PT|SN|79|p5|
|SF|NP|29|p2|
|SF|IS|1|p1|
|SN|NP|29|p2|
|SN|SB|28, 83|p6|
|SN|SH|5, 61|p7|
|SN|FS|25|p7|
|SN|LS|71|p7|
|SN|SR|44, 45|p4|
|SN|OS|34|p7|
|SN|UN|21|p7|
|SN|TR|67, 39, 38, 35, 20|p5|
|SN|SF|13|p3|
|SN|IS|1|p1|
|RV|NP|29|p2|
|RV|SB|28|p4|
|RV|SF|13|p3|
|RV|IS|1|p1|

<!-- end of page 48 -->

## **4.6.3 Transitions Conditions Table**

|**Condition**<br>**Id**|**Content of the conditions**|
|---|---|
|[1]|The driver isolates the ERTMS/ETCS on-board equipment.|
|[2]|(a desk is open)|
|[3]|(The sleeping input information is set to "Sleeping not requested" is received any<br>more) AND (train is at standstill)|
|[4]|The ERTMS/ETCS on-board equipment is powered.|
|[5]|(train is at standstill) AND (ERTMS/ETCS level is 0 or NTC or 1) AND (driver selects<br>Shunting mode)|
|[6]|(train is at standstill) AND (ERTMS/ETCS level is 2) AND (reception of the<br>information “Shunting granted by RBC”, due to a Shunting request from the driver)|
|[7]|(the driver acknowledges the train trip) AND (the train is at standstill) AND (the<br>ERTMS/ETCS level is different from 0, NTC)|
|[8]|(Staff Responsible mode is proposed to the driver) AND (driver acknowledges)**{4}**|
|[9]|(MA+SSP+gradient are on-board) AND (the ERTMS/ETCS on-board equipment<br>starts to indicate to the driver that an unprotected LX is being approached (see<br>clause 5.16.1.4))|
|[10]|(valid Train Data is stored on board) AND (MA (excluding with Supervised<br>Manoeuvre authorisation) + SSP +gradient are on-board) AND (the train position<br>confidence interval does not overlap any Mode Profile)|
|[11]|(While being in release speed monitoring, the on-board receives a balise group<br>whose first possible location is known by linking information to be in rear of the EOA<br>by a distance shorter than the distance between the active Eurobalise antenna and<br>the front end of the train, at the EOA or in advance of the EOA) AND (ERTMS/ETCS<br>level is 2).|
|[12]|(The train/engine overpasses the EOA/LOA with its min safe antenna position) AND<br>(ERTMS/ETCS level is 1)**see {9} here under**|
|[13]|The ERTMS/ETCS on-board equipment detects a fault that affects safety|
|[14]|(The sleeping input information is set to "Sleeping requested") AND (train is at<br>standstill) AND (all desks connected to the ERTMS/ETCS on-board equipment are<br>closed)|
|[15]|(An ackn. request for On Sight is displayed to the driver) AND (the driver<br>acknowledges)**see {1} here under**|
|[16]|(The train/engine overpasses the EOA/LOA with its min safe front end) AND<br>(ERTMS/ETCS level is 2).**see {9} here under**|
|[17]|The onboard reacts according to a linking reaction set to “trip”.|

<!-- end of page 49 -->

|[18]|(the train/engine receives and uses a trip order given by balise) AND (override is not<br>active)|
|---|---|
|[19]|(driver selects “exit Shunting”) AND (train is at standstill).|
|[20]|(unconditional emergency stop message is accepted)|
|[21]|(ERTMS/ETCS level switches to 0)**see {2} here under**|
|[22]|(a desk is open) AND (”Stop Shunting on desk opening” information is stored<br>onboard)|
|[23]|(a desk is open) AND (no ”Stop Shunting on desk opening” information is stored<br>onboard)|
|[24]|(MA+SSP+gradient are on-board) AND (the ERTMS/ETCS on-board equipment<br>commands the service brake or the emergency brake)|
|[25]|(ERTMS/ETCS level switches to 1 or 2) AND (MA+SSP+gradient are on-board) AND<br>(the train position confidence interval does not overlap any Mode Profile)|
|[26]|(desks are closed) AND (”Continue Shunting on desk closure” function is active)<br>AND (The passive shunting input information is set to "Passive shunting permitted")|
|[27]|(desks are closed) AND (”Continue Shunting on desk closure” function is not active)|
|[28]|(desks are closed)|
|[29]|the ERTMS/ETCS on-board equipment is NOT powered|
|[30]|(desks are closed) AND (The passive shunting input information is set to "Passive<br>shunting not permitted")|
|[31]|(MA+SSP+gradient are on-board) AND (the train position confidence interval does not<br>overlap any Mode Profile) AND (ERTMS/ETCS level is 2)|
|[32]|(MA+SSP+gradient are on-board) AND (the train position confidence interval does<br>not overlap any Mode Profile) AND (ERTMS/ETCS level is 1) AND (no trip order is<br>given by balise)|
|[33]|(MA+SSP+gradient are on-board) AND (the AD mode is no longer requested by the<br>ERTMS/ATO on-board,**see {10} here under**)|
|[34]|(A Mode Profile defining an On Sight area is on-board) AND (The train position<br>confidence interval overlaps this On Sight area) AND (Starting from the min safe<br>front end of the train this On Sight area is the furthest area that the train position<br>confidence interval overlaps within the Mode Profile) AND (The ERTMS/ETCS level<br>switches to 1 or 2)|
|[35]|(driver selects Shunting mode) AND (The ERTMS/ETCS on-board equipment is<br>interfaced to the National System through an STM) AND (a National Trip Procedure<br>is active,**see {8} here under**)|
|[36]|(the identity of the overpassed balise group is not in the list of expected balises<br>related to SR mode) AND (override is not active).|
|[37]|(driver selects “override”) AND (train speed is under or equal to the speed limit for<br>triggering the “override” function)**see {3} here under**|

<!-- end of page 50 -->

|[38]|(The ERTMS/ETCS on-board equipment is interfaced to the National System through<br>an STM) AND (The ERTMS/ETCS level switches to 0,1 or 2) AND (a National Trip<br>Procedure is active)**see {8} here under**|
|---|---|
|[39]|(The ERTMS/ETCS level switches to 1 or 2) AND (no MA has been accepted)|
|[40]|(A Mode Profile defining an On Sight area is on-board) AND (The train position<br>confidence interval overlaps this On Sight area) AND (Starting from the min safe<br>front end of the train this On Sight area is the furthest area that the train position<br>confidence interval overlaps within the Mode Profile)|
|[41]|(T_NVCONTACT is passed) AND (associated reaction is “train trip”)|
|[42]|(The train/engine overpasses the SR distance with its estimated front end) AND<br>(override is not active)|
|[43]|(The train/engine overpasses the former EOA/LOA (when Override was activated)<br>with the min safe antenna position) AND (override is not active),**see {3} and {9}**<br>**here under**|
|[44]|(“override” function is active) AND (ERTMS/ETCS level switches to 1)**see** **{3} here**<br>**under**|
|[45]|(“override” function is active) AND (no unconditional emergency stop message has<br>been received) AND (ERTMS/ETCS level switches to 2)**see** **{3} here under**|
|[46]|(Driver selects NON LEADING) AND (train is at standstill) AND (The non-leading<br>input information is set to "Non-leading permitted")|
|[47]|(The non-leading input information is set to "Non-leading not permitted") AND (train<br>is at standstill)|
|[48]|(MA+SSP+gradient are on-board) AND (SSP and gradient are no longer known for<br>the whole length of the train)|
|[49]|(reception of information “stop if in shunting”) AND (override is not active)|
|[50]|(An ackn. request for Shunting is displayed to the driver) AND (the driver<br>acknowledges)**see {5} here under**|
|[51]|(A Mode Profile defining a Shunting area is on-board) AND (The max safe front end<br>of the train is in advance of the entry of the Shunting area)|
|[52]|(the identity of the overpassed balise group is not in the list of expected balise groups<br>related to SH mode) AND (override is not active).|
|[53]|(MA+SSP+gradient are on-board) AND (the driver selects "ATO disengage" or sets<br>the ATO selector to "Stand-by")|
|[54]|(reception of information “stop if in Staff Responsible”) AND (no list of expected<br>balise groups related to SR mode has been received or the list of expected balise<br>groups related to SR mode does not include the identity of the overpassed balise<br>group) AND (override is not active)|
|[56]|(the ERTMS/ETCS level switches to “NTC”)|
|[58]|(the ERTMS/ETCS level is “NTC”) AND (an acknowledgement request for SN mode<br>is displayed to the driver) AND (the driver acknowledges)|

<!-- end of page 51 -->

|[59]|(train is at standstill) AND (driver has acknowledged the reversing)**see {6} here**<br>**under**|
|---|---|
|[60]|(an acknowledgement request for UN mode is displayed to the driver) AND (the<br>driver acknowledges)|
|[61]|(A Mode Profile defining a Shunting area is on-board) AND (The max safe front end<br>of the train is in advance of the entry of the Shunting area) AND (The ERTMS/ETCS<br>level switches to 1 or 2)|
|[62]|(the driver acknowledges the train trip) AND (the train is at standstill) AND (the<br>ERTMS/ETCS level is 0) AND (valid Train Data is on-board)|
|[63]|(the driver acknowledges the train trip) AND (the train is at standstill) AND (the<br>ERTMS/ETCS level is NTC) AND (valid Train Data is on-board)|
|[65]|(The system version number X of a received balise telegram is greater than the<br>highest version number X supported by the on-board equipment) AND<br>(ERTMS/ETCS level is 1 or 2)|
|[66]|The expected balise group referred in the linking information with an ID not set to<br>“unknown” is passed in the unexpected direction|
|[67]|(The ERTMS/ETCS level switches to level 1) AND (a trip order has been received)<br>AND (override is not active)|
|[68]|(the driver acknowledges the train trip) AND (the train is at standstill) AND (the<br>ERTMS/ETCS level is 0 or NTC) AND (no valid Train Data is on-board)|
|[69]|Estimated train front end is in rear of the start location of either SSP or gradient<br>profile stored on-board|
|[70]|(An ackn. request for Limited Supervision is displayed to the driver) AND (the driver<br>acknowledges)**see {7} here under**|
|[71]|(A Mode Profile defining a Limited Supervision area is on-board) AND (The train<br>position confidence interval overlaps this Limited Supervision area) AND (Starting<br>from the min safe front end of the train this Limited Supervision area is the furthest<br>area that the train position confidence interval overlaps within the Mode Profile) AND<br>(The ERTMS/ETCS level switches to 1 or 2)|
|[72]|(A Mode Profile defining a Limited Supervision area is on-board) AND (The train<br>position confidence interval overlaps this Limited Supervision area) AND (Starting<br>from the min safe front end of the train this Limited Supervision area is the furthest<br>area that the train position confidence interval overlaps within the Mode Profile).|
|[73]|(A Mode Profile defining an On Sight area is on-board) AND (The train position<br>confidence interval overlaps this On Sight area) AND (The estimated front end of the<br>train is not inside an LS acknowledgement area) AND (Starting from the min safe<br>front end of the train this On Sight area is the furthest area that the train position<br>confidence interval overlaps within the Mode Profile)|
|[74]|(A Mode Profile defining a Limited Supervision area is on-board) AND (The train<br>position confidence interval overlaps this Limited Supervision area) AND (The<br>estimated front end of the train is not inside an OS acknowledgement area) AND<br>(Startingfrom the min safe front end of the train this Limited Supervision area is the|

<!-- end of page 52 -->

||furthest area that the train position confidence interval overlaps within the Mode<br>Profile)|
|---|---|
|[75]|(The estimated front end of the train is not inside an OS acknowledgement area)<br>AND (The train position confidence interval does not overlap any Mode Profile)|
|[76]|(The estimated front end of the train is not inside an LS acknowledgement area) AND<br>(The train position confidence interval does not overlap any Mode Profile)|
|[77]|(the ERTMS/ETCS level switches to 0) AND (valid Train Data is on-board)|
|[78]|(the ERTMS/ETCS level switches to 0 or NTC) AND (no valid Train Data is on-board)|
|[79]|(the ERTMS/ETCS level switches to NTC) AND (valid Train Data is on-board)|
|[80]|(The AD mode is requested by the ERTMS/ATO on-board,**see {10} here under**)<br>AND (SSP and gradient are known for the whole length of the train) AND (the<br>ERTMS/ETCS on-board equipment does not command the service brake) AND (the<br>ERTMS/ETCS on-board equipment does not command the emergency brake) AND<br>(the driver selects "ATO engage")|
|[81]|An MA, which is included in a “Supervised Manoeuvre authorisation” due to a<br>Supervised Manoeuvre request by the driver, is received from the RBC|
|[82]|(driver selects “Exit of Supervised Manoeuvre”) AND (train is at standstill).|
|[83]|(valid Train Data is stored on-board) AND (The safe consist length in front the engine<br>becomes different from zero)|
|[84]|The accumulated underestimation/overestimation in measuring the movements over<br>a defined total distance exceeds the safety threshold|

{1} The request to acknowledge On Sight is displayed to the driver only if certain conditions are fulfilled. These conditions are not specified here. See the “On Sight” procedure” in 5.9.

{2} This transition to the Unfitted mode is also a transition of level. For further information, See the “Level Transition” procedure in 5.10 and the “Start Of Mission” procedure in 5.4.

{3} See the “Override” procedure” of SRS-§5.

{4} The Staff Responsible mode is proposed to the driver only if certain conditions are fulfilled. These conditions are not specified here. See the “Start Of Mission” procedure and the "Train Trip" procedure of SRS-§5.

{5} The request to acknowledge Shunting is displayed to the driver only if certain conditions are fulfilled. These conditions are not specified here. See the “Entry in Shunting” procedure and the “Start Of Mission” procedure of SRS-§5.

{6} The request to acknowledge Reversing is displayed to the driver when certain conditions are fulfilled. These conditions are not specified here. See the “reversing” procedure of SRS-§5.

{7} The request to acknowledge Limited Supervision is displayed to the driver only if certain conditions are fulfilled. These conditions are not specified here. See the “Limited Supervision” procedure” of SRS-§5 (for transitions from FS/AD/OS/UN to LS) and the "Start of mission" procedure (for transition from SB to LS).

{8} Refer to Subset-035 for details.

<!-- end of page 53 -->

{9} The condition shall also be applicable to a location considered by the ERTMS/ETCS on-board equipment as temporary EOA, as per clause 3.12.2.4, 3.12.4.7 or 3.12.5.8.

{10} Refer to Subset-125 for details.

<!-- end of page 54 -->

# **4.7 DMI depending on modes**

## **4.7.1 Introduction**

4.7.1.1 The DMI is an interface that allows the direct exchange of information between the driver and the ERTMS/ETCS onboard equipment. The indirect exchange of information done via the train interface (e.g. a driver’s action on the service brake used for the service brake feedback, opening/closing the desk) is not part of the DMI.

4.7.1.2 The device(s) used to select “ERTMS/ETCS onboard equipment powered/unpowered” is (are) not part of the DMI.

4.7.1.3 The device(s) used to select/indicate “ERTMS/ETCS onboard equipment isolated/not isolated” is (are) part of the DMI.

4.7.1.4 Intentionally deleted.

4.7.1.5 Information (input or output) only relevant for National System and not originated by the ERTMS/ETCS on-board is not included in the following section.

## **4.7.2 DMI versus Mode Table**

4.7.2.1.1 X = active: For a DMI output, this means that the output information shall be shown to the driver when the ERTMS/ETCS onboard equipment is in the mode indicated in the column. For a DMI input, this means that it shall be possible for the driver to enter this information when the ERTMS/ETCS onboard equipment is in the mode indicated in the column).

4.7.2.1.2 A = available: This means that the input/output shall become active ONLY if another condition(s) is (are) fulfilled. This condition(s) are not described here.

4.7.2.1.3 Grey cells: availability and meaning defined by national system.

4.7.2.1.4 NA = Not Applicable: This concerns the modes SF and IS in which the DMI inputs and outputs cannot be determined.

|**Input information**|N|S|P|S|S|F|A|L|S|O|S<br>N|U|T|P|S|I|S|R|
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
||P|B|S|H|M|S|D|S|R|S|L<br>L|N|R|T|F|S|N|V|
|Train Data (refer to 3.18.3.2)||A||||A|A|A|A|A||A|||NA|NA|A||
|Selection of language||A||A|A|A|A|A|A|A|A|A|A|A|NA|NA|A|A|
|Driver id||A||A|A|A|A|A|A|A|A|A|||NA|NA|A||
|Train running number||A|||A|A|A|A|A|A|A|A|||NA|NA|A||
|ERTMS/ETCS level||A||||A|A|A|A|A|A|A|||NA|NA|A||
|Track Adhesion factor||A|||A|A|A|A|A|A||A|||NA|NA|A||
|RBC contact information||A|||A|A|A|A|A|A|A|||A|NA|NA|||

<!-- end of page 55 -->

|**Input information**|N<br>P|S<br>B|P<br>S|S<br>H|S<br>M|F<br>S|A<br>D|L<br>S|S<br>R|O<br>S|S<br>L<br>N<br>L|U<br>N|T<br>R<br>P<br>T|S<br>F|I<br>S|S<br>N|R<br>V|
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
|Radio network information<br>-<br>Radio network type<br>-<br>GSM-R radio network-id||A|||A|A|A|A|A|A|A|A|A|NA|NA|A||
|Perform mission with only one<br>radio system||A|||A|A|A|A|A|A|A|A|A|NA|NA|A||
|Train integrity confirmation||A|||A|A|A|A|A|A||A|A|NA|NA|A||
|Start||A|||||||A||||A|NA|NA|||
|Override request||A||A||A|A|A|A|A||A|A|NA|NA|A||
|Shunting request||A|||A|A|A|A|A|A||A|A|NA|NA|A||
|“Continue Shunting on desk<br>closure” request||||A||||||||||NA|NA|||
|“Exit of Shunting” request||||A||||||||||NA|NA|||
|Supervised Manoeuvre request||A|||A|A|A|A|A|A|||A|NA|NA|||
|“Exit of Supervised Manoeuvre”<br>request|||||A|||||||||NA|NA|||
|Non Leading request||A||A|A|A|A|A|A|A||||NA|NA|||
|Ackn of fixed text information||A|||A|A|A|A|A|A||A|A<br>A|NA|NA||A|
|Ackn of plain text information||A|||A|A|A|A|A|A||A|A<br>A|NA|NA||A|
|Ackn of level transition||A||A||A|A|A|A|A||A|A|NA|NA|A||
|Ackn of Limited Supervision<br>mode||A||||A|A|A||A|||A|NA|NA|||
|Ackn of On Sight mode||A||||A|A|A||A|||A|NA|NA|||
|Ackn of Shunting mode||A||A||A|A|A||A|||A|NA|NA|||
|Ackn of Staff Resp. mode||A|||||||||||A|NA|NA|||
|Ackn of Unfitted mode||A||||||||||||NA|NA|||
|Ackn of Reversing mode||||||A|A|A||A||||NA|NA|||
|Ackn of SN mode||A||||||||||||NA|NA|||
|Ackn of Train Trip|||||||||||||A|NA|NA|||
|Ackn for Roll Away Protection||||A|A|A||A|A|A||A|A|NA|NA||A|
|Ackn<br>for<br>Unauthorised<br>Direction Movement Protection|||||A|A||A|A|A|||A|NA|NA||A|
|Ackn for Standstill Supervision||A||||||||||||NA|NA|||
|Ackn for Post Trip distance<br>exceeded|||||||||||||A|NA|NA|||
|Ackn of Train Data change from<br>source different from the driver||||||A|A|A|A|A||A|A|NA|NA|A||
|Ackn for reversing distance<br>exceeded||||||||||||||NA|NA||A|
|Ackn of non-leading no longer<br>permitted|||||||||||A|||NA|NA|||

<!-- end of page 56 -->

|**Input information**|N<br>P|S<br>B|P<br>S|S<br>H|S<br>M|F<br>S|A<br>D|L<br>S|S<br>R|O<br>S|S<br>L|N<br>L|U<br>N|T<br>R|P<br>T|S<br>F|I<br>S|S<br>N|R<br>V|
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
|Track Ahead Free||A||||||A|A|A|||||A|NA|NA|||
|SR mode speed limit and<br>distance|||||||||A|||||||NA|NA|||
|Virtual Balise Cover||A||||||||||||||NA|NA|||
|BTM alarm reaction inhibition||A||A|||||A|||||||NA|NA|||
|Revoke BTM alarm reaction<br>inhibition||A||A|||||A|||||||NA|NA|||
|Isolation|X|X|X|X|X|X|X|X|X|X|X|X|X|X|X|X|X|X|X|
|ATO selector||A||A|A|A|A|A|A|A||A|A|A|A|NA|NA|A|A|
|ATO engage||||||A|A|||||||||NA|NA|||
|ATO disengage|||||||A|||||||||NA|NA|||
|Skip<br>ATO<br>stopping<br>point||||||A|A|||||||||NA|NA|||
|request/revocation||||||||||||||||||||
|**Output information**|N<br>P|S<br>B|P<br>S|S<br>H|S<br>M|F<br>S|A<br>D|L<br>S|S<br>R|O<br>S|S<br>L|N<br>L|U<br>N|T<br>R|P<br>T|S<br>F|I<br>S|S<br>N|R<br>V|
|ERTMS/ETCS Mode||A||X|X|X|X|X|X|X||X|X|A|X|A|X|X|X|
|Current ERTMS/ETCS level||A||X|X|X|X|X|X|X||X|X|A|X|NA|NA|X|X|
|Train Speed||A||X|X|X|X|X|X|X||X|X|A|X|NA|NA|A|X|
|Permitted Speed||||A|X|X|X||A|A||||||NA|NA||X|
|SBI Speed|||||A|A|A|||||||||NA|NA|||
|Target Speed|||||A|A|A||A|A||||||NA|NA|||
|Target distance|||||A|A|A||A|A||||||NA|NA||X|
|Release speed|||||A|A|A|A||A||||||NA|NA|||
|Speed and distance monitoring<br>supervision status||||A|A|A|A|A|A|A|||A||A|NA|NA||A|
|Time to Indication|||||A|A|A||A|A||||||NA|NA|||
|LSSMA||||||||A||||||||NA|NA|||
|Trip reason||||||||||||||A|X|NA|NA|||
|Train Data (refer to 3.18.3.2)||A||||A|A|A|A|A|||A|A|A|NA|NA|A|A|
|Driver id||A||A|A|A|A|A|A|A||A|A|A|A|NA|NA|A|A|
|Train running number||A||A|A|A|A|A|A|A||A|A|A|A|NA|NA|A|A|
|RBC contact information||A||A|A|A|A|A|A|A||A|A|A|A|NA|NA|A|A|
|Radio network information<br>-<br>Radio network type<br>-<br>GSM-R radio network-id||A||A|A|A|A|A|A|A||A|A|A|A|NA|NA|A|A|
|Virtual Balise Covers||A||A|A|A|A|A|A|A||A|A|A|A|NA|NA|A|A|
|BTM alarm reaction inhibition||A||A|||||A|||||||NA|NA|||
|Brake indication||A||A|A|A||A|A|A|||A|A|A|NA|NA|A|A|

<!-- end of page 57 -->

|**Output information**|N<br>P|S<br>B|P<br>S|S<br>H|S<br>M|F<br>S|A<br>D|L<br>S|S<br>R|O<br>S|S<br>L<br>N<br>L|U<br>N|T<br>R|P<br>T|S<br>F|I<br>S|S<br>N|R<br>V|
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
|Fixed text information||A|||A|A|A|A|A|A||A|A|A|NA|NA||A|
|Plain text information||A|||A|A|A|A|A|A||A|A|A|NA|NA||A|
|Reversing allowed||||||A|A|A||A|||||NA|NA|||
|Track<br>condition<br>excluding<br>sound<br>horn,<br>non<br>stopping<br>areas, tunnel stopping areas<br>and big metal masses<br>-<br>Power control<br>-<br>Pantograph control<br>-<br>Air tightness  control<br>-<br>Radio hole, supervision of<br>safe<br>radio<br>connection<br>stopped<br>-<br>Brakes control|||||A|A|A|A||A|A||A|A|NA|NA|||
|Track conditions sound horn,<br>non stopping areas, tunnel<br>stopping areas|||||A|A|A|A||A|||||NA|NA|||
|Geographical position||A|||A|A|A|A|A|A|A|A|A|A|NA|NA|||
|Override status||||A|||||A|||A|||NA|NA|A||
|LX status "not protected"|||||A|A|A|A||A|||||NA|NA|||
|Shunting refused by RBC||A|||A|A|A|A|A|A||||A|NA|NA|||
|Shunting<br>request<br>not<br>answered by RBC||A|||A|A|A|A|A|A||||A|NA|NA|||
|Supervised Manoeuvre refused<br>by RBC||A|||A|A|A|A|A|A||||A|NA|NA|||
|Supervised Manoeuvre request<br>not answered by RBC||A|||A|A|A|A|A|A||||A|NA|NA|||
|Entry in FS||||||A|||||||||NA|NA|||
|Entry in OS||||||||||A|||||NA|NA|||
|Entry in SM|||||A||||||||||NA|NA|||
|Level transition announcement||||||A|A|A|A|A|A|A|A|A|NA|NA|A||
|Track Ahead Free request||A||||||A|A|A||||A|NA|NA|||
|Adhesion factor “slippery rail”||A|||A|A|A|A|A|A||A|A|A|NA|NA|A|A|
|Trackside malfunction||A||A|A|A|A|A|A|A||A|A|A|NA|NA|A|A|
|Notification<br>of<br>Train<br>Data<br>change from source different<br>from the driver||A||||A|A|A|A|A||A|A|A|NA|NA|A||
|Operated System Version||A||A|A|A|A|A|A|A|A|A|A|A|NA|NA|A|A|
|Failed Radio Network<br>registration(s)||A|||A|A|A|A|A|A|A|||A|NA|NA|||

<!-- end of page 58 -->

|**Output information**|N<br>P|S<br>B|P<br>S|S<br>H|S<br>M|F<br>S|A<br>D|L<br>S|S<br>R|O<br>S|S<br>L<br>N<br>L|U<br>N|T<br>R|P<br>T|S<br>F|I<br>S|S<br>N|R<br>V|
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
|Safe radio connection<br>indication||A||A|A|A|A|A|A|A|A|A|A|A|NA|NA|A|A|
|Local time||A||X|X|X|X|X|X|X|X|X|A|X|NA|NA|A|X|
|Gradient|||||X|X|X|||A|||||NA|NA|||
|MRSP|||||X|X|X|||A|||||NA|NA|||
|First Indication location|||||A|A|A|||A|||||NA|NA|||
|EOA<sup>[2]</sup>/LOA|||||A|A|A|||A|||||NA|NA|||
|Authorised direction|||||X||||||||||NA|NA|||
|Brake reason||A||A|A|A||A|A|A||A|A|A|NA|NA|A|A|
|Trackside not compatible||A||A|A|A|A|A|A|A|A|A|A|A|NA|NA|A|A|
|Train is rejected||A|||||||||||||NA|NA|||
|Route unsuitability(ies)||||||A|A|A||A|||||NA|NA|||
|Set Speed indication||A||A|A|A|A|A|A|A|A|A|A|A|NA|NA|A|A|
|Non-leading no longer<br>permitted|||||||||||A||||NA|NA|||
|ATO status||A||A|A|A|A|A|A|A|A|A|A|A|NA|NA|A|A|
|Target Advice Speed, Coasting<br>advice, next advice change<br>location||||||A|||||||||NA|NA|||
|Dwell time, next stopping point<br>name and estimated arrival<br>time, stopping points locations,<br>door<br>information,<br>Stopping<br>accuracy, Skip Stopping Point<br>indicator||||||A|A||||||||NA|NA|||
|ATO warning|||||||A||||||||NA|NA|||
|ATO data need||||||A|A|A|A|A||A|A|A|NA|NA|A||
|Impairment due to<br>accumulated underestimation /<br>overestimation in measuring<br>the movements over a defined<br>total distance (refer to 3.6.8.5<br>and 6)|||||A|A|A|A|A|A|||||NA|NA|||
|NTC not available<sup>[1]</sup>|||||||||||A||||NA|NA|A||
|NTC data need<sup>[1]</sup>||||||A|A|A|A|A||A|A|A|NA|NA|A||
|NTC failed<sup>[1]</sup>||A||A|A|A|A|A|A|A|A|A|A|A|NA|NA|A||

[1] In case the ERTMS/ETCS on-board equipment is interfaced to the National System through an STM, refer to SUBSET-035 for details.

[2] When the ERTMS/ETCS on-board equipment applies at least one of the clauses 3.12.2.4, 3.12.4.7 and 3.12.5.8, it refers to the closest location amongst the temporary EOA(s) and the EOA.

<!-- end of page 59 -->

# **4.8 Acceptance of received information**

## **4.8.1 Introduction**

4.8.1.1 The aim of this chapter is to give an overview of which information is accepted or rejected depending on the state of the on-board (level, mode), the origin of the received information (from RBC or not), and in case of information not transmitted by an RBC the type of information (infill or non-infill).

4.8.1.2 The following sections have to be interpreted by applying the filters as shown in Figure 3. The first filter is detailed in section 4.8.3 “Accepted information depending on the level, the origin and the type of information”, the third filter in section 4.8.4 “Accepted information depending on the mode and the type of information”.

4.8.1.3 If a message contains level transition information, any other information in that message shall be evaluated considering the level transition information.

4.8.1.3.1 Information received in the same message as an immediate level transition order or a conditional level transition order that causes a level transition shall be evaluated against the first filter in two steps:

   - 1) A first evaluation shall take place considering the on-board currently operated level, as if a level transition order for further location had been received (i.e. the condition [1] or [2] of Figure 3, if applied, shall be automatically fulfilled).

   - 2) Then, if relevant, information to which the condition [1] or [2] of Figure 3 applies shall be immediately extracted from the buffer and re-evaluated according to the new selected level. The information accepted or rejected immediately considering the onboard currently operated level shall not be re-evaluated according to the new selected level.

4.8.1.4 Note: As shown in Figure 3, information stored following an announcement of a change of level, is re-checked for acceptance when the level has changed. This implies that, when the level changes, the mode is - for a short moment – still unchanged, until the stored information has been processed. The consequence for the Third Filter is that information needs to be accepted for this short period also in modes in which this information is otherwise useless.

4.8.1.5 If a message contains infill information, this latter shall be evaluated considering all other non-infill information in that message.

4.8.1.6 When evaluating trackside information received by radio or when re-evaluating a set of information released from the transition buffer, linking information, if any, shall be evaluated prior to any other location related information.

<!-- end of page 60 -->

<!-- Start of picture text -->
INPUT INFORMATION<br>First filter<br>R<br>REJECTED<br>For acceptance and  INFORMATION<br>rejection conditions and  A[3] [4] [5]  A[7]<br>their exceptions, see  [8] [9] [10]<br>LEVEL tables  [11] [12] [13]<br>R[1]  R[2]  R[6]  [14] [15] [16]<br>[17] [18]<br>Condition [1]  NO<br>fulfilled<br>A<br>Condition [2]  NO<br>YES  fulfilled<br>NO<br>YES  Condition [6]<br>fulfilled<br>TRANSITION BUFFER :  YES<br>YES<br>See 4.8.5 and 4.8.1.3.1.  Condition [3], [4],<br>[5], [8], [9], [10],<br>[11], [12], [13], [14],<br>[15], [16], [17] or  YES<br>[18] fulfilled<br>Condition [7]<br>NO<br>fulfilled<br>NO<br>INFORMATION<br>THAT PASSED<br>FIRST FILTER<br>Second Filter<br>RBC  YES  message from  NO  “RBC transition order”<br>message?  supervising RBC   or“Request to shorten MA”  YES<br> or “Revocation of Emergency Stop”<br>or “LSSMA display toggle on/off order”<br>REJECTED<br>YES  INFORMATION<br>NO<br>“Ack of Train Data”<br>  or “Session Management”   NO<br>YES   or “Ack of Session Termination”<br>TRANSITION BUFFER:  NO<br>information is stored, until<br>RBC transition is effective<br>INFORMATION<br>THAT PASSED<br>SECOND FILTER<br>Third Filter :  See Table depending on  MODE<br>ACCEPTED<br>INFORMATION<br><!-- End of picture text -->

**Figure 3: schematic representation of the filtering of received information**

## **4.8.2 Assumptions**

4.8.2.1 The following tables shall be applied assuming that:

<!-- end of page 61 -->

- a) the information complies with the system version checks (see section 3.17.3) and with the data consistency checks.(see section 3.16)

- b) with the exception of information part of an SM authorisation, the direction for which the information is valid matches the current train orientation, or the balise group crossing direction (for SL, PS and SH engines).(see section 3.6.3)

- c) In level 2, it is assumed that the “RBC” information which is marked “A” (Accepted) comes from the supervising RBC (see RBC/RBC handover). If this information is received from the “Accepting” RBC while the “Handing Over” RBC is still responsible, it is stored onboard until the RBC transition is performed

<u>Exception 1: The information “Acknowledgement of Train Data”, "Session</u> Management" and “Acknowledgement of Session Termination" shall be immediately accepted.

<u>Exception 2: The information “RBC transition order”, “Request to shorten MA”,</u> “Revocation of Emergency Stop” and “LSSMA display toggle on/off order” shall be rejected.

   - d) to check exception [4] in 4.8.3, the track description is referred to the SOLR (i.e. relocation has been performed see 3.6.4.3).

   - e) the information from balise is received while no movement opposite to the authorised direction is performed (see clause 3.14.3.6)

4.8.2.2 Regarding 4.8.2.1 a): In case a balise is missed or a balise telegram cannot be decoded, the information “Inhibition of balise group message consistency reaction” is only used by the on-board equipment to inhibit the service brake reaction, while the balise group message is rejected. If all the telegrams from a balise group are correctly read, the information “Inhibition of balise group message consistency reaction”, if received, shall be ignored by the on-board equipment. Therefore this information need not to be referred to in the following tables.

4.8.2.3 In case a balise telegram contains the information VBC marker and a country/region identity that both match a stored VBC, the whole balise telegram is ignored and any further check in relation to this balise telegram is irrelevant (refer to 3.15.9.3 b)). Otherwise the information VBC marker, if included in a consistent balise group message, shall always be ignored by the ERTMS/ETCS on-board equipment and need not to be referred to in the following tables.

4.8.2.4 Note: with the exception of the data that is forwarded to a National System through the STM interface (see 3.15.6 and SUBSET-035), what will happen to the data to be used by applications outside ERTMS/ETCS (e.g. whether it is discarded, forwarded to an external application, processed by a national function…) is outside the scope of this specification and is assumed as not being part of the ERTMS/ETCS on-board functionality.

4.8.2.5 Note: the system version order received from balise group need not be referred to in the following tables because it is taken into account by the on-board equipment prior to the checks referred to in this section (see also clause 3.17.3.3).

<!-- end of page 62 -->

## **4.8.3 Accepted information depending on the level, the origin and the type of information**

4.8.3.1 From RBC or not

4.8.3.1.1 “No” in column “From RBC” has to be understood as information received from a balise group, loop or RIU.

NR = Not Relevant A = Accepted R = Rejected

||From RBC|<br>Type||Onboard op|erating level||
|---|---|---|---|---|---|---|
|Information|||0|NTC|1|2|
|National Values|No|Non-infill|A|A|A|A|
||No|Infill|||||
||Yes|NR|R [2]|R [2]|R [2]|A|
|Linking|No|Non-infill|R [1]|R [1]|A|R [1]|
||No|Infill|R|R|A|R [1]|
||Yes|NR|R [2]|R [2]|R [2]|A [3] [17]|
|Signalling Related Speed Restriction|No|Non-infill|R [1]|R [1]|A|R [1]|
||No|Infill|R|R|A [18]|R [1]|
||Yes|NR|||||
|Movement Authority (excluding with<br>SM Authorisation)<br>+ (optional) Mode Profile<br>+ (optional) List of Balise Groups for<br>SH area|No|Non-infill|R [1]|R [1]|A [4]|R [1]|
||No|Infill|R|R|A [4]|R [1]|
||Yes|NR|R [2]|R [2]|R [2]|A [3] [4] [5]|
|Movement authority (SM Authorisation)|No|Non-infill|||||
||No|Infill|||||
||Yes|NR|R|R|R|A [4] [5] [17]|
|SM refused|No|Non-infill|||||
||No|Infill|||||
||Yes|NR|R|R|R|A|
|Acknowledgement of safe consist<br>length for SM|No|Non-infill|||||
||No|Infill|||||
||Yes|NR|R|R|R|A|
|Repositioning Information|No|Non-infill|R|R|A|R|
||No|Infill|||||
||Yes|NR|||||
|Gradient Profile|No|Non-infill|R [1]|R [1]|A|R [1]|

<!-- end of page 63 -->

||From RBC|Type||Onboard op|erating level||
|---|---|---|---|---|---|---|
|Information|||0|NTC|1|2|
||No|Infill|R|R|A|R [1]|
||Yes|NR|R [2]|R [2]|R [2]|A [3] [17]|
|International SSP|No|Non-infill|R [1]|R [1]|A|R [1]|
||No|Infill|R|R|A|R [1]|
||Yes|NR|R [2]|R [2]|R [2]|A [3] [17]|
|Axle Load speed profile|No|Non-infill|R [1]|R [1]|A|R [1]|
||No|Infill|R|R|A|R [1]|
||Yes|NR|R [2]|R [2]|R [2]|A [3] [17]|
|Level Transition Order|No|Non-infill|A|A|A|A [16]|
||No|Infill|R|R|A|R [1]|
||Yes|NR|A|A|A|A|
|Conditional Level Transition Order|No|Non-infill|A [11]|A [11]|A [11]|A [11] [16]|
||No|Infill|||||
||Yes|NR|||||
|Session Management|No|Non-infill|A [15]|A [15]|A [15]|A [14] [15]|
||No|Infill|||||
||Yes|NR|A [15]|A [15]|A [15]|A [15]|
|Radio Network transition order|No|Non-infill|A|A|A|A|
||No|Infill|||||
||Yes|NR|A|A|A|A|
|MA Request Parameters|No|Non-infill|||||
||No|Infill|||||
||Yes|NR|A|A|A|A|
|Position Report parameters|No|Non-infill|||||
||No|Infill|||||
||Yes|NR|A|A|A|A|
|SR Authorisation + (optional) List of<br>Balise Groups in SR mode|No|Non-infill|||||
||No|Infill|||||
||Yes|NR|R|R|R|A [3]|
|Stop if in SR mode|No|Non-infill|R|R|A|A|
||No|Infill|||||
||Yes|NR|||||
|SR distance information from loop|No|Non-infill|R|R|A|R|
||No|Infill|||||
||Yes|NR|||||

<!-- end of page 64 -->

||From RBC|<br>Type||Onboard ope|rating level||
|---|---|---|---|---|---|---|
|Information|||0|NTC|1|2|
|Temporary Speed Restriction|No|Non-infill|A|R [1] [2]|A|A [8]|
||No|Infill|R|R|A|R [1]|
||Yes|NR|R [2]|R [2]|R [2]|A [3] [17]|
|Temporary Speed Restriction<br>Revocation|No|Non-infill|A|R [1] [2]|A|A|
||No|Infill|||||
||Yes|NR|R [2]|R [2]|R [2]|A [3] [17]|
|Inhibition of revocable TSRs from<br>balises in level 2|No|Non-infill|||||
||No|Infill|||||
||Yes|NR|R [2]|R [2]|R [2]|A|
|Default Gradient for TSR|No|Non-infill|A|R [1] [2]|A|A|
||No|Infill|||||
||Yes|NR|||||
|Route Suitability Data|No|Non-infill|R [1]|R [1]|A|R [1]|
||No|Infill|R|R|A|R [1]|
||Yes|NR|R [2]|R [2]|R [2]|A [3] [17]|
|Adhesion Factor|No|Non-infill|R[1]|R[1]|A|R|
||No|Infill|R|R|A|R [1]|
||Yes|NR|R[2]|R[2]|R[2]|A|
|Plain Text Information|No|Non-infill|A|R [1] [2]|A|A|
||No|Infill|||||
||Yes|NR|R [2]|R [2]|R [2]|A [12]|
|Fixed Text Information|No|Non-infill|A|R [1] [2]|A|A|
||No|Infill|||||
||Yes|NR|R [2]|R [2]|R [2]|A [12]|
|Geographical Position|No|Non-infill|A|R [1] [2]|A|A|
||No|Infill|||||
||Yes|NR|R [2]|R [2]|R [2]|A|
|RBC Transition Order|No|Non-infill|R|R|R|A [15]|
||No|Infill|||||
||Yes|NR|R|R|R|A [3] [15] [17]|
|Danger for SH information|No|Non-infill|A [13]|A [13]|A|A|
||No|Infill|||||
||Yes|NR|||||
|Stop Shunting on desk opening|No|Non-infill|A|A|A|A|
||No|Infill|||||

<!-- end of page 65 -->

||From RBC|Type||Onboard op|erating level||
|---|---|---|---|---|---|---|
|Information|||0|NTC|1|2|
||Yes|NR|||||
|Radio Infill Area information|No|Non-infill|R|R|A [15]|R [1]|
||No|Infill|R|R|A|R [1]|
||Yes|NR|||||
|Session Management with<br>neighbouring RIU|No|Non-infill|R|R|A [15]|R|
||No|Infill|||||
||Yes|NR|||||
|EOLM information|No|Non-infill|A|A|A|A|
||No|Infill|||||
||Yes|NR|||||
|Assignment of Co-ordinate system|No|Non-infill|||||
||No|Infill|||||
||Yes|NR|A [10]|A [10]|A [10]|A [10]|
|Infill Location Reference|No|Non-infill|||||
||No|Infill|R|R|A|R [1]|
||Yes|NR|||||
|Track Conditions excluding big metal<br>masses|No|Non-infill|R [1]|R [1]|A|R [1]|
||No|Infill|R|R|A|R [1]|
||Yes|NR|R [2]|R [2]|R [2]|A [3] [17]|
|Track condition big metal masses|No|Non-infill|A|A|A|A|
||No|Infill|R|R|A|R [1]|
||Yes|NR|R [2]|R [2]|R [2]|A [17]|
|Location Identity (NID_C + NID_BG<br>transmitted in the balise telegram)|No|Non-infill|A|A|A|A|
||No|Infill|||||
||Yes|NR|||||
|Recognition of exit from TRIP mode|No|Non-infill|||||
||No|Infill|||||
||Yes|NR|R|R|R|A|
|Acknowledgement of Train Data|No|Non-infill|||||
||No|Infill|||||
||Yes|NR|A|A|A|A|
|Request to shorten MA<br>(MA + (optional) Mode Profile<br>+ (optional) List of Balise Groups for<br>SH area)|No|Non-infill|||||

<!-- end of page 66 -->

||From RBC|Type||Onboard op|erating level||
|---|---|---|---|---|---|---|
|Information|||0|NTC|1|2|
||No|Infill|||||
||Yes|NR|R|R|R|A [3] [4] [5]|
|Unconditional Emergency Stop|No|Non-infill|||||
||No|Infill|||||
||Yes|NR|R [2]|R [2]|R [2]|A|
|Conditional Emergency Stop|No|Non-infill|||||
||No|Infill|||||
||Yes|NR|R [2]|R [2]|R [2]|A|
|Revocation of Emergency Stop<br>(Conditional or Unconditional)|No|Non-infill|||||
||No|Infill|||||
||Yes|NR|R|R|R|A|
|SH refused|No|Non-infill|||||
||No|Infill|||||
||Yes|NR|R|R|R|A [3]|
|SH authorised + (optional) List of<br>Balise Groups for SH area|No|Non-infill|||||
||No|Infill|||||
||Yes|NR|R|R|R|A [3]|
|Track Ahead Free Request|No|Non-infill|||||
||No|Infill|||||
||Yes|NR|R|R|R|A [3]|
|Train Running Number|No|Non-infill|||||
||No|Infill|||||
||Yes|NR|R|R|R|A|
|Acknowledgement of session<br>termination|No|Non-infill|A|A|A|A|
||No|Infill|||||
||Yes|NR|A|A|A|A|
|Train Rejected|No|Non-infill|||||
||No|Infill|||||
||Yes|NR|R|R|R|A|
|Train Accepted|No|Non-infill|||||
||No|Infill|||||
||Yes|NR|R|R|R|A|
|SoM Position Report Confirmed by<br>RBC|No|Non-infill|||||

<!-- end of page 67 -->

||From RBC|Type||Onboard ope|rating level||
|---|---|---|---|---|---|---|
|Information|||0|NTC|1|2|
||No|Infill|||||
||Yes|NR|R|R|R|A|
|Reversing Area Information|No|Non-infill|R [1]|R [1]|A|R [1]|
||No|Infill|R|R|A|R [1]|
||Yes|NR|R [2]|R [2]|R [2]|A [3]|
|Reversing Supervision Information|No|Non-infill|R [1]|R [1]|A|R [1]|
||No|Infill|R|R|A|R [1]|
||Yes|NR|R [2]|R [2]|R [2]|A [3]|
|Default Balise/Loop/RIU Information|No|Non-infill|A|A|A|A|
||No|Infill|||||
||Yes|NR|||||
|Track Ahead Free up to level 2<br>transition location|No|Non-infill|A [9]|A [9]|A [9]|R|
||No|Infill|||||
||Yes|NR|||||
|Permitted Braking Distance<br>Information|No|Non-infill|R [1]|R [1]|A|R [1]|
||No|Infill|R|R|A|R [1]|
||Yes|NR|R [2]|R [2]|R [2]|A [3]|
|Level Crossing information|No|Non-infill|R [1] [2]|R [1] [2]|A|A|
||No|Infill|R|R|A|R [1]|
||Yes|NR|R [2]|R [2]|R [2]|A [3] [17]|
|Virtual Balise Cover order|No|Non-infill|A|A|A|A|
||No|Infill|||||
||Yes|NR|||||
|Generic LS function marker|No|Non-infill|A|A|A|A|
||No|Infill|||||
||Yes|NR|||||
|LSSMA display toggle on order|No|Non-infill|R [1]|R [1]|A|R [1]|
||No|Infill|||||
||Yes|NR|R [2]|R [2]|R [2]|A [3] [5]|
|LSSMA display toggle off order|No|Non-infill|R|R|A|R|
||No|Infill|||||
||Yes|NR|R|R|R|A|

<!-- end of page 68 -->

||From RBC|Type||Onboard ope|rating level||
|---|---|---|---|---|---|---|
|Information|||0|NTC|1|2|
|Data to be used by applications<br>outside ERTMS/ETCS|No|Non-infill|A|A|A|A|
||No|Infill|R|R|A|R [1]|
||Yes|NR|A|A|A|A|

[1] exception: stored onboard if an order to switch to level 1 at a further location has been received.

[2] exception: stored onboard if an order to switch to level 2 at a further location has been received.

[3] exception: rejected if:

- Train Data has been sent to the RBC and the RBC has not yet acknowledged any train data in the ongoing communication session, or

- Train Data where the value of Train category, Axle load, Loading gauge or Traction system is different from the last value acknowledged by the RBC has been sent to the RBC and the corresponding “Acknowledgement of Train Data” has not been received yet.

[4] exception: rejected if the SSP and gradient already available on-board or given together with the MA do not cover the full length of the MA.

[5] exception: rejected if emergency stop(s) have been accepted and are not yet revoked or deleted onboard (see mode transitions).

[8] exception: revocable TSRs shall be rejected if information “inhibition of revocable TSRs from balises in level 2” is stored on-board.

[9] exception: rejected if no level 2 transition order is stored onboard.

[10] exception: rejected if the referred LRBG is memorised to have been reported with different “previous LRBG”

[11] exception: rejected if a level transition order is received in the same message, or if a previous level transition order has announced a level transition still to be executed

[12] exception: rejected if the text message is sent with a request for report of driver acknowledgement with the same text message identifier as a previously received text message, which the driver has not yet acknowledged

[13] exception: rejected if not received together with an immediate level transition order to level 1 or 2

[14] exception: rejected if it relates to an order to establish a communication session with an RBC referred to in an RBC transition order currently stored or received in the same message

[15] exception: rejected if it is a session establishment order (which, for sleeping units, is to be executed) received together with a Radio Network transition order including a Radio Network type:

- FRMCS or FRMCS+GSM-R while FRMCS is the only radio system installed on-board or FRMCS+GSM-R while both radio systems are installed on-board but the driver has elected to perform the mission with FRMCS only, and if the FRMCS on-board is not registered to the FRMCS Radio Network

- FRMCS+GSM-R while both radio systems are installed on-board, and, unless the driver has elected to perform the mission with only one radio system, and if either the FRMCS on-board is not registered to the FRMCS Radio Network or none of the GSM-R Mobile Terminal(s) available to establish the communication session is registered to this GSM-R Radio Network

- GSM-R or FRMCS+GSM-R while GSM-R is the only radio system installed on-board or FRMCS+GSM-R while both radio systems are installed on-board but the driver has elected to

<!-- end of page 69 -->

perform the mission with GSM-R only, and if none of the GSM-R Mobile Terminal(s) available to establish the communication session is registered to this GSM-R Radio Network.

[16] exception: rejected if it is received from a balise group marked as unlinked and the list of trackside supported levels contained in that order includes level 1.

[17] exception: rejected if a “Safe consist length information for SM” message has been sent to the RBC and the corresponding acknowledgment has not been received yet in the ongoing mission.

[18] exception: rejected if the Signalling Related Speed Restriction equals zero

### 4.8.3.2 From National System X (through STM interface)

|||Onb|oard operating le|vel||
|---|---|---|---|---|---|
|Information from National|0|NTC X|NTC Y|1|2|
|System X through STM<br>interface||||||
|STM max speed|A [7]|R|R [6]|A [7]|A [7]|
|STM system speed/distance|A [7]|R|R|A [7]|A [7]|

[6] exception: stored by ETCS onboard if an order to switch to level NTC X at a further location has been received.

[7] exception: rejected by ETCS onboard if no order to switch to level NTC X at a further location has been received.

4.8.3.3 Intentionally deleted.

4.8.3.4 Intentionally deleted.

<!-- end of page 70 -->

## **4.8.4 Accepted Information depending on the mode and the type of information**

4.8.4.1 Assumptions

4.8.4.1.1 For infill information, only the columns FS, AD and LS shall apply. In all other modes, infill information shall be rejected.

4.8.4.1.2 Intentionally deleted.

4.8.4.2 Intentionally deleted.

### NR = Not Relevant A = Accepted R = Rejected

|Information|||||||||M|ode||||||||||
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
||NP|SB|PS|SH|SM|FS|AD|LS|SR|OS|SL|NL|UN|TR|PT|SF|IS|SN|RV|
|National Values|NR|A [2][13]|A|A|A|A[13]|A[13]|A[13]|A[13]|A[13]|A|A|A|A|A [1]<br>[13]|NR|NR|A|A|
|Linking|NR|A[2][4]<br>[13]|R|R|A|A[13]|A[13]|A[13]|A[13]|A[13]|R|A|A|R|A [1] [4]<br>[13]|NR|NR|A|R|
|Signalling Related Speed<br>Restriction|NR|A[2][4]|R|R|R|A|A|A|A|A|R|R|A|R|A [1] [4]|NR|NR|A|R|
|Movement Authority (excluding<br>with SM Authorisation)<br>+ (optional) Mode Profile<br>+ (optional) List of Balise<br>Groups for SH area|NR|A[2][4]<br>[11]|R|R|R|A|A|A|A|A|R|R|A|R|A [1] [4]|NR|NR|A|R|
|Movement Authority (SM<br>Authorisation)|NR|A[2][13]|R|R|A|A[13]|A[13]|A[13]|A[13]|A[13]|R|R|R|R|A [1]<br>[13]|NR|NR|R|R|

<!-- end of page 71 -->

|Information|||||||||M|ode||||||||||
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
||NP|SB|PS|SH|SM|FS|AD|LS|SR|OS|SL|<br>NL|UN|TR|PT|SF|IS|SN|RV|
|SM Authorisation|NR|A[2][14]|R|R|A|A[14]|A[14]|A[14]|A[14]|A[14]|R|R|R|R|A [1]<br>[14]|NR|NR|R|R|
|SM refused|NR|A[2][14]|R|R|A|A[14]|A[14]|A[14]|A[14]|A[14]|R|R|R|R|A [1]<br>[14]|NR|NR|R|R|
|Acknowledgement of safe<br>consist length for SM|NR|A|R|R|A|A|A|A|A|A|R|R|R|A|A|NR|NR|R|R|
|Repositioning Information|NR|R|R|R|R|A|A|A|R|A|R|R|R|R|R|NR|NR|R|R|
|Gradient Profile|NR|A[2][4]<br>[13]|R|R|A|A[13]|A[13]|A[13]|A[13]|A[13]|R|R|A|R|A [1] [4]<br>[13]|NR|NR|A|R|
|International SSP|NR|A[2][4]<br>[13]|R|R|A|A[13]|A[13]|A[13]|A[13]|A[13]|R|R|A|R|A [1] [4]<br>[13]|NR|NR|A|R|
|Axle load speed profile|NR|A[2][4]<br>[13]|R|R|A|A[13]|A[13]|A[13]|A[13]|A[13]|R|R|A|R|A [1] [4]<br>[13]|NR|NR|A|R|
|STM max speed|NR|A [2]|R|R|R|A|A|A|A|A|R|R|A|A|A [1]|NR|NR|A|R|
|STM system speed/distance|NR|A [2]|R|R|R|A|A|A|A|A|R|R|A|A|A [1]|NR|NR|R|R|
|Level Transition Order and<br>Conditional Level Transition<br>Order|NR|A [2]|A [7]|A [7]|A [7]|A|A|A|A|A|A|A|A|A|A [1] [5]|NR|NR|A|R|
|Session Management|NR|A|A [3]|A [3]|A<br>[12]|A|A|A|A|A|A|A|A|A|A [1]|NR|NR|A|A|
|Radio Network transition order|NR|A [2]<br>[13]|A|A|A|A[13]|A[13]|A[13]|A[13]|A[13]|A|A|A|A|A [1]<br>[13]|NR|NR|A|A|
|MA Request Parameters|NR|A [2]|R|R|R|A|A|A|A|A|R|R|A|R|A [1]|NR|NR|A|R|

<!-- end of page 72 -->

|Information|||||||||M|ode||||||||||
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
||NP|SB|PS|SH|SM|<br>FS|AD|LS|SR|OS|SL|<br>NL|UN|TR|<br>PT|SF|IS|SN|RV|
|Position Report parameters|NR|A [2]<br>[13]|R|R|A|A[13]|A[13]|A[13]|A[13]|A[13]|R|A|A|R|A [1]<br>[13]|NR|NR|A|A|
|SR Authorisation+<br>(optional) List of Balise Groups<br>in SR mode|NR|A[2][4][1<br>1]|R|R|R|R|R|R|A|R|R|R|R|R|A [1] [4]|NR|NR|R|R|
|Stop if in SR mode|NR|R|R|R|R|R|R|R|A|R|R|R|R|R|R|NR|NR|R|R|
|SR distance information from<br>loop|NR|R|R|R|R|R|R|R|A [6]|R|R|R|R|R|R|NR|NR|R|R|
|Temporary Speed Restriction|NR|A [2][4]<br>[13]|R|R|A|A[13]|A[13]|A[13]|A[13]|A[13]|R|R|A|A|A [1] [4]<br>[13]|NR|NR|A|R|
|Temporary Speed Restriction<br>Revocation|NR|A[2][4]<br>[13]|R|R|A|A[13]|A[13]|A[13]|A[13]|A[13]|R|R|A|A|A [1] [4]<br>[13]|NR|NR|A|R|
|Inhibition of revocable TSRs<br>from balises in level 2|NR|A [2]<br>[13]|R|R|A|A[13]|A[13]|A[13]|A[13]|A[13]|R|R|A|A|A [1]<br>[13]|NR|NR|A|R|
|Default Gradient for TSR|NR|A[2][4]|R|R|A|A|A|A|A|A|R|R|A|A|A [1]|NR|NR|A|R|
|Route Suitability Data|NR|A[2][4]|R|R|R|A|A|A|A|A|R|R|A|R|A [1] [4]|NR|NR|A|R|
|Adhesion Factor|NR|A[2][4]<br>[13]|R|R|A|A[13]|A[13]|A[13]|A[13]|A[13]|R|R|A|R|A [1] [4]<br>[13]|NR|NR|A|R|
|Plain Text Information|NR|A [2]<br>[13]|R|R|A|A[13]|A[13]|A[13]|A[13]|A[13]|R|R|A|A|A [1]<br>[13]|NR|NR|A|A|
|Fixed Text Information|NR|A [2]<br>[13]|R|R|A|A[13]|A[13]|A[13]|A[13]|A[13]|R|R|A|A|A [1]<br>[13]|NR|NR|A|A|
|Geographical Position|NR|A [2]<br>[13]|R|R|A|A[13]|A[13]|A[13]|A[13]|A[13]|R|A|A|A|A [1]<br>[13]|NR|NR|A|R|

<!-- end of page 73 -->

|Information|||||||||M|ode||||||||||
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
||NP|SB|PS|SH|SM|<br>FS|AD|LS|SR|OS|SL|NL|UN|TR|PT|SF|IS|SN|RV|
|RBC Transition Order|NR|A[2][4]<br>[13]|A [8]|A [8]|A|A[13]|A[13]|A[13]|A[13]|A[13]|A|A|R|A|A [1] [4]<br>[13]|NR|NR|R|R|
|Danger for SH information|NR|R|R|A|R|R|R|R|R|R|R|R|R|R|R|NR|NR|R|R|
|Stop Shunting on desk opening|NR|R|A|R|R|R|R|R|R|R|R|R|R|R|R|NR|NR|R|R|
|Radio Infill Area information|NR|R|R|R|R|A|A|A|A|A|R|R|R|R|R|NR|NR|R|R|
|Session Management with<br>neighbouring RIU|NR|R|R|R|R|A|A|A|A|A|R|R|R|R|R|NR|NR|R|R|
|EOLM information|NR|R|R|R|A|A|A|A|A|A|A|A|A|A|R|NR|NR|A|A|
|Assignment of Co-ordinate<br>system|NR|A [2]|R|R|A|R|R|R|A|R|R|A|A|R|A [1]|NR|NR|A|R|
|Infill Location Reference|NR|R|R|R|R|A|A|A|R|R|R|R|R|R|R|NR|NR|R|R|
|Track Conditions excluding<br>sound horn, non stopping<br>areas, tunnel stopping areas<br>and big metal masses|NR|A[2][4]<br>[13]|R|R|A|A[13]|A[13]|A[13]|A[13]|A[13]|R|A|A|A|A [1] [4]<br>[13]|NR|NR|A|R|
|Track conditions sound horn,<br>non stopping areas, tunnel<br>stopping areas|NR|A[2][4]<br>[13]|R|R|A|A[13]|A[13]|A[13]|A[13]|A[13]|R|R|A|R|A [1] [4]<br>[13]|NR|NR|A|R|
|Track condition big metal<br>masses|NR|A[2][4]<br>[13]|A|A|A|A[13]|A[13]|A[13]|A[13]|A[13]|A|A|A|A|A [1] [4]<br>[13]|NR|NR|A|R|
|Location Identity (NID_C +<br>NID_BG)|NR|A [2]|A|A|A|A|A|A|A|A|A|A|A|A|A|NR|NR|A|A|
|Recognition of exit from TRIP<br>mode|NR|R|R|R|R|R|R|R|R|R|R|R|R|R|A|NR|NR|R|R|

<!-- end of page 74 -->

|Information|||||||||M|ode||||||||||
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
||NP|SB|PS|SH|SM|<br>FS|AD|LS|SR|OS|SL|NL|UN|TR|PT|SF|IS|SN|RV|
|Acknowledgement of Train<br>Data|NR|A [2]|R|R|R|A|A|A|A|A|R|R|A|A|A|NR|NR|A|A|
|Request to shorten MA<br>(MA + (optional) Mode Profile<br>+ (optional) List of Balise<br>Groups for SH area)|NR|R|R|R|R|A|A|A|R|A|R|R|R|R|R|NR|NR|R|R|
|Unconditional Emergency Stop|NR|A [2]|R|R|A|A|A|A|A|A|R|R|A|R|R|NR|NR|A|R|
|Conditional Emergency Stop|NR|R|R|R|A|A|A|A|R|A|R|R|A|R|R|NR|NR|A|R|
|Revocation of Emergency Stop<br>(Conditional or Unconditional)|NR|R|R|R|A|A|A|A|R|A|R|R|R|R|A [1]|NR|NR|R|R|
|SH refused|NR|A [2]<br>[14]|R|R|A|A[14]|A[14]|A[14]|A[14]|A[14]|R|R|R|R|A [1]<br>[14]|NR|NR|R|R|
|SH authorised + (optional) List<br>of Balise Groups for SH area|NR|A [2]<br>[14]|R|R|A|A[14]|A[14]|A[14]|A[14]|A[14]|R|R|R|R|A [1]<br>[14]|NR|NR|R|R|
|Track Ahead Free Request|NR|A [2]|R|R|R|R|R|A|A|A|R|R|R|R|A[1]|NR|NR|R|R|
|Train Running Number|NR|A [2]<br>[13]|R|R|A|A[13]|A[13]|A[13]|A[13]|A[13]|R|A|R|A|A[13]|NR|NR|R|A|
|Acknowledgement of session<br>termination|NR|A|A|A|A|A|A|A|A|A|A|A|A|A|A|NR|NR|A|A|
|Train Rejected|NR|A [2]|R|R|R|R|R|R|R|R|R|R|R|R|R|NR|NR|R|R|
|Train Accepted|NR|A [2]|R|R|R|R|R|R|R|R|R|R|R|R|R|NR|NR|R|R|
|SoM Position Report Confirmed<br>by RBC|NR|A [2]|R|R|R|R|R|R|R|R|R|R|R|R|R|NR|NR|R|R|
|Reversing Area Information|NR|A[2][4]|R|R|R|A|A|A|A|A|R|R|A|R|A [1] [4]|NR|NR|A|A|

<!-- end of page 75 -->

|Information|||||||||M|ode||||||||||
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
||NP|SB|PS|SH|SM|<br>FS|AD|LS|SR|OS|SL|NL|UN|TR|PT|SF|IS|SN|RV|
|Reversing Supervision<br>Information|NR|A[2][4]|R|R|R|A|A|A|A|A|R|R|A|R|A [1] [4]|NR|NR|A|A|
|Default Balise/Loop/RIU<br>Information|NR|A [2]|A|A|A|A|A|A|A|A|A|A|A|A|A|NR|NR|A|A|
|Track Ahead Free up to level 2<br>transition location|NR|A [2]|R|R|R|A|A|A|A|A|R|R|A|A|A|NR|NR|A|R|
|Permitted Braking Distance<br>Information|NR|A[2][4]|R|R|R|A|A|A|A|A|R|R|A|R|A [1] [4]|NR|NR|A|R|
|Level Crossing information|NR|A[2][4]<br>[13]|R|R|A|A[13]|A[13]|A[13]|A[13]|A[13]|R|R|A|R|A [1] [4]<br>[13]|NR|NR|A|R|
|Virtual Balise Cover order|NR|A|A|A|A|A|A|A|A|A|A|A|A|A|A|NR|NR|A|A|
|Generic LS function marker|NR|A|A|A|A|A|A|A|A|A|A|A|A|A|A|NR|NR|A|A|
|LSSMA display toggle on order|NR|R|R|R|R|A [9]|A [9]|A|A [9]|A [10]|R|R|A [9]|R|R|NR|NR|A [9]|R|
|LSSMA display toggle off order|NR|R|R|R|R|R|R|A|R|R|R|R|R|R|R|NR|NR|R|R|
|Data to be used by applications<br>outside ERTMS/ETCS|NR|A[13]|A|A|A|A[13]|A[13]|A[13]|A[13]|A[13]|A|A|A|A|A[13]|NR|NR|A|A|

[1]: for level 2: only if following the reception of the information “Recognition of Exit from TR mode” with a more recent time stamp; for level 1: rejected [2]: only if a cab is active

[3]: for order to establish a communication session: RBC contact information is stored without establishing the communication session

[4]: only if valid Train Data are stored on-board or if received in an SM authorisation

[5]: only level transition announcement (i.e., immediate level transition order and conditional level transition order shall be rejected)

[6]: rejected if override is active

[7]: only immediate level transition order and conditional level transition order shall be accepted (i.e., level transition announcement shall be rejected) and stored for later evaluation (see 4.4.8.1.5, 4.4.20.1.11 & 4.4.21.1.11)

<!-- end of page 76 -->

[8]: only RBC transition order with null distance to execution shall be accepted (i.e., RBC transition announcement shall be rejected) for storing the RBC contact information (see 4.4.8.1.5.2 & 4.4.20.1.13)

[9]: only if the train position confidence interval overlaps the Limited Supervision area of a mode profile received in the same message AND if starting from the min safe front end of the train this Limited Supervision area is the furthest area that the train position confidence interval overlaps within in the mode profile

[10]: only if the train position confidence interval overlaps the Limited Supervision area of a mode profile received in the same message AND if starting from the min safe front end of the train this Limited Supervision area is the furthest area that the train position confidence interval overlaps within the mode profile AND if the estimated front end of the train is not inside an OS acknowledgement area

[11]: only if valid Train Running Number is stored on-board or if Train Running Number is received in the same message

[12]: only order to terminate a communication session shall be accepted

[13]: rejected if it is included in an SM Authorisation rejected as per exception [14]

[14]: rejected if the time stamp referring to the on-board request does not match the time stamp of the last sent request

<!-- end of page 77 -->

## **4.8.5 Handling of transition buffer in case of level transition announcement or RBC/RBC handover**

4.8.5.1 If an order to switch to level NTC, 1 or 2 at a further location has been received, the ERTMS/ETCS onboard equipment shall be able to store in a transition buffer (see figure 3, first filter) three sets of information obtained from three filtered messages.

4.8.5.2 If an RBC transition order has been received and the Handing Over RBC is still the supervising one, the ERTMS/ETCS onboard equipment shall be able to store in a transition buffer (see figure 3, second filter) three sets of information obtained from three filtered messages from the Accepting RBC.

4.8.5.2.1 Note: the term “set of information” refers to the part of a message being stored in the transition buffer (i.e. information which is neither accepted nor rejected immediately) according to the conditions stated in 4.8.3.1 [1] and [2] (for level transition) or according to 4.8.2.1c (for RBC/RBC handover).

4.8.5.3 In case three sets of information are already stored in the transition buffer, any new set to be stored shall replace the oldest one currently stored.

4.8.5.4 The sets of information stored in the transition buffer shall be deleted:

   - a) in case the level transition order is deleted or overwritten by another level transition order for a different level, OR

   - b) in case the RBC transition order is deleted or overwritten by an order to switch to another Accepting RBC, OR

   - c) in case the communication session with the RBC that provided the stored information is terminated

4.8.5.5 At the same time the level transition is performed or at the same time the Accepting RBC becomes the supervising one, the sets of information stored in the transition buffer shall be released and re-evaluated in the sequence they have been received.

4.8.5.6 This sequential re-evaluation of all the released information shall be a prerequisite to any use by the on-board equipment (e.g. it will lead neither to an intermediate change of mode nor to a change of information displayed to the driver) and shall obey the following principles:

   - a) Starting from the information currently used by on-board at the moment the level/RBC transition is effective, the ERTMS/ETCS on-board equipment shall determine the new information for train supervision, by performing sequential updates from the information released from the transition buffer, if accepted.

   - b) For each information update related to a re-evaluated set of information, the same rules shall apply as to information update related to new information accepted outside a level/RBC transition context.

   - c) The information resulting from this sequential update shall then be used by the ERTMS/ETCS on-board equipment.

<!-- end of page 78 -->

4.8.5.7 Accepting re-evaluated Conditional Emergency Stop information according to table 4.8.3 implies that the accepted Conditional Emergency Stop information may be accepted or rejected in a further step (see clause 3.10.2.2) depending on the given stop location. This decision, based on the comparison between the min safe front end position of the train at the time the message was received and the given stop location, shall be considered part of the evaluation process as it affects the further re-evaluation of information stored in the transition buffer (see clause 3.10.2.4).

4.8.5.7.1 Note: For the case of the Unconditional Emergency Stop information accepting the information according to table 4.8.3 will always lead to the train being tripped (see clause 3.10.2.3) when re-evaluation of the transition buffer is completed. Information accepted during re-evaluation of information stored in the transition buffer can then be affected on transition to TR mode according to conditions in Table 4.10.

4.8.5.8 Note: The requirement to acknowledge an Emergency Stop information according to clause 3.10.1.4, i.e., communicating to the RBC if the information has been accepted (Conditional or Unconditional Emergency Stop) or rejected because the train has passed the stop location (Conditional Emergency Stop only), applies to the time when the information is used, immediately after the sequential update has been completed. Regards acknowledging the reception of an emergency stop message, as for any other information received from trackside, see clause 3.16.3.5.

<!-- end of page 79 -->

# **4.9 What happens to accepted and stored information when entering a given level**

## **4.9.1 Introduction**

4.9.1.1 Every data that can be stored onboard after being accepted may be influenced by a level transition.

4.9.1.2 A level transition acts on the “status” of stored information.

4.9.1.3 In case of entering level 1, MA Request Parameters, Position Report Parameters and Track Ahead Free Request shall be deleted.

4.9.1.3.1 In case of entering level 0, NTC or 1, the information “Inhibition of revocable TSRs from balises in level 2” shall be deleted.

4.9.1.4 For all other stored data, a level transition has no effect (void).

<!-- end of page 80 -->

# **4.10 What happens to accepted and stored information when entering a given mode**

## **4.10.1 Introduction**

4.10.1.1 Every data that can be stored onboard after being accepted may be influenced by a mode transition.

4.10.1.2 A mode transition acts on the “status” of stored information.

4.10.1.3 Depending on which mode is entered, the action shall be one of the following:

   - a) data is deleted,

   - b) data is to be revalidated,

   - c) data is reset (set to default values)

   - d) data status is unchanged,

   - e) not relevant (the action on the data cannot be determined. This concerns the entry in SF and IS modes)

D = Deleted TBR = To Be Revalidated U = Unchanged NR = Not relevant R = Reset

||||||||||**Ente**|**red**|**Mode**|||||||||
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
|**Data Stored on-**|**NP**|**SB**|**PS**|**SH**|**SM**|**FS**|**AD**|**LS**|**SR**|**OS**|**SL**|**NL**|**UN**|**TR**|**PT**|**SF**|**IS**|**SN**|**RV**|
|**board**||||||||||||||||||||
|National Values|U|U|U|U|U|U|U|U|U|U|U|U|U|U|U|NR|NR|U|U|
|Not yet applicable|D|U|U|U|U|U|U|U|U|U|U|U|U|U|U|NR|NR|U|U|
|National Values||||||||||||||||||||

<!-- end of page 81 -->

||||||||||**Ente**|**red**|**Mode**|||||||||
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
|**Data Stored on-**<br>**board**|**NP**|**SB**|**PS**|**SH**|**SM**|**FS**|**AD**|**LS**|**SR**|**OS**|**SL**|**NL**|**UN**|**TR**|**PT**|**SF**|**IS**|**SN**|**RV**|
|Linking|D|D|D|D|U|U|U|U|D|U|D|D|D|D|U|NR|NR|D|D|
|Movement Authority<br>(excluding SM<br>Authorisation)|D|D|D|D|D|U|U|U|D|U|D|D|D|D|U|NR|NR|D|D|
|Movement Authority<br>(SM Authorisation)|D|D|D|D|U|D|D|D|D|D|D|D|D|D|U|NR|NR|D|D|
|Gradient Profile|D|D|D|D|U|U|U|U|D|U|D|D|D|D|U|NR|NR|D|D|
|International SSP|D|D|D|D|U|U|U|U|D|U|D|D|D|D|U|NR|NR|D|D|
|Axle load speed profile|D|D|D|D|U|U|U|U|D|U|D|D|D|D|U|NR|NR|D|D|
|STM max speed|D|D|D|D|D|U|U|U|D|U|D|D|U|U|U|NR|NR|U|D|
|STM system<br>speed/distance|D|D|D|D|D|U|U|U|D|U|D|D|U|U|U|NR|NR|U|D|
|Level Transition<br>announcement|D|D|U|D|D|U|U|U|D|U|D|D|D|U|U|NR|NR|D|D|
|Immediate Level<br>Transition<br>Order/Conditional Level<br>Transition Order|U|U|U|U|D|D|D|D|D|D|U|U|D|U|D|NR|NR|D|D|
|Stop Shunting on desk<br>opening|D|D|U|U|D|U|U|U|U|U|D|U|U|U|U|NR|NR|U|U|
|List of Balise Groups for<br>SH area|D|D|U|U|D|U|U|U|D|U|D|D|D|D|U|NR|NR|D|D|
|MA Request<br>Parameters|D|U|U|U|U|U|U|U|U|U|U|U|U|U|U|NR|NR|U|U|

<!-- end of page 82 -->

||||||||||**Ente**|**red M**|**ode**|||||||||
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
|**Data Stored on-**<br>**board**|**NP**|**SB**|**PS**|**SH**|**SM**|**FS**|**AD**|**LS**|**SR**|**OS**|**SL**|**NL**|**UN**|**TR**|**PT**|**SF**|**IS**|**SN**|**RV**|
|Position Report<br>parameters|D|U|U|U|U|U|U|U|U|U|U|U|U|U|U|NR|NR|U|U|
|List of Balise Groups in<br>SR Authority + SR<br>mode speed limit and<br>distance|D|D|D|D|D|D|D|D|U|D|D|D|D|D|U|NR|NR|D|D|
|Temporary Speed<br>Restriction|D|D|D|D|U|U|U|U|U|U|D|D|U|U|U|NR|NR|D|D|
|Inhibition of revocable<br>TSRs from balises in<br>level 2|D|D|D|D|U|U|U|U|D|U|D|D|D|U|U|NR|NR|D|D|
|Default Gradient for<br>TSR|D|D|D|D|U|U|U|U|U|U|D|D|U|U|U|NR|NR|D|D|
|Signalling related<br>Speed Restriction|D|D|D|D|D|U|U|U|D|U|D|D|D|D|U|NR|NR|D|D|
|Route Suitability Data|D|D|D|D|D|U|U|U|D|U|D|D|D|D|U|NR|NR|D|D|
|Adhesion Factor (from<br>trackside)|R|R|R|R|U|U|U|U|U|U|R|R|U|U|U|NR|NR|R|U|
|Adhesion Factor (from<br>driver)|R|R|R|R|U|U|U|U|U|U|R|R|U|U|U|NR|NR|U|U|
|Plain Text Information|D|D|D|D|U|U|U|U|U|U|D|D|U|U|U|NR|NR|D|U|
|Fixed Text Information|D|D|D|D|U|U|U|U|U|U|D|D|U|U|U|NR|NR|D|U|
|Geographical Position|D|U|D|D|U|U|U|U|U|U|D|U|U|U|U|NR|NR|D|D|
|Mode Profile|D|D|D|D|D|U|U|U|D|U|D|D|D|D|U|NR|NR|D|D|

<!-- end of page 83 -->

||||||||||**Ente**|**red**|**Mode**|||||||||
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
|**Data Stored on-**<br>**board**|**NP**|**SB**|**PS**|**SH**|**SM**|**FS**|**AD**|**LS**|**SR**|**OS**|**SL**|**NL**|**UN**|**TR**|**PT**|**SF**|**IS**|**SN**|**RV**|
|RBC Transition Order|D|D|D|D|D|U|U|U|D|U|D|D|D|D|U|NR|NR|D|D|
|Radio Infill Area<br>information|D|D|D|D|D|U|U|U|D|D|D|D|D|D|U|NR|NR|D|D|
|EOLM information|TBR|U|D|D|U|U|U|U|U|U|U|U|U|U|U|NR|NR|U|U|
|Track Conditions<br>excluding sound horn,<br>non stopping areas,<br>tunnel stopping areas<br>and big metal masses|R|R|R|R|U|U|U|U|R|U|R|U|R|U|U|NR|NR|R|R|
|Track conditions sound<br>horn, non stopping<br>areas, tunnel stopping<br>areas|R|R|R|R|U|U|U|U|R|U|R|R|R|R|R|NR|NR|R|R|
|Track condition big<br>metal masses|R|R|R|R|U|U|U|U|R|U|R|U|U|U|U|NR|NR|U|R|
|Unconditional<br>Emergency Stops|D|D|D|D|U|U|U|U|D|U|D|D|D|U|U|NR|NR|D|D|
|Conditional Emergency<br>Stops|D|D|D|D|U|U|U|U|D|U|D|D|D|U|U|NR|NR|D|D|
|Train Position|TBR|U|U|U|U|U|U|U|U|U|U[1]|<br>U|U|U|U|NR|NR|U|U|
|Accumulated<br>underestimation /<br>overestimation in<br>measuring the<br>movements over a<br>defined total distance|U|U|U|U|U|U|U|U|U|U|U|U|U|U|U|NR|NR|U|U|

<!-- end of page 84 -->

||||||||||**Ente**|**red**|**Mode**|||||||||
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
|**Data Stored on-**<br>**board**|**NP**|**SB**|**PS**|**SH**|**SM**|**FS**|**AD**|**LS**|**SR**|**OS**|**SL**|**NL**|**UN**|**TR**|**PT**|**SF**|**IS**|**SN**|**RV**|
|Train Data|D|TBR|U|TBR|TBR|U|U|U|U|U|U|TBR|<br>U|U|U|NR|NR|U|U|
|ERTMS/ETCS level|TBR|U|U|U|U|U|U|U|U|U|U|U|U|U|U|NR|NR|U|U|
|Table of priority of<br>trackside supported<br>levels|TBR|U|U|U|U|U|U|U|U|U|U|U|U|U|U|NR|NR|U|U|
|Not yet applicable table<br>of priority of trackside<br>supported levels|U|D|U|D|D|U|U|U|D|U|D|D|D|U|U|NR|NR|D|D|
|Driver ID|D|TBR|U|U|U|U|U|U|U|U|D|U|U|U|U|NR|NR|U|U|
|Radio Network<br>information (Radio<br>Network type and GSM-<br>R Radio Network ID)|U|U|U|U|U|U|U|U|U|U|U|U|U|U|U|NR|NR|U|U|
|Radio system used for<br>safe radio connection|D|U|U|U|U|U|U|U|U|U|U|U|U|U|U|NR|NR|U|U|
|RBC contact information|TBR|U|U|U|U|U|U|U|U|U|U|U|U|U|U|NR|NR|U|U|
|Mission performed with<br>only one radio system|D|D|U|D|U|U|U|U|U|U|U|U|U|U|U|NR|NR|U|U|
|Train Running Number|D|TBR|U|U|U|U|U|U|U|U|D|U|U|U|U|NR|NR|U|U|
|Reversing Area<br>Information|D|D|D|D|D|U|U|U|D|U|D|D|D|D|U|NR|NR|D|U|
|Reversing Supervision<br>Information|D|D|D|D|D|U|U|U|D|U|D|D|D|D|U|NR|NR|D|U|
|Track Ahead Free<br>Request|D|D|D|D|D|D|D|D|U|U|D|D|D|D|U|NR|NR|D|D|

<!-- end of page 85 -->

||||||||||**Ente**|**red**|**Mode**|||||||||
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
|**Data Stored on-**<br>**board**|**NP**|**SB**|**PS**|**SH**|**SM**|**FS**|**AD**|**LS**|**SR**|**OS**|**SL**|**NL**|**UN**|**TR**|**PT**|**SF**|**IS**|**SN**|**RV**|
|Permitted Braking<br>Distance Information|D|D|D|D|D|U|U|U|D|U|D|D|D|D|U|NR|NR|D|D|
|Level Crossing<br>information|D|D|D|D|U|U|U|U|D|U|D|D|D|D|U|NR|NR|D|D|
|RBC/RIU System<br>Version|D|U|U|U|U|U|U|U|U|U|U|U|U|U|U|NR|NR|U|U|
|Operated System<br>Version|U|U|U|U|U|U|U|U|U|U|U|U|U|U|U|NR|NR|U|U|
|Virtual Balise Covers|U|U|U|U|U|U|U|U|U|U|U|U|U|U|U|NR|NR|U|U|
|Language used to<br>display information to<br>the driver|U|U|U|U|U|U|U|U|U|U|U|U|U|U|U|NR|NR|U|U|
|Generic LS function<br>marker|U|U|U|U|U|U|U|U|U|U|U|U|U|U|U|NR|NR|U|U|
|LSSMA display toggle<br>on order|D|D|D|D|D|D|D|U|D|D|D|D|D|D|U|NR|NR|D|D|
|ATO selector position|U|U|U|U|U|U|U|U|U|U|U|U|U|U|U|NR|NR|U|U|

#### [1]: exception: “D” when the status is invalid

<!-- end of page 86 -->

### **4.10.1.4 NOTES:**

4.10.1.4.1 Intentionally deleted.

4.10.1.4.2 The following information is not considered to be stored information:

   - a) Repositioning information

   - b) Session Management (exception: the RBC contact information, which is given with an order to establish a communication session, is stored on-board)

   - c) Danger for SH information

   - d) Assignment of Co-ordinate system

   - e) Infill Location Reference

   - f) Location Identity (NID_C + NID_BG transmitted in the balise telegram)

   - g) Recognition of exit from TRIP mode

   - h) Acknowledgement of Train Data

   - i) SH refused

   - j) SH authorised

   - k) Balise/loop System Version

   - l) Intentionally deleted

   - m) Intentionally deleted

   - n) Revocation of Emergency Stop (Conditional or Unconditional)

   - o) Temporary Speed Restriction Revocation

   - p) Intentionally deleted

   - q) Acknowledgement of session termination

   - r) Default Balise Information

   - s) Request to shorten MA (Note: if the request is accepted, the proposed shortened MA, the mode profile (if any) and the list of balise groups for SH area (if any) become(s) stored information)

   - t) Train Rejected

   - u) Train Accepted

   - v) SoM position report confirmed by RBC

   - w) Track Ahead Free up to level 2 transition location

   - x) Signalling related speed restriction value zero (i.e., train trip order)

   - y) Stop if in SR mode

   - z) Data to be forwarded to a National System through the STM interface

   - aa) LSSMA display toggle off order

<!-- end of page 87 -->

- bb) SM Authorisation cc) SM Refused

- dd) Acknowledgement of safe consist length info for SM

<!-- end of page 88 -->

# **4.11 What happens to stored information when exiting NP mode**

4.11.1.1 Status of stored information, which is set to "Invalid" when No Power mode is entered, shall be affected, when relevant, by information from the Cold Movement Detection function, according to the following table:

||||||**Stat**|**us of**|**On-b**|**oard**|**stored info**|**rmatio**|**n**|||
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
||<br>inf|EOLM<br>ormati|<br>on|Trai|n Posi|tion|ERT|MS/E<br>Level|TCS<br> <br>Table<br>supp|of trac<br>orted l|kside<br>evels|RB<br>inf|C contact<br>ormation|
|**Transition conditions**|Un-<br>known|<br>Invalid|Valid|<br>Un-<br>known<br>|Invalid|Valid|Un-<br>know<br>n|Invalid|Valid<br>Un-<br>known|Invalid|Valid|Un-<br>known|Invalid Valid|
|No Cold movement occurred||~~⚫~~|||~~⚫~~|||~~⚫~~||~~⚫~~|||~~⚫~~|
|Cold movement detected or<br>Cold movement information<br>not available||~~⚫~~||||||||~~⚫~~||||

4.11.1.2 Note: Status of stored information, which remains valid after NP mode has been entered, is not affected by information from the Cold Movement Detection function.

4.11.1.3 If a cold movement has been detected (see section 3.15.8), or the Cold Movement Detection function is not able to confirm that no cold movement has taken place, no change of status of information to “valid” shall be made until it has been validated by a different means than cold movement detection.

4.11.1.4 In case Supervised Manoeuvre, Shunting or Passive Shunting mode was left to No Power mode and a stored and not yet evaluated immediate level transition order or conditional level transition order has to be evaluated (see 4.4.8.1.5, 4.4.20.1.11 and 4.4.21.1.11.1), the following shall apply:

   - a) The above table in 4.11.1.1 shall not affect the previously applicable level and the table of trackside supported levels, which were set to "Invalid" when No Power mode was entered;

   - b) The previously applicable level which was set to "Invalid" when No Power mode was entered, shall be considered as the current level for the evaluation of the immediate level transition order or the conditional level transition order;

   - c) By exception to 5.10.4.1 b), any level change, which result from the immediate level transition order or the conditional level transition order, shall not lead to any driver acknowledgment;

   - d) The table of trackside supported levels, which was applicable and was set to "Invalid" when No Power mode was entered, shall be deleted;

   - e) The level and the table of trackside supported levels, which result from the immediate level transition order or the conditional level transition order, shall be set to “invalid” and the above table in 4.11.1.1 shall be applied to them by analogy.

<!-- end of page 89 -->

# **4.12 What happens to an ongoing brake command when entering a given mode**

4.12.1.1 The reason for which a brake command has been triggered in a given mode may be influenced by a mode transition.

4.12.1.2 Depending on which mode is entered, the action shall be one of the following:

   - a) the brake command reason is revoked, i.e. it does not apply anymore in the context of the entered mode

   - b) the brake command reason is maintained, i.e. it remains applicable in the context of the entered mode

   - c) the brake command reason is to be re-evaluated according to the data available in the entered mode

   - d) not relevant (there is no transition from the mode in which the brake command reason could be applicable to the entered mode or the transition condition(s) to the entered mode can only be fulfilled when the condition(s) to release the brake command associated to this individual reason (see 3.14.1) is(are) fulfilled)

   - e) not defined (the action on the brake command reason cannot be determined. This concerns the entry in SF and IS modes)

M = Maintained R = Revoked TBR = To Be Re-evaluated Grey cells = Not relevant or not defined

<!-- end of page 90 -->

|||||||||**E**|**ntere**|**d Mo**|**de**||||||||
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
|**Brake command**<br>**reason**|**NP**|**SB**|**PS**|**SH**|**SM**|**FS**|**AD**|**LS**|**SR**|**OS**|**SL NL**|**UN**|**TR**|**PT**|**SF**|**IS**|**SN**|**RV**|
|Trip|R||||||||||||||||||
|Speed & Distance<br>monitoring|R|R||TBR|TBR|TBR||TBR|TBR|TBR||TBR|R||||TBR||
|Roll Away Protection|R|R||M|M [2]|M||M|M|M||M|R||||R||
|Unauthorised Direction<br>Movement Protection|R|R||R|M [2]|M [1]||M [1]|M [1]|M [1]||R|R||||R||
|Standstill Supervision|R|||R|R|R||R|R|R|R|R|R||||R||
|Linking inconsistency|R|R||M|M [2]|M||M|M|M||M|M||||M||
|BG message<br>inconsistency|R|R||M|M [2]|M||M|M|M||M|M||||M||
|RAMS related functions|R|R||M|M [2]|M||M|M|M||M|M||||M||
|Check safe radio<br>connection<br>(T_NVCONTACT)|R|R||R||M||M|R|M||R|R||||R||
|Reverse Movement<br>distance in RV mode<br>overpassed|R|R|||||||||||||||||
|Reverse Movement<br>distance in PT mode<br>overpassed|R|R||R|R|R||R|R|R|||||||||
|Change of Train Data<br>from sources different<br>from the driver while<br>running|R|R||R|R|M||M|M|M|R|M|M|M|||M||

<!-- end of page 91 -->

|||||||||**E**|**ntere**|**d Mo**|**de**|||||||||
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
|**Brake command**<br>**reason**|**NP**|**SB**|**PS**|**SH**|**SM**|**FS**|**AD**|**LS**|**SR**|**OS**|**SL**|**NL**|**UN**|**TR**|**PT**|**SF**|**IS**|**SN**|**RV**|
|Train movement detected<br>while the driver is<br>modifying or revalidating<br>the Train Data (ETCS or<br>NTC)|R|R||R||M||M|M|M|||M|M||||M||
|Safe consist length<br>information no longer<br>available|R|R||R||||||||||M||||||
|Train movement detected<br>while the driver is<br>entering SR<br>speed/distance limits|R|R||R||R||R||R|||R|R||||R||
|Text message not<br>acknowledged|R|R||R|M|M||M|M|M|R||M|M|M|||R||
|STM control function<br>(see SUBSET-035<br>10.3.3.3)|R|R||R|R|R||R|R|R|||R|R||||||
|STM control function<br>(see SUBSET-035<br>10.3.3.4)|R|R||R||R||R|R|R|||R|R||||||
|Mode change to OS not<br>acknowledged|R|R||R||R||R|R||||R|R||||R||
|Mode change to SH not<br>acknowledged|R|R||||||||||||R||||||
|Mode change to LS not<br>acknowledged|R|R||R||R|||R|R|||R|R||||R||

<!-- end of page 92 -->

|||||||||**E**|**ntere**|**d Mo**|**de**||||||
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
|**Brake command**<br>**reason**|**NP**|**SB**|**PS**|**SH**|**SM**|**FS**|**AD**|**LS**|**SR**|**OS**|**SL NL**|**UN**|**TR**|**PT SF IS**|**SN**|**RV**|
|Change to level NTC not<br>acknowledged|R|R||R||R||R|R|R||R|R|R|||
|Change to level 0 not<br>acknowledged|R|R||R||R||R|R|R|||R||R||

[1]: exception: R in case of transition from PT mode

[2]: exception: R in case the SM authorisation changes the train orientation

<!-- end of page 93 -->
