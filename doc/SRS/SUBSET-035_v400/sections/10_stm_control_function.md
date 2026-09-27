# **10. STM CONTROL FUNCTION**

## **10.1 General requirements**

10.1.1.1 It shall be possible to configure the ERTMS/ETCS on-board equipment with the list of STMs installed on-board.

10.1.1.2 The STM Control Function shall maintain a list of “available” STMs, which includes all STMs that have an established connection to the STM Control Function and report either CS, HS or DA state.

10.1.1.3 Level NTC X shall be considered as “Available for use” for level transition (see [1] paragraph 5.10.2.4.1) if the STM X associated to this level is available.

10.1.1.4 The STM Control Function shall send to the STM the following information when the connection to the STM is established:

   - a) The ERTMS/ETCS on-board functions that are available

   - b) The ETCS bus address of all available ERTMS/ETCS on-board functions

   - c) The safety level of all available ERTMS/ETCS on-board functions (see 6.2)

10.1.1.4.1 Note: Only Juridical Data and DMI channels 2, 3 & 4 can be marked as not available.

10.1.1.5 The STM Control Function shall inform the STM about the active DMI channel

   - a) whenever the active DMI channel changes,

   - b) whenever the connection to STM Control Function is established.

## **10.2 Association of STM X to Level NTC X**

10.2.1.1 The ERTMS/ETCS on-board shall be configurable with a look-up table that gives the correspondence between NID_NTC values and the NID_STM values of the STM(s) fitted on-board. For each NID_NTC value within this look-up table, a list of one or several NID_STM values shall be configured, with a priority order.

10.2.1.1.1 Note: A National System can cover the functionalities of other National Systems having their own NID_NTC values. For that case, the look-up table is needed to map the NID_NTC values corresponding to these encapsulated National Systems to the NID_STM value(s) of the STM(s) fitted on-board supporting them. But an entry in the look-up table is not needed for the case there is a one-to-one relation between NID_NTC value and NID_STM value.

10.2.1.1.2 Throughout this document, “STM X” stands for “STM associated to Level NTC X”. This STM is not necessarily fitted on-board.

10.2.1.2 If Level NTC X (defined by its NID_NTC) is not already associated to an STM, the ERTMS/ETCS on-board shall associate this Level NTC X to STM X as follows:

   - a) When a level transition order to Level NTC X is accepted,

<!-- end of page 52 -->

the STM X shall be the STM which NID_STM is equal to NID_NTC, if the level transition order is received from a trackside constituent with ETCS system version strictly lower than 2.0 or if the look-up table does not contain the NID_NTC value of Level NTC X.

Otherwise the STM X shall be the STM having the highest priority among the available STMs linked to the NID_NTC value in the look-up table. If there is no available STM linked to this NID_NTC value, the STM X shall be the STM having the highest priority among the STMs linked to this NID_NTC value.

   - b) When the ERTMS/ETCS on-board receives trackside data to be transmitted to an STM with the NID_NTC value of Level NTC X, the STM X shall be associated as for the level transition.

   - c) When the Level NTC X is selected/validated by driver,

      - the STM X shall be the STM which NID_STM is equal to NID_NTC, if the look-up table does not contain the NID_NTC value of Level NTC X.

      - Otherwise, the STM X shall be the STM having the highest priority among the available STMs linked to this NID_NTC value in the look-up table. If there is no available STM linked to this NID_NTC value, then the STM X shall be the STM having the highest priority among the connected STMs linked to this NID_NTC value and that are not considered as failed or seen as isolated. Otherwise, the STM X shall be the STM having the highest priority among the STMs linked to this NID_NTC value.

10.2.1.3 The association between a Level NTC X and an STM X shall be kept until the Level NTC X is left after having been entered, or until the Stand-By or No Power mode is entered.

10.2.1.3.1 Note: If STM X associated to the current Level NTC X is no more available, it remains associated to Level NTC X until one of these conditions is fulfilled, even if another STM supporting NTC X is available. This avoids that there is a change of active STM that is neither due to a level transition from trackside, nor due to a driver level selection/validation.

## **10.3 STM MANAGER SYSTEM**

### **10.3.1 Scope**

10.3.1.1 The present chapter does not specify the whole STM Control Function, but only the part of the STM Control Function that manages the states of the connected STM(s).

### **10.3.2 State transition orders**

10.3.2.1 The STM Control Function STM state order table is a table that lists all the events that lead to a state order given by the STM Control Function to the STM.

<!-- end of page 53 -->

#### 10.3.2.2 STM state order table (ERTMS/ETCS on-board STM Control Function)

