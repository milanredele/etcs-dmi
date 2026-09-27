## **ERTMS/ETCS**

# **System Requirements Specification Chapter 3 Principles**

REF  :  SUBSET-026-3 ISSUE :

4.0.0 DATE : 05/07/2023

<!-- end of page 1 -->

## **3.1 Modification History**

|Issue Number<br>Date|Section Number|Modification / Description|Author/Editor|
|---|---|---|---|
|1.0.1<br>990307|All|Merge of Basic + Detailed<br>Principles<br>Removing redundant<br>material, correcting text and<br>adding proposals.|HE|
|1.1.0<br>990423|All|Class P Official Issue|HE|
|1.1.1<br>990521|All|Corrections after UNISIG<br>review.|KL|
|1.1.2<br>990713|All|Additional functions for<br>class 1 and changes related<br>to these functions in other<br>parts|KL|
|1.1.3<br>990722|All|Changes according to<br>review of version 1.1.2|KL|
|1.1.4<br>990729|All|Editorial corrections,<br>finalisation meeting<br>Stuttgart 990729|HE|
|1.2.0<br>990730|Version number|Release version|HE|
|1.3.0<br>991201|All|Corrections and new<br>functions according to<br>ECSAG and UNISIG<br>comments|KL|
|1.3.1<br>991217|All|Corrections after UNISIG<br>review 15 December 99|KL|
|2.0.0<br>991222|Minor editing|Release Version|Ch. Frerichs (ed.)|
|2.0.1<br>000921|All|Corrections after UNISIG<br>review 15 June 00|KL|
|2.1.0<br>001017|Most|Corrections after UNISIG<br>review 11 October 00|KL|
|2.2.0<br>010108|Section 3.18.4.6.6<br>3.18.4.6.8 removed|–<br>Changes as decided on<br>Steering Committee<br>meeting 13 December 2000<br>(changes from 2.0.0<br>marked)|KL|

<!-- end of page 2 -->

|2.2.2<br>020201|Refer to document: SUBSET–026 Corrected<br>Paragraphs, Issue 2.2.2|KL|
|---|---|---|
|2.2.4 SG checked<br>040528|Including all CLRs agreed with the EEIG (see “List of<br>CLRs agreed with EEIG for SRS v2.2.4” dated<br>28/05/04)<br>Affected clauses see change marks|H. Kast|
|2.2.5<br>210105|Incorporation of solution proposal for CLR 007 with<br>EEIG users group comments<br>Corrections according to erratum list agreed in SG<br>meeting 170105|AH|
|2.2.6<br>050301|Including all CLRs being in state “EEIG pending” as<br>per list of CLRs extracted on 28/01/05.|OG|
|2.2.7<br>220705|Including all CLRs extracted from “CR-<br>Report_10.6.05-by number.rtf” and mentioned in<br>column 2.2.7 in “CR status 13.6.05.xls”<br>22/07/05  Changes for CR 126 included (HK)|OG|
|2.2.8<br>211105|Change marks cleaned up and updated according to<br>last CRs decisions (including split of CRs7&126)|OG|
|2.2.9<br>24/02/06|Including all CRs that are classified as “IN” as per<br>SUBSET-108 version 1.0.0<br>Removal of all CRs that are not classified as “IN” as<br>per SUBSET-108 version 1.0.0, with the exception of<br>CRs 63,98,120,158,538|OG|
|2.3.0<br>24/02/06|Release version|HK|
|2.3.1<br>12/06/06||OG|
|2.3.2<br>17/03/08|Including all CRs that are classified as “IN” as per<br>SUBSET-108 version 1.2.0 and all CRs that are in<br>state “Analysis completed” according to ERA CCM|AH|
|2.9.1<br>06/10/08|Including all enhancement CR’s retained for baseline<br>3 and all other error CR’s<br>For editorial reasons, the following CR’s are also<br>included: CR656, CR804, CR821|AH|
|3.0.0<br>13/12/08|Release version|AH|
|3.0.1<br>22/12/09|Including the results of the editorial review of the SRS<br>3.0.0 and the other error CR’s that are in state<br>“Analysis completed” according to ERA CCM|AH|

<!-- end of page 3 -->

