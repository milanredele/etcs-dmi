## **3.11 Static Speed Restrictions and Gradients**

**3.11.1 Introduction**

3.11.1.1 The permitted speed at which the train is allowed to travel shall be limited to different kinds of Static Speed Restrictions.

3.11.1.2 A Static Speed Restriction shall be handled in the same way independent of ETCS level.

### **3.11.2 Definition of Static Speed Restriction**

3.11.2.1 Static Speed Restrictions are imposed by the trackside infrastructure, the train characteristics, the signalling and the mode of the on-board equipment.

3.11.2.2 There are eleven categories of Static Speed Restrictions: a) Static Speed Profile (SSP) b) Axle load Speed Profile (ASP) c) Temporary Speed Restrictions (TSR) d) Maximum Train Speed e) Signalling related speed restriction (only level 1) f) Mode related Speed Restriction.

<!-- end of page 97 -->

   - g) STM Max speed (for details refer to Subset-035)

   - h) STM System speed (for details refer to Subset-035)

   - i) Level Crossing speed restriction (LX SR)

   - j) Override function related Speed Restriction

   - k) Speed restriction to ensure a given permitted braking distance (PBD SR) (see 3.11.11)

3.11.2.3 The Static Speed Restriction categories are independent of each other. This means that one speed restriction category cannot affect, nor be affected by, any other category of Static Speed Restrictions.

<!-- Start of picture text -->
v<br>d<br>Maximum Train Speed<br>Static Speed Profile<br>Temporary Speed Restriction Mode related Speed Restriction<br><!-- End of picture text -->

#### **Figure 26: Example of Static Speed Restriction categories on a piece of track.**

3.11.2.4 Depending on the type of Static Speed Restriction train length may have to be used to ensure that the full length of the train has passed a Static Speed Restriction discontinuity before a speed increase shall be taken into account.

3.11.2.5 Intentionally deleted.

3.11.2.6 Intentionally deleted.

### **3.11.3 Static Speed Profile (SSP)**

3.11.3.1.1 The Static Speed Profile (SSP) is a description of the fixed speed restrictions of a given piece of track. The speed restrictions can be related to e.g. maximum line speed, curves, points, tunnel profiles, bridges.

<!-- end of page 98 -->

3.11.3.1.2 The Static Speed Profile is based on factors, which are both track and train dependent. The relationship between track and train characteristics determines the individual Static Speed Profile for each train.

3.11.3.1.3 It shall be possible for every element (distance between two discontinuities) of a static speed profile to define, if a transition to a higher speed limit than the speed limit specified for this element is permitted before the complete train has left the element.

**3.11.3.2 Static Speed Profile Categories**

3.11.3.2.1 It shall be possible to transmit several Static Speed Profile Categories; one Basic SSP category and specific SSP categories related to the international train categories.

3.11.3.2.1.1 The specific SSP categories are decomposed into two types:

   - a) The “Cant Deficiency” SSP categories: the cant deficiency value assigned to one category shall define the maximum speed, determined by suspension design, at which a particular train can traverse a curve and thus can be used to set a specific speed limit in a curve with regards to this category.

   - b) The “other specific” SSP categories: it groups all other specific SSP categories corresponding to the other international train categories

3.11.3.2.1.2 Whenever the type of specific SSP category is not explicitly specified in the following requirements, it shall be interpreted as being applicable for both types of specific SSP categories.

3.11.3.2.2 For each part of the Static Speed Profile, the ERTMS/ETCS trackside shall:

   - a) always give the Basic SSP, which shall be considered as the default “Cant Deficiency” SSP

   - b) optionally give one or more specific SSPs

   - c) specify, for each “other specific” SSP, whether it replaces or not the “Cant Deficiency” SSP as selected by the ERTMS/ETCS on-board equipment according to 3.11.3.2.3

3.11.3.2.3 For each part of the Static Speed Profile, the ERTMS/ETCS on-board equipment shall select the SSP best suiting its “Cant Deficiency” train category, according to the following order of preference:

   - a) if available, the “Cant Deficiency” SSP matching its “Cant Deficiency” train category, OR

   - b) if available, the “Cant Deficiency” SSP with the highest Cant Deficiency value below the value of its “Cant Deficiency” train category, OR

   - c) the Basic SSP

