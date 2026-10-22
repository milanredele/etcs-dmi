# **4. RULES**

## **4.1 Installation rules**

### **4.1.1 Rules for balises**

#### 4.1.1.1 General installation rules for balises

|Rule|Reminder: the rules of the references below must be respected.|
|---|---|
|Reference|SUBSET-036|
||❑ Section 4.2.5: Cross-talk protection|
||❑ Section 5.2 : Balise air gap interface<br>❑ Section 5.6.2 : Installation requirements for balises<br>❑ Section 5.6.3: Distance between balises|
||❑ Section 5.7: Environmental Conditions|
|Justification|The rules of the reference above are required in order to guarantee<br>interoperability from a transmission point of view.|

4.1.1.2 Maximum distance between balises within a group – to determine that no further balise is expected within a group (potentially missing balise).

|Rule|The maximum distance between two consecutive balises within the<br>same group shall be 12 m from reference mark to reference mark.|
|---|---|
|Reference||
|Justification|The distance must be as short as possible in order to determine<br>potential loss of balises as soon as possible, but must respect the<br>longest minimum distance according to rule referenced in 4.1.1.1<br>herein.|

<!-- end of page 14 -->

4.1.1.3 Maximum distance between any balise at a signal containing switched information and the stopping point – for level 1.

|Rule|With regards to balises at a signal containing switched information any<br>balise located in rear of the operational stopping location shall not be<br>located further than 0.7m in rear of the operational stopping location.|
|---|---|
|Reference|SUBSET-036 section 5.2.2.5 (for the value 1.3 m)|
|Justification|-<br>A train that stops at the operational stopping point in rear of the<br>signal showing stop should not be able to receive information<br>contained in the balise group between the stopping point and the<br>EOA<br>-<br>The rule refers to the antenna being mounted closest to the<br>extremity of the engine where the reference mark of the antenna is<br>2m in rear of the extremity of the engine<br>-<br>For the earliest reception of a balise signal the ”side lobe zone” of<br>the balises (= 1.3 m) is taken into account|
||interoperable constraints for not receiving info from balise @ stopping position<br>2m|
||1,3m<br>EOA<br>Operational stopping point relative<br>1st balise of group<br>0,7m|

<!-- end of page 15 -->

|Rule|The last encountered balise of the balise group giving an MA, giving an<br>immediate level transition order, or giving a “Stop if in SR”, that is placed<br>close to the EOA/LOA shall be a minimum distance of 1.3m plus the<br>distance the train may run during the time Tn, calculated from the<br>formulas in Subset-036, clause 4.2.9, in rear of the EOA/LOA.<br>Note: for train speeds lower than 80 km/h, the time Tn always equals to<br>100ms.<br>In Level 2 for the immediate level transition order, the maximum<br>distance between the on-board antenna and the train front end (12.5m<br>+ max. distance first axle to front end) shall be added to the above<br>distances.<br>Exception: for an immediate level transition order, this rule does not<br>apply in case the level transition has been announced and the distance<br>for the execution of the level transition has been engineered such that<br>the level transition is performed before the EOA/LOA is passed.|
|---|---|
|Reference|SUBSET-036 section 5.2.2.5 (for the value 1.3 m); section 4.2.9 (for the<br>time Tn); section 5.6.3 (for the value 80 km/h).<br>ERA/ERTMS/033281 section 3.1.2 (for the max distance between the<br>first axle and the train front end).|
|Justification|-<br>The underlying approach is that all information related to the<br>extension of an MA or the level transition order at a border or the<br>“Stop if in SR” must have been received before the train is tripped,<br>or override is ended, due to overpassing the EOA/LOA.<br>-<br>This rule is sufficient to ensure that the action resulting from the<br>content of the balise group message will be considered by the on-<br>board as preceding the overpassing of the EOA/LOA with the train<br>“min safe antenna position”/”min safe front end”, i.e. it is sufficient<br>to avoid that a train trip will occur regardless the time needed to<br>process the balise group message (refer to SUBSET-026 section<br>A.3.5.2).<br>-<br>According to the FFFIS Eurobalise no further information can be<br>received from a balise if the (on-board) antenna has passed a balise<br>by a distance of more than 1.3m|

<!-- end of page 16 -->

4.1.1.5 Minimum distance between the last switchable balise of a balise group and limit of train detection section – for level 1

|Rule|If the transition from one train detection section to the following one<br>affects the information transmitted by a switchable balise, this<br>switchable balise shall be placed at least 13.8 m in rear of the location<br>where the detection device of the next section may start detecting the<br>train.|
|---|---|
|Reference|SUBSET-036 section 5.2.2.5 (for the values 1.3 m)|
|Justification|-<br>The aim of this rule is to avoid that the antenna of the train is still<br>able to read information coming from the balise group of block n,<br>while the train is already detected in block n+1 (e.g. as its 1<sup>st</sup>axle<br>short-circuits the track circuit of block n+1).<br>-<br>The rule takes into account the side lobe zone of the antennas and<br>the balises, the last switchable balise of the group is therefore to be<br>located at least 12.5 m (= the furthest location of the antenna in rear<br>of the 1<sup>st</sup>axle) + 1.3 m (= side lobe zone) = 13.8 m in rear of the<br>detection device limit (to be defined).|
||**12,5m**<br>**1,3m**<br>**LEU**|
||Block N+1<br>Block N|
|Comment|In case of jointless track circuits the train detection area is overlapping<br>both track circuits. The start of this area must be considered when<br>defining the distances.|

<!-- end of page 17 -->

#### 4.1.1.6 Number of balises that can be processed per unit of time

|Rule|Let “d” be the distance run by a train at the maximum speed of the line<br>during 0.8 s.<br>In this distance “d”, the number of encountered balises shall not exceed<br>8.<br>Note: The maximum speed of the line is the nominal line speed value<br>(engineered SSP). Tolerances due to inaccuracy of speed<br>measurements and speed margins before brake intervention are not to<br>be taken into account for engineering.|
|---|---|
|Reference|Limitations of SUBSET-036 - section 4.2.9 must be considered|
|Justification|The rule is linked to processing of balise information on-board|
|Remark|Figure<br>Interoperable constraints to ensure that all the balises can be<br>processed on-board<br>9 balises received in window d :  NOT OK<br>8 balises received in window d : OK|

