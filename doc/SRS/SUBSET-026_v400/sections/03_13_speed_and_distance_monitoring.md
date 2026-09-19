## **3.13 Speed and distance monitoring**

**3.13.1 Introduction**

3.13.1.1 The speed and distance monitoring is the supervision of the speed of the train versus its position, in order to assure that the train remains within the given speed and distance limits.

<!-- end of page 114 -->

3.13.1.1.1 Note: The speed and distance monitoring of the on-board can only assure this when the following necessary conditions are fulfilled:

   - Brake system of the train functions as specified

   - wheel/rail adhesion is sufficient for the required safe deceleration

   - Brake characteristics (and other Train related inputs) are correctly entered into the on-board

3.13.1.2 Note: The ERTMS/ETCS on-board equipment triggers brake commands and revokes them, it may also receive status information if the brakes are applied or released. However, it cannot be made responsible if brake control circuits outside the equipment fail. Also the way the brakes are released by the driver after a revocation of a brake command is an implementation issue.

3.13.1.3 Figure 28 gives an overview of the main elements contributing to the speed and distance monitoring. These elements (inputs, functions and outputs) are detailed in the following chapters.

<!-- Start of picture text -->
Train related Inputs<br>Braking model  Onboard correction factors:  Maximum train speed<br>OR<br>Brake percentage  Kdry_rst, Kwet_rst, Kn TCO interface<br>Special Brakes<br>Train length  • Electro-pneumatic brake<br>Service Brake  • Eddy current brake<br>Brake  Traction  • SB command implemented  Fixed Values  •• Magnetic shoe brake  Regenerative brake<br>• SB feedback implemented<br>position  model  • SB application (Brake pressure)  Nominal rotating mass<br>Brake  Speed & Distance<br>percentage  track conditions  Calculation of decelerations:  Determination of brake  Monitoring<br>deceleration curves:<br>Conversion  Kdry_rst / Kwet_rst / A_safe(v,d) for EBD curve  • EBD<br>Model  Kv_int / Kr_int / • SBD  Traction model<br>reduced adhesion • GUI  Fixed Values<br>Traction/Braking models  A_expected(v,d) for SBD curve  Supervision limits:<br>A_brake_emergency  MRSP  •• Emergency brake intervention (EBI)  Service brake intervention (SBI)<br>A_normal_service(v,d) for GUI curve  • Warning (W)  TI commands<br>A_brake_service  TRK speed  • Permitted speed (P)<br>Train position  restrictions /  • Indication (I)<br>acceleration/ speed /  A_brake_normal_service  A_gradient  speed /  Max train speed  • Release speed monitoring start location<br>Acceleration /  distance  Determination of<br>T_brake_service_react  limits<br>T_brake_service  Deceleration  the supervised  DMI<br>due to Gradient  targets  commands<br>T_brake_emergency_react  Speed and distance<br>T_brake_emergency  monitoring commands<br>• TI commands<br>Calculation of brake  Calculation of brake build up  • Emergency brake command<br>build up times:  reduced times per target:  • Service brake command<br>• TCO command<br>T_bs_react, T_bs for SBI limit  T_bs_reduced  • DMI commands: • Normal status<br>• Indication status<br>Kt_int   T_be_react, T_be  T_be_reduced  • Overspeed status<br>Electro-pneumatic brake for EBI limit  • Warning status<br>• Intervention status<br>National Values<br>Gradients  Speed and distance limits:  • Trackside integrated correction factors:<br>• LoA  Kv_int, Kr_int, Kt_int<br>Reduced Adhesion conditions  •• EoA / SvL  Location from SR distance  ••• Available adhesion  EB confidence level  SB command inhibition in TSM<br>• EB command revocation in CSM/TSM<br>Track conditions  Trackside Speed  • Guidance curve inhibition<br>powerless section &  Restrictions  • A_NVMAXREDADH under reduced adhesion<br>brake inhibition  • Service Brake feedback inhibition<br>• Release Speed<br>Trackside related Inputs<br><!-- End of picture text -->

**Figure 28: Speed and distance monitoring overview**

<!-- end of page 115 -->

3.13.1.4 Throughout the following sections, all the distances marked with “d” (lower case), which are referred in parameters, formulas and figures, are counted from the single reference location of the on-board equipment for the supervision of distances (i.e. the SOLR).

3.13.1.5 When the ERTMS/ETCS on-board equipment applies at least one of the clauses 3.12.2.4, 3.12.4.7 and 3.12.5.8, all the instances of the terms EOA and SvL in this section 3.13 shall refer to the closest location amongst the temporary EOA(s) and the EOA and to the closest location amongst the temporary SvL(s) and the SvL, respectively.

### **3.13.2 Inputs for speed and distance monitoring**

#### **3.13.2.1 Introduction**

3.13.2.1.1 The traction / braking models, the brake position / brake percentage are used for the definition of the kinematic behaviour of the train after a service brake command or an emergency brake command has been initiated.

3.13.2.1.2 However, railway brakes have a statistical behaviour and braking distances vary within the typical distribution for a given condition. Correction factors are therefore incorporated for the speed and distance monitoring.

3.13.2.1.3 The correction factors will allow obtaining, from the nominal emergency braking performance of the train, the minimum emergency braking performances that are required for reference conditions set by trackside.

**3.13.2.2 Train related inputs**

#### **3.13.2.2.1 Introduction**

3.13.2.2.1.1 The train related inputs to be considered for the speed and distance monitoring are:

   - a) Traction model

   - b) Braking models (brake reaction time, brake build up time and speed dependent deceleration) or brake percentage

   - c) Brake position

   - d) Special brakes (interface configuration and status)

   - e) Service brake (interface configuration and application)

   - f) Traction cut-off interface

   - g) On-board correction factors

   - h) Nominal rotating mass

   - i) Train length

   - j) Fixed values related to speed and distance monitoring

   - k)  Train related speed restriction (i.e. the maximum train speed)

<!-- end of page 116 -->

3.13.2.2.1.2 These train related inputs are acquired as Train Data (see 3.18.3.2 items b) c) and d)), except:

   - the configuration of the special brakes, service brake and traction cut-off interfaces which are not affected by the Train Data acquisition,

   - the service brake application and the special brakes statuses which are continuously acquired on the Train Interface,

   - the fixed values.

3.13.2.2.1.3 The speed and distance monitoring shall use braking models acquired as Train Data, unless the brake percentage is acquired as Train Data and the conversion model is applicable (see 3.13.3.2 for its validity limits).

#### **3.13.2.2.2 Traction model**

3.13.2.2.2.1 The traction model shall be given as a step function as indicated in Figure 29. Depending on whether the traction cut-off command is implemented or not (see 3.13.2.2.8.1), it shall describe the nominal traction cut-off time (T_traction_cut_off) counted from the moment when either the traction cut-off command or the emergency brake command is respectively triggered by the on-board (t0) to the moment the acceleration due to traction (A_traction) is zero (t1). The estimated acceleration value of the train shall be considered during this time.

<!-- Start of picture text -->
A_traction<br>Estimated<br>acceleration<br>t0  t1  time<br><!-- End of picture text -->

**Figure 29: Traction Model**

3.13.2.2.2.2 Note: The current value of A_traction is not known directly by the on-board. It is implicitly known as a contribution to the estimated acceleration, together with the acceleration due to gradient.

#### **3.13.2.2.3 Braking Models**

#### **3.13.2.2.3.1 Speed Dependent Deceleration**

3.13.2.2.3.1.1 The deceleration due to braking shall be given as a step function of the speed.

3.13.2.2.3.1.2 It shall be possible to define up to seven steps for each speed dependent deceleration model.

3.13.2.2.3.1.3 Note: An example with 4 steps is given in Figure 30. A_brake(V) is calculated as follows:

<!-- end of page 117 -->

- A_brake = AD_0  when 0 ≤ speed ≤ V1

- A_brake = AD_1  when V1 < speed ≤ V2

- A_brake = AD_2  when V2 < speed ≤ V3

- A_brake = AD_3  when V3 < speed

<!-- Start of picture text -->
A_brake<br>AD_1<br>AD_0<br>AD_2<br>AD_3<br>0  V1  V2  V3  speed<br><!-- End of picture text -->

**Figure 30: Speed Dependent Deceleration Model**

3.13.2.2.3.1.4 The last step of A_brake(V) shall by definition be considered as open ended, i.e. it has no upper speed limit.

3.13.2.2.3.1.5 The model shall be applicable only after full build up of the braking effort (see a_full in Figure 31)

3.13.2.2.3.1.6 The model shall be used for the emergency brake nominal deceleration (A_brake_emergency(V)), for the full service brake deceleration (A_brake_service(V)) and for the normal service brake deceleration (A_brake_normal_service(V)).

3.13.2.2.3.1.7 It shall be possible to define individual speed dependent deceleration models of A_brake_emergency(V) and A_brake_service(V) for each combination of use of regenerative brake, eddy current brake and magnetic shoe brake.

3.13.2.2.3.1.8 Note: Individual deceleration models may be equal, thereby avoiding the influence of a specific brake on A_brake_emergency(V) or A_brake_service(V). However, the choice to take into account or not the contribution of a specific brake for A_brake_emergency(V) or A_brake_service(V) is only rolling stock dependent, not an ETCS implementation issue.

3.13.2.2.3.1.9 It shall be possible to define up to two sets of three models of A_brake_normal_service(V):

   - a) one set applicable when the brake position is in “Freight train in G”

   - b) one set applicable when the brake position is in “Passenger train in P” or “Freight train in P”

<!-- end of page 118 -->

3.13.2.2.3.1.10 A set of A_brake_normal_service(V) shall be defined as a function of the full service brake deceleration at zero speed, A_brake_service(V=0):

If A_brake_service(V = 0)  A_SB01

A_brake_normal_service(V) = A_brake_normal_service_0(V)

if A_SB01 < A_brake_service(V = 0)  A_SB12

- A_brake_normal_service(V) = A_brake_normal_service_1(V)

if A_SB12 < A_brake_service (V = 0)

A_brake_normal_service(V) = A_brake_normal_service_2(V)

3.13.2.2.3.1.11 Note: the two pivot values A_SB01 and A_SB12 are part of the A_brake_normal_service model, i.e. they are train related input data for the speed and distance monitoring function.

#### **3.13.2.2.3.2 Brake reaction time and brake build up time**

3.13.2.2.3.2.1 The deceleration A_brake is not available immediately after the on-board commands the brake. There is a time lag between brake command and the start of the brake force build-up. There is also time needed to build up the full brake force.

3.13.2.2.3.2.2 The models for the brake build up time shall be given both as a ramp function and as a step function as explained in Figure 31.

<!-- Start of picture text -->
A_brake<br>a_full<br>95%<br>possible<br>real shape<br>ramp<br>step<br>t0  t1  t3  t2  time<br><!-- End of picture text -->

**Figure 31: Brake Build Up Time Models**

3.13.2.2.3.2.3 In Figure 31, the following time intervals are defined:

   - a) T_brake_react (t0…t1) is the interval between the command of the brake by the onboard and the moment the brake force starts to build up.

   - b) T_brake_increase (t1...t2) is the interval in which the brake force increases from the zero to the moment when 95% of full brake effort is reached.

   - c) T_brake_build_up (t0...t3) is the equivalent brake build up time.

<!-- end of page 119 -->

3.13.2.2.3.2.4 The equivalent brake build up time (T_brake_build_up) is defined as T_brake_build_up = T_brake_react + 0.5*T_brake_increase.

3.13.2.2.3.2.5 This model for T_brake_build_up shall be used for the emergency brake (T_brake_emergency) and for the full service brake (T_brake_service).

3.13.2.2.3.2.6 Note: The equivalent brake build up time is a safe approximation. In the beginning of the build-up time the ramp and step models assume a deceleration smaller than the real shape, in the later part this is compensated by a higher deceleration. The approximation done with the 95% factor is compensated by the margin between the models and the real shape existing in the beginning of the build-up time.

3.13.2.2.3.2.7 Intentionally deleted.

3.13.2.2.3.2.8 It shall be possible to define individual values of T_brake_emergency_react, T_brake_emergency, T_brake_service_react and T_brake_service for each combination of use of regenerative brake, eddy current brake, magnetic shoe brake and Ep brake.

3.13.2.2.3.2.9 Note: Individual values of T_brake_emergency and T_brake_service may be equal, thereby avoiding the influence of a specific brake. However, the choice to take into account or not the contribution of a specific brake for T_brake_emergency and T_brake_service is only rolling stock dependent, not an ETCS implementation issue.

3.13.2.2.3.2.10 Note: In general, T_brake_emergency and T_brake_service are determined by the pneumatic brake therefore avoiding to take into account of the influence of the regenerative brake, eddy current brake or magnetic shoe brake. However, if the Electropneumatic brake system is used, it is possible that T_brake_emergency and T_brake_service are determined by another special brake.

#### **3.13.2.2.4 Brake Position**

3.13.2.2.4.1 The brake position shall be set to one of the following three values:

   - a) Passenger train in P

   - b) Freight train in P

   - c) Freight train in G

3.13.2.2.4.2 Note: The brake position defines the behaviour of the brake for specific train types.

#### **3.13.2.2.5 Brake Percentage**

3.13.2.2.5.1 If the brake percentage is captured as Train Data and the conversion model is applicable (see 3.13.3.2), they are used to derive A_brake_emergency(V), A_brake_service(V), T_brake_emergency and T_brake_service.

<!-- end of page 120 -->

3.13.2.2.5.2 Note: the conversion model has been designed assuming that all the provisions laid down in the EN 16834 : 2019, with the exception of sections 9.3.1, 9.4.1 and 9.5.2, apply for the acquired brake percentage.

<!-- end of page 121 -->

#### **3.13.2.2.6 Special Brakes**

3.13.2.2.6.1 For each special brake (regenerative brake, eddy current brake, magnetic shoe brake and electro-pneumatic brake), the on-board shall be configured to define one of the following possibilities marked with an “X” in Table 3

||||_configuratio_|_n possibilities_||
|---|---|---|---|---|---|
|||_No interface_<br>_exists_|_Interface_<br>_exists and_<br>_status affects_<br>_the_<br>_emergency_<br>_brake model_<br>_only_|_Interface_<br>_exists and_<br>_status affects_<br>_the service_<br>_brake model_<br>_only_|_Interface_<br>_exists and_<br>_status affects_<br>_both_<br>_emergency_<br>_and service_<br>_brake models_|
|e|regenerative brake|x|x|x|x|
|brak|eddy current brake|x|x|x|x|
|pecial|magnetic shoe<br>brake|x|x|||
|S|Ep brake|x||x|x|

**Table 3: On-board Configuration in relation to special brakes**

3.13.2.2.6.2 When an interface exists with the regenerative brake, eddy current brake, magnetic shoe brake system and/or the Ep brake on-board system and depending whether their status affects the concerned brake parameter(s), the speed and distance monitoring shall take into account their status “active” or “not active” to select the appropriate brake parameter(s) captured as Train Data, according to Table 4:

|||_When interf_<br>_parameter, s_|_ace exists an_<br>_election of b_<br>_sta_|_d if status affect_<br>_rake parameter_<br>_tus of:_|_s the brake_<br>_according to_|
|---|---|---|---|---|---|
|||regenerative<br>brake|eddy<br>current<br>brake|magnetic<br>shoe brake|Ep brake|
|r|A_brake_emergency(V)|x|x|x||
|aramete|T_brake_emergency_react<br>T_brake_emergency|x|x|x|x|
|ke p|A_brake_service(V)|x|x|||
|Bra|T_brake_service_react<br>T_brake_service|x|x||x|

**Table 4: Selection of brake parameters according to status of special brakes**

<!-- end of page 122 -->

3.13.2.2.6.3 When the brake percentage is captured as Train Data and the conversion model is applicable, A_brake_emergency(V), T_brake_emergency and A_brake_service(V) shall not be influenced by the status of a special brake. However, the conversion model offers the possibility that T_brake_service can be affected by the status of the regenerative brake, eddy current brake or Ep brake (see A.3.9).

3.13.2.2.6.4 The on-board equipment shall be configured to define whether it is allowed to take into account the contribution of a special/additional brake, which is independent from wheel/rail adhesion, for the selection of the maximum emergency brake deceleration under reduced adhesion conditions (see 3.13.6.2.1.6).

3.13.2.2.6.5 Note: the choice to set to “allowed” the contribution of such special/additional brake in the selection of the maximum emergency braking effort, is rolling stock dependent.

3.13.2.2.6.6 If it is allowed to take into account the contribution of a special/additional brake, which is independent from wheel/rail adhesion, the speed and distance monitoring function shall take into account the status “active” or “not active” of the special/additional brake to select the appropriate National Value under reduced adhesion conditions (see 3.13.2.3.7.7).

#### **3.13.2.2.7 Service brake**

3.13.2.2.7.1 The on-board shall be configured to define whether the service brake command is implemented or not, i.e. whether a service brake interface is implemented to command a full service brake effort.

3.13.2.2.7.2 The on-board shall be configured to define whether the service brake feedback is implemented or not, i.e. whether it is able to acquire from the service brake interface the information that the service brake is currently applied.

3.13.2.2.7.3 If the service brake feedback is implemented and if not inhibited by National Value, the speed and distance monitoring function shall take into account either the main brake pipe pressure or the brake cylinder pressure to adjust in real time the expected brake build up time (see 3.13.9.3.3.4 and Appendix A.3.10).

#### **3.13.2.2.8 Traction cut-off interface**

3.13.2.2.8.1 The on-board shall be configured to define whether the traction cut-off command is implemented, i.e. whether the interface to the traction system is implemented or not.

#### **3.13.2.2.9 On-board Correction Factors**

#### **3.13.2.2.9.1 Correction factors for the emergency deceleration**

3.13.2.2.9.1.1 If the braking models are captured as Train Data, rolling stock correction factors shall be defined in the ETCS on-board equipment. If the brake percentage is captured as Train Data and the conversion model is used (see 3.13.3.2 for its validity limits), no rolling stock correction factor shall apply.

<!-- end of page 123 -->

3.13.2.2.9.1.2 For each defined individual speed dependent deceleration model of A_brake_emergency(V) (i.e. corresponding to each combination of use of regenerative brake, eddy current brake and magnetic shoe brake), one set of rolling stock correction factors Kdry_rst(V, EBCL) and Kwet_rst(V) shall be defined in the on-board equipment.

3.13.2.2.9.1.3 For a given confidence level on emergency brake safe deceleration (EBCL), the rolling stock correction factor Kdry_rst(V) shall be given as a step function of speed, with the same steps as the ones of A_brake_emergency(V).

3.13.2.2.9.1.4 The confidence level on emergency brake safe deceleration represents the probability of the following individual event: the rolling stock emergency brake subsystem of the train does ensure a deceleration at least equal to A_brake_emergency(V) * Kdry_rst(V), when the emergency brake is commanded on dry rails.

3.13.2.2.9.1.5 The rolling stock correction factor Kwet_rst(V) shall be given as a step function of speed, with the same steps as the ones of A_brake_emergency(V). It represents the loss of deceleration with regards to emergency braking on dry rails, when the emergency brake is commanded on wet rails, according to wheel/rail adhesion reference conditions.

**3.13.2.2.9.2 Correction factor for gradient on normal service deceleration**

3.13.2.2.9.2.1 The speed dependent correction factors for gradient on the normal service brake, Kn+(V) and Kn-(V), shall be given as step functions in the range from 0 to 10 m/s2.

3.13.2.2.9.2.2 It shall be possible to define up to five steps for Kn+(V) and for Kn-(V), respectively.

3.13.2.2.9.2.3 Note: An example with 4 steps is given in Figure 32. Kn is calculated as follows:

   - Kn = Kn_0 when 0 ≤ speed ≤ V1

   - Kn = Kn_1 when V1 < speed ≤ V2

   - Kn = Kn_2 when V2 < speed ≤ V3

   - Kn = Kn_3 when V3 < speed

<!-- Start of picture text -->
Kn<br>Kn_1<br>Kn_0<br>Kn_2<br>Kn_3<br>V1  V2  V3  speed<br><!-- End of picture text -->

#### **Figure 32  Speed dependent correction factor for normal service brake (Kn)**

3.13.2.2.9.2.4 Kn+(V) shall be applicable for positive gradients.

<!-- end of page 124 -->

3.13.2.2.9.2.5 Kn-(V) shall be applicable for negative gradients.

3.13.2.2.9.2.6 The last step of the Kn+(V) or Kn-(V) shall by definition be considered as open ended, i.e. it has no upper speed limit.

#### **3.13.2.2.10 Nominal Rotating mass**

3.13.2.2.10.1 It shall be possible to define the nominal rotating mass to be used for compensating the gradient, instead of the two related fixed values defined in A.3.1.

#### **3.13.2.2.11 Train length**

3.13.2.2.11.1 The speed and distance monitoring shall take into account the train length acquired as part of Train Data (see section 3.18.3).

#### **3.13.2.2.12 Fixed values**

3.13.2.2.12.1 The speed and distance monitoring shall take into account the fixed values defined in A.3.1 that are related to speed and distance monitoring.

#### **3.13.2.2.13 Maximum train speed**

