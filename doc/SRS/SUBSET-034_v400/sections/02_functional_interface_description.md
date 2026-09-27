# **2 Functional Interface Description**

## **2.1 General**

2.1.1.1 This chapter describes the functional requirements on all information which is exchanged between ERTMS/ETCS on-board and the Vehicle via the Train Interface.

2.1.1.2 The information which is exchanged between ERTMS/ETCS on-board and the Vehicle is based on the functionality defined by the ERTMS/ETCS SRS [1].

2.1.1.3 Note: Due to its complexity and characteristics, the specification of the interface between ERTMS/ETCS on-board and the recording device in the train is defined in a separate interface specification and therefore not part of the train interface specification.

2.1.1.4 With reference to the Train Interface:

   - Input is defined as data flow from Vehicle to ERTMS/ETCS on-board

   - Output is defined as data flow from ERTMS/ETCS on-board to Vehicle.

<!-- end of page 7 -->

2.1.1.5 In this chapter 2 all functional requirements are written as mandatory principles, i.e. using the word “shall”. Whether a function is used in a specific implementation of the Train Interface may depend on the characteristics of the Vehicle. See further details in chapter 3 which contains the mandatory and optional requirements for the application of the Train Interface functions by the rolling stock subsystem.

## **2.2 Mode Control**

### **2.2.1 Sleeping**

2.2.1.1 The sleeping information is defined as a two state input with the following values:

   - Sleeping requested

   - Sleeping not requested.

2.2.1.2 Note: The input value “Sleeping requested” is used by ERTMS/ETCS on-board as one of the conditions for the transition to Sleeping mode. The other two conditions are “standstill”, which is managed internally in the ERTMS/ETCS on-board and “All desks connected to the ERTMS/ETCS on-board equipment are closed”, equivalent to “All cabs connected to the ERTMS/ETCS on-board equipment are not active”, which is generated internally in the ERTMS/ETCS on-board based on the input values “Cab not active” as defined in 2.5.1 of this document. See also the SRS references in 2.9.

2.2.1.3 The following requirements shall apply to the rolling stock:

2.2.1.3.1 After successful train inauguration, i.e. one master vehicle exists, defined by strictly one activated cab in the train, the information about successful master definition shall be communicated train-wide to all ERTMS/ETCS on-board units by means of the value “Sleeping requested”.

2.2.1.3.1.1 Exception: The ERTMS/ETCS on-board connected via the cab status input (see 2.5.1) with the active cab may be excluded from getting the “Sleeping requested” information because it is not relevant for this ERTMS/ETCS on-board.

2.2.1.3.2 If no active cab exists in the train, this information shall be communicated train-wide to all ERTMS/ETCS on-board units by means of the value “Sleeping not requested”.

2.2.1.3.3 Note: By means of this configuration of the sleeping input it is ensured that the ERTMS/ETCS on-board will only go to sleeping mode if another cab in the train is active, i.e. another train control system (ETCS or national) provides the supervision of the train movement.

### **2.2.2 Passive shunting**

2.2.2.1 The passive shunting information is defined as a two state input with the following values:

   - Passive shunting permitted

   - Passive shunting not permitted.

2.2.2.2 Note: The input value “Passive shunting permitted” is used by ERTMS/ETCS on-board as one of the conditions for the transition to Passive Shunting mode. The other two conditions are “desks are closed”, equivalent to “Cabs are not active”, which is generated internally in the ERTMS/ETCS on-board from the input values “cab not active” as defined in 2.5.1 of this document, and “Continue Shunting on desk closure” function is active, which is

<!-- end of page 8 -->

generated internally in ERTMS/ETCS on-board from driver input. See also the SRS references in 2.9.

2.2.2.3 The following requirements shall apply to the rolling stock:

2.2.2.3.1 The passive shunting input shall have the value “Passive shunting permitted” if the train is immobilized by means of a braking system that can be released from another cab after its activation.

