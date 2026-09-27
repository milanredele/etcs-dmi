##### **5. GENERAL ERGONOMIC PRINCIPLES**


**5.1** **Principles for presentation**


**5.1.1** **Presentation techniques**


**5.1.1.1** **Borders**


5.1.1.1.1 To structure the presentation of the different objects, a three dimensional impression is
created by surrounding areas, buttons and input fields with a border.


5.1.1.1.2 The border of an area shall be drawn as follows to give the impression of depth:

a) Left and top lines of the area: 1 cell width, black colour

b) Right and bottom lines of the area: 1 cell width, shadow colour


5.1.1.1.3 Unless stated otherwise, the border of a button (touch screen technology) or the border
of the label part of a button (soft key technology) shall be drawn as follows to give the
impression it is lifted:

a) Left and top outer lines of the button: 1 cell width, black colour

b) Left and top inner lines of the button (adjacent to the outer line): 1 cell width, shadow

colour

c) Right and bottom outer lines of the button: 1 cell width, shadow colour

d) Right and bottom inner lines of the button (adjacent to the outer line): 1 cell width,

black colour


5.1.1.1.4 The border of an input field shall be drawn as follows to delimit the concerned input field
from the other ones:

a) Left/Top/Right/Bottom lines of the area: 1 cell width, medium grey colour


**5.1.1.2** **Layers**


5.1.1.2.1 Areas displayed with the same impression of depth shall form a layer (see Figure 1).


5.1.1.2.1.1 Note: The colours used in Figure 1 intentionally differ from the mandatory colours of
Table 4. They are optimised only for a printed copy of this specification.

###### Layer 0 Layer -1 Layer -2


Version 4.0.0 PAGE 18 OF 317


**ERA ERTMS unit**

**ETCS Driver Machine Interface**


**Figure 1 – Layer definition**


5.1.1.2.2 The areas without border shall form the layer 0.


5.1.1.2.3 The areas with a border and inside layer 0 shall form layer -1.


5.1.1.2.4 The areas with a border and inside layer -1 shall form layer -2.


5.1.1.2.5 When an area is allocated to the layer -1 or layer -2, a border shall be drawn around this
area.


**5.1.1.3** **Frames**


5.1.1.3.1 When a flashing frame is required as specified in the following chapters, it shall replace
the border of the concerned area/button and it shall be drawn as follows:

a) Left/Top/Right/Bottom lines of the area: 2 cells width, yellow


5.1.1.3.2 The frame(s) shall flash by toggling every 0.25 seconds between visible and not visible
(e.g. background colour) starting with the visible state.


**5.1.2** **Characters**


**5.1.2.1** **Character type**


5.1.2.1.1 The character type shall not use serifs.


5.1.2.1.2 The character type shall use a proportionally spaced font.


5.1.2.1.3 The character spacing shall be the normal spacing as defined by the chosen font.


5.1.2.1.4 Note: Chicago, Helvetica, Swiss or Verdana are recommended fonts.


5.1.2.1.5 When the dot character ‘.’ Is used in a keyboard (see 10.3.5 & 10.3.6), it shall be presented
in bold style.


**5.1.2.2** **Character height**


5.1.2.2.1 The height of the characters (see H in Figure 2) shall refer to the height of the capital
characters.







**Figure 2 – Height of characters and line spacing**


5.1.2.2.2 Note: The lower case characters and numbers are derived from the chosen font type.


Version 4.0.0 PAGE 19 OF 317


**ERA ERTMS unit**

**ETCS Driver Machine Interface**


5.1.2.2.3 The height of the characters shall be:

a) speed scale numbers, numbers for numeric/enhanced numeric/alphanumeric

keyboards, numbers on F areas for dedicated keyboards (soft key technology): 16
cells,

b) current speed (digital): 18 cells,

c) release speed (digital): 17 cells,

d) numbers for the kilometres part of the geographical position, for the remaining

distance to the tunnel stopping area, for the Lowest Supervised Speed within the
Movement Authority, for the remaining seconds of the dwell time (if ≤ 59 seconds), for
the remaining minutes of the dwell time (if > 59 seconds): 12 cells,

