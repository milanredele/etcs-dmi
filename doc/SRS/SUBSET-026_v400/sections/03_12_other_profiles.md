## **3.12 Other Profiles**

### **3.12.1 Track Conditions**

3.12.1.1 The Track Condition function is used to inform the driver and/or the train of a condition in front of the train.

3.12.1.2 A Track Condition shall be given as profile data (e.g. non-stopping area), i.e. start and end of the data is given, or location data (e.g. change of traction system) i.e. start location given, depending on the type of track condition.

3.12.1.2.1 The starting point of a profile type track condition shall be evaluated taking into account the max safe front end of the train, the end of the profile taking into account the min safe rear end of the train. Location type data shall be evaluated taking into account the max safe front of the train.

3.12.1.2.1.1 Note: The timing of output data to control train equipment (e.g. pantograph) is application specific.

3.12.1.2.1.2 Exception 1: The starting point of a Big Metal Mass type track condition shall be evaluated taking into account the max safe antenna position, the end of the profile taking into account the min safe antenna position.

3.12.1.2.1.3 Exception 2: The end of the Powerless section and the end of the Station Platform shall be evaluated taking into account the min safe front end of the train.

3.12.1.2.1.4 Exception 3: The start and end of a tunnel stopping area and of a sound horn track condition shall be evaluated taking into account the estimated front end of the train.

3.12.1.2.1.5 Exception 4: The start and end of a radio hole shall be evaluated taking into account the estimated position of the front/rear and rear/front ends of the engine respectively, depending on whether the train orientation is the same as/opposite to the active cab.

3.12.1.2.1.5.1 Note: it is assumed that all the radio antennas are installed on the engine.

3.12.1.3 The types of track conditions to be covered by this function are:

   - Powerless section, lower pantograph (initial state: no powerless section, i.e. pantograph not to be lowered)

<!-- end of page 107 -->

   - Powerless section, switch off main power switch (initial state: no powerless section, i.e. main power switch not to be switched off)

   - Air tightness (initial state: no request for air tightness)

   - Sound horn (initial state: no request for sound horn)

   - Non stopping area (initial state: stopping permitted)

   - Tunnel stopping area (initial state: no tunnel stopping area)

   - Change of traction system, switch traction system on-board, used for train capable of handling several traction systems (initial state: no initial state – keep the current setting)

   - Change of allowed current consumption, limit current consumed by the train, used to adapt the maximum current consumption of the train to the maximum current allowed by the trackside (initial state: no initial state – keep the current setting)

   - Big metal masses, ignore onboard integrity check alarms of balise transmission. (initial state: alarms not ignored)

   - Radio hole, stop supervision of the loss of safe radio connection (initial state: loss of safe radio connection supervised)

   - Switch off regenerative brake (initial state: regenerative brake on)

   - Switch off eddy current brake for service brake (initial state: eddy current brake on for service brake)

   - Switch off eddy current brake for emergency brake (initial state: eddy current brake on for emergency brake)

   - Switch off magnetic shoe brake (initial state: magnetic shoe brake on).

   - Station platform, enable passenger doors with or without steps according to platform location, side and height (initial state: no platform, i.e. passenger doors not enabled).

3.12.1.3.1 Note: In case of regenerative brake switch off or magnetic shoe brake switch off, the deceleration of the emergency brake might be affected if the effect of these brakes was included in the calculation of the deceleration value.

3.12.1.3.2 Note: In case of eddy current brake switch off the deceleration of the service brake or emergency brake might be affected if the effect of these brakes was included in the calculation of the deceleration value.

3.12.1.3.3 Note: in case of powerless section the deceleration of the service brake or emergency brake might be affected if the effect of a regenerative brake not independent from the presence of voltage in the catenary was included in the calculation of the deceleration value.

3.12.1.4 Intentionally deleted.

3.12.1.5 The following actions shall be performed once a track condition has been received:

   - a) Indicate on DMI (see chapter 5, procedure “Indication of track conditions”), except “Station platform”, “Change of allowed current consumption” and “Big metal masses”.

