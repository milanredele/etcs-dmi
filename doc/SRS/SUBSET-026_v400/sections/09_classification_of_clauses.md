# **ERTMS/ETCS**

**System Requirements Specification Chapter 9 Classification of clauses**

REF  :  SUBSET-026-9 ISSUE :

4.0.0 DATE : 05/07/2023

<!-- end of page 1 -->

# **9.1 Modification History**

|Issue Number<br>Date|Section Number<br>Modification / Description|Author|
|---|---|---|
|3.4.2<br>17/11/15|All<br>Creation of the document|A. Hougardy|
|3.4.3<br>16/12/15||A. Hougardy|
|3.5.0<br>18/12/15|Baseline 3 2<sup>nd</sup>release version as recommended to EC<br>(see ERA-REC-123-2015/REC)|A. Hougardy|
|3.5.1<br>28/04/16|CR 1249 reopening following RISC #75|A. Hougardy|
|3.6.0<br>13/05/16|Baseline 3 2<sup>nd</sup>release version|A. Hougardy|
|3.6.1<br>29/05/17|CR’s 940, 994, 1120, 1170, 1252, 1259, 1263, 1264,<br>1288, 1293, 1300|O. Gemine|
|3.6.2<br>31/05/18|CR’s 887, 940 (bad implementation), 1296, 1306|O. Gemine|
|3.6.3<br>21/02/20|CR’s 1128, 1130, 1274, 1282, 1311, 1313, 1318,<br>1320, 1327, 1328, 1329, 1333, 1334, 1335, 1338,<br>1341, 1345|O. Gemine<br>A. Hougardy|
|3.6.4<br>22/06/20|CR’s 994, 1312, 1320, 1334|O. Gemine<br>A. Hougardy|
|3.6.5<br>22/12/21|CR’s 1021, 1162, 1238, 1354, 1358, 1370, 1372,<br>1376, 1377, 1395, 1396|O. Gemine<br>A. Hougardy|
|3.6.6<br>29/08/22|CR’s 940 (updated), 968, 1288 (updated), 1302, 1342,<br>1350, 1363, 1389, 1408, 1410, 1411, 1418|O. Gemine<br>A. Hougardy|
|3.9.1<br>24/11/22|CR’s 988, 1307, 1344, 1367, 1384, 1397, 1423, 1424,<br>1425<br>Outcome of B4R1 1<sup>st</sup>consolidation phase|O. Gemine<br>A. Hougardy|
|3.9.2|CR’s 1367, 1370|O. Gemine|
|21/02/23|Outcome of B4R1 2<sup>nd</sup>consolidation phase|A. Hougardy|
|3.9.3|CR’s 1359, 1427|O. Gemine|
|31/05/23|Outcome of B4R1 3<sup>rd</sup>consolidation phase|A. Hougardy|
|3.9.4|CR’s 1342 (updated), 1431|O. Gemine|
|30/06/23|Outcome of B4R1 4<sup>th</sup>consolidation phase|A. Hougardy|

<!-- end of page 2 -->

|Issue Number<br>Date|Section Number|Modification / Description|Author|
|---|---|---|---|
|4.0.0|Baseline 4 1<sup>st</sup>release v|ersion|O. Gemine|
|05/07/23|||A. Hougardy|

<!-- end of page 3 -->

|**9.2**|**Table of Contents**|
|---|---|
|9.1<br>M|odification History ........................................................................................................... 2|
|9.2<br>T|able of Contents .............................................................................................................. 4|
|9.3<br>In|troduction ....................................................................................................................... 5|
|9.3.1|Scope and Purpose.................................................................................................... 5|
|9.3.2|Definitions .................................................................................................................. 5|
|9.4<br>Cl|assification of clauses .................................................................................................... 6|
|9.4.1|Chapter 1 ................................................................................................................... 6|
|9.4.2|Chapter 2 ................................................................................................................... 8|
|9.4.3|Chapter 3 ................................................................................................................. 13|
|9.4.4|Chapter 4 ................................................................................................................. 74|
|9.4.5|Chapter 5 ................................................................................................................. 88|
|9.4.6|Chapter 6 ............................................................................................................... 112|
|9.4.7|Chapter 7 ............................................................................................................... 134|
|9.4.8|Chapter 8 ............................................................................................................... 144|

<!-- end of page 4 -->

# **9.3 Introduction**

## **9.3.1 Scope and Purpose**

9.3.1.1 Chapter 9 lists a classification into categories of all the clauses in the chapters 1 to 8 of the SRS.

9.3.1.2 The purpose of this chapter is to ease the assessment of the compliance of an ERTMS/ETCS on-board equipment with the SRS.

9.3.1.3 To that effect, this chapter comprehensively identifies which clauses contain requirements allocated to the ERTMS/ETCS on-board equipment and conversely which ones do not, either because they contain requirements allocated to the ERTMS/ETCS trackside only or because they are of another type.

## **9.3.2 Definitions**

- 9.3.2.1

   - The following categories are used to classify each SRS clause:

   - a) **<u>ERTMS/ETCS on-board requirement</u>** <u>: a clause containing requirement(s) that must</u> be fulfilled by a SRS compliant ERTMS/ETCS on-board

   - b) **<u>ERTMS/ETCS trackside requirement</u>** : a clause containing requirement(s) that must be fulfilled by a SRS compliant ERTMS/ETCS trackside, in case the corresponding function is implemented

   - c) **<u>Definition</u>** : a clause that is a necessary prerequisite to the correct interpretation of requirement(s) or without which requirement(s) cannot be unambiguously interpreted

   - d) **<u>Informative</u>** : a clause that helps the reader to better understand the context or the justification of requirement(s)

   - e) **<u>Others</u>** <u>: a clause that does not belong to any of the above categories</u>

9.3.2.2 Throughout the SRS, the requirements are identified as sentences using the keyword “shall”. However:

   - a) In section 9.4, tables are identified as a single entity through a reference based on the accompanying clause number. They can be classified as ERTMS/ETCS on-board and/or trackside requirements even if they do not include the keyword “shall”.

   - b) Elements of the ERTMS/ETCS language (radio messages, packets and variables, see chapters 7 and 8) are also described with tables. The numbered titles (i.e. the name of the element preceded by a clause number) together with their associated table are considered as single entities and are classified as both ERTMS/ETCS onboard and trackside requirements, even if they do not include the keyword “shall” either.

9.3.2.3 Amongst the categories listed in 9.3.2.1 only the two first ones can be combined, in case a requirement equally applies to both ERTMS/ETCS on-board equipment and ERTMS/ETCS trackside or in case two unambiguously distinguishable on-board and trackside requirements are kept together in the concerned clause for readability reasons.

<!-- end of page 5 -->

# **9.4 Classification of clauses**

## **9.4.1 Chapter 1**

|||Clause|classificatio|n||
|---|---|---|---|---|---|
|Clause number|ETCS on-<br>board<br>requirement|ETCS<br>trackside<br>requirement|Definition|Informative|Others|
|1.1||||x||
|1.2||||x||
|1.3||||x||
|1.3.1.1||||x||
|1.3.1.2||||x||
|1.4||||x||
|1.4.1.1||||x||
|1.4.1.1 1<sup>st</sup>bullet||||x||
|1.4.1.1 2<sup>nd</sup>bullet||||x||
|1.4.1.1 3<sup>rd</sup>bullet||||x||
|1.4.1.1 4<sup>th</sup>bullet||||x||
|1.4.1.1 5<sup>th</sup>bullet||||x||
|1.4.1.1 6<sup>th</sup>bullet||||x||
|1.4.1.1 7<sup>th</sup>bullet||||x||
|1.5||||x||
|1.5.1.1||||x||
|1.5.1.2||||x||
|1.5.1.3||||x||
|1.5.1.4||||x||
|1.6||||x||
|1.6.1.1||||x||
|1.6.1.2||||x||
|1.7||||x||
|1.7.1.1||||x||
|1.7.1.2|x|||||
|1.7.1.3||x||||
|1.7.1.4|||||x|
|1.7.1.5|x|x||||
|1.8||||x||
|1.8.1.1|||x|||
|1.8.1.2||||x||
|1.8.2||||x||
|1.8.2.1||||x||
|1.8.3||||x||
|1.8.3.1||||x||
|1.8.3.2||||x||
|1.8.3.3||||x||
|1.8.4||||x||
|1.8.4.1||||x||
|1.8.4.2||||x||
|1.8.5||||x||
|1.8.5.1.1||||x||

<!-- end of page 6 -->

|||Clause|classificatio|n||
|---|---|---|---|---|---|
|Clause number|ETCS on-<br>board<br>requirement|ETCS<br>trackside<br>requirement|Definition|Informative|Others|
|1.8.6||||x||
|1.8.6.1||||x||
|1.8.7||||x||
|1.8.7.1.1||||x||
|1.8.8||||x||
|1.8.8.1||||x||
|1.8.9||||x||
|1.8.9.1||||x||
|1.8.9.2||||x||
|1.8.10||||x||
|1.8.10.1||||x||
|1.8.10.2||||x||

<!-- end of page 7 -->

## **9.4.2 Chapter 2**

||ETCS n-|Clause<br>ETCS|classificatio|n||
|---|---|---|---|---|---|
|Clause number|o<br>board<br>requirement|<br>trackside<br>requirement|Definition|Informative|Others|
|2.1||||x||
|2.2||||x||
|2.3||||x||
|2.3.1||||x||
|2.3.1.1||||x||
|2.4||||x||
|2.4.1.1|||x|||
|2.4.1.2|||x|||
|2.4.1.3|||x|||
|2.4.1.3 a)|||x|||
|2.4.1.3 b)|||x|||
|2.4.1.3 c)|||x|||
|2.4.1.3 d)|||x|||
|2.5||||x||
|2.5.1||||x||
|2.5.1.1|||x|||
|2.5.1.1 a)|||x|||
|2.5.1.1 b)|||x|||
|2.5.1.1 c)|||x|||
|2.5.1.1 d)|||x|||
|2.5.1.1 e)|||x|||
|2.5.1.1 f)|||x|||
|2.5.1.1 g)|||x|||
|2.5.1.1 h)|||x|||
|2.5.1.2||||x||
|2.5.1.2.1|||x|||
|2.5.1.2.2||||x||
|2.5.1.2.3|||x|||
|2.5.1.2.4|||x|||
|2.5.1.2.5|||x|||
|2.5.1.3||||x||
|2.5.1.3.1|||x|||
|2.5.1.4||||x||
|2.5.1.4.1|||x|||
|2.5.1.4.2|||x|||
|2.5.1.5||||x||
|2.5.1.5.1|||x|||
|2.5.1.5.2||||x||
|2.5.1.5.3||||x||
|2.5.1.5.4||||x||
|2.5.1.6||||x||
|2.5.1.6.1|||x|||
|2.5.1.6.2|||x|||
|2.5.1.7||||x||

<!-- end of page 8 -->

|||Clause<br>|classificatio|n||
|---|---|---|---|---|---|
|Clause number|ETCS on-<br>board<br>requirement|ETCS<br>trackside<br>requirement|Definition|Informative|Others|
|2.5.1.7.1|||x|||
|2.5.1.7.2|||x|||
|2.5.1.8||||x||
|2.5.1.8.1|||x|||
|2.5.1.9||||x||
|2.5.1.9.1|||x|||
|2.5.2||||x||
|2.5.2.1|||x|||
|2.5.2.1 a)|||x|||
|2.5.2.1 b)|||x|||
|2.5.2.1 c)|||x|||
|2.5.2.2||||x||
|2.5.2.2.1|||x|||
|2.5.2.2.2||||x||
|2.5.2.2.2 a)||||x||
|2.5.2.2.2 b)||||x||
|2.5.2.2.2 c)||||x||
|2.5.2.3||||x||
|2.5.2.3.1||||x||
|2.5.2.3.2||||x||
|2.5.2.4||||x||
|2.5.2.4.1||||x||
|2.5.3||||x||
|2.5.3 Figure 1||||x||
|<br>2.5.3.1||||x||
|2.6||||x||
|2.6.1||||x||
|2.6.1.1|||x|||
|2.6.1.2||||x||
|2.6.1.3|||x|||
|2.6.2||||x||
|2.6.2.1|||x|||
|2.6.2.2|||x|||
|2.6.2.3|||x|||
|2.6.2.3 1<sup>st</sup>bullet|||x|||
|2.6.2.3 2<sup>nd</sup>bullet|||x|||
|2.6.2.3 3<sup>rd</sup>bullet|||x|||
|2.6.2.3 4<sup>th</sup>bullet|||x|||
|2.6.2.3 5<sup>th</sup>bullet|||||x|
|2.6.2.4||||x||
|2.6.2.5|||||x|
|2.6.2.6|||||x|
|2.6.2.7||||x||
|2.6.3||||x||
|2.6.3.1||||x||

<!-- end of page 9 -->

|||Clause<br>|classificatio|n||
|---|---|---|---|---|---|
|Clause number|ETCS on-<br>board<br>requirement|ETCS<br>trackside<br>requirement|Definition|Informative|Others|
|2.6.3.1.1|||x|||
|2.6.3.1.2|||x|||
|2.6.3.1.3||||x||
|2.6.3.1.4||||x||
|2.6.3.1.5|||x|||
|2.6.3.1.6||||x||
|2.6.3.1.6 Figure 2||||x||
|2.6.3.2||||x||
|2.6.3.2.1|||x|||
|2.6.3.2.1 1<sup>st</sup>bullet|||x|||
|2.6.3.2.2|||x|||
|2.6.3.2.2 1<sup>st</sup>bullet|||x|||
|2.6.3.2.3|||x|||
|2.6.3.2.3 1<sup>st</sup>bullet|||x|||
|2.6.3.2.4|||x|||
|2.6.3.2.4 1<sup>st</sup>bullet|||x|||
|2.6.3.2.4 2<sup>nd</sup>bullet|||x|||
|2.6.3.2.4 3<sup>rd</sup>bullet|||x|||
|2.6.3.2.4 4<sup>th</sup>bullet|||x|||
|2.6.4||||x||
|2.6.4.1||||x||
|2.6.4.1.1|||x|||
|2.6.4.1.2|||x|||
|2.6.4.1.3||||x||
|2.6.4.1.4|||||x|
|2.6.4.1.5||||x||
|2.6.4.1.6|||x|||
|2.6.4.1.7|||x|||
|2.6.4.1.8|||x|||
|2.6.4.1.9|||x|||
|2.6.4.1.10|||x|||
|2.6.4.1.11|||||x|
|2.6.4.1.11 Figure 3||||x||
|2.6.4.2||||x||
|2.6.4.2.1|||x|||
|2.6.4.2.1 1<sup>st</sup>bullet|||x|||
|2.6.4.2.1 2<sup>nd</sup>bullet|||x|||
|2.6.4.2.2|||x|||
|2.6.4.2.2 1<sup>st</sup>bullet|||x|||
|2.6.4.2.3|||x|||
|2.6.4.2.3 1<sup>st</sup>bullet|||x|||
|2.6.4.2.3 2<sup>nd</sup>bullet|||x|||
|2.6.4.2.4|||x|||
|2.6.4.2.4 1<sup>st</sup>bullet|||x|||
|2.6.4.2.4 2<sup>nd</sup>bullet|||x|||

<!-- end of page 10 -->

|||Clause<br>|classificatio|n||
|---|---|---|---|---|---|
|Clause number|ETCS on-<br>board<br>requirement|ETCS<br>trackside<br>requirement|Definition|Informative|Others|
|2.6.4.2.4 3<sup>rd</sup>bullet|||x|||
|2.6.4.2.4 4<sup>th</sup>bullet|||x|||
|2.6.5||||x||
|2.6.5.1||||x||
|2.6.5.1.1|||x|||
|2.6.5.1.2|||x|||
|2.6.5.1.3|||x|||
|2.6.5.1.4|||x|||
|2.6.5.1.5|||x|||
|2.6.5.1.6|||x|||
|2.6.5.1.7|||x|||
|2.6.5.1.8|||x|||
|2.6.5.1.9||||x||
|2.6.5.1.10|||x|||
|2.6.5.1.11|||x|||
|2.6.5.1.11 Figure 4||||x||
|2.6.5.1.11 Figure 5||||x||
|<br>2.6.5.2||||x||
|2.6.5.2.1|||x|||
|2.6.5.2.1 1<sup>st</sup>bullet|||x|||
|2.6.5.2.1 2<sup>nd</sup>bullet|||x|||
|2.6.5.2.1 3<sup>rd</sup>bullet|||x|||
|2.6.5.2.2|||x|||
|2.6.5.2.2 1<sup>st</sup>bullet|||x|||
|2.6.5.2.2 2<sup>nd</sup>bullet|||x|||
|2.6.5.2.3|||x|||
|2.6.5.2.3 1<sup>st</sup>bullet|||x|||
|2.6.5.2.3 1<sup>st</sup>bullet 1<sup>st</sup>||||||
|sub-bullet|||x|||
|2.6.5.2.3 1<sup>st</sup>bullet||||||
|2<sup>nd</sup>sub-bullet|||x|||
|2.6.5.2.3 2<sup>nd</sup>bullet|||x|||
|2.6.5.2.4|||x|||
|2.6.5.2.4 1<sup>st</sup>bullet|||x|||
|2.6.5.2.4 2<sup>nd</sup>bullet|||x|||
|2.6.5.2.4 3<sup>rd</sup>bullet|||x|||
|2.6.5.2.4 4<sup>th</sup>bullet|||x|||
|2.6.5.2.4 5<sup>th</sup>bullet|||x|||
|2.6.6||||x||
|2.6.6.1||||x||
|2.6.6.1.1|||x|||
|2.6.6.1.1.1||||x||
|2.6.6.1.2|||x|||
|2.6.6.1.3|||x|||
|2.6.6.1.4|||x|||
|2.6.6.1.5|||x|||

<!-- end of page 11 -->

||ETCS on-|Clause<br>ETCS|classificatio|n||
|---|---|---|---|---|---|
|Clause number|<br>board<br>requirement|<br>trackside<br>requirement|Definition|Informative|Others|
|2.6.6.1.6|||x|||
|2.6.6.1.7|||||x|
|2.6.6.1.7 Figure 6||||x||
|2.6.6.2||||x||
|2.6.6.2.1|||x|||
|2.6.6.2.1 1<sup>st</sup>bullet|||x|||
|2.6.6.2.1 2<sup>nd</sup>bullet|||x|||
|2.6.6.2.2|||x|||
|2.6.6.2.2 1<sup>st</sup>bullet|||x|||
|2.6.6.2.2 2<sup>nd</sup>bullet|||x|||
|2.6.6.2.2 3<sup>rd</sup>bullet|||x|||
|2.6.6.2.2 4<sup>th</sup>bullet|||x|||
|2.6.6.2.2 5<sup>th</sup>bullet|||x|||
|2.6.6.2.2 6<sup>th</sup>bullet|||x|||
|2.6.6.2.3|||x|||
|2.6.6.2.3 1<sup>st</sup>bullet|||x|||
|2.6.6.2.3 2<sup>nd</sup>bullet|||x|||
|2.6.6.2.4|||x|||
|2.6.6.2.4 1<sup>st</sup>bullet|||x|||
|2.6.6.2.4 2<sup>nd</sup>bullet|||x|||
|2.6.6.2.4 3<sup>rd</sup>bullet|||x|||
|2.6.6.2.4 4<sup>th</sup>bullet|||x|||
|2.6.6.2.4 5<sup>th</sup>bullet|||x|||
|2.6.6.2.4 6<sup>th</sup>bullet|||x|||
|2.6.6.2.4 7<sup>th</sup>bullet|||x|||
|2.6.7|||||x|
|2.6.8||||x||
|2.6.8.1||||x||
|2.6.8.2||||x||
|2.6.8.3 Table 1||||x||
|2.6.8.3 a)||||x||
|2.6.8.3 b)||||x||

<!-- end of page 12 -->

## **9.4.3 Chapter 3**

|||Clause<br>|classificatio|n||
|---|---|---|---|---|---|
|Clause number|ETCS on-<br>board<br>requirement|ETCS<br>trackside<br>requirement|Definition|Informative|Others|
|3.1||||x||
|3.2||||x||
|3.3||||x||
|3.3.1||||x||
|3.3.1.1||||x||
|3.3.1.2||||x||
|3.3.1.3||||x||
|3.3.1.4||||x||
|3.4||||x||
|3.4.1||||x||
|3.4.1.1|||x|||
|3.4.1.2|||x|||
|3.4.1.2 a)|||x|||
|3.4.1.2 b)|||x|||
|3.4.1.2 c)|||x|||
|3.4.1.3|||x|||
|3.4.2||||x||
|3.4.2.1.1|||x|||
|3.4.2.1.2|||x|||
|3.4.2.2||||x||
|3.4.2.2.1|||x|||
|3.4.2.2.1.1|x|x||||
|3.4.2.2.2|||x|||
|3.4.2.2.2 Figure 1||||x||
|3.4.2.3||||x||
|3.4.2.3.1|||x|||
|3.4.2.3.1 Figure 1a||||x||
|3.4.2.3.2||||x||
|3.4.2.3.2.1|||||x|
|3.4.2.3.2.2|x|x||||
|3.4.2.3.2.2 Figure 2||||x||
|3.4.2.3.2.3||||x||
|3.4.2.3.3||||x||
|3.4.2.3.3.1|x|||||
|3.4.2.3.3.1.1||||x||
|3.4.2.3.3.2|x|||||
|3.4.2.3.3.3|x|||||
|3.4.2.3.3.4|x|||||
|3.4.2.3.3.4 Figure2a||||x||
|3.4.2.3.3.5|x|||||
|3.4.2.3.3.6|x|x||||

<!-- end of page 13 -->

|||Clause<br>|classificatio|n||
|---|---|---|---|---|---|
|Clause number|ETCS on-<br>board<br>requirement|ETCS<br>trackside<br>requirement|Definition|Informative|Others|
|3.4.2.3.3.6.1||||x||
|3.4.2.3.3.6.1 Figure 2b||||x||
|3.4.2.3.3.7|x|||||
|3.4.2.3.3.7.1||||x||
|3.4.2.3.3.8|x|||||
|3.4.2.3.3.8.1||||x||
|3.4.2.4||||x||
|3.4.2.4.1|x|||||
|3.4.3||||x||
|3.4.3.1||||x||
|3.4.3.2||||x||
|3.4.3.2 a)||||x||
|3.4.3.2 b)||||x||
|3.4.3.2 c)||||x||
|3.4.3.2.1|||||x|
|3.4.3.2.2||||x||
|3.4.3.3||x||||
|3.4.4||||x||
|3.4.4.1||||x||
|3.4.4.1.1||||x||
|3.4.4.1.1 1<sup>st</sup>bullet||||x||
|3.4.4.1.1 2<sup>nd</sup>bullet||||x||
|3.4.4.1.1 3<sup>rd</sup>bullet||||x||
|3.4.4.1.2|||x|||
|3.4.4.1.2.1||||x||
|3.4.4.2||||x||
|3.4.4.2.1||x||||
|3.4.4.2.1 a)||x||||
|3.4.4.2.1 b)||x||||
|3.4.4.2.1 c)||x||||
|3.4.4.2.1 d)||x||||
|3.4.4.2.1 e)||x||||
|3.4.4.2.1.1|||x|||
|3.4.4.2.1.1 a)|||x|||
|3.4.4.2.1.1 b)|||x|||
|3.4.4.2.1.1 c)|||x|||
|3.4.4.2.2||x||||
|3.4.4.2.2.1|||||x|
|3.4.4.2.2.2||||x||
|3.4.4.2.2.3||||x||
|3.4.4.2.3||x||||
|3.4.4.2.3 a)||x||||
|3.4.4.2.3 b)||x||||

<!-- end of page 14 -->

|||Clause<br>|classificatio|n||
|---|---|---|---|---|---|
|Clause number|ETCS on-<br>board<br>requirement|ETCS<br>trackside<br>requirement|Definition|Informative|Others|
|3.4.4.2.3 c)||x||||
|3.4.4.3||||x||
|3.4.4.3.1|||x|||
|3.4.4.3.2||x||||
|3.4.4.3.3||x||||
|3.4.4.4||||x||
|3.4.4.4.1|||x|||
|3.4.4.4.2|x|||||
|3.4.4.4.2.1|x|||||
|3.4.4.4.2.1 a)|x|||||
|3.4.4.4.2.1 b)|x|||||
|3.4.4.4.2.1 c)|x|||||
|3.4.4.4.2.2|x|||||
|3.4.4.4.3|x|||||
|3.4.4.4.3 1<sup>st</sup>bullet|x|||||
|3.4.4.4.3 2<sup>nd</sup>bullet|x|||||
|3.4.4.4.3.1|||x|||
|3.4.4.4.3.2|x|||||
|3.4.4.4.4|x|||||
|3.4.4.4.5|x|||||
|3.4.4.4.5.1|x|||||
|3.4.4.4.6|x|||||
|3.4.4.4.6 a)|x|||||
|3.4.4.4.6 b)|x|||||
|3.4.4.4.6 c)|x|||||
|3.4.4.4.6.1|x|||||
|3.4.4.4.6.2||||x||
|3.4.4.4.7|x|||||
|3.4.4.5||||x||
|3.4.4.5.1|x|||||
|3.4.5||||x||
|3.4.5.1||||x||
|3.4.5.1.1||||x||
|3.4.5.1.2||||x||
|3.4.5.1.3|||x|||
|3.4.5.1.3 1<sup>st</sup>bullet|||x|||
|3.4.5.1.3 2<sup>nd</sup>bullet|||x|||
|3.4.5.1.3 3<sup>rd</sup>bullet|||x|||
|3.4.5.1.3 4<sup>th</sup>bullet|||x|||
|3.4.5.1.3 5<sup>th</sup>bullet|||x|||
|3.4.5.1.4|x|||||
|3.4.5.1.5|||x|||
|3.4.5.1.6|x|||||

<!-- end of page 15 -->

|||Clause<br>|classificatio|n||
|---|---|---|---|---|---|
|Clause number|ETCS on-<br>board<br>requirement|ETCS<br>trackside<br>requirement|Definition|Informative|Others|
|3.4.5.2||||x||
|3.4.5.2.1|x|||||
|3.4.5.2.2|x|||||
|3.4.5.2.3||||x||
|3.4.5.2.3 a)||||x||
|3.4.5.2.3 b)||||x||
|3.5||||x||
|3.5.1||||x||
|3.5.1.1||||x||
|3.5.1.2||||x||
|3.5.2||||x||
|3.5.2.1|||x|||
|3.5.2.2||||x||
|3.5.2.3||||x||
|3.5.2.4|x|||||
|3.5.2.5||||x||
|3.5.2.6||||x||
|3.5.2.6.1|||x|||
|3.5.2.6.1 a)|||x|||
|3.5.2.6.1 b)|||x|||
|3.5.2.6.1 c)|||x|||
|3.5.2.6.1 d)|||x|||
|3.5.2.6.2|||x|||
|3.5.2.6.2 a)|||x|||
|3.5.2.6.2 b)|||x|||
|3.5.2.6.2 c)|||x|||
|3.5.2.6.3|||x|||
|3.5.2.6.3 a)|||x|||
|3.5.2.6.3 b)|||x|||
|3.5.2.6.3 c)|||x|||
|3.5.2.6.4|||x|||
|3.5.2.6.4 a)|||x|||
|3.5.2.6.4 b)|||x|||
|3.5.2.6.4 c)|||x|||
|3.5.3||||x||
|3.5.3.1|||||x|
|3.5.3.2|||||x|
|3.5.3.3|||||x|
|3.5.3.4|x|||||
|3.5.3.4 a)|x|||||
|3.5.3.4 b)|x|||||
|3.5.3.4 c)|x|||||
|3.5.3.4 d)|x|||||

<!-- end of page 16 -->

|||Clause<br>|classificatio|n||
|---|---|---|---|---|---|
|Clause number|ETCS on-<br>board<br>requirement|ETCS<br>trackside<br>requirement|Definition|Informative|Others|
|3.5.3.4 e)|x|||||
|3.5.3.4 f)|x|||||
|3.5.3.4 g)|x|||||
|3.5.3.4 h)|x|||||
|3.5.3.4.1|x|||||
|3.5.3.4.1 1<sup>st</sup>bullet|x|||||
|3.5.3.4.1 2<sup>nd</sup>bullet|x|||||
|3.5.3.4.2|x|||||
|3.5.3.5|||||x|
|3.5.3.5.1|||||x|
|3.5.3.5.2|x|||||
|3.5.3.5.2.1|x|||||
|3.5.3.5.3|||||x|
|3.5.3.6|||||x|
|3.5.3.7|x|x||||
|3.5.3.7 a)|x|||||
|3.5.3.7 b)|x|||||
|3.5.3.7 c)||x||||
|3.5.3.7 d)|x|||||
|3.5.3.7 d) 1<sup>st</sup>bullet|x|||||
|3.5.3.7 d) 2<sup>nd</sup>bullet|x|||||
|3.5.3.7 e)||x||||
|3.5.3.7.1|x|||||
|3.5.3.7.1 1)|x|||||
|3.5.3.7.1 2)|x|||||
|3.5.3.7.1 3)|x|||||
|3.5.3.7.2|x|||||
|3.5.3.7.3|x|||||
|3.5.3.7.4|x|||||
|3.5.3.7.4.1|x|||||
|3.5.3.7.5||x||||
|3.5.3.8|x|||||
|3.5.3.8 a)|x|||||
|3.5.3.8 b)|x|||||
|3.5.3.8 c)|x|||||
|<br>3.5.3.8 d)|x|||||
|3.5.3.8 e)|x|||||
|<br>3.5.3.8 f)|x|||||
|3.5.3.8 g)|x|||||
|3.5.3.8 h)|x|||||
|3.5.3.8 i)|x|||||
|3.5.3.8 Figure 3||||x||
|3.5.3.9|||||x|

<!-- end of page 17 -->

|||Clause<br>|classificatio|n||
|---|---|---|---|---|---|
|Clause number|ETCS on-<br>board<br>requirement|ETCS<br>trackside<br>requirement|Definition|Informative|Others|
|3.5.3.9.1|||||x|
|3.5.3.10|||||x|
|3.5.3.10 Figure 4|||||x|
|3.5.3.11|x|||||
|3.5.3.11.1||||x||
|3.5.3.11.2||||x||
|3.5.3.11.3||||x||
|3.5.3.12|||||x|
|3.5.3.13|x|||||
|3.5.3.13.1|x|||||
|3.5.3.14||||x||
|3.5.3.15|x|||||
|3.5.3.15.1|||||x|
|3.5.4||||x||
|3.5.4.1|x|x||||
|3.5.4.2|x|||||
|3.5.4.2.1|x|x||||
|3.5.4.3|x|||||
|3.5.4.3 1<sup>st</sup>bullet|x|||||
|3.5.4.3 2<sup>nd</sup>bullet|x|||||
|3.5.4.3 3<sup>rd</sup>bullet|x|||||
|3.5.4.3.1||||x||
|3.5.4.4|x|||||
|3.5.4.5|x|||||
|3.5.4.6||x||||
|3.5.4.7|x|||||
|3.5.4.7.1||||x||
|3.5.5||||x||
|3.5.5.1|x|||||
|3.5.5.1 a)|x|||||
|3.5.5.1 b)|x|||||
|3.5.5.1 c)|||||x|
|3.5.5.1 d)|||||x|
|3.5.5.1 e)|||||x|
|3.5.5.1 f)|||||x|
|<br>3.5.5.2|x|||||
|3.5.5.2 a)|x|||||
|<br>3.5.5.2 b)||x||||
|3.5.5.2 c)|x|||||
|3.5.5.2 Figure 5||||x||
|3.5.5.3|x|||||
|3.5.5.3.1|x|||||
|3.5.5.3.2|x|||||

<!-- end of page 18 -->

|||Clause<br>|classificatio|n||
|---|---|---|---|---|---|
|Clause number|ETCS on-<br>board<br>requirement|ETCS<br>trackside<br>requirement|Definition|Informative|Others|
|3.5.5.4||x||||
|3.5.5.5||||x||
|3.5.5.6|x|||||
|3.5.5.7|||||x|
|3.5.6||||x||
|3.5.6.1|x|||||
|3.5.6.1 a)|x|||||
|3.5.6.1 b)|x|||||
|3.5.6.1 c)|x|||||
|3.5.6.1.1|||x|||
|3.5.6.1.1 a)|||x|||
|3.5.6.1.1 b)|||x|||
|3.5.6.1.2||||x||
|3.5.6.1.3||||x||
|3.5.6.2|x|||||
|3.5.6.3|x|||||
|3.5.6.3.1||||x||
|3.5.6.3.2||||x||
|3.5.6.4|x|||||
|3.5.6.5|x|||||
|3.5.6.5 a)|x|||||
|3.5.6.5 b)|x|||||
|3.5.6.5 c)|x|||||
|3.5.6.6|x|||||
|3.5.6.7|x|||||
|3.5.6.7 a)|x|||||
|3.5.6.7 b)|x|||||
|3.5.6.7 c)|x|||||
|3.5.6.7 d)|x|||||
|3.5.6.8|x|||||
|3.5.7||||x||
|3.5.7.1|x|||||
|3.5.7.2|x|||||
|3.5.7.2.1||||x||
|3.5.7.3|x|||||
|3.5.7.3 a)|x|||||
|3.5.7.3 b)|x|||||
|3.5.7.4|x|||||
|3.5.7.5|x|||||
|3.5.7.5 Table 1|x|||||
|3.5.7.5 Table 2|x|||||
|3.5.7.6|x|||||
|3.5.7.6 a)|x|||||

<!-- end of page 19 -->

|||Clause<br>|classificatio|n||
|---|---|---|---|---|---|
|Clause number|ETCS on-<br>board<br>requirement|ETCS<br>trackside<br>requirement|Definition|Informative|Others|
|3.5.7.6 b)|x|||||
|3.5.7.6.1||||x||
|3.5.7.7|x|||||
|3.6||||x||
|3.6.1||||x||
|3.6.1.1|||x|||
|3.6.1.1 a)|||x|||
|3.6.1.1 b)|||x|||
|3.6.1.2||||x||
|3.6.1.2 Figure 6||||x||
|3.6.1.2 Figure 7||||x||
|3.6.1.3|||x|||
|3.6.1.3 1<sup>st</sup>bullet|||x|||
|3.6.1.3 2<sup>nd</sup>bullet|||x|||
|3.6.1.3 3<sup>rd</sup>bullet|||x|||
|3.6.1.3 3<sup>rd</sup>bullet 1<sup>st</sup>hyphen|||x|||
|3.6.1.3 3<sup>rd</sup>bullet 2<sup>nd</sup>hyphen|||x|||
|3.6.1.3 3<sup>rd</sup>bullet 3<sup>rd</sup>hyphen|||x|||
|3.6.1.3 last sentence|||x|||
|3.6.1.3.1||||x||
|3.6.1.3.2|||x|||
|3.6.1.3.3||||x||
|3.6.1.3.4|||x|||
|3.6.1.4|x|||||
|3.6.1.4.1|||||x|
|3.6.1.5|x|||||
|3.6.1.5.1|x|||||
|3.6.1.5.2||||x||
|3.6.1.6|x|||||
|3.6.1.7|x|||||
|3.6.1.7 1<sup>st</sup>bullet|x|||||
|3.6.1.7 2<sup>nd</sup>bullet|x|||||
|3.6.2||||x||
|3.6.2.1||||x||
|3.6.2.1.1||x||||
|3.6.2.1.2||x||||
|3.6.2.2||||x||
|3.6.2.2.1||x||||
|3.6.2.2.2|x|x||||
|3.6.2.2.2 a)|x|||||
|3.6.2.2.2 a) 1<sup>st</sup>bullet|x|||||
|3.6.2.2.2 a) 2<sup>nd</sup>bullet|x|||||
|3.6.2.2.2 b)||x||||

<!-- end of page 20 -->

