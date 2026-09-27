# **6 On-board Equipment**

## **6.1 Architectural Layouts**

The On-board Transmission Equipment is part of the ERTMS/ETCS On-board Constituent, and has the main functions to generate Tele-powering signals to the Balise, to receive and process Up-link signals from the Balise, to constitute the interface between the air-gap (Interface ‘A’) and the ERTMS/ETCS Kernel, and to provide applicable test data to the Test Interfaces via an Interface Adapter.

The On-board Transmission Equipment includes an Antenna Unit, and a functional block denominated the BTM function.

<!-- Start of picture text -->
ERTMS/ETCS<br>ERTMS/ETCS<br>On-board<br>Kernel<br>Constituent<br>Test<br>Interfaces<br>BTM function Interface<br>On-board<br>Adapter<br>Transmission<br>Equipment<br>Antenna Unit<br>Tele-powering Up-link<br>Signal Signal<br><!-- End of picture text -->

**Figure 41:  On-board Transmission Equipment and its main interfaces**

## **6.2 Antenna Air-gap Interface**

### **6.2.1 Tele-powering Energy Transmission**

### 6.2.1.1 Transmission Medium

The On-board Antenna Unit shall provide power to the wayside Up-link Balises by generating a magnetic field. This field shall be produced in a transmit loop of the Antenna Unit, and induce a voltage in a reception loop of the Up-link Balise.  The induced voltage in the Balise shall be based mainly on the vertical component of the magnetic field that flows through the Balise loop.

A Standard Size Up-link Balise and a Reduced Size Up-link Balise exist.  The definition of Balise size is related to the size of the reference area that the performance of the Balise is related to.  The field distribution from the Antenna Unit shall be such that an Up-link Balise gets enough power to be able to provide an output signal forming the contact volume for the Antenna Unit in question.  This also relates to the specific Up-link Balise (Reduced or Standard Size) and the specific conditions.

<!-- end of page 110 -->

### 6.2.1.2 Tele-powering Electrical Data

#### **6.2.1.2.1 CW Tele-powering signal**

The magnetic field shall be produced at a frequency of 27.095 MHz with a tolerance of ±5 kHz.

The signal shall be a continuous wave (CW).  The carrier noise shall be < -110 dBc/Hz at frequency offsets  10 kHz.

#### **6.2.1.2.2 Toggling Modulation**

For interoperable systems, the On-board Transmission Equipment shall be able to pulse width modulate the Tele-powering carrier signal by a 50 kHz synchronisation signal according to clause D1 of Annex D on page 143.

Only one kind of modulation may take place at any given time of operation.  See sub-clauses 4.2.6 on page 31, and 4.2.7 on page 31.

#### **6.2.1.2.3 Intentionally Deleted**

### 6.2.1.3 Compatibility Requirements on the Tele-powering signal

The On-board Transmission Equipment shall transmit a 27 MHz CW Tele-powering signal when passing over KVB, Ebicab, or RSDD Balises in order not to be disturbed by these Balises.<sup>45</sup>

In order to achieve compatibility with old types of KER Balises, the maximum flux from the On-board Transmission Equipment shall be 200 nVs in a Standard Size Reference Area positioned at a vertical distance of 93 mm below the top of rail.  Alternatively, the maximum flux level 140 nVs applies in a Standard Size Reference Area positioned at a vertical distance of 150 mm below the top of rail.  The respective flux levels refer to a CW Tele-powering flux level where the KER Balises shall not be destroyed or degraded.

For the purpose of testing, the minimum absolute value of the complex impedance of the KER Balise is assumed to be 40  , measured at a flux level of 3 dB below the respective maximum flux levels (i.e., 140 nVs and 100 nVs respectively).

The heights refer to the vertical position of the Standard Size Reference Area, and during testing the Test Antenna shall be positioned at respectively 220 mm and 277 mm above the KER Balise.

### 6.2.1.4 Antenna Unit and Balise interaction

See sub-clause 5.2.2.3 on page 57.

The On-board Transmission Equipment shall guarantee that, in all possible operational conditions, the magnetic flux concatenated with the Balise reference areas (standard size, reduced size, and reduced size with transversal installation) never exceeds the applicable  d4 value (see sub-clause 5.2.2.6 on page 63), in both CW and toggling mode, when the Balise impedance fulfils the requirements of sub-clause 5.2.2.6 on page 63.

> 45  A KVB, RSDD, or Ebicab Balise might transmit one or two bits (at an ASK modulated data rate of 50 kbit/s) before it turns silent again.  This shall not affect the BTM function.

<!-- end of page 111 -->

### 6.2.1.5 Tele-powering Field Distribution

The field distribution from the Antenna Unit shall be such that the Balise gets enough power to be able to provide an output signal forming the Contact Volume for the Antenna Unit in question.  This also relates to the specific Balise (Reduced Size or Standard Size), and the specific conditions.