<!-- end of page 108 -->

   - b) Send information with the remaining distance to an ERTMS/ETCS external function (see chapter 5, procedure “Generation of track conditions related information to an ERTMS/ETCS external function”), with the exception of big metal mass track condition, sound horn track condition, non stopping area, tunnel stopping area and supervision of radio transmission which are handled inside the ERTMS/ETCS onboard equipment.

3.12.1.5.1 Note: Whether some information shall be filtered (not shown to the driver or not sent to an ERTMS/ETCS external function) is outside the scope of ERTMS/ETCS.

3.12.1.5.2 Note: The ERTMS/ETCS external function must be able to handle new track condition of the same type as previously received and covering the same distance.

3.12.1.6 The train is permitted to run without any track condition information given from the trackside. The initial state shall then be used by the on-board equipment.

### **3.12.2 Route Suitability**

3.12.2.1 Route suitability data defines which values concerning loading gauge, traction system and axle load category a train must meet to be allowed to enter the route.

3.12.2.2 It shall be possible for trackside to send route suitability data as location data when needed.

3.12.2.3 On reception of route suitability data, the ERTMS/ETCS on-board equipment shall compare it with the corresponding Train Data stored on-board. Unsuitability exists if:

   - a) The loading gauge profile of the train is not included in the list of loading gauges accepted by trackside

   - b) The list of traction systems accepted by the engine does not include the one received from trackside

   - c) The axle load category of the train is not included in the list of permitted ones received from trackside

3.12.2.3.1 Exception to 3.12.2.3 b): If the engine is able to run on a line not fitted with any traction system, unsuitability never exists.

3.12.2.4 If at least one unsuitability exists, the closest location corresponding to the unsuitability(ies) shall be considered as both temporary EOA and SvL, with no Release Speed. The driver shall be informed about all unsuitabilities.

3.12.2.5 The temporary EOA and SvL are entities distinct from the EOA and SvL continuously supervised by the on-board. Unless specified otherwise, all the instances of the terms EOA or SvL used in this document do not refer to these temporary EOA/SvL.

3.12.2.5.1 Intentionally deleted.

3.12.2.6 Intentionally deleted.

<!-- end of page 109 -->

3.12.2.7 Intentionally deleted.

3.12.2.8 Intentionally deleted.

3.12.2.9 The Train Data concerning route suitability is part of the Train Data sent to the RBC.

3.12.2.9.1 Note: This allows for route suitability supervision to be used in systems external to the ERTMS/ETCS system.

3.12.2.10 The train is permitted to run without any route suitability data given from the track. No default values shall be used or supervised by the on-board equipment, i.e. the initial state is that no restrictions related to route suitability exists.

### **3.12.3 Text Transmission**

#### **3.12.3.1 General Rules**

3.12.3.1.1 It shall be possible to transmit information to be displayed to the driver from the trackside to the on-board equipment in the form of text messages.

3.12.3.1.2 Text messages shall always be supplemented by conditions on when and where they are to be displayed, and whether any acknowledgement is requested from the driver. These parameters shall be transmitted individually for each message.

3.12.3.1.3 Text messages and the supplementary information shall always be transmitted in one message.

3.12.3.1.4 It shall be possible to send the text to be displayed in plain text or to send a number selecting a fixed message.

3.12.3.1.4.1 Note: In case of plain text messages the trackside selects the language in which the message is displayed.

3.12.3.1.5 Intentionally deleted.

3.12.3.1.6 Intentionally deleted.

3.12.3.1.7 Intentionally deleted.

3.12.3.1.8 Intentionally deleted.

3.12.3.1.9 The following data shall be included in a text message:

   - Class of message (auxiliary or important information)

   - Plain text message or fixed message number

   - Condition for start of indication

   - Condition for end of indication

   - If driver acknowledgement is requested or not

3.12.3.1.10 The appearance of a message shall depend on the class and on whether a driver acknowledgement is requested.

<!-- end of page 110 -->

3.12.3.1.11 It shall be possible for trackside to send a text message with a request to report driver acknowledgement, if any, to an RBC.

