# **6 CS/PS COMMUNICATION FUNCTIONAL MODULE**

## **6.1 Introduction**

6.1.1.1 This chapter specifies the Communication Functional Module (CFM), its services, and the protocol stack based on circuit switched and packet switched bearer services of GSM/GPRS and fixed networks. The CFM covers the OSI layers 4 (transport layer), 3 (network layer), and 2 (data link layer).

6.1.1.2 Note: The service interface is not mandatory. The service primitives of Annex B describe the interface at a functional level only _._

## **6.2 Service definition**

### **6.2.1 Model of communication services**

6.2.1.1 The communication services that the Communication Functional Module offers to its users (Safe Functional Module and optionally non-safe users) are based on the services provided by the transport layer of ISO/OSI reference model [ITU-T X.214]. These services concern:

   - Transport connection establishment/release;

   - Reliable data transmission;

   - Transparent data transmission.

6.2.1.2 A communication functional module offers also reliability enhancement of the transmission channel.

6.2.1.3 A CFM entity communicates with its users (CFM user<sup>2</sup> ) through one or more Transport Service Access Point (TSAP) by means of transport service primitives. The CFM entities supporting a transport connection exchange Transport Protocol Data Units (TPDU) for normal data use the service of the lower layers, through the respective Service Access Points.

6.2.1.4 For CS mode, more than one transport connection per physical channel can optionally be supported by a CFM. This option is not required for ETCS level 1 radio in-fill unit. Instead, for PS mode, more than one transport connection per physical channel shall always be supported by a CFM.

6.2.1.5 Figure 3 contains a model only. It does not restrict any implementations.

### **6.2.2 Connection establishment**

6.2.2.1 The process of establishing a transport connection is initiated at the time when the communication service user requests a connection set up to the Communication Functional Module. This service is accessed through the service primitive T-CONNECT.request with its associated parameters at the TSAP. At the time of connection set up request, the user

> 2 CFM user is applied to indicate a service user of the CFM. The correct OSI term would be TS user.

<!-- end of page 21 -->

has the possibility to specify its needs by means of QoS class and of the application type to be served.

##### **Figure 3 Model of communication service (CS mode)**

6.2.2.2 The communication functional module evaluates the value of the QoS class and the application type. The associated set of quality of service parameter values will be used:

   - to select the proper bearer service for physical connection establishment, when this connection does not yet exist;

   - optionally, to select the scheduling features of transport layer multiplexing.

   - Note: QoS class will be ignored in case of a PS connection.

### **6.2.3 Data transfer**

6.2.3.1 The data transfer service is provided after a successful transport connection set up. This service is accessed through the service primitive T-DATA.request with its associated parameters at the TSAP. The Communication Functional Module provides transparent and reliable transfer of user data in both directions simultaneously and hides to its users the way in which the data are handled internally.

<!-- end of page 22 -->

### **6.2.4 Connection release**

6.2.4.1 The transport connection release is provided by the Communication Functional Module through the use of the transport service primitive T-DISCONNECT.request, with its associated parameters. The connection release due to the Communication Functional Module, or caused by lower layers, will be indicated to the user.

### **6.2.5 Quality of Service (only for CS mode)**

6.2.5.1 The term Quality of Service (QoS) refers to certain characteristics of a transport connection as observed between the endpoints.

6.2.5.2 The QoS parameters give transport service (TS) users a method of specifying their needs and give the TS provider a basis for selection of the protocol or for requesting services of lower layers. The QoS is normally negotiated between the TS users and the TS provider on a per transport connection basis, using the T-CONNECT request, indication, response, and confirm TS primitives. The negotiated QoS values then apply throughout the lifetime of the transport connection. For the purposes of this FIS for the use in the transport protocol the values for all parameters are fixed for a given application type, in which case QoS negotiation on a per transport connection basis is restricted to local negotiation between the requesting side and its local transport providing entity.

6.2.5.3 There is no guarantee that the originally negotiated QoS will be maintained throughout the transport connection lifetime. The Transport Service provider does not explicitly signal changes in QoS.

6.2.5.4 Possible choices and default values for each parameter will normally be specified at the time of initial TS provider installation.

## **6.3 Communication protocols for CS**

### **6.3.1 Introduction**

6.3.1.1 This section provides a precise specification of the communication protocols of the user channel over CS. The protocol specifications are described layer by layer as delta specifications to existing standards.

### **6.3.2 Data Link Layer**

6.3.2.1 According to the OSI reference model the reliable transfer of data is provided by the data link layer. The data link layer of the B/Bm-channel provides functional and procedural means to establish, maintain, and release connections and to transfer data. It will detect and correct data transfer errors, which may occur in the physical layer.

6.3.2.2 The protocol of layer 2 (DTE-DTE communication) will transmit data according to the sequence of their data request primitives.

6.3.2.3 The layer 2 protocol is covered by the HDLC standards. The application conditions are given as delta specifications.

<!-- end of page 23 -->

6.3.2.4 The frame structure according to [ISO/IEC 3309] and the elements of the control procedures according to [ISO/IEC 4335] shall be used.

6.3.2.5 The HDLC balanced asynchronous class (BAC) of procedures shall be used. The HDLC basic procedure shall provide the following error detection and recovery features:

   - automatic re-transmission after missing acknowledge;

   - 16 bit frame check sequence.

6.3.2.6 Some standardised options of HDLC are required as defined in [ISO/IEC 7809]:

   - option 3.2: multi-selective reject (SREJ);

   - option 10:  extended sequence numbering (SABME);

   - option 15.1:  Start/stop transmission.

Note: Option 8 is not used (see 6.3.2.9).

Note: Option 2 is not used.

6.3.2.7 The elements supporting the procedure and options are described in [ISO/IEC 7776] except for the following rules<sup>3</sup> :

   - a) Only the single link procedure is used.

   - b) An independent HDLC protocol is used in each B/Bm channel.

   - c) An ”unsolicited DM” is not used.

   - d) In the case of FRMR condition link reset shall not be used. The receiver of FRMR shall send a DISC frame as a response (see [ISO/IEC 7776] section 5.6).

   - e) An ”unsolicited UA” response frame” in the information transfer phase is ignored.

   - f) ”Basic mode of operation” is not used.

   - g) Extended sequence numbering (modulo 128) is used.

   - h) The calling system plays the DTE role and the called system plays the DCE role. These roles include the layer 2 addressing. The system initiating the establishment of the B/Bm channel is considered to be the calling system.

   - i) The end system with the DTE role is responsible for the establishment and release of the layer 2 connection. Only the end system with the DTE role is allowed to send SABME frames. However, the other system can also release the connection.

   - j) In the case of ordered release of the connection, the layer 2 connection should be released before the B/Bm channel.

   - k) The interframe time fill-in shall be “Mark”.

   - l) The layer 2 protocol shall not insert any inter-octet time fill-in ([ISO/IEC 4335] §4.1.4.2).

   - m) Only control escape transparency shall be used ([ISO/IEC 7776] §3.5.2.2).

   - n) Receiving a SABME frame before the first I frame is received shall not lead to the link resetting procedure but be handled as an additional attempt to perform link set-up.

3 For further detailed information see Annex D.

<!-- end of page 24 -->

o) Received UI frames shall be ignored.

6.3.2.8 The order of transmitting bits within each octet in the information field is to send the least significant bit first.

6.3.2.9 Response I frames shall be sent only with F=1. Response I frames with F=0 shall not be sent.

6.3.2.10 SREJ shall be sent as response frame only.

### **6.3.3 Network Layer**

#### **6.3.3.1 CS Connection Management Function**

6.3.3.1.1 The CS Connection Management function provides the synchronisation mechanism required between the usage of the B/Bm- channel protocol stack and the signalling protocol stack.

6.3.3.1.2 The following tasks shall be performed by the CS Connection Management function:

   - a) Registration with requested and appropriate GSM.

   - b) Establishment of network connection(s) by means of the 3GPP 27.007 and ETS 300102 signalling protocol (see [ETS 300102-1]).

   - c) Mapping of the requested QoS parameters into signalling information.

   - d) Connection refusal when applicable

   - e) Connection release by means of the 3GPP 27.007 and ETS 300102 signalling protocols

   - f) Handling of the GSM/ISDN supplementary services information.

   - g) Error reporting and retrieving information on error reasons received from 3GPP 27.007 and ETS 300102 signalling protocols.

   - h) disconnect of data link layer followed by release of physical connection in case of disconnect phase (e.g. when the number of retransmission attempts exceeds N2 or in case of FRMR condition detected) (see [ISO/IEC 7776] section 5.3.3, 5.3.4).

6.3.3.1.3 If a B/Bm-channel connection is not already established, the receipt of an N- CONNECT.request primitive shall cause the control plane signalling procedures for circuit switched connection to establish a B/Bmchannel connection. The requested QOS parameters for the N-connection shall be mapped onto user-network signalling information elements.

6.3.3.1.4 During B/Bm- channel connection establishment, supplementary services information and signalling protocol cause codes shall be handled as specified in [GSM/R interfaces].

6.3.3.1.5 Note: A simplified handling of signalling information and error reasons is allowed.

6.3.3.1.6 When the B/Bm- channel connection is established in layer 1, the CS Connection Management  function informs the B/Bm- channel network layer entity and B/Bm- channel data link layer entity. The data link layer entity performs synchronisation with its peer data link layer entity and informs the network layer entity after successful synchronisation.

<!-- end of page 25 -->

6.3.3.1.7 Each EuroRadio has to operate one or more B/Bm-channels with EuroRadio peer. The layer 3 and layer 2 entities are processed independently in each B/Bm- channel.

6.3.3.1.8 When the N-DISCONNECT.request is received, the B/Bm- channel is released by the 3GPP 27.007 and ETS 300102 signalling protocols.

#### **6.3.3.2 B/BmChannel network Layer**