The field strength from the Antenna Unit shall be defined as the total flux into a Balise reference area placed in any position relative to the Antenna Unit in accordance with sub-clause 5.2.2.4 on page 58.  The total flux through this area can be measured by a calibrated Reference Loop (see sub-clause 5.2.2.4 on page 58).  The input signal to the Balise, for different positions relative to the Antenna Unit, is the flux through the Reference Area in accordance with sub-clause 5.2.2.4 on page 58.

The deviation of the field form from the Antenna Unit, due to debris and proximity of conductive material, relative to the field form in free air, shall be considered in the Antenna Unit design (see also sub-clause 5.2.2.5 on page 59).

Debris and the proximity to conductive material may influence the efficiency of the Antenna Unit itself.  Such influence shall be within the specified limits for the performance of the Antenna Unit.

The levels of debris, nominated as Class A and Class B layers, are defined herein.  The Antenna Unit design shall be such that both Class A and Class B Balises are properly handled.

### 6.2.1.6 Procedure control and Error Handling

Side lobes shall be handled by the BTM function based on the received signals from Interface 'A1', and on the time and odometer information.

The On-board Transmission Equipment shall normally use the lobe where the Antenna Unit and the Balise are aligned to each other (in the case of stopping over a preceding side lobe, the received data may be passed on to the ERTMS/ETCS Kernel after a time-out, see sub-clause 6.2.2.5 on page 115).  This lobe is called the main lobe.  Outside this lobe, the magnetic flux through the reference area of the Balise changes sign, and a side lobe is generated by the Antenna Unit.  If the flux in this side lobe is strong enough to activate the Balise, the Balise may respond with an Up-link signal.  The filtering of this Up-link signal shall be made by the BTM function. The activation of the Balise before or after the main lobe shall not disturb the transmission in the main lobe.

The On-board Transmission Equipment shall filter the lobes of data transmission based on the physical properties of the Balise signal, and on the following Balise configuration data given by the Balise telegram: M_VERSION, NID_C, NID_BG, N_PIG and, if present<sup>46</sup> , NID_VBCMK (see SUBSET-026).  The field distribution and the design of the Antenna Unit may generate more than one lobe while passing a Balise.  Thus one Balise may be interpreted as two or more Balises.  Consequently, even if more than one lobe has been received from one Balise, the BTM function shall report to the ERTMS/ETC Kernel that only one Balise has been passed.

The level of field strength from the Antenna Unit that is needed to activate the Balise in the contact volume required for Balise detection shall be supervised by the On-board Transmission Equipment.  If the transmitted level of the Tele-powering signal is so low that Balises may not be detected by the On-board Transmission Equipment, this is an error and shall be detected by the On-board Transmission Equipment.  If the level of the Tele-powering signal is so high that it may generate cross-talk, this error shall be detected by the On-board Transmission Equipment.

An alternative to the ability of detecting these errors is that the errors are shown to have a low enough probability to occur.

46    If M_VERSION = 2.0, 2.1, 2.2, 2.3 or 3.0, NID_VBCMK is part of the optional packet 0 appended to the header

If M_VERSION = 1.1, NID_VBCMK is part of the optional packet 200 appended to the header If M_VERSION = 1.0, NID_VBCMK does not exist

<!-- end of page 112 -->

### 6.2.1.7 Metal Masses outside of the specified Metal Mask

In general, there could be metallic objects in the track that might obstruct the ability of the On-board Transmission Equipment to check that it can detect a Balise.  However, objects complying with the criteria in sub-clause 6.5.2 on page 125 shall not impact the On-board Transmission Equipment from this perspective.  This is further dealt with in sub-clause 6.2.1.8.

While passing a metal mass that is outside the specified metal mask<sup>47</sup> according to Table 18 on page 125, the On-board Transmission Equipment shall be allowed to give an alarm to the ERTMS/ETCS Kernel.  The ERTMS/ETCS Kernel shall ignore this alarm by having been informed in advance, e.g., by the appropriate Balise information.

The metal mass is considered outside the allowed mask if:

- Being positioned higher than specified in Table 18.

- Having a larger width than specified in Table 18, and the object is positioned in the range between the specified maximum height and 50 mm below the specified maximum height.

- Having a length exceeding 10 m, and being positioned in the range between the specified maximum height and 50 mm below the specified maximum height.

The distance from the end of such a metal mass to the centre of a Balise shall exceed<sup>48</sup> :

db [m]  0.2 [s] • Maximum Permitted Speed [km/h] / 3.6

Other metallic objects important for the air-gap transmission (but not having impact on obstructing the ability of the On-board Transmission Equipment to check that it can detect a Balise) are defined in sub-clause 5.7.10 on page 95.

### 6.2.1.8 Metal Masses and Distances to Balises