3.13.2.2.13.1 The speed and distance monitoring shall take into account the maximum train speed defined as part of Train Data (see section 3.18.3).

#### **3.13.2.3 Trackside related inputs**

#### **3.13.2.3.1 Introduction**

3.13.2.3.1.1 The trackside related inputs to be considered for the speed and distance monitoring are:

   - a) Trackside related speed restrictions

   - b) Gradients

   - c) Track conditions related to brake inhibition

   - d) Track conditions related to powerless section

   - e) Reduced adhesion conditions

   - f) Specific speed and distance limits (e.g. EOA/SvL)

   - g) National Values

#### **3.13.2.3.2 Trackside related speed restrictions**

3.13.2.3.2.1 The speed and distance monitoring shall take into account the trackside related speed restrictions composed of all speed restrictions mentioned in 3.11.2 except the maximum train speed.

<!-- end of page 125 -->

#### **3.13.2.3.3 Gradients**

3.13.2.3.3.1 The speed and distance monitoring shall take into account the gradient profile and the default gradient for TSR (see section 3.11.12).

#### **3.13.2.3.4 Track conditions**

3.13.2.3.4.1 The speed and distance monitoring shall take into account the following types of track condition received from trackside (see section 3.12.1): powerless section, inhibition of regenerative brake, eddy current brake and magnetic shoe brake.

#### **3.13.2.3.5 Reduced adhesion conditions**

3.13.2.3.5.1 The speed and distance monitoring shall take into account the track reduced adhesion received from trackside or selected by the driver (see section 3.18.4.6).

#### **3.13.2.3.6 Specific speed / distance limits**

3.13.2.3.6.1 The speed and distance monitoring shall take into account the following limits:

   - a) the Limit of Authority (LOA), the End of Authority (EOA), the Supervised Location (SvL) and its associated release speed, if any.

   - b) the maximum permitted distance to run in Staff Responsible

#### **3.13.2.3.7 National Values for speed and distance monitoring**

3.13.2.3.7.1 It shall be possible by means of a National Value to inhibit the use of the service brake command in target speed monitoring.

3.13.2.3.7.2 It shall be possible to state by means of a National Value whether an emergency brake command has to be revoked, both in ceiling speed and target speed monitoring, when:

   - a) the Permitted Speed supervision limit is no longer exceeded, or

   - b) the train is at standstill.

3.13.2.3.7.3 It shall be possible by means of a National Value to inhibit the guidance curve (GUI).

3.13.2.3.7.4 It shall be possible by means of a National Value to inhibit the service brake feedback function.

3.13.2.3.7.5 It shall be possible by means of National Values to indicate to the on-board equipment the required confidence level on the emergency brake safe deceleration, when the emergency brake is commanded on dry rails (see 3.13.2.2.9.1.4).

3.13.2.3.7.6 It shall be possible by means of a National Value to indicate to the on-board equipment the available wheel/rail adhesion, weighted between the wheel/rail adhesion for dry rails and the wheel/rail adhesion for wet rails according to reference conditions.

3.13.2.3.7.7 In order to adapt to the train behaviour under reduced adhesion conditions, it shall be possible by means of National Values either to limit to a maximum value the speed

<!-- end of page 126 -->

dependent deceleration for the emergency brake when the reduced adhesion conditions are known to ETCS (see 3.13.2.3.5) or to request supplementary DMI information assisting further the driver in ceiling speed monitoring. Three values shall be applicable for a given combination of the brake position and of the type of brakes:

   - a) the first value shall be used for “Passenger train in P” with special/additional brakes independent from wheel/rail adhesion;

   - b) the second value shall be used for “Passenger train in P” without special/additional brakes independent from wheel/rail adhesion;

   - c) the third value shall be used for “Freight train in P” or “Freight train in G”.

3.13.2.3.7.8 It shall be possible by means of a National Value to specify a release speed.

3.13.2.3.7.9 It shall be possible by means of a National Value to inhibit the compensation of the speed measurement inaccuracy.

3.13.2.3.7.10 It shall be possible by means of National Values to define integrated correction factors, namely Kv_int(V), Kr_int(l) and Kt_int. The integrated correction factors only apply to the on-board equipment when the conversion model is used.

3.13.2.3.7.11 The speed dependent correction factor, Kv_int(V), shall be given as a step function.

3.13.2.3.7.11.1 It shall be possible to define up to five steps for Kv_int(V).

3.13.2.3.7.11.2 Note: An example with 4 steps is given in Figure 33. Kv_int is calculated as follows:

   - Kv_int = Kv_int_0 when 0 ≤ speed ≤ V1

   - Kv_int = Kv_int_1 when V1 < speed ≤ V2

   - Kv_int = Kv_int_2 when V2 < speed ≤ V3

   - Kv_int = Kv_int_3 when V3 < speed

<!-- Start of picture text -->
Kv_int<br>Kv_int_1<br>Kv_int_0<br>Kv_int_2<br>Kv_int_3<br>V1  V2  V3  speed<br><!-- End of picture text -->

**Figure 33  Speed dependent correction factor Kv_int**

3.13.2.3.7.11.3 It shall be possible to define up to 2 sets of Kv_int with separate speed limits V1, V2, .. for each set. The sets of Kv_int relate to the following train types:

<!-- end of page 127 -->

      - 1) Freight trains

      - 2) Conventional passenger trains

3.13.2.3.7.11.3.1 Note: Different sets of Kv_int are needed for different types of trains in order to compensate the absence of the rolling stock related correction factors when the conversion model is used.

3.13.2.3.7.11.4 The set of Kv_int for conventional passenger trains shall be divided into two sub sets Kv_int_x_a and Kv_int_x_b, with identical speed limits V1, V2, ....

3.13.2.3.7.11.5 Subset Kv_int_x_a shall be applicable for maximum emergency brake deceleration lower or equal to a deceleration limit, defined as a National Value.

3.13.2.3.7.11.6 Subset Kv_int_x_b shall be applicable for maximum emergency brake deceleration greater or equal to a deceleration limit, defined as a National Value.

3.13.2.3.7.12 The train length dependent correction factor, Kr_int(l), shall be given as a step function.

3.13.2.3.7.12.1 It shall be possible to define up to five steps for Kr_int(l).

3.13.2.3.7.12.2 Note: An example with 4 steps is given in Figure 34. Kr_int is calculated as follows:

   - Kr_int = Kr_int_0 when 0 ≤ train length ≤ L1

   - Kr_int = Kr_int_1 when L1 < train length ≤ L2

   - Kr_int = Kr_int_2 when L2 < train length ≤ L3

   - Kr_int = Kr_int_3 when L3 < train length

<!-- Start of picture text -->
Kr_int<br>Kr_int_1<br>Kr_int_0<br>Kr_int_2<br>Kr_int_3<br>L1  L2  L3  train length<br><!-- End of picture text -->

#### **Figure 34  Train length dependent correction factor Kr_int**

3.13.2.3.7.13 The last step of the Kv_int(V) and Kr_int(l) shall by definition be considered as open ended, i.e. it has no upper speed and train length limit, respectively.

3.13.2.3.7.14 The correction factor for brake build up time (Kt_int) shall be a single parameter.

<!-- end of page 128 -->

### **3.13.3 Conversion Models**

#### **3.13.3.1 Introduction**

3.13.3.1.1 For trains with variable composition (loco hauled trains), the brake characteristics can vary together with the composition of the train. In this case, it is not convenient to preprogram the brake parameters necessary to calculate the braking curves. The only practical way to obtain the correct values for the current train composition is to include them into the data entry process by the driver. However, it cannot be expected from the driver to know deceleration values and brake build up times. Conversion models are therefore defined to convert the parameters entered by the driver (brake percentage and brake position) into the parameters of the corresponding brake model.

3.13.3.1.2 Note: The process for defining the input parameters for the conversion model (brake percentage and brake position) is outside the scope of the ERTMS/ETCS specifications.

**3.13.3.2 Applicability of the conversion models**

3.13.3.2.1 The conversion models shall be used by the on-board equipment if the brake percentage is acquired as part of Train Data, and if the maximum train speed, the brake percentage and the train length are all within the following validity limits of the conversion models:

   - a) 0 ≤ V ≤ 200, where V is the maximum train speed in km/h

   - b) 30 ≤ λ ≤ 250, where λ is the brake percentage in %

   - c) 0 ≤ L ≤ Lmax, where L is the train length in m and where Lmax = 900 m if the brake position is “Passenger train in P” or Lmax = 1500 m if the brake position is “Freight train in P” or “Freight train in G”

3.13.3.2.1.1 Note: The overspeed above the maximum train speed which may occur due to the ceiling speed margins is taken into account in the definition of the conversion model.

3.13.3.2.2 For trains not fitting into at least one of those validity limits, it is still possible to acquire the brake percentage as Train Data, but the conversion models are not applicable, which means that braking models (i.e. pre-programmed deceleration profiles and brake build up times) shall be used by the speed and distance monitoring function.

**3.13.3.3 Brake percentage conversion model**

**3.13.3.3.1 Input parameters**

3.13.3.3.1.1 The input for the model shall be the brake percentage of the train as defined in 3.13.2.2.5.

**3.13.3.3.2 Calculation of the basic deceleration**

3.13.3.3.2.1 The basic deceleration A_basic(V) shall be given as a step function of the speed using the algorithm defined in Appendix A.3.7.

<!-- end of page 129 -->

#### **3.13.3.3.3 Output parameters**

3.13.3.3.3.1 The output of the brake percentage conversion model shall consist of two speed dependent deceleration brake models, A_brake_emergency(V) for the emergency brake and A_brake_service(V) for the service brake.

#### **3.13.3.4 Brake position conversion model**

#### **3.13.3.4.1 Input parameters**

3.13.3.4.1.1 The input for the model shall consist of the brake position of the train as defined in 3.13.2.2.4, the train length and the target speed.

#### **3.13.3.4.2 Calculation of the emergency brake reaction time and equivalent build up time**

3.13.3.4.2.1 The brake reaction time and equivalent brake build up time for the emergency brake shall be determined as specified in Appendix A.3.8.

#### **3.13.3.4.3 Calculation of the full service brake reaction time and equivalent build up time**

3.13.3.4.3.1 The brake reaction time and equivalent brake build up time for the full service brake shall be determined as specified in Appendix A.3.9.

#### **3.13.3.4.4 Output parameters**

3.13.3.4.4.1 The outputs of the brake position conversion model shall consist of:

   - a) two values of the equivalent brake build up time to be used when the target speed (V_target) is equal to zero, one value for the emergency brake and one for the full service brake:

T_brake_emergency_cm0 as defined for emergency brake in A.3.8

T_brake_service_cm0 as defined for service brake in A.3.9

- b) two values of the equivalent brake build up time to be used when the target speed (V_target) is different from zero, one value for the emergency brake and one for the full service brake:

T_brake_emergency_cmt as defined for emergency brake in A.3.8

   - T_brake_service_cmt as defined for service brake in A.3.9

- c) two values of the brake reaction time, one value for the emergency brake and one for the full service brake:

T_brake_emergency_react value as defined for emergency brake in A.3.8

- T_brake_service_react value as defined for service brake in A.3.9

### **3.13.4 Acceleration / Deceleration due to gradient**

#### **3.13.4.1 Introduction**

3.13.4.1.1 The elements of the gradient profile given from trackside shall be compensated:

   - a) in location according to the train length as defined in 3.13.4.2

<!-- end of page 130 -->

- b) in value according to the rotating mass as defined in 3.13.4.3 in order to derive the corresponding acceleration/deceleration.

<!-- Start of picture text -->
Black: defined by trackside<br>Blue: defined by onboard<br>Change of line<br>elevation (simplified)<br>SvL<br>EOA<br>Trackside Gradient<br>profile  G6=+1.2%<br>positive  G3=  G4=   G5=+0.7%<br>G1=0%  G2= -0.9%  -1.8%  -0.8%  G7=0%<br>negative<br>Train  G2<br>The  worst case gradient  Train  G3<br>under the train when it<br>approaches the SvL.<br>Train  G4<br>Train  G5<br>The gradients compensated<br>with the train length and the<br>accelaration in m/s/s deduced  Train  G7<br>with M_rotating_min &<br>M_rotating_max<br>G1  G2  G3  G4  G5  G7<br>AG1=0  AG2= -0.0865  AG3= -0.1729  AG4=  AG5=  AG7=0<br>-0.0769  +0.05965<br><!-- End of picture text -->

#### **Figure 35: Compensation on the gradient profile**

3.13.4.1.2 The default gradient for TSR shall be compensated in value according to the rotating mass as defined in 3.13.4.3.

3.13.4.1.3 For all locations not covered by the gradient profile, the on-board shall consider the gradient value as:

   - a) the default gradient for TSR, if available and if the concerned target is due to a TSR

   - b) zero, for other cases.

#### **3.13.4.2 Train length compensation**

3.13.4.2.1 Assuming that a fictive train front end would be at any location between the current (actual) train front end location and the SvL, the acceleration due to the gradient shall be determined using the lowest (taking the sign into account) gradient value given by the

<!-- end of page 131 -->

gradient profile between the location of the fictive train front end and the location of the fictive train rear end (see Figure 35).

#### **3.13.4.3 Rotating mass**

3.13.4.3.1 The influence of gradients shall be compensated for the rotating mass of the train (see Figure 35).

3.13.4.3.1.1 Note: Since the rotating mass works like a flywheel (rotating inertia), the effect of the gradient is reduced. Assume for instance a (theoretical) train without any rotating mass, not braking, on a downhill gradient from height 1 to height 2. All the energy added to the train when it goes from H1 to H2 is converted into linear forward motion. This can be observed as an acceleration due to the gradient. Now assume the same train with part of the weight rotating. If this train travels the same distance from H1 to H2, the same amount of energy is added to the train. But now a part of that energy is converted into rotational motion and only the remaining part is converted into linear forward motion. The latter can be observed as an acceleration which is less than for the train without rotating mass.

3.13.4.3.1.2 Note: For the influence of the rotating mass on the deceleration due to the brake, it is already taken into account in the values for the brake parameters.

3.13.4.3.2 The following formulas shall be used:

a) If M_rotating_nom is unknown:

- Uphill: A_gradient = g * grad / (1000+10*M_rotating_max)

- Downhill: A_gradient = g * grad / (1000+10*M_rotating_min)

- b) If M_rotating_nom is known:

- Uphill: A_gradient = g * grad / (1000+10*M_rotating_nom)

- Downhill: A_gradient = g * grad / (1000+10*M_rotating_nom)

- Legend:

A_gradient = acceleration/deceleration due to gradient (downhill acceleration is given with a negative value)

g = 9.81 m/s<sup>2</sup> - acceleration of gravity in m/s<sup>2</sup>

grad = gradient values in ‰ (positive = uphill)

M_rotating_nom = nominal rotating mass (part of train data) as a percentage of the total train weight

M_rotating_max = maximum possible rotating mass (see A.3.1) as a percentage of the total train weight

M_rotating_min = minimum possible rotating mass (see A.3.1) as a percentage of the total train weight

<!-- end of page 132 -->

### **3.13.5 Determination of locations without special brake contribution and with reduced adhesion conditions**

3.13.5.1 As long as it uses a track condition profile given by trackside, the on-board shall consider locations without special brake contribution over a distance going from the start location of the profile to the foot of the deceleration curve (EBD, SBD or GUI, see sections 3.13.8.3, 3.13.8.4 and 3.13.8.5).

3.13.5.2 If the status of a special brake is “not active”, all locations shall be considered without the contribution of this special brake.

3.13.5.2.1 Note: in such case, a track condition profile implying the inhibition of this special brake will have no effect.

3.13.5.3 From the adhesion profile given by trackside, the on-board shall consider locations with reduced adhesion conditions over a distance going from the start location of the profile to the location derived by adding the train length to the end location of the profile.

3.13.5.4 When slippery rail is selected by the driver, all locations shall be considered with reduced adhesion conditions.

3.13.5.5 The speed and distance monitoring shall use, as resulting reduced adhesion conditions, the most restrictive value of the adhesion conditions selected by the driver and the adhesion conditions calculated from the trackside profile.

### **3.13.6 Calculation of the deceleration and brake build up time**

**3.13.6.1 Introduction**

3.13.6.1.1 This chapter describes how the safe emergency brake, the expected and the normal service brake decelerations and the time intervals due to brake build up time are calculated.

**3.13.6.2 Emergency brake**

#### **3.13.6.2.1 Safe deceleration**

3.13.6.2.1.1 The safe deceleration, A_safe(V,d), is safety relevant. This means that for the calculation of the safe deceleration, all necessary track and train characteristics shall be taken into account.

3.13.6.2.1.2 The train and track related characteristics to be considered are:

   - a) The speed dependent deceleration model(s) for the emergency brake either acquired as part of Train Data (see 3.13.2.2.3.1) or derived from the brake percentage using the conversion model (see 3.13.3.3)

   - b) The acceleration/deceleration due to gradient i.e. A_gradient(d) (see c))

   - c) The locations with reduced adhesion conditions (see 3.13.5)

   - d) The National Values for reduced adhesion condition (see 3.13.2.3.7.7)

<!-- end of page 133 -->

   - e) The locations without special brake contribution (see 3.13.5), only if the speed dependent deceleration model(s) for the emergency brake are acquired as part of Train Data

   - f) The rolling stock correction factors Kdry_rst(V, EBCL) and Kwet_rst(V) (see 3.13.2.2.9.1), only if the speed dependent deceleration model(s) for the emergency brake are acquired as part of Train Data

   - g) The National Values for confidence level on emergency brake safe deceleration and for the available wheel/rail adhesion (see 3.13.2.3.7.5 & 3.13.2.3.7.6), only if the speed dependent deceleration model(s) for the emergency brake are acquired as part of Train Data

   - h) The integrated correction factors Kv_int(V) (with the two pivot deceleration values for passenger trains) and Kr_int(l) (see 3.13.2.3.7), only if the conversion model is used

   - i) The brake position (see 3.13.2.2.4)

   - j) The acquired train length L_TRAIN (see 3.13.2.2.11), only if the conversion model is used

3.13.6.2.1.3 A_safe(V,d) shall be equal to:

For locations with normal adhesion conditions and for locations with reduced adhesion conditions when A_MAXREDADH does not limit to a maximum value the speed dependent deceleration for the emergency brake:

A_safe(V,d) = A_brake_safe(V,d) + A_gradient(d)

For locations with reduced adhesion conditions when A_MAXREDADH limits to a maximum value the speed dependent deceleration for the emergency brake:

A_safe(V,d) = MIN(A_brake_safe(V,d) , A_MAXREDADH) + A_gradient(d)

3.13.6.2.1.4 A_brake_safe(V,d) shall be the safe emergency brake deceleration. A_brake_safe(V,d) shall be equal to:

If the speed dependent deceleration model(s) for the emergency brake are acquired as part of Train Data:

A_brake_safe(V,d) = Kdry_rst(V, M_NVEBCL) * (Kwet_rst(V) + M_NVAVADH *(1- Kwet_rst(V))) * A_brake_emergency(V,d)

If the conversion model is used:

A_brake_safe(V) = Kv_int(V) * Kr_int(L_TRAIN) * A_brake_emergency(V)

3.13.6.2.1.5 A_brake_emergency(V,d) shall be the emergency brake deceleration as a function of the speed, of the locations with change of special brake(s) contribution encountered between the train front and the foot of the EBD curve. A_brake_emergency(V,d) shall be equal to:

A_brake_emergency1(V) when destfront ≤ d ≤ d1

A_brake_emergency2(V) when d1 < d ≤ d2

A_brake_emergency3(V) when d2 < d ≤ d3

<!-- end of page 134 -->

#### Where

d1, d2, d3,... are the locations with change of special brake(s) contribution

A_brake_emergencyx(V) is equal to the emergency brake model, A_brake_emergency, applicable for the concerned combination of brake.

<!-- Start of picture text -->
A_brake_emergency<br>regenerative brake off<br>Pneumatic brake<br>plus regenerative brake<br>Pneumatic<br>brake only<br>d1 EBD foot  distance<br><!-- End of picture text -->

**Figure 36: Influence of track conditions on A_brake_emergency(V,d)**

3.13.6.2.1.6 A_MAXREDADH shall be the value, out of the three related National Values, applicable for this train according to:

   - a) its brake position

   - b) whether special/additional brakes independent from wheel/rail adhesion are active and it is allowed to take into account their contribution to the emergency braking effort.

3.13.6.2.1.7 Kdry_rst(V, M_NVEBCL) shall be the rolling stock correction factor, as a function of speed (with speed steps identical with the ones of A_brake_emergency(V)), corresponding to the confidence level on emergency brake safe deceleration required by trackside (National Value).

3.13.6.2.1.8 Kv_int(V) shall be the integrated correction factor applicable for the train, selected according to the brake position.

3.13.6.2.1.8.1 If the brake position is “Passenger train in P”, the set of Kv_int shall be calculated as a function of the maximum emergency brake deceleration (A_ebmax) in the following way (see also figure 10):

Kv_int_x = Kv_int_x_a when A_ebmax ≤ A_P12. Kv_int_x = Kv_int_x_b when A_ebmax ≥ A_P23. Kv_int_x = Kv_int_x_a + (A_ebmax - A_P12)/(A_P23 - A_P12) * (Kv_int_x_b - Kv_int_x_a) when A_P12 < A_ebmax < A_P23.”

