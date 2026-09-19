## **3.4 Balise configuration, linking and Euroloop**

**3.4.1 Balise Configurations – Balise Group Definition**

3.4.1.1 A balise group consists of between one and eight balises sharing the same balise group identity.

3.4.1.2 In every balise, the following information is at least stored: a) The internal number (from 1 to 8) of the balise

   - b) The number of balises inside the group

   - c) The balise group identity.

3.4.1.3 The internal number of the balise describes the relative position of the balise in the group.

### **3.4.2 Balise Co-ordinate System**

3.4.2.1.1 Every balise group has its own co-ordinate system.

3.4.2.1.2 The orientation of the co-ordinate system of a balise group is defined by the nominal direction (see 3.4.2.2.2) and is identified as balise group orientation.

**3.4.2.2 Balise groups composed of two or more balises**

3.4.2.2.1 The origin of the co-ordinate system for each balise group is given by the balise number 1 (called location reference) in the balise group.

3.4.2.2.1.1 Exception: If the balise number 1 of the group is duplicated, the balise number 2 shall be the location reference in case, out of this pair of duplicated balises, the ERTMS/ETCS on-board equipment has only received the telegram from the balise number 2.

<!-- end of page 10 -->

3.4.2.2.2 The nominal/reverse direction of each balise group is defined by increasing/decreasing internal balise numbers.

<!-- Start of picture text -->
Reverse direction   Nominal direction  Balise Group orientation<br>Location Reference  Balise Group schematic<br>representation<br>1st 2nd 3rd<br><!-- End of picture text -->

**Figure 1: Orientation of the balise group**

#### **3.4.2.3 Balise groups composed of a single balise**

3.4.2.3.1 Balise groups consisting of only one single balise are referred to as "single balise groups" in the following.

No inherent coordinate system

<!-- Start of picture text -->
Single Balise Group<br>Location Reference  schematic representation<br>1st<br>Figure 1a: Single balise group<br><!-- End of picture text -->

#### **3.4.2.3.2 Assignment of the co-ordinate system by means of linking information:**

3.4.2.3.2.1 Intentionally deleted.

3.4.2.3.2.2 For balise groups consisting of a single balise, the information "direction with which the linked balise group will be passed over" from a previously received linking information shall assign a co-ordinate system to the balise.

<!-- end of page 11 -->

<!-- Start of picture text -->
Nominal<br>or reverse<br>Linking<br>Linking distance  information<br>reverse  nominal<br>Reference  Single balise group with co-<br>Balise group  ordinate system assigned by<br>with inherent  linking information<br>co-ordinate<br>system<br><!-- End of picture text -->

#### **Figure 2: Assignment of a co-ordinate system to a single balise group by linking**

3.4.2.3.2.3 The reference for the linking information can be either a single balise group if a coordinate system has been assigned to it before, or a balise group consisting of two or more balises (with "inherent" co-ordinate system)

#### **3.4.2.3.3 Assignment of the co-ordinate system by means of a dialogue between the onboard and the RBC:**

3.4.2.3.3.1 If the ERTMS/ETCS on-board equipment cannot evaluate the orientation of the last balise group received, being a single balise group, i.e. no linking information is available to identify the orientation of the co-ordinate system of this single balise group, the ERTMS/ETCS on-board equipment shall report its position by means of a position report based on two balise groups reporting the train position in reference to the LRBG and the “previous LRBG”, if any.

3.4.2.3.3.1.1 Note: Receiving this type of position report advises the RBC of the need to assign a co-ordinate system to this single balise group.

3.4.2.3.3.2 When a single balise group is received and the previous LRBG is known, the position report based on two balise groups shall use as direction reference a move from the “previous LRBG” towards this single balise group (being the new LRBG): directional information in the position report pointing in the same direction as the direction reference shall be reported as “nominal”, otherwise as “reverse”.

3.4.2.3.3.3 If the “previous LRBG “ is not known, the “previous LRBG” and all directional information of the position report based on two balise groups shall be reported as “unknown”.

3.4.2.3.3.4 If a new single balise group (BG2), different from the current LRBG (BG1), becomes LRBG while the running direction of the train is opposite to the running direction when this current LRBG (BG1) was last passed, the “previous LRBG” and all directional

