## **3.15 Special functions**

**3.15.1 RBC/RBC Handover**

**3.15.1.1 Introduction**

3.15.1.1.1 The RBC/RBC Handover principles are such that trains are able to pass from one RBC area to another automatically (without driver action).

3.15.1.1.2 This is also granted when, due to a failure in the GSM-R on-board radio communication system, the on-board is no longer able to manage two communication sessions established through GSM-R at once, while the communication session with the Handing Over RBC has been established through GSM-R and the communication session with the Accepting RBC can only be established through GSM-R. Thereby, the behaviour of the RBCs is independent from such on-board degraded situation.

3.15.1.1.3 However, such an RBC/RBC handover performed by a train with only one communication session established through GSM-R at once may result in performance penalties since it will not be able to “prepare” (session establishment, version determination, …) the expected supervision by the Accepting RBC until the on-board disconnects from the Handing Over RBC.

3.15.1.1.4 Intentionally deleted.

3.15.1.1.5 For successive RBC/RBC handovers, it shall be possible for an RBC to act as the Accepting and as the Handing Over RBC for the same engine at different RBC/RBC border locations simultaneously.

3.15.1.1.5.1 Note: Successive RBC/RBC handover means that the trackside initiates another handover procedure while an ongoing handover has not finished. However, from the ERTMS/ETCS on-board point of view, there is only one handover at a time.

3.15.1.1.5.2 Note: An RBC acting as both Accepting and Handing Over RBC for the same engine may as Accepting RBC forward all or parts of route related information it receives as Handing Over RBC, but if and how this is done is intentionally not specified.

3.15.1.1.6 In an RBC/RBC handover, the Accepting RBC is defined by the RBC transition order, while the Handing Over RBC is the RBC which the ERTMS/ETCS on-board equipment considers as the supervising RBC when receiving an RBC transition order.

3.15.1.1.6.1 Exception: clause 3.15.1.3.2 describes a situation when the current Accepting RBC becomes the new Handing Over RBC.

**3.15.1.2 Handing Over RBC**

3.15.1.2.1 When the Handing Over RBC detects that a route is set for a train to enter another RBC area, it shall send:

<!-- end of page 182 -->

   - a) Intentionally deleted.

   - b) To the Accepting RBC the following information:

   - The ETCS identity of the on-board equipment;

   - The border location that will be passed by the train when entering the Accepting RBC area;

   - Current mode of the on-board equipment;

   - For a leading engine performing a mission in a mode different from Supervised Manoeuvre, Train Data and Train Running Number;

   - For an engine in Supervised Manoeuvre mode, safe consist length information and default Train Data;

   - The system versions supported by the on-board equipment;

   - Optionally, for a non-leading engine, the ETCS identity of the leading engine.

3.15.1.2.1.1 Exception: for successive handovers, an RBC already acting as Accepting RBC for the engine shall only send this information to the next Accepting RBC after the information about the train has been received from the ERTMS/ETCS on-board equipment.

3.15.1.2.2 Intentionally deleted.

3.15.1.2.3 It shall be possible for the Handing Over RBC to request route related information from the Accepting RBC, limited to a maximum amount of data.

3.15.1.2.3.1 Route related information is :

   - a) Movement authorities

   - b) Linking

   - c) International static speed profiles

   - d) Axle Load Speed profiles

   - e) Gradients

   - f) Temporary speed restrictions

   - g) Mode profiles

   - h) Temporary speed restriction revocations

   - i) Track Conditions

   - j) Level Transition orders

   - k) Intentionally deleted

   - l) Route Suitability Data

   - m)  National Values

   - n) Adhesion Factor

<!-- end of page 183 -->

   - o) Level Crossings

   - p) Permitted Braking Distance Information

3.15.1.2.3.2 Note: The amount of information to be sent between the RBCs is depending on the implementation trackside.

3.15.1.2.4 The Handing Over RBC shall send information to an on-board equipment concerning the route in advance of the border only if this information has been received from the Accepting RBC in the Route related information.

3.15.1.2.4.1 Note: Route related information received from the Accepting RBC will be processed by the Handing Over RBC if possible.

3.15.1.2.5 Deleted.

3.15.1.2.6 When the Handing Over RBC receives a position report and detects that the maximum safe front end of the train has passed the border location, it shall inform the Accepting RBC.