<!-- end of page 135 -->

<!-- Start of picture text -->
Kv_int<br>Kv_int_0_a<br>Kv_int_0_b<br>Kv_int_1_a<br>Kv_int_3_a  Kv_int_2_a<br>Kv_int_1_b  Kv_int_2_b<br>Kv_int_4_a  Kv_int_3_b<br>Kv_int_4_b<br>A_P12  A_P23  A_ebmax<br><!-- End of picture text -->

**Figure 37: Kv_int structure for conventional passenger trains**

3.13.6.2.1.8.2 The maximum EB deceleration A_ebmax shall be the maximum of A_brake_emergency between 0 km/h and the maximum speed of the train.

3.13.6.2.1.9 Note: Figure 38 gives an example of the influence of the various track/train characteristics on A_safe(V,d) and consequently on the EBD curve (see 3.13.8.3).

<!-- Start of picture text -->
speed  EBD<br>A_safe7<br>A_safe5<br>A_safe6<br>A_brake_emergency(v)<br>change<br>A_safe3<br>A_safe4<br>A_brake_emergency(v)<br>change<br>A_safe2 A_brake_emergency(v)<br>change<br>A_safe1<br>start of track  End of reduced  Gradient  Gradient  Distance<br>condition & start  adhesion  change  change<br>of reduced<br>adhesion<br><!-- End of picture text -->

**Figure 38: Influence of track/train characteristics on A_safe**

#### **3.13.6.2.2 Safe brake build up time**

3.13.6.2.2.1 The safe brake build up time, T_be, is safety relevant. This means that for the calculation of the safe brake build up time, all necessary track and train characteristics shall be taken into account.

3.13.6.2.2.2 The train and track related characteristics to be considered are:

   - a) The values of T_brake_emergency_react and T_brake_emergency acquired as part of Train Data (see 3.13.2.2.3.2.8) or the values of T_brake_emergency_react and

<!-- end of page 136 -->

T_brake_emergency derived from the conversion model (see 3.13.3.4) using the brake position and train length acquired as Train Data.

   - b) The integrated correction factor Kt_int, only if the conversion model is used  (see 3.13.2.3.7)

   - c) The status of the regenerative brake, eddy current brake, magnetic shoe brake and Ep brake system (see 3.13.2.2.6), only if the values of T_brake_emergency are acquired as part of Train Data

3.13.6.2.2.3 The safe brake reaction time T_be_react and the safe brake build up time T_be shall be equal to:

If values of T_brake_emergency are acquired as part of Train Data:

- T_be_react = T_brake_emergency_react, with T_brake_emergency_react corresponding to the combination of special brakes currently in use

- T_be = T_brake_emergency, with T_brake_emergency corresponding to the combination of special brakes currently in use

If the conversion model is used:

T_be_react = Kt_int * T_brake_emergency_react

T_be = Kt_int * T_brake_emergency

3.13.6.2.2.4 The safe brake build up reduced time T_be_reduced shall be obtained for every target from T_be and T_be_react as defined in section A.3.12.

3.13.6.2.2.4.1 Note: Applying the Brake Build Up Time ramp model, it is possible that the predicted train speed reaches standstill or decelerates under the target speed before T_be time elapses.

**3.13.6.3 Service brake**

#### **3.13.6.3.1 Expected deceleration**

3.13.6.3.1.1 Since the expected deceleration is not safety relevant, no worst case conditions (e.g. correction factors, adhesion conditions) need to be taken into account for its calculation.

3.13.6.3.1.2 The train and track related characteristics to be considered are:

   - a) The speed dependent deceleration model(s) for the full service brake either acquired as part of Train Data (see 3.13.2.2.3.1) or derived from the brake percentage using the conversion model (see 3.13.3.3)

   - b) The acceleration/deceleration due to gradient i.e. A_gradient(d) (see c))

   - c) The locations without special brake contribution (see 3.13.5)

3.13.6.3.1.3 A_expected(V,d) shall be equal to:

A_expected(V,d) = A_brake_service(V,d) +A_gradient(d)

<!-- end of page 137 -->

3.13.6.3.1.4 A_brake_service(V,d) shall be the full deceleration of the service brake as a function of the speed, of the locations with change of special brake(s) contribution encountered between the train front and the foot of the SBD curve. A_brake_service(V,d) shall be equal to:

A_brake_service1(V) when destfront ≤ d ≤ d1

A_brake_service2(V) when d1 < d ≤ d2

A_brake_service3(V) when d2 < d ≤ d3

Where

d1, d2, d3,... are the locations with change of special brake(s) contribution

A_brake_servicex(V) is equal to the full service brake model, A_brake_service, applicable for the concerned combination of brake.

#### **3.13.6.3.2 Expected brake build up time**

3.13.6.3.2.1 Since the expected brake build up time is not safety relevant, no worst case conditions (e.g. correction factors, adhesion conditions) need to be taken into account for its calculation.

3.13.6.3.2.2 No track related characteristics are to be considered for the expected brake build up time.

3.13.6.3.2.3 The train related characteristics to be considered are:

   - a) The values of T_brake_service_react and T_brake_service acquired as part of Train Data (see 3.13.2.2.3.2.8) or the value(s) of T_brake_service_react and T_brake_service derived from the conversion model (see 3.13.3.4) using the brake position and train length acquired as Train Data)

   - b) The status of the regenerative brake, eddy current brake and Ep brake system (see 3.13.2.2.6)

3.13.6.3.2.4 The expected brake reaction time T_bs_react and the expected brake build up time T_bs shall be equal to the brake build up time of the full service brake:

   - T_bs_react = T_brake_service_react, with T_brake_service_react corresponding to the combination of special brakes currently in use

   - T_bs = T_brake_service, with T_brake_service corresponding to the combination of special brakes currently in use

3.13.6.3.2.5 If the service brake feedback is not available for use, the expected brake build up reduced time T_bs_reduced shall be obtained for every target from T_bs as defined in section A.3.12. Otherwise, T_bs_reduced shall be set to T_bs for every target.

3.13.6.3.2.5.1 Note: Applying the Brake Build Up Time ramp model, it is possible that the predicted train speed reaches standstill or decelerates under the target speed before T_bs time elapses.

<!-- end of page 138 -->

#### **3.13.6.4 Normal service brake deceleration**

3.13.6.4.1 Since the normal service brake deceleration is not safety relevant, no worst case conditions (e.g. correction factors, adhesion conditions) need to be taken into account for its calculation.

3.13.6.4.2 The train and track related characteristics to be considered are:

   - a) The speed dependent deceleration model(s) for the full service brake either acquired as part of Train Data (see 3.13.2.2.3.1) or derived from the brake percentage using the conversion model (see 3.13.3.3)

   - b) The speed dependent deceleration model(s) for the normal service brake acquired as part of Train Data (see 3.13.2.2.3.1)

   - c) The acceleration/deceleration due to gradient i.e. A_gradient(d) (see c))

   - d) The brake position (see 3.13.2.2.4)

   - e) The on-board correction factors Kn+(V) and Kn-(V) (see 3.13.2.2.9.2)

   - f) The locations without special brake contribution (see 3.13.5)

   - g) The gradient profile compensated in location according to the train length (see 3.13.4.2)

3.13.6.4.3 The normal service brake deceleration shall be equal to:

For positive gradient values (uphill):

- A_normal_service(V,d) = A_brake_normal_service(V,d) + A_gradient(d) – Kn+(V)*grad(d)/1000

For negative gradient values (downhill):

A_normal_service(V,d) = A_brake_normal_service(V,d) + A_gradient(d) – Kn-(V)*grad(d)/1000

#### Where

grad = gradient values in ‰ (positive = uphill)

3.13.6.4.4 A_brake_normal_service(V,d) shall be the normal deceleration of the service brake as a function of the speed, of the locations with change of special brake(s) contribution encountered between the train front and the foot of the GUI curve. A_brake_normal_service(V,d) shall be equal to:

   - A_brake_normal_service1(V) when destfront ≤ d ≤ d1

   - A_brake_normal_service2(V) when d1 < d ≤ d2

   - A_brake_normal_service3(V) when d2 < d ≤ d3

#### Where

d1, d2, d3,... are the locations with change of special brake(s) contribution

<!-- end of page 139 -->

A_brake_normal_servicex(V) is equal to the normal service brake model applicable for the concerned combination of brake position and of the value of A_brake_service(V=0) between dx-1 and dx (see 3.13.2.2.3.1.9 and 3.13.2.2.3.1.10).

### **3.13.7 Determination of Most Restrictive Speed Profile (MRSP)**

3.13.7.1 The Most Restrictive Speed Profile (MRSP) is a description of the most restrictive speed restrictions the train must obey on a given piece of track.

3.13.7.2 The Most Restrictive Speed Profile shall be derived from elements corresponding to all speed restrictions (see 3.13.2.2.13 & 3.13.2.3.2), some elements being compensated by the train length if requested by trackside (see 3.11.3.1.3 for SSP, 3.11.4.6 for ASP and 3.11.5.3 for TSR). To do so, the ERTMS/ETCS on-board shall continuously compute the MRSP current speed (V_MRSP), which is the lowest speed of the MRSP elements encountered between the min safe front end and the max safe front end of the train.

<!-- Start of picture text -->
V<br>d<br>Speed Restriction categories Train length<br>Most Restrictive Speed Profile (with L_DOUBTOVER & L_DOUBTUNDER = 0)<br><!-- End of picture text -->

#### **Figure 39: Most Restrictive Speed Profile selection**

3.13.7.2.1 Note 1: The envelope of V_MRSP over a given piece of track travelled by the train forms the MRSP.

3.13.7.2.2 Note 2: The MRSP as a whole cannot be computed in advance by the on-board equipment, since the locations of its speed increases/decreases depend on the size of the train position confidence interval at a given time/location.

### **3.13.8 Determination of targets and brake deceleration curves**

#### **3.13.8.1 Introduction**

3.13.8.1.1 A target is defined by a target location and a target speed, to which the train must decelerate before reaching the target location.

3.13.8.1.2 For that purpose, the on-board equipment shall use brake deceleration curves related to the supervised targets, from the deceleration values as specified in sections 3.13.6.2.1, 3.13.6.3.1and 3.13.6.3.2.5.

<!-- end of page 140 -->

3.13.8.1.3 These deceleration values being speed and distance dependent, a brake deceleration curve shall be calculated piecewise, i.e. it shall be composed of interconnected arcs of parabola, each one being based on one of the speed/distance dependent deceleration values (see Figure 38).

#### **3.13.8.2 Determination of the supervised targets**

3.13.8.2.1 The on-board shall continuously supervise a list of targets, which may include the following types of target:

   - a) the start locations of the MRSP elements whose speed is lower than V_MRSP and which are in advance of the max safe front end of the train

   - b) the Limit of Authority (LOA)

   - c) the End of Authority (EOA) and the Supervised Location (SvL)

   - d) the location deduced from the maximum permitted distance to run in Staff Responsible, with a target speed zero

3.13.8.2.1.1 Note: depending on the information received from trackside and the position of the train, the list of supervised targets may be empty.

3.13.8.2.2 The list of supervised targets shall be re-evaluated when any of the elements it is built of is changed (e.g. new MA and/or track description accepted on-board, update of stored information in specific situations (see sections A.3.4 and 4.10)).

3.13.8.2.3 A target corresponding to an MRSP element shall be removed from the list of supervised targets when the max safe front end of the train has passed the target location.

#### **3.13.8.3 Emergency Brake Deceleration curves (EBD)**

3.13.8.3.1 If a target belongs to the MRSP or is an LOA, the on-board shall calculate an EBD curve based on the safe deceleration A_safe(V,d), that crosses the ceiling speed EBI supervision limit (see 3.13.9.2) at the target location, and that extends up to the location where the target speed is reached (EBD foot).

<!-- end of page 141 -->

<!-- Start of picture text -->
Speed<br>EBD<br>reference<br>EBD curve<br>EBI<br>Target speed<br>Ceiling speed limits<br>(from MRSP<br>or LoA)  Permitted<br>EBD<br>target location<br>foot   Distance<br><!-- End of picture text -->

**Figure 40: Calculation of the EBD curve with regards to MRSP or LOA target**

3.13.8.3.2 If a target is an SvL, the on-board shall calculate an Emergency Brake Deceleration (EBD) curve based on the safe deceleration A_safe(V,d) and that reaches zero speed at the SvL.

3.13.8.3.3 If a target is the location at the end of the maximum permitted distance to run in Staff Responsible, the on-board shall calculate an Emergency Brake Deceleration (EBD) curve based on the safe deceleration A_safe(V,d) and that reaches zero speed at this staff responsible end location.

<!-- Start of picture text -->
Speed<br>EBD curve<br>EBD  EBD<br>reference  =  foot<br>SvL or<br>Location from max<br>SR distance<br>Distance<br><!-- End of picture text -->

**Figure 41: Calculation of the EBD curve with regards to SvL or SR distance**

#### **3.13.8.4 Service Brake Deceleration curves (SBD)**

3.13.8.4.1 If a target is an EOA, the on-board shall calculate an Service Brake Deceleration (SBD) curve based on the expected deceleration A_expected(V,d) and that reaches zero speed at this EOA location.

<!-- end of page 142 -->

<!-- Start of picture text -->
Speed<br>SBD curve<br>SBD  SBD<br>reference  = foot<br>EOA<br>Distance<br><!-- End of picture text -->

#### **Figure 42: Calculation of the SBD curve with regards to EOA**

#### **3.13.8.5 Guidance curves (GUI)**

3.13.8.5.1 The purpose of the guidance curve (GUI) is to provide a comfortable way of braking for the driver, to avoid excessive wear of the brakes and to save traction energy.

3.13.8.5.2 If the National Value does not inhibit them, the on-board shall calculate a guidance curve (GUI) for each supervised target, based on the normal service brake deceleration A_normal_service(V,d). The foot of a GUI curve (i.e. the location where the GUI speed is equal to the target speed) shall be:

   - a) the target location, in case of EOA/SvL

   - b) the location defined in 3.13.9.3.5.9, for others targets

### **3.13.9 Supervision limits**

#### **3.13.9.1 Overview**

3.13.9.1.1 In this chapter the following supervision limits are defined:

   - Emergency brake intervention (EBI)

   - Service brake intervention (SBI)

   - Warning (W)

   - Permitted speed (P)

   - Indication (I)

   - Release speed monitoring start location

3.13.9.1.2 The purpose of the emergency brake intervention supervision limit is to assure that the train will remain within the various limits (in distance/speed) imposed by the trackside.

<!-- end of page 143 -->

3.13.9.1.3 The purpose of all other supervision limits is to assist the driver in preventing an emergency brake intervention by maintaining the speed of the train within the appropriate limits.

#### **3.13.9.2 Ceiling supervision limits**

3.13.9.2.1 The ceiling supervision limits are derived from the MRSP elements, where the speed is constant (refer to 3.13.7) or from the LOA.

3.13.9.2.2 From an MRSP element or from the LOA, the Permitted speed, Warning, Service brake intervention and Emergency brake intervention supervision limits are defined (see Figure 43).

<!-- Start of picture text -->
Speed<br>EBI<br>dV_ebi<br>SBI<br>dV_sbi<br>W<br>dV_warning<br>P = VMRSP (or LOA<br>speed)<br>distance<br><!-- End of picture text -->

**Figure 43: Ceiling supervision limits**

3.13.9.2.3 For dv_ebi, the following formula shall be applied:

<!-- Start of picture text -->
when  𝑉𝑀𝑅𝑆𝑃 > 𝑉𝑒𝑏𝑖𝑚𝑖𝑛 :<br>𝑑𝑉𝑒𝑏𝑖 = 𝑚𝑖𝑛{𝑑𝑉𝑒𝑏𝑖𝑚𝑖𝑛 + 𝐶𝑒𝑏𝑖 ⋅(𝑉𝑀𝑅𝑆𝑃 −𝑉𝑒𝑏𝑖𝑚𝑖𝑛), 𝑑𝑉𝑒𝑏𝑖𝑚𝑎𝑥}<br>(𝑑𝑉𝑒𝑏𝑖𝑚𝑎𝑥−𝑑𝑉𝑒𝑏𝑖𝑚𝑖𝑛)<br>with  𝐶𝑒𝑏𝑖 =<br>(𝑉𝑒𝑏𝑖𝑚𝑎𝑥−𝑉𝑒𝑏𝑖𝑚𝑖𝑛)<br>when  𝑉𝑀𝑅𝑆𝑃 ≤𝑉𝑒𝑏𝑖𝑚𝑖𝑛 :  𝑑𝑉𝑒𝑏𝑖 = 𝑑𝑉𝑒𝑏𝑖𝑚𝑖𝑛<br>dV_ebi<br>dV_ebi_max<br>dV_ebi_min<br>0  V_ebi_min  V_ebi_max  V_MRSP/ LOA speed<br><!-- End of picture text -->

**Figure 44: Definition of dV_ebi**

<!-- end of page 144 -->

3.13.9.2.4 dV_ebi_min, dV_ebi_max, V_ebi_min and V_ebi_max are defined as fixed values (See Appendix A.3.1)

3.13.9.2.5 For dV_sbi, the same formula as for dV_ebi shall apply, dV_sbi_min, dV_sbi_max, V_sbi_min and V_sbi_max being also defined as fixed values (See Appendix A.3.1)

3.13.9.2.6 For dV_warning, the same formula as for dV_ebi shall apply, dV_warning_min, dV_warning_max, V_warning_min and V_warning_max being also defined as fixed values (See Appendix A.3.1)

3.13.9.2.7 For LOA, the same formulas shall apply, by substituting V_MRSP with the LOA speed.

3.13.9.2.8 Intentionally deleted.

**3.13.9.3 Braking to target supervision limits**

**3.13.9.3.1 Overview**

3.13.9.3.1.1 The braking to target supervision limits are derived from the EBD, SBD and GUI curves.

3.13.9.3.1.2 From an EBD curve, the Emergency brake intervention (EBI), Service brake intervention (SBI2), Warning (W), Permitted speed (P) and Indication (I) supervision limits, valid for the estimated speed, are defined as follows(see Figure 45):

<!-- Start of picture text -->
EBD curve<br>speed  Dbec<br>Vbec<br>Vdelta2<br>Aest1<br>Aest2 Vdelta1<br>W  Vdelta0<br>Vest P<br>I  SBI2  EBI<br>Tind.Vest Tdriver.Vest Tbs2.Vest<br>Twarning.Vest<br>distance<br><!-- End of picture text -->

#### **Figure 45: Braking to target supervision limits from EBD curve**

3.13.9.3.1.3 From the SBD curve, Service brake intervention (SBI1), Warning (W), Permitted speed (P) and Indication (I) supervision limits, valid for the estimated speed, are defined as follows (see Figure 46):

<!-- end of page 145 -->

<!-- Start of picture text -->
speed  SBD curve<br>W<br>Vest P<br>I  SBI1<br>Tind.Vest Tdriver.Vest Tbs1.Vest<br>Twarning.Vest<br>EOA  distance<br><!-- End of picture text -->

**Figure 46: Braking to target supervision limits from SBD curve**

3.13.9.3.1.4 No specific supervision limit is calculated from the GUI curve: it is only used to adjust the Permitted speed (P) supervision limit, which is obtained either from the EBD or the SBD curve.

#### **3.13.9.3.2 EBI supervision limit**

3.13.9.3.2.1 If not inhibited by National Value, the ERTMS/ETCS on-board equipment shall compensate the inaccuracy of the speed measurement by taking into account the speed under reading amount (V_ura) at the moment when the calculation is made: V_delta0 = V_ura (see Figure 45).

3.13.9.3.2.2 The time elapsed between the Emergency brake intervention and the full application of the braking effort is reached (EBD) shall be split into two parts:

   - a) Time during which the traction effort is still present: T_traction

   - b) Remaining time during which the traction effort is not present: T_berem

3.13.9.3.2.3 The traction time (T_Traction) shall be defined as follows:

   - a) when the traction cut-off is implemented:

      - T_traction = MAX((T_traction_cut_off - (T_warning + T_bs2)) ; 0).

   - b) when the traction cut-off is not implemented: T_traction = T_traction_cut_off

3.13.9.3.2.4 Note: When the traction cut-off is implemented, the traction cut-off command is triggered when passing the warning limit. The term (T_warning + T_bs2) in the equation above takes this into account, assuming that the warning limit is derived from the EBD.

3.13.9.3.2.5 T_bs2 and T_warning are defined in sections 3.13.9.3.3 and 3.13.9.3.4.

3.13.9.3.2.6 The remaining time with no traction (T_berem) shall be equal to MAX(T_be_reduced - T_traction ; 0).

<!-- end of page 146 -->

3.13.9.3.2.7 Intentionally deleted.

3.13.9.3.2.8 During T_traction, the estimated acceleration (A_est1) shall be the one measured at the moment when the calculation is made, but limited to positive or null values.

