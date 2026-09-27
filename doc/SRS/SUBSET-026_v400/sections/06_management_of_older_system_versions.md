**ERTMS/ETCS System Requirements Specification Chapter 6 Management of older System Versions** REF  :  SUBSET-026-6 ISSUE :

4.0.0 DATE : 05/07/2023

<!-- end of page 1 -->

# **6.1 Modification History**

|Issue Number<br>Date|Modification / Description|Author|
|---|---|---|
|3.0.0<br>23/12/08|First and release version|Hougardy A.|
|3.0.1<br>22/12/09|Including the results of the editorial review of the SRS<br>3.0.0 and the other error CR’s that are in state “Analysis<br>completed” according to ERA CCM|Hougardy A.|
|3.1.0<br>22/02/10|Release version|Hougardy A.|
|3.1.1<br>08/11/10|Including all CR’s that are in state “Analysis completed”<br>according to ERA CCM, plus CR731.|Hougardy A.|
|3.2.0<br>22/12/10|Release version|Hougardy A.|
|3.2.1<br>13/12/11|Including all CR’s that are in state “Analysis completed”<br>according to ERA CCM.|Hougardy A.|
|3.3.0<br>07/03/12|Baseline 3 release version|Hougardy A.|
|3.3.1<br>04/04/14|CR’s 1159, 1176, 1185|Gemine O.|
|3.3.2<br>23/04/14|Baseline 3 1<sup>st</sup>maintenance pre-release version|Gemine O.|
|3.3.3<br>06/05/14|CR 1223<br>Baseline 3 1<sup>st</sup>maintenance 2<sup>nd</sup>pre-release version|Gemine O.|
|3.4.0<br>12/05/14|Baseline 3 1<sup>st</sup>maintenance release version|Gemine O.|
|3.4.1<br>23/06/14|no change|Gemine O.|
|3.4.2<br>17/11/15|CR’s 299, 1089, 1262, 1266, 1280|Gemine O.|
|3.4.3<br>16/12/15|Update due to overall CR consolation phase|Gemine O.|
|3.5.0<br>18/12/15|Baseline 3 2<sup>nd</sup>release version as recommended to EC<br>(see ERA-REC-123-2015/REC)|Gemine O.|
|3.5.1<br>28/04/16|No change|Gemine O.|

<!-- end of page 2 -->

|3.6.0<br>13/05/16|Baseline 3 2<sup>nd</sup>release version|Hougardy A.|
|---|---|---|
|3.6.1<br>29/05/17|CR 994|Gemine O.|
|3.6.2<br>31/05/18|CR 994 (bad implementation)|Gemine O.|
|3.6.3<br>21/02/20|CR’s 1320, 1334, 1335, 1338|Gemine O.|
|3.6.4<br>22/06/20|No change|Gemine O.|
|3.6.5<br>22/12/21|CR’s 1238, 1395|Hougardy A.|
|3.6.6<br>29/08/22|CR’s 968, 988, 1238 (updated), 1307, 1342, 1350,<br>1363, 1367, 1389, 1397, 1408, 1423|Hougardy A.|
|3.9.1<br>24/11/22|CR’s 1307, 1367 (updated), 1424, 1425<br>Outcome of B4R1 1<sup>st</sup>consolidation phase|Gemine O.<br>Hougardy A.|
|3.9.2<br>21/02/23|Outcome of B4R1 2<sup>nd</sup>consolidation phase|Gemine O.<br>Hougardy A.|
|3.9.3<br>31/05/23|CR 1359<br>Outcome of B4R1 3<sup>rd</sup>consolidation phase|Gemine O.<br>Hougardy A.|
|3.9.4|CR1342 (updated)|Gemine O.|
|30/06/23|Outcome of B4R1 4<sup>th</sup>consolidation phase|Hougardy A.|
|4.0.0<br>05/07/23|Baseline 4 1<sup>st</sup>release version|Gemine O.<br>Hougardy A.|

<!-- end of page 3 -->

# **6.2 Table of Contents**

|6.1|Modification History ........................................................................................................... 2|
|---|---|
|6.2|Table of Contents .............................................................................................................. 4|
|6.3|Scope................................................................................................................................ 5|
|6.4|Envelopes of system versions ........................................................................................... 6|
|6.4|.1<br>Trackside - envelope of legally operated system versions .......................................... 6|
|6.4|.2<br>On-board – allowed envelopes of supported system versions .................................... 6|
|6.5|Trackside requirements in relation to older system versions ............................................. 7|
|6.5|.1<br>Trackside areas operated with system version number X = 1 .................................... 7|
|6.5|.2<br>Trackside areas operated with system version number X = 2 .................................. 37|
|6.5|.3<br>Trackside areas operated with system version number X = 3 .................................. 52|
|6.6|On-board requirements in relation to older system versions ............................................ 53|
|6.6|.1<br>Introduction .............................................................................................................. 53|
|6.6|.2<br>Specific requirements for on-board operating with system version number X = 1 ..... 53|
|6.6|.3<br>Handling of air gap data related to system version number X = 1 ............................. 55|
|6.6|.4<br>Specific requirements for on-board operating with system version number X = 2 ..... 70|
|6.6|.5<br>Handling of air gap data related to system version number X = 2 ............................. 71|

<!-- end of page 4 -->

# **6.3 Scope**

6.3.1.1 The chapter defines:

   - a) the composition of envelope of legally operated system versions, i.e. all the ERTMS/ETCS system versions that trackside shall be allowed to operate.

   - b) the allowed envelopes of system versions supported by the on-board.

6.3.1.2 By default, all the clauses listed in the other SRS chapters are applicable regardless of the system version operated (see SUBSET-104 § 6.1.3.2); this chapter includes the exceptions to those clauses and the additional clauses, which apply when the system version of some trackside constituents and/or the system version operated relates to a version number older than the last one introduced.

<!-- end of page 5 -->

# **6.4 Envelopes of system versions**

## **6.4.1 Trackside - envelope of legally operated system versions**

6.4.1.1 **Incompatible versions**

6.4.1.1.1 The system version number X, which a trackside infrastructure is allowed to operate with, shall be one of the following: 1, 2 or 3

6.4.1.2 **Compatible versions**

6.4.1.2.1 Within system version number X = 1, the system version number Y that a trackside infrastructure is allowed to use shall be any of the following: 0 or 1

6.4.1.2.2 Within system version number X = 2, the system version number Y that a trackside infrastructure is allowed to use shall be any of the following: 0, 1, 2 or 3

6.4.1.2.3 Within system version number X = 3, the system version number Y that a trackside infrastructure is allowed to use shall be any of the following: 0

**6.4.2 On-board – allowed envelopes of supported system versions**

6.4.2.1 The highest system version number supported by the ERTMS/ETCS on-board shall be one of the following: 2.1, 2.2 or 3.0.

6.4.2.2 In case the highest system version number supported by the ERTMS/ETCS on-board is not 3.0, the ERTMS/ETCS on-board is said to support a reduced envelope of system versions, which includes all the system versions from 1.0 up to its highest supported one. Refer to SUBSET-153 for the applicable exceptions.

<!-- end of page 6 -->

# **6.5 Trackside requirements in relation to older system versions**

## **6.5.1 Trackside areas operated with system version number X = 1**

**6.5.1.1 Introduction**

6.5.1.1.1 The section is applicable for trackside infrastructures that will be tendered and still operated with the system version number X = 1, after the entry into force of this release of the SRS.

6.5.1.1.2 Within a trackside infrastructure operated with the system version number X = 1, it shall be allowed to use the following values of M_VERSION: 1.0 and 1.1.

6.5.1.1.3 Within a trackside area operated with an RBC certified to the system version number X = 1, it shall also be allowed to use for balises the following values of M_VERSION: 2.0, 2.1, 2.2, 2.3 and 3.0.

6.5.1.1.3.1 Note: this configuration is meaningful in case the trains operating on this RBC area support the system version number X = 2 or 3 and the on-board requirements related to the trackside information marked with 2.0, 2.1, 2.2, 2.3 or 3.0 are applicable regardless of the operated version (i.e. they are applied by the on-board equipment even if this latter operates with the system version number X = 1 ordered by RBC).

**6.5.1.2 Exceptions to chapter 3**

6.5.1.2.1 Intentionally deleted.

6.5.1.2.1.1 Clause 3.4.5.2.3 a) shall not apply.

6.5.1.2.1.2 Clause 3.5.2.6.1 b) shall be replaced with “The telephone number of the RBC.”

6.5.1.2.1.3 Clause 3.5.2.6.2 b) shall be replaced with “The telephone number of the accepting RBC.”

6.5.1.2.1.4 Clause 3.5.3.7 e) shall be replaced with: “When the trackside receives the session established report or the information that no compatible system version is supported by the on-board, it shall consider the communication session established.”

6.5.1.2.1.5 Clause 3.5.4.6 shall be replaced with: “When the trackside receives a session established report inside an existing communication session it shall ignore this message.”

6.5.1.2.1.6 Clause 3.5.6.1.1 shall not apply.

6.5.1.2.2 Clause 3.7.1.1 b) shall be replaced with: “When needed, limitations related to the movement authority, i.e. Mode profile for On Sight or Shunting and signalling related speed restriction (see sections 3.12.4 and 3.11.6). Mode profile and Signalling related Speed restriction shall always be sent together with the MA to which the information belongs”

6.5.1.2.3 In clause 3.7.1.1 c), the bullet “Optionally Speed restriction to ensure a given permitted braking distance (see section 3.11. 11)” shall not apply.

<!-- end of page 7 -->

6.5.1.2.4 In clause 3.7.2.4, the bullet “LX speed restrictions” shall not apply.

6.5.1.2.5 In clause 3.7.2.4, the bullet “Inhibition of revocable TSRs from balises in level 2 (from RBC only)” shall not apply.

6.5.1.2.6 Clause 3.9.3.2 shall be replaced with: “The orders shall be sent via balise groups.”

6.5.1.2.7 Clause 3.9.3.8.1 shall not apply.

6.5.1.2.8 Clause 3.11.3.2.2 c) shall not apply.

6.5.1.2.9 Intentionally deleted

6.5.1.2.10 Clause 3.11.5.12 shall not apply.

6.5.1.2.11 Clauses 3.11.9.1, 3.12.5.1, 3.12.5.2, 3.12.5.4, 3.12.5.5, 3.12.5.6, 3.12.5.7, 3.15.1.2.3.1 o) shall not apply.

6.5.1.2.12 Clauses 3.11.11.1, 3.11.11.2 shall not apply

6.5.1.2.13 Clause 3.12.3.4.3.2 shall not apply.

6.5.1.2.14 Clauses 3.12.3.1.11 and 3.12.3.5.1 shall not apply.

6.5.1.2.15 Clause 3.12.4.1 shall be replaced with: “It shall be possible for trackside to send a Mode Profile. The Mode Profile can request On Sight mode and Shunting mode.”

6.5.1.2.16 Clause 3.15.1.2.3.1 i) shall be replaced with: “Track Conditions excluding big metal masses”.

6.5.1.2.17 Clause 3.15.1.2.3.1 p) shall not apply.

6.5.1.2.18 Clause 3.15.6.5 shall be replaced with: "Amongst the data to be used by applications outside ERTMS/ETCS that can be transmitted by trackside over the ERTMS/ETCS transmission channels, it shall be possible, only from balise as non-infill information or from RBC, to identify some National Systems (see 6.6.3.2.3 Exception [20]) to which the data will be forwarded by the ERTMS/ETCS on-board equipment in case it is interfaced to this National System through an STM."

**6.5.1.3 Exceptions to chapter 4**

6.5.1.3.1 Void.

**6.5.1.4 Exceptions to chapter 5**

6.5.1.4.1 Clause 5.5.3.1.3 shall be replaced with: “If a communication session with an RBC exists: Step 2 - The end of mission shall be reported to the RBC by means of the message “End of Mission”.

   - Step 3 - The RBC shall request to terminate the communication session.

   - Step 4 - The ERTMS/ETCS on-board equipment shall terminate the communication session

<!-- end of page 8 -->

End of procedure”

6.5.1.4.2 Clauses 5.5.3.1.3.1 & 5.5.3.1.4 shall not apply.

**6.5.1.5 Exceptions to chapter 7**

6.5.1.5.1 Clause 7.3.3.5 shall be replaced with: “Exception: Packet 255 “End of Telegram” does not follow the above defined structure.”

6.5.1.5.2 The table 7.4.1.1 shall be replaced with:

|Packet|Packet Name|Page N°|
|---|---|---|
|Number|||
|2|System Version Order||
|3|National Values||
|5|Linking||
|6|Virtual Balise Cover order||
|12|Level 1 Movement Authority||
|15|Level 2 Movement Authority||
|16|Repositioning Information||
|21|Gradient Profile||
|27|International Static Speed Profile||
|39|Track Condition Change of traction system {1}||
|41|Level Transition Order||
|42|Session Management||
|44|Data used by applications outside the ERTMS/ETCS system.||
|45|Radio Network registration||
|46|Conditional Level Transition Order||
|49|List of Balise Groups for SH Area||
|51|Axle load Speed Profile||
|57|Movement Authority Request Parameters||
|58|Position Report Parameters||
|63|List of Balise Groups in SR Authority||
|65|Temporary Speed Restriction||
|66|Temporary Speed Restriction Revocation||
|67|Track Condition Big Metal Masses||
|68|Track Condition {1}||
|70|Route Suitability Data {1}||
|71|Adhesion Factor||
|72|Packet for sending plain text messages||
|79|Geographical Position Information||
|80|Mode profile||
|90|Track Ahead Free up to level 2 transition location||
|131|RBC transition order||
|132|Danger for Shunting information||
|133|Radio infill area information||
|134|EOLM Packet||
|135|Stop Shunting on desk opening||
|136|Infill location reference||

<!-- end of page 9 -->

|Packet<br>Number|Packet Name|Page N°|
|---|---|---|
|137|Stop if in Staff Responsible||
|138|Reversing area information||
|139|Reversing supervision information||
|140|Train running number from RBC||
|141|Default Gradient for Temporary Speed Restriction||
|145|Inhibition of balise group message consistency reaction||
|200|Virtual Balise Cover marker||
|203|National Values for braking curves||
|206|Track Condition||
|207|Route Suitability Data||
|239|Track Condition Change of traction system||
|254|Default balise, loop or RIU information||

{1}Note: used on lines where trains are operated with on-board equipment supporting only system version = 1.0.

### 6.5.1.5.2.1 The table 7.4.1.2 shall be replaced with:

|Packet<br>Number|Packet Name|Page N°|
|---|---|---|
|0|Position Report||
|1|Position Report based on two balise groups||
|3|Onboard telephone numbers||
|4|Error Reporting||
|9|Level 2 transition information||
|11|Validated train data||
|44|Data used by applications outside the ERTMS/ETCS system.||

6.5.1.5.3 Section 7.4.2.0 (Packet Number 0: Virtual Balise Cover marker) shall not apply.

### 6.5.1.5.4 Table 7.4.2.1.1 (Packet Number 3: National Values) shall be replaced with:

|**_Description_**|Downloads a set of Natio|nal Values to th|e train|
|---|---|---|---|
|**_Transmitted by_**|Balise, RBC|||
|**_Content_**|**Variable**|**Length**|**Comment**|
||NID_PACKET|8||
||Q_DIR|2||
||L_PACKET|13||
||Q_SCALE|2||
||D_VALIDNV|15||
||N_ITER|5||
||NID_C(k)|10|Identification of national area(s) to<br>which the set applies|
||V_NVSHUNT|7||
||V_NVSTFF|7||

<!-- end of page 10 -->

|V_NVONSIGHT|7|
|---|---|
|V_NVUNFIT|7|
|V_NVREL|7|
|D_NVROLL|15|
|Q_NVSBTSMPERM|1|
|Q_NVEMRRLS|1|
|V_NVALLOWOVTRP|7|
|V_NVSUPOVTRP|7|
|D_NVOVTRP|15|
|T_NVOVTRP|8|
|D_NVPOTRP|15|
|M_NVCONTACT|2|
|T_NVCONTACT|8|
|M_NVDERUN|1|
|D_NVSTFF|15|
|Q_NVDRIVER_ADHES|1|

6.5.1.5.5 Section 7.4.2.3.1 (Packet Number 13: Staff Responsible distance Information from loop) shall not apply.

6.5.1.5.6 Table 7.4.2.7 (Packet Number 27: International Static Speed Profile) shall be replaced with:

|**_Description_**|Static speed profile and o<br>train category.|ptionally speed limits|depending on the international|
|---|---|---|---|
|**_Transmitted by_**|Any|||
|**_Content_**|**Variable**|**Length**|**Comment**|
||NID_PACKET|8||
||Q_DIR|2||
||L_PACKET|13||
||Q_SCALE|2||
||D_STATIC|15||
||V_STATIC|7||
||Q_FRONT|1||
||N_ITER|5||
||NC_DIFF(n)|4||
||V_DIFF(n)|7||
||N_ITER|5||
||D_STATIC(k)|15||

<!-- end of page 11 -->

|V_STATIC(k)|7|
|---|---|
|Q_FRONT(k)|1|
|N_ITER(k)|5|
|NC_DIFF(k,m)|4|
|V_DIFF(k,m)|7|

6.5.1.5.7 Table 7.4.2.8 (Packet Number 39: Track Condition Change of traction system) shall be replaced with:

|**_Description_**|The packet gives inform|ation about cha|nge of the traction system.|
|---|---|---|---|
|**_Transmitted by_**|Any|||
|**_Content_**|Variable|Length|Comment|
||NID_PACKET|8||
||Q_DIR|2||
||L_PACKET|13||
||Q_SCALE|2||
||D_TRACTION|15||
||M_TRACTION|8|Identity of the traction system|

6.5.1.5.8 Section 7.4.2.8.1 (Packet Number 40: Track Condition Change of allowed current consumption) shall not apply.

6.5.1.5.9 Table 7.4.2.11 (Packet Number 44: Data used by applications outside the ERTMS/ETCS system) shall be replaced with:

|**_Description_**|Messages between trackside<br>information used by applications o|and on-board<br>utside the ERT|devices, which contain<br>MS/ETCS system.|
|---|---|---|---|
|**_Transmitted by_**|Any|||
|**_Content_**|**Variable**|**Length**|**Comment**|
||NID_PACKET|8||
||Q_DIR|2||
||L_PACKET|13||
||NID_XUSER|9||
||Other<br>data,<br>depending<br>on<br>NID_XUSER|||

6.5.1.5.9.1 Table 7.4.2.11.1 (Packet Number 45: Radio Network transition order) shall be replaced with:

|**_Description_**|Packet to give the identity|of the Radio Network.||
|---|---|---|---|
|**_Transmitted by_**|Balise, RBC, RIU|||
|**_Content_**|**Variable**|**Length**|**Comment**|
||NID_PACKET|8||

<!-- end of page 12 -->

|Q_DIR|2|
|---|---|
|L_PACKET|13|
|NID_MN|24|

6.5.1.5.10 Table 7.4.2.13 (Packet Number 51: Axle Load Speed Profile) shall be replaced with:

|**_Description_**|This packet gives the speed<br>equal to the specified value f|restrictions f<br>or the speed|or trains with axle load higher than or<br>restriction|
|---|---|---|---|
|**_Transmitted by_**|Any|||
|**_Content_**|**Variable**|**Length**|**Comment**|
||NID_PACKET|8||
||Q_DIR|2||
||L_PACKET|13||
||Q_SCALE|2||
||Q_TRACKINIT|1||
||D_AXLELOAD|15|Only<br>if<br>Q_TRACKINIT<br>=<br>0,<br>D_AXLELOAD and the following<br>variables follow|
||L_AXLELOAD|15||
||Q_FRONT|1||
||N_ITER|5||
||M_AXLELOAD(n)|7||
||V_AXLELOAD(n)|7|Speed restriction to be applied if the|
||||axle<br>load<br>of<br>the<br>train<br><br>M_AXLELOAD(n)|
||N_ITER|5||
||D_AXLELOAD(k)|15||
||L_AXLELOAD(k)|15||
||Q_FRONT(k)|1||
||N_ITER(k)|5||
||M_AXLELOAD(k,m)|7||
||V_AXLELOAD(k,m)|7|Speed restriction to be applied if the|
||||axle<br>load<br>of<br>the<br>train<br><br>M_AXLELOAD(k,m)|

6.5.1.5.11 Section 7.4.2.13.1 (Packet Number 52: Permitted Braking Distance Information) shall not apply.

6.5.1.5.12 Section 7.4.2.16.1 (Packet Number 64: Inhibition of revocable TSRs from balises in level 2) shall not apply.

<!-- end of page 13 -->

6.5.1.5.12.1 Table 7.4.2.19 (Packet Number 67: Track Condition Big Metal Masses) shall be replaced with:

|**_Description_**|The packet gives details<br>balise transmission due to|concerning whe<br>big metal mas|re to ignore integrity check alarms of<br>ses trackside.|
|---|---|---|---|
|**_Transmitted by_**|Balise|||
|**_Content_**|**Variable**|**Length**|**Comment**|
||NID_PACKET|8||
||Q_DIR|2||
||L_PACKET|13||
||Q_SCALE|2||
||D_TRACKCOND|15||
||L_TRACKCOND|15|The distance for which integrity<br>check alarms of balise transmission<br>shall be ignored|
||N_ITER|5||
||D_TRACKCOND(k)|15||
||L_TRACKCOND(k)|15|The distance for which integrity<br>check alarms of balise transmission<br>shall be ignored|

6.5.1.5.13 Section 7.4.2.20.1 (Packet Number 69: Track Condition Station Platforms) shall not apply.

6.5.1.5.14 Table 7.4.2.21 (Packet Number 70: Route Suitability data) shall be replaced with:

|**_Description_**|The packet gives the characteris|tics needed to|enter a route.|
|---|---|---|---|
|**_Transmitted by_**|Any|||
|**_Content_**|**Variable**|**Length**|**Comment**|
||NID_PACKET|8||
||Q_DIR|2||
||L_PACKET|13||
||Q_SCALE|2||
||Q_TRACKINIT|1||
||D_TRACKINIT|15|Only if Q_TRACKINIT = 1|
||D_SUITABILITY|15|Only<br>If<br>Q_TRACKINIT<br>=<br>0,<br>D_SUITABILITY and the following<br>variables follows|
||Q_SUITABILITY|2||
||M_AXLELOAD|7|If Q_SUITABILITY = axle load.<br>It gives the max axle load|

<!-- end of page 14 -->

|M_TRACTION|8|If<br>Q_SUITABILITY<br>=<br>traction<br>system|
|---|---|---|
|N_ITER|5||
|D_SUITABILITY(k)|15||
|Q_SUITABILITY(k)|2||
|M_AXLELOAD(k)|7|If Q_SUITABILITY(k) = axle load.<br>It gives the max axle load|
|M_TRACTION(k)|8|If Q_SUITABILITY(k) = traction<br>system|

6.5.1.5.15 Section 7.4.2.23 (Packet Number 73: Packet for sending plain text messages) shall be replaced with:

Packet Number 72: Packet for sending plain text message

|**_Description_**||||
|---|---|---|---|
|**_Transmitted by_**|Balise, RBC|||
|**_Content_**|**Variable**|**Length**|**Comment**|
||NID_PACKET|8||
||Q_DIR|2||
||L_PACKET|13||
||Q_SCALE|2||
||Q_TEXTCLASS|2||
||Q_TEXTDISPLAY|1||
||D_TEXTDISPLAY|15|Start condition|
||M_MODETEXTDISPLAY|4|Start condition|
||M_LEVELTEXTDISPLAY|3|Start condition|
||NID_NTC|8|If M_LEVELTEXTDISPLAY = 1<br>(NTC)|
||L_TEXTDISPLAY|15|End condition|
||T_TEXTDISPLAY|10|End condition|
||M_MODETEXTDISPLAY|4|End condition|
||M_LEVELTEXTDISPLAY|3|End condition|
||NID_NTC|8|If M_LEVELTEXTDISPLAY = 1<br>(NTC)|
||Q_TEXTCONFIRM|2||
||L_TEXT|8||
||X_TEXT(L_TEXT)|8||

6.5.1.5.16 Section 7.4.2.24 (Packet Number 74: Packet for sending fixed text messages) shall not apply.

<!-- end of page 15 -->

6.5.1.5.17 Table 7.4.2.25 (Packet Number 79: Geographical Position Information) shall be replaced with:

|**_Description_**|This packet gives geographi<br>to the train.|cal location inf|ormation for one or multiple|references|
|---|---|---|---|---|
|**_Transmitted by_**|Balise, RBC||||
|**_Content_**|**Variable**|**Length**|**Comment**||
||NID_PACKET|8|||
||Q_DIR|2|||
||L_PACKET|13|||
||Q_SCALE|2|||
||Q_NEWCOUNTRY|1|||
||NID_C|10|if Q_NEWCOUNTRY = 1||
||NID_BG|14|Geographical Position<br>Balise Group|Reference|
||D_POSOFF|15|||
||Q_MPOSITION|1|Geographical<br>Position<br>direction|<br>counting|
||M_POSITION|20|Track kilometre reference|value|
||N_ITER|5|||
||Q_NEWCOUNTRY(k)|1|||
||NID_C(k)|10|if Q_NEWCOUNTRY(k) =|1|
||NID_BG(k)|14|Geographical Position<br>Balise Group|Reference|
||D_POSOFF(k)|15|||
||Q_MPOSITION(k)|1|Geographical<br>Position<br>direction|<br>counting|
||M_POSITION(k)|20|Track kilometre reference|value|

### 6.5.1.5.18 Table 7.4.2.26 (Packet Number 80: Mode profile) shall be replaced with:

|**_Description_**|Mode profile associated t|o an MA||
|---|---|---|---|
|**_Transmitted by_**|Any|||
|**_Content_**|**Variable**|**Length**|**Comment**|
||NID_PACKET|8||
||Q_DIR|2||
||L_PACKET|13||
||Q_SCALE|2||
||D_MAMODE|15||
||M_MAMODE|2|OS, SH|

<!-- end of page 16 -->

|V_MAMODE|7||
|---|---|---|
|L_MAMODE|15||
|L_ACKMAMODE|15||
|N_ITER|5||
|D_MAMODE(k)|15||
|M_MAMODE(k)|2|OS, SH|
|V_MAMODE(k)|7||
|L_MAMODE(k)|15||
|L_ACKMAMODE(k)|15||

6.5.1.5.19 Section 7.4.2.26.1 (Packet Number 88: Level Crossing information) shall not apply.

6.5.1.5.20 Section 7.4.2.37.1 (Packet Number 143: Session Management with neighbouring Radio Infill Unit) shall not apply.

6.5.1.5.20.1 Section 7.4.2.37.3 (Packet Number 180: LSSMA display toggle order) shall not apply.

6.5.1.5.20.2 Section 7.4.2.37.4 (Packet Number 181: Generic LS function marker) shall not apply.

6.5.1.5.21 Added section 7.4.2.37.3 (Packet Number 200: Virtual Balise Cover marker) shall apply:

Packet Number 200: Virtual Balise Cover marker

|**_Description_**|Indication to on-board tha|t the telegram can be|ignored according to a VBC.|
|---|---|---|---|
|**_Transmitted by_**|Balise|||
|**_Content_**|**Variable**|**Length**|**Comment**|
||NID_PACKET|8||
||Q_DIR|2||
||L_PACKET|13||
||NID_VBCMK|6||

6.5.1.5.22 Added section 7.4.2.37.4 (Packet Number 203: National Values for braking curves) shall apply:

Packet Number 203: National Values for braking curves

|**_Description_**|Downloads a subset of N<br>This subset is a complem|ational Values to the train, used for braking curves.<br>ent to the National Values included in packet 3.|
|---|---|---|
|**_Transmitted by_**|Balise, RBC||
|**_Content_**|**Variable**|**Length**<br>**Comment**|
||NID_PACKET|8|
||Q_DIR|2|
||L_PACKET|13|
||Q_NVGUIPERM|1|

<!-- end of page 17 -->

|Q_NVSBFBPERM|1||
|---|---|---|
|Q_NVINHSMICPERM|1||
|A_NVMAXREDADH1|6||
|A_NVMAXREDADH2|6||
|A_NVMAXREDADH3|6||
|M_NVAVADH|5||
|M_NVEBCL|4||
|Q_NVKINT|1||
|Q_NVKVINTSET|2|Only<br>if<br>Q_NVKINT<br>=<br>1,<br>Q_NVKVINTSET and the following<br>variables follow|
|A_NVP12|6|Only if Q_NVKVINTSET = 1|
|A_NVP23|6|Only if Q_NVKVINTSET = 1|
|V_NVKVINT|7|= 0km/h|
|M_NVKVINT|7|Valid between  V_NVKVINT and<br>V_NVKVINT(1)<br>If Q_NVKVINTSET = 1, gives the<br>correction<br>factor<br>if<br>maximum<br>emergency brake deceleration is<br>lower than A_NVP12|
|M_NVKVINT|7|Only if Q_NVKVINTSET = 1<br>Valid between V_NVKVINT and<br>V_NVKVINT(1)|
|||Gives<br>the<br>correction<br>factor<br>if<br>maximum<br>emergency<br>brake<br>deceleration<br>is<br>higher<br>than<br>A_NVP23|
|N_ITER|5||
|V_NVKVINT(n)|7||
|M_NVKVINT(n)|7|Valid between V_NVKVINT(n) and<br>V_NVKVINT(n+1)<br>If Q_NVKVINTSET = 1, gives the<br>correction<br>factor<br>if<br>maximum<br>emergency brake deceleration is<br>lower than A_NVP12|

<!-- end of page 18 -->

|M_NVKVINT(n)|7|Only if Q_NV<br>Valid betwe<br>V_NVKVINT<br> <br>|KVINTSET = 1<br>en V_NVKVINT<br>(n+1)<br> <br>|(n) and<br> <br>|
|---|---|---|---|---|
|||Gives<br>the<br>|correction<br>fa|ctor<br>if<br>|
|||maximum|emergency|brake|
|||deceleration<br>A_NVP23|<br>is<br>higher|than|
|N_ITER|5||||
|Q_NVKVINTSET(k)|2||||
|A_NVP12(k)|6|Only if Q_NV|KVINTSET(k) =|1|
|A_NVP23(k)|6|Only if Q_NV|KVINTSET(k) =|1|
|V_NVKVINT(k)|7|= 0km/h|||
|M_NVKVINT(k)|7|Valid betwe<br>V_NVKVINT<br>If Q_NVKVIN<br>correction<br>emergency<br>lower than A|en V_NVKVINT<br>(k,1)<br>TSET(k) = 1, gi<br>factor<br>if<br>m<br>brake decelera<br>_NVP12(k)|(k) and<br>ves the<br>aximum<br>tion is|
|M_NVKVINT(k)|7|Only if Q_NV<br>Valid betwe<br>V_NVKVINT|KVINTSET(k) =<br>en V_NVKVINT<br>(k,1)|1<br>(k) and|
|||Gives<br>the<br>maximum<br>deceleration<br>A_NVP23(k)|correction<br>fa<br>emergency<br> <br>is<br>higher<br>|ctor<br>if<br>brake<br>than|
|N_ITER(k)|5||||
|V_NVKVINT(k,m)|7||||
|M_NVKVINT(k,m)|7|Valid<br>betw<br>and V_NVKV<br>If Q_NVKVIN<br>correction<br>emergency<br>lower than A|een<br>V_NVKVI<br>INT(k,m+1)<br>TSET(k) = 1, gi<br>factor<br>if<br>m<br>brake decelera<br>_NVP12(k)|NT(k,m)<br>ves the<br>aximum<br>tion is|
|M_NVKVINT(k,m)|7|Only if Q_NV<br>Valid<br>betw<br>and V_NVKV|KVINTSET(k) =<br>een<br>V_NVKVI<br>INT(k,m+1)|1<br>NT(k,m)|
|||Gives<br>the|correction<br>fa|ctor<br>if|
|||maximum|emergency|brake|
|||deceleration<br>A_NVP23(k)|<br>is<br>higher<br>|than|

<!-- end of page 19 -->

|L_NVKRINT|5|= 0m|
|---|---|---|
|M_NVKRINT|5|Valid between L_NVKRINT and<br>L_NVKRINT(1)|
|N_ITER|5||
|L_NVKRINT(l)|5||
|M_NVKRINT(l)|5|Valid between L_NVKRINT(l) and<br>L_NVKRINT(l+1)|
|M_NVKTINT|5||

6.5.1.5.23 Added section 7.4.2.37.5 (Packet Number 206: Track Condition) shall apply:

Packet Number 206: Track Condition

|**_Description_**|The packet gives details conce<br>e.g. lower pantograph|rning the tr|ack ahead to support the driver when|
|---|---|---|---|
|**_Transmitted by_**|Any|||
|**_Content_**|**Variable**|**Length**|**Comment**|
||NID_PACKET|8||
||Q_DIR|2||
||L_PACKET|13||
||Q_SCALE|2||
||Q_TRACKINIT|1||
||D_TRACKINIT|15|Only if Q_TRACKINIT = 1|
||D_TRACKCOND|15|Only<br>if<br>Q_TRACKINIT<br>=<br>0,<br>D_TRACKCOND and the following<br>variables follow|
||L_TRACKCOND|15||
||M_TRACKCONDBC|4||
||N_ITER|5||
||D_TRACKCOND(k)|15||
||L_TRACKCOND(k)|15||
||M_TRACKCONDBC(k)|4||

6.5.1.5.24 Added section 7.4.2.37.6 (Packet Number 207: Route Suitability Data) shall apply:

### Packet Number 207: Route Suitability Data

|**_Description_**|The packet gives the charac|teristics needed to en|ter a route.|
|---|---|---|---|
|**_Transmitted by_**|Any|||
|**_Content_**|**Variable**|**Length**|**Comment**|
||NID_PACKET|8||
||Q_DIR|2||
||L_PACKET|13||

<!-- end of page 20 -->

|Q_SCALE|2||
|---|---|---|
|Q_TRACKINIT|1||
|D_TRACKINIT|15|Only if Q_TRACKINIT = 1|
|D_SUITABILITY|15|Only If Q_TRACKINIT = 0,<br>D_SUITABILITY<br>and<br>the<br>following variables follows|
|Q_SUITABILITY|2||
|M_LINEGAUGE|8|If Q_SUITABILITY = loading<br>gauge|
|M_AXLELOADCAT|7|If Q_SUITABILITY = axle load.<br>It gives the max axle load<br>category, assuming that the axle<br>load categories are sorted in<br>ascending order from category A<br>to E5|
|M_VOLTAGE|4|If Q_SUITABILITY = traction<br>system|
|NID_CTRACTION|10|If Q_SUITABILITY = traction<br>system and M_VOLTAGE ≠ 0|
|N_ITER|5||
|D_SUITABILITY(k)|15||
|Q_SUITABILITY(k)|2||
|M_LINEGAUGE(k)|8|If Q_SUITABILITY = loading<br>gauge|
|M_AXLELOADCAT(k)|7|If Q_SUITABILITY = axle load.<br>It gives the max axle load<br>category, assuming that the axle<br>load categories are sorted in<br>ascending order from category A<br>to E5|
|M_VOLTAGE(k)|4|If Q_SUITABILITY = traction<br>system|
|NID_CTRACTION(k)|10|If Q_SUITABILITY = traction<br>system and M_VOLTAGE ≠ 0|

6.5.1.5.25 Added section 7.4.2.37.7 (Packet Number 239: Track Condition Change of traction system) shall apply:

Packet Number 239: Track Condition Change of traction system

|**_Description_**|The packet gives information about change of the traction system.|
|---|---|
|**_Transmitted by_**|Any|

<!-- end of page 21 -->

|**_Content_**|**Variable**|**Length**|**Comment**|
|---|---|---|---|
||NID_PACKET|8||
||Q_DIR|2||
||L_PACKET|13||
||Q_SCALE|2||
||D_TRACTION|15||
||M_VOLTAGE|4|Identity of the traction system|
||NID_CTRACTION|10|NID_CTRACTION<br>given<br>only<br>if<br>M_VOLTAGE ≠ 0|

6.5.1.5.25.1 Table 7.4.3.1 (Packet Number 0: Position Report) shall be replaced with:

|**_Description_**|This packet is used to r<br>additional information (e.g|eport the train<br>. mode, level, et|position and speed as well as some<br>c.)|
|---|---|---|---|
|**_Transmitted to_**|RBC, RIU|||
|**_Content_**|**Variable**|**Length**|**Comment**|
||NID_PACKET|8||
||L_PACKET|13||
||Q_SCALE|2||
||NID_LRBG|10 + 14||
||D_LRBG|15||
||Q_DIRLRBG|2||
||Q_DLRBG|2||
||L_DOUBTOVER|15||
||L_DOUBTUNDER|15||
||Q_INTEGRITY|2||
||L_TRAININT|15|If Q_INTEGRITY = “Train integrity<br>confirmed by external device” or<br>“Train integrity  confirmed by driver”|
||V_TRAIN|7||
||Q_DIRTRAIN|2||
||M_MODE|4||
||M_LEVEL|3||
||NID_NTC|8|If M_LEVEL = NTC|

6.5.1.5.25.2 Table 7.4.3.2 (Packet Number 1: Position Report based on two balise groups) shall be replaced with:

<!-- end of page 22 -->

