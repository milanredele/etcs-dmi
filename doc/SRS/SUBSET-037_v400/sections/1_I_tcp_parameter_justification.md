# **ANNEX I. TCP PARAMETER JUSTIFICATION**

I.1.1.1 This Annex is included to clarify following values:

I.1.1.2 There are some dependencies for choosing the TCP parameters. The following considerations are valid for ETCS data links. For other links the values can be calculated equivalent.

I.1.1.3 Consideration 1:

Transmission errors over on the air interface will be detected and corrected by the E- GPRS protocol layers but cause a significant delay of such frames. To avoid unnecessary retransmissions RTO min. should be greater than the expected transmission delay for the longest user packet (see SUBSET-093).

Minimum Retransmission Timeout = 3 s

I.1.1.4 Consideration 2:

To allow a reestablishment after a connection loss a tuning of the detection of connection loss will be needed. According to the values in Table 8 the detection time should exceed about 13 s to have an equivalent behaviour as in CS mode. This could be reached by:

#### TcpMaxDataRetransmissions = 2

Maximum Retransmission Timeout = 5 s

TcpUserTimeout = 11 s

|Time [s]|Action|RTO|
|---|---|---|
|0|Transmission|3|
|3|First Retransmission|5|
|8|Second Retransmission|5|
|13|Loss Detection||

I.1.1.5 Consideration 3:

Starting in 2013 new mechanisms for throughput optimisation were implemented in the standard TCP implementations, what is in contradiction to the requirement of loss detection. This optimization should be switched off:

#### TcpEarlyRetrans = 0

I.1.1.6 In the following table, a representation of the T_NVCONTACT computation is given assuming a general message interval of 4 s and a position report interval of 4 s:

<!-- end of page 88 -->

**Table 28: T_NVCONTACT computation PS**

||**min.**<br>**[s]**|**max.**<br>**[s]**||
|---|---|---|---|
|time up to last triggering<br>T_NVCONTACT|0||General Message receiving parallel to<br>sending the interfere Position Report|
|||10|General Message 5s before<br>interference, Position Report/ACK in<br>front|
|Transmission/retransmission|13|13|TcpMaxDataRetransmission = 2<br>Maximum Retransmission Timeout = 5|
|New communication<br>Establishment|5|5|Free mobile should be available with<br>high probability in PS mode|
|Protocol establishment|4|4|By experience|
|New message available for<br>transmission|0|5|No sync between session re-<br>establishment and General Message*|
|Transmission of the|1||Transmit General Message|
|message||1,5|Transmit MA|
||**23**|**38,5**||

- T_NVCONTACT < 23 s: T_NVCONTACT reaction will be triggered.

23 s ≤ T_NVCONTACT ≤ 38.5 s: T_NVCONTACT reaction can be triggered.

38.5 s ≤ T_NVCONTACT: TNVCONTACT reaction should not be triggered.

* In case the RBC systematically sends a General Message upon reestablishment of the connection, the max value of 38.5 s is reduced to 33.5 s.

<!-- end of page 89 -->