#### 4.1.1.7 Balise group separation

|Rule|Between the first and the last balise of a balise group no balise of<br>another balise group shall be placed.|
|---|---|
|Reference||
|Justification|The interleaving of balise groups has not been considered in the<br>definition of the ETCS functions.|
|Remark|Placing a balise of a group within another balise group is sometimes<br>referred as “interleaving”.|

#### 4.1.1.8 Lateral and angular tolerances for balise installation

|Rule|Reminder: the rules of the reference below must be respected.|
|---|---|
|Reference|Subset-036 section 5.6.2.3|

<!-- end of page 18 -->

Justification -

4.1.1.9 Rules for balise installation in narrow curves

|Rule|Reminder: the rules of the reference below must be respected regards|
|---|---|
||the installation of Eurobalises in horizontal or vertical curves.|
|Reference|Subset-036 section 5.6.5|
|Justification|-|

4.1.1.10 Intentionally deleted

4.1.1.11 Balise group configurations

|Rule|Reminder: the rules of the reference below must be respected regards|
|---|---|
||- Number of balises in each group/use of single balise groups|
||- TSR Balise groups|
|Reference|SUBSET-091 – section 8.3.2.1|
|Justification||

4.1.1.12 Intentionally deleted

4.1.1.13 Balise installation relative to mission profile

|Rule|Reminder: the rules of the reference below must be respected e.g.|
|---|---|
||- Number of Unlinked Balise groups (marked as unlinked)<br>- Maximum distances between Balise groups|
|Reference|SUBSET-091 – chapter 10 Mission Profile|
|Justification|The safety analysis and safety requirements are based on this mission<br>profile of the reference above.|

### **4.1.2 Rules for Eurobalise antenna**

4.1.2.1 General installation rules for antennas (former 4.1.2.3)

|Rule|Reminder: Installation rules presented in FFFIS for Eurobalise shall be<br>respected.|
|---|---|
|Reference|SUBSET-036:|
||❑ Section 5.2 : Balise air gap interface|

<!-- end of page 19 -->

- ❑ Section 6.5 : Installation Requirements for Antennas ❑ Section 6.6: Specific Environmental Conditions for Antennas ❑ Section 6.7: Specific EMC Requirements for Antennas

- Justification

4.1.2.2 Minimum / maximum distance between the front of the engine / 1st axle of the engine and the Eurobalise antenna

Rule The antenna shall be placed such that the Reference Mark of the balise antenna lies:

- between 2m from the front of the engine and the 1<sup>st</sup> axle : The minimum value of 2m shall be ensured taking into account dynamic effects of the coupling

- or, up to 12.5 m in the rear of the 1<sup>st</sup> axle.

The front of an engine shall be defined by the extremity on the side of the active cab, the “1<sup>st</sup> axle” as the axle closest to the front of the engine. For an engine with a cab on each side, one antenna is sufficient if the areas of both sides where the antenna can be placed overlap, and the antenna, regards its reference mark, is placed in the overlapping part.

<!-- Start of picture text -->
allowed position<br>for antenna<br>max 12,5 m  min 2 m<br>Reference<br><!-- End of picture text -->

<!-- end of page 20 -->

- Justification The maximum value of 12.5m has been specified to allow the use of the same antenna for both directions, on a locomotive, and to provide sufficient space to install the antenna on all different types of trains. Furthermore the aim of the minimum distance of 2m to train front is :

<!-- Start of picture text -->
min 2 m min 2 m<br>-<br>to avoid an antenna receiving a telegram from a balise energised by<br>another antenna<br>-<br>to avoid a balise energised by one antenna perturbing the<br>transmission of an adjacent antenna.<br>Remark  Interference with antennas of other systems, especially KER based, has<br>to be considered as well.<br><!-- End of picture text -->

4.1.2.3 Intentionally deleted (former 4.1.2.2)

### **4.1.3 Rules for Euroloops**

4.1.3.1 Intentionally deleted

4.1.3.2 General installation rules for Euroloops

|Rule|Remin<br>respe|der: All installation rules given in FFFIS Euroloop have to be<br>cted.|
|---|---|---|
|Reference|SUBS|ET-044|
||❑|Section 6.1.3: Arrangements|
||❑ <br>❑|Section 6.10: Trackside Installation Rules<br>Section 6.11: Specific Electrical Requirements|
||❑|Section 6.13: EMC Requirements|
||❑|Section 7.8: Installation constraints for the Antenna Unit<br>Function|
|Justification|||

### **4.1.4 Intentionally deleted**

<!-- end of page 21 -->

## **4.2 Telegrams and messages**

### **4.2.1 Balise telegrams**

4.2.1.1 Length of balise telegrams (300 km/h, 500 km/h)

|Rule|Reminder: the rules of the references below must be respected.|
|---|---|
|Reference|SUBSET-036 section 5.2.2.3.|
|Justification|The rules are required in order to guarantee interoperability from a<br>transmission point of view.|

### **4.2.2 Radio messages**

Note: Radio messages means RBC messages or radio infill messages (the same protocol is used in both cases).

4.2.2.1 Maximum length per message – to allow for the dimensioning of radio input buffers

|Rule|Application data (excluding Euroradio protocol data) shall not exceed<br>500 bytes.|
|---|---|
|Reference||
|Justification|-<br>the length must be sufficient for MA - track description, according to<br>4.3.2.1 a)|
||-<br>transmission delay|
||-<br>more risk of perturbation|
||-<br>size of EVC buffers|

### **4.2.3 Intentionally deleted**

<!-- end of page 22 -->

### **4.2.4 Data engineering rules for individual data types**

4.2.4.1 Packet 145 (Inhibition of balise group, message consistency reaction)

|Rule|For all balise groups: it shall be forbidden to transmit the packet 145 if<br>the balise group message contains, for the same validity direction as<br>packet 145, safety related data that, if missed, could lead to the ETCS<br>core hazard.|
|---|---|
|Reference|SUBSET-026, section 3.16.2.4.4.1 b), 3.16.2.5.1.1 b), 7.4.2.37.2|
|Justification|According to SUBSET-091 table 14.1.1.2 footer 14, the message<br>consistency check is a protective feature, which has already been<br>credited when deriving the safety targets for the hazards BTM-H1, BTM-<br>H4, EUB-H1, EUB-H4.|

