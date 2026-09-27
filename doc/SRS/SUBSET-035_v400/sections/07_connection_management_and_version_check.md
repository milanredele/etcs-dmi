# **7. CONNECTION MANAGEMENT AND VERSION CHECK**

## **7.1 General requirements linked to the opening of point-to-point connection between STM and ERTMS/ETCS on-board**

### **7.1.1 Opening of the connection**

7.1.1.1 A connection shall be considered as established when the version check is considered as completed and successful (see chapter 7.1.2).

7.1.1.2 The STM shall take the initiative to establish the connection.

7.1.1.3 When a STM has to establish a connection with an ERTMS/ETCS on-board function, and fails to establish the connection 2 times, it shall be allowed to retry the establishment of connection after 10 seconds.

### **7.1.2 Check of version**

7.1.2.1 Each time the STM opens a connection with any ERTMS/ETCS on-board function, the STM shall send its “FFFIS STM version number” to this ERTMS/ETCS on-board function, followed by the STM state report information in the same application message.

7.1.2.2 When receiving the “FFFIS STM version number” from the STM, the concerned ERTMS/ETCS on-board function shall check the version compatibility as follows:

   - a) if the “FFFIS STM version number X” from the STM is lower than the lowest “FFFIS STM version number X” supported by the ERTMS/ETCS on-board equipment, the ERTMS/ETCS on-board function shall close the connection (final disconnection on Safety Layers).

   - b) if the “FFFIS STM version number X” from the STM is amongst the ones supported by the ERTMS/ETCS on-board equipment, the ERTMS/ETCS on-board function shall send to the STM the highest supported FFFIS STM version number of which the version number X is equal to the one received from the STM. The ERTMS/ETCS onboard function shall be allowed to transmit application data to the STM.

   - c) if the “FFFIS STM version number X” from the STM is greater than the highest version number X supported by the ERTMS/ETCS on-board equipment, the ERTMS/ETCS on-board function shall close the connection (final disconnection).

7.1.2.3 When receiving “FFFIS STM version number” from ERTMS/ETCS on-board, the STM shall check the version compatibility. If it is compatible with the “FFFIS STM version number” of the STM, then the version check is considered as terminated and successful. The STM shall be allowed to transmit further application data to the ERTMS/ETCS onboard function.

7.1.2.4 If the “FFFIS STM version number” of the ERTMS/ETCS on-board is not compatible with the “FFFIS STM version number” of the STM, then the STM shall close the connection (final disconnection) to the concerned ERTMS/ETCS on-board function.

<!-- end of page 43 -->

### **7.1.3 Closing of the connection**

7.1.3.1 Closing a connection on application layer shall be done by requesting the Safety Layers (see 6.6.1.2) to close the connection.

<!-- Start of picture text -->
7.1.4  Connection Sequence Charts.<br>STM ETCS<br>Safety Layer connection<br>Net Data message: Version number<br>Connection<br>established<br>Connection  Net Data message: Version number  for ETCS<br>established<br>for STM<br>Other Net Data Messages<br>Safety Layer disconnection<br><!-- End of picture text -->

**Figure 4 Nominal connection establishment sequence chart**

<!-- Start of picture text -->
STM ETCS<br>Safety Layer connection<br>Net Data message: Version number<br>Connection<br>rejected by<br>ETCS<br>Safety Layer disconnection<br><!-- End of picture text -->

**Figure 5  Bad version number disconnection sequence chart**

## **7.2 General requirements linked to handling multicast connection**

<!-- end of page 44 -->

7.2.1.1 The multicast sender shall open a separate connection for all “FFFIS STM version numbers” defined in the Legal backward compatibility envelope (see table 16.3.1.1).

7.2.1.2 Note: For each multicast application connection (currently limited to Odometer Function), the table 6.5.1.5 contains one SAP for each “FFFIS STM version number”. This allows opening separate connections.

7.2.1.3 On each connection, the multicast sender shall transmit the corresponding “FFFIS STM version number” over the FFFIS STM. The transmission shall be repeated to support restarting STMs.

7.2.1.4 When receiving “FFFIS STM version number” from ERTMS/ETCS on-board, the STM shall check the version compatibility.

7.2.1.5 If the “FFFIS STM version number” of the ERTMS/ETCS on-board is not compatible with the “FFFIS STM version number” of the STM, then the STM shall ignore any information received from this multicast connection.

<!-- end of page 45 -->