2.2.2.3.2 If the condition in 2.2.2.3.1 is not fulfilled, the passive shunting input shall have the value “Passive shunting not permitted”.

2.2.2.3.3 It shall be allowed to configure the passive shunting input permanently as “Passive shunting not permitted”. This is a decision made only by the Railway Undertaking e.g. based on the characteristics of the vehicle.

### **2.2.3 Non-Leading**

2.2.3.1 The non-leading information is defined as a two state input with the following values:

   - Non-leading permitted

   - Non-leading not permitted.

2.2.3.2 Note: The input value “Non-leading permitted” is used by ERTMS/ETCS on-board as one of the conditions for the transition to Non Leading mode. The other two conditions are “standstill” and “Driver selects Non Leading via the DMI” which are managed internally in the ERTMS/ETCS on-board. See also the SRS references in 2.9.

2.2.3.3 The following requirements shall apply to the rolling stock:

2.2.3.3.1 The non-leading input shall have the value “Non-leading permitted” if either

   - a) the brake release function of the train wide brake control device of the engine is inhibited (for example in case the driver of the non-leading engine is allowed to command the service brake application),

   - OR

   - b) the train wide service brake control device of the engine is isolated (for example it is isolated from the brake pipe, in case of using a brake pipe pressure control system).

2.2.3.3.2 If none of the conditions in a) is fulfilled, the non-leading input shall have the value “Nonleading not permitted”.

### **2.2.4 Isolation**

2.2.4.1 The isolation information is defined as a two state output with the following values:

   - ETCS isolated

   - ETCS not isolated.

2.2.4.2 Note: The output “ETCS isolated” is generated by the ERTMS/ETCS on-board to inform the vehicle that the ERTMS/ETCS on-board is in Isolation mode. This information may be used by some other on-board equipment/systems. It is the responsibility of the ERTMS/ETCS on-board to ensure that in isolation mode the ERTMS/ETCS on-board equipment is physically isolated from the brakes (see SRS clause 4.4.3.1.1).

<!-- end of page 9 -->

### **2.2.5 Automatic driving**

2.2.5.1 The automatic driving information is defined as a two state output with the following values:

   - ERTMS/ETCS on-board is in AD mode.

   - ERTMS/ETCS on-board is not in AD mode.

2.2.5.2 The following requirements shall apply to the rolling stock:

2.2.5.1.1 The automatic driving output value “ETCS is in AD mode” shall be used by the train to enable the traction/braking and door commands from the ERTMS/ATO on-board and to disable the traction commands from the driver.

2.2.5.1.2 The automatic driving output value “ETCS is not in AD mode” shall be used by the train to disable the traction/braking and door commands from the ERTMS/ATO on-board.

### **2.2.6 Remote shunting**

2.2.6.1 The remote shunting information is defined as a two state output with the following values:

   - ERTMS/ETCS on-board is in a mode permitting remote shunting

   - ERTMS/ETCS on-board is not in a mode permitting remote shunting.

2.2.6.2 Note: The output “ERTMS/ETCS on-board is in a mode permitting remote shunting” is generated by the ERTMS/ETCS on-board to inform other on-board equipment/systems that the remote control could be activated.

2.2.6.3 The following requirements shall apply to the rolling stock:

2.2.6.3.1 The remote shunting output value “ERTMS/ETCS on-board is in a mode permitting remote shunting” shall be used by the train to allow a radio remote control unit to control the train.

2.2.6.3.2 The remote shunting output value “ERTMS/ETCS on-board is not in a mode permitting remote shunting” shall be used by the train to inhibit any radio remote control.

## **2.3 Control of Brakes**

### **2.3.1 Service brake command**

2.3.1.1 The service brake command (SBC) is defined as a two state output with the following values:

   - Service brake commanded

   - Service brake not commanded.

2.3.1.2 Note: The SBC output is generated by ERTMS/ETCS on-board to command the service brake and to revoke this command.

