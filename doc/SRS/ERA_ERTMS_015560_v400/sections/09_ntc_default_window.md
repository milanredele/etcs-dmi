##### **9. ETCS AND NTC INFORMATION SHOWN ON A NTC**

**DEFAULT WINDOW**


**9.1** **Introduction**


9.1.1.1 The chapter 9 is applicable for the modes SN and NL in ERTMS/ETCS level NTC.


9.1.1.2 The chapter 9.2 applies regardless the National System is interfaced to the ERTMS/ETCS
onboard through an STM. In case the National System is interfaced to the ERTMS/ETCS
onboard through an STM, the chapters 9.3, 9.3.7.1.10 and 9.5 also apply.


**9.2** **ETCS objects**


9.2.1.1 The ETCS objects/functions in document [2] chapter 4.7.2, modes SN and NL shall be
displayed as far as they concern a default window, i.e. the appearance shall be as
specified in chapter 8 but the location of the ETCS objects/functions will be according to
the definition of the NTC default window of the corresponding National System.


9.2.1.2 The ETCS buttons accessing the sub-level windows shall be available with the labels as
specified in 8.5 but with their size and location depending on the ergonomic arrangements
of areas of the NTC default window of the corresponding National System.


**9.3** **NTC Objects**


**9.3.1** **General**


9.3.1.1 All texts used with NTC objects shall use the same font, indent, character and line spacing
as used for ETCS objects.


9.3.1.2 The colours requested by the text, indicator or button attribute of a STM request shall be
displayed with RGB values as specified for ETCS objects in Table 4. The additional
colours not specified for ETCS objects shall be displayed with the RGB values in Table
19.

|Colour name|Red|Green|Blue|
|---|---|---|---|
|blue|0|0|234|
|green|0|234|0|
|light red|255|96|96|
|light green|96|255|96|



**Table 19 – 24-bit RGB colour scheme for additional NTC colours**


**9.3.2** **Flashing mode and style**


9.3.2.1 When flashing style ‘yellow frame’ is selected, each NTC indicator or button requested to
flash by the STM shall be surrounded by a flashing frame as specified in 5.1.1.3.1.


Version 4.0.0 PAGE 135 OF 317


**ERA ERTMS unit**

**ETCS Driver Machine Interface**


9.3.2.2 When flashing style ‘whole area’ is selected, each NTC indicator or button requested to
flash by the STM shall toggle between visible and not visible state (i.e. the dark blue
background colour).


9.3.2.3 Flashing of different objects shall be synchronised: all objects with normal flashing mode
and the same frequency shall be in the same state at the same time ; objects with
counterphase flashing shall be in the alternative state at this time.


**9.3.3** **Text Messages**


9.3.3.1 NTC text messages shall be treated and displayed as and together with ETCS text
messages, including scrolling and acknowledgment (see 8.2.3.4).


9.3.3.2 Exception: the display shall be according to the display attribute sent by the STM with the
text message.


**9.3.4** **Indicators**


9.3.4.1 An NTC indicator can display text and/or an icon. Its state may change by changing the
contained text, icon, text colour, text background colour or flashing mode. Additionally its
position may change.


9.3.4.2 Visibility of caption text


9.3.4.2.1 The caption text shall always be visible when no icon is requested by the STM.


9.3.4.2.2 If the STM uses the customisable DMI, the caption text shall also be visible, if “display of
text upon icon” is requested as corresponding icon attribute in the configuration data.


9.3.4.2.3 Otherwise the caption text shall be ignored by the ERTMS/ETCS on-board.


9.3.4.3 An indicator shall be displayed according to the display attribute sent with the indicator
request.


9.3.4.4 If both the caption text and the icon are displayed, the layering shall be text in foreground,
icon in middle layer and background colour in background.


9.3.4.5 The part of the caption text from the seventh character shall be displayed on a second
line.


**9.3.5** **Buttons**


9.3.5.1 Buttons are a pure functional extension of Indicators. All requirements of chapter 9.3.4
shall apply to buttons, by replacing "indicator" with "button".


9.3.5.2 The ERTMS/ETCS-onboard shall display NTC buttons pressed and not pressed like
ETCS buttons.


**9.3.6** **Sounds**


9.3.6.1 A sound shall be played according to the sound definition sent in the sound requests.


**9.3.7** **Supervision Information**


Version 4.0.0 PAGE 136 OF 317


**ERA ERTMS unit**

**ETCS Driver Machine Interface**


9.3.7.1 If the STM uses the customisable DMI service and is configured to display such
information or it uses the unified DMI service, the speed and distance supervision
information sent by the STM shall be displayed by the ERTMS/ETCS on-board according
to the following rules:


9.3.7.1.1 The current train speed pointer shall be displayed as specified in 8.2.1.2 but with the
colour requested for it by the STM.


9.3.7.1.2 The current train speed digital shall be displayed as specified in 8.2.1.3.


9.3.7.1.3 When requested by the display mode sent by the STM, the distance to target bar shall be
displayed as specified in 8.2.2.1.


9.3.7.1.4 When requested by the display mode sent by the STM, the distance to target digital shall
be displayed as specified in 8.2.2.2.


9.3.7.1.5 When the supervision speeds are requested to be displayed as bars, the width of those
speed bars shall be 9 cells, except for:


a) the part of the permitted speed bar below a release speed bar,


b) the release speed bar,


c) the intervention speed bar if it is requested to display it with the “wide bar width”.


9.3.7.1.6 When a release speed bar is displayed, the permitted speed bar and the release speed
bar shall be indicated applying clause 8.2.1.6.4 by analogy to the CSG.