|||Clause<br>|classificatio|n||
|---|---|---|---|---|---|
|Clause number|ETCS on-<br>board<br>requirement|ETCS<br>trackside<br>requirement|Definition|Informative|Others|
|3.6.2.2.2 c)|x|||||
|3.6.2.2.2.1|x|||||
|3.6.2.2.2.2||x||||
|3.6.2.2.2.3|x|||||
|3.6.2.2.3||||x||
|3.6.2.2.3 Figure 8||||x||
|3.6.2.2.3.1||||x||
|3.6.2.3||||x||
|3.6.2.3.1||x||||
|3.6.2.3.1.1||||x||
|3.6.2.3.1.1 1<sup>st</sup>bullet||||x||
|3.6.2.3.1.1 1<sup>st</sup>bullet Figure 9||||x||
|3.6.2.3.1.1 2<sup>nd</sup>bullet||||x||
|3.6.2.3.1.1 2<sup>nd</sup>bullet Figure 10||||x||
|3.6.2.3.1.2||||x||
|3.6.2.3.1.2 1<sup>st</sup>bullet||||x||
|3.6.2.3.1.2 2<sup>nd</sup>bullet||||x||
|3.6.2.3.1.2 3<sup>rd</sup>bullet||||x||
|3.6.2.4|||||x|
|3.6.3||||x||
|3.6.3.1||||x||
|3.6.3.1.1||x||||
|3.6.3.1.1 a)||x||||
|3.6.3.1.1 b)||x||||
|3.6.3.1.1 c)||x||||
|3.6.3.1.2||x||||
|3.6.3.1.2 a)||x||||
|3.6.3.1.2 b)||x||||
|3.6.3.1.2 c)||x||||
|3.6.3.1.2.1|||||x|
|3.6.3.1.3|x|||||
|3.6.3.1.3.1|x|||||
|3.6.3.1.3.2|x|||||
|3.6.3.1.4|x|||||
|3.6.3.1.4.1|x|||||
|3.6.3.1.4.2||||x||
|3.6.3.1.4.2 Figure 11|||||x|
|3.6.3.2||||x||
|3.6.3.2.1||x||||
|3.6.3.2.1 Figure 12|||x|||
|3.6.3.2.2|x|x||||
|3.6.3.2.2 a)|x|x||||
|3.6.3.2.2 b)|x|x||||

<!-- end of page 21 -->

|||Clause<br>|classificatio|n||
|---|---|---|---|---|---|
|Clause number|ETCS on-<br>board<br>requirement|ETCS<br>trackside<br>requirement|Definition|Informative|Others|
|3.6.3.2.2 c)|x|x||||
|3.6.3.2.2 d)|x|x||||
|3.6.3.2.2 e)|x|x||||
|3.6.3.2.3|x|x||||
|3.6.3.2.3 a)|x|x||||
|3.6.3.2.3 b)|x|x||||
|3.6.3.2.3 c)|x|x||||
|3.6.3.2.4|x|x||||
|3.6.3.2.4 a)|x|x||||
|3.6.3.2.4 b)|x|x||||
|3.6.3.2.4 c)|x|x||||
|3.6.3.2.4 d)||||x||
|3.6.3.2.5||x||||
|3.6.3.2.5.1||||x||
|3.6.3.2.5.1 Figure 13||||x||
|3.6.3.2.6|x|x||||
|3.6.3.2.6 a)|x|x||||
|3.6.3.2.6 b)|x|x||||
|3.6.3.2.6 c)|x|x||||
|3.6.4||||x||
|3.6.4.1||||x||
|3.6.4.1.1|||x|||
|3.6.4.1.1 a)|||x|||
|3.6.4.1.1 b)|||x|||
|3.6.4.1.2||||x||
|3.6.4.1.3|x|||||
|3.6.4.1.4|x|||||
|3.6.4.1.5|x|||||
|3.6.4.1.5 a)|x|||||
|3.6.4.1.5 b)|x|||||
|3.6.4.1.5 last sentence|x|||||
|3.6.4.1.4 Figure 13a||||x||
|3.6.4.2||||x||
|3.6.4.2.1|||x|||
|3.6.4.2.2|x|||||
|3.6.4.2.2 a)|x|||||
|3.6.4.2.2 b)|x|||||
|<br>3.6.4.2.2.1|x|||||
|3.6.4.2.2.2|x|||||
|3.6.4.2.2.3||||x||
|3.6.4.2.3|x|||||
|3.6.4.2.4|x|||||
|3.6.4.2.4 Table 2a|x|||||

<!-- end of page 22 -->

|||Clause<br>|classificatio|n||
|---|---|---|---|---|---|
|Clause number|ETCS on-<br>board<br>requirement|ETCS<br>trackside<br>requirement|Definition|Informative|Others|
|3.6.4.2.4.1||||x||
|3.6.4.2.4.2||||x||
|3.6.4.2.4.3||||x||
|3.6.4.2.5|x|||||
|3.6.4.2.5 a)|x|||||
|3.6.4.2.5 b)|x|||||
|3.6.4.2.5 b) 1<sup>st</sup>bullet|x|||||
|3.6.4.2.5 b) 2<sup>nd</sup>bullet|x|||||
|3.6.4.2.5 b) 3<sup>rd</sup>bullet|x|||||
|3.6.4.2.5 c)|x|||||
|3.6.4.2.5 c) 1<sup>st</sup>bullet|x|||||
|3.6.4.2.5 c) 2<sup>nd</sup>bullet|x|||||
|3.6.4.2.5 c) 3<sup>rd</sup>bullet|x|||||
|3.6.4.2.5.1||||x||
|3.6.4.2.5.2||||x||
|3.6.4.2.5.3||||x||
|3.6.4.2.5.4||||x||
|3.6.4.2.5.5||||x||
|3.6.4.2.6|x|||||
|3.6.4.2.6 1<sup>st</sup>bullet|x|||||
|3.6.4.2.6 2<sup>nd</sup>bullet|x|||||
|3.6.4.2.6 3<sup>rd</sup>bullet|x|||||
|3.6.4.2.6.1||||x||
|3.6.4.2.6.1 Figure 13b||||x||
|3.6.4.2.6.1 Figure 13c||||x||
|3.6.4.2.6.1 Figure 13d||||x||
|3.6.4.2.6.1 Figure 13e||||x||
|3.6.5||||x||
|3.6.5.1||||x||
|3.6.5.1.1|||x|||
|3.6.5.1.1.1|||||x|
|3.6.5.1.2|x|||||
|3.6.5.1.2 a)|x|||||
|3.6.5.1.2 b)|x|||||
|3.6.5.1.2 c)|x|||||
|<br>3.6.5.1.2 d)|x|||||
|3.6.5.1.2 e)|x|||||
|<br>3.6.5.1.2 f)|x|||||
|3.6.5.1.2 g)|x|||||
|3.6.5.1.2 h)|x|||||
|3.6.5.1.2 i)|x|||||
|3.6.5.1.2 Figure 14||||x||
|3.6.5.1.3||||x||

<!-- end of page 23 -->

|||Clause<br>|classificatio|n||
|---|---|---|---|---|---|
|Clause number|ETCS on-<br>board<br>requirement|ETCS<br>trackside<br>requirement|Definition|Informative|Others|
|3.6.5.1.4|x|||||
|3.6.5.1.4 a)|x|||||
|3.6.5.1.4 b)|x|||||
|3.6.5.1.4 c)|x|||||
|3.6.5.1.4 d)|x|||||
|3.6.5.1.4 e)|x|||||
|3.6.5.1.4 f)|x|||||
|3.6.5.1.4 g)|x|||||
|3.6.5.1.4 h)|x|||||
|3.6.5.1.4 i)|x|||||
|3.6.5.1.4 j)|x|||||
|3.6.5.1.4 k)|x|||||
|3.6.5.1.4 l)|x|||||
|3.6.5.1.4.1|x|||||
|3.6.5.1.5||x||||
|3.6.5.1.5 a)||x||||
|3.6.5.1.5 b)||x||||
|3.6.5.1.5 c)||x||||
|3.6.5.1.5 d)||x||||
|3.6.5.1.5 e)||x||||
|3.6.5.1.5.1||x||||
|3.6.5.1.6|x|||||
|3.6.5.1.7|x|||||
|3.6.5.1.8|x|||||
|3.6.5.1.8.1||||x||
|3.6.5.2||||x||
|3.6.5.2.1||||x||
|3.6.5.2.2|x|||||
|3.6.5.2.3|x|||||
|3.6.5.2.3 a)|x|||||
|3.6.5.2.3 a) 1<sup>st</sup>bullet|x|||||
|3.6.5.2.3 a) 2<sup>nd</sup>bullet|x|||||
|3.6.5.2.3 a) 3<sup>rd</sup>bullet|x|||||
|3.6.5.2.3 a) 4<sup>th</sup>bullet|x|||||
|3.6.5.2.3 b)|x|||||
|3.6.5.2.4|x|||||
|3.6.5.2.4.1||||x||
|3.6.5.2.4 Figure 15||||x||
|3.6.5.2.5|x|||||
|3.6.5.2.5 Table 2a|x|||||
|3.6.5.2.5 Table 2b|x|||||
|3.6.5.2.6|x|||||
|3.6.5.2.7||||x||

<!-- end of page 24 -->

|||Clause<br>|classificatio|n||
|---|---|---|---|---|---|
|Clause number|ETCS on-<br>board<br>requirement|ETCS<br>trackside<br>requirement|Definition|Informative|Others|
|3.6.5.2.8||||x||
|3.6.5.2.9||||x||
|3.6.6||||x||
|3.6.6.1|x|||||
|3.6.6.2|x|||||
|3.6.6.3|x|||||
|3.6.6.4||x||||
|3.6.6.4 a)||x||||
|3.6.6.4 b)||x||||
|3.6.6.4 c)||x||||
|3.6.6.4.1|x|||||
|3.6.6.4.2|x|||||
|3.6.6.4.3|x|||||
|3.6.6.5|x|||||
|3.6.6.6||||x||
|3.6.6.7|x|||||
|3.6.6.8|||||x|
|3.6.6.9|x|||||
|3.6.6.9 a)|x|||||
|3.6.6.9 b)|x|||||
|3.6.6.9 c)|x|||||
|3.6.6.9 d)|x|||||
|3.6.6.9.1|x|||||
|3.6.6.10||x||||
|3.6.6.10 1<sup>st</sup>bullet||x||||
|3.6.6.10 2<sup>nd</sup>bullet||x||||
|3.6.6.10 3<sup>rd</sup>bullet||x||||
|3.6.6.10 4<sup>th</sup>bullet||x||||
|3.6.6.10 Figure 16||||x||
|3.6.7||||x||
|3.6.7.1|x|||||
|3.6.7.1 a)|x|||||
|3.6.7.1 b)|x|||||
|3.6.7.1 c)|x|||||
|3.6.7.1 d)|x|||||
|3.6.7.1 e)|x|||||
|3.6.7.1 f)|x|||||
|3.6.7.1 g)|x|||||
|3.6.7.2|x|||||
|3.6.7.3|x|||||
|3.6.7.3 a)|x|||||
|3.6.7.3 b)|x|||||
|3.6.7.3 c)|x|||||

<!-- end of page 25 -->

|||Clause<br>|classificatio|n||
|---|---|---|---|---|---|
|Clause number|ETCS on-<br>board<br>requirement|ETCS<br>trackside<br>requirement|Definition|Informative|Others|
|3.6.7.3.1||||x||
|3.6.7.3.2||||x||
|3.6.7.4|x|||||
|3.6.7.5|x|||||
|3.6.8||||x||
|3.6.8.1||||x||
|3.6.8.1.1||||x||
|3.6.8.2|x|||||
|3.6.8.3|x|||||
|3.6.8.4|x|||||
|3.6.8.5|x|||||
|3.6.8.5.1||||x||
|3.6.8.6|x|||||
|3.6.8.6.1||||x||
|3.6.8.6.2|x|||||
|3.6.8.7|x|||||
|3.6.8.7.1||||x||
|3.6.8.8|x|||||
|3.7||||x||
|3.7.1||||x||
|3.7.1.1||x||||
|3.7.1.1 a)||x||||
|3.7.1.1 b)||x||||
|3.7.1.1 c)||x||||
|3.7.1.1 c) 1<sup>st</sup>bullet||x||||
|3.7.1.1 c) 2<sup>nd</sup>bullet||x||||
|3.7.1.1 c) 3<sup>rd</sup>bullet||x||||
|3.7.1.1 c) 4<sup>th</sup>bullet||x||||
|3.7.1.1 c) 5<sup>th</sup>bullet||x||||
|3.7.1.1 c) 6<sup>th</sup>bullet||x||||
|3.7.1.1 c) 7<sup>th</sup>bullet||x||||
|3.7.1.1 c) 8<sup>th</sup>bullet||x||||
|3.7.1.1 d)||x||||
|3.7.2||||x||
|3.7.2.1||x||||
|3.7.2.1 1<sup>st</sup>bullet||x||||
|3.7.2.1 2<sup>nd</sup>bullet||x||||
|3.7.2.2||x||||
|3.7.2.2.1||x||||
|3.7.2.3|x|||||
|3.7.2.3.1|||x|||
|3.7.2.3.2|||x|||
|3.7.2.4||x||||

<!-- end of page 26 -->

|||Clause<br>|classificatio|n||
|---|---|---|---|---|---|
|Clause number|ETCS on-<br>board<br>requirement|ETCS<br>trackside<br>requirement|Definition|Informative|Others|
|3.7.2.4 1<sup>st</sup>bullet||x||||
|3.7.2.4 2<sup>nd</sup>bullet||x||||
|3.7.2.4 3<sup>rd</sup>bullet||x||||
|3.7.2.4 4<sup>th</sup>bullet||x||||
|3.7.2.4 5<sup>th</sup>bullet||x||||
|3.7.2.4 6<sup>th</sup>bullet||x||||
|3.7.2.4 7<sup>th</sup>bullet||x||||
|3.7.2.4 8<sup>th</sup>bullet||x||||
|3.7.3||||x||
|3.7.3.1|x|||||
|3.7.3.1 a)|x|||||
|3.7.3.1 b)|x|||||
|3.7.3.1 c)|x|||||
|3.7.3.1 d)|x|||||
|3.7.3.1 e)|x|||||
|3.7.3.1 f)|x|||||
|3.7.3.1 g)|x|||||
|3.7.3.1 h)|x|||||
|3.7.3.1 i)|x|||||
|3.7.3.1 j)|x|||||
|3.7.3.1 k)|x|||||
|3.7.3.1 l)|x|||||
|3.7.3.1 m)|x|||||
|3.7.3.1 n)|x|||||
|3.7.3.1 o)|x|||||
|3.7.3.1 p)|x|||||
|3.7.3.1.1|x|||||
|3.7.3.1.2|x|||||
|3.7.3.1.3|x|||||
|3.7.3.1.4|x|||||
|3.7.3.2|x|||||
|3.7.3.2 a)|x|||||
|3.7.3.2 b)|x|||||
|3.7.3.2 c)|x|||||
|3.7.3.2 d)|x|||||
|<br>3.7.3.2 e)|x|||||
|3.7.3.3|x|||||
|3.7.3.4|x|||||
|3.7.3.4 a)|x|||||
|3.7.3.4 b)|x|||||
|3.7.3.5|||||x|
|3.7.3.6||||x||
|3.8||||x||

<!-- end of page 27 -->

|||Clause<br>|classificatio|n||
|---|---|---|---|---|---|
|Clause number|ETCS on-<br>board<br>requirement|ETCS<br>trackside<br>requirement|Definition|Informative|Others|
|3.8.1||||x||
|3.8.1.1|||x|||
|3.8.1.1 a)|||x|||
|3.8.1.1 b)|||x|||
|3.8.1.1 c)|||x|||
|3.8.1.1 d)|||x|||
|3.8.1.1 e)|||x|||
|3.8.1.1 f)|||x|||
|3.8.1.1 f) 1<sup>st</sup>bullet|||x|||
|3.8.1.1 f) 2<sup>nd</sup>bullet|||x|||
|3.8.1.2||x||||
|3.8.1.3||||x||
|3.8.1.3 1<sup>st</sup>bullet||||x||
|3.8.1.3 2<sup>nd</sup>bullet||||x||
|3.8.1.3 3<sup>rd</sup>bullet||||x||
|3.8.1.4||||x||
|3.8.1.5||||x||
|3.8.1.5 a)||||x||
|3.8.1.5 b)||||x||
|3.8.1.5 c)||||x||
|3.8.1.6||||x||
|3.8.2||||x||
|3.8.2.1||||x||
|3.8.2.1.1||||x||
|3.8.2.1.1 a)||||x||
|3.8.2.1.1 b)||||x||
|3.8.2.1.1 c)||||x||
|3.8.2.1.1 d)||||x||
|3.8.2.1.1 e)||||x||
|3.8.2.1.2||x||||
|3.8.2.1.2 a)||x||||
|3.8.2.1.2 b)||x||||
|3.8.2.1.3||||x||
|3.8.2.1.4|x|||||
|3.8.2.1.4.1||||x||
|3.8.2.1.5|x|||||
|3.8.2.1.6|x|||||
|3.8.2.1.7|x|||||
|3.8.2.2||||x||
|3.8.2.2.1|||x|||
|3.8.2.2.1 a)|||x|||
|3.8.2.2.1 b)|||x|||
|3.8.2.2.2|x|||||

<!-- end of page 28 -->

|||Clause<br>|classificatio|n||
|---|---|---|---|---|---|
|Clause number|ETCS on-<br>board<br>requirement|ETCS<br>trackside<br>requirement|Definition|Informative|Others|
|3.8.2.2.3|x|||||
|3.8.2.2.4|x|||||
|3.8.2.3||||x||
|3.8.2.3.1|x|||||
|3.8.2.3.2|x|||||
|3.8.2.3.2 a)|x|||||
|3.8.2.3.2 b)|x|||||
|3.8.2.3.2 c)|x|||||
|3.8.2.4||||x||
|3.8.2.4.1|x|||||
|3.8.2.4.2|x|||||
|3.8.2.4.3|x|||||
|3.8.2.5||||x||
|3.8.2.5.1|x|||||
|3.8.2.5.2|x|||||
|3.8.3||||x||
|3.8.3.1|||x|||
|3.8.3.2||x||||
|3.8.3.2 a)||x||||
|3.8.3.2 b)||x||||
|3.8.3.3||x||||
|3.8.3.3 a)||x||||
|3.8.3.3 b)||x||||
|3.8.3.3 c)||x||||
|3.8.3.3 Figure 17||||x||
|3.8.3.3.1||||x||
|3.8.3.4||x||||
|3.8.3.4.1||||x||
|3.8.3.5|||||x|
|3.8.3.5.1|||||x|
|3.8.3.6||x||||
|3.8.3.7||x||||
|3.8.3.7.1||||x||
|3.8.3.8||||x||
|3.8.3.9||x||||
|3.8.3.10||x||||
|3.8.3.10.1||||x||
|3.8.3.10.1 Figure 18||||x||
|3.8.3.10.1 Figure 19||||x||
|3.8.3.11|||||x|
|3.8.3.11 Figure 20|||||x|
|3.8.4||||x||
|3.8.4.1||||x||

<!-- end of page 29 -->

|||Clause<br>|classificatio|n||
|---|---|---|---|---|---|
|Clause number|ETCS on-<br>board<br>requirement|ETCS<br>trackside<br>requirement|Definition|Informative|Others|
|3.8.4.1.1|x|||||
|3.8.4.1.2|x|||||
|3.8.4.1.2 a)|x|||||
|3.8.4.1.2 b)|x|||||
|3.8.4.1.3|x|||||
|3.8.4.1.3.1||||x||
|3.8.4.1.4|x|||||
|3.8.4.1.4.1||||x||
|3.8.4.2||||x||
|3.8.4.2.1|x|||||
|3.8.4.2.1 a)|x|||||
|3.8.4.2.1 b)|x|||||
|3.8.4.2.1.1||||x||
|3.8.4.2.2|x|||||
|3.8.4.2.2 a)|x|||||
|3.8.4.2.2 b)|x|||||
|3.8.4.2.2 c)|x|||||
|3.8.4.2.2.1||||x||
|3.8.4.2.3|x|||||
|3.8.4.2.4|x|||||
|3.8.4.2.5|x|||||
|3.8.4.2.5.1||||x||
|3.8.4.3||||x||
|3.8.4.3.1|x|||||
|3.8.4.3.1 a)|x|||||
|3.8.4.3.1 b)|x|||||
|3.8.4.3.1.1||||x||
|3.8.4.3.2|x|||||
|3.8.4.4||||x||
|3.8.4.4.1|x|||||
|3.8.4.4.2|x|||||
|3.8.4.4.2 a)|x|||||
|3.8.4.4.2 b)|x|||||
|3.8.4.4.2 c)|x|||||
|3.8.4.4.3|x|||||
|3.8.4.4.4|x|||||
|3.8.4.4.4.1||||x||
|3.8.4.4.5|x|||||
|3.8.4.4.5.1||||x||
|3.8.4.5||||x||
|3.8.4.5.1|x|||||
|3.8.4.5.1 a)|x|||||
|3.8.4.5.1 b)|x|||||

<!-- end of page 30 -->

|||Clause<br>|classificatio|n||
|---|---|---|---|---|---|
|Clause number|ETCS on-<br>board<br>requirement|ETCS<br>trackside<br>requirement|Definition|Informative|Others|
|3.8.4.5.1 c)|x|||||
|3.8.4.5.2|x|||||
|3.8.4.6||||x||
|3.8.4.6.1|||x|||
|3.8.4.6.2|x|||||
|3.8.4.6.3||x||||
|3.8.4.6.4|x|||||
|3.8.4.6.5|x|||||
|3.8.4.6.5 a)|x|||||
|3.8.4.6.5 b)|x|||||
|3.8.4.6.5 c)|x|||||
|3.8.5||||x||
|3.8.5.1|x|||||
|3.8.5.1 a)|x|||||
|3.8.5.1 b)|x|||||
|3.8.5.1.1||||x||
|3.8.5.1.2|x|||||
|3.8.5.1.3|x|||||
|3.8.5.1.4|x|||||
|3.8.5.1.5|x|||||
|3.8.5.2||x||||
|3.8.5.2.1||||x||
|3.8.5.2.2|x|||||
|3.8.5.2.3||x||||
|3.8.5.2.3.1||||x||
|3.8.5.2.4|x|||||
|3.8.5.3||||x||
|3.8.5.3.1||||x||
|3.8.5.3.2||||x||
|3.8.5.3.2 1<sup>st</sup>bullet||||x||
|3.8.5.3.2 2<sup>nd</sup>bullet||||x||
|3.8.5.3.2 Figure 21a||||x||
|3.8.5.3.2 Figure 21b||||x||
|3.8.5.3.3||||x||
|3.8.5.3.3 1<sup>st</sup>bullet||||x||
|3.8.5.3.3 2<sup>nd</sup>bullet||||x||
|3.8.5.3.3 3<sup>rd</sup>bullet||||x||
|3.8.5.3.3 Figure 22a||||x||
|3.8.5.3.3 Figure 22b||||x||
|3.8.5.3.3 Figure 22c||||x||
|3.8.5.3.4||||x||
|3.8.5.3.4 1<sup>st</sup>bullet||||x||
|3.8.5.3.4 2<sup>nd</sup>bullet||||x||

<!-- end of page 31 -->

|||Clause<br>|classificatio|n||
|---|---|---|---|---|---|
|Clause number|ETCS on-<br>board<br>requirement|ETCS<br>trackside<br>requirement|Definition|Informative|Others|
|3.8.5.3.4 Figure 23a||||x||
|3.8.5.3.4 Figure 23b||||x||
|3.8.5.3.5||||x||
|3.8.5.3.5.1||||x||
|3.8.5.3.5.2||||x||
|3.8.5.3.5.2 a)||||x||
|3.8.5.3.5.2 b)||||x||
|3.8.5.3.5.2 c)||||x||
|3.8.5.3.5.2 c) Figure 24||||x||
|3.8.5.3.5.3||||x||
|3.8.5.3.5.3 a)||||x||
|3.8.5.3.5.3 b)||||x||
|3.8.5.3.5.3 c)||||x||
|3.8.5.3.5.3 d)||||x||
|3.8.5.3.5.4||||x||
|3.8.5.3.5.4 a)||||x||
|3.8.5.3.5.4 b)||||x||
|3.8.5.3.5.4 c)||||x||
|3.8.5.3.5.4 d)||||x||
|3.8.5.3.5.4 d) Figure 25||||x||
|3.8.6||||x||
|3.8.6.1|x|x||||
|3.8.6.1 a)||x||||
|3.8.6.1 b)|x|||||
|3.8.6.1 b) 1<sup>st</sup>bullet|x|||||
|3.8.6.1 b) 2<sup>nd</sup>bullet|x|||||
|3.8.6.1 c)|x|||||
|3.8.6.2|x|||||
|3.9||||x||
|3.9.1||||x||
|3.9.1.1||x||||
|3.9.1.1 a)||x||||
|3.9.1.1 b)||x||||
|3.9.1.1 c)||x||||
|3.9.1.1.1|||x|||
|3.9.1.2||||x||
|3.9.1.3|x|||||
|3.9.1.4||||x||
|3.9.2||||x||
|3.9.2.1|||||x|
|3.9.2.2|||||x|
|3.9.2.3|||||x|
|3.9.2.4|||||x|

<!-- end of page 32 -->

|||Clause<br>|classificatio|n||
|---|---|---|---|---|---|
|Clause number|ETCS on-<br>board<br>requirement|ETCS<br>trackside<br>requirement|Definition|Informative|Others|
|3.9.2.5|||||x|
|3.9.2.6|||||x|
|3.9.2.7|||||x|
|3.9.2.8|||||x|
|3.9.2.9|||||x|
|3.9.2.10|||||x|
|3.9.2.11|x|||||
|3.9.2.12|||||x|
|3.9.3||||x||
|3.9.3.1||x||||
|3.9.3.2||x||||
|3.9.3.3|x|||||
|3.9.3.3 a)|||||x|
|3.9.3.3 b)|x|||||
|3.9.3.4|x|x||||
|3.9.3.5|x|||||
|3.9.3.5 a)|x|||||
|3.9.3.5 b)|x|||||
|3.9.3.5.1|||||x|
|3.9.3.5.1.1|||||x|
|3.9.3.5.2|||||x|
|3.9.3.6|x|||||
|3.9.3.6 a)|x|||||
|3.9.3.6 b)|x|||||
|3.9.3.6.1|x|||||
|3.9.3.7||x||||
|3.9.3.8||x||||
|3.9.3.8 a)||x||||
|3.9.3.8 b)||x||||
|3.9.3.8.1||x||||
|3.9.3.9|x|||||
|3.9.3.10|x|||||
|3.9.3.10 a)|x|||||
|3.9.3.10 b)|x|||||
|3.9.3.11|x|||||
|3.9.3.11 a)|x|||||
|3.9.3.11 b)|x|||||
|<br>3.9.3.11 c)|x|||||
|3.9.3.11 d)|x|||||
|3.9.3.11.1||||x||
|3.9.3.11.1 a)||||x||
|3.9.3.11.1 b)||||x||
|3.9.3.12||x||||

<!-- end of page 33 -->

|||Clause<br>|classificatio|n||
|---|---|---|---|---|---|
|Clause number|ETCS on-<br>board<br>requirement|ETCS<br>trackside<br>requirement|Definition|Informative|Others|
|3.9.3.12 a)||x||||
|3.9.3.12 b)||x||||
|3.9.3.12.1||||x||
|3.9.3.12.2||||x||
|3.9.3.12.2 Figure 25a||||x||
|3.9.3.13||x||||
|3.9.3.14|x|x||||
|3.9.3.15|x|||||
|3.9.3.16|x|||||
|3.9.3.17|||||x|
|3.10||||x||
|3.10.1||||x||
|3.10.1.1||||x||
|3.10.1.1.1|||||x|
|3.10.1.2||x||||
|3.10.1.3||x||||
|3.10.1.3.1|x|||||
|3.10.1.4|x|||||
|3.10.1.4.1|||x|||
|3.10.2||||x||
|3.10.2.1||x||||
|3.10.2.2|x|x||||
|3.10.2.2 a)|x|||||
|3.10.2.2 b)|x|||||
|3.10.2.2 b) 1<sup>st</sup>bullet|x|||||
|3.10.2.2 b) 2<sup>nd</sup>bullet|x|||||
|3.10.2.2 b) 3<sup>rd</sup>bullet|x|||||
|3.10.2.2 b) 4<sup>th</sup>bullet|x|||||
|3.10.2.2 b) last sentence|x|||||
|3.10.2.3|x|||||
|3.10.2.4|x|||||
|3.10.2.5|||||x|
|3.10.2.6|||||x|
|3.10.3||||x||
|3.10.3.1||x||||
|3.10.3.2|x|||||
|3.10.3.3|x|||||
|3.10.3.4|||||x|
|3.11||||x||
|3.11.1||||x||
|3.11.1.1|x|||||
|3.11.1.2|x|||||
|3.11.2||||x||

<!-- end of page 34 -->

|||Clause<br>|classificatio|n||
|---|---|---|---|---|---|
|Clause number|ETCS on-<br>board<br>requirement|ETCS<br>trackside<br>requirement|Definition|Informative|Others|
|3.11.2.1|||x|||
|3.11.2.2|||x|||
|3.11.2.2 a)|||x|||
|3.11.2.2 b)|||x|||
|3.11.2.2 c)|||x|||
|3.11.2.2 d)|||x|||
|3.11.2.2 e)|||x|||
|3.11.2.2 f)|||x|||
|3.11.2.2 g)|||x|||
|3.11.2.2 h)|||x|||
|3.11.2.2 i)|||x|||
|3.11.2.2 j)|||x|||
|3.11.2.2 k)|||x|||
|3.11.2.3|||x|||
|3.11.2.3 Figure 26||||x||
|3.11.2.4|x|||||
|3.11.2.5|||||x|
|3.11.2.6|||||x|
|3.11.3||||x||
|3.11.3.1.1|||x|||
|3.11.3.1.2|||x|||
|3.11.3.1.3||x||||
|3.11.3.2||||x||
|3.11.3.2.1||x||||
|3.11.3.2.1.1|||x|||
|3.11.3.2.1.1 a)|||x|||
|3.11.3.2.1.1 b)|||x|||
|3.11.3.2.1.2|||x|||
|3.11.3.2.2||x||||
|3.11.3.2.2 a)||x||||
|3.11.3.2.2 b)||x||||
|3.11.3.2.2 c)||x||||
|3.11.3.2.3|x|||||
|3.11.3.2.3 a)|x|||||
|3.11.3.2.3 b)|x|||||
|<br>3.11.3.2.3 c)|x|||||
|3.11.3.2.3.1|||||x|
|3.11.3.2.4|||||x|
|3.11.3.2.5|x|||||
|3.11.3.2.6|x|||||
|3.11.3.2.6 a)|x|||||
|3.11.3.2.6 b)|x|||||
|3.11.3.3||||x||

<!-- end of page 35 -->

|||Clause<br>|classificatio|n||
|---|---|---|---|---|---|
|Clause number|ETCS on-<br>board<br>requirement|ETCS<br>trackside<br>requirement|Definition|Informative|Others|
|3.11.3.3.1|||x|||
|3.11.3.3.2|x|||||
|3.11.3.3.3|||x|||
|3.11.4||||x||
|3.11.4.1||x||||
|3.11.4.2||x||||
|3.11.4.2.1|||||x|
|3.11.4.3|x|||||
|3.11.4.3.1||||x||
|3.11.4.4|||||x|
|3.11.4.5|x|||||
|3.11.4.6||x||||
|3.11.5||||x||
|3.11.5.1||||x||
|3.11.5.2|||x|||
|3.11.5.3||x||||
|3.11.5.4|x|||||
|3.11.5.5|x|x||||
|3.11.5.6||x||||
|3.11.5.7|x|||||
|3.11.5.8|x|||||
|3.11.5.9|x|||||
|3.11.5.10|x|||||
|3.11.5.11|||||x|
|3.11.5.12||x||||
|3.11.5.13|x|||||
|3.11.5.14|x|||||
|3.11.5.14 1<sup>st</sup>bullet|x|||||
|3.11.5.14 2<sup>nd</sup>bullet|x|||||
|3.11.5.15||||x||
|3.11.6||||x||
|3.11.6.1||x||||
|3.11.6.2|x|||||
|3.11.6.3|x|||||
|3.11.6.3.1|x|||||
|3.11.6.4|x|x||||
|3.11.6.5|x|||||
|3.11.6.5.1||||x||
|3.11.7||||x||
|3.11.7.1|x|||||
|3.11.7.1.1|x|||||
|3.11.7.1.2||||x||
|3.11.7.1.3|x|||||

<!-- end of page 36 -->

|||Clause<br>|classificatio|n||
|---|---|---|---|---|---|
|Clause number|ETCS on-<br>board<br>requirement|ETCS<br>trackside<br>requirement|Definition|Informative|Others|
|3.11.8||||x||
|3.11.8.1|x|||||
|3.11.9||||x||
|3.11.9.1||x||||
|3.11.10||||x||
|3.11.10.1|x|||||
|3.11.11||||x||
|3.11.11.1||x||||
|3.11.11.2||x||||
|3.11.11.2 1<sup>st</sup>bullet||x||||
|3.11.11.2 2<sup>nd</sup>bullet||x||||
|3.11.11.2 3<sup>rd</sup>bullet||x||||
|3.11.11.2 4<sup>th</sup>bullet||x||||
|3.11.11.3|x|||||
|3.11.11.4|x|||||
|3.11.11.4 1<sup>st</sup>bullet|x|||||
|3.11.11.4 2<sup>nd</sup>bullet|x|||||
|3.11.11.4 3<sup>rd</sup>bullet|x|||||
|3.11.11.4 4<sup>th</sup>bullet|x|||||
|3.11.11.4 5<sup>th</sup>bullet|x|||||
|3.11.11.4 6<sup>th</sup>bullet|x|||||
|3.11.11.4 7<sup>th</sup>bullet|x|||||
|3.11.11.4 8<sup>th</sup>bullet|x|||||
|3.11.11.4 9<sup>th</sup>bullet|x|||||
|3.11.11.4 10<sup>th</sup>bullet|x|||||
|3.11.11.4.1||||x||
|3.11.11.4.2||||x||
|3.11.11.5||||x||
|3.11.11.6|x|||||
|3.11.11.7|x|||||
|3.11.11.8|x|||||
|3.11.11.9|x|||||
|3.11.11.10||||x||
|3.11.11.11|x|||||
|3.11.12||||x||
|3.11.12.1||x||||
|3.11.12.2||x||||
|3.11.12.3||x||||
|3.11.12.4||x||||
|3.11.12.4 Figure 27||||x||
|3.11.12.4.1||||x||
|3.11.12.5||x||||
|3.11.12.6|x|||||

<!-- end of page 37 -->

|||Clause<br>|classificatio|n||
|---|---|---|---|---|---|
|Clause number|ETCS on-<br>board<br>requirement|ETCS<br>trackside<br>requirement|Definition|Informative|Others|
|3.12||||x||
|3.12.1||||x||
|3.12.1.1||||x||
|3.12.1.2||x||||
|3.12.1.2.1|x|||||
|3.12.1.2.1.1||||x||
|3.12.1.2.1.2|x|||||
|3.12.1.2.1.3|x|||||
|3.12.1.2.1.4|x|||||
|3.12.1.2.1.5|x|||||
|3.12.1.2.1.5.1||||x||
|3.12.1.3|||x|||
|3.12.1.3 1<sup>st</sup>bullet|||x|||
|3.12.1.3 2<sup>nd</sup>bullet|||x|||
|3.12.1.3 3<sup>rd</sup>bullet|||x|||
|3.12.1.3 4<sup>th</sup>bullet|||x|||
|3.12.1.3 5<sup>th</sup>bullet|||x|||
|3.12.1.3 6<sup>th</sup>bullet|||x|||
|3.12.1.3 7<sup>th</sup>bullet|||x|||
|3.12.1.3 8<sup>th</sup>bullet|||x|||
|3.12.1.3 9<sup>th</sup>bullet|||x|||
|3.12.1.3 10<sup>th</sup>bullet|||x|||
|3.12.1.3 11<sup>th</sup>bullet|||x|||
|3.12.1.3 12<sup>th</sup>bullet|||x|||
|3.12.1.3 13<sup>th</sup>bullet|||x|||
|3.12.1.3 14<sup>th</sup>bullet|||x|||
|3.12.1.3 15<sup>th</sup>bullet|||x|||
|3.12.1.3.1||||x||
|3.12.1.3.2||||x||
|3.12.1.3.3||||x||
|3.12.1.4|||||x|
|3.12.1.5|x|||||
|3.12.1.5 a)|x|||||
|3.12.1.5 b)|x|||||
|3.12.1.5.1||||x||
|3.12.1.5.2||||x||
|3.12.1.6|x|||||
|3.12.2||||x||
|3.12.2.1|||x|||
|3.12.2.2||x||||
|3.12.2.3|x|||||
|3.12.2.3 a)|x|||||
|3.12.2.3 b)|x|||||

