##### **10. SUB-LEVEL WINDOWS – GENERAL REQUIREMENTS**


**10.1** **Introduction**


10.1.1.1 All figures provided in chapter 10 are only used to show the layout of the sub-level
windows for explanatory reasons.


**10.2** **Menu windows**


**10.2.1** **Menu windows for touch screen technology**


10.2.1.1 The window shall be in the D/F/G area.


10.2.1.2 Each object shall follow the dimension and position as specified in Table 20.


10.2.1.3 The buttons 1, 2,.. shall be up-type buttons.

|Menu window|Col2|Col3|Col4|Col5|
|---|---|---|---|---|
|**_Item_**|**_Width_**|**_ Height_**|**_X Location_**|**_Y Location_**|
|Window Title|306|24|0|0|
|‘close’ button|82|50|0|400|
|Button 1|153|50|0|50|
|Button 2|153|50|153|50|
|Button 3|153|50|0|100|
|Button 4|153|50|153|100|
|…|…|…|…|…|



**Table 20 – Menu window (touch screen technology)**


10.2.1.4 Figure 95 gives an example of the layout of a menu window containing 8 buttons with the
7 [th] and 8 [th] in state ‘disabled’ (i.e. in dark grey).

|Col1|Col2|Col3|Col4|
|---|---|---|---|
|||Window Title|Window Title|
|||||
|||Button 1|Button 2|
|||Button 3|Button 4|
|||Button 5|Button 6|
|||Button 7|Button 8|
|||||
|||||
|||||
|||||
|||||



**Figure 95 – Menu window (touch screen technology)**


Version 4.0.0 PAGE 140 OF 317


**ERA ERTMS unit**

**ETCS Driver Machine Interface**


**10.2.2** **Menu windows for soft key technology**


10.2.2.1 The [Close] button shall be in H3.


10.2.2.2 The window shall contain a list of maximum 10 selections (texts) in area D/G/I.


10.2.2.3 The list of selections shall be displayed left aligned with an indent of 15 cells from the left
of the area D/G/I.


10.2.2.4 The first selection of the list shall be 112 cells (i.e. an indent of 100 cells + the 12 cells of
the character size) below the top of area D/G/I.


10.2.2.5 The text of each selection shall:

a) start with a number giving the position of the selection in the list ;

b) identify the name of the selection ;

c) separate the number and the name of the selection by a ‘-‘ and 1 space on each side

of the dash.


10.2.2.6 The numbers used for the selections shall be positioned in an ascending order.


10.2.2.6.1 When more than 10 selections exist for a menu window, 10.2.2.3 to 6 shall apply for each

group of maximum 9 selections and F10 shall be dedicated to the [More] button. When
pressing the [More] button, the next (maximum) 9 selections shall be presented but with
the numbers adapted accordingly (e.g. going respectively from 10 to maximum 18 for the
next 9 selections). The list of selections shall be circular i.e. the 1 [st] group of selections
(from 1 to 9) follows the last group of selections.


10.2.2.7 Example of a selection: “1 – Train data”.


10.2.2.8 The labels of the F buttons shall be numbers matching the numbers of the selections.


10.2.2.9 The F buttons shall be up-type buttons.


10.2.2.10 Figure 96 gives an example of the layout of a menu window containing 5 selections with

the 4 [th] and 5 [th] selections in state ‘disabled’.


Version 4.0.0 PAGE 141 OF 317


**ERA ERTMS unit**

**ETCS Driver Machine Interface**

|Window Title<br>1 – selection #1<br>2 – selection #2<br>3 – selection #3<br>4 – selection #4<br>5 – selection #5<br>1 2 3 4 5|Col2|Col3|Col4|Col5|
|---|---|---|---|---|
|1 – selection #1<br>2 – selection #2<br>3 – selection #3<br>4 – selection #4<br>5 – selection #5<br>1<br>5<br>4<br>3<br>2<br>Window Title|1 – selection #1<br>2 – selection #2<br>3 – selection #3<br>4 – selection #4<br>5 – selection #5<br>1<br>5<br>4<br>3<br>2<br>Window Title|1 – selection #1<br>2 – selection #2<br>3 – selection #3<br>4 – selection #4<br>5 – selection #5<br>1<br>5<br>4<br>3<br>2<br>Window Title|1 – selection #1<br>2 – selection #2<br>3 – selection #3<br>4 – selection #4<br>5 – selection #5<br>1<br>5<br>4<br>3<br>2<br>Window Title||
|1 – selection #1<br>2 – selection #2<br>3 – selection #3<br>4 – selection #4<br>5 – selection #5<br>1<br>5<br>4<br>3<br>2<br>Window Title|1 – selection #1<br>2 – selection #2<br>3 – selection #3<br>4 – selection #4<br>5 – selection #5<br>1<br>5<br>4<br>3<br>2<br>Window Title|1 – selection #1<br>2 – selection #2<br>3 – selection #3<br>4 – selection #4<br>5 – selection #5<br>1<br>5<br>4<br>3<br>2<br>Window Title|1 – selection #1<br>2 – selection #2<br>3 – selection #3<br>4 – selection #4<br>5 – selection #5<br>1<br>5<br>4<br>3<br>2<br>Window Title||
|1|2|3|4|4|



**Figure 96 – Menu window (soft key technology)**


**10.2.3** **Layers**


10.2.3.1 The layers for menu windows shall be as follows:

a) Layer 0: D/F/G (touch screen technology) or D/G/I (soft key technology)

b) All other areas: same as default window (see 8.1.1.4)


**10.3** **Data entry windows**


**10.3.1** **Input fields**


10.3.1.1 An input field shall be used to allow the driver to enter data.


10.3.1.2 The height of the total input field shall be 50 cells.


10.3.1.3 When using the touch screen technology, the width of the total input field shall be 306
cells.


10.3.1.3.1 For touch screen technology, the input fields will be located on the D/F/G area (having a

width of 306 cells).


10.3.1.4 When using the soft key technology, the width of the total input field shall be 266 cells.


10.3.1.4.1 For soft key technology, the input fields will be located on the D/G/I area (having a width

of 266 cells).


10.3.1.5 Each input field shall be divided into a label area and a data area.


10.3.1.6 The label area shall give the topic of the input field.


10.3.1.7 Exception: If there is only one input field within the window, the input field can only consist
of a data area.


Version 4.0.0 PAGE 142 OF 317


**ERA ERTMS unit**

**ETCS Driver Machine Interface**


10.3.1.7.1 Note: With a single input field, the window title can already indicate unambiguously the

topic of the input field.


10.3.1.8 When the input field contains a label area, the width of the data area shall be 102 cells.


10.3.1.9 The label area shall be placed to the left of the data area.


10.3.1.10 The text in the label area shall be aligned to the right of the label area with an indent of 10

cells.


10.3.1.11 The value of the data in the data area shall be aligned to the left of the data area with an

indent of 10 cells.


10.3.1.12 The text colour of the label area shall be grey; the background colour of the label area

shall be dark grey.


10.3.1.13 If the input field is not selected and no data value has been accepted yet by the driver

during the data entry / validation process (i.e. ‘not selected’ state), the background colour
of the data area shall be dark grey and, if any, the data value colour shall be grey.


10.3.1.13.1 Note: regarding the definition of a data entry / validation process; see chapter 10.6.


10.3.1.14 If the input field is selected (i.e. ‘selected’ state), the background colour of the data area

shall be medium grey and the colour of the data value or of the value corresponding to
the pressed key(s) (see 10.3.1.19) shall be black.


10.3.1.15 If the input field is not selected but a data value has already been accepted by the driver

during the data entry / validation process (i.e. ‘accepted’ state), the background colour of
the data area shall be dark grey and the the data value colour shall be white.


10.3.1.16 Table 21 gives an overview of the data field states.












|Col1|Not selected|Selected|Accepted|
|---|---|---|---|
|Background of the<br>data area|dark grey|medium grey|dark grey|
|Data value|grey|black|white|
|Value corresponding<br>to the pressed key(s)<br>(see 10.3.1.19)|-|black|-|



**Table 21 – Overview of data field states**


10.3.1.17 Figure 97 gives an overview of the colour philosophy for an input field during a data entry

/ validation process.


Version 4.0.0 PAGE 143 OF 317


**ERA ERTMS unit**

**ETCS Driver Machine Interface**


DATA INPUT FIELD COLOUR DEPENDING ON DATA FIELD STATE



































Data accepted


**Figure 97 – State transitions for an input field with colour philosophy**


10.3.1.18 When an input field is selected, the associated keyboard shall be presented in the area

below the area of the input field(s).


10.3.1.19 After the first press on a data key of the associated keyboard, the value corresponding to

the pressed data key shall be displayed in the data area instead of the data value (if any)
of the selected input field.


10.3.1.20 If the input field is not selected anymore whilst a value has been entered / modified without

accepting it, the entered value shall be erased from the data area and the current data
value (if any) shall be deleted.


10.3.1.21 To accept the entered value in an input field in order that it replaces the current data value

(if any), the driver shall activate the associated [Enter] button.


10.3.1.22 When using the touch screen technology, the associated [Enter] button shall be the data

field itself.


10.3.1.23 When a data entry / validation process starts, the first input field shall be in the ‘selected’

state, all other input fields shall be in the ‘not selected’ state.


Version 4.0.0 PAGE 144 OF 317


**ERA ERTMS unit**

**ETCS Driver Machine Interface**


10.3.1.24 After activating the [Enter] button associated to the selected input field, this input field shall