2.3.1.3 The following requirements shall apply to the rolling stock:

2.3.1.3.1 The SBC output value “Service brake commanded” shall result in the train applying the full service brake and cutting off the traction.

2.3.1.3.2 Note: Full service brake means application of 100% of the installed braking performance of the train.

<!-- end of page 10 -->

2.3.1.3.3 The SBC output value “Service brake not commanded” shall result in a release of the service brake, but only to the highest brake level currently commanded by other application(s) or by the driver, and shall permit the traction power to be switched on.

2.3.1.3.4 Note 1: the traction power can be switched on again only after the driver has cancelled the traction command (i.e. after a “0-position-acknowledgement” by the traction controller).”

2.3.1.3.5 Note 2: In case of no SB manually applied by the driver and in case of no ASC activated, the SB released by ETCS will automatically cancel the brake application on the train. In case of a gradient, it is possible to have forward movement which must be controlled by driver with his own action on brake. This is acceptable as it is the same situation today (without ETCS).

2.3.1.3.6 Note 3: The full service brake may be actuated by various brake systems depending on the rolling stock brake architecture (e.g. dynamic brake by substitution, blending or superposition principle with the UIC air brake).

### **2.3.2 Brake pressure**

2.3.2.1 The brake pressure information is defined as a numerical value input with the following values:

2.3.2.2 Note: The brake pressure input is used by ERTMS/ETCS on-board in the service brake feedback model in [1].

2.3.2.3 The following requirements apply to the rolling stock:

2.3.2.3.1 The value of the brake pressure input shall represent either the pressure in the main brake pipe or in the brake cylinder.

2.3.2.3.2 Note: The ERTMS/ETCS on-board has to be configured for one of these two input parameters.

### **2.3.3 Emergency brake command**

2.3.3.1 The emergency brake command (EBC) is defined as a two state output with the following values:

   - Emergency brake commanded

   - Emergency brake not commanded.

2.3.3.2 Note: The EBC output is generated by ERTMS/ETCS on-board to command the emergency brake and to revoke this command.

2.3.3.3 The following requirements apply to the rolling stock:

2.3.3.3.1 The EBC output value “Emergency brake commanded” shall result in the train applying the emergency brake and cutting off the traction.

2.3.3.3.2 The EBC output value “Emergency brake not commanded” shall permit release of the emergency brake (implementation dependent if brake is released automatically or not, decision made by operator) and shall permit the traction power to be switched on.

2.3.3.3.3 Note: the traction power can be switched on again only after the driver has cancelled the traction command (i.e. after a “0-position-acknowledgement” by the traction controller).

<!-- end of page 11 -->

### **2.3.4 Special brake inhibition area – Trackside orders**

2.3.4.1 The generic requirement descriptions in this section shall apply to the inhibition of the following special brakes:

   - Regenerative brake

   - Magnetic shoe brake

   - Eddy current brake for emergency braking

   - Eddy current brake for service braking.

2.3.4.2 For each special brake inhibition area, the “Special brake inhibition area” information is an output that contains the following information:

   - the remaining distance from the max safe front end of the train to the start location of this special brake inhibition area

   - the remaining distance from the min safe rear end of the train to the end location of this special brake inhibition area.

### **2.3.5 Special brake inhibit – STM Orders**

2.3.5.1 The generic requirement descriptions in this section shall apply to the inhibition of the following special brakes:

   - Regenerative brake

   - Magnetic shoe brake

   - Eddy current brake for emergency braking

   - Eddy current brake for service braking.

2.3.5.2 This special brake information is defined for each special brake as a two state output with the following values:

   - Not inhibited

   - Inhibited.

2.3.5.3 Note: This special brake inhibit output is generated by the ERTMS/ETCS on-board to inform the train that the respective special brake application is to be allowed / inhibited due to an order from STM.

### **2.3.6 Special brake status**