3.15.1.2.6.1 Note: This information might be needed to inform the signalman of the Accepting RBC that the train has entered the Accepting RBC area.

3.15.1.2.7 It is a trackside implementation issue to decide when it is appropriate to send the session termination order to the on-board equipment, e.g. when the Handing Over RBC receives a position report and detects that the minimum safe rear end of the train has passed the border, or after the RBC has received a train integrity confirmation indicating that the confirmed rear end of the train has passed the border.

3.15.1.2.8 When the Accepting RBC informs the Handing Over RBC that it has taken over the responsibility, the latter shall stop sending route related information to the on-board equipment.

3.15.1.2.9 When the Handing Over RBC detects that the transition to the Accepting RBC has to be cancelled, it shall send this cancellation information to the Accepting RBC (including the train identification).

3.15.1.2.9.1 Note: For instance, the cancellation procedure can be triggered by:

   - Change to a route which does no more include the border;

   - The need to initiate a Supervised Manoeuvre procedure, after the RBC-RBC handover has been engaged with an on-board equipment in a mode different from Supervised Manoeuvre;

   - The sending of an “end of mission” information from the on-board equipment.

#### **3.15.1.3 On-board equipment**

3.15.1.3.1  Following the reception of an order to switch to another RBC at a given location, the onboard equipment shall:

a) Immediately establish the communication session with the Accepting RBC;

<!-- end of page 184 -->

   - b) Send a position report to the Handing Over RBC when the maximum safe front end of the train passes the given location;

   - c) Send a position report to the Handing Over RBC when the minimum safe rear end of the train passes the given location;

3.15.1.3.2 Exception to 3.15.1.3.1 a) (degraded situation), only if the following conditions are fulfilled:

   - a) the GSM-R radio system is installed on-board, AND

   - b) the on-board equipment is able to handle only one communication session established through GSM-R at a given time, AND

   - c) the communication session with the Handing Over RBC has been established through GSM-R, AND

   - d) the Radio Network type is GSM-R or is FRMCS+GSM-R while the RBC transition order does not relate to an RBC interfaced with FRMCS only,

the ERTMS/ETCS on-board equipment shall wait until the session with the Handing over RBC is terminated due to crossing the border, apply the clause 3.5.6.6 (if relevant), and then establish the session with the Accepting RBC after successful registration of the GSM-R Mobile Terminal to the new GSM-R Radio Network (if relevant).

3.15.1.3.2.1 Justification: in case of loss of safe radio connection with the Handing over RBC, the only GSM-R Mobile Terminal still available cannot be pre-empted to set-up a safe radio connection with the Accepting RBC as long as the Handing over RBC is the supervising one.

3.15.1.3.2.2 The ERTMS/ETCS on-board equipment shall manage only one RBC/RBC handover at a time, therefore a new RBC transition order shall replace a previously received order.

3.15.1.3.2.3 If, whilst in session with both the Handing Over RBC and the Accepting RBC, the ERTMS/ETCS on-board equipment receives a new RBC transition order with an Accepting RBC different than the current one from the RBC/RBC handover already engaged, the communication session with the RBC which is not the currently supervising RBC shall be terminated, while the currently supervising RBC remains or becomes the Handing Over RBC. Then after the clauses 3.15.1.3.1 and 3.15.1.3.2 (if relevant) shall be applied again for the new pair of Handing Over RBC/Accepting RBC.

3.15.1.3.2.4 Exception to 3.15.1.3.2: If, while waiting until the communication session with the Handing over RBC is terminated due to crossing the border, the on-board receives a new RBC transition order with an Accepting RBC different than the current one as per the RBC/RBC handover already engaged and if the maximum safe front end of the train has left the area of the current Handing Over RBC when this new RBC transition order is received, the communication session with the current Handing Over RBC shall be terminated, the registration of its GSM-R Mobile Terminal in working condition to the ordered GSM-R Radio Network (if any) shall be performed (see 3.5.6.6), and the communication session shall be established with the Accepting RBC from the previous RBC transition order, which becomes the new Handing Over RBC. Then after, the

<!-- end of page 185 -->

clauses 3.15.1.3.1 and 3.15.1.3.2 (if relevant) shall be applied again for the new pair of Handing Over RBC/Accepting RBC.

3.15.1.3.3 As soon as the on-board equipment has established the session with the Accepting RBC, it shall send its valid Train Data if available. If in Supervised Manoeuvre mode, it shall send its safe consist length information instead.

