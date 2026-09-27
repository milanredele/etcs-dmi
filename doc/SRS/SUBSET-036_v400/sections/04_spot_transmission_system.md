# **4 Spot Transmission System**

## **4.1 Architectural Layouts**

### **4.1.1 Introduction**

The Eurobalise Transmission System is a safe spot transmission based system conveying safety related information between the wayside infrastructure and the train.

The Eurobalise Transmission System is a spot transmission system, where transmission is implemented by Balises.

Information transmitted from an Up-link Balise to the On-board Transmission Equipment is fixed or variable depending upon the application (Up-link data transmission).

Spot transmission is when a transmission path exists between the wayside equipment and the On-board Transmission Equipment at discrete locations.  The information is provided to/from the train only as the Antenna Unit passes or stands over the corresponding Balise.  The length of track on which the information is passed and received is limited to approximately one meter per Balise.

The Eurobalise Transmission System is intended for use in all of the levels of applications defined within the ERTMS/ETCS (called Level 0, Level 1, Level 2 and Level NTC respectively).

### **4.1.2 Units and Functions**

The Eurobalise Transmission System consists of the (wayside) Balise and the On-board Transmission Equipment (that is part of the ERTMS/ETCS On-board constituent).  Balises are of either fixed type or controlled type.  The On-board Transmission Equipment consists of the Antenna Unit and the BTM function.  The Wayside Signalling Equipment consists of the LEU and other external equipment involved in the wayside signalling process.

See Figure 1 of sub-clause 4.1.3.1 on page 21.

<!-- end of page 20 -->

### **4.1.3 Interfaces**

### 4.1.3.1 Overall Configuration

<!-- Start of picture text -->
ERTMS/ETCS<br>ERTMS/ETCS<br>On-board<br>Kernel<br>Constituent<br>Test<br>Interfaces<br>BTM function Interface<br>On-board<br>Adapter<br>Transmission<br>Equipment<br>Antenna Unit<br>‘A’<br>‘A’ Eurobalise<br>Transmission<br>Balise Balise System<br>Fixed Controlled<br>‘C’<br>Wayside LEU<br>Signalling<br>Equipment ‘S’<br>To Wayside Signaling<br>or Interlocking<br><!-- End of picture text -->

**Figure 1:  Eurobalise Transmission System, Interfaces**

The On-board Transmission Equipment communicates with the ERTMS/ETCS Kernel.  The Balise communicates with the Wayside Signalling Equipment via Interface ‘C’.  The LEU (part of the Wayside Signalling Equipment) communicates with the wayside signalling or interlocking via (the non-standardised) Interface ‘S’.

<!-- end of page 21 -->

### 4.1.3.2 External Interfaces

There is one preferred external standardised interface to and from the Eurobalise Transmission System:

**Interface 'C'** This is defined as the wayside interface between the Balise and the LEU. Telegrams are sent serially at the same data rate as in the air gap.  This interface is split into the following subinterfaces:

|Interface ‘C1’|This is an interface used for transmitting Up-link Eurobalise telegrams from<br>the LEU to the Balise.|
|---|---|
|Interface ‘C4’|This is an optional interface used for inhibiting switching of telegrams in the<br>LEU during a Balise passage.|
|Interface ‘C6’|This is an interface used for biasing the serial interface (‘C1’) input circuits<br>of a controlled Up-link Balise (transmitted from the LEU).|

There is also an Interface 'S' that is defined as the input to the LEU that interfaces the different national railway signalling equipment. This is not a part of the Eurobalise Transmission System.

Finally, there is an optional interface defined for programming the Fixed Telegram (for Fixed Balises) or the Default Telegram (for Controlled Balises) into the Balise using wire aided programming when applicable.  This interface is denominated Interface ‘C5’.  Requirements are found in sub-clause 5.4 on page 74, but the interface is not within the scope of this specification.

### 4.1.3.3 Internal Interfaces

There is one internal standardised interface within the Eurobalise Transmission System:

**Interface 'A'** This interface is split into the following sub-interfaces:

Interface ‘A1’ This is an interface used for transmitting Up-link Eurobalise telegrams from the Up-link Balise to the Antenna Unit. Interface ‘A4’ This is an interface used for transmitting the required power (Tele-powering) from the Antenna Unit to the Up-link Balise.

Additionally, there is an optional interface defined for programming the Fixed Telegram (for Fixed Balises) or the Default Telegram (for Controlled Balises) into the Balise using inductive programming when applicable. This interface is denominated Interface ‘A5’.  Requirements are found in sub-clause 5.4 on page 74, but the interface is not within the scope of this specification.

<!-- end of page 22 -->

### 4.1.3.4 Test Interfaces

There are three functional interfaces available for testing the Eurobalise Transmission System:

- **Interface 'V1'** This is an interface used for testing various properties of the BTM function.  In particular, it includes a specific sub-set designed for testing the Eurobalise Transmission System.  The interface is not required to be integrated in the operational equipment.  A company specific adapter (allowed to be external to the operational equipment) is used for providing the standardised interface.

- **Interface 'V2'** This is an interface transmitting time and odometer information to the BTM function during testing.  The interface is not required to be integrated in the operational equipment.  A company specific adapter (allowed to be external to the operational equipment) is used for providing the standardised interface.

- **Interface 'V4'** This interface comprises a pair of square wave signals giving the information of the longitudinal speed and the running direction of the Antenna Unit.  This is used during testing, and is an alternative to using Interface ‘V2’ above.  The interface is not required to be integrated in the operational equipment.  A company specific adapter (allowed to be external to the operational equipment) is used for providing the standardised interface.

<!-- end of page 23 -->

### **4.1.4 Basic Functions**

The Eurobalise Transmission System comprises the following basic functions:

On-board Transmission Equipment functionality:

- Generation of Tele-powering signal

- Assurance of Tele-powering signal level and Balise detectability

- Detection of Up-link Balises

- Up-link signal filtering and demodulation

- Physical Cross-talk protection

- Physical prevention of transmission of Side lobes, and/or management of Side lobe effects in data and in location

- Immunity to environmental noise

- Checking of Up-link incoming data with respect to Coding Requirements

- Detection of telegram type and decoding

- Extraction of user data

- Telegram Filtering

- Management of Up-link telegram switching within a Balise passage

- Time and odometer stamping of output data

- Support for Balise Localisation (for vital and non-vital purposes)

- Time and odometer data management

- Detection of Bit Errors

- Start-up tests

Optional On-board Transmission Equipment functionality:

- KER Up-link signal reception

- KER Up-link data checking and decoding

- Up-link KER data reporting

- Switching of Tele-powering mode (CW, toggling modulation)

- Logical Cross-talk protection management

- Self tests

<!-- end of page 24 -->

Up-link Balise functionality:

- Reception of Tele-powering signal

- Up-link signal generation

- Data management

- Mode selection at start-up

- Limitation of the Up-link field (i.e., the Balise current)

- Support to programming and management of operational/programming mode

- Reception of data from Interface ‘C’

- Control of I/O characteristics

- Cross-talk protection with other cables

- Generation of signal for Blocking of Telegram switching (optional)

### **4.1.5 Management of Faults and Failures**

If the On-board Transmission Equipment is not able to detect Balises, it shall report this to the ERTMS/ETCS Kernel.

If there is a failure in Interface ‘C’, that makes transmission of the telegram from this interface impossible, the Balise shall send the Default Telegram which shall be transmitted to the On-board Transmission Equipment and handled as any other telegram.

<!-- end of page 25 -->

## **4.2 Functional Requirements**

### **4.2.1 Balise Tele-powering**

The On-board Transmission Equipment shall provide a Tele-powering signal used for activating Up-link Balises. The vehicle mounted Antenna Unit shall transmit this signal to the Balise via Interface ‘A’.

The On-board Transmission Equipment shall provide the desired Tele-powering Mode (CW, or the optional toggling modulation used for achieving interoperability with existing KER systems) on command from the ERTMS/ETCS Kernel.

The On-board Transmission Equipment shall be able to switch the Tele-powering signal on/off on command from the ERTMS/ETCS Kernel.

### **4.2.2 Up-link Data Transmission**