6.3.3.2.1 According to the OSI reference model the network layer of a B/Bm- channel provides functional and procedural means to establish, maintain, and release network connections between open systems containing communicating transport entities independent from routing and relay considerations.

6.3.3.2.2 For Layer 3, the T.70 network layer protocol for CSPDNs shall be used in the B/Bmchannel. Only the T.70 header (refer to [ITU-T T.70] Section 3.3.3 and Figure 4) is applied: Segmentation/re-assembly of the NSDU out of/into sequences of NPDUs and setting of the M-Bit.

6.3.3.2.3 Note: ISDN B-channel circuit switched mode: T.90 specifies in appendix II the T.70 network layer protocol as an optional protocol usable on a per call basis.

<!-- Start of picture text -->
MSB  LSB<br>8  ...  1<br>1  0  0  0  0  0  0  0  1<br>2  M  Q  0  0  0  0  0  0<br>3...n  network user data field<br><!-- End of picture text -->

**Figure 4 Format of NPDU**

6.3.3.2.4 When the more data mark (M) is set to 1 it indicates that more data is to follow. The Q-bit is reserved; currently the value is set to 0.

6.3.3.2.5 Error handling of T.70 header is a matter of implementation.

### **6.3.4 Transport Layer**

#### **6.3.4.1 Functions**

6.3.4.1.1 The transport layer only establishes a transport connection if a network connection exists. If the network connection does not exist at the moment when an association is requested, the transport entity first of all requests the establishment of such a connection and then automatically sets up the transport connection. Each different application type should have established its own transport connection for the intended duration of the communication. TP2 shall be used in order to provide more than one transport connection over the same network connection.

6.3.4.1.2 The layer 4 protocol is covered by [ITU-T X.224] ”Protocol for providing the OSI connection-mode transport service”; the application conditions are given as delta specifications in section 0. The elements of transport procedure class 2 (TP2) listed in

<!-- end of page 26 -->

Table 2 shall be used. Some special problems of the protocol are described in the following sections.

<!-- end of page 27 -->

**Table 2 Procedure elements of TP2**

|**Protocol mechanism**|**X.224**<br>**Cross-**<br>**ref.**|**Variant or Option**|**TP Class 2**|**used**|**not**<br>**used**|
|---|---|---|---|---|---|
|Assignment to network connection|6.1.1||x|*||
|TPDU transfer|6.2||x|*||
|Segmenting and reassembling|6.3||x|*||
|Concatenation and separation|6.4||x||*|
|Connection establishment|6.5||x|*||
|Connection refusal|6.6||x|*||
|Normal release|6.7|Explicit|x|*||
|Error release|6.8||x|*||
|Association of TPDU’s with transport<br>connection|6.9||x|*||
|TPDU numbering|6.10|Normal<br>Extended|m (Note 1)<br>o (Note 1)|*|*|
|Expedited data transfer|6.11|Network Expedited|x (Note 1)||*|
|Reassignment after failure|6.12||na||*|
|Retention and acknowledgement of<br>TPDU’s|6.13|Confirmation of receipt|na||*|
|Re synchronisation|6.14||na||*|
|Multiplexing and de-multiplexing|6.15||x (Note 2)|(Note<br>3)|*|
|Explicit flow control|6.16||m|*||
|Checksum|6.17||x||*|
|Frozen references|6.18||||*|
|Re transmission on time-out|6.19||na||*|
|Resequencing|6.20||na||*|
|Inactivity control|6.21||na||*|
|Treatment of protocol errors|6.22||x|*||
|Splitting and recombining|6.23||||*|
|Notes<br>X     Procedure always included in class<br>na   Not applicable in TP class 2<br>m    Negotiable procedure whose imple<br>o    Negotiable procedure whose implem<br>1     Not applicable in class 2 when non-<br>2     Multiplexing may lead to degradatio<br>has been selected.<br>3     Option. This option is not required f|2<br>mentation in eq<br>entation in eq<br>use of explicit<br>n of the qualit<br>or ETCS level|uipment is mandatory<br>uipment is optional<br>flow control is selected.<br>y of service if the non-use o<br>1 radio in-fill unit.|f explicit flow co|ntrol||

#### **6.3.4.2 Priority handling**

#### 6.3.4.2.1 The priority has to be handled:

- during set-up phase of the physical connection (”eMLPP priority”): The GSM phase 2+ supplementary service ”Enhanced Multi-Level Precedence and Pre-emption service (eMLPP)” [3GPP 22.067] provides different levels of priority for

- EuroRadio FIS – CS/PS Communication Functional Module

<!-- end of page 28 -->

call set-up and for call continuity. The GSM operator allocates set-up classes and pre-emption capabilities to each priority level according to the railway specifications (refer to EIRENE SRS). The priority is requested during set-up of the physical connection by the CS Connection Management function. The priority level 1 (Controlcommand safety) will be used for all application types.

   - by the scheduling algorithm during multiplexing (”transport priority”): A transport priority is defined for the different application types (see section 6.5.3.4.4)

6.3.4.2.2 Note: All priority treatment of the transport layer refers to transport priorities.

6.3.4.2.3 The action taken by the transport protocol during connection lifetime is not explicitly defined in ITU-T X.224.

6.3.4.2.4 The following policy has to be adopted in each CFM at transport connection set-up request:

   - If sufficient resources are available to provide the service (in both the local and distant system) the new connection will be established.

   - Otherwise, the connection request is refused.

6.3.4.2.5 The handling of transport priority during the data phase of the transport connection is specified in the following section.

#### **6.3.4.3 Multiplexing**

6.3.4.3.1 Multiplexing of two or more transport connections onto a single network connection can be provided as an option. This option is not required for ETCS level 1 radio in-fill unit.

6.3.4.3.2 Multiplexing requires the following functions:

   - a) The identification of the transport connection source is provided by an appropriate DST-REF parameter of each DT TPDU and additionally the SRC-REF parameter of CR, CC, DR, and DC TPDUs. These parameters are used to identify each TPDU in a given transport connection and ensures that data from different transport connections are not mixed or mis-routed.

   - b) Peer flow control regulates the rate at which TPDUs of individual transport connections are sent to the peer transport entity. The use of explicit flow control on each transport connection will conform to ITU-T X.224 recommendation sub-section 10.2.4.2 and will be used in addition to any other form of flow control performed in the lower layers.

   - c) The scheduling of the next transport connection to be served over the network connection: The connection associated with application type ATP has to be served first.

   - d) The transport connection endpoint identifier (TCEPID) at the TSAP provides local identification of the transport connection. Service boundary flow control is provided as a matter of implementation. These local flow control mechanisms shall be in accordance to transport priority requests.

<!-- end of page 29 -->

#### **6.3.4.4 Release of the network connection**

6.3.4.4.1 The release of network connection occurs when all the transport connections associated with it have been released.

6.3.4.4.2 In the case of an abnormal release by the network, all associated transport connections are released and the transport service users are immediately informed.

#### **6.3.4.5 Segmenting/reassembling**

6.3.4.5.1 If the size of the transport service data unit (TSDU), which is requested for transmission to the transport layer, exceeds the maximum size of the user data part of the DT TPDU, then segmentation must first be performed on the TSDU. One TSDU is mapped into more than one TPDU with added protocol control information.

6.3.4.5.2 The segmenting/reassembling reduces the throughput because of the increased overhead in the TPDUs. Normal priority user data is segmented, if it does not fit into one TPDU. The recommended length of TSDUs is <= 123 octets.

6.3.4.5.3 The transmitting transport entity should apply the length 128 octets for all TPDUs except the last one.

6.3.4.5.4 The peer transport entity has to identify the transport connection of the received segments and to reassemble the segments into the TSDU.

6.3.4.5.5 The receiving transport entity shall be able to accept TPDUs of different length: from 1 up to 128 octets.

6.3.4.5.6 If one TPDU (which is requested for transmission to the network layer as NSDU) is handled by the network entity, the next TPDU has to wait. Segmenting of long lower priority TSDU provides the possibility to multiplex TPDUs of higher priority with the stream of lower priority TSDU segments.

#### **6.3.4.6 Addressing**

6.3.4.6.1 The ConnectRequest TPDU (CR TPDU) and the ConnectConfirm TPDU (CC TPDU) contain address information: the calling transport selector, and the called transport selector or the responding transport selector in the respective TSAP IDs. The transport selector consists of the sub-parameters application type, ETCS ID type and ETCS ID (Figure 5 and Table 3).

6.3.4.6.2 Note: The parameter code and length shown in Figure 5 indicate the structure according to X.224 section 13.3.4

|Parameter|Parameter|Application|ETCS ID|ETCS ID|
|---|---|---|---|---|
|code|length|type|type||
|(1 octet)|(1 octet)|(1 octet)|(1 octet)|(3 octets)|

**Figure 5 Structure of the transport selector**

6.3.4.6.3 The first octet of the transport selector is used for the assignment of the application type (Table 3). The first 5 bits specify the main application type. The minor application types specify the main application types in more details. Every main application type can comprise eight applications. The general structure of the parameter ”application type” is:

<!-- end of page 30 -->

application type (1 octet) = main application type (5 bits)

   - + minor application type(3 bits)

6.3.4.6.4 The application type of calling and called transport selectors has to be identical. If the called CFM does not support a requested application type, the establishment request will be rejected by DR TPDU.

**Table 3 Format and encoding of transport selector**

