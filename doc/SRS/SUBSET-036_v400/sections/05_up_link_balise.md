# **5 Up-link Balise**

## **5.1 Architectural Layouts**

A Eurobalise is a device that is interrogated and Tele-powered by means of an inductively coupled Telepowering signal, see sub-clause 6.2.1 on page 110.  The response of the Eurobalise is also an inductively coupled Up-link signal, see sub-clause 5.2.2 on page 53.  Source and sink of the Tele-powering signal and the Up-link signal respectively is the vehicle mounted Antenna Unit.

<!-- Start of picture text -->
Up-link signal Tele-powering signal<br>Interface 'C'<br>Eurobalise<br><!-- End of picture text -->

**Figure 8:  Eurobalise and its main interfaces**

The origin of the data carried by the Up-link signal shall be a non-volatile memory in the Eurobalise, or a serial data-link referenced as Interface 'C', see sub-clause 5.3 on page 68.  The data in the non-volatile memory shall be programmable by means of the programming principles of sub-clause 5.4 on page 74.

## **5.2 Balise air-gap Interface**

### **5.2.1 Balise Tele-powering**

### 5.2.1.1 Specification of the Tele-powering signal

An Up-link Balise shall be able to operate compliantly with sub-clause 5.2.2 on page 53 when being powered by a CW Tele-powering signal as specified in sub-clause 6.2.1.2.1 on page 111.

An Up-link Balise shall be able to operate compliantly with sub-clause 5.2.2 on page 53 when being powered by a toggling Tele-powering signal as specified in sub-clause B1.1 of Annex B on page 138.

### 5.2.1.2 Compatibility requirements on the Balise Tele-powering

An Up-link Balise shall be compatible with a Tele-powering signal that is AM modulated by a non-toggling 50 kHz synchronisation signal defined in sub-clause B1.2 of Annex B on page 138.

The compatibility requirements shall be as defined in sub-clause 5.2.2.9 on page 67.

<!-- end of page 52 -->

### **5.2.2 Up-link Data Transmission**

### 5.2.2.1 Transmission medium

The Balise shall generate a magnetic field that shall be picked up by the On-board Antenna Unit.  This magnetic field shall be produced in a transmit loop of the Balise, and shall induce a voltage in a horizontal reception loop of the Antenna Unit.

### 5.2.2.2 Up-link Electrical Data

#### **5.2.2.2.1 General**

The following requirements apply after a start-up time for the Balise of TBAL  s  , as defined in sub-clause 5.2.2.9 on page 67.

#### **5.2.2.2.2 Centre Frequency and Frequency Deviation**

The magnetic field shall produce two frequencies that shall be used for frequency shift keying (FSK) of the Uplink data.  The two frequencies shall nominally be 3.951 MHz for a logical 0 (fL)<sup>18</sup> and nominally be 4.516 MHz for a logical 1 (fH)<sup>19</sup> .  In a shift between the two frequencies the carrier shall have a continuous phase (i.e., continuous phase frequency shift keying modulation shall apply).

- The centre frequency shall be (fH+fL)/2 = 4.234 MHz  175 kHz.

- The frequency deviation shall be (fH-fL)/2 = 282.24 kHz  7 %.

Centre frequency and frequency deviation shall be measured by means of analysing the signal within a sliding window of fixed length.  The signal shall be observed within a band width greater than twice the 10 dB signal band width (i.e., more than 2 MHz).  The total measuring time shall be long compared to the sliding window and in the range of one telegram.  The window itself shall be fairly short compared to the length of a data bit, but long enough to respect the needed band width.

The upper and lower frequencies detected within a 16 bit long sliding window shall be averaged separately for each individual bit, dependent on the decoded bit (i.e., the frequency for decoded “1” bits and “0” bits shall be averaged separately and on a bit by bit basis).  This evaluation should be based on demodulated frequency values sufficiently far from the bit transition regions.  A time period of not more than the time equivalent to one period of the carrier (236 ns) could possibly be ignored around the bit transition if proven practical for test purposes.

Centre frequency shall be calculated as (fLmax+fHmax)/2 and (fLmin+fHmin)/2 within the fixed sliding 16 bit window. Both calculations shall result in compliance with the requirement defined above.

Frequency deviation shall be calculated as (fHmax-fLmin)/2 and (fHmin-fLmax)/2 within the fixed sliding 16 bit window.  Both calculations shall result in compliance with the requirement defined above.

> 18  One ‘0’-bit corresponds to approximately 7 periods of 3.951 MHz.

> 19  One ‘1’-bit corresponds to approximately 8 periods of 4.516 MHz.

<!-- end of page 53 -->

#### **5.2.2.2.3 Mean Data Rate**

The mean data rate is defined as 1500 divided by the length of 1500 consecutive data bits.  For any consecutive 1500 bits, the mean data rate shall be 564.48 kbit/s, with an overall tolerance of  2.5 %, i.e.:

#### **5.2.2.2.4 Data Rate Variation**

After the defined start-up period (TBAL according to sub-clause 5.2.2.9 on page 67), the data rate variation (around the mean data rate, as defined above) and the jitter of the data from the Balise shall fulfil either the MTIE requirement 1 (relative to the theoretical data rate) or the MTIE requirement 2 (relative to the transmitted mean data rate) below.<sup>20</sup>

The measurement method shall be based on phase demodulation of the Up-link signal performed in a sufficient amount of points during a one bit window, evaluation of the best linear fit of these phase samples (linear regression) during the bit window, identification of the exact instants of bit transition, evaluation of the overall time interval error considering the combination of data rate and carrier phase errors, and a verification of the MTIE 1 or MTIE 2 requirements using the curves below (Figure 9 and Figure 10).  The bit transitions are defined as where the two best fit lines of successive “one” and “zero” (or “zero” and “one”) bits meet.  In the event of many successive “ones” or “zeroes” (maximum 8 according to sub-clause A1.1.2 of Annex A on page 134), the distance between discernible bit transitions is split into a suitable amount of equally long bits, and consequently the overall time interval error is assigned (split) in equal parts to the same number of bits.

#### **MTIE requirement 1:**

where  is the observation interval in bits, and the MTIE is measured relative to the data rate 564.48 kbit/s.

> 20 MTIE (n) = max 1  k  N-n (max k  i  k+n di - min k  i  k+n di);  n= 1, 2, 3, 4,....N-1 is the window length used for the analysis, k is the starting position of the window, N is the total number of examined symbols, di is the error (with the sign) of the ending instant of the bit i within the examined window with respect to the used reference clock.

<!-- end of page 54 -->

<!-- Start of picture text -->
800<br>data rate<br>variation  MTIE1<br>600<br>jitter<br>400<br>MTIE  [ns]<br>Measured relative<br>to the Data Rate<br>200<br>564.48 kbit/s<br>148<br>0<br>1  100  200  300  400  500<br>observation interval  [bits]  (one bit  1.77 s)<br><!-- End of picture text -->

**Figure 9:  MTIE requirement 1**

**MTIE requirement 2:** 236 • 10<sup>-9</sup> s for 1 bit    5 bit 370 • 10<sup>-9</sup> s for 5 bit <   50 bit 2.5 •  • 10<sup>-6</sup> /564.48 + 148 • 10-<sup>9</sup> s for 50 bit <   1000 bit

where  is the observation interval in bits, and the MTIE is measured relative to the mean data rate.

<!-- Start of picture text -->
800<br>MTIE2<br>600  data rate<br>jitter  variation<br>400<br>MTIE  [ns]<br>Measured relative<br>to the actual Mean<br>200  Data Rate<br>148<br>0<br>1  100  200  300  400  500<br>observation interval  [bits]  (one bit  1.77 s)<br><!-- End of picture text -->

**Figure 10:  MTIE requirement 2**

<!-- end of page 55 -->

#### **5.2.2.2.5 Amplitude Jitter**

The allowed amplitude jitter shall be +1.5/-2.0 dB per any period of 1.77  s (independent of a bit transition) on the average amplitude value for that period of time.

Amplitude jitter shall be measured both during a start-up ramp simulating the activation of a Balise upon train passage, and during steady state conditions.  The Up-link signal amplitude received by a field probe shall be measured, and data shall be analysed within two sliding windows of fixed length.  One window shall be long compared to the length of a data bit, and the other window shall have the length of a single data bit (according to the actual bit duration, approximately 1.77  s).

The amplitude jitter is defined as the ratio between the average amplitude of the Up-link signal amplitude, evaluated over a time window (Wi) of 1.77  s at the centre of another much longer time window (Wm) of defined length, and the average amplitude of the signal amplitude evaluated over this last time window Wm.  The time window Wm should be of different lengths, in order to cope with different Tele-powering conditions for the Balise under test.  A duration of 50  s – 100  s should be chosen when simulating dynamic Tele-powering conditions, whilst a duration of 400  s – 800  s should be chosen when measuring the amplitude jitter with constant Tele-powering flux.

In both conditions, a number of consecutive measurement steps shall be carried out in order to continuously scan an entire signal record of defined duration (TS).  This is achieved by shifting the time window Wm (and consequently the centred time window Wi) from the start of the signal record, after each measurement, by one step of 1.77  s up to the end.

When the signal is acquired and elaborated, the bandwidth of the measuring equipment shall be wider than the signal bandwidth.  A bandwidth of 4 MHz is a reasonable compromise.  It should be narrow enough not to measure signals outside the defined signal bandwidth, but wide enough not to create excessive errors due to for example time delays or transients.

Figure 11 exemplifies the above defined process.

<!-- Start of picture text -->
Maximum +1.5/-2.0 dB<br>deviation.<br>The average amplitude inte-<br>grated over a 50 s – 800 s<br>wide sliding window.<br>The average amplitude<br>integrated over a one<br>bit wide sliding window.<br><!-- End of picture text -->

**Figure 11:  Amplitude jitter**

<!-- end of page 56 -->

#### **5.2.2.2.6 Signal Band width**

The 10 dB signal bandwidth shall be less than 1000 kHz when random user data is transmitted.  This requirement shall be verified using the following procedure.  In a first step, the signal power is measured in a 1 MHz wide band centred around the already determined centre frequency.  This is performed through evaluation of the RMS averaged spectrum of the signal, using a Resolution Bandwidth of approximately 4.8 kHz, a Span of 4 MHz (corresponding to a signal record length of 800  s), and an averaging factor of 10.  The signal power is then obtained by integration of this spectrum within the above defined 1 MHz band.  Thereafter, the same process is repeated, but with the 1 MHz window centred respectively 1 MHz above, and 1 MHz below, the already determined centre frequency.  The sum of the signal power within the latter two 1 MHz windows shall be at least 10 dB below the signal power of the 1 MHz window that was centred around the centre frequency (the first measurement).

### 5.2.2.3 Antenna Unit and Balise interaction

The operational requirements on the Eurobalise Transmission System depend on the design of the Antenna Unit, the design of the Balise, and the requirements in this document.

Two sizes of the Balise shall be considered, Standard Size and Reduced Size Balises.  A Reduced Size Balise shall also be allowed for transversal installation (i.e., the longer side in a right angle to the track).

To make interoperability possible, the position relative to the track and the size of the active reference area of the Balises shall be the same for all manufacturers, in accordance with this specification (see also sub-clause 5.2.2.4 on page 58).  This cannot be changed in the future without considering interoperability with already delivered products.

