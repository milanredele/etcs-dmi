# **ERTMS/ETCS**

**System Requirements Specification Chapter 8 Messages**

REF  :  SUBSET-026-8 ISSUE :

4.0.0 DATE : 05/07/2023

<!-- end of page 1 -->

# **8.1 Modification History**

|Issue Number<br>Date|Section Number|Modification / Description|Author|
|---|---|---|---|
|0.0.1<br>990715|All|Creation of the document<br>“Clean version” based on<br>SRS Class P Ch. 8|V. Roger|
|0.0.2<br>990716|All|Update to SRS Class 1|V. Roger|
|0.1.0<br>990727|All|Update considering review<br>comments from ADT and<br>ALS|V. Roger|
|1.0.0<br>990729|Version number and<br>editorial changes.|Finalisation<br>meeting,<br>Stuttgart 990729.|HE|
|1.2.0<br>990730|Version number|Release version|HE|
|1.2.1<br>991124|Sections 8.4 to 8.7|ECSAG<br>comments<br>(on<br>chapter<br>8)<br>taken<br>into<br>account.|V. Roger|
|1.2.2<br>991209|Sections 8.4 to 8.7.<br>Creation of appendix.|Upsate to SRS Class 1<br>version 2 – First release|V. Roger|
|1.3.0<br>991217|Sections 8.4 to 8.7.<br>Suppression<br>of<br>appendix.|Upsate to SRS Class 1<br>version 2 – Unisig Review<br>(991216)|V. Roger|
|1.3.1<br>991220|Section 8.7.14|Add  Q_SCALE|P. Rimbaud|
|2.0.0<br>991222|Minor editorial changes|Release version|Ch. Frerichs (ed.)|
|2.0.1<br>001002|All|Corrections after UNISIG<br>review 15 June 00|P. Rimbaud|
|2.1.0<br>001026|Sections 8.4.1, 8.4.2,<br>8.4.3,<br>8.4.4,<br>8.5.1,<br>8.5.2, 8.5.3, 8.6, 8.7|Corrections after UNISIG<br>review 10/11 October 00|P. Rimbaud|
|2.2.0|Packet<br>71<br>deleted,<br>NID_C 10 bit|UNISIG release|SAB|
|2.2.2|Packet<br>71<br>added,<br>messages 42 and 158<br>deleted|SUBSET-026<br>Corrected<br>Paragraphs, Issue 2.2.2|JY. Riou|
|2.2.4 – 040512||UNISIG Change Request<br>according the scope defined<br>in the 06/05/2004 e-mail|JY. RIOU|

<!-- end of page 2 -->

|Issue Number<br>Date|Section Number<br>Modification / Description|Author|
|---|---|---|
|2.2.4 SG checked<br>28/05/04|Including all CLRs agreed with EEIG (see “List of<br>CLRs agreed with EEIG for SRS v2.2.4” dated<br>28/05/04)<br>Affected clauses see change marks|H. Kast|
|2.2.5<br>21/01/05|Incorporation of solution proposal for CLR 007 with<br>EEIG users group comments|A. Hougardy|
|2.2.6<br>04/02/05|§ 8.4.2.1, § 8.4.3.1, § 8.7.12 according to CR242<br>§ 8.4.4.4.1.1, § 8.5.3, § 8.7.22 according to CR458<br>§ 8.6.3 according to CR 487|JY. RIOU|
|2.2.7<br>01/08/05|§ 8.7.22 error correction (Q_ORIENTATION)<br>according to CR458,<br>§ 8.4.4.4.2 according to CR 126<br>§8.4.4.4.3 b), § 8.6.17 according to CR 299<br>§ 8.4.1.4.5, § 8.4.4.4.1 according to CR 413<br>§ 8.4.1.4.6 according to CR 633|JY.RIOU|
|2.2.8<br>30/11/05|Change marks cleaned up and updated according to<br>last CR decisions (including split of CRs 7 and 126)|JY. RIOU|
|2.2.9<br>24/02/06|Including all CR s that are classified as “IN” per<br>Subset-108 version 1.0.0<br>Removal of all CRs that are not classified as “IN” as<br>per SUBSET-108 version 1.0.0 with the exception of<br>the CR 63, 98, 120, 158 and 538|JY. RIOU|
|2.3.0<br>24/02/06|Release version|HK|
|2.3.1<br>14/06/2006|§ 8.4.4.4.1 and § 8.7.5: “SRS v2.3.0 Release Note<br>CR 382” point,<br>§ 8.4.4.4.3 b) and 8.6.17: removing of premature<br>CR299 update|JY. RIOU|
|2.3.2<br>17/03/08|Including all CRs that are in state “Analysis completed”<br>according to ERA CCM|A. Hougardy|
|2.9.1<br>06/10/08|Including all enhancement CR’s retained for 3.0.0<br>baseline and all other error CR’s that are in state<br>“Analysis completed” according to ERA CCM<br>For editorial reasons, the following CR’s are also<br>included: CR656, CR804, CR821|A. Hougardy|
|3.0.0<br>23/12/08|Release version|A. Hougardy|

<!-- end of page 3 -->