|**_Description_**|This packet is an extensio<br>in case of single balise gro<br>on-board equipment is ab<br>before) to give a direction<br>report.|n of the “standa<br>ups if the orien<br>le to report a s<br>reference for th|rd position report “ packet 0. It is used<br>tation of the LRBG is unknown but the<br>econd balise group (the one detected<br>e directional information in the position|
|---|---|---|---|
|**_Transmitted to_**|RBC, RIU|||
|**_Content_**|**Variable**|**Length**|**Comment**|
||NID_PACKET|8||
||L_PACKET|13||
||Q_SCALE|2||
||NID_LRBG|10 + 14||
||NID_PRVLRBG|10 + 14|Used as reference for all directional<br>information in the packet: a move<br>from PRVLRBG towards the LRBG<br>defines the “nominal” direction|
||D_LRBG|15||
||Q_DIRLRBG|2|Train<br>orientation<br>according<br>to<br>reference direction|
||Q_DLRBG|2|Train front position according to<br>reference direction|
||L_DOUBTOVER|15||
||L_DOUBTUNDER|15||
||Q_INTEGRITY|2||
||L_TRAININT|15|If Q_INTEGRITY = “Train integrity<br>confirmed by external device” or<br>“Train integrity  confirmed by driver”|
||V_TRAIN|7||
||Q_DIRTRAIN|2|Actual running direction according to<br>reference direction|
||M_MODE|4||
||M_LEVEL|3||
||NID_NTC|8|If M_LEVEL = NTC|

6.5.1.5.25.3 Added Section 7.4.3.3.1 (Packet Number 3: On-board telephone numbers) shall apply:

Packet Number 3: On-board telephone numbers

|**Description**|Telephone numbers asso|ciated to the on-board equipment|
|---|---|---|
|**_Transmitted to_**|RBC, RIU||
|**_Content_**|**Variable**|**Length**<br>**Comment**|

<!-- end of page 23 -->

|NID_PACKET|8|
|---|---|
|L_PACKET|13|
|N_ITER|5|
|NID_RADIO (k)|64|

### 6.5.1.5.25.4 Table 7.4.3.5 (Packet Number 11: Validated train data) shall be replaced with:

|**_Description_**|Validated train data.|||
|---|---|---|---|
|**_Transmitted to_**|RBC|||
|**_Content_**|**Variable**|**Length**|**Comment**|
||NID_PACKET|8||
||L_PACKET|13||
||NID_OPERATIONAL|32||
||NC_TRAIN|15||
||L_TRAIN|12||
||V_MAXTRAIN|7||
||M_LOADINGGAUGE|8||
||M_AXLELOAD|7||
||M_AIRTIGHT|2||
||N_ITER|5||
||M_TRACTION (k)|8|Type of traction system|
||N_ITER|5||
||NID_NTC (k)|8|Type of National System available|

### 6.5.1.5.26 Table 7.5.1.36 (D_VALIDNV) shall be replaced with:

|**_Name_**|Distance to start of va|lidity of national values||
|---|---|---|---|
|**_Description_**||||
|**_Length of variable_**|**_Minimum Value_**|**_Maximum Value_**|**_Resolution/formula_**|
|15 bits|0 cm|327.670 km|10 cm, 1m or 10 m depends on Q_SCALE|

### 6.5.1.5.27 Added section 7.5.1.62.2 (M_AXLELOAD) shall apply:

### M_AXLELOAD

|**_Name_**|Axle load|||
|---|---|---|---|
|**_Description_**||||
|**_Length of variable_**|**_Minimum Value_**|**_Maximum Value_**|**_Resolution/formula_**|
|7 bits|0 t|40 t|0.5 t|
|**_Special/Reserved Values_**|101 0001|Spare||
||…|…||
||111 1101|Spare||
||111 1110|Axle load above 40 t||

<!-- end of page 24 -->

|111 1111|Spare|
|---|---|

### 6.5.1.5.27.1 Table 7.5.1.64 (M_ERROR) shall be replaced with:

|**_Name_**|Identifier of the type o|f error|
|---|---|---|
|**_Description_**|||
|**_Length of variable_**|**_Minimum Value_**|**_Maximum Value_**<br>**_Resolution/formula_**|
|8 bits|||
|**_Special/Reserved Values_**|0|Balise group: linking consistency error (ref. 3.16.2.3)|
||1|Linked balise group: message consistency error (ref. 3.16.2.4.1/4)|
||2|Unlinked balise  group:  message consistency error (ref. 3.16.2.5)|
||3|Radio: message consistency error (ref. 3.16.3.1.1a,c)|
||4|Radio: sequence error  (ref. 3.16.3.1.1b)|
||5|Radio: safe radio connection error (ref. 3.16.3.4, to be sent when<br>communication links re-established)|
||6|Non safety critical failure|
||7|Safety critical failure (ref 4.4.6.1.6 , 4.4.15.1.5)|
||8-255|Spare|

### 6.5.1.5.27.2 Table 7.5.1.68 (M_LOADINGGAUGE) shall be replaced with:

|**_Name_**|Loading gauge|||
|---|---|---|---|
|**_Description_**|Defining the loading g|auge profile of a train (refer to T|SI RST)|
|**_Length of variable_**|**_Minimum Value_**|**_Maximum Value_**|**_Resolution/formula_**|
|8 bits||||
|**_Special/Reserved Values_**|0|No loading gauge is define|d for the train|
||1-255|Non interoperable value (t|his is not a spare value)|

### 6.5.1.5.27.3 Table 7.5.1.65 (M_LEVEL) shall be replaced with:

|**_Name_**|Current Operating Le|vel|
|---|---|---|
|**_Description_**|||
|**_Length of variable_**|**_Minimum Value_**|**_Maximum Value_**<br>**_Resolution/formula_**|
|3 bits|||
|**_Special/Reserved Values_**|0|Level 0|
||1|Level NTC specified by NID_NTC|
||2|Level 1|
||3|Level 2 (formerly level 2 trackside where train reported position and integrity<br>are not used to determine the parts of the track that are occupied by the train)|
||4|Level 2, where train reported position and integrity are used to determine the<br>parts of the track that are occupied by the train (formerly level 3)|
||5-7|Spare|

### 6.5.1.5.27.4 Table 7.5.1.66 (M_LEVELTEXTDISPLAY) shall be replaced with:

**_Name_** Onboard operating level for text display

<!-- end of page 25 -->

|**_Description_**|The text is displayed|when entering / as long as in the defined level|
|---|---|---|
|**_Length of variable_**|**_Minimum Value_**|**_Maximum Value_**<br>**_Resolution/formula_**|
|3 bits|||
|**_Special/Reserved Values_**|0|Level 0|
||1|Level NTC specified by NID_NTC|
||2|Level 1|
||3|Level 2 (formerly level 2 trackside where train reported position and integrity<br>are not used to determine the parts of the track that are occupied by the train)|
||4|Level 2, where train reported position and integrity are used to determine the<br>parts of the track that are occupied by the train (formerly level 3)|
||5|The display of the text shall not be limited by the level|
||6-7|Spare|

### 6.5.1.5.27.5 Table 7.5.1.67 (M_LEVELTR) shall be replaced with:

|**_Name_**|Required level||
|---|---|---|
|**_Description_**|||
|**_Length of variable_**|**_Minimum Value_**|**_Maximum Value_**<br>**_Resolution/formula_**|
|3 bits|||
|**_Special/Reserved Values_**|0|Level 0|
||1|Level NTC specified by NID_NTC|
||2|Level 1|
||3|Level 2 (formerly level 2 trackside where train reported position and integrity<br>are not used to determine the parts of the track that are occupied by the train)|
||4|Level 2, where train reported position and integrity are used to determine the<br>parts of the track that are occupied by the train (formerly level 3)|
||5-7|Spare|

### 6.5.1.5.28 Table 7.5.1.70 (M_MAMODE) shall be replaced with:

|**_Name_**|Required mode for a p|art of the MA||
|---|---|---|---|
|**_Description_**||||
|**_Length of variable_**|**_Minimum Value_**|**_Maximum Value_**|**_Resolution/formula_**|
|2 bits||||
|**_Special/Reserved Values_**|00|On Sight||
||01|Shunting||
||10 – 11|Spare||

### 6.5.1.5.28.1 Table 7.5.1.72 (M_MODE) shall be replaced with:

|**_Name_**|Onboard operating mo|de||
|---|---|---|---|
|**_Description_**||||
|**_Length of variable_**|**_Minimum Value_**|**_Maximum Value_**|**_Resolution/formula_**|
|4 bits||||

<!-- end of page 26 -->

|**_Special/Reserved Values_**|0|Full Supervision|
|---|---|---|
||1|On Sight|
||2|Staff Responsible|
||3|Shunting|
||4|Unfitted|
||5|Sleeping|
||6|Stand By|
||7|Trip|
||8|Post Trip|
||9|System Failure|
||10|Isolation|
||11|Non Leading|
||12|If reported level is NTC, National System; otherwise, Limited Supervision|
||13|National System|
||14|Reversing|
||15|Spare|

### 6.5.1.5.29 Table 7.5.1.73 (M_MODETEXTDISPLAY) shall be replaced with:

|Name|Onboard operating m|ode for text display||
|---|---|---|---|
|Description<br>|The display of the te<br>transition from the de<br>|xt starts if the on-board is i<br>fined mode<br>|n the defined mode/ends if the on-board executes a<br>|
|Length of variable|Minimum Value|Maximum Value|Resolution/formula|
|4 bits||||
|Special/Reserved Values|0|Full Supervision||
||1|On Sight||
||2|Staff Responsible||
||3|Spare||
||4|Unfitted||
||5|Spare||
||6|Stand By||
||7|Trip||
||8|Post Trip||
||9|Spare||
||10|Spare||
||11|Spare||
||12|Spare||
||13|Spare||
||14|Reversing||
||15|No “mode” sub-conditio<br>the text.|n specified for the start/end condition of the display of|

<!-- end of page 27 -->

### 6.5.1.5.30 Table 7.5.1.76 (M_POSITION) shall be replaced with:

|**_Name_**|Track kilometre refere|nce value||
|---|---|---|---|
|**_Description_**|The geographical posi|tion reporting function uses|this variables content as a reference value.|
|**_Length of variable_**|**_Minimum Value_**|**_Maximum Value_**|**_Resolution/formula_**|
|20 bits|0 m|1’048’574 m|1 m|
|**_Special/Reserved Values_**|1’048’575|No more geographical|position calculation after this reference location|

### 6.5.1.5.31 Table 7.5.1.77 (M_TRACKCOND) shall be replaced with:

|**_Name_**|Type of track conditio|n|
|---|---|---|
|**_Description_**|||
|**_Length of variable_**|**_Minimum Value_**|**_Maximum Value_**<br>**_Resolution/formula_**|
|4 bits|||
|**_Special/Reserved Values_**|0000|Non stopping area – tunnel. Initial state: stopping permitted (no tunnel)|
||0001|Non stopping area – bridge. Initial state: stopping permitted (no bridge)|
||0010|Non stopping area – other reasons. Initial state: stopping permitted|
||0011|Powerless section – lower pantograph. Initial state: not powerless section|
||0100|Radio hole (stop supervising T_NVCONTACT). Initial state: supervise<br>T_NVCONTACT|
||0101|Air tightness. Initial state: no request for air tightness|
||0110|Switch off regenerative brake. Initial state: regenerative brake on|
||0111|Switch off eddy current brake for service brake. Initial state: eddy current brake<br>for service brake on|
||1000|Switch off magnetic shoe brake. Initial state: magnetic shoe brake on|
||1001|Powerless section – switch off the main power switch. Initial state: not<br>powerless section|
||1010 –1111|Spare|

6.5.1.5.32 Added section 7.5.1.77.1 (M_TRACKCONDBC) shall apply:

### M_TRACKCONDBC

|**_Name_**|Type of track conditio|n|
|---|---|---|
|**_Description_**|||
|**_Length of variable_**|**_Minimum Value_**|**_Maximum Value_**<br>**_Resolution/formula_**|
|4 bits|||
|**_Special/Reserved Values_**|0000|Non stopping area. Initial state: stopping permitted|
||0001|Tunnel stopping area. Initial state: no tunnel stopping area|
||0010|Sound horn. Initial state: no request for sound horn|
||0011|Powerless section – lower pantograph. Initial state: not powerless section|
||0100|Radio hole (stop supervising T_NVCONTACT). Initial state: supervise<br>T_NVCONTACT|
||0101|Air tightness. Initial state: no request for air tightness|
||0110|Switch off regenerative brake. Initial state: regenerative brake on|

<!-- end of page 28 -->

|0111|Switch off eddy current brake for service brake. Initial state: eddy current brake<br>for service brake on|
|---|---|
|1000|Switch off magnetic shoe brake. Initial state: magnetic shoe brake on|
|1001|Powerless section – switch off the main power switch. Initial state: not<br>powerless section|
|1010|Switch off eddy current brake for emergency brake. Initial state: eddy current<br>brake for emergency brake on|
|1011 –1111|Spare|

### 6.5.1.5.33 Added section 7.5.1.77.2 (M_TRACTION) shall apply:

### M_TRACTION

|**_Name_**|Traction system||
|---|---|---|
|**_Description_**|It indicates the tractio|n system installed on a specific line or respectively that can be used by an engine|
|**_Length of variable_**|**_Minimum Value_**|**_Maximum Value_**<br>**_Resolution/formula_**|
|8 bits|||
|**_Special/Reserved Values_**|0|Line not fitted with any traction system|
||1|3 kV DC, Italy|
||2|25 kV AC 50 Hz, Conventional lines France|
||3|25 kV AC 50 Hz, High speed lines France|
||4|Non interoperable value (this is not a spare value)|
||5|1.5 kV DC, France|
||6|1.5 kV DC, Netherlands|
||7|25 kV AC 50 Hz, Conventional lines Netherlands|
||8|25 kV AC 50 Hz, High speed lines Netherlands|
||9-10|Non interoperable value (this is not a spare value)|
||11|15kV AC 16 2/3 Hz, max. train current 600A Germany|
||12|15kV AC 16 2/3 Hz, max. train current 780A Germany|
||13|15kV AC 16 2/3 Hz, max. train current 900A Germany|
||14|Non interoperable value (this is not a spare value)|
||15|15kV AC 16 2/3 Hz, max. train current 1500A Germany|
||16-25|Non interoperable value (this is not a spare value)|
||26|25 kV AC 50 Hz, Italy|
||27-30|Non interoperable value (this is not a spare value)|
||31|25 kV AC 50 Hz, 1600mm, High speed lines Spain|
||32|3 kV DC, Conventional lines 220 km/h Spain|
||33|3 kV DC, Conventional lines160 km/h Spain|
||34|25 kV AC 50 Hz, 1600mm/1950mm, High speed lines Spain|
||35-40|Non interoperable value (this is not a spare value)|
||41|15 kV AC 16 2/3 Hz, 1320mm/1450 mm, Switzerland|
||42|15 kV AC 16 2/3 Hz, 1450 mm/1600 mm, Switzerland|

<!-- end of page 29 -->

|43|15 kV AC 16 2/3 Hz, 1950 mm, Switzerland|
|---|---|
|44|15 kV AC 16 2/3 Hz, 1320 mm/1450 mm/1600 mm, Switzerland|
|45|15 kV AC 16 2/3 Hz, 1450 mm/1600mm/1950 mm, Switzerland|
|46|15 kV AC 16 2/3 Hz, 1320 mm/1450mm/1600mm/1950 mm, Switzerland|
|47-255|Non interoperable value (this is not a spare value)|

### 6.5.1.5.34 Table 7.5.1.83 (NC_DIFF) shall be replaced with:

|**_Name_**|Specific SSP category||
|---|---|---|
|**_Description_**|It is the specific SSP c<br>Used together with V_<br>go faster or lower than<br>Value 0 of NC_DIFF c<br>of NC_TRAIN.|ategory for which a differential value for the static line speed exists.<br>DIFF to permit trains belonging to the corresponding international train category to<br>the “international basic static speed” given by V_STATIC.<br>orresponds to the LSB of NC_TRAIN, value 14 of NC_DIFF to MSB (15-bit variable)|
|**_Length of variable_**|**_Minimum Value_**|**_Maximum Value_**<br>**_Resolution/formula_**|
|4 bits|0|15<br>Numbers|
|**_Special/Reserved Values_**|0|Specific SSP applicable to Cant Deficiency 275 mm|
||1|Specific SSP applicable to Cant Deficiency 80 mm|
||2|Specific SSP applicable to Cant Deficiency 100 mm|
||3|Specific SSP applicable to Cant Deficiency 130 mm|
||4|Specific SSP applicable to Cant Deficiency 150 mm|
||5|Specific SSP applicable to Cant Deficiency 165 mm|
||6|Specific SSP applicable to Cant Deficiency 180 mm|
||7|Specific SSP applicable to Cant Deficiency 225 mm|
||8|Specific SSP applicable to Cant Deficiency 300 mm|
||9|Specific SSP applicable to Freight train braked in “P” position|
||10|Specific SSP applicable to Freight train braked in “G” position|
||11|Specific SSP applicable to Passenger train|
||12|Specific SSP applicable to Cant Deficiency 245 mm|
||13|Specific SSP applicable to Cant Deficiency 210 mm|
||14-15|Spare|

### 6.5.1.5.34.1 Table 7.5.1.84 (NC_TRAIN) shall be replaced with:

|**_Name_**|International Train Category.||
|---|---|---|
|**_Description_**|Train category to which the train belongs.||
||Thanks to NC_TRAIN, the train knows the “Specific” SSP ca|tegory it must consider.|
||By receiving a list of static speed profile, thanks to NC_DIFF,|the train can select the SSP it must obey.|
||Each bit represents one category.||
||A train can belong to various categories.||
|**_Length of variable_**|**_Minimum Value_**<br>**_Maximum Value_**|**_Resolution/formula_**|
|15 bits||Bitset|

<!-- end of page 30 -->

|**_Special/Reserved Values_**|000 0000 0000 0000|Train does not belong to any of the “International” Train Category|
|---|---|---|
||xxx xxxx xxxx xxx1|Cant Deficiency 275 mm|
||xxx xxxx xxxx xx1x|Cant Deficiency 80 mm|
||xxx xxxx xxxx x1xx|Cant Deficiency 100 mm|
||xxx xxxx xxx 1xxx|Cant Deficiency 130 mm|
||xxx xxxx xxx1 xxxx|Cant Deficiency 150 mm|
||xxx xxxx xx1x xxxx|Cant Deficiency 165 mm|
||xxx xxxx x1xx xxxx|Cant Deficiency 180 mm|
||xxx xxxx 1xxx xxxx|Cant Deficiency 225 mm|
||xxx xxx1 xxxx xxxx|Cant Deficiency 300 mm|
||xxx xx1x xxxx xxxx|Freight train braked in “P” position|
||xxx x1xx xxxx xxxx|Freight train braked in “G” position|
||xxx 1xxx xxxx xxxx|Passenger train|
||xx1 xxxx xxxx xxxx|Cant Deficiency 245 mm|
||x1x xxxx xxxx xxxx|Cant Deficiency 210 mm|
||1xx xxxx xxxx xxxx|Spare|

### 6.5.1.5.34.2 Table 7.5.1.91.1 (NID_MN) shall be replaced with:

|**_Name_**|Identity of Radio Netw|ork||
|---|---|---|---|
|**_Description_**|The NID_MN identifi<br>indicates whether the<br>entered left adjusted i<br>is shorter than 6 digits<br>about NID_MN refer t|es either the GSM-R netwo<br>trackside is fitted with FRM<br>nto the data field, the leftmo<br>, the remaining space is to b<br>o Subset-054.|rk the GSM-R Mobile Terminal has to register with or<br>CS. The NID_MN consists of up to 6 digits which are<br>st digit is the digit to be dialled first. In case the NID_MN<br>e filled with special character “F”. For further information|
|**_Length of variable_**|**_Minimum Value_**|**_Maximum Value_**|**_Resolution/formula_**|
|24 bits|0|999999|Binary Coded Decimal|
|**_Special/Reserved Values_**|901999|FRMCS||
||For each digit ;|||
||Values A – E|Not Used||
||F|Use value F for digit to|indicate no digit (if number shorter than 6 digits)|

### 6.5.1.5.34.3 Table 7.5.1.92 (NID_OPERATIONAL) shall be replaced with:

|**_Name_**|Train Running Numbe|r||
|---|---|---|---|
|**_Description_**|This is the operationa|l train running number.||
|**_Length of variable_**|**_Minimum Value_**|**_Maximum Value_**|**_Resolution/formula_**|
|32 bits|0|9999 9999|Binary Coded Decimal|
|**_Special/Reserved Values_**|For each digit ;|||
||Values A – E|Spare||
||F|Use value F for digit to|indicate no digit (if number shorter than 8 digits)|
||FFFF FFFF|Unknown||

### 6.5.1.5.34.4 Table 7.5.1.107 (Q_EMERGENCYSTOP) shall be replaced with:

<!-- end of page 31 -->

|**_Name_**|Qualifier for emergen|cy stop acknowledgement|
|---|---|---|
|**_Description_**|Qualifier to indicate w|hether the train has accepted or not a conditional emergency stop.|
||For an unconditional e|mergency stop, it is set to “not relevant”|
|**_Length of variable_**|**_Minimum Value_**|**_Maximum Value_**<br>**_Resolution/formula_**|
|2 bits|||
|**_Special/Reserved Values_**|0|Conditional Emergency Stop accepted|
||1|Conditional Emergency Stop rejected|
||2|Not Relevant (Unconditional Emergency Stop)|
||3|Spare|

### 6.5.1.5.35 Table 7.5.1.138 (Q_TEXTCONFIRM) shall be replaced with:

|**_Name_**|Qualifies the need / re|action of text confirmation|
|---|---|---|
|**_Description_**|||
|**_Length of variable_**|**_Minimum Value_**|**_Maximum Value_**<br>**_Resolution/formula_**|
|2 bits|||
|**_Special/Reserved Values_**|00|No confirmation required|
||01|Continue display until confirmed|
||10|Apply service brake if not confirmed when end conditions reached|
||11|Spare|

### 6.5.1.5.35.1 Added section 7.5.1.140.1 (Q_TRACKDEL) shall apply:

|**_Name_**|Track description dele|ted.||
|---|---|---|---|
|**_Description_**|Qualifier to indicate wh|ether the onboard has de|leted (for any reason) track description or not.|
|**_Length of variable_**|**_Minimum Value_**|**_Maximum Value_**|**_Resolution/formula_**|
|1 bit||||
|**_Special/Reserved Values_**|0|No track description|deleted|
||1|Track description de|leted|

### 6.5.1.5.35.2 Table 7.5.1.172 (V_TRAIN) shall be replaced with:

|**_Name_**|Train speed|||
|---|---|---|---|
|**_Description_**||||
|**_Length of variable_**|**_Minimum Value_**|**_Maximum Value_**|**_Resolution/formula_**|
|7 bits|0 km/h|600 km/h|5 km/h|
|**_Special/Reserved Values_**|121-127|Spare||

6.5.1.5.36 Note: the packets listed above, which are not allowed for use in balise telegrams/loop messages marked with system version number X = 1 or in messages from RBC/RIU operating with system version number X = 1, may contain variables that have been introduced in the system version number X = 2 or 3. These variables are not mentioned in this section, since their use is implicitly forbidden by the fact that the packets using them are not allowed.

<!-- end of page 32 -->

### **6.5.1.6 Exceptions to chapter 8**

6.5.1.6.1 Clause 8.4.1.4.5 shall not apply.

6.5.1.6.2 Clause 8.4.1.4.8 shall be replaced with “Exception 8: A message transmitted by a balise group can contain several packets 200 (Virtual Balise Cover marker).”

6.5.1.6.3 The table under clause 8.4.2.1 shall be replaced with:

##### **General Format of Balise Telegram**

|Field No.|VARIABLE|Length ( bits)|Remarks|
|---|---|---|---|
|1|Q_UPDOWN|1|Defines the direction of the information:<br>Down-link telegram (train to track) (0)<br>Up-link telegram (track to train) (1)|
|2|M_VERSION|7|Version of the ERTMS/ETCS system.|
|3|Q_MEDIA|1|Defines the type of media: Balise (0)|
|4|N_PIG|3|Position in the group. Defines the position of the balise in the<br>balise group.|
|5|N_TOTAL|3|Total number of balises in the balise group|
|6|M_DUP|2|Used to indicate whether the information of the balise is a<br>duplicate of the balise before or after this one.|
|7|M_MCOUNT|8|Message counter (M_MCOUNT) - 8 bits. To enable detection<br>of a change of balise group message during passage of the<br>balise group.|
|8|NID_C|10|Country or region.|
|9|NID_BG|14|Identity of the balise group.|
|10|Q_LINK|1|Marks the balise group as linked (Q_LINK = 1) or unlinked<br>(Q_LINK = 0)|
||Packet 200<br>(optional)|29|Virtual Balise Cover marker|
||Information|Variable|This information is composed according to the rules applicable<br>for packets.|
||Packet 255|8|Finishing flag of the telegram|

6.5.1.6.4 Clause 8.4.2.3 shall be replaced with “When used, the packet 200 shall be transmitted as the first packet of the telegram (i.e. it is appended to the header).”

6.5.1.6.5 The table under clause 8.4.4.4.1 shall be replaced with:

|**Track to Train message**|**Mess. ID**|**Optional packets**|
|---|---|---|
|SR Authorisation|2|63|
|Movement Authority|3|21, 27, 49, 80, plus common optional packets|
|Request To Shorten MA|9|80|
|General Message|24|From RBC: 21, 27, plus common optional<br>packets|
|||From RIU: 45, 254|
|SH authorised|28|49, plus common optional packets|

<!-- end of page 33 -->

|MA with Shifted Location Reference|33|21, 27, 80, plus common optional packets|
|---|---|---|
|Infill MA|37|5, 21, 27, 39, 41, 44, 51, 65, 68, 70, 71, 80, 138,<br>139, 206, 207, 239|

### 6.5.1.6.6 The table under clause 8.4.4.4.1.1 shall be replaced with:

### **Common optional packets**

3, 5, 39, 51, 41, 42, 44, 45, 57, 58, 65, 66, 68, 70, 71, 72, 79, 131, 138, 139, 140, 203, 206, 207, 239

6.5.1.6.6.1 Clause 8.4.4.4.2 shall be replaced with: “The train to track message 136 (Train Position Report) and 157 (SoM Position Report) may optionally include the following packets:

   - a) Packet 4 (Error Reporting),

   - b) Packet 44 (Data used by applications outside the ERTMS/ETCS system).”