3.15.1.3.4 When the on-board equipment is connected to both RBCs, it shall send its position reports to both of them with the use of the position report parameters valid for the Handing Over RBC.

3.15.1.3.4.1 If the on-board equipment is connected to both RBCs, and it executes an End of Mission, it shall execute the End of Mission procedure with both RBCs.

3.15.1.3.5 As soon as the on-board sends a position report directly to the Accepting RBC with its maximum safe front end having passed the border, it shall use information received from the Accepting RBC, which is now considered to be the supervising RBC, and only a disconnection order shall be accepted from the Handing Over RBC.

3.15.1.3.5.1 Intentionally deleted.

3.15.1.3.6 While both communication sessions are opened, if information is received from the Accepting RBC before a position report is sent to the Accepting RBC with the maximum safe front end having passed the border, this information shall be stored on-board. Exception: The acknowledgement of Train Data shall be immediately accepted by the on-board equipment.

3.15.1.3.6.1 Note: for the exhaustive list of accepted/rejected information, please refer to Chapter 4 Use of received information.

3.15.1.3.7 When the train front end passes the announced border or when an order to execute the RBC transition immediately is received, the on-board shall substitute the current valid RBC contact information with those of the Accepting RBC.

3.15.1.3.8 After this substitution, the on-board shall however retain the RBC contact information of the Handing Over RBC until at least one of the following conditions is fulfilled:

   - a) The communication session with this Handing Over RBC has been terminated,

   - b) The RBC transition order is deleted according to 4.10.

3.15.1.3.8.1 Note: Even after the train front end has passed the border, the on-board may have to maintain the communication session with the Handing Over RBC (see 3.5.4) or reestablish it (see 3.5.3.4 f)) and needs therefore to remember the RBC contact information of this RBC.

3.15.1.3.9 In case the ERTMS/ETCS on-board equipment has reported that the train has passed with its min safe rear end the announced border and no order to terminate the session is received from the Handing Over RBC within a fixed waiting time (see Appendix A.3.1) from the time the position report was sent, it shall repeatedly send a position report with the fixed waiting time after each repetition, until the order to terminate the session is

<!-- end of page 186 -->

received, or the defined number of repetitions (see Appendix A.3.1) has been reached. If no reply is received within the fixed waiting time after the last repetition, the ERTMS/ETCS on-board equipment shall terminate the communication session with the Handing Over RBC.

#### **3.15.1.4 Accepting RBC**

3.15.1.4.1 The Accepting RBC shall keep route related information sent to the Handing Over RBC updated. In particular, this possibly includes temporary speed restrictions.

3.15.1.4.2 As soon as the Accepting RBC receives from the on-board equipment a position report and detects that the maximum safe front end of the train has passed the border, it shall inform the Handing Over RBC that it has taken over the responsibility.

3.15.1.4.3 When the Accepting RBC receives Train Data from both the on-board equipment and the Handing over RBC Train Data provided by the on-board equipment shall take precedence.

3.15.1.4.4 If the Accepting RBC receives a cancellation information from the Handing Over RBC, it shall send an order to terminate the communication session to the corresponding onboard equipment (if already established).

3.15.1.4.5 The Accepting RBC shall comply with the maximum amount of data contained in the last received route related information request from the Handing Over RBC.

3.15.1.4.6 An Accepting RBC shall only give a transition order for a successive RBC/RBC handover after the on-board has reported as LRBG the balise group at the RBC/RBC border for the already ongoing RBC/RBC handover or a balise group in advance of that border.

**3.15.1.5 RBC/RBC message acknowledgement**

3.15.1.5.1 As soon as a consistent RBC/RBC message including the request for acknowledgement is received, the receiving RBC shall send an acknowledgement to the emitting RBC.

3.15.1.5.2 The RBC/RBC message is consistent when all checks have been completed successfully:

   - a) It has passed the checks performed by the RBC/RBC Safe Communication Interface protocol (see SUBSET-098);

   - b) Variables in the message do not have invalid values.

3.15.1.5.3 The acknowledgement message shall refer to the identity of the concerned message sent by the emitting RBC.

### **3.15.2 Handling of Trains with Non Leading Engines**

3.15.2.1 It is possible to operate a train using more than one engine, each engine being under the control of a driver.