go to the ‘accepted’ state and the next input field related to the same topic (i.e. which can
be on a next data entry window) shall be selected automatically.


10.3.1.25 The list of input fields of the data entry window(s) related to the same topic shall be circular

i.e. the first input field follows the last one and the last input field preceeds the first one.


10.3.1.26 When using the touch screen technology, it shall be possible for the driver to select a

specific input field by activating the input field area (the label or data part). For the
activation, the input field shall behave like an up-type button.


10.3.1.27 When using soft key technology, it shall be possible for the driver to select a specific input

field by using the [Up] and [Down] scroll buttons.


**10.3.2** **Entering characters**


10.3.2.1 A cursor shall be used to indicate to the driver where his next selected character will be
inserted within the input field.


10.3.2.2 The cursor shall be a horizontal line below the position of the next character to be entered
i.e. an underscore.


10.3.2.3 The cursor shall flash by changing from visible to not visible (e.g. background colour) with
a nominal frequency of 2 Hz with a symmetrical mark space ratio.


10.3.2.4 When a data key of a keyboard allows entering one single character (e.g. all data keys of
a numeric keyboard), the cursor shall jump to the next position in the input field as soon
as this data key entry is echoed within the input field.


10.3.2.5 When a data key of a keyboard allows entering various characters (e.g. all data keys of
an alphanumeric keyboard), the following shall apply:

a) the cursor shall jump automatically with a delay-time of 2 s to the next position in the

input field after displaying this data key entry within the input field.

b) by pressing the same data key again within these 2 s delay-time or by holding the data

key for some time, another character under the same data key shall be selected;

c) by pressing another data key within these 2 s delay-time the cursor shall be forced to

jump to the next position in the input field directly.


10.3.2.6 The rules specified in 5.1.5 shall apply as soon as the 6 [th] character of an alphanumeric or
numeric data is entered.


**10.3.3** **Echo texts**


10.3.3.1 An echo text shall be composed of a label part and a data part.


10.3.3.2 The label part shall be identical to the label of the concerned input field.


10.3.3.3 The data part of the echo text shall display the data value of the concerned input field.


10.3.3.4 Exception: If the data value is not consistent, the data part of the echo text shall indicate
the type of inconsistency as specified in 10.3.4 instead of the data value.


Version 4.0.0 PAGE 145 OF 317


**ERA ERTMS unit**

**ETCS Driver Machine Interface**


10.3.3.5 The echo text shall be white if the entered data has been accepted by the driver during
the data entry / validation process, otherwise it shall be grey.


10.3.3.6 The echo texts shall be presented inside the A/B/C/E area in the same order as their
related input fields in D/F/G (touch screen technology) or D/G/I (soft key technology).


10.3.3.7 The labels of the echo texts shall be right aligned with an indent of 5 on the left side of the
X position 204.


10.3.3.8 The label of the first echo text shall be 112 cells (i.e. an indent of 100 cells + the 12 cells
of the character size) below the top of area A/B/C/E.


10.3.3.9 The data of the echo texts shall be left aligned with an indent of 5 cells on the right side
of the X position 204.


10.3.3.10 The data of the first echo text shall be 112 cells (i.e. an indent of 100 cells + the 12 cells

of the character size) below the top of area A/B/C/E.


**10.3.4** **Data checks**


**10.3.4.1** **Introduction**


10.3.4.1.1 This chapter defines the mechanisms used to inform the driver about data entry mistakes.

For that purpose, five types of checks are defined:

a) Technical range check used when the value of an input field is out of its technical

range (e.g. outside the range defined in document [2], section A.3.11),

b) Technical resolution check used when the value of an input field is not matching its

resolution (e.g. different from the resolution defined in document [2], section A.3.11)

c) Technical cross-check used when the values of several input fields do not technically

fit together,

d) Operational range check used when the value of an input field is out of its operational

range (e.g. outside the range used for the nominal operational situations),

e) Operational cross-check used when the values of several input fields do not

operationally fit together.


10.3.4.1.1.1 Note: The main difference between the technical and operational rules is that an
operational one can be overruled by the driver while a technical one forces him to
modify the data value(s).


10.3.4.1.2 It shall be possible to configure in the on-board the permitted range(s), resolution for a

specific input field as well as the cross-check rules between several input fields. However,
the definitions of those rules are outside the scope of this specification.


10.3.4.1.3 Since these mechanisms rely on the echo texts, it is only possible to inform the driver

about data entry mistakes in data entry windows with echo texts.


**10.3.4.2** **Technical range checks**


10.3.4.2.1 The check versus the technical permitted range shall take place when an entered data

value is accepted by the driver.


Version 4.0.0 PAGE 146 OF 317


**ERA ERTMS unit**

**ETCS Driver Machine Interface**


10.3.4.2.2 When the entered data value of an input field is outside its pre-configured technical

permitted range, the data part of its echo text shall indicate ‘++++’ in red.


10.3.4.2.3 The input field that contains the out of range shall remain in the “Selected IF/data value”

state (see Figure 97) and shall still show the entered data value.


10.3.4.2.4 The [Enter] button and, if any, the [Up], [Down], [Next] and [Previous] navigation buttons

shall be disabled until the state of the input field switches to “Selected IF/value of pressed
key(s)”.


**10.3.4.3** **Technical resolution checks**


10.3.4.3.1 The check versus the technical resolution shall take place when an entered data value is

accepted by the driver.


10.3.4.3.2 When an entered data value of an input field is outside its pre-configured technical

resolution, the data part of its echo text shall indicate ‘++++’ in red.


10.3.4.3.3 The input field that contains the wrong resolution shall remain in the “Selected IF/data

value” state (see Figure 97) and shall still show the entered data value.


10.3.4.3.4 The [Enter] button and, if any, the [Up], [Down], [Next] and [Previous] navigation buttons

shall be disabled until the state of the input field switches to “Selected IF/value of pressed
key(s)”.


**10.3.4.4** **Technical cross-checks**


10.3.4.4.1 When a valid button activation is performed on the ‘Yes’ button attached to the question

‘[Window Title] entry complete?’ (see 10.3.4.5 and 10.3.6), the technical cross-check rules
shall be executed in sequence.


10.3.4.4.2 For the input fields whose entered data values do not comply with the currently executed

cross-check rule, the data part of their corresponding echo texts shall indicate ‘????’ in
red.


10.3.4.4.3 The input fields not complying with the cross-check rule shall still show their entered data

value.


10.3.4.4.4 The ‘Yes’ button attached to the question ‘[Window Title] entry complete?’ shall be

disabled until one of the entered data values is modified i.e. until one of the input field
switches to “Not Selected IF/Accepted Data value” (see Figure 97).


**10.3.4.5** **Operational range checks**


10.3.4.5.1 The check versus the operational permitted range shall take place when an entered data

value is accepted by the driver and only if the technical range check, if any, is satisfied.


10.3.4.5.2 When the entered data value of the input field is outside its pre-configured operational

range, the data part of its echo text shall indicate ‘++++’ in yellow.


10.3.4.5.3 The input field that contains the operational out of range shall remain in the“Selected

IF/data value” state (see Figure 97) and shall still show the entered data value.


Version 4.0.0 PAGE 147 OF 317


**ERA ERTMS unit**

**ETCS Driver Machine Interface**


10.3.4.5.4 If any, the [Up], [Down], [Next] and [Previous] navigation buttons shall be disabled until

the state of the input field switches to “Selected IF/value of pressed key(s)”.


10.3.4.5.5 The [Enter] button shall become a delay-type button to allow the driver to overrule the

operational range check rule.


10.3.4.5.6 If the driver performs a valid button activation on the delay-type [Enter] button, the entered

data value of the input field shall be considered as permitted meaning that the input field
shall go in the “Not Selected IF/Accepted Data value” state and the data part of the echo
text shall display the entered data value instead of ‘++++’ .


**10.3.4.6** **Operational cross-checks**


10.3.4.6.1 When a valid button activation is performed on the ‘Yes’ button attached to the question

‘[Window Title] entry complete?’ (see 10.3.4.5 and 10.3.6), the operational cross-check
rules shall be executed in sequence and only if all technical cross-check(s) is/are satisfied.


10.3.4.6.2 For the input fields whose entered data values do not comply with the currently executed

cross-check rule, the data part of their corresponding echo texts shall indicate ‘????’ in
yellow.


10.3.4.6.3 The input fields not complying with the cross-check rule shall still show their entered data

value.


10.3.4.6.4 The ‘Yes’ button attached to the question ‘[Window Title] entry complete?’ shall become

a delay-type button to allow the driver to overrule the operational cross-check rule.


10.3.4.6.5 If the driver performs a valid button activation on the delay-type ‘Yes’ button, the entered

data values of the input fields concerned by the cross-check rule shall be considered as
permitted and the data part of the corresponding echo texts shall display the entered data
values instead of ‘????’.


**10.3.4.7** **Sequence of data checks**


10.3.4.7.1 The sequence of data checks shall follow the process in Figure 98.


Version 4.0.0 PAGE 148 OF 317


**ERA ERTMS unit**

**ETCS Driver Machine Interface**

































































**Figure 98 – Sequence of data checks**


**10.3.5** **Data entry window for touch screen technology**


10.3.5.1 A data entry window shall contain a maximum of 4 input fields if it covers the total grid
array (i.e. A/B/C/D/E/F/G) or only one input field if it covers the half grid array (i.e. D/F/G).


Version 4.0.0 PAGE 149 OF 317


**ERA ERTMS unit**

**ETCS Driver Machine Interface**


