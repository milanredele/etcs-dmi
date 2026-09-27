# **5. ERTMS/ETCS ON-BOARD FUNCTIONS**

## **5.1 Functional architecture**

5.1.1.1 The ERTMS/ETCS on-board equipment shall allow the STM to communicate with the following functions:

   - a) DMI

   - b) STM Control

   - c) Reference Time

   - d) BIU

   - e) TIU

   - f) Juridical Data

   - g) Odometer

<!-- Start of picture text -->
Driver<br>DMI<br>ERTMS/ETCS On-board<br>FFFIS STM<br>Radio<br>Transmission<br>STM Sync And Reference Time Reference Clock Function DMI Function TransmissionLoop<br>Balise<br>DMI Data Transmission<br>STM Control Function Data STM Control Function<br>Supervision<br>Function Odometer Data Odometer Function<br>Juridical Data<br>Brake Interface Data<br>Train Interface Data<br> Juridical Data<br>Function<br>TIU Function BIU Function<br>National  FIS TI FIS JR<br>Trackside<br><!-- End of picture text -->

**Figure 1 – General configuration of STM and ERTMS/ETCS on-board**

## **5.2 Data and ERTMS/ETCS on-board functions**

5.2.1.1 The following paragraphs describe the ERTMS/ETCS on-board functions that are available for STM and the data that shall be transmitted over the interface.

5.2.1.2 The data is transmitted over the STM bus using Multicast or Point-to-Point Connections, see chapter 6.5.

### **5.2.2 Reference time**

<!-- end of page 34 -->

5.2.2.1 ERTMS/ETCS on-board is responsible for providing common reference time to all connected STMs. This is defined in [2].

### **5.2.3 Odometer**

5.2.3.1 Odometry data & parameters shall be sent by the ERTMS/ETCS on-board to all STMs using multicast messages.

### **5.2.4 Train Interface (TIU)**

5.2.4.1 A subset of the train interface signals specified in [6], command and status / availability are transmitted via the FFFIS STM. These train interface signals transmitted via the FFFIS STM are called Train Interface FFFIS STM signals.

5.2.4.2 The TIU Function is described as the exchange of information between the train interface and the STM, in this case:

a) Status: is functional information coming from the train interface to the STM,

b) Command: is functional information coming from the STM to the train interface.

5.2.4.3 Train Interface FFFIS STM command signals shall be:

|**Command signal**|**Description**|
|---|---|
|Regenerative Brake|To allow or to suppress the use of the<br>Regenerative Brake.|
|Magnetic Shoe Brake|To allow or to suppress the use of the<br>Magnetic Shoes Brake.|
|Eddy Current Brake for Service Brake|To allow or to suppress the use of the Eddy<br>Current Brake for Service Brake.|
|Eddy Current Brake for Emergency Brake|To allow or to suppress the use of the Eddy<br>Current Brake for Emergency Brake.|
|Pantograph|Lower or raise the Pantograph|
|Air Tightness|Open or close air flaps|
|Main Switch / Circuit Breaker|Open or close the Main Switch / Circuit<br>Breaker. This is considered as only one<br>command.|
|Traction Cut Off|Cut off or not the traction|

5.2.4.3.1 Note: Service and Emergency Brake commands are handled in the BIU interface see chapter 5.2.5.

5.2.4.4 Train Interface FFFIS STM status signals shall be:

|**Status signal**|**Description**|
|---|---|
|Traction status|Specifies the status of the traction power|
|Direction Controller information|Specifies the position of the direction controller|
|Cab Status|Specifies the active cab|

5.2.4.4.1 Note: Service and Emergency Brake status are handled in the BIU interface see chapter 5.2.5.

### **5.2.5 Brake Interface (BIU)**

<!-- end of page 35 -->

5.2.5.1 The Brake Interface via ETCS is formally a part of the Train Interface. It shall include the brake interface parameters, command and status / availability of the Emergency Brake access and the Service Brake access.

