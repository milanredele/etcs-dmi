## **3. SCOPE OF THE TEST SPECIFICATIONS**

3.1.1.1 The scope of the Subset-076 is to define tests to be used in proving the technical conformity and functionality of the ETCS on board subsystem against requirements of the Subset-026 [2]. The operational use of the ETCS On board subsystem and the trackside engineering of real lines where the train will run are out of scope of the Ss-076. These two aspects have to be checked against the corresponding technical documentation by the competent body.

3.1.1.2 The list of (totally or partially) non-testable requirements and the related justifications are provided in Table 3.

3.1.1.3 In particular, regarding FRMCS the following strategy has been applied: parts of requirements applicable when FRMCS is the only radio system installed on-board and/or for which an FRMCS radio simulator would be needed to perform the test (i.e. also some parts of requirements applicable when both radio systems (GSMR+FRMCS) are installed on-board) are currently not tested by Subset-076. In future version of the document (when FRMCS radio simulator is available), all radio configurations will be fully tested.

3.1.1.4 Note: when “No” is indicated in the column “Partially testable”, it means that the whole requirement is considered as not testable.

**_Table 3: Non testable requirements_**

|**SUBSET-026 requirement**|**Justification**|**Partially**<br>**testable**|
|---|---|---|
|3.5.3.7.1|Seeremarksforparts1),2) and 3) of requirement|Yes|
|3.5.3.7.1 1)|FRMCS adaptor needed for full establishment of safe radio<br>connection|No|
|3.5.3.7.1 2)|Without FRMCS adaptor, testing limited to mission with only GSM-<br>R radio system|Yes|
|3.5.3.7.1 3)|Without FRMCS adaptor, the full establishment of safe radio<br>connection is not possible in case the radio network type is<br>FRMCS; it may also be difficult/impossible to ensure that the<br>previousradio systemstored byEuroradioisFRMCS|Yes|
|3.5.3.7.2|Testing limited to storage of GSM-R as radio system used for safe<br>radio connection:otherwiseFRMCS adaptorstrictlynecessary|Yes|
|3.5.4.2|Testing limited to re-connecting via GSM-R (as radio system used<br>for safe radio connection): otherwise FRMCS adaptor strictly<br>necessary|Yes|
|3.5.6.7|See remarks for parts a), b) and c) of requirement|Yes|
|3.5.6.7 a)|The configuration with FRMCS being the only radio system<br>installed on-board is not tested, so testing limited to the case<br>where the storedradionetworktypeisFRMCS|Yes|
|3.5.6.7 b)|Without FRMCS adaptor, testing limited to the case where FRMCS<br>on-boardisnotregistered|Yes|
|3.5.6.7 c)|Without FRMCS adaptor, testing limited to mission with only GSM-<br>R radio system|Yes|

<!-- end of page 7 -->

|**SUBSET-026 requirement**|**Justification**|**Partially**<br>**testable**|
|---|---|---|
|3.6.3.1.4.1|Requirement to be tested with SUBSET-074|No|
|3.13.10.2.6 b) b)|To ensure that the transition to Trip mode is due to condition Id [11]<br>and not [16], the conditions of test are difficult to reproduce in lab,<br>in particular due to the distance of 5m between the balise antenna<br>and the front end of the train which is defined in SUBSET-094 for<br>all the tests of SUBSET-076 (and that we do not intend to change<br>to cover this sub-requirement).<br>It has been considered that condition Id [16] will apply before<br>condition Id [11] when the first possible location of the BG is known<br>to be at the EOA or in advance of the EOA.<br>Therefore the most probable operational situation is tested with<br>3.13.10.2.6 b) a), which is also the easiest configuration to test<br>because at very low speed, the "on-board tolerances when<br>determining the reference location of the balise group" which are at<br>least above 3m according to constraints exported to the supplier in<br>SUBSET-094, should ensure that the min safe front end of the train<br>does not overpass the EOA before the transition to Trip with<br>condition Id [11].|No|
|3.13.10.2.6 b) c)|To ensure that the transition to Trip mode is due to condition Id [11]<br>and not [16], the conditions of test are difficult to reproduce in lab,<br>in particular due to the distance of 5m between the balise antenna<br>and the front end of the train which is defined in SUBSET-094 for<br>all the tests of SUBSET-076 (and that we do not intend to change<br>to cover this sub-requirement).<br>It has been considered that condition Id [16] will apply before<br>condition Id [11] when the first possible location of the BG is known<br>to be at the EOA or in advance of the EOA.<br>Therefore the most probable operational situation is tested with<br>3.13.10.2.6 b) a), which is also the easiest configuration to test<br>because at very low speed, the "on-board tolerances when<br>determining the reference location of the balise group" which are at<br>least above 3m according to constraints exported to the supplier in<br>SUBSET-094, should ensure that the min safe front end of the train<br>does not overpass the EOA before the transition to Trip with<br>condition Id [11].|No|
|3.16.2.4.8.2.1|Requirement to be tested with SUBSET-074|No|
|3.17.3.5 b)|Not testable with actual System Version X values|No|
|3.17.3.6 a)|Not testable with actual System Version X values|No|
|A.3.4.1.3 table - STM max<br>speed|Requirement to be tested with SUBSET-074|No|
|A.3.4.1.3 table - STM<br>system speed/distance|Requirement to be tested with SUBSET-074|No|
|A.3.4.1.3 table -<br>Unconditional Emergency<br>Stop|None of the special situations listed by A.3.4.1.2 seems possible<br>while UES stored on-board (which immediately leads to trip<br>procedure).|No|
|A.3.4.1.3 table - RBC/RIU<br>System Version|None of the special situations listed by A.3.4.1.2 seems possible to<br>provoke between reception of Msg 32 and the immediate reply by<br>sending of Msg159/154.|No|

<!-- end of page 8 -->

|**SUBSET-026 requirement**|**Justification**|**Partially**<br>**testable**|
|---|---|---|
|4.4.7.1.6 a)|Use of "can": cannot really be considered as an on-board<br>requirement. Will at least be indirectly tested with chapter 3 Table<br>2c anyway).|No|
|4.4.7.1.6 b)|Use of "can": cannot really be considered as an on-board<br>requirement. Will at least be indirectly tested with chapter 3 Table<br>2c anyway).|No|
|4.5.1.4|Generic requirement related to NP mode|No|
|4.6.3 table - Condition Id<br>[35]|STM - National Trip procedure is active<br>Requirement to be tested with SUBSET-074|No|
|4.6.3 table - Condition Id<br>[38]|STM - National Trip procedure is active<br>Requirement to be tested with SUBSET-074|No|
|4.7.2.1.4 table - Input<br>information Perform<br>mission with only one radio<br>system|Condition A testable at least in a specific mode<br>Without FRMCS simulator, tests limited to cases where GSM-R is<br>chosen.|Yes|
|4.7.2.1.4 table - Output<br>information NTC not<br>available|Requirement to be tested with SUBSET-074|No|
|4.7.2.1.4 table - Output<br>information NTC data need|Requirement to be tested with SUBSET-074|No|
|4.7.2.1.4 table - Output<br>information NTC failed|Requirement to be tested with SUBSET-074|No|
|4.8.3.1.1 table - Session<br>Management|Testing limited to Packet 42 (Session Management for RBC<br>interfaced to GSM-R): otherwise FRMCS adaptor needed for full<br>establishment ofsaferadio connection|Yes|
|4.8.3.1.1 table - RBC<br>Transition Order|Testing limited to Packet 131 (RBC transition order for RBC<br>interfaced to GSM-R): otherwise FRMCS adaptor needed for full<br>establishment ofsaferadio connection|Yes|
|4.8.3.1.1 table - Data to be<br>used by applications<br>outside ERTMS/ETCS|Data used by applications outside the ERTMS/ETCS system|No|
|4.8.3.1.1 table - Exception<br>[15]|For first bullet point: Testing limited to Radio Network type<br>=FRMCS otherwise FRMCS adaptor or OBU only equipped with<br>FRMCS strictlynecessary.|Yes|
|4.8.3.2 Table - STM max<br>speed|Requirement to be tested with SUBSET-074|No|
|4.8.3.2 Table - STM system<br>speed/distance|Requirement to be tested with SUBSET-074|No|
|4.8.3.2 exception [6]|Requirement to be tested with SUBSET-074|No|
|4.8.3.2 exception [7]|Requirement to be tested with SUBSET-074|No|
|4.8.4.2 table - Session<br>Management|Testing limited to Packet 42 (Session Management for RBC<br>interfaced to GSM-R): otherwise FRMCS adaptor needed for full<br>establishment ofsaferadio connection|Yes|

<!-- end of page 9 -->

|**SUBSET-026 requirement**|**Justification**|**Partially**<br>**testable**|
|---|---|---|
|4.8.4.2 table - RBC<br>Transition Order|Testing limited to Packet 131 (RBC transition order for RBC<br>interfaced to GSM-R): otherwise FRMCS adaptor needed for full<br>establishment ofsaferadio connection|Yes|
|4.8.4.2 table - Data to be<br>used by applications<br>outside ERTMS/ETCS|Data used by applications outside the ERTMS/ETCS system|No|
|4.10.1.3 e)|Action "not relevant" in next table of 4.10|No|
|4.10.1.3 table - line STM<br>max speed|Requirement to be tested with SUBSET-074|No|
|4.10.1.3 table - line STM<br>system speed/distance|Requirement to be tested with SUBSET-074|No|
|4.10.1.3 table - line Radio<br>system used for safe radio<br>connection|Not testable without FRMCS simulator (to check the connection<br>attempt with the radio that was not in use before the NP)|No|
|4.10.1.3 table - line Mission<br>performed with only one<br>radio system|Without FRMCS simulator, tests limited to cases where GSM-R is<br>chosen.|Yes|
|4.12.1.2 d)|Not relevant case and as stated in the requirement: "there is no<br>transition from the mode in which the brake command reason<br>could be applicable to the entered mode or the transition<br>condition(s) to the entered mode can only be fulfilled when the<br>condition(s) to release the brake command associated to this<br>individual reason(see 3.14.1)is(are)fulfilled"|No|
|4.12.1.2 e)|Not defined case: "the action on the brake command reason<br>cannot be determined. This concerns the entry in SF and IS<br>modes"|No|
|5.4.3.2 D7|See remarks for parts a) and b) of requirement|Yes|
|5.4.3.2 D7 a)|FRMCS adaptor strictly necessary (OBU only equipped with<br>FRMCS also strictlynecessaryfora part oftherequirement)|No|
|5.4.3.2 D7 b)|FRMCS adaptor strictly necessary|No|
|5.4.3.2 S3|See remarks for parts c), d), e) and i) of requirement|Yes|
|5.4.3.2 S3 c)|FRMCS adaptor strictly necessary and for parts additionally OBU<br>only equippedwith FRMCS strictlynecessary|No|
|5.4.3.2 S3 d)|FRMCS adaptor strictly necessary|No|
|5.4.3.2 S3 e)|Without FRMCS simulator, only the case where the GSM-R is<br>chosen is testable|Yes|
|5.4.3.2 S3 i)|Not testable for subcase which demands OBU only equipped with<br>FRMCS|Yes|
|5.4.3.2 S4|See remarks for parts a), b) and c) of requirement|Yes|
|5.4.3.2 S4 a)|FRMCS adaptor strictly necessary|No|
|5.4.3.2 S4 b)|Not testable for subcase which demands OBU only equipped with<br>FRMCS. Only testable with Radio Network type = FRMCS and<br>ETCS OB equipped with both FRMCS and GSM-R.|Yes|

<!-- end of page 10 -->

|**SUBSET-026 requirement**|**Justification**|**Partially**<br>**testable**|
|---|---|---|
|5.4.3.2 S4 c)|FRMCS adaptor strictly necessary|No|
|5.4.3.2 A42|See remarks for parts a) and b) of requirement|Yes|
|5.4.3.2 A42 a)|Not testable for subcase which demands OBU only equipped with<br>FRMCS. Only testable with Radio Network type = FRMCS and<br>ETCS OBequippedwithboth FRMCS and GSM-R.|Yes|
|5.4.3.2 A42 b)|For the subcase where only GSM-R failed, FRMCS adaptor strictly<br>necessary|Yes|
|5.4.3.2 D9|Testing limited to mission with only GSM-R radio system:<br>otherwiseFRMCS adaptorstrictlynecessary|Yes|
|5.4.3.3 - Following D2:<br>stored level is "invalid" or<br>"unknown"|The status of "Level" implies that it comes from NP, in which case<br>the "RBC contact information" is also TBR and cannot be valid.|No|
|5.6.2.2 D030|STM National Trip procedure<br>Requirement to be testedwithSUBSET-074|No|
|5.6.2.2 A030|STM National Trip procedure<br>Requirement to be testedwithSUBSET-074|No|
|5.8.3.7.1|Override function activated by STM<br>Requirement to be testedwithSUBSET-074|No|
|5.10.2.4.1|See remarks for part a) of requirement|Yes|
|5.10.2.4.1 a)|See remarks for part a) and b) of requirement|Yes|
|5.10.2.4.1 a) a)|Not possible for ETCS OB to detect that FRMCS OB is in working<br>condition|No|
|5.10.2.4.1 a) b)|Not possible for ETCS OB to detect that FRMCS OB is in working<br>condition|No|
|5.10.3.15.2|See remarks for part a) of requirement|Yes|
|5.10.3.15.2 a)|See remarks for parts a) and b) of requirement|Yes|
|5.10.3.15.2 a) a)|FRMCS adaptor strictly necessary|No|
|5.10.3.15.2 a) b)|FRMCS adaptor strictly necessary|No|
|6.6.2.1.2|This requirement replaces the requirement 3.6.1.3.4 which is not<br>an ETCS on-board requirement according to chapter 9 of<br>SUBSET-026|No|
|6.6.2.2.3|This requirement makes the requirement 4.4.7.1.6 b) not<br>applicable and this requirement is considered as Not testable in<br>this table|No|
|6.6.2.3.1|This requirement only removes the possible selection of SM in<br>5.4.3.2 S10. It is not testable as anyway the conditions for enabling<br>the SM buttons cannot be met while operating X=1 in Level 2 (no<br>communication session with a supervising RBC certified with a<br>system version X.Y > 2.2canexist).|No|
|6.6.2.3.2|This requirement only removes the possible selection of SM in<br>5.4.3.2 S20 via 5.4.5.3 k). It is not testable as anyway the<br>conditions for enabling the SM buttons cannot be met while<br>operating X=1 in Level 2 (no communication session with a<br>supervising RBC certified with a system version X.Y > 2.2 can<br>exist).|No|

<!-- end of page 11 -->