|**NP**|< A15|< A15|< A15|< A15|< A15|< A15|< A15|
|---|---|---|---|---|---|---|---|
|A1 >|**PO**|< A1|< A1|< A1|< A1|< A1|< A1|
||A2 >|**CO**||||||
|||A3 >|**DE**|||||
|||A4a >|A4a >|**CS**|< C4a<br>< E4a<br>< G4a<br>< H4a<br>< I4a<br>< J4a|< B4a<br>< B4b<br>< I4a<br>< A4b<br>< E4a<br>< K4a<br>< L4a||
|||||A6 ><br>B6 >|**HS**|||
|||||A9>|A9 >|**DA**||
|A17 >|A16 >|A16 >|A16 >|A16 >|A16 >|A16 >|**FA**|
|B16>|B16 >|B16 >|B16 >|B16 >|B16 >|B16 >||
||C16 >|C16 >|C16 >|C16 >|C16 >|C16 >||
||H16 >|H16 >|H16 >|D16 >|D16 >|E16 >||
||I16 >|I16 >|I16 >|H16 >|H16 >|F16 >||
||L16 >|O16 >|O16 >|N16 >|N16 >|H16 >||
||P16 >|P16 >|P16 >|O16 >|O16 >|N16 >||
||A17 >|A17 >|A17 >|P16 ><br>A17 >|P16 ><br>A17 >|O16 ><br>P16 ><br>Q16><br>A17 >||

10.3.2.3 The state indicated in table 10.3.2.2 corresponds to the last state report received from the STM or to FA state if an FA state order has been sent since the reception of the last state report. The STM Control Function shall consider the STM to be in NP when it has not received any state report from the STM.

10.3.2.4 STM state order conditions table applicable to STM X, associated to Level NTC X (ERTMS/ETCS on-board STM Control Function)

|**Condition**|**Content of the conditions**|
|---|---|
|**Id**||
|A1|(STM X connects to the STM Control Function) AND (STM X reports PO state)|
|A2|(“Request CO state” received from STM X)|

<!-- end of page 54 -->

|**Condition**<br>**Id**|**Content of the conditions**|
|---|---|
|A3|(“Request DE state” received from STM X) AND (ETCS Train Data is validated)|
|A4a|(“Request CS state” received from STM X)|
|B4a|(ERTMS/ETCS on-board performs a level transition ordered by the trackside from Level NTC<br>X to Level 0, 1, 2)|
|C4a|(announcement for a transition to Level NTC X is stored) AND (STM X reports HS state) AND<br>(a level transition order to Level NTC Y is received before the transition to Level NTC X) AND<br>(STM X is different from the STM Y associated to Level NTC Y)|
|B4b|(The driver manually changes the level from Level NTC X to Level NTC Y) AND (STM X is<br>different from the STM Y associated to Level NTC Y)|
|E4a|(ETCS mode changes to SB)|
|G4a|(STM X reports “HS state”) AND (no transition to any level associated to STM X for further<br>location is stored on-board) AND (Override function is not active) AND (ETCS level is different<br>from any level associated to STM X)|
|H4a|(ETCS mode is SB) AND (No cab is active)|
|I4a|(ETCS mode changes to SH)|
|J4a|(announcement for a transition to Level NTC X is stored) AND (STM X reports HS state) AND<br>(a level transition order to Level 0, 1 or 2 is received before the transition to Level NTC X)|
|K4a|(The driver manually changes the level from Level NTC X to Level 0, 1 or 2)|
|L4a|(ETCS mode changes to TR)|
|A4b|(ERTMS/ETCS on-board performs a transition ordered by the trackside from Level NTC X to<br>Level NTC Y) AND (STM X is different from the STM Y associated to Level NTC Y)|
|A6|(A transition to Level NTC X for a further location is stored on-board) AND (STM X reports CS<br>state) AND (no other STM reports HS state)|
|B6|(ETCS mode is SB) AND (Cab is active) AND (valid level of the ERTMS/ETCS on-board is<br>Level NTC X) AND (STM X reports CS state) AND (no other STM reports HS state)|
|A9|(level of the ERTMS/ETCS on-board is Level NTC X) AND  (STM X reports CS or HS state)<br>AND (no other STM reports DA state) AND (ETCS mode is SN, SL or NL)|
|A15|(the ERTMS/ETCS on-board equipment is NOT powered)|
|A16|(the STM Control Function receives from STM X a state request which is not allowed by the<br>state transition table)|
|B16|(STM X reports a state it must not be in according to table 9.2.1.1)|
|C16|(the STM Control Function has sent a state transition order except “DA state transition order”<br>and except “conditional CS state transition order”) AND (STM X does not report the required<br>state within a maximum delay time of 10 seconds)|

<!-- end of page 55 -->

