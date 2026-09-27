# **4 REFERENCE ARCHITECTURE**

4.1.1.1.1 The Communication Functional Module (CFM) determines the necessary functions and capabilities to make use of FRMCS. Figure 1 contains a detailed reference architecture of the radio communication sub-system. The service interfaces and the protocol interfaces are defined.

4.1.1.1.2 In Figure 1 the interfaces (1c) and (1d) are used towards the FRMCS which can be used on-board and/or trackside and encompasses the user plane to exchange user data as well as the control plane to manage necessary information for communications (FRMCS APIs) (refer to FRMCS FFFIS). Interface (1c) is the interface between EuroRadio and the FRMCS on-board (OBapp). Interface (1d) is the interface between the EuroRadio and the FRMCS trackside (TSapp) - this interface is FFS.

<!-- Start of picture text -->
                                                                   User<br>                                                                         ETCS: Subset-37-2<br>CFM User CFM User<br>                                                                          ATO: Subset-148<br>2c 2c<br>                                                                Transport Communication Functional Module (CFM) Communication Functional Module (CFM)<br>On-Board (client side) Trackside (server side)<br>                                                                                Subset-37-3<br>Connection  Connection<br>Management Management<br>L4: Packaging/Redundancy<br>ALE ALE<br>FRMCS L4: Security Layer FRMCS  DNS<br>API TLS TLS API<br>PKI<br>Services<br>L4: Correction<br>TCP TCP<br>Layer 3<br>IP IP<br>Ethernet Ethernet<br>1c OBapp TSapp 1d<br>                                                             Transmission<br>FRMCS on-board FRMCS trackside<br>                                                                 FRMCS and TOBA specifications<br>PKI Domain<br>FFS<br>FRMCS<br>FRMCS trackside<br>user plane<br>control plane         user plane control plane<br><!-- End of picture text -->

**Figure 1 Reference architecture of EuroRadio**

<!-- end of page 6 -->

4.1.1.1.3 Interface (2c) is the interface between the Communication Functional Module (CFM) and the CFM User and it is in the scope of this specification.

4.1.1.1.4 Logical peer entity interfaces Security Layer, Layer 4 (Transport), Layer 3 (Network) are mandatory for interoperability. The interface is specified in terms of protocol data units and communication relevant aspects of module functionality.

4.1.1.1.5 Additional to the application related communication the TLS protocol layer needs IP Connectivity to the support functions “DNS and PKI Services”.

<!-- end of page 7 -->