4.2.4.2 Sharing of identifiers within different transmission systems

|Rule|Reminder: the rules of the reference below must be respected|
|---|---|
|Reference|SUBSET-026, section 3.18.4.4|
|Justification||

#### 4.2.4.3 List of balises for SH Area

|Rule|It shall be forbidden to send the packet 49 (list of Balises for SH Area)<br>in a message which does not contain the packet 80 (Mode Profile) with<br>the variable M_MAMODE = “Shunting”.<br>Exception: the rule does not apply for the radio message “SH<br>authorised” since its list of optional packets includes the packets 3, 44<br>and 49 only.|
|---|---|
|Reference|SUBSET-026, section 4.4.8.1.1 b), 8.4.4.4.1|
|Justification|The on-board must always link a list of balises for SH area to either one<br>given mode profile “Shunting” or to one SH authorisation from the RBC.|

<!-- end of page 23 -->

#### 4.2.4.4 Transmission of non-infill information by loop or RIU

|Rule|The following non-infill information can be transmitted from a loop:<br>-<br>Packet 13 (SR distance information from loop)<br>-<br>Packet 44 (Data used by applications outside the ERTMS/ETCS<br>system)<br>-<br>Packet 180 (LSSMA display toggle order)<br>-<br>Packet 254 (Default Balise/Loop/RIU information)<br>The following non-infill information can be transmitted from an RIU:<br>-<br>Message 32 (RBC/RIU System Version)<br>-<br>Message 39 (Acknowledgement of session termination)<br>-<br>Packet 44 (Data used by applications outside the ERTMS/ETCS<br>system)<br>-<br>Packet 45 (Radio Network transition order)<br>-<br>Packet 143 (Session Management with neighbouring RIU)<br>-<br>Packet 180 (LSSMA display toggle order)<br>-<br>Packet 254 (Default Balise/Loop/RIU information)|
|---|---|
|Reference|SUBSET-026 - 3.6.2.3, 4.8.1.5<br>SUBSET-040 - 4.2.4.5|
|Justification|To clarify which packets not included in the list of allowable infill packets<br>defined in section 4.2.4.5 can nevertheless be transmitted by loop or<br>RIU.|

<!-- end of page 24 -->

#### 4.2.4.5 Infill Information

#### 4.2.4.5.1

|Rule|Infill information which is repeated from the balise group at the next<br>main signal by any infill device shall be limited to infill MA, linking and<br>route related track description information. All information which does<br>not relate to Infill (e.g. information for opposite direction or EOLM etc.)<br>shall not be given as infill information.<br>Permitted infill information:<br>-<br>Packet 136 (infill location reference)<br>-<br>Packet 12, 80, 49 (MA, Mode Profile, List of Balises for SH area)<br>-<br>Packet 21 (Gradient Profile)<br>-<br>Packet 27, 51, 65, 70 (SSP, ASP, TSR, Route Suitability)<br>-<br>Packet 5 (Linking)<br>-<br>Packet 41 (Level transition) (see also next rule below)<br>-<br>Packet 44 (data used outside ERTMS) (only if NID_XUSER ≠102)<br>-<br>Packet 39, 40, 67, 68, 69 (Track condition)<br>-<br>Packet 71 (adhesion factor)<br>-<br>Packet 133 (Radio in-fill area information)<br>-<br>Packet 138, 139 (Reversing area/supervision information)<br>-<br>Packet 52 (Permitted Braking Distance Information)<br>-<br>Packet 88 (Level Crossing Information)|
|---|---|
|Reference|SUBSET-026 – section 3.8.4.6.3|
|Justification|This is to avoid any misinterpretation by on-board.|

#### 4.2.4.5.2

|Rule|If infill information contains an announcement of an immediate level|
|---|---|
||transition at the location of the location reference for the infill|
||information, for the distance D_LEVELTR the value of “0m” shall be|
||used.|
|Justification|For infill only distance based information can be interpreted on-board|

#### 4.2.4.5.3

|Rule|Upon reception of an infill MA, the infill location reference given by the|
|---|---|
||infill device must be in rear of the current EOA/LOA.|
|Reference|SUBSET-026 – section 3.4.3.1; 3.8.4.6.2-4; 4.8.1.5|

<!-- end of page 25 -->

Justification

An MA extension via an infill MA is only possible if there is no gap between the old MA and the MA extension.

#### 4.2.4.6 Mode Profile

#### 4.2.4.6.1

#### 4.2.4.6.2

|Rule|The overlapping of mode profile areas in the mode profile packet shall<br>be forbidden.|
|---|---|
|Reference||
|Justification|There is no possibility to handle two mode profiles at the same location.|
|Rule|In case a Level 1 MA contains V_MAIN = 0 and the MA is transmitted<br>with a mode profile, the mode profile shall start at distance zero.|
|Reference|SUBSET-026 – 4.6.2 & 4.6.3 transition [32]|
|Justification|The procedures for mode transitions caused by mode profiles in Subset<br>026, chapter 5 do not cover “further location” transitions from SR mode<br>to OS, SH, LS.|

#### 4.2.4.6.3

|Rule|It shall be forbidden to announce a mode profile area in advance of an|
|---|---|
||SH area.|
|Reference||
|Justification|To avoid conflicting mode transition conditions.|

#### 4.2.4.6.4

|Rule|It shall be forbidden to send in the same message a mode profile SH<br>area for current location together with an immediate level transition<br>order to level 0 or level NTC, or with a conditional level transition order<br>that causes a level transition to level 0 or level NTC.|
|---|---|
|Reference||
|Justification|To avoid conflicting mode transition conditions.|

<!-- end of page 26 -->

4.2.4.7 Track conditions

4.2.4.7.1

<!-- end of page 27 -->

Rule The minimum distance (latest transmission) between announcement of track condition Powerless Section with pantograph to be lowered and the start location of this track condition shall correspond to 17s when running at line speed (engineered SSP) in the approach area (B-D in the figure below).

The minimum distance (latest transmission) between announcement of track condition Powerless Section with main power switch to be switched off and the start location of this track condition shall correspond to 11s when running at line speed (engineered SSP) in the approach area (B-D in the figure below).

