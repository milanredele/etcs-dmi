## **3.8 Movement authority**

### **3.8.1 Characteristics of a MA**

3.8.1.1 The following characteristics can be used in a Movement Authority (see Figure 17: Structure of an MA):

   - a) The End of Movement Authority is the location to which the train is authorised to move.

   - b) When the Target Speed at the End of Movement Authority is zero, the End of Movement Authority is called EOA (End of Authority); when the target speed is not zero, it is called the LOA (Limit of Authority). This non zero target speed can be time limited.

   - c) If no overlap exists, the Danger Point is a location beyond the End of Movement Authority that can be reached by the front end of the train without a risk for a hazardous situation.

   - d) The end of an overlap (if used in the existing interlocking system) is a location beyond or at the End of Movement Authority that can be reached by the front end of the train without a risk for a hazardous situation. This additional distance beyond the End of Movement Authority is only valid for a defined time.

   - e) A release speed is a speed limit under which the train is allowed to run in the vicinity of the End of Movement Authority, when the target speed is zero. One release speed

<!-- end of page 75 -->

can be associated with the Danger Point, and another one with the overlap. Release speed can also be calculated on-board the train (see section 3.13.9.3.6.5).

- f) The MA can be split into several sections, The last one is called End Section.

   - A first time-out value can be attached to each section. This value will be used for the revocation of the associated route when the train has not entered into it yet. It is called the Section time-out.

   - In addition, a second time-out value can be attached to the End Section of the MA. This second time-out will be used for the revocation of the last section when it is occupied by the train; it is called the End Section time-out.

3.8.1.2 The values of the time-outs possibly given in an MA shall take into account the time elapsed from the start of validity of information to the sending of the message.

- 3.8.1.3

   - Note: A Danger Point can be (not exhaustive list):

   - the entry point of an occupied block section (if the line is operated according to fixed block principles)

   - the position of the last confirmed rear end of a train i.e. the position deduced from the confirmed train length information contained in a position report confirming the train integrity (if the line is operated according to moving block principles)

   - the fouling point of a switch, positioned for a route, conflicting with the current direction of movement of the train (both for fixed and moving block mode of operation)

3.8.1.4 Note: Traditionally the overlap is a piece of track (beyond the danger point), that is put at disposal of a train, to guarantee a non hazardous situation, also in case the driver should misjudge the stopping distance for the train. In ERTMS/ETCS the overlap can be used to improve the efficiency of the braking supervision.

3.8.1.5 Note: Time-out values can be given in the MA to cope with the following situations depending on the interlocking operations, i.e. the timers on-board will only reflect the situation trackside and when expired (on-board) the actions taken are restrictive:

   - a) Section time-out or time-out for the speed at the LOA: When a signalman requests a route release of a part of a route not yet entered by the approaching train.

   - b) End Section time-out: When the train has entered the last part of a route, the automatic route release can be delayed to make sure that the train has come to a standstill before any switches inside the route can be moved.

   - c) Time-out for an overlap: When the train has entered the last part of a route, the overlap associated with the route remains valid for a certain time to make sure that the train has successfully stopped before its End of Movement Authority. If the overlap is still unoccupied when the timer expires the interlocking revokes the overlap.

3.8.1.6 Note: If the trackside equipment does not have enough information to give the distance to the End of Movement Authority with a target speed equal to zero, a target speed higher than zero can be given (LOA, Limit of Authority). It is the responsibility of the trackside to ensure that the safe distance beyond the LOA is long enough to brake the train from

<!-- end of page 76 -->

the target speed to a stand still without any hazardous situation. It is the responsibility of the on-board equipment to apply the brakes if no new information is received when the Limit of Authority is passed.

### **3.8.2 MA request to the RBC**

**3.8.2.1 General**

3.8.2.1.1 The on-board equipment may request a new Movement Authority from the RBC for the following reasons:

   - a) “Start” selection by the driver (only level 2)

   - b) With respect to perturbation location (only level 2)

   - c) With respect to MA timer elapsing (only level 2)

   - d) Track description deletion (only level 2)

   - e) Reception of "track ahead free up to the level 2 transition location"