|**Octet**|Bit<br>`8765`|`4321`|**Content**|
|---|---|---|---|
|1|`1100`<br>`1100`|`0001`<br>`0010`|Parameter code of calling TSAP or<br>Parameter code of called TSAP|
|2|`0000`|`0101`|Parameter length (fixed length=5)|
|3|`xxxx`|`xxxx`|Application type<sup>1</sup>|
||`0001`<br>`0001`<br>`0001`<br>`0001`|`0xxx`<br>`0000`<br>`0001`<br>`0111`|ATP<br>ERTMS/ETCS level 2<br>ERTMS/ETCS level 1<br>National use<sup>2</sup>|
||`0001`<br>`0001`|`1xxx`<br>`1010`|National use for trackside equipment<br>RBC-Interlocking communication|
||`0001`|`1011`|RBC-RBC communication|
||`0001`|`1100`|Interlocking-Interlocking communication|
||`0010`|`0xxx`|Key management|
||`0010`|`0000`|KMC/KMC communication|
||`0010`|`0001`|KM domain internal communication|
||`0011`|`000x`|ATO communication|
||`0011`|`0000`|ATO/ATO communication|
||`0011`|`0001`|ATO domain internal communication|
||`1111`|`1111`|Reserved for error handling|
|4|`0000`|`0000`|ETCS ID type<br>Radio in-fill unit|
||`0000`|`0001`|RBC|
||`0000`<br>`0000`|`0010`<br>`0011`|Engine<br>Reserved for Balise|
||`0000`<br>`0000`<br>`0000`<br>`0000`|`0100`<br>`0101`<br>`0110`<br>`1000`|Reserved for Field element (eg, Level crossing)<br>Key management entity<br>Interlocking related entity<br>ATO-TS|
||`0000`|`1001`|ATO-OB|
||`1111`|`1111`|Unknown<sup>3</sup>|
|5-7|||ETCS ID|

Note:

1. Application type ATP is mandatory. All other application type values are reserved.

2. Minor application type “National use” is reserved for non-interoperable national applications.

3. Can only be used together with an ETCS ID value “unknown”.

<!-- end of page 31 -->

### **6.3.5 Applicability conditions of [ITU-T X.224]**

**Table 4 Applicability conditions of [ITU-T X.224]**

|**Section**|**Application conditions**|
|---|---|
|Introduction|These application conditions only apply for the EuroRadio specification.|
|§ 1|Transport procedure class 2 (TP class 2) for the connection-oriented data transfer shall be<br>used. All other TP classes of X.224 shall not be used.<br>”Conformance testing” shall not be used.|
|§ 4.2|ED, EA, and RJ TPDU shall not be used.|
|§ 5.1|The communication services are specified in section 6.1.1.1.<br>Tab.1/X.224 shall not be used.|
|§ 5.2|The network service used is a ”connection oriented network service(CONS)”. The parameter<br>exchange between the transport entity and the network service provider is implementation<br>dependent. The network service primitives according to X.213 should be used.<br>The following applies for Tab.2a/X.224, if used:<br>•<br>N-DATA-ACKNOWLEDGE primitives shall not be used.<br>•<br>N-EXPEDITED-DATA primitives shall not be used. With N-CONNECT primitives, ”receipt<br>confirmation option”, ”expedited data option” and ”NS user data” shall not be used.<br>•<br>With N-DISCONNECT primitives, ”NS user data” shall not be used.<br>•<br>N-UNITDATA shall not be used.<br>•<br>Tab. 2b/X.224 shall not be used.|
|§ 5.3.1|The future functions ”encryption”, ”accounting mechanisms”, ”status exchange”, ”blocking”,<br>”temporary release of network connections”, and ”alternative checksum algorithm” shall not be<br>used.<br>”Monitoring of QoS” shall not be used.|
|§ 5.3.1.1|c) ”error detection” shall not be used.<br>d) ”error recovery” shall not be used.|
|§ 5.3.1.2|b)<br>All transport connections from trainborne transport layer entity to the same trackside layer<br>entity and vice versa are multiplexed onto one network connection. <sup>4</sup>(Option)<br>c) The default size of the TPDU shall be 128 octets.<br>e)<br>The called network address, if provided, shall be used as network address. If this network<br>address is not provided by T-CONNECT.request, the ETCS IDs have to be mapped <sup>5</sup>.<br>f) A TCEPID should be used to distinguish between transport connections.<br>g) ”TS user data” can be used.<br>h) ”inactivity timers” shall not be used.|
|§ 5.3.1.3|a) ”concatenation and separation” shall not be used.<br>c) ”splitting and recombining” shall not be used.<br>f) ”expedited data” shall not be used.|
|§ 5.4.1|TP class 2 shall be used.|
|§ 5.4.2|The TP class cannot be negotiated. The accepted class and its options must be equal to the<br>required class 2.|
|§ 5.4.3|A network connection of Type A is a precondition.|
|§ 5.4.4|TP class 0 shall not be used.|
|§ 5.4.5|TP class 1 shall not be used.|
|§ 5.4.6.2|”Explicit flow control” shall be used.|
|§ 5.4.7|TP class 3 shall not be used.|
|§ 5.4.8|TP class 4 shall not be used.|

4Refer to section 6.3.4.3

5Refer to section 6.5.1

<!-- end of page 32 -->

|**Section**|**Application conditions**|
|---|---|
|§ 5.5|TP class 4 with ”connectionless-mode network service (CNLS)” shall not be used.|
|§ 6.1.1.3|All transport connections between the same pair of transport layer entities are multiplexed onto<br>one network connection.<sup>6</sup>(Option)<br>Procedures for ”re-synchronisation”, ”reassignment after failure” and ”splitting” shall not be<br>used.<br>Note 3: The value of the appropriate delay should be 0s. <sup>7</sup><br>Note 4: shall not be used.<br>Note 5: shall not be used.|
|§ 6.1.2|”connectionless-mode network service” shall not be used.|
|§ 6.2.2|N-EXPEDITED-DATA and N-UNITDATA primitives shall not be used.|
|§ 6.2.3|”connectionless-mode network service” shall not be used.<br>The network expedited variant shall not be used.|
|§ 6.4|”concatenation and separation” shall not be used.|
|§ 6.5.2|N-UNITDATA primitives shall not be used.|
|§ 6.5.3|The following TPDU parameters shall not be used:<br>•<br>use of extended format;<br>•<br>version number;<br>•<br>protection;<br>•<br>checksum;<br>•<br>additional option selection;<br>•<br>alternate protocol classes;<br>•<br>acknowledge time;<br>•<br>inactivity time;<br>•<br>residual error rate;<br>•<br>reassignment time;<br>•<br>Option “non-use of explicit flow control in class 2”.<br>The following TPDU parameters should not be used:<br>•<br>TPDU size (proposed and selected);<br>•<br>preferred maximum TPDU size (proposed and selected).<br>If these parameters are used, the receiver shall ignore them.|

6Refer to section 6.3.4.3

> 7Refer to section 6.3.4.4

<!-- end of page 33 -->

|**Section**|**Application conditions**|
|---|---|
|§ 6.5.4|Transport connections are only established by the initiator of the network connection.<br>Optionally, the responder can try to establish a transport connection. If it cannot be negotiated<br>with peer transport layer entity or peer TS user, the transport connection establishment request<br>will be rejected.<br>”splitting and recombining” shall not be used.<br>The timer TS1 is a matter of local implementation.<br>The network expedited variant shall not be used.<br>a) A TCEPID should be used as a reference.<br>c) ”initial credit” equals to 15 for transport connections with application type ATP; ”initial credit”<br>equals to 1 for all other transport connections (if option ”Multiplexing” is used).<br>e) ”acknowledge time” shall not be used.<br>f) ”checksum” shall not be used.<br>g) ”protection” shall not be used.<br>h) ”inactivity time” shall not be used.<br>o) Option “non-use of explicit flow control in class 2” shall not be used.<br>The following parameters shall not be negotiated:<br>i) ”Protocol class” shall be always 2; ”alternative class” shall not be used.<br>Table 3/X.224 shall not be used. The following parameters shall not be negotiated:<br>j) The default size of the TPDU shall be 128 octets. This shall be maximum size usable.<br>k) ”Preferred maximum TPDU size” should not be used.<br>l) ”extended format” shall not be used.<br>m) ”checksum” shall not be used.<br>n) The parameter value of ”priority” shall be set according to the value of transport priority <sup>8</sup>.<br>p) ”network receipt confirmation” and ”network expedited data transfer” shall not be used.<br>q) ”transport expedited data transfer” shall not be used.<br>r) ”use of selective acknowledgement” shall not be used.<br>s) ”use of request acknowledgement” shall not be used.<br>t) ”version number” shall not be used.<br>u) ”reassignment time parameter” shall not be used.|
|§ 6.5.5|”connectionless-mode network service” shall not be used.|
|§ 6.6|The required class and options must be accepted.|
|§ 6.7.1|The explicit ”release procedure” shall be used. <sup>9</sup>|
|§ 6.7.1.4|The implicit ”release procedure” shall not be used. If the network connection is interrupted, an<br>error indication should be given to the application.|
|§ 6.7.1.5|The orderly release of the transport connection requires the availability of the network<br>connection.<br>The release may result in discarding of TPDUs.<br>Note 5: a network connection shall be immediately released in order when all transport<br>connections multiplexed onto the network connection have been released.<br>Note 6: The timer TS2 is a matter of local implementation.|
|§6.7.2|”connectionless-mode network service” shall not be used.|
|§ 6.8|”Error release” shall be used.<br>On receipt of N-RESET.indication a N-DISCONNECT.request has to be issued.|
|§ 6.9.1.2|N-EXPEDITED-DATA primitives shall not be used.|
|§ 6.9.1.4.2|f) Add: The DST-REF parameter shall be mapped onto the local ”transport connection endpoint<br>identifier (TCEPID)”.|
|§ 6.9.2|”connectionless-mode network service” shall not be used.|
|§ 6.11|”expedited data transfer” shall not be used.|

8Refer to section 6.5.3.4.4

9Refer to 6.3.4.4

<!-- end of page 34 -->