e) numbers for the target distance digital, in the planning information, for the metres part

of the geographical position, for the remaining seconds of the dwell time (if > 59
seconds): 10 cells,

f) local time of text messages: 10 cells,

g) letters for alphanumeric keyboards and for the label of the Train running number (i.e.

‘TRN’): 10 cells,

h) other characters (e.g. used for input fields, text messages, echo texts, etc.): 12 cells


**5.1.3** **Texts**


5.1.3.1 Unless stated otherwise, texts shall be left aligned inside its allocated area.


5.1.3.2 Unless stated otherwise, an indent of 3 cells shall be used from the limit of the area when
aligning a text.


5.1.3.3 Unless stated otherwise, texts shall be vertically centred inside its allocated area.


5.1.3.4 Unless stated otherwise, texts shall be in grey.


5.1.3.5 Unless stated otherwise, the line spacing of texts shall be 2 times the height of characters
(see 2H in Figure 2).


**5.1.4** **Numbers**


5.1.4.1 When using numbers, leading zeros shall not be shown (e.g. show 80 km/h not 080 km/h),
unless it is essential (e.g. telephone number).


**5.1.5** **Numeric or Alphanumeric data**


5.1.5.1 If a data contains more than 5 (alpha)numeric characters on a text line, a single ‘space’
character shall be introduced to create 2 separate groups of characters when displaying
this data. The length of each group of characters shall not exceed 5 characters.


5.1.5.2 A ‘line break’ shall be introduced every 8 characters when displaying this data i.e. not
more than 8 characters shall be presented on the same text line.


5.1.5.2.1 Note: the space characters and the line breaks are not part of the data value. They are
only used to ease the readability of long data.


Version 4.0.0 PAGE 20 OF 317


**ERA ERTMS unit**

**ETCS Driver Machine Interface**


5.1.5.2.2 Note: A data for which the range is limited to dedicated values (i.e. with a dedicated
keyboard, see 10.3 for more details) is not considered as a numeric or alphanumeric data.


**5.1.6** **Symbols**


5.1.6.1 When a symbol is referenced in this specification, it shall be displayed according to the
form/shape, colour and size as specified in chapter 13.


5.1.6.2 The pixels of the bitmap files specified in chapter 13 shall be understood as cells.


5.1.6.3 Every symbol shall be centred in its area.


**5.1.7** **Sounds**


5.1.7.1 When a sound is referenced in this specification, it shall be played as specified in chapter
14.


**5.1.8** **Units**


5.1.8.1 Unless stated otherwise, speeds shall be displayed in km/h.


5.1.8.2 Unless stated otherwise, distances shall be displayed in meters (m).


**5.2** **Physical parameters**


**5.2.1** **General parameters**


**5.2.1.1** **Display size**


5.2.1.1.1 The minimum size of the total image display area shall be 180 mm x 135 mm (w x h).


**5.2.1.2** **Display resolution**


5.2.1.2.1 The minimum resolution of the total image display area shall be based on a total grid array
of 640 x 480 square cells.


5.2.1.2.2 This 640 x 480 ratio shall form the basis for all object proportions independently of the
resolution and of the size of the total image display area.


**5.2.1.3** **Colours**


5.2.1.3.1 The following 24-bit RGB colour values shall be used.


5.2.1.3.2 Any reference in the specification to a colour shall be deemed to be a reference to this
Table 4.


5.2.1.3.3 The background colour shall always be the colour #6 “dark blue (background)”.

|Nr|Colour name|Red|Green|Blue|
|---|---|---|---|---|
|1|white|255|255|255|
|2|black|0|0|0|
|3|grey|195|195|195|



Version 4.0.0 PAGE 21 OF 317


**ERA ERTMS unit**

**ETCS Driver Machine Interface**

|4|medium grey|150|150|150|
|---|---|---|---|---|
|5|dark grey|85|85|85|
|6|dark blue (background)|3|17|34|
|7|shadow|8|24|57|
|8|yellow|223|223|0|
|9|orange|234|145|0|
|10|red|191|0|2|
|11|PASP dark|33|49|74|
|12|PASP light|41|74|107|