6.5.1.6.6.1.1 Clause 8.4.4.4.3 shall not apply.

6.5.1.6.6.2 Table 8.5.2 shall be replaced with:

|**Mes. Id.**|**Message Name**|**Invariant**|**Transmitted to**|
|---|---|---|---|
|129|Validated Train Data|No|RBC|
|130|Request for Shunting|No|RBC|
|132|MA Request|No|RBC|
|136|Train Position Report|No|RBC, RIU|
|137|Request to shorten MA is granted|No|RBC|
|138|Request to shorten MA is rejected|No|RBC|
|146|Acknowledgement|No|RBC, RIU|
|147|Acknowledgement of Emergency Stop|No|RBC|
|149|Track Ahead Free Granted|No|RBC|
|150|End of Mission|No|RBC|
|153|Radio infill request|No|RIU|
|154|No compatible version supported|Yes|RBC, RIU|
|155|Initiation of a communication session|Yes|RBC, RIU|
|156|Termination of a communication session|Yes|RBC, RIU|
|157|SoM Position Report|No|RBC|
|159|Session Established|No|RBC, RIU|

### 6.5.1.6.6.2.1 Table 8.5.3 shall be replaced with:

|**Mes. Id.**|**Message Name**|**Invariant**|**Transmitted by**|
|---|---|---|---|
|2|SR Authorisation|No|RBC|

<!-- end of page 34 -->

|**Mes. Id.**|**Message Name**|**Invariant**|**Transmitted by**|
|---|---|---|---|
|3|Movement Authority|No|RBC|
|6|Recognition of exit from TRIP mode|No|RBC|
|8|Acknowledgement of Train Data|No|RBC|
|9|Request to Shorten MA|No|RBC|
|15|Conditional Emergency Stop|No|RBC|
|16|Unconditional Emergency Stop|No|RBC|
|18|Revocation of Emergency Stop|No|RBC|
|24|General message|No|RBC, RIU|
|27|SH Refused|No|RBC|
|28|SH Authorised|No|RBC|
|33|MA with Shifted Location Reference|No|RBC|
|34|Track Ahead Free Request|No|RBC|
|37|Infill MA|No|RIU|
|40|Train Rejected|No|RBC|
|32|RBC/RIU System Version|Yes|RBC, RIU|
|39|Acknowledgement<br>of<br>termination<br>of<br>a<br>communication session|Yes|RBC, RIU|
|41|Train Accepted|No|RBC|
|43|SoM position report confirmed by RBC|No|RBC|
|45|Assignment of coordinate system|No|RBC|

6.5.1.6.6.2.2 Section 8.6.2.1 (Message 131: Request for Supervised Manoeuvre) shall not apply.

6.5.1.6.6.3 Table 8.6.3 (Message 132: MA Request) shall be replaced with:

<!-- Start of picture text -->
Field  VARIABLE/  Remarks<br>No.  PACKET<br>1  NID_MESSAGE<br>2  L_MESSAGE<br>3  T_TRAIN<br>4  NID_ENGINE<br>5  Q_TRACKDEL<br>6  Packet 0 or 1<br>7  Optional packets<br><!-- End of picture text -->

6.5.1.6.6.3.1 Section 8.6.3.1 (Message 133: Safe consist length information for Supervised Manoeuvre) shall not apply.

6.5.1.6.6.3.2 Table 8.6.10 (Message 150 End of Mission) shall be replaced with:

<!-- end of page 35 -->

<!-- Start of picture text -->
Field  VARIABLE/  Remarks<br>No.  PACKET<br>1  NID_MESSAGE<br>2  L_MESSAGE<br>3  T_TRAIN<br>4  NID_ENGINE<br>5  Packet 0 or 1<br><!-- End of picture text -->

6.5.1.6.6.4 Section 8.6.16 (Message 158: Text Message Acknowledged by Driver) shall not apply.

6.5.1.6.6.5 Table 8.6.17 (Message 159: Session established) shall be replaced with:

<!-- Start of picture text -->
Field  VARIABLE/  Remarks<br>No.  PACKET<br>1  NID_MESSAGE<br>2  L_MESSAGE<br>3  T_TRAIN<br>4  NID_ENGINE<br>5  Packet 3<br><!-- End of picture text -->

6.5.1.6.6.6 Section 8.7.2.1 (Message 4: SM Authorisation) shall not apply.

6.5.1.6.6.7 Section 8.7.2.2 (Message 5: SM Refused) shall not apply.

6.5.1.6.6.8 Section 8.7.3.1 (Message 7: Acknowledgement of safe consist length info for SM) shall not apply.

6.5.1.6.7 Table 8.7.6 (Message 15: Conditional Emergency Stop) shall be replaced with:

<!-- Start of picture text -->
Field  VARIABLE  Remarks<br>No.<br>1  NID_MESSAGE<br>2  L_MESSAGE<br>3  T_TRAIN<br>4  M_ACK<br>5  NID_LRBG<br>6  NID_EM  Identification Number of the Emergency Stop Message.<br>7  Q_SCALE<br>8  Q_DIR<br>9  D_EMERGENCYSTOP  Distance between LRBG and the position reference to the emergency stop.<br><!-- End of picture text -->

### 6.5.1.6.8 Table 8.7.14 (Message 34: Track Ahead Free Request) shall be replaced with:

<!-- end of page 36 -->

Field VARIABLE Remarks No.

- 1 NID_MESSAGE 2 L_MESSAGE 3 T_TRAIN 4 M_ACK 5 NID_LRBG 6 Q_SCALE 7 Q_DIR 8 D_TAFDISPLAY 9 L_TAFDISPLAY

6.5.1.6.9 Section 8.7.16 (Message 38: Acknowledgement of session establishment) shall not apply.

6.5.1.6.10 Note: Packets or variables that have been introduced in the system version number X = 2 or 3, which cannot be contained within messages transmitted to an RBC operating with system version number X = 1, are not mentioned in the section 6.5.1.5.

### **6.5.1.7 Additional requirements**

6.5.1.7.1 Any balise telegram, which includes the packet 2, the packet 6, the packet 135, the packet 145, the packet 200, the packet 203, the packet 206, the packet 207 or the packet 239, shall be marked with the system version number 1.1.

6.5.1.7.2 An RBC that uses the packet 203, the packet 206, the packet 207 or the packet 239 shall transmit a system version number equal to 1.1, when negotiating the establishment of the communication session.

6.5.1.7.3 Any message transmitted by loop, which includes the packet 206, the packet 207 or the packet 239, shall be marked with the system version number 1.1.

6.5.1.7.4 An RIU that uses the packet 206, the packet 207 or the packet 239 shall transmit a system version number equal to 1.1, when negotiating the establishment of the communication session.

6.5.1.7.5 A balise group or RBC message including the packet 203 shall also include the packet 3 (i.e. in a message, the packet 203 cannot be transmitted without the packet 3).

6.5.1.7.6 In the packet 70, the use of the value “00” of the variable Q_SUITABILITY shall be forbidden.

**6.5.2 Trackside areas operated with system version number X = 2**

**6.5.2.1 General**

<!-- end of page 37 -->

6.5.2.1.1 This section is applicable for trackside infrastructures that will be tendered and still operated with the system version number X = 2, after the entry into force of this release of the SRS.

6.5.2.1.1.1 Intentionally deleted.

6.5.2.1.2 Within a trackside infrastructure operated with the system version number X = 2, it shall be allowed to use the following values of M_VERSION: 1.0, 1.1, 2.0, 2.1, 2.2 and 2.3.

6.5.2.1.3 Within a trackside area operated with an RBC certified to the system version number X = 2, it shall also be allowed to use for balises the following value of M_VERSION: 3.0.

6.5.2.1.3.1 Note: this configuration is meaningful in case the trains operating on this RBC area support the system version number X = 3 and the on-board requirements related to the trackside information marked with 3.0 are applicable regardless of the operated version (i.e. they are applied by the on-board equipment even if this latter operates with the system version number X = 2 ordered by RBC).

### **6.5.2.2 Exceptions to chapters 3, 4, 5**

6.5.2.2.1 For RBCs certified to the system version number 2.0 and for RBCs certified to the system version number 2.1, 2.2 or 2.3 handing over a train fitted with an on-board equipment whose highest supported system version number X.Y is only 2.0, the bullet “The system versions supported by the on-board equipment” in clause 3.15.1.2.1 b) shall not apply.

6.5.2.2.2 For RBCs certified to the system version number 2.0, 2.1 or 2.2, for RIUs certified to a system version number lower than 2.3 and for RBCs/RIUs certified to the system version number 2.3 in communication with an on-board equipment whose highest supported system version number X.Y is only 2.0, 2.1 or 2.2, the clauses 6.5.1.2.1.4 and 6.5.1.2.1.5 shall apply.

6.5.2.2.3 For RBCs certified to the system version number 2.0, 2.1, 2.2, and for RBCs certified to the system version number 2.3 in communication with an on-board equipment whose highest supported system version number X.Y is only 2.0, 2.1 or 2.2, the clauses 6.5.1.4.1 and 6.5.1.4.2 shall apply.

6.5.2.2.4 For balise telegrams marked with the system version number 2.0, 2.1, 2.2 and for RBCs certified to the system version number 2.0, 2.1 or 2.2, the clauses 6.5.1.2.1.2&3 shall apply.

6.5.2.2.5 For balise telegrams marked with the system version number 2.0, 2.1, 2.2 and for RBCs/RIUs certified to the system version number 2.0, 2.1 or 2.2, the clause 6.5.1.2.1.6 shall apply.

**6.5.2.3 Exceptions to chapters 7, 8**

6.5.2.3.1 For the balise telegrams/loop messages marked with the system version number 1.0 or 1.1 and for messages transmitted by RIUs certified to the system version number 1.0 or 1.1, the exceptions listed in sections 6.5.1.5, 6.5.1.6 and 6.5.1.7 shall apply by analogy.

<!-- end of page 38 -->

6.5.2.3.1.1 For the balise telegrams/loop messages marked with the system version number 2.0 or 2.1 and for messages transmitted by RBCs certified to the system version number 2.0 or 2.1, the following exceptions shall apply:

6.5.2.3.1.1.1 The Table 7.4.1.1 shall be replaced with:

|Packet<br>|Packet Name|Page N°|
|---|---|---|
|Number|||
|0|Virtual Balise Cover marker||
|2|System Version order||
|3|National Values||
|5|Linking||
|6|Virtual Balise Cover order||
|12|Level 1 Movement Authority||
|13|Staff Responsible distance information from loop||
|15|Level 2 Movement Authority||
|16|Repositioning Information||
|21|Gradient Profile||
|27|International Static Speed Profile||
|39|Track Condition Change of traction system||
|40|Track Condition Change of allowed current consumption||
|41|Level Transition Order||
|42|Session Management||
|44|Data used by applications outside the ERTMS/ETCS system.||
|45|Radio Network registration||
|46|Conditional Level Transition Order||
|49|List of Balise Groups for SH Area||
|51|Axle load Speed Profile||
|52|Permitted Braking Distance Information||
|57|Movement Authority Request Parameters||
|58|Position Report Parameters||
|63|List of Balise Groups in SR Authority||
|64|Inhibition of revocable TSRs from balises in level 2||
|65|Temporary Speed Restriction||
|66|Temporary Speed Restriction Revocation||
|67|Track Condition Big Metal Masses||
|68|Track Condition||
|69|Track Condition Station Platforms||
|70|Route Suitability Data||
|71|Adhesion Factor||
|72|Packet for sending plain text messages||
|76|Packet for sending fixed text messages||
|79|Geographical Position Information||
|80|Mode profile||
|88|Level crossing information||
|90|Track Ahead Free up to level 2 transition location||
|131|RBC transition order||
|132|Danger for Shunting information||

<!-- end of page 39 -->

|Packet<br>Number|Packet Name|Page N°|
|---|---|---|
|133|Radio infill area information||
|134|EOLM Packet||
|135|Stop Shunting on desk opening||
|136|Infill location reference||
|137|Stop if in Staff Responsible||
|138|Reversing area information||
|139|Reversing supervision information||
|140|Train running number from RBC||
|141|Default Gradient for Temporary Speed Restriction||
|143|Session Management with neighbouring Radio Infill Unit||
|145|Inhibition of balise group message consistency reaction||
|180|LSSMA display toggle order||
|181|Generic LS function marker||
|254|Default balise, loop or RIU information||
|255|End of Information||

6.5.2.3.1.1.2 In section 7.4.2.23, "Packet Number 73" shall be replaced with "Packet Number 72"

6.5.2.3.1.1.3 In section 7.4.2.24, "Packet Number 74" shall be replaced with "Packet Number 76"

6.5.2.3.1.1.4 The Table 7.5.1.73 (M_MODETEXTDISPLAY) shall be replaced with:

|Name|On-board operating m|ode for text display||
|---|---|---|---|
|Description|The display of the te<br>transition from the def|xt starts if the on-board is in<br>ined mode|the defined mode/ends if the on-board executes a|
|Length of variable|Minimum Value|Maximum Value|Resolution/formula|
|4 bits||||
|Special/Reserved Values|0|Full Supervision||
||1|On Sight||
||2|Staff Responsible||
||3|Spare||
||4|Unfitted||
||5|Spare||
||6|Stand By||
||7|Trip||
||8|Post Trip||
||9|Spare||
||10|Spare||
||11|Spare||
||12|Limited Supervision||
||13|Spare||
||14|Reversing||
||15|No “mode” sub-conditio<br>the text|n specified for the start/end condition of the display of|

