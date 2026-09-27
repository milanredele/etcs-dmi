## **ERTMS/ETCS**

# **FFFIS for Eurobalise**

REF : SUBSET-036 ISSUE :

4.0.0 DATE : 05/07/2023

|**Company**|**Technical Approval**|**Management approval**|
|---|---|---|
|ALSTOM|||
|AZD|||
|CAF|||
|HITACHI RAIL STS|||
|MERMEC|||
|SIEMENS|||
|THALES|||

<!-- end of page 1 -->

# **Modification History**

|**Issue**<br>**Date**|**Section**<br>**Number**|**Modification/Description**|**Author**|
|---|---|---|---|
|2.5.1<br>2011-01-19|All|The following technical modifications relative to version<br>2.4.1 apply to this version:<br>• Down-link functionality is removed.<br>• EN 300 330 is replaced by EN 302 608 (a formal<br>change only without technical impact).<br>• Removal of requirement on short default tele-<br>grams in section 5.2.2.8.6.<br>• Change of “should” to “shall” in section 6.3.<br>Other modifications herein are either clarifications, and/or<br>made for improving the general quality of the specification.<br>This update resolves CR 867.|Per Lundberg|
|2.5.2<br>2011-04-14|1.3|Removal of section 1.3 (Technical Modifications in This<br>Version) and introduction of this Modification History.|Per Lundberg|
|2.5.3<br>2011-04-14||Modifications according to imperfections 036:537, 036:538,<br>and 036:539.|Per Lundberg|
|2.5.4<br>2011-09-19||Modifications according to imperfections 036:540 and<br>036:541.|Per Lundberg|
|2.5.5<br>2011-09-30||Modifications according to imperfections 036:542 and<br>036:543.|Per Lundberg|
|2.5.6<br>2011-10-21|6.2.2.1|Modification according to imperfection 036:544 resolving<br>CR 482.|Per Lundberg|
|2.5.7<br>2011-11-25|3.2,<br>4.2.8.2,<br>5.2.2.3|Modifications according to updated imperfection 036:507<br>resolving CR 867, and movement of footnote in section<br>4.2.8.2.|Per Lundberg|
|2.5.8<br>2012-01-12|5.6|Modifications according to imperfection 036:545 resolving<br>the SUBSET-036 part of CR 890 (Balise installation in<br>narrow curves).|Per Lundberg|
|2.5.9<br>2012-02-01||Modifications according to imperfections 036:546 through<br>036:555 after SG/ERA/EUG review and WGI meeting of<br>January 31 2012.|Per Lundberg|
|2.5.10<br>2012-02-08||Removal of “Class 1” on the front page.|Per Lundberg|
|3.0.0<br>2012-02-24||Baseline 3 release version (only change of Issue number).|Per Lundberg|
|3.0.1<br>2015-11-10|5.6.2.3,<br>5.7.10.4.1,<br>5.7.10.7.2,<br>6.7.4|Update resolving CR 1180, CR 1188, and CR 1275.|Per Lundberg|
|3.0.2<br>2015-11-16|5.7.10.7.2,<br>6.7.4|Update after UNISIG internal review.|Per Lundberg|
|3.0.3<br>2015-12-11|4.2.9|Update as per review comment agreed in EECT meeting 16<br>(08/12/2015) (deletion of note [8] in section 4.2.9 as per<br>CR1265 agreed solution)|Philippe<br>Prieels|

<!-- end of page 2 -->