|Issue Number<br>Date|Section Number<br>Modification / Description|Author|
|---|---|---|
|3.0.1<br>22/12/09|Including the results of the editorial review of the SRS<br>3.0.0 and the other error CR’s that are in state<br>“Analysis completed” according to ERA CCM|A. Hougardy|
|3.1.0<br>22/02/10|Release version|A. Hougardy|
|3.1.1<br>08/11/10|Including all CR’s that are in state “Analysis<br>completed” according to ERA CCM, plus CR731.|A. Hougardy|
|3.2.0<br>22/12/10|Release version|A. Hougardy|
|3.2.1<br>13/12/11|Including all CR’s that are in state “Analysis<br>completed” according to ERA CCM|A. Hougardy|
|3.3.0<br>07/03/12|Baseline 3 release version|A. Hougardy|
|3.3.1<br>04/04/14|CR’s 1155, 1185|O. Gemine|
|3.3.2<br>23/04/14|Baseline 3 1<sup>st</sup>maintenance pre-release version|O. Gemine|
|3.3.3<br>06/05/14|CR 1223<br>Baseline 3 1<sup>st</sup>maintenance 2<sup>nd</sup>pre-release version|O. Gemine|
|3.4.0<br>12/05/14|CR 1223<br>Baseline 3 1<sup>st</sup>maintenance release version|O. Gemine|
|3.4.1<br>23/06/15|CR’s 1014, 1222|O. Gemine|
|3.4.2<br>17/11/15|CR’s 299, 1262, 1265, 1266|O. Gemine|
|3.4.3<br>16/12/15|Update due to overall CR consolation phase|O. Gemine|
|3.5.0<br>18/12/15|Baseline 3 2<sup>nd</sup>release version as recommended to EC<br>(see ERA-REC-123-2015/REC)|O. Gemine|
|3.5.1<br>28/04/16|No change|O. Gemine|
|3.6.0<br>13/05/16|Baseline 3 2<sup>nd</sup>release version|A. Hougardy|
|3.6.1<br>29/05/17|No change|O. Gemine|

<!-- end of page 4 -->

|Issue Number<br>Date|Section Number<br>Modification / Description|Author|
|---|---|---|
|3.6.2<br>31/05/18|No change|O. Gemine|
|3.6.3<br>21/02/20|CR 1313|O. Gemine|
|3.6.4<br>22/06/20|No change|O. Gemine|
|3.6.5<br>22/12/21|CR 1238|O. Gemine|
|3.6.6<br>29/08/22|CR’s 968, 1120, 1342, 1350, 1367, 1408|O. Gemine|
|3.9.1<br>24/11/22|CR’s 988, 1307, 1423|O. Gemine|
|3.9.2<br>21/02/23|No change|O. Gemine|
|3.9.3<br>31/05/23|CR’s 1306, 1359<br>Outcome of B4R1 3<sup>rd</sup>consolidation phase|A Hougardy<br>O. Gemine|
|3.9.4<br>30/06/23|CR 1342 (updated)<br>Outcome of B4R1 4<sup>th</sup>consolidation phase|A Hougardy<br>O. Gemine|
|4.0.0<br>05/07/23|Baseline 4 1<sup>st</sup>release version|A Hougardy<br>O. Gemine|

<!-- end of page 5 -->

|**8.2**<br>|**Table of Contents**|
|---|---|
|8.1<br>Mo|dification History ........................................................................................................... 2|
|8.2<br>Ta|ble of Contents .............................................................................................................. 6|
|8.3<br>Intr|oduction ....................................................................................................................... 8|
|8.3.1|Scope and Purpose.................................................................................................... 8|
|8.3.2|Definitions .................................................................................................................. 8|
|8.4<br>Ru|les............................................................................................................................... 10|
|8.4.1|Common Rules ........................................................................................................ 10|
|8.4.2|Rules for Eurobalise telegrams ................................................................................ 12|
|8.4.3|Rules for Euroloop messages .................................................................................. 13|
|8.4.4|Rules for Euroradio messages ................................................................................. 14|
|8.5<br>Lis|t of radio Messages .................................................................................................... 18|
|8.5.1|Introduction .............................................................................................................. 18|
|8.5.2|Train to Track radio messages ................................................................................. 18|
|8.5.3|Track to Train radio messages ................................................................................. 19|
|8.6<br>De|finition of Radio Messages from Train to Track ........................................................... 20|
|8.6.1|Message 129: Validated Train Data ......................................................................... 20|
|8.6.2|Message 130: Request for Shunting ........................................................................ 20|
|8.6.2.1|Message 131: Request for Supervised Manoeuvre .............................................. 20|
|8.6.3|Message 132: MA Request ...................................................................................... 21|
|8.6.3.1|Message 133: Safe consist length information for SM .......................................... 21|
|8.6.4|Message 136: Train Position Report ........................................................................ 21|
|8.6.5|Message 137: Request to Shorten MA is granted .................................................... 22|
|8.6.6|Message 138: Request to Shorten MA is rejected .................................................... 22|
|8.6.7|Message 146: Acknowledgement............................................................................. 22|
|8.6.8|Message 147: Acknowledgement of Emergency Stop .............................................. 23|
|8.6.9|Message 149: Track Ahead Free Granted ............................................................... 23|
|8.6.10|Message 150: End of Mission .................................................................................. 24|
|8.6.11|Message 153: Radio infill request ............................................................................ 24|
|8.6.12|Message 154: No compatible version supported ...................................................... 24|
|8.6.13|Message 155: Initiation of a communication session ................................................ 25|
|8.6.14|Message 156: Termination of a communication session .......................................... 25|
|8.6.15|Message 157: SoM Position Report ......................................................................... 25|
|8.6.16|Message 158: Text Message Acknowledged by Driver ............................................ 26|
|8.6.17|Message 159: Session established .......................................................................... 26|
|8.7<br>De|finition of Radio Messages from Track to Train ........................................................... 27|
|8.7.1|Message 2: SR Authorisation ................................................................................... 27|
|8.7.2|Message 3: Movement Authority .............................................................................. 27|

<!-- end of page 6 -->