<!-- end of page 38 -->

|||Clause<br>|classificatio|n||
|---|---|---|---|---|---|
|Clause number|ETCS on-<br>board<br>requirement|ETCS<br>trackside<br>requirement|Definition|Informative|Others|
|3.12.2.3 c)|x|||||
|3.12.2.3.1|x|||||
|3.12.2.4|x|||||
|3.12.2.5|||x|||
|3.12.2.5.1|||||x|
|3.12.2.6|||||x|
|3.12.2.7|||||x|
|3.12.2.8|||||x|
|3.12.2.9||||x||
|3.12.2.9.1||||x||
|3.12.2.10|x|||||
|3.12.3||||x||
|3.12.3.1||||x||
|3.12.3.1.1||x||||
|3.12.3.1.2||x||||
|3.12.3.1.3||x||||
|3.12.3.1.4||x||||
|3.12.3.1.4.1|||||x|
|3.12.3.1.5|||||x|
|3.12.3.1.6|||||x|
|3.12.3.1.7|||||x|
|3.12.3.1.8|||||x|
|3.12.3.1.9||x||||
|3.12.3.1.9 1<sup>st</sup>bullet||x||||
|3.12.3.1.9 2<sup>nd</sup>bullet||x||||
|3.12.3.1.9 3<sup>rd</sup>bullet||x||||
|3.12.3.1.9 4<sup>th</sup>bullet||x||||
|3.12.3.1.9 5<sup>th</sup>bullet||x||||
|3.12.3.1.10|x|||||
|3.12.3.1.11||x||||
|3.12.3.2||||x||
|3.12.3.2.1||||x||
|3.12.3.3||||x||
|3.12.3.3.1|x|||||
|3.12.3.3.2||||x||
|3.12.3.3.3||||x||
|3.12.3.3.4||||x||
|3.12.3.3.5||||x||
|3.12.3.4||||x||
|3.12.3.4.1||x||||
|3.12.3.4.2|||x|||
|3.12.3.4.2 1<sup>st</sup>bullet|||x|||
|3.12.3.4.2 2<sup>nd</sup>bullet|||x|||

<!-- end of page 39 -->

|||Clause<br>|classificatio|n||
|---|---|---|---|---|---|
|Clause number|ETCS on-<br>board<br>requirement|ETCS<br>trackside<br>requirement|Definition|Informative|Others|
|3.12.3.4.2 3<sup>rd</sup>bullet|||x|||
|3.12.3.4.3|||x|||
|3.12.3.4.3 1<sup>st</sup>bullet|||x|||
|3.12.3.4.3 2<sup>nd</sup>bullet|||x|||
|3.12.3.4.3 3<sup>rd</sup>bullet|||x|||
|3.12.3.4.3 4<sup>th</sup>bullet|||x|||
|3.12.3.4.3.1|x|x||||
|3.12.3.4.3.1.1|x|||||
|3.12.3.4.3.1.2|x|||||
|3.12.3.4.3.1.3|x|||||
|3.12.3.4.3.1.4|x|||||
|3.12.3.4.3.2|x|x||||
|3.12.3.4.3.2 a)|x|x||||
|3.12.3.4.3.2 b)|x|x||||
|3.12.3.4.4|x|||||
|3.12.3.4.5|x|||||
|3.12.3.4.6|x|||||
|3.12.3.4.7|x|x||||
|3.12.3.4.7.1|x|||||
|3.12.3.4.7.2|x|||||
|3.12.3.4.8|||||x|
|3.12.3.5||||x||
|3.12.3.5.1||x||||
|3.12.3.5.1 1<sup>st</sup>bullet||x||||
|3.12.3.5.1 2<sup>nd</sup>bullet||x||||
|3.12.3.5.2|x|||||
|3.12.3.5.3|x|||||
|3.12.4||||x||
|3.12.4.1||x||||
|3.12.4.2|x|||||
|3.12.4.3|x|||||
|3.12.4.3.1|x|||||
|3.12.4.3.1 a)|x|||||
|3.12.4.3.1 b)|x|||||
|3.12.4.3.1 c)|x|||||
|3.12.4.4|x|||||
|3.12.4.5|||x|||
|3.12.4.6|||x|||
|3.12.4.7|x|||||
|3.12.4.7 a)|x|||||
|3.12.4.7 b)|x|||||
|3.12.4.7 c)|x|||||
|3.12.4.7.1||||x||

<!-- end of page 40 -->

|||Clause<br>|classificatio|n||
|---|---|---|---|---|---|
|Clause number|ETCS on-<br>board<br>requirement|ETCS<br>trackside<br>requirement|Definition|Informative|Others|
|3.12.4.8|||x|||
|3.12.5||||x||
|3.12.5.1||x||||
|3.12.5.2||x||||
|3.12.5.3|x|||||
|3.12.5.4||x||||
|3.12.5.5||x||||
|3.12.5.6||x||||
|3.12.5.6 a)||x||||
|3.12.5.6 b)||x||||
|3.12.5.7||x||||
|3.12.5.8|x|||||
|3.12.5.9|||x|||
|3.13||||x||
|3.13.1||||x||
|3.13.1.1|||x|||
|3.13.1.1.1<br>||||x||
|3.13.1.1.1 1<sup>st</sup>bullet||||x||
|3.13.1.1.1 2<sup>nd</sup>bullet||||x||
|3.13.1.1.1 3<sup>rd</sup>bullet||||x||
|3.13.1.2||||x||
|3.13.1.3||||x||
|3.13.1.3 Figure 28||||x||
|3.13.1.4|||x|||
|3.13.1.5|x|||||
|3.13.2||||x||
|3.13.2.1||||x||
|3.13.2.1.1||||x||
|3.13.2.1.2||||x||
|3.13.2.1.3||||x||
|3.13.2.2||||x||
|3.13.2.2.1||||x||
|3.13.2.2.1.1||||x||
|3.13.2.2.1.1 a)||||x||
|3.13.2.2.1.1 b)||||x||
|3.13.2.2.1.1 c)||||x||
|3.13.2.2.1.1 d)||||x||
|3.13.2.2.1.1 e)||||x||
|3.13.2.2.1.1 f)||||x||
|3.13.2.2.1.1 g)||||x||
|3.13.2.2.1.1 h)||||x||
|3.13.2.2.1.1 i)||||x||
|3.13.2.2.1.1 j)||||x||

<!-- end of page 41 -->

|||Clause<br>|classificatio|n||
|---|---|---|---|---|---|
|Clause number|ETCS on-<br>board<br>requirement|ETCS<br>trackside<br>requirement|Definition|Informative|Others|
|3.13.2.2.1.1 k)||||x||
|3.13.2.2.1.2||||x||
|3.13.2.2.1.2 1<sup>st</sup>bullet||||x||
|3.13.2.2.1.2 2<sup>nd</sup>bullet||||x||
|3.13.2.2.1.2 3<sup>rd</sup>bullet||||x||
|3.13.2.2.1.3|x|||||
|3.13.2.2.2||||x||
|3.13.2.2.2.1|x|||||
|3.13.2.2.2.1 Figure 29||||x||
|3.13.2.2.2.2||||x||
|3.13.2.2.3||||x||
|3.13.2.2.3.1||||x||
|3.13.2.2.3.1.1|x|||||
|3.13.2.2.3.1.2|x|||||
|3.13.2.2.3.1.3||||x||
|3.13.2.2.3.1.3 Figure 30||||x||
|3.13.2.2.3.1.3 1<sup>st</sup>bullet||||x||
|3.13.2.2.3.1.3 2<sup>nd</sup>bullet||||x||
|3.13.2.2.3.1.3 3<sup>rd</sup>bullet||||x||
|3.13.2.2.3.1.3 4<sup>th</sup>bullet||||x||
|3.13.2.2.3.1.4|x|||||
|3.13.2.2.3.1.5|x|||||
|3.13.2.2.3.1.6|x|||||
|3.13.2.2.3.1.7|x|||||
|3.13.2.2.3.1.8||||x||
|3.13.2.2.3.1.9|x|||||
|3.13.2.2.3.1.9 a)|x|||||
|3.13.2.2.3.1.9 b)|x|||||
|3.13.2.2.3.1.10|x|||||
|3.13.2.2.3.1.11||||x||
|3.13.2.2.3.2||||x||
|3.13.2.2.3.2.1||||x||
|3.13.2.2.3.2.2|x|||||
|3.13.2.2.3.2.2 Figure 31||||x||
|3.13.2.2.3.2.3|||x|||
|3.13.2.2.3.2.3 a)|||x|||
|3.13.2.2.3.2.3 b)|||x|||
|<br>3.13.2.2.3.2.3 c)|||x|||
|3.13.2.2.3.2.4|||x|||
|3.13.2.2.3.2.5|x|||||
|3.13.2.2.3.2.6||||x||
|3.13.2.2.3.2.7|||||x|
|3.13.2.2.3.2.8|x|||||

<!-- end of page 42 -->

|||Clause<br>|classificatio|n||
|---|---|---|---|---|---|
|Clause number|ETCS on-<br>board<br>requirement|ETCS<br>trackside<br>requirement|Definition|Informative|Others|
|3.13.2.2.3.2.9||||x||
|3.13.2.2.3.2.10||||x||
|3.13.2.2.4||||x||
|3.13.2.2.4.1|x|||||
|3.13.2.2.4.1 a)|x|||||
|3.13.2.2.4.1 b)|x|||||
|3.13.2.2.4.1 c)|x|||||
|3.13.2.2.4.2||||x||
|3.13.2.2.5||||x||
|3.13.2.2.5.1||||x||
|3.13.2.2.5.2||||x||
|3.13.2.2.6||||x||
|3.13.2.2.6.1|x|||||
|3.13.2.2.6.1 Table 3|x|||||
|3.13.2.2.6.2|x|||||
|3.13.2.2.6.2 Table 4|x|||||
|3.13.2.2.6.3|x|||||
|3.13.2.2.6.4|x|||||
|3.13.2.2.6.5||||x||
|3.13.2.2.6.6|x|||||
|3.13.2.2.7||||x||
|3.13.2.2.7.1|x|||||
|3.13.2.2.7.2|x|||||
|3.13.2.2.7.3|x|||||
|3.13.2.2.8||||x||
|3.13.2.2.8.1|x|||||
|3.13.2.2.9||||x||
|3.13.2.2.9.1||||x||
|3.13.2.2.9.1.1|x|||||
|3.13.2.2.9.1.2|x|||||
|3.13.2.2.9.1.3|x|||||
|3.13.2.2.9.1.4|||x|||
|3.13.2.2.9.1.5|x|||||
|3.13.2.2.9.2||||x||
|3.13.2.2.9.2.1|x|||||
|3.13.2.2.9.2.2|x|||||
|3.13.2.2.9.2.3||||x||
|3.13.2.2.9.2.3 1<sup>st</sup>bullet||||x||
|3.13.2.2.9.2.3 2<sup>nd</sup>bullet||||x||
|3.13.2.2.9.2.3 3<sup>rd</sup>bullet||||x||
|3.13.2.2.9.2.3 4<sup>th</sup>bullet||||x||
|3.13.2.2.9.2.3 Figure 32||||x||
|3.13.2.2.9.2.4|x|||||

<!-- end of page 43 -->

|||Clause<br>|classificatio|n||
|---|---|---|---|---|---|
|Clause number|ETCS on-<br>board<br>requirement|ETCS<br>trackside<br>requirement|Definition|Informative|Others|
|3.13.2.2.9.2.5|x|||||
|3.13.2.2.9.2.6|x|||||
|3.13.2.2.10||||x||
|3.13.2.2.10.1|x|||||
|3.13.2.2.11||||x||
|3.13.2.2.11.1|x|||||
|3.13.2.2.12||||x||
|3.13.2.2.12.1|x|||||
|3.13.2.2.13||||x||
|3.13.2.2.13.1|x|||||
|3.13.2.3||||x||
|3.13.2.3.1||||x||
|3.13.2.3.1.1||||x||
|3.13.2.3.1.1 a)|||x|||
|3.13.2.3.1.1 b)|||x|||
|3.13.2.3.1.1 c)|||x|||
|3.13.2.3.1.1 d)|||x|||
|3.13.2.3.1.1 e)|||x|||
|3.13.2.3.1.1 f)|||x|||
|3.13.2.3.1.1 g)|||x|||
|3.13.2.3.2||||x||
|3.13.2.3.2.1|x|||||
|3.13.2.3.3||||x||
|3.13.2.3.3.1|x|||||
|3.13.2.3.4||||x||
|3.13.2.3.4.1|x|||||
|3.13.2.3.5||||x||
|3.13.2.3.5.1|x|||||
|3.13.2.3.6||||x||
|3.13.2.3.6.1|x|||||
|3.13.2.3.6.1 a)|x|||||
|3.13.2.3.6.1 b)|x|||||
|3.13.2.3.7||||x||
|3.13.2.3.7.1||x||||
|3.13.2.3.7.2||x||||
|3.13.2.3.7.2 a)||x||||
|3.13.2.3.7.2 b)||x||||
|3.13.2.3.7.3||x||||
|3.13.2.3.7.4||x||||
|3.13.2.3.7.5||x||||
|3.13.2.3.7.6||x||||
|3.13.2.3.7.7||x||||
|3.13.2.3.7.7 a)||x||||

<!-- end of page 44 -->

|||Clause<br>|classificatio|n||
|---|---|---|---|---|---|
|Clause number|ETCS on-<br>board<br>requirement|ETCS<br>trackside<br>requirement|Definition|Informative|Others|
|3.13.2.3.7.7 b)||x||||
|3.13.2.3.7.7 c)||x||||
|3.13.2.3.7.8||x||||
|3.13.2.3.7.9||x||||
|3.13.2.3.7.10||x||||
|3.13.2.3.7.11||x||||
|3.13.2.3.7.11.1||x||||
|3.13.2.3.7.11.2||||x||
|3.13.2.3.7.11.2 1<sup>st</sup>bullet||||x||
|3.13.2.3.7.11.2 2<sup>nd</sup>bullet||||x||
|3.13.2.3.7.11.2 3<sup>rd</sup>bullet||||x||
|3.13.2.3.7.11.2 4<sup>th</sup>bullet||||x||
|3.13.2.3.7.11.2 Figure 33||||x||
|3.13.2.3.7.11.3||x||||
|3.13.2.3.7.11.3 1)||x||||
|3.13.2.3.7.11.3 2)||x||||
|3.13.2.3.7.11.3.1||||x||
|3.13.2.3.7.11.4||x||||
|3.13.2.3.7.11.5||x||||
|3.13.2.3.7.11.6||x||||
|3.13.2.3.7.12||x||||
|3.13.2.3.7.12.1||x||||
|3.13.2.3.7.12.2||||x||
|3.13.2.3.7.12.2 1<sup>st</sup>bullet||||x||
|3.13.2.3.7.12.2 2<sup>nd</sup>bullet||||x||
|3.13.2.3.7.12.2 3<sup>rd</sup>bullet||||x||
|3.13.2.3.7.12.2 4<sup>th</sup>bullet||||x||
|3.13.2.3.7.12.2 Figure 34||||x||
|3.13.2.3.7.13|x|x||||
|3.13.2.3.7.14||x||||
|3.13.3||||x||
|3.13.3.1||||x||
|3.13.3.1.1||||x||
|3.13.3.1.2||||x||
|3.13.3.2||||x||
|3.13.3.2.1|x|||||
|3.13.3.2.1 a)|x|||||
|<br>3.13.3.2.1 b)|x|||||
|3.13.3.2.1 c)|x|||||
|3.13.3.2.1.1||||x||
|3.13.3.2.2|x|||||
|3.13.3.3||||x||
|3.13.3.3.1||||x||

<!-- end of page 45 -->

|||Clause<br>|classificatio|n||
|---|---|---|---|---|---|
|Clause number|ETCS on-<br>board<br>requirement|ETCS<br>trackside<br>requirement|Definition|Informative|Others|
|3.13.3.3.1.1|x|||||
|3.13.3.3.2||||x||
|3.13.3.3.2.1|x|||||
|3.13.3.3.3||||x||
|3.13.3.3.3.1|x|||||
|3.13.3.4||||x||
|3.13.3.4.1||||x||
|3.13.3.4.1.1|x|||||
|3.13.3.4.2||||x||
|3.13.3.4.2.1|x|||||
|3.13.3.4.3||||x||
|3.13.3.4.3.1|x|||||
|3.13.3.4.4||||x||
|3.13.3.4.4.1|x|||||
|3.13.3.4.4.1 a)|x|||||
|3.13.3.4.4.1 b)|x|||||
|3.13.3.4.4.1 c)|x|||||
|3.13.4||||x||
|3.13.4.1||||x||
|3.13.4.1.1|x|||||
|3.13.4.1.1 a)|x|||||
|3.13.4.1.1 b)|x|||||
|3.13.4.1.1 Figure 35||||x||
|3.13.4.1.2|x|||||
|3.13.4.1.3|x|||||
|3.13.4.1.3 a)|x|||||
|3.13.4.1.3 b)|x|||||
|3.13.4.2||||x||
|3.13.4.2.1|x|||||
|3.13.4.3||||x||
|3.13.4.3.1|x|||||
|3.13.4.3.1.1||||x||
|3.13.4.3.1.2||||x||
|3.13.4.3.2|x|||||
|3.13.4.3.2 a)|x|||||
|3.13.4.3.2 a) 1<sup>st</sup>bullet|x|||||
|3.13.4.3.2 a) 2<sup>nd</sup>bullet|x|||||
|<br>3.13.4.3.2 b)|x|||||
|3.13.4.3.2 b) 1<sup>st</sup>bullet|x|||||
|3.13.4.3.2 b) 2<sup>nd</sup>bullet|x|||||
|3.13.5||||x||
|3.13.5.1|x|||||
|3.13.5.2|x|||||

<!-- end of page 46 -->

|||Clause<br>|classificatio|n||
|---|---|---|---|---|---|
|Clause number|ETCS on-<br>board<br>requirement|ETCS<br>trackside<br>requirement|Definition|Informative|Others|
|3.13.5.2.1||||x||
|3.13.5.3|x|||||
|3.13.5.4|x|||||
|3.13.5.5|x|||||
|3.13.6||||x||
|3.13.6.1||||x||
|3.13.6.1.1||||x||
|3.13.6.2||||x||
|3.13.6.2.1||||x||
|3.13.6.2.1.1|x|||||
|3.13.6.2.1.2|||x|||
|3.13.6.2.1.2 a)|||x|||
|3.13.6.2.1.2 b)|||x|||
|3.13.6.2.1.2 c)|||x|||
|3.13.6.2.1.2 d)|||x|||
|3.13.6.2.1.2 e)|||x|||
|3.13.6.2.1.2 f)|||x|||
|3.13.6.2.1.2 g)|||x|||
|3.13.6.2.1.2 h)|||x|||
|3.13.6.2.1.2 i)|||x|||
|3.13.6.2.1.2 j)|||x|||
|3.13.6.2.1.3|x|||||
|3.13.6.2.1.4|x|||||
|3.13.6.2.1.5|x|||||
|3.13.6.2.1.5 Figure 36||||x||
|3.13.6.2.1.6|x|||||
|3.13.6.2.1.6 a)|x|||||
|3.13.6.2.1.6 b)|x|||||
|3.13.6.2.1.7|x|||||
|3.13.6.2.1.8|x|||||
|3.13.6.2.1.8.1|x|||||
|3.13.6.2.1.8.1 Figure 37||||x||
|3.13.6.2.1.8.2|x|||||
|3.13.6.2.1.9||||x||
|3.13.6.2.1.9 Figure 38||||x||
|3.13.6.2.2||||x||
|3.13.6.2.2.1|x|||||
|3.13.6.2.2.2|||x|||
|3.13.6.2.2.2 a)|||x|||
|3.13.6.2.2.2 b)|||x|||
|3.13.6.2.2.2 c)|||x|||
|3.13.6.2.2.3|x|||||
|3.13.6.2.2.4|x|||||

<!-- end of page 47 -->

|||Clause<br>|classificatio|n||
|---|---|---|---|---|---|
|Clause number|ETCS on-<br>board<br>requirement|ETCS<br>trackside<br>requirement|Definition|Informative|Others|
|3.13.6.2.2.4.1||||x||
|3.13.6.3||||x||
|3.13.6.3.1||||x||
|3.13.6.3.1.1||||x||
|3.13.6.3.1.2|||x|||
|3.13.6.3.1.2 a)|||x|||
|3.13.6.3.1.2 b)|||x|||
|3.13.6.3.1.2 c)|||x|||
|3.13.6.3.1.3|x|||||
|3.13.6.3.1.4|x|||||
|3.13.6.3.2||||x||
|3.13.6.3.2.1||||x||
|3.13.6.3.2.2||||x||
|3.13.6.3.2.3|||x|||
|3.13.6.3.2.3 a)|||x|||
|3.13.6.3.2.3 b)|||x|||
|3.13.6.3.2.4|x|||||
|3.13.6.3.2.5|x|||||
|3.13.6.3.2.5.1||||x||
|3.13.6.4||||x||
|3.13.6.4.1||||x||
|3.13.6.4.2|||x|||
|3.13.6.4.2 a)|||x|||
|3.13.6.4.2 b)|||x|||
|3.13.6.4.2 c)|||x|||
|3.13.6.4.2 d)|||x|||
|3.13.6.4.2 e)|||x|||
|3.13.6.4.2 f)|||x|||
|3.13.6.4.3|x|||||
|3.13.6.4.4|x|||||
|3.13.7||||x||
|3.13.7.1|||x|||
|3.13.7.2|x|||||
|3.13.7.2 Figure 39||||x||
|3.13.7.2.1||||x||
|3.13.7.2.2||||x||
|3.13.8||||x||
|3.13.8.1||||x||
|3.13.8.1.1|||x|||
|3.13.8.1.2|x|||||
|3.13.8.1.3|x|||||
|3.13.8.2||||x||
|3.13.8.2.1|x|||||

<!-- end of page 48 -->

|||Clause<br>|classificatio|n||
|---|---|---|---|---|---|
|Clause number|ETCS on-<br>board<br>requirement|ETCS<br>trackside<br>requirement|Definition|Informative|Others|
|3.13.8.2.1 a)|x|||||
|3.13.8.2.1 b)|x|||||
|3.13.8.2.1 c)|x|||||
|3.13.8.2.1 d)|x|||||
|3.13.8.2.1.1||||x||
|3.13.8.2.2|x|||||
|3.13.8.2.3|x|||||
|3.13.8.3||||x||
|3.13.8.3.1|x|||||
|3.13.8.3.1 Figure 40||||x||
|3.13.8.3.2|x|||||
|3.13.8.3.3|x|||||
|3.13.8.3.3 Figure 41||||x||
|3.13.8.4||||x||
|3.13.8.4.1|x|||||
|3.13.8.4.1 Figure 42||||x||
|3.13.8.5||||x||
|3.13.8.5.1||||x||
|3.13.8.5.2|x|||||
|3.13.8.5.2 a)|x|||||
|3.13.8.5.2 b)|x|||||
|3.13.9||||x||
|3.13.9.1||||x||
|3.13.9.1.1||||x||
|3.13.9.1.1 1<sup>st</sup>bullet||||x||
|3.13.9.1.1 2<sup>nd</sup>bullet||||x||
|3.13.9.1.1 3<sup>rd</sup>bullet||||x||
|3.13.9.1.1 4<sup>th</sup>bullet||||x||
|3.13.9.1.1 5<sup>th</sup>bullet||||x||
|3.13.9.1.1 6<sup>th</sup>bullet||||x||
|3.13.9.1.2||||x||
|3.13.9.1.3||||x||
|3.13.9.2||||x||
|3.13.9.2.1|||x|||
|3.13.9.2.2|||x|||
|3.13.9.2.2 Figure 43||||x||
|<br>3.13.9.2.3|x|||||
|3.13.9.2.3 Figure 44||||x||
|3.13.9.2.4|||x|||
|3.13.9.2.5|x|||||
|3.13.9.2.6|x|||||
|3.13.9.2.7|x|||||
|3.13.9.2.8|||||x|

<!-- end of page 49 -->

|||Clause<br>|classificatio|n||
|---|---|---|---|---|---|
|Clause number|ETCS on-<br>board<br>requirement|ETCS<br>trackside<br>requirement|Definition|Informative|Others|
|3.13.9.3||||x||
|3.13.9.3.1||||x||
|3.13.9.3.1.1|||x|||
|3.13.9.3.1.2|||x|||
|3.13.9.3.1.2 Figure 45||||x||
|3.13.9.3.1.3|||x|||
|3.13.9.3.1.3 Figure 46||||x||
|3.13.9.3.1.4||||x||
|3.13.9.3.2||||x||
|3.13.9.3.2.1|x|||||
|3.13.9.3.2.2|x|||||
|3.13.9.3.2.2 a)|x|||||
|3.13.9.3.2.2 b)|x|||||
|3.13.9.3.2.3|x|||||
|3.13.9.3.2.3 a)|x|||||
|3.13.9.3.2.3 b)|x|||||
|3.13.9.3.2.4||||x||
|3.13.9.3.2.5||||x||
|3.13.9.3.2.6|x|||||
|3.13.9.3.2.7|||||x|
|3.13.9.3.2.8|x|||||
|3.13.9.3.2.9|x|||||
|3.13.9.3.2.10|x|||||
|3.13.9.3.2.11||||x||
|3.13.9.3.2.12|x|||||
|3.13.9.3.3||||x||
|3.13.9.3.3.1|x|||||
|3.13.9.3.3.2|x|||||
|3.13.9.3.3.3|x|||||
|3.13.9.3.3.4|x|||||
|3.13.9.3.3.4.1|x|||||
|3.13.9.3.3.5|x|||||
|3.13.9.3.3.6||||x||
|3.13.9.3.3.7|x|||||
|3.13.9.3.3.7 Figure 47||||x||
|3.13.9.3.3.8|x|||||
|3.13.9.3.3.8 Figure 48||||x||
|3.13.9.3.3.8.1||||x||
|3.13.9.3.3.9|||||x|
|3.13.9.3.4||||x||
|3.13.9.3.4.1|x|||||
|3.13.9.3.4.2|||x|||
|3.13.9.3.5||||x||

<!-- end of page 50 -->

|||Clause<br>|classificatio|n||
|---|---|---|---|---|---|
|Clause number|ETCS on-<br>board<br>requirement|ETCS<br>trackside<br>requirement|Definition|Informative|Others|
|3.13.9.3.5.1|x|||||
|3.13.9.3.5.2|||x|||
|3.13.9.3.5.3||||x||
|3.13.9.3.5.4|x|||||
|3.13.9.3.5.5|x|||||
|3.13.9.3.5.6|x|||||
|3.13.9.3.5.7|x|||||
|3.13.9.3.5.7 Figure 49||||x||
|3.13.9.3.5.7.1||||x||
|3.13.9.3.5.8|x|||||
|3.13.9.3.5.9|x|||||
|3.13.9.3.5.9 a)|x|||||
|3.13.9.3.5.9 b)|x|||||
|3.13.9.3.5.9 c)|x|||||
|3.13.9.3.5.9 d)|x|||||
|3.13.9.3.5.9 e)|x|||||
|3.13.9.3.5.10<br>|x|||||
|3.13.9.3.5.10.1||||x||
|3.13.9.3.5.11|x|||||
|3.13.9.3.5.12|x|||||
|3.13.9.3.5.12.1||||x||
|3.13.9.3.6||||x||
|3.13.9.3.6.1|x|||||
|3.13.9.3.6.2|x|||||
|3.13.9.3.6.3||||x||
|3.13.9.3.6.4|x|||||
|3.13.9.3.6.5|x|||||
|3.13.9.3.6.6||||x||
|3.13.9.3.6.7||||x||
|3.13.9.4||||x||
|3.13.9.4.1|||x|||
|3.13.9.4.2||||x||
|3.13.9.4.3||x||||
|3.13.9.4.3 a)||x||||
|3.13.9.4.3 b)||x||||
|3.13.9.4.3 c)||x||||
|3.13.9.4.4|x|||||
|3.13.9.4.5||||x||
|3.13.9.4.6|x|||||
|3.13.9.4.6 a)|x|||||
|3.13.9.4.6 b)|x|||||
|3.13.9.4.7|x|||||
|3.13.9.4.7 Figure 50||||x||

<!-- end of page 51 -->

|||Clause<br>|classificatio|n||
|---|---|---|---|---|---|
|Clause number|ETCS on-<br>board<br>requirement|ETCS<br>trackside<br>requirement|Definition|Informative|Others|
|3.13.9.4.8|x|||||
|3.13.9.4.8 Figure 51||||x||
|3.13.9.4.8 Figure 51a||||x||
|3.13.9.4.8.1|x|||||
|3.13.9.4.8.2|x|||||
|3.13.9.4.8.2.1||||x||
|3.13.9.4.8.2.1 a)||||x||
|3.13.9.4.8.2.1 b)||||x||
|3.13.9.4.8.2.2||||x||
|3.13.9.4.9|x|||||
|3.13.9.4.9 Figure 52||||x||
|3.13.9.4.9.1||||x||
|3.13.9.5|||||x|
|3.13.10||||x||
|3.13.10.1||||x||
|3.13.10.1.1|||x|||
|3.13.10.1.2|||x|||
|3.13.10.1.2 1<sup>st</sup>bullet|||x|||
|3.13.10.1.2 2<sup>nd</sup>bullet|||x|||
|3.13.10.1.2 3<sup>rd</sup>bullet|||x|||
|3.13.10.1.2 Figure 53||||x||
|3.13.10.1.3|||x|||
|3.13.10.1.4|||x|||
|3.13.10.1.5|||x|||
|3.13.10.2||||x||
|3.13.10.2.1|x|||||
|3.13.10.2.2|x|||||
|3.13.10.2.3|x|||||
|3.13.10.2.4|x|||||
|3.13.10.2.5|x|||||
|3.13.10.2.6|x|||||
|3.13.10.2.6 a)|x|||||
|3.13.10.2.6 b)|x|||||
|3.13.10.2.6 b) 1<sup>st</sup>bullet|x|||||
|3.13.10.2.6 b) 2<sup>nd</sup>bullet|x|||||
|3.13.10.2.6 b) 3<sup>rd</sup>bullet|x|||||
|<br>3.13.10.2.7|x|||||
|3.13.10.2.8|||x|||
|3.13.10.3||||x||
|3.13.10.3.1|x|||||
|3.13.10.3.2|x|||||
|3.13.10.3.3|x|||||
|3.13.10.3.3 Table 5|x|||||

<!-- end of page 52 -->

|||Clause<br>|classificatio|n||
|---|---|---|---|---|---|
|Clause number|ETCS on-<br>board<br>requirement|ETCS<br>trackside<br>requirement|Definition|Informative|Others|
|3.13.10.3.3 Table 6|x|||||
|3.13.10.3.4|x|||||
|3.13.10.3.4 Table 7|x|||||
|3.13.10.3.5|x|||||
|3.13.10.3.6|x|||||
|3.13.10.3.7||||x||
|3.13.10.3.8|x|||||
|3.13.10.3.8.1|x|||||
|3.13.10.3.8.2|x|||||
|3.13.10.3.9|x|||||
|3.13.10.3.9.1|x|||||
|3.13.10.3.10|x|||||
|3.13.10.3.10.1|x|||||
|3.13.10.4||||x||
|3.13.10.4.1||||x||
|3.13.10.4.2|x|||||
|3.13.10.4.2.1||||x||
|3.13.10.4.2.2||||x||
|3.13.10.4.2.3||||x||
|3.13.10.4.3|x|||||
|3.13.10.4.4|x|||||
|3.13.10.4.5|x|||||
|3.13.10.4.6|x|||||
|3.13.10.4.7|x|||||
|3.13.10.4.7.1|||||x|
|3.13.10.4.8|x|||||
|3.13.10.4.8.1|x|||||
|3.13.10.4.9|x|||||
|3.13.10.4.9 a)|x|||||
|3.13.10.4.9 b)|x|||||
|3.13.10.4.10|x|||||
|3.13.10.4.10.1|x|||||
|3.13.10.4.10.1 Table 8|x|||||
|3.13.10.4.10.1 Figure 54||||x||
|3.13.10.4.10.1 Table 9|x|||||
|3.13.10.4.10.1 Figure 55||||x||
|3.13.10.4.10.1 Table 10|x|||||
|3.13.10.4.10.1 Table 11|x|||||
|3.13.10.4.11||||x||
|3.13.10.4.12||||x||
|3.13.10.4.13|x|||||
|3.13.10.4.13.1|x|||||

<!-- end of page 53 -->

|||Clause<br>|classificatio|n||
|---|---|---|---|---|---|
|Clause number|ETCS on-<br>board<br>requirement|ETCS<br>trackside<br>requirement|Definition|Informative|Others|
|3.13.10.4.14|x|||||
|3.13.10.4.15|x|||||
|3.13.10.4.15 Table 12|x|||||
|3.13.10.4.16|x|||||
|3.13.10.4.17|x|||||
|3.13.10.4.18||||x||
|3.13.10.5||||x||
|3.13.10.5.1|x|||||
|3.13.10.5.2|x|||||
|3.13.10.5.3|x|||||
|3.13.10.5.3.1|x|||||
|3.13.10.5.4|x|||||
|3.13.10.5.4 Table 13|x|||||
|3.13.10.5.4 Table 14|x|||||
|3.13.10.5.5|x|||||
|3.13.10.5.5 Table 15|x|||||
|3.13.10.5.6|x|||||
|3.13.10.5.7|x|||||
|3.13.10.6||||x||
|3.13.10.6.1|x|||||
|3.13.10.6.1 Table 16|x|||||
|3.13.10.6.2|x|||||
|3.13.10.6.2.1||||x||
|3.13.10.6.3|x|||||
|3.13.10.6.4|x|||||
|3.13.10.6.5|x|||||
|3.13.11||||x||
|3.13.11.1||||x||
|3.13.11.2|x|||||
|3.13.11.3|x|||||
|3.13.11.3 a)|x|||||
|3.13.11.3 b)|x|||||
|3.13.11.3 c)|x|||||
|3.13.11.4|x|||||
|3.13.11.5|x|||||
|3.13.11.6|x|||||
|3.13.11.6 Figure 56||||x||
|3.13.11.7|x|||||
|3.13.11.7.1|x|||||
|3.13.11.7.1 a)|x|||||
|3.13.11.7.1 b)|x|||||
|3.13.11.7.1.1|x|||||
|3.13.11.7.1.2|x|||||

<!-- end of page 54 -->

