##### **8. ETCS INFORMATION SHOWN ON THE ETCS DEFAULT**

**WINDOW**


**8.1** **Introduction**


8.1.1.1 The chapter 8 is applicable for ERTMS/ETCS levels 0/1/2 and ERTMS/ETCS level NTC
excluding the modes SN and NL.


8.1.1.2 For the modes SN and NL in ERTMS/ETCS level NTC, the NTC default window of the
corresponding National System will be displayed instead. In case a National System is
interfaced to the ERTMS/ETCS onboard through an STM, see chapter 9.


8.1.1.3 The figures in this chapter show the ETCS objects/functions allocated to the areas of the
ETCS layout to form the ETCS default window. The figures showing the areas (e.g. Figure
26) concerned by an ETCS object/function presents the touch screen layout on the left
hand side and the soft key layout on the right hand side.


8.1.1.4 The layers on the ETCS default window shall be as follows:

a) Layer 0: E10, E11, F, H (soft key technology), I (soft key technology), G6, G7, G8, G9,

G10, Z (touch screen technology), Y (touch screen technology)

b) Layer -1: A1, A2+A3 (drawn as one area), A4, B (drawn as one area), D (drawn as

one area), C1, C2+C3+C4 (drawn as one area), C5, C6, C7, C8, C9, E1, E2, E3, E4
(touch screen technology), E5-E8 (soft key technology, drawn as one area) or E5-E9
(touch screen technology, drawn as one area), G1, G2, G3, G4, G5, G11, G12, G13

c) Layer -2: B3, B4, B5, B6, B7, B8


**8.2** **Speed and Supervision information**











































































































**Figure 26 – Areas for speed and supervision information**


Version 4.0.0 PAGE 46 OF 317


**ERA ERTMS unit**

**ETCS Driver Machine Interface**



Target distance digital


Target distance bar


Target speed







|Col1|Col2|150<br>100 200<br>133<br>50 300<br>0 400|Col4|Col5|Col6|Col7|Col8|
|---|---|---|---|---|---|---|---|
||1340|1340|1340|1340|1340|1340|1340|
|||||||||
|||||||||
|||||||||
||**2**|||||||
|||||||||


**Figure 27 – Overview of the main objects in the speed and supervision areas**


**8.2.1** **Speed Information**


**8.2.1.1** **Speed dial**


8.2.1.1.1 This DMI object displays the speed dial.


8.2.1.1.2 The speed dial shall be displayed in area B0 (see Figure 28).



Circular speed gauge


Speed dial


Current speed pointer
(analog & digital)


Mode indication


Actual orders



































































































**Figure 28 – Area for the speed dial**


8.2.1.1.3 The range of the speed dial shall be pre-configured onboard to one of the following
possibilities:

a) 0 km/h to 400 km/h

b) 0 km/h to 250 km/h

c) 0 km/h to 180 km/h

d) 0 km/h to 140 km/h


8.2.1.1.4 The speed dial shall be circular and shall indicate speeds from 0 km/h to the maximum
value of the pre-configured onboard range.


Version 4.0.0 PAGE 47 OF 317


**ERA ERTMS unit**

**ETCS Driver Machine Interface**


8.2.1.1.5 The speed dial shall be composed of:


a) short or long speed indicator lines drawn radially, from the limit of B0 towards the centre

of B0, at every 10 km/h,


b) speed numbers attached to some speed indicator lines, positioned at the end of the

related indicator line towards the centre of B0 and equally spaced from each other.


8.2.1.1.6 The length of the short speed indicator lines shall be 15 cells.


8.2.1.1.7 The length of the long speed indicator lines shall be 25 cells.


8.2.1.1.8 The width of the speed indicator lines shall be 1 cell.


8.2.1.1.9 The numbers and speed indicator lines shall be white.


8.2.1.1.10 The functions displayed in B1 and B2 shall use the mapping described here below for the

pre-configured onboard range.


8.2.1.1.11 For the 400 km/h dial (see Figure 29):


Version 4.0.0 PAGE 48 OF 317


**ERA ERTMS unit**

**ETCS Driver Machine Interface**














|Col1|Col2|Col3|150<br>100 200<br>133<br>50 300<br>0 400|Col5|Col6|Col7|Col8|4000 +<br>2<br>2000<br>+<br>-<br>1000<br>22<br>500<br>-<br>+<br>5<br>+<br>0|Col10|Col11|Col12|Col13|Col14|Main|
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
|||||||||||||||Over-<br>ride|
|||||||||||||||Data<br>view|
|||||||||||||||Spec|
||||||||||||||||
||||||||||||||||
|**2**|**2**|**2**|||||||||||||
||||||||||||||||
||||||||||||||||
||||||||||||||||
|||||||||||||17:33:25|17:33:25|17:33:25|
||||||||||||||||






|Col1|Col2|Col3|150<br>100 200<br>133<br>50 300<br>0 400|Col5|Col6|Col7|Col8|Col9|Col10|Col11|4000 +<br>2<br>2000<br>+<br>-<br>1000<br>22<br>500<br>-<br>+<br>5<br>+<br>0|Col13|Col14|Col15|Col16|Col17|Col18|Col19|Col20|Col21|
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
||||**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**<br>**133**|**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**<br>**133**|**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**<br>**133**|**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**<br>**133**|**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**<br>**133**|**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**<br>**133**|**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**<br>**133**|**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**<br>**133**|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>-<br>22<br>-<br>+<br>2<br>+|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>-<br>22<br>-<br>+<br>2<br>+|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>-<br>22<br>-<br>+<br>2<br>+|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>-<br>22<br>-<br>+<br>2<br>+|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>-<br>22<br>-<br>+<br>2<br>+|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>-<br>22<br>-<br>+<br>2<br>+|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>-<br>22<br>-<br>+<br>2<br>+|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>-<br>22<br>-<br>+<br>2<br>+|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>-<br>22<br>-<br>+<br>2<br>+||
||||||||||||||||||||||
||||||||||||||||||||||
||||||||||||||||||||||
||||||||||||||||||||||
||||||||||||||||||||||
||||||||||||||||||||||
|**2**|**2**|**2**|||||||||||||||||||
||||||||||||||||||||||
||||||||||||||||||||||
||||||||||||||||||||||
||||||||||||||||||||||
||||||||||||||||||||||
||||||||||||||||||17:33:25|17:33:25|17:33:25|17:33:25|
|Main|Main|Main|Over-<br>ride|Data<br>view|Data<br>view|Spec|Spec||||||||||||||



**Figure 29 – 400 km/h indication for the speed dial**


8.2.1.1.11.1 Assuming that 0 degrees (corresponding to 150 km/h) is vertically upwards from the
centre, 0 km/h shall be shown at an angle of -144 degrees and 400 km/h shall be shown
at an angle of +144 degrees, while 200 km/h shall be shown at an angle of +48
degrees.


8.2.1.1.11.2 Both segments from 0 km/h to 200 km/h and from 200 km/h to 400 km/h shall have
linear mapping between speed and angles.


8.2.1.1.11.3 The speed dial with the 400 km/h shall indicate the following numbers: 0, 50, 100, 150,
200, 300 and 400. At each of the following positions 0, 50, 100, 150, 200, 250, 300,


Version 4.0.0 PAGE 49 OF 317


**ERA ERTMS unit**

**ETCS Driver Machine Interface**


350, and 400, a long speed indicator line shall be drawn. In between these lines, short
speed indicator lines shall be drawn.


8.2.1.1.11.4 Note: This means that in the first segment (from 0 to 200) the distance between the 10
km/h indications is wider (9,6 degrees) than in the second segment (from 200 to 400)
(4,8 degrees).


8.2.1.1.12 For the 250 km/h dial (see Figure 30):
























|Col1|Col2|Col3|120140<br>100<br>160<br>80<br>180<br>60<br>133 200<br>40<br>220<br>20<br>240<br>0|Col5|Col6|Col7|Col8|4000 +<br>2<br>2000<br>+<br>-<br>1000<br>22<br>500<br>-<br>+<br>5<br>+<br>0|Col10|Col11|Col12|Col13|Col14|Col15|Col16|Main<br>Over-<br>ride<br>Data<br>view|
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
||||**100**<br>**40**<br>**140**<br>**240**<br>**0**<br>**200**<br>**20**<br>**60**<br>**80**<br>**120**<br>**160**<br>**180**<br>**220**<br>**133**|**100**<br>**40**<br>**140**<br>**240**<br>**0**<br>**200**<br>**20**<br>**60**<br>**80**<br>**120**<br>**160**<br>**180**<br>**220**<br>**133**|**100**<br>**40**<br>**140**<br>**240**<br>**0**<br>**200**<br>**20**<br>**60**<br>**80**<br>**120**<br>**160**<br>**180**<br>**220**<br>**133**|**100**<br>**40**<br>**140**<br>**240**<br>**0**<br>**200**<br>**20**<br>**60**<br>**80**<br>**120**<br>**160**<br>**180**<br>**220**<br>**133**|**100**<br>**40**<br>**140**<br>**240**<br>**0**<br>**200**<br>**20**<br>**60**<br>**80**<br>**120**<br>**160**<br>**180**<br>**220**<br>**133**|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>-<br>22<br>-<br>+<br>2<br>+|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>-<br>22<br>-<br>+<br>2<br>+|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>-<br>22<br>-<br>+<br>2<br>+|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>-<br>22<br>-<br>+<br>2<br>+|2|2|2|2|2|
||||||||||||||||||
|||||||||||||-<br>+|-<br>+|-<br>+|-<br>+|-<br>+|
|||||||||||||22|22|22|22|22|
|||||||||||||||||Spec|
|||||||||||||-|-|-|-|-|
|||||||||||||+|+|+|+|+|
|||||||||||||+|+|+|+||
|||||||||||||5|5|5|5|5|
||||||||||||||||||
|**2**|**2**|**2**|||||||||||||||
||||||||||||||||||
||||||||||||||||||
||||||||||||||||||
||||||||||||||||||
|||||||||||||||17:33:25|17:33:25|17:33:25|
||||||||||||||||||




















|Col1|Col2|Col3|120140<br>100<br>160<br>80<br>180<br>60<br>133 200<br>40<br>220<br>20<br>240<br>0|Col5|Col6|Col7|Col8|Col9|Col10|Col11|4000 +<br>2<br>2000<br>+<br>-<br>1000<br>22<br>500<br>-<br>+<br>5<br>+<br>0|Col13|Col14|Col15|Col16|Col17|Col18|Col19|Col20|Col21|
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
||||**100**<br>**40**<br>**140**<br>**240**<br>**0**<br>**200**<br>**20**<br>**60**<br>**80**<br>**120**<br>**160**<br>**180**<br>**220**<br>**133**|**100**<br>**40**<br>**140**<br>**240**<br>**0**<br>**200**<br>**20**<br>**60**<br>**80**<br>**120**<br>**160**<br>**180**<br>**220**<br>**133**|**100**<br>**40**<br>**140**<br>**240**<br>**0**<br>**200**<br>**20**<br>**60**<br>**80**<br>**120**<br>**160**<br>**180**<br>**220**<br>**133**|**100**<br>**40**<br>**140**<br>**240**<br>**0**<br>**200**<br>**20**<br>**60**<br>**80**<br>**120**<br>**160**<br>**180**<br>**220**<br>**133**|**100**<br>**40**<br>**140**<br>**240**<br>**0**<br>**200**<br>**20**<br>**60**<br>**80**<br>**120**<br>**160**<br>**180**<br>**220**<br>**133**|**100**<br>**40**<br>**140**<br>**240**<br>**0**<br>**200**<br>**20**<br>**60**<br>**80**<br>**120**<br>**160**<br>**180**<br>**220**<br>**133**|**100**<br>**40**<br>**140**<br>**240**<br>**0**<br>**200**<br>**20**<br>**60**<br>**80**<br>**120**<br>**160**<br>**180**<br>**220**<br>**133**|**100**<br>**40**<br>**140**<br>**240**<br>**0**<br>**200**<br>**20**<br>**60**<br>**80**<br>**120**<br>**160**<br>**180**<br>**220**<br>**133**|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>-<br>22<br>-<br>~~+~~<br>2<br>+|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>-<br>22<br>-<br>~~+~~<br>2<br>+|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>-<br>22<br>-<br>~~+~~<br>2<br>+|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>-<br>22<br>-<br>~~+~~<br>2<br>+|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>-<br>22<br>-<br>~~+~~<br>2<br>+|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>-<br>22<br>-<br>~~+~~<br>2<br>+|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>-<br>22<br>-<br>~~+~~<br>2<br>+|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>-<br>22<br>-<br>~~+~~<br>2<br>+|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>-<br>22<br>-<br>~~+~~<br>2<br>+||
||||||||||||||||||||||
||||||||||||||||||||||
||||||||||||||||||||||
||||||||||||||||||||||
||||||||||||||||||||||
||||||||||||||||||||||
|**2**|**2**|**2**|||||||||||||||||||
||||||||||||||||||||||
||||||||||||||||||||||
||||||||||||||||||||||
||||||||||||||||||||||
||||||||||||||||||||||
||||||||||||||||||17:33:25|17:33:25|17:33:25|17:33:25|
|Main|Main|Main|Over-<br>ride|Data<br>view|Data<br>view|Spec|Spec||||||||||||||



**Figure 30 – 250 km/h indication for the speed dial**


8.2.1.1.12.1 Assuming that 0 degrees is vertically upwards from the centre, 0 km/h shall be shown
at an angle of -144 degrees and 250 km/h is shown at an angle of +144 degrees.


Version 4.0.0 PAGE 50 OF 317


**ERA ERTMS unit**

**ETCS Driver Machine Interface**


8.2.1.1.12.2 The segment from 0 km/h to 250 km/h shall have linear mapping between speed and
angles.


8.2.1.1.12.3 The speed dial with the 250 km/h shall indicate the following numbers: 0, 20, 40, 60,
80, 100, 120, 140, 160, 180, 200, 220 and 240. At each of these displayed numbers, a
long speed indicator line shall be drawn. In between these lines, short speed indicator
lines shall be drawn.


8.2.1.1.13 For the 180 km/h dial (see Figure 31):




















|Col1|Col2|Col3|80 100<br>60 120<br>40 140<br>133<br>20 160<br>0 180|Col5|Col6|Col7|Col8|4000 +<br>2<br>2000<br>+<br>-<br>1000<br>22<br>500<br>-<br>+<br>5<br>+<br>0|Col10|Col11|Col12|Col13|Col14|Col15|Col16|Main<br>Over-<br>ride|
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
||||**100**<br>**60**<br>**0**<br>**80**<br>**40**<br>**20**<br>**120**<br>**140**<br>**160**<br>**180**<br>**133**|**100**<br>**60**<br>**0**<br>**80**<br>**40**<br>**20**<br>**120**<br>**140**<br>**160**<br>**180**<br>**133**|**100**<br>**60**<br>**0**<br>**80**<br>**40**<br>**20**<br>**120**<br>**140**<br>**160**<br>**180**<br>**133**|**100**<br>**60**<br>**0**<br>**80**<br>**40**<br>**20**<br>**120**<br>**140**<br>**160**<br>**180**<br>**133**|**100**<br>**60**<br>**0**<br>**80**<br>**40**<br>**20**<br>**120**<br>**140**<br>**160**<br>**180**<br>**133**|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>-<br>22<br>-<br>+<br>2<br>+|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>-<br>22<br>-<br>+<br>2<br>+|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>-<br>22<br>-<br>+<br>2<br>+|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>-<br>22<br>-<br>+<br>2<br>+|2|2|2|2|2|
||||||||||||||||||
|||||||||||||-<br>+|-<br>+|-<br>+|-<br>+|-<br>+|
|||||||||||||-<br>+|-<br>+|-<br>+|-<br>+|Data<br>view|
|||||||||||||22|22|22|22|22|
|||||||||||||||||Spec|
|||||||||||||-|-|-|-|-|
|||||||||||||+|+|+|+|+|
|||||||||||||5|5|5|5||
||||||||||||||||||
|**2**|**2**|**2**|||||||||||||||
||||||||||||||||||
||||||||||||||||||
||||||||||||||||||
||||||||||||||||||
|||||||||||||||17:33:25|17:33:25|17:33:25|
||||||||||||||||||
















|Col1|Col2|Col3|80 100<br>60 120<br>40 140<br>133<br>20 160<br>0 180|Col5|Col6|Col7|Col8|Col9|Col10|Col11|4000 +<br>2<br>2000<br>+<br>-<br>1000<br>22<br>500<br>-<br>+<br>5<br>+<br>0|Col13|Col14|Col15|Col16|Col17|Col18|Col19|Col20|Col21|
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
||||**100**<br>**60**<br>**0**<br>**80**<br>**40**<br>**20**<br>**120**<br>**140**<br>**160**<br>**180**<br>**133**|**100**<br>**60**<br>**0**<br>**80**<br>**40**<br>**20**<br>**120**<br>**140**<br>**160**<br>**180**<br>**133**|**100**<br>**60**<br>**0**<br>**80**<br>**40**<br>**20**<br>**120**<br>**140**<br>**160**<br>**180**<br>**133**|**100**<br>**60**<br>**0**<br>**80**<br>**40**<br>**20**<br>**120**<br>**140**<br>**160**<br>**180**<br>**133**|**100**<br>**60**<br>**0**<br>**80**<br>**40**<br>**20**<br>**120**<br>**140**<br>**160**<br>**180**<br>**133**|**100**<br>**60**<br>**0**<br>**80**<br>**40**<br>**20**<br>**120**<br>**140**<br>**160**<br>**180**<br>**133**|**100**<br>**60**<br>**0**<br>**80**<br>**40**<br>**20**<br>**120**<br>**140**<br>**160**<br>**180**<br>**133**|**100**<br>**60**<br>**0**<br>**80**<br>**40**<br>**20**<br>**120**<br>**140**<br>**160**<br>**180**<br>**133**|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>-<br>22<br>-<br>~~+~~<br>2<br>+|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>-<br>22<br>-<br>~~+~~<br>2<br>+|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>-<br>22<br>-<br>~~+~~<br>2<br>+|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>-<br>22<br>-<br>~~+~~<br>2<br>+|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>-<br>22<br>-<br>~~+~~<br>2<br>+|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>-<br>22<br>-<br>~~+~~<br>2<br>+|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>-<br>22<br>-<br>~~+~~<br>2<br>+|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>-<br>22<br>-<br>~~+~~<br>2<br>+|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>-<br>22<br>-<br>~~+~~<br>2<br>+||
||||||||||||||||||||||
||||||||||||||||||||||
||||||||||||||||||||||
||||||||||||||||||||||
||||||||||||||||||||||
||||||||||||||||||||||
|**2**|**2**|**2**|||||||||||||||||||
||||||||||||||||||||||
||||||||||||||||||||||
||||||||||||||||||||||
||||||||||||||||||||||
||||||||||||||||||||||
||||||||||||||||||17:33:25|17:33:25|17:33:25|17:33:25|
|Main|Main|Main|Over-<br>ride|Data<br>view|Data<br>view|Spec|Spec||||||||||||||



**Figure 31 – 180 km/h indication for the speed dial**


Version 4.0.0 PAGE 51 OF 317


**ERA ERTMS unit**

**ETCS Driver Machine Interface**


8.2.1.1.13.1 Assuming that 0 degrees is vertically upwards from the centre, 0 km/h shall be shown
at an angle of -144 degrees and 180 km/h is shown at an angle of +144 degrees.


8.2.1.1.13.2 The segment from 0 km/h to 180 km/h shall have linear mapping between speed and
angles.


8.2.1.1.13.3 The speed dial with the 180 km/h shall indicate the following numbers: 0, 20, 40, 60,
80, 100, 120, 140, 160, 180. At each of these displayed numbers, a long speed
indicator line shall be drawn. In between these lines, short speed indicator lines shall
be drawn.


8.2.1.1.14 For the 140 km/h dial (see Figure 32):






















|Col1|60 80<br>40 100<br>96<br>20 120<br>0 140|Col3|Col4|Col5|Col6|4000 +<br>2<br>2000<br>+<br>-<br>1000<br>22<br>500<br>-<br>+<br>5<br>+<br>0|Col8|Col9|Col10|Col11|Col12|Col13|Col14|Main|
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
||**100**<br>**60**<br>**0**<br>**80**<br>**40**<br>**20**<br>**120**<br>**140**<br>**96**|**100**<br>**60**<br>**0**<br>**80**<br>**40**<br>**20**<br>**120**<br>**140**<br>**96**|**100**<br>**60**<br>**0**<br>**80**<br>**40**<br>**20**<br>**120**<br>**140**<br>**96**|**100**<br>**60**<br>**0**<br>**80**<br>**40**<br>**20**<br>**120**<br>**140**<br>**96**|**100**<br>**60**<br>**0**<br>**80**<br>**40**<br>**20**<br>**120**<br>**140**<br>**96**|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>-<br>22<br>-<br>+<br>2<br>+|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>-<br>22<br>-<br>+<br>2<br>+|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>-<br>22<br>-<br>+<br>2<br>+|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>-<br>22<br>-<br>+<br>2<br>+|2|2|2|2|2|
|||||||||||||||Over-<br>ride|
|||||||||||-<br>+|-<br>+|-<br>+|-<br>+|-<br>+|
|||||||||||-<br>+|-<br>+|-<br>+|-<br>+|Data<br>view|
|||||||||||22|22|22|22|22|
|||||||||||||||Spec|
|||||||||||-|-|-|-|-|
|||||||||||+|+|+|+|+|
|||||||||||5|5|5|5||
||||||||||||||||
|**1**|||||||||||||||
||||||||||||||||
||||||||||||||||
||||||||||||||||
|||||||||||||17:33:25|17:33:25|17:33:25|
||||||||||||||||




















|Col1|60 80<br>40 100<br>96<br>20 120<br>0 140|Col3|Col4|Col5|Col6|Col7|Col8|Col9|4000 +<br>2<br>2000<br>+<br>-<br>1000<br>22<br>500<br>-<br>+<br>5<br>+<br>0|Col11|Col12|Col13|Col14|Col15|Col16|Col17|Col18|Col19|
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
||**100**<br>**60**<br>**0**<br>**80**<br>**40**<br>**20**<br>**120**<br>**140**<br>**96**|**100**<br>**60**<br>**0**<br>**80**<br>**40**<br>**20**<br>**120**<br>**140**<br>**96**|**100**<br>**60**<br>**0**<br>**80**<br>**40**<br>**20**<br>**120**<br>**140**<br>**96**|**100**<br>**60**<br>**0**<br>**80**<br>**40**<br>**20**<br>**120**<br>**140**<br>**96**|**100**<br>**60**<br>**0**<br>**80**<br>**40**<br>**20**<br>**120**<br>**140**<br>**96**|**100**<br>**60**<br>**0**<br>**80**<br>**40**<br>**20**<br>**120**<br>**140**<br>**96**|**100**<br>**60**<br>**0**<br>**80**<br>**40**<br>**20**<br>**120**<br>**140**<br>**96**|**100**<br>**60**<br>**0**<br>**80**<br>**40**<br>**20**<br>**120**<br>**140**<br>**96**|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>-<br>22<br>-<br>~~+~~<br>2<br>+|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>-<br>22<br>-<br>~~+~~<br>2<br>+|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>-<br>22<br>-<br>~~+~~<br>2<br>+|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>-<br>22<br>-<br>~~+~~<br>2<br>+|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>-<br>22<br>-<br>~~+~~<br>2<br>+|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>-<br>22<br>-<br>~~+~~<br>2<br>+|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>-<br>22<br>-<br>~~+~~<br>2<br>+|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>-<br>22<br>-<br>~~+~~<br>2<br>+|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>-<br>22<br>-<br>~~+~~<br>2<br>+||
||||||||||||||||||||
||||||||||||||||||||
||||||||||||||||||||
||||||||||||||||||||
||||||||||||||||||||
||||||||||||||||||||
|**1**|||||||||||||||||||
||||||||||||||||||||
||||||||||||||||||||
||||||||||||||||||||
||||||||||||||||||||
||||||||||||||||17:33:25|17:33:25|17:33:25|17:33:25|
|Main|Over-<br>ride|Data<br>view|Data<br>view|Spec|Spec||||||||||||||



Version 4.0.0 PAGE 52 OF 317


**ERA ERTMS unit**

**ETCS Driver Machine Interface**


**Figure 32 – 140 km/h indication for the speed dial**


8.2.1.1.14.1 Assuming that 0 degrees is vertically upwards from the centre, 0 km/h shall be shown
at an angle of -144 degrees and 140 km/h is shown at an angle of +144 degrees.


8.2.1.1.14.2 The segment from 0 km/h to 140 km/h shall have linear mapping between speed and
angles.


8.2.1.1.14.3 The speed dial with the 140 km/h shall indicate the following numbers: 0, 20, 40, 60,
80, 100, 120, 140. At each of these displayed numbers, a long speed indicator line
shall be drawn. In between these lines, short speed indicator lines shall be drawn.


**8.2.1.2** **Current train speed pointer**


8.2.1.2.1 This DMI object displays the current speed of the train.


8.2.1.2.2 The current train speed pointer shall be displayed in area B1 (see Figure 33).







































**Figure 33 – Area for the current train speed pointer**













**Figure 34 – Size in cells of the current train speed pointer**


8.2.1.2.3 The pointer indicates the current train speed. The pointer shall consist of a needle and a
circular part centred in B1. Both parts shall always have the same colour.


8.2.1.2.4 The Figure 34 dimensions shall be used.


8.2.1.2.5 Depending on the mode and the supervision status, the pointer shall follow the DMI colour
as specified in Table 8.


Version 4.0.0 PAGE 53 OF 317


**ERA ERTMS unit**

**ETCS Driver Machine Interface**



























