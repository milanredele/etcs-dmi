## **3.6 Location Principles, Train Position and Train Orientation**

### **3.6.1 General**

3.6.1.1 Two types of location based information are defined:

   - a) Information that refers only to a given location, referred to as Location data (e.g. level transition orders, linking)

   - b) Information that remains valid for a certain distance, referred to as Profile data (e.g. SSP, gradient).

<!-- end of page 31 -->

3.6.1.2 Note: Determination of the Train Position is always longitudinal along the route, even though the route might be set through a complex track layout.

<!-- Start of picture text -->
1       2     3<br>4         5      6<br>7<br>Figure 6: Actual route of the train<br>1 5 7<br><!-- End of picture text -->

**Figure 7: Route known by the train**

3.6.1.3 The Train Position information defines the position of the train front in relation to a reference balise group, which is called LRBG (the Last Relevant Balise Group) in case the balise group is marked as linked and may be used for reporting the train position to the RBC (i.e. the balise group is LRBG compliant, see 3.6.2.2.2 a)), and/or in relation to other reference balise groups, which are called ORBGs (Other Reference Balise Groups).

It includes for each of the reference balise groups (LRBG/ORBGs):

- The estimated train front end position, defined by the estimated distance between the LRBG/ORBG and the front end of the train

- The train position confidence interval (see 3.6.4.1)

- Directional train position information in reference to the balise group orientation (see 3.4.2, also Figure 14) of the LRBG/ORBG, regarding:

   - the position of the train front end (nominal or reverse side of the LRBG/ORBG)

      - the train orientation

      - the train running direction

The ORBGs are at least the seven previous LRBGs last reported to the RBC, which may alternatively be used by trackside for referencing location dependent information (see 3.6.2.2.2 c)), the balise groups used as reference by information stored in any of the transition buffers (see section 4.8), and either the last passed balise group marked as unlinked or the last two passed balise groups marked as unlinked if there is no balise group marked as linked in between.

3.6.1.3.1 Note: the train position information in relation to an ORBG is necessary to relocate all location based information to the Single On-board Location Reference (SOLR), in case no linking distance can be used (see section 3.6.4.2).

<!-- end of page 32 -->

3.6.1.3.2 The status of the Train Position information (see 3.6.1.3) is defined as unknown in case neither a train position in relation to an LRBG nor in relation to an ORBG is stored onboard.

3.6.1.3.3 Note: After the ERTMS/ETCS on-board equipment has been powered-off, a stored train position remains in status “invalid” until it is either revalidated (status becomes “valid”) or deleted (status becomes “unknown”).

3.6.1.3.4 The front end of the train refers to the front end of the engine with regards to the train orientation. Exception: In Stand-By mode while no valid Train Data is available but the safe consist length information is available, in Supervised Manoeuvre requests, and from the time the first Supervised Manoeuvre authorisation is received to the time the mission is either ended or continued in Non Leading mode, the estimated front end of the train takes into account the nominal consist length in front of/in rear of the engine depending on whether the train orientation is the same as/opposite to the active cab.

3.6.1.4 When the train position is unknown or invalid, the ERTMS/ETCS on-board equipment shall consider that a valid train position is stored on-board as soon as an LRBG or an ORBG has been passed and any previously stored invalid train position shall be deleted.

3.6.1.4.1 Intentionally deleted.

3.6.1.5 If there is an active cab, this one defines the orientation of the train, i.e. the side of the active cab shall be considered as determining the front of the train. If no cab is active, the train orientation shall be defined by the last active cab.

3.6.1.5.1 Exception: from the time the first Supervised Manoeuvre authorisation is received to the time the mission is either ended or continued in Non Leading mode, the train orientation shall be determined by the direction of the Movement Authority in the last received Supervised Manoeuvre authorisation, regardless of the position of the engine in the shunting consist and of which of its cab(s) is active.

3.6.1.5.2 Note: The train orientation cannot be affected by the direction controller position.

3.6.1.6 The estimated front end shall be used when supervising location based information, unless stated otherwise.

3.6.1.7 The min safe rear end position shall be calculated by subtracting from the min safe front end position, the train length stored as valid Train Data or if no valid Train Data is available but the safe consist length information is available:

   - the min safe consist length in front of the engine and the max safe consist length in rear of the engine, if the train orientation is the same as the active cab, or

   - the min safe consist length in rear of the engine and the max safe consist length in front of the engine, if the train orientation is opposite to the active cab.

<!-- end of page 33 -->

### **3.6.2 Location reference of Data Transmitted to the On-Board Equipment**

**3.6.2.1 Data Transmitted by Balises**

3.6.2.1.1 All location and profile data transmitted by a balise shall refer to the location reference and orientation of the balise group to which the balise belongs.

3.6.2.1.2 Exception: Regarding infill information the section 3.6.2.3.1 shall apply.

**3.6.2.2 Data Transmitted by Radio from RBC**

3.6.2.2.1 All location and profile data transmitted from the RBC shall refer to the location reference and orientation of the LRBG given in the same message.

3.6.2.2.2 For the LRBG the following requirements have to be met:

   - a) The on-board equipment shall use as a reference for reporting the train position to the RBC the last passed LRBG compliant balise group that fulfils the conditions of the clause 3.6.5.1.8.

This balise group is termed as LRBGONB in the following.

Only

- balise groups marked as linked and contained in the previously received linking information, if linking consistency is checked on-board

or

- balise groups not marked as unlinked, if linking consistency was not checked when such a balise group was passed

shall be regarded as LRBG compliant balise groups.

   - b) The RBC shall use a balise group which was reported by the on-board equipment as a reference (in the following termed as LRBGRBC). At a certain moment LRBGRBC and LRBGONB can be different.

   - c) The on-board equipment shall be able to accept information referring to one of at least eight LRBGONB last reported to the RBC.

3.6.2.2.2.1 Exception to a): When the train position is unknown, or when position data has been deleted during SoM procedure, or when the train position is valid or invalid but only referred to a balise group marked as unlinked, the on-board equipment shall use an LRBG identifier set to "unknown" until the onboard has passed an LRBG compliant balise group that fulfils the conditions of the clause 3.6.5.1.8.

3.6.2.2.2.2 Exception to b): When the RBC has received from the onboard an unknown position (as per 3.6.2.2.2.1) or during SoM procedure an invalid position which it is not able to confirm, the RBC shall use an LRBG identifier set to "unknown" until it receives a position report from the onboard having passed an LRBG compliant balise group that fulfils the conditions of the clause 3.6.5.1.8.

<!-- end of page 34 -->

3.6.2.2.2.3 Regarding c): From the time it has reported an unknown position, or an invalid position during SoM procedure, to the time it has received from the RBC a message with an LRBG not set to “unknown”, the on-board equipment shall also be able to accept messages from the RBC containing LRBG “unknown”.

3.6.2.2.3 Example: The following figure illustrates the on-board and RBC views of LRBGs:

<!-- Start of picture text -->
Train<br>A B C D E F Onboard<br>view<br>LRBGONB<br>currently<br>reported<br>to RBC<br>A B C D E F RBC<br>LRBGRBC LRBGRBC view<br>last used currently used<br>RBC reference RBC reference Legend:<br>Position Report<br>LRBG<br>Balise group not<br>considered as LRBG<br><!-- End of picture text -->

_Balise groups A, C_ have been reported to the RBC and can be used by the RBC as LRBG _Balise groups D - F_ : are known thanks to previously received linking information and can be used in the future as onboard reference

#### **Figure 8: On-board and RBC views of LRBG when train is reporting new LRBGONB "D"**

3.6.2.2.3.1 Note: Figure 8 illustrates the case where the RBC uses as reference the last received LRBGONB. The RBC could also use a previously received one (see 3.6.2.2.2 b)).

#### **3.6.2.3 Data transmitted as Infill information**

3.6.2.3.1 All location and profile data transmitted as infill information shall refer to the location reference of the balise group at the next main signal (identified by the infill information) and to the orientation given by the infill device. (See note after justification).

3.6.2.3.1.1 Justification:

   - At locations where routes join: Infill information is the same for all routes, only linking information is different for different routes, see figure below (infill by means of balise group(s), loop or radio)

<!-- end of page 35 -->

<!-- Start of picture text -->
Balise groups<br>providing<br>linking information<br><!-- End of picture text -->

<!-- Start of picture text -->
Main<br>Infill area<br>Signal<br>Balise group<br>at<br>Main Signal<br><!-- End of picture text -->

#### **Figure 9: Routes Join in Rear of InFill Area**

- In case of an infill area with multiple balise groups: all balise groups transmit identical information, as the information of all groups refers to the balise group at the main signal.

<!-- Start of picture text -->
Linking Information<br>Balise group<br>Location<br>at<br>reference<br>Main Signal<br>Balise group<br>providing<br>linking information<br>Balise Groups transmitting<br>Infill Information<br><!-- End of picture text -->

**Figure 10: Location referencing of infill information transmitted by balise groups**

3.6.2.3.1.2 Note: The orientation of infill information given by an infill device is defined in reference to (see also section 3.9):

   - In case of a balise group, the orientation of the balise group sending the infill information

   - In case of loop, the orientation indicated by the End Of Loop Marker

   - In case of radio, the orientation of the LRBG indicated in the message

#### **3.6.2.4 Intentionally deleted**

### **3.6.3 Validity direction of transmitted information**

#### **3.6.3.1 General**

3.6.3.1.1 The direction for which transmitted information is valid shall refer to:

<!-- end of page 36 -->

   - a) the LRBG orientation for information sent by radio

   - b) the balise group orientation for information sent by this balise group

   - c) the loop orientation (which refers itself to the orientation of the balise group transmitting the EOLM information, see 3.4.5.1.3) for information sent by this loop

3.6.3.1.2 Data transmitted to the on-board equipment shall be identified as being valid for a) both directions

   - b) the nominal direction

   - c) the reverse direction

of the referenced balise group (for information sent by balise or radio) or of the loop (for information sent by loop).

3.6.3.1.2.1 Deleted.

