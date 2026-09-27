# **9. ATO OPERATION STATES**

## **9.1 Main concepts**

### **9.1.1 ATO Operational Conditions**

9.1.1.1 The ATO-OB System shall be ready for ATO operation (i.e. ATO Operational) when all the following conditions are satisfied:

- a) The ETCS-OB applicable conditions for ATO Operational are fulfilled (See §9.1.1.2);

- b) There is no Emergency Brake application by another system or the driver;

- c) The TP “End of Journey” of the current journey has not been reached (Stopping Point) or passed (Passing Point or Stopping Point to be skipped) ;

- d) The last TP of the journey has not been passed;

- e) All referenced SPs up to the targeted TP are available on-board;

- f) Data inconsistency affecting the next TP is not detected (see §7.8);

- g) The train is located in an SP included in the current JP;

- h) The train is not located within an ATO Inhibition Zone;

- i) The ETCS Data and ATO Specific Data are valid.

9.1.1.2 The ETCS-OB applicable conditions for ATO Operational are:

- a) The ETCS-OB is in AD Mode or FS Mode and conditions for displaying “ENTERING FS” no longer exist (see [Ref 5] §4.4.9.1.4);

- b) The ETCS-OB is not commanding the Emergency Brake or Full Service Brake.

### **9.1.2 ATO Engagement Conditions**

9.1.2.1 The following conditions shall be fulfilled in order to be able to engage the ATO-OB:

- a) Direction controller is in forward position (only applicable when the direction controller information is available);

- b) While the train is stopped at a platform area, the MA shall be such that the train is able to leave the platform completely based on estimated rear end;

- c) While the train is stopped outside a platform area, the MA allows the train to move (the minimum distance to allow proceeding is train specific);

- d) When the ATO-OB is not engaged and the train is approaching a Stopping Point, the remaining distance is sufficient for the ATO-OB to stop the train (the minimum distance to stop the train is train specific);

- e) Train doors are closed and locked;

- f) The dwell time is elapsed (if any);

- g) Train applicable conditions for operating ATO are fulfilled;

- h)  The TBL is not in brake position;

<!-- end of page 63 -->

   - i) While the train is stopped the TBL is not in traction position.

9.1.2.1.1 **Note:** The condition “Train doors are closed and locked” only applies to passenger trains.

9.1.2.2 If the train is not able to provide train applicable conditions (configuration parameter), ATO-OB shall consider the train applicable conditions are always fulfilled.

## **9.2 No Power (NP)**

9.2.1.1 The ATO-OB shall remain in NP State when it is switched off.

9.2.1.2 When it is in NP State, the ATO-OB has no responsibility for train operation.

## **9.3 ATO Configuration (CO)**

9.3.1.1 The CO State is the default State entered by the ATO-OB after the ATO-OB is switched on.

9.3.1.2 The ATO-OB shall remain in CO State until it has received the required ETCS Data and Specific ATO Data.

9.3.1.3 When the ATO-OB enters CO State, the ATO-OB shall send a “Specific ATO Data Need” information to the ETCS-OB indicating whether it needs or not Specific ATO Data.

9.3.1.4 When it is in CO State, the ATO-OB has no responsibility for train operation.

## **9.4 ATO Not Available (NA)**

9.4.1.1 When it is in NA State, the ATO-OB is waiting for the ATO Operational Conditions (see §9.1.1) to be fulfilled.

9.4.1.2 When it is in NA State, the ATO-OB has no responsibility for train movement.

## **9.5 ATO Available (AV)**

9.5.1.1 When it is in AV State, the ATO-OB is ready for operation and it is waiting for the ATO Engagement Conditions to be fulfilled (see §9.1.2).

9.5.1.2 When it is in AV State, the ATO-OB has no responsibility for train movement.

## **9.6 ATO Ready (RE)**

9.6.1.1 When it is in RE State, the ATO-OB is ready to control train operation as all technical and operational conditions for engagement are fulfilled but the ATO-OB is waiting for driver action to start automatic driving.

<!-- end of page 64 -->