|Mode|Supervision Status|Col3|0 km/h ≤ Pointer<br>≤ V<br>Perm|0 km/h ≤<br>Pointer ≤<br>V *<br>release<br>(when V<br>release<br>exists)|0 km/h ≤<br>Pointer < V<br>Target|V ≤<br>Target<br>Pointer ≤<br>V<br>Perm|Pointer ><br>V (in CSM or<br>Perm<br>TSM)or > V<br>release<br>(in RSM)|
|---|---|---|---|---|---|---|---|
|FS / SM<br>/ OS<br> <br> <br> <br> <br> <br> <br> <br> <br> <br> <br> <br> <br>|CSM<br> <br> <br>|NoS|grey|-|-|-|-|
|FS / SM<br>/ OS<br> <br> <br> <br> <br> <br> <br> <br> <br> <br> <br> <br> <br>|CSM<br> <br> <br>|OvS|-|-|-|-|orange|
|FS / SM<br>/ OS<br> <br> <br> <br> <br> <br> <br> <br> <br> <br> <br> <br> <br>|CSM<br> <br> <br>|WaS|-|-|-|-|orange|
|FS / SM<br>/ OS<br> <br> <br> <br> <br> <br> <br> <br> <br> <br> <br> <br> <br>|CSM<br> <br> <br>|IntS|grey|-|-|-|red|
|FS / SM<br>/ OS<br> <br> <br> <br> <br> <br> <br> <br> <br> <br> <br> <br> <br>|CSM (with target<br>information)**<br> <br> <br>|NoS|-|-|grey|white|-|
|FS / SM<br>/ OS<br> <br> <br> <br> <br> <br> <br> <br> <br> <br> <br> <br> <br>|CSM (with target<br>information)**<br> <br> <br>|OvS|-|-|-|-|orange|
|FS / SM<br>/ OS<br> <br> <br> <br> <br> <br> <br> <br> <br> <br> <br> <br> <br>|CSM (with target<br>information)**<br> <br> <br>|WaS|-|-|-|-|orange|
|FS / SM<br>/ OS<br> <br> <br> <br> <br> <br> <br> <br> <br> <br> <br> <br> <br>|CSM (with target<br>information)**<br> <br> <br>|IntS|-|-|grey|white|red|
|FS / SM<br>/ OS<br> <br> <br> <br> <br> <br> <br> <br> <br> <br> <br> <br> <br>|TSM<br> <br> <br>|IndS|-|-|grey|yellow|-|
|FS / SM<br>/ OS<br> <br> <br> <br> <br> <br> <br> <br> <br> <br> <br> <br> <br>|TSM<br> <br> <br>|OvS|-|-|-|-|orange|
|FS / SM<br>/ OS<br> <br> <br> <br> <br> <br> <br> <br> <br> <br> <br> <br> <br>|TSM<br> <br> <br>|WaS|-|-|-|-|orange|
|FS / SM<br>/ OS<br> <br> <br> <br> <br> <br> <br> <br> <br> <br> <br> <br> <br>|TSM<br> <br> <br>|IntS|-|-|grey|yellow|red|
|FS / SM<br>/ OS<br> <br> <br> <br> <br> <br> <br> <br> <br> <br> <br> <br> <br>|RSM<br>|IndS|-|yellow|-|-|-|
|FS / SM<br>/ OS<br> <br> <br> <br> <br> <br> <br> <br> <br> <br> <br> <br> <br>|RSM<br>|IntS|-|yellow|-|-|red|
|AD<br> <br> <br> <br> <br> <br> <br> <br> <br> <br> <br> <br> <br>|CSM<br> <br> <br>|NoS|grey|-|-|-|-|
|AD<br> <br> <br> <br> <br> <br> <br> <br> <br> <br> <br> <br> <br>|CSM<br> <br> <br>|OvS|-|-|-|-|grey|
|AD<br> <br> <br> <br> <br> <br> <br> <br> <br> <br> <br> <br> <br>|CSM<br> <br> <br>|WaS|-|-|-|-|grey|
|AD<br> <br> <br> <br> <br> <br> <br> <br> <br> <br> <br> <br> <br>|CSM<br> <br> <br>|IntS|-|-|-|-|-|
|AD<br> <br> <br> <br> <br> <br> <br> <br> <br> <br> <br> <br> <br>|CSM (with target<br>information)**<br> <br> <br>|NoS|-|-|grey|white|-|
|AD<br> <br> <br> <br> <br> <br> <br> <br> <br> <br> <br> <br> <br>|CSM (with target<br>information)**<br> <br> <br>|OvS|-|-|-|-|white|
|AD<br> <br> <br> <br> <br> <br> <br> <br> <br> <br> <br> <br> <br>|CSM (with target<br>information)**<br> <br> <br>|WaS|-|-|-|-|white|
|AD<br> <br> <br> <br> <br> <br> <br> <br> <br> <br> <br> <br> <br>|CSM (with target<br>information)**<br> <br> <br>|IntS|-|-|-|-|-|
|AD<br> <br> <br> <br> <br> <br> <br> <br> <br> <br> <br> <br> <br>|TSM<br> <br> <br>|IndS|-|-|grey|white|-|
|AD<br> <br> <br> <br> <br> <br> <br> <br> <br> <br> <br> <br> <br>|TSM<br> <br> <br>|OvS|-|-|-|-|white|
|AD<br> <br> <br> <br> <br> <br> <br> <br> <br> <br> <br> <br> <br>|TSM<br> <br> <br>|WaS|-|-|-|-|white|
|AD<br> <br> <br> <br> <br> <br> <br> <br> <br> <br> <br> <br> <br>|TSM<br> <br> <br>|IntS|-|-|-|-|-|
|AD<br> <br> <br> <br> <br> <br> <br> <br> <br> <br> <br> <br> <br>|RSM<br>|IndS|-|white|-|-|-|
|AD<br> <br> <br> <br> <br> <br> <br> <br> <br> <br> <br> <br> <br>|RSM<br>|IntS|-|-|-|-|-|
|LS<br> <br> <br> <br> <br> <br> <br> <br>|CSM<br> <br> <br>|NoS|grey|-|-|-|-|
|LS<br> <br> <br> <br> <br> <br> <br> <br>|CSM<br> <br> <br>|OvS|-|-|-|-|orange|
|LS<br> <br> <br> <br> <br> <br> <br> <br>|CSM<br> <br> <br>|WaS|-|-|-|-|orange|
|LS<br> <br> <br> <br> <br> <br> <br> <br>|CSM<br> <br> <br>|IntS|grey|-|-|-|red|
|LS<br> <br> <br> <br> <br> <br> <br> <br>|TSM<br> <br> <br>|IndS|-|-|grey|grey|-|
|LS<br> <br> <br> <br> <br> <br> <br> <br>|TSM<br> <br> <br>|OvS|-|-|-|-|orange|
|LS<br> <br> <br> <br> <br> <br> <br> <br>|TSM<br> <br> <br>|WaS|-|-|-|-|orange|
|LS<br> <br> <br> <br> <br> <br> <br> <br>|TSM<br> <br> <br>|IntS|-|-|grey|grey|red|
|LS<br> <br> <br> <br> <br> <br> <br> <br>|RSM|IndS|-|yellow|-|-|-|


Version 4.0.0 PAGE 54 OF 317


**ERA ERTMS unit**

**ETCS Driver Machine Interface**























|Mode|Supervision Status|Col3|0 km/h ≤ Pointer<br>≤ V<br>Perm|0 km/h ≤<br>Pointer ≤<br>V *<br>release<br>(when V<br>release<br>exists)|0 km/h ≤<br>Pointer < V<br>Target|V ≤<br>Target<br>Pointer ≤<br>V<br>Perm|Pointer ><br>V (in CSM or<br>Perm<br>TSM)or > V<br>release<br>(in RSM)|
|---|---|---|---|---|---|---|---|
|||IntS|-|yellow|-|-|red|
|SR / UN<br> <br> <br> <br> <br> <br> <br> <br> <br> <br> <br>|CSM<br> <br> <br>|NoS|grey|-|-|-|-|
|SR / UN<br> <br> <br> <br> <br> <br> <br> <br> <br> <br> <br>|CSM<br> <br> <br>|OvS|-|-|-|-|orange|
|SR / UN<br> <br> <br> <br> <br> <br> <br> <br> <br> <br> <br>|CSM<br> <br> <br>|WaS|-|-|-|-|orange|
|SR / UN<br> <br> <br> <br> <br> <br> <br> <br> <br> <br> <br>|CSM<br> <br> <br>|IntS|grey|-|-|-|red|
|SR / UN<br> <br> <br> <br> <br> <br> <br> <br> <br> <br> <br>|CSM (with target<br>information)**<br> <br> <br>|NoS||-|grey|white|-|
|SR / UN<br> <br> <br> <br> <br> <br> <br> <br> <br> <br> <br>|CSM (with target<br>information)**<br> <br> <br>|OvS|-|-|-|-|orange|
|SR / UN<br> <br> <br> <br> <br> <br> <br> <br> <br> <br> <br>|CSM (with target<br>information)**<br> <br> <br>|WaS|-|-|-|-|orange|
|SR / UN<br> <br> <br> <br> <br> <br> <br> <br> <br> <br> <br>|CSM (with target<br>information)**<br> <br> <br>|IntS|-|-|grey|white|red|
|SR / UN<br> <br> <br> <br> <br> <br> <br> <br> <br> <br> <br>|TSM<br> <br> <br>|IndS|-|-|grey|yellow|-|
|SR / UN<br> <br> <br> <br> <br> <br> <br> <br> <br> <br> <br>|TSM<br> <br> <br>|OvS|-|-|-|-|orange|
|SR / UN<br> <br> <br> <br> <br> <br> <br> <br> <br> <br> <br>|TSM<br> <br> <br>|WaS|-|-|-|-|orange|
|SR / UN<br> <br> <br> <br> <br> <br> <br> <br> <br> <br> <br>|TSM<br> <br> <br>|IntS|-|-|grey|yellow|red|
|SH /<br>RV<br> <br> <br>|CSM<br> <br> <br>|NoS|grey|-|-|-|-|
|SH /<br>RV<br> <br> <br>|CSM<br> <br> <br>|OvS|-|-|-|-|orange|
|SH /<br>RV<br> <br> <br>|CSM<br> <br> <br>|WaS|-|-|-|-|orange|
|SH /<br>RV<br> <br> <br>|CSM<br> <br> <br>|IntS|grey|-|||red|
|NL / SB<br>/ PT|-|-|grey|-|-|-|-|
|TR|-|-|-|-|-|-|red|
||Hyphen (‘-‘) means: not applicable.<br>* When Vrelease exists, the target is an EOA and Vtarget is therefore equal to zero<br>** “With target information” only when requested by National Value<br>For NL/SB/PT modes, there is no speed monitoring, the speed pointer is therefore considered as being always below Vperm<br>For TR mode, the emergency brake command is applied, the speed pointer is therefore considered as being always above Vperm|Hyphen (‘-‘) means: not applicable.<br>* When Vrelease exists, the target is an EOA and Vtarget is therefore equal to zero<br>** “With target information” only when requested by National Value<br>For NL/SB/PT modes, there is no speed monitoring, the speed pointer is therefore considered as being always below Vperm<br>For TR mode, the emergency brake command is applied, the speed pointer is therefore considered as being always above Vperm|Hyphen (‘-‘) means: not applicable.<br>* When Vrelease exists, the target is an EOA and Vtarget is therefore equal to zero<br>** “With target information” only when requested by National Value<br>For NL/SB/PT modes, there is no speed monitoring, the speed pointer is therefore considered as being always below Vperm<br>For TR mode, the emergency brake command is applied, the speed pointer is therefore considered as being always above Vperm|Hyphen (‘-‘) means: not applicable.<br>* When Vrelease exists, the target is an EOA and Vtarget is therefore equal to zero<br>** “With target information” only when requested by National Value<br>For NL/SB/PT modes, there is no speed monitoring, the speed pointer is therefore considered as being always below Vperm<br>For TR mode, the emergency brake command is applied, the speed pointer is therefore considered as being always above Vperm|Hyphen (‘-‘) means: not applicable.<br>* When Vrelease exists, the target is an EOA and Vtarget is therefore equal to zero<br>** “With target information” only when requested by National Value<br>For NL/SB/PT modes, there is no speed monitoring, the speed pointer is therefore considered as being always below Vperm<br>For TR mode, the emergency brake command is applied, the speed pointer is therefore considered as being always above Vperm|Hyphen (‘-‘) means: not applicable.<br>* When Vrelease exists, the target is an EOA and Vtarget is therefore equal to zero<br>** “With target information” only when requested by National Value<br>For NL/SB/PT modes, there is no speed monitoring, the speed pointer is therefore considered as being always below Vperm<br>For TR mode, the emergency brake command is applied, the speed pointer is therefore considered as being always above Vperm|Hyphen (‘-‘) means: not applicable.<br>* When Vrelease exists, the target is an EOA and Vtarget is therefore equal to zero<br>** “With target information” only when requested by National Value<br>For NL/SB/PT modes, there is no speed monitoring, the speed pointer is therefore considered as being always below Vperm<br>For TR mode, the emergency brake command is applied, the speed pointer is therefore considered as being always above Vperm|


**Table 8 – Conditions for display and colour of the current train speed pointer**


**8.2.1.3** **Current train speed digital**


8.2.1.3.1 The current speed of the train shall be displayed digitally.


8.2.1.3.2 The current train speed digital shall be displayed in area B1 (see Figure 35) i.e. inside the
circular part of the pointer.


Version 4.0.0 PAGE 55 OF 317


**ERA ERTMS unit**

**ETCS Driver Machine Interface**









































**Figure 35 – Area for the current train speed digital**





8.2.1.3.3 Area B1 shall be divided along its width into three equally sized sub areas. Every digit of
the current train speed shall be placed in such a sub area and aligned to the right of the
concerned sub area. In this way, the digits will not change location depending on the
different widths of the 10 possible used digits.


8.2.1.3.4 When the speed is composed of less than 3 digits to be displayed, the right most sub
area(s) shall be used.


8.2.1.3.5 The digital numbers shall be black, except if the speed pointer has the red colour. In that
case, the digital numbers shall be white.


**8.2.1.4** **Circular Speed Gauge (CSG)**


8.2.1.4.1 The Circular Speed Gauge (CSG) shall display, around the speed dial, the Vperm,
Vtarget, VSBI and Vrelease information depending on the supervision status.


8.2.1.4.2 The CSG shall be displayed in area B2 (see Figure 36).









































**Figure 36 – Area of the Circular Speed Gauge (CSG)**





Version 4.0.0 PAGE 56 OF 317


**ERA ERTMS unit**

**ETCS Driver Machine Interface**











**Figure 37 – Size in cells of the Circular Speed Gauge (CSG)**


8.2.1.4.3 Figure 38 shows the CSG in FS mode and CSM with NoS status. Figure 39 shows the
CSG in FS mode and TSM with OvS status. Figure 39a shows the CSG in AD mode and
TSM with the ERTMS/ATO on-board driving above the SBI speed (VSBI). Figure 39b
shows the CSG in FS mode and CSM with NoS status with target information requested
by National Value.















|Col1|Col2|Col3|150<br>100 200<br>133<br>50 300<br>0 400|Col5|Col6|Col7|Col8|4000 +<br>2<br>2000<br>+<br>-<br>1000<br>22 60<br>500<br>-<br>+<br>5<br>+<br>0|Col10|Col11|Col12|Col13|Col14|Col15|Col16|Main|
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
|||||||||||||||||Over-<br>ride|
|||||||||||||60<br>+<br><br>22<br>-|60<br>+<br><br>22<br>-|60<br>+<br><br>22<br>-|60<br>+<br><br>22<br>-|Data<br>view|
|||||||||||||60<br>+<br><br>22<br>-|60<br>+<br><br>22<br>-|60<br>+<br><br>22<br>-|60<br>+<br><br>22<br>-|Spec|
|||||||||||||5|5|5|5||
||||||||||||||||||
|**2**|**2**|**2**|||||||||||||||
||||||||||||||||||
||||||||||||||||||
||||||||||||||||||
||||||||||||||||||
|||||||||||||||17:33:25|17:33:25|17:33:25|
||||||||||||||||||


Version 4.0.0 PAGE 57 OF 317


**ERA ERTMS unit**

**ETCS Driver Machine Interface**
















|Col1|Col2|Col3|150<br>100 200<br>133<br>50 300<br>0 400|Col5|Col6|Col7|Col8|Col9|4000 +<br>2<br>2000<br>+<br>-<br>1000<br>22 60<br>500<br>-<br>+<br>5<br>+<br>0|Col11|Col12|Col13|Col14|Col15|Col16|Col17|Col18|
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
||||**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**<br>**133**|**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**<br>**133**|**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**<br>**133**|**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**<br>**133**|**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**<br>**133**|**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**<br>**133**|4000<br>2000<br>1000<br>500<br>0<br>60<br>+<br>5<br>+<br>-<br>22<br>-<br>+<br>2<br>+|4000<br>2000<br>1000<br>500<br>0<br>60<br>+<br>5<br>+<br>-<br>22<br>-<br>+<br>2<br>+|4000<br>2000<br>1000<br>500<br>0<br>60<br>+<br>5<br>+<br>-<br>22<br>-<br>+<br>2<br>+|4000<br>2000<br>1000<br>500<br>0<br>60<br>+<br>5<br>+<br>-<br>22<br>-<br>+<br>2<br>+|4000<br>2000<br>1000<br>500<br>0<br>60<br>+<br>5<br>+<br>-<br>22<br>-<br>+<br>2<br>+|4000<br>2000<br>1000<br>500<br>0<br>60<br>+<br>5<br>+<br>-<br>22<br>-<br>+<br>2<br>+|4000<br>2000<br>1000<br>500<br>0<br>60<br>+<br>5<br>+<br>-<br>22<br>-<br>+<br>2<br>+|4000<br>2000<br>1000<br>500<br>0<br>60<br>+<br>5<br>+<br>-<br>22<br>-<br>+<br>2<br>+||
|||||||||||||||||||
|||||||||||||||||||
|||||||||||||||||||
|||||||||||||||||||
|||||||||||||||||||
|**2**|**2**|**2**|**2**|**2**|**2**|||||||||||||
|||||||||||||||||||
|||||||||||||||||||
|||||||||||||||||||
|||||||||||||||||||
|||||||||||||||||||
||||||||||||||||17:33:25|17:33:25|17:33:25|
|Main|Main|Main|Over-<br>ride|Data<br>view|<br>Spec|||||||||||||



**Figure 38 – Circular Speed Gauge (CSG), in FS mode and CSM with NoS status**















|Col1|Col2|Col3|150<br>100 200<br>143<br>50 300<br>0 400|Col5|Col6|Col7|Col8|4000 +<br>2<br>2000<br>+<br>-<br>1000<br>22 40<br>500<br>-<br>+<br>5<br>+<br>0|Col10|Col11|Col12|Col13|Col14|Col15|Col16|Main|
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
||||**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**<br>**143**|**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**<br>**143**|**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**<br>**143**|**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**<br>**143**|**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**<br>**143**|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>-<br>22<br>-<br>40<br>~~+~~<br>2<br>+|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>-<br>22<br>-<br>40<br>~~+~~<br>2<br>+|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>-<br>22<br>-<br>40<br>~~+~~<br>2<br>+|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>-<br>22<br>-<br>40<br>~~+~~<br>2<br>+|2|2|2|2|2|
|760|760|760|760|760|760|760|760|760|760|760|760|760|760|760|760|Over-<br>ride|
|760|760|760|760|760|760|760|760|760|760|760|760|-<br>+|-<br>+|-<br>+|-<br>+|-<br>+|
|760|760|760|760|760|760|760|760|760|760|760|760|22<br>40|22<br>40|22<br>40|22<br>40|Data<br>view|
|760|760|760|760|760|760|760|760|760|760|760|760|||||Spec|
|760|760|760|760|760|760|760|760|760|760|760|760|-|-|-|-|-|
|760|760|760|760|760|760|760|760|760|760|760|760|+|+|+|+|+|
|760|760|760|760|760|760|760|760|760|760|760|760|5|5|5|5||
||||||||||||||||||
|**2**|**2**|**2**|||||||||||||||
||||||||||||||||||
||||||||||||||||||
||||||||||||||||||
||||||||||||||||||
|||||||||||||||17:33:25|17:33:25|17:33:25|
||||||||||||||||||


Version 4.0.0 PAGE 58 OF 317


**ERA ERTMS unit**

**ETCS Driver Machine Interface**


















|Col1|Col2|Col3|Col4|Col5|Col6|Col7|Col8|Col9|4000 +<br>2<br>2000<br>+<br>-<br>1000<br>22 40<br>500<br>-<br>+<br>5<br>+<br>0|Col11|Col12|Col13|Col14|Col15|Col16|Col17|Col18|
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
||||||||||4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>-<br>22<br>-<br>40<br>+<br>2<br>+|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>-<br>22<br>-<br>40<br>+<br>2<br>+|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>-<br>22<br>-<br>40<br>+<br>2<br>+|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>-<br>22<br>-<br>40<br>+<br>2<br>+|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>-<br>22<br>-<br>40<br>+<br>2<br>+|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>-<br>22<br>-<br>40<br>+<br>2<br>+|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>-<br>22<br>-<br>40<br>+<br>2<br>+|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>-<br>22<br>-<br>40<br>+<br>2<br>+||
|760|760|760|760|760|760|760|760|760|760|760|760|760|760|760|760|760|760|
|760|760|760|760|760|760|760|760|760|760|760|760|760|760|760|760|760||
|760|760|760|760|760|760|760|760|760|760|760|760|760|760|760|760|760||
|760|760|760|760|760|760|760|760|760|760|760|760|760|760|760|760|760||
|||||||||||||||||||
|**2**|**2**|**2**|**2**|**2**|**2**|||||||||||||
|||||||||||||||||||
|||||||||||||||||||
|||||||||||||||||||
|||||||||||||||||||
|||||||||||||||||||
||||||||||||||||17:33:25|17:33:25|17:33:25|
|Main|Main|Main|Over-<br>ride|Data<br>view|Spec|||||||||||||



**Figure 39 – Circular Speed Gauge (CSG), in FS mode and TSM with OvS status**


Version 4.0.0 PAGE 59 OF 317


**ERA ERTMS unit**

**ETCS Driver Machine Interface**






|Col1|Col2|Col3|150<br>100 200<br>152<br>50 300<br>0 400|Col5|Col6|Col7|Col8|4000 +<br>2<br>2000<br>+<br>-<br>1000<br>22 40<br>500<br>-<br>+<br>5<br>+<br>0<br>Welwyn North<br>ATO 17:36:48|Col10|Col11|Col12|Main|
|---|---|---|---|---|---|---|---|---|---|---|---|---|
|760|760|760|760|760|760|760|760|760|760|760|760|Over-<br>ride|
|760|760|760|760|760|760|760|760|760|760|760|760|Data<br>view|
|760|760|760|760|760|760|760|760|760|760|760|760|Spec|
|760|760|760|760|760|760|760|760|760|760|760|760||
||||||||||||||
|**2**|**2**|**2**||||||ATO|ATO|ATO|||
||||||||||||||
||||||||||||||
||||||||||||||
||||||||||||||
|||||||||||17:33:25|17:33:25|17:33:25|
||||||||||||||


























|Col1|Col2|Col3|150<br>100 200<br>152<br>50 300<br>0 400|Col5|Col6|Col7|Col8|Col9|Col10|Col11|4000 +<br>2<br>2000<br>+<br>-<br>1000<br>22 40<br>500<br>-<br>+<br>5<br>+<br>0|Col13|Col14|Col15|Col16|Col17|Col18|Col19|
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
||||**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**<br>**152**|**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**<br>**152**|**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**<br>**152**|**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**<br>**152**|**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**<br>**152**|**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**<br>**152**|**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**<br>**152**|**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**<br>**152**|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>-<br>22<br>-<br>40<br>+<br>2<br>+|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>-<br>22<br>-<br>40<br>+<br>2<br>+|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>-<br>22<br>-<br>40<br>+<br>2<br>+|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>-<br>22<br>-<br>40<br>+<br>2<br>+|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>-<br>22<br>-<br>40<br>+<br>2<br>+|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>-<br>22<br>-<br>40<br>+<br>2<br>+|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>-<br>22<br>-<br>40<br>+<br>2<br>+||
|760|760|760|760|760|760|760|760|760|760|760|760|760|760|760|760|760|760|760|
|760|760|760|760|760|760|760|760|760|760|760|760|760|760|760|760|760|760||
|760|760|760|760|760|760|760|760|760|760|760|760|760|760|760|760|760|760||
|760|760|760|760|760|760|760|760|760|760|760|760|760|760|760|760|760|760||
|760|760|760|||||||||||||||||
||||||||||||||||||||
|**2**|**2**|**2**|||||||||ATO|ATO|ATO|ATO|ATO||||
||||||||||||||||||||
||||||||||||||||||||
||||||||||||||||||||
||||||||||||||||||||
||||||||||||||||||||
||||||||||||||||17:33:25|17:33:25|17:33:25|17:33:25|
|Main|Main|Main|Over-<br>ride|Data<br>view|Data<br>view|Spec|Spec||||||||ATO|ATO|||



**Figure 39a – Circular Speed Gauge (CSG), in AD mode and TSM with the ERTMS/ATO on-board driving**
**above VSBI**


Version 4.0.0 PAGE 60 OF 317


**ERA ERTMS unit**

**ETCS Driver Machine Interface**
















|Col1|Col2|Col3|150<br>100 200<br>133<br>50 300<br>0 400|Col5|Col6|Col7|Col8|4000 +<br>2<br>2000<br>+<br>-<br>1000<br>22 60<br>500<br>-<br>+<br>5<br>+<br>0|Col10|Col11|Col12|Col13|Col14|Main|
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
|760|760|760|760|760|760|760|760|760|760|760|760|760|760|Over-<br>ride|
|760|760|760|760|760|760|760|760|760|760|760|760|760|760|Data<br>view|
|760|760|760|760|760|760|760|760|760|760|760|760|760|760|Spec|
|760|760|760|760|760|760|760|760|760|760|760|760|760|760||
||||||||||||||||
|**2**|**2**|**2**|||||||||||||
||||||||||||||||
||||||||||||||||
||||||||||||||||
|||||||||||||17:33:25|17:33:25|17:33:25|
||||||||||||||||






|Col1|Col2|Col3|150<br>100 200<br>133<br>50 300<br>0 400|Col5|Col6|Col7|Col8|Col9|Col10|Col11|4000 +<br>2<br>2000<br>+<br>-<br>1000<br>22 60<br>500<br>-<br>+<br>5<br>+<br>0|Col13|Col14|Col15|Col16|Col17|Col18|Col19|Col20|Col21|
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
||||**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**<br>**133**|**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**<br>**133**|**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**<br>**133**|**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**<br>**133**|**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**<br>**133**|**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**<br>**133**|**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**<br>**133**|**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**<br>**133**|4000<br>2000<br>1000<br>500<br>0<br>60<br>+<br>5<br>+<br>-<br>22<br>-<br>+<br>2<br>+|4000<br>2000<br>1000<br>500<br>0<br>60<br>+<br>5<br>+<br>-<br>22<br>-<br>+<br>2<br>+|4000<br>2000<br>1000<br>500<br>0<br>60<br>+<br>5<br>+<br>-<br>22<br>-<br>+<br>2<br>+|4000<br>2000<br>1000<br>500<br>0<br>60<br>+<br>5<br>+<br>-<br>22<br>-<br>+<br>2<br>+|4000<br>2000<br>1000<br>500<br>0<br>60<br>+<br>5<br>+<br>-<br>22<br>-<br>+<br>2<br>+|4000<br>2000<br>1000<br>500<br>0<br>60<br>+<br>5<br>+<br>-<br>22<br>-<br>+<br>2<br>+|4000<br>2000<br>1000<br>500<br>0<br>60<br>+<br>5<br>+<br>-<br>22<br>-<br>+<br>2<br>+|4000<br>2000<br>1000<br>500<br>0<br>60<br>+<br>5<br>+<br>-<br>22<br>-<br>+<br>2<br>+|4000<br>2000<br>1000<br>500<br>0<br>60<br>+<br>5<br>+<br>-<br>22<br>-<br>+<br>2<br>+||
|760|760|760|760|760|760|760|760|760|760|760|760|760|760|760|760|760|760|760|760|760|
|760|760|760|760|760|760|760|760|760|760|760|760|760|760|760|760|760|760|760|760||
|760|760|760|760|760|760|760|760|760|760|760|760|760|760|760|760|760|760|760|760||
|760|760|760|760|760|760|760|760|760|760|760|760|760|760|760|760|760|760|760|760||
||||||||||||||||||||||
|**2**|**2**|**2**|||||||||||||||||||
||||||||||||||||||||||
||||||||||||||||||||||
||||||||||||||||||||||
||||||||||||||||||||||
||||||||||||||||||||||
||||||||||||||||||17:33:25|17:33:25|17:33:25|17:33:25|
|Main|Main|Main|Over-<br>ride|Data<br>view|Data<br>view|Spec|Spec||||||||||||||



