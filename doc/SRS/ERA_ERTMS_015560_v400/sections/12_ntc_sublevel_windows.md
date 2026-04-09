##### **12. ERTMS/ATO & NTC X SUB-LEVEL WINDOWS**


**12.1** **Introduction**


12.1.1.1 The chapter 11.7.8 defines the ERTMS/ATO & NTC X sub-level windows based on the
general requirements of chapter 10. It is applicable for all ERTMS/ETCS levels.


12.1.1.2 Note: The default window partly visible in some figures of chapter 11.7.8 uses the ETCS
default window as specified in chapter 8. However, for the modes SN and NL in
ERTMS/ETCS level NTC, the NTC default window of the corresponding National System
will be displayed instead.


**12.2** **Menu Windows**


**12.2.1** **Specific data entry selection window**


12.2.1.1 The Specific data entry selection window shall comply with the requirements in chapter
10.2.


12.2.1.2 The window title shall indicate “Specific data entry selection”.


12.2.1.3 The buttons (for touch screen technology) / selections (for soft key technology) shall
indicate the label as specified in Table 55.


12.2.1.4 The buttons of the Specific data entry selection window shall be enabled when the
conditions specified in Table 55 are fulfilled and no driver’s acknowledgement is required.


12.2.1.4.1 Note: Whether ‘disabled’ buttons are displayed or not for systems that have already

completed their specific data entry or that does not need any specific data (i.e. ‘End of
Specific ATO Data Entry’ or ‘End of Specific NTC Data Entry’ has been received) or that
have not answered (time out following the sending of the ETCS Train data) (see step S2
in 12.7.2) is an implementation issue by applying 5.3.2.5.5.










|Button<br>/selection #|label|Enabling conditions|SUBSET-035 /<br>SUBSET-125<br>reference|
|---|---|---|---|
|1|ATO|(train is at standstill) AND (Driver ID is valid) AND<br>(ERTMS/ETCS level is valid) AND (mode is<br>SB/FS/AD/LS/SR/OS/UN/SN) AND (‘Specific ATO<br>data entry request’ received from the ERTMS/ATO<br>on-board) AND (no ‘STOP’ flag has been sent to<br>the ERTMS/ATO on-board)|SUBSET-125<br>7.14.2.22<br>7.14.2.25<br>|
|3|NTC A|(train is at standstill) AND (Driver ID is valid) AND<br>(ERTMS/ETCS level is valid) AND (mode is<br>SB/FS/AD/LS/SR/OS/UN/SN) AND (‘Specific NTC<br>data entry request’ received for NTC A) AND (no<br>‘STOP’ flag has been sent to the STM supporting<br>NTC A)|SUBSET-35<br> <br>10.7.4.3<br>10.7.4.5|



Version 4.0.0 PAGE 266 OF 317


**ERA ERTMS unit**

**ETCS Driver Machine Interface**



|Button<br>/selection #|label|Enabling conditions|SUBSET-035 /<br>SUBSET-125<br>reference|
|---|---|---|---|
|4|NTC B|(train is at standstill) AND (Driver ID is valid) AND<br>(ERTMS/ETCS level is valid) AND (mode is<br>SB/FS/AD/LS/SR/OS/UN/SN) AND (‘Specific NTC<br>data entry request’ received for NTC B) AND (no<br>‘STOP’ flag has been sent to the STM supporting<br>NTC B)|SUBSET-35<br> <br>10.7.4.3<br>10.7.4.5|
|5|NTC C|(train is at standstill) AND (Driver ID is valid) AND<br>(ERTMS/ETCS level is valid) AND (mode is<br>SB/FS/AD/LS/SR/OS/UN/SN) AND (‘Specific NTC<br>data entry request’ received for NTC C) AND (no<br>‘STOP’ flag has been sent to the STM supporting<br>NTC C)|SUBSET-35<br> <br>10.7.4.3<br>10.7.4.5|
|...|...|...||
|10|End of data entry|(train is at standstill) AND (Driver ID is valid) AND<br>(ERTMS/ETCS level is valid) AND (mode is<br>SB/FS/AD/LS/SR/OS/UN/SN)|SUBSET-35<br>SUBSET-125 <br>7.14.2.10<br>10.7.3.1|


**Table 55 – Button / selection label**





12.2.1.5 The labels ‘NTC A’, ‘NTC B’, ... shall be replaced with the distinct abbreviations of the
concerned National Systems.


12.2.1.6 The buttons (for touch screen technology) / selections (for soft key technology) #1 and
#10 shall be reserved respectively for the ERTMS/ATO data entry selection and for the
‘End of data entry’.


12.2.1.7 When the hour glass symbol (see symbol ST05) is presented (see steps S1 and S4 in
chapter 12.7.2), it shall be shown vertically centered in the NTC data entry selection
window title area. The first X position of the symbol shall be 42. It shall then move 26 cells
to the right every second. When it is no more possible to display the symbol ST05 inside
the window title area, the symbol shall come back to its first position and shall start again
moving to the right with the same pace.


12.2.1.8 Figure 142 shows the presentation of the “Specific data entry selection” window.


Version 4.0.0 PAGE 267 OF 317


**ERA ERTMS unit**

**ETCS Driver Machine Interface**




|Col1|Col2|Col3|150<br>100 200<br>0<br>50 300<br>0 400|Col5|Col6|Col7|Col8|Specific data entry selection<br>ATO<br>NTC A NTC B<br>NTC C<br>End of data entry|
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
















|Col1|Col2|Col3|150<br>100 200<br>0<br>50 300<br>0 400|Col5|Col6|Col7|Col8|Col9|Col10|Col11|Specific data entry selection<br>1 - ATO<br>3 - NTC A<br>4 - NTC B<br>5 - NTC C<br>10 - End of data entry|Col13|Col14|Col15|Col16|Col17|
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
||||**0**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**0**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**0**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**0**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**0**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**0**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**0**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**0**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|Specific data entry selection<br>1 - ATO<br>3 - NTC A<br>4 - NTC B<br>5 - NTC C<br>10 - End of data entry|Specific data entry selection<br>1 - ATO<br>3 - NTC A<br>4 - NTC B<br>5 - NTC C<br>10 - End of data entry|Specific data entry selection<br>1 - ATO<br>3 - NTC A<br>4 - NTC B<br>5 - NTC C<br>10 - End of data entry|Specific data entry selection<br>1 - ATO<br>3 - NTC A<br>4 - NTC B<br>5 - NTC C<br>10 - End of data entry|Specific data entry selection<br>1 - ATO<br>3 - NTC A<br>4 - NTC B<br>5 - NTC C<br>10 - End of data entry||
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
|1|1|1||3|3|4|4|5|5||||||10|10|



**Figure 142 – Specific data entry selection window**


**12.3** **Data entry Windows**


**12.3.1** **NTC X data window(s)**


12.3.1.1 The NTC X data window(s) shall comply with the requirements in chapter 10.3 for a
window on total grid array with echo texts and with the question ‘NTC X data entry
complete?’.


Version 4.0.0 PAGE 268 OF 317


**ERA ERTMS unit**

**ETCS Driver Machine Interface**


12.3.1.2 Unless a specific window title is configured on-board (see document [3]), the window title
shall indicate ‘NTC X data’.


12.3.1.3 The part ‘NTC X’ of the window title (if no specific window title is configured) and of the
question ‘NTC X data entry complete?’ shall be replaced with the distinct abbreviations of
the concerned National System.


12.3.1.4 If there are more than one NTC X data window, the window titles shall also comply with
5.3.1.2.1 g) for the indication of the sequence number of the windows and the total number
of windows related to the NTC X data.


12.3.1.5 If technical range check rules have been configured for some NTC X data (see document

[3]), the requirements in chapter 10.3.4 shall apply for the echo texts.


12.3.1.6 The number of input fields, their labels, their possible default values and their associated
keyboards are not mentioned since it varies depending on the content of the received
“specific NTC data entry request” (see step S3-1 in 12.7.2).


12.3.1.6.1 Figure 143 shows the presentation of the NTC X data window(s).


Version 4.0.0 PAGE 269 OF 317


**ERA ERTMS unit**

**ETCS Driver Machine Interface**


















|1|Col2|3|
|---|---|---|
|4|5|6|
|7|8|9|
|Del|0|**.**|
||||