10.3.5.1.1 Note: the number of input fields is limited to be able to present a keyboard with 12 keys

below the last input field.


10.3.5.2 When the window covers the half grid array (D/F/G areas), each object (excluding the
keyboard keys) shall follow the dimension and position as specified in Table 22.

|Data entry window<br>on half grid array|Col2|Col3|Col4|Col5|
|---|---|---|---|---|
|**_Item_**|**_Width_**|**_ Height_**|**_X Location_**|**_Y Location_**|
|‘Close’ button|82|50|0|400|
|‘Previous’ button (when<br>several windows<br>containing input fields<br>related to the same topic<br>exists)|82|50|82|400|
|‘Next’ button (when<br>several windows<br>containing input fields<br>related to the same topic<br>exists)|82|50|164|400|
|Window Title|306|24|0|0|
|Input field 1 (label part)|204|50|0|50|
|Input field 1 (data part)|102|50|204|50|



**Table 22 – Data entry window on half grid array (touch screen technology)**


10.3.5.3 When the window covers the A/B/C/D/E/F/G areas, each object (excluding the keyboard
keys, the echo texts and the objects for ‘data entry complete’) shall follow the dimension
and position as specified in Table 23.

|Data entry window<br>on total grid array|Col2|Col3|Col4|Col5|
|---|---|---|---|---|
|**_Item_**|**_Width_**|**_ Height_**|**_X Location_**|**_Y Location_**|
|‘Close’ button|82|50|334|400|
|‘Previous’ button (when<br>several windows<br>containing input fields<br>related to the same topic<br>exists)|82|50|416|400|
|‘Next’ button (when<br>several windows<br>containing input fields<br>related to the same topic<br>exists)|82|50|498|400|
|Window Title|334|24|0|0|
|Input field 1 (label part)|204|50|334|50|
|Input field 1 (data part)|102|50|538|50|
|Input field 2 (label part)|204|50|334|100|
|Input field 2 (data part)|102|50|538|100|
|Input field 3 (label part)|204|50|334|150|
|Input field 3 (data part)|102|50|538|150|
|Input field 4 (label part)|204|50|334|200|
|Input field 4 (data part)|102|50|538|200|



Version 4.0.0 PAGE 150 OF 317


**ERA ERTMS unit**

**ETCS Driver Machine Interface**


**Table 23 – Data entry window on total grid array (touch screen technology)**


10.3.5.4 When the window covers the total grid array (A/B/C/D/E/F/G areas), the text label of the
window title shall be right aligned.


10.3.5.5 If the window contains only one input field and only the data part is presented (see
10.3.1.7), the dimension of the data part shall be the dimension of the merged area
between input field 1 (label area) and input field 1 (data area) as expressed in Table 22
and Table 23.


10.3.5.6 When the window covers the total grid array (A/B/C/D/E/F/G areas), it shall be possible to
echo the values of the input fields on the A/B/C/E area applying the requirements in 10.3.3.


10.3.5.7 When the window covers the total grid array (A/B/C/D/E/F/G areas), the objects specified
in Table 24 shall additionally be presented on the window for confirmation by the driver of
the data entry completion.

|Data entry complete|Col2|Col3|Col4|Col5|
|---|---|---|---|---|
|**_Item_**|**_Width_**|**_ Height_**|**_X Location_**|**_Y Location_**|
|area for ‘[Window Title]<br>entry complete?’|334|50|0|350|
|‘Yes’ button|334|50|0|400|



**Table 24 – Data entry complete objects (touch screen technology)**


10.3.5.8 The sensitive area of the ‘Yes’ button shall be extended on the area for the ‘[Window Title]
entry complete?’ (see Table 24).


10.3.5.9 The ‘Yes’ button shall be enabled when all input fields related to the topic of the window(s)
display a data value (displaying a value corresponding to pressed key(s) is not displaying
a data value, for further details see Figure 97). Otherwise the ‘Yes’ button shall be
disabled.


10.3.5.10 The text label of the ‘Yes’ button shall be in black. The background colour shall be in dark

grey if the ‘Yes’ button is disabled or in medium grey if it is enabled. The ‘Yes’ button shall
have the same border as an input field applying 5.1.1.1.4.


10.3.5.11 The ‘Yes’ button shall be an up-type button.


10.3.5.12 Depending on the selected input field, the window shall present the corresponding

keyboard which can be numeric, enhanced numeric, alphanumeric or a dedicated
keyboard with predefined choices.


10.3.5.13 The buttons of the keyboard shall be down-type buttons.


10.3.5.14 Each button of the keyboard shall follow the dimension and position in the D/F/G area as

specified in Table 25 in order to be above the navigation buttons.

|Keyboard|Col2|Col3|Col4|Col5|
|---|---|---|---|---|
|**_Item_**|**_Width_**|**_ Height_**|**_ X Location_**|**_  Y Location_**|
|Keyboard key ‘1’|102|50|0|200|
|Keyboard key ‘2’|102|50|102|200|



Version 4.0.0 PAGE 151 OF 317


**ERA ERTMS unit**

**ETCS Driver Machine Interface**

|Keyboard key ‘3’|102|50|204|200|
|---|---|---|---|---|
|Keyboard key ‘4’|102|50|0|250|
|Keyboard key ‘5’|102|50|102|250|
|Keyboard key ‘6’|102|50|204|250|
|Keyboard key ‘7’|102|50|0|300|
|Keyboard key ‘8’|102|50|102|300|
|Keyboard key ‘9’|102|50|204|300|
|Keyboard key ‘10|102|50|0|350|
|Keyboard key ‘11’|102|50|102|350|
|Keyboard key ‘12’<br>...|102<br>...|50<br>...|204<br>...|350<br>...|



**Table 25 – Keyboard (touch screen technology)**


10.3.5.15 When a numeric keyboard is presented, the keys 1 to 11 shall respectively contain

enabled buttons for the numbers ‘1’ to ‘9’, the [delete] and the number ‘0’. The key 12 shall
show the ‘.’ button as disabled.


10.3.5.16 When an enhanced numeric keyboard is presented, the keys 1 to 12 shall respectively

contain enabled buttons for the numbers ‘1’ to ‘9’, the [delete], the number ‘0’ and the ‘.’
button.


10.3.5.17 When an alphanumeric keyboard is presented, the keys 1 to 11 shall respectively contain

enabled buttons for the alphanumeric characters 1, 2/a/b/c,…, 9/w/x/y/z, the [delete], the
number ‘0’. The key 12 shall show the ‘.’ button as disabled. The labels of the keys shall
separate the number from the letters with a space character e.g. ‘2 abc’.


10.3.5.18 When a dedicated keyboard is limited to a ‘No’/’Yes’ choice, the key ‘7’ shall be the ‘No’

key and the key ‘8’ shall be the ‘Yes’ key.


10.3.5.19 When more than 12 predefined choices exist for a dedicated keyboard, the key 12 shall

be dedicated to the [More] button. When pressing the [More] button, the keys 1 to 11 shall
respectively contain enabled buttons for the next (maximum) 11 predefined choices. The
list of predefined choices shall be circular i.e. the 1 [st] group of predefined choices (from 1
to 11) follows the last group of predefined choices.


10.3.5.20 Figure 99 gives the layout of a data entry window with a single input field without label

part on the half grid array.


Version 4.0.0 PAGE 152 OF 317


**ERA ERTMS unit**

**ETCS Driver Machine Interface**







|Key ‘1’|Col2|Col3|
|---|---|---|
|Key ‘4’<br>Key ‘7’|Key ‘4’<br>Key ‘7’|Key ‘6’|
|Key ‘4’<br>Key ‘7’|Key ‘8’|Key ‘9’|
|Key ‘10’|Key ‘11’|Key ‘11’|
||||


**Figure 99 – Data entry window on half grid array (touch screen technology)**


10.3.5.21 Figure 100 gives the layout of a data entry window with 4 input fields covering the total

grid array including echo texts, a request for ‘[Window Title] entry complete?’, a ‘Previous’
and a ‘Next’ button to scroll between the windows related to the same topic.










