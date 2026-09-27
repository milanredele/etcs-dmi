# **7. ATO FUNCTIONS**

## **7.1 Driving Function**

### **7.1.1 Introduction**

7.1.1.1 The driving function of the ATO-OB is made up by the following functional features:

- a) Time Table Speed Management (TTSM) – See §7.1.2: establishes the optimum speed to achieve the Stopping or Passing Points on time in the most energy efficient way.

- b) Supervised Speed Envelope Management (SSEM) – See §7.1.3: establishes the maximum speed the train can run without interfering with the ETCS speed limits.

- c) Automatic Train Stopping Management (ATSM) – See §7.1.4: establishes the speed profile to stop the train accurately at the Stopping Points.

- d) ATO Traction / Brake Control – See §7.1.5: generates the output commands to drive the train according to the speeds given by the three preceding features.

7.1.1.2 **Note:** The following figure shows an overview of the functional features. This diagram does not describe the architecture.

<!-- Start of picture text -->
ATO DRIVING FUNCTION<br>               SPEED COMPUTATION<br>Supervised Speed  Automatic Train<br>Time Table Speed<br>Envelope Management  Stopping Management<br>Management (TTSM)<br>(SSEM) (ATSM)<br>ATO Operational<br>Speed Profile<br>ATO Traction /<br>Brake Control<br>ATO Output<br>Command<br><!-- End of picture text -->

**Figure 2 ATO driving function**

<!-- end of page 26 -->

### **7.1.2 Time Table Speed Management (TTSM)**

7.1.2.1 The ATO-OB shall compute a Speed Profile (TTSM) which meets the arrival times (with a related tolerance) at the TPs (taking into account the TP alignment required) defined in the JP and minimises the energy consumption as much as possible. This Speed Profile is called “Optimum Speed Profile”.

7.1.2.2 The ATO-OB takes into account the following information from the JP and SPs to compute the Optimum Speed Profile:

- a) Speed Profile defined by:

   - 1) Static Speed Profile depending on the Train Category;

   - 2) Axle Load Speed Profile depending on the Axle Load Category;

   - 3) ASR Speed level.

**Note:** This information forms an upper limit of computed optimum speed profile at each position of the train in the journey;

- b) TPs constraints define current timetable to be respected (including arrival/departure time, alignment position, skip request …);

- c) Low adhesion areas define low adhesion categories from which ATO-OB deduces the corresponding acceleration/deceleration rates reduction;

- d) Altitude information is used for prediction of available power output of combustion engines;

- e) Gradient Profile is used for prediction of running resistance;

- f) Curve Profile is used for prediction of running resistance;

- g) Traction system information is used for prediction of traction/brake capabilities of the train;

- h) Current consumption limitation zone is used for prediction of traction / brake capabilities of the train;

- i) Tunnel information is used for prediction of running resistance;

- j) Stop in rear of an unprotected level crossing (according to the direction of the SP) is used to compute travel times including an enforced stop at unprotected level crossing;

- k) Permitted Braking Distance is used for prediction of speed supervised by ETCS-OB;

- l) Switch off Special Brake areas is used for prediction of speed curve supervised by ETCS-OB and for prediction of brake capabilities of the train.

7.1.2.3 The Optimum Speed Profile shall be calculated, and kept updated, e.g. taking into account the current position and speed of the train.

7.1.2.4 The ATO-OB shall determine the Static Speed Profile to use by comparing the Train Category information received from the ETCS-OB with the Static Speed Profile information included in the SP.

<!-- end of page 27 -->

7.1.2.5 The ATO-OB shall determine the Axle Load Speed Profile to use by comparing the Axle Load Category information received from the ETCS-OB with the Axle Load Speed Profile information included in the SP.

7.1.2.6 The ATO-OB shall determine the applicable Speed Profile until the next Stopping Point from the following information:

- a) Static Speed Profile;

- b) Axle Load Speed Profile;

- c) Maximum train speed;

- d) Train length;

- e) ASR.

7.1.2.7 The ATO-OB shall take into account the predicted EBI supervision limits (see §7.1.3.8) to compute the Optimum Speed Profile.

7.1.2.8 To compute the Optimum Speed Profile, the ATO-OB shall select the applicable normal service braking model(s) from:

- a) The brake position and;

- b) The full service brake deceleration(s) at zero speed depending on:

   - 1) The applicable full service braking model(s) defined by:

      - I. The “index for trains on which the braking models are captured as Train Data” (See §7.13.1.3) and;

      - II. The combination(s) of use of regenerative brake and eddy current brake (See §7.13.1.4),

for trains on which the braking models are captured as Train Data or;

- 2) The brake percentage if it is captured as Train Data and the conversion model is applicable,

according to the clauses [Ref 5] §3.13.2.2.3.1.9 and §3.13.2.2.3.1.10.

7.1.2.9 **Note:** The way to use the information listed above in order to determine the Optimum Speed Profile is supplier specific.

### **7.1.3 Supervised Speed Envelope Management (SSEM)**

7.1.3.1 The ATO-OB shall compute the maximum speed (SSEM) the train can run avoiding ETCS intervention.

7.1.3.2 When the ETCS-OB is in ceiling speed monitoring, the ATO-OB shall drive the train at a speed lower than or equal to the ETCS permitted speed received from the ETCS-OB.

7.1.3.3 When the ETCS-OB is in target speed monitoring, the ATO-OB shall drive the train so as not to reach the ETCS EBI intervention limit received from the ETCS-OB.

<!-- end of page 28 -->

7.1.3.4 **Note:** When in AD Mode and target speed monitoring, the ETCS-OB inhibits the SB command triggered by overpassing an SBI supervision limit.

7.1.3.5 **Note:** While in AD Mode, the ETCS-OB inhibits the Sinfo sound, the over-speed sound and the warning sound in relation to speed and distance monitoring.

7.1.3.6 When the ETCS-OB is in release speed monitoring, the ATO-OB shall drive the train at a speed lower than or equal to the ETCS release speed received from the ETCS-OB.

7.1.3.7 The ATO-OB shall compute the EBD curves within the current MA as defined in [Ref 5] §3.13.8.3, using the information sent by the ETCS-OB:

- a) Value of safe deceleration (A_safe(V,d)) computed by the ATO-OB as defined in [Ref 5] §3.13.6.2.1.3 from:

   - 1) A_GRADIENT (d);

   - 2) A_MAXREDADH (d);

   - 3) A_BRAKE_SAFE (d,V).

- b) MRSP;

- c) Distance to the EOA or LOA currently supervised by the ETCS-OB;

- d) Permitted speed at the EOA or LOA currently supervised by the ETCS-OB;

- e) Distance to the SvL.

7.1.3.8 The ATO-OB shall predict an estimation of the EBI supervision limits based on the computed EBD curves based on [Ref 5] §3.13.9.3.2, using the following information sent by the ETCS-OB:

- a) Time during which the traction effort is still present after the Emergency brake intervention;

- b) Brake reaction time during which the braking effort is not yet present after the Emergency brake intervention;