In the presence of metallic objects according to category 1 of sub-clause 6.5.2 on page 125, the distance dobject in longitudinal direction from this metallic object to the centre of a nearby Balise shall be according to the following equation<sup>49</sup> , where the length of the metallic object is lobject:

For metallic objects according to category 2 of sub-clause 6.5.2 on page 125, the distance dobject in longitudinal direction from this metallic object to the centre of a nearby Balise shall be according to the following equation.

dobject ≥ 1.1 m

For metallic objects according to category 3 of sub-clause 6.5.2 on page 125, the normal Balise installation requirements according to sub-clause 5.7.10.1 on page 95 apply.

> 47 For example a metal bridge.

> 48 It shall be allowed for the On-board Transmission Equipment to use 200 ms to recover its normal function, the ability to detect and read Balises, when the influence from the metal mass has disappeared.

> 49 The equation is considering the maximum acceleration of the train.

<!-- end of page 113 -->

### **6.2.2 Up-link Data Reception**

### 6.2.2.1 Up-link Balise Detection

The On-board Transmission Equipment shall ensure that it is able to detect Balises in accordance with subclause 6.4.5 on page 118.  The only exception shall be when there is full safety protection by other means on system level.  One example is related to situations where large metallic objects are being passed (see sub-clause 6.2.1.7 on page 113).

It is a requirement that there is a threshold within the BTM function that is based on a voltage representing the received field strength.  The actual implementation is supplier dependent.  It shall be possible to verify this threshold (hereafter referred to as Vth) using a certain current encircling the borders of the specified reference area positioned in a defined geometrical position.  It is not a requirement that the actual threshold voltage level is available (but the function is subject to verification).

The BTM function shall not deliver any received telegram to ERTMS/ETCS Kernel when the received field strength is lower than a threshold value of Vth.  Vth shall be set to correspond to a field that is generated by the current Iuth encircling the borders of the specified reference area in the geometrical worst case position. The value of the field strength that corresponds to the current Iuth depends on the size and orientation of the specified reference areas (two different sizes with two different orientations for the smaller size reference area are possible), and on the design of the Antenna Unit.<sup>50</sup> The level is fundamental for the cross-talk protection and the detection of the Balise.

The BTM function shall detect a Balise when the field strength from the Balise is higher than Vth during a minimum time TDET.  TDET may vary with the speed and it depends on the design of the Antenna Unit.

### 6.2.2.2 Telegram Reception

The BTM function shall be able to receive a telegram from a Balise in the Contact Volume.

The distance in the X direction above the Balise where reliable transmission shall take place shall be longer than the minimum required contact length, in which the coding requirements and the dynamic start-up times for the Balise and the On-board Transmission Equipment are taken into account.

The contact length S shall be:

S  > V · (R·TBL+ TBAL+ TBTM + TREL)   (see footnote<sup>51</sup> )

- V = The maximum specified speed for the combination of Antenna Unit, Balise, and telegram length.

- R = A factor for safe reception of a telegram.  It will correspond to a number of extra bits, which is defined by the coding requirements.

- TBL = The transmission time for the longer and the shorter telegram respectively.

- TBAL = The start-up time for the Balise.

- TBTM = The start up time for the BTM function and Antenna Unit together.

- TREL = Extra time that is needed to have the required reliable transmission.<sup>52</sup>

For the On-board receiver, both the MTIE requirements of Figure 9 on page 55 and Figure 10 on page 55 apply.

> 50  This means three values of Iuth for each type of Antenna Unit.

> 51  The terms R, TBTM, and TREL shall be defined by the manufacturer of the equipment.

> 52  The time TREL shall be considered and set by the user of the system, taking into account the desired availability of the system with respect to the expected level of external noise that may disturb the transmission.

<!-- end of page 114 -->

### 6.2.2.3 Decoding Requirements

See sub-clause 4.3 on page 36.

### 6.2.2.4 Reporting

After the Balise passage, both data and reference position shall be made available to the ERTMS/ETCS Kernel. Different telegrams, possibly received during a telegram switching, are not normally required to be reported.  If more than one valid telegram is received by the On-board Transmission Equipment from a single Balise (due to telegram switching), then only one telegram with the appropriate location information should be reported to the ERTMS/ETCS Kernel.  The choice of the reported telegram is free.

In general, the BTM function shall report Balise detection to the ERTMS/ETCS Kernel when a Balise is detected but no telegram is decoded.  In particular, a continuous transmission of only logical ‘0’ or ‘1’ shall be reported in the same way.

### 6.2.2.5 Reporting at low speed (Informative Only)

In case of Balise passage at low speed, more telegrams (due to telegram switching) may be reported for the same Balise.

Under circumstances where the Balise is not passed within the reporting period from the start of the transmission, then the BTM function should make preliminary location reference information and data available to the ERTMS/ETCS Kernel after a time-out of the reporting period after the start of transmission.<sup>53</sup> The location reference information should be made available each reporting period as long as the Balise has not been passed. In the event that the functionality is not implemented for operational purposes, it could exist for the purpose of test and verification.