3.13.9.3.2.9 If T_be_reduced > T_traction, the estimated acceleration during T_berem (A_est2) shall be the one measured at the moment when the calculation is made, but limited to values between 0 and +0.4m/s<sup>2</sup> .

3.13.9.3.2.10 The compensated speed and the distance travelled during the time elapsed between the Emergency brake intervention and the full application of the braking effort is reached shall be derived as follows (see Figure 45):

𝑉𝑏𝑒𝑐 = 𝑚𝑎𝑥{(𝑉𝑒𝑠𝑡 + 𝑉𝑑𝑒𝑙𝑡𝑎0 + 𝑉𝑑𝑒𝑙𝑡𝑎1), 𝑉𝑡𝑎𝑟𝑔𝑒𝑡} + 𝑉𝑑𝑒𝑙𝑡𝑎2

with 𝑉𝑑𝑒𝑙𝑡𝑎0 = 𝑉𝑢𝑟𝑎 or 𝑉𝑑𝑒𝑙𝑡𝑎0 = 0 (if compensation of speed inaccuracy is inhibited by National Value)

with 𝑉𝑑𝑒𝑙𝑡𝑎1 = 𝐴𝑒𝑠𝑡1 ⋅𝑇𝑡𝑟𝑎𝑐𝑡𝑖𝑜𝑛 and 𝑉𝑑𝑒𝑙𝑡𝑎2 = 𝐴𝑒𝑠𝑡2 ⋅𝑇𝑏𝑒𝑟𝑒𝑚

3.13.9.3.2.11 Note: The formula avoids that V_bec is lower than V_target.

3.13.9.3.2.12 For the estimated speed V_est, the location of the EBI supervision limit shall be: 𝑑𝐸𝐵𝐼(𝑉𝑒𝑠𝑡) = 𝑑𝐸𝐵𝐷(𝑉𝑏𝑒𝑐) −𝐷𝑏𝑒𝑐

#### **3.13.9.3.3 SBI supervision limit**

3.13.9.3.3.1 For the EOA, the on-board shall calculate the location of the SBI supervision limit (SBI1) valid for the estimated speed, assuming that this latter remains constant during the interval T_bs1, until the SBD curve is reached.

- 𝑑𝑆𝐵𝐼1(𝑉𝑒𝑠𝑡) = 𝑑𝑆𝐵𝐷(𝑉𝑒𝑠𝑡) −𝑉𝑒𝑠𝑡 ⋅𝑇𝑏𝑠1

3.13.9.3.3.2 For an EBD based target, the on-board shall calculate the location of the SBI supervision limit (SBI2) valid for the estimated speed, assuming that this latter remains constant during the interval T_bs2, until the location of the EBI supervision limit is reached.

𝑑𝑆𝐵𝐼2(𝑉𝑒𝑠𝑡) = 𝑑𝐸𝐵𝐼(𝑉𝑒𝑠𝑡) −𝑉𝑒𝑠𝑡 ⋅𝑇𝑏𝑠2

3.13.9.3.3.3 If the service brake command is available for use and the service brake feedback is not available for use, T_bs1 and T_bs2 shall be equal to T_bs_reduced.

3.13.9.3.3.4 If both the service brake command and the service brake feedback are available for use, T_bs1 and T_bs2 shall by default be set to T_bs. When the service brake is used by the driver in target speed monitoring or release speed monitoring, they shall be reduced and possibly locked to the respective fixed values of 0s and T_bs2_locked, until

<!-- end of page 147 -->

the ceiling speed monitoring is entered; they are then reset to T_bs (refer to detailed algorithm in Appendix A.3.10).

3.13.9.3.3.4.1 In case T_bs < T_bs2_locked then T_bs2 shall be equal to T_bs2_locked.

3.13.9.3.3.5 If the service brake command is not available for use, T_bs1 and T_bs2 shall be set to zero.

3.13.9.3.3.6 Note: The values T_bs1 and T_bs2 = 0s are defined to achieve the maximum performance when service brake command is not used.

3.13.9.3.3.7 For display purpose only, the SBI1 speed for the estimated train front end, shall be calculated as follows (see Figure 47):

- 𝑉𝑆𝐵𝐼1(𝑑𝑒𝑠𝑡𝑓𝑟𝑜𝑛𝑡) = 𝑉𝑆𝐵𝐷(𝑑𝑒𝑠𝑡𝑓𝑟𝑜𝑛𝑡 + 𝑉𝑒𝑠𝑡 ⋅𝑇𝑏𝑠1) 𝑉𝑆𝐵𝐼1(𝑑𝑒𝑠𝑡𝑓𝑟𝑜𝑛𝑡) = 0 if 𝑑𝑒𝑠𝑡𝑓𝑟𝑜𝑛𝑡 + 𝑉𝑒𝑠𝑡 ⋅𝑇𝑏𝑠1 ≥𝑑𝐸𝑂𝐴

<!-- Start of picture text -->
speed  SBD curve<br>SBI1<br>Vest<br>P  SBI1<br>Vest.Tbs1<br>destfront EOA  distance<br><!-- End of picture text -->

#### **Figure 47: Calculation of SBI1 speed displayed to the driver**

3.13.9.3.3.8 For display purpose only, the SBI2 speed for the max safe front end of the train shall be calculated as follows (see Figure 48):

𝑉𝑆𝐵𝐼2(𝑑𝑚𝑎𝑥𝑠𝑎𝑓𝑒𝑓𝑟𝑜𝑛𝑡) = 𝑉𝑡𝑎𝑟𝑔𝑒𝑡 + 𝑑𝑉𝑠𝑏𝑖(𝑉𝑡𝑎𝑟𝑔𝑒𝑡) if 𝑑𝑚𝑎𝑥𝑠𝑎𝑓𝑒𝑓𝑟𝑜𝑛𝑡 + 𝑉𝑒𝑠𝑡 ⋅𝑇𝑏𝑠2 + 𝐷𝑏𝑒𝑑𝑖𝑠𝑝𝑙𝑎𝑦 ≥𝑑𝐸𝐵𝐷(𝑉𝑡𝑎𝑟𝑔𝑒𝑡)

<!-- end of page 148 -->

With 𝑉𝑑𝑒𝑙𝑡𝑎0 , 𝑉𝑑𝑒𝑙𝑡𝑎1 and 𝑉𝑑𝑒𝑙𝑡𝑎2 calculated according to 3.13.9.3.2.10

<!-- Start of picture text -->
𝑉𝑑𝑒𝑙𝑡𝑎1 𝑉𝑑𝑒𝑙𝑡𝑎2<br>With  𝐷𝑏𝑒𝑑𝑖𝑠𝑝𝑙𝑎𝑦 = (𝑉𝑒𝑠𝑡 + 𝑉𝑑𝑒𝑙𝑡𝑎0 + 2 ) ⋅𝑇𝑡𝑟𝑎𝑐𝑡𝑖𝑜𝑛 + (𝑉𝑒𝑠𝑡 + 𝑉𝑑𝑒𝑙𝑡𝑎0 + 𝑉𝑑𝑒𝑙𝑡𝑎1 + 2 )  ⋅𝑇𝑏𝑒𝑟𝑒𝑚<br>speed<br>EBD curve<br>D<br>be<br>SBI2  display<br>Vbec<br>Vdelta0+V delta1+ Vdelta2<br>Vest<br>SBI2  EBI<br>P<br>Tbs2.Vest<br>dmaxsafefront distance<br><!-- End of picture text -->

**Figure 48: Calculation of SBI2 speed displayed to the driver**

3.13.9.3.3.8.1 Note: the re-use of the same distance travelled and speed increase between the SBI2 supervision limit and the EBD, as for the estimated speed (see Figure 48), leads to an overestimation/underestimation of the SBI2 speed to be displayed to the driver. This simplification, which avoids the need of an iterated calculation, is however acceptable and necessary since the error made tends to zero when the train reaches the SBI2 supervision limit.

3.13.9.3.3.9 Intentionally deleted.

#### **3.13.9.3.4 Warning supervision limit (W)**

3.13.9.3.4.1 The on-board shall calculate the location of the Warning supervision limit valid for the estimated speed, assuming that this latter remains constant during the interval T_warning until the location of the SBI1 (for the EOA) or the SBI2 (for an EBD based target) supervision limit is reached.

𝑑𝑊(𝑉𝑒𝑠𝑡) = 𝑑𝑆𝐵𝐼1(𝑉𝑒𝑠𝑡) −𝑉𝑒𝑠𝑡 ⋅𝑇𝑤𝑎𝑟𝑛𝑖𝑛𝑔 for the EOA

- 𝑑𝑊(𝑉𝑒𝑠𝑡) = 𝑑𝑆𝐵𝐼2(𝑉𝑒𝑠𝑡) −𝑉𝑒𝑠𝑡 ⋅𝑇𝑤𝑎𝑟𝑛𝑖𝑛𝑔 for an EBD based target

3.13.9.3.4.2 T_warning is defined as a fixed value (refer to A.3.1).

<!-- end of page 149 -->

#### **3.13.9.3.5 Permitted speed supervision limit (P)**

3.13.9.3.5.1 In case the calculation of the GUI curve is inhibited, the on-board shall calculate the location of the Permitted speed supervision limit valid for the estimated speed, assuming that this latter remains constant during the interval T_driver until the location of the SBI1 (for the EOA) or the SBI2 (for an EBD based target) supervision limit is reached.

- 𝑑𝑃(𝑉𝑒𝑠𝑡) = 𝑑𝑆𝐵𝐼1(𝑉𝑒𝑠𝑡) −𝑉𝑒𝑠𝑡 ⋅𝑇𝑑𝑟𝑖𝑣𝑒𝑟 for the EOA

- 𝑑𝑃(𝑉𝑒𝑠𝑡) = 𝑚𝑖𝑛{(𝑑𝑆𝐵𝐼2(𝑉𝑒𝑠𝑡) −𝑉𝑒𝑠𝑡 ⋅𝑇𝑑𝑟𝑖𝑣𝑒𝑟), 𝑑𝑡𝑎𝑟𝑔𝑒𝑡} for an EBD based target

3.13.9.3.5.2 T_driver is defined as a fixed value (refer to A.3.1).

3.13.9.3.5.3 Note: The reference for the Permitted speed supervision limit is the SBI supervision limit and not the Warning supervision limit. As a result the permitted and warning supervision limits are clearly separated and do not affect each other. In this way it is clear that the warning is not part of the critical performance interval.

3.13.9.3.5.4 In case the calculation of the Guidance curve is enabled, the on-board shall calculate the location of the Permitted speed supervision limit valid for the estimated speed, as follows:

- 𝑑𝑃(𝑉𝑒𝑠𝑡) = 𝑚𝑖𝑛{(𝑑𝑆𝐵𝐼1(𝑉𝑒𝑠𝑡) −𝑉𝑒𝑠𝑡 ⋅𝑇𝑑𝑟𝑖𝑣𝑒𝑟), 𝑑𝐺𝑈𝐼(𝑉𝑒𝑠𝑡)} for the EOA

- 𝑑𝑃(𝑉𝑒𝑠𝑡) = 𝑚𝑖𝑛{(𝑑𝑆𝐵𝐼2(𝑉𝑒𝑠𝑡) −𝑉𝑒𝑠𝑡 ⋅𝑇𝑑𝑟𝑖𝑣𝑒𝑟), 𝑑𝐺𝑈𝐼(𝑉𝑒𝑠𝑡)} for an EBD based target

3.13.9.3.5.5 In case the calculation of the GUI curve is inhibited, for display purpose only, the P speed related to SBD shall be calculated for the estimated train front end as follows:

3.13.9.3.5.6 In case the calculation of the GUI curve is enabled, for display purpose only, the P speed related to SBD shall be calculated for the estimated train front end as follows:

[𝑉𝑃(𝑑𝑒𝑠𝑡𝑓𝑟𝑜𝑛𝑡)]𝐸𝑂𝐴 = 𝑚𝑖𝑛{𝑉𝑆𝐵𝐷 (𝑑𝑒𝑠𝑡𝑓𝑟𝑜𝑛𝑡 + 𝑉𝑒𝑠𝑡 ⋅(𝑇𝑑𝑟𝑖𝑣𝑒𝑟 + 𝑇𝑏𝑠1)) , [𝑉𝐺𝑈𝐼(𝑑𝑒𝑠𝑡𝑓𝑟𝑜𝑛𝑡)]𝐸𝑂𝐴} [𝑉𝑃(𝑑𝑒𝑠𝑡𝑓𝑟𝑜𝑛𝑡)]𝐸𝑂𝐴 = 0 if 𝑑𝑒𝑠𝑡𝑓𝑟𝑜𝑛𝑡 + 𝑉𝑒𝑠𝑡 ⋅(𝑇𝑑𝑟𝑖𝑣𝑒𝑟 + 𝑇𝑏𝑠1) ≥𝑑𝐸𝑂𝐴

3.13.9.3.5.7 In case the calculation of the GUI curve is inhibited, for display purpose only, the P speed related to EBD, shall be calculated for the max safe front end of the train as follows (see Figure 49):

[𝑉𝑃(𝑑𝑚𝑎𝑥𝑠𝑎𝑓𝑒𝑓𝑟𝑜𝑛𝑡)]𝐸𝐵𝐷−𝑇𝑎𝑟𝑔𝑒𝑡 = 𝑉𝑡𝑎𝑟𝑔𝑒𝑡 if 𝑑𝑚𝑎𝑥𝑠𝑎𝑓𝑒𝑓𝑟𝑜𝑛𝑡 + 𝑉𝑒𝑠𝑡 ⋅(𝑇𝑑𝑟𝑖𝑣𝑒𝑟 + 𝑇𝑏𝑠2) + 𝐷𝑏𝑒𝑑𝑖𝑠𝑝𝑙𝑎𝑦 ≥𝑑𝐸𝐵𝐷(𝑉𝑡𝑎𝑟𝑔𝑒𝑡)

<!-- end of page 150 -->

With V_delta0, V_delta1 and V_delta2 calculated according to 3.13.9.3.2.10

<!-- Start of picture text -->
speed<br>EBD curve<br>D<br>bedisplay<br>P  Vbec<br>Vdelta0+Vdelta1+Vdelta2<br>Vest<br>EBI<br>P<br>(Tdriver+Tbs2).Vest<br>dmaxsafefront distance<br><!-- End of picture text -->

**Figure 49: Calculation of Permitted speed displayed to the driver**

3.13.9.3.5.7.1 Note: the re-use of the same distance travelled and speed increase between the Permitted speed supervision limit and the EBD, as for the estimated speed (see Figure 49), leads to an overestimation/underestimation of the Permitted speed to be displayed to the driver. This simplification, which avoids the need of an iterated calculation, is however acceptable and necessary since the error made tends to zero when the train reaches the Permitted speed supervision limit.

3.13.9.3.5.8 In case the calculation of the GUI curve is enabled, for display purpose only, the P speed related to EBD, shall be calculated for the max safe front end of the train as follows:

<!-- Start of picture text -->
[𝑉𝑃(𝑑𝑚𝑎𝑥𝑠𝑎𝑓𝑒𝑓𝑟𝑜𝑛𝑡)]𝐸𝐵𝐷−𝑇𝑎𝑟𝑔𝑒𝑡 =<br>𝑚𝑎𝑥 𝑚𝑖𝑛  ( 𝑉𝐸𝐵𝐷 (𝑑𝑚𝑎𝑥𝑠𝑎𝑓𝑒𝑓𝑟𝑜𝑛𝑡 −(𝑉𝑑𝑒𝑙𝑡𝑎0 + 𝑉  + 𝑉 𝑒𝑠𝑡 ⋅(𝑇 𝑑𝑒𝑙𝑡𝑎1 𝑑𝑟𝑖𝑣𝑒𝑟  + 𝑉 + 𝑇 𝑑𝑒𝑙𝑡𝑎2 𝑏𝑠2 ) ) + 𝐷𝑏𝑒 𝑑𝑖𝑠𝑝𝑙𝑎𝑦 ) ) , , 𝑉𝑡𝑎𝑟𝑔𝑒𝑡<br>{ { [𝑉𝐺𝑈𝐼(𝑑𝑚𝑎𝑥𝑠𝑎𝑓𝑒𝑓𝑟𝑜𝑛𝑡)]𝐸𝐵𝐷−𝑇𝑎𝑟𝑔𝑒𝑡 } }<br>[𝑉𝑃(𝑑𝑚𝑎𝑥𝑠𝑎𝑓𝑒𝑓𝑟𝑜𝑛𝑡)]𝐸𝐵𝐷−𝑇𝑎𝑟𝑔𝑒𝑡 = 𝑉𝑡𝑎𝑟𝑔𝑒𝑡<br><!-- End of picture text -->

<!-- end of page 151 -->

if 𝑑𝑚𝑎𝑥𝑠𝑎𝑓𝑒𝑓𝑟𝑜𝑛𝑡 + 𝑉𝑒𝑠𝑡 ⋅(𝑇𝑑𝑟𝑖𝑣𝑒𝑟 + 𝑇𝑏𝑠2) + 𝐷𝑏𝑒𝑑𝑖𝑠𝑝𝑙𝑎𝑦 ≥𝑑𝐸𝐵𝐷(𝑉𝑡𝑎𝑟𝑔𝑒𝑡) or if 𝑑𝑚𝑎𝑥𝑠𝑎𝑓𝑒𝑓𝑟𝑜𝑛𝑡 ≥𝑑𝐺𝑈𝐼(𝑉𝑡𝑎𝑟𝑔𝑒𝑡)

With V_delta0, V_delta1 and V_delta2 calculated according to 3.13.9.3.2.10

𝑉𝑑𝑒𝑙𝑡𝑎1 𝑉𝑑𝑒𝑙𝑡𝑎2 With 𝐷𝑏𝑒𝑑𝑖𝑠𝑝𝑙𝑎𝑦 = (𝑉𝑒𝑠𝑡 + 𝑉𝑑𝑒𝑙𝑡𝑎0 + 2 ) ⋅𝑇𝑡𝑟𝑎𝑐𝑡𝑖𝑜𝑛 + (𝑉𝑒𝑠𝑡 + 𝑉𝑑𝑒𝑙𝑡𝑎0 + 𝑉𝑑𝑒𝑙𝑡𝑎1 + 2 ~~)~~ ⋅𝑇𝑏𝑒𝑟𝑒𝑚

3.13.9.3.5.9 In order to determine the reference location of the target distance displayed to the driver, in order to check whether the target is masking another one, and in order to determine the foot of the GUI curve (only if it is enabled) in case of target different from EOA/SvL, the location of the Permitted speed supervision limit, valid for the target speed, shall be calculated from the EBD, taking into account the following assumptions:

   - a) the estimated acceleration shall be set to “zero”

   - b) if not inhibited by National Value, the compensation of the inaccuracy of the speed measurement shall be set to a value calculated from the target speed, as defined in SUBSET-041 § 5.3.1.2: V_delta0t = f41(V_target)

   - c) the safe brake build up time shall be considered to be fully reduced as per A.3.12 algorithm, i.e. it shall be set to 𝑇𝑏𝑒_𝑟𝑒𝑎𝑐𝑡

   - d) if the service brake command is available for use and the service brake feedback is not available for use, the expected brake build up time shall be considered to be fully reduced as per A.3.12 algorithm, i.e. it shall be set to 𝑇𝑏𝑠_𝑟𝑒𝑎𝑐𝑡

   - e) the above-mentioned location of the Permitted speed supervision limit shall not be beyond the target location

3.13.9.3.5.10 To do so, the same formulas defined above with V_est and V_delta0 shall be applied, by substituting V_est with V_target and V_delta0 with V_delta0t.

𝑑𝐸𝐵𝐼(𝑉𝑡𝑎𝑟𝑔𝑒𝑡) = 𝑑𝐸𝐵𝐷(𝑉𝑡𝑎𝑟𝑔𝑒𝑡 + 𝑉𝑑𝑒𝑙𝑡𝑎0𝑡) −(𝑉𝑡𝑎𝑟𝑔𝑒𝑡 + 𝑉𝑑𝑒𝑙𝑡𝑎0𝑡) ⋅(𝑇𝑏𝑒𝑟𝑒𝑚_𝑚𝑖𝑛 + 𝑇𝑡𝑟𝑎𝑐𝑡𝑖𝑜𝑛_𝑚𝑎𝑥) 𝑑𝑃(𝑉𝑡𝑎𝑟𝑔𝑒𝑡) = 𝑀𝐼𝑁{𝑑𝐸𝐵𝐼(𝑉𝑡𝑎𝑟𝑔𝑒𝑡) −𝑉𝑡𝑎𝑟𝑔𝑒𝑡 ⋅(𝑇𝑑𝑟𝑖𝑣𝑒𝑟 + 𝑇𝑏𝑠__𝑓𝑜𝑜𝑡), 𝑑𝑡𝑎𝑟𝑔𝑒𝑡} With 𝑇𝑏𝑒𝑟𝑒𝑚_𝑚𝑖𝑛 = MAX(𝑇𝑏𝑒_𝑟𝑒𝑎𝑐𝑡 − 𝑇𝑡𝑟𝑎𝑐𝑡𝑖𝑜𝑛_𝑚𝑎𝑥 , 0)

With 𝑇𝑏𝑒_𝑟𝑒𝑎𝑐𝑡 as defined in clause 3.13.6.2.2.3