3.11.3.2.3.1 Intentionally deleted.

3.11.3.2.4 Intentionally deleted.

3.11.3.2.5 “Other Specific” SSP categories not relevant to the current train shall be ignored.

<!-- end of page 99 -->

3.11.3.2.6 For each part of the Static Speed Profile, the ERTMS/ETCS on-board equipment in a train belonging to at least one or more “other international” train categories shall use the most restrictive speed amongst:

   - a) the ” Cant Deficiency” SSP as selected in 3.11.3.2.3, only if none of the “other specific” SSP categories matching the train categories replaces the ” Cant Deficiency” SSP, AND

   - b) all the “other specific” SSP categories matching the “other international” train categories.

#### **3.11.3.3 Train categories**

3.11.3.3.1 A maximum of 31 train categories is defined to match the SSP categories. 16 “Cant Deficiency” train categories and 15 “other international” train categories.

3.11.3.3.2 A train shall always belong to one and only one “Cant Deficiency” train category and may optionally belong to one or more “other international” train categories.

3.11.3.3.3 The train category(ies) to which a train belongs is a part of its Train Data.

### **3.11.4 Axle load Speed Profile**

3.11.4.1 It shall be possible to define an Axle load Speed Profile as a non-continuous profile.

3.11.4.2 For each section with a speed restriction due to axle load, it shall be possible to transmit one or more axle load category speed restrictions.

3.11.4.2.1 Intentionally deleted.

3.11.4.3 The ERTMS/ETCS on-board equipment shall only consider the speed restriction that is associated with  the axle load category matching that of the train.

3.11.4.3.1 Note: As a consequence, it is the trackside responsibility to provide the axle load category speed restrictions taking into account the different axle load categories of the trains suitable to operate on the line.

3.11.4.4 Intentionally deleted.

3.11.4.5 The initial state for Axle load Speed Profile shall be “no restriction due to axle load”.

3.11.4.6 Whether a speed increase after the axle load speed restriction shall be delayed with train length, shall be determined by the axle load speed profile information sent to the onboard equipment.

### **3.11.5 Temporary Speed Restrictions**

3.11.5.1 The temporary speed restriction is defined in order to enable a separate category of track infrastructure speed restriction, which can be used for working areas etc.

<!-- end of page 100 -->

3.11.5.2 All Temporary Speed Restrictions are independent of each other. This means that an individual Temporary Speed Restriction cannot affect, nor be affected by, any other individual Temporary Speed Restriction.

3.11.5.3 Whether a speed increase after the temporary speed restriction shall be delayed with train length, shall be determined by the temporary speed restriction information sent to the on-board equipment.

3.11.5.4 When two or more temporary speed restrictions overlap, the most restrictive speed of the overlapping temporary speed restrictions shall be used in the area of overlap.

3.11.5.5 Each Temporary Speed Restriction shall have an identity to make it possible to revoke the Temporary Speed Restriction using its identity. The speed restriction shall be revoked immediately when revocation is received from trackside, without delay for the train length.

3.11.5.6 It shall be possible to identify whether a Temporary Speed Restriction is possible to revoke or not.

3.11.5.7 A new Temporary Speed Restriction shall not replace a previously received Temporary Speed Restriction with another identity.

3.11.5.8 Temporary Speed Restrictions shall only be revoked on request from the trackside.

3.11.5.9 If the on-board equipment receives a new Temporary Speed Restriction (TSR) with the same identity as an already received TSR, the new Temporary Speed Restriction shall replace the previous one, except when the Temporary Speed Restriction is identified as non revocable in which case this shall be considered as an additional TSR.

3.11.5.10 In case the train has changed its orientation any Temporary Speed Restriction shall be deleted (operational requirement: will be executed due to the mode change).

3.11.5.11 Intentionally deleted.

3.11.5.12 It shall be possible for the RBC to order an ERTMS/ETCS on-board equipment in Level 2 to reject revocable TSRs from balises.

3.11.5.13 When ERTMS/ETCS on-board equipment has accepted an order to reject revocable TSRs from balises, this inhibition shall be stored and shall be effective immediately, but only for revocable TSRs received from balises thereafter.