3.6.3.1.3 When receiving information from any transmission medium, the ERTMS/ETCS on-board equipment shall only take into account information valid for the train orientation. Other information shall be ignored.

3.6.3.1.3.1 Exception 1: for SL, PS and SH engines, balise group crossing direction shall be considered.

3.6.3.1.3.2 Exception 2: information in a Supervised Manoeuvre authorisation shall be taken into account also when its validity direction is opposite to that of the current train orientation

3.6.3.1.4 If the train orientation cannot be referred to a direction of the trackside device to which the transmitted information refers (or for SL, PS and SH engines if the balise group crossing direction is unknown), data received from any transmission medium valid for one direction only (nominal or reverse) shall be rejected by the onboard equipment. Data valid for both directions shall be evaluated (see section 4.8).

3.6.3.1.4.1 Exception: if not rejected due to balise group message consistency check (see 3.16.2.4.4.1 and 3.16.2.5.1.1), data to be forwarded to a National System (see section 3.15.6) valid for one direction only shall be accepted. Justification: the co-ordinate system of the balise group might be known to the National System by other means inherent to the National System itself.

3.6.3.1.4.2 Note: the clause 3.6.3.1.4 applies for example if no co-ordinate system has been assigned to a single balise group.

#### **Figure 11: Intentionally deleted**

**3.6.3.2 Location, Continuous Profile Data and Non-continuous Profile Data**

3.6.3.2.1 Location and profile data shall have the structure shown in Figure 12 below

<!-- end of page 37 -->

<!-- Start of picture text -->
Direction  with<br>regard to location<br>continuous    value(1)   value(2)<br>profile and<br>location<br>data<br> distance (1)   distance (2)<br>LRBG/ORBG<br> value(1)   value(2)<br>non continuous   length (1)   length (2)<br>profile data<br> distance (1)   distance (2)<br>LRBG/ORBG<br><!-- End of picture text -->

#### **Figure 12: General Structure of location and profile data**

3.6.3.2.2 With regard to Figure 12 the following applies to continuous profile data:

   - a) Value (n) shall be valid for distance (n+1)

   - b) For distance (1) the previously received data shall be used (in case of an SSP this includes train length delay, refer to 3.11.3.1.3).

   - c) Distances shall be given as unsigned incremental values representing the distance between value(n) and value(n-1).

   - d) The last value (n) transmitted shall be valid for an unlimited distance unless value(n) represents a special "end of profile" value.

   - e) If distance (n+1) = 0 then the corresponding profile value n shall still be taken into account.

3.6.3.2.3 With regard to Figure 12 the following shall apply to location data:

   - a) Distances shall be given as unsigned incremental values representing the distance between value(n) and value(n-1).

<!-- end of page 38 -->

   - b) For distance (1) the previously received data shall be used.

   - c) Each value (n) may represent a single value or a set of data.

3.6.3.2.4 According to Figure 12 the structure for non-continuous profile data shall allow to contain multiple elements (value(n) for length(n)) inside the profile.

   - a) Distance to the start of each element (value(n) for length(n)) shall be given as unsigned incremental values, each increment representing the distance between starts of element (n) and element (n-1).

   - b) For distance (1) the previously received data (or initial data/default values, see section 3.7) shall be used.

   - c) Each value (n) may represent a single value or a set of data.

   - d) Note: There is no relationship between length of element (n-1) and distance (n), i.e., elements may overlap.

3.6.3.2.5 It shall be possible for the RBC to shift the location reference, e.g., after a change of train orientation or running direction.

3.6.3.2.5.1 Justification: Refer to Figure 13. To make it possible to shift the location reference if – due to the location of the LRBG and the start location – distance (1) would become a negative value.

<!-- Start of picture text -->
direction  with regard<br>to location reference<br>value(1) value(2)<br>distance (1) distance (2)<br>LRBG<br>Distance to the new location<br>reference<br>Shifted<br>location<br>reference<br><!-- End of picture text -->

#### **Figure 13: Shifted Location Reference (shown for continuous data /location profile, but also valid for non continuous data profile).**

3.6.3.2.6 With regards to Figure 12 the following applies to linking information

<!-- end of page 39 -->

- a) The distance (1) shall be given to the first balise group included in the linking information

- b) The distance (n) shall be given as the distance between two consecutive balise groups

- c) Each value (n) shall represent the linking information related to that balise group.

### **3.6.4 Train Position Confidence Interval and Relocation**

**3.6.4.1 Train Position Confidence Interval**

3.6.4.1.1 The confidence interval to the train position refers to the distance to the reference balise group and takes into account

   - a) On-board over-reading amount and under-reading amount, which include among other things the odometer accuracy and the error in detection of the balise group location reference.

   - b) The location accuracy of the reference balise group.

3.6.4.1.2 Note: The confidence interval increases in relation to the distance travelled from the reference balise group depending on the accuracy of odometer equipment.

3.6.4.1.3 The value of the Location Accuracy shall be determined by Linking information when it becomes available, or, if it has not been previously determined by Linking information when the balise group becomes LRBG or ORBG, by the corresponding National Value or the corresponding Default Value if the National Value is not applicable.

3.6.4.1.4 Once the location accuracy of a balise group has been determined according to the clause 3.6.4.1.3, it shall not be updated (e.g. neither upon reception of further Linking information, nor when linking is no longer checked, nor when new National Values becomes applicable).

3.6.4.1.5 The confidence interval to the train front end position shall be delimited by:

   - a) The min(imum) safe front end position, which is in rear (in relation to the orientation of the train) of the estimated train front end position at a distance calculated as follows:

      - 𝐿𝑑𝑜𝑢𝑏𝑡𝑜𝑣𝑒𝑟 = 𝑄𝑙𝑜𝑐𝑎𝑐𝑐−𝑟𝑒𝑓𝐵𝐺 + overreading amount + 𝛾 ⋅ 𝐿𝑡𝑟𝑎𝑖𝑛𝑜𝑣𝑒𝑟

   - b) The max(imum) safe front end position, which is in advance (in relation to the orientation of the train) of the estimated train front end position at a distance calculated as follows:

      - 𝐿𝑑𝑜𝑢𝑏𝑡𝑢𝑛𝑑𝑒𝑟 = 𝑄𝑙𝑜𝑐𝑎𝑐𝑐−𝑟𝑒𝑓𝐵𝐺 + underreading amount + 𝛾 ⋅ 𝐿𝑡𝑟𝑎𝑖𝑛𝑢𝑛𝑑𝑒𝑟

With 𝛾= 1 only in Stand-By mode while no valid Train Data is available but the safe consist length information is available, in Supervised Manoeuvre requests, and from the time the first Supervised Manoeuvre authorisation is received to the time the mission is either ended or continued in Non Leading mode, and with 𝐿𝑡𝑟𝑎𝑖𝑛𝑜𝑣𝑒𝑟 & 𝐿𝑡𝑟𝑎𝑖𝑛𝑢𝑛𝑑𝑒𝑟 determined as follows:

<!-- end of page 40 -->

- 𝐿𝑡𝑟𝑎𝑖𝑛𝑢𝑛𝑑𝑒𝑟 is the difference between the Train Data max safe consist length and nominal consist length in front of/in rear of the engine, depending on whether the train orientation is the same as/opposite to the active cab respectively.

- 𝐿𝑡𝑟𝑎𝑖𝑛𝑜𝑣𝑒𝑟 is the difference between the Train Data nominal consist length and min safe consist length in front of/in rear of the engine, depending on whether the train orientation is the same as/opposite to the active cab respectively.

Otherwise 𝛾= 0

<!-- Start of picture text -->
LRBG 1  Estimated front end<br>Q_LOCACC(1)  Q_LOCACC(1)<br>measured distance<br>location  over-reading  under-reading<br>reference of  Q_LOCACC(1)  amount  amount  Q_LOCACC(1)<br>the LRBG<br>as detected<br>by on-board  L_DOUBTOVER  L_DOUBTUNDER<br>Confidence interval<br>min safe front end  max safe front end<br><!-- End of picture text -->

#### **Figure 13a: Train confidence interval and train front end position in reference to LRBG**

#### **3.6.4.2 Relocation**

3.6.4.2.1 The relocation consists in changing the reference location of all location based information handled by the ERTMS/ETCS on-board equipment, so that as soon it is used and at any further time it is referred to the Single On-board Location Reference (SOLR).

3.6.4.2.2 The Single On-board Location Reference (SOLR) shall be:

   - a) the last received balise group that is the reference of linking information or that is announced in linking information (including if it is announced with a balise group with ID “unknown” and it contains repositioning information), while the linking consistency is checked (see 3.4.4.2.1.1), or

   - b) the last received balise group, while no linking consistency is checked.

3.6.4.2.2.1 Exception to 3.6.4.2.2 b): when exiting No Power mode, the SOLR shall be set to the stored LRBG if any.

3.6.4.2.2.2 Whenever linking information is received (e.g. when it is released from the transition buffer), the clause 3.7.3.1 m) shall be applied before this clause 3.6.4.2.2. For all other information, any relocation to the SOLR resulting from this clause 3.6.4.2.2 shall take place before the corresponding item of the clause 3.7.3.1 is applied.

<!-- end of page 41 -->

3.6.4.2.2.3 Note: the SOLR is generally equal to the LRBGONB. For some cases however, like the transition to level 1/2 area, it might be possible that the linking information released from the transition buffer provokes the change of SOLR to a former LRBG in case this information does not announce every balise group in rear of the border (see Figure 13e).

3.6.4.2.3 Before it can be relocated, all location based information received from trackside shall be first processed by the on-board equipment into a series of individual location items each of them being referred to an individual distance to the reference balise group of the location based information, this distance being counted positive/negative depending on whether the location item is in advance of/in rear of the reference balise group with regards to the train orientation.

3.6.4.2.4 For a given location based information (e.g. EOA), up to three individual location items can be defined, as stipulated in Table 2a. Whenever a (or a part of a) clause of the ETCS specifications is mentioned in this Table 2a, it shall be applied by the ERTMS/ETCS onboard equipment using the corresponding types of location item.

