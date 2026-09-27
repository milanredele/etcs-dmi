# **ERTMS/ETCS**

**System Requirements Specification Chapter 2 Basic System Description**

REF  :  SUBSET-026-2 ISSUE :

4.0.0 DATE : 05/07/2023

<!-- end of page 1 -->

# **2.1 Modification History**

|Issue Number<br>Date|Section Number|Modification / Description|Author|
|---|---|---|---|
|0.0.1<br>19 july 1999|All|First class 1 draft using new<br>templates<br>and<br>including<br>contributions from WPs|PZ|
|0.1.0<br>26 july 1999|System<br>architecture<br>figure<br>§ 2.3.1.2|Updating and introduction of<br>Radio infill<br>Reference to future class 1<br>deleted|PZ|
|1.0.0<br>29 July 1999|Document<br>version,<br>editorial<br>changes,<br>updating<br>the<br>architecture figure.|Finalisation<br>in<br>Stuttgart<br>990729|HE|
|1.2.0<br>990730|Version number|Release version|HE|
|1.2.1<br>991209|All|Draft for 2<sup>nd</sup>release|SAB|
|1.3.0<br>9912016|All|Review comments added|SAB|
|2.0.0<br>991222|Minor editing|Finalisation|SAB|
|2.0.1|All|Corrections after review|SAB|
|2.1.0|Minor editing|UNISIG release|SAB|
|2.2.0|Version number|UNISIG release|SAB|
|2.2.2|Version number|Final edition|Ch. Frerichs|
|1.2.2002||||
|2.3.0|Version number|Release version|HK|
|24/02/06|No change since 2.2.2|||
|2.3.2<br>17/03/08|Including CRs that are<br>in<br>state<br>“Analysis<br>completed” according<br>to ERA CCM|Working version|AH|
|3.0.0<br>23/12/08|Version number<br>No change since 2.3.2|Release version|AH|

<!-- end of page 2 -->

|3.0.1||Including the results of the<br>|AH|
|---|---|---|---|
|22/12/09||editorial review of the SRS<br>3.0.0 and the other error<br>CR’s<br>that<br>are<br>in state<br>“Analysis<br>completed”<br>according to ERA CCM||
|3.1.0<br>22/02/10||Release version|AH|
|3.1.1<br>08/11/10||Including all CR’s that are in<br>state “Analysis completed”<br>according to ERA CCM|AH|
|3.2.0<br>22/12/10|No change|Release version|AH|
|3.2.1<br>13/12/11||Including all CR’s that are in<br>state “Analysis completed”<br>according to ERA CCM|AH|
|3.3.0<br>07/03/12||Baseline 3 release version|AH|
|3.3.1<br>04/04/14|No change||OG|
|3.3.2<br>23/04/14|No change|Baseline 3 1<sup>st</sup>maintenance<br>pre-release version|OG|
|3.3.3<br>06/05/14|No change|Baseline 3 1<sup>st</sup>maintenance<br>2<sup>nd</sup>pre-release version|OG|
|3.4.0<br>12/05/14|No change|Baseline 3 1<sup>st</sup>maintenance<br>release version|OG|
|3.4.1<br>23/06/15|CR1236||OG|
|3.4.2<br>17/11/15|CR’s 1237, 1265||OG|
|3.4.3<br>16/12/15|No change||OG|
|3.5.0<br>18/12/15|Baseline 3 2<sup>nd</sup>release<br>(see ERA-REC-123-2|version as recommended to EC<br>015/REC)|AH|
|3.5.1<br>28/04/16|No change||OG|

<!-- end of page 3 -->

|3.6.0<br>13/05/16|Baseline 3 2<sup>nd</sup>release version|AH|
|---|---|---|
|3.6.1<br>29/05/17|No change|OG|
|3.6.2<br>31/05/18|No change|OG|
|3.6.3<br>21/02/20|No change|AH|
|3.6.4<br>22/06/20|No change|AH<br>OG|
|3.6.5<br>22/12/21|CR 1238|AH<br>OG|
|3.6.6<br>29/08/22|CR’s 1238 (updated), 1342|AH<br>OG|
|3.9.1|CR 1174|AH|
|24/11/22||OG|
|3.9.2|No change|AH|
|21/02/23||OG|
|3.9.3|CR 1359|AH|
|31/05/23|Outcome of B4R1 3<sup>rd</sup>consolidation phase|OG|
|3.9.4|CR 1342 (updated)|AH|
|30/06/23||OG|
|4.0.0<br>05/07/23|Baseline 4 1<sup>st</sup>release version|AH<br>OG|