|Col1|NTC A data<br>label 1 data 1<br>label 2 data 2<br>label 1 data 1<br>label 2 data 2<br>1 2 3<br>4 5 6<br>7 8 9<br>NTC A data entry complete? Del 0 .<br>Yes|Col3|
|---|---|---|
|Del<br>2<br>3<br>4<br>7<br>8<br>9<br>0<br>1<br>5<br>6<br>Yes<br>NTC A data<br>label 1<br>label 2<br>data 1<br>data 2<br>data 1<br>label 1<br>label 2<br>data 2<br>NTC A data entry complete?|Del<br>2<br>3<br>4<br>7<br>8<br>9<br>0<br>1<br>5<br>6<br>Yes<br>NTC A data<br>label 1<br>label 2<br>data 1<br>data 2<br>data 1<br>label 1<br>label 2<br>data 2<br>NTC A data entry complete?|Del<br>2<br>3<br>4<br>7<br>8<br>9<br>0<br>1<br>5<br>6<br>Yes<br>NTC A data<br>label 1<br>label 2<br>data 1<br>data 2<br>data 1<br>label 1<br>label 2<br>data 2<br>NTC A data entry complete?|


|NTC A data<br>label 1 data 1<br>label 2 data 2<br>label 1 data 1<br>label 2 data 2<br>NTC A data entry complete?<br>Yes|Col2|Col3|Col4|Col5|Col6|label 1 data 1|Col8|Col9|Col10|Col11|Col12|Col13|
|---|---|---|---|---|---|---|---|---|---|---|---|---|
|Yes<br>NTC A data<br>label 1<br>label 2<br>data 1<br>data 2<br>data 1<br>label 1<br>label 2<br>data 2<br>NTC A data entry complete?|Yes<br>NTC A data<br>label 1<br>label 2<br>data 1<br>data 2<br>data 1<br>label 1<br>label 2<br>data 2<br>NTC A data entry complete?|Yes<br>NTC A data<br>label 1<br>label 2<br>data 1<br>data 2<br>data 1<br>label 1<br>label 2<br>data 2<br>NTC A data entry complete?|Yes<br>NTC A data<br>label 1<br>label 2<br>data 1<br>data 2<br>data 1<br>label 1<br>label 2<br>data 2<br>NTC A data entry complete?|Yes<br>NTC A data<br>label 1<br>label 2<br>data 1<br>data 2<br>data 1<br>label 1<br>label 2<br>data 2<br>NTC A data entry complete?|Yes<br>NTC A data<br>label 1<br>label 2<br>data 1<br>data 2<br>data 1<br>label 1<br>label 2<br>data 2<br>NTC A data entry complete?|data 1<br>label 1|data 1<br>label 1|data 1<br>label 1|data 1<br>label 1|data 1<br>label 1|data 1<br>label 1|Del|
|Yes<br>NTC A data<br>label 1<br>label 2<br>data 1<br>data 2<br>data 1<br>label 1<br>label 2<br>data 2<br>NTC A data entry complete?|Yes<br>NTC A data<br>label 1<br>label 2<br>data 1<br>data 2<br>data 1<br>label 1<br>label 2<br>data 2<br>NTC A data entry complete?|Yes<br>NTC A data<br>label 1<br>label 2<br>data 1<br>data 2<br>data 1<br>label 1<br>label 2<br>data 2<br>NTC A data entry complete?|Yes<br>NTC A data<br>label 1<br>label 2<br>data 1<br>data 2<br>data 1<br>label 1<br>label 2<br>data 2<br>NTC A data entry complete?|Yes<br>NTC A data<br>label 1<br>label 2<br>data 1<br>data 2<br>data 1<br>label 1<br>label 2<br>data 2<br>NTC A data entry complete?|Yes<br>NTC A data<br>label 1<br>label 2<br>data 1<br>data 2<br>data 1<br>label 1<br>label 2<br>data 2<br>NTC A data entry complete?|label 2|label 2|label 2|data 2|data 2|data 2|data 2|
|Yes<br>NTC A data<br>label 1<br>label 2<br>data 1<br>data 2<br>data 1<br>label 1<br>label 2<br>data 2<br>NTC A data entry complete?|Yes<br>NTC A data<br>label 1<br>label 2<br>data 1<br>data 2<br>data 1<br>label 1<br>label 2<br>data 2<br>NTC A data entry complete?|Yes<br>NTC A data<br>label 1<br>label 2<br>data 1<br>data 2<br>data 1<br>label 1<br>label 2<br>data 2<br>NTC A data entry complete?|Yes<br>NTC A data<br>label 1<br>label 2<br>data 1<br>data 2<br>data 1<br>label 1<br>label 2<br>data 2<br>NTC A data entry complete?|Yes<br>NTC A data<br>label 1<br>label 2<br>data 1<br>data 2<br>data 1<br>label 1<br>label 2<br>data 2<br>NTC A data entry complete?|Yes<br>NTC A data<br>label 1<br>label 2<br>data 1<br>data 2<br>data 1<br>label 1<br>label 2<br>data 2<br>NTC A data entry complete?|label 2|label 2|label 2|data 2|data 2|data 2||
|Yes<br>NTC A data<br>label 1<br>label 2<br>data 1<br>data 2<br>data 1<br>label 1<br>label 2<br>data 2<br>NTC A data entry complete?|Yes<br>NTC A data<br>label 1<br>label 2<br>data 1<br>data 2<br>data 1<br>label 1<br>label 2<br>data 2<br>NTC A data entry complete?|Yes<br>NTC A data<br>label 1<br>label 2<br>data 1<br>data 2<br>data 1<br>label 1<br>label 2<br>data 2<br>NTC A data entry complete?|Yes<br>NTC A data<br>label 1<br>label 2<br>data 1<br>data 2<br>data 1<br>label 1<br>label 2<br>data 2<br>NTC A data entry complete?|Yes<br>NTC A data<br>label 1<br>label 2<br>data 1<br>data 2<br>data 1<br>label 1<br>label 2<br>data 2<br>NTC A data entry complete?|Yes<br>NTC A data<br>label 1<br>label 2<br>data 1<br>data 2<br>data 1<br>label 1<br>label 2<br>data 2<br>NTC A data entry complete?|label 2|label 2|label 2|data 2|data 2|data 2||
|Yes<br>NTC A data<br>label 1<br>label 2<br>data 1<br>data 2<br>data 1<br>label 1<br>label 2<br>data 2<br>NTC A data entry complete?|Yes<br>NTC A data<br>label 1<br>label 2<br>data 1<br>data 2<br>data 1<br>label 1<br>label 2<br>data 2<br>NTC A data entry complete?|Yes<br>NTC A data<br>label 1<br>label 2<br>data 1<br>data 2<br>data 1<br>label 1<br>label 2<br>data 2<br>NTC A data entry complete?|Yes<br>NTC A data<br>label 1<br>label 2<br>data 1<br>data 2<br>data 1<br>label 1<br>label 2<br>data 2<br>NTC A data entry complete?|Yes<br>NTC A data<br>label 1<br>label 2<br>data 1<br>data 2<br>data 1<br>label 1<br>label 2<br>data 2<br>NTC A data entry complete?|Yes<br>NTC A data<br>label 1<br>label 2<br>data 1<br>data 2<br>data 1<br>label 1<br>label 2<br>data 2<br>NTC A data entry complete?|label 2|label 2|label 2|data 2|data 2|data 2||
|Yes<br>NTC A data<br>label 1<br>label 2<br>data 1<br>data 2<br>data 1<br>label 1<br>label 2<br>data 2<br>NTC A data entry complete?|Yes<br>NTC A data<br>label 1<br>label 2<br>data 1<br>data 2<br>data 1<br>label 1<br>label 2<br>data 2<br>NTC A data entry complete?|Yes<br>NTC A data<br>label 1<br>label 2<br>data 1<br>data 2<br>data 1<br>label 1<br>label 2<br>data 2<br>NTC A data entry complete?|Yes<br>NTC A data<br>label 1<br>label 2<br>data 1<br>data 2<br>data 1<br>label 1<br>label 2<br>data 2<br>NTC A data entry complete?|Yes<br>NTC A data<br>label 1<br>label 2<br>data 1<br>data 2<br>data 1<br>label 1<br>label 2<br>data 2<br>NTC A data entry complete?|Yes<br>NTC A data<br>label 1<br>label 2<br>data 1<br>data 2<br>data 1<br>label 1<br>label 2<br>data 2<br>NTC A data entry complete?|label 2|label 2|label 2|data 2|data 2|data 2||
|Yes<br>NTC A data<br>label 1<br>label 2<br>data 1<br>data 2<br>data 1<br>label 1<br>label 2<br>data 2<br>NTC A data entry complete?|Yes<br>NTC A data<br>label 1<br>label 2<br>data 1<br>data 2<br>data 1<br>label 1<br>label 2<br>data 2<br>NTC A data entry complete?|Yes<br>NTC A data<br>label 1<br>label 2<br>data 1<br>data 2<br>data 1<br>label 1<br>label 2<br>data 2<br>NTC A data entry complete?|Yes<br>NTC A data<br>label 1<br>label 2<br>data 1<br>data 2<br>data 1<br>label 1<br>label 2<br>data 2<br>NTC A data entry complete?|Yes<br>NTC A data<br>label 1<br>label 2<br>data 1<br>data 2<br>data 1<br>label 1<br>label 2<br>data 2<br>NTC A data entry complete?|Yes<br>NTC A data<br>label 1<br>label 2<br>data 1<br>data 2<br>data 1<br>label 1<br>label 2<br>data 2<br>NTC A data entry complete?|label 2|label 2|label 2|data 2|data 2|data 2||
|Yes|Yes|Yes|Yes|Yes|Yes|Yes|Yes|Yes|Yes|Yes|Yes|Yes|
|1|2|3|4|5|6|6|7|8|8|9|0|0|