The reporting period could be between 50 ms and 600 ms.

> 53 Under circumstances when the vehicle has stopped, for example with the Antenna Unit over the first side lobe of the Balise, then the preliminary location reference may be made available to the ERTMS/ETCS Kernel after a time-out of the reporting period, and it may be based on the side lobe information.

<!-- end of page 115 -->

### 6.2.2.6 Cross-talk Conditions

Cross-talk protection is based on the following properties regarding the Antenna Unit and its accompanied installation rules:

- Company specific geometrical conditions for the Antenna Unit (height, and lateral and angular displacements in free air).

- Company specific maximum transmitted levels of field strength.

- Company specific minimum receiving threshold.

- Maximum input-to-output characteristics specified for the Balise.

- Maximum conformity deviation for Up-link in the cross-talk zone of the Balise.

- The assumption that the deviation of the conformity for Tele-powering in the cross-talk zone (for the purpose of cross-talk protection demonstration) is respecting the B value as specified in the side-lobe zone (see sub-clause 5.2.2.5 on page 59).

- The assumption that the provisions specified in sub-clause 5.7.10.4 on page 99 regarding Guard Rail are sufficient to avoid any influence related to cross-talk.

- The influence of cables in the track under all conditions is limited according to sub-clause 6.6.10 on page 130.

- The fulfilment of the company specific installation rules.

The worst case condition when two Antenna Units are involved is that the output signal level of the Balise equals the horizontal line Iu3 (independent of the Antenna output field strength of the Antenna Unit that has the Balise in its cross-talk protected zone).  In free air propagation, the conformity tolerance B in Figure 14 on page 60 and Figure 15 on page 61shall be considered for the Balise for Up-link in the Balise cross-talk zone.

## **6.3 Intentionally Deleted**

<!-- end of page 116 -->

## **6.4 RAMS Requirements**

### **6.4.1 On-board Transmission Equipment functionality**

Table 16 below defines the functionality of the On-board Transmission Equipment, together with a linking to the top-level functionality of sub-clause 4.4.2 on page 42 and top-level hazards of sub-clause 4.4.6.3 on page 46.<sup>54</sup> Optional functions and barriers defined in sub-clause 4.1.4 on page 24 are intentionally excluded.

|**On-board functionality:**|**Related top-level**<br>**functions**|**Related top-level**<br>**hazards**|
|---|---|---|
|Generation of correct Tele-powering signal|F1, F2|H1, H3, H5, and H6 apply|
|Detection of Up-link Balises|F1|H1, H2, and H3 apply|
|Up-link signal filtering and demodulation|F1, F2|H1, H3, H4, H5, and H6<br>apply|
|Physical Cross-talk protection|F1, F2, F3, F4|H2, H7, H8, and H9 apply|
|Physical prevention of transmission of Side lobes,<br>and/or management of Side lobe effects in data and<br>in location|F2, F3, F4|H5, H7 and H8 apply|
|Immunity to environmental noise|F1, F2|H1, H2, H4, H5, and H6<br>apply|
|Checking of Up-link incoming data with respect to<br>Coding Requirements|F2|H4, H5, and H6 apply|
|Detection of telegram type and decoding|F2|H4, H5, and H6 apply|
|Extraction of user data|F2|H4, H5, and H6 apply|
|Telegram Filtering|F2|H4, H5, and H6 apply<sup>55</sup>|
|Management of Up-link telegram switching within<br>a Balise passage|F2|H4, H5, and H6 apply|
|Time and odometer stamping of output data|F3, F4|H7 and H8 apply|
|Support for Balise Localisation (for vital and non-<br>vital purposes)|F3, F4|H7 and H8 apply|
|Detection of Bit Errors|F2|H4, H5, and H6 apply|

**Table 16:  On-board Transmission Equipment functionality and related top-level hazards**

The hazards H2, H3, H5, and H6 are not explicitly quantified for reasons mentioned in sub-clause 4.4.6.3 on page 46.  For hazard H4, see also the concept of the non-trusted channel in sub-clause 4.4.6.4 on page 47.

> 54 Only the defined functionality is mandatory, but not a specific structure or design solution.

> 55 For example, a decision based on longer duration of sufficient quality will reduce the probability of H4.

<!-- end of page 117 -->

### **6.4.2 Reliability**

See sub-clause 4.4.3 on page 42.

### **6.4.3 Availability**

See sub-clause 4.4.4 on page 43.

### **6.4.4 Intentionally Deleted**

### **6.4.5 Safety**

### 6.4.5.1 Hazards and Failure Trees