<!-- end of page 4 -->

|**2.2**|**Table of Contents**|
|---|---|
|2.1|Modification History ........................................................................................................... 2|
|2.2|Table of Contents .............................................................................................................. 5|
|2.3|Introduction ....................................................................................................................... 6|
|2.3|.1<br>Scope and purpose .................................................................................................... 6|
|2.4|System structure ............................................................................................................... 7|
|2.5|Subsystems ...................................................................................................................... 8|
|2.5|.1<br>Trackside subsystem ................................................................................................. 8|
|2.5|.2<br>On-board subsystem .................................................................................................. 9|
|2.5|.3<br>ERTMS/ETCS reference architecture ...................................................................... 11|
|2.6|Levels and transitions ..................................................................................................... 12|
|2.6|.1<br>Introduction .............................................................................................................. 12|
|2.6|.2<br>Definitions ................................................................................................................ 12|
|2.6|.3<br>ERTMS/ETCS Application Level 0 ........................................................................... 14|
|2.6|.4<br>ERTMS/ETCS Application Level NTC ...................................................................... 16|
|2.6|.5<br>ERTMS/ETCS Application Level 1 ........................................................................... 18|
|2.6|.6<br>ERTMS/ETCS Application Level 2 ........................................................................... 21|
|2.6|.7<br>Intentionally deleted ................................................................................................. 24|
|2.6|.8<br>Level transitions ....................................................................................................... 25|

<!-- end of page 5 -->

# **2.3 Introduction**

## **2.3.1 Scope and purpose**

2.3.1.1 The present chapter gives the basic description of the **ERTMS/ETCS system** proposed to achieve technical interoperability.

<!-- end of page 6 -->

# **2.4 System structure**

2.4.1.1 Due to the nature of the required functions, the **ERTMS/ETCS system** will have to be partly on the trackside and partly on board the trains.

2.4.1.2 This defines two subsystems, the on-board subsystem and the trackside subsystem.

- 2.4.1.3

- The environment of ERTMS/ETCS system is composed of:

- a) the train with optionally a Train Integrity Monitoring System, which will then be considered in the train interface specification;

- b) the driver, which will then be considered via the driver interface specification;

- c) other onboard interfaces (see architecture drawing in 2.5.3);

- d) external trackside systems (interlockings, control centres, etc.), for which no interoperability requirement will be established.

<!-- end of page 7 -->

# **2.5 Subsystems**

## **2.5.1 Trackside subsystem**

2.5.1.1 Depending on the application level (see further sections), the trackside subsystem can be composed of:

   - a) balise

   - b) lineside electronic unit

   - c) the radio communication network(s) (FRMCS and/or GSM-R)

   - d) the Radio Block Centre (RBC)

   - e) Euroloop

   - f) Radio infill unit

   - g) Key Management Centre (KMC)

   - h) Public Key Infrastructure (PKI)

**2.5.1.2 Balise**

2.5.1.2.1 The balise is a transmission device that can send telegrams to the on-board subsystem.

2.5.1.2.2 The balise is based on the existing Eurobalise specifications. These documents are included in the frame of the ERTMS/ETCS specifications.

2.5.1.2.3 The balises provides the up-link, i. e. the possibility to send messages from trackside to the on-board subsystem.

2.5.1.2.4 The balises can provide fixed messages or, when connected to a lineside electronic unit, messages that can be changed.

2.5.1.2.5 The balises will be organised in groups, each balise transmitting a telegram and the combination of all telegrams defining the message sent by the balise group.

**2.5.1.3 Lineside electronic unit**

2.5.1.3.1 The lineside electronic units are electronic devices, that generate telegrams to be sent by balises, on basis of information received from external trackside systems.

**2.5.1.4 Trackside radio communication network(s) (FRMCS and/or GSM-R)**

2.5.1.4.1 The GSM-R radio communication network is used for the bi-directional exchange of messages between on-board subsystems and RBC or radio infill units.

2.5.1.4.2 The FRMCS radio communication network is used for the bi-directional exchange of messages between on-board subsystems and RBC.