|8.7.2.1|Message 4: SM Authorisation ............................................................................... 28|
|---|---|
|8.7.2.2|Message 5: SM Refused ...................................................................................... 28|
|8.7.3|Message 6: Recognition of exit from TRIP mode ..................................................... 29|
|8.7.3.1|Message 7: Acknowledgment of safe consist length info for SM ........................... 29|
|8.7.4|Message 8: Acknowledgement of Train Data ........................................................... 29|
|8.7.5|Message 9: Request to Shorten MA ......................................................................... 30|
|8.7.6|Message 15: Conditional Emergency Stop ............................................................... 30|
|8.7.7|Message 16: Unconditional Emergency Stop ........................................................... 31|
|8.7.8|Message 18: Revocation of Emergency Stop ........................................................... 31|
|8.7.9|Message 24: General message ............................................................................... 31|
|8.7.10|Message 27: SH Refused ........................................................................................ 32|
|8.7.11|Message 28: SH Authorised ..................................................................................... 32|
|8.7.12|Message 32: RBC/RIU System Version ................................................................... 32|
|8.7.13|Message 33: MA with Shifted Location Reference ................................................... 33|
|8.7.14|Message 34: Track Ahead Free Request ................................................................. 33|
|8.7.15|Message 37: Infill MA ............................................................................................... 34|
|8.7.16|Message 38: Acknowledgement of session establishment ....................................... 34|
|8.7.17|Message 39: Acknowledgement of termination of a communication session ............ 34|
|8.7.18|Message 40: Train Rejected .................................................................................... 35|
|8.7.19|Message 41: Train Accepted .................................................................................... 35|
|8.7.20|Intentionally deleted ................................................................................................. 35|
|8.7.21|Message 43: SoM position report confirmed by RBC ............................................... 35|
|8.7.22|Message 45: Assignment of coordinate system ....................................................... 36|

<!-- end of page 7 -->

# **8.3 Introduction**

## **8.3.1 Scope and Purpose**

8.3.1.1 This chapter defines the format and content of messages necessary for ERTMS/ETCS functions.

8.3.1.2 Concerning the transmission media, this chapter does not cover considerations such as medium-specific use constraints (e.g. distance between track-circuit and balise…), as well as functions (e.g. detection of balise reference, time and location stamp, identifying type of receiving balise, Key Management, Releasing/maintaining a radio connection…) and performance of the transmission media.

## **8.3.2 Definitions**

8.3.2.1 Transmission media considered hereafter are standard ERTMS/ETCS transmission media used for ETCS (Eurobalise, Euroradio and Euroloop).

8.3.2.2 A message includes user data (application level) and protocol data (depending on the transmission medium).

8.3.2.3 A Eurobalise message is the information sent by a balise group (i.e. the message is composed of one or several telegrams, sorted by balise number in the group (telegram from balise number 1 first), each telegram is transmitted by a Eurobalise). A Eurobalise telegram contains one header and an identified and coherent set of Packets.

<!-- end of page 8 -->

<!-- Start of picture text -->
Reverse direction   Nominal direction<br>1st 2nd 3rd<br>Location Reference<br>Composition of message when passing the balise group in<br>nominal direction:<br>Balise telegrams read:  1st 2nd 3rd<br>Balise message composed:  1st 2nd 3rd<br>Composition of message when passing the balise group in<br>reverse direction:<br>Balise telegrams read:  3rd 2nd 1st<br>Balise message composed:  1st 2nd 3rd<br><!-- End of picture text -->

**Figure 1: Composition of a balise group message**

8.3.2.4 A Euroradio message contains one header and an identified and coherent set of variables (if needed) and Packets.

8.3.2.5 A Euroloop message contains one header and an identified and coherent set of Packets.

<!-- end of page 9 -->

# **8.4 Rules**

## **8.4.1 Common Rules**

8.4.1.1 A message (Euroradio/Euroloop) or telegram (Eurobalise) is composed of 1. One Header,

   2. When needed, a predefined set of variables (only for Radio),

   3. When needed, a predefined set of Packets (only for Radio),

4. Optional Packets as needed by application.

8.4.1.2 The transmission order shall respect the order of data elements listed in the message format (from top to bottom).

8.4.1.3 The behaviour of the receiver shall not depend on the sequence of the Packets given by the message.

8.4.1.3.1 Exception for Infill information: The locations given in the packets following packet 136 (Infill Location Reference) shall be referred to the balise group indicated in such packet.

8.4.1.3.2 Note: orientations are in any case always referred to the directionality of balise group (balise transmission), directionality of loop (Euroloop transmission) or directionality of LRBG (radio transmission).

8.4.1.4 A track-to-train message shall contain at most one instance of the same packet type for the same direction.

8.4.1.4.1 Exception 1: A message can contain several packets 44 (Data used by applications outside the ERTMS/ETCS system).

8.4.1.4.2 Exception 2: A message can contain several packets 65 (Temporary Speed Restriction). In case of revocable TSRs, the identities of the corresponding temporary speed restrictions (variable NID_TSR) transmitted in the same message shall be different.

8.4.1.4.3 Exception 3: A message can contain several packets 66 (TSR Revocation). The identities of the corresponding temporary speed restrictions (variable NID_TSR) transmitted in the same message shall be different.

8.4.1.4.4 Exception 4: A message transmitted by a balise group can contain one packet 136 per balise telegram per direction. Each packet 136 indicates which part of that telegram is to be considered as part of the infill information. Multiple packets 136 in balises of a balise group shall have identical content per direction.

8.4.1.4.5 Exception 5: A message can contain several packets 88 (Level Crossing information). The identities of the corresponding Level Crossings (variable NID_LX) transmitted in the same message shall be different.

<!-- end of page 10 -->

8.4.1.4.6 Exception 6: A message transmitted by a balise group can contain several packets 254 (default balise, loop or RIU information).

8.4.1.4.7 Exception 7: A message transmitted by a balise group can contain several packets 145 (Inhibition of balise group message consistency reaction).

8.4.1.4.8 Exception 8: A message transmitted by a balise group can contain several packets 0 (Virtual Balise Cover marker).