|**SUBSET-026 requirement**|**Justification**|**Partially**<br>**testable**|
|---|---|---|
|6.6.2.3.6|This requirement only removes the possible selection of SM in<br>5.11.2.2 S140. It is not testable as anyway the conditions for<br>enabling the SM buttons cannot be met while operating X=1 in<br>Level 2 (no communication session with a supervising RBC<br>certifiedwitha system version X.Y > 2.2canexist).|No|
|6.6.2.3.7|Removal of section 5.21 related to Supervised Manoeuvre<br>procedure: this procedure cannot be initated while operating X=1 in<br>Level 2 (no communication session with a supervising RBC<br>certifiedwitha system version X.Y > 2.2canexist).|No|
|6.6.4.1.1|This requirement refers to the requirement 6.6.2.1.2 and this<br>requirementis considered asNot testableinthis table|No|
|6.6.4.2.1|This requirement refers to the requirement 6.6.2.2.3 and this<br>requirementis considered asNot testableinthis table|No|
|6.6.4.3.1|Not testable for the same reason as for 6.6.2.3.1,2, 6 &7|No|
|8.4.1.5.1|Data used by applications outside the ERTMS/ETCS system|No|
|8.4.4.4.2 c)|Data used by applications outside the ERTMS/ETCS system|No|
|8.4.4.4.3 a)|Packet 4 in a message 157 is considered as not testable (possible<br>test scenario seemshighly unlikely).|No|
|8.4.4.4.3 e)|Not testable: Packet 44 (Data used by applications outside the<br>ERTMS/ETCS system)|No|

3.1.1.5 Hereafter the list of Sequences that shall be applied to follow a test campaign according to the TSI CCS, which contains the Subset-026 v4.0.0.

3.1.1.6 The column " _Test Sequence_ " provides the reference of the applicable sequence. The column “ _Train data set_ ” specifies the set of train data that needs to be configured within the on-board unit for the test sequence (the train data sets are defined in [5]).

3.1.1.7 Test Sequences dedicated to optional interfaces (indicated with a reference to the interface(s) in column " _Optional Interface_ ") do not have to be run if the on-board unit under test does not implement these optional interfaces.

3.1.1.8 Test Sequences requiring a specific configuration for the installation of on-board radio system(s) (“GSM-R only” or “FRMCS+GSM-R” indicated in column “Radio system(s) installed on-board”) do not have to be run if the on-board unit under test is not compatible with this configuration.

3.1.1.9 When nothing is indicated in column “Radio system(s) installed on-board”, Test Sequences can be run indifferently with the configurations of installation of onboard radio system(s) “GSM-R only” or “FRMCS+GSM-R”. The configuration “FRMCS only” is not currently tested (see 3.1.1.3) and the supplier does not have to provide it [5].

<!-- end of page 12 -->

**_Table 4: Applicable Test Sequences_**

|**Test Sequence**|**Optional**<br>**Interface**|**Radio**<br>**system(s)**<br>**installed on-**<br>**board**|**Train data set**|
|---|---|---|---|
|Subset-076-6-3_3040200_01_v400_SV30|||Generic|
|Subset-076-6-3_3040200_02_v400_SV30|||Generic|
|Subset-076-6-3_3040200_03_v400_SV30|||Generic|
|Subset-076-6-3_3040200_04_v400_SV30|||Generic|
|Subset-076-6-3_3040200_05_v400_SV30|||Generic|
|Subset-076-6-3_3040300_01_v400_SV30|RIU||Generic|
|Subset-076-6-3_3040400_03_v400_SV30|||Generic|
|Subset-076-6-3_3040400_04_v400_SV30|||Generic|
|Subset-076-6-3_3040400_05_v400_SV30|||Generic|
|Subset-076-6-3_3040400_06_v400_SV30|||Generic|
|Subset-076-6-3_3040400_07_v400_SV30|||Generic|
|Subset-076-6-3_3040400_08_v400_SV30|||Generic|
|Subset-076-6-3_3040400_09_v400_SV30|RIU||Generic|
|Subset-076-6-3_3040400_10_v400_SV30|||Generic|
|Subset-076-6-3_3040500_01_v400_SV30|EUROLOOP||Generic|
|Subset-076-6-3_3040500_02_v400_SV30|EUROLOOP||Generic|
|Subset-076-6-3_3040500_03_v400_SV30|EUROLOOP||Generic|
|Subset-076-6-3_3050300_01_v400_SV30|||Generic|
|Subset-076-6-3_3050300_02_v400_SV30|||Generic|
|Subset-076-6-3_3050300_03_v400_SV30|RIU||Generic|
|Subset-076-6-3_3050300_05_v400_SV30|||Generic|
|Subset-076-6-3_3050300_10_v400_SV30|||Generic|
|Subset-076-6-3_3050300_11_v400_SV30|||Generic|
|Subset-076-6-3_3050300_12_v400_SV30|||Generic|
|Subset-076-6-3_3050300_18_v400_SV30|||Generic|
|Subset-076-6-3_3050300_19_v400_SV30|||Generic|

<!-- end of page 13 -->

|**Test Sequence**|**Optional**<br>**Interface**|**Radio**<br>**system(s)**<br>**installed on-**<br>**board**|**Train data set**|
|---|---|---|---|
|Subset-076-6-3_3050400_01_v400_SV30|||Generic|
|Subset-076-6-3_3050400_02_v400_SV30|RIU||Generic|
|Subset-076-6-3_3050400_03_v400_SV30|||Generic|
|Subset-076-6-3_3050500_01_v400_SV30|RIU||Generic|
|Subset-076-6-3_3050500_02_v400_SV30|||Generic|
|Subset-076-6-3_3050500_03_v400_SV30|||Generic|
|Subset-076-6-3_3050500_04_v400_SV30|||Generic|
|Subset-076-6-3_3050500_08_v400_SV30|||Generic|
|Subset-076-6-3_3050500_10_v400_SV30|||Generic|
|Subset-076-6-3_3050500_11_v400_SV30|||Generic|
|Subset-076-6-3_3050600_01_v400_SV30|||Generic|
|Subset-076-6-3_3050600_03_v400_SV30||GSM-R only|Generic|
|Subset-076-6-3_3050600_04_v400_SV30|RIU||Generic|
|Subset-076-6-3_3050600_05_v400_SV30||FRMCS+GSM-R|Generic|
|Subset-076-6-3_3050600_06_v400_SV30||FRMCS+GSM-R|Generic|
|Subset-076-6-3_3050700_01_v400_SV30|RIU||Generic|
|Subset-076-6-3_3050700_02_v400_SV30|||Generic|
|Subset-076-6-3_3050700_03_v400_SV30|||Generic|
|Subset-076-6-3_3050700_04_v400_SV30|||Generic|
|Subset-076-6-3_3050700_05_v400_SV30|||Generic|
|Subset-076-6-3_3060100_01_v400_SV30|||Generic|
|Subset-076-6-3_3060200_01_v400_SV30|||Generic|
|Subset-076-6-3_3060300_01_v400_SV30|||Generic|
|Subset-076-6-3_3060300_02_v400_SV30|||Generic|
|Subset-076-6-3_3060400_01_v400_SV30|||Generic|
|Subset-076-6-3_3060500_01_v400_SV30|||Generic|
|Subset-076-6-3_3060500_03_v400_SV30|||Generic|

<!-- end of page 14 -->

|**Test Sequence**|**Optional**<br>**Interface**|**Radio**<br>**system(s)**<br>**installed on-**<br>**board**|**Train data set**|
|---|---|---|---|
|Subset-076-6-3_3060500_04_v400_SV30|||Generic|
|Subset-076-6-3_3060500_05_v400_SV30|||Generic|
|Subset-076-6-3_3060500_06_v400_SV30|||Generic|
|Subset-076-6-3_3060500_07_v400_SV30|||Generic|
|Subset-076-6-3_3060500_08_v400_SV30|Safe consist<br>length<br>information<br>acquired from<br>ERTMS/ETCS<br>external sources||Generic|
|Subset-076-6-3_3060500_09_v400_SV30|||Generic|
|Subset-076-6-3_3060500_10_v400_SV30|||Generic|
|Subset-076-6-3_3060500_11_v400_SV30|Safe consist<br>length<br>information<br>acquired from<br>ERTMS/ETCS<br>external sources||Generic|
|Subset-076-6-3_3060500_12_v400_SV30|Safe consist<br>length<br>information<br>acquired from<br>ERTMS/ETCS<br>external sources||Generic|
|Subset-076-6-3_3060500_13_v400_SV30|Safe consist<br>length<br>information<br>acquired from<br>ERTMS/ETCS<br>external sources||Generic|
|Subset-076-6-3_3060500_14_v400_SV30|Train Data<br>acquired from<br>ERTMS/ETCS<br>external sources||Generic|
|Subset-076-6-3_3060500_15_v400_SV30|||Generic|
|Subset-076-6-3_3060500_16_v400_SV30|||Generic|
|Subset-076-6-3_3060600_01_v400_SV30|||Generic|
|Subset-076-6-3_3060600_02_v400_SV30|STM||Generic|

<!-- end of page 15 -->

|**Test Sequence**|**Optional**<br>**Interface**|**Radio**<br>**system(s)**<br>**installed on-**<br>**board**|**Train data set**|
|---|---|---|---|
|Subset-076-6-3_3060700_01_v400_SV30|||Generic|
|Subset-076-6-3_3060800_01_v400_SV30|||Generic|
|Subset-076-6-3_3060800_02_v400_SV30|||Generic|
|Subset-076-6-3_3060800_03_v400_SV30|||Generic|
|Subset-076-6-3_3070200_01_v400_SV30|||Generic|
|Subset-076-6-3_3070200_02_v400_SV30|||Generic|
|Subset-076-6-3_3070300_01_v400_SV30|||Generic|
|Subset-076-6-3_3070300_02_v400_SV30|||Generic|
|Subset-076-6-3_3070300_03_v400_SV30|||Generic|
|Subset-076-6-3_3070300_04_v400_SV30|RIU||Generic|
|Subset-076-6-3_3070300_05_v400_SV30|||Generic|
|Subset-076-6-3_3070300_06_v400_SV30|RIU||Generic|
|Subset-076-6-3_3070300_07_v400_SV30|||Generic|
|Subset-076-6-3_3070300_08_v400_SV30|||Generic|
|Subset-076-6-3_3070300_09_v400_SV30|Safe consist<br>length<br>information<br>acquired from<br>ERTMS/ETCS<br>external sources||Generic|
|Subset-076-6-3_3070300_10_v400_SV30|Safe consist<br>length<br>information<br>acquired from<br>ERTMS/ETCS<br>external sources||Generic|
|Subset-076-6-3_3070300_11_v400_SV30|Safe consist<br>length<br>information<br>acquired from<br>ERTMS/ETCS<br>external sources||Generic|
|Subset-076-6-3_3070300_12_v400_SV30|||Generic|
|Subset-076-6-3_3070300_13_v400_SV30|||Generic|

<!-- end of page 16 -->

|**Test Sequence**|**Optional**<br>**Interface**|**Radio**<br>**system(s)**<br>**installed on-**<br>**board**|**Train data set**|
|---|---|---|---|
|Subset-076-6-3_3080200_01_v400_SV30|||Generic|
|Subset-076-6-3_3080200_02_v400_SV30|||Generic|
|Subset-076-6-3_3080200_03_v400_SV30|||Generic|
|Subset-076-6-3_3080200_04_v400_SV30|||Generic|
|Subset-076-6-3_3080200_05_v400_SV30|||Generic|
|Subset-076-6-3_3080200_06_v400_SV30|||Generic|
|Subset-076-6-3_3080200_07_v400_SV30|||Generic|
|Subset-076-6-3_3080200_08_v400_SV30|||Generic|
|Subset-076-6-3_3080300_01_v400_SV30|||Generic|
|Subset-076-6-3_3080400_01_v400_SV30|||Generic|
|Subset-076-6-3_3080400_03_v400_SV30|||Generic|
|Subset-076-6-3_3080400_05_v400_SV30|||Generic|
|Subset-076-6-3_3080400_06_v400_SV30|||Generic|
|Subset-076-6-3_3080400_07_v400_SV30|||Generic|
|Subset-076-6-3_3080400_08_v400_SV30|||Generic|
|Subset-076-6-3_3080400_09_v400_SV30|||Generic|
|Subset-076-6-3_3080400_10_v400_SV30|||Generic|
|Subset-076-6-3_3080400_12_v400_SV30|||Generic|
|Subset-076-6-3_3080400_13_v400_SV30|||Generic|
|Subset-076-6-3_3080400_14_v400_SV30|||Generic|
|Subset-076-6-3_3080500_01_v400_SV30|||Generic|
|Subset-076-6-3_3080500_03_v400_SV30|||Generic|
|Subset-076-6-3_3090200_01_v400_SV30|EUROLOOP||Generic|
|Subset-076-6-3_3090200_02_v400_SV30|EUROLOOP||Generic|
|Subset-076-6-3_3090200_04_v400_SV30|EUROLOOP||Generic|
|Subset-076-6-3_3090300_01_v400_SV30|RIU||Generic|
|Subset-076-6-3_3090300_02_v400_SV30|RIU||Generic|

<!-- end of page 17 -->

|**Test Sequence**|**Optional**<br>**Interface**|**Radio**<br>**system(s)**<br>**installed on-**<br>**board**|**Train data set**|
|---|---|---|---|
|Subset-076-6-3_3090300_03_v400_SV30|RIU||Generic|
|Subset-076-6-3_3090300_04_v400_SV30|RIU||Generic|
|Subset-076-6-3_3090300_05_v400_SV30|RIU||Generic|
|Subset-076-6-3_3090300_06_v400_SV30|RIU||Generic|
|Subset-076-6-3_3090300_07_v400_SV30|RIU||Generic|
|Subset-076-6-3_3090300_08_v400_SV30|RIU||Generic|
|Subset-076-6-3_3090300_09_v400_SV30|RIU||Generic|
|Subset-076-6-3_3090300_10_v400_SV30|RIU||Generic|
|Subset-076-6-3_3090300_11_v400_SV30|RIU||Generic|
|Subset-076-6-3_3090300_12_v400_SV30|RIU||Generic|
|Subset-076-6-3_3100200_01_v400_SV30|||Generic|
|Subset-076-6-3_3110200_01_v400_SV30|||Generic|
|Subset-076-6-3_3110200_02_v400_SV30|||Generic with<br>Safe consist<br>length<br>information|
|Subset-076-6-3_3110200_03_v400_SV30|Safe consist<br>length<br>information<br>acquired from<br>ERTMS/ETCS<br>external sources||Generic|
|Subset-076-6-3_3110300_01_v400_SV30|||Generic|
|Subset-076-6-3_3110300_02_v400_SV30|||Generic with<br>Safe consist<br>length<br>information|
|Subset-076-6-3_3110300_03_v400_SV30|||Generic with<br>Safe consist<br>length<br>information|
|Subset-076-6-3_3110400_01_v400_SV30|||Generic|
|Subset-076-6-3_3110400_02_v400_SV30|||Generic|

<!-- end of page 18 -->

