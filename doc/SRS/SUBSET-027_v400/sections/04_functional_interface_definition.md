# **4. FUNCTIONAL INTERFACE DEFINITION**

## **4.1 Principles**

4.1.1.1 The ERTMS/ETCS on-board equipment shall detect occurrence of specific events and provide the corresponding message to the on-board recording device (see section 4.3, table 2).

4.1.1.2 When such an event occurs, the ERTMS/ETCS on-board equipment shall register:

   - a)  the date and time of the occurrence of the event using Universal Time Co-ordinated (UTC)

   - b) The train position and speed at the occurrence of the event

   - c) The operated system version, level and mode at the occurrence of the event

4.1.1.3 This date and time information shall be used to timestamp the corresponding message(s) to be sent over the interface according to the table 1.

4.1.1.4 The juridical data included in a message shall be forwarded over the interface less than 5 seconds after the occurrence of the event that triggered the message.

4.1.1.5 When sending one message or several messages together in relation with the same triggering event, the encapsulated data shall be consistent with each other regarding the time stamping.

<!-- end of page 9 -->

## **4.2 Juridical Recording information (Messages / Variables)**

### **4.2.1 Messages list**

4.2.1.1 Each message has a variable in its header that contains a number to have a way to distinguish the messages. The list of all the messages, associated number and purpose is shown in Table 1:

|**NID_MESSAGE**|**MESSAGE**|**PAGE**|
|---|---|---|
|1|GENERAL MESSAGE|21|
|2|TRAIN DATA|21|
|3|EMERGENCY BRAKE COMMAND STATE|28|
|4|SERVICE BRAKE COMMAND STATE|29|
|5|MESSAGE TO RADIO INFILL UNIT|29|
|6|TELEGRAM FROM BALISE|29|
|7|MESSAGE FROM EUROLOOP|29|
|8|MESSAGE FROM RADIO INFILL UNIT|30|
|9|MESSAGE FROM RBC|30|
|10|MESSAGE TO RBC|30|
|11|DRIVER’S ACTIONS|30|
|12|BALISE GROUP ERROR|32|
|13|RADIO ERROR|33|
|14|STM INFORMATION|33|
|15|INFORMATION FROM COLD MOVEMENT DETECTOR|36|
|16|START DISPLAYING FIXED TEXT MESSAGE|36|
|17|STOP DISPLAYING FIXED TEXT MESSAGE|36|
|18|START DISPLAYING PLAIN TEXT MESSAGE|37|
|19|STOP DISPLAYING PLAIN TEXT MESSAGE|37|
|20|SPEED AND DISTANCE MONITORING INFORMATION|37|
|21|DMI SYMBOL STATUS|40|

<!-- end of page 10 -->

|22|DMI SOUND STATUS|43|
|---|---|---|
|23|DMI SYSTEM STATUS MESSAGE|43|
|24|RBC CONTACT INFORMATION ENTERED BY THE DRIVER|44|
|25|SR SPEED/DISTANCE ENTERED BY THE DRIVER|45|
|26|NTC SELECTED|46|
|27|SAFETY CRITICAL FAULT IN MODE SL, NL OR PS|46|
|28|VIRTUAL BALISE COVER SET BY THE DRIVER|46|
|29|VIRTUAL BALISE COVER REMOVED BY THE DRIVER|46|
|30|SLEEPING INPUT|47|
|31|PASSIVE SHUNTING INPUT|47|
|32|NON LEADING INPUT|47|
|33|REGENERATIVE BRAKE STATUS|48|
|34|MAGNETIC SHOE BRAKE STATUS|48|
|35|EDDY CURRENT BRAKE STATUS|49|
|36|ELECTRO PNEUMATIC BRAKE STATUS|49|
|37|ADDITIONAL BRAKE STATUS|49|
|38|CAB STATUS|50|
|39|DIRECTION CONTROLLER POSITION|51|
|40|TRACTION STATUS|51|
|41|TYPE OF TRAIN DATA|52|
|42|NATIONAL SYSTEM ISOLATION|52|
|43|TRACTION CUT OFF COMMAND STATE|53|
|44|LOWEST<br>SUPERVISED<br>SPEED<br>WITHIN<br>THE<br>MOVEMENT<br>AUTHORITY|53|
|45|TRACK CONDITIONS|54|
|46|SET SPEED|56|
|47|BRAKE AND TRACTION INTERFACE CONFIGURATION|57|
|48|RADIO NETWORK ID ENTERED BY THE DRIVER|59|

<!-- end of page 11 -->

|49|TRAIN RUNNING NUMBER ENTERED BY THE DRIVER|60|
|---|---|---|
|50|TRAIN INTEGRITY INFORMATION|60|
|51|REMOTE SHUNTING STATE|60|
|52|ODOMETER ACCURACY MONITORING ERROR|61|
|53|TARGET ADVICE SPEED|60|
|54|OVERALL CONSIST LENGTH|62|
|55-254|SPARE||
|255|ETCS ON-BOARD PROPRIETARY JURIDICAL DATA|63|

**Table 1: Juridical Recording messages list**

### **4.2.2 General structure of the messages**

4.2.2.1 All the messages have the same structure with a common header and a set of variables depending on the message sent.

4.2.2.2 A message shall be composed of:

   1. A common header (fields 1 to 11). Therefore the variables 3 to 11 must be captured with each event of the table 2.

   2. Complementary variables as needed by application (fields 12-N) according to the messages list.

#### Field FIELDS Remarks

#### No

|1|NID_MESSAGE|Message identification number|
|---|---|---|
|2|L_MESSAGE|Message length including fields 1 to N|
|3|DATE|Current date|
|4|TIME|Current time|
|5|TRAIN_POSITION|Current train position|
|6|V_TRAIN|Current train speed|
|7|DRIVER_ID|Driver identifier|
|8|NID_ENGINE|On-board ETCS identity|

<!-- end of page 12 -->

|9|SYSTEM_VERSION|Currently operated system version|
|---|---|---|
|10|LEVEL|Current level|
|11|MODE|Current mode|
|12 …|Complementary<br>variables|Data associated to the message. Its length<br>depends on the message content, but it’s<br>always rounded up to a bytes unit.|

Note: To be coherent the length of the variables defined in other documents is not included in the following description.

4.2.2.3 Signed values shall be encoded as 2’s complement.

<!-- end of page 13 -->

### **4.2.3 Common Fields Description**

#### 4.2.3.1 NID_MESSAGE

|**_Description_**|This field contains the me|ssage identifier.||
|---|---|---|---|
|**_Content_**|**Variable**|**Length**|**Comment**|
||NID_MESSAGE|8||

#### **NID_MESSAGE**

|**Name**|Message identifier|||
|---|---|---|---|
|**Description**|Identifier of the me|ssage||
|**Length of variable**|**Minimum Value**|**Maximum Value**|**Resolution/formula**|
|8 bits|0|255|Numbers|
|**Special/Reserved**<br>**Values**||||

#### 4.2.3.2 L_MESSAGE

|**_Description_**|This field contains the me|ssage length.||
|---|---|---|---|
|**_Content_**|**Variable**|**Length**|**Comment**|
||L_MESSAGE|11||

#### **L_MESSAGE**

|**Name**|Message length|||
|---|---|---|---|
|**Description**|L_MESSAGE indi<br>variables defined i|cates the length of t<br>n the message header|he message in bytes, including all<br>(L_MESSAGE also).|
|**Length of variable**|**Minimum Value**|**Maximum Value**|**Resolution/formula**|
|11 bits|0|2047|1 Byte|
|**Special/Reserved**<br>**Values**||||

#### 4.2.3.3 DATE

|**_Description_**|It contains the date.|||
|---|---|---|---|
|**_Content_**|**Variable**|**Length**|**Comment**|
||YEAR|7||
||MONTH|4||
||DAY|5||
|**EAR**<br>**Name**|Official year|||

#### **YEAR**

<!-- end of page 14 -->