3.8.2.1.2 It shall be possible for the RBC to send MA request parameters defining: a) whether MA requests shall be repeated and if so, the time between each repetition b) the triggering time criterion for the reasons 3.8.2.1.1 b) & c) respectively

3.8.2.1.3 Note: the MA requests for reasons 3.8.2.1.1 b) & c) can be triggered only if the MA request parameters have been received from the RBC.

3.8.2.1.4 The parameters received from the RBC shall be valid until new MA request parameters are received from the RBC.

3.8.2.1.4.1 Note: This will lead to immediate sending of an MA request in case at the moment the new parameters are received, the time since the last sending of an MA request is equal to or higher than the new received repetition period.

3.8.2.1.5 As long as at least one reason for sending MA requests is applicable and unless it is requested by the RBC not to do so, the ERTMS/ETCS on-board equipment shall repeat the MA requests as indicated by the RBC or with a repetition cycle according to a fixed value (see appendix A.3.1) in case no MA request parameters are stored on-board.

3.8.2.1.6 If a reason for sending MA requests becomes applicable while an MA request repetition cycle is already ongoing for another reason, the MA request triggered for this new reason shall reset the repetition cycle.

3.8.2.1.7 Together with any MA request the on-board shall inform the RBC about the reason(s) that is (are) applicable at the time the MA request is sent.

**3.8.2.2 MA request to the RBC with respect to the perturbation location or MA timer elapsing (only level 2)**

3.8.2.2.1 The triggering criteria that can be used by the RBC are the following:

<!-- end of page 77 -->

   - a) A defined time before the train reaches the perturbation location assuming it is running at the warning speed (see section 3.13.11 for details).

   - b) A defined time before the Section timer (not the End Section timer, not the Overlap timer) for any section of the MA expires, or before the LOA speed timer expires.

3.8.2.2.2 With regard to the above possibilities, the MA request shall be triggered when the train front has passed the location defined by 3.8.2.2.1 a) / when the moment defined by 3.8.2.2.1 b) is reached.

3.8.2.2.3 Once the resulting location regarding 3.8.2.2.1 a) is passed by the train front, the reason "Time before reaching the perturbation location reached" shall remain applicable until the triggering criterion is not fulfilled anymore, e.g. due to the reception of a new MA or to a temporary EOA that is no longer supervised.

3.8.2.2.4 Once the defined time before the expiration of a Section timer or before the expiration of the LOA speed timer is reached, the reason "Time before a Section timer/LOA speed timer expires reached" shall remain applicable until no Section timer, for which the defined time before expiration is reached, is supervised and no LOA, for which the defined time before expiration is reached, is supervised.

**3.8.2.3 MA request to the RBC on driver selecting “Start” (only level 2)**

3.8.2.3.1 An MA request shall be sent to the RBC when the driver selects ”Start”.

3.8.2.3.2 The reason ""Start" selected by driver" shall remain applicable until: a) an MA is received or

   - b) an SR authorisation is received or

   - c) the desk is closed.

**3.8.2.4 MA request to the RBC on reception of "track ahead free up to the level 2 transition location"**

3.8.2.4.1 If a level 2 transition is announced and a communication session is already established, an MA request shall be sent to the RBC when the information "Track ahead free up to level 2 transition location" is received from balise group.

3.8.2.4.2 The ERTMS/ETCS on-board equipment shall also inform the RBC about the identity of the level 2 transition location balise group, as received through the information "Track ahead free up to level 2 transition location".

3.8.2.4.3 By exception to the clause 3.8.2.1.5, only one MA request with the reason "Track ahead free up to the level 2 transition location" shall be sent upon reception of the corresponding information from balise group.

**3.8.2.5 MA request to the RBC on track description deletion (only level 2)**

3.8.2.5.1 An MA request shall be sent to the RBC when any part of the track description is deleted according to A.3.4, except for situations a, b, f, k.

<!-- end of page 78 -->

3.8.2.5.2 The reason "Track description deletion" for MA requests shall remain applicable until a new MA is received on-board.

### **3.8.3 Structure of a Movement Authority (MA)**

3.8.3.1 The distance to the End of Movement Authority can be composed of several sections.

3.8.3.2 For each section composing the MA the following information shall be given;

   - a) Length of the section

   - b) Optionally, Section time-out value and distance from beginning of section to Section timer stop location