**2.5.1.5 RBC**

<!-- end of page 8 -->

2.5.1.5.1 The RBC is a computer-based system that elaborates messages to be sent to the train on basis of information received from external trackside systems and on basis of information exchanged with the on-board subsystems.

2.5.1.5.2 The main objective of these messages is to provide movement authorities to allow the safe movement of trains on the Railway infrastructure area under the responsibility of the RBC.

2.5.1.5.3 The interoperability requirements for the RBC are mainly related to the data exchange between the RBC and the on-board subsystem.

2.5.1.5.4 The RBC can be interfaced to the FRMCS and/or GSM-R radio communication network(s).

**2.5.1.6 Euroloop** 2.5.1.6.1 The Euroloop subsystem operates on Level 1 lines, providing signalling information in advance as regard to the next main signal in the train running direction.

2.5.1.6.2 The Euroloop subsystem is composed of an on-board functionality and by one or more trackside parts.

**2.5.1.7 Radio infill Unit** 2.5.1.7.1 The RADIO INFILL subsystem operates on Level 1 lines, providing signalling information in advance as regard to the next main signal in the train running direction.

2.5.1.7.2 The RADIO INFILL subsystem is composed of an on-board functionality and by one or more trackside parts (named RADIO INFILL Unit).

**2.5.1.8 KMC** 2.5.1.8.1 The role of the KMC is to manage the cryptographic keys, which are used to secure the EURORADIO communications between the ERTMS/ETCS entities (ERTMS/ETCS onboard equipments, RBCs and RIUs).

**2.5.1.9 PKI** 2.5.1.9.1 The role of the PKI is to manage and distribute digital certificates, so as to allow a secure on-line distribution of cryptographic keys between KMCs and from a KMC to the ERTMS/ETCS entities (ERTMS/ETCS on-board equipments, RBCs and RIUs).

**2.5.2 On-board subsystem** 2.5.2.1 The on-board subsystem can be composed of: a) the ERTMS/ETCS on-board equipment; b) the on-board part of the FRMCS and/or GSM-R radio system(s); c) the ERTMS/ATO on-board equipment

<!-- end of page 9 -->

**2.5.2.2 ERTMS/ETCS on-board equipment**

2.5.2.2.1 The ERTMS/ETCS on-board equipment is a computer-based system that supervises the movement of the train to which it belongs, on basis of information exchanged with the trackside subsystem.

2.5.2.2.2 The interoperability requirements for the ERTMS/ETCS on-board equipment are related to the functionality and the data exchange between the trackside subsystems and the on-board subsystem and to the functional data exchange between the on-board subsystem and:

   - a) the driver;

   - b) the train;

   - c) the onboard part of the existing national train control system(s).

**2.5.2.3 Onboard radio communication system(s) (FRMCS and/or GSM-R)**

2.5.2.3.1 The GSM-R on-board radio system is used for the bi-directional exchange of messages between on-board subsystem and RBC or radio infill unit.

2.5.2.3.2 The FRMCS on-board radio system is used for the bi-directional exchange of messages between on-board subsystem and RBC.

**2.5.2.4 ERTMS/ATO on-board equipment**

2.5.2.4.1 The ERTMS/ATO on-board equipment is a computer-based system that can substitute the driver for acting on the traction/braking of the train, on the basis of information exchanged with the ERTMS/ETCS on-board equipment, with the ERTMS/ATO trackside subsystem and with the train (see SUBSET-125 for details).

<!-- end of page 10 -->

## **2.5.3 ERTMS/ETCS reference architecture**