<!-- end of page 12 -->

information of the position report based on two balise groups shall be reported as “unknown” (see Figure 2a).

<!-- Start of picture text -->
LRBG = BG2<br>PrevLRBG = unknown<br>Dir train position = unknown<br>open<br>Dir train orientation = unknown<br>cab<br>Dir running = unknown<br>|<br>BG2<br>\<br>BG1<br>_<br>Figure 2a: Position report based on two balise groups versus train running direction<br>3.4.2.3.3.5 If a single balise group, being the LRBG, is received again, the LRBG and the “previous<br>LRBG” of the position report based on two balise groups shall remain unchanged.<br><!-- End of picture text -->

3.4.2.3.3.6 The assignment of a co-ordinate system received from the RBC shall identify the balise group for which the assignment is given, and shall assign a balise group orientation “nominal” or “reverse” to this balise group relative to the on-board direction reference reported in the position report based on two balise groups (see 3.4.2.3.3.2).

3.4.2.3.3.6.1 Note: From the sequence of reported balise groups, the RBC can derive the balise group orientation with which the balise group was passed.

<!-- end of page 13 -->

<!-- Start of picture text -->
Train running<br>direction<br>LRBG = BGx<br>LRBG = BGx<br>PRVLRBG = BGy<br>Dir train position =  nom Dir train position =  rev<br>Dir train orientation =  nom Dir train orientation =  rev<br>Dir running = nom Dir running =  rev<br>open open<br>cab  cab<br>Distance from LRBG  Distance from LRBG<br>BGy  BGx  BGx<br>On-board reference direction  RBC:<br>„nominal“<br>Trackside balise group<br>orientation of BGx relative<br>Before assignment of   After assignment of<br>to a move from BGy to<br>co-ordinate system by the RBC  BGx is “reverse”  co-ordinate system by the RBC<br><!-- End of picture text -->

#### **Figure 2b: Example for assigning a co-ordinate system**

3.4.2.3.3.7 For single balise groups reported as LRBG and stored according to 3.6.2.2.2c, awaiting an assignment of a co-ordinate system, the ERTMS/ETCS on-board equipment shall be able to discriminate if a single balise has been reported more than once and with different “previous LRBGs” to the RBC.

3.4.2.3.3.7.1 Note: For a single balise group reported as LRBG awaiting the assignment of a coordinate system also the rules for LRBGs reported to the RBC (see 3.6.2.2.2) apply.

3.4.2.3.3.8 A co-ordinate system assignment received from trackside shall be rejected by the ERTMS/ETCS on-board equipment if the referred LRBG is memorised (see 3.6.2.2.2c) to have been reported more than once and with different “previous LRBGs”.

3.4.2.3.3.8.1 Note: If a single balise group is memorised, according to 3.6.2.2.2c, more than once, and with different “previous LRBGs”, the assignment of the co-ordinate system is ambiguous.

#### **3.4.2.4 Balise groups composed of one pair of duplicated balises**

3.4.2.4.1 A group of two balises duplicating each other shall be treated as a single balise group in case where only one balise is correctly read.

<!-- end of page 14 -->

### **3.4.3 Balise Information Types and Usage**

3.4.3.1 In level 1, all information to the on-board system is given from balise groups or additionally from Euroloops or Radio Infill Units (see section 3.9). In level 2, balise groups are mostly used for location information.

3.4.3.2 In level 1, the balise information can be of the following type (please refer to sections 3.6.2.3 and 3.8.5):

a) Non-infill

b) Intentionally deleted

c) Infill.

3.4.3.2.1 Intentionally deleted.

3.4.3.2.2 Note: Infill information is referring to the location reference of an announced balise group.

3.4.3.3 Some information shall be read also in sleeping mode and when no linking information is available (see Chapter 4 Use of received information). If such information is transmitted by balises, and if the information is directional, balise groups consisting of at least two balises shall be used.

### **3.4.4 Linking**

**3.4.4.1 Introduction**

3.4.4.1.1 Aim of linking:

   - To determine whether a balise group has been missed or not received within the expectation window (see section 3.4.4.4) and take the appropriate action.

   - To assign a co-ordinate system to balise groups consisting of a single balise.

   - To perform the relocation of location based information without any consideration of the odometer inaccuracy (see section 3.6.4).