- c) Remaining time during which the traction effort is not present until the equivalent brake build up time elapses after the Emergency brake intervention;

- d) Compensation of the inaccuracy of the speed measurement;

- e) Current estimated train speed;

- f) Current estimated train acceleration.

7.1.3.9 The ATO-OB shall stop the train at a distance in rear of an EOA, as defined in the SP.

7.1.3.10 **Note:** The algorithm to establish the ATO maximum speed within the ETCS target, ceiling and release speed limits is supplier specific.

### **7.1.4 Automatic Train Stopping Management (ATSM)**

7.1.4.1 The ATO-OB shall define the speed profile (ATSM) to stop the train automatically at the Stopping Points (taking into account the TP alignment required in the JP).

<!-- end of page 29 -->

7.1.4.2 The ATO-OB shall consider the stopping window of a Stopping Point as the Stopping Point location ± the required stopping tolerance mentioned in the SP.

7.1.4.3 The JP, sent from the ATO-TS, shall identify the required Stopping Points of the train from the list of TPs included in the SP (which contain their position). It shall also define if the train has to align to each Stopping Point with its front, its middle or its rear end.

7.1.4.4 **Note:** The ATO-OB disengages when it stops the train at a Stopping Point considered as reached independently of whether the ATO-OB has stopped the train within the stopping window or not. It is therefore a manual operation, by the driver, to align the train or to take other actions, if necessary, depending on local procedures.

7.1.4.5 **Note:** The algorithm to establish the ATSM Speed Profile is supplier specific.

### **7.1.5 ATO Traction / Brake Control**

7.1.5.1 The ATO Traction / Brake Control generates the ATO output commands in order to follow the ATO Operational Speed Profile defined from TTSM, ATSM and SSEM. The train will use these commands to control traction and brakes.

7.1.5.2 The ATO-OB shall take into account the following information from the JP and SPs affecting the Traction or Brake effort limits in order to compute the traction/braking commands:

- a) Low adhesion areas;

- b) Current consumption limitation zone (including powerless section);

- c) Switch off Regenerative Brake areas;

- d) Switch off eddy current brake for service brake areas;

- e) Switch off eddy current brake for emergency brake areas;

- f) Switch off Magnetic Shoe Brake areas.

7.1.5.3 To compute the traction/braking commands, the ATO-OB shall take into account the following information:

- a) The nominal rotating mass (if available);

- b) The currently applicable normal service braking model selected from:

   - 1) The brake position and;

   - 2) The full service brake deceleration at zero speed depending on:

      - I. The applicable full service braking model defined by:

         - I.I. The “index for trains on which the braking models are captured as Train Data” (See §7.13.1.3) and;

         - I.II. The current combination of use of regenerative brake and eddy current brake (See §7.13.1.4),

         - for trains on which the braking models are captured as Train Data or;

      - II. The brake percentage if it is captured as Train Data and the conversion model is applicable,

<!-- end of page 30 -->

according to the clauses [Ref 5] §3.13.2.2.3.1.9 and §3.13.2.2.3.1.10.

7.1.5.4 **Note:** Traction and brake outputs should be adapted to the train characteristics to enable control of the vehicle maintaining adequate acceleration/deceleration and jerk limitation. This adaptation is application specific.

7.1.5.5 **Note:** The ATO-OB should aim to reduce the transitions between traction and braking. The actual requirement related to this transition minimisation is supplier and application specific.

7.1.5.6 **Note:** The interface to transmit the output from ATO-OB to the train is specified in [Ref 9].

7.1.5.7 For S-type trains, the ATO-OB shall consider the “dynamic brake force limit area” defined in SP when regulating the train speed throughout this area.

7.1.5.8 For S-type trains, the ATO-OB shall request for a Full Service Brake by requesting the maximum train brake and, if applicable, the maximum dynamic brake, respecting current dynamic brake force limits.

7.1.5.9 For S-type trains when applicable for a given vehicle: if the dynamic brake is requested and not confirmed by the train, then the ATO-OB shall use the train brake instead.

7.1.5.10 When applicable for given vehicle: if the locomotive brake is requested and not confirmed by the train, then the ATO-OB shall use the train brake instead.

7.1.5.11 When applicable for given vehicle: if the holding brake is requested and not confirmed by the train, then the ATO-OB shall use the train brake instead.

7.1.5.12 **Note:** The rest of this section contains driver craftsmanship acts which should be considered by the ATO-OB.

7.1.5.13 For S-type trains, if the ATO-OB is configured to manage the dynamic brake, the maximum permitted dynamic brake force realised by locomotive alone or in multiple traction should not exceed the values defined in the following formulae due to the maximum longitudinal force in the train.

   - V ≤ 30 km/h:           Fdyn[kN] = 150 KN;

   - 30 < V ≤ 60 km/h:  Fdyn[kN] = 40 KN + 3,67 x V [km/h];

   - V > 60 km/h:           Fdyn[kN] = 260 KN.

Where V is current speed

(refer to [Ref 15] 4.3.3.1)

7.1.5.14 **Note** : the train is configured to manage the dynamic brake limits if the relevant data are available at train level.

7.1.5.15 For S-type trains, the ATO OB should send a quick brake release request when necessary to guarantee that the train brake is released before applying traction or

<!-- end of page 31 -->

coasting. The ATO-OB should consider that the train brake is completely released when the train brake release time is elapsed, where train brake release time is defined according to the following Table 3:

|_brake release_|||_type of tr_|_ain_|||
|---|---|---|---|---|---|---|
||_passen_|_ger,_|_freig_|_ht,_|_freigh_|_t,_|
||_P posi_|_tion_|_P posi_|_tion_|_G posit_|_ion_|
||_standard_|_EP_|_standard_|_EP_|_standard_|_EP_|
|_by using high pressure_<br>_filling stroke_|_25 s_|_15 s_|_25 s_|_20 s_|_75 s_|_20 s_|
|_by_<br>_using_<br>_release_<br>_position only_|_40 s_|_15 s_|_60 s_|_20 s_|_120 s_|_20 s_|

#### **Table 3 Train brake release time**

7.1.5.16 The train should give a feedback on the way the quick brake release has been applied including the details whether it is realised by means of high pressure filling stroke or overcharging feedback. When the train is not able to provide such a feedback, then the ATO-OB should always consider the highest possible value belonging to the category for the train brake release time.

7.1.5.17 To start S freight trains on flat track or small gradient (when holding brake is sufficient to immobilise the train), the ATO-OB should

- a) Release the train brake if it is still applied (after manual train stop), and possibly send a quick brake release request to guarantee that the indirect brake is released before applying traction;

- b) Wait that the train brake is completely released;

- c) Start commanding traction (while holding brake is still applied by the train).

7.1.5.18 **Note** : The train will automatically release the holding brake when traction is applied.

7.1.5.19 To start S passengers trains on flat track or small gradient (when holding brake is sufficient to immobilise the train), the ATO-OB should