9.6.1.2 When the conditions for engagement are fulfilled, the driver has the responsibility of starting automatic driving by selecting “ATO Engage”.

9.6.1.3 When it is in RE State, the ATO-OB is not yet responsible for train movement (still waiting for the action by the driver to start automatic driving).

9.6.1.4 **Note:**The request to start automatic driving may be done when the train is either stopped or moving.

## **9.7 ATO Engaged (EG)**

9.7.1.1 When it is in EG State, the ATO-OB is responsible for driving the train controlling brake and traction according to the computed ATO Operational Speed Profile.

## **9.8 ATO Disengaging (DE)**

9.8.1.1 The ATO-OB shall transition to DE State, if any of the ATO Operational Conditions but the ETCS related ones is lost while the ATO-OB is in EG State.

9.8.1.2 During the first 5 seconds after the ATO-OB  has transitioned to DE State, the ATO-OB shall continue to follow the last computed ATO Operational Speed Profile with the limitation of not requesting traction.

9.8.1.3 If the ATO-OB recovers the ATO Operational Conditions within the first 5 seconds after the ATO-OB  has transitioned to DE State, the ATO-OB shall transiton to EG State.

9.8.1.4 If the ATO-OB does not recover the ATO Operational Conditions within the first 5 seconds after the ATO-OB  has transitioned to DE State, the ATO-OB shall apply the Full Service Brake (if it is not already applied).

9.8.1.5 **Note:**The ATO Disengaging scenario is described in section §9.10.3.

## **9.9 ATO Failure (FA)**

9.9.1.1 The ATO-OB shall enter the FA State in case of a fault which does not allow performing ATO functions.

9.9.1.2 **Note:**In FA State, the driver has the responsibility to execute the operational procedures defined by supplier and Railway Undertakings.

9.9.1.3 Transitions to FA State shall be reported by the ATO-OB to the ATO-TS and the driver (if it is still possible) and recorded on-board.

<!-- end of page 65 -->

## **9.10 Transitions between States**

### **9.10.1 Introduction**

9.10.1.1 This section §9.10 defines the different scenarios and the transitions between ATO-OB States including the transition conditions.

9.10.1.2 **Note:** The sections from §9.10.1 to §9.10.5 are not requirements but just descriptive text.

### **9.10.2 Nominal scenario**

9.10.2.1 The Figure 9 Nominal scenario shows the nominal ATO operation scenario.

9.10.2.2 The nominal scenario is based on the following steps:

- 1) The ATO-OB is powered on.

   - The ATO-OB transitions from NP to CO State. The “ATO Selected” indication is displayed.

- 2) ETCS data entry process (including ATO Specific Data Entry) is completed and the ATO-OB receives the required data. The ATO-OB transitions from CO to NA State. The “ATO Selected” indication is displayed.

- 3) When the ATO Operational Conditions are fulfilled (see §9.1.1), the ATO-OB transitions from NA to AV State. The “ATO Selected” indication is still displayed.

- 4) When all the ATO Engagement Conditions are fulfilled (see §9.1.2), the ATO-OB transitions from AV to RE Stateand the “ATO Ready for Engagement” indication is displayed to the driver.

- 5) The driver selects “ATO Engage”, the ETCS-OB changes to AD Mode. The ATO-OB transitions from RE to EG State. The “ATO Engaged” indication is displayed to the driver and the ATO-OB starts driving the train automatically

- 6) The ATO-OB drives the train. When the train stops, the ATO-OB requests the “Train Holding Brake” application and the “ATO Selected” indication is again displayed to the driver.

The ATO-OB transitions from EG to AV State. The train is stationary waiting until the ATO Engagement Conditions are fulfilled again.

- 7) Return to step 4) and repeat the sequence until the end of the journey.

<!-- end of page 66 -->

<!-- Start of picture text -->
ATO  ATO Not<br>Configuration  2) Available        3) ATO Available  4) ATO Ready<br>(AV) (RE)<br>(CO) (NA)<br>1) 5)<br>No Power  6) ATO Engaged<br>(NP) (EG)<br>ATO OPERATIONAL<br><!-- End of picture text -->

