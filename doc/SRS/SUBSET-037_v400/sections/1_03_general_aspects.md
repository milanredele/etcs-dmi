# **3 GENERAL ASPECTS**

## **3.1 Scope**

3.1.1.1 This FIS is applicable for remote data communication of ERTMS data applications.

3.1.1.2 This document (Subset-037-1) covers the following parts of the FIS EuroRadio,

   - The umbrella of the EuroRadio protocol family, that covers:

      - the communication of safety and non-safety related applications.

      - the communication via GSM-R in CS mode, via GSM-R in PS mode and via FRMCS.

   - The definition of the protocol stacks used for GSM-R CS and GSM-R PS communication for non-safety related applications.

   - The coordinating function to start the correct communication mode depending on the requested remote application.

3.1.1.3 Subset-037-1 does not define:

   - The application functionality and application information flow.

   - The Safety Layer to support safety related applications that is defined in Subset-037-2.

   - CFM for FRMCS that is specified in Subset-037-3.

   - The open networks used.

   - The physical architecture of the radio communication subsystem.

## **3.2 Structure of Subset 037 family**

3.2.1.1 Subset 037 is a family of three documents that describes the EuroRadio protocol stack:

   - Subset-037-1 describes the Communication Functional Module applicable to CS and PS data transmission and the coordinating function responsible to select the proper data transmission system between GSM-R CS, GSM-R PS and FRMCS.

   - Subset-037-2 describes the Safe Functional Module applicable to radio communication systems providing communication services for safety-related application processes using open networks.

   - Subset-037-3 describes the Communication Functional Module applicable to FRMCS.

3.2.1.2 In the Figure 1 is shown the relationship between the three Subsets. Refers to chapter 4 for the details about functions and interfaces.

<!-- end of page 9 -->

<!-- Start of picture text -->
Safety Related  Non-Safety Related<br>Application Application<br>3<br>SFM<br>Subset-037-2<br>2a<br>Coordinating Function<br>Subset-037-1<br>2a 2c<br>CS/PS CFM FRMCS CFM<br>Subset-037-1 Subset-037-3<br>1a<br>1c<br>1b<br><!-- End of picture text -->

**Figure 1 Subset-037 document family**

<!-- end of page 10 -->

## **3.3 Acronyms and abbreviations**

3.3.1.1 For general ERTMS/ETCS terms, definitions and abbreviations refer to [Subset-023]. New terms and abbreviations relevant and used in this FIS are specified here.

|AR|Authentication Response|
|---|---|
|AU1|First Authentication message|
|AU2|Second Authentication message|
|AU3|Third Authentication message|
|BAC|Balanced Asynchronous Class|
|Bm|Full-rate traffic channel|
|CEPID|Connection EndPoint IDentifier|
|CFM|Communication Functional Module|
|CS|Circuit Switched|
|CSPDN|Circuit Switched Public Data Network|
|DA|Destination Address|
|DCE|Data Communication Equipment|
|DI|Disconnect|
|Dm|Control Channel|
|DT|Data|
|DTE|Data Terminal Equipment|
|EF|Elementary File (SIM Card)|
|eMLPP|Enhanced Multi-Level Precedence and Pre-emption|
|ETS|European Telecommunication Standard|
|FRMR|FRaMe Reject|
|FRMCS|Future Railway Mobile Communication System|
|HDLC|High level Data Link Control|
|ID|Identity|
|IEC|International Electrotechnical Commission|
|ISDN|Integrated Services Digital Network|
|ITU|International Telecommunication Union|
|LAPB|Link Access Protocol Balanced|
|m|message|
|MA|Management|
|MNID|MNID list is a list of Mobile Network IDs.|
|MT|Mobile Termination|
|NPDU|Network Protocol Data Unit|

<!-- end of page 11 -->

|NSAP|Network Service Access Point|
|---|---|
|NSDU|Network Service Data Unit|
|NT|Network Termination|
|O&M|Operation and Maintenance|
|OSI|Open System Interconnection|
|PDN|Packet Data Network|
|PDU|Protocol Data Unit|
|PDP|Packet Data Protocol|
|PPP|Point to Point Protocol|
|PS|Packet Switched|
|PSD|Packet Switched Data|
|PSTN|Public Switched Telephone Network|
|QoS|Quality of Service|
|RP|ResPonse|
|RQ|ReQuest|
|RTO|Retransmission TimeOut|
|SA|Source Address|
|SABME|Set Asynchronous Balanced Mode Extended|
|SAP|Service Access Point|
|SaPDU|Safety Protocol Data Unit|
|SFM|Safe Functional Module|
|SREJ|Selective REJect|
|TC|Transport Connection|
|TCEPID|Transport Connection EndPoint IDentifier|
|TP|Transport Protocol|
|TP2|Transport Protocol Class 2|
|TPDU|Transport Protocol Data Unit|
|TS|Transport Service|
|TSAP|Transport Service Access Point|
|TSDU|Transport Service Data Unit|
|UA|Unnumbered Acknowledge|
|UI|Unnumbered Information (HDLC frame)|
|X|Mandatory parameter|
|X(U)|Use of this parameter is a user option|
|X(D)|Use of this parameter is a user option. If not provided, a default value will be used.|

<!-- end of page 12 -->

## **3.4 Definitions**

3.4.1.1 For general ERTMS/ETCS terms, definitions and abbreviations refer to [Subset-023]. New definitions relevant and used in this FIS are specified here.