- a) Release the train brake if it is still applied (after manual driving before stop);

- b) Wait that the train brake is completely released;

- c) Start commanding traction (while holding brake is still applied by the train).

7.1.5.20 **Note** : The train will automatically release the holding brake when traction is applied.

7.1.5.21 To start S-type trains on steep incline (in which the holding brake force is not sufficient to maintain the train stationary), the ATO-OB should:

<!-- end of page 32 -->

- a) Request from the train the authorisation to apply traction over brake;

- b) Wait until the authorisation to apply traction over brake is given by the train;

- c) Start process of releasing the train brake;

- d) Start commanding traction according to the actual degree of the train brake release to prevent roll-back.

7.1.5.22 **Note** : The train will automatically release the holding brake when traction is applied.

7.1.5.23 To start S-type trains on steep slope down (in which the holding brake force is not sufficient to maintain the train stationary), the ATO-OB should:

- a) Start the process of releasing the train brake (the train starts to move and accelerates downhill due to gravity while the train brake is releasing);

- b) Release the holding brake at the same time as the train brake;

- c) Start commanding traction when the train brake release time is elapsed.

7.1.5.24 The ATO-OB should apply the following rules for using the brake on S-type trains:

- a) If the train consist of a locomotive only, the ATO-OB should not exclusively use the dynamic brake when braking to standstill at an EOA.

- b) For other trains (traction units with at least one wagon), the ATO-OB should not use the locomotive brake as long as standstill is not reached. As an exception the locomotive brake is allowed to be used when braking to a Stopping Point is configured with the attribute “relaxed couplers”.

- c) For other trains (traction units with at least one wagon), the ATO-OB is allowed to exclusively use the dynamic brake only when the speed is higher than a train specific value defined on-board.

7.1.5.25 The ATO-OB should apply the following rule for using the brake on all trains:

- a) The ATO-OB should be configured to ignore or to respect dynamic brake inhibition.

- b) If configured to do so, the ATO-OB should request the train to not use dynamic brake when being in a dynamic brake inhibition area.

7.1.5.26 Driving on a steep slope, the ATO-OB possibly needs to adapt the train brake effort in order to prevent the train brake exhaustion (see [Ref 16] section 5.4.4.2).

7.1.5.27 When starting on steep incline, the ATO-OB should start applying traction before releasing the train brake in order to prevent the train rolling-back if traction over brake is enabled.

## **7.2 Timing Point Management**

### **7.2.1 Timing Point states**

7.2.1.1 A Stopping Point can be considered as not used, targeted, reached or passed. These states are mutually exclusive.

<!-- end of page 33 -->

7.2.1.2 A Passing Point (or Stopping Point to be skipped) can be considered as not used, targeted or passed. These states are mutually exclusive.

7.2.1.3 Upon reception of a JP, the ATO-OB shall consider the first TP in advance of the train as the targeted one and all the other ones in advance of the train as not used.

7.2.1.4 The ATO-OB shall consider a targeted Stopping Point as reached when it has stopped (manually or automatically) within a distance in rear of or in advance of the Stopping Point (taking into account the TP alignment required in the JP). This Stopping Point Reached distance is configured in the SP.

7.2.1.5 The ATO-OB shall consider a Stopping Point as passed when any of the following conditions are fulfilled:

- a) For manually driven trains, the train has passed the “Stopping Point reached distance” beyond the Stopping Point (taking into account the Timing Point alignment required in the JP);

- b) For automatically driven trains, the Stopping Point is considered as reached and the ATO-OB enters EG State;

- c) The Stopping Point is considered as reached, the speed of the train is greater than 10 km/h and the train has passed the Stopping Point location (taking into account the TP alignment required in the JP).

7.2.1.6 A Passing Point (or Stopping Point to be skipped) shall be considered as passed when the train has passed the location of the TP (taking into account the Timing Point alignment required in the JP).

7.2.1.7 Once a TP is considered as passed, the next TP, if any, shall be the targeted TP managed by the ATO-OB.

7.2.1.8 Once a Stopping Point is considered as passed the next Stopping Point (or Stopping Point to be skipped) information, if any, shall be displayed on the DMI (see §8.2.7), but may not be the targeted TP yet if there are Passing Points in between.

### **7.2.2 Train Door Operation (TDO)**

7.2.2.1 The Train Door Operation (TDO) shall provide the opening and closing commands/information of train doors for passenger exchange.

7.2.2.2 If the JP requests the ATO-OB to manage the doors opening, the doors opening process may allow the following alternatives depending on static train configuration:

- a) Manual door opening command executed by the driver following the displayed ATOOB information (see §8.2.4.1);

- b) Automatic door opening command sent by the ATO-OB to the train in accordance with the information contained in the JP i.e. either:

   - 1) To provide doors opening after passengers’ request. Individually for each door and depending on the train door release or;

<!-- end of page 34 -->

- 2) To provide automatic centralised door opening.

7.2.2.3 If the JP requests the ATO-OB to manage the doors closing, the doors closing process may allow the following alternatives depending on static train configuration: a) Manual door closing command executed by the driver following the displayed ATOOB information (see §8.2.4.4);

- b) Automatic door closing command sent by the ATO-OB to the train.

7.2.2.4 The ATO-OB shall send an automatic door opening command to the train door management syste m when the f ollowin g conditions are fulfilled: a) Static train configuration allows automatic train doors opening; b) The ATO-OB is in EG State; c) The train is at standstill; d) The ATO-OB expects the train to stop within the stopping window of a Stopping Point.

7.2.2.5 Depending on the “centralised opening” information r eceived in the JP, the ATO-OB shall send the automatic door opening command to: a) Provide doors opening after passengers’ request individually for each door or; b) Provide automatic centralised door opening.

7.2.2.6 When the remaining dwell time is equal to the train c onfiguration time to perform normal door closure procedure, the ATO-OB shall send an automatic door closing command to the t rain door management system if the following conditions are fulfilled: a) Static train configuration allows automatic train doors closing; b) The ETCS-OB is in AD Mode.

7.2.2.7 **Note** : The management of doors that become obstructed when closing is outside the scope of the ATO-OB.

7.2.2.8 The following picture shows the options for doors opening/closing previously described.

<!-- end of page 35 -->

<!-- Start of picture text -->
Right, left  The ATO-OB requests to the<br>The train door opening is  Opening doors    or both Static  Manual ETCS-OB to display the<br>triggered in JP configuration Indication to request the driver<br>to open the doors<br>None Automatic<br>No The ATO OB sends commands<br>to open doors individually on<br>ATO-OB is in passenger request and<br>Nothing is done by the ATO-OB EG state display the  Doors are open  requests the ETCS- OB to<br>indication<br>Yes<br>No<br>The ATO OB sends commands<br>Centralised  to open the required doors and<br>opening in JP requests the ETCS- OB to<br>Yes display the  Doors are open<br>indication<br>Managed by The ATO-OB requests to the<br>The remaining dwell time  Closing doors     ATO Static  Manual ETCS-OB to display the<br>is equal to the time to close the doors in JP configuration indication to request the driver<br>to close The doors<br>Not managed by ATO Automatic No<br>The ATO-OB sends commands<br>to close doors and Requests<br>the ETCS-OB to Display the<br>Nothing is done by  ETCS is in   Doors are being closed by<br>the ATO-OB AD Mode ATO  indication<br>Yes<br><!-- End of picture text -->