**Table 4 - 24-bit RGB colour scheme**


**5.2.2** **Luminance adjustment**


5.2.2.1 It shall be possible for the driver to adjust the luminance.


5.2.2.1.1 Note: Additionally, this adjustment may be done automatically.


5.2.2.2 The last stored luminance shall be used when opening the desk. In case no luminance is
stored onboard, the median value of the range shall be used as the default luminance.


5.2.2.3 Note: The range in which the luminance can be adjusted is outside the scope of the
present document.


5.2.2.4 In addition to the brightness window (see chapter 11.2.4), the ERTMS/ETCS DMI may
offer the following possibility to adjust the luminance: other means positioned on an
ergonomic location on the driver’s desk.


**5.2.3** **Loudspeaker adjustment**


5.2.3.1 It shall be possible for the driver to adjust the volume of the loudspeaker.


5.2.3.2 The last stored volume shall be used when opening the desk. In case no volume is stored
onboard, the median value of the range shall be used as the default volume.


5.2.3.3 Note: The range in which the volume can be adjusted is outside the scope of the present
document.


5.2.3.4 In addition to the volume window (see chapter 11.2.4), the ERTMS/ETCS DMI may offer
the following possibility to adjust the loudspeaker: other means positioned on an
ergonomic location on the driver’s desk.


**5.3** **Arrangement of information**


**5.3.1** **Windows**


**5.3.1.1** **General Requirements**


5.3.1.1.1 The presentation of objects, text messages and buttons shall be possible on several
levels. Within those levels, they shall be allocated to areas of the ERTMS/ETCS DMI.


Version 4.0.0 PAGE 22 OF 317


**ERA ERTMS unit**

**ETCS Driver Machine Interface**


5.3.1.1.2 Objects, text messages and buttons presented within the same level shall form a ‘window’.


5.3.1.1.3 The default windows of the ERTMS/ETCS DMI shall be the total image display area with
the allocation of objects, text messages and buttons as described in chapters 8 and 9.


5.3.1.1.4 A default window shall not cover any other window.


5.3.1.1.5 While a sub-level window is activated, it shall cover the parent level window. A window
shall be covered partially or totally by the sub-level window depending on the size of the
sub-level window. The latest sub-level window shall be active meaning that all other
windows shall not respond to any driver input.


5.3.1.1.6 A window shall be composed of:

a) a unique window title giving the topic of the window (e.g. Train data) ;

b) one or several areas for the content of the window e.g. input fields, buttons,.. ;

c) a [Close] button closing the window and returning to the parent window ;

d) possibly, a [Next] button: to be used to select the next window related to the same

topic ;

e) possibly, a [Previous] button: to be used to select the previous window related to the

same topic.


5.3.1.1.7 Exception: On a default window, 5.3.1.1.6 shall not apply.


5.3.1.1.8 Exception: When using a soft key technology, if there are several windows related to the
same topic (e.g. Train data), the [Close] button shall be replaced by the [Previous] button
on the windows following the first one. (see chapter 10.3.6).


5.3.1.1.8.1 Note: When using a soft key technology, for this kind of windows, there are not enough
keys to present all necessary navigation buttons. Consequently, the driver will have to
go back to the first window of the topic to find the [Close] button.


5.3.1.1.9 The scrolling between various windows related to the same topic shall not be circular i.e.
the first window shall not scroll to the last one and vice-versa.


5.3.1.1.10 Note: For more details about the navigation buttons, see chapter 5.3.2.7.


**5.3.1.2** **Window title**


5.3.1.2.1 A window title area shall meet the following requirements:


a) the height shall be 24 cells;


b) the background colour shall be black;


c) it shall contain a text label identifying the window;


d) the text label on the window title area shall be grey;


e) it shall be positioned at the top of the window;


f) it shall cover the width of the window, unless stated otherwise for specific windows;


g) if the number of DMI objects (e.g. buttons, text messages, input data fields) related to

the topic of a window cannot fit on the window area(s), the text label on the window title