|**Information**|**Location**|**"min" location item**|**"estimated"**<br>**location item**|**"max" location item**|
|---|---|---|---|---|
|National Values|start of validity||3.18.2.3||
|Linking|balise group(s) first<br>possible location|||3.4.4.4.3 1<sup>st</sup>bullet<br>together with 3.4.4.4.3.1|
||balise group(s) last<br>possible location|3.4.4.4.3 2<sup>nd</sup>bullet<br>together with 3.4.4.4.3.1|||
|Movement Authority|section ends|3.8.5.1 b) (MA partially<br>replaced)|3.8.5.2.2 (determination<br>of the current section)|3.8.4.2.2 a) (SvL<br>withdrawal)|
|||3.8.4.2.2 a) & c)<br>(EOA/LOA withdrawal)<br>Other clauses in row<br>EOA|3.8.4.2.2 a) & c)<br>(EOA/LOA withdrawal)<br>Other clauses in row<br>EOA|Other clauses in row EBD<br>based target|
||section timer stop<br>locations|3.8.4.2.3<br>3.8.4.2.4<br>3.8.4.2.5|||
||End Section timer start|||3.8.4.1.1<br>3.8.4.1.3<br>3.8.4.1.4|
||Overlap timer start|||3.8.4.4.1<br>3.8.4.4.4|
|||||3.8.4.4.5|
||End of MA as EOA|3.8.4.3.2, 3.8.4.4.2 c)<br>(LOA becomes EOA)<br>Other clauses in row<br>EOA|3.8.4.3.2, 3.8.4.4.2 c)<br>(LOA becomes EOA)<br>Other clauses in row<br>EOA||
|||3.10.2.2 b) 1<sup>st</sup>& 2<sup>nd</sup><br>bullets (comparison vs.<br>CES stop loc.)|||

<!-- end of page 42 -->

|**Information**|**Location**|**"min" location item**|**"estimated"**<br>**location item**|**"max" location item**|
|---|---|---|---|---|
||End of MA as LOA|3.10.2.2 b) 1<sup>st</sup>& 4<sup>th</sup><br>bullets (comparison vs.<br>CES stop loc.)<br>3.12.4.7 b) & c)<br>(comparison vs. Mode<br>Profile area start)||See clauses in row EBD<br>based target|
|||3.13.10.2.6 a)<br>3.13.10.2.7<br>4.4.19.1.4 a)<br>4.6.3 [12], [16] & [43]<br>SUBSET-041 § 5.2.1.9<br>SUBSET-041 § 5.2.1.13|||
||End of MA as SvL|||3.8.4.5.1 c)<br>Other clauses in row EBD<br>based target|
|||||3.10.2.2 b) 2<sup>nd</sup>& 3<sup>rd</sup><br>bullet (comparison vs.<br>CES stop loc.)|
||Danger Point as SvL|||3.8.4.5.1 b)<br>Other clauses in row EBD<br>based target|
||End of overlap as SvL|||3.8.4.5.1 a)<br>Other clauses in row EBD<br>based target|
|Signalling related speed<br>restriction from an infill device|start|Justification: The signallin<br>accepted if the infill refer<br>SOLR at that time is als<br>announced by linking p<br>consequence, the start loc<br>relocated through linking<br>"min", "max" or "estimate|Not relevant<br>g speed restriction receive<br>ence is known by linking<br>o part of linking, becaus<br>rovokes a change of S<br>ation of this infill signalling<br>distance as per 3.6.4.2.5a,<br>d" location item has no infl|d by infill MA can only be<br>with known ID. Moreover,<br>e the existence of BG(s)<br>OLR by 3.6.4.2.2a. As a<br>speed restriction is always<br>so that its classification as<br>uence.|
|Mode Profile|acknowledgement area<br>start(s)||5.7.3.2 a)<br>5.9.3.2 a)<br>5.19.3.2 a)<br>4.6.3 [73], [74], [75] &<br>[76], 4.8.4 [10] (sub-<br>condition “The<br>estimated front end of<br>the train is not inside an<br>OS/LS acknowledgement<br>area”)||

<!-- end of page 43 -->

|**Information**|**Location**|**"min" location item**|**"estimated"**<br>**location item**|**"max" location item**|
|---|---|---|---|---|
||area start(s)|3.12.4.7 (Temporary<br>EOA)<br>Other clauses in row<br>EOA|3.12.4.7 (Temporary<br>EOA)<br>Other clauses in row<br>EOA|4.6.3 [10], [25], [31],<br>[32], [34], [40], [71],<br>[72], [73], [74], [75] &<br>[76], 4.8.4 [9] & [10]<br>(Check of train position<br>confidence interval vs.<br>MP area)|
|||||4.6.3 [51], [61]<br>5.7.3.6<br>5.7.4.1<br>5.9.2.2|
|||||5.9.3.7<br>5.9.5.1<br>5.19.2.2|
|||||5.19.3.7<br>5.19.5.1|
||||4.6.3 [73], [74], [75] &<br>[76] (sub-condition “The<br>estimated front end of|3.12.4.3.1 b) & c)|
||||the train is not inside an<br>OS/LS acknowledgement<br>area”)|3.12.4.7 a) (temporary<br>SvL)<br>3.12.4.7 b) (comparison<br>with LOA location)<br>3.12.4.7 c) (temporary<br>SvL and comparison with<br>LOA location)|
|||||3.13.7.2 together with<br>3.11.2.2 f) (start of<br>speed element for<br>MRSP)<br>Other clauses in row EBD<br>based target|
|||||A.3.4.1.3 [7]<br>A.3.4.1.3 [12]|
||area end(s) (**)|4.6.3 [10], [25], [31],<br>[32], [34], [40], [71],<br>[72], [73], [74], [75] &<br>[76], 4.8.4 [9] & [10]<br>(Check of train position<br>confidence interval vs.<br>MP area)|||
|||5.9.2.2<br>5.9.5.1<br>5.9.6.1.1<br>5.19.2.2|||
|||5.19.5.1<br>5.19.6.1.1|||

<!-- end of page 44 -->

|**Information**|**Location**|**"min" location item**|**"estimated"**<br>**location item**|**"max" location item**|
|---|---|---|---|---|
|||3.13.7.2 together with<br>3.11.2.2 f) & 3.13.2.3.2.1<br>(end of speed element<br>for MRSP)<br>3.15.10.2<br>A.3.4.1.3 [14]|||
|Gradient Profile|profile start (***)|3.7.3.1.2 together with<br>3.7.3.1 b) (replacing<br>profile: end of the<br>overlap distance<br>between replaced profile<br>and replacing profile)|3.7.2.3 together with<br>3.7.2.3.1 & 3.7.2.3.2<br>(comparison vs. train<br>front to determine full<br>coverage of the MA)<br>4.6.3 [69]|3.7.3.1.2 together with<br>3.7.3.1 b) (replacing<br>profile: start of the<br>overlap distance<br>between replaced profile<br>and replacing profile)|
||Change(s) to lower value||3.13.4.2.1 (A_gradient(d)<br>for 3.13.6.3.1.3 &<br>3.13.6.4.3)<br>3.13.6.4.3 (grad(d))<br>3.15.10.3|3.13.4.2.1 (A_gradient(d)<br>for 3.13.6.2.1.3)|
||Change(s) to higher<br>value|3.13.4.2.1 (A_gradient(d)<br>for 3.13.6.2.1.3)|3.13.4.2.1 (A_gradient(d)<br>for 3.13.6.3.1.3 &<br>3.13.6.4.3)<br>3.13.6.4.3 (grad(d))<br>3.15.10.3||
||profile end (*)|3.7.3.1 b) (profile<br>partially replaced)||3.7.2.3 together with<br>3.7.2.3.1 & 3.7.2.3.2<br>(comparison vs. SvL to<br>determine full coverage<br>of the MA)|
|International SSP|profile start (***)|3.7.3.1.1 together with<br>3.7.3.1<br>a)<br>(replacing<br>profile:<br>end<br>of<br>the<br>overlap<br>distance<br>between replaced profile<br>and replacing profile)|3.7.2.3 together with<br>3.7.2.3.1 & 3.7.2.3.2<br>(comparison vs. train<br>front to determine full<br>coverage of the MA)|3.7.3.1.1 together with<br>3.7.3.1<br>a)<br>(replacing<br>profile:<br>start<br>of<br>the<br>overlap<br>distance<br>between replaced profile<br>and replacing profile)|
|||3.13.7.2 together with<br>3.11.2.2 a) & 3.13.2.3.2.1<br>(replacing profile:<br>start/end of SSP element<br>for MRSP if, at this<br>location, the speed of<br>the element of the<br>replacing profile, taking<br>into account the possible<br>relocation of change(s)|4.6.3 [69]|3.13.7.2 together with<br>3.11.2.2 a) & 3.13.2.3.2.1<br>(replacing profile:<br>start/end of SSP element<br>for MRSP, if the speed of<br>the 1<sup>st</sup>element of the<br>replacing profile is lower<br>than the speed of the<br>element of the replaced<br>profile at this location)|

<!-- end of page 45 -->