<!-- Start of picture text -->
running direction  powerless section<br>A  B  D  Pantograph lowered/  E<br>Main power switch<br>switched off<br>LRBG/ORBG<br>Announcement distance<br>D_TRACKCOND  L_TRACKCOND<br>The minimum distance (latest transmission) between announcement of<br>track condition Change of Traction System and the location of this track<br>condition shall correspond to 17s when running at line speed<br>(engineered SSP) in the approach area (B-F in the figure below).<br><!-- End of picture text -->

<!-- Start of picture text -->
running direction<br>A  C B<br>LRBG/ORBG<br>Announcement distance  F<br>D_TRACTION<br>A: LRBG/ORBG which is the location reference point for the distances<br>given<br>B: latest announcement location<br>D: start location of track condition Powerless Section with pantograph<br>to be lowered or with main power switch to be switched off<br>E: end location of track condition Powerless Section with pantograph to<br>be lowered or with main power switch to be switched off<br>F: location for track condition Change of Traction System<br>Reference  SUBSET-026 –section 3.7.1.1 c)<br><!-- End of picture text -->

<!-- end of page 28 -->

Justification This distance needs to be long enough to ensure that the driver (or an optional automatic system) is able to perform the necessary actions (e.g. reduce traction power, open the main switch, lower the pantograph, change the traction system) before reaching the beginning of the powerless section or the location of the change of traction system, respectively.

#### 4.2.4.7.2

|Rule|The minimum distance (latest transmission) between announcement of<br>track condition<br>-<br>Air tightness<br>-<br>Switch off regenerative/eddy current<br>(service/emergency)/magnetic shoe brake<br>and the start location of this track condition shall correspond to 10s<br>when running at line speed (engineered SSP) in the approach area.|
|---|---|
|Reference|SUBSET-026 –section 3.7.1.1 c)|
|Justification|This distance needs to be long enough to ensure that the driver (or an<br>optional automatic system) is able perform the related action before<br>reaching the beginning of the track condition.|

#### 4.2.4.8 Linking data handling

#### 4.2.4.8.1

|Rule|Balise groups with balise group qualifier “unlinked” shall never be<br>announced via linking.|
|---|---|
|Reference||
|Justification|This is to avoid any contradiction between the consistency reaction<br>regarding “Unlinked” balise groups and the one regarding announced<br>linking reaction.|

<!-- end of page 29 -->

#### 4.2.4.8.2

|Rule|Balise groups with balise group qualifier “unlinked” shall never be used<br>to transmit linking information unless it is sent as infill information (see<br>4.2.4.5 herein).|
|---|---|
|Reference|SUBSET-026 – section 3.6.1.4|
|Justification|Balise groups with a balise group qualifier “unlinked” can never become<br>an LRBG.|
||This rule aims at reducing system complexity caused by the relocation<br>of information received from a mixture of linked and unlinked balise<br>groups which in addition only leads to a degradation of performance.|

#### 4.2.4.9 Packets 65 and 66 (Temporary Speed Restrictions)

|Rule|It shall be forbidden to use the same identity (NID_TSR) for a TSR<br>referred to in packets 65 and 66 sent in the same message.|
|---|---|
|Reference||
|Justification|This is to avoid any contradiction between enforcing/replacing and<br>revoking a TSR.|

4.2.4.9.1 Intentionally deleted

4.2.4.9.2 Intentionally deleted

4.2.4.10 Supervised Manoeuvre authorisation

- 4.2.4.10.1

|Rule|All information being part of a Supervised Manoeuvre authorisation|
|---|---|
||shall have the same unidirectional validity direction.|
|Reference|SUBSET-026, 3.6.1.5.1|
|Justification|The direction of the Movement Authority within a Supervised<br>Manoeuvre authorisation determines the train orientation.|

- 4.2.4.10.2

|Rule|It shall be forbidden to give a Supervised Manoeuvre authorisation over<br>a level transition border where the border BG contains an immediate<br>level transition order or a conditional level transition order that, when<br>evaluated, would lead to a level transition to another level than 2.|
|---|---|
|Reference|SUBSET-026, 4.4.21.1.11|
|Justification|The SM mode is only used in level 2.|

#### 4.2.4.10.3

<!-- end of page 30 -->

|Rule|It shall be forbidden to give a Supervised Manoeuvre authorisation over<br>an RBC/RBC border in case the neighbouring RBC is certified to a<br>system version X.Y < 2.3.|
|---|---|
|Reference||
|Justification|Neither can the SM mode be handled by an RBC certified with a system<br>version X.Y < 2.3 nor can an alternative mode be used by the “Handing<br>Over” RBC to report the on-board mode to such neighbouring RBC.|

#### 4.2.4.10.4

|Rule|It shall be forbidden to give a Supervised Manoeuvre authorisation<br>which changes the train orientation as long as the min safe rear end of<br>the consist is inside the area of another RBC.|
|---|---|
|Reference||
|Justification|With regards to its direction, such Movement Authority would<br>automatically extend beyond the RBC/RBC border, e.g. into the area of<br>the former “Handing Over” RBC while this latter is no longer the<br>supervising one.|

#### 4.2.4.11 Packet 131 (RBC Transition Order)

|Rule|It shall be forbidden to use the special value “Contact the last known<br>RBC” for the RBC ETCS identity number NID_RBC.|
|---|---|
|Reference|SUBSET-026 – section 7.5.1.96|
|Justification|Using the special value “Contact the last known RBC” would point to<br>the “Handing Over” RBC which makes no sense in announcing an RBC<br>Handover|

#### 4.2.4.12 Packet 42 (Session Management) and Packet 131 (RBC Transition Order)

|Rule|It shall be forbidden to send a session establishment order with an RBC<br>certified with the system version X.Y < 2.3 to an on-board in Supervised<br>Manoeuvre mode.|
|---|---|
|Reference||
|Justification|Neither can the SM mode be handled by an RBC certified with a system<br>version X.Y < 2.3 nor can an alternative mode be used by the on-board<br>to report its mode to such neighbouring RBC.|

<!-- end of page 31 -->

#### 4.2.4.13 Packet 88 (Level Crossing information)