|3.1.0<br>22/02/10|Release version|AH|
|---|---|---|
|3.1.1<br>08/11/10|Including all CR’s that are in state “Analysis<br>completed” according to ERA CCM, plus CR731, 972<br>and 1000.|AH|
|3.2.0<br>22/12/10|Release version|AH|
|3.2.1<br>13/12/11|Including all CR’s that are in state “Analysis<br>completed” according to ERA CCM, plus CR772|AH|
|3.3.0<br>07/03/12|Baseline 3 release version|AH|
|3.3.1<br>04/04/14|CR’s 944, 1109,1124, 1127, 1149, 1150, 1183, 1185|OG|
|3.3.2<br>23/04/14|Baseline 3 1<sup>st</sup>maintenance pre-release version|OG|
|3.3.3<br>06/05/14|CR 1223<br>Baseline 3 1<sup>st</sup>maintenance 2<sup>nd</sup>pre-release version|OG|
|3.4.0<br>12/05/14|Baseline 3 1<sup>st</sup>maintenance release version|OG|
|3.4.1<br>23/06/15|CR’s 239, 852, 1014, 1117, 1163, 1164, 1172, 1260|OG|
|3.4.2<br>17/11/15|CR’s 299, 933, 1084, 1086, 1087, 1107, 1152, 1163<br>(update), 1184, 1190, 1197, 1249, 1254, 1262, 1265,<br>1266, 1273, 1277|OG|
|3.4.3<br>16/12/15|CR1283 plus update due to overall CR consolation<br>phase|OG|
|3.5.0<br>18/12/15|Baseline 3 2<sup>nd</sup>release version as recommended to<br>EC (see ERA-REC-123-2015/REC)|OG|
|3.5.1<br>28/04/16|CR 1249 reopening following RISC #75|OG|
|3.6.0<br>13/05/16|Baseline 3 2<sup>nd</sup>release version|AH|
|3.6.1<br>29/05/17|CR’s 940, 994, 1120, 1170, 1251, 1252, 1259, 1263,<br>1264, 1288, 1293,1296, 1300|OG|
|3.6.2|CR’s 887, 940, 994, 1120, 1293, 1300, 1306|OG|
|31/05/18|Replacement of all equations due to the disabling of<br>the former Microsoft equation editor|AH|

<!-- end of page 4 -->

|3.6.3<br>21/02/20|CR’s 940, 1130, 1267, 1282, 1311, 1312, 1313,<br>1318, 1320, 1327, 1328, 1329, 1330, 1332, 1333,<br>1334, 1338, 1341, 1345, 1347, 1348|OG<br>AH|
|---|---|---|
|3.6.4<br>22/06/20|CR’s 1282, 1306, 1313, 1334|OG<br>AH|
|3.6.5<br>22/12/21|CR’s 1021, 1162, 1238, 1354, 1358, 1370, 1372,<br>1376, 1377, 1382, 1384, 1386, 1396|OG<br>AH|
|3.6.6<br>29/08/22|CR’s 940 (updated), 968, 1288 (updated), 1302,<br>1342, 1363, 1367, 1389, 1410, 1411, 1414, 1418|OG<br>AH|
|3.9.1<br>24/11/22|CR’s 940 (updated), 988, 1307, 1344, 1367<br>(updated), 1397, 1423, 1424<br>Outcome of B4R1 1<sup>st</sup>consolidation phase|OG<br>AH|
|3.9.2<br>21/02/23|CR’s 1318, 1367, 1370<br>Outcome of B4R1 2<sup>nd</sup>consolidation phase|OG<br>AH|
|3.9.3<br>31/05/23|CR’s 1359, 1427<br>Outcome of B4R1 3<sup>rd</sup>consolidation phase|OG<br>AH|
|3.9.4|CR’s 1342 (updated), 1432|OG|
|30/06/23|Outcome of B4R1 4<sup>th</sup>consolidation phase|AH|
|4.0.0<br>05/07/23|Baseline 4 1<sup>st</sup>release version|OG<br>AH|

<!-- end of page 5 -->