3.15.2.2 Only the leading engine is responsible for the train movement supervision functions.

<!-- end of page 187 -->

### **3.15.3 Splitting/joining**

3.15.3.1 ERTMS/ETCS allows Splitting and Joining using the normal supervision functions available (e.g. On-sight, Shunting).

3.15.3.2 Splitting only refers to the case that the two resulting trains contain at least one ERTMS/ETCS on-board equipment each.

3.15.3.2.1 Note: This must be ensured by operational procedures.

3.15.3.3 ERTMS/ETCS is not responsible for providing information that a Splitting/Joining operation has been correctly completed (technical aspect and/or operational aspect).

3.15.3.4 Justification: ERTMS/ETCS is not able to provide this information. Splitting and Joining requires the fulfilment of operating rules ensuring that a Splitting/Joining operation has been correctly completed (e.g. physical disconnection).

### **3.15.4 Reversing of movement direction**

3.15.4.1 It shall be possible to send in advance to an on-board equipment information about areas, where initiation of reversing of movement direction is possible, i.e. change the direction of train movement without changing the train orientation.

3.15.4.1.1 A new reversing area given from the trackside shall replace the one already available on-board.

3.15.4.2 Together with start and end of reversing area, the following supervision information shall be sent:

   - a) Maximum distance to run in the direction opposite to the orientation of the reversing area, the fixed reference location being the end location of the area where reversing of movement is permitted with which the maximum distance information is sent.

   - b) Reversing mode speed limit allowed during reverse movement.

<!-- Start of picture text -->
End location for<br>reversing  Start  End<br>distance<br>Reversing area<br>Reference<br>location for<br>Maximum distance to run in  reversing<br>reverse movement  distance<br><!-- End of picture text -->

**Figure 57: Reversing area and maximum distance to run**

3.15.4.2.1 The ERTMS/ETCS on-board equipment shall use as fixed reference location for reversing distance the end location of the reversing area with which the maximum distance information is received. This fixed reference location shall remain unchanged until a new reversing area is received.

<!-- end of page 188 -->

3.15.4.2.1.1 Example 1: If a closer SvL is defined, see Appendix A.3.4 for a complete list of situations, the reversing area is deleted beyond the new SvL. The reference location for the distance to run in the direction opposite to the reversing area remains fixed at its original position.

3.15.4.2.1.2 Example 2: the fixed reference location remains also unchanged in case of update of distance to run in reverse movement without receiving a new reversing area.

<!-- Start of picture text -->
EoA of<br>New end location  shortened<br>for reversing  MA<br>distance<br>Shortened reversing<br>area<br>Reference<br>Previous maximum distance<br>location for<br>to run in reverse movement<br>reversing<br>distance<br>New maximum distance to run in reverse movement<br><!-- End of picture text -->

#### **Figure 58: Influence of a shortened Movement Authority and of a renewal of the maximum distance to run**

3.15.4.2.2 Note: All locations refer to the estimated front end of the train (refer to clause 3.6.4.6).

3.15.4.3 New distance to run and Reversing mode speed limit given from the trackside shall replace the one already available on-board.

3.15.4.3.1 Intentionally deleted.

#### **Figure 59: Intentionally deleted**

3.15.4.4 While at standstill with the front end of the train inside the indicated area, it shall be possible for the driver to reverse the direction of movement.

3.15.4.5 The on-board equipment shall allow movement in the direction opposite to the train orientation, supervising it according to distance and speed received.

3.15.4.6 Note: level transitions and RBC/RBC handovers are not handled by the ERTMS/ETCS on-board equipment when in Reversing mode.

3.15.4.7 When at standstill the on-board equipment shall inform the driver if the reversing of movement is permitted.

3.15.4.8 If the end location of the maximum distance to run in the opposite direction is passed by the train front end, the emergency brake command shall be triggered.

<!-- end of page 189 -->

### **3.15.5 Track ahead free**

3.15.5.1 In a level 2 area, the ERTMS/ETCS on-board equipment is able to handle a track ahead free request given by the RBC.

3.15.5.2 The track ahead free request from the RBC shall indicate to the on-board

   - a) at which location the ERTMS/ETCS on-board equipment shall begin to display the request to the driver.

   - b) at which location the ERTMS/ETCS on-board equipment shall stop to display the request to the driver (in case the driver did not acknowledge).