|**Condition**<br>**Id**|**Content of the conditions**|
|---|---|
|D16|(the STM Control Function has sent a “DA state transition order”) AND (STM X does not report<br>the required state within a maximum delay time of 5 seconds)|
|E16|(the STM Control Function has sent a “conditional CS state transition order”) AND (STM X<br>does not report CS state or send a “National Trip Procedure” information within a maximum<br>delay time of 10 seconds)|
|F16|(the STM Control Function has sent a “conditional CS state transition order”) AND (the STM<br>Control Function has already received a “National Trip Procedure” information from STM X)<br>AND (STM X does not report CS state or send a “National Trip Procedure” information within a<br>maximum delay time of 10 seconds)|
|H16|(a final disconnection between the ERTMS/ETCS on-board STM Control Function and STM X<br>was detected (see [3] and [2]))|
|I16|(The ERTMS/ETCS on-board performs a transition ordered by trackside to Level NTC X) AND<br>(STM X is not available)|
|L16|(STM X has not yet sent the Specific NTC Data Need) AND (STM X requests CO state)|
|N16|(The timeout TrainDataView_STM_Response_Timeout for STM X has expired)|
|O16|(The timeout TrainDataEntry_STM_Response_Timeout for STM X has expired)|
|P16|(A safety-related information has not been transmitted to STM because of disconnection)|
|Q16|(“National Trip Procedure” is active) AND (STM X reports again “National Trip Procedure”<br>information) AND (the current ETCS mode is PT or UN)|
|A17|(STM X reports FA state)|

10.3.2.5 Note: The delay is shorter for transition to DA state because this transition is assumed as the most critical one from a safety aspect.

10.3.2.6 When the conditions to change the STM state within the STM Control Function are valid according to 10.3.2.2 and 10.3.2.4, the STM Control Function shall send the corresponding state transition order to STM X.

10.3.2.6.1 Exception 1: The STM Control Function shall not send an order for NP or PO state.

10.3.2.6.2 Exception 2: The STM Control Function shall not send an order for FA state if the STM has reported FA state (transition A17).

10.3.2.7 When the state transition order is going to CS state, the STM Control Function shall send an “unconditional order CS state” for the transitions A4a, B4a, C4a, E4a, G4a, H4a, I4a, J4a, K4a and L4a, and a “conditional order CS state” for the transitions A4b and B4b.

10.3.2.8 Note about Q16 condition: The Trip mode is entered if the STM X is in National Trip Procedure when a transition to level 0, 1 or 2 occurs. The National Trip Procedure may

<!-- end of page 56 -->

still be reported after this transition in case the STM has been ordered to CS with a conditional order due to a previous level transition from NTC X to NTC Y.

### **10.3.3 Requirements linked to state transition orders and state reports**

10.3.3.1 The STM Control Function shall not evaluate the state transition order conditions, except conditions to FA state, if this STM has not reported the state corresponding to the last state transition order.

10.3.3.2 An STM is considered as active by the ERTMS/ETCS on-board from the moment it has sent the DA state order to the STM until it sends another state order to this STM (except “conditional CS state transition order”) or receives a state report different from DA from this STM.

10.3.3.3 The STM Control Function shall command the emergency brake from the moment a “conditional CS state transition order” has been sent to a STM and this STM is in National Trip Procedure, up to the moment this STM reports CS state, or is considered as failed and the train reaches standstill.

10.3.3.3.1 Note: This brake command avoids that the train could run untimely without supervision, in case the active STM does not send a brake command but still sends its National Trip Procedure which delays the activation of the STM of the newly entered area.

10.3.3.4 The STM Control Function shall apply the emergency brake when the level is NTC X and the mode is SN and STM X is known as installed on-board but not available.

10.3.3.5 Exception: the brake shall not be applied in case the STM X is known to be isolated, through the corresponding input on the Train Interface.

10.3.3.6 The emergency brake application shall be released by the STM Control Function when

   - a) the STM X has established the connection to the STM Control Function after a nonfinal disconnection and the reported STM X state is DA,

   - b) or the level changes to Level 0, 1, 2,

   - c) or the level changes to a Level NTC Y that is not associated to STM X,

   - d) or the mode SN is left with no change of level,

   - e) or the dedicated input on the Train Interface informs the ERTMS/ETCS on-board that the STM X is isolated.

10.3.3.7 The ERTMS/ETCS on-board shall accept the reconnection of an STM not considered as in FA state or reporting PO state, except in case of final disconnection on Safety Layers.

10.3.3.8 The STM Control Function shall inform the driver that the STM X is not available while all of the following conditions are fulfilled

   - the level is NTC X,

   - and (the mode is SN) or (the mode is NL and has been so for at least 5s),

   - and STM X is known as installed on-board but not available,

<!-- end of page 57 -->

   - and STM X is not known to be isolated through the corresponding input on the Train Interface.