**Figure 9 Nominal scenario**

### **9.10.3 Alternative scenario: Losing ATO Operational Conditions**

9.10.3.1 Precondition: the train is running with the ATO-OB in EG State and loses ATO Operational Conditions (see §9.1.1).

9.10.3.2 If the ATO-OB loses any ATO Operational Condition (see §9.1.1) except “The ETCS-OB applicable conditions for ATO Operational are fulfilled” (see §9.1.1.1 a)), the scenario is based on the following steps:

- 1) The “ATO Disengaging” indication is displayed to the driver;

- 2) The ATO-OB transitions from EG to DE State with the following consequences:

   - a) During the first 5 seconds after the ATO-OB  has transitioned to DE State, the ATO-OB continues to follow the last computed ATO Operational Speed Profile with the limitation of not requesting traction (§9.8.1.2).

   - b) If the driver applies the brake using the TBL or selects “ATO Disengage” before 5 seconds, the ATO-OB transitions from DE to NA State and the ETCS-OB leaves AD Mode;

   - c) If ATO-OB recovers ATO Operational Conditions before 5 seconds (no selection of “ATO Engage” is required in this situation), the ATO-OB transitions from DE to EG State and continues to drive the train automatically;

   - d) If the driver does not react and the ATO Operational Conditions are not recovered after 5 seconds, the ATO-OB remains in DE State and applies the Full Service Brake (if not already applied):

      - i. If the driver brakes using the TBL or selects “ATO Disengage” at any time while the ATO-OB is braking, the ATO-OB releases its Service Brake command and transitions from DE to NA State.

      - ii. When the train is stopped, the ATO-OB transitions from DE to NA State and the ETCS-OB leaves AD Mode.

9.10.3.3 If the ATO-OB loses the ATO Operational Condition “The ETCS-OB applicable conditions for ATO Operational are fulfilled” (see §9.1.1.1 a)), the scenario is based on the following steps:

- 1) The ETCS-OB leaves AD Mode;

- 2) The “ATO Selected” indication is displayed to the driver;

- 3) The ATO-OB transitions to NA State.

<!-- end of page 67 -->

### **9.10.4 Alternative scenario: ATO Failure**

9.10.4.1 This scenario is based on the following steps:

- 1) The ATO-OB detects a fault that does not allow ATO operation;

- 2) The ATO-OB transitions to FA State;

- 3) The “ATO Failure” indication is displayed to the driver and an audible warning is generated during 5 seconds;

- 4) The driver executes the operational procedures defined by supplier and Railway Undertakings.

### **9.10.5 Alternative scenario: Driver brakes manually while the train is automatically driven**

9.10.5.1 Precondition: The ATO-OB is in EG State.

9.10.5.2 This scenario is based on the following steps:

- 1) The driver manually brakes using the TBL;

- 2) The ATO-OB stops automatic driving. The ATO-OB transitions to AV State;

- 3) The driver continues driving manually until the driver decides to start automatic driving again. Then the driver sets the TBL in neutral or traction position and selects “ATO Engage”. The sequence continues as in the nominal scenario.

### **9.10.6 Flowchart of ATO-OB State transitions**

9.10.6.1 The transitions shall comply with the information given on:

- a) The previous information of the present section §9 (excluding descriptive text of clauses from §9.10.1 to §9.10.5);

- b) The Table 6 Transition table;

- c) The Table 7 Transition conditions table.

<!-- end of page 68 -->

<!-- Start of picture text -->
[10]<br>ATO  ATO Not<br>No Power  [1]  [2]<br>Configuration  Available<br>(NP) [12] [9a]<br>(CO) (NA)<br>[3a]<br>[12] [6b] or [8] or [10]<br>ATO Available<br> ATO Failure<br> (AV)<br>(FA) [11]<br>ATO<br>Disengaging          [4] [7]<br>(DE)<br>Nominal scenario ATO Ready<br>Losing ATO Operational conditions<br>(RE)<br>ATO Failure<br>Losing ATO Engagement conditions<br>Train is powered off [5]<br>[3b]<br>ATO Engaged        [6a] or [8]<br>[9b] (EG)<br><!-- End of picture text -->