3.11.5.14 The inhibition of revocable TSRs from balises shall be deleted if any of the following occurs:

   - the communication session established with the RBC that ordered the inhibition is terminated, OR

   - in case of RBC/RBC handover, the max safe front end of the train crosses the RBC/RBC border.

3.11.5.15 Note: this inhibition may be useful in Level 1 / Level 2 mixed signalling applications when the RBC has more precise information about restrictions than can be given from balises.

<!-- end of page 101 -->

The RBC may then order inhibition of revocable TSRs from balises and instead send more precise TSRs to the train.

### **3.11.6 Signalling related speed restrictions**

3.11.6.1 In level 1, it shall be possible to send to the on-board equipment a speed restriction with a value depending on the current state of signalling.

3.11.6.2 This speed value shall be taken into account by the on-board equipment as soon as it is received on-board, with the exception of a signalling related speed restriction from an infill device. In case of infill information the speed restriction shall be taken into account from the location reference of the balise group at the next main signal.

3.11.6.3 The speed restriction shall be valid until a new signalling related speed restriction is received.

3.11.6.3.1 If the ERTMS/ETCS on-board equipment switches from level 1 to level 2, the signalling related speed restriction shall remain valid until a level 2 MA is accepted by the ERTMS/ETCS on-board equipment

3.11.6.4 In case of a signal at danger the signalling related speed restriction shall have value zero, which shall be evaluated by the ERTMS/ETCS on-board equipment not as a speed limit but as a train trip order.

3.11.6.5 In case of infill information the signalling related speed restriction at zero shall be ignored.

3.11.6.5.1 Note: The infill information will also include an EOA at the next main signal that will be supervised according to the normal rules.

### **3.11.7 Mode related speed restrictions**

3.11.7.1 The value of the mode related speed restriction shall be determined by the corresponding national value or the corresponding default values if the national values are not applicable.

3.11.7.1.1  Exception 1: For the modes On-sight, Limited Supervision and Shunting the speed limit can also be given from the trackside. The speed limit given from the trackside shall prevail over the National value and the default value.

3.11.7.1.2 Exception 2: For the modes Reversing and Supervised Manoeuvre there is no National/Default value. The speed limit is always given from trackside.

3.11.7.1.3 Exception 3: For the mode Staff Responsible the speed limit can also be entered by the driver. The speed limit given by the driver shall prevail over the National/Default value.

### **3.11.8 Train related speed restriction**

3.11.8.1 It shall be possible to define the maximum train speed related to the actual performance and configuration of the train.

<!-- end of page 102 -->

### **3.11.9 LX speed restriction**

3.11.9.1 It shall be possible to define a LX speed restriction when the train has to pass a non protected Level Crossing.

### **3.11.10 Override function related Speed Restriction**

3.11.10.1 While the “override” function is active, the override speed limit (national /default value) shall be taken into account.

### **3.11.11 Speed restriction to ensure permitted braking distance**

3.11.11.1 It shall be possible for trackside to request the ERTMS/ETCS on-board equipment to calculate a speed restriction based on a permitted braking distance given by trackside.

3.11.11.2 The order shall be given by means of a non-continuous profile defining:

   - The start and end location for the speed restriction

   - The permitted braking distance (PBD) used to calculate the speed restriction value

   - Whether the permitted braking distance is to be achieved with the Service Brake or Emergency Brake

   - A single gradient value applicable for the calculation

3.11.11.3 The speed restriction shall be calculated when the ERTMS/ETCS on-board equipment receives the permitted braking distance information from trackside, and shall be recalculated only if any of the inputs taken into account for the calculation of the speed restriction changes.

3.11.11.4 The calculation of the speed restriction by the ERTMS/ETCS on-board equipment shall take into account that:

   - The single gradient value received from trackside shall be compensated in value according to the rotating mass as defined in 3.13.4.3.

   - The safe deceleration shall be computed as in 3.13.6.2.1 but without considering the adhesion profiles, the track conditions related to brake inhibition and the track conditions related to powerless section given by trackside.

   - The expected deceleration shall be computed as in 3.13.6.3.1 but without considering the track conditions related to brake inhibition and the track conditions related to powerless section given by trackside.

   - The ERTMS/ETCS on-board equipment shall calculate an Emergency Brake Deceleration (EBD) curve based on the safe deceleration and that reaches zero speed at a distance equal to the permitted braking distance.

   - If the permitted braking distance is to be achieved with the service brake, the ERTMS/ETCS on-board equipment shall also calculate a Service Brake Deceleration (SBD) curve based on the expected deceleration and that reaches zero speed at a distance equal to the permitted braking distance.