- 3.8.3.3

- In addition, it shall be possible to define for the End Section of the MA:

- a) End Section time-out value and distance from the End Section timer start location to the end of the last section

- b) Danger point information (distance from end of section to danger point, release speed related to danger point)

- c) Overlap information (distance from end of section to end of overlap, time-out, distance from Overlap timer start location to end of section, release speed related to overlap)

<!-- Start of picture text -->
LRBG/ Distance to Danger Point<br>ORBG  Length of Overlap<br>Section timer stop location  Section timer stop location<br>Overlap timer start location<br>End Section timer start location<br>Section(1)   Section(2) = End Section<br>Optional signal<br><!-- End of picture text -->

**Figure 17: Structure of an MA**

3.8.3.3.1 Note: If only one section is given in the MA it is regarded as the End Section.

- 3.8.3.4

   - The Section timer stop location shall be inside of the corresponding section.

3.8.3.4.1 Note: the End Section and Overlap timer start locations may be outside their corresponding section. One example can be seen referring to figure 22c: An infill MA

<!-- end of page 79 -->

towards a signal at stop will replace the previous End Section by a new short End Section starting at the infill location reference and ending at the next main signal, however the End Section and Overlap timer start locations still have to be consistent with the Interlocking timer start locations. Another example is when a timer start location is in rear of the LRBG.

3.8.3.5 Intentionally deleted.

3.8.3.5.1 Intentionally deleted.

3.8.3.6 When an MA is transmitted by a balise group, the length of the first section shall refer to the balise co-ordinate system of that balise group.

3.8.3.7 In case a main signal is at danger in level 1, the first section shall give the distance from the balise group at the main signal to the location of the main signal, i.e. the distance to EOA is given. Where available, information concerning danger point and overlap for this EOA may also be given.

3.8.3.7.1 Justification: The balise group is not necessarily placed at the same location as the signal and thus an infill message (which includes the same information as the balise group at the main signal) could change the location of the EOA to a position closer to the train.

3.8.3.8 Note: In case the main signal is at danger in level 1, the on-board will supervise the given distance (specified in section 3.8.3.7) as the distance to EOA.

3.8.3.9 When an MA is transmitted by radio from the RBC, the length of the first section shall refer to the balise co-ordinate system of the LRBG given in the same message.

3.8.3.10 It shall be possible to give the length of a section to any location in the track.

3.8.3.10.1 Note: A section can cover several blocks and is not restricted to block ends (see figures).

<!-- Start of picture text -->
[   ] [   ] [   ] [   ]<br>Section(1)<br>[   ] : Optional signal EOA/LOA<br><!-- End of picture text -->

**Figure 18: Distance to End of Movement Authority when no time-outs are needed**

<!-- end of page 80 -->

<!-- Start of picture text -->
[   ] [   ] [   ] [   ]<br>Section(2)<br>EOA/LOA<br>[   ] : Optional signal<br><!-- End of picture text -->

#### **Figure 19 : Distance to End of Movement Authority when time-outs might be needed**

3.8.3.11 Intentionally deleted.

#### **Figure 20: Intentionally deleted**

### **3.8.4 Use of the MA on board the train**

#### **3.8.4.1 End Section Time-Out**

3.8.4.1.1 The End Section timer shall be started on-board when the train passes the End Section timer start location given by trackside with its max safe front end.

3.8.4.1.2 When the End Section timer value becomes greater than the time-out value given by trackside, the following shall apply:

   - a) The EOA/LOA shall be withdrawn to the current position of the train. Refer to appendix A.3.4 for the exhaustive list of location based information stored on-board, which shall be deleted accordingly;

   - b) if any, a non zero target speed value at the End of Movement Authority shall be set to zero (i.e. an LOA at the End of Movement Authority becomes an EOA withdrawn to the current position of the train).

3.8.4.1.3 In case no End Section timer is running when the on-board receives a new MA with an End Section timer start location in rear of the max safe front end of the train, the onboard shall consider that the End Section timer value became greater than its time-out value and apply 3.8.4.1.2.

3.8.4.1.3.1 Justification: in this case the train is already beyond the timer start location, therefore it is impossible to determine when that location was crossed and so what share of the timeout value has elapsed since the crossing event. The safe assumption is to consider that the time-out value has been exceeded and therefore that the End Section will soon be released by the Interlocking.

