# **6. APPENDIX: ENGINEERING RULES FOR OLDER SYSTEM VERSIONS**

## **6.1 Installation Rules**

### **6.1.1 Miscellaneous**

6.1.1.1 Level transitions borders and RBC/RBC handover borders

6.1.1.1.1 For any trackside system operating with system version number X = 1, the following rule shall apply:

|Rule|Level transition borders and RBC/RBC handover borders shall not be<br>located where shunting or reversing could take place.|
|---|---|
|Reference||
|Justification|Level transitions and RBC/RBC handovers are rejected by|
||ERTMS/ETCS on-board equipment, supporting only system version|
||number X = 1, when in Shunting mode or in Reversing mode.|

<!-- end of page 49 -->

## **6.2 Telegrams and Messages**

### **6.2.1 Data engineering rules for individual data types**

6.2.1.1 Infill Information

6.2.1.1.1 For any balise telegram, loop message and RIU message with M_VERSION where X = 1, rule 4.2.4.5.1 shall be replaced with:

|Rule|Infill information which is repeated from the balise group at the next<br>main signal by any infill device shall be limited to infill MA, linking and<br>route related track description information. All information which does<br>not relate to Infill (e.g. information for opposite direction or EOLM etc.)<br>shall not be given as infill information.<br>Permitted infill information:<br>-<br>Packet 136 (infill location reference)<br>-<br>Packet 12, 80; 49 (MA, Mode Profile, List of Balises for SH area)<br>-<br>Packet 21 (Gradient Profile)<br>-<br>Packet 27, 51, 65, 70 (SSP, ASP, TSR, Route Suitability)<br>-<br>Packet 5 (Linking)<br>-<br>Packet 41 (Level transition) (see also rule 4.2.4.5.2)<br>-<br>Packet 44 (data used outside ERTMS) (only if NID_XUSER ≠102)<br>-<br>Packet 39, 67, 68, 206, 207, 239 (Track condition)<br>-<br>Packet 71 (adhesion factor)<br>-<br>Packet 138, 139 (Reversing area/supervision information)|
|---|---|
|Reference||
|Justification|This for consistency with SRS Chapter 6, that defines which packets a<br>Trackside operating with M_VERSION where X = 1 is allowed to<br>transmit.|

6.2.1.1.2 For any Trackside operated with system version number X<3, rule 4.2.4.5.3 shall be replaced with:

|Rule|Upon reception of an infill MA, the infill location reference given by the<br>infill device must be in rear of the current EOA/LOA.|
|---|---|
|Reference|SUBSET-026 – section 3.4.3.1; 3.8.4.6.2-4; 4.8.1.5|
|Justification|An MA extension via an infill MA is only possible if there is no gap<br>between the old MA and the MA extension.|

<!-- end of page 50 -->

|Remark|In order to not induce a gap between the old MA and the MA extension<br>via infill, the trackside should always ensure that, when the infill MA is<br>received:<br>•<br>in case the old MA has not been relocated, the linking information<br>announcing the main balise group provides the distance between<br>the balise group giving the old MA and the main balise group, OR<br>•<br>in case the old MA has been relocated, only relocation(s) using<br>distance(s) retrieved from linking information has(ve) been<br>performed, OR<br>•<br>in case the old MA has been relocated with a distance not retrieved<br>from linking information, the old MA current section has been duly<br>updated with repositioning information after or at the same time the<br>last relocation has taken place AND the linking information<br>announcing the main balise group provides the distance between<br>the current reference balise group of the old MA and the main<br>balise group.|
|---|---|

#### 6.2.1.2 Mode Profile

6.2.1.2.1 For any balise telegram, loop message and RIU message with M_VERSION where X = 1, rule 4.2.4.6.2 shall be replaced with:

|Rule|In case there is a Level 1 MA Packet with V_MAIN = 0, it is not allowed<br>that the Message includes any mode profile packet.|
|---|---|
|Reference||
|Justification|For an ERTMS/ETCS on-board equipment supporting only system<br>version number X = 1, the reaction to a message containing a Level 1|
||MA Packet with V_MAIN = 0 and a mode profile is undefined.|

#### 6.2.1.3 Level transition order

|Rule|In a level transition order sent in a balise telegram or loop message with<br>M_VERSION where X=1, or sent by an RBC/RIU with System Version<br>where X=1, trackside shall include all applicable values of NID_STM<br>containing the national system(s) installed in the infrastructure.|
|---|---|
|Reference|Subset-035 §7.4.1.1.17|
|Justification|When receiving such telegram or message, the on-board will not use<br>any “level translation” look-up table.|

#### 6.2.1.3.1 Conditional Level Transition Order

<!-- end of page 51 -->

|Rule|Any trackside system operating with system version number X = 1 shall<br>not send packet 46 (Conditional Level Transition Order) in a telegram<br>or message which contains the packet 41 (Level Transition Order). In<br>addition, it shall be forbidden to send packet 46 between a level<br>transition announcement and the announced location of the level<br>transition.|
|---|---|
|Reference||
|Justification|In ERTMS/ETCS on-board equipment supporting only system version<br>number X=1, a packet 46 (Conditional Level Transition Order) may<br>replace a packet 41 (Level Transition Order) received at the same time<br>or already stored on-board and consequently cancel an announced<br>level transition.|