|**Information**|**Location**|**"min" location item**|**"estimated"**<br>**location item**|**"max" location item**|
|---|---|---|---|---|
|||to lower value in rear of<br>this location, is higher<br>than the speed of the<br>element of the replaced<br>profile)||No profile previously<br>stored on-board or<br>replaced profile:<br>3.13.7.2 together with<br>3.11.2.2 a) & 3.13.2.3.2.1<br>(start of 1<sup>st</sup>SSP element<br>for MRSP)|
||Change(s) to lower value|||3.13.7.2 together with<br>3.11.2.2 a) & 3.13.2.3.2.1<br>(start/end of SSP<br>element for MRSP)<br>Other clauses in row EBD<br>based target|
||Change(s) to higher<br>value|3.13.7.2 together with<br>3.11.2.2 a) & 3.13.2.3.2.1<br>(start/end of SSP<br>element for MRSP)<br>3.15.10.2|||
||profile end (*)|3.7.3.1 a) (profile<br>partially replaced)<br>3.13.7.2 together with<br>3.11.2.2 a) & 3.13.2.3.2.1<br>(end of last SSP element<br>for MRSP)<br>3.15.10.2||3.7.2.3 together with<br>3.7.2.3.1 & 3.7.2.3.2<br>(comparison vs. SvL to<br>determine full coverage<br>of the MA)|
|Axle load speed profile|resume initial state|3.7.3.2 b)|||
||1<sup>st</sup>area start|3.7.3.1.3 together with<br>3.7.3.1 c) (replacing<br>profile: end of the<br>overlap distance<br>between replaced profile<br>and replacing profile)||3.7.3.1.3 together with<br>3.7.3.1 c) (replacing<br>profile: start of the<br>overlap distance<br>between replaced profile<br>and replacing profile)|
||area start(s) (***)|||3.13.7.2 together with<br>3.11.2.2 b) &<br>3.13.2.3.2.1 (start of<br>speed element for<br>MRSP)<br>Other clauses in row EBD<br>based target|
||area end(s) (*)|3.13.7.2 together with<br>3.11.2.2 b) &<br>3.13.2.3.2.1 (end of<br>speed element for<br>MRSP)<br>3.15.10.2|||
|Level Transition Order|acknowledgement area<br>start|||5.10.4.1 a)|

<!-- end of page 46 -->

|**Information**|**Location**|**"min" location item**|**"estimated"**<br>**location item**|**"max" location item**|
|---|---|---|---|---|
||border|3.13.7.2 together with<br>3.11.2.2 h) &<br>3.13.2.3.2.1 (end of<br>speed element for<br>MRSP)<br>3.15.10.2<br>3.5.3.8 d)<br>3.6.5.1.4 f)<br>5.10.3.3.3<br>5.10.3.3.5<br>5.10.3.6.2<br>5.10.3.6.5<br>5.10.3.10.3<br>5.10.3.10.6|5.10.1.5<br>5.10.2.9 a)<br>5.10.3.7.5|3.13.7.2 together with<br>3.11.2.2 g) & h),<br>3.13.2.3.2.1 (start of<br>speed element for<br>MRSP)<br>Other clauses in row EBD<br>based target|
|Position Report parameters|location to report with<br>min safe rear end|3.6.5.1.5 c)|||
||location to report with<br>max safe front end|||3.6.5.1.5 c)|
|SR distance information from<br>loop|distance in SR mode||4.6.3 [42]<br>5.8.4.1 h)|4.4.11.1.3.1 c)<br>Other clauses in row EBD<br>based target|
|Temporary Speed Restriction|area start (***)|||3.13.7.2 together with<br>3.11.2.2 c), 3.13.2.3.2.1<br>(start of speed element<br>for MRSP)<br>Other clauses in row EBD<br>based target|
||area end (*)|3.13.7.2 together with<br>3.11.2.2 c) & 3.13.2.3.2.1<br>(end of speed element<br>for MRSP)<br>3.15.10.2|||
|Route Suitability Data|resume initial state|3.7.3.2 d)|||
||unsuitability location(s)||3.12.2.4 (Temporary<br>EOA)<br>Other clauses in row<br>EOA|3.12.2.4 (Temporary SvL)<br>Other clauses in row EBD<br>based target|
|Adhesion Factor|slippery rail area start<br>(***)|||3.13.5.3<br>3.13.6.2.1.3|
||slippery rail area end|3.13.5.3<br>3.13.6.2.1.3|||
|Plain/Fixed Text Information|start display||3.12.3.4.2 1<sup>st</sup>bullet<br>A.3.4.1.3 [8]<br>A.3.4.1.3 [13]||
||end display||3.12.3.4.3 1<sup>st</sup>bullet||
|Geographical Position|offset from the location<br>reference||3.6.6.1 together with<br>3.6.6.10 2<sup>nd</sup>bullet<br>3.6.6.4.2||

<!-- end of page 47 -->

|**Information**|**Location**|**"min" location item**|**"estimated"**<br>**location item**|**"max" location item**|
|---|---|---|---|---|
|RBC Transition Order|border|3.5.3.8 f)<br>3.5.7.6 b)<br>3.6.5.1.4 e)<br>3.15.1.3.1 c)<br>3.15.1.3.9<br>4.6.3 [84]|3.15.1.3.7|3.5.7.6 a)<br>3.6.5.1.4 k)<br>3.11.5.14 2<sup>nd</sup>bullet<br>3.15.1.3.1 b)<br>3.15.1.3.2<br>3.15.1.3.5<br>3.15.1.3.6<br>3.17.2.8 c) & e)<br>4.6.3 [84]<br>5.15.1.4|
|Radio Infill Area information|location where to<br>connect/disconnect||3.9.3.5<br>3.9.3.10 a)||
|EOLM information|loop area start|||3.4.5.1.6 together with<br>3.4.5.1.5|
||loop area end|3.4.5.1.6 together with<br>3.4.5.1.5|||
|Track Condition…|resume initial state|3.7.3.2 c)|||
|…powerless section with|area start|5.20.2.3||3.7.3.1 g)|
|pantograph to be lowered||5.20.2.4||3.12.1.2.1<br>3.15.10.2<br>5.18.2.2<br>5.18.2.3<br>5.20.2.2<br>5.20.2.3 1<sup>st</sup>bullet|
||area end (*)|3.12.1.2.1.3<br>3.15.10.2<br>5.18.2.5<br>5.18.2.6<br>5.20.2.3 2<sup>nd</sup>bullet<br>5.20.2.4<br>5.20.2.5|||
|…powerless section with main|resume initial state|3.7.3.2 c)|||
|power switch to be switched off|area start|5.20.3.3<br>5.20.3.4||3.7.3.1 g)<br>3.12.1.2.1<br>3.15.10.2<br>5.18.3.2<br>5.18.3.3<br>5.20.3.2<br>5.20.3.3 1<sup>st</sup>bullet|
||area end (*)|3.12.1.2.1.3<br>3.15.10.2<br>5.18.3.4<br>5.18.3.5<br>5.20.3.3 2<sup>nd</sup>bullet<br>5.20.3.4<br>5.20.3.5|||
|…non stopping area|resume initial state|3.7.3.2 c)|||

<!-- end of page 48 -->

|**Information**<br>**Location**|**"min" location item**|**"estimated"**<br>**location item**|**"max" location item**|
|---|---|---|---|
|area start|||3.7.3.1 g)<br>3.12.1.2.1<br>3.15.10.2<br>5.18.4.2 a) & b)<br>5.18.4.3<br>5.18.4.4|
|area end (*)|3.12.1.2.1<br>3.15.10.2<br>5.18.4.2 b) & c)|||
|…radio hole<br>resume initial state|3.7.3.2 c)|||
|area start||3.5.3.8 g)<br>3.5.4.4<br>3.7.3.1 g)<br>3.12.1.2.1.5<br>3.15.10.2<br>3.16.3.4.1.3<br>5.18.5.2||
|area end (*)||3.5.3.4 e)<br>3.5.4.4<br>3.5.7.5 (table 2 [7])<br>3.15.10.2<br>3.16.3.4.1.3<br>5.18.5.3||
|…air tightness<br>resume initial state|3.7.3.2 c)|||
|area start|||3.7.3.1 g)<br>3.12.1.2.1<br>3.15.10.2<br>5.18.6.2<br>5.18.6.3<br>5.20.4.2<br>5.20.4.3|
||||5.20.4.4|
|area end (*)|3.12.1.2.1<br>3.15.10.2<br>5.18.6.4<br>5.18.6.5<br>5.20.4.3<br>5.20.4.4|||
||5.20.4.5|||
|…inhibition of special brake<br>resume initial state|3.7.3.2 c)|||

<!-- end of page 49 -->

|**Information**|**Location**|**"min" location item**|**"estimated"**<br>**location item**|**"max" location item**|
|---|---|---|---|---|
||area start|||3.7.3.1 g)<br>3.12.1.2.1<br>3.13.5.1<br>3.13.6.2.1.5<br>3.13.6.3.1.4<br>3.13.6.4.4<br>3.15.10.2<br>5.18.7.3<br>5.18.7.4<br>5.20.5.3<br>5.20.5.4<br>5.20.5.5|
||area end (*)|3.12.1.2.1<br>3.15.10.2<br>5.18.7.5<br>5.20.5.4<br>5.20.5.5<br>5.20.5.6|||
|…tunnel stopping area|resume initial state|3.7.3.2 c)|||
||area start||3.7.3.1 g)<br>3.12.1.2.1.4<br>5.18.8.4<br>5.18.8.5||
||area end (*)||3.12.1.2.1.4<br>5.18.8.3||
|…sound horn|resume initial state|3.7.3.2 c)|||
||area start||3.7.3.1 g)<br>3.12.1.2.1.4<br>3.15.10.2<br>5.18.9.2||
||area end (*)||3.12.1.2.1.4<br>3.15.10.2<br>5.18.9.3||
|…change of traction system|change|5.18.10.6<br>5.20.6.3<br>5.20.6.4||3.12.1.2.1<br>3.15.10.2<br>5.18.10.2<br>5.18.10.5<br>5.20.6.2<br>5.20.6.3 1<sup>st</sup>bullet|
|…change of allowed current<br>consumption|change|5.20.7.4<br>5.20.7.5||3.12.1.2.1<br>5.20.7.2<br>5.20.7.4 1<sup>st</sup>bullet|
|…station platform|resume initial state|3.7.3.2 e)|||
||area start|5.20.8.4||3.7.3.1 o)|
|||5.20.8.5||3.12.1.2.1<br>5.20.8.2<br>5.20.8.4 1<sup>st</sup>bullet|

<!-- end of page 50 -->