**Figure 143 – NTC X data window (1** **[st]** **window)**


**12.3.2** **ATO data window(s)**


12.3.2.1 The ATO data window(s) shall comply with the requirements in chapter 10.3 for a window
on total grid array with echo texts and with the question ‘ATO data entry complete?’.


12.3.2.2 The window title shall indicate “ATO data”.


12.3.2.3 If there are more than one ATO data window, the window titles shall also comply with
5.3.1.2.1 g) for the indication of the sequence number of the windows and the total number
of windows related to the ATO data.


Version 4.0.0 PAGE 270 OF 317


**ERA ERTMS unit**

**ETCS Driver Machine Interface**


12.3.2.4 If technical range check rules have been configured for some ATO data (see document

[5]), the requirements in chapter 10.3.4 shall apply for the echo texts.


12.3.2.5 The number of input fields, their labels, their possible default values and their associated
keyboards are not mentioned since it varies depending on the content of the received
“specific ATO data entry request” (see step S3-1 in 12.7.2).


12.3.2.5.1 Figure 143a shows the presentation of the ATO data window(s).





label 1
label 2



data 1
data 2










|Col1|1|2|3|
|---|---|---|---|
||4|5|6|
||7|8|9|
||Del|0|**.**|
|Yes||||













|ATO data<br>label 1 data 1<br>label 2 data 2<br>label 1 data 1<br>label 2 data 2<br>ATO data entry complete?<br>Yes|Col2|Col3|Col4|Col5|Col6|label 1|Col8|Col9|data 1|Col11|Col12|Col13|
|---|---|---|---|---|---|---|---|---|---|---|---|---|
|ATO data<br>ATO data entry complete?<br>Yes<br>label 1<br>label 2<br>data 1<br>data 2<br>label 1<br>label 2<br>data 1<br>data 2|ATO data<br>ATO data entry complete?<br>Yes<br>label 1<br>label 2<br>data 1<br>data 2<br>label 1<br>label 2<br>data 1<br>data 2|ATO data<br>ATO data entry complete?<br>Yes<br>label 1<br>label 2<br>data 1<br>data 2<br>label 1<br>label 2<br>data 1<br>data 2|ATO data<br>ATO data entry complete?<br>Yes<br>label 1<br>label 2<br>data 1<br>data 2<br>label 1<br>label 2<br>data 1<br>data 2|ATO data<br>ATO data entry complete?<br>Yes<br>label 1<br>label 2<br>data 1<br>data 2<br>label 1<br>label 2<br>data 1<br>data 2|ATO data<br>ATO data entry complete?<br>Yes<br>label 1<br>label 2<br>data 1<br>data 2<br>label 1<br>label 2<br>data 1<br>data 2|label 1|label 1|label 1|data 1|data 1|data 1|Del|
|ATO data<br>ATO data entry complete?<br>Yes<br>label 1<br>label 2<br>data 1<br>data 2<br>label 1<br>label 2<br>data 1<br>data 2|ATO data<br>ATO data entry complete?<br>Yes<br>label 1<br>label 2<br>data 1<br>data 2<br>label 1<br>label 2<br>data 1<br>data 2|ATO data<br>ATO data entry complete?<br>Yes<br>label 1<br>label 2<br>data 1<br>data 2<br>label 1<br>label 2<br>data 1<br>data 2|ATO data<br>ATO data entry complete?<br>Yes<br>label 1<br>label 2<br>data 1<br>data 2<br>label 1<br>label 2<br>data 1<br>data 2|ATO data<br>ATO data entry complete?<br>Yes<br>label 1<br>label 2<br>data 1<br>data 2<br>label 1<br>label 2<br>data 1<br>data 2|ATO data<br>ATO data entry complete?<br>Yes<br>label 1<br>label 2<br>data 1<br>data 2<br>label 1<br>label 2<br>data 1<br>data 2|label 2|label 2|label 2|data 2|data 2|data 2|data 2|
|ATO data<br>ATO data entry complete?<br>Yes<br>label 1<br>label 2<br>data 1<br>data 2<br>label 1<br>label 2<br>data 1<br>data 2|ATO data<br>ATO data entry complete?<br>Yes<br>label 1<br>label 2<br>data 1<br>data 2<br>label 1<br>label 2<br>data 1<br>data 2|ATO data<br>ATO data entry complete?<br>Yes<br>label 1<br>label 2<br>data 1<br>data 2<br>label 1<br>label 2<br>data 1<br>data 2|ATO data<br>ATO data entry complete?<br>Yes<br>label 1<br>label 2<br>data 1<br>data 2<br>label 1<br>label 2<br>data 1<br>data 2|ATO data<br>ATO data entry complete?<br>Yes<br>label 1<br>label 2<br>data 1<br>data 2<br>label 1<br>label 2<br>data 1<br>data 2|ATO data<br>ATO data entry complete?<br>Yes<br>label 1<br>label 2<br>data 1<br>data 2<br>label 1<br>label 2<br>data 1<br>data 2|label 2|label 2|label 2|data 2|data 2|data 2||
|ATO data<br>ATO data entry complete?<br>Yes<br>label 1<br>label 2<br>data 1<br>data 2<br>label 1<br>label 2<br>data 1<br>data 2|ATO data<br>ATO data entry complete?<br>Yes<br>label 1<br>label 2<br>data 1<br>data 2<br>label 1<br>label 2<br>data 1<br>data 2|ATO data<br>ATO data entry complete?<br>Yes<br>label 1<br>label 2<br>data 1<br>data 2<br>label 1<br>label 2<br>data 1<br>data 2|ATO data<br>ATO data entry complete?<br>Yes<br>label 1<br>label 2<br>data 1<br>data 2<br>label 1<br>label 2<br>data 1<br>data 2|ATO data<br>ATO data entry complete?<br>Yes<br>label 1<br>label 2<br>data 1<br>data 2<br>label 1<br>label 2<br>data 1<br>data 2|ATO data<br>ATO data entry complete?<br>Yes<br>label 1<br>label 2<br>data 1<br>data 2<br>label 1<br>label 2<br>data 1<br>data 2|label 2|label 2|label 2|data 2|data 2|data 2||
|ATO data<br>ATO data entry complete?<br>Yes<br>label 1<br>label 2<br>data 1<br>data 2<br>label 1<br>label 2<br>data 1<br>data 2|ATO data<br>ATO data entry complete?<br>Yes<br>label 1<br>label 2<br>data 1<br>data 2<br>label 1<br>label 2<br>data 1<br>data 2|ATO data<br>ATO data entry complete?<br>Yes<br>label 1<br>label 2<br>data 1<br>data 2<br>label 1<br>label 2<br>data 1<br>data 2|ATO data<br>ATO data entry complete?<br>Yes<br>label 1<br>label 2<br>data 1<br>data 2<br>label 1<br>label 2<br>data 1<br>data 2|ATO data<br>ATO data entry complete?<br>Yes<br>label 1<br>label 2<br>data 1<br>data 2<br>label 1<br>label 2<br>data 1<br>data 2|ATO data<br>ATO data entry complete?<br>Yes<br>label 1<br>label 2<br>data 1<br>data 2<br>label 1<br>label 2<br>data 1<br>data 2|label 2|label 2|label 2|data 2|data 2|data 2||
|ATO data<br>ATO data entry complete?<br>Yes<br>label 1<br>label 2<br>data 1<br>data 2<br>label 1<br>label 2<br>data 1<br>data 2|ATO data<br>ATO data entry complete?<br>Yes<br>label 1<br>label 2<br>data 1<br>data 2<br>label 1<br>label 2<br>data 1<br>data 2|ATO data<br>ATO data entry complete?<br>Yes<br>label 1<br>label 2<br>data 1<br>data 2<br>label 1<br>label 2<br>data 1<br>data 2|ATO data<br>ATO data entry complete?<br>Yes<br>label 1<br>label 2<br>data 1<br>data 2<br>label 1<br>label 2<br>data 1<br>data 2|ATO data<br>ATO data entry complete?<br>Yes<br>label 1<br>label 2<br>data 1<br>data 2<br>label 1<br>label 2<br>data 1<br>data 2|ATO data<br>ATO data entry complete?<br>Yes<br>label 1<br>label 2<br>data 1<br>data 2<br>label 1<br>label 2<br>data 1<br>data 2|label 2|label 2|label 2|data 2|data 2|data 2||
|ATO data<br>ATO data entry complete?<br>Yes<br>label 1<br>label 2<br>data 1<br>data 2<br>label 1<br>label 2<br>data 1<br>data 2|ATO data<br>ATO data entry complete?<br>Yes<br>label 1<br>label 2<br>data 1<br>data 2<br>label 1<br>label 2<br>data 1<br>data 2|ATO data<br>ATO data entry complete?<br>Yes<br>label 1<br>label 2<br>data 1<br>data 2<br>label 1<br>label 2<br>data 1<br>data 2|ATO data<br>ATO data entry complete?<br>Yes<br>label 1<br>label 2<br>data 1<br>data 2<br>label 1<br>label 2<br>data 1<br>data 2|ATO data<br>ATO data entry complete?<br>Yes<br>label 1<br>label 2<br>data 1<br>data 2<br>label 1<br>label 2<br>data 1<br>data 2|ATO data<br>ATO data entry complete?<br>Yes<br>label 1<br>label 2<br>data 1<br>data 2<br>label 1<br>label 2<br>data 1<br>data 2|label 2|label 2|label 2|data 2|data 2|data 2||
|Yes|Yes|Yes|Yes|Yes|Yes|Yes|Yes|Yes|Yes|Yes|Yes|Yes|
|1|2|3|4|5|6|6|7|8|8|9|0|0|