|||Clause<br>|classificatio|n||
|---|---|---|---|---|---|
|Clause number|ETCS on-<br>board<br>requirement|ETCS<br>trackside<br>requirement|Definition|Informative|Others|
|3.13.11.8|x|||||
|3.13.11.9|x|||||
|3.13.11.10||||x||
|3.14||||x||
|3.14.1||||x||
|3.14.1.1||||x||
|3.14.1.2|x|||||
|3.14.1.3|x|||||
|3.14.1.4||||x||
|3.14.1.5|x|||||
|3.14.1.6|x|||||
|3.14.1.7|x|||||
|3.14.1.7.1|x|||||
|3.14.1.7.2|x|||||
|3.14.1.7.3|x|||||
|3.14.1.7.4|x|||||
|3.14.1.7.5|x|||||
|3.14.1.7.6|x|||||
|3.14.1.7.7||||x||
|3.14.1.8|x|||||
|3.14.1.9|x|||||
|3.14.1.10|x|||||
|3.14.1.10.1||||x||
|3.14.1.11|x|||||
|3.14.1.11.1|x|||||
|3.14.1.11.2|x|||||
|3.14.2||||x||
|3.14.2.1||||x||
|3.14.2.2|x|||||
|3.14.2.3|x|||||
|3.14.2.4|x|||||
|3.14.2.5||||x||
|3.14.2.6|x|||||
|3.14.2.7|x|||||
|3.14.3||||x||
|3.14.3.1|x|||||
|3.14.3.2|x|||||
|3.14.3.3||||x||
|3.14.3.4|x|||||
|3.14.3.5|x|||||
|3.14.3.6|x|||||
|3.14.4|||||x|
|3.15||||x||

<!-- end of page 55 -->

|||Clause<br>|classificatio|n||
|---|---|---|---|---|---|
|Clause number|ETCS on-<br>board<br>requirement|ETCS<br>trackside<br>requirement|Definition|Informative|Others|
|3.15.1||||x||
|3.15.1.1||||x||
|3.15.1.1.1||||x||
|3.15.1.1.2||||x||
|3.15.1.1.3||||x||
|3.15.1.1.4|||||x|
|3.15.1.1.5||x||||
|3.15.1.1.5.1||||x||
|3.15.1.1.5.2||||x||
|3.15.1.1.6|||x|||
|3.15.1.1.6.1|||x|||
|3.15.1.2||||x||
|3.15.1.2.1||x||||
|3.15.1.2.1.1||x||||
|3.15.1.2.1 a)|||||x|
|3.15.1.2.1 b)||x||||
|3.15.1.2.1 b) 1<sup>st</sup>bullet||x||||
|3.15.1.2.1 b) 2<sup>nd</sup>bullet||x||||
|3.15.1.2.1 b) 3<sup>rd</sup>bullet||x||||
|3.15.1.2.1 b) 4<sup>th</sup>bullet||x||||
|3.15.1.2.1 b) 5<sup>th</sup>bullet||x||||
|3.15.1.2.1 b) 6<sup>th</sup>bullet||x||||
|3.15.1.2.1 b) 7<sup>th</sup>bullet||x||||
|3.15.1.2.2|||||x|
|3.15.1.2.3||x||||
|3.15.1.2.3.1|||x|||
|3.15.1.2.3.1 a)|||x|||
|3.15.1.2.3.1 b)|||x|||
|3.15.1.2.3.1 c)|||x|||
|3.15.1.2.3.1 d)|||x|||
|3.15.1.2.3.1 e)|||x|||
|3.15.1.2.3.1 f)|||x|||
|3.15.1.2.3.1 g)|||x|||
|3.15.1.2.3.1 h)|||||x|
|3.15.1.2.3.1 i)|||x|||
|3.15.1.2.3.1 j)|||x|||
|3.15.1.2.3.1 k)|||||x|
|<br>3.15.1.2.3.1 l)|||x|||
|3.15.1.2.3.1 m)|||x|||
|3.15.1.2.3.1 n)|||x|||
|3.15.1.2.3.1 o)|||x|||
|3.15.1.2.3.1 p)|||x|||
|3.15.1.2.3.2||||x||

<!-- end of page 56 -->

|||Clause<br>|classificatio|n||
|---|---|---|---|---|---|
|Clause number|ETCS on-<br>board<br>requirement|ETCS<br>trackside<br>requirement|Definition|Informative|Others|
|3.15.1.2.4||x||||
|3.15.1.2.4.1||||x||
|3.15.1.2.5|||||x|
|3.15.1.2.6||x||||
|3.15.1.2.6.1||||x||
|3.15.1.2.7||||x||
|3.15.1.2.8||x||||
|3.15.1.2.9||x||||
|3.15.1.2.9.1||||x||
|3.15.1.2.9.1 1<sup>st</sup>bullet||||x||
|3.15.1.2.9.1 2<sup>nd</sup>bullet||||x||
|3.15.1.2.9.1 3<sup>rd</sup>bullet||||x||
|3.15.1.3||||x||
|3.15.1.3.1|x|||||
|3.15.1.3.1 a)|x|||||
|3.15.1.3.1 b)|x|||||
|3.15.1.3.1 c)|x|||||
|3.15.1.3.2|x|||||
|3.15.1.3.2 a)|x|||||
|3.15.1.3.2 b)|x|||||
|3.15.1.3.2 c)|x|||||
|3.15.1.3.2 d)|x|||||
|3.15.1.3.2 last sentence|x|||||
|3.15.1.3.2.1||||x||
|3.15.1.3.2.2|x|||||
|3.15.1.3.2.3|x|||||
|3.15.1.3.2.4|x|||||
|3.15.1.3.3|x|||||
|3.15.1.3.4|x|||||
|3.15.1.3.4.1|x|||||
|3.15.1.3.5|x|||||
|3.15.1.3.5.1|||||x|
|3.15.1.3.6|x|||||
|3.15.1.3.6.1||||x||
|3.15.1.3.7|x|||||
|3.15.1.3.8|x|||||
|3.15.1.3.8 a)|x|||||
|<br>3.15.1.3.8 b)|x|||||
|3.15.1.3.8.1||||x||
|3.15.1.3.9|x|||||
|3.15.1.4||||x||
|3.15.1.4.1||x||||
|3.15.1.4.2||x||||

<!-- end of page 57 -->

|||Clause<br>|classificatio|n||
|---|---|---|---|---|---|
|Clause number|ETCS on-<br>board<br>requirement|ETCS<br>trackside<br>requirement|Definition|Informative|Others|
|3.15.1.4.3||x||||
|3.15.1.4.4||x||||
|3.15.1.4.5||x||||
|3.15.1.4.6||x||||
|3.15.1.5||||x||
|3.15.1.5.1||x||||
|3.15.1.5.2|||x|||
|3.15.1.5.2 a)|||x|||
|3.15.1.5.2 b)|||x|||
|3.15.1.5.3||x||||
|3.15.2||||x||
|3.15.2.1||||x||
|3.15.2.2||||x||
|3.15.3||||x||
|3.15.3.1||||x||
|3.15.3.2|||x|||
|3.15.3.2.1||||x||
|3.15.3.3||||x||
|3.15.3.4||||x||
|3.15.4||||x||
|3.15.4.1||x||||
|3.15.4.1.1|x|||||
|3.15.4.2||x||||
|3.15.4.2 a)||x||||
|3.15.4.2 b)||x||||
|3.15.4.2 Figure 57||||x||
|3.15.4.2.1|x|||||
|3.15.4.2.1.1||||x||
|3.15.4.2.1.2||||x||
|3.15.4.2.1 Figure 58||||x||
|3.15.4.2.2||||x||
|3.15.4.3|x|||||
|3.15.4.3.1|||||x|
|3.15.4.3.1 Figure 59|||||x|
|3.15.4.4|x|||||
|3.15.4.5|x|||||
|3.15.4.6||||x||
|3.15.4.7|x|||||
|3.15.4.8|x|||||
|3.15.5||||x||
|3.15.5.1||||x||
|3.15.5.2|x|x||||
|3.15.5.2 a)|x|x||||

<!-- end of page 58 -->

|||Clause<br>|classificatio|n||
|---|---|---|---|---|---|
|Clause number|ETCS on-<br>board<br>requirement|ETCS<br>trackside<br>requirement|Definition|Informative|Others|
|3.15.5.2 b)|x|x||||
|3.15.5.3||||x||
|3.15.5.4|x|||||
|3.15.5.5||||x||
|3.15.5.6|x|||||
|3.15.6||||x||
|3.15.6.1||||x||
|3.15.6.2||||x||
|3.15.6.2.1|||||x|
|3.15.6.3|||||x|
|3.15.6.4|||||x|
|3.15.6.5||x||||
|3.15.6.5.1||||x||
|3.15.7||||x||
|3.15.7.1||||x||
|3.15.7.2|x|||||
|3.15.7.3||||x||
|3.15.7.4|x|||||
|3.15.7.5|x|||||
|3.15.7.6|x|||||
|3.15.7.6.1||||x||
|3.15.8||||x||
|3.15.8.1|x|||||
|3.15.8.1.1|x|||||
|3.15.8.2|x|||||
|3.15.8.3||||x||
|3.15.8.3 a)||||x||
|3.15.8.3 b)||||x||
|3.15.9||||x||
|3.15.9.1||x||||
|3.15.9.1 a)|||x|||
|3.15.9.1 b)|||x|||
|3.15.9.2|x|||||
|3.15.9.3|x|||||
|3.15.9.3 a)|x|||||
|3.15.9.3 b)||||x||
|3.15.9.3.1|x|||||
|3.15.9.4|x|||||
|3.15.9.5|x|||||
|3.15.9.5 a)|x|||||
|3.15.9.5 b)|x|||||
|3.15.9.5 c)|x|||||
|3.15.9.5 d)|x|||||

<!-- end of page 59 -->

|||Clause<br>|classificatio|n||
|---|---|---|---|---|---|
|Clause number|ETCS on-<br>board<br>requirement|ETCS<br>trackside<br>requirement|Definition|Informative|Others|
|3.15.9.6|x|||||
|3.15.10||||x||
|3.15.10.1|x|||||
|3.15.10.2|x|||||
|3.15.10.3|x|||||
|3.15.10.3.1|x|||||
|3.15.10.4|x|||||
|3.15.10.5|x|||||
|3.15.11||||x||
|3.15.11.1||||x||
|3.15.11.2|x|||||
|3.15.11.3||||x||
|3.16||||x||
|3.16.1||||x||
|3.16.1.1|x|||||
|3.16.1.1.1|x|||||
|3.16.1.2||||x||
|3.16.1.3||||x||
|3.16.1.4|x|||||
|3.16.2||||x||
|3.16.2.1||||x||
|3.16.2.1.1|||x|||
|3.16.2.1.2|||x|||
|3.16.2.1.2.1||||x||
|3.16.2.1.3|||||x|
|3.16.2.2||||x||
|3.16.2.2.1|x|||||
|3.16.2.2.2|x|||||
|3.16.2.2.2 a)|x|||||
|3.16.2.2.2 b)|x|||||
|3.16.2.2.2 c)|x|||||
|3.16.2.3||||x||
|3.16.2.3.1|x|||||
|3.16.2.3.1 a)|x|||||
|3.16.2.3.1 b)|x|||||
|<br>3.16.2.3.1 c)|x|||||
|3.16.2.3.1.1|x|||||
|3.16.2.3.1.1 a)|x|||||
|3.16.2.3.1.1 b)|x|||||
|3.16.2.3.2|||||x|
|3.16.2.3.2.1|||||x|
|3.16.2.3.3|||||x|
|3.16.2.3.4|x|||||

<!-- end of page 60 -->

|||Clause<br>|classificatio|n||
|---|---|---|---|---|---|
|Clause number|ETCS on-<br>board<br>requirement|ETCS<br>trackside<br>requirement|Definition|Informative|Others|
|3.16.2.4||||x||
|3.16.2.4.1|x|||||
|3.16.2.4.1 a)|x|||||
|3.16.2.4.1 b)|x|||||
|3.16.2.4.1 c)|||||x|
|3.16.2.4.1 d)|x|||||
|3.16.2.4.2|x|||||
|3.16.2.4.3|x|||||
|3.16.2.4.3.1|x|||||
|3.16.2.4.3.1 a)|x|||||
|3.16.2.4.3.1 b)|x|||||
|3.16.2.4.4|x|||||
|3.16.2.4.4 a)|x|||||
|3.16.2.4.4 b)|x|||||
|3.16.2.4.4 c)|||||x|
|3.16.2.4.4 d)|x|||||
|3.16.2.4.4.1|x|||||
|3.16.2.4.4.1 a)|x|||||
|3.16.2.4.4.1 a) 1<sup>st</sup>bullet|x|||||
|3.16.2.4.4.1 a) 2<sup>nd</sup>bullet|x|||||
|3.16.2.4.4.1 a) 3<sup>rd</sup>bullet|x|||||
|3.16.2.4.4.1 a) 4<sup>th</sup>bullet|x|||||
|3.16.2.4.4.1 a) 5<sup>th</sup>bullet|x|||||
|3.16.2.4.4.1 b)|x|||||
|3.16.2.4.4.2|x|||||
|3.16.2.4.4.3|x|||||
|3.16.2.4.4.4|x|||||
|3.16.2.4.5||x||||
|3.16.2.4.6||x||||
|3.16.2.4.6.1||x||||
|3.16.2.4.7|x|||||
|3.16.2.4.7.1|x|||||
|3.16.2.4.8||x||||
|3.16.2.4.8.1|x|||||
|3.16.2.4.8.2|x|||||
|3.16.2.4.8.2.1|x|||||
|3.16.2.4.9|x|||||
|3.16.2.5||||x||
|3.16.2.5.1|x|||||
|3.16.2.5.1 a)|x|||||
|3.16.2.5.1 b)|x|||||
|3.16.2.5.1 c)|||||x|
|3.16.2.5.1 d)|x|||||

<!-- end of page 61 -->

|||Clause<br>|classificatio|n||
|---|---|---|---|---|---|
|Clause number|ETCS on-<br>board<br>requirement|ETCS<br>trackside<br>requirement|Definition|Informative|Others|
|3.16.2.5.1.1|x|||||
|3.16.2.5.1.1 a)|x|||||
|3.16.2.5.1.1 a) 1<sup>st</sup>bullet|x|||||
|3.16.2.5.1.1 a) 2<sup>nd</sup>bullet|x|||||
|3.16.2.5.1.1 a) 3<sup>rd</sup>bullet|x|||||
|3.16.2.5.1.1 a) 4<sup>th</sup>bullet|x|||||
|3.16.2.5.1.1 a) 5<sup>th</sup>bullet|x|||||
|3.16.2.5.1.1 b)|x|||||
|3.16.2.5.2|x|||||
|3.16.2.5.3|x|||||
|3.16.2.6||||x||
|3.16.2.6.1|x|||||
|3.16.2.6.2|x|||||
|3.16.2.7||||x||
|3.16.2.7.1||||x||
|3.16.2.7.1.1|x|||||
|3.16.2.7.2||||x||
|3.16.2.7.2.1|x|||||
|3.16.2.7.2.1 a)|x|||||
|3.16.2.7.2.1 b)|x|||||
|3.16.2.7.2.2|x|||||
|3.16.2.7.2.3||||x||
|3.16.3||||x||
|3.16.3.1||||x||
|3.16.3.1.1|||x|||
|3.16.3.1.1 a)|||x|||
|3.16.3.1.1 b)|||x|||
|3.16.3.1.1 c)|||x|||
|3.16.3.1.1.1|||||x|
|3.16.3.1.1.2|x|||||
|3.16.3.1.2|||||x|
|3.16.3.1.3|||||x|
|3.16.3.1.3.1|||||x|
|3.16.3.1.4|||||x|
|3.16.3.2||||x||
|3.16.3.2.1||x||||
|3.16.3.2.2||x||||
|3.16.3.2.3||x||||
|3.16.3.3||||x||
|3.16.3.3.1||x||||
|3.16.3.3.2|x|x||||
|3.16.3.3.3|x|x||||
|3.16.3.3.3.1|||||x|

<!-- end of page 62 -->

|||Clause<br>|classificatio|n||
|---|---|---|---|---|---|
|Clause number|ETCS on-<br>board<br>requirement|ETCS<br>trackside<br>requirement|Definition|Informative|Others|
|3.16.3.3.3.2||||x||
|3.16.3.3.4|||||x|
|3.16.3.3.4 Figure 60||||x||
|3.16.3.4||||x||
|3.16.3.4.1|x|||||
|3.16.3.4.1.1|x|||||
|3.16.3.4.1.2|x|||||
|3.16.3.4.1.2.1|x|||||
|3.16.3.4.1.3|x|||||
|3.16.3.4.1.3 Figure 61||||x||
|3.16.3.4.1.3 Figure 62||||x||
|3.16.3.4.2||x||||
|3.16.3.4.2 a)||x||||
|3.16.3.4.2 b)||x||||
|3.16.3.4.2 c)||x||||
|3.16.3.4.3|x|||||
|3.16.3.4.4|x|||||
|3.16.3.4.5|x|||||
|3.16.3.4.5 a)|x|||||
|3.16.3.4.5 b)|x|||||
|3.16.3.4.6|||||x|
|3.16.3.4.7||x||||
|3.16.3.5||||x||
|3.16.3.5.1|x|||||
|3.16.3.5.1.1||||x||
|3.16.3.5.2|||||x|
|3.16.3.5.3|x|||||
|3.16.3.5.4|||||x|
|3.16.4||||x||
|3.16.4.1|x|||||
|3.16.4.2|||x|||
|3.16.4.3|x|||||
|3.17||||x||
|3.17.1||||x||
|3.17.1.1||||x||
|3.17.1.2||||x||
|3.17.1.3|||||x|
|3.17.2||||x||
|3.17.2.1|x|||||
|3.17.2.1.1|x|||||
|3.17.2.2|x|||||
|3.17.2.3|x|||||
|3.17.2.4||x||||

<!-- end of page 63 -->

|||Clause<br>|classificatio|n||
|---|---|---|---|---|---|
|Clause number|ETCS on-<br>board<br>requirement|ETCS<br>trackside<br>requirement|Definition|Informative|Others|
|3.17.2.5|x|||||
|3.17.2.5.1||||x||
|3.17.2.6|x|||||
|3.17.2.7|x|||||
|3.17.2.8|x|||||
|3.17.2.8 a)|x|||||
|3.17.2.8 b)|x|||||
|3.17.2.8 c)|x|||||
|3.17.2.8 d)|x|||||
|3.17.2.8 e)|x|||||
|3.17.2.8.1|x|||||
|3.17.2.8.2|x|||||
|3.17.2.9|x|||||
|3.17.2.9.1|x|||||
|3.17.3||||x||
|3.17.3.1||x||||
|3.17.3.2||x||||
|3.17.3.3|x|||||
|3.17.3.4|x|||||
|3.17.3.4.1||||x||
|3.17.3.4.2|||||x|
|3.17.3.5|x|||||
|3.17.3.5 a)|x|||||
|3.17.3.5 b)|x|||||
|3.17.3.5 c)|x|||||
|3.17.3.5 d)|x|||||
|3.17.3.5 e)|x|||||
|3.17.3.6|x|||||
|3.17.3.6 a)|x|||||
|3.17.3.6 b)|x|||||
|3.17.3.6 c)|x|||||
|3.17.3.7|x|||||
|3.17.3.8|||||x|
|3.17.3.9|||||x|
|3.17.3.10|||||x|
|3.17.3.11|x|||||
|3.17.3.11 a)|x|||||
|<br>3.17.3.11 b)|x|||||
|3.17.3.11 c)|x|||||
|3.17.3.12|||||x|
|3.17.3.12.1|||||x|
|3.17.3.13|||||x|
|3.18||||x||

<!-- end of page 64 -->

|||Clause<br>|classificatio|n||
|---|---|---|---|---|---|
|Clause number|ETCS on-<br>board<br>requirement|ETCS<br>trackside<br>requirement|Definition|Informative|Others|
|3.18.1||||x||
|3.18.1.1||||x||
|3.18.2||||x||
|3.18.2.1||||x||
|3.18.2.2|x|||||
|3.18.2.3|x|||||
|3.18.2.4|x|||||
|3.18.2.5|x|||||
|3.18.2.5 1<sup>st</sup>bullet|x|||||
|3.18.2.5 2<sup>nd</sup>bullet|x|||||
|3.18.2.6||||x||
|3.18.2.7|x|||||
|3.18.2.7.1||||x||
|3.18.2.8||x||||
|3.18.2.8.1|x|||||
|3.18.2.9|x|||||
|3.18.2.9 1<sup>st</sup>bullet|x|||||
|3.18.2.9 2<sup>nd</sup>bullet|x|||||
|3.18.2.10|x|||||
|3.18.2.11|x|||||
|3.18.3||||x||
|3.18.3.1||||x||
|3.18.3.2|x|||||
|3.18.3.2 a)|x|||||
|3.18.3.2 b)|x|||||
|3.18.3.2 b) 1<sup>st</sup>bullet|x|||||
|3.18.3.2 b) 2<sup>nd</sup>bullet|x|||||
|3.18.3.2 c)|x|||||
|3.18.3.2 c) 1<sup>st</sup>bullet|x|||||
|3.18.3.2 c) 2<sup>nd</sup>bullet|x|||||
|3.18.3.2 c) 3<sup>rd</sup>bullet|x|||||
|3.18.3.2 c) 4<sup>th</sup>bullet|x|||||
|3.18.3.2 c) 5<sup>th</sup>bullet|x|||||
|3.18.3.2 d)|x|||||
|3.18.3.2 e)|x|||||
|<br>3.18.3.2 f)|x|||||
|3.18.3.2 g)|x|||||
|<br>3.18.3.2 h)|x|||||
|3.18.3.2 i)|x|||||
|3.18.3.2 j)|||||x|
|3.18.3.2 k)|x|||||
|3.18.3.2.1||||x||
|3.18.3.2.2|x|||||

<!-- end of page 65 -->

|||Clause<br>|classificatio|n||
|---|---|---|---|---|---|
|Clause number|ETCS on-<br>board<br>requirement|ETCS<br>trackside<br>requirement|Definition|Informative|Others|
|3.18.3.2.3|x|||||
|3.18.3.2.4|x|||||
|3.18.3.2.5|x|||||
|3.18.3.2.5.1|x|||||
|3.18.3.2.5.2||||x||
|3.18.3.3|x|||||
|3.18.3.3.1|x|||||
|3.18.3.4|x|||||
|3.18.3.4 a)|x|||||
|3.18.3.4 b)|x|||||
|3.18.3.4 c)|x|||||
|3.18.3.4 d)|x|||||
|3.18.3.4 e)|x|||||
|3.18.3.4 f)|x|||||
|3.18.3.4 g)|x|||||
|3.18.3.4 h)|x|||||
|3.18.3.4 i)|x|||||
|3.18.3.4.1||x||||
|3.18.3.4.2|x|||||
|3.18.3.5|x|||||
|3.18.3.5 a)|x|||||
|3.18.3.5 b)|x|||||
|3.18.3.6||||x||
|3.18.3.7|x|||||
|3.18.3.7 a)|x|||||
|3.18.3.7 b)|x|||||
|3.18.3.8|x|||||
|3.18.3.9|x|||||
|3.18.3.10|x|||||
|3.18.3.10.1||x||||
|3.18.3.10.2|x|||||
|3.18.4||||x||
|3.18.4.1||||x||
|3.18.4.1.1|||x|||
|3.18.4.1.1.1||||x||
|3.18.4.1.2|x|||||
|3.18.4.1.3|x|||||
|3.18.4.1.4|x|||||
|3.18.4.2||||x||
|3.18.4.2.1|x|||||
|3.18.4.2.2||||x||
|3.18.4.2.3||||x||
|3.18.4.2.4|x|||||

<!-- end of page 66 -->

|||Clause<br>|classificatio|n||
|---|---|---|---|---|---|
|Clause number|ETCS on-<br>board<br>requirement|ETCS<br>trackside<br>requirement|Definition|Informative|Others|
|3.18.4.2.4.1|||||x|
|3.18.4.2.5|x|||||
|3.18.4.3||||x||
|3.18.4.3.1|x|||||
|3.18.4.3.1.1||||x||
|3.18.4.3.2|x|||||
|3.18.4.3.3|||||x|
|3.18.4.3.4|x|||||
|3.18.4.3.4.1||||x||
|3.18.4.3.5|x|||||
|3.18.4.3.6|x|||||
|3.18.4.3.6.1|x|||||
|3.18.4.3.6.1 a)|x|||||
|3.18.4.3.6.1 b)|x|||||
|3.18.4.3.6.2|x|||||
|3.18.4.3.6.3|x|||||
|3.18.4.3.6.3 a)|x|||||
|3.18.4.3.6.3 b)|x|||||
|3.18.4.4||||x||
|3.18.4.4.1|||x|||
|3.18.4.4.2|x|x||||
|3.18.4.4.3||||x||
|3.18.4.5||||x||
|3.18.4.5.1|x|||||
|3.18.4.5.2|x|||||
|3.18.4.5.3|x|||||
|3.18.4.5.4|x|||||
|3.18.4.5.4.1|x|||||
|3.18.4.5.5|x|||||
|3.18.4.6||||x||
|3.18.4.6.1||||x||
|3.18.4.6.2|x|||||
|3.18.4.6.2.1|x|x||||
|3.18.4.6.2.2||x||||
|3.18.4.6.2.3|x|||||
|3.18.4.6.3|x|x||||
|3.18.4.6.3.1|||||x|
|3.18.4.6.4|x|||||
|3.18.4.6.5|||||x|
|3.18.5||||x||
|3.18.5.1|x|||||
|3.18.5.2|x|||||
|3.18.5.3|||||x|

<!-- end of page 67 -->

|||Clause<br>|classificatio|n||
|---|---|---|---|---|---|
|Clause number|ETCS on-<br>board<br>requirement|ETCS<br>trackside<br>requirement|Definition|Informative|Others|
|3.18.6||||x||
|3.18.6.1|x|||||
|3.18.6.2|x|||||
|3.19|||||x|
|3.20||||x||
|3.20.1.1|||x|||
|3.20.1.2|x|||||
|3.20.1.2.1||||x||
|3.20.1.3|||||x|
|3.20.1.4|||||x|
|3.20.1.5|||||x|
|3.20.1.6|||||x|
|3.20.1.7|||||x|
|3.20.1.8|||||x|
|3.20.1.9|||||x|
|APPENDIX TO CHAPTER 3||||x||
|A.3.1||||x||
|A.3.1 Table|x|||||
|A.3.2|x|||x||
|A.3.2 Table|x|||||
|A.3.2 Table-footnote|||x|||
|A.3.3||||x||
|A.3.3.1||||x||
|A.3.3.1 Table 17|||x|||
|A.3.3.2|x|||||
|A.3.3.3||||x||
|A.3.3.4||||x||
|A.3.3.4 1<sup>st</sup>bullet||||x||
|A.3.3.4 2<sup>nd</sup>bullet||||x||
|A.3.3.4 3<sup>rd</sup>bullet||||x||
|A.3.3.5||||x||
|A.3.4||||x||
|A.3.4.1||||x||
|A.3.4.1.1||||x||
|A.3.4.1.2|||x|||
|A.3.4.1.2 a)|||x|||
|A.3.4.1.2 b)|||x|||
|A.3.4.1.2 c)|||x|||
|A.3.4.1.2 d)|||x|||
|A.3.4.1.2 e)|||x|||
|A.3.4.1.2 f)|||x|||
|A.3.4.1.2 g)|||x|||
|A.3.4.1.2 h)|||x|||

<!-- end of page 68 -->

|||Clause<br>|classificatio|n||
|---|---|---|---|---|---|
|Clause number|ETCS on-<br>board<br>requirement|ETCS<br>trackside<br>requirement|Definition|Informative|Others|
|A.3.4.1.2 i)|||x|||
|A.3.4.1.2 j)|||x|||
|A.3.4.1.2 k)|||x|||
|A.3.4.1.2 l)|||x|||
|A.3.4.1.2 m)|||x|||
|A.3.4.1.2 n)|||x|||
|A.3.4.1.2 o)|||x|||
|A.3.4.1.3|x|||||
|A.3.4.1.3 a)|x|||||
|A.3.4.1.3 b)|x|||||
|A.3.4.1.3 c)|x|||||
|A.3.4.1.3 d)|x|||||
|A.3.4.1.3 Table|x|||||
|A.3.4.1.3 Table-footnote [1]|x|||||
|A.3.4.1.3 Table-footnote [2]||||x||
|A.3.4.1.3 Table-footnote [3]||||x||
|A.3.4.1.3 Table-footnote [4]||||x||
|A.3.4.1.3 Table-footnote [5]||||x||
|A.3.4.1.3 Table-footnote [6]||||x||
|A.3.4.1.3 Table-footnote [7]|x|||||
|A.3.4.1.3 Table-footnote [8]|x|||||
|A.3.4.1.3 Table-footnote [9]|x|||||
|A.3.4.1.3 Table-footnote [10]|x|||||
|A.3.4.1.3 Table-footnote [11]|x|||||
|A.3.4.1.3 Table-footnote [12]|x|||||
|A.3.4.1.3 Table-footnote [13]|x|||||
|A.3.4.1.3 Table-footnote [14]||||x||
|A.3.4.1.4||||x||
|A.3.4.1.4.1|||||x|
|A.3.4.1.4.2|||x|||
|A.3.4.1.4.2 a)|||x|||
|A.3.4.1.4.2 b)|||x|||
|A.3.4.1.4.2 c)|||x|||
|A.3.4.1.4.2 d)|||x|||
|A.3.4.1.4.2 e)|||x|||
|A.3.4.1.4.2 f)|||x|||
|A.3.4.1.4.2 g)|||x|||
|A.3.4.1.4.2 h)|||x|||
|A.3.4.1.4.2 i)|||x|||
|A.3.4.1.4.2 j)|||x|||
|A.3.4.1.4.2 k)|||x|||
|A.3.4.1.4.2 l)|||||x|
|A.3.4.1.4.2 m)|||||x|

<!-- end of page 69 -->

|||Clause<br>|classificatio|n||
|---|---|---|---|---|---|
|Clause number|ETCS on-<br>board<br>requirement|ETCS<br>trackside<br>requirement|Definition|Informative|Others|
|A.3.4.1.4.2 n)|||x|||
|A.3.4.1.4.2 o)|||x|||
|A.3.4.1.4.2 p)|||||x|
|A.3.4.1.4.2 q)|||x|||
|A.3.4.1.4.2 r)|||x|||
|A.3.4.1.4.2 s)|||x|||
|A.3.4.1.4.2 t)|||x|||
|A.3.4.1.4.2 u)|||x|||
|A.3.4.1.4.2 v)|||x|||
|A.3.4.1.4.2 w)|||x|||
|A.3.4.1.4.2 x)|||x|||
|A.3.4.1.4.2 y)|||x|||
|A.3.4.1.4.2 z)|||x|||
|A.3.4.1.4.2 aa)|||x|||
|A.3.4.1.4.2 bb)|||x|||
|A.3.4.1.4.2 cc)|||x|||
|A.3.4.1.4.2 dd)|||x|||
|A.3.5||||x||
|A.3.5.1|x|||||
|A.3.5.1 1<sup>st</sup>bullet|x|||||
|A.3.5.1 2<sup>nd</sup>bullet|x|||||
|A.3.5.1 3<sup>rd</sup>bullet|x|||||
|A.3.5.1 4<sup>th</sup>bullet|x|||||
|A.3.5.1 5<sup>th</sup>bullet|x|||||
|A.3.5.1 6<sup>th</sup>bullet|x|||||
|A.3.5.1 7<sup>th</sup>bullet|x|||||
|A.3.5.1 8<sup>th</sup>bullet|||||x|
|A.3.5.1 9<sup>th</sup>bullet|x|||||
|A.3.5.1 10<sup>th</sup>bullet|||||x|
|A.3.5.1 11<sup>th</sup>bullet|x|||||
|A.3.5.1 12<sup>th</sup>bullet|x|||||
|A.3.5.1.1||||x||
|A.3.5.1.1 1<sup>st</sup>bullet||||x||
|A.3.5.1.1 2<sup>nd</sup>bullet||||x||
|A.3.5.1.1 3<sup>rd</sup>bullet||||x||
|A.3.5.1.1 4<sup>th</sup>bullet||||x||
|A.3.5.2|x|||||
|A.3.5.2.1||||x||
|A.3.5.2.2||||x||
|A.3.5.2.3||||x||
|A.3.6||||x||
|A.3.6.1||||x||
|A.3.6.1.1|x|||||

<!-- end of page 70 -->

|||Clause<br>|classificatio|n||
|---|---|---|---|---|---|
|Clause number|ETCS on-<br>board<br>requirement|ETCS<br>trackside<br>requirement|Definition|Informative|Others|
|A.3.6.1.1.1||||x||
|A.3.6.2||||x||
|A.3.6.2.1|x|||||
|A.3.6.2.1 1<sup>st</sup>bullet|x|||||
|A.3.6.2.1 2<sup>nd</sup>bullet|x|||||
|A.3.6.2.1 3<sup>rd</sup>bullet|x|||||
|A.3.6.2.1 4<sup>th</sup>bullet|x|||||
|A.3.6.2.1 5<sup>th</sup>bullet|x|||||
|A.3.6.2.1.1||||x||
|A.3.6.2.1.1 1<sup>st</sup>bullet||||x||
|A.3.6.2.1.1 2<sup>nd</sup>bullet||||x||
|A.3.6.2.1.1 3<sup>rd</sup>bullet||||x||
|A.3.6.2.1.2||||x||
|A.3.7||||x||
|A.3.7.1|x|||||
|A.3.7.2|x|||||
|A.3.7.3|x|||||
|A.3.7.4|x|||||
|A.3.7.5|x|||||
|A.3.7.6|x|||||
|A.3.7.6 Table|x|||||
|A.3.8||||x||
|A.3.8.1|x|||||
|A.3.8.2|x|||||
|A.3.8.3|x|||||
|A.3.8.4|x|||||
|A.3.8.5|x|||||
|A.3.8.6|x|||||
|A.3.9||||x||
|A.3.9.1|x|||||
|A.3.9.2|x|||||
|A.3.9.3|x|||||
|A.3.9.4|x|||||
|A.3.9.5|x|||||
|A.3.9.6|x|||||
|A.3.9.7||||x||
|A.3.9.8|x|||||
|A.3.10||||x||
|A.3.10.1||||x||
|A.3.10.2|x|||||
|A.3.10.2 a)|x|||||
|A.3.10.2 b)|x|||||
|A.3.10.3|x|||||

<!-- end of page 71 -->

|||Clause<br>|classificatio|n||
|---|---|---|---|---|---|
|Clause number|ETCS on-<br>board<br>requirement|ETCS<br>trackside<br>requirement|Definition|Informative|Others|
|A.3.10.4|x|||||
|A.3.10.5||||x||
|A.3.10.6||||x||
|A.3.11||||x||
|A.3.11 Table|x|||||
|A.3.12||||x||
|A.3.12.1.1||||x||
|A.3.12.1.2||||x||
|A.3.12.1.3|||x|||
|A.3.12.1.3 a)|||x|||
|A.3.12.1.3 b)|||x|||
|A.3.12.1.3 c)|||x|||
|A.3.12.1.3 d)|||x|||
|A.3.12.1.3 e)|||x|||
|A.3.12.1.3 f)|||x|||
|A.3.12.1.3 g)|||x|||
|A.3.12.1.4|x|||||
|A.3.12.1.5|x|||||
|A.3.12.2||||x||
|A.3.12.2.1|x|||||
|A.3.12.2.2|x|||||
|A.3.12.2.3|x|||||
|A.3.12.2.4|x|||||
|A.3.12.2.5|x|||||
|A.3.12.2.6|x|||||
|A.3.12.2.7|x|||||
|A.3.12.2.8|x|||||
|A.3.12.3||||x||
|A.3.12.3.1|x|||||
|A.3.12.3.2|x|||||
|A.3.12.3.3|x|||||
|A.3.12.3.4|x|||||
|A.3.12.3.5|x|||||
|A.3.12.3.6||||x||
|A.3.12.4||||x||
|A.3.12.4.1|x|||||
|A.3.12.4.2|x|||||
|A.3.12.4.3|x|||||
|A.3.12.4.4|x|||||
|A.3.12.4.5|x|||||
|A.3.12.4.6|x|||||
|A.3.12.5||||x||
|A.3.12.5.1|x|||||

