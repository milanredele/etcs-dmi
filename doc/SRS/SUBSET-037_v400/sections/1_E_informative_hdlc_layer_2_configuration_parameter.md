# **ANNEX E. (INFORMATIVE) HDLC LAYER 2 CONFIGURATION PARAMETERS FOR CS MODE**

E.1.1.1 This Annex is included to clarify the following values.

E.1.1.2 There are some dependencies for choosing the HDLC parameters. The following considerations are valid for ETCS data links. For other links the values can be calculated equivalent.

E.1.1.3 Consideration 1:

To send with full bandwidth, the Tx Buffer must have at least a capacity to transmit continuously data frames up to receiving the acknowledgement of the first transmitted frame. The Tx Buffer should not be significantly larger than this value because of blocking retransmission frames. This value depends on the windows size k, the number of bits per frame N1 (corrected by start and stop bit, which attributes to the buffer bit count by a factor of 1+2/8=1.25 and including a maximum of two start/stop flags which adds another 16 bits per HDLC frame), the nominal user rate of the link (X=4800 bit/s) and two times the transmission + processing delay of a frame (TF assumed with 500 ms, corresponding to a round trip time of 2 * TF = 1 s). Specific values for k and N1 must therefore respect the following relationship, taking also into account 2 HDLC frames in the opposite direction:

E.1.1.4 Consideration 2: T1 has to be larger than _two times transfer delay to avoid checkpointing at each HDLC transmission. An additional margin for buffer delays_ of the other entity of 500 ms is necessary. Hence T1 is set to 1.5 s.

E.1.1.5 Consideration 3: T4 is an optional parameter controlling the keep alive mechanism of HDLC. A small value decreases the time to detect an interrupted data link. A value between T1 and two times T1 is reasonable. T4=2 s is recommended.

E.1.1.6 Consideration 4: The time T to try to transmit a frame until eventually disconnecting in case of not receiving any acknowledgment, depends on the number of retransmissions N2 and the timer T1:

This time should be high enough to reach a high probability of MA transmission within 12 s as required by the infrastructure providers. According to field experiences of different projects and vendors this time is considered to be about 8s. With T1=1.5 s (see consideration 2), Hence N2 is set to 4.

E.1.1.7 In the following table, a representation of the T_NVCONTACT computation is given assuming a general message rate of 4 s and a position report rate of 4 s:

<!-- end of page 78 -->

**Table 62 T_NVCONTACT computation**

|**Time Event**|**min.**|**max.**|**Description**|
|---|---|---|---|
||0||General Message reception in parallel to the sending<br>of the Position Report that will be lost|
|time elapsed since the last reset of<br>T_NVCONTACT||7|General Message reception 4s before interference,<br>Position Report sent and its ACK received just before<br>the interference that caused the loss of the next<br>general message|
|Transmission/retransmission|7.5|7.5|(N2+1)*T1 with N2 = 4 and T1 = 1.5 s|
|ll / bil|1||free mobile available(1s is an assumption)|
|reca  moe recovery||5|no free mobile available(5s is an assumption)|
|Connection Establishment Delay|8.5|8.5|Refer to Subset-093|
|Protocol establishment|4|4|HDLC, TP2 and safety layer protocol establishment<br>(4s is an assumption)|
|new<br>message<br>available<br>for<br>transmission|0|4*|no synchronization between the cyclic sending of<br>General<br>Messages<br>and<br>the<br>connection<br>re-<br>establishment|
||1||transmit General Message|
|transmission of the message||2.5|transmit MA|
|**_Final Time_**|**_22_**|**_38.5*_**||

- T_NVCONTACT < 22 s: T_NVCONTACT reaction will be triggered

22 s ≤ T_NVCONTACT ≤ 38.5s: T_NVCONTACT reaction can be triggered

-

38.5 s ≤ T_NVCONTACT: T_NVCONTACT reaction should not be triggered.

- In case the RBC systematically sends a General Message upon re-establishment of the connection, the max value of 38.5s is reduced to 34.5s.

<!-- end of page 79 -->
