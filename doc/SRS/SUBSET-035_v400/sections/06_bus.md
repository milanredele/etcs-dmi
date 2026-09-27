# **6. BUS**

## **6.1 The PROFIBUS**

6.1.1.1 The bus used for the interface between STM and ERTMS/ETCS on-board functions shall be the PROFIBUS, defined by [5].

6.1.1.2 The PROFIBUS protocol is used up to the FDL layer.

6.1.1.2.1 Note: The use of the FDL layer is specified in [3], chapter 4.

6.1.1.3 The bus configuration parameters for the PROFIBUS shall be:

   - a) Baud Rate: 1500 Kbps

   - b) Minimum Station Delay of Responders (min TSDR): 11 tBit

   - c) Maximum Station Delay of Responders (max TSDR): 150 tBit

   - d) Slot Time (TSL): 300 tBit

   - e) Quiet Time (TQUI): 0 tBit

   - f) Setup Time (TSET): 1 tBit

   - g) Time Target Rotation (TTR): 30000 tBit (20 ms)

   - h) GAP Actualisation Factor (G): 10

   - i) Highest Station Address (HSA): 126

   - j) Max Retry Limit (max_retry_limit): 1

6.1.1.3.1 Note: This allows for a maximum permissible line length (PROFIBUS length) of 200 m per segment and a maximum number of 32 stations when using cable type A. In case a greater length or more stations are required, repeaters can be used without changing the configuration.

6.1.1.3.2 Note: PROFIBUS may also be used for other communications than the one between STM and ERTMS/ETCS on-board specified in this FFFIS STM.

### **6.1.2 Physical connection**

6.1.2.1 The default physical medium shall be RS-485 twisted pair shielded copper cable.

6.1.2.2 The default connectors of the different equipments (ERTMS/ETCS on-board functions and STMs) shall be 9-pin female D-SUB and cabling according to PROFIBUS specifications.

### **6.1.3 Bus redundancy and retransmission**

6.1.3.1 Retransmission is specified in [3]

6.1.3.2 Regarding bus redundancy, the STM and ERTMS/ETCS on-board shall have at least one bus interface each, and may have two interfaces.

<!-- end of page 38 -->

6.1.3.3 In case STM and ERTMS/ETCS on-board do not have the same number of buses, only one bus shall be connected.

6.1.3.4 The dual bus configuration shall be managed by the “Redundancy Supervisor” see Ref.: [3].

## **6.2 Safety**

6.2.1.1 To allow communication between different equipment with different Safety Integrity Levels (SIL), the FFFIS STM shall provide communication with three levels of safety protocol (SL):

   - a) Safety Level 4 (SL 4)

   - b) Safety Level 2 (SL 2)

   - c) Safety Level 0 (SL 0)

6.2.1.1.1 Justification: According to the requirements for Safety-related communication in transmission systems (see [8]), an equipment with no or a low Safety Integrity Level shall not masquerade as an equipment with a higher Safety Integrity Level. This requirement shall be fulfilled by using the defined Safety Levels.

6.2.1.1.2 Note: The three levels of safety are specified in [3] and [2].

6.2.1.2 No equipment shall implement any Safety Level corresponding to a higher Safety Integrity Level (SIL).

6.2.1.3 ERTMS/ETCS on-board functions shall implement all the safety protocols up to the Safety Level (SL) corresponding to the SIL of the function.

## **6.3 On-board Architecture**

6.3.1.1 Each STM shall only have one physical bus address (Station/Node address) towards the ERTMS/ETCS on-board.

6.3.1.2 The ERTMS/ETCS on-board may use one or several physical bus addresses depending on its architecture.

6.3.1.3 An STM shall be able to handle one different physical address for each ERTMS/ETCS on-board function.

6.3.1.4 In case several STMs share the same physical address, each of them shall establish its own connection at Application Layer using different NID_STMs.

## **6.4 Physical Addressing (Station/Nodes addresses)**

6.4.1.1 The physical addresses shall be allocated according to the following table.

<!-- end of page 39 -->

|**Physical Address**|**Device**|
|---|---|
|2|STM Control Function|
|0, 1, 2, 3 . . 19|Other ERTMS/ETCS on-board functions|
|20 . . 49|Unused by FFFIS STM|
|50 . . 69|STM configurable addresses range|
|70 . . 126|STMs (NID_NTC+70)|
|127|Reserved for Broadcast and Multicast|

6.4.1.2 By default the Physical address of an STM shall be the NID_NTC value + 70.