<!-- end of page 72 -->

|||Clause|classificatio|n||
|---|---|---|---|---|---|
|Clause number|ETCS on-<br>board<br>requirement|ETCS<br>trackside<br>requirement|Definition|Informative|Others|
|A.3.12.5.2|x|||||
|A.3.12.6||||x||
|A.3.12.6.1|x|||||
|A.3.12.6.2|x|||||
|A.3.12.7||||x||
|A.3.12.7.1|x|||||
|A.3.12.7.2|x|||||
|A.3.12.8||||x||
|A.3.12.8.1|x|||||
|A.3.12.8.2||||x||
|A.3.12.9||||x||
|A.3.12.9.1||||x||
|A.3.12.9.2||||x||
|A.3.12.9.2 Figure 63||||x||
|A.3.12.9.3||||x||
|A.3.12.9.4||||x||
|A.3.12.9.5||||x||
|A.3.12.9.5.1||||x||
|A.3.12.9.6||||x||
|A.3.12.9.7||||x||
|A.3.12.9.8||||x||
|A.3.12.9.9||||x||
|A.3.12.9.10||||x||
|A.3.12.9.11||||x||
|A.3.12.9.12||||x||
|A.3.12.9.13||||x||
|A.3.12.9.14||||x||
|A.3.12.9.15||||x||
|A.3.12.9.16||||x||
|A.3.12.9.17||||x||
|A.3.12.9.18||||x||
|A.3.12.9.19||||x||
|A.3.13||||x||
|A.3.13.1||||x||
|A.3.13.2|x|||||

<!-- end of page 73 -->

## **9.4.4 Chapter 4**

|||Clause<br>|classification|||
|---|---|---|---|---|---|
|Clause number|ETCS on-<br>board<br>requirement|ETCS<br>trackside<br>requirement|Definition|Informative|Others|
|4.1||||x||
|4.2||||x||
|4.3||||x||
|4.3.1||||x||
|4.3.1.1||||x||
|4.3.1.2||||x||
|4.3.1.3||||x||
|4.3.1.4||||x||
|4.3.1.5||||x||
|4.3.1.6|x|||||
|4.3.1.7||||x||
|4.3.2||||x||
|4.3.2.1||||x||
|4.4||||x||
|4.4.1||||x||
|4.4.1.1||||x||
|4.4.1.1 a)||||x||
|4.4.1.1 b)||||x||
|4.4.1.1 c)||||x||
|4.4.1.2||||x||
|4.4.2||||x||
|4.4.2.1|x|||||
|4.4.2.2|||||x|
|4.4.3||||x||
|4.4.3.1||||x||
|4.4.3.1.1|||||x|
|4.4.3.1.2|x|||||
|4.4.3.1.3|||||x|
|4.4.3.1.4|||||x|
|4.4.3.2||||x||
|4.4.3.2.1||||x||
|4.4.3.3||||x||
|4.4.3.3.1||||x||
|4.4.3.3.2||||x||
|4.4.4||||x||
|4.4.4.1||||x||
|4.4.4.1.1|||x|||
|4.4.4.1.1.1||||x||
|4.4.4.1.2|x|||||
|4.4.4.1.3|||||x|
|4.4.4.2||||x||
|4.4.4.2.1||||x||
|4.4.4.3||||x||
|4.4.4.3.1||||x||
|4.4.4.3.2||||x||

<!-- end of page 74 -->

|||Clause<br>|classification|||
|---|---|---|---|---|---|
|Clause number|ETCS on-<br>board<br>requirement|ETCS<br>trackside<br>requirement|Definition|Informative|Others|
|4.4.4.3.3||||x||
|4.4.5<br>||||x||
|4.4.5.1||||x||
|4.4.5.1.1|x|||||
|4.4.5.1.2|x|||||
|4.4.5.1.3|||||x|
|4.4.5.2||||x||
|4.4.5.2.1||||x||
|4.4.5.3||||x||
|4.4.5.3.1||||x||
|4.4.5.3.2||||x||
|4.4.6||||x||
|4.4.6.1||||x||
|4.4.6.1.1|||x|||
|4.4.6.1.2|x|||||
|4.4.6.1.3|x|||||
|4.4.6.1.4|x|||||
|4.4.6.1.5|x|||||
|4.4.6.1.6|||||x|
|4.4.6.1.7|x|||||
|4.4.6.1.8|x|||||
|4.4.6.1.9||||x||
|4.4.6.1.10|x|||||
|4.4.6.1.10 a)|x|||||
|4.4.6.1.10 b)|x|||||
|4.4.6.1.10 c)|x|||||
|4.4.6.1.11|||||x|
|4.4.6.1.12|x|||||
|4.4.6.1.13|x|||||
|4.4.6.2||||x||
|4.4.6.2.1||||x||
|4.4.6.3||||x||
|4.4.6.3.1||||x||
|4.4.6.3.2||||x||
|4.4.6.3.2.1||||x||
|4.4.7||||x||
|4.4.7.1||||x||
|4.4.7.1.1|||x|||
|4.4.7.1.2|||x|||
|4.4.7.1.3||||x||
|4.4.7.1.4|x|||||
|4.4.7.1.5|x|||||
|4.4.7.1.5.1|x|||||
|4.4.7.1.5.2||||x||
|4.4.7.1.5.3|x|||||
|4.4.7.1.5.4|x|||||
|4.4.7.1.6|x|||||

<!-- end of page 75 -->

|||Clause<br>|classification|||
|---|---|---|---|---|---|
|Clause number|ETCS on-<br>board<br>requirement|ETCS<br>trackside<br>requirement|Definition|Informative|Others|
|4.4.7.1.6 a)|x|||||
|4.4.7.1.6 b)|x|||||
|4.4.7.2||||x||
|4.4.7.2.1||||x||
|4.4.7.3||||x||
|4.4.7.3.1||||x||
|4.4.7.3.2||||x||
|4.4.8||||x||
|4.4.8.1||||x||
|4.4.8.1.1|x|||||
|4.4.8.1.1 a)|x|||||
|4.4.8.1.1 b)|x|||||
|4.4.8.1.1 c)|x|||||
|4.4.8.1.1 d)|||||x|
|4.4.8.1.2|x|||||
|4.4.8.1.3|x|||||
|4.4.8.1.4|x|||||
|4.4.8.1.5|x|||||
|4.4.8.1.5.1||||x||
|4.4.8.1.5.2|x|||||
|4.4.8.1.5.3|x|||||
|4.4.8.1.6|x|||||
|4.4.8.1.7||||x||
|4.4.8.1.7 1<sup>st</sup>bullet||||x||
|4.4.8.1.7 2<sup>nd</sup>bullet||||x||
|4.4.8.1.8||||x||
|4.4.8.1.8 1<sup>st</sup>bullet||||x||
|4.4.8.1.8 2<sup>nd</sup>bullet||||x||
|4.4.8.1.9||||x||
|4.4.8.1.9.1||||x||
|4.4.8.1.10|x|||||
|4.4.8.1.11|||||x|
|4.4.8.1.12|||||x|
|4.4.8.2||||x||
|4.4.8.2.1||||x||
|4.4.8.3||||x||
|4.4.8.3.1||||x||
|4.4.8.3.2||||x||
|4.4.8.3.2 a)||||x||
|4.4.8.3.2 b)||||x||
|4.4.9||||x||
|4.4.9.1||||x||
|4.4.9.1.1|x|||||
|4.4.9.1.2||||x||
|4.4.9.1.3||||x||
|4.4.9.1.4|x|||||
|4.4.9.1.4.1||||x||

<!-- end of page 76 -->

|||Clause<br>|classification|||
|---|---|---|---|---|---|
|Clause number|ETCS on-<br>board<br>requirement|ETCS<br>trackside<br>requirement|Definition|Informative|Others|
|4.4.9.1.5|x|||||
|4.4.9.1.6|x|||||
|4.4.9.1.7|||||x|
|4.4.9.2||||x||
|4.4.9.2.1||||x||
|4.4.9.3||||x||
|4.4.9.3.1||||x||
|4.4.9.3.2||||x||
|4.4.9.3.3||||x||
|4.4.10||||x||
|4.4.10.1||||x||
|4.4.10.1.1|||x|||
|4.4.10.1.1 a)|||x|||
|4.4.10.1.1 b)|||||x|
|4.4.10.1.1 c)|||x|||
|4.4.10.1.2|x|||||
|4.4.10.1.2.1|||||x|
|4.4.10.1.3|x|||||
|4.4.10.1.4|x|||||
|4.4.10.1.5|||||x|
|4.4.10.2||||x||
|4.4.10.2.1||||x||
|4.4.10.3||||x||
|4.4.10.3.1||||x||
|4.4.10.3.2||||x||
|4.4.11||||x||
|4.4.11.1||||x||
|4.4.11.1.1|||x|||
|4.4.11.1.2|||x|||
|4.4.11.1.2 a)|||x|||
|4.4.11.1.2 b)|||x|||
|4.4.11.1.2 c)|||x|||
|4.4.11.1.3|x|||||
|4.4.11.1.3 a)|x|||||
|4.4.11.1.3 b)|x|||||
|4.4.11.1.3 c)|x|||||
|4.4.11.1.3 d)|x|||||
|4.4.11.1.3 e)|x|||||
|<br>4.4.11.1.3.1|x|||||
|4.4.11.1.3.1 a)|x|||||
|4.4.11.1.3.1 b)|x|||||
|<br>4.4.11.1.3.1 c)|x|x||||
|<br>4.4.11.1.3.1.1||||x||
|4.4.11.1.4||||x||
|4.4.11.1.5|x|||||
|4.4.11.1.5.1|x|||||
|4.4.11.1.5.2|x|||||

<!-- end of page 77 -->

|||Clause<br>|classification|||
|---|---|---|---|---|---|
|Clause number|ETCS on-<br>board<br>requirement|ETCS<br>trackside<br>requirement|Definition|Informative|Others|
|4.4.11.1.6|x|||||
|4.4.11.1.6.1||||x||
|4.4.11.1.6.2|x|||||
|4.4.11.1.6.3|x|||||
|4.4.11.1.6.4|x|||||
|4.4.11.1.6.4 a)|x|||||
|4.4.11.1.6.4 b)|x|||||
|4.4.11.1.6.5|x|||||
|4.4.11.1.6.6|x|||||
|4.4.11.1.6.7|x|||||
|4.4.11.1.7|x|||||
|4.4.11.1.8|x|||||
|4.4.11.1.9|x|||||
|4.4.11.1.10|||||x|
|4.4.11.1.11|||||x|
|4.4.11.2||||x||
|4.4.11.2.1||||x||
|4.4.11.3||||x||
|4.4.11.3.1||||x||
|4.4.11.3.2||||x||
|4.4.11.3.3||||x||
|4.4.12||||x||
|4.4.12.1||||x||
|4.4.12.1.1|||x|||
|4.4.12.1.2|x|||||
|4.4.12.1.3|x|||||
|4.4.12.1.4|x|||||
|4.4.12.1.5|x|||||
|4.4.12.1.6||||x||
|4.4.12.1.7|x|||||
|4.4.12.1.7.1||||x||
|4.4.12.1.8|||||x|
|4.4.12.1.9|||||x|
|4.4.12.2||||x||
|4.4.12.2.1||||x||
|4.4.12.3||||x||
|4.4.12.3.1||||x||
|4.4.12.3.2||||x||
|4.4.13||||x||
|4.4.13.1||||x||
|4.4.13.1.1|||||x|
|4.4.13.1.1.1||||x||
|4.4.13.1.2|x|||||
|4.4.13.1.3|x|||||
|4.4.13.1.4|x|||||
|4.4.13.1.4.1||||x||
|4.4.13.1.5|||||x|

<!-- end of page 78 -->

|||Clause<br>|classification|||
|---|---|---|---|---|---|
|Clause number|ETCS on-<br>board<br>requirement|ETCS<br>trackside<br>requirement|Definition|Informative|Others|
|4.4.13.1.6|x|||||
|4.4.13.2||||x||
|4.4.13.2.1||||x||
|4.4.13.3||||x||
|4.4.13.3.1||||x||
|4.4.13.3.2||||x||
|4.4.14||||x||
|4.4.14.1||||x||
|4.4.14.1.1|x|||||
|4.4.14.1.2|x|||||
|4.4.14.1.2.1|x|||||
|4.4.14.1.3|x|||||
|4.4.14.1.3.1|x|||||
|4.4.14.1.3.2|x|||||
|4.4.14.1.4|x|||||
|4.4.14.1.5|||||x|
|4.4.14.1.6||||x||
|4.4.14.1.7|||||x|
|4.4.14.1.8|||||x|
|4.4.14.1.9|x|||||
|4.4.14.2||||x||
|4.4.14.2.1||||x||
|4.4.14.3||||x||
|4.4.14.3.1||||x||
|4.4.14.3.2||||x||
|4.4.15||||x||
|4.4.15.1||||x||
|4.4.15.1.1|||x|||
|4.4.15.1.1.1||||x||
|4.4.15.1.1.2|x|||||
|4.4.15.1.1.3|x|||||
|4.4.15.1.2|x|||||
|4.4.15.1.3|x|||||
|4.4.15.1.4|x|||||
|4.4.15.1.5|||||x|
|4.4.15.1.6|x|||||
|4.4.15.1.7|||||x|
|4.4.15.1.8|||||x|
|4.4.15.1.9|||||x|
|4.4.15.1.10|x|||||
|4.4.15.2||||x||
|4.4.15.2.1||||x||
|4.4.15.3||||x||
|4.4.15.3.1||||x||
|4.4.15.3.2||||x||
|4.4.16||||x||
|4.4.16.1||||x||

<!-- end of page 79 -->

|||Clause<br>|classification|||
|---|---|---|---|---|---|
|Clause number|ETCS on-<br>board<br>requirement|ETCS<br>trackside<br>requirement|Definition|Informative|Others|
|4.4.16.1.1||||x||
|4.4.16.1.2<br>||||x||
|4.4.16.1.3||||x||
|4.4.16.1.4|x|||||
|4.4.16.1.5|x|||||
|4.4.16.1.6|x|||||
|4.4.16.2||||x||
|4.4.16.2.1||||x||
|4.4.16.3||||x||
|4.4.16.3.1||||x||
|4.4.16.3.2||||x||
|4.4.16.3.2.1||||x||
|4.4.17||||x||
|4.4.17.1||||x||
|4.4.17.1.1|||x|||
|4.4.17.1.2|x|||||
|4.4.17.1.3|||||x|
|4.4.17.2||||x||
|4.4.17.2.1||||x||
|4.4.17.3||||x||
|4.4.17.3.1||||x||
|4.4.17.3.2|||||x|
|4.4.17.4||||x||
|4.4.17.4.1||||x||
|4.4.17.4.2||||x||
|4.4.17.4.3||||x||
|4.4.17.4.4||||x||
|4.4.17.5||||x||
|4.4.17.5.1||||x||
|4.4.18||||x||
|4.4.18.1||||x||
|4.4.18.1.1|||x|||
|4.4.18.1.2||||x||
|4.4.18.1.3|x|||||
|4.4.18.1.3 a)|x|||||
|4.4.18.1.3 b)|x|||||
|4.4.18.1.4|x|||||
|4.4.18.1.5|x|||||
|4.4.18.1.6|x|||||
|4.4.18.1.7|x|||||
|4.4.18.1.8|x|||||
|4.4.18.1.9|||||x|
|4.4.18.1.10|x|||||
|4.4.18.1.11|x|||||
|4.4.18.1.12|x|||||
|4.4.18.2||||x||
|4.4.18.2.1||||x||

<!-- end of page 80 -->

|||Clause<br>|classification|||
|---|---|---|---|---|---|
|Clause number|ETCS on-<br>board<br>requirement|ETCS<br>trackside<br>requirement|Definition|Informative|Others|
|4.4.18.3||||x||
|4.4.18.3.1||||x||
|4.4.18.3.2||||x||
|4.4.19||||x||
|4.4.19.1||||x||
|4.4.19.1.1|||x|||
|4.4.19.1.2|x|||||
|4.4.19.1.3|x|||||
|4.4.19.1.4|x|||||
|4.4.19.1.4 a)|x|||||
|4.4.19.1.4 b)|x|||||
|4.4.19.1.4.1|||x|||
|4.4.19.1.4.2|x|||||
|4.4.19.1.4.2 a)|x|||||
|4.4.19.1.4.2 b)|x|||||
|4.4.19.1.4.2 c)|x|||||
|4.4.19.1.4.3|x|||||
|4.4.19.1.4.4|x|||||
|4.4.19.1.4.5|x|||||
|4.4.19.1.4.5 a)|x|||||
|4.4.19.1.4.5 b)|x|||||
|4.4.19.1.4.6|x|||||
|4.4.19.1.4.7|x|||||
|4.4.19.1.4.7 a)|x|||||
|4.4.19.1.4.7 b)|x|||||
|4.4.19.1.4.8|x|||||
|4.4.19.1.5||||x||
|4.4.19.1.6||||x||
|4.4.19.1.7|||||x|
|4.4.19.2||||x||
|4.4.19.2.1||||x||
|4.4.19.3||||x||
|4.4.19.3.1||||x||
|4.4.19.3.1.1||||x||
|4.4.19.3.2||||x||
|4.4.19.3.2.1||||x||
|4.4.20||||x||
|4.4.20.1||||x||
|4.4.20.1.1|||x|||
|4.4.20.1.2|x|||||
|4.4.20.1.3|x|||||
|4.4.20.1.4|x|||||
|4.4.20.1.5|x|||||
|4.4.20.1.6|x|||||
|4.4.20.1.7|x|||||
|4.4.20.1.8|x|||||
|4.4.20.1.9|x|||||

<!-- end of page 81 -->

|||Clause<br>|classification|||
|---|---|---|---|---|---|
|Clause number|ETCS on-<br>board<br>requirement|ETCS<br>trackside<br>requirement|Definition|Informative|Others|
|4.4.20.1.10|||||x|
|4.4.20.1.11<br>|x|||||
|4.4.20.1.11.1||||x||
|4.4.20.1.12|x|||||
|4.4.20.1.13|x|||||
|4.4.20.1.14|||||x|
|4.4.20.1.15|x|||||
|4.4.20.2||||x||
|4.4.20.2.1||||x||
|4.4.20.3||||x||
|4.4.20.3.1||||x||
|4.4.20.3.2||||x||
|4.4.20.3.3||||x||
|4.4.21||||x||
|4.4.21.1||||x||
|4.4.21.1.1|||x|||
|4.4.21.1.2||||x||
|4.4.21.1.3|x|||||
|4.4.21.1.4|x|||||
|4.4.21.1.5|x|||||
|4.4.21.1.6|x|||||
|4.4.21.1.6.1||||x||
|4.4.21.1.7|x|||||
|4.4.21.1.7 a)|x|||||
|4.4.21.1.7 b)|x|||||
|4.4.21.1.7 b) 1<sup>st</sup>bullet|x|||||
|<br>4.4.21.1.7 b) 2<sup>nd</sup>bullet|x|||||
|<br>4.4.21.1.7 c) 1<sup>st</sup>bullet|x|||||
|<br>4.4.21.1.7 c) 2<sup>nd</sup>bullet|x|||||
|<br>4.4.21.1.8|x|||||
|4.4.21.1.9|x|||||
|4.4.21.1.10|x|||||
|4.4.21.1.11|x|||||
|4.4.21.1.11.1||||x||
|4.4.21.1.12|x|||||
|4.4.21.1.13|x|||||
|4.4.21.2||||x||
|4.4.21.2.1||||x||
|4.4.21.3||||x||
|4.4.21.3.1||||x||
|4.4.21.3.2||||x||
|4.4.21.3.3||||x||
|4.5||||x||
|4.5.1||||x||
|4.5.1.1|||x|||
|4.5.1.2||||x||
|4.5.1.3||||x||

<!-- end of page 82 -->

|||Clause<br>|classification|||
|---|---|---|---|---|---|
|Clause number|ETCS on-<br>board<br>requirement|ETCS<br>trackside<br>requirement|Definition|Informative|Others|
|4.5.1.4|x|||||
|4.5.1.5|||x|||
|4.5.2||||x||
|4.5.2.1|x|||||
|4.5.2.2|||x|||
|4.5.2.2 Table|x|||||
|4.5.2.2 Table-footnote {1}||||x||
|4.5.2.2 Table-footnote {2}|x|||||
|4.5.2.2 Table-footnote {3}||||x||
|<br>4.5.2.2 Table-footnote {4}|x|||||
|<br>4.6||||x||
|4.6.1||||x||
|4.6.1.1|||x|||
|4.6.1.2|||x|||
|4.6.1.3|||x|||
|4.6.1.4|||x|||
|4.6.1.5|||x|||
|4.6.1.6|||x|||
|4.6.2 Table|x|||||
|4.6.3 Table|x|||||
|4.6.3 Table-footnote {1}||||x||
|4.6.3 Table-footnote {2}||||x||
|4.6.3 Table-footnote {3}||||x||
|4.6.3 Table-footnote {4}||||x||
|4.6.3 Table-footnote {5}||||x||
|4.6.3 Table-footnote {6}||||x||
|4.6.3 Table-footnote {7}||||x||
|4.6.3 Table-footnote {8}||||x||
|<br>4.6.3 Table-footnote {9}|x|||||
|<br>4.6.3 Table-footnote {10}||||x||
|4.7||||x||
|4.7.1||||x||
|4.7.1.1|||x|||
|4.7.1.2|||x|||
|4.7.1.3|||x|||
|4.7.1.4|||||x|
|4.7.1.5||||x||
|4.7.2||||x||
|4.7.2.1.1|x|||||
|4.7.2.1.2|x|||||
|4.7.2.1.3|||x|||
|4.7.2.1.4|||x|||
|4.7.2.1.4 Table|x|||||
|4.8||||x||
|4.8.1||||x||
|4.8.1.1||||x||
|4.8.1.2||||x||

<!-- end of page 83 -->

|||Clause<br>|classification|||
|---|---|---|---|---|---|
|Clause number|ETCS on-<br>board<br>requirement|ETCS<br>trackside<br>requirement|Definition|Informative|Others|
|4.8.1.3|x|||||
|4.8.1.3.1<br>|x|||||
|4.8.1.3.1 1)|x|||||
|4.8.1.3.1 2)|x|||||
|4.8.1.4||||x||
|4.8.1.5|x|||||
|4.8.1.6|x|||||
|4.8 Figure 3||||x||
|4.8.2||||x||
|4.8.2.1|x|||||
|4.8.2.1 a)|x|||||
|4.8.2.1 b)|x|||||
|4.8.2.1 c)|x|||||
|4.8.2.1 d)|x|||||
|4.8.2.1 e)|x|||||
|4.8.2.2|x|||||
|4.8.2.3|x|||||
|4.8.2.4||||x||
|4.8.2.5||||x||
|4.8.3||||x||
|4.8.3.1||||x||
|4.8.3.1.1|||x|||
|4.8.3.1.1 Table|x|||||
|4.8.3.1.1 Table-footnote [1]|x|||||
|4.8.3.1.1 Table-footnote [2]|x|||||
|4.8.3.1.1 Table-footnote [3]|x|||||
|<br>4.8.3.1.1 Table-footnote [4]|x|||||
|<br>4.8.3.1.1 Table-footnote [5]|x|||||
|<br>4.8.3.1.1 Table-footnote [8]|x|||||
|4.8.3.1.1 Table-footnote [9]|x|||||
|4.8.3.1.1 Table-footnote [10]|x|||||
|4.8.3.1.1 Table-footnote [11]|x|||||
|4.8.3.1.1 Table-footnote [12]|x|||||
|4.8.3.1.1 Table-footnote [13]|x|||||
|4.8.3.1.1 Table-footnote [14]|x|||||
|4.8.3.1.1 Table-footnote [15]|x|||||
|4.8.3.1.1 Table-footnote [16]|x|||||
|4.8.3.1.1 Table-footnote [17]|x|||||
|<br>4.8.3.2||||x||
|4.8.3.2 Table|x|||||
|4.8.3.2 Table-footnote [6]|x|||||
|<br>4.8.3.2 Table-footnote [7]|x|||||
|4.8.3.3|||||x|
|4.8.3.4|||||x|
|4.8.4||||x||
|4.8.4.1||||x||
|4.8.4.1.1|x|||||

<!-- end of page 84 -->

|||Clause<br>|classification|||
|---|---|---|---|---|---|
|Clause number|ETCS on-<br>board<br>requirement|ETCS<br>trackside<br>requirement|Definition|Informative|Others|
|4.8.4.1.2|||||x|
|4.8.4.2|||||x|
|4.8.4.2 Table|x|||||
|4.8.4.2 Table-footnote [1]|x|||||
|4.8.4.2 Table-footnote [2]|x|||||
|4.8.4.2 Table-footnote [3]|x|||||
|4.8.4.2 Table-footnote [4]|x|||||
|4.8.4.2 Table-footnote [5]|x|||||
|4.8.4.2 Table-footnote [6]|x|||||
|4.8.4.2 Table-footnote [7]|x|||||
|<br>4.8.4.2 Table-footnote [8]|x|||||
|<br>4.8.4.2 Table-footnote [9]|x|||||
|4.8.4.2 Table-footnote [10]|x|||||
|4.8.4.2 Table-footnote [11]|x|||||
|4.8.4.2 Table-footnote [12]|x|||||
|4.8.4.2 Table-footnote [13]|x|||||
|4.8.4.2 Table-footnote [14]|x|||||
|4.8.5||||x||
|4.8.5.1|x|||||
|4.8.5.2|x|||||
|4.8.5.2.1||||x||
|4.8.5.3|x|||||
|4.8.5.4|x|||||
|4.8.5.4 a)|x|||||
|4.8.5.4 b)|x|||||
|<br>4.8.5.4 c)|x|||||
|<br>4.8.5.5|x|||||
|4.8.5.6|x|||||
|4.8.5.6 a)|x|||||
|4.8.5.6 b)|x|||||
|4.8.5.6 c)|x|||||
|4.8.5.7|x|||||
|4.8.5.7.1||||x||
|4.8.5.8||||x||
|4.9||||x||
|4.9.1||||x||
|4.9.1.1||||x||
|4.9.1.2||||x||
|4.9.1.3|x|||||
|4.9.1.3.1|x|||||
|4.9.1.4||||x||
|4.10||||x||
|4.10.1||||x||
|4.10.1.1||||x||
|4.10.1.2||||x||
|4.10.1.3|x|||||
|4.10.1.3 a)|x|||||

<!-- end of page 85 -->

|||Clause<br>|classification|||
|---|---|---|---|---|---|
|Clause number|ETCS on-<br>board<br>requirement|ETCS<br>trackside<br>requirement|Definition|Informative|Others|
|4.10.1.3 b)|x|||||
|4.10.1.3 c)|x|||||
|4.10.1.3 d)<br>|x|||||
|4.10.1.3 e)|x|||||
|4.10.1.3 Table|x|||||
|4.10.1.3 Table-footnote [1]|x|||||
|4.10.1.4||||x||
|4.10.1.4.1|||||x|
|4.10.1.4.2|||x|||
|4.10.1.4.2 a)|||x|||
|4.10.1.4.2 b)|||x|||
|<br>4.10.1.4.2 c)|||x|||
|4.10.1.4.2 d)|||x|||
|4.10.1.4.2 e)|||x|||
|4.10.1.4.2 f)|||x|||
|4.10.1.4.2 g)|||x|||
|4.10.1.4.2 h)|||x|||
|4.10.1.4.2 i)|||x|||
|4.10.1.4.2 j)|||x|||
|4.10.1.4.2 k)|||x|||
|4.10.1.4.2 l)|||||x|
|4.10.1.4.2 m)|||||x|
|4.10.1.4.2 n)|||x|||
|4.10.1.4.2 o)|||x|||
|4.10.1.4.2 p)|||||x|
|<br>4.10.1.4.2 q)|||x|||
|4.10.1.4.2 r)|||x|||
|4.10.1.4.2 s)|||x|||
|4.10.1.4.2 t)|||x|||
|4.10.1.4.2 u)|||x|||
|4.10.1.4.2 v)|||x|||
|4.10.1.4.2 w)|||x|||
|4.10.1.4.2 x)|||x|||
|4.10.1.4.2 y)|||x|||
|4.10.1.4.2 z)|||x|||
|4.10.1.4.2 aa)|||x|||
|4.10.1.4.2 bb)|||x|||
|4.10.1.4.2 cc)|||x|||
|4.10.1.4.2 dd)|||x|||
|4.11||||x||
|4.11.1.1|x|||||
|4.11.1.1 Table|x|||||
|4.11.1.2||||x||
|4.11.1.3|x|||||
|4.11.1.4|x|||||
|4.11.1.4 a)|x|||||
|4.11.1.4 b)|x|||||

<!-- end of page 86 -->

|||Clause|classification|||
|---|---|---|---|---|---|
|Clause number|ETCS on-<br>board<br>requirement|ETCS<br>trackside<br>requirement|Definition|Informative|Others|
|4.11.1.4 c)|x|||||
|4.11.1.4 d)|x|||||
|4.11.1.4 e)|x|||||
|4.12||||x||
|4.12.1.1||||x||
|4.12.1.2|x|||||
|4.12.1.2 a)|x|||||
|4.12.1.2 b)|x|||||
|4.12.1.2 c)|x|||||
|4.12.1.2 d)|x|||||
|4.12.1.2 e)|x|||||
|4.12.1.2 Table|x|||||
|4.12.1.2 Table-footnote [1]|x|||||
|4.12.1.2 Table-footnote [2]|x|||||

<!-- end of page 87 -->

## **9.4.5 Chapter 5**

|Clause number|ETCS on-<br>board<br>requirement|Claus<br>ETCS<br>trackside<br>requirement|e classificati<br>Definition|on<br>Informative|Others|
|---|---|---|---|---|---|
|5.1||||x||
|5.2||||x||
|5.3<br>||||x||
|5.3.1||||x||
|5.3.1.1||||x||
|5.3.1.2||||x||
|5.3.1.3|x|||||
|5.3.1.3.1||||x||
|5.3.1.4||||x||
|5.3.2||||x||
|5.3.2.1|||x|||
|5.3.2.2|||x|||
|5.3.2.3|||x|||
|5.3.2.4|||x|||
|5.4||||x||
|5.4.1||||x||
|5.4.1.1||||x||
|5.4.1.1 a)||||x||
|5.4.1.1 b)||||x||
|5.4.1.1 c)||||x||
|5.4.1.1 d)||||x||
|5.4.1.2||||x||
|5.4.1.3||||x||
|5.4.1.4|x|||||
|5.4.2||||x||
|5.4.2.1|||x|||
|5.4.2.1 a)|||x|||
|5.4.2.1 b)|||x|||
|5.4.2.1 c)|||x|||
|5.4.2.2|||x|||
|5.4.2.3||||x||
|5.4.2.4||||x||
|5.4.3||||x||
|5.4.3.1||||x||
|5.4.3.2||||x||
|5.4.3.2 S0|x|||||
|5.4.3.2 S1|x|||||
|5.4.3.2 D2|x|||||
|5.4.3.2 D3|x|||||
|5.4.3.2 D7|x|||||
|5.4.3.2 S2|x|||||
|5.4.3.2 S3|x|||||
|5.4.3.2 S4|x|||||

<!-- end of page 88 -->

|Clause number|ETCS on-<br>board<br>requirement|Claus<br>ETCS<br>trackside<br>requirement|e classificati<br>Definition|on<br>Informative|Others|
|---|---|---|---|---|---|
|5.4.3.2 A29|x|||||
|5.4.3.2 A41|x|||||
|5.4.3.2 A43|x|||||
|5.4.3.2 D8|x|||||
|5.4.3.2 A42|x|||||
|5.4.3.2 D9|x|||||
|5.4.3.2 S5|x|||||
|5.4.3.2 S10|x|||||
|5.4.3.2 S12|x|||||
|5.4.3.2 D12|x|||||
|5.4.3.2 S13|x|||||
|5.4.3.2 D10|x|||||
|5.4.3.2 D11|x|||||
|5.4.3.2 D15|x|||||
|5.4.3.2 S11|x|||||
|5.4.3.2 S20|x|||||
|5.4.3.2 S21|x|||||
|5.4.3.2 S22|x|||||
|5.4.3.2 S23|x|||||
|5.4.3.2 S24|x|||||
|5.4.3.2 S25|x|||||
|5.4.3.2 A31|x|||||
|5.4.3.2 D31|x|||||
|5.4.3.2 A32|x|||||
|5.4.3.2 D32|x|||||
|5.4.3.2 A33|x|||||
|5.4.3.2 A34|x|||||
|5.4.3.2 D33||x||||
|5.4.3.2 A35|x|x||||
|5.4.3.2 D22||x||||
|5.4.3.2 A23||x||||
|5.4.3.2 D34|x|||||
|5.4.3.2 A24|x|||||
|5.4.3.2 A38||x||||
|5.4.3.2 D35|x|||||
|5.4.3.2 A39|x|||||
|5.4.3.2 A40|x|||||
|5.4.3.2.1|x|||||
|5.4.3.2.1 1<sup>st</sup>bullet|x|||||
|5.4.3.2.1 2<sup>nd</sup>bulet|x|||||
|5.4.3.2.2|x|||||
|5.4.3.3||||x||
|5.4.3.3 Table|x|||||
|5.4.4||||x||

<!-- end of page 89 -->

|||Claus|e classificati|on||
|---|---|---|---|---|---|
|Clause number|ETCS on-<br>board<br>requirement|ETCS<br>trackside<br>requirement|Definition|Informative|Others|
|5.4.4.1||||x||
|5.4.4.1 Figure 1||||x||
|5.4.5||||x||
|5.4.5.1|x|||||
|5.4.5.2||||x||
|5.4.5.3|x|||||
|5.4.5.3 a)|x|||||
|5.4.5.3 b)|x|||||
|5.4.5.3 c)|x|||||
|5.4.5.3 d)|x|||||
|5.4.5.3 e)|x|||||
|5.4.5.3 f)|x|||||
|5.4.5.3 g)|x|||||
|5.4.5.3 h)|x|||||
|5.4.5.3 h) 1<sup>st</sup>bullet|x|||||
|5.4.5.3 h) 2<sup>nd</sup>bullet|x|||||
|5.4.5.3 h) 3<sup>rd</sup>bullet|x|||||
|5.4.5.3 h) 4<sup>th</sup>bullet|x|||||
|5.4.5.3 h) 5<sup>th</sup>bullet|x|||||
|5.4.5.3 i)|x|||||
|5.4.5.3 j)|x|||||
|<br>5.4.5.3 j) 1<sup>st</sup>bullet|x|||||
|5.4.5.3 j) 2<sup>nd</sup>bullet|x|||||
|5.4.5.3 k)|x|||||
|5.4.5.3 l)|x|||||
|5.4.6||||x||
|5.4.6.1|||x|||
|5.4.6.2|||x|||
|5.5||||x||
|5.5.1||||x||
|5.5.1.1|||x|||
|5.5.2||||x||
|5.5.2.1||||x||
|5.5.2.1.1|||x|||
|5.5.2.1.2||||x||
|5.5.2.1.3|||x|||
|5.5.2.2|||||x|
|5.5.2.3||||x||
|5.5.2.3.1|||x|||
|5.5.2.3.2|||x|||
|5.5.2.3.3||||x||
|5.5.3||||x||
|5.5.3.1|||x|||
|5.5.3.1.1||||x||

<!-- end of page 90 -->