|**3.2**<br>|**Table of Contents**|
|---|---|
|3.1<br>Mo|dification History ........................................................................................................... 2|
|3.2<br>Ta|ble of Contents .............................................................................................................. 6|
|3.3<br>Int|roduction ..................................................................................................................... 10|
|3.3.1|Scope and purpose .................................................................................................. 10|
|3.4<br>Ba|lise configuration, linking and Euroloop ....................................................................... 10|
|3.4.1|Balise Configurations – Balise Group Definition ....................................................... 10|
|3.4.2|Balise Co-ordinate System ....................................................................................... 10|
|3.4.3|Balise Information Types and Usage ........................................................................ 15|
|3.4.4|Linking ..................................................................................................................... 15|
|3.4.5|Euroloop (level 1 only) ............................................................................................. 18|
|3.5<br>Ma|nagement of Radio Communication ........................................................................... 19|
|3.5.1|Introduction .............................................................................................................. 19|
|3.5.2|General .................................................................................................................... 19|
|3.5.3|Establishing a communication session ..................................................................... 20|
|3.5.4|Maintaining a communication session ...................................................................... 25|
|3.5.5|Terminating a communication session ..................................................................... 26|
|3.5.6|Managing the Radio Networks ................................................................................. 28|
|3.5.7|Safe Radio Connection Indication ............................................................................ 30|
|3.6<br>Lo|cation Principles, Train Position and Train Orientation ................................................ 31|
|3.6.1|General .................................................................................................................... 31|
|3.6.2|Location reference of Data Transmitted to the On-Board Equipment ....................... 34|
|3.6.3|Validity direction of transmitted information .............................................................. 36|
|3.6.4|Train Position Confidence Interval and Relocation ................................................... 40|
|3.6.5|Position Reporting to the RBC ................................................................................. 59|
|3.6.6|Geographical position reporting ............................................................................... 66|
|3.6.7|Supervision of distances not referred to balise groups ............................................. 68|
|3.6.8|Monitoring of odometer accuracy ............................................................................. 70|
|3.7<br>Co|mpleteness of data for safe train movement ............................................................... 71|
|3.7.1|Completeness of data .............................................................................................. 71|
|3.7.2|Responsibility for completeness of information ......................................................... 71|
|3.7.3|Extension, replacement and deletion of location based information ......................... 72|
|3.8<br>Mo|vement authority ......................................................................................................... 75|
|3.8.1|Characteristics of a MA ............................................................................................ 75|
|3.8.2|MA request to the RBC ............................................................................................ 77|
|3.8.3|Structure of a Movement Authority (MA) .................................................................. 79|
|3.8.4|Use of the MA on board the train.............................................................................. 81|

<!-- end of page 6 -->

|3.8.5|MA Update ............................................................................................................... 84|
|---|---|
|3.8.6|Co-operative shortening of MA (Level 2 only)........................................................... 91|
|3.9<br>Me|ans to transmit Infill information (Level 1 only) ............................................................ 92|
|3.9.1|General .................................................................................................................... 92|
|3.9.2|Infill by loop .............................................................................................................. 92|
|3.9.3|Infill by radio ............................................................................................................. 93|
|3.10<br>|Emergency Messages ................................................................................................. 96|
|3.10.1|General .................................................................................................................... 96|
|3.10.2|Emergency Stop ...................................................................................................... 96|
|3.10.3|Revocation of an Emergency Message .................................................................... 97|
|3.11<br>|Static Speed Restrictions and Gradients...................................................................... 97|
|3.11.1|Introduction .............................................................................................................. 97|
|3.11.2|Definition of Static Speed Restriction ....................................................................... 97|
|3.11.3|Static Speed Profile (SSP) ....................................................................................... 98|
|3.11.4|Axle load Speed Profile .......................................................................................... 100|
|3.11.5|Temporary Speed Restrictions ............................................................................... 100|
|3.11.6|Signalling related speed restrictions ....................................................................... 102|
|3.11.7|Mode related speed restrictions ............................................................................. 102|
|3.11.8|Train related speed restriction ................................................................................ 102|
|3.11.9|LX speed restriction ............................................................................................... 103|
|3.11.10|Override function related Speed Restriction ........................................................... 103|
|3.11.11|Speed restriction to ensure permitted braking distance .......................................... 103|
|3.11.12|Gradients ............................................................................................................... 106|
|3.12<br>|Other Profiles ............................................................................................................ 107|
|3.12.1|Track Conditions .................................................................................................... 107|
|3.12.2|Route Suitability ..................................................................................................... 109|
|3.12.3|Text Transmission .................................................................................................. 110|
|3.12.4|Mode profile ........................................................................................................... 113|
|3.12.5|Level Crossings ..................................................................................................... 114|
|3.13<br>|Speed and distance monitoring ................................................................................. 114|
|3.13.1|Introduction ............................................................................................................ 114|
|3.13.2|Inputs for speed and distance monitoring ............................................................... 116|
|3.13.3|Conversion Models ................................................................................................ 129|
|3.13.4|Acceleration / Deceleration due to gradient ............................................................ 130|
|3.13.5|Determination of locations without special brake contribution and with reduced|
|adhesi|on conditions ............................................................................................................. 133|
|3.13.6|Calculation of the deceleration and brake build up time ......................................... 133|
|3.13.7|Determination of Most Restrictive Speed Profile (MRSP) ....................................... 140|