9.3.7.1.7 When the intervention speed bar is requested to be displayed with “wide bar width”, it shall
be displayed with 20 cells.


9.3.7.1.8 The speed bars and hooks shall be displayed along the speed dial in the area B2 as for
the Circular speed gauge and for the Basic speed hook(s) used on the ETCS default
window, except consideration of the display mode.


a) A dark grey bar below 0km/h (-149 degrees to -144 degrees, as specified for ETCS

default window) if display of any bar is requested.


b) The target speed bar in the colour requested for target speed between permitted speed

and target speed if permitted speed is displayed and is lower than target speed,
otherwise between 0km/h and target speed.


c) If the requested display mode is ‘hook only’, the target speed hook shall be displayed

at the target speed as specified in 8.2.1.5.5 but with the colour requested for it by the
STM.


d) If the requested display mode is ‘hook and bar’, the target speed hook shall be

displayed at the target speed as specified in 8.2.1.4.7 but with the colour requested for
it by the STM.


e) The permitted speed bar in the colour requested for permitted speed between target

speed and permitted speed if target speed is displayed and is lower than permitted
speed, otherwise between 0km/h and permitted speed. The permitted speed bar may
overlap with the release speed bar.


Version 4.0.0 PAGE 137 OF 317


**ERA ERTMS unit**

**ETCS Driver Machine Interface**


f) If the requested display mode is ‘hook only’, the permitted speed hook shall be

displayed at the permitted speed as specified in 8.2.1.5.4 but with the colour requested
for it by the STM.


g) If the requested display mode is ‘hook and bar’, the permitted speed hook shall be

displayed at the permitted speed as specified in 8.2.1.4.7 but with the colour requested
for it by the STM.


h) The intervention speed bar between permitted speed and intervention speed in the

colour requested for intervention speed.


i) The release speed bar between 0km/h and release speed, possibly overlapping with

permitted speed bar in the colour requested for the release speed.


j) The order of superimposing objects on top of the background from back to front is:

intervention speed bar, target speed bar/hook, permitted speed bar/hook, release
speed bar.


9.3.7.1.9 The release speed digital display shall be displayed in the colour requested for the release
speed.


9.3.7.1.10 As long as no information has been sent by the STM, the train speed pointer shall be

displayed in grey and no other supervision information shall be displayed.


**9.4** **Customisable DMI service**


9.4.1.1 The size and position of NTC DMI objects shall be specified in cells using the same
coordinate system with 640x480 cells as specified in 6.2. The position of an object shall
be defined as the offset of the upper left corner of the object from the upper left corner of
the total grid array. It shall be retrieved from the configuration data using the position
identifier sent by the STM. The specification of the customisable DMI service
consequently does not reuse the ETCS layout except when explicitly referring to the name
of an ETCS area.


9.4.1.2 With the customisable DMI service, the areas for text message (E5-E11) and for its related
buttons shall not be used for DMI elements by an STM other than its national text
messages. If the ETCS speed and supervision display is used by the STM, it shall not be
hidden by other NTC elements displayed in the same area.


9.4.1.3 The customisable DMI service shall display icons centred in the specified area.


**9.5** **Unified DMI service**


**9.5.1** **Introduction**


9.5.1.1 As a principle for the unified DMI service, the ETCS default window is offered to the STMs
with the same definition of the areas as specified in chapter 6. No ETCS areas are moved.


9.5.1.2 Only areas of the ETCS default window that are not used for ETCS information in NTC
levels and modes NL or SN can be used for NTC buttons and indicators.


9.5.1.2.1 The available areas for buttons are


Version 4.0.0 PAGE 138 OF 317


**ERA ERTMS unit**

**ETCS Driver Machine Interface**


a) For soft key technology: F8, F9, F10, H2, H3, H4


b) For touch screen technology: F8, F9,C2, C3, C4, C5, C6, G1-G10 [1]


9.5.1.2.2 The available areas for indicators are B3, B4, B5, C2, C3, C4, C5, C6, G1-G10 [1], and H1
for soft key technology.


9.5.1.3 The available button and indicator areas are mapped to a corresponding position identifier.


9.5.1.4 Since the unified DMI has no configuration for the display of national information, the
following restrictions apply:


a) NTC indicators and buttons are displayed with caption texts, text and background

colour, but without icons. The font size and text alignment cannot be selected.


b) The flashing style used for NTC indicators/buttons and the slow/fast flashing frequencies

cannot be selected.


c) NTC sounds are specified by a sequence of segments defined by a duration and an

associated frequency sent to the ERTMS/ETCS on-board.


d) The speed dial range in B0 is the same range as the ETCS one.


**9.5.2** **Requirements**


9.5.2.1 The ERTMS/ETCS on-board shall display buttons and indicators in the ETCS area
specified by the position identifier.


9.5.2.2 The ERTMS/ETCS on-board shall display caption texts of buttons and indicators with 10
cells font size and centred vertically and horizontally.


9.5.2.3 The ERTMS/ETCS on-board shall implement the flashing style as ‘yellow frame’ for the
NTC indicators and buttons requested to flash by the STM. For slow flashing the frame
shall toggle every 0.5 seconds, for fast flashing every 0.25 seconds.


9.5.2.4 The ERTMS/ETCS on-board shall display the NTC supervision information using the
same range for the speed dial as for ETCS supervision information.


1 Some areas can be used for buttons or indicators, depending on the need of the National System


Version 4.0.0 PAGE 139 OF 317


**ERA ERTMS unit**

**ETCS Driver Machine Interface**

