# **APPENDIX TO CHAPTER 3**

## **A.3.1 List of Fixed Value Data**

|**Fixed Value Data**|**Value**|**Name**|
|---|---|---|
|The number of times to try to establish a safe radio<br>connection.|3 times||
|Repetition of radio messages (i.e. excluding the first<br>sending)|3 times||
|Waiting time before radio message repetition|15 s||
|Speed difference between Permitted speed and<br>Emergency Brake Intervention supervision limits,<br>minimum value|7.5 km/h|dV_ebi_min|
|Speed difference between Permitted speed and<br>Emergency Brake Intervention supervision limits,<br>maximum value|15 km/h|dV_ebi_max|
|Value of MRSP where dV_ebi starts to increase to<br>dV_ebi_max|110 km/h|V_ebi_min|
|Value of MRSP where dV_ebi stops to increase to<br>dV_ebi_max|210 km/h|V_ebi_max|
|Speed difference between Permitted speed and<br>Service Brake Intervention supervision limits, minimum<br>value|5.5 km/h|dV_sbi_min|
|Speed difference between Permitted speed and<br>Service Brake Intervention supervision limits, maximum<br>value|10 km/h|dV_sbi_max|
|Value of MRSP where dV_sbi starts to increase to<br>dV_sbi_max|110 km/h|V_sbi_min|
|Value of MRSP where dV_sbi stops to increase to<br>dV_sbi_max|210 km/h|V_sbi_max|
|Speed difference between Permitted speed and<br>Warning supervision limits, minimum value|4 km/h|dV_warning_min|
|Speed difference between Permitted speed and<br>Warning supervision limits, maximum value|5 km/h|dV_warning_max|
|Value of MRSP where dV_warning starts to increase to<br>dV_warning_max|110 km/h|V_warning_min|
|Value of MRSP where dV_warning stops to increase to<br>dV_warning_max|140 km/h|V_warning_max|

<!-- end of page 217 -->

|Time before the first Indication to display the TTI|14 s|T_dispTTI|
|---|---|---|
|Time between Warning supervision limit and SBI|2 s|T_warning|
|Driver reaction time between Permitted speed<br>supervision limit and SBI|4 s|T_driver|
|Maximum possible rotating mass as a percentage of<br>the total weight of the train|15 %|M_rotating_max|
|Minimum possible rotating mass as a percentage of the<br>total weight of the train|2 %|M_rotating_min|
|MA request repetition cycle, default value|60 s|TCYCRQSTD|
|Level/Mode transitions:|5 s|TACK|
|Driver acknowledgement time|||
|Maximum time to maintain a communication session in<br>case of failed re-connection attempts|5 minutes||
|Distance of metal immunity in Levels 0/NTC|300 metres||
|Distance of metal immunity set by procedure in level 1<br>or 2|300 metres||
|Driver reaction time before sounding the horn|4 s||
|Time between minimum safe rear end of the train<br>leaving a track condition area and on-board deleting the<br>applicable indication|5 s||
|Distance to keep on-board information in rear of the min<br>safe rear end of the train|300 metres||
|Additional delay time to disconnection on supervision of<br>safe radio connection|60 s||
|“Connection status” timer for safe radio connection<br>indication|45 s||
|Time from the latest Radio Network registration order<br>to a Mobile Terminal after which the registration is<br>considered as failed.|40 s||
|Time from when the FRMCS on-board equipment has<br>been detected to be connected to the ETCS on-board<br>equipment after which the registration is considered as<br>failed.|40 s||
|Waiting time for system version message|15 s||
|Waiting<br>time<br>for<br>acknowledgement<br>of<br>session<br>establishment|15 s||
|Monitoring of odometer accuracy: Total distance of<br>accumulated movements|5000 m||
|Monitoring of odometer accuracy: Maximum distance<br>interval|100 m||

<!-- end of page 218 -->

|Monitoring of odometer accuracy: Impairment threshold|250 m (derived from<br>5% of 5000m)|
|---|---|
|Monitoring of odometer accuracy: Safety threshold|1500<br>m<br>(derived|
||from 30% of 5000m)|

## **A.3.2 List of National / Default Data**

|**National / Default Data**|**Default Value**|**SRS Name**<br>**(Reference only)**|
|---|---|---|
|Modification of adhesion factor by driver|Not allowed|Q_NVDRIVER_ADHES|
|Shunting mode speed limit|30km/h|V_NVSHUNT|
|Staff Responsible mode speed limit|40km/h|V_NVSTFF|
|On Sight mode speed limit|30km/h|V_NVONSIGHT|
|Limited Supervision mode speed limit|100 km/h|V_NVLIMSUPERV|
|Unfitted mode speed limit|100km/h|V_NVUNFIT|
|Release Speed|40km/h|V_NVREL|
|Distance to be used in Roll Away Protection,<br>Unauthorised Direction Movement Protection and<br>Standstill supervision|2m|D_NVROLL|
|Permission to use service brake in target speed<br>monitoring|Yes|Q_NVSBTSMPERM|
|Qualifier to release emergency brake|Only at standstill|Q_NVEMRRLS|
|Permission to use guidance curves|No|Q_NVGUIPERM|
|Permission to use the service brake feedback|No|Q_NVSBFBPERM|
|Permission to inhibit the compensation of the speed<br>measurement inaccuracy|No|Q_NVINHSMICPERM|
|Speed limit for triggering the override function|0km/h|V_NVALLOWOVTRP|
|Override speed limit to be supervised when the<br>“override” function is active|30 km/h|V_NVSUPOVTRP|
|Distance for train trip suppression when override<br>function is triggered|200m|D_NVOVTRP|
|Max. time for train trip suppression when override<br>function is triggered|60 s|T_NVOVTRP|
|Change of driver ID permitted while running|Yes|M_NVDERUN|
|System reaction if T_NVCONTACT elapses|No reaction|M_NVCONTACT|
|Maximum time since the time-stamp of the last received<br>message||T_NVCONTACT|

<!-- end of page 219 -->

|Distance to be allowed for reversing in Post Trip mode.|200 m|D_NVPOTRP|
|---|---|---|
|Max permitted distance to run in Staff Responsible<br>mode||D_NVSTFF|
|Default location accuracy of a balise group|12 m|Q_NVLOCACC|
|Weighting factor for available wheel/rail adhesion|0|M_NVAVADH|
|Confidence<br>level<br>for<br>emergency<br>brake<br>safe<br>deceleration on dry rails|99.9999999 %|M_NVEBCL|
|Train length step used for the integrated correction<br>factor Kr_int|N/A|L_NVKRINT|
|Train length dependent integrated correction factor<br>Kr_int|0.9|M_NVKRINT*|
|Speed step used for the integrated correction factor<br>Kv_int|N/A|V_NVKVINT|
|Speed dependent integrated correction factor Kv_int|0.7|M_NVKVINT*|
|Integrated correction factor for brake build up time|1.1|M_NVKTINT|
|Maximum deceleration value under reduced adhesion<br>conditions (1)|1.0 m/s<sup>2</sup>|A_NVMAXREDADH1|
|Maximum deceleration value under reduced adhesion<br>conditions (2)|0.7 m/s<sup>2</sup>|A_NVMAXREDADH2|
|Maximum deceleration value under reduced adhesion<br>conditions (3)|0.7 m/s<sup>2</sup>|A_NVMAXREDADH3|
|Lower deceleration limit to determine the set of Kv_int<br>to be used|N/A|A_NVP12|
|Upper deceleration limit to determine the set of Kv_int<br>to be used|N/A|A_NVP23|

*The default value of the correction factor Kr_int shall be valid for any train length, and likewise the default value of the correction factor Kv_int shall be valid for any brake position, speed and maximum emergency brake deceleration. This means that the Kr_int model does not contain any train length step, and that the Kv_int model is valid for all train types and does neither contain any speed step nor any pivot deceleration limit.

## **A.3.3 Handling of information received from trackside**

A.3.3.1 Before it can be accepted and used by the ERTMS/ETCS on-board equipment, raw information received from trackside is subject to various checks, which can lead to the individual rejection/ignoring of information (e.g. Movement Authority not valid for the train orientation), the ignoring of a whole balise telegram or the rejection of a whole message. The SRS clauses/sections corresponding to these checks are gathered in Table 17.

<!-- end of page 220 -->

|||**Type**|**of data**|
|---|---|---|---|
|**Type of check**|**Individual**<br>**information**|**Telegram**|**Message**|
|System Version|3.17.3.11 a) & c)|3.17.3.5 a), d) & e)|3.17.3.5 b)<br>3.17.3.6 a)<br>3.17.3.6 c)<br>3.17.3.11 b)|
|Virtual Balise Cover||3.15.9.3 a)||
|Unauthorised<br>Direction Movement<br>Protection||3.14.3.6||
|Duplicated balises|3.16.2.4.8.1<br>3.16.2.4.8.2 together<br>with 3.16.2.4.8.2.1|||
|Linking|||3.4.4.4.2<br>3.4.4.4.2.1<br>3.4.4.4.2.2<br>3.4.4.4.3.2 together with 3.4.4.4.3 and<br>3.4.4.4.6<br>3.4.4.4.7|
|Message consistency|||3.16.1.4 together with 3.16.1.1 and<br>3.16.1.1.1<br>3.16.1.4 together with 3.16.2.4.1,<br>3.16.2.4.7, 3.16.2.4.7.1 and with exception<br>3.16.2.4.2<br>3.16.1.4 together with 3.16.2.4.4,<br>3.16.2.4.7, 3.16.2.4.7.1 and with exception<br>3.16.2.4.4.1 a)<br>3.16.1.4 together with 3.16.2.5.1,<br>3.16.2.4.7, 3.16.2.4.7.1 and with exception<br>3.16.2.5.1.1 a)<br>3.16.1.4 together with 3.16.3.1.1 a),<br>3.16.3.3.3 and 3.16.3.1.1 c)|
|EOLM vs loop<br>identity|||3.4.5.2.1|
|Validity direction|3.6.3.1.3 with<br>exceptions 3.6.3.1.3.1<br>and 3.6.3.1.3.2<br>3.6.3.1.4 with<br>exception 3.6.3.1.4.1|||

<!-- end of page 221 -->

|||**Type of data**|
|---|---|---|
|**Type of check**|**Individual**<br>**information**|**Telegram**<br>**Message**|
|Level, mode, origin of|4.8||
|information, infill/non-|||
|infill, other|||
|miscellaneous criteria|||