### 4.2.2.1 Information Flow

The Eurobalise Transmission System shall be capable of receiving information from the Wayside Signalling Equipment, and passing this information to the ERTMS/ETCS Kernel.

A Balise that is connected to an LEU shall transmit the received data transparently to Interface ‘A’.  Fixed, standalone Balises transmit fixed pre-programmed data during a train passage.

The BTM function shall make all the received data available to the ERTMS/ETCS Kernel, associated to the location information of the Balise passed over.

This shall be performed regardless of the direction of travel of the vehicle.

Under application conditions where a Balise Group consists of a number of Balises holding distributed data, the BTM function shall make available to the ERTMS/ETCS Kernel the data received in such a way that the order, in which data was received, can be reconstructed.

Information shall be correlated in such a way that the ERTMS/ETCS Kernel can identify that certain information is transmitted from a certain Balise, by associating the Balise data to the corresponding Balise location information.

### 4.2.2.2 Filtering of Telegrams

Under circumstances where telegrams are switched while they are received by the On-board Transmission Equipment, then the BTM function should normally make the latest received telegram available to the ERTMS/ETCS Kernel once (the details for the criteria of the “latest received telegram” are depending on each manufacturer’s specifications, but it shall be a safely received telegram with high quality during the transmission).  In some cases, the telegram can be made available more than once, e.g., when passing over the Balise at low speed (see sub-clause 6.2.2.5 on page 115).

The information received from Balises should be filtered and analysed by the BTM function.

The BTM function is allowed to filter out incoming data, provided that a fully validated telegram is already received and decoded, and that the testability and delay requirements are fulfilled (see sub-clause 4.2.9 on page 33).

<!-- end of page 26 -->

### 4.2.2.3 Blocking of Telegram Switching

In order to improve the availability, an optional function of blocking the telegram switching is possible.  This function requires that upon activation of transmission from track to train, the Balise shall signal to the LEU at the beginning of its start-up that it is being activated.  If implemented, the LEU shall block telegram switching for a minimum time of 10 ms.  The maximum blocking time is dependent on system requirements.

### 4.2.2.4 Protection of Data

Data transmitted from track to train is considered safety critical.  Protection of the data against air-gap noise effects and noise induced hazards in the receiving and transmitting equipment<sup>1</sup> shall be sufficient in order to ensure bit error detection to the extent that is specified by the coding requirements.

### 4.2.2.5 Air-gap Data Transmission, Protocols and Procedures

Data transmission shall be performed without handshaking in Interface ‘A’.

It is allowed to transmit sporadic bit sequences for diagnostic purposes in accordance with sub-clause 5.2.2.8.5 on page 66.

### **4.2.3 Intentionally Deleted**

### **4.2.4 Location Reference**

### 4.2.4.1 Balise Centre Detection

The BTM function shall provide data that enables evaluation of the instant and/or location when the Antenna Unit reference mark crosses over the Balise reference mark, by analysing either the properties of the received Up-link signal, or data, or both.

### 4.2.4.2 Time and Odometer stamping of the detected Balise Centre

The Eurobalise Transmission System shall provide data that enables evaluation of the location reference point for the Balise<sup>2</sup> , in time or position, depending on the quality of the time and odometer information that is available during each Balise passage. The information shall be made available to the ERTMS/ETCS Kernel.  The instant in time or position on which the location reference is based shall originate from the ERTMS/ETCS Kernel.

### 4.2.4.3 Train Direction Detection

Information about Balise sequences shall be passed on to the ERTMS/ETCS Kernel.  The Eurobalise Transmission System shall provide information that enables the ERTMS/ETCS Kernel to evaluate the direction of the train on the basis of the reported sequence of passed Balises.

> 1 Noise induced hazards are for example random disturbances leading to faults in the functions of the receiver.

> 2 The location reference point for the Balise corresponds to the Balise reference mark.

<!-- end of page 27 -->

### **4.2.5 Cross-talk Protection**

### 4.2.5.1 Intrinsic Cross-talk Protection

The Eurobalise Transmission System shall not allow a valid telegram to be passed through, from a Balise located in a cross-talk protected zone, to the On-board ERTMS/ETCS Kernel, as defined in this specification.

The Eurobalise Transmission System shall ensure protection against cross-talk based on signal levels when all constraints regarding the installation requirements are considered.  Additional cross-talk protection<sup>3</sup> is achieved by performing the ERTMS/ETCS level functions defined in SUBSET-026.

The intrinsic cross-talk protection for the Eurobalise Transmission System is based on:

- The fulfilment of the Balise field conformity requirements (see sub-clause 5.2.2.5 on page 59).

- The fulfilment of the Balise input-to output characteristic (see sub-clause 5.2.2.6 on page 63).

- The installation requirements for Balises in proximity of extraneous cables or metallic masses (see sub-clauses 5.7.10.7 on page 105 and 5.7.10.4 on page 99).

- The electrical and company specific installation requirements for Balise controlling interface cables.

- The minimum value of the field strength threshold of the BTM function receiver, Vth, which is sufficiently high to correctly handle possible up-link signal received from an activated Balise in the crosstalk protected zone (see sub-clauses 6.2.2.1 on page 114 and 4.2.5.2.2 on page 30).

- The Tele-powering field generated by the On-board Antenna Unit, or generated by a second On-board Antenna Unit (possibly present in its vicinity on the same train), in the worst case Tele-powering field condition, reaching a Balise in a cross-talk protected zone, which is low enough not to activate it to a level that the Up-link signal is correctly received by the first Antenna Unit (see sub-clause 4.2.5.2.1 on page 30).

The worst case for the Balise input-to-output characteristic and field conformity shall be considered, see Figure 16 of sub-clause 5.2.2.6 on page 63, Figure 14 on page 60, and Figure 15 on page 61.  The worst case situation for the On-board Transmission Equipment and for air-gap propagation shall be considered.  However, in the case of two Antenna Units, only the Up-link protects from cross-talk.

Definition of the cross-talk protected zone (directions as per the reference axes according to sub-clause 4.5 on page 50) is according to the distances of Table 1 below.

> 3  The Balises are in general configured in (linked or unlinked) Balise Groups with more than one Balise, or as single Balises with information linked to other Balises or sources of data.  Verification of the group configuration data and of the linking information, performed by the ERTMS/ETCS system level functions, constitutes an additional protection against cross-talk.

<!-- end of page 28 -->

|**Type of cross-talk**|**Involved equipment**|**Zone where cross-talk shall not occur**|
|---|---|---|
|Lateral<br>(direction Y)|One Balise and one Antenna Unit.|1.4 m or more between the Balise and the<br>Antenna Unit (related to the Z reference<br>marks).|
|Lateral<br>(direction Y)|One or two Balises and two Anten-<br>na Units.|3.0 m or more between the cross-talk Balise<br>and the interfered Antenna Unit (related to the<br>Z reference marks).|
|Vertical<br>(direction Z)|One Balise and one Antenna Unit.|4.8 m, or more, related to the X and Y refer-<br>ence marks.|
|Longitudinal<br>(direction X)|Two Balises and one Antenna Unit.<br>2.6 m or more between two consec-<br>utive Standard Size Balises, and<br>2.3 m or more between two Re-<br>duced Size Balises (related to the Y<br>reference marks).  2.6 m applies if<br>combinations of Balise sizes are<br>applicable.|Any location of the Antenna Unit along the<br>same track as the Balises.<sup>4</sup>|
|Longitudinal<br>(direction X)|One Balise and two Antenna Units.<br>4.0 m or more between two Antenna<br>Units.|Any location of the Antenna Units along the<br>same track as the Balise.<sup>5</sup>|

#### **Table 1:  Definition of Cross-talk Protected Zone**

Longitudinal cross-talk is mainly related to reliability cross-talk.  It is a safety-related aspect that the On-board constituent is enabled to correctly determine the order (e.g., sequence in time and/or position) of the passed Balises, and that erroneous positioning (see sub-clause 4.2.10.2 on page 35) shall not occur.

The configurations (including the number of units) of Table 1 are considered being worst cases from a cross-talk standpoint.