3.8.4.1.4 In case an End Section timer is already running when the on-board receives a new MA with an End Section timer start location in rear of the max safe front end of the train, the on-board shall keep the End Section timer running but replace the time-out value with the value received with the new MA.

<!-- end of page 81 -->

3.8.4.1.4.1 Justification: this allows repetition of the MA via RBC (e.g. acknowledgment of current MA was lost) without unintentionally affecting the End Section timer.

**3.8.4.2 Section Time-Outs**

3.8.4.2.1 For each section, the on-board shall consider a Section timer that has started:

   - a) For Level 2: at the value of the time stamp of the message including the MA.

   - b) For Level 1: at the time of passage over the first encountered balise of the balise group giving the MA.

3.8.4.2.1.1 Justification for b): This is to ensure that the timer is always started before or at the same time as the related variable information is received. Thus the timer start is independent of in which balise the variable information is given.

3.8.4.2.2 When a Section timer value becomes greater than the time-out value given by trackside, the following shall apply unless an MA shortening has occurred with A.3.4.1.3 condition [11] applied:

   - a) the EOA/LOA and the SvL shall be withdrawn to the entry point of the revoked section. Refer to appendix A.3.4 for the exhaustive list of location based information stored on-board, which shall be deleted accordingly;

   - b) the National/ Default Value of the Release Speed shall apply ;

   - c) if any, a non zero target speed value at the End of Movement Authority shall be set to zero (i.e. an LOA at the End of Movement Authority becomes an EOA withdrawn to the entry point of the revoked section).

3.8.4.2.2.1 Justification: Applying 3.8.4.2.2 while the ERTMS/ETCS on-board equipment has considered the current estimated front end and max safe front end positions, as the EOA and SvL respectively, with no Release Speed, could lead to inappropriate system behaviour such as the EOA being moved in advance of the current one or in the sudden supervision of a Release Speed allowing the train to move forward.

3.8.4.2.3 The Section timer shall be stopped when the min safe front end of the train has passed the associated Section timer stop location.

3.8.4.2.4 In case of reverse movement which brings back the min safe front end of the train in rear of a Section timer stop location after the Section timer has been stopped according to 3.8.4.2.3, the on-board shall consider that the Section timer value became greater than its time-out value and shall apply 3.8.4.2.2 once the train has reached standstill.

3.8.4.2.5 If, upon its evaluation, a new MA includes a section with its timer stop location already in rear of the min safe front end of the train, the on-board shall consider that the Section timer had been stopped before its value could become greater than its time-out value and shall not apply 3.8.4.2.2.

3.8.4.2.5.1 Justification: in this case the train is already beyond the timer stop location, therefore it is impossible to determine when that location was crossed and so what share of the timeout value has elapsed before the crossing event. Knowing the above on-board

<!-- end of page 82 -->

behaviour, it is always the trackside responsibility to take the appropriate measures to ensure a safe release of the corresponding section.

**3.8.4.3 Time-out of the speed associated with the End of Movement Authority (LOA speed time out)**

3.8.4.3.1 For the LOA speed, the on-board shall consider a timer that has started:

   - a) For Level 2: at the value of the time stamp of the message including the MA.

   - b) For Level 1: at the time of passage over the first encountered balise of the balise group giving the MA.

3.8.4.3.1.1 Justification for b): This is to ensure that the timer is always started before or at the same time as the related variable information is received. Thus the timer start is independent of in which balise the variable information is given.

3.8.4.3.2 When the LOA speed timer value becomes greater than the time-out value given by trackside, the speed associated with the LOA shall be set to zero (i.e. the Limit of Authority becomes an End of Authority and the SvL is defined on-board according to 3.8.4.5). Refer to appendix A.3.4 for the exhaustive list of location based information stored on-board, which shall be deleted accordingly.

#### **3.8.4.4 Time-out of Overlap**

3.8.4.4.1 The Overlap timer shall be started on-board when the train passes the Overlap timer start location given by trackside with its max safe front end. The timer shall be considered as started even if a time-out value “infinite” is given.