<!-- end of page 52 -->

#### 6.2.1.4 Track conditions

6.2.1.4.1 For any trackside system operating with system version number X = 1, rule 4.2.4.7.1 shall be replaced with:

|Rule|The minimum distance (latest transmission) between announcement of<br>track condition Powerless Section with pantograph to be lowered and<br>the start location of this track condition shall correspond to 17s when<br>running at line speed (engineered SSP) in the approach area (B-D in<br>the figure below).<br>The minimum distance (latest transmission) between announcement of<br>track condition Powerless Section with main power switch to be<br>switched off and the start location of this track condition shall<br>correspond to 11s when running at line speed (engineered SSP) in the<br>approach area (B-D in the figure below).<br>The “Distance to change of traction system” shall refer to the middle of<br>a Powerless Section track condition (F in the figure below).|
|---|---|
||E<br>powerless section<br>Pantograph lowered/<br>Main power switch<br>switched off<br>running direction<br>D<br>LRBG/ORBG<br>B<br>A|
||F<br>Announcement distance<br>D_TRACKCOND<br>L_TRACKCOND<br>D_TRACTION<br>A: LRBG/ORBG which is the location reference point for the distances<br>given<br>B: latest announcement location<br>D: start location of track condition Powerless Section with pantograph<br>to be lowered or with main power switch to be switched off<br>E: end location of track condition Powerless Section with pantograph to<br>be lowered or with main power switch to be switched off<br>F: location for track condition Change of Traction System|
|Reference|SUBSET-026 –section 3.7.1.1 c)|
|Justification|No Change of Traction System announcement is computed by an<br>ERTMS/ETCS on-board equipment supporting only system version<br>number X = 1.|

<!-- end of page 53 -->

#### 6.2.1.4.2 Updating track conditions

|Rule|A trackside operating in system version number X=1 that wants to<br>update one track condition must at the same time resend all track<br>conditions that it wants the ERTMS/ETCS on-board to apply, including<br>those already entered by the train. Note: information about Big Metal<br>Mass cannot be repeated from an RBC.|
|---|---|
|Reference|Subset-026, section 3.7.3|
|Justification|How to update track conditions in ERTMS/ETCS on-boards supporting<br>only system version number X=1 is open for different interpretations and<br>there is a risk that when updating one track condition this may also<br>replace (delete) others.|

#### 6.2.1.5 National Values

|Rule|In National Values sent in a balise telegram with M_VERSION where<br>X=1, or sent by an RBC with System Version where X=1, trackside shall<br>include at least one country identifier for which the National Values are<br>applicable.|
|---|---|
|Reference|Subset-026 §6.5.1.5.4|
|Justification|There is no on-board behaviour defined for handling National Values<br>received without identifier of the area(s) (country or region) in which<br>they are applicable|

#### 6.2.1.6 Movement Authorities

|Rule|For any trackside system operating with system version number X < 3<br>and where the level corresponding to the value M_LEVELTR = 4 (i.e.<br>formerly level 3) is operated, the packets 15 sent by the RBC shall not<br>include any of the following timers: section timer, end section timer and<br>overlap timer.|
|---|---|
|Reference|SUBSET-026 v3.6.0, v3.4.0 and v2.3.0 § 3.8.3.5|
|Justification|An on-board equipment compliant with the above former referential<br>might not be resilient to the use of MA timers while operating with the<br>former level 3.|

<!-- end of page 54 -->

## **6.3 Dimensioning rules for messages**

### **6.3.1 Data**

6.3.1.1 For any Trackside operated with system version number X=1, rule 4.3.2.1 c) shall be replaced with:

Number of mode profile sections

||Maximum number of iterations in<br>1 packet|Minimum memorised on board|
|---|---|---|
|Rule|2|3|
|Reference|SUBSET-026 section–7.4.2.26<br>and section 4.2.4.6 herein||
|Justification||Based on the maximum number<br>of iterations in 1 packet and on<br>the fact that no minimum number<br>of mode profile sections<br>memorised on-board is specified<br>for ERTMS/ETCS on-board<br>equipment supporting only<br>system version number X=1, it<br>cannot be assumed that it stores<br>more than 3 mode profile<br>sections.|

6.3.1.2 For any Trackside operated with system version number X=2, rule 4.3.2.1 s) shall be replaced with:

Number of Permitted Braking Distance Speed Restrictions

||Maximum number of iterations in<br>1 packet|Minimum memorised on board|
|---|---|---|
|Rule|2|5|
|Reference|SUBSET-026 – section 7.4.2.13.1||
|Justification||For ERTMS/ETCS on-board<br>equipment supporting up to<br>system version number X=2, it<br>cannot be assumed that it stores<br>more than 5 PBD SR.|

<!-- end of page 55 -->

6.3.1.3 For any Trackside operated with system version number X<3, rule 4.3.2.1 p) shall be replaced with:

Number of Axle load speed restriction values per ASP segment

||Maximum number of iterations per<br>ASP segment|Minimum memorised on board|
|---|---|---|
|Rule|3||
|Reference|SUBSET-026 – section 7.4.2.13||
|Justification|||

<!-- end of page 56 -->