|**Section**|**Application conditions**|
|---|---|
|§ 6.12|”reassignment after failure” shall not be used.|
|§ 6.13|”retention and acknowledgement of TPDUs” shall not be used.|
|§ 6.14|”re-synchronisation” shall not be used.|
|§ 6.15|Details of multiplexing are specified in section 6.3.4.3.|
|§ 6.15.2|ED, EA, and RJ TPDUs shall not be used.|
|§ 6.15.3|Note 2: ”concatenation” shall not be used.|
|§ 6.16|Explicit flow control shall be used.|
|§ 6.17|”checksum” shall not be used.|
|§ 6.18|”frozen reference” shall not be used.|
|§ 6.19|”re transmission on time-out” shall not be used.|
|§ 6.20|”resequencing” shall not be used.|
|§ 6.21|”inactivity control” shall not be used.|
|§ 6.22.2|”connectionless-mode network service” shall not be used.|
|§ 6.23|”splitting and combining” shall not be used.|
|§ 7|Tab.6/X.224 shall not be used. Refer to Table 2.|
|§ 8|TP class 0 shall not be used.|
|§ 9|TP class 1 shall not be used.|
|§ 10.2.1|d) ”concatenation and separation” shall not be used.<br>f) ”multiplexing and de-multiplexing” are used.|
|§ 10.2.3|Data transfer without flow control shall not be used.|
|§ 10.2.4.1|”segmenting and reassembling” are used.|
|§ 10.2.4.3|”Expedited data transfer” shall not be used.|
|§ 11|TP class 3 shall not be used.|
|§ 12|TP class 4 shall not be used.|
|§ 13.1|Table 8/X.224: ED, EA and RJ TPDUs shall not be used.|
|§ 13.3.3|b) ”initial credit” equals 15 for transport connections with application type ATP ”initial credit”<br>equals to 1 for all other transport connections (if option ”Multiplexing” is used).<br>e) TP class 2;<br>Options:<br>”use of normal format in all classes”<br>”use of explicit flow control in class 2”.|
|§ 13.3.4|The following parameters shall be used in the variable part:<br>a) TSAP-IDs are used. The parameter length shall be equal to 5. The parameter value contains<br>the respective transport selector <sup>10</sup>.<br>l) ”Priority” shall be used. The parameter value shall be set according to the value of transport<br>priority<sup>11</sup>.|
|§ 13.5.4|The variable part of the DR TPDU should not be used.|
|§ 13.7.1|”extended format” shall not be used.|
|§ 13.7.4|The variable part shall not be used.|
|§ 13.8|ED TPDUs shall not be used.|
|§ 13.9.1|”extended format” shall not be used.|

10Refer to section 6.3.4.6

11Refer to section 6.5.3.4.4

<!-- end of page 35 -->

|**Section**|**Application conditions**|
|---|---|
|§ 13.9.4|The variable part shall not be used.|
|§ 13.10|EA TPDUs shall not be used.|
|§ 13.11|RJ TPDUs shall not be used.|
|§ 14|”Conformance” with ITU-T Rec. X.224 shall not be required.|
|Annex A|TP class 0, 1, 3 and 4 and ”connectionless mode network service” shall not be used.|
|Annex B|The ”network connection management sub protocol(NCMS)” shall not be used.|
|Annex C|”Conformance” with ITU-T Rec. X.224 shall not be required.|
|Annex D|”checksum” shall not be used.|
|Annex E|shall not be used.|

### **6.3.6 Time sequences**

6.3.6.1 The time sequences are shown in the appropriate OSI layer service definition standards (e.g. for layer 4 refer to [ITU-T X.214]). This chapter illustrates the interaction of the layers.

6.3.6.2 Figure 6 contains the connection establishment by trainborne EuroRadio only. The signalling connection between EuroRadio and the Mobile Termination is established after “power-on” of the Mobile Termination to provide the radio resources and mobility management.

<!-- end of page 36 -->

<!-- Start of picture text -->
Layer 4 Layer 3 Layer 2<br>T-CONN.req<br>(user data) GSM 07.07 Signaling<br>N-CONN.req<br> +CBST=<m> D<number><br>CONNECT<br>Bm channel<br>DL-CONN.req<br>SABME<br>UA<br>DL-CONN_conf<br>N-CONN.conf<br>CR TPDU<br>N-DATA.req<br>(CR TPDU) DL-DATA.req<br>(1.segment) I( 1.segment)<br>...<br>DL-DATA.req ...<br>(n.segment) I( n.segment)<br><!-- End of picture text -->

**Figure 6 Detailed protocol sequence during connection establishment (requesting side only)**

6.3.6.3 Note: The lower part of Figure 6 shows the segmentation of the CR TPDU as an example of a TPDU size > 123 octets.

<!-- end of page 37 -->

<!-- Start of picture text -->
Layer 4 Layer 3 Layer 2<br>T-DATA.req DT TPDU<br>N-DATA.req<br>(DT TPDU) DL-DATA.req<br>(1.segment)... I( 1.segment)<br>DL-DATA.req ...<br>(n.segment) I( n.segment)<br><!-- End of picture text -->

**Figure 7 Detailed protocol sequence during data transfer (requesting side only)**

<!-- Start of picture text -->
Layer 4 Layer 3 Layer 2<br>T-DISC.req DR TPDU<br>N-DATA.req<br>(DR TPDU) DL-DATA.req<br>(1.segment)... I( 1.segment)<br>DL-DATA.req ...<br>(n.segment) I( n.segment)<br><!-- End of picture text -->

**Figure 8 Detailed protocol sequence during connection release (requesting side only)**

### **6.3.7 Relationships of PDUs and SDUs**

6.3.7.1 This chapter contains examples of layer overheads based on a 25 octet data field in HDLC frames.

6.3.7.2 The safety layer (as described in [Subset-037-2]), if applied, adds a header and the MAC to the user data.

6.3.7.3 Transport connections are multiplexed on one network connection according to their transport priority. The layer 4 adds a header to the user data.

6.3.7.4 If the TS user provides a normal priority TSDU of appropriate length (<=123 octets), the layer 4 does not segment/reassemble the user data (Figure 9). Segmenting and reassembling in layer 3 results in a 2 byte segment header.

6.3.7.5 In the case of a non-safe connection Figure 9 is still valid, but without the second line (SaPDU).

<!-- end of page 38 -->

<!-- Start of picture text -->
header application info<br>Application PDU<br>MAC<br>header User data <=114 octets Length in octets<br>SaPDU<br>1 8<br>header<br>TPDU ...<br>5<br>header first segment header last segment<br>NPDU<br>2 32 2 <= 32<br>flag address control data FCS flag The trailer flag is required,<br>HDLC frame if the next frame does not<br>1 1 2 <=34 2 1<br>immediately follow.<br><!-- End of picture text -->

**Figure 9 Example of segmenting/reassembling in layer 3**

6.3.7.6 If the TS user did not provide a normal priority TSDU of appropriate length, the layer 4 segments/reassembles the user data into/from TPDUs of standard length of 128 octets. Segmenting and reassembling in layer 4 will result in a 5 byte header added to each segment (Figure 10). The layer 3 header is additionally required to be consistent with the NPDU format of the other connections.

<!-- end of page 39 -->

<!-- Start of picture text -->
Application PDU header application info<br>header MAC<br>user data > 114 octets<br>SaPDU<br>1 8<br>TSDU<br>header first segment header last segment<br>TPDU<br>5 123 octets 5 <=123<br>header first segment header last segment<br>NPDU<br>2 <=2332 2 <= 32<br>flag address control data FCS flag<br>HDLC frame<br>1 1 2 <=34  2 1<br><!-- End of picture text -->

**Figure 10 Example of segmenting/reassembling in layer 4 and layer 3**

## **6.4 Communication protocols for PS**

### **6.4.1 Introduction**

6.4.1.1 This section provides a precise specification of the communication protocols of the user channel over PS. The protocol specifications are described layer by layer. Table 5 shows the delta to existing standards.

Note: The word PS used in this specification refers to Packet Switched communication over GSM-R, i.e., GPRS. Packet Switched communication via FRMCS is specified in Subset037-3.

6.4.1.2 An APN shall be provided that is dedicated to ETCS traffic.

6.4.1.3 One dedicated PDP context ID for ETCS purposes shall be subscribed to each MT.

6.4.1.4 Only mobile initiated PDP context activations shall be supported for ETCS.

6.4.1.5 A PDP context shall be deactivated only by the OBU.

### **6.4.2 Adaptation Layer Entity (ALE)**

### **6.4.2.1 Functions**

<!-- end of page 40 -->

6.4.2.1.1 The main functions of ALE are:

   - a) Adaptation between EuroRadio Safety Layer and TCP layer.

   - b) Establishment and Release of the TCP connection.

   - c) Conversion between Safety Layer packets to/from TCP stream.

   - d) Monitoring of channel availability.

6.4.2.1.2 All the above ALE functions are based on [Subset-098] (RBC-RBC Safe Communication Interface), using the requirements specified in Table 5. The paragraphs below explain the adaptation of Subset-098 for on-board to trackside safe communication.

**Table 5. Applicability conditions of Subset-098**

