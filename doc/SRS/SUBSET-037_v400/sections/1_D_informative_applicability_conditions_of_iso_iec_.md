# **ANNEX D. (INFORMATIVE) APPLICABILITY CONDITIONS OF ISO/IEC 7776 (1995)**

D.1.1.1 Notes:

1. Only DTE to remote DTE will be considered since this is the case applicable to EuroRadio.

2. “Not applicable” means this case is not possible for EuroRadio.

3. “shall be used” and  “shall not be used” indicate the application conditions for EuroRadio.

4. “Optional” means this feature can be implemented or not; if implemented it shall be compliant with the specification.

|**Section**<br>Foreword|**Application conditions**<br>Annex A (conformance) shall not be used|
|---|---|
|Introduction|"Protocol Implementation Conformance Statement" shall not be used|
|§ 1 Scope|Shall be used<br>Only the following features/options shall be used<br>•<br>DTE/DTE communication<br>•<br>Start/Stop transmission<br>•<br>Extended (mod 128) operation<br>•<br>Single link procedure<br>Bilateral agreements means: “General agreement for all EuroRadio<br>implementations is made by this application conditions”<br>Clause 7 (conformance) shall not be used|
|§ 2 Normative references|Shall be used<br>ISO/IEC 7478, X.25, ISO/IEC 9646-1,2:1994 ISO/IEC 646 are not applicable|
|§ 3 Frame structure|Shall be used. Table 1 (modulo 8) shall not be used.|
|§ 3.1 Flag sequence|Shall be used.|
|§3.2 Address field|Shall be used.|
|§ 3.3 Control field|Shall be used. Basic (modulo 8) operation shall not be used.|
|§3.4 Information field|Shall be used.|
|§ 3.5.1<br>Transparency Synchronous<br>transmission|Not Applicable.|
|§ 3.5.2<br>Transparency Start/stop<br>transmission|Shall be used. Control-escape transparency only shall be used.|
|§3.5.2.1<br>Seven-bit data path<br>transparency|Shall not be used.|
|§ 3.5.2.2<br>Control-escape<br>transparency|Shall be used.|
|§ 3.5.2.3<br>Extended transparency|Shall not be used.|
|§ 3.5.2.3.1|Shall not be used.|
|Flow-control transparency||

EuroRadio FIS – CS/PS Communication Functional Module

<!-- end of page 73 -->

|**Section**|**Application conditions**|
|---|---|
|§ 3.5.2.3.2<br>Control-character octet<br>transparency|Shall not be used.|
|§ 3.6 Frame check<br>sequence (FCS) field|Shall be used.|
|§ 3.7.1<br>Order of bit transmission|Shall be used.<br>The order of transmitting bits within each octet in the information field is to send<br>the least significant bit first.|
|§ 3.7.2<br>Start/stop transmission|Shall be used.|
|§ 3.8.1<br>Invalid frames Synchronous<br>transmission|Not Applicable.|
|§ 3.8.2<br>Invalid frames Start/stop<br>transmission|Shall be used.|
|§ 3.9.1<br>Frame abortion<br>Synchronous transmission|Not Applicable.|
|§ 3.9.2|Shall be used.|
|Frame abortion Start/stop<br>transmission||
|§ 3.10.1<br>Interframe time fill<br>Synchronous transmission|Not Applicable.|
|§ 3.10.2<br>Interframe time fill<br>Start/stop transmission|Shall be used. Flags shall not be used as interframe time fill. [FIS 8.2.2.7l)]|
|§ 3.11.1|Not Applicable.|
|Data link channel states<br>Synchronous transmission||
|§ 3.11.2.1<br>Data link channel states<br>Start/stop transmission<br>Active channel state|Channel state shall not be used. Flags shall not be used as interframe time fill in.<br>[FIS 8.2.2.7l)].|
|§ 3.11.2.2<br>Data link channel states<br>Start/stop transmission Idle<br>channel state|Channel state shall not be used. Timer T5 shall not be used.|
|§ 4.1.1<br>Control field formats|Shall be used. Table 3 (Modulo 8 operation) shall not be used.|
|§ 4.1.1.1<br>Information transfer format<br>⎯I|Shall be used.|
|§ 4.1.1.2|Shall be used.|
|Supervisory format⎯S||
|§ 4.1.1.3|Shall be used.|
|Unnumbered format⎯U||
|§ 4.1.2.1<br>Modulus|Shall be used. Modulo 8 shall not be used.|
|§ 4.1.2.2.1<br>Send state variable V(S)|Shall be used.|