|Clause number|ETCS on-<br>board<br>requirement|Claus<br>ETCS<br>trackside<br>requirement|e classificati<br>Definition|on<br>Informative|Others|
|---|---|---|---|---|---|
|5.5.3.1.2|x|||||
|5.5.3.1.3|x|||||
|5.5.3.1.3.1||||x||
|5.5.3.1.4|x|||||
|5.5.3.1.4 step 3||x||||
|5.5.3.1.4 step 4|x|||||
|5.5.3.1.4.1||||x||
|5.5.3.1.4.2||||x||
|5.5.3.2|||||x|
|5.5.4||||x||
|5.5.4.1.1|x|||||
|5.5.4.1.1.1|x|||||
|5.5.4.1.2|x|||||
|5.6||||x||
|5.6.1||||x||
|5.6.1.1||||x||
|5.6.1.2|||||x|
|5.6.2||||x||
|5.6.2.1||||x||
|5.6.2.2||||x||
|5.6.2.2 E015|x|||||
|5.6.2.2 D020|x|||||
|5.6.2.2 D030|x|||||
|5.6.2.2 A030|x|||||
|5.6.2.2 A045|x|||||
|5.6.2.2 S050|x|||||
|5.6.2.2 A050|x|||||
|5.6.2.2 D040|x|||||
|5.6.2.2 A100|x|||||
|5.6.2.2 D080|x|||||
|5.6.2.2 A095|x|||||
|5.6.2.2 S100|x|||||
|5.6.2.2 A115|x|||||
|5.6.2.2 A220|x|||||
|5.6.3||||x||
|5.6.3.1||||x||
|5.6.3.1 Figure 2||||x||
|5.6.4||||x||
|5.6.4.1||||x||
|5.6.4.1.1|x|||||
|5.6.4.1.2|x|||||
|5.6.4.1.3||||x||
|5.6.4.2|x|||||
|5.6.4.3|x|||||

<!-- end of page 91 -->

|||Claus|e classificati|on||
|---|---|---|---|---|---|
|Clause number|ETCS on-<br>board<br>requirement|ETCS<br>trackside<br>requirement|Definition|Informative|Others|
|5.7||||x||
|5.7.1||||x||
|5.7.1.1||||x||
|5.7.1.2||||x||
|5.7.1.3||x||||
|5.7.1.4||||x||
|5.7.1.5||||x||
|5.7.2||||x||
|5.7.2.1||||x||
|5.7.2.2|||x|||
|5.7.2.3|x|||||
|5.7.2.4|x|||||
|5.7.3||||x||
|5.7.3.1||||x||
|5.7.3.1 a)||||x||
|5.7.3.1 b)||||x||
|5.7.3.2|x|||||
|5.7.3.2 a)|x|||||
|5.7.3.2 b)|x|||||
|5.7.3.3|x|||||
|5.7.3.4|||||x|
|5.7.3.5|x|||||
|5.7.3.6|x|||||
|5.7.3.7|x|||||
|5.7.4||||x||
|5.7.4.1|x|||||
|5.7.4.2|x|||||
|5.7.5||||x||
|5.7.5 Figure 3||||x||
|5.8||||x||
|5.8.1||||x||
|5.8.1.1||||x||
|5.8.1.2||||x||
|5.8.1.2 1<sup>st</sup>bullet||||x||
|5.8.1.2 2<sup>nd</sup>bullet||||x||
|5.8.1.2 3<sup>rd</sup>bullet||||x||
|5.8.1.2 4<sup>th</sup>bullet||||x||
|5.8.1.2 5<sup>th</sup>bullet||||x||
|5.8.1.2 6<sup>th</sup>bullet||||x||
|5.8.1.3||||x||
|5.8.1.4||||x||
|5.8.1.4.1||||x||
|5.8.1.5||||x||
|5.8.1.6||||x||

<!-- end of page 92 -->

|||Claus|e classificati|on||
|---|---|---|---|---|---|
|Clause number|ETCS on-<br>board<br>requirement|ETCS<br>trackside<br>requirement|Definition|Informative|Others|
|5.8.1.7||||x||
|5.8.1.7 a)||||x||
|5.8.1.7 b)||||x||
|5.8.1.7 c)<br>||||x||
|5.8.1.7 d)||||x||
|5.8.1.7 e)|||||x|
|5.8.1.8||||x||
|5.8.1.9|x|||||
|5.8.2||||x||
|5.8.2.1|x|||||
|5.8.2.1 a)|x|||||
|5.8.2.1 b)|x|||||
|5.8.2.1 c)|x|||||
|5.8.2.2|||||x|
|5.8.2.3|x|||||
|5.8.3||||x||
|5.8.3.1|x|||||
|5.8.3.1 a)|x|||||
|5.8.3.1 b)|x|||||
|5.8.3.1 c)|x|||||
|5.8.3.1.1|x|||||
|5.8.3.1.2||||x||
|5.8.3.1.3|x|||||
|5.8.3.1.3 a)|x|||||
|5.8.3.1.3 b)|x|||||
|5.8.3.2||||x||
|5.8.3.3||||x||
|5.8.3.4||||x||
|5.8.3.5||||x||
|5.8.3.6|x|||||
|5.8.3.7|x|||||
|5.8.3.7.1|x|||||
|5.8.3.7.2|x|||||
|5.8.3.8|x|||||
|5.8.3.9|x|||||
|5.8.4||||x||
|5.8.4.1|x|||||
|5.8.4.1 a)|x|||||
|<br>5.8.4.1 b)|x|||||
|5.8.4.1 c)|x|||||
|5.8.4.1 d)|x|||||
|5.8.4.1 e)|x|||||
|5.8.4.1 f)|x|||||
|5.8.4.1g)|x|||||

<!-- end of page 93 -->

|Clause number|ETCS on-<br>board<br>requirement|Claus<br>ETCS<br>trackside<br>requirement|e classificati<br>Definition|on<br>Informative|Others|
|---|---|---|---|---|---|
|5.8.4.1 h)|x|||||
|5.8.4.1 i)|x|||||
|5.8.4.1.1||||x||
|5.8.4.2|x|||||
|5.8.4.3|||||x|
|5.9||||x||
|5.9.1||||x||
|5.9.1.1|x|||||
|5.9.1.2||||x||
|5.9.2||||x||
|5.9.2.1|x|||||
|5.9.2.2|x|||||
|5.9.2.3|x|||||
|5.9.2.4|x|||||
|5.9.2.5||||x||
|5.9.2.5 Figure 4||||x||
|5.9.2.6||||x||
|5.9.2.7|x|||||
|5.9.3||||x||
|5.9.3.1||||x||
|5.9.3.1 a)||||x||
|5.9.3.1 b)||||x||
|5.9.3.2|x|||||
|5.9.3.2 a)|x|||||
|5.9.3.2 b)|x|||||
|5.9.3.2 c)|x|||||
|5.9.3.3|||x|||
|5.9.3.4|x|||||
|5.9.3.5|||||x|
|5.9.3.6|x|||||
|5.9.3.6 Figure 5||||x||
|5.9.3.7|x|||||
|5.9.3.8|x|||||
|5.9.4||||x||
|5.9.4.1||||x||
|5.9.4.2|x|||||
|5.9.5||||x||
|5.9.5.1|x|||||
|5.9.5.2|x|||||
|5.9.6||||x||
|5.9.6.1||||x||
|5.9.6.1.1|x|||||

<!-- end of page 94 -->

|Clause number|ETCS on-<br>board<br>requirement|Claus<br>ETCS<br>trackside<br>requirement|e classificati<br>Definition|on<br>Informative|Others|
|---|---|---|---|---|---|
|5.9.6.2||||x||
|5.9.6.2.1||||x||
|5.9.6.2.2||||x||
|5.9.6.2.3||||x||
|5.9.6.2.3 1<sup>st</sup>bullet||||x||
|5.9.6.2.3 2<sup>nd</sup>bullet||||x||
|5.9.6.2.4||||x||
|5.9.6.3||||x||
|5.9.6.3.1||||x||
|5.9.6.3.2||||x||
|5.9.7||||x||
|5.9.7 Figure 6||||x||
|5.10||||x||
|5.10.1||||x||
|5.10.1.1||x||||
|5.10.1.2||x||||
|5.10.1.3|x|||||
|5.10.1.3.1||||x||
|5.10.1.4||x||||
|5.10.1.4.1||||x||
|5.10.1.4.1 Figure 7||||x||
|5.10.1.5|x|||||
|5.10.1.6|x|||||
|5.10.1.6.1|x|||||
|5.10.1.7|x|||||
|5.10.1.7.1||||x||
|5.10.1.7.2||||x||
|5.10.1.8|x|||||
|5.10.1.8.1||||x||
|5.10.1.9||||x||
|5.10.2||||x||
|5.10.2.1||x||||
|5.10.2.2||x||||
|5.10.2.2.1||||x||
|5.10.2.3||x||||
|5.10.2.3.1|||||x|
|5.10.2.4|x|||||
|5.10.2.4.1|x|||||
|5.10.2.4.1 a)|x|||||
|<br>5.10.2.4.1 a) 1<sup>st</sup>bullet|x|||||
|5.10.2.4.1 a) 2<sup>nd</sup>||||||
|<br>bullet|x|||||
|5.10.2.4.1 a) 3<sup>rd</sup>bullet|x|||||
|5.10.2.4.1 a) 4<sup>th</sup>bullet|x|||||

<!-- end of page 95 -->

|Clause number|ETCS on-<br>board<br>requirement|Claus<br>ETCS<br>trackside<br>requirement|e classificati<br>Definition|on<br>Informative|Others|
|---|---|---|---|---|---|
|5.10.2.4.1 a) last||||||
|sentence|x|||||
|5.10.2.4.1 b)|x|||||
|5.10.2.4.1 c)|x|||||
|5.10.2.4.1.1||||x||
|5.10.2.4.2||||x||
|5.10.2.5|x|||||
|5.10.2.6|x|||||
|5.10.2.7|x|||||
|5.10.2.7.1||||x||
|5.10.2.8|x|||||
|5.10.2.9|x|||||
|5.10.2.9 a)|x|||||
|5.10.2.9 b)|x|||||
|5.10.2.10|x|||||
|5.10.2.10 a)|x|||||
|5.10.2.10 b)|x|||||
|5.10.2.10.1|||||x|
|5.10.3||||x||
|5.10.3.1||||x||
|5.10.3.1.1||x||||
|5.10.3.1.2||x||||
|5.10.3.1.2 a)||x||||
|5.10.3.1.2 b)||x||||
|5.10.3.1.3|x|||||
|5.10.3.1.4|x|||||
|5.10.3.1.5|x|||||
|5.10.3.1.6||x||||
|5.10.3.2||||x||
|5.10.3.2.1||x||||
|5.10.3.2.2|x|||||
|5.10.3.2.3||x||||
|5.10.3.2.4||||x||
|5.10.3.2.5|x|||||
|5.10.3.2.6||x||||
|5.10.3.3||||x||
|5.10.3.3.1||x||||
|5.10.3.3.1 a)||x||||
|5.10.3.3.1 b)||x||||
|5.10.3.3.2|x|||||
|5.10.3.3.3|x|||||
|5.10.3.3.4||||x||
|5.10.3.3.5|x|||||
|5.10.3.3.5.1||||x||

<!-- end of page 96 -->

|Clause number|ETCS on-<br>board<br>requirement|Claus<br>ETCS<br>trackside<br>requirement|e classificati<br>Definition|on<br>Informative|Others|
|---|---|---|---|---|---|
|5.10.3.4||||x||
|5.10.3.4.1||x||||
|5.10.3.4.2||||x||
|5.10.3.5||||x||
|5.10.3.5.1||x||||
|5.10.3.5.1 a)||x||||
|5.10.3.5.1 b)||x||||
|5.10.3.5.2||||x||
|5.10.3.6||||x||
|5.10.3.6.1||x||||
|5.10.3.6.1 a)||x||||
|5.10.3.6.1 b)||x||||
|5.10.3.6.2|x|||||
|5.10.3.6.3||||x||
|5.10.3.6.4||||x||
|5.10.3.6.5|x|||||
|5.10.3.6.5.1||||x||
|5.10.3.7||||x||
|5.10.3.7.1||x||||
|5.10.3.7.2|x|||||
|5.10.3.7.3||x||||
|5.10.3.7.4||||x||
|5.10.3.7.5|x|||||
|5.10.3.7.6||x||||
|5.10.3.8||||x||
|5.10.3.8.1||x||||
|5.10.3.8.2||||x||
|5.10.3.8.3||||x||
|5.10.3.9||||x||
|5.10.3.9.1||x||||
|5.10.3.9.1 a)||||x||
|5.10.3.9.1 b)||||x||
|5.10.3.9.2|||||x|
|5.10.3.9.3||||x||
|5.10.3.10||||x||
|5.10.3.10.1||x||||
|5.10.3.10.1 a)||||x||
|5.10.3.10.1 b)||||x||
|5.10.3.10.2|||||x|
|5.10.3.10.3|x|||||
|5.10.3.10.4||||x||
|5.10.3.10.5||||x||
|5.10.3.10.6|x|||||
|5.10.3.10.6.1||||x||

<!-- end of page 97 -->

|||Claus|e classificati|on||
|---|---|---|---|---|---|
|Clause number|ETCS on-<br>board<br>requirement|ETCS<br>trackside<br>requirement|Definition|Informative|Others|
|5.10.3.11||||x||
|5.10.3.11.1|||||x|
|5.10.3.11.2||||x||
|5.10.3.11.3|||||x|
|5.10.3.12||||x||
|5.10.3.12.1||||x||
|5.10.3.12.2||||x||
|5.10.3.12.3|||||x|
|5.10.3.13||||x||
|5.10.3.13.1|||||x|
|5.10.3.13.2||||x||
|5.10.3.13.3||||x||
|5.10.3.14||||x||
|5.10.3.14.1|x|||||
|5.10.3.14.2|x|||||
|5.10.3.14.3|x|||||
|5.10.3.14.4|x|||||
|5.10.3.14.5||||x||
|5.10.3.15||||x||
|5.10.3.15.1||||x||
|5.10.3.15.2|x|||||
|5.10.3.15.2 a)|x|||||
|<br>5.10.3.15.2 a) 1<sup>st</sup>||||||
|bullet|x|||||
|5.10.3.15.2 a) 2<sup>nd</sup><br>||||||
|bullet|x|||||
|5.10.3.15.2 a) 3<sup>rd</sup>||||||
|<br>bullet|x|||||
|5.10.3.15.2 b)|x|||||
|5.10.3.15.2.1||||x||
|5.10.3.15.3|x|x||||
|5.10.3.15.4|x|||||
|5.10.4||||x||
|5.10.4.1|x|||||
|5.10.4.1 a)|x|||||
|5.10.4.1 b)|x|||||
|5.10.4.1.1|x|||||
|5.10.4.1.2|x|||||
|5.10.4.1.3|x|||||
|5.10.4.1.4|x|||||
|5.10.4.2|x|||||
|5.10.4.3|||||x|
|5.10.4.4|x|||||
|5.10.4.4 Table|x|||||
|5.11||||x||

<!-- end of page 98 -->

|Clause number|ETCS on-<br>board<br>requirement|Claus<br>ETCS<br>trackside<br>requirement|e classificati<br>Definition|on<br>Informative|Others|
|---|---|---|---|---|---|
|5.11.1||||x||
|5.11.1.1||||x||
|5.11.2||||x||
|5.11.2.1||||x||
|5.11.2.2||||x||
|5.11.2.2 S010|x|||||
|5.11.2.2 A025|x|||||
|5.11.2.2 D020|x|||||
|5.11.2.2 A030|x|||||
|5.11.2.2 A035|x|||||
|5.11.2.2 S050|x|||||
|5.11.2.2 S060|x|||||
|5.11.2.2 D80|x|||||
|5.11.2.2 A105|x|||||
|5.11.2.2 D085|x|||||
|5.11.2.2 A140|x|||||
|5.11.2.2 D090|x|||||
|5.11.2.2 A145|x|||||
|5.11.2.2 A150|x|||||
|5.11.2.2 D110|x|||||
|5.11.2.2 A115|x|x||||
|5.11.2.2 S120|x|||||
|5.11.2.2 D130|x|||||
|5.11.2.2 S130|x|||||
|5.11.2.2 S140|x|||||
|5.11.2.2 S140 a)|x|||||
|5.11.2.2 S140 b)|x|||||
|5.11.2.2 S140 c)|x|||||
|5.11.2.2 S140 d)|x|||||
|5.11.2.2 S150|x|||||
|5.11.2.2 S150 a)|x|||||
|5.11.2.2 S150 b)|x|||||
|5.11.2.2 S150 c)|x|||||
|5.11.2.2 S160|x|||||
|5.11.2.2 S170|x|||||
|5.11.3||||x||
|5.11.3.1||||x||
|5.11.3.1 Figure 8||||x||
|5.11.4||||x||
|5.11.4.1||||x||
|5.11.4.1.1|x|||||
|5.11.4.1.2|x|||||
|5.11.4.2|x|||||
|5.11.4.3|x|||||

<!-- end of page 99 -->

|||Claus|e classificati|on||
|---|---|---|---|---|---|
|Clause number|ETCS on-<br>board<br>requirement|ETCS<br>trackside<br>requirement|Definition|Informative|Others|
|5.12||||x||
|5.12.1||||x||
|5.12.1.1||||x||
|5.12.1.2||||x||
|5.12.1.3||||x||
|5.12.1.4||||x||
|5.12.1.5||||x||
|5.12.2||||x||
|5.12.2.1||||x||
|5.12.2.2||||x||
|5.12.2.3||||x||
|5.12.2.4||||x||
|5.12.2.5|x|||||
|5.12.3||||x||
|5.12.3.1||||x||
|5.12.3.1 a)||||x||
|5.12.3.1 b)||||x||
|5.12.3.1 c)||||x||
|5.12.3.2||||x||
|5.12.3.2 a)||||x||
|<br>5.12.3.2 b)||||x||
|5.12.3.3||||x||
|5.12.3.3.1||||x||
|5.12.3.3.2||||x||
|5.12.3.3.3||||x||
|5.12.3.3.4||||x||
|5.12.3.4||||x||
|5.12.3.4.1||||x||
|5.12.3.4.2||||x||
|5.12.3.4.3||||x||
|5.12.3.5||||x||
|5.12.3.5.1||||x||
|5.12.3.5.2||||x||
|5.12.4||||x||
|5.12.4.1||||x||
|5.12.4.2||||x||
|5.12.4.2.1|x|||||
|5.12.4.2.2|x|||||
|5.12.4.3|x|||||
|5.13||||x||
|5.13.1.1||||x||
|5.13.1.2||||x||
|5.13.1.3|x|||||
|5.13.1.4|x|||||

<!-- end of page 100 -->

|||Claus|e classificati|on||
|---|---|---|---|---|---|
|Clause number|ETCS on-<br>board<br>requirement|ETCS<br>trackside<br>requirement|Definition|Informative|Others|
|5.13.1.5|x|||||
|5.13.1.6||x||||
|5.13.1.7||x||||
|5.13.1.8||||x||
|5.14||||x||
|5.14.1||||x||
|5.14.1.1|||x|||
|5.14.1.2|||x|||
|5.14.2||||x||
|5.14.2.1||||x||
|5.14.2.1.1||||x||
|5.14.2.2||||x||
|5.14.2.3||||x||
|5.14.2.4||||x||
|5.14.2.5||||x||
|5.14.3||||x||
|5.14.3.1||||x||
|5.14.3.2||||x||
|5.14.3.3||||x||
|5.14.3.4||||x||
|5.14.3.5||||x||
|5.14.3.6||||x||
|5.15||||x||
|5.15.1||||x||
|5.15.1.1||x||||
|5.15.1.2||x||||
|5.15.1.2.1||||x||
|5.15.1.2.2|||x|||
|5.15.1.2.3||||x||
|5.15.1.3||x||||
|5.15.1.3.1||||x||
|5.15.1.4|x|||||
|5.15.1.5|||||x|
|5.15.2||||x||
|5.15.2.1||||x||
|5.15.2.1.1||||x||
|5.15.2.1.1 a)||||x||
|<br>5.15.2.1.1 b)||||x||
|5.15.2.1.1 c)||||x||
|5.15.2.1.1 d)||||x||
|<br>5.15.2.1.1 e)||||x||
|5.15.2.1.1 f)||||x||
|5.15.2.1.1 g)||||x||
|<br>5.15.2.2||||x||

<!-- end of page 101 -->

|||Claus|e classificati|on||
|---|---|---|---|---|---|
|Clause number|ETCS on-<br>board<br>requirement|ETCS<br>trackside<br>requirement|Definition|Informative|Others|
|5.15.2.2.1||||x||
|5.15.2.2.1.1||||x||
|5.15.2.2.1.2||||x||
|5.15.2.2.2||||x||
|5.15.2.2.2.1||||x||
|5.15.2.2.2.2||||x||
|5.15.2.2.2.3||||x||
|5.15.2.2.3||||x||
|5.15.2.2.3.1||||x||
|5.15.2.2.3.1a)||||x||
|5.15.2.2.3.1b)||||x||
|5.15.2.2.3.1 Figure 9||||x||
|5.15.2.2.3.2||||x||
|5.15.2.2.4||||x||
|5.15.2.2.4.1||||x||
|5.15.2.2.4.2||||x||
|5.15.2.2.4.2.1||||x||
|5.15.2.2.5||||x||
|5.15.2.2.5.1||||x||
|5.15.2.2.5.2||||x||
|5.15.2.2.6||||x||
|5.15.2.2.6.1||||x||
|5.15.2.2.6.2||||x||
|5.15.2.2.7||||x||
|5.15.2.2.7.1||||x||
|5.15.3||||x||
|5.15.3.1||||x||
|5.15.3.1.1||||x||
|5.15.3.1.1 a)||||x||
|5.15.3.1.1 b)||||x||
|5.15.3.1.1 c)||||x||
|5.15.3.1.1 d)||||x||
|5.15.3.1.1 e)||||x||
|5.15.3.1.1 f)||||x||
|5.15.3.2||||x||
|5.15.3.2.1||||x||
|5.15.3.2.1.1||||x||
|5.15.3.2.1.2||||x||
|5.15.3.2.2||||x||
|5.15.3.2.2.1||||x||
|5.15.3.2.2.1 a)||||x||
|5.15.3.2.2.1 b)||||x||
|5.15.3.2.2.2||||x||
|5.15.3.2.3||||x||

<!-- end of page 102 -->

|||Claus|e classificati|on||
|---|---|---|---|---|---|
|Clause number|ETCS on-<br>board<br>requirement|ETCS<br>trackside<br>requirement|Definition|Informative|Others|
|5.15.3.2.3.1||||x||
|5.15.3.2.3.2||||x||
|5.15.3.2.4||||x||
|5.15.3.2.4.1||||x||
|5.15.3.2.4.2||||x||
|5.15.3.2.5||||x||
|5.15.3.2.5.1||||x||
|5.15.3.2.5.2||||x||
|5.15.3.2.6||||x||
|5.15.3.2.6.1||||x||
|5.15.3.2.6.2||||x||
|5.15.4||||x||
|5.15.4.1||||x||
|5.15.4.2||||x||
|5.15.4.3||||x||
|5.15.4.4|||||x|
|5.16||||x||
|5.16.1||||x||
|5.16.1.1||||x||
|5.16.1.2|x|||||
|5.16.1.3|x|||||
|5.16.1.4|x|||||
|5.16.1.4 a)|x|||||
|5.16.1.4 b)|x|||||
|5.16.1.5|x|||||
|5.16.2||||x||
|5.16.2.1|x|||||
|5.16.2.1 Figure 10||||x||
|5.16.3||||x||
|5.16.3.1|x|||||
|5.16.3.2|x|||||
|5.16.3.2 Figure 11||||x||
|5.16.3.3||||x||
|5.17||||x||
|5.17.1||||x||
|5.17.1.1||||x||
|5.17.1.2||||x||
|5.17.1.3||||x||
|5.17.2||||x||
|5.17.2.1||||x||
|5.17.2.2||||x||
|5.17.2.2 S0|x|||||
|5.17.2.2 D0|x|||||
|5.17.2.2 D1|x|||||

<!-- end of page 103 -->

|||Claus|e classificati|on||
|---|---|---|---|---|---|
|Clause number|ETCS on-<br>board<br>requirement|ETCS<br>trackside<br>requirement|Definition|Informative|Others|
|5.17.2.2 D3|x|||||
|5.17.2.2 D5|x|||||
|5.17.2.2 D7|x|||||
|5.17.2.2 A1|x|||||
|5.17.2.2 S2|x|||||
|5.17.2.2 S3|x|||||
|5.17.2.2 A5|x|||||
|5.17.2.2 D2|x|||||
|5.17.2.2 S1|x|||||
|5.17.2.2 D4|x|||||
|5.17.2.2 D9|x|||||
|5.17.2.2 S4|x|||||
|5.17.2.2 S5|x|||||
|5.17.2.2 A6|x|||||
|5.17.2.2 S6|x|||||
|5.17.2.2 A7|x|||||
|5.17.3||||x||
|5.17.3.1||||x||
|5.17.3.1 Figure 12||||x||
|5.18||||x||
|5.18.1||||x||
|5.18.1.1||||x||
|5.18.1.1 a)||||x||
|5.18.1.1 b)||||x||
|5.18.1.1 c)||||x||
|5.18.1.1 d)||||x||
|5.18.1.1 e)||||x||
|5.18.1.1 f)||||x||
|5.18.1.1 g)||||x||
|5.18.1.1 h)||||x||
|5.18.1.1 i)||||x||
|5.18.1.2||||x||
|5.18.2||||x||
|5.18.2.1||||x||
|5.18.2.1.1|||||x|
|5.18.2.2|x|||||
|5.18.2.2.1|x|||||
|5.18.2.2.2|x|||||
|5.18.2.2.2 1<sup>st</sup>bullet|x|||||
|5.18.2.2.2 2<sup>nd</sup>bullet|x|||||
|5.18.2.2.2.1||||x||
|5.18.2.3|x|||||
|5.18.2.3 1<sup>st</sup>bullet|x|||||
|5.18.2.32<sup>nd</sup> bullet|x|||||

<!-- end of page 104 -->

|Clause number|ETCS on-<br>board<br>requirement|Claus<br>ETCS<br>trackside<br>requirement|e classificati<br>Definition|on<br>Informative|Others|
|---|---|---|---|---|---|
|5.18.2.4|||||x|
|5.18.2.4.1|||||x|
|5.18.2.5|x|||||
|5.18.2.5 1<sup>st</sup>bullet|x|||||
|5.18.2.5 2<sup>nd</sup>bullet|x|||||
|5.18.2.5.1|x|||||
|5.18.2.5.1 1<sup>st</sup>bullet|x|||||
|5.18.2.5.1 2<sup>nd</sup>bullet|x|||||
|5.18.2.5.1.1||||x||
|5.18.2.6|x|||||
|5.18.2.6.1||||x||
|5.18.2.6.1 Figure 13||||x||
|5.18.3||||x||
|5.18.3.1||||x||
|5.18.3.2|x|||||
|5.18.3.2.1|x|||||
|5.18.3.2.2|x|||||
|5.18.3.2.2 1<sup>st</sup>bullet|x|||||
|5.18.3.2.2 2<sup>nd</sup>bullet|x|||||
|5.18.3.2.2.1||||x||
|5.18.3.3|x|||||
|5.18.3.3 1<sup>st</sup>bullet|x|||||
|5.18.3.3 2<sup>nd</sup>bullet|x|||||
|5.18.3.4|x|||||
|5.18.3.4 1<sup>st</sup>bullet|x|||||
|5.18.3.4 2<sup>nd</sup>bullet|x|||||
|5.18.3.4.1|x|||||
|5.18.3.4.1 1<sup>st</sup>bullet|x|||||
|5.18.3.4.1 2<sup>nd</sup>bullet|x|||||
|5.18.3.4.1.1||||x||
|5.18.3.5|x|||||
|5.18.3.5.1||||x||
|5.18.3.4.1 Figure 14||||x||
|5.18.4||||x||
|5.18.4.1||||x||
|5.18.4.2|x|||||
|5.18.4.2 a)|x|||||
|5.18.4.2 b)|x|||||
|<br>5.18.4.2 c)|x|||||
|5.18.4.3|x|||||
|5.18.4.4|x|||||
|5.18.4.4 1<sup>st</sup>bullet|x|||||
|5.18.4.4 2<sup>nd</sup>bullet|x|||||
|5.18.4.5|||||x|

<!-- end of page 105 -->

|||Claus|e classificati|on||
|---|---|---|---|---|---|
|Clause number|ETCS on-<br>board<br>requirement|ETCS<br>trackside<br>requirement|Definition|Informative|Others|
|5.18.4.6||||x||
|5.18.4.6 Figure 15||||x||
|5.18.5||||x||
|5.18.5.1||||x||
|5.18.5.2|x|||||
|5.18.5.3|x|||||
|5.18.5.3 Figure 16||||x||
|5.18.6||||x||
|5.18.6.1||||x||
|5.18.6.2|x|||||
|5.18.6.2.1|x|||||
|5.18.6.2.2|x|||||
|5.18.6.2.2 1<sup>st</sup>bullet|x|||||
|5.18.6.2.2 2<sup>nd</sup>bullet|x|||||
|5.18.6.2.2.1||||x||
|5.18.6.3|x|||||
|5.18.6.3 1<sup>st</sup>bullet|x|||||
|5.18.6.3 2<sup>nd</sup>bullet|x|||||
|5.18.6.4|x|||||
|5.18.6.4 1<sup>st</sup>bullet|x|||||
|5.18.6.4 2<sup>nd</sup>bullet|x|||||
|5.18.6.4.1|x|||||
|5.18.6.4.1 1<sup>st</sup>bullet|x|||||
|5.18.6.4.1 2<sup>nd</sup>bullet|x|||||
|5.18.6.4.1.1||||x||
|5.18.6.5|x|||||
|5.18.6.5.1||||x||
|5.18.6.5.1 Figure 17||||x||
|5.18.7||||x||
|5.18.7.1||||x||
|5.18.7.2||||x||
|5.18.7.3|x|||||
|5.18.7.3.1|x|||||
|5.18.7.3.1 1<sup>st</sup>bullet|x|||||
|5.18.7.3.1 2<sup>nd</sup>bullet|x|||||
|5.18.7.3.1.1||||x||
|5.18.7.3.2|x|||||
|5.18.7.4|x|||||
|5.18.7.4 1<sup>st</sup>bullet|x|||||
|5.18.7.4 2<sup>nd</sup>bullet|x|||||
|5.18.7.5|x|||||
|5.18.7.5 Figure 18||||x||
|5.18.8||||x||
|5.18.8.1||||x||

<!-- end of page 106 -->

|||Claus|e classificati|on||
|---|---|---|---|---|---|
|Clause number|ETCS on-<br>board<br>requirement|ETCS<br>trackside<br>requirement|Definition|Informative|Others|
|5.18.8.1.1||||x||
|5.18.8.2|x|||||
|5.18.8.3|x|||||
|5.18.8.3 a)|x|||||
|5.18.8.3 b)|x|||||
|5.18.8.4|x|||||
|5.18.8.5|x|||||
|5.18.8.5 1<sup>st</sup>bullet|x|||||
|5.18.8.5 2<sup>nd</sup>bullet|x|||||
|5.18.8.6||||x||
|5.18.8.6 Figure 19||||x||
|5.18.9||||x||
|5.18.9.1||||x||
|5.18.9.2|x|||||
|5.18.9.2.1|x|||||
|5.18.9.3|x|||||
|5.18.9.4||||x||
|5.18.9.4 Figure 20||||x||
|5.18.10||||x||
|5.18.10.1||||x||
|5.18.10.2|x|||||
|5.18.10.3|x|||||
|5.18.10.4|x|||||
|5.18.10.4 1<sup>st</sup>bullet|x|||||
|5.18.10.4 2<sup>nd</sup>bullet|x|||||
|5.18.10.4.1||||x||
|5.18.10.5|x|||||
|5.18.10.5 1<sup>st</sup>bullet|x|||||
|5.18.10.5 2<sup>nd</sup>bullet|x|||||
|5.18.10.6|x|||||
|5.18.10.6.1||||x||
|5.18.10.6.1 Figure 21||||x||
|5.19||||x||
|5.19.1||||x||
|5.19.1.1||x||||
|5.19.1.2|x|||||
|5.19.2||||x||
|5.19.2.1|x|||||
|5.19.2.2|x|||||
|5.19.2.3|x|||||
|5.19.2.4|x|||||
|5.19.2.5||||x||
|5.19.2.5 Figure 22||||x||
|<br>5.19.2.6||||x||

<!-- end of page 107 -->

|||Claus|e classificati|on||
|---|---|---|---|---|---|
|Clause number|ETCS on-<br>board<br>requirement|ETCS<br>trackside<br>requirement|Definition|Informative|Others|
|5.19.2.7|x|||||
|5.19.3||||x||
|5.19.3.1||||x||
|5.19.3.1 a)||||x||
|5.19.3.1 b)||||x||
|5.19.3.2|x|||||
|5.19.3.2 a)|x|||||
|5.19.3.2 b)|x|||||
|5.19.3.2 c)|x|||||
|5.19.3.3||||x||
|5.19.3.4|x|||||
|5.19.3.5|||||x|
|5.19.3.6|x|||||
|5.19.3.6 Figure 23||||x||
|5.19.3.7|x|||||
|5.19.3.8|x|||||
|5.19.4||||x||
|5.19.4.1||||x||
|5.19.4.2|x|||||
|5.19.5||||x||
|5.19.5.1|x|||||
|5.19.5.2|x|||||
|5.19.6||||x||
|5.19.6.1||||x||
|5.19.6.1.1|x|||||
|5.19.6.2||||x||
|5.19.6.2.1||||x||
|5.19.6.2.2||||x||
|5.19.6.3||||x||
|5.19.6.3.1||||x||
|5.19.6.3.2||||x||
|5.19.7||||x||
|5.19.7 Figure 24||||x||
|5.20||||x||
|5.20.1||||x||
|5.20.1.1||||x||
|5.20.1.1 a)||||x||
|5.20.1.1 b)||||x||
|5.20.1.1 c)||||x||
|<br>5.20.1.1 d)||||x||
|5.20.1.1 e)||||x||
|5.20.1.1 f)||||x||
|5.20.1.1 g)||||x||
|<br>5.20.1.2|x|||||

<!-- end of page 108 -->

|||Claus|e classificati|on||
|---|---|---|---|---|---|
|Clause number|ETCS on-<br>board<br>requirement|ETCS<br>trackside<br>requirement|Definition|Informative|Others|
|5.20.2||||x||
|5.20.2.1||||x||
|5.20.2.2|x|||||
|5.20.2.3|x|||||
|5.20.2.3 1<sup>st</sup>bullet|x|||||
|5.20.2.3 2<sup>nd</sup>bullet|x|||||
|5.20.2.4|x|||||
|5.20.2.5|x|||||
|5.20.2.6||||x||
|5.20.2.6 Figure 25||||x||
|5.20.2.7||||x||
|5.20.2.8|x|||||
|5.20.3||||x||
|5.20.3.1||||x||
|5.20.3.2|x|||||
|5.20.3.3|x|||||
|5.20.3.3 1<sup>st</sup>bullet|x|||||
|5.20.3.3 2<sup>nd</sup>bullet|x|||||
|5.20.3.4|x|||||
|5.20.3.5|x|||||
|5.20.3.6||||x||
|5.20.3.6 Figure 26||||x||
|5.20.3.7||||x||
|5.20.3.8|x|||||
|5.20.4||||x||
|5.20.4.1||||x||
|5.20.4.2|x|||||
|5.20.4.3|x|||||
|5.20.4.3 1<sup>st</sup>bullet|x|||||
|5.20.4.3 2<sup>nd</sup>bullet|x|||||
|5.20.4.4|x|||||
|5.20.4.5|x|||||
|5.20.4.5 Figure 27||||x||
|5.20.4.6||||x||
|5.20.4.7|x|||||
|5.20.5||||x||
|5.20.5.1||||x||
|5.20.5.2||||x||
|5.20.5.3|x|||||
|5.20.5.4|x|||||
|5.20.5.4 1<sup>st</sup>bullet|x|||||
|5.20.5.4 2<sup>nd</sup>bullet|x|||||
|5.20.5.5|x|||||
|5.20.5.6|x|||||

<!-- end of page 109 -->