|**Information**|**Location**|**"min" location item**|**"estimated"**<br>**location item**|**"max" location item**|
|---|---|---|---|---|
||area end (*)|3.12.1.2.1.3<br>5.20.8.4<br>5.20.8.5<br>5.20.8.6|||
|…Big Metal Mass|area start (***)|||3.7.3.1 f)<br>3.12.1.2.1.2<br>5.22.3.1<br>5.22.5.2.1|
||area end (*)|3.12.1.2.1.2<br>5.22.3.1|||
|Conditional Emergency Stop|stop location|3.10.2.2 a)<br>3.10.2.2 b) (comparison<br>vs. train front)<br>4.8.5.7|3.10.2.2 b) 1<sup>st</sup>bullet<br>(EOA withdrawal or LOA<br>withdrawal to EOA)<br>3.10.2.2 b) 4<sup>th</sup>bullet|3.10.2.2 b) 1<sup>st</sup>bullet<br>(comparison vs.<br>EOA/LOA)<br>3.10.2.2 b) 2<sup>nd</sup>bullet|
|||3.10.2.2 b) 1<sup>st</sup>bullet<br>(EOA withdrawal or LOA<br>withdrawal to EOA)<br>3.10.2.2 b) 4<sup>th</sup>bullet<br>(LOA withdrawal to EOA)|(LOA withdrawal to EOA)<br>Other clauses in row<br>EOA|(comparison vs. EOA &<br>SvL)<br>3.10.2.2 b) 3<sup>rd</sup>bullet<br>(comparison vs. SvL)<br>3.10.2.2 b) 4<sup>th</sup>bullet|
|||Other clauses in row<br>EOA||(comparison vs. LOA)|
|||||3.10.2.2 b) 1<sup>st</sup>, 2<sup>nd</sup>bullets<br>(SvL withdrawal)<br>3.10.2.2 b) 4<sup>th</sup>bullet<br>(LOA withdrawal to SvL)<br>Other clauses in row EBD<br>based target|
|||||3.10.2.2 b) last sentence<br>(A.3.4.1.3 [1])|
|Track Ahead Free Request|area start||3.15.5.2 a)||
||area end||3.15.5.2 b)||
|Reversing Area Information|area start||3.15.4.4<br>5.13.1.3||
||area end (*)||3.15.4.4<br>5.13.1.3||
||Reference location for<br>reversing distance||3.15.4.2.1||
||end of RV distance||3.15.4.8||
|Permitted Braking Distance|resume initial state|3.7.3.2 a)|||
|Information|1<sup>st</sup>area start|3.7.3.1.4 together with<br>3.7.3.1 d) (replacing<br>profile: end of the<br>overlap distance<br>between replaced profile<br>and replacing profile)||3.7.3.1.4 together with<br>3.7.3.1 d) (replacing<br>profile: start of the<br>overlap distance<br>between replaced profile<br>and replacing profile)|

<!-- end of page 51 -->

|**Information**|**Location**|**"min" location item**|**"estimated"**<br>**location item**|**"max" location item**|
|---|---|---|---|---|
||area start (***)|||3.13.7.2 together with<br>3.11.2.2 k), 3.13.2.3.2.1<br>(start of speed element<br>for MRSP)<br>Other clauses in row EBD<br>based target|
||area end (*)|3.13.7.2 together with<br>3.11.2.2 k), 3.13.2.3.2.1<br>(end of speed element<br>for MRSP)<br>3.15.10.2|||
|Level Crossing information|stopping area start||5.16.2.1||
||area start (***)|3.12.5.8 (temporary<br>EOA)<br>Other clauses in row<br>EOA|3.12.5.8 (temporary<br>EOA)<br>Other clauses in row<br>EOA|3.12.5.8 (temporary SvL)<br>3.13.7.2 together with<br>3.11.2.2 i), 3.13.2.3.2.1<br>(start of speed element|
||||5.16.2.1|for MRSP)<br>Other clauses in row EBD<br>based target|
||area end|3.13.7.2 together with<br>3.11.2.2 i), 3.13.2.3.2.1<br>(end of speed element<br>for MRSP)<br>3.15.10.2<br>5.16.1.5|||
|Confirmed train length<br>_(computed on-board for train_<br>_integrity reporting)_|min safe rear end at the<br>time the train was last<br>known to be integer|||3.6.5.2.4<br>Table 2c [3] & [9]|
|EOA|_(corresponds to other_<br>_location items as listed_<br>_above or, for A.3.4.1.3_<br>_[11] to the estimated_<br>_train front at the time of_<br>_the MA shortening)_|3.13.9.4.8.2 (for d_EOA<br>used without 10%<br>coefficient in d_tripEOA<br>formula)<br>3.13.10.2.6 a)<br>3.13.10.2.7<br>4.6.3 [12], [16] & [43]<br>4.4.19.1.4 a)<br>5.8.4.1 c)|3.8.6.1 b)<br>3.13.8.2.1 c)<br>3.13.9.4.8.2 (for d_EOA<br>used with 10%<br>coefficient in d_tripEOA<br>formula)<br>3.15.10.2<br>3.15.10.4<br>A.3.4.1.3 [11]<br>5.16.3.2|3.13.10.2.6 b)|
|||SUBSET-040 § 4.2.4.5.3<br>SUBSET-040 § 6.2.1.1.2|SUBSET-125 §10.2.7.15||
|||SUBSET-041 § 5.2.1.9<br>SUBSET-041 § 5.2.1.13|||

<!-- end of page 52 -->

|**Information**|**Location**|**"min" location item**|**"estimated"**<br>**location item**|**"max" location item**|
|---|---|---|---|---|
|EBD based target:|_(corresponds to other_|||3.8.6.1 b)|
|SvL, LOA, start location of MRSP<br>element, maximum permitted<br>distance to run in SR|_location items as listed_<br>_above or, for A.3.4.1.3_<br>_[11] to the max safe_<br>_train front at the time of_<br>_the MA shortening)_|||3.13.8.2.1 a), b), c) & d)<br>3.13.9.4.8.2(for EBD)<br>3.13.11.7.1<br>3.13.11.7.1.1<br>3.13.11.7.1.2<br>3.15.10.2<br>3.15.10.4<br>A.3.4.1.3 [11]<br>5.16.3.2|
|||||SUBSET-125 §10.2.7.3 a)<br>& b)<br>SUBSET-125 §10.2.7.9 a)<br>& b)<br>SUBSET-125 §10.2.7.15|

(*): depending on whether A.3.4.1.3 [1] or [10] is applied, this may no longer be the area/profile end transmitted by the trackside

(**): depending on whether A.3.4.1.3 [1], [10] or [14] is applied, this may no longer be the area end transmitted by the trackside

(***): depending on whether A.3.6.2.1 is applied, this may no longer be the area/profile start transmitted by the trackside

#### **Table 2a: Correspondence between location items and clauses in the ETCS specifications using them**

3.6.4.2.4.1 Note 1: an individual location based information can be classified as several types of location items. For example, the EOA location is an "estimated" location item to define SBD foot, a "min" location item to provoke entry into Trip mode and a "max" location item if it defines the SvL. As a second example, a single TSR encompasses two location items, i.e. a "max" location item at its start location and a "min" location item at its end location. Classification of TSR location item, as true for any Speed Restriction, is indirectly deduced from the fact that V_MRSP is obtained with the min safe front end and the max safe front end of the train as per clause 3.13.10.2.8.

3.6.4.2.4.2 Note 2: in general (but not necessarily for all the functions), an “estimated”/”min”/”max” location item is used to apply a clause when this latter involves a comparison against the estimated front end position/min safe rear end position or the min safe antenna position/ max safe front end position or the max safe antenna position.

3.6.4.2.4.3 Note 3: as long as linking distance(s) can be used to perform the relocation, several items associated to a given location based information will be referred with the same distance to the SOLR by the on-board. Otherwise, these location items (e.g. “min”, “estimated” and “max” MA section ends) will be referred to the SOLR with different distances, after a relocation as per clause 3.6.4.2.5 b) or c) has taken place.

<!-- end of page 53 -->

3.6.4.2.5 When a balise group becomes the SOLR or when evaluating (see section 4.8) location based trackside information, which is referred to a balise group different from the SOLR, every location item shall be relocated to the SOLR by subtracting from the distance to its former reference balise group (FRBG):

   - a) the distance between the FRBG and the SOLR, retrieved from linking information if it is available and known (i.e. no linking distance to a repositioning balise group being encountered between these balise groups) and, if any, the last relocation of this location item has not been performed as per clause 3.6.4.2.5 c), OR

   - b) if the last relocation of this location item has been performed as per clause 3.6.4.2.5 c) towards a BG not received earlier than the reference BG of this location item, the distance between the FRBG and the SOLR retrieved from linking information if it is available and known (i.e. no linking distance to a repositioning balise group being encountered between these balise groups):

      - as such, for "estimated" location items,

      - diminished by twice the location accuracy of the FRBG, for "min" location items,

      - augmented by twice the location accuracy of the FRBG, for "max" location items, OR

   - c) in all other cases, the estimated, min or max travelled distance between the FRBG and the SOLR, computed as per clauses 3.6.1.3 and 3.6.4.1.5 from train front end positions in reference to FRBG and to SOLR, as follows:

      - (estimated front end position against FRBG – estimated front end position against SOLR) for "estimated" location items,

      - (min safe front end position against FRBG – min safe front end position against SOLR) for "min" location items,

      - (max safe front end position against FRBG – max safe front end position against SOLR) for "max" location items.

3.6.4.2.5.1 Note 1: For infill information or when evaluating information from a balise group marked as unlinked while linking consistency is checked, the distances used for relocation will always be negative and will result in an increase of the supervised distances to the location items (because they are relocated back to the SOLR).

3.6.4.2.5.2 Note 2: The FRBG can be the former SOLR, a balise group that does not become the SOLR (e.g. an unlinked balise group while linking consistency is checked), a balise group that has transmitted information that has been stored in the transition buffer, the LRBG used in an RBC message or an infill location reference.

3.6.4.2.5.3 Note 3: All reference balise groups that are used in clause 3.6.4.2.5 are listed in Train Position defined in 3.6.1.3. Furthermore, the list of the location items that was relocated as per clause 3.6.4.2.5 c) needs also to be memorised to apply this clause 3.6.4.2.5.

3.6.4.2.5.4 Note 4: By principle, the relocation from former SOLR to new SOLR done by clause 3.6.4.2.5 c) has no effect on the supervision of the location items, because the same

<!-- end of page 54 -->