With 𝑇𝑡𝑟𝑎𝑐𝑡𝑖𝑜𝑛_𝑚𝑎𝑥 as defined in A.3.12.2.7

With 𝑇𝑏𝑠_𝑓𝑜𝑜𝑡 set to 𝑇𝑏𝑠_𝑟𝑒𝑎𝑐𝑡 as defined in clause 3.13.6.3.2.4 if the service brake command is available for use and the service brake feedback is not available for use; otherwise set to 𝑇𝑏𝑠2 as defined in section 3.13.9.3.3

3.13.9.3.5.10.1 Justification: the two first assumptions are intended to avoid fluctuations of the target distance displayed to the driver. Moreover the foot of the GUI curve may influence the perturbation location, which must be fully predictable for trackside engineering reasons.

<!-- end of page 152 -->

The third and fourth assumptions are intended to consider the nominal operation, in which the train speed follows the permitted speed, leading to the reduction of the needed brake build up times to the minimum before the target location is reached.

The fifth assumption is to ensure that the permitted speed displayed to the driver, considering the brake build up times reduction, is not higher than the target speed at the target location.

3.13.9.3.5.11 In case a non protected LX start location is supervised as both temporary EOA and SvL and the stopping in rear of LX is not required, the location of the most restrictive Permitted speed supervision limit, valid for the LX speed shall be used in order to determine the location where the supervision of the LX start location is substituted by the supervision of the LX speed (see section 5.16.3).

3.13.9.3.5.12 To calculate this location, the same formulas defined above with V_est shall be applied by substituting V_est with V_LX.

𝑑𝑆𝐵𝐼1(𝑉𝐿𝑋) = 𝑑𝑆𝐵𝐷(𝑉𝐿𝑋) −𝑉𝐿𝑋 ⋅𝑇𝑏𝑠1 𝑑𝑆𝐵𝐼2(𝑉𝐿𝑋) = 𝑑𝐸𝐵𝐼(𝑉𝐿𝑋) −𝑉𝐿𝑋 ⋅𝑇𝑏𝑠2 With

And with V_delta0, V_delta1 and V_delta2 calculated according to 3.13.9.3.2.10 In case the GUI curve is inhibited:

𝑑𝑃(𝑉𝐿𝑋) = 𝑑𝑆𝐵𝐼1(𝑉𝐿𝑋) −𝑉𝐿𝑋 ⋅𝑇𝑑𝑟𝑖𝑣𝑒𝑟 if 𝑑𝑆𝐵𝐼2(𝑉𝐿𝑋)−𝑑𝑆𝐵𝐼1(𝑉𝐿𝑋) ≥𝑑𝑚𝑎𝑥𝑠𝑎𝑓𝑒𝑓𝑟𝑜𝑛𝑡 −𝑑𝑒𝑠𝑡𝑓𝑟𝑜𝑛𝑡 Or 𝑑𝑃(𝑉𝐿𝑋) = 𝑑𝑆𝐵𝐼2(𝑉𝐿𝑋) −𝑉𝐿𝑋 ⋅𝑇𝑑𝑟𝑖𝑣𝑒𝑟 if 𝑑𝑆𝐵𝐼2(𝑉𝐿𝑋)−𝑑𝑆𝐵𝐼1(𝑉𝐿𝑋) < 𝑑𝑚𝑎𝑥𝑠𝑎𝑓𝑒𝑓𝑟𝑜𝑛𝑡 −𝑑𝑒𝑠𝑡𝑓𝑟𝑜𝑛𝑡 In case the GUI curve is enabled:

𝑑𝑃(𝑉𝐿𝑋) = 𝑚𝑖𝑛{(𝑑𝑆𝐵𝐼1(𝑉𝐿𝑋) −𝑉𝐿𝑋 ⋅𝑇𝑑𝑟𝑖𝑣𝑒𝑟), 𝑑𝐺𝑈𝐼(𝑉𝐿𝑋)} if 𝑑𝑆𝐵𝐼2(𝑉𝐿𝑋)−𝑑𝑆𝐵𝐼1(𝑉𝐿𝑋) ≥𝑑𝑚𝑎𝑥𝑠𝑎𝑓𝑒𝑓𝑟𝑜𝑛𝑡 −𝑑𝑒𝑠𝑡𝑓𝑟𝑜𝑛𝑡 Or 𝑑𝑃(𝑉𝐿𝑋) = 𝑚𝑖𝑛{(𝑑𝑆𝐵𝐼2(𝑉𝐿𝑋) −𝑉𝐿𝑋 ⋅𝑇𝑑𝑟𝑖𝑣𝑒𝑟), 𝑑𝐺𝑈𝐼(𝑉𝐿𝑋)} if 𝑑𝑆𝐵𝐼2(𝑉𝐿𝑋)−𝑑𝑆𝐵𝐼1(𝑉𝐿𝑋) < 𝑑𝑚𝑎𝑥𝑠𝑎𝑓𝑒𝑓𝑟𝑜𝑛𝑡 −𝑑𝑒𝑠𝑡𝑓𝑟𝑜𝑛𝑡

3.13.9.3.5.12.1 Note: the use of the instantaneous speed under reading amount and acceleration in the calculation of this location avoids a jump of display when the substitution takes place.

#### **3.13.9.3.6 Indication supervision limit (I)**

3.13.9.3.6.1 The on-board shall calculate the location of the Indication supervision limit valid for the estimated speed, assuming that this latter remains constant during the interval T_indication until the location of the Permitted speed supervision limit is reached.

𝑑𝐼(𝑉𝑒𝑠𝑡) = 𝑑𝑃(𝑉𝑒𝑠𝑡) −𝑉𝑒𝑠𝑡 ⋅𝑇𝑖𝑛𝑑𝑖𝑐𝑎𝑡𝑖𝑜𝑛

<!-- end of page 153 -->

3.13.9.3.6.2 If the service brake feedback interface is not available for use, then T_indication shall be calculated as follows:

𝑇𝑖𝑛𝑑𝑖𝑐𝑎𝑡𝑖𝑜𝑛 = 𝑚𝑎𝑥{(0.8 ⋅𝑇𝑏𝑠_𝑟𝑒𝑑𝑢𝑐𝑒𝑑), 5𝑠} + 𝑇𝑑𝑟𝑖𝑣𝑒𝑟

3.13.9.3.6.3 Note: The reduction of T_indication by a factor is intended to improve performance and the feasibility of this reduction is based on experience with real implementations. To avoid very low values when T_bs_reduced is small, a minimum is defined for T_indication, giving the driver always enough time to operate the brake.

3.13.9.3.6.4 If the service brake feedback interface is available for use then T_indication shall be equal to 5s + T_driver.

3.13.9.3.6.5 If available for use, the service brake feedback shall not have any effect on T_bs1 and T_bs2 when calculating the Indication supervision limit: T_bs1 and T_bs2 shall be set to T_bs in the formulas in 3.13.9.3.2 and 3.13.9.3.3.

3.13.9.3.6.6 Note 1: This avoids that service brake feedback, while braking to one target which causes the full locking of T_bs1 and T_bs2 for all the targets, affects the Indication supervision limit for another target(s). Otherwise, the indication to the driver could come too late. It also avoids its influence on the acceptance criteria of request to shorten MA.

3.13.9.3.6.7 Note 2: If the service brake feedback is not available for use, T_bs1 and T_bs2 are set either to T_bs or to zero, depending on the availability of the service brake command (see 3.13.9.3.3.3 and 3.13.9.3.3.5).

#### **3.13.9.4 Release speed supervision limits**

3.13.9.4.1 The release speed is a special ceiling speed limit, applicable in the vicinity of the EOA. The EBI supervision limit is equal to the release speed. There is no SBI, W, P, I supervision limit associated to the release speed.

3.13.9.4.2 Note: The release speed may be necessary for two reasons. One is that a train has to be able to approach the EOA where the permitted speed reaches zero and might be too restrictive to permit acceptable driving due to inaccuracy of the measured distance. The other reason is that in a level 1 application the train has to be able to overpass the balise when the signal clears. For these two reasons a (low) release speed may be given from trackside or may be calculated on board, based on the distance from the EOA to the Supervised Location.

3.13.9.4.3 With each MA, it shall be possible for the trackside to:

   - a) Give the value of the release speed directly to the on-board, OR

   - b) Instruct the on-board to calculate the release speed, OR

   - c) Instruct the on-board to use the national value.

3.13.9.4.4 In case the MA does not identify the variant to be used or in case of LOA, no release speed shall be supervised.

<!-- end of page 154 -->

3.13.9.4.5 Note: When the release speed is given as a fixed value from trackside, the ERTMS/ETCS system cannot be responsible for stopping the train in rear of the Supervised Location. In this case, it is the full responsibility of the infrastructure manager to set the appropriate release speed with regard to the risk of passing the Supervised Location.

3.13.9.4.6 The start location of the release speed monitoring (i.e. where the EBI supervision limit related to EBD is replaced with an EBI supervision limit equal to the release speed value) shall be the location of the most restrictive SBI supervision limit among the SBI1 related to EOA, the SBI2 related to SvL and, when the Release Speed is calculated on-board, the SBI2 supervision limit(s) related to other target(s), if any, between the Trip location related to the EOA (see d_tripEOA in 3.13.9.4.8.2) and the SvL, calculated for the Release Speed value, taking into account the following assumptions:

   - a) the estimated acceleration shall be set to “zero”

   - b) if not inhibited by National Value, the compensation of the inaccuracy of the speed measurement shall be set to a value calculated from the release speed, as defined in SUBSET-041 § 5.3.1.2: V_delta0rs = f41(V_release)

3.13.9.4.7 To do so, the same formulas defined above with V_est and V_delta0 shall be applied, by substituting V_est with V_release and V_delta0 with V_delta0rs.

𝑑𝑆𝐵𝐼1(𝑉𝑟𝑒𝑙𝑒𝑎𝑠𝑒) = 𝑑𝑆𝐵𝐷(𝑉𝑟𝑒𝑙𝑒𝑎𝑠𝑒) −𝑉𝑟𝑒𝑙𝑒𝑎𝑠𝑒 ⋅𝑇𝑏𝑠1

[𝑑𝑆𝐵𝐼2(𝑉𝑟𝑒𝑙𝑒𝑎𝑠𝑒)]𝑇𝑎𝑟𝑔𝑒𝑡−𝑛 = [𝑑𝐸𝐵𝐼(𝑉𝑟𝑒𝑙𝑒𝑎𝑠𝑒)]𝑇𝑎𝑟𝑔𝑒𝑡−𝑛 −𝑉𝑟𝑒𝑙𝑒𝑎𝑠𝑒 ⋅𝑇𝑏𝑠2 with [𝑑𝐸𝐵𝐼(𝑉𝑟𝑒𝑙𝑒𝑎𝑠𝑒)]𝑇𝑎𝑟𝑔𝑒𝑡−𝑛 = [𝑑𝐸𝐵𝐷(𝑉𝑟𝑒𝑙𝑒𝑎𝑠𝑒 + 𝑉𝑑𝑒𝑙𝑡𝑎0𝑟𝑠)]𝑇𝑎𝑟𝑔𝑒𝑡−𝑛

−(𝑉𝑟𝑒𝑙𝑒𝑎𝑠𝑒 + 𝑉𝑑𝑒𝑙𝑡𝑎0𝑟𝑠) ⋅(𝑇𝑏𝑒𝑟𝑒𝑚 + 𝑇𝑡𝑟𝑎𝑐𝑡𝑖𝑜𝑛)

with Target_n (n=1) being the SvL and, when the Release Speed is calculated on-board, with Target_n (n>1) being any other EBD based target between the Trip location related to the EOA and the SvL

[𝑑𝑆𝐵𝐼2(𝑉𝑟𝑒𝑙𝑒𝑎𝑠𝑒)]𝑀𝑅𝐸𝐵𝐷𝑇 = min{[𝑑𝑆𝐵𝐼2(𝑉𝑟𝑒𝑙𝑒𝑎𝑠𝑒)]𝑇𝑎𝑟𝑔𝑒𝑡−1, … , [𝑑𝑆𝐵𝐼2(𝑉𝑟𝑒𝑙𝑒𝑎𝑠𝑒)]𝑇𝑎𝑟𝑔𝑒𝑡−𝑛}

with MREBDT = SvL or, when the Release Speed is calculated on-board, Most Restrictive Target amongst the EBD based targets between the Trip location related to the EOA and the SvL (included)

𝑑𝑠𝑡𝑎𝑟𝑡 = 𝑑𝑆𝐵𝐼1(𝑉𝑟𝑒𝑙𝑒𝑎𝑠𝑒) if [𝑑𝑆𝐵𝐼2(𝑉𝑟𝑒𝑙𝑒𝑎𝑠𝑒)]𝑀𝑅𝐸𝐵𝐷𝑇−𝑑𝑆𝐵𝐼1(𝑉𝑟𝑒𝑙𝑒𝑎𝑠𝑒) ≥𝑑𝑚𝑎𝑥𝑠𝑎𝑓𝑒𝑓𝑟𝑜𝑛𝑡 −𝑑𝑒𝑠𝑡𝑓𝑟𝑜𝑛𝑡 𝑅𝑆𝑀

Or 𝑑𝑠𝑡𝑎𝑟𝑡 = [𝑑𝑆𝐵𝐼2(𝑉𝑟𝑒𝑙𝑒𝑎𝑠𝑒)]𝑀𝑅𝐸𝐵𝐷𝑇 if 𝑅𝑆𝑀

[𝑑𝑆𝐵𝐼2(𝑉𝑟𝑒𝑙𝑒𝑎𝑠𝑒)]𝑀𝑅𝐸𝐵𝐷𝑇−𝑑𝑆𝐵𝐼1(𝑉𝑟𝑒𝑙𝑒𝑎𝑠𝑒) < 𝑑𝑚𝑎𝑥𝑠𝑎𝑓𝑒𝑓𝑟𝑜𝑛𝑡 −𝑑𝑒𝑠𝑡𝑓𝑟𝑜𝑛𝑡

<!-- end of page 155 -->

<!-- Start of picture text -->
Speed<br>SBD<br>EBD<br>EBI from EBD<br>SBI2<br>EBI = Vrelease<br>SBI1<br>start  EOA  SvL  distance<br>RSM<br><!-- End of picture text -->

**Figure 50: Start location of Release Speed Monitoring**

3.13.9.4.8 When the Release Speed is calculated on-board (Figure 51/51a box 3), its value shall be equal to the most restrictive value, at the Trip location related to the EOA (see d_tripEOA in 3.13.9.4.8.2) plus (only in level 1) a distance in advance taking into account the maximum delay to apply the emergency brake when passing an EOA, amongst the EBI supervision limit related to the SvL (Figure 51/51a box 1) and, if any, the EBI supervision limits(s) related to other target(s) between the Trip location related to the EOA (see d_tripEOA in 3.13.9.4.8.2) and the SvL (Figure 51/51a box 2).

<!-- Start of picture text -->
Speed  EBD(MRSP)<br>EBD(SvL)<br>SBD<br>MRSP<br>EBI(SvL)  1<br>Speed restriction<br>between EOA<br>and SvL<br>SBI1<br>2<br>EBI(MRSP)<br>3<br>Calculated Release<br>Speed due to<br>speed restriction<br>start  EOA  trip location  SvL  distance<br>RSM  related to EOA<br><!-- End of picture text -->

**Figure 51: Calculated Release Speed based on speed restriction between EOA and SvL (level 2)**

<!-- end of page 156 -->

<!-- Start of picture text -->
Speed  EBD(MRSP)<br>EBD(SvL)<br>SBD<br>MRSP<br>Speed restriction<br>EBI(SvL)  1  between EOA<br>and SvL<br>SBI1<br>2<br>3  EBI(MRSP)<br>Calculated Release<br>D41 Dbec<br>Speed due to<br>speed restriction<br>start  EOA  trip location  SvL  distance<br>RSM  related to EOA<br><!-- End of picture text -->

#### **Figure 51a: Calculated Release Speed based on speed restriction between EOA and SvL (level 1)**

3.13.9.4.8.1 In order to calculate in advance the EBI supervision limit(s) referred to in 3.13.9.4.8, the on-board equipment shall take into account an estimated acceleration set to “zero”.

3.13.9.4.8.2 The on-board equipment shall seek for each target referred to in clause 3.13.9.4.8, a release speed value which satisfies the two following inequalities:

𝐴𝐵𝑆{𝑉𝑟𝑒𝑙𝑒𝑎𝑠𝑒 −(𝑉𝐸𝐵𝐷(𝑑𝑡𝑟𝑖𝑝𝐸𝑂𝐴 + 𝛼⋅𝐷41 + 𝐷𝑏𝑒𝑐) −𝑉𝑑𝑒𝑙𝑡𝑎0𝑟𝑠𝑜𝑏)} ≤1𝑘𝑚/ℎ 𝑑𝑡𝑟𝑖𝑝𝐸𝑂𝐴 + 𝛼⋅𝐷41 + 𝐷𝑏𝑒𝑐 ≤𝑑𝐸𝐵𝐷(𝑉𝑡𝑎𝑟𝑔𝑒𝑡)

With 𝑉𝑑𝑒𝑙𝑡𝑎0𝑟𝑠𝑜𝑏 = 𝑚𝑎𝑥{𝑓41(𝑉𝑟𝑒𝑙𝑒𝑎𝑠𝑒), 𝑉𝑢𝑟𝑎} or 𝑉𝑑𝑒𝑙𝑡𝑎0𝑟𝑠𝑜𝑏 = 0 (if compensation of speed inaccuracy is inhibited by National Value)

With 𝐷𝑏𝑒𝑐 = (𝑉𝑟𝑒𝑙𝑒𝑎𝑠𝑒 + 𝑉𝑑𝑒𝑙𝑡𝑎0𝑟𝑠𝑜𝑏) ⋅(𝑇𝑡𝑟𝑎𝑐𝑡𝑖𝑜𝑛 + 𝑇𝑏𝑒𝑟𝑒𝑚)

With 𝑇𝑡𝑟𝑎𝑐𝑡𝑖𝑜𝑛 and 𝑇𝑏𝑒𝑟𝑒𝑚 as defined in 3.13.9.3.2 but considering the traction cut-off as if it was not implemented and substituting 𝑇𝑏𝑒_𝑟𝑒𝑑𝑢𝑐𝑒𝑑 with 𝑇𝑏𝑒 as defined in 3.13.6.2.2.3

With 𝐷41 = 𝑇41 ⋅(𝑉𝑟𝑒𝑙𝑒𝑎𝑠𝑒 + 𝑉𝑑𝑒𝑙𝑡𝑎0𝑟𝑠𝑜𝑏) With

𝑑𝑡𝑟𝑖𝑝𝐸𝑂𝐴 = 𝑑𝐸𝑂𝐴 + 𝛼⋅𝐿𝑎𝑛𝑡𝑒𝑛𝑛𝑎−𝑓𝑟𝑜𝑛𝑡 +𝑚𝑎𝑥{(<sup>2 ⋅𝑄</sup> +𝛽⋅(<sup>𝑙𝑜𝑐𝑎𝑐𝑐−𝑟𝑒𝑓𝐵𝐺</sup> 𝐿𝑡𝑟𝑎𝑖𝑛𝑜𝑣𝑒𝑟<sup>+ 10𝑚+ 10% ⋅𝑑</sup> + 𝐿𝑡𝑟𝑎𝑖𝑛𝑢𝑛𝑑𝑒𝑟 )<sup>𝐸𝑂𝐴</sup> ) , (𝑑𝑚𝑎𝑥𝑠𝑎𝑓𝑒𝑓𝑟𝑜𝑛𝑡 −𝑑𝑚𝑖𝑛𝑠𝑎𝑓𝑒𝑓𝑟𝑜𝑛𝑡)}

And with 𝛼= 1 either if the current level is 1 and no order to switch to level 2 at a location in rear of the EOA is stored on-board or if an order to switch to level 1 at a location in rear of the EOA is stored on-board

<!-- end of page 157 -->

- 𝛼= 0 either if the current level is 2 and no order to switch to level 1 at a location in rear of the EOA is stored on-board or if an order to switch to level 2 at a location in rear of the EOA is stored on-board

And with 𝛽= 1 only from the time a first Supervised Manoeuvre authorisation is received to the time the mission is either ended or continued in Non Leading mode (see clause 3.6.4.1.5 for 𝐿𝑡𝑟𝑎𝑖𝑛𝑜𝑣𝑒𝑟 and 𝐿𝑡𝑟𝑎𝑖𝑛𝑢𝑛𝑑𝑒𝑟) ; otherwise 𝛽= 0 And with T41 as defined in SUBSET-041 § 5.2.1.13

If no speed value higher than V_target fulfils the above inequalities, then:

𝑉𝑟𝑒𝑙𝑒𝑎𝑠𝑒 = 𝑉𝑡𝑎𝑟𝑔𝑒𝑡