|Col1|Col2|Col3|Col4|Col5|Col6|Col7|
|---|---|---|---|---|---|---|
|Window Title (x/y)|Label 1|Label 1|Label 1|Label 1|Data 1|Data 1|
|[Window Title] entry complete?<br>Label 1<br>Label 2<br>Label 3<br>Label 4<br>Label 5<br>…<br>Data 1<br>Data 2<br>Data 3<br>Data 4<br>Data 5<br>...|[Window Title] entry complete?<br>Label 1<br>Label 2<br>Label 3<br>Label 4<br>Label 5<br>…<br>Data 1<br>Data 2<br>Data 3<br>Data 4<br>Data 5<br>...|[Window Title] entry complete?<br>Label 1<br>Label 2<br>Label 3<br>Label 4<br>Label 5<br>…<br>Data 1<br>Data 2<br>Data 3<br>Data 4<br>Data 5<br>...|[Window Title] entry complete?<br>Label 1<br>Label 2<br>Label 3<br>Label 4<br>Label 5<br>…<br>Data 1<br>Data 2<br>Data 3<br>Data 4<br>Data 5<br>...|[Window Title] entry complete?<br>Label 1<br>Label 2<br>Label 3<br>Label 4<br>Label 5<br>…<br>Data 1<br>Data 2<br>Data 3<br>Data 4<br>Data 5<br>...|[Window Title] entry complete?<br>Label 1<br>Label 2<br>Label 3<br>Label 4<br>Label 5<br>…<br>Data 1<br>Data 2<br>Data 3<br>Data 4<br>Data 5<br>...|[Window Title] entry complete?<br>Label 1<br>Label 2<br>Label 3<br>Label 4<br>Label 5<br>…<br>Data 1<br>Data 2<br>Data 3<br>Data 4<br>Data 5<br>...|
|[Window Title] entry complete?<br>Label 1<br>Label 2<br>Label 3<br>Label 4<br>Label 5<br>…<br>Data 1<br>Data 2<br>Data 3<br>Data 4<br>Data 5<br>...|Label 2|Label 2|Label 2|Label 2|Data 2|Data 2|
|[Window Title] entry complete?<br>Label 1<br>Label 2<br>Label 3<br>Label 4<br>Label 5<br>…<br>Data 1<br>Data 2<br>Data 3<br>Data 4<br>Data 5<br>...|Label 3|Label 3|Label 3|Label 3|Data 3|Data 3|
|[Window Title] entry complete?<br>Label 1<br>Label 2<br>Label 3<br>Label 4<br>Label 5<br>…<br>Data 1<br>Data 2<br>Data 3<br>Data 4<br>Data 5<br>...|Label 4|Label 4|Label 4|Label 4|Data 4|Data 4|
|[Window Title] entry complete?<br>Label 1<br>Label 2<br>Label 3<br>Label 4<br>Label 5<br>…<br>Data 1<br>Data 2<br>Data 3<br>Data 4<br>Data 5<br>...|Key ‘1’|Key ‘1’|Key ‘2’|Key ‘2’|Key ‘3’|Key ‘3’|
|[Window Title] entry complete?<br>Label 1<br>Label 2<br>Label 3<br>Label 4<br>Label 5<br>…<br>Data 1<br>Data 2<br>Data 3<br>Data 4<br>Data 5<br>...|Key ‘4’|Key ‘4’|Key ‘5’|Key ‘5’|Key ‘6’|Key ‘6’|
|[Window Title] entry complete?<br>Label 1<br>Label 2<br>Label 3<br>Label 4<br>Label 5<br>…<br>Data 1<br>Data 2<br>Data 3<br>Data 4<br>Data 5<br>...|Key ‘7’|Key ‘7’|Key ‘8’|Key ‘8’|Key ‘9’|Key ‘9’|
|[Window Title] entry complete?<br>Label 1<br>Label 2<br>Label 3<br>Label 4<br>Label 5<br>…<br>Data 1<br>Data 2<br>Data 3<br>Data 4<br>Data 5<br>...|Key ‘10’|Key ‘10’|Key ‘11’|Key ‘11’|Key ‘12’|Key ‘12’|
|YES|||||||
||||||||



**Figure 100 – Data entry window with 4 input fields on total grid array (touch screen technology)**


**10.3.6** **Data entry window for soft key technology**


Version 4.0.0 PAGE 153 OF 317


**ERA ERTMS unit**

**ETCS Driver Machine Interface**


10.3.6.1 A Data entry window shall contain a maximum of 4 input fields if it covers the total grid
array (i.e. A/B/C/D/E/G/I) or only one input field if it covers the half grid array (i.e. D/G/I).


10.3.6.1.1 Note: the number of input fields is limited to be able to present a dedicated keyboard

below the last input field.


10.3.6.2 When the window covers the half grid array (D/G/I areas), each object (excluding the
keyboard keys) shall follow the dimension and position as specified in Table 26.

|Data entry window<br>on half grid array|Col2|Col3|Col4|Col5|
|---|---|---|---|---|
|**_Item_**|**_Width_**|**_ Height_**|**_X Location_**|**_Y Location_**|
|Window Title|266|24|0|0|
|Input field 1 (label part)|164|50|0|50|
|Input field 1 (data part)|102|50|164|50|



**Table 26 – Data entry window on half grid array (soft key technology)**


10.3.6.3 When the window covers the total grid array (A/B/C/D/E/G/I areas), each object (excluding
the keyboard keys, the echo texts and the objects for ‘data entry complete’) shall follow
the dimension and position as specified in Table 27.

|Data entry window<br>on total grid array|Col2|Col3|Col4|Col5|
|---|---|---|---|---|
|**_Item_**|**_Width_**|**_ Height_**|**_X Location_**|**_Y Location_**|
|Window Title|334|24|0|0|
|Input field 1 (label part)|164|50|334|50|
|Input field 1 (data part)|102|50|498|50|
|Input field 2 (label part)|164|50|334|100|
|Input field 2 (data part)|102|50|498|100|
|Input field 3 (label part)|164|50|334|150|
|Input field 3 (data part)|102|50|498|150|
|Input field 4 (label part)|164|50|334|200|
|Input field 4 (data part)|102|50|498|200|



**Table 27 – Data entry window on total grid array (soft key technology)**


10.3.6.4 If the window contains only one input field and only the data part is presented (see
10.3.1.7), the dimension of the data part shall be the dimension of the merged area
between input field 1 (label area) and input field 1 (data area) as expressed in Table 26
and Table 27.


10.3.6.5 When the window covers the total grid array (A/B/C/D/E/G/I areas), the text label of the
window title shall be right aligned.


10.3.6.6 When no previous window containing input fields related to the same topic exists, the

[Close] button shall be in H3.


10.3.6.7 When a previous window containing input fields related to the same topic exists, the

[Previous] button shall be in H3.


Version 4.0.0 PAGE 154 OF 317


**ERA ERTMS unit**

**ETCS Driver Machine Interface**


10.3.6.8 When a next window containing input fields related to the same topic exists, the [Next]
button shall be in H4.


10.3.6.9 When a window contains more than one input field or the ‘Yes’ button is enabled (see
10.3.6.13) or the ‘switch’ button is enabled (see 11.3.9.7), The [Up] and [Down] buttons
shall be respectively in H5 and H6.


10.3.6.10 The [Enter] button shall be in H7.


10.3.6.11 When the window covers the total grid array (A/B/C/D/E/G/I areas), it shall be possible to

echo the values of the input fields on the A/B/C/E area applying the requirements in 10.3.3.


10.3.6.12 When the window covers the total grid array (A/B/C/D/E/G/I areas), the objects specified

in Table 28 shall additionally be presented on the window for confirmation by the driver of
the data entry completion.

|Data entry complete|Col2|Col3|Col4|Col5|
|---|---|---|---|---|
|**_Item_**|**_Width_**|**_ Height_**|**_X Location_**|**_Y Location_**|
|area for ‘[Window Title]<br>entry complete?’|334|50|0|330|
|‘Yes’ button|334|50|0|380|



**Table 28 – Data entry complete objects (soft key technology)**


10.3.6.13 The ‘Yes’ button shall be enabled when all input fields related to the topic of the window(s)

display a data value (displaying a value corresponding to pressed key(s) is not displaying
a data value, for further details see Figure 97). Otherwise the ‘Yes’ button shall be
disabled.


10.3.6.14 The text label of the ‘Yes’ button shall be in black. The background colour shall be in dark

grey if the ‘Yes’ button is disabled or in medium grey if it is enabled. The ‘Yes’ button shall
have the same border as an input field applying 5.1.1.1.4.


10.3.6.15 When the ‘Yes’ button is enabled, an associated soft key with the label ‘Yes’ shall be

presented in F3 if the [Down] button has been pressed being on the last input field or if
the [Up] button has been pressed being on the first input field.


10.3.6.15.1 Note: the ‘Yes’ button is consequently inserted between the last and the first input fields

within the circular list of input fields (see 10.3.1.25).


10.3.6.16 Depending on the selected input field, the window shall present in area F/H the

corresponding keyboard which can be numeric, enhanced numeric, alphanumeric or a
dedicated keyboard with predefined choices.


10.3.6.17 The buttons of the keyboard shall be down-type buttons.


10.3.6.18 When a numeric keyboard is presented, the buttons F1 to F10 shall be used respectively

for the numbers 1, 2, …, 9 and 0.


10.3.6.19 When an enhanced numeric keyboard is presented (i.e. when a ‘.’ Is used), the buttons

F1 to F10 shall be used respectively for the numbers 1/’.’, 2, …, 9 and 0. The label of F1
shall separate the number 1 from the dot ‘.’ With a space character.


Version 4.0.0 PAGE 155 OF 317


**ERA ERTMS unit**

**ETCS Driver Machine Interface**


10.3.6.20 When an alphanumeric keyboard is presented, the buttons F1 to F10 shall be used

respectively for the alphanumeric characters 1, 2/a/b/c, …, 9/w/x/y/z and 0. The labels of
the keys shall separate the number from the letters with a space character e.g. ‘2 abc’.


10.3.6.21 When a numeric, an enhanced numeric or an alphanumeric keyboard is presented, H2

shall be used for the [Delete] button.


10.3.6.22 When a dedicated keyboard with predefined choices is presented, the following shall

apply:

a) The window shall contain a list of selections (texts) in area D/G/I.

b) The list shall be displayed left aligned with an indent of 15 cells from the left of the

area D/G/I.

c) The first selection of the list shall be 27 cells (i.e. an indent of 15 cells + the 12 cells

of the character size) below the position of the input field 3 (half grid array) or input
field 4 (total grid array).

d) The text of each selection shall:

      - start with a number or a letter giving the position of the selection in the list ;

      - identify the name/value of the selection ;

      - separate the number/letter and the name/value of the selection by a ‘-‘.

e) The numbers or letters used for the selections shall be positioned in a logical order

respectively from 1 to maximum 10 or from A to J ;