|**Section**|**Application conditions**|
|---|---|
|§ 1<br>Modification<br>History|Not relevant.|
|§ 2 Table of<br>Contents|Not relevant.|
|§ 3 introduction|Not relevant.|
|§ 4 Reference<br>architecture|Not relevant.|
|§ 5 Safe<br>Functional<br>Module|Not relevant.|
|§ 6<br>Communication<br>Functional<br>Module|All applicable except for the following rows of this table.|
|§ 6.1 General|Not relevant, however not only RBC-RBC Safe Communication Interface, but generic on-board<br>and trackside equipment.|
|§ 6.2.1.1.1|Systems are assumed both fixed and mobile.|
|§ 6.2.1.1.2|Physical redundancy not supported on OBU side.|
|§ 6.3.1.1.1|Running not only on ground based systems.|
|§ 6.3.1.1.4|The diagram in figure 28 shows an example for a fixed connection, not over GSM-R (GPRS).|
|§ 6.3.2.1.3|Only Class D.|
|§ 6.3.2.1.4|One single physical link only, with only one TCP connection, no redundancy used.|
|§ 6.3.3 Class A<br>request|Not relevant.|
|§ 6.3.4.1.1|A request for a Class D quality of service shall result in the Adaptation Layer attempting to<br>make only one TCP connections to the remote Adaptation Layer entity. This connection shall<br>be used to transfer all data and control messages. The safe connection shall operate only on<br>this link. The exact details of how this link shall be monitored and managed are contained in<br>§6.6.|
|§ 6.4.1.1.3|Managing of the redundancy is not applicable.|
|§ 6.5.2.1.1|Transport priority is not used.|
|§ 6.5.2.2.1|Specified in chapter 6.4.2.3.|
|§ 6.5.2.5.4|TCP_LISTEN_ON_PORT specified in 6.4.2.4.1|
|§ 6.5.2.6.1|Every connection between two subsystems is realised through only one transport connection.|
|§ 6.6.1 Class A<br>(optional for|Not relevant.|

<!-- end of page 41 -->

|**Section**|**Application conditions**|
|---|---|
|implementation<br>)||
|<br>§ 6.6.2|Class D is used.<br>One single physical link only, with only one TCP connection, no redundancy used.|
|§ 6.8|Specified in chapter 6.4.3|
|§ 6.8.3.1.2|IP v4 is mandatory,|
|§ 6.9.3.1.1|Specified in chapter 6.4.2.3.|
|§ 7<br>INFORMATIVE<br>ANNEX|Not relevant.|

#### **6.4.2.2 Redundancy of the ALE Server physical interfaces**

6.4.2.2.1 The communication between OBU and RBC is realised by ALE client (on-board) / server (trackside).

6.4.2.2.2 The ALE Server (trackside) may have several physical interfaces, but only one IP address is responded to an ALE Client (on-board) by a DNS response, subsequent to a DNS query of the ALE Client during connection establishment. The process how the ALE Client manages the IP address of the server is a matter of implementation.

#### **6.4.2.3 Addressing**

6.4.2.3.1 Dynamic IP address allocation shall be used for the ALE client (on-board) and the IP address is obtained during the PDP context activation (see Figure 11).

6.4.2.3.2 Instead, the ALE server (trackside) IP address shall be permanent.

6.4.2.3.3 If the optional parameter Network Address does not contain an IP address in the T- CONNECT.request primitive a DNS query shall be used to resolve IP address.

6.4.2.3.4 To translate the ETCS id of the ALE server a DNS lookup shall be used.

6.4.2.3.5 The format of the string (host name) sent to the DNS shall be: “id<ETCS ID>.ty<ETCS-ID Type>.etcs”, using lowercase hexadecimal ASCII character representation of the <ETCS ID> and <ETCS-ID Type>. Example: If the ETCS id type is RBC and the ETCS ID is ‘1001 0011 1100 0000 1111 0101, the formatted string will be ‘id93c0f5.ty01.etcs’. See also [Subset-037-2].

6.4.2.3.6 The DNS feature shall comply with [RFC 1034 ] and [RFC 1035].

6.4.2.3.7 A (logical) ETCS DNS lookup shall be split in separate requests, sent simultaneously, each only querying for a single record (QCOUNT=1); i.e. the request for IP address and TXT field shall be performed by two separate DNS requests. This applies to all ETCS DNS lookup attempts referred throughout Subset-037-1 specification.

6.4.2.3.8 A DNS response can contain more than one TXT record in random order. Among the received TXT records, one single record shall contain the format “txm=” and, if applicable, “tp=” which are both reserved for ER. This TXT record shall be identified by syntax check in the OBU.

#### **6.4.2.4 Listening port**

<!-- end of page 42 -->

6.4.2.4.1 The listening TCP port is 7911.

Note: The use of this port is for private networks only.

#### **6.4.2.5 Connection Monitoring**

6.4.2.5.1 Standard TCP Keep Alive shall be used, together with other TCP parameters and features, see Table 6.

#### **6.4.2.6 Connection Management functions**

6.4.2.6.1 The Connection Management function manages the AT-command interface and the switching between the control plane (command state) and the user plane (data state).

6.4.2.6.2 The following tasks are performed by the Connection Management function:

   - a) Registration with requested and appropriate GSM (same for CS and PS)

   - b) Connection refusal in case of an error

   - c) Error reporting and retrieving information on error reasons

   - d) Check GPRS attach status and attach if not already attached

   - e) Check PDP context activation and activate PDP context if not already active

   - f) Change the interface state to MT into on-line data state before connection establishment.

   - g) Change the interface state to MT into AT command state after release of all transport connections associated with the specific MT.

   - h) Establish the PPP and extract the ETCS DNS IP address.

   - i) Association of a MT with a requested transport connection.

6.4.2.6.3 In case a new PS mode connection is requested within the same network of an already established one (e.g. RBC handover within the same network), the same MT as for the already established connection shall be used.

### **6.4.3 TCP Layer**

6.4.3.1 The transport layer protocol is TCP [RFC 793].

6.4.3.2 In the following Table 6, Mandatory (M) and Optional (O) TCP Features are specified from ETCS operation point of view.

6.4.3.3 To reach an equivalent performance to CS mode, the TCP parameters shall be optimized to detect a communication loss in 13 s. For justification see ANNEX I.

6.4.3.4 The values of some TCP Parameters can be proposed in the DNS TXT field, see 6.5.2.4, but the applicability of such proposed values is optional, depending on the implementation.

6.4.3.5 Whether a parameter is configurable per connection or not depends on the Linux TCP implementation point of view. Other implementations or newer Linux implementations could have other restrictions or parameters.

**Table 6. Applicability conditions of TCP**

|**Feature**|**RFC**|**M/O**|**Value**|**Comments**|
|---|---|---|---|---|
|1<br>Initial RTO|793|M|>= TCP_RTO_MIN|Also known as “TCP_timeout_init”|

<!-- end of page 43 -->

||**Feature**|**RFC**|**M/O**|**Value**|**Comments**|
|---|---|---|---|---|---|
|||1122||< TCP_RTO_MAX<br>(Recommended: =<br>TCP_RTO_MIN)|_Note: not configurable per connection_|
|2|Minimum Retransmission Timeout|793<br>1122|M|1-5s<br>(Recommended: 3<br>s)|TCP_RTO_MIN: The RTO is not allowed to<br>be lower than this value<br>_Note: not configurable per connection_|
|3|Maximum Retransmission Timeout|793<br>1122|M|>=5s<br>(Recommended: 5<br>s)|TCP_RTO_MAX: Should be set to a value<br>that defines the maximum allowed time<br>before a forced retransmission<br>_Note: not configurable per connection_|
|4|Karn and Jacobson's algorithm,<br>with exponential back-off|1122|M|Used|Standard TCP feature to compute RTO<br>_Note: not configurable per connection_|
|6|TcpMaxConnectRetransmissions|793<br>1122|M|3|Number of SYN-packet retries; also known<br>as “TCP_SYN_retries”<br>_Note: not configurable per connection_|
|7|TcpMaxDataRetransmissions|793<br>1122.|M|1-5<br>(Recommended: 2)|Also known as “TCP_retries2”<br>_Note: not configurable per connection_<br>The detection time range is<br>(1+TcpMaxDataRetransmissions) *<br>[TCP_RTO_MIN, TCP_RTO_MAX], i.e. for<br>recommended values [9,15] s.|
|8|TcpKeepAliveTime|793<br>1122|M|10-20 s<br>(Recommended:<br>10 s)|The interval to wait before probing the idle<br>connection<br>_Note: configurable per connection_|
|9|TcpKeepAliveInterval|793<br>1122|M|2-5 s<br>(Recommended: 2<br>s)|The interval to wait before retrying the<br>probe after an initial failure to respond:<br>_Note: configurable per connection_|
|10|TcpKeepAliveProbes|793<br>1122|M|2-4<br>(Recommended: 2)|The maximum number of times to retry the<br>probe<br>_Note: configurable per connection_<br>_Note 2: Expected disconnect time for_<br>_recommended value is TcpKeepAliveTime_<br>_+_<br>_TcpKeepAliveInterval*TcpKeepAliveProbes_<br>_= 14s_|
|11|TcpUserTimeout|793|O|>=10<br>(Recommended:<br>11 s)|The TCP user timeout controls how long<br>transmitted data may remain<br>unacknowledged before a connection is<br>forcefully closed.<br>It is checked during RTO update.<br>The detection time range is<br>[TcpUserTimeout , TcpUserTimeout +<br>min(TcpUserTimeout, TCP_RTO_MAX)],<br>i.e. for recommended values [11,16] s.<br>_Note: configurable per connection_<br>_Note 2: the recommended value of 11 is_<br>_chosen in order to cover delays in relation_<br>_of RTO timeout._|
|12|TcpSack|2018<br>2883|M|enabled|Selective Acknowledgement<br>_Note: not configurable per connection_|
|13|TcpTimestamps|7323|M|disabled|_Note: not configurable per connection_|
|14|TcpNoDelay|1122<br>6633|M|enabled|Disables Nagel’s algorithm which<br>concatenates small messages before<br>sending them|

<!-- end of page 44 -->

||**Feature**|**RFC**|**M/O**|**Value**|**Comments**|
|---|---|---|---|---|---|
||||||_Note: configurable per connection at API_<br>_level but the changing configuration is_<br>_intentionally not supported by the DNS_<br>_TXT field_|
|15|TCP Push Bit|793|M|enabled|Force the processing of the receiver buffer<br>_Note: not configurable per connection_|
|16|Max TCP segment size|793|M|<= 1416<br>(Recommended: =<br>1416)|Maximum value is MTU - sizeof(max TCP<br>Header) - sizeof(max IP Header)<br>Where guaranteed MTU=1500 byte,<br>sizeof(max TCP Header)=60 byte,<br>sizeof(max IP Header) = 24 byte<br>_Note: configurable per connection_|
|17|TcpEarlyRetrans|5827|M|<=2<br>(Recommended: 0)|Controls the mode of retransmissions in<br>certain widely available TCP<br>implementation. Should not be used for<br>EuroRadio. Note: not configurable per<br>connection.|