|**Test Sequence**|**Optional**<br>**Interface**|**Radio**<br>**system(s)**<br>**installed on-**<br>**board**|**Train data set**|
|---|---|---|---|
|Subset-076-6-3_3110500_01_v400_SV30|||Generic|
|Subset-076-6-3_3110500_02_v400_SV30|||Generic|
|Subset-076-6-3_3110500_03_v400_SV30|||Generic|
|Subset-076-6-3_3110600_01_v400_SV30|||Generic|
|Subset-076-6-3_3110600_02_v400_SV30|RIU||Generic|
|Subset-076-6-3_3110600_03_v400_SV30|||Generic|
|Subset-076-6-3_3110600_04_v400_SV30|EUROLOOP||Generic|
|Subset-076-6-3_3110700_01_v400_SV30|||Generic|
|Subset-076-6-3_3110800_01_v400_SV30|||Generic|
|Subset-076-6-3_3110800_02_v400_SV30|||Generic with<br>Safe consist<br>length<br>information|
|Subset-076-6-3_3111100_01_v400_SV30|||Gamma 1|
|Subset-076-6-3_3111100_02_v400_SV30|||Lambda 1|
|Subset-076-6-3_3111100_03_v400_SV30|||Gamma 1|
|Subset-076-6-3_3111100_04_v400_SV30|||Lambda 1|
|Subset-076-6-3_3111100_05_v400_SV30|||Gamma 1|
|Subset-076-6-3_3111100_06_v400_SV30|||Gamma 1|
|Subset-076-6-3_3111200_01_v400_SV30|||Generic|
|Subset-076-6-3_3120200_01_v400_SV30|||Generic|
|Subset-076-6-3_3120200_04_v400_SV30|||Generic|
|Subset-076-6-3_3120200_05_v400_SV30|||Generic|
|Subset-076-6-3_3120200_06_v400_SV30|||Generic without<br>traction system|
|Subset-076-6-3_3120200_07_v400_SV30|||Generic|
|Subset-076-6-3_3120300_01_v400_SV30|||Generic|
|Subset-076-6-3_3120300_02_v400_SV30|||Generic|
|Subset-076-6-3_3120300_03_v400_SV30|||Generic|

<!-- end of page 19 -->

|**Test Sequence**|**Optional**<br>**Interface**|**Radio**<br>**system(s)**<br>**installed on-**<br>**board**|**Train data set**|
|---|---|---|---|
|Subset-076-6-3_3120300_04_v400_SV30|||Generic|
|Subset-076-6-3_3120300_05_v400_SV30|||Generic|
|Subset-076-6-3_3120300_06_v400_SV30|||Generic|
|Subset-076-6-3_3120300_07_v400_SV30|||Generic|
|Subset-076-6-3_3120300_08_v400_SV30|||Generic|
|Subset-076-6-3_3120300_09_v400_SV30|||Generic|
|Subset-076-6-3_3120400_01_v400_SV30|||Generic|
|Subset-076-6-3_3120400_02_v400_SV30|||Generic|
|Subset-076-6-3_3120400_03_v400_SV30|||Generic|
|Subset-076-6-3_3120400_04_v400_SV30|||Generic|
|Subset-076-6-3_3120400_05_v400_SV30|||Generic|
|Subset-076-6-3_3120400_06_v400_SV30|||Generic|
|Subset-076-6-3_3120400_07_v400_SV30|||Generic|
|Subset-076-6-3_3120400_08_v400_SV30|||Generic|
|Subset-076-6-3_3130232_01_v400_SV30|||Gamma 1|
|Subset-076-6-3_3130232_02_v400_SV30|||Lambda 1|
|Subset-076-6-3_3130232_03_v400_SV30|||Gamma 1|
|Subset-076-6-3_3130232_04_v400_SV30|||Lambda 1|
|Subset-076-6-3_3130232_05_v400_SV30|||Gamma 1|
|Subset-076-6-3_3130232_06_v400_SV30|||Lambda 1|
|Subset-076-6-3_3130232_07_v400_SV30|||Gamma 1|
|Subset-076-6-3_3130232_08_v400_SV30|||Lambda 1|
|Subset-076-6-3_3130232_09_v400_SV30|||Gamma 1|
|Subset-076-6-3_3130232_10_v400_SV30|||Lambda 1|
|Subset-076-6-3_3130232_11_v400_SV30|||Gamma 1|
|Subset-076-6-3_3130232_12_v400_SV30|||Lambda 1|
|Subset-076-6-3_3130232_13_v400_SV30|||Gamma 1|

<!-- end of page 20 -->

|**Test Sequence**|**Optional**<br>**Interface**|**Radio**<br>**system(s)**<br>**installed on-**<br>**board**|**Train data set**|
|---|---|---|---|
|Subset-076-6-3_3130232_14_v400_SV30|||Lambda 1|
|Subset-076-6-3_3130232_15_v400_SV30|||Gamma 1|
|Subset-076-6-3_3130232_16_v400_SV30|||Lambda 1|
|Subset-076-6-3_3130232_17_v400_SV30|||Gamma 1|
|Subset-076-6-3_3130232_18_v400_SV30|||Lambda 1|
|Subset-076-6-3_3130233_01_v400_SV30|||Gamma 1|
|Subset-076-6-3_3130233_02_v400_SV30|||Lambda 1|
|Subset-076-6-3_3130233_03_v400_SV30|||Gamma 2|
|Subset-076-6-3_3130233_04_v400_SV30|||Gamma 1|
|Subset-076-6-3_3130233_05_v400_SV30|||Gamma 1|
|Subset-076-6-3_3130233_06_v400_SV30|||Gamma 2|
|Subset-076-6-3_3130234_01_v400_SV30|||Gamma 2|
|Subset-076-6-3_3130234_02_v400_SV30|||Gamma 1|
|Subset-076-6-3_3130234_03_v400_SV30|||Gamma 1|
|Subset-076-6-3_3130234_04_v400_SV30|||Gamma 1|
|Subset-076-6-3_3130234_05_v400_SV30|||Gamma 2|
|Subset-076-6-3_3130234_06_v400_SV30|||Gamma 1|
|Subset-076-6-3_3130234_07_v400_SV30|||Lambda 4|
|Subset-076-6-3_3130234_08_v400_SV30|||Gamma 1|
|Subset-076-6-3_3130234_10_v400_SV30|||Gamma 1|
|Subset-076-6-3_3130235_01_v400_SV30|||Gamma 1|
|Subset-076-6-3_3130235_02_v400_SV30|||Lambda 1|
|Subset-076-6-3_3130235_03_v400_SV30|||Gamma 1|
|Subset-076-6-3_3130235_04_v400_SV30|||Lambda 1|
|Subset-076-6-3_3130235_05_v400_SV30|||Gamma 2|
|Subset-076-6-3_3130237_01_v400_SV30|||Gamma 1|
|Subset-076-6-3_3130237_02_v400_SV30|||Gamma 1|

<!-- end of page 21 -->

|**Test Sequence**|**Optional**<br>**Interface**|**Radio**<br>**system(s)**<br>**installed on-**<br>**board**|**Train data set**|
|---|---|---|---|
|Subset-076-6-3_3130237_03_v400_SV30|||Gamma 1|
|Subset-076-6-3_3130237_04_v400_SV30|||Gamma 1|
|Subset-076-6-3_3130237_05_v400_SV30|||Lambda 3|
|Subset-076-6-3_3130237_06_v400_SV30|||Lambda 1|
|Subset-076-6-3_3130237_07_v400_SV30|||Lambda 1|
|Subset-076-6-3_3130237_08_v400_SV30|||Lambda 1|
|Subset-076-6-3_3130237_09_v400_SV30|||Lambda 1|
|Subset-076-6-3_3130237_10_v400_SV30|||Gamma 1|
|Subset-076-6-3_3130237_11_v400_SV30|||Lambda 1|
|Subset-076-6-3_3130237_12_v400_SV30|||Lambda 1|
|Subset-076-6-3_3130237_13_v400_SV30|||Lambda 1|
|Subset-076-6-3_3130237_14_v400_SV30|||Gamma 1|
|Subset-076-6-3_3130237_15_v400_SV30|||Lambda 1|
|Subset-076-6-3_3130237_16_v400_SV30|||Gamma 1|
|Subset-076-6-3_3130237_17_v400_SV30|||Lambda 1|
|Subset-076-6-3_3130237_18_v400_SV30|||Gamma 1|
|Subset-076-6-3_3130237_19_v400_SV30|||Lambda 1|
|Subset-076-6-3_3130700_01_v400_SV30|||Gamma 1|
|Subset-076-6-3_3130700_02_v400_SV30|||Lambda 1|
|Subset-076-6-3_3130700_03_v400_SV30|||Gamma 1|
|Subset-076-6-3_3130700_04_v400_SV30|||Lambda 1|
|Subset-076-6-3_3130700_05_v400_SV30|||Gamma 1|
|Subset-076-6-3_3130700_06_v400_SV30|||Lambda 1|
|Subset-076-6-3_3130700_07_v400_SV30|||Gamma 1|
|Subset-076-6-3_3130700_08_v400_SV30|||Lambda 1|
|Subset-076-6-3_3130700_09_v400_SV30|||Generic|
|Subset-076-6-3_3130810_01_v400_SV30|||Gamma 1|

<!-- end of page 22 -->

|**Test Sequence**|**Optional**<br>**Interface**|**Radio**<br>**system(s)**<br>**installed on-**<br>**board**|**Train data set**|
|---|---|---|---|
|Subset-076-6-3_3130810_02_v400_SV30|||Lambda 1|
|Subset-076-6-3_3131020_01_v400_SV30|||Gamma 1|
|Subset-076-6-3_3131020_02_v400_SV30|||Lambda 1|
|Subset-076-6-3_3131020_03_v400_SV30|||Gamma 1|
|Subset-076-6-3_3131020_04_v400_SV30|||Lambda 1|
|Subset-076-6-3_3131020_05_v400_SV30|||Gamma 2|
|Subset-076-6-3_3131030_01_v400_SV30|||Gamma 1|
|Subset-076-6-3_3131030_02_v400_SV30|||Lambda 1|
|Subset-076-6-3_3131030_03_v400_SV30|||Gamma 1|
|Subset-076-6-3_3131030_04_v400_SV30|||Lambda 1|
|Subset-076-6-3_3131030_05_v400_SV30|||Gamma 1|
|Subset-076-6-3_3131030_06_v400_SV30|||Lambda 1|
|Subset-076-6-3_3131030_07_v400_SV30|||Gamma 1|
|Subset-076-6-3_3131030_08_v400_SV30|||Lambda 1|
|Subset-076-6-3_3131030_09_v400_SV30|||Gamma 1|
|Subset-076-6-3_3131030_10_v400_SV30|||Lambda 1|
|Subset-076-6-3_3131030_11_v400_SV30|||Gamma 1|
|Subset-076-6-3_3131030_12_v400_SV30|||Lambda 1|
|Subset-076-6-3_3131030_13_v400_SV30|||Gamma 1|
|Subset-076-6-3_3131030_14_v400_SV30|||Lambda 1|
|Subset-076-6-3_3131030_15_v400_SV30|||Gamma 1|
|Subset-076-6-3_3131030_16_v400_SV30|||Lambda 1|
|Subset-076-6-3_3131030_17_v400_SV30|||Gamma 1|
|Subset-076-6-3_3131030_18_v400_SV30|||Lambda 1|
|Subset-076-6-3_3131030_19_v400_SV30|||Gamma 2|
|Subset-076-6-3_3131030_20_v400_SV30|||Gamma 1|
|Subset-076-6-3_3131030_21_v400_SV30|||Lambda 1|

<!-- end of page 23 -->

|**Test Sequence**|**Optional**<br>**Interface**|**Radio**<br>**system(s)**<br>**installed on-**<br>**board**|**Train data set**|
|---|---|---|---|
|Subset-076-6-3_3131030_22_v400_SV30|||Gamma 2|
|Subset-076-6-3_3131030_23_v400_SV30|||Gamma 1|
|Subset-076-6-3_3131030_24_v400_SV30|||Lambda 1|
|Subset-076-6-3_3131030_25_v400_SV30|||Gamma 1|
|Subset-076-6-3_3131030_26_v400_SV30|||Lambda 1|
|Subset-076-6-3_3131030_27_v400_SV30|||Gamma 1|
|Subset-076-6-3_3131030_28_v400_SV30|||Lambda 1|
|Subset-076-6-3_3131040_01_v400_SV30|||Gamma 1|
|Subset-076-6-3_3131040_02_v400_SV30|||lambda 1|
|Subset-076-6-3_3131040_03_v400_SV30|||Gamma 1|
|Subset-076-6-3_3131040_04_v400_SV30|||Lambda 1|
|Subset-076-6-3_3131040_05_v400_SV30|||Gamma 1|
|Subset-076-6-3_3131040_06_v400_SV30|||Lambda 1|
|Subset-076-6-3_3131040_07_v400_SV30|||Gamma 1|
|Subset-076-6-3_3131040_08_v400_SV30|||Lambda 1|
|Subset-076-6-3_3131040_09_v400_SV30|||Gamma 1|
|Subset-076-6-3_3131040_10_v400_SV30|||Lambda 1|
|Subset-076-6-3_3131040_11_v400_SV30|||Gamma 1|
|Subset-076-6-3_3131040_12_v400_SV30|||Lambda 1|
|Subset-076-6-3_3131040_13_v400_SV30|||Gamma 1|
|Subset-076-6-3_3131040_14_v400_SV30|||Lambda 1|
|Subset-076-6-3_3131040_15_v400_SV30|||Gamma 1|
|Subset-076-6-3_3131040_16_v400_SV30|||Lambda 1|
|Subset-076-6-3_3131040_17_v400_SV30|||Gamma 1|
|Subset-076-6-3_3131040_18_v400_SV30|||Lambda 1|
|Subset-076-6-3_3131040_19_v400_SV30|||Gamma 1|
|Subset-076-6-3_3131040_20_v400_SV30|||Lambda 1|

<!-- end of page 24 -->

|**Test Sequence**|**Optional**<br>**Interface**|**Radio**<br>**system(s)**<br>**installed on-**<br>**board**|**Train data set**|
|---|---|---|---|
|Subset-076-6-3_3131040_21_v400_SV30|||Gamma 1|
|Subset-076-6-3_3131040_22_v400_SV30|||Lambda 1|
|Subset-076-6-3_3131040_23_v400_SV30|||Gamma 1|
|Subset-076-6-3_3131040_24_v400_SV30|||Lambda 1|
|Subset-076-6-3_3131040_25_v400_SV30|||Gamma 1|
|Subset-076-6-3_3131040_26_v400_SV30|||Lambda 1|
|Subset-076-6-3_3131040_27_v400_SV30|||Gamma 1|
|Subset-076-6-3_3131040_28_v400_SV30|||Lambda 1|
|Subset-076-6-3_3131040_29_v400_SV30|||Gamma 1|
|Subset-076-6-3_3131040_30_v400_SV30|||Lambda 1|
|Subset-076-6-3_3131040_31_v400_SV30|||Gamma 1|
|Subset-076-6-3_3131040_32_v400_SV30|||Lambda 1|
|Subset-076-6-3_3131040_33_v400_SV30|||Gamma 1|
|Subset-076-6-3_3131040_34_v400_SV30|||Lambda 1|
|Subset-076-6-3_3131040_35_v400_SV30|||Gamma 1|
|Subset-076-6-3_3131040_36_v400_SV30|||Lambda 1|
|Subset-076-6-3_3131040_37_v400_SV30|||Gamma 1|
|Subset-076-6-3_3131040_38_v400_SV30|||Lambda 1|
|Subset-076-6-3_3131040_39_v400_SV30|||Gamma 1|
|Subset-076-6-3_3131040_40_v400_SV30|||Lambda 1|
|Subset-076-6-3_3131040_41_v400_SV30|||Gamma 1|
|Subset-076-6-3_3131040_42_v400_SV30|||Lambda 1|
|Subset-076-6-3_3131040_43_v400_SV30|||Gamma 1|
|Subset-076-6-3_3131040_44_v400_SV30|||Lambda 1|
|Subset-076-6-3_3131040_45_v400_SV30|||Gamma 1|
|Subset-076-6-3_3131040_46_v400_SV30|||Lambda 1|
|Subset-076-6-3_3131040_47_v400_SV30|||Gamma 1|