2.3.6.1 The generic requirement descriptions in this section shall apply to the status of the following special brakes:

   - Regenerative brake

   - Magnetic shoe brake

   - Eddy current brake

   - Electro Pneumatic (EP) brake.

2.3.6.2 Note: The specifications for the status of these special brakes are exactly the same and therefore given only once.

2.3.6.3 The special brake status information is defined as a two state input with the following values:

<!-- end of page 12 -->

   - Special brake active

   - Special brake not active.

2.3.6.4 Note: The special brake status input is used by ERTMS/ETCS on-board to adapt the braking curve model for the characteristics of the service brake, the emergency brake, or both, according to the possible configurations of ERTMS/ETCS on-board as defined in [1].

2.3.6.5 The following requirements shall apply to the rolling stock:

2.3.6.5.1 The special brake status input shall have the value “Special brake active” if the special brake is available, i.e. in working condition and not inhibited.

2.3.6.5.2 The special brake status input shall have the value “Special brake not active” if the special brake is not available, i.e. not in working condition or inhibited.

### **2.3.7 Additional brake status**

2.3.7.1 The additional brake status information (ABS) is defined as a two state input with the following values:

   - Additional brakes active

   - Additional brakes not active.

2.3.7.2 The “additional brakes” are defined as any brakes in the train which are independent of wheel/rail adhesion.

2.3.7.3 Note: The ABS input is used by ERTMS/ETCS on-board to adapt the braking curve model for the characteristics of the additional brakes independent of wheel/rail adhesions, as defined in [1].

2.3.7.4 The following requirements shall apply to the rolling stock:

2.3.7.4.1 The ABS input shall have the value “additional brakes active” if the additional brake(s) is/are available, i.e. in working condition and not inhibited.

2.3.7.4.2 The ABS input shall have the value “additional brakes not active” if the additional brake(s) is/are not available, i.e. not in working condition or inhibited.

## **2.4 Control of Train Functions**

### **2.4.1 Change of traction system**

2.4.1.1 The “Change of traction system” information is an output that contains the following information:

   - the remaining distance from the max safe front end of the train to the location of change of traction system

   - the identity of the new traction system.

### **2.4.2 Powerless section with pantograph to be lowered – Trackside orders**

2.4.2.1 For each powerless section with pantograph to be lowered, the “Powerless section with pantograph to be lowered” information is an output that contains the following information:

   - the remaining distance from the max safe front end of the train to the start location of this powerless section

<!-- end of page 13 -->

   - the remaining distance from the min safe front end of the train to the end location of this powerless section.

### **2.4.3 Pantograph – STM orders**

2.4.3.1 The pantograph information is defined as a two state output with the following values:

   - Raise

   - Lower.

2.4.3.2 Note: This pantograph output is generated by the ERTMS/ETCS on-board to inform the train that the pantograph has to be raised / lowered immediately due to an order from STM.

### **2.4.4 Air tightness area – Trackside orders**

2.4.4.1 For each air tightness area, the “Air Tightness area” information is an output that contains the following information:

   - the remaining distance from the max safe front end of the train to the start location of this air tightness area

   - the remaining distance from the min safe rear end of the train to the end location of this air tightness area.

### **2.4.5 Air tightness – STM orders**

2.4.5.1 The air tightness information is defined as a two state output with the following values:

   - Open

   - Close.

2.4.5.2 Note: This air tightness output is generated by the ERTMS/ETCS on-board to inform the train that the flap has to be open / closed immediately due to an order from STM.

### **2.4.6 Station platform**

2.4.6.1 For each station platform, the “Station platform” information is an output that contains the following information:

   - the remaining distance from the max safe front end of the train to the start location of this station platform

   - the remaining distance from the min safe front end of the train to the end location of this station platform

   - the nominal height of platform above rail level (refer to TSI infrastructure)

   - the position of the station platform (left side, right side, both sides) in reference to the train orientation.

### **2.4.7 Powerless section with main power switch to be switched off – Trackside orders**