8.4.1.4.9 Exception 9: A message transmitted by a balise group can contain several packets 6 (Virtual Balise Cover order). The identities (pairs of variables NID_VBCMK and NID_C) of the corresponding VBC transmitted in the same message shall be different.

8.4.1.5 A train-to-track message shall contain at most one instance of the same packet type.

8.4.1.5.1 Exception: A message can contain several packets 44 (Data used by applications outside the ERTMS/ETCS system).

8.4.1.6 Note: For the purposes of clause 8.4.1.4, when the same packet is transmitted by duplicated balises, this is considered to be only a single instance of the packet within the message. Justification: The on-board equipment will only use one of these duplicated telegrams (and therefore only one set of duplicated packets) to compose the balise group message (see 3.16.2.4.8.2).

<!-- end of page 11 -->

## **8.4.2 Rules for Eurobalise telegrams**

8.4.2.1 The format of the telegram to be transmitted by each balise is as follows:

#### **General Format of Balise Telegram**

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
||Packet 0<br>(optional)|14|Virtual Balise Cover marker|
||Information|Variable|This information is composed according to the rules applicable<br>for packets.|
||Packet 255|8|Finishing flag of the telegram|

Number of bits in balise header: 50

8.4.2.2 The user information transmitted by a balise shall contain complete packets, i.e. splitting a packet between two balises is forbidden.

8.4.2.3 When used, the packet 0 shall be transmitted as the first packet of the telegram (i.e. it is appended to the header).

8.4.2.4 Note: If there is an active VBC stored on-board and in order to find a VBC marker, the ERTMS/ETCS on-board equipment needs first to check M_VERSION:

   - If M_VERSION = 0.Y, the telegram will be ignored;

   - If M_VERSION = 1.0, there will be no VBC marker;

   - If M_VERSION = 1.1, the on-board must look for a packet 200 (see chapter 6);

   - In all other cases (including when M_VERSION is higher than the highest system version supported by the on-board), the on-board must look for a packet 0.

<!-- end of page 12 -->

If a packet 0 or 200 is found, the ERTMS/ETCS on-board equipment must also check whether NID_C matches the VBC marker included in the packet 0 or 200. This implies that in all future system versions the size and location of M_VERSION and NID_C inside the header, the overall size of the header and the position/content of the packet 0 appended to it, will remain invariant.

## **8.4.3 Rules for Euroloop messages**

### 8.4.3.1 The format of the message to be transmitted by each loop is as follows:

|**General Fo**|**rmat of Loop Mess**|**age**||
|---|---|---|---|
|Field No.|VARIABLE|Length ( bits)|Remarks|
|1|Q_UPDOWN|1|Defines the direction of the information:<br>Down-link message (train to track) (0)<br>Up-link message (track to train) (1)|
|2|M_VERSION|7|Version of the ERTMS/ETCS system.|
|3|Q_MEDIA|1|Defines the type of media: Loop   (1)|
|4|NID_C|10|Country or region.|
|5|NID_LOOP|14|Identity of Euroloop.|
||Information|Variable|This information is composed according to the rules applicable<br>for packets.|
||Packet 255|8|Finishing flag of the message|

Number of bits in loop header: 33

### 8.4.3.2 Intentionally deleted.

<!-- end of page 13 -->

## **8.4.4 Rules for Euroradio messages**

8.4.4.1 The message identifier is unique (variable NID_MESSAGE).

8.4.4.1.1 All message identifiers not listed in 8.5.3 shall be considered as invalid values (i.e. like spare values) when received by the on-board equipment. Exception: reception of information only differing by Y with regards to the highest system version number X supported by on-board (refer to section 3.17.3.11 b)).

8.4.4.1.1.1 Note: Depending on the system version number with which the message was transmitted relevant exception from chapter 6 may apply regarding 8.5.3.

8.4.4.2 Each message shall indicate its own length through the use of the variable L_MESSAGE.

8.4.4.2.1 The receiver shall check whether the computed length of the message is equal to the length given by L_MESSAGE.

8.4.4.3 The messages shall be composed of predefined variables and packets.

8.4.4.4 For some messages, it shall be possible to add optional packets at the end of the message.

8.4.4.4.1 The track to train messages possibly including optional packets are listed hereafter:

|**Track to Train message**|**Mess. ID**|**Optional packets**|
|---|---|---|
|SR Authorisation|2|63|
|Movement Authority|3|21, 27, 49, 80, plus common optional packets|
|SM Authorisation|4|3, 5, 31, 39, 40, 44, 45, 51, 58, 64, 65, 66, 67,<br>68, 69, 71, 73, 74, 79, 88, 131, 140|
|Request To Shorten MA|9|49, 80|
|General Message|24|From RBC: 21, 27, plus common optional<br>packets<br>From RIU: 44, 45, 143, 180, 254|
|SH authorised|28|3, 44, 49|
|MA with Shifted Location Reference|33|21, 27, 49, 80, plus common optional packets|
|Infill MA|37|5, 21, 27, 39, 40, 41, 44, 49, 51, 52, 65, 68, 69,<br>70, 71, 80, 88, 138, 139|

<!-- end of page 14 -->

8.4.4.4.1.1 The common optional packets are the following ones:

### **Common optional packets**

3, 5, 31, 32, 39, 40, 51, 41, 42, 44, 45, 52, 57, 58, 64, 65, 66, 67, 68, 69, 70, 71, 73, 74, 79, 88, 131, 138, 139, 140, 180

8.4.4.4.2 The train to track message 136 (Train Position Report)may include the following packets:

   - a) Packet 4 (Error Reporting, see section 3.16.4),

   - b) Packet 5 (Train running number, see section 3.18.4.5),

   - c) Packet 44 (Data used by applications outside the ERTMS/ETCS system).

