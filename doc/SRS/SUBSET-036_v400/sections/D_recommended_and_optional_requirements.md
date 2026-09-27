# **Annex D, Recommended and Optional Requirements**

# **D1 Interoperability with earlier generations of ATP**

## **D1.1 Requirements on the Tele-powering link to make Interoperability possible**

Interoperability with earlier generations of ATP systems that already operate with the Magnetic Transponder Technology in the Eurobalise frequency ranges is not required, but shall be and remain possible.  This applies to earlier generations of systems operating with a Tele-powering frequency of either 27.115 MHz or 27.095 MHz.

Specifically for interoperable systems, the On-board Transmission Equipment shall be able to pulse width modulate the 27.095 MHz carrier signal by a “toggling” 50 kHz synchronisation signal.

The specification of the toggling Tele-powering signal is defined in sub-clause B1.1 of Annex B on page 138.

## **D1.2 Transfer Syntax**

### **D1.2.1 Intentionally Deleted**

### **D1.2.2 Handshaking**

No handshaking shall be required.

### **D1.2.3 Disconnection**

The Up-link telegram shall be sent uninterrupted as long as the Up-link Balise receives enough power from the On-board Antenna Unit.

### **D1.2.4 Synchronisation**

A BCH cyclic block code shall be used.  The block length shall be 341 or 1023 bits.  The code shall be sent cyclically.  To avoid the need for awaiting the start bit of one data block this code shall be modified in such a way that the beginning of the message content can be found after a redundancy check has been performed.

<!-- end of page 143 -->

## **D1.3 EMC Requirements for Tele-powering**

The emission from the Eurobalise On-board Transmission Equipment transmitting the toggling Tele-powering signal is according to Figure 54 below.

<!-- Start of picture text -->
+42 dB  A/m<br>dB  A/m at 10 m<br>+25 dB/MHz +32 dB  A/m<br>-25 dB/MHz<br>f0-200 kHz f0-5 kHz f0+5 kHz f0+200 kHz<br>-1 dB  A/m<br>f0<br>Where f0 = 27.095 MHz<br>f<br><!-- End of picture text -->

**Figure 54:  Requirements for interoperable mode**

# **D2 Intentionally Deleted**

# **D3 Earlier ATP systems, Considered Products**

The following list of products is referred to in this document:

- Ebicab 700/900

- KVB

- RSDD

- Crocodile

- Signum

<!-- end of page 144 -->

# **D4 Balise Blocking Signal Output (Interface ‘C4’)**

## **D4.1 General**

Interface ‘C4’ is optional and not mandatory.  When it is implemented, it shall be used for transmitting the information to the LEU that the Balise is powered by a train.  This then requires that the LEU shall not be allowed to switch telegram for a certain time period.

Details at the LEU connector will be based on mutual agreements between concerned manufacturers.

## **D4.2 Physical Transmission**

### **D4.2.1 Transmission Medium**

### D4.2.1.1 General

The signal shall be polarity independent.  This means that interchanging the two inputs leads shall not affect the function of the interface.

The transmission shall be base band signals on electrical conductors.  The conductor shall be a balanced, shielded, twisted pair cable.

### D4.2.1.2 Cable Characteristics

The following applies.

|**Parameter**|**Limits**|
|---|---|
|Maximum attenuation at 8.8 kHz|2.0 dB/km|
|Maximum attenuation at 100 kHz|4.0 dB/km|
|Characteristic Impedance at 8.8 kHz|100to 200|
|Characteristic Impedance at 100 kHz|100to 170|

For the purpose of determining the cable attenuation, EN 50289 applies.

<!-- end of page 145 -->

### **D4.2.2 Electrical Data**

### D4.2.2.1 General

The signal shall consist of temporarily lowered input impedance of the Balise.  This impedance change shall be detected by the LEU through its effect on the output of the Interface ‘C6’ signal.

### D4.2.2.2 Signal Duration

The impedance change duration (the time when the min. 150 µs impedance is below ‘signal active’ load impedance) shall be max. 350 µs

### D4.2.2.3 Load Impedance of the Balise

The magnitude of the ‘signal not active’ load impedance shall be 150  < `|` Z `|` < 300  (in the relevant frequency band, 8.820 kHz ±0.1 kHz)

The magnitude of the ‘signal active’ load impedance shall be `|` Z `|` ≤ 10 % of ‘signal not (in the relevant frequency band, 8.820 kHz ±0.1 kHz) active’ load impedance

### **D4.2.3 Functional Data**

The Interface ‘C1’ signal shall not be disturbed by the impedance change.

<!-- end of page 146 -->

## **D4.3 Transmission of Messages on Application Level**

### **D4.3.1 General**

The interface shall handle a single message, defined according to this sub-clause.

### **D4.3.2 Message Description**

|Sender:|Balise|
|---|---|
|Receiver:|LEU|
|Purpose:|Inhibiting telegram switching for a certain time period|
|Trigger event:|The Balise is sufficiently powered through Interface ‘A’|
|Type:|Command|

**Table 22:  Messages**

### **D4.3.3 Repetition Rate**

The Balise shall send the Interface ‘C4’ message each time it starts being powered through the air gap.  The pulse shall begin when the flux level is within the window  d1-10 dB to  d1.  An additional time delay of maximum 150  s after the passage of  d1 is allowed.  The applicable level of  d1 is found in sub-clause 5.2.2.6 on page 63.

### **D4.3.4 Re-triggerability**

The LEU shall not be re-triggerable during the inhibition time.

## **D4.4 Safety**

No safety related requirements apply for Interface ‘C4’.  A failure is related to availability, not to safety.
