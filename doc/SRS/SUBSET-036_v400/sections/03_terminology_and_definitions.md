# **3 Terminology and Definitions**

## **3.1 Acronyms and Abbreviations**

In general, the acronyms of SUBSET-023 apply.  Additionally, the following list of acronyms applies within this specification:

|**Acronym**|**Explanation**|
|---|---|
|AM|Amplitude Modulation|
|ASK|Amplitude Shift Keying|
|BCH|Bose-Chaudhuri-Hocquenghem|
|BER|Bit Error Rate|
|CW|Continuous Wave|
|DBPL|Differential Bi Phase Level|
|DC|Direct Current|
|Ebicab|ATP system based on Magnetic Transponder Technology|
|FIFO|First In, First Out|
|FSK|Frequency Shift Keying|
|GF(2)|Galois Field base 2|
|H/W|Hardware|
|ID|Identification code|
|I/O|Input-Output|
|KER|KVB, Ebicab, RSDD|
|KVB|Controle de Vitesse par Balise (ATP system based on Magnetic<br>Transponder Technology)|
|LSB|Least Significant Bit|
|MSB|Most Significant Bit|
|MTIE|Maximum Time Interval Error|
|NV|Non Volatile|
|RMS|Root Mean Square|
|RSDD|Ripetizione Segnali Discontinua Digitale (ATP system based on<br>Magnetic Transponder Technology)|
|S/W|Software|

<!-- end of page 13 -->

The following abbreviations apply:

|**Abbreviation**|**Explanation**|
|---|---|
|max.|maximum|
|min.|minimum|
|Ref.|Reference|
|Vpp|Volts peak to peak|

<!-- end of page 14 -->

## **3.2 Definitions**

In general, the definitions of SUBSET-023 apply.  Additionally, the following list of definition applies within this specification:

|**Term**<br>**Antenna Reference Marks**|**Definition**<br>These indicate the electrical centre of the Antenna Unit.|
|---|---|
|**Antenna Unit**|The On-board Transmission Unit, with the main functions to transmit<br>signals to and/or receive signals from the Balise through the air gap.|
|**Balise**|A wayside Transmission Unit that uses the Magnetic Transponder<br>Technology.  Its main function is to transmit and/or receive signals<br>through the air gap.  The Balise is a single device mounted on the track,<br>which communicates with a train passing over it.  In this specification,<br>Balise is used as a short word for Eurobalise, unless otherwise stated.|
|**Balise Cross-talk Zone**|The zone outside the Main Lobe Zone and the Side lobe Zone, where<br>less stringent requirements on Up-link field conformity with the refer-<br>ence field is defined for the Balise.|
|**Balise Group**|One or more Balises that on a higher system level together create a<br>quantity of information related to the location reference in the track, the<br>direction of validity of data, and train protection information.  This is<br>the location in the track where spot transmission occurs.|
|**Balise Information**|The information part of the Balise Telegram (i.e., the telegram without<br>CRC, control bits, and synchronisation bits), i.e., the user bits.|
|**Balise Reference Marks**|These correspond to the centre of symmetry of the Balise radiation<br>pattern.|
|**Balise Telegram**|The Balise Telegram located in the Balise Data.  The telegram consists<br>of information, CRC, and synchronisation bits.|
|**Balise Transmission Module**<br>**(BTM)**|An On-board module for intermittent transmission between track and<br>train, which processes Up-link signals and telegrams from a Balise.  It<br>interfaces the ERTMS/ETCS Kernel and the Antenna Unit.|
|**BTM Function**|An On-board function that processes Up-link data, and that interfaces<br>the ERTMS/ETCS Kernel and the On-board Antenna Unit.  This is not<br>necessarily a physical device, and it is not a Constituent itself (but is<br>part of the ERTMS/ETCS On-board Constituent).|
|**Cluster of Balises**|One or more Balises that seen from the vehicle, regardless of the con-<br>tained information, are close to each other.  The definition of ‘close’ is<br>dependent on the Maximum Permitted Speed.|
|**Compatibility**|Compatibility between two systems means that they can coexist under<br>defined conditions without interfering with each other as to specified<br>functions.|

<!-- end of page 15 -->