#### **Table 17: Check of raw data received from trackside**

A.3.3.2 With the exception of the clauses/sections referred to in Table 17 and of the clauses 3.16.3.5.1, 3.17.2.3 , 3.17.2.5, 3.17.2.6 and 3.17.3.3, all the clauses in this specification and in the SUBSET-035, in which trackside information is referred to (through the terms “balise”, “telegram”, “balise group [message]”, “message”, “[name of] information”...), shall be applied assuming that the information has not been ignored/rejected by the ERTMS/ETCS on-board equipment due to all the checks listed in Table 17.

A.3.3.3 Example 1: clause 3.16.2.4.9 has to be understood as follows: “If a <consistent> message <composed with telegrams that have passed the system version check, that have not been ignored because of a VBC, that have not been ignored because of duplication, and that have been received while no movement opposite to the authorised direction was performed> has been received <with one of its telegrams composing it> containing the information “default balise information” <which is valid for the train orientation (or the balise group crossing direction for NL or SL engines) and which has passed the level and mode filters>, the driver shall be informed.”

A.3.3.4 Example 2: as a result of the clause A.3.3.2, the ERTMS/ETCS on-board equipment will not apply requirements in relation to the content of the telegram or the message such as:

   - clause 3.6.2.2.2 a), in case the balise group message is rejected because inconsistent (e.g. according to 3.16.2.4.1), it does not become LRBG

   - clause 3.17.2.3, in case the balise telegram is ignored because of its system version number (e.g. according to 3.17.3.5 d)), this latter will not affect the system version operated by the on-board

   - clause 3.18.2.5 2<sup>nd</sup> bullet, in case a message from a balise group marked as linked is rejected because the balise group was not announced by linking (see 3.16.2.4.3), the balise group country or region identifier will not be compared with the one(s) of the currently applicable set of National Values

A.3.3.5 Example 3: as a result of the clause A.3.3.2, the clause 3.4.1.1 (definition of a balise group) has to be understood as follows: “A balise group consists of between one and eight balises sharing the same balise group identity <and which are not covered by a VBC (i.e. whose telegrams will not be ignored by the on-board) at a certain moment in time>”. Therefore when, for migration purposes, more than one instance of balises with the same internal number but with different VBC markers are used in a cluster of balises, the number of balises inside the group that is indicated in each balise telegram should

<!-- end of page 222 -->

not take into account the balises which are covered by a VBC at a certain moment in time.

## **A.3.4 Handling of Accepted and Stored Information in specific Situations**

### **A.3.4.1 Introduction**

A.3.4.1.1 All data that can be stored onboard after being accepted may be influenced in special situations.

A.3.4.1.2 The situations acting on the “status” of stored information are:

   - a) the acceptance of a conditional emergency stop (3.10.2.2 b));

   - b) the reception of a shortened MA (3.8.5.1.3, 3.8.5.1.4);

   - c) the stored MA is shortened due to a section time-out (3.8.4.2.2);

   - d) the SvL is shifted (to the DP if any or to the EOA) due to an overlap time-out (3.8.4.4.2) ;

   - e) the stored MA is shortened due to an end section time-out (3.8.4.1.2);

   - f) a request to shorten MA is granted by the onboard (3.8.6.2);

   - g) inconsistency in a balise group marked as unlinked and the train is at standstill (3.16.2.5.2);

   - h) a linking reaction led to a service brake and the train is at standstill (3.16.2.6.2) ;

   - i) the reaction due to the supervision of the safe radio connection led to a service brake and the train is at standstill (3.16.3.4.5 b) ;

   - j) the train category, axle load category, loading gauge or traction system is changed and the train is at standstill (3.18.3.7) ;

   - k) driver closes the desk during SoM ;

   - l) RAMS related supervision functions led to a service brake and the train is at standstill (3.16.2.7)

   - m) inconsistency in a balise group marked as linked and linking consistency is not checked onboard and the train is at standstill (3.16.2.4.4.2)

   - n) the Limit of Authority becomes an End of Authority and the on-board considers an SvL (3.8.4.3.2)

   - o) the safe consist length information acquired from external source becomes unavailable (4.4.21.1.12)

A.3.4.1.3 Depending on the situation, the action shall be one of the following:

   - a) data is deleted,

<!-- end of page 223 -->

- b) data is reset (set to initial states)

- c) data status is unchanged,

d) data is to be revalidated

#### _D = Deleted U = Unchanged R = Reset TBR = To Be Revalidated_

|||**Situations listed above**||
|---|---|---|---|
|**Data Stored on-board**|**a – d, f, n**|**e, g – j, l, m, o**|**k**|
|National Values|U|U|U|
|Not yet applicable National<br>Values|D[1]|D[10]|D|
|Linking|D[1]|D[10]|D|
|Movement Authority|D[1] [3]|D[10] [11]|D[5]|
|Gradient Profile|D[1]|D[10]|D|
|International SSP|D[1]|D[10]|D|
|Axle load speed profile|D[1]|D[10]|D|
|STM max speed|U|U|D|
|STM system speed/distance|U|U|D|
|Level Transition Order|U|U|D|
|Stop Shunting on desk opening|U|U|U|
|List of balise groups for SH area|D|D[9]|D[5]|
|MA Request Parameters|U|U|U|
|Position Report parameters|U|U|U|
|List of Balise groups in SR<br>Authority + SR mode speed limit<br>and distance|U[2]|U|D[5]|
|Temporary Speed Restrictions|U|U|D|
|Inhibition of revocable TSRs from<br>balises in level 2|U|U|D|
|Default Gradient for TSR|U[4]|U[4]|D|
|Signalling related Speed<br>Restriction|D[1]|D[10]|D[5]|
|Route Suitability Data|D[1]|D[10]|D|
|Plain Text Information (location<br>based)|D[8]|D[13]|D|
|Plain Text Information (not<br>location based)|U|U|D|

<!-- end of page 224 -->

|||**Situations listed above**||
|---|---|---|---|
|**Data Stored on-board**|**a – d, f, n**|**e, g – j, l, m, o**|**k**|
|Fixed Text Information (location<br>based)|D[8]|D[13]|D|
|Fixed Text Information (not<br>location based)|U|U|D|
|Geographical Position|U|U|U|
|Mode Profile|D[1] [7] [14]|D[10] [12]|D[5]|
|RBC Transition Order|D[1]|D[10]|D|
|Radio Infill Area information|D[1]|D[10]|D|
|EOLM information|U|U|U|
|Track Conditions excluding big<br>metal masses|R[1]|R[10]|R|
|Track condition big metal masses|R[1]|R[10]|R|
|Unconditional Emergency Stop|U|U|D|
|Conditional Emergency Stop|U|U|D|
|Train Position|U|U|U|
|Accumulated underestimation /<br>overestimation in measuring the<br>movements over a defined total<br>distance|U|U|U|
|Train Data|U|U|TBR|
|Adhesion factor|U|U|D|
|ERTMS/ETCS level|U|U|U|
|Table of priority of trackside<br>supported levels|U|U|U|
|Not yet applicable table of priority<br>of trackside supported levels|U|U|D|
|Driver ID|U|U|TBR|
|Radio Network information<br>(Radio Network type and GSM-R<br>Radio Network ID, if any)|U|U|U|
|Radio system used for safe radio<br>connection|U|U|U|
|RBC contact information|U|U|U|
|Mission performed with only one<br>radio system|U|U|D|
|Train Running Number|U|U|TBR|
|Reversing Area Information|D[1]|D[10]|D|

<!-- end of page 225 -->

|||**Situations listed above**|
|---|---|---|
|**Data Stored on-board**|**a – d, f, n**|**e, g – j, l, m, o**<br>**k**|
|Reversing Supervision<br>Information|U|U<br>D|
|Track Ahead Free Request|U[6]|U<br>D|
|Level Crossing information|U|U<br>D|
|Permitted Braking Distance<br>Information|D[1]|D[10]<br>D|
|RBC/RIU System Version|U|U<br>U|
|Operated System Version|U|U<br>U|
|Language used to display<br>information to the driver|U|U<br>U|
|Virtual Balise Covers|U|U<br>U|
|Generic LS function marker|U|U<br>U|
|LSSMA display toggle on order|U|U<br>D|

[1]: beyond the new SvL or in case of situation a, beyond the stop location of the accepted CES

[2]: The considered situations cannot occur when a list of balise groups to be used in SR is available onboard. Indeed, the onboard is in SR mode and since no MA or track description are stored onboard, no new SvL may be defined.

[3]: In case of reception of a new non-infill MA (situation b or f), the stored MA is fully replaced with the new one. In case of reception of a new infill MA (situation b), the stored MA is replaced beyond the infill location reference, i.e. the balise group at the next main signal

[4]: The considered situations a-d, f, h, i cannot occur when the default gradient for a TSR is used on-board.

[5]: The considered situation cannot occur because acceptance of this information has led to exit from SoM procedure.

[6]: The considered situations b-d, f cannot occur when a TAF request is stored on-board

[7]: If the start location of the Mode Profile is beyond the new SvL, the acknowledgement window of the Mode Profile shall be deleted as well

[8]: only if the location where to start to display the text is beyond the new SvL; otherwise all the text information

(i.e. including end location where to stop display, if any) shall remain unchanged

[9]: unchanged if the onboard is in SH mode

[10]: beyond the current max safe front end position of the train

[11]: the ERTMS/ETCS on-board equipment shall consider the current estimated front end and max safe front end positions of the train, as the EOA and SvL respectively, with no release speed

[12]: If the start location of the Mode Profile is beyond the current max safe front end, the acknowledgement window of the Mode Profile shall be deleted as well

[13]: only if the location where to start to display the text is beyond the current max safe front end; otherwise all the text information (i.e. including end location where to stop display, if any) shall remain unchanged

[14]: In case of reception of a new non-infill MA with or without Mode Profile (situation b or f), the stored Mode Profile is deleted. In case of reception of a new infill MA (situation b), the stored Mode Profile is deleted only beyond the infill location reference, i.e. the balise group at the next main signal

<!-- end of page 226 -->

A.3.4.1.4 NOTES:

A.3.4.1.4.1 Intentionally deleted.

A.3.4.1.4.2 The following information is not considered to be stored information:

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

   - k) Balise/loop system version

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

<!-- end of page 227 -->

- bb) SM Authorisation