> 4 In general, it is assumed that the attention is focused to the near vicinity of the Balises in question.  Therefore, it is assumed that the Antenna Unit is positioned anywhere within the zone limited by 1.3 m before the first Balise and 1.3 m after the second Balise (related to the Z reference marks of the Balises). From a reliability cross-talk standpoint, the On-board Balise Equipment shall not report the telegram of a Balise more than 1.3 m away from it’s Y reference marks (in X direction).  See SUBSET-026.

> 5 In general, it is assumed that the attention is focused to the near vicinity of the Balise in question.  Therefore, it is assumed that the Balise is positioned anywhere within the zone limited by 1.3 m before the first Antenna Unit and 1.3 m after the second Antenna Unit (related to the Z reference marks of the Antenna Units).

<!-- end of page 29 -->

Other cross-talk related conditions:

|**Object**|**Requirement**|
|---|---|
|Cables in the track.|Cables shall be outside the protected area according to Figure 29 and<br>Figure 30 of sub-clause 5.7.10.1 on page 95 (except for approved loop<br>cables according to Figure 39 of sub-clause 5.7.10.7.1 on page 105).  The<br>installation of Balises in the proximity of cables, or the installation of<br>cables in the proximity of Balises shall fulfil the requirements stated in<br>sub-clause 5.7.10.7 on page 105.|
|Metallic reflectors on the vehicle.|Metallic objects shall be outside the metal free area of the Antenna Unit,<br>as specified by the manufacturer.|
|Metallic reflectors in the track.|Metallic objects on the ground shall be outside the protected area for the<br>Balise according to Figure 29 and Figure 30 of sub-clause 5.7.10.1 on<br>page 95.|
|Guard Rails|See sub-clause 5.7.10.4 on page 99.|

**Table 2:  Other Cross-talk conditions**

### 4.2.5.2 Up-link Data Communication

#### **4.2.5.2.1 One Balise, one Antenna Unit**

The total attenuation from the Antenna Unit Tele-powering to the received signal level of the Up-link signal shall under the worst case condition (i.e., highest possible efficiency according to Figure 16 of sub-clause 5.2.2.6 on page 63, and in presence of nearby cables, guard rails, and debris) be more than the ratio between the maximum Tele-powering signal level in the Antenna Unit and the minimum value of the Up-link receiver threshold field strength Vth.

#### **4.2.5.2.2 One Balise, two Antenna Units**

A cross-talking Balise may be powered by another vehicle.  The received signal level from the Balise shall under the worst case condition (i.e., highest possible output current Iu3  according to Figure 16 of sub-clause 5.2.2.6 on page 63, and in presence of nearby cables, guard rails, and debris) be less than the minimum value of the field strength threshold of the BTM function receiver Vth.

### 4.2.5.3 Intentionally Deleted

<!-- end of page 30 -->

### **4.2.6 Compatibility with existing systems**

### 4.2.6.1 General

The requirement on compatibility has to be regarded in a general sense, mostly applicable to the adopted transmission technology.  This requirement will have to be considered on the basis of the concerned Railway system specification, and on the applicable Eurobalise test procedures.  The requirement of compatibility is explicitly intended for the earlier generation of Balises using the Magnetic Transponder Technology, and the same air-gap signal frequencies as the Eurobalise system.  As for the compatibility with other systems working at different frequencies, the issue of compatibility will have to be considered case by case considering the overall Railway system.

### 4.2.6.2 Up-link Data Communication

The Eurobalise Transmission System shall be compatible with any existing railway systems, see examples in clause D3 of Annex D on page 144.  Relevant conditions shall be defined case by case.

### 4.2.6.3 Intentionally Deleted

### **4.2.7 Interoperability with existing KER Systems**

The On-board Transmission Equipment should optionally be able to read the data coming from the KVB, Ebicab, and RSDD Balises.  This requires that the On-board Transmission Equipment is transmitting a 27 MHz toggling 50 kHz modulated Tele-powering signal.  The BTM function shall be informed by the ERTMS/ETCS Kernel at start-up, and whenever there is a change of operating conditions, whether it shall transmit a 27 MHz CW signal or a 27 MHz signal modulated by a toggling 50 kHz Tele-powering signal.  .

The Eurobalise responds equally when being activated by either a 27 MHz CW signal, or a 27 MHz signal with a toggling 50 kHz modulation (see sub-clause 5.2.2.9 on page 67).

The On-board Transmission Equipment should transmit 27 MHz CW at train speeds above 350 km/h.<sup>6</sup>

> 6  The reason for transmitting only 27 MHz CW at train speeds above 350 km/h is that the start-up time for the Balise is less when it receives CW compared to the toggling Tele-powering signal.  Additionally, the KER systems are not specified for speeds above 350 km/h, which means that there is no use for the toggling signal at these high speeds.  The conclusion is that the CW signal is recommended at these high speeds.

<!-- end of page 31 -->

### **4.2.8 Quality of the Data Transmission Channel**

### 4.2.8.1 Data Capacity

The following telegrams shall be possible at a maximum vehicle speed of 500 km/h:

- 1) 341 bit telegram.

- 2) 1023 bit telegram.

Mixing of Balises, and transmitting different telegram lengths, shall be possible on the same line.  Please observe the constraints of sub-clause 5.2.2.3 on page 57.

The Balise shall be able to receive data from an LEU at a distance of at least 500 m (see sub-clause 5.3.1 on page 68).  Sub-clause 5.3 on page 68 specifies the needed requirements for achieving interchangeability for distances of up to 500 m.  Longer distances than 500 m (for example 5 km) can be achieved by the individual supplier.

### 4.2.8.2 Transmission Bit Errors

The BER (Bit Error Rate) in the central area of the contact length of each Balise should be less than 10<sup>-6</sup> .<sup>7</sup> Bit errors in the railway environment could occur as burst errors, random bit errors, and bit slip/insertion.  The BER shall be such that the Eurobalise Transmission System fulfils the RAMS requirements. The requirement is an overall requirement for a complete system.

The BTM function shall detect (and possibly correct, to a limited extent) bit errors in Up-link transmission.

### 4.2.8.3 Code Protection

Data and telegram structures shall be protected against possible noise effects in the air-gap, and against noise induced hazards in the receiving and transmitting equipment by suitable telegram coding algorithms as described by the coding requirements (see sub-clause 4.3 on page 36).

The same coding algorithms shall protect data and telegram structures against noise and failures during transmission via the serial link connecting the LEU with the Balise (there is no bit error detection in the Balise).

Data and telegram structures shall be protected against noise or failures in the communication between the BTM functions and the ERTMS/ETCS Kernel by different coding algorithms.

> 7 The hint on BER target may be individually verified on a voluntary basis, and is not a firm requirement.  Moreover, it can not be verified in any harmonised interface.  This property only partly addresses aspects related to the overall system requirements of section 4.4.4.

<!-- end of page 32 -->

### **4.2.9 Timing and Distance Requirements**

The maximum time delay between a bit on Interface ‘C1’ at the Balise end of the interface and the corresponding bit on Interface ‘A1’ shall be 10  s.

The time delay between the end of transmission of the current Balise (that is 1.3 m after the centre point of the current Balise) in a cluster of Balises, and the availability of data for the ERTMS/ETCS Kernel (location reference information and the data from this current Balise) shall be less than Tn.  The requirement is in general applicable in terms of constraints on distances between Balise Groups.

<!-- Start of picture text -->
T4<br>T3<br>T2<br>T1<br>100 ms 100 ms 100 ms 100 ms<br> t   t   t <br>t1 t2 t3<br>1.3 m 1.3 m 1.3 m 1.3 m<br>Balises<br><!-- End of picture text -->

**Figure 2:  Example of a passage of a cluster of four Balises**

   - Tn = 100 +  t n − 1 ms, where  t 0 = 0 and t 0 = 0

   - 0        if  t n − 1  100 +  t n − 2 ms

   - t n − 1 =  100 +  t n-2 − t n − 1   ms   otherwise

- Tn = Maximum delay from 1.3 m after the centre of the Balise until the Up-link data is available at the ERTMS/ETCS Kernel.

- n = The number of the Balise in the cluster, n  1 _through_ 8  . When  _tn_ − 1 = 0, then n → 1, i.e., then n corresponds to the first Balise in the next cluster.

