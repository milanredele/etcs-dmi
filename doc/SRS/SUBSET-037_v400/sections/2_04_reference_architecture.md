# **4 REFERENCE ARCHITECTURE**

4.1.1.1 EN 50159 defines the reference architecture for safety-related systems using open transmission systems. The general structure of a safety-related system such as the European Train Control System (Figure 1) is derived from EN 50159.

4.1.1.2 In addition to safety-related information, application processes in the safety-related equipment can exchange non-safety related information with remote application processes using the services of the radio communication system.

<!-- Start of picture text -->
Safety-Related Safety-Related<br>Equipment Equipment<br>Safety-Related<br>Application  Information Application<br>Process Process<br>3 3<br>Safety-Related<br>Safety-Related Safety-Related<br>Message<br>Transmission Transmission<br>System System<br>2 2<br>Protocol Data<br>(Open) (Open)<br>Unit<br>Communication Communication<br>System System<br>1 1<br>Network<br><!-- End of picture text -->

**Figure 1 Structure of the radio communication system**

4.1.1.3 For the purposes of this FIS, the open transmission system of EN 50159 is divided into components: the Communication System and the Open Network. The open (public or railway owned) network is out of scope for this part of the FIS. Only the service features requested at the interface to the network are covered and described in the [Subset-037-1].

4.1.1.4 The Safety Functional Module (SFM) provides the functions of the safety-related transmission system. The Communication Functional Module (CFM) provides the functions of the communication system is covered in the [Subset-037-1]. The service interfaces and the protocol interfaces are defined.

<!-- end of page 12 -->

4.1.1.5 Interface 3 is a service interface between safe applications (e.g. ATP) and the Safe Functional Module (safety layer).

4.1.1.6 Interface 2 is an optional service interface between non-safe applications or support applications and the Communication Functional Module. This option is not required for ETCS level 1 radio in-fill unit.

4.1.1.7 The service interfaces 2 and 3 are not mandatory for interoperability. Only a functional definition is provided.

4.1.1.8 Logical peer entity interface 5 is mandatory for interoperability. The interface is specified in terms of protocol data units and communication relevant aspects of module functionality.

4.1.1.9 The O&M plane covers all operations and management aspects. Interface 4 is a local service interface to the O&M stack, which is not specified.

4.1.1.10 The CFM is out of scope of this FIS.

<!-- end of page 13 -->
