# **16. VERSION MANAGEMENT**

## **16.1 Introduction**

16.1.1.1 The version of the FFFIS STM defines unambiguously the mandatory interface functions that ensure technical exchangeability between ERTMS/ETCS on-board and STM.

16.1.1.2 During the life time of the FFFIS STM there may be several versions of the FFFIS STM.

16.1.1.3 The objective of this section is to define requirements applicable to ERTMS/ETCS onboard equipment and to STM, when different versions of the FFFIS STM have been defined.

## **16.2 Identification/evolution of the versions**

16.2.1.1 The evolution of the versions of the FFFIS STM shall be sequential, i. e. there shall only be a direct upgrade of an existing version and no branch is accepted.

16.2.1.2 The version of the FFFIS STM shall be identified by a number which complies with the following:

   - a) Each Version Number will have the following format: X.Y, where X and Y are any number between 0 and 255 (examples: 2.0, 3.0, 4.2).

   - b) The first number (X) distinguishes not compatible versions.

   - c) The second number (Y) indicates compatibility within a version X.

   - d) If the first number of two versions is the same, that indicates that those versions are compatible, independently of the second number (e. g. version 4.5 is compatible with 4.3, 4.14).

16.2.1.3 The “FFFIS STM version number X or Y” is incremented only when the functionality of the FFFIS STM changes.

## **16.3 Version numbers**

16.3.1.1 Table of FFFIS STM version numbers

<!-- end of page 86 -->

|**FFFIS STM**<br>**Version**<br>**Number**|**Supported by**<br>**ERTMS/ETCS on-**<br>**board equipment**|**Remark**|
|---|---|---|
|X=2,<br>Y=0,<br>Z=0|Supplier specific|Initial Version, introduced in SUBSET-035<br>v2.0.0.|
|X=3,<br>Y=0,<br>Z|Supplier specific|Introduced<br>in<br>SUBSET-035<br>v2.1.1<br>(General revision of the FFFIS STM)<br>Z is vendor specific|
|Legal<br>backward<br>compatibility<br>envelope<br>X=4,<br>Y=0|Yes|Introduced<br>in<br>SUBSET-035<br>v3.x.0<br>(General revision of the FFFIS STM in the<br>frame of ETCS baseline 3)|

16.3.1.2 The STM shall support and send one and only one “FFFIS STM version number”, which is the highest one amongst those included in the “legal backward compatibility envelope”, as defined in table 16.3.1.1.

16.3.1.3 The ERTMS/ETCS on-board equipment shall support any of the “FFFIS STM version numbers X” included in the “legal backward compatibility envelope”, as defined in table 16.3.1.1.

16.3.1.4 All nodes/functions of the ERTMS/ETCS on-board equipment shall support the same “FFFIS STM version numbers” and shall therefore send the same “FFFIS STM version number”, when opening a connection with a given STM (see section 7.1.2).

16.3.1.5 When a connection is successfully established with a “FFFIS STM version number X” lower than the highest STM version numbers X included in the “legal backward compatibility envelope”, the ERTMS/ETCS on-board equipment shall apply the corresponding set of requirements as per section 16.4, in order to ensure backward compatibility between the ERTMS/ETCS on-board equipment and the STM.

## **16.4 Management of older FFFIS STM versions by ERTMS/ETCS onboard**

16.4.1.1 The “FFFIS STM version number” introduced in this version of the SUBSET-035 is the starting point of the “legal backward compatibility envelope”, which means that whether an ERTMS/ETCS on-board equipment supports a “FFFIS STM version number X” lower than the one introduced in this version of the SUBSET-035 is supplier specific and outside the scope of this document.

<!-- end of page 87 -->