**Figure 39b – Circular Speed Gauge (CSG), in FS mode and CSM with NoS status with target**
**information requested by National Value**


8.2.1.4.4 Assuming that 0 degrees is vertically upwards from the centre of the speed dial, the CSG
shall be placed along the outside border of the speed dial, but from –149 degrees to +144
degrees.


8.2.1.4.5 When the CSG is shown, the part of the CSG from –149 degrees to -144 degrees (i.e. 0
km/h) shall always be displayed with dark grey.


8.2.1.4.6 The width of the CSG shall be 9 cells from zero up to the hook as shown in Figure 37.


Version 4.0.0 PAGE 61 OF 317


**ERA ERTMS unit**

**ETCS Driver Machine Interface**


8.2.1.4.7 At Vperm, the CSG shall display a ‘hook’ covering the outer border of the speed dial. The
size of the hook shall be 6x20 cells (see Figure 37) and the upper limit of the hook shall
be at Vperm.


8.2.1.4.8 While the Over-speed, the Warning or the Intervention Status is active, the CSG between
the ‘hook’ (Vperm) and VSBI shall have the same width as the ‘hook’ (see Figure 39).


8.2.1.4.9 The CSG shall follow the DMI colour as defined in Table 9.





























|Mode|Supervision<br>Status|Col3|0 km/h ≤ CSG<br>≤ V<br>perm|0 km/h ≤ CSG<br>≤ V *<br>release<br>(when<br>Vrelease<br>exists)|0 km/h ≤ CSG<br>< V<br>target|V ≤ CSG ≤<br>target<br>V<br>perm|V < CSG ≤<br>perm<br>V<br>SBI|
|---|---|---|---|---|---|---|---|
|FS<br> <br> <br> <br> <br> <br> <br> <br> <br> <br> <br> <br> <br> <br>|CSM<br> <br> <br>|NoS|dark grey|-|-|-|-|
|FS<br> <br> <br> <br> <br> <br> <br> <br> <br> <br> <br> <br> <br> <br>|CSM<br> <br> <br>|OvS|dark grey|-|-|-|orange|
|FS<br> <br> <br> <br> <br> <br> <br> <br> <br> <br> <br> <br> <br> <br>|CSM<br> <br> <br>|WaS|dark grey|-|-|-|orange|
|FS<br> <br> <br> <br> <br> <br> <br> <br> <br> <br> <br> <br> <br> <br>|CSM<br> <br> <br>|IntS|dark grey|-|-|-|red|
|FS<br> <br> <br> <br> <br> <br> <br> <br> <br> <br> <br> <br> <br> <br>|CSM (with<br>target<br>information)<br>**<br> <br> <br>|NoS|-|-|dark grey|white|-|
|FS<br> <br> <br> <br> <br> <br> <br> <br> <br> <br> <br> <br> <br> <br>|CSM (with<br>target<br>information)<br>**<br> <br> <br>|OvS|-|-|dark grey|white|orange|
|FS<br> <br> <br> <br> <br> <br> <br> <br> <br> <br> <br> <br> <br> <br>|CSM (with<br>target<br>information)<br>**<br> <br> <br>|WaS|-|-|dark grey|white|orange|
|FS<br> <br> <br> <br> <br> <br> <br> <br> <br> <br> <br> <br> <br> <br>|CSM (with<br>target<br>information)<br>**<br> <br> <br>|IntS|-|-|dark grey|white|red|
|FS<br> <br> <br> <br> <br> <br> <br> <br> <br> <br> <br> <br> <br> <br>|TSM<br> <br> <br>|IndS|-|medium grey|dark grey|yellow|-|
|FS<br> <br> <br> <br> <br> <br> <br> <br> <br> <br> <br> <br> <br> <br>|TSM<br> <br> <br>|OvS|-|medium grey|dark grey|yellow|orange|
|FS<br> <br> <br> <br> <br> <br> <br> <br> <br> <br> <br> <br> <br> <br>|TSM<br> <br> <br>|WaS|-|medium grey|dark grey|yellow|orange|
|FS<br> <br> <br> <br> <br> <br> <br> <br> <br> <br> <br> <br> <br> <br>|TSM<br> <br> <br>|IntS|-|medium grey|dark grey|yellow|red|
|FS<br> <br> <br> <br> <br> <br> <br> <br> <br> <br> <br> <br> <br> <br>|RSM<br>|IndS|-|medium grey|-|yellow|-|
|FS<br> <br> <br> <br> <br> <br> <br> <br> <br> <br> <br> <br> <br> <br>|RSM<br>|IntS|-|medium grey|-|yellow|-|
|AD<br> <br> <br> <br> <br> <br> <br> <br> <br> <br> <br> <br> <br>|CSM<br> <br> <br>|NoS|dark grey|-|-|-|-|
|AD<br> <br> <br> <br> <br> <br> <br> <br> <br> <br> <br> <br> <br>|CSM<br> <br> <br>|OvS|dark grey|-|-|-|dark grey|
|AD<br> <br> <br> <br> <br> <br> <br> <br> <br> <br> <br> <br> <br>|CSM<br> <br> <br>|WaS|dark grey|-|-|-|dark grey|
|AD<br> <br> <br> <br> <br> <br> <br> <br> <br> <br> <br> <br> <br>|CSM<br> <br> <br>|IntS|-|-|-|-|-|
|AD<br> <br> <br> <br> <br> <br> <br> <br> <br> <br> <br> <br> <br>|CSM (with<br>target<br>information)<br>**<br> <br> <br>|NoS|-|-|dark grey|white|-|
|AD<br> <br> <br> <br> <br> <br> <br> <br> <br> <br> <br> <br> <br>|CSM (with<br>target<br>information)<br>**<br> <br> <br>|OvS|-|-|dark grey|white|white|
|AD<br> <br> <br> <br> <br> <br> <br> <br> <br> <br> <br> <br> <br>|CSM (with<br>target<br>information)<br>**<br> <br> <br>|WaS|-|-|dark grey|white|white|
|AD<br> <br> <br> <br> <br> <br> <br> <br> <br> <br> <br> <br> <br>|CSM (with<br>target<br>information)<br>**<br> <br> <br>|IntS|-|-|-|-|-|
|AD<br> <br> <br> <br> <br> <br> <br> <br> <br> <br> <br> <br> <br>|TSM<br> <br> <br>|IndS|-|medium grey|dark grey|white|-|
|AD<br> <br> <br> <br> <br> <br> <br> <br> <br> <br> <br> <br> <br>|TSM<br> <br> <br>|OvS|-|medium grey|dark grey|white|white|
|AD<br> <br> <br> <br> <br> <br> <br> <br> <br> <br> <br> <br> <br>|TSM<br> <br> <br>|WaS|-|medium grey|dark grey|white|white|
|AD<br> <br> <br> <br> <br> <br> <br> <br> <br> <br> <br> <br> <br>|TSM<br> <br> <br>|IntS|-|-|-|-|-|
|AD<br> <br> <br> <br> <br> <br> <br> <br> <br> <br> <br> <br> <br>|RSM|IndS|-|medium grey|-|white|-|


Version 4.0.0 PAGE 62 OF 317


**ERA ERTMS unit**

**ETCS Driver Machine Interface**
















|Mode|Supervision<br>Status|Col3|0 km/h ≤ CSG<br>≤ V<br>perm|0 km/h ≤ CSG<br>≤ V *<br>release<br>(when<br>Vrelease<br>exists)|0 km/h ≤ CSG<br>< V<br>target|V ≤ CSG ≤<br>target<br>V<br>perm|V < CSG ≤<br>perm<br>V<br>SBI|
|---|---|---|---|---|---|---|---|
|||IntS|-|-|-|-|-|
|SB / LS /<br>SM / OS /<br>SR / SH /<br>UN / RV /<br>TR / PT /<br>NL|-|AllS|-|-|-|-|-|
||Hyphen (‘-‘) means: not applicable<br>* When Vrelease exists, the target is an EOA and Vtarget is therefore equal to zero<br>** “With target information” only when requested by National Value|Hyphen (‘-‘) means: not applicable<br>* When Vrelease exists, the target is an EOA and Vtarget is therefore equal to zero<br>** “With target information” only when requested by National Value|Hyphen (‘-‘) means: not applicable<br>* When Vrelease exists, the target is an EOA and Vtarget is therefore equal to zero<br>** “With target information” only when requested by National Value|Hyphen (‘-‘) means: not applicable<br>* When Vrelease exists, the target is an EOA and Vtarget is therefore equal to zero<br>** “With target information” only when requested by National Value|Hyphen (‘-‘) means: not applicable<br>* When Vrelease exists, the target is an EOA and Vtarget is therefore equal to zero<br>** “With target information” only when requested by National Value|Hyphen (‘-‘) means: not applicable<br>* When Vrelease exists, the target is an EOA and Vtarget is therefore equal to zero<br>** “With target information” only when requested by National Value|Hyphen (‘-‘) means: not applicable<br>* When Vrelease exists, the target is an EOA and Vtarget is therefore equal to zero<br>** “With target information” only when requested by National Value|



**Table 9 – Conditions for display and colour of the circular speed gauge**


**8.2.1.5** **Basic Speed Hook(s)**


8.2.1.5.1 The Basic Speed Hook(s) shall display, around the speed dial, the Vperm and Vtarget
information depending on the supervision status.


8.2.1.5.2 The Basic Speed Hook(s) shall be displayed in area B2 (see Figure 40).









































**Figure 40 – Area of the Basic Speed Hook(s)**





8.2.1.5.3 Examples of Basic Speed Hook(s) are given in Figure 41, Figure 42, Figure 43 and Figure
44.


Version 4.0.0 PAGE 63 OF 317


**ERA ERTMS unit**

**ETCS Driver Machine Interface**














|Col1|150<br>100 200<br>36<br>50 300<br>0 400|Col3|Col4|Col5|Col6|4000<br>2000<br>1000<br>- 0<br>500 22<br>-<br>+<br>5<br>+<br>0|Col8|Col9|Col10|Main|
|---|---|---|---|---|---|---|---|---|---|---|
||**36**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**36**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**36**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**36**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**36**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>0<br>-<br>22<br>-|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>0<br>-<br>22<br>-|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>0<br>-<br>22<br>-|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>0<br>-<br>22<br>-|Over-<br>ride|
||**36**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**36**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**36**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**36**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**36**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>0<br>-<br>22<br>-|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>0<br>-<br>22<br>-|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>0<br>-<br>22<br>-|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>0<br>-<br>22<br>-|Data<br>view|
||**36**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**36**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**36**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**36**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**36**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>0<br>-<br>22<br>-|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>0<br>-<br>22<br>-|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>0<br>-<br>22<br>-|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>0<br>-<br>22<br>-|Spec|
||**36**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**36**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**36**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**36**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**36**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>0<br>-<br>22<br>-|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>0<br>-<br>22<br>-|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>0<br>-<br>22<br>-|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>0<br>-<br>22<br>-||
|**2**|||||||||||
||||||||||||
||||||||||17:33:25|17:33:25|






|Col1|150<br>100 200<br>36<br>50 300<br>0 400|Col3|Col4|Col5|Col6|Col7|Col8|4000<br>2000<br>1000<br>- 0<br>500 22<br>-<br>+<br>5<br>+<br>0|Col10|Col11|Col12|Col13|Col14|Col15|Col16|
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
||**36**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**36**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**36**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**36**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**36**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**36**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**36**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>0<br>-<br>22<br>-|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>0<br>-<br>22<br>-|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>0<br>-<br>22<br>-|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>0<br>-<br>22<br>-|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>0<br>-<br>22<br>-|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>0<br>-<br>22<br>-|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>0<br>-<br>22<br>-||
|||||||||||||||||
|||||||||||||||||
|||||||||||||||||
|||||||||||||||||
|||||||||||||||||
|**2**||||||||||||||||
|||||||||||||||||
|||||||||||||||||
|||||||||||||||||
|||||||||||||||||
||||||||||||||17:33:25|17:33:25|17:33:25|
|Main|Over-<br>ride|Data<br>view|Data<br>view|Spec|Spec|||||||||||



**Figure 41 – Basic Speed Hook(s), OS mode in CSM/NoS**


Version 4.0.0 PAGE 64 OF 317


**ERA ERTMS unit**

**ETCS Driver Machine Interface**


















|Col1|Col2|Col3|150<br>100 200<br>36<br>50 300<br>0 400<br>20|Col5|Col6|Col7|Col8|4000<br>2000<br>1000<br>500<br>+ 0<br>5<br>+<br>0|Col10|Col11|Col12|Col13|Col14|Main|
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
|290|290|290|290|290|290|290|290|290|290|290|290|290|290|Over-<br>ride|
|290|290|290|290|290|290|290|290|290|290|290|290|290|290|Data<br>view|
|290|290|290|290|290|290|290|290|290|290|290|290|290|290|Spec|
|290|290|290|290|290|290|290|290|290|290|290|290|290|290||
||||||||||||||||
|**2**|**2**|**2**|||||||||||||
||||||||||||||||
||||||||||||||||
||||||||||||||||
|||||||||||||17:33:25|17:33:25|17:33:25|
||||||||||||||||






|Col1|Col2|Col3|150<br>100 200<br>36<br>50 300<br>0 400<br>20|Col5|Col6|Col7|Col8|Col9|Col10|Col11|4000<br>2000<br>1000<br>500<br>+ 0<br>5<br>+<br>0|Col13|Col14|Col15|Col16|Col17|Col18|Col19|Col20|Col21|
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
||||**36**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**<br>20|**36**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**<br>20|**36**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**<br>20|**36**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**<br>20|**36**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**<br>20|**36**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**<br>20|**36**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**<br>20|**36**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**<br>20|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>0|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>0|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>0|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>0|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>0|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>0|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>0|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>0|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>0||
|290|290|290|290|290|290|290|290|290|290|290|290|290|290|290|290|290|290|290|290|290|
|290|290|290|290|290|290|290|290|290|290|290|290|290|290|290|290|290|290|290|290||
|290|290|290|290|290|290|290|290|290|290|290|290|290|290|290|290|290|290|290|290||
|290|290|290|290|290|290|290|290|290|290|290|290|290|290|290|290|290|290|290|290||
|290|290|290|20|20|20|20|20|20|20|20|20|20|20|20|20|20|20|20|20|20|
||||||||||||||||||||||
|**2**|**2**|**2**|||||||||||||||||||
||||||||||||||||||||||
||||||||||||||||||||||
||||||||||||||||||||||
||||||||||||||||||||||
||||||||||||||||||||||
||||||||||||||||||17:33:25|17:33:25|17:33:25|17:33:25|
|Main|Main|Main|Over-<br>ride|Data<br>view|Data<br>view|Spec|Spec||||||||||||||



**Figure 42 – Basic Speed Hook(s), OS mode in TSM/IndS with a release speed**


**Figure 43 – Intentionally deleted**


Version 4.0.0 PAGE 65 OF 317


**ERA ERTMS unit**

**ETCS Driver Machine Interface**






|Col1|Col2|Col3|150<br>100 200<br>102<br>50 300<br>0 400|Col5|Col6|Col7|Col8|Col9|Col10|Col11|Col12|Col13|Col14|Main|
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
|140|140|140|140|140|140|140|140|140|140|140|140|140|140|Over-<br>ride|
|140|140|140|140|140|140|140|140|140|140|140|140|140|140|Data<br>view|
|140|140|140|140|140|140|140|140|140|140|140|140|140|140|Spec|
|140|140|140|140|140|140|140|140|140|140|140|140|140|140||
||||||||||||||||
|**2**|**2**|**2**|||||||||||||
||||||||||||||||
||||||||||||||||
||||||||||||||||
|||||||||||||17:33:25|17:33:25|17:33:25|
||||||||||||||||






|Col1|Col2|Col3|150<br>100 200<br>102<br>50 300<br>0 400|Col5|Col6|Col7|Col8|Col9|Col10|Col11|Col12|Col13|Col14|Col15|Col16|Col17|Col18|Col19|Col20|Col21|
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
||||**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**<br>**102**|**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**<br>**102**|**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**<br>**102**|**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**<br>**102**|**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**<br>**102**|**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**<br>**102**|**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**<br>**102**|**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**<br>**102**|||||||||||
|140|140|140|140|140|140|140|140|140|140|140|140|140|140|140|140|140|140|140|140|140|
|140|140|140|140|140|140|140|140|140|140|140|140|140|140|140|140|140|140|140|140||
|140|140|140|140|140|140|140|140|140|140|140|140|140|140|140|140|140|140|140|140||
|140|140|140|140|140|140|140|140|140|140|140|140|140|140|140|140|140|140|140|140||
|140|140|140|||||||||||||||||||
||||||||||||||||||||||
|**2**|**2**|**2**|||||||||||||||||||
||||||||||||||||||||||
||||||||||||||||||||||
||||||||||||||||||||||
||||||||||||||||||||||
||||||||||||||||||||||
||||||||||||||||||17:33:25|17:33:25|17:33:25|17:33:25|
|Main|Main|Main|Over-<br>ride|Data<br>view|Data<br>view|Spec|Spec||||||||||||||



**Figure 44 – Basic Speed Hook(s), SR mode in TSM/IndS with a speed restriction at 90km/h**


**Figure 45 – Intentionally deleted**


8.2.1.5.4 At Vperm, a first ‘hook’ shall be displayed overlapping the outer border of the speed dial.
The size of the hook shall be 10x20 cells and the upper limit of the hook shall be at Vperm.


8.2.1.5.5 At Vtarget, a second ‘hook’ shall be displayed overlapping the outer border of the speed
dial. The size of the hook shall be 10x20 cells and the upper limit of the hook shall be at
Vtarget.


8.2.1.5.6 When the two hooks overlap each other, the overlapping part of the hook at Vperm shall
overlay the hook at Vtarget


Version 4.0.0 PAGE 66 OF 317


**ERA ERTMS unit**

**ETCS Driver Machine Interface**


8.2.1.5.7 The Basic Speed Hook(s) shall follow the DMI colour as defined in Table 10.






















|Col1|Col2|Col3|Basic Speed Hook(s)|Col5|
|---|---|---|---|---|
|Mode|Supervision Status|Supervision Status|hook at Vperm|hook at Vtarget|
|SM /<br>OS* /<br>SR*<br> <br> <br>|CSM|AllS|white|-|
|SM /<br>OS* /<br>SR*<br> <br> <br>|CSM (with<br>target<br>information)**|AllS|white|medium grey|
|SM /<br>OS* /<br>SR*<br> <br> <br>|TSM|AllS|white|medium grey|
|SM /<br>OS* /<br>SR*<br> <br> <br>|RSM (not<br>applicable for<br>SR)|AllS|white|medium grey|
|SH*|CSM|AllS|white|-|
|RV|CSM|AllS|white|-|
|SB / FS<br>/ AD /<br>TR / PT<br>/ NL /<br>UN / LS|-|AllS|-|-|



Hyphen (‘-‘) means: not applicable.


               - The Basic Speed Hook(s) is/are shown if driver has requested to display it (toggle
on) (see chapter 8.2.2.4 for the toggling function)


** “With target information” only when requested by National Value


**Table 10 – Conditions for display and colour of the Basic Speed Hook(s)**


**8.2.1.6** **Release speed**


8.2.1.6.1 The graphical presentation of the release speed shall be displayed in area B2 (see Figure
46).


8.2.1.6.2 The digital presentation of the release speed shall be displayed in area B6 (see Figure
46).















































**Figure 46 – Areas for the Release speed**





Version 4.0.0 PAGE 67 OF 317


**ERA ERTMS unit**

**ETCS Driver Machine Interface**











**Figure 47 – Release speed, when V** perm **> V** release











**Figure 48 – Release speed, when V** perm **< V** release


8.2.1.6.3 When a Release speed exists, its graphical presentation shall be shown on the CSG as
specified in Table 9.


8.2.1.6.4 When the Release speed is shown on the CSG, it shall be shown at the outer part of the
CSG. This Release speed display (Vrelease) shall be separated from the permitted speed
display (Vperm) by a 1 cell line being in the background colour. The permitted speed
display below the Release speed value shall have a width of 3 cells. The width of the
Release speed display shall ensure that the total width of the CSG is always kept at 9
cells (see Figure 47 and Figure 48).


8.2.1.6.5 When a Release speed exists, its digital presentation shall be displayed with a number as
specified in Table 11.


Version 4.0.0 PAGE 68 OF 317


**ERA ERTMS unit**

**ETCS Driver Machine Interface**




















|Mode|Supervision Status|Col3|Release speed digital|
|---|---|---|---|
|FS / SM /<br>OS* / LS<br> <br> <br>|CSM|AllS|no|
|FS / SM /<br>OS* / LS<br> <br> <br>|CSM (with<br>target<br>information)**|AllS|no|
|FS / SM /<br>OS* / LS<br> <br> <br>|TSM|AllS|yes (yellow)|
|FS / SM /<br>OS* / LS<br> <br> <br>|RSM|AllS|yes (yellow)|
|AD<br> <br> <br>|CSM|AllS|no|
|AD<br> <br> <br>|CSM (with<br>target<br>information)**|AllS|no|
|AD<br> <br> <br>|TSM|AllS|yes (medium grey)|
|AD<br> <br> <br>|RSM|AllS|yes (medium grey)|
|SB / SH /<br>UN / PT /<br>TR / NL /<br>SR / RV|-|AllS|no|




              - For OS, the digital presentation of the release speed is shown if driver has
requested to display it (toggle on) (see chapter 8.2.2.4 for the toggling function)


** “With target information” only when requested by National Value


**Table 11 – Conditions for display of the release speed digital**


**8.2.1.7** **Lowest Supervised Speed within the Movement Authority (LSSMA)**


8.2.1.7.1 The Lowest Supervised Speed within the Movement Authority (LSSMA) shall be displayed
in area A1 (see Figure 48a).































**Figure 48a – Area of the Lowest Supervised Speed within Movement Authority (LSSMA)**


8.2.1.7.2 Figure 48b gives an example of the LSSMA.


Version 4.0.0 PAGE 69 OF 317


**ERA ERTMS unit**

**ETCS Driver Machine Interface**


|120|150<br>100 200<br>88<br>50 300<br>0 400|Col3|Col4|Col5|Col6|Col7|Col8|Col9|Col10|Col11|Col12|Main|
|---|---|---|---|---|---|---|---|---|---|---|---|---|
|||||||||||||Over-<br>ride|
|||||||||||||Data<br>view|
|||||||||||||Spec|
||||||||||||||
||||||||||||||
|**1**|||||||||||||
||||||||||||||
||||||||||||||
||||||||||||||
||||||||||||||
||||||||||||||






|120|150<br>100 200<br>88<br>50 300<br>0 400|Col3|Col4|Col5|Col6|Col7|Col8|Col9|Col10|Col11|Col12|Col13|Col14|Col15|Col16|
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
|120|**88**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**88**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**88**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**88**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**88**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**88**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**88**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|||||||||
|120|**88**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**88**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**88**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**88**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**88**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**88**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**88**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|||||||||
|120|**88**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**88**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**88**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**88**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**88**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**88**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**88**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|||||||||
|120|**88**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**88**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**88**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**88**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**88**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**88**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**88**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|||||||||
|120|**88**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**88**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**88**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**88**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**88**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**88**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**88**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|||||||||
|**1**||||||||||||||||
|||||||||||||||||
|||||||||||||||||
||||||||||||||17:33:25|17:33:25|17:33:25|
|Main|Over-<br>ride|Data<br>view|<br>Spec|<br>Spec||||||||||||



**Figure 48b – LSSMA at 120 km/h**


8.2.1.7.3 When the display conditions defined in document [2] are fulfilled, the LSSMA shall be
shown with a number in grey vertically and horizontally centred in A1.


8.2.1.7.4 When the LSSMA number is displayed, the symbol LS01 (see chapter 13) shall also be
used in area A1 to indicate that this speed is specific to the Limited Supervision mode and
therefore does not substitute the observance of the line-side information.


8.2.1.7.5 The LSSMA number shall overlay the symbol LS01.


**8.2.2** **Brake Information**


Version 4.0.0 PAGE 70 OF 317


**ERA ERTMS unit**

**ETCS Driver Machine Interface**


**8.2.2.1** **Distance to target bar**


8.2.2.1.1 This DMI object shows the remaining distance to target bar.


8.2.2.1.2 The distance to target bar shall be displayed in area A3 (see Figure 49).





































































































**Figure 49 – Area for distance to target bar**


8.2.2.1.3 Figure 50 gives an example of the distance to target bar.















|Col1|Col2|Col3|150<br>100 200<br>67<br>50 300<br>0 400|Col5|Col6|Col7|Col8|4000<br>2000<br>1000<br>500<br>+ 0<br>5<br>+<br>0|Col10|Col11|Col12|Col13|Col14|Col15|Col16|Main|
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
|290|290|290|290|290|290|290|290|290|290|290|290|290|290|290|290|Over-<br>ride|
|290|290|290|290|290|290|290|290|290|290|290|290|290|290|290|290|Data<br>view|
|290|290|290|290|290|290|290|290|290|290|290|290|290|290|290|290|Spec|
|290|290|290|290|290|290|290|290|290|290|290|290|5|5|5|5||
||||||||||||||||||
|**2**|**2**|**2**|||||||||||||||
||||||||||||||||||
||||||||||||||||||
||||||||||||||||||
||||||||||||||||||
|||||||||||||||17:33:25|17:33:25|17:33:25|
||||||||||||||||||


Version 4.0.0 PAGE 71 OF 317


**ERA ERTMS unit**

**ETCS Driver Machine Interface**


