<!-- end of page 103 -->

   - The estimated acceleration shall be set to “zero”.

   - If not inhibited by National Value, the compensation of the inaccuracy of the speed measurement shall be set to a value calculated from the PBD speed, as defined in SUBSET-041 § 5.3.1.2: V_delta0PBD = f41(V_PBD + dV_EBI(V_PBD)) if the permitted braking distance is to be achieved with the emergency brake; V_delta0PBD = f41(V_PBD + dV_SBI(V_PBD)) if the permitted braking distance is to be achieved with the service brake.

   - The train will travel a distance from the last encountered balise of a group that provides restrictive information until initiating the brake command. This travelled distance shall be set to a value calculated from the PBD speed considering a processing delay (T41) equal to SUBSET-041 § 5.2.1.1.

   - Regardless of how the service brake feedback is actually configured (see 3.13.2.2.7.2), T_bs1 and T_bs2 (see 3.13.9.3.3) shall be defined as if the service brake feedback was not implemented.

   - Regardless of how the traction cut-off interface is actually configured (see 3.13.2.2.8), T_traction (see 3.13.9.3.2) shall be defined as if the traction cut-off was not implemented.

3.11.11.4.1 Note: Knowing how the PBD speed restriction is computed by the ERTMS/ETCS onboard equipment, it is the responsibility of the trackside to set the appropriate permitted braking distance with regard to the risk of not initiating the brake command in due time when encountering a further balise group providing restrictive information. In other words, if deemed necessary, the trackside can include provisions based on the characteristics of the balise group providing restrictive information e.g. distances between balises in that group with regards to validity direction of transmitted information and balise group orientation, accuracy of balise location.

3.11.11.4.2 Note: If the permitted braking distance is to be achieved with the service brake, it is the responsibility of the trackside to also consider an estimation of the on-board over-reading and under-reading amounts at the time the brake command is initiated in order to lower the likelihood of the max safe front end of the train reaching the EBI supervision limit.

3.11.11.5 Note: Throughout the following formulas, all the distances marked with “d” (lower case) are counted from a single arbitrary reference location.

3.11.11.6 If the permitted braking distance is to be achieved with the emergency brake, the ERTMS/ETCS on-board equipment shall seek the PBD speed restriction value (V_PBD) which satisfies the two following inequalities. The resulting value shall then be rounded down to the next lower multiple of 5km/h:

𝐴𝐵𝑆{(𝑉𝑃𝐵𝐷 + 𝑑𝑉𝑒𝑏𝑖) −(𝑉𝐸𝐵𝐷(𝑑𝑜𝑓𝑓𝑠𝑒𝑡 + 𝐷𝑏𝑒𝑐) −𝑉𝑑𝑒𝑙𝑡𝑎0𝑃𝐵𝐷)} ≤1𝑘𝑚/ℎ

𝑑𝑜𝑓𝑓𝑠𝑒𝑡 + 𝐷𝑏𝑒𝑐 ≤𝑑𝑃𝐵𝐷

With 𝑑𝑉𝑒𝑏𝑖 as defined in 3.13.9.2.3 by substituting 𝑉𝑀𝑅𝑆𝑃 with 𝑉𝑃𝐵𝐷

With 𝑉𝑑𝑒𝑙𝑡𝑎0𝑃𝐵𝐷 = 𝑓41(𝑉𝑃𝐵𝐷 + 𝑑𝑉𝑒𝑏𝑖) or 𝑉𝑑𝑒𝑙𝑡𝑎0𝑃𝐵𝐷 = 0 (if compensation of speed inaccuracy is inhibited by National Value)

<!-- end of page 104 -->

With 𝐷𝑏𝑒𝑐 = (𝑉𝑃𝐵𝐷 + 𝑑𝑉𝑒𝑏𝑖 + 𝑉𝑑𝑒𝑙𝑡𝑎0𝑃𝐵𝐷) ⋅(𝑇𝑡𝑟𝑎𝑐𝑡𝑖𝑜𝑛 + 𝑇𝑏𝑒𝑟𝑒𝑚)

