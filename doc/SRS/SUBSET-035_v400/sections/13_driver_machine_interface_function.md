# **13. DRIVER MACHINE INTERFACE FUNCTION**

## **13.1 Introduction**

13.1.1.1 The DMI Function allows the driver to directly interact with the ERTMS/ETCS on-board for what regards the national information related to the default window. That means that all inputs from the driver to the ERTMS/ETCS on-board and all outputs from the ERTMS/ETCS on-board to the driver in the default window are controlled by this function.

13.1.1.2 The DMI Function shall provide the unified DMI and the customisable DMI services.

13.1.1.3 An STM designed for usage with a customisable DMI provides a set of configuration data for its default window as part of its product documentation as described in chapter 13.5. The ERTMS/ETCS on-board shall be configurable to store this information and serve the STM DMI requests according to this configuration. The customisable DMI service shall be used, when configuration data for a customisable DMI layout are stored in the ERTMS/ETCS on-board for the NID_STM of the STM.

13.1.1.4 An STM designed to use the unified DMI provides no configuration data as part of its product documentation. The unified DMI service shall be used, when no configuration data for a customisable DMI layout is stored in the ERTMS/ETCS on-board for the NID_STM of the STM.

13.1.1.5 Note: Unconfigurable parts of the DMI functions shall be handled in the same way by the unified and the customisable DMI services.

## **13.2 General requirements regarding DMI Function**

13.2.1.1 The ERTMS/ETCS on-board shall only allow the active STM to communicate with the driver.

13.2.1.2 When the STM is no more active (see 4.1.1.3), the ERTMS/ETCS on-board shall delete all DMI objects controlled by this STM.

13.2.1.3 When the connection between an STM and the DMI Function is disconnected, the ERTMS/ETCS on-board shall delete all the DMI objects controlled by this STM (including preliminary requests) after a timeout of 2 seconds.

13.2.1.3.1 Justification: The timeout of 2 seconds is to give the STM the chance to re-establish the connection.

13.2.1.4 When the connection between the active STM and the DMI Function is lost and reestablished within the timeout of 2 seconds, the ERTMS/ETCS on-board shall delete all the DMI objects controlled by the STM when the DMI connection to the STM is established.

<!-- end of page 74 -->

13.2.1.5 The ERTMS/ETCS on-board shall be able to receive and store preliminary request for DMI objects from an STM being in HS state and display them immediately after having received the DA state report.

13.2.1.5.1 Note: The sending of preliminary request is to allow the DMI Function to prepare in background the information to be presented to the driver once the STM switches to DA state. Therefore, the STM should send all DMI objects that needs to be displayed after the change to DA as preliminary DMI request.

13.2.1.6 When an STM reports PO, CS or FA, or is considered as failed, the ERTMS/ETCS onboard shall delete all preliminary requests for DMI objects from this STM.

13.2.1.7 If the ETCS train speed is configured not to be displayed for an STM while the ERTMS/ETCS on-board is in SN mode (see chapter 13.5.1.1.7), the ERTMS/ETCS onboard shall inhibit the display of the ETCS train speed only once the DA state report is received from this STM by the STM Control Function.

## **13.3 DMI channels**

13.3.1.1 The DMI Function shall be allowed to use up to four DMI channels. Each channel shall correspond to one connection.

13.3.1.2 At most one DMI channel shall be active, only this one shall be used for the communication related to DMI objects with the DMI Function at application level.

13.3.1.3 Note 1: Connections corresponding to the inactive DMI channels may however remain open.

13.3.1.3.1 Note 2: The ERTMS/ETCS on-board may report a DMI channel as active even if no interaction with the driver is possible, e.g. when no cab is active.

13.3.1.4 At the time the active DMI channel changes, the DMI Function shall delete all the DMI objects controlled by the STM.

## **13.4 DMI Objects**

### **13.4.1 DMI object identities**

13.4.1.1 The DMI objects indicators and buttons used by the different STMs are assigned a unique object identity made of NID_STM and Indicator/Button Identifier.

13.4.1.2 The STM Identity is implicitly provided by the STM by its announced NID_STM (and repeated in each message header according to the language).

13.4.1.3 The Indicator/Button Identifier is provided by the STM as part of the corresponding Indicator/Button request.

13.4.1.4 The Indicator/Button Identifier is used by the STM to be able to change the state of objects and to move or remove them. The Button Identifier is also used by the ERTMS/ETCS on-board to transmit the button events to the STM. If the customisable DMI service is used, it is also used to define the properties of the object.