2.4.7.1 For each powerless section with main power switch to be switched off, the “Powerless section with main power switch to be switched off” information is an output that contains the following information:

- the remaining distance from the max safe front end of the train to the start location of this powerless section

<!-- end of page 14 -->

   - the remaining distance from the min safe front end of the train to the end location of this powerless section.

### **2.4.8 Main Power Switch – STM orders**

2.4.8.1 The main power switch information is defined as a two state output with the following values:

   - Open

   - Close.

2.4.8.2 Note: This main power switch output is generated by the ERTMS/ETCS on-board to inform the train that the main switch has to be open / closed immediately due to an order from STM.

### **2.4.9 Traction Cut Off**

2.4.9.1 The traction cut off information (TCO) is defined as a two state output with the following values:

   - Cut off traction

   - Do not cut off traction.

2.4.9.2 Note: The TCO output is generated by ERTMS/ETCS on-board to cut the traction as soon as it passes the warning limit of the braking curve model as defined in [1] or as a consequence of an STM command.

2.4.9.3 The following requirements shall apply to the rolling stock:

2.4.9.3.1 The TCO output value “Cut off traction” shall be used by the train to cut off the traction power.

2.4.9.3.2 The TCO output value “Do not cut off traction” shall allow the driver or an automatic system (ASC) to apply traction power.

### **2.4.10 Change of allowed current consumption**

2.4.10.1 The “Change of allowed current consumption” information is an output that contains the following information:

   - the remaining distance from the max safe front end of the train to the location of change of allowed current consumption

   - the new allowed current consumption.

### **2.4.11 Engine orientation in Supervised Manoeuvre**

2.4.11.1 The engine orientation with regards to the last received SM authorisation is a two state output with the following values:

   - Same as the one of the SM authorisation

   - Opposite to the one of the SM authorisation.

2.4.11.2 Note: This output is generated by the ERTMS/ETCS on-board in Supervised Manoeuvre mode to indicate to the train how to interpret the outputs “Change of traction system”, “Powerless section with pantograph to be lowered – Trackside orders”, “Air tightness area

<!-- end of page 15 -->

   - Trackside orders”, “Station platform”, “Powerless section with main power switch to be switched off – Trackside orders” and “Change of allowed current consumption”.

## **2.5 Train Status**

### **2.5.1 Cab Status**

2.5.1.1 The cab status information is defined as a two state input with the following values:

   - Cab active

   - Cab not active.

2.5.1.2 Note 1: The cab status input is used by ERTMS/ETCS on-board for various purposes as defined in [1] or by an STM as defined in [3]. The expression “desk open” in [1] is equivalent to “Cab active” and “desk closed” in [1] is equivalent to “Cab not active”.

2.5.1.3 If there is more than one cab connected to a single ERTMS/ETCS on-board unit, each cab will be connected to its individual input.

2.5.1.4 The following requirements shall apply to the rolling stock:

2.5.1.4.1 The cab status input shall have the value “Cab active” if the cab connected to this input is active.

2.5.1.4.2 Note: The active cab is the cab from which the traction is controlled.

2.5.1.4.3 The cab status input shall have the value “Cab not active” if the cab connected to this input is not active.

2.5.1.4.4 For single cab locos with two desks, each related to a different train orientation, each desk will be connected to its individual cab status input.

2.5.1.4.5 For single cab locos with only one desk, the cab status shall be combined with the main running direction information to define two virtual cab status signals, connected to their individual inputs.

Virtual Cab A active = (Cab active) AND (main running direction A)

Virtual Cab B active = (Cab active) AND (main running direction B)

2.5.1.4.6 Note: The main running direction may be obtained from e.g. the head lights of the train or a dedicated switch.

2.5.1.4.7 Regardless of the vehicle layout the rolling stock shall ensure that only one cab or virtual cab is reported active at any time to a single ERTMS/ETCS on-board equipment.

