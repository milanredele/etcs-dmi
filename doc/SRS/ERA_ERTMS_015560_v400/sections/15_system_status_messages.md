##### **15. LIST OF SYSTEM STATUS MESSAGES**


15.1.1.1 The system status messages shall be displayed to the driver as specified in Table 68,
Table 69 and Table 70, in order to fulfil the driver information required in documents [2],

[3] and [5] respectively.


15.1.1.2 In Table 68, Table 69 and Table 70, it is assumed that when a start condition is applied
the onboard is in one of the modes for which it is possible to display the corresponding
information in table 4.7.2 of document [2]. Then after any mode change, to one of those
for which it is specified that the information is not displayed, shall also be considered as
an end condition for the system status message..


15.1.1.3 The case of the displayed system status messages shall comply with the case of the texts
in Table 68, Table 69 and Table 70.


15.1.1.4 The system status messages shall be displayed as text messages not to be
acknowledged.


15.1.1.4.1 Exception: The system status message “[name of NTC] failed” and “NL no longer

permitted” shall be displayed as a text message to be acknowledged.


15.1.1.4.2 Note: the system status messages are provided in English. However, the actual system

status messages displayed to the driver depend on the selected language (see chapter
5.5).


15.1.1.5 The part [name of NTC] of a system status shall be replaced with the distinct abbreviations
of the concerned National System.

















|System status<br>message|Start condition|End condition|Table 4.7.2<br>corresponding row|
|---|---|---|---|
|Balise read error|3.16.2.4.4.3|Message displayed for 30 s<br>once 3.14.1.6 is fulfilled|Brake reason|
|Balise read error|3.16.2.5.3|Message displayed for 30 s<br>once 3.14.1.6 is fulfilled|Brake reason|
|Balise read error|3.16.2.6.1 (service<br>brake reaction)|Message displayed for 30 s<br>once 3.14.1.6 is fulfilled|Brake reason|
|Balise read error|3.16.2.7.1.1|Message displayed for 30 s<br>once 3.14.1.6 is fulfilled|Brake reason|
|Balise read error|3.16.2.7.2.2|Message displayed for 30 s<br>once 3.14.1.6 is fulfilled|Brake reason|
|Balise read error|4.6.3 [17]|PT mode left,<br>4.6.3 [62], 4.6.3 [63], 4.6.3 [68]|Trip reason|
|Balise read error|4.6.3 [66]|PT mode left,<br>4.6.3 [62], 4.6.3 [63], 4.6.3 [68]|Trip reason|
|Trackside malfunction|3.16.2.4.9|Message displayed for 30 s|Trackside malfunction|


Version 4.0.0 PAGE 312 OF 317


**ERA ERTMS unit**

**ETCS Driver Machine Interface**






























|System status<br>message|Start condition|End condition|Table 4.7.2<br>corresponding row|
|---|---|---|---|
|Communication error|3.16.3.4.1 (service<br>brake reaction)|Message displayed for 30 s (if<br>3.14.1.7 fulfilled beforehand) or<br>if brake command reason<br>revoked as per 4.12.1.2<br>beforehand,<br>3.14.1.7 (if message displayed<br>for 30 s beforehand),<br>Brake command reason<br>revoked as per 4.12.1.2 (if<br>message displayed for 30 s<br>beforehand)|Brake reason|
|Communication error|4.6.3 [41]|PT mode left,<br>4.6.3 [62], 4.6.3 [63]|Trip reason|
|Entering FS|4.4.9.1.4|4.4.9.1.4|Entry in FS|
|Entering OS|4.4.12.1.7|4.4.12.1.7|Entry in OS|
|Entering SM|4.4.21.1.6|4.4.21.1.6|Entry in SM|
|Runaway movement|3.14.2.4|3.14.1.5|Brake reason|
|Runaway movement|3.14.3.2|3.14.1.5|Brake reason|
|Runaway movement|3.14.4.2 and 3.14.4.5|3.14.1.5|Brake reason|
|Runaway movement|3.18.3.3.1|3.14.1.5|Brake reason|
|Runaway movement|4.4.11.1.5.1|3.14.1.5|Brake reason|
|SM refused<br>SM request failed|5.21.2 A220|As soon as any button in the<br>main window is selected|Supervised<br>Manoeuvre request<br>refused by RBC|
|SM refused<br>SM request failed|5.21.4.1|As soon as any button in the<br>main window is selected|Supervised<br>Manoeuvre request<br>not answered by RBC|
|SH refused|5.6.2 A220|As soon as any button in the<br>main window is selected|Shunting refused by<br>RBC|
|SH refused|4.6.3 [35]|4.6.3 [63]|Trip reason|
|SH request failed|5.6.4.1.2|As soon as any button in the<br>main window is selected|Shunting  request not<br>answered by RBC|
|Trackside not<br>compatible|3.5.3.7 d) 2nd bullet|Message displayed for 30 s|Trackside not<br>compatible|
|Trackside not<br>compatible|4.6.3 [65]|PT mode left,<br>4.6.3 [62], 4.6.3 [63], 4.6.3 [68]|Trip reason|
|Train data changed|5.17.2.2 A1|Message displayed for 30 s<br>from the time a train movement<br>is detected|Notification of Train<br>Data change from<br>source different from<br>the driver|