3.8.4.4.2 When the Overlap timer value becomes greater than the time-out value given by trackside, the following shall apply:

   - a) the overlap information shall be deleted and the Supervised Location shall be determined in accordance with 3.8.4.5. Refer to appendix A.3.4 for the exhaustive list of location based information stored on-board, which shall be deleted accordingly.

   - b) the release speed associated with the Overlap shall be deleted

   - c) if any, a non zero target speed value at the End of Movement Authority shall be set to zero (i.e. an LOA at the End of Movement Authority becomes an EOA).

3.8.4.4.3 If the train comes to a standstill after the Overlap timer has been started, the on-board shall consider that the Overlap timer value became greater than its time-out value and shall apply 3.8.4.4.2.

3.8.4.4.4 In case no Overlap timer is running when the on-board receives a new MA with an Overlap timer start location in rear of the max safe front end of the train, the on-board shall consider that the Overlap timer value became greater than its time-out value and shall apply 3.8.4.4.2.

3.8.4.4.4.1 Justification: in this case the train is already beyond the timer start location, therefore it is impossible to determine when that location was crossed and so what share of the time-

<!-- end of page 83 -->

out value has elapsed since the crossing event. The safe assumption is to consider that the time-out value has been exceeded and therefore that the Overlap will soon be released by the Interlocking.

3.8.4.4.5 In case an Overlap timer is already running when the on-board receives a new MA with an Overlap timer start location in rear of the max safe front end of the train, the on-board shall keep the Overlap timer running but replace the Overlap time-out value with the value received with the new MA.

3.8.4.4.5.1 Justification: this allows repetition of the MA via RBC (e.g. acknowledgment of current MA was lost) without unintentionally affecting the Overlap timer.

**3.8.4.5 Supervised Location**

3.8.4.5.1 Unless stated otherwise, the Supervised Location (SvL) shall be defined on-board as: a) the end of overlap (if any and before time-out).

   - b) if not, the Danger Point (if any).

   - c) if not, the end of the End Section.

3.8.4.5.2 As long as a Limit of Authority is supervised, no SvL shall be defined on-board.

**3.8.4.6 Infill MA (level 1 only)**

3.8.4.6.1 An MA given by an infill device is called an infill MA.

3.8.4.6.2 An infill MA shall be evaluated on-board only if the on-board equipment is in FS, AD or LS mode.

3.8.4.6.3 The infill information shall include the identity of the balise group at the next main signal i.e. the identity of the balise group giving the information that is transmitted in advance by the infill device.

3.8.4.6.4 An infill MA shall be evaluated on-board only if the linking information, regarding the main signal balise group to which it refers, is available.

3.8.4.6.5 The on-board shall start a Section timer for each section beyond the next main signal:

   - a) When the infill information is received from a balise group at the time of passing the first encountered balise of the infill balise group.

   - b) When the infill information is received from a loop at the time of receiving the loop message.

   - c) When the infill information is received from a radio infill unit at the value of the time stamp of the radio infill message including the MA.

### **3.8.5 MA Update**

3.8.5.1 A new MA shall replace a previously received MA in the following ways:

<!-- end of page 84 -->

   - a) When the new MA is given from a balise group at a main signal (i.e. non-infill information) or from the RBC all data included in the previous MA shall be replaced by the new data.

   - b) When the new MA is given as infill information all data beyond the announced balise group at the next main signal shall be replaced.

3.8.5.1.1 Note: This refers to all information included in the MA as listed in section 3.8.1.1 and the Signalling related speed restriction (see section 3.11.6).

3.8.5.1.2 When an infill MA is received, the on-board shall start a new MA section at the infill location reference, i.e. the balise group at the next main signal (see 3.6.2.3.1).

3.8.5.1.3 If the SvL defined from the new MA is closer than the one supervised with the former MA, this shall be considered by the on-board equipment as an MA shortening. Refer to appendix A.3.4 for the exhaustive list of location based information stored on-board, which shall be deleted accordingly.

3.8.5.1.4 If a new MA defines an SvL while the on-board was supervising an LOA, this shall always be considered by the on-board equipment as an MA shortening regardless of the SvL location. Refer to appendix A.3.4 for the exhaustive list of location based information stored on-board, which shall be deleted accordingly.