|Rule|The location of a level crossing, as defined by the combination of D_LX|
|---|---|
||and L_LX, shall not coincide with the location of another level crossing,<br>i.e. the defined positions of crossings shall be independent.|
|Reference|SUBSET-026 - section 3.12.5.4|
|Justification||

#### 4.2.4.14 Packets 72 and 76 (text messages)

#### 4.2.4.14.1

|Rule|The use of the sub-condition “location” for the end condition shall be<br>allowed only if the sub-condition “location" is used for the start condition.|
|---|---|
|Reference|SUBSET-026 – section 3.12.3.4; 7.4.2.23; 7.4.2.24|
|Justification||

#### 4.2.4.14.2

#### 4.2.4.14.3

|Rule|It shall be forbidden to use as sub-condition for the start/end condition<br>a mode which can be left by the on-board as a result from a mode profile<br>for current location given in the same trackside message.<br>It shall be forbidden to use as sub-condition for the start/end condition<br>a level which can be left by the on-board as a result from an immediate<br>level transition order or from a conditional level transition order given in<br>the same trackside message.<br>It shall be forbidden to use as sub-condition for the start/end condition<br>a mode which can be left by the on-board as a result from an immediate<br>level transition order or from a conditional level transition order given in<br>the same trackside message.|
|---|---|
|Reference|SUBSET-026 – section 3.12.3.4; 7.4.2.23; 7.4.2.24|
|Justification|This is to avoid any misinterpretation by the on-board|
|Remark|This engineering rule does not address a change of mode or level that<br>might result from a mode profile for further location or from a level<br>transition announcement, which cannot be covered by a generic rule.|
|Rule|It shall be forbidden to use the special value “Contact the last known<br>RBC” for the RBC ETCS identity number NID_RBC.|

<!-- end of page 32 -->

|Reference|SUBSET-026 – sections 7.4.2.23; 7.4.2.24|
|---|---|
|Justification|The driver acknowledgement report is to be sent to the RBC interested<br>in such report, which cannot be ensured by the use of the special value.|

#### 4.2.4.15 Shifted location reference

|Rule|It shall be forbidden to send a message with Shifted Location Reference<br>(D_REF <>0m) containing information applicable to both directions<br>(Q_DIR = both), unless the co-ordinate system of the referenced balise<br>group is proven to be known to the on-board (e.g. through a packet 0).|
|---|---|
|Reference|SUBSET-026, sections 3.6.3.1.4, 3.6.3.2.5.|
|Justification|The on-board must know the co-ordinate system of the reference<br>balise group to determine the direction to shift the location reference.<br>In case this is a single balise group, which has been reported as<br>LRBG via a Packet 1, the co-ordinate system of the balise group may<br>be unknown to the on-board.<br>The rule ensures that the on-board is not required to evaluate for<br>acceptance information that is valid for both directions (see Subset-026<br>3.6.3.1.3.1), when the direction to shift the location reference cannot be<br>determined.|

4.2.4.16 Packet 32 (Session management for RBC interfaced to FRMCS only) and Packet 42 (Session Management for RBC interfaced to GSM-R)

|Rule|It shall be forbidden to send in a message a packet 32 together with a|
|---|---|
||packet 42 for the same direction.|
|Reference||
|Justification||

4.2.4.17 Packet 31 (RBC transition order for RBC interfaced to FRMCS only) and Packet 131 (RBC transition order for RBC interfaced to GSM-R)

|Rule|It shall be forbidden to send in a message a packet 31 together with a|
|---|---|
||packet 131 for the same direction.|
|Reference||
|Justification||

<!-- end of page 33 -->

## **4.3 Dimensioning rules for messages**

### **4.3.1 Constraints**

4.3.1.1 The maximum number of iterations of the same type of information:

|Rule|In case the Engineering rules limit the number of iterations of a certain<br>type of information, this shall take precedence over the 31 (= maximum<br>of N_ITER) iterations stated in chapter 7 of the SRS.|
|---|---|
|Reference|SUBSET-026 – section 7.5.1.77|
|Justification|In chapter 7 of the SRS, a nominal value range for N_ITER was chosen<br>in order to rationalise the ETCS language. Where specific limits for<br>N_ITER are required, they are stated in the Engineering Rules<br>document.|
|Remark||

### **4.3.2 Data**

4.3.2.1 List of data that are related to dimensioning rules:

a) Number of MA sections (excluding the End Section)

||Maximum number of iterations in 1<br>packet|Minimum memorised on board|
|---|---|---|
|Rule|5|6|
|Reference|||
|Justification||The use of infill information<br>requires at least one additional<br>section to be memorised.|
|Remark|In addition the MA includes an End<br>above numbers|Section which is not included in the|

b) Number of balise IDs in balise list for SR authority or for shunting mode

||Maximum number of iterations in 1<br>packet|Minimum memorised on board|
|---|---|---|
|Rule|15 being transmitted using the||
||same packet||
|Reference|||

<!-- end of page 34 -->

|Justification|This packet will never be|A new incoming balise list|
|---|---|---|
||combined with other packets|replaces the previous one.|
||requiring a big data volume.||

#### c) Number of mode profile sections

||Maximum number of iterations in 1<br>packet|Minimum memorised on board|
|---|---|---|
|Rule|2|6|
|Reference|SUBSET-026 section–7.4.2.26<br>and section 4.2.4.6 herein||
|Justification||A mode profile contained in an<br>Infill MA replaces the one stored<br>only beyond the reference<br>location. Therefore onboard can<br>currently have 3 sections of mode<br>profiles, and receive 3 more<br>sections in the Infill MA.|

#### d) Number of locations with changes of SSP

||Maximum number of iterations in 1<br>packet|Minimum memorised on board|
|---|---|---|
|Rule|31|50|
|Reference|||
|Justification||50 SSP sections memorised on-<br>board with a change of SSP<br>section every 500m would cover a<br>distance of 25km.|

#### e) Number of TSR

||Maximum number of packets in 1|Minimum memorised on board|
|---|---|---|
||message||
|Rule|10|30|
|Reference|||
|Justification|||

<!-- end of page 35 -->

#### f) Number of changes of gradient