The influence of metal masses like metal sleepers and metal structures underneath the Balise may influence the flux from an Antenna Unit into the reference area of the Balise, and influence the field from the reference area to an Antenna Unit.  Therefore, and due to the requirement for interoperability, the position of the reference area relative to metal masses shall also be the same for all manufacturers.

The following length of telegram shall apply for the size of the Balise versus the Maximum Permitted Speed at the location where the Balise is installed:

||Maximum|Permitted Speed|
|---|---|---|
|Balise type|v300 km/h|300 < v500 km/h|
|Standard Size|Long (1023 bits)<br>and|Long (1023 bits)<br>and|
||Short (341 bits)|Short (341 bits)|
|Reduced Size|Long (1023 bits)<br>and<br>Short (341 bits)|Short (341 bits)|

**Table 5:  Telegram length versus Balise type and Maximum Permitted Speed**

<!-- end of page 57 -->

### 5.2.2.4 Balise Reference Areas

For interoperability reasons, within the Eurobalise Transmission System, the size of the reference area, that the performance of the Balise is related to, shall be standardised.

The operational requirements and the output field strength of the antenna loop(s) of the Balise are final, i.e., they can not be changed in future implementations and designs of the system.

The Standard Size and the Reduced Size Balises have the following reference areas for defining the field strength from an Antenna Unit as well as the output field strength from a Balise:

- The Standard Size Balise shall have the active reference area 358 mm × 488 mm.

- The Reduced Size Balise shall have the active reference area 200 mm × 390 mm.

The reference area shall be centred around the Z axis and be in level with the X and Y axes of a Balise.

The output signal from the Antenna Unit is defined as the total flux  d through the reference area in a position related to the reference marks of the Balise.  The field from the Antenna Unit is not homogeneous in the vicinity of the Antenna Unit.

The output field strength from a Balise is defined as the current Iu that encircles the reference area in a position related to the reference marks of the Balise.

Reference Loops of two different sizes should be used for measuring the flux from an Antenna Unit and for measuring the field strength from a Balise.  The Reference Loops shall be conform with the definitions of the reference areas.

The input flux to a Balise shall be conform with the flux measured through the reference area.  The output field from a Balise shall be conform with the field from a current encircling the reference area.

For reference axes see definition in sub-clause 4.5 on page 50.

<!-- end of page 58 -->

### 5.2.2.5 Field Distribution

The vertical component of the field strength from the Up-link Balise shall be conform with a reference field. The reference field is the vertical component in free space from a constant current that encircles the reference area, see sub-clause 5.2.2.4 on page 58.  When the field strength from the reference area is lower than the levels R0–C and R0–D respectively, as defined below, the reference field shall be limited to the levels R0–C (only in the notch region close to the Main Lobe Zone) and R0–D respectively.  The difference, expressed in dB, between the output signal level generated by the Balise and the level of the reference field constitutes the conformity deviation for Up-link.

For the conformity of the field form three zones are defined: the Main Lobe Zone, the side lobe zone, and the Balise cross-talk zone.

The input signal to the Balise is the flux through the reference area defined for the Balise, originating from the Antenna Unit.  The conformity of the input signal to the Balise with the field received in the reference area shall be within the same tolerances as for the Up-link.<sup>21</sup> Conformity in Tele-powering applies only in the Main Lobe Zone and in the Side lobe zone.

The resolution of the evaluation of conformity is dependent on the size of the area (a smaller area gives a better resolution).  However, it is not practically possible to perform the evaluation with an infinitely small area.  The evaluation of the conformity shall be performed with a square-shaped area of maximum 200 mm by 200 mm. The maximum area for conformity evaluation of the Up-link signal may be larger within the Balise cross-talk zone.<sup>22</sup>

The Main Lobe Zone is defined as the volume within the 16 corners of Figure 12.

<!-- Start of picture text -->
Z<br>Z = 460<br>Y<br>X<br>Z = 220<br><!-- End of picture text -->

**Figure 12:  The Main Lobe Zone**

> 21 The conformity of the Tele-powering is reciprocal to the Up-link.  This means that the vertical Up-link field from the Balise in any point of interest may be interchanged with the vertical Tele-powering magnetic dipole moment from a small loop, in the same point, in the free space above the Balise.  The vertical dipole moment is the current multiplied with the horizontally encircled area.  Thus, the Up-link reference field corresponds to the Tele-powering reference magnetic dipole moments for each point of interest above the Balise.  The difference between the magnetic dipole moment, which activates the Balise to a given level, and the reference magnetic dipole moment constitutes the conformity deviation for Tele-powering.

<!-- end of page 59 -->

The volume of the Main Lobe Zone is shown in the tables of Figure 13, related to the centre of the Balise (as per the reference marks of the Balise and the direction co-ordinates defined in sub-clause 4.5 on page 50):

||Z = 220<br>Z = 460|X<br>Y|X<br>Y<br>Z = 220<br>Z = 460||
|---|---|---|---|---|
|The v<br>for a ref|olume of the Main<br>erence area parallel|Lobe Zone<br>to the X-axis:|The volume of the Main L<br>for a reference area transverse|obe Zone<br>to the X-axis:|
|Z = 220 mm|X = 0 mm<br>X =250 mm<br>X =200 mm|Y =200 mm<br>Y = 0 mm<br>Y =150 mm|Z = 220 mm<br>X = 0 mm<br>X =200 mm<br>X =150 mm|Y =250 mm<br>Y =  0 mm<br>Y =200 mm|
|Z = 460 mm|X = 0 mm<br>X =350 mm<br>X =300 mm|Y =350 mm<br>Y = 0 mm<br>Y =300 mm|Z = 460 mm<br>X = 0 mm<br>X =350 mm<br>X =300 mm|Y =350 mm<br>Y =  0 mm<br>Y =300 mm|

**Figure 13:  The volume of the Main Lobe Zone**

Within the Main Lobe Zone the conformity requirement is that the difference between a field generated by a Balise and the reference field shall be within ±1.5 dB, see Figure 14 and Figure 15.

<!-- Start of picture text -->
R0<br>±1.5 dB<br>A C<br>XT<br>D<br>B<br>Reference field<br>Main Lobe  Side Lobe  Balise Cross-<br>Zone Zone talk Zone<br><!-- End of picture text -->

**Figure 14:  Reference field and limits, Up-link**

<!-- end of page 60 -->

<!-- Start of picture text -->
R0<br>±1.5 dB<br>A C<br>XT<br>D<br>B<br>Reference field<br>Main Lobe  Side Lobe  Balise Cross-<br>Zone Zone talk Zone<br><!-- End of picture text -->

**Figure 15:  Reference field and limits, Tele-powering**

The side lobe zone is the volume around the Balise defined by the following co-ordinates, excluding the Main Lobe Zone:

- -1300 mm < X < +1300 mm

- -1400 mm < Y < +1400 mm

- +220 mm < Z < +460 mm

In the part of the side lobe zone closest to the Main Lobe Zone (the notch region), the reference field is limited to be no more than C dB lower than the highest field strength in the Main Lobe Zone at the level Z = 220 mm (R0). This (in the notch region) applies to both Up-link and Tele-powering cases.  The same also applies in the extreme regions near the cross-talk protected zone, but for the Tele-powering case only.

In the side lobe zone the reference field is also limited to be no lower than the values given by the reference field translated +xT cm or -xT cm along the X axis, and translated +yT cm or -yT cm along the Y axis.

The conformity requirement for the side lobe zone is that the difference between a field generated by a Balise and the reference field shall be between +A dB and –  dB, see Figure 14 and Figure 15.

Tolerances and limits for the side lobe zone:

- A = 5 dB

- C = 35 dB

- xT = 5 cm

- yT = 5 cm

<!-- end of page 61 -->

In the Balise cross-talk zone the reference field is limited to be no more than D dB lower than the highest field strength in the Main Lobe Zone at level Z = 220 mm (R0).

The conformity requirement for the Balise cross-talk zone is that the difference between a field generated by a Balise and the reference field shall be between +B dB and –  dB, see Figure 14 and Figure 15.

Tolerances and limits for the Balise cross-talk zone:

- B = 5 dB

- D = 60 dB

The field from the Balise, and the flux through the Balise, may deviate from the form of the field in free space due to debris and to the proximity to conductive material.  The influence of such deviations of the field form shall be considered in the Antenna Unit design.

Debris and the proximity to conductive material may influence the efficiency of the Balise itself.  Such influence shall be within the specified limits for the performance of the Balise.

The levels of debris, denominated Class A and Class B layers, are defined in sub-clause 5.7.9 on page 93.

<!-- end of page 62 -->

### 5.2.2.6 Transmission in the Main Lobe Zone

The input-to-output characteristics of a Balise shall be according to Figure 16 below.  The upper limit is mainly related to intrinsic cross-talk protection, and the lower limit is mainly related to detection of Up-link Balises. The influence from debris (see sub-clause 5.7.9 on page 93), metallic structures on ground (see sub-clause 5.7.10 on page 95), approved mounting details (see sub-clause 5.7.10.3 on page 98), and cables (see sub-clauses 5.7.10.7 on page 105 and 5.3.4 on page 74) shall be included. However, please observe the correction of the flux levels defined in Table 15 of sub-clause 5.7.9 on page 94 during the influence of some debris conditions. The Balise response shall be inside the area limited by the shaded areas in Figure 16, and considering the measurement errors.  Furthermore, the Balise response shall be inside this area for all the geometrical positions of the Main Lobe Zone considering the actual Balise Conformity performance.  The latter requirement means that the upper and lower restrictions must be further limited by the difference between the actual Balise Conformity deviation for the test point of the I/O characteristics test, and the worst case Balise Conformity deviations (maximum and minimum) for all other geometrical test points within the Main Lobe Zone.

The field strength from the Antenna Unit shall be defined as stated in sub-clause 6.2.1.5 on page 112.

Up-link field strength represented by loop current

<!-- Start of picture text -->
Upper limit for cross-talk<br>Iu3<br>Example of response<br>from a Balise<br>Iu2<br>Lower limit<br>Iu1<br>O<br> d1  d3  d2 Tele-powering magnetic flux  d4<br><!-- End of picture text -->

**Figure 16:  Input-to-output characteristics for a Balise**

Characteristics for a Standard Size Balise:

|Iu1= 23 mA|Iu2= 37 mA|Iu3= 116 mA|Iu3= 116 mA|Non-permanent damage<sup>23</sup>|
|---|---|---|---|---|
|d1= 7.7 nVs<br>aracteristics for a|d2= 12.2 nVs<br>Reduced Size Balis|d3= 9.2 nVs<br>e:|d4= 200 nVs|d5= 300 nVs|
|Iu1= 37 mA|Iu2= 59 mA|Iu3= 186 mA|Iu3= 186 mA|Non-permanent damage<sup>23</sup>|
|d1= 4.9 nVs|d2= 7.7 nVs|d3= 5.8 nVs|d4= 130 nVs|d5= 250 nVs|

Characteristics for a Reduced Size Balise:

> 23  Without being permanently damaged the Balise shall withstand the flux level  d5, including also non-toggling modulation.

<!-- end of page 63 -->

When the total flux from the Antenna Unit through the defined reference area of the Balise exceeds  d1, the Balise shall start to operate (see sub-clause 5.2.2.9 on page 67), and the field strength from the Balise shall be higher than a field strength represented by a current of Iu1 that flows in a conductor encircling the reference area.