3.15.5.3 As long as it is displayed, the driver has the possibility to acknowledge the track ahead free request (meaning the driver confirms that the track between the head of the train and the next signal or board marking signal position is free).

3.15.5.4 When the driver acknowledges, the ERTMS/ETCS on-board equipment shall stop displaying the request, and shall inform the RBC that the track ahead is free.

3.15.5.5 There is no restrictive consequence by the on-board system if the driver does not acknowledge.

3.15.5.6 A new track ahead free request shall replace the one previously received and stored.

### **3.15.6 Handling of National Systems**

3.15.6.1 The ERTMS/ETCS on-board supports driving on national infrastructure under the supervision of National Systems.

3.15.6.2 In case the ERTMS/ETCS on-board equipment is interfaced to a National System through an STM, refer to Subset 035 for detailed requirements.

3.15.6.2.1 Intentionally deleted.

3.15.6.3 Intentionally deleted.

3.15.6.4 Intentionally deleted.

3.15.6.5 Amongst the data to be used by applications outside ERTMS/ETCS that can be transmitted by trackside over the ERTMS/ETCS transmission channels, it shall be possible, only from balise as non-infill information or from RBC, to identify a National System to which the data will be forwarded by the ERTMS/ETCS on-board equipment in case it is interfaced to this National System through an STM.

3.15.6.5.1 Note: In case the ERTMS/ETCS on-board equipment is not interfaced to the concerned National System through an STM, the way the data is forwarded to the National System is outside the scope of the ERTMS/ETCS specifications. However, the trackside has to take into account that any ERTMS/ETCS on-board equipment interfaced to the concerned National System through an STM will apply all the applicable ERTMS/ETCS rules to the balise group/RBC message that includes this data.

<!-- end of page 190 -->

### **3.15.7 Tolerance of Big Metal Mass**

3.15.7.1 Big metal object in the track, exceeding the limits for big metal masses as defined in Subset-036, section 6.5.2 “Metal Masses in the Track” may trigger an alarm (called “Integrity check alarm of balise transmission”, and referred in the following as “BTM alarm” in short) reporting a malfunction for the onboard balise transmission function.

3.15.7.2 In Levels 0/NTC, the alarms which may be triggered by metal masses shall be ignored for a defined distance (see A.3.1). If the alarm persists for a longer distance the ERTMS/ETCS on-board equipment shall trigger a safety reaction.

3.15.7.3 Justification: Ignoring the alarm for a defined distance eliminates the need to equip all excessive big metal masses with track condition “Big Metal Mass” outside ETCS fitted areas.

3.15.7.4 In Levels 1/2, the BTM alarms which may be triggered by metal masses shall be ignored in any of the following cases: a) if the “BTM alarm reaction inhibition” is active (see procedure in 5.22), or b) if mode is Stand-By.

3.15.7.5 In all Levels, the BTM alarms which may be triggered by metal masses shall be ignored if the track condition “Big Metal Mass” is applicable for the given location (see 3.12.1.3, 9<sup>th</sup> bullet).

3.15.7.6 If the BTM alarm is triggered and not ignored according to 3.15.7.4 or 3.15.7.5, the ERTMS/ETCS on-board equipment shall trigger a safety reaction.

3.15.7.6.1 Note: the on-board reaction is left to specific implementation because it contributes to the attainment of the global on-board THR, whose apportionment is on-boardimplementation specific.

### **3.15.8 Cold Movement Detection**

3.15.8.1 After being switched off (i.e. once in No Power mode), the ERTMS/ETCS on-board equipment shall be capable, if fitted with, to detect and record whether the engine has been moved or not, during a period of at least 72 hours.

3.15.8.1.1 To allow small movements e.g. for coupling in No Power mode, the ERTMS/ETCS onboard equipment shall consider that no cold movement has occurred as long as the train does not move for more than 2m away from the train position stored when No Power mode was entered.

3.15.8.2 When powered on again, the ERTMS/ETCS on-board equipment shall use, if available, the memorised information about cold movement in order to update the status of information stored by on-board equipment (see chapter 4 section 4.11 for details).

3.15.8.3 Note: information memorised by Cold Movement Detection function is considered as not available if:

<!-- end of page 191 -->

- a) no Cold Movement Detection function is implemented in the ERTMS/ETCS on-board equipment, OR