<!-- end of page 75 -->

13.4.1.5 All icons (bitmap symbols) used by the different STMs using a customisable DMI are assigned an icon identity made of NID_STM and Icon Identifier.

13.4.1.6 An Icon Identifier can be provided by the STM as part of the corresponding Indicator/Button request.

13.4.1.7 All sounds (wave form for audible information) used by the different STMs using a customisable DMI are assigned a unique sound identity made of NID_STM and Sound Identifier.

13.4.1.8 A Sound Identifier can be provided by the STM as part of the corresponding sound request.

13.4.1.9 For specifying the position of DMI objects, Position Identifiers are used.

13.4.1.10 If the unified DMI service is used, the Position Identifier specifies an area of the ETCS layout as defined in [9].

13.4.1.11 If the customisable DMI service is used, the Position Identifier and the NID_STM are used to define the position in cell coordinates and size as specified in the configuration data for this STM.

### **13.4.2 Text messages**

13.4.2.1 The DMI Function shall display a text message when requested by the STM. The text message request shall consist of a Text Identifier, a string of text to be shown to the driver, a display attribute and a possible request for driver acknowledgement.

13.4.2.2 The DMI Function shall report to the STM the acknowledgement of text messages (which were required to be acknowledged) from the driver referencing the corresponding Text Identifier.

13.4.2.3 The DMI Function shall delete a text message when requested by the active STM. The request shall reference the Text Identifier of the text message to be deleted.

13.4.2.3.1 Note: The acknowledgement does not lead to the end of the display of a text message.

13.4.2.4 If the STM requests a text message with the same Text Identifier as a not yet deleted text message, the ERTMS/ETCS on-board shall delete the original text message and display the new requested text message.

13.4.2.5 The display attribute specifies the colour of the text, its background colour, the flashing mode and the group of text messages.

13.4.2.6 The flashing mode specifies if the slow, fast or no flashing and if normal or counterphase flashing shall be used.

### **13.4.3 Indicators**

13.4.3.1 An Indicator is a DMI object for display of information without input.

13.4.3.2 The STM shall request the display of an Indicator by means of the following definition:

<!-- end of page 76 -->

- a) its Indicator Identifier,

- b) an optional Icon Identifier,

c) an optional caption text,

d) a Position Identifier,

e) a display attribute.

13.4.3.3 The Icon Identifier shall be used by the DMI Function in case of the customisable DMI service to retrieve from the configuration data the corresponding icon attached to an Indicator/Button object.

13.4.3.4 The display attribute shall specify the background colour and the flashing mode for the whole Indicator and the display colour of the caption text.

13.4.3.5 The flashing mode specifies if the slow, fast or no flashing and if normal or counterphase flashing shall be used.

### **13.4.4 Buttons**

13.4.4.1 Buttons are a pure functional extension of Indicators. All requirements of chapter 13.4.3 shall apply to Buttons, by replacing "Indicator" with "Button".

13.4.4.2 The extension is the transmission of Button events from the DMI Function to STM. The DMI Function shall make a distinction between push event (transition from Button not pressed to pressed state) and release event (opposite transition).

13.4.4.3 The DMI Function shall report Button push and release events to the STM and shall timestamp those event reports to reflect the sequence of events.

13.4.4.4 The DMI Function shall use the Reference Time (see chapter 5.2.2) for timestamping the Button events reports.

### **13.4.5 Sounds**

13.4.5.1 STM shall request a Sound by means of the following definition:

   - a) an optional Sound Identifier,

   - b) only in case of a unified DMI and a Sound to be generated, a sequence of segments defined by a duration and an associated frequency,

<!-- end of page 77 -->

<!-- Start of picture text -->
Freq.<br><!-- End of picture text -->

<!-- Start of picture text -->
Time<br><!-- End of picture text -->

Figure 11 : Example of sound definition

   - c) an indication if the Sound has to be repeated continuously or not or to be stopped.

13.4.5.2 The Sound Identifier shall be used by the ERTMS/ETCS on-board in case of the customisable DMI service to retrieve from the configuration data the corresponding sound.

13.4.5.3 The Sound Identifier shall be used by the ERTMS/ETCS on-board in both DMI services to stop the generation of a Sound, if requested by the STM.

13.4.5.4 The DMI Function shall be able to manage two STM requests for Sounds at the same time.