<!-- end of page 25 -->

|**Test Sequence**|**Optional**<br>**Interface**|**Radio**<br>**system(s)**<br>**installed on-**<br>**board**|**Train data set**|
|---|---|---|---|
|Subset-076-6-3_3131040_48_v400_SV30|||Lambda 1|
|Subset-076-6-3_3131040_49_v400_SV30|||Gamma 1|
|Subset-076-6-3_3131040_50_v400_SV30|||Lambda 1|
|Subset-076-6-3_3131040_51_v400_SV30|||Gamma 1|
|Subset-076-6-3_3131040_52_v400_SV30|||Lambda 1|
|Subset-076-6-3_3131040_53_v400_SV30|||Gamma 1|
|Subset-076-6-3_3131040_54_v400_SV30|||Lambda 1|
|Subset-076-6-3_3131040_55_v400_SV30|||Gamma 1|
|Subset-076-6-3_3131040_56_v400_SV30|||Lambda 1|
|Subset-076-6-3_3131040_57_v400_SV30|||Gamma 1|
|Subset-076-6-3_3131040_58_v400_SV30|||Lambda 1|
|Subset-076-6-3_3131040_59_v400_SV30|||Gamma 1|
|Subset-076-6-3_3131040_60_v400_SV30|||Lambda 1|
|Subset-076-6-3_3131040_61_v400_SV30|||Gamma 1|
|Subset-076-6-3_3131040_62_v400_SV30|||Lambda 1|
|Subset-076-6-3_3131040_63_v400_SV30|||Gamma 1|
|Subset-076-6-3_3131040_64_v400_SV30|||Lambda 1|
|Subset-076-6-3_3131040_65_v400_SV30|||Gamma 1|
|Subset-076-6-3_3131040_66_v400_SV30|||Lambda 1|
|Subset-076-6-3_3131040_67_v400_SV30|||Gamma 1|
|Subset-076-6-3_3131040_68_v400_SV30|||Lambda 1|
|Subset-076-6-3_3131040_69_v400_SV30|||Gamma 1|
|Subset-076-6-3_3131040_70_v400_SV30|||Lambda 1|
|Subset-076-6-3_3131040_71_v400_SV30|||Gamma 1|
|Subset-076-6-3_3131040_72_v400_SV30|||Lambda 1|
|Subset-076-6-3_3131040_73_v400_SV30|||Gamma 1|
|Subset-076-6-3_3131040_74_v400_SV30|||Lambda 1|

<!-- end of page 26 -->

|**Test Sequence**|**Optional**<br>**Interface**|**Radio**<br>**system(s)**<br>**installed on-**<br>**board**|**Train data set**|
|---|---|---|---|
|Subset-076-6-3_3131040_75_v400_SV30|||Gamma 1|
|Subset-076-6-3_3131040_76_v400_SV30|||Lambda 1|
|Subset-076-6-3_3131040_77_v400_SV30|||Gamma 1|
|Subset-076-6-3_3131040_78_v400_SV30|||Lambda 1|
|Subset-076-6-3_3131040_79_v400_SV30|||Gamma 1|
|Subset-076-6-3_3131040_80_v400_SV30|||Lambda 1|
|Subset-076-6-3_3131040_81_v400_SV30|||Gamma 1|
|Subset-076-6-3_3131040_82_v400_SV30|||Gamma 2|
|Subset-076-6-3_3131040_83_v400_SV30|||Gamma 1|
|Subset-076-6-3_3131040_84_v400_SV30|||Lambda 1|
|Subset-076-6-3_3131040_85_v400_SV30|||Gamma 2|
|Subset-076-6-3_3131040_86_v400_SV30|||Lambda 2|
|Subset-076-6-3_3131040_87_v400_SV30|||Gamma 1|
|Subset-076-6-3_3131040_88_v400_SV30|||Lambda 1|
|Subset-076-6-3_3131040_89_v400_SV30|||Gamma 1|
|Subset-076-6-3_3131040_90_v400_SV30|||Lambda 1|
|Subset-076-6-3_3131040_91_v400_SV30|||Gamma 1|
|Subset-076-6-3_3131040_92_v400_SV30|||Gamma 1|
|Subset-076-6-3_3131040_93_v400_SV30|||Gamma 1|
|Subset-076-6-3_3131040_94_v400_SV30|||Gamma 1|
|Subset-076-6-3_3131040_95_v400_SV30|||Gamma 1|
|Subset-076-6-3_3131040_96_v400_SV30|||Gamma 2|
|Subset-076-6-3_3131040_97_v400_SV30|||Lambda 1|
|Subset-076-6-3_3131040_98_v400_SV30|||Lambda 1|
|Subset-076-6-3_3131040_99_v400_SV30|||Gamma 1|
|Subset-076-6-3_3131050_01_v400_SV30|||Gamma 1|
|Subset-076-6-3_3131050_02_v400_SV30|||Lambda 1|

<!-- end of page 27 -->

|**Test Sequence**|**Optional**<br>**Interface**|**Radio**<br>**system(s)**<br>**installed on-**<br>**board**|**Train data set**|
|---|---|---|---|
|Subset-076-6-3_3131050_03_v400_SV30|||Gamma 1|
|Subset-076-6-3_3131050_04_v400_SV30|||Lambda 1|
|Subset-076-6-3_3131050_05_v400_SV30|||Gamma 1|
|Subset-076-6-3_3131050_06_v400_SV30|||Lambda 1|
|Subset-076-6-3_3131050_07_v400_SV30|||Gamma 1|
|Subset-076-6-3_3131050_08_v400_SV30|||Lambda 1|
|Subset-076-6-3_3131050_09_v400_SV30|||Gamma 1|
|Subset-076-6-3_3131050_10_v400_SV30|||Lambda 1|
|Subset-076-6-3_3131050_11_v400_SV30|||Gamma 1|
|Subset-076-6-3_3131050_12_v400_SV30|||Lambda 1|
|Subset-076-6-3_3131050_13_v400_SV30|||Gamma 1|
|Subset-076-6-3_3131050_14_v400_SV30|||Lambda 1|
|Subset-076-6-3_3131050_15_v400_SV30|||Gamma 1|
|Subset-076-6-3_3131050_16_v400_SV30|||Lambda 1|
|Subset-076-6-3_3131050_17_v400_SV30|||Gamma 1|
|Subset-076-6-3_3131050_18_v400_SV30|||Lambda 1|
|Subset-076-6-3_3131050_19_v400_SV30|||Gamma 1|
|Subset-076-6-3_3131050_20_v400_SV30|||Lambda 1|
|Subset-076-6-3_3131050_21_v400_SV30|||Gamma 1|
|Subset-076-6-3_3131050_22_v400_SV30|||Lambda 1|
|Subset-076-6-3_3131050_23_v400_SV30|||Gamma 1|
|Subset-076-6-3_3131050_24_v400_SV30|||Lambda 1|
|Subset-076-6-3_3131060_01_v400_SV30|||Gamma 1|
|Subset-076-6-3_3131060_02_v400_SV30|||Lambda 1|
|Subset-076-6-3_3131060_03_v400_SV30|||Gamma 1|
|Subset-076-6-3_3131060_04_v400_SV30|||Lambda 1|
|Subset-076-6-3_3131060_05_v400_SV30|||Gamma 1|

<!-- end of page 28 -->

|**Test Sequence**|**Optional**<br>**Interface**|**Radio**<br>**system(s)**<br>**installed on-**<br>**board**|**Train data set**|
|---|---|---|---|
|Subset-076-6-3_3131060_06_v400_SV30|||Lambda 1|
|Subset-076-6-3_3131060_07_v400_SV30|||Gamma 1|
|Subset-076-6-3_3131060_08_v400_SV30|||Lambda 1|
|Subset-076-6-3_3131060_09_v400_SV30|||Gamma 1|
|Subset-076-6-3_3131060_10_v400_SV30|||Lambda 1|
|Subset-076-6-3_3131060_11_v400_SV30|||Gamma 1|
|Subset-076-6-3_3131060_12_v400_SV30|||Lambda 1|
|Subset-076-6-3_3131060_13_v400_SV30|||Gamma 1|
|Subset-076-6-3_3131060_14_v400_SV30|||Lambda 1|
|Subset-076-6-3_3131060_15_v400_SV30|||Gamma 1|
|Subset-076-6-3_3131060_16_v400_SV30|||Lambda 1|
|Subset-076-6-3_3131060_17_v400_SV30|||Gamma 1|
|Subset-076-6-3_3131060_18_v400_SV30|||Lambda 1|
|Subset-076-6-3_3131060_19_v400_SV30|||Gamma 1|
|Subset-076-6-3_3131060_20_v400_SV30|||Lambda 1|
|Subset-076-6-3_3131100_01_v400_SV30|||Gamma 1|
|Subset-076-6-3_3131100_02_v400_SV30|||Lambda 1|
|Subset-076-6-3_3131100_03_v400_SV30|||Gamma 1|
|Subset-076-6-3_3131100_04_v400_SV30|||Lambda 1|
|Subset-076-6-3_3131100_05_v400_SV30|||Gamma 1|
|Subset-076-6-3_3131100_06_v400_SV30|||Lambda 1|
|Subset-076-6-3_3131100_07_v400_SV30|||Lambda 1|
|Subset-076-6-3_3131100_08_v400_SV30|||Gamma 1|
|Subset-076-6-3_3131100_09_v400_SV30|||Gamma 1|
|Subset-076-6-3_3131100_10_v400_SV30|||Gamma 1|
|Subset-076-6-3_3131100_11_v400_SV30|||Gamma 1|
|Subset-076-6-3_3140100_02_v400_SV30|||Generic|

<!-- end of page 29 -->

|**Test Sequence**|**Optional**<br>**Interface**|**Radio**<br>**system(s)**<br>**installed on-**<br>**board**|**Train data set**|
|---|---|---|---|
|Subset-076-6-3_3140100_03_v400_SV30|||Generic|
|Subset-076-6-3_3140100_04_v400_SV30|||Generic|
|Subset-076-6-3_3140100_05_v400_SV30|||Generic|
|Subset-076-6-3_3140300_01_v400_SV30|||Generic|
|Subset-076-6-3_3140300_02_v400_SV30|||Generic|
|Subset-076-6-3_3140300_03_v400_SV30|||Generic|
|Subset-076-6-3_3150100_01_v400_SV30|||Generic|
|Subset-076-6-3_3150100_02_v400_SV30|||Generic|
|Subset-076-6-3_3150100_03_v400_SV30|||Generic|
|Subset-076-6-3_3150100_04_v400_SV30|||Generic|
|Subset-076-6-3_3150100_05_v400_SV30|||Generic|
|Subset-076-6-3_3150100_06_v400_SV30|||Generic|
|Subset-076-6-3_3150100_07_v400_SV30|||Generic|
|Subset-076-6-3_3150100_08_v400_SV30|||Generic|
|Subset-076-6-3_3150100_09_v400_SV30|||Generic|
|Subset-076-6-3_3150100_10_v400_SV30|Safe consist<br>length<br>information<br>acquired from<br>ERTMS/ETCS<br>external sources||Generic|
|Subset-076-6-3_3150100_11_v400_SV30|||Generic|
|Subset-076-6-3_3150400_01_v400_SV30|||Generic|
|Subset-076-6-3_3150400_02_v400_SV30|||Generic|
|Subset-076-6-3_3150700_01_v400_SV30|||Generic|
|Subset-076-6-3_3150800_01_v400_SV30|||Generic|
|Subset-076-6-3_3150800_02_v400_SV30|||Generic|
|Subset-076-6-3_3150800_03_v400_SV30|EUROLOOP||Generic|
|Subset-076-6-3_3150800_04_v400_SV30|||Generic|

<!-- end of page 30 -->

|**Test Sequence**|**Optional**<br>**Interface**|**Radio**<br>**system(s)**<br>**installed on-**<br>**board**|**Train data set**|
|---|---|---|---|
|Subset-076-6-3_3150800_05_v400_SV30|||Generic|
|Subset-076-6-3_3150900_01_v400_SV30|||Generic|
|Subset-076-6-3_3150900_02_v400_SV30|||Generic|
|Subset-076-6-3_3150900_03_v400_SV30|||Generic|
|Subset-076-6-3_3160200_02_v400_SV30|||Generic|
|Subset-076-6-3_3160200_03_v400_SV30|||Generic|
|Subset-076-6-3_3160200_04_v400_SV30|||Generic|
|Subset-076-6-3_3160200_05_v400_SV30|||Generic|
|Subset-076-6-3_3160200_06_v400_SV30|||Generic|
|Subset-076-6-3_3160200_07_v400_SV30|||Generic|
|Subset-076-6-3_3160200_08_v400_SV30|||Generic|
|Subset-076-6-3_3160200_09_v400_SV30|||Generic|
|Subset-076-6-3_3160200_10_v400_SV30|||Generic|
|Subset-076-6-3_3160200_11_v400_SV30|||Generic|
|Subset-076-6-3_3160200_12_v400_SV30|||Generic|
|Subset-076-6-3_3160200_13_v400_SV30|||Generic|
|Subset-076-6-3_3160200_14_v400_SV30|||Generic|
|Subset-076-6-3_3160200_15_v400_SV30|||Generic|
|Subset-076-6-3_3160200_16_v400_SV30|||Generic|
|Subset-076-6-3_3160200_17_v400_SV30|||Generic|
|Subset-076-6-3_3160200_18_v400_SV30|||Generic|
|Subset-076-6-3_3160200_19_v400_SV30|||Generic|
|Subset-076-6-3_3160200_20_v400_SV30|||Generic|
|Subset-076-6-3_3160200_21_v400_SV30|||Generic|
|Subset-076-6-3_3160200_22_v400_SV30|||Generic|
|Subset-076-6-3_3160200_23_v400_SV30|||Generic|
|Subset-076-6-3_3160200_24_v400_SV30|||Generic|

<!-- end of page 31 -->