With 𝑇𝑡𝑟𝑎𝑐𝑡𝑖𝑜𝑛 and 𝑇𝑏𝑒𝑟𝑒𝑚 as defined in 3.13.9.3.2 but substituting T_be_reduced with T_be as defined in 3.13.6.2.2.3

With 𝑑𝑃𝐵𝐷 being the permitted braking distance given by trackside

With 𝑉𝐸𝐵𝐷(𝑑) being the EBD curve that reaches zero speed at 𝑑𝑃𝐵𝐷

With 𝑑𝑜𝑓𝑓𝑠𝑒𝑡 = 𝐿𝑎𝑛𝑡𝑒𝑛𝑛𝑎−𝑓𝑟𝑜𝑛𝑡 + 𝑇41 ⋅(𝑉𝑃𝐵𝐷 + 𝑑𝑉𝑒𝑏𝑖 + 𝑉𝑑𝑒𝑙𝑡𝑎0𝑃𝐵𝐷)

If no speed value fulfils the above inequalities, then:

𝑉𝑃𝐵𝐷 = 0

3.11.11.7 If the permitted braking distance is to be achieved with the service brake, the PBD speed restriction (V_PBD) shall be equal to the most restrictive value amongst the one computed from the EBD (see 3.11.11.8) and the one computed from the SBD (see 3.11.11.9). The resulting value shall then be rounded down to the next lower multiple of 5km/h.

3.11.11.8 If the permitted braking distance is to be achieved with the service brake, the ERTMS/ETCS on-board equipment shall seek the PBDEBD speed restriction value which satisfies the two following inequalities:

- 𝐴𝐵𝑆{(𝑉𝐸𝐵𝐷(𝑑𝑜𝑓𝑓𝑠𝑒𝑡 + 𝐷𝑏𝑒𝑐(𝑉+ (𝑉𝑃𝐵𝐷𝑃𝐵𝐷+ 𝑑𝑉+ 𝑑𝑉𝑠𝑏𝑖) −𝑠𝑏𝑖) ⋅𝑇𝑏𝑠2) −𝑉𝑑𝑒𝑙𝑡𝑎0𝑃𝐵𝐷)<sup>} ≤1𝑘𝑚/ℎ</sup>

𝑑𝑜𝑓𝑓𝑠𝑒𝑡 + 𝐷𝑏𝑒𝑐 + (𝑉𝑃𝐵𝐷 + 𝑑𝑉𝑠𝑏𝑖) ⋅𝑇𝑏𝑠2 ≤𝑑𝑃𝐵𝐷

With 𝑑𝑉𝑠𝑏𝑖 as defined in 3.13.9.2.5 by substituting 𝑉𝑀𝑅𝑆𝑃 with 𝑉𝑃𝐵𝐷

With 𝑉𝑑𝑒𝑙𝑡𝑎0𝑃𝐵𝐷 = 𝑓41(𝑉𝑃𝐵𝐷 + 𝑑𝑉𝑠𝑏𝑖) or 𝑉𝑑𝑒𝑙𝑡𝑎0𝑃𝐵𝐷 = 0 (if compensation of speed inaccuracy is inhibited by National Value)

With 𝐷𝑏𝑒𝑐 = (𝑉𝑃𝐵𝐷 + 𝑑𝑉𝑠𝑏𝑖 + 𝑉𝑑𝑒𝑙𝑡𝑎0𝑃𝐵𝐷) ⋅(𝑇𝑡𝑟𝑎𝑐𝑡𝑖𝑜𝑛 + 𝑇𝑏𝑒𝑟𝑒𝑚)

With 𝑇𝑡𝑟𝑎𝑐𝑡𝑖𝑜𝑛 and 𝑇𝑏𝑒𝑟𝑒𝑚 as defined in 3.13.9.3.2 but substituting 𝑇𝑏𝑒_𝑟𝑒𝑑𝑢𝑐𝑒𝑑 with 𝑇𝑏𝑒 as defined in 3.13.6.2.2.3

With 𝑇𝑏𝑠2 as defined in 3.13.9.3.3 but substituting 𝑇𝑏𝑠_𝑟𝑒𝑑𝑢𝑐𝑒𝑑 with 𝑇𝑏𝑠 as defined in 3.13.6.3.2.4