8.4.4.4.3 The train to track message 157 (SoM Position Report) may include the following packets:

   - a) Packet 4 (Error Reporting, see section 3.16.4),

   - b) Packet 5 (Train running number, see section 5.4.3.2 A33&A34),

   - c) Packet 10 (Safe consist length information for Supervised Manoeuvre, see section 5.4.3.2 A33&A34),

   - d) Packet 11 (Train Data, see section 5.4.3.2 A33&A34),

   - e) Packet 44 (Data used by applications outside the ERTMS/ETCS system).

8.4.4.4.4 The train to track message 132 (MA request) may include the following packet: a) Packet 9 (Level 2 transition information, see clauses 3.8.2.7.1&2)

8.4.4.4.5 The train to track message 131 (Request for Supervised Manoeuvre) may optionally include the following packet:

   - a) Packet 12 (Default Train Data for Supervised Manoeuvre)

8.4.4.5 If needed to obtain an integer number of bytes, padding shall be added at the end of the message.

<!-- end of page 15 -->

8.4.4.6 Standard format of a radio message from track to train :

8.4.4.6.1 Format:

|Field<br>No.|VARIABLE|Remarks|
|---|---|---|
|1|NID_MESSAGE|Message Identification Number|
|2|L_MESSAGE|Message length including everything (from field 1 to padding<br>inclusive).|
|3|T_TRAIN|Time Stamp from RBC (see sections 3.16.3.2 & 3.16.3.3).|
|4|M_ACK|Indicates whether the message must be acknowledged (or not) by<br>the on-board equipment (message n° 146).|
|5|NID_LRBG|Identification Number of LRBG.|
|…|variables as<br>required by<br>NID_MESSAGE|If needed for this message. Used when sending variables which<br>are not included in a packet.|
|…|packets as<br>required by<br>NID_MESSAGE|If needed for this message.|
||Optional packets|Refer to section 8.4.4.4 of this document.|
||Padding|If required.|

8.4.4.6.2 Note: In section 8.7 giving the contents of the messages, the padding information is intentionally omitted.

8.4.4.6.3 The track to train message 39 (Acknowledgement of termination of a communication session) shall include the variable M_ACK set to 0. Justification: see 3.5.5.3.

8.4.4.7 Standard format of a radio message from train to track:

<!-- end of page 16 -->

### 8.4.4.7.1 Format:

|Field<br>No.|VARIABLE|Remarks|
|---|---|---|
|1|NID_MESSAGE|Message Identification Number|
|2|L_MESSAGE|Message length including everything (from field 1 to padding<br>inclusive).|
|3|T_TRAIN|Time Stamp from Train (see chapter 3 – Data Consistency).|
|4|NID_ENGINE|Identity of the train.|
|5|variables as<br>required by<br>NID_MESSAGE|If needed for this message. Used when sending variables which<br>are not included in a packet.|
|6|Packet 0 or 1|Train-to-track packet type 0 – Position report, or packet type 1 -<br>Position report based on two balise groups. Not included in<br>messages 146, 154, 155, 156 and 159.|
|7|Other Packets as<br>required by<br>NID_MESSAGE||
|8|Optional packets||
||Padding|If required.|

8.4.4.7.2 Exception:  The position report (packet 0 or packet 1) is not included in the following messages:

   - a) Message 146 (Acknowledgement),

   - b) Message 154 (No compatible version supported),

   - c) Message 155 (Initiation of a communication session),

   - d) Message 156 (Termination of a communication session),

   - e) Intentionally deleted

   - f) Message 159 (Session Established).

8.4.4.7.3 Note: In section 8.6 giving the contents of the messages, the padding information is intentionally omitted.

<!-- end of page 17 -->

# **8.5 List of radio Messages**

## **8.5.1 Introduction**

8.5.1.1 This section identifies the radio messages with corresponding Message Identifier (“Mes. Id.”) and Message Name. It also gives a list of the version-invariant messages.

8.5.1.2 Intentionally deleted.

## **8.5.2 Train to Track radio messages**

|**Mes. Id.**|**Message Name**|**Invariant**|**Transmitted to**|
|---|---|---|---|
|129|Validated Train Data|No|RBC|
|130|Request for Shunting|No|RBC|
|131|Request for Supervised Manoeuvre|No|RBC|
|132|MA Request|No|RBC|
|133|Safe consist length information for Supervised<br>Manoeuvre|No|RBC|
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
|158|Text message acknowledged by driver|No|RBC|
|159|Session Established|No|RBC, RIU|

<!-- end of page 18 -->

## **8.5.3 Track to Train radio messages**

|**Mes. Id.**|**Message Name**|**Invariant**|**Transmitted by**|
|---|---|---|---|
|2|SR Authorisation|No|RBC|
|3|Movement Authority|No|RBC|
|4|SM Authorisation|No|RBC|
|5|SM Refused|No|RBC|
|6|Recognition of exit from TRIP mode|No|RBC|
|7|Acknowledgement of safe consist length info for<br>SM|No|RBC|
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
|38|Acknowledgement of session establishment|No|RBC, RIU|
|39|Acknowledgement<br>of<br>termination<br>of<br>a<br>communication session|Yes|RBC, RIU|
|41|Train Accepted|No|RBC|
|43|SoM position report confirmed by RBC|No|RBC|
|45|Assignment of coordinate system|No|RBC|

<!-- end of page 19 -->

# **8.6 Definition of Radio Messages from Train to Track**

## **8.6.1 Message 129: Validated Train Data**

<!-- Start of picture text -->
Field  VARIABLE/  Remarks<br>No.  PACKET<br>1  NID_MESSAGE<br>2  L_MESSAGE<br>3  T_TRAIN<br>4  NID_ENGINE<br>5  Packet 0 or 1<br>6  Train data  Train - track packet type 11.<br><!-- End of picture text -->

## **8.6.2 Message 130: Request for Shunting**