|**Test Sequence**|**Optional**<br>**Interface**|**Radio**<br>**system(s)**<br>**installed on-**<br>**board**|**Train data set**|
|---|---|---|---|
|Subset-076-6-3_3160200_25_v400_SV30|||Generic|
|Subset-076-6-3_3160200_26_v400_SV30|||Generic|
|Subset-076-6-3_3160200_27_v400_SV30|||Generic|
|Subset-076-6-3_3160200_30_v400_SV30|||Generic|
|Subset-076-6-3_3160200_31_v400_SV30|||Generic|
|Subset-076-6-3_3160200_32_v400_SV30|||Generic|
|Subset-076-6-3_3160200_33_v400_SV30|||Generic|
|Subset-076-6-3_3160200_34_v400_SV30|||Generic|
|Subset-076-6-3_3160300_01_v400_SV30|||Generic|
|Subset-076-6-3_3160300_02_v400_SV30|RIU||Generic|
|Subset-076-6-3_3160400_01_v400_SV30|||Generic|
|Subset-076-6-3_3160400_02_v400_SV30|||Generic|
|Subset-076-6-3_3170200_01_v400_SV30|||Generic|
|Subset-076-6-3_3170200_02_v400_SV30|||Generic|
|Subset-076-6-3_3170200_03_v400_SV30|||Generic|
|Subset-076-6-3_3170200_04_v400_SV30|||Generic|
|Subset-076-6-3_3170200_05_v400_SV30|||Generic|
|Subset-076-6-3_3170200_06_v400_SV30|||Generic|
|Subset-076-6-3_3170200_07_v400_SV30|EUROLOOP||Generic|
|Subset-076-6-3_3170200_08_v400_SV30|||Generic|
|Subset-076-6-3_3170200_09_v400_SV30|RIU||Generic|
|Subset-076-6-3_3170200_10_v400_SV30|Safe consist<br>length<br>information<br>acquired from<br>ERTMS/ETCS<br>external sources||Generic|
|Subset-076-6-3_3170200_11_v400_SV30|||Generic with<br>Safe consist<br>length<br>information|

<!-- end of page 32 -->

|**Test Sequence**|**Optional**<br>**Interface**|**Radio**<br>**system(s)**<br>**installed on-**<br>**board**|**Train data set**|
|---|---|---|---|
|Subset-076-6-3_3170300_02_v400_SV30|EUROLOOP||Generic|
|Subset-076-6-3_3170300_03_v400_SV30|||Generic|
|Subset-076-6-3_3170300_04_v400_SV30|||Generic|
|Subset-076-6-3_3170300_05_v400_SV30|||Generic|
|Subset-076-6-3_3170300_06_v400_SV30|||Generic|
|Subset-076-6-3_3170300_07_v400_SV30|||Generic|
|Subset-076-6-3_3180200_01_v400_SV30|||Generic|
|Subset-076-6-3_3180300_01_v400_SV30|||Generic|
|Subset-076-6-3_3180300_02_v400_SV30|||Generic|
|Subset-076-6-3_3180400_01_v400_SV30|||Generic|
|Subset-076-6-3_3180400_02_v400_SV30|||Generic|
|Subset-076-6-3_3180400_03_v400_SV30||FRMCS+GSM-R|Generic|
|Subset-076-6-3_3180400_04_v400_SV30|||Generic|
|Subset-076-6-3_3180400_05_v400_SV30|||Generic|
|Subset-076-6-3_3180600_01_v400_SV30|||Generic|
|Subset-076-6-3_4040600_01_v400_SV30|||Generic|
|Subset-076-6-3_4040600_02_v400_SV30|||Generic|
|Subset-076-6-3_4040600_03_v400_SV30|||Generic|
|Subset-076-6-3_4040700_01_v400_SV30|||Generic|
|Subset-076-6-3_4040800_01_v400_SV30|||Generic|
|Subset-076-6-3_4040800_02_v400_SV30|||Generic|
|Subset-076-6-3_4040800_03_v400_SV30|||Generic|
|Subset-076-6-3_4040800_04_v400_SV30|||Generic|
|Subset-076-6-3_4040800_05_v400_SV30|||Generic|
|Subset-076-6-3_4041100_02_v400_SV30|||Generic|
|Subset-076-6-3_4041100_05_v400_SV30|||Generic|
|Subset-076-6-3_4041100_06_v400_SV30|||Generic|

<!-- end of page 33 -->

|**Test Sequence**|**Optional**<br>**Interface**|**Radio**<br>**system(s)**<br>**installed on-**<br>**board**|**Train data set**|
|---|---|---|---|
|Subset-076-6-3_4041100_07_v400_SV30|EUROLOOP||Generic|
|Subset-076-6-3_4041100_08_v400_SV30|||Generic|
|Subset-076-6-3_4041100_09_v400_SV30|EUROLOOP||Generic|
|Subset-076-6-3_4041300_01_v400_SV30|||Generic|
|Subset-076-6-3_4041400_01_v400_SV30|||Generic|
|Subset-076-6-3_4041400_02_v400_SV30|||Generic|
|Subset-076-6-3_4041500_01_v400_SV30|||Generic|
|Subset-076-6-3_4041600_01_v400_SV30|||Generic|
|Subset-076-6-3_4041600_02_v400_SV30|||Generic|
|Subset-076-6-3_4041600_03_v400_SV30|||Generic|
|Subset-076-6-3_4041600_04_v400_SV30|||Generic|
|Subset-076-6-3_4041600_05_v400_SV30|||Generic|
|Subset-076-6-3_4041600_06_v400_SV30|||Generic|
|Subset-076-6-3_4041600_07_v400_SV30|||Generic|
|Subset-076-6-3_4041600_08_v400_SV30|||Generic|
|Subset-076-6-3_4041600_09_v400_SV30|||Generic|
|Subset-076-6-3_4041600_10_v400_SV30|||Generic|
|Subset-076-6-3_4041600_11_v400_SV30|||Generic|
|Subset-076-6-3_4041600_12_v400_SV30|||Generic|
|Subset-076-6-3_4041600_13_v400_SV30|||Generic|
|Subset-076-6-3_4041600_14_v400_SV30|||Generic|
|Subset-076-6-3_4041600_15_v400_SV30|||Generic|
|Subset-076-6-3_4041600_16_v400_SV30|||Generic|
|Subset-076-6-3_4041600_17_v400_SV30|||Generic|
|Subset-076-6-3_4041600_18_v400_SV30|||Generic|
|Subset-076-6-3_4041600_19_v400_SV30|||Generic|
|Subset-076-6-3_4041600_20_v400_SV30|||Generic|

<!-- end of page 34 -->

|**Test Sequence**|**Optional**<br>**Interface**|**Radio**<br>**system(s)**<br>**installed on-**<br>**board**|**Train data set**|
|---|---|---|---|
|Subset-076-6-3_4041600_21_v400_SV30|||Generic|
|Subset-076-6-3_4041600_22_v400_SV30|||Generic|
|Subset-076-6-3_4041800_01_v400_SV30|||Generic|
|Subset-076-6-3_4041800_02_v400_SV30|||Generic|
|Subset-076-6-3_4041800_03_v400_SV30|||Generic|
|Subset-076-6-3_4041800_04_v400_SV30|||Generic|
|Subset-076-6-3_4041800_05_v400_SV30|||Generic|
|Subset-076-6-3_4042000_02_v400_SV30|||Generic|
|Subset-076-6-3_4042000_03_v400_SV30|||Generic|
|Subset-076-6-3_4050200_01_v400_SV30|||Generic|
|Subset-076-6-3_4050200_02_v400_SV30|||Generic|
|Subset-076-6-3_4050200_03_v400_SV30|||Generic|
|Subset-076-6-3_4050200_04_v400_SV30|||Generic|
|Subset-076-6-3_4050200_05_v400_SV30|Safe consist<br>length<br>information<br>acquired from<br>ERTMS/ETCS<br>external sources||Generic|
|Subset-076-6-3_4050200_07_v400_SV30|||Generic|
|Subset-076-6-3_4050200_08_v400_SV30|||Generic|
|Subset-076-6-3_4050200_09_v400_SV30|||Generic|
|Subset-076-6-3_4050200_10_v400_SV30|||Generic|
|Subset-076-6-3_4050200_11_v400_SV30|||Generic|
|Subset-076-6-3_4050200_12_v400_SV30|||Generic with<br>Safe consist<br>length<br>information|
|Subset-076-6-3_4060300_01_v400_SV30|||Generic|
|Subset-076-6-3_4060300_02_v400_SV30|||Generic|
|Subset-076-6-3_4060300_03_v400_SV30|||Generic|

<!-- end of page 35 -->

|**Test Sequence**|**Optional**<br>**Interface**|**Radio**<br>**system(s)**<br>**installed on-**<br>**board**|**Train data set**|
|---|---|---|---|
|Subset-076-6-3_4060300_04_v400_SV30|||Generic|
|Subset-076-6-3_4060300_05_v400_SV30|||Generic|
|Subset-076-6-3_4060300_06_v400_SV30|||Generic|
|Subset-076-6-3_4060300_07_v400_SV30|STM||Generic|
|Subset-076-6-3_4060300_08_v400_SV30|||Generic|
|Subset-076-6-3_4060300_09_v400_SV30|||Generic|
|Subset-076-6-3_4060300_10_v400_SV30|||Generic|
|Subset-076-6-3_4060300_11_v400_SV30|||Generic|
|Subset-076-6-3_4060300_12_v400_SV30|||Generic|
|Subset-076-6-3_4060300_13_v400_SV30|||Generic|
|Subset-076-6-3_4060300_14_v400_SV30|Safe consist<br>length<br>information<br>acquired from<br>ERTMS/ETCS<br>external sources||Generic|
|Subset-076-6-3_4070200_01_v400_SV30|||Generic|
|Subset-076-6-3_4070201_01_v400_SV30|||Generic|
|Subset-076-6-3_4070201_02_v400_SV30|Train Data<br>acquired from<br>ERTMS/ETCS<br>external sources||Generic|
|Subset-076-6-3_4070201_03_v400_SV30|||Generic|
|Subset-076-6-3_4070201_04_v400_SV30|||Generic with<br>Safe consist<br>length<br>information|
|Subset-076-6-3_4070201_05_v400_SV30|||Generic with<br>Safe consist<br>length<br>information|
|Subset-076-6-3_4080100_01_v400_SV30|||Generic|
|Subset-076-6-3_4080100_02_v400_SV30|||Generic|

<!-- end of page 36 -->

|**Test Sequence**|**Optional**<br>**Interface**|**Radio**<br>**system(s)**<br>**installed on-**<br>**board**|**Train data set**|
|---|---|---|---|
|Subset-076-6-3_4080100_03_v400_SV30|||Generic|
|Subset-076-6-3_4080100_04_v400_SV30|||Generic|
|Subset-076-6-3_4080100_05_v400_SV30|||Generic|
|Subset-076-6-3_4080100_06_v400_SV30|||Generic|
|Subset-076-6-3_4080300_01_v400_SV30|RIU||Generic|
|Subset-076-6-3_4080300_02_v400_SV30|||Generic|
|Subset-076-6-3_4080300_03_v400_SV30|||Generic|
|Subset-076-6-3_4080300_04_v400_SV30|||Generic|
|Subset-076-6-3_4080300_05_v400_SV30|||Generic|
|Subset-076-6-3_4080300_06_v400_SV30|EUROLOOP||Generic|
|Subset-076-6-3_4080300_07_v400_SV30|||Generic|
|Subset-076-6-3_4080300_08_v400_SV30|||Generic|
|Subset-076-6-3_4080300_09_v400_SV30|||Generic|
|Subset-076-6-3_4080300_10_v400_SV30|||Generic|
|Subset-076-6-3_4080300_11_v400_SV30|STM||Generic|
|Subset-076-6-3_4080300_12_v400_SV30|STM||Generic|
|Subset-076-6-3_4080300_13_v400_SV30|||Generic|
|Subset-076-6-3_4080300_14_v400_SV30|||Generic|
|Subset-076-6-3_4080300_15_v400_SV30|||Generic|
|Subset-076-6-3_4080300_16_v400_SV30|||Generic|
|Subset-076-6-3_4080300_17_v400_SV30|||Generic|
|Subset-076-6-3_4080300_18_v400_SV30|||Generic with<br>Safe consist<br>length<br>information|
|Subset-076-6-3_4080300_19_v400_SV30|||Generic with<br>Safe consist<br>length<br>information|

<!-- end of page 37 -->

|**Test Sequence**|**Optional**<br>**Interface**|**Radio**<br>**system(s)**<br>**installed on-**<br>**board**|**Train data set**|
|---|---|---|---|
|Subset-076-6-3_4080300_20_v400_SV30|||Generic with<br>Safe consist<br>length<br>information|
|Subset-076-6-3_4080300_21_v400_SV30|Safe consist<br>length<br>information<br>acquired from<br>ERTMS/ETCS<br>external sources||Generic|
|Subset-076-6-3_4080300_22_v400_SV30|Safe consist<br>length<br>information<br>acquired from<br>ERTMS/ETCS<br>external sources||Generic|
|Subset-076-6-3_4080402_01_v400_SV30|||Generic|
|Subset-076-6-3_4080403_01_v400_SV30|||Generic|
|Subset-076-6-3_4080403_02_v400_SV30|STM||Generic|
|Subset-076-6-3_4080404_01_v400_SV30|||Generic|
|Subset-076-6-3_4080404_02_v400_SV30|RIU||Generic|
|Subset-076-6-3_4080405_01_v400_SV30|||Generic|
|Subset-076-6-3_4080406_01_v400_SV30|||Generic|
|Subset-076-6-3_4080406_02_v400_SV30|RIU||Generic|
|Subset-076-6-3_4080407_01_v400_SV30|||Generic|
|Subset-076-6-3_4080408_01_v400_SV30|||Generic|
|Subset-076-6-3_4080409_01_v400_SV30|||Generic|
|Subset-076-6-3_4080410_01_v400_SV30|||Generic|
|Subset-076-6-3_4080410_02_v400_SV30|||Generic|
|Subset-076-6-3_4080410_03_v400_SV30|STM||Generic|
|Subset-076-6-3_4080413_01_v400_SV30|||Generic|
|Subset-076-6-3_4080413_02_v400_SV30|||Generic|
|Subset-076-6-3_4080414_01_v400_SV30|||Generic|

<!-- end of page 38 -->

