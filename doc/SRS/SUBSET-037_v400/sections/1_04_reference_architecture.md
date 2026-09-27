# **4 REFERENCE ARCHITECTURE**

4.1.1.1 The Communication Functional Module (CFM) provides the functions of the communication system based on circuit-switched/packet-switched bearer services of the GSM-R/GPRS. Figure 2 contains a detailed reference architecture of the radio communication sub-system. The service interfaces and the protocol interfaces are defined.

4.1.1.2 In Figure 2 the Interface 1 is an interface between the EuroRadio and the chosen transmission medium. It consists of a user plane for transfer of user data and a control plane for connection management. Interface 1a is the GSM/GPRS-Interface (on-board) and it is the recommended on-board interface between the EuroRadio and the MT (refer to [EuroRadio FFFIS]). Interface 1b is the Interface to fixed networks (trackside). In Figure 2 a primary rate interface to ISDN-like networks is shown for CS mode, although ISDN basic rate interface and PSTN are not excluded. For PS mode an Ethernet interface shall be used. Interface 1c is the interface between EuroRadio and FRMCS on-board. Interface 1d is the interface between EuroRadio and FRMCS Trackside.

<!-- end of page 16 -->

<!-- Start of picture text -->
Train side Track side<br>Support  Other IP  Support<br>application Applications Non-safe Non-safe application<br>Applications ATP application ATP application Applications<br>Control Normal data Normal data Control<br>4 8 2a 3 3 2a 4<br>Safety layer 5 Safety layer<br>2b 2b 2b 2b<br>Coordinating function for CS, PS and FRMCS Coordinating function for CS, PS and FRMCS<br>ChannelControl  2c FRMCS data PS data ChannelControl  CS dataNormal  CS dataNormal  ChannelControl  PS dataNormal  ChannelControl  2c FRMCS data<br>ALE client ALE server<br>RFC 793 TCP X.224 TP2 6 X.224 TP2 RFC 793 TCP<br>RFC 791 IP T.70 CSPDN header T.70 CSPDN header RFC 791 IP<br>RFC 1661<br>GSM 27.007 AT CMD<br>O&M FRMCS PPP FRMCS O&M<br>[Subset 37-3] [Subset 37-3]<br>1c<br>RFC 1661<br>GSM 27.007 AT CMD<br>PPP<br>GSM 24.008<br>SM<br>GSM 44.065 SNDCP GSM 24.008 GMM GSM 24.008 ETS 300 102 DSS1<br>GSM 44.064 LLC<br>1c 1d<br>GSM 44.060 RLC<br>ISO 7776 HDLC ISO 7776 HDLC<br>GSM 44.060 MAC GSM 44.006 DL 7 ETS 300 125 LAPD<br>ISO3309 ISO3309<br>IEEE 802.3 IEEE 802.3 IEEE 802.3<br>1a 1b<br>Ethernet Ethernet Ethernet<br>GSM 24.004 RF ETS 300 011 ISDN PRI<br>OBApp PD channel Dm channel Bm channel B channel D channel Eth channel TSApp<br>FRMCS Control/User plane PS User plane CS/PS Control plane CS User plane CS User plane CS Control plane PS Control/User plane FRMCS Control/User plane<br>PSD mobile termination Number of interface CSD communication entity PSD + CSD communication entity GSM-R/GPRS CFM – Scope of SubSet-037-1<br>CSD mobile termination Data flow PSD communication entity FRMCS + PSD + CSD communication entity SFM – Scope of SubSet-037-2<br>Protocol interface FRMCS communication entity FRMCS CFM – Scope of SubSet-037-3<br>Figure 2 Reference architecture of EuroRadio<br>Resource<br>Management PS data<br><!-- End of picture text -->

<!-- end of page 17 -->

4.1.1.3 Interface 2a is the service interface between non-safe applications or support applications and the coordinating function. Interface 2b is the service interface between SFM and the coordinating function for safety applications. The coordinating function is described in section 7.

4.1.1.4 Interface 2c is the service interface between coordinating function and the FRMCS and it is described in [Subset-037-3].

4.1.1.5 Interface 3 is the Safe Functional Module Interface and it is described in [Subset-037-2] together with the Safety Layer and the interface 5.

4.1.1.6 The service interfaces 2 and 3 are not mandatory for interoperability. Only a functional definition is provided.

4.1.1.7 Logical peer entity interfaces 5, 6 and 7 (7 only for CS mode) are mandatory for interoperability. The interface is specified in terms of protocol data units and communication relevant aspects of module functionality.

Note: interface 6 refers to logical interfaces at the transport level peer entities. This refers both to X.224 entities in CS mode and TCP entities in PS mode.

4.1.1.8 The O&M plane covers all operations and management aspects. Interface 4 is a local service interface to the O&M stack, which is not specified.

4.1.1.9 Interface 8 is a service interface for other on-board IP applications to use packet switched communication. The interface consists of functions to share the mobile terminals, and a data interface to send and receive IP packets. The corresponding counterpart for the trackside is out of scope for this specification.

4.1.1.10 The coordinating function shown in the Figure 2 also supports FRMCS described in the [Subset-037-3].

<!-- end of page 18 -->