Version 4.0.0 PAGE 23 OF 317


**ERA ERTMS unit**

**ETCS Driver Machine Interface**


shall include between brackets the sequence number of the current window and the
total number of windows related to the same topic separated by a slash e.g. (1/2).


**5.3.2** **Buttons**


**5.3.2.1** **Size of a button**


5.3.2.1.1 When using a touch screen technology, the size of the touch sensitive surface of the
button shall be equal to the size of the visible surface of the button, unless stated
otherwise for specific buttons.


**5.3.2.2** **Button operation feedback**


5.3.2.2.1 Activation of a button shall be accompanied by feedback:

a) visual, and

b) tactile and/or audible.


**5.3.2.3** **Button labels**


5.3.2.3.1 The buttons shall be labelled with a language dependent text or with a symbol (see
chapter 13).


5.3.2.3.2 The text label or the symbol shall be centred on the button, unless stated otherwise for
specific buttons.


**5.3.2.4** **Button colour**


5.3.2.4.1 The background colour of a button shall be the Dark Blue (background) colour, unless
stated otherwise for specific buttons.


**5.3.2.5** **Button states**


5.3.2.5.1 A button may have three different states: “enabled”, “disabled” and “pressed”.


5.3.2.5.2 An “enabled” button shall be shown slightly lifted from the background by displaying a
border (see 5.1.1.1.3).


5.3.2.5.3 A “pressed” button shall be shown slightly into the background by not displaying its border.


5.3.2.5.4 Only one button shall be in the “pressed” state at the same time.


5.3.2.5.5 A “disabled” button shall be:

a) shown as an “enabled” button with the text label in dark grey or with a specific symbol,

or

b) not shown at all.


5.3.2.5.6 Note: For soft key technology, the border of the button refers to the border around its label
part.


**5.3.2.6** **Button types**


5.3.2.6.1 There are three ways in which an “enabled” button can react to driver selections (up, down
or delay).


Version 4.0.0 PAGE 24 OF 317


**ERA ERTMS unit**

**ETCS Driver Machine Interface**


5.3.2.6.2 On selection by the driver, the up-type button (see Figure 3) shall change to the “pressed”
state and the ‘click’ sound shall be played. As long as the button remains pressed by the
driver, the button shall remain in the “pressed” state. After releasing the selection, the
button state shall exit the “pressed” state and a valid button activation shall be considered
by the onboard (implying that the function associated to the button is initiated).


5.3.2.6.3 If, when using touch screen technology, the driver selection continues, but outside the uptype button itself (the finger slides out of the sensitive area of the button) the button shall
return to the ”enabled” state and no valid button activation shall be considered by the
onboard. When the driver selection moves back to the button (the finger slides back onto
the sensitive area of the button) the button shall be shown in the “pressed” state again,
but this time without the ‘click’ sound played.



state


driver
action

on
button



time


time













**Figure 3 - Activation of an up-type button**


5.3.2.6.4 On selection by the driver, the down-type button (see Figure 4) shall alter from ”enabled”
to “pressed” and immediately back to the ”enabled” state. The ‘click’ sound shall be played
and a valid button activation shall be considered by the onboard.


5.3.2.6.5 A down-type button can have a repeat function if the button remains pressed by the driver
for longer than 1.5 seconds. After 1.5 seconds, the repeat function shall consider valid
button activations each 0.3 sec; the visual and audible indications are as if the driver was
pressing on the button every 0.3 sec.


Version 4.0.0 PAGE 25 OF 317


**ERA ERTMS unit**

**ETCS Driver Machine Interface**



button activation



state


driver
action

on
button



















**Figure 4 - Activation of a down-type button**


5.3.2.6.6 The delay-type button is similar to the up-type button but with a delay (see Figure 5). On
selection by the driver, the delay-type button shall change to the “pressed” state and the
‘click’ sound shall be played. The button shall then toggle every 0.25 seconds between
the “pressed” and “enabled” states as long as the button remains pressed by the driver.
After 2 seconds, if the button is still pressed by the driver, the button shall change again
to the “pressed” state and the procedure according to the up-type button shall be followed.
If the button is pressed by the driver for less than the 2 seconds, the button shall return to
the ”enabled” state, the procedure with the 2 seconds timer shall be reset and no valid
button activation shall be considered by the onboard