13.4.5.4.1 Note: This will allow an STM to request a long Sound and a short Sound simultaneously.

### **13.4.6 Supervision information**

13.4.6.1 There shall be two sets of supervision information:

   - a) Speed and distance values

   - b) Colours and display modes

13.4.6.2 Speed and distance values consists of :

   - a) Permitted Speed

   - b) Target Speed

   - c) Target Distance

   - d) Release Speed

   - e) Intervention Speed

13.4.6.3 Colours and display modes consists of:

   - a) Current train speed pointer

<!-- end of page 78 -->

      - Colour

   - b) Permitted Speed

      - Colour

      - Display mode: no display, bar only, hook only or hook and bar

   - c) Target Speed

      - Colour

      - Display mode: no display, bar only, hook only or hook and bar

   - d) Target Distance

      - Display mode: no display, bar only, digital only or bar and digital

   - e) Release Speed

      - Colour

      - Display mode: no display, bar only, digital only or bar and digital

   - f) Intervention Speed

      - Colour

      - Display mode: no display, display with normal bar width or display with wide bar width.

13.4.6.4 The DMI Function shall use the last received information for Current train speed pointer, Target Speed, Release Speed, Permitted Speed, Intervention Speed and Target Distance.

## **13.5 Customisable DMI service**

13.5.1.1 The configuration of the customisable DMI shall define the following data for each STM using the customisable DMI service:

13.5.1.1.1 The NID_STM of the STM.

13.5.1.1.2 The list of Indicators defined for the STM with the following data for each Indicator:

   - a) identifier (a number);

   - b) font size (height in cells);

   - c) horizontal text-alignment (left, right or centred);

   - d) vertical text-alignment (upper part, lower part or centred).

13.5.1.1.3 Two lists of Indicator positions (one list for soft key technology and one list for touch screen technology) defined for the STM, and for each Indicator position:

   - a) identifier (a number);

   - b) x:y offset of the upper left corner in cells;

   - c) x:y size of the area in cells.

13.5.1.1.4 The list of Buttons defined for the STM with the following data for each Button:

<!-- end of page 79 -->

   - a) identifier (a number);

   - b) font size (height in cells);

   - c) horizontal text-alignment (left, right or centred);

   - d) vertical text-alignment (upper part, lower part or centred).

13.5.1.1.5 Two lists of Button positions (one list for soft key technology and one list for touch screen technology) defined for the STM and, for each Button position:

   - a) identifier (a number);

   - b) x:y offset of the upper left corner in cells;

   - c) x:y size of the area in cells;

   - d) linked soft key (for soft key technology).

13.5.1.1.6 The list of Icons defined for the STM and, for each Icon:

   - a) identifier (a number);

   - b) bitmap, as RGB bitmap file (according to Microsoft BMP file format); Pixels in the bitmap files shall be understood as cells.

   - c) display of text upon icon: yes/no.

13.5.1.1.7 ETCS speed and distance supervision

   - a) For speed and distance supervision display in speed dial as for ETCS in area B0-B2, B6 and A2-A3 (applicable as long as the STM is active):

   - b) Yes/No; “Yes” means that the ETCS train speed display is re-used as such together with the supervision information as specified in 13.4.6. “No” means that there is no display of speed and distance supervision in the ETCS way.

   - c) if Yes: speed dial range (0-140/180/250/400 km/h or same range as ETCS).

13.5.1.1.8 Options for flashing of Indicators and Buttons (additionally to flashing mode):

   - a) the frequency for slow and fast flashing;

   - b) the flashing style either as ‘yellow frame’ or as ‘whole area’.

13.5.1.1.9 The list of Sounds defined for the STM and, for each sound, its Sound definition.

   - a) identifier (a number);

   - b) sound, as WAV file (according to Microsoft WAV file format);

13.5.1.1.10 Moved areas of the ETCS layout:

   - a) If a STM needs partially or totally the cells used by an area defined in the ETCS layout and in which ETCS DMI objects are displayed in level NTC modes SN or NL, the ETCS objects displayed in it must be moved somewhere else on the national layout. Therefore it shall be possible to specify a changed location for moving the following ETCS areas and their related ETCS objects. For buttons also the new related soft key (F1-F5) must be defined:

<!-- end of page 80 -->

   - Areas F1-F5 for the buttons for selecting the main, override, data view, special or settings window;

   - Area A4 for the adhesion “slippery rail”;

   - Areas B7 and C8 for the ETCS mode and level display;

   - Area C1 for the mode/level acknowledgements;

   - Area C7 for the Override status indication;

   - Area C9 for the brake indication;

   - Area E1 for safe radio connection indication;

   - Area G13 for local time

- b) The new location shall be specified by a new x:y position in cells.

- c) The moved areas shall have the same size as the original ETCS areas.

#### 13.5.1.2 Recapping Table with configuration data for customisable DMI:

|**Description**|**Multiplicity**|**Range and unit**|
|---|---|---|
|NID_STM of the STM|1|0-254|
|Number of Indicators|1|0-255|
|Indicator id (i)|For each Indicator|1-255|
|Font size (i)|For each Indicator|height in cells (8-60)|
|Horizontal text alignment (i)|For each Indicator|Left , right, centred|
|Vertical text alignment (i)|For each Indicator|upper part, lower part, centred|
|Number of Indicator positions in case of<br>touch screen technology|1|0-24|
|Indicator position id (i)|For each Indicator position|1-24|
|X Offset of the upper left corner<br>(i)|For each Indicator position|0-639 [cells]|
|Y Offset of the upper left corner<br>(i)|For each Indicator position|0-479 [cells]|
|Horizontal size (i)|For each Indicator position|8-640 [cells]|
|Vertical size (i)|For each Indicator position|8-480 [cells]|
|Number of Indicator positions in case of<br>soft key technology|1|0-24|
|Indicator position id (i)|For each Indicator position|1-24|
|X Offset of the upper left corner<br>(i)|For each Indicator position|0-639 [cells]|
|Y Offset of the upper left corner<br>(i)|For each Indicator position|0-479 [cells]|
|Horizontal size (i)|For each Indicator position|8-640 [cells]|
|Vertical size (i)|For each Indicator position|8-480 [cells]|
|Number of Buttons|1|0-255|
|Button id (i)|For each Button|1-255|

<!-- end of page 81 -->

|Font size (i)|For each Button|height in cells (8-60)|
|---|---|---|
|Horizontal text alignment (i)|For each Button|Left , right, centred|
|Vertical text alignment (i)|For each Button|upper part, lower part, centred|
|Number of Button positions in case of<br>touch screen technology|1|0-24|
|Button position id for touch<br>screen (i)|For each Button position|1-24|
|X Offset of the upper left corner<br>(i)|For each Button position|0-639 [cells]|
|Y Offset of the upper left corner<br>(i)|For each Button position|0-479 [cells]|
|Horizontal size (i)|For each Button position|8-640 [cells]|
|Vertical size (i)|For each Button position|8-480 [cells]|
|Number of Button positions in case of<br>soft key technology|1|0-24|
|Button position id for soft key (i)|For each Button position|1-24|
|X Offset of the upper left corner<br>(i)|For each Button position|0-639 [cells]|
|Y Offset of the upper left corner<br>(i)|For each Button position|0-479 [cells]|
|Horizontal size (i)|For each Button position|8-640 [cells]|
|Vertical size (i)|For each Button position|8-480 [cells]|
|Linked soft key|For each Button position|F1-F10,H2-H4|
|Number of Icons|1|0-255|
|Icon id (i)|For each Icon|1-255|
|Icon (i)|For each Icon|Bitmap file|
|Display text upon icon|For each Icon|Yes/No|
|ETCS speed and distance supervision|1|Yes/No|
|ETCS speed dial range|1|No, same as ETCS, 140, 180,<br>250, 400 km/h|
|Slow flashing frequency for Buttons and<br>Indicators|1|(0,5 – 8) Hz|
|Fast flashing frequency for Buttons and<br>Indicators|1|(0,5 – 8) Hz|
|Flashing style|1|Frame, whole area|
|Number of Sounds|1|0-255|
|Sound id (i)|For each Sound|1-255|
|sound (i)|For each Sound|Wave file|
|Number of moved areas of the ETCS<br>layout|1|0 – 13|
|ETCS area of moved element(i)|For each moved element|A4, B7, C1, C7-C9, E1, F1-F5,<br>G13|

<!-- end of page 82 -->

|X Offset of the upper left corner|For each moved element|0-639 [cells]|
|---|---|---|
|(i) of new location|||
|Y Offset of the upper left corner|For each moved element|0-479 [cells]|
|(i) of new location|||
|Soft key Identifier (i)|For each moved button|F1-F10, H2-H4|

<!-- end of page 83 -->