|**Test Sequence**|**Optional**<br>**Interface**|**Radio**<br>**system(s)**<br>**installed on-**<br>**board**|**Train data set**|
|---|---|---|---|
|Subset-076-6-3_4080414_02_v400_SV30|STM||Generic|
|Subset-076-6-3_4080415_01_v400_SV30|||Generic|
|Subset-076-6-3_4080415_02_v400_SV30|STM||Generic|
|Subset-076-6-3_4080415_03_v400_SV30|||Generic with<br>Safe consist<br>length<br>information|
|Subset-076-6-3_4080416_01_v400_SV30|||Generic|
|Subset-076-6-3_4080416_02_v400_SV30|RIU||Generic|
|Subset-076-6-3_4080417_01_v400_SV30|||Generic|
|Subset-076-6-3_4080418_01_v400_SV30|||Generic|
|Subset-076-6-3_4080418_03_v400_SV30|EUROLOOP||Generic|
|Subset-076-6-3_4080418_04_v400_SV30|Safe consist<br>length<br>information<br>acquired from<br>ERTMS/ETCS<br>external sources||Generic with<br>Safe consist<br>length<br>information|
|Subset-076-6-3_4080419_01_v400_SV30|||Generic|
|Subset-076-6-3_4080419_02_v400_SV30|STM||Generic|
|Subset-076-6-3_4080420_01_v400_SV30|||Generic|
|Subset-076-6-3_4080420_02_v400_SV30|EUROLOOP||Generic|
|Subset-076-6-3_4080420_03_v400_SV30|Safe consist<br>length<br>information<br>acquired from<br>ERTMS/ETCS<br>external sources||Generic with<br>Safe consist<br>length<br>information|
|Subset-076-6-3_4080421_01_v400_SV30|||Generic|
|Subset-076-6-3_4080421_02_v400_SV30|||Generic|
|Subset-076-6-3_4080421_03_v400_SV30|||Generic|
|Subset-076-6-3_4080423_01_v400_SV30|||Generic|
|Subset-076-6-3_4080424_01_v400_SV30|||Generic|

<!-- end of page 39 -->

|**Test Sequence**|**Optional**<br>**Interface**|**Radio**<br>**system(s)**<br>**installed on-**<br>**board**|**Train data set**|
|---|---|---|---|
|Subset-076-6-3_4080424_02_v400_SV30|EUROLOOP||Generic|
|Subset-076-6-3_4080425_01_v400_SV30|||Generic|
|Subset-076-6-3_4080425_02_v400_SV30|RIU||Generic|
|Subset-076-6-3_4080425_03_v400_SV30|EUROLOOP||Generic|
|Subset-076-6-3_4080425_04_v400_SV30|||Generic|
|Subset-076-6-3_4080426_01_v400_SV30|||Generic|
|Subset-076-6-3_4080427_01_v400_SV30|||Generic|
|Subset-076-6-3_4080428_01_v400_SV30|||Generic|
|Subset-076-6-3_4080428_02_v400_SV30|||Generic with<br>Safe consist<br>length<br>information|
|Subset-076-6-3_4080429_01_v400_SV30|RIU||Generic|
|Subset-076-6-3_4080430_01_v400_SV30|||Generic|
|Subset-076-6-3_4080430_02_v400_SV30|||Generic with<br>Safe consist<br>length<br>information|
|Subset-076-6-3_4080431_01_v400_SV30|||Generic|
|Subset-076-6-3_4080431_02_v400_SV30|Safe consist<br>length<br>information<br>acquired from<br>ERTMS/ETCS<br>external sources||Generic with<br>Safe consist<br>length<br>information|
|Subset-076-6-3_4080432_01_v400_SV30|||Generic|
|Subset-076-6-3_4080433_01_v400_SV30|||Generic|
|Subset-076-6-3_4080434_01_v400_SV30|||Generic|
|Subset-076-6-3_4080435_01_v400_SV30|||Generic|
|Subset-076-6-3_4080436_01_v400_SV30|||Generic|

<!-- end of page 40 -->

|**Test Sequence**|**Optional**<br>**Interface**|**Radio**<br>**system(s)**<br>**installed on-**<br>**board**|**Train data set**|
|---|---|---|---|
|Subset-076-6-3_4080436_02_v400_SV30|Safe consist<br>length<br>information<br>acquired from<br>ERTMS/ETCS<br>external sources||Generic with<br>safe consist<br>length<br>information|
|Subset-076-6-3_4080436_03_v400_SV30|||Generic|
|Subset-076-6-3_4080437_01_v400_SV30|||Generic|
|Subset-076-6-3_4080438_01_v400_SV30|||Generic|
|Subset-076-6-3_4080440_01_v400_SV30|||Generic|
|Subset-076-6-3_4080440_02_v400_SV30|EUROLOOP||Generic|
|Subset-076-6-3_4080440_03_v400_SV30|STM||Generic|
|Subset-076-6-3_4080440_04_v400_SV30|Safe consist<br>length<br>information<br>acquired from<br>ERTMS/ETCS<br>external sources||Generic with<br>Safe consist<br>length<br>information|
|Subset-076-6-3_4080441_01_v400_SV30|||Generic|
|Subset-076-6-3_4080441_02_v400_SV30|Safe consist<br>length<br>information<br>acquired from<br>ERTMS/ETCS<br>external sources||Generic with<br>Safe consist<br>length<br>information|
|Subset-076-6-3_4080442_01_v400_SV30|||Generic|
|Subset-076-6-3_4080443_01_v400_SV30|||Generic|
|Subset-076-6-3_4080444_01_v400_SV30|||Generic|
|Subset-076-6-3_4080444_02_v400_SV30|||Generic with<br>safe consist<br>length<br>information|
|Subset-076-6-3_4080444_03_v400_SV30|||Generic|
|Subset-076-6-3_4080445_01_v400_SV30|||Generic|
|Subset-076-6-3_4080445_02_v400_SV30|||Generic|

<!-- end of page 41 -->

|**Test Sequence**|**Optional**<br>**Interface**|**Radio**<br>**system(s)**<br>**installed on-**<br>**board**|**Train data set**|
|---|---|---|---|
|Subset-076-6-3_4080445_03_v400_SV30|EUROLOOP||Generic|
|Subset-076-6-3_4080445_04_v400_SV30|RIU||Generic|
|Subset-076-6-3_4080445_05_v400_SV30|Safe consist<br>length<br>information<br>acquired from<br>ERTMS/ETCS<br>external sources||Generic with<br>Safe consist<br>length<br>information|
|Subset-076-6-3_4080446_01_v400_SV30|||Generic|
|Subset-076-6-3_4080446_02_v400_SV30|||Generic with<br>Safe consist<br>length<br>information|
|Subset-076-6-3_4080447_01_v400_SV30|||Generic|
|Subset-076-6-3_4080450_01_v400_SV30|||Generic|
|Subset-076-6-3_4080451_01_v400_SV30|||Generic|
|Subset-076-6-3_4080453_01_v400_SV30|||Generic|
|Subset-076-6-3_4080454_01_v400_SV30|||Generic|
|Subset-076-6-3_4080454_02_v400_SV30|||Generic|
|Subset-076-6-3_4080454_03_v400_SV30|EUROLOOP||Generic|
|Subset-076-6-3_4080454_04_v400_SV30|RIU||Generic|
|Subset-076-6-3_4080454_05_v400_SV30|||Generic with<br>Safe consist<br>length<br>information|
|Subset-076-6-3_4080455_01_v400_SV30|||Generic with<br>Safe consist<br>length<br>information|
|Subset-076-6-3_4080455_02_v400_SV30|Safe consist<br>length<br>information<br>acquired from<br>ERTMS/ETCS<br>external sources||Generic with<br>Safe consist<br>length<br>information|

<!-- end of page 42 -->

|**Test Sequence**|**Optional**<br>**Interface**|**Radio**<br>**system(s)**<br>**installed on-**<br>**board**|**Train data set**|
|---|---|---|---|
|Subset-076-6-3_4080455_03_v400_SV30|||Generic with<br>Safe consist<br>length<br>information|
|Subset-076-6-3_4080455_04_v400_SV30|||Generic with<br>Safe consist<br>length<br>information|
|Subset-076-6-3_4080455_05_v400_SV30|||Generic with<br>Safe consist<br>length<br>information|
|Subset-076-6-3_4080455_06_v400_SV30|||Generic with<br>Safe consist<br>length<br>information|
|Subset-076-6-3_4080455_07_v400_SV30|||Generic with<br>Safe consist<br>length<br>information|
|Subset-076-6-3_4080455_08_v400_SV30|||Generic with<br>Safe consist<br>length<br>information|
|Subset-076-6-3_4080500_01_v400_SV30|||Generic|
|Subset-076-6-3_4080500_02_v400_SV30|||Generic|
|Subset-076-6-3_4080500_03_v400_SV30|||Generic|
|Subset-076-6-3_4090100_01_v400_SV30|||Generic|
|Subset-076-6-3_4100103_01_v400_SV30|RIU||Generic|
|Subset-076-6-3_4100103_02_v400_SV30|||Generic|
|Subset-076-6-3_4100103_03_v400_SV30|||Generic|
|Subset-076-6-3_4100103_04_v400_SV30|||Generic|
|Subset-076-6-3_4100103_05_v400_SV30|||Generic|
|Subset-076-6-3_4100103_06_v400_SV30<br>Subset-076-6-3_4100103_07_v400_SV30|||Generic<br>Generic|

<!-- end of page 43 -->

|**Test Sequence**|**Optional**<br>**Interface**|**Radio**<br>**system(s)**<br>**installed on-**<br>**board**|**Train data set**|
|---|---|---|---|
|Subset-076-6-3_4100103_08_v400_SV30|||Generic|
|Subset-076-6-3_4100103_09_v400_SV30|||Generic|
|Subset-076-6-3_4100103_10_v400_SV30|EUROLOOP||Generic|
|Subset-076-6-3_4100103_11_v400_SV30|||Generic|
|Subset-076-6-3_4100103_12_v400_SV30|||Generic|
|Subset-076-6-3_4100103_13_v400_SV30|||Generic|
|Subset-076-6-3_4100103_14_v400_SV30|||Generic|
|Subset-076-6-3_4100103_15_v400_SV30|||Generic|
|Subset-076-6-3_4100103_16_v400_SV30|||Generic|
|Subset-076-6-3_4100103_17_v400_SV30|||Gamma 1|
|Subset-076-6-3_4100103_18_v400_SV30|||Generic|
|Subset-076-6-3_4100103_19_v400_SV30|||Generic|
|Subset-076-6-3_4100103_20_v400_SV30|||Generic|
|Subset-076-6-3_4100103_21_v400_SV30|||Generic|
|Subset-076-6-3_4100103_22_v400_SV30|||Generic|
|Subset-076-6-3_4100103_23_v400_SV30|||Generic|
|Subset-076-6-3_4100103_24_v400_SV30|||Generic|
|Subset-076-6-3_4100103_25_v400_SV30|||Generic|
|Subset-076-6-3_4100103_26_v400_SV30|||Generic|
|Subset-076-6-3_4100103_27_v400_SV30|||Generic|
|Subset-076-6-3_4100103_28_v400_SV30|||Generic|
|Subset-076-6-3_4100103_29_v400_SV30|||Generic|
|Subset-076-6-3_4100103_30_v400_SV30|||Generic|
|Subset-076-6-3_4100103_31_v400_SV30|||Generic|
|Subset-076-6-3_4100103_32_v400_SV30|||Generic|
|Subset-076-6-3_4100103_33_v400_SV30|||Generic|
|Subset-076-6-3_4100103_34_v400_SV30|||Generic|

<!-- end of page 44 -->

|**Test Sequence**|**Optional**<br>**Interface**|**Radio**<br>**system(s)**<br>**installed on-**<br>**board**|**Train data set**|
|---|---|---|---|
|Subset-076-6-3_4100103_35_v400_SV30|||Generic|
|Subset-076-6-3_4100103_36_v400_SV30|||Generic|
|Subset-076-6-3_4100103_37_v400_SV30|||Generic|
|Subset-076-6-3_4100103_38_v400_SV30|||Generic|
|Subset-076-6-3_4100103_39_v400_SV30|||Generic|
|Subset-076-6-3_4100103_40_v400_SV30|||Generic|
|Subset-076-6-3_4100103_41_v400_SV30|||Generic|
|Subset-076-6-3_4100103_42_v400_SV30|||Generic|
|Subset-076-6-3_4100103_43_v400_SV30|||Generic|
|Subset-076-6-3_4100103_44_v400_SV30|||Generic|
|Subset-076-6-3_4100103_45_v400_SV30|||Generic|
|Subset-076-6-3_4100103_46_v400_SV30|||Generic|
|Subset-076-6-3_4100103_47_v400_SV30|||Generic|
|Subset-076-6-3_4100103_48_v400_SV30|||Generic with<br>Safe consist<br>length<br>information|
|Subset-076-6-3_4100103_49_v400_SV30|||Generic with<br>Safe consist<br>length<br>information|
|Subset-076-6-3_4120100_01_v400_SV30|||Generic|
|Subset-076-6-3_4120100_02_v400_SV30|||Generic|
|Subset-076-6-3_4120100_03_v400_SV30|||Generic|
|Subset-076-6-3_4120100_04_v400_SV30|||Generic|
|Subset-076-6-3_4120100_05_v400_SV30|||Generic|
|Subset-076-6-3_4120100_06_v400_SV30|||Generic|
|Subset-076-6-3_4120100_07_v400_SV30|||Generic|
|Subset-076-6-3_4120100_08_v400_SV30|||Generic|
|Subset-076-6-3_4120100_09_v400_SV30|||Generic|

<!-- end of page 45 -->

|**Test Sequence**|**Optional**<br>**Interface**|**Radio**<br>**system(s)**<br>**installed on-**<br>**board**|**Train data set**|
|---|---|---|---|
|Subset-076-6-3_4120100_10_v400_SV30|||Generic|
|Subset-076-6-3_4120100_11_v400_SV30|||Generic|
|Subset-076-6-3_4120100_12_v400_SV30|Train Data<br>acquired from<br>ERTMS/ETCS<br>external sources||Generic|
|Subset-076-6-3_4120100_13_v400_SV30|||Generic|
|Subset-076-6-3_4120100_14_v400_SV30|Safe consist<br>length<br>information<br>acquired from<br>ERTMS/ETCS<br>external sources||Generic|
|Subset-076-6-3_4120100_15_v400_SV30|||Generic|
|Subset-076-6-3_4120100_16_v400_SV30|||Generic|
|Subset-076-6-3_4120100_17_v400_SV30|||Generic with<br>Safe consist<br>length<br>information|
|Subset-076-6-3_4120100_18_v400_SV30|STM||Generic|
|Subset-076-6-3_5030100_01_v400_SV30|||Generic|
|Subset-076-6-3_5040300_01_v400_SV30|||Generic|
|Subset-076-6-3_5040300_02_v400_SV30|||Generic|
|Subset-076-6-3_5040300_03_v400_SV30|||Generic|
|Subset-076-6-3_5040300_04_v400_SV30|||Generic|
|Subset-076-6-3_5040300_05_v400_SV30|||Generic|
|Subset-076-6-3_5040300_06_v400_SV30|||Generic|
|Subset-076-6-3_5040300_07_v400_SV30|||Generic|
|Subset-076-6-3_5040300_08_v400_SV30||FRMCS+GSM-R|Generic|
|Subset-076-6-3_5040300_09_v400_SV30|||Generic|
|Subset-076-6-3_5040300_10_v400_SV30|||Generic|
|Subset-076-6-3_5040300_11_v400_SV30||FRMCS+GSM-R|Generic|

<!-- end of page 46 -->