- t n = The time that the data is FIFO queued.

- t n =  The elapsed time when the train moves from 1.3 m after the centre of Balise n to 1.3 m after the centre of Balise n+1.

<!-- end of page 33 -->

The distance between two clusters of Balises shall be at least d c .

d c = TN • v line [m]

- d c = The distance between two clusters of Balises, i.e., from 1.3 m after the last Balise in the first cluster to 1.3 m before the first Balise in the second cluster.

- v line = The Maximum Permitted Speed in m/ms.

At low speeds of the train, an estimated location reference (with lower confidence than the location reference information delivered after the Balise passage) should be given in relation with the Up-link data after the maximum time delay (a time-out) defined in sub-clause 6.2.2.5 on page 115.  See also sub-clause 4.2.10 on page 35.

<!-- end of page 34 -->

### **4.2.10 Location Reference Accuracy**

### 4.2.10.1 General

The Eurobalise Transmission System shall evaluate the location for the Balise, using the available time and odometer information, and make this information available to the ERTMS/ETCS Kernel.  This delivered information includes the error in the time and odometer information, which is not considered in the following.

### 4.2.10.2 Accuracy for vital purposes

The location accuracy shall be within  1 m for each Balise, when a Balise has been passed.

When applicable, the location accuracy in the preliminary location reference, delivered after the reporting period defined in sub-clause 6.2.2.5 on page 115 during the Balise passage, shall be within  1 m.<sup>8</sup>

### 4.2.10.3 Accuracy for non-vital purposes

The location accuracy shall fulfil the following Figure 3 with a confidence interval of 0.998 after the Balise passage.

Figure 3 below specifies the error |Lerr _|_ as function of the speed.  |Lerr _|_ is the maximum error in measured Balise position relative to the physical centre of the Balise.  The error in the external odometer references is not included.<sup>9</sup>

<!-- Start of picture text -->
|Lerr| (m)<br>0.70<br>0.20<br>Speed (km/h)<br>40  500<br><!-- End of picture text -->

**Figure 3:  Error in position of the Balise centre relative to the odometer value**

The figure above may be expressed as<sup>10</sup> :

> 8 Each manufacturer shall specify the needed performance related to the received odometer and time information to meet this requirement.

> 9 Preferably, the vertical component of the Up-link magnetic field is used for this purpose.  Therefore particular demands on conformity and stability apply for this signal both in static and dynamic conditions.

> 10 Each manufacturer shall specify the needed performance related to the received odometer and time information to meet this requirement.

<!-- end of page 35 -->

## **4.3 Coding Requirements**

### **4.3.1 Introduction**

### 4.3.1.1 Overview

The key features of the telegram format are the following:

- Two compatible telegram lengths, 1023 and 341 respectively.

- A large number of unrestricted information bits, 830 and 210, respectively (some of these bits will be reserved for higher levels of the telegram transmission system such as the separation of Up-link and Down-link telegrams.)

- Provable safety against various types of transmission errors.

- Inversion of all bits of the telegram is always recognised by the decoder.

- The transmission needs not start (or end) at the beginning of a telegram.  The detection procedure is completely transparent with respect to cyclic shifts of a telegram.

- Support for compatibility with unknown future format variations.

The telegram format allows for quantitative evaluation of the effect of random bit errors, burst errors, bit slips and bit insertions, and all combinations thereof, with particular attention to the potential problems of telegram change and format misinterpretation (long as short and vice versa).

Note that any safety related evaluation is valid only with respect to some specific receiver.  Receivers other than that of sub-clause 4.3.4.1 on page 41 may be used, provided that a complete safety related evaluation can be given.

### 4.3.1.2 Telegram Format

The telegram format is described with respect to Figure 4.  There are two versions, a long format of length, nL = 1023 (= 93·11), and a short format of length nS = 341 (= 31·11).  The bits of the telegram are denoted bn-1, bn-2, ..., b1, b0 (with n = nL = 1023 or n = nS = 341).  The numbering with descending indices (from left to right) is chosen such that “left” and “right” conform with Figure 4.  The order of transmission is from left to right (but need not begin with the leftmost bit bn-1).

|Shaped Data|cb|sb|esb|Check bits|
|---|---|---|---|---|
|8311=913 or 2111=231 bits|3 bits|12 bits|10 bits|85 bits|

**Figure 4:  The telegram format**

The telegram begins with a block of “shaped data”, which contains the user data “scrambled” and “shaped” as described in sub-clauses 4.3.2.2 on page 37 and 4.3.2.3 on page 38.  In the long format, this block consists of 913 bits (83 11-bit words), i.e., the bits b1022...b110.  In the short format, the block consists of 231 bits (21 words), i.e., b340...b110 (from now on and unless stated otherwise, a “word” consists of 11 bits).  Each word contains 10 user bits.  A long telegram thus contains 830 user bits and a short telegram contains 210 user bits.

<!-- end of page 36 -->

The three bits b109...b107 are “control bits” (cb).  The first control bit, b109, is the “inversion bit” _,_ which shall be set to zero.  The other two control bits, b108 and b107, are not currently used and are intended for future format variations.  For the present format, these spare bits shall be set to b108=0 and b107=1.  The next 12 bits, b106...b95, are “scrambling bits” (sb).  They store the initial state of a scrambler that operates on the data bits before shaping, see sub-clause 4.3.2.2 on page 37.  The following 10 bits, b94...b85, are “extra shaping bits” (esb).  They are used to enforce the shaping constraints on the check bits independent of the scrambling.  They are disregarded by the receiver (except that the shaping constraints are checked).  The last 85 bits, b84...b0, are “check bits”, and comprise 75 parity bits of the error detecting code and 10 bits for synchronisation.

### **4.3.2 Encoding Requirements**

### 4.3.2.1 General

The following notation is used.  With any binary n-tuple v = [vn-1, vn-2, ..., v1, v0], we associate the binary polynomial v(x):= vn-1x<sup>n-1</sup> + vn-2x<sup>n-2</sup> + ... + v1x + v0 (in more mathematical terms, a “bit” is an element of the finite field GF(2), and a “binary polynomial” is an element of the ring GF(2)[2]).  For any two binary polynomials c(x) and d(x), Rc(x)[d(x)] denotes the remainder of the division of d(x) by c(x).  That is, the unique polynomial r(x) of degree less than the degree of c(x) such that d(x)=q(x)c(x)+r(x), for some polynomial q(x) (all additions are to be performed mod 2).

### 4.3.2.2 Scrambling

Scrambling shall be done in a way to get the same result as from the following steps:

1. Replacement of the first ten user bits by a function of all user bits.

2. Computation of a 32-bit integer S from the 12 scrambling bits.

3. The actual scrambling, using a 32-bit linear feedback shift register with initial state S.

The purpose of step 1 (and of the specific formulation of step 3) is to make sure that changing a single user bit gives a completely different scrambled sequence.

- **Step 1** : Let m=830 for the long format and m=210 for the short format.  Let u m-1 , u m-2 , ..., u 0 be the user bits. The user bits are partitioned, from left to right, into k 10-bit blocks, U k-1 =(u m-1 ... u m-10 ), U k-2 =(u m-11 ... u m-20 ), ..., U 0 =(u 9 ...u 0 ), with k=83 for the long format and k=21 for the short format.  A new sequence U’ k-1 , U’ k-2 , ..., U’ 0 of 10-bit words is formed that differs only in the first word: U’ i =U i for i=0...k-2 and

where all 10-bit blocks are interpreted as integers with most significant bit (MSB) to the left.  The sequence U’ k-1 , ..., U’ 0 is converted back to a bit stream u’ m-1 , ..., u’ 0 , which agrees with u m-1 , ..., u 0 except for the first ten bits u’ m-1 , ..., u’ m-10 .

- **Step 2** : The 12 scrambling bits (sb) b 106 ...b 95 are considered as an integer, with most significant bit (MSB) b 106 and least significant bit (LSB) b 95 , B = b 106 ·2<sup>11</sup> +...+b 96 ·2+b 95 .  The 32-bit integer S is defined as