10.3.3.8.1 Note: the 5s delay on the information to the driver is required because the STM X requests to enter in CS state only after the mode has changed to NL.

## **10.4 ETCS data**

10.4.1.1 The ETCS data transmitted by the ERTMS/ETCS on-board to the STMs shall include a subset of the ETCS Train Data (defined in [1]), as listed below:

   - a) Train category(ies)

   - b) Train length

   - c) Traction / brake parameters

   - d) Maximum train speed

   - e) Loading gauge

   - f) Axle load category

   - g) Traction system(s) accepted by the engine

   - h) Train fitted with airtight system

10.4.1.2 The ETCS data transmitted by the ERTMS/ETCS on-board to the STMs shall include a subset of the ETCS Train Data entry input fields (defined in [9]), as listed below:

   - a) Train Type, if applicable for the train

10.4.1.3 Note: Extra data for the available STMs are handled in the Specific NTC Data Entry procedure see chapter 10.7.

10.4.1.4 The traction / brake parameters shall include:

   - a) Equivalent brake build up time for full service brake for the combination of none of the special brakes being used

   - b) Equivalent brake build up time for emergency brake for the combination of none of the special brakes being used

   - c) Traction cut off time

   - d) Brake position

   - e) Brake percentage, if applicable for the train

10.4.1.5 The ETCS data transmitted by the ERTMS/ETCS on-board to the STMs shall include a subset of ETCS Additional Data (defined in [1]) as listed below:

   - a) Train Running Number

   - b) ETCS identity

   - c) Adhesion factor

   - d) Date and Time (UTC Time)

<!-- end of page 58 -->

10.4.1.6 The ETCS data transmitted by the ERTMS/ETCS on-board to the STMs shall include the ETCS National / Default Values (defined in [1])

10.4.1.7 The STM Control Function shall transmit the subset of valid ETCS Train Data when the ETCS Train Data is validated.

10.4.1.7.1 Note: ETCS Train Data could be changed and validated from sources different from the driver if acquired from ERTMS/ETCS on-board external sources.

10.4.1.8 The STM Control Function shall transmit the valid ETCS Additional Data a) when the STM has entered into Configuration (CO) state, and

   - b) when the valid ETCS Additional Data except date / time has changed.

10.4.1.9 The STM Control Function shall transmit the currently used ETCS National / Default Values

   - a) when the STM has entered into Configuration (CO) state, and

   - b) when the currently used ETCS National Values have changed (this also includes the case when the National Values are reset to the Default Values).

## **10.5 ETCS status data**

10.5.1.1 The STM Control Function shall send the ETCS status data consisting of the current ETCS mode and level (defined in [1]):

   - a) To all connected STMs whenever the ETCS mode or level changes.

   - b) To any STM when the connection to the STM Control Function is established.

10.5.1.2 In case the ETCS mode is AD, the STM Control Function shall report in the ETCS status data that the ETCS on-board is in FS mode instead. This also implies that by exception to 10.5.1.1 a), neither a change of ETCS mode from FS to AD nor from AD to FS shall trigger the sending of the ETCS status data.

10.5.1.3 In case the ETCS mode is SM, the STM Control Function shall report in the ETCS status data that the ETCS on-board is in SH mode instead. This also implies that by exception to 10.5.1.1 a), a change of ETCS mode from SM to SH shall not trigger the sending of the ETCS status data.

## **10.6 Language used to display information to the driver**

10.6.1.1 The STM Control Function shall transmit the language used to display information to the driver:

   - a) To all connected STMs whenever the language is changed,

   - b) To any STM when the connection to the STM Control Function is established.

## **10.7 Specific NTC Data Entry**

### **10.7.1 Definitions**

<!-- end of page 59 -->

10.7.1.1 The “Specific NTC Data” are the national data that need to be requested to the driver.

10.7.1.2 The STM may use the transmitted ETCS data: ETCS Train Data, ETCS Additional Data and ETCS National Values in order to reduce the entry of “Specific NTC Data” by the driver.

10.7.1.3 All “Specific NTC Data” used by all the different STMs are assigned a unique identity made of NID_STM and Data Identifier.

10.7.1.4 The process to deliver those “Specific NTC Data” to the STM is called “Specific NTC Data Entry”.

10.7.1.4.1 Note: Specific NTC Data Entry is possible at start-up and later on during mission through the Train Data Entry procedure.

### **10.7.2 Responsibilities**

10.7.2.1 The ERTMS/ETCS on-board equipment is responsible for the dialogue with the driver during the Specific NTC Data Entry/Validation process, for checking the technical range checks (if configured on-board) and for the transmission of the Specific NTC Data after the driver’s validation.

