# **ERTMS/ETCS**

**System Requirements Specification Chapter 7 ERTMS/ETCS language**

REF  :  SUBSET-026-7 ISSUE :

4.0.0 DATE : 05/07/2023

<!-- end of page 1 -->

# **7.1 Modification History**

|Issue Number<br>Date|Section Number|Modification / Description|Author|
|---|---|---|---|
|0.0.1<br>990422|All|Creation of document|OG/DD|
|0.0.2<br>990423|All|Changed<br>according<br>to<br>Siemens comments|OG/DD|
|1.1.0<br>990423|All|Class P Official Issue|OG/DD|
|1.1.1<br>990525|All|Add review comments<br>UNISIG_All_COM_006_7.d<br>oc|BRO|
|1.1.2|All|Some minor corrections|SAB|
|1.1.3|All|First draft for class 1|SAB|
|1.1.4|All|Update according to review<br>comments|SAB|
|1.1.5|All|Some minor modifications<br>(see revision marks) +<br>Addition of length of<br>variables in the packets.|OG|
|1.1.6|Version number and<br>editorial changes.|Finalisation meeting in<br>Stuttgart 990729|HE|
|1.2.0<br>990730|Version Number|Release Version|HE|
|1.2.1<br>991209|All|Changes according to WPs<br>for SRS upgrade + editorial<br>changes due to ECSAG /<br>UNISIG agreed questions|OG|
|1.3.0<br>991217|All|Changed<br>according<br>to<br>review comments|OG|
|2.0.0<br>991222|Minor editorial changes|Release version|OG|
|2.0.1<br>000926|All|Corrections after UNISIG<br>review 15 June 00|OG|
|2.1.0<br>001012|All|Corrections<br>according<br>to<br>“2nisig_all_com_SRS_<br>2.0.1” document|OG|
|2.2.0|Packet<br>71<br>deleted,<br>NID_C 10 bit|UNISIG release|SAB|

<!-- end of page 2 -->

|2.2.2|see revision marks<br>Corrections<br>according<br>to<br>SUBSET-026<br>Corrected<br>Paragraphs, issue 2.2.2.<br>Mainly,<br>Packet<br>71<br>and<br>Q_NVDRIVER_ADHES<br>added|OG|
|---|---|---|
|2.2.4<br>24.05.2004|Update after cross checking<br>and comments from Alain|B. Stamm|
|2.2.4 SG checked<br>28/05/04|Including all CLRs agreed with the EEIG (see “List of<br>CLRs agreed with EEIG for SRS v2.2.4” dated<br>28/05/04)<br>Affected clauses see change marks|H. Kast|
|2.2.5<br>04/01/05|Incorporation of solution proposal for CLR 007 with<br>EEIG users group comments|A. Hougardy|
|2.2.6|Incorporation of all CRs and CLRs submitted to the<br>EEIG until 21.01.2005|B. Stamm|
|2.2.7|Incorporation of all CRs and CLRs extracted from “CR-<br>Report_10.6.05-by number.rtf” and mentioned in<br>column<br>2.2.7<br>in<br>“CR<br>status<br>13.6.05<br>_rmk_chap_3_4_220605.xls”|B. Stamm|
|2.2.8|Change marks cleaned up and updated according to<br>last CRs decisions (including split of CRs7&126)|J. Liesche|
|2.2.9<br>24/02/06|Including all CRs that are classified as “IN” as per<br>SUBSET-108 version 1.0.0<br>Removal of all CRs that are not classified as “IN” as<br>per SUBSET-108 version 1.0.0, with the exception of<br>CRs 63,98,120,158,538|J. Liesche|
|2.3.0<br>24/02/06|Release version|HK|
|2.3.1|Including SG CR decision made since SRS 2.2.8,<br>correct errors in 2.2.8 detected when creating SRS<br>2.3.0|J. Liesche|
|2.3.2<br>17/03/08|Including all CRs that are classified as “IN” as per<br>SUBSET-108 version 1.2.0 and all CRs that are in<br>state “Analysis completed” according to ERA CCM|A. Hougardy|
|2.9.1<br>06/10/08|Including all enhancement CR’s retained for 3.0.0<br>baseline and all other error CR’s that are in state<br>“Analysis completed” according to ERA CCM<br>For editorial reasons, the following CR’s are also<br>included: CR656, CR804, CR821|A. Hougardy|

<!-- end of page 3 -->

|3.0.0<br>23/12/08|Release version|A. Hougardy|
|---|---|---|
|3.0.1<br>22/12/09|Including the results of the editorial review of the SRS<br>3.0.0 and the other error CR’s that are in state<br>“Analysis completed” according to ERA CCM|A. Hougardy|
|3.1.0<br>22/02/10|Release version|A. Hougardy|
|3.1.1<br>08/11/10|Including all CR’s that are in state “Analysis<br>completed” according to ERA CCM, plus CR731, 972<br>and 1000.|A. Hougardy|
|3.2.0<br>22/12/10|Release version|A. Hougardy|
|3.2.1<br>13/12/11|Including all CR’s that are in state “Analysis<br>completed” according to ERA CCM.|A. Hougardy|
|3.3.0<br>07/03/12|Baseline 3 release version|A. Hougardy|
|3.3.1<br>04/04/14|CR 1176|O. Gemine|
|3.3.2<br>23/04/14|Baseline 3 1<sup>st</sup>maintenance pre-release version|O. Gemine|
|3.3.3<br>06/05/14|CR 1223<br>Baseline 3 1<sup>st</sup>maintenance 2<sup>nd</sup>pre-release version|O. Gemine|
|3.4.0<br>12/05/14|Baseline 3 1<sup>st</sup>maintenance release version|O. Gemine|
|3.4.1<br>23/06/15|CR’s 1164, 1250|O. Gemine|
|3.4.2<br>17/11/15|CR’s 299, 1089, 1249, 1262, 1265, 1266, 1280|O. Gemine|
|3.4.3<br>16/12/15|1283 plus update due to overall CR consolation phase|<sup>O. Gemine</sup>|
|3.5.0<br>18/12/15|Baseline 3 2<sup>nd</sup>release version as recommended to EC<br>(see ERA-REC-123-2015/REC)|O. Gemine|
|3.5.1<br>28/04/16|CR 1249 reopening following RISC #75|O. Gemine|
|3.6.0<br>13/05/16|Baseline 3 2<sup>nd</sup>release version|A. Hougardy|

<!-- end of page 4 -->

|3.6.1<br>29/05/17|CR’s 940, 994, 1252, 1288, 1293|O. Gemine|
|---|---|---|
|3.6.2<br>31/05/18|CR 994 (bad implementation)|O. Gemine|
|3.6.3<br>21/02/20|CR’s 1282, 1311, 1313, 1320, 1329, 1334, 1340, 1341|<sup>O. Gemine</sup>|
|3.6.4<br>22/06/20|CR 1334|O. Gemine|
|3.6.5<br>22/12/21|CR’s 1238, 1396|O. Gemine|
|3.6.6<br>29/08/22|CR’s 940 (updated), 1120, 1342, 1350, 1363, 1367,<br>1389|O. Gemine|
|3.9.1<br>24/11/22|CR’s<br>988,<br>1307,<br>1367(updated),<br>1397,<br>1293<br>(updated), 1425<br>Outcome of B4R1 1<sup>st</sup>consolidation phase|O. Gemine<br>A. Hougardy|
|3.9.2<br>21/02/23|Outcome of B4R1 2<sup>nd</sup>consolidation phase|O. Gemine<br>A. Hougardy|
|3.9.3<br>31/05/23|CR 1359<br>Outcome of B4R1 3<sup>rd</sup>consolidation phase|O. Gemine<br>A. Hougardy|
|3.9.4<br>30/06/23|CR 1342 (updated)<br>Outcome of B4R1 4<sup>th</sup>consolidation phase|O. Gemine<br>A. Hougardy|
|4.0.0<br>05/07/23|Baseline 4 1<sup>st</sup>release version|O. Gemine<br>A. Hougardy|

<!-- end of page 5 -->

|**7.2**|**Table of Contents**|
|---|---|
|7.1|Modification History ........................................................................................................... 2|
|7.2|Table of Contents .............................................................................................................. 6|
|7.3|Components of ERTMS/ETCS Language ......................................................................... 7|
|7.3|.1<br>Introduction ................................................................................................................ 7|
|7.3|.2<br>Definition of Variables ................................................................................................ 7|
|7.3|.3<br>Definition of Packets .................................................................................................. 8|
|7.4|PACKETS ....................................................................................................................... 10|
|7.4|.1<br>List of Packets .......................................................................................................... 10|
|7.4|.2<br>PACKETS: TRACK TO TRAIN ................................................................................. 12|
|7.4|.3<br>PACKETS: TRAIN TO TRACK ................................................................................. 40|
|7.4|.4<br>Intentionally deleted ................................................................................................. 45|
|7.5|Definitions of Variables ................................................................................................... 46|

<!-- end of page 6 -->

# **7.3 Components of ERTMS/ETCS Language**

**7.3.1 Introduction** 7.3.1.1 The ERTMS/ETCS language is used in transmitting information over the radio, balise and loop airgaps.

7.3.1.2 The ERTMS/ETCS language is based on variables, packets, messages and telegrams (variables and packets are described in this section, while telegrams and messages are described in chapter 8).

7.3.1.3 Note: A number of variables contain values which have to be assigned. Some of these values have to be unique to ensure that the system functions properly. A centralised handling of this assignment is therefore required (nationally or internationally, depending on the variable). The variables concerned have been marked. The values included in this document for these variables are therefore not to be used without prior verification of their validity. See SUBSET-054 for further details.

## **7.3.2 Definition of Variables**

|7.3.2.1|Variables are used to encode single data values. Variables cannot be split in minor units.<br>The whole variable has one type (meaning).|
|---|---|
|7.3.2.2|Variables may have special values which are related to the basic meaning of the variable.|
|7.3.2.3|Special values have always the highest values in a variable (e.g. 32767 = “unknown”).|
|7.3.2.4|Spare values are located between the normal and special values in the variable range|
|7.3.2.5|Names of variables are unique. A variable is used in context with the meaning as<br>described in the variable definition. Variables with different meanings have different<br>names.|
|7.3.2.6|All variable definitions are independent of the transport media over which they are used,<br>if used in more than one media.|
|7.3.2.7|Signed values shall be encoded as 2’s complement.|
|7.3.2.8|One bit variables (Boolean) always use 0 for false and 1 for true.|
|7.3.2.9|Offsets for numerical values are avoided (0 is used for 0, 1 for 1, etc.) except where<br>justified.|
|7.3.2.10|When transmitting over the different transmission media, the most significant bit shall be<br>transmitted first.|
|7.3.2.11|All Variables have one of the following prefixes:|
||A_<br>Acceleration|
||D_<br>distance|

<!-- end of page 7 -->

G_ Gradient L_ length M_ Miscellaneous N_ Number NC_ class number NID_ identity number Q_ Qualifier T_ time/date V_ Speed X_ Text

## **7.3.3 Definition of Packets**

7.3.3.1 Packets are multiple variables grouped into a single unit, with a defined internal structure.

7.3.3.2

This structure consists of a packet header with:

- Track to Train: a unique packet number, the length of the packet in bits, the orientation information, optionally the scale for distance/length information and an information section containing a defined set of variables. The packet structure is as follows:

|Number|NID_PACKET|Packet identifier|
|---|---|---|
|Direction|Q_DIR|Specifies the validity direction of<br>transmitted data|
|Length|L_PACKET|Number of bits in the packet|
|Scale|Q_SCALE|Specifies which scale is used for<br>distance/length<br>information<br>within the packet.<br>There is no Q_SCALE variable<br>in packets which do not contain<br>distance information.|
|Information|......|Well defined set(s) of variables.|

- Train to Track: a unique packet number, the length of the packet in bits, optionally the distance scale and an information section containing a defined set of variables. The packet structure is as follows:

|Number|NID_PACKET|Packet identifier|
|---|---|---|
|Length|L_PACKET|Number of bits in the packet|
|Scale|Q_SCALE|Specifies which scale is used for<br>distance/length<br>information<br>within the packet.|
|||There is no Q_SCALE variable<br>in packets which do not contain<br>distance information.|

<!-- end of page 8 -->

- Information ...... Well defined set(s) of variables.

7.3.3.3 The packet definition does not change when transmitted over different transmission media.

7.3.3.4 All packet identifiers not listed in 7.4.1.1 shall be considered as invalid values (i.e. like spare values) when received by the on-board equipment. Exception: reception of information only differing by Y with regards to the highest system version number X supported by on-board (refer to section 3.17.3.11).

7.3.3.4.1 Note: Depending on the system version number with which the message/telegram was transmitted relevant exception from chapter 6 may apply regarding 7.4.1.1.

7.3.3.5 Exception: Packet 0 “Virtual Balise Cover marker” and Packet 255: “End of Telegram” do not follow the above defined structure.

7.3.3.6 N_ITER specifies the number of iterations of a variable or group of variables which follow.

7.3.3.7 If N_ITER is 0 then no variables follow.

7.3.3.8 Two or more nested levels of iterations can exist.

7.3.3.9 If, depending on the value of a previous qualifier variable in the packet, a variable is optional, it is written indented in the packet definition

7.3.3.10 Row “Transmitted by” in the description of a packet specifies which ERTMS/ETCS trackside device (balise, loop, RIU, RBC) can transmit this packet. “Any” means that the packet can be transmitted by a balise, a loop, an RBC and a RIU.

7.3.3.10.1 Row “Transmitted to” in the description of a packet specifies to which ERTMS/ETCS trackside device the packet can be transmitted.

<!-- end of page 9 -->

# **7.4 PACKETS**

## **7.4.1 List of Packets**

### 7.4.1.1 Track to Train

|Packet<br>|Packet Name|Page N°|
|---|---|---|
|Number|||
|0|Virtual Balise Cover marker|12|
|2|System Version order|12|
|3|National Values|12|
|5|Linking|15|
|6|Virtual Balise Cover order|16|
|12|Level 1 Movement Authority|16|
|13|Staff Responsible distance information from loop|18|
|15|Level 2 Movement Authority|18|
|16|Repositioning Information|19|
|21|Gradient Profile|19|
|27|International Static Speed Profile|20|
|31|RBC transition order for RBC interfaced to FRMCS only|20|
|32|Session management for RBC interfaced to FRMCS only|21|
|39|Track Condition Change of traction system|21|
|40|Track Condition Change of allowed current consumption|21|
|41|Level Transition Order|22|
|42|Session Management for RBC interfaced to GSM-R|22|
|44|Data used by applications outside the ERTMS/ETCS system.|23|
|45|Radio Network transition order|23|
|46|Conditional Level Transition Order|23|
|49|List of Balise Groups for SH Area|24|
|51|Axle load Speed Profile|24|
|52|Permitted Braking Distance Information|25|
|57|Movement Authority Request Parameters|26|
|58|Position Report Parameters|26|
|63|List of Balise Groups in SR Authority|26|
|64|Inhibition of revocable TSRs from balises in level 2|27|
|65|Temporary Speed Restriction|27|
|66|Temporary Speed Restriction Revocation|27|
|67|Track Condition Big Metal Masses|27|
|68|Track Condition|28|
|69|Track Condition Station Platforms|28|
|70|Route Suitability Data|29|
|71|Adhesion Factor|30|
|73|Packet for sending plain text messages|30|
|74|Packet for sending fixed text messages|31|
|79|Geographical Position Information|32|
|80|Mode profile|33|
|88|Level crossing information|33|

<!-- end of page 10 -->

|Packet<br>Number|Packet Name|Page N°|
|---|---|---|
|90|Track Ahead Free up to level 2 transition location|34|
|131|RBC transition order for RBC interfaced to GSM-R|34|
|132|Danger for Shunting information|34|
|133|Radio infill area information|35|
|134|EOLM Packet|35|
|135|Stop Shunting on desk opening|35|
|136|Infill location reference|36|
|137|Stop if in Staff Responsible|36|
|138|Reversing area information|36|
|139|Reversing supervision information|37|
|140|Train running number from RBC|37|
|141|Default Gradient for Temporary Speed Restriction|37|
|143|Session Management with neighbouring Radio Infill Unit|37|
|145|Inhibition of balise group message consistency reaction|38|
|180|LSSMA display toggle order|38|
|181|Generic LS function marker|38|
|254|Default balise, loop or RIU information|39|
|255|End of Information|39|
|7.4.1.2|Train to Track||
|Packet<br>Number|Packet Name|Page N°|
|0|Position Report|40|
|1|Position Report based on two balise groups|40|
|2|Onboard supported system versions|41|
|4|Error Reporting|41|
|5|Train running number|42|
|9|Level 2 transition information|42|
|10|Safe consist length information for Supervised Manoeuvre|42|
|11|Validated train data|42|
|12|Default train data for Supervised Manoeuvre|43|
|44|Data used by applications outside the ERTMS/ETCS system.|44|

### 7.4.1.3 Intentionally deleted

<!-- end of page 11 -->

## **7.4.2 PACKETS: TRACK TO TRAIN**

7.4.2.0 Packet Number 0: Virtual Balise Cover marker

|**_Description_**|Indication to on-board tha|t the telegram can be|ignored according to a VBC|
|---|---|---|---|
|**_Transmitted by_**|Balise|||
|**_Content_**|**Variable**|**Length**|**Comment**|
||NID_PACKET|8||
||NID_VBCMK|6||

### 7.4.2.1 Packet Number 2: System Version order

|**_Description_**|This packet is used to tell|the on-board which is|the operated system version|
|---|---|---|---|
|**_Transmitted by_**|Balise|||
|**_Content_**|**Variable**|**Length**|**Comment**|
||NID_PACKET|8||
||Q_DIR|2||
||L_PACKET|13||
||M_VERSION|7||

### 7.4.2.1.1 Packet Number 3: National Values

|**_Description_**|Downloads a set of Natio|nal Values to th|e train|
|---|---|---|---|
|**_Transmitted by_**|Balise, RBC|||
|**_Content_**|**Variable**|**Length**|**Comment**|
||NID_PACKET|8||
||Q_DIR|2||
||L_PACKET|13||
||Q_SCALE|2||
||D_VALIDNV|15||
||NID_C|10|Identification of national areas to<br>which the set applies|
||N_ITER|5||
||NID_C(k)|10|Identification of additional national<br>area(s) to which the set applies|
||V_NVSHUNT|7||
||V_NVSTFF|7||
||V_NVONSIGHT|7||
||V_NVLIMSUPERV|7||
||V_NVUNFIT|7||
||V_NVREL|7||

<!-- end of page 12 -->

|D_NVROLL|15||
|---|---|---|
|Q_NVSBTSMPERM|1||
|Q_NVEMRRLS|1||
|Q_NVGUIPERM|1||
|Q_NVSBFBPERM|1||
|Q_NVINHSMICPERM|1||
|V_NVALLOWOVTRP|7||
|V_NVSUPOVTRP|7||
|D_NVOVTRP|15||
|T_NVOVTRP|8||
|D_NVPOTRP|15||
|M_NVCONTACT|2||
|T_NVCONTACT|8||
|M_NVDERUN|1||
|D_NVSTFF|15||
|Q_NVDRIVER_ADHES|1||
|A_NVMAXREDADH1|6||
|A_NVMAXREDADH2|6||
|A_NVMAXREDADH3|6||
|Q_NVLOCACC|6||
|M_NVAVADH|5||
|M_NVEBCL|4||
|Q_NVKINT|1||
|Q_NVKVINTSET|2|Only if Q_NVKINT = 1,<br>Q_NVKVINTSET and the following<br>variables follow|
|A_NVP12|6|Only if Q_NVKVINTSET = 1|
|A_NVP23|6|Only if Q_NVKVINTSET = 1|
|V_NVKVINT|7|= 0 km/h|
|M_NVKVINT|7|Valid between V_NVKVINT and<br>V_NVKVINT(1)<br>If Q_NVKVINTSET = 1, gives the<br>correction factor if maximum<br>emergency brake deceleration is<br>lower than A_NVP12|

<!-- end of page 13 -->

|M_NVKVINT|7|Only if Q_NVKVINTSET = 1<br>Valid between V_NVKVINT and<br>V_NVKVINT(1)<br>Gives the correction factor if<br>maximum emergency brake<br>deceleration is higher than<br>A_NVP23|
|---|---|---|
|N_ITER|5||
|V_NVKVINT(n)|7||
|M_NVKVINT(n)|7|Valid between V_NVKVINT(n) and<br>V_NVKVINT(n+1)<br>If Q_NVKVINTSET = 1, gives the<br>correction<br>factor<br>if<br>maximum<br>emergency brake deceleration is<br>lower than A_NVP12|
|M_NVKVINT(n)|7|Only if Q_NVKVINTSET = 1<br>Valid between V_NVKVINT(n) and<br>V_NVKVINT(n+1)|
|||Gives<br>the<br>correction<br>factor<br>if|
|||maximum<br>emergency<br>brake|
|||deceleration<br>is<br>higher<br>than<br>A_NVP23|
|N_ITER|5||
|Q_NVKVINTSET(k)|2||
|A_NVP12(k)|6|Only if Q_NVKVINTSET(k) = 1|
|A_NVP23(k)|6|Only if Q_NVKVINTSET(k) = 1|
|V_NVKVINT(k)|7|= 0km/h|
|M_NVKVINT(k)|7|Valid between V_NVKVINT(k) and<br>V_NVKVINT(k,1)<br>If Q_NVKVINTSET(k) = 1, gives the<br>correction<br>factor<br>if<br>maximum<br>emergency brake deceleration is<br>lower than A_NVP12(k)|
|M_NVKVINT(k)|7|Only if Q_NVKVINTSET(k) = 1<br>Valid between V_NVKVINT(k) and<br>V_NVKVINT(k,1)|
|||Gives<br>the<br>correction<br>factor<br>if|
|||maximum<br>emergency<br>brake|
|||deceleration<br>is<br>higher<br>than<br>A_NVP23(k)|

<!-- end of page 14 -->

|N_ITER(k)|5||
|---|---|---|
|V_NVKVINT(k,m)|7||
|M_NVKVINT(k,m)|7|Valid<br>between<br>V_NVKVINT(k,m)<br>and V_NVKVINT(k,m+1)<br>If Q_NVKVINTSET(k) = 1, gives the<br>correction<br>factor<br>if<br>maximum<br>emergency brake deceleration is<br>lower than A_NVP12(k)|
|M_NVKVINT(k,m)|7|Only if Q_NVKVINTSET(k) = 1<br>Valid<br>between<br>V_NVKVINT(k,m)<br>and V_NVKVINT(k,m+1)<br>Gives<br>the<br>correction<br>factor<br>if<br>maximum<br>emergency<br>brake<br>deceleration<br>is<br>higher<br>than<br>A_NVP23(k)|
|L_NVKRINT|5|= 0m|
|M_NVKRINT|5|Valid between L_NVKRINT and<br>L_NVKRINT(1)|
|N_ITER|5||
|L_NVKRINT(l)|5||
|M_NVKRINT(l)|5|Valid between L_NVKRINT(l) and<br>L_NVKRINT(l+1)|
|M_NVKTINT|5||

### 7.4.2.2 Packet Number 5: Linking

|**_Description_**|Linking Information.|||
|---|---|---|---|
|**_Transmitted by_**|Any|||
|**_Content_**|**Variable**|**Length**|**Comment**|
||NID_PACKET|8||
||Q_DIR|2||
||L_PACKET|13||
||Q_SCALE|2||
||D_LINK|15||
||Q_NEWCOUNTRY|1||
||NID_C|10|if Q_NEWCOUNTRY = 1|
||NID_BG|14||
||Q_LINKORIENTATION|1||
||Q_LINKREACTION|2||
||Q_LOCACC|6||

<!-- end of page 15 -->

|N_ITER|5||
|---|---|---|
|D_LINK (k)|15||
|Q_NEWCOUNTRY(k)|1||
|NID_C (k)|10|if Q_NEWCOUNTRY(k) = 1|
|NID_BG (k)|14||
|Q_LINKORIENTATION (k)|1||
|Q_LINKREACTION (k)|2||
|Q_LOCACC (k)|6||