When the flux from the Antenna Unit exceeds  d2 (Figure 16, sub-clause 5.2.2.6 page 63), the field strength from the Balise shall exceed the field strength from a current Iu2 in the encircling conductor.

The output signal from the Balise for an input signal lower than  d1 shall be regarded to be non-specified for properties other than the maximum signal level.

The Balise shall operate in saturation mode when the flux from the Antenna Unit through the defined reference area of the Balise is high.  Then, for an increasing input flux, the field strength from the Up-link Balise shall be approximately constant and may not fall more than –0.5 [dB/dB].<sup>24</sup>

When the flux from the Antenna Unit exceeds  d4 (Figure 16, sub-clause 5.2.2.6 page 63), the proper function of the Balise can not be guaranteed.  Thus, the Antenna Unit shall not create a flux that exceeds  d4.

When the Balise receives a flux  d from the Antenna Unit, a voltage is induced in the Balise receiver loop.  The Balise loads the induced voltage, which in turn generates a current Ireflected in the receiver loop.  This current may, if the distance to the Antenna Unit is very close, influence the Antenna Unit.  This interaction can be expressed as an impedance Zreflected (the induced voltage  d divided by the current Ireflected).

The absolute value of the complex impedance Zreflected of the Standard Size Balise shall be higher than 60  when the Balise receives a flux reaching  d4 +0/–3 dB.

The absolute value of the complex impedance Zreflected of the Reduced Size Balise shall be higher than 40  when the Balise receives a flux reaching  d4 +0/–3 dB.

> 24 Example: If  d rises 1 dB then the output field may not fall more than 0.5 dB.  This is required in order to ensure that a correct location reference can be set by the On-board Transmission Equipment.

<!-- end of page 64 -->

### 5.2.2.7 Cross-talk Conditions

Cross-talk protection is based on the following properties regarding the Balise and its accompanied installation rules:

- The fulfilment of the input-to output characteristics within the Main Lobe Zone in all specified conditions.

- The fulfilment of the conformity requirements in free air.

- The fulfilment of Up-link current induction into nearby cables, and Balise controlling interface cables, considering the company specific rules.

- The fulfilment of the company specific installation rules for cables.

- The fulfilment of requirements related to installation in the vicinity of Guard Rails.

- The fulfilment of requirements related to Loop Cable.

The worst case condition with cables is when a Balise is installed close to a cable, as shown in Figure 40 of subclause 5.7.10.7.1 on page 105, which also crosses another track.  The current level in the cable at the position where a potential On-board Transmission Equipment may pass the same cable have to respect the limits in subclause 5.7.10.7 on page 105.  This applies for a current that originates from a Balise that is in a cross-talk position (relative to the above On-board Transmission Equipment).  The company specific installation rules for the Balises shall limit the induced electromotive force so that the Up-link current limits of sub-clause 5.7.10.7 on page 105 are fulfilled.

It is the responsibility of the Balise manufacturer to specify installation rules considering the company specific common mode properties of the Balise controlling interface in order to not exceed the effect on the On-board Transmission Equipment of the current limits specified in sub-clause 5.7.10.7 on page 105 in the relation to the Up-link induced current.

<!-- end of page 65 -->

### 5.2.2.8 Protocol

#### **5.2.2.8.1 Start-up of the Transmission Link**

When the flux from the Antenna Unit is high enough, the Up-link Balise shall start to send the intended message. This must occur at a flux equal to or lower than  d1.  The Balise start-up time shall be as defined in sub-clause 5.2.2.9 on page 67.

#### **5.2.2.8.2 Handshaking**

No handshaking shall be required.

#### **5.2.2.8.3 Disconnection**

The Up-link telegram shall be sent uninterrupted as long as the Up-link Balise receives enough flux from the Onboard Antenna Unit.

#### **5.2.2.8.4 Synchronisation**

The telegrams shall be sent cyclically.  To avoid the need for awaiting the start bit of one telegram the applied coding allows to find the beginning of the message content after a redundancy check has been performed.

The data protection properties of this code are described in sub-clause 4.3 on page 36.

#### **5.2.2.8.5 Procedures**

The Up-link transmission shall be transparent from Interface ‘C’ to Interface ‘A’.  This means that all received data shall be transmitted by the Up-link Balise, when it is activated.  The data shall be transmitted in FIFO order.

When switching telegrams in the Wayside Signalling Equipment or in the Up-link Balise, a sequence of between 75 bits and 128 bits of only logical ‘1’ or only logical ‘0’ shall be inserted in-between the old and the new telegram.  These ‘1’ or ‘0’ sequences shall be inserted by the LEU in general cases, and by the Balise when switching to the Default Telegram is activated.

It shall be allowed to transmit a sequence of between 75 bits and 128 bits of only logical ‘1’ or only logical ‘0’ from the LEU to Interface ‘C’.<sup>25</sup> The insertion of the above mentioned bits shall not have any impact on the reliability.

#### **5.2.2.8.6 Default Telegram**

Under failure conditions<sup>26</sup> , the Balise shall transmit a Default Telegram to Interface ‘A’.

If the Balise switches from sending the LEU data to sending the Default Telegram during the passage of the train, it shall continue to send the Default Telegram as long as the Balise is sufficiently energised.

Switching from LEU data to the Default Telegram shall be done according to the requirements in sub-clause 5.2.2.8.5.

> 25 The telegram transmitted before and after the sequence can be the same.

> 26 Failure conditions can be the result of for example a cut cable, absence of signals, interference (bursts) on Interface ‘C’, or insufficient quality according to sub-clause 5.3.2.3.6 on page 82.

<!-- end of page 66 -->

### 5.2.2.9 Interoperability and compatibility requirements on the Balise Up-link transmission

The Up-link Balise shall have started to operate when the flux from the Antenna Unit has reached  d1.  Then it shall choose the appropriate transmission mode, based on the kind of modulation of the received Tele-powering signal, for the purpose of compatibility.  A Eurobalise shall be silent when it is being activated by KVB, Ebicab or RSDD.  The Tele-powering signal from these systems is a non-toggling 50 kHz modulated 27 MHz signal (see sub-clause B1.2 of Annex B on page 138).

<!-- Start of picture text -->
[Vs]<br>Tele-powering magnetic flux<br> d1<br>Time [s]<br>For CW modulation  Transmit data<br>< 150 s<br>For toggling AM  Transmit data<br>< 250 s<br>For non-toggling AM, alt. 1  No transmission of data<br>No transmission<br>For non-toggling AM, alt. 2  Transmit data  of data<br>< 80 s<br><!-- End of picture text -->

**Figure 17:  Timing diagram for Balise start-up**

When the Tele-powering signal is CW, the Up-link Balise shall within the time limit 150  s (TBAL) start to send the data using FSK modulation to the Interface 'A1'.

When the Tele-powering signal is amplitude modulated (toggling or non-toggling modulation), a Balise shall either not respond for a period of time that does not exceed 250  s (TBAL), or it may transmit data for less than 80  s, until it has decided whether the AM is toggling or not.  Then two alternative mode transfers shall exist:

1. For a toggling AM it shall start (alternatively proceed) sending the Up-link signal using FSK modulation.

2. For a non-toggling AM it shall remain passive (not sending any data), alternatively stop sending the Up-link signal within 80  s from the moment the transmission started.  The Balise shall send data also when a toggling decision could not be taken.

### 5.2.2.10 Coding requirements

See sub-clause 4.3 on page 36.

<!-- end of page 67 -->

## **5.3 Balise Controlling Interfaces**

### **5.3.1 Introduction**

This sub-clause defines the interface between the Balise constituent and the Lineside Electronic Unit (LEU).

The Balise controlling interface cable is regarded part of the Balise, and is the responsibility of the Balise manufacturer.  Therefore the interface is mainly specified at the LEU output.

Connectors can be used on both the Balise and on the cable.  The use of these connectors is not mandatory, and other means of connections are allowed.

For Up-link transmission, the LEU receives messages from wayside signalling or interlocking.  These messages are converted into Up-link Eurobalise Telegrams, and are passed on through the Interface ‘C’ to the Balise, which transmits the Eurobalise Telegrams to the On-board equipment of the passing trains.  This specification defines a ‘Preferred Solution’, that is valid for cable lengths of up to 500 m.  Longer cable lengths will require other, more stringent requirements, which are not standardised.

This sub-clause defines four different interfaces:

- Up-link data input, Interface ‘C1’

- Output Blocking signal , Interface ‘C4’ (optional)

- Balise programming interface, Interface ‘C5’

- Auxiliary energy input, Interface ‘C6’

Interface ‘C1’, Interface ‘C6’, and Interface ‘C4’ shall share the same transmission medium (the same cable).

Interfaces ‘C1’ and ‘C6’ are defined in the following sub-clauses (see sub clauses 5.3.2 and 5.3.3), and the specifications apply to the LEU output unless otherwise explicitly stated.

The optional output blocking signal (Interface ‘C4’) is defined in clause D4 of Annex D on page 145, and the specifications apply to the Balise output unless otherwise explicitly stated.

The Balise programming interface (Interface ‘C5’) is not within the scope of this specification.

<!-- end of page 68 -->

### **5.3.2 Up-link Data Input (Interface ‘C1’)**

### 5.3.2.1 General

Interface ‘C1’ shall be used for transmitting Eurobalise Telegrams from the LEU to the Balise.

### 5.3.2.2 Functional Requirements

Accidental short circuit for infinite time to the signals shall not permanently damage any connected equipment.

This interface shall be considered transparent, which implies that the transmitted messages do not need to be defined within this specification.

### 5.3.2.3 Physical Transmission

#### **5.3.2.3.1 Transmission Medium**

The signal shall be polarity independent.  This means that interchanging the two input leads shall not affect the received bit stream.

The transmission shall be base band signals on electrical conductors.

#### **5.3.2.3.2 Electrical Data**

#### 5.3.2.3.2.1 Signal Level

The signal level V2 as defined according to Figure 19 on page 71 shall be limited according to Table 6 into a restive 120  load.

|**Signal level, V2**|**Requirement**|
|---|---|
||**at the LEU output**|
|Minimum value|> 14 Vpp|
|Maximum value|< 18 Vpp|

**Table 6:  Interface ‘C1’, Signal Levels**

#### 5.3.2.3.2.2 Return Loss

The Return Loss (at the LEU connector) considering a resistive 120  load (and that the frequency is within 0.2 MHz to 0.6 MHz) shall be better than

Definition of Return loss is found in clause C1 on page 142.

<!-- end of page 69 -->

#### 5.3.2.3.2.3 Waveform and Bit Coding

The signal shall be Differential Bi-Phase-Level (DBPL) coded according to Figure 18.

<!-- Start of picture text -->
Bit Cell 1 2 3 4 5 6 7 8 9 10 11<br>Bit Value X 1 0 1 1 0 0 0 1 0 1<br>Letter A A B B B A B A A B B<br>+1<br>Level<br>-1<br><!-- End of picture text -->

'X' = Don’t know

#### **Figure 18:  Differential Bi-Phase-Level coding scheme**

This means that the determination of the bit value is performed in two stages.  The first stage is to translate the phase shift in the centre of each bit cell into a letter.  A shift from +1 to -1 is translated into an ‘A’, and a shift from -1 to +1 is translated into a ‘B’.  The second stage is to compare the current letter with the previous one.  If they are equal, the current bit value is a ‘1’.  If they are not equal, the value is a ‘0’.

#### 5.3.2.3.2.4 Mean Data Rate

The bit rate shall be:

564.48 kbit/s

The mean data rate is defined as 1500 divided by the duration of 1500 consecutive data bits.

#### 5.3.2.3.2.5 Mean Data Rate Inaccuracy

For any consecutive 1500 bits, the mean data rate shall be according to sub-clause 5.3.2.3.2.4, with an overall tolerance of

<!-- end of page 70 -->

#### 5.3.2.3.2.6 Eye Diagram

The signal into a resistive 120  load shall fulfil the requirements according to Figure 19.  The shaded areas constitute a mask into which the signal shall not enter (considering the actual mean data rate and the actual V2 signal level).

<!-- Start of picture text -->
T T1<br>V1 V2<br>Tjitter Tjitter<br><!-- End of picture text -->

**Figure 19:  Eye Diagram, Up-link**

#### 5.3.2.3.2.7 Eye Diagram Parameters

The parameters in Figure 19 shall be according to Table 7.

|**Parameter**|**Requirement**|
|---|---|
||**at the LEU output**|
|T|1|
||Rate<br>Data<br>Mean<br>actual<br>2<br>•|
|Tjitter|60 ns|
|T1|0.6•T|
|V1|0.74•V2|

**Table 7:  Eye Diagram Parameters, Up-link**

#### 5.3.2.3.2.8 Rising and Falling Edges

The 10 % to 90 % rise time and fall time, with a resistive 120  load, shall be

<!-- end of page 71 -->

#### **5.3.2.3.3 Error Detecting/Correcting Codes**

According to sub-clause 4.3 on page 36.

#### **5.3.2.3.4 Handshaking and Re-sending**

No handshaking shall be performed.

#### **5.3.2.3.5 Flow Control**

The Balise shall receive data from the Interface ‘C1’ at the same rate as it is sent from the LEU.

#### **5.3.2.3.6 Error Handling**

The Balise shall start transmitting the Default Telegram, at the latest after a period of time equivalent to 341 bits, when the Balise can not with sufficient quality receive a signal from Interface ‘C1’.

In general, when the Balise can not detect any valid signal or valid data on the Balise controlling interface, it shall start sending the stored (Default) telegram.  In particular, a continuous stream of only logical ‘0’ or ‘1’ shall be either transparently transmitted to Interface ‘A’, or cause a switch to the Default Telegram.  See also second paragraph of sub-clause 4.4.6.2.3 on page 44.

This applies both to the situation when the Balise has been activated by a passing train and is ready to start sending a telegram, and to the situation when the Balise can no longer detect any valid signal on Interface ‘C1’ during a train passage.

Once the Balise has started sending the Default Telegram, it shall continue doing so as long as it is sufficiently energised by the train, even if there should be a resumption of valid signal on Interface ‘C1’.

Each time the Balise is sufficiently energised by the train, a new decision shall be made about whether there is any valid signal on Interface ‘C1’.

### 5.3.2.4 Transmission of Messages on Application Level

The general format shall be according to sub-clause 4.3 on page 36.

<!-- end of page 72 -->

### **5.3.3 Auxiliary Energy Input (Interface ‘C6’)**

### 5.3.3.1 Functional Requirements

Interface ‘C6’ shall be present and fulfil the requirements of this sub-clause.  This interface may be used for powering the Up-link serial interface input circuits of the Balise from the LEU.  When Interface ‘C4’ is implemented, Interface ‘C6’ shall be used as a carrier for the blocking signal (see clause D4 of Annex D on page 145).

### 5.3.3.2 Physical Transmission

#### **5.3.3.2.1 Transmission Medium**

The signal shall be polarity independent.  This means that interchanging the two inputs leads shall not affect the function of the interface.

The transmission shall be base band signals on electrical conductors.

#### **5.3.3.2.2 Electrical Data**

#### 5.3.3.2.2.1 Signal Level

||**Requirement**<br>**at the LEU output**|
|---|---|
|Signal level shall be|22.0 +1.0/-2.0 Vpp|
|(into a resistive 170load)||

**Table 8:  Interface ‘C6’, Signal Levels**

#### 5.3.3.2.2.2 Return Loss

The Return Loss (at the LEU connector) considering a resistive 170  load (and that the frequency is within 8.820 kHz  0.1 kHz) shall be better than Definition of Return loss is found in clause C1 on page 142.

4 dB.

5.3.3.2.2.3 Frequency The signal shall be a sine wave at a frequency of

8.820 kHz  0.1 kHz

5.3.3.2.2.4 Harmonics

The second harmonic content of the signal from LEU shall be (measured into a resistive 170  load)

The RMS high frequency harmonic content of the signal from LEU shall be (measured into a 120  load impedance)

< -20 dBc < -40 dBc between 0.1 and 1 MHz

<!-- end of page 73 -->

### **5.3.4 Common Mode Signal Levels**

### 5.3.4.1 Conducted emission

The induction of Up-link signal into the connected cable shall be limited so that the specific company installation rules fulfil what is stated in sub-clause 5.2.2.7 on page 65.

### 5.3.4.2 Susceptibility

The company specific common mode immunity of the Balise controlling interface shall be sufficient so that the company specific installation rules ensure correct performance of the Balise when the cable is subjected to Telepowering induction from the On-board Antenna Unit respecting the limits stated in sub-clause 6.6.10 on page 130.

## **5.4 Programming Principles**

The Up-link Balise should be programmable, either by means of inductive or wire transmission of energy and data between the programming equipment and the Balise.

The Balise programming principles and programming process (including also data retention) shall ensure that the safety targets as defined in sub-clause 4.4.6 on page 43 are met.  The Balise manufacturer shall design the Balise so that the programming circuitry is not activated during normal operation and storage.  The programming process (including tools) shall ensure that the intended telegram is programmed into each Balise.

<!-- end of page 74 -->

## **5.5 RAMS Requirements**

### **5.5.1 Balise functionality**

### 5.5.1.1 Overview

Table 9 below defines the functionality of the Balise, together with a linking to the top-level functionality of subclause 4.4.2 on page 42 and top-level hazards of sub-clause 4.4.6.3 on page 46.<sup>27</sup> Optional functions defined in sub-clause 4.1.4 on page 24 are intentionally excluded.

|**Balise functionality:**|**Related top-level**<br>**functions**|**Related top-level**<br>**hazards**|
|---|---|---|
|Reception of Tele-powering signal|F1, F2|H1, H5, and H6 apply|
|Up-link signal generation|F1, F2|H1, H4, H5 and H6 apply|
|Data management|F2|H4, H5, and H6 apply|
|Mode selection at start-up|F1|H1 applies|
|Limitation of the Up-link field|F2, F3, F4|H7, H8, and H9 apply|
|Support to programming and management of opera-<br>tional/programming mode|F2|H4, H5, and H6 apply|
|Reception of data from Interface ‘C’|F2|H4, H5, and H6 apply|
|Control of I/O characteristics|F1, F2, F3, F4|H1, H7, H8, and H9 apply|
|Cross-talk protection with other cables|F2, F3, F4|H7, H8, and H9 apply|

**Table 9:  Balise functionality and related top-level hazards**

The hazards H5 and H6 are not explicitly quantified for reasons mentioned in sub-clause 4.4.6.3.  For hazard H4, see also the concept of the non-trusted channel in sub-clause 4.4.6.4 on page 47.

### 5.5.1.2 Reception of Tele-powering signal

It includes reception of energy from the air-gap, field conformity, AC/DC conversion and input power limitation. All operational, environmental and failure conditions that could inhibit the Balise from being energised at a level higher than the one corresponding to the minimum flux level of the applicable I/O characteristic shall be regarded as hazardous situations.

<!-- end of page 75 -->

### 5.5.1.3 Up-link signal generation

It includes modulation, control, transmission of the Up-link signal to the air-gap, and Up-link field conformity. All operational, environmental and failure conditions that could inhibit the Balise from generating the Up-link signal with electrical characteristics inside the allowed tolerances shall be regarded as hazardous situations.

### 5.5.1.4 Data Management

It includes Fixed or Default Telegram retention, data rate generation, memory management and serialisation of data.  All operational, environmental and failure conditions that could inhibit the Balise from sending the intended data, at the correct rate, to the Up-link signal generation function shall be regarded as hazardous situations.

### 5.5.1.5 Mode selection at start-up

It includes detection of the current Tele-powering condition (CW, toggling, or non-toggling mode), setting up of the corresponding operational mode and control of the start-up transient.  All operational, environmental and failure conditions that inhibit the Balise from properly setting the required mode and from responding within the maximum delay time shall be regarded as hazardous situations.

### 5.5.1.6 Limitation of the Up-link field

It includes the upper limitation of the Up-link signal level in the allowed operational and environmental conditions (debris, temperature etc.).  All operational, environmental and failure conditions that could inhibit the Balise from limiting an Up-link signal level to lower than the maximum level of the applicable I/O characteristic shall be regarded as hazardous situations.

### 5.5.1.7 Support to programming and management of operational/programming mode

It includes switching from normal operation mode to programming mode and vice-versa, under control of an external programming tool, reception, storage and check of the programmed data.  All operational, environmental and failure conditions that could generate the transmission of corrupted memory data shall be regarded as hazardous situations.

### 5.5.1.8 Reception of data from Interface ‘C’

It includes the check of the quality of the incoming data and management of the switch from Interface ‘C’ data to Default Telegram, DBPL/NRZ decoding, management of the master clock, cross-talk protection among cables of different Balises, generation of the Blocking Signal (where applicable), and powering of the input circuitry from the Biasing Signal (including protection against leakage of energy from Interface C to the up-link transmitter circuitry, where applicable).  All operational, environmental and failure conditions that could inhibit the Balise from correctly transferring the incoming data to the up-link signal generation function, or from correctly switching the telegram to be transmitted from the one at Interface C to the Default Telegram and vice-versa within a maximum allowed time, shall be regarded as hazardous situations.

<!-- end of page 76 -->

### 5.5.1.9 Control of I/O characteristics

It includes the combined control of incoming Tele-powering energy and of the Up-link signal level in the allowed operational and environmental conditions (debris, temperature etc.).  All operational, environmental and failure conditions that could inhibit the Balise from transmitting an Up-link signal level higher than the minimum level, and lower than the maximum allowed level, of the applicable I/O characteristic shall be regarded as hazardous situations.

### 5.5.1.10 Cross-talk protection

Proper instructions for allowed layouts of cables crossing the tracks in the vicinity of a Balise, issued by the Balise manufacturer, shall minimise the risk of possible cross-talk occurrence according to the requirements of sub-clause 5.7.10.7 on page 105.  The rules are defined so as to avoid cross-talk when the Balise and the Onboard system are correctly operating.  If components fail, there is a potential risk that the rules do not protect.

The possible cross-talk effects of unintentional cables crossing the tracks in the vicinity of a Balise, with undefined layouts, are not covered at Balise level.

### **5.5.2 Reliability**

See sub-clause 4.4.3 on page 42.

### **5.5.3 Availability**

See sub-clause 4.4.4 on page 43.

### **5.5.4 Intentionally Deleted**

<!-- end of page 77 -->

### **5.5.5 Safety**

### 5.5.5.1 Hazards and Functionality

The top-level hazards defined in sub-clause 4.4.6.3 on page 46, and the related Balise functionality of Table 9 in sub-clause 5.5.1 on page 75, are apportioned and broken down as follows.  How each failure contributes to the respective hazards HXB is company specific, and dependent on implementation of suitable barriers.  However, the quantification of sub-clause 5.5.5.2 on page 81 shall be fulfilled.