#### **Figure 10 State Transitions**

<!-- end of page 69 -->

### **9.10.7 Symbols**

9.10.7.1 The indication “4>” means: The condition n°4 must be fulfilled to trigger the transition from the state located in the column to the state that is indicated by the arrow “>”.

9.10.7.2 Each transition from a given state receives a priority order (indicated by “-px-”, x is the priority order) to avoid a conflict between the different transitions when they occur at the same time (i.e. in the same clock cycle). P1 has a higher priority than P2.

9.10.7.3 "8, 10, 11" means "8 or 10 or 11".

### **9.10.8 Transition table**

|**NP**|<12<br>-p1-|<12<br>-p1-|<12<br>-p1-|<12<br>-p1-|<12<br>-p1-|<12<br>-p1-|<12<br>-p1-|
|---|---|---|---|---|---|---|---|
|1><br>-p1-|**CO**|||||||
||2><br>-p3-|**NA**|<9a<br>-p3-|<9a<br>-p3-|<10<br>-p3-|<6b, 8,<br>10<br>-p3-||
|||3a><br>-p3-|**AV**|<7<br>-p4-|<6a,8<br>-p4-|||
||||4><br>-p4-|**RE**||||
|||||5><br>-p5-|**EG**|<3b<br>-p4-||
||||||9b><br>-p5-|**DE**||
||11><br>-p2-|11><br>-p2-|11><br>-p2-|11><br>-p2-|11><br>-p2-|11><br>-p2-|**FA**|

**Table 6 Transition table**

9.10.8.1 If several consecutive transition conditions are fulfilled at the same time, the ATO-OB State shall transition from the initial state to the final state without performing any action(s) linked to the intermediate state(s).

<!-- end of page 70 -->

### **9.10.9 Transition conditions table**

|**Condition**<br>**Id**|**Content of the conditions**|
|---|---|
|[1]|The ATO-OB is powered on.|
|[2]|The ATO-OB has received the required “ETCS Data” and “Specific ATO Data”.|
|[3a]|The ATO Operational Conditions are fulfilled (see §9.1.1).|
|[3b]|(The Train Applicable conditions for operating ATO are fulfilled) AND (The ATO-OB recovers<br>the ATO Operational Conditions (see §9.1.1) within 5 seconds after changing to DE State).|
|[4]|The ATO Engagement Conditions are fulfilled (see §9.1.2).|
|[5]|The ATO-OB considers the input “ATO Engage” as selected (see §10.2.8.6, i.e. the driver has<br>selected “ATO Engage” and the ETCS-OB is in AD Mode),|
|[6a]|(The train stops at a Stopping Point considered as reached) AND (the train is stationary<br>through at least the application of the Train Holding Brake, see §6.2.1.6 to §6.2.1.8).|
|[6b]|(The train stops) AND (the train is stationary through at least the application of the Train<br>Holding Brake, see §6.2.1.6 to §6.2.1.8).|
|[7]|The ATO Engagement Conditions are not fulfilled (see §9.1.2).|
|[8]|The Driver manually brakes using the TBL.|
|[9a]|The ATO-OB loses any ATO Operational Condition.|
|[9b]|The Train Applicable conditions for operating ATO are not fulfilled OR ATO-OB loses any ATO<br>Operational Condition (see §9.1.1) except “The ETCS-OB applicable conditions for ATO<br>Operational are fulfilled” (see §9.1.1.1 a)).|
|[10]|The ETCS-OB leaves AD Mode|
|[11]|The ATO-OB detects a fault which does not allow performing ATO functions (e.g. connection<br>with ETCS-OB is not active while ATO-OB is not in CO State).|
|[12]|The ATO-OB is powered off.|

#### **Table 7 Transition conditions table**

<!-- end of page 71 -->

## **9.11 ATO-OB Active Functions Table**

9.11.1.1 X = functions shall be active

Empty case = function shall be inactive

O = Optional (function is not required for interoperability, but is not forbidden)