change of distances within the Train Position is applied inversely to the distances of the location items.

3.6.4.2.5.5 Note 5: The supervision of distances on-board will always be safe using these rules, together with the SUBSET-040 §4.6.1.1 rule as prerequisite. If the trackside wants to increase the performance, it is its responsibility to provide linking in due course or to repeat the location based information in reference to further balise groups.

3.6.4.2.6 Regarding the continuous profiles (i.e. SSP and gradient): if a relocation as per clause 3.6.4.2.5 b) or c) results in at least one change of value being relocated in rear of one or more preceding change(s) of value, the ERTMS/ETCS on-board equipment shall recompose the continuous profile according to the following steps:

   - Step 1: For each concerned set of consecutive changes of value, the on-board shall consider the profile as if it would have been received from trackside with, by exception to 3.6.3.2.2 c), an incremental distance being negative from the furthest in advance concerned change of value to the furthest in rear concerned change of value;

   - Step 2: From the end location to the start location of each “reverted” element(s) delimited by a negative incremental distance, the ERTMS/ETCS on-board equipment shall retain the lowest parts of the overlapping elements obtained from step 1;

   - Step 3: The clause 3.6.4.2.3 shall be applied to the profile obtained from step 2, resulting in a continuous profile with all discontinuities ordered by increasing individual distances referred to the SOLR, as if this profile would have been received by trackside being compliant with 3.6.3.2.2 (i.e. with only unsigned incremental distances).

3.6.4.2.6.1 Note: the recomposed profile obtained from the clause 3.6.4.2.6 may include less elements than the profile before relocation, possibly with the original change(s) to higher value no longer present depending on the respective speed/gradient values of the concerned overlapping elements considered in steps 1 and 2.

<!-- end of page 55 -->

<!-- Start of picture text -->
Q_LOCACC(LRBG) (known from previous linking or National/Default Value)<br>LRBG 1  2  3<br>Linking  D_LINK(1)  D_LINK(2)  D_LINK(3)<br>Info  Q_LOCACC(1)  Q_LOCACC(2)  Q_LOCACC(3)<br>LRBG<br>EOA<br>distance (3)<br>distance (2)<br>distance (1)<br>Confidence Interval = Function [Q_LOCACC; Odometer Error]<br>When the ERTMS/ETCS on-board has read the balise group 1<br>• the balise group 1 becomes the LRBG/SOLR<br>• the distance to EOA is relocated by subtracting D_LINK (1) from distance (1),<br>resulting in distance (2). (distance (1) may be the distance to EOA derived from<br>the MA or the result of a previous relocation.)<br>• the train position confidence interval vs. balise group 1 (taking into account the<br>location accuracy of  balise group 1 and on-board tolerances when determining<br>the reference location of the balise group) replaces the one vs. the former LRBG,<br>for the supervision of the on-board location based items<br>When the ERTMS/ETCS on-board has read the balise group 2<br>• the distance to EOA is relocated by subtracting D_LINK(2) from distance (2),<br>resulting in distance (3).<br>• the train position confidence interval vs. balise group 2 replaces the one vs. balise<br>group 1 for the supervision of the on-board location based items<br>Interval<br>Confidence<br><!-- End of picture text -->

#### **Figure 13b:  Replacement of confidence interval and relocation with linking info, on change of LRBG/SOLR**

<!-- end of page 56 -->

<!-- Start of picture text -->
Level 0 => 2<br>transition<br>LRBG<br>0  1  2  3  4<br>D_LINK(1)  D_LINK(2)  D_LINK(3)  D_LINK(4)<br>MA Section(1) length  MA Section(2) length = End<br>Section length<br>MA Section (1’) end<br>MA Section(2’) end = End<br>Section end<br>OR  MA Section (1’’) end<br>MA Section(2’’) end = End<br>Section end<br><!-- End of picture text -->

When the on-board performs the transition to level 2, the location items of the MA stored on-board (referred to balise group 0) are relocated prior to its evaluation:

- If balise group 1 is still the LRBG/SOLR, the first MA Section end is relocated by subtracting D_LINK (1) from MA Section (1) length, to obtain the distance from the SOLR to the MA section end (1’)

- If balise group 2 is already the LRBG/SOLR, the first MA Section end is relocated by subtracting (D_LINK (1) + D_LINK (2)) from MA Section (1) length, to obtain the distance from the SOLR to the MA section end (1”)

- The same goes for the second MA Section end, i.e. the distance from the SOLR to the MA section end (2’) or (2’’) are obtained by substracting D_LINK (1) or (D_LINK (1) + D_LINK (2)) from (MA Section (1) length + MA Section (2) length )

#### **Figure 13c: Relocation with linking info of trackside information referred to previously passed balise group, different from the current LRBG/SOLR**

<!-- end of page 57 -->

<!-- Start of picture text -->
D_TSR  L_TSR<br>differences between  differences between   TSR start  TSR end<br>the CI against UBG1  the CI against BG1  location =  location =<br>and the CI against  (FRBG) and the CI  "max"  "min"<br>BG1, on both sides  against BG2 (SOLR),  location item  location item<br>of CI  on both sides of CI<br>L_DOUBTUNDER<br>BG1  UBG1  BG2  BG3  BG4<br>L_DOUBTOVER<br>L_TSR<br>(1st reloc.)<br>D_TSR (1st reloc.)<br>Linked balise group<br>D_TSR (2nd reloc.)  L_TSR (2nd reloc.)<br>Unlinked balise group<br><!-- End of picture text -->

- 1st relocation: When the ERTMS/ETCS on-board reads UBG1, it does not become the SOLR, so that the location items of the TSR within the message it provides are relocated by clause 3.6.4.2.5c on BG1 (which was received earlier) which is the SOLR at that time:

   - ➢ the absolute value of the difference between the max safe front end positions against BG1 and against UBG1 is added (substraction of a negative difference) to D_TSR ("max" location item).

- ➢ the absolute value of the difference between the min safe front end positions against BG1 and against UBG1 is added (substraction of a negative difference) to (D_TSR + L_TSR) ("min" location item).

- _The start & end locations of the TSR are handled independently ; the original L_TSR is not used as a separate variable by the relocation process._

- • 2nd relocation: When the ERTMS/ETCS on-board reads BG2, it becomes the new SOLR, so that the TSR location items are relocated on it: despite linking distance is available between BG1 and BG2, the relocation of the TSR location items is neither performed by clause 3.6.4.2.5a nor by clause 3.6.4.2.5b, as the last relocation of the TSR location items has been performed by clause 3.6.4.2.5c to a balise group, which was received earlier than the former reference balise group of the TSR location items, so:

   - ➢ the absolute value of the difference between the max safe front end positions against BG1 and against BG2 is subtracted from D_TSR ("max" location item).

- ➢ the absolute value of the difference between the min safe front end positions against BG1 and against BG2 is subtracted from (D_TSR + L_TSR) ("min" location item).

- _Each location item has to be handled independently. This example only covers the TSR location items._

- • 3rd relocation: When the ERTMS/ETCS on-board reads BG3, it becomes the new SOLR, so that the TSR location items are relocated on it: linking distance is available between BG2 and BG3 and it is used for the relocation of the TSR location items, as the last relocation of the TSR location items has been performed by clause 3.6.4.2.5c but not towards a balise group received earlier than the former reference balise group of the TSR location items, so:

- ➢ the linking distance between BG2 and BG3, retrieved from linking information and augmented by twice the location accuracy of BG2, is subtracted from D_TSR.

- ➢ the linking distance between BG2 and BG3, retrieved from linking information and diminished by twice the location accuracy of BG2, is subtracted from (D_TSR + L_TSR).

- • 4th relocation: When the ERTMS/ETCS on-board reads BG4, it becomes the new SOLR, so that the TSR location items are relocated on it: linking distance is available between BG3 and BG4 and it is used as such for the relocation of the TSR location items, as the last relocation of the TSR location items has not been performed by clause 3.6.4.2.5c, so:

   - ➢ the linking distance between BG3 and BG4, retrieved from linking information, is subtracted from D_TSR.

   - ➢ the linking distance between BG3 and BG4, retrieved from linking information, is subtracted from (D_TSR + L_TSR).

#### **Figure 13d: Relocation with Train Position inaccuracy of trackside information transmitted by an unlinked balise group while linking consistency is checked**

<!-- end of page 58 -->

<!-- Start of picture text -->
Level 1 => 2<br>transition<br>LRBG<br>c  1  i  2  3  4<br>D_LINK(1)  D_LINK(2)  D_LINK(3)  D_LINK(4)<br>MA Section(1) length  MA Section(2) length<br> (= End Section length)<br>MA Section(1’) end<br>MA Section(2’) end<br>Confidence Intervall<br><!-- End of picture text -->

The balise group BGi is still the LRBG and SOLR when the on-board performs the transition to level 2. The linking information which was stored in the transition buffer does not announce this BGi but BG1 that therefore becomes the new SOLR. Then the location items of the MA also released from the transition buffer (referred to balise group BGc) are relocated to BG1 prior to its evaluation, through this linking information:

- The first MA Section end is relocated by subtracting D_LINK (1) from MA Section (1) length, to obtain the distance from the SOLR to the MA section (1’) end

- • The second MA Section end is relocated by subtracting D_LINK (1) from MA Section (1) length + MA Section (2) length, to obtain the distance from the SOLR to the MA section (2’) end

- Although the balise group BGi is the LRBG, the on-board uses the train position confidence interval vs. BG1 to supervise the MA, as it is the SOLR.

#### **Figure 13e: Relocation of buffered trackside information referred to previously passed balise group, with change of LRBG/SOLR**

### **3.6.5 Position Reporting to the RBC**

#### **3.6.5.1 General**

3.6.5.1.1 The position refers to the front end of the train , as per clause 3.6.1.3.4.

3.6.5.1.1.1 Intentionally deleted.

3.6.5.1.2 The position report shall contain at least the following position and direction data

   - a) The distance between the LRBG and the estimated front end of the train.

<!-- end of page 59 -->

- b) The train position confidence interval in relation to the LRBG, given as the distance from the estimated front end position to the min safe front end position and the distance from the estimated front end position to the max safe front end position.