|3.1.0<br>2015-12-17|-|Baseline 3 2<sup>nd</sup>release version|Philippe<br>Prieels|
|---|---|---|---|
|3.1.1<br>2022-09-02|5.2.2.4,<br>5.6.2.3,<br>5.7.10.1,<br>5.9.2,<br>6.2.1.6,<br>6.6.4,<br>Annex D,<br>Annex G|Update resolving CR1307, CR1357, CR1372 and CR1373.|Nefi Carvalho|
|3.1.2<br>2022-09-02|2, 4.6.2,<br>5.7.10.1,<br>6.5.2|Update resolving CR1307|Nefi Carvalho|
|3.9.1<br>2022-11-25|-|Formal update for the 2<sup>nd</sup>consolidation review for Base-<br>line 4 1<sup>st</sup>release version|Jakub Marek|
|3.9.2<br>2023-02-17|4.1.1|Update resolving CR1342|Nefi Carvalho|
|3.9.3<br>2023-05-30|2, 4.1.1,<br>4.6.2,<br>5.2.2.4,<br>5.6.2.3,<br>5.7.10.1,<br>5.9.2,<br>6.2.1.6,<br>6.5.2,<br>6.6.4,<br>Annex D,<br>Annex G|Update reflecting the results of the 3<sup>rd</sup>consolidation review<br>for Baseline 4 1<sup>st</sup>release version, including the CR1372<br>update|Jakub Marek|
|3.9.4<br>2023-06-23|1, 2, 3.1,<br>3.2, 4.1.1,<br>4.2.5.1,<br>4.4.6.4,<br>4.4.6.7,<br>5.5.5.2,<br>6.4.5.2,<br>B1.2, F1,<br>F3, F4,|Update reflecting the results of the 4<sup>th</sup>consolidation review<br>for Baseline 4 1<sup>st</sup>release version, including the CR1342<br>update|Jakub Marek<br>Nefi Carvalho|
|4.0.0<br>2023-07-05|-|Baseline 4 1<sup>st</sup>release version|Nefi Carvalho|

<!-- end of page 3 -->

## **Foreword**

The main body of SUBSET-036, and the relevant Annexes designated as “normative”, constitute the mandatory requirements for achieving air-gap interoperability between any possible combination of wayside and train-borne equipment.  Annexes designated as “informative”, either provide background information for the mandatory requirements, or outline non-mandatory requirements and optional functionality.

SUBSET-085 specifies test methods and tools for verification of compliance with the mandatory requirements of SUBSET-036 (this document).

<!-- end of page 4 -->

## **Contents**

|**1**<br>**IN**|**TRODUCTION ________________________________________________________ 11**|
|---|---|
|**2**<br>**N **|**ORMATIVEREFERENCES _______________________________________________ 12**|
|**3**<br>**T  **|**ERMINOLOGY ANDDEFINITIONS _________________________________________ 13**|
|**3.1**|**Acronyms and Abbreviations _________________________________________________ 13**|
|**3.2**|**Definitions ________________________________________________________________ 15**|
|**3.3**|**Influence of Tolerances ______________________________________________________ 19**|
|**4**<br>**SP **|**OTTRANSMISSIONSYSTEM _____________________________________________ 20**|
|**4.1**|**Architectural Layouts _______________________________________________________ 20**|
|4.1.1|Introduction _____________________________________________________________________ 20|
|4.1.2|Units and Functions _______________________________________________________________ 20|
|4.1.3|Interfaces _______________________________________________________________________ 21|
|4.1.4|Basic Functions __________________________________________________________________ 24|
|4.1.5|Management of Faults and Failures ___________________________________________________ 25|
|**4.2**|**Functional Requirements ____________________________________________________ 26**|
|4.2.1|Balise Tele-powering ______________________________________________________________ 26|
|4.2.2|Up-link Data Transmission _________________________________________________________ 26|
|4.2.3|Intentionally Deleted ______________________________________________________________ 27|
|4.2.4|Location Reference _______________________________________________________________ 27|
|4.2.5|Cross-talk Protection ______________________________________________________________ 28|
|4.2.6|Compatibility with existing systems __________________________________________________ 31|
|4.2.7|Interoperability with existing KER Systems ____________________________________________ 31|
|4.2.8|Quality of the Data Transmission Channel _____________________________________________ 32|
|4.2.9|Timing and Distance Requirements ___________________________________________________ 33|
|4.2.1|0<br>Location Reference Accuracy _____________________________________________________ 35|
|**4.3**|**Coding Requirements _______________________________________________________ 36**|
|4.3.1|Introduction _____________________________________________________________________ 36|
|4.3.2|Encoding Requirements ____________________________________________________________ 37|
|4.3.3|Telegram Switching _______________________________________________________________ 40|
|4.3.4|Decoding Requirements ___________________________________________________________ 41|
|**4.4**|**RAMS Requirements _______________________________________________________ 42**|
|4.4.1|General ________________________________________________________________________ 42|
|4.4.2|Top level functionality_____________________________________________________________ 42|
|4.4.3|Reliability ______________________________________________________________________ 42|
|4.4.4|Availability _____________________________________________________________________ 43|
|4.4.5|Intentionally Deleted ______________________________________________________________ 43|
|4.4.6|Safety __________________________________________________________________________ 43|