|Col1|Col2|Col3|150<br>100 200<br>67<br>50 300<br>0 400|Col5|Col6|Col7|Col8|Col9|4000<br>2000<br>1000<br>500<br>+ 0<br>5<br>+<br>0|Col11|Col12|Col13|Col14|Col15|Col16|Col17|Col18|
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
||||**67**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**67**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**67**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**67**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**67**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**67**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>0|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>0|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>0|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>0|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>0|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>0|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>0|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>0||
|290|290|290|290|290|290|290|290|290|290|290|290|290|290|290|290|290|290|
|290|290|290|290|290|290|290|290|290|290|290|290|290|290|290|290|290||
|290|290|290|290|290|290|290|290|290|290|290|290|290|290|290|290|290||
|290|290|290|290|290|290|290|290|290|290|290|290|290|290|290|290|290||
|||||||||||||||||||
|**2**|**2**|**2**|**2**|**2**|**2**|||||||||||||
|||||||||||||||||||
|||||||||||||||||||
|||||||||||||||||||
|||||||||||||||||||
|||||||||||||||||||
||||||||||||||||17:33:25|17:33:25|17:33:25|
|Main|Main|Main|Over-<br>ride|Data<br>view|Spec|||||||||||||



**Figure 50 – Distance to target**


8.2.2.1.4 A distance scale shall be displayed on the left hand side of the area A3 from 0 to 1000
metres. The distance scale between 0 and 100 m shall be linear, then it shall be
logarithmic from 100 m to 1000 m. At each of the positions defined in Table 12, a distance
indicator line shall be drawn horizontally. For 0, 500 and 1000 metres, the distance
indicator lines shall be with a width of 2 cells and a length of 13 cells. The other lines shall
be shorter distance indicator lines with a width of 1 cell and a length of 9 cells.







|Distance<br>indicator line|position of distance indicator<br>lines|
|---|---|
|1000|(12,-1)|
|900|(16,6)|
|800|(16,13)|
|700|(16,22)|
|600|(16,32)|
|500|(12,45)|
|400|(16,59)|
|300|(16,79)|
|200|(16,105)|
|100|(16,152)|
|0|(12,185)|


**Table 12 –Distance scale for the target distance bar**


Version 4.0.0 PAGE 72 OF 317


**ERA ERTMS unit**

**ETCS Driver Machine Interface**


8.2.2.1.5 The distance indicator lines shall be grey.


8.2.2.1.6 The target distance shall be indicated by a vertical rectangular bar with a width of 10 cells
on the right hand side of the area A3. The bottom left corner of the vertical rectangular bar
shall be positioned at (29,186).The vertical rectangular bar shall display the remaining
distance to the target from 0 to maximum 1000 metres as specified by the distance scale.
For distances above 1000 metres, the vertical rectangular bar shall display 1000 metres.


8.2.2.1.7 The vertical rectangular bar shall be grey.


8.2.2.1.8 The distance to target bar and the distance scale shall be shown in A3 as specified in
Table 13.
















|Mode|Supervision Status|Col3|Distance to target bar|
|---|---|---|---|
|FS / AD /<br>SM<br> <br> <br>|CSM|AllS|no|
|FS / AD /<br>SM<br> <br> <br>|CSM (with<br>target<br>information)*|AllS|yes|
|FS / AD /<br>SM<br> <br> <br>|TSM|AllS|yes|
|FS / AD /<br>SM<br> <br> <br>|RSM|AllS|yes|
|RV|-|AllS|yes|
|SB / SH /<br>UN / PT /<br>TR / NL /<br>LS / OS /<br>SR|-|AllS|no|




              - “With target information” only when requested by National Value


**Table 13 – Conditions for display of the distance to target bar and of the distance scale**


**8.2.2.2** **Distance to target digital**


8.2.2.2.1 This DMI object shows the remaining distance to target digital.


8.2.2.2.2 The distance to target digital shall be displayed in area A2 (see Figure 51).



































































































**Figure 51 – Area for distance to target digital**


8.2.2.2.3 Figure 50 gives an example of the distance to target digital.


Version 4.0.0 PAGE 73 OF 317


**ERA ERTMS unit**

**ETCS Driver Machine Interface**


8.2.2.2.4 The distance to target digital shall be able to show up to 5 digits. These numbers shall be
right aligned with an indent of 10 cells.


8.2.2.2.5 This digital representation shall be vertically centred in A2.


8.2.2.2.6 It shall show a number in grey to the nearest unit of 10 (rounding).


8.2.2.2.7 The distance to target digital shall be shown in A2 as specified in Table 14.






















|Mode|Supervision Status|Col3|Distance to target digital|
|---|---|---|---|
|FS / AD /<br>SM / OS /<br>SR*<br> <br> <br>|CSM|AllS|no|
|FS / AD /<br>SM / OS /<br>SR*<br> <br> <br>|CSM (with<br>target<br>information)**|AllS|yes|
|FS / AD /<br>SM / OS /<br>SR*<br> <br> <br>|TSM|AllS|yes|
|FS / AD /<br>SM / OS /<br>SR*<br> <br> <br>|RSM (not<br>applicable for<br>SR)|AllS|yes|
|RV|-|AllS|yes|
|SB / SH /<br>UN / PT /<br>TR / NL /<br>LS|-|AllS|no|




               - For OS/SR, the distance to target digital is shown if driver has requested to display
it (toggle on) (see chapter 8.2.2.4 for the toggling function)


** “With target information” only when requested by National Value


**Table 14 – Conditions for display of the distance to target digital**


**8.2.2.3** **Emergency/Service Brake Intervention**


8.2.2.3.1 This DMI object shows that ERTMS/ETCS is commanding the brakes.


8.2.2.3.2 The emergency/service brake intervention shall be displayed in area C9 (Figure 52).











































































































**Figure 52 – Area for brake intervention symbol**


8.2.2.3.3 The symbol ST01, see chapter 13, shall be used.


Version 4.0.0 PAGE 74 OF 317


**ERA ERTMS unit**

**ETCS Driver Machine Interface**
















|Col1|Col2|Col3|150<br>100 200<br>88<br>50 300<br>0 400|Col5|Col6|Col7|Col8|4000<br>2000<br>1000<br>500<br>+ 0<br>5<br>+<br>0|Col10|Col11|Col12|Col13|Col14|Main|
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
|290|290|290|290|290|290|290|290|290|290|290|290|290|290|Over-<br>ride|
|290|290|290|290|290|290|290|290|290|290|290|290|290|290|Data<br>view|
|290|290|290|290|290|290|290|290|290|290|290|290|290|290|Spec|
|290|290|290|290|290|290|290|290|290|290|290|290|290|290||
||||||||||||||||
|**2**|**2**|**2**|||||||||||||
||||||||||||||||
||||||||||||||||
||||||||||||||||
|||||||||||||17:33:25|17:33:25|17:33:25|
||||||||||||||||






|Col1|Col2|Col3|150<br>100 200<br>88<br>50 300<br>0 400|Col5|Col6|Col7|Col8|Col9|Col10|Col11|4000<br>2000<br>1000<br>500<br>+ 0<br>5<br>+<br>0|Col13|Col14|Col15|Col16|Col17|Col18|Col19|Col20|Col21|
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
||||**88**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**88**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**88**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**88**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**88**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**88**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**88**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**88**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>0|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>0|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>0|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>0|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>0|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>0|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>0|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>0|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>0||
|290|290|290|290|290|290|290|290|290|290|290|290|290|290|290|290|290|290|290|290|290|
|290|290|290|290|290|290|290|290|290|290|290|290|290|290|290|290|290|290|290|290||
|290|290|290|290|290|290|290|290|290|290|290|290|290|290|290|290|290|290|290|290||
|290|290|290|290|290|290|290|290|290|290|290|290|290|290|290|290|290|290|290|290||
|290|290|290|||||||||||||||||||
||||||||||||||||||||||
|**2**|**2**|**2**|||||||||||||||||||
||||||||||||||||||||||
||||||||||||||||||||||
||||||||||||||||||||||
||||||||||||||||||||||
||||||||||||||||||||||
||||||||||||||||||17:33:25|17:33:25|17:33:25|17:33:25|
|Main|Main|Main|Over-<br>ride|Data<br>view|Data<br>view|Spec|Spec||||||||||||||



**Figure 53 – Brake intervention**


8.2.2.3.4 If a driver acknowledgement is required for releasing a brake intervention (see document

[2]), the requirements specified in 5.4 shall apply for the symbol ST01 as soon as, if any,
the other conditions for the brake release are met (e.g. being at standstill).


8.2.2.3.4.1 Note: If a request for acknowledgement of an ERTMS/ETCS level, of a mode or of a
trackside text message leads to the brake intervention, the release will be done
respectively when the ERTMS/ETCS level, the mode or the trackside text message is
acknowledged.


Version 4.0.0 PAGE 75 OF 317


**ERA ERTMS unit**

**ETCS Driver Machine Interface**


8.2.2.3.5 When using the touch screen technology, the sensitive area of C9 shall be extended to
the C8 and E1 areas. The frame shall only surround the C9 area.


8.2.2.3.6 When the brake intervention is released without any driver’s acknowledgement (on ST01
or on any other DMI object), sound Sinfo shall be executed.


8.2.2.3.6.1 Note: when a driver’s acknowledgement is required leading to the brake release, Sinfo
is already played (see chapter 5.4) to draw the driver’s attention to this
acknowledgement.


**8.2.2.4** **Toggling function for speed information**


8.2.2.4.1 These DMI objects allow the driver to toggle on and off some speed and distance
monitoring information displayed in areas A and B and the planning information displayed
in D. The toggling function is located respectively in A/B (touch screen technology) and
F7 (soft key technology) (see Figure 54).

































































**Figure 54 – Areas for toggling function of speed/distance information**


8.2.2.4.2 When using touch screen technology: If the onboard is in one of the modes identified in
the Table 15, the areas A and B shall become sensitive to allow the driver to toggle on
and off the display of all concerned objects (see Table 15) for that mode.


8.2.2.4.3 When using soft key technology: If the onboard is in one of the modes identified in the
Table 15, F7 shall be an enabled up-type button showing the symbol DR01 to allow the
driver to toggle on and off the display of all concerned objects (see Table 15) for that
mode.


8.2.2.4.4 In all other modes (not mentioned in Table 15), the toggling function shall be inactive. For
the touch screen technology, the A/B areas shall not be sensitive and for the soft key
technology, no button shall exist in F7 for the toggling function.


Version 4.0.0 PAGE 76 OF 317


**ERA ERTMS unit**

**ETCS Driver Machine Interface**

|Mode|Concerned Object|
|---|---|
|OS<br> <br> <br> <br>|Basic Speed Hook(s)|
|OS<br> <br> <br> <br>|Release speed digital|
|OS<br> <br> <br> <br>|Distance to target (digital)|
|OS<br> <br> <br> <br>|Planning information|
|OS<br> <br> <br> <br>|Time to Indication|
|SR<br> <br>|Basic Speed Hook(s)|
|SR<br> <br>|Distance to target (digital)|
|SR<br> <br>|Time to Indication|
|SH|Basic Speed Hook(s)|



**Table 15 – Objects concerned by the toggling function**


8.2.2.4.5 When the onboard enters one of the modes identified in Table 15, the display of the
concerned objects shall be automatically toggled off.


**8.2.2.5** **Time to Indication (TTI)**


8.2.2.5.1 The Time to Indication (TTI) shall be displayed in area A1 (see Figure 54a).



























**Figure 54a – Area of the Time to Indication (TTI)**





Version 4.0.0 PAGE 77 OF 317


**ERA ERTMS unit**

**ETCS Driver Machine Interface**


8.2.2.5.2 Figure 54b gives an example of the TTI.
















|Col1|Col2|Col3|150<br>100 200<br>133<br>50 300<br>0 400|Col5|Col6|Col7|Col8|4000 +<br>2<br>2000<br>+<br>-<br>1000<br>60<br>22<br>500<br>-<br>+<br>5<br>+<br>0|Col10|Col11|Col12|Col13|Col14|Main|
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
|||||||||||||||Over-<br>ride|
|||||||||||||||Data<br>view|
|||||||||||||||Spec|
||||||||||||||||
||||||||||||||||
|**2**|**2**|**2**|||||||||||||
||||||||||||||||
||||||||||||||||
||||||||||||||||
||||||||||||||||
|||||||||||||17:33:25|17:33:25|17:33:25|
||||||||||||||||






|Col1|Col2|Col3|150<br>100 200<br>133<br>50 300<br>0 400|Col5|Col6|Col7|Col8|Col9|Col10|Col11|4000 +<br>2<br>2000<br>+<br>-<br>1000<br>60<br>22<br>500<br>-<br>+<br>5<br>+<br>0|Col13|Col14|Col15|Col16|Col17|Col18|Col19|Col20|Col21|
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
||||**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**<br>**133**|**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**<br>**133**|**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**<br>**133**|**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**<br>**133**|**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**<br>**133**|**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**<br>**133**|**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**<br>**133**|**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**<br>**133**|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>-<br>22<br>-<br>~~+~~<br>2<br>+<br>60|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>-<br>22<br>-<br>~~+~~<br>2<br>+<br>60|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>-<br>22<br>-<br>~~+~~<br>2<br>+<br>60|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>-<br>22<br>-<br>~~+~~<br>2<br>+<br>60|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>-<br>22<br>-<br>~~+~~<br>2<br>+<br>60|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>-<br>22<br>-<br>~~+~~<br>2<br>+<br>60|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>-<br>22<br>-<br>~~+~~<br>2<br>+<br>60|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>-<br>22<br>-<br>~~+~~<br>2<br>+<br>60|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>-<br>22<br>-<br>~~+~~<br>2<br>+<br>60||
||||||||||||||||||||||
||||||||||||||||||||||
||||||||||||||||||||||
||||||||||||||||||||||
||||||||||||||||||||||
||||||||||||||||||||||
|**2**|**2**|**2**|||||||||||||||||||
||||||||||||||||||||||
||||||||||||||||||||||
||||||||||||||||||||||
||||||||||||||||||||||
||||||||||||||||||||||
||||||||||||||||||17:33:25|17:33:25|17:33:25|17:33:25|
|Main|Main|Main|Over-<br>ride|Data<br>view|Data<br>view|Spec|Spec||||||||||||||



**Figure 54b –Time to Indication (TTI)**


8.2.2.5.3 The TTI shall be shown with a dark grey square of 50x50 cells and a white square whose
size shall depend on the remaining Time to Indication according to the following formula:

10         - _n_ 10         - ( _n_         - 1 )

If _TdispTTI_  10  _TTI_  _TdispTTI_  10 then

_Sizewhite_ = _n_  ( 5  5 _cells_ )

_square_


With n = 1..10


Version 4.0.0 PAGE 78 OF 317


**ERA ERTMS unit**

**ETCS Driver Machine Interface**


With TdispTTI = Time before the first Indication to display the TTI defined as a fixed value in
document [2]


8.2.2.5.4 Both squares shall be vertically and horizontally centred in A1 with the white square
overlaying the dark grey one.


8.2.2.5.5 Note: The TTI is particularly useful when the driver needs to anticipate more than in the
average situations, e.g. reduced adhesion due to poor weather conditions. In those cases,
the TTI helps the driver adapting the driving style in an effective way but without providing
a too accurate presentation.


8.2.2.5.6 The TTI shall be shown in A1 as specified in Table 15a.












|Mode|Supervision Status|Col3|Time to Indication|
|---|---|---|---|
|FS / AD /<br>SM / OS /<br>SR*<br> <br>|CSM|AllS|yes**|
|FS / AD /<br>SM / OS /<br>SR*<br> <br>|TSM|AllS|no|
|FS / AD /<br>SM / OS /<br>SR*<br> <br>|RSM (not<br>applicable for<br>SR)|AllS|no|
|SB / SH /<br>UN / PT /<br>TR / NL /<br>LS / RV|-|AllS|no|




               - For OS / SR, the TTI is shown if driver has requested to display it (toggle on) (see
chapter 8.2.2.4 for the toggling function)


** Only when requested by National Value and TTI < TdispTTI


**Table 15a – Conditions for display of the Time to Indication**


8.2.2.5.7 When the TTI is displayed, the sound Sinfo shall be played, unless in Automatic Driving
mode.


**8.2.3** **Supplementary Driving Information**


**8.2.3.1** **Mode information**


8.2.3.1.1 Mode information consists of three elements:

a) the ERTMS/ETCS current mode ;

b) a mode acknowledgement is requested;


c) the override symbol is displayed, to inform the driver that the override function is

active.


8.2.3.1.2 The current ERTMS/ETCS mode shall be displayed in B7 (see Figure 55) by using the
following symbols defined in chapter 13: symbols MO01, MO04, MO06, MO07, MO09,
MO11, MO12, MO13, MO14, MO16, MO18, MO21, MO23 or MO24.


8.2.3.1.2.1 Exception: If MO18 cannot be displayed on the total image display area, the SF mode
shall be indicated by any other means (e.g. blank screen, frozen screen, dedicated
lamp, sound,...).


8.2.3.1.2.2 Exception: The mode IS shall be indicated by any means (e.g. by the isolation device).


Version 4.0.0 PAGE 79 OF 317


**ERA ERTMS unit**

**ETCS Driver Machine Interface**


8.2.3.1.3 The mode acknowledgement shall be displayed in area C1 (see Figure 55) by using the
following symbols defined in chapter 13: symbols MO02, MO05, MO08, MO10, MO15,
MO17, MO20 or MO22.


8.2.3.1.4 When MO10 is displayed, the Ack-button shall be a delay-type button.


8.2.3.1.5 The override shall be displayed in area C7 (see Figure 55) by using the symbol MO03
defined in chapter 13.


8.2.3.1.6 If an ERTMS/ETCS level announcement without acknowledgement is already displayed
in area C1, it shall be substituted by the mode acknowledgement until the driver
acknowledges.










































|B2<br>A B1 B0<br>B8<br>B6 B3 B4 B5 B7<br>C8<br>C2 C3 C4 C1 C5 C6 C7<br>C9|Col2|Col3|Col4|Col5|Col6|
|---|---|---|---|---|---|
|A<br>B2<br>B6<br>B0<br>B3<br>B4<br>B5<br>B1<br>C8<br>C2<br>C3<br>C5<br>C6<br>C4<br>B7<br>C1<br>C7<br>C9<br>B8|B6|B6|B6|B4|B4|
|C8|C2|C3|C4|C1|C5|
|C9|C9|C9|C9|C9|C9|




|B2<br>A B1 B0<br>B8<br>B6 B3 B4 B5 B7<br>C8<br>C2 C3 C4 C1 C5 C6 C7<br>C9|Col2|Col3|Col4|Col5|Col6|Col7|
|---|---|---|---|---|---|---|
|A<br><br>B2<br>B6<br>B0<br>B3<br>B4<br>B5<br>B1<br>C8<br>C2<br>C3<br>C5<br>C6<br>C4<br>B7<br>C1<br>C7<br>C9<br>B8|B6|B6|B3|B4|B5|B7|
|A<br><br>B2<br>B6<br>B0<br>B3<br>B4<br>B5<br>B1<br>C8<br>C2<br>C3<br>C5<br>C6<br>C4<br>B7<br>C1<br>C7<br>C9<br>B8|C2|C3<br>C4|C3<br>C4|C1|C5<br>C6|C7|
|C9|C9|C9|C9|C9|C9|C9|





**Figure 55 – Areas for mode information (active and acknowledgment)**


8.2.3.1.7 Figure 56 shows an example of an active mode symbol in B7 and of the override symbol
in C7.





|Col1|150<br>100 200<br>36<br>50 300<br>0 400|Col3|Col4|Col5|Col6|Col7|Col8|Col9|Col10|Col11|Col12|Col13|Main|
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
||||||||||||||Over-<br>ride|
||||||||||||||Data<br>view|
||||||||||||||Spec|
|||||||||||||||
|||||||||||||||
|**1**||||||||||||||
|||||||||||||||
|||||||||||||||
|||||||||||||||
||||||||||||17:33:25|17:33:25|17:33:25|
|||||||||||||||


Version 4.0.0 PAGE 80 OF 317




**ERA ERTMS unit**

**ETCS Driver Machine Interface**






|Col1|150<br>100 200<br>36<br>50 300<br>0 400|Col3|Col4|Col5|Col6|Col7|Col8|Col9|Col10|Col11|Col12|Col13|Col14|Col15|Col16|Col17|Col18|Col19|
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
||**36**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**36**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**36**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**36**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**36**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**36**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**36**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**36**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|||||||||||
||**36**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**36**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**36**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**36**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**36**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**36**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**36**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**36**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|||||||||||
||**36**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**36**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**36**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**36**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**36**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**36**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**36**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**36**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|||||||||||
||**36**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**36**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**36**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**36**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**36**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**36**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**36**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**36**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|||||||||||
||**36**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**36**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**36**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**36**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**36**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**36**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**36**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**36**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|||||||||||
|**1**|||||||||||||||||||
||||||||||||||||||||
||||||||||||||||||||
||||||||||||||||17:33:25|17:33:25|17:33:25|17:33:25|
|Main|Over-<br>ride|Data<br>view|Data<br>view|Spec|Spec||||||||||||||



**Figure 56 – Mode information**


8.2.3.1.8 For the symbols displayed in C1 showing a mode to be acknowledged (i.e. all symbols
except MO03), the requirements specified in 5.4 shall apply.


8.2.3.1.9 Symbol MO03 (active override) shall be shown as long as the override function is active
and has to be displayed (see[2]).


**8.2.3.2** **Level information**


8.2.3.2.1 Level information consists of three elements:

a) the current ERTMS/ETCS level ;

b) an ERTMS/ETCS level announcement with acknowledgement;


c) an ERTMS/ETCS level announcement.


8.2.3.2.2 When the current ERTMS/ETCS level is valid and equal to 0, NTC (except in the modes
SN and NL), 1 or 2, it shall be displayed in area C8 (see Figure 57).


8.2.3.2.3 If the current ERTMS/ETCS level is unknown or invalid, no DMI object shall be displayed
in area C8.


Version 4.0.0 PAGE 81 OF 317


**ERA ERTMS unit**

**ETCS Driver Machine Interface**













































































































**Figure 57 – Areas for level information**


8.2.3.2.4 The symbol LE01, LE03, LE04 shall be used (see chapter 13), depending on the current
ERTMS/ETCS level.


8.2.3.2.5 An ERTMS/ETCS level announcement and an ERTMS/ETCS level announcement with
acknowledgement shall be displayed in area C1 (see Figure 57).


8.2.3.2.6 No ERTMS/ETCS level announcement shall be displayed as long as a mode
acknowledgement is displayed in C1.


8.2.3.2.7 If no acknowledgement is required for the ERTMS/ETCS level announcement, the symbol
LE06, LE08, LE10 or LE12 (see chapter 13) shall be used, depending on the
ERTMS/ETCS level announcement.


8.2.3.2.8 If an acknowledgement is required for the ERTMS/ETCS level announcement, the symbol
LE07, LE09 (see chapter 13) shall be used, depending on the next ERTMS/ETCS level
announcement. For these symbols, the requirements specified in 5.4 shall apply. As long
as the train has not yet reached the trackside location from where the acknowledgement
is required or as soon as the ERTMS/ETCS level announcement is acknowledged, the
symbol LE06, LE08 (see chapter 13) shall replace respectively LE07, LE09.


8.2.3.2.9 For level NTC, the distinct abbreviation of the corresponding National System (its
definition is inherent to the National System and is outside the scope of this specification)
shall be displayed instead of the text “NTC” as shown in symbol LE02, LE08, LE09.


8.2.3.2.10 The space used for characters of the National System abbreviation shall not exceed an

area of 48 x 19 (w x h) cells in the C8 and shall comply with the minimum size of characters
as defined in 5.1.2.


Version 4.0.0 PAGE 82 OF 317


**ERA ERTMS unit**

**ETCS Driver Machine Interface**
















|Col1|Col2|Col3|150<br>100 200<br>133<br>50 300<br>0 400|Col5|Col6|Col7|Col8|4000<br>2000<br>- 100<br>1000<br>22<br>500<br>-<br>+<br>5<br>+<br>0|Col10|Col11|Col12|Col13|Col14|Main|
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
|||||||||||||||Over-<br>ride|
|||||||||||||||Data<br>view|
|||||||||||||||Spec|
||||||||||||||||
||||||||||||||||
|**2**|**2**|**2**||**0**|||||||||||
||||||||||||||||
||||||||||||||||
||||||||||||||||
|||||||||||||17:33:25|17:33:25|17:33:25|
||||||||||||||||






|Col1|Col2|Col3|150<br>100 200<br>133<br>50 300<br>0 400|Col5|Col6|Col7|Col8|Col9|Col10|Col11|4000<br>2000<br>- 100<br>1000<br>22<br>500<br>-<br>+<br>5<br>+<br>0|Col13|Col14|Col15|Col16|Col17|Col18|Col19|Col20|Col21|
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
||||**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**<br>**133**|**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**<br>**133**|**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**<br>**133**|**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**<br>**133**|**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**<br>**133**|**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**<br>**133**|**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**<br>**133**|**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**<br>**133**|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>-<br>22<br>-<br>100|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>-<br>22<br>-<br>100|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>-<br>22<br>-<br>100|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>-<br>22<br>-<br>100|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>-<br>22<br>-<br>100|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>-<br>22<br>-<br>100|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>-<br>22<br>-<br>100|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>-<br>22<br>-<br>100|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>-<br>22<br>-<br>100||
||||||||||||||||||||||
||||||||||||||||||||||
||||||||||||||||||||||
||||||||||||||||||||||
||||||||||||||||||||||
||||||||||||||||||||||
|**2**|**2**|**2**|||**0**|**0**|||||||||||||||
||||||||||||||||||||||
||||||||||||||||||||||
||||||||||||||||||||||
||||||||||||||||||||||
||||||||||||||||||||||
||||||||||||||||||17:33:25|17:33:25|17:33:25|17:33:25|
|Main|Main|Main|Over-<br>ride|Data<br>view|Data<br>view|Spec|Spec||||||||||||||



**Figure 58 – Level information**


**8.2.3.3** **Track Ahead Free information**


8.2.3.3.1 The track ahead free information shall be displayed in area D (see Figure 59).


Version 4.0.0 PAGE 83 OF 317


**ERA ERTMS unit**

**ETCS Driver Machine Interface**











































































































**Figure 59 – Area for track ahead free information**


8.2.3.3.2 The track ahead free information shall be displayed via a question box.


8.2.3.3.3 The height of the question box shall be 50 cells.


8.2.3.3.4 The width of the question box shall be 244 cells.


8.2.3.3.5 When using touch screen technology, the top left corner of the question box shall be
positioned at (0,50).


8.2.3.3.6 When using soft key technology, the top left corner of the question box shall be positioned
at (0,100).


8.2.3.3.7 The question box shall be divided into a question part and an answer part.


8.2.3.3.8 The width of the question part shall be 162 cells.


8.2.3.3.9 The question part shall be placed to the left of the answer part.


8.2.3.3.10 The symbol DR02 defined in chapter 13 shall be displayed centred in the question part.

