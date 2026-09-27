# **3 GENERAL ASPECTS**

## **3.1 Scope**

3.1.1.1 This document (Subset-037-2) is applicable to radio communication systems providing communication services for safety-related application processes using open networks. It specifies for ERTMS/ETCS the Radio System Interoperability for message exchange between on-board and trackside equipment in respect to safety-related application processes, like Automatic Train Protection of ETCS level 2. Additionally, it specifies for ETCS level 1 the optional message exchange between on-board equipment and radio infill unit.

3.1.1.2 Subset-037-2 does not define:

   - The application functionality and application information flow.

   - The open networks used.

   - The physical architecture of the radio communication subsystem.

3.1.1.3 Currently, the version handling fixed for ERTMS/ETCS is as follows:

   - There is one version of SFM only.

3.1.1.4 Version upgrade for enhanced EuroRadio SFM, if any, will follow the principle as defined in [Subset-026]:

   - The on-board SFM may operate with several of its versions.

   - The on-board SFM will decide whether it can use the protocol data units (PDUs) received from trackside.

   - This version check does not restrict negotiation of connection features by means of safety feature (SFM).

<!-- end of page 7 -->

## **3.2 Acronyms and abbreviations**

3.2.1.1 For general ERTMS/ETCS terms, definitions and abbreviations refer to [Subset-023]. New terms and abbreviations relevant and used in this FIS are specified here.

|AR|Authentication Response|
|---|---|
|AU1|First Authentication message|
|AU2|Second Authentication message|
|AU3|Third Authentication message|
|CEPID|Connection EndPoint IDentifier|
|CFM|Communication Functional Module|
|CS|Circuit Switched|
|DA|Destination Address|
|DES|Data Encryption Standard|
|DF|Direction Flag|
|DI|Disconnect|
|DT|Data|
|ETY|ETCS ID type field in a SaPDU|
|ID|Identity|
|IEC|International Electrotechnical Commission|
|ITU|International Telecommunication Union|
|KAB|Authentication Key (same as KMAC)|
|KS|Session Key (same as KSMAC)|
|KSMAC|Session Key|
|m|message|
|MA|Management|
|MT|Mobile Termination|
|MTI|Message Type Identifier|
|O&M|Operation and Maintenance|
|OSI|Open System Interconnection|
|PDU|Protocol Data Unit|
|PS|Packet Switched|
|QoS|Quality of Service|
|SA|Source Address|
|SaCEPID|Safe Connection EndPoint IDentifier|
|SaF|Safety Features|
|SAP|Service Access Point|

<!-- end of page 8 -->

|SaPDU|Safety Protocol Data Unit|
|---|---|
|SaS|Safety Service|
|SaSAP|Safety Service Access Point|
|SaSDU|Safety Service Data Unit|
|SaUD|Safety User Data|
|SFM|Safe Functional Module|
|TC|Transport Connection|
|TCEPID|Transport Connection EndPoint IDentifier|
|TPDU|Transport Protocol Data Unit|
|TS|Transport Service|
|TSAP|Transport Service Access Point|
|TSDU|Transport Service Data Unit|
|X|Mandatory parameter|
|X(U)|Use of this parameter is a user option|
|X(D)|Use of this parameter is a user option. If not provided, a default value will be used.|

## **3.3 Definitions**

3.3.1.1 For general ERTMS/ETCS terms, definitions and abbreviations refer to [Subset-023]. New definitions relevant and used in this FIS are specified here.

**Mandatory feature:** The feature has to be provided by on-board and/or trackside equipment where interoperability is required.

**Optional feature/Option:** The feature might be provided or not. If provided, it has to be provided as specified. Optional features are not required. Interoperability between EuroRadio peers providing and not providing the optional feature has to be guaranteed. Otherwise, the option has to be deactivated.

#### **National Add-on:**

The feature is a matter of national railway specification. Interoperability must not be influenced.

#### **CS MODE**

Circuit switched transmission mode uses a dedicated end-to-end transmission resource for each logical connection.

#### **DATA ENCRYPTION STANDARD (DES)**

A block cipher published in 1977 by the NBS as a US government norm. DES has been renamed Data Encryption Algorithm (DEA) during its adoption as an ANSI standard ([ANSI X3.92], 1981).

#### **DES KEY**

A cryptographic key of length 64 bits, where each eighth bit is an odd parity bit, as defined in [ANSI X3.92], 1981. Because of this structure, the effective key length is 56 bits.

<!-- end of page 9 -->

#### **DELETION (of a message)**

An attack in which a message is erased from the stream of messages.

**FORM FIT FUNCTIONAL INTERFACE SPECIFICATION (FFFIS)**

A FFFIS is the complete definition of an interface between functional or physical entities.

The FFFIS includes:

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

**INSERTION (of a new message)**

An attack in which a new message is being implanted into the stream of messages.

#### **MESSAGE AUTHENTICATION CODE (MAC)**

An authenticator which is sent with a message to enable the receiver to detect alterations made to the message since it left the sender and to verify that the source of the message is as claimed. The MAC is a function of the whole message and a secret key.

#### **MODIFICATION (of a message)**

Any unauthorised change of any part of a message.

#### **PADDING**

The information used to fill the unused part of a message to fill the block size.

#### **PS MODE**

Packet switched transmission mode shares radio transmission resources between several logical connections.

#### **RADIO COMMUNICATION SYSTEM**

A radio transmission system providing data communication services via open networks. It can be completed by an safety related transmission system to ensure safe data transmission.

#### **REPETITION/REPLAY**

An attack in which a message is stored and re-transmitted later.

1Note that 'Communication protocol' is used with different meanings in the EuroRadio FIS and FFFIS:

In the FIS a communication protocol is a protocol between peer entities within different End Systems connected by a network.

In the FFFIS a communication protocol is a protocol between functional modules or physical entities located in the same End System.

<!-- end of page 10 -->

#### **TRANSMISSION MODE TABLE**

The Transmission mode table contains the transmission mode for each known ETCS ID (i.e. RBC).

#### **TRIPLE-KEY**

Term used for three concatenated DES-keys, i.e. a length of 192 bits. In this specification, KMAC and KSMAC are both triple-keys.

## **3.4 References**

3.4.1.1 This FIS incorporates by dated or undated references, provisions from other publications. The relevant parts of these normative references are cited at the appropriate place in the text and the publications are listed hereafter. For dated references, subsequent amendments to or revisions of any of these publications apply to this FIS only when incorporated in it by amendment or revision. For undated references the latest edition of the publication referred to applies.

|ANSI X3.92|12.80|American National Standard Data Encryption Algorithm|
|---|---|---|
|EN 50159|09.10|Safety-Related Communication in Transmission Systems|
|ISO/IEC 9797-1|12.99|Information technology - Security techniques - Messages<br>Authentication Codes (MACs) - Part 1: Mechanisms using a<br>block cipher|
|ITU-T E.212|11.98|The international identification plan for mobile terminals and<br>mobile users|
|ITU-T X.214|11.93|Information Technology - Open System Interconnection -<br>Transport service definition|
|Subset-023||Glossary of Terms and Abbreviations|
|Subset-026||System Requirements Specification|
|Subset-037-1||EuroRadio FIS – GSM-R CS/PS Communication Functional<br>Module and Coordinating Function FRMCS/GSM-R|
|Subset-092-2||ERTMS EuroRadio Test cases Safety Layer|
|Subset-093||GSM-R Interfaces Bearer Service Requirements’|
|Subset-137||On-line Key Management FFFIS|

<!-- end of page 11 -->