- cc) SM Refused

dd) Acknowledgement of safe consist length for SM

## **A.3.5 Handling of Actions in Specific Situations**

A.3.5.1 Regards the following actions executed in reference to location based information received from trackside, the on-board equipment shall, by exception to the other requirements in this document, ensure that the action related to passing a location is neither reverted, nor executed twice in case of reverse movement (initiated by driver or due to roll-away) and sub-sequent forward movement, or in case of adjustment of train position and relocation on passing a  balise group that becomes SOLR, which result in a new train position situated in rear of the location which triggered the action:

   - Applying new National Values (see 3.18.2.3)

   - Request to acknowledge new level on entering the acknowledgement area (see 5.10.4.1 a)), actions related to passing the level transition border (see 3.5.3.8 d), 3.6.5.1.4 f), 5.10.1.5, 5.10.3.3.3, 5.10.3.6.2, 5.10.3.7.5, 5.10.3.10.3)

   - Start and stop displaying plain or fixed text messages (see 3.12.3.4.3.1)

   - Mode transition due to passing the beginning (see 3.12.4.5 together with 4.6.3 [34], [40], [71], [72], [73], [74]) or the end (see 3.12.4.6 together with 4.6.3 [75], [76]) of a LS/OS mode profile

   - Actions related to radio infill areas (see 3.5.4.3 3<sup>rd</sup> bullet, 3.9.3.5, 3.9.3.10 a)&b), 3.9.3.15, 3.9.3.16)

   - Actions related to RBC/RBC handover (see 3.5.3.8 f), 3.6.5.1.4 e)&k), 3.11.5.14 2<sup>nd</sup> bullet, 3.15.1.3.1 b)&c), 3.15.1.3.2, 3.15.1.3.7, 3.15.1.3.8 a), 3.17.2.8 c)&e), 5.15.1.4)

   - Actions related to track condition information with the exception of big metal masses and non stopping areas (see 3.5.3.4 e), 3.5.3.8 g), 3.5.4.4, 3.16.3.4.1.3, 5.18.2.2,3,5&6, 5.18.3.2,3,4&5, 5.18.5.2&3, 5.18.6.2,3,4&5, 5.18.7.3,4&5, 5.18.8.3,4&5, 5.18.9.2&3, 5.18.10.2,5&6, 5.20.2.2,4&5, 5.20.3.2,4&5, 5.20.4.2,4&5, 5.20.5.3,5&6, 5.20.6.2&4, 5.20.7.2&5, 5.20.8.2,5&6)

   - Intentionally deleted

   - Start and stop Track Ahead free request to driver (see 3.15.5.2)

   - Intentionally deleted

   - Substitute the supervision of the LX start location as temporary EOA/SvL by the inclusion of the LX speed restriction in the MRSP (see 5.16.2.1, 5.16.3.2)

   - Start the MA end section timer/overlap timer (see 3.8.4.1.1, 3.8.4.4.1)

A.3.5.1.1 Note: the fact that an action is not referred to in the above list does not mean that the action is automatically reverted, but that the other requirements in this document strictly apply. For instance:

<!-- end of page 228 -->

   - In case the reverse movement or the relocation brings back the max safe antenna position in rear of the start location of the big metal mass area, the on-board will stop ignoring the alarms which may be triggered by big metal masses (i.e. the clauses 3.12.1.2.1.2 and 3.12.1.3 apply)

   - In case the reverse movement or the relocation brings back the min safe front end in rear of an unprotected LX end location, the on-board will take again into account the LX speed restriction (i.e. 3.13.10.2.8 applies) and display again the unprotected LX status (i.e. 5.16.1.5 applies)

   - The transition to TR mode on passing the EOA/LOA will never be reverted, even if the train moves backwards in rear of the EOA/LOA location. Reason: on purpose, no such transition back to FS/OS/LS is specified in sections 4.6.2 and 4.6.3.

   - The transition from CSM to TSM on passing the Indication supervision limit will not be reverted in case of relocation that brings back the train front end in rear of the Indication supervision limit. Reason: it has been specified in that way for obvious ergonomic reasons (see 3.13.10.6.1).

A.3.5.2 A maximum time Tn (see Subset-036 clause 4.2.9) after it has received a balise group message (i.e. a maximum time Tn after it has received the last balise telegram of the balise group), the ERTMS/ETCS on-board equipment shall not consider any action related to passing an EOA (only in level 1), an LOA, or a former EOA/LOA located in advance of the train position measured at the time of reception of this last telegram, until the content of the message has been taken into account.

A.3.5.2.1 Example 1: in level 1, the crossing of the EOA/LOA location with the min safe antenna, before a new extended MA (received when the min safe antenna was in rear of the EOA/LOA) has been processed, will not lead to train trip. In other terms the replacement of the EOA/LOA is considered by the on-board as happening before the min safe antenna crosses the EOA/LOA location (i.e. preventing that clause 3.13.10.2.7 applies).

A.3.5.2.2 Example 2: when the override function is active, the crossing of the former EOA/LOA location by the min safe antenna, before a “Stop if in SR” information (received when the min safe antenna was in rear of the former EOA/LOA) has been processed, will not lead to the end of the override procedure followed by a train trip due to “Stop if in SR”. In other terms, both the deletion of the former EOA/LOA and the end of override procedure (see 5.8.3.1.3 and 5.8.4.1 c)) are considered by the on-board as simultaneously happening before the min safe antenna crosses the former EOA/LOA location.

A.3.5.2.3 Example 3: in level 2, the crossing of the LOA location with the min safe front end before an immediate level transition order to level NTC or level 0 (received when the min safe front end was in rear of the LOA) has been processed, will not lead to train trip. In other terms the deletion of the MA (and therefore the deletion of the LOA) due to the level change is considered by the on-board as happening before the min safe front end crosses the LOA location (i.e. preventing that clause 3.13.10.2.6 a) applies).

<!-- end of page 229 -->

## **A.3.6 Deletion of accepted and stored information when used**

### **A.3.6.1 Standard case**

A.3.6.1.1 When the train moves in the direction of its train orientation, storage capacity occupied by trackside information no longer used, i.e., the related on-board functionality has been completed, shall be made available immediately.

A.3.6.1.1.1 Note: The requirement is needed to allow trackside to predict the storage capacity available on-board in order to comply with dimensioning rules regards information stored on-board given in Subset 040.

### **A.3.6.2 Exception**

A.3.6.2.1 Following information shall remain stored on-board for a distance defined by a fixed value in rear of the min safe rear end position of the train:

   - location dependent static speed restrictions , i.e., SSP, ASP, TSR, LX SR, PBD SR (see 3.11.2.2),

   - gradient information,

   - reduced adhesion information received from trackside,

   - Track condition “Big metal masses”,

   - MA Section entry points and their associated Section timer stop locations.

A.3.6.2.1.1 Note: The above information remains stored for the case of a reverse movement:

   - With the exception of the track condition “Big metal masses”,  the stored information allows the ERTMS/ETCS on-board equipment to calculate speed supervision limits after a reverse movement (roll-away, or initiated by the driver),

   - Track condition “Big metal masses” is needed also for a reverse movement itself to avoid any false alarms due to Big metal masses in the track,

   - The MA Section information is needed to apply the clause 3.8.4.2.4 in case of reverse movement in rear of an MA Section timer stop location.

A.3.6.2.1.2 Note: The distance to intervention of the Roll Away Protection or the Unauthorised Direction Movement Protection is determined by a National/Default value.  This is also true for a reverse movement in Post trip mode. However, following an intervention, the train will not stop immediately. In order to keep the on-board functionality simple, a fixed distance value was chosen to define an unambiguous location in rear of the train where the above information is no longer required and the related on-board storage capacity is made available again.

## **A.3.7 Calculation of the basic deceleration**

A.3.7.1 The brake percentage (λ) shall be converted into two different input parameters: λo = λ for calculation of emergency brake deceleration (A_brake_emergency(V))

<!-- end of page 230 -->

λo = MIN (λ, 135) for calculation of service brake deceleration (A_brake_service(V))

where λ is the brake percentage defined as part of Train Data.

A.3.7.2 The calculation of the basic deceleration (A_basic(V)) shall use a common algorithm that will be used twice, once for the service brake and once for the emergency brake.

A.3.7.3 The speed limit for the first step shall be calculated as V_lim = x * λo<sup>y</sup> . V_lim is the speed limit for the first step in km/h x = 16.85

   - y = 0.428

A.3.7.4 The first step of the basic deceleration shall be calculated as AD_0 = A * λo + B AD_0 is the basic deceleration in m/s<sup>2</sup> for 0 ≤ speed ≤ V_lim.

   - A = 0.0075

   - B = 0.076

A.3.7.5 The following steps of the basic deceleration shall be calculated by means of a set of polynomials of the third order with the following format:

   - AD_n = a3_n * λo<sup>3</sup> + a2_n * λo<sup>2</sup> + a1_n * λo + a0_n

and with the following values for n (all speed limits in km/h):

|n = 1|valid for V_lim < speed ≤ 100|if V_lim < 100|
|---|---|---|
||to be ignored|if V_lim ≥ 100|
|n = 2|valid for V_lim < speed ≤ 120|if 100 < V_lim < 120|
||valid for 100 < speed ≤ 120|if V_lim ≤ 100|
||to be ignored|if V_lim ≥ 120|
|n = 3|valid for V_lim < speed ≤ 150|if 120 < V_lim < 150|
||valid for 120 < speed ≤ 150|if V_lim ≤ 120|
||to be ignored|if V_lim ≥ 150|
|n = 4|valid for V_lim < speed ≤ 180|if 150 < V_lim < 180|
||valid for 150 < speed ≤ 180|if V_lim ≤ 150|
||to be ignored|if V_lim ≥ 180|
|n = 5|valid for V_lim < speed|if V_lim > 180|
||valid for 180 < speed|if V_lim ≤ 180|

#### A.3.7.6 The coefficients for the polynomials shall be defined as follows:

|am_n|||m =|||
|---|---|---|---|---|---|
|||3|2|1|0|
||1|-6.30E-07|6.10E-05|4.72E-03|0.0663|
||2|2.73E-07|-4.54E-06|5.14E-03|0.1300|
|n =|3|5.58E-08|-6.76E-06|5.81E-03|0.0479|
||4|3.00E-08|-3.85E-06|5.52E-03|0.0480|

<!-- end of page 231 -->