### **2.5.2 Direction Controller**

2.5.2.1 The direction controller information is defined as a three state input with the following values:

   - Forward

   - Neutral

   - Backward.

2.5.2.2 The notion of forward direction shall correspond to the train orientation defined by the active (virtual) cab as defined in 2.5.1, i.e. when the direction controller is in forward

<!-- end of page 16 -->

   - position, this means that the train movement will be in the direction of the active (virtual) cab.

2.5.2.3 If no cab is active the direction controller information may have any value, but shall be ignored by ERTMS/ETCS on-board.

2.5.2.4 Note: The direction controller input is used by ERTMS/ETCS on-board to prevent train movement which conflicts with the current position of the direction controller in the active cab and to detect the driver's intention to reverse, which is one of the conditions for entering Reversing mode. The direction controller input is also used by an STM as defined in [3].

2.5.2.5 The following requirements shall apply to the rolling stock:

2.5.2.5.1 If the ERTMS/ETCS on-board is connected to more than one cab, it is the responsibility of the rolling stock to relate the direction controller information to the active cab.

### **2.5.3 Train integrity**

2.5.3.1 The train integrity information is defined as a three state input with the following values:

   - Train integrity confirmed

   - Train integrity lost

   - Train integrity status unknown.

2.5.3.2 The following requirements shall apply to the rolling stock:

2.5.3.2.1 In case of detected train split (intentional or unintentional) or a train joining, the vehicle shall provide the information “Train integrity lost”.

2.5.3.2.2 Note: If the train integrity information fails it can be mitigated by detecting a change of the train length (see clauses 2.6.2.4.2 and 2.6.3.2.1).

### **2.5.4 Traction status**

2.5.4.1 The traction status information is defined as a two state input with the following values:

   - On

   - Off.

2.5.4.2 Note: This traction status information is forwarded by the ERTMS/ETCS on-board to the STM.

### **2.5.5 Set Speed**

2.5.5.1 The set speed information is defined as a two state input plus a numerical value input:

   - Display set speed information

   - Do not display set speed information

   - A speed value within the range from 0 to 600 km/h with a resolution of 1 km/h.

2.5.5.1.1 Note: The set speed input is used by ERTMS/ETCS on-board only for display on the DMI.

<!-- end of page 17 -->

## **2.6 Train Data**

### **2.6.1 Type of train data entry**

2.6.1.1 The type of train data entry information is defined as a three state input with the following values:

   - Fixed

   - Flexible

   - Switchable.

### **2.6.2 Overall consist length information**

2.6.2.1 The “overall consist length” information is an input that contains the following information:

   - Whether the overall length of the consist is available.

   - If the answer to the above question is yes, the following information is provided:

   - The nominal, min and max consist lengths on the side of the engine corresponding to cab A, counted from the end of the engine corresponding to the orientation of this cab A

   - The nominal, min and max consist lengths on the side of the engine opposite to cab A, counted from the end of the engine corresponding to the orientation of this cab A

2.6.2.2 In order to form the “safe consist length” information, the ERTMS/ETCS on-board equipment shall by default use as such the above values in 2.6.2.1 2<sup>nd</sup> bullet/3<sup>rd</sup> bullet to determine the nominal, min and max consist lengths in front of/in rear of the engine respectively. If there is more than one cab connected to a single ERTMS/ETCS on-board unit and the active cab (or the last active cab) is the cab B, the ERTMS/ETCS on-board equipment shall otherwise derive the nominal, min and max consist lengths in front of/in rear of the engine by subtracting/adding the engine length from/to the above values in 2.6.2.1 3<sup>rd</sup> bullet/2<sup>nd</sup> bullet respectively.

2.6.2.3 Note: For all types of trains, when no valid Train Data is stored on-board, the availability of the “safe consist length” information is a prerequisite for the ERTMS/ETCS on-board equipment being able to deliver position reports with train integrity confirmed and is a prerequisite to perform a mission with the ERTMS/ETCS on-board equipment in Supervised Manoeuvre mode.