<!-- end of page 7 -->

|3.13.8|Determination of targets and brake deceleration curves ......................................... 140|
|---|---|
|3.13.9|Supervision limits ................................................................................................... 143|
|3.13.10|Speed and distance monitoring commands ............................................................ 159|
|3.13.11|Perturbation location .............................................................................................. 176|
|3.14<br>|Brake Command Handling and Protection against Undesirable Train Movement ...... 179|
|3.14.1|Brake Command Handling ..................................................................................... 179|
|3.14.2|Roll Away Protection .............................................................................................. 181|
|3.14.3|Unauthorised Direction Movement Protection ........................................................ 181|
|3.14.4|Intentionally deleted ............................................................................................... 182|
|3.15<br>|Special functions ....................................................................................................... 182|
|3.15.1|RBC/RBC Handover .............................................................................................. 182|
|3.15.2|Handling of Trains with Non Leading Engines ........................................................ 187|
|3.15.3|Splitting/joining ....................................................................................................... 188|
|3.15.4|Reversing of movement direction ........................................................................... 188|
|3.15.5|Track ahead free .................................................................................................... 190|
|3.15.6|Handling of National Systems ................................................................................ 190|
|3.15.7|Tolerance of Big Metal Mass .................................................................................. 191|
|3.15.8|Cold Movement Detection ...................................................................................... 191|
|3.15.9|Virtual Balise Cover................................................................................................ 192|
|3.15.10|Advance display of route related information .......................................................... 193|
|3.15.11|Driving with Automatic Train Operation .................................................................. 193|
|3.16<br>|Data Consistency ...................................................................................................... 194|
|3.16.1|General .................................................................................................................. 194|
|3.16.2|Balises ................................................................................................................... 194|
|3.16.3|Radio ..................................................................................................................... 200|
|3.16.4|Error reporting to RBC ........................................................................................... 203|
|3.17<br>|System Version Management .................................................................................... 203|
|3.17.1|Introduction ............................................................................................................ 203|
|3.17.2|Determination of the operated system version ....................................................... 204|
|3.17.3|Handling of trackside data in relation to system version ......................................... 206|
|3.18<br>|System Data .............................................................................................................. 208|
|3.18.1|Fixed Values .......................................................................................................... 208|
|3.18.2|National / Default Values ........................................................................................ 208|
|3.18.3|Train Data .............................................................................................................. 209|
|3.18.4|Additional Data ....................................................................................................... 213|
|3.18.5|Date and Time ....................................................................................................... 216|
|3.18.6|Data view ............................................................................................................... 216|
|3.19<br>|Intentionally deleted ................................................................................................... 216|

<!-- end of page 8 -->

|3.20<br>J|uridical Data ............................................................................................................. 216|
|---|---|
|Appendix|to Chapter 3 ............................................................................................................ 217|
|A.3.1|List of Fixed Value Data ......................................................................................... 217|
|A.3.2|List of National / Default Data ................................................................................. 219|
|A.3.3|Handling of information received from trackside ..................................................... 220|
|A.3.4|Handling of Accepted and Stored Information in specific Situations ....................... 223|
|A.3.5|Handling of Actions in Specific Situations ............................................................... 228|
|A.3.6|Deletion of accepted and stored information when used ........................................ 230|
|A.3.7|Calculation of the basic deceleration ...................................................................... 230|
|A.3.8<br>time|Calculation of the emergency brake reaction time and emergency brake equivalent<br>232|
|A.3.9|Calculation of the full service brake reaction time and full service brake equivalent time<br>233|
|A.3.10|Service brake feedback .......................................................................................... 235|
|A.3.11|Data unit, range and resolution .............................................................................. 239|
|A.3.12|Calculation of reduced values of safe brake build up time and expected brake build up|
|time|240|
|A.3.13|Inhibition of increase of displayed permitted speed and SBI speed ........................ 251|

<!-- end of page 9 -->