5 3.23E-09 1.66E-06 5.06E-03 0.0559

## **A.3.8 Calculation of the emergency brake reaction time and emergency brake equivalent time**

A.3.8.1 The basic brake build up time for the emergency brake with the brake position in passenger trains in P shall be calculated as:

T_brake_basic_eb = a + b * (L/100) + c * (L/100)<sup>2</sup>

where

L = MAX (400m; train length in m) a = 2.30 b = 0.00

c = 0.17

A.3.8.2 The basic brake build up time for the emergency brake with the brake position in freight trains in P shall be calculated as:

T_brake_basic_eb = a + b * (L/100) + c * (L/100)<sup>2</sup> where

L = MAX (400m; train length in m)

If train length ≤ 900m:

a = 2.30 b = 0.00 c = 0.17

If 900m < train length ≤ 1500m:

a = -0.40 b = 1.60

c = 0.03

A.3.8.3 The basic brake build up time for the emergency brake with the brake position in freight trains in G shall be calculated as:

T_brake_basic_eb = a + b * (L/100) + c * (L/100)<sup>2</sup> where

L = train length in m

If train length ≤ 900m:

a = 12.00 b = 0.00 c = 0.05

If 900m < train length ≤ 1500m: a = -0.40 b = 1.60

<!-- end of page 232 -->

c = 0.03

A.3.8.4 The equivalent brake build up time for the emergency brake shall be computed as follows: T_brake_emergency_cm0 = T_brake_basic_eb when V_target = 0 T_brake_emergency_cmt = kto * T_brake_basic_eb when V_target > 0 where

V_target is the target speed

A.3.8.5 The correction factor kto shall depend on the brake position as follows: kto = 1 + Ct

where

Ct = 0.16 for freight trains in G Ct = 0.20 for freight trains in P Ct = 0.20 for passenger trains

A.3.8.6 The brake reaction times for the emergency brake shall be defined as follows:

|category|T_brake_emergency_react|
|---|---|
|brake position in passenger trains|1.42 s|
|brake position in freight trains in P|2.99 s|
|brake position in freight trains in G|9.30 s|

## **A.3.9 Calculation of the full service brake reaction time and full service brake equivalent time**

A.3.9.1 The basic brake build up time for full service brake for passenger trains in P shall be calculated as:

T_brake_basic_sb = a + b * (L/100) + c * (L/100)<sup>2</sup> where

L = train length in m

   - a = 3.00

   - b = 1.50

   - c = 0.10

A.3.9.2 The basic brake build up time for full service brake for freight trains in P shall be calculated as:

   - T_brake_basic_sb = a + b * (L/100) + c * (L/100)<sup>2</sup> where

L = train length in m

If train length ≤ 900m:

a = 3.00

<!-- end of page 233 -->

b = 2.77

c = 0.00

If 900m < train length ≤ 1500m:

a = 10.50 b = 0.32 c = 0.18

A.3.9.3 The basic brake build up time for full service brake for freight trains in G shall be calculated as:

T_brake_basic_sb = a + b * (L/100) + c * (L/100)<sup>2</sup>

where

L = MAX (400m; train length in m)

If train length ≤ 900m:

a = 3.00 b = 2.77

c = 0.00

If 900m < train length ≤ 1500m:

a = 10.50 b = 0.32 c = 0.18

A.3.9.4 The equivalent brake build up time for the service brake shall be computed as follows:

T_brake_service_cm0 = T_brake_basic_sb when V_target = 0

T_brake_service_cmt = kto * T_brake_basic_sb when V_target > 0

A.3.9.5 The correction factor kto shall be defined as in A.3.8.5

A.3.9.6 The values of a, b, c, kto and T_brake_service_react used in A.3.9.1, A.3.9.2, A.3.9.3, A.3.9.4 and A.3.9.8 define reference values for the equivalent brake build up time for the service brake, which shall be considered as maximum ones. If justified by the specific brake system of the train other values of these coefficients, which lead to shorter values of the equivalent brake build up time for the service brake, may be used.

A.3.9.7 Note: Although certain trains may perform better, the reference values for the equivalent brake build up time for the service brake, as defined here, are the appropriate basis for infrastructure planning.

A.3.9.8 The brake reaction times for the service brake shall be defined as follows:

|category|T_brake_service_react|
|---|---|
|brake position in passenger trains|1.06 s|
|brake position in freight trains in P|2.07 s|
|brake position in freight trains in G|5.70 s|

<!-- end of page 234 -->

## **A.3.10 Service brake feedback**

A.3.10.1 The purpose of service brake feedback is to reduce the distance between the SBI and EBI supervision limits and between the SBI and SBD curves.

A.3.10.2 The on-board shall consider the service brake feedback as available for use if: a) The service brake feedback is implemented, AND

   - b) The national value does not inhibit its use.

A.3.10.3 Two different types of feedback from the service brake are specified, main brake pipe pressure and brake cylinder pressure. The algorithms below are made for main brake pipe pressure. When brake cylinder pressure is used instead this shall be converted into a fictive main brake pressure value in the following way:

   - p = fictive main brake pipe pressure (kPa)

p_cylinder = brake cylinder pressure (kPa)

k1 = vehicle dependent constant (set by engineering of ETCS on-board; k1 is normally between 2.0 and 2.7)

   - p =  500  - p_cylinder / k1

A.3.10.4 The value of T_bs1 and T_bs2 shall be calculated according to the following algorithm to take the service brake feedback into account:

   - p = current main brake pipe pressure (or fictive main brake pipe pressure calculated in A.3.10.3)

p0 = reference pressure when not braking

p1 = pressure at which the train starts to brake = p0 - 30

p2 = pressure limit, under which T_bs1 and T_bs2 are locked = p0 - 60

- p3 = pressure at full service brake = p0 - 150

Q_feedback_active = a Boolean stating whether the feedback function is active, i.e. once it has started to reduce T_bs1 and T_bs2 until the ceiling speed monitoring is entered.

Q_Tbslocked = a boolean stating whether T_bs1 and T_bs2 have been locked to the following values due to enough main brake pipe pressure reduction:

T_bs1_locked =  0 s.

T_bs2_locked =  2 s.

Q_displaylocked_P = a boolean stating whether the displayed permitted speed is locked due to SB feedback.

Q_displaylocked_SBI = a boolean stating whether the displayed SBI speed (if any) is locked due to SB feedback.

Q_displaylocked_TD = a boolean stating whether the displayed target distance is locked due to SB feedback.

A displayed value is locked from the moment the SB feedback has started to reduce T_bs1 and T_bs2 until the calculated value becomes less than the displayed and

<!-- end of page 235 -->

locked value. Note: It is only SB feedback that can start the locking of the displayed values. Once started and still locked it remains locked also in case the calculated values are increased due to other reasons (e.g. due to relocation), which will prolong the locking period.

Initial values when the target speed monitoring is entered or when the release speed monitoring is entered not from target speed monitoring:

Tbs1_prev= Tbs Q_feedback_active = false Q_displaylocked_P = false Q_displaylocked_SBI = false Q_displaylocked_TD = false Q_Tbslocked =false

If on-board is in target speed monitoring or release speed monitoring then If Q_Tbslocked then T_bs1 = T_bs1_locked T_bs2 = T_bs2_locked Else

If p > p2 then If Q_feedback_active or p ≤ p1 then Q_feedback_active = true T_bs_feedback = T_bs * (p - p3) / (p0 - p3) T_bs1 = T_bs2 = T_bs_feedback If T_bs_feedback > T_bs then T_bs1 = T_bs2 = T_bs Else if T_bs_feedback < T_bs2_locked then T_bs2 = T_bs2_locked End If Else T_bs1 = T_bs T_bs2 = T_bs End If Else T_bs1 = T_bs1_locked T_bs2 = T_bs2_locked Q_feedback_active = true Q_Tbslocked = true

<!-- end of page 236 -->

End If End If Else T_bs1 = T_bs T_bs2 = T_bs End if If Q_feedback_active and T_bs1 < T_bs1_prev then Q_displaylocked_P = true Q_displaylocked_SBI = true Q_displaylocked_TD = true End If T_bs1_prev = T_bs1

If Q_displaylocked_P and the permitted speed computed for display purposes (VP-DMI) as per clause 3.13.10.4.3 is less than the locked and displayed permitted speed, then Q_displaylocked_P = false

End If

If Q_displaylocked_SBI and the SBI speed computed for display purposes (VSBI-DMI) as per clause 3.13.10.4.4 is less than the locked and displayed SBI speed, then Q_displaylocked_SBI = false End If

If Q_displaylocked_TD and the target distance computed for display purposes as per clause 3.13.10.4.7 is less than the locked and displayed target distance, then

Q_displaylocked_TD = false End If

If the MRDT changes then Q_displaylocked_P = false Q_displaylocked_SBI = false Q_displaylocked_TD = false

End If

<!-- end of page 237 -->

<!-- Start of picture text -->
T_bs1(p)<br>1<br>0,9<br>0,8<br>0,7<br>0,6<br>Tb<br>s 0,5<br>0,4<br>0,3<br>0,2<br>0,1<br>0<br>350 360 370 380 390 400 410 420 430 440 450 460 470 480 490 500<br>p [kPa]<br><!-- End of picture text -->

- The reference pressure p0 (nominal value 500 kPa) shall be set on starting the ETCS: a) To the first stable p value between 400-550 kPa achieved.

- b) Stable in this instance means that the pressure has not varied more than ± 20 kPa over 3 seconds.

The reference pressure p0 shall thereafter be adapted to the current pressure according to the following table (which applies if the calculation is performed once per second):

||**CONDITIONS:**|**ACTION:**|**REMARKS**|
|---|---|---|---|
|a)|p = p0|No change|Constant pressure|
|b)|p > p0|p0 = p0 + 1,5|Increasing pressure|
|c)|p < p0 - 30|No change|Braking|
|d)|p0 > p>p0 - 30|p0 = p0−0,5|Decreasing pressure|

Where:

- p is limited to max 550 kPa.

- Values given in kPa.

A.3.10.5 Note: If T_bs1 and T_bs2 have been locked to 0s and 2 s on approaching a non zero target, the locking will remain even if the train speed comes below the target speed. This avoids “jumping” indications related to the values of T_bs1 and T_bs2. It also makes it

<!-- end of page 238 -->