||Maximum number of iterations in 1<br>packet|Minimum memorised on board|
|---|---|---|
|Rule|31|50|
|Reference|||
|Justification||50 gradients memorised on-board<br>with a change in gradient every<br>500m would cover a distance of<br>25 km.|

#### g) Number of locations for position reports

||Maximum number of iterations in 1<br>packet|<br>Minimum memorised on board|
|---|---|---|
|Rule|15||
|Reference|||
|Justification|||
|Remark||If a train gets a new packet 58<br>from the RBC, it replaces the old<br>position report parameter.|

#### h) Number of text messages

||Maximum number of iterations in 1<br>packet|<br>Minimum memorised on board|
|---|---|---|
|Rule|1 plain text + 1 fixed text|5 plain text + 5 fixed text|
|Reference|||
|Justification|||

#### i) Number of linked balise groups

||Maximum number of iterations in 1<br>packet|Minimum memorised on board|
|---|---|---|
|Rule|29|30|
|Reference|||
|Justification|29 iterations allow for a maximum of<br>30 linked balise groups to be<br>transmitted in onepacket. Because|The on-board system should be<br>able to manage an MA of 30 km|

<!-- end of page 36 -->

new linking information completely with an average of 1 linked overwrites old information, the balise group per km. amount of linked balises to be stored is unchanged Exception: In case linking information is transmitted as infill information, Engineering must take care of any balises between the infill location and the infill reference location (i.e. the main signal balise group) which remain stored onboard

#### j) Number of Track Conditions Change of traction system

||Maximum number of iterations in 1<br>packet|<br>Minimum memorised on board|
|---|---|---|
|Rule|No iteration in packet|1|
|Reference|SUBSET-026 – section 7.4.2.8||
|Justification||The onboard system is able to<br>manage one change of traction<br>system at a time.|

#### k) Number of Track Conditions Big Metal masses

||Maximum number of iterations in 1<br>packet|<br>Minimum memorised on board|
|---|---|---|
|Rule|4|5|
|Reference|SUBSET-026 – section 7.4.2.19||
|Justification|||

#### l) Number of Track Conditions

||Maximum number of iterations in 1<br>packet|<br>Minimum memorised on board|
|---|---|---|
|Rule|19|20|
|Reference|SUBSET-026 – section 7.4.2.20||
|Justification|||

<!-- end of page 37 -->

#### m) Number of Route suitability data

||Maximum number of iterations in 1<br>packet|Minimum memorised on board|
|---|---|---|
|Rule|2|1 list of loading gauges AND|
|||1 list of axle load categories AND|
|||1 value of traction system type.|
|Reference|SUBSET-026 – section 7.4.2.21||
|Justification|||

- n) Intentionally deleted

- o) Number of Axle load speed profile segments

||Maximum number of iterations of|Minimum memorised on board|
|---|---|---|
||ASP segments in 1 packet||
|Rule|14|30|
|Reference|SUBSET-026 – section 7.4.2.13||
|Justification|||

- p) Number of Axle load speed restriction values per ASP segment

||Maximum number of iterations per|Minimum memorised on board|
|---|---|---|
||ASP segment||
|Rule|13||
|Reference|SUBSET-026 – section 7.4.2.13||
|Justification|||

#### q) Number of adhesion profiles

||Maximum number of iterations in 1<br>packet|Minimum memorised on board|
|---|---|---|
|Rule|No iteration in packet|10|
|Reference|SUBSET-026 – section 7.4.2.22||
|Justification|||

#### r) Number of reversing area

<!-- end of page 38 -->

||Maximum number of iterations in 1<br>packet|Minimum memorised on board|
|---|---|---|
|Rule|No iteration in packet|1|
|Reference|SUBSET-026 – section 7.4.2.34||
|Justification|||

#### s) Number of Permitted Braking Distance Speed Restrictions

||Maximum number of iterations in 1<br>packet|Minimum memorised on board|
|---|---|---|
|Rule|5|16|
|Reference|SUBSET-026 – section 7.4.2.13.1||
|Justification|||

#### t) Number of Track Conditions Station Platforms

||Maximum number of iterations in 1<br>packet|Minimum memorised on-board|
|---|---|---|
|Rule|4|5|
|Reference|SUBSET-026 – section 7.4.2.20.1||
|Justification|||

u) Number of Track Conditions Allowed Current Consumption

||Maximum number of iterations in 1<br>packet|Minimum memorised on board|
|---|---|---|
|Rule|No iteration in packet|1|
|Reference|SUBSET-026 – section 7.4.2.8.1||
|Justification|||

v) Number of Level Crossings

<!-- end of page 39 -->

||Maximum number of packets in 1|Minimum memorised on board|
|---|---|---|
||message||
|Rule|10|10|
|Reference|||
|Justification|||

#### w) Number of Virtual Balise Covers set by trackside

||Maximum number of packets in 1<br>message|Minimum memorised on board|
|---|---|---|
|Rule|10|10|
|Reference|SUBSET-026 – section 7.4.2.2.1||
|Justification|||
|Remark||The minimum number stored on-<br>board of this rule does not include<br>the minimum number of VBCs set<br>by driver that the on-board must<br>be able to store (see rule 4.5.1.2)|

#### x) Size of packet 44 with NID_XUSER = 102

||Maximum number of bytes in<br>packet 44 if NID_XUSER = 102|Minimum memorised on board|
|---|---|---|
|Rule|222||
|Reference|SUBSET-026 sections 3.15.6.5<br>and 7.4.2.11<br>SUBSET-058 section 7.2.22||
|Justification|The total size of a packet 44 with<br>NID_XUSER = 102, which will be<br>forwarded in its entirety to an STM<br>inside packet STM-45, must not<br>exceed the maximum number of<br>bytes which can be transmitted as<br>user data in packet STM-45 (i.e.<br>maximum value of variable<br>N_LITER).|No memorisation applicable|
|Remark|The rule is only relevant for radio<br>messages. In a balisegroup||

<!-- end of page 40 -->

message, the maximum allowed size can never be exceeded.

4.3.2.1.1 Note: The value for the “Maximum number of iterations in 1 packet” in the rules above refers to the value of N_ITER in the related packets.

### **4.3.3 Intentionally deleted**

### **4.3.4 Multiple instances of Packets**

4.3.4.1 Intentionally deleted