The background colour of the question part shall be dark grey.


8.2.3.3.11 The answer part shall display the label ‘Yes’ in black. The background colour of the answer

part shall be medium grey.


8.2.3.3.12 When using touch screen technology, the answer part shall be an up-type enabled button.


8.2.3.3.13 When using soft key technology, H3 displaying the label ‘Yes’ shall be the soft key

associated to the answer part.


8.2.3.3.14 The question part and the ‘Yes’ button (i.e. the answer part) shall both have the same

borders as an input field applying 5.1.1.1.4.


8.2.3.3.15 Figure 60 shows an example of the track ahead free symbol in D.


Version 4.0.0 PAGE 84 OF 317


**ERA ERTMS unit**

**ETCS Driver Machine Interface**










|Col1|Col2|Col3|150<br>100 200<br>36<br>50 300<br>0 400|Col5|Col6|Col7|Col8|Yes|Col10|Col11|Col12|Col13|Col14|Main|
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
|||||||||||||||Over-<br>ride|
|||||||||||||||Data<br>view|
|||||||||||||||Spec|
||||||||||||||||
||||||||||||||||
|**2**|**2**|**2**|||||||||||||
||||||||||||||||
||||||||||||||||
||||||||||||||||
|||||||||||||17:33:25|17:33:25|17:33:25|
||||||||||||||||










|Col1|Col2|Col3|150<br>100 200<br>36<br>50 300<br>0 400|Col5|Col6|Col7|Col8|Col9|Col10|Col11|Yes|Col13|Col14|Col15|Col16|Col17|Col18|Col19|Col20|Col21|
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
||||**36**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**36**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**36**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**36**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**36**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**36**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**36**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**36**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|Yes|Yes|Yes|Yes|Yes|Yes|Yes|Yes|Yes||
||||||||||||||||||||||
|||||||||||||||||||||Yes|
||||||||||||||||||||||
||||||||||||||||||||||
||||||||||||||||||||||
||||||||||||||||||||||
|**2**|**2**|**2**|||||||||||||||||||
||||||||||||||||||||||
||||||||||||||||||||||
||||||||||||||||||||||
||||||||||||||||||||||
||||||||||||||||||||||
||||||||||||||||||17:33:25|17:33:25|17:33:25|17:33:25|
|Main|Main|Main|Over-<br>ride|Data<br>view|Data<br>view|Spec|Spec||||||||||||||



**Figure 60 – Track Ahead Free information**


**8.2.3.4** **Text messages**


8.2.3.4.1 This DMI object displays the plain/fixed text messages received from trackside, the
system status messages specified in chapter 15.


8.2.3.4.2 When using touch screen technology, the text messages shall use the areas E5 – E9 (see
Figure 61).


8.2.3.4.3 When using soft key technology, the text messages shall use the areas E5 – E8 and H5H6 (see Figure 61).


Version 4.0.0 PAGE 85 OF 317


**ERA ERTMS unit**

**ETCS Driver Machine Interface**











































































































**Figure 61 – Areas for text messages**


8.2.3.4.4 Figure 62 shows an example of the presentation of text messages.



















|Col1|Col2|Col3|150<br>100 200<br>36<br>50 300<br>0 400|Col5|Col6|Col7|Col8|4000 +<br>2<br>2000<br>+<br>-<br>1000<br>22<br>500<br>-<br>+<br>5<br>+<br>0|Col10|Col11|Col12|Col13|Col14|Col15|Col16|Main|
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
|||||||||||||||||Over-<br>ride|
|||||||||||||||||Data<br>view|
|||||||||||||+<br>-|+<br>-|+<br>-|+<br>-|Spec|
|||||||||||||5|5|5|5||
||||||||||||||||||
|**2**|**2**|**2**|||||||||||||||
||||||||||||||||||
||||Entering FS<br>17:33<br>17:22 No MA received at level<br>Unauthorised passing of<br>EOA / LOA<br>17:28<br>transition|Entering FS<br>17:33<br>17:22 No MA received at level<br>Unauthorised passing of<br>EOA / LOA<br>17:28<br>transition|Entering FS<br>17:33<br>17:22 No MA received at level<br>Unauthorised passing of<br>EOA / LOA<br>17:28<br>transition|Entering FS<br>17:33<br>17:22 No MA received at level<br>Unauthorised passing of<br>EOA / LOA<br>17:28<br>transition|||||||||||
||||||||||||||||||
||||||||||||||||||
|||||||||||||||17:33:25|17:33:25|17:33:25|
||||||||||||||||||


Version 4.0.0 PAGE 86 OF 317


**ERA ERTMS unit**

**ETCS Driver Machine Interface**






















|Col1|Col2|Col3|150<br>100 200<br>36<br>50 300<br>0 400|Col5|Col6|Col7|Col8|Col9|4000 +<br>2<br>2000<br>+<br>-<br>1000<br>22<br>500<br>-<br>+<br>5<br>+<br>0|Col11|Col12|Col13|Col14|Col15|Col16|Col17|Col18|
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
||||**36**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**36**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**36**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**36**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**36**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**36**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>-<br>22<br>-<br>+<br>2<br>+|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>-<br>22<br>-<br>+<br>2<br>+|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>-<br>22<br>-<br>+<br>2<br>+|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>-<br>22<br>-<br>+<br>2<br>+|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>-<br>22<br>-<br>+<br>2<br>+|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>-<br>22<br>-<br>+<br>2<br>+|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>-<br>22<br>-<br>+<br>2<br>+|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>-<br>22<br>-<br>+<br>2<br>+||
|||||||||||||||||||
|||||||||||||||||||
|||||||||||||||||||
|||||||||||||||||||
|||||||||||||||||||
|**2**|**2**|**2**|**2**|**2**|**2**|||||||||||||
|||||||||||||||||||
||||Entering FS<br>17:33<br>17:22 No MA received at level<br>Unauthorised passing of<br>EOA / LOA<br>17:28|Entering FS<br>17:33<br>17:22 No MA received at level<br>Unauthorised passing of<br>EOA / LOA<br>17:28|Entering FS<br>17:33<br>17:22 No MA received at level<br>Unauthorised passing of<br>EOA / LOA<br>17:28|Entering FS<br>17:33<br>17:22 No MA received at level<br>Unauthorised passing of<br>EOA / LOA<br>17:28||||||||||||
|||||||||||||||||||
|||||||||||||||||||
|||||||||||||||||||
||||||||||||||||17:33:25|17:33:25|17:33:25|
|Main|Main|Main|Over-<br>ride|Data<br>view|Spec|||||||||||||



**Figure 62 – Text messages**


8.2.3.4.5 Figure 63 shows an example of a text message to be acknowledged.



|Col1|150<br>100 200<br>36<br>50 300<br>0 400|Col3|Col4|Col5|Col6|Col7|Col8|Col9|Col10|Col11|Col12|Col13|Main|
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
||||||||||||||Over-<br>ride|
||||||||||||||Data<br>view|
||||||||||||||Spec|
|||||||||||||||
|||||||||||||||
|**1**||||||||||||||
|||||||||||||||
||Acknowledgement<br>17:33|Acknowledgement<br>17:33|Acknowledgement<br>17:33|Acknowledgement<br>17:33||||||||||
|||||||||||||||
||||||||||||17:33:25|17:33:25|17:33:25|
|||||||||||||||


Version 4.0.0 PAGE 87 OF 317






**ERA ERTMS unit**

**ETCS Driver Machine Interface**










|Col1|150<br>100 200<br>36<br>50 300<br>0 400|Col3|Col4|Col5|Col6|Col7|Col8|Col9|Col10|Col11|Col12|Col13|Col14|Col15|Col16|
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
||**36**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**36**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**36**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**36**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**36**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**36**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**||||||||||
|||||||||||||||||
|||||||||||||||||
|||||||||||||||||
|||||||||||||||||
|||||||||||||||||
|**1**|**1**|**1**|**1**|||||||||||||
|||||||||||||||||
||Acknowledgement<br>17:33|Acknowledgement<br>17:33|Acknowledgement<br>17:33|Acknowledgement<br>17:33||||||||||||
|||||||||||||||||
|||||||||||||||||
||||||||||||||17:33:25|17:33:25|17:33:25|
|Main|Over-<br>ride|Data<br>view|Spec|||||||||||||



**Figure 63 – Text message to be acknowledged**


8.2.3.4.6 The following applies to all text messages:

a) The text messages shall be presented in white colour.

b) The local time of appearance shall be attached to the first line of a displayed text

message. It shall be separated from the first character of the displayed text by an
indent of 10 cells. This local time shall be in the format ‘hh:mm’ with a 24 hours time
reference.

c) If a text message does not fit in one area, it shall continue inside the next area (i.e.

the text message will be composed of several lines). The next lines shall be aligned
with the first character of the displayed text (see Figure 62).


8.2.3.4.7 The following applies to text messages that do not have to be acknowledged:

a) The text messages shall be divided into two groups. The first group shall contain the

system status messages and the important plain/fixed text messages received from
trackside. The second group shall contain the auxiliary plain/fixed text messages
received from trackside.

b) The text messages of the first group shall be displayed above the text messages of

the second group.

c) The text messages of the first group shall be presented with characters in bold style.

The text messages of the second group shall be presented with characters in regular
style.

d) The text messages belonging to the same group shall be classified in a chronological

way; the newest text message being displayed on top of the group.

e) It shall be possible to scroll line by line through the list of text messages. The scrolling

function shall not be circular i.e. the first line of the first text message shall not scroll
to the last line of the last text message and vice-versa.


Version 4.0.0 PAGE 88 OF 317


**ERA ERTMS unit**

**ETCS Driver Machine Interface**


f) When using touch screen technology, to scroll through the list of text messages the

area E10 shall be dedicated to the [Up] button, the area E11 shall be dedicated to

[Down] button.

g) When using soft key technology, to scroll through the list of text messages the H5

shall be dedicated to the [Up] button and H6 shall be dedicated to the [Down] button.
The symbols NA13, NA15 and NA14, NA16 shall echo the [Up] and [Down] buttons
respectively in E10 and E11.

h) Sound Sinfo, see chapter 14, shall be used when a new text message of the first group

is displayed for the first time. No sound shall be used when a new text message of the
second group is displayed for the first time.


8.2.3.4.8 The following applies only to text messages to be acknowledged regardless of the group
they belong to:

a) A text message to be acknowledged shall be presented alone (see Figure 63) (the

other messages that do not have to be acknowledged are temporarily not shown) in
the E5-E9 (touch screen technology) or E5-E8 (soft key technology) area.

b) As long as an Ack is required, the requirements specified in 5.4 shall apply on the full

area formed by E5-E9 (touch screen technology) or E5-E8 (soft key technology); E10
and E11 shall show respectively the symbols NA15 and NA16.

c) After acknowledgement and if the acknowledgement does not lead to the end of

display, the corresponding text message shall be managed as a text message that do
not have to be acknowledged but without playing the sound Sinfo.


**8.2.3.5** **Orders and announcements of track conditions (excluding tunnel stopping areas)**


8.2.3.5.1 This DMI object displays orders and announcement of track conditions (excluding tunnel
stopping areas), e.g. lowering the pantograph.


8.2.3.5.2 The orders and announcements of track conditions (excluding tunnel stopping areas) shall
be displayed in area B3/4/5 (see Figure 64).


8.2.3.5.3 The placement of the objects is from left to right filling B3/4/5. When an area is already
displaying a symbol, the next area shall be used. When all areas are already displaying
symbols, any further objects to be displayed shall wait that B3, B4 or B5 is free.





































**Figure 64 – Areas for orders and announcement of track conditions (excluding tunnel stopping areas)**


Version 4.0.0 PAGE 89 OF 317


**ERA ERTMS unit**

**ETCS Driver Machine Interface**


8.2.3.5.4 The symbols TC19, TC21, shall be used to order “Close air conditioning intake
announcement”; symbol TC19 to indicate an automatic execution, symbol TC21 when the
driver is requested to act.


8.2.3.5.5 The symbol TC19 shall be used to indicate “Air conditioning intake closed”.


8.2.3.5.6 The symbols TC20, TC22 shall be used to order “Open air conditioning intake”; symbol
TC20 to indicate an automatic execution, symbol TC22 when the driver is requested to
act.


8.2.3.5.7 The symbols TC02, TC03 shall be used to order “Lower pantograph”; symbol TC02 to
indicate an automatic execution, symbol TC03 when the driver is requested to act.


8.2.3.5.8 The symbol TC01 shall be used to indicate “Pantograph lowered”.


8.2.3.5.9 The symbols TC04, TC05 shall be used to order “Raise pantograph”; symbol TC04 to
indicate an automatic execution, symbol TC05 when the driver is requested to act.


8.2.3.5.10 The symbols TC06, TC07 shall be used to order “Neutral section announcement”; symbol

TC06 to indicate an automatic execution, symbol TC07 when the driver is requested to
act.


8.2.3.5.11 The symbol TC06 shall be used to indicate “Neutral section”.


8.2.3.5.12 The symbols TC08, TC09 shall be used to order “End of Neutral section”; symbol TC08

to indicate an automatic execution, symbol TC09 when the driver is requested to act.


8.2.3.5.13 The symbols TC10, TC11 shall be used respectively to indicate “Non Stopping area” and

“Non Stopping area announcement”.


8.2.3.5.14 The symbol TC12 shall be used to indicate “Radio hole”.


8.2.3.5.15 The symbols TC13, TC14 shall be used to order “Inhibition of magnetic shoe brake

announcement”; symbol TC13 to indicate an automatic execution, symbol TC14 when the
driver is requested to act.


8.2.3.5.16 The symbol TC13 shall be used to indicate “Inhibition of magnetic shoe brake”.


8.2.3.5.17 The symbols TC15, TC16, shall be used to order “Inhibition of eddy current brake

announcement”; symbol TC15 to indicate an automatic execution, symbol TC16 when the
driver is requested to act.


8.2.3.5.18 The symbol TC15 shall be used to indicate “Inhibition of eddy current brake”.


8.2.3.5.19 The symbols TC17, TC18 shall be used to order “Inhibition of regenerative brake

announcement”; symbol TC17 to indicate an automatic execution, symbol TC18 when the
driver is requested to act.


8.2.3.5.20 The symbol TC17 shall be used to indicate “Inhibition of regenerative brake”.


8.2.3.5.21 The symbols TC23, TC24 shall be used to order a “change of traction system

announcement, the line is not fitted with any traction system”; symbol TC23 to indicate an
automatic execution, symbol TC24 when the driver is requested to act.


Version 4.0.0 PAGE 90 OF 317


**ERA ERTMS unit**

**ETCS Driver Machine Interface**


8.2.3.5.22 The symbol TC23 shall be used to indicate “New traction system, the line is not fitted with

any traction system”.


8.2.3.5.23 The symbols TC25, TC26 shall be used to order a “change of traction system

announcement, AC 25 kV 50 Hz”; symbol TC25 to indicate an automatic execution,
symbol TC26 when the driver is requested to act.


8.2.3.5.24 The symbol TC25 shall be used to indicate “New traction system, AC 25 kV 50 Hz”.


8.2.3.5.25 The symbols TC27, TC28 shall be used to order a “change of traction system

announcement, AC 15 kV 16.7 Hz”; symbol TC27 to indicate an automatic execution,
symbol TC28 when the driver is requested to act.


8.2.3.5.26 The symbol TC27 shall be used to indicate “New traction system, AC 15 kV 16.7 Hz”.


8.2.3.5.27 The symbols TC29, TC30 shall be used to order a “change of traction system

announcement, DC 3 kV”; symbol TC29 to indicate an automatic execution, symbol TC30
when the driver is requested to act.


8.2.3.5.28 The symbol TC29 shall be used to indicate “New traction system, DC 3 kV”.


8.2.3.5.29 The symbols TC31, TC32 shall be used to order a “change of traction system

announcement, DC 1.5 kV”; symbol TC31 to indicate an automatic execution, symbol
TC32 when the driver is requested to act.


8.2.3.5.30 The symbol TC31 shall be used to indicate “New traction system, DC 1.5 kV”.


8.2.3.5.31 The symbols TC33, TC34 shall be used to order a “change of traction system

announcement, DC 600/750 V”; symbol TC33 to indicate an automatic execution, symbol
TC34 when the driver is requested to act.


8.2.3.5.32 The symbol TC33 shall be used to indicate “New traction system, DC 600/750 V”.


8.2.3.5.33 The symbol TC35 shall be used to order “Sound horn”.


8.2.3.5.34 Figure 65 gives an example of the presentation of orders and announcements in area

B3/4/5.


Version 4.0.0 PAGE 91 OF 317


**ERA ERTMS unit**

**ETCS Driver Machine Interface**














|Col1|Col2|Col3|150<br>100 200<br>133<br>50 300<br>0 400|Col5|Col6|Col7|Col8|4000 +<br>2<br>2000<br>+<br>-<br>1000<br>22<br>500<br>-<br>+<br>5<br>+<br>0|Col10|Col11|Col12|Col13|Col14|Main|
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
|||||||||||||||Over-<br>ride|
|||||||||||||||Data<br>view|
|||||||||||||||Spec|
||||||||||||||||
||||||||||||||||
||||||||||||||||
|**2**|**2**|**2**|||||||||||||
||||||||||||||||
||||||||||||||||
||||||||||||||||
|||||||||||||17:33:25|17:33:25|17:33:25|
||||||||||||||||






|Col1|Col2|Col3|150<br>100 200<br>133<br>50 300<br>0 400|Col5|Col6|Col7|Col8|Col9|Col10|4000 +<br>2<br>2000<br>+<br>-<br>1000<br>22<br>500<br>-<br>+<br>5<br>+<br>0|Col12|Col13|Col14|Col15|Col16|Col17|Col18|Col19|Col20|
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
||||**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**<br>**133**|**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**<br>**133**|**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**<br>**133**|**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**<br>**133**|**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**<br>**133**|**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**<br>**133**|**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**<br>**133**|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>-<br>22<br>-<br>+<br>2<br>+|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>-<br>22<br>-<br>+<br>2<br>+|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>-<br>22<br>-<br>+<br>2<br>+|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>-<br>22<br>-<br>+<br>2<br>+|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>-<br>22<br>-<br>+<br>2<br>+|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>-<br>22<br>-<br>+<br>2<br>+|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>-<br>22<br>-<br>+<br>2<br>+|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>-<br>22<br>-<br>+<br>2<br>+|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>-<br>22<br>-<br>+<br>2<br>+||
|||||||||||||||||||||
|||||||||||||||||||||
|||||||||||||||||||||
|||||||||||||||||||||
|||||||||||||||||||||
|||||||||||||||||||||
|**2**|**2**|**2**||||||||||||||||||
|||||||||||||||||||||
|||||||||||||||||||||
|||||||||||||||||||||
|||||||||||||||||||||
|||||||||||||||||||||
|||||||||||||||||17:33:25|17:33:25|17:33:25|17:33:25|
|Main|Main|Main|Over-<br>ride|Data<br>view|Spec|Spec||||||||||||||



**Figure 65 – Orders and announcement of track conditions (excluding tunnel stopping areas)**


**8.2.3.6** **Tunnel stopping area track condition**


8.2.3.6.1 This DMI object shows the next “tunnel stopping area” track condition.


8.2.3.6.2 The tunnel stopping area shall be displayed in area C2/C3/C4 (see Figure 66).


Version 4.0.0 PAGE 92 OF 317


**ERA ERTMS unit**

**ETCS Driver Machine Interface**



































































































**Figure 66 – Area for the tunnel stopping area**













|Col1|Col2|150<br>100 200<br>133<br>50 300<br>0 400|Col4|Col5|Col6|Col7|4000 +<br>2<br>2000<br>+<br>-<br>1000<br>22<br>500<br>-<br>+<br>5<br>+<br>0|Col9|Col10|Col11|Col12|Col13|Col14|Col15|Main|
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
|||**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**<br>**133**|**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**<br>**133**|**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**<br>**133**|**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**<br>**133**|**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**<br>**133**|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>-<br>22<br>-<br>+<br>2<br>+|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>-<br>22<br>-<br>+<br>2<br>+|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>-<br>22<br>-<br>+<br>2<br>+|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>-<br>22<br>-<br>+<br>2<br>+|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>-<br>22<br>-<br>+<br>2<br>+|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>-<br>22<br>-<br>+<br>2<br>+|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>-<br>22<br>-<br>+<br>2<br>+|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>-<br>22<br>-<br>+<br>2<br>+|Over-<br>ride|
|||**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**<br>**133**|**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**<br>**133**|**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**<br>**133**|**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**<br>**133**|**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**<br>**133**|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>-<br>22<br>-<br>+<br>2<br>+|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>-<br>22<br>-<br>+<br>2<br>+|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>-<br>22<br>-<br>+<br>2<br>+|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>-<br>22<br>-<br>+<br>2<br>+|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>-<br>22<br>-<br>+<br>2<br>+|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>-<br>22<br>-<br>+<br>2<br>+|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>-<br>22<br>-<br>+<br>2<br>+|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>-<br>22<br>-<br>+<br>2<br>+|Data<br>view|
|||**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**<br>**133**|**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**<br>**133**|**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**<br>**133**|**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**<br>**133**|**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**<br>**133**|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>-<br>22<br>-<br>+<br>2<br>+|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>-<br>22<br>-<br>+<br>2<br>+|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>-<br>22<br>-<br>+<br>2<br>+|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>-<br>22<br>-<br>+<br>2<br>+|+<br>-|+<br>-|+<br>-|+<br>-|Spec|
|||**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**<br>**133**|**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**<br>**133**|**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**<br>**133**|**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**<br>**133**|**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**<br>**133**|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>-<br>22<br>-<br>+<br>2<br>+|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>-<br>22<br>-<br>+<br>2<br>+|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>-<br>22<br>-<br>+<br>2<br>+|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>-<br>22<br>-<br>+<br>2<br>+|5|5|5|5||
|**2**|**2**|2348||||||||||||||
|||||||||||||||||
|||||||||||||||||
|||||||||||||||||
||||||||||||||17:33:25|17:33:25|17:33:25|


Version 4.0.0 PAGE 93 OF 317


**ERA ERTMS unit**

**ETCS Driver Machine Interface**
















|2|Col2|150<br>100 200<br>133<br>50 300<br>0 400<br>2348|Col4|Col5|Col6|Col7|Col8|4000 +<br>2<br>2000<br>+<br>-<br>1000<br>22<br>500<br>-<br>+<br>5<br>+<br>0|Col10|Col11|Col12|Col13|Col14|Col15|Col16|Col17|
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
|**2**|**2**|2348<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**<br>**133**|2348<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**<br>**133**|2348<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**<br>**133**|2348<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**<br>**133**|2348<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**<br>**133**|2348<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**<br>**133**|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>-<br>22<br>-<br>+<br>2<br>+|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>-<br>22<br>-<br>+<br>2<br>+|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>-<br>22<br>-<br>+<br>2<br>+|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>-<br>22<br>-<br>+<br>2<br>+|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>-<br>22<br>-<br>+<br>2<br>+|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>-<br>22<br>-<br>+<br>2<br>+|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>-<br>22<br>-<br>+<br>2<br>+|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>-<br>22<br>-<br>+<br>2<br>+||
|**2**|**2**|2348<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**<br>**133**|2348<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**<br>**133**|2348<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**<br>**133**|2348<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**<br>**133**|2348<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**<br>**133**|2348<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**<br>**133**|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>-<br>22<br>-<br>+<br>2<br>+|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>-<br>22<br>-<br>+<br>2<br>+|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>-<br>22<br>-<br>+<br>2<br>+|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>-<br>22<br>-<br>+<br>2<br>+|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>-<br>22<br>-<br>+<br>2<br>+|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>-<br>22<br>-<br>+<br>2<br>+|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>-<br>22<br>-<br>+<br>2<br>+|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>-<br>22<br>-<br>+<br>2<br>+||
|**2**|**2**|2348<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**<br>**133**|2348<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**<br>**133**|2348<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**<br>**133**|2348<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**<br>**133**|2348<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**<br>**133**|2348<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**<br>**133**|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>-<br>22<br>-<br>+<br>2<br>+|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>-<br>22<br>-<br>+<br>2<br>+|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>-<br>22<br>-<br>+<br>2<br>+|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>-<br>22<br>-<br>+<br>2<br>+|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>-<br>22<br>-<br>+<br>2<br>+|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>-<br>22<br>-<br>+<br>2<br>+|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>-<br>22<br>-<br>+<br>2<br>+|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>-<br>22<br>-<br>+<br>2<br>+||
|**2**|**2**|2348<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**<br>**133**|2348<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**<br>**133**|2348<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**<br>**133**|2348<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**<br>**133**|2348<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**<br>**133**|2348<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**<br>**133**|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>-<br>22<br>-<br>+<br>2<br>+|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>-<br>22<br>-<br>+<br>2<br>+|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>-<br>22<br>-<br>+<br>2<br>+|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>-<br>22<br>-<br>+<br>2<br>+|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>-<br>22<br>-<br>+<br>2<br>+|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>-<br>22<br>-<br>+<br>2<br>+|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>-<br>22<br>-<br>+<br>2<br>+|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>-<br>22<br>-<br>+<br>2<br>+||
|**2**|**2**|2348<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**<br>**133**|2348<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**<br>**133**|2348<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**<br>**133**|2348<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**<br>**133**|2348<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**<br>**133**|2348<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**<br>**133**|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>-<br>22<br>-<br>+<br>2<br>+|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>-<br>22<br>-<br>+<br>2<br>+|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>-<br>22<br>-<br>+<br>2<br>+|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>-<br>22<br>-<br>+<br>2<br>+|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>-<br>22<br>-<br>+<br>2<br>+|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>-<br>22<br>-<br>+<br>2<br>+|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>-<br>22<br>-<br>+<br>2<br>+|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>-<br>22<br>-<br>+<br>2<br>+||
|**2**|**2**|2348<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**<br>**133**|2348<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**<br>**133**|2348<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**<br>**133**|||||||||||||
||||||||||||||||||
||||||||||||||||||
||||||||||||||||||
||||||||||||||||||
|||||||||||||||17:33:25|17:33:25|17:33:25|
|Main|Main|Over-<br>ride|Data<br>view|Spec|||**?**|**?**|||||||||



**Figure 67 – Tunnel stopping area**


8.2.3.6.3 The requirements 8.2.3.6.4 to 8.2.3.6.9 shall apply only if tunnel stopping areas are known
by the onboard. (for further details, see [2])


8.2.3.6.4 It shall be possible to toggle on and off the display of the tunnel stopping area by touching
the sensitive area of C2/C3/C4 (touch screen technology) or by using F6 (soft key
technology).


8.2.3.6.5 When using the touch screen technology, the symbol DR05 shall be shown in C2/C3/C4
if the tunnel stopping area is toggled off.


8.2.3.6.6 When using the soft key technology, the symbol DR05 shall be shown in F6.