Note that 2801775573 = 69069<sup>3</sup> mod 2<sup>32</sup> ; the latter number is a common choice for this type of random number generator.

<!-- end of page 37 -->

- **Step 3:** Use the shift register circuit of Figure 5, where the squares are delay cells, and the plus signs denote the exclusive-OR operation.  The coefficients h 31 , h 30 , h 29 , h 27 , h 25 , and h 0 are equal to 1 (connected through).  All other coefficients are 0 (no connection).  The total number of delay cells is 32.  The binary representation of S is loaded as initial state in the shift register of Figure 5 (with MSB to the left). Then the circuit is clocked m-1 times, with input u’ m-1 , ..., u’ 0 , to generate the scrambled bits s m-1 , s m- 2 , ..., s 0 (the first output, s m-1 , is read before the first clock).

   - In polynomial notation, the circuit of Figure 5 performs, at each clock, the operation  (x)  Rh(x)[x·  (x) + u i x<sup>32</sup> ], where  (x) = 31 x<sup>31</sup> + ... + 1 x + 0 is the contents of the shift register (with 0 to the right), where h(x) = x<sup>32</sup> + x<sup>31</sup> + x<sup>30</sup> + x<sup>29</sup> + x<sup>27</sup> + x<sup>25</sup> + 1, and where u i is the current input (i=m1...0).

<!-- Start of picture text -->
u´m-1, u´m-2, ... , u´0<br>h31 h2 h1 h0<br>sm-1, sm-2, ... , s0<br><!-- End of picture text -->

**Figure 5:  Scrambling**

### 4.3.2.3 The 10-to-11-Bit Transformation

The scrambled bits are partitioned into blocks of 10 bits each, in the direction of descending indices (the first block thus consists of the bits s m-1 , s m-2 , ..., s m-10 , with m as above).  There are 83 such blocks in the long format and 21 in the short format.  Each such block shall be transformed into an 11-bit word by a substitution table. The 1024 substitution values (11-bit words) are listed in clause B2 of Annex B on page 139 (in the order of increasing magnitude).  The substitution rule is that the block, considered as an integer i (between 0 and 1023, with MSB to the left), is transformed into the i-th word in the list (where the words are numbered beginning with 0).  The substitution word for i+1 is thus always larger (as an integer) than the substitution word for i.

The words are listed in clause B2 of Annex B on page 139.

<!-- end of page 38 -->

### 4.3.2.4 Computing the Check Bits

After the scrambling and the transformation of sub-clauses 4.3.2.2 on page 37 and 4.3.2.3 on page 38, and by some choice of the “extra shaping bits” (esb) b 94 ...b 85 , the bits b n-1 ...b 85 of the candidate telegram are fixed.  It remains to compute the check bits b 84 ...b 0 .  In polynomial notation (as introduced at the beginning of sub-clause 4.3.2.1 on page 37), the check bits shall be defined as follows:

where the polynomials f(x), g(x), and o(x) depend on the format.  For the long format, the following equations should be used:  f(x)= f L (x), g(x)=g L (x), and o(x) = g L (x):

- gL(x) =  x<sup>75</sup> + x<sup>73</sup> + x<sup>72</sup> + x<sup>71</sup> + x<sup>67</sup> + x<sup>62</sup> + x<sup>61</sup> + x<sup>60</sup> + x<sup>57</sup> + x<sup>56</sup> + x<sup>55</sup> + x<sup>52</sup> + x<sup>51</sup> + x<sup>49</sup> + x<sup>46</sup> + x<sup>45</sup> + x<sup>44</sup> + x<sup>43</sup> + x<sup>41</sup> + x<sup>37</sup> + x<sup>35</sup> + x<sup>34</sup> + x<sup>33</sup> + x<sup>31</sup> + x<sup>30</sup> + x<sup>28</sup> + x<sup>26</sup> + x<sup>24</sup> + x<sup>21</sup> + x<sup>17</sup> + x<sup>16</sup> + x<sup>15</sup> + x<sup>13</sup> + x<sup>12</sup> + x<sup>11</sup> + x<sup>9</sup> + x<sup>4</sup> + x + 1.

For the short format, the following equations should be used:  f(x)= f S (x), g(x)=g S (x), and o(x) = g S (x):

- fS(x) = x<sup>10</sup> + x<sup>8</sup> + x<sup>7</sup> + x<sup>5</sup> + x<sup>3</sup> + x + 1

- gS(x) = x<sup>75</sup> + x<sup>72</sup> + x<sup>71</sup> + x<sup>70</sup> + x<sup>69</sup> + x<sup>68</sup> + x<sup>66</sup> + x<sup>65</sup> + x<sup>64</sup> + x<sup>63</sup> + x<sup>60</sup> + x<sup>55</sup> + x<sup>54</sup> + x<sup>49</sup> + x<sup>47</sup> + x<sup>46</sup> + x<sup>45</sup> + x<sup>44</sup> + x<sup>43</sup> + x<sup>42</sup> + x<sup>41</sup> + x<sup>39</sup> + x<sup>38</sup> + x<sup>37</sup> + x<sup>36</sup> + x<sup>34</sup> + x<sup>33</sup> + x<sup>32</sup> + x<sup>31</sup> + x<sup>30</sup> + x<sup>27</sup> + x<sup>25</sup> + x<sup>22</sup> + x<sup>19</sup> + x<sup>17</sup> + x<sup>13</sup> + x<sup>12</sup> + x<sup>11</sup> + x<sup>10</sup> + x<sup>6</sup> + x<sup>3</sup> + x + 1.

The polynomials gL(x) and gS(x) satisfy

which implies that the tree-fold repetition of a short telegram satisfies the parity check of the long format.

### 4.3.2.5 Testing Candidate Telegrams

#### **4.3.2.5.1 General**

Every telegram shall satisfy all conditions below.  As described in sub-clause 4.3.2.3 on page 38, a candidate telegram that does not satisfy all these conditions shall be rejected; a new candidate may then be obtained by either changing the extra shaping bits (which affects only the check bits), or by changing the scrambling bits (which affects the whole telegram).

All the conditions below shall also hold “wrap-around”, i.e., for cyclically repeated telegrams.  All indices are tacitly assumed to be reduced modulo n (=1023 or 341 for the long and the short format, respectively).

Recall that an 11-bit word is called “valid” if it is one of the 1024 substitution values of sub-clause 4.3.2.3 on page 38.

<!-- end of page 39 -->

#### **4.3.2.5.2 Alphabet Condition**

Any 11-bit word b i-1 ...b i-11 such that i is a multiple of 11 shall be valid.

Clearly, this condition is automatically satisfied in the shaped-data part of the telegram.  However, the alphabet condition applies to all parts of the telegram.

#### **4.3.2.5.3 Off-Synch-Parsing Condition**

This condition tests sequences of 11-bit words: (b i-1 ...b i-11 ), (b i-12 ...b i-22 ), (b i-23 ...b i-33 ), ... with i _not_ a multiple of 11.  It imposes a limit on the number of consecutive valid words within such sequences.

If i+1 or i-1 is a multiple of 11, the length of the longest run of consecutive valid words shall not exceed 2 (two). Otherwise, if it is not a multiple of 11, the length of the longest run of consecutive valid words shall not exceed 10 (ten) for long telegrams and 6 (six) for short telegrams.

None of these conditions is automatically satisfied in any part of the telegram.  However, the substitution table “helps” in the case where i+1 or i-1 is a multiple of 11, see sub-clause 4.3.2.3 on page 38.

#### **4.3.2.5.4 Aperiodicity Condition for Long Format**

This condition applies only to the long format.  It ensures that no part of a long telegram may be mistaken as a short telegram, even in the presence of noise and bit slips, by testing the Hamming distance between two sequences of 11-bit words that are separated by about 341 bits.

For every i that is a multiple of 11:

- the Hamming distance between b i-1 ...b i-22 and b i-341-1 ...b i-341-22 shall be at least 3;

- for each k = +1, -1, +2, -2, +3 and -3, the Hamming distance between b i-1 ...b i-22 and b i-341-k-1 ...b i-341-k-22 shall be at least 2.

#### **4.3.2.5.5 Under-sampling Condition**