### **6.4.4 Network Layer**

6.4.4.1 The network layer protocol is IPv4 [RFC 791].

### **6.4.5 Data Link Layer**

6.4.5.1 These interfaces, like PPP or Ethernet, are specified in the [EuroRadio FFFIS]

### **6.4.6 Time sequences**

6.4.6.1 The time sequences are shown for the sublayers of the protocol stack which are applied on top of GPRS.

6.4.6.2 Figure 11 contains the signalling flow for PS service setup (see also ANNEX G), applicable at OBU side only. This signalling flow is necessary in the following cases:

   - after initialization of the Mobile Termination to provide the radio resources and mobility management.

   - on explicit request from the application (i.e. border crossing).

   - following loss of radio coverage.

6.4.6.3 Network registration shall be performed followed by:

   - on all mobiles: a single attempt of GPRS attachment (+CGATT) with timeout of 5 s;

- on one mobile: a single attempt of PDP context activation (+CGACT) with timeout of 3s.

6.4.6.4 The successful network registration shall be reported to the application, even in case of GPRS attachment (+CGATT) and/or PDP context activation failure, which shall then be continuously monitored on one mobile by a polling task in the following conditions:

   - Start the polling on all MT’s, successfully registered on a network, not associated to transport connections and in command state, otherwise don’t poll.

   - Every predefined polling period (max 10s), perform GPRS attachment (+CGATT) and PDP context activation (+CGACT).

      - © _This document has been developed and released by UNISIG_

EuroRadio FIS – CS/PS Communication Functional Module

<!-- end of page 45 -->

   - As soon as successful/unsuccessful PS status is received form the MT, the PS status is changed accordingly.

   - When the polling period expires, if there is no PS status received from the MT, the PS status is not updated and the ongoing GPRS attachment (+CGATT) and PDP context activation (+CGACT) shall be aborted and restarted.

   - If the association of the MT with a transport connection is requested by an application while polling is ongoing, the polling shall be aborted anytime, and the status of PS shall be the last known one (successful or unsuccessful).

   - The polling procedure is managed independently on all MTs.

6.4.6.5 Figure 12 contains the connection establishment (OBU side only) protocol sequence.

6.4.6.6 Figure 13 contains the detailed protocol sequence during data transfer.

6.4.6.7 Figure 14 contains the detailed protocol sequence for connection release.

6.4.6.8 Note: the exchange of AU3 and AR SaPDUs are out of scope for transport connection establishment.

6.4.6.9 Note: the AT commands shown in the pictures are specified in the [EuroRadio FFFIS].

<!-- end of page 46 -->

<!-- Start of picture text -->
OBU MT<br>OBU-AP OBU-ER<br>SFM CFM<br>+CGREG  Set  initial  conditions<br>(reporting etc)<br>T-REGISTR.req<br>Registration  request<br>+COPS<br>  MNID<br>Network Registration<br>OK<br>+CGREG:2,1<br>Registered to status<br>+CGATT  GPRS activation  request<br>OK<br>GPRS attach<br>+CGDCONT<br>OK<br>+CGEQREQ  PDP context activation<br>(see ANNEX G)<br>OK<br>+CGACT<br>OK<br>T-REGISTR.ind<br>MNID<br>timeout<br>timeout<br><!-- End of picture text -->

**Figure 11 Time sequence “Network registration and PS service setup” (OBU side only)**

<!-- end of page 47 -->

<!-- Start of picture text -->
Layer 4  Layer 3<br>Coordinating  ALE  TCP  Coord.<br>function sublayer function<br>3GPP 27.007 Signalling<br>T-CONN.req<br>AU1 SaPDU<br>Check PS status.<br>If not OK, see ANNEX G<br>+CGDATA<br>Enter data<br>state<br>Establish PPP stack<br>OBU IP address<br>OBU IP address<br>DNS IP address  DNS IP address<br>ETCS DNS queries for RBC IP address and TXT field<br>DNS<br>server<br>RBC IP address and TXT field<br>TCP_<br>Open_Port<br>3 way handshaking<br>TCP_<br>Connected<br>TCP_<br>Send_Data<br>TCP segment  (AU1 ALEPKT (AU1 SaPDU))<br>AU1<br>TCP_<br>TCP segment  (AU2 ALEPKT (AU2 SaPDU))<br>DataReady<br>TCP_<br>T-CONN.<br>ReadData<br>confirm<br>AU2<br>AU2<br><!-- End of picture text -->

**Figure 12 Time sequence “Connection establishment” (OBU side only)**

<!-- end of page 48 -->

<!-- Start of picture text -->
Layer 4<br>Layer 4<br>Coordinating  ALE  TCP  TCP  ALE<br>function sublayer sublayer<br>DT SaPDU<br>T-DATA.req<br>TCP_<br>Send_Data<br>DT SaPDU<br>TCP<br>segment<br>TCP_<br>DT<br>Data_Ready<br>ALEPKT<br>(DT ALEPKT)<br>TCP_<br>Read_Data<br>T-DATA.ind<br>DT<br>ALEPKT<br>DT SaPDU<br><!-- End of picture text -->

**Figure 13 Time sequence “Data Transfer”**

<!-- end of page 49 -->

<!-- Start of picture text -->
Layer 4  Layer 4<br>Coordinating  ALE  TCP  TCP  ALE<br>function sublayer sublayer<br>DI SaPDU<br>T-DISC.req<br>TCP_<br>DI SaPDU  Send_Data<br>TCP<br>DI ALEPKT  segment<br>TCP_<br>Data_Ready<br>(DI ALEPKT)<br>TCP_<br>Read_Data<br>DI ALEPKT<br>TCP_Close<br>Normal TCP<br>closing<br>TCP_Close<br>T-DISC.ind<br>DI SaPDU<br><!-- End of picture text -->

**Figure 14 Time sequence “Connection Release”**

### **6.4.7 Relationship of PDUs**

6.4.7.1 This section contains examples of layer overheads of the protocol stack based on top of GPRS.

6.4.7.2 The safety layer adds a header and the MAC to the user data.

6.4.7.3 The ALE sublayer adds a 10 octet header (or more, if Packet Type equals 1 or 2) to the user data.

6.4.7.4 The transport layer adds a 24 octet header (or more) to the user data.

6.4.7.5 The IP layer adds a 20 or 24 octet header to the user data.

6.4.7.6 Neither the ALE sublayer nor the transport layer segment/reassemble the user data.

<!-- end of page 50 -->

<!-- Start of picture text -->
Application PDU  Application data<br>Header  User data   MAC<br>SaPDU<br>1  <= 1023  8<br>Header<br>ALEPKT<br>10<br>Header<br>TCP segment<br>>=20<br>Header<br>IP packet<br>20 or 24<br>Length in octets<br><!-- End of picture text -->

**Figure 15 Relation between PDUs**

## **6.5 Management of Communication Functional Module**

### **6.5.1 Connection Handling for GSM-R services**

6.5.1.1 The CFM has to establish the connections according to the Transmission Mode Table between peer applications (i.e. CFM users). The details of the following tasks are a matter of implementation.

6.5.1.2 The communication functional module optionally offers several logical connections between the trackside and the on-board equipment via the same physical channel. This option is not required for ETCS level 1 radio in-fill unit. See 6.2.1.4.

6.5.1.3 The ”transport address” is a generic name that is used to identify a set of transport service access points (TSAPs) which are all located at the interface between a higher layer and the transport layer of the CFM. If a generic name is used to denote an object, then exactly one member of the set of objects will be selected.

6.5.1.4 The transport address is used to access a single transport service (TS) user entity. The network address by itself is not sufficient to identify a particular CFM user entity. It is

<!-- end of page 51 -->

necessary to refer to the requested CFM user entity type by using a special identifier or address qualifier: the application type.

<!-- Start of picture text -->
External ATP<br>address info (calling CFM user ) ATP<br>Other  (called CFM user)<br>CFM user<br>CdA = ETCS ID type, ETCS ID<br>appl.type=ATP<br>SaSAP SaSAP<br>Safety layer Safety layer<br>Safety  Safety<br>entity entity<br>CdA = ETCS ID type, ETCS ID<br>appl.type=ATP Applic. type = ... Applic. type = ATP<br>T S AP T SAP T S AP TS A P<br>Transport layer Transport layer<br>CR TPDU<br>Address Transport Transport<br>mapping entity CdA = entity<br>(application type,<br>CdA = E.164-No. ETCS ID type,<br>N S AP NSAP ETCS ID) NSAP NSAP<br>Network layer Network layer<br>Address<br>adaptation<br>07.07 dial string<br>MT2<br>CdA = E.164-No.<br>Network<br><!-- End of picture text -->

**Figure 16 Example of address mapping**

6.5.1.5 Transport layer entities and CFM user entities are bound together at TSAPs. Every CFM user entity may be bound to one or more TSAPs. This is a matter of implementation. There is no relationship between TSAPs and multiplexing. The multiplexed transport connections may terminate at different TSAPs.

6.5.1.6 The addresses are used in the T-CONNECT primitives (transport address) and N- CONNECT-primitives (network address) at the service interface. If a CFM user entity (e.g. the safety layer entity) wants to establish a connection with another CFM user entity, it provides information to address the called CFM user (e.g. an ETCS ID type and ETCS ID) and the application type. This address information has to be mapped into the format and structure requested by the CFM for connection establishment.