<!-- end of page 40 -->

6.5.2.3.1.2 For messages transmitted by RBCs certified to the system version number 2.0 or 2.1, the following exception shall apply:

6.5.2.3.1.2.1 The Table under clause 8.4.4.4.1.1 shall be replaced with:

### **Common optional packets**

3, 5, 39, 40, 51, 41, 42, 44, 45, 52, 57, 58, 64, 65, 66, 68, 69, 70, 71, 72, 76, 79, 88, 131, 138, 139, 140, 180

6.5.2.3.2 For RBCs/RIUs certified to the system version number 2.0, the following exceptions shall apply:

6.5.2.3.2.1 The table 7.4.1.2 shall be replaced with:

|Packet<br>Number|Packet Name|Page N°|
|---|---|---|
|0|Position Report||
|1|Position Report based on two balise groups||
|3|On-board telephone numbers||
|4|Error Reporting||
|5|Train running number||
|9|Level 2 transition information||
|11|Validated train data||
|44|Data used by applications outside the ERTMS/ETCS system.||

6.5.2.3.2.2 The clauses 6.5.1.5.25.3 and 6.5.1.6.6.5 shall apply.

6.5.2.3.2.3 The clauses 6.5.1.5.25.1&2 shall apply.

6.5.2.3.2.4 The Table 7.5.1.72 (M_MODE) shall be replaced with:

|**_Name_**<br>On-board operating m|ode||
|---|---|---|
|**_Description_**|||
|**_Length of variable_**<br>**_Minimum Value_**|**_Maximum Value_**|**_Resolution/formula_**|
|4 bits|||
|**_Special/Reserved Values_**<br>0|Full Supervision||
|1|On Sight||
|2|Staff Responsible||
|3|Shunting||
|4|Unfitted||
|5|Sleeping||
|6|Stand By||
|7|Trip||
|8|Post Trip||
|9|System Failure||
|10|Isolation||

<!-- end of page 41 -->

|11|Non Leading|
|---|---|
|12|Limited Supervision|
|13|National System|
|14|Reversing|
|15|Passive Shunting|

6.5.2.3.3 For RBCs/RIUs certified to the system version number 2.1, and for RBCs/RIUs certified to the system version number 2.2 or 2.3 in communication with an on-board equipment whose highest supported system version number X.Y is only 2.0 or 2.1, the following exceptions shall apply:

### 6.5.2.3.3.1 The table 7.4.1.2 shall be replaced with:

|Packet<br>Number|Packet Name|Page N°|
|---|---|---|
|0|Position Report||
|1|Position Report based on two balise groups||
|2|On-board supported system versions||
|3|On-board telephone numbers {1}||
|4|Error Reporting||
|5|Train running number||
|9|Level 2 transition information||
|11|Validated train data||
|44|Data used by applications outside the ERTMS/ETCS system.||

{1}Note: used by on-board equipment whose highest supported system version = 2.0.

### 6.5.2.3.3.2 The clause 6.5.1.5.25.3 shall apply.

6.5.2.3.3.3 The table 8.6.17 (Message 159: Session established) shall be replaced with:

<!-- Start of picture text -->
Field  VARIABLE/  Remarks<br>No.  PACKET<br>1  NID_MESSAGE<br>2  L_MESSAGE<br>3  T_TRAIN<br>4  NID_ENGINE<br>5  Packet 2 or 3<br><!-- End of picture text -->

6.5.2.3.3.4 The clauses 6.5.2.3.2.3&4 shall apply.

6.5.2.3.4 For RBCs certified to the system version number 2.2 or 2.3 in communication with an on-board equipment whose highest supported system version number X.Y is only 2.0 or 2.1, the following exception shall apply:

6.5.2.3.4.1 The clauses 6.5.2.3.1.1.1, 2, 3&4 and 6.5.2.3.1.2.1 shall apply.

6.5.2.3.5 For RBCs certified to the system version number 2.0 or 2.1, and for RBCs certified to the system version number 2.2 or 2.3 in communication with an on-board equipment whose

<!-- end of page 42 -->

highest supported system version number X.Y is only 2.0 or 2.1, the following exceptions shall apply:

### 6.5.2.3.5.1 Table 7.5.1.64 (M_ERROR) shall be replaced with:

|**_Name_**|Identifier of the type of|error|
|---|---|---|
|**_Description_**|||
|**_Length of variable_**|**_Minimum Value_**|**_Maximum Value_**<br>**_Resolution/formula_**|
|8 bits|||
|**_Special/Reserved Values_**|0|Balise group: linking consistency error (ref. 3.16.2.3)|
||1|Linked balise group: message consistency error (ref. 3.16.2.4.1/4)|
||2|Unlinked balise group: message consistency error (ref. 3.16.2.5)|
||3|Radio: message consistency error (ref. 3.16.3.1.1 except 3.16.3.1.1 b)|
||4|Radio: sequence error (ref. 3.16.3.1.1b)|
||5|Radio: safe radio connection error (ref. 3.16.3.4, to be sent when<br>communication links re-established)|
||6|Safety critical fault (ref 4.4.6.1.6 , 4.4.15.1.5)|
||7|Double linking error (3.16.2.7.1)|
||8|Double repositioning error (3.16.2.7.2)|
||9-255|Spare|

6.5.2.3.5.2 Clause 8.4.4.4.3 shall be replaced with: “The train to track message 157 (SoM Position Report) may optionally include the following packets:

   - a) Packet 4 (Error Reporting, see section 3.16.4),

   - b) Packet 5 (Train running number, see section 5.4.3.2 A33&A34),

   - c) Packet 44 (Data used by applications outside the ERTMS/ETCS system).”

6.5.2.3.6 For RBCs certified to the system version number 2.2, and for RBCs certified to the system version number 2.3 in communication with an on-board equipment whose highest supported system version number X.Y is only 2.2, the following exceptions shall apply:

### 6.5.2.3.6.1 Table 7.5.1.72 (M_MODE) shall be replaced with:

|Name|Onboard operating m|ode||
|---|---|---|---|
|Description||||
|Length of variable|Minimum Value|Maximum Value|Resolution/formula|
|5 bits||||
|Special/Reserved Values|0|Full Supervision||
||1|On Sight||
||2|Staff Responsible||
||3|Shunting||
||4|Unfitted||
||5|Sleeping||

<!-- end of page 43 -->

|6|Stand By|
|---|---|
|7|Trip|
|8|Post Trip|
|9|System Failure|
|10|Isolation|
|11|Non Leading|
|12|Limited Supervision|
|13|National System|
|14|Reversing|
|15|Passive Shunting|
|16|Automatic Driving|
|17-31|Spare|

### 6.5.2.3.6.2 Table 7.5.1.73 (M_MODETEXTDISPLAY) shall be replaced with:

|Name|Onboard operating m|ode for text display||
|---|---|---|---|
|Description<br>|The display of the te<br>transition from the de<br>|xt starts if the on-board is in<br>fined mode<br>|the defined mode/ends if the on-board executes a<br>|
|Length of variable|Minimum Value|Maximum Value|Resolution/formula|
|4 bits||||
|Special/Reserved Values|0|Full Supervision||
||1|On Sight||
||2|Staff Responsible||
||3|Automatic Driving||
||4|Unfitted||
||5|Spare||
||6|Stand By||
||7|Trip||
||8|Post Trip||
||9|Spare||
||10|Spare||
||11|Spare||
||12|Limited Supervision||
||13|Spare||
||14|Reversing||
||15|No “mode” sub-conditio<br>the text|n specified for the start/end condition of the display of|

6.5.2.3.6.3 Clause 8.4.4.4.3 shall be replaced with: “The train to track message 157 (SoM Position Report) may optionally include the following packets:

a) Packet 4 (Error Reporting, see section 3.16.4),

<!-- end of page 44 -->

- b) Packet 5 (Train running number, see section 5.4.3.2 A33&A34),

- c) Packet 11 (Train Data, see section 5.4.3.2 A33&A34),

d) Packet 44 (Data used by applications outside the ERTMS/ETCS system).”

6.5.2.3.7 For RBCs certified to the system version number 2.0, 2.1 or 2.2, and for RBCs certified to the system version number 2.3 in communication with an on-board equipment whose highest supported system version number X.Y is only 2.0, 2.1 or 2.2, the following exceptions shall apply:

6.5.2.3.7.1 Clauses 6.5.1.6.6.2.2, 6.5.1.6.6.3.1, 6.5.1.6.6.6, 7 & 8 shall apply.

6.5.2.3.7.2 Clause 6.5.1.6.6.3.2 shall apply.

6.5.2.3.8 For RBCs/RIUs certified to the system version number 2.0, 2.1 or 2.2, and for RBCs/RIUs certified to the system version number 2.3 in communication with an on-board equipment whose highest supported system version number X.Y is only 2.0, 2.1 or 2.2, the following exceptions shall apply:

6.5.2.3.8.1 Clauses 6.5.1.6.6.2.1 and 6.5.1.6.9 shall apply.

6.5.2.3.8.2 Clause 6.5.1.5.35.2 shall apply.

6.5.2.3.9 For RBCs certified to the system version number 2.0, 2.1, 2.2 or 2.3, the following exceptions shall apply:

6.5.2.3.9.1 Clauses 6.5.1.2.16 & 6.5.1.5.12.1 shall apply.

6.5.2.3.9.2 Clauses 6.5.1.5.27.3, 4 & 5 shall apply.

6.5.2.3.10 For the balise telegrams/loop messages marked with the system version number 2.0, 2.1, 2.2 or 2.3, the following exception shall apply:

6.5.2.3.10.1 Clauses 6.5.1.5.27.4 & 5 shall apply.

6.5.2.3.11 For RIUs certified to the system version number 2.0, 2.1, 2.2 or 2.3, the following exception shall apply:

6.5.2.3.11.1 Clauses 6.5.1.5.27.3 & 5 shall apply.

6.5.2.3.12 For the balise telegrams/loop messages marked with the system version number 2.0, 2.1, 2.2 or 2.3 and for messages transmitted by RBCs/RIUs certified to the system version number 2.0, 2.1, 2.2 or 2.3, the following exceptions shall apply:

6.5.2.3.12.1 Table 7.4.2.13 (Packet Number 51: Axle Load Speed Profile) shall be replaced with:

|**_Description_**|This packet gives the speed restrictions for trains with axle load category higher|
|---|---|
||than or equal to the specified value for the speed restriction, assuming that the<br>axle load categories are sorted in ascending order from category A to E5|
|**_Transmitted by_**|Any|
|**_Content_**|**Variable**<br>**Length**<br>**Comment**|

<!-- end of page 45 -->

|NID_PACKET|8||
|---|---|---|
|Q_DIR|2||
|L_PACKET|13||
|Q_SCALE|2||
|Q_TRACKINIT|1||
|D_TRACKINIT|15|Only if Q_TRACKINIT = 1|
|D_AXLELOAD|15|Only<br>if<br>Q_TRACKINIT<br>=<br>0,<br>D_AXLELOAD and the following<br>variables follow|
|L_AXLELOAD|15||
|Q_FRONT|1||
|N_ITER|5||
|M_AXLELOADCAT(n)|7||
|V_AXLELOAD(n)|7|Speed restriction to be applied if the<br>axle load category of the train<br>M_AXLELOADCAT(n)|
|N_ITER|5||
|D_AXLELOAD(k)|15||
|L_AXLELOAD(k)|15||
|Q_FRONT(k)|1||
|N_ITER(k)|5||
|M_AXLELOADCAT(k,m)|7||
|V_AXLELOAD(k,m)|7|Speed restriction to be applied if the<br>axle load category of the train<br>M_AXLELOADCAT(k,m)|

### 6.5.2.3.12.2 Table 7.4.2.21 (Packet Number 70: Route Suitability Data) shall be replaced with:

|**_Description_**|The packet gives the characterist|ics needed to ent|er a route.|
|---|---|---|---|
|**_Transmitted by_**|Any|||
|**_Content_**|**Variable**|**Length**|**Comment**|
||NID_PACKET|8||
||Q_DIR|2||
||L_PACKET|13||
||Q_SCALE|2||
||Q_TRACKINIT|1||
||D_TRACKINIT|15|Only if Q_TRACKINIT = 1|
||D_SUITABILITY|15|Only If Q_TRACKINIT = 0,<br>D_SUITABILITY<br>and<br>the<br>following variables follows|

<!-- end of page 46 -->

|Q_SUITABILITY|2||
|---|---|---|
|M_LINEGAUGE|8|If Q_SUITABILITY = loading<br>gauge|
|M_AXLELOADCAT|7|If Q_SUITABILITY = axle load.<br>It gives the max axle load<br>category, assuming that the axle<br>load categories are sorted in<br>ascending order from category A<br>to E5.|
|M_VOLTAGE|4|If Q_SUITABILITY = traction<br>system|
|NID_CTRACTION|10|If Q_SUITABILITY = traction<br>system and M_VOLTAGE ≠ 0|
|N_ITER|5||
|D_SUITABILITY(k)|15||
|Q_SUITABILITY(k)|2||
|M_LINEGAUGE(k)|8|If Q_SUITABILITY(k) = loading<br>gauge|
|M_AXLELOADCAT(k)|7|If Q_SUITABILITY(k) = axle load.<br>It gives the max axle load<br>category, assuming that the axle<br>load categories are sorted in<br>ascending order from category A<br>to E5.|
|M_VOLTAGE(k)|4|If Q_SUITABILITY(k) = traction<br>system|
|NID_CTRACTION(k)|10|If Q_SUITABILITY(k) = traction<br>system and M_VOLTAGE(k) ≠0|

6.5.2.3.13 For balise telegrams marked with the system version number 2.0, 2.1, 2.2 or 2.3 and for messages transmitted by RBCs/RIUs certified to the system version number 2.0, 2.1, 2.2 or 2.3, the following exceptions shall apply:

6.5.2.3.13.1 Table 7.4.2.11.1 (Packet Number 45: Radio Network transition order) shall be replaced with:

|**_Description_**|Packet to give the identity|of the GSM-R Radio|Network.|
|---|---|---|---|
|**_Transmitted by_**|Balise, RBC, RIU|||
|**_Content_**|**Variable**|**Length**|**Comment**|
||NID_PACKET|8||
||Q_DIR|2||
||L_PACKET|13||

<!-- end of page 47 -->

|NID_MN|24|
|---|---|

6.5.2.3.14 For balise telegrams marked with the system version number 2.2 and for messages transmitted by RBC/RIUs certified to the system version number 2.2, the following exception shall apply:

### 6.5.2.3.14.1 The Table 7.4.1.1 shall be replaced with:

|Packet<br>|Packet Name|Page N°|
|---|---|---|
|Number|||
|0|Virtual Balise Cover marker||
|2|System Version order||
|3|National Values||
|5|Linking||
|6|Virtual Balise Cover order||
|12|Level 1 Movement Authority||
|13|Staff Responsible distance information from loop||
|15|Level 2 Movement Authority||
|16|Repositioning Information||
|21|Gradient Profile||
|27|International Static Speed Profile||
|39|Track Condition Change of traction system||
|40|Track Condition Change of allowed current consumption||
|41|Level Transition Order||
|42|Session Management||
|44|Data used by applications outside the ERTMS/ETCS system.||
|45|Radio Network registration||
|46|Conditional Level Transition Order||
|49|List of Balise Groups for SH Area||
|51|Axle load Speed Profile||
|52|Permitted Braking Distance Information||
|57|Movement Authority Request Parameters||
|58|Position Report Parameters||
|63|List of Balise Groups in SR Authority||
|64|Inhibition of revocable TSRs from balises in level 2||
|65|Temporary Speed Restriction||
|66|Temporary Speed Restriction Revocation||
|67|Track Condition Big Metal Masses||
|68|Track Condition||
|69|Track Condition Station Platforms||
|70|Route Suitability Data||
|71|Adhesion Factor||
|73|Packet for sending plain text messages||
|74|Packet for sending fixed text messages||
|79|Geographical Position Information||
|80|Mode profile||
|88|Level crossing information||
|90|Track Ahead Free up to level 2 transition location||

<!-- end of page 48 -->

|Packet<br>Number|Packet Name|Page N°|
|---|---|---|
|131|RBC transition order||
|132|Danger for Shunting information||
|133|Radio infill area information||
|134|EOLM Packet||
|135|Stop Shunting on desk opening||
|136|Infill location reference||
|137|Stop if in Staff Responsible||
|138|Reversing area information||
|139|Reversing supervision information||
|140|Train running number from RBC||
|141|Default Gradient for Temporary Speed Restriction||
|143|Session Management with neighbouring Radio Infill Unit||
|145|Inhibition of balise group message consistency reaction||
|180|LSSMA display toggle order||
|181|Generic LS function marker||
|254|Default balise, loop or RIU information||
|255|End of Information||

6.5.2.3.15 For RBCs certified to the system version number 2.2, the following exception shall apply:

### 6.5.2.3.15.1 The Table under clause 8.4.4.4.1.1 shall be replaced with:

### **Common optional packets**

3, 5, 39, 40, 51, 41, 42, 44, 45, 52, 57, 58, 64, 65, 66, 68, 69, 70, 71, 73, 74, 79, 88, 131, 138, 139, 140, 180

6.5.2.3.16 For balise telegrams marked with the system version number 2.3 and for messages transmitted by RBCs/RIUs certified to the system version number 2.3, the following exceptions shall apply:

### 6.5.2.3.16.1 The Table 7.4.1.1 shall be replaced with:

|Packet<br>Number|Packet Name|Page N°|
|---|---|---|
|0|Virtual Balise Cover marker||
|2|System Version order||
|3|National Values||
|5|Linking||
|6|Virtual Balise Cover order||
|12|Level 1 Movement Authority||
|13|Staff Responsible distance information from loop||
|15|Level 2 Movement Authority||
|16|Repositioning Information||
|21|Gradient Profile||
|27|International Static Speed Profile||
|31|RBC transition order for RBC interfaced to FRMCS only||
|32|Session management for RBC interfaced to FRMCS only||

<!-- end of page 49 -->

|Packet<br>|Packet Name|Page N°|
|---|---|---|
|Number|||
|39|Track Condition Change of traction system||
|40|Track Condition Change of allowed current consumption||
|41|Level Transition Order||
|42|Session Management for RBC interfaced to GSM-R||
|44|Data used by applications outside the ERTMS/ETCS system.||
|45|Radio Network registration||
|46|Conditional Level Transition Order||
|49|List of Balise Groups for SH Area||
|51|Axle load Speed Profile||
|52|Permitted Braking Distance Information||
|57|Movement Authority Request Parameters||
|58|Position Report Parameters||
|63|List of Balise Groups in SR Authority||
|64|Inhibition of revocable TSRs from balises in level 2||
|65|Temporary Speed Restriction||
|66|Temporary Speed Restriction Revocation||
|67|Track Condition Big Metal Masses||
|68|Track Condition||
|69|Track Condition Station Platforms||
|70|Route Suitability Data||
|71|Adhesion Factor||
|73|Packet for sending plain text messages||
|74|Packet for sending fixed text messages||
|79|Geographical Position Information||
|80|Mode profile||
|88|Level crossing information||
|90|Track Ahead Free up to level 2 transition location||
|131|RBC transition order for RBC interfaced to GSM-R||
|132|Danger for Shunting information||
|133|Radio infill area information||
|134|EOLM Packet||
|135|Stop Shunting on desk opening||
|136|Infill location reference||
|137|Stop if in Staff Responsible||
|138|Reversing area information||
|139|Reversing supervision information||
|140|Train running number from RBC||
|141|Default Gradient for Temporary Speed Restriction||
|143|Session Management with neighbouring Radio Infill Unit||
|145|Inhibition of balise group message consistency reaction||
|180|LSSMA display toggle order||
|181|Generic LS function marker||
|245|Radio Network type||
|254|Default balise, loop or RIU information||
|255|End of Information||