**Figure 143a – ATO data window (1** **[st]** **window)**


Version 4.0.0 PAGE 271 OF 317


**ERA ERTMS unit**

**ETCS Driver Machine Interface**


**12.4** **Data validation windows**


**12.4.1** **NTC X data validation window**


12.4.1.1 The NTC X data validation window shall comply with the requirements in chapter 10.4.


12.4.1.2 Unless a specific window title is configured on-board (see document [3]), the window title
shall indicate “Validate NTC X data”.


12.4.1.3 The part ‘NTC X’ of the window title (if no specific window title is configured) shall be
replaced with the distinct abbreviations of the concerned National.


12.4.1.4 The echo texts shall echo data of the NTC X data window(s) (see 12.3.1).


12.4.1.5 Figure 144 shows the presentation of the NTC X data validation window with the data of
the 1 [st] input field modified by the driver and consequently shown in white applying
10.3.3.5.


Version 4.0.0 PAGE 272 OF 317


**ERA ERTMS unit**

**ETCS Driver Machine Interface**
















|Validate NTC A data<br>Yes<br>label 1 data 1<br>label 2 data 2<br>No Yes<br>Validate NTC A data<br>Yes<br>label 1 data 1<br>label 2 data 2|Col2|Col3|Col4|Col5|Col6|Col7|Col8|Col9|Col10|Col11|
|---|---|---|---|---|---|---|---|---|---|---|
|No<br>Yes<br>label 1<br>label 2<br>data 1<br>data 2<br>Validate NTC A data<br>Yes<br>Yes<br>label 1<br>label 2<br>data 1<br>data 2<br>Validate NTC A data|No<br>Yes<br>label 1<br>label 2<br>data 1<br>data 2<br>Validate NTC A data<br>Yes<br>Yes<br>label 1<br>label 2<br>data 1<br>data 2<br>Validate NTC A data|No<br>Yes<br>label 1<br>label 2<br>data 1<br>data 2<br>Validate NTC A data<br>Yes<br>Yes<br>label 1<br>label 2<br>data 1<br>data 2<br>Validate NTC A data|No<br>Yes<br>label 1<br>label 2<br>data 1<br>data 2<br>Validate NTC A data<br>Yes<br>Yes<br>label 1<br>label 2<br>data 1<br>data 2<br>Validate NTC A data|No<br>Yes<br>label 1<br>label 2<br>data 1<br>data 2<br>Validate NTC A data<br>Yes<br>Yes<br>label 1<br>label 2<br>data 1<br>data 2<br>Validate NTC A data|No<br>Yes<br>label 1<br>label 2<br>data 1<br>data 2<br>Validate NTC A data<br>Yes<br>Yes<br>label 1<br>label 2<br>data 1<br>data 2<br>Validate NTC A data|No<br>Yes<br>label 1<br>label 2<br>data 1<br>data 2<br>Validate NTC A data<br>Yes<br>Yes<br>label 1<br>label 2<br>data 1<br>data 2<br>Validate NTC A data|No<br>Yes<br>label 1<br>label 2<br>data 1<br>data 2<br>Validate NTC A data<br>Yes<br>Yes<br>label 1<br>label 2<br>data 1<br>data 2<br>Validate NTC A data|No<br>Yes<br>label 1<br>label 2<br>data 1<br>data 2<br>Validate NTC A data<br>Yes<br>Yes<br>label 1<br>label 2<br>data 1<br>data 2<br>Validate NTC A data|No<br>Yes<br>label 1<br>label 2<br>data 1<br>data 2<br>Validate NTC A data<br>Yes<br>Yes<br>label 1<br>label 2<br>data 1<br>data 2<br>Validate NTC A data||
|No<br>Yes<br>label 1<br>label 2<br>data 1<br>data 2<br>Validate NTC A data<br>Yes<br>Yes<br>label 1<br>label 2<br>data 1<br>data 2<br>Validate NTC A data|No<br>Yes<br>label 1<br>label 2<br>data 1<br>data 2<br>Validate NTC A data<br>Yes<br>Yes<br>label 1<br>label 2<br>data 1<br>data 2<br>Validate NTC A data|No<br>Yes<br>label 1<br>label 2<br>data 1<br>data 2<br>Validate NTC A data<br>Yes<br>Yes<br>label 1<br>label 2<br>data 1<br>data 2<br>Validate NTC A data|No<br>Yes<br>label 1<br>label 2<br>data 1<br>data 2<br>Validate NTC A data<br>Yes<br>Yes<br>label 1<br>label 2<br>data 1<br>data 2<br>Validate NTC A data|No<br>Yes<br>label 1<br>label 2<br>data 1<br>data 2<br>Validate NTC A data<br>Yes<br>Yes<br>label 1<br>label 2<br>data 1<br>data 2<br>Validate NTC A data|No<br>Yes<br>label 1<br>label 2<br>data 1<br>data 2<br>Validate NTC A data<br>Yes<br>Yes<br>label 1<br>label 2<br>data 1<br>data 2<br>Validate NTC A data|No<br>Yes<br>label 1<br>label 2<br>data 1<br>data 2<br>Validate NTC A data<br>Yes<br>Yes<br>label 1<br>label 2<br>data 1<br>data 2<br>Validate NTC A data|No<br>Yes<br>label 1<br>label 2<br>data 1<br>data 2<br>Validate NTC A data<br>Yes<br>Yes<br>label 1<br>label 2<br>data 1<br>data 2<br>Validate NTC A data|No<br>Yes<br>label 1<br>label 2<br>data 1<br>data 2<br>Validate NTC A data<br>Yes<br>Yes<br>label 1<br>label 2<br>data 1<br>data 2<br>Validate NTC A data|No<br>Yes<br>label 1<br>label 2<br>data 1<br>data 2<br>Validate NTC A data<br>Yes<br>Yes<br>label 1<br>label 2<br>data 1<br>data 2<br>Validate NTC A data||
|No<br>Yes<br>label 1<br>label 2<br>data 1<br>data 2<br>Validate NTC A data<br>Yes<br>Yes<br>label 1<br>label 2<br>data 1<br>data 2<br>Validate NTC A data|No<br>Yes<br>label 1<br>label 2<br>data 1<br>data 2<br>Validate NTC A data<br>Yes<br>Yes<br>label 1<br>label 2<br>data 1<br>data 2<br>Validate NTC A data|No<br>Yes<br>label 1<br>label 2<br>data 1<br>data 2<br>Validate NTC A data<br>Yes<br>Yes<br>label 1<br>label 2<br>data 1<br>data 2<br>Validate NTC A data|No<br>Yes<br>label 1<br>label 2<br>data 1<br>data 2<br>Validate NTC A data<br>Yes<br>Yes<br>label 1<br>label 2<br>data 1<br>data 2<br>Validate NTC A data|No<br>Yes<br>label 1<br>label 2<br>data 1<br>data 2<br>Validate NTC A data<br>Yes<br>Yes<br>label 1<br>label 2<br>data 1<br>data 2<br>Validate NTC A data|No<br>Yes<br>label 1<br>label 2<br>data 1<br>data 2<br>Validate NTC A data<br>Yes<br>Yes<br>label 1<br>label 2<br>data 1<br>data 2<br>Validate NTC A data|No<br>Yes<br>label 1<br>label 2<br>data 1<br>data 2<br>Validate NTC A data<br>Yes<br>Yes<br>label 1<br>label 2<br>data 1<br>data 2<br>Validate NTC A data|No<br>Yes<br>label 1<br>label 2<br>data 1<br>data 2<br>Validate NTC A data<br>Yes<br>Yes<br>label 1<br>label 2<br>data 1<br>data 2<br>Validate NTC A data|No<br>Yes<br>label 1<br>label 2<br>data 1<br>data 2<br>Validate NTC A data<br>Yes<br>Yes<br>label 1<br>label 2<br>data 1<br>data 2<br>Validate NTC A data|No<br>Yes<br>label 1<br>label 2<br>data 1<br>data 2<br>Validate NTC A data<br>Yes<br>Yes<br>label 1<br>label 2<br>data 1<br>data 2<br>Validate NTC A data||
|No<br>Yes<br>label 1<br>label 2<br>data 1<br>data 2<br>Validate NTC A data<br>Yes<br>Yes<br>label 1<br>label 2<br>data 1<br>data 2<br>Validate NTC A data|No<br>Yes<br>label 1<br>label 2<br>data 1<br>data 2<br>Validate NTC A data<br>Yes<br>Yes<br>label 1<br>label 2<br>data 1<br>data 2<br>Validate NTC A data|No<br>Yes<br>label 1<br>label 2<br>data 1<br>data 2<br>Validate NTC A data<br>Yes<br>Yes<br>label 1<br>label 2<br>data 1<br>data 2<br>Validate NTC A data|No<br>Yes<br>label 1<br>label 2<br>data 1<br>data 2<br>Validate NTC A data<br>Yes<br>Yes<br>label 1<br>label 2<br>data 1<br>data 2<br>Validate NTC A data|No<br>Yes<br>label 1<br>label 2<br>data 1<br>data 2<br>Validate NTC A data<br>Yes<br>Yes<br>label 1<br>label 2<br>data 1<br>data 2<br>Validate NTC A data|No<br>Yes<br>label 1<br>label 2<br>data 1<br>data 2<br>Validate NTC A data<br>Yes<br>Yes<br>label 1<br>label 2<br>data 1<br>data 2<br>Validate NTC A data|No<br>Yes<br>label 1<br>label 2<br>data 1<br>data 2<br>Validate NTC A data<br>Yes<br>Yes<br>label 1<br>label 2<br>data 1<br>data 2<br>Validate NTC A data|No<br>Yes<br>label 1<br>label 2<br>data 1<br>data 2<br>Validate NTC A data<br>Yes<br>Yes<br>label 1<br>label 2<br>data 1<br>data 2<br>Validate NTC A data|No<br>Yes<br>label 1<br>label 2<br>data 1<br>data 2<br>Validate NTC A data<br>Yes<br>Yes<br>label 1<br>label 2<br>data 1<br>data 2<br>Validate NTC A data|No<br>Yes<br>label 1<br>label 2<br>data 1<br>data 2<br>Validate NTC A data<br>Yes<br>Yes<br>label 1<br>label 2<br>data 1<br>data 2<br>Validate NTC A data||
|No<br>Yes<br>label 1<br>label 2<br>data 1<br>data 2<br>Validate NTC A data<br>Yes<br>Yes<br>label 1<br>label 2<br>data 1<br>data 2<br>Validate NTC A data|No<br>Yes<br>label 1<br>label 2<br>data 1<br>data 2<br>Validate NTC A data<br>Yes<br>Yes<br>label 1<br>label 2<br>data 1<br>data 2<br>Validate NTC A data|No<br>Yes<br>label 1<br>label 2<br>data 1<br>data 2<br>Validate NTC A data<br>Yes<br>Yes<br>label 1<br>label 2<br>data 1<br>data 2<br>Validate NTC A data|No<br>Yes<br>label 1<br>label 2<br>data 1<br>data 2<br>Validate NTC A data<br>Yes<br>Yes<br>label 1<br>label 2<br>data 1<br>data 2<br>Validate NTC A data|No<br>Yes<br>label 1<br>label 2<br>data 1<br>data 2<br>Validate NTC A data<br>Yes<br>Yes<br>label 1<br>label 2<br>data 1<br>data 2<br>Validate NTC A data|No<br>Yes<br>label 1<br>label 2<br>data 1<br>data 2<br>Validate NTC A data<br>Yes<br>Yes<br>label 1<br>label 2<br>data 1<br>data 2<br>Validate NTC A data|No<br>Yes<br>label 1<br>label 2<br>data 1<br>data 2<br>Validate NTC A data<br>Yes<br>Yes<br>label 1<br>label 2<br>data 1<br>data 2<br>Validate NTC A data|No<br>Yes<br>label 1<br>label 2<br>data 1<br>data 2<br>Validate NTC A data<br>Yes<br>Yes<br>label 1<br>label 2<br>data 1<br>data 2<br>Validate NTC A data|No<br>Yes<br>label 1<br>label 2<br>data 1<br>data 2<br>Validate NTC A data<br>Yes<br>Yes<br>label 1<br>label 2<br>data 1<br>data 2<br>Validate NTC A data|No<br>Yes<br>label 1<br>label 2<br>data 1<br>data 2<br>Validate NTC A data<br>Yes<br>Yes<br>label 1<br>label 2<br>data 1<br>data 2<br>Validate NTC A data||
|No<br>Yes<br>label 1<br>label 2<br>data 1<br>data 2<br>Validate NTC A data<br>Yes<br>Yes<br>label 1<br>label 2<br>data 1<br>data 2<br>Validate NTC A data|No<br>Yes<br>label 1<br>label 2<br>data 1<br>data 2<br>Validate NTC A data<br>Yes<br>Yes<br>label 1<br>label 2<br>data 1<br>data 2<br>Validate NTC A data|No<br>Yes<br>label 1<br>label 2<br>data 1<br>data 2<br>Validate NTC A data<br>Yes<br>Yes<br>label 1<br>label 2<br>data 1<br>data 2<br>Validate NTC A data|No<br>Yes<br>label 1<br>label 2<br>data 1<br>data 2<br>Validate NTC A data<br>Yes<br>Yes<br>label 1<br>label 2<br>data 1<br>data 2<br>Validate NTC A data|No<br>Yes<br>label 1<br>label 2<br>data 1<br>data 2<br>Validate NTC A data<br>Yes<br>Yes<br>label 1<br>label 2<br>data 1<br>data 2<br>Validate NTC A data|No<br>Yes<br>label 1<br>label 2<br>data 1<br>data 2<br>Validate NTC A data<br>Yes<br>Yes<br>label 1<br>label 2<br>data 1<br>data 2<br>Validate NTC A data|No<br>Yes<br>label 1<br>label 2<br>data 1<br>data 2<br>Validate NTC A data<br>Yes<br>Yes<br>label 1<br>label 2<br>data 1<br>data 2<br>Validate NTC A data|No<br>Yes<br>label 1<br>label 2<br>data 1<br>data 2<br>Validate NTC A data<br>Yes<br>Yes<br>label 1<br>label 2<br>data 1<br>data 2<br>Validate NTC A data|No<br>Yes<br>label 1<br>label 2<br>data 1<br>data 2<br>Validate NTC A data<br>Yes<br>Yes<br>label 1<br>label 2<br>data 1<br>data 2<br>Validate NTC A data|No<br>Yes<br>label 1<br>label 2<br>data 1<br>data 2<br>Validate NTC A data<br>Yes<br>Yes<br>label 1<br>label 2<br>data 1<br>data 2<br>Validate NTC A data||
|||||||No|Yes||||
||||||||||||