3.8.5.1.5 On reception of a shortened MA sent together with other location based information, the deletion of information referred to in the clauses 3.8.5.1.3 and 3.8.5.1.4 shall apply to the information stored on-board prior to the reception of this trackside information, before any clause dealing with the replacement of information (e.g. 3.7.3.1 or 3.18.2.9 first bullet) is applied.

3.8.5.2 It shall be possible to update the length of an MA section by means of repositioning information contained in a balise group message (see section 3.8.5.3).

3.8.5.2.1 Note: The concerned MA section need not be the end section.

3.8.5.2.2 Upon reception of repositioning information and only if linking information has announced a following balise group as unknown but containing repositioning information, the onboard shall update the length of the current MA section in which the train front end is.

3.8.5.2.3 A balise group message containing a non-infill movement authority shall not contain repositioning information for the same direction.

3.8.5.2.3.1 Note: It is possible to combine repositioning with an infill MA.

3.8.5.2.4 The reception of repositioning information or of a new MA with an LOA shall not be considered as an MA shortening by the on-board equipment.

**3.8.5.3 Examples of MA update**

3.8.5.3.1 Note: In the following examples on how to update an MA are given. The examples are not exhaustive.

<!-- end of page 85 -->

3.8.5.3.2 Example: Extension of MA via a main balise group in Level 1

   - by giving a new longer section, see Figure 21a

   - by giving a first section to the same location as in the previous MA and a second section, see Figure 21b

<!-- Start of picture text -->
(0)  (1)  (2)       (3)<br>Section (1)  MA 1 given in<br>balise group (0)<br>MA 2 given in<br>balise group (1)<br>Section (1)<br><!-- End of picture text -->

#### **Figure 21a: Extension of an MA in Level 1, one section in the new MA**

<!-- Start of picture text -->
(0)     (1)           (2)<br>MA 1 given in<br>Section (1)<br>balise group (0)<br>MA 2 given in<br>balise group (1)<br>Section (1)                      section (2)<br><!-- End of picture text -->

#### **Figure 21b: Extension of an MA in level 1, two sections in the new MA**

3.8.5.3.3 Example: MA update via infill information in Level 1. (Refer to section 3.6.2.3 for location reference of infill information)

   - MA extension, by giving two new sections, see Figure 22a

   - MA shortening, see Figure 22b

   - MA repetition, see Figure 22c

<!-- end of page 86 -->

<!-- Start of picture text -->
Infill Device(s)<br>(1)    (2)                   (3)<br>Section (1)<br>MA given in<br>balise group (1)<br>End Section timer<br>start location<br>Infill MA from<br>Section (2)  trackside<br>End<br>Section (1)  Section (2)<br>Section<br>timer stop<br>timer start<br>location<br>l i<br>Resulting MA<br>Section (2)  on-board<br>Section (1)  Section (3)<br>Section (3)   End<br>timer stop  Section<br>location  timer start<br>l i<br><!-- End of picture text -->

**Figure 22a: Extension of an MA with Infill information**

<!-- end of page 87 -->

<!-- Start of picture text -->
Infill Device(s)<br>(1)    (2)              (3)<br>Section (1)  MA given in<br>balise group (1)<br>End Section<br>timer start<br>location<br>Infill MA<br>End Section timer<br>start location  Section (1)<br>Resulting MA<br>onboard<br>Section (2)<br>Section (1)<br>End Section timer<br>start location<br><!-- End of picture text -->

**Figure 22b: Shortening of an MA with Infill information**

<!-- Start of picture text -->
Infill Device(s)<br>(1)    (2)              (3)<br>Section (1)  MA given in<br>balise group (1)<br>End Section timer<br>start location<br>Infill MA<br>End Section timer<br>start location  Section (1)<br>Resulting MA<br>Section (2)  onboard<br>Section (1)<br>End Section timer<br>start location<br><!-- End of picture text -->

**Figure 22c: Repetition of an MA with Infill information**

<!-- end of page 88 -->

3.8.5.3.4 Example: Extension of MA in Level 2

   - by using the same LRBG as in previous MA, see Figure 23a

   - by using a new LRBG, see Figure 23b