<!-- Start of picture text -->
Field  VARIABLE/  Remarks<br>No.  PACKET<br>1  NID_MESSAGE<br>2  L_MESSAGE<br>3  T_TRAIN<br>4  NID_ENGINE<br>5  Packet 0 or 1<br><!-- End of picture text -->

## **8.6.2.1 Message 131: Request for Supervised Manoeuvre**

<!-- Start of picture text -->
Field  VARIABLE/  Remarks<br>No.  PACKET<br>1  NID_MESSAGE<br>2  L_MESSAGE<br>3  T_TRAIN<br>4  NID_ENGINE<br>5  Packet 0 or 1<br>6  Packet 10<br>7  Optional packet<br><!-- End of picture text -->

<!-- end of page 20 -->

## **8.6.3 Message 132: MA Request**

<!-- Start of picture text -->
Field  VARIABLE/  Remarks<br>No.  PACKET<br>1  NID_MESSAGE<br>2  L_MESSAGE<br>3  T_TRAIN<br>4  NID_ENGINE<br>5  Q_MARQSTREAS<br>ON<br>6  Packet 0 or 1<br>7  Optional packets<br><!-- End of picture text -->

## **8.6.3.1 Message 133: Safe consist length information for SM**

<!-- Start of picture text -->
Field  VARIABLE/  Remarks<br>No.  PACKET<br>1  NID_MESSAGE<br>2  L_MESSAGE<br>3  T_TRAIN<br>4  NID_ENGINE<br>5  Packet 0 or 1<br>6  Packet 10<br><!-- End of picture text -->

## **8.6.4 Message 136: Train Position Report**

<!-- Start of picture text -->
Field  VARIABLE/  Remarks<br>No.  PACKET<br>1  NID_MESSAGE<br>2  L_MESSAGE<br>3  T_TRAIN<br>4  NID_ENGINE<br>5  Packet 0 or 1<br>6  Optional packets<br><!-- End of picture text -->

<!-- end of page 21 -->

## **8.6.5 Message 137: Request to Shorten MA is granted**

<!-- Start of picture text -->
Field  VARIABLE/  Remarks<br>No.  PACKET<br>1  NID_MESSAGE<br>2  L_MESSAGE<br>3  T_TRAIN<br>4  NID_ENGINE<br>5  T_TRAIN  Time stamp contained in the request.<br>6  Packet 0 or 1<br><!-- End of picture text -->

## **8.6.6 Message 138: Request to Shorten MA is rejected**

<!-- Start of picture text -->
Field  VARIABLE/  Remarks<br>No.  PACKET<br>1  NID_MESSAGE<br>2  L_MESSAGE<br>3  T_TRAIN<br>4  NID_ENGINE<br>5  T_TRAIN  Time stamp contained in the request.<br>6  Packet 0 or 1<br><!-- End of picture text -->

## **8.6.7 Message 146: Acknowledgement**

<!-- Start of picture text -->
Field  VARIABLE  Remarks<br>No.<br>1  NID_MESSAGE<br>2  L_MESSAGE<br>3  T_TRAIN<br>4  NID_ENGINE<br>5  T_TRAIN   Time stamp contained in the message that is acknowledged.<br><!-- End of picture text -->

<!-- end of page 22 -->

## **8.6.8 Message 147: Acknowledgement of Emergency Stop**

<!-- Start of picture text -->
Field  VARIABLE  Remarks<br>No.<br>1  NID_MESSAGE<br>2  L_MESSAGE<br>3  T_TRAIN<br>4  NID_ENGINE<br>5  NID_EM  Identification Number of the acknowledged Emergency Message.<br>6  Q_EMERGENCY<br>STOP<br>7  Packet 0 or 1<br><!-- End of picture text -->

## **8.6.9 Message 149: Track Ahead Free Granted**

<!-- Start of picture text -->
Field  VARIABLE/  Remarks<br>No.  PACKET<br>1  NID_MESSAGE<br>2  L_MESSAGE<br>3  T_TRAIN<br>4  NID_ENGINE<br>5  Packet 0 or 1<br><!-- End of picture text -->

<!-- end of page 23 -->

## **8.6.10 Message 150: End of Mission**

<!-- Start of picture text -->
Field  VARIABLE/  Remarks<br>No.  PACKET<br>1  NID_MESSAGE<br>2  L_MESSAGE<br>3  T_TRAIN<br>4  NID_ENGINE<br>5  Q_DESK<br>6  Packet 0 or 1<br><!-- End of picture text -->

## **8.6.11 Message 153: Radio infill request**

<!-- Start of picture text -->
Field  VARIABLE  Remarks<br>No.<br>1  NID_MESSAGE<br>2  L_MESSAGE<br>3  T_TRAIN<br>4  NID_ENGINE<br>5  NID_C  identity of the country of the “target” main balise group<br>6  NID_BG  identity of the “target” main balise group<br>7  Q_INFILL  start; end of infill<br>8  Packet 0 or 1<br><!-- End of picture text -->

## **8.6.12 Message 154: No compatible version supported**

<!-- Start of picture text -->
Field  VARIABLE/  Remarks<br>No.  PACKET<br>1  NID_MESSAGE<br>2  L_MESSAGE<br>3  T_TRAIN<br>4  NID_ENGINE<br><!-- End of picture text -->

<!-- end of page 24 -->

## **8.6.13 Message 155: Initiation of a communication session**

<!-- Start of picture text -->
Field  VARIABLE/  Remarks<br>No.  PACKET<br>1  NID_MESSAGE<br>2  L_MESSAGE<br>3  T_TRAIN<br>4  NID_ENGINE<br><!-- End of picture text -->

## **8.6.14 Message 156: Termination of a communication session**

<!-- Start of picture text -->
Field  VARIABLE/  Remarks<br>No.  PACKET<br>1  NID_MESSAGE<br>2  L_MESSAGE<br>3  T_TRAIN<br>4  NID_ENGINE<br><!-- End of picture text -->