|**Description**|It’s used to label data<br>and ten).|recorded. Only the las|t two figures of the year are recorded (unit|
|---|---|---|---|
|**Length of variable**|**Minimum Value**|**Maximum Value**|**Resolution/formula**|
|7 bits|00|99|1 year|
|**Special/Reserved**|110 0100|100|not used|
|**Values**|…|…|…|
||111 1110|126|not used|
||111 1111|127|year unknown|

#### **MONTH**

|**Name**|Official month||||
|---|---|---|---|---|
|**Description**|It’s used to label dat|a recorde|d.||
|**Length of variable**|**Minimum Value**|**Maxi**|**mum Value**|**Resolution/formula**|
|4 bits|01|12||1 month|
|**Special/Reserved**|0000||0|not used|
|**Values**|1101||13|not used|
||1110||14|not used|
||1111||15|month unknown|

#### **DAY**

|**Name**|Official day|||
|---|---|---|---|
|**Description**|It’s used to label data|recorded.||
|**Length of variable**|**Minimum Value**|**Maximum Value**|**Resolution/formula**|
|5 bits|01|31|1 day|
|**Special/Reserved**<br>**Values**|0 0000|0|day unknown|

#### 4.2.3.4 TIME

|**_Description_**|It contains the time in Universal|Time Co-ordinated (UTC).|
|---|---|---|
|**_Content_**|**Variable**|**Length**<br>**Comment**|
||HOUR|5|
||MINUTES|6|
||SECONDS|6|
||TTS|5|

<!-- end of page 15 -->

#### **HOUR**

|**Name**|Official hour|||
|---|---|---|---|
|**Description**|It’s used to label dat|a recorded.||
|**Length of variable**|**Minimum Value**|**Maximum Value**|**Resolution/formula**|
|5 bits|00|23|1 hour|
|**Special/Reserved**|1 1000|24|not used|
|**Values**|…|…|…|
||1 1110|30|not used|
||1 1111|31|hour unknown|

#### **MINUTES**

|**Name**|Official minutes|||
|---|---|---|---|
|**Description**|It’s used to label dat|a recorded.||
|**Length of variable**|**Minimum Value**|**Maximum Value**|**Resolution/formula**|
|6 bits|00|59|1 minute|
|**Special/Reserved**|11 1100|60|not used|
|**Values**|11 1101|61|not used|
||11 1110|62|not used|
||11 1111|63|minutes unknown|

#### **SECONDS**

|**Name**|Official seconds|||
|---|---|---|---|
|**Description**|It’s used to label dat|a recorded.||
|**Length of variable**|**Minimum Value**|**Maximum Value**|**Resolution/formula**|
|6 bits|00|59|1 second|
|**Special/Reserved**|11 1100|60|not used|
|**Values**|11 1101|61|not used|
||11 1110|62|not used|
||11 1111|63|seconds unknown|

#### **TTS**

|**Name**|Official hundredth of|second||
|---|---|---|---|
|**Description**|It's used to label data<br>SECONDS.|recorded. Used only i|n conjunction with HOUR, MINUTES and|
|**Length of variable**|**Minimum Value**|**Maximum Value**|**Resolution/formula**|
|5 bits|000 ms|950 ms|050 ms|
|**Special/Reserved**|10100 to 11110||not used|
|**Values**|11111||hundredth of second unknown|

<!-- end of page 16 -->

#### 4.2.3.5 TRAIN_POSITION

|**_Description_**|This field contains the posi<br>reference to the SOLR and<br>SOLR.|tion of the<br>the LRBG,|train. This position is calculated in<br>if it exists and it is different from the|
|---|---|---|---|
|**_Content_**|**Variable**|**Length**|**Comment**|
||Q_SCALE_SOLR||Defined by analogy to 7.5.1.129 of<br>[1]|
||NID_SOLR||Defined by analogy to 7.5.1.90 of [1]|
||D_SOLR||Defined by analogy to 7.5.1.13 of [1]|
||Q_DIRSOLR||Defined by analogy to 7.5.1.104 of<br>[1]|
||Q_DSOLR||Defined by analogy to 7.5.1.106 of<br>[1]|
||L_DOUBTOVER_SOLR||Defined by analogy to 7.5.1.43 of [1]|
||L_DOUBTUNDER_SOLR||Defined by analogy to 7.5.1.44 of [1]|
||Q_LRBG|2||
||Q_SCALE_LRBG||Defined by analogy to 7.5.1.129 of<br>[1]. This variable exists only if<br>Q_LRBG is equal to value 2.|
||NID_LRBG||Defined in 7.5.1.90 of [1]. This<br>variable exists only if Q_LRBG is<br>equal to value 2.|
||D_LRBG||Defined in 7.5.1.13 of [1]. This<br>variable exists only if Q_LRBG is<br>equal to value 2.|
||Q_DIRLRBG||Defined in 7.5.1.104 of [1]. This<br>variable exists only if Q_LRBG is<br>equal to value 2.|
||Q_DLRBG||Defined in 7.5.1.106 of [1]. This<br>variable exists only if Q_LRBG is<br>equal to value 2.|
||L_DOUBTOVER_LRBG||Defined by analogy to 7.5.1.43 of [1].<br>This variable exists only if Q_LRBG<br>is equal to value 2.|
||L_DOUBTUNDER_LRBG||Defined by analogy to 7.5.1.44 of [1].<br>This variable exists only if Q_LRBG<br>is equal to value 2.|

#### **Q_LRBG**

**Name** Qualifier to indicate if the train position refers to an LRBG and if the LRBG is different from the SOLR

<!-- end of page 17 -->

|**Description**|This variable indic<br>different from the|ates if the train positi<br>SOLR.|on refers to an LRBG and if the LRBG is|
|---|---|---|---|
|**Length of variable**|**Minimum Value**|**Maximum Value**|**Resolution/formula**|
|2 bits||||
|**Special/Reserved**<br>**Values**|0|The train position|does not refer to an LRBG|
||1|The train position|refers to an LRBG that is the SOLR|
||2|The train position|refers to an LRBG that is not the SOLR|
||3|Spare||

#### 4.2.3.6 V_TRAIN

|**_Description_**|This field contains the curr|ent speed of the train.||
|---|---|---|---|
|**_Content_**|**Variable**|**Length**|**Comment**|
||V_TRAIN|10||

#### **V_TRAIN**

|**Name**|Current train speed|||
|---|---|---|---|
|**Description**||||
|**Length of variable**|**Minimum Value**|**Maximum Value**|**Resolution/formula**|
|10 bits|0 km/h|600 km/h|1 km/h|
|**Special/reserved**|601 – 1022|Spare||
|**value**||||
||1023|Standstill||

#### 4.2.3.7 DRIVER_ID

|**_Description_**|This field contains the dri|ver identifier number.|
|---|---|---|
|**_Content_**|**Variable**|**Length**<br>**Comment**|
||DRIVER_ID|128 bits|

<!-- end of page 18 -->

#### **DRIVER_ID**

|**Name**|Driver identifier number|||
|---|---|---|---|
|**Description**|The DRIVER_ID cons<br>entered left adjusted i<br>character of the DRIV<br>characters, the remaini<br>0x00.|ists of up to 16 alph<br>nto the data field, th<br>ER_ID. In case the<br>ng characters are to|anumeric characters, which are<br>e leftmost character is the first<br>DRIVER_ID is shorter than 16<br>be coded with the null character|
|**Length of variable**|**Minimum Value**|**Maximum Value**|**Resolution/formula**|
|128 bits|||1 to 16 alphanumeric<br>characters, completed by 15 to<br>0 null (0x00) characters (ISO<br>8859-1, also known as Latin<br>Alphabet #1)|
|**Special/reserved**<br>**value**|‘????????????????’|Unknown||

#### 4.2.3.8 NID_ENGINE

|**_Description_**|This field contains the onb|oard ETCS ide|ntity.|
|---|---|---|---|
|**_Content_**|**Variable**|**Length**|**Comment**|
||NID_ENGINE||Defined in Chapter 7 of [1]|

#### 4.2.3.9 SYSTEM_VERSION

|**_Description_**|This field contains the cur|rently operated|system version.|
|---|---|---|---|
|**_Content_**|**Variable**|**Length**|**Comment**|
||M_VERSION||Defined in Chapter 7 of [1]|

#### 4.2.3.10 LEVEL

|**_Description_**|This field contains the cur|rent level.||
|---|---|---|---|
|**_Content_**|**Variable**|**Length**|**Comment**|
||M_LEVEL||Defined in Chapter 7 of [1]|

#### 4.2.3.11 MODE

|**_Description_**|This field contains the cur|rent mode.||
|---|---|---|---|
|**_Content_**|**Variable**|**Length**|**Comment**|
||M_MODE||Defined in Chapter 7 of [1]|

<!-- end of page 19 -->

<!-- end of page 20 -->

### **4.2.4 Message Description**

#### 4.2.4.1 GENERAL MESSAGE

|**_Description_**|This message contains the co|mmon header only.||
|---|---|---|---|
|**_Content_**|**Complementary Variable**|**Length**|**Comment**|
||Null|||

#### 4.2.4.2 TRAIN DATA

|**_Description_**|This message contains the train d|ata.||
|---|---|---|---|
|**_Content_**|**Complementary Variable**|**Length**|**Comment**|
||V_MAXTRAIN||Maximum train speed for the train.<br>Defined in Chapter 7 of [1]|
||NC_CDTRAIN||Cant<br>deficiency<br>train<br>category.<br>Defined in Chapter 7 of [1]|
||NC_TRAIN||Other international train category.<br>Defined in Chapter 7 of [1]|
||L_TRAIN||Train length.<br>Defined in Chapter 7 of [1]|
||T_TRACTION_CUT_OFF|12||
||M_BRAKE_POSITION|2||
||M_NOM_ROT_MASS|5||
||Q_BRAKE_CAPT_TYPE|1||
||M_BRAKE_PERCENTAGE|8|Only if Q_BRAKE_CAPT_TYPE = 0|
||N_BRAKE_CONF|4|Only if Q_BRAKE_CAPT_TYPE = 0|
||M_BRAKE_LAMBDA_CONF(k)|3|Only if Q_BRAKE_CAPT_TYPE = 0:<br>specific configuration of the special<br>brakes for lambda train|
||T_BRAKE_SERVICE_REACT(k)|12|Only if Q_BRAKE_CAPT_TYPE = 0:<br>Service Brake reaction time|
||T_BRAKE_SERVICE(k)|12|Only if Q_BRAKE_CAPT_TYPE = 0:<br>Service Brake equivalent brake build<br>up time for target speed = 0|
||T_BRAKE_SERVICE(k)|12|Only if Q_BRAKE_CAPT_TYPE = 0:<br>Service Brake equivalent build up time<br>for target speed > 0|

<!-- end of page 21 -->

|N_BRAKE_CONF|4|Only if Q_BRAKE_CAPT_TYPE = 1<br>(gamma type), N_BRAKE_CONF and<br>the following variables follow until<br>A_BRAKE_SERVICE_COMP<br>inclusive|
|---|---|---|
|M_BRAKE_GAMMA_CONF(k)|4|Specific configuration of the special<br>brakes for gamma trains|
|T_BRAKE_EMERGENCY_REA<br>CT(k)|12|Emergency Brake reaction time|
|T_BRAKE_EMERGENCY(k)|12|Emergency Brake equivalent brake<br>build up time|
|N_BRAKE_SECTIONS(k)|3|Number of sections in order to build<br>the following brake model.|
|V_BRAKE_EMERGENCY_COM<br>P(k, m)|10|Speed component of the emergency<br>brake nominal deceleration.|
|A_BRAKE_EMERGENCY_COM<br>P(k, m)|8|Acceleration<br>component<br>of<br>the<br>emergency<br>brake<br>nominal<br>deceleration.|
|M_KDRY_RST(A_BRAKE_EMERGENCY_<br>COMP(k, m), 0)|5|Rolling stock correction factor on dry<br>rail for a confidence level equal to 50<br>%|
|M_KDRY_RST(A_BRAKE_EMERGENCY_<br>COMP(k, m), 1)|5|Rolling stock correction factor on dry<br>rail for a confidence level equal to 90<br>%|
|M_KDRY_RST(A_BRAKE_EMERGENCY_<br>COMP(k, m), 2)|5|Rolling stock correction factor on dry<br>rail for a confidence level equal to 99<br>%|
|M_KDRY_RST(A_BRAKE_EMERGENCY_<br>COMP(k, m), 3)|5|Rolling stock correction factor on dry<br>rail for a confidence level equal to 99,9<br>%|
|M_KDRY_RST(A_BRAKE_EMERGENCY_<br>COMP(k, m), 4)|5|Rolling stock correction factor on dry<br>rail for a confidence level equal to<br>99,99 %|
|M_KDRY_RST(A_BRAKE_EMERGENCY_<br>COMP(k, m), 5)|5|Rolling stock correction factor on dry<br>rail for a confidence level equal to<br>99,999 %|
|M_KDRY_RST(A_BRAKE_EMERGENCY_<br>COMP(k, m), 6)|5|Rolling stock correction factor on dry<br>rail for a confidence level equal to<br>99,9999 %|
|M_KDRY_RST(A_BRAKE_EMERGENCY_<br>COMP(k, m), 7)|5|Rolling stock correction factor on dry<br>rail for a confidence level equal to<br>99,99999 %|

<!-- end of page 22 -->

|M_KDRY_RST(A_BRAKE_EMERGENCY_<br>COMP(k, m), 8)|5|Rolling stock correction factor on dry<br>rail for a confidence level equal to<br>99,999999 %|
|---|---|---|
|M_KDRY_RST(A_BRAKE_EMERGENCY_<br>COMP(k, m), 9)|5|Rolling stock correction factor on dry<br>rail for a confidence level equal to<br>99,9999999 %|
|M_KWET_RST(A_BRAKE_EMERGENCY<br>_COMP(k, m))|5|Rolling stock correction factor on wet<br>rail|
|T_BRAKE_SERVICE_REACT(k)|12|Service Brake reaction time|
|T_BRAKE_SERVICE(k)|12|Service Brake equivalent brake build<br>up time|
|N_BRAKE_SECTIONS(k)|3|Number of sections in order to build<br>the following brake model.|
|V_BRAKE_SERVICE_COMP(k,<br>m)|10|Speed component of the service brake<br>nominal deceleration.|
|A_BRAKE_SERVICE_COMP(k,<br>m)|8|Acceleration component of the service<br>brake nominal deceleration.|
|M_LOADINGGAUGE||Loading gauge. Defined in Chapter 7<br>of [1]|
|N_AXLE||Axle number of the engine. Defined in<br>Chapter 7 of [1]|
|M_AXLELOADCAT||Axle load category. Defined in Chapter<br>7 of [1]|
|N_ITER||Number of iterations. Defined in<br>Chapter 7 of [1]|
|M_VOLTAGE(k)||Traction system voltage. Defined in<br>Chapter 7 of [1]|
|NID_CTRACTION(k)||Only if M_VOLTAGE(k) ≠ 0. Country<br>identifier of the traction system.<br>Defined in Chapter 7 of [1]|
|N_ITER||Number of iterations. Defined in<br>Chapter 7 of [1]|
|NID_NTC(k)||National system identity. Defined in<br>Chapter 7 of [1]|
|M_AIRTIGHT||Airtight system presence. Defined in<br>Chapter 7 of [1]|

<!-- end of page 23 -->

#### **T_TRACTION_CUT_OFF**

|**Name**|Time to cut-off traction||
|---|---|---|
|**Description**|It is the nominal traction cut-off time counte<br>traction cut-off command (if implemented)<br>is triggered by the on-board to the moment<br>zero.|d from the moment when either the<br>or the emergency brake command<br>the acceleration due to traction is|
|**Length of variable**|**Minimum Value**<br>**Maximum Value**|**Resolution/formula**|
|12 bits|0 s<br>40.95 s|0.01 s|

#### **M_BRAKE_POSITION**

|**Name**|Brake position|||
|---|---|---|---|
|**Description**|The brake position|defines the behaviour of|the brake for specific train types.|
|**Length of variable**|**Minimum Value**|**Maximum Value**|**Resolution/formula**|
|2 bits||||
|**Special/reserved**<br>|0|Passenger train in P||
|**value**|1|Freight train in P||
||2|Freight train in G||
||3|Spare||

#### **M_NOM_ROT_MASS**

|**Name**|Nominal rotating m|ass of the train||
|---|---|---|---|
|**Description**|It defines the nomi|nal rotating mass as a p|ercentage of the total train weight.|
|**Length of variable**|**Minimum Value**|**Maximum Value**|**Resolution/formula**|
|5 bits|0 %|15 %|1 %|
|**Special/reserved**|16|Unknown||
|**value**|17-31|Spare||

#### **Q_BRAKE_CAPT_TYPE**

|**Name**|Qualifier for gam|ma/lambda discrimi|nation|
|---|---|---|---|
|**Description**|This variable discri|minates the type of|capture of the brake parameters.|
|**Length of variable**|**Minimum Value**|**Maximum Value**|**Resolution/formula**|
|1 bit||||
|**Special/Reserved**|0|Lambda type: the|brake percentage is acquired as Train|
|**Values**||Data and the con|version model is applicable|

<!-- end of page 24 -->

1 Gamma type: all other captures

#### **M_BRAKE_PERCENTAGE**

|**Name**|Brake percentage v|alue||
|---|---|---|---|
|**Description**|The brake percent<br>with the conversion|age is used to derive t<br>model.|he brake parameters in conjunction|
|**Length of variable**|**Minimum Value**|**Maximum Value**|**Resolution/formula**|
|8 bits|0 %|250 %|1 %|
|**Special/reserved**<br>**value**|251-255|Spare||

#### **N_BRAKE_CONF**

|**Name**|Special brakes configuration number||
|---|---|---|
|**Description**|Number of iterations of special brake c<br>selection of the appropriate brake paramet<br>message|onfiguration(s) applicable to the<br>er(s), following this variable in the|
|**Length of variable**|**Minimum Value**<br>**Maximum Value**|**Resolution/formula**|
|4 bits|1<br>16||

#### **M_BRAKE_LAMBDA_CONF**

|**Name**|Specific special br|akes configuration for lambda trains|
|---|---|---|
|**Description**|It describes a spe<br>parameters are ap|cific special brake configuration to which the related brake<br>plicable.|
|**Length of variable**|**Minimum Value**|**Maximum Value**<br>**Resolution/formula**|
|3 bits||Bit set|
|**Special/reserved**<br>**value**|000|No interface to special brakes exists or all status are<br>inactive|
||xx1|Regenerative brake interface exists and status is active|
||x1x|Eddy current brake interface exists and status is active|
||1xx|Ep brake interface exists and status is active|

#### **T_BRAKE_SERVICE_REACT**

|**Name**|Service Brake reaction time|
|---|---|
|**Description**|This is the reaction time for the service brake, i.e. the interval between the<br>moment the service brake command is triggered by the ERTMS/ETCS on-<br>board and the moment the brake force starts to build up.|

<!-- end of page 25 -->

|**Length of variable**|**Minimum Value**|**Maximum Value**|**Resolution/formula**|
|---|---|---|---|
|12 bits|0 s|204.75 s|0.05 s|

#### **T_BRAKE_SERVICE**

|**Name**|Service Brake equi|valent brake build up tim|e|
|---|---|---|---|
|**Description**|This is the equivale|nt brake build up time f|or the service brake.|
|**Length of variable**|**Minimum Value**|**Maximum Value**|**Resolution/formula**|
|12 bits|0 s|204.75 s|0.05 s|

#### **M_BRAKE_GAMMA_CONF**

|**Name**|Specific special br|akes configuration for gamma trains|
|---|---|---|
|**Description**|It describes a spe<br>parameters are ap|cific special brake configuration to which the related brake<br>plicable.|
|**Length of variable**|**Minimum Value**|**Maximum Value**<br>**Resolution/formula**|
|4 bits||Bit set|
|**Special/reserved**<br>**value**|0000|No interface to special brakes exists or all status are<br>inactive|
||xxx1|Regenerative brake interface exists and status is active|
||xx1x|Eddy current brake interface exists and status is active|
||x1xx|Magnetic shoe brake interface exists and status is active|
||1xxx|Ep brake interface exists and status is active|

#### **T_BRAKE_EMERGENCY_REACT**

|**Name**|Emergency Brake reaction time, i.e. the interval between the moment the<br>emergency brake command is triggered by the ERTMS/ETCS on-board and<br>the moment the brake force starts to build up.|
|---|---|
|**Description**|This is the reaction time for the emergency brake.|
|**Length of variable**|**Minimum Value**<br>**Maximum Value**<br>**Resolution/formula**|
|12 bits|0 s<br>204.75 s<br>0.05 s|

#### **T_BRAKE_EMERGENCY**

|**Name**|Emergency Brake equivalent brake build up time|
|---|---|
|**Description**|This is the equivalent brake build up time for the emergency brake.|
|**Length of variable**|**Minimum Value**<br>**Maximum Value**<br>**Resolution/formula**|

<!-- end of page 26 -->

|12 bits<br>0 s|204.75 s|0.05 s|
|---|---|---|

#### **N_BRAKE_SECTIONS**

|**Name**|Brake number of s|ections||
|---|---|---|---|
|**Description**|Number of iteration<br>this variable in the|s of speed sections nee<br>message.|ded to build a brake model, following|
|**Length of variable**|**Minimum Value**|**Maximum Value**|**Resolution/formula**|
|3 bits|1|7||
|**Special/reserved**<br>**value**|0|Spare||

#### **V_BRAKE_EMERGENCY_COMP**

|**Name**|Emergency brake s|peed component||
|---|---|---|---|
|**Description**|It contains the low<br>emergency brake d|est speed value of the s<br>eceleration component i|peed section to which the related<br>s applicable.|
|**Length of variable**|**Minimum Value**|**Maximum Value**|**Resolution/formula**|
|10 bits|0 km/h|600 km/h|1 km/h|
|**Special/reserved**<br>**value**|601 – 1023|Spare||

#### **A_BRAKE_EMERGENCY_COMP**

|**Name**|Emergency brake|deceleration component||
|---|---|---|---|
|**Description**|It contains the valu|e of the emergency brake|deceleration component which is|
||applicable to the re|lated speed section.||
|**Length of variable**|**Minimum Value**|**Maximum Value**|**Resolution/formula**|
|8 bits|0 m/s²|2.55 m/s²|0.01 m/s²|

#### **M_KDRY_RST**

|**Name**|Rolling stock corre|ction factor on dry rails||
|---|---|---|---|
|**Description**|This variable is|a correction factor app|licable to the emergency brake|
||deceleration accor|ding to the variable M_N|VEBCL defined in chapter 7 of [1].|
|**Length of variable**|**Minimum Value**|**Maximum Value**|**Resolution/formula**|
|5 bits|0|1.55|0.05|

#### **M_KWET_RST**

<!-- end of page 27 -->

|**Name**|Rolling stock corre|ction factor on wet rail||
|---|---|---|---|
|**Description**|This variable is<br>deceleration accor|a correction factor app<br>ding to the variable M_N|licable to the emergency brake<br>VAVADH defined in chapter 7 of [1].|
|**Length of variable**|**Minimum Value**|**Maximum Value**|**Resolution/formula**|
|5 bits|0|1.55|0.05|

#### **V_BRAKE_SERVICE_COMP**

|**Name**|Service brake spee|d component||
|---|---|---|---|
|**Description**|It contains the low<br>service brake dece|est speed value of the s<br>leration component is ap|peed section to which the related<br>plicable.|
|**Length of variable**|**Minimum Value**|**Maximum Value**|**Resolution/formula**|
|10 bits|0 km/h|600 km/h|1 km/h|
|**Special/reserved**<br>**value**|601 – 1023|Spare||

#### **A_BRAKE_SERVICE_COMP**

|**Name**|Service brake deceleration component||
|---|---|---|
|**Description**|It contains the value of the service brake<br>applicable to the related speed section.|deceleration component which is|
|**Length of variable**|**Minimum Value**<br>**Maximum Value**|**Resolution/formula**|
|8 bits|0 m/s²<br>2.55 m/s²|0.01 m/s²|

#### 4.2.4.3 EMERGENCY BRAKE COMMAND STATE

|**_Description_**|This message records the emerg<br>[4] 2.3.3).|ency brak|e application command state (see|
|---|---|---|---|
|**_Content_**|**Complementary Variable**|**Length**|**Comment**|
||M_BRAKE_COMMAND_STATE|1||

#### **M_BRAKE_COMMAND_STATE**

|**Name**|Brake command st|ate||
|---|---|---|---|
|**Description**|It contains the com|mand state of the brakes.||
|**Length of variable**|**Minimum Value**|**Maximum Value**|**Resolution/formula**|
|1 bit||||
|**Special/reserved**|0|Not commanded||
|**value**|1|Commanded||

<!-- end of page 28 -->

#### 4.2.4.4 SERVICE BRAKE COMMAND STATE

|**_Description_**|This message records the servic<br>2.3.3).|e brake a|pplication command state (see [4]|
|---|---|---|---|
|**_Content_**|**Complementary Variable**|**Length**|**Comment**|
||M_BRAKE_COMMAND_STATE|1|Defined in 4.2.4.3|

#### 4.2.4.5 MESSAGE TO RADIO INFILL UNIT

|**_Description_**|This message shall be sent a|fter sending|a message to an RIU.|
|---|---|---|---|
|**_Content_**|**Complementary Variable**|**Length**|**Comment**|
||NID_C||Defined in Chapter 7 of [1]|
||NID_RIU||Defined in Chapter 7 of [1]. ETCS<br>identity (NID_C + NID_RIU) of the<br>RIU to which the following message<br>has been sent.|
||Message, as defined in Chap|ters 7 and 8|of [1], sent to the referenced RIU.|

#### 4.2.4.6 TELEGRAM FROM BALISE

|**_Description_**|This message is sent after receiving a telegram from a balise.|
|---|---|
|**_Content_**|The content of this message is the telegram coming from a balise as defined in<br>Chapters 7 and 8 of [1].|

#### 4.2.4.7 MESSAGE FROM EUROLOOP

|**_Description_**|This message is sent after receiving a message from an Euroloop.|
|---|---|
|**_Content_**|The content of this message is any message coming from an Euroloop as|
||defined in Chapters 7 and 8 of [1].|

<!-- end of page 29 -->

#### 4.2.4.8 MESSAGE FROM RADIO INFILL UNIT

|**_Description_**|This message is sent after re|ceiving a m|essage from a radio infill unit.|
|---|---|---|---|
|**_Content_**|**Complementary Variable**|**Length**|**Comment**|
||NID_C||Defined in Chapter 7 of [1]|
||NID_RIU||Defined in Chapter 7 of [1]. ETCS<br>identity (NID_C + NID_RIU) of the<br>RIU from which the following<br>message has been received.|
||Message, as defined in Cha<br>RIU.|pters 7 and|8 of [1], coming from the referenced|

#### 4.2.4.9 MESSAGE FROM RBC

|**_Description_**|This message is sent after re|ceiving a m|essage from an RBC.|
|---|---|---|---|
|**_Content_**|**Complementary Variable**|**Length**|**Comment**|
||NID_C||Defined in Chapter 7 of [1]|
||NID_RBC||Defined in Chapter 7 of [1]. ETCS<br>identity (NID_C + NID_RBC) of the<br>RBC from which the following<br>message has been received.|
||Message, as defined in [1], c|oming from|the referenced RBC.|

#### 4.2.4.10 MESSAGE TO RBC

|**_Description_**|This message is sent after se|nding a me|ssage to an RBC.|
|---|---|---|---|
|**_Content_**|**Complementary Variable**|**Length**|**Comment**|
||NID_C||Defined in Chapter 7 of [1]|
||NID_RBC||Defined in Chapter 7 of [1]. ETCS<br>identity (NID_C + NID_RBC) of the<br>RBC to which the following<br>message has been sent.|
||Message, as defined in [1], s|ent to the re|ferenced RBC.|

#### 4.2.4.11 DRIVER’S ACTIONS

|**_Description_**|This message is sent whenev<br>ERTMS/ETCS DMI.|er the driver acts on the on board system via the|
|---|---|---|
|**_Content_**|**Complementary Variable**|**Length**<br>**Comment**|
||M_DRIVERACTIONS|8|

<!-- end of page 30 -->

#### **M_DRIVERACTIONS**

|**Name**||Driver’s actions|.|
|---|---|---|---|
|**Description**||This variable co|ntains the driver’s action.|
|**Length**<br>**variable**|**of**|**Minimum Value**|**Maximum Value**<br>**Resolution/formula**|
|8 bit||||
|**Special/Reser**<br>**Values**|**ved**|0000 0000<br>0000 0001<br>0000 0010<br>0000 0011<br>0000 0100<br>0000 0101<br>0000 0110<br>0000 0111<br>0000 1000<br>0000 1001<br>0000 1010<br>0000 1011<br>0000 1100<br>0000 1101<br>0000 1110<br>0000 1111<br>0001 0000<br>0001 0001<br>0001 0010<br>0001 0011<br>0001 0100<br>0001 0101<br>0001 0110<br>0001 0111<br>0001 1000<br>0001 1001<br>0001 1010<br>0001 1011<br>0001 1100<br>0001 1101<br>0001 1110<br>0001 1111<br>0010 0000<br>0010 0001<br>0010 0010|Ack of On Sight mode<br>Ack of Shunting mode<br>Ack of Train Trip<br>Ack of Staff Responsible mode<br>Ack of Unfitted mode<br>Ack of Reversing mode<br>Ack level 0<br>Ack of NL no longer permitted<br>Supervised Manoeuvre selected<br>Exit Supervised Manoeuvre selected<br>Ack level NTC<br>Shunting selected<br>Non Leading selected<br>Ack of Limited Supervision mode<br>Override selected<br>“Continue Shunting on desk closure” selected<br>Brake release acknowledgement<br>Exit of Shunting selected<br>Isolation selected<br>Start selected<br>Train Data Entry requested<br>Validation of train data<br>Confirmation of Track Ahead Free<br>Ack of Plain Text information<br>Ack of Fixed Text information<br>Request to hide supervision limits<br>Train integrity confirmation<br>Request to show supervision limits<br>Ack of SN mode<br>Selection of Language<br>Request to show geographical position<br>Request to hide geographical position<br>“Slippery rail” selected<br>“Non slippery rail” selected<br>Level 0 selected|

<!-- end of page 31 -->

|0010 0011|Level 1 selected|
|---|---|
|0010 0100|Level 2 selected|
|0010 0101|Spare|
|0010 0110|Level NTC selected|
|0010 0111|Request to show tunnel stopping area information|
|0010 1000|Request to hide tunnel stopping area information|
|0010 1001|Scroll up button activated|
|0010 1010|Scroll down button activated|
|0010 1011|ATO "On" selected|
|0010 1100|ATO "Stand by" selected|
|0010 1101|ATO engage selected|
|0010 1110|ATO disengage selected|
|0010 1111|Request to skip ATO stopping point|
|0011 0000|Revoke skip ATO stopping point requested|
|0011 0001|Inhibition of BTM alarm reaction selected|
|0011 0010|Inhibition of BTM alarm reaction revoked|
|00110011|Radio Network type FRMCS selected|
|00110100|Radio Network type FRMCS+GSM-R selected|
|00110101|Radio Network type GSM-R selected|
|00110110<br>00110111|“Perform mission with only one radio system” selected<br>“Do not perform mission with only one radio system” selected|

#### 4.2.4.12 BALISE GROUP ERROR

|**_Description_**|This message contains a bali|se group rel|ated error as identified by M_ERROR.|
|---|---|---|---|
|**_Content_**|**Complementary Variable**|**Length**|**Comment**|
||NID_C||Defined in Chapter 7 of [1]|
||NID_ERRORBG|14||
||M_ERROR||Defined in Chapter 7 of [1]|

#### **NID_ERRORBG**

|Name|Identity number of|the balise group which tr|iggered the error|
|---|---|---|---|
|**Description**|It contains the iden<br>NID_ERRORBG is<br>the NID_ERRORB<br>and covers the cas|tity number of the balise<br>identical to NID_BG (de<br>G Special Value "16383"<br>e that, due to the error, t|group to which the error is related.<br>fined in chapter 7 of [1]) except for<br>which has the meaning "unknown"<br>he balise group identity is unknown|
|**Length of variable**|**Minimum Value**|**Maximum Value**|**Resolution/formula**|
|14 bits|0|16382|Numbers|
|**Special/reserved**<br>**value**|16383|Unknown||

<!-- end of page 32 -->

#### 4.2.4.13 RADIO ERROR

|**_Description_**|This message contains an e<br>identified by M_ERROR.|rror related|to communication with an RBC as|
|---|---|---|---|
|**_Content_**|**Complementary Variable**|**Length**|**Comment**|
||NID_C||Defined in Chapter 7 of [1]|
||NID_RBC||Defined in Chapter 7 of [1]. ETCS<br>identity (NID_C + NID_RBC) of the<br>RBC to which the error is related|
||M_ERROR||Defined in Chapter 7 of [1]|

#### 4.2.4.14 STM INFORMATION

|**Description**|This message is sent to the o<br>when certain STM packets are<br>relation to NTCs are displayed<br>connection happens.|n-board re<br>exchange<br>or a disco|cording device on an STM event, i.e.<br>d, certain system status messages in<br>nnection of the STM Control Function|
|---|---|---|---|
|**Content**|**Complementary Variable**|**Length**|**Comment**|
||NID_STMX|8|STM relevant for the event|
||NID_STMEVENT|2|STM Event type|
||M_DISCSENDER|1|If NID_STMEVENT = 0, sender of<br>disconnect request|
||M_DISCTYPE|1|If NID_STMEVENT = 0, type of<br>disconnection.|
||M_DISCREASON||If NID_STMEVENT = 0,<br>disconnection reason as defined in<br>[7], chapter 5.2.5.9 and [6] chapter<br>5.3.1.3|
||STM_SYSTEM_STATUS<br>_MESSAGE|4|If NID_STMEVENT = 1|
||NID_STMPACKET|8|If NID_STMEVENT = 2|
||If NID_STMEVENT = 2, S<br>described in Chapters 7 &|TM packet<br>8 of [2]|variables (without NID_PACKET) as|

<!-- end of page 33 -->

#### **NID_STMX**

|**Name**|STM identification|||
|---|---|---|---|
|**Description**|STM relevant for t<br>For STM-packets o<br>its value is given b|he event<br>r disconnect request<br>y the NID_STM as d|s sent from an STM or to a single STM,<br>efined in [2].|
|**Length of variable**|**Minimum Value**|**Maximum Value**|**Resolution/formula**|
|8 bits|0|254||
|**Special/reserved**<br>**value**|255|For STM-packets<br>(connected) STMs|or disconnect requests sent to all|

#### **NID_STMEVENT**

|**Name**|STM Event type||
|---|---|---|
|**Description**|||
|**Length of variable**|**Minimum Value**|**Maximum Value** **Resolution/formula**|
|2 bits|||
|**Special/reserved**|0|Disconnection|
|**value**|1|Display of system status message|
||2|Reception/sending of STM packet|
||3|Spare|

#### **M_DISCSENDER**

|**Name**|Sender of disconn|ect request|
|---|---|---|
|**Description**|Sender of disconn|ect request (STM or STM Control Function).|
|**Length of variable**|**Minimum Value**|**Maximum Value** **Resolution/formula**|
|1 bit|||
|**Special/reserved**|0|Disconnect request sent from STM|
|**value**|1|Disconnect request sent from STM Control Function|

#### **M_DISCTYPE**

|**Name**|Type of disconnect|ion|
|---|---|---|
|**Description**|Type of disconnect|ion, see [7], section 5.2.5.9 (line “New setup desired”)|
|**Length of variable**|**Minimum Value**|**Maximum Value**<br>**Resolution/formula**|
|1 bit|||
|**Special/reserved**|0|Final disconnection|
|**value**|1|Non final disconnection|

<!-- end of page 34 -->

#### **STM_SYSTEM_STATUS_MESSAGE**

|**Name**|STM SYSTEM S|TATUS MESSAGE||
|---|---|---|---|
|**Description**|System status m<br>A bit set to ‘1’<br>displayed|essage displayed to th<br>means that the corre|e driver<br>sponding system status message is|
|**Length of variable**|**Bit number**|**Definition**|**Resolution/formula**|
|4 bits||as in chapter 15<br>of [3]|Bitset<br>The least significant bit of the variable<br>corresponds to bit 01.|
|**Special/Reserved**<br>**Values**|Bit 01<br>Bit 02<br>Bit 03<br>Bit 04|NTC brake demand<br>NTC needs data<br>NTC failed<br>NTC is not available|<br>|

#### **NID_STMPACKET**

|**Name**|STM packet identif|ication|
|---|---|---|
|**Description**|STM-packet numb|er, i.e. NID_PACKET as defined in Chapter 8 of [2].|
|**Length of variable**|**Minimum Value**|**Maximum**<br>**Value**<br>**Resolution/formula**|
|8 bits|||
|**Special/reserved**|6|Override activation|
|**value**|14|State order to STM|
||15|State report from STM|
||16|Transition variables STM max speed from STM|
||17|Transition variables STM system speed and distance<br>from STM|
||18|National Trip Procedure|
||20|Antenna/BTM ID|
||21|Test Procedure Permission Request|
||22|Test Procedure Permission|
||23|End of Test Procedure|
||31|Active DMI channel|
||32|Button Request|
||34|Button event report|
||35|Indicator request|
||38|Text message|
||39|Delete text message|

<!-- end of page 35 -->

|40|Acknowledgement reply|
|---|---|
|43|Speed and distance supervision information|
|46|Sound command|
|47|ETCS BTM status message to STM|
|128|STM emergency and service brake command to brake<br>interface|
|129|STM specific brake control command|
|130|STM commands to train interface|
|161|NTC juridical data from STM|
|Other values|Spare|

#### 4.2.4.15 INFORMATION FROM COLD MOVEMENT DETECTOR

|**_Description_**|This message gives the info<br>power-up.|rmation from the cold movement detector at the|
|---|---|---|
|**_Content_**|**Complementary Variable**|**Length**<br>**Comment**|
||M_COLD_MVT|2|

#### **M_COLD_MVT**

|**Name**|Cold movement detec|tor information|
|---|---|---|
|**Description**|Indicates whether no<br>been detected or if no|cold movement has occurred or if a cold movement has<br>cold movement information is available.|
|**Length of variable**|**Minimum Value**|**Maximum Value**<br>**Resolution/formula**|
|2 bits|||
|**Special/reserved**|0|No cold movement occurred|
|**value**|1|Cold movement detected|
||2|No cold movement information available|
||3|Spare|

#### 4.2.4.16 START DISPLAYING FIXED TEXT MESSAGE

|**_Description_**|This message contains a fixe<br>being shown to the driver.|d text mess|age from the trackside that is currently|
|---|---|---|---|
|**_Content_**|**Complementary Variable**|**Length**|**Comment**|
||Q_TEXT||Defined in Chapter 7 of [1]|

#### 4.2.4.17 STOP DISPLAYING FIXED TEXT MESSAGE

<!-- end of page 36 -->

|**_Description_**|This message contains a fixe<br>shown to the driver any more.|d text me|ssage from the trackside that is not|
|---|---|---|---|
|**_Content_**|**Complementary Variable**|**Length**|**Comment**|
||Q_TEXT||Defined in Chapter 7 of [1]|

#### 4.2.4.18 START DISPLAYING PLAIN TEXT MESSAGE

|**_Description_**|This message contains a plai<br>being shown to the driver.|n text mess|age from the trackside that is currently|
|---|---|---|---|
|**_Content_**|**Complementary Variable**|**Length**|**Comment**|
||L_TEXT||Defined in Chapter 7 of [1]|
||X_TEXT(L_TEXT)||Defined in Chapter 7 of [1]|

#### 4.2.4.19 STOP DISPLAYING PLAIN TEXT MESSAGE

|**_Description_**|This message contains a plai<br>shown to the driver any more.|n text me|ssage from the trackside that is not|
|---|---|---|---|
|**_Content_**|**Complementary Variable**|**Length**|**Comment**|
||L_TEXT||Defined in Chapter 7 of [1]|
||X_TEXT(L_TEXT)||Defined in Chapter 7 of [1]|

#### 4.2.4.20 SPEED AND DISTANCE MONITORING INFORMATION

|**_Description_**|This message contains Spee<br>information displayed to the d|d and Distance m<br>river|onitoring data, in relation to the|
|---|---|---|---|
|**_Content_**|**Complementary Variable**|**Length**|**Comment**|
||M_SDMTYPE|2||
||M_SDMSUPSTAT|3||
||V_PERM|10||
||V_SBI|10||
||V_TARGET|10||
||D_TARGET|15||
||V_RELEASE|10||
||M_TTI|4||

#### **M_SDMTYPE**

|**Name**|Speed and distance monitoring type|
|---|---|
|**Description**|Type of the speed and distance monitoring|

<!-- end of page 37 -->

|**Length of variable**|**Minimum Value**|**Maximum Value**|**Resolution/formula**|
|---|---|---|---|
|2 bits||||
|**Special/reserved**|0|Ceiling speed monitoring|(CSM)|
|**value**|1|Target speed monitoring|(TSM)|
||2|Release speed monitorin|g (RSM)|
||3|Spare||

#### **M_SDMSUPSTAT**

|**Name**|Speed and distance m|onitoring supervision status|.|
|---|---|---|---|
|**Description**|Supervision status of|the speed and distance mon|itoring|
|**Length of variable**|**Minimum Value**|**Maximum Value**|**Resolution/formula**|
|3 bits||||
|**Special/reserved**|0|Normal Status||
|**value**|1|Indication Status||
||2|Overspeed Status||
||3|Warning Status||
||4|Intervention Status||
||5...7|Spare||

#### **M_TTI**

|**Name**|Time to Indication|||
|---|---|---|---|
|**Description**|Time to Indication disp<br>the DMI object (see ch|layed to the driver as per the<br>apter 8.2.2 in document [3])|size of the white square of|
|**Length of variable**|**Minimum Value**|**Maximum Value**|**Resolution/formula**|
|4 bits|5x5 cells|50x50 cells|5x5 cells|
|**Special/reserved**|0|None||
|**value**|11-15|Spare||

#### **V_PERM**

|**Name**|Permitted speed.|||
|---|---|---|---|
|**Description**|Permitted speed di|splayed to the driver||
|**Length of variable**|**Minimum Value**|**Maximum Value**|**Resolution/formula**|
|10 bits|0 km/h|600 km/h|1 km/h|
|**Special/reserved**<br>**value**|601 – 1022|Spare||

<!-- end of page 38 -->

1023 None

#### **V_SBI**

|**Name**|Service brake inter|vention speed.||
|---|---|---|---|
|**Description**|SBI speed displaye|d to the driver||
|**Length of variable**|**Minimum Value**|**Maximum Value**|**Resolution/formula**|
|10 bits|0 km/h|600 km/h|1 km/h|
|**Special/reserved**|601 – 1022|Spare||
|**value**||||
||1023|None||

#### **V_TARGET**

|**Name**|Target speed.|||
|---|---|---|---|
|**Description**|Target speed displ|ayed to the driver||
|**Length of variable**|**Minimum Value**|**Maximum Value**|**Resolution/formula**|
|10 bits|0 km/h|600 km/h|1 km/h|
|**Special/reserved**<br>**value**|601 – 1022|Spare||
||1023|None||

#### **D_TARGET**

|**Name**|Target distance.|||
|---|---|---|---|
|**Description**|Target distance dis|played to the driver||
|**Length of variable**|**Minimum Value**|**Maximum Value**|**Resolution/formula**|
|15 bits|0 m|32766 m|1 m|
|**Special/reserved**<br>**value**|32767|None||

#### **V_RELEASE**

|**Name**|Release speed.|||
|---|---|---|---|
|**Description**|Release speed dis|played to the driver.||
|**Length of variable**|**Minimum Value**|**Maximum Value**|**Resolution/formula**|
|10 bits|0 km/h|600 km/h|1 km/h|

<!-- end of page 39 -->

|**Special/reserved**|601-1022|Spare|
|---|---|---|
|**value**|||
||1023|None|

#### 4.2.4.21 DMI SYMBOL STATUS

|**_Description_**|This message contains the status|of the set of symbols that can be displayed on the|
|---|---|---|
||DMI (except planning, navigati<br>considered as relevant for juridic|on and settings related symbols that are not<br>al recording).|
|**_Content_**|**Complementary Variable**|**Length**<br>**Comment**|
||DMI_SYMB_STATUS|110|

#### **DMI_SYMB_STATUS**

|**Name**|DMI SYMBOL S|TATUS||
|---|---|---|---|
|**Description**<br>|Status of the sym<br>A bit set to ‘1’ me<br>|bols displayed to the<br>ans that the correspo<br>|driver<br>nding symbol is displayed.<br>|
|**Length of variable**|**Bit number**|**Definition**|**Resolution/formula**|
|110 bits||as in chapter 13<br>of [3]|Bitset<br>The bit 01 corresponds to the least<br>significant bit of the variable|
|**Special/Reserved**|Bit 01|LE01||
|**Values**|Bit 02|LE02||
||Bit 03|LE03||
||Bit 04|LE04||
||Bit 05|spare||
||Bit 06|LE06||
||Bit 07|LE07||
||Bit 08|LE08||
||Bit 09|LE09||
||Bit 10|LE10||
||Bit 11|spare||
||Bit 12|LE12||
||Bit 13|spare||
||Bit 14|MO23||
||Bit 15|MO24||
||Bit 16|MO01||
||Bit 17|MO02||
||Bit 18|MO03||
||Bit 19|MO04||
||Bit 20|MO05||
||Bit 21|MO06||
||Bit 22|MO07||

<!-- end of page 40 -->

|Bit 23|MO08|
|---|---|
|Bit 24|MO09|
|Bit 25|MO10|
|Bit 26|MO11|
|Bit 27|MO12<br>|
|Bit 28|MO13|
|Bit 29|MO14|
|Bit 30|MO15|
|Bit 31|MO16|
|Bit 32|MO17|
|Bit 33|MO18|
|Bit 34|MO19|
|Bit 35|MO20|
|Bit 36|MO21|
|Bit 37|MO22|
|Bit 38|ST01|
|Bit 39|ST02|
|Bit 40|ST03|
|Bit 41|ST04|
|Bit 42|ST05|
|Bit 43|ST06|
|Bit 44|TC01|
|Bit 45|TC02|
|Bit 46|TC03|
|Bit 47|TC04|
|Bit 48|TC05|
|Bit 49|TC06|
|Bit 50|TC07|
|Bit 51|TC08|
|Bit 52|TC09|
|Bit 53|TC10|
|Bit 54|TC11|
|Bit 55|TC12|
|Bit 56|TC13|
|Bit 57|TC14|
|Bit 58|TC15|
|Bit 59|TC16|
|Bit 60|TC17|
|Bit 61|TC18|
|Bit 62|TC19|
|Bit 63|TC20|
|Bit 64|TC21|
|Bit 65|TC22|
|Bit 66|TC23|
|Bit 67|TC24|
|Bit 68|TC25|
|Bit 69|TC26|

<!-- end of page 41 -->

|Bit 70|TC27|
|---|---|
|Bit 71|TC28|
|Bit 72|TC29|
|Bit 73|TC30|
|Bit 74|TC31|
|Bit 75|TC32|
|Bit 76|TC33|
|Bit 77|TC34|
|Bit 78|TC35|
|Bit 79|TC36|
|Bit 80|TC37|
|Bit 81|DR01|
|Bit 82|DR02|
|Bit 83|DR03|
|Bit 84|DR04|
|Bit 85|DR05|
|Bit 86|LX01|
|Bit 87|LS01|
|Bit 88|BTMA|
|Bit 89|ATO01|
|Bit 90|ATO02|
|Bit 91|ATO03|
|Bit 92|ATO04|
|Bit 93|ATO05|
|Bit 94|ATO06|
|Bit 95|ATO07|
|Bit 96|ATO08|
|Bit 97|ATO09|
|Bit 98|ATO10|
|Bit 99|ATO11|
|Bit 100|ATO12|
|Bit 101|ATO13|
|Bit 102|ATO14|
|Bit 103|ATO15|
|Bit 104|ATO16|
|Bit 105|ATO17|
|Bit 106|ATO18|
|Bit 107|ATO19|
|Bit 108|ATO20|
|Bit 109|SM01|
|Bit 110|SM02|

<!-- end of page 42 -->

#### 4.2.4.22 DMI SOUND STATUS

|**_Description_**|This message contains the stat<br>attention from the outside to the|us of the sounds that are used to draw the driver’s<br>display.|
|---|---|---|
|**_Content_**|**Complementary Variable**|**Length**<br>**Comment**|
||DMI_SOUND_STATUS|3|

#### **DMI_SOUND_STATUS**

|**Name**|DMI SOUND ST|ATUS||
|---|---|---|---|
|**Description**|Status of the aud<br>A bit set to ‘1’ me|ible information play<br>ans that the corresp|ed to the driver<br>onding sound is generated|
|**Length of variable**|**Bit number**|**Definition**|**Resolution/formula**|
|3 bits||as in chapter 1<br>of [3]|4<br>Bitset<br>The bit 01 corresponds to the least<br>significant bit of the variable|
|**Special/Reserved**<br>**Values**|Bit 01<br>Bit 02<br>Bit 03|Sound Sinfo - Info<br>Sound S1 – Over-<br>Sound S2 – Warn|rmation on DMI<br>speed<br>ing|

#### 4.2.4.23 DMI SYSTEM STATUS MESSAGE

|**_Description_**|This message contains which sys|tem status messa|ges are displayed to the driver|
|---|---|---|---|
|**_Content_**|**Complementary Variable**|**Length**|**Comment**|
||SYSTEM_STATUS_MESSAGE|29||

#### **SYSTEM_STATUS_MESSAGE**

|**Name**|SYSTEM STATU|S MESSAGE||
|---|---|---|---|
|**Description**|System status m<br>A bitset to ‘1’<br>displayed|essage displayed to t<br>means that the corr|he driver<br>esponding system status message is|
|**Length of variable**|**Bit number**|**Definition**|**Resolution/formula**|
|31 bits||as in chapter 15<br>of [3]|Bitset<br>The least significant bit of the variable<br>corresponds to bit 01.|
|**Special/Reserved**<br>**Values**|Bit 01<br>Bit 02<br>Bit 03<br>Bit 04<br>Bit 05|Balise read error<br>Trackside malfunct<br>Communication err<br>Entering FS<br>Entering OS|ion<br>or|

<!-- end of page 43 -->

|Bit 06|Runaway movement|
|---|---|
|Bit 07|SH refused|
|Bit 08|SH request failed|
|Bit 09|Trackside not compatible|
|Bit 10|Train data changed|
|Bit 11|Train is rejected|
|Bit 12|Unauthorized passing of EOA / LOA|
|Bit 13|No MA received at level transition|
|Bit 14|SR distance exceeded|
|Bit 15|SH stop order|
|Bit 16|SR stop order|
|Bit 17|Emergency stop|
|Bit 18|RV distance exceeded|
|Bit 19|No track description|
|Bit 20|Route unsuitable – axle load category|
|Bit 21|Route unsuitable – loading gauge|
|Bit 22|Route unsuitable – traction system|
|Bit 23|GSM-R network registration failed|
|Bit 24|FRMCS network registration failed|
|Bit 25|PT distance exceeded|
|Bit 26|NL no longer permitted|
|Bit 27|Odometer impaired|
|Bit 28|SM refused|
|Bit 29|SM request failed|
|Bit 30|Entering SM|
|Bit 31|Safe consist length no longer available|

#### 4.2.4.24 RBC CONTACT INFORMATION ENTERED BY THE DRIVER

|**_Description_**|This message contains the RB|C contact info|rmation entered by the driver.|
|---|---|---|---|
|**_Content_**|**Complementary Variable**|**Length**|**Comment**|
||Q_RBCENTRY|2||
||NID_C||Only if Q_RBCENTRY = 2 or 3<br>Identity of the country or region<br>complementing<br>the<br>RBC<br>identity<br>number. Defined in chapter 7 of [1]|
||NID_RBC||Only if Q_RBCENTRY = 2 or 3<br>RBC ETCS identity number. Defined<br>in Chapter 7 of [1]|
||NID_RADIO||Only if Q_RBCENTRY = 3<br>Radio subscriber number. Defined in<br>Chapter 7 of [1]|

<!-- end of page 44 -->

#### **Q_RBCENTRY**

|**Name**|Qualifier for the RB|C contact information||
|---|---|---|---|
|**Description**|This variable indica|tes the type of driver’s s|election for the RBC data|
|**Length of variable**|**Minimum Value**|**Maximum Value**|**Resolution/formula**|
|2 bit||||
|**Special/reserved**<br>|0|Contact last known RB|C|
|**value**|1|Use short number||
||2|Enter RBC data (Ra<br>FRMCS+GSM-R while|dio Network type = FRMCS or<br>only FRMCS installed on-board)|
||3|Enter RBC data (Ra<br>FRMCS+GSM-R while|dio Network type = GSM-R or<br>GSM-R is installed on-board)|

#### 4.2.4.25 SR SPEED/DISTANCE ENTERED BY THE DRIVER

|**_Description_**|This message contains the ch<br>driver.|ange of the SR S|peed or Distance entered by the|
|---|---|---|---|
|**_Content_**|**Complementary Variable**|**Length**|**Comment**|
||D_SR|17||
||V_SR|10||

#### **D_SR**

|**Name**|Staff Responsible|distance.||
|---|---|---|---|
|**Description**|Distance allowed r<br>the DMI. The ma<br>appropriate from o|unning in Staff Responsib<br>ximum value correspond<br>perational point of view.|le, modified by the driver through<br>s to the one that is considered|
|**Length of variable**|**Minimum Value**|**Maximum Value**|**Resolution/formula**|
|17 bits|0 m|100000 m|1 m|
|Special/reserved<br>value|100001-131071|Spare||

<!-- end of page 45 -->

#### **V_SR**

|**Name**|Staff Responsible|speed||
|---|---|---|---|
|**Description**|Speed allowed run<br>DMI.|ning in Staff Responsibl|e, modified by the driver through the|
|**Length of variable**|**Minimum Value**|**Maximum Value**|**Resolution/formula**|
|10 bits|0 km/h|600 km/h|1 km/h|
|Special/reserved<br>value|601-1023|Spare||

#### 4.2.4.26 NTC SELECTED

|**_Description_**|This message contains the id|entity of the|NTC when the selected level is NTC.|
|---|---|---|---|
|**_Content_**|**Complementary Variable**|**Length**|**Comment**|
||NID_NTC||Defined in Chapter 7 of [1].|

#### 4.2.4.27 SAFETY CRITICAL FAULT IN MODE SL, NL OR PS

|**_Description_**|This message records the oc<br>or PS.|currence of a safety critical fault in mode SL, NL|
|---|---|---|
|**_Content_**|**Complementary Variable**|**Length**<br>**Comment**|
||Null||

#### 4.2.4.28 VIRTUAL BALISE COVER SET BY THE DRIVER

|**_Description_**|This message reflects the cod|e entered|by the driver to set a VBC.|
|---|---|---|---|
|**_Content_**|**Complementary Variable**|**Length**|**Comment**|
||NID_VBCMK||Defined in Chapter 7 of [1].|
||NID_C||Defined in Chapter 7 of [1].|
||T_VBC||Defined in Chapter 7 of [1].|

#### 4.2.4.29 VIRTUAL BALISE COVER REMOVED BY THE DRIVER

|**_Description_**|This message reflects the cod|e entered|by the driver to remove a VBC.|
|---|---|---|---|
|**_Content_**|**Complementary Variable**|**Length**|**Comment**|
||NID_C||Defined in Chapter 7 of [1].|
||NID_VBCMK||Defined in Chapter 7 of [1].|

<!-- end of page 46 -->

#### 4.2.4.30 SLEEPING INPUT

|**_Description_**|This message allows to trans|mit the state of the sleeping input (see [4] 2.2.1).|
|---|---|---|
|**_Content_**|**Complementary Variable**|**Length**<br>**Comment**|
||M_SLEEPING|1|

#### **M_SLEEPING**

|**Name**|Sleeping input stat|e||
|---|---|---|---|
|**Description**|This variable conta|ins the state of the sleepin|g input.|
|**Length of variable**|**Minimum Value**|**Maximum Value**|**Resolution/formula**|
|1 bit||||
|**Special/reserved**<br>|0|Sleeping not requested||
|**value**|1|Sleeping requested||

#### 4.2.4.31 PASSIVE SHUNTING INPUT

|**_Description_**|This message allows to trans<br>2.2.2).|mit the state of the passive shunting input (see [4]|
|---|---|---|
|**_Content_**|**Complementary Variable**|**Length**<br>**Comment**|
||M_PASSIVE_SHUNTING|1|

#### **M_PASSIVE_SHUNTING**

|**Name**|Passive shunting in|put state|
|---|---|---|
|**Description**|This variable conta|ins the state of the passive shunting input.|
|**Length of variable**|**Minimum Value**|**Maximum Value**<br>**Resolution/formula**|
|1 bit|||
|**Special/reserved**<br>|0|Passive shunting not permitted|
|**value**|1|Passive shunting permitted|

#### 4.2.4.32 NON LEADING INPUT

|**_Description_**|This message allows to tran<br>2.2.3).|smit the state of the non leading input (see [4]|
|---|---|---|
|**_Content_**|**Complementary Variable**|**Length**<br>**Comment**|
||M_NON_LEADING|1|

<!-- end of page 47 -->

#### **M_NON_LEADING**

|**Name**|Non leading input s|tate||
|---|---|---|---|
|**Description**|This variable conta|ins the state of the non le|ading input.|
|**Length of variable**|**Minimum Value**|**Maximum Value**|**Resolution/formula**|
|1 bit||||
|**Special/reserved**<br>|0|Non leading not permitt|ed|
|**value**|1|Non leading permitted||

#### 4.2.4.33 REGENERATIVE BRAKE STATUS

|**_Description_**|This message allows to trans|mit the regenerative brake status (see [4] 2.3.6).|
|---|---|---|
|**_Content_**|**Complementary Variable**|**Length**<br>**Comment**|
||M_RB_STATUS|1|

#### **M_RB_STATUS**

|**Name**|Status of the regen|erative brake||
|---|---|---|---|
|**Description**|This variable conta|ins the status of the reg|enerative brake|
|**Length of variable**|**Minimum Value**|**Maximum Value**|**Resolution/formula**|
|1 bit||||
|**Special/reserved**|0|Not active||
|**value**|1|Active||

#### 4.2.4.34 MAGNETIC SHOE BRAKE STATUS

|**_Description_**|This message allows to trans|mit the magnetic shoe brake status (see [4] 2.3.6).|
|---|---|---|
|**_Content_**|**Complementary Variable**|**Length**<br>**Comment**|
||M_MSB_STATUS|1|

#### **M_MSB_STATUS**

|**Name**|Status of the magn|etic shoe brake||
|---|---|---|---|
|**Description**|This variable conta|ins the status of the ma|gnetic shoe brake|
|**Length of variable**|**Minimum Value**|**Maximum Value**|**Resolution/formula**|
|1 bit||||
|**Special/reserved**|0|Not active||
|**value**|1|Active||

<!-- end of page 48 -->

#### 4.2.4.35 EDDY CURRENT BRAKE STATUS

|**_Description_**|This message allows to trans|mit the eddy current brake status (see [4] 2.3.6).|
|---|---|---|
|**_Content_**|**Complementary Variable**|**Length**<br>**Comment**|
||M_ECB_STATUS|1|

#### **M_ECB_STATUS**

|**Name**|Status of the eddy|current brake|
|---|---|---|
|**Description**|This variable conta|ins the status of the eddy current brake|
|**Length of variable**|**Minimum Value**|**Maximum Value**<br>**Resolution/formula**|
|1 bit|||
|**Special/reserved**|0|Not active|
|**value**|1|Active|

#### 4.2.4.36 ELECTRO PNEUMATIC BRAKE STATUS

|**_Description_**|This message allows to tran<br>2.3.6).|smit the electro pneumatic brake status (see [4]|
|---|---|---|
|**_Content_**|**Complementary Variable**|**Length**<br>**Comment**|
||M_EP_STATUS|1|

#### **M_EP_STATUS**

|**Name**|Status of the electr|o pneumatic brake||
|---|---|---|---|
|**Description**|This variable conta|ins the status of the ele|ctro pneumatic brake|
|**Length of variable**|**Minimum Value**|**Maximum Value**|**Resolution/formula**|
|1 bit||||
|**Special/reserved**|0|Not active||
|**value**|1|Active||

#### 4.2.4.37 ADDITIONAL BRAKE STATUS

|**_Description_**|This message allows to trans|mit the additional brake status (see [4] 2.3.7).|
|---|---|---|
|**_Content_**|**Complementary Variable**|**Length**<br>**Comment**|
||M_AB_STATUS|1|

<!-- end of page 49 -->

#### **M_AB_STATUS**

|**Name**|Status of the additi|onal brakes||
|---|---|---|---|
|**Description**|This variable conta|ins the status of the ad|ditional brakes|
|**Length of variable**|**Minimum Value**|**Maximum Value**|**Resolution/formula**|
|1 bit||||
|**Special/reserved**|0|Not active||
|**value**|1|Active||

#### 4.2.4.38 CAB STATUS

|**_Description_**|This message allows to trans<br>received from the train interfa|mit the cab<br>ce (see [4]|status that the ERTMS/ETCS onboard<br>2.5.1).|
|---|---|---|---|
|**_Content_**|**Complementary Variable**|**Length**|**Comment**|
||M_CAB_A_STATUS|1||
||Q_CAB_B|1||
||M_CAB_B_STATUS|1|Only if Q_CAB_B = 1|

#### **M_CAB_A_STATUS**

|**Name**|Cab A status|||
|---|---|---|---|
|**Description**|This variable conta<br>connected to only o|ins the cab A status. In<br>ne cab, this cab is cons|case the ERTMS/ETCS onboard is<br>idered as being the cab A.|
|**Length of variable**|**Minimum Value**|**Maximum Value**|**Resolution/formula**|
|1 bit||||
|**Special/reserved**|0|Not active||
|**value**|1|Active||

#### **Q_CAB_B**

|**Name**|Qualifier for cab B|||
|---|---|---|---|
|**Description**|Qualifier to indicate<br>onboard.|whether a second cab|is connected to the ERTMS/ETCS|
|**Length of variable**|**Minimum Value**|**Maximum Value**|**Resolution/formula**|
|1 bit||||
|**Special/reserved**|0|No||
|**value**|1|Yes||

<!-- end of page 50 -->

#### **M_CAB_B_STATUS**

|**Name**|Cab B status|||
|---|---|---|---|
|**Description**|This variable conta|ins the cab B status.||
|**Length of variable**|**Minimum Value**|**Maximum Value**|**Resolution/formula**|
|1 bit||||
|**Special/reserved**|0|Not active||
|**value**|1|Active||

#### 4.2.4.39 DIRECTION CONTROLLER POSITION

|**_Description_**|This message allows to transm|it the direction controller position (see [4] 2.5.2).|
|---|---|---|
|**_Content_**|**Complementary Variable**|**Length**<br>**Comment**|
||M_DIRECTION_CONTROLL<br>ER|2|

#### **M_DIRECTION_CONTROLLER**

|**Name**|Direction controller|state||
|---|---|---|---|
|**Description**|This variable conta|ins the direction controller|input state.|
|**Length of variable**|**Minimum Value**|**Maximum Value**|**Resolution/formula**|
|2 bits||||
|**Special/reserved**|00|Neutral||
|**value**|01|Backward||
||10|Forward||
||11|Spare||

#### 4.2.4.40 TRACTION STATUS

|**_Description_**|This message allows to trans|mit the traction status (see [4] 2.5.4).|
|---|---|---|
|**_Content_**|**Complementary Variable**|**Length**<br>**Comment**|
||M_TRACTION_STATUS|1|

<!-- end of page 51 -->

#### **M_TRACTION_STATUS**

|**Name**|Traction status|||
|---|---|---|---|
|**Description**|This variable conta|ins the traction status||
|**Length of variable**|**Minimum Value**|**Maximum Value**|**Resolution/formula**|
|1 bit||||
|**Special/reserved**|0|Off||
|**value**|1|On||

#### 4.2.4.41 TYPE OF TRAIN DATA ENTRY

|**_Description_**|This message allows to trans|mit the type of train data entry (see [4] 2.6.1).|
|---|---|---|
|**_Content_**|**Complementary Variable**|**Length**<br>**Comment**|
||M_TRAIN_DATA_ENTRY|2|

#### **M_TRAIN_DATA_ENTRY**

|**Name**|Type of train data|entry||
|---|---|---|---|
|**Description**|This variable conta|ins the type of train dat|a entry|
|**Length of variable**|**Minimum Value**|**Maximum Value**|**Resolution/formula**|
|2 bit||||
|**Special/reserved**|0|Fixed||
|**value**|1|Flexible||
||2|Switchable||
||3|Spare||

#### 4.2.4.42 NATIONAL SYSTEM ISOLATION

|**_Description_**|This message allows to transmit the ind<br>interfaced to the on-board through an S|ication tha<br>TM, is iso|t a National System, which is<br>lated or not (see [4] 2.7).|
|---|---|---|---|
|**_Content_**|**Complementary Variable**|**Length**|**Comment**|
||NID_NTC||Defined in [1]|
||M_NATIONAL_SYSTEM_ISOLATION|1||

<!-- end of page 52 -->

#### **M_NATIONAL_SYSTEM_ISOLATION**

|**Name**|Isolation of the Nat|ional System||
|---|---|---|---|
|**Description**|This variable conta|ins the indication of iso|lation of the National System|
|**Length of variable**|**Minimum Value**|**Maximum Value**|**Resolution/formula**|
|1 bit||||
|**Special/reserved**|0|NTC isolated||
|**value**|1|NTC not isolated||

#### 4.2.4.43 TRACTION CUT OFF COMMAND STATE

|**_Description_**|This message allows to transmi<br>2.4.9)|t the tracti|on cut off command state (see [4]|
|---|---|---|---|
|**_Content_**|**Complementary Variable**|**Length**|**Comment**|
||M_TCO_COMMAND_STATE|1||

#### **M_TCO_COMMAND_STATE**

|**Name**|Traction cut off co|mmand state||
|---|---|---|---|
|**Description**|This variable conta|ins the command state|of the traction cut off.|
|**Length of variable**|**Minimum Value**|**Maximum Value**|**Resolution/formula**|
|1 bit||||
|**Special/reserved**|0|Not commanded||
|**value**|1|Commanded||

4.2.4.44 LOWEST SUPERVISED SPEED WITHIN THE MOVEMENT AUTHORITY

|**_Description_**|This message allows to transm|it the LSSMA|displayed to the driver|
|---|---|---|---|
|**_Content_**|**Complementary Variable**|**Length**|**Comment**|
||V_LSSMA|10||

#### **V_LSSMA**

|**Name**|Lowest Speed Sup|ervised within the Move|ment Authority.|
|---|---|---|---|
|**Description**|LSSMA displayed t|o the driver.||
|**Length of variable**|**Minimum Value**|**Maximum Value**|**Resolution/formula**|
|10 bits|0 km/h|600 km/h|1 km/h|
|**Special/reserved**|601-1022|Spare||
|**value**|1023|None||

<!-- end of page 53 -->

#### 4.2.4.45 TRACK CONDITIONS

|**_Description_**<br>|This message allows to trans<br>(see [4] 2.3.4, 2.4.1, 2.4.2, 2.4.<br>|mit the inf<br>4, 2.4.6, 2<br>|ormation related to track condition(s)<br>.4.7 and 2.4.10).<br>|
|---|---|---|---|
|**_Content_**|**Complementary Variable**|**Length**|**Comment**|
||Q_SCALE||Defined in Chapter 7 of [1]|
||N_TRACKCOND_TI|5||
||M_TRACKCOND_TI(k)|4||
||D_MINSFE_TO_END(k)|16|Only if M_TRACKCOND_TI = 0, 1 or<br>9|
||D_MINSRE_TO_END(k)|15|Only if M_TRACKCOND_TI = 2, 3, 4,<br>5 or 6|
||M_VOLTAGE(k)||Only if M_TRACKCOND_TI = 7.<br>Defined in Chapter 7 of [1]|
||NID_CTRACTION(k)||Only if M_VOLTAGE ≠ 0. Defined in<br>Chapter 7 of [1]|
||M_CURRENT(k)||Only if M_TRACKCOND_TI = 8.<br>Defined in Chapter 7 of [1]|
||M_PLATFORM(k)||Only if M_TRACKCOND_TI = 9.<br>Defined in Chapter 7 of [1]|
||Q_PLATFORM(k)||Only if M_TRACKCOND_TI = 9.<br>Defined in Chapter 7 of [1]|
||D_MAXSFE_TO_START(k)|16||

#### **N_ TRACKCOND_TI**

|**Name**|Number of track co|nditions||
|---|---|---|---|
|**Description**|Number of track co|nditions following this v|ariable in the message.|
|**Length of variable**|**Minimum Value**|**Maximum Value**|**Resolution/formula**|
|5 bits|1|27||
|**Special/reserved**|0|Spare||
|**value**|28-31|Spare||

<!-- end of page 54 -->

#### **M_TRACKCOND_TI**

|**Name**|Type of track cond|ition|
|---|---|---|
|**Description**|Defines the type of|track condition the information relates to|
|**Length of variable**|**Minimum Value**|**Maximum**<br>**Value**<br>**Resolution/formula**|
|4 bits|||
|**Special/reserved**|0|Powerless section with pantograph to be lowered|
|**value**|1|Powerless section with main power switch to be switched<br>off|
||2|Air tightness area|
||3|Inhibition of regenerative brake|
||4|Inhibition of magnetic shoe brake|
||5|Inhibition of eddy current brake for emergency brake|
||6|Inhibition of eddy current brake for service brake|
||7|Change of traction system|
||8|Change of allowed current consumption|
||9|Station platform|
||10-15|Spare|

#### **D_MAXSFE_TO_START**

|**Name**|Distance from train|max safe front end to sta|rt location of a track condition.|
|---|---|---|---|
|**Description**|Remaining distanc<br>track condition.|e from the train max safe|front end to the start location of a|
|**Length of variable**|**Minimum Value**|**Maximum Value**|**Resolution/formula**|
|16 bits|-327.670 km|327.670 km|10 cm, 1m or 10 m depending<br>on Q_SCALE.|
|**Special/reserved**<br>**value**|-32768|Not relevant||

<!-- end of page 55 -->

#### **D_MINSFE_TO_END**

|**Name**|Distance from train|min safe front end to e|nd location of a track condition.|
|---|---|---|---|
|**Description**|Remaining distanc<br>track condition.|e from the train min sa|fe front end to the end location of a|
|**Length of variable**|**Minimum Value**|**Maximum Value**|**Resolution/formula**|
|16 bits|-327.680 km|327.670 km|10 cm, 1m or 10 m depending<br>on Q_SCALE|

#### **D_MINSRE_TO_END**

|**Name**|Distance from train|min safe rear end to en|d|location of a track condition.|
|---|---|---|---|---|
|**Description**|Remaining distanc<br>track condition.|e from the train min saf|e|rear end to the end location of a|
|**Length of variable**|**Minimum Value**|**Maximum Value**||**Resolution/formula**|
|15 bits|0 m|327.670 km||10 cm, 1m or 10 m depending<br>on Q_SCALE|

#### 4.2.4.46 SET SPEED

|**_Description_**|This message allows to transm|it the Set Sp|eed displayed to the driver|
|---|---|---|---|
|**_Content_**|**Complementary Variable**|**Length**|**Comment**|
||V_SETSPEED|10||

#### **V_SETSPEED**

|**Name**|Set Speed.|||
|---|---|---|---|
|**Description**|Set Speed display|ed to the driver.||
|**Length of variable**|**Minimum Value**|**Maximum Value**|**Resolution/formula**|
|10 bits|0 km/h|600 km/h|1 km/h|
|**Special/reserved**|601-1022|Spare||
|**value**|1023|None||

<!-- end of page 56 -->

#### 4.2.4.47 BRAKE AND TRACTION INTERFACE CONFIGURATION

|**_Description_**|This message contains the configu<br>service brake command, the servic<br>eddy current brake, the magnetic<br>special/additional brake independen<br>off command.|ration of the Train Interface with regards to the<br>e brake feedback, the regenerative brake, the<br>shoe brake, the electro pneumatic brake, the<br>t from wheel/rail adhesion and the traction cut-|
|---|---|---|
|**_Content_**|**Complementary Variable**|**Length**<br>**Comment**|
||Q_SERVICEBRAKEINTERFACE|1|
||Q_SERVICEBRAKEFEEDBACK|1|
||M_REGENERATIVEBRAKE|2|
||M_EDDYCURRENTBRAKE|2|
||M_MAGNETICSHOEBRAKE|2|
||M_ELECTROPNEUMATICBRAKE|2|
||Q_SPECADDBRAKEINDADH|1|
||Q_TRACTIONCUTOFFINTERFA<br>CE|1|

#### **Q_SERVICEBRAKEINTERFACE**

|**Name**|Qualifier for service|brake interface|
|---|---|---|
|**Description**|Indicates whether t|he service brake command is implemented or no.|
|**Length of variable**|**Minimum Value**|**Maximum Value**<br>**Resolution/formula**|
|1 bit|||
|**Special/Reserved**|0|Not implemented|
|**Values**|1|Implemented|

#### **Q_SERVICEBRAKEFEEDBACK**

|**Name**|Qualifier for service|brake feedback interface||
|---|---|---|---|
|**Description**|Indicates whether t|he service brake feedback is|implemented or not.|
|**Length of variable**|**Minimum Value**|**Maximum Value**|**Resolution/formula**|
|1 bit||||
|**Special/Reserved**|0|Not implemented||
|**Values**|1|Implemented||

<!-- end of page 57 -->

#### **M_REGENERATIVEBRAKE**

|**Name**|Regenerative brake|interface|
|---|---|---|
|**Description**|It describes the int<br>braking curve calcu|erface with regenerative brake and whether it affects the<br>lation.|
|**Length of variable**|**Minimum Value**|**Maximum Value**<br>**Resolution/formula**|
|2 bits|||
|**Special/Reserved**|00|No interface|
|**Values**|01|Interface exists and affects only EB|
||10|Interface exists and affects only SB|
||11|Interface exists and affects EB and SB|

#### **M_EDDYCURRENTBRAKE**

|**Name**|Eddy current brake|interface|
|---|---|---|
|**Description**|Describes the inte<br>braking curve calcu|rface with eddy current brake and whether it affects the<br>lation.|
|**Length of variable**|**Minimum Value**|**Maximum Value**<br>**Resolution/formula**|
|2 bits|||
|**Special/Reserved**|00|No interface|
|**Values**|01|Interface exists and affects only EB|
||10|Interface exists and affects only SB|
||11|Interface exists and affects EB and SB|

#### **M_MAGNETICSHOEBRAKE**

|**Name**|Magnetic shoe bra|ke interface|
|---|---|---|
|**Description**|Describes the inter<br>braking curve calcu|face with magnetic shoe brake and whether it affects the<br>lation.|
|**Length of variable**|**Minimum Value**|**Maximum Value**<br>**Resolution/formula**|
|2 bits|||
|**Special/Reserved**|00|No interface|
|**Values**|01|Interface exists and affects only EB|
||10|Spare|
||11|Spare|

<!-- end of page 58 -->

#### **M_ELECTROPNEUMATICBRAKE**

|**Name**|Electro pneumatic|brake interface||
|---|---|---|---|
|**Description**|Describes the inter<br>braking curve calcu|face with electro pneumati<br>lation.|c brake and whether it affects the|
|**Length of variable**|**Minimum Value**|**Maximum Value**|**Resolution/formula**|
|2 bits||||
|**Special/Reserved**|00|No interface||
|**Values**|01|Interface exists and aff|ects onlySB|
||10|Interface exists and aff|ects EB and SB|
||11|Spare||

#### **Q_SPECADDBRAKEINDADH**

|**Name**|Qualifier for specia|l/additional brake interface||
|---|---|---|---|
|**Description**|Indicates whether<br>from wheel/rail adh|the interface with a special/a<br>esion is implemented or not.|dditional brake independent|
|**Length of variable**|Minimum Value|Maximum Value|Resolution/formula|
|1 bit||||
|**Special/Reserved**|0|Not implemented||
|**Values**|1|Implemented||

#### **Q_TRACTIONCUTOFFINTERFACE**

|**Name**|Qualifier for traction|cut off interface||
|---|---|---|---|
|**Description**|Indicates whether t|he traction cut off comman|d is implemented or not.|
|**Length of variable**|**Minimum Value**|**Maximum Value**|**Resolution/formula**|
|1 bit||||
|**Special/Reserved**|0|Not implemented||
|**Values**|1|Implemented||

#### 4.2.4.48 GSM-R RADIO NETWORK ID ENTERED BY THE DRIVER

|**_Description_**|This message contains the GSM-|R Radio Net|work ID entered by the driver.|
|---|---|---|---|
|**_Content_**|**Complementary Variable**|**Length**|**Comment**|
||NID_MN||Identity of GSM-R Radio Network.|
||||Defined in Chapter 7 of [1]|

<!-- end of page 59 -->

#### 4.2.4.49 TRAIN RUNNING NUMBER ENTERED BY THE DRIVER

|**_Description_**|This message contains the Train R|unning Nu|mber entered by the driver.|
|---|---|---|---|
|**_Content_**|**Complementary Variable**|**Length**|**Comment**|
||NID_OPERATIONAL||Train Running Number. Defined in|
||||Chapter 7 of [1]|

#### 4.2.4.50 TRAIN INTEGRITY INFORMATION

|**_Description_**|This message contains the train<br>interface (see [4] 2.5.3).|integrity|information|received from the train|
|---|---|---|---|---|
|**_Content_**|**Complementary Variable**|**Length**||**Comment**|
||M_TRAIN_INTEGRITY_INFO|2|||

#### **M_TRAIN_INTEGRITY_INFO**

|**Name**|Train integrity infor|mation|
|---|---|---|
|**Description**|This variable conta|ins the train integrity information|
|**Length of variable**|**Minimum Value**|**Maximum Value**<br>**Resolution/formula**|
|2 bits|||
|**Special/reserved**|0|Train integrity confirmed|
|**value**|1|Train integrity lost|
||2|Train integrity status unknown|

#### 4.2.4.51 REMOTE SHUNTING STATE

|**_Description_**|This message records the output<br>4.4.8.1.4).|permitting|remote shunting operation (see [1]|
|---|---|---|---|
|**_Content_**|**Complementary Variable**|**Length**|**Comment**|
||M_REMOTE_SHUNTING_STA<br>TE|1||

#### **M_REMOTE_SHUNTING_STATE**

|**Name**|Remote shunting s|tate||
|---|---|---|---|
|**Description**|It contains the stat|e permitting remote shu|nting.|
|**Length of variable**|**Minimum Value**|**Maximum Value**|**Resolution/formula**|
|1 bit||||
|**Special/reserved**|0|Not permitting remote|shunting|
|**value**|1|Permitting remote shu|nting|

<!-- end of page 60 -->

#### 4.2.4.52 ODOMETER ACCURACY MONITORING ERROR

|**_Description_**|This message contains an err|or related to o|dometer accuracy monitoring|
|---|---|---|---|
|**_Content_**|**Complementary Variable**|**Length**|**Comment**|
||M_ERROR||Defined in Chapter 7 of [1]|

#### 4.2.4.53 TARGET ADVICE SPEED

|**_Description_**|This message allows to transm<br>driver|it the Targ|et Advice Speed displayed to the|
|---|---|---|---|
|**_Content_**|**Complementary Variable**|**Length**|**Comment**|
||V_TARGETADVICESPEED|10||

#### **V_TARGETADVICESPEED**

|**Name**|Target Advice Spe|ed.||
|---|---|---|---|
|**Description**|Target Advice Spe|ed displayed to the driver.||
|**Length of variable**|**Minimum Value**|**Maximum Value**|**Resolution/formula**|
|10 bits|0 km/h|600 km/h|1 km/h|
|**Special/reserved**|601-1022|Spare||
|**value**|1023|None||

<!-- end of page 61 -->

#### 4.2.4.54 OVERALL CONSIST LENGTH

|**_Description_**|This message allows to transmit the|safe consis|t length input (see [4] 2.6.2)|
|---|---|---|---|
|**_Content_**|**Complementary Variable**|**Length**|**Comment**|
||Q_OVCONSISTLENGTH||Defined<br>by<br>analogy<br>to<br>7.5.1.112.1 of [1].|
||L_CONSISTFRONTCABANOM||Defined<br>by<br>analogy<br>to<br>7.5.1.42.3<br>of<br>[1].<br>This<br>variable<br>exists<br>only<br>if<br>Q_OVCONSISTLENGTH is<br>equal to value 1|
||L_CONSISTFRONTCABAMIN||Defined<br>by<br>analogy<br>to<br>7.5.1.42.2<br>of<br>[1].<br>This<br>variable<br>exists<br>only<br>if<br>Q_OVCONSISTLENGTH is<br>equal to value 1|
||L_CONSISTFRONTCABAMAX||Defined<br>by<br>analogy<br>to<br>7.5.1.42.1<br>of<br>[1].<br>This<br>variable<br>exists<br>only<br>if<br>Q_OVCONSISTLENGTH is<br>equal to value 1|
||L_CONSISTREARCABANOM||Defined<br>by<br>analogy<br>to<br>7.5.1.42.6<br>of<br>[1].<br>This<br>variable<br>exists<br>only<br>if<br>Q_OVCONSISTLENGTH is<br>equal to value 1|
||L_CONSISTREARCABAMIN||Defined<br>by<br>analogy<br>to<br>7.5.1.42.5<br>of<br>[1].<br>This<br>variable<br>exists<br>only<br>if<br>Q_OVCONSISTLENGTH is<br>equal to value 1|
||L_CONSISTREARCABAMAX||Defined<br>by<br>analogy<br>to<br>7.5.1.42.4<br>of<br>[1].<br>This<br>variable<br>exists<br>only<br>if<br>Q_OVCONSISTLENGTH is<br>equal to value 1|

<!-- end of page 62 -->

#### 4.2.4.255 ETCS ON-BOARD PROPRIETARY JURIDICAL DATA

|**_Description_**|This message allows to record information that is specific to an ETCS on-board|
|---|---|
||equipment<sup>1</sup>.|
|**_Content_**|Proprietary data|

> 1 If needed, the non harmonised information referred to in [4] can be included in this message.

<!-- end of page 63 -->

## **4.3 Triggering events list**

4.3.1.1 The following table gives the list of events that trigger the sending of a juridical data message by the ERTMS/ETCS on-board equipment.

|**TRIGGERING EVENT**|**NID_MESSAGE**|
|---|---|
|Every 5 seconds|1|
|When the operated system version changes|1|
|When the level changes|1 (and 26 when level<br>changes to NTC)|
|When the mode changes|1|
|When train data are validated at SoM|2|
|When train data are changed|2|
|When the state of the emergency brake command changes|3|
|When the state of the service brake command changes|4|
|When a telegram from an Eurobalise is received|6|
|When a message from an Euroloop is received|7|
|When a message from a RIU is received|8|
|When a message to a RIU is sent|5|
|When a message from a RBC is received|9|
|When a message to a RBC is sent|10|
|When a balise group error is detected|12|
|When a radio message error is detected|13|
|When a safety critical fault in mode SL, NL or PS occurs|27|
|At start up<sup>2</sup>|15, 47|
|When the driver acts on the on-board system through the<br>DMI|11|
|When a fixed text message is shown to the driver|16|

> 2 i.e. once the ERTMS/ETCS on-board is powered up, when the connection with the On-board Recording Device is established.

<!-- end of page 64 -->

|When a fixed text message is not shown any more to the<br>driver|17|
|---|---|
|When a plain text message is shown to the driver|18|
|When a plain text message is not shown any more to the<br>driver|19|
|When any of the speed and distance monitoring information<br>changes|20|
|When the LSSMA appears, changes or disappears on the<br>DMI|44|
|When the Set Speed appears, changes or disappears on the<br>DMI|46|
|When the Target Advice Speed appears, changes or<br>disappears on the DMI|53|
|When any of the DMI symbols appears or disappears|21|
|When the playing of any audible information to the driver is<br>started|22|
|When any of the system status messages appears or<br>disappears on the DMI|23|
|When any of the STM related system status messages<br>appears or disappears on the DMI|14|
|When the driver selects “Contact last known RBC”, “Use<br>short number” or when the driver has entered/re-<br>entered/revalidated the RBC data|24|
|When the driver has entered a GSM-R Radio Network ID|48|
|When the driver has entered/re-entered/revalidated the<br>Train Running Number|49|
|When the driver changes the SR speed/distance|25|
|When the driver sets a Virtual Balise Cover|28|
|When the driver removes a Virtual Balise Cover|29|
|In any of the following events<br>•<br>At start up<sup>2</sup><br>•<br>When the sleeping input state changes|30|

<!-- end of page 65 -->

|In any of the following events|31|
|---|---|
|•<br>At start up<sup>2</sup><br>•<br>When the passive shunting input state changes||
|At start up<sup>2</sup>and when the non leading input state changes|32|
|Only if the ERTMS/ETCS onboard is interfaced with the<br>regenerative brake:<br>•<br>At start up<sup>2</sup>|33|
|•<br>When the status of the regenerative brake changes||
|Only if the ERTMS/ETCS onboard is interfaced with the<br>magnetic shoe brake in any of the following events:<br>•<br>At start up<sup>2</sup><br>•<br>When the status of the magnetic shoe brake changes|34|
|Only if the ERTMS/ETCS onboard is interfaced with the eddy<br>current brake in any of the following events:<br>•<br>At start up<sup>2</sup><br>•<br>When the status of the eddy current brake changes|35|
|Only if the ERTMS/ETCS onboard is interfaced with the<br>electro pneumatic brake in any of the following events:<br>•<br>At start up<sup>2</sup>|36|
|•<br>When the status of the electro pneumatic brake<br>changes||
|Only if the ERTMS/ETCS onboard is interfaced with the<br>additional brakes in any of the following events<br>•<br>At start up<sup>2</sup>|37|
|•<br>When the status of the additional brake changes||
|At start up<sup>2</sup>and when the cab status changes|38|
|In any of the following events:|39|
|•<br>At start up<sup>2</sup>if a cab is already active<br>•<br>When a cab becomes active<br>•<br>When the direction controller input state changes||

<!-- end of page 66 -->

|In any|of the following events:|40|
|---|---|---|
|•|At start up<sup>2</sup>||
|•|When the status of the traction changes||
|In any|of the following events:|41|
|•|At start up<sup>2</sup>if a cab is already active||
|•|When a cab becomes active||
|•|When the type of the train data changes||
|In any|of the following events:|42|
|•|At start up<sup>2</sup>||
|•|When the isolation status of any National System<br>changes||
|When|the traction cut off command state changes|43|
|When|any of the following packets is sent to an STM:|14|
|•|STM-14 State order||
|•|STM-20 Antenna/BTM ID||
|•|STM-22 Test Procedure Permission||
|•|STM-31 Active DMI channel||
|•|STM-34 Button event report||
|•|STM-40 Acknowledgement reply||
|•|STM-47 ETCS BTM status message to STM||
|When|any of the following packets is received from an STM:|14|
|•|STM-6 Override activation||
|•|STM-16 STM max speed||
|•|STM-17 STM system speed and distance||
|•|STM-18 National Trip Procedure||
|•|STM-21 Test Procedure Permission Request||
|•|STM-23 End of Test Procedure||
|•|STM-32 Button Request||

<!-- end of page 67 -->

|•<br>STM-35 Indicator request||
|---|---|
|•<br>STM-38 Text message||
|•<br>STM-39 Delete text message||
|•<br>STM-46 Sound command||
|•<br>STM-128 Brake command||
|•<br>STM-129 STM specific brake control command<br>•<br>STM-130 STM commands to train interface||
|•<br>STM-161 NTC juridical data||
|When packet STM-15 State report from STM is received<br>from an STM:|14|
|•<br>after a (re)connection<br>•<br>or with a different value of NID_STMSTATE with<br>regards to previously-received packet STM-15||
|When packet STM-43 Speed and distance supervision<br>information is received from an STM with a different value of<br>any variable except D_TARGET with regards to previously-<br>received packet STM-43|14|
|At any STM disconnect event|14|
|Each time information related to track condition(s) is<br>provided to an ERTMS/ETCS external function|45|
|Only if the ERTMS/ETCS on-board is interfaced with a train<br>integrity external source in any of the following events:<br>•<br>At start up<sup>2</sup><br>•<br>When the train integrity information changes|50|
|When the state of the remote shunting information changes|51|
|When any of the thresholds related to the odometer<br>accuracy monitoring is reached|52|
|Only if the ERTMS/ETCS onboard is interfaced with an<br>external source providing the safe consist length information,<br>in any of the following events:<br>•<br>At start up<sup>2</sup>|54|

<!-- end of page 68 -->

- When the safe consist length information becomes available or unavailable

- While the safe consist length information is available, when any of the six values composing it changes

**Table 2: List of triggering events and related messages**

<!-- end of page 69 -->