<!-- Start of picture text -->
On-board<br>Train Driver<br>recording device<br>TIMS<br>SUBSET-034<br>SUBSET-027<br>SUBSET-119 ERA_ERTMS_015560 SUBSET-147<br>SUBSET-147<br>National<br>System(*) BIU    TIU DMI function Juridical data<br>STM ATO On-board<br>STM control  ATO control<br>Odometry<br>function function<br>or<br>Other<br>solution BTM LTM On-boardETCS EURORADIO SUBSET-037SUBSET-146<br>FRMCS FIS-7970<br>FRMCS FFFIS-7950<br>SUBSET-037 SUBSET-114<br>A11T6001 SUBSET-137<br>FRMCS SUBSET-146<br>on-board<br>GSM-R fixed  GSM-R<br>SUBSET-036 SUBSET-044 network Mobile FRMCS<br>trackside<br>SUBSET-037<br>SUBSET-146<br>SUBSET-037 FRMCS FIS-7970<br>FRMCS FFFIS-7950<br>National<br>EUROBALISE EUROLOOP<br>System<br>EURORADIO EURORADIO KMC 1<br>SUBSET-137<br>SUBSET-146<br>RIU RBC 1<br>SUBSET-036 SUBSET-044<br>SUBSET-039 PKI SUBSET-038<br>SUBSET-098 SUBSET-137<br>SUBSET-146<br>InterlockingLEU TracksideETCS RBC 2 SUBSET-137SUBSET-146<br>EURORADIO KMC 2<br>Control Centre<br>(*) Depending on its functionality and the desired configuration, the national system can be addressed either via an STM using<br>     the standard interface or via another national solution<br>SUBSET-139 SUBSET-147<br>SUBSET-035 SUBSET-056 SUBSET-057 SUBSET-058<br>SUBSET-125 SUBSET-130 SUBSET-143<br>SUBSET-101<br>SUBSET-114<br>SUBSET-114<br>SUBSET-146<br>SUBSET-146<br>SUBSET-137 SUBSET-146<br>SUBSET-137 SUBSET-146<br>SUBSET-137<br>SUBSET-114 SUBSET-137<br><!-- End of picture text -->

### **Figure 1: ERTMS/ETCS system and its interfaces**

2.5.3.1 Note: the entities inside the ERTMS/ETCS on-board equipment box are shown only to highlight the scope of the interfaces that are specified in the TSI CCS annex A.

<!-- end of page 11 -->

# **2.6 Levels and transitions**

## **2.6.1 Introduction**

2.6.1.1 The different ERTMS/ETCS application levels (short: levels) are a way to express the possible operating relationships between track and train. Level definitions are related to the trackside equipment used, to the way trackside information reaches the on-board units and to which functions are processed in the trackside and in the on-board equipment respectively.

2.6.1.2 Different levels have been defined to allow each individual railway administration to select the appropriate ERTMS/ETCS application trackside, according to their strategies, to their trackside infrastructure and to the required performance. Furthermore, the different application levels permit the interfacing of individual signalling systems and train control systems to ERTMS/ETCS.

2.6.1.3 For the purpose of a consistent specification a level 0 has been defined. This level is used for operation on non-equipped (unfitted) lines or on lines equipped with train control system(s) but operation under their supervision is currently not possible.

## **2.6.2 Definitions**

2.6.2.1 A train equipped with ERTMS/ETCS on-board equipment always co-operates with the ERTMS/ETCS trackside equipment in a defined ERTMS/ETCS level.

2.6.2.2 All transitions between levels are performed according to well-specified rules.

- 2.6.2.3

- ERTMS/ETCS can be configured to operate in one of the following application levels:

- ERTMS/ETCS Level 0 (train equipped with ERTMS/ETCS operating on a line not equipped with any train control system (ERTMS/ETCS or national system) or on a line equipped with ERTMS/ETCS and/or national system(s) but operation under their supervision is currently not possible)

- ERTMS/ETCS Level NTC (train equipped with ERTMS/ETCS operating on a line equipped with a national system)

- ERTMS/ETCS Application Level 1 with or without infill transmission (train equipped with ERTMS/ETCS operating on a line equipped with Eurobalises and optionally Euroloop or Radio infill)

- ERTMS/ETCS Application Level 2 (train equipped with ERTMS/ETCS operating on a line controlled by a Radio Block Centre and equipped with Eurobalises and Euroradio) with train detection and train separation performed by the Radio Block Centre based on information received from the train and/or by other trackside equipment outside the scope of ERTMS/ETCS

- Intentionally deleted

<!-- end of page 12 -->

2.6.2.4 It is possible to superimpose several application levels in parallel on the same track, for example parallel operation of a line with a national system and with ERTMS/ETCS level 1 or 2. Other examples might be a station which is shared by trains arriving over level 1 and level 2 lines (junctions).

2.6.2.5 Intentionally deleted.

- 2.6.2.6

   - Intentionally deleted.

