# **6. OVERVIEW**

## **6.1 ERTMS/ATO Reference Architecture**

<!-- Start of picture text -->
SUBSET-139*<br>Driver Train<br>SUBSET-147*<br>ERA_ERTMS_015560<br>SUBSET-034<br>DMI<br>function ATO - OB<br>SUBSET-130<br>ETCS - OB SUBSET-143<br>SUBSET-126<br>SUBSET-148<br>SUBSET-027<br>ATO - TS<br>ORD<br><!-- End of picture text -->

***only applicable for new vehicles**

#### **Figure 1 ERTMS/ATO reference architecture**

## **6.2 Generic Requirements**

6.2.1.1 The ATO-OB shall drive the train automatically while it is engaged.

6.2.1.2 **Note:** The ATO-OB can only be engaged by the driver.

6.2.1.3 The ATO-OB shall drive the train so as to respect the time table provided by ATO-TS without infringing the safe limits imposed by ETCS-OB (see §7.1).

6.2.1.4 The driver shall be able to drive manually the train while the ATO-OB is not engaged.

6.2.1.5 The ATO-OB shall not command the Emergency Brake.

6.2.1.6 When the train stops while the ATO-OB is engaged, the ATO-OB shall maintain the train stationary until the departure condition is fulfilled, which can be one of the following:

- a) if the train is stationary at a Stopping Point, the ATO-OB is going to EG State;

- b) if the train is stationary but NOT at a Stopping Point, the MA allows the train to move.

6.2.1.7 The ATO-OB shall maintain the train stationary requesting to the train the application of the Train Holding Brake.

6.2.1.8 If the Train Holding Brake force is not sufficient to maintain the train stationary, the ATOOB shall request to the train the application of the train brake in addition to the Train Holding Brake.

<!-- end of page 19 -->

6.2.1.9 The train will provide a feedback related to actual application of Holding Brake.

6.2.1.10 If the train is not able to provide Holding Brake Application feedback (configuration

parameter), the ATO-OB shall consider Holding Brake is applied after it has been commanded.

6.2.1.11 While the train is automatically driven, the ATO-OB shall disengage if the driver activates manually the brake via the TBL.

6.2.1.12 While it is engaged, the ATO-OB shall not take into account the traction commands coming from the driver. In consequence, if the driver commands traction manually via the TBL while the train is automatically driven, the ATO-OB shall remain engaged.

6.2.1.13 **Note:**The ATO-OB has no functionality regarding the execution of ETCS track conditions. This is a responsibility of ETCS-OB, external systems or the driver.

6.2.1.14 The ATO-TS shall inform the ATO-OB using the SPs or JPs, if it is not possible to apply traction, e.g. due to passing through a powerless section (i.e. current consumption limitation zone with a current limit value set to “0”).

6.2.1.15 **Note:**The ATO-OB is not responsible to check the vigilance of the Driver’s activity control function in accordance with clause 4.2.9.3.1 in [Ref 17]. This is a responsibility of an external system.

6.2.1.16 **Note:**The driver is responsible to verify that it is safe to begin automatic driving before starting automatic driving (e.g. passengers exchange completed, no obstacles, etc…).

6.2.1.17 The ATO-OB shall use the estimated train front end when determining train position information versus SP locations, unless otherwise specified in this document.

6.2.1.18 Regards stopping a train at an EOA (including temporary EOAs) it shall be possible to define in the SP a distance value as the stop location in rear of the EOA. Besides this distance value, the ability of the ATO-OB to stop the train accurately will determine the actual stop location.

## **6.3 Exported constraints**

### **6.3.1 Train**

6.3.1.1 **Exported constraint:**The installation of the ATO in the train shall ensure that a brake command from a Driver or an on-board safety system will take precedence over an ATO command.

6.3.1.2 **Note:**An on-board safety system that generates a brake command to Rolling Stock may be the Passenger Emergency Alarm (as defined in clause 4.2.5.3.3 in [Ref 17]).

6.3.1.3 **Exported constraint:**The installation of the ATO in the train shall ensure that ATO-OB is not able to apply traction when Emergency Brake is applied.

<!-- end of page 20 -->