The top-level hazards defined in sub- clause 4.4.6.3 on page 46, and the related Balise functionality of Table 16 in sub-clause 6.4.1 on page 117, are apportioned and broken down as follows.  How each failure contributes to the respective hazards HXOB is company specific, and dependent on implementation of suitable barriers.  However, the quantification of sub-clause 6.4.5.2 on page 122 shall be fulfilled.  Shaded boxes below include functionality belonging to the platform, which are not included in the quantification of sub-clause 6.4.5.2.

###### **H1OB: A Balise Group is not detected**

Erroneous generation of Tele-powering signal Insufficient immunity to environmental noise Erroneous Balises detection functionality Erroneous Up-link signal filtering and demodulation

#### **Figure 42:  Balise Group Detection**

###### **H2OB: Erroneous reporting of Balise Detection**

Insufficient immunity to environmental noise Erroneous Balise detection functionality Insufficient physical cross-talk protection

#### **Figure 43:  Erroneous Reporting of Balise Detection**

<!-- end of page 118 -->

**Figure 44:  Erroneous Reporting of Balise Detection in presence of KER Balise**

**Figure 45:  Erroneous telegram interpretable as correct**

<!-- end of page 119 -->

**Figure 46:  Loss of telegram for full performance**

**Figure 47:  No transmission of Default Telegram**

<!-- end of page 120 -->

**Figure 48:  Erroneous Localisation**

**Figure 49:  Order of reported Balises is erroneous**

**H9OB: Erroneous reporting of Balises in a different track** Insufficient physical cross-talk protection

**Figure 50:  Reporting of Balises in a different track**

<!-- end of page 121 -->

### 6.4.5.2 Quantification

Table 17 defines the requirements that shall be fulfilled for the On-board Transmission Equipment hazards of sub-clause 6.4.5.1 on page 118, when assuming that the specified maintenance is fulfilled.

|**No.**|**Hazard Description**|**[f/h]**|
|---|---|---|
|H1OB|A Balise Group is not detected<sup>56</sup>|SUBSET-091, ETCS_OB07 denominated<br>Failure of Balise Group Detection.|
|H2OB|The On-board Transmission Equipment erroneously<br>reports that it has detected a Balise|-|
|H3OB|The On-board Transmission Equipment erroneously<br>reports detection of a Eurobalise in presence of a<br>KER Balise|-|
|H4OB|Transmission of an erroneous telegram interpreta-<br>ble as correct|SUBSET-091, ETCS_OB06 denominated<br>Corruption of Balise Message.|
|H5OB|Loss of the telegram, from a certain Balise, intend-<br>ed for full performance|-|
|H6OB|No transmission of Default Telegram in case of<br>wayside failures|-|
|H7OB|Erroneous localisation of a Balise with reception of<br>valid telegram|See requirements for O1 and O2 below, and<br>further explanations in Annex F.|
|H8OB|The order of reported Balises, with reception of<br>valid telegram, is erroneous|See requirements for O1 and O2 below, and<br>further explanations in Annex F.|
|H9OB|Erroneous reporting of a Balise in a different track,<br>with reception of valid telegram|See requirements for O1 and O2 below, and<br>further explanations in Annex F.|

#### **Table 17:  Quantification for On-board Transmission Equipment**

From the overall requirements in SUBSET-091 and the methodology of Annex F, the following mandatory requirements on unavailability apply:

O1  10<sup>-6</sup>

O2  10<sup>-6</sup>

O1 means that the On-board equipment is more sensitive than expected.  It is assumed that it can not be more than 30 dB sensitive than a fault free equipment.

O2 means that the On-board equipment is transmitting more Tele-powering field than specified.  It is assumed that it can not transmit more than 10 dB higher field than specified (i.e., not more that  d4 +10 dB).

The hazards H7OB, H8OB, and H9OB are caused by failures in the threshold function of the On-board Transmission Equipment and/or significantly excessive Tele-powering signal.

> 56 A Balise group, which contains information that if it is missed could lead to a hazardous consequence, shall consist of a minimum of two Balises.  See ETCS_TR07 in SUBSET-091.

<!-- end of page 122 -->

The quantification of Hazard H4OB does not include the non-trusted channel (see sub-clause 4.4.6.4 on page 47).

The figures might originate from a hardware failure, and is thus dependent on MTTR (including the detection time) and the actual failure frequency.  The combination of these aspects is the sums quantified in Table 17 above.<sup>57</sup>

The hazards H2OB, H3OB, H5OB, and H6OB are not explicitly quantified for reasons mentioned in sub-clause 4.4.6.3 on page 46.

### 6.4.5.3 Independence of hazard causes

For some of the hazards, dependencies also have to be considered when calculating the figures of Table 17 on page 122.

Crosswise unavailability of each type of hazard is independent between the On-board Transmission Equipment and the Balise.