possible to release the brakes before a speed reduction, without having the curves moving back again. It might though result in emergency brake intervention if the driver releases the brakes too early. But since EBI is not moved, this is not a safety issue. To keep 2 s between the SBI and EBI enables the service brake to be activated first and thus may avoid emergency brake.

A.3.10.6 Note: If feedback is active but T_bs1 and T_bs2 are not locked, the feedback function will remain active until the ceiling speed monitoring is entered. This avoids “jumping” indications in some rare situations.

## **A.3.11 Data unit, range and resolution**

|Data|Unit|Range|Resolution|
|---|---|---|---|
|Train Data: Train length|m|0-4095|1 m|
|Train<br>Data:<br>Brake<br>percentage|%|10-250|1 %|
|Train Data: Maximum train<br>speed|km/h|0-600|5 km/h|
|Train Data: Loading gauge|n/a|G1, GA, GB, GC, does not fit any of the<br>interoperable<br>loading<br>gauge<br>profiles|n/a|
|Train<br>Data:<br>Axle<br>load<br>category|n/a|A, HS17, B1, B2, C2, C3, C4, D2, D3, D4,<br>D4XL, E4, E5|n/a|
|Train Data: Train fitted with<br>airtight system|n/a|Yes, No|n/a|
|Driver ID|n/a|1 to 16 alphanumeric characters<br>(selected from 0 to 9 and a to z)|n/a|
|RBC ID|n/a|0-16777214|1|
|RBC phone number|n/a|no restriction|n/a|
|Train running number|n/a|no restriction|n/a|
|Distance to run in SR mode|m|0-100000|1 m|
|Maximum SR speed|km/h|0-600|5 km/h|

<!-- end of page 239 -->

## **A.3.12 Calculation of reduced values of safe brake build up time and expected brake build up time**

### **A.3.12.1 Introduction**

A.3.12.1.1 Modelling the brake build up effort using a ramp function rather than a step function allows to predict that a certain deceleration development may be enough to safely reach a target with only a portion of the equivalent brake build up time elapsed.

A.3.12.1.2 This section defines how the safe brake build up time and expected brake build up times can be reduced to take profit of such effect.

A.3.12.1.3 This computation is done for each target according to the following seven steps:

   - a) Determination of the inputs for the computation;

   - b) Extrapolation of the train speed development over the brake reaction time, to check whether this extrapolated speed is above the target speed at this time;

   - c) Extrapolation of the train speed development over the full brake build up time along the ramp model;

   - d) Computation of the time at which the target speed is reached along the ramp model, for the targets whose speed is higher than this train speed extrapolated as per bullet c);

   - e) Computation of the corresponding travelled distances;

   - f) Conversion of these travelled distances into reduced values of safe and expected (equivalent) brake build up times that are to be used in the formulas to derive the EBI/SBI supervision limits;

   - g) Selection of the highest reduced values of safe and expected (equivalent) brake build up times amongst the ones ensuring equivalent speed reduction and the ones ensuring equivalent travelled distance.

A.3.12.1.4 Exception: in case the conversion model is used and 𝐾𝑡_𝑖𝑛𝑡 = 0 , the rest of section A.3.12 does not apply for 𝑇𝑏𝑒_𝑟𝑒𝑑𝑢𝑐𝑒𝑑 determination and 𝑇𝑏𝑒_𝑟𝑒𝑑𝑢𝑐𝑒𝑑 shall be set to 𝑇𝑏𝑒 .

A.3.12.1.5 Exception: if 𝑇𝑡𝑟𝑎𝑐𝑡𝑖𝑜𝑛 ≥𝑇𝑏𝑒 , the rest of section A.3.12 does not apply for 𝑇𝑏𝑒_𝑟𝑒𝑑𝑢𝑐𝑒𝑑 determination and 𝑇𝑏𝑒_𝑟𝑒𝑑𝑢𝑐𝑒𝑑 shall be set to 𝑇𝑏𝑒 .

### **A.3.12.2 Inputs for the computation (brake build up times reduction)**

A.3.12.2.1 The delays when full brake forces are reached, 𝑡2𝑏𝑒 and 𝑡2𝑏𝑠 , shall be computed as follows:

𝑡2𝑏𝑒 = 2 ∙𝑇𝑏𝑒 −𝑇𝑏𝑒_𝑟𝑒𝑎𝑐𝑡

With 𝑇𝑏𝑒_𝑟𝑒𝑎𝑐𝑡 and 𝑇𝑏𝑒 as defined in clause 3.13.6.2.2.3

- 𝑡2𝑏𝑠 = 2 ∙𝑇𝑏𝑠 −𝑇𝑏𝑠_𝑟𝑒𝑎𝑐𝑡

<!-- end of page 240 -->

With 𝑇𝑏𝑠_𝑟𝑒𝑎𝑐𝑡 and 𝑇𝑏𝑠 as defined in clause 3.13.6.3.2.4

A.3.12.2.2 For every target except EOA, 𝐴𝐸𝐵 shall be set to:

   - the minimum value of A_brake_safe(V,d) as defined in clause 3.13.6.2.1.4 if normal adhesion condition applies everywhere between the min safe front end train position and 𝑑𝑡𝑎𝑟𝑔𝑒𝑡 taking into account 3.13.5.3, or if the applicable A_MAXREDADH value does not limit its value;

   - MIN(the minimum value of A_brake_safe(V,d), A_MAXREDADH) otherwise

with the minimum value of A_brake_safe(V,d) applicable:

- at any location between the estimated train front position and 𝑑𝑡𝑎𝑟𝑔𝑒𝑡

- and at any speed value between 𝑉𝑏𝑒𝑐 and either null speed for SvL or 𝑉𝑡𝑎𝑟𝑔𝑒𝑡 for other EBD based targets

with 𝑉𝑏𝑒𝑐 as defined in clause 3.13.9.3.2.10 but substituting T_be_reduced with T_be as defined in 3.13.6.2.2.3.

A.3.12.2.3 For every target except EOA, 𝐴𝑠𝑎𝑓𝑒_𝑚𝑎𝑥 shall be set to the maximum value of A_safe(V,d) as defined in 3.13.6.2.1.3 and applicable:

   - at any location between the estimated train front position and 𝑑𝑡𝑎𝑟𝑔𝑒𝑡

   - and at any speed value between 𝑉𝑏𝑒𝑐 and either null speed for SvL or 𝑉𝑡𝑎𝑟𝑔𝑒𝑡 for other EBD based targets

with 𝑉𝑏𝑒𝑐 as defined in clause 3.13.9.3.2.10 but substituting T_be_reduced with T_be as defined in 3.13.6.2.2.3.

A.3.12.2.4 For every target, 𝐴𝑆𝐵 shall be set to the minimum value of A_brake_service(V,d) as defined in clause 3.13.6.3.1.4 applicable:

   - at any location between the estimated train front position and 𝑑𝑡𝑎𝑟𝑔𝑒𝑡

   - and at any speed value between 𝑉𝑒𝑠𝑡 and either null speed for EOA/SvL or 𝑉𝑡𝑎𝑟𝑔𝑒𝑡 otherwise

A.3.12.2.5 For every target, 𝐴𝑒𝑥𝑝𝑒𝑐𝑡𝑒𝑑_𝑚𝑎𝑥 shall be set to the maximum value of A_expected(V,d) as defined in clause 3.13.6.3.1.3 applicable:

   - at any location between the estimated train front position and 𝑑𝑡𝑎𝑟𝑔𝑒𝑡

   - and at any speed value between 𝑉𝑒𝑠𝑡 and either null speed for EOA/SvL or 𝑉𝑡𝑎𝑟𝑔𝑒𝑡 otherwise

A.3.12.2.6 If the service brake command is available for use, 𝑇𝑡𝑟𝑎𝑐𝑡𝑖𝑜𝑛_𝑚𝑖𝑛 shall be the value of 𝑇𝑡𝑟𝑎𝑐𝑡𝑖𝑜𝑛 as defined in clause 3.13.9.3.2.3 but substituting 𝑇𝑏𝑠2 with 𝑇𝑏𝑠 .

A.3.12.2.7 If the service brake command is available for use, 𝑇𝑡𝑟𝑎𝑐𝑡𝑖𝑜𝑛_𝑚𝑎𝑥 shall be the value of 𝑇𝑡𝑟𝑎𝑐𝑡𝑖𝑜𝑛 as defined in clause 3.13.9.3.2.3 but substituting 𝑇𝑏𝑠2 with 𝑇𝑏𝑠_𝑟𝑒𝑎𝑐𝑡

A.3.12.2.8 If the service brake command is not available for use, 𝑇𝑡𝑟𝑎𝑐𝑡𝑖𝑜𝑛_𝑚𝑖𝑛 and 𝑇𝑡𝑟𝑎𝑐𝑡𝑖𝑜𝑛_𝑚𝑎𝑥 shall be the value of 𝑇𝑡𝑟𝑎𝑐𝑡𝑖𝑜𝑛 as defined in clause 3.13.9.3.2.3 (i.e. with 𝑇𝑏𝑠2 = 0 ).

<!-- end of page 241 -->

### **A.3.12.3 Train speed after the brake reaction times (at the beginning of the ramp)**

A.3.12.3.1 For every target except EOA, the estimated train speed 𝑉𝑒𝑠𝑡 shall be extrapolated by the delay 𝑇𝑏𝑒_𝑟𝑒𝑎𝑐𝑡 as follows:

If 𝑇𝑡𝑟𝑎𝑐𝑡𝑖𝑜𝑛_𝑚𝑎𝑥 < 𝑇𝑏𝑒_𝑟𝑒𝑎𝑐𝑡 :

𝑉𝑡1𝑏𝑒 = 𝑉𝑒𝑠𝑡 + 𝑉𝑑𝑒𝑙𝑡𝑎0 + 𝐴𝑒𝑠𝑡1 ∙𝑇𝑡𝑟𝑎𝑐𝑡𝑖𝑜𝑛_𝑚𝑎𝑥 + 𝐴𝑒𝑠𝑡2 ∙(𝑇𝑏𝑒_𝑟𝑒𝑎𝑐𝑡 −𝑇𝑡𝑟𝑎𝑐𝑡𝑖𝑜𝑛_𝑚𝑎𝑥)

- If 𝑇𝑡𝑟𝑎𝑐𝑡𝑖𝑜𝑛_𝑚𝑎𝑥 ≥𝑇𝑏𝑒_𝑟𝑒𝑎𝑐𝑡 :

