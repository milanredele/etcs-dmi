# **3 GENERAL ASPECTS**

## **3.1 Scope**

3.1.1.1.1 This document (Subset-037-3) is applicable for data transmission over FRMCS without safety responsibility.

3.1.1.1.2 In particular Subset-037-3 does not define:

   - The application functionality and application information flow.

   - The architecture of the radio communication system.

   - Security aspects are specified in [Subset-146].

   - Safety aspects as these are specified in [Subset-037-2].

## **3.2 Acronyms and abbreviations**

3.2.1.1.1 For general ERTMS/ETCS terms, definitions and abbreviations refer to [Subset-023]. New terms and abbreviations relevant and used in this FIS are specified here.

|**Abbreviation**|**Meaning**|
|---|---|
|API|Application Programming Interface|
|AU1|First Authentication message|
|AU2|Second Authentication message|
|CFM|Communication Functional Module|
|CS|Circuit Switched|
|DI|Disconnect|
|DT|Data|
|FRMCS|Future Rail Mobile Communication System|
|ID|Identity|
|ITU|International Telecommunication Union|
|MTU|Maximum Transfer Unit|
|O&M|Operation and Maintenance|
|OSI|Open System Interconnection|
|PDU|Protocol Data Unit|
|PS|Packet Switched|
|RTO|Retransmission TimeOut|
|SFM|Safe Functional Module|
|TCEPID|Transport Connection EndPoint Identifier|
|TP|Transport Protocol|
|TSAP|Transport Service Access Point|
|TU|Trackside Unit (e.g. RBC)|

## **3.3 Definitions**

3.3.1.1.1 For general ERTMS/ETCS terms, definitions and abbreviations refer to [Subset-023]. New definitions relevant and used in this FIS are specified here.

<!-- end of page 4 -->

#### **FUNCTIONAL MODULE**

Set of functions contributing to realize the same global task.

#### **Mandatory feature**

The feature has to be provided by on-board and/or trackside equipment where interoperability is required.

#### **MESSAGE AUTHENTICATION CODE (MAC)**

An authenticator which is sent with a message to enable the receiver to detect alterations made to the message since it left the sender and to verify that the source of the message is as claimed. The MAC is a function of the whole message and a secret key.

#### **National Add-on**

The feature is a matter of national railway specification. Interoperability must not be influenced.

#### **Optional feature/Option**

The feature might be provided or not. If provided, it has to be provided as specified. Optional features are not required. Interoperability between EuroRadio peers providing and not providing the optional feature has to be guaranteed. Otherwise, the option has to be deactivated.

## **3.4 References**

This FIS incorporates by dated or undated references, provisions from other publications. The relevant parts of these normative references are cited at the appropriate place in the text and the publications are listed hereafter. For dated references, subsequent amendments to or revisions of any of these publications apply to this FIS only when incorporated in it by amendment or revision. For undated references the latest edition of the publication referred to applies.

|**Reference**|**Title**|**Author**|**Issue**|
|---|---|---|---|
|FRMCS FFFIS|UIC; FRMCS FFFIS – Form Fit Functional Interface Specification|UIC||
|RFC 791|Internet Protocol, RFC791 aka IETF STD 5, last update 2/2013 (RFC6864)|IETF|8/1981|
|RFC 793|Transmission Control Protocol, RFC793 aka IETF STD 7, last update 2/2012<br>(RFC6528)|IETF|8/1981|
|RFC 1122|Requirements for Internet Hosts – Communication Layers.|IETF|10/1989|
|RFC 2018|TCP Selective Acknowledgment Options|IETF|10/1996|
|RFC 2460|Internet Protocol, Version 6 (Ipv6)|IETF|10/1998|
|RFC 2883|An Extension to the Selective Acknowledgement (SACK) Option for TCP|IETF|07/2000|
|RFC 5482|TCP User Timeout Option|IETF|03/2009|
|RFC 6633|Deprecation of ICMP Source Quench Messages|IETF|05/2012|
|RFC 7323|TCP Extensions for High Performance|IETF|09/2014|
|Subset-023|Glossary of Terms and Abbreviations|UNISIG||
|Subset-037-1|EuroRadio FIS – GSM-R CS/PS Communication Functional Module and<br>Coordinating Function FRMCS/GSM-R|UNISIG||
|Subset-037-2|EuroRadio FIS – Safety Functional Module|UNISIG||
|Subset-098|RBC-RBC Safe Communication Interface|UNISIG||
|Subset-146|Security Layers for ETCS Applications|UNISIG||

<!-- end of page 5 -->
