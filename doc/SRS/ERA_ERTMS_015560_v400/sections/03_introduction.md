##### **3. INTRODUCTION**


**3.1** **Foreword**


3.1.1.1 A clear and consistent definition of the ERTMS/ETCS driver machine interface helps the
driver to better understand the tasks he has to perform. This increases the speed and the
accuracy of interactions between the driver and the ERTMS/ETCS onboard equipment,
hence reducing the probability of human errors in application of the operational rules.


3.1.1.2 Moreover, harmonising the presentation of displayed information and the driver’s
interactions with the equipment, contributes to a unified operation of the trains regardless
of which suppliers products they are fitted with. This reduces further the potential for
human errors, reduces the driver training requirement and facilitates cross-acceptance of
equipment.


**3.2** **Scope and Field of Application**


3.2.1.1 This document defines the interface between the driver and the ERTMS/ETCS onboard
by detailing:

a) information to be displayed to the driver in response to operational situations. This

includes visual information for speed and distance monitoring, the symbols and text
messages as well as audible information.

b) the interactions between the driver and the ERTMS/ETCS onboard. This includes the

dialogue sequences used during data entry.


3.2.1.2 The DMI related interfaces inside the ERTMS/ETCS on-board equipment, the interfaces
between the driver and the ERTMS/GSM-R and between the driver and any other non
ERTMS/ETCS application, are outside of the scope of this specification.


3.2.1.3 The main part of the interface between the driver and the National System(s) is outside of
the scope of this specification. In case a National System is interfaced to the
ERTMS/ETCS onboard through an STM, a limited number of requirements are specified
in the present document (see chapters 9 & 12).


3.2.1.4 Cab integration issues (e.g. which screen(s) is/are used for the interface between the
driver and the ERTMS/ETCS onboard, the position of this/these screens inside the driver’s
cab, as well as which non ERTMS/ETCS applications are integrated onto the same
screen(s) as the one(s) used by the ERTMS/ETCS onboard) are also outside of the scope
of this specification.


3.2.1.5 Even though this specification allows two possible technologies, namely touch screen or
soft key, the specific hardware solutions (e.g. the number of screens, the size of hard
keys,...) used to achieve the ERTMS/ETCS DMI are outside of the scope of this
specification.


**3.3** **Document Description**


3.3.1.1 This specification describes two possible technologies for implementing the total image
display area, namely touch screen or soft key.


Version 4.0.0 PAGE 13 OF 317


**ERA ERTMS unit**

**ETCS Driver Machine Interface**


3.3.1.2 Any other technology shall be precluded.


3.3.1.3 Combining both technologies with the full freedom is not permitted by this specification.
However, this specification allows to design a hybrid solution by adding sensitive areas /
buttons on a soft key based layout.


3.3.1.4 Should this hybrid solution be retained, the added sensitive areas or buttons shall comply
with the corresponding requirements specified for the touch screen technology but
respecting the dimensions of the soft key based layout..


3.3.1.4.1 Note: It means that, for instance, the areas A/B can be sensitive for the “toggling function
for speed supervision” by applying the requirement 8.2.2.4.2.


3.3.1.5 Chapter 5 defines general ergonomic principles used throughout the document.


3.3.1.6 Chapter 6 details the various areas of the ETCS layout for both technologies. The
following chapters extensively refer to these areas when defining the displayed objects.


3.3.1.7 Chapter 7 introduces the supervision status with regards to the braking curves. Some
objects (e.g. speed pointer, circular speed gauge) will refer to them when defining their
displayed colour(s).


3.3.1.8 Chapter 8 details the ETCS & ATO objects forming the ETCS default window.


3.3.1.9 Chapter 9 details the STM objects forming the NTC default window.


3.3.1.10 Chapter 10 describes general (graphical) requirements for the sub-level windows.


3.3.1.11 Chapter 11 details the ERTMS/ETCS sub-level windows using the general requirements
of chapter 10


3.3.1.12 Chapter 12 details the ERTMS/ATO & NTC sub-level windows using the general
requirements of chapter 10.


3.3.1.13 Chapter 13 details all symbols used throughout the document.


3.3.1.14 Chapter 14 details the sounds used throughout the document.


3.3.1.15 Chapter 15 details the text messages to be displayed with regards to certain system
statuses.


3.3.1.16 Throughout the document, when a specific technology is not explicitly mentioned, then
the concerned requirement shall apply to both technologies.


Version 4.0.0 PAGE 14 OF 317


**ERA ERTMS unit**

**ETCS Driver Machine Interface**