**Figure 3 Door operation diagrams**

7.2.2.9 **Note:** Based on the previous requirements, the TDO operates according to the following scenario:

- a) When the train is at standstill and the ATO-OB expects the train to stop within the stopping window of a Stopping Point;

   - 1) If the ATO-OB is in EG State and the static configuration allows automatic door opening, the ATO-OB provides to the train door system the train doors opening commands or the possibility to open doors after passenger request, on the side(s) defined in the JP or;

   - 2) If the ATO-OB is not in EG State or the static configuration requests manual door opening, when the train stops within the stopping window, the ATO-OB requests to the ETCS-OB to display the indication to request the driver to open doors defined in the JP.

- b) A safe system enables the release of the appropriate doors on the correct side(s) (it may take place after the actual stop of the train, not in the scope of ATO-OB);

- c) When the train stops, the ATO-OB requests the application of the Train Holding Brake and disengages automatic driving;

- d) The ATO-OB starts the count-down of the dwell time;

- e) When the remaining dwell time is equal to the train configuration time to perform normal door closure procedure:

   - 1) If the ETCS-OB is in AD Mode and static configuration allows automatic door closing, the ATO-OB sends automatically the door closing commands to the train door system or;

   - 2) If the ETCS-OB is not in AD Mode or the static configuration requests manual door closing, the ATO-OB requests to the ETCS-OB to display the indication to request the driver to close doors.

<!-- end of page 36 -->

7.2.2.10 **Note:** The interface to transmit the output from ATO-OB to the train is specified in [Ref 9].

### **7.2.3 Dwell time Management**

7.2.3.1 While a Stopping Point is considered as reached, each time the train stops or an updated JP modifying the departure time of that Stopping Point is received:

- a) The ATO-OB shall compute the dwell time as the difference between the departure time given by the JP and the time at which the train is stopped with a minimum value corresponding to the minimum dwell time given in the JP.

- b) The ATO-OB shall start a countdown starting from the computed dwell time (remaining dwell time).

7.2.3.2 Once the dwell time is expired, the displayed remaining dwell time shall remain at zero.

7.2.3.3 If the JP requests to hold the train at a Stopping Point (see §7.4), while the train is stopped at the corresponding Stopping Point, the dwell time shall be set to hold and shall not be considered as elapsed while the Train Hold at Stopping Point is requested.

7.2.3.4 If there is any remaining dwell time or the dwell time is set to hold, the dwell time shall be set to “0” (elapsed) when the train is moving with a speed greater than 10 km/h.

7.2.3.5 **Note:** The purpose of the speed limit is to avoid a reset of the dwell time if the driver is, e.g. jogging to adjust the stopping position of the train.

## **7.3 Add/skip Stopping Point**

7.3.1.1 The ATO-TS may add additional Stopping Points or request to skip Stopping Points in real time by updating the JP.

7.3.1.2 Any newly received Stopping Point shall be ignored if the distance to the new TP is not sufficient for the ATO-OB to stop the train (supplier specific) or the TP is already passed. In this case, the ATO-TS shall be informed.

7.3.1.3 When it requests the skipping of a Stopping Point, the ATO-TS shall update the JP marking the Stopping Point in question as a Stopping Point to be skipped.

7.3.1.4 The ATO-TS shall be able to revoke a Stopping Point skip that it had requested before by means of a JP Update.

7.3.1.5 The ATO-OB shall allow the driver to request to skip the next Stopping Point when the ATO-OB is in AV, RE, EG or DE State, the next Stopping Point is not already considered as a Stopping Point to be skipped and the doors are closed and locked, unless the train is stopped at a Stopping Point considered as reached.

7.3.1.6 While the driver requests to skip the next Stopping Point, the ATO-OB shall consider that Stopping Point as a Stopping Point to be skipped.

<!-- end of page 37 -->

7.3.1.7 Once the driver has requested to skip the next Stopping Point, the ATO-OB shall store that Stopping Point skip request until one of the following conditions is met:

- a) The concerned Stopping Point is passed;

- b) The driver revokes his/her own Stopping Point skip request;

- c) Further to a JP update, the concerned Stopping Point is no longer the next stopping point referred to in the JP;

- d) Further to a JP update, the concerned Stopping Point is requested to be skipped by TS in the JP.

7.3.1.8 As long as the Stopping Point skip request by driver is stored, the driver shall be allowed to revoke this Stopping Point skip request.

7.3.1.9 When Stopping Point skipping is requested or revoked by the driver, the ATO-TS shall be informed.

7.3.1.10 For Operational Speed Profile computation purposes, the ATO-OB shall consider a Stopping Point to be skipped as a Passing Point.

7.3.1.11 **Note:** If skipping a Stopping Point at a platform requires a special speed limit for passing through the platform, ATO-TS can transmit an ASR in the “JP Update”.

## **7.4 Train Hold at a Stopping Point**

7.4.1.1 The ATO-TS shall be able to request Train Hold at a Stopping Point by means of a JP Update.

7.4.1.2 **Note:** The Control Centre may require Train Hold (via JP Update) for operational reasons for one or several trains.

7.4.1.3 When Train Hold is requested, this information shall be displayed on the DMI in such a way that the driver is clearly advised about it.

## **7.5 Low Adhesion Management**

7.5.1.1 When low adhesion is selected by the driver, this information shall be sent by the ATOOB to the ATO-TS.

7.5.1.2 When the ATO-OB is informed about “slip/slide” from an external system, this information shall be sent to the ATO-TS.

7.5.1.3 **Note:** Slip/slide information is used by the ATO-OB for diagnostic purposes.

<!-- end of page 38 -->

7.5.1.4 If Control Centre provides the functionality to advise ATO-TS about areas of reduced adhesion, the ATO-TS shall inform the concerned trains about the “Low adhesion Area” via the JP.

7.5.1.5 The ATO-OB shall adapt the ATO Operational Speed Profile and traction / braking commands according to the “adhesion category” transmitted via the JP.

7.5.1.6 When it receives a JP without low adhesion information, the ATO-OB shall consider the adhesion as the condition non slippery rail.

## **7.6 Time Management**

7.6.1.1 The ATO-OB and ATO-TS shall use the UTC Time with an accuracy of ±1 second.

7.6.1.2 All the time variables included in the ATO packets (e.g. timestamp, estimated arrival time…) shall be in UTC, unless otherwise specified.

7.6.1.3 ATO-OB shall be able to convert UTC Time to Local Time in order to display to the driver the arrival time to upcoming Stopping Points.

7.6.1.4 **Note:** The Local Time is defined as:

- Local Time = UTC Time + UTC Time Zone Offset + Daylight Saving Time, where:

- Coordinated Universal Time (UTC) is the current reference time.

- UTC Time Zone Offset is the difference in minutes from UTC Time for a place and

- date ([Ref 7]).

- Daylight Saving Time (DST) is the practice of setting the clocks forward one hour

- from standard time during the summer months, and back again in the fall, to make better use of natural daylight.

7.6.1.5 **Note** : The UTC Time Zone Offset value is indicated in the SP; while the Daylight Saving Time is indicated in the JP.

## **7.7 Reporting Management**

7.7.1.1 The ATO-OB shall send STRs to an ATO-TS from the moment it has received a JP from that ATO-TS until the last TP included in the JP received from that ATO-TS is considered as passed unless otherwise specified.

7.7.1.2 While being in FA State, the ATO-OB shall try to send STRs to an ATO-TS regardless the other conditions.

7.7.1.3 If an acknowledgement to the previous STR has been received, or if this is the first STR following a Communication Session establishment, the ATO-OB shall send an STR to the ATO-TS when:

- a) There is a change of the ATO Operation State;

<!-- end of page 39 -->

- b) There is a change of one of the indicators (See §7.7.1.6 g));

- c) The reporting time interval for triggering an STR is elapsed (if cyclic reporting is configured);

- d) The train passes a Passing Point;

- e) The length of the train has changed.

7.7.1.4 The ATO-OB may combine several triggering conditions in one STR, but it shall send an STR at the latest one second after the condition has been detected.

7.7.1.5 The reporting time interval for triggering an STR shall restart after an STR is sent (either event-based or cyclical).

7.7.1.6 The ATO-OB shall inform the ATO-TS about:

- a) The current ATO-OB State;

- b) The speed of the train at the moment the STR is sent;

- c) Train position information:

   - 1) SP identifier;

   - 2) The position of the estimated front end of the train, in relation to the beginning of the SP at the moment the STR is sent.

- d) The following information concerning the most recent TP considered as either reached or passed:

   - 1) TP identifier;

   - 2) Qualifier to indicate if the train stopped, departed or passed the TP (see §7.7.1.71.1.1.a) 8));

   - 3) In case of stopping, if the train stopped within the stopping window.

- e) The estimated arrival time to, at least, the next TP belonging to its current JP:

   - 1) TP identifier;

   - 2) Estimated arrival time.

- f) The Driver ID;

- g) The following indicators:

   - 1) JP-SP inconsistency;

   - 2) Routing Error;

   - 3) Next Stopping Point Skip;

   - 4) Low adhesion reported by the driver;

   - 5) Slip/Slide information detected by external system;

   - 6) Operational conditions fulfilment;

   - 7) Train is moving;

   - 8) Unable to stop at the next Stopping Point;

- h) The length of the train.

7.7.1.7 The “qualifier to indicate if the train stopped, departed or passed the TP” shall be set to:

- a) “Stopped” from the first time the train stops at a Stopping Point considered as reached until that Stopping Point is considered as passed;

<!-- end of page 40 -->

- b) “Departed” while the condition a) is not fulfilled and the last TP considered as passed is a Stopping Point;

- c) “Passed” while the condition a) is not fulfilled and the last TP considered as passed is a Passing Point or Stopping Point to be skipped.

7.7.1.8 The ATO-TS shall send an STRAck packet to the ATO-OB as an answer to each STR received using the timestamp and the packet counter information of that STR.

## **7.8 Data Consistency Management**

### **7.8.1 Introduction**

7.8.1.1 The ATO-OB shall detect data inconsistency when:

a) A Routing Error or;

b) A Segment and Journey Profiles Consistency Error, is detected.

7.8.1.2 If ATO-OB detects any data inconsistency:

- a) The ATO-OB shall inform the ATO-TS about inconsistency through the STR;

- b) The ATO-OB shall not use inconsistent data.

### **7.8.2 Routing Errors**

7.8.2.1 An ATO-OB which has located the train in an SP included in the current JP shall detect a Routing Error:

- When the identifier of the next balise group announced in the ETCS Linking Information received from the ETCS-OB is not included in the balise groups listed in the SPs referenced by the JP, AND

- The remaining distance to this next balise group does not exceed the remaining distance covered by the JP, AND

- This next balise group is not announced as “unknown but containing repositioning information”.

7.8.2.2 The ATO-OB shall lose the ATO Operational Conditions when a Routing Error is detected.

### **7.8.3 Segment and Journey Profiles Consistency Error**

7.8.3.1 The ATO-OB shall detect Segment and Journey Profiles Consistency Error if:

- a) TP included in the JP is not found in the corresponding SP;

- b) The ATO-TS sends an SP with the status “invalid”;

c) Time references of TPs listed in the JP are equal, or not in ascending order;

<!-- end of page 41 -->

- d) The SP does not provide the location values in increasing order for any profile data type;

- e) Any location data given in an SP is longer than the length of the SP;

- f) Any length data given in the SP is zero;

- g) The SP version of an SP received is not the one included in the corresponding JP.

7.8.3.2 If Segment and Journey Profiles Consistency Error is detected, the ATO-OB shall lose the ATO Operational Conditions when data inconsistency affects the journey to the next TP.

<!-- end of page 42 -->

## **7.9 ATO System Version Management**

### **7.9.1 Introduction**

7.9.1.1 The ATO shall have a version number which will be transmitted in the ATO-OB/ATO-TS interface in order to support ATO backward compatibility.

7.9.1.2 The evolution of the versions of the ATO system shall be sequential, i.e. there shall only be one direct upgrade of an existing version and no branch is accepted.

7.9.1.3 The ATO system version shall be identified by a version number which complies with the following:

- a) Each version number will have the following format: X.Y;

- b) The first number (major version) distinguishes incompatible versions;

- c) The second number (minor version) indicates compatibility within a major version X;

- d) If the first numbers of two versions are the same, this indicates that those versions are compatible, independently of the second number.

7.9.1.4 The major version will be increased in case of a non-compatible change.

7.9.1.5 The minor version will be increased in case of a compatible change.

7.9.1.6 The ATO-OB and the ATO-TS may support several major ATO system versions.

### **7.9.2 Compatibility/Incompatibility criteria**

7.9.2.1 The compatibility/incompatibility between two consecutive ATO system versions is established by analysing the relationship between an ATO-OB operating one system version and an ATO-TS operated with the other one.

7.9.2.2 In the following sections, version A is the existing system version, while version B is the subsequent system version, for which the compatibility/incompatibility is to be determined.

7.9.2.3 The version B is compatible with version A if both following conditions are met:

- a) a train operating version A can run a normal service on trackside infrastructure operated with version B;

- b) a train operating version B can run a normal service on trackside infrastructure operated with version A.

7.9.2.4 Conversely, the version B is incompatible with version A if one of following conditions is met:

- a) there is a technical, operational or safety related obstacle preventing a train operating version A from running a normal service on a trackside infrastructure operated with version B;