2.6.2.7 It is possible to transmit information not intended for ERTMS/ETCS but for other systems over the ERTMS/ETCS transmission channels. This information is not used by ERTMS/ETCS.

<!-- end of page 13 -->

## **2.6.3 ERTMS/ETCS Application Level 0**

**2.6.3.1 General description**

2.6.3.1.1 Level 0 covers operation of ETCS equipped trains on lines not equipped with ETCS or national systems or on lines where trackside ERTMS/ETCS infrastructure and/or national systems may exist but operation under their supervision is currently not possible (e.g. commissioning or on-board/trackside failed components).

2.6.3.1.2 In Level 0 it is authorized to operate trains without any train control system and therefore line side optical signals or other means of signalling are used to give movement authorities to the driver.

2.6.3.1.3 ERTMS/ETCS on-board equipment provides no supervision except of the maximum design speed of a train and maximum speed permitted in unfitted areas.

2.6.3.1.4 Train detection and train separation are performed by the trackside equipment of the underlying signalling system (interlocking, track circuits etc.) and are outside the scope of ERTMS/ETCS.

2.6.3.1.5 Level 0 uses no track-train transmission except Eurobalises to announce/command level transitions. Eurobalises therefore still have to be read. No balise data except certain special commands are interpreted.

2.6.3.1.6 No supervisory information is indicated on the DMI except the train speed. Train data has to be entered in order not to have to stop a train at a level transition to ERTMS/ETCS equipped area and to supervise maximum train speed.

<!-- Start of picture text -->
ETCS<br>end of track segment<br><!-- End of picture text -->

- **Figure 2: ERTMS/ETCS Application Level 0**

**2.6.3.2 Summary of characteristics of Application Level 0**

2.6.3.2.1 Trackside equipment:

   - No ERTMS/ETCS trackside equipment is used except for Eurobalises to announce level transitions and other specific commands.

<!-- end of page 14 -->

2.6.3.2.2 Main ERTMS/ETCS trackside functions:

   - None.

2.6.3.2.3 On-board equipment:

   - ERTMS/ETCS Onboard equipment with Eurobalise transmission.

2.6.3.2.4 Main ERTMS/ETCS on-board functions:

   - Supervision of maximum train speed.

   - Supervision of maximum speed permitted in an unfitted area.

   - Reading of Eurobalises to detect level transitions and certain special commands. All other messages are rejected.

   - No cab signalling.

<!-- end of page 15 -->

## **2.6.4 ERTMS/ETCS Application Level NTC**

**2.6.4.1 General description**

2.6.4.1.1 Level NTC is used to run ERTMS/ETCS equipped trains on lines equipped with national train control and speed supervision systems.

2.6.4.1.2 Train control information generated trackside by the national train control system is transmitted to the train via the communication channels of the underlying national system.

2.6.4.1.3 Note: Lineside optical signals might be necessary or not, depending on the performance and functionality of the underlying systems.

2.6.4.1.4 Intentionally deleted.

2.6.4.1.5 The achievable level of supervision is similar to the one provided by the underlying national systems.

2.6.4.1.6 Train detection and train separation are performed by the trackside equipment of the underlying signalling system (interlocking, track circuits etc.) and are outside the scope of ERTMS/ETCS.

2.6.4.1.7 Level NTC uses no ERTMS/ETCS track-train information except to announce/command level transitions and specific commands related to balise transmission. Eurobalises therefore still have to be read.

2.6.4.1.8 The information displayed to the driver depends on the functionality of the underlying national system. The active national system is indicated to the driver as part of that information. Full train data has to be entered in order not to have to stop a train at a level transition position and to supervise maximum train speed.

2.6.4.1.9 A combination of national systems can be regarded as one NTC level.

2.6.4.1.10 Depending on the functionality and the configuration of the specific national system installed onboard, the ERTMS/ETCS Onboard system may need to be interfaced to it, in order to perform the transitions from/to the national system and/or in order to give access to ERTMS/ETCS Onboard resources (e.g. DMI). This can be achieved through a device called an STM (Specific Transmission Module) using a standardised interface.

2.6.4.1.11 Intentionally deleted.

<!-- end of page 16 -->

<!-- Start of picture text -->
Optional,<br>depending on<br>national<br>system<br>National<br>ETCS<br>System<br>existing national system  end of track segment<br><!-- End of picture text -->