2.6.2.4 The following requirement shall apply to the rolling stock:

2.6.2.4.1 For a given train composition, the min and max values for the consist length on both sides of the engine shall be fixed and shall differ from the nominal length value to an extent which is due to the coupling play between the different vehicles of the consist and/or to any other uncertainties in the consist length information.

2.6.2.4.2 The vehicle shall provide an updated train length following a change in the train composition.

### **2.6.3 Other train data information**

2.6.3.1 The other train data information is an input that enables the ERTMS/ETCS on-board equipment to determine values for one or more of those following items of train data referred to in §3.18.3.2 of [1]:

<!-- end of page 18 -->

2.6.3.1.1 Train Category Cant Deficiency

2.6.3.1.2 Train length

2.6.3.1.3 Traction / brake parameter set

2.6.3.1.3.1 The traction /brake parameter set is composed by:

   - Traction model

   - Brake build up time model and speed dependent deceleration model

   - Brake percentage

   - Brake position

   - Nominal rotating mass

2.6.3.1.4 Maximum train speed

2.6.3.1.5 Loading gauge

2.6.3.1.6 Axle load category

2.6.3.1.7 Traction system(s) accepted by the engine

2.6.3.1.8 Train fitted with airtight system

2.6.3.2 The following requirement shall apply to the rolling stock:

2.6.3.2.1 The vehicle shall provide an updated train length following a change in the train composition.

2.6.3.3 The acquisition of train data information from the train interface is an optional feature for the ERTMS/ETCS on-board equipment.

**2.6.3.4 Data not provided via Train Interface**

2.6.3.4.1 The additional train data listed in §3.18.3.2 of [1] are not part of train data by external sources. Axle Number is a purely static data element and is set only by configuration in the ETCS on-board. The List of National Systems Available On-board is out of scope of the standardized train interface. “Other international train category” is not transferred via Train Interface since “brake position” input is transferred.

2.6.3.4.2 Correction factors for the emergency deceleration shall not be transmitted via Train Interface. This data is pre-configured in the ETCS on-board (linked to each EB speed dependent deceleration model, see [1] 3.13.2.2.9.1.2).

2.6.3.4.3 Correction factor for gradient on normal service deceleration shall not be transmitted via TI. This data is pre-configured in the ETCS on-board.

### **2.6.4 Ways to provide train data information via train interface**

2.6.4.1 Overall consist length information and the other train data can be provided to the ETCS on-board via Train Interface in the following ways:

   - The train data themselves.

   - The train data are derived from “type of train configuration”. This identifier is used by the ETCS on-board for the selection of the appropriate train data set among the preconfigured ones.

<!-- end of page 19 -->

2.6.4.2 The type of train configuration information is defined as a numerical value.

2.6.4.3 For each train data it shall be configurable if the train data shall be provided from preconfigured values or from the driver according to “type of train data entry” information or via train interface with the train data themselves or via train interface derived from the “type of train configuration” information.

2.6.4.4 If train data cannot be provided via train interface ERTMS/ETCS on-board shall only consider the train data variables from pre-configured values or from the driver.

## **2.7 Additional Data**

### **2.7.1 Train running number**

2.7.1.1 The train running number information is defined as a numerical value input:

A value within the range from 0 to 9999 9999 with a resolution of 1.

## **2.8 National System isolation**

2.8.1.1 The National System isolation information is defined as a two state input with the following values:

   - NTC isolated

   - NTC not isolated.

2.8.1.2 A NTC isolation input shall be used by the ERTMS/ETCS on-board equipment in case it is interfaced to the National System through an STM and this National System requires isolation of the STM to be implemented.

## **2.9 Reference of functions**

2.9.1.1 The following tables give the SRS, DMI, STM subsets references for each function on the Train Interface and the direction of the information (Input / Output of the ERTMS/ETCS on-board).