10.7.2.2 The STM is responsible for checking the content (e.g. range, spares, internal dependency of parameters) of the data. The STM can be exempted of technical range checks if those are configured in the ERTMS/ETCS on-board equipment.

### **10.7.3 General requirements**

10.7.3.1 The ERTMS/ETCS on-board equipment shall offer the possibility to the driver to skip the Specific NTC Data Entry for a STM.

10.7.3.2 The ETCS Train Data as well as the Specific NTC Data might become invalid within the STM at any time due to national requirements. In this case, the STM may request the data from the ETCS by sending the “Specific NTC Data Need”.

10.7.3.3 Specific NTC Data can be or become invalid, because:

   - a) the ETCS Train Data Entry/Specific NTC Data Entry procedure has not yet been performed or has been aborted, or

   - b) the driver has skipped the Specific NTC Data Entry for this STM before the STM has sent the “End of Specific NTC Data Entry” to the ERTMS/ETCS on-board, or

   - c) the ETCS Train Data Entry procedure has already been performed by the time the STM has entered into CO state, e.g. the STM has been powered on or restarted during train mission, or

   - d) the ETCS Train Data has changed from sources different from the driver and this change impacts the validity status of the Specific NTC Data, according to national rules, or

   - e) because of STM internal function, e.g. national shunting.

<!-- end of page 60 -->

10.7.3.4 When the ERTMS/ETCS on-board receives the “Specific NTC Data Need” while in FS, AD, LS, SR, OS, UN, TR, PT and SN modes, it shall inform the driver that the national system needs data.

10.7.3.5 The ERTMS/ETCS on-board shall delete this information to the driver when the driver initiates the Train Data entry procedure or when the corresponding STM is considered as failed or when this STM is known to be isolated by TIU “NTC isolation status” input data.

10.7.3.6 The STM requests its Specific NTC Data with a “Specific NTC Data Entry request” which shall include for each Specific NTC Data, the following information: the label, optionally a default value, and optionally values for a dedicated keyboard.

10.7.3.7 Note: Unless values for a dedicated keyboard are provided or the type of keyboard is configured on-board, an alphanumeric keyboard will by default be used (see document ref [9]).

10.7.3.8 It shall be possible to configure in the ERTMS/ETCS on-board the following parameters for any STM:

   - 1) The window titles for the NTC data entry, the NTC data validation and the NTC data view windows

   - 2) For each Specific NTC Data Identifier not using a dedicated keyboard:

      - a) The type of keyboard amongst numeric, enhanced numeric and alphanumeric

      - b) If the type of keyboard is numeric or enhanced numeric, whether leading zeros have to be kept and sent to the STM

      - c) The allowed minimum and maximum value, that shall be used by the ERTMS/ETCS on-board with a technical range check

10.7.3.9 By analogy to the modification/revalidation of ETCS Train data, the [1] requirements 3.14.1.7.3, 3.18.3.3.1 regarding the brake command/release when a movement is detected while modifying or revalidating the Train Data in normal operation after the start of mission shall also apply for the NTC data modification/revalidation.

### **10.7.4 Specific NTC Data Entry procedure**

10.7.4.1 As soon as the ETCS Train Data is validated by the driver and if the connected STM is in CO, DE, CS, HS or DA state, the ERTMS/ETCS on-board shall indicate to the STM the beginning of its Specific NTC Data Entry procedure by sending the START flag.

10.7.4.2 The ETCS Train Data shall be sent immediately after the START flag.

10.7.4.3 While a Specific NTC Data Entry is ongoing, the ERTMS/ETCS on-board shall indicate to the STM the end of its Specific NTC Data Entry procedure by sending the STOP flag when one of the following conditions is fulfilled:

   - a) after having received the “End of Specific NTC Data Entry” from the respective STM,

   - b) at expiration of the timeout specified in 10.7.4.9 for the respective STM,

<!-- end of page 61 -->

   - c) when the Train Data Entry procedure is aborted by the ERTMS/ETCS on-board for reasons not related to the STM interface

   - d) the Specific NTC Data Entry for this STM has been skipped by the driver see 10.7.3.1.

10.7.4.3.1 Note: Reasons leading to the abortion of the Train Data entry procedure and not related to the STM interface can be e.g. the cab deactivation, the driver aborting the Train Data entry procedure,...

10.7.4.4 Note: ETCS Train Data is also sent without the START and STOP flags outside a Train Data entry procedure, see 10.4.1.7.

10.7.4.5 Once the STM has received the ETCS Train Data while its Specific NTC Data Entry is ongoing:

   - a) If the STM requires Specific NTC Data, the STM shall send a “Specific NTC Data Entry request” information to the ERTMS/ETCS on-board.

   - b) If the STM doesn’t require Specific NTC Data, the STM shall send an “End of Specific NTC Data Entry” information to the ERTMS/ETCS on-board.