6.3.1.4 The ETCS-OB delivers to the train a binary information to report if the ETCS-OB is in AD mode or not, see detailed requirements in [Ref 18].

### **6.3.2 Infrastructure Manager**

6.3.2.1 **Exported constraint:** The infrastructure manager shall guarantee the consistency between the ETCS track description and the data specified in the SP and JP.

6.3.2.2 **Exported constraint:** If any data is different depending on the train running direction, two different SPs shall be defined (one for each direction).

### **6.3.3 Train doors management**

6.3.3.1 **Note:** The authorisation for the release of the doors will be performed in accordance with the clause 4.2.5.5.6 in [Ref 17].

6.3.3.2 **Exported constraint:** Driver’s door commands shall always override the ATO door commands.

6.3.3.3 Note. In accordance with clause 4.2.5.5.7 in [Ref 17], Traction power will be applied only when all doors are closed and locked.

### **6.3.4 Control Centre**

6.3.4.1 **Exported constraint:** The Control Centre shall be synchronised with an external source of UTC time.

<!-- end of page 21 -->

## **6.4 Journey Profiles and Segment Profiles**

### **6.4.1 Introduction**

6.4.1.1 **Note:** A JP defines the route of a specific train by listing the SPs which will be travelled by the train.

### **6.4.2 Journey Profile (JP)**

6.4.2.1 The ATO-TS shall send JPs to the ATO-OB containing:

- a) Status of the JP;

- b) Train route data including a list of:

   - 1) SP identifier;

   - 2) SP version;

   - 3) SP travelling direction.

- c) Operational data including a list of:

   - 1) TP identifier;

   - 2) Arrival time and tolerance;

   - 3) TP alignment;

   - 4) Daylight Saving Time information;

   - 5) TP type;

   - 6) Additional TP information;

      - End of Journey;

      - Stopping Point with Relaxed couplers.

   - 7) Departure time;

   - 8) Train Hold information;

   - 9) Minimum dwell time;

   - 10) Doors management information;

- d) Dynamic infrastructure data required to operate (Temporary Constraints) including a list of:

   - 1) Temporary Constraint type (ASR, Low Adhesion, ATO Inhibition Zone, Current Consumption Limitation Zone or DAS Inhibition Zone);

   - 2) Temporary Constraint location;

   - 3) ASR speed level and a qualifier which indicates if the supervision of the end of the speed restriction relates to the front or the rear end the train;

   - 4) Low adhesion rate (if applicable).

6.4.2.2 All location information shall be referred to a Segment Profile ID and given as a distance from the beginning of that SP, unless otherwise specified.

6.4.2.3 The JP shall include the list of SPs to be travelled by the ATO-OB in the order defined by the train movement.

<!-- end of page 22 -->

6.4.2.4 The ATO-OB shall use the travelling direction information to determine if the corresponding SP will be travelled in nominal or reverse direction.

6.4.2.5 The JP shall identify, for each Stopping Point, if the ATO-OB has to manage train doors opening (including the sides for opening the doors) and train doors closing.

6.4.2.6 When entering into a Low Adhesion Area, ATO Inhibition Zone, DAS Inhibition Zone, Current Consumption Limitation Zone, Dynamic Brake inhibition area, Dynamic Brake force limit area or ASR, the ATO-OB shall consider the restriction from the estimated front end of the train.

6.4.2.7 When leaving a Low Adhesion Area, ATO Inhibition Zone, Current Consumption Limitation Zone, Dynamic Brake inhibition area, Dynamic Brake force limit area or DAS Inhibition Zone the ATO-OB shall consider the end of the restriction from the estimated rear end of the train.

6.4.2.8 When leaving an ASR, the ATO-OB shall consider the end of the restriction depending on the value of the qualifier which indicates if the supervision of the end of the speed restriction relates to the front or the rear end the train.

6.4.2.9 If the TRN (Train Running Number) changes, the ATO-OB shall delete any stored JP and it shall send a new HSReq.

6.4.2.10 The JP shall list all time references of TPs in chronological order.

6.4.2.11 The identifier of a TP is composed of a country/region identity number and a TP identity number unique within the country/region.

6.4.2.12 A JP shall contain only one TP EoJ, which is the last TP of that JP.