<!-- end of page 5 -->

|**4.5**|**Reference Axes and Origins of Co-ordinates ____________________________________ 50**|
|---|---|
|**4.6**|**Electrical Requirements _____________________________________________________ 51**|
|4.6.1|On-board Equipment ______________________________________________________________ 51|
|4.6.2|Wayside Equipment _______________________________________________________________ 51|
|**5**<br>**U**|**P-LINKBALISE _______________________________________________________ 52**|
|**5.1**|**Architectural Layouts _______________________________________________________ 52**|
|**5.2**|**Balise air-gap Interface ______________________________________________________ 52**|
|5.2.1|Balise Tele-powering ______________________________________________________________ 52|
|5.2.2|Up-link Data Transmission _________________________________________________________ 53|
|**5.3**|**Balise Controlling Interfaces _________________________________________________ 68**|
|5.3.1|Introduction _____________________________________________________________________ 68|
|5.3.2|Up-link Data Input (Interface ‘C1’) ___________________________________________________ 69|
|5.3.3|Auxiliary Energy Input (Interface ‘C6’) _______________________________________________ 73|
|5.3.4|Common Mode Signal Levels _______________________________________________________ 74|
|**5.4**|**Programming Principles _____________________________________________________ 74**|
|**5.5**|**RAMS Requirements _______________________________________________________ 75**|
|5.5.1|Balise functionality _______________________________________________________________ 75|
|5.5.2|Reliability ______________________________________________________________________ 77|
|5.5.3|Availability _____________________________________________________________________ 77|
|5.5.4|Intentionally Deleted ______________________________________________________________ 77|
|5.5.5|Safety __________________________________________________________________________ 78|
|**5.6**|**Installation Requirements for Balises __________________________________________ 83**|
|5.6.1|Reference Axes __________________________________________________________________ 83|
|5.6.2|General Installation Requirements for Balises __________________________________________ 83|
|5.6.3|Distance between Balises __________________________________________________________ 87|
|5.6.4|Number of Balises in a Balise Group _________________________________________________ 87|
|5.6.5|Balise Installation in Narrow Curves __________________________________________________ 88|
|**5.7**|**Specific Environmental Conditions for Balises __________________________________ 92**|
|5.7.1|Operational Temperature ___________________________________________________________ 92|
|5.7.2|Storage _________________________________________________________________________ 92|
|5.7.3|Sealing, Dust and Moisture _________________________________________________________ 92|
|5.7.4|Mechanical Stress ________________________________________________________________ 92|
|5.7.5|Meteorological Conditions _________________________________________________________ 92|
|5.7.6|Lightning _______________________________________________________________________ 92|
|5.7.7|Chemical Conditions ______________________________________________________________ 92|
|5.7.8|Biological Conditions _____________________________________________________________ 93|
|5.7.9|Debris _________________________________________________________________________ 93|

<!-- end of page 6 -->