f) The labels of the F buttons shall be numbers/letters matching the numbers/letters of

the selection/value.


10.3.6.22.1 Exception: When a dedicated keyboard is limited to a ‘No’/’Yes’ choice, no list of selections

shall be presented in D/G/I area. F7 shall be the ‘No’ key and F8 shall be the ‘Yes’ key.


10.3.6.22.2 When more than 10 predefined choices exist for a dedicated keyboard, 10.3.6.22 shall

apply for each group of maximum 9 choices and F10 shall be dedicated to the [More]
button. When pressing the [More] button, the next (maximum) 9 predefined choices shall
be presented but with the numbers/letters adapted accordingly (e.g. going respectively
from 10 to maximum 18 or from J to maximum R for the next 9 choices). The list of
predefined choices shall be circular i.e. the 1 [st] group of predefined choices (from 1 to 9)
follows the last group of predefined choices.


10.3.6.23 Figure 101 gives an example of the layout of a data entry window on half grid array with

a numeric keyboard.


Version 4.0.0 PAGE 156 OF 317


**ERA ERTMS unit**

**ETCS Driver Machine Interface**

|Window Title<br>Data<br>1 2 3 4 5 6 7 8 9 0|Col2|Col3|Col4|Col5|
|---|---|---|---|---|
|8<br>1<br>0<br>9<br>7<br>6<br>5<br>4<br>3<br>2<br>Window Title<br>Data|8<br>1<br>0<br>9<br>7<br>6<br>5<br>4<br>3<br>2<br>Window Title<br>Data|8<br>1<br>0<br>9<br>7<br>6<br>5<br>4<br>3<br>2<br>Window Title<br>Data|8<br>1<br>0<br>9<br>7<br>6<br>5<br>4<br>3<br>2<br>Window Title<br>Data||
|8<br>1<br>0<br>9<br>7<br>6<br>5<br>4<br>3<br>2<br>Window Title<br>Data|8<br>1<br>0<br>9<br>7<br>6<br>5<br>4<br>3<br>2<br>Window Title<br>Data|8<br>1<br>0<br>9<br>7<br>6<br>5<br>4<br>3<br>2<br>Window Title<br>Data|8<br>1<br>0<br>9<br>7<br>6<br>5<br>4<br>3<br>2<br>Window Title<br>Data||
|8<br>1<br>0<br>9<br>7<br>6<br>5<br>4<br>3<br>2<br>Window Title<br>Data|8<br>1<br>0<br>9<br>7<br>6<br>5<br>4<br>3<br>2<br>Window Title<br>Data|8<br>1<br>0<br>9<br>7<br>6<br>5<br>4<br>3<br>2<br>Window Title<br>Data|8<br>1<br>0<br>9<br>7<br>6<br>5<br>4<br>3<br>2<br>Window Title<br>Data||
|8<br>1<br>0<br>9<br>7<br>6<br>5<br>4<br>3<br>2<br>Window Title<br>Data|8|9|0|0|



**Figure 101 – Data entry window on half grid array and a numeric keyboard (soft key technology)**


10.3.6.24 Figure 102 gives an example of the layout of a data entry window on half grid array with

a dedicated keyboard.

|Col1|Col2|Col3|Col4|Col5|Col6|Col7|Window Title|Col9|Col10|Col11|Col12|Col13|
|---|---|---|---|---|---|---|---|---|---|---|---|---|
||||||||||||||
||||||||Data|Data|Data|Data|Data|Data|
||||||||Data|Data|Data|Data|Data||
||||||||1 - Selection #1<br>2 - Selection #2<br>3 - Selection #3<br>4 - Selection #4<br>…..<br>10 - Selection #10|1 - Selection #1<br>2 - Selection #2<br>3 - Selection #3<br>4 - Selection #4<br>…..<br>10 - Selection #10|1 - Selection #1<br>2 - Selection #2<br>3 - Selection #3<br>4 - Selection #4<br>…..<br>10 - Selection #10|1 - Selection #1<br>2 - Selection #2<br>3 - Selection #3<br>4 - Selection #4<br>…..<br>10 - Selection #10|1 - Selection #1<br>2 - Selection #2<br>3 - Selection #3<br>4 - Selection #4<br>…..<br>10 - Selection #10|1 - Selection #1<br>2 - Selection #2<br>3 - Selection #3<br>4 - Selection #4<br>…..<br>10 - Selection #10|
||||||||1 - Selection #1<br>2 - Selection #2<br>3 - Selection #3<br>4 - Selection #4<br>…..<br>10 - Selection #10|1 - Selection #1<br>2 - Selection #2<br>3 - Selection #3<br>4 - Selection #4<br>…..<br>10 - Selection #10|1 - Selection #1<br>2 - Selection #2<br>3 - Selection #3<br>4 - Selection #4<br>…..<br>10 - Selection #10|1 - Selection #1<br>2 - Selection #2<br>3 - Selection #3<br>4 - Selection #4<br>…..<br>10 - Selection #10|1 - Selection #1<br>2 - Selection #2<br>3 - Selection #3<br>4 - Selection #4<br>…..<br>10 - Selection #10||
||||||||1 - Selection #1<br>2 - Selection #2<br>3 - Selection #3<br>4 - Selection #4<br>…..<br>10 - Selection #10|1 - Selection #1<br>2 - Selection #2<br>3 - Selection #3<br>4 - Selection #4<br>…..<br>10 - Selection #10|1 - Selection #1<br>2 - Selection #2<br>3 - Selection #3<br>4 - Selection #4<br>…..<br>10 - Selection #10|1 - Selection #1<br>2 - Selection #2<br>3 - Selection #3<br>4 - Selection #4<br>…..<br>10 - Selection #10|1 - Selection #1<br>2 - Selection #2<br>3 - Selection #3<br>4 - Selection #4<br>…..<br>10 - Selection #10||
||||||||1 - Selection #1<br>2 - Selection #2<br>3 - Selection #3<br>4 - Selection #4<br>…..<br>10 - Selection #10|1 - Selection #1<br>2 - Selection #2<br>3 - Selection #3<br>4 - Selection #4<br>…..<br>10 - Selection #10|1 - Selection #1<br>2 - Selection #2<br>3 - Selection #3<br>4 - Selection #4<br>…..<br>10 - Selection #10|1 - Selection #1<br>2 - Selection #2<br>3 - Selection #3<br>4 - Selection #4<br>…..<br>10 - Selection #10|1 - Selection #1<br>2 - Selection #2<br>3 - Selection #3<br>4 - Selection #4<br>…..<br>10 - Selection #10||
||||||||||||||
||||||||||||||
|1|1|2|3|4|5|6|6|7|8|9|10|10|



**Figure 102 – Data entry window on half grid array and a dedicated keyboard (soft key technology)**


10.3.6.25 Figure 103 and Figure 104 give examples of the layout of a data entry window with 4 input

fields covering the total grid array including echo texts and the request for ‘[Window Title]
entry complete?’; Figure 103 when a numeric keyboard is associated to the selected input
field, Figure 104 when dedicated keyboard is associated to the selected input field.


Version 4.0.0 PAGE 157 OF 317


**ERA ERTMS unit**

**ETCS Driver Machine Interface**











|Window Title<br>Label 1 Data 1<br>Label 2 Data 2<br>Label 1 Data 1<br>Label 2 Data 2 Label 3 Data 3<br>Label 3 Data 3<br>Label 4 Data 4<br>Label 4 Data 4<br>[Window Title] entry complete?<br>YES<br>1 2 3 4 5 6 7 8 9 0|Data 1|Col3|Col4|Col5|
|---|---|---|---|---|
|8<br>1<br>0<br>9<br>7<br>6<br>5<br>4<br>3<br>2<br>Window Title<br>Data 1<br>Label 1<br>Data 2<br>Label 2<br>Data 3<br>Label 3<br>Data 4<br>Label 4<br>Label 1<br>Label 2<br>Label 3<br>Label 4<br>YES<br>[Window Title] entry complete?<br>Data 1<br>Data 2<br>Data 3<br>Data 4|Data 2|Data 2|Data 2|Data 2|
|8<br>1<br>0<br>9<br>7<br>6<br>5<br>4<br>3<br>2<br>Window Title<br>Data 1<br>Label 1<br>Data 2<br>Label 2<br>Data 3<br>Label 3<br>Data 4<br>Label 4<br>Label 1<br>Label 2<br>Label 3<br>Label 4<br>YES<br>[Window Title] entry complete?<br>Data 1<br>Data 2<br>Data 3<br>Data 4|Data 3|Data 3|Data 3|Data 3|
|8<br>1<br>0<br>9<br>7<br>6<br>5<br>4<br>3<br>2<br>Window Title<br>Data 1<br>Label 1<br>Data 2<br>Label 2<br>Data 3<br>Label 3<br>Data 4<br>Label 4<br>Label 1<br>Label 2<br>Label 3<br>Label 4<br>YES<br>[Window Title] entry complete?<br>Data 1<br>Data 2<br>Data 3<br>Data 4|Data 4|Data 4|Data 4|Data 4|
|8<br>1<br>0<br>9<br>7<br>6<br>5<br>4<br>3<br>2<br>Window Title<br>Data 1<br>Label 1<br>Data 2<br>Label 2<br>Data 3<br>Label 3<br>Data 4<br>Label 4<br>Label 1<br>Label 2<br>Label 3<br>Label 4<br>YES<br>[Window Title] entry complete?<br>Data 1<br>Data 2<br>Data 3<br>Data 4|Data 4|Data 4|Data 4||
|8<br>1<br>0<br>9<br>7<br>6<br>5<br>4<br>3<br>2<br>Window Title<br>Data 1<br>Label 1<br>Data 2<br>Label 2<br>Data 3<br>Label 3<br>Data 4<br>Label 4<br>Label 1<br>Label 2<br>Label 3<br>Label 4<br>YES<br>[Window Title] entry complete?<br>Data 1<br>Data 2<br>Data 3<br>Data 4|Data 4|Data 4|Data 4||
|1|1|9|0|0|