|**Chapter**|**Name**|**Reference in**<br>**SRS [1]**|**Input /**<br>**Output**|
|---|---|---|---|
|2.2.1|Sleeping|4.4.6 / 4.6.3|Input|
|2.2.2|Passive shunting|4.4.20 / 4.6.3|Input|
|2.2.3|Non-Leading|4.4.15 / 4.6.3|Input|
|2.2.4|Isolation|4.4.3.1.1|Output|
|2.2.5|Automatic Driving|4.4.16|Output|
|2.2.6|Remote Shunting|4.4.8.1.4 /<br>4.4.21.1.13|Output|

<!-- end of page 20 -->

|**Chapter**|**Name**|**Reference in**<br>**SRS [1]**|**Input /**<br>**Output**|
|---|---|---|---|
|2.3.1|Service brake<br>command|3.13.2.2.7|Output|
|2.3.2|Brake pressure|3.13.2.2.7 /<br>A.3.10|Input|
|2.3.3|Emergency brake<br>command|3.13.10 / 3.14.1<br>/ 4.4.4 / 4.4.5 /<br>4.4.13|Output|
|2.3.4|Special brake inhibition<br>area|3.12.1|Output|
|2.3.6|Special brake status|3.13|Input|
|2.3.7|Additional brake status|3.13|Input|
|2.4.1|Change of traction<br>system|3.12.1|Output|
|2.4.2|Powerless section with<br>pantograph to be<br>lowered|3.12.1|Output|
|2.4.4|Air tightness area|3.12.1|Output|
|2.4.6|Station platform|3.12.1|Output|
|2.4.7|Powerless section with<br>main power switch to<br>be switched off|3.12.1|Output|
|2.4.9|Traction Cut Off|3.13.2.2.8|Output|
|2.4.10|Change of allowed<br>current consumption|3.12.1|Output|
|2.4.11|Engine orientation in<br>Supervised Manoeuvre|4.4.21.1.13|Output|
|2.5.1|Cab Status|4.6.3|Input|
|2.5.2|Direction Controller|3.14.2 / 5.13.1.4|Input|
|2.5.3|Train integrity|3.6.5.2|Input|
|2.5.5|Set Speed|4.7.2|Input|
|2.6.2|Overall consist length<br>information|3.18.3|Input|
|2.6.2.4.2|Other train data<br>information|3.18.3 / 5.17|Input|

<!-- end of page 21 -->

|**Chapter**|**Name**|**Reference in**|**Input /**|
|---|---|---|---|
|||**SRS [1]**|**Output**|
|2.7.1|Train running number|3.18.4.5|Input|

**Table 1 –SRS references**

|**Chapter**|**Name**|**Reference in**|**Input /**|
|---|---|---|---|
|||**DMI [2]**|**Output**|
|2.5.5|Set Speed|8.2.3.9|Input|
|2.6.1|Type of train data entry|10.3.9.6|Input|

**Table 2 – DMI references**

|**Chapter**|**Name**|**Reference in**<br>**STM [3]**|**Input /**<br>**Output**|
|---|---|---|---|
|2.3.1|Service brake<br>command|5.2.5|Output|
|2.3.3|Emergency brake<br>command|5.2.5|Output|
|2.3.5|Special brake inhibit|5.2.4.3|Output|
|2.4.3|Pantograph|5.2.4.3|Output|
|2.4.5|Air tightness|5.2.4.3|Output|
|2.4.8|Main power switch|5.2.4.3|Output|
|2.4.9|Traction Cut Off|5.2.4.3|Output|
|2.5.1|Cab Status|5.2.4.4|Input|
|2.5.2|Direction Controller|5.2.4.4|Input|
|2.5.3.1|Traction status|5.2.4.4|Input|
|2.8|National System<br>isolation|10.3.3.5,<br>10.3.3.6 e),<br>10.14.1.2|Input|

**Table 3 – STM references**