4.3.4.2 Multiple instances of packets in messages

|Rule|Reminder: with regards to multiple instances of the same Packet inside|
|---|---|
||a message, the rules of the references below must be respected.|
|Reference|SUBSET-026 – section 8.4.1.4|
|Justification||

### **4.3.5 Intentionally deleted**

## **4.4 Rules for on-board configuration data**

### **4.4.1 Braking curves**

#### **4.4.1.1 Introduction**

4.4.1.1.1 In order to properly set the National Values for braking curves, it is necessary to define the conditions under which the nominal emergency brake deceleration, brake reaction time, and brake build up time are determined for the rolling stock.

4.4.1.1.2 If the braked weight percentage is acquired as Train Data by the ERTMS/ETCS on-board equipment and if the conversion model is applicable (i.e. the train is said to be a “Lambda” train), the speed dependent deceleration profile, the brake reaction time and brake build up time, which are obtained from the Conversion Model, are to be considered as the nominal emergency brake deceleration, brake reaction time, and brake build up time.

4.4.1.1.3 Otherwise, the nominal emergency brake deceleration profile(s), brake reaction time(s), and brake build up time(s) are preconfigured and acquired as ETCS Train Data by the ERTMS/ETCS on-board equipment (i.e. the train is said to be a “Gamma” train), and the rules specified in the section 4.4.1.2, 4.4.1.3, 4.4.1.4 and 4.4.1.5 shall apply.

<!-- end of page 41 -->

4.4.1.1.3.1 Note: these rules are applicable for one set of emergency brake deceleration profile, brake reaction time and brake build up time, and rolling stock correction factors belonging to a given set of ETCS Train Data, regardless of whether this latter covers one or more train formations.

4.4.1.1.4 For default Train Data for Supervised Manoeuvre, only preconfigured braking models (brake reaction time, brake build up time and speed dependent deceleration profile) shall be used. However, the rules specified in the section 4.4.1.2, 4.4.1.3, 4.4.1.4 and 4.4.1.5 shall not be compulsory.

#### **4.4.1.2 Nominal emergency brake deceleration profile**

**4.4.1.2.1 Environmental conditions**

4.4.1.2.1.1 The nominal emergency brake deceleration shall be based on the environmental conditions according to section 6.4.2 of EN 16834:2019.

#### **4.4.1.2.2 Humidity of friction elements**

4.4.1.2.2.1 The emergency brake deceleration shall be based on dry friction elements.

**4.4.1.2.3 Track profile**

4.4.1.2.3.1 If field tests are carried out to define the nominal emergency brake deceleration, they shall be performed on straight and as level as possible track. The deceleration shall be corrected to level track.

#### **4.4.1.2.4 Load**

#### **4.4.1.2.4.1 Passenger trains without automatic loading device**

4.4.1.2.4.1.1 The nominal emergency brake deceleration shall be valid for normally loaded vehicles (see clauses 4.2.4.5.2 (5) & (6) of the TSI LOC&PAS).

**4.4.1.2.4.2 Passenger trains with automatic loading device**

4.4.1.2.4.2.1 For vehicles with automatic loading device the nominal emergency brake deceleration shall be defined as the lowest deceleration from the whole loading range (from empty to exceptional load) and if the lowest deceleration is obtained by several loads then the greatest load shall be taken into account as the nominal loaded condition

#### **4.4.1.2.5 Use of special brake systems**

4.4.1.2.5.1 Note: All installed brake systems can be considered in the nominal emergency brake deceleration, based on a reliability/availability study.

4.4.1.2.5.2 In case special brake system(s) (regenerative brake, magnetic shoe brake or eddy current brake) is/are considered in the nominal emergency brake deceleration and if the train is running on lines where a certain special brake system is not permitted or must be inhibited at certain locations (through the track condition “Inhibition of special

<!-- end of page 42 -->

brakes”), further nominal deceleration profiles without the contribution of the concerned special brake system shall be defined.

4.4.1.2.5.3 In case the dynamic brake not independent from the presence of voltage in the catenary (i.e. regenerative brake not backed up by a rheostatic brake) is included in the nominal emergency brake deceleration, further nominal deceleration profile(s) without the contribution of this brake shall be defined. Justification: the train will always encounter a powerless section (through the track condition “powerless section”) wherever it will operate.

#### **4.4.1.2.6 Wheel diameter**

4.4.1.2.6.1 The nominal deceleration shall be based on new wheel diameter.

#### **4.4.1.3 Emergency brake build up time**

4.4.1.3.1 The nominal brake build up time shall be the equivalent brake build-up time as specified in section 3.13.2.2.3.2 of SUBSET-026.

4.4.1.3.2 The nominal brake reaction time shall be the brake reaction time as specified in section 3.13.2.2.3.2 of SUBSET-026.

#### **4.4.1.4 Rolling Stock Correction factor Kdry_rst**

4.4.1.4.1 Kdry_rst(V,EBCL) shall be established for each confidence level that can be required by trackside (refer to sections 3.13.2.2.9.1.2, 3.13.2.2.9.1.3, 3.13.2.2.9.1.4 and variable M_NVEBCL in SUBSET-026). For the dry rail reference conditions, see section 4.4.1.2.1.

4.4.1.4.2 Note: The Monte Carlo methodology has shown to be suitable for the determination of the Kdry_rst values. However another methodology can be chosen, provided that it can be demonstrated that the required confidence levels are achieved.

**4.4.1.5 Rolling Stock Correction factor Kwet_rst**

#### **4.4.1.5.1 Trains fitted with wheel slide protection system**

4.4.1.5.1.1 In order to determine the correction factor Kwet_rst(V), results from the vehicle implementation tests of the WSP system in accordance with EN15595:2018+AC:2021 shall be taken into account. The following tests in accordance with Table 4 of EN15595:2018+AC:2021 shall be considered:

   - Test No 4 ‐ Dry rail; 120 km/h to stop; considering only maximum deceleration (emergency brake application);

   - Test No 2 ‐ Dry rail, maximum speed to stop; maximum deceleration (emergency brake application);

   - Test No 5 ‐ Low adhesion (sprayed rail); 120 km/h to stop; maximum deceleration (emergency brake application);

   - Test No 6 ‐ Low adhesion (sprayed rail); maximum speed to stop; maximum deceleration (emergency brake application).