<!-- Start of picture text -->
H1B: A Balise is not detectable<br>Erroneous reception of Tele-powering signal<br>Erroneous Up-link signal generation<br>Erroneous mode selection at start-up<br>Erroneous control of I/O characteristics<br><!-- End of picture text -->

**Figure 20:  Balise Detectability**

<!-- Start of picture text -->
H4B: Transmission of an erroneous telegram interpretable as correct<br>Erroneous data management<br>Erroneous programming due to Balise failure<br>Erroneous reception of data from Interface ‘C’<br>Erroneous Up-link signal generation<br><!-- End of picture text -->

#### **Figure 21:  Erroneous telegram interpretable as correct**

<!-- end of page 78 -->

##### **H5B: Loss of telegram intended for full performance**

Erroneous data management Erroneous programming due to Balise failure Erroneous reception of data from Interface ‘C’ Erroneous Up-link signal generation Erroneous reception of Tele-powering signal

#### **Figure 22:  Loss of telegram for full performance**

##### **H6B: No transmission of Default Telegram**

Erroneous data management Erroneous programming due to Balise failure Erroneous reception of data from Interface ‘C’ Erroneous Up-link signal generation Erroneous reception of Tele-powering signal

#### **Figure 23:  No transmission of Default Telegram**

**H7B: Erroneous localisation** Erroneous limitation of the Up-link field Erroneous control of I/O characteristics Erroneous cross-talk protection with other cables

**Figure 24:  Erroneous Localisation**

<!-- end of page 79 -->

**H8B: The order of reported Balises is erroneous**

Erroneous limitation of the Up-link field Erroneous control of I/O characteristics Erroneous cross-talk protection with other cables

#### **Figure 25:  Order of reported Balises is erroneous**

**H9B: Erroneous reporting of Balises in a different track**

Erroneous limitation of the Up-link field Erroneous control of I/O characteristics Erroneous cross-talk protection with other cables

#### **Figure 26:  Reporting of Balises in a different track**

<!-- end of page 80 -->

### 5.5.5.2 Quantification

Table 10 defines the requirements that shall be fulfilled for the Balise hazards of sub-clause 5.5.5.1 on page 78, when assuming that the specified maintenance is fulfilled.

|||**One Balise**|**One Balise**|**Two or several**<br>**consecutive**<br>**Balises**<sup>**28**</sup>|
|---|---|---|---|---|
|**No.**|**Hazard Description**|**Q**|**[f/h]**|**[f/h]**|
|H1B|A Balise is not detectable|210<sup>-5</sup>|-|10<sup>-9</sup>|
|H4B|Transmission of an erroneous telegram inter-<br>pretable as correct|-|-|-|
|H5B|Loss of the telegram, from a certain Balise,<br>intended for full performance|-|-|-|
|H6B|No transmission of Default Telegram in case<br>of wayside failures|-|-|-|
|H7B|Erroneous localisation of a Balise with recep-<br>tion of valid telegram|See A|nnex F and the note|below.|
|H8B|The order of reported Balises, with reception<br>of valid telegram, is erroneous<sup>29</sup>|See A|nnex F and the note|below.|
|H9B|Erroneous reporting of a Balise in a different<br>track, with reception of valid telegram|See A|nnex F and the note|below.|

#### **Table 10:  Quantification for Balise**

- Note: The overall system requirements on a cross-talk THR of 10<sup>-9</sup> f/h stated in SUBSET-091 shall be respected considering the mandatory On-board requirements stated in sub-clause 6.4.5.2 on page 122 and the methodology of Annex F.

The hazards H7B, H8B, and H9B are caused by failures in the Balise (too strong Up-link signal).

Quantification of Hazard H4B is not applicable, because covered by the non-trusted channel (see sub-clause 4.4.6.4 on page 47).

The figures might originate from a hardware failure, and is thus dependent on MTTR (including the detection time) and the actual failure frequency.  The combination of these aspects is the sums quantified in Table 10 above.<sup>30</sup>

The hazards H5B and H6B are not explicitly quantified for reasons mentioned in sub-clause 4.4.6.3 on page 46.

> 28 Only two Balises are currently commonly evaluated.

> 29 One Balise has been virtually moved (e.g., due to longitudinal cross-talk) so that the order of Balises becomes erroneous.

> 30 In which relation those hazards are related to safety is determined by hazard analyses on higher system level.

<!-- end of page 81 -->

### 5.5.5.3 Independence of hazard causes

For some of the hazards, dependencies also have to be considered when calculating the figures of Table 10 on page 81.

It is assumed that there is negligible common cause factor (CCF) for the case that two or several consecutive Balises are affected within the hazards H4B, H5B and H6B.  If this is proven not true, then this aspect shall be separately analysed.

Crosswise unavailability of each type of hazard is independent between the On-board Transmission Equipment and the Balise.

Effects of faults shall be analysed assuming additional noise from the air-gap.  Any ratio of random decoded bit error rate shall be analysed, assuming that the On-board Transmission Equipment uses the reference receiver (see sub-clause 4.3.4 on page 41).

### 5.5.5.4 Conditions/Assumptions

The apportionment of the figures of Table 10 on page 81 is based on the following presumptions:

- The Mean Time to Restore (MTTR) is 10 hours.

- The dependencies with air-gap related aspects shall be considered.  See sub-clause 4.4.6.5 on page 48.

- H5B and H6B means that a physical Balise is either detectable or undetectable, and that the telegram in question is corrupted and/or not transmitted (i.e., H5B and H6B are always more probable than H1B).

- The H6B probability is conditional that wayside failures are present (H5B expresses the probability for wayside failures).

- Erroneous localisation in H7B means that the requirements of sub-clause 4.2.10.2 on page 35 are not fulfilled.

- Only random aspects are included.

- All figures are based on mean restore times.  The analyses should be supported by sensitivity analyses wherever deemed necessary.

The following aspects are not within the scope of the quantification of Table 10 on page 81:

- Vandalism

- Exceptional occurrences (e.g., exceptional environmental conditions outside specification, like lightning effects out of specification)

- Erroneous installation

- Erroneous maintenance

- Programming with erroneous telegrams (i.e., a non-intended telegram is programmed into a Balise)

- Occupational Health

- Mechanical damage due to maintenance (causing conditions outside specification)

The quantification should, as far as possible, be based on data acquired by experience.  If such data is not available, data from MIL-HDBK 217 or other similar recognised database should be used.  Data may be tailored considering manufacturer experience (if available), but explicit justifications are required.

<!-- end of page 82 -->

## **5.6 Installation Requirements for Balises**

### **5.6.1 Reference Axes**

See sub-clause 4.5 on page 50.

### **5.6.2 General Installation Requirements for Balises**

### 5.6.2.1 Height Tolerances for Balise Mounting

The following Balise mounting heights apply:

||Debris layer|The distance from top<br>of rail to reference<br>marks, Zb:<sup>31</sup>|
|---|---|---|
|Highest position of any Balise:|Class A and B|–93 mm|
|Lowest position of Standard Size Balise:|Class A|–190 mm|
||Class B|–210 mm|
|Lowest position of Reduced Size Balise (transversal and|Class A|–150 mm|
|longitudinal mounting):|Class B|–193 mm|

#### **Table 11:  Balise Mounting Heights**

The debris layers Class A and Class B are defined in sub-clause 5.7.9 on page 93.  All debris classes shall be considered for the highest position of any type of Balise.

Balises can be classified by the supplier to Class A or Class B.  When a Balise of one class is mounted to a height corresponding to another class then the less severe class of the two is valid for this Balise, where the Class A is the most severe and Class B the less severe class.

Each design of Antenna Unit shall for interoperability reasons be able to handle each kind of Balise mounting stated above.  It shall always take into consideration the most severe debris layer class.

According to the definition of reference area for the Balise the influence of debris affects the transmission in two ways:

1. The input to, and the output from, a Balise are measured in the reference area that is covered by debris.

2. The input to, and the output from, an Antenna Unit are measured in the reference area that is covered by debris.

> 31 As the Zb values refer to the reference marks, the bottom of a Balise will usually be lower. In situations where the mounting surface is too low, in order not to exceed the maximum Zb value, a distance block of a non-conductive material shall be put between the Balise and the mounting surface.

<!-- end of page 83 -->

### 5.6.2.2 Distance from Top of Rail to Balise Reference Mark

The following table defines the applicable range of distances (in mm) from Top of Rail to the Balise reference mark for different combinations of the applicable debris class for the actual application and the Balise class.

|||Debris Class|in Application|
|---|---|---|---|
|Balise Size|Balise Class|A|B|
|**Standard**|**A**|**-93 to -190**|**-93 to -210**|
|Standard|B|Not allowed|-93 to -210|
|Reduced|A|-93 to -150|-93 to -193|
|**Reduced**|**B**|Not allowed|**-93 to -193**|

**Table 12:  Mounting height versus Balise Class**

Preferred combinations are marked with **bold** text.

<!-- end of page 84 -->

### 5.6.2.3 Lateral and Angular Tolerances for Balise Installation

The lateral and angular tolerances apply to both the Standard Size and Reduced Size Balises.  The reference axes and angles are described in sub-clause 4.5 on page 50.

|The maximum lateral deviation between the Z reference<br>marks of the Balise and the centre axis<sup>32</sup>of the track:|15 mm|Tolerance for general applications.|
|---|---|---|
|Provided that the track curve radius is1000 m and the<br>Maximum Permitted Speed is180 km/h the lateral<br>deviation from the centre axis<sup>32</sup>of the track may be:|40 mm|Tolerance to be used only when the<br>layout of the track does not allow for the<br>general application tolerance.|
|Provided that the track curve radius is1000 m, the<br>Maximum Permitted Speed is220 km/h, the Balise is<br>installed 40 mm higher than otherwise allowed, longitu-<br>dinal installation of the Reduced Size Balise is not used,<br>no metallic plane is present closer than 400 mm below<br>the Balise, Balise is not mounted on steel sleepers and<br>debris Class A application is not applied, the lateral<br>deviation from the centre axis<sup>32</sup>of the track may be:|±60 mm|Tolerance to be used only when the<br>layout of the track does not allow for the<br>general application tolerance.|
|Provided that the track curve radius is1000 m, the<br>Maximum Permitted Speed is180 km/h and the Balise<br>is installed 40 mm higher than otherwise allowed, the<br>lateral deviation from the centre axis<sup>32</sup>of the track may<br>be:|80 mm|Tolerance to be used only when the<br>layout of the track does not allow for the<br>general application tolerance.|
|Allowed tilting of the Balise (Tb), related to the Y-axis:|2|**X**<br>**Y**<br>**Tilting****2**|
|Allowed pitching of the Balise, related to the X-axis:|5|**X**<br>**Y**<br>**Pitching****5**|
|Allowed yawing of the Balise, related to the X-axis:|10|**X**<br>**Z**<br>**Yawing****10**|

> 32 The centre axis of the track is located half the distance between the webs of the rails.  The value of the lateral tolerance does not include the influence from lateral rail wear (this shall instead be considered in the dynamic displacement of the Antenna Unit).

<!-- end of page 85 -->

