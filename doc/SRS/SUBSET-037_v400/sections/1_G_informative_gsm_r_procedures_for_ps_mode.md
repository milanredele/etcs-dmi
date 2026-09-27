# **ANNEX G. (INFORMATIVE) GSM-R PROCEDURES FOR PS MODE**

## **G.1. PROCEDURES**

G.1.1.1 The on-board enables communication in PS mode by two procedures, GPRS Attach and PDP Context Activation.

G.1.1.2 The procedures are required only to one MT and it is optional to do also to all available MTs.

G.1.1.3 The procedures are only possible to perform when GPRS service is enabled in the current radio cell.

G.1.1.4 As a precondition GPRS service is supported by the mobile terminal and enabled in related subscriber data (defined in the HLR)

G.1.1.5 The information below is valid for class B mobile terminals.

G.1.1.6 The sequence for the procedures is the following: 1. Network Registration

   2. GPRS Attach

   3. PDP Context Activation

## **G.2. GPRS ATTACH**

G.2.1.1 The GPRS Attach registers the mobile terminal in the packet data network and starts mobility management for the mobile terminal. Mobility management is the functionality in the network to manage the current location of the mobile terminal.

G.2.1.2 GPRS Attach is managed by the AT command ‘AT+CGATT’.

G.2.1.3 The mobile terminal must be registered to a network before executing the GPRS Attach. G.2.1.4 GPRS Attach is requested immediately after network registration and before safe connection setup, if the mobile termination was not yet GPRS attached. Note:  Depend on the Network Mode registration and GPRS Attach could be done in one step (Network Mode 1).

G.2.1.5 After successful GPRS attach, the MT may transit non-GPRS enabled cells. However, the GPRS attachment is kept. Thus, the packet service will be available as soon as the MT camps on a GPRS enabled cell without the need to perform a new attachment.

## **G.3. PDP CONTEXT ACTIVATION**

G.3.1.1 The PDP Context enables the mobile terminal to access and use packet data networks. The access point and protocol to use (e.g. IP) are passed as parameters in the activation

<!-- end of page 84 -->

order. At activation the mobile terminal will obtain an IP address and will also get the IP address for the default gateway and the IP address for the default DNS.

G.3.1.2 PDP Context is managed by the AT commands as specified in [EuroRadio FFFIS] - ‘AT+CGDCONT’ to set parameters APN and protocol.

   - ‘AT+CGEQREQ’ to set QoS parameters, QoS parameter traffic class = ‘streaming’

   - ‘AT+CGACT’ to activate/deactivate the PDP Context

<!-- end of page 85 -->