|**Test Sequence**|**Optional**<br>**Interface**|**Radio**<br>**system(s)**<br>**installed on-**<br>**board**|**Train data set**|
|---|---|---|---|
|Subset-076-6-3_5040300_12_v400_SV30|||Generic|
|Subset-076-6-3_5040300_13_v400_SV30||FRMCS+GSM-R|Generic|
|Subset-076-6-3_5040300_14_v400_SV30|||Generic|
|Subset-076-6-3_5040300_15_v400_SV30|||Generic|
|Subset-076-6-3_5040300_16_v400_SV30|||Generic|
|Subset-076-6-3_5040300_17_v400_SV30|||Generic|
|Subset-076-6-3_5040300_18_v400_SV30|||Generic|
|Subset-076-6-3_5040300_19_v400_SV30|||Generic|
|Subset-076-6-3_5040300_20_v400_SV30|||Generic|
|Subset-076-6-3_5040300_21_v400_SV30|||Generic|
|Subset-076-6-3_5040300_22_v400_SV30|||Generic with<br>Safe consist<br>length<br>information|
|Subset-076-6-3_5040300_23_v400_SV30||FRMCS+GSM-R|Generic|
|Subset-076-6-3_5040300_24_v400_SV30||FRMCS+GSM-R|Generic|
|Subset-076-6-3_5040300_25_v400_SV30||FRMCS+GSM-R|Generic|
|Subset-076-6-3_5040500_01_v400_SV30|||Generic|
|Subset-076-6-3_5040500_02_v400_SV30|||Generic|
|Subset-076-6-3_5040500_03_v400_SV30|||Generic|
|Subset-076-6-3_5040500_04_v400_SV30|STM||Generic|
|Subset-076-6-3_5040500_05_v400_SV30|||Generic|
|Subset-076-6-3_5040500_06_v400_SV30|||Generic with<br>Safe consist<br>length<br>information|
|Subset-076-6-3_5050300_01_v400_SV30|RIU||Generic|
|Subset-076-6-3_5050400_01_v400_SV30|||Generic|
|Subset-076-6-3_5050400_02_v400_SV30|||Generic|
|Subset-076-6-3_5060200_01_v400_SV30|||Generic|

<!-- end of page 47 -->

|**Test Sequence**|**Optional**<br>**Interface**|**Radio**<br>**system(s)**<br>**installed on-**<br>**board**|**Train data set**|
|---|---|---|---|
|Subset-076-6-3_5060200_02_v400_SV30|||Generic|
|Subset-076-6-3_5060200_03_v400_SV30|||Generic|
|Subset-076-6-3_5060200_04_v400_SV30|||Generic|
|Subset-076-6-3_5060200_05_v400_SV30|||Generic|
|Subset-076-6-3_5060400_01_v400_SV30|||Generic|
|Subset-076-6-3_5070300_01_v400_SV30|||Generic|
|Subset-076-6-3_5070300_02_v400_SV30|||Generic|
|Subset-076-6-3_5070300_03_v400_SV30|||Generic|
|Subset-076-6-3_5070300_04_v400_SV30|||Generic|
|Subset-076-6-3_5070300_05_v400_SV30|||Generic|
|Subset-076-6-3_5080200_01_v400_SV30|||Generic|
|Subset-076-6-3_5080200_02_v400_SV30|||Generic|
|Subset-076-6-3_5080200_03_v400_SV30|||Generic|
|Subset-076-6-3_5080200_04_v400_SV30|||Generic|
|Subset-076-6-3_5080200_05_v400_SV30|||Generic|
|Subset-076-6-3_5080300_01_v400_SV30|||Generic|
|Subset-076-6-3_5080300_02_v400_SV30|STM||Generic|
|Subset-076-6-3_5080300_03_v400_SV30|EUROLOOP||Generic|
|Subset-076-6-3_5080300_04_v400_SV30|STM||Generic|
|Subset-076-6-3_5080300_05_v400_SV30|STM||Generic|
|Subset-076-6-3_5080300_06_v400_SV30|||Generic|
|Subset-076-6-3_5080300_07_v400_SV30|||Generic|
|Subset-076-6-3_5080400_01_v400_SV30|||Generic|
|Subset-076-6-3_5080400_02_v400_SV30|||Generic|
|Subset-076-6-3_5080400_03_v400_SV30|||Generic|
|Subset-076-6-3_5080400_04_v400_SV30|||Generic|
|Subset-076-6-3_5080400_05_v400_SV30|||Generic|

<!-- end of page 48 -->

|**Test Sequence**|**Optional**<br>**Interface**|**Radio**<br>**system(s)**<br>**installed on-**<br>**board**|**Train data set**|
|---|---|---|---|
|Subset-076-6-3_5080400_06_v400_SV30|||Generic|
|Subset-076-6-3_5080400_07_v400_SV30|||Generic|
|Subset-076-6-3_5080400_08_v400_SV30|||Generic|
|Subset-076-6-3_5080400_09_v400_SV30|||Generic|
|Subset-076-6-3_5080400_10_v400_SV30|||Generic|
|Subset-076-6-3_5080400_11_v400_SV30|||Generic|
|Subset-076-6-3_5080400_12_v400_SV30|||Generic|
|Subset-076-6-3_5090200_01_v400_SV30|||Generic|
|Subset-076-6-3_5090200_02_v400_SV30|||Generic|
|Subset-076-6-3_5090200_03_v400_SV30|||Generic|
|Subset-076-6-3_5090200_04_v400_SV30|||Generic|
|Subset-076-6-3_5090300_01_v400_SV30|||Generic|
|Subset-076-6-3_5090400_01_v400_SV30|||Generic|
|Subset-076-6-3_5100100_01_v400_SV30|STM||Generic|
|Subset-076-6-3_5100100_02_v400_SV30|||Generic|
|Subset-076-6-3_5100100_04_v400_SV30|STM||Generic|
|Subset-076-6-3_5100100_05_v400_SV30|STM||Generic|
|Subset-076-6-3_5100100_06_v400_SV30|||Generic|
|Subset-076-6-3_5100200_01_v400_SV30|||Generic|
|Subset-076-6-3_5100200_03_v400_SV30|||Generic|
|Subset-076-6-3_5100200_04_v400_SV30|STM||Generic|
|Subset-076-6-3_5100200_05_v400_SV30|STM||Generic|
|Subset-076-6-3_5100200_06_v400_SV30|||Generic|
|Subset-076-6-3_5100200_07_v400_SV30|||Generic|
|Subset-076-6-3_5100200_08_v400_SV30|||Generic|
|Subset-076-6-3_5100200_09_v400_SV30|||Generic|
|Subset-076-6-3_5100200_10_v400_SV30|||Generic|

<!-- end of page 49 -->

|**Test Sequence**|**Optional**<br>**Interface**|**Radio**<br>**system(s)**<br>**installed on-**<br>**board**|**Train data set**|
|---|---|---|---|
|Subset-076-6-3_5100200_11_v400_SV30|||Generic|
|Subset-076-6-3_5100200_12_v400_SV30|||Generic|
|Subset-076-6-3_5100300_01_v400_SV30|||Generic|
|Subset-076-6-3_5100300_02_v400_SV30|||Generic|
|Subset-076-6-3_5100300_03_v400_SV30|||Generic|
|Subset-076-6-3_5100300_04_v400_SV30|||Generic|
|Subset-076-6-3_5100300_07_v400_SV30|||Generic|
|Subset-076-6-3_5100300_08_v400_SV30|||Generic|
|Subset-076-6-3_5100300_09_v400_SV30|||Generic|
|Subset-076-6-3_5100300_10_v400_SV30|||Generic|
|Subset-076-6-3_5100300_11_v400_SV30|||Generic|
|Subset-076-6-3_5100315_01_v400_SV30|||Generic|
|Subset-076-6-3_5100315_02_v400_SV30|||Generic|
|Subset-076-6-3_5100400_01_v400_SV30|||Generic|
|Subset-076-6-3_5100400_02_v400_SV30|STM||Generic|
|Subset-076-6-3_5100400_03_v400_SV30|STM||Generic|
|Subset-076-6-3_5100400_04_v400_SV30|STM||Generic|
|Subset-076-6-3_5100400_05_v400_SV30|STM||Generic|
|Subset-076-6-3_5100400_06_v400_SV30|||Generic|
|Subset-076-6-3_5100400_08_v400_SV30|||Generic|
|Subset-076-6-3_5100400_09_v400_SV30|||Generic|
|Subset-076-6-3_5100400_10_v400_SV30|STM||Generic|
|Subset-076-6-3_5110200_01_v400_SV30|||Generic|
|Subset-076-6-3_5110200_02_v400_SV30|||Generic with<br>Safe consist<br>length<br>information|
|Subset-076-6-3_5110200_03_v400_SV30|||Generic|

<!-- end of page 50 -->

|**Test Sequence**|**Optional**<br>**Interface**|**Radio**<br>**system(s)**<br>**installed on-**<br>**board**|**Train data set**|
|---|---|---|---|
|Subset-076-6-3_5110200_04_v400_SV30|||Generic with<br>Safe consist<br>length<br>information|
|Subset-076-6-3_5110400_01_v400_SV30|||Generic|
|Subset-076-6-3_5110400_02_v400_SV30|||Generic|
|Subset-076-6-3_5120200_01_v400_SV30|||Generic|
|Subset-076-6-3_5120400_01_v400_SV30|||Generic|
|Subset-076-6-3_5150400_02_v400_SV30|||Generic|
|Subset-076-6-3_5160000_01_v400_SV30|||Generic|
|Subset-076-6-3_5160000_02_v400_SV30|||Generic|
|Subset-076-6-3_5160000_03_v400_SV30|||Generic|
|Subset-076-6-3_5160000_04_v400_SV30|||Generic|
|Subset-076-6-3_5160000_05_v400_SV30|||Generic|
|Subset-076-6-3_5160000_06_v400_SV30|||Generic with<br>Safe consist<br>length<br>information|
|Subset-076-6-3_5170200_01_v400_SV30|Train Data<br>acquired from<br>ERTMS/ETCS<br>external sources||Generic|
|Subset-076-6-3_5170200_02_v400_SV30|Train Data<br>acquired from<br>ERTMS/ETCS<br>external sources||Generic|
|Subset-076-6-3_5170200_03_v400_SV30|Train Data<br>acquired from<br>ERTMS/ETCS<br>external sources||Generic|
|Subset-076-6-3_5170200_04_v400_SV30|Train Data<br>acquired from<br>ERTMS/ETCS<br>external sources||Generic|

<!-- end of page 51 -->

|**Test Sequence**|**Optional**<br>**Interface**|**Radio**<br>**system(s)**<br>**installed on-**<br>**board**|**Train data set**|
|---|---|---|---|
|Subset-076-6-3_5170200_05_v400_SV30|Train Data<br>acquired from<br>ERTMS/ETCS<br>external sources||Generic|
|Subset-076-6-3_5180200_01_v400_SV30|||Generic|
|Subset-076-6-3_5180200_02_v400_SV30|||Generic|
|Subset-076-6-3_5180200_03_v400_SV30|||Gamma 1|
|Subset-076-6-3_5180200_04_v400_SV30|||Gamma 1|
|Subset-076-6-3_5180300_01_v400_SV30|||Generic|
|Subset-076-6-3_5180300_02_v400_SV30|||Generic|
|Subset-076-6-3_5180300_03_v400_SV30|||Gamma 1|
|Subset-076-6-3_5180300_04_v400_SV30|||Gamma 1|
|Subset-076-6-3_5180400_01_v400_SV30|||Generic|
|Subset-076-6-3_5180400_02_v400_SV30|||Generic|
|Subset-076-6-3_5180500_01_v400_SV30|||Generic|
|Subset-076-6-3_5180500_02_v400_SV30|||Generic|
|Subset-076-6-3_5180500_03_v400_SV30|||Generic|
|Subset-076-6-3_5180500_04_v400_SV30|||Generic|
|Subset-076-6-3_5180500_05_v400_SV30|||Generic with<br>Safe consist<br>length<br>information|
|Subset-076-6-3_5180600_01_v400_SV30|||Generic|
|Subset-076-6-3_5180600_02_v400_SV30|||Generic|
|Subset-076-6-3_5180600_03_v400_SV30|||Gamma 1|
|Subset-076-6-3_5180600_04_v400_SV30|||Gamma 1|
|Subset-076-6-3_5180600_05_v400_SV30|||Generic|
|Subset-076-6-3_5180700_01_v400_SV30|||Generic|
|Subset-076-6-3_5180700_02_v400_SV30|||Generic|
|Subset-076-6-3_5180700_03_v400_SV30|||Generic|

<!-- end of page 52 -->

|**Test Sequence**|**Optional**<br>**Interface**|**Radio**<br>**system(s)**<br>**installed on-**<br>**board**|**Train data set**|
|---|---|---|---|
|Subset-076-6-3_5180700_04_v400_SV30|||Generic|
|Subset-076-6-3_5180700_05_v400_SV30|||Gamma 1|
|Subset-076-6-3_5180700_06_v400_SV30|||Gamma 1|
|Subset-076-6-3_5180700_07_v400_SV30|||Gamma 1|
|Subset-076-6-3_5180700_08_v400_SV30|||Gamma 1|
|Subset-076-6-3_5180800_01_v400_SV30|||Generic|
|Subset-076-6-3_5180900_01_v400_SV30|||Generic|
|Subset-076-6-3_5181000_01_v400_SV30|||Generic|
|Subset-076-6-3_5181000_02_v400_SV30|||Generic|
|Subset-076-6-3_5181000_03_v400_SV30|||Gamma 1|
|Subset-076-6-3_5190200_01_v400_SV30|||Generic|
|Subset-076-6-3_5190200_02_v400_SV30|||Generic|
|Subset-076-6-3_5190200_03_v400_SV30|||Generic|
|Subset-076-6-3_5190200_04_v400_SV30|||Generic|
|Subset-076-6-3_5190200_05_v400_SV30|||Generic|
|Subset-076-6-3_5190200_06_v400_SV30|||Generic|
|Subset-076-6-3_5190200_07_v400_SV30|||Generic|
|Subset-076-6-3_5190300_01_v400_SV30|||Generic|
|Subset-076-6-3_5190300_02_v400_SV30|||Generic|
|Subset-076-6-3_5190300_03_v400_SV30|||Generic|
|Subset-076-6-3_5190400_01_v400_SV30|||Generic|
|Subset-076-6-3_5200800_01_v400_SV30|||Generic|
|Subset-076-6-3_5200800_02_v400_SV30|||Generic|
|Subset-076-6-3_5210200_01_v400_SV30|||Generic with<br>Safe consist<br>length<br>information|

<!-- end of page 53 -->