### 7.4.2.2.1 Packet Number 6: Virtual Balise Cover order

|**_Description_**|The packet sets/removes|a Virtual Balise|Cover.|
|---|---|---|---|
|**_Transmitted by_**|Balise|||
|**_Content_**|**Variable**|**Length**|**Comment**|
||NID_PACKET|8||
||Q_DIR|2||
||L_PACKET|13||
||Q_VBCO|1||
||NID_VBCMK|6||
||NID_C|10||
||T_VBC|8|Only if Q_VBCO = 1|

### 7.4.2.3 Packet Number 12: Level 1 Movement Authority

|**_Description_**|Transmission of a movement autho|rity for level 1.||
|---|---|---|---|
|**_Transmitted_**<br>**_by_**|Balise, loop, RIU|||
|**_Content_**|**Variable**|**Length**|**Comment**|
||NID_PACKET|8||
||Q_DIR|2||
||L_PACKET|13||
||Q_SCALE|2||
||V_MAIN|7||
||V_EMA|7||
||T_EMA|10|Can be set to “no time-out”|
||N_ITER|5|Set to zero if V_MAIN = 0 or if<br>only one section in the MA|
||L_SECTION(k)|15||
||Q_SECTIONTIMER(k)|1||
||T_SECTIONTIMER(k)|10||

<!-- end of page 16 -->

|D_SECTIONTIMERSTOPLOC(k)|15|
|---|---|
|L_ENDSECTION|15|
|Q_SECTIONTIMER|1|
|T_SECTIONTIMER|10|
|D_SECTIONTIMERSTOPLOC|15|
|Q_ENDTIMER|1|
|T_ENDTIMER|10|
|D_ENDTIMERSTARTLOC|15|
|Q_DANGERPOINT|1|
|D_DP|15|
|V_RELEASEDP|7|
|Q_OVERLAP|1|
|D_STARTOL|15|
|T_OL|10|
|D_OL|15|
|V_RELEASEOL|7|

<!-- end of page 17 -->

### 7.4.2.3.1 Packet Number 13: Staff Responsible distance Information from loop

|**_Description_**|Information for trains in staf|f responsible|mode|
|---|---|---|---|
|**_Transmitted by_**|Loop|||
|**_Content_**|**Variable**|**Length**|**Comment**|
||NID_PACKET|8||
||Q_DIR|2||
||L_PACKET|13||
||Q_SCALE|2||
||Q_NEWCOUNTRY|1||
||NID_C|10|If Q_NEWCOUNTRY = 1|
||NID_BG|14|Main signal balise group|
||Q_NEWCOUNTRY|1||
||NID_C|10|If Q_NEWCOUNTRY = 1|
||NID_BG|14|Reference balise|
||D_SR|15||
||N_ITER|5||
||Q_NEWCOUNTRY (k)|1||
||NID_C (k)|10|If Q_NEWCOUNTRY (k) = 1|
||NID_BG (k)|14|Reference balise|
||D_SR (k)|15||

### 7.4.2.4 Packet Number 15: Level 2 Movement Authority

|**_Description_**|Transmission of a movement autho|rity for level 2.||
|---|---|---|---|
|**_Transmitted_**<br>**_by_**|RBC|||
|**_Content_**|**Variable**|**Length**|**Comment**|
||NID_PACKET|8||
||Q_DIR|2||
||L_PACKET|13||
||Q_SCALE|2||
||V_EMA|7||
||T_EMA|10|Can be set to “no time-out”|
||N_ITER|5|Set to zero if only one section in<br>the MA|
||L_SECTION(k)|15||
||Q_SECTIONTIMER(k)|1||
||T_SECTIONTIMER(k)|10||

<!-- end of page 18 -->

|D_SECTIONTIMERSTOPLOC(k)|15|
|---|---|
|L_ENDSECTION|15|
|Q_SECTIONTIMER|1|
|T_SECTIONTIMER|10|
|D_SECTIONTIMERSTOPLOC|15|
|Q_ENDTIMER|1|
|T_ENDTIMER|10|
|D_ENDTIMERSTARTLOC|15|
|Q_DANGERPOINT|1|
|D_DP|15|
|V_RELEASEDP|7|
|Q_OVERLAP|1|
|D_STARTOL|15|
|T_OL|10|
|D_OL|15|
|V_RELEASEOL|7|

### 7.4.2.5 Packet Number 16: Repositioning Information

|**_Description_**|Transmission of the upda|te of an MA section||
|---|---|---|---|
|**_Transmitted by_**|Balise|||
|**_Content_**|**Variable**|**Length**|**Comment**|
||NID_PACKET|8||
||Q_DIR|2||
||L_PACKET|13||
||Q_SCALE|2||
||L_SECTION|15||

### 7.4.2.6 Packet Number 21: Gradient Profile

|**_Description_**|Transmission of the gradi|ent.||
|---|---|---|---|
|**_Transmitted by_**|Any|||
|**_Content_**|**Variable**|**Length**|**Comment**|
||NID_PACKET|8||
||Q_DIR|2||
||L_PACKET|13||
||Q_SCALE|2||
||D_GRADIENT|15||
||Q_GDIR|1|0 = downhill 1= uphill|
||G_A|8||

<!-- end of page 19 -->

|N_ITER|5||
|---|---|---|
|D_GRADIENT(k)|15||
|Q_GDIR(k)|1|0 = downhill 1= uphill|
|G_A(k)|8||

### 7.4.2.7 Packet Number 27: International Static Speed Profile

|**_Description_**|Static speed profile and opt<br>train category.|ionally speed|limits depending on the international|
|---|---|---|---|
|**_Transmitted by_**|Any|||
|**_Content_**|**Variable**|**Length**|**Comment**|
||NID_PACKET|8||
||Q_DIR|2||
||L_PACKET|13||
||Q_SCALE|2||
||D_STATIC|15||
||V_STATIC|7|Basic SSP|
||Q_FRONT|1||
||N_ITER|5||
||Q_DIFF(n)|2||
||NC_CDDIFF(n)|4|If Q_DIFF(n) = 0|
||NC_DIFF(n)|4|If Q_DIFF(n) = 1 or 2|
||V_DIFF(n)|7||
||N_ITER|5||
||D_STATIC(k)|15||
||V_STATIC(k)|7|Basic SSP|
||Q_FRONT(k)|1||
||N_ITER(k)|5||
||Q_DIFF(k,m)|2||
||NC_CDDIFF(k,m)|4|If Q_DIFF(k,m) = 0|
||NC_DIFF(k,m)|4|If Q_DIFF(k,m) = 1 or 2|
||V_DIFF(k,m)|7||

### 7.4.2.7.1 Packet Number 31: RBC transition order for RBC interfaced to FRMCS only

|**_Description_**|Packet to order an RBC tr|ansition||
|---|---|---|---|
|**_Transmitted by_**|Balise, RBC|||
|**_Content_**|**Variable**|**Length**|**Comment**|
||NID_PACKET|8||
||Q_DIR|2||

<!-- end of page 20 -->

|L_PACKET|13||
|---|---|---|
|Q_SCALE|2||
|D_RBCTR|15||
|NID_C|10|“Accepting” RBC identity|
|NID_RBC|14||
|Q_SLEEPSESSION|1||

### 7.4.2.7.2 Packet Number 32: Session Management for RBC interfaced to FRMCS only

|**_Description_**|Packet to give the identity<br>or terminated.|of the RBC wit|h which a session shall be established|
|---|---|---|---|
|**_Transmitted by_**|Balise, RBC|||
|**_Content_**|**Variable**|**Length**|**Comment**|
||NID_PACKET|8||
||Q_DIR|2||
||L_PACKET|13||
||Q_RBC|1||
||NID_C|10|RBC ETCS identity :<br>NID_C not relevant if NID_RBC has<br>value “Contact last known RBC”|
||NID_RBC|14||
||Q_SLEEPSESSION|1||

### 7.4.2.8 Packet Number 39: Track Condition Change of traction system

|**_Description_**|The packet gives informatio|n about chan|ge of the traction system.|
|---|---|---|---|
|**_Transmitted by_**|Any|||
|**_Content_**|**Variable**|**Length**|**Comment**|
||NID_PACKET|8||
||Q_DIR|2||
||L_PACKET|13||
||Q_SCALE|2||
||D_TRACTION|15||
||M_VOLTAGE|4|Identity of the traction system|
||NID_CTRACTION|10|NID_CTRACTION given only if<br>M_VOLTAGE ≠ 0|

### 7.4.2.8.1 Packet Number 40: Track Condition Change of allowed current consumption

|**_Description_**|The packet gives informati|on about change of the allowed current consumption.|
|---|---|---|
|**_Transmitted by_**|Any||
|**_Content_**|**Variable**|**Length**<br>**Comment**|

<!-- end of page 21 -->

|NID_PACKET|8||
|---|---|---|
|Q_DIR|2||
|L_PACKET|13||
|Q_SCALE|2||
|D_CURRENT|15||
|M_CURRENT|10|Allowed current consumption.|

### 7.4.2.9 Packet Number 41: Level Transition Order

**_Description_** Packet to identify where a level transition shall take place. In case of mixed levels, the successive M_LEVELTR’s go from the highest priority level to the lowest one.

|**_Transmitted by_**|Any|||
|---|---|---|---|
|**_Content_**|**Variable**|**Length**|**Comment**|
||NID_PACKET|8||
||Q_DIR|2||
||L_PACKET|13||
||Q_SCALE|2||
||D_LEVELTR|15||
||M_LEVELTR|3||
||NID_NTC|8|If M_LEVELTR = 1 (NTC)|
||L_ACKLEVELTR|15||
||N_ITER|5||
||M_LEVELTR(k)|3||
||NID_NTC(k)|8|If M_LEVELTR(k) = 1 (NTC)|
||L_ACKLEVELTR(k)|15||

### 7.4.2.10 Packet Number 42: Session Management for RBC interfaced to GSM-R

|**_Description_**|Packet to give the identit<br>session shall be establish|y and telepho<br>ed or terminate|ne number of the RBC with which a<br>d.|
|---|---|---|---|
|**_Transmitted by_**|Balise, RBC|||
|**_Content_**|**Variable**|**Length**|**Comment**|
||NID_PACKET|8||
||Q_DIR|2||
||L_PACKET|13||
||Q_RBC|1||
||NID_C|10|RBC ETCS identity :<br>NID_C not relevant if NID_RBC has<br>value “Contact last known RBC”|

<!-- end of page 22 -->

|NID_RBC|14||
|---|---|---|
|NID_RADIO|64|not relevant if NID_RBC has value|
|||“Contact last known RBC”|
|Q_SLEEPSESSION|1||

### 7.4.2.11 Packet Number 44: Data used by applications outside the ERTMS/ETCS system.

|**_Description_**|Messages between trackside a<br>information used by applications ou|nd on-b<br>tside the|oard devices, which contain<br>ERTMS/ETCS system.|
|---|---|---|---|
|**_Transmitted by_**|Any|||
|**_Content_**|**Variable**|**Length**|**Comment**|
||NID_PACKET|8||
||Q_DIR|2||
||L_PACKET|13||
||NID_XUSER|9||
||NID_NTC|8|Only if NID_XUSER = 102<br>(National System functions)|
||Other<br>data,<br>depending<br>on<br>NID_XUSER<br>and,<br>in<br>case<br>NID_XUSER = 102, also on<br>NID_NTC|||

### 7.4.2.11.1 Packet Number 45: Radio Network transition order

|**_Description_**|Packet to give the Radio N<br>identity.|etwork type a|nd, if any, the GSM-R Radio Network|
|---|---|---|---|
|**_Transmitted by_**|Balise, RBC, RIU|||
|**_Content_**|**Variable**|**Length**|**Comment**|
||NID_PACKET|8||
||Q_DIR|2||
||L_PACKET|13||
||Q_NETWORKTYPE|2||
||NID_MN|24|If Q_NETWORTYPE = 1 or 2|

### 7.4.2.11.2 Packet Number 46: Conditional Level Transition Order

|**_Description_**|Packet for a conditional lev<br>the highest priority level to|el transition. The succ<br>the lowest one.|essive M_LEVELTR’s go from|
|---|---|---|---|
|**_Transmitted by_**|Balise|||
|**_Content_**|**Variable**|**Length**|**Comment**|
||NID_PACKET|8||
||Q_DIR|2||
||L_PACKET|13||

<!-- end of page 23 -->

|M_LEVELTR|3||
|---|---|---|
|NID_NTC|8|If M_LEVELTR = 1 (NTC)|
|N_ITER|5||
|M_LEVELTR(k)|3||
|NID_NTC(k)|8|If M_LEVELTR(k) = 1 (NTC)|

### 7.4.2.12 Packet Number 49: List of Balise Groups for SH Area

|**_Description_**|Used to list balise group(s)|which the tra|in can pass over in SH mode|
|---|---|---|---|
|**_Transmitted by_**|Any|||
|**_Content_**|**Variable**|**Length**|**Comment**|
||NID_PACKET|8||
||Q_DIR|2||
||L_PACKET|13||
||N_ITER|5||
||Q_NEWCOUNTRY(k)|1||
||NID_C(k)|10|if Q_NEWCOUNTRY(k) = 1|
||NID_BG(k)|14||

### 7.4.2.13 Packet Number 51: Axle Load Speed Profile

|**_Description_**|This packet gives the axle load|speed restr|ictions|
|---|---|---|---|
|**_Transmitted by_**|Any|||
|**_Content_**|**Variable**|**Length**|**Comment**|
||NID_PACKET|8||
||Q_DIR|2||
||L_PACKET|13||
||Q_SCALE|2||
||Q_TRACKINIT|1||
||D_TRACKINIT|15|Only if Q_TRACKINIT = 1|
||D_AXLELOAD|15|Only<br>if<br>Q_TRACKINIT<br>=<br>0,<br>D_AXLELOAD and the following<br>variables follow|
||L_AXLELOAD|15||
||Q_FRONT|1||
||N_ITER|5||
||M_AXLELOADCAT(n)|7||
||V_AXLELOAD(n)|7|Speed restriction to be applied if the<br>axle load category of the train =<br>M_AXLELOADCAT(n)|

<!-- end of page 24 -->

|N_ITER|5||
|---|---|---|
|D_AXLELOAD(k)|15||
|L_AXLELOAD(k)|15||
|Q_FRONT(k)|1||
|N_ITER(k)|5||
|M_AXLELOADCAT(k,m)|7||
|V_AXLELOAD(k,m)|7|Speed restriction to be applied if the<br>axle load category of the train =<br>M_AXLELOADCAT(k,m)|

### 7.4.2.13.1 Packet Number 52: Permitted Braking Distance Information

|**_Description_**|This packet requests the<br>ensure a given permitted b|on-board cal<br>rake distance|culation of speed restrictions which<br>in case of an EB, or SB, intervention|
|---|---|---|---|
|**_Transmitted by_**|Any|||
|**_Content_**|**Variable**|**Length**|**Comment**|
||NID_PACKET|8||
||Q_DIR|2||
||L_PACKET|13||
||Q_SCALE|2||
||Q_TRACKINIT|1||
||D_TRACKINIT|15|Only if Q_TRACKINIT = 1|
||D_PBD|15|Only if Q_TRACKINIT = 0, D_PBD<br>and the following variables follow|
||Q_GDIR|1|0 = downhill, 1 = uphill|
||G_PBDSR|8|Gradient value to be used for the<br>calculation|
||Q_PBDSR|1||
||D_PBDSR|15||
||L_PBDSR|15||
||N_ITER|5||
||D_PBD(k)|15||
||Q_GDIR(k)|1|0 = downhill, 1 = uphill|
||G_PBDSR(k)|8|Gradient value to be used for the<br>calculation|
||Q_PBDSR(k)|1||
||D_PBDSR(k)|15||
||L_PBDSR(k)|15||

<!-- end of page 25 -->

### 7.4.2.14 Packet Number 57: Movement Authority Request Parameters

|**_Description_**|This packet is intended to<br>has to ask for a movement|give parameters tellin<br>authority.|g when and how often the train|
|---|---|---|---|
|**_Transmitted by_**|RBC|||
|**_Content_**|**Variable**|**Length**|**Comment**|
||NID_PACKET|8||
||Q_DIR|2||
||L_PACKET|13||
||T_MAR|8||
||T_TIMEOUTRQST|10||
||T_CYCRQST|8||

### 7.4.2.15 Packet Number 58: Position Report Parameters

|**_Description_**<br>This packet is intended to give<br>position has to be reported.|parameters telling|when and how often the|
|---|---|---|
|**_Transmitted by_**<br>RBC|||
|**_Content_**<br>**Variable**|**Length**|**Comment**|
|NID_PACKET|8||
|Q_DIR|2||
|L_PACKET|13||
|Q_SCALE|2||
|T_CYCLOC|8||
|D_CYCLOC|15||
|M_LOC|3||
|N_ITER|5||
|D_LOC(k)|15||
|Q_LGTLOC(k)|1||

### 7.4.2.16 Packet Number 63: List of Balise Groups in SR Authority

|**_Description_**|Used to list balise group(s)|which the trai|n can pass over in SR mode|
|---|---|---|---|
|**_Transmitted by_**|RBC|||
|**_Content_**|**Variable**|**Length**|**Comment**|
||NID_PACKET|8||
||Q_DIR|_2_||
||L_PACKET|13||
||N_ITER|5||
||Q_NEWCOUNTRY(k)|1||
||NID_C(k)|10|if Q_NEWCOUNTRY(k) = 1|

<!-- end of page 26 -->

NID_BG(k) 14

### 7.4.2.16.1 Packet Number 64: Inhibition of revocable TSRs from balises in level 2

|**_Description_**|This packet is used to inh|ibit revocable TSRs f|rom balises in level 2.|
|---|---|---|---|
|**_Transmitted by_**|RBC|||
|**_Content_**|**Variable**|**Length**|**Comment**|
||NID_PACKET|8||
||Q_DIR|2||
||L_PACKET|13||

### 7.4.2.17 Packet Number 65: Temporary Speed Restriction

|**_Description_**|Transmission of temporar|y speed restriction.||
|---|---|---|---|
|**_Transmitted by_**|Any|||
|**_Content_**|**Variable**|**Length**|**Comment**|
||NID_PACKET|8||
||Q_DIR|2||
||L_PACKET|13||
||Q_SCALE|2||
||NID_TSR|8||
||D_TSR|15||
||L_TSR|15||
||Q_FRONT|1||
||V_TSR|7||

7.4.2.18 Packet Number 66: Temporary Speed Restriction Revocation

|**_Description_**|Transmission of temporar|y speed restric|tion revocation.|
|---|---|---|---|
|**_Transmitted by_**|Balise, RBC|||
|**_Content_**|**Variable**|**Length**|**Comment**|
||NID_PACKET|8||
||Q_DIR|2||
||L_PACKET|13||
||NID_TSR|8|Identity of TSR to be revoked|

### 7.4.2.19 Packet Number 67: Track Condition Big Metal Masses

|**_Description_**|The packet gives details<br>balise transmission due to|concerning where to ignore integrity check alarms of<br>big metal masses trackside.|
|---|---|---|
|**_Transmitted by_**|Balise, RBC||
|**_Content_**|**Variable**|**Length**<br>**Comment**|
||NID_PACKET|8|

<!-- end of page 27 -->

|Q_DIR|2||
|---|---|---|
|L_PACKET|13||
|Q_SCALE|2||
|D_TRACKCOND|15||
|L_TRACKCOND|15|The distance for which integrity<br>check alarms of balise transmission<br>shall be ignored|
|N_ITER|5||
|D_TRACKCOND(k)|15||
|L_TRACKCOND(k)|15|The distance for which integrity<br>check alarms of balise transmission<br>shall be ignored|

### 7.4.2.20 Packet Number 68: Track Condition

|**_Description_**|The packet gives details con<br>e.g. lower pantograph|cerning the t|rack ahead to support the driver when|
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
||M_TRACKCOND|4||
||N_ITER|5||
||D_TRACKCOND(k)|15||
||L_TRACKCOND(k)|15||
||M_TRACKCOND(k)|4||

### 7.4.2.20.1 Packet Number 69: Track Condition Station Platforms

|**_Description_**|The packet gives details concerning the location<br>for use by the train’s door control system|and height of station platforms|
|---|---|---|
|**_Transmitted by_**|Any||
|**_Content_**|**Variable**<br>**Length**|**Comment**|

<!-- end of page 28 -->

|NID_PACKET|8||
|---|---|---|
|Q_DIR|2||
|L_PACKET|13||
|Q_SCALE|2||
|Q_TRACKINIT|1||
|D_TRACKINIT|15|Only if Q_TRACKINIT = 1|
|D_TRACKCOND|15|Only<br>if<br>Q_TRACKINIT<br>=<br>0,<br>D_TRACKCOND and the following<br>variables follow|
|L_TRACKCOND|15||
|M_PLATFORM|4||
|Q_PLATFORM|2||
|N_ITER|5||
|D_TRACKCOND(k)|15||
|L_TRACKCOND(k)|15||
|M_PLATFORM(k)|4||
|Q_PLATFORM(k)|2||

### 7.4.2.21 Packet Number 70: Route Suitability Data

|**_Description_**|The packet gives the characteristics ne|eded to ent|er a route.|
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
||Q_SUITABILITY|2||
||M_LINEGAUGE|8|If<br>Q_SUITABILITY=<br>loading<br>gauge|
||M_LINEAXLELOADCAT|16|If Q_SUITABILITY= axle load.|
||M_VOLTAGE|4|If Q_SUITABILITY = traction<br>system|

<!-- end of page 29 -->

|NID_CTRACTION|10|If Q_SUITABILITY = traction<br>system and M_VOLTAGE ≠0|
|---|---|---|
|N_ITER|5||
|D_SUITABILITY(k)|15||
|Q_SUITABILITY(k)|2||
|M_LINEGAUGE(k)|8|If Q_SUITABILITY(k) = loading<br>gauge|
|M_LINEAXLELOADCAT(k)|16|If Q_SUITABILITY(k) = axle<br>load.|
|M_VOLTAGE(k)|4|If Q_SUITABILITY(k) = traction<br>system|
|NID_CTRACTION(k)|10|If Q_SUITABILITY(k) = traction<br>system and M_VOLTAGE(k) ≠0|

### 7.4.2.22 Packet number 71: Adhesion factor

|**_Description_**|This packet is used when t<br>to be used in the brake mo|he trackside requests<br>del.|a change of the adhesion factor|
|---|---|---|---|
|**_Transmitted by_**|Any|||
|**_Content_**|**Variable**|**Length**|**Comment**|
||NID_PACKET|8||
||Q_DIR|2||
||L_PACKET|13||
||Q_SCALE|2||
||D_ADHESION|15||
||L_ADHESION|15||
||M_ADHESION|1||

### 7.4.2.23 Packet Number 73: Packet for sending plain text messages

|**_Description_**||||
|---|---|---|---|
|**_Transmitted by_**|Balise, RBC|||
|**_Content_**|**Variable**|**Length**|**Comment**|
||NID_PACKET|8||
||Q_DIR|2||
||L_PACKET|13||
||Q_SCALE|2||
||Q_TEXTCLASS|2||
||Q_TEXTDISPLAY|1|Start/end sub-conditions relation|
||D_TEXTDISPLAY|15|Start sub-condition|
||M_MODETEXTDISPLAY|4|Start sub-condition|

<!-- end of page 30 -->

|M_LEVELTEXTDISPLAY|3|Start sub-condition|
|---|---|---|
|NID_NTC|8|If M_LEVELTEXTDISPLAY = 1<br>(NTC)|
|L_TEXTDISPLAY|15|End sub-condition|
|T_TEXTDISPLAY|10|End sub-condition|
|M_MODETEXTDISPLAY|4|End sub-condition|
|M_LEVELTEXTDISPLAY|3|End sub-condition|
|NID_NTC|8|If M_LEVELTEXTDISPLAY = 1<br>(NTC)|
|Q_TEXTCONFIRM|2||
|Q_CONFTEXTDISPLAY|1|If Q_TEXTCONFIRM ≠ 0|
|Q_TEXTREPORT|1|If Q_TEXTCONFIRM ≠ 0|
|NID_TEXTMESSAGE|8|Only If Q_TEXTREPORT = 1|
|NID_C|10|Only If Q_TEXTREPORT = 1|
|NID_RBC|14|Only If Q_TEXTREPORT = 1|
|L_TEXT|8||
|X_TEXT(L_TEXT)|8||