|**Term**|**Definition**|
|---|---|
|**Contact Length**|In general, the distance between the place where a train becomes able<br>to communicate with a device (e.g., a Balise) to the place where com-<br>munication becomes impossible.<br>In particular for this specification, the longitudinal distance that is<br>needed to ensure transmission from the Balise with the specified quali-<br>ty (e.g., see sub-clause 4.2.8.2 on page 32).  The contact length is de-<br>pendent on the specific lateral displacement and on the mounting<br>height.|
|**Contact Volume**|The volume constituted by the Contact Lengths for all lateral displace-<br>ments and mounting heights of the antenna where transmission from<br>the Balise is guaranteed with the specified quality.|
|**Contact Zone**|See Main Lobe Zone.|
|**Cross-talk**|When a telegram is read from a Balise that should not be read, e.g., a<br>Balise on another track.|
|**Cross-talk protected zone**|The zone in the vicinity of the Balise where transmission is not intend-<br>ed to take place.|
|**Default Telegram**|This is an Up-link Telegram permanently stored in controlled Up-link<br>Balises.  This telegram is transmitted in the event of communication<br>failure between the Up-link Balise and the LEU.  This is mainly used<br>for failure detection purposes (but constitutes a valid Eurobalise Tele-<br>gram).|
|**Eurobalise**|One set of technical solutions for Balises used in an ERTMS/ETCS<br>installation.  A Eurobalise is a Balise that fulfils the mandatory re-<br>quirements of clauses 4 and 5 of this specification.|
|**Eurobalise Transmission**<br>**System**|The Pan-European spot transmission system for transmission between<br>wayside and the ERTMS/ETCS Kernel.  It is a sub function in the total<br>European Rail Traffic Management System, ERTMS, and it is one of<br>the sub-systems in the railways’ European Train Control System,<br>ETCS.|
|**Eurobalise Telegram**|This is a telegram fulfilling the Coding Requirements, and carrying<br>application data for the ERTMS/ETCS system according to the ETCS<br>language.  The length of the telegram is either 341 bits (including 210<br>User Bits) which is also referred to as “short telegram”, or 1023 bits<br>(including 830 User Bits) which is also referred to as “long telegram”.|
|**‘fL’ **|The lower of the two frequencies used by the Up-link Balise to accom-<br>plish the FSK type of modulation for transmitting Eurobalise Tele-<br>grams.|
|**‘fH’ **|The higher of the two frequencies used by the Up-link Balise to ac-<br>complish the FSK type of modulation for transmitting Eurobalise Tele-<br>grams.|

<!-- end of page 16 -->

|**Term**|**Definition**|
|---|---|
|**Fixed Data**|Data transmitted to and from the train, and that can only be changed by<br>reconfiguration, i.e., data that does not change during normal railway<br>operation.|
|**Fixed Telegram**|A telegram with fixed data in the Up-Link Balise.|
|**Interface ‘A’**|The air gap interface between the wayside Eurobalise and the On-board<br>Transmission Equipment.  It is used for data exchange between track<br>and train.  The interface uses magnetic coupling.|
|**Interface ‘C’**|The wayside interface between the LEU and the Eurobalise.  Telegrams<br>are sent/received serially at the same data rate as in the air gap.|
|**Interface ‘S’**|The input to the LEU (Up-link) that interfaces the different national<br>railway signalling equipment.  This is not part of the Eurobalise<br>Transmission System.|
|**Interface ‘V’**|The test interface between the On-board Transmission Equipment, and<br>external test and verification equipment.  This interface is used for<br>controlling the BTM function, and for acquiring data during system<br>verification tests (certification tests).|
|**Interoperability**|In general, Interoperability between two systems means that they can<br>operate mutually at a specified time and place as to specified function.<br>In particular, Interoperability means the ability of the Trans-European<br>high speed rail system to allow the safe and uninterrupted movement of<br>high speed trains that accomplish the specified levels of performance.|
|**Lineside Electronic Unit**<br>**(LEU)**|A Wayside unit that interfaces the national Wayside Signalling Equip-<br>ment and the Balise.  Specifically for the purpose of Up-link, it is a<br>device for communicating variable signalling data to controlled Balis-<br>es. LEU is not within the scope of this specification.|
|**Location Reference**|A position in the track.  For a single Balise it refers to the reference<br>mark of the Balise (see sub-clause 4.5.1), and for a Balise Group it<br>refers to Balise number one of the Balise Group (the Balise with<br>N_PIG = 0).|
|**Magnetic Transponder**<br>**Technology**|A method that uses magnetic coupling in the air gap between a trans-<br>mitter and a receiver for conveying data and energy.  In the Eurobalise<br>Transmission System context, it considers systems using the 27 MHz<br>band for Tele-powering and the 4.5 MHz band for Up-link transmis-<br>sion.  The magnetic field is mainly vertical, and the transponder is<br>located in the centre of the track.|
|**Main Lobe Zone**|The zone above the Balise, where the highest requirements on field<br>conformity of the magnetic field with the reference field apply for the<br>Balise.<br>The Main Lobe Zone is identical to the previously used Contact Zone.|
|**Maximum Permitted Speed**|The highest speed that any train is permitted to operate at**,**where Balis-<br>es or concerned metallic objects are installed. The actual train speed<br>may be higher than the Maximum Permitted Speed due to speed meas-<br>urement inaccuracy and brake intervention limits.|
|**Non-toggling Tele-powering**<br>**signal**|50 kHz modulation of the Tele-powering signal, where each modula-<br>tion pulse has the same length.  Characteristic of the modulation used<br>in the older KER ATP/ATC systems.|
|**On-board ATP/ATC**|Synonymous to Train Borne Equipment defined in SUBSET-023.|