|**Test Sequence**|**Optional**<br>**Interface**|**Radio**<br>**system(s)**<br>**installed on-**<br>**board**|**Train data set**|
|---|---|---|---|
|Subset-076-6-3_5210200_02_v400_SV30|||Generic with<br>Safe consist<br>length<br>information|
|Subset-076-6-3_5210200_03_v400_SV30|||Generic with<br>Safe consist<br>length<br>information|
|Subset-076-6-3_5210400_01_v400_SV30|||Generic with<br>Safe consist<br>length<br>information|
|Subset-076-6-3_5220200_01_v400_SV30|||Generic|
|Subset-076-6-3_5220200_02_v400_SV30|||Generic|
|Subset-076-6-3_5220200_03_v400_SV30|||Generic|
|Subset-076-6-3_5220200_04_v400_SV30|||Generic|
|Subset-076-6-3_5220200_05_v400_SV30|||Generic|
|Subset-076-6-3_5220200_06_v400_SV30|||Generic|
|Subset-076-6-3_6060200_01_v400_SV30|||Generic|
|Subset-076-6-3_6060200_02_v400_SV30|||Generic|
|Subset-076-6-3_6060200_03_v400_SV30|||Generic|
|Subset-076-6-3_6060200_04_v400_SV30|||Generic|
|Subset-076-6-3_6060200_05_v400_SV30|||Generic|
|Subset-076-6-3_6060200_06_v400_SV30|||Generic|
|Subset-076-6-3_6060200_07_v400_SV30|||Generic|
|Subset-076-6-3_6060302_01_v400_SV30|||Generic|
|Subset-076-6-3_6060302_02_v400_SV30|||Gamma 1|
|Subset-076-6-3_6060302_03_v400_SV30|EUROLOOP||Generic|
|Subset-076-6-3_6060302_04_v400_SV30|||Generic|
|Subset-076-6-3_6060302_05_v400_SV30|||Generic|
|Subset-076-6-3_6060302_06_v400_SV30|||Gamma 1|

<!-- end of page 54 -->

|**Test Sequence**|**Optional**<br>**Interface**|**Radio**<br>**system(s)**<br>**installed on-**<br>**board**|**Train data set**|
|---|---|---|---|
|Subset-076-6-3_6060302_07_v400_SV30|||Generic|
|Subset-076-6-3_6060302_08_v400_SV30|||Generic|
|Subset-076-6-3_6060302_09_v400_SV30|||Generic|
|Subset-076-6-3_6060302_10_v400_SV30|||Generic|
|Subset-076-6-3_6060302_11_v400_SV30|||Generic|
|Subset-076-6-3_6060302_12_v400_SV30|||Generic|
|Subset-076-6-3_6060302_13_v400_SV30|||Generic|
|Subset-076-6-3_6060303_01_v400_SV30|||Generic|
|Subset-076-6-3_6060303_02_v400_SV30|||Generic|
|Subset-076-6-3_6060304_01_v400_SV30|||Generic|
|Subset-076-6-3_6060304_02_v400_SV30|||Generic|
|Subset-076-6-3_6060304_03_v400_SV30|||Generic|
|Subset-076-6-3_6060304_04_v400_SV30|||Generic with<br>Safe consist<br>length<br>information|
|Subset-076-6-3_6060304_05_v400_SV30|||Generic|
|Subset-076-6-3_6060304_06_v400_SV30|Safe consist<br>length<br>information<br>acquired from<br>ERTMS/ETCS<br>external sources||Generic with<br>Safe consist<br>length<br>information|
|Subset-076-6-3_6060304_07_v400_SV30|||Generic|
|Subset-076-6-3_6060400_02_v400_SV30|||Generic|
|Subset-076-6-3_6060400_03_v400_SV30|||Generic|
|Subset-076-6-3_6060400_04_v400_SV30|||Generic|
|Subset-076-6-3_6060400_05_v400_SV30|||Generic|
|Subset-076-6-3_6060400_06_v400_SV30|||Generic|
|Subset-076-6-3_6060400_07_v400_SV30|||Generic|
|Subset-076-6-3_6060400_08_v400_SV30|||Generic|

<!-- end of page 55 -->

|**Test Sequence**|**Optional**<br>**Interface**|**Radio**<br>**system(s)**<br>**installed on-**<br>**board**|**Train data set**|
|---|---|---|---|
|Subset-076-6-3_6060500_01_v400_SV30|||Generic|
|Subset-076-6-3_6060500_02_v400_SV30|||Generic|
|Subset-076-6-3_6060500_03_v400_SV30|EUROLOOP||Generic|
|Subset-076-6-3_6060500_04_v400_SV30|||Generic|
|Subset-076-6-3_6060500_05_v400_SV30|||Generic|
|Subset-076-6-3_6060500_06_v400_SV30|||Generic|
|Subset-076-6-3_6060500_07_v400_SV30|||Generic|
|Subset-076-6-3_6060500_08_v400_SV30|||Generic|
|Subset-076-6-3_6060500_09_v400_SV30|||Generic|
|Subset-076-6-3_6060500_10_v400_SV30|||Generic with<br>Safe consist<br>length<br>information|
|Subset-076-6-3_6060500_11_v400_SV30|Safe consist<br>length<br>information<br>acquired from<br>ERTMS/ETCS<br>external sources||Generic with<br>Safe consist<br>length<br>information|
|Subset-076-6-3_6060500_12_v400_SV30|||Generic with<br>Safe consist<br>length<br>information|
|Subset-076-6-3_6060500_13_v400_SV30|||Generic|
|Subset-076-6-3_6060500_14_v400_SV30|||Generic|
|Subset-076-6-3_6060500_15_v400_SV30|||Generic|
|Subset-076-6-3_6060500_16_v400_SV30|||Generic|
|Subset-076-6-3_6060500_17_v400_SV30|||Generic|
|Subset-076-6-3_6060504_01_v400_SV30|||Generic|
|Subset-076-6-3_6060504_02_v400_SV30|||Generic with<br>Safe consist<br>length<br>information|

<!-- end of page 56 -->

|**Test Sequence**|**Optional**<br>**Interface**|**Radio**<br>**system(s)**<br>**installed on-**<br>**board**|**Train data set**|
|---|---|---|---|
|Subset-076-6-3_6060504_03_v400_SV30|Safe consist<br>length<br>information<br>acquired from<br>ERTMS/ETCS<br>external sources||Generic with<br>Safe consist<br>length<br>information|
|Subset-076-6-3_6060504_04_v400_SV30|||Generic with<br>Safe consist<br>length<br>information|
|Subset-076-6-3_6060504_05_v400_SV30|||Generic|
|Subset-076-6-3_6060504_06_v400_SV30|||Generic|
|Subset-076-6-3_6060504_07_v400_SV30|||Generic|
|Subset-076-6-3_6060504_08_v400_SV30|||Generic|
|Subset-076-6-3_6060504_09_v400_SV30|||Generic|
|Subset-076-6-3_6060505_01_v400_SV30|||Generic with<br>Safe consist<br>length<br>information|
|Subset-076-6-3_6060505_02_v400_SV30|||Generic with<br>Safe consist<br>length<br>information|
|Subset-076-6-3_6060505_03_v400_SV30|Safe consist<br>length<br>information<br>acquired from<br>ERTMS/ETCS<br>external sources||Generic with<br>Safe consist<br>length<br>information|
|Subset-076-6-3_6060505_04_v400_SV30|||Generic|
|Subset-076-6-3_6060505_05_v400_SV30|||Generic|
|Subset-076-6-3_6060505_06_v400_SV30|||Generic|
|Subset-076-6-3_6060505_07_v400_SV30|||Generic|
|Subset-076-6-3_6060505_08_v400_SV30|||Generic|
|Subset-076-6-3_6060506_01_v400_SV30|||Generic|
|Subset-076-6-3_6060506_02_v400_SV30|||Generic|

<!-- end of page 57 -->

|**Test Sequence**|**Optional**<br>**Interface**|**Radio**<br>**system(s)**<br>**installed on-**<br>**board**|**Train data set**|
|---|---|---|---|
|Subset-076-6-3_7040200_03_v400_SV30|||Generic|
|Subset-076-6-3_7050100_01_v400_SV30|||Generic|
|Subset-076-6-3_8040100_01_v400_SV30|||Generic|
|Subset-076-6-3_8040400_01_v400_SV30|||Generic|
|Subset-076-6-3_9990200_01_v400_SV30|||Generic|
|Subset-076-6-3_9990200_02_v400_SV30|||Generic|
|Subset-076-6-3_9990200_03_v400_SV30|||Lambda 1|
|Subset-076-6-3_9990200_04_v400_SV30|||Generic|
|Subset-076-6-3_9990200_05_v400_SV30|||Generic|
|Subset-076-6-3_9990200_06_v400_SV30|||Generic|
|Subset-076-6-3_9990200_07_v400_SV30|||Generic|
|Subset-076-6-3_9990200_08_v400_SV30|||Generic|
|Subset-076-6-3_9990200_09_v400_SV30|||Generic|
|Subset-076-6-3_9990200_10_v400_SV30|||Generic|
|Subset-076-6-3_9990200_11_v400_SV30|||Generic|
|Subset-076-6-3_9990200_12_v400_SV30|||Lambda 1|
|Subset-076-6-3_9990200_13_v400_SV30|||Generic with<br>Safe consist<br>length<br>information|
|Subset-076-6-3_9990400_01_v400_SV30|||Generic|
|Subset-076-6-3_9990400_03_v400_SV30|||Generic|
|Subset-076-6-3_9990400_04_v400_SV30|||Generic|
|Subset-076-6-3_9990400_05_v400_SV30|||Generic|
|Subset-076-6-3_9990400_06_v400_SV30|||Generic|
|Subset-076-6-3_9990400_07_v400_SV30|||Generic|
|Subset-076-6-3_9990400_08_v400_SV30|||Generic|
|Subset-076-6-3_9990400_09_v400_SV30|||Generic|

<!-- end of page 58 -->

|**Test Sequence**|**Optional**<br>**Interface**|**Radio**<br>**system(s)**<br>**installed on-**<br>**board**|**Train data set**|
|---|---|---|---|
|Subset-076-6-3_9990400_10_v400_SV30|||Generic|
|Subset-076-6-3_9990400_11_v400_SV30|||Generic|
|Subset-076-6-3_9990400_13_v400_SV30|||Generic|
|Subset-076-6-3_9990400_15_v400_SV30|||Generic|
|Subset-076-6-3_9990400_16_v400_SV30|||Generic|
|Subset-076-6-3_9990400_18_v400_SV30|||Generic|
|Subset-076-6-3_9990400_19_v400_SV30|||Generic|
|Subset-076-6-3_9990400_20_v400_SV30|||Generic|
|Subset-076-6-3_9990400_21_v400_SV30|||Generic|
|Subset-076-6-3_9990400_22_v400_SV30|||Generic|
|Subset-076-6-3_9990400_23_v400_SV30|||Generic|
|Subset-076-6-3_9990400_24_v400_SV30|||Generic|
|Subset-076-6-3_9990400_25_v400_SV30|||Generic|
|Subset-076-6-3_9990400_26_v400_SV30|RIU||Generic|
|Subset-076-6-3_9990400_27_v400_SV30|||Generic|
|Subset-076-6-3_9990400_28_v400_SV30|||Generic|
|Subset-076-6-3_9990400_29_v400_SV30|||Generic|
|Subset-076-6-3_9990400_30_v400_SV30|RIU||Generic|
|Subset-076-6-3_9990400_31_v400_SV30|EUROLOOP||Generic|
|Subset-076-6-3_9990400_32_v400_SV30|||Generic|
|Subset-076-6-3_9990400_33_v400_SV30|||Generic|
|Subset-076-6-3_9990400_34_v400_SV30|||Generic|
|Subset-076-6-3_9990400_35_v400_SV30|EUROLOOP||Generic|
|Subset-076-6-3_9990400_36_v400_SV30|RIU||Generic|
|Subset-076-6-3_9990400_37_v400_SV30|||Generic|
|Subset-076-6-3_9990400_38_v400_SV30|EUROLOOP||Generic|
|Subset-076-6-3_9990400_39_v400_SV30|EUROLOOP||Generic|

<!-- end of page 59 -->

|**Test Sequence**|**Optional**<br>**Interface**|**Radio**<br>**system(s)**<br>**installed on-**<br>**board**|**Train data set**|
|---|---|---|---|
|Subset-076-6-3_9990400_40_v400_SV30|EUROLOOP||Generic|
|Subset-076-6-3_9990400_41_v400_SV30|||Generic|
|Subset-076-6-3_9990400_42_v400_SV30|||Generic|
|Subset-076-6-3_9990400_43_v400_SV30|||Generic|
|Subset-076-6-3_9990400_44_v400_SV30|||Generic|
|Subset-076-6-3_9990400_45_v400_SV30|||Generic|
|Subset-076-6-3_9990400_46_v400_SV30|||Generic|
|Subset-076-6-3_9990400_47_v400_SV30|||Generic|
|Subset-076-6-3_9990400_48_v400_SV30||FRMCS+GSM-R|Generic|
|Subset-076-6-3_9990400_49_v400_SV30|||Generic|
|Subset-076-6-3_9990500_01_v400_SV30|||Generic|
|Subset-076-6-3_9990500_02_v400_SV30|||Generic|
|Subset-076-6-3_9990500_03_v400_SV30|||Generic|
|Subset-076-6-3_9990500_04_v400_SV30|RIU||Generic|
|Subset-076-6-3_9990500_05_v400_SV30|||Generic|
|Subset-076-6-3_9990500_06_v400_SV30|RIU||Generic|
|Subset-076-6-3_9990500_07_v400_SV30|RIU||Generic|
|Subset-076-6-3_9990500_09_v400_SV30|||Generic|
|Subset-076-6-3_9990500_10_v400_SV30|||Generic|
|Subset-076-6-3_9990500_11_v400_SV30|||Generic|
|Subset-076-6-3_9990500_14_v400_SV30|||Generic|
|Subset-076-6-3_9990500_15_v400_SV30|||Generic|
|Subset-076-6-3_9990500_16_v400_SV30|||Generic|
|Subset-076-6-3_9990500_18_v400_SV30|||Generic|
|Subset-076-6-3_9990500_19_v400_SV30|||Generic|
|Subset-076-6-3_9990500_20_v400_SV30|||Generic|
|Subset-076-6-3_9990500_21_v400_SV30|STM||Generic|

<!-- end of page 60 -->

|**Test Sequence**|**Optional**<br>**Interface**|**Radio**<br>**system(s)**<br>**installed on-**<br>**board**|**Train data set**|
|---|---|---|---|
|Subset-076-6-3_9990500_22_v400_SV30|RIU||Generic|
|Subset-076-6-3_9990500_24_v400_SV30|||Generic|
|Subset-076-6-3_9990500_25_v400_SV30|RIU||Generic|
|Subset-076-6-3_9990500_26_v400_SV30|||Generic|
|Subset-076-6-3_9990500_27_v400_SV30|||Generic|
|Subset-076-6-3_9990500_28_v400_SV30|||Generic|
|Subset-076-6-3_9990502_01_v400_SV30|||Generic|
|Subset-076-6-3_9990600_01_v400_SV30|||Generic|
|Subset-076-6-3_9990600_02_v400_SV30|||Generic|
|Subset-076-6-3_9990600_03_v400_SV30|||Generic|
|Subset-076-6-3_9990600_04_v400_SV30|||Generic|
|Subset-076-6-3_9990600_05_v400_SV30|||Generic|
|Subset-076-6-3_9990600_06_v400_SV30|||Generic|
|Subset-076-6-3_9990600_07_v400_SV30|||Generic|

<!-- end of page 61 -->