- Note: In case of multi-rail track, where one or more track(s) are operated with ETCS, one Balise can be installed serving several tracks as long as the installation of the Balise is in accordance with the rules above when each track is considered individually.  Where it is not possible for one Balise to serve several tracks, several Balises can be installed, where each Balise serves one track, as long as each Balise is installed according to the above rules for the track it is intended to serve.  In case several Balises are installed as described, a Balise may or may not be read/detected if installed outside the limits defined above, with reference to the track on which the train is running.

<!-- end of page 86 -->

### **5.6.3 Distance between Balises**

The minimum distance between two consecutive Balises shall be 2.3 m from centre to centre, on lines with a Maximum Permitted Speed of 180 km/h.<sup>33</sup>

An exception to the general rule above is that the minimum distance between two consecutive Standard Size Eurobalises shall be 2.6 m from centre to centre, on lines with a Maximum Permitted Speed of 180 km/h. 33

The minimum distance between two consecutive Balises shall be 3.0 m from centre to centre, on lines with a Maximum Permitted Speed of 300 km/h.

The minimum distance between two consecutive Balises shall be 5.0 m from centre to centre, on lines with a Maximum Permitted Speed of 500 km/h.

The minimum distances between Eurobalises are visualised as shown in Figure 27 and Figure 28 below.

<!-- Start of picture text -->
Minimum<br>[m]  Balise<br>Distance<br>5.0<br>3.0<br>2.3  Maximum<br>Permitted Speed<br>180  300  500  [km/h]<br><!-- End of picture text -->

**Figure 27:  Minimum Distance Between Reduced Size Eurobalises**

<!-- Start of picture text -->
Minimum<br>[m]  Balise<br>Distance<br>5.0<br>3.0<br>2.6  Maximum<br>Permitted Speed<br>180  300  500  [km/h]<br><!-- End of picture text -->

**Figure 28:  Minimum Distance Between Standard Size Eurobalises**

For information on distance between clusters of Balises, see sub-clause 4.2.9 on page 33.

### **5.6.4 Number of Balises in a Balise Group**

The number of Balises in a Balise group shall be as defined in SUBSET-026, SUBSET-040, and SUBSET-091.

> 33 If the distance is closer, then there is a risk for cross-talk in the side lobes from the respective Up-link Balises.  Additionally, the timing constraints for the On-board Transmission Equipment are affected.

<!-- end of page 87 -->

### **5.6.5 Balise Installation in Narrow Curves**

### 5.6.5.1 General

In general, this specification applies for the minimum horizontal curve radius 300 m and the minimum vertical curve radius 9000 m.  This sub-clause (5.6.5) defines restrictions required in case Balise installation in more narrow curves is needed.

### 5.6.5.2 Engineering Rules

For each combination of vertical (convex or concave) and horizontal curvature, the set of installation restrictions are defined in Table 13 below.  The detailed restrictions are defined in sub-clause 5.6.5.3 below.

|Horizontal Radius|R ≥ 300 m|300 m > R ≥ 260 m|260 m > R ≥ 200 m|200 m > R ≥ 180 m|
|---|---|---|---|---|
|Vertical Radius|||||
|R ≥ 9000 m|No additional|5.6.5.3.1|5.6.5.3.1|5.6.5.3.1|
||limitations|5.6.5.3.2|5.6.5.3.2|5.6.5.3.2|
|||5.6.5.3.3|5.6.5.3.3|5.6.5.3.3|
|||5.6.5.3.4|5.6.5.3.5|5.6.5.3.5|
|||5.6.5.3.6|5.6.5.3.6|5.6.5.3.6<br>5.6.5.3.7|
|9000 m > R ≥ 3000 m|5.6.5.3.9|5.6.5.3.1|5.6.5.3.1|5.6.5.3.1|
|||5.6.5.3.2|5.6.5.3.2|5.6.5.3.2|
|||5.6.5.3.3|5.6.5.3.3|5.6.5.3.3|
|||5.6.5.3.4|5.6.5.3.5|5.6.5.3.5|
|||5.6.5.3.6|5.6.5.3.6|5.6.5.3.6|
|||5.6.5.3.9|5.6.5.3.9|5.6.5.3.7<br>5.6.5.3.9|
|3000 m > R ≥ 2000 m|5.6.5.3.9|Not supported|Not supported|Not supported|
|2000 m > R ≥ 1100 m|5.6.5.3.8<br>5.6.5.3.9|Not supported|Not supported|Not supported|
|R < 1100 m|Not supported|Not supported|Not supported|Not supported|

**Table 13:  Installation Restrictions versus Curve Radii**

<!-- end of page 88 -->

### 5.6.5.3 Installation Restrictions

#### **5.6.5.3.1 Vertical Installation Height**

The vertical installation height of the Balise shall be within the interval between 93 mm and 140 mm below the top of rail.

<!-- Start of picture text -->
Top of rail<br>93 mm  d  140 mm<br><!-- End of picture text -->

#### **5.6.5.3.2 Longitudinal Installation**

Longitudinal installation of the Reduced Size Balise is not allowed.

#### **5.6.5.3.3 Metallic Plane**

There shall be no metallic plane closer than 400 mm below the Balise.

<!-- Start of picture text -->
d  400 mm<br><!-- End of picture text -->

Metallic Plane

<!-- end of page 89 -->

#### **5.6.5.3.4 Maximum Permitted Speed 1**

The highest permitted speed is 100 km/h.

#### **5.6.5.3.5 Maximum Permitted Speed 2**

The highest permitted speed is 85 km/h.

#### **5.6.5.3.6 Steel Sleeper**

Balise mounting on steel sleepers is not allowed.

#### **5.6.5.3.7 Balise Displacement**

The Balise shall be displaced 15 mm towards the centre of the curve.  Installation tolerances according to “general applications” in section 5.6.2.3 apply.

<!-- Start of picture text -->
d = 15 mm<br>Centre of track<br><!-- End of picture text -->

#### **5.6.5.3.8 Debris**

Debris Class A application is not allowed.

#### **5.6.5.3.9 Reduction of Vertical Installation Interval**

For vertical radius R between 1100 m and 9000 m, the reduction shall be ((45000/R) -5) mm applicable to both the highest and the lowest allowed installation height (in order to cope with both convex and concave curvature and antenna installation in the front of and in the rear of the bogie).

The following figure illustrates how much the installation range shall be reduced as a function of vertical curve radius (e.g., for a vertical curve radius of 3000 m combined with a horizontal curve radius of less than 300 m, the allowed installation range is between 103 mm and 130 mm below the top of rail).

<!-- end of page 90 -->

<!-- Start of picture text -->
Reduction of<br>installation<br>range<br>±35 mm<br>±17.5 mm<br>(45000/R) -5<br>±10 mm<br>1100  2000  3000  9000  Vertical curve<br>radius R in m<br><!-- End of picture text -->

<!-- end of page 91 -->

## **5.7 Specific Environmental Conditions for Balises**

### **5.7.1 Operational Temperature**

The Balise shall fulfil one of the classes of sub-clause 4.3 (Temperature) of EN 50125-3.

### **5.7.2 Storage**

During transit and storage, i.e., within a maximum of two weeks, the Balise should not be damaged by exposure to ambient temperatures in the following range:

Tmin = -40<sup>o</sup> C<sup>34</sup>

Tmax = +85<sup>o</sup> C

The Balise should be designed to be held in storage for a maximum period of 5 years without any requirement for test and inspection. During such storage, the ambient temperature should not exceed the following range:<sup>35</sup>

Tmin = +15<sup>o</sup> C

Tmax = +35<sup>o</sup> C

### **5.7.3 Sealing, Dust and Moisture**

The Balise enclosures should be designed as to allow correct operation at the IP67 environmental rating as defined in EN 60529.

All exposed modules and sub-assemblies used in the Eurobalise equipment should be sealed against the effects of moisture, mould growth and contamination.

### **5.7.4 Mechanical Stress**

The Balise shall fulfil applicable parts of sub-clause 4.13 (Vibration and Shocks) of EN 50125-3.

### **5.7.5 Meteorological Conditions**

The Balise shall fulfil applicable parts of sub-clauses 4.4 (Humidity), 4.5 (Wind), 4.6 (Rain), 4.7 (Snow and Hail), 4.8 (Ice), and 4.9 (Solar Radiation) of EN 50125-3.

### **5.7.6 Lightning**

The Balise shall as a minimum fulfil item 1.5 of Table 1, and item 2.3 of Table 2, in EN 50121-4.

### **5.7.7 Chemical Conditions**

The Balise shall fulfil applicable parts of sub-clause 4.11 (Pollution) of EN 50125-3.

> 34 A lower temperature can be specified for specific products that do not contain components that are only specified for a minimum temperature of -40<sup>o</sup> C.

> 35 This requirement is a minimum requirement that every manufacturer shall fulfil.  Other storage temperatures can be considered in addition to these requirements for a specific customer.

<!-- end of page 92 -->

### **5.7.8 Biological Conditions**

The Balise shall fulfil applicable parts of sub-clause 4.11 (Pollution) of EN 50125-3.

### **5.7.9 Debris**

The debris shall be applied on the Balise under test in accordance with sections B5.2.2 and B5.2.3 of SUBSET085.

The following Table 14 specifies the debris on the Balise, and the corresponding Classes A and B.

|**Material**|**Description**|**Layer on top o**|**f Balise,  [mm]**|
|---|---|---|---|
|||**Class B**|**Class A**|
|Water|Clear|100|200|
||0.1 % NaCl (weight)|10|100|
|Snow|Fresh, 0<sup>o</sup>C|300 (Note<sup>36</sup>)|300 (Note<sup>36</sup>)|
||Wet, 20 % water|300 (Note<sup>36</sup>)|300 (Note<sup>36</sup>)|
|Ice|Non porous|100|100|
|Ballast|Stone|100|100|
|Sand|Dry|20|20|
||Wet|20|20|
|Mud|Without salt water|50|50|
||With salt water, 0.5 %<br>NaCl (weight)|10|50|
|Iron Ore|Hematite (Fe2O3)|20|20|
||Magnetite (Fe3O4)|2|20|
|Iron dust<sup>37</sup>|Braking dust|10|10|
|Coal dust|8 % sulphur|10|10|
|Oil and Grease||50|50|

**Table 14:  Debris layers on top of the Balise and its Classes.**

A Class A Balise is a Balise fulfilling the requirements of this specification when applying Class A debris conditions, and a Class B Balise is a Balise fulfilling the requirements of this specification when applying Class B debris conditions.

> 36 300 mm or up to the bottom of the Antenna Unit.

> 37 A non-conductive mixture of grease and iron oxide which is normally encountered in the Railway environment.

<!-- end of page 93 -->

The flux levels  d1 and  d2 of sub-clause 5.2.2.6 on page 63 shall be increased when the Balise is subjected to some debris conditions.  The flux increase shall be in accordance with Table 15 below for the  d1 and  d2 levels.

|**Material**|**Description**|**Flux inc**|**rease, [dB]**|
|---|---|---|---|
|||**Class B**|**Class A**|
|Water|Clear|2.0|3.0|
||0.1 % NaCl (weight)|1.0|2.5|
|Iron Ore|Magnetite (Fe3O4)|1.0|2.0|

**Table 15:  Flux Increase (**  **d1 and**  **d2 levels).**

The influence of debris affects the transmission in two ways:

1. The Input /Output characteristics of the Balise (e.g., the tuning of the Balise) are affected.

2. The mutual coupling between Balise and Antenna Unit is affected.

The Balise should have a Balise Class A or B based on the influence corresponding to item 1 above.