5.3.2.6.7 If, when using touch screen technology, the driver selection continues, but outside the
delay-type button itself (the finger slides out of the sensitive area of the button) the button
shall return to the ”enabled” state, the procedure with the 2 seconds timer shall be reset
and no valid button activation shall be considered by the onboard. When the driver
selection moves back to the delay-type button (the finger slides back onto the sensitive
area of the button), the procedure with the 2 seconds timer shall start again but this time
without the ‘click’ sound played.





button

state


driver
action

on
button









|button activation taken into account =|Col2|
|---|---|
|time<br>enabled<br>pressed<br> <br>~~2 s~~<br>not<br>pressed<br>pressed<br>~~2 s~~<br>not<br>presse<br>enabled<br>pressed<br>pressed<br>pressed<br>pressed<br>enabled<br>enabled<br>enabled|time<br>enabled<br>pressed<br> <br>~~2 s~~<br>not<br>pressed<br>pressed<br>~~2 s~~<br>not<br>presse<br>enabled<br>pressed<br>pressed<br>pressed<br>pressed<br>enabled<br>enabled<br>enabled|
|not<br>pressed|not<br>presse|


Version 4.0.0 PAGE 26 OF 317


**ERA ERTMS unit**

**ETCS Driver Machine Interface**


**Figure 5 - Activation of a delay-type button**


**5.3.2.7** **Navigation buttons**


5.3.2.7.1 The following navigation buttons shall be used where appropriate:


a) [Close] button: to be used for closing a window and returning to the parent window;

symbols NA11 of chapter 13 shall be used.


b) [Enter] button: to be used to accept the input field data value; the [Enter] button finishes

the handling of the current selection; symbol NA20 of chapter 13 shall be used (soft
key technology).


c) [Next] button: to be used to select the next window related to the same topic using the

symbol NA17.


d) [Previous] button: to be used to select the previous window related to the same topic

using the symbols NA18.


e) [Delete] button: to be used to delete the just entered character, symbol NA21 of chapter

13 shall be used.


f) [Up] or [Down] button: to be used to scroll respectively up and down in lists; symbols

NA13 and NA14 of chapter 13 shall be used.


g) [Scale Up] or [Scale Down] button: to be used respectively to shorten/enlarge a

distance scale; symbols NA03, NA04 (touch screen technology) and NA07, NA08 (soft
key technology) of chapter 13 shall be used.


h) Intentionally deleted.


i) [More] button: to be used to present the next predefined choices of a dedicated

keyboard or the next selections of a Menu window, symbol NA23 of chapter 13 shall
be used.


5.3.2.7.2 The [Delete], [Up] and [Down] buttons shall be down-type buttons with a repeat function.


5.3.2.7.3 The [Enter] button shall be an up-type unless an operational data check rule is not satisfied
in which case it becomes a delay-type button (see 10.3.4 for further details).


5.3.2.7.4 The [Close], [Next], [Previous], [Scale Up], [Scale Down] and [More] navigation buttons
shall always be up-type buttons.


5.3.2.7.5 For the [Up], [Down], [Scale Up], [Scale Down], [Next] and [Previous] buttons, they shall
be disabled if their respective function does not lead to any change in the display.


5.3.2.7.6 In some situations, the [Close] button (see 11.7) and the [Enter] button (see 10.3.4) shall
also be disabled.


5.3.2.7.7 If the buttons in “disabled” state are shown (see 5.3.2.5.5), the symbols NA05, NA06,
NA09, NA10, NA12, NA15, NA16, NA18.2, NA19 and NA22 shall respectively replace the
symbols NA03, NA04, NA07, NA08, NA11, NA13, NA14, NA17, NA18 and NA20.


**5.4** **Acknowledgements**


Version 4.0.0 PAGE 27 OF 317


**ERA ERTMS unit**

**ETCS Driver Machine Interface**