Effects of faults shall be analysed in the presence of noise from the air-gap.  If the actual worst case noise situation is known, then the faults shall be analysed against this known noise effect, otherwise if the effect is unknown then any ratio of random decoded bit error rate shall be analysed.

### 6.4.5.4 Conditions/Assumptions

The apportionment of the figures of Table 17 on page 122 is based on the following presumptions:

- The Mean Time to Restore (MTTR) is irrelevant for the purpose of the quantification included in subclause 6.4.5.2 on page 122 (a faulty On-board Transmission Equipment results in the vehicle being taken out of operation).

- The mean time for detection of On-board Transmission Equipment failures is company specific, and might differ between the various hazards of sub-clause 6.4.5.2 on page 122.  The Mission Profile defined in higher system level documentation shall be considered in the company specific choices.

- The dependencies with air-gap related aspects shall be considered.  See sub-clause 4.4.6.5 on page 48.

- H5OB and H6OB means that a physical Balise is either detected or undetected, and that the telegram in question is corrupted and/or not transmitted (i.e., H5OB and H6OB are always more probable than H1OB).

- H6OB is assumed to be identical to H5OB from an On-board Transmission Equipment standpoint (the On-board Transmission Equipment is transparent from a telegram contents standpoint).

- H8OB and H9OB are implicitly also included in the case that the Balise is erroneously located (i.e., the figures H8OB and H9OB are always lower than the figure H7OB).

- Erroneous localisation in H7OB means that the requirements of sub-clause 4.2.10.2 on page 35 are not fulfilled.

- Only random aspects are included.

<!-- end of page 123 -->

- The Basic Receiver defined in sub-clause 4.3.4 on page 41 is assumed to be implemented.  In case of other receiver principles, the entire analysis included herein needs to be re-considered.

- The On-board Transmission Equipment functionality is an integrated part of the ERTMS/ETCS Constituent.  The quantified hazards for the On-board Transmission Equipment (Table 17 on page 122) include potential contribution from dependencies with other On-board functions.  For example, assume that in a specific design of an On-board Transmission Equipment the BTM functionality is dependent on information from other functional blocks within the ERTMS/ETCS Constituent (that generates e.g., odometer data or time information), then the specified value of Table 17 includes the effect of this dependency.

- All figures are based on mean detection times.  The analyses should be supported by sensitivity analyses wherever deemed necessary.

The following aspects are not within the scope of the quantification of Table 17 on page 122:

- Vandalism

- Exceptional occurrences (e.g., exceptional environmental conditions outside specification)

- Erroneous installation

- Erroneous maintenance

- Occupational Health

- Mechanical damage due to maintenance (causing conditions outside specification)

The quantification should, as far as possible, be based on data acquired by experience.  If such data is not available, data from MIL-HDBK 217 or other similar recognised database should be used.  Data may be tailored considering manufacturer experience (if available), but explicit justifications are required.

<!-- end of page 124 -->

## **6.5 Installation Requirements for Antennas**

### **6.5.1 Reference Axes**

See sub-clause 4.5 on page 50.

### **6.5.2 Metal Masses in the Track**

Metal masses in the track may have a disturbing effect on the On-board Transmission Equipment.  For example, metal masses may obstruct the ability of the On-board Transmission Equipment to check that it can detect a Balise.

For compatibility reasons the On-board Transmission Equipment shall tolerate the following metal masses (i.e., not issue an alarm), and be able to properly detect a Balise compliantly with the installation rules defined in subclause 6.2.1.8 on page 113.

Category 1:

<!-- Start of picture text -->
Antenna Unit<br>w 1 d1<br>w 2 d2<br>w 3<br>d3<br><!-- End of picture text -->

**Figure 51:  Metal masses in the track**

|**Width**|**Highest distance**|
|---|---|
||**from top of rail**|
|w1 120 mm|d1= 92 mm|
|w2 200 mm|d2= 50 mm|
|w3> 200 mm|d3= 0 mm|

**Table 18:  Metal masses in the track, Category 1**

Within this category 1, the length of the object shall not exceed 10 m.  The above defined shapes are considered part of this category if they are positioned in the range between the specified maximum height of Table 18 and 50 mm below the specified maximum height of Table 18.

<!-- end of page 125 -->

Category 2:

|**Width**|**Highest distance**|
|---|---|
||**from top of rail**|
|w1 120 mm|d1= 42 mm|
|w2 200 mm|d2= 0 mm|
|w3> 200 mm|d3= -50 mm|

#### **Table 19:  Metal masses in the track, Category 2**

Within this category 2, there is no restriction on the maximum length of the metallic object.  Objects belonging to this category are wider than 100 mm.  The above defined shapes are considered part of this category if they are positioned in the range between the specified maximum height of Table 19 and 80 mm below the top of the rail.

Approved installation in the vicinity of guard rails is explicitly dealt with in sub-clause 5.7.10.4 on page 99.

Category 3:

This includes all other cases that form less demanding cases.

In case of potential overlapping between categories, the most restrictive case shall apply.

Other restrictions concerning metal masses in the track are handled on a higher system level and are defined in sub-clauses 6.2.1.7 on page 113 and 6.2.1.8 on page 113.

A step by step guideline for determining the relevant category of the object is found in Annex G on page 155.

### **6.5.3 Antenna sizes and Mounting Requirements**

Manufacturer dependent.

<!-- end of page 126 -->

### **6.5.4 Allowed displacements for the Antenna Unit**

The allowed static and dynamic displacements of the Antenna Unit relative to the track should be specified in a table having the following shape.  The reference axes and angles are described in sub-clause 4.5 on page 50.

||**Dynamic**<br>**displacement**|**Static**<br>**position**|**Total dis-**<br>**placement**|||
|---|---|---|---|---|---|
|The minimum vertical distance<br>from the reference marks of the<br>Antenna Unit to the top of rails:|ddd mm|sss mm|ttt mm|||
|The maximum vertical distance<br>from the reference marks of the<br>Antenna Unit to the top of rails:|ddd mm|sss mm|ttt mm|||
|The total maximum lateral devia-<br>tion (L) between the Z reference<br>mark of the Antenna Unit and the<br>centre axis<sup>58</sup>of the track:|ddd mm|sss mm|ttt mm|**L**<br>**Z**||
|Maximum tilting of the Antenna<br>Unit:|y|y|y|**+y º**<br>**-y º**||
|Maximum yawing of the Antenna<br>Unit:|x|x|x|**AU**<br>**Balise**<br>**top view**|**+x º**<br>**-x º**|
|Maximum pitching of the Antenna<br>Unit:|z|z|z|**side view**<br>**running directi**|**+z º**<br>**on**<br>**-z º**|

> 58 The centre axis of the track is located half the distance between the web of the rails. The value of the lateral deviation shall include the influence from lateral rail wear.

<!-- end of page 127 -->

## **6.6 Specific Environmental Conditions for Antennas**

### **6.6.1 Operational Temperature**

The Antenna Unit shall fulfil one of the classes of the sub-clause 4.3 (Temperature) of EN 50125-1.

### **6.6.2 Storage**

During transit and storage, i.e., within a maximum of two weeks, the Antenna Unit should not be damaged by exposure to ambient temperatures in the following range:

Tmin = -40 °C

Tmax = +85 °C

The Antenna Unit should be designed to be held in storage for a maximum period of 5 years without any requirements for test and inspection.  During such storage, the ambient temperature should not exceed the following range.

Tmin = +15 °C Tmax = +35 °C

### **6.6.3 Sealing, Dust and Moisture**

The Antenna Unit enclosures should be designed as to allow correct operation at minimum at the IP65 environmental rating as defined in the EN 60529.

The Antenna Unit should be sealed against the effects of moisture, mould growth and contamination.

### **6.6.4 Mechanical Stress**

The Antenna Unit shall fulfil applicable parts of EN 61373:2010 - Railway applications - Rolling stock equipment - Shock and vibration tests.

### **6.6.5 Meteorological Conditions**

The Antenna Unit shall fulfil applicable parts of sub-clauses 4.4 (Humidity), 4.5 (Air movement), 4.6 (Rain), 4.7 (Snow and Hail), 4,8 (Ice), and 4.9 (Solar Radiation) of EN 50125-1.

### **6.6.6 Chemical Conditions**

The Antenna Unit shall fulfil applicable parts of sub-clause 4.11 (Pollution) of EN 50125-1.

### **6.6.7 Biological Conditions**

The Antenna Unit shall fulfil applicable parts of sub-clause 4.11 (Pollution) of EN 50125-1.

<!-- end of page 128 -->

### **6.6.8 Debris**

Table 20 gives examples of debris under the Antenna Unit.  The manufacturer shall specify the performance of the Antenna Unit and its maximum allowed debris.

|**Material**|**Description**|**Layer below t**<br>**Antenna**|**he bottom of the**<br>**Unit [mm]**|
|---|---|---|---|
|||**Minimum**|**Maximum**|
|Snow|Fresh, 0<sup>o</sup>C|20|top of Balise|
||Wet, 20 % water|10|top of Balise|
|Ice||10|top of Balise|
|Mud|Without salt water|10|50|
||With salt water, 0.5 %<br>NaCl (weight)|-|50|
|Iron Ore|Hematite (Fe2O3)|-|5|
||Magnetite (Fe3O4)|-|5|
|Iron dust|Braking dust|2|5|
|Coal dust|8 % sulphur|-|5|
|Oil and<br>Grease||2|20|

**Table 20:  Examples of debris under the Antenna Unit**

### **6.6.9 Metallic Masses**

The Antenna Unit shall be mounted in such a way that metal is avoided in a well-defined area as specified by the manufacturer.