There shall be a clear marking that identifies the Balise Class of the Balise.

<!-- end of page 94 -->

### **5.7.10 Metallic Masses and Cables in proximity**

### 5.7.10.1 Metal Free Volume

A Balise shall be mounted in such a way that metal, except for the approved mounting details, is avoided in a cubic volume around the Balise, as shown in Figure 29 and Figure 30.  The limits to the sides and downwards (in the directions X, Y, and Z) refer to the reference marks of the Balise.  The origin of this co-ordinate system is the centre of a right angle reference system passing through the reference marks of the Balise.  Upwards, in the Z- direction, the metal free volume shall extend above the Balise limited only by the vertical track clearance.  Electrically closed horizontal loops are not allowed around or above the Balise at the limits of the defined metal free zone.

<!-- Start of picture text -->
Sleeper<br>Z-direction<br>Y-direction<br>Standard Size<br>Balis e<br>400  mm 210 mm<br>470  mm X-direction<br><!-- End of picture text -->

**Figure 29:  Metal free volume for Standard Size Balise**

<!-- Start of picture text -->
Sleeper<br>Z-direction<br>Y-direction<br>Reduced Size<br>Balis e<br>315  mm 210 mm<br>410  mm X-direction<br><!-- End of picture text -->

**Figure 30:  Metal free volume for Reduced Size Balise**

These limits of the metal free volume apply to normal operation situations.  For transversal mounting of the Reduced Size Balise Figure 30 applies 90  rotated, so that the free space in the Y direction is 410 mm and the free space in the X direction is 315 mm.

When such a metal free volume cannot be found, the mounting height shall be adjusted according to sub-clause 5.7.10.5 on page 102. Moreover, the minimum horizontal distances from metal masses specified on Chapters 6.2.1.7 and 6.2.1.8 shall be respected.

The influence from concrete and bi-block sleepers shall be allowed for in the overall tolerances for the Balise. This means that no compensation of the height shall be needed for these types of sleeper.

<!-- end of page 95 -->

An infringement of the metal-free volume of small metal objects intruding from the sides of the metal-free volume, is permitted if the intrusion in the Y-direction is  110 mm and the width of the objects in the X-direction is  180 mm.

<!-- end of page 96 -->

### 5.7.10.2 Mounting to Steel Sleeper

The requirements of this sub-clause are optional, and apply only to products intended to be used during such conditions.

For steel sleepers the specified mounting height Zb shall be adjusted for the amount of iron masses near the Balise.

The Standard Size Balise shall be mounted with its reference marks at a distance of at least 45 mm above the top of a steel sleeper.  The lowest position of the Standard Size Balise (Zb) in sub-clause 5.6.2.1 on page 83 will therefore be raised by 45 mm.  The highest position of the Balise shall be 93 mm below the top of rail.

The Reduced Size Balise shall be mounted with its reference marks at a distance of at least 60 mm above the top of a steel sleeper.  The lowest position of the Reduced Size Balise (Zb) in sub-clause 5.6.2.1 on page 83 will therefore be raised by 60 mm.  The highest position of the Balise shall be 79 mm below the top of rail for -160 mm ≤ Z ≤ -139 mm, otherwise 93 mm below the top of rail.

Please observe that the highest position of the steel sleeper is 139 mm below the Top of Rail.

<!-- Start of picture text -->
Top of Rail<br>Z  –139 mm<br> 45 mm for Standard Size Balise<br>35 mm± 5 mm    60 mm for Reduced Size Balise<br>35 mm ± 5 mm<br>80 mm ± 40 mm<br>135 mm± 15 mm<br>Steel sleeper<br>230 mm ± 35 mm<br><!-- End of picture text -->

**Figure 31:  Balise mounted to a steel sleeper**

<!-- end of page 97 -->

### 5.7.10.3 Mounting to Other Sleeper

The size of metallic mounting assemblies shall be restricted when mounting a Balise to other than steel sleepers. When viewing the metallic mounting assemblies in the Z-direction, the total area in the X/Y plane of projection shall not exceed:

300 cm² for a Standard Size Balise.

140 cm² for a Reduced Size Balise, transversal mounting.

140 cm² for a Reduced Size Balise, longitudinal mounting.

The mounting assembly and the reinforcement of a concrete sleeper should not create or have the form of conductive loops.  If they do, the requirements stated in the sub-clauses 5.7.10.1 and 5.7.10.2 apply.  The mounting assembly and reinforcement, and the exact positions and forms of metallic mounting assemblies that are allowed, should be specified by the manufacturer of the Balise.

<!-- end of page 98 -->

### 5.7.10.4 Guard Rails

#### **5.7.10.4.1 Laterally displaced Guard Rails**

As an exception to the metal free area as defined in section 5.7.10.1, guard rails may be located in the metal free area under the following conditions.  For ensuring both cross-talk protection and reliable transmission, guard rails in the vicinity of Balises shall be cut, leaving gaps of at least 20 mm.  Such a cut shall be done within ±300 mm in the X-direction from the Z reference mark of the Balise (see distance dx in Figure 32 below).<sup>38</sup>

<!-- Start of picture text -->
Normal rails  Guard rails<br>d y d y<br>d x<br>dx<br>Cut<br><!-- End of picture text -->

**Figure 32:  Laterally Displaced Guard Rails**

In the Y-direction, measured from the Z reference mark of the Balise, the distance shall be at least (the guard rails may be positioned on either or both sides of the Balise):

- dy  300 mm for the Standard Size Balise,

- dy  320 mm for the Reduced Size Balise, transversal mounting,

- dy  220 mm for the Reduced Size Balise, longitudinal mounting. At a level of 100 mm above the X and Y reference marks, the distance shall be at least 190 mm.<sup>39</sup>

If a guard rail is not parallel with the Balise, the shortest distance to the guard rail along the entire Balise applies. The meaning with gaps above is that it is either free air, or filled with dielectric material.

> 38 In rare circumstances (e.g., unfavourable combinations of the length of the guard rail related to the wave propagation properties), full intrinsic cross-talk protection can not be guaranteed on a single Balise level.  However, additional protection is ensured on system level (such as balise groups with multiple Balises, linking, etc.).

> 39 This allows for cutting one side of the rail foot but leaving the rail head intact.

<!-- end of page 99 -->

#### **5.7.10.4.2 Centrally positioned Guard Rails**

In some applications there are two guard rails centrally positioned in the track that without any precaution would pass through the metal free area as defined in section 5.7.10.1.  Where Balises are supposed to be installed, there shall be gaps in the guard rails to respect the metal free area as defined in section 5.7.10.1.  The following defines the allowed installation cases.

The guard rail positions with respect to the top of the rail.

<!-- Start of picture text -->
Z=0<br>Zgr<br><!-- End of picture text -->

<!-- Start of picture text -->
Z<br>Y<br>X<br><!-- End of picture text -->

Balise positioning and gap in guard rails

<!-- Start of picture text -->
Top of rail<br>Zb<br>Guard Rail  Guard Rail<br>l2<br>Z<br>l1<br>Y  X<br><!-- End of picture text -->

**Figure 33:  Centrally positioned Guard Rails**

The following distances apply to allowed configurations:

- Zgr ≥ 0 mm

- Zb shall fulfil the defined installation rules for Balises

- l1 ≥ 0.94 m

- l2 ≥ 0.47 m

In case Zgr  50 mm, the total width of the upper vertical projection of the guard rails shall not exceed 200 mm in order to respect the requirements of section 6.5.2 (i.e., the foots of the guard rail may be wider).

<!-- end of page 100 -->

#### **5.7.10.4.3 Derailment plinth**

In some applications there is a concrete derailment plinth (with metallic reinforcement) positioned in the middle of the track.  Where Balises are supposed to be installed, there is a gap in the derailment plinth.  The following defines the allowed installation cases.

<!-- Start of picture text -->
Metallic reinforcement position of the derailment plinth with respect<br>to the top of the rail<br>Z=0<br>Zp<br>Derailment Plinth<br>W<br>Z  Metallic plane<br>Y<br>X<br><!-- End of picture text -->

Balise positioning and gap in derailment plinth

<!-- Start of picture text -->
Top of rail<br>Zb<br>Derailment  Derailment<br>Plinth  Plinth<br>d<br>Metallic Plane<br>Z  l2<br>l1<br>Y  X<br><!-- End of picture text -->

**Figure 34:  Derailment Plinth**

The following distances apply to allowed configurations:

- Zp ≥ 80 mm

- W  500 mm

93 mm  Zb  138 mm

- d ≥ 140 mm

- l1 ≥ 1 m

- l2 ≥ 0.5 m

<!-- end of page 101 -->

### 5.7.10.5 Other interfering Conductive Material

If the surface below the Balise contains a conductive structure such as a metal sheet or a net of conductors that are connected in the crossing points<sup>40</sup> , and this metal is closer than 210 mm, then the mounting height Zb must be adjusted.  The mounting height Zb and the distance d refer to the actual top of rail (Z=0), for which the rail wear shall be considered.

The Balise mounting height (Zb) from the top of rail to the reference mark in the presence of a metal structure.

<!-- Start of picture text -->
Z=0<br>Zb<br>d<br>Zb Standard Size Balise<br>[mm]<br>-93<br>Zb maximum<br>-152<br>Zb minimum<br>d<br>-210 [mm]<br>233 292 420<br><!-- End of picture text -->

<!-- Start of picture text -->
Zb Reduced Size Balise (transversal and longitudinal)<br>[mm]<br>-93<br>Zb maximum<br>-143<br>Zb minimum<br>d<br>-193 [mm]<br>233 283 403<br><!-- End of picture text -->

**Figure 35:  Mounting heights for Balise in proximity to metal structure**

> 40 It is common that iron reinforcement in concrete track beds forms a net of conductors that are connected in the crossing points.

<!-- end of page 102 -->

### 5.7.10.6 Mounting in the extreme vicinity of Metal Planes

For mounting in the extreme vicinity of metallic planes, the specified mounting height shall be adjusted for the amount of metal masses near the Balise.

The requirements of this sub-clause are optional, and only apply to products intended to be used during the following conditions.

It is allowed that specifically tuned Balises are used in combination with this specific installation condition<sup>41</sup> .

Please observe that this specific installation case imposes that the Balise may be mounted higher than the general rule for the highest allowed Balise mounting defined in sub-clause 5.6.2.2 on page 84.  In this case, the implication is that the below-defined case shall always include the metallic plane at the defined distance to the Balise when the limitations of sub-clause 5.6.2.2 on page 84 are violated.  It is in this case also required that the metallic plane is significantly larger than the Balise<sup>42</sup> , and that it is centred with respect to the Balise reference marks. For testing purposes, the definitions of SUBSET-085 that correspond to sub-clause 5.7.10.5 on page 102 herein apply also to this case, except that the specific distances defined below shall be used.

The basic requirement is that the metallic plane may be positioned as high as 186 mm below the Top of Rail. For mounting conditions with the metallic plane more than 233 mm below the Top of Rail, see sub-clause 5.7.10.5 on page 102.

The distance between the Balise and the Top of Rail, Zb, shall be in accordance with Figure 37 or Figure 38 below.

Regarding the lateral deviation of the Balise, the installation requirements for general applications in sub-clause 5.6.2.3 on page 85 apply.

This installation condition shall only be applied where the track curve radius is more than 1000 m.

For this installation condition, only short telegrams shall be used for Maximum Permitted Speed above 300 km/h (applies to both Standard Size Balises and Reduced Size Balises).