8.2.3.6.7 When the tunnel stopping area is toggled on, the symbols TC36, TC37 shall be shown in
C2 to indicate respectively “Tunnel stopping area” and “Tunnel stopping area
announcement”.


8.2.3.6.8 As long as the symbol TC37 is displayed, the remaining distance to the tunnel stopping
area shall also be indicated in the C3/C4 area.


8.2.3.6.9 The remaining distance to the tunnel stopping area shall be able to show up to 5 digits
with a resolution of 1 m. These numbers shall be in grey, right aligned with an indent of
10 cells and vertically centred.


8.2.3.6.10 When using touch screen technology, when the condition specified in 8.2.3.6.3 is not

fulfilled, C2/C3/C4 shall not be sensitive and shall not display the symbol DR05.


8.2.3.6.11 When using soft key technology, when the condition specified in 8.2.3.6.3 is not fulfilled,

no button shall exist in the F6 area.


**8.2.3.7** **Adhesion Factor Indication**


Version 4.0.0 PAGE 94 OF 317


**ERA ERTMS unit**

**ETCS Driver Machine Interface**


8.2.3.7.1 This DMI object shows that the adhesion factor is set to “slippery rail”.


8.2.3.7.2 The adhesion factor “slippery rail” shall be displayed in area A4 (Figure 68).





































































































**Figure 68 – Area for adhesion factor**


8.2.3.7.3 The symbol ST02, see Figure 69, shall be used.


Version 4.0.0 PAGE 95 OF 317


**ERA ERTMS unit**

**ETCS Driver Machine Interface**














|Col1|Col2|150<br>100 200<br>133<br>50 300<br>0 400|Col4|4000 +<br>2<br>2000<br>+<br>-<br>1000<br>22<br>500<br>-<br>+<br>5<br>+<br>0|Col6|Col7|Col8|Main|
|---|---|---|---|---|---|---|---|---|
|||**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**<br>**133**|**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**<br>**133**|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>-<br>22<br>-<br>~~+~~<br>2<br>+|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>-<br>22<br>-<br>~~+~~<br>2<br>+|2|2|2|
|||||||||Over-<br>ride|
|||||||-<br>+|-<br>+|-<br>+|
|||||||22|22|Data<br>view|
|||||||||Spec|
|||||||-|-|-|
|||||||+|+|+|
|||||||5|5||
||||||||||
|**2**|**2**||||||||
||||||||||
||||||||||
||||||||||
||||||||17:33:25|17:33:25|
||||||||||






|Col1|Col2|150<br>100 200<br>133<br>50 300<br>0 400|Col4|Col5|Col6|Col7|Col8|4000 +<br>2<br>2000<br>+<br>-<br>1000<br>22<br>500<br>-<br>+<br>5<br>+<br>0|Col10|Col11|Col12|Col13|Col14|Col15|
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
|||**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**<br>**133**|**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**<br>**133**|**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**<br>**133**|**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**<br>**133**|**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**<br>**133**|**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**<br>**133**|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>-<br>22<br>-<br>+<br>2<br>+|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>-<br>22<br>-<br>+<br>2<br>+|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>-<br>22<br>-<br>+<br>2<br>+|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>-<br>22<br>-<br>+<br>2<br>+|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>-<br>22<br>-<br>+<br>2<br>+|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>-<br>22<br>-<br>+<br>2<br>+||
||||||||||||||||
||||||||||||||||
||||||||||||||||
||||||||||||||||
||||||||||||||||
|**2**|**2**||||||||||||||
||||||||||||||||
||||||||||||||||
||||||||||||||||
||||||||||||||||
|||||||||||||17:33:25|17:33:25|17:33:25|
|Main|Main|Over-<br>ride|Data<br>view|Spec|||||||||||



**Figure 69 – Adhesion Factor “slippery rail”**


**8.2.3.8** **Level Crossing “not protected” Indication**


8.2.3.8.1 This DMI object shows that a level crossing is in the status “not protected”.


8.2.3.8.2 The level crossing “not protected” shall be displayed in area B3/4/5 (Figure 70).


8.2.3.8.3 The placement of the objects is from left to right filling B3/4/5. When an area is already
displaying a symbol, the next area shall be used. When all areas are already displaying
symbols, any further objects to be displayed shall wait that B3, B4 or B5 is free.


Version 4.0.0 PAGE 96 OF 317


**ERA ERTMS unit**

**ETCS Driver Machine Interface**





























**Figure 70 – Area for Level Crossing “not protected”**





8.2.3.8.4 The symbol LX01, see Figure 71, shall be used to indicate level crossing “not protected”.


Version 4.0.0 PAGE 97 OF 317


**ERA ERTMS unit**

**ETCS Driver Machine Interface**
















|Col1|Col2|Col3|150<br>100 200<br>133<br>50 300<br>0 400|Col5|Col6|Col7|Col8|4000<br>2000<br>- 0<br>1000<br>22<br>500<br>-<br>+<br>5<br>+<br>0|Col10|Col11|Col12|Col13|Col14|Main|
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
|1340|1340|1340|1340|1340|1340|1340|1340|1340|1340|1340|1340|1340|1340|Over-<br>ride|
|1340|1340|1340|1340|1340|1340|1340|1340|1340|1340|1340|1340|1340|1340|Data<br>view|
|1340|1340|1340|1340|1340|1340|1340|1340|1340|1340|1340|1340|1340|1340|Spec|
|1340|1340|1340|1340|1340|1340|1340|1340|1340|1340|1340|1340|1340|1340||
||||||||||||||||
|**2**|**2**|**2**|||||||||||||
||||||||||||||||
||||||||||||||||
||||||||||||||||
|||||||||||||17:33:25|17:33:25|17:33:25|
||||||||||||||||






|Col1|Col2|Col3|150<br>100 200<br>133<br>50 300<br>0 400|Col5|Col6|Col7|Col8|Col9|Col10|Col11|4000<br>2000<br>- 0<br>1000<br>22<br>500<br>-<br>+<br>5<br>+<br>0|Col13|Col14|Col15|Col16|Col17|Col18|Col19|Col20|Col21|
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
||||**133**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**133**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**133**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**133**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**133**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**133**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**133**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**133**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|0<br>4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>-<br>22<br>-|0<br>4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>-<br>22<br>-|0<br>4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>-<br>22<br>-|0<br>4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>-<br>22<br>-|0<br>4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>-<br>22<br>-|0<br>4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>-<br>22<br>-|0<br>4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>-<br>22<br>-|0<br>4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>-<br>22<br>-|0<br>4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>-<br>22<br>-||
|1340|1340|1340|1340|1340|1340|1340|1340|1340|1340|1340|1340|1340|1340|1340|1340|1340|1340|1340|1340|1340|
|1340|1340|1340|1340|1340|1340|1340|1340|1340|1340|1340|1340|1340|1340|1340|1340|1340|1340|1340|1340||
|1340|1340|1340|1340|1340|1340|1340|1340|1340|1340|1340|1340|1340|1340|1340|1340|1340|1340|1340|1340||
|1340|1340|1340|1340|1340|1340|1340|1340|1340|1340|1340|1340|1340|1340|1340|1340|1340|1340|1340|1340||
|1340|1340|1340|||||||||||||||||||
||||||||||||||||||||||
|**2**|**2**|**2**|||||||||||||||||||
||||||||||||||||||||||
||||||||||||||||||||||
||||||||||||||||||||||
||||||||||||||||||||||
||||||||||||||||||||||
||||||||||||||||||17:33:25|17:33:25|17:33:25|17:33:25|
|Main|Main|Main|Over-<br>ride|Data<br>view|Data<br>view|Spec|Spec||||||||||||||



**Figure 71 – Level Crossing “not protected”**


**8.2.3.9** **Set Speed Indication**


8.2.3.9.1 This DMI object shows the Set Speed value.


8.2.3.9.2 The Set Speed indication shall be displayed in area B0 (see Figure 71b).


Version 4.0.0 PAGE 98 OF 317


**ERA ERTMS unit**

**ETCS Driver Machine Interface**



































































































**Figure 71b – Area for the set speed**


8.2.3.9.3 The object to indicate the Set Speed shall be a white circle with a diameter of 10 cells.


8.2.3.9.4 The centre of the Set Speed object shall correspond to the Set Speed value and shall be
located on a circle with a radius of 111 cells having the same centre as area B0.


8.2.3.9.5 The Set Speed object shall cover the speed dial.


8.2.3.9.6 Figure 71c shows the Set Speed object.


Version 4.0.0 PAGE 99 OF 317


**ERA ERTMS unit**

**ETCS Driver Machine Interface**














|Col1|Col2|Col3|150<br>100 200<br>133<br>50 300<br>0 400|Col5|Col6|Col7|Col8|4000 +<br>2<br>2000<br>+<br>-<br>1000<br>22<br>500<br>-<br>+<br>5<br>+<br>0|Col10|Col11|Col12|Col13|Col14|Main|
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
|||||||||||||||Over-<br>ride|
|||||||||||||||Data<br>view|
|||||||||||||||Spec|
||||||||||||||||
||||||||||||||||
|**2**|**2**|**2**|||||||||||||
||||||||||||||||
||||||||||||||||
||||||||||||||||
|||||||||||||17:33:25|17:33:25|17:33:25|
||||||||||||||||






|Col1|Col2|Col3|150<br>100 200<br>133<br>50 300<br>0 400|Col5|Col6|Col7|Col8|Col9|Col10|Col11|4000 +<br>2<br>2000<br>+<br>-<br>1000<br>22<br>500<br>-<br>+<br>5<br>+<br>0|Col13|Col14|Col15|Col16|Col17|Col18|Col19|Col20|Col21|
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
||||**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**<br>**133**|**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**<br>**133**|**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**<br>**133**|**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**<br>**133**|**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**<br>**133**|**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**<br>**133**|**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**<br>**133**|**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**<br>**133**|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>-<br>22<br>-<br>+<br>2<br>+|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>-<br>22<br>-<br>+<br>2<br>+|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>-<br>22<br>-<br>+<br>2<br>+|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>-<br>22<br>-<br>+<br>2<br>+|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>-<br>22<br>-<br>+<br>2<br>+|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>-<br>22<br>-<br>+<br>2<br>+|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>-<br>22<br>-<br>+<br>2<br>+|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>-<br>22<br>-<br>+<br>2<br>+|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>-<br>22<br>-<br>+<br>2<br>+||
||||||||||||||||||||||
||||||||||||||||||||||
||||||||||||||||||||||
||||||||||||||||||||||
||||||||||||||||||||||
||||||||||||||||||||||
|**2**|**2**|**2**|||||||||||||||||||
||||||||||||||||||||||
||||||||||||||||||||||
||||||||||||||||||||||
||||||||||||||||||||||
||||||||||||||||||||||
||||||||||||||||||17:33:25|17:33:25|17:33:25|17:33:25|
|Main|Main|Main|Over-<br>ride|Data<br>view|Data<br>view|Spec|Spec||||||||||||||



**Figure 71c – Set Speed at 135km/h**


**8.2.3.10** **Supervised Manoeuvre authorised direction**


8.2.3.10.1 The Supervised Manoeuvre authorised direction shall be displayed in area B8 (see Figure

71d).


Version 4.0.0 PAGE 100 OF 317


**ERA ERTMS unit**

**ETCS Driver Machine Interface**





































**Figure 71d – Area for Supervised Manoeuvre authorised direction**





8.2.3.10.2 The Supervised Manoeuvre authorised direction shall be displayed by using one of the

following symbols defined in chapter 13: SM01, SM02.


8.2.3.10.3 Figure 71e shows an example of the authorised direction symbol in B8.















|Col1|Col2|Col3|150<br>100 200<br>36<br>50 300<br>0 400|Col5|Col6|Col7|Col8|4000<br>2000<br>1000<br>500<br>+ 0<br>5<br>+<br>0|Col10|Col11|Col12|Col13|Col14|Col15|Col16|Main|
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
|290|290|290|290|290|290|290|290|290|290|290|290|290|290|290|290|Over-<br>ride|
|290|290|290|290|290|290|290|290|290|290|290|290|290|290|290|290|Data<br>view|
|290|290|290|290|290|290|290|290|290|290|290|290|290|290|290|290|Spec|
|290|290|290|290|290|290|290|290|290|290|290|290|5|5|5|5||
||||||||||||||||||
|**2**|**2**|**2**|||||||||||||||
||||||||||||||||||
||||||||||||||||||
||||||||||||||||||
||||||||||||||||||
|||||||||||||||17:33:25|17:33:25|17:33:25|
||||||||||||||||||


Version 4.0.0 PAGE 101 OF 317


**ERA ERTMS unit**

**ETCS Driver Machine Interface**


















|Col1|Col2|Col3|150<br>100 200<br>36<br>50 300<br>0 400|Col5|Col6|Col7|Col8|Col9|4000<br>2000<br>1000<br>500<br>+ 0<br>5<br>+<br>0|Col11|Col12|Col13|Col14|Col15|Col16|Col17|Col18|
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
||||**36**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**36**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**36**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**36**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**36**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**36**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>0|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>0|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>0|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>0|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>0|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>0|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>0|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>0||
|290|290|290|290|290|290|290|290|290|290|290|290|290|290|290|290|290|290|
|290|290|290|290|290|290|290|290|290|290|290|290|290|290|290|290|290||
|290|290|290|290|290|290|290|290|290|290|290|290|290|290|290|290|290||
|290|290|290|290|290|290|290|290|290|290|290|290|290|290|290|290|290||
|||||||||||||||||||
|**2**|**2**|**2**|**2**|**2**|**2**|||||||||||||
|||||||||||||||||||
|||||||||||||||||||
|||||||||||||||||||
|||||||||||||||||||
|||||||||||||||||||
||||||||||||||||17:33:25|17:33:25|17:33:25|
|Main|Main|Main|Over-<br>ride|Data<br>view|Spec|||||||||||||



**Figure 71e – Authorised direction information**


8.2.3.10.4 When the Supervised Manoeuvre authorised direction changes, the audible information

Sinfo shall be played.


**8.2.3.11** **Big Metal Mass reaction inhibition**


8.2.3.11.1 The Big Metal Mass reaction inhibition shall be displayed in area C6 (see Figure 71f).









































































































**Figure 71f – Area for Big Metal Mass reaction inhibition**


8.2.3.11.2 The Big Metal Mass reaction inhibition shall be displayed by using the symbol ST07

defined in chapter 13.


8.2.3.11.3 Figure 71g shows an example of the Big Metal Mass reaction inhibition symbol in C6.


Version 4.0.0 PAGE 102 OF 317


**ERA ERTMS unit**

**ETCS Driver Machine Interface**






|Col1|Col2|Col3|150<br>100 200<br>0<br>50 300<br>0 400|Col5|Col6|Col7|Col8|Col9|Col10|Col11|Col12|Col13|Col14|Main|
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
|||||||||||||||Over-<br>ride|
|||||||||||||||Data<br>view|
|||||||||||||||Spec|
||||||||||||||||
||||||||||||||||
|**2**|**2**|**2**|||||||||||||
|**2**|**2**|**2**|||||||||||||
|**2**|**2**|**2**|||||||||||||
||||||||||||||||
||||||||||||||||
||||||||||||||||
|||||||||||||17:33:25|17:33:25|17:33:25|
||||||||||||||||






|Col1|150<br>100 200<br>0<br>50 300<br>0 400|Col3|Col4|Col5|Col6|Col7|Col8|Col9|Col10|Col11|Col12|Col13|Col14|Col15|Col16|Col17|Col18|Col19|
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
||**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**<br>**0**|**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**<br>**0**|**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**<br>**0**|**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**<br>**0**|**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**<br>**0**|**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**<br>**0**|**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**<br>**0**|**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**<br>**0**|||||||||||
||||||||||||||||||||
||||||||||||||||||||
||||||||||||||||||||
||||||||||||||||||||
||||||||||||||||||||
||||||||||||||||||||
|**2**|||||||||||||||||||
|**2**|||||||||||||||||||
||||||||||||||||||||
||||||||||||||||||||
||||||||||||||||||||
||||||||||||||||||||
||||||||||||||||17:33:25|17:33:25|17:33:25|17:33:25|
|Main|Over-<br>ride|Data<br>view|Data<br>view|Spec|Spec||||||||||||||



**Figure 71g – Big Metal Mass reaction inhibition**


**8.3** **Planning Information**


**8.3.1** **General description**


8.3.1.1 The planning information shall be shown in area D (see Figure 72) if one of the following
conditions is met:

a) intentionally deleted

b) the current mode is FS, SM or AD,


Version 4.0.0 PAGE 103 OF 317


**ERA ERTMS unit**

**ETCS Driver Machine Interface**


c) the current mode is OS, the speed and distance monitoring information is toggled on

(see 8.2.2.4) and the track ahead free information (see 8.2.3.3) is neither displayed
nor needs to be displayed


8.3.1.1.1 Intentionally deleted.









































































**Figure 72 – Area for planning information**


8.3.1.2 Figure 73 gives an overview of the objects of the planning information


Zoom function



Distance scale


Orders and announcements

of track conditions


Gradient profile


Zoom function





Speed profile discontinuity
(target at speed zero)


Planning Area Speed Profile (PASP)


Speed profile discontinuity
related to the indication marker
(speed decrease)


Indication marker


Train position








|Col1|4000<br>2000<br>1000 0<br>-<br>500 22<br>-<br>80<br>+<br>0 5<br>+<br>0|Col3|Col4|
|---|---|---|---|
|||||
|||||
|||-<br>~~22~~<br>-<br>~~0~~<br>||
|||||
|||||
|||||
|||||
|||||



**Figure 73 – Main objects of the planning information**


8.3.1.3 The planning information shall have the following objects:

a) distance scale

b) orders and announcements of track conditions (excluding tunnel stopping areas)

c) gradient profile

d) speed profile discontinuity information

e) Planning Area Speed Profile (PASP)

f) indication marker

g) intentionally deleted


Version 4.0.0 PAGE 104 OF 317


**ERA ERTMS unit**

**ETCS Driver Machine Interface**


h) zoom function


8.3.1.4 When the planning information is not shown, the navigation buttons/sensitive areas
related to the zoom function shall not exist.


**8.3.2** **Layering principles**


8.3.2.1 The order of superimposing objects on top of the background from back to front is:

1) The PASP

2) The distance scale

3) The indication marker

4) The orders and annoucements, gradient profile, speed profile discontinuities

5) Intentionally deleted.


**8.3.3** **Distance scale**


8.3.3.1 This DMI object displays the distance scale of the planning information in D1-D7.


8.3.3.2 Depending on the distance range selected by the driver, the functions displayed in D2D8 shall use the corresponding mapping described here below..













































































































**Figure 74 – Area for the distance scale**


8.3.3.3 The distance scale between 0 (1 [st] distance scale line) and the 2 [nd] distance scale line shall
be linear (see Table 16 and Figure 73), then it shall be logarithmic from the 2 [nd] distance
scale line until the end of the scale.


8.3.3.4 There shall be 6 ranges available: from 0 to 1 000 m, from 0 to 2 000 m, from 0 to 4 000
m, from 0 to 8 000 m, from 0 to 16 000 and from 0 to 32 000 m. Depending on the selected
range, the distance scale shall display the numbers and distance scale lines as described

|in Table 16:|Col2|Col3|
|---|---|---|
|Range|Displayed Numbers|Displayed distance scale lines|
|0 – 1000|0, 125, 250, 500, 1000|0, 25, 50, 75, 100, 125, 250, 500, 1000|
|0 – 2000|0, 250, 500, 1000, 2000|0, 50, 100, 150, 200, 250, 500, 1000,<br>2000|



Version 4.0.0 PAGE 105 OF 317


**ERA ERTMS unit**

**ETCS Driver Machine Interface**

|0 – 4000|0, 500, 1000, 2000, 4000|0, 100, 200, 300, 400, 500, 1000, 2000,<br>4000|
|---|---|---|
|0 – 8000|0, 1000, 2000, 4000, 8000|0, 200, 400, 600, 800, 1000, 2000, 4000,<br>8000|
|0 – 16000|0, 2000, 4000, 8000, 16000|0, 400, 800, 1200, 1600, 2000, 4000,<br>8000, 16000|
|0 – 32000|0, 4000, 8000, 16000, 32000|0, 800, 1600, 2400, 3200, 4000, 8000,<br>16000, 32000|



**Table 16 – Ranges of Distance scale**


8.3.3.5 9 distance scale lines with a length of 200 cells shall be displayed crossing the areas D2
to D7 and shall be positioned within area D as specified in Table 17. From bottom to top:
the first, the sixth and the ninth distance scale lines shall have a 2 cells width, the others
shall have a 1 cell width.







|Distance scale<br>line|position of distance scale lines|
|---|---|
|1st|(40,283)|
|2nd|(40,250)|
|3rd|(40,206)|
|4th|(40,182)|
|5th|(40,164)|
|6th|(40,150)|
|7th|(40,107)|
|8th|(40,64)|
|9th|(40,21)|


**Table 17 –Distance scale lines for the planning information**


8.3.3.6 The scale numbers shall be medium grey and vertically centred on the distance scale
lines and aligned on the right of area D1. The 2 cell width distance scale lines shall be in
medium grey, the 1 cell width distance scale lines in dark grey.


8.3.3.6.1 Note: for the number 0, half of this number will be in D9.


**8.3.4** **Orders and announcements**


8.3.4.1 This DMI object shows an overview of the orders and announcements.


8.3.4.2 The orders and announcements overview shall be displayed in area D2/D3/D4 (see Figure
75) and within the movement authority and up to the first target at zero speed, if any.


Version 4.0.0 PAGE 106 OF 317


**ERA ERTMS unit**

**ETCS Driver Machine Interface**


8.3.4.3 The symbols PL17, PL19 shall be used to show the forthcoming orders “Close air
conditioning intake announcement”; symbol PL17 to indicate an automatic execution,
symbol PL19 when the driver is requested to act.


8.3.4.4 The symbols PL18, PL20 shall be used to show the forthcoming orders “Open air
conditioning intake”; symbol PL18 to indicate an automatic execution, symbol PL20 when
the driver is requested to act.


8.3.4.5 The symbols PL01, PL02 shall be used to show the forthcoming orders “Lower
pantograph”; symbol PL01 to indicate an automatic execution, symbol PL02 when the
driver is requested to act.


8.3.4.6 The symbols PL03, PL04 shall be used to show the forthcoming orders “Raise
pantograph”; symbol PL03 to indicate an automatic execution, symbol PL04 when the
driver is requested to act.


8.3.4.7 The symbols PL05, PL06 shall be used to show the forthcoming orders “Neutral section
announcement”; symbol PL05 to indicate an automatic execution, symbol PL06 when the
driver is requested to act.


8.3.4.8 The symbols PL07, PL08 shall be used to show the forthcoming orders “End of neutral
section”; symbol PL07 to indicate an automatic execution, symbol PL08 when the driver
is requested to act.


8.3.4.9 The symbol PL09 shall be used to show forthcoming “Non stopping area announcement”.


8.3.4.10 The symbol PL10 shall be used to indicate forthcoming “Radio hole”.


8.3.4.11 The symbols PL11, PL12 shall be used to show the forthcoming orders “Inhibition of
magnetic shoe brake announcement”; symbol PL11 to indicate an automatic execution,
symbol PL12 when the driver is requested to act.


8.3.4.12 The symbols PL13, PL14 shall be used to show the forthcoming orders “Inhibition of eddy
current brake announcement”; symbol PL13 to indicate an automatic execution, symbol
PL14 when the driver is requested to act.


8.3.4.13 The symbols PL15, PL16 shall be used to show the forthcoming orders “Inhibition of
regenerative brake announcement”; symbol PL15 to indicate an automatic execution,
symbol PL16 when the driver is requested to act.


8.3.4.14 The symbol PL24 shall be used to show the forthcoming order “Sound horn”.


8.3.4.15 The symbols PL25, PL26 shall be used to show the forthcoming orders “change of traction
system announcement, the line is not fitted with any traction system”; symbol PL25 to
indicate an automatic execution, symbol PL26 when the driver is requested to act.


8.3.4.16 The symbols PL27, PL28 shall be used to show the forthcoming orders “change of traction
system announcement, AC 25 kV 50 Hz”; symbol PL27 to indicate an automatic
execution, symbol PL28 when the driver is requested to act.


Version 4.0.0 PAGE 107 OF 317


**ERA ERTMS unit**

**ETCS Driver Machine Interface**


8.3.4.17 The symbols PL29, PL30 shall be used to show the forthcoming orders “change of traction
system announcement, AC 15 kV 16.7 Hz”; symbol PL29 to indicate an automatic
execution, symbol PL30 when the driver is requested to act.


8.3.4.18 The symbols PL31, PL32 shall be used to show the forthcoming orders “change of traction
system announcement, DC 3 kV”; symbol PL31 to indicate an automatic execution,
symbol PL32 when the driver is requested to act.


8.3.4.19 The symbols PL33, PL34 shall be used to show the forthcoming orders “change of traction
system announcement, DC 1.5 kV”; symbol PL33 to indicate an automatic execution,
symbol PL34 when the driver is requested to act.


8.3.4.20 The symbols PL35, PL36 shall be used to show the forthcoming orders “change of traction
system announcement, DC 600/750 V”; symbol PL35 to indicate an automatic execution,
symbol PL36 when the driver is requested to act.













































































































**Figure 75 – Area for the orders and announcements**


8.3.4.21 Figure 73 gives an example of orders and announcements of the planning information.


8.3.4.22 Along the distance scale, the bottom of the symbols shall be positioned at the distance
from the current train front position to the location where the corresponding symbols for
track conditions will start to be displayed in B3/4/5.


8.3.4.23 Symbols shall be distributed over the three columns D2/D3/D4 to avoid overlapping as
much as possible. Two adjacent symbols shall not be placed into the same column but in
different columns.


8.3.4.24 Symbols in the same column D2, D3 or D4 shall not be hidden by symbols at a longer
distance i.e. in case of overlapping symbols, the closest symbol shall be drawn on top of
the more distant symbol(s).


8.3.4.25 The rules 8.3.4.23 and 8.3.4.24 shall apply also taking into account the position of the
ATO stopping points symbols (see 8.5.3).


**8.3.5** **Gradient profile**


8.3.5.1 This DMI object shows an overview of the gradient profile.


Version 4.0.0 PAGE 108 OF 317


**ERA ERTMS unit**

**ETCS Driver Machine Interface**


8.3.5.2 The gradient profile shall be displayed in area D5 (see Figure 76) and within the movement
authority and up to the first target at zero speed, if any.











































































































**Figure 76 – Area for the gradient profile**


8.3.5.3 Figure 73 gives an example of the gradient profile of the planning information.


8.3.5.4 The gradient profile shall be shown as a set of rectangles with different gradients. The
rectangles shall have a width equal to the width of D5.


8.3.5.5 Along the distance scale, the bottom of a rectangle shall be positioned at the
corresponding distance of the start of the gradient element from the current train front
position. The length of the rectangle shall represent the length of the gradient element.