<!-- end of page 50 -->

6.5.2.3.16.2 Added section 7.4.2.37.5 (Packet Number 245: Radio Network type) shall apply: Packet Number 245: Radio Network type

|**_Description_**|Packet to give the Radio N|etwork type||
|---|---|---|---|
|**_Transmitted by_**|Balise, RBC, RIU|||
|**_Content_**|**Variable**|**Length**|**Comment**|
||NID_PACKET|8||
||Q_DIR|2||
||L_PACKET|13||
||Q_NETWORKTYPE|2||

6.5.2.3.17 For messages transmitted by RBCs/RIUs certified to the system version number 2.3, the following exception shall apply:

6.5.2.3.17.1 The table under clause 8.4.4.4.1 shall be replaced with:

|**Track to Train message**|**Mess. ID**|**Optional packets**|
|---|---|---|
|SR Authorisation|2|63|
|Movement Authority|3|21, 27, 49, 80, plus common optional packets|
|SM Authorisation|4|3, 5, 31, 39, 40, 44, 45, 51, 58, 64, 65, 66, 67,<br>68, 69, 71, 73, 74, 79, 88, 131, 140, 245|
|Request To Shorten MA|9|49, 80|
|General Message|24|From RBC: 21, 27, plus common optional<br>packets<br>From RIU: 44, 45, 143, 180, 245, 254|
|SH authorised|28|3, 44, 49|
|MA with Shifted Location Reference|33|21, 27, 49, 80, plus common optional packets|
|Infill MA|37|5, 21, 27, 39, 40, 41, 44, 49, 51, 52, 65, 68, 69,<br>70, 71, 80, 88, 138, 139|

6.5.2.3.18 For messages transmitted by RBCs certified to the system version number 2.3, the following exception shall apply:

6.5.2.3.18.1 The Table under clause 8.4.4.4.1.1 shall be replaced with:

### **Common optional packets**

3, 5, 31, 32, 39, 40, 51, 41, 42, 44, 45, 52, 57, 58, 64, 65, 66, 68, 69, 70, 71, 73, 74, 79, 88, 131, 138, 139, 140, 180, 245

6.5.2.3.19 Note: Packets or variables that have been introduced in a system version number X.Y (2.1, 2.2; 2.3 or 3.0), which cannot be contained within messages transmitted to an X = 2 RBC operating with a lower system version number than X.Y, are not mentioned in this section 6.5.2.3.

### **6.5.2.4 Additional requirements**

<!-- end of page 51 -->

6.5.2.4.1 Any balise telegram, which includes the packet 31, 32 or 245, shall be marked with the system version number 2.3.

6.5.2.4.2 An RBC that uses the packet 31 or 32 shall transmit a system version number equal to 2.3, when negotiating the establishment of the communication session.

6.5.2.4.3 An RBC/RIU that uses the packet 245 shall transmit a system version number equal to 2.3, when negotiating the establishment of the communication session.

6.5.2.4.4 Any balise group, RBC or RIU message including the packet 245 with its variable Q_NETWORKTYPE = 1 or 2 shall also include the packet 45.

6.5.2.4.5 Any balise group, RBC or RIU message including the packet 245 with its variable Q_NETWORKTYPE = 0 shall not include the packet 45.

## **6.5.3 Trackside areas operated with system version number X = 3**

**6.5.3.1 General**

6.5.3.1.1 This section is applicable for trackside infrastructures that were operated with the system version number X = 1 or 2, before the migration to the system version number X = 3.

6.5.3.1.2 Within a trackside infrastructure operated with the system version number X = 3, it shall be allowed to use the following values of M_VERSION: 1.0, 1.1, 2.0, 2.1, 2.2, 2.3 and 3.0.

**6.5.3.2 Exceptions to chapters 3, 4, 5**

6.5.3.2.1 For RIUs certified to a system version number lower than 2.3, the clauses 6.5.1.2.1.4 and 6.5.1.2.1.5 shall apply.

**6.5.3.3 Exceptions to chapters 7, 8**

6.5.3.3.1 For the balise telegrams/loop messages marked with the system version number 1.0 or 1.1 and for messages transmitted by RIUs certified to the system version number 1.0 or 1.1, the exceptions listed in sections 6.5.1.5, 6.5.1.6 and 6.5.1.7 shall apply by analogy.

6.5.3.3.2 For the balise telegrams/loop messages marked with the system version number 2.0, 2.1, 2.2 or 2.3 and for messages transmitted by RIUs certified to the system version number 2.0, 2.1, 2.2 or 2.3, the exceptions listed in section 6.5.2.2.4 shall apply by analogy.

6.5.3.3.3 For the balise telegrams marked with the system version number 2.3 and for messages transmitted by RIUs certified to the system version number 2.3, the exceptions listed in section 6.5.2.4 shall apply by analogy.

<!-- end of page 52 -->

# **6.6 On-board requirements in relation to older system versions**

## **6.6.1 Introduction**

- 6.6.1.1

- This section covers the following situations:

- a) Train is running on a trackside infrastructure operated with system version number X = 1 or 2

- b) Train is running on a trackside infrastructure operated with system version number X = 3, but still transmitting some balise/loop/RIU information related to system version number X = 1 or 2 (see section 6.5.3)

- c) Train is running on a trackside infrastructure operated with system version number X = 3, but on-board equipment has established a communication session with a neighbouring RBC certified to system version number X = 1 or 2

## **6.6.2 Specific requirements for on-board operating with system version number X = 1**

**6.6.2.1 Exceptions to chapter 3**

6.6.2.1.1 Clause 3.12.3.4.7.2 shall be replaced with: “If the driver acknowledges before the end condition is fulfilled, the on-board equipment shall consider the driver acknowledgement as always ending the text display, regardless of the end condition defined in 3.12.3.4.3.1”.

6.6.2.1.2 Clause 3.6.1.3.4 shall be replaced with “The front end of the train refers to the front end of the engine with regards to the train orientation.”

6.6.2.1.3 If the ERTMS/ETCS on-board equipment is in mode FS or OS, the row “Temporary Speed Restriction” in section 3.6.4.2 table 2a shall be replaced with:

|**Information**|**Location**|**"min" location**<br>**item**|**"estimated"**<br>**location item**|**"max" location**<br>**item**|
|---|---|---|---|---|
|Temporary Speed Restriction|area start (***)||3.13.7.2 together with<br>3.11.2.2 c),<br>3.13.2.3.2.1 (start of<br>speed element for<br>MRSP)<br>Other clauses in row<br>EBD based target||
||area end (*)||3.13.7.2 together with<br>3.11.2.2 c) &<br>3.13.2.3.2.1 (end of<br>speed element for<br>MRSP)<br>3.15.10.2||

6.6.2.1.4 Clause 3.11.4.3 shall be replaced with: “The ERTMS/ETCS on-board equipment shall consider the most restrictive speed restriction that is associated with any axle load

<!-- end of page 53 -->

category lower than, or equal to that of the train assuming that the axle load categories are sorted in ascending order from category A to E5.”

**6.6.2.2 Exceptions to chapter 4**

6.6.2.2.1 Clause 4.4.11.1.3 d) shall be replaced with: “balise groups giving the order ‘stop if in SR’. This order shall immediately trip the train.”

6.6.2.2.2 Condition [54] in table 4.6.3 shall be replaced with: “(reception of information “stop if in Staff Responsible”) AND (override is not active)”.

6.6.2.2.3 Clause 4.4.7.1.6 b) shall not apply.

6.6.2.2.4 Added clause 4.4.9.1.8 shall apply: “The sub-condition "Mode = FS" used in the end condition of indication of text messages shall be considered as fulfilled if and only if a transition from FS to another mode than AD is executed”.

6.6.2.2.5 Added clause 4.4.16.1.7 shall apply: “The sub-condition "Mode = FS" used in the start condition of indication of text messages shall be evaluated as if the ERTMS/ETCS onboard equipment was in Full Supervision mode”.

6.6.2.2.6 Added clause 4.4.16.1.8 shall apply: “The sub-condition "Mode = FS" used in the end condition of indication of text messages shall be considered as fulfilled if and only if a transition from AD to another mode than FS is executed”.

### **6.6.2.3 Exceptions to chapter 5**

6.6.2.3.1 Requirement S10 in table 5.4.3.2 shall be replaced with:

**S10** The ERTMS/ETCS on-board equipment shall offer the possibility to the driver to select SH, NL, or to select Train Data Entry.

   - If the driver selects SH ( **E12** ), the process shall continue in the same way as the procedure “Shunting initiated by the driver”. If, in level 2, the RBC rejects the request for Shunting ( **E13** ), the process shall go back to **S10** .

   - If the driver selects NL ( **E10** ) then the ERTMS/ETCS on-board equipment shall immediately switch to Non Leading mode (refer to SRS chapter 4, transition between modes: transition [46]). The mission starts in NL mode (if level is 2, the ERTMS/ETCS on-board equipment also reports the change of mode to the RBC).

   - If the driver selects Train Data Entry ( **E11** ), the process shall go to **S12** .

   - Following **E10** , **E12** , if the position is still invalid, the ERTMS/ETCS on-board shall delete the train position data (new status: “unknown”).

6.6.2.3.2 Clause 5.4.5.3 k) shall not apply.

6.6.2.3.3 Clause 5.5.3.1.3 shall be replaced with: “If a communication session with an RBC exists: Step 2 - The end of mission shall be reported to the RBC by means of the message “End of Mission”.

Step 3 - The RBC shall request to terminate the communication session.

<!-- end of page 54 -->

- Step 4 - The ERTMS/ETCS on-board equipment shall terminate the communication session

End of procedure”

6.6.2.3.4 Clause 5.5.3.1.4 shall not apply.

6.6.2.3.5 Clause 5.5.4.1.1 shall be replaced with: “Level 2: In case a communication session is established and no request to terminate the communication session is received from the RBC within a fixed waiting time (see appendix to chapter 3, List of Fixed Value Data) after sending the “End of Mission” message, the message shall be repeated with the fixed waiting time after each repetition.”

### 6.6.2.3.6 Requirement S140 in table 5.11.2.2 shall be replaced with:

- S140 The ERTMS/ETCS on-board equipment shall offer the possibility to the driver to select "start" (only if train data has been previously entered), or to select SH

   - a) If the driver selects "start" and the level is 1 ( **E150** ), the process shall go to **S160**

   - b) If the driver selects "start" and the level is 2 or 3 ( **E155** ), the process shall go to **S150**

   - c) If the driver selects SH ( **E145** ), the process shall continue in the same ways as the procedure “Shunting initiated by the driver”. If the SH request is refused by the RBC ( **E165** ) the process shall return to **S140** .

6.6.2.3.7 Section 5.21 shall not apply.

### **6.6.2.4 Exceptions to chapters 7, 8**

6.6.2.4.1 Void

## **6.6.3 Handling of air gap data related to system version number X = 1**

**6.6.3.1 General**

6.6.3.1.1 For information received from trackside, the message consistency check shall be achieved taking into account the exceptions to chapters 7 and 8, as described in sections 6.5.1.5,  6.5.1.6 and 6.5.1.7.

6.6.3.1.1.1 Exception: The on-board equipment shall not consider the reception of a packet 76 as a message data consistency error (i.e. use of spare value for NID_PACKET) and shall ignore its content.

6.6.3.1.2 For information received from trackside, the ERTMS/ETCS on-board equipment shall use the translation tables defined here below, in order to use the information as if it had been elaborated in compliance with the current chapters 7 and 8.

**6.6.3.2 Packets received from balise, loop, RIU, RBC**

<!-- end of page 55 -->

6.6.3.2.1 In the table below, the translation of information may depend on the on-board operated system version at the time the information is received and accepted on-board.

6.6.3.2.2 When a level transition or an RBC/RBC handover is announced, the information stored on-board in the transition buffer shall be translated according to system version operated on-board at the time the information is released from the transition buffer (i.e. the system version operated by the trackside infrastructure, towards which the train is running).

6.6.3.2.3 Depending on the packet, the action can be:

   - a) data is unchanged,

   - b) data is rejected,

   - c) data is translated,

   - d) not relevant

R = Rejected T = Translated U = Unchanged NR = Not relevant

||**Received information**|**A**|**ction**|
|---|---|---|---|
|Packet<br>Number|Packet Name|Operated<br>system version<br>number X = 1|Operated system<br>version number X<br>= 2 or 3|
|2|System Version Order|U|U|
|3|National Values|T [1a] [2]|T [1b] [2]|
|5|Linking|U|U|
|6|Virtual Balise Cover order|U|U|
|12|Level 1 Movement Authority|U|U|
|15|Level 2 Movement Authority|U|U|
|16|Repositioning Information|U|U|
|21|Gradient Profile|U|U|
|27|International Static Speed Profile|U [3]|U [3]|
|39|Track Condition Change of traction system|T [13]|T [13]|
|41|Level Transition Order|T [21]|T [21]|
|42|Session Management|U|U|
|44|Data used by applications outside the ERTMS/ETCS<br>system.|U [20]|U [20]|
|45|Radio Network registration|T [23]|T [23]|
|46|Conditional Level Transition Order|T [21]|T [21]|

<!-- end of page 56 -->

||**Received information**|**Ac**|**tion**|
|---|---|---|---|
|Packet|Packet Name|Operated|Operated system|
|Number||<br>system version<br>number X = 1|<br>version number X<br>= 2 or 3|
|49|List of Balise Groups for SH Area|U|U|
|51|Axle load Speed Profile|T [4][5]|T [4][5]|
|57|Movement Authority Request Parameters|U|U|
|58|Position Report Parameters|U|U|
|63|List of Balise Groups in SR Authority|U|U|
|65|Temporary Speed Restriction|U|U|
|66|Temporary Speed Restriction Revocation|U|U|
|67|Track Condition Big Metal Masses|U|U|
|68|Track Condition|U [8] [9]|U [8] [9]|
|70|Route Suitability Data|R [11] [12]|R [11] [12]|
|71|Adhesion Factor|U|U|
|72|Packet for sending plain text messages|T [6] [22]|T [6] [22]|
|79|Geographical Position Information|U [14]|U [14]|
|80|Mode profile|T [7]|T [7]|
|90|Track Ahead Free up to level 2 transition location|U|U|
|131|RBC transition order|U|U|
|132|Danger for Shunting information|U|U|
|133|Radio infill area information|U|U|
|134|EOLM Packet|U|U|
|135|Stop Shunting on desk opening|U|U|
|136|Infill location reference|U|U|
|137|Stop if in Staff Responsible|U|U|
|138|Reversing area information|U|U|
|139|Reversing supervision information|U|U|
|140|Train running number from RBC|T [10]|T [10]|
|141|Default Gradient for Temporary Speed Restriction|U|U|
|145|Inhibition of balise group message consistency reaction|U|U|
|200|Virtual Balise Cover marker|T [15]|T [15]|
|203|National Values for braking curves|T [16]|T [16]|
|206|Track Condition|T [17]|T [17]|

<!-- end of page 57 -->

||**Received information**|**Ac**|**tion**|
|---|---|---|---|
|Packet<br>Number|Packet Name|Operated<br>system version<br>number X = 1|Operated system<br>version number X<br>= 2 or 3|
|207|Route Suitability Data|T [18]|T [18]|
|239|Track Condition Change of traction system|T [19]|T [19]|
|254|Default balise, loop or RIU information|U|U|

[1a] The National Values Q_NVLOCACC, V_NVLIMSUPERV (introduced in system version number X = 2) shall be set to their respective default value

[1b] The National Values Q_NVLOCACC, V_NVLIMSUPERV (introduced in system version number X = 2), if already stored on-board and applicable, shall not be affected by the content of the packet 3 (i.e. if these National Values were already applicable and 2<sup>nd</sup> bullet of clause 3.18.2.5 is not applied, they shall remain applicable with their country identifier(s) previously stored).

[2] If the packet 203 is not received in the same message, the National Values for braking curves Q_NVGUIPERM, Q_NVSBFBPERM, Q_NVINHSMICPERM, M_NVAVADH, M_NVEBCL, A_NVP12, A_NVP23, V_NVKVINT, M_NVKVINT, L_NVKRINT, M_NVKRINT, M_NVKTINT, A_NVMAXREDADH1, A_NVMAXREDADH2, A_NVMAXREDADH3 (introduced in system version number X.Y = 1.1), if already stored on-board and applicable, shall not be affected by the content of the packet 3 (i.e. if the National Values for braking curves were already applicable and 2<sup>nd</sup> bullet of clause 3.18.2.5 is not applied, they shall remain applicable with their country identifier(s) previously stored).

[3] Exception: if N_ITER (following Q_FRONT)  0, the variables Q_DIFF, NC_CDDIFF (introduced in system version number X = 2) and NC_DIFF (as specified in system version number X = 3) shall be set according to the following table:

|Value received<br>from X = 1 trackside|Transl|ated values on-b|oard|
|---|---|---|---|
|NC_DIFF|Q_DIFF|NC_CDDIFF|NC_DIFF|
|0|0|9|-|
|1|0|0|-|
|2|0|1|-|
|3|0|2|-|
|4|0|3|-|
|5|0|4|-|
|6|0|5|-|
|7|0|7|-|
|8|0|10|-|
|9|1 or 2, see {1}|-|0|

<!-- end of page 58 -->

|10|1 or 2, see {1}|-|1|
|---|---|---|---|
|11|1 or 2, see {1}|-|2|
|12|0|8|-|
|13|0|6|-|

{1} Q_DIFF = 2 if a Specific SSP applicable to a Cant Deficiency category lower than or equal to the one of the train is received; otherwise Q_DIFF = 1

[4] If Q_TRACKINIT = 1, D_TRACKINIT (introduced in system version number X = 2) shall be set to 0

[5] The variable M_AXLELOADCAT (introduced in system version number X = 2) shall be set according to the following table:

|Value received from X = 1<br>trackside|Translated value<br>on-board|
|---|---|
|M_AXLELOAD|M_AXLELOADCAT|
|M_AXLELOAD ≤ 16 t|A|
|16 t < M_AXLELOAD ≤ 17 t|HS17|
|17 t < M_AXLELOAD ≤ 18 t|B1|
|18 t < M_AXLELOAD ≤ 20 t|C2|
|20 t < M_AXLELOAD ≤ 22.5 t|D2|
|22.5 t < M_AXLELOAD ≤ 40 t|E4|
|or M_AXLELOAD = “Axle load<br>above 40 t”||

[6] The variable NID_PACKET shall be set to 73 and if Q_TEXTCONFIRM  0, then Q_CONFTEXTDISPLAY and Q_TEXTREPORT (introduced in system version number X = 2) shall be set to 0

[7] The variable Q_MAMODE (introduced in system version number X = 2) shall be set to 1

[8] Exception: If the packet 206 is not received in the same message and if M_TRACKCOND = 1 or 2, then M_TRACKCOND (modified in system version number X = 2) shall be set to 0

[9] Exception: If the packet 206 is received in the same message, the ERTMS/ETCS on-board shall ignore the packet 68.