For this installation condition, a Maximum Permitted Speed of 180 km/h applies for the transversally mounted Reduced Size Balise.

It is not allowed to combine the use of toggling modulation with this specific installation.

<!-- Start of picture text -->
To p  of rail<br>Zb<br>-233 mm  d  -186 mm<br>Metallic Plane<br><!-- End of picture text -->

**Figure 36:  Balise mounted in the extreme vicinity of Metal Planes**

> 41 In such cases, since the metal plane can be regarded as an integral part of the Balise, all applicable requirements shall be fulfilled in the presence of the metallic plane, with the exception of Field Conformity, in which free air conditions apply.

> 42 This installation case does not apply to reinforcement in concrete, which is considered covered by sub-clause 5.7.10.5 on page 108.  This case typically applies to metal bridges or other solid metal surfaces.

<!-- end of page 103 -->

<!-- Start of picture text -->
Zb d<br>[mm] -233 -203 -186 [mm]<br>Zb maximum<br>-76<br>-86<br>-93<br>Zb minimum<br>-103<br><!-- End of picture text -->

**Figure 37:  Mounting height, Standard Size Balise**

<!-- Start of picture text -->
Zb d<br>[mm] -233 -193 -186 [mm]<br>Zb maximum<br>-86<br>-93<br>-96<br>-103<br>Zb minimum<br><!-- End of picture text -->

**Figure 38:  Mounting height, Reduced Size Balise**

<!-- end of page 104 -->

### 5.7.10.7 Interfering Conductive Cables

#### **5.7.10.7.1 LZB Cables**

To ensure cross-talk protection there are restrictions in the way cables can be placed in the proximity of the Balise.  The surface above the Balise shall be free from cables and metal material other than those approved. Figure 39 shows the approved mounting of a conductive loop cable on top of and along the X-axis of the Balise. The conductive loop cable may be positioned either on top of the Balise, or underneath the Balise.

<!-- Start of picture text -->
Loop cable with approved location.<br>dmax = 20 mm<br>Balise<br>dmax  is the maximum exterior<br>Sleeper  diameter of a loop cable<br>compatible with loop systems.<br><!-- End of picture text -->

**Figure 39:  Location of a conductive loop cable**

The company specific Balise installation rules (i.e., installation tolerances and the related fastening devices for the conductive loop cable) shall ensure that the maximum Up-link induction into the conductive loop cable is limited to 0.3 mA (see sub-clause 6.6.10 on page 130).  The centre of the conductive loop cable shall always be positioned more than 75 mm below the top of rail during coexistence with Eurobalise.<sup>43</sup>

The acceptance criteria are company specific, and shall consider the company specific installation rules.  The test limit (0.3 mA), under the responsibility of the Balise manufacturer, shall consider installation rules, source and load impedance, matching conditions, type of soil, metallic bridges, metallic structures, and cable crossings (phenomena likely to cause resonance phenomena).  For test purposes, the specific set-up of SUBSET-085 applies.

The company specific Balise installation rules (i.e., installation tolerances, the related fastening devices for the conductive loop cable, and in some exceptional cases recommended suitable ferrite devices) shall also ensure that the maximum allowed Tele-powering induction into the conductive loop cable does not generate a malfunction of the Balise (e.g., an erroneous start-up behaviour and/or a continuously activated Balise).

> 43 In rare circumstances (e.g., unfavourable combinations of the length of the conductive loop cable related to the wave propagation properties), full intrinsic cross-talk protection can not be guaranteed on a single Balise level.  However, additional protection is ensured on system level (such as Balise Groups with multiple Balises, linking, etc.).

<!-- end of page 105 -->

It is assumed that the maximum allowed induction generated by the On-board Transmission Equipment, induced into conductive loop cables, is limited and defined according to sub-clause 6.6.10 on page 130<sup>44</sup> .  The current into real conductive loop cables might be different, and may fluctuate along the conductive loop cable due to electromagnetic coupling with the surroundings of the cable.

When installing Balises, it shall be guaranteed that the current level defined below is not exceeded above the Balise.  The solution is that suitable ferrite devices are applied on the LZB cable (at least one ferrite on each side of the Balise) in some exceptional cases for the purpose of reducing the 27 MHz current.  Key parameters for the suitable devices are found in Annex C (clause C2 on page 142).  In installations where the centre of the LZB cable is always positioned more than 105 mm below the top of the rail, ferrite devices should not be used.  In installations where the centre of the LZB cable is anywhere along the cable segment positioned within the interval 75 mm to 105 mm below the top of rail, and/or longitudinal mounting of Reduced Size Balises applies, ferrite devices with properties as defined in clause C2 on page 142 shall be applied.  It is assumed that the LZB cable is never installed higher than 75 mm below the top of the rail (during coexistence with Eurobalises).

The acceptance criteria for the purpose of 27 MHz testing of Balises, shall consider the company specific installation rules.  The test limit shall consider the same aspects as for Up-link induction above, and shall be 250 mA.

For test purposes, the specific set-up of SUBSET-085 applies.  Please observe that during laboratory testing, using the set-up of SUBSET-085 and the limit above, no ferrite devices shall be applied.

The acceptance criteria for Balise testing may be limited to checking that the Balise does not start generating any Up-link signal (defined as no Up-link signal exceeding Iu1 -10 dB), and that it shows correct start-up behaviour when subjected to a typical dynamic Tele-powering ramp (CW and toggling).

The company specific installation rules shall consider the fluctuation of the resultant current along the conductive loop cable due to electromagnetic coupling to the surroundings of the conductive loop cable (e.g., reflections, standing waves, etc.).

The above requirements related to the Balise in the presence of LZB cables only apply to products intended for this use.

> 44 The values of sub-clause 6.6.10 on page 138 are assumed under the condition of minimum serial loop impedance of 75  for the installed LZB cable.

<!-- end of page 106 -->

#### **5.7.10.7.2 Other Cables**

The Balise shall be installed in such a way that the interaction with other cables is low.  The Balise shall be far enough from a cable to guarantee that the interaction with the cable is kept below the levels defined in the following.

<!-- Start of picture text -->
B<br>Balise<br>A<br>C   The level of the<br>reference mark<br>of the Balise<br>The required distances A, B, and C, and the<br>combinations A/C and B/C respectively shall<br>be defined by the supplier of the balise.<br><!-- End of picture text -->

**Figure 40:  Location of other cables**

When defining the distances A, B, and C, the metal free volume in sub-clause 5.7.10.1 on page 95 shall be respected.

The Balise shall be installed in such a way that the induction from the Up-link signal to any nearby cable causes a current:

- Less than 2 mA in the Up-link frequency band when the cable passes the same track at another position, or passes another track.  At those passing positions, the applicable vertical distance is equal to or exceeds 93 mm below the top of the rail in this case.

- Less than 10 mA in the Up-link frequency band when the cable passes the same track at another position, or passes another track.  At those passing positions, the applicable vertical distance is equal to or exceeds 493 mm below the top of the rail in this case.

These values consider the maximum Up-link current possible for the specific Balise under consideration.

The Balise shall be installed in such a way that a current of a certain maximum value being induced in a nearby cable from a Tele-powering signal does not generate a malfunction of the Balise (e.g., input-to-output characteristic).

It is assumed that the maximum allowed induction generated by the On-board Transmission Equipment, induced into cables at a position underneath the Antenna Unit, is limited and defined according to sub-clause 6.6.10 on page 130.  The current into real cables might be different, and may fluctuate along the cable due to electromagnetic coupling with the surroundings of the cable.

The company specific installation rules shall handle the current arising in the vicinity of the Balise (Up-link and Tele-powering) by rules that limit the influence to the Balise so that the requirements above are fulfilled (no cross-talk or no malfunction respectively).

For the case of cables equal to or more than 93 mm below top of rail, it can be assumed that the requirements are fulfilled if a cable is more than two meters away from the Balise.  In the same way, the distance one metre is assumed sufficient for the 493 mm case.  This applies to both Up-link and Tele-powering, and assuming normal conditions.

The installation rules shall consider the fluctuation of the resultant current along the cable due to electromagnetic coupling to the surroundings of the cable (e.g., reflections, standing waves, etc.).

For the Interface ‘C’ cable, all installation rules shall be defined by the supplier of the Balise.  However, the maximum induced currents specified above shall be respected.

<!-- end of page 107 -->

## **5.8 Specific EMC Requirements**

### **5.8.1 In-band Emission**

The Up-link Balise shall comply with EN 302 608.

### **5.8.2 Out-band Emission**

The Up-link Balise shall comply with EN 302 608.

### **5.8.3 Susceptibility Requirements**

The Up-link Balise shall comply with the applicable items of table 1 and table 2 in sub-clause 6.2 of EN 501214.  This requirement does neither apply for the in-band frequency band 4.234 MHz  1 MHz, nor for the frequency range  500 kHz centred on the Tele-powering carrier frequency.

## **5.9 Specific Electrical Requirements**

### **5.9.1 General**

During normal operation, as well as in accidental conditions, the installation of the Balises and the related Balise controlling interface cables shall be provided with suitable means to ensure:

- protection of persons against electric shock hazard (e.g., stepping over the Balise);

- protection of equipment against damage due to over-voltage.

### **5.9.2 Provisions against accidental contact with the traction power voltage**

In accordance with sub-clause 7.1 of EN 50122-1, the parts that are located within the “Overhead contact line zone, or pantograph zone” (as defined in chapter 4 of EN 50122-1), shall be protected according to the provisions defined in sub-clauses 7.3 and 7.4 of EN 50122-1.

<!-- end of page 108 -->

### **5.9.3 Insulation co-ordination**

For the insulation co-ordination according to EN 50124-1, special attention shall be given to sub-clause 6.1 of EN 50124-1.  For the Balise, the following parameters apply:

- Over-voltage category

Over-voltage category OV3 shall be considered for the Balise either in stand-alone use, or connected via the Balise controlling interface cable to the LEU.

- Working voltage

The worst case working voltage shall be determined, considering the Tele-powering originated voltage (as per sub-clause 5.2.2.6 on page 63), induced voltages (as per sub-clause 6.1.3 of EN 50124-1), as well as the auxiliary energy source (as per sub-clause 5.3.3 on page 73).

- Rated impulse voltage

The Rated Impulse Voltage (UNi) shall be determined on the basis of Table A.1 of EN 50124-1.

For Balises, a minimum Rated Impulse Voltage of 4 kV shall be considered between any metallic part in the Balise (e.g., fixing devices, connectors, etc.) directly or indirectly connected to the earth, and the Balise case.

- Pollution degree

For parts that are placed outdoors (the Balise itself, and the Balise controlling interface cable), the pollution degree PD4B shall be considered.

### **5.9.4 Dielectric Tests**

Dielectric tests shall be carried out on specimen of stand alone Balises, or on typical arrangements of Balises with the Balise controlling interface cable, in order to verify the fulfilment of the insulation requirements of subclause 5.9.3 above.  Tests shall be organised and carried out in accordance with Annex B of EN 50124-1.

## **5.10 Requirements for Test Tools and Procedures**

See SUBSET-085, which includes a complete set of test specifications, test procedures, and test tools regarding the mandatory tests.

## **5.11 Quality and Safety Assurance**

All actions shall comply with the methodology stated in EN 50126, and with the methods stated in EN 50129 and EN 50128 (if applicable).

<!-- end of page 109 -->