𝑉𝑡1𝑏𝑒 = 𝑉𝑒𝑠𝑡 + 𝑉𝑑𝑒𝑙𝑡𝑎0 + 𝐴𝑒𝑠𝑡1 ∙𝑇𝑏𝑒_𝑟𝑒𝑎𝑐𝑡

With 𝑉𝑑𝑒𝑙𝑡𝑎0 as defined in clause 3.13.9.3.2.1

With 𝐴𝑒𝑠𝑡1 as defined in clause 3.13.9.3.2.8

With 𝐴𝑒𝑠𝑡2 as defined in clause 3.13.9.3.2.9

With 𝑇𝑏𝑒_𝑟𝑒𝑎𝑐𝑡 as defined in clause 3.13.6.2.2.3

A.3.12.3.2 For every MRSP or LOA target, if 𝑉𝑡1𝑏𝑒 ≤𝑉𝑡𝑎𝑟𝑔𝑒𝑡 , the rest of section A.3.12 does not apply in 𝑇𝑏𝑒_𝑟𝑒𝑑𝑢𝑐𝑒𝑑 determination and 𝑇𝑏𝑒_𝑟𝑒𝑑𝑢𝑐𝑒𝑑 shall be set to 𝑇𝑏𝑒_𝑟𝑒𝑎𝑐𝑡 .

A.3.12.3.3 For SvL target or target at the end of the maximum permitted distance to run in SR, if 𝑉𝑡1𝑏𝑒 = 0 , the rest of section A.3.12 does not apply in 𝑇𝑏𝑒_𝑟𝑒𝑑𝑢𝑐𝑒𝑑 determination and 𝑇𝑏𝑒_𝑟𝑒𝑑𝑢𝑐𝑒𝑑 shall be set to 𝑇𝑏𝑒_𝑟𝑒𝑎𝑐𝑡 .

A.3.12.3.4 For every MRSP or LOA target, if 𝑉𝑒𝑠𝑡 ≤𝑉𝑡𝑎𝑟𝑔𝑒𝑡 , the rest of section A.3.12 does not apply in 𝑇𝑏𝑠_𝑟𝑒𝑑𝑢𝑐𝑒𝑑 determination and 𝑇𝑏𝑠_𝑟𝑒𝑑𝑢𝑐𝑒𝑑 shall be set to 𝑇𝑏𝑠_𝑟𝑒𝑎𝑐𝑡 .

A.3.12.3.5 For EOA target, SvL target or target at the end of the maximum permitted distance to run in SR, if 𝑉𝑒𝑠𝑡 = 0 , the rest of section A.3.12does not apply in 𝑇𝑏𝑠_𝑟𝑒𝑑𝑢𝑐𝑒𝑑 determination and 𝑇𝑏𝑠_𝑟𝑒𝑑𝑢𝑐𝑒𝑑 shall be set to 𝑇𝑏𝑠_𝑟𝑒𝑎𝑐𝑡 .

A.3.12.3.6 Note: For every target, the train speed is considered as remaining constant and equal to 𝑉𝑒𝑠𝑡 during the delay 𝑇𝑏𝑠_𝑟𝑒𝑎𝑐𝑡 .

### **A.3.12.4 Train speed after the full brake build up times (at the end of the ramp)**

A.3.12.4.1 For every target except EOA, the estimated train speed 𝑉𝑒𝑠𝑡 shall be extrapolated by the delay 𝑡2𝑏𝑒 as follows:

𝑉𝑡2𝑏𝑒 = MAX(0 , 𝑉𝑒𝑠𝑡 + 𝑉𝑑𝑒𝑙𝑡𝑎0 + 𝐴𝑒𝑠𝑡1 ∙𝑇𝑡𝑟𝑎𝑐𝑡𝑖𝑜𝑛_𝑚𝑎𝑥 + 𝐴𝑒𝑠𝑡2 ∙(𝑡2𝑏𝑒 −𝑇𝑡𝑟𝑎𝑐𝑡𝑖𝑜𝑛_𝑚𝑎𝑥) −<sup>𝐴𝐸𝐵∙(𝑡2𝑏𝑒−𝑇𝑏𝑒_𝑟𝑒𝑎𝑐𝑡)</sup> 2 )

With 𝑉𝑑𝑒𝑙𝑡𝑎0 as defined in clause 3.13.9.3.2.1

With 𝐴𝑒𝑠𝑡1 as defined in clause 3.13.9.3.2.8

With 𝐴𝑒𝑠𝑡2 as defined in clause 3.13.9.3.2.9

<!-- end of page 242 -->

With 𝑇𝑏𝑒_𝑟𝑒𝑎𝑐𝑡 as defined in clause 3.13.6.2.2.3

A.3.12.4.2 For every MRSP or LOA target for which 𝑉𝑡2𝑏𝑒 ≥𝑉𝑡𝑎𝑟𝑔𝑒𝑡 , the rest of section A.3.12 does not apply for 𝑇𝑏𝑒_𝑟𝑒𝑑𝑢𝑐𝑒𝑑 determination and 𝑇𝑏𝑒_𝑟𝑒𝑑𝑢𝑐𝑒𝑑 shall be set to 𝑇𝑏𝑒 .

A.3.12.4.3 For the SvL or the target at the end of the maximum permitted distance to run in SR, if 𝑉𝑡2𝑏𝑒 > 0 , the rest of section A.3.12 does not apply for 𝑇𝑏𝑒_𝑟𝑒𝑑𝑢𝑐𝑒𝑑 determination and 𝑇𝑏𝑒_𝑟𝑒𝑑𝑢𝑐𝑒𝑑 shall be set to 𝑇𝑏𝑒 .

A.3.12.4.4 For every target, the estimated train speed 𝑉𝑒𝑠𝑡 shall be extrapolated by the delay 𝑡2𝑏𝑠 as follows:

With 𝑇𝑏𝑠_𝑟𝑒𝑎𝑐𝑡 as defined in clause 3.13.6.3.2.4

A.3.12.4.5 For every MRSP or LOA target for which 𝑉𝑡2𝑏𝑠 ≥𝑉𝑡𝑎𝑟𝑔𝑒𝑡 , the rest of section A.3.12 does not apply for 𝑇𝑏𝑠_𝑟𝑒𝑑𝑢𝑐𝑒𝑑 determination and 𝑇𝑏𝑠_𝑟𝑒𝑑𝑢𝑐𝑒𝑑 shall be set to 𝑇𝑏𝑠 .

A.3.12.4.6 For the EOA, the SvL or the target at the end of the maximum permitted distance to run in SR, if 𝑉𝑡2𝑏𝑠 > 0 , the rest of section A.3.12 does not apply for 𝑇𝑏𝑠_𝑟𝑒𝑑𝑢𝑐𝑒𝑑 determination and 𝑇𝑏𝑠_𝑟𝑒𝑑𝑢𝑐𝑒𝑑 shall be set to 𝑇𝑏𝑠 .

### **A.3.12.5 Reduced brake build up times (as per the ramp model)**

A.3.12.5.1 For every target except EOA, the time 𝑡2𝑏𝑒_𝑒𝑛𝑜𝑢𝑔ℎ shall be computed as follows:

A.3.12.5.2 For every target, the time 𝑡2𝑏𝑠_𝑒𝑛𝑜𝑢𝑔ℎ shall be computed as follows:

<!-- end of page 243 -->

### **A.3.12.6 Travelled distances during reduced brake build up times (ramp model)**

A.3.12.6.1 The distance travelled to reach the speed of any target for which 𝑡2𝑏𝑒_𝑒𝑛𝑜𝑢𝑔ℎ has been computed shall be computed as follows:

A.3.12.6.2 The distance travelled to reach the speed of any target for which 𝑡2𝑏𝑠_𝑒𝑛𝑜𝑢𝑔ℎ has been computed shall be computed as follows:

### **A.3.12.7 Reduced values of safe brake build up time and expected brake build up time for distance equivalence**

A.3.12.7.1 The distance computed along the ramp model shall be converted into the time 𝑡𝑏𝑒_𝑒𝑛𝑜𝑢𝑔ℎ_𝑠𝑡𝑒𝑝_𝑑𝑖𝑠𝑡 at which it is reached along the step model, as follows:

   - if 𝐴𝑒𝑠𝑡1 = 𝐴𝑒𝑠𝑡2 = 0 :

- if 𝐴𝑒𝑠𝑡1 & 𝐴𝑒𝑠𝑡2 > 0:

𝑡𝑏𝑒_𝑒𝑛𝑜𝑢𝑔ℎ_𝑠𝑡𝑒𝑝_𝑑𝑖𝑠𝑡 = 𝑡𝑏𝑒_𝑋 + 𝑡𝑏𝑒_𝑌

𝑉𝑒𝑠𝑡+𝑉𝑑𝑒𝑙𝑡𝑎0+(𝐴𝑒𝑠𝑡1−𝐴𝑒𝑠𝑡2)∙𝑇𝑡𝑟𝑎𝑐𝑡𝑖𝑜𝑛_𝑚𝑖𝑛 With 𝑡𝑏𝑒_𝑋 = −𝐴𝑒𝑠𝑡2

And with

A.3.12.7.2 The distance computed along the ramp model shall be converted into the time 𝑡𝑏𝑠_𝑒𝑛𝑜𝑢𝑔ℎ_𝑠𝑡𝑒𝑝 at which it is reached along the step model, as follows:

   - if 𝑉𝑒𝑠𝑡 = 0 :

𝑡𝑏𝑠_𝑒𝑛𝑜𝑢𝑔ℎ_𝑠𝑡𝑒𝑝_𝑑𝑖𝑠𝑡 = 𝑇𝑏𝑠_𝑟𝑒𝑎𝑐𝑡

- if 𝑉𝑒𝑠𝑡 ≠0 :

<!-- end of page 244 -->

### **A.3.12.8 Final reduced values of safe brake build up time and expected brake build**

### **up time**

A.3.12.8.1 Finally, the reduced values of safe brake build up time and expected brake build up time shall be computed as follows:

With 𝑡𝑏𝑒_𝑒𝑛𝑜𝑢𝑔ℎ_𝑠𝑡𝑒𝑝 = 𝑀𝐴𝑋(𝑡𝑏𝑒_𝑒𝑛𝑜𝑢𝑔ℎ_𝑠𝑡𝑒𝑝_𝑑𝑒𝑙𝑡𝑎𝑉 , 𝑡𝑏𝑒_𝑒𝑛𝑜𝑢𝑔ℎ_𝑠𝑡𝑒𝑝_𝑑𝑖𝑠𝑡)