**Figure 103 – Data entry window with 4 input fields on total grid array and numeric keyboard (soft key**
**technology)**











|Window Title|Col2|Col3|Col4|Col5|Col6|Label 1|Col8|Col9|Data 1|Col11|Col12|Col13|
|---|---|---|---|---|---|---|---|---|---|---|---|---|
|Label 1<br>Label 2<br>Label 3<br>Label 4<br>[Window Title] entry complete?<br>Data 1<br>Data 2<br>Data 3<br>Data 4|Label 1<br>Label 2<br>Label 3<br>Label 4<br>[Window Title] entry complete?<br>Data 1<br>Data 2<br>Data 3<br>Data 4|Label 1<br>Label 2<br>Label 3<br>Label 4<br>[Window Title] entry complete?<br>Data 1<br>Data 2<br>Data 3<br>Data 4|Label 1<br>Label 2<br>Label 3<br>Label 4<br>[Window Title] entry complete?<br>Data 1<br>Data 2<br>Data 3<br>Data 4|Label 1<br>Label 2<br>Label 3<br>Label 4<br>[Window Title] entry complete?<br>Data 1<br>Data 2<br>Data 3<br>Data 4|Label 1<br>Label 2<br>Label 3<br>Label 4<br>[Window Title] entry complete?<br>Data 1<br>Data 2<br>Data 3<br>Data 4|Label 1<br>Label 2<br>Label 3<br>Label 4<br>[Window Title] entry complete?<br>Data 1<br>Data 2<br>Data 3<br>Data 4|Label 1<br>Label 2<br>Label 3<br>Label 4<br>[Window Title] entry complete?<br>Data 1<br>Data 2<br>Data 3<br>Data 4|Label 1<br>Label 2<br>Label 3<br>Label 4<br>[Window Title] entry complete?<br>Data 1<br>Data 2<br>Data 3<br>Data 4|Label 1<br>Label 2<br>Label 3<br>Label 4<br>[Window Title] entry complete?<br>Data 1<br>Data 2<br>Data 3<br>Data 4|Label 1<br>Label 2<br>Label 3<br>Label 4<br>[Window Title] entry complete?<br>Data 1<br>Data 2<br>Data 3<br>Data 4|Label 1<br>Label 2<br>Label 3<br>Label 4<br>[Window Title] entry complete?<br>Data 1<br>Data 2<br>Data 3<br>Data 4||
|Label 1<br>Label 2<br>Label 3<br>Label 4<br>[Window Title] entry complete?<br>Data 1<br>Data 2<br>Data 3<br>Data 4|Label 1<br>Label 2<br>Label 3<br>Label 4<br>[Window Title] entry complete?<br>Data 1<br>Data 2<br>Data 3<br>Data 4|Label 1<br>Label 2<br>Label 3<br>Label 4<br>[Window Title] entry complete?<br>Data 1<br>Data 2<br>Data 3<br>Data 4|Label 1<br>Label 2<br>Label 3<br>Label 4<br>[Window Title] entry complete?<br>Data 1<br>Data 2<br>Data 3<br>Data 4|Label 1<br>Label 2<br>Label 3<br>Label 4<br>[Window Title] entry complete?<br>Data 1<br>Data 2<br>Data 3<br>Data 4|Label 1<br>Label 2<br>Label 3<br>Label 4<br>[Window Title] entry complete?<br>Data 1<br>Data 2<br>Data 3<br>Data 4|Label 2|Label 2|Label 2|Data 2|Data 2|Data 2|Data 2|
|Label 1<br>Label 2<br>Label 3<br>Label 4<br>[Window Title] entry complete?<br>Data 1<br>Data 2<br>Data 3<br>Data 4|Label 1<br>Label 2<br>Label 3<br>Label 4<br>[Window Title] entry complete?<br>Data 1<br>Data 2<br>Data 3<br>Data 4|Label 1<br>Label 2<br>Label 3<br>Label 4<br>[Window Title] entry complete?<br>Data 1<br>Data 2<br>Data 3<br>Data 4|Label 1<br>Label 2<br>Label 3<br>Label 4<br>[Window Title] entry complete?<br>Data 1<br>Data 2<br>Data 3<br>Data 4|Label 1<br>Label 2<br>Label 3<br>Label 4<br>[Window Title] entry complete?<br>Data 1<br>Data 2<br>Data 3<br>Data 4|Label 1<br>Label 2<br>Label 3<br>Label 4<br>[Window Title] entry complete?<br>Data 1<br>Data 2<br>Data 3<br>Data 4|Label 2|Label 2|Label 2|Data 2|Data 2|Data 2||
|Label 1<br>Label 2<br>Label 3<br>Label 4<br>[Window Title] entry complete?<br>Data 1<br>Data 2<br>Data 3<br>Data 4|Label 1<br>Label 2<br>Label 3<br>Label 4<br>[Window Title] entry complete?<br>Data 1<br>Data 2<br>Data 3<br>Data 4|Label 1<br>Label 2<br>Label 3<br>Label 4<br>[Window Title] entry complete?<br>Data 1<br>Data 2<br>Data 3<br>Data 4|Label 1<br>Label 2<br>Label 3<br>Label 4<br>[Window Title] entry complete?<br>Data 1<br>Data 2<br>Data 3<br>Data 4|Label 1<br>Label 2<br>Label 3<br>Label 4<br>[Window Title] entry complete?<br>Data 1<br>Data 2<br>Data 3<br>Data 4|Label 1<br>Label 2<br>Label 3<br>Label 4<br>[Window Title] entry complete?<br>Data 1<br>Data 2<br>Data 3<br>Data 4|Label 3|Label 3|Label 3|Data 3|Data 3|Data 3|Data 3|
|Label 1<br>Label 2<br>Label 3<br>Label 4<br>[Window Title] entry complete?<br>Data 1<br>Data 2<br>Data 3<br>Data 4|Label 1<br>Label 2<br>Label 3<br>Label 4<br>[Window Title] entry complete?<br>Data 1<br>Data 2<br>Data 3<br>Data 4|Label 1<br>Label 2<br>Label 3<br>Label 4<br>[Window Title] entry complete?<br>Data 1<br>Data 2<br>Data 3<br>Data 4|Label 1<br>Label 2<br>Label 3<br>Label 4<br>[Window Title] entry complete?<br>Data 1<br>Data 2<br>Data 3<br>Data 4|Label 1<br>Label 2<br>Label 3<br>Label 4<br>[Window Title] entry complete?<br>Data 1<br>Data 2<br>Data 3<br>Data 4|Label 1<br>Label 2<br>Label 3<br>Label 4<br>[Window Title] entry complete?<br>Data 1<br>Data 2<br>Data 3<br>Data 4|Data 4<br>Label 4<br>1 - Selection #1<br>2 - Selection #2<br>3 - Selection #3|Data 4<br>Label 4<br>1 - Selection #1<br>2 - Selection #2<br>3 - Selection #3|Data 4<br>Label 4<br>1 - Selection #1<br>2 - Selection #2<br>3 - Selection #3|Data 4|Data 4|Data 4|Data 4|
|Label 1<br>Label 2<br>Label 3<br>Label 4<br>[Window Title] entry complete?<br>Data 1<br>Data 2<br>Data 3<br>Data 4|Label 1<br>Label 2<br>Label 3<br>Label 4<br>[Window Title] entry complete?<br>Data 1<br>Data 2<br>Data 3<br>Data 4|Label 1<br>Label 2<br>Label 3<br>Label 4<br>[Window Title] entry complete?<br>Data 1<br>Data 2<br>Data 3<br>Data 4|Label 1<br>Label 2<br>Label 3<br>Label 4<br>[Window Title] entry complete?<br>Data 1<br>Data 2<br>Data 3<br>Data 4|Label 1<br>Label 2<br>Label 3<br>Label 4<br>[Window Title] entry complete?<br>Data 1<br>Data 2<br>Data 3<br>Data 4|Label 1<br>Label 2<br>Label 3<br>Label 4<br>[Window Title] entry complete?<br>Data 1<br>Data 2<br>Data 3<br>Data 4|Data 4<br>Label 4<br>1 - Selection #1<br>2 - Selection #2<br>3 - Selection #3|Data 4<br>Label 4<br>1 - Selection #1<br>2 - Selection #2<br>3 - Selection #3|Data 4<br>Label 4<br>1 - Selection #1<br>2 - Selection #2<br>3 - Selection #3|Data 4|Data 4|Data 4||
|Label 1<br>Label 2<br>Label 3<br>Label 4<br>[Window Title] entry complete?<br>Data 1<br>Data 2<br>Data 3<br>Data 4|Label 1<br>Label 2<br>Label 3<br>Label 4<br>[Window Title] entry complete?<br>Data 1<br>Data 2<br>Data 3<br>Data 4|Label 1<br>Label 2<br>Label 3<br>Label 4<br>[Window Title] entry complete?<br>Data 1<br>Data 2<br>Data 3<br>Data 4|Label 1<br>Label 2<br>Label 3<br>Label 4<br>[Window Title] entry complete?<br>Data 1<br>Data 2<br>Data 3<br>Data 4|Label 1<br>Label 2<br>Label 3<br>Label 4<br>[Window Title] entry complete?<br>Data 1<br>Data 2<br>Data 3<br>Data 4|Label 1<br>Label 2<br>Label 3<br>Label 4<br>[Window Title] entry complete?<br>Data 1<br>Data 2<br>Data 3<br>Data 4|Data 4<br>Label 4<br>1 - Selection #1<br>2 - Selection #2<br>3 - Selection #3|Data 4<br>Label 4<br>1 - Selection #1<br>2 - Selection #2<br>3 - Selection #3|Data 4<br>Label 4<br>1 - Selection #1<br>2 - Selection #2<br>3 - Selection #3|Data 4|Data 4|Data 4||
|Label 1<br>Label 2<br>Label 3<br>Label 4<br>[Window Title] entry complete?<br>Data 1<br>Data 2<br>Data 3<br>Data 4|Label 1<br>Label 2<br>Label 3<br>Label 4<br>[Window Title] entry complete?<br>Data 1<br>Data 2<br>Data 3<br>Data 4|Label 1<br>Label 2<br>Label 3<br>Label 4<br>[Window Title] entry complete?<br>Data 1<br>Data 2<br>Data 3<br>Data 4|Label 1<br>Label 2<br>Label 3<br>Label 4<br>[Window Title] entry complete?<br>Data 1<br>Data 2<br>Data 3<br>Data 4|Label 1<br>Label 2<br>Label 3<br>Label 4<br>[Window Title] entry complete?<br>Data 1<br>Data 2<br>Data 3<br>Data 4|Label 1<br>Label 2<br>Label 3<br>Label 4<br>[Window Title] entry complete?<br>Data 1<br>Data 2<br>Data 3<br>Data 4|Data 4<br>Label 4<br>1 - Selection #1<br>2 - Selection #2<br>3 - Selection #3|Data 4<br>Label 4<br>1 - Selection #1<br>2 - Selection #2<br>3 - Selection #3|Data 4<br>Label 4<br>1 - Selection #1<br>2 - Selection #2<br>3 - Selection #3|Data 4|Data 4|Data 4||
|Label 1<br>Label 2<br>Label 3<br>Label 4<br>[Window Title] entry complete?<br>Data 1<br>Data 2<br>Data 3<br>Data 4|Label 1<br>Label 2<br>Label 3<br>Label 4<br>[Window Title] entry complete?<br>Data 1<br>Data 2<br>Data 3<br>Data 4|Label 1<br>Label 2<br>Label 3<br>Label 4<br>[Window Title] entry complete?<br>Data 1<br>Data 2<br>Data 3<br>Data 4|Label 1<br>Label 2<br>Label 3<br>Label 4<br>[Window Title] entry complete?<br>Data 1<br>Data 2<br>Data 3<br>Data 4|Label 1<br>Label 2<br>Label 3<br>Label 4<br>[Window Title] entry complete?<br>Data 1<br>Data 2<br>Data 3<br>Data 4|Label 1<br>Label 2<br>Label 3<br>Label 4<br>[Window Title] entry complete?<br>Data 1<br>Data 2<br>Data 3<br>Data 4|Data 4<br>Label 4<br>1 - Selection #1<br>2 - Selection #2<br>3 - Selection #3|Data 4<br>Label 4<br>1 - Selection #1<br>2 - Selection #2<br>3 - Selection #3|Data 4<br>Label 4<br>1 - Selection #1<br>2 - Selection #2<br>3 - Selection #3|Data 4|Data 4|Data 4||
|YES|YES|YES|YES|YES|YES|YES|YES|YES|YES|YES|YES|YES|
|1|2|3|||||||||||