|||Claus|e classificati|on||
|---|---|---|---|---|---|
|Clause number|ETCS on-<br>board<br>requirement|ETCS<br>trackside<br>requirement|Definition|Informative|Others|
|5.20.5.6 Figure 28||||x||
|5.20.5.7||||x||
|5.20.5.8|x|||||
|5.20.6||||x||
|5.20.6.1||||x||
|5.20.6.2|x|||||
|5.20.6.3|x|||||
|5.20.6.3 1<sup>st</sup>bullet|x|||||
|5.20.6.3 2<sup>nd</sup>bullet|x|||||
|5.20.6.4|x|||||
|5.20.6.5||||x||
|5.20.6.5 Figure 29||||x||
|5.20.6.6|x|||||
|5.20.7||||x||
|5.20.7.1||||x||
|5.20.7.2|x|||||
|5.20.7.3|x|||||
|5.20.7.4|x|||||
|5.20.7.4 1<sup>st</sup>bullet|x|||||
|5.20.7.4 2<sup>nd</sup>bullet|x|||||
|5.20.7.5|x|||||
|5.20.7.6||||x||
|5.20.7.6 Figure 30||||x||
|5.20.7.7|x|||||
|5.20.8||||x||
|5.20.8.1||||x||
|5.20.8.2|x|||||
|5.20.8.3|x|||||
|5.20.8.4|x|||||
|5.20.8.4 1<sup>st</sup>bullet|x|||||
|5.20.8.4 2<sup>nd</sup>bullet|x|||||
|5.20.8.4 3<sup>rd</sup>bullet|x|||||
|5.20.8.4 4<sup>th</sup>bullet|x|||||
|5.20.8.5|x|||||
|5.20.8.6|x|||||
|5.20.8.7||||x||
|5.20.8.7 Figure 31||||x||
|5.20.8.8||||x||
|5.20.8.9|x|||||
|5.21||||x||
|5.21.1||||x||
|5.21.1.1||||x||
|5.21.2||||x||
|5.21.2.1||||x||

<!-- end of page 110 -->

|Clause number|ETCS on-<br>board<br>requirement|Claus<br>ETCS<br>trackside<br>requirement|e classificati<br>Definition|on<br>Informative|Others|
|---|---|---|---|---|---|
|5.21.2.2||||x||
|5.21.2.2 S0|x|||||
|5.21.2.2 A045|x|||||
|5.21.2.2 S050|x|||||
|5.21.2.2 D080|x|||||
|5.21.2.2 A050|x|||||
|5.21.2.2 A075|x|||||
|5.21.2.2 A095|x|||||
|5.21.2.2 A220|x|||||
|5.21.3||||x||
|5.21.3.1||||x||
|5.21.3.1 Figure 32||||x||
|5.21.4||||x||
|5.21.4.1|x|||||
|5.22||||x||
|5.22.1||||x||
|5.22.1.1||||x||
|5.22.1.2||||x||
|5.22.1.3||||x||
|5.22.1.4||||x||
|5.22.1.5||||x||
|5.22.1.6||||x||
|5.22.1.7||||x||
|5.22.1.8||||x||
|5.22.2||||x||
|5.22.2.1|x|||||
|5.22.2.2|x|||||
|5.22.3||||x||
|5.22.3.1|x|||||
|5.22.3.1.1|x|||||
|5.22.4||||x||
|5.22.4.1|x|||||
|5.22.4.2|x|||||
|5.22.5||||x||
|5.22.5.1|x|||||
|5.22.5.1 a)|x|||||
|5.22.5.1 b)|x|||||
|5.22.5.1 c)|x|||||
|5.22.5.2|x|||||
|5.22.5.2.1|x|||||
|5.22.5.3||||x||

<!-- end of page 111 -->

## **9.4.6 Chapter 6**

|||Clause|classification||||Replacing Cl|ause classif|ication||
|---|---|---|---|---|---|---|---|---|---|---|
||ETCS on-||||Replaced||||||
|Clause<br>number|board<br>requireme<br>nt|ETCS<br>trackside<br>requirement|Definition<br>Informative|Others|<br>clause<br>number|ETCS on-<br>board<br>requirement|ETCS<br>trackside<br>requirement|Definition|Informative|Others|
|6.1|||x||||||||
|6.2|||x||||||||
|6.3|||x||||||||
|6.3.1.1|||x||||||||
|6.3.1.1 a)|||x||||||||
|6.3.1.1 b)|||x||||||||
|6.3.1.2|||x||||||||
|6.4|||x||||||||
|6.4.1|||x||||||||
|6.4.1.1|||x||||||||
|6.4.1.1.1||x|||||||||
|6.4.1.2|||x||||||||
|6.4.1.2.1||x|||||||||
|6.4.1.2.2||x|||||||||
|6.4.1.2.3||x|||||||||
|6.4.2|||x||||||||
|6.4.2.1|x||||||||||
|6.4.2.2|x||||||||||
|6.5|||x||||||||
|6.5.1|||x||||||||
|6.5.1.1|||x||||||||
|6.5.1.1.1|||x||||||||
|6.5.1.1.2||x|||||||||
|6.5.1.1.3||x|||||||||

<!-- end of page 112 -->

||ETCS on-|Clause|classification||Replaced||Replacing Cl|ause classif|ication||
|---|---|---|---|---|---|---|---|---|---|---|
|Clause<br>number|<br>board<br>requireme<br>nt|ETCS<br>trackside<br>requirement|Definition<br>Informative|Others|<br>clause<br>number|ETCS on-<br>board<br>requirement|ETCS<br>trackside<br>requirement|Definition|Informative|Others|
|6.5.1.1.3.1|||x||||||||
|6.5.1.2|||x||||||||
|6.5.1.2.1||||x|||||||
|6.5.1.2.1.1||x|||||||||
|6.5.1.2.1.2||x|||3.5.2.6.1 b)|||x|||
|6.5.1.2.1.3||x|||3.5.2.6.2 b)|||x|||
|6.5.1.2.1.4||x|||3.5.3.7 e)||x||||
|6.5.1.2.1.5||x|||3.5.4.6||x||||
|6.5.1.2.1.6||x|||||||||
|6.5.1.2.2||x|||3.7.1.1 b)||x||||
|6.5.1.2.3||x|||||||||
|6.5.1.2.4||x|||||||||
|6.5.1.2.5||x|||||||||
|6.5.1.2.6||x|||3.9.3.2||x||||
|6.5.1.2.7||x|||||||||
|6.5.1.2.8||x|||||||||
|6.5.1.2.9||||x|||||||
|6.5.1.2.10||x|||||||||
|6.5.1.2.11||x|||||||||
|6.5.1.2.12||x|||||||||
|6.5.1.2.13||x|||||||||
|6.5.1.2.14||x|||||||||
|6.5.1.2.15||x|||3.12.4.1||x||||
|6.5.1.2.16||x|||3.15.1.2.3.1<br>i)||x||||
|6.5.1.2.17||x|||||||||
|6.5.1.2.18||x|||||||||

<!-- end of page 113 -->

|||Clause|classification||||Replacing Cl|ause classif|ication||
|---|---|---|---|---|---|---|---|---|---|---|
||ETCS on-||||Replaced||||||
|Clause<br>number|<br>board<br>requireme<br>nt|ETCS<br>trackside<br>requirement|Definition<br>Informative|Others|<br>clause<br>number|ETCS on-<br>board<br>requirement|ETCS<br>trackside<br>requirement|Definition|Informative|Others|
|6.5.1.3|||x||||||||
|6.5.1.3.1||||x|||||||
|6.5.1.4|||x||||||||
|6.5.1.4.1||x|||5.5.3.1.3|{1}|x||||
|6.5.1.4.2||x|||||||||
|6.5.1.5|||x||||||||
|6.5.1.5.1||x|||7.3.3.5|||x|||
|6.5.1.5.2||x|||7.4.1.1||||x||
|6.5.1.5.2.1||x|||7.4.1.2||||x||
|6.5.1.5.3||x|||||||||
|6.5.1.5.4||x|||7.4.2.1.1|{1}|x||||
|6.5.1.5.5||x|||||||||
|6.5.1.5.6||x|||7.4.2.7|{1}|x||||
|6.5.1.5.7||x|||7.4.2.8|{1}|x||||
|6.5.1.5.8||x|||||||||
|6.5.1.5.9||x|||7.4.2.11|{1}|x||||
|6.5.1.5.9.1||x|||7.4.2.11.1|{1}|x||||
|6.5.1.5.10||x|||7.4.2.13|{1}|x||||
|6.5.1.5.11||x|||||||||
|6.5.1.5.12||x|||||||||
|6.5.1.5.12.1||x|||7.4.2.19|{1}|x||||
|6.5.1.5.13||x|||||||||
|6.5.1.5.14||x|||7.4.2.21|{1}|x||||
|6.5.1.5.15||x|||7.4.2.23|{1}|x||||
|6.5.1.5.16||x|||||||||
|6.5.1.5.17||x|||7.4.2.25|{1}|x||||

<!-- end of page 114 -->

|||Clause|classification||||Replacing Cl|ause classif|ication||
|---|---|---|---|---|---|---|---|---|---|---|
||ETCS on-||||Replaced||||||
|Clause<br>number|<br>board<br>requireme<br>nt|ETCS<br>trackside<br>requirement|Definition<br>Informative|Others|<br>clause<br>number|ETCS on-<br>board<br>requirement|ETCS<br>trackside<br>requirement|Definition|Informative|Others|
|6.5.1.5.18||x|||7.4.2.26|{1}|x||||
|6.5.1.5.19||x|||||||||
|6.5.1.5.20||x|||||||||
|6.5.1.5.20.1||x|||||||||
|6.5.1.5.20.2||x|||||||||
|6.5.1.5.21||x|||||||||
|6.5.1.5.22||x|||||||||
|6.5.1.5.23||x|||||||||
|6.5.1.5.24||x|||||||||
|6.5.1.5.25||x|||||||||
|6.5.1.5.25.1||x|||7.4.3.1|{1}|x||||
|6.5.1.5.25.2||x|||7.4.3.2|{1}|x||||
|6.5.1.5.25.3||x|||||||||
|6.5.1.5.25.4||x|||7.4.3.5|{1}|x||||
|6.5.1.5.26||x|||7.5.1.36|{1}|x||||
|6.5.1.5.27||x|||||||||
|6.5.1.5.27.1||x|||7.5.1.64|{1}|x||||
|6.5.1.5.27.2||x|||7.5.1.68|{1}|x||||
|6.5.1.5.27.3||x|||7.5.1.65|{1}|x||||
|6.5.1.5.27.4||x|||7.5.1.66|{1}|x||||
|6.5.1.5.27.5||x|||7.5.1.67|{1}|x||||
|6.5.1.5.28||x|||7.5.1.70|{1}|x||||
|6.5.1.5.28.1||x|||7.5.1.72|{1}|x||||
|6.5.1.5.29||x|||7.5.1.73|{1}|x||||
|6.5.1.5.30||x|||7.5.1.76|{1}|x||||
|6.5.1.5.31||x|||7.5.1.77|{1}|x||||

<!-- end of page 115 -->

|||Clause|classification||||Replacing Cl|ause classif|ication||
|---|---|---|---|---|---|---|---|---|---|---|
||ETCS on-||||Replaced||||||
|Clause<br>number|<br>board<br>requireme<br>nt|ETCS<br>trackside<br>requirement|Definition<br>Informative|Others|<br>clause<br>number|ETCS on-<br>board<br>requirement|ETCS<br>trackside<br>requirement|Definition|Informative|Others|
|6.5.1.5.32||x|||||||||
|6.5.1.5.33||x|||||||||
|6.5.1.5.34||x|||7.5.1.83|{1}|x||||
|6.5.1.5.34.1||x|||7.5.1.84|{1}|x||||
|6.5.1.5.34.2||x|||7.5.1.91.1|{1}|x||||
|6.5.1.5.34.3||x|||7.5.1.92|{1}|x||||
|6.5.1.5.34.4||x|||7.5.1.107|{1}|x||||
|6.5.1.5.35||x|||7.5.1.138|{1}|x||||
|6.5.1.5.35.1||x|||||||||
|6.5.1.5.35.2||x|||7.5.1.172|{1}|x||||
|6.5.1.5.36|||x||||||||
|6.5.1.6|||x||||||||
|6.5.1.6.1||x|||||||||
|6.5.1.6.2||x|||8.4.1.4.8||x||||
|6.5.1.6.3||x|||8.4.2.1|||x|||
|6.5.1.6.4||x|||8.4.2.3||x||||
|6.5.1.6.5||x|||8.4.4.4.1<br>Table|{1}|x||||
|6.5.1.6.6||x|||8.4.4.4.1.1<br>Table|{1}|x||||
|6.5.1.6.6.1||x|||8.4.4.4.2|{1}|x||||
|6.5.1.6.6.1.1||x|||||||||
|6.5.1.6.6.2||x|||8.5.2|{1}|x||||
|6.5.1.6.6.2.1||x|||8.5.3|{1}|x||||
|6.5.1.6.6.2.2||x|||||||||
|6.5.1.6.6.3||x|||8.6.3|{1}|x||||
|6.5.1.6.6.3.1||x|||||||||

<!-- end of page 116 -->

||ETCS on-|Clause|classification||Replaced||Replacing Cl|ause classif|ication||
|---|---|---|---|---|---|---|---|---|---|---|
|Clause<br>number|<br>board<br>requireme<br>nt|ETCS<br>trackside<br>requirement|Definition<br>Informative|Others|<br>clause<br>number|ETCS on-<br>board<br>requirement|ETCS<br>trackside<br>requirement|Definition|Informative|Others|
|6.5.1.6.6.3.2||x|||8.6.10|{1}|5.5.3.1.3<br>step 3||||
|6.5.1.6.6.4||x|||||||||
|6.5.1.6.6.5||x|||8.6.17|{1}|x||||
|6.5.1.6.6.6||x|||||||||
|6.5.1.6.6.7||x|||||||||
|6.5.1.6.6.8||x|||||||||
|6.5.1.6.7||x|||8.7.6|{1}|x||||
|6.5.1.6.8||x|||8.7.14|{1}|x||||
|6.5.1.6.9||x|||||||||
|6.5.1.6.10|||x||||||||
|6.5.1.7|||x||||||||
|6.5.1.7.1||x|||||||||
|6.5.1.7.2||x|||||||||
|6.5.1.7.3||x|||||||||
|6.5.1.7.4||x|||||||||
|6.5.1.7.5||x|||||||||
|6.5.1.7.6||x|||||||||
|6.5.2|||x||||||||
|6.5.2.1|||x||||||||
|6.5.2.1.1|||x||||||||
|6.5.2.1.1.1||||x|||||||
|6.5.2.1.2||x|||||||||
|6.5.2.1.3||x|||||||||
|6.5.2.1.3.1|||x||||||||
|6.5.2.2|||x||||||||
|6.5.2.2.1||x|||||||||

<!-- end of page 117 -->

||ETCS on-|Clause|classification||Replaced||Replacing Cl|ause classif|ication||
|---|---|---|---|---|---|---|---|---|---|---|
|Clause<br>number|<br>board<br>requireme<br>nt|ETCS<br>trackside<br>requirement|Definition<br>Informative|Others|<br>clause<br>number|ETCS on-<br>board<br>requirement|ETCS<br>trackside<br>requirement|Definition|Informative|Others|
|6.5.2.2.2||x|||||||||
|6.5.2.2.3||x|||||||||
|6.5.2.2.4||x|||||||||
|6.5.2.2.5||x|||||||||
|6.5.2.3|||x||||||||
|6.5.2.3.1||x|||||||||
|6.5.2.3.1.1||x|||||||||
|6.5.2.3.1.1.1||x|||7.4.1.1||||x||
|6.5.2.3.1.1.2||x|||||||||
|6.5.2.3.1.1.3||x|||||||||
|6.5.2.3.1.1.4||x|||7.5.1.73|{1}|x||||
|6.5.2.3.1.2||x|||||||||
|6.5.2.3.1.2.1||x|||8.4.4.4.1.1<br>Table|{1}|x||||
|6.5.2.3.2||x|||||||||
|6.5.2.3.2.1||x|||7.4.1.2||||x||
|6.5.2.3.2.2||x|||||||||
|6.5.2.3.2.3||x|||||||||
|6.5.2.3.2.4||x|||7.5.1.72|{1}|x||||
|6.5.2.3.3||x|||||||||
|6.5.2.3.3.1||x|||7.4.1.2||||x||
|6.5.2.3.3.2||x|||||||||
|6.5.2.3.3.3||x|||8.6.17|{1}|x||||
|6.5.2.3.3.4||x|||||||||
|6.5.2.3.4||x|||||||||
|6.5.2.3.4.1||x|||||||||
|6.5.2.3.5||x|||||||||

<!-- end of page 118 -->

|||Clause|classification||||Replacing Cl|ause classif|ication||
|---|---|---|---|---|---|---|---|---|---|---|
||ETCS on-||||Replaced||||||
|Clause<br>number|<br>board<br>requireme<br>nt|ETCS<br>trackside<br>requirement|Definition<br>Informative|Others|<br>clause<br>number|ETCS on-<br>board<br>requirement|ETCS<br>trackside<br>requirement|Definition|Informative|Others|
|6.5.2.3.5.1||x|||7.5.1.64|{1}|x||||
|6.5.2.3.5.2||x|||8.4.4.4.3|{1}|x||||
|6.5.2.3.6||x|||||||||
|6.5.2.3.6.1||x|||7.5.1.72|{1}|x||||
|6.5.2.3.6.2||x|||7.5.1.73|{1}|x||||
|6.5.2.3.6.3||x|||8.4.4.4.3|{1}|x||||
|6.5.2.3.7||x|||||||||
|6.5.2.3.7.1||x|||||||||
|6.5.2.3.7.2||x|||||||||
|6.5.2.3.8||x|||||||||
|6.5.2.3.8.1||x|||||||||
|6.5.2.3.8.2||x|||||||||
|6.5.2.3.9||x|||||||||
|6.5.2.3.9.1||x|||||||||
|6.5.2.3.9.2||x|||||||||
|6.5.2.3.10||x|||||||||
|6.5.2.3.10.1||x|||||||||
|6.5.2.3.11||x|||||||||
|6.5.2.3.11.1||x|||||||||
|6.5.2.3.12||x|||||||||
|6.5.2.3.12.1||x|||7.4.2.13|{1}|x||||
|6.5.2.3.12.2||x|||7.4.2.21|{1}|x||||
|6.5.2.3.13||x|||||||||
|6.5.2.3.13.1||x|||7.4.2.11.1|{1}|x||||
|6.5.2.3.14||x|||||||||
|6.5.2.3.14.1||x|||7.4.1.1|{1}|x||||

<!-- end of page 119 -->

|||Clause|classification||||Replacing Cl|ause classif|ication||
|---|---|---|---|---|---|---|---|---|---|---|
||ETCS on-||||Replaced||||||
|Clause<br>number|<br>board<br>requireme<br>nt|ETCS<br>trackside<br>requirement|Definition<br>Informative|Others|<br>clause<br>number|ETCS on-<br>board<br>requirement|ETCS<br>trackside<br>requirement|Definition|Informative|Others|
|6.5.2.3.15||x|||||||||
|6.5.2.3.15.1||x|||8.4.4.4.1.1<br>Table|{1}|x||||
|6.5.2.3.16||x|||||||||
|6.5.2.3.16.1||x|||7.4.1.1|{1}|x||||
|6.5.2.3.16.2||x|||||||||
|6.5.2.3.17||x|||||||||
|6.5.2.3.17.1||x|||8.4.4.4.1<br>Table|{1}|x||||
|6.5.2.3.18||x|||||||||
|6.5.2.3.18.1||x|||8.4.4.4.1.1<br>Table|{1}|x||||
|6.5.2.3.19|||x||||||||
|6.5.2.4|||x||||||||
|6.5.2.4.1||x|||||||||
|6.5.2.4.2||x|||||||||
|6.5.2.4.3||x|||||||||
|6.5.2.4.4||x|||||||||
|6.5.2.4.5||x|||||||||
|6.5.3|||x||||||||
|6.5.3.1|||x||||||||
|6.5.3.1.1|||x||||||||
|6.5.3.1.2||x|||||||||
|6.5.3.2|||x||||||||
|6.5.3.2.1||x|||||||||
|6.5.3.3|||x||||||||
|6.5.3.3.1||x|||||||||

<!-- end of page 120 -->

|||Clause|classification||||Replacing Cl|ause classif|ication||
|---|---|---|---|---|---|---|---|---|---|---|
||ETCS on-||||Replaced||||||
|Clause<br>number|<br>board<br>requireme<br>nt|ETCS<br>trackside<br>requirement|Definition<br>Informative|Others|<br>clause<br>number|ETCS on-<br>board<br>requirement|ETCS<br>trackside<br>requirement|Definition|Informative|Others|
|6.5.3.3.2||x|||||||||
|6.5.3.3.3||x|||||||||
|6.6|||x||||||||
|6.6.1|||x||||||||
|6.6.1.1|||x||||||||
|6.6.1.1 a)|||x||||||||
|6.6.1.1 b)|||x||||||||
|6.6.1.1 c)|||x||||||||
|6.6.1.1 d)|||x||||||||
|6.6.2|||x||||||||
|6.6.2.1|||x||||||||
|6.6.2.1.1|x||||3.12.3.4.7.2|x|||||
|6.6.2.1.2|x||||3.6.3.1.4|||x|||
|6.6.2.1.3|x||||3.6.4.2.4<br>Table 2a<br>row<br>“Temporary<br>Speed<br>Restriction”|x|||||
|6.6.2.1.4|x||||3.11.4.3|x|||||
|6.6.2.2|||x||||||||
|6.6.2.2.1|x||||4.4.11.1.3<br>d)|x|||||
|6.6.2.2.2|x||||<br>4.6.3<br>condition<br>[54]|x|||||
|6.6.2.2.3|x||||||||||
|6.6.2.2.4|x||||||||||

<!-- end of page 121 -->

|||Clause|classification||||Replacing Cl|ause classif|ication||
|---|---|---|---|---|---|---|---|---|---|---|
||ETCS on-||||Replaced||||||
|Clause<br>number|<br>board<br>requireme<br>nt|ETCS<br>trackside<br>requirement|Definition<br>Informative|Others|<br>clause<br>number|ETCS on-<br>board<br>requirement|ETCS<br>trackside<br>requirement|Definition|Informative|Others|
|6.6.2.2.5|x||||||||||
|6.6.2.2.6|x||||||||||
|6.6.2.3|||x||||||||
|6.6.2.3.1|x||||5.4.3.2 S10|x|||||
|6.6.2.3.2|x||||||||||
|6.6.2.3.3|x||||5.5.3.1.3|5.5.3.1.3<br>steps 2 & 4|{2}||||
|6.6.2.3.4|x||||||||||
|6.6.2.3.5|x||||5.5.4.1.1|x|||||
|6.6.2.3.6|x||||5.11.2.2<br>S140|x|||||
|6.6.2.3.7|x||||||||||
|6.6.2.4|||x||||||||
|6.6.2.4.1||||x|||||||
|6.6.3|||x||||||||
|6.6.3.1|||x||||||||
|6.6.3.1.1|x||||||||||
|6.6.3.1.1.1|x||||||||||
|6.6.3.1.2|x||||||||||
|6.6.3.2|||x||||||||
|6.6.3.2.1|||x||||||||
|6.6.3.2.2|x||||||||||
|6.6.3.2.3|||x||||||||
|6.6.3.2.3 a)|||x||||||||
|6.6.3.2.3 b)|||x||||||||
|6.6.3.2.3 c)|||x||||||||
|6.6.3.2.3 d)|||x||||||||

<!-- end of page 122 -->

|||Clause|classification||||Replacing Cl|ause classif|ication||
|---|---|---|---|---|---|---|---|---|---|---|
||ETCS on-||||Replaced||||||
|Clause<br>number|<br>board<br>requireme<br>nt|ETCS<br>trackside<br>requirement|Definition<br>Informative|Others|<br>clause<br>number|ETCS on-<br>board<br>requirement|ETCS<br>trackside<br>requirement|Definition|Informative|Others|
|6.6.3.2.3<br>Table|x||||||||||
|6.6.3.2.3<br>Table -<br>footnote [1a]|x||||||||||
|6.6.3.2.3<br>Table -<br>footnote [1b]|x||||||||||
|6.6.3.2.3<br>Table -<br>footnote [2]|x||||||||||
|<br>6.6.3.2.3<br>Table -<br>footnote [3]|x||||||||||
|<br>6.6.3.2.3<br>Table -<br>footnote [4]|x||||||||||
|6.6.3.2.3<br>Table -<br>footnote [5]|x||||||||||
|6.6.3.2.3<br>Table -<br>footnote [6]|x||||||||||
|<br>6.6.3.2.3<br>Table -<br>footnote [7]|x||||||||||
|<br>6.6.3.2.3<br>Table -<br>footnote [8]|x||||||||||
|<br>6.6.3.2.3<br>Table -<br>footnote [9]|x||||||||||

<!-- end of page 123 -->

|||Clause|classification||||Replacing Cl|ause classif|ication||
|---|---|---|---|---|---|---|---|---|---|---|
||ETCS||||Replaced||||||
|Clause<br>number|on-<br>board<br>requireme<br>nt|ETCS<br>trackside<br>requirement|Definition<br>Informative|Others|<br>clause<br>number|ETCS on-<br>board<br>requirement|ETCS<br>trackside<br>requirement|Definition|Informative|Others|
|6.6.3.2.3<br>Table -<br>footnote [10]|x||||||||||
|6.6.3.2.3<br>Table -<br>footnote [11]|x||||||||||
|6.6.3.2.3<br>Table -<br>footnote [12]|x||||||||||
|6.6.3.2.3<br>Table -<br>footnote [13]|x||||||||||
|<br>6.6.3.2.3<br>Table -<br>footnote [14]|x||||||||||
|6.6.3.2.3<br>Table -<br>footnote [15]|x||||||||||
|6.6.3.2.3<br>Table -<br>footnote [16]|x||||||||||
|6.6.3.2.3<br>Table -<br>footnote [17]|x||||||||||
|6.6.3.2.3<br>Table -<br>footnote [18]|x||||||||||
|<br>6.6.3.2.3<br>Table -<br>footnote [19]|x||||||||||

<!-- end of page 124 -->

|||Clause|classification||||Replacing Cl|ause classif|ication||
|---|---|---|---|---|---|---|---|---|---|---|
||ETCS on-||||Replaced||||||
|Clause<br>number|<br>board<br>requireme<br>nt|ETCS<br>trackside<br>requirement|Definition<br>Informative|Others|<br>clause<br>number|ETCS on-<br>board<br>requirement|ETCS<br>trackside<br>requirement|Definition|Informative|Others|
|6.6.3.2.3<br>Table -<br>footnote [20]|x||||||||||
|6.6.3.2.3<br>Table -<br>footnote [21]|x||||||||||
|6.6.3.2.3<br>Table -<br>footnote [22]|x||||||||||
|6.6.3.2.3<br>Table -<br>footnote [23]|x||||||||||
|6.6.3.3|||x||||||||
|6.6.3.3.1|||x||||||||
|6.6.3.3.2|||x||||||||
|6.6.3.3.2 a)|||x||||||||
|6.6.3.3.2 b)|||x||||||||
|6.6.3.3.2 c)|||x||||||||
|6.6.3.3.2 d)|||x||||||||
|6.6.3.3.2<br>Table|x||||||||||
|6.6.3.3.2<br>Table -<br>footnote [1]|x||||||||||
|6.6.3.3.2<br>Table -<br>footnote [2]|x||||||||||
|6.6.3.3.2<br>Table -<br>footnote [2]<br>Note|||x||||||||

<!-- end of page 125 -->

|||Clause|classification||||Replacing Cl|ause classif|ication||
|---|---|---|---|---|---|---|---|---|---|---|
||ETCS on-||||Replaced||||||
|Clause<br>number|<br>board<br>requireme<br>nt|ETCS<br>trackside<br>requirement|Definition<br>Informative|Others|<br>clause<br>number|ETCS on-<br>board<br>requirement|ETCS<br>trackside<br>requirement|Definition|Informative|Others|
|6.6.3.4|||x||||||||
|6.6.3.4.1|||x||||||||
|6.6.3.4.1.1|x||||3.5.3.7 d)<br>1<sup>st</sup>bullet|x|||||
|6.6.3.4.1.2|x||||||||||
|6.6.3.4.1.3|x||||||||||
|6.6.3.4.1.4|x||||3.8.2.1.7|x|||||
|6.6.3.4.1.5|x||||||||||
|6.6.3.4.1.6|x||||||||||
|6.6.3.4.2|x||||3.18.4.5.4|x|||||
|6.6.3.4.3|x||||3.18.4.5.4.1|x|||||
|6.6.3.4.3.1|x||||5.4.3.2 A33<br>& A34|x|||||
|6.6.3.4.4|x||||||||||
|6.6.3.4.5|||x||||||||
|6.6.3.4.5 a)|||x||||||||
|6.6.3.4.5 b)|||x||||||||
|6.6.3.4.5 c)|||x||||||||
|6.6.3.4.5 d)|||x||||||||
|6.6.3.4.5<br>Table|x||||||||||
|6.6.3.4.5<br>Table -<br>footnote [1]|x||||||||||
|<br>6.6.3.4.5<br>Table -<br>footnote [1a]|x||||||||||

<!-- end of page 126 -->

|||Clause|classification||||Replacing Cl|ause classif|ication||
|---|---|---|---|---|---|---|---|---|---|---|
||ETCS||||Replaced||||||
|Clause<br>number|on-<br>board<br>requireme<br>nt|ETCS<br>trackside<br>requirement|Definition<br>Informative|Others|<br>clause<br>number|ETCS on-<br>board<br>requirement|ETCS<br>trackside<br>requirement|Definition|Informative|Others|
|6.6.3.4.5<br>Table -<br>footnote [1b]|x||||||||||
|6.6.3.4.5<br>Table -<br>footnote [1c]|x||||||||||
|6.6.3.4.5<br>Table -<br>footnote [2]|x||||||||||
|6.6.3.4.5<br>Table -<br>footnote [3]|x||||||||||
|<br>6.6.3.4.5<br>Table -<br>footnote [3a]|x||||||||||
|6.6.3.4.5<br>Table -<br>footnote [3b]|x||||||||||
|6.6.3.4.5<br>Table -<br>footnote [3c]|x||||||||||
|6.6.3.4.5<br>Table -<br>footnote [3d]|x||||||||||
|6.6.3.4.5<br>Table -<br>footnote [3e]|x||||||||||
|<br>6.6.3.4.5<br>Table -<br>footnote [4]|x||||||||||

<!-- end of page 127 -->

||ETCS on-|Clause|classification||Replaced||Replacing Cl|ause classif|ication||
|---|---|---|---|---|---|---|---|---|---|---|
|Clause<br>number|<br>board<br>requireme<br>nt|ETCS<br>trackside<br>requirement|Definition<br>Informative|Others|<br>clause<br>number|ETCS on-<br>board<br>requirement|ETCS<br>trackside<br>requirement|Definition|Informative|Others|
|6.6.3.4.5<br>Table -<br>footnote [5]|x||||||||||
|6.6.3.4.5<br>Table -<br>footnote [6]|x||||||||||
|6.6.3.4.5<br>Table -<br>footnote [7]|x||||||||||
|6.6.3.4.5<br>Table -<br>footnote [8]|x||||||||||
|6.6.4|||x||||||||
|6.6.4.1|||x||||||||
|6.6.4.1.1|x||||||||||
|6.6.4.1.2|x||||||||||
|6.6.4.1.3|x||||||||||
|6.6.4.2|||x||||||||
|6.6.4.2.1|x||||||||||
|6.6.4.2.2|x||||||||||
|6.6.4.3|||x||||||||
|6.6.4.3.1|x||||||||||
|6.6.4.3.2|x||||||||||
|6.6.4.4|||x||||||||
|6.6.4.4.1||||x|||||||
|6.6.5|||x||||||||
|6.6.5.1|||x||||||||
|6.6.5.1.1|x||||||||||
|6.6.5.1.2|x||||||||||

<!-- end of page 128 -->

|||Clause|classification||||Replacing Cl|ause classif|ication||
|---|---|---|---|---|---|---|---|---|---|---|
||ETCS on-||||Replaced||||||
|Clause<br>number|<br>board<br>requireme<br>nt|ETCS<br>trackside<br>requirement|Definition<br>Informative|Others|<br>clause<br>number|ETCS on-<br>board<br>requirement|ETCS<br>trackside<br>requirement|Definition|Informative|Others|
|6.6.5.2|||x||||||||
|6.6.5.2.1|x||||||||||
|6.6.5.2.2|x||||||||||
|6.6.5.2.3|x||||||||||
|6.6.5.2.4|x||||||||||
|6.6.5.2.5|x||||||||||
|6.6.5.2.6|x||||||||||
|6.6.5.2.7|x||||||||||
|6.6.5.3|||x||||||||
|6.6.5.3.1|||x||||||||
|6.6.5.3.2|x||||||||||
|6.6.5.3.3|x||||||||||
|6.6.5.3.4|x||||||||||
|6.6.5.3.5|x||||||||||
|6.6.5.3.6|x||||||||||
|6.6.5.3.7|||x||||||||
|6.6.5.3.7 a)|||x||||||||
|6.6.5.3.7 b)|||x||||||||
|6.6.5.3.7 c)|||x||||||||
|6.6.5.3.7 d)|||x||||||||
|6.6.5.3.7<br>Table|x||||||||||
|6.6.5.3.7<br>Table -<br>footnote [1]|x||||||||||
|<br>6.6.5.3.7<br>Table -<br>footnote [1a]|x||||||||||

<!-- end of page 129 -->

||ETCS on-|Clause|classification||Replaced||Replacing Cl|ause classif|ication||
|---|---|---|---|---|---|---|---|---|---|---|
|Clause<br>number|<br>board<br>requireme<br>nt|ETCS<br>trackside<br>requirement|Definition<br>Informative|Others|<br>clause<br>number|ETCS on-<br>board<br>requirement|ETCS<br>trackside<br>requirement|Definition|Informative|Others|
|6.6.5.3.7<br>Table -<br>footnote [1b]|x||||||||||
|6.6.5.3.7<br>Table -<br>footnote [1c]|x||||||||||
|6.6.5.3.7<br>Table -<br>footnote [2]|x||||||||||
|6.6.5.3.7<br>Table -<br>footnote [3]|x||||||||||
|6.6.5.3.7<br>Table -<br>footnote [4]|x||||||||||
|6.6.5.3.7<br>Table -<br>footnote [5]|x||||||||||
|6.6.5.4|||x||||||||
|6.6.5.4.1|||x||||||||
|6.6.5.4.2|x||||||||||
|6.6.5.4.3|x||||||||||
|6.6.5.4.4|x||||||||||
|6.6.5.4.5|x||||||||||
|6.6.5.4.6|||x||||||||
|6.6.5.4.6 a)|||x||||||||
|6.6.5.4.6 b)|||x||||||||
|6.6.5.4.6 c)|||x||||||||
|6.6.5.4.6 d)|||x||||||||

<!-- end of page 130 -->

|||Clause|classification||||Replacing Cl|ause classif|ication||
|---|---|---|---|---|---|---|---|---|---|---|
||ETCS on-||||Replaced||||||
|Clause<br>number|<br>board<br>requireme<br>nt|ETCS<br>trackside<br>requirement|Definition<br>Informative|Others|<br>clause<br>number|ETCS on-<br>board<br>requirement|ETCS<br>trackside<br>requirement|Definition|Informative|Others|
|6.6.5.4.6<br>Table|x||||||||||
|6.6.5.4.6<br>Table -<br>footnote [1]|x||||||||||
|6.6.5.4.6<br>Table -<br>footnote [2]|x||||||||||
|6.6.5.4.6<br>Table -<br>footnote [3]|x||||||||||
|<br>6.6.5.4.6<br>Table -<br>footnote [4]|x||||||||||
|6.6.5.5|||x||||||||
|6.6.5.5.1|||x||||||||
|6.6.5.5.2|x||||||||||
|6.6.5.5.3|x||||||||||
|6.6.5.5.4|x||||||||||
|6.6.5.5.5|x||||||||||
|6.6.5.5.6|||x||||||||
|6.6.5.5.6 a)|||x||||||||
|6.6.5.5.6 b)|||x||||||||
|6.6.5.5.6 c)|||x||||||||
|6.6.5.5.6 d)|||x||||||||
|<br>6.6.5.5.6<br>Table|x||||||||||
|6.6.5.5.6<br>Table -<br>footnote [1]|x||||||||||