### 7.4.2.24 Packet Number 74: Packet for sending fixed text messages

|**_Description_**||||
|---|---|---|---|
|**_Transmitted by_**|Balise, RBC|||
|**_Content_**|**Variable**|**Lengt**<br>**h**|**Comment**|
||NID_PACKET|8||
||Q_DIR|2||
||L_PACKET|13||
||Q_SCALE|2||
||Q_TEXTCLASS|2||
||Q_TEXTDISPLAY|1|Start/end sub-conditions relation|
||D_TEXTDISPLAY|15|Start sub-condition|
||M_MODETEXTDISPLAY|4|Start sub-condition|
||M_LEVELTEXTDISPLAY|3|Start sub-condition|
||NID_NTC|8|If M_LEVELTEXTDISPLAY = 1<br>(NTC)|
||L_TEXTDISPLAY|15|End sub-condition|
||T_TEXTDISPLAY|10|End sub-condition|
||M_MODETEXTDISPLAY|4|End sub-condition|
||M_LEVELTEXTDISPLAY|3|End sub-condition|

<!-- end of page 31 -->

|NID_NTC|8|If M_LEVELTEXTDISPLAY = 1<br>(NTC)|
|---|---|---|
|Q_TEXTCONFIRM|2||
|Q_CONFTEXTDISPLAY|1|If Q_TEXTCONFIRM ≠ 0|
|Q_TEXTREPORT|1|If Q_TEXTCONFIRM ≠ 0|
|NID_TEXTMESSAGE|8|Only If Q_TEXTREPORT = 1|
|NID_C|10|Only If Q_TEXTREPORT = 1|
|NID_RBC|14|Only If Q_TEXTREPORT = 1|
|Q_TEXT|8||

### 7.4.2.25 Packet Number 79: Geographical Position Information

|**_Description_**|This packet gives geograph<br>to the train.|ical location inf|ormation for one or multiple references|
|---|---|---|---|
|**_Transmitted by_**|Balise, RBC|||
|**_Content_**|**Variable**|**Length**|**Comment**|
||NID_PACKET|8||
||Q_DIR|2||
||L_PACKET|13||
||Q_SCALE|2||
||Q_NEWCOUNTRY|1||
||NID_C|10|if Q_NEWCOUNTRY = 1|
||NID_BG|14|Geographical Position Reference<br>Balise Group|
||D_POSOFF|15||
||Q_MPOSITION|1|Geographical<br>Position<br>counting<br>direction|
||M_POSITION|24|Track kilometre reference value|
||N_ITER|5||
||Q_NEWCOUNTRY(k)|1||
||NID_C(k)|10|if Q_NEWCOUNTRY(k) = 1|
||NID_BG(k)|14|Geographical Position Reference<br>Balise Group|
||D_POSOFF(k)|15||
||Q_MPOSITION(k)|1|Geographical<br>Position<br>counting<br>direction|
||M_POSITION(k)|24|Track kilometre reference value|

<!-- end of page 32 -->

### 7.4.2.26 Packet Number 80: Mode profile

|**_Description_**|Mode profile associated to|an MA||
|---|---|---|---|
|**_Transmitted by_**|Any|||
|**_Content_**|**Variable**|**Length**|**Comment**|
||NID_PACKET|8||
||Q_DIR|2||
||L_PACKET|13||
||Q_SCALE|2||
||D_MAMODE|15||
||M_MAMODE|2|OS, LS, SH|
||V_MAMODE|7||
||L_MAMODE|15||
||L_ACKMAMODE|15||
||Q_MAMODE|1||
||N_ITER|5||
||D_MAMODE(k)|15||
||M_MAMODE(k)|2|OS, LS, SH|
||V_MAMODE(k)|7||
||L_MAMODE(k)|15||
||L_ACKMAMODE(k)|15||
||Q_MAMODE(k)|1||

### 7.4.2.26.1 Packet Number 88: Level Crossing information

|**_Description_**<br>Level Crossing information|||
|---|---|---|
|**_Transmitted by_**<br>Any|||
|**_Content_**<br>**Variable**|**Length**|**Comment**|
|NID_PACKET|8||
|Q_DIR|2||
|L_PACKET|13||
|Q_SCALE|2||
|NID_LX|8||
|D_LX|15||
|L_LX|15||
|Q_LXSTATUS|1||
|V_LX|7|Only if Q_LXSTATUS = 1|
|Q_STOPLX|1|Only if Q_LXSTATUS = 1|
|L_STOPLX|15|Only if Q_STOPLX = 1|

<!-- end of page 33 -->

### 7.4.2.26.2 Packet Number 90: Track Ahead Free up to level 2 transition location

|**_Description_**|Notification to on-board th<br>transmitting this information|at track ah<br>up to the lev|ead is free from the balise group<br>el 2 transition location|
|---|---|---|---|
|**_Transmitted by_**|Balise|||
|**_Content_**|**Variable**|**Length**|**Comment**|
||NID_PACKET|8||
||Q_DIR|2||
||L_PACKET|13||
||Q_NEWCOUNTRY|1||
||NID_C|10|If Q_NEWCOUNTRY = 1|
||NID_BG|14|Level 2 transition location balise<br>group|

### 7.4.2.27 Packet Number 131: RBC transition order for RBC interfaced to GSM-R

|**_Description_**|Packet to order an RBC tr|ansition||
|---|---|---|---|
|**_Transmitted by_**|Balise, RBC|||
|**_Content_**|**Variable**|**Length**|**Comment**|
||NID_PACKET|8||
||Q_DIR|2||
||L_PACKET|13||
||Q_SCALE|2||
||D_RBCTR|15||
||NID_C|10|“Accepting” RBC identity|
||NID_RBC|14||
||NID_RADIO|64|“Accepting” RBC radio subscriber<br>number|
||Q_SLEEPSESSION|1||

### 7.4.2.28 Packet Number 132: Danger for Shunting information

|**_Description_**|Transmission of the aspe|ct of a shunting signal|
|---|---|---|
|**_Transmitted by_**|Balise||
|**_Content_**|**Variable**|**Length**<br>**Comment**|
||NID_PACKET|8|
||Q_DIR|2|
||L_PACKET|13|
||Q_ASPECT|1|

<!-- end of page 34 -->

### 7.4.2.29 Packet Number 133: Radio infill area information

|**_Description_**||||
|---|---|---|---|
|**_Transmitted by_**|Balise|||
|**_Content_**|**Variable**|**Length**|**Comment**|
||NID_PACKET|8||
||Q_DIR|2||
||L_PACKET|13||
||Q_SCALE|2||
||Q_RIU|1||
||NID_C|10|RIU ETCS identity|
||NID_RIU|14||
||NID_RADIO|64||
||D_INFILL|15||
||NID_C|10|Refers to the next main signal balise<br>group (relevant only for the case of<br>establishing<br>a<br>communication<br>session)|
||NID_BG|14||

### 7.4.2.30 Packet Number 134: EOLM Packet

|**_Description_**<br>This packet announces a l|oop.||
|---|---|---|
|**_Transmitted by_**<br>Balise|||
|**_Content_**<br>**Variable**|**Length**|**Comment**|
|NID_PACKET|8||
|Q_DIR|2||
|L_PACKET|13||
|Q_SCALE|2||
|NID_LOOP|14||
|D_LOOP|15||
|L_LOOP|15||
|Q_LOOPDIR|1||
|Q_SSCODE|4||

### 7.4.2.31 Packet Number 135: Stop Shunting on desk opening

|**_Description_**|Packet to stop Shunting o|n desk opening.||
|---|---|---|---|
|**_Transmitted by_**|Balise|||
|**_Content_**|**Variable**|**Length**|**Comment**|
||NID_PACKET|8||

<!-- end of page 35 -->

|Q_DIR|2|
|---|---|
|L_PACKET|13|

### 7.4.2.32 Packet Number 136: Infill location reference

|**_Description_**|Defines location referenc<br>balise/loop telegram resp|e for all data co<br>ectively, followi|ntained in the same radio message or<br>ng this packet.|
|---|---|---|---|
|**_Transmitted by_**|Balise, loop, RIU|||
|**_Content_**|**Variable**|**Length**|**Comment**|
||NID_PACKET|8||
||Q_DIR|2||
||L_PACKET|13||
||Q_NEWCOUNTRY|1||
||NID_C|10|If Q_NEWCOUNTRY = 1|
||NID_BG|14||

### 7.4.2.33 Packet Number 137: Stop if in Staff Responsible

|**_Description_**|Information to stop a train|in staff responsible.|
|---|---|---|
|**_Transmitted by_**|Balise||
|**_Content_**|**Variable**|**Length**<br>**Comment**|
||NID_PACKET|8|
||Q_DIR|2|
||L_PACKET|13|
||Q_SRSTOP|1|

### 7.4.2.34 Packet Number 138: Reversing area information

|**_Description_**|Used to send start and len|gth of reversing area|to the on-board|
|---|---|---|---|
|**_Transmitted by_**|Any|||
|**_Content_**|**Variable**|**Length**|**Comment**|
||NID_PACKET|8||
||Q_DIR|2||
||L_PACKET|13||
||Q_SCALE|2||
||D_STARTREVERSE|15||
||L_REVERSEAREA|15||

<!-- end of page 36 -->

### 7.4.2.35 Packet Number 139: Reversing supervision information

|**_Description_**|Used to send supervision<br>to the on-board|parameters (distance|to run, speed) of reversing area|
|---|---|---|---|
|**_Transmitted by_**|Any|||
|**_Content_**|**Variable**|**Length**|**Comment**|
||NID_PACKET|8||
||Q_DIR|2||
||L_PACKET|13||
||Q_SCALE|2||
||D_REVERSE|15||
||V_REVERSE|7||

### 7.4.2.36 Packet Number 140: Train running number from RBC

|**_Description_**|Train running number from|RBC||
|---|---|---|---|
|**_Transmitted by_**|RBC|||
|**_Content_**|**Variable**|**Length**|**Comment**|
||NID_PACKET|8||
||Q_DIR|2||
||L_PACKET|13||
||NID_OPERATIONAL|32||

### 7.4.2.37 Packet Number 141: Default Gradient for Temporary Speed Restriction

|**_Description_**|It defines a default gradie<br>profile (packet 21) is avai|nt to be used f<br>lable|or TSR supervision when no gradient|
|---|---|---|---|
|**_Transmitted by_**|Balise|||
|**_Content_**|**Variable**|**Length**|**Comment**|
||NID_PACKET|8||
||Q_DIR|2||
||L_PACKET|13||
||Q_GDIR|1|0 = downhill 1= uphill|
||G_TSR|8||

### 7.4.2.37.1 Packet Number 143: Session Management with neighbouring Radio Infill Unit

|**_Description_**|Packet to give the identit<br>Infill Unit with which a ses|y and telephone number of the neighbouring Radio<br>sion shall be established or terminated.|
|---|---|---|
|**_Transmitted by_**|RIU||
|**_Content_**|**Variable**|**Length**<br>**Comment**|
||NID_PACKET|8|
||Q_DIR|2|

<!-- end of page 37 -->

|L_PACKET|13||
|---|---|---|
|Q_RIU|1||
|NID_C|10|RIU ETCS identity|
|NID_RIU|14||
|NID_RADIO|64||

### 7.4.2.37.2 Packet Number 145: Inhibition of balise group message consistency reaction

|**_Description_**|Indication to on-board that t<br>(service brake command) can<br>in case one or more balise t<br>detected but not decoded.|he balise group message consistency reaction<br>be inhibited for this balise group message only,<br>elegram(s) of the group is/are missed or is/are|
|---|---|---|
|**_Transmitted by_**|Balise||
|**_Content_**|**Variable**|**Length**<br>**Comment**|
||NID_PACKET|8|
||Q_DIR|2|
||L_PACKET|13|

### 7.4.2.37.3 Packet Number 180: LSSMA display toggle order

|**_Description_**|Used to toggle on/off the<br>MA.|display of the|Lowest Supervised Speed within the|
|---|---|---|---|
|**_Transmitted by_**|Any|||
|**_Content_**|**Variable**|**Length**|**Comment**|
||NID_PACKET|8||
||Q_DIR|2||
||L_PACKET|13||
||Q_LSSMA|1||
||T_LSSMA|8|Only if Q_LSSMA = 1|

### 7.4.2.37.4 Packet Number 181: Generic LS function marker

|**_Description_**|Used to enable the generic toggling on/off of the display of the Lowest<br>Supervised Speed within the MA.|
|---|---|
|**_Transmitted by_**|Balise|
|**_Content_**|**Variable**<br>**Length**<br>**Comment**|
||NID_PACKET<br>8|
||Q_DIR<br>2|
||L_PACKET<br>13|

<!-- end of page 38 -->

7.4.2.38 Packet Number 254: Default balise, loop or RIU information

|**_Description_**|Indication to on-board tha<br>contains default informati|t balise telegram, loop message or RIU information<br>on due to a fault of the trackside equipment.|
|---|---|---|
|**_Transmitted by_**|Balise, loop, RIU||
|**_Content_**|**Variable**|**Length**<br>**Comment**|
||NID_PACKET|8|
||Q_DIR|2|
||L_PACKET|13|

### 7.4.2.39 Packet Number 255: End of Information

|**_Description_**|This packet consists only of NID_<br>It acts as a finish flag; the receive<br>message/telegram when receivin<br>field.|PACKET containing 8 bit 1s<br>r will stop reading the remaining part of the<br>g eight bits set to one in the NID_PACKET|
|---|---|---|
|**_Transmitted by_**|Balise, Loop||
|**_Content_**|**Variable**|**Length**<br>**Comment**|
||NID_PACKET|8<br>= 255 (1111 1111)|

<!-- end of page 39 -->

## **7.4.3 PACKETS: TRAIN TO TRACK**

### 7.4.3.1 Packet Number 0: Position Report

|**_Description_**|This packet is used to re<br>additional information (e.g.|port the train<br>mode, level, et|position and speed as well as some<br>c.)|
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
||L_TRAININT|15|If Q_INTEGRITY = “Train integrity<br>confirmed by external source” or<br>“Train integrity  confirmed by driver”|
||V_TRAIN|7||
||Q_DIRTRAIN|2||
||M_MODE|5||
||M_LEVEL|3||
||NID_NTC|8|If M_LEVEL = NTC|

7.4.3.2 Packet Number 1: Position Report based on two balise groups

