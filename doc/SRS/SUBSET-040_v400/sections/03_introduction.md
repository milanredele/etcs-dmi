# **3. INTRODUCTION**

## **3.1 References**

3.1.1.1 The following documents are referenced in this document:

   - System Requirement Specification - SUBSET-026

   - ETCS Driver Machine Interface - ERA_ERTMS_015560

   - Safety Requirements for Technical Interoperability of ETCS in Levels 1 & 2 – SUBSET-091

   - FFFIS for Eurobalise – SUBSET-036

   - FFFIS for Euroloop – SUBSET-044

   - Interface ´G´ Specification – SUBSET-100

   - Interface ‘K’ Specification – SUBSET-101

   - Technical Specification for the Interoperability for the “Rolling Stock subsystem - Locomotives and passenger rolling stock” (in the following referred to as “TSI LOC&PAS”)

   - Railway Applications – Braking – Brake performance, EN 16834, dated 2019

   - Railway Applications – Braking – Wheel Slide Protection, EN15595:2018+AC:2021, dated 2021

   - Interfaces between Control-Command and Signalling trackside and other subsystems, ERA/ERTMS/033281

3.1.1.2 Intentionally deleted

3.1.1.3 Intentionally deleted

## **3.2 Aim and purpose for a subset of engineering rules**

### **3.2.1 ERTMS/ETCS engineering rules**

3.2.1.1 The engineering rules are system-related limitations for installation of equipment, exchange of information, on-board configuration data, etc. that characterise the implementation of ERTMS subsystems.

3.2.1.2 These engineering rules provide additional constraints to the requirements stated in the SRS and other sub-level documents in order to ensure interoperability.

3.2.1.2.1 The Engineering Rules stated here are therefore complementary to the requirements stated in the SRS and subdocuments. References herein to other documents are not exhaustive, in particular to the SRS.

3.2.1.3 Intentionally deleted

<!-- end of page 11 -->

3.2.1.4 The aim of these engineering rules is not to define the whole set of rules necessary to realise a project with ERTMS/ETCS.

   - Additional rules, which are not defined in this document, may be needed, and may vary depending on the project constraints, Clients requirements or rules and Industry procedures. However, those rules must not preclude the use of any equipment meeting the engineering rules stated here.

3.2.1.5 The engineering rules defined stated herein or referenced are mandatory; Engineering advice is not in the scope of this document

### **3.2.2 Transmission systems other than ERTMS/ETCS**

3.2.2.1 Some constraints related to KER-compatible systems are described in appendix to this document.

3.2.2.2 Possible additional constraints related to transmission systems different from ERTMS (e.g. KER) must be defined within the relevant project.

## **3.3 Referencing balises and antennas**

### **3.3.1 Referencing balises and balise groups**

3.3.1.1 The reference location of a balise is the Balise Reference Marks, which are visible signs on the surface of the balise.

3.3.1.2 Balise groups will be considered as a complete device limited by the reference location of its outer balises.

3.3.1.3 The reference location of a balise group is the reference location of its outer balise with N_PIG variable = 0.

3.3.1.4 The «last switchable balise» of a balise group refers to the last encountered switchable balise with regards to the balise group crossing direction.

3.3.1.5 Distance between balise groups is by definition the distance between closest balises of the two groups (i.e. between the Balise Reference Mark of the last one of the first group and the Balise Reference Mark of the first one of the second group).

   - Note: This convention should not be mixed up with the distance used in the linking information (i.e. between the Balise Reference Mark of the balise with N_PIG variable = 0 of the first group and the Balise Reference Mark of the balise with N_PIG variable = 0 of the second group); see following figure

<!-- end of page 12 -->

<!-- Start of picture text -->
linking distance<br>N_PIG   0   1   2   3                   0   1   2   3<br>(example)<br>distance between balise groups<br>N_PIG   0   1   2   3                    0   1   2   3<br>(example)<br><!-- End of picture text -->

### **3.3.2 Referencing antennas**

3.3.2.1 The reference location of an antenna is the Antenna Reference Marks, which are visible signs on the surface of the antenna.

## **3.4 Intentionally deleted**

<!-- end of page 13 -->