5.2.5.2 Note: The BIU Function is separated from the TIU Function to allow physical separation and different safety and performance levels between brake commands/status and other commands/status on the Train Interface.

5.2.5.3 The brake status gives the availability of the brake command.

### **5.2.6 Juridical data**

5.2.6.1 The FFFIS STM shall offer the possibility to the STM to transmit the national juridical data to be forwarded (together with the ETCS data) to the On-Board Recording Device.

### **5.2.7 STM Control Function**

5.2.7.1 The STM Control Function shall control the STM state and the compatibility of the ERTMS/ETCS on-board and STM versions.

5.2.7.2 The STM Control Function shall handle the transmission of the ETCS data for STM and of the Specific NTC Data Entry/Data View for STM.

5.2.7.3 The STM Control Function shall handle the transmission of the ETCS status data for STM.

5.2.7.4 The STM Control Function shall handle the transmission of the language used to display information to the driver.

5.2.7.5 The STM Control Function shall handle the test procedure for STMs.

5.2.7.6 The STM Control Function shall handle the Override procedure for STMs.

5.2.7.7 The STM Control Function shall handle the trackside data to be transmitted to an NTC.

5.2.7.8 The STM Control Function shall handle STM max speed and STM system speed/distance.

5.2.7.9 The STM Control Function shall handle the transmission of the bus address, safety level and availability of the ERTMS/ETCS on-board functions.

5.2.7.10 The STM Control Function shall handle the display of STM failure status.

5.2.7.11 The STM Control Function shall handle the transmission of the active Interface 'K' Antenna/BTM.

5.2.7.12 The STM control function shall handle the transmission of the BTM alarm data.

### **5.2.8 DMI**

5.2.8.1 The DMI Function shall allow an active STM to dialogue with the driver for what regards its default window (see [9] chapter 9). This includes:

   - a) Management of buttons,

<!-- end of page 36 -->

- b) Management of indicators,

- c) Management of sounds,

d) Management of text messages,

e) Management of supervision information

## **5.3 ERTMS/ETCS on-board functions and resources available for STMs**

5.3.1.1 The ERTMS/ETCS on-board shall allow the STM to access its functions and resources according to the following table:

a) x = access is allowed in all Levels

b) (x) = access is allowed in all Levels if possible

c) s = access is only allowed for an active STM (see chapter 4.1.1.3)

- d) h = access is allowed for an STM in HS for preliminary request for DMI objects (see 13.2.1.5)

|**ERTMS/ETCS ON-BOARD**<br>**functions and resources**<br>**available for STMs**|**N**<br>**P**|**S**<br>**B**|**P**<br>**S**|**S**<br>**H**|**F**<br>**S**|**L**<br>**S**|**S**<br>**R**|**O**<br>**S**|**S**<br>**L**|**N**<br>**L**|**U**<br>**N**|**T**<br>**R**|**P**<br>**T**|**S**<br>**F**|**I**<br>**S**|**S**<br>**N**|**R**<br>**V**|
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
|STM Control Function||x|x|x|x|x|x|x|x|x|x|x|x|||x|x|
|Reference Time||x|x|x|x|x|x|x|x|x|x|x|x|||x|x|
|DMI Function||h|||h|h|h|h||s,<br>h|h|h|h|||s,<br>h||
|Juridical Data||x|x|x|x|x|x|x|x|x|x|x|x|(x)||x|x|
|Odometer Function||x|x|x|x|x|x|x|x|x|x|x|x|||x|x|
|TIU<br>command<br>(Train<br>Interface<br>FFFIS STM signals)|||||||||s|s||||||s||
|TIU status (Train Interface FFFIS<br>STM signals)||x|x|x|x|x|x|x|x|x|x|x|x|||x|x|
|BIU command||||||||||||||||s||
|BIU status||x|x|x|x|x|x|x|x|x|x|x|x|||x|x|

5.3.1.2 When an ERTMS/ETCS on-board function fails, it shall isolate itself from the bus and shall try to close the connection with the STM.

<!-- end of page 37 -->