3.13.9.4.8.2.1 Note: The above formulas are intended to prevent the calculated release speed from fluctuating, according to the distance, speed and acceleration measurements. It allows calculating the release speed only once, for a given on-board reference location, unless

   - the train position confidence interval exceeds a predicted one, which is based on the assumption that the whole distance between the current on-board reference location and the EOA would be travelled with SUBSET-041 odometer performance values and without any update of the on-board reference location, or

   - the speed under reading amount (V_ura) exceeds the SUBSET-041 performance value

Whenever the on-board reference location is updated (e.g. new LRBG), the release speed will however be recalculated and will increase with a step. This behaviour is acceptable from an operational point of view.

3.13.9.4.8.2.2 Note: The method chosen (e.g. iterative algorithm) to compute the release speed is an implementation issue.

3.13.9.4.9 If the release speed (Figure 52 box 1 gives an example when it is calculated on-board) exceeds any MRSP element anywhere in the area (Figure 52 box 2) delimited on one side by the location situated at a distance equal to the train position confidence interval vs. the SOLR in rear of the presumed start location of the Release speed monitoring and on the other side by the trip location related to the EOA (see d_tripEOA in 3.13.9.4.8.2), the on-board shall use as a fixed release speed (Figure 52 box 4) the most restrictive MRSP element (Figure 52 box 3) within this (these) area(s), and shall re-evaluate the start location of the Release speed monitoring accordingly.

<!-- end of page 158 -->

<!-- Start of picture text -->
speed<br>EBD<br>SBD<br>2<br>SBI  1<br>3<br>MRSP<br>MRSP<br>EBI<br>4<br>Release Speed<br>limited by MRSP<br>train position<br>confidence<br>interval<br>presumed  re-evaluated  EOA  trip location  SvL  distance<br>start of RSM  start of RSM  related to EOA<br><!-- End of picture text -->

**Figure 52: Release Speed limited by MRSP**

3.13.9.4.9.1 Note: the train position confidence interval correction in rear of the presumed start location guarantees that an MRSP element, whose end would not be passed yet by the min safe front end of the train when the presumed start location of the Release speed monitoring is reached, is taken into account to adjust the release speed to the speed of this MRSP element.

**3.13.9.5 Intentionally deleted**

### **3.13.10 Speed and distance monitoring commands**

#### **3.13.10.1 Introduction**

3.13.10.1.1 By comparing the train speed and position to the various supervision limits defined in the previous section, the on-board equipment generates braking commands, traction cut-off commands and relevant information to the driver. The information displayed to the driver is selected according to the following supervision statuses of the speed and distance monitoring function: Normal status, Indication status, Overspeed status, Warning status and Intervention status.

3.13.10.1.2 The following types of speed and distance monitoring are defined:

   - Ceiling speed monitoring (CSM)

   - Target speed monitoring (TSM)

   - Release speed monitoring (RSM)

<!-- end of page 159 -->

<!-- Start of picture text -->
Speed<br>I<br>MRSP<br>release speed<br>monitoring<br>SBI<br>ceiling speed monitoring release speed<br>Distance<br>Start EOA SvL<br>RSM<br><!-- End of picture text -->

#### **Figure 53: Different types of speed and distance monitoring**

3.13.10.1.3 Ceiling speed monitoring is the speed supervision in the area where the train can run without the need to brake to a target.

3.13.10.1.4 Target speed monitoring is the speed and distance supervision in the area where the specific information related to a target is displayed to the driver and within which the train brakes to a target.

3.13.10.1.5 Release speed monitoring is the speed and distance supervision in the area close to the EOA where the train is allowed to run with release speed to approach the EOA.

#### **3.13.10.2 General requirements**

3.13.10.2.1 The train speed indicated to the driver shall be identical to the speed used for the speed monitoring. This shall be the estimated speed.

3.13.10.2.2 Once a Train Interface command (traction cut-off, service brake or emergency brake) is triggered, the on-board shall apply it until its corresponding revocation condition is met.

3.13.10.2.3 If there is no on-board interface with the service brake or if the use of the service brake command is not allowed by a National Value (only in Target speed monitoring), whenever a service brake command is specified, the emergency brake command shall be triggered instead.

3.13.10.2.4 The emergency brake command, which is triggered instead of the service brake command when an SBI supervision limit is exceeded, shall be revoked according to the requirements specified for the revocation of service brake command, unless the emergency brake command has been also triggered due to an EBI supervision limit. In such case, the condition for revoking the emergency brake command due to EBI supervision limit shall prevail.

<!-- end of page 160 -->

3.13.10.2.5 The on-board shall revoke the Intervention status only when no brake command is applied by the speed and distance monitoring function.

3.13.10.2.6 In level 2: Train trip shall be initiated if:

   - a) the on-board equipment detects that the minimum safe front end has passed the EOA/LOA location, OR

   - b) while being in release speed monitoring, the on-board equipment receives a balise group whose first possible location (see 3.4.4.4.3.1) is known by linking information to be:

      - in rear of the EOA by a distance shorter than the distance between the active Eurobalise antenna and the front end of the train, OR

      - at the EOA, OR

      - in advance of the EOA.

3.13.10.2.7 In Level 1: Train Trip shall be initiated if the on-board equipment detects that the minimum safe antenna position has passed the EOA/LOA location.

3.13.10.2.8 Intentionally deleted.

#### **3.13.10.3 Requirements for Ceiling speed monitoring**

3.13.10.3.1 The on-board equipment shall display the Permitted speed ceiling supervision limit.

3.13.10.3.2 When the supervision status is Overspeed, Warning or Intervention, the on-board equipment shall display the SBI speed ceiling supervision limit.

3.13.10.3.3 The on-board shall compare the estimated speed with the ceiling supervision limits defined in section 3.13.9.2 and shall trigger/revoke commands to the train interface (service brake if implemented or emergency brake) and supervision statuses as described in Table 5 and Table 6.

|Triggering<br>condition<br>#|Estimated speed|Location|TI<br>Command<br>triggered|Supervision<br>status triggered|
|---|---|---|---|---|
|t1|𝑉𝑒𝑠𝑡≤𝑉𝑀𝑅𝑆𝑃|Any|-|Normal Status|
|t2|𝑉𝑒𝑠𝑡> 𝑉𝑀𝑅𝑆𝑃|Any|-|Overspeed Status|
|t3|𝑉𝑒𝑠𝑡> 𝑉𝑀𝑅𝑆𝑃+ 𝑑𝑉𝑤𝑎𝑟𝑛𝑖𝑛𝑔(𝑉𝑀𝑅𝑆𝑃)|Any|-|Warning Status|
|t4|𝑉𝑒𝑠𝑡> 𝑉𝑀𝑅𝑆𝑃+ 𝑑𝑉𝑠𝑏𝑖(𝑉𝑀𝑅𝑆𝑃)|Any|SB|Intervention Status|
|t5|𝑉𝑒𝑠𝑡> 𝑉𝑀𝑅𝑆𝑃+ 𝑑𝑉𝑒𝑏𝑖(𝑉𝑀𝑅𝑆𝑃)|Any|EB|Intervention Status|

**Table 5: triggering of Train Interface commands and supervision statuses in ceiling speed monitoring**

<!-- end of page 161 -->

|Revocation<br>condition #|Estimated speed|Location|TI<br>Command<br>revoked|Supervision<br>status revoked|
|---|---|---|---|---|
|r0|Standstill||EB|Intervention Status|
|r1|𝑉𝑒𝑠𝑡≤𝑉𝑀𝑅𝑆𝑃|Any|SB<br>EB (only if<br>allowed by<br>National<br>Value)|Indication Status<br>Overspeed Status<br>Warning Status<br>Intervention Status (in<br>case of EB command,<br>only if allowed by<br>National Value)|

**Table 6: Revocation of Train Interface commands and supervision statuses in ceiling speed**

#### **monitoring**

3.13.10.3.4 The on-board equipment shall execute the transitions between the different supervision statuses as described in Table 7 (see section 4.6.1 for details about the symbols). This table takes into account the order of precedence between the supervision statuses and the possible updates of the MRSP while in ceiling speed monitoring (e.g. when a TSR is revoked).

<!-- Start of picture text -->
Normal  < r1  < r1  < r1  < r0, r1<br>status  -p1-  -p1-  -p1-  -p1-<br>Indication<br>status<br>t2 >  t2 >  Overspeed<br>-p3-  -p3- status<br>t3 >  t3 >  t3 >  Warning<br>-p2-  -p2-  -p2  status<br>t4, t5 >  t4, t5 >  t4, t5 >  t4, t5 >  Intervention<br>-p1-  -p1-  -p1-  -p1-  status<br><!-- End of picture text -->

**Table 7: Transitions between supervision statuses in ceiling speed monitoring**

3.13.10.3.5 When the speed and distance monitoring function becomes active and the ceiling speed monitoring is the first one entered, the triggering condition t1 defined in Table 5 shall be checked in order to determine whether the Normal status applies. If it is not the case, the

<!-- end of page 162 -->

on-board shall immediately set the supervision status to the relevant value, applying a transition from the Normal status according to Table 7.

3.13.10.3.6 The Indication status is not used in ceiling speed monitoring. However, in case the ceiling speed monitoring is entered and the supervision status was previously set to Indication, the on-board equipment shall immediately execute one of the transitions from the Indication status, as described in Table 7.

3.13.10.3.7 In ceiling speed monitoring, only the ceiling supervision limits (described in section 3.13.9.2) are used to determine the commands to the Train Interface and the supervision statuses displayed to the driver. However the braking to target supervision limits and the release speed supervision limits (described in sections 3.13.9.3 and 3.13.9.3.6.5) are also used to determine the locations where the transition to target speed monitoring and to release speed monitoring occur respectively.

3.13.10.3.8 The on-board equipment shall display to the driver the first Indication location that will be reached either by the max safe or by the estimated train front end. To that effect, the onboard shall compute the remaining distance to the first Indication location as follows:

If 𝑉𝑒𝑠𝑡 < 𝑉𝑟𝑒𝑙𝑒𝑎𝑠𝑒

Ind distance =

min {([𝑑(𝑑𝐼(𝑉𝑆𝐵𝐼1𝑒𝑠𝑡(𝑉)]𝑇𝑎𝑟𝑔𝑒𝑡−1𝑟𝑒𝑙𝑒𝑎𝑠𝑒) −𝑑 −𝑑𝑒𝑠𝑡𝑓𝑟𝑜𝑛𝑡𝑚𝑎𝑥𝑠𝑎𝑓𝑒𝑓𝑟𝑜𝑛𝑡), ([𝑑), … , ([𝑑𝑆𝐵𝐼2(𝑉𝑟𝑒𝑙𝑒𝑎𝑠𝑒𝐼(𝑉𝑒𝑠𝑡)])]𝑀𝑅𝐸𝐵𝐷𝑇𝑇𝑎𝑟𝑔𝑒𝑡−𝑚−𝑑−𝑑𝑚𝑎𝑥𝑠𝑎𝑓𝑒𝑓𝑟𝑜𝑛𝑡𝑚𝑎𝑥𝑠𝑎𝑓𝑒𝑓𝑟𝑜𝑛𝑡), )<sup>}</sup>

With [𝑑𝑆𝐵𝐼2(𝑉𝑟𝑒𝑙𝑒𝑎𝑠𝑒)]𝑀𝑅𝐸𝐵𝐷𝑇 as defined in 3.13.9.4.7

And with Target_1, ..., Target_m being EBD based targets whose speed value is below V_MRSP and is below the estimated speed, excluding the SvL and any other targets between the Trip location related to the EOA and the SvL

If 𝑉𝑒𝑠𝑡 ≥𝑉𝑟𝑒𝑙𝑒𝑎𝑠𝑒

Ind distance =

min {([𝑑𝐼(𝑉𝑒𝑠𝑡([𝑑)]𝑇𝑎𝑟𝑔𝑒𝑡−1𝐼(𝑉𝑒𝑠𝑡)] −𝑑𝐸𝑂𝐴 𝑚𝑎𝑥𝑠𝑎𝑓𝑒𝑓𝑟𝑜𝑛𝑡−𝑑𝑒𝑠𝑡𝑓𝑟𝑜𝑛𝑡), ([𝑑), … , ([𝑑𝐼(𝑉𝑒𝑠𝑡𝐼(𝑉)]𝑒𝑠𝑡𝑆𝑣𝐿)]−𝑑𝑇𝑎𝑟𝑔𝑒𝑡−𝑛𝑚𝑎𝑥𝑠𝑎𝑓𝑒𝑓𝑟𝑜𝑛𝑡−𝑑𝑚𝑎𝑥𝑠𝑎𝑓𝑒𝑓𝑟𝑜𝑛𝑡), )<sup>}</sup>

With Target_1, ..., Target_n being EBD based targets whose speed value is below V_MRSP and is below the estimated speed, excluding the SvL

3.13.10.3.8.1 In case no release speed exists, the same formulas shall be applied, by substituting V_release with the value 0.

3.13.10.3.8.2 Exception: In case the list of supervised targets is empty or in case of LOA with no EBD based target whose speed value is below V_MRSP and with no EBD based target whose speed value is below the estimated speed, the ERTMS/ETCS on-board equipment shall not display any first Indication location information.

3.13.10.3.9 If A_MAXREDADH (see 3.13.6.2.1.6) requests the target information as supplementary DMI information, the on-board equipment shall display to the driver the target information

<!-- end of page 163 -->

(target speed and distance to target) related to one target at a time: the Most Relevant Displayed Target (MRDT). The MRDT shall be selected amongst the supervised targets as the one which determines the remaining distance to the first Indication location (as specified in 3.13.10.3.8 and 3.13.10.3.8.1). The indicated distance to the target shall be computed in the same way as for target speed monitoring, i.e. clauses 3.13.10.4.7, 3.13.10.4.8 and 3.13.10.4.8.1 shall apply.

3.13.10.3.9.1 Exception: In case the list of supervised targets is empty or in case of LOA with no EBD based target whose speed value is below V_MRSP and with no EBD based target whose speed value is below the estimated speed, the ERTMS/ETCS on-board equipment shall not display any target information.

3.13.10.3.10 If A_MAXREDADH (see 3.13.6.2.1.6) requests a time to Indication as supplementary DMI information, the on-board equipment shall compute the Time to Indication (TTI) as the time to travel at the estimated speed the remaining distance to the first Indication location (as specified in 3.13.10.3.8 and 3.13.10.3.8.1). The on-board equipment shall inform the driver as long as this time is shorter than a fixed value (refer to A.3.1).

3.13.10.3.10.1 Exception: In case the list of supervised targets is empty or in case of LOA with no EBD based target whose speed value is below V_MRSP and with no EBD based target whose speed value is below the estimated speed, the ERTMS/ETCS on-board equipment shall not compute any time to Indication.

#### **3.13.10.4 Requirements for Target speed monitoring**

3.13.10.4.1 In target speed monitoring, both the ceiling supervision limits and the braking to target supervision limits, described in sections 3.13.9.2 and 3.13.9.3, are used to determine the commands to the Train Interface and the supervision statuses displayed to the driver.

3.13.10.4.2 The on-board equipment shall display to the driver the target information (target speed and distance to target) related to one target at a time: the Most Relevant Displayed Target (MRDT). The MRDT shall be selected amongst the supervised targets whose Indication supervision limit is exceeded (i.e. a condition to trigger a supervision status with respect to these targets is met, see table 8 and table 9) and shall be determined according to the following steps:

   - Step 0: MRDT0 = the target of which the braking to target Permitted speed supervision limit (refer to section 3.13.9.3.5), calculated for the current position of the train, is the lowest one amongst the concerned targets:

[𝑉𝑃(𝑑𝑒𝑠𝑡𝑓𝑟𝑜𝑛𝑡)]𝐸𝑂𝐴<sup>, [𝑉𝑃(𝑑𝑚𝑎𝑥𝑠𝑎𝑓𝑒𝑓𝑟𝑜𝑛𝑡)]</sup> 𝑆𝑣𝐿<sup>,</sup> [𝑉𝑃]𝑀𝑅𝐷𝑇0 = min {[𝑉𝑃(𝑑𝑚𝑎𝑥𝑠𝑎𝑓𝑒𝑓𝑟𝑜𝑛𝑡)]𝑇𝑎𝑟𝑔𝑒𝑡−1<sup>, … , [𝑉𝑃(𝑑𝑚𝑎𝑥𝑠𝑎𝑓𝑒𝑓𝑟𝑜𝑛𝑡)]</sup> 𝑇𝑎𝑟𝑔𝑒𝑡−𝑛} with [𝑉𝑃(𝑑𝑒𝑠𝑡𝑓𝑟𝑜𝑛𝑡)]𝐸𝑂𝐴<sup>taken into account only if𝑑𝑒𝑠𝑡𝑓𝑟𝑜𝑛𝑡> [𝑑𝐼(𝑉𝑒𝑠𝑡)]𝐸𝑂𝐴</sup> with [𝑉𝑃(𝑑𝑚𝑎𝑥𝑠𝑎𝑓𝑒𝑓𝑟𝑜𝑛𝑡)]𝑆𝑣𝐿<sup>taken into account only if𝑑𝑚𝑎𝑥𝑠𝑎𝑓𝑒𝑓𝑟𝑜𝑛𝑡> [𝑑𝐼(𝑉𝑒𝑠𝑡)]𝑆𝑣𝐿</sup> with [𝑉𝑃(𝑑𝑚𝑎𝑥𝑠𝑎𝑓𝑒𝑓𝑟𝑜𝑛𝑡)]𝑇𝑎𝑟𝑔𝑒𝑡−1<sup>taken into account only if𝑑𝑚𝑎𝑥𝑠𝑎𝑓𝑒𝑓𝑟𝑜𝑛𝑡> [𝑑𝐼(𝑉𝑒𝑠𝑡)]𝑇𝑎𝑟𝑔𝑒𝑡−1,</sup> 𝑉𝑀𝑅𝑆𝑃 > 𝑉𝑡𝑎𝑟𝑔𝑒𝑡−1 and 𝑉𝑒𝑠𝑡 ≥𝑉𝑡𝑎𝑟𝑔𝑒𝑡−1

<!-- end of page 164 -->

with [𝑉𝑃(𝑑𝑚𝑎𝑥𝑠𝑎𝑓𝑒𝑓𝑟𝑜𝑛𝑡)]𝑇𝑎𝑟𝑔𝑒𝑡−𝑛<sup>taken into account only if𝑑𝑚𝑎𝑥𝑠𝑎𝑓𝑒𝑓𝑟𝑜𝑛𝑡> [𝑑𝐼(𝑉𝑒𝑠𝑡)]𝑇𝑎𝑟𝑔𝑒𝑡−𝑛,</sup> 𝑉𝑀𝑅𝑆𝑃 > 𝑉𝑡𝑎𝑟𝑔𝑒𝑡−𝑛 and 𝑉𝑒𝑠𝑡 ≥𝑉𝑡𝑎𝑟𝑔𝑒𝑡−𝑛

- Step 1: the on-board equipment shall check whether the MRDT obtained from the previous step (MRDT0) masks any other target(s) remaining in the list of concerned targets, whose target speed is lower than MRDT0. A target is masked by MRDT0 if its Indication supervision limit is located in rear of the location of the MRDT0 Permitted speed supervision limit, both at the target speed of MRDT0. It shall be identified using one of the following formulas, where both the Indication supervision limit and the Permitted speed supervision limit are calculated using the same formulas defined above and by substituting V_est with V_target_MRDT0:

<!-- Start of picture text -->
or<br>[𝑑𝐼 (𝑉𝑡𝑎𝑟𝑔𝑒𝑡𝑀𝑅𝐷𝑇0)]𝐸𝑂𝐴 < [𝑑𝑃 (𝑉𝑡𝑎𝑟𝑔𝑒𝑡𝑀𝑅𝐷𝑇0)]𝑀𝑅𝐷𝑇0  or  [𝑑𝐼 (𝑉𝑡𝑎𝑟𝑔𝑒𝑡𝑀𝑅𝐷𝑇0)]𝑆𝑣𝐿 < [𝑑𝑃 (𝑉𝑡𝑎𝑟𝑔𝑒𝑡𝑀𝑅𝐷𝑇0)]𝑀𝑅𝐷𝑇0<br>or ... or<br>[𝑑𝐼 (𝑉𝑡𝑎𝑟𝑔𝑒𝑡𝑀𝑅𝐷𝑇0)] < [𝑑𝑃 (𝑉𝑡𝑎𝑟𝑔𝑒𝑡𝑀𝑅𝐷𝑇0)]<br>𝑇𝑎𝑟𝑔𝑒𝑡−1 𝑀𝑅𝐷𝑇0<br>[𝑑𝐼 (𝑉𝑡𝑎𝑟𝑔𝑒𝑡𝑀𝑅𝐷𝑇0)] < [𝑑𝑃 (𝑉𝑡𝑎𝑟𝑔𝑒𝑡𝑀𝑅𝐷𝑇0)]<br>𝑇𝑎𝑟𝑔𝑒𝑡−𝑛 𝑀𝑅𝐷𝑇0<br><!-- End of picture text -->

If at least one target is masked by MRDT0, then the MRDT obtained from this step (MRDT1) shall be the masked target with its Indication supervision limit the furthest in rear of the location of the MRDT0 Permitted speed supervision limit and the on-board equipment shall go to the next step.