- c) The identity of the location reference, the LRBG.

- d) The orientation of the train in relation to the LRBG orientation. Note: Driver selected running direction is only handled by the on-board system.

- e) The position of the front end of the train in relation to the LRBG (nominal or reverse side of the LRBG).

- f) Whether the train is at standstill or, if it is not at standstill, its estimated speed

- g) Train integrity information.

- h) Direction of train movement in relation to the LRBG orientation

- i) Optionally, the previous LRBG. In case of an LRBG being a single balise group with no co-ordinate system assigned, directional information referred to in items d), e) and h) is defined in reference to the pair of LRBG and previous LRBG (see 3.4.2.3.3).

<!-- Start of picture text -->
LRBG orientation  d)  Train orientation in relation to LRBG<br>reverse  nominal<br>reverse  nominal<br>Active cab<br>c)<br>LRBG identity<br>a)  Estimated distance travelled<br>distance  distance<br>b) to min safe to max safe<br>front end  front end<br><!-- End of picture text -->

<!-- Start of picture text -->
LRBG orientation  d)  Train orientation in relation to LRBG<br>nominal  reverse<br>nominal  reverse<br>Active cab<br>c)  LRBG identity<br>a)  Estimated distance travelled<br>distance  distance<br>b) to min safe to max safe<br>front end  front end<br><!-- End of picture text -->

**Figure 14: Information given in a position report (two examples to show the relation between LRBG and train orientation)**

<!-- end of page 60 -->

3.6.5.1.3 Note: A balise group marked as unlinked is never used for position reporting to the RBC, since its location, or the balise group itself, may not be known to the RBC.

3.6.5.1.4 The on-board equipment shall send position reports as requested by the RBC in the position report parameters. In addition, it shall also send a position report if at least one of the events listed hereafter occurs:

   - a) The train reaches standstill.

   - b) The mode changes.

   - c) The driver confirms train integrity.

   - d) A loss of train integrity is detected.

   - e) The train passes an RBC/RBC border with its min safe rear end.

   - f) The train passes with its min safe rear end a level transition border which led to a transition from level 2 to level 0, NTC or 1.

   - g) The level changes.

   - h) A communication session is successfully established.

   - i) The train leaves standstill.

   - j) The train passes an LRBG compliant balise group (see 3.6.2.2.2 a)), if no position report parameters are stored on-board.

   - k) The train passes an RBC/RBC border with its max safe front end.

   - l) An error as defined in 3.16.4 is detected.

3.6.5.1.4.1 If the position report results from one or more events listed in 3.6.5.1.4, its content shall reflect the consequences of these events.

3.6.5.1.5 For the position report parameters requested by the RBC the following possibilities shall be available, individually or in combination

   - a) Periodically in time.

   - b) Periodically in space.

   - c) When the max safe front end or min safe rear end of the train has passed a specified location.

   - d) At every passage of an LRBG compliant balise group (see 3.6.2.2.2 a)).

   - e) Immediately.

3.6.5.1.5.1 Exception: it shall not be possible to combine d) and e).

3.6.5.1.6 Regarding 3.6.5.1.4 j) and 3.6.5.1.5 d): the position report triggered by the passage of an LRBG compliant balise group shall be sent only once the content of the message from this balise group has been taken into account.

3.6.5.1.7 The given position report parameters shall be valid until new parameters are given from the RBC.

<!-- end of page 61 -->

3.6.5.1.8 After an LRBG compliant balise group is passed, the ERTMS/ETCS on-board equipment shall be allowed to report the train position with this balise group as reference only once the content of the message from this balise group and the content of the messages from all the previous LRBG compliant balise groups (if any) have been taken into account.

3.6.5.1.8.1 Justification: The mode and level reported in a position report must be consistent with the content of the message of the LRBG used in this position report (e.g. if the reported train position is within an OS/SH/LS area provided by a Mode Profile given by the LRBG used in this position report, the reported mode will be the one requested by the Mode Profile).

**3.6.5.2 Report of train integrity information**

3.6.5.2.1 The confirmation of train integrity may be given by external source or by driver. For the ERTMS/ETCS on-board equipment, the confirmation of train integrity means that the train length stored as valid Train Data or the safe consist length at the time the train was last known to be integer can be used for reporting the train position to the RBC, which will allow the trackside to use the information about the confirmed train rear end position.

3.6.5.2.2 Driver input of train integrity confirmation shall only be permitted at standstill.

3.6.5.2.3 The train integrity information reported to the RBC shall consist of:

   - a) Train integrity status information

      - No train integrity information

      - Train integrity confirmed by external source

      - Train integrity confirmed by driver

      - Train integrity lost

   - b) Confirmed train length information (only available when train integrity confirmation is reported).

3.6.5.2.4 The confirmed train length information shall represent the distance between the min safe rear end at the time the train was last known to be integer and the estimated position of the train front at the time when the train integrity information is sent to the RBC (see Figure 15).

3.6.5.2.4.1 Note: when a confirmation of integrity is received from an external source, this does not necessarily mean that the train is complete at the moment that the confirmation is received, but rather that the train was known to be complete at some time before the confirmation of integrity was received. This time will depend on the properties of both the external source and the interface to this source.

<!-- end of page 62 -->

<!-- Start of picture text -->
Legend:<br>T0  Time the train was last<br>known to be integer<br>Min safe rear<br>T  Confirmed train length<br>end at T0<br>reported to RBC<br>Estimated rear<br>end at T0<br>Estimated front<br>end at T<br> O c U I C<br>LRBG<br>Estimated distance from LRBG at T<br>Confirmed train length at T<br>Confirmed rear<br>end at T<br><!-- End of picture text -->

#### **Figure 15: Calculation of Confirmed Train Length when train integrity is reported to the RBC**

3.6.5.2.5 The transitions between the different values of the train integrity status information to be sent to the relevant RBC shall be executed as described in Table 2b according to the conditions in Table 2c (see section 4.6.1 for details about the symbols).

<!-- end of page 63 -->

|**No Integrity**<br>**information**|<br>< 5<br>-p1-|< 5,7,8,9,10<br>-p3-|< 1,6<br>-p3|
|---|---|---|---|
|2 ><br>-p1-|**Integrity**<br>**confirmed by**<br>**driver**|< 2<br>-p2-|< 2<br>-p1-|
|3 ><br>-p3-||**Integrity**<br>**confirmed by**<br>**external**<br>**source**|<br>< 3<br>-p2-|
|4 ><br>-p2-||4 ><br>-p1-|**Integrity lost**|

#### **Table 2b: Transitions between values of the train integrity status information to be reported to the RBC**

|**Condition**<br>**Id**|**Content of the conditions**|
|---|---|
|[1]|The Train Data status is changed from valid to invalid|
|[2]|(Train is at standstill)<br>AND<br>{[(no Valid Train Data is available but the safe consist length is<br>available) AND (if any, safe consist length information for<br>Supervised Manoeuvre sent to the RBC has been acknowledged by<br>this latter)] OR [(valid Train Data is available and has been<br>acknowledged by the RBC) AND (no new Train Data regarding train<br>length acquired from external source is pending driver’s validation)]}<br>AND<br>(the train integrity is confirmed by the driver)|
|[3]|(The information "Train integrity confirmed" is received from an<br>external source)<br>AND<br>{[(no Valid Train Data is available but the safe consist length is<br>available and has not changed since the time the train was last<br>known to be integer)AND(if any, safe consist length information for|

<!-- end of page 64 -->

Supervised Manoeuvre sent to the RBC has been acknowledged by this latter)] OR [(valid Train Data is available and has been acknowledged by the RBC) AND (Train Data regarding train length has not changed since the time the train was last known to be integer) AND (no new Train Data regarding train length acquired from external source is pending driver’s validation)]}

AND

(the train position is valid and is referred to an LRBG) AND

(the train position was valid and was referred to an LRBG at the time the train was last known to be integer)

AND

(no reverse movement is currently performed nor has been performed since the time the train was last known to be integer) AND

(no SM authorisation changing the train orientation has been received since the time the train was last known to be integer)

AND

||(the distance between the min safe rear end at the time the train was<br>last known to be integer and the current estimated train position<br>does not exceed the range of the confirmed train length information)|
|---|---|
|[4]|(The information "Train integrity lost" is received from an external<br>source) AND ((valid Train Data is available since the time the train<br>integrity was last known to be lost) OR (the on-board is configured to<br>capture the safe consist length from the Train Interface))|
|[5]|A position report indicating that the train integrity is confirmed is sent<br>to the RBC|
|[6]|The information "Train integrity status unknown" is received from an<br>external source|
|[7]|(Train Data regarding length is changed) OR (new Train Data<br>regarding train length acquired from external source is pending<br>driver’s validation) OR (if no Valid Train Data is available, the safe<br>consist length is changed or is no longer available)|
|[8]|A reverse movement is performed|
|[9]|The distance between the min safe rear end at the time the train was<br>last known to be integer and the current estimated train position<br>exceeds the range of the confirmed train length information|

<!-- end of page 65 -->

[10] A Supervised Manoeuvre authorisation changing the train orientation is received

#### **Table 2c: Transition conditions for the train integrity status information to be reported to the RBC**

3.6.5.2.6 Following the successful establishment of a communication session with an RBC, the train integrity status information to be reported to this RBC shall initially be set to "No integrity information" and the conditions of the table 2c shall be evaluated before sending the first position report.

3.6.5.2.7 Note: As long as no train length is available (captured as valid Train Data or derived from the safe consist length information when no valid Train Data is available) or as long as the train position is not valid or not referred to an LRBG, the ERTMS/ETCS on-board equipment cannot report that the train integrity is confirmed, regardless of the train integrity information received from an external source. Justification: in order to calculate the confirmed train length when reporting a train integrity confirmation, the train position must be valid and referred to an LRBG and the train length must be available at the time of the train integrity confirmation.