Under-sampling by 2, i.e., permuting a telegram into b n-2 , b n-4 , ..., b 1 , b n-1 , b n-3 , ..., b 2 , b 0 , results in another code word in the cyclic code and is thus not detectable by checking the parity bits.  Since it is plausible that such a transformation can be caused by a hardware defect, each telegram is tested to make sure that such a transformed code word violates the Alphabet Condition.

Let v j =b j2k , j=0...n-1 (under-sampling by a factor of 2<sup>k</sup> ).  For k=1, 2, 3, 4 and for any i, the length of the longest run of valid words in the sequence (v i-1 ...v i-11 ), (v i-12 ...v i-22 ), (v i-23 ...v i-33 ) shall not exceed 30.

In other words, no under-sampled short telegram and no length-341 segment of an under-sampled long telegram may satisfy the Alphabet Condition with arbitrary word boundaries.

### **4.3.3 Telegram Switching**

Usually, a telegram is repeated “forever”, i.e., for the whole duration of a train passage: bn-1, ..., b0, bn-1, bn-2, ...  If the transmitter switches to a new telegram, a string of all zeros or a string all ones shall be inserted between the last transmitted bit of the old telegram and the first transmitted bit of the new telegram (the “last" and “first" transmitted bit can be any bit in the telegram and need not be b0 and bn-1, respectively).

The length of this inserted string shall be between 75 and 128 bits.

<!-- end of page 40 -->

### **4.3.4 Decoding Requirements**

### 4.3.4.1 Basic Receiver Operation

The receiver comes in two (very similar) versions, one for the long format (with n=1023) and one for the short format (n=341).

Any used receiver shall be at least as good as the following one:

1. Consider a window of n+r consecutive received bits (long format: r=77; short format: r=121.  If the window has already been shifted over 7500 bits, set r=n).

2. Is the parity-check satisfied, i.e., are the first n bits (considered as a polynomial) divisible by g(x) ?  If not, shift window and go to 1.

3. Do the r extra bits (rightmost in window) coincide with the first r bits (leftmost in window) ?  If not, shift window and go to 1.

4. Find the beginning (position of b n-1 ) of the telegram with the help of f(x).  See sub-clause A1.2.1 of Annex A on page 134, (if R f(x) [v(x)] is an “impossible” value, go to 1).

5. Are all 11-bit words (b n-1 ...b n-11 ), (b n-12 ...b n-22 ), ..., (b 10 ...b 0 ) valid ?  If not, shift window and go to 1.

6. At this point, the telegram is considered safe.

7. Is the inversion bit b 109 =1 ?  If yes, see sub-clause 4.3.4.2 below.

8. Check the other two control bits. If b 108 =1 or b 107 =0, abort with the message “unknown telegram format”.

9. Invert the 10-to-11-bit transformation.

10. De-scramble.

11. Output the user bits and the original state of the inversion bit (b 109 ).

See also additional information in sub-clause A1.2.2 of Annex A on page 135.

### 4.3.4.2 Check of the Control Bits

Every receiver shall check the “control bits” (cb).  If the inversion bit b 109 is found to be 1, all the received bits could be used after inversion, or could be rejected by the BTM function.

In both cases a message “inversion bit set“ shall be sent to the ERTMS/ETCS Kernel.

The other two “control bits” b 108 and b 107 shall be checked (after the telegram is decoded and considered valid). If they are not found to be 0 and 1 respectively, the receiver shall announce the message “unknown telegram format”.

### 4.3.4.3 Check of the Under-sampling Condition

The receiver shall not check the Under-sampling Condition of sub-clause 4.3.2.5.5 on page 40 (the reason is that future format variations designed, e.g., for real-time encodability may not be able to enforce that condition).

<!-- end of page 41 -->

### 4.3.4.4 Check of the Extra bits

Note, that the basic receiver of sub-clause 4.3.4.1 requires a number of extra bits (beyond the length of the telegram) to be error-free.  The requirement is 77 bits for the long, and 121 bits for the short format.  Any safety related receiver shall at least consider this amount of extra bits.

## **4.4 RAMS Requirements**

### **4.4.1 General**

Within this sub-clause (4.4), the term “Transmission System” is used as a short form for “Balise Location and Transmission System”.

A RAMS Program (RAM Program and Safety Plan) shall address issues related to RAMS management, reliability, availability, maintainability, and safety, in accordance with the applicable definitions of EN 50126.

In general, the minimum operational lifetime should be 20 years.  In particular the minimum operational lifetime for the fixed data Balise should be 30 years.

### **4.4.2 Top level functionality**

Table 3 below defines the top-level functionality of the constituents of the Transmission System in terms of basic functions.  Related hazards are found in sub-clause 4.4.6.3 on page 46.

|**No.**|**Function Description**|**Related hazards**|
|---|---|---|
|F1|Balise Detection|H1, H2, H3|
|F2|Transmit protected data from wayside devices to the intended<br>train devices|H4, H5, H6, H9|
|F3|Provide data used for localisation of the train|H7|
|F4|Allow understanding of the travelling direction of the train|H8|

**Table 3:  List of basic functions**

### **4.4.3 Reliability**

The MTTF (Mean Time To Failure) for a given constituent of the Transmission System might fluctuate with the time.  The reliability targets concern the mean MTTF value over the operational lifetime.

The constituents of the Transmission System shall operate so as to ensure that reliability cross-talk from, and to, adjacent tracks does not adversely affect the overall reliability.  Reliability cross-talk is defined as the disturbing effect on the correct transmission of data, such that correct transmission is unattainable.

<!-- end of page 42 -->

### **4.4.4 Availability**

The Balise Detect function implicitly measures the air-gap noise levels, and effectively constitutes an EMC level supervision.  When the EMC level is above a level that ensures the required Balise transmission performance, then the On-board Transmission Equipment may perform Balise Detect.  Thus, this implicitly includes EMC supervision, and triggers a vital fallback function (i.e., the Balise Detect functionality).  The false alarm rate for the Balise Detect functionality is affecting the availability that must comply with the overall system level requirements.

The following specific availability targets should be fulfilled:

- A mean figure of 10<sup>6</sup> Balise passages with error free telegrams delivered by the On-board Transmission Equipment to the ERTMS/ETCS Kernel should be ensured.  This applies within the entire specified range of environmental conditions and train speeds.

- The On-board Transmission Equipment should not erroneously report to the ERTMS/ETCS Kernel that it has detected a Balise more often than 10<sup>-3</sup> times per hour.<sup>11</sup>

### **4.4.5 Intentionally Deleted**

### **4.4.6 Safety**

### 4.4.6.1 General

For the constituents of the Transmission System, a Safety Plan shall be agreed.  It shall be implemented, reviewed, and maintained throughout the lifecycle of the system.  The following issues shall be considered:

- Identification of the safety related functions for the system, and definition of the corresponding integrity levels.

- Applicable analysis methods.

- Identification and analysis of all possible hazards.

- Assessment of risks.

- Criteria for risk mitigation and tolerability.

- Safety verification, validation, and assessment.

All work pertaining to Safety shall comply with the standards:

- EN 50126

- EN 50128

- EN 50129

<!-- end of page 43 -->

### 4.4.6.2 Safety related functionality

#### **4.4.6.2.1 Introduction**

The functionality defined by Table 3 on page 42 is categorised safety related.

No single independent constituent failure shall result in a hazard rate exceeding the figures specified in subclauses 5.5.5.2 on page 81 and 6.4.5.2 on page 122.  Secondary or dependent failures that occur as a result of an initial failure shall also be considered in combination with that initial failure.

#### **4.4.6.2.2 Balise Detection**

The ability to detect Balises is considered safety-critical, and constitutes a fall-back functionality in case the transmitted telegram can not be read by the On-board Transmission Equipment.  The detection function is given as an indication to the ERTMS/ETCS Kernel.

Information about wayside failures shall be passed on to the ERTMS/ETCS Kernel.  This includes transmitting a Balise Detect without an accompanying valid telegram.

#### **4.4.6.2.3 Transmission of protected data**