Version 4.0.0 PAGE 313 OF 317


**ERA ERTMS unit**

**ETCS Driver Machine Interface**














|System status<br>message|Start condition|End condition|Table 4.7.2<br>corresponding row|
|---|---|---|---|
||5.17.2.2 S2|5.17.2.2 S3 (E3)|Brake reason|
||5.17.2.2 S4|5.17.2.2 S5 (E5)|Brake reason|
|Safe consist length no<br>longer available|4.4.21.1.12|Message displayed for 30 s (if<br>3.14.1.7.6 fulfilled beforehand<br>or if brake command reason<br>revoked as per 4.12.1.2<br>beforehand),<br>3.14.1.7.6 (if message<br>displayed for 30 s beforehand),<br>Brake command reason<br>revoked as per 4.12.1.2 (if<br>message displayed for 30 s<br>beforehand).|Brake reason|
|Train is rejected|5.4.3.2 A40|As soon as any button in the<br>main window is selected|Train is rejected|
|Unauthorized passing<br>of EOA / LOA|4.6.3 [11]|PT mode left,<br>4.6.3 [62], 4.6.3 [63]|Trip reason|
|Unauthorized passing<br>of EOA / LOA|4.6.3 [12]|PT mode left,<br>4.6.3 [62], 4.6.3 [63]|Trip reason|
|Unauthorized passing<br>of EOA / LOA|4.6.3 [16]|PT mode left,<br>4.6.3 [62], 4.6.3 [63]|Trip reason|
|Unauthorized passing<br>of EOA / LOA|4.6.3 [18]|PT mode left,<br>4.6.3 [62], 4.6.3 [63]|Trip reason|
|Unauthorized passing<br>of EOA / LOA|4.6.3 [43]|PT mode left,<br>4.6.3 [62], 4.6.3 [63]|Trip reason|
|No MA received at<br>level transition|4.6.3 [39]|PT mode left,<br>4.6.3 [62], 4.6.3 [63]|Trip reason|
|No MA received at<br>level transition|4.6.3 [67]|PT mode left,<br>4.6.3 [62], 4.6.3 [63]|Trip reason|
|SR distance exceeded|4.6.3 [42]|PT mode left,<br>4.6.3 [62], 4.6.3 [63]|Trip reason|
|SH stop order|4.6.3 [49]|PT mode left,<br>4.6.3 [68]|Trip reason|
|SH stop order|4.6.3 [52]|PT mode left,<br>4.6.3 [68]|Trip reason|
|SR stop order|4.6.3 [36]|PT mode left,<br>4.6.3 [62], 4.6.3 [63]|Trip reason|
|SR stop order|4.6.3 [54] (if operated<br>system version X ≥ 2)|<br> <br>PT mode left,<br>4.6.3 [62], 4.6.3 [63]|Trip reason|



Version 4.0.0 PAGE 314 OF 317


**ERA ERTMS unit**

**ETCS Driver Machine Interface**


