3.6.5.2.8 Note: In order to keep the sending rate of position reports as requested by the RBC, the confirmation of train integrity by an external source does not trigger itself any position report. It is only in the first position report following the last confirmation of train integrity that such confirmation by external source can be reported. The difference between the confirmed train length and the train length will then grow to an extent depending on both the frequency of the train integrity confirmation and the position report sending rate.

3.6.5.2.9 Note: When the information "Train integrity lost" is received, the train integrity status information is reported in every position report following the detection of the loss of train integrity, until the train integrity is confirmed again, or until the information "Train integrity status unknown" is received from the external source, or until the Train Data is invalidated.

### **3.6.6 Geographical position reporting**

3.6.6.1 The ERTMS/ETCS on-board equipment shall display, only on driver request, the geographical position of the estimated front end of the train in relation to the track kilometre. The display of the geographical position shall also be stopped on driver request.

3.6.6.2 The resolution of the position indication shall be 1 metre (sufficient to allow the driver to report the train position when communicating with the signalman).

3.6.6.3 When receiving new geographical position information (from radio or from balise group), the ERTMS/ETCS on-board equipment shall replace the currently stored geographical position information (if any) by this new received one, continuing the ongoing geographical position calculation until at least one of the condition of 3.6.6.9 applies.

<!-- end of page 66 -->

3.6.6.4 Geographical position information shall always use a balise group as geographical position reference balise group and if needed an offset from that balise group. A geographical position reference balise group shall be either:

   - a) part of the last reported balise groups memorised on-board, in case the information is transmitted by radio, OR

   - b) the balise group transmitting the information, in case the information is transmitted by balise group, OR

   - c) any balise group not yet passed at the time of reception of the information.

3.6.6.4.1 In case the information is received by radio and at least one of the announced geographical position reference balise group(s) is part of the last reported balise groups memorised on-board, the on-board equipment shall use the data related to the most recently reported balise group.

3.6.6.4.2 From the currently stored geographical position information, the track kilometre reference given for a geographical reference location shall become applicable if the train has detected the related geographical reference balise group and has travelled the offset distance from this reference balise group.

3.6.6.4.3 The announced and not applicable geographical references shall be deleted on-board if the train changes orientation.

3.6.6.5 The distance travelled from the geographical reference location shall be taken into account when calculating the geographical position.

3.6.6.6 In cases where the track kilometre is not incremental (jumps, changes in counting direction, scaling error) the reported position might be wrong between the point of irregularity and the next new reference.

3.6.6.7 In cases where single balise groups are used as a reference for geographical position information and where no linking information is available (and therefore no orientation can be assigned to the balise group), the on-board equipment shall ignore the geographical position information related to these single balise groups.

3.6.6.8 Intentionally deleted.

3.6.6.9 The on-board equipment shall continue calculating the position from a track kilometre reference (i.e. this track kilometre reference shall remain applicable) until: a) a new track kilometre reference becomes applicable, OR b) it is told not to do so, OR c) the calculated geographical position becomes negative, OR

   - d) no more geographical position information is available (e.g., deleted according to conditions in SRS chapter 4)

3.6.6.9.1 Once a track kilometre reference is no longer applicable, it shall be deleted.

<!-- end of page 67 -->

3.6.6.10 The following data shall be included in a message for geographical position (for every track kilometre reference):

   - Identity of the geographical position reference balise group

   - Distance from geographical position reference balise group to the track kilometre reference (offset)

   - Value of the track kilometre reference

   - Counting direction of the track kilometre in relation to the geographical position reference balise group orientation.

<!-- Start of picture text -->
track kilometre   actual geogr. position:<br>reference   counting up  Track kilometre reference value<br>(counting direction:  + estimated distance travelled<br>nominal   reverse    opposite)<br>geogr. position<br>LRBG/<br>reference balise<br>ORBG<br>group<br>offset to<br>track kilometre<br>distance travelled<br>reference<br><!-- End of picture text -->

**Figure 16: Geographical position example**

### **3.6.7 Supervision of distances not referred to balise groups**

3.6.7.1 Independently from the train position in relation to balise groups (see 3.6.1.3), the ERTMS/ETCS on-board equipment shall calculate the remaining distance to be travelled by the train in relation to the following distances as soon as their supervision is started or re-started:

   - a) the maximum distance the train can move (National/Default Value) in relation to the Roll Away Protection (see section 3.14.2), the Unauthorised Direction Movement Protection (see section 3.14.3) and the Standstill supervision (see section 4.4.7.1);

   - b) the maximum distance for reversing (National/Default Value) in Post Trip mode (see 4.4.14.1.3);

   - c) the distance for train trip suppression (National/Default Value) after the Override function has been triggered (see clause 5.8.4.1 b));

   - d) the fixed distance over which the on-board balise transmission alarms are ignored, before a safety reaction is triggered (see clauses 3.15.7.2 and 5.22.5.1 a));

   - e) the fixed distance for small movements in No Power mode (see clause 3.15.8.1.1), in relation to the Cold Movement Detection function;

<!-- end of page 68 -->

   - f) a zero distance to the former EOA/LOA for the override de-activation or for the trip condition if the override is no longer active, after the Override function has been triggered in SB or PT mode while there was no valid train position stored on-board (see clauses 5.8.3.1.1 and 5.8.4.1 c));

   - g) the maximum permitted distance to run in Staff Responsible mode when it is determined by the National/Default Value, when it is transmitted by the RBC, or when it is entered by the driver (see clauses 4.4.11.1.3.1 a) & b)).

3.6.7.2 For the supervision of the distances referred in 3.6.7.1 a), b), c), d) & e) the ERTMS/ETCS on-board equipment shall take into account, for the concerned direction(s), the estimated distance travelled away from the location when their supervision was started/re-started.

3.6.7.3 For the supervision of the distances referred in 3.6.7.1 f) & g) the ERTMS/ETCS onboard equipment shall manage a virtual train front position in the following way:

   - a) The supervised distance minus the estimated distance travelled away from the location when the supervision was started determines the remaining distance from the estimated front end position to the end of the supervised distance.

   - b) The supervised distance minus the estimated distance travelled away from the location when the supervision was started and minus the odometer under-reading amount since the function was activated determines the remaining distance from the max(imum) safe front end position to the end of the supervised distance.

   - c) The supervised distance minus the estimated distance travelled away from the location when the supervision was started plus the odometer over-reading amount since the supervision was started determines the remaining distance from the min(imum) safe front end position to the end of the supervised distance.

3.6.7.3.1 Note 1: The location when the supervision is started/re-started is determined by the ERTMS/ETCS on-board (e.g. from a value of its raw position counter) regardless whether there is a stored train position in relation to balise group(s).

3.6.7.3.2 Note 2: This virtual train position is created at the time the supervision of the distance starts and overpassing a balise group does not impact its related estimated, min safe and max safe front end positions.

3.6.7.4 Any virtual train position in relation to such types of supervision of distance not referred to balise group locations shall be deleted when the related supervision ends (for the distance supervised as per 3.6.7.1 f), see 5.8.3.1.3).

3.6.7.5 For the maximum permitted distance to run in Staff Responsible mode, any update of this distance through the RBC, the driver or the triggering of the Override while already in SR mode shall be considered as a re-start of the supervision, i.e. any related previous virtual train position shall be deleted and replaced by a new one as per 3.6.7.3. Conversely, upon reception of new National Values, the related virtual train position shall be re-evaluated as per 3.6.7.3 only considering the new National Value.

<!-- end of page 69 -->

### **3.6.8 Monitoring of odometer accuracy**

3.6.8.1 The ERTMS/ETCS on-board equipment monitors the odometer accuracy based on the separate accumulation of underestimation and overestimation in measuring the movement of the train over a fixed distance.

3.6.8.1.1 Note: The accumulation of the underestimation/overestimation in measuring the movements considers that for both the forward and the backwards movements the absolute value contributes separately to the accumulation.

3.6.8.2 The ERTMS/ETCS on-board equipment shall store the accumulated underestimation/overestimation in measuring the movements over a defined total distance (as defined in A.3.1).

3.6.8.3 The check of the odometer accuracy shall be performed periodically at fixed distance intervals (see 3.6.8.5 and 3.6.8.7).

3.6.8.4 The distance of the intervals shall be less than or equal to a defined maximum distance interval (as defined in A.3.1).

3.6.8.5 When performing the check at fixed distance intervals, if any of the accumulated underestimation/overestimation in measuring the movements over the defined total distance travelled (see 3.6.8.2) exceeds the impairment threshold (as defined in A.3.1), the ERTMS/ETCS on-board equipment shall consider the odometer performance impaired, and the driver shall be informed.

3.6.8.5.1 Note: Exceeding the impairment threshold may indicate that the odometer accuracy exceeds the performance requirement as defined in SUBSET-041 §5.3.1.1.

3.6.8.6 Once the odometer performance is impaired, the ERTMS/ETCS on-board equipment shall continue to consider the odometer performance as impaired until the train has travelled the defined total distance (as defined in A.3.1 see 3.6.8.2) with both the accumulated underestimation and overestimation in measuring the movements being continuously below the "accuracy of distances measured on-board".

3.6.8.6.1 Note: This means that once the odometer performance is impaired, the odometer performance will continue to be displayed as being impaired until the train has travelled at least again the defined total distance (see 3.6.8.2).

3.6.8.6.2 As long as the odometer performance is considered as impaired the on-board shall inform the driver.

3.6.8.7 When performing the check at fixed distance intervals, if any of the accumulated underestimation/overestimation in measuring the movements over the defined total distance travelled (see 3.6.8.2) exceeds the safety threshold (as defined in A.3.1), the ERTMS/ETCS on-board equipment shall switch to mode System Failure.

<!-- end of page 70 -->

3.6.8.7.1 Note: The train must not be stopped due to exceeding this safety threshold while operating in Level 0 or Level NTC. The ERTMS/ETCS on-board equipment should therefore handle this when entering Level 1 or 2.

3.6.8.8 If any of the accumulated underestimation/overestimation in measuring the movements exceeds the defined values (see 3.6.8.5 and 3.6.8.7) the ERTMS/ETCS on-board equipment shall apply the related reactions even if the on-board has not travelled the whole total distance (see 3.6.8.2).