EuroRadio FIS – CS/PS Communication Functional Module

<!-- end of page 74 -->

|**Section**|**Application conditions**|
|---|---|
|§ 4.1.2.2.2<br>Send sequence number<br>N(S)|Shall be used.|
|§ 4.1.2.2.3<br>Receive state variable V(R)|Shall be used.|
|§ 4.1.2.2.4<br>Receive sequence number<br>N(R)|Shall be used.|
|§ 4.1.2.2.5<br>Poll/Final bit P/F|Shall be used.|
|§ 4.2 Functions of the<br>poll/final bit|Shall be used.|
|§ 4.3 Commands and<br>responses|Shall be used. Table 5 (Modulo 8) shall not be used.<br>Table 6 (modulo 128): response I frames shall be accepted only with F=1<br>Supervisory frame REJ shall not be used.<br>Supervisory frame SREJ shall be used as response frame only.<br>Unnumbered information frame UI shall not be used.|
|§ 4.3.1<br>Information (I) command|Shall be used.|
|§ 4.3.2<br>Receive ready (RR)<br>command and response|Shall be used.|
|§ 4.3.3<br>Receive not ready (RNR)<br>command and response|Shall be used.|
|§ 4.3.4<br>Reject (REJ) command and<br>response|Shall not be used.|
|§ 4.3.5<br>Set asynchronous balanced<br>mode (SABM)<br>command/Set<br>asynchronous balanced<br>mode extended (SABME)<br>command|Shall be used. SABME only shall be used.|
|§ 4.3.6 Disconnect (DISC)<br>command|Shall be used.|
|§ 4.3.7 Unnumbered<br>acknowledgement (UA)<br>response|Shall be used.|
|§ 4.3.8<br>Disconnected mode (DM)<br>response|Shall be used. An ”unsolicited DM” shall not be used. [FIS 8.2.2.7d)]|
|§ 4.3.9 Frame reject<br>(FRMR) response|Shall be used.<br>REJ and UI shall be identified as “not implemented”.<br>SREJ shall be identified as “implemented”.<br>Table 7 (modulo 8) shall not be used.|
|§ 4.4.1 Busy condition|Shall be used.|
|§ 4.4.2 N(S) sequence<br>error|Shall be used_._<br>The first sentence (The information field….shall be discarded) shall not be used.<br>The last sentence shall be used only for the means specified in 4.4.2.1<br>(Checkpoint recovery) and 4.4.2.3 (Timeout recovery)_._|

<!-- end of page 75 -->