**Figure 144 – NTC X data validation window**


**12.4.2** **ATO data validation window**


12.4.2.1 The ATO data validation window shall comply with the requirements in chapter 10.4.


12.4.2.2 The window title shall indicate “Validate ATO data”.


12.4.2.3 The echo texts shall echo data of the ATO data window(s) (see 12.3.2).


Version 4.0.0 PAGE 273 OF 317


**ERA ERTMS unit**

**ETCS Driver Machine Interface**


12.4.2.4 Figure 144a shows the presentation of the ATO data validation window with the data of
the 1 [st] input field modified by the driver and consequently shown in white applying
10.3.3.5.



















|Validate ATO data<br>Yes<br>label 1 data 1<br>label 2 data 2<br>Yes|Col2|Col3|Col4|Col5|Col6|Yes|Col8|Col9|Col10|Col11|Col12|
|---|---|---|---|---|---|---|---|---|---|---|---|
|Yes<br>Yes<br>label 1<br>label 2<br>data 1<br>data 2<br>Validate ATO data|Yes<br>Yes<br>label 1<br>label 2<br>data 1<br>data 2<br>Validate ATO data|Yes<br>Yes<br>label 1<br>label 2<br>data 1<br>data 2<br>Validate ATO data|Yes<br>Yes<br>label 1<br>label 2<br>data 1<br>data 2<br>Validate ATO data|Yes<br>Yes<br>label 1<br>label 2<br>data 1<br>data 2<br>Validate ATO data|Yes<br>Yes<br>label 1<br>label 2<br>data 1<br>data 2<br>Validate ATO data|Yes|Yes|Yes|Yes|Yes||
|Yes<br>Yes<br>label 1<br>label 2<br>data 1<br>data 2<br>Validate ATO data|Yes<br>Yes<br>label 1<br>label 2<br>data 1<br>data 2<br>Validate ATO data|Yes<br>Yes<br>label 1<br>label 2<br>data 1<br>data 2<br>Validate ATO data|Yes<br>Yes<br>label 1<br>label 2<br>data 1<br>data 2<br>Validate ATO data|Yes<br>Yes<br>label 1<br>label 2<br>data 1<br>data 2<br>Validate ATO data|Yes<br>Yes<br>label 1<br>label 2<br>data 1<br>data 2<br>Validate ATO data|Yes|Yes|Yes|Yes|Yes||
|Yes<br>Yes<br>label 1<br>label 2<br>data 1<br>data 2<br>Validate ATO data|Yes<br>Yes<br>label 1<br>label 2<br>data 1<br>data 2<br>Validate ATO data|Yes<br>Yes<br>label 1<br>label 2<br>data 1<br>data 2<br>Validate ATO data|Yes<br>Yes<br>label 1<br>label 2<br>data 1<br>data 2<br>Validate ATO data|Yes<br>Yes<br>label 1<br>label 2<br>data 1<br>data 2<br>Validate ATO data|Yes<br>Yes<br>label 1<br>label 2<br>data 1<br>data 2<br>Validate ATO data|Yes|Yes|Yes|Yes|Yes||
|Yes<br>Yes<br>label 1<br>label 2<br>data 1<br>data 2<br>Validate ATO data|Yes<br>Yes<br>label 1<br>label 2<br>data 1<br>data 2<br>Validate ATO data|Yes<br>Yes<br>label 1<br>label 2<br>data 1<br>data 2<br>Validate ATO data|Yes<br>Yes<br>label 1<br>label 2<br>data 1<br>data 2<br>Validate ATO data|Yes<br>Yes<br>label 1<br>label 2<br>data 1<br>data 2<br>Validate ATO data|Yes<br>Yes<br>label 1<br>label 2<br>data 1<br>data 2<br>Validate ATO data|Yes|Yes|Yes|Yes|Yes||
|Yes<br>Yes<br>label 1<br>label 2<br>data 1<br>data 2<br>Validate ATO data|Yes<br>Yes<br>label 1<br>label 2<br>data 1<br>data 2<br>Validate ATO data|Yes<br>Yes<br>label 1<br>label 2<br>data 1<br>data 2<br>Validate ATO data|Yes<br>Yes<br>label 1<br>label 2<br>data 1<br>data 2<br>Validate ATO data|Yes<br>Yes<br>label 1<br>label 2<br>data 1<br>data 2<br>Validate ATO data|Yes<br>Yes<br>label 1<br>label 2<br>data 1<br>data 2<br>Validate ATO data|Yes|Yes|Yes|Yes|Yes||
|Yes<br>Yes<br>label 1<br>label 2<br>data 1<br>data 2<br>Validate ATO data|Yes<br>Yes<br>label 1<br>label 2<br>data 1<br>data 2<br>Validate ATO data|Yes<br>Yes<br>label 1<br>label 2<br>data 1<br>data 2<br>Validate ATO data|Yes<br>Yes<br>label 1<br>label 2<br>data 1<br>data 2<br>Validate ATO data|Yes<br>Yes<br>label 1<br>label 2<br>data 1<br>data 2<br>Validate ATO data|Yes<br>Yes<br>label 1<br>label 2<br>data 1<br>data 2<br>Validate ATO data|Yes|Yes|Yes|Yes|Yes||
|Yes|Yes|Yes|Yes|Yes|Yes|Yes|Yes|Yes|Yes|Yes|Yes|
||||||||No|Yes||||