|**ATO-OB FUNCTIONS**|**RELATED**<br>**SRS§**|**NP**|**CO**|**NA**|**AV**|**RE**|**EG**|**DE**|**FA**|
|---|---|---|---|---|---|---|---|---|---|
|**General requirements**||||||||||
|SP version management|10.1.7.25||X|X|X|X|X|X||
|**ATO Functions**||||||||||
|Compute the ATO Operational<br>Speed Profile|7.1.2, 7.1.3,<br>7.1.4||O|O|O|O|X|X||
|Send traction commands|7.1.5||||||X|||
|Send braking commands|7.1.5<br>6.2.1.6||||X|X|X|X||
|Send<br>train<br>doors<br>opening/closing requests|7.2.2||||X||X|||
|Compute the dwell time|7.2.3|||X<sup>1</sup>|X|X||||
|Manage changes in Stopping<br>Points in the JP|7.3|||X<sup>1</sup>|X|X|X|X||
|Hold train at a Stopping Point|7.2.3.3, 7.4|||X<sup>1</sup>|X|X||||
|Manage low adhesion|7.5||||||X|X||
|Time Management|7.6||X|X|X|X|X|X|O|
|Provide STRs to ATO-TS|7.7||X<sup>1</sup>|X|X|X|X|X|O|
|Detect data inconsistency|7.8||X<sup>1</sup>|X<sup>1</sup>|X|X|X|X||
|ATO<br>System<br>Version<br>Management|7.9|||X<sup>1</sup>|X|X|X|X||
|ATO-OB<br>Train<br>Position<br>Determination|7.9.4|||X<sup>1</sup>|X|X|X|X||
|Driver Advisory System (DAS)|7.11||O|X<sup>2</sup>|X<sup>2</sup>|X<sup>2</sup>|O|O||
|Perform ATO-OB self-tests|7.12||O|O|O|O|O|O||
|ATO-OB Data acquisition|7.13||X|X|X|X|X|X||
|**ATO-OB States Management**<br>**Conditions**||||||||||
|Determine ATO-OB State|9.10||X|X|X|X|X|X|X|
|**ATO Communication**||||||||||
|Send and receive information<br>to/from the ETCS-OB|10.2||X|X|X|X|X|X|O|

<!-- end of page 72 -->

|**ATO-OB FUNCTIONS**|**RELATED**<br>**SRS§**|**NP**|**CO**|**NA**|**AV**|**RE**|**EG**|**DE**|**FA**|
|---|---|---|---|---|---|---|---|---|---|
|Send and receive messages<br>to/from the ATO-TS<sup>3</sup>|10.1||X|X|X|X|X|X||

1 When the JP and SP information required is available.

2 When clause §8.2.8.1 is fulfilled.

3 Excluding function “Provide STRs to ATO-TS”.

#### **Table 8 ATO-OB Active Functions table**

## **9.12 ETCS Mode transition request**

9.12.1.1 The ATO-OB shall request the ETCS-OB to be in AD Mode as long as any of the following conditions is fulfilled:

- a) The ATO-OB is in RE, EG or DE State;

- b) The ATO-OB is in AV State, the ETCS-OB is in AD Mode and the TBL is in neutral position.

9.12.1.2 To change from “not requesting AD Mode” to “requesting AD Mode”, the ATO-OB shall first verify that the current ETCS-OB Mode is not AD.

9.12.1.3 **Note:** The ATO-OB needs to verify that the ETCS-OB has left AD Mode before requesting it again to guard against situations where the ATO-OB may become disengaged while the ETCS-OB remains in AD mode. For example, if the ATO-OB transitions to RE State due to a momentary brake request from the TBL and then requests AD Mode again, there is a possibility that the ETCS-OB could miss the “AD Mode Not Requested” information.

9.12.1.4 **Note:** When the ATO-OB stops requesting the ETCS-OB to be AD Mode, the ETCS-OB will change from AD Mode to the applicable ETCS Mode according to the ETCS mode transition table as defined in [Ref 5] §4.6.

<!-- end of page 73 -->