|**Section**|**Application conditions**|
|---|---|
|§ 4.4.2.1|Shall be used.|
|Checkpoint recovery||
|§ 4.4.2.2<br>REJ recovery|Shall not be used. SREJ recovery shall be used instead.|
|§ 4.4.2.3|Shall be used.|
|Time-out recovery||
|§ 4.4.3 Invalid frame<br>condition|Shall be used.|
|§ 4.4.4 Frame rejection<br>condition|Shall be used.<br>In the case of FRMR reject condition; link reset shall not be used. The receiver of<br>FRMR shall send a DISC frame as a response. [FIS 8.2.2.7e)]|
|§ 5.1 Procedure for<br>addressing|Shall be used. Single link operation (SLP) only shall be used.<br>The end system initiating the establishment of the B/Bm channel is considered to<br>be the “calling end system”. The calling end system plays the DTE role and the<br>called system plays the DCE role in respect to addressing. [FIS 8.2.2.7i)]|
|§ 5.2 Procedure for the use<br>of the P/F bit|Shall be used.|
|§ 5.3.1<br>Procedures for link set-up<br>and disconnection<br>Link set-up|Shall be used.<br>The calling end system shall initiate link set-up. [FIS 8.2.2.7j)]<br>SABME only shall be used.<br>The DTE shall never re-initiate link set-up.|
|§ 5.3.2<br>Information transfer phase|Shall be used. Timer T4 is optional.<br>In the information transfer phase a SABME command shall not be sent, because link resetting<br>is not allowed (see §5.3.1).<br>When receiving a SABME command while in the information transfer phase, the DTE shall<br>send a DISC command and then initiate the release of the B/Bm channel.<br>For backward compatibility response I frames shall be accepted with F=1 (see [ISO/IEC 7809]<br>section 5.4.2.1 and 5.4.2.2). [FIS 8.2.2.9].|
|§ 5.3.3 Link disconnection|Shall be used.<br>Receiving of SABME is not applicable.<br>Optionally, the sender of the DISC can initiate the release of the B/Bmchannel.|
|§ 5.3.4 Disconnected phase|Shall be used.<br>Both DTE shall never re-initiate link set-up.<br>The last two clauses shall not be used.|
|§ 5.3.5<br>Collision of unnumbered<br>commands|Not Applicable.|
|§ 5.3.6<br>Collision of DM response<br>with SABM/SABME or DISC<br>command|Not Applicable.<br>An ”unsolicited DM” shall not be used. [FIS 8.2.2.7d)]|
|§ 5.3.7|Not Applicable.|
|<br>Collision of DM responses|<br>An ”unsolicited DM” shall not be used. [FIS 8.2.2.7d)]|
|§ 5.4 Procedures for<br>information transfer|Shall be used. Modulo 8 shall not be used.|
|§ 5.4.1<br>Sending I frames|Shall be used.|
|§ 5.4.2|Shall be used.|
|Receiving an I frame|The acknowledgement of the received I- frame shall be sent as soon as possible,<br>in any case not later than T2.|

<!-- end of page 76 -->

|**Section**|**Application conditions**|
|---|---|
|§ 5.4.3|Shall be used.|
|Reception of invalid frames||
|§ 5.4.4 Reception of out-of-<br>sequence frames|Shall not be used. SREJ recovery action shall be used instead.|
|§ 5.4.5<br>Receiving acknowledgment|Shall be used.|
|§ 5.4.6<br>Receiving a REJ frame|Not Applicable. REJ frame shall not be used.<br>A received REJ shall result in a FRMR.|
|§ 5.4.7|Shall be used.|
|Receiving an RNR frame|REJ shall not be used.|
|§ 5.4.8|Shall be used.|
|DTE busy condition|REJ shall not be used.|
|§ 5.4.9<br>Waiting acknowledgement|Shall be used.<br>REJ shall not be used. SREJ shall be used instead.|
|§ 5.5 Conditions for link<br>resetting or link re-<br>initialization (link set-up)|Shall be used. Link resetting procedures (5.6.1) shall not be used.|
|§ 5.6.1<br>Procedure for link resetting<br>Link reset|Shall not be used.|
|§ 5.6.2|Shall be used.|
|Procedure for link resetting<br>Request for link reset|Link resetting procedures (5.6.1) shall not be used.|
|§ 5.7.1.1 Timer T1|Shall be used.<br>Table 40 ”Layer2 configuration parameters“ contains the value(s).|
|§ 5.7.1.2 Timer T2|Shall be used.|
|§ 5.7.1.3 Timer T3|Optional.|
|§ 5.7.1.4 Parameter T4|Optional.|
|§ 5.7.1.5 Parameter T5|Not Used.|
|§ 5.7.2 Maximum number of<br>transmissions N2|Shall be used.<br>See note in ER FIS §8.3.2.2|
|§ 5.7.3 Maximum number of<br>bits in an I frame N1|Shall be used.|
|§ 5.7.4 Maximum number of<br>outstanding I frames k|Shall be used.|
|§ 6 Multilink procedure|Not Used.|
|§ 7.1 Static Conformance|Conformance to chapter 7 is not required.<br>Subset 092-1 contains the conformance requirements to ER FIS.|
|§ 7.2 Dynamic<br>Conformance<br>Annex B|Conformance to chapter 7 is not required.<br>Subset 092-1 contains the conformance requirements to ER FIS.<br>Informative_._|

<!-- end of page 77 -->