### **Figure 3: ERTMS/ETCS Application Level NTC**

### **2.6.4.2 Summary of characteristics of Application Level NTC**

2.6.4.2.1 Trackside equipment:

   - Level NTC uses the track-train transmission system from an underlying national system, which is not part of ERTMS/ETCS.

   - For level transition purposes Eurobalises are used.

2.6.4.2.2 Main ERTMS/ETCS trackside functions:

   - None.

2.6.4.2.3 On-board equipment:

   - ERTMS/ETCS Onboard equipment with Eurobalise transmission.

   - Onboard part of the national system.

- 2.6.4.2.4

- Main ERTMS/ETCS on-board function:

- No train supervision, it is fully handed over to the national system.

- Reading of Eurobalises to detect level transitions and certain special commands. All other messages are rejected.

- Management of the national system through STM, in case the ERTMS/ETCS onboard equipment is interfaced to the national system through an STM.

<!-- end of page 17 -->

- No cab signalling.

## **2.6.5 ERTMS/ETCS Application Level 1**

**2.6.5.1 General description**

2.6.5.1.1 ERTMS/ETCS Level 1 is a spot transmission based train control system to be used as an overlay on an underlying signalling system.

2.6.5.1.2 Movement authorities are generated trackside and are transmitted to the train via Eurobalises.

2.6.5.1.3 ERTMS/ETCS Level 1 provides a continuous speed supervision system, which also protects against overrun of the authority.

2.6.5.1.4 Train detection and train separation are performed by the trackside equipment of the underlying signalling system (interlocking, track circuits etc.) and are outside the scope of ERTMS/ETCS.

2.6.5.1.5 Level 1 is based on Eurobalises as spot transmission devices.

2.6.5.1.6 The trackside equipment does not know the train to which it sends information.

2.6.5.1.7 If in level 1 a lineside signal clears, an approaching train can not receive this information until it passes the Eurobalise group at that signal. The driver therefore has to observe the lineside signal to know when to proceed. The train has then to be permitted to approach the stopping location below a maximum permitted release speed.

2.6.5.1.8 Additional Eurobalises can be placed between distant and main signals to transmit infill information, the train will receive new information before reaching the signal.

2.6.5.1.9 Note: Lineside signals are required in level 1 applications, except if semi-continuous infill is provided.

2.6.5.1.10 Semi-continuous infill can be provided using Euroloop or radio infill. In this case, the onboard system will be able to show new information to the driver as soon as it is available and even at standstill.

2.6.5.1.11 Euroloop or radio infill can improve the safety of a level 1 system as they allow the operation without release speed.

<!-- end of page 18 -->

<!-- Start of picture text -->
Interlocking<br>ETCS<br>LEU<br>Eurobalise end of track segment<br><!-- End of picture text -->

**Figure 4: ERTMS/ETCS Application Level 1 without infill function**

<!-- Start of picture text -->
Radio infill<br>ETCS Interlocking optional<br>LEU<br>Eurobalise Euroloop end of track segment<br><!-- End of picture text -->

**Figure 5: ERTMS/ETCS Application Level 1 with infill function by Euroloop or Radio infill**

<!-- end of page 19 -->

### **2.6.5.2 Summary of characteristics of Application Level 1**

2.6.5.2.1 Trackside equipment:

   - Eurobalises for spot transmission from track to train.

   - Eurobalises must be able to transmit variable information.

   - Semi continuous infill transmission by using Euroloop or radio infill is optional.

2.6.5.2.2 Main ERTMS/ETCS trackside function:

   - Determine movement authorities according to the underlying signalling system.

   - Transmit movement authorities and track description data to the train.

2.6.5.2.3 On-board equipment:

   - ERTMS/ETCS Onboard equipment with Eurobalise transmission and with:

      - Euroloop transmission if infill by Euroloop is required.

      - Radio infill transmission if infill by radio is required.

- The on-board part of the Radio Communication subsystem, if infill by radio is required

2.6.5.2.4 Main ERTMS/ETCS on-board function:

   - Reception of movement authority and track description related to the transmitting balise.

   - Selection of the most restrictive value of the different speeds permitted at each location ahead.

   - Calculation of a dynamic speed profile taking into account the train running/braking characteristics which are known on-board and the track description data.

   - Comparison of the train speed with the permitted speed and commanding of the brake application if necessary.

   - Cab signalling to the driver.