[10] Within the 8 digits of the variable NID_OPERATIONAL (as specified in system version X = 1), any digit coded as "F" shall be rightmost shifted, in order to obtain a variable NID_OPERATIONAL (as specified in system version X = 3) made of the significant digits leftmost adjusted followed by digits coded as "F".

[11] Exception: If the packet 207 is not received in the same message and if Q_TRACKINIT = 1, the packet shall not be rejected.

[12] Exception: If the packet 207 is not received in the same message and if the value “10” of the variable Q_SUITABILITY is used with M_TRACTION equal to one of the values that are listed in the translation table [13], the variables M_VOLTAGE and NID_CTRACTION (introduced in system version X.Y = 1.1) shall be set according to the translation table [13]. The ERTMS/ETCS on-board shall ignore any other route suitability information not related to the traction system

<!-- end of page 59 -->

[13] If the packet 239 is received in the same message or if M_TRACTION is not equal to one of the values that are listed here below, the ERTMS/ETCS on-board shall ignore the packet 39. If the packet 239 is not received in the same message and if M_TRACTION is equal to one of the values that are listed here below the variables M_VOLTAGE and NID_CTRACTION shall be set according to the following table:

|Value received|Translated v|alues on-board|
|---|---|---|
|from X = 1 trackside|||
|M_TRACTION|M_VOLTAGE|NID_CTRACTION|
|0|0|-|
|1|3|10|
|2|1|12|
|3|1|13|
|5|4|14|
|6|4|1|
|7|1|2|
|8|1|3|
|11|2|19|
|12|2|20|
|13|2|21|
|15|2|22|
|26|1|11|
|31|1|18|
|32|3|15|
|33|3|16|
|34|1|17|
|41|2|4|
|42|2|5|
|43|2|6|
|44|2|7|
|45<br>46|2<br>2|8<br>9|

[14] Exception: if M_POSITION = 1’048’575, then M_POSITION (modified in system version number X = 2) shall be set to 16’777’215

[15] The variable NID_PACKET shall be set to 0 and both the variables Q_DIR and L_PACKET shall be deleted

<!-- end of page 60 -->

[16] The National Values included in the packet 203 shall be appended to the packet 3 received in the same message, in order to form a single set of National Values, to which apply the distance to start of validity and the list of national area identifiers given in the packet 3.

[17] The variable NID_PACKET shall be set to 68.

[18] The variable NID_PACKET shall be set to 70 and if the value “01” of the variable Q_SUITABILITY is used, the variable M_LINEAXLELOADCAT (introduced in system version number X = 3) shall be set according to the following table:

|Value received from X = 1<br>trackside|Translated value on-board|
|---|---|
|M_AXLELOADCAT|M_LINEAXLELOADCAT|
|A|0000 0000 0000 0001|
|HS17|0000 0000 0000 0011|
|B1|0000 0000 0000 0111|
|B2|0000 0000 0000 1111|
|C2|0000 0000 0001 1111|
|C3|0000 0000 0011 1111|
|C4|0000 0000 0111 1111|
|D2|0000 0000 1111 1111|
|D3|0000 0001 1111 1111|
|D4|0000 0011 1111 1111|
|D4XL|0000 0111 1111 1111|
|E4|0000 1111 1111 1111|
|E5|0001 1111 1111 1111|

[19] The variable NID_PACKET shall be set to 39

[20] Exception: if NID_XUSER is equal to one of the values that are listed here below the variables NID_XUSER and NID_NTC shall be set according to the following table:

|Value received|Translated val|ues on-board|
|---|---|---|
|from X = 1 trackside|||
|NID_XUSER|NID_XUSER|NID_NTC|
|13|102|28|
|39|102|11|

[21] The variable M_LEVELTR shall be set according to the following table:

|Value received from X = 1|Translated value|
|---|---|
|trackside|on-board|
|0|0|
|1|1|

<!-- end of page 61 -->

|2|2|
|---|---|
|3|3|
|4|3|

[22] The variable M_LEVELTEXTDISPLAY shall be set according to the following table:

|Value received from X = 1<br>trackside|Translated value<br>on-board|
|---|---|
|0|0|
|1|1|
|2|2|
|3|3|
|4|3|
|5|4|

[23] the variable Q_NETWORKTYPE (introduced in system version number X = 3) shall be incorporated in this packet 45 (as specified in 6.5.1.5.9.1) in order to form the packet 45 (as specified in 7.4.2.11.1) as follows:

If NID_MN (X=1) = 901999 and either the applicable table of priority of trackside supported levels does not include level 2 or the operated level is different from 2 while no table of priority of trackside supported levels is applicable, Q_NETWORKTYPE is set to 0 and the variable NID_MN is deleted

If NID_MN (X=1) = 901999 and either the applicable table of priority of trackside supported levels includes level 2 or the operated level is 2 while no table of priority of trackside supported levels is applicable, Q_NETWORKTYPE is set to 1 and the variable NID_MN is set to the value of the GSM-R Radio Network ID currently stored on-board

If NID_MN (X=1) ≠ 901999, Q_NETWORKTYPE is set to 2

### **6.6.3.3 Messages received from RBC/RIU**

6.6.3.3.1 This section applies for the parts of radio messages, excluding the packets themselves, which are received from an RBC/RIU certified to the system version number X = 1.

6.6.3.3.2 Depending on the received message, the action can be:

   - a) data is unchanged,

   - b) data is rejected

   - c) data is translated,

   - d) not relevant

<!-- end of page 62 -->

|Message<br>Number|Message Name|Action|
|---|---|---|
|2|SR Authorisation|U|
|3|Movement Authority|U|
|6|Recognition of exit from TRIP mode|U|
|8|Acknowledgement of Train Data|U|
|9|Request to Shorten MA|U|
|15|Conditional Emergency Stop|T [1]|
|16|Unconditional Emergency Stop|U|
|18|Revocation of Emergency Stop|U|
|24|General message|U|
|27|SH Refused|U|
|28|SH Authorised|U|
|33|MA with Shifted Location Reference|U|
|34|Track Ahead Free Request|T [1]|
|37|Infill MA|U|
|40|Train Rejected|U [2]|
|32|RBC/RIU system version|U|
|39|Acknowledgement of termination of a communication session|U|
|41|Train Accepted|U [2]|
|43|SoM position report confirmed by RBC|U|
|45|Assignment of coordinate system|U|

[1] Variable D_REF (introduced in system version number X = 2) shall be set to 0

[2] Exception: if the variable NID_LRBG ≠ 16777215, it shall be set to 16777215, i.e. the message shall be considered as having been received with NID_LRBG = 16777215.

Note: An RBC X=1 based on an older version of the specification may use a value different from 16777215 for NID_LRBG in message 40 or 41.

### **6.6.3.4 Messages transmitted to RBC/RIU**

6.6.3.4.1 This section applies for radio messages/packets, which are transmitted to an RBC or an RIU certified to the system version number X = 1.

6.6.3.4.1.1 Clause 3.5.3.7 d) 1<sup>st</sup> bullet shall be replaced with: “If one of its supported system versions is compatible with the one sent by trackside, it shall send a session established report, including its telephone numbers, to the trackside.”

6.6.3.4.1.2 Clauses 3.5.3.7.4 and 3.5.3.7.4.1 shall not apply.

<!-- end of page 63 -->

6.6.3.4.1.3 Added clause 3.5.3.7.6 shall apply: “Regarding d) 1<sup>st</sup> bullet: If the ERTMS/ETCS onboard equipment is in Supervised Manoeuvre mode, it shall terminate the communication session immediately after the sending of the session established report.”

6.6.3.4.1.4 Clause 3.8.2.1.7 shall be replaced with: "Together with the MA request the on-board shall inform the RBC if the reason "Track description deletion" is applicable."

6.6.3.4.1.5 Clause 3.12.3.5.2 shall not apply.

6.6.3.4.1.6 Clause 3.18.3.10 shall not apply.

6.6.3.4.2 Clause 3.18.4.5.4 shall be replaced with: “Only if valid Train Data is available: following any entry/modification of the train running number when a communication session is already established or following the successful establishment of a communication session when valid train running number is already available, the ERTMS/ETCS onboard equipment shall send the Train Data to the RBC.

6.6.3.4.3 Clause 3.18.4.5.4.1 shall be replaced with: “Exception: if the train running number has been received from the RBC, the Train Data shall not be sent back to the RBC by the ERTMS/ETCS on-board equipment.

6.6.3.4.3.1 Requirements A33 and A34 in table 5.4.3.2 shall be replaced with:

**A33** The “SoM position report” message, marked as referring to a “valid train position referred to an LRBG”, shall be transmitted to the RBC. If already stored on-board, valid Train Data shall be transmitted to the RBC immediately after the “SoM position report” message. This condition leads to **S10** . **A34** If the train position data stored in the on-board equipment is of status “invalid” and refers to an LRBG, the “SoM position report” message, marked as referring to an “invalid train position referred to an LRBG”, shall be transmitted to the RBC. Otherwise the "SoM position report" message, marked as referring to "no train position referred to an LRBG” and with the LRBG identity set to "unknown", shall be transmitted to the RBC. In both cases valid Train Data, if already stored on-board, shall be transmitted to the RBC immediately after the “SoM position report” message. The process shall then go to **D33**

6.6.3.4.4 The ERTMS/ETCS on-board equipment shall elaborate the information to be transmitted to the RBC/RIU certified to system version number X = 1, by applying the following translation table to the corresponding information intended for an RBC/RIU certified to the system version number X.Y = 3.0.

6.6.3.4.5 Depending on the transmitted message/packet, the action can be:

   - a) data is unchanged,

b) data is deleted (i.e. it is not sent to the receiver)

- c) data is translated,

<!-- end of page 64 -->

d) not relevant (i.e. no corresponding requirement to trigger the sending is applicable)

- D = Deleted T = Translated U = Unchanged NR = Not relevant

|Mess<br>nbpck nb|Message name/packet name|Action|
|---|---|---|
|XXX0|Position Report|T [1]|
|XXX1|Position Report based on two balise groups|T [1]|
|1592|On-board supported system versions|T[6]|
|XXX4|Error Reporting|U [2]|
|XXX5|Train Running Number|NR|
|1329|Level 2 transition information|U|
|12911|Validated Train Data (packet)|T [3]|
|129|Validated Train Data (message)|U|
|130|Request for Shunting|U|
|131|Request for Supervised Manoeuvre|NR|
|132|MA Request|T [4]|
|133|Safe consist length information for SM|NR|
|136|Train Position Report|U|
|137|Request to shorten MA is granted|U|
|138|Request to shorten MA is rejected|U|
|146|Acknowledgement|U|
|147|Acknowledgement of Emergency Stop|T [5]|
|149|Track Ahead Free Granted|U|
|150|End of Mission|T [8]|
|153|Radio infill request|U|
|154|No compatible version supported|U|
|155|Initiation of a communication session|U|
|156|Termination of a communication session|U|
|157|SoM Position Report|U [7]|
|158|Text message acknowledged by driver|NR|
|159|Session Established|U|

[1] the packet 0 and the packet 1 shall be translated as follows:

<!-- end of page 65 -->

|**_Description_**|This packet is used to repo<br>additional information (e.g. m|rt the train<br>ode, level, et|position and speed as well as some<br>c.)|
|---|---|---|---|
|**_Transmitted to_**<br>|RBC, RIU<br>|||
|**_Content_**|**Variable**|**Length**|**Comment**|
||NID_PACKET|8||
||L_PACKET|13||
||Q_SCALE|2||
||NID_LRBG|10 + 14||
||D_LRBG|15||
||Q_DIRLRBG|2||
||Q_DLRBG|2||
||L_DOUBTOVER|15||
||L_DOUBTUNDER|15||
||Q_INTEGRITY|2||
||L_TRAININT|15||
||V_TRAIN|7|See translation [1c]|
||Q_DIRTRAIN|2||
||M_MODE|4|See translation [1a]|
||M_LEVEL|3|See translation [1b]|
||NID_NTC|8||

|**_Description_**<br>**_Transmitted to_**|This packet is an extension<br>case of single balise group<br>board equipment is able to<br>to give a direction referenc<br>RBC, RIU|of the “standard posit<br>s if the orientation of th<br>report a second balise<br>e for the directional inf|ion report“ packet 0. It is used in<br>e LRBG is unknown but the on-<br>group (the one detected before)<br>ormation in the position report.|
|---|---|---|---|
|**_Content_**|**Variable**|**Length**|**Comment**|
||NID_PACKET|8||
||L_PACKET|13||
||Q_SCALE|2||
||NID_LRBG|10 + 14||
||NID_PRVLRBG|10 + 14||
||D_LRBG|15||
||Q_DIRLRBG|2||
||Q_DLRBG|2||
||L_DOUBTOVER|15||
||L_DOUBTUNDER|15||

<!-- end of page 66 -->

|Q_INTEGRITY|2||
|---|---|---|
|L_TRAININT|15||
|V_TRAIN|7|See translation [1c]|
|Q_DIRTRAIN|2||
|M_MODE|4|See translation [1a]|
|M_LEVEL|3|See translation [1b]|
|NID_NTC|8||

#### [1a] M_MODE shall be set according to the following table:

|Value that would be<br>transmitted to an X.Y= 3.0<br>RBC|Transmitted value to<br>an X=1 RBC|
|---|---|
|0|0|
|1|1|
|2|2|
|3|3|
|4|4|
|5|5|
|6|6|
|7|7|
|8|8|
|9|9|
|10|10|
|11|11|
|12|12|
|13|13|
|14|14|
|15|3|
|16|0|

Note: if M_MODE (X=3) = 12 (LS), no translation is effected

[1b] M_LEVEL shall be set according to the following table:

|Value that would be|Transmitted value to an|
|---|---|
|transmitted to an|X=1 RBC|
|X.Y=3.0 RBC||
|0|0|

<!-- end of page 67 -->

|1|1|
|---|---|
|2|2|
|3|3 or 4, see {1}|

{1} M_LEVEL = 4 if a table of trackside supported levels is stored on-board and it is originated from a level transition order with M_LEVELTR = 4 given with a priority higher than M_LEVELTR = 3, if any. Otherwise, M_LEVEL = 3.

[1c] If V_TRAIN (X=3) = 127 (train at standstill), then V_TRAIN (X=1) = 0 km/h

[2] Exceptions: if M_ERROR (X=3) = 6, then M_ERROR (X=1) = 7; if M_ERROR (X=3) = 7, 8, 9 or 10 then the packet shall be deleted

[3] the packet 11 shall be translated as follows:

|**_Description_**<br>Validated train data.|||
|---|---|---|
|**_Transmitted to_**<br>RBC|||
|**_Content_**<br>**Variable**|**Length**|**Comment**|
|NID_PACKET|8||
|L_PACKET|13||
|NID_OPERATIONAL|32|See translation [3a]|
|NC_TRAIN|15|See translation [3b]|
|L_TRAIN|12||
|V_MAXTRAIN|7||
|M_LOADINGGAUGE|8|See translation [3c]|
|M_AXLELOAD|7|See translation [3d]|
|M_AIRTIGHT|2||
|N_ITER|5|See translation [3e]|
|N_ITER|5||
|NID_NTC (k)|8|Type of National System available|

[3a] NID_OPERATIONAL shall be set to the value stored on-board

[3b] NC_TRAIN shall be set according to the following table:

|Value stored on-board|Transmitted value to X=1 RBC|
|---|---|
|NC_CDTRAIN|NC_TRAIN|
|0|xxx xxxx xxxx xx1x|
|1|xxx xxxx xxxx x1xx|
|2|xxx xxxx xxxx 1xxx|
|3|xxx xxxx xxx1 xxxx|
|4|xxx xxxx xx1x xxxx|
|5|xxx xxxx x1xx xxxx|

<!-- end of page 68 -->

|6|x1x xxxx xxxx xxxx|
|---|---|
|7|xxx xxxx 1xxx xxxx|
|8|xx1 xxxx xxxx xxxx|
|9|xxx xxxx xxxx xxx1|
|10|xxx xxx1 xxxx xxxx|
|NC_TRAIN||
|000 0000 0000 0000|No bit is set to 1|
|xxx xxxx xxxx xxx1|xxx xx1x xxxx xxxx|
|xxx xxxx xxxx xx1x|xxx x1xx xxxx xxxx|
|xxx xxxx xxxx x1xx|xxx 1xxx xxxx xxxx|
|Other values|No bit is set to 1|

[3c] M_LOADINGGAUGE shall be set to 0

[3d] M_AXLELOAD shall be set according to the following table:

|Value stored on-board|Transmitted value to X=1<br>RBC|
|---|---|
|A|16 t|
|HS17|17 t|
|B1|18 t|
|B2|18 t|
|C2|20 t|
|C3|20 t|
|C4|20 t|
|D2|22,5 t|
|D3|22,5 t|
|D4|22,5 t|
|D4xL|22,5 t|
|E4|25 t|
|E5|25 t|

[3e] N_ITER shall be set to 0

[4] Q_MARQSTREASON shall be replaced with Q_TRACKDEL (1 bit) as follows: if Q_MARQSTREASON = x1xxx, Q_TRACKDEL shall be set to 1, otherwise Q_TRACKDEL shall be set to 0

[5] The variable Q_EMERGENCYSTOP (modified in system version number X = 2) shall be set according to the following table:

<!-- end of page 69 -->

|Value that would be transmitted<br>to X=3 RBC|Transmitted value to X=1 RBC|
|---|---|
|Q_EMERGENCYSTOP|Q_EMERGENCYSTOP|
|0|0|
|1|0|
|2|2|
|3|1|

[6] the packet 2 shall be replaced with the following packet numbered as 3:

|**Description**|Telephone numbers asso|ciated to the on|board equipment|
|---|---|---|---|
|**_Transmitted to_**|RBC, RIU|||
|**_Content_**|**Variable**|**Length**|**Comment**|
||NID_PACKET|8|=3|
||L_PACKET|13||
||N_ITER|5||
||NID_RADIO (k)|64||

[7] Exception: the packet 10 and/or the packet 11, if any, shall be deleted

[8] The variable Q_DESK shall be deleted

## **6.6.4 Specific requirements for on-board operating with system version number X = 2**

**6.6.4.1 Exceptions to chapter 3**

6.6.4.1.1 If the system version number of the supervising RBC is 2.0, 2.1 or 2.2, clause 6.6.2.1.2 shall apply.

6.6.4.1.2 Clause 6.6.2.1.3 shall apply.

6.6.4.1.3 Clause 6.6.2.1.4 shall apply.

**6.6.4.2 Exceptions to chapter 4**

6.6.4.2.1 If the system version number of the supervising RBC is 2.0, 2.1 or 2.2, clause 6.6.2.2.3 shall apply.

6.6.4.2.2 For text messages received in balise telegrams marked with a system version number lower than 2.2 or received from RBCs certified to the system version number 2.0 or 2.1, the clauses 6.6.2.2.4, 6.6.2.2.5 and 6.6.2.2.6 shall apply.

**6.6.4.3 Exceptions to chapter 5**

<!-- end of page 70 -->

6.6.4.3.1 If the system version number of the supervising RBC is 2.0, 2.1 or 2.2, clauses 6.6.2.3.1, 2, 6 &7 shall apply.

6.6.4.3.2 If the on-board is in communication with an RBC whose system version number is 2.0, 2.1 or 2.2, clauses 6.6.2.3.3, 6.6.2.3.4 & 6.6.2.3.5 shall apply.