**Figure 144a – ATO data validation window**


**12.5** **Data view windows**


**12.5.1** **NTC X data view window**


12.5.1.1 The NTC X data view window(s) shall comply with the requirements in chapter 10.5.


Version 4.0.0 PAGE 274 OF 317


**ERA ERTMS unit**

**ETCS Driver Machine Interface**


12.5.1.2 Unless a specific window title is configured on-board (see document [3]), the window titles
shall indicate “NTC X data view”.


12.5.1.3 The part ‘NTC X’ of the window title (if no specific window title is configured) shall be
replaced with the distinct abbreviations of the concerned National System.


12.5.1.4 If there are more than one NTC X data view window, the window titles shall also comply
with 5.3.1.2.1 g) for the indication of the sequence number of the windows and the total
number of windows related to the NTC X Data view.


12.5.1.5 The NTC X data view items shall correspond to the received Specific NTC Data View
values (see document [3]).


12.5.1.6 The data view windows of all the National Systems available on-board shall be considered
as an extension of the ETCS (see 11.5.1) and ATO (see 12.5.2) data view windows. In
other terms, the 1 [st] NTC X data view window is accessed by pressing the [Next] button on
the last ATO Data view window, the 1 [st] NTC Y data view window is accessed by pressing
the [Next] button on the last NTC X data view window,...


12.5.1.6.1 Note: the sequence order of data view windows between the different National Systems

available on-board (NTC X, NTC Y,...) is an implementation issue.


12.5.1.7 Figure 145 shows the presentation of a NTC X data view window.


Version 4.0.0 PAGE 275 OF 317


**ERA ERTMS unit**

**ETCS Driver Machine Interface**






|Col1|Col2|Col3|150<br>100 200<br>0<br>50 300<br>0 400|Col5|Col6|Col7|Col8|NTC A data view<br>label 1 data<br>label 2 data|Col10|Col11|
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












|Col1|Col2|Col3|150<br>100 200<br>0<br>50 300<br>0 400|Col5|Col6|Col7|Col8|Col9|Col10|Col11|NTC A data view<br>label 1 data 1<br>label 2 data 2|Col13|Col14|Col15|Col16|Col17|
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
||||**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**<br>**0**|**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**<br>**0**|**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**<br>**0**|**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**<br>**0**|**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**<br>**0**|**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**<br>**0**|**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**<br>**0**|**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**<br>**0**|NTC A data view<br>label 1<br>label 2<br>data 1<br>data 2|NTC A data view<br>label 1<br>label 2<br>data 1<br>data 2|NTC A data view<br>label 1<br>label 2<br>data 1<br>data 2|NTC A data view<br>label 1<br>label 2<br>data 1<br>data 2|NTC A data view<br>label 1<br>label 2<br>data 1<br>data 2||
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



**Figure 145 – NTC X data view window**


**12.5.2** **ATO data view window**


12.5.2.1 The ATO data view window(s) shall comply with the requirements in chapter 10.5.


12.5.2.2 The window titles shall indicate “ATO data view”.


12.5.2.3 If there are more than one ATO data view window, the window titles shall also comply with
5.3.1.2.1 g) for the indication of the sequence number of the windows and the total number
of windows related to the ATO Data view.


Version 4.0.0 PAGE 276 OF 317


**ERA ERTMS unit**

**ETCS Driver Machine Interface**


12.5.2.4 The ATO data view items shall correspond to the received Specific ATO Data View values
(see document [5]).


12.5.2.5 The ATO data view windows shall be considered as an extension of the ETCS data view
windows (see 11.5.1). In other terms, the 1 [st] ATO data view window is accessed by
pressing the [Next] button on the last ETCS Data view window


12.5.2.6 Figure 145a shows the presentation of a ATO data view window.