<!-- end of page 43 -->

- b) there is a technical, operational or safety related obstacle preventing a train operating version B from running a normal service on a trackside infrastructure operated with version A.

7.9.2.5 The expression “train running a normal service” shall be understood as “train which is not penalised because of a reduction of performance or safety”.

### **7.9.3 Use of the ATO system version**

7.9.3.1 On setting up a communication session between ATO-OB and ATO-TS equipment, the ATO-OB shall send its major ATO system version(s) and for each of them the corresponding highest supported minor version.

7.9.3.2 The ATO-TS shall answer with the ATO system version that will be used by the ATO-TS for the ATO-OB/ATO-TS communication. The major version to be used by the ATO-TS shall be the highest supported by both ATO-OB and ATO-TS.

7.9.3.3 The ATO-OB shall use the same major ATO system version as the ATO-TS for the track/train communication.

7.9.3.4 Within one of its supported system version numbers X, the ATO-OB shall always operate the highest system version number Y it supports, regardless of the system version number Y transmitted by the ATO-TS.

7.9.3.5 If no major ATO system version is supported by both ATO-OB and ATO-TS, the ATOTS shall answer with a “no compatible” value of the ATO system version to be used and the communication shall be terminated.

### **7.9.4 Envelopes of system versions**

#### **7.9.4.1 ATO-TS - envelope of legally operated system versions**

7.9.4.1.1 The system version number X, which an ATO-TS is allowed to operate with, shall be 1.

7.9.4.1.2 Within system version number X = 1, the system version number Y that an ATO-TS is allowed to use shall be any of the following: 0 or 1.

7.9.4.1.2.1 Note: for the relevancy of this clause to the ATO-TS, see [Ref 19] § 4.5.1.2, which can be applied by analogy for the ERTMS/ATO system.

**7.9.4.2 ATO-OB – allowed envelopes of supported system versions**

7.9.4.2.1 The highest system version number supported by the ATO-OB shall be one of the following: 1.0 or 1.1.

<!-- end of page 44 -->

### **7.9.5 ATO-OB system version vs. ETCS-OB system version**

7.9.5.1 Only the ATO-OB  ETCS-OB combinations listed in the Table 3a below shall be allowed, where the system version number X.Y indicates the highest system version supported by the ATO-OB/ETCS-OB.

**Possible combinations of system version number X.Y** ATO-OB 1.0  ETCS-OB 2.2 ATO-OB 1.1  ETCS-OB 3.0

#### **Table 3a ATO-OB/ETCS-OB possible system version number combinations**

7.9.5.2 In case the ATO-OB, whose highest supported system version is 1.0, is interfaced to an ETCS-OB 2.2 (i.e. an ETCS-OB that supports a reduced envelope of ETCS system versions, which includes all the ETCS system versions from 1.0 up to 2.2), see [Ref 20] for the applicable exceptions.

## **7.10 ATO-OB Train Position Determination**

7.10.1.1 The ATO-OB shall determine the train position within an SP from:

- a) The most recently received value of the position counter;

- b) The position counter at the moment a balise contained in an SP referred to in the current JP was passed;

- c) The balise position given in the SP;

- d) The distance from the antenna to the train front end;

- e) The distance travelled during the estimated time elapsed since the time at which the position counter was determined.

7.10.1.2 **Note:** The estimated time elapsed since the time at which the position counter was determined (see §7.10.1.1e)) considers:

- a) The time elapsed between the time at which the position counter was determined and the packet timestamp and;

- b) The estimated time elapsed since the packet was received.

7.10.1.3 The following figure presents how the ATO-OB determines the train position within an SP using the data defined in §7.10.1.1:

<!-- end of page 45 -->

<!-- Start of picture text -->
SP start N_LOC_BALISE  N_LOC_REF<br>D_Location of the balise D_Antenna d (∆t)<br>Distance in SP<br>SP front end<br><!-- End of picture text -->

#### **Figure 4 Train position within the SP**

Where:

- a) N_LOC_REF is the most recently received value of the position counter;

- b) N_LOC_BALISE is the position counter at the moment a balise contained in an SP referred to in the current JP is passed;

- c) D_Location of the balise is the balise position given in the SP;

- d) D_Antenna is the distance from the antenna to the train front end;

- e) d (∆t) is the distance travelled during the estimated time elapsed since the time at which the position counter was determined.

<!-- end of page 46 -->

7.10.1.4 In order to supervise any element sent by the ETCS-OB, the ATO-OB shall determine the front end of the train as follows:

Estimated front end = N_LOC_REF + Qrc*(D_Antenna + d (∆t))

Max safe front end = N_LOC_REF + Qrc*(D_Antenna + L_UNCERTAINTY_UNDERREADING + d (∆t)) Min safe front end = N_LOC_REF + Qrc*(D_Antenna - L_UNCERTAINTY_OVERREADING + d (∆t)) Where:

- a) N_LOC_REF is the most recently received value of the position counter;

- b) D_Antenna is the distance from the antenna to the train front end;

- c) L_UNCERTAINTY_UNDERREADING is the under-reading amount of the confidence interval to the train position from the SOLR;

- d) L_UNCERTAINTY_OVERREADING is the over-reading amount of the confidence interval to the train position from the SOLR;

- e) d (∆t) is the distance travelled during the estimated time elapsed since the time at which the position counter was determined;

- f) Qrc is the factor to indicate whether a movement in the direction of the train orientation corresponds to an increase (Qrc = 1) or a decrease (Qrc = -1) of the raw counter.

<!-- Start of picture text -->
N_LOC_REF Estimated front end<br>D_Antenna d (∆t)<br>L_UNCERTAINTY_OVERREADING L_UNCERTAINTY_UNDERREADING<br>Confidence interval<br>min safe front end max safe front end<br><!-- End of picture text -->

#### **Figure 5 Train position to supervise ETCS-OB elements**

7.10.1.5 The ATO-OB shall determine the estimated rear end position of the train as the estimated front end position minus the length of the train provided by the ETCS-OB.

7.10.1.6 The ATO-OB shall determine the minimum safe rear end position of the train as the minimum safe front end position minus the length of the train provided by the ETCS-OB.

<!-- end of page 47 -->

7.10.1.7 When locating the train for the first time in a JP, the ATO-OB has to check which of the 3 balise information received from the ETCS-OB are contained in an SP referred to in the current JP:

- a) If at least two different balises out of the three are contained in an SP referred to in the current JP, the ATO-OB shall determine the train position within an SP from:

   - 1) The travelling direction given in the JP;

   - 2) The information of those balises.

- b) If only the reference balise of the SOLR is contained in an SP referred to in the current JP, the ATO-OB shall determine the train position within an SP from:

   - 1) The travelling direction given in the JP;

   - 2) The orientation of the train in relation to the direction of the SOLR;

   - 3) The position of the front end of the train in relation to the SOLR (nominal or reverse side of the SOLR);

   - 4) The information about the SOLR.

