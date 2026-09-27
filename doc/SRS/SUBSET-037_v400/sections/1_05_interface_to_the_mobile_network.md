# **5 INTERFACE TO THE MOBILE NETWORK**

5.1.1.1 The requirements to the mobile network are specified by [Subset-093].

5.1.1.2 The interface requirements are specified in [EuroRadio FFFIS].

5.1.1.3 The multiplexing protocol [TS 27.010] shall be used to coordinate the possible data streams for one CS and at least 2 PS services between CFM and mobile.

5.1.1.4 The following table specifies the necessary requirements for this protocol.

**Table 1 Applicability conditions of [TS 27.010]**

|**Section**|**Application conditions**|
|---|---|
|§ 1<br>Modification<br>History|Not relevant.|
|§ 2 Table of<br>Contents|Not relevant.|
|§ 3<br>Abbreviations|Not relevant.|
|§ 4 Overview<br>of Multiplexing<br>System|For the physical link the mode “advanced without error recovery” shall be used.|
|§ 5 Non Error<br>Recovery mode<br>Options|All applicable except for the following rows of this table.|
|§ 5.1.2 Start up<br>services|As mode for the physical link “HDLC - UI frames “ shall be used.|
|§ 5.1.3 DLC<br>establishment<br>services|For the DLC the frame type UIH shall be used.<br>The convergence layer shall be set to “2” for CS services and PS services<br>The Priority parameter shall be used to give the highest priority to the ETCS application|
|§ 5.1.5 Power<br>Control<br>services|Power save control will not be used.|
|§ 5.2.7.2<br>Start/stop<br>transmission –<br>extended<br>transparency|The transparency procedure shall be used for DC1/DC3.|
|§ 5.2.7.3<br>Flow-control<br>transparency|Software flow control using DC1/DC3 shall be supported.|
|§ 6 Error<br>Recovery Mode<br>Option|Not relevant.|
|Annex A<br>(informative):<br>Advice to TE<br>software<br>implementers|Applicable.|
|Annex B<br>(informative):<br>Explanatory<br>notes on the<br>CRC<br>Calculation|Applicable.|

<!-- end of page 19 -->

|**Section**||**Application conditions**|
|---|---|---|
|Annex C|Not relevant.||
|(informative):|||
|Change History|||

## **5.2 Service primitives for mobile network registration**

5.2.1.1 For handling the network registration, the two primitives T-REGISTRATION.request and T-REGISTRATION.indication will be provided.

5.2.1.2 The service primitives are forwarded from/to the Safe Functional Module (SFM) and interpreted as command/response at the interface to mobile network (see section B.5).

## **5.3 Service primitives for Permitted Mobile Networks (GSM-R only)**

5.3.1.1 It is necessary to indicate a list of 'Permitted' Mobile Networks to the driver. This list comprises mobile networks that are both 'available', i.e. the mobile detects their presence, and 'Allowed', i.e. a previously-stored list of mobile networks to which the mobile is allowed to register.

5.3.1.2 The service will be supported by the primitives T-PERMISSION.request and T-PERMISSION.indication.

5.3.1.3 The service primitives are command/response between the Communication Functional Module (CFM) and the mobile terminal (MT). For details see Annex B.5.1.1.

<!-- end of page 20 -->