If none of the remaining targets from the list of concerned targets is masked by MRDT0 or if there is no other remaining target to check in the list of concerned targets, then the MRDT shall be the target obtained from the previous step (i.e. MRDT0).

   - Step n: the on-board shall apply step n-1, substituting MRDTn-2 with MRDTn-1 and checking the list of concerned targets excluding the targets which have been preselected as MRDT in all the previous steps (i.e. from MRDT0 to MRDTn-1 inclusive).

3.13.10.4.2.1 Note 1: the above process for the determination of the MRDT ensures that when several targets are close to each other it is avoided that a target is displayed after its Indication supervision limit has been reached.

3.13.10.4.2.2 Note 2: when entering target speed monitoring, there is by definition at least one target that satisfies the conditions to be selected as MRDT. Afterwards (e.g. due to train braking) it is possible that no target satisfies any more the conditions to be selected as MRDT, which however only means that the target previously selected remains the MRDT (see clause 3.13.10.4.5).

3.13.10.4.2.3 Note 3: if MRDTn-1 is a target at zero speed (e.g. EOA or SvL), then it is always selected as MRDT, i.e. no other target can be selected as MRDT as per step n.

<!-- end of page 165 -->

3.13.10.4.3 The on-board equipment shall display the Permitted speed, according to following formula:

With Target_1, ..., Target_n being all the targets from the list of supervised targets

3.13.10.4.4 When the supervision status is Overspeed, Warning or Intervention, the on-board equipment shall display the SBI speed, according to the following formula:

3.13.10.4.5 Once a target is the MRDT, it shall remain the MRDT until it is removed from the list of supervised targets or until it is replaced as MRDT with another target that has a target speed lower than or equal to the current MRDT and which is selected according to clause 3.13.10.4.2. The driver shall be informed upon any change of MRDT.

3.13.10.4.6 If the MRDT is either the EOA or the SvL, the on-board equipment shall display the release speed, if given by the trackside or calculated on-board.

3.13.10.4.7 If the MRDT is neither the EOA nor the SvL, the indicated distance to the target shall be the distance between the maximum safe front end and the location of the Permitted speed supervision limit calculated for the target speed (see section 3.13.9.3.5 for the calculation of this location), but limited to zero after this location is passed.

[target distance]𝐷𝑀𝐼 = 𝑚𝑎𝑥{(𝑑𝑃(𝑉𝑡𝑎𝑟𝑔𝑒𝑡) −𝑑𝑚𝑎𝑥𝑠𝑎𝑓𝑒𝑓𝑟𝑜𝑛𝑡), 0}

3.13.10.4.7.1 Intentionally deleted.

3.13.10.4.8 If the MRDT is either the EOA or the SvL, the indicated distance to the target shall be calculated as follows:

- [target distance]𝐷𝑀𝐼 = 𝑚𝑎𝑥{𝑚𝑖𝑛{(𝑑𝐸𝑂𝐴 −𝑑𝑒𝑠𝑡𝑓𝑟𝑜𝑛𝑡), (𝑑𝑆𝑣𝐿 −𝑑𝑚𝑎𝑥𝑠𝑎𝑓𝑒𝑓𝑟𝑜𝑛𝑡)}, 0}

3.13.10.4.8.1 As long as the displayed values are locked due to SB feedback (see Appendix A.3.10 for details) or are not allowed to increase (see Appendix A.3.13 for details), the on-board equipment shall ensure that the displayed Permitted speed, the displayed SBI speed (if any) and the distance to target (in case of service brake feedback) never increase (e.g. due to the reduction of T_bs1 and T_bs2 or e.g. due to relocation). In other terms if a concerned displayed value (VP_DMI, VSBI_DMI or target distance) calculated as above has a higher value than the previously displayed value, then the previous value shall remain displayed until a further calculated value is lower than the displayed one.

3.13.10.4.9 The on-board shall consider the service brake command as available for use unless:

   - a) The service brake command is not implemented, OR

b) The national value inhibits its use.

<!-- end of page 166 -->

3.13.10.4.10 The on-board equipment shall compare the estimated speed and train position with the ceiling and braking to target supervision limits and shall trigger/revoke commands to the train interface (traction cut-off if implemented, service brake if available for use or emergency brake) and supervision statuses, by evaluating and taking into account the conditions as specified in clause 3.13.10.4.10.1.

3.13.10.4.10.1 The conditions in Table 8 and Table 10 shall be evaluated for each target, if lower than V_MRSP, related to an MRSP element or LOA, the conditions in Table 9 and Table 11 shall be evaluated for the targets EOA and SvL and for the end of the maximum permitted distance to run in Staff Responsible.

|Triggering<br>condition<br>#|Estimated speed|Train front end position (max safe)|TI<br>Command<br>triggered|Supervisi<br>on status<br>triggered|
|---|---|---|---|---|
|t3|𝑉𝑡𝑎𝑟𝑔𝑒𝑡< 𝑉𝑒𝑠𝑡≤𝑉𝑀𝑅𝑆𝑃|𝑑𝐼(𝑉𝑒𝑠𝑡) < 𝑑𝑚𝑎𝑥𝑠𝑎𝑓𝑒𝑓𝑟𝑜𝑛𝑡≤𝑑𝑃(𝑉𝑒𝑠𝑡)|-|Indication<br>Status|
|t4||𝑑𝑚𝑎𝑥𝑠𝑎𝑓𝑒𝑓𝑟𝑜𝑛𝑡> 𝑑𝑃(𝑉𝑒𝑠𝑡)|-|Overspeed<br>Status|
|t6|𝑉𝑀𝑅𝑆𝑃<br>< 𝑉𝑒𝑠𝑡≤<br>𝑉𝑀𝑅𝑆𝑃+ 𝑑𝑉𝑤𝑎𝑟𝑛𝑖𝑛𝑔(𝑉𝑀𝑅𝑆𝑃)|𝑑𝑚𝑎𝑥𝑠𝑎𝑓𝑒𝑓𝑟𝑜𝑛𝑡≤𝑑𝑊(𝑉𝑒𝑠𝑡)|-|Overspeed<br>Status|
|t7|𝑉𝑡𝑎𝑟𝑔𝑒𝑡+ 𝑑𝑉𝑤𝑎𝑟𝑛𝑖𝑛𝑔(𝑉𝑡𝑎𝑟𝑔𝑒𝑡)<br>< 𝑉𝑒𝑠𝑡≤<br>𝑉𝑀𝑅𝑆𝑃+ 𝑑𝑉𝑤𝑎𝑟𝑛𝑖𝑛𝑔(𝑉𝑀𝑅𝑆𝑃)|𝑑𝑚𝑎𝑥𝑠𝑎𝑓𝑒𝑓𝑟𝑜𝑛𝑡> 𝑑𝑊(𝑉𝑒𝑠𝑡)|TCO|Warning<br>Status|
|t9|𝑉𝑀𝑅𝑆𝑃+ 𝑑𝑉𝑤𝑎𝑟𝑛𝑖𝑛𝑔(𝑉𝑀𝑅𝑆𝑃)<br>< 𝑉𝑒𝑠𝑡≤<br>𝑉𝑀𝑅𝑆𝑃+ 𝑑𝑉𝑠𝑏𝑖(𝑉𝑀𝑅𝑆𝑃)|𝑑𝑚𝑎𝑥𝑠𝑎𝑓𝑒𝑓𝑟𝑜𝑛𝑡≤𝑑𝑆𝐵𝐼2(𝑉𝑒𝑠𝑡)|TCO|Warning<br>Status|
|t10|𝑉𝑡𝑎𝑟𝑔𝑒𝑡+ 𝑑𝑉𝑠𝑏𝑖(𝑉𝑡𝑎𝑟𝑔𝑒𝑡)<br>< 𝑉𝑒𝑠𝑡≤<br>𝑉𝑀𝑅𝑆𝑃+ 𝑑𝑉𝑠𝑏𝑖(𝑉𝑀𝑅𝑆𝑃)|𝑑𝑚𝑎𝑥𝑠𝑎𝑓𝑒𝑓𝑟𝑜𝑛𝑡> 𝑑𝑆𝐵𝐼2(𝑉𝑒𝑠𝑡)|SB|Intervention<br>Status|
|t12|𝑉𝑀𝑅𝑆𝑃+ 𝑑𝑉𝑠𝑏𝑖(𝑉𝑀𝑅𝑆𝑃)<br>< 𝑉𝑒𝑠𝑡≤<br>𝑉𝑀𝑅𝑆𝑃+ 𝑑𝑉𝑒𝑏𝑖(𝑉𝑀𝑅𝑆𝑃)|𝑑𝑚𝑎𝑥𝑠𝑎𝑓𝑒𝑓𝑟𝑜𝑛𝑡≤𝑑𝐸𝐵𝐼(𝑉𝑒𝑠𝑡)|SB|Intervention<br>Status|
|t13|𝑉𝑡𝑎𝑟𝑔𝑒𝑡+ 𝑑𝑉𝑒𝑏𝑖(𝑉𝑡𝑎𝑟𝑔𝑒𝑡)<br>< 𝑉𝑒𝑠𝑡≤<br>𝑉𝑀𝑅𝑆𝑃+ 𝑑𝑉𝑒𝑏𝑖(𝑉𝑀𝑅𝑆𝑃)|𝑑𝑚𝑎𝑥𝑠𝑎𝑓𝑒𝑓𝑟𝑜𝑛𝑡> 𝑑𝐸𝐵𝐼(𝑉𝑒𝑠𝑡)|EB|Intervention<br>Status|
|t15|𝑉𝑒𝑠𝑡> 𝑉𝑀𝑅𝑆𝑃+ 𝑑𝑉𝑒𝑏𝑖(𝑉𝑀𝑅𝑆𝑃)|<sup>Not relevant</sup>|EB|Intervention<br>Status|

#### **Table 8: Triggering of Train Interface commands and supervision statuses in target speed monitoring, MRSP target or LOA**

<!-- end of page 167 -->

<!-- Start of picture text -->
speed<br>EBD<br>VMRSP+dVebi<br>15<br>EBI<br>12<br>SBI<br>9<br>W<br>VMRSP<br>6<br>P<br>I  13<br>10<br>3<br>7<br>4<br>?<br>Vest<br>use of reduced  EBI<br>brake build up<br>SBI<br>times<br>P  W<br>I<br>Vtarget<br>dest dmaxsafe dtarget distance<br><!-- End of picture text -->

**Figure 54: Triggering of Train Interface commands and supervision statuses in target speed monitoring, MRSP target or LOA (number in circle corresponds with the equivalent triggering condition in Table 8)**

<!-- end of page 168 -->

|Triggering<br>condition<br>#|Estimated speed|Train front end position (estimated and max safe)|TI<br>Command<br>triggered|Supervisi<br>on status<br>triggered|
|---|---|---|---|---|
|t0|𝑉𝑒𝑠𝑡= 𝑉𝑟𝑒𝑙𝑒𝑎𝑠𝑒|(𝑑𝑚𝑎𝑥𝑠𝑎𝑓𝑒𝑓𝑟𝑜𝑛𝑡> 𝑑𝐼(𝑉𝑒𝑠𝑡)for SvL<br>OR𝑑𝑒𝑠𝑡𝑓𝑟𝑜𝑛𝑡> 𝑑𝐼(𝑉𝑒𝑠𝑡)for EOA)|-|Indication<br>Status|
|t1||(𝑑𝑚𝑎𝑥𝑠𝑎𝑓𝑒𝑓𝑟𝑜𝑛𝑡> 𝑑𝑃(𝑉𝑒𝑠𝑡)for SvL<br>OR𝑑𝑒𝑠𝑡𝑓𝑟𝑜𝑛𝑡> 𝑑𝑃(𝑉𝑒𝑠𝑡)for EOA)|-|Overspeed<br>Status|
|t2||(𝑑𝑚𝑎𝑥𝑠𝑎𝑓𝑒𝑓𝑟𝑜𝑛𝑡> 𝑑𝑊(𝑉𝑒𝑠𝑡)for SvL<br>OR𝑑𝑒𝑠𝑡𝑓𝑟𝑜𝑛𝑡> 𝑑𝑊(𝑉𝑒𝑠𝑡)for EOA)|TCO|Warning<br>Status|
|t3|𝑉𝑟𝑒𝑙𝑒𝑎𝑠𝑒< 𝑉𝑒𝑠𝑡≤𝑉𝑀𝑅𝑆𝑃|(𝑑𝑚𝑎𝑥𝑠𝑎𝑓𝑒𝑓𝑟𝑜𝑛𝑡> 𝑑𝐼(𝑉𝑒𝑠𝑡)for SvL<br>OR𝑑𝑒𝑠𝑡𝑓𝑟𝑜𝑛𝑡> 𝑑𝐼(𝑉𝑒𝑠𝑡)for EOA)<br>AND<br>(𝑑𝑚𝑎𝑥𝑠𝑎𝑓𝑒𝑓𝑟𝑜𝑛𝑡≤𝑑𝑃(𝑉𝑒𝑠𝑡) for SvL<br>AND𝑑𝑒𝑠𝑡𝑓𝑟𝑜𝑛𝑡≤𝑑𝑃(𝑉𝑒𝑠𝑡)for EOA)|-|Indication<br>Status|
|t4||𝑑𝑚𝑎𝑥𝑠𝑎𝑓𝑒𝑓𝑟𝑜𝑛𝑡> 𝑑𝑃(𝑉𝑒𝑠𝑡)for SvL<br>OR𝑑𝑒𝑠𝑡𝑓𝑟𝑜𝑛𝑡> 𝑑𝑃(𝑉𝑒𝑠𝑡)for EOA|-|Overspeed<br>Status|
|t6|𝑉𝑀𝑅𝑆𝑃<br>< 𝑉𝑒𝑠𝑡≤<br>𝑉𝑀𝑅𝑆𝑃+ 𝑑𝑉𝑤𝑎𝑟𝑛𝑖𝑛𝑔(𝑉𝑀𝑅𝑆𝑃)|(𝑑𝑚𝑎𝑥𝑠𝑎𝑓𝑒𝑓𝑟𝑜𝑛𝑡≤𝑑𝑊(𝑉𝑒𝑠𝑡) for SvL<br>AND𝑑𝑒𝑠𝑡𝑓𝑟𝑜𝑛𝑡≤𝑑𝑊(𝑉𝑒𝑠𝑡)for EOA)|-|Overspeed<br>Status|
|t7|𝑉𝑟𝑒𝑙𝑒𝑎𝑠𝑒<br>< 𝑉𝑒𝑠𝑡≤<br>𝑉𝑀𝑅𝑆𝑃+ 𝑑𝑉𝑤𝑎𝑟𝑛𝑖𝑛𝑔(𝑉𝑀𝑅𝑆𝑃)|𝑑𝑚𝑎𝑥𝑠𝑎𝑓𝑒𝑓𝑟𝑜𝑛𝑡> 𝑑𝑊(𝑉𝑒𝑠𝑡)for SvL<br>OR𝑑𝑒𝑠𝑡𝑓𝑟𝑜𝑛𝑡> 𝑑𝑊(𝑉𝑒𝑠𝑡)for EOA|TCO|Warning<br>Status|
|t9|𝑉𝑀𝑅𝑆𝑃+ 𝑑𝑉𝑤𝑎𝑟𝑛𝑖𝑛𝑔(𝑉𝑀𝑅𝑆𝑃)<br>< 𝑉𝑒𝑠𝑡≤<br>𝑉𝑀𝑅𝑆𝑃+ 𝑑𝑉𝑠𝑏𝑖(𝑉𝑀𝑅𝑆𝑃)|(𝑑𝑚𝑎𝑥𝑠𝑎𝑓𝑒𝑓𝑟𝑜𝑛𝑡≤𝑑𝑆𝐵𝐼2(𝑉𝑒𝑠𝑡) for SvL<br>AND𝑑𝑒𝑠𝑡𝑓𝑟𝑜𝑛𝑡≤𝑑𝑆𝐵𝐼1(𝑉𝑒𝑠𝑡)for EOA)|TCO|Warning<br>Status|
|t10|𝑉𝑟𝑒𝑙𝑒𝑎𝑠𝑒<br>< 𝑉𝑒𝑠𝑡≤<br>𝑉𝑀𝑅𝑆𝑃+ 𝑑𝑉𝑠𝑏𝑖(𝑉𝑀𝑅𝑆𝑃)|𝑑𝑚𝑎𝑥𝑠𝑎𝑓𝑒𝑓𝑟𝑜𝑛𝑡> 𝑑𝑆𝐵𝐼2(𝑉𝑒𝑠𝑡)for SvL<br>OR𝑑𝑒𝑠𝑡𝑓𝑟𝑜𝑛𝑡> 𝑑𝑆𝐵𝐼1(𝑉𝑒𝑠𝑡)for EOA|SB|Intervention<br>Status|
|t12|𝑉𝑀𝑅𝑆𝑃+ 𝑑𝑉𝑠𝑏𝑖(𝑉𝑀𝑅𝑆𝑃)<br>< 𝑉𝑒𝑠𝑡≤<br>𝑉𝑀𝑅𝑆𝑃+ 𝑑𝑉𝑒𝑏𝑖(𝑉𝑀𝑅𝑆𝑃)|𝑑𝑚𝑎𝑥𝑠𝑎𝑓𝑒𝑓𝑟𝑜𝑛𝑡≤𝑑𝐸𝐵𝐼(𝑉𝑒𝑠𝑡)|SB|Intervention<br>Status|
|t13|𝑉𝑟𝑒𝑙𝑒𝑎𝑠𝑒<br>< 𝑉𝑒𝑠𝑡≤<br>𝑉𝑀𝑅𝑆𝑃+ 𝑑𝑉𝑒𝑏𝑖(𝑉𝑀𝑅𝑆𝑃)|𝑑𝑚𝑎𝑥𝑠𝑎𝑓𝑒𝑓𝑟𝑜𝑛𝑡> 𝑑𝐸𝐵𝐼(𝑉𝑒𝑠𝑡)|EB|Intervention<br>Status|

<!-- end of page 169 -->

|Triggering<br>condition<br>#|Estimated speed|Train front end position (estimated and max safe)|TI<br>Command<br>triggered|Supervisi<br>on status<br>triggered|
|---|---|---|---|---|
|t15|𝑉𝑒𝑠𝑡> 𝑉𝑀𝑅𝑆𝑃+ 𝑑𝑉𝑒𝑏𝑖(𝑉𝑀𝑅𝑆𝑃)|<sup>Not relevant</sup>|EB|Intervention<br>Status|

#### **Table 9: Triggering of Train Interface commands and supervision statuses in target speed monitoring, EOA/SvL with release speed**

<!-- Start of picture text -->
speed  SBD  EBD<br>VMRSP+dVebi<br>EBI  15<br>SBI  12<br>W  9<br>13<br>P  6  EBI<br>10<br>I<br>SBI2<br>7 SBI1<br>3<br>4<br>?<br>Vest<br>Vrelease<br>0  1  2<br>I<br>distance<br>dest dmaxsafe start  EOA  SvL<br>RSM<br><!-- End of picture text -->

#### **Figure 55: Triggering of Train Interface commands and supervision statuses in target speed monitoring, EOA/SvL with release speed (number in circle corresponds with equivalent triggering condition in Table 9)**

<!-- end of page 170 -->

|Revoc<br>ation<br>conditi<br>on #|Estimated speed|Train front end position (max safe)|TI Command<br>revoked|Supervision<br>status revoked|
|---|---|---|---|---|
|r0||Standstill|EB|Intervention status|
|r1|𝑉𝑒𝑠𝑡≤𝑉𝑡𝑎𝑟𝑔𝑒𝑡|Not relevant|TCO<br>SB<br>EB (in case<br>V_target ≠ 0, only if<br>allowed by National<br>Value)|Overspeed status<br>Warning status<br>Intervention status<br>(in case of EB<br>command and<br>V_target ≠ 0, only if<br>allowed by National<br>Value)|
|r3|𝑉𝑡𝑎𝑟𝑔𝑒𝑡< 𝑉𝑒𝑠𝑡≤𝑉𝑀𝑅𝑆𝑃|𝑑𝑚𝑎𝑥𝑠𝑎𝑓𝑒𝑓𝑟𝑜𝑛𝑡≤𝑑𝑃(𝑉𝑒𝑠𝑡)|TCO<br>SB<br>EB (only if allowed<br>by National Value)|Overspeed status<br>Warning status<br>Intervention status<br>(in case of EB<br>command, only if<br>allowed by National<br>Value)|

#### **Table 10: Revocation of Train Interface commands and supervision statuses in target speed monitoring, MRSP target or LOA**