With 𝑡𝑏𝑠_𝑒𝑛𝑜𝑢𝑔ℎ_𝑠𝑡𝑒𝑝 = 𝑀𝐴𝑋(𝑡𝑏𝑠_𝑒𝑛𝑜𝑢𝑔ℎ_𝑠𝑡𝑒𝑝_𝑑𝑒𝑙𝑡𝑎𝑉 , 𝑡𝑏𝑠_𝑒𝑛𝑜𝑢𝑔ℎ_𝑠𝑡𝑒𝑝_𝑑𝑖𝑠𝑡)

𝑇𝑏𝑠_𝑟𝑒𝑎𝑐𝑡+𝑡2𝑏𝑠_𝑒𝑛𝑜𝑢𝑔ℎ and 𝑡𝑏𝑠_𝑒𝑛𝑜𝑢𝑔ℎ_𝑠𝑡𝑒𝑝_𝑑𝑒𝑙𝑡𝑎𝑉 = 2

A.3.12.8.2 Note: the limitation at 𝑇𝑏𝑒 and 𝑇𝑏𝑠 values is needed because of the safe-side approximations done on the brake models in the computation defined in the present section.

### **A.3.12.9 Informative annex: derivation of the formulas**

A.3.12.9.1 The purpose of this part is to explain how the formulas given in the rest of section A.3.12 have been obtained. The explanation is based on the emergency brake related formulas, A.3.12.7.17 explains how these can be modified to obtain service brake related formulas.

A.3.12.9.2 **About A.3.12.3&4:** For these calculations, it is assumed (refer to figure 45 and 3.13.9.3.2) that once the emergency brake command is triggered, the train speed (compensated for the speed measurement inaccuracy 𝑉𝑑𝑒𝑙𝑡𝑎0 ) increases with 𝐴𝑒𝑠𝑡1 acceleration up to 𝑇𝑡𝑟𝑎𝑐𝑡𝑖𝑜𝑛_𝑚𝑎𝑥 time and then with 𝐴𝑒𝑠𝑡2 acceleration. This speed increase is compensated by the 𝐴𝐸𝐵 deceleration coming from the brake force as per the ramp model from 𝑇𝑏𝑒_𝑟𝑒𝑎𝑐𝑡 to 𝑡2𝑏𝑒 (refer to Figure 31). The average deceleration coming from the brake force is half of its final (full) value.

<!-- end of page 245 -->

<!-- Start of picture text -->
Brake force (deceleration) development (EB)<br>Deceleration<br>AEB<br>Ttraction_max Tbe_react<br>0<br>t2be time<br>-Aest2 = -0.4 m/s 2<br>-Aest1<br><!-- End of picture text -->

**Figure 63: Example of the Brake Build Up Time Model**

A.3.12.9.3 From the description above and from Figure 63, it is clear that solving the following definite integrals gives the final formula used in A.3.12.3.1:

<!-- Start of picture text -->
𝑡2𝑏𝑒 𝑇𝑡𝑟𝑎𝑐𝑡𝑖𝑜𝑛_𝑚𝑎𝑥 𝑇𝑏𝑒_𝑟𝑒𝑎𝑐𝑡 𝑡2𝑏𝑒<br>= 𝑣0 + 𝑎1(𝑡)𝑑𝑡 + 𝑎2(𝑡)𝑑𝑡+ 𝑎3(𝑡)𝑑𝑡<br>𝑉𝑡2𝑏𝑒 = 𝑣0 + ∫𝑎(𝑡)𝑑𝑡 ∫ ∫ ∫<br>0 0 𝑇𝑡𝑟𝑎𝑐𝑡𝑖𝑜𝑛_𝑚𝑎𝑥 𝑇𝑏𝑒_𝑟𝑒𝑎𝑐𝑡<br>𝑇𝑡𝑟𝑎𝑐𝑡𝑖𝑜𝑛_𝑚𝑎𝑥 𝑇𝑏𝑒_𝑟𝑒𝑎𝑐𝑡<br>= 𝑣0 + 𝐴𝑒𝑠𝑡1𝑑𝑡 + 𝐴𝑒𝑠𝑡2𝑑𝑡<br>∫ ∫<br>0 𝑇𝑡𝑟𝑎𝑐𝑡𝑖𝑜𝑛_𝑚𝑎𝑥<br>𝑡2𝑏𝑒<br>−𝐴𝐸𝐵<br>+<br>∫<br>(𝑡2𝑏𝑒 −𝑇𝑏𝑒_𝑟𝑒𝑎𝑐𝑡)<br>𝑇𝑏𝑒_𝑟𝑒𝑎𝑐𝑡 (𝐴𝑒𝑠𝑡2 + ∙(𝑡−𝑇𝑏𝑒_𝑟𝑒𝑎𝑐𝑡)) 𝑑𝑡<br><!-- End of picture text -->

   - where 𝑣0 = 𝑉𝑒𝑠𝑡 + 𝑉𝑑𝑒𝑙𝑡𝑎0

A.3.12.9.4 **About A.3.12.5:** The speed computed at 𝑡2𝑏𝑒 in A.3.12.4 can be computed for any time 𝑡 between MAX( 𝑇𝑡𝑟𝑎𝑐𝑡𝑖𝑜𝑛_𝑚𝑎𝑥 , 𝑇𝑏𝑒_𝑟𝑒𝑎𝑐𝑡 ) and 𝑡2𝑏𝑒 by using the following substitution 𝑡2𝑏𝑒 = 𝑡 in A.3.12.9.3 formulas, which give the following final formula:

A.3.12.9.5 The above formula can be used to express an unknown time (𝑡−𝑇𝑏𝑒_𝑟𝑒𝑎𝑐𝑡) to get the final time 𝑡= 𝑡2𝑏𝑒_𝑒𝑛𝑜𝑢𝑔ℎ that corresponds to the wanted final speed (𝑉𝑡𝑎𝑟𝑔𝑒𝑡 + 𝑑𝑉𝑒𝑏𝑖(𝑉𝑡𝑎𝑟𝑔𝑒𝑡)) . Doing so, this quadratic form from which (𝑡−𝑇𝑏𝑒_𝑟𝑒𝑎𝑐𝑡) or 𝑡= 𝑡2𝑏𝑒_𝑒𝑛𝑜𝑢𝑔ℎ finally, can be obtained by solving:

<!-- end of page 246 -->

With ∆𝑉𝑒𝑏_𝑡 = MAX(0 , 𝑉𝑒𝑠𝑡 + 𝑉𝑑𝑒𝑙𝑡𝑎0 −𝑉𝑡𝑎𝑟𝑔𝑒𝑡)

A.3.12.9.5.1 Note: For solving the above quadratic equation, only the root with positive sign in front of the square root is used, in order to obtain 𝑡2𝑏𝑒_𝑒𝑛𝑜𝑢𝑔ℎ ≥𝑇𝑏𝑒_𝑟𝑒𝑎𝑐𝑡

A.3.12.9.6 **About A.3.12.6:** The distance travelled along the ramp model at any time 𝑡 between MAX( 𝑇𝑡𝑟𝑎𝑐𝑡𝑖𝑜𝑛_𝑚𝑎𝑥 , 𝑇𝑏𝑒_𝑟𝑒𝑎𝑐𝑡 ) and 𝑡2𝑏𝑒 can then be written as (with the assumption that 𝑇𝑏𝑒_𝑟𝑒𝑎𝑐𝑡 ≥𝑇𝑡𝑟𝑎𝑐𝑡𝑖𝑜𝑛_𝑚𝑎𝑥 , but the result is the same otherwise (i.e. for the case 𝑇𝑏𝑒_𝑟𝑒𝑎𝑐𝑡 < 𝑇𝑡𝑟𝑎𝑐𝑡𝑖𝑜𝑛_𝑚𝑎𝑥 )):

𝑑𝑟𝑎𝑚𝑝(𝑡) = (𝑑𝑖𝑠𝑡𝑎𝑛𝑐𝑒 𝑓𝑟𝑜𝑚 𝑖𝑛𝑡𝑒𝑟𝑣𝑒𝑛𝑡𝑖𝑜𝑛 𝑡𝑜 𝑡𝑟𝑎𝑐𝑡𝑖𝑜𝑛 𝑐𝑢𝑡-𝑜𝑓𝑓(𝑇𝑡𝑟𝑎𝑐𝑡𝑖𝑜𝑛_𝑚𝑎𝑥))

+ (𝑑𝑖𝑠𝑡𝑎𝑛𝑐𝑒 𝑏𝑒𝑡𝑤𝑒𝑒𝑛 𝑡𝑟𝑎𝑐𝑡𝑖𝑜𝑛 𝑐𝑢𝑡-𝑜𝑓𝑓(𝑇𝑡𝑟𝑎𝑐𝑡𝑖𝑜𝑛_𝑚𝑎𝑥) 𝑎𝑛𝑑 𝑠𝑡𝑎𝑟𝑡 𝑜𝑓 𝑏𝑟𝑎𝑘𝑒 𝑒𝑓𝑓𝑜𝑟𝑡 𝑟𝑎𝑚𝑝(𝑇𝑏𝑒_𝑟𝑒𝑎𝑐𝑡))

- +(𝑣𝑎𝑟𝑖𝑎𝑏𝑙𝑒 𝑑𝑖𝑠𝑡𝑎𝑛𝑐𝑒 𝑜𝑣𝑒𝑟 𝑡ℎ𝑒 𝑏𝑟𝑎𝑘𝑒 𝑒𝑓𝑓𝑜𝑟𝑡 𝑟𝑎𝑚𝑝 (𝑡))