**3.12.3.2 Intentionally deleted**

3.12.3.2.1 Intentionally deleted

**3.12.3.3 Fixed text messages**

3.12.3.3.1 Fixed text messages shall be stored on-board in all languages that can be selected by the driver.

3.12.3.3.2 Intentionally deleted.

3.12.3.3.3 Intentionally deleted.

3.12.3.3.4 Intentionally deleted.

3.12.3.3.5 Intentionally deleted.

**3.12.3.4 Conditions for Start/End of Indication**

3.12.3.4.1 It shall be possible to specify individual sub-conditions for start/end condition of indication.

3.12.3.4.2 The following sub-conditions can be used to define the start condition:

   - Location (the train front end is in advance of this location)

   - Mode (the on-board is in this mode)

   - Level (the on-board is in this level)

3.12.3.4.3 The following sub-conditions can be used to define the end condition:

   - Location (the train front end is in advance of this location)

   - Time (the duration since the start condition is fulfilled elapses)

   - Mode (a transition from this mode is executed)

   - Level (a transition from this level is executed)

3.12.3.4.3.1 It shall be possible to define whether one or all of the sub-conditions used from the list in 3.12.3.4.2/3.12.3.4.3 have to be fulfilled to define the start/end condition. This definition shall apply to both the start and the end conditions. It shall apply to the start condition checked by the on-board when at least two sub-conditions from the list in 3.12.3.4.2 are used by the trackside and it shall apply to the end condition checked by the on-board when at least two sub-conditions from the list in 3.12.3.4.3 are used by the trackside.

3.12.3.4.3.1.1 When at least two sub-conditions from the list in 3.12.3.4.2 are used and they all have to be fulfilled, they shall be continuously evaluated until they are all fulfilled at the same time.

<!-- end of page 111 -->

3.12.3.4.3.1.2 When at least two sub-conditions from the list in 3.12.3.4.3 are used and they all have to be fulfilled, they shall be evaluated independently from each other and a sub-condition shall no longer be evaluated once it is fulfilled.

3.12.3.4.3.1.3 If none of the sub-conditions from the list in 3.12.3.4.2 is used, it shall be considered as a start condition immediately fulfilled.

3.12.3.4.3.1.4 If none of the sub-conditions from the list in 3.12.3.4.3 is used, it shall be considered as an end condition never fulfilled.

3.12.3.4.3.2 In case a confirmation of the text message is requested, it shall be possible to define whether the driver acknowledgement is considered:

   - a) As always ending the text display, regardless of the end condition defined in 3.12.3.4.3.1

   - b) As a necessary condition to end the text display, in addition to the end condition defined in 3.12.3.4.3.1.

3.12.3.4.4 The end condition shall be evaluated as soon as the start condition is fulfilled. No display shall take place if the end condition is immediately fulfilled, regardless if a confirmation of the text message is requested.

3.12.3.4.5 Once the text message is displayed and the end condition is fulfilled, the start condition shall not be re-evaluated.

3.12.3.4.6 When the sub-condition "location" is used for the end condition, the length on which the text is displayed shall refer to the location used for the start condition, independently from other start sub-conditions.

3.12.3.4.7 In case a confirmation of the text message is requested, it shall be possible to define whether the service brake or emergency brake application shall be commanded if the driver does not acknowledge before the end condition is fulfilled.

3.12.3.4.7.1 If the driver does not acknowledge before the end condition is fulfilled, the text message shall remain displayed until acknowledged by driver.

3.12.3.4.7.2 If the driver acknowledges before the end condition is fulfilled, the on-board equipment shall consider the driver acknowledgement as requested by trackside (see 3.12.3.4.3.2).

3.12.3.4.8 Intentionally deleted.

**3.12.3.5 Report of driver acknowledgement to RBC**

3.12.3.5.1 If trackside requests a report of driver acknowledgement, then it shall include:

   - a text message identifier

   - the identity of the RBC to which the driver acknowledgement report is to be sent.

<!-- end of page 112 -->