6.5.1.7 Figure 16 gives an example of address information mappings during the connection establishment from trainborne CFM to trackside CFM. The calling TS user entity (i.e. in this example the safety layer entity) obtains the called transport address from the application (ETCS ID type and ETCS ID). The address information will be passed through the SFM towards the CFM.

6.5.1.8 The calling CFM has the following tasks:

<!-- end of page 52 -->

   - To check, that a Mobile Termination is registered with the mobile network contained in the T-CONNECT.request;

   - In PS mode, to check that the MT is attached to the mobile network contained in the T-CONNECT.request and to attach the MT if necessary;

   - In PS mode, to activate the PDP context activation if not yet active;

   - In PS mode, to activate PPP supervised with ppp_activation_timeout (see 6.5.3.3.3);

   - To associate the requested connection with an appropriate Mobile Termination;

   - To derive the called network address from address information indicating the called CFM user;

   - To insert into the connection request (CR) TPDU the called transport selector (in the case of train initiated physical connection establishment according to Figure 5) and the calling transport selector;

   - To select the local NSAP by which the network service primitives (if applicable) is issued.

   - After the PS service setup is successful (see ANNEX G), to perform independent simultaneous ETCS DNS queries for A and TXT field,  repeatedly with an interval of _dns_lookup_reptime_ for max. _dns_lookup_time_ (see 6.5.3.3.2), using the ETCS ID type and ETCS ID contained in the received T-CONNECT.request.

6.5.1.9 Note: The details of local call and ID management (e.g. address mapping) are out of scope for this FIS.

6.5.1.10 Table 7 Address information (train-initiated call set-up)shows the defined combinations of address information values.

**Table 7 Address information (train-initiated call set-up)**

|**ETCS ID**<br>**type**|**ETCS ID**|**Network address**|**Action**|**Remarks**|
|---|---|---|---|---|
|RBC|RBC ID|RBC network address<br>provided|CS mode: use network address,<br>update the transmission mode via<br>the other MT if possible<br>PS mode: retrieve IP address from<br>DNS||
|RBC|RBC ID|Network address not<br>provided or<br>Default value ”NA<br>unknown”|CS mode: use short dialling code<br>“Most appropriate RBC”, update the<br>transmission tode via the other MT if<br>possible<br>PS mode: retrieve IP address from<br>DNS|Short dialling code<br>15xx [EIRENE SRS]|
|“unknown”|Default value<br>”ETCS ID<br>unknown”|Network address not<br>provided or<br>Default value ”NA<br>unknown”|CS mode: use short dialling code<br>”Most appropriate RBC”, NO update<br>of the transmission mode via the<br>other MT<br>PS mode: cannot be used|Default for<br>addressing in CS|

<!-- end of page 53 -->

|**ETCS ID**<br>**type**|**ETCS ID**|**Network address**|**Action**|**Remarks**|
|---|---|---|---|---|
|“unknown”|Default value<br>”ETCS ID<br>unknown”|RBC network address<br>provided|CS/PS mode: use network address|PS mode: not used<br>for ETCS<br>applications|

6.5.1.11 The ConnectRequest TPDU (CR TPDU) and the ConnectConfirm TPDU (CC TPDU) contain the calling and the called transport selectors in the format specified for the TPDUs (see section 6.3.4.6).

6.5.1.12 In CS mode the trackside called network address will be a generic address to identify a set of network service access points (NSAPs), which are bound to the ”Primary rate access” (ISDN-like networks). The called network number should be a ”hunting number”: incoming calls to the network number will be distributed by the terminating exchange (or the PABX) among a group of interfaces. One of the idle interfaces will be selected to receive the call.

6.5.1.13 In PS mode the trackside called network address will be an IP address identifying the peer RBC.

6.5.1.14 The trackside sets of TSAPs are bound to special CFM user entities (e.g. in Figure 16 the safety layer entity is bound to a special TSAP). The CFM user entity A is bound to a TSAP but actually not used (maybe it is a non-safe application layer entity, which has to use another TSAP and application type).

6.5.1.15 The transport layer entity in the called CFM uses:

   - the address information contained in the connection request (CR) TPDU to derive the called ETCS ID type and ETCS ID and to select one appropriate TSAP (based on the application type received);

   - the responding ETCS ID type and ETCS ID contained in the T-CONNECT.response primitive to build the connection confirm (CC) TPDU.

6.5.1.16 If the transport layer entity of the called side is not able to select a TSAP bound with the requested application type, the CR TPDU will be rejected.

### **6.5.2 DNS Record TXT Field**

6.5.2.1 The DNS Record TXT field in scope of EuroRadio is a semicolon separated and ended list of uniquely named, by equal sign, comma separated lists containing unique strings including empty strings. Characters are ASCII. E.g. "txm=cs;foo=bla;tp=blub,,b;".

6.5.2.2 Transmission mode PS will be indicated by an IP address in the A field of the DNS record.

6.5.2.3 If no PS mode will be supported by the RBC other supported RBC EuroRadio transmission modes are indicated by the “txm” named list of the DNS record’s TXT field. Indicate able transmission modes are:

   - CS by the string “cs” contained in the txm list

Future releases might support additional transmission modes.

Note: To force the fallback to CS mode for an RBC, no A record should be contained within the respective DNS response (but only the TXT field with “txm=cs”).

<!-- end of page 54 -->

6.5.2.4 Suggested specific transmission protocol parameters are indicated by the “tp” named list of the DNS record’s TXT field. Each entry of this list matches, in order, to a transport parameter as per Table 6 which is commented as “configurable per connection”. I.e. for “tp=<p1>,<p2>,<p3>,<p4>,<p5>;” the following correspondence holds:

   - <p1> : TcpKeepAliveTime

   - <p2> : TcpKeepAliveInterval

   - <p3> : TcpKeepAliveProbes

   - <p4> : TcpUserTimeout

   - <p5> : Max TCP segment size.

Omitting the setting of a parameter is indicated by an empty string at the corresponding list position. The strings are to be interpreted as of the intended value’s unit (e.g. the <p1> parameter represents seconds, the <p3> parameter represents “count”).

Numbers are decimals represented as strings, i.e. “580” for the decimal number 580.

In the following cases, the suggested parameters shall not apply at all:

- In case of definition range mismatch between any single parameter with its general value range as per Table 6 “Value” column

- In case of expected parameter count mismatch

The use of a suggested parameter is mandatory unless it is not settable in the used TCP implementation.

### **6.5.3 Configuration management**

6.5.3.1 The local O&M stack provides an initial set of configuration parameters, which are to be set as follows.

#### **6.5.3.2 Configuration parameters for CS mode**

**Table 8 Layer 2 configuration parameters for CS mode**

|**Parameter**|**Symbol**|**Interoperability**<br>**relevant**|**Recommended**<br>**value (if not**<br>**interoperability**<br>**relevant)**|**Mandatory value (if**<br>**interoperability**<br>**relevant)**|**Comments**|
|---|---|---|---|---|---|
|Address|||A, B|Calling entity: A<br>Called entity: B||
|Maximum number of bits in<br>an I frame|N1|Yes||240 ≤ N1(Tx) ≤ 1024<br>N1(Rx)=1024|Parameter k and N1 can<br>be different in both<br>|
|Window size|k|Yes||(Because Tx side can<br>use N1(Tx)=1024 as a<br>maximum)<br>𝑘=<br>𝑋∗2 ∗𝑇𝐹<br>(𝑁1 + 16) ∗1.25<br>+ 2|directions.<br>Flags are not included<br>As a consequence of the<br>max value for N1(Tx),<br>receive buffers have to<br>support N1 =1024.|
|||||k(Rx) = 17<br>(Because Tx side can<br>use N1(Tx)=240 as a<br>minimum)<br>e.g.:|In the Rx side, the values<br>are fixed to their<br>maximum.<br>Recommended value for<br>transmission N1 = 312|

<!-- end of page 55 -->

|**Parameter**|**Symbol**|**Interoperability**<br>**relevant**|**Recommended**<br>**value (if not**<br>**interoperability**<br>**relevant)**|**Mandatory value (if**<br>**interoperability**<br>**relevant)**|**Comments**|
|---|---|---|---|---|---|
|||||N1(Tx)=312<br>k(Tx)=14|(This is equal to 4 frames<br>per 1 TPDU)<br>(see ANNEX E,<br>consideration 1)|
|Acknowledge time|T1|Yes||T1=1.5 s|See ANNEX E,<br>consideration 2|
|Local processing delay time|T2|Yes||< 80 ms|Implementation<br>dependent|
|Out of service time|T3|No|T3 >> T4||Matter of implementation<br>(to be used only if T4 is<br>supported)|
|Inactivity time|T4|No|T4=2 s||Matter of implementation<br>(see ANNEX F,<br>consideration 3)|
|Maximum number of<br>retransmission attempts|N2|Yes||4|Note: ISO/IEC 7776<br>specifies the number of<br>transmissions = N2+1<br>(see ANNEX E,<br>consideration 4)|
|Error detection and<br>correction||||FCS-16|No options|

6.5.3.2.1 Interoperability relevant parameter values according to Table 8 are mandatory; noninteroperability relevant parameters can be used for tuning the HDLC.

6.5.3.2.2 The description of the layer 2 configuration parameters for CS mode is provided by [ISO/IEC 7776] section 5.7.

6.5.3.2.3 Timer T5 shall not be used.

6.5.3.2.4 The description of the layer 3 configuration parameters for CS mode is provided in [ITU-T T.70].

**Table 9 Layer 3 configuration parameters for CS mode**

|**Parameter**|**Symbol**|**Range of**<br>**values**|**Applied value**|**Comments**|
|---|---|---|---|---|
|Maximum number of<br>|NL3seg||NL3seg=(N1/8)-5|The layer 3 header is included.|
|octets in a segment||||NL3segis related to the layer 2 frame length N1|

6.5.3.2.5 The description of the layer 4 configuration parameters for CS mode is provided by [ITUT X.224].