|5.7.1|0<br>Metallic Masses and Cables in proximity ____________________________________________ 95|
|---|---|
|**5.8**|**Specific EMC Requirements ________________________________________________ 108**|
|5.8.1|In-band Emission ________________________________________________________________ 108|
|5.8.2|Out-band Emission ______________________________________________________________ 108|
|5.8.3|Susceptibility Requirements _______________________________________________________ 108|
|**5.9**|**Specific Electrical Requirements _____________________________________________ 108**|
|5.9.1|General _______________________________________________________________________ 108|
|5.9.2|Provisions against accidental contact with the traction power voltage _______________________ 108|
|5.9.3|Insulation co-ordination ___________________________________________________________ 109|
|5.9.4|Dielectric Tests _________________________________________________________________ 109|
|**5.10**|**Requirements for Test Tools and Procedures ___________________________________ 109**|
|**5.11**|**Quality and Safety Assurance _______________________________________________ 109**|
|**6**<br>**O**|**N-BOARDEQUIPMENT_________________________________________________ 110**|
|**6.1**|**Architectural Layouts ______________________________________________________ 110**|
|**6.2**|**Antenna Air-gap Interface __________________________________________________ 110**|
|6.2.1|Tele-powering Energy Transmission _________________________________________________ 110|
|6.2.2|Up-link Data Reception ___________________________________________________________ 114|
|**6.3**|**Intentionally Deleted _______________________________________________________ 116**|
|**6.4**|**RAMS Requirements ______________________________________________________ 117**|
|6.4.1|On-board Transmission Equipment functionality _______________________________________ 117|
|6.4.2|Reliability _____________________________________________________________________ 118|
|6.4.3|Availability ____________________________________________________________________ 118|
|6.4.4|Intentionally Deleted _____________________________________________________________ 118|
|6.4.5|Safety _________________________________________________________________________ 118|
|**6.5**|**Installation Requirements for Antennas _______________________________________ 125**|
|6.5.1|Reference Axes _________________________________________________________________ 125|
|6.5.2|Metal Masses in the Track _________________________________________________________ 125|
|6.5.3|Antenna sizes and Mounting Requirements ___________________________________________ 126|
|6.5.4|Allowed displacements for the Antenna Unit __________________________________________ 127|
|**6.6**|**Specific Environmental Conditions for Antennas _______________________________ 128**|
|6.6.1|Operational Temperature __________________________________________________________ 128|
|6.6.2|Storage ________________________________________________________________________ 128|
|6.6.3|Sealing, Dust and Moisture ________________________________________________________ 128|
|6.6.4|Mechanical Stress _______________________________________________________________ 128|
|6.6.5|Meteorological Conditions ________________________________________________________ 128|
|6.6.6|Chemical Conditions _____________________________________________________________ 128|
|6.6.7|Biological Conditions ____________________________________________________________ 128|

<!-- end of page 7 -->

|6.6.|8<br>Debris ________________________________________________________________________ 129|
|---|---|
|6.6.|9<br>Metallic Masses _________________________________________________________________ 129|
|6.6.|10<br>Cables ______________________________________________________________________ 130|
|**6.7**|**Specific EMC Requirements for Antennas _____________________________________ 131**|
|6.7.|1<br>General _______________________________________________________________________ 131|
|6.7.|2<br>In-band Emission ________________________________________________________________ 131|
|6.7.|3<br>Out-band Emission ______________________________________________________________ 131|
|6.7.|4<br>Eurobalise Transmission Susceptibility _______________________________________________ 132|
|6.7.|5<br>Out-band Susceptibility ___________________________________________________________ 132|
|**6.8**|**Specific Electrical Requirements _____________________________________________ 132**|
|**6.9**|**Requirements for Test Tools and Procedures ___________________________________ 132**|
|**6.10**|**Quality and Safety Assurance _______________________________________________ 132**|
|**ANNE**|**XA (INFORMATIVE), ADDITIONAL TECHNICAL INFORMATION _________________ 133**|
|**A1**|**CODING BACKGROUND _______________________________________________ 133**|
|**A1.1**|**Encoding _________________________________________________________________ 133**|
|A1.|1.1<br>General _____________________________________________________________________ 133|
|A1.|1.2<br>Comment to the 10-to-11-Bit Transformation________________________________________ 134|
|**A1.2**|**Decoding _________________________________________________________________ 134**|
|A1.|2.1<br>Synchronisation _______________________________________________________________ 134|
|A1.|2.2<br>Comments to the Receiver Operation ______________________________________________ 135|
|**A1.3**|**Safety Considerations ______________________________________________________ 136**|
|A1.|3.1<br>Introduction __________________________________________________________________ 136|
|A1.|3.2<br>Random Bit Errors and Burst Errors _______________________________________________ 136|
|A1.|3.3<br>Bit Slips and Insertions _________________________________________________________ 137|
|A1.|3.4<br>Telegram Change _____________________________________________________________ 137|
|A1.|3.5<br>Format Mixing _______________________________________________________________ 137|
|A1.|3.6<br>Over-sampling and Under-sampling _______________________________________________ 137|
|**ANNE**|**XB (NORMATIVE), ADDITIONAL TECHNICAL REQUIREMENTS _________________ 138**|
|**B1**|**REQUIREMENTS ON THETELE-POWERING SIGNAL _________________________ 138**|
|**B1.1**|**Toggling Tele-powering signal _______________________________________________ 138**|
|**B1.2**|**Non-toggling Tele-powering signal ___________________________________________ 138**|
|**B2**|**THE10-TO-11 BITTRANSFORMATIONSUBSTITUTIONWORDS ________________ 139**|
|**ANNE**|**XC (NORMATIVE), ADDITIONALTECHNICALREQUIREMENTS ________________ 142**|
|**C1**|**RETURNLOSSDEFINITION ____________________________________________ 142**|
|**C2**|**FERRITEDEVICES FORLZB CABLE APPLICATIONS _________________________ 142**|
|**ANNE**|**XD, RECOMMENDED ANDOPTIONALREQUIREMENTS _______________________ 143**|

