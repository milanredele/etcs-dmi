# **3. GENERAL**

## **3.1 References**

|Ref. N°|Document Reference|Title|
|---|---|---|
|[1]|SUBSET-026|System Requirements Specification|
|[2]|SUBSET-056|STM FFFIS Safe Time Layer|
|[3]|SUBSET-057|STM FFFIS Safe Link Layer|
|[4]|SUBSET-058|FFFIS STM Application Layer|
|[5]|CENELEC 50170-2<br>(1996)|PROFIBUS|
|[6]|SUBSET-034|FIS for the Train Interface|
|[7]|SUBSET-041|Performance Requirements for Interoperability|
|[8]|CENELEC EN 50159<br>(2010)|Safety related communication in transmission systems|
|[9]|ERA_ERTMS_015560|ETCS Driver Machine Interface|
|[10]|SUBSET-101|Interface “K” specification|
|[11]|ERA_ERTMS_040001|Assignment Of Values To ETCS Variables|

## **3.2 Scope and purpose**

3.2.1.1 The acronym FFFIS stands for “Form Fit Functional Interface Specification”. This means an interface specification covering all protocol levels of communication, and including connector and physical level.

3.2.1.2 The lowest level boundary of this specification is the “Field Data Link” layer of the PROFIBUS. The term “bus” used afterwards in the document corresponds to this FDL layer. The referenced PROFIBUS standards cover the lowest communication layers, physical layer including connector, see [5].

3.2.1.3 The upper boundary of the specification describes the functions linked to the interface between an ERTMS/ETCS on-board equipment and an STM.

3.2.1.4 The FFFIS STM specifies the set of requirements enabling the ERTMS/ETCS on-board equipment to be connected to any STM (i.e. the ERTMS/ETCS on-board and the STMs are interchangeable), so that:

   - a) The functionality of the assembly ERTMS/ETCS on-board equipment / STM operating in level NTC / mode SN is equivalent to the one of the legacy National Train Control system,

   - b) The transitions between ERTMS/ETCS and a National System and the transitions between National Systems are seamlessly performed, with no additional constraint exported on the trackside other than the installation of Eurobalises for the level transitions.

<!-- end of page 31 -->

3.2.1.5 Within the set of requirements allocated to the ERTMS/ETCS on-board in this FFFIS STM, the access to some of the ERTMS/ETCS on-board standardised interfaces (DMI, Train Interface, Juridical Recording interface) or functions (e.g. odometer) allows minimising the number of interfaces/components needed for the installation of several National Systems on-board.

3.2.1.6 However, the use of specific interfaces or functions by National Systems, instead of these ERTMS/ETCS on-board interfaces/functions offered through this FFFIS STM, is permitted as long as it does not export any requirement on the ERTMS/ETCS on-board in addition to the ones specified in this FFFIS STM. Their choice and their definition are outside the scope of this specification.

3.2.1.7 Any implementation that does not comply with the clause 3.2.1.6 is considered as not compliant with the FFFIS STM and is outside the scope of this specification.

3.2.1.8 The use of the Interface “K” (see document ref [10]), which offers access to the KER balise interface, also allows minimising the number of antennas installed on-board, but is not considered as part of this FFFIS STM as the data is not transmitted over the PROFIBUS.

<!-- end of page 32 -->