5.4.1.1 When using touch screen technology, when a driver’s acknowledgement is required and
can be displayed, the ERTMS/ETCS DMI shall always offer an acknowledgement (Ack)
located on the total image display area itself. In addition, it may offer the following
possibility for the acknowledgement (Ack): a button positioned in an ergonomic location
on the driver’s desk.


5.4.1.1.1 Note: The location of the acknowledgement button onto the total image display area varies
depending on the object to be acknowledged. See chapter 8 for the specific area(s)
becoming the acknowledgement button.


5.4.1.1.2 Note: Depending on the situation, it may happen that a driver’s acknowledgement is
required but cannot be displayed yet ; see 5.4.1.9 and 5.4.1.11.


5.4.1.2 When using soft key technology, when a driver’s acknowledgement is required and can
be displayed, the ERTMS/ETCS DMI shall always offer an acknowledgement (Ack) via
the soft key H7 showing the symbol DR04. In addition, it may offer the following possibility
for the acknowledgement (Ack): a button positioned on an ergonomic location on the
driver’s desk.


5.4.1.3 Unless stated otherwise, the Ack-button shall be an up-type button.


5.4.1.4 When using touch screen technology, the area displaying the related object or text
message shall become the Ack-button.


5.4.1.5 When a driver’s acknowledgement is displayed, a yellow flashing frame shall be used to
surround the related object or text message and sound Sinfo (see chapter 14) shall be
played.


5.4.1.6 When using soft key technology, an additional frame around H7 (i.e. the ‘Ack’ label) shall
also flash.


5.4.1.6.1 Note: in the soft key technology, 2 flashing frames are displayed.


5.4.1.7 Only one request for Acknowledgement (Ack) at any given time shall be presented to the
driver.


5.4.1.8 As soon as the current object or text message has been acknowledged, the Ack-button
and the yellow flashing frame(s) related to this object or text message shall disappear.


5.4.1.9 If there is more than one object or text message for which a driver’s acknowledgement is
required, they shall be managed according to a FIFO principle with a delay of 1 sec
between their display i.e. the next object or text message and its related request of
Acknowledgement shall be displayed 1 second after the current object or text message
has been acknowledged or revoked.


5.4.1.9.1 In case several driver acknowledgement requests for objects or text messages are
triggered simultaneously, they shall be included in the FIFO queue as if they were received
in the following sequence:


1) Acknowledgement request for level transition


2) Acknowledgement request for mode change


Version 4.0.0 PAGE 28 OF 317


**ERA ERTMS unit**

**ETCS Driver Machine Interface**


3) Acknowledgement request for fixed text message from trackside


4) Acknowledgement request for plain text message from trackside


5) Acknowledgement request for system status messages


6) Acknowledgement request to release a brake


7) Acknowledgement request for NTC text messages


5.4.1.10 The ERTMS/ETCS DMI shall display text messages that do not have to be acknowledged
only when the FIFO list does not contain any text message(s) which has to be
acknowledged (see 8.2.3.4 for details about display of text messages).


5.4.1.11 If a driver’s acknowledgement is required when a data entry window is displayed, see
11.7.1.8 and 11.7.1.9.


**5.5** **Languages**


5.5.1.1 The ERTMS/ETCS DMI shall be able to display text in all languages pre-configured
onboard.


5.5.1.2 In addition to the settings menu allowing access to the language window (see chapter
11.2.4), the ERTMS/ETCS DMI may offer the following possibility to access it: a button
positioned on an ergonomic location on the driver’s desk.


5.5.1.3 The text labels displayed on buttons, text messages (except plain text messages given
from trackside), the window titles and text labels for the input fields, the echo texts and
the data view items shall be displayed in the selected language.


**5.6** **Isolation**


5.6.1.1 The ERTMS/ETCS DMI shall offer a means to isolate the ERTMS/ETCS on-board
equipment.


5.6.1.1.1 Note: The location and form of this are implementation dependent.


Version 4.0.0 PAGE 29 OF 317


**ERA ERTMS unit**

**ETCS Driver Machine Interface**