3.12.3.5.2 When the driver has acknowledged a text message with a request to report driver acknowledgement, the driver acknowledgement report, including the text message identifier, shall be sent to the RBC referenced in the request.

3.12.3.5.3 A new text message with request for report of driver acknowledgement shall be rejected by the ERTMS/ETCS on-board equipment if it has the same text message identifier as a previously received text message, which the driver has not yet acknowledged.

**3.12.4 Mode profile**

3.12.4.1 It shall be possible for trackside to send a Mode Profile. The Mode Profile can request On Sight mode, Limited Supervision mode and Shunting mode.

3.12.4.2 For OS and LS mode the mode profile defines the entry and the length of the On Sight/Limited Supervision area. For SH mode the mode profile only defines the entry location to SH mode, any length given shall be ignored by the on-board.

3.12.4.3 On reception of a new MA (with or without Mode Profile) the on-board equipment shall delete the currently supervised Mode Profile.

3.12.4.3.1 Exception: When receiving a new MA by infill,

   - a) any currently supervised OS/LS Mode Profile shall be deleted only beyond the reference location of the infill information;

   - b) in case the infill location reference is in rear of or at the start location of a currently supervised SH Mode Profile, this currently supervised SH Mode Profile shall be deleted;

   - c) in case the infill location reference is in advance of the start location of a currently supervised SH Mode Profile, any Mode Profile and, if any, a list of balise groups for SH area included in this infill MA shall be ignored by the on-board equipment. No deletion of this currently supervised SH Mode Profile shall take place in this case.

3.12.4.4 In case the SH Mode Profile is deleted for another reason than entering SH mode, the corresponding list of balise groups for SH area shall be deleted.

3.12.4.5 The beginning of the Mode Profile relates to the max safe front end of the train.

3.12.4.6 The end of the mode profile relates to the min safe front end of the train.

3.12.4.7 Until the ERTMS/ETCS on-board equipment has switched to the concerned mode, it shall consider the beginning of the Mode Profile as a temporary EOA. The ERTMS/ETCS on-board equipment shall only for the cases below consider a temporary SvL with no release speed that is at a location:

   - a) At the beginning of the Mode Profile if it is required by the Mode Profile.

   - b) That is determined in accordance with 3.8.4.5 as if no LOA had been given, if it is required that no temporary SvL is to be considered with respect to the Mode Profile and the MA defines an LOA located in advance of or at the start of the Mode Profile.

<!-- end of page 113 -->

   - c) At the beginning of the Mode Profile, if it is required that no temporary SvL is to be considered with respect to the Mode Profile and the MA defines an LOA located in rear of the start of the Mode Profile.

3.12.4.7.1 Note: No temporary SvL results from the Mode Profile if it requires that no temporary SvL is to be considered with respect to it and the MA defines an EOA.

3.12.4.8 See clause 3.12.2.5.

**3.12.5 Level Crossings**

3.12.5.1 It shall be possible for trackside to inform the ERTMS/ETCS on-board equipment about the conditions under which a Level Crossing (LX) must be passed.

3.12.5.2 Each Level Crossing shall have an identity, so that all LX information is independent of each other. This means that an individual LX information cannot affect, nor be affected by, any other individual LX information.

3.12.5.3 If the ERTMS/ETCS on-board equipment receives a new LX information with the same identity as an already received LX information, the new LX information shall replace the previous one.

3.12.5.4 Level Crossing information shall be given as profile data, corresponding to the LX start location and the length of the LX area.

3.12.5.5 Level Crossing information shall indicate whether the LX is protected or not.

3.12.5.6 In case the LX is not protected, ERTMS/ETCS on-board equipment shall be informed: a) at which speed the LX is allowed to be passed

   - b) whether the stopping of the train in rear of the LX start location is required or not

3.12.5.7 In case stopping in rear of the non protected LX is required, a stopping area in rear of the LX start location shall be defined.

3.12.5.8 In case the LX is not protected, the ERTMS/ETCS on-board equipment shall consider the LX start location as both temporary EOA and SvL, with no release speed. See section 5.16 for other detailed requirements.

3.12.5.9 See clause 3.12.2.5.