**Mandatory feature:** The feature has to be provided by on-board and/or trackside equipment where interoperability is required.

**Optional feature/Option:** The feature might be provided or not. If provided, it has to be provided as specified. Optional features are not required. Interoperability between EuroRadio peers providing and not providing the optional feature has to be guaranteed. Otherwise, the option has to be deactivated.

#### **National Add-on:**

The feature is a matter of national railway specification. Interoperability must not be influenced.

#### **CS MODE**

Circuit switched transmission mode uses a dedicated end-to-end transmission resource for each logical connection.

#### **FORM FIT FUNCTIONAL INTERFACE SPECIFICATION (FFFIS)**

A FFFIS is the complete definition of an interface between functional or physical entities. The FFFIS includes:

- FIS,

- Electrical characteristics related to data,

- communication protocol<sup>1</sup> ,

- plug.

The FFFIS guarantees the interoperability but not the exchangeability of physical entities.

#### **FUNCTIONAL INTERFACES SPECIFICATION (FIS)**

A FIS specifies the link between functional modules or between physical entities by:

- The required external data flow,

- The required data characteristics,

- The data range and resolution requirements.

#### **FUNCTIONAL MODULE**

Set of functions contributing to realize the same global task.

#### **MESSAGE AUTHENTICATION CODE (MAC)**

An authenticator which is sent with a message to enable the receiver to detect alterations made to the message since it left the sender and to verify that the source of the message is as claimed. The MAC is a function of the whole message and a secret key.

1Note that 'Communication protocol' is used with different meanings in the EuroRadio FIS and FFFIS:

In the FIS a communication protocol is a protocol between peer entities within different End Systems connected by a network.

In the FFFIS a communication protocol is a protocol between functional modules or physical entities located in the same End System.

<!-- end of page 13 -->

#### **PADDING**

The information used to fill the unused part of a message to fill the block size.

#### **PS MODE**

Packet switched transmission mode shares radio transmission resources between several logical connections.

#### **PS SERVICE SETUP**

GPRS attach followed by PDP context activation, as described in ANNEX G.

#### **PS STATUS**

Status of the PS service setup: it’s successful or OK only if PS service setup is successful.

#### **RADIO COMMUNICATION SYSTEM**

A radio transmission system providing data communication services via open networks. It can be completed by an safety related transmission system to ensure safe data transmission.

#### **TRANSMISSION MODE TABLE**

The Transmission Mode Table contains the transmission mode for each known ETCS ID (i.e. RBC).

## **3.5 References**

3.5.1.1 This FIS incorporates by dated or undated references, provisions from other publications. The relevant parts of these normative references are cited at the appropriate place in the text and the publications are listed hereafter. For dated references, subsequent amendments to or revisions of any of these publications apply to this FIS only when incorporated in it by amendment or revision. For undated references the latest edition of the publication referred to applies.

|3GPP 22.011||Service accessibility|
|---|---|---|
|3GPP 22.067||Enhanced Multi-Level Precedence and Pre-emption Service<br>(eMLPP) Stage 1|
|3GPP 27.007||AT command set for User Equipment (UE)|
|EIRENE SRS||EIRENE Project Team. System Requirement Specification.|
|ETS 300102-1|1990|ISDN; User-network interface layer 3; Specification for basic<br>call control|
|EuroRadio FFFIS||UIC ERTMS/GSM-R Unisig; EuroRadio Interface Group;<br>Radio Transmission FFFIS for EuroRadio; A11T6001|
|ISO/IEC 3309|12.93|HDLC procedures; Frame structure|
|ISO/IEC 4335|12.93|HDLC procedures; Elements of Procedures|
|ISO/IEC 7776|07.95|Description of the X.25 LAPB-compatible DTE data link<br>procedure|
|ISO/IEC 7809|12.93|HDLC procedures; Classes of Procedures|
|ITU-T E.212|11.98|The international identification plan for mobile terminals and<br>mobile users|

<!-- end of page 14 -->

ITU-T T.70 03.93 Network-independent basic transport service for telematic services ITU-T X.214 11.93 Information Technology - Open System Interconnection - Transport service definition ITU-T X.224 11.93 Protocol for providing the OSI connection-mode transport service N-9018 UIC - GSM-R Network Codes RFC 1034 Domain Names – Concepts and Facilities RFC 1035 Domain Names – Implementation and Specification RFC 1122 Requirements for Internet Hosts -- Communication Layers RFC 2018 TCP Selective Acknowledgment Options RFC 2883 An Extension to the Selective Acknowledgement (SACK) Option for TCP. RFC 5482 TCP User Timeout Option RFC 6633 Deprecation of ICMP Source Quench Messages RFC 7323 TCP Extensions for High Performance RFC 791 Internet Protocol RFC 793 Transmission Control Protocol SIM FFFIS MORANE SIM FFFIS for GSM-R SIM cards P38T9001 Subset-023 Glossary of Terms and Abbreviations Subset-026 System Requirements Specification Subset-037-2 EuroRadio FIS – Safety Layer Subset-037-3 Euroradio FIS – FRMCS Communication Functional Module Subset-093 GSM-R Interfaces Bearer Service Requirements’ Subset-098 RBC-RBC Safe Communication Interface TS 27.010 3rd Generation Partnership Project; Technical Specification Group Core Network and Terminals; Terminal Equipment to User Equipment (TE-UE) multiplexer protocol

<!-- end of page 15 -->