10.7.4.6 After the ERTMS/ETCS on-board has received the Specific NTC Data Entry request, it shall perform the Specific NTC Data Entry/Validation exchanges with the driver when the driver selects this Specific NTC Data Entry.

10.7.4.7 Once the Specific NTC Data for an STM has been validated by the driver, the ERTMS/ETCS on-board shall send the “Specific NTC Data” to this STM.

10.7.4.8 When the STM receives the Specific NTC Data, it checks the data according to its national criteria. Depending on the check result:

   - a) the STM shall send an “End of Specific NTC Data Entry” if the checks are OK and the STM has all the requested data.

   - b) the STM shall send again Specific NTC Data Entry request.

10.7.4.9 For all connected STMs, the ERTMS/ETCS on-board shall supervise separately a timeout of 10s (TrainDataEntry_STM_Response_Timeout, see chapter 10.3.2.4, O16):

   - a) from sending the ETCS Train Data by the ETCS while the Specific NTC Data Entry procedure is running, until the reception of a Specific NTC Data Entry request or the “End of Specific NTC Data Entry” from the STM and

   - b) from each sending Specific NTC Data by the ETCS until the reception of the Specific NTC Data Entry request or the “End of Specific NTC Data Entry” from the STM.

<!-- end of page 62 -->

### **10.7.5 Sequence diagrams for the Specific NTC Data Entry**

<!-- Start of picture text -->
STM A STM B<br>Driver ERTMS/ETCS on-board<br>associated to NTC A Associated to NTC B<br>ETCS Train Data validated<br>Start flag Start flag<br>ETCS Train Data<br>ETCS Train Data<br>Specific NTC Data Entry Request<br>NTC data entry selection window<br>Specific NTC Data Entry Request<br>Buttons for NTC A & B are enabled<br>NTC A selected by the driver<br>Specific NTC Data of NTC A presented to the driver<br>Specific NTC Data for NTC A validated<br>Specific NTC Data values<br>End of Specific NTC Data Entry<br>NTC data entry selection window<br>Buttons for NTC B is enabled<br>Stop flag<br>NTC B selected by the driver<br>Specific NTC Data of NTC B presented to the driver<br>Specific NTC Data for NTC B validated<br>Specific NTC Data values<br>End of Specific NTC Data Entry<br>NTC data entry selection window<br>Buttons for NTC A & B are<br>disabled<br>Stop flag<br><!-- End of picture text -->

**Figure 6 – Specific NTC Data Entry performed**

<!-- end of page 63 -->

<!-- Start of picture text -->
STM A STM B<br>Driver ERTMS/ETCS on-board<br>associated to NTC A associated to NTC B<br>ETCS Train Data validated<br>Start flag Start flag<br>ETCS Train Data<br>ETCS Train Data<br>Specific NTC Data Entry Request<br>NTC data entry selection window<br>Specific NTC Data Entry Request<br>Buttons for NTC A & B are<br>enabled<br>NTC A selected by the driver<br>Specific NTC Data of NTC A presented to the driver<br>Specific NTC Data for NTC A validated<br>Specific NTC Data values<br>End of Specific NTC Data Entry<br>Stop flag<br>NTC data entry selection window<br>Buttons for NTC B is enabled<br>Driver presses “End of data entry“<br>Stop flag<br><!-- End of picture text -->

**Figure 7 – Specific NTC Data Entry skipped for NTC B**

<!-- end of page 64 -->

<!-- Start of picture text -->
STM A STM B<br>Driver ERTMS/ETCS on-board<br>associated to NTC A associated to NTC B<br>ETCS Train Data validated<br>Start flag Start flag<br>ETCS Train Data<br>ETCS Train Data<br>Specific NTC Data Entry Request<br>NTC data entry selection window<br>Buttons for NTC A & B are  Specific NTC Data Entry Request<br>enabled<br>Cab being closed<br>Stop flag Stop flag<br><!-- End of picture text -->

**Figure 8 – Specific NTC Data Entry aborted**

## **10.8 Specific NTC Data View**

10.8.1.1 This procedure shall allow the driver to view the Specific NTC Data View values currently known by the STM.

10.8.1.2 When the Data View procedure is triggered, the ERTMS/ETCS on-board shall send to all available STMs a Request for Specific NTC Data View values.

10.8.1.3 Once the STM has received the ETCS Request for Specific NTC Data View values:

   - a) If the STM requires Specific NTC Data View values to be displayed, the STM shall send those Specific NTC Data View values (labels and corresponding values) to the STM Control Function.

   - b) If the STM doesn’t require Specific NTC Data View values to be displayed, the STM shall send a “No Specific NTC Data View values” to the ETCS STM Control Function.