**6.6.4.4 Exceptions to chapters 7, 8**

6.6.4.4.1 Void

## **6.6.5 Handling of air gap data related to system version number X = 2**

**6.6.5.1 General**

6.6.5.1.1 For information received from trackside, the message consistency check shall be achieved taking into account the exceptions to chapters 7 and 8, as described in section 6.5.2.3.

6.6.5.1.2 For information received from trackside, the ERTMS/ETCS on-board equipment shall apply the requirements here below, in order to use the information as if it had been elaborated in compliance with the current chapters 7 and 8.

**6.6.5.2 Packets received from balise, loop, RIU, RBC**

6.6.5.2.1 Upon receipt of a packet 41 or 46, the translation [21] referred to in 6.6.3.2.3 shall apply by analogy.

6.6.5.2.2 Upon receipt of a packet 70, the translation [18] referred to in 6.6.3.2.3 shall apply by analogy.

6.6.5.2.3 Upon receipt of a packet 72, the variable NID_PACKET shall be set to 73 and the translation [22] referred to in 6.6.3.2.3 shall apply by analogy.

6.6.5.2.4 Upon receipt of a packet 76, the variable NID_PACKET shall be set to 74 and the translation [22] referred to in 6.6.3.2.3 shall apply by analogy.

6.6.5.2.5 Upon receipt of a packet 245 with its variable Q_NETWORKTYPE = 0, the variable NID_PACKET shall be set to 45.

6.6.5.2.6 Upon receipt of a packet 245 with its variable Q_NETWORKTYPE = 1 or 2, this latter shall be incorporated in the packet 45 received in the same message (i.e. packet 45 as specified in 6.5.2.3.13.1), in order to form a single packet 45 as specified in 7.4.2.11.1.

6.6.5.2.7 Upon receipt of a packet 45 without packet 245 in the same message, the on-board shall form the packet 45 as specified in 7.4.2.11.1 with its variable Q_NETWORKTYPE set to 2.

**6.6.5.3 Messages transmitted to RBC/RIU X.Y = 2.0**

6.6.5.3.1 This section applies for radio messages/packets, which are transmitted to an RBC or an RIU certified to the system version number X.Y = 2.0.

<!-- end of page 71 -->

6.6.5.3.2 The clause 6.6.3.4.1.1 shall apply.

6.6.5.3.3 Clause 6.6.3.4.1.2 shall apply.

6.6.5.3.4 Clause 6.6.3.4.1.3&6 shall apply.

6.6.5.3.5 Clause 6.6.3.4.3.1 shall apply.

6.6.5.3.6 The ERTMS/ETCS on-board equipment shall elaborate the information to be transmitted to the RBC/RIU certified to system version number X = 2.0, by applying the following translation table to the corresponding information intended for an RBC/RIU certified to the system version number X.Y = 3.0.

6.6.5.3.7 Depending on the transmitted message/packet, the action can be:

   - a) data is unchanged,

   - b) data is deleted (i.e. it is not sent to the receiver)

   - c) data is translated,

d) not relevant (i.e. no corresponding requirement to trigger the sending is applicable)

### D = Deleted T = Translated U = Unchanged NR = Not relevant

|Mess<br>nbpck nb|Message name/packet name|Action|
|---|---|---|
|XXX0|Position Report|T [1]|
|XXX1|Position Report based on two balise groups|T [1]|
|1592|On-board supported system versions|T [2]|
|XXX4|Error Reporting|U [3]|
|XXX5|Train Running Number|U|
|1329|Level 2 transition information|U|
|12911|Validated Train Data (packet)|U|
|129|Validated Train Data (message)|U|
|130|Request for Shunting|U|
|131|Request for Supervised Manoeuvre|NR|
|132|MA Request|U|
|133|Safe consist length information for SM|NR|
|136|Train Position Report|U|
|137|Request to shorten MA is granted|U|
|138|Request to shorten MA is rejected|U|
|146|Acknowledgement|U|

<!-- end of page 72 -->

|Mess<br>nbpck nb|Message name/packet name|Action|
|---|---|---|
|147|Acknowledgement of Emergency Stop|U|
|149|Track Ahead Free Granted|U|
|150|End of Mission|T [5]|
|153|Radio infill request|U|
|154|No compatible version supported|U|
|155|Initiation of a communication session|U|
|156|Termination of a communication session|U|
|157|SoM Position Report|U [4]|
|158|Text message acknowledged by driver|U|
|159|Session Established|U|

[1] the packet 0 and the packet 1 shall be translated as follows:

|**_Description_**|This packet is used to repo<br>additional information (e.g. m|rt the train<br>ode, level, et|position and speed as well as some<br>c.)|
|---|---|---|---|
|**_Transmitted to_**<br>|RBC, RIU<br>|||
|**_Content_**|**Variable**|**Length**|**Comment**|
||NID_PACKET|8||
||L_PACKET|13||
||Q_SCALE|2||
||NID_LRBG|10 + 14||
||D_LRBG|15||
||Q_DIRLRBG|2||
||Q_DLRBG|2||
||L_DOUBTOVER|15||
||L_DOUBTUNDER|15||
||Q_INTEGRITY|2||
||L_TRAININT|15||
||V_TRAIN|7|See translation [1c]|
||Q_DIRTRAIN|2||
||M_MODE|4|See translation [1a]|
||M_LEVEL|3|See translation [1b]|
||NID_NTC|8||

<!-- end of page 73 -->

|**_Description_**|This packet is an extensio<br>case of single balise group<br>board equipment is able to<br>to give a direction referenc|n of the “standar<br>s if the orientati<br>report a second<br>e for the directi|d position report“ packet 0. It is used in<br>on of the LRBG is unknown but the on-<br>balise group (the one detected before)<br>onal information in the position report.|
|---|---|---|---|
|**_Transmitted to_**|RBC, RIU|||
|**_Content_**|**Variable**|**Length**|**Comment**|
||NID_PACKET|8||
||L_PACKET|13||
||Q_SCALE|2||
||NID_LRBG|10 + 14||
||NID_PRVLRBG|10 + 14||
||D_LRBG|15||
||Q_DIRLRBG|2||
||Q_DLRBG|2||
||L_DOUBTOVER|15||
||L_DOUBTUNDER|15||
||Q_INTEGRITY|2||
||L_TRAININT|15||
||V_TRAIN|7|See translation [1c]|
||Q_DIRTRAIN|2||
||M_MODE|4|See translation [1a]|
||M_LEVEL|3|See translation [1b]|
||NID_NTC|8||

[1a] M_MODE shall be set according to the following table:

|Value that would be<br>Transmitted value to an|
|---|
|transmitted to an<br>X.Y=3.0 RBC<br>X.Y=2.0 RBC|
|0<br>0|
|1<br>1|
|2<br>2|
|3<br>3|
|4<br>4|
|5<br>5|
|6<br>6|
|7<br>7|

<!-- end of page 74 -->

|8|8|
|---|---|
|9|9|
|10|10|
|11|11|
|12|12|
|13|13|
|14|14|
|15|15|
|16|0|

- [1b] See translation [1b] referred to in 6.6.3.4.5, which applies by analogy

- [1c] See translation [1c] referred to in 6.6.3.4.5, which applies by analogy

- [2] See translation [6] referred to in 6.6.3.4.5, which applies by analogy

- [3] Exception: if M_ERROR (X=3) = 9 or 10, then the packet shall be deleted

- [4] See exception [7] referred to in 6.6.3.4.5

[5] See translation [8] referred to in 6.6.3.4.5

### **6.6.5.4 Messages transmitted to RBC/RIU X.Y = 2.1**

6.6.5.4.1 This section applies for radio messages/packets, which are transmitted to an RBC or an RIU certified to the system version number X.Y = 2.1.

6.6.5.4.2 Clause 6.6.3.4.1.2 shall apply.

6.6.5.4.3 Clause 6.6.3.4.1.3&6 shall apply.

6.6.5.4.4 Clause 6.6.3.4.3.1 shall apply.

6.6.5.4.5 The ERTMS/ETCS on-board equipment shall elaborate the information to be transmitted to the RBC/RIU certified to system version number X = 2.1, by applying the following translation table to the corresponding information intended for an RBC/RIU certified to the system version number X.Y =3.0.

6.6.5.4.6 Depending on the transmitted message/packet, the action can be:

   - a) data is unchanged,

   - b) data is deleted (i.e. it is not sent to the receiver)

   - c) data is translated,

   - d) not relevant (i.e. no corresponding requirement to trigger the sending is applicable)

- D = Deleted T = Translated U = Unchanged NR = Not relevant

<!-- end of page 75 -->

|Mess<br>nbpck nb|Message name/packet name|Action|
|---|---|---|
|XXX0|Position Report|T [1]|
|XXX1|Position Report based on two balise groups|T [1]|
|1592|On-board supported system versions|U|
|XXX4|Error Reporting|U [2]|
|XXX5|Train Running Number|U|
|1329|Level 2 transition information|U|
|12911|Validated Train Data (packet)|U|
|129|Validated Train Data (message)|U|
|130|Request for Shunting|U|
|131|Request for Supervised Manoeuvre|NR|
|132|MA Request|U|
|133|Safe consist length information for SM|NR|
|136|Train Position Report|U|
|137|Request to shorten MA is granted|U|
|138|Request to shorten MA is rejected|U|
|146|Acknowledgement|U|
|147|Acknowledgement of Emergency Stop|U|
|149|Track Ahead Free Granted|U|
|150|End of Mission|T [4]|
|153|Radio infill request|U|
|154|No compatible version supported|U|
|155|Initiation of a communication session|U|
|156|Termination of a communication session|U|
|157|SoM Position Report|U [3]|
|158|Text message acknowledged by driver|U|
|159|Session Established|U|

[1] See translation [1] referred to in 6.6.5.3.7

[2] See exception [3] referred to in 6.6.5.3.7

[3] See exception [7] referred to in 6.6.3.4.5

[4] See translation [8] referred to in 6.6.3.4.5

### **6.6.5.5 Messages transmitted to RBC/RIU X.Y = 2.2**

<!-- end of page 76 -->

6.6.5.5.1 This section applies for radio messages/packets, which are transmitted to an RBC or an RIU certified to the system version number X.Y = 2.2.

6.6.5.5.2 Clause 6.6.3.4.1.2 shall apply.

6.6.5.5.3 Clause 6.6.3.4.1.3&6 shall apply.

6.6.5.5.4 Requirements A33&A34 in table 5.4.3.2 shall be replaced with:

- **A33** The “SoM position report” message, marked as referring to a “valid train position referred to an LRBG”, shall be transmitted to the RBC, together with valid Train Data and/or valid Train running number, if already stored on-board.

This condition leads to **S10** .

- **A34** If the train position data stored in the on-board equipment is of status “invalid” and refers to an LRBG, the “SoM position report” message, marked as referring to an “invalid train position referred to an LRBG”, shall be transmitted to the RBC.

   - Otherwise the "SoM position report" message, marked as referring to "no train position referred to an LRBG” and with the LRBG identity set to "unknown", shall be transmitted to the RBC.

In both cases valid Train Data and/or valid Train running number, if already stored onboard, shall be included in the “SoM position report” message. The process shall then go to **D33**

6.6.5.5.5 The ERTMS/ETCS on-board equipment shall elaborate the information to be transmitted to the RBC/RIU certified to system version number X = 2.2, by applying the following translation table to the corresponding information intended for an RBC/RIU certified to the system version number X.Y = 3.0.

6.6.5.5.6 Depending on the transmitted message/packet, the action can be:

   - a) data is unchanged,

   - b) data is deleted (i.e. it is not sent to the receiver)

   - c) data is translated,

d) not relevant (i.e. no corresponding requirement to trigger the sending is applicable)

### D = Deleted T = Translated U = Unchanged NR = Not relevant

|Mess<br>nbpck nb|Message name/packet name|Action|
|---|---|---|
|XXX0|Position Report|T [1]|
|XXX1|Position Report based on two balise groups|T [1]|
|1592|On-board supported system versions|U|
|XXX4|Error Reporting|U|

<!-- end of page 77 -->

|Mess<br>nbpck nb|Message name/packet name|Action|
|---|---|---|
|XXX5|Train Running Number|U|
|1329|Level 2 transition information|U|
|12911|Validated Train Data (packet)|U|
|129|Validated Train Data (message)|U|
|130|Request for Shunting|U|
|131|Request for Supervised Manoeuvre|NR|
|132|MA Request|U|
|133|Safe consist length information for SM|NR|
|136|Train Position Report|U|
|137|Request to shorten MA is granted|U|
|138|Request to shorten MA is rejected|U|
|146|Acknowledgement|U|
|147|Acknowledgement of Emergency Stop|U|
|149|Track Ahead Free Granted|U|
|150|End of Mission|T [2]|
|153|Radio infill request|U|
|154|No compatible version supported|U|
|155|Initiation of a communication session|U|
|156|Termination of a communication session|U|
|157|SoM Position Report|U [3]|
|158|Text message acknowledged by driver|U|
|159|Session Established|U|

[1] the packet 0 and the packet 1 shall be translated as follows:

|**_Description_**|This packet is used to repo<br>additional information (e.g. m|rt the train position and speed as well as some<br>ode, level, etc.)|
|---|---|---|
|**_Transmitted to_**|RBC, RIU||
|**_Content_**|**Variable**|**Length**<br>**Comment**|
||NID_PACKET|8|
||L_PACKET|13|
||Q_SCALE|2|
||NID_LRBG|10 + 14|
||D_LRBG|15|

<!-- end of page 78 -->

|Q_DIRLRBG|2||
|---|---|---|
|Q_DLRBG|2||
|L_DOUBTOVER|15||
|L_DOUBTUNDER|15||
|Q_INTEGRITY|2||
|L_TRAININT|15||
|V_TRAIN|7|See translation [1b]|
|Q_DIRTRAIN|2||
|M_MODE|5||
|M_LEVEL|3|See translation [1a]|
|NID_NTC|8||

|**_Description_**|This packet is an extensio<br>in case of single balise gr<br>on-board equipment is ab<br>before) to give a direction<br>report.|n of the “standa<br>oups if the orien<br>le to report a s<br>reference for th|rd position report “ packet 0. It is used<br>tation of the LRBG is unknown but the<br>econd balise group (the one detected<br>e directional information in the position|
|---|---|---|---|
|**_Transmitted to_**|RBC, RIU|||
|**_Content_**|**Variable**|**Length**|**Comment**|
||NID_PACKET|8||
||L_PACKET|13||
||Q_SCALE|2||
||NID_LRBG|10 + 14||
||NID_PRVLRBG|10 + 14||
||D_LRBG|15||
||Q_DIRLRBG|2||
||Q_DLRBG|2||
||L_DOUBTOVER|15||
||L_DOUBTUNDER|15||
||Q_INTEGRITY|2||
||L_TRAININT|15||
||V_TRAIN|7|See translation [1b]|
||Q_DIRTRAIN|2||
||M_MODE|5||
||M_LEVEL|3|See translation [1a]|
||NID_NTC|8||

<!-- end of page 79 -->

[1a] See translation [1b] referred to in 6.6.3.4.5, which applies by analogy

[1b] See translation [1c] referred to in 6.6.3.4.5, which applies by analogy

- [2] See translation [8] referred to in 6.6.3.4.5

[3] Exception: the packet 10, if any, shall be deleted

### **6.6.5.6 Messages transmitted to RBC/RIU X.Y = 2.3**

6.6.5.6.1 This section applies for radio messages/packets, which are transmitted to an RBC or an RIU certified to the system version number X.Y = 2.3.

6.6.5.6.2 The ERTMS/ETCS on-board equipment shall elaborate the information to be transmitted to the RBC/RIU certified to system version number X = 2.3, by applying the following translation table to the corresponding information intended for an RBC/RIU certified to the system version number X.Y = 3.0.

6.6.5.6.3 Depending on the transmitted message/packet, the action can be:

   - a) data is unchanged,

   - b) data is deleted (i.e. it is not sent to the receiver)

   - c) data is translated,

d) not relevant (i.e. no corresponding requirement to trigger the sending is applicable)

### D = Deleted T = Translated U = Unchanged NR = Not relevant

|Mess<br>nbpck nb|Message name/packet name|Action|
|---|---|---|
|XXX0|Position Report|T [1]|
|XXX1|Position Report based on two balise groups|T [1]|
|1592|On-board supported system versions|U|
|XXX4|Error Reporting|U|
|XXX5|Train Running Number|U|
|1329|Level 2 transition information|U|
|12911|Validated Train Data (packet)|U|
|129|Validated Train Data (message)|U|
|130|Request for Shunting|U|
|131|Request for Supervised Manoeuvre|U|
|132|MA Request|U|
|133|Safe consist length information for SM|U|
|136|Train Position Report|U|

<!-- end of page 80 -->

|Mess<br>nbpck nb|Message name/packet name|Action|
|---|---|---|
|137|Request to shorten MA is granted|U|
|138|Request to shorten MA is rejected|U|
|146|Acknowledgement|U|
|147|Acknowledgement of Emergency Stop|U|
|149|Track Ahead Free Granted|U|
|150|End of Mission|U|
|153|Radio infill request|U|
|154|No compatible version supported|U|
|155|Initiation of a communication session|U|
|156|Termination of a communication session|U|
|157|SoM Position Report|U|
|158|Text message acknowledged by driver|U|
|159|Session Established|U|

[1] the packet 0 and the packet 1 shall be translated as follows:

|**_Description_**|This packet is used to re<br>additional information (e.g.|port the train position and speed as well as some<br>mode, level, etc.)|
|---|---|---|
|**_Transmitted to_**|RBC, RIU||
|**_Content_**|**Variable**|**Length**<br>**Comment**|
||NID_PACKET|8|
||L_PACKET|13|
||Q_SCALE|2|
||NID_LRBG|10 + 14|
||D_LRBG|15|
||Q_DIRLRBG|2|
||Q_DLRBG|2|
||L_DOUBTOVER|15|
||L_DOUBTUNDER|15|
||Q_INTEGRITY|2|
||L_TRAININT|15|
||V_TRAIN|7|
||Q_DIRTRAIN|2|
||M_MODE|5|

<!-- end of page 81 -->

||M_LEVEL|3|See translation [1a]|
|---|---|---|---|
||NID_NTC|8||
|**_Description_**|This packet is an extensio<br>in case of single balise gro<br>on-board equipment is ab<br>before) to give a direction<br>report.|n of the “standa<br>ups if the orien<br>le to report a s<br>reference for th|rd position report “ packet 0. It is used<br>tation of the LRBG is unknown but the<br>econd balise group (the one detected<br>e directional information in the position|
|**_Transmitted to_**|RBC, RIU|||
|**_Content_**|**Variable**|**Length**|**Comment**|
||NID_PACKET|8||
||L_PACKET|13||
||Q_SCALE|2||
||NID_LRBG|10 + 14||
||NID_PRVLRBG|10 + 14||
||D_LRBG|15||
||Q_DIRLRBG|2||
||Q_DLRBG|2||
||L_DOUBTOVER|15||
||L_DOUBTUNDER|15||
||Q_INTEGRITY|2||
||L_TRAININT|15||
||V_TRAIN|7||
||Q_DIRTRAIN|2||
||M_MODE|5||
||M_LEVEL|3|See translation [1a]|
||NID_NTC|8||

[1a] See translation [1b] referred to in 6.6.3.4.5, which applies by analogy

<!-- end of page 82 -->