3.4.4.1.2 A balise group is linked when its linking information (see section 3.4.4.2) is known in advance.

3.4.4.1.2.1 Note: In cases where a balise group contains repositioning information, the term linked also applies since the balise group is announced, marked as linked and contains repositioning information marked accordingly.

**3.4.4.2 Content of linking information**

3.4.4.2.1 Linking information shall be composed of:

   - a) The identity of the linked balise group.

b) Where the location reference of the group is.

- c) The accuracy of this location.

<!-- end of page 15 -->

Note: If the reference balise is duplicated, it is the trackside responsibility to define the location accuracy to cover at least the location of the two duplicated balises.

   - d) The direction with which the linked balise group will be passed over (nominal or reverse).

   - e) The reaction required if a data consistency problem occurs with the linked balise group.

3.4.4.2.1.1 "Linking consistency is checked" shall be interpreted as when:

   - a) linking information is stored on-board, AND

   - b) depending on the mode the linking consistency check is active, AND

   - c) the supervision of the expectation window of the furthest announced balise group has not yet been stopped (see 3.4.4.4.6).

3.4.4.2.2 Instead of the identity of a linked balise group it shall be possible to identify a following linked balise group as unknown but containing repositioning information.

3.4.4.2.2.1 Intentionally deleted.

3.4.4.2.2.2 Note 1: Regarding the repositioning information, see chapter 3.8.5.3.5 and 3.8.5.2.

3.4.4.2.2.3 Note 2: In case the identity of the next balise group is not unambiguously known because the route is not known by the trackside, this feature allows to link this balise group.

3.4.4.2.3 For each linked balise group, the trackside shall select one of the following reactions to be used in case of data inconsistencies:

   - a) Train trip  (Trip mode, see Chapter 4)

   - b) Command service brake

   - c) No reaction

For further details see section 3.16.2.

#### **3.4.4.3 Unlinked Balise Groups**

3.4.4.3.1 A balise group, which contains information that must be considered even when the balise group is not announced by linking, is called an unlinked balise group.

3.4.4.3.2 Unlinked balise groups shall consist at minimum of two balises.

3.4.4.3.3 Unlinked balise groups shall always contain the unlinked balise group qualifier.

**3.4.4.4 Rules applicable to balise groups when linking consistency is checked**

3.4.4.4.1 "Expected balise group" shall be interpreted as an announced balise group whose expectation window is currently supervised by the on-board.

3.4.4.4.2 When the expected balise group is referred in the linking information with a balise group with ID not set to “unknown”, the ERTMS/ETCS on-board equipment shall reject the

<!-- end of page 16 -->

message from any balise group marked as linked and not included in the linking information.

3.4.4.4.2.1 When the expected balise group is referred in the linking information with a balise group with ID “unknown”, the ERTMS/ETCS on-board equipment shall reject the message from any balise group marked as linked unless:

   - a) the on-board equipment can determine the orientation of the linked balise group by information from the balise group itself (therefore excluding for example single balise groups), AND

   - b) the balise group contains repositioning information valid for the train orientation, AND

   - c) the balise group is crossed with the direction announced in the linking information.

3.4.4.4.2.2 Balise groups marked as unlinked shall be taken into account.

3.4.4.4.3 For each balise group marked as linked and included in the linking information, the ERTMS/ETCS on-board equipment shall check whether the balise giving the location reference of the group was detected (see SUBSET-036 sections 4.2.4.1 and 4.2.4.2) within its expectation window starting

   - when the max safe antenna position has passed the first possible location of the balise group

and ending

   - when the min safe antenna position has passed the last possible location of the balise group

3.4.4.4.3.1 The first possible location and the last possible location of the balise group are defined by the linking distance and the location accuracy of the expected balise group.

3.4.4.4.3.2 The ERTMS/ETCS on-board equipment shall reject the message from a balise group whose location reference is detected outside its expectation window or whose location reference is received while its expectation window is no longer supervised.

3.4.4.4.4 In case of a balise group containing repositioning information, the first possible location shall be the reference location of the previously linked balise group.