Data and telegram structures shall be protected against possible noise effects in the air-gap and noise induced hazards in the receiving and transmitting equipment, by telegram coding algorithms, as defined in sub-clause 4.3 on page 36.

The same coding algorithms shall protect data, and telegram structures, against noise and failures during transmission in the Balise controlling interface connecting the LEU with the Balise (there is no bit error detection in the Balise).  However, the Balise shall switch to its Default Telegram if the data quality falls below an acceptable level within a maximum allowed time (the actual level is manufacturer dependent).

Data transmitted from track to train is considered safety-critical.  Protection of the data against air-gap noise effects and noise-induced hazards in the receiving and transmitting equipment<sup>12</sup> shall be sufficient in order to ensure bit error detection to the extent that is specified in sub-clause 4.3 on page 36.

The constituents of the Transmission System shall ensure protection against cross-talk based on signal levels when all constraints regarding the installation requirements are considered.  The cross-talk protection can additionally be based on the reception of at least two Balises that are logically linked to each other.  This protection, and the logical linking of these Balises, is performed on ERTMS/ETCS system level.

Information about wayside failures shall be passed on to the ERTMS/ETCS Kernel.  This includes transmitting a Default Telegram.

The constituents of the Transmission System shall operate so that the probability for systematic safety cross-talk from, and to, adjacent tracks is sufficiently low.<sup>13</sup> This shall be included in the proof of safety.  Safety crosstalk is defined as the acceptance of unwanted data, interpreted as valid, by an unintended On-board Transmission Equipment.

> 12 Noise induced hazards are for example random disturbances leading to faults in the functions of the receiver.

> 13 Additional protection is provided on ERTMS/ETCS system level through linking of Balise Groups (linking within Balise Groups with multiple Balises, and linking between Balise Groups).

<!-- end of page 44 -->

#### **4.4.6.2.4 Localisation**

The Onboard Transmission Equipment shall be able to provide information suitable for detecting and evaluating the location reference of the Balise, and make this information available to the ERTMS/ETCS Kernel.  The safety of this function is based on the passage of at least two Balises.

The localisation accuracy shall be as specified in sub-clause 4.2.10.2 on page 35, when a Balise has been passed.

#### **4.4.6.2.5 Travelling direction**

The constituents of the Transmission System shall allow evaluation of the travel direction at each Balise Group. It is not allowed to mix the order of the Balises due to longitudinal cross-talk.  The safety of this function is based on the passage at least two Balises that are linked to each other.

Information about Balise sequences shall be passed on to the ERTMS/ETCS Kernel.  It shall be correlated in such a way that the ERTMS/ETCS Kernel can identify that certain information is transmitted from a certain Balise.

The ERTMS/ETCS Kernel will determine the train’s travel direction, by the sequence of the reported Balises. The ERTMS/ETCS Kernel will be able to determine the train's direction of travel from received telegrams, from at least two linked consecutive Balises (e.g., two single Balises, or the Balises within a Balise Group with multiple Balises).

<!-- end of page 45 -->

### 4.4.6.3 Top-level Hazards

The top-level hazards are defined in Table 4, together with their possible sources of the hazards<sup>14</sup> and the related functionality of Table 3 in sub-clause 4.4.2 on page 42.  Non-considered exceptional conditions outside the specification are not explicitly mentioned herein.

|**No.**|**Hazard Description**|**Related**<br>**function**|**Origin of failure**|
|---|---|---|---|
|H1|A Balise is not detected|F1|Balise<br>Air-gap<br>On-board Transmission Equipment|
|H2|The On-board Transmission Equipment<br>erroneously reports that it has detected a<br>Balise|F1|Air-gap<br>On-board Transmission Equipment|
|H3|The On-board Transmission Equipment<br>erroneously reports detection of a Eurobal-<br>ise inpresence of a KER Balise|F1|Air-gap<br>On-board Transmission Equipment|
|H4|Transmission of an erroneous telegram<br>interpretable as correct|F2|Balise<br>On-board Transmission Equipment<br>LEU<br>Air-gap<br>Interface ‘C’<br>Programming|
|H5|Loss of the telegram, from a certain Balise,<br>intended for full performance|F2|Balise<br>On-board Transmission Equipment<br>LEU<br>Air-gap<br>Interface ‘C’<br>Programming|
|H6|No transmission of Default Telegram in<br>case of wayside failures|F2|Balise<br>LEU<br>Interface ‘C’<br>Programming<br>Air-gap<br>On-board Transmission Equipment|
|H7|Erroneous localisation of a Balise with<br>reception of valid telegram<sup>15</sup>|F3|Balise<br>Air-gap<br>On-board Transmission Equipment|
|H8|The order of reported Balises, with recep-<br>tion of valid telegram, is erroneous|F4|Balise<br>Air-gap<br>On-board Transmission Equipment|
|H9|Erroneous reporting of a Balise in a differ-<br>ent track, with reception of valid telegram|F2|Balise<br>Air-gap<br>On-board Transmission Equipment|

**Table 4:  List of top-level hazards**

> 14 “Balise” includes e.g., the related installation rules for cables etc.

> 15 Longitudinal cross-talk is an example of a wayside source for this.  On-board Transmission Equipment failure in position and/or time reference of a Balise passage is an example of an on-board source.

<!-- end of page 46 -->

The hazards H2, H3, H5, and H6 are not considered hazards from a system point of view, provided that the availability of the related functions is sufficient to support the apportionment to the different modes of the mission profile.  This means that no quantification will be provided in sub-clauses 5.5.5.2 on page 81 and 6.4.5.2 on page 122.  The hazards H2, H3, H5, and H6 are included herein for the purpose of completeness and linking between failures and consequences, and should be regarded informative as long as the availability is sufficient.

The hazards H7, H8, and H9 are caused by technical failures within the respective constituent.  Potential violation of installation rules is not considered in the quantification of the constituents (sub-clauses 5.5.5.2 and 6.4.5.2), but has to be considered by other means.

### 4.4.6.4 Principles for apportionment

Dependent on the safety objectives for the concerned items, a wrong side failure, a WSF, can originate from hardware and/or software failures, as well as all types of information errors.  A WSF can lead to an accident.

Safety integrity results from the combination of quantifiable elements (generally associated to hardware, e.g., protection against random failure during the operational life of the equipment), and non-quantifiable elements (generally associated to protection against systematic failures due to for instance incomplete specifications, residual design errors, and production processes).

The top-level hazards are defined and apportioned in accordance with Table 4 of sub-clause 4.4.6.3 on page 46. In general, there are several sources for each of the hazards as illustrated in Figure 6 below.

<!-- Start of picture text -->
HX<br>HXB HXAG HXOB HXother<br>Contribution Contribution Contribution Other<br>from the from the air- from the On- contribution not<br>Balise gap board currently<br>transmission considered<br>functionality within this<br>Norm<br><!-- End of picture text -->

**Figure 6:  Principles for apportionment**

The hazard denomination HX refers to any of those hazards defined sub-clause 4.4.6.3.  For some hazards, the general structure of Figure 6 is reduced because all sources are not applicable.  The related wayside and Onboard hazards (HXB and HXOB) are further detailed and quantified in sub-clauses 5.5.5 on page 78 and 6.4.5 on page 118 respectively.  The air-gap contribution (HXAG) is dealt with in sub-clause 4.4.6.5 on page 48.  The contribution HXother refers to sources regarded as external to this specification (e.g., LEU and programming). This is currently not within the scope of this specification, and must be considered by other means.

<!-- end of page 47 -->

Specifically, regarding H4 it includes the concept of a non-trusted channel in accordance with EN 50159.  The border of the non-trusted channel is company specific, and the following concepts apply:

- A. Each supplier has to define the borders between the non-trusted channel and the trusted part of the channel based on the definitions of all possible failures as defined in EN 50159.

- B. Provided that the On-board part is equal to or better than the Basic Receiver, and performs all the consistency checks on the received data that are required by the SRS (see SUBSET-026), then it can be assumed that the coding requirements, and the defined Basic Receiver (see sub-clause 4.3.4 on page 41), protects against all possible failures within the non-trusted channel (as defined by EN 50159).