- b) the Cold Movement Detection function has encountered a condition, during the No Power period, which prevents the use of the Cold Movement information (e.g. the battery ensuring the Cold Movement Detection function has run down during the No Power period).

### **3.15.9 Virtual Balise Cover**

3.15.9.1 It shall be possible to set and remove from balise a Virtual Balise Cover (VBC). A VBC is defined by:

   - a) A marker corresponding to balises to be ignored by the on-board together with the area (country or region) in which the VBC is applicable. The VBC marker and the country/region identity form the unique VBC identity.

   - b) Its validity period.

3.15.9.2 During a start of mission, the driver shall have the opportunity to set a new VBC, or to remove an existing one.

3.15.9.3 As long as a VBC is stored on-board:

   - a) While applying any other clause (with the exception of the ones of section 3.20 "Juridical data") than this one, the ERTMS/ETCS on-board equipment shall consider any balise telegram that includes a VBC marker and a country/region identity that both match the VBC identity as not received (i.e. as if the balise was physically covered).

   - b) As a consequence, no reaction will be applied if errors in the reading of the rest of such balise telegram occur.

3.15.9.3.1 Since it relies on the system version number of the telegram itself (see chapter 6 for details), the check stipulated in 3.15.9.3 a) shall prevail on any system version number related check specified in the section 3.17, with the exception of 3.17.3.5 a).

3.15.9.4 If the ERTMS/ETCS on-board equipment receives from balise or from driver a new VBC with the same VBC identity as an already stored VBC, the new VBC shall replace the previous one, including its validity period.

3.15.9.5 A VBC shall be retained on-board when the on-board equipment is switched off (i.e. enters No Power mode) and shall remain applicable when powered on again. It shall be deleted when:

   - a) it is ordered by trackside, or

   - b) its validity period has elapsed, or

   - c) it is removed by the driver (during Start of Mission), or

   - d) a mismatch is detected between the country/region identity read from a balise group and the country/region identity of the VBC. Note: this means that the reception of a

<!-- end of page 192 -->

consistent balise group message is a necessary condition for deleting a VBC due to mismatching country/region identities.

3.15.9.6 The validity period shall start at the time the balise group message is received or shall start at the time the VBC is entered by the driver.

### **3.15.10 Advance display of route related information**

3.15.10.1 The ERTMS/ETCS on-board equipment shall display an overview of the gradient profile (as received from trackside), of the MRSP, of the track conditions (except the tunnel stopping areas, big metal masses, changes of allowed current consumption and station platforms), of the first Indication location, if any (only in Ceiling Speed monitoring), and of the EOA/LOA, with the remaining distances referred to the train front end position.

3.15.10.2 With regards to the MRSP, the track conditions and the EOA/LOA, the remaining distances shall be computed taking into account the min safe, the estimated or the max safe train front end position depending on their respective supervision.

3.15.10.3 With regards to the gradient profile, the remaining distances shall be computed taking into account the estimated train front end position.

3.15.10.3.1 With regards to the first Indication location, the remaining distance shall be computed as specified in clauses 3.13.10.3.8 and 3.13.10.3.8.1.

3.15.10.4 The overview of route related information shall be restricted to the elements contained within the movement authority and up to the first target at zero speed, if any.

3.15.10.5 When the ERTMS/ETCS on-board equipment applies at least one of the clauses 3.12.2.4, 3.12.4.7 and 3.12.5.8, the term EOA in this section 3.15.10 shall refer to the closest location amongst the temporary EOA(s) and the EOA.

### **3.15.11 Driving with Automatic Train Operation**

3.15.11.1 In case it is interfaced to an ERTMS/ATO on-board, the ERTMS/ETCS on-board equipment supports automatic driving on lines fitted with an ERTMS/ATO trackside subsystem.

3.15.11.2 The driver shall have the possibility, through an ATO selector, to enable/disable the automatic driving and the display of the information related to the ERTMS/ATO subsystem, with the exception of the ATO data entry/view. The ATO selector position ("On" or "Stand-by") applicable when the ERTMS/ETCS on-board equipment is switched off (i.e. enters No Power mode) shall be retained and shall remain applicable when powered on.

3.15.11.3 For detailed requirements in case the ERTMS/ETCS on-board equipment is interfaced to an ERTMS/ATO on-board, refer to chapter 4 and SUBSET-125.

<!-- end of page 193 -->