10.8.1.4 When the ERTMS/ETCS on-board receives the Specific NTC Data View values, it shall present them to the driver.

10.8.1.5 For all connected STMs, the ERTMS/ETCS on-board shall supervise separately a timeout of 10s (TrainDataView_STM_Response_Timeout, see chapter 10.3.2.4, N16) from sending the Request for Specific NTC Data View values until the reception of Specific NTC Data View values or the “No Specific Data View values” information from the respective STM.

<!-- end of page 65 -->

## **10.9 STM Test Procedure**

10.9.1.1 The STM shall be allowed to send a Test Procedure Permission Request, including a Test Identity, to the STM Control Function.

10.9.1.2 Having received this Test Procedure Permission Request, the ERTMS/ETCS on-board shall grant Test Procedure Permission when technically suitable.

10.9.1.2.1 Note: the condition to grant this Test Procedure Permission is specific to ERTMS/ETCS on-board implementation and to the Test Identity requested by the STM.

10.9.1.3 Having received this Test Procedure Permission, the STM shall perform the test and then report the End of Test Procedure, including test result and optional text message.

10.9.1.3.1 Note: the way the test result and text message are displayed is specific to ERTMS/ETCS on-board implementation.

## **10.10 Override**

### **10.10.1 Introduction**

10.10.1.1 This Override procedure (Trip Inhibition, Pass Stop or Pass signal at danger) is specified in order to provide an override for the active system as well as for the system to be activated without applying the brakes (e.g. trip) by both systems.

10.10.1.2 When Override is activated in the active system (ERTMS/ETCS on-board or STM), all on-board systems receive a notification. Each system can then activate and monitor its specific Override procedure limits (e.g. time, distance and/or reception of trackside information) and trip inhibition. Termination of this monitoring is done independently in each system.

10.10.1.3 After a level transition, the activated system is able to immediately have its Override function active. It can then start to supervise the relevant speed for Override under the limits of the activated system according to its specific requirements. The limits may be considered from the location where driver requested Override.

### **10.10.2 Requirements**

10.10.2.1 In addition to the conditions defined in [1], the ETCS Override status shall be activated when in level NTC, the ERTMS/ETCS on-board has received from the active STM the activation report of its own Override procedure.

10.10.2.2 The ETCS Override function shall be reset each time a new activation report is received from the active STM.

10.10.2.3 The ERTMS/ETCS on-board shall report its Override status (activated or deactivated):

   - a) To any STM with an established connection to the STM Control Function whenever its Override status changes,

   - b) To any connecting STM when the connection to the STM Control Function is established.

<!-- end of page 66 -->

10.10.2.4 Note: If the Override function is active while in the Mode SN, no speed supervision is performed by the ERTMS/ETCS on-board and all connected STMs except for the active STM.

## **10.11 Transmission of ETCS trackside messages for STMs**

10.11.1.1 When the ERTMS/ETCS on-board receives from an RBC or from a Balise Group as non-infill information data to be used by applications outside ERTMS/ETCS which has to be transmitted to an NTC (i.e. data received with NID_XUSER = 102 together with the concerned NID_NTC), the data shall be transmitted by the STM Control Function to the STM associated to the Level NTC which NID_NTC is contained in this trackside data.

10.11.1.1.1 Note: Trackside data received as infill information is not transmitted to STMs.

10.11.1.2 The STM Control Function shall add to the transmitted trackside data the odometer reading of the balise group which transmitted the trackside message, or the odometer reading of the LRBG of the message if it was received from RBC.

10.11.1.3 The odometer reading shall correspond to the estimated odometer value of the location reference of the balise group.

## **10.12 STM max speed and STM system speed/distance**

### **10.12.1 After announcement, but before the transition to Level NTC X**

10.12.1.1 When an “STM max speed” (V_STMMAX) from STM X in HS state is accepted, the ERTMS/ETCS on-board includes the “STM max speed” in the computation of the MRSP (see [1] 4.5.2) as a speed restriction that shall start at the level transition border.

10.12.1.2 When the ERTMS/ETCS on-board accepts a new “STM max speed” (V_STMMAX) from STM X, the ERTMS/ETCS on-board shall replace the previously received “STM max speed” (V_STMMAX) with the new value.

10.12.1.3 If the STM X connected or known as installed on-board (see 10.1.1.1) is not available, then the ERTMS/ETCS on-board shall consider that “STM max speed” = 0.

10.12.1.3.1 Note: The purpose of the above requirement is to try to prevent the train to enter in a Level NTC area while this STM is not available.

10.12.1.4 When an “STM system speed” (V_STMSYS) together with an “STM system distance” (D_STMSYS) from STM X in HS state is accepted, the ERTMS/ETCS onboard includes the “STM system speed” (V_STMSYS) into the computation of the MRSP (see [1] 4.5.2), as a new speed restriction that shall start at a location “STM system distance” (D_STMSYS) in rear of the level transition border and shall end at the level transition border.