|System status<br>message|Start condition|End condition|Table 4.7.2<br>corresponding row|
|---|---|---|---|
||6.6.2.2.2 (if operated<br>system version X =<br>1)|PT mode left,<br>4.6.3 [62], 4.6.3 [63]|Trip reason|
|Emergency stop|4.6.3 [20]|PT mode left,<br>4.6.3 [62], 4.6.3 [63]|Trip reason|
|RV distance exceeded|3.15.4.8|3.14.1.7.1|Brake reason|
|RV distance exceeded|4.4.18.1.4|3.14.1.7.1|Brake reason|
|PT distance exceeded|4.4.14.1.3|3.14.1.7.4|Brake reason|
|PT distance exceeded|4.4.14.1.3.2|3.14.1.7.4|Brake reason|
|No track description|4.6.3 [69]|PT mode left,<br>4.6.3 [62], 4.6.3 [63]|Trip reason|
|[name of NTC] brake<br>demand|4.6.3 [38]|PT mode left,<br>4.6.3 [62], 4.6.3 [63]|Trip reason|
|Route unsuitable –<br>loading gauge|3.12.2.3 a)|Route suitability data deleted<br>as per A.3.4,<br>3.7.3.2 d),<br>3.7.3.1 h) with 3.12.2.3 a) not<br>fulfilled|Route unsuitability(ies)|
|Route unsuitable –<br>traction system|3.12.2.3 b)|Route suitability data deleted<br>as per A.3.4,<br>3.7.3.2 d),<br>3.7.3.1 i) with 3.12.2.3 b) not<br>fulfilled|Route unsuitability(ies)|
|Route unsuitable –axle<br>load category|<br>3.12.2.3 c)|Route suitability data deleted<br>as per A.3.4,<br>3.7.3.2 d),<br>3.7.3.1 j) with 3.12.2.3 c) not<br>fulfilled|Route unsuitability(ies)|
|FRMCS network<br>registration failed|5.4.3.2 A41|Driver elects to perform the<br>mission with only one radio<br>system,<br>As soon as any button in the<br>main window is selected|Failed Radio Network<br>registration(s)|
|FRMCS network<br>registration failed|5.4.3.2 A42|Driver elects to perform the<br>mission with only one radio<br>system,<br>As soon as any button in the<br>main window is selected|Failed Radio Network<br>registration(s)|



Version 4.0.0 PAGE 315 OF 317


**ERA ERTMS unit**

**ETCS Driver Machine Interface**





|System status<br>message|Start condition|End condition|Table 4.7.2<br>corresponding row|
|---|---|---|---|
||5.4.3.2 A43|Driver elects to perform the<br>mission with only one radio<br>system,<br>As soon as any button in the<br>main window is selected|Failed Radio Network<br>registration(s)|
|GSM-R network<br>registration failed|5.4.3.2 A29|Driver elects to perform the<br>mission with only one radio<br>system,<br>As soon as any button in the<br>main window is selected|Failed Radio Network<br>registration(s)|
|GSM-R network<br>registration failed|5.4.3.2 A42|Driver elects to perform the<br>mission with only one radio<br>system,<br>As soon as any button in the<br>main window is selected|Failed Radio Network<br>registration(s)|
|GSM-R network<br>registration failed|5.4.3.2 A43|Driver elects to perform the<br>mission with only one radio<br>system,<br>As soon as any button in the<br>main window is selected|Failed Radio Network<br>registration(s)|
|NL no longer permitted|4.4.15.1.1.3|Text acknowledged|Non-leading no longer<br>permitted|
|Odometer impaired|3.6.8.5|3.6.8.6|Impairment due to<br>accumulated<br>underestimation /<br>overestimation in<br>measuring the<br>movements over a<br>defined total distance|


**Table 68 - System status messages related to SUBSET-026 requirements**







|System status<br>message|Start condition|End Condition|Table 4.7.2<br>corresponding row|
|---|---|---|---|
|[name of NTC] is not<br>available|10.3.3.8|10.3.3.8|NTC not available|
|[name of NTC] needs<br>data|10.7.3.4|10.7.3.5|NTC data need|
|Runaway movement|10.7.3.9|10.7.3.9|Brake reason|
|[name of NTC] failed|10.14.1.1|Text acknowledged|NTC failed|
|[name of NTC] failed|10.14.1.2|Text acknowledged|NTC failed|


**Table 69 - System status messages related to SUBSET-035 requirements**


Version 4.0.0 PAGE 316 OF 317


**ERA ERTMS unit**

**ETCS Driver Machine Interface**



|System status<br>message|Start condition|End Condition|Table 4.7.2<br>corresponding row|
|---|---|---|---|
|ATO needs data|7.14.2.13|7.14.2.14|ATO data need|
|Runaway movement|7.14.2.18|7.14.2.18|Brake reason|


**Table 70 - System status messages related to SUBSET-125 requirements**


15.1.1.6 In Table 68, some system status messages are displayed to inform the driver about a
brake command reason. Any mode change, to one of those for which the table 4.12 of
document [2] specifies that a brake reason is revoked, shall also be considered as an end
condition for the corresponding system status message.


15.1.1.7 In case more than one instance of the same system status message would have to be
displayed according to the start/end conditions stipulated in the Table 68, only one
instance of this system status message shall be displayed, until all the end conditions are
fulfilled.


Version 4.0.0 PAGE 317 OF 317