- c) If none of the previous conditions is fulfilled, the ATO-OB will not be able to locate the train within an SP referred to in the current JP using the received balise information.

7.10.1.8 **Note:** The ATO-OB may be directly interfaced to odometer sensors (application specific).

## **7.11 Driving Advisory System (DAS)**

7.11.1.1 The ATO-OB shall compute DAS trajectories defined by a “Target Advice Speed” or a “Coasting advice” and a “distance to next advice change” in order to follow the ATO Operational Speed Profile defined from TTSM, ATSM and SSEM.

7.11.1.2 **Note:** The way to establish DAS trajectories to follow the ATO Operational Speed Profile is supplier specific.

## **7.12 Perform ATO-OB self-tests**

7.12.1.1 The ATO-OB system shall execute automatically (without requiring additional action by staff) self-tests procedures (if any) to determine whether the equipment is capable of operating and is fit for service.

7.12.1.2 The ATO-OB shall make sure that performed self-tests (if any) do not have any impact on connected systems (e.g. ETCS-OB, Rolling Stock).

7.12.1.3 **Note:** The execution or not of any self-test is supplier specific.

7.12.1.4 When self-tests fail, the ATO-OB shall go to Failure State.

<!-- end of page 48 -->

## **7.13 ATO-OB Data acquisition**

### **7.13.1 ETCS Data**

7.13.1.1 The ETCS data transmitted by the ETCS-OB to the ATO-OB shall include a subset of the ETCS Train Data (defined in [Ref 5]), as listed below:

- a) Train category(ies);

- b) Train length;

- c) Traction / brake parameters:

   - 1) Nominal rotating mass (if available);

   - 2) Brake Percentage (if captured as ETCS Train Data and the conversion model is applicable);

   - 3) Brake Position.

- d) Maximum train speed;

- e) Axle load category.

7.13.1.2 The ETCS data transmitted by the ETCS-OB to the ATO-OB shall include an “Index for trains on which the braking models are captured as Train Data”. This index refers to the set of full service braking models preconfigured in the ETCS-OB, which are currently applicable according to the capture of the ETCS Train Data.

7.13.1.3 Each value of the “Index for trains on which the braking models are captured as Train Data” refers to a set of preconfigured full service braking models.

7.13.1.4 Each preconfigured full service braking model within a set is defined by a different combination of use of regenerative brake and eddy current brake.

7.13.1.5 Both ATO-OB and ETCS-OB shall coherently store:

- a) The sets of full service braking models with their corresponding indexes, for trains on which the braking models are captured as Train Data and;

- b) Up to six normal service braking models together with their corresponding brake position and pivot values,

following the rules defined in [Ref 5] §3.13.2.2.3.1.

7.13.1.6 **Note:** Extra data for the ATO-OB are handled in the Specific ATO Data Entry procedure (see §7.13.2).

7.13.1.7 The ETCS data transmitted by the ETCS-OB to the ATO-OB shall include a subset of ETCS Additional Data (defined in [Ref 5]) as listed below:

- a) Driver ID;

- b) TRN;

- c) ETCS identity.

<!-- end of page 49 -->

7.13.1.8 The ETCS data transmitted by the ETCS-OB to the ATO-OB shall include, for each antenna installed on-board, the distance from the antenna to the train front end used by the ETCS-OB to determine the train front end position.

7.13.1.9 **Note:** ETCS Train Data could be changed and validated from sources different from the driver if acquired from ETCS-OB external sources.

### **7.13.2 Specific ATO Data Entry**

#### **7.13.2.1 Definitions**

7.13.2.2 The “Specific ATO Data” are the data that need to be requested to the driver.

7.13.2.3 All “Specific ATO Data” used by the ATO-OB are assigned a unique Data Identifier.

7.13.2.4 The process to deliver those “Specific ATO Data” to the ATO-OB is called “Specific ATO Data Entry”.

7.13.2.5 **Note:** Specific ATO Data Entry is possible at start-up and later on during mission through the Train Data Entry procedure.

#### **7.13.2.6 Responsibilities**

7.13.2.7 The ETCS-OB is responsible for the dialogue with the driver during the Specific ATO Data Entry/Validation process, for checking the technical range checks (if configured onboard) and for the transmission of the Specific ATO Data after the driver’s validation.

7.13.2.8 The ATO-OB is responsible for checking the content (e.g. range, spares, internal dependency of parameters) of the data. The ATO-OB can be exempted of technical range checks if those are configured in the ETCS-OB.

#### **7.13.2.9 General requirements**

7.13.2.10 The ETCS-OB shall offer the possibility to the driver to skip the Specific ATO Data Entry.

7.13.2.11 If Specific ATO Data becomes invalid, the ATO-OB may request the data from the ETCSOB by sending the “Specific ATO Data Need”.

7.13.2.12 Specific ATO Data can be or become invalid, because:

- a) The Specific ATO Data Entry procedure has not yet been performed or has been aborted, or

- b) The driver has skipped the Specific ATO Data Entry for the ATO-OB before the ATOOB has sent the “End of Specific ATO Data Entry” to the ETCS-OB, or

- c) The ATO-OB detects that the validity of the Specific ATO Data may have been affected.

7.13.2.13 **Note:** The conditions to detect that the validity of the Specific ATO Data may have been affected are supplier specific, e.g. the ETCS Train Data has changed from sources

<!-- end of page 50 -->

different from the driver and this change impacts the validity status of the Specific ATO Data.

7.13.2.14 When it receives the “Specific ATO Data Need” while in FS, AD, LS, SR, OS, UN, TR, PT and SN modes, the ETCS-OB shall inform the driver that the ATO-OB needs data.

7.13.2.15 The ETCS-OB shall delete this information to the driver when the driver initiates the Train Data entry procedure or when the ATO-OB is considered as failed.

7.13.2.16 The ATO-OB requests its Specific ATO Data with a “Specific ATO Data Entry request” which shall include for each Specific ATO Data, the following information: the label, optionally a default value, and optionally values for a dedicated keyboard.

7.13.2.17 **Note:** Unless values for a dedicated keyboard are provided or the type of keyboard is configured on-board, an alphanumeric keyboard will by default be used (see [Ref 11]).

7.13.2.18 It shall be possible to configure in the ETCS-OB the following parameters for each Specific ATO Data Identifier not using a dedicated keyboard:

   - a) The type of keyboard amongst numeric, enhanced numeric and alphanumeric;

   - b) If the type of keyboard is numeric or enhanced numeric, whether leading zeros have to be kept and sent to the ATO;

   - c) The allowed minimum and maximum value, that shall be used by the ETCS-OB with a technical range check.

7.13.2.19 By analogy to the modification/revalidation of ETCS Train data, the [Ref 5] requirements §3.14.1.7.3, §3.18.3.3.1 regarding the brake command/release when a movement is detected while modifying or revalidating the Train Data in normal operation after the start of mission shall also apply for the Specific ATO data modification/revalidation.

#### **7.13.2.20 Specific ATO Data Entry procedure**