|**_Description_**|This packet is an extension<br>in case of single balise gro<br>on-board equipment is abl<br>before) to give a direction r<br>report.|of the “standard position report “ packet 0. It is used<br>ups if the orientation of the LRBG is unknown but the<br>e to report a second balise group (the one detected<br>eference for the directional information in the position|
|---|---|---|
|**_Transmitted to_**|RBC, RIU||
|**_Content_**|**Variable**|**Length**<br>**Comment**|
||NID_PACKET|8|
||L_PACKET|13|
||Q_SCALE|2|
||NID_LRBG|10 + 14|

<!-- end of page 40 -->

|NID_PRVLRBG|10 + 14|Used as reference for all directional<br>information in the packet: a move<br>from PRVLRBG towards the LRBG<br>defines the “nominal” direction|
|---|---|---|
|D_LRBG|15||
|Q_DIRLRBG|2|Train<br>orientation<br>according<br>to<br>reference direction|
|Q_DLRBG|2|Train front position according to<br>reference direction|
|L_DOUBTOVER|15||
|L_DOUBTUNDER|15||
|Q_INTEGRITY|2||
|L_TRAININT|15|If Q_INTEGRITY = “Train integrity<br>confirmed by external source” or<br>“Train integrity  confirmed by driver”|
|V_TRAIN|7||
|Q_DIRTRAIN|2|Actual running direction according to<br>reference direction|
|M_MODE|5||
|M_LEVEL|3||
|NID_NTC|8|If M_LEVEL = NTC|

### 7.4.3.3 Packet Number 2: Onboard supported system versions

|**Description**|System versions that the|on-board equipment i|s able to operate|
|---|---|---|---|
|**_Transmitted to_**|RBC, RIU|||
|**_Content_**|**Variable**|**Length**|**Comment**|
||NID_PACKET|8||
||L_PACKET|13||
||M_VERSION|7||
||N_ITER|5||
||M_VERSION (k)|7||

### 7.4.3.4 Packet Number 4: Error reporting

|**_Description_**|Error reporting to the RBC|||
|---|---|---|---|
|**_Transmitted to_**|RBC|||
|**_Content_**|**Variable**|**Length**|**Comment**|
||NID_PACKET|8||
||L_PACKET|13||
||M_ERROR|8|error type identifier|

<!-- end of page 41 -->

### 7.4.3.4.1 Packet Number 5: Train running number

|**_Description_**|Train running number|||
|---|---|---|---|
|**_Transmitted to_**|RBC|||
|**_Content_**|**Variable**|**Length**|**Comment**|
||NID_PACKET|8||
||L_PACKET|13||
||NID_OPERATIONAL|32||

### 7.4.3.4.2 Packet Number 9: Level 2 transition information

|**_Description_**|Identity of the level 2 tran|sition balise group||
|---|---|---|---|
|**_Transmitted to_**|RBC|||
|**_Content_**|**Variable**|**Length**|**Comment**|
||NID_PACKET|8||
||L_PACKET|13||
||NID_LTRBG|10 + 14||

### 7.4.3.4.3 Packet Number 10: Safe consist length information for Supervised Manoeuvre

|**_Description_**|Safe consist length information for Supervi|sed Man|oeuvre.|
|---|---|---|---|
|**_Transmitted_**<br>**_to_**|<br>RBC|||
|**_Content_**|**Variable**|**Lengt**<br>**h**|**Comment**|
||NID_PACKET|8||
||L_PACKET|13||
||Q_SAFECONSISTLENGTH|1||
||L_CONSISTFRONTENGINENOM|12|Only if<br>Q_SAFECONSISTLENGTH = 1,<br>L_CONSISTFRONTENGINENOM<br>and the following variables follow|
||L_CONSISTFRONTENGINEMIN|12||
||L_CONSISTFRONTENGINEMAX|12||
||L_CONSISTREARENGINENOM|12||
||L_CONSISTREARENGINEMIN|12||
||L_CONSISTREARENGINEMAX|12||

### 7.4.3.5 Packet Number 11: Validated train data

|**_Description_**|Validated train data.|
|---|---|
|**_Transmitted to_**|RBC|

<!-- end of page 42 -->

|**_Content_**|**Variable**|**Length**|**Comment**|
|---|---|---|---|
||NID_PACKET|8||
||L_PACKET|13||
||NC_CDTRAIN|4||
||NC_TRAIN|15||
||L_TRAIN|12||
||V_MAXTRAIN|7||
||M_LOADINGGAUGE|8||
||M_AXLELOADCAT|7||
||M_AIRTIGHT|2||
||N_AXLE|10||
||N_ITER|5||
||M_VOLTAGE(k)|4|Identity of the traction system|
||NID_CTRACTION(k)|10|NID_CTRACTION(k) given only if<br>M_VOLTAGE(k) ≠ 0|
||N_ITER|5||
||NID_NTC(k)|8|Type of National System available|

### 7.4.3.5.1 Packet Number 12: Default train data for Supervised Manoeuvre

|**_Description_**|Default train data for Supervi|sed Manoeu|vre.|
|---|---|---|---|
|**_Transmitted to_**|RBC|||
|**_Content_**|**Variable**|**Length**|**Comment**|
||NID_PACKET|8||
||L_PACKET|13||
||NC_CDTRAIN|4||
||NC_TRAIN|15||
||V_MAXTRAIN|7||
||M_LOADINGGAUGE|8||
||M_AXLELOADCAT|7||
||M_AIRTIGHT|2||
||N_AXLE|10||
||N_ITER|5||
||M_VOLTAGE(k)|4|Identity of the traction system|
||NID_CTRACTION(k)|10|NID_CTRACTION(k) given only if<br>M_VOLTAGE(k) ≠ 0|

<!-- end of page 43 -->

7.4.3.6 Packet Number 44: Data used by applications outside the ERTMS/ETCS system.

|**_Description_**|Messages between on-board<br>information used by applications o|and trackside<br>utside the ERT|devices, which contain<br>MS/ETCS system.|
|---|---|---|---|
|**_Transmitted to_**|RBC, RIU|||
|**_Content_**|**Variable**|**Length**|**Comment**|
||NID_PACKET|8||
||L_PACKET|13||
||NID_XUSER|9||
||Other<br>data,<br>depending<br>on<br>NID_XUSER|||

<!-- end of page 44 -->

## **7.4.4 Intentionally deleted**

<!-- end of page 45 -->

# **7.5 Definitions of Variables**

### 7.5.0.1 A_NVMAXREDADH1

|**_Name_**|Maximum deceleration|under reduced adhesion conditions (1)|
|---|---|---|
|**_Description_**|Maximum deceleration|under reduced adhesion conditions applicable for trains:|
||•<br>With brake p<br>•<br>with special/<br>This variable is part of|osition “Passenger train in P”, and<br>additional brakes independent from wheel/rail adhesion.<br>the National Values|
|**_Length of variable_**|**_Minimum Value_**|**_Maximum Value_**<br>**_Resolution/formula_**|
|6 bits|0 m/s<sup>2</sup>|3 m/s<sup>2</sup><br>0.05 m/s<sup>2</sup>|
|**_Special/Reserved Values_**|61|No maximum deceleration, display target information in CSM|
||62|No maximum deceleration, display time to Indication in CSM|
||63|No maximum deceleration, no additional display|

### 7.5.0.2 A_NVMAXREDADH2

|**_Name_**|Maximum deceleration|under reduced adhesion conditions (2)|
|---|---|---|
|**_Description_**|Maximum deceleration<br>•<br>with brake p<br>•<br>without spec<br>This variable is part of|under reduced adhesion conditions applicable for trains:<br>osition “Passenger train in P”, and<br>ial/additional brakes independent from wheel/rail adhesion.<br>the National Values|
|**_Length of variable_**|**_Minimum Value_**|**_Maximum Value_**<br>**_Resolution/formula_**|
|6 bits|0 m/s<sup>2</sup>|3 m/s<sup>2</sup><br>0.05 m/s<sup>2</sup>|
|**_Special/Reserved Values_**|61|No maximum deceleration, display target information in CSM|
||62|No maximum deceleration, display time to Indication in CSM|
||63|No maximum deceleration, no additional display|

### 7.5.0.3 A_NVMAXREDADH3

|**_Name_**|Maximum deceleration|under reduced adhesion cond|itions (3)|
|---|---|---|---|
|**_Description_**|Maximum deceleration<br>•<br>with brake p<br>•<br>with brake p<br>This variable is part of|under reduced adhesion cond<br>osition “Freight train in P”, or<br>osition “Freight train in G”.<br>the National Values|itions applicable for trains:|
|**_Length of variable_**|**_Minimum Value_**|**_Maximum Value_**|**_Resolution/formula_**|
|6 bits|0 m/s<sup>2</sup>|3 m/s<sup>2</sup>|0.05 m/s<sup>2</sup>|
|**_Special/Reserved Values_**|61|No maximum deceleration|, display target information in CSM|
||62|No maximum deceleration|, display time to Indication in CSM|
||63|No maximum deceleration|, no additional display|

### 7.5.0.4 A_NVP12

|**_Name_**|Lower deceleration limit to determine the set of Kv|to be used|
|---|---|---|
|**_Description_**|Lower deceleration limit to determine the set of corr<br>trains.|ection factor Kv to be used for Conventional Passenger|
||This variable is part of the National Values.||
|**_Length of variable_**|**_Minimum Value_**<br>**_Maximum Value_**|**_Resolution/formula_**|

<!-- end of page 46 -->

|6 bits<br>.5.0.5<br>A_NVP23|0 m/s<sup>2</sup>|3.15 m/s<sup>2</sup>|0.05 m/s<sup>2</sup>|
|---|---|---|---|
|**_Name_**|Upper deceleration lim|it to determine the set of Kv|to be used|
|**_Description_**|Upper deceleration lim<br>trains.|it to determine the set of cor|rection factor Kv to be used for Conventional Passenger|
||This variable is part of|the National Values.||
|**_Length of variable_**|**_Minimum Value_**|**_Maximum Value_**|**_Resolution/formula_**|
|6 bits|0 m/s<sup>2</sup>|3.15 m/s<sup>2</sup>|0.05 m/s<sup>2</sup>|

### 7.5.0.5

### 7.5.1.1 D_ADHESION

|**_Name_**|Distance to start of are|a with reduced adhesion fac|tor|
|---|---|---|---|
|**_Description_**||||
|**_Length of variable_**|**_Minimum Value_**|**_Maximum Value_**|**_Resolution/formula_**|
|15 bits<br>.5.1.2<br>D_AXLE|0 cm<br>LOAD|327.670 km|10 cm, 1 m or 10 m depending on Q_SCALE|
|**_Name_**|Incremental distance t|o the start of the next Axle lo|ad speed profile|
|**_Description_**||||
|**_Length of variable_**|**_Minimum Value_**|**_Maximum Value_**|**_Resolution/formula_**|
|15 bits|0 m|327.670 km|10 cm, 1m or 10 m depending on Q_SCALE|

### 7.5.1.2 D_AXLELOAD

### 7.5.1.2.1 D_CURRENT

|**_Name_**|Distance to change of|allowed current consumptio|n|
|---|---|---|---|
|**_Description_**||||
|**_Length of variable_**|**_Minimum Value_**|**_Maximum Value_**|**_Resolution/formula_**|
|15 bits|0 cm|327.670 km|10 cm, 1 m or 10 m depending on Q_SCALE|

### 7.5.1.3 D_CYCLOC

|**_Name_**|Distance between two|position reports from the train||
|---|---|---|---|
|**_Description_**|The train has to report|its position every D_CYCLOC|meters.|
|**_Length of variable_**|**_Minimum Value_**|**_Maximum Value_**|**_Resolution/formula_**|
|15 bits|0 cm|327.660 km|10 cm, 1m or 10 m depends on Q_SCALE|
|**_Special/Reserved Values_**|32767|The train has not to report|cyclically its position.|

### 7.5.1.4 D_DP

|**_Name_**|Distance from the End|of Movement Authority to d|anger point|
|---|---|---|---|
|**_Description_**||||
|**_Length of variable_**|**_Minimum Value_**|**_Maximum Value_**|**_Resolution/formula_**|
|15 bits|0 cm|327.670 km|10 cm, 1m or 10 m depends on Q_SCALE.|

### 7.5.1.5 D_EMERGENCYSTOP

|**_Name_**|Distance to emergenc|y stop location||
|---|---|---|---|
|**_Description_**||||
|**_Length of variable_**|**_Minimum Value_**|**_Maximum Value_**|**_Resolution/formula_**|
|15 bits|0 cm|327.670 km|10 cm, 1m or 10 m depends on Q_SCALE.|

<!-- end of page 47 -->

### 7.5.1.6 D_ENDTIMERSTARTLOC

|**_Name_**|Distance from the End|section timer start location|to the End of Movement Authority|
|---|---|---|---|
|**_Description_**||||
|**_Length of variable_**|**_Minimum Value_**|**_Maximum Value_**|**_Resolution/formula_**|
|15 bits|0 cm|327.670 km|10 cm, 1m or 10 m depends on Q_SCALE|

### 7.5.1.7 D_GRADIENT

|**_Name_**|Incremental distance t|o next change of gradient.||
|---|---|---|---|
|**_Description_**||||
|**_Length of variable_**|**_Minimum Value_**|**_Maximum Value_**|**_Resolution/formula_**|
|15 bits|0 cm|327.670 km|10 cm, 1m or 10 m depends on Q_SCALE.|

### 7.5.1.8 D_INFILL

|**_Name_**|Distance to location w|here to connect/disconnect|to a radio infill unit|
|---|---|---|---|
|**_Description_**||||
|**_Length of variable_**|**_Minimum Value_**|**_Maximum Value_**|**_Resolution/formula_**|
|15 bits|0 cm|327.670 km|10 cm, 1m or 10 m depends on Q_SCALE|

### 7.5.1.9 D_LEVELTR

|**_Name_**|Distance to level trans|ition||
|---|---|---|---|
|**_Description_**||||
|**_Length of variable_**|**_Minimum Value_**|**_Maximum Value_**|**_Resolution/formula_**|
|15 bits|0 cm|327.660 km|10 cm, 1m or 10 m depends on Q_SCALE.|
|**_Special/Reserved Values_**|32767|Now (The level transiti|on is performed upon receipt of the order)|

### 7.5.1.10 D_LINK

|**_Name_**|Incremental linking dis|tance to next linked balise g|roup|
|---|---|---|---|
|**_Description_**||||
|**_Length of variable_**|**_Minimum Value_**|**_Maximum Value_**|**_Resolution/formula_**|
|15 bits|0 cm|327.670 km|10 cm, 1m or 10 m depends on Q_SCALE|

### 7.5.1.11 D_LOC

|**_Name_**|Incremental distance|between locations where the|train has to report its position.|
|---|---|---|---|
|**_Description_**||||
|**_Length of variable_**|**_Minimum Value_**|**_Maximum Value_**|**_Resolution/formula_**|
|15 bits|0 cm|327.670 km|10 cm, 1m or 10 m depends on Q_SCALE|

### 7.5.1.12 D_LOOP

|**_Name_**|Distance between EO|LM and start of loop||
|---|---|---|---|
|**_Description_**|The EOLM specifies t|he distance to the beginning|of the loop transmission|
|**_Length of variable_**|**_Minimum Value_**|**_Maximum Value_**|**_Resolution/formula_**|
|15 bits|0 cm|327.670 km|10 cm, 1m or 10 m depends on Q_SCALE|

### 7.5.1.13 D_LRBG

**_Name_** Distance between the last relevant balise group and the estimated front end of the train (the side of the active cab).

<!-- end of page 48 -->

|**_Description_**||||
|---|---|---|---|
|**_Length of variable_**|**_Minimum Value_**|**_Maximum Value_**|**_Resolution/formula_**|
|15 bits|0 cm|327.660 km|10 cm, 1m or 10 m depends on Q_SCALE|
|**_Special/Reserved Values_**|32767|Unknown or greater tha|n 327.660 km|

### 7.5.1.13.1 D_LX

|**_Name_**|Distance to LX start lo|cation||
|---|---|---|---|
|**_Description_**||||
|**_Length of variable_**|**_Minimum Value_**|**_Maximum Value_**|**_Resolution/formula_**|
|15 bits|0 cm|327.670 km|10 cm, 1m or 10 m depends on Q_SCALE|

### 7.5.1.14 D_MAMODE

|**_Name_**|Incremental distance t|o the start of the next Mode P|rofile|
|---|---|---|---|
|**_Description_**||||
|**_Length of variable_**|**_Minimum Value_**|**_Maximum Value_**|**_Resolution/formula_**|
|15 bits|0 cm|327.670 km|10 cm, 1m or 10 m depends on Q_SCALE|

### 7.5.1.15 D_NVOVTRP

|**_Name_**|Maximum distance for|overriding the train trip||
|---|---|---|---|
|**_Description_**|This variable is part of|the National Values||
|**_Length of variable_**|**_Minimum Value_**|**_Maximum Value_**|**_Resolution/formula_**|
|15 bits|0 cm|327.670 km|10 cm, 1m or 10 m depends on Q_SCALE|

### 7.5.1.16 D_NVPOTRP

|**_Name_**|Maximum distance for|reversing in Post Trip mode||
|---|---|---|---|
|**_Description_**|This variable is part of|the National Values||
|**_Length of variable_**|**_Minimum Value_**|**_Maximum Value_**|**_Resolution/formula_**|
|15 bits|0 cm|327.670 km|10 cm, 1m or 10 m depends on Q_SCALE|

### 7.5.1.17 D_NVROLL

|**_Name_**|Roll away distance lim|it||
|---|---|---|---|
|**_Description_**|This variable is part o<br>Movement Protection<br>may be moved for unc|f the National Values and is<br>and Standstill Supervision. W<br>oupling.|used for Roll Away Protection, Unauthorised Direction<br>ithin the (national/default) limits of D_NVROLL the train|
|**_Length of variable_**|**_Minimum Value_**|**_Maximum Value_**|**_Resolution/formula_**|
|15 bits|0 cm|327.660 km|10 cm, 1m or 10 m depends on Q_SCALE|
|**_Special/Reserved Values_**|32767|||

### 7.5.1.18 D_NVSTFF

|**_Name_**|Maximum distance for|running in Staff Responsibl|e mode|
|---|---|---|---|
|**_Description_**|This variable is part of|the National Values||
|**_Length of variable_**|**_Minimum Value_**|**_Maximum Value_**|**_Resolution/formula_**|
|15 bits|0 cm|327.660 km|10 cm, 1m or 10 m depends on Q_SCALE|
|**_Special/Reserved Values_**|32767|||

<!-- end of page 49 -->

### 7.5.1.19 D_OL

|**_Name_**|The distance from the|End of Movement Authority|to the end of overlap|
|---|---|---|---|
|**_Description_**||||
|**_Length of variable_**|**_Minimum Value_**|**_Maximum Value_**|**_Resolution/formula_**|
|15 bits<br>.5.1.19.1 D_PBD|0 cm|327.670 km|10 cm, 1m or 10 m depends on Q_SCALE.|
|**_Name_**|Permitted Braking Dis|tance||
|**_Description_**||||
|**_Length of variable_**|**_Minimum Value_**|**_Maximum Value_**|**_Resolution/formula_**|
|15 bits|0 cm|327.670 km|10 cm, 1m or 10 m depends on Q_SCALE.|

### 7.5.1.19.1 D_PBD

### 7.5.1.19.2 D_PBDSR

|**_Name_**<br>|Incremental distance to|the start of the next speed|restriction to ensure permitted braking distance|
|---|---|---|---|
|**_Description_**||||
|**_Length of variable_**<br>|**_Minimum Value_**|**_Maximum Value_**|**_Resolution/formula_**|
|15 bits<br>|0 cm|327.670 km|10 cm, 1m or 10 m depends on Q_SCALE.|
|.5.1.20<br>D_POSOFF<br>**_Name_**<br> <br>|<br>Offset from the location<br>kilometre reference.|reference of the geograph|ical position reference balise group to the related track|
|**_Description_**<br> <br>|The geographical posit<br>reference of the geogra|ion reporting function use<br>phical position reference b|s this variables content as an offset from the location<br>alise group to the related track kilometre reference.|
|**_Length of variable_**<br>|**_Minimum Value_**|**_Maximum Value_**|**_Resolution/formula_**|
|15 bits<br>|0 m|327.670 km|10 cm, 1m or 10 m depends on Q_SCALE.|

### 7.5.1.20 D_POSOFF

### 7.5.1.21 D_RBCTR

|**_Name_**|Distance to RBC trans|ition||
|---|---|---|---|
|**_Description_**||||
|**_Length of variable_**|**_Minimum Value_**|**_Maximum Value_**|**_Resolution/formula_**|
|15 bits|0 cm|327.670 km|10 cm, 1m or 10 m depends on Q_SCALE.|

### 7.5.1.22 D_REF

|**_Name_**|Reference distance|||
|---|---|---|---|
|**_Description_**|Distance between the L|RBG and the new shifted loc|ation reference.|
||The positive values are|in the nominal direction of th|e LRBG|
|**_Length of variable_**|**_Minimum Value_**|**_Maximum Value_**|**_Resolution/formula_**|
|16 bits|-327.680 km|327.670 km|10 cm, 1m or 10 m depends on Q_SCALE.|
|**_Special/Reserved Values_**|The negative value are|coded in 2’s complement||

### 7.5.1.23 D_REVERSE

|**_Name_**|Maximum distance to|run in RV mode||
|---|---|---|---|
|**_Description_**|Distance from referen|ce location to end location of|the distance to run in RV mode|
|**_Length of variable_**|**_Minimum Value_**|**_Maximum Value_**|**_Resolution/formula_**|
|15 bits|0 cm|327.660 km|10 cm, 1m or 10 m depends on Q_SCALE|
|**_Special/Reserved Values_**|32767|||

<!-- end of page 50 -->

### 7.5.1.24 D_SECTIONTIMERSTOPLOC

|**_Name_**|Distance from beginnin|g of section to the Section T|ime-out stop location|
|---|---|---|---|
|**_Description_**||||
|**_Length of variable_**|**_Minimum Value_**|**_Maximum Value_**|**_Resolution/formula_**|
|15 bits|0 cm|327.670 km|10 cm, 1m or 10 m depends on Q_SCALE|

### 7.5.1.25 D_SR

|**_Name_**|Distance in SR mode|||
|---|---|---|---|
|**_Description_**|Distance that can be ru|n in SR mode||
|**_Length of variable_**|**_Minimum Value_**|**_Maximum Value_**|**_Resolution/formula_**|
|15 bits|0 cm|327.660 km|10 cm, 1m or 10 m depends on Q_SCALE|
|**_Special/Reserved Values_**|32767|||

### 7.5.1.26 D_STARTOL

|**_Name_**|Distance from the ove|rlap timer start location to th|e End of Movement Authority|
|---|---|---|---|
|**_Description_**||||
|**_Length of variable_**|**_Minimum Value_**|**_Maximum Value_**|**_Resolution/formula_**|
|15 bits|0 cm|327.670 km|10 cm, 1m or 10 m depends on Q_SCALE|

### 7.5.1.27 D_STARTREVERSE

|**_Name_**|Distance to start of rev|ersing permitted area||
|---|---|---|---|
|**_Description_**||||
|**_Length of variable_**|**_Minimum Value_**|**_Maximum Value_**|**_Resolution/formula_**|
|15 bits|0 cm|327.670 km|10 cm, 1m or 10 m depends on Q_SCALE|

### 7.5.1.28 D_STATIC

|**_Name_**|Incremental distance t|o next discontinuity in a inte|rnational SSP profile|
|---|---|---|---|
|**_Description_**||||
|**_Length of variable_**|**_Minimum Value_**|**_Maximum Value_**|**_Resolution/formula_**|
|15 bits|0 cm|327.670 km|10 cm, 1m or 10 m depends on Q_SCALE|

### 7.5.1.29 D_SUITABILITY

|**_Name_**|Distance to change in|route suitability||
|---|---|---|---|
|**_Description_**|The incremental dista|nce to where the route suitab|ility data changes.|
|**_Length of variable_**|**_Minimum Value_**|**_Maximum Value_**|**_Resolution/formula_**|
|15 bits|0 m|327.670 km|10 cm, 1m or 10 m depending on Q_SCALE|

### 7.5.1.30 D_TAFDISPLAY

|**_Name_**|Distance from where|on a track ahead free request s|hall be displayed|
|---|---|---|---|
|**_Description_**||||
|**_Length of variable_**|**_Minimum Value_**|**_Maximum Value_**|**_Resolution/formula_**|
|15 bits|0 cm|327.670 km|10 cm, 1m or 10 m depends on Q_SCALE|
|.5.1.31<br>D_TEXT<br>**_Name_**|DISPLAY<br>Distance from where|on a text shall be displayed||

### 7.5.1.31 D_TEXTDISPLAY

<!-- end of page 51 -->

|**_Description_**||||
|---|---|---|---|
|**_Length of variable_**|**_Minimum Value_**|**_Maximum Value_**|**_Resolution/formula_**|
|15 bits|0 cm|327.660 km|10 cm, 1m or 10 m depends on Q_SCALE|
|**_Special/Reserved Values_**|32767|No “location” sub-condi<br>text|tion specified for the start condition of the display of the|

### 7.5.1.32 D_TRACKINIT

|**_Name_**|Distance to start of em|pty profile||
|---|---|---|---|
|**_Description_**|Distance to where initi|al states of the related track|description in the packet shall be resumed|
|**_Length of variable_**|**_Minimum Value_**|**_Maximum Value_**|**_Resolution/formula_**|
|15 bits|0 m|327.670 km|10 cm, 1m or 10 m depending on Q_SCALE|

### 7.5.1.33 D_TRACKCOND

|**_Name_**|Track condition distan|ce||
|---|---|---|---|
|**_Description_**|The incremental distan|ce to where the track condi|tions change.|
|**_Length of variable_**|**_Minimum Value_**|**_Maximum Value_**|**_Resolution/formula_**|
|15 bits|0 m|327.670 km|10 cm, 1m or 10 m depending on Q_SCALE|

### 7.5.1.34 D_TRACTION

|**_Name_**|Distance to change of|traction||
|---|---|---|---|
|**_Description_**||||
|**_Length of variable_**|**_Minimum Value_**|**_Maximum Value_**|**_Resolution/formula_**|
|15 bits|0 m|327.670 km|10 cm, 1m or 10 m depending on Q_SCALE|

### 7.5.1.35 D_TSR

|**_Name_**|Distance to beginning|of temporary speed restricti|on|
|---|---|---|---|
|**_Description_**||||
|**_Length of variable_**|**_Minimum Value_**|**_Maximum Value_**|**_Resolution/formula_**|
|15 bits|0 cm|327.670 km|10 cm, 1m or 10 m depends on Q_SCALE|

### 7.5.1.36 D_VALIDNV

|**_Name_**|Distance to start of va|lidity of national values||
|---|---|---|---|
|**_Description_**||||
|**_Length of variable_**|**_Minimum Value_**|**_Maximum Value_**|**_Resolution/formula_**|
|15 bits|0 cm|327.660 km|10 cm, 1m or 10 m depends on Q_SCALE|
|**_Special/Reserved Values_**|32767|Now (National Values a|re immediately applicable)|

### 7.5.1.37 G_A

|**_Name_**|Gradient|||
|---|---|---|---|
|**_Description_**|This is the absolute va|lue of the engineered gradient between tw|o defined locations.|
|**_Length of variable_**|**_Minimum Value_**|**_Maximum Value_**|**_Resolution/formula_**|
|8 bits|0|254‰|1‰|
|**_Special/Reserved Values_**|255|Non numerical value telling that th<br>D_GRADIENT(n)|e current gradient description ends at|

<!-- end of page 52 -->

### 7.5.1.37.1 G_PBDSR

|**_Name_**|Default gradient for PB|D Speed restriction|
|---|---|---|
|**_Description_**|Defines a default gra<br>distance|dient to be used for calculation of speed restriction to ensure permitted braking|
|**_Length of variable_**|**_Minimum Value_**|**_Maximum Value_**<br>**_Resolution/formula_**|
|8 bits|0|255‰<br>1‰|

### 7.5.1.38 G_TSR

|**_Name_**|Default gradient for TS|R supervision|
|---|---|---|
|**_Description_**|defines a default gradie|nt to be used for TSR supervision when no gradient profile (packet 21) is available.|
|**_Length of variable_**|**_Minimum Value_**|**_Maximum Value_**<br>**_Resolution/formula_**|
|8 bits|0|255‰<br>1‰|

### 7.5.1.39 L_ACKLEVELTR

|**_Name_**|Length of the acknowl|edgement area in rear of th|e required level|
|---|---|---|---|
|**_Description_**||||
|**_Length of variable_**|**_Minimum Value_**|**_Maximum Value_**|**_Resolution/formula_**|
|15 bits|0 cm|327.670 km|10 cm, 1m or 10 m depends on Q_SCALE|

### 7.5.1.40 L_ACKMAMODE

|**_Name_**|Length of the acknowl|edgement area in rear of the|start of the required mode|
|---|---|---|---|
|**_Description_**||||
|**_Length of variable_**|**_Minimum Value_**|**_Maximum Value_**|**_Resolution/formula_**|
|15 bits|0 cm|327.670 km|10 cm, 1m or 10 m depends on Q_SCALE|

### 7.5.1.41 L_ADHESION

|**_Name_**|Length of reduced adh|esion||
|---|---|---|---|
|**_Description_**|Length for which the r|educed adhesion factor app|ly.|
|**_Length of variable_**|**_Minimum Value_**|**_Maximum Value_**|**_Resolution/formula_**|
|15 bits|0 cm|327.670 km|10 cm, 1 m or 10 m depending on Q_SCALE|
|.5.1.42<br>L_AXLE<br>**_Name_**|LOAD<br>Length of speed restri|ction due to Axle load||
|**_Description_**||||
|**_Length of variable_**|**_Minimum Value_**|**_Maximum Value_**|**_Resolution/formula_**|
|15 bits|0 m|327.670 km|10 cm, 1m or 10 m depending on Q_SCALE|

### 7.5.1.42 L_AXLELOAD

### 7.5.1.42.1 L_CONSISTFRONTENGINEMAX

|**_Name_**|Maximum consist leng|th in front of the engine||
|---|---|---|---|
|**_Description_**|This is the maximum l<br>taking into account the<br>consist length informa|ength of the consist in front<br>active cab, and considerin<br>tion.|of the engine, counted from the front end of the engine<br>g the coupling play and/or any other uncertainties in the|
|**_Length of variable_**|**_Minimum Value_**|**_Maximum Value_**|**_Resolution/formula_**|
|12 bits|0 m|4095 m|1 m|

<!-- end of page 53 -->

### 7.5.1.42.2 L_CONSISTFRONTENGINEMIN

|**_Name_**|Minimum consist lengt|h in front of the engine||
|---|---|---|---|
|**_Description_**|This is the minimum le<br>taking into account the<br>consist length informat|ngth of the consist in front<br>active cab, and considerin<br>ion.|of the engine, counted from the front end of the engine<br>g the coupling play and/or any other uncertainties in the|
|**_Length of variable_**|**_Minimum Value_**|**_Maximum Value_**|**_Resolution/formula_**|
|12 bits|0 m|4095 m|1 m|

### 7.5.1.42.3 L_CONSISTFRONTENGINENOM

|**_Name_**|Nominal consist length|in front of the engine||
|---|---|---|---|
|**_Description_**|This is the nominal len<br>uncertainties in the co<br>the active cab.|gth of the consist in front o<br>nsist length information, cou|f the engine without any coupling play and/or any other<br>nted from the front end of the engine taking into account|
|**_Length of variable_**|**_Minimum Value_**|**_Maximum Value_**|**_Resolution/formula_**|
|12 bits|0 m|4095 m|1 m|

### 7.5.1.42.4 L_CONSISTREARENGINEMAX

|**_Name_**|Maximum consist leng|th in rear of the engine||
|---|---|---|---|
|**_Description_**|This is the maximum l<br>taking into account the<br>consist length informat|ength of the consist in rear<br>active cab, and considerin<br>ion.|of the engine, counted from the front end of the engine<br>g the coupling play and/or any other uncertainties in the|
|**_Length of variable_**|**_Minimum Value_**|**_Maximum Value_**|**_Resolution/formula_**|
|12 bits|0 m|4095 m|1 m|

### 7.5.1.42.5 L_CONSISTREARENGINEMIN

|**_Name_**|Minimum consist lengt|h in rear of the engine||
|---|---|---|---|
|**_Description_**|This is the minimum le<br>taking into account the<br>consist length informat|ngth of the consist in rear<br>active cab, and considerin<br>ion.|of the engine, counted from the front end of the engine<br>g the coupling play and/or any other uncertainties in the|
|**_Length of variable_**|**_Minimum Value_**|**_Maximum Value_**|**_Resolution/formula_**|
|12 bits|0 m|4095 m|1 m|

### 7.5.1.42.6 L_CONSISTREARENGINENOM

|**_Name_**|Nominal consist length|in rear of the engine||
|---|---|---|---|
|**_Description_**|This is the nominal len<br>uncertainties in the co<br>the active cab.|gth of the consist in rear o<br>nsist length information, cou|f the engine without any coupling play and/or any other<br>nted from the front end of the engine taking into account|
|**_Length of variable_**|**_Minimum Value_**|**_Maximum Value_**|**_Resolution/formula_**|
|12 bits|0 m|4095 m|1 m|

### 7.5.1.43 L_DOUBTOVER

|**_Name_**|L_DOUBTOVER|||
|---|---|---|---|
|**_Description_**|L_DOUBTOVER is the|over-reading amount plus|the Q_LOCACC of the LRBG|
|**_Length of variable_**|**_Minimum Value_**|**_Maximum Value_**|**_Resolution/formula_**|
|15 bits|0 cm|327.660 km|10 cm, 1m or 10 m depends on Q_SCALE|
|**_Special/Reserved Values_**|32767|Unknown or greater th|an 327.660 km|
|.5.1.44<br>L_DOUBT<br>**_Name_**|UNDER<br>L_DOUBTUNDER|||

### 7.5.1.44 L_DOUBTUNDER

<!-- end of page 54 -->

|**_Description_**|L_DOUBTUNDER is t|he under-reading amount pl|us the Q_LOCACC of the LRBG|
|---|---|---|---|
|**_Length of variable_**|**_Minimum Value_**|**_Maximum Value_**|**_Resolution/formula_**|
|15 bits|0 cm|327.660 km|10 cm, 1m or 10 m depends on Q_SCALE|
|**_Special/Reserved Values_**|32767|Unknown or greater tha|n 327.660 km|

### 7.5.1.45 L_ENDSECTION

|**_Name_**|Length of the End sec|tion in the MA||
|---|---|---|---|
|**_Description_**||||
|**_Length of variable_**|**_Minimum Value_**|**_Maximum Value_**|**_Resolution/formula_**|
|15 bits|0 cm|327.670 km|10 cm, 1m or 10 m depends on Q_SCALE.|

### 7.5.1.46 L_LOOP

|**_Name_**|Length of loop|||
|---|---|---|---|
|**_Description_**|L_LOOP specifies the|length of the loop starting fr|om the distance indicated by D_LOOP|
|**_Length of variable_**|**_Minimum Value_**|**_Maximum Value_**|**_Resolution/formula_**|
|15 bits|0 cm|327.670 km|10 cm, 1m or 10 m depends on Q_SCALE|

### 7.5.1.46.1 L_LX

|**_Name_**|Length of the LX area|||
|---|---|---|---|
|**_Description_**||||
|**_Length of variable_**|**_Minimum Value_**|**_Maximum Value_**|**_Resolution/formula_**|
|15 bits|0 cm|327.670 km|10 cm, 1m or 10 m depends on Q_SCALE|

### 7.5.1.47 L_MAMODE

|**_Name_**|Length of the area of t|he required mode||
|---|---|---|---|
|**_Description_**||||
|**_Length of variable_**|**_Minimum Value_**|**_Maximum Value_**|**_Resolution/formula_**|
|15 bits|0 cm|327.660 km|10 cm, 1m or 10 m depending on Q_SCALE|
|**_Special/Reserved Values_**|32767|||

### 7.5.1.48 L_MESSAGE

|**_Name_**|Message length|||
|---|---|---|---|
|**_Description_**|L_MESSAGE indicates th<br>in the message header (N|e length of the message i<br>ID_MESSAGE and L_ME|n bytes, including all packets and all variables defined<br>SSAGE also).|
|**_Length of variable_**|**_Minimum Value_**|**_Maximum Value_**|**_Resolution/formula_**|
|10 bits|0|1023|1 Byte|

### 7.5.1.48.1 L_NVKRINT

|**_Name_**|Train length step used|to define the integrated cor|rection factor Kr|
|---|---|---|---|
|**_Description_**|This variable is part of|the National Values||
|**_Length of variable_**|**_Minimum Value_**|**_Maximum Value_**|**_Resolution/formula_**|
|5 bits||||
|**_Special/Reserved Values_**|0|0m||
||1|25m||
||2|50m||

<!-- end of page 55 -->

|3|75m|
|---|---|
|4|100m|
|5|150m|
|6|200m|
|7|300m|
|....|.... (steps of 100m)|
|31|2700m|

### 7.5.1.49 L_PACKET

|**_Name_**|Packet length|||
|---|---|---|---|
|**_Description_**|L_PACKET indicates|the length of the packet in bits, i|ncluding all bits of the packet header|
|**_Length of variable_**|**_Minimum Value_**|**_Maximum Value_**|**_Resolution/formula_**|
|13 bits|0|8191|1 bit|

### 7.5.1.49.1 L_PBDSR

|**_Name_**|Length of speed restri|ction to ensure permitted bra|king distance|
|---|---|---|---|
|**_Description_**||||
|**_Length of variable_**|**_Minimum Value_**|**_Maximum Value_**|**_Resolution/formula_**|
|15 bits|0 cm|327.670 km|10 cm, 1m or 10 m depends on Q_SCALE.|

### 7.5.1.50 L_REVERSEAREA

|**_Name_**|Length of the reversin|g permitted area||
|---|---|---|---|
|**_Description_**||||
|**_Length of variable_**|**_Minimum Value_**|**_Maximum Value_**|**_Resolution/formula_**|
|15 bits|0 cm|327.670 km|10 cm, 1m or 10 m depends on Q_SCALE|

### 7.5.1.51 L_SECTION

|**_Name_**|Length of section in th|e MA||
|---|---|---|---|
|**_Description_**||||
|**_Length of variable_**|**_Minimum Value_**|**_Maximum Value_**|**_Resolution/formula_**|
|15 bits|0 cm|327.670 km|10 cm, 1m or 10 m depends on Q_SCALE|

### 7.5.1.51.1 L_STOPLX

|**_Name_**|Length of the stopping|area in rear of the start loca|tion of the LX area|
|---|---|---|---|
|**_Description_**||||
|**_Length of variable_**|**_Minimum Value_**|**_Maximum Value_**|**_Resolution/formula_**|
|15 bits|0 cm|327.670 km|10 cm, 1m or 10 m depends on Q_SCALE|

### 7.5.1.52 L_TAFDISPLAY

|**_Name_**|Length on which a tra|ck ahead free request shall b|e displayed|
|---|---|---|---|
|**_Description_**||||
|**_Length of variable_**|**_Minimum Value_**|**_Maximum Value_**|**_Resolution/formula_**|
|15 bits|0 cm|327.670 km|10 cm, 1m or 10 m depends on Q_SCALE|

<!-- end of page 56 -->

### 7.5.1.53 L_TEXT

|**_Name_**|Length of text string|||
|---|---|---|---|
|**_Description_**|L_TEXT defines the len|gth of a text string (L_TEXT *|X_TEXT)|
|**_Length of variable_**|**_Minimum Value_**|**_Maximum Value_**|**_Resolution/formula_**|
|8 bits|0|255|1 Text String Element|

### 7.5.1.54 L_TEXTDISPLAY

|**_Name_**|Length on which a tex|t shall be displayed||
|---|---|---|---|
|**_Description_**||||
|**_Length of variable_**|**_Minimum Value_**|**_Maximum Value_**|**_Resolution/formula_**|
|15 bits|0 cm|327.660 km|10 cm, 1m or 10 m depends on Q_SCALE|
|**_Special/Reserved Values_**|32767|No “location” sub-cond<br>text|ition specified for the end condition of the display of the|

### 7.5.1.55 L_TRACKCOND

|**_Name_**|Length for which the d|efined track condition is valid||
|---|---|---|---|
|**_Description_**||||
|**_Length of variable_**|**_Minimum Value_**|**_Maximum Value_**|**_Resolution/formula_**|
|15 bits|0 m|327.670 km|10 cm, 1m or 10 m depending on Q_SCALE|

### 7.5.1.56 L_TRAIN

|**_Name_**|Train length|||
|---|---|---|---|
|**_Description_**|This is the length of th|e train acquired as Train Data|.|
||When the safe con<br>L_CONSISTREAREN<br>RBC with the leading e|sist length is captured as<br>GINEMAX, considering that v<br>ngine/cab located at the very|part of valid Train Data, L_TRAIN is equal to<br>alid Train Data can only be captured and sent to the<br>front of the train.|
|**_Length of variable_**|**_Minimum Value_**|**_Maximum Value_**|**_Resolution/formula_**|
|12 bits|0 m|4095 m|1 m|

### 7.5.1.57 L_TRAININT

|**_Name_**|Confirmed Train length|||
|---|---|---|---|
|**_Description_**|Information sent to the R<br>end of the train at the tim<br>of the train front reported|BC allowing the tracksid<br>e the train was last know<br>to the RBC.|e to retrieve what was the position of the min safe rear<br>n to be integer. It is counted from the estimated position|
|**_Length of variable_**|**_Minimum Value_**|**_Maximum Value_**|**_Resolution/formula_**|
|15 bits|0 m|32767 m|1 m|

### 7.5.1.58 L_TSR

|**_Name_**|Length of the tempora|ry speed restriction||
|---|---|---|---|
|**_Description_**||||
|**_Length of variable_**|**_Minimum Value_**|**_Maximum Value_**|**_Resolution/formula_**|
|15 bits|0 cm|327.670 km|10 cm, 1m or 10 m depends on Q_SCALE|

### 7.5.1.59 M_ACK

|**_Name_**|Qualifier for acknowledgement request||
|---|---|---|
|**_Description_**|Indicates whether the message must be acknowle|dged or not|
|**_Length of variable_**|**_Minimum Value_**<br>**_Maximum Value_**|**_Resolution/formula_**|

<!-- end of page 57 -->

|1 bit|||
|---|---|---|
|**_Special/Reserved Values_**|0|No acknowledgement required|
||1|Acknowledgement required|

### 7.5.1.60 M_ADHESION

|**_Name_**|Adhesion factor|||
|---|---|---|---|
|**_Description_**||||
|**_Length of variable_**|**_Minimum Value_**|**_Maximum Value_**|**_Resolution/formula_**|
|1 bit||||
|**_Special/Reserved Values_**|0|Slippery rail||
||1|Non slippery rail||

### 7.5.1.61 M_AIRTIGHT

|**_Name_**|airtight system presen|ce||
|---|---|---|---|
|**_Description_**|indicates whether the t|rain is fitted with an airtight|system or not.|
|**_Length of variable_**|**_Minimum Value_**|**_Maximum Value_**|**_Resolution/formula_**|
|2 bits||||
|**_Special/Reserved Values_**|00|Not fitted||
||01|Fitted||
||10|Spare||
||11|Spare||

### 7.5.1.62 M_AXLELOADCAT

|**_Name_**|Axle load category||
|---|---|---|
|**_Description_**|The values allocated<br>equipment to compare<br>For the underlying me<br>INF TSI.<br>The category HS17 (ax<br>HS RST TSI clause 4.2<br>without any negative p<br>= 1.|below correspond to  the axle load categories and it is used by the on-board<br>its axle load category with the axle load category sent by trackside.<br>aning of the axle load categories listed below (with the exception of HS17) refer to<br>le load <= 17t) corresponds to a static load per axle only, as specified in the former<br>.3.2. The introduction of this artefact is necessary to ensure backward compatibility,<br>erformance impact, in case ASPs are used on lines operated with system version X|
|**_Length of variable_**|**_Minimum Value_**|**_Maximum Value_**<br>**_Resolution/formula_**|
|7 bits|||
|**_Special/Reserved Values_**|0|A|
||1|HS17|
||2|B1|
||3|B2|
||4|C2|
||5|C3|
||6|C4|
||7|D2|
||8|D3|
||9|D4|
||10|D4XL|
||11|E4|

<!-- end of page 58 -->

|12|E5|
|---|---|
|13-127|Spare|

### 7.5.1.62.1 M_CURRENT

|**_Name_**|Allowed current consu|mption||
|---|---|---|---|
|**_Description_**|It defines the allowed c|urrent consumption to be u|sed by the train|
|**_Length of variable_**|**_Minimum Value_**|**_Maximum Value_**|**_Resolution/formula_**|
|10 bits|0 A|10000 A|10 A|
|**_Special/Reserved Values_**|1001 - 1022|Spare||
||1023|No restriction for curre|nt consumption|

### 7.5.1.63 M_DUP

|**_Name_**|Duplicate balise|||
|---|---|---|---|
|**_Description_**|Flags to tell whether th|e balise is a duplicate of one|of the adjacent balises.|
|**_Length of variable_**|**_Minimum Value_**|**_Maximum Value_**|**_Resolution/formula_**|
|2 bits||||
|**_Special/Reserved Values_**|00|No duplicates||
||01|This balise is a duplica<br>the balise group).|te of the next balise (seen in the nominal direction of|
||10|This balise is a duplicat<br>of the balise group).|e of the previous balise (seen in the nominal direction|
||11|Spare||

### 7.5.1.64 M_ERROR

|**_Name_**|Identifier of the type of|error||
|---|---|---|---|
|**_Description_**||||
|**_Length of variable_**|**_Minimum Value_**|**_Maximum Value_**|**_Resolution/formula_**|
|8 bits||||
|**_Special/Reserved Values_**|0|Balise group: linking co|nsistency error (ref. 3.16.2.3)|
||1|Linked balise group: m|essage consistency error(ref. 3.16.2.4.1/4)|
||2|Unlinked balise group:|message consistency error (ref. 3.16.2.5)|
||3|Radio: message consis|tency error (ref. 3.16.3.1.1 except 3.16.3.1.1b)|
||4|Radio: sequence error|(ref. 3.16.3.1.1b)|
||5|Radio: safe radio c<br>communication links re|onnection error (ref. 3.16.3.4, to be sent when<br>-established)|
||6|Safety critical fault (ref|4.4.6.1.6 , 4.4.15.1.5)|
||7|Double linking error (3.|16.2.7.1)|
||8|Double repositioning er|ror (3.16.2.7.2)|
||9|Odometer accuracy mo|nitoring: impairment threshold reached (ref. 3.6.8.5)|
||10|Odometer accuracy mo|nitoring: safety threshold reached (ref. 3.6.8.7)|
||11-255|Spare||

### 7.5.1.65 M_LEVEL

|**_Name_**|Current Operating Level|
|---|---|
|**_Description_**||

<!-- end of page 59 -->

|**_Length of variable_**|**_Minimum Value_**|**_Maximum Value_**<br>**_Resolution/formula_**|
|---|---|---|
|3 bits|||
|**_Special/Reserved Values_**|0|Level 0|
||1|Level NTC specified by NID_NTC|
||2|Level 1|
||3|Level 2|
||4-7|Spare|

### 7.5.1.66 M_LEVELTEXTDISPLAY

|**_Name_**|Onboard operating le|vel for text display||
|---|---|---|---|
|**_Description_**|The display of the text<br>from the defined level|starts if the on-board is in th<br>|e defined level/ends if the on-board executes a transition|
|**_Length of variable_**|**_Minimum Value_**|**_Maximum Value_**|**_Resolution/formula_**|
|3 bits||||
|**_Special/Reserved Values_**|0|Level 0||
||1|Level NTC specified b|y NID_NTC|
||2|Level 1||
||3|Level 2||
||4|No “level” sub-conditio<br>the text|n specified for the start/end condition of the display of|
||5-7|Spare||

### 7.5.1.67 M_LEVELTR

|**_Name_**|Required level|||
|---|---|---|---|
|**_Description_**||||
|**_Length of variable_**|**_Minimum Value_**|**_Maximum Value_**|**_Resolution/formula_**|
|3 bits||||
|**_Special/Reserved Values_**|0|Level 0||
||1|Level NTC specified by|NID_NTC|
||2|Level 1||
||3|Level 2||
||4-7|Spare||

### 7.5.1.67.1 M_LINEGAUGE

|**_Name_**|Line gauge|||
|---|---|---|---|
|**_Description_**|Defining which loading|gauge(s) are permitted on|a line (refer to TSI INF)|
|**_Length of variable_**|**_Minimum Value_**|**_Maximum Value_**|**_Resolution/formula_**|
|8 bits|||Bitset|
|**_Special/Reserved Values_**|xxxx xxx1|G1||
||xxxx xx1x|GA||
||xxxx x1xx|GB||
||xxxx 1xxx|GC||
||00000000|Spare||
||xxx1 xxxx|Spare||
||xx1x xxxx|Spare||

<!-- end of page 60 -->

|x1xx xxxx|Spare|
|---|---|
|1xxx xxxx|Spare|

### 7.5.1.67.2 M_LINEAXLELOADCAT

|**_Name_**|Line axle load categories|||
|---|---|---|---|
|**_Description_**|Defining which axle load<br>suitability function|categories are permitted|on a line (refer to TSI INF) in order to perform the Route|
|**_Length of variable_**|**_Minimum Value_**|**_Maximum Value_**|**_Resolution/formula_**|
|16 bits|||Bitset|
|**_Special/Reserved Values_**|xxxx xxxx xxxx xxx1|A||
||xxxx xxxx xxxx xx1x|HS17||
||xxxx xxxx xxxx x1xx|B1||
||xxxx xxxx xxxx 1xxx|B2||
||xxxx xxxx xxx1 xxxx|C2||
||xxxx xxxx xx1x xxxx|C3||
||xxxx xxxx x1xx xxxx|C4||
||xxxx xxxx 1xxx xxxx|D2||
||xxxx xxx1 xxxx xxxx|D3||
||xxxx xx1x xxxx xxxx|D4||
||xxxx x1xx xxxx xxxx|D4XL||
||xxxx 1xxx xxxx xxxx|E4||
||xxx1 xxxx xxxx xxxx|E5||
||0000 0000 0000 0000|Spare||
||xx1x xxxx xxxx xxxx|Spare||
||x1xx xxxx xxxx xxxx|Spare||
||1xxx xxxx xxxx xxxx|Spare||

### 7.5.1.68 M_LOADINGGAUGE

|**_Name_**|Loading gauge|||
|---|---|---|---|
|**_Description_**|Defining the loading g|auge profile of a train (refer|to LOC&PAS TSI)|
|**_Length of variable_**|**_Minimum Value_**|**_Maximum Value_**|**_Resolution/formula_**|
|8 bits||||
|**_Special/Reserved Values_**|0|The train does not fit to|any of the interoperable loading gauge profiles|
||1|G1||
||2|GA||
||3|GB||
||4|GC||
||5-255|Spare||

### 7.5.1.69 M_LOC

|**_Name_**|Special location/mome|nt where the train has to report its position|
|---|---|---|
|**_Description_**|||
|**_Length of variable_**|**_Minimum Value_**|**_Maximum Value_**<br>**_Resolution/formula_**|
|3 bits|||

<!-- end of page 61 -->

|**_Special/Reserved Values_**|000|Now (The position report is sent upon receipt of the order)|
|---|---|---|
||001|Every LRBG compliant balise group.|
||010|Do not send position report on passage of LRBG compliant balise group.|
||011 - 111|Spare|

### 7.5.1.70 M_MAMODE

|**_Name_**|Required mode for a p|art of the MA||
|---|---|---|---|
|**_Description_**||||
|**_Length of variable_**|**_Minimum Value_**|**_Maximum Value_**|**_Resolution/formula_**|
|2 bits||||
|**_Special/Reserved Values_**|00|On Sight||
||01|Shunting||
||10|Limited Supervision||
||11|Spare||

### 7.5.1.71 M_MCOUNT

|**_Name_**|Message counter|||
|---|---|---|---|
|**_Description_**|The purpose of this c<br>group message the tel|ounter is to make it possible<br>egram belongs to.|for the ERTMS/ETCS on-board to detect which balise|
|**_Length of variable_**|**_Minimum Value_**|**_Maximum Value_**|**_Resolution/formula_**|
|8 bits|0|253|Numbers|
|**_Special/Reserved Values_**|254|The telegram never fits|any message of the group|
||255|The telegram fits with a|ll telegrams of the same balise group|

### 7.5.1.72 M_MODE

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
||6|Stand By||
||7|Trip||
||8|Post Trip||
||9|System Failure||
||10|Isolation||
||11|Non Leading||
||12|Limited Supervision||
||13|National System||

<!-- end of page 62 -->

|14|Reversing|
|---|---|
|15|Passive Shunting|
|16|Automatic Driving|
|17|Supervised Manoeuvre|
|18-31|Spare|

### 7.5.1.73 M_MODETEXTDISPLAY

|Name|Onboard operating m|ode for text display||
|---|---|---|---|
|Description|The display of the te<br>transition from the def|xt starts if the on-board is in t<br>ined mode|he defined mode/ends if the on-board executes a|
|Length of variable|Minimum Value|Maximum Value|Resolution/formula|
|4 bits||||
|Special/Reserved Values|0|Full Supervision||
||1|On Sight||
||2|Staff Responsible||
||3|Automatic Driving||
||4|Unfitted||
||5|Supervised Manoeuvre||
||6|Stand By||
||7|Trip||
||8|Post Trip||
||9|Spare||
||10|Spare||
||11|Spare||
||12|Limited Supervision||
||13|Spare||
||14|Reversing||
||15|No “mode” sub-condition<br>the text|specified for the start/end condition of the display of|

### 7.5.1.73.1 M_NVAVADH

|**_Name_**|Weighting factor for av|ailable wheel/rail adhesion||
|---|---|---|---|
|**_Description_**|This variable is part of|the National Values.||
|**_Length of variable_**|**_Minimum Value_**|**_Maximum Value_**|**_Resolution/formula_**|
|5 bits|0|1.00|0.05|
|**_Special/Reserved Values_**|1.05 – 1.55|Spare||

### 7.5.1.74 M_NVCONTACT

|**_Name_**|T_NVCONTACT react|ion||
|---|---|---|---|
|**_Description_**|Indicates the reaction<br>This variable is part of|to be performed when T_NVC<br>the National Values|ONTACT timer elapses|
|**_Length of variable_**|**_Minimum Value_**|**_Maximum Value_**|**_Resolution/formula_**|
|2 bits||||
|**_Special/Reserved Values_**|00|Train trip||
||01|Apply service brake||

<!-- end of page 63 -->

|10|No Reaction|
|---|---|
|11|Spare|

### 7.5.1.75 M_NVDERUN

|**_Name_**|Entry of Driver ID per|mitted while running||
|---|---|---|---|
|**_Description_**|This variable is part of|the National Values||
|**_Length of variable_**|**_Minimum Value_**|**_Maximum Value_**|**_Resolution/formula_**|
|1 bit||||
|**_Special/Reserved Values_**|0|No||
||1|Yes||

### 7.5.1.75.1 M_NVEBCL

|**_Name_**|Confidence level for e|mergency brake safe deceleration on dry r|ails|
|---|---|---|---|
|**_Description_**|This variable is part of<br>Based on the require<br>correction factor Kdry<br>The confidence level<br>individual event: the r<br>least equal to A_brak<br>rails.|the National Values.<br>d confidence level, the on-board equipme<br>_rst(V).<br>on emergency brake safe deceleration r<br>olling stock emergency brake subsystem<br>e_emergency(V) * Kdry_rst(V), when the|nt selects its corresponding rolling stock<br>epresents the probability of the following<br>of the train does ensure a deceleration at<br>emergency brake is commanded on dry|
|**_Length of variable_**|**_Minimum Value_**|**_Maximum Value_**|**_Resolution/formula_**|
|4 bits||||
|**_Special/Reserved Values_**|0|Confidence level = 50 %||
||1|Confidence level = 90 %||
||2|Confidence level = 99 %||
||3|Confidence level = 99.9 %||
||4|Confidence level = 99.99%||
||5|Confidence level = 99.999 %||
||6|Confidence level = 99.9999 %||
||7|Confidence level = 99.99999 %||
||8|Confidence level = 99.999999 %||
||9|Confidence level = 99.9999999 %||
||10-15|Spare||

### 7.5.1.75.2 M_NVKRINT

|**_Name_**|Integrated correction f|actor Kr||
|---|---|---|---|
|**_Description_**|This is the train length|dependent integrated correction|factor.|
||M_NVKRINT(l) is valid|for a train length between L_NV|KRINT(l) and L_NVKRINT(l+1).|
||M_NVKRINT is valid b|etween 0m and L_NVKRINT(1)||
||This variable is part of|the National Values||
|**_Length of variable_**|**_Minimum Value_**|**_Maximum Value_**|**_Resolution/formula_**|
|5 bits|0|1.55|0.05|

### 7.5.1.75.3 M_NVKTINT

|**_Name_**|Integrated correction factor Kt|
|---|---|
|**_Description_**|This variable is part of the National Values|

<!-- end of page 64 -->

|**_Length of variable_**|**_Minimum Value_**|**_Maximum Value_**|**_Resolution/formula_**|
|---|---|---|---|
|5 bits|0|1.55|0.05|

### 7.5.1.75.4 M_NVKVINT

|**_Name_**|Integrated correction f|actor Kv|
|---|---|---|
|**_Description_**|This is the speed dep|endent integrated correction factor.|
||M_NVKVINT(n) is vali|d for an estimated speed between V_NVKVINT(n) and V_NVKVINT(n+1).|
||M_NVKVINT is valid b<br>This variable is part of|etween 0 km/h and V_NVKVINT(1)<br>the National Values|
|**_Length of variable_**|**_Minimum Value_**|**_Maximum Value_**<br>**_Resolution/formula_**|
|7 bits|0|2.54<br>0.02|

### 7.5.1.75.5 M_PLATFORM

|**_Name_**|Type of platform|||
|---|---|---|---|
|**_Description_**|Nominal height of platf|orm above rail level (refer to|TSI infrastructure)|
|**_Length of variable_**|**_Minimum Value_**|**_Maximum Value_**|**_Resolution/formula_**|
|4 bits||||
|**_Special/Reserved Values_**|0000|200 mm||
||0001|300-380 mm||
||0010|550 mm||
||0011|580 mm||
||0100|680 mm||
||0101|685 mm||
||0110|730 mm||
||0111|760 mm||
||1000|840 mm||
||1001|900 mm||
||1010|915 mm||
||1011|920 mm||
||1100|960 mm||
||1101|1100 mm||
||1110 – 1111|Spare||

### 7.5.1.76 M_POSITION

|**_Name_**|Track kilometre reference|value||
|---|---|---|---|
|**_Description_**|The geographical position|reporting function uses th|is variables content as a reference value.|
|**_Length of variable_**|**_Minimum Value_**|**_Maximum Value_**|**_Resolution/formula_**|
|24 bits|0 m|9’999’999  m|1 m|
|**_Special/Reserved Values_**|10’000’000-16’777’214|Spare||
||16’777’215|No more geographical p|osition calculation after this reference location|

### 7.5.1.77 M_TRACKCOND

|**_Name_**|Type of track condition|
|---|---|
|**_Description_**||

<!-- end of page 65 -->

|**_Length of variable_**|**_Minimum Value_**|**_Maximum Value_**<br>**_Resolution/formula_**|
|---|---|---|
|4 bits|||
|**_Special/Reserved Values_**|0000|Non stopping area. Initial state: stopping permitted|
||0001|Tunnel stopping area. Initial state: no tunnel stopping area|
||0010|Sound horn. Initial state: no request for sound horn|
||0011|Powerless section – lower pantograph. Initial state: not powerless section|
||0100|Radio hole (stop supervising T_NVCONTACT). Initial state: supervise<br>T_NVCONTACT|
||0101|Air tightness. Initial state: no request for air tightness|
||0110|Switch off regenerative brake. Initial state: regenerative brake on|
||0111|Switch off eddy current brake for service brake. Initial state: eddy current brake<br>for service brake on|
||1000|Switch off magnetic shoe brake. Initial state: magnetic shoe brake on|
||1001|Powerless section – switch off the main power switch. Initial state: not<br>powerless section|
||1010|Switch off eddy current brake for emergency brake. Initial state: eddy current<br>brake for emergency brake on|
||1011 –1111|Spare|

### 7.5.1.78 M_VOLTAGE

|**_Name_**|Traction System volta|ge|
|---|---|---|
|**_Description_**|It indicates the voltag<br>by an engine<br>The identity of the tr<br>identifier of the tractio|e of the traction system installed on a specific line or respectively that can be used<br>action system is given by M_VOLTAGE and, if M_VOLTAGE ≠ 0, by the country<br>n system (NID_CTRACTION)|
|**_Length of variable_**|**_Minimum Value_**|**_Maximum Value_**<br>**_Resolution/formula_**|
|4 bits|||
|**_Special/Reserved Values_**|0|Line not fitted with any traction system|
||1|AC 25 kV 50 Hz|
||2|AC 15 kV 16.7 Hz|
||3|DC 3 kV|
||4|DC 1.5 kV|
||5|DC 600/750 V|
||6-15|Spare|

### 7.5.1.79 M_VERSION

|**_Name_**|Version of ETCS syst|em||
|---|---|---|---|
|**_Description_**|This gives the version<br>Each part indicates th<br>-<br>The first number<br>-<br>The second num|of the ETCS system<br>e first and second number of<br>distinguishes not compatible<br>ber indicates compatibility wit|the version respectively.<br>versions. (The three MSB’s)<br>hin a version X. (The four LSB’s)|
|**_Length of variable_**|**_Minimum Value_**|**_Maximum Value_**|**_Resolution/formula_**|
|7 bits||||
|**_Special/Reserved Values_**|000 XXXX|Previous versions accor|ding to e.g. EEIG SRS, UIC A200 SRS|
||001 0000|Version 1.0, introduced|in SRS 1.2.0|
||001 0001|Version 1.1, introduced|in SRS 3.3.0|

<!-- end of page 66 -->

|001 0010|Not valid|
|---|---|
|….||
|001 1111|Not valid|
|010 0000|Version 2.0, introduced in SRS 3.3.0|
|010 0001|Version 2.1, introduced in SRS 3.6.0|
|010 0010|Version 2.2, introduced in SRS 4.0.0|
|010 0011|Version 2.3, introduced in SRS 4.0.0|
|010 0100|Not valid|
|…|…|
|010 1111|Not valid|
|011 0000|Version 3.0, introduced in SRS 4.0.0|
|011 0001|Reserved for future use (this is a valid value)|
|…|…|
|111 1111|Reserved for future use (this is a valid value)|

### 7.5.1.79.1 N_AXLE

|**_Name_**|Axle number of the eng|ine||
|---|---|---|---|
|**_Description_**|This gives the number<br>equipment is fitted|of axles of the single un|it (fixed train set or locomotive) in which the onboard|
|**_Length of variable_**|**_Minimum Value_**|**_Maximum Value_**|**_Resolution/formula_**|
|10 bits|0|1022|integers|
|**_Special/Reserved Values_**|1023|Unknown||

### 7.5.1.80 N_ITER

|**_Name_**|Number of iterations o|f a data set following this var|iable in a packet|
|---|---|---|---|
|**_Description_**|If N_ITER is 0 then no|data set is following. Two or|more nested levels of iterations can exist.|
|**_Length of variable_**|**_Minimum Value_**|**_Maximum Value_**|**_Resolution/formula_**|
|5 bits|0|31|integers|

### 7.5.1.81 N_PIG

|**_Name_**|Position in Group|||
|---|---|---|---|
|**_Description_**|Defines the relative po|sition in a balise group||
|**_Length of variable_**|**_Minimum Value_**|**_Maximum Value_**|**_Resolution/formula_**|
|3 bits||||
|**_Special/Reserved Values_**|0|I am the 1<sup>st</sup>||
||…|…||
||7|I am the 8<sup>th</sup>||

### 7.5.1.82 N_TOTAL

|**_Name_**|Total number of balise|(s) in the group||
|---|---|---|---|
|**_Description_**||||
|**_Length of variable_**|**_Minimum Value_**|**_Maximum Value_**|**_Resolution/formula_**|
|3 bits||||
|**_Special/Reserved Values_**|0<br>…|1 balise in the group||

<!-- end of page 67 -->

7 8 balises in the group

### 7.5.1.82.1 NC_CDDIFF

|**_Name_**|Cant Deficiency SSP|category|
|---|---|---|
|**_Description_**<br>|It is the “Cant Deficien<br>Used together with V_<br>speed” given by V_ST<br>|cy” SSP category for which a different value for the static line speed exists.<br>DIFF to permit certain trains to go faster or lower than the “international basic static<br>ATIC.<br> <br>|
|**_Length of variable_**|**_Minimum Value_**|**_Maximum Value_**<br>**_Resolution/formula_**|
|4 bits|0|15|
|**_Special/Reserved Values_**|0|Specific SSP applicable to Cant Deficiency 80 mm|
||1|Specific SSP applicable to Cant Deficiency 100 mm|
||2|Specific SSP applicable to Cant Deficiency 130 mm|
||3|Specific SSP applicable to Cant Deficiency 150 mm|
||4|Specific SSP applicable to Cant Deficiency 165 mm|
||5|Specific SSP applicable to Cant Deficiency 180 mm|
||6|Specific SSP applicable to Cant Deficiency 210 mm|
||7|Specific SSP applicable to Cant Deficiency 225 mm|
||8|Specific SSP applicable to Cant Deficiency 245 mm|
||9|Specific SSP applicable to Cant Deficiency 275 mm|
||10|Specific SSP applicable to Cant Deficiency 300 mm|
||11 - 15|Spare|

### 7.5.1.82.2 NC_CDTRAIN

|**_Name_**|Cant Deficiency Train Ca|tegory||
|---|---|---|---|
|**_Description_**<br>|Cant Deficiency Train cat<br>Thanks to NC_CDTRAIN<br>static speed profile, thank<br>NC_CDTRAIN.<br>A train belongs to one an<br>|egory to which the train belongs.<br>, the train knows the “Cant Deficien<br>s to NC_CDDIFF, the train can sele<br>d only one category of Cant Deficien<br>|cy” SSP it must obey. By receiving a list of<br>ct the “Cant Deficiency” SSP best suiting its<br>cy.<br>|
|**_Length of variable_**|**_Minimum Value_**|**_Maximum Value_**|**_Resolution/formula_**|
|4 bits|0|15||
|**_Special/Reserved Values_**|0|Cant Deficiency 80 mm||
||1|Cant Deficiency 100 mm||
||2|Cant Deficiency 130 mm||
||3|Cant Deficiency 150 mm||
||4|Cant Deficiency 165 mm||
||5|Cant Deficiency 180 mm||
||6|Cant Deficiency 210 mm||
||7|Cant Deficiency 225 mm||
||8|Cant Deficiency 245 mm||
||9|Cant Deficiency 275 mm||
||10|Cant Deficiency 300 mm||
||11 - 15|Spare||

<!-- end of page 68 -->

### 7.5.1.83 NC_DIFF

|**_Name_**|Other specific SSP cat|egory|
|---|---|---|
|**_Description_**|It is the “other specific”<br>Used together with V<br>category to go faster o<br>Value 0 of NC_DIFF c<br>of NC_TRAIN.|SSP category for which a different value for the static line speed exists.<br>_DIFF to permit trains belonging to the corresponding “other international” train<br>r lower than the “international basic static speed” given by V_STATIC.<br>orresponds to the LSB of NC_TRAIN, value 14 of NC_DIFF to MSB (15-bit variable)|
|**_Length of variable_**|**_Minimum Value_**|**_Maximum Value_**<br>**_Resolution/formula_**|
|4 bits|0|15<br>Numbers|
|**_Special/Reserved Values_**|0|Specific SSP applicable to Freight train braked in “P” position|
||1|Specific SSP applicable to Freight train braked in “G” position|
||2|Specific SSP applicable to Passenger train|
||3-15|Spare|

### 7.5.1.84 NC_TRAIN

|**_Name_**|Other International Train C|ategory.|
|---|---|---|
|**_Description_**|Other train category (differ<br>Thanks to NC_TRAIN, the<br>By receiving a list of static<br>Each bit represents one ca<br>A train can belong to variou|ent from Cant Deficiency) to which the train belongs.<br>train knows the “Other specific” SSP category it must consider.<br>speed profile, thanks to NC_DIFF, the train can select the SSP it must obey.<br>tegory.<br>s categories.|
|**_Length of variable_**|**_Minimum Value_**|**_Maximum Value_**<br>**_Resolution/formula_**|
|15 bits||Bitset|
|**_Special/Reserved Values_**|000 0000 0000 0000|Train does not belong to any of the “Other International” Train Category|
||xxx xxxx xxxx xxx1|Freight train braked in “P” position|
||xxx xxxx xxxx xx1x|Freight train braked in “G” position|
||xxx xxxx xxxx x1xx|Passenger train|
||xxx xxxx xxx 1xxx|Spare|
||xxx xxxx xxx1 xxxx|Spare|
||xxx xxxx xx1x xxxx|Spare|
||xxx xxxx x1xx xxxx|Spare|
||xxx xxxx 1xxx xxxx|Spare|
||xxx xxx1 xxxx xxxx|Spare|
||xxx xx1x xxxx xxxx|Spare|
||xxx x1xx xxxx xxxx|Spare|
||xxx 1xxx xxxx xxxx|Spare|
||xx1 xxxx xxxx xxxx|Spare|
||x1x xxxx xxxx xxxx|Spare|
||1xx xxxx xxxx xxxx|Spare|

### 7.5.1.85 NID_BG (Values to be assigned according to 7.3.1.3)

|**_Name_**|Identity number of the|balise group||
|---|---|---|---|
|**_Description_**|Identity number of a ba|lise group or loop within the|country or region defined by NID_C.|
|**_Length of variable_**|**_Minimum Value_**|**_Maximum Value_**|**_Resolution/formula_**|
|14 bits|0|16382|Numbers|

<!-- end of page 69 -->

|**_Special/Reserved Values_**<br>16383|Identity is unknown (only to be used for Linking information)|
|---|---|

### 7.5.1.86 NID_C (Values to be assigned according to 7.3.1.3)

|**_Name_**|Identity number of the c|ountry or region||
|---|---|---|---|
|**_Description_**|Code used to identify th<br>need not necessarily fol|e country or region in which t<br>low administrative or politica|he balise group, the RBC or the RIU is situated. These<br>l boundaries.|
|**_Length of variable_**|**_Minimum Value_**|**_Maximum Value_**|**_Resolution/formula_**|
|10 bits|0|1023|Numbers|

### 7.5.1.86.1 NID_CTRACTION (Values to be assigned according to 7.3.1.3)

|**_Name_**|Country identifier of th|e traction system||
|---|---|---|---|
|**_Description_**|It identifies the informa|tion, additional to M_VOLTAG|E, required to fully define the traction system.|
|**_Length of variable_**|**_Minimum Value_**|**_Maximum Value_**|**_Resolution/formula_**|
|10 bits|0|1023|Numbers|

### 7.5.1.87 NID_EM

|**_Name_**|Emergency message id|entity||
|---|---|---|---|
|**_Description_**|Identifies the number of|the emergency message||
|**_Length of variable_**|**_Minimum Value_**|**_Maximum Value_**|**_Resolution/formula_**|
|4 bits||||

### 7.5.1.88 NID_ENGINE (Values to be assigned according to 7.3.1.3)

|**_Name_**|Onboard ETCS identity|||
|---|---|---|---|
|**_Description_**|The ETCS identity numb|er is uniquely defined for E|RTMS/ETCS purposes|
|**_Length of variable_**|**_Minimum Value_**|**_Maximum Value_**|**_Resolution/formula_**|
|24 bits||||

### 7.5.1.89 NID_LOOP (Values to be assigned according to 7.3.1.3)

|**_Name_**|Identity number of the loop||
|---|---|---|
|**_Description_**|Identity number of a loop within the country or regio|n defined by NID_C given in the EOLM balise header.|
|**_Length of variable_**|**_Minimum Value_**<br>**_Maximum Value_**|**_Resolution/formula_**|
|14 bits|0<br>16383|Numbers|

### 7.5.1.90 NID_LRBG

|**_Name_**|Identity of  last relevant|balise group||
|---|---|---|---|
|**_Description_**|Country/region identity (|NID_C) + balise identity nu|mber of last relevant balise group (NID_BG).|
|**_Length of variable_**|**_Minimum Value_**|**_Maximum Value_**|**_Resolution/formula_**|
|10 + 14 bits||||
|**_Special/Reserved Values_**|16777215|Unknown||

### 7.5.1.90.1 NID_LTRBG

|**_Name_**|Identity of the level 2 transition balise group|
|---|---|
|**_Description_**|Identity of the balise group at the level 2 transition location towards which the train is running.|
||Country/region identity (NID_C) + balise identity number of the level 2 transition location balise group<br>(NID_BG).|

<!-- end of page 70 -->

|**_Length of variable_**|**_Minimum Value_**|**_Maximum Value_**|**_Resolution/formula_**|
|---|---|---|---|
|10 + 14 bits||||

### 7.5.1.90.2 NID_LX

|**_Name_**|Identity number of the|Level Crossing.||
|---|---|---|---|
|**_Description_**||||
|**_Length of variable_**|**_Minimum Value_**|**_Maximum Value_**|**_Resolution/formula_**|
|8 bits|0|255|Number|
|**_Special/Reserved Values_**|0-126|Reserved for non RBC|transmission (balise, loop or radio infill)|
||127-255|Reserved for RBC tran|smission|

### 7.5.1.91 NID_MESSAGE

|**_Name_**|Message identifier|||
|---|---|---|---|
|**_Description_**|Message identifier. Re|gards defined values of NID_|MESSAGE, refer to chapters 8.5.2 and 8.5.3|
|**_Length of variable_**|**_Minimum Value_**|**_Maximum Value_**|**_Resolution/formula_**|
|8 bits|0|255|Numbers|

### 7.5.1.91.1 NID_MN (Values to be assigned according to 7.3.1.3)

|**_Name_**|Identity of GSM-R Ra|dio Network||
|---|---|---|---|
|**_Description_**|The NID_MN identifie<br>consists of up to 6 dig<br>be dialled first. In case<br>character “F”. For furt|s the GSM-R network the G<br>its which are entered left ad<br>the NID_MN is shorter tha<br>her information about NID_M|SM-R Mobile Terminal has to register with. The NID_MN<br>justed into the data field, the leftmost digit is the digit to<br>n 6 digits, the remaining space is to be filled with special<br>N refer to Subset-54.|
|**_Length of variable_**|**_Minimum Value_**|**_Maximum Value_**|**_Resolution/formula_**|
|24 bits|0|999999|Binary Coded Decimal|
|**_Special/Reserved Values_**|For each digit ;|||
||Values A – E|Not Used||
||F|Use value F for digit to|indicate no digit (if number shorter than 6 digits)|

### 7.5.1.92 NID_OPERATIONAL

|**_Name_**|Train Running Numbe|r||
|---|---|---|---|
|**_Description_**|This is the operational<br>entered left adjusted<br>NID_OPERATIONAL|train running number. The<br>into the data field, the left<br>is shorter than 8 digits, the r|NID_OPERATIONAL consists of up to 8 digits which are<br>most digit is the digit to be entered first. In case the<br>emaining space is to be filled with special character “F”.|
|**_Length of variable_**|**_Minimum Value_**|**_Maximum Value_**|**_Resolution/formula_**|
|32 bits|0|9999 9999|Binary Coded Decimal|
|**_Special/Reserved Values_**|For each digit ;|||
||Values A – E|Spare||
||F|Use value F for digit to|indicate no digit (if number shorter than 8 digits)|
||FFFF FFFF|Spare||

### 7.5.1.93 NID_PACKET

|**_Name_**|Packet identifier|||
|---|---|---|---|
|**_Description_**|This is used in the he<br>follows. Regards defin|ader for each packet, allowin<br>ed values of NID_PACKET,.r|g the receiving equipment to identify the data which<br>efer to “packet numbers” in the tables in chapter 7.4.1.|
|**_Length of variable_**|**_Minimum Value_**|**_Maximum Value_**|**_Resolution/formula_**|
|8 bits|0|255|Numbers|

<!-- end of page 71 -->

### 7.5.1.94 NID_PRVLRBG

|**_Name_**|Identity of previous LRB|G||
|---|---|---|---|
|**_Description_**|Previous LRBG detecte<br>direction in-between.<br>Country/region identity (|d when running towards t<br>NID_C) + balise identity n|he balise group identified as LRBG with no change of<br>umber of the previous LRBG (NID_BG).|
|**_Length of variable_**|**_Minimum Value_**|**_Maximum Value_**|**_Resolution/formula_**|
|10 + 14 bits||||
|**_Special/Reserved Values_**|16777215|unknown||

### 7.5.1.95 NID_RADIO (Values to be assigned according to 7.3.1.3)

|**_Name_**|Radio subscriber number.||
|---|---|---|
|**_Description_**|Quoted as a 16 digit decimal number.<br>The number is to be entered “left adjusted” starting w<br>value F shall be added after the least significant digit<br>For further information about NID_RADIO  refer to S|ith the first digit to be dialled. Padding by the special<br>of the number.<br>UBSET-054.|
|**_Length of variable_**|**_Minimum Value_**<br>**_Maximum Value_**|**_Resolution/formula_**|
|64 bits|0<br>9999 9999 9999 9999|Binary Coded Decimal|
|**_Special/Reserved Values_**|For each digit ;||
||Values A – E<br>Not Used||
||F<br>Use value F for digit to in|dicate no digit (if number shorter than 16 digits)|
||FFFF FFFF FFFF FFFF<br>Use the short number sto|red onboard|

### 7.5.1.96 NID_RBC (Values to be assigned according to 7.3.1.3)

|**_Name_**|RBC ETCS identity nu|mber||
|---|---|---|---|
|**_Description_**|This variable provides|the identity of the RBC belongi|ng to NID_C.|
||The RBC ETCS identit|y is given by NID_C + NID_RB|C.|
|**_Length of variable_**|**_Minimum Value_**|**_Maximum Value_**|**_Resolution/formula_**|
|14 bits|0|16 382|Number|
|**_Special/Reserved Values_**|16 383|Contact last known RBC||

### 7.5.1.97 NID_RIU (Values to be assigned according to 7.3.1.3)

|**_Name_**|Identity of radio infill unit|||
|---|---|---|---|
|**_Description_**|This variable provides the|identity of the RIU belonging|to NID_C.|
||The RIU ETCS identity is|given by NID_C + NID_RIU.||
|**_Length of variable_**|**_Minimum Value_**|**_Maximum Value_**|**_Resolution/formula_**|
|14 bits|0|16 383|Number|

### 7.5.1.98 NID_NTC (Values to be assigned according to 7.3.1.3)

|**_Name_**|National System identity||
|---|---|---|
|**_Description_**|Each value of this variab|le represents the identity of a National System.|
|**_Length of variable_**|**_Minimum Value_**|**_Maximum Value_**<br>**_Resolution/formula_**|
|8 bits|0|255|

### 7.5.1.98.1 NID_TEXTMESSAGE

|**_Name_**|Text message identifier|
|---|---|

<!-- end of page 72 -->

|**_Description_**|Identity of a text message|from trackside to be use|d in a report of driver acknowledgement to the RBC|
|---|---|---|---|
|**_Length of variable_**|**_Minimum Value_**|**_Maximum Value_**|**_Resolution/formula_**|
|8 bits|0|255|Number|

### 7.5.1.99 NID_TSR

|**_Name_**|Identity number of Te|mporary Speed Restriction.||
|---|---|---|---|
|**_Description_**||||
|**_Length of variable_**|**_Minimum Value_**|**_Maximum Value_**|**_Resolution/formula_**|
|8 bits|0|255|Number|
|**_Special/Reserved Values_**|0-126|Reserved for non RBC t|ransmission (balise, loop or radio infill)|
||127-254|Reserved for RBC trans|mission|
||255|Non-revocable speed re|striction (applicable for all transmission media)|

### 7.5.1.99.1 NID_VBCMK

|**_Name_**|Marker for Virtual Balise|Cover||
|---|---|---|---|
|**_Description_**||||
|**_Length of variable_**|**_Minimum Value_**|**_Maximum Value_**|**_Resolution/formula_**|
|6 bits|0|63|Number|

### 7.5.1.100 NID_XUSER (Values to be assigned according to 7.3.1.3)

|**_Name_**|Identity of user system|||
|---|---|---|---|
|**_Description_**|Identity of user system fo|r which remainder of pack|et is intended.|
|**_Length of variable_**|**_Minimum Value_**|**_Maximum Value_**|**_Resolution/formula_**|
|9 bits|0|511|Numbers|

### 7.5.1.101 Q_ASPECT

|**_Name_**|Aspect of “danger for|shunting” signal||
|---|---|---|---|
|**_Description_**||||
|**_Length of variable_**|**_Minimum Value_**|**_Maximum Value_**|**_Resolution/formula_**|
|1 bit||||
|**_Special/Reserved Values_**|0|Stop if in SH mode||
||1|Go if in SH mode||

### 7.5.1.101.1 Q_CONFTEXTDISPLAY

|**_Name_**|Qualifier for text confir|mation versus end of text di|splay|
|---|---|---|---|
|**_Description_**|Gives the relationship|between the driver acknowl|edgement and the end condition for text display|
|**_Length of variable_**|**_Minimum Value_**|**_Maximum Value_**|**_Resolution/formula_**|
|1 bit||||
|**_Special/Reserved Values_**|0|Driver acknowledgeme<br>condition|nt always ends the text display, regardless of the end|
||1|Driver acknowledgeme|nt is an additional condition to end the display|

### 7.5.1.102 Q_DANGERPOINT

|**_Name_**|Qualifier for danger point description.|
|---|---|
|**_Description_**|This variable is set to 1 if either a danger point exists or a release speed has to be specified|

<!-- end of page 73 -->

|**_Length of variable_**|**_Minimum Value_**|**_Maximum Value_**|**_Resolution/formula_**|
|---|---|---|---|
|1 bit||||
|**_Special/Reserved Values_**|0|No danger point infor|mation|
||1|Danger point informa|tion to follow|

### 7.5.1.102.1 Q_DIFF

|**_Name_**|Qualifier for specific SS|P categories.||
|---|---|---|---|
|**_Description_**|Indicates the type of sp<br>In case of “other specif<br>Cant Deficiency SSP<br>international” train cate|ecific SSP category<br>ic” SSP, it tells ERTMS/ETCS<br>as selected by on-board (ref<br>gory to which the “other speci|on-board equipment whether it replaces or not the<br>. 3.11.3.2.3), when the train belongs to an “other<br>fic” SSP applies|
|**_Length of variable_**|**_Minimum Value_**|**_Maximum Value_**|**_Resolution/formula_**|
|2 bits||||
|**_Special/Reserved Values_**|0|Cant Deficiency specific|category|
||1|Other specific category,|replaces the Cant Deficiency SSP|
||2|Other specific category,|does not replace the Cant Deficiency SSP|
||3|Spare||

### 7.5.1.102.2 Q_DESK

|**_Name_**|Qualifier for desk clos|ure.||
|---|---|---|---|
|**_Description_**|Indicates whether the|desks of the engine are cl|osed or not|
|**_Length of variable_**|**_Minimum Value_**|**_Maximum Value_**|**_Resolution/formula_**|
|1 bit||||
|**_Special/Reserved Values_**|0|Desks are closed||
||1|A desk is open||

### 7.5.1.103 Q_DIR

|**_Name_**|Validity direction of tra|nsmitted data||
|---|---|---|---|
|**_Description_**|Qualifier to indicate th<br>balise group sending|e relevant validity direction o<br>the information or to direction|f transmitted data, with reference to directionality of the<br>ality of the LRBG, in case of information sent via radio.|
|**_Length of variable_**|**_Minimum Value_**|**_Maximum Value_**|**_Resolution/formula_**|
|2 bits||||
|**_Special/Reserved Values_**|00|Reverse||
||01|Nominal||
||10|Both directions||
||11|Spare||

### 7.5.1.104 Q_DIRLRBG

|**_Name_**|Orientation of the train|in relation to the direction o|f the LRBG|
|---|---|---|---|
|**_Description_**||||
|**_Length of variable_**|**_Minimum Value_**|**_Maximum Value_**|**_Resolution/formula_**|
|2 bits||||
|**_Special/Reserved Values_**|0|Reverse||
||1|Nominal||
||2|Unknown||

<!-- end of page 74 -->

|3|Spare|
|---|---|

### 7.5.1.105 Q_DIRTRAIN

|**_Name_**|Direction of train move|ment in relation to the LRB|G orientation|
|---|---|---|---|
|**_Description_**||||
|**_Length of variable_**|**_Minimum Value_**|**_Maximum Value_**|**_Resolution/formula_**|
|2 bits||||
|**_Special/Reserved Values_**|0|Reverse||
||1|Nominal||
||2|Unknown||
||3|Spare||

### 7.5.1.106 Q_DLRBG

|**_Name_**|Qualifier telling on whi|ch side of the LRBG the est|imated front end is|
|---|---|---|---|
|**_Description_**||||
|**_Length of variable_**|**_Minimum Value_**|**_Maximum Value_**|**_Resolution/formula_**|
|2 bits||||
|**_Special/Reserved Values_**|0|Reverse||
||1|Nominal||
||2|Unknown||
||3|Spare||

### 7.5.1.107 Q_EMERGENCYSTOP

|**_Name_**|Qualifier for emergenc|y stop acknowledgement||
|---|---|---|---|
|**_Description_**|Qualifier to inform the<br>For an unconditional e|RBC about the use of a cond<br>mergency stop, it is set to “n|itional emergency stop by the on-board equipment.<br>ot relevant”|
|**_Length of variable_**|**_Minimum Value_**|**_Maximum Value_**|**_Resolution/formula_**|
|2 bit||||
|**_Special/Reserved Values_**|0|Conditional Emergency<br>3.10.2.2 b) 1<sup>st</sup>and 4<sup>th</sup>bu|Stop accepted, with update of current EOA/LOA (ref<br>llets)|
||1|Conditional Emergency<br>3.10.2.2 b) 2<sup>nd</sup>and 3<sup>rd</sup>b|Stop accepted, with no update of current EOA/LOA (ref<br>ullets)|
||2|Not Relevant (Unconditi|onal Emergency Stop) (ref 3.10.2.3)|
||3|Conditional Emergency<br>stop location (ref 3.10.2.|Stop rejected because train has passed the emergency<br>2 a))|