<!-- end of page 131 -->

|||Clause|classification||||Replacing Cl|ause classif|ication||
|---|---|---|---|---|---|---|---|---|---|---|
||ETCS on-||||Replaced||||||
|Clause<br>number|<br>board<br>requireme<br>nt|ETCS<br>trackside<br>requirement|Definition<br>Informative|Others|<br>clause<br>number|ETCS on-<br>board<br>requirement|ETCS<br>trackside<br>requirement|Definition|Informative|Others|
|6.6.5.5.6<br>Table -<br>footnote [1a]|x||||||||||
|6.6.5.5.6<br>Table -<br>footnote [1b]|x||||||||||
|6.6.5.5.6<br>Table -<br>footnote [2]|x||||||||||
|6.6.5.5.6<br>Table -<br>footnote [3]|x||||||||||
|6.6.5.6|||x||||||||
|6.6.5.6.1|||x||||||||
|6.6.5.6.2|x||||||||||
|6.6.5.6.3|||x||||||||
|6.6.5.6.3 a)|||x||||||||
|6.6.5.6.3 b)|||x||||||||
|6.6.5.6.3 c)|||x||||||||
|6.6.5.6.3 d)|||x||||||||
|6.6.5.6.3<br>Table|x||||||||||
|6.6.5.6.3<br>Table -<br>footnote [1]|x||||||||||
|6.6.5.6.3<br>Table -<br>footnote [1a]|x||||||||||
|6.6.5.6.3<br>Table -<br>footnote [2]|x||||||||||

<!-- end of page 132 -->

- {1} The replacing clause does not inherit the classification "ETCS on-board requirement" of the replaced clause because the replacement clause (being part of section 6.5) is applicable to the trackside only.

- {2} The replacing clause does not inherit the classification "ETCS trackside requirement" of the replaced clause because the replacement clause (being part of section 6.6) is applicable to the on-board only.

<!-- end of page 133 -->

## **9.4.7 Chapter 7**

|||Clause c<br>|lassification|||
|---|---|---|---|---|---|
|Clause number|ETCS on-<br>board<br>requirement|ETCS<br>trackside<br>requirement|Definition|Informative|Others|
|7.1||||x||
|7.2||||x||
|7.3||||x||
|7.3.1||||x||
|7.3.1.1|||x|||
|7.3.1.2|||x|||
|7.3.1.3||||x||
|7.3.2||||x||
|7.3.2.1|||x|||
|7.3.2.2|||x|||
|7.3.2.3|||x|||
|7.3.2.4|||x|||
|7.3.2.5|||x|||
|7.3.2.6|||x|||
|7.3.2.7|x|x||||
|7.3.2.8|||x|||
|7.3.2.9|||x|||
|7.3.2.10|x|x||||
|7.3.2.11|||x|||
|7.3.3||||x||
|7.3.3.1|||x|||
|7.3.3.2|||x|||
|7.3.3.2 1<sup>st</sup>bullet|||x|||
|7.3.3.2 2<sup>nd</sup>bullet|||x|||
|7.3.3.3|||x|||
|7.3.3.4|x|||||
|7.3.3.4.1||||x||
|7.3.3.5|||x|||
|7.3.3.6|||x|||
|7.3.3.7|||x|||
|7.3.3.8|||x|||
|7.3.3.9|||x|||
|7.3.3.10|||x|||
|7.3.3.10.1|||x|||
|7.4||||x||
|7.4.1||||x||
|7.4.1.1||||x||
|7.4.1.1 Table||||x||

<!-- end of page 134 -->

|||Clause c<br>|lassification|||
|---|---|---|---|---|---|
|Clause number|ETCS on-<br>board<br>requirement|ETCS<br>trackside<br>requirement|Definition|Informative|Others|
|7.4.1.2||||x||
|7.4.1.2 Table||||x||
|7.4.1.3|||||x|
|7.4.2||||x||
|7.4.2.0 Packet Number 0: Virtual||||||
|Balise Cover marker<br>|x|x||||
|7.4.2.1 Packet Number 2: System<br>Version o<sup>rd</sup>er|x|x||||
|7.4.2.1.1 Packet Number 3:||||||
|National Values|x|x||||
|7.4.2.2 Packet Number 5: Linking|x|x||||
|7.4.2.2.1 Packet Number 6: Virtual<br>Balise Cover o<sup>rd</sup>er|x|x||||
|7.4.2.3 Packet Number 12: Level 1||||||
|Movement Authority|x|x||||
|7.4.2.3.1 Packet Number 13: Staff<br>Responsible distance information<br>from loop|x|x||||
|7.4.2.4 Packet Number 15: Level 2||||||
|Movement Authority|x|x||||
|7.4.2.5 Packet Number 16:<br>Repositioning information|x|x||||
|7.4.2.6 Packet Number 21:||||||
|Gradient Profile|x|x||||
|7.4.2.7 Packet Number 27:||||||
|International Static Speed Profile|x|x||||
|7.4.2.7.1 Packet Number 31: RBC<br>transition order for RBC interfaced<br>to FRMCS only|x|x||||
|7.4.2.7.2 Packet Number 32:||||||
|Session Management for RBC<br>interfaced to FRMCS only|x|x||||
|7.4.2.8 Packet Number 39: Track<br>Condition Change of traction||||||
|<br>system|x|x||||
|7.4.2.8.1 Packet Number 40: Track<br>Condition Change of allowed<br>current consumption|x|x||||
|7.4.2.9 Packet Number 41: Level||||||
|Transition O<sup>rd</sup>er|x|x||||
|7.4.2.10 Packet Number 42:<br>Session management for RBC<br>interfaced to GSM-R|x|x||||
|7.4.2.11 Packet Number 44: Data<br>used by applications outside the<br>ERTMS/ETCS system|x|x||||
|7.4.2.11.1 Packet Number 45:||||||
|Radio Network transition order|x|x||||
|7.4.2.11.2 Packet Number 46:<br>Conditional Level Transition O<sup>rd</sup>er|x|x||||

<!-- end of page 135 -->

|||Clause c<br>|lassification|||
|---|---|---|---|---|---|
|Clause number|ETCS on-<br>board<br>requirement|ETCS<br>trackside<br>requirement|Definition|Informative|Others|
|7.4.2.12 Packet Number 49: List of<br>||||||
|Balises for SH area|x|x||||
|7.4.2.13 Packet Number 51: axle<br>load speed profile|x|x||||
|7.4.2.13.1 Packet Number 52:<br>||||||
|Permitted Braking Distance<br>Information|x|x||||
|7.4.2.14 Packet Number 57: MA<br>||||||
|request Parameters|x|x||||
|7.4.2.15 Packet Number 58:||||||
|Position report parameters|x|x||||
|7.4.2.16 Packet Number 63: List of||||||
|Balises in SR Authority|x|x||||
|7.4.2.16.1 Packet Number 64:<br>Inhibition of revocable TSRs from<br>balises in level 2|x|x||||
|7.4.2.17 Packet Number 65:<br>||||||
|Temporary Speed Restriction|x|x||||
|7.4.2.18 Packet Number 66:<br>Temporary Speed Restriction<br>||||||
|Revocation|x|x||||
|7.4.2.19 Packet Number 67: Track||||||
|Conditions Big Metal Masses|x|x||||
|7.4.2.20 Packet Number 68: Track<br>||||||
|Condition|x|x||||
|7..4.2.20.1 Packet Number 69:||||||
|track conditions station platforms<br>|x|x||||
|7.4.2.21 Packet Number 70: route||||||
|<br>suitability data|x|x||||
|7.4.2.22 Packet Number 71:||||||
|Adhesion factor|x|x||||
|7.4.2.23 Packet Number 72: Packet||||||
|for sending plain text messages|x|x||||
|7.4.2.24 Packet Number 76: Packet<br>||||||
|for sending fixed text messages|x|x||||
|<br>7.4.2.25 Packet Number 79:||||||
|Geographical Position Information|x|x||||
|7.4.2.26 Packet Number 80: Mode<br>||||||
|Profile|x|x||||
|7.4.2.26.1 Packet Number 88: Level||||||
|Crossing information|x|x||||
|7.4.2.26.2 Packet Number 90: track<br>ahead free up to level 2 transition<br>location|x|x||||
|74227 Packet Number 131: RBC||||||
|...<br>transition order for RBC interfaced<br>to GSM-R|x|x||||
|74228 Pkt Nb 132||||||
|... ace umer :<br>Danger for Shunting information<br>|x|x||||
|7.4.2.29 Packet Number 133: Radio||||||
|infill area information|x|x||||
|7.4.2.30 Packet Number 134:<br>EOLM Packet|x|x||||

<!-- end of page 136 -->

|||Clause c|lassification|||
|---|---|---|---|---|---|
|Clause number|ETCS on-|ETCS||||
||board<br>requirement|trackside<br>requirement|Definition|Informative|Others|
|7.4.2.31 Packet Number 135: Stop<br>||||||
|Shunting on desk opening<br>|x|x||||
|7.4.2.32 Packet Number 136: Infill||||||
|location reference|x|x||||
|7.4.2.33 Packet Number 137: Stop<br>||||||
|if in SR|x|x||||
|7.4.2.34 Packet Number 138:||||||
|Reversing area information|x|x||||
|7.4.2.35 Packet Number 139:<br>||||||
|Reversing supervision information|x|x||||
|<br>7.4.2.36 Packet Number 140: Train<br>running number from RBC<br>|x|x||||
|7.4.2.37 Packet Number 141:<br>Default Gradient for Temporary||||||
|Speed Restriction|x|x||||
|7.4.2.37.1 Packet Number 143:<br>Session Management with||||||
|neighbouring Radio Infill Unit|x|x||||
|7.4.2.37.2 Packet Number 145:||||||
|<br>Inhibition of balise group message||||||
|<br>consistency reaction|x|x||||
|7.4.2.37.3 Packet Number 180:<br>||||||
|LSSMA display toggle o<sup>rd</sup>er|x|x||||
|7.4.2.37.4 Packet Number 181:||||||
|Generic LS function marker|x|x||||
|7.4.2.38 Packet Number 254:||||||
|Default balise information|x|x||||
|7.4.2.39 Packet Number 255: End||||||
|of Information|x|x||||
|7.4.3||||x||
|7431 Packet Number 0: Position||||||
|...<br>Report|x|x||||
|7.4.3.2 Packet Number 1: Position||||||
|Report based on two balise groups|x|x||||
|7.4.3.3 Packet Number 3: Onboard||||||
|telephone numbers|x|x||||
|7.4.3.4 Packet Number 4: Error||||||
|reporting|x|x||||
|7.4.3.4.1 Packet Number 5: Train||||||
|running number|x|x||||
|7.4.3.4.2 Packet Number 9: Level 2||||||
|<br>transition information|x|x||||
|7.4.3.4.3 Packet Number 10: Safe<br>consist length information for<br>Supervised Manoeuvre|x|x||||
|<br>7.4.3.5 Packet Number 11:||||||
|Validated train data|x|x||||
|74351 Packet Number 12:||||||
|....<br>Default train data for Supervised||||||
|<br>Manoeuvre|x|x||||
|7.4.3.6 Packet Number 44: Data<br>||||||
|used by applications outside the<br>ERTMS/ETCS system|x|x||||

<!-- end of page 137 -->

|||Clause c<br>|lassification|||
|---|---|---|---|---|---|
|Clause number|ETCS on-<br>board<br>requirement|ETCS<br>trackside<br>requirement|Definition|Informative|Others|
|7.4.4|||||x|
|7.5||||x||
|7.5.0.1 A_NVMAXREDADH1|x|x||||
|7.5.0.2 A_NVMAXREDAH2|x|x||||
|7.5.0.3 A_NVMAXREDAH3|x|x||||
|7.5.0.4 A_NVP12|x|x||||
|7.5.0.5 A_NVP23|x|x||||
|7.5.1.1 D_ADHESION|x|x||||
|7.5.1.2 D_AXLELOAD|x|x||||
|7.5.1.2.1 D_CURRENT|x|x||||
|7.5.1.3 D_CYCLOC|x|x||||
|7.5.1.4 D_DP|x|x||||
|7.5.1.5 D_EMERGENCYSTOP|x|x||||
|7.5.1.6 D_ENDTIMERSTARTLOC|x|x||||
|7.5.1.7 D_GRADIENT|x|x||||
|7.5.1.8 D_INFILL|x|x||||
|7.5.1.9 D_LEVELTR|x|x||||
|7.5.1.10 D_LINK|x|x||||
|7.5.1.11 D_LOC|x|x||||
|7.5.1.12 D_LOOP|x|x||||
|7.5.1.13 D_LRBG|x|x||||
|7.5.1.13.1 D_LX|x|x||||
|7.5.1.14 D_MAMODE|x|x||||
|7.5.1.15 D_NVOVTRP|x|x||||
|7.5.1.16 D_NVPOTRP|x|x||||
|7.5.1.17 D_NVROLL|x|x||||
|7.5.1.18 D_NVSTFF|x|x||||
|7.5.1.19 D_OL|x|x||||
|7.5.1.19.1 D_PBD|x|x||||
|7.5.1.19.2 D_PBDSR|x|x||||
|7.5.1.20 D_POSOFF|x|x||||
|7.5.1.21 D_RBCTR|x|x||||
|7.5.1.22 D_REF|x|x||||
|7.5.1.23 D_REVERSE|x|x||||
|7.5.1.24||||||
|D_SECTIONTIMERSTOPLOC|x|x||||
|7.5.1.25 D_SR|x|x||||
|7.5.1.26 D_STARTOL|x|x||||
|7.5.1.27 D_STARTREVERSE|x|x||||
|7.5.1.28 D_STATIC|x|x||||

<!-- end of page 138 -->

|||Clause c<br>|lassification|||
|---|---|---|---|---|---|
|Clause number|ETCS on-<br>board<br>requirement|ETCS<br>trackside<br>requirement|Definition|Informative|Others|
|7.5.1.29 D_SUITABILITY|x|x||||
|7.5.1.30 D_TAFDISPLAY|x|x||||
|7.5.1.31 D_TEXTDISPLAY|x|x||||
|7.5.1.32 D_TRACKINIT|x|x||||
|7.5.1.33 D_TRACKCOND|x|x||||
|7.5.1.34 D_TRACTION|x|x||||
|7.5.1.35 D_TSR|x|x||||
|7.5.1.36 D_VALIDNV|x|x||||
|7.5.1.37 G_A|x|x||||
|7.5.1.37.1 G_PBDSR|x|x||||
|7.5.1.38 G_TSR|x|x||||
|7.5.1.39 L_ACKLEVELTR|x|x||||
|7.5.1.40 L_ACKMAMODE|x|x||||
|7.5.1.41 L_ADHESION|x|x||||
|7.5.1.42 L_AXLELOAD|x|x||||
|7.5.1.42.1||||||
|L_CONSISTFRONTENGINEMAX|x|x||||
|7.5.1.42.2<br>L_CONSISTFRONTENGINEMIN|x|x||||
|7.5.1.42.3||||||
|L_CONSISTFRONTENGINENOM|x|x||||
|7.5.1.42.4||||||
|L_CONSISTREARENGINEMAX|x|x||||
|7.5.1.42.5||||||
|L_CONSISTREARENGINEMIN|x|x||||
|7.5.1.42.6<br>L_CONSISTREARENGINENOM|x|x||||
|7.5.1.43 L_DOUBTOVER|x|x||||
|7.5.1.44 L_DOUBTUNDER|x|x||||
|7.5.1.45 L_ENDSECTION|x|x||||
|7.5.1.46 L_LOOP|x|x||||
|7.5.1.46.1 L_LX|x|x||||
|7.5.1.47 L_MAMODE|x|x||||
|7.5.1.48 L_MESSAGE|x|x||||
|7.5.1.48.1 L_NVKRINT|x|x||||
|7.5.1.49 L_PACKET|x|x||||
|7.5.1.49.1 L_PBDSR|x|x||||
|7.5.1.50 L_REVERSEAREA|x|x||||
|7.5.1.51 L_SECTION|x|x||||
|7.5.1.51.1 L_STOPLX|x|x||||
|7.5.1.52 L_TAFDISPLAY|x|x||||
|7.5.1.53 L_TEXT|x|x||||
|7.5.1.54 L_TEXTDISPLAY|x|x||||

<!-- end of page 139 -->

|||Clause c<br>|lassification|||
|---|---|---|---|---|---|
|Clause number|ETCS on-<br>board<br>requirement|ETCS<br>trackside<br>requirement|Definition|Informative|Others|
|7.5.1.55 L_TRACKCOND|x|x||||
|7.5.1.56 L_TRAIN|x|x||||
|7.5.1.57 L_TRAININT|x|x||||
|7.5.1.58 L_TSR|x|x||||
|7.5.1.59 M_ACK|x|x||||
|7.5.1.60 M_ADHESION|x|x||||
|7.5.1.61 M_AIRTIGHT|x|x||||
|7.5.1.62 M_AXLELOADCAT|x|x||||
|7.5.1.62.1 M_CURRENT|x|x||||
|7.5.1.63 M_DUP|x|x||||
|7.5.1.64 M_ERROR|x|x||||
|7.5.1.65 M_LEVEL|x|x||||
|7.5.1.66 M_LEVELTEXTDISPLAY|x|x||||
|7.5.1.67 M_LEVELTR|x|x||||
|7.5.1.67.1 M_LINEGAUGE|x|x||||
|7.5.1.67.2 M_LINEAXLELOADCAT|x|x||||
|7.5.1.68 M_LOADINGGAUGE|x|x||||
|7.5.1.69 M_LOC|x|x||||
|7.5.1.70 M_MAMODE|x|x||||
|7.5.1.71 M_MCOUNT|x|x||||
|7.5.1.72 M_MODE|x|x||||
|7.5.1.73 M_MODETEXTDISPLAY|x|x||||
|7.5.1.73.1 M_NVAVADH|x|x||||
|7.5.1.74 M_NVCONTACT|x|x||||
|7.5.1.75 M_NVDERUN|x|x||||
|7.5.1.75.1 M_NVEBCL|x|x||||
|7.5.1.75.2 M_NVKRINT|x|x||||
|7.5.1.75.3 M_NVKTINT|x|x||||
|7.5.1.75.4 M_NVKVINT|x|x||||
|7.5.1.75.5 M_PLATFORM|x|x||||
|7.5.1.76 M_POSITION|x|x||||
|7.5.1.77 M_TRACKCOND|x|x||||
|7.5.1.78 M_VOLTAGE|x|x||||
|7.5.1.79 M_VERSION|x|x||||
|7.5.1.79.1 N_AXLE|x|x||||
|7.5.1.80 N_ITER|x|x||||
|7.5.1.81 N_PIG|x|x||||
|7.5.1.82 N_TOTAL|x|x||||
|7.5.1.82.1 NC_CDDIFF|x|x||||
|7.5.1.82.2 NC_CDTRAIN|x|x||||

<!-- end of page 140 -->

|||Clause c<br>|lassification|||
|---|---|---|---|---|---|
|Clause number|ETCS on-<br>board<br>requirement|ETCS<br>trackside<br>requirement|Definition|Informative|Others|
|7.5.1.83 NC_DIFF|x|x||||
|7.5.1.84 NC_TRAIN|x|x||||
|7.5.1.85 NID_BG|x|x||||
|7.5.1.86 NID_C|x|x||||
|7.5.1.86.1 NID_CTRACTION|x|x||||
|7.5.1.87 NID_EM|x|x||||
|7.5.1.88 NID_ENGINE|x|x||||
|7.5.1.89 NID_LOOP|x|x||||
|7.5.1.90 NID_LRBG|x|x||||
|7.5.1.90.1 NID_LTRBG|x|x||||
|7.5.1.90.2 NID_LX|x|x||||
|7.5.1.91 NID_MESSAGE|x|x||||
|7.5.1.91.1 NID_MN|x|x||||
|7.5.1.92 NID_OPERATIONAL|x|x||||
|7.5.1.93 NID_PACKET|x|x||||
|7.5.1.94 NID_PRVLRBG|x|x||||
|7.5.1.95 NID_RADIO|x|x||||
|7.5.1.96 NID_RBC|x|x||||
|7.5.1.97 NID_RIU|x|x||||
|7.5.1.98 NID_NTC|x|x||||
|7.5.1.98.1 NID_TEXTMESSAGE|x|x||||
|7.5.1.99 NID_TSR|x|x||||
|7.5.1.99.1 NID_VBCMK|x|x||||
|7.5.1.100 NID_XUSER|x|x||||
|7.5.1.101 Q_ASPECT|x|x||||
|7.5.1.101.1<br>Q_CONFTEXTDISPLAY|x|x||||
|7.5.1.102 Q_DANGERPOINT|x|x||||
|7.5.1.102.1 Q_DIFF|x|x||||
|7.5.1.102.2 Q_DESK|x|x||||
|7.5.1.103 Q_DIR|x|x||||
|7.5.1.104 Q_DIRLRBG|x|x||||
|7.5.1.105 Q_DIRTRAIN|x|x||||
|7.5.1.106 Q_DLRBG|x|x||||
|7.5.1.107 Q_EMERGENCYSTOP|x|x||||
|7.5.1.108 Q_ENDTIMER|x|x||||
|7.5.1.109 Q_FRONT|x|x||||
|7.5.1.110 Q_GDIR|x|x||||
|7.5.1.111 Q_INFILL|x|x||||
|7.5.1.112 Q_INTEGRITY|x|x||||

<!-- end of page 141 -->

|||Clause c<br>|lassification|||
|---|---|---|---|---|---|
|Clause number|ETCS on-<br>board<br>requirement|ETCS<br>trackside<br>requirement|Definition|Informative|Others|
|7.5.1.112.1||||||
|Q_SAFECONSISTLENGTH|x|x||||
|7.5.1.113 Q_LGTLOC|x|x||||
|7.5.1.114 Q_LINK|x|x||||
|7.5.1.115 Q_LOCACC|x|x||||
|7.5.1.116 Q_LINKORIENTATION|x|x||||
|7.5.1.117 Q_LINKREACTION|x|x||||
|7.5.1.118 Q_LOOPDIR|x|x||||
|7.5.1.118.0 Q_LSSMA|x|x||||
|7.5.1.118.1 Q_LXSTATUS|x|x||||
|7.5.1.118.2 Q_MAMODE|x|x||||
|7.5.1.118.3 Q_MARQSTREASON|x|x||||
|7.5.1.119 Q_MEDIA|x|x||||
|7.5.1.120 Q_MPOSITION|x|x||||
|7.5.1.120.1 Q_NETWORKTYPE|x|x||||
|7.5.1.121 Q_NEWCOUNTRY|x|x||||
|7.5.1.122 Q_NVDRIVER_ADHES|x|x||||
|7.5.1.123 Q_NVEMRRLS|x|x||||
|7.5.1.123.1 Q_NVGUIPERM|x|x||||
|7.5.1.123.2 Q_NVINHSMICPERM|x|x||||
|7.5.1.123.3 Q_NVKINT|x|x||||
|7.5.1.123.4 Q_NVKVINTSET|x|x||||
|7.5.1.123.5 Q_NVLOCACC|x|x||||
|7.5.1.123.6 Q_NVSBFBPERM|x|x||||
|7.5.1.124 Q_NVSBTSMPERM|x|x||||
|7.5.1.125 Q_ORIENTATION|x|x||||
|7.5.1.126 Q_OVERLAP|x|x||||
|7.5.1.126.1 Q_PBDSR|x|x||||
|7.5.1.126.2 Q_PLATFORM|x|x||||
|7.5.1.127 Q_RBC|x|x||||
|7.5.1.128 Q_RIU|x|x||||
|7.5.1.129 Q_SCALE|x|x||||
|7.5.1.130 Q_SECTIONTIMER|x|x||||
|7.5.1.131 Q_SLEEPSESSION|x|x||||
|7.5.1.132 Q_SRSTOP|x|x||||
|7.5.1.133 Q_SSCODE|x|x||||
|7.5.1.134 Q_STATUSLRBG|x|x||||
|7.5.1.134.1 Q_STOPLX|x|x||||
|7.5.1.135 Q_SUITABILITY|x|x||||
|7.5.1.136 Q_TEXT|x|x||||

<!-- end of page 142 -->

|||Clause c<br>|lassification|||
|---|---|---|---|---|---|
|Clause number|ETCS on-<br>board<br>requirement|ETCS<br>trackside<br>requirement|Definition|Informative|Others|
|7.5.1.137 Q_TEXTCLASS|x|x||||
|7.5.1.138 Q_TEXTCONFIRM|x|x||||
|7.5.1.139 Q_TEXTDISPLAY|x|x||||
|7.5.1.140 Q_TEXTREPORT|x|x||||
|7.5.1.141 Q_TRACKINIT|x|x||||
|7.5.1.142 Q_UPDOWN|x|x||||
|7.5.1.142.1 Q_VBCO|x|x||||
|7.5.1.143 T_CYCLOC|x|x||||
|7.5.1.144 T_CYCRQST|x|x||||
|7.5.1.144.1 T_LSSMA|x|x||||
|7.5.1.145 T_ENDTIMER|x|x||||
|7.5.1.146 T_EMA|x|x||||
|7.5.1.147 T_MAR|x|x||||
|7.5.1.148 T_NVCONTACT|x|x||||
|7.5.1.149 T_NVOVTRP|x|x||||
|7.5.1.150 T_OL|x|x||||
|7.5.1.151 T_SECTIONTIMER|x|x||||
|7.5.1.152 T_TEXTDISPLAY|x|x||||
|7.5.1.153 T_TIMEOUTRQST|x|x||||
|7.5.1.154 T_TRAIN|x|x||||
|7.5.1.154.1 T_VBC|x|x||||
|7.5.1.155 V_AXLELOAD|x|x||||
|7.5.1.156 V_DIFF|x|x||||
|7.5.1.157 V_EMA|x|x||||
|7.5.1.157.1 V_LX|x|x||||
|7.5.1.158 V_MAIN|x|x||||
|7.5.1.159 V_MAMODE|x|x||||
|7.5.1.160 V_MAXTRAIN|x|x||||
|7.5.1.161 V_NVALLOWOVTRP|x|x||||
|7.5.1.161.1 V_NKVINT|x|x||||
|7.5.1.161.2 V_NVLIMSUPERV|x|x||||
|7.5.1.162 V_NVONSIGHT|x|x||||
|7.5.1.163 V_NVSUPOVTRP|x|x||||
|7.5.1.164 V_NVREL|x|x||||
|7.5.1.165 V_NVSHUNT|x|x||||
|7.5.1.166 V_NVSTFF|x|x||||
|7.5.1.167 V_NVUNFIT|x|x||||
|7.5.1.168 V_RELEASEDP|x|x||||
|7.5.1.169 V_RELEASEOL|x|x||||
|7.5.1.170 V_REVERSE|x|x||||

<!-- end of page 143 -->

|||Clause c|lassification|||
|---|---|---|---|---|---|
|Clause number|ETCS on-<br>board<br>requirement|ETCS<br>trackside<br>requirement|Definition|Informative|Others|
|7.5.1.170.1 V_SM|x|x||||
|7.5.1.171 V_STATIC|x|x||||
|7.5.1.172 V_TRAIN|x|x||||
|7.5.1.173 V_TSR|x|x||||
|7.5.1.174 X_TEXT|x|x||||

## **9.4.8 Chapter 8**

|||Clause c<br>|lassification|||
|---|---|---|---|---|---|
||ETCS on-|ETCS||||
|Clause number|<br>board<br>requirement|<br>trackside<br>requirement|Definition|Informative|Others|
|8.3||||x||
|8.3.1||||x||
|8.3.1.1||||x||
|8.3.1.2||||x||
|8.3.2||||x||
|8.3.2.1|||x|||
|8.3.2.2|||x|||
|8.3.2.3|||x|||
|8.3.2.3 Figure 1||||x||
|8.3.2.4|||x|||
|8.3.2.5|||x|||
|8.4||||x||
|8.4.1||||x||
|8.4.1.1|||x|||
|8.4.1.2|x|x||||
|8.4.1.3|x|x||||
|8.4.1.3.1|x|x||||
|8.4.1.3.2||||x||
|8.4.1.4||x||||
|8.4.1.4.1||x||||
|8.4.1.4.2||x||||
|8.4.1.4.3||x||||
|8.4.1.4.4||x||||
|8.4.1.4.5||x||||
|8.4.1.4.6||x||||
|8.4.1.4.7||x||||
|8.4.1.4.8||x||||
|8.4.1.4.9||x||||
|8.4.1.5|x|||||
|8.4.1.5.1|x|||||

<!-- end of page 144 -->

||ETCS on-|Clause c<br>ETCS|lassification|||
|---|---|---|---|---|---|
|Clause number|<br>board<br>requirement|<br>trackside<br>requirement|Definition|Informative|Others|
|8.4.1.6||||x||
|8.4.2||||x||
|8.4.2.1|||x|||
|8.4.2.1 Table|||x|||
|8.4.2.2||x||||
|8.4.2.3||x||||
|8.4.2.4||||x||
|8.4.3||||x||
|8.4.3.1|||x|||
|8.4.3.1 Table|||x|||
|8.4.3.2|||||x|
|8.4.4||||x||
|8.4.4.1||||x||
|8.4.4.1.1|x|||||
|8.4.4.1.1.1||||x||
|8.4.4.2|x|x||||
|8.4.4.2.1|x|x||||
|8.4.4.3|x|x||||
|8.4.4.4|x|x||||
|8.4.4.4.1||||x||
|8.4.4.4.1 Table|x|x||||
|8.4.4.4.1.1||||x||
|8.4.4.4.1.1 Table|x|x||||
|8.4.4.4.2|x|x||||
|8.4.4.4.2 a)|x|x||||
|8.4.4.4.2 b)|x|x||||
|8.4.4.4.2 c)|x|x||||
|8.4.4.4.3|x|x||||
|8.4.4.4.3 a)|x|x||||
|8.4.4.4.3 b)|x|x||||
|8.4.4.4.3 c)|x|x||||
|8.4.4.4.3 d)|x|x||||
|8.4.4.4.3 e)|x|x||||
|8.4.4.4.4|x|x||||
|8.4.4.4.4 a)|x|x||||
|8.4.4.4.5|x|x||||
|8.4.4.4.5 a)|x|x||||
|8.4.4.5|x|x||||
|8.4.4.6||||x||
|8.4.4.6.1|||x|||
|8.4.4.6.1 Table|||x|||
|8.4.4.6.2||||x||

<!-- end of page 145 -->

||ETCS on-|Clause c<br>ETCS|lassification|||
|---|---|---|---|---|---|
|Clause number|<br>board<br>requirement|<br>trackside<br>requirement|Definition|Informative|Others|
|8.4.4.6.3||x||||
|8.4.4.7||||x||
|8.4.4.7.1|||x|||
|8.4.4.7.1 Table|||x|||
|8.4.4.7.2|||x|||
|8.4.4.7.2 a)|||x|||
|8.4.4.7.2 b)|||x|||
|8.4.4.7.2 c)|||x|||
|8.4.4.7.2 d)|||x|||
|8.4.4.7.2 e)|||||x|
|8.4.4.7.2 f)|||x|||
|8.4.4.7.3||||x||
|8.5||||x||
|8.5.1||||x||
|8.5.1.1||||x||
|8.5.1.2|||||x|
|8.5.2||||x||
|8.5.2 Table|x|x||||
|8.5.3||||x||
|8.5.3 Table|x|x||||
|8.6||||x||
|8.6.1 Message 129: Validated Train<br>Data|x|x||||
|8.6.2 Message 130: Request for<br>Shunting|x|x||||
|8.6.2.1 Message 131: Request for||||||
|Supervised Manoeuvre|x|x||||
|8.6.3 Message 132: MA request|x|x||||
|<br>8.6.3.1 Message 133: Safe consist<br>length information for SM|x|x||||
|8.6.4 Message 136: Train Position<br>Report|x|x||||
|8.6.5 Message 137: Request to||||||
|<br>Shorten MA is granted|x|x||||
|8.6.6 Message 138: Request to||||||
|Shorten MA is rejected|x|x||||
|<br>8.6.7 Message 146:||||||
|Acknowledgement|x|x||||
|8.6.8 Message 147:<br>Acknowledgement of Emergency<br>Stop|x|x||||
|<br>8.6.9 Message 149: Track Ahead||||||
|<br>Free Granted|x|x||||
|8.6.10 Message 150: End of||||||
|<br>Mission|x|x||||
|8.6.11 Message 153: Radio infill<br>request|x|x||||

<!-- end of page 146 -->

||ETCS|Clause c<br>ETCS|lassification|||
|---|---|---|---|---|---|
|Clause number|on-<br>board<br>requirement|<br>trackside<br>requirement|Definition|Informative|Others|
|8.6.12 Message 154: No||||||
|compatible version supported|x|x||||
|8.6.13 Message 155: Initiation of a<br>||||||
|communication session<br>|x|x||||
|8.6.14 Message 156: Termination<br>||||||
|of a communication session|x|x||||
|8.6.15 Message 157: SoM Position<br>||||||
|Report|x|x||||
|8.6.16 Message 158: Text||||||
|Message Acknowledged by Driver|x|x||||
|<br>8.6.17 Message 159: Session||||||
|established|x|x||||
|8.7||||x||
|8.7.1 Message 2: SR Authorisation|x|x||||
|8.7.2 Message 3: Movement||||||
|<br>Authority|x|x||||
|8.7.2.1 Message 4: SM||||||
|Authorisation|x|x||||
|8.7.2.2 Message 5: SM Refused|x|x||||
|8.7.3 Message 6: Recognition of<br>exit from TRIP mode|x|x||||
|8.7.3.1 Message 7:<br>||||||
|Acknowledgement of safe consist<br>||||||
|length info for SM|x|x||||
|8.7.4 Message 8:||||||
|Acknowledgement of Train Data|x|x||||
|8.7.5 Message 9: Request to||||||
|<br>Shorten MA|x|x||||
|8.7.6 Message 15: Conditional||||||
|Emergency Stop|x|x||||
|<br>8.7.7 Message 16: Unconditional||||||
|<br>Emergency Stop|x|x||||
|8.7.8 Message 18: Revocation of<br>||||||
|Emergency Stop|x|x||||
|<br>8.7.9 Message 24: General||||||
|<br>message|x|x||||
|8.7.10 Message 27: SH Refused|x|x||||
|8.7.11 Message 28: SH Authorised|x|x||||
|8.7.12 Message 32: RBC/RIU<br>System Version<br>|x|x||||
|8.7.13 Message 33: MA Shifted||||||
|<br>Location Reference|x|x||||
|8.7.14 Message 34: Track Ahead||||||
|<br>Free Request|x|x||||
|8.7.15 Message 37: Infill MA|x|x||||
|<br>8.7.16 Message 38:||||||
|<br>Acknowledgement of session||||||
|<br>establishment|x|x||||
|8717 Message 39:||||||
|..<br>Acknowledgement of termination of||||||
|<br>a communication session|x|x||||
|8.7.18Message40: Train Rejected|x|x||||

<!-- end of page 147 -->

|||Clause c|lassification|||
|---|---|---|---|---|---|
|Clause number|ETCS on-<br>board<br>requirement|ETCS<br>trackside<br>requirement|Definition|Informative|Others|
|8.7.19 Message 41: Train Accepted|x|x||||
|8.7.20|||||x|
|8.7.21 Message 43: SoM position<br>report confirmed by RBC|x|x||||
|8.7.22 Message 45: Assignment of<br>coordinate system|x|x||||

<!-- end of page 148 -->