3.4.4.4.5 The on-board equipment shall supervise only one expectation window at a time according to the order given by linking information and starting with the first announced balise group in advance of the train.

3.4.4.4.5.1 Upon reception of new linking information and after the replacement of previously stored linking information (if any), the first announced balise group in advance of the train shall be determined by the on-board equipment as the first one in the resulting linking information stored on-board, whose end of expectation window has not yet been reached.

3.4.4.4.6 The ERTMS/ETCS on-board equipment shall stop supervising the expectation window of a balise group and shall start supervising the expectation window of the next one announced in the linking information (if any) when one of the following events occurs:

<!-- end of page 17 -->

   - a) the location reference of the group is detected (see SUBSET-036 sections 4.2.4.1 and 4.2.4.2) inside its expectation window

   - b) a linking consistency error is found, see 3.16.2.3.1

   - c) a balise group message consistency error is found, see 3.16.2.4.1

3.4.4.4.6.1 Linking consistency error due to early reception of balise group expected later (see 3.16.2.3.1 c)): if the location reference received is the one of the next balise group announced in the linking information, the ERTMS/ETCS on-board equipment shall check its linking consistency and apply again clause 3.4.4.4.6, i.e. it will immediately expect the further next balise group announced in the linking information.

3.4.4.4.6.2 Note: 3.4.4.4.6 a) implies that in case a balise group composed of more than one balise is crossed in nominal direction there will be other balise telegram(s) from this group still to be received once its expectation window is no longer supervised. Conversely, in case a balise group composed of more than one balise is crossed in reverse direction, the telegram(s) of the first balise(s) of this group might be received before its expectation window starts to be supervised.

3.4.4.4.7 In case the expected balise group is referred in the linking information with a balise group with ID not set to “unknown”, the ERTMS/ETCS on-board equipment shall reject the message from this group and trip the train if the balise group is passed in the unexpected direction.

**3.4.4.5 Rules applicable to balise groups when linking consistency is not checked**

3.4.4.5.1 All balise groups shall be taken into account.

### **3.4.5 Euroloop (level 1 only)**

**3.4.5.1 End Of Loop Marker (Euroloop announcement)**

3.4.5.1.1 The End Of Loop Marker (EOLM) information is transmitted only by balise groups.

3.4.5.1.2 The balise group transmitting the EOLM information marks the beginning of a track area where loop messages can be received. In bidirectional applications, it is possible to have an EOLM at both sides of a loop.

3.4.5.1.3 The following information is included in the EOLM:

   - Loop identity used to identify the loop.

   - Key to select the spread spectrum key necessary to receive the loop messages.

   - Distance to the loop giving the distance from the EOLM to the location from where the loop is installed.

   - Length of the loop.

   - Indicator telling the on-board whether the orientation of the loop (i.e. its nominal direction) is identical or opposite to the balise group orientation including the EOLM information.

<!-- end of page 18 -->

3.4.5.1.4 The ERTMS/ETCS on-board equipment shall manage only one EOLM information at a time, therefore a new EOLM shall replace a previously stored one.

3.4.5.1.5 The loop area is defined as the track area from the reference location of the balise group from which the EOLM information has been received to the location determined by the distance to the loop plus the length of the loop.

3.4.5.1.6 After the min safe loop antenna position (calculated by subtracting the distance between the active Euroloop antenna and the front end of the train from the min safe front end position) has passed the start of the loop area, the ERTMS/ETCS on-board equipment shall delete the EOLM information as soon as the loop antenna position is outside the loop area, taking into account the min safe antenna position in case of movement in the direction of train orientation and the max safe antenna position in case of movement opposite to train orientation.

**3.4.5.2 Rules related to Euroloop**

3.4.5.2.1 The ERTMS/ETCS on-board equipment shall only accept information coming from a Euroloop if the loop identity referred in the loop message matches the loop identity referred in the EOLM information stored on-board.

3.4.5.2.2 The ERTMS/ETCS on-board equipment shall start accepting messages from the Euroloop as soon as its corresponding EOLM information is received.

3.4.5.2.3 The Euroloop information can be of the following type: a) Non-infill.

b) Infill.