### 7.5.1.108 Q_ENDTIMER

|**_Name_**|Qualifier to indicate w|hether end section timer info|rmation exists for the End section in the MA|
|---|---|---|---|
|**_Description_**||||
|**_Length of variable_**|**_Minimum Value_**|**_Maximum Value_**|**_Resolution/formula_**|
|1 bit||||
|**_Special/Reserved Values_**|0|No End section timer i|nformation|
||1|End section timer infor|mation to follow|

### 7.5.1.109 Q_FRONT

|**_Name_**<br>Qualifier for validity|end point of profile element|
|---|---|

<!-- end of page 75 -->

|**_Description_**|Qualifier to indicate if a<br>train length delay) or th|speed limit given for a profile<br>e end of the train (train lengt|element is to be applied until the front of the train (no<br>h delay) has left the element|
|---|---|---|---|
|**_Length of variable_**|**_Minimum Value_**|**_Maximum Value_**|**_Resolution/formula_**|
|1 bit||||
|**_Special/Reserved Values_**|0|Train length delay on v|alidity end point of profile element.|
||1|No train length delay o|n validity end point of profile element|

### 7.5.1.110 Q_GDIR

|**_Name_**|Qualifier for gradient sl|ope.||
|---|---|---|---|
|**_Description_**||||
|**_Length of variable_**|**_Minimum Value_**|**_Maximum Value_**|**_Resolution/formula_**|
|1 bit||||
|**_Special/Reserved Values_**|0|downhill||
||1|uphill||

### 7.5.1.111 Q_INFILL

|**_Name_**|Qualifier to indicate w|hether a train is entering or|exiting the radio infill area.|
|---|---|---|---|
|**_Description_**||||
|**_Length of variable_**|**_Minimum Value_**|**_Maximum Value_**|**_Resolution/formula_**|
|1 bit||||
|**_Special/Reserved Values_**|0|Enter||
||1|Exit||

### 7.5.1.112 Q_INTEGRITY

|**_Name_**|Qualifier for train integ|rity status||
|---|---|---|---|
|**_Description_**|Qualifier, identifying t<br>by L_TRAININT|he train integrity information. T|he related confirmed train length information is given|
|**_Length of variable_**|**_Minimum Value_**|**_Maximum Value_**|**_Resolution/formula_**|
|2 bits||||
|**_Special/Reserved Values_**|0|No train integrity informa|tion|
||1|Train integrity confirmed|by external source|
||2|Train integrity confirmed|by driver|
||3|Train integrity lost||

### 7.5.1.112.1 Q_SAFECONSISTLENGTH

|**_Name_**|Qualifier to indicate if t|he safe consist length inform|ation is available|
|---|---|---|---|
|**_Description_**|This variable indicates|if the safe consist length info|rmation is available.|
|**_Length of variable_**|**_Minimum Value_**|**_Maximum Value_**|**_Resolution/formula_**|
|1 bit||||
|**_Special/Reserved Values_**|0|No safe consist length in|formation available|
||1|Safe consist length infor|mation available|

### 7.5.1.113 Q_LGTLOC

|**_Name_**|Qualifier for the specified report location|
|---|---|
|**_Description_**|This qualifier tells whether the train has to report its position when the max safe front end or  when the min<br>safe rear end has over passed the location defined by D_LOC|

<!-- end of page 76 -->

|**_Length of variable_**|**_Minimum Value_**|**_Maximum Value_**|**_Resolution/formula_**|
|---|---|---|---|
|1 bit||||
|**_Special/Reserved Values_**|0|Min safe rear end||
||1|Max safe front end||

### 7.5.1.114 Q_LINK

|**_Name_**|Link Qualifier|||
|---|---|---|---|
|**_Description_**|This qualifier is used t|o mark a balise group as link|ed or unlinked.|
|**_Length of variable_**|**_Minimum Value_**|**_Maximum Value_**|**_Resolution/formula_**|
|1 bit||||
|**_Special/Reserved Values_**|0|Unlinked||
||1|Linked||

### 7.5.1.115 Q_LOCACC

|**_Name_**|Accuracy of the balise l|ocation||
|---|---|---|---|
|**_Description_**|This Qualifier defines th<br>a location accuracy of +|e absolute value of the acc<br>/- 63m)|uracy of the Balise location (i.e., the value 63m  identifies|
|**_Length of variable_**|**_Minimum Value_**|**_Maximum Value_**|**_Resolution/formula_**|
|6 bits|0 m|63 m|1 m|

### 7.5.1.116 Q_LINKORIENTATION

|**_Name_**|Qualifier for the directi|on of the linked balise group||
|---|---|---|---|
|**_Description_**|Indicates whether the|linked balise group will be over|passed by the train in nominal or reverse direction.|
|**_Length of variable_**|**_Minimum Value_**|**_Maximum Value_**|**_Resolution/formula_**|
|1 bit||||
|**_Special/Reserved Values_**|0|The balise group is seen|by the train in reverse direction|
||1|The balise group is seen|by the train in nominal direction|

### 7.5.1.117 Q_LINKREACTION

|**_Name_**|linking reaction|||
|---|---|---|---|
|**_Description_**|Qualifier for the reacti<br>with the balise group l|on to be performed if a linking o<br>inked to.|r a balise group message consistency problem occurs|
|**_Length of variable_**|**_Minimum Value_**|**_Maximum Value_**|**_Resolution/formula_**|
|2 bits||||
|**_Special/Reserved Values_**|00|Train trip||
||01|Apply service brake||
||10|No Reaction||
||11|Spare||

### 7.5.1.118 Q_LOOPDIR

|**_Name_**|Qualifier to indicate th|e direction of the loop||
|---|---|---|---|
|**_Description_**|Indicates LOOP-refere|nce direction in relation to EO|LM direction|
|**_Length of variable_**|**_Minimum Value_**|**_Maximum Value_**|**_Resolution/formula_**|
|1 bit||||
|**_Special/Reserved Values_**|0|Opposite||

<!-- end of page 77 -->

|1<br>Same|
|---|

### 7.5.1.118.0 Q_LSSMA

|**_Name_**|Qualifier for the LSSM|A display||
|---|---|---|---|
|**_Description_**|This qualifier tells whe<br>within the MA|ther the on-board has to to|ggle on/off the display of the lowest supervised speed|
|**_Length of variable_**|**_Minimum Value_**|**_Maximum Value_**|**_Resolution/formula_**|
|1 bit||||
|**_Special/Reserved Values_**|0|Toggle off||
||1|Toggle on||

### 7.5.1.118.1 Q_LXSTATUS

|**_Name_**|LX Protection Status|||
|---|---|---|---|
|**_Description_**|Indicates whether the LX|is protected or not||
|**_Length of variable_**|**_Minimum Value_**|**_Maximum Value_**|**_Resolution/formula_**|
|1 bit||||
|**_Special/Reserved Values_**|0|LX is protected||
||1|LX is not protected||

### 7.5.1.118.2 Q_MAMODE

|**_Name_**|Qualifier to indicate the|supervision of the beginnin|g of the  mode profile|
|---|---|---|---|
|**_Description_**|This qualifier defines w<br>if no temporary SvL sh|hether the beginning of the<br>all be considered with respe|mode profile shall be considered as temporary SvL, or<br>ct to the mode profile.|
|**_Length of variable_**|**_Minimum Value_**|**_Maximum Value_**|**_Resolution/formula_**|
|1 bit||||
|**_Special/Reserved Values_**|0|No temporary SvL to b|e considered with respect to the mode profile|
||1|Beginning of mode pro|file to be considered as temporary SvL|

### 7.5.1.118.3 Q_MARQSTREASON

|**_Name_**|Reason for MA reque|st sending||
|---|---|---|---|
|**_Description_**|Qualifier to indicate th|e reason why the MA request is|sent to the RBC|
|**_Length of variable_**|**_Minimum Value_**|**_Maximum Value_**|**_Resolution/formula_**|
|5 bits|||Bitset|
|**_Special/Reserved Values_**|xxxx1|Start selected by driver||
||xxx1x|Time before reaching the p|erturbation location reached|
||xx1xx|Time before a section time|r/LOA speed timer expires reached|
||x1xxx|Track description deleted||
||1xxxx|TAF up to level 2 transition|location|

### 7.5.1.119 Q_MEDIA

|**_Name_**|Qualifier to indicate th|e type of media||
|---|---|---|---|
|**_Description_**|Indicates whether it is|a balise telegram or a loop|message|
|**_Length of variable_**|**_Minimum Value_**|**_Maximum Value_**|**_Resolution/formula_**|
|1 bit||||
|**_Special/Reserved Values_**|0|Balise||

<!-- end of page 78 -->

|1|Loop|
|---|---|

### 7.5.1.120 Q_MPOSITION

|**_Name_**|Qualifier for track kilo|metre direction.||
|---|---|---|---|
|**_Description_**|Qualifier to indicate th<br>geographical position|e direction of counting of the<br>reference balise group directi|geographical position track kilometre in relation to the<br>onality.|
|**_Length of variable_**|**_Minimum Value_**|**_Maximum Value_**|**_Resolution/formula_**|
|1 bit|0|1||
|**_Special/Reserved Values_**|0|Opposite  (counting do<br>upwards if passed in rev|wnwards if passed in nominal direction or counting<br>erse direction)|
||1|Same (counting upward<br>if passed in reverse dire|s if passed in nominal direction or counting downwards<br>ction)|

### 7.5.1.120.1 Q_NETWORKTYPE

|**_Name_**|Qualifier for the Radio|Network type||
|---|---|---|---|
|**_Description_**|Indicates with which ra|dio communication system(s|) the trackside is fitted.|
|**_Length of variable_**|**_Minimum Value_**|**_Maximum Value_**|**_Resolution/formula_**|
|2 bits||||
|**_Special/Reserved Values_**|0|FRMCS||
||1|FRMCS+GSM-R||
||2|GSM-R||
||3|Spare||

### 7.5.1.121 Q_NEWCOUNTRY

|**_Name_**|New Country Qualifier||
|---|---|---|
|**_Description_**|Qualifier to indicate w<br>one before inside the|hether the next balise group is in the same country / railway administration as the<br>packet or not.|
||For the first balise g<br>administration as the o<br>telegram giving the pa|roup in the packet, if Q_NEWCOUNTRY = 0, it is the same country / railway<br>ne of the LRBG within the radio message, the one of balise group within the balise<br>cket, or the one of the loop within the loop message giving the packet.|
|**_Length of variable_**|**_Minimum Value_**|**_Maximum Value_**<br>**_Resolution/formula_**|
|1 bit|||
|**_Special/Reserved Values_**|0|Same country / railway administration, no NID_C follows|
||1|Not the same country / railway administration, NID_C follows|

### 7.5.1.122 Q_NVDRIVER_ADHES

|**_Name_**|Qualifier for the modifi|cation of trackside adhesio|n factor by driver|
|---|---|---|---|
|**_Description_**|This variable is part of|the National Values||
|**_Length of variable_**|**_Minimum Value_**|**_Maximum Value_**|**_Resolution/formula_**|
|1 bit||||
|**_Special/Reserved Values_**|0|Not allowed||
||1|Allowed||

### 7.5.1.123 Q_NVEMRRLS

|**_Name_**|Qualifier Emergency Brake Release|
|---|---|
|**_Description_**|Qualifier to revoke the emergency brake command when the Permitted Speed limit is no longer exceeded<br>or at standstill (for ceiling speed and target speed monitoring)_._|
||This variable is part of the National Values|

<!-- end of page 79 -->

|**_Length of variable_**|**_Minimum Value_**|**_Maximum Value_**|**_Resolution/formula_**|
|---|---|---|---|
|1 bit||||
|**_Special/Reserved Values_**|0|Revoke emergency brak|e command at standstill|
||1|Revoke emergency brak<br>no longer exceeded|e command when permitted speed supervision limit is|

### 7.5.1.123.1 Q_NVGUIPERM

|**_Name_**|Permission to use the|guidance curve||
|---|---|---|---|
|**_Description_**|This variable is part of|the National Values||
|**_Length of variable_**|**_Minimum Value_**|**_Maximum Value_**|**_Resolution/formula_**|
|1 bit||||
|**_Special/Reserved Values_**|0|No||
||1|Yes||

### 7.5.1.123.2 Q_NVINHSMICPERM

|**_Name_**|Permission to inhibit t|he compensation of the spee|d measurement inaccuracy|
|---|---|---|---|
|**_Description_**|Qualifier to inhibit the<br>related supervision lim<br>This variable is part of|compensation of the speed<br>its.<br>the National Values|measurement inaccuracy for the calculation of the EBI|
|**_Length of variable_**|**_Minimum Value_**|**_Maximum Value_**|**_Resolution/formula_**|
|1 bit||||
|**_Special/Reserved Values_**|0|No||
||1|Yes||

### 7.5.1.123.3 Q_NVKINT

|**_Name_**|Qualifier for integrated|correction factors||
|---|---|---|---|
|**_Description_**|This variable is part of|the National Values||
|**_Length of variable_**|**_Minimum Value_**|**_Maximum Value_**|**_Resolution/formula_**|
|1 bit||||
|**_Special/Reserved Values_**|0|No integrated correctio|n factors follow|
||1|Integrated correction fa|ctors follow|

### 7.5.1.123.4 Q_NVKVINTSET

|**_Name_**|Type of Kv_int set|||
|---|---|---|---|
|**_Description_**||||
|**_Length of variable_**|**_Minimum Value_**|**_Maximum Value_**|**_Resolution/formula_**|
|2 bits||||
|**_Special/Reserved Values_**|00|Freight trains||
||01|Conventional passeng|er trains|
||10-11|Spare||

### 7.5.1.123.5 Q_NVLOCACC

|**_Name_**|Default accuracy of the balise location (absolute value)||
|---|---|---|
|**_Description_**|This variable is part of the National Values||
|**_Length of variable_**|**_Minimum Value_**<br>**_Maximum Value_**|**_Resolution/formula_**|

<!-- end of page 80 -->

|6 bits|0 m|63 m|1 m|
|---|---|---|---|
|.5.1.123.6 Q_NVSBF<br>**_Name_**|BPERM<br>Permission to use the|service brake feedback||
|**_Description_**|This variable is part of|the National Values||
|**_Length of variable_**|**_Minimum Value_**|**_Maximum Value_**|**_Resolution/formula_**|
|1 bit||||
|**_Special/Reserved Values_**|0|No||
||1|Yes||

### 7.5.1.123.6 Q_NVSBFBPERM

### 7.5.1.124 Q_NVSBTSMPERM

|**_Name_**|Permission to use ser|vice brake in target speed m|onitoring|
|---|---|---|---|
|**_Description_**|This variable is part of|the National Values||
|**_Length of variable_**|**_Minimum Value_**|**_Maximum Value_**|**_Resolution/formula_**|
|1 bit||||
|**_Special/Reserved Values_**|0|No||
||1|Yes||

### 7.5.1.125 Q_ORIENTATION

|**_Name_**|Co-ordinate system  a|ssigned to a single balise group||
|---|---|---|---|
|**_Description_**|The co-ordinate syste<br>LRBG in a position rep|m is assigned by the RBC to a b<br>ort based on two balise groups.|alise group reported by the on-board equipment as|
|**_Length of variable_**|**_Minimum Value_**|**_Maximum Value_**|**_Resolution/formula_**|
|1 bit||||
|**_Special/Reserved Values_**|0|Reverse||
||1|Nominal||

### 7.5.1.126 Q_OVERLAP

|**_Name_**|Qualifier to tell whethe|r there is an overlap||
|---|---|---|---|
|**_Description_**|This variable is set to|1 if either an overlap exists or a rel|ease speed has to be specified|
|**_Length of variable_**|**_Minimum Value_**|**_Maximum Value_**|**_Resolution/formula_**|
|1 bit||||
|**_Special/Reserved Values_**|0|No overlap information||
||1|Overlap information to follow||

### 7.5.1.126.1 Q_PBDSR

|**_Name_**|Qualifier for Permitted|Braking Distance||
|---|---|---|---|
|**_Description_**|Qualifier defining whet<br>Emergency Brake|her the permitted braking dista|nce is to be achieved with the Service Brake or|
|**_Length of variable_**|**_Minimum Value_**|**_Maximum Value_**|**_Resolution/formula_**|
|1 bit||||
|**_Special/Reserved Values_**|0|EB intervention requested||
||1|SB intervention requested||

### 7.5.1.126.2 Q_PLATFORM

|**_Name_**|Platform position (relative to direction of authorised movement)|
|---|---|

<!-- end of page 81 -->

|**_Description_**||||
|---|---|---|---|
|**_Length of variable_**|**_Minimum Value_**|**_Maximum Value_**|**_Resolution/formula_**|
|2 bits||||
|**_Special/Reserved Values_**|00|Platform on left side||
||01|Platform on right side||
||10|Platform on both sides||
||11|Spare||

### 7.5.1.127 Q_RBC

|**_Name_**|Qualifier for communi|cation session order||
|---|---|---|---|
|**_Description_**||||
|**_Length of variable_**|**_Minimum Value_**|**_Maximum Value_**|**_Resolution/formula_**|
|1 bit||||
|**_Special/Reserved Values_**|0|Terminate communicati|on session|
||1|Establish communicatio|n session|

### 7.5.1.128 Q_RIU

|**_Name_**|Qualifier for communi|cation session order||
|---|---|---|---|
|**_Description_**||||
|**_Length of variable_**|**_Minimum Value_**|**_Maximum Value_**|**_Resolution/formula_**|
|1 bit||||
|**_Special/Reserved Values_**|0|Terminate communicati|on session|
||1|Establish communicatio|n session|

### 7.5.1.129 Q_SCALE

|**_Name_**|Qualifier for the distan|ce/length scale.||
|---|---|---|---|
|**_Description_**|Qualifier to indicate th<br>Q_SCALE.|e same scale used for describ|ing all distances/lengths inside the packet that contains|
|**_Length of variable_**|**_Minimum Value_**|**_Maximum Value_**|**_Resolution/formula_**|
|2 bits||||
|**_Special/Reserved Values_**|0|10 cm scale||
||1|1 m scale||
||2|10 m scale||
||3|Spare||

### 7.5.1.130 Q_SECTIONTIMER

|**_Name_**|Qualifier to indicate w|hether there is a Section Tim|e-Out related to the section|
|---|---|---|---|
|**_Description_**||||
|**_Length of variable_**|**_Minimum Value_**|**_Maximum Value_**|**_Resolution/formula_**|
|1 bit||||
|**_Special/Reserved Values_**|0|No Section Timer infor|mation|
||1|Section Timer informati|on to follow|

### 7.5.1.131 Q_SLEEPSESSION

|**_Name_**|Session management for sleeping equipment|
|---|---|

<!-- end of page 82 -->

|**_Description_**|Qualifier for a Sleepin|g onboard equipment to exe|cute or not the “session establishment/termination” order|
|---|---|---|---|
|**_Length of variable_**|**_Minimum Value_**|**_Maximum Value_**|**_Resolution/formula_**|
|1 bit||||
|**_Special/Reserved Values_**|0|Ignore session establis|hment/termination order|
||1|Execute session estab|lishment/termination order|

### 7.5.1.132 Q_SRSTOP

|**_Name_**|“Stop if in Staff Respo|nsible” information||
|---|---|---|---|
|**_Description_**|Specifies whether an|onboard equipment in staff re|sponsible has to stop or not|
|**_Length of variable_**|**_Minimum Value_**|**_Maximum Value_**|**_Resolution/formula_**|
|1 bit||||
|**_Special/Reserved Values_**|0|Stop if in SR mode||
||1|Go if in SR mode||

### 7.5.1.133 Q_SSCODE

|**_Name_**|Spread Spectrum Cod|e for Euroloop||
|---|---|---|---|
|**_Description_**|Specifies the code req|uired to receive telegrams fr|om a specific Euroloop installation.|
|**_Length of variable_**|**_Minimum Value_**|**_Maximum Value_**|**_Resolution/formula_**|
|4 bits|0|14||
|**_Special/Reserved Values_**|15|Code reserved for test p|urposes|

### 7.5.1.134 Q_STATUSLRBG

|**_Name_**|Status of SoM position|report in relation to the LRB|G|
|---|---|---|---|
|**_Description_**|It provides the status|of the SoM position report in|relation to the LRBG|
|**_Length of variable_**|**_Minimum Value_**|**_Maximum Value_**|**_Resolution/formula_**|
|2 bits||||
|**_Special/Reserved Values_**|00|Invalid train position ref|erred to an LRBG|
||01|Valid train position refe|rred to an LRBG|
||10|No train position referre|d to an LRBG|
||11|spare||

### 7.5.1.134.1 Q_STOPLX

|**_Name_**|Qualifier for stopping i|n rear of the LX||
|---|---|---|---|
|**_Description_**|Indicates whether stop|ping the train in rear of a non|protected LX is required|
|**_Length of variable_**|**_Minimum Value_**|**_Maximum Value_**|**_Resolution/formula_**|
|1 bit||||
|**_Special/Reserved Values_**|0|No stop required||
||1|Stop required||

### 7.5.1.135 Q_SUITABILITY

|**_Name_**|Type of route suitabilit|y data||
|---|---|---|---|
|**_Description_**||||
|**_Length of variable_**|**_Minimum Value_**|**_Maximum Value_**|**_Resolution/formula_**|
|2 bits||||
|**_Special/Reserved Values_**|00|Loading gauge||

<!-- end of page 83 -->

|01|Axle load|
|---|---|
|10|Traction system|
|11|Spare|

### 7.5.1.136 Q_TEXT

|**_Name_**|Fixed message to be|displayed.||
|---|---|---|---|
|**_Description_**|Q_TEXT is a pointer t<br>driver for the DMI sha|o select a fixed text message<br>ll be used additionally as a qu|from the defined table. The language selected by the<br>alifier to choose the appropriate language table.|
|**_Length of variable_**|**_Minimum Value_**|**_Maximum Value_**|**_Resolution/formula_**|
|8 bits|0|255||
|**_Special/Reserved Values_**|0|“Level crossing not prote|cted”|
||1|“Acknowledgement”||
||2-255|Spare||

### 7.5.1.137 Q_TEXTCLASS

|**_Name_**|Class of message to b|e displayed.||
|---|---|---|---|
|**_Description_**|Q_TEXTCLASS specif<br>message)|ies the class of the text mess|age included in the same packet (either plain or fixed|
|**_Length of variable_**|**_Minimum Value_**|**_Maximum Value_**|**_Resolution/formula_**|
|2 bits||||
|**_Special/Reserved Values_**|00|Auxiliary Information||
||01|Important Information||
||10|Spare||
||11|Spare||

### 7.5.1.138 Q_TEXTCONFIRM

|**_Name_**|Qualifier for text confir|mation||
|---|---|---|---|
|**_Description_**||||
|**_Length of variable_**|**_Minimum Value_**|**_Maximum Value_**|**_Resolution/formula_**|
|2 bits||||
|**_Special/Reserved Values_**|00|No confirmation required||
||01|Confirmation required||
||10|Confirmation required: co<br>end condition is fulfilled,<br>the driver|mmand application of the service brake when display<br>unless the text has already been acknowledged by|
||11|Confirmation required: c<br>display end condition<br>acknowledged by the dri|ommand application of the emergency brake when<br>is fulfilled, unless the text has already been<br>ver|

### 7.5.1.139 Q_TEXTDISPLAY

|**_Name_**|Qualifier for the combi|nation of text message sub-|condition|
|---|---|---|---|
|**_Description_**|Q_TEXTDISPLAY defi<br>not|nes whether the start/end s|ub-conditions for text message are to be combined or|
|**_Length of variable_**|**_Minimum Value_**|**_Maximum Value_**|**_Resolution/formula_**|
|1 bit||||
|**_Special/Reserved Values_**|0|No, display as soon as|/ until one of the sub-conditions is fulfilled|
||1|Yes, display as soon a|s / until all sub-conditions are fulfilled|

<!-- end of page 84 -->

### 7.5.1.140 Q_TEXTREPORT

|**_Name_**|Qualifier for reporting a|cknowledgement of text by|driver|
|---|---|---|---|
|**_Description_**||||
|**_Length of variable_**|**_Minimum Value_**|**_Maximum Value_**|**_Resolution/formula_**|
|1 bit||||
|**_Special/Reserved Values_**|0|No driver acknowledge|ment report required|
||1|Driver acknowledgeme|nt report required|

### 7.5.1.141 Q_TRACKINIT

|**_Name_**|Qualifier for resuming|the initial states of the relate|d track description of the packet.|
|---|---|---|---|
|**_Description_**||||
|**_Length of variable_**|**_Minimum Value_**|**_Maximum Value_**|**_Resolution/formula_**|
|1 bit||||
|**_Special/Reserved Values_**|0|No initial states to be re|sumed,  profile to follow|
||1|Empty profile, initial sta|tes to be resumed|

### 7.5.1.142 Q_UPDOWN

|**_Name_**|Balise telegram trans|mission direction||
|---|---|---|---|
|**_Description_**|It defines the direction|of the information in the balis|e telegram|
|**_Length of variable_**|**_Minimum Value_**|**_Maximum Value_**|**_Resolution/formula_**|
|1 bit||||
|**_Special/Reserved Values_**|0|Down link telegram||
||1|Up link telegram||

### 7.5.1.142.1 Q_VBCO

|**_Name_**|Qualifier for Virtual Ba|lise Cover order|
|---|---|---|
|**_Description_**|Qualifier to set or rem|ove a VBC|
|**_Length of variable_**|**_Minimum Value_**|**_Maximum Value_**<br>**_Resolution/formula_**|
|1 bit|||
|**_Special/Reserved Values_**|0|Remove the Virtual Balise Cover|
||1|Set the Virtual Balise Cover|

### 7.5.1.143 T_CYCLOC

|**_Name_**|Time Interval between t|wo position reports sent by th|e train|
|---|---|---|---|
|**_Description_**|The train must send its|position every T_CYCLOC||
|**_Length of variable_**|**_Minimum Value_**|**_Maximum Value_**|**_Resolution/formula_**|
|8 bits|0 s|254 s|1s|
|**_Special/Reserved Values_**|255|||

### 7.5.1.144 T_CYCRQST

|**_Name_**|Time between two cycl|ic requests for a movement|authority|
|---|---|---|---|
|**_Description_**|As long as at least one<br>every T_CYCRQST se|reason for sending MA req<br>conds|uests is applicable, the on-board will repeat its request|
|**_Length of variable_**|**_Minimum Value_**|**_Maximum Value_**|**_Resolution/formula_**|
|8 bits|0 s|254 s|1s|

<!-- end of page 85 -->

|**_Special/Reserved Values_**|255|No repetition|
|---|---|---|

### 7.5.1.144.1 T_LSSMA

|**_Name_**|Delay to toggle on the|LSSMA display||
|---|---|---|---|
|**_Description_**||||
|**_Length of variable_**|**_Minimum Value_**|**_Maximum Value_**|**_Resolution/formula_**|
|8 bits|0 s|255 s|1 s|

### 7.5.1.145 T_ENDTIMER

|**_Name_**|Validity time for the E|nd section in the MA||
|---|---|---|---|
|**_Description_**|Time for which the En<br>by D_ENDTIMERSTA|d section is valid measured<br>RTLOC.|from the moment the train reaches the location defined|
|**_Length of variable_**|**_Minimum Value_**|**_Maximum Value_**|**_Resolution/formula_**|
|10 bits|0 s|1022 s|1 s|
|**_Special/Reserved Values_**|1023|||

### 7.5.1.146 T_EMA

|**_Name_**|Validity time for the tar|get speed at the End of Mo|vement Authority|
|---|---|---|---|
|**_Description_**|Time for which the tar|get speed is valid measured|from the moment information is received|
|**_Length of variable_**|**_Minimum Value_**|**_Maximum Value_**|**_Resolution/formula_**|
|10 bits|0 s|1022 s|1 s|
|**_Special/Reserved Values_**|1023|||

### 7.5.1.147 T_MAR

|**_Name_**|Time before reaching|the perturbation location||
|---|---|---|---|
|**_Description_**||||
|**_Length of variable_**|**_Minimum Value_**|**_Maximum Value_**|**_Resolution/formula_**|
|8 bits|0 s|254 s|1 s|
|**_Special/Reserved Values_**|255|No MA request triggerin|g with regards to this function|

### 7.5.1.148 T_NVCONTACT

|**_Name_**|Maximum time since th|e time-stamp of the last rec|eived message.|
|---|---|---|---|
|**_Description_**|If the time elapsed fro<br>seconds, an appropriat|m the time stamp of the la<br>e action according to M_NV|st received message is greater than T_NVCONTACT<br>CONTACT must be triggered.|
||This variable is part of|the National Values||
|**_Length of variable_**|**_Minimum Value_**|**_Maximum Value_**|**_Resolution/formula_**|
|8 bits|0 s|254 s|1s|
|**_Special/Reserved Values_**|255|||

### 7.5.1.149 T_NVOVTRP

|**_Name_**|Maximum time for ove|rriding the train trip||
|---|---|---|---|
|**_Description_**|This variable is part of|the National Values||
|**_Length of variable_**|**_Minimum Value_**|**_Maximum Value_**|**_Resolution/formula_**|
|8 bits|0 s|255 s|1 s|

<!-- end of page 86 -->

### 7.5.1.150 T_OL

|**_Name_**|Overlap validity time|||
|---|---|---|---|
|**_Description_**|The time span the trai<br>reaches the location de|n can expect the overlap t<br>fined by D_STARTOL.|o be available, measured from the moment the train|
|**_Length of variable_**|**_Minimum Value_**|**_Maximum Value_**|**_Resolution/formula_**|
|10 bits|0 s|1022 s|1 s|
|**_Special/Reserved Values_**|1023|||

### 7.5.1.151 T_SECTIONTIMER

|**_Name_**|Validity time of a secti|on in the MA||
|---|---|---|---|
|**_Description_**|Time for which the sec|tion is valid.||
|**_Length of variable_**|**_Minimum Value_**|**_Maximum Value_**|**_Resolution/formula_**|
|10 bits|0 s|1022 s|1 s|
|**_Special/Reserved Values_**|1023|||

### 7.5.1.152 T_TEXTDISPLAY

|**_Name_**|Duration for which a t|ext shall be displayed||
|---|---|---|---|
|**_Description_**||||
|**_Length of variable_**|**_Minimum Value_**|**_Maximum Value_**|**_Resolution/formula_**|
|10 bits|0 s|1022 s|1 s|
|**_Special/Reserved Values_**|1023|No “time” sub-condition|specified for the end condition of the display of the text|

### 7.5.1.153 T_TIMEOUTRQST

|**_Name_**|Time before any sectio|n timer expires or the LOA|speed timer expires|
|---|---|---|---|
|**_Description_**||||
|**_Length of variable_**|**_Minimum Value_**|**_Maximum Value_**|**_Resolution/formula_**|
|10 bits|0 s|1022 s|1 s|
|**_Special/Reserved Values_**|1023|No MA request trigger|ing with regards to this function|

### 7.5.1.154 T_TRAIN

|**_Name_**|Trainborne clock|||
|---|---|---|---|
|**_Description_**|Time, according to train|borne clock, at which mess|age is sent|
|**_Length of variable_**|**_Minimum Value_**|**_Maximum Value_**|**_Resolution/formula_**|
|32 bits|0 s|42949672.94 s|10 ms|
|**_Special/Reserved Values_**|4294967295|Unknown||

### 7.5.1.154.1 T_VBC

|**_Name_**|VBC validity period|||
|---|---|---|---|
|**_Description_**|Time period in which th|e VBC is applicable||
|**_Length of variable_**|**_Minimum Value_**|**_Maximum Value_**|**_Resolution/formula_**|
|8 bits|0 hours|6120 hours (255 days)|24 hours|
|.5.1.155 V_AXLE<br>**_Name_**|LOAD<br>Speed restriction relate|d to axleload||
|**_Description_**||||

### 7.5.1.155 V_AXLELOAD

<!-- end of page 87 -->

|**_Length of variable_**|**_Minimum Value_**|**_Maximum Value_**|**_Resolution/formula_**|
|---|---|---|---|
|7 bits|0 km/h|600 km/h|5 km/h|
|**_Special/Reserved Values_**|121 –127|Spare||

### 7.5.1.156 V_DIFF

|**_Name_**|Absolute Positive Spe|ed associated to a train cate|gory.|
|---|---|---|---|
|**_Description_**||||
|**_Length of variable_**|**_Minimum Value_**|**_Maximum Value_**|**_Resolution/formula_**|
|7 bits|0 km/h|600 km/h|5 km/h|
|**_Special/Reserved Values_**|121 – 127|Spare||

### 7.5.1.157 V_EMA

|**_Name_**|Permitted speed at th|e End of Movement Authority||
|---|---|---|---|
|**_Description_**||||
|**_Length of variable_**|**_Minimum Value_**|**_Maximum Value_**|**_Resolution/formula_**|
|7 bits|0 km/h|600 km/h|5 km/h|
|**_Special/Reserved Values_**|121-127|Spare||

### 7.5.1.157.1 V_LX

|**_Name_**|Permitted speed for the|LX speed restriction||
|---|---|---|---|
|**_Description_**|Speed at which the LX|can be passed when it is n|ot protected|
|**_Length of variable_**|**_Minimum Value_**|**_Maximum Value_**|**_Resolution/formula_**|
|7 bits|0 km/h|600 km/h|5 km/h|
|**_Special/Reserved Values_**|121 – 127|Spare||

### 7.5.1.158 V_MAIN

|**_Name_**|Signalling related spee|d restriction||
|---|---|---|---|
|**_Description_**||||
|**_Length of variable_**|**_Minimum Value_**|**_Maximum Value_**|**_Resolution/formula_**|
|7 bits|0 km/h|600 km/h|5 km/h|
|**_Special/Reserved Values_**|121-127|Spare||
||V_MAIN = 0 means “tri|p order”||

### 7.5.1.159 V_MAMODE

|**_Name_**|Required mode relate|d speed||
|---|---|---|---|
|**_Description_**||||
|**_Length of variable_**|**_Minimum Value_**|**_Maximum Value_**|**_Resolution/formula_**|
|7 bits|0 km/h|600 km/h|5 km/h|
|**_Special/Reserved Values_**|121 – 126|Spare||
||127|Use the national speed|value of the required mode|

### 7.5.1.160 V_MAXTRAIN

|Name|Maximum train speed.||
|---|---|---|
|Description|||
|Length of variable|Minimum Value<br>Maximum Value|Resolution/formula|

<!-- end of page 88 -->

|7 bits|0 km/h|600 km/h|5 km/h|
|---|---|---|---|
|**_Special/Reserved Values_**|121 – 127|Spare||

### 7.5.1.161 V_NVALLOWOVTRP

|**_Name_**|Speed limit allowing th|e driver to select the “override”|function|
|---|---|---|---|
|**_Description_**|This variable is part of|the National Values||
|**_Length of variable_**|**_Minimum Value_**|**_Maximum Value_**|**_Resolution/formula_**|
|7 bits|0 km/h|600km/h|5 km/h|
|**_Special/Reserved Values_**|121 – 127|Spare||

### 7.5.1.161.1 V_NVKVINT

|**_Name_**|Speed step used to de|fine the integrated correctio|n factor Kv|
|---|---|---|---|
|**_Description_**|This variable is part of|the National Values||
|**_Length of variable_**|**_Minimum Value_**|**_Maximum Value_**|**_Resolution/formula_**|
|7 bits|0 km/h|600km/h|5 km/h|
|**_Special/Reserved Values_**|121 – 127|Spare||

### 7.5.1.161.2 V_NVLIMSUPERV

|**_Name_**|Limited Supervision m|ode speed limit||
|---|---|---|---|
|**_Description_**|This variable is part of|the National Values||
|**_Length of variable_**|**_Minimum Value_**|**_Maximum Value_**|**_Resolution/formula_**|
|7 bits|0 km/h|600km/h|5 km/h|
|**_Special/Reserved Values_**|121 – 127|Spare||

### 7.5.1.162 V_NVONSIGHT

|**_Name_**|On Sight mode speed|limit||
|---|---|---|---|
|**_Description_**|This variable is part of|the National Values||
|**_Length of variable_**|**_Minimum Value_**|**_Maximum Value_**|**_Resolution/formula_**|
|7 bits|0 km/h|600 km/h|5 km/h|
|**_Special/Reserved Values_**|121-127|Spare||

### 7.5.1.163 V_NVSUPOVTRP

|**_Name_**|Override speed limit to|be supervised when the “o|verride” function is active|
|---|---|---|---|
|**_Description_**|This variable is part of|the National Values||
|**_Length of variable_**|**_Minimum Value_**|**_Maximum Value_**|**_Resolution/formula_**|
|7 bits|0 km/h|600km/h|5 km/h|
|**_Special/Reserved Values_**|121 – 127|Spare||

### 7.5.1.164 V_NVREL

|**_Name_**|Release Speed|||
|---|---|---|---|
|**_Description_**|This variable is part of|the National Values||
|**_Length of variable_**|**_Minimum Value_**|**_Maximum Value_**|**_Resolution/formula_**|
|7 bits|0 km/h|600 km/h|5 km/h|
|**_Special/Reserved Values_**|121-127|Spare||

<!-- end of page 89 -->

### 7.5.1.165 V_NVSHUNT

|**_Name_**|Shunting mode speed li|mit||
|---|---|---|---|
|**_Description_**|This variable is part of th|e National Values||
|**_Length of variable_**|**_Minimum Value_**|**_Maximum Value_**|**_Resolution/formula_**|
|7 bits|0 km/h|600 km/h|5 km/h|
|**_Special/Reserved Values_**|121-127|Spare||

### 7.5.1.166 V_NVSTFF

|**_Name_**|Staff Responsible mod|e speed limit||
|---|---|---|---|
|**_Description_**|This variable is part of|the National Values||
|**_Length of variable_**|**_Minimum Value_**|**_Maximum Value_**|**_Resolution/formula_**|
|7 bits|0 km/h|600 km/h|5 km/h|
|**_Special/Reserved Values_**|121-127|Spare||

### 7.5.1.167 V_NVUNFIT

|**_Name_**|Unfitted mode speed li|mit||
|---|---|---|---|
|**_Description_**|This variable is part of|the National Values||
|**_Length of variable_**|**_Minimum Value_**|**_Maximum Value_**|**_Resolution/formula_**|
|7 bits|0 km/h|600 km/h|5 km/h|
|**_Special/Reserved Values_**|121-127|Spare||

### 7.5.1.168 V_RELEASEDP

|**_Name_**|Release speed associ|ated with the danger point||
|---|---|---|---|
|**_Description_**||||
|**_Length of variable_**|**_Minimum Value_**|**_Maximum Value_**|**_Resolution/formula_**|
|7 bits|0 km/h|600 km/h|5 km/h|
|**_Special/Reserved Values_**|121-125|Spare||
||126|Use onboard calculated r|elease speed|
||127|Use national value||

### 7.5.1.169 V_RELEASEOL

|**_Name_**|Release speed associ|ated with the overlap||
|---|---|---|---|
|**_Description_**||||
|**_Length of variable_**|**_Minimum Value_**|**_Maximum Value_**|**_Resolution/formula_**|
|7 bits|0 km/h|600 km/h|5 km/h|
|**_Special/Reserved Values_**|121-125|Spare||
||126|Use onboard calculated|release speed|
||127|Use national value||

### 7.5.1.170 V_REVERSE

|**_Name_**|Reversing mode spee|d limit||
|---|---|---|---|
|**_Description_**||||
|**_Length of variable_**|**_Minimum Value_**|**_Maximum Value_**|**_Resolution/formula_**|
|7 bits|0 km/h|600 km/h|5 km/h|

<!-- end of page 90 -->

|**_Special/Reserved Values_**|121-127|Spare|
|---|---|---|

### 7.5.1.170.1 V_SM

|**_Name_**|Supervised Manoeuvr|e mode speed limit||
|---|---|---|---|
|**_Description_**||||
|**_Length of variable_**|**_Minimum Value_**|**_Maximum Value_**|**_Resolution/formula_**|
|7 bits|0 km/h|600 km/h|5 km/h|
|**_Special/Reserved Values_**|121-127|Spare||

### 7.5.1.171 V_STATIC

|**_Name_**|Basic static speed pro|file||
|---|---|---|---|
|**_Description_**|Basic static speed pro|file speed after discontinuity (|k).|
|**_Length of variable_**|**_Minimum Value_**|**_Maximum Value_**|**_Resolution/formula_**|
|7 bits|0 km/h|600 km/h|5 km/h|
|**_Special/Reserved Values_**|121-126|Spare||
||127|Non numerical value te<br>D_STATIC(n)|lling that the static speed profile description ends at|

### 7.5.1.172 V_TRAIN

|**_Name_**|Train speed|||
|---|---|---|---|
|**_Description_**||||
|**_Length of variable_**|**_Minimum Value_**|**_Maximum Value_**|**_Resolution/formula_**|
|7 bits|0 km/h|600 km/h|5 km/h|
|**_Special/Reserved Values_**|121-126|Spare||
||127|Standstill||

### 7.5.1.173 V_TSR

|**_Name_**|Permitted speed for th|e temporary speed restrictio|n|
|---|---|---|---|
|**_Description_**||||
|**_Length of variable_**|**_Minimum Value_**|**_Maximum Value_**|**_Resolution/formula_**|
|7 bits|0 km/h|600 km/h|5 km/h|
|**_Special/Reserved Values_**|121 – 127|Spare||

### 7.5.1.174 X_TEXT

|**_Name_**|Text String Element|||
|---|---|---|---|
|**_Description_**|Text strings are used t<br>character encoded as IS|o transmit plain text messages<br>O 8859-1, also known as Latin|. Each element of a text string contains a single<br>Alphabet #1.|
|**_Length of variable_**|**_Minimum Value_**|**_Maximum Value_**|**_Resolution/formula_**|
|8 bits||||

<!-- end of page 91 -->