## **8.6.15 Message 157: SoM Position Report**

<!-- Start of picture text -->
Field  VARIABLE/  Remarks<br>No.  PACKET<br>1  NID_MESSAGE<br>2  L_MESSAGE<br>3  T_TRAIN<br>4  NID_ENGINE<br>5  Q_STATUSLRBG<br>6  Packet 0 or 1<br>7  Optional packets<br><!-- End of picture text -->

<!-- end of page 25 -->

## **8.6.16 Message 158: Text Message Acknowledged by Driver**

<!-- Start of picture text -->
Field  VARIABLE/  Remarks<br>No.  PACKET<br>1  NID_MESSAGE<br>2  L_MESSAGE<br>3  T_TRAIN<br>4  NID_ENGINE<br>5  NID_TEXTMESSA Identity of the text message that the driver has acknowledged.<br>GE<br>6  Packet 0 or 1<br><!-- End of picture text -->

## **8.6.17 Message 159: Session established**

<!-- Start of picture text -->
Field  VARIABLE/  Remarks<br>No.  PACKET<br>1  NID_MESSAGE<br>2  L_MESSAGE<br>3  T_TRAIN<br>4  NID_ENGINE<br>5  Packet 2<br><!-- End of picture text -->

<!-- end of page 26 -->

# **8.7 Definition of Radio Messages from Track to Train**

## **8.7.1 Message 2: SR Authorisation**

<!-- Start of picture text -->
Field  VARIABLE  Remarks<br>No.<br>1  NID_MESSAGE<br>2  L_MESSAGE<br>3  T_TRAIN<br>4  M_ACK<br>5  NID_LRBG<br>6  Q_SCALE<br>7  D_SR<br>8  Optional packets<br><!-- End of picture text -->

## **8.7.2 Message 3: Movement Authority**

<!-- Start of picture text -->
Field  VARIABLE  Remarks<br>No.<br>1  NID_MESSAGE<br>2  L_MESSAGE<br>3  T_TRAIN<br>4  M_ACK<br>5  NID_LRBG<br>6  Level 2 Movement  Packet 15<br>Authority<br>7  Optional packets<br><!-- End of picture text -->

<!-- end of page 27 -->

## **8.7.2.1 Message 4: SM Authorisation**

<!-- Start of picture text -->
Field  VARIABLE/PACK Remarks<br>No.  ET<br>1  NID_MESSAGE<br>2  L_MESSAGE<br>3  T_TRAIN<br>4  M_ACK<br>5  NID_LRBG<br>6  T_TRAIN  Time stamp of the Supervised Manoeuvre request<br>7  Q_SCALE<br>8  D_REF  Reference Distance<br>9  V_SM  Supervised Manoeuvre mode speed limit<br>10   Level 2 Movement  Packet 15<br>Authority<br>11   Gradient profile  Packet 21<br>12   International Static  Packet 27<br>Speed Profile<br>13   Optional packets<br><!-- End of picture text -->

## **8.7.2.2 Message 5: SM Refused**

<!-- Start of picture text -->
Field  VARIABLE  Remarks<br>No.<br>1  NID_MESSAGE<br>2  L_MESSAGE<br>3  T_TRAIN<br>4  M_ACK<br>5  NID_LRBG<br>6  T_TRAIN  Time stamp of the Supervised Manoeuvre request<br><!-- End of picture text -->

<!-- end of page 28 -->

## **8.7.3 Message 6: Recognition of exit from TRIP mode**

<!-- Start of picture text -->
Field  VARIABLE  Remarks<br>No.<br>1  NID_MESSAGE<br>2  L_MESSAGE<br>3  T_TRAIN<br>4  M_ACK<br>5  NID_LRBG<br><!-- End of picture text -->

## **8.7.3.1 Message 7: Acknowledgment of safe consist length info for SM**

<!-- Start of picture text -->
Field  VARIABLE  Remarks<br>No.<br>1  NID_MESSAGE<br>2  L_MESSAGE<br>3  T_TRAIN<br>4  M_ACK<br>5  NID_LRBG<br>6  T_TRAIN  Time stamp of the message Safe consist length info for SM<br><!-- End of picture text -->

## **8.7.4 Message 8: Acknowledgement of Train Data**

<!-- Start of picture text -->
Field  VARIABLE  Remarks<br>No.<br>1  NID_MESSAGE<br>2  L_MESSAGE<br>3  T_TRAIN<br>4  M_ACK<br>5  NID_LRBG<br>6  T_TRAIN  Reference to received train data message<br><!-- End of picture text -->

<!-- end of page 29 -->

## **8.7.5 Message 9: Request to Shorten MA**

<!-- Start of picture text -->
Field  VARIABLE  Remarks<br>No.<br>1  NID_MESSAGE<br>2  L_MESSAGE<br>3  T_TRAIN<br>4  M_ACK<br>5  NID_LRBG<br>6  Level 2 Movement  Packet 15<br>Authority<br>7  Optional packets<br><!-- End of picture text -->

## **8.7.6 Message 15: Conditional Emergency Stop**

<!-- Start of picture text -->
Field  VARIABLE  Remarks<br>No.<br>1  NID_MESSAGE<br>2  L_MESSAGE<br>3  T_TRAIN<br>4  M_ACK<br>5  NID_LRBG<br>6  NID_EM  Identification Number of the Emergency Stop Message.<br>7  Q_SCALE<br>8  D_REF<br>9  Q_DIR<br>10   D_EMERGENCYSTOP<br><!-- End of picture text -->

<!-- end of page 30 -->

## **8.7.7 Message 16: Unconditional Emergency Stop**