**Figure 104 – Data entry window with 4 input fields on total grid array and dedicated keyboard (soft key**
**technology)**


**10.3.7** **Layers**


10.3.7.1 The layers for data entry windows on half grid array shall be as follows:

a) Layer 0: D/F/G (touch screen technology) or D/G/I (soft key technology)

b) All other areas: same as default window (see 8.1.1.4)


Version 4.0.0 PAGE 158 OF 317


**ERA ERTMS unit**

**ETCS Driver Machine Interface**


10.3.7.2 The layers for data entry windows on total grid array shall be as follows:

a) Layer 0: all areas

b) Layer -1: none

c) Layer -2: none


**10.4** **Data validation windows**


**10.4.1** **Data validation for touch screen technology**


10.4.1.1 The window shall be in the A/B/C/D/E/F/G area.


10.4.1.2 The data validation window shall contain a single input field (only data part) with a
dedicated keyboard being a ‘No’/‘Yes’ choice (see 10.3.5.18).


10.4.1.3 Each object shall follow the dimension and position as specified in Table 29.


10.4.1.4 The text label of the window title shall be right aligned.

|Data validation window|Col2|Col3|Col4|Col5|
|---|---|---|---|---|
|**_Item_**|**_Width_**|**_ Height_**|**_ X Location_**|**_Y Location_**|
|Window Title|334|24|0|0|
|‘Close’ button|82|50|334|400|
|Input field (data part)|<br>306|50|334|0|
|‘No’ key|102|50|334|300|
|‘Yes’ key|102|50|436|300|



**Table 29 – Data validation window (touch screen technology)**


10.4.1.5 The window shall give echo texts corresponding to the input fields of the topic (e.g. train
data) to be validated applying the requirements in 10.3.3.


10.4.1.6 Figure 105 gives an example of the layout of a data validation window containing 5 data
to be validated.


Version 4.0.0 PAGE 159 OF 317


**ERA ERTMS unit**

**ETCS Driver Machine Interface**









**Figure 105 – Data validation window (touch screen technology)**


**10.4.2** **Data validation for soft key technology**


10.4.2.1 The window shall be in the A/B/C/D/E/G/I area.


10.4.2.2 The data validation window shall contain a single input field (only data part) with a
dedicated keyboard being a ‘No’/‘Yes’ choice (see 10.3.6.22.1).


10.4.2.3 Each object shall follow the dimension and position as specified in Table 30.


10.4.2.4 The text label of the window title shall be right aligned.

|Data validation window|Col2|Col3|Col4|Col5|
|---|---|---|---|---|
|**_Item_**|**_Width_**|**_ Height_**|**_X Location_**|**_Y Location_**|
|Window Title|334|24|0|0|
|Input field (data part)|268|50|334|0|



**Table 30 – Data validation window (soft key technology)**


10.4.2.5 The [Close] button shall be in H3.


10.4.2.6 The window shall give echo texts corresponding to the input fields of the topic (e.g. train
data) to be validated applying the requirements in 10.3.3.


10.4.2.7 Figure 106 gives an example of the layout of a data validation window containing 5 data
to be validated.


Version 4.0.0 PAGE 160 OF 317


**ERA ERTMS unit**

**ETCS Driver Machine Interface**











|Window Title<br>Yes<br>Label 1 Data 1<br>Label 2 Data 2<br>Label 3 Data 3<br>Label 4 Data 4<br>Label 5 Data 5<br>… ...<br>No Yes|Col2|Col3|Col4|Col5|Yes|Col7|Col8|Col9|Col10|Col11|
|---|---|---|---|---|---|---|---|---|---|---|
|Yes<br>No<br>Window Title<br>Yes<br>Label 1<br>Label 2<br>Label 3<br>Label 4<br>Label 5<br>…<br>Data 1<br>Data 2<br>Data 3<br>Data 4<br>Data 5<br>...|Yes<br>No<br>Window Title<br>Yes<br>Label 1<br>Label 2<br>Label 3<br>Label 4<br>Label 5<br>…<br>Data 1<br>Data 2<br>Data 3<br>Data 4<br>Data 5<br>...|Yes<br>No<br>Window Title<br>Yes<br>Label 1<br>Label 2<br>Label 3<br>Label 4<br>Label 5<br>…<br>Data 1<br>Data 2<br>Data 3<br>Data 4<br>Data 5<br>...|Yes<br>No<br>Window Title<br>Yes<br>Label 1<br>Label 2<br>Label 3<br>Label 4<br>Label 5<br>…<br>Data 1<br>Data 2<br>Data 3<br>Data 4<br>Data 5<br>...|Yes<br>No<br>Window Title<br>Yes<br>Label 1<br>Label 2<br>Label 3<br>Label 4<br>Label 5<br>…<br>Data 1<br>Data 2<br>Data 3<br>Data 4<br>Data 5<br>...|Yes|Yes|Yes|Yes|Yes||
|Yes<br>No<br>Window Title<br>Yes<br>Label 1<br>Label 2<br>Label 3<br>Label 4<br>Label 5<br>…<br>Data 1<br>Data 2<br>Data 3<br>Data 4<br>Data 5<br>...|Yes<br>No<br>Window Title<br>Yes<br>Label 1<br>Label 2<br>Label 3<br>Label 4<br>Label 5<br>…<br>Data 1<br>Data 2<br>Data 3<br>Data 4<br>Data 5<br>...|Yes<br>No<br>Window Title<br>Yes<br>Label 1<br>Label 2<br>Label 3<br>Label 4<br>Label 5<br>…<br>Data 1<br>Data 2<br>Data 3<br>Data 4<br>Data 5<br>...|Yes<br>No<br>Window Title<br>Yes<br>Label 1<br>Label 2<br>Label 3<br>Label 4<br>Label 5<br>…<br>Data 1<br>Data 2<br>Data 3<br>Data 4<br>Data 5<br>...|Yes<br>No<br>Window Title<br>Yes<br>Label 1<br>Label 2<br>Label 3<br>Label 4<br>Label 5<br>…<br>Data 1<br>Data 2<br>Data 3<br>Data 4<br>Data 5<br>...|Yes|Yes|Yes|Yes|Yes||
|||||||No|Yes||||


