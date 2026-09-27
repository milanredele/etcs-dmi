# **5. INTRODUCTION**

## **5.1 Scope and purpose of the document**

5.1.1.1 The European Railways are currently in the process of implementing ERTMS. A further step in achieving improved capacity, on-time performance and opportunities to realise energy efficiency improvements is to develop and implement Automatic Train Operation (ATO).

5.1.1.2 ERTMS/ATO provides a set of non-safety functions related to speed control, accurate stopping, door opening and closing, and other functions traditionally assigned to a driver, while the safety of operation is still ensured by ETCS with regards to the speed and distance limits and also by other safe systems.

5.1.1.3 ERTMS/ATO covers a wide range of applications from manually assisted to fully automated train operation. Possible actual operation depends on the desired grade of automation (GoA) and the automation level supported by IM on a specific route.

5.1.1.4 The definition of GoA arises from apportioning responsibility for the given functions of railway operations between operational staff and involved technical railway systems. The table below defines the operation principles for each GoA level.

|**GoA**|**GoA Name**|**Train Operator**|**Description**|
|---|---|---|---|
|**GoA1**|**Non automated**<br>**train operation**|Train driver in the<br>cab|The train is driven manually; but protected by automatic train<br>protection (ATP). This GoA can also include providing advisory<br>information to assist manual driving.|
|**GoA2**|**Semi-**<br>**automated train**<br>**operation**|Train driver in the<br>cab|The train is driven automatically, stopping is automated but a driver in<br>the cab is required to start automatic driving of the train, the driver can<br>operate the doors (although this can also be done automatically), the<br>driver is still in the cab to check the track ahead is clear and carry out<br>other manual functions. The driver can take over in emergency or<br>degraded situations.|
|**GoA3**|**Driverless train**<br>**operation**|Train attendant<br>on-board the<br>train|The train is operated automatically including automatic departure, a<br>train attendant has some operational tasks, e.g. operating the train<br>doors (although this can also be done automatically) and can assume<br>control in case of emergency or degraded situations.|
|**GoA4**|**Unattended**<br>**train operation**|No staff on-board<br>competent to<br>operate the train|Unattended train operation; all functions of train operation are<br>automatic with no staff on-board to assume control in case of<br>emergencies or degraded situations.|

#### **Table 1 Grades of Automation high level description**

5.1.1.5 While mainline railway applications usually apply non-automated train operation, e.g., GoA1 presently for ETCS Level 1 and ETCS Level 2, Urban Transport Systems are demonstrating across the world the capability of Automated Train Operation to increase line capacity and to reduce energy consumption, compared to manual train operation.

<!-- end of page 14 -->

5.1.1.6 With the introduction of ERTMS/ATO, Automated Train Operation (GoA2 to GoA4) will be beneficial for the different kinds of railway operation:

- a) For High Speed Lines, Intercity lines and Regional lines, ERTMS/ATO will enhance the timetable adherence, provide high performance and enable the introduction of train traction energy saving functions fully managed by the ATO.

- b) For Freight lines, ERTMS/ATO is supporting a smoother operation (e.g., allowing efficient conflict management and minimising unexpected train stops, support loading/unloading operations…) which lead to energy savings, but also to improved line capacity.

- c) For Urban and Suburban applications, ERTMS/ATO will permit to provide high performance for lines carrying intensive inner suburban and cross-city traffic. ATO will also bring energy saving for these types of operation.

5.1.1.7 The ATO Operational Concept was defined by the EEIG ERTMS Users Group up to GoA4:

- a) ERTMS/ATO Operational Principles [Ref 1];

- b) ERTMS/ATO Operational Requirements [Ref 2];

- c) ERTMS/ATO Glossary [Ref 3];

- d) ERTMS/ATO Operational Scenarios [Ref 4].

5.1.1.8 As ERTMS/ATO equipped trains shall be able to operate over any ERTMS/ATO equipped track, the interface between ERTMS/ATO on-board and trackside must be technically interoperable, i.e. messages, commands, data etc. communicated between them must be understood by the receiver as intended by the sender.