##### **Table 10 Layer 4 configuration parameters for CS mode**

|**Parameter**|**Symbol**|**Range of values**|**Applied value**|**Comments**|
|---|---|---|---|---|
|TP class|TP x||TP 2|No choice|
|Procedure elements||||Refer to Table 2|
|Standard TPDU length|NTPDU|1 - 128 octets|128 octets||
|Initial credit|NTIC|1 – 15|15|Application type = ATP|

EuroRadio FIS – CS/PS Communication Functional Module

<!-- end of page 56 -->

|**Parameter**|**Symbol**|**Range of values**|**Applied value**|**Comments**|
|---|---|---|---|---|
||||1|All other optional application types|

#### **6.5.3.3 Configuration parameters for PS mode**

6.5.3.3.1 TCP Configuration Parameters

6.5.3.3.1.1 Refer to see Table 6. Applicability conditions of TCP for the values to be set to the TCP parameters.

6.5.3.3.2 ETCS DNS query Configuration Parameters

6.5.3.3.2.1 The dns_lookup_timeout parameter shall be set to 5 sec.

6.5.3.3.2.2 The _dns_lookup_reptime_ parameter shall be set to 1s.

6.5.3.3.3 PPP Activation parameter

6.5.3.3.3.1 The _ppp_activation_timeout_ parameter shall be set to 2 sec.

#### **6.5.3.4 QoS parameters**

6.5.3.4.1 Normally, the QoS parameters give CFM users a method of specifying their needs and give the CFM a basis for selection of the protocol or for requesting services of lower layers. For the purposes of this FIS sets of QoS parameters values are specified.

6.5.3.4.2 Each value of service primitive parameter **QoS class** is associated with a set of QoS parameter values, which represents the requirements to the physical connection to be established. The requirements are independent from application type.

6.5.3.4.3 Only for CS mode, the default value for the QoS parameter **User data rate** is 4800 bit/s. For PS mode it is not used.

6.5.3.4.4 The range of QoS parameter **Transport priority** is 0-5. Table 11 contains the association with application types.

**Table 11 Transport priority**

|**Value**|**Associated application type**|**Comments**|
|---|---|---|
|0|-|Not used|
|1|Application type ATP|Highest value used|
|All other values ar|e reserved.||

6.5.3.4.5 Only for CS mode, QoS classes 0-9 are reserved for application type ATP of ERTMS/ETCS. The data rate and eMLPP priority (refer to section 6.3.4.2) parameters have to be used during physical connection set-up. For PS mode it is not used.

##### **Table 12 Mapping of QoS classes 0-9**

|**QoS class**|**Service**|**Nominal bit rate**<br>**[bit/s]**|**eMLPP priority**|
|---|---|---|---|
|1|CS|4 800|1|
||All other QoS class|values are reserved for fut|ure use.|

<!-- end of page 57 -->

### **6.5.4 Supervision / Diagnostics**

#### **6.5.4.1 Error handling**

6.5.4.1.1 If an error occurs in the communication functional module or if the communication functional module receives an indication of an error, the error and its reason will be indicated. The different reasons require different error handling actions. The errors can be ignored, locally logged or indicated.

6.5.4.1.2 If there is a problem with call establishment, the CFM should try by itself to recover the problem. Only if the problem cannot be solved, (i.e. the transport connection cannot be established), will the CFM inform the CFM user.

**Table 13 Error types of the CFM and their handling**

|**Reason/ code**||**Sub-reasons**|**Error handling action**|
|---|---|---|---|
|Network error<br>Code =1|1<br>2<br>3|Number not assigned; invalid number<br>format<br>Channel unacceptable<br>Impossibility to establish physical<br>connection for other reason<br>(e.g. V.25ter response No<br>DIALTONE)|Indication of a persistent error is created by the<br>provider and is contained in the reason<br>parameter of the T-DISCONNECT.indication|
|Network resource not<br>available<br>Code=2|1<br>2<br>3|No channel available<br>Network congestion<br>Other sub-reason<br>(e.g. V.25ter responseNO CARRIER)|Indication of a transient error is created by the<br>provider and is contained in the reason<br>parameter of the T-DISCONNECT.indication|
|Service or option is<br>temporarily not<br>available|1<br>2|QoS not available<br>Bearer capability not available|Indication of a transient error is created by the<br>provider and is contained in the reason<br>parameter of the T-DISCONNECT.indication|
|Code=3||||
|Reason unknown<br>Code =5|||Error indication is created by the called<br>communication functional module and is<br>contained in the reason parameter of the T-<br>DISCONNECT.indication.|
|Called TS user not<br>available<br>Code =6|1<br>2<br>3|Application of requested type is not<br>supported<br>Called user unknown<br>(e.g. V.25ter response NO ANSWER)<br>Called user not available<br>(e.g. V.25ter responseBUSY)|Error indication is created by the called<br>communication functional module and is<br>contained in the user data of the DR TPDU. The<br>calling CFM will report the error to the calling<br>application with the T-DISCONNECT.indication|
|Internal error<br>Code =7|1<br>2<br>3|Mandatory element<sup>12</sup>is missing (e.g.<br>element of a TS primitive)<br>Inappropriate state<br>Other sub-reasons<br>(e.g. V.25ter responseERROR)|Error logging<br>Deletion of the invalid message|
|mobile registration<br>error<br>Code=8<br>Notes:|1|No Mobile Termination has been<br>registered|T-DISCONNECT.indication<br>The application should re-try network<br>registration|

1. All other reason/sub-reason values are reserved.

2. Reasons and sub-reasons are a matter of implementation. 3. Reason Code 0 is reserved for normal release requested by a CFM user.

#### **6.5.4.2 Error reporting**

12 Caused by  the local application

<!-- end of page 58 -->

6.5.4.2.1 The safety functional module and/or the applications are informed about error situations that lead to a disconnection by using the T-DISCONNECT indication service primitive.

**Table 14 Parameter of the T-DISCONNECT Primitive and their contents**

|**Parameter of the T-DISCONNECT Primitive**|**Contents**|
|---|---|
|Reason|TS user invoked / TS provider invoked<br>In the case of TS provider disconnection:<br>error type/sub-reason (see Table 13)|
|User data|User data of the DISCONNECT request of the remote TS<br>user (internal information from the remote TS user)|

#### **6.5.4.3 Error logging**

6.5.4.3.1  Error logging is a matter of the implementation.

## **6.6 Resource Management for on-board IP communication applications**

6.6.1.1 Communication resources not currently used by ETCS may be used by other on-board applications for IP communication.

6.6.1.2 The use of communication resources is managed according to the priority of the application. Assigned resources may therefore be revoked if an application with higher priority requests communication resources.

6.6.1.3 Three service primitives are provided:

   - **Rm-SERVICE.request**

User request for communication resources.

- **Rm-SERVICE.release**

Release of communication resources by user or by resource manager.

- **Rm-SERVICE.indication**

Result from a request for communication resources.

**Table 15 Service primitives of the Resource Management**

|**Primitive**<br>**Parameter**|**Rm-SERVICE.**<br>**request**|**Rm-SERVICE.**<br>**indication**|**Rm-SERVICE.**<br>**release**|
|---|---|---|---|
|Application Type|X|||
|Service ID||X|X|
|Reason||X||
|Sub-reason||X||

6.6.1.4 The request for communication resources is made by using the **Rm-SERVICE.request** primitive. The parameter Application Type is supplied by the user. The resource manager

<!-- end of page 59 -->

will use this parameter to set the priority of the application and to assign APN and radio network quality of service parameters as specified in the table below.

6.6.1.5 Supported application types are listed in the following table.

**Table 16 Application Types supported by the Resource Management**

|**Application**|**Application Type**|**APN**|**QoS**|
|---|---|---|---|
|Key Management|KMS|kms<br>_Note: The APN will_<br>_be extended by the_<br>_network_<br>_by_<br>_MNC_<br>_and MCC according_<br>_to [EIRENE SRS]_|As configured in APN,<br>so ‘AT+CGEQREQ’,<br>as in G.3.1.2, is not<br>necessary|
|Automatic Train<br>Operation|ATO|ato<br>_Note: Functional_<br>_name, will be_<br>_managed by the_<br>_network_|FFS|

6.6.1.6 At reception of Rm-SERVICE.request the resource manager will perform the following:

   - Check if communication resources are available or that it is possible to revoke resources from an application with lower priority.

   - If not already done, attach to GPRS, activate PDP context according to the application type and start the PPP protocol.

   - Indicate the result to the user.

6.6.1.7 The result of a request of communication resources is sent to the user in the **RmSERVICE.indication** primitive. A Service ID is assigned and the outcome is indicated by the parameters Reason and Sub-reason.

**Table 17 Successful Resource Management request**

|**Reason**|**Sub-**|**Description**|
|---|---|---|
|**Code**|**reason**||
||**Code**||
|0||Communication resources are assigned to the user.<br>The communication resource is identified by parameter Service ID.|

##### **Table 18 Sub-reasons for the reason NOT-Successful Resource Management request**

|**Reason**<br>**Code**|**Sub-**<br>**reason**<br>**Code**|**Description**|
|---|---|---|
|1|1|Packet switched communication is not supported by network|
||2|Communication resources are not available|
||3|Network error|

<!-- end of page 60 -->

|**Reason**|**Sub-**||**Description**|
|---|---|---|---|
|**Code**|**reason**|||
||**Code**|||
||4|Other fault||

6.6.1.8 The parameter Service ID is a local identification of the communication resource.

6.6.1.9 A normal release of a communication resource is initiated by the user with the **RmSERVICE.release** primitive.

6.6.1.10 Revocation of a communication resource is initiated by the resource manager with the **RmSERVICE.release** primitive, as a result of another application with higher priority requesting communication resources or any network or equipment issue.

<!-- end of page 61 -->