|Revoc<br>ation<br>conditi<br>on #|Estimated speed|Train front end position (estimated and max<br>safe)|TI Command<br>revoked|Supervision<br>status revoked|
|---|---|---|---|---|
|r0||Standstill|EB|Intervention status|
|r1|𝑉𝑒𝑠𝑡≤𝑉𝑟𝑒𝑙𝑒𝑎𝑠𝑒|Not relevant|TCO<br>SB<br>EB (in case<br>V_release ≠ 0, only<br>if allowed by<br>National Value)|Overspeed status<br>Warning status<br>Intervention status<br>(in case of EB<br>command and<br>V_release ≠ 0, only<br>if allowed by<br>National Value)|
|r3|𝑉𝑟𝑒𝑙𝑒𝑎𝑠𝑒< 𝑉𝑒𝑠𝑡≤𝑉𝑀𝑅𝑆𝑃|𝑑𝑚𝑎𝑥𝑠𝑎𝑓𝑒𝑓𝑟𝑜𝑛𝑡≤𝑑𝑃(𝑉𝑒𝑠𝑡) for SvL<br>AND𝑑𝑒𝑠𝑡𝑓𝑟𝑜𝑛𝑡≤𝑑𝑃(𝑉𝑒𝑠𝑡)for EOA|TCO<br>SB<br>EB (only if allowed<br>by National Value)|Overspeed status<br>Warning status<br>Intervention status<br>(in case of EB<br>command, only if<br>allowed by National<br>Value)|

#### **Table 11: Revocation of Train Interface commands and supervision statuses in target speed monitoring, EOA/SvL with release speed**

3.13.10.4.11 Note: For clarity reasons, the Figures 54 and 55 show the train speed/position in a region where the target speed monitoring may not have been entered yet, further to the crossing of an Indication supervision limit.

<!-- end of page 171 -->

3.13.10.4.12 Note: Figure 55 shows the parts of the ceiling speed and braking to target supervision limits, which are used in target speed monitoring to trigger the brake commands and the transitions between supervision statuses. It does not show what is displayed to the driver: in particular, the braking to target Permitted supervision limit is displayed (even if not supervised) for values lower than the release speed.

3.13.10.4.13 In case of target EOA/SvL with a release speed higher than or equal to V_MRSP or without any supervised release speed, the Table 9 and Table 11 shall be applied, by substituting V_release with the value 0.

3.13.10.4.13.1 In case the target is the location at the end of the maximum permitted distance to run in Staff Responsible, the Table 9 and Table 11 shall be applied, by substituting V_release with the value 0, SvL with staff responsible end location and by ignoring any formula related to EOA.

3.13.10.4.14 A TI command shall be triggered if a corresponding triggering condition is met for at least one target. On the other hand it shall be revoked only if a corresponding revocation condition is met for each supervised target.

3.13.10.4.15 The on-board equipment shall execute the transitions between the different supervision statuses as described in Table 12 (see section 4.6.1 for details about the symbols). A triggering condition shall be taken into account as soon as it is satisfied for any target. On the other hand a transition from Overspeed, Warning or Intervention status to the Indication status shall be made only if a revocation condition specified for the concerned transition is met for each supervised target.

<!-- Start of picture text -->
Normal<br>status<br>t0, t3 >  Indication  < r1, r3  < r1, r3  < r0, r1, r3<br>-p4-  status  -p1-  -p1-  -p1-<br>t1, t4, t6 >  t1, t4, t6 >  Overspeed<br>-p3-  -p3-  status<br>t2, t7, t9 >  t2, t7, t9 >  t2, t7, t9 >  Warning<br>-p2-  -p2-  -p2-  status<br>t10, t12, t13,  t10, t12, t13,  t10, t12, t13,  t10, t12, t13,<br>t15 >  t15 >  t15 >  t15 >  Intervention<br>status<br>-p1-  -p1-  -p1-  -p1-<br><!-- End of picture text -->

**Table 12: Transitions between supervision statuses in target speed monitoring**

<!-- end of page 172 -->

3.13.10.4.16 When the speed and distance monitoring function becomes active and the target speed monitoring is the first one entered, the triggering condition t3 defined in Table 8 or Table 9 shall be checked for each target in order to determine whether the Indication status applies. If it is not the case, the on-board shall immediately set the supervision status to the relevant value, applying a transition from the Indication status according to clause 3.13.10.4.15.

3.13.10.4.17 The Normal status is not used in target speed monitoring. However, in case the target speed monitoring is entered and the supervision status was previously set to Normal, the on-board equipment shall immediately execute one of the transitions from the Normal status, as specified in clause 3.13.10.4.15.

3.13.10.4.18 Note: Depending upon train speed/position it is possible that for some target(s) none of the triggering conditions specified in table 8 and 9 is met. However the conditions to enter the target speed monitoring are such (see condition [1] in table 16) that the clauses 3.13.10.4.16 and 3.13.10.4.17 always allow determining a supervision status.

#### **3.13.10.5 Requirements for release speed monitoring**

3.13.10.5.1 The on-board equipment shall display the Release speed.

3.13.10.5.2 The on-board equipment shall display the target distance according to the following formula:

- [target distance]𝐷𝑀𝐼 = 𝑚𝑎𝑥{𝑚𝑖𝑛{(𝑑𝐸𝑂𝐴 −𝑑𝑒𝑠𝑡𝑓𝑟𝑜𝑛𝑡), (𝑑𝑆𝑣𝐿 −𝑑𝑚𝑎𝑥𝑠𝑎𝑓𝑒𝑓𝑟𝑜𝑛𝑡)}, 0}

3.13.10.5.3 The braking to target Permitted speed supervision limit related to either the EOA or the SvL shall also be displayed according to the following formula:

[𝑉𝑃]𝐷𝑀𝐼 = min {[𝑉𝑃(𝑑𝑒𝑠𝑡𝑓𝑟𝑜𝑛𝑡)]𝐸𝑂𝐴<sup>, [𝑉𝑃(𝑑𝑚𝑎𝑥𝑠𝑎𝑓𝑒𝑓𝑟𝑜𝑛𝑡)]</sup> 𝑆𝑣𝐿<sup>}</sup>

with [𝑉𝑃(𝑑𝑒𝑠𝑡𝑓𝑟𝑜𝑛𝑡)]𝐸𝑂𝐴<sup>calculated as per 3.13.9.3.5.5 or 3.13.9.3.5.6</sup>

and with [𝑉𝑃(𝑑𝑚𝑎𝑥𝑠𝑎𝑓𝑒𝑓𝑟𝑜𝑛𝑡)]𝑆𝑣𝐿<sup>calculated as per 3.13.9.3.5.7 or 3.13.9.3.5.8</sup>

3.13.10.5.3.1 The clause 3.13.10.4.8.1 shall also apply by analogy for the display of the target distance and the braking to target Permitted speed supervision limit related to the EOA/SvL.

3.13.10.5.4 The on-board equipment shall compare the estimated speed with the release speed and shall trigger/revoke commands to the train interface (emergency brake) and supervision statuses as described in Table 13 and Table 14.

<!-- end of page 173 -->

|Triggering<br>condition|Estimated speed|Location|TI<br>Command|Supervision<br>status triggered|
|---|---|---|---|---|
|#|||triggered||
|t1|𝑉𝑒𝑠𝑡≤𝑉𝑟𝑒𝑙𝑒𝑎𝑠𝑒|Any|-|Indication Status|
|t2|𝑉𝑒𝑠𝑡> 𝑉𝑟𝑒𝑙𝑒𝑎𝑠𝑒|Any|EB|Intervention Status|

#### **Table 13: Triggering of Train Interface commands and supervision statuses in release speed monitoring**

|Triggering<br>condition<br>#|Estimated speed|Location|TI<br>Command<br>revoked|Supervision<br>status revoked|
|---|---|---|---|---|
|r0|Standstill||EB|Intervention Status|
|r1|𝑉𝑒𝑠𝑡≤𝑉𝑟𝑒𝑙𝑒𝑎𝑠𝑒|Any|-|Overspeed Status<br>Warning Status|

#### **Table 14: Revocation of Train Interface commands and supervision statuses in release speed monitoring**

3.13.10.5.5 The on-board equipment shall execute the transitions between the different supervision statuses as described in Table 15 (see section 4.6.1 for details about the symbols). This table takes into account the order of precedence between the supervision statuses and the possible updates of the release speed while in release speed monitoring.

<!-- Start of picture text -->
Normal<br>status<br>t1 >  Indication  < r1  < r1  < r0<br>-p1-  status  -p1-  -p1-  -p1-<br>Overspeed<br>status<br>Warning<br>status<br>t2 >  t2 >  t2 >  t2 >  Intervention<br>-p1-  -p1-  -p1-  -p1-  status<br><!-- End of picture text -->

**Table 15: Transitions between supervision statuses in release speed monitoring**

<!-- end of page 174 -->

3.13.10.5.6 When the speed and distance monitoring function becomes active and the release speed monitoring is the first one entered, the triggering condition t1 defined in Table 13 shall be checked in order to determine whether the Indication status applies. If it is not the case, the on-board shall immediately set the supervision status to the Intervention status, applying a transition from the Indication status according to Table 15.

3.13.10.5.7 The Normal, Warning and Overspeed statuses are not used in release speed monitoring. However, in case the release speed monitoring is entered and the supervision status was previously set to Normal, Warning or Overspeed, the on-board equipment shall immediately execute one of the transitions from respectively the Normal, Warning or Overspeed status, as described in Table 15.

#### **3.13.10.6 Transitions between types of Speed and distance monitoring**

3.13.10.6.1 The transitions between the Ceiling speed monitoring, the Target speed monitoring and the Release speed monitoring shall be achieved as described in the Table 16:

|Condi<br>tion id|<br>Transition condition|CSM|TSM|RSM|
|---|---|---|---|---|
|[1]|{(The train is not at standstill) AND ((The train has passed with its<br>max safe front end the Indication location calculated from an EBD<br>whose target speed is below V_MRSP and is below the train<br>speed) OR (The train has passed with its estimated front end the<br>Indication location calculated from the SBD)) AND ((In case a<br>release speed exists, the train speed is above or equal to the<br>release speed) OR (No release speed exists))}<br>OR<br>{(A release speed exists) AND (the train speed is below the release<br>speed) AND (The train has passed with its max safe front end the<br>Indication location calculated from an EBD whose target speed is<br>below the train speed, excluding the EBD from the SvL and any<br>other targets between the Trip location related to the EOA and the<br>SvL)}|~~•~~|||
|[2]|(The train has passed with its max safe front end the RSM start<br>location if it is calculated from an EBD) OR (The train has passed<br>with its estimated front end the RSM start location if it is calculated<br>from the SBD)|~~•~~|~~•~~||
|[3]|(The MRDT is removed from the list of supervised targets) AND<br>(condition [1] is not fulfilled) AND (condition [2] is not fulfilled)||~~•~~|~~•~~|
|[4]|(The list of supervised targets is updated) AND (condition [1] is<br>fulfilled)AND(condition[2]is not fulfilled)|~~•~~||~~•~~|
|[5]|(The list of supervised targets is updated) AND (condition [2] is<br>fulfilled)|~~•~~|~~•~~||
|[6]|(V_MRSP is updated) AND (The MRDT speed is no longer below<br>V_MRSP) AND (condition [1] is not fulfilled) AND (condition [2] is<br>not fulfilled)||~~•~~||

<!-- end of page 175 -->

#### **Table 16: Transitions between types of Speed and distance monitoring**

3.13.10.6.2 If a transition of speed and distance monitoring occurs while a brake command is already applied, the concerned command shall be maintained until the revocation condition, if specified for the newly entered speed and distance monitoring, is fulfilled.

3.13.10.6.2.1 Note: This means that when the service brake is commanded in ceiling speed monitoring while it is not available in target speed monitoring, the service brake remains commanded when the on-board switches to target speed monitoring and is only revoked when the Permitted speed supervision limit is no longer exceeded.

3.13.10.6.3 If a transition from target speed monitoring to ceiling speed or release speed monitoring occurs while a traction cut-off command is already applied, the traction cut-off command shall be immediately revoked.

3.13.10.6.4 If a transition from target speed monitoring to release speed monitoring occurs while a service brake command is already applied, the service brake command shall be immediately revoked.

3.13.10.6.5 On executing a transition between types of speed and distance monitoring, the supervision status shall be determined according to the requirements specified for the newly entered speed and distance monitoring.

### **3.13.11 Perturbation location**

3.13.11.1 The purpose of the perturbation location is to trigger the MA request to the RBC in order to renew the Movement Authority in due time before the train would have to brake to an EOA/SvL or LOA target.

3.13.11.2 For the SvL, the on-board shall calculate the perturbation location applying the clauses 3.13.11.3, 3.13.11.4, 3.13.11.5 and 3.13.11.6.

3.13.11.3 Starting from the first element of the MRSP (i.e. from the start location of the on-board stored track description), the on-board shall calculate the location of the Indication supervision limit, valid for the speed of the MRSP element, taking into account the following assumptions:

   - a) the estimated acceleration shall be set to “zero”

   - b) if not inhibited by National Value, the compensation of the inaccuracy of the speed measurement shall be set to a value, calculated from the speed of the MRSP element, as defined in SUBSET-041 § 5.3.1.2: V_delta0ind = f41(V_MRSP-n)

   - c) If available for use, the service brake feedback shall not have any effect: T_bs1ind and T_bs2ind shall be set to T_bs if the service brake command is available for use, otherwise they shall be set to “zero”. T_tractionind and T_beremind shall be defined as in 3.13.9.3.2 for T_traction and T_berem by substituting T_bs2 with T_bs2ind and T_be_reduced with T_be as defined in 3.13.6.2.2.3

<!-- end of page 176 -->

3.13.11.4 To calculate the EBI supervision limit, the same formulas defined above with V_est, T_traction, T_berem and V_delta0 shall be applied, by substituting V_est with V_MRSPn, T_traction with T_tractionind, T_berem with T_beremind and V_delta0 with V_delta0ind.

𝑑𝐸𝐵𝐼(𝑉𝑀𝑅𝑆𝑃−𝑛) = 𝑑𝐸𝐵𝐷(𝑉𝑀𝑅𝑆𝑃−𝑛 + 𝑉𝑑𝑒𝑙𝑡𝑎0𝑖𝑛𝑑) −(𝑉𝑀𝑅𝑆𝑃−𝑛 + 𝑉𝑑𝑒𝑙𝑡𝑎0𝑖𝑛𝑑) ⋅(𝑇𝑏𝑒𝑟𝑒𝑚𝑖𝑛𝑑 + 𝑇𝑡𝑟𝑎𝑐𝑡𝑖𝑜𝑛𝑖𝑛𝑑) 𝑑𝑆𝐵𝐼2(𝑉𝑀𝑅𝑆𝑃−𝑛) = 𝑑𝐸𝐵𝐼(𝑉𝑀𝑅𝑆𝑃−𝑛) −𝑉𝑀𝑅𝑆𝑃−𝑛 ⋅𝑇𝑏𝑠2𝑖𝑛𝑑

𝑑𝐼(𝑉𝑀𝑅𝑆𝑃−𝑛) = 𝑑𝑃(𝑉𝑀𝑅𝑆𝑃−𝑛) −𝑉𝑀𝑅𝑆𝑃−𝑛 ⋅𝑇𝑖𝑛𝑑𝑖𝑐𝑎𝑡𝑖𝑜𝑛

With 𝑑𝑃(𝑉𝑀𝑅𝑆𝑃−𝑛) = 𝑑𝑆𝐵𝐼2(𝑉𝑀𝑅𝑆𝑃−𝑛) −𝑉𝑀𝑅𝑆𝑃−𝑛 ⋅𝑇𝑑𝑟𝑖𝑣𝑒𝑟 if the GUI curve is inhibited

Or 𝑑𝑃(𝑉𝑀𝑅𝑆𝑃−𝑛) = 𝑚𝑖𝑛{(𝑑𝑆𝐵𝐼2(𝑉𝑀𝑅𝑆𝑃−𝑛) −𝑉𝑀𝑅𝑆𝑃−𝑛 ⋅𝑇𝑑𝑟𝑖𝑣𝑒𝑟), 𝑑𝐺𝑈𝐼(𝑉𝑀𝑅𝑆𝑃−𝑛)} if the GUI curve is enabled

3.13.11.5 If the Indication supervision limit, obtained from the speed of the n<sup>th</sup> element, is located between the start and end locations of this n<sup>th</sup> element, the perturbation location shall be calculated as follows:

If 𝑑𝑎𝑀𝑅𝑆𝑃−𝑛 < 𝑑𝐼(𝑉𝑀𝑅𝑆𝑃−𝑛) ≤𝑑𝑏𝑀𝑅𝑆𝑃−𝑛

Then 𝑑𝑝𝑒𝑟𝑡𝑢𝑟𝑏𝑎𝑡𝑖𝑜𝑛 = 𝑑𝐼(𝑉𝑀𝑅𝑆𝑃−𝑛)

3.13.11.6 If the Indication supervision limit, obtained from the speed of the n<sup>th</sup> element, is located in advance of the end location of this n<sup>th</sup> element, and if the Indication supervision limit, obtained from the speed of the n+1<sup>th</sup> element is located in rear of the end location of this n<sup>th</sup> element (see Figure 56), the perturbation location shall be calculated as follows:

- If 𝑑𝐼(𝑉𝑀𝑅𝑆𝑃−𝑛) > 𝑑𝑏𝑀𝑅𝑆𝑃−𝑛 and 𝑑𝐼(𝑉𝑀𝑅𝑆𝑃−𝑛+1) < 𝑑𝑏𝑀𝑅𝑆𝑃−𝑛

- 𝑏

- Then 𝑑𝑝𝑒𝑟𝑡𝑢𝑟𝑏𝑎𝑡𝑖𝑜𝑛 = 𝑑𝑀𝑅𝑆𝑃−𝑛

<!-- Start of picture text -->
speed<br>EBD<br>VMRSP-n+1<br>I<br>VMRSP-n I<br>d MRSPa − n d MRSPb − n distance<br><!-- End of picture text -->

**Figure 56: Perturbation location derived from MRSP speed increase**

<!-- end of page 177 -->

3.13.11.7 For the EOA, the on-board shall calculate its perturbation location in the same way as for the SvL, except that the formulas to calculate the distance between the location of the Indication supervision limit and the SBD shall be:

𝑑𝑆𝐵𝐼1(𝑉𝑀𝑅𝑆𝑃−𝑛) = 𝑑𝑆𝐵𝐷(𝑉𝑀𝑅𝑆𝑃−𝑛) −𝑉𝑀𝑅𝑆𝑃−𝑛 ⋅𝑇𝑏𝑠1𝑖𝑛𝑑

𝑑𝐼(𝑉𝑀𝑅𝑆𝑃−𝑛) = 𝑑𝑃(𝑉𝑀𝑅𝑆𝑃−𝑛) −𝑉𝑀𝑅𝑆𝑃−𝑛 ⋅𝑇𝑖𝑛𝑑𝑖𝑐𝑎𝑡𝑖𝑜𝑛

With 𝑑𝑃(𝑉𝑀𝑅𝑆𝑃−𝑛) = 𝑑𝑆𝐵𝐼1(𝑉𝑀𝑅𝑆𝑃−𝑛) −𝑉𝑀𝑅𝑆𝑃−𝑛 ⋅𝑇𝑑𝑟𝑖𝑣𝑒𝑟 if the GUI curve is inhibited

Or 𝑑𝑃(𝑉𝑀𝑅𝑆𝑃−𝑛) = 𝑚𝑖𝑛{(𝑑𝑆𝐵𝐼1(𝑉𝑀𝑅𝑆𝑃−𝑛) −𝑉𝑀𝑅𝑆𝑃−𝑛 ⋅𝑇𝑑𝑟𝑖𝑣𝑒𝑟), 𝑑𝐺𝑈𝐼(𝑉𝑀𝑅𝑆𝑃−𝑛)} if the GUI curve is enabled

3.13.11.7.1 For the LOA, the on-board shall calculate its perturbation location in the same way as for the SvL, except that:

   - a) the elements of the MRSP whose speed is lower than the LOA speed shall be skipped,

   - b) the clause 3.13.11.6 shall apply only if none of the two referred consecutive MRSP elements is skipped according to a)

3.13.11.7.1.1 In case no perturbation location can be found applying 3.13.11.7.1 (e.g. the LOA speed is higher than the speed of all elements of the MRSP), the perturbation location shall be set at the LOA location.

3.13.11.7.1.2 In case the perturbation location found applying 3.13.11.7.1 is in advance of the LOA, the perturbation location shall be set at the LOA location.

3.13.11.8 The on-board shall trigger the MA request to the RBC when the train has passed, either with its estimated front end for the perturbation location calculated from the EOA or with its max safe front end for the perturbation location calculated from the SvL or the LOA, the following location:

𝑑𝑀𝐴𝑅 = 𝑑𝑝𝑒𝑟𝑡𝑢𝑟𝑏𝑎𝑡𝑖𝑜𝑛 −(𝑉𝑀𝑅𝑆𝑃 + 𝑑𝑉𝑤𝑎𝑟𝑛𝑖𝑛𝑔(𝑉𝑀𝑅𝑆𝑃)) ⋅𝑇𝑀𝐴𝑅

3.13.11.9 If, in exceptional situation (e.g. after a shortening of MA), the EBD, SBD or GUI speed at the start location of the MRSP is lower than the speed of the first element of the MRSP, the location to trigger the MA request to the RBC shall be considered as already passed.

3.13.11.10 Note: For trackside engineering reasons, the assumptions for the calculation of the EBI supervision limit are necessary to obtain a fully predictable perturbation location, i.e. independent from the measured acceleration and speed confidence interval.

<!-- end of page 178 -->
