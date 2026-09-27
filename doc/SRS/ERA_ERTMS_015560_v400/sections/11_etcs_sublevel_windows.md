##### **11. ERTMS/ETCS SUB-LEVEL WINDOWS**


**11.1** **Introduction**


11.1.1.1 The chapter 11 defines the ERTMS/ETCS sub-level windows based on the general
requirements of chapter 10. It is applicable for all ERTMS/ETCS levels.


11.1.1.2 Note: The default window partly visible in some figures of chapter 11 uses the ETCS
default window as specified in chapter 8. However, for the modes SN and NL in
ERTMS/ETCS level NTC, the NTC default window of the corresponding National System
will be displayed instead.


**11.2** **Menu Windows**


**11.2.1** **Main window**


11.2.1.1 The Main window shall comply with the requirements in chapter 10.2.


11.2.1.2 The window title shall indicate “Main”.


11.2.1.3 The buttons (for touch screen technology) / selections (for soft key technology) shall
indicate the label as specified in Table 33.


11.2.1.4 The buttons of the Main window shall be enabled when the conditions specified in Table
33 are fulfilled and no driver’s acknowledgement is required.


11.2.1.4.1 Note: The button / selection #4 is intentionally not used.


11.2.1.5 The ‘Initiate SM’/‘Continue in SM’, ‘Exit SM’, ‘Shunting’, ’Exit Shunting’, ‘Non-Leading’ and
‘Maintain Shunting’ buttons shall be delay type buttons.


11.2.1.6 When the hour glass symbol ST05 is presented (due to an exchange of messages with
the RBC, see chapter 11.7), it shall be shown vertically centered in the ‘Main’ window title
area. The first X position of the symbol shall be 42. It shall then move 26 cells to the right
every second. When it is no more possible to display the symbol ST05 inside the window
title area, the symbol shall come back to its first position and shall start again moving to
the right with the same pace.


Version 4.0.0 PAGE 166 OF 317


**ERA ERTMS unit**

**ETCS Driver Machine Interface**






|Button /<br>selection #|label|Enabling conditions|SRS reference|Col5|Col6|
|---|---|---|---|---|---|
|1|Start|(train is at standstill) AND (mode is SB) AND<br>(Driver ID is valid) AND (Train data are valid)<br>AND (ERTMS/ETCS level is valid) AND (Train<br>running number is valid) AND ((ERTMS/ETCS<br>level is 0/NTC/1) OR ((ERTMS/ETCS level is 2)<br>AND (communication session exists) AND (Train<br>Data acknowledged by RBC)) OR<br>((ERTMS/ETCS level is 2) AND (no<br>communication session exists)))<br>OR<br>(train is at standstill) AND (mode is PT) AND<br>(Train data are valid) AND ((ERTMS/ETCS level<br>is 1) OR ((ERTMS/ETCS level is 2) AND<br>(communication session exists) AND (no<br>pending emergency stop is stored onboard)))<br>OR<br>(mode is SR) AND (ERTMS/ETCS level is 2)<br>AND (communication session exists)|3.8.2.7<br>4.4.11.1.6<br>4.4.14.1.6<br>4.7.2<br>5.4.3.2 S20<br>5.4.5.3<br>5.11.3 S140<br>|3.8.2.7<br>4.4.11.1.6<br>4.4.14.1.6<br>4.7.2<br>5.4.3.2 S20<br>5.4.5.3<br>5.11.3 S140<br>|3.8.2.7<br>4.4.11.1.6<br>4.4.14.1.6<br>4.7.2<br>5.4.3.2 S20<br>5.4.5.3<br>5.11.3 S140<br>|
|2|Driver ID|(train is at standstill) AND (mode is SB) AND<br>(Driver ID is valid) AND (ERTMS/ETCS level is<br>valid)<br>OR<br>((Modification of Driver ID while running is<br>allowed by national value) OR ((Modification of<br>Driver ID while running is not allowed by national<br>value) AND (train is at standstill))) AND (mode is<br>SH/FS/AD/SM/LS/SR/OS/NL/UN/SN)|3.18.4.1<br>4.7.2<br>5.4.5.3<br>|3.18.4.1<br>4.7.2<br>5.4.5.3<br>|3.18.4.1<br>4.7.2<br>5.4.5.3<br>|
|3|Train data|(train is at standstill) AND (Driver ID is valid)<br>AND (ERTMS/ETCS level is valid) AND (mode<br>is SB/FS/AD/LS/SR/OS/UN/SN) AND ((safe<br>consist length information is not available) OR<br>((safe consist length information is available)<br>AND (safe consist length values in front the<br>engine are equal to zero)))|3.18.3.2.1<br>3.18.3.3<br>3.18.3.5 b<br>4.7.2<br>5.4.3.2 S10<br>5.4.5.3<br>|3.18.3.2.1<br>3.18.3.3<br>3.18.3.5 b<br>4.7.2<br>5.4.3.2 S10<br>5.4.5.3<br>|3.18.3.2.1<br>3.18.3.3<br>3.18.3.5 b<br>4.7.2<br>5.4.3.2 S10<br>5.4.5.3<br>|
|5|Level|(train is at standstill) AND (Driver ID is valid)<br>AND (mode is SB/FS/AD/LS/SR/OS/NL/UN/SN)||3.18.4.2||
|5|Level|(train is at standstill) AND (Driver ID is valid)<br>AND (mode is SB/FS/AD/LS/SR/OS/NL/UN/SN)||4.7.2|4.7.2|
|5|Level|(train is at standstill) AND (Driver ID is valid)<br>AND (mode is SB/FS/AD/LS/SR/OS/NL/UN/SN)||5.4.5.3|5.4.5.3|
|6|Train running number|(train is at standstill) AND (mode is SB) AND<br>(Driver ID is valid) AND (ERTMS/ETCS level is<br>valid)<br>OR<br>(mode is FS/AD/SM/LS/SR/OS/NL/UN/SN)|3.18.4.5.1<br>3.18.4.5.2<br>3.18.4.5.3<br>4.7.2<br>5.4.5.3<br>|3.18.4.5.1|3.18.4.5.1|
|6|Train running number|(train is at standstill) AND (mode is SB) AND<br>(Driver ID is valid) AND (ERTMS/ETCS level is<br>valid)<br>OR<br>(mode is FS/AD/SM/LS/SR/OS/NL/UN/SN)|3.18.4.5.1<br>3.18.4.5.2<br>3.18.4.5.3<br>4.7.2<br>5.4.5.3<br>|3.18.4.5.2|3.18.4.5.2|
|6|Train running number|(train is at standstill) AND (mode is SB) AND<br>(Driver ID is valid) AND (ERTMS/ETCS level is<br>valid)<br>OR<br>(mode is FS/AD/SM/LS/SR/OS/NL/UN/SN)|3.18.4.5.1<br>3.18.4.5.2<br>3.18.4.5.3<br>4.7.2<br>5.4.5.3<br>|3.18.4.5.3|3.18.4.5.3|
|6|Train running number|(train is at standstill) AND (mode is SB) AND<br>(Driver ID is valid) AND (ERTMS/ETCS level is<br>valid)<br>OR<br>(mode is FS/AD/SM/LS/SR/OS/NL/UN/SN)|3.18.4.5.1<br>3.18.4.5.2<br>3.18.4.5.3<br>4.7.2<br>5.4.5.3<br>|4.7.2|4.7.2|
|6|Train running number|(train is at standstill) AND (mode is SB) AND<br>(Driver ID is valid) AND (ERTMS/ETCS level is<br>valid)<br>OR<br>(mode is FS/AD/SM/LS/SR/OS/NL/UN/SN)|3.18.4.5.1<br>3.18.4.5.2<br>3.18.4.5.3<br>4.7.2<br>5.4.5.3<br>|5.4.5.3|5.4.5.3|



Version 4.0.0 PAGE 167 OF 317


**ERA ERTMS unit**

**ETCS Driver Machine Interface**












|Button /<br>selection #|label|Enabling conditions|SRS reference|Col5|Col6|
|---|---|---|---|---|---|
|7 <br>|Shunting|(train is at standstill) AND (Driver ID is valid)<br>AND (mode is SB/FS/AD/SM/LS/SR/OS/UN/SN)<br>AND (ERTMS/ETCS level is valid) AND<br>((ERTMS/ETCS level is 0/1/NTC) OR<br>((ERTMS/ETCS level is 2) AND (communication<br>session exists)))<br>OR<br>(train is at standstill) AND (mode is PT) AND<br>((ERTMS/ETCS level is 1) OR ((ERTMS/ETCS<br>level is 2) AND (communication session exists)<br>AND (no pending emergency stop is stored<br>onboard)))|4.4.8.1.6<br>4.7.2<br>5.4.3.2 S10<br>5.4.5.3<br>5.6.3 E015<br>5.11.2 S140<br>|4.4.8.1.6<br>4.7.2<br>5.4.3.2 S10<br>5.4.5.3<br>5.6.3 E015<br>5.11.2 S140<br>|4.4.8.1.6<br>4.7.2<br>5.4.3.2 S10<br>5.4.5.3<br>5.6.3 E015<br>5.11.2 S140<br>|
|7 <br>|Exit Shunting|(train is at standstill) AND (mode is SH)||4.6.3 [19]||
|7 <br>|Exit Shunting|(train is at standstill) AND (mode is SH)||4.7.2|4.7.2|
|8|Non-Leading|(train is at standstill) AND (Driver ID is valid)<br>AND (ERTMS/ETCS level is valid) AND (mode<br>is SB/SH/FS/AD/SM/LS/SR/OS) AND (The “non<br>leading” input signal is received)|4.6.3 [46]<br>4.7.2<br>5.4.3.2 S10<br>5.4.5.3<br>|4.6.3 [46]|4.6.3 [46]|
|8|Non-Leading|(train is at standstill) AND (Driver ID is valid)<br>AND (ERTMS/ETCS level is valid) AND (mode<br>is SB/SH/FS/AD/SM/LS/SR/OS) AND (The “non<br>leading” input signal is received)|4.6.3 [46]<br>4.7.2<br>5.4.3.2 S10<br>5.4.5.3<br>|4.7.2|4.7.2|
|8|Non-Leading|(train is at standstill) AND (Driver ID is valid)<br>AND (ERTMS/ETCS level is valid) AND (mode<br>is SB/SH/FS/AD/SM/LS/SR/OS) AND (The “non<br>leading” input signal is received)|4.6.3 [46]<br>4.7.2<br>5.4.3.2 S10<br>5.4.5.3<br>|5.4.3.2 S10|5.4.3.2 S10|
|8|Non-Leading|(train is at standstill) AND (Driver ID is valid)<br>AND (ERTMS/ETCS level is valid) AND (mode<br>is SB/SH/FS/AD/SM/LS/SR/OS) AND (The “non<br>leading” input signal is received)|4.6.3 [46]<br>4.7.2<br>5.4.3.2 S10<br>5.4.5.3<br>|5.4.5.3|5.4.5.3|
|9|Maintain Shunting|(mode is SH) AND (The “passive shunting” input<br>signal is received)||4.4.20.1.5||
|9|Maintain Shunting|(mode is SH) AND (The “passive shunting” input<br>signal is received)||4.4.20.1.6|4.4.20.1.6|
|9|Maintain Shunting|(mode is SH) AND (The “passive shunting” input<br>signal is received)||4.6.3 [26]|4.6.3 [26]|
|9|Maintain Shunting|(mode is SH) AND (The “passive shunting” input<br>signal is received)||4.7.2|4.7.2|
|10|Radio data|(train is at standstill) AND (Driver ID is valid)<br>AND (ERTMS/ETCS level is valid) AND (mode<br>is SB/FS/AD/SM/LS/SR/OS/NL/PT/UN/SN)|3.18.4.3<br>4.7.2<br>|3.18.4.3|3.18.4.3|
|10|Radio data|(train is at standstill) AND (Driver ID is valid)<br>AND (ERTMS/ETCS level is valid) AND (mode<br>is SB/FS/AD/SM/LS/SR/OS/NL/PT/UN/SN)|3.18.4.3<br>4.7.2<br>|4.7.2|4.7.2|



Version 4.0.0 PAGE 168 OF 317


**ERA ERTMS unit**

**ETCS Driver Machine Interface**







|Button /<br>selection #|label|Enabling conditions|SRS reference|
|---|---|---|---|
|11<br>|Initiate SM|(train is at standstill) AND (mode is SB) AND<br>(Driver ID is valid) AND (safe consist length<br>information is available) AND (ERTMS/ETCS<br>level is valid) AND (ERTMS/ETCS level is 2)<br>AND (no RBC transition order is stored on-<br>board) AND (only one communication session<br>with a supervising RBC certified with a system<br>version X.Y > 2.2 exists) AND (the train position<br>is valid and is referred to an LRBG)<br>OR<br>(train is at standstill) AND (mode is PT) AND<br>(valid Train Data is stored on-board) AND (safe<br>consist length information is available) AND<br>(ERTMS/ETCS level is 2) AND (no RBC<br>transition order is stored on-board) AND (only<br>one communication session with a supervising<br>RBC certified with a system version X.Y > 2.2<br>exists) AND (the train position is valid and is<br>referred to an LRBG) AND (no pending<br>emergency stop is stored onboard)<br>OR<br>(train is at standstill) AND (mode is<br>FS/AD/LS/OS/SR) AND (safe consist length<br>information is available) AND (ERTMS/ETCS<br>level is 2) AND (no RBC transition order is<br>stored on-board) AND (only one communication<br>session with a supervising RBC certified with a<br>system version X.Y > 2.2 exists)|4.4.21.1.3<br>4.7.2<br>5.4.3.2 S10<br>5.4.5.3<br>5.11.2 S140<br>5.21.3 E015<br>6.6.2.3.1<br>6.6.2.3.2<br>6.6.2.3.6<br>6.6.2.3.7<br>6.6.4.3.1<br>|
|11<br>|Continue in SM|(train is at standstill) AND (mode is SM) AND<br>(safe consist length information is available)<br>AND (communication session with an RBC<br>certified with a system version X.Y > 2.2 exists)<br>OR<br>(train is at standstill) AND (mode is PT) AND (no<br>valid Train Data is stored on-board) AND (safe<br>consist length information is available) AND<br>(ERTMS/ETCS level is 2) AND (a<br>communication session with a superving RBC<br>certified with a system version X.Y > 2.2 exists)<br>AND (no pending emergency stop is stored<br>onboard)|4.4.21.1.10<br>4.7.2<br>5.11.2 S140<br>5.21.3 E015<br>|
|12|Exit SM|(train is at standstill) AND (mode is SM)|4.7.2<br>|


**Table 33 – Button / selection label**


11.2.1.7 Figure 109 shows the presentation of the main window (if not in SM, SH or NL mode).


Version 4.0.0 PAGE 169 OF 317


**ERA ERTMS unit**

**ETCS Driver Machine Interface**












|Col1|Col2|Col3|150<br>100 200<br>0<br>50 300<br>0 400|Col5|Col6|Col7|Col8|Main<br>Start Driver ID<br>Train data<br>Train running<br>Level<br>number<br>Shunting Non-Leading|Col10|
|---|---|---|---|---|---|---|---|---|---|
|||||||||Start|Start|
|||||||||Train data|Train data|
|||||||||Level|Level|
|||||||||Shunting|Shunting|
|||||||||Maintain Shunting|Radio data|
|||||||||||
|**2**|**2**|**2**|**2**|||||Initiate SM<br>Exit SM|Exit SM|
|||||||||||
|||||||||||
|||||||||||
|||||||||||
|||||||||||
|||||||||||




|Col1|Col2|Col3|150<br>100 200<br>0<br>50 300<br>0 400|Col5|Col6|Col7|Col8|Col9|Col10|Col11|Main<br>1 - Start<br>2 - Driver ID<br>3 - Train data<br>5 - Level<br>6 - Train running number<br>7 - Shunting<br>8 - Non-Leading<br>9 - Maintain shunting|Col13|Col14|Col15|Col16|Col17|
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
||||**0**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**0**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**0**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**0**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**0**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**0**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**0**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**0**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|1 - Start<br>2 - Driver ID<br>3 - Train data<br>5 - Level<br>6 - Train running number<br>7 - Shunting<br>8 - Non-Leading<br>9 - Maintain shunting<br>Main|1 - Start<br>2 - Driver ID<br>3 - Train data<br>5 - Level<br>6 - Train running number<br>7 - Shunting<br>8 - Non-Leading<br>9 - Maintain shunting<br>Main|1 - Start<br>2 - Driver ID<br>3 - Train data<br>5 - Level<br>6 - Train running number<br>7 - Shunting<br>8 - Non-Leading<br>9 - Maintain shunting<br>Main|1 - Start<br>2 - Driver ID<br>3 - Train data<br>5 - Level<br>6 - Train running number<br>7 - Shunting<br>8 - Non-Leading<br>9 - Maintain shunting<br>Main|1 - Start<br>2 - Driver ID<br>3 - Train data<br>5 - Level<br>6 - Train running number<br>7 - Shunting<br>8 - Non-Leading<br>9 - Maintain shunting<br>Main||
||||||||||||||||||
||||||||||||||||||
||||||||||||||||||
||||||||||||||||||
||||||||||||||||||
||||||||||||||||||
|**2**|**2**|**2**|||||||||||||||
||||||||||||||||||
||||||||||||||||||
||||||||||||||||||
||||||||||||||||||
||||||||||||||||||
||||||||||||||||||
|1|1|1|2|3|3|||5|5|6|6|7|8|9|...|...|



**Figure 109 – Main window**


**11.2.2** **Override window**


11.2.2.1 The Override window shall comply with the requirements in chapter 10.2.


11.2.2.2 The window title shall indicate “Override”.


11.2.2.3 The button (for touch screen technology) / selection (for soft key technology) shall indicate
the label as specified in Table 34.


Version 4.0.0 PAGE 170 OF 317


**ERA ERTMS unit**

**ETCS Driver Machine Interface**


11.2.2.4 The button of the Override window shall be enabled when the conditions specified in Table
34 are fulfilled and no driver’s acknowledgement is required.







|Button<br>/selection #|label|Enabling conditions|SRS reference|
|---|---|---|---|
|1|EOA|(train speed is under or equal to the speed limit<br>for triggering the “override”function) AND (mode<br>is FS/AD/LS/SR/OS/UN/SN/SH)<br>OR<br>(train speed is under or equal to the speed limit<br>for triggering the “override”function) AND (mode<br>is SB) AND (Driver ID is valid) AND (Train data<br>are valid) AND (Train running number is valid)<br>AND (ERTMS/ETCS level is valid) AND<br>(ERTMS/ETCS level is 2)<br>OR<br>(train speed is under or equal to the speed limit<br>for triggering the “override”function) AND (mode<br>is PT) AND (Train data are valid) AND (Train<br>running number is valid)|4.6.3 [37]<br>4.7.2<br>5.4.5.3<br>5.8.2.1<br>5.11.4.2<br>|


**Table 34 – Button / selection label**


11.2.2.5 Figure 110 shows the presentation of the override window.





Version 4.0.0 PAGE 171 OF 317


**ERA ERTMS unit**

**ETCS Driver Machine Interface**






|Col1|Col2|Col3|150<br>100 200<br>0<br>50 300<br>0 400|Col5|Col6|Col7|Col8|Override|
|---|---|---|---|---|---|---|---|---|
|||||||||EOA|
||||||||||
||||||||||
|**2**|**2**|**2**|**2**||||||
||||||||||
||||||||||
||||||||||
||||||||||
||||||||||
||||||||||




|Col1|Col2|Col3|150<br>100 200<br>0<br>50 300<br>0 400|Col5|Col6|Col7|Col8|Col9|Col10|Col11|Override<br>1 - EOA|Col13|Col14|Col15|Col16|Col17|
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
||||**0**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**0**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**0**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**0**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**0**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**0**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**0**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**0**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|1 - EOA<br>Override|1 - EOA<br>Override|1 - EOA<br>Override|1 - EOA<br>Override|1 - EOA<br>Override||
||||||||||||||||||
||||||||||||||||||
||||||||||||||||||
||||||||||||||||||
||||||||||||||||||
||||||||||||||||||
|**2**|**2**|**2**|||||||||||||||
||||||||||||||||||
||||||||||||||||||
||||||||||||||||||
||||||||||||||||||
||||||||||||||||||
||||||||||||||||||
|1|1|1|||||||||||||||



**Figure 110 – Override window**


**11.2.3** **Special window**


11.2.3.1 The Special window shall comply with the requirements in chapter 10.2.


11.2.3.2 The window title shall indicate “Special”.


11.2.3.3 The buttons (for touch screen technology) / selections (for soft key technology) shall
indicate the label as specified in Table 35.


Version 4.0.0 PAGE 172 OF 317


**ERA ERTMS unit**

**ETCS Driver Machine Interface**


11.2.3.4 The buttons of the Special window shall be enabled when the conditions specified in Table
35 are fulfilled and no driver’s acknowledgement is required.


11.2.3.5 The ‘Train integrity’ button shall be a delay type button.
















|Button<br>/selection #|label|Enabling conditions|SRS reference|Col5|Col6|
|---|---|---|---|---|---|
|1|Adhesion|(train is at standstill) AND (mode is SB) AND<br>(Modification of adhesion factor by driver is<br>allowed by national value) AND (Driver ID is<br>valid) AND (Train data are valid) AND<br>(ERTMS/ETCS level is valid)<br>OR<br>(Modification of adhesion factor by driver is<br>allowed by national value) AND (mode is<br>FS/AD/SM/LS/SR/OS/UN/SN)|3.18.4.6.2.1<br>4.7.2<br>|3.18.4.6.2.1<br>4.7.2<br>|3.18.4.6.2.1<br>4.7.2<br>|
|2|SR speed / distance|(train is at standstill) AND (mode is SR)||4.4.11.1.5||
|2|SR speed / distance|(train is at standstill) AND (mode is SR)||4.7.2|4.7.2|
|3|Train integrity|(train is at standstill) AND (mode is<br>SB/FS/AD/LS/SR/OS/UN/PT/SN) AND (Driver<br>ID is valid) AND (Train data are valid and have<br>been acknowledged by an RBC with which a<br>communication session exists) AND<br>(ERTMS/ETCS level is valid) AND (the train<br>position is valid and is referred to an LRBG)<br>AND (the distance between the current min safe<br>rear end and the current estimated front end<br>does not exceed the range of the confirmed train<br>length information)<br>OR<br>(train is at standstill) AND (mode is SM) AND (if<br>any, an updated safe consist length information<br>for Supervised Manoeuvre sent to the RBC has<br>been acknowledged by this latter, with which a<br>communication session exists) AND (the<br>distance between the current min safe rear end<br>and the current estimated front end does not<br>exceed the range of the confirmed train length<br>information)<br>OR<br>(train is at standstill) AND (mode is SB) AND<br>(Driver ID is valid) AND (ERTMS/ETCS level is<br>valid) AND (no valid Train data is available) AND<br>(Safe consist length information has been sent<br>to the RBC and has been acknowledged by this<br>latter, with which a communication session<br>exists) AND (the train position is valid and is<br>referred to an LRBG) AND (the distance<br>between the current min safe rear end and the<br>current estimated front end does not exceed the<br>range of the confirmed train length information)|3.6.5.2.1<br>3.6.5.2.2<br>3.6.5.2.5<br>Table 2e<br>4.4.7.1.6<br>4.7.2<br>|3.6.5.2.1|3.6.5.2.1|
|3|Train integrity|(train is at standstill) AND (mode is<br>SB/FS/AD/LS/SR/OS/UN/PT/SN) AND (Driver<br>ID is valid) AND (Train data are valid and have<br>been acknowledged by an RBC with which a<br>communication session exists) AND<br>(ERTMS/ETCS level is valid) AND (the train<br>position is valid and is referred to an LRBG)<br>AND (the distance between the current min safe<br>rear end and the current estimated front end<br>does not exceed the range of the confirmed train<br>length information)<br>OR<br>(train is at standstill) AND (mode is SM) AND (if<br>any, an updated safe consist length information<br>for Supervised Manoeuvre sent to the RBC has<br>been acknowledged by this latter, with which a<br>communication session exists) AND (the<br>distance between the current min safe rear end<br>and the current estimated front end does not<br>exceed the range of the confirmed train length<br>information)<br>OR<br>(train is at standstill) AND (mode is SB) AND<br>(Driver ID is valid) AND (ERTMS/ETCS level is<br>valid) AND (no valid Train data is available) AND<br>(Safe consist length information has been sent<br>to the RBC and has been acknowledged by this<br>latter, with which a communication session<br>exists) AND (the train position is valid and is<br>referred to an LRBG) AND (the distance<br>between the current min safe rear end and the<br>current estimated front end does not exceed the<br>range of the confirmed train length information)|3.6.5.2.1<br>3.6.5.2.2<br>3.6.5.2.5<br>Table 2e<br>4.4.7.1.6<br>4.7.2<br>|3.6.5.2.2|3.6.5.2.2|
|3|Train integrity|(train is at standstill) AND (mode is<br>SB/FS/AD/LS/SR/OS/UN/PT/SN) AND (Driver<br>ID is valid) AND (Train data are valid and have<br>been acknowledged by an RBC with which a<br>communication session exists) AND<br>(ERTMS/ETCS level is valid) AND (the train<br>position is valid and is referred to an LRBG)<br>AND (the distance between the current min safe<br>rear end and the current estimated front end<br>does not exceed the range of the confirmed train<br>length information)<br>OR<br>(train is at standstill) AND (mode is SM) AND (if<br>any, an updated safe consist length information<br>for Supervised Manoeuvre sent to the RBC has<br>been acknowledged by this latter, with which a<br>communication session exists) AND (the<br>distance between the current min safe rear end<br>and the current estimated front end does not<br>exceed the range of the confirmed train length<br>information)<br>OR<br>(train is at standstill) AND (mode is SB) AND<br>(Driver ID is valid) AND (ERTMS/ETCS level is<br>valid) AND (no valid Train data is available) AND<br>(Safe consist length information has been sent<br>to the RBC and has been acknowledged by this<br>latter, with which a communication session<br>exists) AND (the train position is valid and is<br>referred to an LRBG) AND (the distance<br>between the current min safe rear end and the<br>current estimated front end does not exceed the<br>range of the confirmed train length information)|3.6.5.2.1<br>3.6.5.2.2<br>3.6.5.2.5<br>Table 2e<br>4.4.7.1.6<br>4.7.2<br>|3.6.5.2.5<br>Table 2e|3.6.5.2.5<br>Table 2e|
|3|Train integrity|(train is at standstill) AND (mode is<br>SB/FS/AD/LS/SR/OS/UN/PT/SN) AND (Driver<br>ID is valid) AND (Train data are valid and have<br>been acknowledged by an RBC with which a<br>communication session exists) AND<br>(ERTMS/ETCS level is valid) AND (the train<br>position is valid and is referred to an LRBG)<br>AND (the distance between the current min safe<br>rear end and the current estimated front end<br>does not exceed the range of the confirmed train<br>length information)<br>OR<br>(train is at standstill) AND (mode is SM) AND (if<br>any, an updated safe consist length information<br>for Supervised Manoeuvre sent to the RBC has<br>been acknowledged by this latter, with which a<br>communication session exists) AND (the<br>distance between the current min safe rear end<br>and the current estimated front end does not<br>exceed the range of the confirmed train length<br>information)<br>OR<br>(train is at standstill) AND (mode is SB) AND<br>(Driver ID is valid) AND (ERTMS/ETCS level is<br>valid) AND (no valid Train data is available) AND<br>(Safe consist length information has been sent<br>to the RBC and has been acknowledged by this<br>latter, with which a communication session<br>exists) AND (the train position is valid and is<br>referred to an LRBG) AND (the distance<br>between the current min safe rear end and the<br>current estimated front end does not exceed the<br>range of the confirmed train length information)|3.6.5.2.1<br>3.6.5.2.2<br>3.6.5.2.5<br>Table 2e<br>4.4.7.1.6<br>4.7.2<br>|4.4.7.1.6|4.4.7.1.6|
|3|Train integrity|(train is at standstill) AND (mode is<br>SB/FS/AD/LS/SR/OS/UN/PT/SN) AND (Driver<br>ID is valid) AND (Train data are valid and have<br>been acknowledged by an RBC with which a<br>communication session exists) AND<br>(ERTMS/ETCS level is valid) AND (the train<br>position is valid and is referred to an LRBG)<br>AND (the distance between the current min safe<br>rear end and the current estimated front end<br>does not exceed the range of the confirmed train<br>length information)<br>OR<br>(train is at standstill) AND (mode is SM) AND (if<br>any, an updated safe consist length information<br>for Supervised Manoeuvre sent to the RBC has<br>been acknowledged by this latter, with which a<br>communication session exists) AND (the<br>distance between the current min safe rear end<br>and the current estimated front end does not<br>exceed the range of the confirmed train length<br>information)<br>OR<br>(train is at standstill) AND (mode is SB) AND<br>(Driver ID is valid) AND (ERTMS/ETCS level is<br>valid) AND (no valid Train data is available) AND<br>(Safe consist length information has been sent<br>to the RBC and has been acknowledged by this<br>latter, with which a communication session<br>exists) AND (the train position is valid and is<br>referred to an LRBG) AND (the distance<br>between the current min safe rear end and the<br>current estimated front end does not exceed the<br>range of the confirmed train length information)|3.6.5.2.1<br>3.6.5.2.2<br>3.6.5.2.5<br>Table 2e<br>4.4.7.1.6<br>4.7.2<br>|4.7.2|4.7.2|



Version 4.0.0 PAGE 173 OF 317


**ERA ERTMS unit**

**ETCS Driver Machine Interface**



|Button<br>/selection #|label|Enabling conditions|SRS reference|
|---|---|---|---|
|4 <br>|BMM reaction inhibition|(train is at standstill) AND (mode is SB) AND<br>(Driver ID is valid) AND (ERTMS/ETCS level is<br>valid) AND (ERTMS/ETCS level is 1/2) AND (the<br>“BTM alarm reaction inhibition” function is not<br>active)<br>OR<br>(train is at standstill) AND (mode is SR/SH) AND<br>(ERTMS/ETCS level is 1/2) AND (the “BTM<br>alarm reaction inhibition” function is not active)|4.7.2<br>5.4.5.3<br>5.22.2.1<br>|
|4 <br>|Revoke BMM reaction inhibition|(train is at standstill) AND (mode is SB) AND<br>(Driver ID is valid) AND (ERTMS/ETCS level is<br>valid) AND (ERTMS/ETCS level is 1/2) AND (the<br>“BTM alarm reaction inhibition” function is active)<br>OR<br>(train is at standstill) AND (mode is SR/SH) AND<br>(ERTMS/ETCS level is 1/2) AND (the “BTM alarm<br>reaction inhibition” function is active)|4.7.2<br>5.4.5.3<br>5.22.5.1 c<br>|


**Table 35 – Button / selection label**





11.2.3.6 Figure 111 shows the presentation of the “Special” window (with the SR speed/distance
button ‘disabled’).


Version 4.0.0 PAGE 174 OF 317


**ERA ERTMS unit**

**ETCS Driver Machine Interface**










|Col1|Col2|Col3|150<br>100 200<br>0<br>50 300<br>0 400|Col5|Col6|Col7|Col8|Special<br>Adhesion SR speed/distance<br>BMM reaction<br>Train integrity<br>inhibition|
|---|---|---|---|---|---|---|---|---|
||||||||||
||||||||||
|**2**|**2**|**2**|**2**||||||
||||||||||
||||||||||
||||||||||
||||||||||
||||||||||
||||||||||








|Col1|Col2|Col3|150<br>100 200<br>0<br>50 300<br>0 400|Col5|Col6|Col7|Col8|Col9|Col10|Col11|Special<br>1 - Adhesion<br>2 - SR speed/distance<br>3 - Train integrity<br>4 - BMM reaction inhibition|Col13|Col14|Col15|Col16|Col17|
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
||||**0**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**0**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**0**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**0**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**0**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**0**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**0**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**0**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|1 - Adhesion<br>2 - SR speed/distance<br>3 - Train integrity<br>4 - BMM reaction inhibition<br>Special|1 - Adhesion<br>2 - SR speed/distance<br>3 - Train integrity<br>4 - BMM reaction inhibition<br>Special|1 - Adhesion<br>2 - SR speed/distance<br>3 - Train integrity<br>4 - BMM reaction inhibition<br>Special|1 - Adhesion<br>2 - SR speed/distance<br>3 - Train integrity<br>4 - BMM reaction inhibition<br>Special|1 - Adhesion<br>2 - SR speed/distance<br>3 - Train integrity<br>4 - BMM reaction inhibition<br>Special||
||||||||||||||||||
||||||||||||||||||
||||||||||||||||||
||||||||||||||||||
||||||||||||||||||
||||||||||||||||||
|**2**|**2**|**2**|||||||||||||||
||||||||||||||||||
||||||||||||||||||
||||||||||||||||||
||||||||||||||||||
||||||||||||||||||
||||||||||||||||||
|1|1|1|2|3|3|4|4||||||||||



**Figure 111 – Special window**


**11.2.4** **Settings window**


11.2.4.1 The Settings window shall comply with the requirements in chapter 10.2.


11.2.4.2 The window title shall indicate “Settings”.


11.2.4.3 The buttons (for touch screen technology) / selections (for soft key technology) shall
indicate the label as specified in Table 36.


Version 4.0.0 PAGE 175 OF 317


**ERA ERTMS unit**

**ETCS Driver Machine Interface**


11.2.4.4 The buttons of the Settings window shall be enabled when the conditions specified in
Table 36 are fulfilled and no driver’s acknowledgement is required.


11.2.4.5 It shall be possible in the Settings window to add buttons for additional DMI technical
functions (e.g. a function locking the touch screen for cleaning purpose).


11.2.4.5.1 Note: These additional DMI technical functions are outside of the scope of this

specification. Nevertheless, it is recommended that they follow the ergonomic principles
specified in this document (e.g. if a sub-level window is accessed via such button, it is
recommended that the sub-level window follows the general requirements of chapter 9)


















|Button<br>/selection #|label|Enabling conditions|SRS reference|
|---|---|---|---|
|1|Symbol SE03 (for touch)<br>Language (for soft)|(train is at standstill) AND (mode is SB)<br>OR<br>(mode is<br>SH/FS/AD/SM/LS/SR/OS/NL/UN/TR/PT/SN/RV)|4.7.2|
|2|Symbol SE02 (for touch)<br>Volume (for soft)|(train is at standstill) AND (mode is SB)<br>OR<br>(mode is<br>SH/FS/AD/SM/LS/SR/OS/NL/UN/TR/PT/SN/RV)|-|
|3|Symbol SE01 (for touch)<br>Brightness (for soft)|(train is at standstill) AND (mode is SB)<br>OR<br>(mode is<br>SH/FS/AD/SM/LS/SR/OS/NL/UN/TR/PT/SN/RV)|-|
|4|System version|(train is at standstill) AND (mode is SB)<br>OR<br>(mode is<br>SH/FS/AD/SM/LS/SR/OS/NL/UN/TR/PT/SN/RV)|4.7.2|
|5|Set VBC|(train is at standstill) AND (mode is SB) AND<br>(maximum on-board storage capacity of VBC set<br>by driver is not reached, see [4] 4.5.1.2)|4.7.2|
|6|Remove VBC|(train is at standstill) AND (mode is SB) AND (at<br>least one VBC is stored on-board)|4.7.2|
|7|ATO|(train is at standstill) AND (mode is SB)<br>OR<br>(mode is<br>SH/FS/AD/SM/LS/SR/OS/NL/UN/TR/PT/SN/RV)|3.15.11.2<br>4.7.2<br>|
|8 and<br>following|Used for “Additional DMI technical functions” (outside of the scope of this specification)|Used for “Additional DMI technical functions” (outside of the scope of this specification)|Used for “Additional DMI technical functions” (outside of the scope of this specification)|



**Table 36 – Button / selection label**


11.2.4.6 Figure 112 shows the presentation of the “Settings” window.


Version 4.0.0 PAGE 176 OF 317


**ERA ERTMS unit**

**ETCS Driver Machine Interface**










|Col1|Col2|Col3|150<br>100 200<br>0<br>50 300<br>0 400|Col5|Col6|Col7|Col8|Settings<br>System version<br>Set VBC Remove VBC<br>ATO|
|---|---|---|---|---|---|---|---|---|
||||||||||
||||||||||
|**2**|**2**|**2**|**2**||||||
||||||||||
||||||||||
||||||||||
||||||||||
||||||||||
||||||||||












|Col1|Col2|Col3|150<br>100 200<br>0<br>50 300<br>0 400|Col5|Col6|Col7|Col8|Col9|Col10|Col11|Settings<br>1 - Language<br>2 - Volume<br>3 - Brightness<br>4 - System version<br>5 - Set VBC<br>6 - Remove VBC<br>7 - ATO|Col13|Col14|Col15|Col16|Col17|
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
||||**0**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**0**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**0**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**0**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**0**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**0**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**0**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**0**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|1 - Language<br>2 - Volume<br>3 - Brightness<br>4 - System version<br>5 - Set VBC<br>6 - Remove VBC<br>7 - ATO<br>Settings|1 - Language<br>2 - Volume<br>3 - Brightness<br>4 - System version<br>5 - Set VBC<br>6 - Remove VBC<br>7 - ATO<br>Settings|1 - Language<br>2 - Volume<br>3 - Brightness<br>4 - System version<br>5 - Set VBC<br>6 - Remove VBC<br>7 - ATO<br>Settings|1 - Language<br>2 - Volume<br>3 - Brightness<br>4 - System version<br>5 - Set VBC<br>6 - Remove VBC<br>7 - ATO<br>Settings|1 - Language<br>2 - Volume<br>3 - Brightness<br>4 - System version<br>5 - Set VBC<br>6 - Remove VBC<br>7 - ATO<br>Settings||
||||||||||||||||||
||||||||||||||||||
||||||||||||||||||
||||||||||||||||||
||||||||||||||||||
||||||||||||||||||
|**2**|**2**|**2**|||||||||||||||
||||||||||||||||||
||||||||||||||||||
||||||||||||||||||
||||||||||||||||||
||||||||||||||||||
||||||||||||||||||
|1|1|1|2|3|3|4|4|5|5|6|6|7|||||



**Figure 112 – Settings window**


**11.2.5** **Radio data window**


11.2.5.1 The Radio data window shall comply with the requirements in chapter 10.2.


11.2.5.2 The window title shall indicate “Radio data”.


11.2.5.3 The buttons (for touch screen technology) / selections (for soft key technology) shall
indicate the label as specified in Table 37.


Version 4.0.0 PAGE 177 OF 317


**ERA ERTMS unit**

**ETCS Driver Machine Interface**


11.2.5.4 The buttons of the Radio data window shall be enabled when the conditions specified in
Table 37 are fulfilled and no driver’s acknowledgement is required.


11.2.5.5 The ‘GSM-R network ID’ button shall be a delay type button.


11.2.5.6 When the hour glass symbol ST05 is presented (see chapter 11.7), it shall be shown
vertically centered in the ‘Radio data’ window title area. The first X position of the symbol
shall be 42. It shall then move 26 cells to the right every second. When it is no more
possible to display the symbol ST05 inside the window title area, the symbol shall come
back to its first position and shall start again moving to the right with the same pace.










|Button<br>/selection #|label|Enabling conditions|SRS reference|
|---|---|---|---|
|1|Contact last RBC|(train is at standstill) AND (Driver ID is valid)<br>AND (mode is SB/FS/AD/SM/LS/SR/OS/NL/PT)<br>AND (ERTMS/ETCS level is valid) AND<br>(ERTMS/ETCS level is 2) AND (RBC contact<br>information is valid OR invalid)<br>AND<br>((((Radio Network type is FRMCS) OR ((Radio<br>Network type is FRMCS+GSM-R) AND (FRMCS<br>is the only radio system installed on-board))) AND<br>(FRMCS on-board is registered to the FRMCS<br>Radio Network)) OR<br>((Radio Network type is FRMCS+GSM-R) AND<br>(both radio systems are installed on-board) AND<br>(FRMCS on-board is registered to the FRMCS<br>Radio Network) AND (at least one GSM-R Mobile<br>Terminal is registered to a GSM-R Radio<br>Network)) OR<br>((Radio Network type is FRMCS+GSM-R) AND<br>(both radio systems are installed on-board) AND<br>(Perform mission with only one radio system is<br>Yes) AND ((FRMCS on-board is registered to the<br>FRMCS Radio Network) OR (at least one GSM-<br>R Mobile Terminal registered to a GSM-R Radio<br>Network))) OR<br>(((Radio Network type is GSM-R) OR ((Radio<br>Network type is FRMCS+GSM-R) AND (GSM-R<br>is the only radio system installed on-board))) AND<br>(at least one GSM-R Mobile Terminal registered<br>to a GSM-R Radio Network)|3.18.4.3.2<br>5.4.3.2 S3<br>5.4.5.3 j<br>|



Version 4.0.0 PAGE 178 OF 317


**ERA ERTMS unit**

**ETCS Driver Machine Interface**






|Button<br>/selection #|label|Enabling conditions|SRS reference|
|---|---|---|---|
|2|Use short number|(train is at standstill) AND (Driver ID is valid)<br>AND (mode is SB/FS/AD/SM/LS/SR/OS/NL/PT)<br>AND (ERTMS/ETCS level is valid) AND<br>(ERTMS/ETCS level is 2)<br>AND<br>(((Radio Network type is FRMCS+GSM-R) AND<br>(both radio systems are installed on-board) AND<br>(FRMCS on-board is registered to the FRMCS<br>Radio Network) AND (at least one GSM-R Mobile<br>Terminal is registered to a GSM-R Radio<br>Network)) OR<br>((Radio Network type is FRMCS+GSM-R) AND<br>(both radio systems are installed on-board) AND<br>(Perform mission with only one radio system is<br>Yes) AND (at least one GSM-R Mobile Terminal<br>registered to a GSM-R Radio Network)) OR<br>(((Radio Network type is GSM-R) OR ((Radio<br>Network type is FRMCS+GSM-R) AND (GSM-R<br>is the only radio system installed on-board))) AND<br>(at least one GSM-R Mobile Terminal registered<br>to a GSM-R Radio Network)))|3.18.4.3.2<br>3.18.4.3.4<br>5.4.3.2 S3<br>5.4.5.3 j<br>|
|3|Enter RBC data|(train is at standstill) AND (Driver ID is valid)<br>AND (mode is SB/FS/AD/SM/LS/SR/OS/NL/PT)<br>AND (ERTMS/ETCS level is valid) AND<br>(ERTMS/ETCS level is 2)<br>AND<br>((((Radio Network type is FRMCS) OR ((Radio<br>Network type is FRMCS+GSM-R) AND (FRMCS<br>is the only radio system installed on-board))) AND<br>(FRMCS on-board is registered to the FRMCS<br>Radio Network)) OR<br>((Radio Network type is FRMCS+GSM-R) AND<br>(both radio systems are installed on-board) AND<br>(FRMCS on-board is registered to the FRMCS<br>Radio Network) AND (at least one GSM-R Mobile<br>Terminal is registered to a GSM-R Radio<br>Network)) OR<br>((Radio Network type is FRMCS+GSM-R) AND<br>(both radio systems are installed on-board) AND<br>(Perform mission with only one radio system is<br>Yes) AND ((FRMCS on-board is registered to the<br>FRMCS Radio Network) OR (at least one GSM-<br>R Mobile Terminal registered to a GSM-R Radio<br>Network))) OR<br>(((Radio Network type is GSM-R) OR ((Radio<br>Network type is FRMCS+GSM-R) AND (GSM-R<br>is the only radio system installed on-board)))<br>AND (at least one GSM-R Mobile Terminal<br>registered to a GSM-R Radio Network)))|3.18.4.3.2<br>5.4.3.2 S3<br>5.4.5.3 j<br>|



Version 4.0.0 PAGE 179 OF 317


**ERA ERTMS unit**

**ETCS Driver Machine Interface**



|Button<br>/selection #|label|Enabling conditions|SRS reference|
|---|---|---|---|
|5|Radio network type|(train is at standstill) AND (Driver ID is valid)<br>AND (mode is SB/FS/LS/SR/OS/NL/PT/UN/SN)<br>AND (ERTMS/ETCS level is valid)|3.18.4.3.6<br>5.4.3.2 S3<br>5.4.5.3 j<br>|
|6|GSM-R network ID|(train is at standstill) AND (Driver ID is valid)<br>AND (mode is<br>SB/FS/AD/SM/LS/SR/OS/NL/PT/UN/SN) AND<br>(ERTMS/ETCS level is valid) AND (Radio<br>Network type is GSM-R OR FRMCS+GSM-R)|3.18.4.3.6<br>5.4.3.2 S3<br>5.4.5.3 j<br>|
|7|Mission with one radio system|(train is at standstill) AND (Driver ID is valid) AND<br>(mode is SB/FS/LS/SR/OS/NL/PT/UN/SN) AND<br>(ERTMS/ETCS<br>level<br>is<br>valid)<br>AND<br>(ERTMS/ETCS level is 2/3) AND (Radio Network<br>type is FRMCS+GSM-R) AND (both radio<br>systems are installed on-board)<br>AND<br>(((FRMCS on-board is registered to the FRMCS<br>Radio Network) AND (no GSM-R Mobile Terminal<br>registered to a GSM-R Radio Network)) OR<br>((FRMCS on-board is not registered to the<br>FRMCS Radio Network) AND (at least one<br>GSM-R Mobile Terminal registered to a GSM-R<br>Radio Network)))|5.4.3.2 S5<br>|


**Table 37 – Button / selection label**


11.2.5.7 Figure 113 shows the presentation of the “Radio data” window.





Version 4.0.0 PAGE 180 OF 317


**ERA ERTMS unit**

**ETCS Driver Machine Interface**


|Col1|150<br>100 200<br>0<br>50 300<br>0 400|Col3|Col4|Col5|Col6|Radio data<br>Contact last RBC Use short number<br>Enter RBC data<br>Radio network type GSM-R network ID<br>Mission with one<br>radio system|
|---|---|---|---|---|---|---|
||||||||
|**2**|**2**||||||
||||||||
||||||||
||||||||
||||||||
||||||||













|Col1|150<br>100 200<br>0<br>50 300<br>0 400|Col3|Col4|Col5|Col6|Col7|Radio data<br>1 - Contact last RBC<br>2 - Use short number<br>3 - Enter RBC data<br>5 - Radio network type<br>6 - GSM-R network ID<br>7 - Mission with one radio<br>system|Col9|Col10|Col11|Col12|Col13|
|---|---|---|---|---|---|---|---|---|---|---|---|---|
||**0**<br> <br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**0**<br> <br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**0**<br> <br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**0**<br> <br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**0**<br> <br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**0**<br> <br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|1 - Contact last RBC<br>2 - Use short number<br>3 - Enter RBC data<br>5 - Radio network type<br>6 - GSM-R network ID<br>7 - Mission with one radio<br>   system<br>Radio data|1 - Contact last RBC<br>2 - Use short number<br>3 - Enter RBC data<br>5 - Radio network type<br>6 - GSM-R network ID<br>7 - Mission with one radio<br>   system<br>Radio data|1 - Contact last RBC<br>2 - Use short number<br>3 - Enter RBC data<br>5 - Radio network type<br>6 - GSM-R network ID<br>7 - Mission with one radio<br>   system<br>Radio data|1 - Contact last RBC<br>2 - Use short number<br>3 - Enter RBC data<br>5 - Radio network type<br>6 - GSM-R network ID<br>7 - Mission with one radio<br>   system<br>Radio data|1 - Contact last RBC<br>2 - Use short number<br>3 - Enter RBC data<br>5 - Radio network type<br>6 - GSM-R network ID<br>7 - Mission with one radio<br>   system<br>Radio data||
||**0**<br> <br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**0**<br> <br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**0**<br> <br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**0**<br> <br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**0**<br> <br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**0**<br> <br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|1 - Contact last RBC<br>2 - Use short number<br>3 - Enter RBC data<br>5 - Radio network type<br>6 - GSM-R network ID<br>7 - Mission with one radio<br>   system<br>Radio data|1 - Contact last RBC<br>2 - Use short number<br>3 - Enter RBC data<br>5 - Radio network type<br>6 - GSM-R network ID<br>7 - Mission with one radio<br>   system<br>Radio data|1 - Contact last RBC<br>2 - Use short number<br>3 - Enter RBC data<br>5 - Radio network type<br>6 - GSM-R network ID<br>7 - Mission with one radio<br>   system<br>Radio data|1 - Contact last RBC<br>2 - Use short number<br>3 - Enter RBC data<br>5 - Radio network type<br>6 - GSM-R network ID<br>7 - Mission with one radio<br>   system<br>Radio data|1 - Contact last RBC<br>2 - Use short number<br>3 - Enter RBC data<br>5 - Radio network type<br>6 - GSM-R network ID<br>7 - Mission with one radio<br>   system<br>Radio data||
||**0**<br> <br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**0**<br> <br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**0**<br> <br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**0**<br> <br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**0**<br> <br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**0**<br> <br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|1 - Contact last RBC<br>2 - Use short number<br>3 - Enter RBC data<br>5 - Radio network type<br>6 - GSM-R network ID<br>7 - Mission with one radio<br>   system<br>Radio data|1 - Contact last RBC<br>2 - Use short number<br>3 - Enter RBC data<br>5 - Radio network type<br>6 - GSM-R network ID<br>7 - Mission with one radio<br>   system<br>Radio data|1 - Contact last RBC<br>2 - Use short number<br>3 - Enter RBC data<br>5 - Radio network type<br>6 - GSM-R network ID<br>7 - Mission with one radio<br>   system<br>Radio data|1 - Contact last RBC<br>2 - Use short number<br>3 - Enter RBC data<br>5 - Radio network type<br>6 - GSM-R network ID<br>7 - Mission with one radio<br>   system<br>Radio data|1 - Contact last RBC<br>2 - Use short number<br>3 - Enter RBC data<br>5 - Radio network type<br>6 - GSM-R network ID<br>7 - Mission with one radio<br>   system<br>Radio data||
||**0**<br> <br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**0**<br> <br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**0**<br> <br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**0**<br> <br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**0**<br> <br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**0**<br> <br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|1 - Contact last RBC<br>2 - Use short number<br>3 - Enter RBC data<br>5 - Radio network type<br>6 - GSM-R network ID<br>7 - Mission with one radio<br>   system<br>Radio data|1 - Contact last RBC<br>2 - Use short number<br>3 - Enter RBC data<br>5 - Radio network type<br>6 - GSM-R network ID<br>7 - Mission with one radio<br>   system<br>Radio data|1 - Contact last RBC<br>2 - Use short number<br>3 - Enter RBC data<br>5 - Radio network type<br>6 - GSM-R network ID<br>7 - Mission with one radio<br>   system<br>Radio data|1 - Contact last RBC<br>2 - Use short number<br>3 - Enter RBC data<br>5 - Radio network type<br>6 - GSM-R network ID<br>7 - Mission with one radio<br>   system<br>Radio data|1 - Contact last RBC<br>2 - Use short number<br>3 - Enter RBC data<br>5 - Radio network type<br>6 - GSM-R network ID<br>7 - Mission with one radio<br>   system<br>Radio data||
||**0**<br> <br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**0**<br> <br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**0**<br> <br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**0**<br> <br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**0**<br> <br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**0**<br> <br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|1 - Contact last RBC<br>2 - Use short number<br>3 - Enter RBC data<br>5 - Radio network type<br>6 - GSM-R network ID<br>7 - Mission with one radio<br>   system<br>Radio data|1 - Contact last RBC<br>2 - Use short number<br>3 - Enter RBC data<br>5 - Radio network type<br>6 - GSM-R network ID<br>7 - Mission with one radio<br>   system<br>Radio data|1 - Contact last RBC<br>2 - Use short number<br>3 - Enter RBC data<br>5 - Radio network type<br>6 - GSM-R network ID<br>7 - Mission with one radio<br>   system<br>Radio data|1 - Contact last RBC<br>2 - Use short number<br>3 - Enter RBC data<br>5 - Radio network type<br>6 - GSM-R network ID<br>7 - Mission with one radio<br>   system<br>Radio data|1 - Contact last RBC<br>2 - Use short number<br>3 - Enter RBC data<br>5 - Radio network type<br>6 - GSM-R network ID<br>7 - Mission with one radio<br>   system<br>Radio data||
|**2**|||||||||||||
||||||||||||||
||||||||||||||
|1|2|3|||5|6|6|7|||||


**Figure 113 – Radio data window**


**11.3** **Data entry Windows**


**11.3.1** **Train running number window**


11.3.1.1 The Train running number window shall comply with the requirements in chapter 10.3 for
a window on half grid array containing a single input field with only the data part.


11.3.1.2 The window title shall indicate “Train running number”.


Version 4.0.0 PAGE 181 OF 317


**ERA ERTMS unit**

**ETCS Driver Machine Interface**


11.3.1.3 The single input field shall be used for the entry / revalidation of the train running number.


11.3.1.4 The keyboard associated to the train running number shall be a numeric keyboard.


11.3.1.5 Figure 114 shows the presentation of the Train running number window.












|Col1|Col2|Col3|150<br>100 200<br>0<br>50 300<br>0 400|Col5|Col6|Col7|Col8|Train running number<br>45678|Col10|Col11|Col12|
|---|---|---|---|---|---|---|---|---|---|---|---|
|||||||||||||
|||||||||1|1|2|3|
|||||||||4|4|5|6|
|||||||||||||
|**2**|**2**|**2**||||||7|7|8|9|
|||||||||||||
|||||||||Del|Del|0|**.**|
|||||||||||||
|||||||||||||
|||||||||||||
|||||||||||||





|Col1|Col2|Col3|150<br>100 200<br>0<br>50 300<br>0 400|Col5|Col6|Col7|Col8|Col9|Col10|Col11|Train running number<br>Del<br>45678|Col13|Col14|Col15|Col16|Col17|
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
||||**0**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**0**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**0**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**0**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**0**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**0**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**0**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**0**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|Del<br>Train running number<br>45678|Del<br>Train running number<br>45678|Del<br>Train running number<br>45678|Del<br>Train running number<br>45678|Del<br>Train running number<br>45678|Del|
||||||||||||45678|45678|45678|45678|45678|45678|
||||||||||||||||||
||||||||||||||||||
||||||||||||||||||
||||||||||||||||||
||||||||||||||||||
|**2**|**2**|**2**|||||||||||||||
||||||||||||||||||
||||||||||||||||||
||||||||||||||||||
||||||||||||||||||
||||||||||||||||||
||||||||||||||||||
|1|1|1|2|3|3|4|4|**5**|**5**|**6**|**6**|7|8|9|0|0|


**Figure 114 – Train running number window**


**11.3.2** **ERTMS/ETCS level window**


11.3.2.1 The ERTMS/ETCS level window shall comply with the requirements in chapter 10.3 for a
window on half grid array containing a single input field with only the data part.


Version 4.0.0 PAGE 182 OF 317


**ERA ERTMS unit**

**ETCS Driver Machine Interface**


11.3.2.2 The window title shall indicate “Level”.


11.3.2.3 The single input field shall be used for the entry / revalidation of the ERTMS/ETCS level.


11.3.2.4 The keyboard associated to the ERTMS/ETCS level shall be a dedicated keyboard as
specified in Table 38 displaying the ERTMS/ETCS level(s).

|Button /selection #|Label|
|---|---|
|1|Level 1|
|2|Level 2|
|4|Level 0|
|5|NTC A|
|6|NTC B|
|7|NTC C|
|8|NTC D|
|9|NTC E|
|...|...|



**Table 38 – Keyboard for ERTMS/ETCS level**


11.3.2.5 The buttons / selections #1, 2, 4 shall be reserved respectively for the ERTMS/ETCS
levels 1, 2, 0.


11.3.2.6 For NTC levels, the labels ‘NTC A’, ‘NTC B’, ... shall be replaced by the distinct
abbreviations of the concerned National Systems (its definition is inherent to the National
System and is outside the scope of this specification).


11.3.2.7 When a table of priority of trackside supported levels (see document [2] for further details)
is available onboard, only the buttons corresponding to ERTMS/ETCS levels contained in
the table of priority of trackside supported levels shall be enabled; the other buttons shall
be disabled.


11.3.2.8 When a table of priority of trackside supported levels is not available onboard, only the
buttons corresponding to ERTMS/ETCS levels contained in the default list of levels
configured on-board shall be enabled; the other buttons shall be disabled.


11.3.2.9 Figure 115 shows the presentation of the ERTMS/ETCS level window (with 6 National
Systems).


Version 4.0.0 PAGE 183 OF 317


**ERA ERTMS unit**

**ETCS Driver Machine Interface**




|Col1|150<br>100 200<br>0<br>50 300<br>0 400|Col3|Level<br>Level 2<br>Level 1 Level 2|Col5|Col6|
|---|---|---|---|---|---|
||**0**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**0**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|Level 0|NTC A|NTC B|
|||||||
||||NTC C|NTC D|NTC E|
|||||||
||||NTC F|NTC F|NTC F|
|||||||
|||||||
|||||||







|Col1|150<br>100 200<br>0<br>50 300<br>0 400|Col3|Col4|Col5|Col6|Col7|Col8|Col9|Level<br>Level 2|Col11|Col12|Col13|Col14|Col15|
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
||**0**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**0**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**0**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**0**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**0**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**0**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**0**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**0**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|Level<br>Level 2|Level<br>Level 2|Level<br>Level 2|Level<br>Level 2|Level<br>Level 2||
||||||||||Level 2|Level 2|Level 2|Level 2|Level 2|Level 2|
||||||||||1 - Level 1<br>2 - Level 2<br>4 - Level 0<br>5 - NTC A<br>6 - NTC B<br>7 - NTC C<br>8 - NTC D<br>9 - NTC E<br>10 - NTC F|1 - Level 1<br>2 - Level 2<br>4 - Level 0<br>5 - NTC A<br>6 - NTC B<br>7 - NTC C<br>8 - NTC D<br>9 - NTC E<br>10 - NTC F|1 - Level 1<br>2 - Level 2<br>4 - Level 0<br>5 - NTC A<br>6 - NTC B<br>7 - NTC C<br>8 - NTC D<br>9 - NTC E<br>10 - NTC F|1 - Level 1<br>2 - Level 2<br>4 - Level 0<br>5 - NTC A<br>6 - NTC B<br>7 - NTC C<br>8 - NTC D<br>9 - NTC E<br>10 - NTC F|1 - Level 1<br>2 - Level 2<br>4 - Level 0<br>5 - NTC A<br>6 - NTC B<br>7 - NTC C<br>8 - NTC D<br>9 - NTC E<br>10 - NTC F||
||||||||||1 - Level 1<br>2 - Level 2<br>4 - Level 0<br>5 - NTC A<br>6 - NTC B<br>7 - NTC C<br>8 - NTC D<br>9 - NTC E<br>10 - NTC F|1 - Level 1<br>2 - Level 2<br>4 - Level 0<br>5 - NTC A<br>6 - NTC B<br>7 - NTC C<br>8 - NTC D<br>9 - NTC E<br>10 - NTC F|1 - Level 1<br>2 - Level 2<br>4 - Level 0<br>5 - NTC A<br>6 - NTC B<br>7 - NTC C<br>8 - NTC D<br>9 - NTC E<br>10 - NTC F|1 - Level 1<br>2 - Level 2<br>4 - Level 0<br>5 - NTC A<br>6 - NTC B<br>7 - NTC C<br>8 - NTC D<br>9 - NTC E<br>10 - NTC F|1 - Level 1<br>2 - Level 2<br>4 - Level 0<br>5 - NTC A<br>6 - NTC B<br>7 - NTC C<br>8 - NTC D<br>9 - NTC E<br>10 - NTC F||
||||||||||1 - Level 1<br>2 - Level 2<br>4 - Level 0<br>5 - NTC A<br>6 - NTC B<br>7 - NTC C<br>8 - NTC D<br>9 - NTC E<br>10 - NTC F|1 - Level 1<br>2 - Level 2<br>4 - Level 0<br>5 - NTC A<br>6 - NTC B<br>7 - NTC C<br>8 - NTC D<br>9 - NTC E<br>10 - NTC F|1 - Level 1<br>2 - Level 2<br>4 - Level 0<br>5 - NTC A<br>6 - NTC B<br>7 - NTC C<br>8 - NTC D<br>9 - NTC E<br>10 - NTC F|1 - Level 1<br>2 - Level 2<br>4 - Level 0<br>5 - NTC A<br>6 - NTC B<br>7 - NTC C<br>8 - NTC D<br>9 - NTC E<br>10 - NTC F|1 - Level 1<br>2 - Level 2<br>4 - Level 0<br>5 - NTC A<br>6 - NTC B<br>7 - NTC C<br>8 - NTC D<br>9 - NTC E<br>10 - NTC F||
||||||||||||||||
||||||||||||||||
||||||||||||||||
||||||||||||||||
||||||||||||||||
||||||||||||||||
||||||||||||||||
||||||||||||||||
|1|2|||4|4|**5**|**5**|**6**|**6**|7|8|9|10|10|


**Figure 115 – ERTMS/ETCS level window**





**11.3.3** **Driver ID window**


11.3.3.1 The Driver ID window shall comply with the requirements in chapter 10.3 for a window on
half grid array containing a single input field with only the data part.


11.3.3.2 The window title shall indicate “Driver ID”.


11.3.3.3 The single input field shall be used for the entry / revalidation of the Driver ID.


11.3.3.4 The keyboard associated to the Driver ID shall be an alphanumeric keyboard.


Version 4.0.0 PAGE 184 OF 317


**ERA ERTMS unit**

**ETCS Driver Machine Interface**


11.3.3.5 When the onboard is in the step S1 of the start up dialogue sequence (see 11.7.2), the
Driver ID window shall also present a ‘settings’ button with the symbol SE04 and a ‘train
running number’ button with the label ’TRN’.


11.3.3.6 The ‘settings’ button shall be positioned:

a) For touch screen technology: in the bottom right corner of D/F/G area with a size of

82 x 50 cells (w x h) i.e. at the position (224,400),

b) For soft key technology: in H6.


11.3.3.7 The ‘train running number’ button shall be positioned:

a) For touch screen technology: left aligned of the ‘setting’ button with a size of 82 x 50

cells (w x h) i.e. at the position (142,400),

b) For soft key technology: in H5.


11.3.3.8 Figure 116 shows the presentation of the Driver ID window.


Version 4.0.0 PAGE 185 OF 317


**ERA ERTMS unit**

**ETCS Driver Machine Interface**












|Col1|150<br>100 200<br>0<br>50 300<br>0 400|Col3|Col4|Col5|Col6|Driver ID<br>1234 567<br>1 2 3<br>abc def|Col8|Col9|Col10|Col11|Col12|
|---|---|---|---|---|---|---|---|---|---|---|---|
|||||||||||||
|||||||1|1|1|1|3 def|3 def|
|||||||4 ghi|4 ghi|5 jkl|5 jkl|6 mno|6 mno|
|||||||||||||
|**2**|**2**|||||7 pqrs|7 pqrs|8 tuv|8 tuv|9 wxyz|9 wxyz|
|||||||||||||
|||||||Del|Del|0|0|.|.|
|||||||||||||
||||||||||TRN|TRN||
|||||||||||||





|Col1|150<br>100 200<br>0<br>50 300<br>0 400|Col3|Col4|Col5|Col6|Col7|Col8|Col9|Driver ID<br>Del<br>1234 567|Col11|Col12|Col13|Col14|Col15|
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
||**0**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**0**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**0**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**0**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**0**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**0**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**0**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**0**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|Del<br>Driver ID<br>1234 567|Del<br>Driver ID<br>1234 567|Del<br>Driver ID<br>1234 567|Del<br>Driver ID<br>1234 567|Del<br>Driver ID<br>1234 567|Del|
||||||||||1234 567|1234 567|1234 567|1234 567|1234 567|1234 567|
||||||||||||||||
||||||||||||||||
|||||||||||||||TRN|
||||||||||||||||
||||||||||||||||
|**2**|||||||||||||||
||||||||||||||||
||||||||||||||||
||||||||||||||||
||||||||||||||||
||||||||||||||||
|1|2 abc|3 def|3 def|4 ghi|4 ghi|5 jkl|5 jkl|6 mno|6 mno|7 pqrs|8 tuv|9 wxyz|0|0|


**Figure 116 – Driver ID window**


**11.3.4** **GSM-R network ID window**


11.3.4.1 The GSM-R network ID window shall comply with the requirements in chapter 10.3 for a
window on half grid array containing a single input field with only the data part


11.3.4.2 The window title shall indicate “GSM-R network ID”.


11.3.4.3 The single input field shall be used for the entry / revalidation of the GSM-R Radio Network
ID.


Version 4.0.0 PAGE 186 OF 317


**ERA ERTMS unit**

**ETCS Driver Machine Interface**


11.3.4.4 The keyboard associated to the Radio network ID shall be a dedicated keyboard
corresponding to the alphanumeric list of available and allowed GSM-R Radio Networks
acquired following the driver’s action on the ‘Radio network ID’ button.


11.3.4.5 Figure 117 shows the presentation of the GSM-R network ID window.








|Col1|150<br>100 200<br>0<br>50 300<br>0 400|Col3|Col4|Col5|Col6|GSM-R network ID<br>GSMR-A|Col8|Col9|
|---|---|---|---|---|---|---|---|---|
||**0**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**0**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**0**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**0**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**0**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|GSMR-A|GSMR-B|Telecom X|
||**0**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**0**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**0**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**0**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**0**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**||||
|**2**|||||||||
||||||||||
||||||||||









|Col1|150<br>100 200<br>0<br>50 300<br>0 400|Col3|Col4|Col5|Col6|Col7|Col8|GSM-R network ID<br>GSMR-A<br>1 - GSMR-A<br>2 - GSMR-B<br>3 - Telecom X|Col10|Col11|Col12|Col13|Col14|
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
||**0**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**0**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**0**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**0**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**0**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**0**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**0**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|1 - GSMR-A<br>2 - GSMR-B<br>3 - Telecom X<br>GSM-R network ID<br>GSMR-A|1 - GSMR-A<br>2 - GSMR-B<br>3 - Telecom X<br>GSM-R network ID<br>GSMR-A|1 - GSMR-A<br>2 - GSMR-B<br>3 - Telecom X<br>GSM-R network ID<br>GSMR-A|1 - GSMR-A<br>2 - GSMR-B<br>3 - Telecom X<br>GSM-R network ID<br>GSMR-A|1 - GSMR-A<br>2 - GSMR-B<br>3 - Telecom X<br>GSM-R network ID<br>GSMR-A||
|||||||||||||||
|||||||||||||||
|||||||||||||||
|||||||||||||||
|||||||||||||||
|||||||||||||||
|**2**||||||||||||||
|||||||||||||||
|||||||||||||||
|||||||||||||||
|||||||||||||||
|||||||||||||||
|1|2|3|3|||||||||||


**Figure 117 – GSM-R network ID window**


**11.3.5** **RBC data window**


Version 4.0.0 PAGE 187 OF 317


**ERA ERTMS unit**

**ETCS Driver Machine Interface**


11.3.5.1 The RBC data window shall comply with the requirements in chapter 10.3 for a window
on total grid array with the question ‘RBC data entry complete?’ but no echo texts.


11.3.5.2 The window title shall indicate “RBC data”.


11.3.5.3 The 1 [st] input field with the label ‘RBC ID’ shall be used for the entry / revalidation of the
RBC ID.


11.3.5.3.1 When converting the entered RBC ID into binary format, the 14 less significant bits shall

form the variable NID_RBC and the remaining bits (max 10 bits) shall form the variable
NID_C (see [2] chapter 7 for the definitions of NID_C and NID_RBC).


11.3.5.4 The 2 [nd] input field with the label ‘RBC phone number’ shall exist only if the Radio Network
type stored on-board is GSM-R or FRMCS+GSM-R while GSM-R is installed on-board
and if existing, it shall be used for the entry / revalidation of the RBC telephone number.


11.3.5.5 The keyboards associated to the 2 input field(s) shall be numeric keyboards.


11.3.5.6 Figure 118 shows the presentation of the RBC data window.


Version 4.0.0 PAGE 188 OF 317


**ERA ERTMS unit**

**ETCS Driver Machine Interface**


















|RBC data entry complete?|1|Col3|2|3|
|---|---|---|---|---|
|RBC data entry complete?|4|4|5|6|
|RBC data entry complete?|7|7|8|9|
|RBC data entry complete?|Del|Del|0|**.**|
|Yes|||||









|RBC data<br>RBC ID 1234 5678<br>Del<br>1234 5678<br>RBC phone number<br>9012 3456<br>RBC data entry complete?<br>Yes|Col2|Col3|Col4|Col5|Col6|Col7|Col8|Col9|Col10|Col11|Col12|Col13|
|---|---|---|---|---|---|---|---|---|---|---|---|---|
|Del<br>RBC data<br>RBC data entry complete?<br>1234 5678<br>9012 3456<br>1234 5678<br>RBC ID<br>RBC phone number<br>Yes|Del<br>RBC data<br>RBC data entry complete?<br>1234 5678<br>9012 3456<br>1234 5678<br>RBC ID<br>RBC phone number<br>Yes|Del<br>RBC data<br>RBC data entry complete?<br>1234 5678<br>9012 3456<br>1234 5678<br>RBC ID<br>RBC phone number<br>Yes|Del<br>RBC data<br>RBC data entry complete?<br>1234 5678<br>9012 3456<br>1234 5678<br>RBC ID<br>RBC phone number<br>Yes|Del<br>RBC data<br>RBC data entry complete?<br>1234 5678<br>9012 3456<br>1234 5678<br>RBC ID<br>RBC phone number<br>Yes|Del<br>RBC data<br>RBC data entry complete?<br>1234 5678<br>9012 3456<br>1234 5678<br>RBC ID<br>RBC phone number<br>Yes|RBC ID|RBC ID|RBC ID|1234 5678|1234 5678|1234 5678|1234 5678|
|Del<br>RBC data<br>RBC data entry complete?<br>1234 5678<br>9012 3456<br>1234 5678<br>RBC ID<br>RBC phone number<br>Yes|Del<br>RBC data<br>RBC data entry complete?<br>1234 5678<br>9012 3456<br>1234 5678<br>RBC ID<br>RBC phone number<br>Yes|Del<br>RBC data<br>RBC data entry complete?<br>1234 5678<br>9012 3456<br>1234 5678<br>RBC ID<br>RBC phone number<br>Yes|Del<br>RBC data<br>RBC data entry complete?<br>1234 5678<br>9012 3456<br>1234 5678<br>RBC ID<br>RBC phone number<br>Yes|Del<br>RBC data<br>RBC data entry complete?<br>1234 5678<br>9012 3456<br>1234 5678<br>RBC ID<br>RBC phone number<br>Yes|Del<br>RBC data<br>RBC data entry complete?<br>1234 5678<br>9012 3456<br>1234 5678<br>RBC ID<br>RBC phone number<br>Yes|RBC ID|RBC ID|RBC ID|1234 5678|1234 5678|1234 5678|Del|
|Del<br>RBC data<br>RBC data entry complete?<br>1234 5678<br>9012 3456<br>1234 5678<br>RBC ID<br>RBC phone number<br>Yes|Del<br>RBC data<br>RBC data entry complete?<br>1234 5678<br>9012 3456<br>1234 5678<br>RBC ID<br>RBC phone number<br>Yes|Del<br>RBC data<br>RBC data entry complete?<br>1234 5678<br>9012 3456<br>1234 5678<br>RBC ID<br>RBC phone number<br>Yes|Del<br>RBC data<br>RBC data entry complete?<br>1234 5678<br>9012 3456<br>1234 5678<br>RBC ID<br>RBC phone number<br>Yes|Del<br>RBC data<br>RBC data entry complete?<br>1234 5678<br>9012 3456<br>1234 5678<br>RBC ID<br>RBC phone number<br>Yes|Del<br>RBC data<br>RBC data entry complete?<br>1234 5678<br>9012 3456<br>1234 5678<br>RBC ID<br>RBC phone number<br>Yes|1234 5678<br>9012 3456<br>RBC phone number|1234 5678<br>9012 3456<br>RBC phone number|1234 5678<br>9012 3456<br>RBC phone number|1234 5678<br>9012 3456<br>RBC phone number|1234 5678<br>9012 3456<br>RBC phone number|1234 5678<br>9012 3456<br>RBC phone number|1234 5678<br>9012 3456<br>RBC phone number|
|Del<br>RBC data<br>RBC data entry complete?<br>1234 5678<br>9012 3456<br>1234 5678<br>RBC ID<br>RBC phone number<br>Yes|Del<br>RBC data<br>RBC data entry complete?<br>1234 5678<br>9012 3456<br>1234 5678<br>RBC ID<br>RBC phone number<br>Yes|Del<br>RBC data<br>RBC data entry complete?<br>1234 5678<br>9012 3456<br>1234 5678<br>RBC ID<br>RBC phone number<br>Yes|Del<br>RBC data<br>RBC data entry complete?<br>1234 5678<br>9012 3456<br>1234 5678<br>RBC ID<br>RBC phone number<br>Yes|Del<br>RBC data<br>RBC data entry complete?<br>1234 5678<br>9012 3456<br>1234 5678<br>RBC ID<br>RBC phone number<br>Yes|Del<br>RBC data<br>RBC data entry complete?<br>1234 5678<br>9012 3456<br>1234 5678<br>RBC ID<br>RBC phone number<br>Yes|1234 5678<br>9012 3456<br>RBC phone number|1234 5678<br>9012 3456<br>RBC phone number|1234 5678<br>9012 3456<br>RBC phone number|1234 5678<br>9012 3456<br>RBC phone number|1234 5678<br>9012 3456<br>RBC phone number|1234 5678<br>9012 3456<br>RBC phone number||
|Del<br>RBC data<br>RBC data entry complete?<br>1234 5678<br>9012 3456<br>1234 5678<br>RBC ID<br>RBC phone number<br>Yes|Del<br>RBC data<br>RBC data entry complete?<br>1234 5678<br>9012 3456<br>1234 5678<br>RBC ID<br>RBC phone number<br>Yes|Del<br>RBC data<br>RBC data entry complete?<br>1234 5678<br>9012 3456<br>1234 5678<br>RBC ID<br>RBC phone number<br>Yes|Del<br>RBC data<br>RBC data entry complete?<br>1234 5678<br>9012 3456<br>1234 5678<br>RBC ID<br>RBC phone number<br>Yes|Del<br>RBC data<br>RBC data entry complete?<br>1234 5678<br>9012 3456<br>1234 5678<br>RBC ID<br>RBC phone number<br>Yes|Del<br>RBC data<br>RBC data entry complete?<br>1234 5678<br>9012 3456<br>1234 5678<br>RBC ID<br>RBC phone number<br>Yes|1234 5678<br>9012 3456<br>RBC phone number|1234 5678<br>9012 3456<br>RBC phone number|1234 5678<br>9012 3456<br>RBC phone number|1234 5678<br>9012 3456<br>RBC phone number|1234 5678<br>9012 3456<br>RBC phone number|1234 5678<br>9012 3456<br>RBC phone number||
|Del<br>RBC data<br>RBC data entry complete?<br>1234 5678<br>9012 3456<br>1234 5678<br>RBC ID<br>RBC phone number<br>Yes|Del<br>RBC data<br>RBC data entry complete?<br>1234 5678<br>9012 3456<br>1234 5678<br>RBC ID<br>RBC phone number<br>Yes|Del<br>RBC data<br>RBC data entry complete?<br>1234 5678<br>9012 3456<br>1234 5678<br>RBC ID<br>RBC phone number<br>Yes|Del<br>RBC data<br>RBC data entry complete?<br>1234 5678<br>9012 3456<br>1234 5678<br>RBC ID<br>RBC phone number<br>Yes|Del<br>RBC data<br>RBC data entry complete?<br>1234 5678<br>9012 3456<br>1234 5678<br>RBC ID<br>RBC phone number<br>Yes|Del<br>RBC data<br>RBC data entry complete?<br>1234 5678<br>9012 3456<br>1234 5678<br>RBC ID<br>RBC phone number<br>Yes|1234 5678<br>9012 3456<br>RBC phone number|1234 5678<br>9012 3456<br>RBC phone number|1234 5678<br>9012 3456<br>RBC phone number|1234 5678<br>9012 3456<br>RBC phone number|1234 5678<br>9012 3456<br>RBC phone number|1234 5678<br>9012 3456<br>RBC phone number||
|Del<br>RBC data<br>RBC data entry complete?<br>1234 5678<br>9012 3456<br>1234 5678<br>RBC ID<br>RBC phone number<br>Yes|Del<br>RBC data<br>RBC data entry complete?<br>1234 5678<br>9012 3456<br>1234 5678<br>RBC ID<br>RBC phone number<br>Yes|Del<br>RBC data<br>RBC data entry complete?<br>1234 5678<br>9012 3456<br>1234 5678<br>RBC ID<br>RBC phone number<br>Yes|Del<br>RBC data<br>RBC data entry complete?<br>1234 5678<br>9012 3456<br>1234 5678<br>RBC ID<br>RBC phone number<br>Yes|Del<br>RBC data<br>RBC data entry complete?<br>1234 5678<br>9012 3456<br>1234 5678<br>RBC ID<br>RBC phone number<br>Yes|Del<br>RBC data<br>RBC data entry complete?<br>1234 5678<br>9012 3456<br>1234 5678<br>RBC ID<br>RBC phone number<br>Yes|1234 5678<br>9012 3456<br>RBC phone number|1234 5678<br>9012 3456<br>RBC phone number|1234 5678<br>9012 3456<br>RBC phone number|1234 5678<br>9012 3456<br>RBC phone number|1234 5678<br>9012 3456<br>RBC phone number|1234 5678<br>9012 3456<br>RBC phone number||
|Del<br>RBC data<br>RBC data entry complete?<br>1234 5678<br>9012 3456<br>1234 5678<br>RBC ID<br>RBC phone number<br>Yes|Del<br>RBC data<br>RBC data entry complete?<br>1234 5678<br>9012 3456<br>1234 5678<br>RBC ID<br>RBC phone number<br>Yes|Del<br>RBC data<br>RBC data entry complete?<br>1234 5678<br>9012 3456<br>1234 5678<br>RBC ID<br>RBC phone number<br>Yes|Del<br>RBC data<br>RBC data entry complete?<br>1234 5678<br>9012 3456<br>1234 5678<br>RBC ID<br>RBC phone number<br>Yes|Del<br>RBC data<br>RBC data entry complete?<br>1234 5678<br>9012 3456<br>1234 5678<br>RBC ID<br>RBC phone number<br>Yes|Del<br>RBC data<br>RBC data entry complete?<br>1234 5678<br>9012 3456<br>1234 5678<br>RBC ID<br>RBC phone number<br>Yes|1234 5678<br>9012 3456<br>RBC phone number|1234 5678<br>9012 3456<br>RBC phone number|1234 5678<br>9012 3456<br>RBC phone number|1234 5678<br>9012 3456<br>RBC phone number|1234 5678<br>9012 3456<br>RBC phone number|1234 5678<br>9012 3456<br>RBC phone number||
|Yes|Yes|Yes|Yes|Yes|Yes|Yes|Yes|Yes|Yes|Yes|Yes|Yes|
|1|2|3|4|5|6|6|7|8|8|9|0|0|
||||||||||||||


**Figure 118 – RBC data window**


**11.3.6** **Language window**


11.3.6.1 The Language window shall comply with the requirements in chapter 10.3 for a window
on half grid array containing a single input field with only the data part.


11.3.6.2 The window title shall indicate “Language”.


11.3.6.3 The single input field shall be used for the entry / revalidation of the language.


Version 4.0.0 PAGE 189 OF 317


**ERA ERTMS unit**

**ETCS Driver Machine Interface**


11.3.6.4 The keyboard associated to the language shall be a dedicated keyboard displaying the
possible language(s) in its (their) own language.


11.3.6.4.1 Note: the possible language(s) depends on the onboard configuration.


11.3.6.5 Figure 119 shows the presentation of the language window.



|Col1|Col2|Col3|150<br>100 200<br>0<br>50 300<br>0 400|Col5|Col6|Col7|Col8|Language|Col10|Col11|
|---|---|---|---|---|---|---|---|---|---|---|
|||||||||English|English|English|
||||||||||||
|||||||||Deutsch|English|Francais|
|||||||||Nederlands|Nederlands|Nederlands|
||||||||||||
|**2**|**2**|**2**|||||||||
||||||||||||
||||||||||||
||||||||||||
||||||||||||
||||||||||||
||||||||||||


|Col1|Col2|Col3|150<br>100 200<br>0<br>50 300<br>0 400|Col5|Col6|Col7|Col8|Col9|Col10|Col11|Language<br>English|Col13|Col14|Col15|Col16|Col17|
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
||||**0**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**0**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**0**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**0**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**0**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**0**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**0**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**0**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|Language<br>English|Language<br>English|Language<br>English|Language<br>English|Language<br>English||
||||||||||||English|English|English|English|English|English|
||||||||||||1 - Deutsch<br>2 - English<br>3 - Francais<br>4 - Nederlands|1 - Deutsch<br>2 - English<br>3 - Francais<br>4 - Nederlands|1 - Deutsch<br>2 - English<br>3 - Francais<br>4 - Nederlands|1 - Deutsch<br>2 - English<br>3 - Francais<br>4 - Nederlands|1 - Deutsch<br>2 - English<br>3 - Francais<br>4 - Nederlands||
||||||||||||1 - Deutsch<br>2 - English<br>3 - Francais<br>4 - Nederlands|1 - Deutsch<br>2 - English<br>3 - Francais<br>4 - Nederlands|1 - Deutsch<br>2 - English<br>3 - Francais<br>4 - Nederlands|1 - Deutsch<br>2 - English<br>3 - Francais<br>4 - Nederlands|1 - Deutsch<br>2 - English<br>3 - Francais<br>4 - Nederlands||
||||||||||||1 - Deutsch<br>2 - English<br>3 - Francais<br>4 - Nederlands|1 - Deutsch<br>2 - English<br>3 - Francais<br>4 - Nederlands|1 - Deutsch<br>2 - English<br>3 - Francais<br>4 - Nederlands|1 - Deutsch<br>2 - English<br>3 - Francais<br>4 - Nederlands|1 - Deutsch<br>2 - English<br>3 - Francais<br>4 - Nederlands||
||||||||||||||||||
||||||||||||||||||
|**2**|**2**|**2**|||||||||||||||
||||||||||||||||||
||||||||||||||||||
||||||||||||||||||
||||||||||||||||||
||||||||||||||||||
||||||||||||||||||
|1|1|1|2|3|3|4|4||||||||||


Version 4.0.0 PAGE 190 OF 317











**Figure 119 – Language window**


**11.3.7** **Volume window**


**ERA ERTMS unit**

**ETCS Driver Machine Interface**


11.3.7.1 The Volume window shall comply with the requirements in chapter 10.3 for a window on
half grid array containing a single input field with only the data part.


11.3.7.2 The window title shall indicate “Volume”.


11.3.7.3 The single input field shall be used for the entry / revalidation of the volume.


11.3.7.4 The keyboard associated to the volume shall be a dedicated keyboard.


11.3.7.4.1 Note: the definition of the keyboard is an implementation issue; e.g. several buttons for

different levels of volume, 2 buttons to respectively decrease/increase the volume level,...


**11.3.8** **Brightness window**


11.3.8.1 The Brightness window shall comply with the requirements in chapter 10.3 for a window
on half grid array containing a single input field with only the data part.


11.3.8.2 The window title shall indicate “Brightness”.


11.3.8.3 The single input field shall be used for the entry / revalidation of the luminance.


11.3.8.4 The keyboard associated to the luminance shall be a dedicated keyboard.


11.3.8.4.1 Note: the definition of the keyboard is an implementation issue; e.g. several buttons for

different levels of luminance, 2 buttons to respectively decrease/increase the luminance
level,...


**11.3.9** **Train data window(s)**


11.3.9.1 The Train data window(s) shall comply with the requirements in chapter 10.3 for a window
on total grid array with echo texts and with the question ‘Train data entry complete?’.


11.3.9.2 The window title shall indicate “Train data”.


11.3.9.3 If there are more than one Train data window, the window titles shall also comply with
5.3.1.2.1g) for the indication of the sequence number of the windows and the total number
of windows related to the train data.


11.3.9.4 When data check rules have been defined for train data, the requirements in chapter
10.3.4 shall apply for the echo texts.


11.3.9.5 The number of input fields is not mentioned since it can vary depending on:


a) the chosen procedure for the train data entry (see 11.3.9.6),


b) whether some train data are pre-configured onboard,


c) whether some train data are received from other ERTMS/ETCS external sources (e.g.

from the train interface),


d) whether train data pre-configured onboard or received from other ERTMS/ETCS

external sources are modifiable by the driver,


Version 4.0.0 PAGE 191 OF 317


**ERA ERTMS unit**

**ETCS Driver Machine Interface**


11.3.9.5.1 Note: The choice to allow or not the driver to modify a train data pre-configured onboard

or received from other ERTMS/ETCS external sources is outside of the scope of this
specification.


11.3.9.6 It shall be possible to select by configuration or by means of an input signal from the train
interface the kind of train data entry configuration to be applied amongst the following
possibilities:

a) _Fixed train data entry_ : the Train data window shall contain only one input field allowing

the driver to enter a train type amongst a number of pre-configured ones. Each train
type shall represent a combination of all train data. Once a train type is selected, the
onboard shall not offer any possibility for the driver to change any value of a specific
train data composing the selected train type.

b) _Flexible train data entry_ : the Train data entry window(s) shall contain one or more input

fields for the specific train data the driver has to enter/modify.

c) _Switchable train data entry:_ the Train data entry window(s) shall offer the possibility to

switch from a “ _Fixed train data entry”_ layout to _a “Flexible train data entry”_ layout or
vice versa.


**11.3.9.7** **Requirements applicable to “Switchable train data entry”:**


11.3.9.7.1 The Train data window(s) shall by default be presented with the layout lastly used, i.e. the

layout “Fixed train data entry” or “Flexible train data entry” shall always be retained.


11.3.9.7.2 The Train data window(s) shall present an enabled ‘switch’ button.


11.3.9.7.3 When the driver presses the ‘switch’ button, the Train data window(s) shall switch to the

other layout, i.e. to “ _Fixed train data entry”_ if the current layout is _“Flexible train data entry”_
or vice versa.


11.3.9.7.4 The label of the ‘switch’ button shall be ‘Select type’ if the Train data window(s) show a

_“Flexible train data entry”_ layout or with the label ‘Enter data’ if the Train data window(s)
show a _“Fixed train data entry”_ layout.


11.3.9.7.5 The ‘switch’ button shall be positioned:

a) For touch screen technology: in the bottom right corner of D/F/G area with a size of

60 x 50 cells (w x h) i.e. at the position (246,400),

b) For soft key technology: in the D/G/I area and above F9 with a size of 64 x 50 cells (w

x h) (i.e. at the position (178,400). The text label of the ‘switch’ button shall be in black.
The background colour shall be in medium grey. The ‘switch’ button shall have the
same border as an input field applying 5.1.1.1.4.


11.3.9.7.6 For soft key technology, when the ‘switch’ button is enabled, an associated soft key with

the same label as the ‘switch’ button shall be presented in F9 if the [Down] button has
been pressed being on the last input field or the [Up] button has been pressed being on
the first input field.


11.3.9.7.6.1 Note: the ‘switch’ button is consequently inserted between the last and the first input
fields within the circular list of input fields (see 10.3.1.25).


**11.3.9.8** **Keyboard associated to the fixed train data entry**


Version 4.0.0 PAGE 192 OF 317


**ERA ERTMS unit**

**ETCS Driver Machine Interface**


11.3.9.8.1 The keyboard associated to the train type of the fixed train data entry shall be as specified

in Table 39.

|Input Field|Keyboard|
|---|---|
|Train type|Dedicated keyboard with each key label giving the<br>name of the train type|



**Table 39 – Keyboard for fixed train data entry**


11.3.9.8.2 Note: the naming of the train types is outside of the scope of this specification.


**11.3.9.9** **Keyboards associated to the flexible train data entry**


11.3.9.9.1 The keyboards associated to the possible input field(s) of the flexible train data entry shall

be as specified in Table 40.

|Input Field|Keyboard|
|---|---|
|Train category|Dedicated keyboard|
|Length (m)|Numeric|
|Brake percentage|Numeric|
|Maximum speed (km/h)|Numeric|
|Axle load category|Dedicated keyboard|
|Airtight|Dedicated keyboard<br>Touch screen technology:<br>Key ‘7’ = No<br>Key ‘8’ = Yes<br>Soft key technology:<br>F7= No<br>F8 = Yes|
|Loading gauge|Dedicated keyboard|



**Table 40 – Keyboards for flexible train data entry**


11.3.9.9.2 The keyboard associated to the ‘Train category’, the ‘Axle load category’ and the ‘Loading

gauge’ input field shall display keys only for those ERTMS/ETCS operational train
categories, axle load categories and loading gauges relevant for the train formation(s)
(including the operational degraded situations).


11.3.9.9.3 The labels for the ‘Train category’ input field as well as their correspondence with the cant

deficiency train category values and the brake position (other international train category)
values shall be as specified in Table 41.









|ERTMS/ETCS operational train<br>category|Col2|Cant deficiency<br>train category value|Other international<br>train category value|
|---|---|---|---|
|**Type of train**|**Label**|**Label**|**Label**|
|Passenger trains (PASS)<br>|PASS 1|80 mm|Passenger train in P|
|Passenger trains (PASS)<br>|PASS 2|130 mm|Passenger train in P|


Version 4.0.0 PAGE 193 OF 317


**ERA ERTMS unit**

**ETCS Driver Machine Interface**






|Col1|PASS 3|150 mm|Passenger train in P|
|---|---|---|---|
|Tilting trains (TILT)<br> <br> <br> <br> <br> <br>|TILT 1|165 mm|Passenger train in P|
|Tilting trains (TILT)<br> <br> <br> <br> <br> <br>|TILT 2|180 mm|Passenger train in P|
|Tilting trains (TILT)<br> <br> <br> <br> <br> <br>|TILT 3|210 mm|Passenger train in P|
|Tilting trains (TILT)<br> <br> <br> <br> <br> <br>|TILT 4|225 mm|Passenger train in P|
|Tilting trains (TILT)<br> <br> <br> <br> <br> <br>|TILT 5|245 mm|Passenger train in P|
|Tilting trains (TILT)<br> <br> <br> <br> <br> <br>|TILT 6|275 mm|Passenger train in P|
|Tilting trains (TILT)<br> <br> <br> <br> <br> <br>|TILT 7|300 mm|Passenger train in P|
|Freight trains with brake<br>position in P (FP)<br> <br> <br>|FP 1|80 mm|Freight train in P|
|Freight trains with brake<br>position in P (FP)<br> <br> <br>|FP 2|100 mm|Freight train in P|
|Freight trains with brake<br>position in P (FP)<br> <br> <br>|FP 3|130 mm|Freight train in P|
|Freight trains with brake<br>position in P (FP)<br> <br> <br>|FP 4|150 mm|Freight train in P|
|Freight trains with brake<br>position in G (FG)<br> <br> <br>|FG 1|80 mm|Freight train in G|
|Freight trains with brake<br>position in G (FG)<br> <br> <br>|FG 2|100 mm|Freight train in G|
|Freight trains with brake<br>position in G (FG)<br> <br> <br>|FG 3|130 mm|Freight train in G|
|Freight trains with brake<br>position in G (FG)<br> <br> <br>|FG 4|150 mm|Freight train in G|



**Table 41 – Keyboard for Train category**


11.3.9.9.4 The labels for the ‘Loading gauge’ input field as well as their correspondence with the

loading gauge values shall be as specified in Table 42 (see document [2], section A.3.11
for data values).

|Loading gauge label|Loading gauge value|
|---|---|
|G1|G1|
|GA|GA|
|GB|GB|
|GC|GC|
|Out of GC|The train does not fit to any of<br>the interoperable loading<br>gauge profiles|



**Table 42 – Keyboard for Loading gauge**


11.3.9.9.5 The labels for the ‘Axle load category’ input field shall correspond to the axle load category

values (see document [2], section A.3.11 for data values).


**11.3.9.10 Example of Train data for a variable train formation**


11.3.9.10.1 This kind of train data windows are typically used for freight trains or passenger trains with

a variable number of coaches.


Version 4.0.0 PAGE 194 OF 317


**ERA ERTMS unit**

**ETCS Driver Machine Interface**


11.3.9.10.2 Figure 120 and Figure 121 show the presentation of the Train data windows for a variable

train formation using the flexible train data entry with all train data modifiable by the driver
(i.e. all input fields are existing).




















|Train category PASS 1<br>Length (m) 200<br>Brake percentage 135<br>Max speed (km/h) 160<br>PASS 1 PASS 2 PASS 3|Col2|PASS 1|
|---|---|---|
|PASS 1|PASS 1|PASS 3|
|FP 2|FP 3|FP 4|
|FG 2|FG 3|FG 4|





















|Train data (1/2)<br>Train category PASS 1<br>Length (m) 200<br>Train category PASS 1<br>Brake percentage 135<br>Length (m) 200<br>Brake percentage 135<br>Max speed (km/h) 160<br>Max speed (km/h) 160<br>Axle load category A<br>1 - PASS 1<br>Airtight no 2 - PASS 2<br>Loading gauge Out of GC 3 - PASS 3<br>4 - FP 2<br>5 - FP 3<br>6 - FP 4<br>7 - FG 2<br>Train data entry complete?<br>8 - FG 3<br>9 - FG 4<br>Yes|Col2|Col3|Col4|Col5|Col6|Col7|Col8|Col9|Col10|Col11|Col12|Col13|
|---|---|---|---|---|---|---|---|---|---|---|---|---|
|Train category<br>Length (m)<br>Brake percentage<br>Max speed (km/h)<br>Axle load category<br>Airtight<br>Loading gauge<br>Train data (1/2)<br>PASS 1<br>200<br>135<br>160<br>A<br>no<br>Out of GC<br>1 - PASS 1<br>2 - PASS 2<br>3 - PASS 3<br>4 - FP 2<br>5 - FP 3<br>6 - FP 4<br>7 - FG 2<br>8 - FG 3<br>9 - FG 4<br>200<br>PASS 1<br>Train category<br>Length (m)<br>135<br>Brake percentage<br>160<br>Max speed (km/h)<br>Train data entry complete?<br>Yes|Train category<br>Length (m)<br>Brake percentage<br>Max speed (km/h)<br>Axle load category<br>Airtight<br>Loading gauge<br>Train data (1/2)<br>PASS 1<br>200<br>135<br>160<br>A<br>no<br>Out of GC<br>1 - PASS 1<br>2 - PASS 2<br>3 - PASS 3<br>4 - FP 2<br>5 - FP 3<br>6 - FP 4<br>7 - FG 2<br>8 - FG 3<br>9 - FG 4<br>200<br>PASS 1<br>Train category<br>Length (m)<br>135<br>Brake percentage<br>160<br>Max speed (km/h)<br>Train data entry complete?<br>Yes|Train category<br>Length (m)<br>Brake percentage<br>Max speed (km/h)<br>Axle load category<br>Airtight<br>Loading gauge<br>Train data (1/2)<br>PASS 1<br>200<br>135<br>160<br>A<br>no<br>Out of GC<br>1 - PASS 1<br>2 - PASS 2<br>3 - PASS 3<br>4 - FP 2<br>5 - FP 3<br>6 - FP 4<br>7 - FG 2<br>8 - FG 3<br>9 - FG 4<br>200<br>PASS 1<br>Train category<br>Length (m)<br>135<br>Brake percentage<br>160<br>Max speed (km/h)<br>Train data entry complete?<br>Yes|Train category<br>Length (m)<br>Brake percentage<br>Max speed (km/h)<br>Axle load category<br>Airtight<br>Loading gauge<br>Train data (1/2)<br>PASS 1<br>200<br>135<br>160<br>A<br>no<br>Out of GC<br>1 - PASS 1<br>2 - PASS 2<br>3 - PASS 3<br>4 - FP 2<br>5 - FP 3<br>6 - FP 4<br>7 - FG 2<br>8 - FG 3<br>9 - FG 4<br>200<br>PASS 1<br>Train category<br>Length (m)<br>135<br>Brake percentage<br>160<br>Max speed (km/h)<br>Train data entry complete?<br>Yes|Train category<br>Length (m)<br>Brake percentage<br>Max speed (km/h)<br>Axle load category<br>Airtight<br>Loading gauge<br>Train data (1/2)<br>PASS 1<br>200<br>135<br>160<br>A<br>no<br>Out of GC<br>1 - PASS 1<br>2 - PASS 2<br>3 - PASS 3<br>4 - FP 2<br>5 - FP 3<br>6 - FP 4<br>7 - FG 2<br>8 - FG 3<br>9 - FG 4<br>200<br>PASS 1<br>Train category<br>Length (m)<br>135<br>Brake percentage<br>160<br>Max speed (km/h)<br>Train data entry complete?<br>Yes|Train category<br>Length (m)<br>Brake percentage<br>Max speed (km/h)<br>Axle load category<br>Airtight<br>Loading gauge<br>Train data (1/2)<br>PASS 1<br>200<br>135<br>160<br>A<br>no<br>Out of GC<br>1 - PASS 1<br>2 - PASS 2<br>3 - PASS 3<br>4 - FP 2<br>5 - FP 3<br>6 - FP 4<br>7 - FG 2<br>8 - FG 3<br>9 - FG 4<br>200<br>PASS 1<br>Train category<br>Length (m)<br>135<br>Brake percentage<br>160<br>Max speed (km/h)<br>Train data entry complete?<br>Yes|Train category|Train category|Train category|PASS 1|PASS 1|PASS 1|PASS 1|
|Train category<br>Length (m)<br>Brake percentage<br>Max speed (km/h)<br>Axle load category<br>Airtight<br>Loading gauge<br>Train data (1/2)<br>PASS 1<br>200<br>135<br>160<br>A<br>no<br>Out of GC<br>1 - PASS 1<br>2 - PASS 2<br>3 - PASS 3<br>4 - FP 2<br>5 - FP 3<br>6 - FP 4<br>7 - FG 2<br>8 - FG 3<br>9 - FG 4<br>200<br>PASS 1<br>Train category<br>Length (m)<br>135<br>Brake percentage<br>160<br>Max speed (km/h)<br>Train data entry complete?<br>Yes|Train category<br>Length (m)<br>Brake percentage<br>Max speed (km/h)<br>Axle load category<br>Airtight<br>Loading gauge<br>Train data (1/2)<br>PASS 1<br>200<br>135<br>160<br>A<br>no<br>Out of GC<br>1 - PASS 1<br>2 - PASS 2<br>3 - PASS 3<br>4 - FP 2<br>5 - FP 3<br>6 - FP 4<br>7 - FG 2<br>8 - FG 3<br>9 - FG 4<br>200<br>PASS 1<br>Train category<br>Length (m)<br>135<br>Brake percentage<br>160<br>Max speed (km/h)<br>Train data entry complete?<br>Yes|Train category<br>Length (m)<br>Brake percentage<br>Max speed (km/h)<br>Axle load category<br>Airtight<br>Loading gauge<br>Train data (1/2)<br>PASS 1<br>200<br>135<br>160<br>A<br>no<br>Out of GC<br>1 - PASS 1<br>2 - PASS 2<br>3 - PASS 3<br>4 - FP 2<br>5 - FP 3<br>6 - FP 4<br>7 - FG 2<br>8 - FG 3<br>9 - FG 4<br>200<br>PASS 1<br>Train category<br>Length (m)<br>135<br>Brake percentage<br>160<br>Max speed (km/h)<br>Train data entry complete?<br>Yes|Train category<br>Length (m)<br>Brake percentage<br>Max speed (km/h)<br>Axle load category<br>Airtight<br>Loading gauge<br>Train data (1/2)<br>PASS 1<br>200<br>135<br>160<br>A<br>no<br>Out of GC<br>1 - PASS 1<br>2 - PASS 2<br>3 - PASS 3<br>4 - FP 2<br>5 - FP 3<br>6 - FP 4<br>7 - FG 2<br>8 - FG 3<br>9 - FG 4<br>200<br>PASS 1<br>Train category<br>Length (m)<br>135<br>Brake percentage<br>160<br>Max speed (km/h)<br>Train data entry complete?<br>Yes|Train category<br>Length (m)<br>Brake percentage<br>Max speed (km/h)<br>Axle load category<br>Airtight<br>Loading gauge<br>Train data (1/2)<br>PASS 1<br>200<br>135<br>160<br>A<br>no<br>Out of GC<br>1 - PASS 1<br>2 - PASS 2<br>3 - PASS 3<br>4 - FP 2<br>5 - FP 3<br>6 - FP 4<br>7 - FG 2<br>8 - FG 3<br>9 - FG 4<br>200<br>PASS 1<br>Train category<br>Length (m)<br>135<br>Brake percentage<br>160<br>Max speed (km/h)<br>Train data entry complete?<br>Yes|Train category<br>Length (m)<br>Brake percentage<br>Max speed (km/h)<br>Axle load category<br>Airtight<br>Loading gauge<br>Train data (1/2)<br>PASS 1<br>200<br>135<br>160<br>A<br>no<br>Out of GC<br>1 - PASS 1<br>2 - PASS 2<br>3 - PASS 3<br>4 - FP 2<br>5 - FP 3<br>6 - FP 4<br>7 - FG 2<br>8 - FG 3<br>9 - FG 4<br>200<br>PASS 1<br>Train category<br>Length (m)<br>135<br>Brake percentage<br>160<br>Max speed (km/h)<br>Train data entry complete?<br>Yes|Train category|Train category|Train category|PASS 1|PASS 1|PASS 1||
|Train category<br>Length (m)<br>Brake percentage<br>Max speed (km/h)<br>Axle load category<br>Airtight<br>Loading gauge<br>Train data (1/2)<br>PASS 1<br>200<br>135<br>160<br>A<br>no<br>Out of GC<br>1 - PASS 1<br>2 - PASS 2<br>3 - PASS 3<br>4 - FP 2<br>5 - FP 3<br>6 - FP 4<br>7 - FG 2<br>8 - FG 3<br>9 - FG 4<br>200<br>PASS 1<br>Train category<br>Length (m)<br>135<br>Brake percentage<br>160<br>Max speed (km/h)<br>Train data entry complete?<br>Yes|Train category<br>Length (m)<br>Brake percentage<br>Max speed (km/h)<br>Axle load category<br>Airtight<br>Loading gauge<br>Train data (1/2)<br>PASS 1<br>200<br>135<br>160<br>A<br>no<br>Out of GC<br>1 - PASS 1<br>2 - PASS 2<br>3 - PASS 3<br>4 - FP 2<br>5 - FP 3<br>6 - FP 4<br>7 - FG 2<br>8 - FG 3<br>9 - FG 4<br>200<br>PASS 1<br>Train category<br>Length (m)<br>135<br>Brake percentage<br>160<br>Max speed (km/h)<br>Train data entry complete?<br>Yes|Train category<br>Length (m)<br>Brake percentage<br>Max speed (km/h)<br>Axle load category<br>Airtight<br>Loading gauge<br>Train data (1/2)<br>PASS 1<br>200<br>135<br>160<br>A<br>no<br>Out of GC<br>1 - PASS 1<br>2 - PASS 2<br>3 - PASS 3<br>4 - FP 2<br>5 - FP 3<br>6 - FP 4<br>7 - FG 2<br>8 - FG 3<br>9 - FG 4<br>200<br>PASS 1<br>Train category<br>Length (m)<br>135<br>Brake percentage<br>160<br>Max speed (km/h)<br>Train data entry complete?<br>Yes|Train category<br>Length (m)<br>Brake percentage<br>Max speed (km/h)<br>Axle load category<br>Airtight<br>Loading gauge<br>Train data (1/2)<br>PASS 1<br>200<br>135<br>160<br>A<br>no<br>Out of GC<br>1 - PASS 1<br>2 - PASS 2<br>3 - PASS 3<br>4 - FP 2<br>5 - FP 3<br>6 - FP 4<br>7 - FG 2<br>8 - FG 3<br>9 - FG 4<br>200<br>PASS 1<br>Train category<br>Length (m)<br>135<br>Brake percentage<br>160<br>Max speed (km/h)<br>Train data entry complete?<br>Yes|Train category<br>Length (m)<br>Brake percentage<br>Max speed (km/h)<br>Axle load category<br>Airtight<br>Loading gauge<br>Train data (1/2)<br>PASS 1<br>200<br>135<br>160<br>A<br>no<br>Out of GC<br>1 - PASS 1<br>2 - PASS 2<br>3 - PASS 3<br>4 - FP 2<br>5 - FP 3<br>6 - FP 4<br>7 - FG 2<br>8 - FG 3<br>9 - FG 4<br>200<br>PASS 1<br>Train category<br>Length (m)<br>135<br>Brake percentage<br>160<br>Max speed (km/h)<br>Train data entry complete?<br>Yes|Train category<br>Length (m)<br>Brake percentage<br>Max speed (km/h)<br>Axle load category<br>Airtight<br>Loading gauge<br>Train data (1/2)<br>PASS 1<br>200<br>135<br>160<br>A<br>no<br>Out of GC<br>1 - PASS 1<br>2 - PASS 2<br>3 - PASS 3<br>4 - FP 2<br>5 - FP 3<br>6 - FP 4<br>7 - FG 2<br>8 - FG 3<br>9 - FG 4<br>200<br>PASS 1<br>Train category<br>Length (m)<br>135<br>Brake percentage<br>160<br>Max speed (km/h)<br>Train data entry complete?<br>Yes|200<br>Length (m)|200<br>Length (m)|200<br>Length (m)|200<br>Length (m)|200<br>Length (m)|200<br>Length (m)|200<br>Length (m)|
|Train category<br>Length (m)<br>Brake percentage<br>Max speed (km/h)<br>Axle load category<br>Airtight<br>Loading gauge<br>Train data (1/2)<br>PASS 1<br>200<br>135<br>160<br>A<br>no<br>Out of GC<br>1 - PASS 1<br>2 - PASS 2<br>3 - PASS 3<br>4 - FP 2<br>5 - FP 3<br>6 - FP 4<br>7 - FG 2<br>8 - FG 3<br>9 - FG 4<br>200<br>PASS 1<br>Train category<br>Length (m)<br>135<br>Brake percentage<br>160<br>Max speed (km/h)<br>Train data entry complete?<br>Yes|Train category<br>Length (m)<br>Brake percentage<br>Max speed (km/h)<br>Axle load category<br>Airtight<br>Loading gauge<br>Train data (1/2)<br>PASS 1<br>200<br>135<br>160<br>A<br>no<br>Out of GC<br>1 - PASS 1<br>2 - PASS 2<br>3 - PASS 3<br>4 - FP 2<br>5 - FP 3<br>6 - FP 4<br>7 - FG 2<br>8 - FG 3<br>9 - FG 4<br>200<br>PASS 1<br>Train category<br>Length (m)<br>135<br>Brake percentage<br>160<br>Max speed (km/h)<br>Train data entry complete?<br>Yes|Train category<br>Length (m)<br>Brake percentage<br>Max speed (km/h)<br>Axle load category<br>Airtight<br>Loading gauge<br>Train data (1/2)<br>PASS 1<br>200<br>135<br>160<br>A<br>no<br>Out of GC<br>1 - PASS 1<br>2 - PASS 2<br>3 - PASS 3<br>4 - FP 2<br>5 - FP 3<br>6 - FP 4<br>7 - FG 2<br>8 - FG 3<br>9 - FG 4<br>200<br>PASS 1<br>Train category<br>Length (m)<br>135<br>Brake percentage<br>160<br>Max speed (km/h)<br>Train data entry complete?<br>Yes|Train category<br>Length (m)<br>Brake percentage<br>Max speed (km/h)<br>Axle load category<br>Airtight<br>Loading gauge<br>Train data (1/2)<br>PASS 1<br>200<br>135<br>160<br>A<br>no<br>Out of GC<br>1 - PASS 1<br>2 - PASS 2<br>3 - PASS 3<br>4 - FP 2<br>5 - FP 3<br>6 - FP 4<br>7 - FG 2<br>8 - FG 3<br>9 - FG 4<br>200<br>PASS 1<br>Train category<br>Length (m)<br>135<br>Brake percentage<br>160<br>Max speed (km/h)<br>Train data entry complete?<br>Yes|Train category<br>Length (m)<br>Brake percentage<br>Max speed (km/h)<br>Axle load category<br>Airtight<br>Loading gauge<br>Train data (1/2)<br>PASS 1<br>200<br>135<br>160<br>A<br>no<br>Out of GC<br>1 - PASS 1<br>2 - PASS 2<br>3 - PASS 3<br>4 - FP 2<br>5 - FP 3<br>6 - FP 4<br>7 - FG 2<br>8 - FG 3<br>9 - FG 4<br>200<br>PASS 1<br>Train category<br>Length (m)<br>135<br>Brake percentage<br>160<br>Max speed (km/h)<br>Train data entry complete?<br>Yes|Train category<br>Length (m)<br>Brake percentage<br>Max speed (km/h)<br>Axle load category<br>Airtight<br>Loading gauge<br>Train data (1/2)<br>PASS 1<br>200<br>135<br>160<br>A<br>no<br>Out of GC<br>1 - PASS 1<br>2 - PASS 2<br>3 - PASS 3<br>4 - FP 2<br>5 - FP 3<br>6 - FP 4<br>7 - FG 2<br>8 - FG 3<br>9 - FG 4<br>200<br>PASS 1<br>Train category<br>Length (m)<br>135<br>Brake percentage<br>160<br>Max speed (km/h)<br>Train data entry complete?<br>Yes|135<br>Brake percentage|135<br>Brake percentage|135<br>Brake percentage|135<br>Brake percentage|135<br>Brake percentage|135<br>Brake percentage||
|Train category<br>Length (m)<br>Brake percentage<br>Max speed (km/h)<br>Axle load category<br>Airtight<br>Loading gauge<br>Train data (1/2)<br>PASS 1<br>200<br>135<br>160<br>A<br>no<br>Out of GC<br>1 - PASS 1<br>2 - PASS 2<br>3 - PASS 3<br>4 - FP 2<br>5 - FP 3<br>6 - FP 4<br>7 - FG 2<br>8 - FG 3<br>9 - FG 4<br>200<br>PASS 1<br>Train category<br>Length (m)<br>135<br>Brake percentage<br>160<br>Max speed (km/h)<br>Train data entry complete?<br>Yes|Train category<br>Length (m)<br>Brake percentage<br>Max speed (km/h)<br>Axle load category<br>Airtight<br>Loading gauge<br>Train data (1/2)<br>PASS 1<br>200<br>135<br>160<br>A<br>no<br>Out of GC<br>1 - PASS 1<br>2 - PASS 2<br>3 - PASS 3<br>4 - FP 2<br>5 - FP 3<br>6 - FP 4<br>7 - FG 2<br>8 - FG 3<br>9 - FG 4<br>200<br>PASS 1<br>Train category<br>Length (m)<br>135<br>Brake percentage<br>160<br>Max speed (km/h)<br>Train data entry complete?<br>Yes|Train category<br>Length (m)<br>Brake percentage<br>Max speed (km/h)<br>Axle load category<br>Airtight<br>Loading gauge<br>Train data (1/2)<br>PASS 1<br>200<br>135<br>160<br>A<br>no<br>Out of GC<br>1 - PASS 1<br>2 - PASS 2<br>3 - PASS 3<br>4 - FP 2<br>5 - FP 3<br>6 - FP 4<br>7 - FG 2<br>8 - FG 3<br>9 - FG 4<br>200<br>PASS 1<br>Train category<br>Length (m)<br>135<br>Brake percentage<br>160<br>Max speed (km/h)<br>Train data entry complete?<br>Yes|Train category<br>Length (m)<br>Brake percentage<br>Max speed (km/h)<br>Axle load category<br>Airtight<br>Loading gauge<br>Train data (1/2)<br>PASS 1<br>200<br>135<br>160<br>A<br>no<br>Out of GC<br>1 - PASS 1<br>2 - PASS 2<br>3 - PASS 3<br>4 - FP 2<br>5 - FP 3<br>6 - FP 4<br>7 - FG 2<br>8 - FG 3<br>9 - FG 4<br>200<br>PASS 1<br>Train category<br>Length (m)<br>135<br>Brake percentage<br>160<br>Max speed (km/h)<br>Train data entry complete?<br>Yes|Train category<br>Length (m)<br>Brake percentage<br>Max speed (km/h)<br>Axle load category<br>Airtight<br>Loading gauge<br>Train data (1/2)<br>PASS 1<br>200<br>135<br>160<br>A<br>no<br>Out of GC<br>1 - PASS 1<br>2 - PASS 2<br>3 - PASS 3<br>4 - FP 2<br>5 - FP 3<br>6 - FP 4<br>7 - FG 2<br>8 - FG 3<br>9 - FG 4<br>200<br>PASS 1<br>Train category<br>Length (m)<br>135<br>Brake percentage<br>160<br>Max speed (km/h)<br>Train data entry complete?<br>Yes|Train category<br>Length (m)<br>Brake percentage<br>Max speed (km/h)<br>Axle load category<br>Airtight<br>Loading gauge<br>Train data (1/2)<br>PASS 1<br>200<br>135<br>160<br>A<br>no<br>Out of GC<br>1 - PASS 1<br>2 - PASS 2<br>3 - PASS 3<br>4 - FP 2<br>5 - FP 3<br>6 - FP 4<br>7 - FG 2<br>8 - FG 3<br>9 - FG 4<br>200<br>PASS 1<br>Train category<br>Length (m)<br>135<br>Brake percentage<br>160<br>Max speed (km/h)<br>Train data entry complete?<br>Yes|160<br>Max speed (km/h)|160<br>Max speed (km/h)|160<br>Max speed (km/h)|160<br>Max speed (km/h)|160<br>Max speed (km/h)|160<br>Max speed (km/h)||
|Train category<br>Length (m)<br>Brake percentage<br>Max speed (km/h)<br>Axle load category<br>Airtight<br>Loading gauge<br>Train data (1/2)<br>PASS 1<br>200<br>135<br>160<br>A<br>no<br>Out of GC<br>1 - PASS 1<br>2 - PASS 2<br>3 - PASS 3<br>4 - FP 2<br>5 - FP 3<br>6 - FP 4<br>7 - FG 2<br>8 - FG 3<br>9 - FG 4<br>200<br>PASS 1<br>Train category<br>Length (m)<br>135<br>Brake percentage<br>160<br>Max speed (km/h)<br>Train data entry complete?<br>Yes|Train category<br>Length (m)<br>Brake percentage<br>Max speed (km/h)<br>Axle load category<br>Airtight<br>Loading gauge<br>Train data (1/2)<br>PASS 1<br>200<br>135<br>160<br>A<br>no<br>Out of GC<br>1 - PASS 1<br>2 - PASS 2<br>3 - PASS 3<br>4 - FP 2<br>5 - FP 3<br>6 - FP 4<br>7 - FG 2<br>8 - FG 3<br>9 - FG 4<br>200<br>PASS 1<br>Train category<br>Length (m)<br>135<br>Brake percentage<br>160<br>Max speed (km/h)<br>Train data entry complete?<br>Yes|Train category<br>Length (m)<br>Brake percentage<br>Max speed (km/h)<br>Axle load category<br>Airtight<br>Loading gauge<br>Train data (1/2)<br>PASS 1<br>200<br>135<br>160<br>A<br>no<br>Out of GC<br>1 - PASS 1<br>2 - PASS 2<br>3 - PASS 3<br>4 - FP 2<br>5 - FP 3<br>6 - FP 4<br>7 - FG 2<br>8 - FG 3<br>9 - FG 4<br>200<br>PASS 1<br>Train category<br>Length (m)<br>135<br>Brake percentage<br>160<br>Max speed (km/h)<br>Train data entry complete?<br>Yes|Train category<br>Length (m)<br>Brake percentage<br>Max speed (km/h)<br>Axle load category<br>Airtight<br>Loading gauge<br>Train data (1/2)<br>PASS 1<br>200<br>135<br>160<br>A<br>no<br>Out of GC<br>1 - PASS 1<br>2 - PASS 2<br>3 - PASS 3<br>4 - FP 2<br>5 - FP 3<br>6 - FP 4<br>7 - FG 2<br>8 - FG 3<br>9 - FG 4<br>200<br>PASS 1<br>Train category<br>Length (m)<br>135<br>Brake percentage<br>160<br>Max speed (km/h)<br>Train data entry complete?<br>Yes|Train category<br>Length (m)<br>Brake percentage<br>Max speed (km/h)<br>Axle load category<br>Airtight<br>Loading gauge<br>Train data (1/2)<br>PASS 1<br>200<br>135<br>160<br>A<br>no<br>Out of GC<br>1 - PASS 1<br>2 - PASS 2<br>3 - PASS 3<br>4 - FP 2<br>5 - FP 3<br>6 - FP 4<br>7 - FG 2<br>8 - FG 3<br>9 - FG 4<br>200<br>PASS 1<br>Train category<br>Length (m)<br>135<br>Brake percentage<br>160<br>Max speed (km/h)<br>Train data entry complete?<br>Yes|Train category<br>Length (m)<br>Brake percentage<br>Max speed (km/h)<br>Axle load category<br>Airtight<br>Loading gauge<br>Train data (1/2)<br>PASS 1<br>200<br>135<br>160<br>A<br>no<br>Out of GC<br>1 - PASS 1<br>2 - PASS 2<br>3 - PASS 3<br>4 - FP 2<br>5 - FP 3<br>6 - FP 4<br>7 - FG 2<br>8 - FG 3<br>9 - FG 4<br>200<br>PASS 1<br>Train category<br>Length (m)<br>135<br>Brake percentage<br>160<br>Max speed (km/h)<br>Train data entry complete?<br>Yes|160<br>Max speed (km/h)|160<br>Max speed (km/h)|160<br>Max speed (km/h)|160<br>Max speed (km/h)|160<br>Max speed (km/h)|160<br>Max speed (km/h)||
|Train category<br>Length (m)<br>Brake percentage<br>Max speed (km/h)<br>Axle load category<br>Airtight<br>Loading gauge<br>Train data (1/2)<br>PASS 1<br>200<br>135<br>160<br>A<br>no<br>Out of GC<br>1 - PASS 1<br>2 - PASS 2<br>3 - PASS 3<br>4 - FP 2<br>5 - FP 3<br>6 - FP 4<br>7 - FG 2<br>8 - FG 3<br>9 - FG 4<br>200<br>PASS 1<br>Train category<br>Length (m)<br>135<br>Brake percentage<br>160<br>Max speed (km/h)<br>Train data entry complete?<br>Yes|Train category<br>Length (m)<br>Brake percentage<br>Max speed (km/h)<br>Axle load category<br>Airtight<br>Loading gauge<br>Train data (1/2)<br>PASS 1<br>200<br>135<br>160<br>A<br>no<br>Out of GC<br>1 - PASS 1<br>2 - PASS 2<br>3 - PASS 3<br>4 - FP 2<br>5 - FP 3<br>6 - FP 4<br>7 - FG 2<br>8 - FG 3<br>9 - FG 4<br>200<br>PASS 1<br>Train category<br>Length (m)<br>135<br>Brake percentage<br>160<br>Max speed (km/h)<br>Train data entry complete?<br>Yes|Train category<br>Length (m)<br>Brake percentage<br>Max speed (km/h)<br>Axle load category<br>Airtight<br>Loading gauge<br>Train data (1/2)<br>PASS 1<br>200<br>135<br>160<br>A<br>no<br>Out of GC<br>1 - PASS 1<br>2 - PASS 2<br>3 - PASS 3<br>4 - FP 2<br>5 - FP 3<br>6 - FP 4<br>7 - FG 2<br>8 - FG 3<br>9 - FG 4<br>200<br>PASS 1<br>Train category<br>Length (m)<br>135<br>Brake percentage<br>160<br>Max speed (km/h)<br>Train data entry complete?<br>Yes|Train category<br>Length (m)<br>Brake percentage<br>Max speed (km/h)<br>Axle load category<br>Airtight<br>Loading gauge<br>Train data (1/2)<br>PASS 1<br>200<br>135<br>160<br>A<br>no<br>Out of GC<br>1 - PASS 1<br>2 - PASS 2<br>3 - PASS 3<br>4 - FP 2<br>5 - FP 3<br>6 - FP 4<br>7 - FG 2<br>8 - FG 3<br>9 - FG 4<br>200<br>PASS 1<br>Train category<br>Length (m)<br>135<br>Brake percentage<br>160<br>Max speed (km/h)<br>Train data entry complete?<br>Yes|Train category<br>Length (m)<br>Brake percentage<br>Max speed (km/h)<br>Axle load category<br>Airtight<br>Loading gauge<br>Train data (1/2)<br>PASS 1<br>200<br>135<br>160<br>A<br>no<br>Out of GC<br>1 - PASS 1<br>2 - PASS 2<br>3 - PASS 3<br>4 - FP 2<br>5 - FP 3<br>6 - FP 4<br>7 - FG 2<br>8 - FG 3<br>9 - FG 4<br>200<br>PASS 1<br>Train category<br>Length (m)<br>135<br>Brake percentage<br>160<br>Max speed (km/h)<br>Train data entry complete?<br>Yes|Train category<br>Length (m)<br>Brake percentage<br>Max speed (km/h)<br>Axle load category<br>Airtight<br>Loading gauge<br>Train data (1/2)<br>PASS 1<br>200<br>135<br>160<br>A<br>no<br>Out of GC<br>1 - PASS 1<br>2 - PASS 2<br>3 - PASS 3<br>4 - FP 2<br>5 - FP 3<br>6 - FP 4<br>7 - FG 2<br>8 - FG 3<br>9 - FG 4<br>200<br>PASS 1<br>Train category<br>Length (m)<br>135<br>Brake percentage<br>160<br>Max speed (km/h)<br>Train data entry complete?<br>Yes|160<br>Max speed (km/h)|160<br>Max speed (km/h)|160<br>Max speed (km/h)|160<br>Max speed (km/h)|160<br>Max speed (km/h)|160<br>Max speed (km/h)||
|Train category<br>Length (m)<br>Brake percentage<br>Max speed (km/h)<br>Axle load category<br>Airtight<br>Loading gauge<br>Train data (1/2)<br>PASS 1<br>200<br>135<br>160<br>A<br>no<br>Out of GC<br>1 - PASS 1<br>2 - PASS 2<br>3 - PASS 3<br>4 - FP 2<br>5 - FP 3<br>6 - FP 4<br>7 - FG 2<br>8 - FG 3<br>9 - FG 4<br>200<br>PASS 1<br>Train category<br>Length (m)<br>135<br>Brake percentage<br>160<br>Max speed (km/h)<br>Train data entry complete?<br>Yes|Train category<br>Length (m)<br>Brake percentage<br>Max speed (km/h)<br>Axle load category<br>Airtight<br>Loading gauge<br>Train data (1/2)<br>PASS 1<br>200<br>135<br>160<br>A<br>no<br>Out of GC<br>1 - PASS 1<br>2 - PASS 2<br>3 - PASS 3<br>4 - FP 2<br>5 - FP 3<br>6 - FP 4<br>7 - FG 2<br>8 - FG 3<br>9 - FG 4<br>200<br>PASS 1<br>Train category<br>Length (m)<br>135<br>Brake percentage<br>160<br>Max speed (km/h)<br>Train data entry complete?<br>Yes|Train category<br>Length (m)<br>Brake percentage<br>Max speed (km/h)<br>Axle load category<br>Airtight<br>Loading gauge<br>Train data (1/2)<br>PASS 1<br>200<br>135<br>160<br>A<br>no<br>Out of GC<br>1 - PASS 1<br>2 - PASS 2<br>3 - PASS 3<br>4 - FP 2<br>5 - FP 3<br>6 - FP 4<br>7 - FG 2<br>8 - FG 3<br>9 - FG 4<br>200<br>PASS 1<br>Train category<br>Length (m)<br>135<br>Brake percentage<br>160<br>Max speed (km/h)<br>Train data entry complete?<br>Yes|Train category<br>Length (m)<br>Brake percentage<br>Max speed (km/h)<br>Axle load category<br>Airtight<br>Loading gauge<br>Train data (1/2)<br>PASS 1<br>200<br>135<br>160<br>A<br>no<br>Out of GC<br>1 - PASS 1<br>2 - PASS 2<br>3 - PASS 3<br>4 - FP 2<br>5 - FP 3<br>6 - FP 4<br>7 - FG 2<br>8 - FG 3<br>9 - FG 4<br>200<br>PASS 1<br>Train category<br>Length (m)<br>135<br>Brake percentage<br>160<br>Max speed (km/h)<br>Train data entry complete?<br>Yes|Train category<br>Length (m)<br>Brake percentage<br>Max speed (km/h)<br>Axle load category<br>Airtight<br>Loading gauge<br>Train data (1/2)<br>PASS 1<br>200<br>135<br>160<br>A<br>no<br>Out of GC<br>1 - PASS 1<br>2 - PASS 2<br>3 - PASS 3<br>4 - FP 2<br>5 - FP 3<br>6 - FP 4<br>7 - FG 2<br>8 - FG 3<br>9 - FG 4<br>200<br>PASS 1<br>Train category<br>Length (m)<br>135<br>Brake percentage<br>160<br>Max speed (km/h)<br>Train data entry complete?<br>Yes|Train category<br>Length (m)<br>Brake percentage<br>Max speed (km/h)<br>Axle load category<br>Airtight<br>Loading gauge<br>Train data (1/2)<br>PASS 1<br>200<br>135<br>160<br>A<br>no<br>Out of GC<br>1 - PASS 1<br>2 - PASS 2<br>3 - PASS 3<br>4 - FP 2<br>5 - FP 3<br>6 - FP 4<br>7 - FG 2<br>8 - FG 3<br>9 - FG 4<br>200<br>PASS 1<br>Train category<br>Length (m)<br>135<br>Brake percentage<br>160<br>Max speed (km/h)<br>Train data entry complete?<br>Yes|160<br>Max speed (km/h)|160<br>Max speed (km/h)|160<br>Max speed (km/h)|160<br>Max speed (km/h)|160<br>Max speed (km/h)|160<br>Max speed (km/h)||
|Yes|Yes|Yes|Yes|Yes|Yes|Yes|Yes|Yes|Yes|Yes|Yes|Yes|
|1|2|3|4|5|6|6|7|8|8|9|||
||||||||||||||


**Figure 120 – Train data window for a variable train formation with all train data modifiable by the driver**
**(1** **[st]** **window)**


Version 4.0.0 PAGE 195 OF 317


**ERA ERTMS unit**

**ETCS Driver Machine Interface**


















|Axle load category A<br>Airtight no<br>Loading gauge Out of GC<br>Train data entry complete?<br>Yes|A|Col3|B1|Col5|B2|Col7|
|---|---|---|---|---|---|---|
|Axle load category<br>Airtight<br>Loading gauge<br>A<br>no<br>Out of GC<br>Train data entry complete?<br>Yes|C2|C2|C3|C3|C4|C4|
|Axle load category<br>Airtight<br>Loading gauge<br>A<br>no<br>Out of GC<br>Train data entry complete?<br>Yes|D2|D2|D3|D3|D4|D4|
|Axle load category<br>Airtight<br>Loading gauge<br>A<br>no<br>Out of GC<br>Train data entry complete?<br>Yes|D4XL|D4XL|E4|E4|.<br>E5|.<br>E5|
|Axle load category<br>Airtight<br>Loading gauge<br>A<br>no<br>Out of GC<br>Train data entry complete?<br>Yes|||||||


















|Train data (2/2)<br>Axle load category A<br>Del<br>Airtight no<br>Train category PASS 1<br>Loading gauge Out of GC<br>Length (m) 200<br>Brake percentage 135<br>Max speed (km/h) 160<br>Axle load category A<br>1 - A<br>Airtight no 2 - B1<br>Loading gauge Out of GC 3 - B2<br>4 - C2<br>5 - C3<br>6 - C4<br>7 - D2<br>Train data entry complete?<br>8 - D3<br>9 - D4<br>Yes|Col2|Col3|Col4|Col5|Col6|Col7|Col8|Col9|Col10|Col11|Col12|Col13|
|---|---|---|---|---|---|---|---|---|---|---|---|---|
|Train category<br>Length (m)<br>Brake percentage<br>Max speed (km/h)<br>Axle load category<br>Airtight<br>Loading gauge<br>PASS 1<br>200<br>135<br>160<br>A<br>no<br>Out of GC<br>Del<br>Train data (2/2)<br>A<br>Axle load category<br>Train data entry complete?<br>Yes<br>no<br>Airtight<br>1 - A<br>2 - B1<br>3 - B2<br>4 - C2<br>5 - C3<br>6 - C4<br>7 - D2<br>8 - D3<br>9 - D4<br>Out of GC<br>Loading gauge|Train category<br>Length (m)<br>Brake percentage<br>Max speed (km/h)<br>Axle load category<br>Airtight<br>Loading gauge<br>PASS 1<br>200<br>135<br>160<br>A<br>no<br>Out of GC<br>Del<br>Train data (2/2)<br>A<br>Axle load category<br>Train data entry complete?<br>Yes<br>no<br>Airtight<br>1 - A<br>2 - B1<br>3 - B2<br>4 - C2<br>5 - C3<br>6 - C4<br>7 - D2<br>8 - D3<br>9 - D4<br>Out of GC<br>Loading gauge|Train category<br>Length (m)<br>Brake percentage<br>Max speed (km/h)<br>Axle load category<br>Airtight<br>Loading gauge<br>PASS 1<br>200<br>135<br>160<br>A<br>no<br>Out of GC<br>Del<br>Train data (2/2)<br>A<br>Axle load category<br>Train data entry complete?<br>Yes<br>no<br>Airtight<br>1 - A<br>2 - B1<br>3 - B2<br>4 - C2<br>5 - C3<br>6 - C4<br>7 - D2<br>8 - D3<br>9 - D4<br>Out of GC<br>Loading gauge|Train category<br>Length (m)<br>Brake percentage<br>Max speed (km/h)<br>Axle load category<br>Airtight<br>Loading gauge<br>PASS 1<br>200<br>135<br>160<br>A<br>no<br>Out of GC<br>Del<br>Train data (2/2)<br>A<br>Axle load category<br>Train data entry complete?<br>Yes<br>no<br>Airtight<br>1 - A<br>2 - B1<br>3 - B2<br>4 - C2<br>5 - C3<br>6 - C4<br>7 - D2<br>8 - D3<br>9 - D4<br>Out of GC<br>Loading gauge|Train category<br>Length (m)<br>Brake percentage<br>Max speed (km/h)<br>Axle load category<br>Airtight<br>Loading gauge<br>PASS 1<br>200<br>135<br>160<br>A<br>no<br>Out of GC<br>Del<br>Train data (2/2)<br>A<br>Axle load category<br>Train data entry complete?<br>Yes<br>no<br>Airtight<br>1 - A<br>2 - B1<br>3 - B2<br>4 - C2<br>5 - C3<br>6 - C4<br>7 - D2<br>8 - D3<br>9 - D4<br>Out of GC<br>Loading gauge|Train category<br>Length (m)<br>Brake percentage<br>Max speed (km/h)<br>Axle load category<br>Airtight<br>Loading gauge<br>PASS 1<br>200<br>135<br>160<br>A<br>no<br>Out of GC<br>Del<br>Train data (2/2)<br>A<br>Axle load category<br>Train data entry complete?<br>Yes<br>no<br>Airtight<br>1 - A<br>2 - B1<br>3 - B2<br>4 - C2<br>5 - C3<br>6 - C4<br>7 - D2<br>8 - D3<br>9 - D4<br>Out of GC<br>Loading gauge|Axle load category|Axle load category|Axle load category|A|A|A|A|
|Train category<br>Length (m)<br>Brake percentage<br>Max speed (km/h)<br>Axle load category<br>Airtight<br>Loading gauge<br>PASS 1<br>200<br>135<br>160<br>A<br>no<br>Out of GC<br>Del<br>Train data (2/2)<br>A<br>Axle load category<br>Train data entry complete?<br>Yes<br>no<br>Airtight<br>1 - A<br>2 - B1<br>3 - B2<br>4 - C2<br>5 - C3<br>6 - C4<br>7 - D2<br>8 - D3<br>9 - D4<br>Out of GC<br>Loading gauge|Train category<br>Length (m)<br>Brake percentage<br>Max speed (km/h)<br>Axle load category<br>Airtight<br>Loading gauge<br>PASS 1<br>200<br>135<br>160<br>A<br>no<br>Out of GC<br>Del<br>Train data (2/2)<br>A<br>Axle load category<br>Train data entry complete?<br>Yes<br>no<br>Airtight<br>1 - A<br>2 - B1<br>3 - B2<br>4 - C2<br>5 - C3<br>6 - C4<br>7 - D2<br>8 - D3<br>9 - D4<br>Out of GC<br>Loading gauge|Train category<br>Length (m)<br>Brake percentage<br>Max speed (km/h)<br>Axle load category<br>Airtight<br>Loading gauge<br>PASS 1<br>200<br>135<br>160<br>A<br>no<br>Out of GC<br>Del<br>Train data (2/2)<br>A<br>Axle load category<br>Train data entry complete?<br>Yes<br>no<br>Airtight<br>1 - A<br>2 - B1<br>3 - B2<br>4 - C2<br>5 - C3<br>6 - C4<br>7 - D2<br>8 - D3<br>9 - D4<br>Out of GC<br>Loading gauge|Train category<br>Length (m)<br>Brake percentage<br>Max speed (km/h)<br>Axle load category<br>Airtight<br>Loading gauge<br>PASS 1<br>200<br>135<br>160<br>A<br>no<br>Out of GC<br>Del<br>Train data (2/2)<br>A<br>Axle load category<br>Train data entry complete?<br>Yes<br>no<br>Airtight<br>1 - A<br>2 - B1<br>3 - B2<br>4 - C2<br>5 - C3<br>6 - C4<br>7 - D2<br>8 - D3<br>9 - D4<br>Out of GC<br>Loading gauge|Train category<br>Length (m)<br>Brake percentage<br>Max speed (km/h)<br>Axle load category<br>Airtight<br>Loading gauge<br>PASS 1<br>200<br>135<br>160<br>A<br>no<br>Out of GC<br>Del<br>Train data (2/2)<br>A<br>Axle load category<br>Train data entry complete?<br>Yes<br>no<br>Airtight<br>1 - A<br>2 - B1<br>3 - B2<br>4 - C2<br>5 - C3<br>6 - C4<br>7 - D2<br>8 - D3<br>9 - D4<br>Out of GC<br>Loading gauge|Train category<br>Length (m)<br>Brake percentage<br>Max speed (km/h)<br>Axle load category<br>Airtight<br>Loading gauge<br>PASS 1<br>200<br>135<br>160<br>A<br>no<br>Out of GC<br>Del<br>Train data (2/2)<br>A<br>Axle load category<br>Train data entry complete?<br>Yes<br>no<br>Airtight<br>1 - A<br>2 - B1<br>3 - B2<br>4 - C2<br>5 - C3<br>6 - C4<br>7 - D2<br>8 - D3<br>9 - D4<br>Out of GC<br>Loading gauge|Axle load category|Axle load category|Axle load category|A|A|A|Del|
|Train category<br>Length (m)<br>Brake percentage<br>Max speed (km/h)<br>Axle load category<br>Airtight<br>Loading gauge<br>PASS 1<br>200<br>135<br>160<br>A<br>no<br>Out of GC<br>Del<br>Train data (2/2)<br>A<br>Axle load category<br>Train data entry complete?<br>Yes<br>no<br>Airtight<br>1 - A<br>2 - B1<br>3 - B2<br>4 - C2<br>5 - C3<br>6 - C4<br>7 - D2<br>8 - D3<br>9 - D4<br>Out of GC<br>Loading gauge|Train category<br>Length (m)<br>Brake percentage<br>Max speed (km/h)<br>Axle load category<br>Airtight<br>Loading gauge<br>PASS 1<br>200<br>135<br>160<br>A<br>no<br>Out of GC<br>Del<br>Train data (2/2)<br>A<br>Axle load category<br>Train data entry complete?<br>Yes<br>no<br>Airtight<br>1 - A<br>2 - B1<br>3 - B2<br>4 - C2<br>5 - C3<br>6 - C4<br>7 - D2<br>8 - D3<br>9 - D4<br>Out of GC<br>Loading gauge|Train category<br>Length (m)<br>Brake percentage<br>Max speed (km/h)<br>Axle load category<br>Airtight<br>Loading gauge<br>PASS 1<br>200<br>135<br>160<br>A<br>no<br>Out of GC<br>Del<br>Train data (2/2)<br>A<br>Axle load category<br>Train data entry complete?<br>Yes<br>no<br>Airtight<br>1 - A<br>2 - B1<br>3 - B2<br>4 - C2<br>5 - C3<br>6 - C4<br>7 - D2<br>8 - D3<br>9 - D4<br>Out of GC<br>Loading gauge|Train category<br>Length (m)<br>Brake percentage<br>Max speed (km/h)<br>Axle load category<br>Airtight<br>Loading gauge<br>PASS 1<br>200<br>135<br>160<br>A<br>no<br>Out of GC<br>Del<br>Train data (2/2)<br>A<br>Axle load category<br>Train data entry complete?<br>Yes<br>no<br>Airtight<br>1 - A<br>2 - B1<br>3 - B2<br>4 - C2<br>5 - C3<br>6 - C4<br>7 - D2<br>8 - D3<br>9 - D4<br>Out of GC<br>Loading gauge|Train category<br>Length (m)<br>Brake percentage<br>Max speed (km/h)<br>Axle load category<br>Airtight<br>Loading gauge<br>PASS 1<br>200<br>135<br>160<br>A<br>no<br>Out of GC<br>Del<br>Train data (2/2)<br>A<br>Axle load category<br>Train data entry complete?<br>Yes<br>no<br>Airtight<br>1 - A<br>2 - B1<br>3 - B2<br>4 - C2<br>5 - C3<br>6 - C4<br>7 - D2<br>8 - D3<br>9 - D4<br>Out of GC<br>Loading gauge|Train category<br>Length (m)<br>Brake percentage<br>Max speed (km/h)<br>Axle load category<br>Airtight<br>Loading gauge<br>PASS 1<br>200<br>135<br>160<br>A<br>no<br>Out of GC<br>Del<br>Train data (2/2)<br>A<br>Axle load category<br>Train data entry complete?<br>Yes<br>no<br>Airtight<br>1 - A<br>2 - B1<br>3 - B2<br>4 - C2<br>5 - C3<br>6 - C4<br>7 - D2<br>8 - D3<br>9 - D4<br>Out of GC<br>Loading gauge|no<br>Airtight|no<br>Airtight|no<br>Airtight|no<br>Airtight|no<br>Airtight|no<br>Airtight|no<br>Airtight|
|Train category<br>Length (m)<br>Brake percentage<br>Max speed (km/h)<br>Axle load category<br>Airtight<br>Loading gauge<br>PASS 1<br>200<br>135<br>160<br>A<br>no<br>Out of GC<br>Del<br>Train data (2/2)<br>A<br>Axle load category<br>Train data entry complete?<br>Yes<br>no<br>Airtight<br>1 - A<br>2 - B1<br>3 - B2<br>4 - C2<br>5 - C3<br>6 - C4<br>7 - D2<br>8 - D3<br>9 - D4<br>Out of GC<br>Loading gauge|Train category<br>Length (m)<br>Brake percentage<br>Max speed (km/h)<br>Axle load category<br>Airtight<br>Loading gauge<br>PASS 1<br>200<br>135<br>160<br>A<br>no<br>Out of GC<br>Del<br>Train data (2/2)<br>A<br>Axle load category<br>Train data entry complete?<br>Yes<br>no<br>Airtight<br>1 - A<br>2 - B1<br>3 - B2<br>4 - C2<br>5 - C3<br>6 - C4<br>7 - D2<br>8 - D3<br>9 - D4<br>Out of GC<br>Loading gauge|Train category<br>Length (m)<br>Brake percentage<br>Max speed (km/h)<br>Axle load category<br>Airtight<br>Loading gauge<br>PASS 1<br>200<br>135<br>160<br>A<br>no<br>Out of GC<br>Del<br>Train data (2/2)<br>A<br>Axle load category<br>Train data entry complete?<br>Yes<br>no<br>Airtight<br>1 - A<br>2 - B1<br>3 - B2<br>4 - C2<br>5 - C3<br>6 - C4<br>7 - D2<br>8 - D3<br>9 - D4<br>Out of GC<br>Loading gauge|Train category<br>Length (m)<br>Brake percentage<br>Max speed (km/h)<br>Axle load category<br>Airtight<br>Loading gauge<br>PASS 1<br>200<br>135<br>160<br>A<br>no<br>Out of GC<br>Del<br>Train data (2/2)<br>A<br>Axle load category<br>Train data entry complete?<br>Yes<br>no<br>Airtight<br>1 - A<br>2 - B1<br>3 - B2<br>4 - C2<br>5 - C3<br>6 - C4<br>7 - D2<br>8 - D3<br>9 - D4<br>Out of GC<br>Loading gauge|Train category<br>Length (m)<br>Brake percentage<br>Max speed (km/h)<br>Axle load category<br>Airtight<br>Loading gauge<br>PASS 1<br>200<br>135<br>160<br>A<br>no<br>Out of GC<br>Del<br>Train data (2/2)<br>A<br>Axle load category<br>Train data entry complete?<br>Yes<br>no<br>Airtight<br>1 - A<br>2 - B1<br>3 - B2<br>4 - C2<br>5 - C3<br>6 - C4<br>7 - D2<br>8 - D3<br>9 - D4<br>Out of GC<br>Loading gauge|Train category<br>Length (m)<br>Brake percentage<br>Max speed (km/h)<br>Axle load category<br>Airtight<br>Loading gauge<br>PASS 1<br>200<br>135<br>160<br>A<br>no<br>Out of GC<br>Del<br>Train data (2/2)<br>A<br>Axle load category<br>Train data entry complete?<br>Yes<br>no<br>Airtight<br>1 - A<br>2 - B1<br>3 - B2<br>4 - C2<br>5 - C3<br>6 - C4<br>7 - D2<br>8 - D3<br>9 - D4<br>Out of GC<br>Loading gauge|Out of GC<br>Loading gauge|Out of GC<br>Loading gauge|Out of GC<br>Loading gauge|Out of GC<br>Loading gauge|Out of GC<br>Loading gauge|Out of GC<br>Loading gauge||
|Train category<br>Length (m)<br>Brake percentage<br>Max speed (km/h)<br>Axle load category<br>Airtight<br>Loading gauge<br>PASS 1<br>200<br>135<br>160<br>A<br>no<br>Out of GC<br>Del<br>Train data (2/2)<br>A<br>Axle load category<br>Train data entry complete?<br>Yes<br>no<br>Airtight<br>1 - A<br>2 - B1<br>3 - B2<br>4 - C2<br>5 - C3<br>6 - C4<br>7 - D2<br>8 - D3<br>9 - D4<br>Out of GC<br>Loading gauge|Train category<br>Length (m)<br>Brake percentage<br>Max speed (km/h)<br>Axle load category<br>Airtight<br>Loading gauge<br>PASS 1<br>200<br>135<br>160<br>A<br>no<br>Out of GC<br>Del<br>Train data (2/2)<br>A<br>Axle load category<br>Train data entry complete?<br>Yes<br>no<br>Airtight<br>1 - A<br>2 - B1<br>3 - B2<br>4 - C2<br>5 - C3<br>6 - C4<br>7 - D2<br>8 - D3<br>9 - D4<br>Out of GC<br>Loading gauge|Train category<br>Length (m)<br>Brake percentage<br>Max speed (km/h)<br>Axle load category<br>Airtight<br>Loading gauge<br>PASS 1<br>200<br>135<br>160<br>A<br>no<br>Out of GC<br>Del<br>Train data (2/2)<br>A<br>Axle load category<br>Train data entry complete?<br>Yes<br>no<br>Airtight<br>1 - A<br>2 - B1<br>3 - B2<br>4 - C2<br>5 - C3<br>6 - C4<br>7 - D2<br>8 - D3<br>9 - D4<br>Out of GC<br>Loading gauge|Train category<br>Length (m)<br>Brake percentage<br>Max speed (km/h)<br>Axle load category<br>Airtight<br>Loading gauge<br>PASS 1<br>200<br>135<br>160<br>A<br>no<br>Out of GC<br>Del<br>Train data (2/2)<br>A<br>Axle load category<br>Train data entry complete?<br>Yes<br>no<br>Airtight<br>1 - A<br>2 - B1<br>3 - B2<br>4 - C2<br>5 - C3<br>6 - C4<br>7 - D2<br>8 - D3<br>9 - D4<br>Out of GC<br>Loading gauge|Train category<br>Length (m)<br>Brake percentage<br>Max speed (km/h)<br>Axle load category<br>Airtight<br>Loading gauge<br>PASS 1<br>200<br>135<br>160<br>A<br>no<br>Out of GC<br>Del<br>Train data (2/2)<br>A<br>Axle load category<br>Train data entry complete?<br>Yes<br>no<br>Airtight<br>1 - A<br>2 - B1<br>3 - B2<br>4 - C2<br>5 - C3<br>6 - C4<br>7 - D2<br>8 - D3<br>9 - D4<br>Out of GC<br>Loading gauge|Train category<br>Length (m)<br>Brake percentage<br>Max speed (km/h)<br>Axle load category<br>Airtight<br>Loading gauge<br>PASS 1<br>200<br>135<br>160<br>A<br>no<br>Out of GC<br>Del<br>Train data (2/2)<br>A<br>Axle load category<br>Train data entry complete?<br>Yes<br>no<br>Airtight<br>1 - A<br>2 - B1<br>3 - B2<br>4 - C2<br>5 - C3<br>6 - C4<br>7 - D2<br>8 - D3<br>9 - D4<br>Out of GC<br>Loading gauge|Out of GC<br>Loading gauge|Out of GC<br>Loading gauge|Out of GC<br>Loading gauge|Out of GC<br>Loading gauge|Out of GC<br>Loading gauge|Out of GC<br>Loading gauge||
|Train category<br>Length (m)<br>Brake percentage<br>Max speed (km/h)<br>Axle load category<br>Airtight<br>Loading gauge<br>PASS 1<br>200<br>135<br>160<br>A<br>no<br>Out of GC<br>Del<br>Train data (2/2)<br>A<br>Axle load category<br>Train data entry complete?<br>Yes<br>no<br>Airtight<br>1 - A<br>2 - B1<br>3 - B2<br>4 - C2<br>5 - C3<br>6 - C4<br>7 - D2<br>8 - D3<br>9 - D4<br>Out of GC<br>Loading gauge|Train category<br>Length (m)<br>Brake percentage<br>Max speed (km/h)<br>Axle load category<br>Airtight<br>Loading gauge<br>PASS 1<br>200<br>135<br>160<br>A<br>no<br>Out of GC<br>Del<br>Train data (2/2)<br>A<br>Axle load category<br>Train data entry complete?<br>Yes<br>no<br>Airtight<br>1 - A<br>2 - B1<br>3 - B2<br>4 - C2<br>5 - C3<br>6 - C4<br>7 - D2<br>8 - D3<br>9 - D4<br>Out of GC<br>Loading gauge|Train category<br>Length (m)<br>Brake percentage<br>Max speed (km/h)<br>Axle load category<br>Airtight<br>Loading gauge<br>PASS 1<br>200<br>135<br>160<br>A<br>no<br>Out of GC<br>Del<br>Train data (2/2)<br>A<br>Axle load category<br>Train data entry complete?<br>Yes<br>no<br>Airtight<br>1 - A<br>2 - B1<br>3 - B2<br>4 - C2<br>5 - C3<br>6 - C4<br>7 - D2<br>8 - D3<br>9 - D4<br>Out of GC<br>Loading gauge|Train category<br>Length (m)<br>Brake percentage<br>Max speed (km/h)<br>Axle load category<br>Airtight<br>Loading gauge<br>PASS 1<br>200<br>135<br>160<br>A<br>no<br>Out of GC<br>Del<br>Train data (2/2)<br>A<br>Axle load category<br>Train data entry complete?<br>Yes<br>no<br>Airtight<br>1 - A<br>2 - B1<br>3 - B2<br>4 - C2<br>5 - C3<br>6 - C4<br>7 - D2<br>8 - D3<br>9 - D4<br>Out of GC<br>Loading gauge|Train category<br>Length (m)<br>Brake percentage<br>Max speed (km/h)<br>Axle load category<br>Airtight<br>Loading gauge<br>PASS 1<br>200<br>135<br>160<br>A<br>no<br>Out of GC<br>Del<br>Train data (2/2)<br>A<br>Axle load category<br>Train data entry complete?<br>Yes<br>no<br>Airtight<br>1 - A<br>2 - B1<br>3 - B2<br>4 - C2<br>5 - C3<br>6 - C4<br>7 - D2<br>8 - D3<br>9 - D4<br>Out of GC<br>Loading gauge|Train category<br>Length (m)<br>Brake percentage<br>Max speed (km/h)<br>Axle load category<br>Airtight<br>Loading gauge<br>PASS 1<br>200<br>135<br>160<br>A<br>no<br>Out of GC<br>Del<br>Train data (2/2)<br>A<br>Axle load category<br>Train data entry complete?<br>Yes<br>no<br>Airtight<br>1 - A<br>2 - B1<br>3 - B2<br>4 - C2<br>5 - C3<br>6 - C4<br>7 - D2<br>8 - D3<br>9 - D4<br>Out of GC<br>Loading gauge|Out of GC<br>Loading gauge|Out of GC<br>Loading gauge|Out of GC<br>Loading gauge|Out of GC<br>Loading gauge|Out of GC<br>Loading gauge|Out of GC<br>Loading gauge||
|Train category<br>Length (m)<br>Brake percentage<br>Max speed (km/h)<br>Axle load category<br>Airtight<br>Loading gauge<br>PASS 1<br>200<br>135<br>160<br>A<br>no<br>Out of GC<br>Del<br>Train data (2/2)<br>A<br>Axle load category<br>Train data entry complete?<br>Yes<br>no<br>Airtight<br>1 - A<br>2 - B1<br>3 - B2<br>4 - C2<br>5 - C3<br>6 - C4<br>7 - D2<br>8 - D3<br>9 - D4<br>Out of GC<br>Loading gauge|Train category<br>Length (m)<br>Brake percentage<br>Max speed (km/h)<br>Axle load category<br>Airtight<br>Loading gauge<br>PASS 1<br>200<br>135<br>160<br>A<br>no<br>Out of GC<br>Del<br>Train data (2/2)<br>A<br>Axle load category<br>Train data entry complete?<br>Yes<br>no<br>Airtight<br>1 - A<br>2 - B1<br>3 - B2<br>4 - C2<br>5 - C3<br>6 - C4<br>7 - D2<br>8 - D3<br>9 - D4<br>Out of GC<br>Loading gauge|Train category<br>Length (m)<br>Brake percentage<br>Max speed (km/h)<br>Axle load category<br>Airtight<br>Loading gauge<br>PASS 1<br>200<br>135<br>160<br>A<br>no<br>Out of GC<br>Del<br>Train data (2/2)<br>A<br>Axle load category<br>Train data entry complete?<br>Yes<br>no<br>Airtight<br>1 - A<br>2 - B1<br>3 - B2<br>4 - C2<br>5 - C3<br>6 - C4<br>7 - D2<br>8 - D3<br>9 - D4<br>Out of GC<br>Loading gauge|Train category<br>Length (m)<br>Brake percentage<br>Max speed (km/h)<br>Axle load category<br>Airtight<br>Loading gauge<br>PASS 1<br>200<br>135<br>160<br>A<br>no<br>Out of GC<br>Del<br>Train data (2/2)<br>A<br>Axle load category<br>Train data entry complete?<br>Yes<br>no<br>Airtight<br>1 - A<br>2 - B1<br>3 - B2<br>4 - C2<br>5 - C3<br>6 - C4<br>7 - D2<br>8 - D3<br>9 - D4<br>Out of GC<br>Loading gauge|Train category<br>Length (m)<br>Brake percentage<br>Max speed (km/h)<br>Axle load category<br>Airtight<br>Loading gauge<br>PASS 1<br>200<br>135<br>160<br>A<br>no<br>Out of GC<br>Del<br>Train data (2/2)<br>A<br>Axle load category<br>Train data entry complete?<br>Yes<br>no<br>Airtight<br>1 - A<br>2 - B1<br>3 - B2<br>4 - C2<br>5 - C3<br>6 - C4<br>7 - D2<br>8 - D3<br>9 - D4<br>Out of GC<br>Loading gauge|Train category<br>Length (m)<br>Brake percentage<br>Max speed (km/h)<br>Axle load category<br>Airtight<br>Loading gauge<br>PASS 1<br>200<br>135<br>160<br>A<br>no<br>Out of GC<br>Del<br>Train data (2/2)<br>A<br>Axle load category<br>Train data entry complete?<br>Yes<br>no<br>Airtight<br>1 - A<br>2 - B1<br>3 - B2<br>4 - C2<br>5 - C3<br>6 - C4<br>7 - D2<br>8 - D3<br>9 - D4<br>Out of GC<br>Loading gauge|Out of GC<br>Loading gauge|Out of GC<br>Loading gauge|Out of GC<br>Loading gauge|Out of GC<br>Loading gauge|Out of GC<br>Loading gauge|Out of GC<br>Loading gauge||
|Train category<br>Length (m)<br>Brake percentage<br>Max speed (km/h)<br>Axle load category<br>Airtight<br>Loading gauge<br>PASS 1<br>200<br>135<br>160<br>A<br>no<br>Out of GC<br>Del<br>Train data (2/2)<br>A<br>Axle load category<br>Train data entry complete?<br>Yes<br>no<br>Airtight<br>1 - A<br>2 - B1<br>3 - B2<br>4 - C2<br>5 - C3<br>6 - C4<br>7 - D2<br>8 - D3<br>9 - D4<br>Out of GC<br>Loading gauge|Train category<br>Length (m)<br>Brake percentage<br>Max speed (km/h)<br>Axle load category<br>Airtight<br>Loading gauge<br>PASS 1<br>200<br>135<br>160<br>A<br>no<br>Out of GC<br>Del<br>Train data (2/2)<br>A<br>Axle load category<br>Train data entry complete?<br>Yes<br>no<br>Airtight<br>1 - A<br>2 - B1<br>3 - B2<br>4 - C2<br>5 - C3<br>6 - C4<br>7 - D2<br>8 - D3<br>9 - D4<br>Out of GC<br>Loading gauge|Train category<br>Length (m)<br>Brake percentage<br>Max speed (km/h)<br>Axle load category<br>Airtight<br>Loading gauge<br>PASS 1<br>200<br>135<br>160<br>A<br>no<br>Out of GC<br>Del<br>Train data (2/2)<br>A<br>Axle load category<br>Train data entry complete?<br>Yes<br>no<br>Airtight<br>1 - A<br>2 - B1<br>3 - B2<br>4 - C2<br>5 - C3<br>6 - C4<br>7 - D2<br>8 - D3<br>9 - D4<br>Out of GC<br>Loading gauge|Train category<br>Length (m)<br>Brake percentage<br>Max speed (km/h)<br>Axle load category<br>Airtight<br>Loading gauge<br>PASS 1<br>200<br>135<br>160<br>A<br>no<br>Out of GC<br>Del<br>Train data (2/2)<br>A<br>Axle load category<br>Train data entry complete?<br>Yes<br>no<br>Airtight<br>1 - A<br>2 - B1<br>3 - B2<br>4 - C2<br>5 - C3<br>6 - C4<br>7 - D2<br>8 - D3<br>9 - D4<br>Out of GC<br>Loading gauge|Train category<br>Length (m)<br>Brake percentage<br>Max speed (km/h)<br>Axle load category<br>Airtight<br>Loading gauge<br>PASS 1<br>200<br>135<br>160<br>A<br>no<br>Out of GC<br>Del<br>Train data (2/2)<br>A<br>Axle load category<br>Train data entry complete?<br>Yes<br>no<br>Airtight<br>1 - A<br>2 - B1<br>3 - B2<br>4 - C2<br>5 - C3<br>6 - C4<br>7 - D2<br>8 - D3<br>9 - D4<br>Out of GC<br>Loading gauge|Train category<br>Length (m)<br>Brake percentage<br>Max speed (km/h)<br>Axle load category<br>Airtight<br>Loading gauge<br>PASS 1<br>200<br>135<br>160<br>A<br>no<br>Out of GC<br>Del<br>Train data (2/2)<br>A<br>Axle load category<br>Train data entry complete?<br>Yes<br>no<br>Airtight<br>1 - A<br>2 - B1<br>3 - B2<br>4 - C2<br>5 - C3<br>6 - C4<br>7 - D2<br>8 - D3<br>9 - D4<br>Out of GC<br>Loading gauge|Out of GC<br>Loading gauge|Out of GC<br>Loading gauge|Out of GC<br>Loading gauge|Out of GC<br>Loading gauge|Out of GC<br>Loading gauge|Out of GC<br>Loading gauge||
|Yes|Yes|Yes|Yes|Yes|Yes|Yes|Yes|Yes|Yes|Yes|Yes|Yes|
|1|2|3|4|5|6|6|7|8|8|9|...|...|
||||||||||||||



**Figure 121 – Train data window for a variable train formation with all train data modifiable by the driver**
**(2** **[nd]** **window)**


11.3.9.10.3 Figure 122 shows the presentation of the Train data windows for a variable train formation

using the flexible train data entry with the train category, the airtight and the loading gauge
pre-configured onboard or received from other ERTMS/ETCS external sources and not
modifiable by the driver i.e. without the ‘Train category’, ‘Airtight’ and ‘Loading gauge’ input
fields.


Version 4.0.0 PAGE 196 OF 317


**ERA ERTMS unit**

**ETCS Driver Machine Interface**
























|Train data<br>Length (m) 200<br>Brake percentage 135<br>Max speed (km/h) 160<br>Axle load category A<br>Train data entry complete?<br>Yes|Length (m) 200<br>Brake percentage 135<br>Max speed (km/h) 160<br>Axle load category A<br>1 2 3|Col3|Col4|200|
|---|---|---|---|---|
|Train data<br>Train data entry complete?<br>Length (m)<br>Brake percentage<br>Max speed (km/h)<br>Axle load category<br>200<br>135<br>160<br>A<br>Yes|1|1|1|3|
|Train data<br>Train data entry complete?<br>Length (m)<br>Brake percentage<br>Max speed (km/h)<br>Axle load category<br>200<br>135<br>160<br>A<br>Yes|4|4|5|6|
|Train data<br>Train data entry complete?<br>Length (m)<br>Brake percentage<br>Max speed (km/h)<br>Axle load category<br>200<br>135<br>160<br>A<br>Yes|7|7|8|9|
|Train data<br>Train data entry complete?<br>Length (m)<br>Brake percentage<br>Max speed (km/h)<br>Axle load category<br>200<br>135<br>160<br>A<br>Yes|Del|Del|0|**.**|
|Train data<br>Train data entry complete?<br>Length (m)<br>Brake percentage<br>Max speed (km/h)<br>Axle load category<br>200<br>135<br>160<br>A<br>Yes|||||















|Train data<br>Length (m) 200<br>Del<br>Brake percentage 135<br>Length (m) 200<br>Max speed (km/h) 160<br>Brake percentage 135<br>Max speed (km/h) 160<br>Axle load category A<br>Axle load category A<br>Train data entry complete?<br>Yes|Col2|Col3|Col4|Col5|Col6|Col7|Col8|Col9|Col10|Col11|Col12|Col13|
|---|---|---|---|---|---|---|---|---|---|---|---|---|
|Del<br>Yes<br>Train data<br>135<br>200<br>Length (m)<br>Brake percentage<br>160<br>Max speed (km/h)<br>A<br>Axle load category<br>Train data entry complete?<br>Length (m)<br>Brake percentage<br>Max speed (km/h)<br>Axle load category<br>200<br>135<br>160<br>A|Del<br>Yes<br>Train data<br>135<br>200<br>Length (m)<br>Brake percentage<br>160<br>Max speed (km/h)<br>A<br>Axle load category<br>Train data entry complete?<br>Length (m)<br>Brake percentage<br>Max speed (km/h)<br>Axle load category<br>200<br>135<br>160<br>A|Del<br>Yes<br>Train data<br>135<br>200<br>Length (m)<br>Brake percentage<br>160<br>Max speed (km/h)<br>A<br>Axle load category<br>Train data entry complete?<br>Length (m)<br>Brake percentage<br>Max speed (km/h)<br>Axle load category<br>200<br>135<br>160<br>A|Del<br>Yes<br>Train data<br>135<br>200<br>Length (m)<br>Brake percentage<br>160<br>Max speed (km/h)<br>A<br>Axle load category<br>Train data entry complete?<br>Length (m)<br>Brake percentage<br>Max speed (km/h)<br>Axle load category<br>200<br>135<br>160<br>A|Del<br>Yes<br>Train data<br>135<br>200<br>Length (m)<br>Brake percentage<br>160<br>Max speed (km/h)<br>A<br>Axle load category<br>Train data entry complete?<br>Length (m)<br>Brake percentage<br>Max speed (km/h)<br>Axle load category<br>200<br>135<br>160<br>A|Del<br>Yes<br>Train data<br>135<br>200<br>Length (m)<br>Brake percentage<br>160<br>Max speed (km/h)<br>A<br>Axle load category<br>Train data entry complete?<br>Length (m)<br>Brake percentage<br>Max speed (km/h)<br>Axle load category<br>200<br>135<br>160<br>A|Length (m)|Length (m)|Length (m)|200|200|200|200|
|Del<br>Yes<br>Train data<br>135<br>200<br>Length (m)<br>Brake percentage<br>160<br>Max speed (km/h)<br>A<br>Axle load category<br>Train data entry complete?<br>Length (m)<br>Brake percentage<br>Max speed (km/h)<br>Axle load category<br>200<br>135<br>160<br>A|Del<br>Yes<br>Train data<br>135<br>200<br>Length (m)<br>Brake percentage<br>160<br>Max speed (km/h)<br>A<br>Axle load category<br>Train data entry complete?<br>Length (m)<br>Brake percentage<br>Max speed (km/h)<br>Axle load category<br>200<br>135<br>160<br>A|Del<br>Yes<br>Train data<br>135<br>200<br>Length (m)<br>Brake percentage<br>160<br>Max speed (km/h)<br>A<br>Axle load category<br>Train data entry complete?<br>Length (m)<br>Brake percentage<br>Max speed (km/h)<br>Axle load category<br>200<br>135<br>160<br>A|Del<br>Yes<br>Train data<br>135<br>200<br>Length (m)<br>Brake percentage<br>160<br>Max speed (km/h)<br>A<br>Axle load category<br>Train data entry complete?<br>Length (m)<br>Brake percentage<br>Max speed (km/h)<br>Axle load category<br>200<br>135<br>160<br>A|Del<br>Yes<br>Train data<br>135<br>200<br>Length (m)<br>Brake percentage<br>160<br>Max speed (km/h)<br>A<br>Axle load category<br>Train data entry complete?<br>Length (m)<br>Brake percentage<br>Max speed (km/h)<br>Axle load category<br>200<br>135<br>160<br>A|Del<br>Yes<br>Train data<br>135<br>200<br>Length (m)<br>Brake percentage<br>160<br>Max speed (km/h)<br>A<br>Axle load category<br>Train data entry complete?<br>Length (m)<br>Brake percentage<br>Max speed (km/h)<br>Axle load category<br>200<br>135<br>160<br>A|Length (m)|Length (m)|Length (m)|200|200|200|Del|
|Del<br>Yes<br>Train data<br>135<br>200<br>Length (m)<br>Brake percentage<br>160<br>Max speed (km/h)<br>A<br>Axle load category<br>Train data entry complete?<br>Length (m)<br>Brake percentage<br>Max speed (km/h)<br>Axle load category<br>200<br>135<br>160<br>A|Del<br>Yes<br>Train data<br>135<br>200<br>Length (m)<br>Brake percentage<br>160<br>Max speed (km/h)<br>A<br>Axle load category<br>Train data entry complete?<br>Length (m)<br>Brake percentage<br>Max speed (km/h)<br>Axle load category<br>200<br>135<br>160<br>A|Del<br>Yes<br>Train data<br>135<br>200<br>Length (m)<br>Brake percentage<br>160<br>Max speed (km/h)<br>A<br>Axle load category<br>Train data entry complete?<br>Length (m)<br>Brake percentage<br>Max speed (km/h)<br>Axle load category<br>200<br>135<br>160<br>A|Del<br>Yes<br>Train data<br>135<br>200<br>Length (m)<br>Brake percentage<br>160<br>Max speed (km/h)<br>A<br>Axle load category<br>Train data entry complete?<br>Length (m)<br>Brake percentage<br>Max speed (km/h)<br>Axle load category<br>200<br>135<br>160<br>A|Del<br>Yes<br>Train data<br>135<br>200<br>Length (m)<br>Brake percentage<br>160<br>Max speed (km/h)<br>A<br>Axle load category<br>Train data entry complete?<br>Length (m)<br>Brake percentage<br>Max speed (km/h)<br>Axle load category<br>200<br>135<br>160<br>A|Del<br>Yes<br>Train data<br>135<br>200<br>Length (m)<br>Brake percentage<br>160<br>Max speed (km/h)<br>A<br>Axle load category<br>Train data entry complete?<br>Length (m)<br>Brake percentage<br>Max speed (km/h)<br>Axle load category<br>200<br>135<br>160<br>A|135<br>Brake percentage|135<br>Brake percentage|135<br>Brake percentage|135<br>Brake percentage|135<br>Brake percentage|135<br>Brake percentage|135<br>Brake percentage|
|Del<br>Yes<br>Train data<br>135<br>200<br>Length (m)<br>Brake percentage<br>160<br>Max speed (km/h)<br>A<br>Axle load category<br>Train data entry complete?<br>Length (m)<br>Brake percentage<br>Max speed (km/h)<br>Axle load category<br>200<br>135<br>160<br>A|Del<br>Yes<br>Train data<br>135<br>200<br>Length (m)<br>Brake percentage<br>160<br>Max speed (km/h)<br>A<br>Axle load category<br>Train data entry complete?<br>Length (m)<br>Brake percentage<br>Max speed (km/h)<br>Axle load category<br>200<br>135<br>160<br>A|Del<br>Yes<br>Train data<br>135<br>200<br>Length (m)<br>Brake percentage<br>160<br>Max speed (km/h)<br>A<br>Axle load category<br>Train data entry complete?<br>Length (m)<br>Brake percentage<br>Max speed (km/h)<br>Axle load category<br>200<br>135<br>160<br>A|Del<br>Yes<br>Train data<br>135<br>200<br>Length (m)<br>Brake percentage<br>160<br>Max speed (km/h)<br>A<br>Axle load category<br>Train data entry complete?<br>Length (m)<br>Brake percentage<br>Max speed (km/h)<br>Axle load category<br>200<br>135<br>160<br>A|Del<br>Yes<br>Train data<br>135<br>200<br>Length (m)<br>Brake percentage<br>160<br>Max speed (km/h)<br>A<br>Axle load category<br>Train data entry complete?<br>Length (m)<br>Brake percentage<br>Max speed (km/h)<br>Axle load category<br>200<br>135<br>160<br>A|Del<br>Yes<br>Train data<br>135<br>200<br>Length (m)<br>Brake percentage<br>160<br>Max speed (km/h)<br>A<br>Axle load category<br>Train data entry complete?<br>Length (m)<br>Brake percentage<br>Max speed (km/h)<br>Axle load category<br>200<br>135<br>160<br>A|160<br>Max speed (km/h)|160<br>Max speed (km/h)|160<br>Max speed (km/h)|160<br>Max speed (km/h)|160<br>Max speed (km/h)|160<br>Max speed (km/h)||
|Del<br>Yes<br>Train data<br>135<br>200<br>Length (m)<br>Brake percentage<br>160<br>Max speed (km/h)<br>A<br>Axle load category<br>Train data entry complete?<br>Length (m)<br>Brake percentage<br>Max speed (km/h)<br>Axle load category<br>200<br>135<br>160<br>A|Del<br>Yes<br>Train data<br>135<br>200<br>Length (m)<br>Brake percentage<br>160<br>Max speed (km/h)<br>A<br>Axle load category<br>Train data entry complete?<br>Length (m)<br>Brake percentage<br>Max speed (km/h)<br>Axle load category<br>200<br>135<br>160<br>A|Del<br>Yes<br>Train data<br>135<br>200<br>Length (m)<br>Brake percentage<br>160<br>Max speed (km/h)<br>A<br>Axle load category<br>Train data entry complete?<br>Length (m)<br>Brake percentage<br>Max speed (km/h)<br>Axle load category<br>200<br>135<br>160<br>A|Del<br>Yes<br>Train data<br>135<br>200<br>Length (m)<br>Brake percentage<br>160<br>Max speed (km/h)<br>A<br>Axle load category<br>Train data entry complete?<br>Length (m)<br>Brake percentage<br>Max speed (km/h)<br>Axle load category<br>200<br>135<br>160<br>A|Del<br>Yes<br>Train data<br>135<br>200<br>Length (m)<br>Brake percentage<br>160<br>Max speed (km/h)<br>A<br>Axle load category<br>Train data entry complete?<br>Length (m)<br>Brake percentage<br>Max speed (km/h)<br>Axle load category<br>200<br>135<br>160<br>A|Del<br>Yes<br>Train data<br>135<br>200<br>Length (m)<br>Brake percentage<br>160<br>Max speed (km/h)<br>A<br>Axle load category<br>Train data entry complete?<br>Length (m)<br>Brake percentage<br>Max speed (km/h)<br>Axle load category<br>200<br>135<br>160<br>A|A<br>Axle load category|A<br>Axle load category|A<br>Axle load category|A<br>Axle load category|A<br>Axle load category|A<br>Axle load category||
|Del<br>Yes<br>Train data<br>135<br>200<br>Length (m)<br>Brake percentage<br>160<br>Max speed (km/h)<br>A<br>Axle load category<br>Train data entry complete?<br>Length (m)<br>Brake percentage<br>Max speed (km/h)<br>Axle load category<br>200<br>135<br>160<br>A|Del<br>Yes<br>Train data<br>135<br>200<br>Length (m)<br>Brake percentage<br>160<br>Max speed (km/h)<br>A<br>Axle load category<br>Train data entry complete?<br>Length (m)<br>Brake percentage<br>Max speed (km/h)<br>Axle load category<br>200<br>135<br>160<br>A|Del<br>Yes<br>Train data<br>135<br>200<br>Length (m)<br>Brake percentage<br>160<br>Max speed (km/h)<br>A<br>Axle load category<br>Train data entry complete?<br>Length (m)<br>Brake percentage<br>Max speed (km/h)<br>Axle load category<br>200<br>135<br>160<br>A|Del<br>Yes<br>Train data<br>135<br>200<br>Length (m)<br>Brake percentage<br>160<br>Max speed (km/h)<br>A<br>Axle load category<br>Train data entry complete?<br>Length (m)<br>Brake percentage<br>Max speed (km/h)<br>Axle load category<br>200<br>135<br>160<br>A|Del<br>Yes<br>Train data<br>135<br>200<br>Length (m)<br>Brake percentage<br>160<br>Max speed (km/h)<br>A<br>Axle load category<br>Train data entry complete?<br>Length (m)<br>Brake percentage<br>Max speed (km/h)<br>Axle load category<br>200<br>135<br>160<br>A|Del<br>Yes<br>Train data<br>135<br>200<br>Length (m)<br>Brake percentage<br>160<br>Max speed (km/h)<br>A<br>Axle load category<br>Train data entry complete?<br>Length (m)<br>Brake percentage<br>Max speed (km/h)<br>Axle load category<br>200<br>135<br>160<br>A|A<br>Axle load category|A<br>Axle load category|A<br>Axle load category|A<br>Axle load category|A<br>Axle load category|A<br>Axle load category||
|Del<br>Yes<br>Train data<br>135<br>200<br>Length (m)<br>Brake percentage<br>160<br>Max speed (km/h)<br>A<br>Axle load category<br>Train data entry complete?<br>Length (m)<br>Brake percentage<br>Max speed (km/h)<br>Axle load category<br>200<br>135<br>160<br>A|Del<br>Yes<br>Train data<br>135<br>200<br>Length (m)<br>Brake percentage<br>160<br>Max speed (km/h)<br>A<br>Axle load category<br>Train data entry complete?<br>Length (m)<br>Brake percentage<br>Max speed (km/h)<br>Axle load category<br>200<br>135<br>160<br>A|Del<br>Yes<br>Train data<br>135<br>200<br>Length (m)<br>Brake percentage<br>160<br>Max speed (km/h)<br>A<br>Axle load category<br>Train data entry complete?<br>Length (m)<br>Brake percentage<br>Max speed (km/h)<br>Axle load category<br>200<br>135<br>160<br>A|Del<br>Yes<br>Train data<br>135<br>200<br>Length (m)<br>Brake percentage<br>160<br>Max speed (km/h)<br>A<br>Axle load category<br>Train data entry complete?<br>Length (m)<br>Brake percentage<br>Max speed (km/h)<br>Axle load category<br>200<br>135<br>160<br>A|Del<br>Yes<br>Train data<br>135<br>200<br>Length (m)<br>Brake percentage<br>160<br>Max speed (km/h)<br>A<br>Axle load category<br>Train data entry complete?<br>Length (m)<br>Brake percentage<br>Max speed (km/h)<br>Axle load category<br>200<br>135<br>160<br>A|Del<br>Yes<br>Train data<br>135<br>200<br>Length (m)<br>Brake percentage<br>160<br>Max speed (km/h)<br>A<br>Axle load category<br>Train data entry complete?<br>Length (m)<br>Brake percentage<br>Max speed (km/h)<br>Axle load category<br>200<br>135<br>160<br>A|A<br>Axle load category|A<br>Axle load category|A<br>Axle load category|A<br>Axle load category|A<br>Axle load category|A<br>Axle load category||
|Del<br>Yes<br>Train data<br>135<br>200<br>Length (m)<br>Brake percentage<br>160<br>Max speed (km/h)<br>A<br>Axle load category<br>Train data entry complete?<br>Length (m)<br>Brake percentage<br>Max speed (km/h)<br>Axle load category<br>200<br>135<br>160<br>A|Del<br>Yes<br>Train data<br>135<br>200<br>Length (m)<br>Brake percentage<br>160<br>Max speed (km/h)<br>A<br>Axle load category<br>Train data entry complete?<br>Length (m)<br>Brake percentage<br>Max speed (km/h)<br>Axle load category<br>200<br>135<br>160<br>A|Del<br>Yes<br>Train data<br>135<br>200<br>Length (m)<br>Brake percentage<br>160<br>Max speed (km/h)<br>A<br>Axle load category<br>Train data entry complete?<br>Length (m)<br>Brake percentage<br>Max speed (km/h)<br>Axle load category<br>200<br>135<br>160<br>A|Del<br>Yes<br>Train data<br>135<br>200<br>Length (m)<br>Brake percentage<br>160<br>Max speed (km/h)<br>A<br>Axle load category<br>Train data entry complete?<br>Length (m)<br>Brake percentage<br>Max speed (km/h)<br>Axle load category<br>200<br>135<br>160<br>A|Del<br>Yes<br>Train data<br>135<br>200<br>Length (m)<br>Brake percentage<br>160<br>Max speed (km/h)<br>A<br>Axle load category<br>Train data entry complete?<br>Length (m)<br>Brake percentage<br>Max speed (km/h)<br>Axle load category<br>200<br>135<br>160<br>A|Del<br>Yes<br>Train data<br>135<br>200<br>Length (m)<br>Brake percentage<br>160<br>Max speed (km/h)<br>A<br>Axle load category<br>Train data entry complete?<br>Length (m)<br>Brake percentage<br>Max speed (km/h)<br>Axle load category<br>200<br>135<br>160<br>A|A<br>Axle load category|A<br>Axle load category|A<br>Axle load category|A<br>Axle load category|A<br>Axle load category|A<br>Axle load category||
|Yes|Yes|Yes|Yes|Yes|Yes|Yes|Yes|Yes|Yes|Yes|Yes|Yes|
|1|2|3|4|5|6|6|7|8|8|9|0|0|
||||||||||||||


**Figure 122 – Train data window for a variable train formation with the train category, the airtight and**
**the loading gauge pre-configured onboard or received from other ERTMS/ETCS external sources and**
**not modifiable by the driver**


**11.3.9.11 Example of Train data for a fixed train formation**


11.3.9.11.1 This kind of train data windows are typically used for train sets (coupled or not) or push
pull trains.


11.3.9.11.2 Figure 123 shows the presentation of the Train data window for a fixed train formation

using the fixed train data entry.


Version 4.0.0 PAGE 197 OF 317


**ERA ERTMS unit**

**ETCS Driver Machine Interface**












|Train data<br>Train type type 1<br>Train type type 1<br>1 - type 1<br>2 - type 2<br>3 - type 3<br>Train data entry complete?<br>Yes|Col2|Col3|Col4|Col5|Col6|Col7|Col8|Col9|Col10|Col11|
|---|---|---|---|---|---|---|---|---|---|---|
|Yes<br>Train data<br>Train data entry complete?<br>Train type type 1<br>type 1<br>Train type<br>1 - type 1<br>2 - type 2<br>3 - type 3|Yes<br>Train data<br>Train data entry complete?<br>Train type type 1<br>type 1<br>Train type<br>1 - type 1<br>2 - type 2<br>3 - type 3|Yes<br>Train data<br>Train data entry complete?<br>Train type type 1<br>type 1<br>Train type<br>1 - type 1<br>2 - type 2<br>3 - type 3|Yes<br>Train data<br>Train data entry complete?<br>Train type type 1<br>type 1<br>Train type<br>1 - type 1<br>2 - type 2<br>3 - type 3|Yes<br>Train data<br>Train data entry complete?<br>Train type type 1<br>type 1<br>Train type<br>1 - type 1<br>2 - type 2<br>3 - type 3|Yes<br>Train data<br>Train data entry complete?<br>Train type type 1<br>type 1<br>Train type<br>1 - type 1<br>2 - type 2<br>3 - type 3|Yes<br>Train data<br>Train data entry complete?<br>Train type type 1<br>type 1<br>Train type<br>1 - type 1<br>2 - type 2<br>3 - type 3|Yes<br>Train data<br>Train data entry complete?<br>Train type type 1<br>type 1<br>Train type<br>1 - type 1<br>2 - type 2<br>3 - type 3|Yes<br>Train data<br>Train data entry complete?<br>Train type type 1<br>type 1<br>Train type<br>1 - type 1<br>2 - type 2<br>3 - type 3|Yes<br>Train data<br>Train data entry complete?<br>Train type type 1<br>type 1<br>Train type<br>1 - type 1<br>2 - type 2<br>3 - type 3||
|Yes<br>Train data<br>Train data entry complete?<br>Train type type 1<br>type 1<br>Train type<br>1 - type 1<br>2 - type 2<br>3 - type 3|Yes<br>Train data<br>Train data entry complete?<br>Train type type 1<br>type 1<br>Train type<br>1 - type 1<br>2 - type 2<br>3 - type 3|Yes<br>Train data<br>Train data entry complete?<br>Train type type 1<br>type 1<br>Train type<br>1 - type 1<br>2 - type 2<br>3 - type 3|Yes<br>Train data<br>Train data entry complete?<br>Train type type 1<br>type 1<br>Train type<br>1 - type 1<br>2 - type 2<br>3 - type 3|Yes<br>Train data<br>Train data entry complete?<br>Train type type 1<br>type 1<br>Train type<br>1 - type 1<br>2 - type 2<br>3 - type 3|Yes<br>Train data<br>Train data entry complete?<br>Train type type 1<br>type 1<br>Train type<br>1 - type 1<br>2 - type 2<br>3 - type 3|Yes<br>Train data<br>Train data entry complete?<br>Train type type 1<br>type 1<br>Train type<br>1 - type 1<br>2 - type 2<br>3 - type 3|Yes<br>Train data<br>Train data entry complete?<br>Train type type 1<br>type 1<br>Train type<br>1 - type 1<br>2 - type 2<br>3 - type 3|Yes<br>Train data<br>Train data entry complete?<br>Train type type 1<br>type 1<br>Train type<br>1 - type 1<br>2 - type 2<br>3 - type 3|Yes<br>Train data<br>Train data entry complete?<br>Train type type 1<br>type 1<br>Train type<br>1 - type 1<br>2 - type 2<br>3 - type 3||
|Yes<br>Train data<br>Train data entry complete?<br>Train type type 1<br>type 1<br>Train type<br>1 - type 1<br>2 - type 2<br>3 - type 3|Yes<br>Train data<br>Train data entry complete?<br>Train type type 1<br>type 1<br>Train type<br>1 - type 1<br>2 - type 2<br>3 - type 3|Yes<br>Train data<br>Train data entry complete?<br>Train type type 1<br>type 1<br>Train type<br>1 - type 1<br>2 - type 2<br>3 - type 3|Yes<br>Train data<br>Train data entry complete?<br>Train type type 1<br>type 1<br>Train type<br>1 - type 1<br>2 - type 2<br>3 - type 3|Yes<br>Train data<br>Train data entry complete?<br>Train type type 1<br>type 1<br>Train type<br>1 - type 1<br>2 - type 2<br>3 - type 3|Yes<br>Train data<br>Train data entry complete?<br>Train type type 1<br>type 1<br>Train type<br>1 - type 1<br>2 - type 2<br>3 - type 3|Yes<br>Train data<br>Train data entry complete?<br>Train type type 1<br>type 1<br>Train type<br>1 - type 1<br>2 - type 2<br>3 - type 3|Yes<br>Train data<br>Train data entry complete?<br>Train type type 1<br>type 1<br>Train type<br>1 - type 1<br>2 - type 2<br>3 - type 3|Yes<br>Train data<br>Train data entry complete?<br>Train type type 1<br>type 1<br>Train type<br>1 - type 1<br>2 - type 2<br>3 - type 3|Yes<br>Train data<br>Train data entry complete?<br>Train type type 1<br>type 1<br>Train type<br>1 - type 1<br>2 - type 2<br>3 - type 3||
|Yes<br>Train data<br>Train data entry complete?<br>Train type type 1<br>type 1<br>Train type<br>1 - type 1<br>2 - type 2<br>3 - type 3|Yes<br>Train data<br>Train data entry complete?<br>Train type type 1<br>type 1<br>Train type<br>1 - type 1<br>2 - type 2<br>3 - type 3|Yes<br>Train data<br>Train data entry complete?<br>Train type type 1<br>type 1<br>Train type<br>1 - type 1<br>2 - type 2<br>3 - type 3|Yes<br>Train data<br>Train data entry complete?<br>Train type type 1<br>type 1<br>Train type<br>1 - type 1<br>2 - type 2<br>3 - type 3|Yes<br>Train data<br>Train data entry complete?<br>Train type type 1<br>type 1<br>Train type<br>1 - type 1<br>2 - type 2<br>3 - type 3|Yes<br>Train data<br>Train data entry complete?<br>Train type type 1<br>type 1<br>Train type<br>1 - type 1<br>2 - type 2<br>3 - type 3|Yes<br>Train data<br>Train data entry complete?<br>Train type type 1<br>type 1<br>Train type<br>1 - type 1<br>2 - type 2<br>3 - type 3|Yes<br>Train data<br>Train data entry complete?<br>Train type type 1<br>type 1<br>Train type<br>1 - type 1<br>2 - type 2<br>3 - type 3|Yes<br>Train data<br>Train data entry complete?<br>Train type type 1<br>type 1<br>Train type<br>1 - type 1<br>2 - type 2<br>3 - type 3|Yes<br>Train data<br>Train data entry complete?<br>Train type type 1<br>type 1<br>Train type<br>1 - type 1<br>2 - type 2<br>3 - type 3||
|Yes<br>Train data<br>Train data entry complete?<br>Train type type 1<br>type 1<br>Train type<br>1 - type 1<br>2 - type 2<br>3 - type 3|Yes<br>Train data<br>Train data entry complete?<br>Train type type 1<br>type 1<br>Train type<br>1 - type 1<br>2 - type 2<br>3 - type 3|Yes<br>Train data<br>Train data entry complete?<br>Train type type 1<br>type 1<br>Train type<br>1 - type 1<br>2 - type 2<br>3 - type 3|Yes<br>Train data<br>Train data entry complete?<br>Train type type 1<br>type 1<br>Train type<br>1 - type 1<br>2 - type 2<br>3 - type 3|Yes<br>Train data<br>Train data entry complete?<br>Train type type 1<br>type 1<br>Train type<br>1 - type 1<br>2 - type 2<br>3 - type 3|Yes<br>Train data<br>Train data entry complete?<br>Train type type 1<br>type 1<br>Train type<br>1 - type 1<br>2 - type 2<br>3 - type 3|Yes<br>Train data<br>Train data entry complete?<br>Train type type 1<br>type 1<br>Train type<br>1 - type 1<br>2 - type 2<br>3 - type 3|Yes<br>Train data<br>Train data entry complete?<br>Train type type 1<br>type 1<br>Train type<br>1 - type 1<br>2 - type 2<br>3 - type 3|Yes<br>Train data<br>Train data entry complete?<br>Train type type 1<br>type 1<br>Train type<br>1 - type 1<br>2 - type 2<br>3 - type 3|Yes<br>Train data<br>Train data entry complete?<br>Train type type 1<br>type 1<br>Train type<br>1 - type 1<br>2 - type 2<br>3 - type 3||
|Yes<br>Train data<br>Train data entry complete?<br>Train type type 1<br>type 1<br>Train type<br>1 - type 1<br>2 - type 2<br>3 - type 3|Yes<br>Train data<br>Train data entry complete?<br>Train type type 1<br>type 1<br>Train type<br>1 - type 1<br>2 - type 2<br>3 - type 3|Yes<br>Train data<br>Train data entry complete?<br>Train type type 1<br>type 1<br>Train type<br>1 - type 1<br>2 - type 2<br>3 - type 3|Yes<br>Train data<br>Train data entry complete?<br>Train type type 1<br>type 1<br>Train type<br>1 - type 1<br>2 - type 2<br>3 - type 3|Yes<br>Train data<br>Train data entry complete?<br>Train type type 1<br>type 1<br>Train type<br>1 - type 1<br>2 - type 2<br>3 - type 3|Yes<br>Train data<br>Train data entry complete?<br>Train type type 1<br>type 1<br>Train type<br>1 - type 1<br>2 - type 2<br>3 - type 3|Yes<br>Train data<br>Train data entry complete?<br>Train type type 1<br>type 1<br>Train type<br>1 - type 1<br>2 - type 2<br>3 - type 3|Yes<br>Train data<br>Train data entry complete?<br>Train type type 1<br>type 1<br>Train type<br>1 - type 1<br>2 - type 2<br>3 - type 3|Yes<br>Train data<br>Train data entry complete?<br>Train type type 1<br>type 1<br>Train type<br>1 - type 1<br>2 - type 2<br>3 - type 3|Yes<br>Train data<br>Train data entry complete?<br>Train type type 1<br>type 1<br>Train type<br>1 - type 1<br>2 - type 2<br>3 - type 3||
|Yes|Yes|Yes|Yes|Yes|Yes|Yes|Yes|Yes|Yes|Yes|
|1|2|3|||||||||
||||||||||||



**Figure 123 – Train data window for a fixed train formation**


**11.3.9.12 Example of Train data window allowing to switch from fixed to flexible train data**

**entry or vice versa**


11.3.9.12.1 This kind of train data window allows via the ‘switch’ button to manually adapt the train

data entry from fixed to variable train formations or vice versa.


11.3.9.12.2 Figure 124 shows the presentation of the Train data window using the switchable train

data entry with a fixed train data entry layout.


Version 4.0.0 PAGE 198 OF 317


**ERA ERTMS unit**

**ETCS Driver Machine Interface**














|Train data<br>Train type type 1<br>Train type type 1<br>Train data entry complete?<br>Enter<br>Yes<br>data|Col2|Col3|Col4|Col5|Col6|Col7|Col8|Col9|Col10|Col11|
|---|---|---|---|---|---|---|---|---|---|---|
|Yes<br>Train data<br>Train data entry complete?<br>Train type type 1<br>Train type<br>type 1<br>Enter<br>data|Yes<br>Train data<br>Train data entry complete?<br>Train type type 1<br>Train type<br>type 1<br>Enter<br>data|Yes<br>Train data<br>Train data entry complete?<br>Train type type 1<br>Train type<br>type 1<br>Enter<br>data|Yes<br>Train data<br>Train data entry complete?<br>Train type type 1<br>Train type<br>type 1<br>Enter<br>data|Yes<br>Train data<br>Train data entry complete?<br>Train type type 1<br>Train type<br>type 1<br>Enter<br>data|Yes<br>Train data<br>Train data entry complete?<br>Train type type 1<br>Train type<br>type 1<br>Enter<br>data|Yes<br>Train data<br>Train data entry complete?<br>Train type type 1<br>Train type<br>type 1<br>Enter<br>data|Yes<br>Train data<br>Train data entry complete?<br>Train type type 1<br>Train type<br>type 1<br>Enter<br>data|Yes<br>Train data<br>Train data entry complete?<br>Train type type 1<br>Train type<br>type 1<br>Enter<br>data|Yes<br>Train data<br>Train data entry complete?<br>Train type type 1<br>Train type<br>type 1<br>Enter<br>data||
|Yes<br>Train data<br>Train data entry complete?<br>Train type type 1<br>Train type<br>type 1<br>Enter<br>data|Yes<br>Train data<br>Train data entry complete?<br>Train type type 1<br>Train type<br>type 1<br>Enter<br>data|Yes<br>Train data<br>Train data entry complete?<br>Train type type 1<br>Train type<br>type 1<br>Enter<br>data|Yes<br>Train data<br>Train data entry complete?<br>Train type type 1<br>Train type<br>type 1<br>Enter<br>data|Yes<br>Train data<br>Train data entry complete?<br>Train type type 1<br>Train type<br>type 1<br>Enter<br>data|Yes<br>Train data<br>Train data entry complete?<br>Train type type 1<br>Train type<br>type 1<br>Enter<br>data|Yes<br>Train data<br>Train data entry complete?<br>Train type type 1<br>Train type<br>type 1<br>Enter<br>data|Yes<br>Train data<br>Train data entry complete?<br>Train type type 1<br>Train type<br>type 1<br>Enter<br>data|Yes<br>Train data<br>Train data entry complete?<br>Train type type 1<br>Train type<br>type 1<br>Enter<br>data|Yes<br>Train data<br>Train data entry complete?<br>Train type type 1<br>Train type<br>type 1<br>Enter<br>data||
|Yes<br>Train data<br>Train data entry complete?<br>Train type type 1<br>Train type<br>type 1<br>Enter<br>data|Yes<br>Train data<br>Train data entry complete?<br>Train type type 1<br>Train type<br>type 1<br>Enter<br>data|Yes<br>Train data<br>Train data entry complete?<br>Train type type 1<br>Train type<br>type 1<br>Enter<br>data|Yes<br>Train data<br>Train data entry complete?<br>Train type type 1<br>Train type<br>type 1<br>Enter<br>data|Yes<br>Train data<br>Train data entry complete?<br>Train type type 1<br>Train type<br>type 1<br>Enter<br>data|Yes<br>Train data<br>Train data entry complete?<br>Train type type 1<br>Train type<br>type 1<br>Enter<br>data|Yes<br>Train data<br>Train data entry complete?<br>Train type type 1<br>Train type<br>type 1<br>Enter<br>data|Yes<br>Train data<br>Train data entry complete?<br>Train type type 1<br>Train type<br>type 1<br>Enter<br>data|Yes<br>Train data<br>Train data entry complete?<br>Train type type 1<br>Train type<br>type 1<br>Enter<br>data|Yes<br>Train data<br>Train data entry complete?<br>Train type type 1<br>Train type<br>type 1<br>Enter<br>data||
|Yes<br>Train data<br>Train data entry complete?<br>Train type type 1<br>Train type<br>type 1<br>Enter<br>data|Yes<br>Train data<br>Train data entry complete?<br>Train type type 1<br>Train type<br>type 1<br>Enter<br>data|Yes<br>Train data<br>Train data entry complete?<br>Train type type 1<br>Train type<br>type 1<br>Enter<br>data|Yes<br>Train data<br>Train data entry complete?<br>Train type type 1<br>Train type<br>type 1<br>Enter<br>data|Yes<br>Train data<br>Train data entry complete?<br>Train type type 1<br>Train type<br>type 1<br>Enter<br>data|Yes<br>Train data<br>Train data entry complete?<br>Train type type 1<br>Train type<br>type 1<br>Enter<br>data|Yes<br>Train data<br>Train data entry complete?<br>Train type type 1<br>Train type<br>type 1<br>Enter<br>data|Yes<br>Train data<br>Train data entry complete?<br>Train type type 1<br>Train type<br>type 1<br>Enter<br>data|Yes<br>Train data<br>Train data entry complete?<br>Train type type 1<br>Train type<br>type 1<br>Enter<br>data|Yes<br>Train data<br>Train data entry complete?<br>Train type type 1<br>Train type<br>type 1<br>Enter<br>data||
|Yes<br>Train data<br>Train data entry complete?<br>Train type type 1<br>Train type<br>type 1<br>Enter<br>data|Yes<br>Train data<br>Train data entry complete?<br>Train type type 1<br>Train type<br>type 1<br>Enter<br>data|Yes<br>Train data<br>Train data entry complete?<br>Train type type 1<br>Train type<br>type 1<br>Enter<br>data|Yes<br>Train data<br>Train data entry complete?<br>Train type type 1<br>Train type<br>type 1<br>Enter<br>data|Yes<br>Train data<br>Train data entry complete?<br>Train type type 1<br>Train type<br>type 1<br>Enter<br>data|Yes<br>Train data<br>Train data entry complete?<br>Train type type 1<br>Train type<br>type 1<br>Enter<br>data|Yes<br>Train data<br>Train data entry complete?<br>Train type type 1<br>Train type<br>type 1<br>Enter<br>data|Yes<br>Train data<br>Train data entry complete?<br>Train type type 1<br>Train type<br>type 1<br>Enter<br>data|Yes<br>Train data<br>Train data entry complete?<br>Train type type 1<br>Train type<br>type 1<br>Enter<br>data|Yes<br>Train data<br>Train data entry complete?<br>Train type type 1<br>Train type<br>type 1<br>Enter<br>data||
|Yes<br>Train data<br>Train data entry complete?<br>Train type type 1<br>Train type<br>type 1<br>Enter<br>data|Yes<br>Train data<br>Train data entry complete?<br>Train type type 1<br>Train type<br>type 1<br>Enter<br>data|Yes<br>Train data<br>Train data entry complete?<br>Train type type 1<br>Train type<br>type 1<br>Enter<br>data|Yes<br>Train data<br>Train data entry complete?<br>Train type type 1<br>Train type<br>type 1<br>Enter<br>data|Yes<br>Train data<br>Train data entry complete?<br>Train type type 1<br>Train type<br>type 1<br>Enter<br>data|Yes<br>Train data<br>Train data entry complete?<br>Train type type 1<br>Train type<br>type 1<br>Enter<br>data|Yes<br>Train data<br>Train data entry complete?<br>Train type type 1<br>Train type<br>type 1<br>Enter<br>data|Yes<br>Train data<br>Train data entry complete?<br>Train type type 1<br>Train type<br>type 1<br>Enter<br>data|Yes<br>Train data<br>Train data entry complete?<br>Train type type 1<br>Train type<br>type 1<br>Enter<br>data|Yes<br>Train data<br>Train data entry complete?<br>Train type type 1<br>Train type<br>type 1<br>Enter<br>data||
|Yes|Yes|Yes|Yes|Yes|Yes|Yes|Yes|Enter<br>data|Enter<br>data|Enter<br>data|
|||Yes||||||Enter<br>data|||
||||||||||||



**Figure 124 – Train data window allowing to switch from fixed to variable train formations**


11.3.9.12.3 Figure 125 shows the presentation of the 1 [st] Train data window using the switchable train

data entry with a flexible train data entry layout and with all train data modifiable by the
driver (i.e. all input fields are existing).


Version 4.0.0 PAGE 199 OF 317


**ERA ERTMS unit**

**ETCS Driver Machine Interface**




















|Train category PASS 1<br>Length (m) 200<br>Brake percentage 135<br>Max speed (km/h) 160<br>PASS 1 PASS 2 PASS 3|Col2|PASS 1|
|---|---|---|
|PASS 1|PASS 1|PASS 3|
|FP 2|FP 3|FP 4|
|FG 2|FG 3|FG 4|















|Train data (1/2)<br>Train category PASS 1<br>Length (m) 200<br>Train category PASS 1<br>Brake percentage 135<br>Length (m) 200<br>Brake percentage 135<br>Max speed (km/h) 160<br>Max speed (km/h) 160<br>Axle load category A<br>Airtight no<br>Loading gauge Out of GC<br>Train data entry complete?<br>Select<br>Yes<br>type|Col2|Col3|Col4|Col5|Col6|Col7|Col8|Col9|Col10|Col11|Col12|
|---|---|---|---|---|---|---|---|---|---|---|---|
|Train category<br>Length (m)<br>Brake percentage<br>Max speed (km/h)<br>Axle load category<br>Airtight<br>Loading gauge<br>Train data (1/2)<br>PASS 1<br>200<br>135<br>160<br>A<br>no<br>Out of GC<br>Train data entry complete?<br>Select<br>type<br>Yes<br>Train category<br>Length (m)<br>200<br>Brake percentage<br>135<br>Max speed (km/h)<br>160<br>PASS 1|Train category<br>Length (m)<br>Brake percentage<br>Max speed (km/h)<br>Axle load category<br>Airtight<br>Loading gauge<br>Train data (1/2)<br>PASS 1<br>200<br>135<br>160<br>A<br>no<br>Out of GC<br>Train data entry complete?<br>Select<br>type<br>Yes<br>Train category<br>Length (m)<br>200<br>Brake percentage<br>135<br>Max speed (km/h)<br>160<br>PASS 1|Train category<br>Length (m)<br>Brake percentage<br>Max speed (km/h)<br>Axle load category<br>Airtight<br>Loading gauge<br>Train data (1/2)<br>PASS 1<br>200<br>135<br>160<br>A<br>no<br>Out of GC<br>Train data entry complete?<br>Select<br>type<br>Yes<br>Train category<br>Length (m)<br>200<br>Brake percentage<br>135<br>Max speed (km/h)<br>160<br>PASS 1|Train category<br>Length (m)<br>Brake percentage<br>Max speed (km/h)<br>Axle load category<br>Airtight<br>Loading gauge<br>Train data (1/2)<br>PASS 1<br>200<br>135<br>160<br>A<br>no<br>Out of GC<br>Train data entry complete?<br>Select<br>type<br>Yes<br>Train category<br>Length (m)<br>200<br>Brake percentage<br>135<br>Max speed (km/h)<br>160<br>PASS 1|Train category<br>Length (m)<br>Brake percentage<br>Max speed (km/h)<br>Axle load category<br>Airtight<br>Loading gauge<br>Train data (1/2)<br>PASS 1<br>200<br>135<br>160<br>A<br>no<br>Out of GC<br>Train data entry complete?<br>Select<br>type<br>Yes<br>Train category<br>Length (m)<br>200<br>Brake percentage<br>135<br>Max speed (km/h)<br>160<br>PASS 1|Train category<br>Length (m)<br>Brake percentage<br>Max speed (km/h)<br>Axle load category<br>Airtight<br>Loading gauge<br>Train data (1/2)<br>PASS 1<br>200<br>135<br>160<br>A<br>no<br>Out of GC<br>Train data entry complete?<br>Select<br>type<br>Yes<br>Train category<br>Length (m)<br>200<br>Brake percentage<br>135<br>Max speed (km/h)<br>160<br>PASS 1|Train category<br>PASS 1|Train category<br>PASS 1|Train category<br>PASS 1|Train category<br>PASS 1|Train category<br>PASS 1|Train category<br>PASS 1|
|Train category<br>Length (m)<br>Brake percentage<br>Max speed (km/h)<br>Axle load category<br>Airtight<br>Loading gauge<br>Train data (1/2)<br>PASS 1<br>200<br>135<br>160<br>A<br>no<br>Out of GC<br>Train data entry complete?<br>Select<br>type<br>Yes<br>Train category<br>Length (m)<br>200<br>Brake percentage<br>135<br>Max speed (km/h)<br>160<br>PASS 1|Train category<br>Length (m)<br>Brake percentage<br>Max speed (km/h)<br>Axle load category<br>Airtight<br>Loading gauge<br>Train data (1/2)<br>PASS 1<br>200<br>135<br>160<br>A<br>no<br>Out of GC<br>Train data entry complete?<br>Select<br>type<br>Yes<br>Train category<br>Length (m)<br>200<br>Brake percentage<br>135<br>Max speed (km/h)<br>160<br>PASS 1|Train category<br>Length (m)<br>Brake percentage<br>Max speed (km/h)<br>Axle load category<br>Airtight<br>Loading gauge<br>Train data (1/2)<br>PASS 1<br>200<br>135<br>160<br>A<br>no<br>Out of GC<br>Train data entry complete?<br>Select<br>type<br>Yes<br>Train category<br>Length (m)<br>200<br>Brake percentage<br>135<br>Max speed (km/h)<br>160<br>PASS 1|Train category<br>Length (m)<br>Brake percentage<br>Max speed (km/h)<br>Axle load category<br>Airtight<br>Loading gauge<br>Train data (1/2)<br>PASS 1<br>200<br>135<br>160<br>A<br>no<br>Out of GC<br>Train data entry complete?<br>Select<br>type<br>Yes<br>Train category<br>Length (m)<br>200<br>Brake percentage<br>135<br>Max speed (km/h)<br>160<br>PASS 1|Train category<br>Length (m)<br>Brake percentage<br>Max speed (km/h)<br>Axle load category<br>Airtight<br>Loading gauge<br>Train data (1/2)<br>PASS 1<br>200<br>135<br>160<br>A<br>no<br>Out of GC<br>Train data entry complete?<br>Select<br>type<br>Yes<br>Train category<br>Length (m)<br>200<br>Brake percentage<br>135<br>Max speed (km/h)<br>160<br>PASS 1|Train category<br>Length (m)<br>Brake percentage<br>Max speed (km/h)<br>Axle load category<br>Airtight<br>Loading gauge<br>Train data (1/2)<br>PASS 1<br>200<br>135<br>160<br>A<br>no<br>Out of GC<br>Train data entry complete?<br>Select<br>type<br>Yes<br>Train category<br>Length (m)<br>200<br>Brake percentage<br>135<br>Max speed (km/h)<br>160<br>PASS 1|Train category<br>PASS 1|Train category<br>PASS 1|Train category<br>PASS 1|Train category<br>PASS 1|Train category<br>PASS 1||
|Train category<br>Length (m)<br>Brake percentage<br>Max speed (km/h)<br>Axle load category<br>Airtight<br>Loading gauge<br>Train data (1/2)<br>PASS 1<br>200<br>135<br>160<br>A<br>no<br>Out of GC<br>Train data entry complete?<br>Select<br>type<br>Yes<br>Train category<br>Length (m)<br>200<br>Brake percentage<br>135<br>Max speed (km/h)<br>160<br>PASS 1|Train category<br>Length (m)<br>Brake percentage<br>Max speed (km/h)<br>Axle load category<br>Airtight<br>Loading gauge<br>Train data (1/2)<br>PASS 1<br>200<br>135<br>160<br>A<br>no<br>Out of GC<br>Train data entry complete?<br>Select<br>type<br>Yes<br>Train category<br>Length (m)<br>200<br>Brake percentage<br>135<br>Max speed (km/h)<br>160<br>PASS 1|Train category<br>Length (m)<br>Brake percentage<br>Max speed (km/h)<br>Axle load category<br>Airtight<br>Loading gauge<br>Train data (1/2)<br>PASS 1<br>200<br>135<br>160<br>A<br>no<br>Out of GC<br>Train data entry complete?<br>Select<br>type<br>Yes<br>Train category<br>Length (m)<br>200<br>Brake percentage<br>135<br>Max speed (km/h)<br>160<br>PASS 1|Train category<br>Length (m)<br>Brake percentage<br>Max speed (km/h)<br>Axle load category<br>Airtight<br>Loading gauge<br>Train data (1/2)<br>PASS 1<br>200<br>135<br>160<br>A<br>no<br>Out of GC<br>Train data entry complete?<br>Select<br>type<br>Yes<br>Train category<br>Length (m)<br>200<br>Brake percentage<br>135<br>Max speed (km/h)<br>160<br>PASS 1|Train category<br>Length (m)<br>Brake percentage<br>Max speed (km/h)<br>Axle load category<br>Airtight<br>Loading gauge<br>Train data (1/2)<br>PASS 1<br>200<br>135<br>160<br>A<br>no<br>Out of GC<br>Train data entry complete?<br>Select<br>type<br>Yes<br>Train category<br>Length (m)<br>200<br>Brake percentage<br>135<br>Max speed (km/h)<br>160<br>PASS 1|Train category<br>Length (m)<br>Brake percentage<br>Max speed (km/h)<br>Axle load category<br>Airtight<br>Loading gauge<br>Train data (1/2)<br>PASS 1<br>200<br>135<br>160<br>A<br>no<br>Out of GC<br>Train data entry complete?<br>Select<br>type<br>Yes<br>Train category<br>Length (m)<br>200<br>Brake percentage<br>135<br>Max speed (km/h)<br>160<br>PASS 1|Length (m)<br>200|Length (m)<br>200|Length (m)<br>200|Length (m)<br>200|Length (m)<br>200|Length (m)<br>200|
|Train category<br>Length (m)<br>Brake percentage<br>Max speed (km/h)<br>Axle load category<br>Airtight<br>Loading gauge<br>Train data (1/2)<br>PASS 1<br>200<br>135<br>160<br>A<br>no<br>Out of GC<br>Train data entry complete?<br>Select<br>type<br>Yes<br>Train category<br>Length (m)<br>200<br>Brake percentage<br>135<br>Max speed (km/h)<br>160<br>PASS 1|Train category<br>Length (m)<br>Brake percentage<br>Max speed (km/h)<br>Axle load category<br>Airtight<br>Loading gauge<br>Train data (1/2)<br>PASS 1<br>200<br>135<br>160<br>A<br>no<br>Out of GC<br>Train data entry complete?<br>Select<br>type<br>Yes<br>Train category<br>Length (m)<br>200<br>Brake percentage<br>135<br>Max speed (km/h)<br>160<br>PASS 1|Train category<br>Length (m)<br>Brake percentage<br>Max speed (km/h)<br>Axle load category<br>Airtight<br>Loading gauge<br>Train data (1/2)<br>PASS 1<br>200<br>135<br>160<br>A<br>no<br>Out of GC<br>Train data entry complete?<br>Select<br>type<br>Yes<br>Train category<br>Length (m)<br>200<br>Brake percentage<br>135<br>Max speed (km/h)<br>160<br>PASS 1|Train category<br>Length (m)<br>Brake percentage<br>Max speed (km/h)<br>Axle load category<br>Airtight<br>Loading gauge<br>Train data (1/2)<br>PASS 1<br>200<br>135<br>160<br>A<br>no<br>Out of GC<br>Train data entry complete?<br>Select<br>type<br>Yes<br>Train category<br>Length (m)<br>200<br>Brake percentage<br>135<br>Max speed (km/h)<br>160<br>PASS 1|Train category<br>Length (m)<br>Brake percentage<br>Max speed (km/h)<br>Axle load category<br>Airtight<br>Loading gauge<br>Train data (1/2)<br>PASS 1<br>200<br>135<br>160<br>A<br>no<br>Out of GC<br>Train data entry complete?<br>Select<br>type<br>Yes<br>Train category<br>Length (m)<br>200<br>Brake percentage<br>135<br>Max speed (km/h)<br>160<br>PASS 1|Train category<br>Length (m)<br>Brake percentage<br>Max speed (km/h)<br>Axle load category<br>Airtight<br>Loading gauge<br>Train data (1/2)<br>PASS 1<br>200<br>135<br>160<br>A<br>no<br>Out of GC<br>Train data entry complete?<br>Select<br>type<br>Yes<br>Train category<br>Length (m)<br>200<br>Brake percentage<br>135<br>Max speed (km/h)<br>160<br>PASS 1|Brake percentage<br>135|Brake percentage<br>135|Brake percentage<br>135|Brake percentage<br>135|Brake percentage<br>135||
|Train category<br>Length (m)<br>Brake percentage<br>Max speed (km/h)<br>Axle load category<br>Airtight<br>Loading gauge<br>Train data (1/2)<br>PASS 1<br>200<br>135<br>160<br>A<br>no<br>Out of GC<br>Train data entry complete?<br>Select<br>type<br>Yes<br>Train category<br>Length (m)<br>200<br>Brake percentage<br>135<br>Max speed (km/h)<br>160<br>PASS 1|Train category<br>Length (m)<br>Brake percentage<br>Max speed (km/h)<br>Axle load category<br>Airtight<br>Loading gauge<br>Train data (1/2)<br>PASS 1<br>200<br>135<br>160<br>A<br>no<br>Out of GC<br>Train data entry complete?<br>Select<br>type<br>Yes<br>Train category<br>Length (m)<br>200<br>Brake percentage<br>135<br>Max speed (km/h)<br>160<br>PASS 1|Train category<br>Length (m)<br>Brake percentage<br>Max speed (km/h)<br>Axle load category<br>Airtight<br>Loading gauge<br>Train data (1/2)<br>PASS 1<br>200<br>135<br>160<br>A<br>no<br>Out of GC<br>Train data entry complete?<br>Select<br>type<br>Yes<br>Train category<br>Length (m)<br>200<br>Brake percentage<br>135<br>Max speed (km/h)<br>160<br>PASS 1|Train category<br>Length (m)<br>Brake percentage<br>Max speed (km/h)<br>Axle load category<br>Airtight<br>Loading gauge<br>Train data (1/2)<br>PASS 1<br>200<br>135<br>160<br>A<br>no<br>Out of GC<br>Train data entry complete?<br>Select<br>type<br>Yes<br>Train category<br>Length (m)<br>200<br>Brake percentage<br>135<br>Max speed (km/h)<br>160<br>PASS 1|Train category<br>Length (m)<br>Brake percentage<br>Max speed (km/h)<br>Axle load category<br>Airtight<br>Loading gauge<br>Train data (1/2)<br>PASS 1<br>200<br>135<br>160<br>A<br>no<br>Out of GC<br>Train data entry complete?<br>Select<br>type<br>Yes<br>Train category<br>Length (m)<br>200<br>Brake percentage<br>135<br>Max speed (km/h)<br>160<br>PASS 1|Train category<br>Length (m)<br>Brake percentage<br>Max speed (km/h)<br>Axle load category<br>Airtight<br>Loading gauge<br>Train data (1/2)<br>PASS 1<br>200<br>135<br>160<br>A<br>no<br>Out of GC<br>Train data entry complete?<br>Select<br>type<br>Yes<br>Train category<br>Length (m)<br>200<br>Brake percentage<br>135<br>Max speed (km/h)<br>160<br>PASS 1|Brake percentage<br>135|Brake percentage<br>135|Brake percentage<br>135|Brake percentage<br>135|Brake percentage<br>135||
|Train category<br>Length (m)<br>Brake percentage<br>Max speed (km/h)<br>Axle load category<br>Airtight<br>Loading gauge<br>Train data (1/2)<br>PASS 1<br>200<br>135<br>160<br>A<br>no<br>Out of GC<br>Train data entry complete?<br>Select<br>type<br>Yes<br>Train category<br>Length (m)<br>200<br>Brake percentage<br>135<br>Max speed (km/h)<br>160<br>PASS 1|Train category<br>Length (m)<br>Brake percentage<br>Max speed (km/h)<br>Axle load category<br>Airtight<br>Loading gauge<br>Train data (1/2)<br>PASS 1<br>200<br>135<br>160<br>A<br>no<br>Out of GC<br>Train data entry complete?<br>Select<br>type<br>Yes<br>Train category<br>Length (m)<br>200<br>Brake percentage<br>135<br>Max speed (km/h)<br>160<br>PASS 1|Train category<br>Length (m)<br>Brake percentage<br>Max speed (km/h)<br>Axle load category<br>Airtight<br>Loading gauge<br>Train data (1/2)<br>PASS 1<br>200<br>135<br>160<br>A<br>no<br>Out of GC<br>Train data entry complete?<br>Select<br>type<br>Yes<br>Train category<br>Length (m)<br>200<br>Brake percentage<br>135<br>Max speed (km/h)<br>160<br>PASS 1|Train category<br>Length (m)<br>Brake percentage<br>Max speed (km/h)<br>Axle load category<br>Airtight<br>Loading gauge<br>Train data (1/2)<br>PASS 1<br>200<br>135<br>160<br>A<br>no<br>Out of GC<br>Train data entry complete?<br>Select<br>type<br>Yes<br>Train category<br>Length (m)<br>200<br>Brake percentage<br>135<br>Max speed (km/h)<br>160<br>PASS 1|Train category<br>Length (m)<br>Brake percentage<br>Max speed (km/h)<br>Axle load category<br>Airtight<br>Loading gauge<br>Train data (1/2)<br>PASS 1<br>200<br>135<br>160<br>A<br>no<br>Out of GC<br>Train data entry complete?<br>Select<br>type<br>Yes<br>Train category<br>Length (m)<br>200<br>Brake percentage<br>135<br>Max speed (km/h)<br>160<br>PASS 1|Train category<br>Length (m)<br>Brake percentage<br>Max speed (km/h)<br>Axle load category<br>Airtight<br>Loading gauge<br>Train data (1/2)<br>PASS 1<br>200<br>135<br>160<br>A<br>no<br>Out of GC<br>Train data entry complete?<br>Select<br>type<br>Yes<br>Train category<br>Length (m)<br>200<br>Brake percentage<br>135<br>Max speed (km/h)<br>160<br>PASS 1|Brake percentage<br>135|Brake percentage<br>135|Brake percentage<br>135|Brake percentage<br>135|Brake percentage<br>135||
|Train category<br>Length (m)<br>Brake percentage<br>Max speed (km/h)<br>Axle load category<br>Airtight<br>Loading gauge<br>Train data (1/2)<br>PASS 1<br>200<br>135<br>160<br>A<br>no<br>Out of GC<br>Train data entry complete?<br>Select<br>type<br>Yes<br>Train category<br>Length (m)<br>200<br>Brake percentage<br>135<br>Max speed (km/h)<br>160<br>PASS 1|Train category<br>Length (m)<br>Brake percentage<br>Max speed (km/h)<br>Axle load category<br>Airtight<br>Loading gauge<br>Train data (1/2)<br>PASS 1<br>200<br>135<br>160<br>A<br>no<br>Out of GC<br>Train data entry complete?<br>Select<br>type<br>Yes<br>Train category<br>Length (m)<br>200<br>Brake percentage<br>135<br>Max speed (km/h)<br>160<br>PASS 1|Train category<br>Length (m)<br>Brake percentage<br>Max speed (km/h)<br>Axle load category<br>Airtight<br>Loading gauge<br>Train data (1/2)<br>PASS 1<br>200<br>135<br>160<br>A<br>no<br>Out of GC<br>Train data entry complete?<br>Select<br>type<br>Yes<br>Train category<br>Length (m)<br>200<br>Brake percentage<br>135<br>Max speed (km/h)<br>160<br>PASS 1|Train category<br>Length (m)<br>Brake percentage<br>Max speed (km/h)<br>Axle load category<br>Airtight<br>Loading gauge<br>Train data (1/2)<br>PASS 1<br>200<br>135<br>160<br>A<br>no<br>Out of GC<br>Train data entry complete?<br>Select<br>type<br>Yes<br>Train category<br>Length (m)<br>200<br>Brake percentage<br>135<br>Max speed (km/h)<br>160<br>PASS 1|Train category<br>Length (m)<br>Brake percentage<br>Max speed (km/h)<br>Axle load category<br>Airtight<br>Loading gauge<br>Train data (1/2)<br>PASS 1<br>200<br>135<br>160<br>A<br>no<br>Out of GC<br>Train data entry complete?<br>Select<br>type<br>Yes<br>Train category<br>Length (m)<br>200<br>Brake percentage<br>135<br>Max speed (km/h)<br>160<br>PASS 1|Train category<br>Length (m)<br>Brake percentage<br>Max speed (km/h)<br>Axle load category<br>Airtight<br>Loading gauge<br>Train data (1/2)<br>PASS 1<br>200<br>135<br>160<br>A<br>no<br>Out of GC<br>Train data entry complete?<br>Select<br>type<br>Yes<br>Train category<br>Length (m)<br>200<br>Brake percentage<br>135<br>Max speed (km/h)<br>160<br>PASS 1|Brake percentage<br>135|Brake percentage<br>135|Brake percentage<br>135|Brake percentage<br>135|Brake percentage<br>135||
|Train category<br>Length (m)<br>Brake percentage<br>Max speed (km/h)<br>Axle load category<br>Airtight<br>Loading gauge<br>Train data (1/2)<br>PASS 1<br>200<br>135<br>160<br>A<br>no<br>Out of GC<br>Train data entry complete?<br>Select<br>type<br>Yes<br>Train category<br>Length (m)<br>200<br>Brake percentage<br>135<br>Max speed (km/h)<br>160<br>PASS 1|Train category<br>Length (m)<br>Brake percentage<br>Max speed (km/h)<br>Axle load category<br>Airtight<br>Loading gauge<br>Train data (1/2)<br>PASS 1<br>200<br>135<br>160<br>A<br>no<br>Out of GC<br>Train data entry complete?<br>Select<br>type<br>Yes<br>Train category<br>Length (m)<br>200<br>Brake percentage<br>135<br>Max speed (km/h)<br>160<br>PASS 1|Train category<br>Length (m)<br>Brake percentage<br>Max speed (km/h)<br>Axle load category<br>Airtight<br>Loading gauge<br>Train data (1/2)<br>PASS 1<br>200<br>135<br>160<br>A<br>no<br>Out of GC<br>Train data entry complete?<br>Select<br>type<br>Yes<br>Train category<br>Length (m)<br>200<br>Brake percentage<br>135<br>Max speed (km/h)<br>160<br>PASS 1|Train category<br>Length (m)<br>Brake percentage<br>Max speed (km/h)<br>Axle load category<br>Airtight<br>Loading gauge<br>Train data (1/2)<br>PASS 1<br>200<br>135<br>160<br>A<br>no<br>Out of GC<br>Train data entry complete?<br>Select<br>type<br>Yes<br>Train category<br>Length (m)<br>200<br>Brake percentage<br>135<br>Max speed (km/h)<br>160<br>PASS 1|Train category<br>Length (m)<br>Brake percentage<br>Max speed (km/h)<br>Axle load category<br>Airtight<br>Loading gauge<br>Train data (1/2)<br>PASS 1<br>200<br>135<br>160<br>A<br>no<br>Out of GC<br>Train data entry complete?<br>Select<br>type<br>Yes<br>Train category<br>Length (m)<br>200<br>Brake percentage<br>135<br>Max speed (km/h)<br>160<br>PASS 1|Train category<br>Length (m)<br>Brake percentage<br>Max speed (km/h)<br>Axle load category<br>Airtight<br>Loading gauge<br>Train data (1/2)<br>PASS 1<br>200<br>135<br>160<br>A<br>no<br>Out of GC<br>Train data entry complete?<br>Select<br>type<br>Yes<br>Train category<br>Length (m)<br>200<br>Brake percentage<br>135<br>Max speed (km/h)<br>160<br>PASS 1|Brake percentage<br>135|Brake percentage<br>135|Brake percentage<br>135|Brake percentage<br>135|Brake percentage<br>135||
|Yes|Yes|Yes|Yes|Yes|Yes|Yes|Yes|Yes|Select<br>type|Select<br>type|Select<br>type|
|||Yes|||||||Select<br>type|||
|||||||||||||


**Figure 125 – Train data window allowing to switch from variable to fixed train formations**


**11.3.10** **SR speed / distance window**


11.3.10.1 The SR speed/distance window shall comply with the requirements in chapter 10.3 for a

window on total grid array with echo texts and with the question ‘SR speed / distance entry
complete?’.


11.3.10.2 The window title shall indicate “SR speed / distance”.


Version 4.0.0 PAGE 200 OF 317


**ERA ERTMS unit**

**ETCS Driver Machine Interface**


11.3.10.3 If data check rules have been defined for SR speed / distance, the requirements in chapter

10.3.4 shall apply for the echo texts.


11.3.10.4 The 1 [st] input field shall be used for the entry / revalidation of the SR speed.


11.3.10.5 The 2 [nd] input field shall be used for the entry / revalidation of the SR distance.


11.3.10.6 The keyboards associated to the 2 input field(s) “SR speed” and “SR distance” shall be

numeric keyboards.


11.3.10.7 Figure 126 shows the presentation of the SR speed / distance window.


Version 4.0.0 PAGE 201 OF 317


**ERA ERTMS unit**

**ETCS Driver Machine Interface**






















|SR speed/distance entry complete?<br>Yes|1|Col3|2|3|
|---|---|---|---|---|
|SR speed/distance entry complete?<br>Yes|4|4|5|6|
|SR speed/distance entry complete?<br>Yes|7|7|8|9|
|SR speed/distance entry complete?<br>Yes|Del|Del|0|**.**|
|SR speed/distance entry complete?<br>Yes|||||













|SR speed/distance<br>SR speed (km/h) 40<br>Del<br>SR distance (m) 450<br>SR speed (km/h) 40<br>SR distance (m) 450<br>SR speed/distance entry complete?<br>Yes|Col2|Col3|Col4|Col5|Col6|Col7|Col8|Col9|Col10|Col11|Col12|Col13|
|---|---|---|---|---|---|---|---|---|---|---|---|---|
|Del<br>SR speed/distance<br>450<br>40<br>SR speed (km/h)<br>SR distance (m)<br>SR speed/distance entry complete?<br>Yes<br>SR speed (km/h)<br>SR distance (m)<br>40<br>450|Del<br>SR speed/distance<br>450<br>40<br>SR speed (km/h)<br>SR distance (m)<br>SR speed/distance entry complete?<br>Yes<br>SR speed (km/h)<br>SR distance (m)<br>40<br>450|Del<br>SR speed/distance<br>450<br>40<br>SR speed (km/h)<br>SR distance (m)<br>SR speed/distance entry complete?<br>Yes<br>SR speed (km/h)<br>SR distance (m)<br>40<br>450|Del<br>SR speed/distance<br>450<br>40<br>SR speed (km/h)<br>SR distance (m)<br>SR speed/distance entry complete?<br>Yes<br>SR speed (km/h)<br>SR distance (m)<br>40<br>450|Del<br>SR speed/distance<br>450<br>40<br>SR speed (km/h)<br>SR distance (m)<br>SR speed/distance entry complete?<br>Yes<br>SR speed (km/h)<br>SR distance (m)<br>40<br>450|Del<br>SR speed/distance<br>450<br>40<br>SR speed (km/h)<br>SR distance (m)<br>SR speed/distance entry complete?<br>Yes<br>SR speed (km/h)<br>SR distance (m)<br>40<br>450|SR speed (km/h)|SR speed (km/h)|SR speed (km/h)|40|40|40|40|
|Del<br>SR speed/distance<br>450<br>40<br>SR speed (km/h)<br>SR distance (m)<br>SR speed/distance entry complete?<br>Yes<br>SR speed (km/h)<br>SR distance (m)<br>40<br>450|Del<br>SR speed/distance<br>450<br>40<br>SR speed (km/h)<br>SR distance (m)<br>SR speed/distance entry complete?<br>Yes<br>SR speed (km/h)<br>SR distance (m)<br>40<br>450|Del<br>SR speed/distance<br>450<br>40<br>SR speed (km/h)<br>SR distance (m)<br>SR speed/distance entry complete?<br>Yes<br>SR speed (km/h)<br>SR distance (m)<br>40<br>450|Del<br>SR speed/distance<br>450<br>40<br>SR speed (km/h)<br>SR distance (m)<br>SR speed/distance entry complete?<br>Yes<br>SR speed (km/h)<br>SR distance (m)<br>40<br>450|Del<br>SR speed/distance<br>450<br>40<br>SR speed (km/h)<br>SR distance (m)<br>SR speed/distance entry complete?<br>Yes<br>SR speed (km/h)<br>SR distance (m)<br>40<br>450|Del<br>SR speed/distance<br>450<br>40<br>SR speed (km/h)<br>SR distance (m)<br>SR speed/distance entry complete?<br>Yes<br>SR speed (km/h)<br>SR distance (m)<br>40<br>450|SR speed (km/h)|SR speed (km/h)|SR speed (km/h)|40|40|40|Del|
|Del<br>SR speed/distance<br>450<br>40<br>SR speed (km/h)<br>SR distance (m)<br>SR speed/distance entry complete?<br>Yes<br>SR speed (km/h)<br>SR distance (m)<br>40<br>450|Del<br>SR speed/distance<br>450<br>40<br>SR speed (km/h)<br>SR distance (m)<br>SR speed/distance entry complete?<br>Yes<br>SR speed (km/h)<br>SR distance (m)<br>40<br>450|Del<br>SR speed/distance<br>450<br>40<br>SR speed (km/h)<br>SR distance (m)<br>SR speed/distance entry complete?<br>Yes<br>SR speed (km/h)<br>SR distance (m)<br>40<br>450|Del<br>SR speed/distance<br>450<br>40<br>SR speed (km/h)<br>SR distance (m)<br>SR speed/distance entry complete?<br>Yes<br>SR speed (km/h)<br>SR distance (m)<br>40<br>450|Del<br>SR speed/distance<br>450<br>40<br>SR speed (km/h)<br>SR distance (m)<br>SR speed/distance entry complete?<br>Yes<br>SR speed (km/h)<br>SR distance (m)<br>40<br>450|Del<br>SR speed/distance<br>450<br>40<br>SR speed (km/h)<br>SR distance (m)<br>SR speed/distance entry complete?<br>Yes<br>SR speed (km/h)<br>SR distance (m)<br>40<br>450|450<br>SR distance (m)|450<br>SR distance (m)|450<br>SR distance (m)|450<br>SR distance (m)|450<br>SR distance (m)|450<br>SR distance (m)|450<br>SR distance (m)|
|Del<br>SR speed/distance<br>450<br>40<br>SR speed (km/h)<br>SR distance (m)<br>SR speed/distance entry complete?<br>Yes<br>SR speed (km/h)<br>SR distance (m)<br>40<br>450|Del<br>SR speed/distance<br>450<br>40<br>SR speed (km/h)<br>SR distance (m)<br>SR speed/distance entry complete?<br>Yes<br>SR speed (km/h)<br>SR distance (m)<br>40<br>450|Del<br>SR speed/distance<br>450<br>40<br>SR speed (km/h)<br>SR distance (m)<br>SR speed/distance entry complete?<br>Yes<br>SR speed (km/h)<br>SR distance (m)<br>40<br>450|Del<br>SR speed/distance<br>450<br>40<br>SR speed (km/h)<br>SR distance (m)<br>SR speed/distance entry complete?<br>Yes<br>SR speed (km/h)<br>SR distance (m)<br>40<br>450|Del<br>SR speed/distance<br>450<br>40<br>SR speed (km/h)<br>SR distance (m)<br>SR speed/distance entry complete?<br>Yes<br>SR speed (km/h)<br>SR distance (m)<br>40<br>450|Del<br>SR speed/distance<br>450<br>40<br>SR speed (km/h)<br>SR distance (m)<br>SR speed/distance entry complete?<br>Yes<br>SR speed (km/h)<br>SR distance (m)<br>40<br>450|450<br>SR distance (m)|450<br>SR distance (m)|450<br>SR distance (m)|450<br>SR distance (m)|450<br>SR distance (m)|450<br>SR distance (m)||
|Del<br>SR speed/distance<br>450<br>40<br>SR speed (km/h)<br>SR distance (m)<br>SR speed/distance entry complete?<br>Yes<br>SR speed (km/h)<br>SR distance (m)<br>40<br>450|Del<br>SR speed/distance<br>450<br>40<br>SR speed (km/h)<br>SR distance (m)<br>SR speed/distance entry complete?<br>Yes<br>SR speed (km/h)<br>SR distance (m)<br>40<br>450|Del<br>SR speed/distance<br>450<br>40<br>SR speed (km/h)<br>SR distance (m)<br>SR speed/distance entry complete?<br>Yes<br>SR speed (km/h)<br>SR distance (m)<br>40<br>450|Del<br>SR speed/distance<br>450<br>40<br>SR speed (km/h)<br>SR distance (m)<br>SR speed/distance entry complete?<br>Yes<br>SR speed (km/h)<br>SR distance (m)<br>40<br>450|Del<br>SR speed/distance<br>450<br>40<br>SR speed (km/h)<br>SR distance (m)<br>SR speed/distance entry complete?<br>Yes<br>SR speed (km/h)<br>SR distance (m)<br>40<br>450|Del<br>SR speed/distance<br>450<br>40<br>SR speed (km/h)<br>SR distance (m)<br>SR speed/distance entry complete?<br>Yes<br>SR speed (km/h)<br>SR distance (m)<br>40<br>450|450<br>SR distance (m)|450<br>SR distance (m)|450<br>SR distance (m)|450<br>SR distance (m)|450<br>SR distance (m)|450<br>SR distance (m)||
|Del<br>SR speed/distance<br>450<br>40<br>SR speed (km/h)<br>SR distance (m)<br>SR speed/distance entry complete?<br>Yes<br>SR speed (km/h)<br>SR distance (m)<br>40<br>450|Del<br>SR speed/distance<br>450<br>40<br>SR speed (km/h)<br>SR distance (m)<br>SR speed/distance entry complete?<br>Yes<br>SR speed (km/h)<br>SR distance (m)<br>40<br>450|Del<br>SR speed/distance<br>450<br>40<br>SR speed (km/h)<br>SR distance (m)<br>SR speed/distance entry complete?<br>Yes<br>SR speed (km/h)<br>SR distance (m)<br>40<br>450|Del<br>SR speed/distance<br>450<br>40<br>SR speed (km/h)<br>SR distance (m)<br>SR speed/distance entry complete?<br>Yes<br>SR speed (km/h)<br>SR distance (m)<br>40<br>450|Del<br>SR speed/distance<br>450<br>40<br>SR speed (km/h)<br>SR distance (m)<br>SR speed/distance entry complete?<br>Yes<br>SR speed (km/h)<br>SR distance (m)<br>40<br>450|Del<br>SR speed/distance<br>450<br>40<br>SR speed (km/h)<br>SR distance (m)<br>SR speed/distance entry complete?<br>Yes<br>SR speed (km/h)<br>SR distance (m)<br>40<br>450|450<br>SR distance (m)|450<br>SR distance (m)|450<br>SR distance (m)|450<br>SR distance (m)|450<br>SR distance (m)|450<br>SR distance (m)||
|Del<br>SR speed/distance<br>450<br>40<br>SR speed (km/h)<br>SR distance (m)<br>SR speed/distance entry complete?<br>Yes<br>SR speed (km/h)<br>SR distance (m)<br>40<br>450|Del<br>SR speed/distance<br>450<br>40<br>SR speed (km/h)<br>SR distance (m)<br>SR speed/distance entry complete?<br>Yes<br>SR speed (km/h)<br>SR distance (m)<br>40<br>450|Del<br>SR speed/distance<br>450<br>40<br>SR speed (km/h)<br>SR distance (m)<br>SR speed/distance entry complete?<br>Yes<br>SR speed (km/h)<br>SR distance (m)<br>40<br>450|Del<br>SR speed/distance<br>450<br>40<br>SR speed (km/h)<br>SR distance (m)<br>SR speed/distance entry complete?<br>Yes<br>SR speed (km/h)<br>SR distance (m)<br>40<br>450|Del<br>SR speed/distance<br>450<br>40<br>SR speed (km/h)<br>SR distance (m)<br>SR speed/distance entry complete?<br>Yes<br>SR speed (km/h)<br>SR distance (m)<br>40<br>450|Del<br>SR speed/distance<br>450<br>40<br>SR speed (km/h)<br>SR distance (m)<br>SR speed/distance entry complete?<br>Yes<br>SR speed (km/h)<br>SR distance (m)<br>40<br>450|450<br>SR distance (m)|450<br>SR distance (m)|450<br>SR distance (m)|450<br>SR distance (m)|450<br>SR distance (m)|450<br>SR distance (m)||
|Del<br>SR speed/distance<br>450<br>40<br>SR speed (km/h)<br>SR distance (m)<br>SR speed/distance entry complete?<br>Yes<br>SR speed (km/h)<br>SR distance (m)<br>40<br>450|Del<br>SR speed/distance<br>450<br>40<br>SR speed (km/h)<br>SR distance (m)<br>SR speed/distance entry complete?<br>Yes<br>SR speed (km/h)<br>SR distance (m)<br>40<br>450|Del<br>SR speed/distance<br>450<br>40<br>SR speed (km/h)<br>SR distance (m)<br>SR speed/distance entry complete?<br>Yes<br>SR speed (km/h)<br>SR distance (m)<br>40<br>450|Del<br>SR speed/distance<br>450<br>40<br>SR speed (km/h)<br>SR distance (m)<br>SR speed/distance entry complete?<br>Yes<br>SR speed (km/h)<br>SR distance (m)<br>40<br>450|Del<br>SR speed/distance<br>450<br>40<br>SR speed (km/h)<br>SR distance (m)<br>SR speed/distance entry complete?<br>Yes<br>SR speed (km/h)<br>SR distance (m)<br>40<br>450|Del<br>SR speed/distance<br>450<br>40<br>SR speed (km/h)<br>SR distance (m)<br>SR speed/distance entry complete?<br>Yes<br>SR speed (km/h)<br>SR distance (m)<br>40<br>450|450<br>SR distance (m)|450<br>SR distance (m)|450<br>SR distance (m)|450<br>SR distance (m)|450<br>SR distance (m)|450<br>SR distance (m)||
|Yes|Yes|Yes|Yes|Yes|Yes|Yes|Yes|Yes|Yes|Yes|Yes|Yes|
|1|2|3|4|5|6|6|7|8|8|9|0|0|
||||||||||||||


**Figure 126 – SR speed / distance window**


**11.3.11** **Adhesion window**


11.3.11.1 The adhesion window shall comply with the requirements in chapter 10.3 for a window on

half grid array containing a single input field with only the data part.


11.3.11.2 The window title shall indicate “Adhesion”.


11.3.11.3 The single input field shall be used for the entry / revalidation of the adhesion.


Version 4.0.0 PAGE 202 OF 317


**ERA ERTMS unit**

**ETCS Driver Machine Interface**


11.3.11.4 The keyboard associated to the adhesion shall be a dedicated keyboard as specified in

Table 43 displaying the possible adhesion status.

|Button /selection #|Label|
|---|---|
|1|Non slippery rail|
|2|Slippery rail|



**Table 43 – Keyboard for adhesion**


11.3.11.5 Figure 127 shows the presentation of the adhesion window.



|Col1|Col2|Col3|150<br>100 200<br>0<br>50 300<br>0 400|Col5|Col6|Col7|Col8|Adhesion<br>Non slippery rail<br>Non slippery<br>Slippery rail<br>rail|
|---|---|---|---|---|---|---|---|---|
||||||||||
||||||||||
|**2**|**2**|**2**|||||||
||||||||||
||||||||||
||||||||||
||||||||||
||||||||||
||||||||||


|Col1|Col2|Col3|150<br>100 200<br>0<br>50 300<br>0 400|Col5|Col6|Col7|Col8|Col9|Col10|Col11|Adhesion<br>Non slippery rail|Col13|Col14|Col15|Col16|Col17|
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
||||**0**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**0**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**0**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**0**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**0**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**0**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**0**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**0**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|Adhesion<br>Non slippery rail|Adhesion<br>Non slippery rail|Adhesion<br>Non slippery rail|Adhesion<br>Non slippery rail|Adhesion<br>Non slippery rail||
||||||||||||Non slippery rail|Non slippery rail|Non slippery rail|Non slippery rail|Non slippery rail|Non slippery rail|
||||||||||||1 - Non slippery rail<br>2 - Slippery rail|1 - Non slippery rail<br>2 - Slippery rail|1 - Non slippery rail<br>2 - Slippery rail|1 - Non slippery rail<br>2 - Slippery rail|1 - Non slippery rail<br>2 - Slippery rail||
||||||||||||1 - Non slippery rail<br>2 - Slippery rail|1 - Non slippery rail<br>2 - Slippery rail|1 - Non slippery rail<br>2 - Slippery rail|1 - Non slippery rail<br>2 - Slippery rail|1 - Non slippery rail<br>2 - Slippery rail||
||||||||||||1 - Non slippery rail<br>2 - Slippery rail|1 - Non slippery rail<br>2 - Slippery rail|1 - Non slippery rail<br>2 - Slippery rail|1 - Non slippery rail<br>2 - Slippery rail|1 - Non slippery rail<br>2 - Slippery rail||
||||||||||||||||||
||||||||||||||||||
|**2**|**2**|**2**|||||||||||||||
||||||||||||||||||
||||||||||||||||||
||||||||||||||||||
||||||||||||||||||
||||||||||||||||||
||||||||||||||||||
|1|1|1|2||||||||||||||


Version 4.0.0 PAGE 203 OF 317







**Figure 127 – Adhesion window**


**ERA ERTMS unit**

**ETCS Driver Machine Interface**


**11.3.12** **Set VBC window**


11.3.12.1 The Set VBC window shall comply with the requirements in chapter 10.3 for a window on

total grid array with echo texts and with the question ‘Set VBC entry complete?’.


11.3.12.2 The window title shall indicate “Set VBC”.


11.3.12.3 If data check rules have been defined for set VBC, the requirements in chapter 10.3.4

shall apply for the echo texts.


11.3.12.4 The single input field ‘VBC set code’ with the label ‘VBC code’ shall be used for the entry

of a new VBC in the list of Virtual Balise Covers stored on-board.


11.3.12.5 When converting the entered ‘VBC set code’ into binary format, the 6 less significant bits

shall form the variable NID_VBCMK, the next 10 bits shall form the variable NID_C and
the remaining bits shall form the variable T_VBC (see [2] chapter 7 for the definitions of
NID_C, NID_VBCMK and T_VBC).


11.3.12.6 The keyboard associated to the ‘VBC set code’ shall be a numeric keyboard.


11.3.12.7 Figure 128 shows the presentation of the Set VBC window.


Version 4.0.0 PAGE 204 OF 317


**ERA ERTMS unit**

**ETCS Driver Machine Interface**
















|Set VBC entry complete?<br>Yes|1|Col3|2|3|
|---|---|---|---|---|
|Set VBC entry complete?<br>Yes|4|4|5|6|
|Set VBC entry complete?<br>Yes|7|7|8|9|
|Set VBC entry complete?<br>Yes|Del|Del|0|**.**|
|Set VBC entry complete?<br>Yes|||||









|Set VBC<br>VBC code 321456<br>Del<br>VBC code 321456<br>Set VBC entry complete?<br>Yes|Col2|Col3|Col4|Col5|Col6|Col7|Col8|Col9|Col10|Col11|
|---|---|---|---|---|---|---|---|---|---|---|
|Del<br>Set VBC<br>VBC code<br>Yes<br>Set VBC entry complete?<br>VBC code<br>321456<br>321456|Del<br>Set VBC<br>VBC code<br>Yes<br>Set VBC entry complete?<br>VBC code<br>321456<br>321456|Del<br>Set VBC<br>VBC code<br>Yes<br>Set VBC entry complete?<br>VBC code<br>321456<br>321456|Del<br>Set VBC<br>VBC code<br>Yes<br>Set VBC entry complete?<br>VBC code<br>321456<br>321456|Del<br>Set VBC<br>VBC code<br>Yes<br>Set VBC entry complete?<br>VBC code<br>321456<br>321456|Del<br>Set VBC<br>VBC code<br>Yes<br>Set VBC entry complete?<br>VBC code<br>321456<br>321456|Del<br>Set VBC<br>VBC code<br>Yes<br>Set VBC entry complete?<br>VBC code<br>321456<br>321456|Del<br>Set VBC<br>VBC code<br>Yes<br>Set VBC entry complete?<br>VBC code<br>321456<br>321456|Del<br>Set VBC<br>VBC code<br>Yes<br>Set VBC entry complete?<br>VBC code<br>321456<br>321456|Del<br>Set VBC<br>VBC code<br>Yes<br>Set VBC entry complete?<br>VBC code<br>321456<br>321456|Del|
|Del<br>Set VBC<br>VBC code<br>Yes<br>Set VBC entry complete?<br>VBC code<br>321456<br>321456|Del<br>Set VBC<br>VBC code<br>Yes<br>Set VBC entry complete?<br>VBC code<br>321456<br>321456|Del<br>Set VBC<br>VBC code<br>Yes<br>Set VBC entry complete?<br>VBC code<br>321456<br>321456|Del<br>Set VBC<br>VBC code<br>Yes<br>Set VBC entry complete?<br>VBC code<br>321456<br>321456|Del<br>Set VBC<br>VBC code<br>Yes<br>Set VBC entry complete?<br>VBC code<br>321456<br>321456|Del<br>Set VBC<br>VBC code<br>Yes<br>Set VBC entry complete?<br>VBC code<br>321456<br>321456|Del<br>Set VBC<br>VBC code<br>Yes<br>Set VBC entry complete?<br>VBC code<br>321456<br>321456|Del<br>Set VBC<br>VBC code<br>Yes<br>Set VBC entry complete?<br>VBC code<br>321456<br>321456|Del<br>Set VBC<br>VBC code<br>Yes<br>Set VBC entry complete?<br>VBC code<br>321456<br>321456|Del<br>Set VBC<br>VBC code<br>Yes<br>Set VBC entry complete?<br>VBC code<br>321456<br>321456||
|Del<br>Set VBC<br>VBC code<br>Yes<br>Set VBC entry complete?<br>VBC code<br>321456<br>321456|Del<br>Set VBC<br>VBC code<br>Yes<br>Set VBC entry complete?<br>VBC code<br>321456<br>321456|Del<br>Set VBC<br>VBC code<br>Yes<br>Set VBC entry complete?<br>VBC code<br>321456<br>321456|Del<br>Set VBC<br>VBC code<br>Yes<br>Set VBC entry complete?<br>VBC code<br>321456<br>321456|Del<br>Set VBC<br>VBC code<br>Yes<br>Set VBC entry complete?<br>VBC code<br>321456<br>321456|Del<br>Set VBC<br>VBC code<br>Yes<br>Set VBC entry complete?<br>VBC code<br>321456<br>321456|Del<br>Set VBC<br>VBC code<br>Yes<br>Set VBC entry complete?<br>VBC code<br>321456<br>321456|Del<br>Set VBC<br>VBC code<br>Yes<br>Set VBC entry complete?<br>VBC code<br>321456<br>321456|Del<br>Set VBC<br>VBC code<br>Yes<br>Set VBC entry complete?<br>VBC code<br>321456<br>321456|Del<br>Set VBC<br>VBC code<br>Yes<br>Set VBC entry complete?<br>VBC code<br>321456<br>321456||
|Del<br>Set VBC<br>VBC code<br>Yes<br>Set VBC entry complete?<br>VBC code<br>321456<br>321456|Del<br>Set VBC<br>VBC code<br>Yes<br>Set VBC entry complete?<br>VBC code<br>321456<br>321456|Del<br>Set VBC<br>VBC code<br>Yes<br>Set VBC entry complete?<br>VBC code<br>321456<br>321456|Del<br>Set VBC<br>VBC code<br>Yes<br>Set VBC entry complete?<br>VBC code<br>321456<br>321456|Del<br>Set VBC<br>VBC code<br>Yes<br>Set VBC entry complete?<br>VBC code<br>321456<br>321456|Del<br>Set VBC<br>VBC code<br>Yes<br>Set VBC entry complete?<br>VBC code<br>321456<br>321456|Del<br>Set VBC<br>VBC code<br>Yes<br>Set VBC entry complete?<br>VBC code<br>321456<br>321456|Del<br>Set VBC<br>VBC code<br>Yes<br>Set VBC entry complete?<br>VBC code<br>321456<br>321456|Del<br>Set VBC<br>VBC code<br>Yes<br>Set VBC entry complete?<br>VBC code<br>321456<br>321456|Del<br>Set VBC<br>VBC code<br>Yes<br>Set VBC entry complete?<br>VBC code<br>321456<br>321456||
|Del<br>Set VBC<br>VBC code<br>Yes<br>Set VBC entry complete?<br>VBC code<br>321456<br>321456|Del<br>Set VBC<br>VBC code<br>Yes<br>Set VBC entry complete?<br>VBC code<br>321456<br>321456|Del<br>Set VBC<br>VBC code<br>Yes<br>Set VBC entry complete?<br>VBC code<br>321456<br>321456|Del<br>Set VBC<br>VBC code<br>Yes<br>Set VBC entry complete?<br>VBC code<br>321456<br>321456|Del<br>Set VBC<br>VBC code<br>Yes<br>Set VBC entry complete?<br>VBC code<br>321456<br>321456|Del<br>Set VBC<br>VBC code<br>Yes<br>Set VBC entry complete?<br>VBC code<br>321456<br>321456|Del<br>Set VBC<br>VBC code<br>Yes<br>Set VBC entry complete?<br>VBC code<br>321456<br>321456|Del<br>Set VBC<br>VBC code<br>Yes<br>Set VBC entry complete?<br>VBC code<br>321456<br>321456|Del<br>Set VBC<br>VBC code<br>Yes<br>Set VBC entry complete?<br>VBC code<br>321456<br>321456|Del<br>Set VBC<br>VBC code<br>Yes<br>Set VBC entry complete?<br>VBC code<br>321456<br>321456||
|Del<br>Set VBC<br>VBC code<br>Yes<br>Set VBC entry complete?<br>VBC code<br>321456<br>321456|Del<br>Set VBC<br>VBC code<br>Yes<br>Set VBC entry complete?<br>VBC code<br>321456<br>321456|Del<br>Set VBC<br>VBC code<br>Yes<br>Set VBC entry complete?<br>VBC code<br>321456<br>321456|Del<br>Set VBC<br>VBC code<br>Yes<br>Set VBC entry complete?<br>VBC code<br>321456<br>321456|Del<br>Set VBC<br>VBC code<br>Yes<br>Set VBC entry complete?<br>VBC code<br>321456<br>321456|Del<br>Set VBC<br>VBC code<br>Yes<br>Set VBC entry complete?<br>VBC code<br>321456<br>321456|Del<br>Set VBC<br>VBC code<br>Yes<br>Set VBC entry complete?<br>VBC code<br>321456<br>321456|Del<br>Set VBC<br>VBC code<br>Yes<br>Set VBC entry complete?<br>VBC code<br>321456<br>321456|Del<br>Set VBC<br>VBC code<br>Yes<br>Set VBC entry complete?<br>VBC code<br>321456<br>321456|Del<br>Set VBC<br>VBC code<br>Yes<br>Set VBC entry complete?<br>VBC code<br>321456<br>321456||
|Yes|Yes|Yes|Yes|Yes|Yes|Yes|Yes|Yes|Yes|Yes|
|1|2|3|4|5|6|7|8|9|0|0|
||||||||||||


**Figure 128 – Set VBC window**


**11.3.13** **Remove VBC window**


11.3.13.1 The Remove VBC window shall comply with the requirements in chapter 10.3 for a window

on total grid array with echo texts and with the question ‘Remove VBC entry complete?’.


11.3.13.2 The window title shall indicate “Remove VBC”.


11.3.13.3 If data check rules have been defined for Remove VBC, the requirements in chapter

10.3.4 shall apply for the echo text.


Version 4.0.0 PAGE 205 OF 317


**ERA ERTMS unit**

**ETCS Driver Machine Interface**


11.3.13.4 The single input field ‘VBC remove code’ with the label ‘VBC code’ shall be used for the

entry of a VBC to be removed from the list of Virtual Balise Covers stored on-board.


11.3.13.5 When converting the entered ‘VBC remove code’ into binary format, the 10 less significant

bits shall form the variable NID_C, the next 6 bits shall form the variable NID_VBCMK and
the remaining bits (max 8 bits) shall not be used by the on-board (see [2] chapter 7 for the
definitions of NID_C, NID_VBCMK).


11.3.13.6 The keyboard associated to the ‘VBC remove code’ shall be a numeric keyboard.


11.3.13.7 Figure 129 shows the presentation of the Remove VBC window.


Version 4.0.0 PAGE 206 OF 317


**ERA ERTMS unit**

**ETCS Driver Machine Interface**












|Remove VBC entry complete?<br>Yes|1|Col3|2|3|
|---|---|---|---|---|
|Yes<br>Remove VBC entry complete?|4|4|5|6|
|Yes<br>Remove VBC entry complete?|7|7|8|9|
|Yes<br>Remove VBC entry complete?|Del|Del|0|**.**|
|Yes<br>Remove VBC entry complete?|||||









|Remove VBC<br>VBC code 50078<br>Del<br>VBC code 50078<br>Remove VBC entry complete?<br>Yes|Col2|Col3|Col4|Col5|Col6|Col7|Col8|Col9|Col10|Col11|
|---|---|---|---|---|---|---|---|---|---|---|
|Del<br>VBC code 50078<br>Yes<br>VBC code<br>Remove VBC<br>Remove VBC entry complete?<br>50078|Del<br>VBC code 50078<br>Yes<br>VBC code<br>Remove VBC<br>Remove VBC entry complete?<br>50078|Del<br>VBC code 50078<br>Yes<br>VBC code<br>Remove VBC<br>Remove VBC entry complete?<br>50078|Del<br>VBC code 50078<br>Yes<br>VBC code<br>Remove VBC<br>Remove VBC entry complete?<br>50078|Del<br>VBC code 50078<br>Yes<br>VBC code<br>Remove VBC<br>Remove VBC entry complete?<br>50078|Del<br>VBC code 50078<br>Yes<br>VBC code<br>Remove VBC<br>Remove VBC entry complete?<br>50078|Del<br>VBC code 50078<br>Yes<br>VBC code<br>Remove VBC<br>Remove VBC entry complete?<br>50078|Del<br>VBC code 50078<br>Yes<br>VBC code<br>Remove VBC<br>Remove VBC entry complete?<br>50078|Del<br>VBC code 50078<br>Yes<br>VBC code<br>Remove VBC<br>Remove VBC entry complete?<br>50078|Del<br>VBC code 50078<br>Yes<br>VBC code<br>Remove VBC<br>Remove VBC entry complete?<br>50078|Del|
|Del<br>VBC code 50078<br>Yes<br>VBC code<br>Remove VBC<br>Remove VBC entry complete?<br>50078|Del<br>VBC code 50078<br>Yes<br>VBC code<br>Remove VBC<br>Remove VBC entry complete?<br>50078|Del<br>VBC code 50078<br>Yes<br>VBC code<br>Remove VBC<br>Remove VBC entry complete?<br>50078|Del<br>VBC code 50078<br>Yes<br>VBC code<br>Remove VBC<br>Remove VBC entry complete?<br>50078|Del<br>VBC code 50078<br>Yes<br>VBC code<br>Remove VBC<br>Remove VBC entry complete?<br>50078|Del<br>VBC code 50078<br>Yes<br>VBC code<br>Remove VBC<br>Remove VBC entry complete?<br>50078|Del<br>VBC code 50078<br>Yes<br>VBC code<br>Remove VBC<br>Remove VBC entry complete?<br>50078|Del<br>VBC code 50078<br>Yes<br>VBC code<br>Remove VBC<br>Remove VBC entry complete?<br>50078|Del<br>VBC code 50078<br>Yes<br>VBC code<br>Remove VBC<br>Remove VBC entry complete?<br>50078|Del<br>VBC code 50078<br>Yes<br>VBC code<br>Remove VBC<br>Remove VBC entry complete?<br>50078||
|Del<br>VBC code 50078<br>Yes<br>VBC code<br>Remove VBC<br>Remove VBC entry complete?<br>50078|Del<br>VBC code 50078<br>Yes<br>VBC code<br>Remove VBC<br>Remove VBC entry complete?<br>50078|Del<br>VBC code 50078<br>Yes<br>VBC code<br>Remove VBC<br>Remove VBC entry complete?<br>50078|Del<br>VBC code 50078<br>Yes<br>VBC code<br>Remove VBC<br>Remove VBC entry complete?<br>50078|Del<br>VBC code 50078<br>Yes<br>VBC code<br>Remove VBC<br>Remove VBC entry complete?<br>50078|Del<br>VBC code 50078<br>Yes<br>VBC code<br>Remove VBC<br>Remove VBC entry complete?<br>50078|Del<br>VBC code 50078<br>Yes<br>VBC code<br>Remove VBC<br>Remove VBC entry complete?<br>50078|Del<br>VBC code 50078<br>Yes<br>VBC code<br>Remove VBC<br>Remove VBC entry complete?<br>50078|Del<br>VBC code 50078<br>Yes<br>VBC code<br>Remove VBC<br>Remove VBC entry complete?<br>50078|Del<br>VBC code 50078<br>Yes<br>VBC code<br>Remove VBC<br>Remove VBC entry complete?<br>50078||
|Del<br>VBC code 50078<br>Yes<br>VBC code<br>Remove VBC<br>Remove VBC entry complete?<br>50078|Del<br>VBC code 50078<br>Yes<br>VBC code<br>Remove VBC<br>Remove VBC entry complete?<br>50078|Del<br>VBC code 50078<br>Yes<br>VBC code<br>Remove VBC<br>Remove VBC entry complete?<br>50078|Del<br>VBC code 50078<br>Yes<br>VBC code<br>Remove VBC<br>Remove VBC entry complete?<br>50078|Del<br>VBC code 50078<br>Yes<br>VBC code<br>Remove VBC<br>Remove VBC entry complete?<br>50078|Del<br>VBC code 50078<br>Yes<br>VBC code<br>Remove VBC<br>Remove VBC entry complete?<br>50078|Del<br>VBC code 50078<br>Yes<br>VBC code<br>Remove VBC<br>Remove VBC entry complete?<br>50078|Del<br>VBC code 50078<br>Yes<br>VBC code<br>Remove VBC<br>Remove VBC entry complete?<br>50078|Del<br>VBC code 50078<br>Yes<br>VBC code<br>Remove VBC<br>Remove VBC entry complete?<br>50078|Del<br>VBC code 50078<br>Yes<br>VBC code<br>Remove VBC<br>Remove VBC entry complete?<br>50078||
|Del<br>VBC code 50078<br>Yes<br>VBC code<br>Remove VBC<br>Remove VBC entry complete?<br>50078|Del<br>VBC code 50078<br>Yes<br>VBC code<br>Remove VBC<br>Remove VBC entry complete?<br>50078|Del<br>VBC code 50078<br>Yes<br>VBC code<br>Remove VBC<br>Remove VBC entry complete?<br>50078|Del<br>VBC code 50078<br>Yes<br>VBC code<br>Remove VBC<br>Remove VBC entry complete?<br>50078|Del<br>VBC code 50078<br>Yes<br>VBC code<br>Remove VBC<br>Remove VBC entry complete?<br>50078|Del<br>VBC code 50078<br>Yes<br>VBC code<br>Remove VBC<br>Remove VBC entry complete?<br>50078|Del<br>VBC code 50078<br>Yes<br>VBC code<br>Remove VBC<br>Remove VBC entry complete?<br>50078|Del<br>VBC code 50078<br>Yes<br>VBC code<br>Remove VBC<br>Remove VBC entry complete?<br>50078|Del<br>VBC code 50078<br>Yes<br>VBC code<br>Remove VBC<br>Remove VBC entry complete?<br>50078|Del<br>VBC code 50078<br>Yes<br>VBC code<br>Remove VBC<br>Remove VBC entry complete?<br>50078||
|Del<br>VBC code 50078<br>Yes<br>VBC code<br>Remove VBC<br>Remove VBC entry complete?<br>50078|Del<br>VBC code 50078<br>Yes<br>VBC code<br>Remove VBC<br>Remove VBC entry complete?<br>50078|Del<br>VBC code 50078<br>Yes<br>VBC code<br>Remove VBC<br>Remove VBC entry complete?<br>50078|Del<br>VBC code 50078<br>Yes<br>VBC code<br>Remove VBC<br>Remove VBC entry complete?<br>50078|Del<br>VBC code 50078<br>Yes<br>VBC code<br>Remove VBC<br>Remove VBC entry complete?<br>50078|Del<br>VBC code 50078<br>Yes<br>VBC code<br>Remove VBC<br>Remove VBC entry complete?<br>50078|Del<br>VBC code 50078<br>Yes<br>VBC code<br>Remove VBC<br>Remove VBC entry complete?<br>50078|Del<br>VBC code 50078<br>Yes<br>VBC code<br>Remove VBC<br>Remove VBC entry complete?<br>50078|Del<br>VBC code 50078<br>Yes<br>VBC code<br>Remove VBC<br>Remove VBC entry complete?<br>50078|Del<br>VBC code 50078<br>Yes<br>VBC code<br>Remove VBC<br>Remove VBC entry complete?<br>50078||
|Yes|Yes|Yes|Yes|Yes|Yes|Yes|Yes|Yes|Yes|Yes|
|1|2|3|4|5|6|7|8|9|0|0|
||||||||||||


**Figure 129 – Remove VBC window**


**11.3.14** **ATO selector window**


11.3.14.1 The ATO selector window shall comply with the requirements in chapter 10.3 for a window

on half grid array containing a single input field with only the data part.


11.3.14.2 The window title shall indicate “ATO selector”.


11.3.14.3 The single input field shall be used for the entry / revalidation of the ATO selector position.


Version 4.0.0 PAGE 207 OF 317


**ERA ERTMS unit**

**ETCS Driver Machine Interface**


11.3.14.4 The keyboard associated to the ATO selector position shall be a dedicated keyboard as

specified in Table 43a displaying the possible ATO selector position.

|Button /selection #|Label|
|---|---|
|1|Stand-by|
|2|On|



**Table 43a – Keyboard for ATO selection**


11.3.14.5 In addition to the ATO selector window, the ERTMS/ETCS DMI may offer the following

possibility to enable/disable the automatic driving and the display of the information
related to the ERTMS/ATO subsystem: other means positioned on an ergonomic location
on the driver’s desk.


11.3.14.6 Figure 129a shows the presentation of the ATO selector window.


Version 4.0.0 PAGE 208 OF 317


**ERA ERTMS unit**

**ETCS Driver Machine Interface**








|Col1|Col2|Col3|150<br>100 200<br>0<br>50 300<br>0 400|Col5|Col6|Col7|Col8|ATO selector<br>On<br>Stand-by On|
|---|---|---|---|---|---|---|---|---|
||||||||||
||||||||||
|**2**|**2**|**2**|**2**||||||
||||||||||
||||||||||
||||||||||
||||||||||
||||||||||
||||||||||



|Col1|Col2|Col3|150<br>100 200<br>0<br>50 300<br>0 400|Col5|Col6|Col7|Col8|Col9|Col10|Col11|ATO selector<br>On|Col13|Col14|Col15|Col16|Col17|
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
||||**0**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**0**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**0**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**0**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**0**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**0**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**0**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**0**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|ATO selector<br>On|ATO selector<br>On|ATO selector<br>On|ATO selector<br>On|ATO selector<br>On||
||||||||||||On|On|On|On|On|On|
||||||||||||1 - Stand-by<br>2 - On|1 - Stand-by<br>2 - On|1 - Stand-by<br>2 - On|1 - Stand-by<br>2 - On|1 - Stand-by<br>2 - On||
||||||||||||1 - Stand-by<br>2 - On|1 - Stand-by<br>2 - On|1 - Stand-by<br>2 - On|1 - Stand-by<br>2 - On|1 - Stand-by<br>2 - On||
||||||||||||1 - Stand-by<br>2 - On|1 - Stand-by<br>2 - On|1 - Stand-by<br>2 - On|1 - Stand-by<br>2 - On|1 - Stand-by<br>2 - On||
||||||||||||||||||
||||||||||||||||||
|**2**|**2**|**2**|||||||||||||||
||||||||||||||||||
||||||||||||||||||
||||||||||||||||||
||||||||||||||||||
||||||||||||||||||
||||||||||||||||||
|1|1|1|2||||||||||||||


**Figure 129a – ATO selector window**


**11.3.15** **Radio network type window**


11.3.15.1 The Radio network type window shall comply with the requirements in chapter 10.3 for a

window on half grid array containing a single input field with only the data part.


11.3.15.2 The window title shall indicate “Radio network type”.


11.3.15.3 The single input field shall be used for the entry / revalidation of the Radio network type.


Version 4.0.0 PAGE 209 OF 317


**ERA ERTMS unit**

**ETCS Driver Machine Interface**


11.3.15.4 The keyboard associated to the Radio network type shall be a dedicated keyboard as

specified in Table 43b displaying the possible radio network types.

|Button /selection #|Label|
|---|---|
|1|FRMCS|
|2|FRMCS+GSM-R|
|3|GSM-R|



**Table 43b – Keyboard for Radio network type**


11.3.15.5 Figure 129b shows the presentation of the Radio network type window.


Version 4.0.0 PAGE 210 OF 317


**ERA ERTMS unit**

**ETCS Driver Machine Interface**


|Col1|150<br>100 200<br>0<br>50 300<br>0 400|Col3|Col4|Col5|Col6|Radio network type<br>FRMCS+GSM-R<br>FRMCS+<br>FRMCS GSM-R<br>GSM-R|
|---|---|---|---|---|---|---|
||||||||
|**2**|**2**||||||
||||||||
||||||||
||||||||
||||||||
||||||||











|Col1|150<br>100 200<br>0<br>50 300<br>0 400|Col3|Col4|Col5|Col6|Col7|Col8|Col9|Radio network type<br>FRMCS+GSM-R|Col11|Col12|Col13|Col14|Col15|
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
||**0**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**0**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**0**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**0**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**0**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**0**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**0**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**0**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|Radio network type<br>FRMCS+GSM-R|Radio network type<br>FRMCS+GSM-R|Radio network type<br>FRMCS+GSM-R|Radio network type<br>FRMCS+GSM-R|Radio network type<br>FRMCS+GSM-R||
||||||||||FRMCS+GSM-R|FRMCS+GSM-R|FRMCS+GSM-R|FRMCS+GSM-R|FRMCS+GSM-R|FRMCS+GSM-R|
||||||||||1 - FRMCS<br>2 - FRMCS+GSM-R<br>3 - GSM-R|1 - FRMCS<br>2 - FRMCS+GSM-R<br>3 - GSM-R|1 - FRMCS<br>2 - FRMCS+GSM-R<br>3 - GSM-R|1 - FRMCS<br>2 - FRMCS+GSM-R<br>3 - GSM-R|1 - FRMCS<br>2 - FRMCS+GSM-R<br>3 - GSM-R||
||||||||||1 - FRMCS<br>2 - FRMCS+GSM-R<br>3 - GSM-R|1 - FRMCS<br>2 - FRMCS+GSM-R<br>3 - GSM-R|1 - FRMCS<br>2 - FRMCS+GSM-R<br>3 - GSM-R|1 - FRMCS<br>2 - FRMCS+GSM-R<br>3 - GSM-R|1 - FRMCS<br>2 - FRMCS+GSM-R<br>3 - GSM-R||
||||||||||1 - FRMCS<br>2 - FRMCS+GSM-R<br>3 - GSM-R|1 - FRMCS<br>2 - FRMCS+GSM-R<br>3 - GSM-R|1 - FRMCS<br>2 - FRMCS+GSM-R<br>3 - GSM-R|1 - FRMCS<br>2 - FRMCS+GSM-R<br>3 - GSM-R|1 - FRMCS<br>2 - FRMCS+GSM-R<br>3 - GSM-R||
||||||||||||||||
||||||||||||||||
|**2**|||||||||||||||
||||||||||||||||
||||||||||||||||
||||||||||||||||
||||||||||||||||
||||||||||||||||
|1|2|3|3||||||||||||


**Figure 129b – Radio network type window**


**11.3.16** **Mission with one radio system window**


11.3.16.1 The Mission with one radio system window shall comply with the requirements in chapter

10.3 for a window on half grid array containing a single input field with only the data part.


11.3.16.2 The window title shall indicate “Mission with one radio system”.


11.3.16.3 The single input field shall be used for the entry of the choice of “Perform mission with

only one radio system”.


Version 4.0.0 PAGE 211 OF 317


**ERA ERTMS unit**

**ETCS Driver Machine Interface**


11.3.16.4 The keyboard associated to the Perform mission with only one radio system shall be a

dedicated keyboard being a ‘No’/‘Yes’ choice as specified in chapter 10.3.


11.3.16.5 Figure 129c shows the presentation of the Mission with one radio system window.








|Col1|150<br>100 200<br>0<br>50 300<br>0 400|Col3|Col4|Col5|Col6|Mission with one radio system<br>No<br>No Yes|Col8|
|---|---|---|---|---|---|---|---|
|||||||||
|||||||||
|**2**||||||No|Yes|
|||||||||
|||||||||
|||||||||
|||||||||
|||||||||


|Col1|150<br>100 200<br>0<br>50 300<br>0 400|Col3|Col4|Col5|Col6|Col7|Col8|Col9|Mission with one radio system<br>No|Col11|Col12|Col13|Col14|Col15|
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
||**0**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**0**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**0**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**0**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**0**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**0**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**0**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**0**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|No<br>Mission with one radio system|No<br>Mission with one radio system|No<br>Mission with one radio system|No<br>Mission with one radio system|No<br>Mission with one radio system||
||||||||||No|No|No|No|No|No|
||||||||||No|No|No|No|No||
||||||||||No|No|No|No|No||
||||||||||No|No|No|No|No||
||||||||||||||||
||||||||||||||||
|**2**|||||||||||||||
||||||||||||||||
||||||||||||||||
|||||||||||No|Yes||||



**Figure 129c –Mission with one radio system window**


**11.4** **Data validation windows**


**11.4.1** **Train data validation window**


Version 4.0.0 PAGE 212 OF 317


**ERA ERTMS unit**

**ETCS Driver Machine Interface**


11.4.1.1 The Train data validation window shall comply with the requirements in chapter 10.4.


11.4.1.2 The window title shall indicate “Validate train data”.


11.4.1.3 The echo texts shall echo data of the Train data window(s) (see 11.3.9).


11.4.1.4 Figure 130 shows the presentation of the Train data validation window with the data of the
2 input fields ‘length’ and ‘max speed’ modified by the driver and consequently shown in
white applying 10.3.3.5.





















|Validate train data<br>Yes<br>Train category PASS 1<br>Length (m) 200<br>Brake percentage 135<br>Max speed (km/h) 160<br>Axle load category A<br>Airtight no<br>Loading gauge Out of GC|Col2|Col3|Col4|Col5|Col6|Col7|Col8|Col9|Col10|Col11|
|---|---|---|---|---|---|---|---|---|---|---|
|Train category<br>Length (m)<br>Brake percentage<br>Max speed (km/h)<br>Axle load category<br>Airtight<br>Loading gauge<br>PASS 1<br>200<br>135<br>160<br>A<br>no<br>Out of GC<br>Validate train data<br>Yes|Train category<br>Length (m)<br>Brake percentage<br>Max speed (km/h)<br>Axle load category<br>Airtight<br>Loading gauge<br>PASS 1<br>200<br>135<br>160<br>A<br>no<br>Out of GC<br>Validate train data<br>Yes|Train category<br>Length (m)<br>Brake percentage<br>Max speed (km/h)<br>Axle load category<br>Airtight<br>Loading gauge<br>PASS 1<br>200<br>135<br>160<br>A<br>no<br>Out of GC<br>Validate train data<br>Yes|Train category<br>Length (m)<br>Brake percentage<br>Max speed (km/h)<br>Axle load category<br>Airtight<br>Loading gauge<br>PASS 1<br>200<br>135<br>160<br>A<br>no<br>Out of GC<br>Validate train data<br>Yes|Train category<br>Length (m)<br>Brake percentage<br>Max speed (km/h)<br>Axle load category<br>Airtight<br>Loading gauge<br>PASS 1<br>200<br>135<br>160<br>A<br>no<br>Out of GC<br>Validate train data<br>Yes|Train category<br>Length (m)<br>Brake percentage<br>Max speed (km/h)<br>Axle load category<br>Airtight<br>Loading gauge<br>PASS 1<br>200<br>135<br>160<br>A<br>no<br>Out of GC<br>Validate train data<br>Yes|Train category<br>Length (m)<br>Brake percentage<br>Max speed (km/h)<br>Axle load category<br>Airtight<br>Loading gauge<br>PASS 1<br>200<br>135<br>160<br>A<br>no<br>Out of GC<br>Validate train data<br>Yes|Train category<br>Length (m)<br>Brake percentage<br>Max speed (km/h)<br>Axle load category<br>Airtight<br>Loading gauge<br>PASS 1<br>200<br>135<br>160<br>A<br>no<br>Out of GC<br>Validate train data<br>Yes|Train category<br>Length (m)<br>Brake percentage<br>Max speed (km/h)<br>Axle load category<br>Airtight<br>Loading gauge<br>PASS 1<br>200<br>135<br>160<br>A<br>no<br>Out of GC<br>Validate train data<br>Yes|Train category<br>Length (m)<br>Brake percentage<br>Max speed (km/h)<br>Axle load category<br>Airtight<br>Loading gauge<br>PASS 1<br>200<br>135<br>160<br>A<br>no<br>Out of GC<br>Validate train data<br>Yes||
|Train category<br>Length (m)<br>Brake percentage<br>Max speed (km/h)<br>Axle load category<br>Airtight<br>Loading gauge<br>PASS 1<br>200<br>135<br>160<br>A<br>no<br>Out of GC<br>Validate train data<br>Yes|Train category<br>Length (m)<br>Brake percentage<br>Max speed (km/h)<br>Axle load category<br>Airtight<br>Loading gauge<br>PASS 1<br>200<br>135<br>160<br>A<br>no<br>Out of GC<br>Validate train data<br>Yes|Train category<br>Length (m)<br>Brake percentage<br>Max speed (km/h)<br>Axle load category<br>Airtight<br>Loading gauge<br>PASS 1<br>200<br>135<br>160<br>A<br>no<br>Out of GC<br>Validate train data<br>Yes|Train category<br>Length (m)<br>Brake percentage<br>Max speed (km/h)<br>Axle load category<br>Airtight<br>Loading gauge<br>PASS 1<br>200<br>135<br>160<br>A<br>no<br>Out of GC<br>Validate train data<br>Yes|Train category<br>Length (m)<br>Brake percentage<br>Max speed (km/h)<br>Axle load category<br>Airtight<br>Loading gauge<br>PASS 1<br>200<br>135<br>160<br>A<br>no<br>Out of GC<br>Validate train data<br>Yes|Train category<br>Length (m)<br>Brake percentage<br>Max speed (km/h)<br>Axle load category<br>Airtight<br>Loading gauge<br>PASS 1<br>200<br>135<br>160<br>A<br>no<br>Out of GC<br>Validate train data<br>Yes|Train category<br>Length (m)<br>Brake percentage<br>Max speed (km/h)<br>Axle load category<br>Airtight<br>Loading gauge<br>PASS 1<br>200<br>135<br>160<br>A<br>no<br>Out of GC<br>Validate train data<br>Yes|Train category<br>Length (m)<br>Brake percentage<br>Max speed (km/h)<br>Axle load category<br>Airtight<br>Loading gauge<br>PASS 1<br>200<br>135<br>160<br>A<br>no<br>Out of GC<br>Validate train data<br>Yes|Train category<br>Length (m)<br>Brake percentage<br>Max speed (km/h)<br>Axle load category<br>Airtight<br>Loading gauge<br>PASS 1<br>200<br>135<br>160<br>A<br>no<br>Out of GC<br>Validate train data<br>Yes|Train category<br>Length (m)<br>Brake percentage<br>Max speed (km/h)<br>Axle load category<br>Airtight<br>Loading gauge<br>PASS 1<br>200<br>135<br>160<br>A<br>no<br>Out of GC<br>Validate train data<br>Yes||
|Train category<br>Length (m)<br>Brake percentage<br>Max speed (km/h)<br>Axle load category<br>Airtight<br>Loading gauge<br>PASS 1<br>200<br>135<br>160<br>A<br>no<br>Out of GC<br>Validate train data<br>Yes|Train category<br>Length (m)<br>Brake percentage<br>Max speed (km/h)<br>Axle load category<br>Airtight<br>Loading gauge<br>PASS 1<br>200<br>135<br>160<br>A<br>no<br>Out of GC<br>Validate train data<br>Yes|Train category<br>Length (m)<br>Brake percentage<br>Max speed (km/h)<br>Axle load category<br>Airtight<br>Loading gauge<br>PASS 1<br>200<br>135<br>160<br>A<br>no<br>Out of GC<br>Validate train data<br>Yes|Train category<br>Length (m)<br>Brake percentage<br>Max speed (km/h)<br>Axle load category<br>Airtight<br>Loading gauge<br>PASS 1<br>200<br>135<br>160<br>A<br>no<br>Out of GC<br>Validate train data<br>Yes|Train category<br>Length (m)<br>Brake percentage<br>Max speed (km/h)<br>Axle load category<br>Airtight<br>Loading gauge<br>PASS 1<br>200<br>135<br>160<br>A<br>no<br>Out of GC<br>Validate train data<br>Yes|Train category<br>Length (m)<br>Brake percentage<br>Max speed (km/h)<br>Axle load category<br>Airtight<br>Loading gauge<br>PASS 1<br>200<br>135<br>160<br>A<br>no<br>Out of GC<br>Validate train data<br>Yes|Train category<br>Length (m)<br>Brake percentage<br>Max speed (km/h)<br>Axle load category<br>Airtight<br>Loading gauge<br>PASS 1<br>200<br>135<br>160<br>A<br>no<br>Out of GC<br>Validate train data<br>Yes|Train category<br>Length (m)<br>Brake percentage<br>Max speed (km/h)<br>Axle load category<br>Airtight<br>Loading gauge<br>PASS 1<br>200<br>135<br>160<br>A<br>no<br>Out of GC<br>Validate train data<br>Yes|Train category<br>Length (m)<br>Brake percentage<br>Max speed (km/h)<br>Axle load category<br>Airtight<br>Loading gauge<br>PASS 1<br>200<br>135<br>160<br>A<br>no<br>Out of GC<br>Validate train data<br>Yes|Train category<br>Length (m)<br>Brake percentage<br>Max speed (km/h)<br>Axle load category<br>Airtight<br>Loading gauge<br>PASS 1<br>200<br>135<br>160<br>A<br>no<br>Out of GC<br>Validate train data<br>Yes||
|Train category<br>Length (m)<br>Brake percentage<br>Max speed (km/h)<br>Axle load category<br>Airtight<br>Loading gauge<br>PASS 1<br>200<br>135<br>160<br>A<br>no<br>Out of GC<br>Validate train data<br>Yes|Train category<br>Length (m)<br>Brake percentage<br>Max speed (km/h)<br>Axle load category<br>Airtight<br>Loading gauge<br>PASS 1<br>200<br>135<br>160<br>A<br>no<br>Out of GC<br>Validate train data<br>Yes|Train category<br>Length (m)<br>Brake percentage<br>Max speed (km/h)<br>Axle load category<br>Airtight<br>Loading gauge<br>PASS 1<br>200<br>135<br>160<br>A<br>no<br>Out of GC<br>Validate train data<br>Yes|Train category<br>Length (m)<br>Brake percentage<br>Max speed (km/h)<br>Axle load category<br>Airtight<br>Loading gauge<br>PASS 1<br>200<br>135<br>160<br>A<br>no<br>Out of GC<br>Validate train data<br>Yes|Train category<br>Length (m)<br>Brake percentage<br>Max speed (km/h)<br>Axle load category<br>Airtight<br>Loading gauge<br>PASS 1<br>200<br>135<br>160<br>A<br>no<br>Out of GC<br>Validate train data<br>Yes|Train category<br>Length (m)<br>Brake percentage<br>Max speed (km/h)<br>Axle load category<br>Airtight<br>Loading gauge<br>PASS 1<br>200<br>135<br>160<br>A<br>no<br>Out of GC<br>Validate train data<br>Yes|Train category<br>Length (m)<br>Brake percentage<br>Max speed (km/h)<br>Axle load category<br>Airtight<br>Loading gauge<br>PASS 1<br>200<br>135<br>160<br>A<br>no<br>Out of GC<br>Validate train data<br>Yes|Train category<br>Length (m)<br>Brake percentage<br>Max speed (km/h)<br>Axle load category<br>Airtight<br>Loading gauge<br>PASS 1<br>200<br>135<br>160<br>A<br>no<br>Out of GC<br>Validate train data<br>Yes|Train category<br>Length (m)<br>Brake percentage<br>Max speed (km/h)<br>Axle load category<br>Airtight<br>Loading gauge<br>PASS 1<br>200<br>135<br>160<br>A<br>no<br>Out of GC<br>Validate train data<br>Yes|Train category<br>Length (m)<br>Brake percentage<br>Max speed (km/h)<br>Axle load category<br>Airtight<br>Loading gauge<br>PASS 1<br>200<br>135<br>160<br>A<br>no<br>Out of GC<br>Validate train data<br>Yes||
|Train category<br>Length (m)<br>Brake percentage<br>Max speed (km/h)<br>Axle load category<br>Airtight<br>Loading gauge<br>PASS 1<br>200<br>135<br>160<br>A<br>no<br>Out of GC<br>Validate train data<br>Yes|Train category<br>Length (m)<br>Brake percentage<br>Max speed (km/h)<br>Axle load category<br>Airtight<br>Loading gauge<br>PASS 1<br>200<br>135<br>160<br>A<br>no<br>Out of GC<br>Validate train data<br>Yes|Train category<br>Length (m)<br>Brake percentage<br>Max speed (km/h)<br>Axle load category<br>Airtight<br>Loading gauge<br>PASS 1<br>200<br>135<br>160<br>A<br>no<br>Out of GC<br>Validate train data<br>Yes|Train category<br>Length (m)<br>Brake percentage<br>Max speed (km/h)<br>Axle load category<br>Airtight<br>Loading gauge<br>PASS 1<br>200<br>135<br>160<br>A<br>no<br>Out of GC<br>Validate train data<br>Yes|Train category<br>Length (m)<br>Brake percentage<br>Max speed (km/h)<br>Axle load category<br>Airtight<br>Loading gauge<br>PASS 1<br>200<br>135<br>160<br>A<br>no<br>Out of GC<br>Validate train data<br>Yes|Train category<br>Length (m)<br>Brake percentage<br>Max speed (km/h)<br>Axle load category<br>Airtight<br>Loading gauge<br>PASS 1<br>200<br>135<br>160<br>A<br>no<br>Out of GC<br>Validate train data<br>Yes|Train category<br>Length (m)<br>Brake percentage<br>Max speed (km/h)<br>Axle load category<br>Airtight<br>Loading gauge<br>PASS 1<br>200<br>135<br>160<br>A<br>no<br>Out of GC<br>Validate train data<br>Yes|Train category<br>Length (m)<br>Brake percentage<br>Max speed (km/h)<br>Axle load category<br>Airtight<br>Loading gauge<br>PASS 1<br>200<br>135<br>160<br>A<br>no<br>Out of GC<br>Validate train data<br>Yes|Train category<br>Length (m)<br>Brake percentage<br>Max speed (km/h)<br>Axle load category<br>Airtight<br>Loading gauge<br>PASS 1<br>200<br>135<br>160<br>A<br>no<br>Out of GC<br>Validate train data<br>Yes|Train category<br>Length (m)<br>Brake percentage<br>Max speed (km/h)<br>Axle load category<br>Airtight<br>Loading gauge<br>PASS 1<br>200<br>135<br>160<br>A<br>no<br>Out of GC<br>Validate train data<br>Yes||
|Train category<br>Length (m)<br>Brake percentage<br>Max speed (km/h)<br>Axle load category<br>Airtight<br>Loading gauge<br>PASS 1<br>200<br>135<br>160<br>A<br>no<br>Out of GC<br>Validate train data<br>Yes|Train category<br>Length (m)<br>Brake percentage<br>Max speed (km/h)<br>Axle load category<br>Airtight<br>Loading gauge<br>PASS 1<br>200<br>135<br>160<br>A<br>no<br>Out of GC<br>Validate train data<br>Yes|Train category<br>Length (m)<br>Brake percentage<br>Max speed (km/h)<br>Axle load category<br>Airtight<br>Loading gauge<br>PASS 1<br>200<br>135<br>160<br>A<br>no<br>Out of GC<br>Validate train data<br>Yes|Train category<br>Length (m)<br>Brake percentage<br>Max speed (km/h)<br>Axle load category<br>Airtight<br>Loading gauge<br>PASS 1<br>200<br>135<br>160<br>A<br>no<br>Out of GC<br>Validate train data<br>Yes|Train category<br>Length (m)<br>Brake percentage<br>Max speed (km/h)<br>Axle load category<br>Airtight<br>Loading gauge<br>PASS 1<br>200<br>135<br>160<br>A<br>no<br>Out of GC<br>Validate train data<br>Yes|Train category<br>Length (m)<br>Brake percentage<br>Max speed (km/h)<br>Axle load category<br>Airtight<br>Loading gauge<br>PASS 1<br>200<br>135<br>160<br>A<br>no<br>Out of GC<br>Validate train data<br>Yes|Train category<br>Length (m)<br>Brake percentage<br>Max speed (km/h)<br>Axle load category<br>Airtight<br>Loading gauge<br>PASS 1<br>200<br>135<br>160<br>A<br>no<br>Out of GC<br>Validate train data<br>Yes|Train category<br>Length (m)<br>Brake percentage<br>Max speed (km/h)<br>Axle load category<br>Airtight<br>Loading gauge<br>PASS 1<br>200<br>135<br>160<br>A<br>no<br>Out of GC<br>Validate train data<br>Yes|Train category<br>Length (m)<br>Brake percentage<br>Max speed (km/h)<br>Axle load category<br>Airtight<br>Loading gauge<br>PASS 1<br>200<br>135<br>160<br>A<br>no<br>Out of GC<br>Validate train data<br>Yes|Train category<br>Length (m)<br>Brake percentage<br>Max speed (km/h)<br>Axle load category<br>Airtight<br>Loading gauge<br>PASS 1<br>200<br>135<br>160<br>A<br>no<br>Out of GC<br>Validate train data<br>Yes||
|||||||No|Yes||||
||||||||||||


**Figure 130 – Train data validation window**


Version 4.0.0 PAGE 213 OF 317


**ERA ERTMS unit**

**ETCS Driver Machine Interface**


**11.4.2** **Set VBC validation window**


11.4.2.1 The Set VBC validation window shall comply with the requirements in chapter 10.4.


11.4.2.2 The window title shall indicate “Validate set VBC”.


11.4.2.3 The echo text shall echo data of the Set VBC window (see 11.3.12).


11.4.2.4 Figure 131 shows the presentation of the Set VBC validation window


11.4.2.4.1 Note: the echo text is always shown in white applying 10.3.3.5 since the input field of the

Set VBC window is always entered by the driver.


Version 4.0.0 PAGE 214 OF 317


**ERA ERTMS unit**

**ETCS Driver Machine Interface**













|Validate set VBC<br>Yes<br>VBC code 321456|Col2|Col3|Col4|Col5|Col6|Col7|Col8|Col9|Col10|Col11|
|---|---|---|---|---|---|---|---|---|---|---|
|VBC code<br>Validate set VBC<br>Yes<br>321456|VBC code<br>Validate set VBC<br>Yes<br>321456|VBC code<br>Validate set VBC<br>Yes<br>321456|VBC code<br>Validate set VBC<br>Yes<br>321456|VBC code<br>Validate set VBC<br>Yes<br>321456|VBC code<br>Validate set VBC<br>Yes<br>321456|VBC code<br>Validate set VBC<br>Yes<br>321456|VBC code<br>Validate set VBC<br>Yes<br>321456|VBC code<br>Validate set VBC<br>Yes<br>321456|VBC code<br>Validate set VBC<br>Yes<br>321456||
|VBC code<br>Validate set VBC<br>Yes<br>321456|VBC code<br>Validate set VBC<br>Yes<br>321456|VBC code<br>Validate set VBC<br>Yes<br>321456|VBC code<br>Validate set VBC<br>Yes<br>321456|VBC code<br>Validate set VBC<br>Yes<br>321456|VBC code<br>Validate set VBC<br>Yes<br>321456|VBC code<br>Validate set VBC<br>Yes<br>321456|VBC code<br>Validate set VBC<br>Yes<br>321456|VBC code<br>Validate set VBC<br>Yes<br>321456|VBC code<br>Validate set VBC<br>Yes<br>321456||
|VBC code<br>Validate set VBC<br>Yes<br>321456|VBC code<br>Validate set VBC<br>Yes<br>321456|VBC code<br>Validate set VBC<br>Yes<br>321456|VBC code<br>Validate set VBC<br>Yes<br>321456|VBC code<br>Validate set VBC<br>Yes<br>321456|VBC code<br>Validate set VBC<br>Yes<br>321456|VBC code<br>Validate set VBC<br>Yes<br>321456|VBC code<br>Validate set VBC<br>Yes<br>321456|VBC code<br>Validate set VBC<br>Yes<br>321456|VBC code<br>Validate set VBC<br>Yes<br>321456||
|VBC code<br>Validate set VBC<br>Yes<br>321456|VBC code<br>Validate set VBC<br>Yes<br>321456|VBC code<br>Validate set VBC<br>Yes<br>321456|VBC code<br>Validate set VBC<br>Yes<br>321456|VBC code<br>Validate set VBC<br>Yes<br>321456|VBC code<br>Validate set VBC<br>Yes<br>321456|VBC code<br>Validate set VBC<br>Yes<br>321456|VBC code<br>Validate set VBC<br>Yes<br>321456|VBC code<br>Validate set VBC<br>Yes<br>321456|VBC code<br>Validate set VBC<br>Yes<br>321456||
|VBC code<br>Validate set VBC<br>Yes<br>321456|VBC code<br>Validate set VBC<br>Yes<br>321456|VBC code<br>Validate set VBC<br>Yes<br>321456|VBC code<br>Validate set VBC<br>Yes<br>321456|VBC code<br>Validate set VBC<br>Yes<br>321456|VBC code<br>Validate set VBC<br>Yes<br>321456|VBC code<br>Validate set VBC<br>Yes<br>321456|VBC code<br>Validate set VBC<br>Yes<br>321456|VBC code<br>Validate set VBC<br>Yes<br>321456|VBC code<br>Validate set VBC<br>Yes<br>321456||
|VBC code<br>Validate set VBC<br>Yes<br>321456|VBC code<br>Validate set VBC<br>Yes<br>321456|VBC code<br>Validate set VBC<br>Yes<br>321456|VBC code<br>Validate set VBC<br>Yes<br>321456|VBC code<br>Validate set VBC<br>Yes<br>321456|VBC code<br>Validate set VBC<br>Yes<br>321456|VBC code<br>Validate set VBC<br>Yes<br>321456|VBC code<br>Validate set VBC<br>Yes<br>321456|VBC code<br>Validate set VBC<br>Yes<br>321456|VBC code<br>Validate set VBC<br>Yes<br>321456||
|||||||No|Yes||||
||||||||||||


**Figure 131 – Set VBC validation window**


**11.4.3** **Remove VBC validation window**


11.4.3.1 The Remove VBC validation window shall comply with the requirements in chapter 10.4.


11.4.3.2 The window title shall indicate “Validate remove VBC”.


11.4.3.3 The echo text shall echo data of the Remove VBC window (see 11.3.13).


11.4.3.4 Figure 132 shows the presentation of the Remove VBC validation window


Version 4.0.0 PAGE 215 OF 317


**ERA ERTMS unit**

**ETCS Driver Machine Interface**


11.4.3.4.1 Note: the echo text is always shown in white applying 10.3.3.5 since the input field of the

Remove VBC window is always entered by the driver.



|Validate remove VBC<br>Yes<br>VBC code 50078|Col2|Col3|Col4|Col5|Col6|Col7|Col8|Col9|Col10|Col11|
|---|---|---|---|---|---|---|---|---|---|---|
|VBC code 50078<br>Validate remove VBC<br>Yes|VBC code 50078<br>Validate remove VBC<br>Yes|VBC code 50078<br>Validate remove VBC<br>Yes|VBC code 50078<br>Validate remove VBC<br>Yes|VBC code 50078<br>Validate remove VBC<br>Yes|VBC code 50078<br>Validate remove VBC<br>Yes|VBC code 50078<br>Validate remove VBC<br>Yes|VBC code 50078<br>Validate remove VBC<br>Yes|VBC code 50078<br>Validate remove VBC<br>Yes|VBC code 50078<br>Validate remove VBC<br>Yes||
|VBC code 50078<br>Validate remove VBC<br>Yes|VBC code 50078<br>Validate remove VBC<br>Yes|VBC code 50078<br>Validate remove VBC<br>Yes|VBC code 50078<br>Validate remove VBC<br>Yes|VBC code 50078<br>Validate remove VBC<br>Yes|VBC code 50078<br>Validate remove VBC<br>Yes|VBC code 50078<br>Validate remove VBC<br>Yes|VBC code 50078<br>Validate remove VBC<br>Yes|VBC code 50078<br>Validate remove VBC<br>Yes|VBC code 50078<br>Validate remove VBC<br>Yes||
|VBC code 50078<br>Validate remove VBC<br>Yes|VBC code 50078<br>Validate remove VBC<br>Yes|VBC code 50078<br>Validate remove VBC<br>Yes|VBC code 50078<br>Validate remove VBC<br>Yes|VBC code 50078<br>Validate remove VBC<br>Yes|VBC code 50078<br>Validate remove VBC<br>Yes|VBC code 50078<br>Validate remove VBC<br>Yes|VBC code 50078<br>Validate remove VBC<br>Yes|VBC code 50078<br>Validate remove VBC<br>Yes|VBC code 50078<br>Validate remove VBC<br>Yes||
|VBC code 50078<br>Validate remove VBC<br>Yes|VBC code 50078<br>Validate remove VBC<br>Yes|VBC code 50078<br>Validate remove VBC<br>Yes|VBC code 50078<br>Validate remove VBC<br>Yes|VBC code 50078<br>Validate remove VBC<br>Yes|VBC code 50078<br>Validate remove VBC<br>Yes|VBC code 50078<br>Validate remove VBC<br>Yes|VBC code 50078<br>Validate remove VBC<br>Yes|VBC code 50078<br>Validate remove VBC<br>Yes|VBC code 50078<br>Validate remove VBC<br>Yes||
|VBC code 50078<br>Validate remove VBC<br>Yes|VBC code 50078<br>Validate remove VBC<br>Yes|VBC code 50078<br>Validate remove VBC<br>Yes|VBC code 50078<br>Validate remove VBC<br>Yes|VBC code 50078<br>Validate remove VBC<br>Yes|VBC code 50078<br>Validate remove VBC<br>Yes|VBC code 50078<br>Validate remove VBC<br>Yes|VBC code 50078<br>Validate remove VBC<br>Yes|VBC code 50078<br>Validate remove VBC<br>Yes|VBC code 50078<br>Validate remove VBC<br>Yes||
|VBC code 50078<br>Validate remove VBC<br>Yes|VBC code 50078<br>Validate remove VBC<br>Yes|VBC code 50078<br>Validate remove VBC<br>Yes|VBC code 50078<br>Validate remove VBC<br>Yes|VBC code 50078<br>Validate remove VBC<br>Yes|VBC code 50078<br>Validate remove VBC<br>Yes|VBC code 50078<br>Validate remove VBC<br>Yes|VBC code 50078<br>Validate remove VBC<br>Yes|VBC code 50078<br>Validate remove VBC<br>Yes|VBC code 50078<br>Validate remove VBC<br>Yes||
|||||||No|Yes||||
||||||||||||


**Figure 132 – Remove VBC validation window**


**11.5** **Data view windows**


**11.5.1** **Data view window**


11.5.1.1 The Data view windows shall comply with the requirements in chapter 10.5.


Version 4.0.0 PAGE 216 OF 317


**ERA ERTMS unit**

**ETCS Driver Machine Interface**


11.5.1.2 The window titles shall indicate “Data view”.


11.5.1.3 The window titles shall also comply with 5.3.1.2.1g) for the indication of the sequence
number of the windows and the total number of windows related to the Data view.


11.5.1.4 The data view items shall be as specified in Table 44 for fixed train data entry and as
specified in Table 45 for flexible train data entry.


11.5.1.5 For the topic “Train data”, only data view items corresponding to the Train Data either
modifiable by the driver or modifiable by other ERTMS/ETCS external sources shall be
displayed.


11.5.1.5.1 Note: a Train Data is considered as modifiable if it can be impacted by a change of value

of the train type (fixed train data entry) or of its individual input field (flexible train data
entry)


11.5.1.6 For the topic “VBCs stored on-board”, the number of data view items is not mentioned
since it can vary depending on the number of VBCs stored on-board.


11.5.1.6.1 For the topic “Radio data info”, the data view item “RBC phone number” shall be displayed

only if the Radio Network type stored on-board is GSM-R or FRMCS+GSM-R while GSMR is installed on-board.







|Topic|Window #|Data view item<br>#|Label|
|---|---|---|---|
|Driver ID|1|1|Driver ID|
|Train running number|1|2|Train running number|
|Train data|1|3|Train type|
|Train data<br> <br> <br> <br> <br> <br>|1 <br> <br> <br> <br> <br> <br>|4|Train category|
|Train data<br> <br> <br> <br> <br> <br>|1 <br> <br> <br> <br> <br> <br>|5|Length (m)|
|Train data<br> <br> <br> <br> <br> <br>|1 <br> <br> <br> <br> <br> <br>|6|Brake percentage|
|Train data<br> <br> <br> <br> <br> <br>|1 <br> <br> <br> <br> <br> <br>|7|Maximum speed (km/h)|
|Train data<br> <br> <br> <br> <br> <br>|1 <br> <br> <br> <br> <br> <br>|8|Axle load category|
|Train data<br> <br> <br> <br> <br> <br>|1 <br> <br> <br> <br> <br> <br>|9|Airtight|
|Train data<br> <br> <br> <br> <br> <br>|1 <br> <br> <br> <br> <br> <br>|10|Loading gauge|
|Radio data info<br> <br> <br>|2 <br> <br> <br>|11|Radio network type|
|Radio data info<br> <br> <br>|2 <br> <br> <br>|12|GSM-R network ID|
|Radio data info<br> <br> <br>|2 <br> <br> <br>|13|RBC ID|
|Radio data info<br> <br> <br>|2 <br> <br> <br>|14|RBC phone number|
|VBCs stored on-board<br> <br>|2..n<br> <br>|15|VBC #1 set code|
|VBCs stored on-board<br> <br>|2..n<br> <br>|16|VBC #2 set code|
|VBCs stored on-board<br> <br>|2..n<br> <br>|...|...|


**Table 44 – Data view items for fixed train data entry**


Version 4.0.0 PAGE 217 OF 317


**ERA ERTMS unit**

**ETCS Driver Machine Interface**







|Topic|Window #|Data view item<br>#|Label|
|---|---|---|---|
|Driver ID|1|1|Driver ID|
|Train running number|1|2|Train running number|
|Train data<br> <br> <br> <br> <br> <br>|1 <br> <br> <br> <br> <br> <br>|4|Train category|
|Train data<br> <br> <br> <br> <br> <br>|1 <br> <br> <br> <br> <br> <br>|5|Length (m)|
|Train data<br> <br> <br> <br> <br> <br>|1 <br> <br> <br> <br> <br> <br>|6|Brake percentage|
|Train data<br> <br> <br> <br> <br> <br>|1 <br> <br> <br> <br> <br> <br>|7|Maximum speed (km/h)|
|Train data<br> <br> <br> <br> <br> <br>|1 <br> <br> <br> <br> <br> <br>|8|Axle load category|
|Train data<br> <br> <br> <br> <br> <br>|1 <br> <br> <br> <br> <br> <br>|9|Airtight|
|Train data<br> <br> <br> <br> <br> <br>|1 <br> <br> <br> <br> <br> <br>|10|Loading gauge|
|Radio data info<br> <br> <br>|2 <br> <br> <br>|11|Radio network type|
|Radio data info<br> <br> <br>|2 <br> <br> <br>|12|GSM-R network ID|
|Radio data info<br> <br> <br>|2 <br> <br> <br>|13|RBC ID|
|Radio data info<br> <br> <br>|2 <br> <br> <br>|14|RBC phone number|
|VBCs stored on-board<br> <br>|2..n<br> <br>|15|VBC #1 set code|
|VBCs stored on-board<br> <br>|2..n<br> <br>|16|VBC #2 set code|
|VBCs stored on-board<br> <br>|2..n<br> <br>|...|...|


**Table 45 – Data view items for flexible train data entry**


11.5.1.7 Figure 133 and Figure 134 show the presentation of 2 Data view windows.


Version 4.0.0 PAGE 218 OF 317


**ERA ERTMS unit**

**ETCS Driver Machine Interface**


|Col1|Col2|Col3|150<br>100 200<br>0<br>50 300<br>0 400|Col5|Col6|Col7|Col8|Data view (1/2)<br>Driver ID 1234<br>Train running number 5678<br>Train category PAS<br>Length (m) 200<br>Brake percentage 135<br>Max speed (km/h) 160<br>Axle load category A<br>Airtight no<br>Loading gauge Out|Col10|Col11|
|---|---|---|---|---|---|---|---|---|---|---|
|60|60|60|60|60|60|60|60|60|60|60|
||||||||||||
|**2**|**2**|**2**|**2**||||||||
||||||||||||
||||||||||||
||||||||||||
||||||||||||
||||||||||||
||||||||||||
















|Col1|Col2|Col3|150<br>100 200<br>0<br>50 300<br>0 400|Col5|Col6|Col7|Col8|Col9|Col10|Col11|Data view (1/2)<br>Driver ID 1234<br>Train running number 5678<br>Train category PASS 1<br>Length (m) 200<br>Brake percentage 135<br>Max speed (km/h) 160<br>Axle load category A<br>Airtight no<br>Loading gauge Out of GC|Col13|Col14|Col15|Col16|Col17|
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
||||**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**<br>**0**|**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**<br>**0**|**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**<br>**0**|**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**<br>**0**|**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**<br>**0**|**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**<br>**0**|**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**<br>**0**|**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**<br>**0**|Data view (1/2)<br>Driver ID<br>Train running number<br>Train category<br>Length (m)<br>Brake percentage<br>Max speed (km/h)<br>Axle load category<br>Airtight<br>Loading gauge<br>1234<br>5678<br>PASS 1<br>200<br>135<br>160<br>A<br>no<br>Out of GC|Data view (1/2)<br>Driver ID<br>Train running number<br>Train category<br>Length (m)<br>Brake percentage<br>Max speed (km/h)<br>Axle load category<br>Airtight<br>Loading gauge<br>1234<br>5678<br>PASS 1<br>200<br>135<br>160<br>A<br>no<br>Out of GC|Data view (1/2)<br>Driver ID<br>Train running number<br>Train category<br>Length (m)<br>Brake percentage<br>Max speed (km/h)<br>Axle load category<br>Airtight<br>Loading gauge<br>1234<br>5678<br>PASS 1<br>200<br>135<br>160<br>A<br>no<br>Out of GC|Data view (1/2)<br>Driver ID<br>Train running number<br>Train category<br>Length (m)<br>Brake percentage<br>Max speed (km/h)<br>Axle load category<br>Airtight<br>Loading gauge<br>1234<br>5678<br>PASS 1<br>200<br>135<br>160<br>A<br>no<br>Out of GC|Data view (1/2)<br>Driver ID<br>Train running number<br>Train category<br>Length (m)<br>Brake percentage<br>Max speed (km/h)<br>Axle load category<br>Airtight<br>Loading gauge<br>1234<br>5678<br>PASS 1<br>200<br>135<br>160<br>A<br>no<br>Out of GC||
|60|60|60|60|60|60|60|60|60|60|60|60|60|60|60|60|60|
|60|60|60|60|60|60|60|60|60|60|60|60|60|60|60|60||
|60|60|60|60|60|60|60|60|60|60|60|60|60|60|60|60||
|60|60|60|60|60|60|60|60|60|60|60|60|60|60|60|60||
|60|60|60|||||||||||||||
||||||||||||||||||
|**2**|**2**|**2**|||||||||||||||
||||||||||||||||||
||||||||||||||||||
||||||||||||||||||
||||||||||||||||||
||||||||||||||||||
||||||||||||||||||
||||||||||||||||||



**Figure 133 – Data view window (1** **[st]** **window)**


Version 4.0.0 PAGE 219 OF 317


**ERA ERTMS unit**

**ETCS Driver Machine Interface**


|Col1|Col2|Col3|150<br>100 200<br>0<br>50 300<br>0 400|Col5|Col6|Col7|Col8|Data view (2/2)<br>Radio network type FRM<br>GSM<br>GSM-R network ID GSM<br>RBC ID 1234<br>RBC phone number 1234<br>9012<br>VBC #1 set code 7195<br>VBC #2 set code 3214|Col10|Col11|
|---|---|---|---|---|---|---|---|---|---|---|
|60|60|60|60|60|60|60|60|60|60|60|
|**2**|**2**|**2**|**2**||||||||
||||||||||||
||||||||||||
||||||||||||
||||||||||||
||||||||||||
||||||||||||
















|Col1|Col2|Col3|150<br>100 200<br>0<br>50 300<br>0 400|Col5|Col6|Col7|Col8|Col9|Col10|Col11|Data view (2/2)<br>Radio network type FRMCS+<br>GSM-R<br>GSM-R network ID GSMR-A<br>RBC ID 1234 5678<br>RBC phone number 1234 5678<br>0912 3456<br>VBC #1 set code 71951<br>VBC #2 set code 321456|Col13|Col14|Col15|Col16|Col17|
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
||||**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**<br>**0**|**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**<br>**0**|**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**<br>**0**|**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**<br>**0**|**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**<br>**0**|**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**<br>**0**|**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**<br>**0**|**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**<br>**0**|Data view (2/2)<br>Radio network type<br>GSM-R network ID<br>RBC ID<br>RBC phone number<br>VBC #1 set code<br>VBC #2 set code<br>FRMCS+<br>GSM-R<br>GSMR-A<br>1234 5678<br>1234 5678<br>0912 3456<br>71951<br>321456|Data view (2/2)<br>Radio network type<br>GSM-R network ID<br>RBC ID<br>RBC phone number<br>VBC #1 set code<br>VBC #2 set code<br>FRMCS+<br>GSM-R<br>GSMR-A<br>1234 5678<br>1234 5678<br>0912 3456<br>71951<br>321456|Data view (2/2)<br>Radio network type<br>GSM-R network ID<br>RBC ID<br>RBC phone number<br>VBC #1 set code<br>VBC #2 set code<br>FRMCS+<br>GSM-R<br>GSMR-A<br>1234 5678<br>1234 5678<br>0912 3456<br>71951<br>321456|Data view (2/2)<br>Radio network type<br>GSM-R network ID<br>RBC ID<br>RBC phone number<br>VBC #1 set code<br>VBC #2 set code<br>FRMCS+<br>GSM-R<br>GSMR-A<br>1234 5678<br>1234 5678<br>0912 3456<br>71951<br>321456|Data view (2/2)<br>Radio network type<br>GSM-R network ID<br>RBC ID<br>RBC phone number<br>VBC #1 set code<br>VBC #2 set code<br>FRMCS+<br>GSM-R<br>GSMR-A<br>1234 5678<br>1234 5678<br>0912 3456<br>71951<br>321456||
|60|60|60|60|60|60|60|60|60|60|60|60|60|60|60|60|60|
|60|60|60|60|60|60|60|60|60|60|60|60|60|60|60|60||
|60|60|60|60|60|60|60|60|60|60|60|60|60|60|60|60||
|60|60|60|60|60|60|60|60|60|60|60|60|60|60|60|60||
|60|60|60|||||||||||||||
||||||||||||||||||
|**2**|**2**|**2**|||||||||||||||
||||||||||||||||||
||||||||||||||||||
||||||||||||||||||
||||||||||||||||||
||||||||||||||||||
||||||||||||||||||
||||||||||||||||||



**Figure 134 – Data view window (2** **[nd]** **window)**


Version 4.0.0 PAGE 220 OF 317


**ERA ERTMS unit**

**ETCS Driver Machine Interface**


**11.5.2** **System version window**


11.5.2.1 The System version window shall comply with the requirements in chapter 10.5.


11.5.2.2 The window title shall indicate “System version”.


11.5.2.3 The data view item shall be as specified in Table 46.

|Topic|data view text #|data|
|---|---|---|
|System version|1|Operated system version|



**Table 46 – Data view items**


11.5.2.4 Figure 135 shows the presentation of the System version window.


Version 4.0.0 PAGE 221 OF 317


**ERA ERTMS unit**

**ETCS Driver Machine Interface**


|Col1|Col2|Col3|150<br>100 200<br>0<br>50 300<br>0 400|Col5|Col6|Col7|Col8|System ve<br>Operated|
|---|---|---|---|---|---|---|---|---|
||||||||||
||||||||||
|**2**|**2**|**2**|**2**||||||
||||||||||
||||||||||
||||||||||
||||||||||
||||||||||
||||||||||






|Col1|Col2|Col3|150<br>100 200<br>0<br>50 300<br>0 400|Col5|Col6|Col7|Col8|Col9|Col10|Col11|System version<br>Operated system 3.0<br>version|Col13|Col14|Col15|Col16|Col17|
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
||||**0**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**0**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**0**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**0**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**0**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**0**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**0**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**0**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|System version<br>Operated system<br>version<br>3.0|System version<br>Operated system<br>version<br>3.0|System version<br>Operated system<br>version<br>3.0|System version<br>Operated system<br>version<br>3.0|System version<br>Operated system<br>version<br>3.0||
||||||||||||||||||
||||||||||||||||||
||||||||||||||||||
||||||||||||||||||
||||||||||||||||||
||||||||||||||||||
|**2**|**2**|**2**|||||||||||||||
||||||||||||||||||
||||||||||||||||||
||||||||||||||||||
||||||||||||||||||
||||||||||||||||||
||||||||||||||||||
||||||||||||||||||



**Figure 135 – System version window**


**11.6** **Parent/child relationship**


11.6.1.1 With regards to the use of the close button, the relationship between parent and child
windows shall be as specified in Table 47.


11.6.1.1.1 Note: The cell for “Additional DMI technical functions” is marked in grey since these

functions are outside of the scope of this specification.


Version 4.0.0 PAGE 222 OF 317


**ERA ERTMS unit**

**ETCS Driver Machine Interface**


11.6.1.2 During the start up dialogue sequence (see 11.7.2 steps S1, S1-1 and S1-2), the Driver
ID window shall be the parent of the Settings and the Train running number windows.


11.6.1.3 During the start up dialogue sequence (see 11.7.2), the Mission with one radio system
window can also be accessed via the step D9.


Version 4.0.0 PAGE 223 OF 317


**ERA ERTMS unit**

**ETCS Driver Machine Interface**



























|Parent/child relationship<br>(from left to right = from parent to child)|Col2|Col3|Col4|
|---|---|---|---|
|Default|Main|Driver ID|-|
|Default|Main|Train data<br>_(one or more windows)_|-|
|Default|Main|Train data validation<br>_(accessible via Train_<br>_data windows)_|-|
|Default|Main|Level|-|
|Default|Main|Radio data|Radio network type<br>_(accessible via the_<br>_Radio data window and_<br>_only if driver selects_<br>_“Radio network type”)_|
|Default|Main|Radio data|GSM-R network ID<br>_(accessible via the_<br>_Radio data window and_<br>_only if driver selects_<br>_“GSM-R network ID”)_|
|Default|Main|Radio data|RBC data<br>_(accessible via the_<br>_Radio data window and_<br>_only if driver selects_<br>_“Enter RBC data”)_|
|Default|Main|Radio data|Mission with one radio<br>system<br>_(accessible via the_<br>_Radio data window and_<br>_only if driver selects_<br>_“Mission with one radio_<br>_system”)_|
|Default|Main|Train running number|-|
|Default|Override|-|-|
|Default|Data<br>View|-|-|
|Default|Special|Adhesion|-|
|Default|Special|SR speed / distance|-|
|Default|Settings|Language|-|
|Default|Settings|Volume|-|
|Default|Settings|Brightness|-|
|Default|Settings|System version|-|
|Default|Settings|Set VBC|-|
|Default|Settings|Set VBC validation|-|
|Default|Settings|Remove VBC|-|
|Default|Settings|Remove VBC validation|-|
|Default|Settings|ATO selector|-|


Version 4.0.0 PAGE 224 OF 317


**ERA ERTMS unit**

**ETCS Driver Machine Interface**







**Table 47 – Parent/child relationship**



Version 4.0.0 PAGE 225 OF 317


**ERA ERTMS unit**

**ETCS Driver Machine Interface**


**11.7** **Dialogue sequences**


**11.7.1** **Introduction**


11.7.1.1 In a dialogue sequence, the latest active window including the mentioned configuration of
objects/symbols (e.g. the main window with all buttons disabled and the hour glass symbol
ST05 displayed) shall remain displayed until another window or another configuration of
the same window is mentioned further on in the flowchart.


11.7.1.2 When an event involves a driver’s action on a button, it assumes that the corresponding
button is enabled (see 11.1 for the conditions enabling a button).


11.7.1.3 The status of data mentioned in the dialogue sequences refers to the status of data stored
onboard as defined in document [2].


11.7.1.4 If the status is “invalid” or “valid”, the value stored onboard shall be presented to the driver
when entering the corresponding data entry window.


11.7.1.4.1 Exception: for the train data windows; see S3-1 of the main dialogue sequence. For the

train data validation window; see S3-2 of the main dialogue sequence.


11.7.1.5 For a window covering the half grid array, the value stored onboard shall be replaced by
the data value of the input field when the driver accepts this data value.


11.7.1.6 For a window covering the total grid array, the values stored onboard shall be replaced by
the data values of the input fields when the driver presses the ‘Yes’ button.


11.7.1.6.1 Exception: for the train data windows, the values stored onboard shall be replaced by the

values of the input fields for train data only when the train data validation window is left
with the value of its input field set to ‘Yes’. It means that no action is done on the train data
stored onboard when the driver presses the ‘Yes’ button of the train data windows (see
S3-2 of the main window dialogue sequence).


11.7.1.6.2 Exception: for the Set VBC or Remove VBC window, the action on the VBCs stored

onboard shall be performed respectively with the value of the input field ‘VBC set code’ or
of the input field ‘VBC remove code’ only when the corresponding validation window is left
with the value of its input field set to ‘Yes’. It means that no action is done on the VBCs
stored onboard when the driver presses the ‘Yes’ button of the Set VBC or Remove VBC
window (see S6-2 and S7-2 of the settings dialogue sequence).


11.7.1.7 After the Start Up dialogue sequence (see 11.7.2), if one of the windows mentioned in
Table 48 is currently displayed and any of the enabling conditions (see 11.2) of the
corresponding button is not fulfilled anymore, the data entry / validation process shall be
stopped and the parent window shall be displayed instead.

|Window|Corresponding button for<br>checking the enabling conditions|
|---|---|
|Train running number|Train running number|
|Driver ID|Driver ID|
|ERTMS/ETCS level|Level|



Version 4.0.0 PAGE 226 OF 317


**ERA ERTMS unit**

**ETCS Driver Machine Interface**







|Window|Corresponding button for<br>checking the enabling conditions|
|---|---|
|Radio network type|Radio network type|
|GSM-R network ID|GSM-R network ID|
|Mission with one radio<br>system|Mission with one radio system|
|RBC data|Enter RBC data|
|Language|Language|
|Volume|Volume|
|Brightness|Brightness|
|ATO selector|ATO|
|Train data|Train data|
|Train data validation|Train data|
|SR speed / distance|SR speed / distance|
|Adhesion|Adhesion|


**Table 48 – Relationship between windows and enabling conditions of buttons**


11.7.1.8 During the Start Up dialogue sequence, if a driver’s acknowledgement is required, it shall
be displayed 1 second after the end of the Start Up dialogue sequence.


11.7.1.9 After the Start Up dialogue sequence, if a data entry or validation window is currently
displayed when a driver’s acknowledgement is required, the data entry / validation
process shall be stopped, the parent window shall be displayed instead and the driver’s
acknowledgement shall appear 1 second afterwards.


**11.7.2** **Start Up**


11.7.2.1 The “Start Up” dialogue sequence shall guide the driver when a start of mission is initiated
as specified in [2] chapter 5.4.


11.7.2.1.1 Note: When possible, the steps refer to the numbering in the SRS (see document [2]) to

facilitate the traceability.


11.7.2.2 The [close] button shall be disabled in all windows presented before reaching S10 except
in the steps S1-1, S1-2, S3-2-2, S3-3 and S3-4.


11.7.2.2.1 Note: In S10, the driver can therefore close the start up dialogue sequence to go to

another sub-level window e.g. to go to the Override window and press the EOA button (if
enabled).


11.7.2.3 Note: Some of steps of the start of mission procedure (see SRS 5.4) are kept for the sake
of understanding. These steps are marked in the figure with a specific background (see
D32 to A40-1) and in the following table by italic texts in the grey rows.


Version 4.0.0 PAGE 227 OF 317


**ERA ERTMS unit**

**ETCS Driver Machine Interface**














































































































|Col1|Col2|
|---|---|
|||
|||























































**Figure 136 – Start Up dialogue sequence**


Version 4.0.0 PAGE 228 OF 317


**ERA ERTMS unit**

**ETCS Driver Machine Interface**


11.7.2.4 The steps of the **“** Start Up **”** dialogue sequence shall follow Table 49.










|ID in Flow<br>Chart|Requirements|Window|
|---|---|---|
|**S0**|If the cab is active and the mode is SB but a communication session is still<br>established or is being established:<br>• <br>The**Main window** shall be presented to the driver with all buttons ‘disabled’.<br>• <br>The symbol**ST05** shall be displayed to show that the onboard awaits that no<br>communication session is established.<br>When all conditions to initiate a start of mission are fulfilled, the procedure shall go<br>to**S1** and the Start Up dialogue sequence shall be engaged.|Figure 109 – Main window|
|**S1**|The**Driver ID window** shall request the driver to enter the Driver ID (if the status<br>of the Driver ID is “unknown”) or shall request the driver to revalidate or re-enter<br>the Driver ID (if the status of Driver ID is “invalid”).<br>Once the Driver ID is entered or revalidated**(E1)**, the procedure shall go to**D2**<br>• <br>If the driver presses the settings button, the procedure shall go to**S1-1** <br>• <br>If the driver presses the train running number button, the procedure shall go to<br>**S1-2**|Figure 116 – Driver ID window|
|**S1-1**|The **Settings window** shall be presented to the driver. (See 11.7.7 for the settings<br>dialogue sequence)<br>Once the driver closes the settings window**(E1-1)**, the procedure shall go back to<br>**S1**|Figure 112 – Settings window|
|**S1-2**|The**Train running number window** shall request the driver to enter the Train<br>running number (if the status of the Train running number is “unknown”) or shall<br>request the driver to revalidate or re-enter the Train running number (if the status<br>of Train running number is “invalid” or “valid”).<br>Once the train running number is entered or revalidated**(E1-2)**, the procedure shall<br>go back to**S1**|Figure 114 – Train running number window|



Version 4.0.0 PAGE 229 OF 317


**ERA ERTMS unit**

**ETCS Driver Machine Interface**



|ID in Flow<br>Chart|Requirements|Window|
|---|---|---|
|**D2**|If both the stored position and the stored level are valid, the procedure shall go to<br>**D3** <br>If the stored position or the stored level is invalid or unknown, the procedure shall<br>go to**S2**||
|**D3**|If the stored level is 2, the procedure shall go to**D7** <br>If the stored level is 0, 1 or NTC, the procedure shall go to**S10**||
|**D7**|Depending on the stored Radio Network type, on the radio systems(s) installed on-<br>board and if one of the following conditions is fulfilled:<br>• <br>The Radio Network type is FRMCS or is FRMCS+GSM-R while FRMCS<br>is the only radio system installed on-board, and the FRMCS on-board<br>is registered to the FRMCS Radio Network, OR<br>• <br>The Radio Network type is FRMCS+GSM-R while both radio systems<br>are installed on-board, and both the FRMCS on-board is registered to<br>the FRMCS Radio Network and at least one GSM-R Mobile Terminal is<br>registered to a GSM-R Radio Network, OR<br>• <br>The Radio Network type is GSM-R or is FRMCS+GSM-R while GSM-R<br>is the only radio system installed on-board, and at least one Mobile<br>Terminal is registered to a GSM-R Radio Network<br>The process shall go to**A31**<br>Otherwise, it shall go to**S4**||


Version 4.0.0 PAGE 230 OF 317


**ERA ERTMS unit**

**ETCS Driver Machine Interface**






|ID in Flow<br>Chart|Requirements|Window|
|---|---|---|
|**S2**|The**ERTMS/ETCS level window** shall request the driver to enter the Level data<br>(if the status of the Level data is “unknown”) or shall request the driver to revalidate<br>or re-enter the Level data (if the status of Level data is “invalid”).<br>If the entered / re-validated level is 2, the procedure shall go to**S3-1** <br>If the entered / re-validated level is 0 or 1 or one of proposed NTC level(s), the<br>procedure shall go to**S10**|Figure 115 – ERTMS/ETCS level window|
|**S3-1**|The**Radio data window** shall offer the possibility to the driver to select ‘Contact<br>last RBC’, ‘Use short number’, ‘Enter RBC data’, 'Radio network type', ‘GSM-R<br>network ID’ and ‘Mission with one radio system’<br>• <br>If the driver presses ‘Contact last RBC’ or ‘Use short number’, the procedure<br>shall go to**A31**. <br>• <br>If the driver presses ‘Enter RBC data’, the procedure shall go to**S3-3**. <br>• <br>If the driver presses ‘Radio network type’, the procedure shall go to**S3-4**. <br>• <br>If the driver presses ‘GSM-R network ID’, the procedure shall go to**S3-2-1**. <br>• <br>If the driver presses ‘Mission with one radio system’, the procedure shall go to<br>**A43**.|Figure 113 – Radio data window|
|**S3-2-1**|The **Radio data window** shall be presented to the driver with all buttons ‘disabled’.<br>The symbol**ST05** shall be displayed to show that the onboard awaits the<br>alphanumeric list of available and allowed GSM-R Networks.<br>If this list is not empty, the procedure shall go to**S3-2-2.**<br>If this list is empty, the procedure shall go to**A29**.|Figure 113 – Radio data window|
|**S3-2-2**|The**GSM-R network ID window** shall request the driver to re-enter the GSM-R<br>network ID<br>Once the GSM-R network ID is entered, the procedure shall go to**S3-2-3**|Figure 117 – GSM-R network ID window|



Version 4.0.0 PAGE 231 OF 317


**ERA ERTMS unit**

**ETCS Driver Machine Interface**






|ID in Flow<br>Chart|Requirements|Window|
|---|---|---|
|**S3-2-3**|The **Radio data window** shall be presented to the driver with all buttons ‘disabled’.<br>The symbol**ST05** shall be displayed to show that the onboard awaits the<br>registration to the GSM-R Network.<br>When at least one Mobile Terminal is registered to the GSM-R Network, the<br>procedure shall go to**S3-1**|Figure 113 – Radio data window|



Version 4.0.0 PAGE 232 OF 317


**ERA ERTMS unit**

**ETCS Driver Machine Interface**






|ID in Flow<br>Chart|Requirements|Window|
|---|---|---|
|**S4**|The**Main window** shall be presented to the driver with all buttons ‘disabled’.<br>The symbol**ST05** shall be displayed to show that the onboard still awaits the<br>registration to the Radio Network(s).<br>The procedure shall go to**A31** if the stored Radio Network type is:<br>a) FRMCS or FRMCS+GSM-R while FRMCS is the only radio system<br>installed on-board, and the FRMCS on-board is registered to the FRMCS<br>Radio Network, OR<br>b) FRMCS+GSM-R while both radio systems are installed on-board, and both<br>the FRMCS on-board is registered to the FRMCS Radio Network and at<br>least one GSM-R Mobile Terminal is registered to a GSM-R Radio Network,<br>OR<br>c) GSM-R or FRMCS+GSM-R while GSM-R is the only radio system installed<br>on-board, and at least one GSM-R Mobile Terminal is registered to a GSM-<br>R Radio Network.<br>The procedure shall go to**A42** if the stored Radio Network type is:<br>a) FRMCS or FRMCS+GSM-R while FRMCS is the only radio system<br>installed on-board, and a sufficient time is elapsed since the FRMCS on-<br>board equipment has been detected to be connected to the ETCS on-board<br>equipment, OR<br>b) FRMCS+GSM-R while both radio systems are installed on-board, and a<br>sufficient time is elapsed since the latest GSM-R Radio Network<br>registration order was sent to a GSM-R Mobile Terminal, OR<br>c) GSM-R or FRMCS+GSM-R while GSM-R is the only radio system installed<br>on-board, and a sufficient time is elapsed since the latest GSM-R Radio<br>Network registration order was sent to a GSM-R Mobile Terminal.<br>|Figure 109 – Main window|



Version 4.0.0 PAGE 233 OF 317


**ERA ERTMS unit**

**ETCS Driver Machine Interface**



|ID in Flow<br>Chart|Requirements|Window|
|---|---|---|
|**A42**|If the stored Radio Network type is FRMCS or FRMCS+GSM-R while FRMCS is<br>the only radio system installed on-board, and the FRMCS network registration has<br>failed, the text message “**FRMCS network registration failed**” (see chapter 15)<br>shall be displayed.<br>If the stored Radio Network type is FRMCS+GSM-R while both radio systems are<br>installed on-board, and the FRMCS network registration and/or GSM-R network<br>registration have/has failed, the text message(s) “**FRMCS network registration**<br>**failed**” and/or “**GSM-R network registration failed**” (see chapter 15) shall be<br>displayed.<br>If the stored Radio Network type is GSM-R or FRMCS+GSM-R while GSM-R is the<br>only radio system installed on-board, and the GSM-R network registration has<br>failed, the text message “**GSM-R network registration failed**” (see chapter 15)<br>shall be displayed.<br>This procedure shall go to**D9.**||
|**D9**|If the stored Radio Network type is FRMCS+GSM-R while both radio systems are<br>installed on-board, and either the FRMCS on-board is registered to the FRMCS<br>Radio Network or at least one GSM-R Mobile Terminal is duly registered to a GSM-<br>R Radio Network, the procedure shall go to**S5** <br>Otherwise, the procedure shall go to**S10**||


Version 4.0.0 PAGE 234 OF 317


**ERA ERTMS unit**

**ETCS Driver Machine Interface**






|ID in Flow<br>Chart|Requirements|Window|
|---|---|---|
|**S5**|The **Mission with only one radio system window** shall request the driver to enter<br>the choice to perform the mission with only one radio system.<br>When entering**S5**, the Mission with one radio system window shall not propose<br>any value in the input field.<br>If the driver enters ‘Yes’ and the RBC contact information is valid**(E2)**, the<br>procedure shall go to**A31.** <br>If the driver enters ‘Yes’ and the RBC contact information is not valid**(E3)**, the<br>procedure shall go to**S3-1.** <br>If the driver enters ‘No’**(E4)**, the procedure shall go to**S10.**|Figure 129c –Mission with one radio system window|
|**A29**|The text message“**GSM-R network registration failed**” (see chapter 15) shall be<br>displayed.<br>This procedure shall go to**D10.**||
|**D10**|If the stored Radio Network type is FRMCS+GSM-R while both radio systems are<br>installed on-board, the procedure shall go back to**S3-1**. <br>Otherwise, the procedure shall go to**S10**.||
|**S3-3**|The**RBC data window** shall request the driver to enter the RBC contact<br>information (if the status of the RBC contact information is “unknown”) or to<br>revalidate or re-enter the RBC contact information (if the status of RBC contact<br>information is “invalid”).<br>When the ‘Yes’ button related to the ‘RBC data entry complete?’ question is<br>enabled (i.e. all input fields contains a value), if the driver presses this ‘Yes’ button,<br>the procedure shall go to**A31**|Figure 118 – RBC data window|



Version 4.0.0 PAGE 235 OF 317


**ERA ERTMS unit**

**ETCS Driver Machine Interface**






|ID in Flow<br>Chart|Requirements|Window|
|---|---|---|
|**S3-4**|The**Radio network type window** shall request the driver to re-enter the Radio<br>network type.<br>If the driver enters FRMCS or FRMCS+GSM-R while FRMCS is installed on-board,<br>and the FRMCS on-board registration is not registered to the FRMCS Radio<br>Network** (E5)**, the process shall go to**A41.** <br>Otherwise**(E6)**, once the Radio network type is entered, the procedure shall go<br>back to**S3-1**|Figure 129b – Radio network type window|
|**A41**|The text message “**FRMCS network registration failed**” (see chapter 15) shall be<br>displayed.<br>The procedure shall go to**D10**.||
|**A43**|If the FRMCS network registration has failed and it is not already displayed through<br>**A41**, the text message “**FRMCS network registration failed**” (see chapter 15)<br>shall be displayed.<br>If the GSM-R network registration has failed and it is not already displayed through<br>**A29**, the text message “**GSM-R network registration failed**” (see chapter 15)<br>shall be displayed.<br>The process shall then go to**S5**||
|**S10**|The procedure shall go to the**S1** of the main window dialogue sequence||
|**A31**|The**Main window** shall be presented to the driver with all buttons ‘disabled’.<br>The symbol**ST05** shall be displayed to show that the onboard awaits an answer<br>from the RBC.|Figure 109 – Main window|
|**D31**|If the opening of the session is successful, the procedure shall go to**D32** <br>If the opening of the session has failed, the procedure shall go to**A32**||



Version 4.0.0 PAGE 236 OF 317


**ERA ERTMS unit**

**ETCS Driver Machine Interface**



|ID in Flow<br>Chart|Requirements|Window|
|---|---|---|
|**A32**|If the communication session is terminated due to no compatible version, the text<br>message“**Trackside not compatible**” (see chapter 15) shall be displayed.<br>This procedure shall go to**S10.**||
|**_D32_**|_If the stored position is valid and refers to an LRBG, the procedure shall go to_**_A33_** <br>_Otherwise, the procedure shall go to_**_A34_**||
|**_A33_**|_The “SoM position report” message, marked as referring to a “valid train position_<br>_referred to an LRBG”, shall be transmitted to the RBC, together with valid Train_<br>_Data and/or valid Train running number, if already stored on-board, and, if available_<br>_while no valid Train Data is stored on-board, with safe consist length information._<br>_This condition leads to_**_S10_**_. _||
|**_A34_**|_If the train position data stored in the on-board equipment is of status “invalid” and_<br>_refers to an LRBG, the “SoM position report” message, marked as referring to an_<br>_“invalid train position referred to an LRBG”, shall be transmitted to the RBC._<br>_Otherwise the "SoM position report" message, marked as referring to "no train_<br>_position referred to an LRBG” and with the LRBG identity set to "unknown", shall_<br>_be transmitted to the RBC._<br>_In both cases valid Train Data and/or valid Train running number, if already stored_<br>_on-board, and, if available while no valid Train Data is stored on-board, safe consist_<br>_length information, shall be included in the “SoM position report” message._<br>_The process shall then go to_**_D33_**||


Version 4.0.0 PAGE 237 OF 317


**ERA ERTMS unit**

**ETCS Driver Machine Interface**



|ID in Flow<br>Chart|Requirements|Window|
|---|---|---|
|**_D33_**|_When the position report marked as referring to an "invalid train position referred_<br>_to an LRBG" is received by the RBC, this latter shall check whether it can validate_<br>_this position report._<br>_If the position report can be validated by the RBC, the process shall go to_**_A35_** <br>_Otherwise, if the position report was marked as referring to "no train position_<br>_referred to an LRBG", or if the position report that was marked as referring to an_<br>_"invalid train position referred to an LRBG" cannot be validated by the RBC, the_<br>_process shall go to_**_D22_**<br>_Note: How the RBC is able to validate the position report is a national issue, out_<br>_of the scope for this specification_||
|**_A35_**|_The RBC shall inform the ERTMS/ETCS onboard equipment that the reported_<br>_position referred to an LRBG is valid._<br>_When this message is received by the ERTMS/ETCS on-board equipment, the_<br>_status of the position shall be set to "valid"_<br>_The process shall go to_**_S10_**_. _||
|**_D22_**|_If the SoM position report is marked as referring to "no train position referred to an_<br>_LRBG", or if the RBC is not able to confirm a SoM position report marked as_<br>_referring to an "invalid train position referred to an LRBG", the RBC shall_<br>_nevertheless decide whether it accepts the train or not._<br>_If yes, the process shall go to_**_A23_** <br>_If no, the process shall go to_**_A38_**<br>_Note: How the RBC assumes responsibility for the train is a national issue, out of_<br>_the scope for this specification_||
|**_A23_**|_The RBC shall inform the ERTMS/ETCS on-board equipment that it accepts the_<br>_train although the on-board has not reported a "valid train position referred to an_<br>_LRBG" information._||


Version 4.0.0 PAGE 238 OF 317


**ERA ERTMS unit**

**ETCS Driver Machine Interface**



|ID in Flow<br>Chart|Requirements|Window|
|---|---|---|
|**_D34_**|_When the ERTMS/ETCS on-board equipment is informed that the train is accepted_<br>_without "valid train position referred to an LRBG" information:_<br>• <br>_If a valid train position data referred to an unlinked balise group is stored_<br>_on-board, the status of the train position shall remain unchanged and the_<br>_process shall go to_**_S10_** <br>• <br>_Otherwise the process shall go to_**_A24_**||
|**_A24_**|_The ERTMS/ETCS on-board equipment shall delete the train position data (new_<br>_status: “unknown”) and the process shall go to_**_S10_**_. _||
|**_A38_**|_The RBC shall inform the ERTMS/ETCS on-board equipment that it rejects the_<br>_train_||
|**_D35_**|_When the ERTMS/ETCS on-board equipment is informed that the train is rejected:_<br>• <br>_If a valid train position data referred to an unlinked balise group is stored_<br>_on-board, the status of the train position shall remain unchanged and the_<br>_process shall go to_**_A40-1_** <br>• <br>_Otherwise the process shall go to_**_A39_**||
|**_A39_**|_The ERTMS/ETCS on-board equipment shall delete the train position data (new_<br>_status: “unknown”) and the process shall go to_**_A40_**||
|**_A40-1_**|_The ERTMS/ETCS on-board equipment shall terminate the session with the RBC._<br>_Once the session is terminated, the process shall go to_**_A40-2_**||
|**A40-2**|The text message“**Train is rejected**” (see chapter 15) shall be displayed.<br>This procedure shall go to**S10**.||


**Table 49 – Steps of the Start Up dialogue sequence**


Version 4.0.0 PAGE 239 OF 317


**ERA ERTMS unit**

**ETCS Driver Machine Interface**


**11.7.3** **Main window**


11.7.3.1 The “Main window” dialogue sequence shows the interaction with the driver when the
main window is presented either because he has pressed the main button on the default
window or because the start up dialogue sequence is in S10 (i.e. a start of mission is
ongoing).


11.7.3.2 The [close] button shall be enabled in all windows except in the steps S5-2-1, S5-2-3, S7,
S8 or S9 where it shall be disabled.


























|S5-2<br>GSM-R network ID<br>window|S5-4<br>Radio network type|
|---|---|
|**S5-2**<br>**GSM-R network ID **<br>**window**|**window**|







































































Driver
has
entered
Yes



































































**Figure 137 – Main window dialogue sequence**













Version 4.0.0 PAGE 240 OF 317


**ERA ERTMS unit**

**ETCS Driver Machine Interface**


11.7.3.3 The steps of the “Main window” dialogue sequence shall follow Table 50.










|ID in Flow<br>Chart|Requirements|Window|
|---|---|---|
|**S1**|The**Main window** shall offer the possibility to the driver to select ‘Driver ID’,<br>‘Shunting’ / ‘Exit Shunting’, ‘Maintain Shunting’, ‘Non leading’, ‘Train data’, ‘Level’,<br>‘Train running number’, ‘Initiate SM’/‘Continue in SM’, ‘Exit SM’ and ‘Start’.<br>• <br>If the driver presses ‘Driver ID’, the procedure shall go to**S2**. <br>• <br>If the driver presses ‘Initiate SM’ or ‘Continue in SM’, the procedure shall go to<br>the Supervised Manoeuvre dialogue sequence.<br>• <br>If the driver presses ‘Shunting’, the procedure shall go to the Shunting dialogue<br>sequence.<br>• <br>If the driver presses ‘Non-Leading’ or ‘Maintain Shunting’, the procedure shall<br>go back to**the default window**. <br>• <br>If the driver presses ‘Exit Shunting’, the procedure shall go to**S0**of the start up<br>dialogue sequence.<br>• <br>If the driver presses ‘Exit SM’, the procedure shall go to**S0**of the start up<br>dialogue sequence.<br>• <br>If the driver presses ‘Train data’, the procedure shall go to**S3-1** <br>• <br>If the driver presses ‘Level’, the procedure shall go to**S4** <br>• <br>If the driver presses ‘Train running number’, the procedure shall go to**S6** <br>• <br>If the driver presses ‘Start’ and the level is 0/1/NTC, the procedure shall go<br>back to**the default window**. <br>• <br>If the driver presses ‘Start’ and the level is 2, the procedure shall go to**D7** <br>• <br>If the driver presses ‘Radio data’, the procedure shall go to**S5-1**|<br>Figure 109 – Main window|



Version 4.0.0 PAGE 241 OF 317


**ERA ERTMS unit**

**ETCS Driver Machine Interface**






|ID in Flow<br>Chart|Requirements|Window|
|---|---|---|
|**S2**|The**Driver ID window** shall request the driver to revalidate or re-enter the Driver<br>ID.<br>Once the Driver ID is re-entered or revalidated, the procedure shall go back to**S1** <br>(the Main window)|Figure 116 – Driver ID window|



Version 4.0.0 PAGE 242 OF 317


**ERA ERTMS unit**

**ETCS Driver Machine Interface**





Version 4.0.0 PAGE 243 OF 317


**ERA ERTMS unit**

**ETCS Driver Machine Interface**


Version 4.0.0 PAGE 244 OF 317


**ERA ERTMS unit**

**ETCS Driver Machine Interface**




|Col1|When the ‘Yes’ button related to the ‘Train data entry complete?’ question is<br>enabled (i.e. every input field for train data in all ‘train data’ windows contains a<br>data value), if the driver presses this ‘Yes’ button and all data values comply with<br>the data checks, the procedure shall go to S3-2<br>Note: In this step, when the driver presses the ‘Yes’ button, train data are not<br>validated yet and consequently are not yet the train data stored onboard for the<br>mission (see 11.7.1.6.1). This is why the term “accept” is used instead of the term<br>“revalidate” and the term “input field for train type/data” is used instead of “train<br>data”.|Col3|
|---|---|---|
|**S3-2**|The**Train data validation window** shall request the driver to validate or not the<br>values of the input fields for train data.<br>When entering**S3-2**, the train data validation window shall always propose the<br>value ‘Yes’ in the input field for train data validation.<br>Once the input field for train data validation is entered or revalidated, if the value is<br>‘No’, the procedure shall go back to**S3-1.**Otherwise, if the value is ‘Yes’, the<br>procedure shall go to**D6**|Figure 130 – Train data validation window|
|**D6**|If Train running number is “valid”, the procedure shall go to**D1** <br>If Train running number is “invalid” or “unknown”, the procedure shall go to**S3-3**||
|**S3-3**|The**Train running number window** shall request the driver to enter the Train<br>running number (if the status of the Train running number is “unknown”) or shall<br>request the driver to revalidate or re-enter the Train running number (if the status<br>of Train running number is “invalid”).<br>Once the train running number is entered or revalidated, the procedure shall go to<br>**D1**|Figure 114 – Train running number window|
|**D1**|When the validated level is 2, the procedure shall go to**D2** <br>When the validated level is 0, 1 or NTC, the procedure shall go back to**S1** (the<br>Main window)||
|**D2**|When the session is open, the procedure shall go to**D8**, otherwise the procedure<br>shall go back to**S1** (the Main window)||



Version 4.0.0 PAGE 245 OF 317


**ERA ERTMS unit**

**ETCS Driver Machine Interface**




|D8|If the ERTMS/ETCS on-board equipment has already received the Train Data<br>acknowledgment from the RBC, the process shall go back to S1 (the Main window),<br>otherwise it shall go to S9|Col3|
|---|---|---|
|**S9**|The**Main window** shall be presented to the driver with all buttons ‘disabled’.<br>The symbol**ST05** shall be displayed to show that the onboard awaits an answer<br>from the RBC.<br>When the train data acknowledgement is received from the RBC or when the<br>communication session is terminated due to no reply from RBC, the procedure<br>shall go back to**S1** (the Main window)|Figure 109 – Main window|
|**S4**|The**ERTMS/ETCS level window** shall request the driver to revalidate or re-enter<br>the Level data.<br>If the entered / re-validated level is 2, the procedure shall go to**D5** <br>If the entered / re-validated level is 0 or 1 or one of proposed NTC level(s), the<br>procedure shall go back to**S1** (the Main window)<br>|Figure 115 – ERTMS/ETCS level window|



Version 4.0.0 PAGE 246 OF 317


**ERA ERTMS unit**

**ETCS Driver Machine Interface**




|D5|The procedure shall go to S8 if RBC contact information is “valid” and:<br>a) the FRMCS on-board is registered to the FRMCS Radio Network, in case<br>the stored Radio Network type is FRMCS or is FRMCS+GSM-R while<br>FRMCS is the only radio system installed on-board, OR<br>b) the FRMCS on-board is registered to the FRMCS Radio Network and at<br>least one GSM-R Mobile Terminal is registered to a GSM-R Radio Network,<br>in case the stored Radio Network type is FRMCS+GSM-R while both radio<br>systems are installed on-board, OR<br>c) at least one GSM-R Mobile Terminal is registered to a Radio Network, in<br>case the stored Radio Network type is GSM-R or is FRMCS+GSM-R while<br>GSM-R is the only radio system installed on-board<br>Otherwise, the procedure shall go to S5-1<br>Exception: If, following the level entry/re-validation, the ERTMS/ETCS on-board<br>equipment switches to the TR mode (case of a transition from level 0/NTC to 2),<br>the Default window shall firstly be presented with the symbol MO05. As soon as<br>the symbol MO05 is acknowledged, the procedure shall go to S5-1|Col3|
|---|---|---|
|**S5-1**|The**Radio data window** shall offer the possibility to the driver to select ‘Contact<br>last RBC’, ‘Use short number’, ‘Enter RBC data’, 'Radio network type', ‘GSM-R<br>network ID’ and ‘Mission with one radio system’<br>• <br>If the driver presses ‘Contact last RBC’ or ‘Use short number’, the procedure<br>shall go to**S8**. <br>• <br>If the driver presses ‘Enter RBC data’, the procedure shall go to**S5-3**. <br>• <br>If the driver presses ‘Radio network type’, the procedure shall go to**S5-4**. <br>• <br>If the driver presses ‘Radio network ID’, the procedure shall go to**S5-2-1**. <br>• <br>If the driver presses ‘Mission with one radio system’, the procedure shall go to<br>**A7**.|Figure 113 – Radio data window|



Version 4.0.0 PAGE 247 OF 317


**ERA ERTMS unit**

**ETCS Driver Machine Interface**




|S5-2-1|The Radio data window shall be presented to the driver with all buttons ‘disabled’.<br>The symbol ST05 shall be displayed to show that the onboard awaits the<br>alphanumeric list of available and allowed GSM-R Networks.<br>If this list is not empty, the procedure shall go to S5-2-2.<br>If this list is empty, the procedure shall go to A5.|Figure 113 – Radio data window|
|---|---|---|
|**S5-2-2**|The**GSM-R network ID window** shall request the driver to re-enter the GSM-R<br>network ID<br>Once the GSM-R network ID is entered, the procedure shall go to**S5-2-3**|Figure 117 – GSM-R network ID window|
|**S5-2-3**|The **Radio data window** shall be presented to the driver with all buttons ‘disabled’.<br>The symbol**ST05** shall be displayed to show that the onboard awaits the<br>registration to the GSM-R Network.<br>When at least one Mobile Terminal is registered to the GSM-R Network, the<br>procedure shall go to**S5-1**|Figure 113 – Radio data window|
|**A5**|The text message“**GSM-R network registration failed**” (see chapter 15) shall be<br>displayed.<br>This procedure shall go to**D9.**||
|**D9**|If the stored Radio Network type is FRMCS+GSM-R while both radio systems are<br>installed on-board, the procedure shall go back to**S5-1**. <br>Otherwise, the procedure shall go to**S1**.||
|**S5-3**|The**RBC data window** shall request the driver to enter the RBC contact<br>information (if the status of the RBC contact information is “unknown”) or to<br>revalidate or re-enter the RBC contact information (if the status of RBC contact<br>information is “invalid” or “valid”).<br>When the ‘Yes’ button related to the ‘RBC data entry complete?’ question is<br>enabled (i.e. all input fields contains a value), if the driver presses this ‘Yes’ button,<br>the procedure shall go to**S8**|Figure 118 – RBC data window|



Version 4.0.0 PAGE 248 OF 317


**ERA ERTMS unit**

**ETCS Driver Machine Interface**




|S5-4|The Radio network type window shall request the driver to re-enter the Radio<br>network type<br>If the driver enters FRMCS or FRMCS+GSM-R while FRMCS is installed on-board,<br>and the FRMCS on-board registration is not registered to the FRMCS Radio<br>Network (E1), the process shall go to A6.<br>Otherwise (E2), once the Radio network type is entered, the procedure shall go<br>back to S5-1|Figure 129b – Radio network type window|
|---|---|---|
|**A6**|The text message “**FRMCS network registration failed**” (see chapter 15) shall be<br>displayed.<br>The procedure shall go to**D9**.||
|**A7**|If the FRMCS network registration has failed and it is not already displayed through<br>**A6**, the text message “**FRMCS network registration failed**” (see chapter 15) shall<br>be displayed.<br>If the GSM-R network registration has failed and it is not already displayed through<br>**A5**, the text message“**GSM-R network registration failed**” (see chapter 15) shall<br>be displayed.<br>The process shall then go to**S10**||
|**S10**|The **Mission with only one radio system window** shall request the driver to enter<br>the choice to perform the mission with only one radio system.<br>When entering**S10**, the Mission with one radio system window shall not propose<br>any value in the input field.<br>If the driver enters ‘Yes’, the procedure shall go to**S5-1.** <br>If the driver enters ‘No’, the procedure shall go to**S1.**|Figure 129c –Mission with one radio system window|
|**S8**|The**Main window** shall be presented to the driver with all buttons ‘disabled’.<br>The symbol**ST05** shall be displayed to show that the onboard awaits an answer<br>from the RBC.|Figure 109 – Main window|



Version 4.0.0 PAGE 249 OF 317


**ERA ERTMS unit**

**ETCS Driver Machine Interface**




|D3|If the opening of the session is successful, the procedure shall go to D4<br>If the opening of the session has failed or the session is terminated due to no<br>compatible version, the procedure shall go back to S1 (the Main window)<br>If the communication session is terminated due to no compatible version, the text<br>message “Trackside not compatible” (see chapter 15) shall be displayed.|Col3|
|---|---|---|
|**D4**|If a start of mission is ongoing, the procedure shall go to the**D32** of the start up<br>dialogue sequence.<br>If no start of mission is ongoing, the procedure shall go back to**S1** (the Main<br>window)||
|**S6**|The**Train running number window** shall request the driver to enter the Train<br>running number (if the status of the Train running number is “unknown”) or shall<br>request the driver to revalidate or re-enter the Train running number (if the status<br>of Train running number is “invalid” or “valid”).<br>Once the train running number is entered or revalidated, the procedure shall go<br>back to**S1** (the Main window)|Figure 114 – Train running number window|
|**D7**|When the session is open, the procedure shall go to**S7**, otherwise the procedure<br>shall go back to**the default window**.||



Version 4.0.0 PAGE 250 OF 317


**ERA ERTMS unit**

**ETCS Driver Machine Interface**


**Table 50 – Steps of the Main window dialogue sequence**





Version 4.0.0 PAGE 251 OF 317


**ERA ERTMS unit**

**ETCS Driver Machine Interface**


**11.7.4** **Shunting**


11.7.4.1 The “Shunting” dialogue sequence shows the interaction with the driver when he has
pressed the shunting button on the main window.


11.7.4.2 The [close] button shall be disabled in the step S1.


















|D1 no reply is rec<br>0/1 Level 2 from the last<br>NTC<br>D2<br>No National trip<br>procedure<br>Yes|eived<br>sendin|
|---|---|
|**D1**<br>Level<br>2<br>0/1<br>no reply is rec<br>from the last<br>**D2**<br>National trip<br>procedure<br>No<br>NTC<br>Yes||








|The TR symbol (MO04)<br>and the text message "SH<br>refused" are displayed|Col2|
|---|---|
|||





**Figure 138 – Shunting dialogue sequence**


Version 4.0.0 PAGE 252 OF 317


**ERA ERTMS unit**

**ETCS Driver Machine Interface**


11.7.4.3 The steps of the “Shunting” dialogue sequence shall follow Table 51.







|ID in Flow<br>Chart|Requirements|Window|
|---|---|---|
|**S0**|When the driver presses the Shunting button in S1 of the Main window dialogue<br>sequence, the procedure shall go to**D1**.||
|**D1**|If the level is 0/1, the SH symbol **MO01** shall be presented and the procedure shall<br>go back to**the default window**. <br>If the level is 2, the procedure shall go to**S1**. <br>If the level is NTC, the procedure shall go to** D2**||
|**D2**|If there is an ongoing National Trip procedure reported by the STM, the TR symbol<br>**MO04** and the text message “SH refused” shall be presented. Otherwise the SH<br>symbol **MO01** shall be presented.<br>In both cases, the procedure shall go back to**the default window**.||
|**S1**|The**Main window** shall be presented to the driver with all buttons ‘disabled’.<br>The symbol**ST05** shall be displayed to show that the onboard awaits an answer<br>from the RBC.<br>When the message ‘Shunting Refused’ is received from the RBC, the text message<br>“SH refused” (see chapter 15) shall be displayed and the procedure shall go back<br>to S0 (i.e. S1 of the Main window dialogue sequence).<br>When no reply is received within the fixed waiting time from the time of the last<br>sending of “Request for Shunting”, the text message “Shunting request failed” (see<br>chapter 15) shall be displayed and the procedure shall go back to**S0** (i.e. S1 of the<br>Main window dialogue sequence)<br>When the message ‘Shunting Authorised’ is received from the RBC, the SH symbol<br>**MO01** shall be presented and the procedure shall go back to **the default window**.|Figure 109 – Main window|


**Table 51 – Steps of the Shunting dialogue sequence**





Version 4.0.0 PAGE 253 OF 317


**ERA ERTMS unit**

**ETCS Driver Machine Interface**


**11.7.5** **Override window**


11.7.5.1 The “Override window” dialogue sequence shows the interaction with the driver when he
presses the ‘Override’ button on the default window.


11.7.5.2 The [close] button shall always be enabled on the Override window.











**Figure 139 – Override window dialogue sequence**


Version 4.0.0 PAGE 254 OF 317


**ERA ERTMS unit**

**ETCS Driver Machine Interface**


11.7.5.3 The steps of the “Override window” dialogue sequence shall follow Table 52.







|ID in Flow<br>Chart|Requirements|Window|
|---|---|---|
|**S0**|When the driver presses the override button on **the default window**, the procedure<br>shall go to**S1**.||
|**S1**|The**Override window** shall be presented to the driver.<br>When the driver presses the ‘EOA’ button, the override EOA symbol**MO03** shall<br>be presented and the procedure shall go back to**the default window**.|Figure 110 – Override window|


**Table 52 – Steps of the Override window dialogue sequence**





Version 4.0.0 PAGE 255 OF 317


**ERA ERTMS unit**

**ETCS Driver Machine Interface**



**11.7.6** **Special window**


11.7.6.1 The “Special window” dialogue sequence shows the interaction with the driver when he
presses the ‘Special’ button on the default window.


11.7.6.2 The [close] button shall always be enabled on the ‘Special’, ‘Adhesion’ and ‘SR speed /
distance’ windows.

































**Figure 140 – Special window dialogue sequence**


Version 4.0.0 PAGE 256 OF 317


**ERA ERTMS unit**

**ETCS Driver Machine Interface**


11.7.6.3 The steps of the “Special window” dialogue sequence shall follow Table 53.










|ID in Flow<br>Chart|Requirements|Window|
|---|---|---|
|**S0**|When the driver presses the special button on **the default window**, the procedure<br>shall go to**S1**.||
|**S1**|The**Special window** shall be presented to the driver.<br>When the driver presses the ‘Adhesion’ button, the procedure shall go to**S2.** <br>When the driver presses the ‘Train Integrity’ button, the procedure shall go back to<br>**the default window**. <br>When the driver presses the ‘SR speed / distance’ button, the procedure shall go<br>to**S3.**<br>When the driver presses the ‘BMM reaction inhibition’ button, the BMM reaction<br>inhibition symbol**ST07** shall be presented and the procedure shall go back to**the**<br>**default window**. <br>When the driver presses the ‘Revoke BMM reaction inhibition’ button, the BMM<br>reaction inhibition symbol **ST07** shall be removed and the procedure shall go back<br>to **the default window**.|Figure 111 – Special window|
|**S2**|The**Adhesion window** shall request the driver to revalidate or re-enter the<br>adhesion.<br>Once the adhesion is entered or revalidated, the procedure shall go to**D1**|Figure 127 – Adhesion window|
|**D1**|When the adhesion is “slippery rail”, the adhesion symbol **ST02** shall be displayed<br>and the procedure shall go back to**S1**. <br>When the adhesion is “non slippery rail”, the adhesion symbol**ST02** shall not be<br>displayed and the procedure shall go back to**S1**.||



Version 4.0.0 PAGE 257 OF 317


**ERA ERTMS unit**

**ETCS Driver Machine Interface**



|ID in Flow<br>Chart|Requirements|Window|
|---|---|---|
|**S3**|The **SR speed / distance window** shall request the driver to revalidate or re-enter<br>the SR speed and/or the SR distance.<br>If the value of the SR distance stored onboard is higher than the maximum value<br>defined in document [2], section A.3.11 or is infinite then the maximum value shall<br>be proposed to the driver.<br>When the ‘Yes’ button related to the ‘SR speed / distance entry complete?’<br>question is enabled (i.e. both input fields contains a value), if the driver presses<br>this ‘Yes’ button and all data values comply with the data checks, the procedure<br>shall go back to**S1**|Figure 126 – SR speed / distance window|


**Table 53 – Steps of the Special window dialogue sequence**





Version 4.0.0 PAGE 258 OF 317


**ERA ERTMS unit**

**ETCS Driver Machine Interface**


**11.7.7** **Settings window**


11.7.7.1 The “Settings window” dialogue sequence shows the interaction with the driver when he
presses the ‘Settings’ button on the default window or on the Driver ID window during the
start up dialogue sequence.


11.7.7.2 The [close] button shall always be enabled on all windows.



















































Set VBC


**Figure 141 – Settings window dialogue sequence**

|S6-1<br>Set VBC window|Col2|
|---|---|
|**S6-2**<br>**Set VBC validation window**|**S6-2**<br>**Set VBC validation window**|
|**S6-2**<br>**Set VBC validation window**|Driver validates<br>Set VBC|



Version 4.0.0 PAGE 259 OF 317


**ERA ERTMS unit**

**ETCS Driver Machine Interface**


11.7.7.3 The steps of the “Settings window” dialogue sequence shall follow Table 54.










|ID in Flow<br>Chart|Requirements|Window|
|---|---|---|
|**S0**|When the driver presses the settings button on**the default window** or the step<br>S1-1 of the start up dialogue sequence is reached, the procedure shall go to**S1**.||
|**S1**|The**Settings window** shall be presented to the driver.<br>When the driver presses the ‘Language’ button, the procedure shall go to**S2**. <br>When the driver presses the ‘Volume’ button, the procedure shall go to**S3**. <br>When the driver presses the ‘Brightness’ button, the procedure shall go to**S4**. <br>When the driver presses the ‘System version’ button, the procedure shall go to**S5**. <br>When the driver presses the ‘Set VBC’ button, the procedure shall go to**S6-1**. <br>When the driver presses the ‘Remove VBC’ button, the procedure shall go to**S7-**<br>**1**. <br>When the driver presses the ‘ATO’ button, the procedure shall go to**S8**.|Figure 112 – Settings window|
|**S2**|The**Language window** shall request the driver to revalidate or re-enter the<br>language.<br>Once the language is re-entered or revalidated, the procedure shall go back to**S1**|Figure 119 – Language window|
|**S3**|The**Volume window** shall request the driver to revalidate or re-enter the volume.<br>Once the volume is re-entered or revalidated, the procedure shall go back to**S1**||
|**S4**|The**Brightness window** shall request the driver to revalidate or re-enter the<br>luminance.<br>Once the luminance is re-entered or revalidated, the procedure shall go back to**S1**||
|**S5**|The**System version window** displays the operated system version to the driver.<br>When the driver presses the [Close] button, the procedure shall go back to**S1**|Figure 135 – System version window|



Version 4.0.0 PAGE 260 OF 317


**ERA ERTMS unit**

**ETCS Driver Machine Interface**






|ID in Flow<br>Chart|Requirements|Window|
|---|---|---|
|**S6-1**|The**Set VBC window** shall request the driver to enter (if no value is proposed) or<br>to accept / re-enter (if a value is proposed) the input field for ‘VBC set code’.<br>If**S6-1** is entered from**S1**(i.e. the Set VBC entry / validation process starts<br>following a driver action on the ‘Set VBC’ button), no value shall be proposed for<br>the input field<br>If**S6-1** is entered from**S6-2**(i.e. the Set VBC entry / validation process is going<br>on), the proposed value of the input field for ‘VBC set code’ shall be the data value<br>from the previous**S6-1** <br>When the ‘Yes’ button related to the ‘Set VBC entry complete?’ question is enabled<br>(i.e. the input field for ‘VBC set code’ contains a data value), if the driver presses<br>this ‘Yes’ button and all data values comply with the data checks, the procedure<br>shall go to**S6-2**<br>Note: In this step, when the driver presses the ‘Yes’ button, the ‘VBC set code’ is<br>not validated yet and consequently a new VBC is not yet added to the list of VBC’s<br>stored onboard. This is why the term ‘input field for VBC set code’ is used instead<br>of ‘VBC set code’.|Figure 128 – Set VBC window|
|**S6-2**|The**Set VBC validation window** shall request the driver to validate or not the<br>value of the input field for ‘VBC set code’.<br>When entering**S6-2**, the Set VBC validation window shall always propose the<br>value ‘Yes’ in the input field for Set VBC validation.<br>Once the input field for Set VBC validation is entered or revalidated, if the value is<br>‘No’, the procedure shall go back to**S6-1.**Otherwise, if the value is ‘Yes’, the<br>procedure shall go back to**S1**|Figure 131 – Set VBC validation window|



Version 4.0.0 PAGE 261 OF 317


**ERA ERTMS unit**

**ETCS Driver Machine Interface**






|ID in Flow<br>Chart|Requirements|Window|
|---|---|---|
|**S7-1**|The**Remove VBC window** shall request the driver to enter (if no value is<br>proposed) or to accept / re-enter (if a value is proposed) the input field for ‘VBC<br>remove code’.<br>If**S7-1** is entered from**S1**(i.e. the Remove VBC entry / validation process starts<br>following a driver action on the ‘Remove VBC’ button), no value shall be proposed<br>for the input field<br>If**S7-1** is entered from**S7-2**(i.e. the Remove VBC entry / validation process is<br>going on), the proposed value of the input field for ‘VBC remove code’ shall be the<br>data value from the previous**S7-1** <br>When the ‘Yes’ button related to the ‘Remove VBC entry complete?’ question is<br>enabled (i.e. the input field for ‘VBC remove code’ contains a data value), if the<br>driver presses this ‘Yes’ button and all data values comply with the data checks,<br>the procedure shall go to**S7-2**<br>Note: In this step, when the driver presses the ‘Yes’ button, the ‘VBC remove code’<br>is not validated yet and consequently the VBC is not yet removed from the list of<br>VBC’s stored onboard. This is why the term ‘input field for VBC remove code’ is<br>used instead of ‘VBC remove code’.|Figure 129 – Remove VBC window|
|**S7-2**|The**Remove VBC validation window** shall request the driver to validate or not<br>the value of the input field for ‘VBC remove code’.<br>When entering**S7-2**, the Remove VBC validation window shall always propose the<br>value ‘Yes’ in the input field for Remove VBC validation.<br>Once the input field for Remove VBC validation is entered or revalidated, if the<br>value is ‘No’, the procedure shall go back to**S7-1.**Otherwise, if the value is ‘Yes’,<br>the procedure shall go back to**S1**|Figure 132 – Remove VBC validation window|



Version 4.0.0 PAGE 262 OF 317


**ERA ERTMS unit**

**ETCS Driver Machine Interface**



|ID in Flow<br>Chart|Requirements|Window|
|---|---|---|
|**S8**|The**ATO selector window** shall request the driver to revalidate or re-enter the<br>ATO selector position.<br>Once the ATO selector position is re-entered or revalidated, the procedure shall go<br>back to**S1**|Figure 129a – ATO selector window|


**Table 54 – Steps of the Settings window dialogue sequence**





Version 4.0.0 PAGE 263 OF 317


**ERA ERTMS unit**

**ETCS Driver Machine Interface**


**11.7.8** **Supervised Manoeuvre**


11.7.8.1 The “Supervised Manoeuvre” dialogue sequence shows the interaction with the driver
when he has pressed the ‘Initiate SM’/’Continue in SM’ button on the main window.


11.7.8.2 The [close] button shall be disabled in the step S1.



















|The SM symbols (MO24)<br>and (SM01 or SM02) are<br>displayed|Col2|
|---|---|
|||


The **default window** is displayed


**Figure 141a – Supervised Manoeuvre dialogue sequence**


Version 4.0.0 PAGE 264 OF 317


**ERA ERTMS unit**

**ETCS Driver Machine Interface**


11.7.8.3 The steps of the “Supervised Manoeuvre” dialogue sequence shall follow Table 54a.







|ID in Flow<br>Chart|Requirements|Window|
|---|---|---|
|**S0**|When the driver presses the ‘Initiate SM’/’Continue in SM’ button in S1 of the Main<br>window dialogue sequence, the procedure shall go to**S1**.||
|**S1**|The**Main window** shall be presented to the driver with all buttons ‘disabled’.<br>The symbol**ST05** shall be displayed to show that the onboard awaits an answer<br>from the RBC.<br>When the message ‘Supervised Manoeuvre Refused’ is received from the RBC,<br>the text message “**SM refused**” (see chapter 15) shall be displayed and the<br>procedure shall go back to**S0** (i.e. S1 of the Main window dialogue sequence).<br>When no reply is received within the fixed waiting time from the time of the last<br>sending of “Request for Supervised Manoeuvre”, the text message “**SM request**<br>**failed**” (see chapter 15) shall be displayed and the procedure shall go back to**S0** <br>(i.e. S1 of the Main window dialogue sequence).<br>When the message ‘Supervised Manoeuvre Authorisation’ is received from the<br>RBC, the SM symbols **MO24** and either **SM01** or **SM02** shall be presented and the<br>procedure shall go back to **the default window**.|Figure 109 – Main window|


**Table 54a – Steps of the Supervised Manoeuvre dialogue sequence**





Version 4.0.0 PAGE 265 OF 317


**ERA ERTMS unit**

**ETCS Driver Machine Interface**