<!-- end of page 43 -->

4.4.1.5.1.2 For each pair of deceleration distances (on dry rail and with low adhesion) obtained from the tests 4 & 5 and 2 & 6, the increase of deceleration distance (in %) obtained from the tests shall be used as follows to determine the correction factor: Kwet_rst = 100/(100+ increase of deceleration distance (in %)), with the deceleration distance resulting from tests 5 & 6 being the mean of the valid tests.

4.4.1.5.1.3 The deceleration distance is defined as the total distance travelled from the triggering of brake command to the train stop, minus the distance travelled from this triggering to the elapsing of the equivalent brake build up time.

4.4.1.5.1.4 In case a unique Kwet_rst (i.e. valid for all speeds) is defined, the maximum increase of deceleration distance between the tests 4 & 5 and 2 & 6 shall be retained.

4.4.1.5.1.5 Note: supplementary tests at other initial speeds (e.g. low speed) may be performed according to the same requirements, e.g. depending on a particular braking system configuration.

#### **4.4.1.5.2 Trains not fitted with wheel slide protection system**

4.4.1.5.2.1 For trains where the first four braked wheelsets are not fitted with a WSP system (without which the reference wheel/rail adhesion condition cannot be validated) the field tests specified in EN15595:2018+AC:2021 cannot be used and the rules of §4.4.1.5.1 shall not be applied.

4.4.1.5.2.2 Note: For such trains, any value lower than or equal to 1 for the rolling stock correction factor Kwet_rst may be used.

### **4.4.2 On-board Supported Levels**

|Rule|The default list of levels configured on-board shall include all the levels|
|---|---|
||fitting the trackside infrastructures where the train has been granted|
||access (i.e. the levels listed in the Interoperability Registers on the|
||concerned infrastructures).|
|Reference|SUBSET-026 section 3.18.4.2|

<!-- end of page 44 -->

|Justification|The ERTMS/ETCS on-board equipment must always be able to switch<br>to a level ordered by trackside (i.e. fitting the line where the train is),<br>independently from the availability of the parts of the on-board<br>equipment allowing to support this level.<br>In case of degraded operation, it is always the responsibility of the<br>Infrastructure Manager to order the level the on-board will switch to and,<br>even though the train is not fitted with the National System<br>corresponding to the ordered level, to instruct the driver to follow the ad-<br>hoc operating rules applicable for a train with a failed National System.<br>Therefore the so-called on-board default list of levels is not an unilateral<br>choice made by the Railway Undertaking based on the devices the on-<br>board is fitted with, but is rather a substitute of the list of trackside<br>supported levels (packet 41) ordered by trackside when this list is not<br>stored on-board.|
|---|---|

### **4.4.3 Data Checks for Driver Input**

#### 4.4.3.1 Permitted Range and Resolution for Data Check Rules

|Rule|The permitted range(s) for the technical and/or operational checks of a<br>specific input field shall be within the limits defined in Subset-026,<br>section A.3.11.<br>The permitted resolution for a specific input field shall be equal to or<br>lower than that defined in Subset-026, section A.3.11.|
|---|---|
|Reference|SUBSET-026 section A.3.11<br>ERA_ERTMS_015560 section 10.3.4|
|Justification|Data check rules for data entered by the driver must comply with the<br>limits defined by the SRS for this data.|

#### 4.4.3.2 Mandatory Technical Range Checks

|Rule|The ERTMS/ETCS on-board shall be configured with the technical<br>permitted range for the input field ‘Maximum Speed (km/h)’|
|---|---|
|Reference|ERA_ERTMS_015560, 10.3.4.1.2, 11.3.9.4.|
|Justification|The rule ensures that a technical range check will always be performed<br>whenever the Maximum Speed (km/h) is entered by the driver.|
|Remark|The rule is applicable only if the mentioned input field is available to the<br>driver, see ERA_ERTMS_015560 11.3.9.5.|

<!-- end of page 45 -->

## **4.5 On-board dimensioning rules**

#### 4.5.1.1 STM related dimensioning rules

|Rule|Reminder: the rules of the references below must be respected.|
|---|---|
|Reference|SUBSET-035|
||❑ Section 15 Limitations|
|Justification||

#### 4.5.1.2 Storage of Virtual Balise Covers set by driver

|Rule|The ERTMS/ETCS on-board equipment shall be able to store at least<br>20 VBCs set by the driver|
|---|---|
|Reference|SUBSET-026 – section 3.15.9.2|
|Justification|In case of cross border cold movement from an LUC A to another LUC<br>B, there should be sufficient storage capacity left for further VBC data<br>entry by driver, assuming that the number of VBCs stored on-board<br>from driver data entry in LUC A does not exceed the maximum allowed<br>number of VBC that can be enforced by trackside at a time (see rule<br>4.3.2.1.1w)|

<!-- end of page 46 -->

## **4.6 On-board odometer engineering rules**

#### 4.6.1.1 Parallelism of distances measured on-board

|Rule|For any couple of reference balise groups BG1 and BG2 part of Train<br>Position information and any couple of times t1 and t2 posterior to their<br>receptions, the estimated front end position, min safe front end position<br>and max safe front end position referred to BG1 and BG2 shall fulfil the<br>following property:<br>•<br>estimated front end position(t2, BG1) – estimated front end<br>position(t1, BG1) =<br>estimated front end position(t2, BG2) – estimated front end<br>position(t1, BG2)<br>•<br>min safe front end position(t2, BG1) – min safe front end<br>position(t1, BG1) =<br>min safe front end position(t2, BG2) – min safe front end<br>position(t1, BG2)<br>•<br>max safe front end position(t2, BG1) – max safe front end<br>position(t1, BG1) =<br>max safe front end position(t2, BG2) – max safe front end<br>position(t1, BG2)|
|---|---|
|Reference|SUBSET-026 section 3.6.4.2.5 c), SUBSET-091 section 12|
|Justification|In case of relocation without linking, this property ensures that applying<br>the formulas in SUBSET-026 clause 3.6.4.2.5 c) has no impact on the<br>probability of occurrence of the base event ODO-4.|

<!-- end of page 47 -->