With 𝑑𝑃𝐵𝐷 being the permitted braking distance given by trackside

With 𝑉𝐸𝐵𝐷(𝑑) being the EBD curve that reaches zero speed at 𝑑𝑃𝐵𝐷

With 𝑑𝑜𝑓𝑓𝑠𝑒𝑡 = 𝐿𝑎𝑛𝑡𝑒𝑛𝑛𝑎−𝑓𝑟𝑜𝑛𝑡 + 𝑇41 ⋅(𝑉𝑃𝐵𝐷 + 𝑑𝑉𝑠𝑏𝑖 + 𝑉𝑑𝑒𝑙𝑡𝑎0𝑃𝐵𝐷)

If no speed value fulfils the above inequalities, then:

𝑉𝑃𝐵𝐷 = 0

3.11.11.9 If the permitted braking distance is to be achieved with the service brake, the ERTMS/ETCS on-board equipment shall seek the PBDSBD speed restriction value which satisfies the two following inequalities:

- 𝐴𝐵𝑆{(𝑉𝑃𝐵𝐷 + 𝑑𝑉𝑠𝑏𝑖) −(𝑉𝑆𝐵𝐷(𝑑𝑜𝑓𝑓𝑠𝑒𝑡 + (𝑉𝑃𝐵𝐷 + 𝑑𝑉𝑠𝑏𝑖) ⋅𝑇𝑏𝑠1))} ≤1𝑘𝑚/ℎ

<!-- end of page 105 -->

- 𝑑𝑜𝑓𝑓𝑠𝑒𝑡 + (𝑉𝑃𝐵𝐷 + 𝑑𝑉𝑠𝑏𝑖) ∙𝑇𝑏𝑠1 ≤𝑑𝑃𝐵𝐷

With 𝑑𝑉𝑠𝑏𝑖 as defined in 3.13.9.2.5 by substituting 𝑉𝑀𝑅𝑆𝑃 with 𝑉𝑃𝐵𝐷

With 𝑇𝑏𝑠1 as defined in 3.13.9.3.3

With 𝑑𝑃𝐵𝐷 being the permitted braking distance given by trackside

With 𝑉𝑆𝐵𝐷(𝑑) being the SBD curve that reaches zero speed at 𝑑𝑃𝐵𝐷

With 𝑑𝑜𝑓𝑓𝑠𝑒𝑡 = 𝐿𝑎𝑛𝑡𝑒𝑛𝑛𝑎−𝑓𝑟𝑜𝑛𝑡 + 𝑇41 ⋅(𝑉𝑃𝐵𝐷 + 𝑑𝑉𝑠𝑏𝑖)

If no speed value fulfils the above inequalities, then:

𝑉𝑃𝐵𝐷 = 0

3.11.11.10 Note: The method chosen (e.g. iterative algorithm) to compute the PBD speed restriction(s) is an implementation issue.

3.11.11.11 The initial state for Speed Restrictions to Ensure Permitted Braking Distance shall be “no speed restriction”.

### **3.11.12 Gradients**

3.11.12.1 The gradient information for a given piece of track shall be transmitted to the on-board equipment in form of a gradient profile.

3.11.12.2 The gradient profile shall be continuous, i.e., give a gradient value for each location within the piece of track covered by the profile.

3.11.12.3 A gradient value shall be identified as a positive value for an uphill slope, and with a negative value for a downhill slope.

3.11.12.4 The gradient profile shall contain the gradient information as a sequence of gradient values, constant between two defined locations each, see Figure 27.

<!-- Start of picture text -->
Travelling direction<br>Track<br>Height<br>Distance<br>Gradient<br>values<br>A B Distance<br><!-- End of picture text -->

**Figure 27: Gradient profile**

<!-- end of page 106 -->

3.11.12.4.1 Note: The figure above symbolises the engineering process to provide the values of gradients. Following the track height, the track must be split in segments giving for each segment a gradient value.

3.11.12.5 It shall be possible via balise groups to send to the on-board equipment a default gradient for TSR, to be used for the parts of the track not covered by the gradient profile.

3.11.12.6 The Default Gradient for TSR stored on-board shall be valid until a new Default Gradient for TSR is received.