- C. The non-trusted part of the channel will need a demonstration that a minimum Tolerable Hazard Rate is fulfilled (see SUBSET-091, ETCS_TR03/ETCS_OB06).

For a formal approval of the non-trusted channel, a safety demonstration is required to the level of 10<sup>-11</sup> failures/hour considering the mission profile defined in higher-level system documentation (see SUBSET-091).

The quantification of sub-clauses 5.5.5 on page 78 and 6.4.5 on page 118 might originate from a hardware failure and from transient failures (e.g., due to traction noise), and is thus dependent on MTTR (including the detection time) and the actual failure frequency.  The combination of all mentioned aspects should be considered.

### 4.4.6.5 Air-gap contribution

The denomination HXAG in the following refers to the explicit contribution to a hazard HX (see Table 4 on page 46) from the air-gap (e.g., due to disturbance).  See the principles of Figure 6 on page 47.

H1AG means that the Balise is not detectable due to e.g., noise in the air-gap.  This is not a contribution relevant to explicitly express.  However, for the Balise it is a requirement that the environment is considered in the corresponding calculation of the Balise contribution (H1B).  In the same way, it is required that the On-board Transmission Equipment is designed to be robust against air-gap disturbance.  Consequently, also H1OB shall absorb relevant contribution from air-gap disturbance.

H2AG means that air-gap disturbance leads to an erroneous Balise Detect (in the absence of a Balise).  This is not a contribution relevant to explicitly express.  However, it is required that the On-board Transmission Equipment is designed to be robust against air-gap disturbance.  Consequently, H2OB shall absorb relevant contribution from air-gap disturbance (which is not explicitly quantified for reasons mentioned in sub-clause 4.4.6.3 on page 46).

H3AG means that air-gap disturbance leads to activation of a KER Balise.  The probability for this is judged incredible.  Furthermore, H3 is not explicitly quantified for reasons mentioned in sub-clause 4.4.6.3 on page 46.

H4AG means that air-gap disturbance changes one telegram to another correct telegram (from the coding requirement standpoint). This is considered included in the not-trusted channel (see sub-clause 4.4.6.4 on page 47).

H5AG means that air-gap disturbance corrupts a telegram.  This is not a contribution relevant to explicitly express.  However, it is required that the On-board Transmission Equipment is designed to be robust against airgap disturbance.  Consequently, H5OB shall absorb relevant contribution from air-gap disturbance (which is not explicitly quantified for reasons mentioned in sub-clause 4.4.6.3 on page 46).

H6AG means that air-gap disturbance corrupts the Default Telegram.  This is not a contribution relevant to explicitly express.  However, it is required that the On-board Transmission Equipment is designed to be robust against air-gap disturbance.  Consequently, H6OB shall absorb relevant contribution from air-gap disturbance (which is not explicitly quantified for reasons mentioned in sub-clause 4.4.6.3 on page 46).

<!-- end of page 48 -->

H7AG means that disturbance in the air-gap might be transported in the infrastructure (e.g., via cables), and cause detectable Balise transmission at another position.  The probability for this is negligible considering that the installation rules for the Balise shall be able to cope with the defined cross-talk conditions (which put heavier demands on the rules).

H8AG means that disturbance in the air-gap might be transported in the infrastructure (e.g., via cables), and cause detectable Balise transmission at another position.  The probability for this is negligible considering that the installation rules for the Balise shall be able to cope with the defined cross-talk conditions (which put heavier demands on the rules).

H9AG means that disturbance in the air-gap might be transported in the infrastructure (e.g., via cables), and cause detectable Balise transmission at another position.  The probability for this is negligible considering that the installation rules for the Balise shall be able to cope with the defined cross-talk conditions (which put heavier demands on the rules).

### 4.4.6.6 Independence of hazard causes

For some of the hazards, dependencies also have to be considered.  The aspect on dependency between air-gap introduced phenomena and the hazards of sub-clauses 5.5.5.2 on page 81 and 6.4.5.2 on page 122 shall be considered.  The combined effects, e.g., hardware failures shall be analysed in the presence of noise.  This contribution comes in the respective Balise and On-board Transmission Equipment.  For failures in the Balise contribution, this shall be calculated for any ratio of random bit error rate.  For failures in the On-board Transmission Equipment, the actual worst case situation shall be considered if known, otherwise any ratio of random bit error rate applies.  See sub-clause 4.4.6.5 on page 48.

### 4.4.6.7 Conditions

The presumptions presented in sub-clauses 5.5.5.4 on page 82 and 6.4.5.4 on page 123 apply.  In particular, please observe that:

- The Basic Receiver defined in sub-clause 4.3.4 on page 41 is assumed to be implemented.  In case of other receiver principles, the entire analysis included herein needs to be re-considered.

- The consistency check of the received data, required by the SRS (see SUBSET-026), is applied on higher system level.

<!-- end of page 49 -->

## **4.5 Reference Axes and Origins of Co-ordinates**

Directions for the Balise and the Antenna Unit respectively shall be defined according to three reference axes related to the rails:

- A reference axis in parallel with the rails (the X-axis).

- A reference axis at right angles across the rails, and which is level with the top of rails (the Y-axis).

- A reference axis directed upwards, at right angles to the rail plane (the Z-axis).

The Balise shall carry reference marks on each of the six sides.  The reference marks shall indicate the positions of the three axes, related to the electrical centre of the Balise (see also sub-clause 5.2.2.4 on page 58).<sup>16</sup>

The Antenna Unit shall carry reference marks on each of the six sides.  The X, Y, and Z reference marks of the Antenna Unit indicate the positions of the X, Y, and Z axes respectively.  The manufacturer of the Antenna Unit shall specify the installation measurements related to these reference marks.

In this specification the lower edge of the Antenna Unit is used as height reference mark.  The offset from the lower edge to the X and Y reference marks shall be considered and indicated by the manufacturer of the Antenna Unit.

<!-- Start of picture text -->
Reference marks of<br>an Antenna Unit.<br>Z<br>Y<br>Z<br>X X<br>Electrical centre<br>Y<br>Z<br>Y<br>X<br>Positive<br>rotation<br>Reference marks<br>of a Balise.<br><!-- End of picture text -->

**Figure 7:  Reference Axes**

In general the origin of co-ordinates is in the plane of the top of rails, and in the middle of the track (as indicated in the right-hand part of Figure 6 above).  However, when explicitly referring to the Balise, the origin of coordinates is at the centre of its reference marks (and the directions of the axes are adjusted in order to coincide with potential tilt, pitch, and yaw angles of the Balise).  In a similar way, when explicitly referring to the Antenna Unit, the origin of co-ordinates is at the centre of its reference marks (and the directions of the axes are adjusted in order to coincide with potential tilt, pitch, and yaw angles of the Antenna Unit).

<!-- end of page 50 -->

To describe the angular deviations from the normal directions, three rotations are defined:

- **Tilt,** an angular deviation where the axis of rotation coincides with the X-axis.

- **Pitch,** an angular deviation where the axis of rotation coincides with the Y-axis.

- **Yaw,** an angular deviation where the axis of rotation coincides with the Z-axis.

To be able to exactly describe the angular deviation of an object related to these axes, the rotation operations shall be carried out in a specific sequence (starting from no angular deviation): yaw, pitch, and tilt.

The opposite order of rotation operations shall be used to align an object with the reference axes: tilt, pitch, and yaw.

## **4.6 Electrical Requirements**

### **4.6.1 On-board Equipment**

The On-board Transmission Equipment should be powered from an On-board battery power supply.

The power supply should comply with clause 3 of EN 50155.

### **4.6.2 Wayside Equipment**

For the controlled and the fixed Balise, transmission of Up-link data to interface ‘A’ shall occur without power from ground based equipment.  The needed power for the transmission of data to Interface ‘A’ shall be made by Tele-powering.

A controlled Balise could, in addition to the Tele-powering, be supplied with biasing power from an LEU via Interface ‘C’<sup>17</sup> .  The biasing power shall not leak into the Balise transmitter part, in order not to lower the overall cross-talk immunity.

> 17 The reason for this is the need to have the Balise input synchronised with the LEU output before a train passes, in situations where the time for transmission is limited to a minimum.

<!-- end of page 51 -->