<!-- Start of picture text -->
𝑡<br>= ∫𝑣(𝑡)𝑑𝑡<br>0<br>𝑇𝑡𝑟𝑎𝑐𝑡𝑖𝑜𝑛_𝑚𝑎𝑥 𝑇𝑏𝑒_𝑟𝑒𝑎𝑐𝑡 𝑡 𝑇𝑡𝑟𝑎𝑐𝑡𝑖𝑜𝑛_𝑚𝑎𝑥<br>= 𝑣1(𝑡)𝑑𝑡 + 𝑣2(𝑡)𝑑𝑡+ 𝑣3(𝑡)𝑑𝑡= (𝑣0 + 𝐴𝑒𝑠𝑡1 ∙𝑡)𝑑𝑡<br>∫ ∫ ∫ ∫<br>0 𝑇𝑡𝑟𝑎𝑐𝑡𝑖𝑜𝑛_𝑚𝑎𝑥 𝑇𝑏𝑒_𝑟𝑒𝑎𝑐𝑡 0<br>𝑇𝑏𝑒_𝑟𝑒𝑎𝑐𝑡<br>+<br>∫ (𝑣0 + 𝐴𝑒𝑠𝑡1 ∙𝑇𝑡𝑟𝑎𝑐𝑡𝑖𝑜𝑛_𝑚𝑎𝑥 + 𝐴𝑒𝑠𝑡2 ∙(𝑡−𝑇𝑡𝑟𝑎𝑐𝑡𝑖𝑜𝑛_𝑚𝑎𝑥)) 𝑑𝑡<br>𝑇𝑡𝑟𝑎𝑐𝑡𝑖𝑜𝑛_𝑚𝑎𝑥<br>𝑡<br>+<br>∫<br>(𝑣0 + 𝐴𝑒𝑠𝑡1 ∙𝑇𝑡𝑟𝑎𝑐𝑡𝑖𝑜𝑛_𝑚𝑎𝑥 + 𝐴𝑒𝑠𝑡2 ∙(𝑇𝑏𝑒_𝑟𝑒𝑎𝑐𝑡 −𝑇𝑡𝑟𝑎𝑐𝑡𝑖𝑜𝑛_𝑚𝑎𝑥) + 𝐴𝑒𝑠𝑡2 ∙(𝑡−𝑇𝑏𝑒_𝑟𝑒𝑎𝑐𝑡)<br>𝑇𝑏𝑒_𝑟𝑒𝑎𝑐𝑡<br>− 𝐴𝐸𝐵 ∙ (𝑡−𝑇𝑏𝑒_𝑟𝑒𝑎𝑐𝑡) 2<br>2 ∙𝑇𝑏𝑒_𝑖𝑛𝑐𝑟 ) 𝑑𝑡=<br><!-- End of picture text -->

<!-- end of page 247 -->

A.3.12.9.7 The value of 𝐷𝑡2𝑏𝑒_𝑒𝑛𝑜𝑢𝑔ℎ is the value of 𝑑_𝑟𝑎𝑚𝑝(𝑡2𝑏𝑒_𝑒𝑛𝑜𝑢𝑔ℎ) . It must be noticed that after having travelled this distance, the wanted final speed is reached, i.e. no distance is to be travelled over the EBD curve.

A.3.12.9.8 **About A.3.12.7:** Because the model that is used in section 3.13 is a step model, we need to find which (artificial) value of 𝑇𝑏𝑒 ( 𝑡𝑏𝑒_𝑒𝑛𝑜𝑢𝑔ℎ_𝑠𝑡𝑒𝑝_𝑑𝑖𝑠𝑡 , here called 𝑡𝑏𝑒_𝑒𝑛 ) would lead to obtaining the same travelled distance 𝐷𝑡2𝑏𝑒_𝑒𝑛𝑜𝑢𝑔ℎ . In contrast to the use of the ramp model, a section of the EBD curve is needed here, between this sought time 𝑡𝑏𝑒_𝑒𝑛 and the time the wanted final speed 𝑉𝑡𝑎𝑟𝑔𝑒𝑡 , here called 𝑉𝑇 ) is reached.

A.3.12.9.9 First, we need an expression of 𝑑_𝑠𝑡𝑒𝑝(𝑡𝑏𝑒_𝑒𝑛) :

<!-- end of page 248 -->

𝑑_𝑠𝑡𝑒𝑝(𝑡𝑏𝑒_𝑒𝑛)

= (𝑑𝑖𝑠𝑡𝑎𝑛𝑐𝑒 𝑓𝑟𝑜𝑚 𝑖𝑛𝑡𝑒𝑟𝑣𝑒𝑛𝑡𝑖𝑜𝑛 𝑡𝑜 𝑡𝑟𝑎𝑐𝑡𝑖𝑜𝑛 𝑐𝑢𝑡-𝑜𝑓𝑓(𝑇𝑡𝑟𝑎𝑐𝑡𝑖𝑜𝑛_𝑚𝑖𝑛))

+ (𝑣𝑎𝑟𝑖𝑎𝑏𝑙𝑒 𝑑𝑖𝑠𝑡𝑎𝑛𝑐𝑒 𝑏𝑒𝑡𝑤𝑒𝑒𝑛 𝑡𝑟𝑎𝑐𝑡𝑖𝑜𝑛 𝑐𝑢𝑡-𝑜𝑓𝑓(𝑇𝑡𝑟𝑎𝑐𝑡𝑖𝑜𝑛_𝑚𝑖𝑛) 𝑎𝑛𝑑 𝑏𝑟𝑎𝑘𝑒 𝑠𝑡𝑒𝑝 (𝑡𝑏𝑒_𝑒𝑛))

A.3.12.9.11 It can be re-written as:

A.3.12.9.12 Introducing 𝑉1 = 𝑉𝑒𝑠𝑡 + 𝑉𝑑𝑒𝑙𝑡𝑎0 + 𝐴𝑒𝑠𝑡1 ∙𝑇𝑡𝑟𝑎𝑐𝑡𝑖𝑜𝑛_𝑚𝑖𝑛 :

<!-- end of page 249 -->

A.3.12.9.13 If 𝐴𝑒𝑠𝑡1 = 𝐴𝑒𝑠𝑡2 = 0 and 𝑉1 ≠0  , we then get:

A.3.12.9.14 If 𝐴𝑒𝑠𝑡1 & 𝐴𝑒𝑠𝑡2 > 0 , we then get:

𝑉1−𝐴𝑒𝑠𝑡2∙𝑇𝑡𝑟𝑎𝑐𝑡𝑖𝑜𝑛_𝑚𝑖𝑛 A.3.12.9.15 Introducing 𝑡𝑏𝑒_𝑋 = : −𝐴𝑒𝑠𝑡2

<!-- end of page 250 -->

𝑡𝑏𝑒_𝑒𝑛 = 𝑡𝑏𝑒_𝑋 ±

𝑉𝑒𝑠𝑡+𝑉𝑑𝑒𝑙𝑡𝑎0+(𝐴𝑒𝑠𝑡1−𝐴𝑒𝑠𝑡2)∙𝑇𝑡𝑟𝑎𝑐𝑡𝑖𝑜𝑛_𝑚𝑖𝑛 A.3.12.9.16 Since 𝑡𝑏𝑒_𝑋 = is always < 0, the valid solution of the −𝐴𝑒𝑠𝑡2 quadratic equation is derived from the positive sign in front of the square root.

A.3.12.9.17 **About A.3.12.8:** This value 𝑡𝑏𝑒_𝑒𝑛 , i.e. 𝑡𝑏𝑒_𝑒𝑛𝑜𝑢𝑔ℎ_𝑠𝑡𝑒𝑝_𝑑𝑖𝑠𝑡 , ensures that the distance travelled along the step model (supporting section 3.13 formulas) is equivalent to the one computed along the ramp model. However, it does not ensure that the speed reduction is equivalent along both models.

A.3.12.9.18 Therefore, an equivalent brake build up time 𝑡𝑏𝑒_𝑒𝑛𝑜𝑢𝑔ℎ_𝑠𝑡𝑒𝑝_𝑑𝑒𝑙𝑡𝑎𝑉 computed from 𝑡2𝑏𝑒_𝑒𝑛𝑜𝑢𝑔ℎ is used as a lower limit to the final 𝑇𝑏𝑒_𝑟𝑒𝑑𝑢𝑐𝑒𝑑 value. Its computation is similar to the one defined by clause 3.13.2.2.3.2.4:

A.3.12.9.19 **About service brake related formulas:** They can be obtained from the emergency brake ones by setting 𝑉𝑑𝑒𝑙𝑡𝑎0 , 𝑇𝑡𝑟𝑎𝑐𝑡𝑖𝑜𝑛_𝑚𝑖𝑛,  𝑇𝑡𝑟𝑎𝑐𝑡𝑖𝑜𝑛_𝑚𝑎𝑥 , 𝐴𝑒𝑠𝑡1 and 𝐴𝑒𝑠𝑡2 to zero and making the following substitutions: 𝑉𝑡2𝑏𝑒 = 𝑉𝑡2𝑏𝑠 ; 𝑇𝑏𝑒_𝑟𝑒𝑎𝑐𝑡 = 𝑇𝑏𝑠_𝑟𝑒𝑎𝑐𝑡 ; 𝑡2𝑏𝑒 = 𝑡2𝑏𝑠 ; 𝐴𝐸𝐵 = 𝐴𝑆𝐵 ; 𝐴𝑠𝑎𝑓𝑒_𝑚𝑎𝑥 = 𝐴𝑒𝑥𝑝𝑒𝑐𝑡𝑒𝑑_𝑚𝑎𝑥 ; 𝐷𝑡2𝑏𝑒_𝑒𝑛𝑜𝑢𝑔ℎ = 𝐷𝑡2𝑏𝑠_𝑒𝑛𝑜𝑢𝑔ℎ ; 𝑡2𝑏𝑒_𝑒𝑛𝑜𝑢𝑔ℎ = 𝑡2𝑏𝑠_𝑒𝑛𝑜𝑢𝑔ℎ.

## **A.3.13 Inhibition of increase of displayed permitted speed and SBI speed**

A.3.13.1 This appendix specifies under which conditions the displayed permitted speed and SBI speed are locked in order to avoid their increase which could be caused by active reduction of brake build up times (see Appendix A.3.12).

A.3.13.2 The boolean stating whether the displayed permitted speed and SBI speed are not allowed to increase (Q_display_pawl) shall be calculated according to the following algorithm:

If on-board is in target speed monitoring or release speed monitoring then

- If the MRDT changes then

Q_display_pawl = false

Else if T_be_reduced computed for any target is lower than T_be then Q_display_pawl = true

Else if the service brake command is available for use, the service brake feedback is not available for use, and T_bs_reduced computed for any target is lower than T_bs then

Q_display_pawl = true

Else

<!-- end of page 251 -->

Q_display_pawl = false

End if

Else Q_display_pawl = false

End if

<!-- end of page 252 -->