5.1.1.9 The following interfaces are specified:

- a) ATO-OB / ATO-TS Interface [Ref 7] & [Ref 8];

- b) ETCS-OB / ATO-OB Interface [Ref 6] & [Ref 10];

- c) ATO-OB / Rolling Stock Interface [Ref 9] & [Ref 14];

5.1.1.10 The **scope** of this document is to define the system functional requirements for an interoperable ERTMS/ATO system, limited to GoA2 (excluding GoA3 and GoA4).

5.1.1.11 This specification is applicable for ETCS levels 1 and 2.

5.1.1.12 The following topics are out of scope of this document:

- a) ATO operation with no ETCS-OB;

- b) GoA3 and GoA4.

<!-- end of page 15 -->

5.1.1.13 The **purpose** of this document is to specify the system requirements that must be fulfilled in order to provide an interoperable solution for ERTMS/ATO (GoA2). It defines the following:

- a) ATO related functions (including DAS);

- b) Driver Machine Interface principles;

- c) ATO Operational States;

- d) ERTMS/ATO architecture (including the definition of all interfaces and the level of standardisation).

## **5.2 Reference documents**

|**Ref. N°**|**Title**|**Reference**|
|---|---|---|
|[Ref 1]|ERTMS/ATO Operational Principles|12E108|
|[Ref 2]|ERTMS/ATO Operational<br>Requirements|13E137|
|[Ref 3]|ERTMS/ATO Glossary|13E154|
|[Ref 4]|ERTMS/ATO Operational Scenarios|13E151|
|[Ref 5]|ERTMS/ETCS System Requirements<br>Specification|SUBSET-026|
|[Ref 6]|ETCS-OB / ATO-OB FFFIS<br>Application Layer|SUBSET-130|
|[Ref 7]|ATO-OB / ATO-TS FFFIS Application<br>Layer|SUBSET-126|
|[Ref 8]|ATO-OB / ATO-TS FFFIS Transport<br>and Security Layers|SUBSET-148|
|[Ref 9]|ATO-OB / Rolling Stock FFFIS<br>Application Layer|SUBSET-139|
|[Ref 10]|ATO-OB Interface Specification<br>Communication Layers<br>for On-board Communication|SUBSET-143|
|[Ref 11]|ETCS Driver Machine Interface|ERA_ERTMS_015560|
|[Ref 12]|Dimensioning and Engineering rules|SUBSET-040|
|[Ref 13]|Glossary of Terms and Abbreviations|SUBSET-023|
|[Ref 14]|<sup>CCS Consist Network</sup><br>Communication Layers|SUBSET-147|
|[Ref 15]|Specific sub-system requirements<br>(traction, braking, etc.) for EMU/DMU,<br>locomotives and driving coaches<br>(Rolling stock sub-system<br>requirements, requirements for<br>economic purposes, requirements for<br>railway standardisation)|UIC 612-2|

<!-- end of page 16 -->

|**Ref. N°**|**Title**|**Reference**|
|---|---|---|
|[Ref 16]|Railway applications - Braking -<br>Requirements for the brake system of<br>trains hauled by locomotives|EN 14198|
|[Ref 17]|<sup>European Commission Regulation -</sup><br>TSI LOC&PAS|1302/2014|
|[Ref 18]|Train Interface FIS|SUBSET-034|
|[Ref 19]|ETCS System Version Management|SUBSET-104|
|[Ref 20]|<sup>Exceptions for on-board reduced</sup><br>envelopes of ETCS system versions|SUBSET-153|

#### **Table 2 Reference Documents**

<!-- end of page 17 -->

## **5.3 Abbreviations**

5.3.1.1 For ATO related abbreviations see ERTMS/ATO Glossary [Ref 3].

5.3.1.2 For ETCS related abbreviations see SUBSET-023 [Ref 13].

## **5.4 Definitions**

5.4.1.1 For ATO related definitions see ERTMS/ATO Glossary [Ref 3].

5.4.1.2 For ETCS related definitions see SUBSET-023 [Ref 13].

<!-- end of page 18 -->