6.4.1.3 STM configurable addresses range shall be used for STMs for which the sum of NID_STM value +70 goes out of the Profibus physical address range

6.4.1.4 In case several STMs share the same physical address, the address value shall be the one of any of the supported STMs or a configurable physical address.

6.4.1.5 When a physical address in the STM configurable addresses range is to be used, it shall be possible to configure the value of this physical address in order to solve any potential address conflicts.

## **6.5 Function Addressing**

6.5.1.1 The FFFIS STM requires communication with different functions of the ERTMS/ETCS on-board as e. g. Odometer, DMI and Juridical Data.

6.5.1.2 The FFFIS STM shall use Service Access Points (SAPs) to support communication between STMs and the different ERTMS/ETCS on-board functions.

6.5.1.3 All ERTMS/ETCS on-board functions shall have a defined fixed SAP.

6.5.1.3.1 Note: The SAP is fixed regardless of the chosen physical address.

6.5.1.4 For transmitting data between ERTMS/ETCS on-board and the STMs, the local (Source) Service Access Point (SSAP) and partner (Destination) Service Access Point (DSAP) shall have the same value.

6.5.1.5 The SAP number shall be defined according to the following table:

|**Logical connections**|**SAP#**<br>**(binary)**|**# of**<br>**SAP**|**Comment**|
|---|---|---|---|
|DMI channel 3|000000|1|Point-to-point|
|DMI channel 4|000001|1|Point-to-point|
|Juridical Data|000010|1|Point-to-point|
|Reserved for FFFIS STM|000011|1|Not used (reserved for backward compatibility).|
|DMI channel 1|000100|1|Point-to-point|
|DMI channel 2|000101|1|Point-to-point|
|Reserved for FFFIS STM|000110|1|Not used (reserved for backward compatibility).|
|Reserved for FFFIS STM|000111|1|Reserved for future extension of the specification|
|Unused by FFFIS STM|001XXX|8|To be defined by on-board implementers|

<!-- end of page 40 -->

|**Logical connections**|**SAP#**<br>**(binary)**|**# of**<br>**SAP**|**Comment**|
|---|---|---|---|
|Unused by FFFIS STM|01XXXX|16|To be defined by on-board implementers|
|Reference Time|100000|1|Multicast|
|STM Control|100001|1|Point-to-point|
|Reserved for FFFIS STM|100010|1|Not used (reserved for backward compatibility).|
|Reserved for FFFIS STM|100011|1|Not used (reserved for backward compatibility).|
|Reserved for FFFIS STM|100100|1|Not used (reserved for backward compatibility).|
|Train Interface|100101|1|Point-to-point|
|Brake Interface|100110|1|Point-to-point|
|Odometer|100111|1|Multicast for FFFIS STM version number X=4|
|Unused by FFFIS STM|101XXX|8|Defined by each implementer.|
|Reserved for FFFIS STM|11XXXX<br>Except<br>111111<br>reserved<br>for<br>broadcast|15|Reserved for future extension of the specification|
|Broadcast|111111|1|Reserved due to PROFIBUS specification|

6.5.1.6 There shall be only one source (one station/node address) which shall transmit messages using the SAP reserved for the Reference Clock Function.

6.5.1.7 There shall be only one source (one station/node address) which shall transmit messages using the SAP reserved for the Odometer Function.

## **6.6 Protocol Layers**

6.6.1.1 The protocol layers are Application Layer (see [4]), Safe Time Layer (see [2]), Safe Link Layer (see [3]) and PROFIBUS FDL layer (see [5]).

6.6.1.2 The Safe Time Layer and Safe Link Layer together shall be considered as the Safety Layers.

<!-- Start of picture text -->
Application Layer Application data<br>Com- Time<br>Safe Time Layer mand Stamp<br>Explicit Com-<br>Safe Link Layer Header mand CRC<br>Profibus FDL Layer Header Trailer<br><!-- End of picture text -->

**Figure 2 - Application Data encapsulation by the layers in PROFIBUS telegram**

<!-- end of page 41 -->

<!-- Start of picture text -->
Time stamp for signalling /<br>Application Application<br>application<br>Time stamp for safe bus<br>Safe Time Layer Safe Time Layer<br>communication<br>Sequence number, identity<br>Safe Link Layer Safe Link Layer<br>and CRC<br>Redundancy Unsafe redundancy Redundancy<br>supervisor supervisor<br>Unsafe bus<br>FDL FDL<br>Unsafe bus<br>FDL FDL<br><!-- End of picture text -->

**Figure 3 - FFFIS STM Protocol Layers**

<!-- end of page 42 -->