<!-- end of page 129 -->

### **6.6.10 Cables**

To ensure the proper operation of the Antenna Unit, there are restrictions for cables placed around the Antenna Unit.

The area under the Antenna Unit should be free from cables.

Cables in the area around the Antenna Unit shall be placed at a distance that guarantees that no influence is possible to/from other On-board Transmission Equipment in compliance with the manufacturer installation rules.

The On-board Transmission Equipment shall be able to handle induced currents in cables, in the track underneath the Antenna, from a cross-talk Balise, of:

- Less than 2 mA in the Up-link frequency band when the cable passes the track at a height equal to or lower than 93 mm below the top of the rail.

- Less than 10 mA in the Up-link frequency band when the cable passes the track at a height equal to or lower than 493 mm below the top of the rail.

The above stated current levels are applicable with the return current passing less than 0.5 m underneath the above mentioned cable, simulated by the reference set-up defined in SUBSET-085.

The On-board Transmission Equipment shall limit the induction into suitable test cables, which assume that the return current is passing at 0.5 m below the cable under consideration, so forming a vertical loop underneath the Antenna Unit, and presenting a characteristic impedance of 400  .  The two extremities of the loop shall be closed by the characteristic impedance.  This loop shall be checked with longitudinal and transversal orientation with respect to the Antenna Unit.  The maximum value of the current at the position of best coupling, and at the minimum company specific height for the Antenna Unit, shall be according to one of the classes in Table 21 below.

|Class|Current|
|---|---|
|1|< 10 mA|
|2|< 25 mA|

#### **Table 21:  Maximum induced current (excluding conductive loop cable)**

Class 1 is applicable to a mounting condition where cables between the rails are positioned at a height equal to or lower than 493 mm below the top of the rail.  Class 2 is applicable when cables between the rails are positioned at a height equal to or lower than 93 mm below the top of the rail.

In particular, regarding interaction with the conductive loop cable defined in sub-clause 5.7.10.7.1 on page 105, the following apply.

The On-board Transmission Equipment shall be able to handle induced Up-link currents in the loop cable, from a Balise, not exceeding 0.3 mA.  The centre of the LZB cable is always positioned more than 75 mm below the top of rail during co-existence with Eurobalise.

The above stated current level is applicable using the reference set-up defined in SUBSET-085 (defining an impedance level of 75  and a vertically oriented loop emulating the real LZB cable).

<!-- end of page 130 -->

The On-board Transmission Equipment shall also limit the Tele-powering induction into the reference set-up defined in SUBSET-085.  The maximum value of the current at the position of best coupling, and at the minimum company specific height for the Antenna Unit, shall not exceed:

250 mA in installations where the centre of the LZB cable is always positioned more than 105 mm below the top of the rail.

400 mA in installations where the centre of the LZB cable is anywhere along the track positioned within the interval 75 mm to 105 mm below the top of rail.

The LZB cable shall not be installed higher than 75 mm below the top of the rail when coexistence with Eurobalise is required.

For the purpose of testing, the configuration and test tool defined in SUBSET-085 apply.

It is assumed that existing On-board KER systems do not induce currents exceeding the current levels specified herein.

It is assumed there are only two active On-board systems on a specific loop segment, of which one is intended to read the Balise.

## **6.7 Specific EMC Requirements for Antennas**

### **6.7.1 General**

This considers only aspects related to radiation in the air-gap.

### **6.7.2 In-band Emission**

The in-band emission from the Eurobalise On-board Transmission Equipment, when transmitting CW Telepowering, shall comply with EN 302 608.

For toggling Tele-powering, the frequency mask of sub-clause D1.3 on page 144 applies.

### **6.7.3 Out-band Emission**

The emission from the Eurobalise On-board Transmission Equipment shall comply with EN 302 608.

<!-- end of page 131 -->

### **6.7.4 Eurobalise Transmission Susceptibility**

The manufacturer shall provide information related to the susceptibility of the on-board equipment, to support its integration in the vehicle.  This information should make reference to recognised technical standards.

### **6.7.5 Out-band Susceptibility**

Radiated immunity requirements shall comply with the applicable items of table 9 in clause 8 of EN 50121-3-2. This requirement does neither apply for the frequency band 2.5 MHz to 6.0 MHz, nor for the frequency range  500 kHz centred on the Tele-powering carrier frequency.

## **6.8 Specific Electrical Requirements**

The On-board Transmission Equipment shall comply with the applicable electrical requirements of EN 50155.

## **6.9 Requirements for Test Tools and Procedures**

See SUBSET-085, which includes a complete set of test specifications, test procedures, and test tools regarding the mandatory tests.

## **6.10 Quality and Safety Assurance**

All actions shall comply with the methodology stated in EN 50126, and with the methods stated in EN 50129 and EN 50128.

<!-- end of page 132 -->