<!-- end of page 8 -->

|**D1**|**INTEROPERABILITY WITH EARLIER GENERATIONS OFATP __________________ 143**|
|---|---|
|**D1.1**|**Requirements on the Tele-powering link to make Interoperability possible __________ 143**|
|**D1.2**|**Transfer Syntax ___________________________________________________________ 143**|
|D1.|2.1<br>Intentionally Deleted ___________________________________________________________ 143|
|D1.|2.2<br>Handshaking _________________________________________________________________ 143|
|D1.|2.3<br>Disconnection ________________________________________________________________ 143|
|D1.|2.4<br>Synchronisation _______________________________________________________________ 143|
|**D1.3**|**EMC Requirements for Tele-powering ________________________________________ 144**|
|**D2**|**INTENTIONALLYDELETED ____________________________________________ 144**|
|**D3**|**EARLIERATP SYSTEMS, CONSIDEREDPRODUCTS _________________________ 144**|
|**D4**|**BALISEBLOCKINGSIGNALOUTPUT(INTERFACE‘C4’) _____________________ 145**|
|**D4.1**|**General __________________________________________________________________ 145**|
|**D4.2**|**Physical Transmission ______________________________________________________ 145**|
|D4.|2.1<br>Transmission Medium __________________________________________________________ 145|
|D4.|2.2<br>Electrical Data ________________________________________________________________ 146|
|D4.|2.3<br>Functional Data _______________________________________________________________ 146|
|**D4.3**|**Transmission of Messages on Application Level ________________________________ 147**|
|D4.|3.1<br>General _____________________________________________________________________ 147|
|D4.|3.2<br>Message Description ___________________________________________________________ 147|
|D4.|3.3<br>Repetition Rate _______________________________________________________________ 147|
|D4.|3.4<br>Re-triggerability ______________________________________________________________ 147|
|**D4.4**|**Safety ___________________________________________________________________ 147**|
|**ANNE**|**XE INTENTIONALLYDELETED __________________________________________ 147**|
|**ANNE**|**XF (INFORMATIVE), CROSS-TALK ANALYSIS METHOD _______________________ 148**|
|**F1**|**BACKGROUND ______________________________________________________ 148**|
|**F2**|**MATRIX ___________________________________________________________ 148**|
|**F2.1**|**General __________________________________________________________________ 148**|
|**F2.2**|**Methodology to demonstrate compliance with THR _____________________________ 149**|
|**F2.3**|**I/O Diagrams _____________________________________________________________ 150**|
|**F3**|**STEP-BY-STEPMETHODOLOGY _________________________________________ 153**|
|**F4**|**DESCRIPTION OFSCENARIOS __________________________________________ 154**|
|**ANNE**|**XG (INFORMATIVE), GUIDELINES RELATED TOMETALLICMASSES ____________ 155**|
|**G1**|**INTRODUCTION _____________________________________________________ 155**|
|**G2**|**GUIDELINES FORDETERMININGAPPLICABLERULES _______________________ 155**|
|**G2.1**|**Step 1 _________________________________________________________________ 155**|

<!-- end of page 9 -->

|**G2.2**|**Step 2 ________________________________**|**_________________________________ 156**|
|---|---|---|
|**G2.3**|**Step 3 ________________________________**|**_________________________________ 157**|
|**G2.4**|**Step 4 ________________________________**|**_________________________________ 157**|

<!-- end of page 10 -->