8.3.5.6 If the rectangle for the gradient element is long enough to show the gradient direction, a
sign shall be shown at the top and bottom of the rectangle: a ‘+’ for a uphill gradient, a ’-’
for a downhill gradient.


8.3.5.7 If the rectangle for the gradient element is long enough to show the number (in ‰) in
addition to the ‘+’ or ‘-‘ sign, this number shall be shown in the middle of the rectangle.


8.3.5.8 Downhill gradients shall be shown in dark grey with characters (sign and/or number) in
white. Uphill gradients and zero gradients shall be shown in grey with characters (sign
and/or number) in black.


8.3.5.9 The uphill gradient and zero gradient rectangles shall have a 1 cell line on top and left
side in white.


8.3.5.10 The downhill gradient rectangles shall have a 1 cell line on top and left side in grey.


8.3.5.11 All gradient rectangles shall have a 1 cell line on the bottom in black.


**8.3.6** **Speed profile discontinuity information**


8.3.6.1 This DMI object displays speed profile discontinuity information which is composed of
symbols that describe whether there is a speed increase or decrease and of numbers that
provide the speed value to be respected at the speed profile discontinuities.


Version 4.0.0 PAGE 109 OF 317


**ERA ERTMS unit**

**ETCS Driver Machine Interface**


8.3.6.2 Along the distance scale, speed profile discontinuity information shall be displayed in D6D7 areas and within the movement authority and up to the first target at zero speed, if
any.











































































































**Figure 77 – Area for the speed profile discontinuity information**


8.3.6.3 The speed profile discontinuity information shall follow all MRSP discontinuities (see
Figure 78 and Figure 80) and the EOA/LOA location.


8.3.6.4 The symbols PL21, PL22, PL23 shall be used respectively for a speed increase, for a
speed decrease and, if any, for the speed decrease to the target related to the indication
marker (see 8.3.8).


8.3.6.4.1 Note: When entering the target speed monitoring, no indication marker will be displayed
anymore, which means that any symbol PL23 will by definition be replaced with a symbol
PL22.


8.3.6.4.2 Exception: In Automatic Driving mode, the symbol PL37 shall be displayed instead of the
symbol PL23.


8.3.6.5 The bottom of the horizontal line of the symbols shall be located at the speed discontinuity
location. The left-half of the speed profile discontinuity symbols shall cover the right side
of area D6. The right-half of the symbols shall cover the left side of area D7.


8.3.6.6 The speed values shall be displayed with numbers in grey except for the target related to
the indication marker (if any) which shall be in yellow.


8.3.6.6.1 Exception: In Automatic Driving mode, the speed value for the target related to the
indication marker (if any) shall be displayed with numbers in white.


8.3.6.7 For speed increases, the bottom of the numbers shall be vertically aligned with the bottom
of the horizontal line of the symbols PL21 while for speed decreases, the top of the
numbers shall be vertically aligned with the bottom of the horizontal line of the symbols
PL22 or PL23.


8.3.6.8 The numbers shall be left aligned in D7 with an indent of 11 cells.


8.3.6.9 In case of overlapping symbols/speed values, the following rules shall apply:


Version 4.0.0 PAGE 110 OF 317


**ERA ERTMS unit**

**ETCS Driver Machine Interface**


a) PL23 (or PL37 in Automatic Driving mode) and its attached speed value shall be drawn

on top of PL22 and PL21 and their attached speed values,

b) PL22 and its attached speed value shall be drawn on top of PL21 and its attached

speed value.


8.3.6.10 Figure 78 gives an example of the speed profile discontinuity information of the planning
information.













**Figure 78 – Speed profile discontinuity information**


**8.3.7** **Planning Area Speed Profile (PASP)**


8.3.7.1 This DMI object displays the Planning Area Speed Profile (PASP) as a speed-distance
diagram.


8.3.7.1.1 Note: The PASP is based on the MRSP and on the EOA/LOA location.


8.3.7.2 The PASP shall be displayed in area D7 (see Figure 79) and within the movement
authority and up to the first target at zero speed, if any.


Version 4.0.0 PAGE 111 OF 317


**ERA ERTMS unit**

**ETCS Driver Machine Interface**















































































































**Figure 79 – Area for the planning area speed profile**


8.3.7.3 The PASP information shall be presented as a diagram. On the vertical axis, the locations
of the speed discontinuities shall be displayed according to the distance scale. On the
horizontal axis, the speed scale shall be divided in 4 identical quarters.


8.3.7.4 The maximum ceiling speed shown in D7 and covering the width of D7 shall represent the
ceiling permitted speed at the current train front position.


8.3.7.5 The PASP information shall only display up to 3 speed discontinuities more restrictive
than the ceiling permitted speed at the current train front position and with a speed value
greater than zero.


8.3.7.6 The fourth speed restriction shall be reserved for the first target at zero speed, if any.


8.3.7.7 The speed shall not be presented to scale, but with fixed ratios relative to the ceiling
permitted speed at the current train front position (1/1). Speed decreases shall be shown
as 3/4, 1/2 or 1/4 of the ceiling permitted speed at the current train position. Each time a
speed decrease is effective, the width of the diagram shall be shorten by quarter(s) of the
full width as follows (with regards to a percentage of the ceiling permitted speed at the
current train front position):

a) From 99% to 75%: 1/4

b) From 74% to 50%: 1/2

c) From 49% to 1%: 3/4


8.3.7.8 Example: if the ceiling permitted speed at the current train front position is 140 km/h and
the first speed reduction is 70 km/h, then the speed profile in D7 shows a reduction to 1/2
of the current maximum; if the next speed reduction is 40 km/h, then the speed profile in
D7 shows 1/4 of the current maximum.


8.3.7.9 If a speed increase is drawn using symbol PL21, no further speed decrease except, if any,
the speed decrease to the first target at zero speed shall be shown on the PASP in D7.


8.3.7.10 The background colour of the PASP in D7-D8 shall be ‘PASP dark’.


8.3.7.11 The PASP diagram colour shall be ‘PASP light’.


8.3.7.12 In Figure 80 two examples of the PASP for the driver are given.


Version 4.0.0 PAGE 112 OF 317


**ERA ERTMS unit**

**ETCS Driver Machine Interface**



















**Figure 80 – Relationship between MRSP and the PASP for the driver**


**8.3.8** **Indication Marker**


8.3.8.1 This DMI object displays in D7 the location of the first Indication (see Figure 81).


8.3.8.2 The indication marker shall be a horizontal line in yellow with a 2 cells width and a length
equal to the width of D7.


8.3.8.2.1 Exception: In Automatic Driving mode, the indication marker shall be in white.


8.3.8.3 When the first Indication location exists (see document [2], 3.13.10.3), the bottom of the
indication marker shall be at this location.









































































































**Figure 81 – Area for the indication marker**


Version 4.0.0 PAGE 113 OF 317


**ERA ERTMS unit**

**ETCS Driver Machine Interface**


8.3.8.4 Figure 78 and Figure 80 show examples of the presentation of the indication marker in
the planning information.


8.3.8.5 Intentionally deleted.


**Figure 82 – Intentionally deleted**


**8.3.9** **Intentionally deleted**


**Figure 83 – Intentionally deleted**


**Figure 84 – Intentionally deleted**


**8.3.10** **Zoom function**


8.3.10.1 These DMI objects allow the driver to change the distance scale of the planning
information (zoom function). The zoom function is located respectively in D9/D12 (touch
screen technology) and H2/H3/D9/D12 (soft key technology) (see Figure 85).





























































































**Figure 85 – Area for the zoom function of the planning information**


8.3.10.2 When using a touch screen technology, when the planning information is shown, a [Scale
Up] button shall be used in the D9 area to shorten the distance scale of the whole planning
information.


8.3.10.3 When using a touch screen technology, when the planning information is shown, a [Scale
Down] button shall be used in the D12 area to enlarge the distance scale of the whole
planning information.


8.3.10.4 When using a touch screen technology, the sensitive area of D9 shall be enlarged by 15
cells height above D9 giving a total size of the sensitive area of 40x30 (wxh).


8.3.10.5 When using a touch screen technology, the sensitive area of D12 shall be enlarged by 15
cells height below D12 giving a total size of the sensitive area of 40x30 (wxh).


8.3.10.6 When using soft key technology, when the planning information is shown, a [Scale Up]
button shall be used in the area H3 to shorten the distance scale of the whole planning


Version 4.0.0 PAGE 114 OF 317


**ERA ERTMS unit**

**ETCS Driver Machine Interface**


information. One of the symbols NA03, NA05 shall be displayed in D9 in order to echo
respectively the NA07 or NA09 of the H3 button.


8.3.10.7 When using soft key technology, when the planning informaton is shown, a [Scale Down]
button shall be used in the area H2 to enlarge the distance scale of the whole planning
information. One of the symbols NA04, NA06 shall be displayed in D12 in order to echo
respectively the NA08 or NA10 of the H2 button.


8.3.10.8 When a valid activation of the [Scale Up] button is done by the driver, the distance scale
shall change to the previous distance range shorter than the current one e.g. change from
0 – 8000 to 0 – 4000.


8.3.10.9 When a valid activation of the [Scale Down] button is done by the driver, the distance
scale shall change to the next distance range longer than the current one e.g. change
from 0 – 8000 to 0 – 16000.


**8.4** **Monitoring Information**
















































































|C8<br>C2 C3 C4C C1 C5 C6 C7<br>C9<br>E1 E5<br>E2 E6 E10<br>E7<br>E3 E8 E11<br>E4 E9|G1 G2 G 3 G4 G5 F7|
|---|---|
|C8<br>C9<br>E1<br>E2<br>E3<br>E4<br>C2<br>C3<br>C4<br>C1<br>C5<br>C6<br>C7<br>E10<br>E11<br>E9<br>E8<br>**E**7<br>E6<br>E5<br><br>C|G6<br>G7<br>G8<br>G9<br>G10<br>F8<br>F9<br>G13<br>G11<br>G12<br>G|



**Figure 86 – Areas for the monitoring information**


**8.4.1** **Safe radio connection indication**


8.4.1.1 This DMI object shows the status of the safe radio connection with regards to its indication
status (see document [2], 3.5.7).


8.4.1.2 The status of the safe radio connection with the relevant RBC/RIU shall be displayed in
area E1 (see Figure 87).


Version 4.0.0 PAGE 115 OF 317


**ERA ERTMS unit**

**ETCS Driver Machine Interface**















































































**Figure 87 – Area for the safe radio connection indication**


8.4.1.3 When the indication status for the safe radio connection is “Connection Up”, the symbol
ST03 shall be displayed in E1.


8.4.1.4 When the indication status for the safe radio connection is “No Connection”, no symbol
shall be displayed in E1.


8.4.1.5 When the indication status for the safe radio connection is “Connection Lost/Set-Up
failed”, the symbol ST04 shall be displayed in E1.


8.4.1.6 Figure 88 shows an example of the presentation of the safe radio connection indication in
E1.













|Col1|Col2|Col3|150<br>100 200<br>133<br>50 300<br>0 400|Col5|Col6|Col7|Col8|4000 +<br>2<br>2000<br>+<br>-<br>1000<br>22<br>500<br>-<br>+<br>5<br>+<br>0|Col10|Col11|Col12|Col13|Col14|Col15|Col16|Main|
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
|||||||||||||||||Over-<br>ride|
|||||||||||||22|22|22|22|Data<br>view|
|||||||||||||+<br>-|+<br>-|+<br>-|+<br>-|Spec|
|||||||||||||5|5|5|5||
||||||||||||||||||
|**2**|**2**|**2**|||||||||||||||
||||||||||||||||||
||||||||||||||||||
||||||||||||||||||
||||||||||||||||||
|||||||||||||||17:33:25|17:33:25|17:33:25|
||||||||||||||||||


Version 4.0.0 PAGE 116 OF 317


**ERA ERTMS unit**

**ETCS Driver Machine Interface**














|Col1|Col2|Col3|150<br>100 200<br>133<br>50 300<br>0 400|Col5|Col6|Col7|Col8|Col9|4000 +<br>2<br>2000<br>+<br>-<br>1000<br>22<br>500<br>-<br>+<br>5<br>+<br>0|Col11|Col12|Col13|Col14|Col15|Col16|Col17|Col18|
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
||||**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**<br>**133**|**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**<br>**133**|**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**<br>**133**|**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**<br>**133**|**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**<br>**133**|**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**<br>**133**|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>-<br>22<br>-<br>+<br>2<br>+|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>-<br>22<br>-<br>+<br>2<br>+|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>-<br>22<br>-<br>+<br>2<br>+|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>-<br>22<br>-<br>+<br>2<br>+|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>-<br>22<br>-<br>+<br>2<br>+|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>-<br>22<br>-<br>+<br>2<br>+|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>-<br>22<br>-<br>+<br>2<br>+|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>-<br>22<br>-<br>+<br>2<br>+||
|||||||||||||||||||
|||||||||||||||||||
|||||||||||||||||||
|||||||||||||||||||
|||||||||||||||||||
|**2**|**2**|**2**|**2**|**2**|**2**|||||||||||||
|||||||||||||||||||
|||||||||||||||||||
|||||||||||||||||||
|||||||||||||||||||
|||||||||||||||||||
||||||||||||||||17:33:25|17:33:25|17:33:25|
|Main|Main|Main|Over-<br>ride|Data<br>view|Spec|||||||||||||



**Figure 88 – Safe radio connection and local time**


**8.4.2** **Reversing permitted indication**


8.4.2.1 This DMI object shows that reversing is permitted.


8.4.2.2 When the train is at standstill inside a reversing area, the indication that reversing is
permitted shall be displayed in area C6 (see Figure 89) using the symbol ST06.







































































































**Figure 89 – Area for the reversing permitted indication**


8.4.2.3 Figure 90 shows an example of the presentation of the reversing is permitted in C6.


Version 4.0.0 PAGE 117 OF 317


**ERA ERTMS unit**

**ETCS Driver Machine Interface**














|Col1|Col2|Col3|150<br>100 200<br>0<br>50 300<br>0 400|Col5|Col6|Col7|Col8|4000 +<br>2<br>2000<br>+<br>-<br>1000<br>22<br>500<br>-<br>+<br>5<br>+<br>0|Col10|Col11|Col12|Col13|Col14|Main|
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
|||||||||||||||Over-<br>ride|
|||||||||||||||Data<br>view|
|||||||||||||||Spec|
||||||||||||||||
||||||||||||||||
|**2**|**2**|**2**|||||||||||||
||||||||||||||||
||||||||||||||||
||||||||||||||||
|||||||||||||17:33:25|17:33:25|17:33:25|
||||||||||||||||






|Col1|Col2|Col3|150<br>100 200<br>0<br>50 300<br>0 400|Col5|Col6|Col7|Col8|Col9|Col10|Col11|4000 +<br>2<br>2000<br>+<br>-<br>1000<br>22<br>500<br>-<br>+<br>5<br>+<br>0|Col13|Col14|Col15|Col16|Col17|Col18|Col19|Col20|Col21|
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
||||**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**<br>**0**|**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**<br>**0**|**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**<br>**0**|**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**<br>**0**|**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**<br>**0**|**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**<br>**0**|**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**<br>**0**|**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**<br>**0**|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>-<br>22<br>-<br>+<br>2<br>+|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>-<br>22<br>-<br>+<br>2<br>+|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>-<br>22<br>-<br>+<br>2<br>+|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>-<br>22<br>-<br>+<br>2<br>+|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>-<br>22<br>-<br>+<br>2<br>+|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>-<br>22<br>-<br>+<br>2<br>+|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>-<br>22<br>-<br>+<br>2<br>+|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>-<br>22<br>-<br>+<br>2<br>+|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>-<br>22<br>-<br>+<br>2<br>+||
||||||||||||||||||||||
||||||||||||||||||||||
||||||||||||||||||||||
||||||||||||||||||||||
||||||||||||||||||||||
||||||||||||||||||||||
|**2**|**2**|**2**|||||||||||||||||||
||||||||||||||||||||||
||||||||||||||||||||||
||||||||||||||||||||||
||||||||||||||||||||||
||||||||||||||||||||||
||||||||||||||||||17:33:25|17:33:25|17:33:25|17:33:25|
|Main|Main|Main|Over-<br>ride|Data<br>view|Data<br>view|Spec|Spec||||||||||||||



**Figure 90 – Reversing permitted**


**8.4.3** **Local time**


8.4.3.1 This DMI object shows the local time.


8.4.3.2 The local time shall be displayed in area G13 (see Figure 91).


Version 4.0.0 PAGE 118 OF 317


**ERA ERTMS unit**

**ETCS Driver Machine Interface**









































































































**Figure 91 – Area for the local time**


8.4.3.3 Figure 88 shows an example of the presentation of the local time in G13.


8.4.3.4 The local time shall be displayed in grey on a single line in the format ‘hh:mm:ss’ with a
24 hours time reference.


**8.4.4** **Geographical position**


8.4.4.1 This DMI object shows the geographical position of the train.


8.4.4.2 The geographical position shall be displayed in area G12 (see Figure 92).











































































































**Figure 92 – Area for the geographical position**


Version 4.0.0 PAGE 119 OF 317


**ERA ERTMS unit**

**ETCS Driver Machine Interface**












|Col1|Col2|Col3|150<br>100 200<br>133<br>50 300<br>0 400|Col5|Col6|Col7|Col8|4000 +<br>2<br>2000<br>+<br>-<br>1000<br>22<br>500<br>-<br>+<br>5<br>+<br>0|Col10|Col11|Col12|Col13|Col14|Main|
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
|||||||||||||||Over-<br>ride|
|||||||||||||||Data<br>view|
|||||||||||||||Spec|
||||||||||||||||
||||||||||||||||
|**2**|**2**|**2**|||||||||||||
||||||||||||||||
||||||||||||||||
||||||||||||||||
|||||||||||43 093|43 093|17:33:25|17:33:25|17:33:25|
||||||||||||||||






|Col1|Col2|Col3|150<br>100 200<br>133<br>50 300<br>0 400|Col5|Col6|Col7|Col8|Col9|Col10|Col11|4000 +<br>2<br>2000<br>+<br>-<br>1000<br>22<br>500<br>-<br>+<br>5<br>+<br>0|Col13|Col14|Col15|Col16|Col17|Col18|Col19|Col20|Col21|
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
||||**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**<br>**133**|**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**<br>**133**|**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**<br>**133**|**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**<br>**133**|**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**<br>**133**|**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**<br>**133**|**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**<br>**133**|**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**<br>**133**|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>-<br>22<br>-<br>+<br>2<br>+|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>-<br>22<br>-<br>+<br>2<br>+|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>-<br>22<br>-<br>+<br>2<br>+|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>-<br>22<br>-<br>+<br>2<br>+|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>-<br>22<br>-<br>+<br>2<br>+|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>-<br>22<br>-<br>+<br>2<br>+|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>-<br>22<br>-<br>+<br>2<br>+|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>-<br>22<br>-<br>+<br>2<br>+|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>-<br>22<br>-<br>+<br>2<br>+||
||||||||||||||||||||||
||||||||||||||||||||||
||||||||||||||||||||||
||||||||||||||||||||||
||||||||||||||||||||||
||||||||||||||||||||||
|**2**|**2**|**2**|||||||||||||||||||
||||||||||||||||||||||
||||||||||||||||||||||
||||||||||||||||||||||
||||||||||||||||||||||
||||||||||||||||||||||
||||||||||||||43 093|43 093|43 093|43 093|17:33:25|17:33:25|17:33:25|17:33:25|
|Main|Main|Main|Over-<br>ride|Data<br>view|Data<br>view|Spec|Spec||||||||||||||



**Figure 93 – Geographical position**


8.4.4.3 The requirements 8.4.4.4 to 8.4.4.9 shall apply only if the geographical position of the train
is known by the onboard. (for further details, see [2])


8.4.4.4 It shall be possible to toggle on and off the display of the geographical position by touching
the sensitive area of G12 (touch screen technology) or by using F8 (soft key technology).


8.4.4.5 As soon as the condition specified in 8.4.4.3 is fulfilled, the last status of the toggle on/off
shall be used for the display of the geographical position.


8.4.4.6 When using the touch screen technology, the symbol DR03 shall be shown in G12 if the
geographical position is toggled off.


Version 4.0.0 PAGE 120 OF 317


**ERA ERTMS unit**

**ETCS Driver Machine Interface**


8.4.4.7 When using the soft key technology, the symbol DR03 shall be shown in F8.


8.4.4.8 When the geographical position is toggled on, the full G12 area shall have a grey
background with the geographical position displayed in black and in the centre of the G12
area.


8.4.4.9 A space character shall be inserted between the kilometre and the metre parts of the
geographical position.


8.4.4.10 When using touch screen technology, when the condition specified in 8.4.4.3 is not
fulfilled, the G12 shall not be sensitive and shall not display the symbol DR03.


8.4.4.11 When using soft key technology, when the condition specified in 8.4.4.3 is not fulfilled, no
button shall exist in the F8 area.


**8.5** **Automatic Train Operation information**


**8.5.1** **General description**


8.5.1.1 The automatic train operation information shall be shown in the areas B0, B8, D2/D3/D4,
D7 and G1-G5 (see Figure 93a) if the ATO selector is set to “On”.



































































**Figure 93a – Areas for ATO information**



8.5.1.2 The ATO information shall be composed of the following objects:

a) ATO status

b) Stopping points

c) At stopping points:

Stopping accuracy

Dwell time

Door information

d) Outside stopping points:

Next stopping point name and estimated arrival time

Skip stopping point status

Target Advice Speed


Version 4.0.0 PAGE 121 OF 317


**ERA ERTMS unit**

**ETCS Driver Machine Interface**


Coasting advice

Next advice change marker


8.5.1.3 Figure 93b gives an example of ATO objects when the train is at a stopping point in
Automatic Driving mode.




|Col1|Col2|Col3|150<br>100 200<br>0<br>50 300<br>0 400|Col5|Col6|Col7|Col8|4000<br>2000<br>- 0<br>1000<br>22<br>500<br>-<br>+<br>5<br>+<br>0|Col10|Col11|Col12|Col13|Col14|Col15|Col16|Main<br>Over-<br>ride<br>Data<br>view<br>Spec|
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
||||||||||||||||||
|||||||||||||22|22|22|22|22|
||||||||||||||||||
|||||||||||||-|-|-|-|-|
|||||||||||||+|+|+|+|+|
|||||||||||||+|+|+|+||
|||||||||||||5|5|5|5|5|
|||||||||||||+|+|+|+|+|
||||||||||||||||||
|**2**|**2**|**2**||||||ATO|||1:09|1:09|||||
||||||||||||||||||
||||||||||||||||||
||||||||||||||||||
||||||||||||||||||
|||||||||||||||17:33:25|17:33:25|17:33:25|
||||||||||||||||||


























|Col1|Col2|Col3|150<br>100 200<br>0<br>50 300<br>0 400|Col5|Col6|Col7|Col8|Col9|Col10|Col11|4000<br>2000<br>- 0<br>1000<br>22<br>500<br>-<br>+<br>5<br>+<br>0|Col13|Col14|Col15|Col16|Col17|Col18|Col19|Col20|Col21|
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
||||**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**<br>**0**|**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**<br>**0**|**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**<br>**0**|**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**<br>**0**|**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**<br>**0**|**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**<br>**0**|**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**<br>**0**|**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**<br>**0**|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>-<br>22<br>-<br>0|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>-<br>22<br>-<br>0|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>-<br>22<br>-<br>0|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>-<br>22<br>-<br>0|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>-<br>22<br>-<br>0|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>-<br>22<br>-<br>0|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>-<br>22<br>-<br>0|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>-<br>22<br>-<br>0|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>-<br>22<br>-<br>0||
||||||||||||||||||||||
||||||||||||||||||||||
||||||||||||||||||||||
||||||||||||||||||||||
||||||||||||||||||||||
||||||||||||||||||||||
|**2**|**2**|**2**|||||||||ATO|||1:09|1:09||||||
||||||||||||||||||||||
||||||||||||||||||||||
||||||||||||||||||||||
||||||||||||||||||||||
||||||||||||||||||||||
||||||||||||||||||17:33:25|17:33:25|17:33:25|17:33:25|
|Main|Main|Main|Over-<br>ride|Data<br>view|Data<br>view|Spec|Spec||||||||||||||



**Figure 93b – ATO objects at a stopping point in AD mode**


8.5.1.4 Figure 93c gives an example of ATO objects when the train is outside stopping points in
Automatic Driving mode.


Version 4.0.0 PAGE 122 OF 317


**ERA ERTMS unit**

**ETCS Driver Machine Interface**






|Col1|Col2|Col3|150<br>100 200<br>133<br>50 300<br>0 400|Col5|Col6|Col7|Col8|4000 +<br>2<br>2000<br>+<br>-<br>1000<br>22<br>500<br>-<br>+<br>5<br>+<br>0<br>Welwyn North<br>ATO 17:36:48|Col10|Col11|Col12|Main|
|---|---|---|---|---|---|---|---|---|---|---|---|---|
|||||||||||||Over-<br>ride|
|||||||||||||Data<br>view|
|||||||||||||Spec|
||||||||||||||
||||||||||||||
|**2**|**2**|**2**||||||ATO|ATO|ATO|||
||||||||||||||
||||||||||||||
||||||||||||||
|||||||||||17:33:25|17:33:25|17:33:25|
||||||||||||||






















|Col1|Col2|Col3|150<br>100 200<br>133<br>50 300<br>0 400|Col5|Col6|Col7|Col8|Col9|Col10|Col11|4000 +<br>2<br>2000<br>+<br>-<br>1000<br>22<br>500<br>-<br>+<br>5<br>+<br>0|Col13|Col14|Col15|Col16|Col17|Col18|Col19|
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
||||**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**<br>**133**|**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**<br>**133**|**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**<br>**133**|**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**<br>**133**|**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**<br>**133**|**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**<br>**133**|**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**<br>**133**|**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**<br>**133**|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>-<br>22<br>-<br>+<br>2<br>+|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>-<br>22<br>-<br>+<br>2<br>+|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>-<br>22<br>-<br>+<br>2<br>+|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>-<br>22<br>-<br>+<br>2<br>+|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>-<br>22<br>-<br>+<br>2<br>+|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>-<br>22<br>-<br>+<br>2<br>+|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>-<br>22<br>-<br>+<br>2<br>+||
||||||||||||||||||||
||||||||||||||||||||
||||||||||||||||||||
||||||||||||||||||||
||||||||||||||||||||
||||||||||||||||||||
|**2**|**2**|**2**|||||||||ATO|Welwyn North<br>17:36:48|Welwyn North<br>17:36:48|Welwyn North<br>17:36:48|Welwyn North<br>17:36:48||||
||||||||||||||||||||
||||||||||||||||||||
||||||||||||||||||||
||||||||||||||||||||
||||||||||||||||||||
||||||||||||||||17:33:25|17:33:25|17:33:25|17:33:25|
|Main|Main|Main|Over-<br>ride|Data<br>view|Data<br>view|Spec|Spec||||||||ATO|ATO|||