<!-- Start of picture text -->
(0)        (1)                  (2)          (3)<br>MA 1 given with<br>Section(1)  balise group (0)<br>as LRBG<br>MA 2 given with<br>balise group (0)<br>as LRBG<br>Section(1)<br><!-- End of picture text -->

#### **Figure 23a: Extension of an MA in level 2, using same LRBG**

<!-- Start of picture text -->
(0)        (1)                  (2)          (3)<br>MA 1 given with<br>Section(1)  balise group (0)<br>as LRBG<br>MA 2 given with<br>balise group (1)<br>as LRBG<br>Section(1)<br><!-- End of picture text -->

#### **Figure 23b: Extension of an MA in Level 2, using a new LRBG**

3.8.5.3.5 Example: Extension of MA in level 1 using a balise group containing repositioning information.

3.8.5.3.5.1 Note: In some existing systems, information about the locked route is not complete.

3.8.5.3.5.2 History of the situation (refer to the figure below):

   - a) Signal A gives an aspect to proceed up to signal Cx because it has received information about the locked route.

   - b) Signal A can determine whether track 3 or track 1 / 2 is locked but is unable to distinguish between track 1 and 2.

   - c) In the situation described the route is set to track 1 or 2.

<!-- end of page 89 -->

<!-- Start of picture text -->
Track 1<br>B1 C1<br>Track 2<br>B2 C2<br>Track 3<br>A B3 C3<br><!-- End of picture text -->

**Figure 24: Information on set route not complete at signal A**

3.8.5.3.5.3 In balise group A the following information is given:

   - a) The most restrictive track description from all routes (which could be a combination from the routes);

   - b) The linking distance given to the farthest balise group containing repositioning information, the identification of the repositioning balise group is not known;

   - c) For a given aspect of signal A, the most restrictive MA from all routes (the shortest sections from the routes and the lowest target speed at the End of Movement Authority);

   - d) If some sections are time limited, the most restrictive timer.

3.8.5.3.5.4 Balise groups B (B1 or B2) give the following static information:

   - a) This is repositioning information

   - b) Linking to the next balise group C

   - c) The distance to the end of the current section (i.e. the distance to the end of section B1 - C1, or the distance to the end of section B2 - C2)

   - d) The track description related to this track.

<!-- end of page 90 -->

<!-- Start of picture text -->
50 km/h<br>Track 1<br>A B1 C1<br>Section(1)  1  = 1200 m Target speed = 50 km/h<br>Linking Distance1 = 600 m<br>40 km/h<br>Track 2<br>A B2 C2<br>Section(1)  2  = 1400 m<br>Target speed = 40 km/h<br>Linking Distance 2= 700<br>Most restrictive SSP<br>Info in A<br>50 km/h<br>40 km/h<br>A<br>Section(1) 1 = 1200 m<br>Target speed = 40 km/h<br>Linking Distance 2 = 700  m<br>50 km/h<br>Info in B1<br>A B1 C1<br>Linking = 600 m<br>Section(1) = 600  m<br><!-- End of picture text -->

**Figure 25: Information contained in A and B1 (for clarity purposes, only SSPs are drawn but the procedure has to be applied for all track description)**

### **3.8.6 Co-operative shortening of MA (Level 2 only)**

3.8.6.1 It shall be possible to shorten a given MA using a special procedure between on-board equipment and RBC. The procedure is as follows:

   - a) The RBC sends a request to shorten MA, which includes a proposed shortened MA with an EOA closer to the train than the current EOA/LOA, optionally with a mode profile and in case of SH mode profile optionally with a list of balise groups for SH area.

<!-- end of page 91 -->

   - b) The ERTMS/ETCS on-board equipment shall check the train front end position versus the Indication supervision limit of the proposed shortened MA.

      - If it is in rear, the request shall be accepted and the on-board equipment shall consider the proposed shortened MA as the new MA, together with its accompanying mode profile (if any) and list of balise groups for SH area (if any).

      - If it is in advance, the request shall be rejected and the previously received MA, mode profile (if any) and list of balise groups for SH area (if any) shall remain valid

   - c) The RBC shall be informed about the decision.

3.8.6.2 If the request from the RBC is granted by the on-board, refer to appendix A.3.4 for the exhaustive list of location based information, which shall be deleted accordingly.