<!-- end of page 20 -->

## **2.6.6 ERTMS/ETCS Application Level 2**

**2.6.6.1 General description**

2.6.6.1.1 ERTMS/ETCS Level 2 is a radio based train control system which provides full cab signalling and does not require lineside signals.

2.6.6.1.1.1 Note: Lineside signals can still be implemented in ERTMS/ETCS level 2.

2.6.6.1.2 Movement authorities are generated trackside and are transmitted to the train via Euroradio.

2.6.6.1.3 ERTMS/ETCS Level 2 provides a continuous speed supervision system, which also protects against overrun of the authority.

2.6.6.1.4 Train detection and train separation can be performed by the Radio Block Centre (in cooperation with the train which sends position reports and train integrity information) and/or by other trackside equipment (interlocking, track circuits etc.), outside the scope of ERTMS/ETCS.

2.6.6.1.5 Level 2 is based on Euroradio for track to train communication and on Eurobalises as spot transmission devices mainly for location referencing.

2.6.6.1.6 The trackside radio block centre which provides the information to the trains knows each ERTMS/ETCS controlled train individually by the ERTMS/ETCS identity of its leading ERTMS/ETCS on-board equipment.

2.6.6.1.7 Intentionally deleted.

<!-- end of page 21 -->

<!-- Start of picture text -->
Radio Block Centre<br>Interlocking<br>Optional<br>Optional<br>train<br>ETCS<br>integrity<br>Eurobalise end of track segment<br>(optional)<br><!-- End of picture text -->

**Figure 6: ERTMS/ETCS Application Level 2**

### **2.6.6.2 Summary of characteristics of Application Level 2**

2.6.6.2.1 Trackside equipment:

   - Radio block centre with Euroradio for bi-directional track-train communication.

   - Eurobalises mainly for location referencing.

2.6.6.2.2 Main ERTMS/ETCS trackside function:

   - Knowing each train equipped with and running under ERTMS/ETCS within an RBC area by its ERTMS/ETCS identity.

   - Following each ERTMS/ETCS controlled train’s location within an RBC area.

   - Optionally, train detection and train separation.

   - Determine movement authorities for each train individually.

   - Transmit movement authorities and track description  to each train individually.

- Handing over of train control between different RBC’s at the RBC-RBC borders.

2.6.6.2.3 On-board equipment:

   - ERTMS/ETCS Onboard equipment with Eurobalise and Euroradio transmissions.

   - The on-board part of the Radio Communication subsystem(s) (FRMCS and/or GSMR).

<!-- end of page 22 -->

2.6.6.2.4 Main ERTMS/ETCS on-board function:

   - The train reads Eurobalises and sends its position relative to the detected balises to the radio block centre.

   - If the train is fitted with a Train Integrity Monitoring System (not part of ERTMS/ETCS) or if the train integrity is confirmed by the driver, the ERTMS/ETCS on-board sends the train integrity information to the Radio Block Centre.

   - The train receives a movement authority and the track description via Euroradio relating to a balise.

   - Selection of the most restrictive value of the different speeds permitted at each location ahead.

   - Calculation of a dynamic speed profile taking into account the train running/braking characteristics which are known on-board and the track description data.

   - Comparison of the train speed with the permitted speed and commanding of the brake application if necessary.

   - Cab signalling to the driver.

<!-- end of page 23 -->

## **2.6.7 Intentionally deleted**

<!-- end of page 24 -->

## **2.6.8 Level transitions**

2.6.8.1 An ERTMS/ETCS equipment which is not isolated always operates in one of the above described levels. All transitions between these levels are performed according to defined functions and procedures.

2.6.8.2 Additional national functions and rules which might be used by an individual railway to for example prevent not equipped trains from entering a level 2 area are not specified here and have to be implemented outside ERTMS/ETCS.

2.6.8.3 The following table shows all possible transitions (marked with Grey):

||to|0|NTC|1|2|
|---|---|---|---|---|---|
|from||||||
|0||||||
|NTC|||a)|||
|1<br>2|||||b)|

**Table 1: Possible level transitions.**

- a) Transitions between level NTC and level NTC describe the switching from one national system to another national system.

- b) Transitions between level 2 and level 2 describe the handover between RBC’s.

<!-- end of page 25 -->