|Col1|Col2|Col3|150<br>100 200<br>0<br>50 300<br>0 400|Col5|Col6|Col7|Col8|ATO data view<br>label 1 data<br>label 2 data|Col10|Col11|
|---|---|---|---|---|---|---|---|---|---|---|
||||||||||||
||||||||||||
|**2**|**2**|**2**|||||||||
||||||||||||
||||||||||||
||||||||||||
||||||||||||
||||||||||||
||||||||||||








|Col1|Col2|Col3|150<br>100 200<br>0<br>50 300<br>0 400|Col5|Col6|Col7|Col8|Col9|Col10|Col11|ATO data view<br>label 1 data 1<br>label 2 data 2|Col13|Col14|Col15|Col16|Col17|
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
||||**0**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**0**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**0**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**0**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**0**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**0**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**0**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**0**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|label 1<br>label 2<br>data 1<br>data 2<br>ATO data view|label 1<br>label 2<br>data 1<br>data 2<br>ATO data view|label 1<br>label 2<br>data 1<br>data 2<br>ATO data view|label 1<br>label 2<br>data 1<br>data 2<br>ATO data view|label 1<br>label 2<br>data 1<br>data 2<br>ATO data view||
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



**Figure 145a – ATO data view window**


Version 4.0.0 PAGE 277 OF 317


**ERA ERTMS unit**

**ETCS Driver Machine Interface**


Version 4.0.0 PAGE 278 OF 317


**ERA ERTMS unit**

**ETCS Driver Machine Interface**


**12.6** **Parent/child relationship**


12.6.1.1 With regards to the use of the close button, the relationship between parent and child
windows shall be as specified in Table 56.


12.6.1.1.1 Note: The cell “Default” refers to the default window. Its layout depends on the current

ERTMS/ETCS level and mode (e.g. it could be the ETCS default window when operating
in level 1/2 or the NTC X default window when operating in level NTC X, mode SN or NL)









|Parent/child relationship<br>(from left to right = from parent to child)|Col2|Col3|Col4|
|---|---|---|---|
|Default|Main|Specific data entry<br>selection<br>_(accessible via the Train data_<br>_validation window)_|ATO data<br>_(one or more windows)_|
|Default|Main|Specific data entry<br>selection<br>_(accessible via the Train data_<br>_validation window)_|ATO data validation<br>_(accessible via ATO data_<br>_windows)_|
|Default|Main|Specific data entry<br>selection<br>_(accessible via the Train data_<br>_validation window)_|NTC A data<br>_(one or more windows)_|
|Default|Main|Specific data entry<br>selection<br>_(accessible via the Train data_<br>_validation window)_|NTC A data validation<br>_(accessible via NTC A data_<br>_windows)_|
|Default|Main|Specific data entry<br>selection<br>_(accessible via the Train data_<br>_validation window)_|NTC B data<br>_(one or more windows)_|
|Default|Main|Specific data entry<br>selection<br>_(accessible via the Train data_<br>_validation window)_|NTC B data validation<br>_(accessible via NTC B data_<br>_windows)_|
|Default|Main|Specific data entry<br>selection<br>_(accessible via the Train data_<br>_validation window)_|...|


**Table 56 – Parent/child relationship**


**12.7** **Dialogue sequences**


**12.7.1** **Introduction**


12.7.1.1 The latest active window including the mentioned configuration of objects/symbols (e.g.
the main window with all buttons disabled and the hour glass symbol ST05 displayed)
shall remain displayed until another window or another configuration of the same window
is mentioned further on in the flowchart.


12.7.1.2 When an event involves a driver’s action on a button, it assumes that the corresponding
button is enabled (see 12.2 for the conditions enabling a button).


12.7.1.3 If one of the windows mentioned in Table 57 is currently displayed and any of the enabling
conditions (see 12.2) of the corresponding button is not fulfilled anymore, the data entry /
validation process shall be stopped and the parent window shall be displayed instead.


Version 4.0.0 PAGE 279 OF 317


**ERA ERTMS unit**

**ETCS Driver Machine Interface**

|Window|Corresponding button for<br>checking the enabling<br>conditions|
|---|---|
|ATO data|ATO|
|ATO data validation|ATO|
|NTC A data|NTC A|
|NTC A data validation|NTC A|
|NTC B data|NTC B|
|NTC B data validation|NTC B|
|...|...|



**Table 57 – Relationship between windows and enabling conditions of buttons**


12.7.1.4 If a data entry or validation window is currently displayed when a driver’s
acknowledgement is required, the data entry / validation process shall be stopped, the
parent window shall be displayed instead and the driver’s acknowledgement shall appear
1 second afterwards.


**12.7.2** **ATO & NTC data dialogue sequence**


12.7.2.1 The “ATO & NTC data” dialogue sequence shows the interaction with the driver following
the ETCS Train data validation while at least one of those systems needs, by design,
specific data from the driver to perform its national supervision, i.e. at least one STM has
sent a ‘Specific NTC Data Need’ information indicating that it needs Specific NTC Data
(see document [3], 8.2.1.4) or the ERTMS/ATO on-board has sent a ‘Specific ATO Data
Need’ information indicating that it needs Specific ATO Data (see document [5], 9.3.1.3)


12.7.2.2 The [close] buttons shall be enabled in all windows except in the steps S1 and S4 where
they shall be disabled.


12.7.2.3 If the driver presses the [close] button in the step S2, the ERTMS/ETCS on-board
equipment shall abort the (full) train data entry procedure


12.7.2.3.1 Note: According to documents [3] & [5], the ‘STOP’ flag will consequently be sent to all

the connected STMs and the ERTMS/ATO on-board when the [close] button is pressed
in step S2. Conversely, when the [close] button is pressed in the step S3-1 or S3-2, the
NTC X data entry/validation process is only interrupted and no ‘STOP’ flag is sent in that
case.


Version 4.0.0 PAGE 280 OF 317


**ERA ERTMS unit**

**ETCS Driver Machine Interface**
















|S1<br>Specific data entry selection window with all buttons disabled<br>except the ‘End of data entry’.<br>The hour glass symbol ST05 is displayed|Col2|
|---|---|
|||
|reception of ‘specific NTC data ent<br>for all NTCs t<br>A<br>reception of ‘specific ATO data ent<br>if the ATO on-b|y request’ or sending of ‘STOP’ flag<br>   hat need data<br>ND<br>     ry request’ or sending of ‘STOP’ flag<br>   oard needs data|





































NTC X data


**Figure 146 – ATO & NTC data dialogue sequence**



ATO data



Version 4.0.0 PAGE 281 OF 317


**ERA ERTMS unit**

**ETCS Driver Machine Interface**


12.7.2.4 The steps of the “ATO & NTC data” dialogue sequence shall follow Table 58.











|ID in Flow<br>Chart|Requirements|Window|
|---|---|---|
|**S3-2,**<br>**Main**<br>**dialogue**<br>**sequence**|The **Train data validation window** requests the driver to validate or not the values<br>of the input fields for ETCS train data.<br>Once the input field for train data validation is entered or revalidated with the value<br>‘Yes’, the procedure shall go to**D1**(instead of D6 of the “Main window” dialogue<br>sequence)|Figure 130 – Train data validation window|
|**D1**|If at least one NTC or the ERTMS/ATO on-board needs data i.e. at least one STM<br>has sent a ‘Specific NTC Data Need’ information indicating that it needs Specific<br>NTC Data or the ERTMS/ATO on-board has sent a ‘Specific ATO Data Need’<br>information indicating that it needs Specific ATO Data, the procedure shall go to<br>**S1**; otherwise it shall go to**D6** in the “Main window” dialogue sequence.||


Version 4.0.0 PAGE 282 OF 317


**ERA ERTMS unit**

**ETCS Driver Machine Interface**






|ID in Flow<br>Chart|Requirements|Window|
|---|---|---|
|**S1**|The**Specific data entry selection window** shall be presented to the driver with<br>all buttons ‘disabled’ except the ‘End of data entry’ button.<br>The symbol**ST05** shall be displayed to show that the ERTMS/ETCS on-board<br>awaits an answer from all the connected STMs supporting NTCs that need specific<br>data and from the ERTMS/ATO on-board if it needs specific data.<br>Note: When the ETCS Train data are validated (step S3-2, Main dialogue<br>sequence), the START flag is sent and then it is followed by the sending of the<br>ETCS Train data (see documents [3] & [5]).<br>The procedure shall go to**S2** when the ERTMS/ETCS on-board equipment: <br>• <br>has either received a ‘Specific NTC data entry request’ or has sent the<br>‘STOP’ flag (see document [3], 10.7.4.3 a) and b)) for each concerned<br>STM <br>AND<br>• <br>has either received a ‘Specific ATO data entry request’ or has sent the<br>‘STOP’ flag (see document [5], 7.14.2.22 a) and b)) if the ERTMS/ATO<br>on-board needs data <br>The driver can choose to skip at once the data entry/validation process of all<br>systems: If the driver presses ‘End of data entry’, the procedure shall immediately<br>go to**D6**in the “Main window” dialogue sequence.<br>Note: When the driver presses ‘End of data entry’, the ERTMS/ETCS on-board<br>sends a ‘STOP’ flag (see documents [3] & [5]) to those systems to which no ‘STOP’<br>flag has been sent yet.|Figure 142 – Specific data entry selection window|