6.4.2.13 The ASR shall include any TSR defined by the ETCS and may include any operational speed restriction requested by IM or RU.

6.4.2.14 The ATO-OB shall be able to process the maximum amount of data corresponding to at least one JP and associated SPs.

6.4.2.15 The ATO-OB shall be able store at least two maximum size JPs including the maximum number of referenced maximum size SPs.

6.4.2.16 When the train moves in the direction of the JP, storage capacity occupied by JP information in rear of the SP where the rear end of the train was located in the last acknowledged STR shall be made available immediately by the ATO-OB.

6.4.2.17 **Note** : The requirement is needed to allow ATO-TS to predict the storage capacity available on-board in order not to cause the minimum memory capacity of the ATO-OB to be exceeded.

6.4.2.18 The handing-over ATO-TS shall guarantee that the remaining minimum memory size available in the ATO-OB is at least 1 maximum size JP (including the maximum number

<!-- end of page 23 -->

of referenced maximum size SPs) when a JP refers to the last Segment Profile containing the accepting ATO-TS contact information.

6.4.2.19 The accepting ATO-TS shall not send JP larger than the 1 maximum JP (including the maximum number of referenced maximum size SPs) until the train is completely within its ATO-TS area.

### **6.4.3 Segment Profile (SP)**

6.4.3.1 The ATO-TS shall send SPs to the ATO-OB containing the static infrastructure data required to operate.

6.4.3.2 A SP shall contain the following information:

- a) SP identifier;

- b) SP version;

- c) SP Status;

- d) Length of the SP (shall not be zero);

- e) Distance to stop in rear of an EOA;

- f) Offset to compute the local time from the UTC time;

- g) Altitude at the beginning of the SP;

- h) Static Speed Profile;

- i) Gradient Profile;

- j) Curve Profile;

- k) Traction system information;

- l) Current Consumption Limitation Zone;

6.4.3.3 A SP shall also contain the following information when existing:

- a) Balises information;

   - 1) BG identifier;

   - 2) Position of the balise in the balise group;

   - 3) Balise location.

- b) TP information:

   - 1) TP Identifier;

   - 2) TP Location;

   - 3) Stopping tolerance;

   - 4) Stopping Point Reached distance;

   - 5) TP Name.

- c) Platform areas;

- d) Tunnel information;

- e) Axle Load Speed Profile;

- f) Stop in rear of an unprotected level crossing (according to the direction of the SP);

- g) Permitted Braking Distance;

- h) Switch off Regenerative Brake areas;

- i) Switch off eddy current brake for service brake areas;

<!-- end of page 24 -->

- j) Switch off eddy current brake for emergency brake areas; k) Switch off Magnetic Shoe Brake areas; l) ATO-TS Contact Information. m) Dynamic brake force limit area n) Dynamic brake inhibition area

6.4.3.4 The identifier of an SP is composed of a country/region identity number and an identity number within the country/region.

6.4.3.5 The nominal direction of an SP is defined by the direction from beginning to end.

6.4.3.5.1 **Note** : An SP may be used in nominal or reverse direction (§6.4.2.4).

6.4.3.6 The SP definition shall ensure that two consecutive SPs are contiguous, i.e. there is no location gap nor overlap between them.

6.4.3.7 All location information shall be given as a distance from the beginning (nominal direction) of the SP, unless otherwise specified.

6.4.3.8 **Note:** Valid location values range between 0 (zero, inclusive) and the length of that SP (inclusive).

6.4.3.9 The ATO-OB shall consider the Stop in rear of an unprotected level crossing restriction from the front end of the train.

6.4.3.10 The distance to stop in rear of an EOA shall be given as a distance from the EOA.

6.4.3.11 Each SP shall have a unique identity number within an ETCS NID_C area.

6.4.3.12 The SP shall have a version number in order to detect if the Infrastructure Manager has brought some changes i.e. if an SP stored in the ATO-OB has become obsolete.

6.4.3.13 **Note:** On-board preloading of SPs may be implemented but the way to do it is not standardised (application specific).

6.4.3.14 For each data type, the list of items shall be included in increasing order of location starting from the beginning of the SP.

<!-- end of page 25 -->