10.12.1.5 When an ERTMS/ETCS on-board accepts a new “STM system speed” (V_STMSYS) and “STM system distance” (D_STMSYS) from STM X, the ERTMS/ETCS on-board shall replace previously received “STM system speed” (V_STMSYS) and “STM system distance” (D_STMSYS) with the new value.

<!-- end of page 67 -->

10.12.1.6 When the level transition announcement to level NTC X is deleted by the ERTMS/ETCS on-board:

   - a) The “STM system speed” (V_STMSYS) shall be deleted and the supervision of the “STM system speed” (V_STMSYS) shall be stopped by the ERTMS/ETCS on-board;

   - b) The “STM max speed” (V_STMMAX) shall be deleted and the supervision of the “STM max speed” (V_STMMAX) shall be stopped by the ERTMS/ETCS on-board.

10.12.1.6.1 Note: when a new level transition to another level than NTC X is accepted, the previous one is deleted and replaced with this new one.

10.12.1.6.2 Note: when a level transition announcement to the same level NTC X is updated (i.e. with a new distance), the "STM system speed" and "STM max speed" are not deleted.

### **10.12.2 After the level transition to Level NTC X**

10.12.2.1 Once the train has passed the level transition border, the ERTMS/ETCS on-board shall supervise the “STM max speed” (V_STMMAX) previously sent by the STM in HS state as ceiling speed until the STM DA state report is received by the ERTMS/ETCS onboard.

10.12.2.2 If the STM is considered to be in FA state by the ERTMS/ETCS on-board after the level transition border, then the ERTMS/ETCS on-board shall stop the supervision of “STM max speed” (V_STMMAX).

10.12.2.3 If, for any reasons (e.g. reception of a level transition order or a manual change of level), the level changes to another level than NTC X, the “STM max speed” (V_STMMAX) shall be deleted and the supervision of the “STM max speed” (V_STMMAX) shall be stopped by the ERTMS/ETCS on-board.

## **10.13 Validity of “National Trip Procedure” information**

10.13.1.1 The ERTMS/ETCS on-board shall consider that a National Trip Procedure is active if the “National Trip Procedure” packet has been received within the last 10 seconds (see [1]).

10.13.1.2 Note: if the National Trip Procedure has been released before a level transition, the ERTMS/ETCS on-board will consider it as still active for a maximum of 10 seconds after the reception of the information, but it is assumed that the level transition after the end of this National Trip Procedure won’t happen within this time, as the train is at standstill.

## **10.14 Display of STM failure status**

10.14.1.1 When an STM has reported FA state or is commanded to FA state, the ERTMS/ETCS on-board shall inform the driver about the failed status of the national system supported by this STM.

10.14.1.2 When at Start of Mission just after validation of ETCS Train Data an STM known by ERTMS/ETCS on-board configuration to be installed is not in CO, CS, HS or DA state and this STM is not known to be isolated by TIU “NTC isolation status” input data,

<!-- end of page 68 -->

ERTMS/ETCS on-board shall inform the driver about the failed status of the national system supported by this STM.

## **10.15 Interface 'K' Antenna/BTM ID**

10.15.1.1 If the ERTMS/ETCS on-board uses alternative 1 of interface 'K' (see [10]), it shall indicate to all KER (KVB, Ebicab, RSDD) STMs whether it can or not guarantee by its own that the interface 'K' data is coming from the intended Antenna/BTM, when the connection to the STM Control Function is established.

10.15.1.2 If ERTMS/ETCS on-board cannot guarantee by its own that the interface 'K' data is coming from the intended Antenna/BTM, the STM Control Function shall inform whether there is an active Antenna/BTM and, if so, which one:

   - a) To all connected KER STMs whenever this information changes,

   - b) To any KER STM when the connection to the STM Control Function is established.

10.15.1.3 Note: This information enables an STM using interface 'K' to fulfil a requirement of [10] asking to supervise that the interface 'K' information comes from the intended source.

## **10.16 BTM alarm data**

10.16.1.1 The STM Control Function shall send the BTM alarm data consisting of the BTM alarm status and whether the antenna is within an announced Big Metal Mass track condition:

   - a) To all connected STMs whenever the BTM alarm status changes or whenever an announced Big Metal Mass track condition is entered or exited during a BTM alarm,

   - b) To any STM when the connection to the STM Control Function is established.

10.16.1.2 Note: The ERTMS/ETCS on-board always sends this information over the FFFIS STM interface regardless the alarms are ignored according to [1] 3.12.1 and 3.15.7.

<!-- end of page 69 -->