Version 4.0.0 PAGE 283 OF 317


**ERA ERTMS unit**

**ETCS Driver Machine Interface**






|ID in Flow<br>Chart|Requirements|Window|
|---|---|---|
|**S2**|The**Specific data entry selection window** shall offer the possibility to the driver<br>to select ‘ATO’, ‘NTC A’, ‘NTC B’,... and ‘End of data entry’<br>• <br>If the driver presses ‘NTC X’, the procedure shall go to**S3-1**. <br>Note: the button ‘NTC X’ represents any of the enabled NTC buttons (‘NTC A’,<br>‘NTC B’, ...)<br>• <br>If the driver presses ‘ATO’, the procedure shall go to**S5-1.** <br>• <br>If the driver presses ‘End of data entry’, the procedure shall go to**D6**in<br>the “Main window” dialogue sequence i.e. it allows the driver to skip some<br>specific data entry/validation processes that are not needed for the<br>mission.<br>Note: When the driver presses ‘End of data entry’, the ERTMS/ETCS on-board<br>sends a ‘STOP’ flag (see documents [3] & [5]) to those systems to which no ‘STOP’<br>flag has been sent yet.|Figure 142 – Specific data entry selection window|
|**S3-1**|When entering**S3-1**, the 1st **NTC X data window** shall be presented to the driver<br>to initiate to entry of NTC X data.<br>The**NTC X data window(s)** shall request the driver to enter (if no value is<br>proposed) or to accept / re-enter (if a value is proposed) each input field for NTC<br>X data.<br>The labels of the input fields for NTC X data shall correspond to the labels<br>contained in the “specific NTC data entry request”.<br>An alphanumeric keyboard shall by default be presented for an input field, unless<br>values for a dedicated keyboard have been received in the “specific NTC data entry<br>request” or the type of keyboard is configured on-board (see document [3]).|Figure 143 – NTC X data window (1st window)|



Version 4.0.0 PAGE 284 OF 317


**ERA ERTMS unit**

**ETCS Driver Machine Interface**

|ID in Flow<br>Chart|Requirements|Window|
|---|---|---|
||When the ERTMS/ETCS on-board receives values for a dedicated keyboard as<br>part of the “Specific NTC Data request”, it shall display the dedicated keyboard<br>when the corresponding input field is selected.<br>When no values for a dedicated keyboard have been received in the “specific NTC<br>data entry request” but a type of keyboard is configured on-board, the<br>ERTMS/ETCS on-board shall display this type of keyboard.<br>If**S3-1** is entered from**S2**(i.e. the NTC X data entry / validation process starts<br>following a driver action on the ‘NTC X’ button) or from** S4**(i.e. a new NTC X data<br>entry / validation process starts following a new specific NTC data entry request<br>from the STM supporting NTC X):<br>• <br>If a value is proposed, it corresponds to the default value received in the<br>specific NTC data entry request<br>If**S3-1** is entered from**S3-2** (i.e. the NTC X data entry / validation process is going<br>on):<br>• <br>The proposed value for each input field shall be the data value from the<br>previous**S3-1**. <br>When the ‘Yes’ button related to the ‘NTC X data entry complete?’ question is<br>enabled (i.e. every input field for NTC X data in all ‘NTC X data’ windows contains<br>a data value), if the driver presses this ‘Yes’ button and all data values comply with<br>the data checks, the procedure shall go to**S3-2** <br>Note: In this step, when the driver presses the ‘Yes’ button, NTC X data are not<br>validated yet and consequently are not yet the NTC X data sent to the STM<br>supporting the NTC X. This is why the term “accept” is used instead of the term<br>“revalidate” and the term “input field for NTC X data” is used instead of “NTC X<br>data”.||



Version 4.0.0 PAGE 285 OF 317


**ERA ERTMS unit**

**ETCS Driver Machine Interface**






|ID in Flow<br>Chart|Requirements|Window|
|---|---|---|
|**S3-2**|The**NTC X data validation window** shall request the driver to validate or not the<br>values of the input fields for NTC X data.<br>When entering**S3-2**, the NTC X data validation window shall always propose the<br>value ‘Yes’ in the input field for NTC X data validation.<br>Once the input field for NTC X data validation is entered or revalidated, if the value<br>is ‘No’, the procedure shall go back to**S3-1**. Otherwise, if the value is ‘Yes’, the<br>procedure shall go to**S4**<br>Note: In this step, when the NTC X data validation window is left with the value of<br>its input field set to ‘Yes’, NTC X data are sent to the STM supporting the NTC X.|Figure 144 – NTC X data validation window|



Version 4.0.0 PAGE 286 OF 317


**ERA ERTMS unit**

**ETCS Driver Machine Interface**






|ID in Flow<br>Chart|Requirements|Window|
|---|---|---|
|**S4**|The**Specific data entry selection window** shall be presented to the driver with<br>all buttons ‘disabled’.<br>If**S4** is entered from**S3-2**(i.e. a specific NTC X data entry is on-going):<br>The symbol**ST05** shall be displayed to show that the ERTMS/ETCS on-board<br>awaits an answer from the STM supporting NTC X.<br>If the ERTMS/ETCS on-board equipment receives a new ‘Specific NTC data entry<br>request’ from the STM supporting NTC X, the procedure shall go back to**S3-1** <br>If the ERTMS/ETCS on-board equipment sends the ‘STOP’ flag (see document<br>[3], 10.7.4.3 a) and b)) to the STM supporting NTC X, the procedure shall go to**S2**<br>If**S4** is entered from**S5-2**(i.e. a specific ATO data entry is on-going):<br>The symbol**ST05** shall be displayed to show that the ERTMS/ETCS on-board<br>awaits an answer from the ERTMS/ATO on-board.<br>If the ERTMS/ETCS on-board equipment receives a new ‘Specific ATO data entry<br>request’ from the ERTMS/ATO on-board, the procedure shall go back to**S5-1** <br>If the ERTMS/ETCS on-board equipment sends the ‘STOP’ flag (see document<br>[5], 7.14.2.22 a) and b)) to the ERTMS/ATO on-board, the procedure shall go to<br>**S2**|Figure 142 – Specific data entry selection window|



Version 4.0.0 PAGE 287 OF 317


**ERA ERTMS unit**

**ETCS Driver Machine Interface**





Version 4.0.0 PAGE 288 OF 317


**ERA ERTMS unit**

**ETCS Driver Machine Interface**



|ID in Flow<br>Chart|Requirements|Window|
|---|---|---|
||When the ‘Yes’ button related to the ‘ATO data entry complete?’ question is<br>enabled (i.e. every input field for ATO data in all ‘ATO data’ windows contains a<br>data value), if the driver presses this ‘Yes’ button and all data values comply with<br>the data checks, the procedure shall go to**S5-2** <br>Note: In this step, when the driver presses the ‘Yes’ button, ATO data are not<br>validated yet and consequently are not yet the ATO data sent to the ERTMS/ATO<br>on-board. This is why the term “accept” is used instead of the term “revalidate” and<br>the term “input field for ATO data” is used instead of “ATO data”.||
|**S5-2**|The**ATO data validation window** shall request the driver to validate or not the<br>values of the input fields for ATO data.<br>When entering**S5-2**, the ATO data validation window shall always propose the<br>value ‘Yes’ in the input field for ATO data validation.<br>Once the input field for ATO data validation is entered or revalidated, if the value<br>is ‘No’, the procedure shall go back to**S5-1**. Otherwise, if the value is ‘Yes’, the<br>procedure shall go to**S4**<br>Note: In this step, when the ATO data validation window is left with the value of its<br>input field set to ‘Yes’, ATO data are sent to the ERTMS/ATO on-board.|Figure 144a – ATO data validation window|


**Table 58 – Steps of the NTC data dialogue sequence**





Version 4.0.0 PAGE 289 OF 317


**ERA ERTMS unit**

**ETCS Driver Machine Interface**