**Figure 93c – ATO objects outside stopping points in AD mode**


8.5.1.5 Figure 93d gives an example of ATO objects when the train is at a stopping point in Full
Supervision mode.


Version 4.0.0 PAGE 123 OF 317


**ERA ERTMS unit**

**ETCS Driver Machine Interface**




|Col1|Col2|Col3|150<br>100 200<br>0<br>50 300<br>0 400|Col5|Col6|Col7|Col8|4000<br>2000<br>- 0<br>1000<br>22<br>500<br>-<br>+<br>5<br>+<br>0<br>ATO 1:09|Col10|Col11|Col12|Col13|Col14|Main|
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
|||||||||||||||Over-<br>ride|
|||||||||||||||Data<br>view|
|||||||||||||||Spec|
||||||||||||||||
||||||||||||||||
||||||||||||||||
|**2**|**2**|**2**||||||ATO|||||||
||||||||||||||||
||||||||||||||||
||||||||||||||||
|||||||||||||17:33:25|17:33:25|17:33:25|
||||||||||||||||


























|Col1|Col2|Col3|150<br>100 200<br>0<br>50 300<br>0 400|Col5|Col6|Col7|Col8|Col9|Col10|Col11|4000<br>2000<br>- 0<br>1000<br>22<br>500<br>-<br>+<br>5<br>+<br>0|Col13|Col14|Col15|Col16|Col17|Col18|Col19|Col20|Col21|
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
||||**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**<br>**0**|**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**<br>**0**|**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**<br>**0**|**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**<br>**0**|**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**<br>**0**|**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**<br>**0**|**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**<br>**0**|**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**<br>**0**|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>-<br>22<br>-<br>0|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>-<br>22<br>-<br>0|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>-<br>22<br>-<br>0|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>-<br>22<br>-<br>0|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>-<br>22<br>-<br>0|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>-<br>22<br>-<br>0|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>-<br>22<br>-<br>0|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>-<br>22<br>-<br>0|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>-<br>22<br>-<br>0||
||||||||||||||||||||||
||||||||||||||||||||||
||||||||||||||||||||||
||||||||||||||||||||||
||||||||||||||||||||||
|**2**|**2**|**2**|||||||||ATO|||1:09|1:09||||||
||||||||||||||||||||||
||||||||||||||||||||||
||||||||||||||||||||||
||||||||||||||||||||||
||||||||||||||||||||||
||||||||||||||||||17:33:25|17:33:25|17:33:25|17:33:25|
|Main|Main|Main|Over-<br>ride|Data<br>view|Data<br>view|Spec|Spec||||||||||||||



**Figure 93d – ATO objects at a stopping point in FS mode**


8.5.1.6 Figure 93e gives an example of ATO objects when the train is outside stopping points in
Full Supervision mode.


Version 4.0.0 PAGE 124 OF 317


**ERA ERTMS unit**

**ETCS Driver Machine Interface**






|Col1|Col2|Col3|150<br>100 200<br>133<br>50 300<br>0 400|Col5|Col6|Col7|Col8|4000 +<br>2<br>2000<br>+<br>-<br>1000<br>22<br>500<br>-<br>+<br>5<br>+<br>0<br>Welwyn North<br>ATO 17:36:48|Col10|Col11|Col12|Main|
|---|---|---|---|---|---|---|---|---|---|---|---|---|
|||||||||||||Over-<br>ride|
|||||||||||||Data<br>view|
|||||||||||||Spec|
||||||||||||||
||||||||||||||
|**2**|**2**|**2**||||||ATO|ATO|ATO|||
||||||||||||||
||||||||||||||
||||||||||||||
|||||||||||17:33:25|17:33:25|17:33:25|
||||||||||||||






















|Col1|Col2|Col3|150<br>100 200<br>133<br>50 300<br>0 400|Col5|Col6|Col7|Col8|Col9|Col10|Col11|4000 +<br>2<br>2000<br>+<br>-<br>1000<br>22<br>500<br>-<br>+<br>5<br>+<br>0|Col13|Col14|Col15|Col16|Col17|Col18|Col19|
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
||||**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**<br>**133**|**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**<br>**133**|**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**<br>**133**|**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**<br>**133**|**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**<br>**133**|**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**<br>**133**|**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**<br>**133**|**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**<br>**133**|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>-<br>22<br>-<br>+<br>2<br>+|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>-<br>22<br>-<br>+<br>2<br>+|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>-<br>22<br>-<br>+<br>2<br>+|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>-<br>22<br>-<br>+<br>2<br>+|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>-<br>22<br>-<br>+<br>2<br>+|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>-<br>22<br>-<br>+<br>2<br>+|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>-<br>22<br>-<br>+<br>2<br>+||
||||||||||||||||||||
||||||||||||||||||||
||||||||||||||||||||
||||||||||||||||||||
||||||||||||||||||||
||||||||||||||||||||
|**2**|**2**|**2**|||||||||ATO|Welwyn North<br>17:36:48|Welwyn North<br>17:36:48|Welwyn North<br>17:36:48|Welwyn North<br>17:36:48||||
||||||||||||||||||||
||||||||||||||||||||
||||||||||||||||||||
||||||||||||||||||||
||||||||||||||||||||
||||||||||||||||17:33:25|17:33:25|17:33:25|17:33:25|
|Main|Main|Main|Over-<br>ride|Data<br>view|Data<br>view|Spec|Spec||||||||ATO|ATO|||



**Figure 93e – ATO objects outside stopping points in FS mode**


8.5.1.7 While a warning sound is requested by the ERTMS/ATO on-board, the audible information
S2, see chapter 14 shall be played.


**8.5.2** **ATO status**


8.5.2.1 This DMI object shows the ATO status.


8.5.2.2 When using touch screen technology, the ATO status shall use the area G1 (see Figure
93f).


8.5.2.3 When using soft key technology, the ATO status shall use the areas G1 and F9 (see
Figure 93f).


Version 4.0.0 PAGE 125 OF 317


**ERA ERTMS unit**

**ETCS Driver Machine Interface**







































**Figure 93f – Area for the ATO status**



8.5.2.4 The symbols ATO01, ATO02, ATO03, ATO04 and ATO05 shall be used in G1 (see
chapter 13), depending on the current ATO status.


8.5.2.5 When using touch screen technology, when ATO02 is displayed, the area G1 shall also
be an enabled up-type button allowing the driver to request the start of automatic driving
(i.e. G1 becomes the ATO engage button).


8.5.2.6 When using touch screen technology, when ATO03 or ATO04 is displayed, the area G1
shall also be an enabled up-type button allowing the driver to request the stop of automatic
driving (i.e. G1 becomes the ATO disengage button).


8.5.2.7 When using soft key technology, when ATO02 is displayed in G1, the area F9 shall be an
enabled up-type button echoing the symbol in G1 and allowing the driver to request the
start of automatic driving (i.e. G1 becomes the ATO engage button).


8.5.2.8 When using soft key technology, when ATO03 or ATO04 is displayed in G1, the area F9
shall be an enabled up-type button echoing the symbol in G1 and allowing the driver to
request the stop of automatic driving (i.e. G1 becomes the ATO disengage button).


8.5.2.9 In addition to the ATO engage/disengage buttons located on the total image display area,
the ERTMS/ETCS DMI may offer the following possibility: button(s) positioned in an
ergonomic location on the driver’s desk.


8.5.2.10 Figures 93b, 93c, 93d, 93e give examples of ATO status.


**8.5.3** **Stopping points**


8.5.3.1 This DMI object shows an overview of the stopping points in advance of the train.


8.5.3.2 The stopping points shall be displayed in area D2/D3/D4 (see Figure 93g) and within the
movement authority and up to the first target at zero speed, if any.


Version 4.0.0 PAGE 126 OF 317


**ERA ERTMS unit**

**ETCS Driver Machine Interface**















































**Figure 93g – Area for the stopping points**





8.5.3.3 The symbol ATO21 shall be used to show the stopping points.


8.5.3.4 Figures 93b, 93c, 93d, 93e give examples of stopping points.


8.5.3.5 Along the distance scale of the planning information (see 8.3.3), the bottom of the symbols
shall be positioned at the distance from the current train front position as requested by the
ERTMS/ATO on-board.


8.5.3.6 Symbols shall be distributed over the three columns D2/D3/D4 to avoid overlapping as
much as possible. Two adjacent symbols shall not be placed into the same column but in
different columns.


8.5.3.7 Symbols in the same column D2, D3 or D4 shall not be hidden by symbols at a longer
distance i.e. in case of overlapping symbols, the closest symbol shall be drawn on top of
the more distant symbol(s).


8.5.3.8 The rules 8.5.3.6 and 8.5.3.7 shall apply also taking into account the position of the orders
and announcements symbols of the planning information (see 8.3.4)


**8.5.4** **Stopping accuracy**


8.5.4.1 This DMI object shows the stopping accuracy when the train stops at a stopping point.


8.5.4.2 The stopping accuracy shall be displayed in area G2 (see Figure 93h).


Version 4.0.0 PAGE 127 OF 317


**ERA ERTMS unit**

**ETCS Driver Machine Interface**































**Figure 93h – Area for the stopping accuracy**



8.5.4.3 The symbol ATO06 shall be used to indicate that the train has overshot the stopping
window and that the driver is requested to act.


8.5.4.4 The symbol ATO07 shall be used to indicate that the train has undershot the stopping
window and that the driver is requested to act.


8.5.4.5 The symbol ATO08 shall be used to indicate that the ATO has achieved an accurate stop.


8.5.4.6 Figures 93b and 93d show examples of the presentation of an accurate stop using ATO08
in G2.


**8.5.5** **Dwell time**


8.5.5.1 This DMI object shows the remaining dwell time.


8.5.5.2 The remaining dwell time shall be displayed in area G3 (see Figure 93i).





























**Figure 93i – Area for the dwell time**


8.5.5.3 The remaining dwell time shall be displayed in grey.





8.5.5.4 If the remaining time is ≤ 59s, the time shall be shown in the format ‘[s]s’ with the numbers
right aligned with an indent of 18 cells.


Version 4.0.0 PAGE 128 OF 317


**ERA ERTMS unit**

**ETCS Driver Machine Interface**


8.5.5.5 If the remaining time is > 59s, the time shall be shown in the format ‘[m]m:ss’ with the
numbers right aligned with an indent of 11 cells.


8.5.5.6 This remaining dwell time shall be vertically centred in G3.


8.5.5.7 When the ERTMS/ATO on-board requests to display “Train hold”, the symbol ATO09 shall
be used.


8.5.5.8 Figures 93b and 93d show examples of the remaining dwell time in G3.


**8.5.6** **Door information**


8.5.6.1 This DMI object shows information about the opening/closing of doors.


8.5.6.2 The door information shall be displayed in area G4 (see Figure 93j).





























**Figure 93j – Area for door information**



8.5.6.3 The symbols ATO10, ATO11, ATO12, ATO13, ATO14, ATO15 and ATO16 shall be used
to respectively indicate “Request driver to open both sides doors”, “Request driver to open
left doors”, “Request driver to open right doors”, “Doors are open”, “Request driver to close
doors”, “Doors are being closed by ATO” and “Doors are closed”.


8.5.6.4 Figures 93b and 93d show examples of door information in G4.


**8.5.7** **Next stopping point name and estimated arrival time**


8.5.7.1 This DMI object shows information about the name of the next stopping point and its
estimated arrival time.


8.5.7.2 The name of the next stopping point and its estimated arrival time shall be displayed in
the G2/G3/G4 area (see Figure 93k).


Version 4.0.0 PAGE 129 OF 317


**ERA ERTMS unit**

**ETCS Driver Machine Interface**





























**Figure 93k – Area for Stopping point name and estimated arrival time**





8.5.7.3 The name of the next stopping point shall be displayed on a first text line.


8.5.7.4 The estimated arrival time shall be displayed on a second text line in the format ‘hh:mm:ss’
with a 24 hours time reference.


8.5.7.5 Each text line shall be horizontally centred in the G2/G3/G4 area.


8.5.7.6 Figures 93c and 93e show examples of the Stopping point name and estimated arrival
time.


**8.5.8** **Skip stopping point status**


8.5.8.1 This DMI object shows information about the skip stopping point status.


8.5.8.2 When using touch screen technology, the skip stopping point status shall use the area G5
(see Figure 93l).


8.5.8.3 When using soft key technology, the skip stopping point status shall use the areas G5 and
F10 (see Figure 93l).



































**Figure 93l – Area for skip stopping point status**





Version 4.0.0 PAGE 130 OF 317


**ERA ERTMS unit**

**ETCS Driver Machine Interface**


8.5.8.4 The symbols ATO17, ATO18 and ATO19 shall be used to respectively indicate the status
“Skip Stopping Point Inactive”, “Skip Stopping Point requested by ATO-TS”, “Skip
Stopping Point requested by driver”.


8.5.8.5 When using touch screen technology, when ATO17 or ATO19 is displayed, the area G5
shall be an enabled delay-type button for the driver to request or revoke the skip stopping
point.


8.5.8.6 When using soft key technology, when ATO17 or ATO19 is displayed in G5, the area F10
shall be an enabled delay-type button echoing the symbol in G5.


8.5.8.7 In addition to the Skip Stopping Point request/revoke buttons located on the total image
display area, the ERTMS/ETCS DMI may offer the following possibility: button(s)
positioned in an ergonomic location on the driver’s desk.


8.5.8.8 Figures 93c and 93e show examples of skip stopping point status in G5.


**8.5.9** **Target advice speed**


8.5.9.1 This DMI object shows the target advice speed.


8.5.9.2 The target advice speed indication shall be displayed in area B0 (see Figure 93m).































**Figure 93m – Area for the target advice speed**





8.5.9.3 The object to indicate the target advice speed shall be a medium grey circle with a
diameter of 10 cells.


8.5.9.4 The centre of the target advice speed object shall correspond to the target advice speed
value and shall be located on a circle with a radius of 111 cells having the same centre as
area B0.


8.5.9.5 The target advice speed object shall cover the speed dial and shall be covered by the set
speed in case both objects overlap.


8.5.9.6 Figure 93n shows the target advice speed object.


Version 4.0.0 PAGE 131 OF 317


**ERA ERTMS unit**

**ETCS Driver Machine Interface**






|Col1|Col2|Col3|150<br>100 200<br>88<br>50 300<br>0 400|Col5|Col6|Col7|Col8|4000 +<br>2<br>2000<br>+<br>-<br>1000<br>22<br>500<br>-<br>+<br>5<br>+<br>0<br>Welwyn North<br>ATO 17:36:48|Col10|Col11|Col12|Main|
|---|---|---|---|---|---|---|---|---|---|---|---|---|
|||||||||||||Over-<br>ride|
|||||||||||||Data<br>view|
|||||||||||||Spec|
||||||||||||||
||||||||||||||
|**2**|**2**|**2**||||||ATO|ATO|ATO|||
||||||||||||||
||||||||||||||
||||||||||||||
|||||||||||17:33:25|17:33:25|17:33:25|
||||||||||||||






















|Col1|Col2|Col3|150<br>100 200<br>88<br>50 300<br>0 400|Col5|Col6|Col7|Col8|Col9|Col10|Col11|4000 +<br>2<br>2000<br>+<br>-<br>1000<br>22<br>500<br>-<br>+<br>5<br>+<br>0|Col13|Col14|Col15|Col16|Col17|Col18|Col19|
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
||||**88**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**88**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**88**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**88**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**88**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**88**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**88**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|**88**<br>**150**<br>**100**<br>**200**<br>**300**<br>**50**<br>**0**<br>**400**|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>-<br>22<br>-<br>+<br>2<br>+|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>-<br>22<br>-<br>+<br>2<br>+|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>-<br>22<br>-<br>+<br>2<br>+|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>-<br>22<br>-<br>+<br>2<br>+|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>-<br>22<br>-<br>+<br>2<br>+|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>-<br>22<br>-<br>+<br>2<br>+|4000<br>2000<br>1000<br>500<br>0<br>+<br>5<br>+<br>-<br>22<br>-<br>+<br>2<br>+||
||||||||||||||||||||
||||||||||||||||||||
||||||||||||||||||||
||||||||||||||||||||
||||||||||||||||||||
||||||||||||||||||||
|**2**|**2**|**2**|||||||||ATO|Welwyn North<br>17:36:48|Welwyn North<br>17:36:48|Welwyn North<br>17:36:48|Welwyn North<br>17:36:48||||
||||||||||||||||||||
||||||||||||||||||||
||||||||||||||||||||
||||||||||||||||||||
||||||||||||||||||||
||||||||||||||||17:33:25|17:33:25|17:33:25|17:33:25|
|Main|Main|Main|Over-<br>ride|Data<br>view|Data<br>view|Spec|Spec||||||||ATO|ATO|||



**Figure 93n – Advice Speed at 125km/h**


**8.5.10** **Coasting advice**


8.5.10.1 This DMI object shows a coasting advice.


8.5.10.2 The coasting advice shall be displayed in area B8 (see Figure 93o).


Version 4.0.0 PAGE 132 OF 317


**ERA ERTMS unit**

**ETCS Driver Machine Interface**









































**Figure 93o – Area for coasting advice**





8.5.10.3 The symbol ATO20 shall be used to indicate a coasting advice.


8.5.10.4 Figure 93e shows an example of coasting advice.


**8.5.11** **Next advice change marker**


8.5.11.1 This DMI object displays in D7 the location of the next advice change (see Figure 93p).


8.5.11.2 The next advice change marker shall be a horizontal dashed line in grey with a 2 cells
width and a length equal to the width of D7.


8.5.11.3 The dashed line shall be composed of 5 grey segments of a length of 10 cells. The grey
segments shall be separated from each other by 10 cells and the first grey segment shall
start from the left border of D7.


8.5.11.4 The bottom of the next advice change marker shall be at the location requested by the
ERTMS/ATO on-board according to the distance scale of the planning information (see
8.3.3).


8.5.11.5 The next advice change marker shall be inserted between the distance scale and the
indication marker in the layering principles of the planning information defined in 8.3.2.















































**Figure 93p – Area for the indication marker**





Version 4.0.0 PAGE 133 OF 317


**ERA ERTMS unit**

**ETCS Driver Machine Interface**


8.5.11.6 Figure 93e shows an example of the presentation of the next advice change marker in
D7.


**8.6** **Sub-level window selection**


































































































|A1<br>A2<br>A<br>A3<br>A4|B 2<br>BB1<br>B6 B3 B4 B5<br>2 C3 C4C C1 C5 C6|Col3|Col4|Col5|Col6|D12<br>B0 DD11<br>B7|D13 D14<br>DD<br>D2 D3 D4D D7<br>56|Col9|Col10|Col11|Col12|Col13|Col14|Col15|Col16|D14|D<br>8<br>I|H1<br>H2<br>H3|
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
|A1<br>A3<br>A4<br>A2<br><br>A|2<br>C3<br>C4<br>C1<br>C5<br>C6<br>B3<br>B4<br>B5<br><br>B1<br>B2<br>B6<br>C<br>B|2<br>C3<br>C4<br>C1<br>C5<br>C6<br>B3<br>B4<br>B5<br><br>B1<br>B2<br>B6<br>C<br>B|2<br>C3<br>C4<br>C1<br>C5<br>C6<br>B3<br>B4<br>B5<br><br>B1<br>B2<br>B6<br>C<br>B|2<br>C3<br>C4<br>C1<br>C5<br>C6<br>B3<br>B4<br>B5<br><br>B1<br>B2<br>B6<br>C<br>B|2<br>C3<br>C4<br>C1<br>C5<br>C6<br>B3<br>B4<br>B5<br><br>B1<br>B2<br>B6<br>C<br>B|B7<br>D12<br>D1<br><br>B0<br>D1|D2|D2|D3|D4|D4|<br>D<br>6|D7<br><br><br>|D7<br><br><br>|D7<br><br><br>|D7<br><br><br>|D7<br><br><br>|D7<br><br><br>|
|A1<br>A3<br>A4<br>A2<br><br>A|2<br>C3<br>C4<br>C1<br>C5<br>C6<br>B3<br>B4<br>B5<br><br>B1<br>B2<br>B6<br>C<br>B|2<br>C3<br>C4<br>C1<br>C5<br>C6<br>B3<br>B4<br>B5<br><br>B1<br>B2<br>B6<br>C<br>B|2<br>C3<br>C4<br>C1<br>C5<br>C6<br>B3<br>B4<br>B5<br><br>B1<br>B2<br>B6<br>C<br>B|2<br>C3<br>C4<br>C1<br>C5<br>C6<br>B3<br>B4<br>B5<br><br>B1<br>B2<br>B6<br>C<br>B|2<br>C3<br>C4<br>C1<br>C5<br>C6<br>B3<br>B4<br>B5<br><br>B1<br>B2<br>B6<br>C<br>B|B7<br>D12<br>D1<br><br>B0<br>D1|D2|D2|D3|D4|D4|<br>D<br>6|D7<br><br><br>|D7<br><br><br>|D7<br><br><br>|D7<br><br><br>|D7<br><br><br>|H4<br>H|
|A1<br>A3<br>A4<br>A2<br><br>A|2<br>C3<br>C4<br>C1<br>C5<br>C6<br>B3<br>B4<br>B5<br><br>B1<br>B2<br>B6<br>C<br>B|2<br>C3<br>C4<br>C1<br>C5<br>C6<br>B3<br>B4<br>B5<br><br>B1<br>B2<br>B6<br>C<br>B|2<br>C3<br>C4<br>C1<br>C5<br>C6<br>B3<br>B4<br>B5<br><br>B1<br>B2<br>B6<br>C<br>B|2<br>C3<br>C4<br>C1<br>C5<br>C6<br>B3<br>B4<br>B5<br><br>B1<br>B2<br>B6<br>C<br>B|2<br>C3<br>C4<br>C1<br>C5<br>C6<br>B3<br>B4<br>B5<br><br>B1<br>B2<br>B6<br>C<br>B|B7<br>D12<br>D1<br><br>B0<br>D1|D2|D2|D3|D4|D4|<br>D<br>6|D7<br><br><br>|D7<br><br><br>|D7<br><br><br>|D7<br><br><br>|D7<br><br><br>|H5<br>|
|A1<br>A3<br>A4<br>A2<br><br>A|2<br>C3<br>C4<br>C1<br>C5<br>C6<br>B3<br>B4<br>B5<br><br>B1<br>B2<br>B6<br>C<br>B|2<br>C3<br>C4<br>C1<br>C5<br>C6<br>B3<br>B4<br>B5<br><br>B1<br>B2<br>B6<br>C<br>B|B3|B4|B4|B4|B4|B4|B4|B4|B4|B4|B4|B4|B4|B4|B4|B4|
|C8<br>C9<br>C|2<br>C3|C4<br>|C4<br>|C1<br>C|C1<br>C|C7<br>G1<br>D9|C7<br>G1<br>D9|G2|G2|G 3<br>D10|G 3<br>D10|G 3<br>D10|G9<br>G4|G9<br>G4|G5<br>D1|G5<br>D1||H6|
|E1|E6<br>E5<br><br>|E6<br>E5<br><br>|E6<br>E5<br><br>|E6<br>E5<br><br>|E6<br>E5<br><br>|E6<br>E5<br><br>|E6<br>E5<br><br>|E6<br>E5<br><br>|E6<br>E5<br><br>|G8<br>G|G8<br>G|G8<br>G|G8<br>G|G8<br>G|G10|G10|G10|H7|
|E2<br>E3<br>F1|E2<br>E3<br>F1|E2<br>E3<br>F1|E2<br>E3<br>F1|E2<br>E3<br>F1|E2<br>E3<br>F1|E2<br>E3<br>F1|E2<br>E3<br>F1|E2<br>E3<br>F1|E2<br>E3<br>F1|E2<br>E3<br>F1|E2<br>E3<br>F1|E2<br>E3<br>F1|E2<br>E3<br>F1|E2<br>E3<br>F1|E2<br>E3<br>F1|E2<br>E3<br>F1|E2<br>E3<br>F1|E2<br>E3<br>F1|
|E2<br>E3<br>F1|E8<br>E7<br><br><br>E|E8<br>E7<br><br><br>E|E8<br>E7<br><br><br>E|E8<br>E7<br><br><br>E|E8<br>E7<br><br><br>E|E8<br>E7<br><br><br>E|E8<br>E7<br><br><br>E|E8<br>E7<br><br><br>E|E8<br>E7<br><br><br>E|E8<br>E7<br><br><br>E|E8<br>E7<br><br><br>E|E8<br>E7<br><br><br>E|E8<br>E7<br><br><br>E|E8<br>E7<br><br><br>E|E8<br>E7<br><br><br>E|E8<br>E7<br><br><br>E|E8<br>E7<br><br><br>E|E8<br>E7<br><br><br>E|
|E2<br>E3<br>F1|E8<br>E7<br><br><br>E|E8<br>E7<br><br><br>E|E8<br>E7<br><br><br>E|E8<br>E7<br><br><br>E|E8<br>E7<br><br><br>E|E8<br>E7<br><br><br>E|E8<br>E7<br><br><br>E|E8<br>E7<br><br><br>E|E8<br>E7<br><br><br>E|E8<br>E7<br><br><br>E|E8<br>E7<br><br><br>E|E8<br>E7<br><br><br>E|E8<br>E7<br><br><br>E|G13|G13|G13|G13|G13|
|E2<br>E3<br>F1|F2|F3|F3|F3|F4<br>F5|F6|F6|F7|F7|F7|F8|F8|F8|F9|F9|F9|F10|F10|



**Figure 94 – Sub-level window selection**


8.6.1.1 The sub-level window selection allows the driver to select the specific sub-level windows.


8.6.1.2 The sub-level window selection shall be composed of 5 buttons displayed in area F1 –
F5.


8.6.1.3 The 5 buttons shall be allocated to the areas F1 – F5 as specified in Table 18.


8.6.1.4 The 5 buttons for sub-level window selection shall always be ‘enabled’.


8.6.1.5 A button of the main menu shall allow accessing the corresponding sub-level window as
specified in Table 18.


8.6.1.6 For the ‘Settings’ sub-level window, the ERTMS/ETCS DMI shall additionally offer the
possibility to access it via a button positioned on an ergonomic location on the driver’s
desk.


8.6.1.7 When using touch screen technology, up-type buttons shall be used.







|Area|Button label|Sub-level window|
|---|---|---|
|F1|Main|Main|
|F2|Over-<br>ride|Override|
|F3|Data<br>view|Data view|
|F4|Spec|Special|
|F5|symbol SE04|Settings|


**Table 18 – sub-level window selection**


Version 4.0.0 PAGE 134 OF 317


**ERA ERTMS unit**

**ETCS Driver Machine Interface**