7.13.2.21 As soon as the ETCS Train Data is validated by the driver, the ETCS-OB shall indicate to the ATO-OB the beginning of its Specific ATO Data Entry procedure by sending the START flag.

7.13.2.22 The ETCS Train Data shall be sent immediately after the START flag.

7.13.2.23 While a Specific ATO Data Entry is ongoing, the ETCS-OB shall indicate to the ATO-OB the end of its Specific ATO Data Entry procedure by sending the STOP flag when one of the following conditions is fulfilled:

   - a) After having received the “End of Specific ATO Data Entry” from the ATO-OB;

   - b) At expiration of the timeout specified in §7.13.2.30 for the ATO-OB;

   - c) When the Train Data Entry procedure is aborted by the ETCS-OB for reasons not related to the ATO-OB interface;

   - d) The Specific ATO Data Entry for the ATO-OB has been skipped by the driver, see §7.13.2.10.

<!-- end of page 51 -->

7.13.2.24 **Note:** Reasons leading to the abortion of the Train Data entry procedure and not related to the ATO-OB interface can be e.g. the cab deactivation, the driver aborting the Train Data entry procedure…

7.13.2.25 **Note:** ETCS Train Data is also sent without the START and STOP flags outside a Train Data entry procedure, see §10.1.8.1.

7.13.2.26 Once the ATO-OB has received the ETCS Train Data while its Specific ATO Data Entry is ongoing:

   - a) If the ATO-OB requires Specific ATO Data, the ATO-OB shall send a “Specific ATO Data Entry request” information to the ETCS-OB;

   - b) If the ATO-OB doesn’t require Specific ATO Data, the ATO-OB shall send an “End of Specific ATO Data Entry” information to the ETCS-OB.

7.13.2.27 When it receives the Specific ATO Data Entry request, the ETCS-OB shall perform the Specific ATO Data Entry/Validation exchanges with the driver.

7.13.2.28 Once the Specific ATO Data for an ATO-OB has been validated by the driver, the ETCSOB shall send the “Specific ATO Data” to this ATO-OB.

7.13.2.29 When the ATO-OB receives the Specific ATO Data, it checks the data according to its criteria. Depending on the check result:

   - a) The ATO-OB shall send an “End of Specific ATO Data Entry” if the checks are OK and the ATO-OB has all the requested data;

   - b) The ATO-OB shall send again Specific ATO Data Entry request.

7.13.2.30 The ETCS-OB shall supervise a timeout of 10 seconds (TrainDataEntry_ATO_Response_Timeout):

   - a) From sending the ETCS Train Data by the ETCS-OB while the Specific ATO Data Entry procedure is running until the reception of a Specific ATO Data Entry request or the “End of Specific ATO Data Entry” from the ATO-OB; and

   - b) From each sending Specific ATO Data by the ETCS-OB until the reception of a Specific ATO Data Entry request or the “End of Specific ATO Data Entry” from the ATO-OB.

7.13.2.31 If the “TrainDataEntry_ATO_Response_Timeout” is triggered, the ETCS-OB shall apply the same reaction as specified in the clause 10.2.2.8.

<!-- end of page 52 -->

#### **7.13.2.32 Sequence diagrams for the Specific ATO Data Entry**

<!-- Start of picture text -->
Driver ETCS-OB ATO-OB<br>ETCS Train Data validated<br>Start flag<br>ETCS Train Data<br>Specific ATO Data Entry Request<br>NTC/ATO data entry selection window<br>Button for ATO is enabled<br>ATO selected by the driver<br>Specific ATO Data is presented to the driver<br>Specific ATO Data is validated<br>Specific ATO Data values<br>End of Specific ATO Data Entry<br>NTC/ATO data entry selection window<br>Button for ATO is disabled<br>Stop flag<br><!-- End of picture text -->

**Figure 6 Specific ATO Data Entry performed**

<!-- end of page 53 -->

<!-- Start of picture text -->
Driver ETCS-OB ATO-OB<br>ETCS Train Data validated<br>Start flag<br>ETCS Train Data<br>Specific ATO Data Entry Request<br>NTC/ATO data entry selection window<br>Button for ATO is enabled<br>Driver presses «End of data entry»<br>Stop flag<br><!-- End of picture text -->

**Figure 7 Specific ATO Data Entry skipped**

<!-- Start of picture text -->
Driver ETCS-OB ATO-OB<br>ETCS Train Data validated<br>Start flag<br>ETCS Train Data<br>Specific ATO Data Entry Request<br>NTC/ATO data entry selection window<br>Button for ATO is enabled<br>Cab being closed<br>Stop flag<br><!-- End of picture text -->

**Figure 8 Specific ATO Data Entry aborted**

### **7.13.3 Specific ATO Data View**

7.13.3.1 This procedure shall allow the driver to view the Specific ATO Data View values currently known by the ATO-OB.

<!-- end of page 54 -->

7.13.3.2 When the Data View procedure is triggered, the ETCS-OB shall send to the ATO-OB a Request for Specific ATO Data View values.

7.13.3.3 Once the ATO-OB has received the ETCS Request for Specific ATO Data View values:

- a) If the ATO-OB has “Specific ATO Data View values” available, the ATO-OB shall send the corresponding “Specific ATO Data View values” (labels and corresponding values) to the ETCS-OB.

- b) If the ATO-OB has no “Specific ATO Data View values” available, the ATO-OB shall send a “No Specific ATO Data View values” to the ETCS-OB.

7.13.3.4 When it receives the “Specific ATO Data View values”, the ETCS-OB shall present them to the driver.

7.13.3.5 The ETCS-OB shall supervise a timeout of 10 seconds (TrainDataView_ATO_Response_Timeout) from sending the Request for Specific ATO Data View values until the reception of “Specific ATO Data View values” or the “No Specific ATO Data View values” information from the ATO-OB.

<!-- end of page 55 -->

7.13.3.6 If the “TrainDataView_ATO_Response_Timeout” is triggered, the ETCS-OB shall:

- a) Display the “ATO Failure” indication for a duration of 30 seconds;

- b) Produce a warning sound for a duration of 5 seconds;

- c) Send no packets to the ATO-OB for 30 seconds.

### **7.13.4 Limitations related to Specific ATO Data Entry/Data View**

7.13.4.1 The number of Data Identifiers within one “Specific ATO Data Entry request” shall be limited to 15 Data Identifiers.

7.13.4.2 The number of Data Identifiers within one “Specific ATO Data values” shall be limited to 15 Data Identifiers.

7.13.4.3 The number of Data Identifiers within one “Specific ATO Data View values” shall be limited to 15 Data Identifiers.

7.13.4.4 The maximum number of characters (coded in UTF-8 by 1 or 2 bytes) shall be:

- a) 20 characters for data labels in “Specific ATO Data Entry request” and “Specific ATO Data View values”;

- b) 10 characters for data values in “Specific ATO Data Entry request” and “Specific ATO Data values”;

- c) 10 characters for data view values in “Specific ATO Data View values”.

<!-- end of page 56 -->