**Figure 106 – Data validation window (soft key technology)**


**10.4.3** **Layers**


10.4.3.1 The layers for data validation window shall be as follows:

a) Layer 0: all areas

b) Layer -1: none

c) Layer -2: none


**10.5** **Data view windows**


**10.5.1** **Data view for touch screen technology**


10.5.1.1 The window shall be in the D/F/G area.


10.5.1.2 Each object shall follow the dimension and position as specified in Table 31.

|Data View window|Col2|Col3|Col4|Col5|
|---|---|---|---|---|
|**_Item_**|**_Width_**|**_ Height_**|**_ X Location_**|**_Y Location_**|
|‘Close’ button|82|50|0|400|
|‘Previous’ button (when<br>several windows<br>containing data view<br>items related to the same<br>data view topic exists)|82|50|82|400|
|‘Next’ button (when<br>several windows<br>containing data view<br>items related to the same<br>data view topic exists)|82|50|164|400|
|Window Title|306|24|0|0|



**Table 31 – Data view window (touch screen technology)**


Version 4.0.0 PAGE 161 OF 317


**ERA ERTMS unit**

**ETCS Driver Machine Interface**


10.5.1.3 A data view item shall be composed of a label part identifying the concerned data and of
a data part displaying its data value.


10.5.1.4 The data part shall display the value only when it is valid (see reference [2] for the status
unknown/invalid/valid).


10.5.1.5 The data view item shall be grey.


10.5.1.6 Data view items related to different topic shall be separated by one empty text line.


10.5.1.7 The labels of the data view items shall be right aligned with an indent of 5 on the left side
of the X position 204.


10.5.1.8 The label of the first data view item shall be 62 cells (i.e. an indent of 50 cells + the 12
cells of the character size) below the top of area D/F/G.


10.5.1.9 The data of the data view items shall be left aligned with an indent of 5 cells on the right
side of the X position 204.


10.5.1.10 The data of the first data view item shall be 62 cells (i.e. an indent of 50 cells + the 12

cells of the character size) below the top of area D/F/G.


10.5.1.11 Figure 107 gives an example of the layout of a data view window containing 5 data view

items; the 2 first data view items belonging to one topic, the next 3 data view items
belonging to another topic.



|Col1|Col2|
|---|---|
|Window Title<br>Label 1<br>Label 2<br>Label 3<br>Label 4<br>Label 5<br>…<br>Data 1<br>Data 2<br>Data 3<br>Data 4<br>Data 5<br>...|Window Title|
|Window Title<br>Label 1<br>Label 2<br>Label 3<br>Label 4<br>Label 5<br>…<br>Data 1<br>Data 2<br>Data 3<br>Data 4<br>Data 5<br>...|Label 1<br>Label 2<br>Label 3<br>Label 4<br>Label 5<br>…<br>Data 1<br>Data 2<br>Data 3<br>Data 4<br>Data 5<br>...|
|Window Title<br>Label 1<br>Label 2<br>Label 3<br>Label 4<br>Label 5<br>…<br>Data 1<br>Data 2<br>Data 3<br>Data 4<br>Data 5<br>...||


**Figure 107 – Data view window (touch screen technology)**


**10.5.2** **Data view for soft key technology**


10.5.2.1 The window shall be in the D/G/I area.





10.5.2.2 Each object shall follow the dimension and position as specified in Table 32.





Version 4.0.0 PAGE 162 OF 317


**ERA ERTMS unit**

**ETCS Driver Machine Interface**

|Item|Width|Height|X Location|Y Location|
|---|---|---|---|---|
|Window Title|266|24|0|0|



**Table 32 – Data view window (soft key technology)**


10.5.2.3 When no previous window containing data view items related to the same topic exists, the

[Close] button shall be in H3.


10.5.2.4 When a previous window containing data view items related to the same topic exists, the

[Previous] button shall be in H3.


10.5.2.5 When a next window containing data view items related to the same topic exists, the [Next]
button shall be in H4.


10.5.2.6 A data view item shall be composed of a label part identifying the concerned data and of
a data part displaying its data value.


10.5.2.7 The data part shall display the value only when it is valid (see reference [2] for the status
unknown/invalid/valid).


10.5.2.8 The data view item shall be grey.


10.5.2.9 Data view items related to different topic shall be separated by one empty text line.


10.5.2.10 The labels of the data view items shall be right aligned with an indent of 5 on the left side

of the X position 176.


10.5.2.11 The label of the first data view item shall be 62 cells (i.e. an indent of 50 cells + the 12

cells of the character size) below the top of area D/G/I.


10.5.2.12 The data of the data view items shall be left aligned with an indent of 5 cells on the right

side of the X position 176.


10.5.2.13 The data of the first data view item shall be 62 cells (i.e. an indent of 50 cells + the 12

cells of the character size) below the top of area D/G/I.


10.5.2.14 Figure 108 gives an example of the layout of a data view window containing 5 data view

items; the 2 first data view items belonging to one topic, the next 3 data view items
belonging to another topic.


Version 4.0.0 PAGE 163 OF 317


**ERA ERTMS unit**

**ETCS Driver Machine Interface**



|Window Title<br>Label 1 Data 1<br>Label 2 Data 2<br>Label 3 Data 3<br>Label 4 Data 4<br>Label 5 Data 5<br>… ...|Col2|Col3|Col4|Col5|Col6|
|---|---|---|---|---|---|
|Window Title<br>Label 1<br>Label 2<br>Label 3<br>Label 4<br>Label 5<br>…<br>Data 1<br>Data 2<br>Data 3<br>Data 4<br>Data 5<br>...|Window Title<br>Label 1<br>Label 2<br>Label 3<br>Label 4<br>Label 5<br>…<br>Data 1<br>Data 2<br>Data 3<br>Data 4<br>Data 5<br>...|Window Title<br>Label 1<br>Label 2<br>Label 3<br>Label 4<br>Label 5<br>…<br>Data 1<br>Data 2<br>Data 3<br>Data 4<br>Data 5<br>...|Window Title<br>Label 1<br>Label 2<br>Label 3<br>Label 4<br>Label 5<br>…<br>Data 1<br>Data 2<br>Data 3<br>Data 4<br>Data 5<br>...|Window Title<br>Label 1<br>Label 2<br>Label 3<br>Label 4<br>Label 5<br>…<br>Data 1<br>Data 2<br>Data 3<br>Data 4<br>Data 5<br>...||
|Window Title<br>Label 1<br>Label 2<br>Label 3<br>Label 4<br>Label 5<br>…<br>Data 1<br>Data 2<br>Data 3<br>Data 4<br>Data 5<br>...|Window Title<br>Label 1<br>Label 2<br>Label 3<br>Label 4<br>Label 5<br>…<br>Data 1<br>Data 2<br>Data 3<br>Data 4<br>Data 5<br>...|Window Title<br>Label 1<br>Label 2<br>Label 3<br>Label 4<br>Label 5<br>…<br>Data 1<br>Data 2<br>Data 3<br>Data 4<br>Data 5<br>...|Window Title<br>Label 1<br>Label 2<br>Label 3<br>Label 4<br>Label 5<br>…<br>Data 1<br>Data 2<br>Data 3<br>Data 4<br>Data 5<br>...|Window Title<br>Label 1<br>Label 2<br>Label 3<br>Label 4<br>Label 5<br>…<br>Data 1<br>Data 2<br>Data 3<br>Data 4<br>Data 5<br>...||
|Window Title<br>Label 1<br>Label 2<br>Label 3<br>Label 4<br>Label 5<br>…<br>Data 1<br>Data 2<br>Data 3<br>Data 4<br>Data 5<br>...||||||


**Figure 108 – Data view window (soft key technology)**


**10.5.3** **Layers**





10.5.3.1 The layers for data view windows shall be as follows:

a) Layer 0: D/F/G (touch screen technology) or D/G/I (soft key technology)

b) All other areas: same as default window (see 8.1.1.4)


**10.6** **Data entry / validation process**


10.6.1.1 If not started yet, a data entry / validation process regarding a topic shall start when the
first data entry window of this topic is displayed.


10.6.1.2 If no validation window regarding the same topic as the data entry window exists, the data
entry / validation process shall stop:

a) when one of the data entry window(s) is left by accepting the data values via the ‘Yes’

button, or

b) when any of the data entry window(s) is left via the [Close] button, or

c) when any of the data entry window(s) is left due to another reason.


10.6.1.3 If a validation window regarding the same topic as the data entry window exists, the data
entry / validation process shall stop:

a) when the validation window is left by accepting a data value set to ‘Yes’ in its input

field, or

b) when any of the data entry window(s) is left via the [Close] button, or

c) when the validation window is left via the [Close] button, or

d) when any of the data entry window(s) is left due to a reason other than accepting the

data values via the ‘Yes’ button, or

e) when the validation window is left due to another reason.


Version 4.0.0 PAGE 164 OF 317


**ERA ERTMS unit**

**ETCS Driver Machine Interface**


10.6.1.4 Note: The other reasons stopping a data entry / validation process are explained in the
relevant sections of chapter 11.


Version 4.0.0 PAGE 165 OF 317


**ERA ERTMS unit**

**ETCS Driver Machine Interface**

