# **7 COORDINATING FUNCTION**

7.1.1.1 The task of the coordinating function is to select the proper communication mode between GSM-R CS mode, GSM-R PS mode or FRMCS.

7.1.1.2 The main principle for choosing the transmission mode is to use FRMCS whenever possible, GPRS Packet Switched mode as a second alternative, and as a last alternative, Circuit Switched mode.

7.1.1.3 The coordinating function will store the last used mode per trackside ETCS ID in a ‘Transmission Mode Table’, and for subsequent connection the mode stored in the table will be used when setting up a connection.

7.1.1.4 The Transmission Mode Table shall contain the following entries for each ever-requested RBC (identified with ETCS ID), the default value is underlined:

GSM-R-Mode = [unknown, CS, PS]

FRMCS-Mode = [NO, YES]

7.1.1.5 A new entry in the Transmission Mode Table shall be generated if the requested RBC is not included in the table.

7.1.1.6 The Transmission Mode Table shall be stored persistently.

7.1.1.7 Establishment of a connection shall be done according to the following rules:

|Connection<br>Request Type|FRMCS<br>Mode|GSM-R<br>Mode|Action|
|---|---|---|---|
|FRMCS|n.a.|n.a.|Establish connection in FRMCS mode.<br>If successful, store FRMCS=yes.|
|GSM-R|n.a.|CS|Establish connection in CS mode.|
|||PS|Establish connection in PS Mode.<br>If the DNS response does not contain an “A” field, the user shall be informed by<br>a T-DISCONNECT.indication unless a “TXT” field indicating CS mode (txm=cs)<br>is received. In this case “CS” shall be stored to GSM-R-Mode and connection<br>establishment shall be done accordingly.|
|||unknown|Try to connect according to GSM-R Mode PS, but if no A-field is received, “CS”<br>shall be stored to GSM-R Mode and connection shall be established<br>accordingly.<br>Note: If receiving an ‘A’ field the mode shall be set to “PS” also if the connection<br>cannot be established.|
|FRMCS &|Yes|n.a.|Try to establish connection in FRMCS mode.|
|GSM-R|No|unknown|If not successful, retry according to the GSM-R mode.<br>Note: Only temporary (no transmission mode entry change) to cover transient<br>FRMCS or engineering failure.|
||No|CS / PS|Establish connection according to GSM-R Connection Request Type|

7.1.1.8 A successful connection establishment shall be indicated to the user by a T- CONNECT.confirmation primitive.

7.1.1.9 The T-CONNECT.confirmation shall inform the application about the type of the established connection (“GSM-R” or “FRMCS").

<!-- end of page 62 -->

7.1.1.10 In case of a not successful connection establishment, the user shall be informed by a T- DISCONNECT.indication with an appropriate reason.

7.1.1.11 During an ongoing connection, the coordinating function shall try a higher prioritised connection availability in parallel according to the following table:

|Connection<br>Request Type|Connection|Action (in parallel to the ongoing connection)|
|---|---|---|
|GSM-R|CS|**PS check**: When second GSM-R MT is free, DNS request for “A” field, if successful,<br>set GSM-R Mode to PS.|
|FRMCS & GSM-R|PS|**FRMCS check**:  Setup and release FRMCS E2E service, control plane only. If<br>successful, set FRMCS mode to YES in Mode Table. (see above)|
||CS|1.<br>**PS check**(see above)<br>2.<br>**FRMCS check**(see above)|

7.1.1.12 If the Transmission Mode Table changes for a specific RBC, an ongoing connection to this RBC shall be kept.

7.1.1.13 ANNEX H contains a flow chart as example for implementation.

<!-- end of page 63 -->