<!-- Start of picture text -->
Field  VARIABLE  Remarks<br>No.<br>1  NID_MESSAGE<br>2  L_MESSAGE<br>3  T_TRAIN<br>4  M_ACK<br>5  NID_LRBG<br>6  NID_EM  Identification Number of the Emergency Stop Message.<br><!-- End of picture text -->

## **8.7.8 Message 18: Revocation of Emergency Stop**

<!-- Start of picture text -->
Field  VARIABLE  Remarks<br>No.<br>1  NID_MESSAGE<br>2  L_MESSAGE<br>3  T_TRAIN<br>4  M_ACK<br>5  NID_LRBG<br>6  NID_EM  Identification Number of the Emergency Stop Message.<br><!-- End of picture text -->

## **8.7.9 Message 24: General message**

<!-- Start of picture text -->
Field  VARIABLE  Remarks<br>No.<br>1  NID_MESSAGE<br>2  L_MESSAGE<br>3  T_TRAIN<br>4  M_ACK<br>5  NID_LRBG<br>6  Optional packets<br><!-- End of picture text -->

<!-- end of page 31 -->

## **8.7.10 Message 27: SH Refused**

<!-- Start of picture text -->
Field  VARIABLE  Remarks<br>No.<br>1  NID_MESSAGE<br>2  L_MESSAGE<br>3  T_TRAIN<br>4  M_ACK<br>5  NID_LRBG<br>6  T_TRAIN  Time stamp of the shunting request.<br><!-- End of picture text -->

## **8.7.11 Message 28: SH Authorised**

<!-- Start of picture text -->
Field  VARIABLE  Remarks<br>No.<br>1  NID_MESSAGE<br>2  L_MESSAGE<br>3  T_TRAIN<br>4  M_ACK<br>5  NID_LRBG<br>6  T_TRAIN  Time stamp of the shunting request.<br>7  Optional packets<br><!-- End of picture text -->

## **8.7.12 Message 32: RBC/RIU System Version**

<!-- Start of picture text -->
Field  VARIABLE  Remarks<br>No.<br>1  NID_MESSAGE<br>2  L_MESSAGE<br>3  T_TRAIN<br>4  M_ACK<br>5  NID_LRBG<br>6  M_VERSION  Version of the ERTMS/ETCS system.<br><!-- End of picture text -->

<!-- end of page 32 -->

## **8.7.13 Message 33: MA with Shifted Location Reference**

<!-- Start of picture text -->
Field  VARIABLE  Remarks<br>No.<br>1  NID_MESSAGE<br>2  L_MESSAGE<br>3  T_TRAIN<br>4  M_ACK<br>5  NID_LRBG<br>6  Q_SCALE<br>7  D_REF  Reference Distance<br>8  Level 2 Movement  Packet 15<br>Authority<br>9  Optional packets<br><!-- End of picture text -->

## **8.7.14 Message 34: Track Ahead Free Request**

<!-- Start of picture text -->
Field  VARIABLE  Remarks<br>No.<br>1  NID_MESSAGE<br>2  L_MESSAGE<br>3  T_TRAIN<br>4  M_ACK<br>5  NID_LRBG<br>6  Q_SCALE<br>7  D_REF<br>8  Q_DIR<br>9  D_TAFDISPLAY<br>10   L_TAFDISPLAY<br><!-- End of picture text -->

<!-- end of page 33 -->

## **8.7.15 Message 37: Infill MA**

<!-- Start of picture text -->
Field  VARIABLE  Remarks<br>No.<br>1  NID_MESSAGE<br>2  L_MESSAGE<br>3  T_TRAIN<br>4  M_ACK<br>5  NID_LRBG<br>6  Infill Location  Packet 136<br>Reference<br>7  Level 1 Movement  Packet 12<br>Authority<br>8  Optional packets<br><!-- End of picture text -->

## **8.7.16 Message 38: Acknowledgement of session establishment**

<!-- Start of picture text -->
Field  VARIABLE  Remarks<br>No.<br>1  NID_MESSAGE<br>2  L_MESSAGE<br>3  T_TRAIN<br>4  M_ACK<br><!-- End of picture text -->

## **8.7.17 Message 39: Acknowledgement of termination of a communication session**

<!-- Start of picture text -->
Field  VARIABLE  Remarks<br>No.<br>1  NID_MESSAGE<br>2  L_MESSAGE<br>3  T_TRAIN<br>4  M_ACK  always set to 0<br>5  NID_LRBG<br><!-- End of picture text -->

<!-- end of page 34 -->

## **8.7.18 Message 40: Train Rejected**

<!-- Start of picture text -->
Field  VARIABLE  Remarks<br>No.<br>1  NID_MESSAGE<br>2  L_MESSAGE<br>3  T_TRAIN<br>4  M_ACK<br>5  NID_LRBG<br><!-- End of picture text -->

## **8.7.19 Message 41: Train Accepted**

<!-- Start of picture text -->
Field  VARIABLE  Remarks<br>No.<br>1  NID_MESSAGE<br>2  L_MESSAGE<br>3  T_TRAIN<br>4  M_ACK<br>5  NID_LRBG<br><!-- End of picture text -->

## **8.7.20 Intentionally deleted**

## **8.7.21 Message 43: SoM position report confirmed by RBC**

<!-- Start of picture text -->
Field  VARIABLE  Remarks<br>No.<br>1  NID_MESSAGE<br>2  L_MESSAGE<br>3  T_TRAIN<br>4  M_ACK<br>5  NID_LRBG<br><!-- End of picture text -->

<!-- end of page 35 -->

## **8.7.22 Message 45: Assignment of coordinate system**

<!-- Start of picture text -->
Field  VARIABLE  Remarks<br>No.<br>1  NID_MESSAGE<br>2  L_MESSAGE<br>3  T_TRAIN<br>4  M_ACK<br>5  NID_LRBG<br>6  Q_ORIENTATION<br><!-- End of picture text -->

<!-- end of page 36 -->