<!-- end of page 17 -->

|**Term**|**Definition**|
|---|---|
|**On-board Transmission**<br>**Equipment**|Consists of Antenna Unit(s) (for Magnetic Transponder Technology),<br>and the Balise Transmission Function.  It functionally matches the air<br>gap interface and the ERTMS/ETCS Kernel.|
|**Pitch**|An angular deviation where the axis of rotation coincides with the Y-<br>axis (see sub-clause 4.5 on page 50).|
|**Reliability Cross-talk**|Disturbing effect on the transmission of data such that correct transmis-<br>sion is unattainable.|
|**Safety Cross-talk**|The acceptance of unwanted signals and data, interpreted as valid, by<br>an unintended receiver.|
|**Side lobe Zone**|The zone relative to the Balise outside the Main Lobe Zone, where less<br>stringent field conformity with the reference field is defined for the<br>Balise.|
|**Spot Transmission System**|Consists of LEU, Balise, and On-board Transmission Equipment.  The<br>LEU is not within the scope of this specification.|
|**Telegram**|A Telegram contains one header and an identified and coherent set of<br>packets.  There are several types of Telegrams referred to in this speci-<br>fication.|
|**Tele-powering**|The method used for powering a Balise from an Antenna Unit through<br>the airgap.|
|**Tele-powering signal**|A signal transmitted by the On-board Transmission Equipment, which<br>activates the Balise uponpassage.|
|**Tilt**|An angular deviation where the axis of rotation coincides with the X-<br>axis (see sub-clause 4.5 onpage 50).|
|**Toggling Tele-powering**<br>**Signal**|50 kHz modulation of the Tele-powering signal, where every other<br>modulation pulse is longer.  Characteristic of the modulation used in an<br>On-board Transmission Equipment in interoperable mode.|
|**Up-link**|All functions that are needed in the Eurobalise Transmission System to<br>constitute the communication from the LEU, or from the fixed Balise,<br>to the ERTMS/ETCS Kernel.|
|**Up-link Telegram**|This is a Eurobalise Telegram used for Up-link communication, includ-<br>ing one User Bit categorising the telegram as valid for Up-link applica-<br>tion.|
|**Valid Telegram**|A Balise Telegram fulfilling the coding requirements of sub-clause 4.3<br>on page 36.|

<!-- end of page 18 -->

|**Term**|**Definition**|
|---|---|
|**Variable Data**|Data transmitted to and from the train, and that may change during<br>normal railway operation.|
|**Yaw**|An angular deviation where the axis of rotation coincides with the Z-<br>axis (see sub-clause 4.5 on page 50).|

## **3.3 Influence of Tolerances**

The requirements in this specification do not involve the error of the test equipment that is used in the test process, unless this is expressly written.  This means a maximum limit value shall be decreased and a minimum limit value shall be increased with the applicable measurement error during test.  The same principle applies to propagation of admitted tolerances when several quantities are combined or analysed.  Further details are found in SUBSET-085.

<!-- end of page 19 -->
