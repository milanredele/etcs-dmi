## **3.18 System Data**

### **3.18.1 Fixed Values**

3.18.1.1 Note: Appendix to chapter 3 contains a list of Fixed values used as system parameters in the supervision. These parameters are system related and can easily be changed in later versions of the ERTMS/ETCS if required. These parameters are not defined as National data.

### **3.18.2 National / Default Values**

3.18.2.1 Note: Appendix to chapter 3 contains list of National and Default Values.

3.18.2.2 Trains shall be supervised according to the National Values of the current infrastructure if they are available on-board.

3.18.2.3 National Values are transmitted with the area(s) (country or region) in which they are applicable. They shall become applicable at a defined location, or shall be applicable immediately.

3.18.2.4 Evaluating a balise group message, the balise identity information referring to the country or region shall be used to ensure that correct National Values are used.

3.18.2.5 For each National Value, the corresponding Default Value shall be used as fall back value if:

   - the National Value is not available, or

   - a mismatch has been detected between the country or region identifier read from a balise group and the corresponding identifier(s) of the applicable set with which the National Value was received and stored.

3.18.2.6 Note: even though the National Values are always transmitted as a single set for a given system version, the content of a set depends on the system version, so that when a set

<!-- end of page 208 -->

of National Values is received or becomes applicable, or when passing a balise group, the on-board equipment may apply clause 3.18.2.5 for a subset of National Values

3.18.2.7 The National Values currently applicable when the on-board equipment is switched off (i.e. enters No Power mode) shall be retained and shall remain applicable when powered on.

3.18.2.7.1 Justification:  The aim of this requirement is to limit the number of balise groups containing National Value information. Once a set of National Values has been received on-board, there is no need to re-load the information unless National Values change, the on-board equipment loses the information (failure situation), or the train enters an area requiring different National Values.

3.18.2.8 The applicable set of National Values data shall be transmitted from the trackside on transition between areas requiring a different set of National Values.

3.18.2.8.1 When a new set of National Values becomes applicable its content shall always overwrite the corresponding National Values currently applicable regardless of the country or region identifier(s).

3.18.2.9 A previously received set of National Values which is not yet applicable shall be deleted if:

   - a new set of National Values is received, or

   - the ERTMS/ETCS on-board equipment is switched off (i.e., enters No Power mode).

3.18.2.10 If a National Value becomes invalid, i.e., a mismatch has been detected between the country or region identifier read from a balise group and the corresponding identifier(s) of the applicable set with which the National Value was received and stored, then it shall be deleted.

3.18.2.11 When a new set of National Values becomes applicable, any ongoing supervision involving an overwritten National Value of type time or distance shall continue, but using the corresponding value from the new set. However, the starting location or starting time shall remain unchanged.

### **3.18.3 Train Data**

3.18.3.1 Train Data can neither be provided nor modified by ERTMS/ETCS trackside equipment.

3.18.3.2 Before starting a mission in a mode different from Supervised Manoeuvre, the Train Data shall be acquired by the ERTMS/ETCS on-board equipment of a leading engine

   - a) Train category(ies)

b) Train length:

- Either the safe consist length

<!-- end of page 209 -->

   - Or any value that is obtained by means of a process which involves the driver or by means of a process or an external source with a safety level that could be lower than the one for the safe consist length

- c) Traction / brake parameters:

   - Traction model

   - Braking models (brake reaction time, brake build up time and speed dependent deceleration) or brake percentage

   - Brake position

   - On-board correction factors

   - Nominal rotating mass

- d) Maximum train speed

e) Loading gauge

   - f) Axle load category

   - g) Traction system(s) accepted by the engine

   - h) Train fitted with airtight system

   - i) List of National Systems available on-board

   - j) Intentionally deleted

   - k) Axle number

3.18.3.2.1 The Train Data may come from ERTMS/ETCS external sources (e.g. the Train Interface), from pre-configured values or from the driver.

3.18.3.2.2 Exception: The driver shall never be involved in the entry/ modification/validation of the Train Data “safe consist length”, “Traction system(s) accepted by the engine”, “List of National Systems available on-board” and “Axle number”.

3.18.3.2.3 The unit, range and resolution of the Train Data that can be directly entered by the driver shall be as specified in A.3.11.

3.18.3.2.4 In the clauses where the term “safe consist length” is not explicitly used, the term “train length” shall be interpreted as referring to the overall length of the train from one extremity to the other one. When no valid Train Data is available but the safe consist length is available, the term “train length” shall refer to the sum of the max safe consist lengths in front of and in rear of the engine respectively. When the safe consist length is captured as part of valid Train Data, the term “train length” shall refer to the max safe consist length in rear of the engine.

3.18.3.2.5 If the safe consist length information is acquired from an external source and it becomes unavailable while performing a mission, the ERTMS/ETCS on-board equipment shall nevertheless consider the Train Data “safe consist length” as unchanged.

<!-- end of page 210 -->

3.18.3.2.5.1 From the time the first Supervised Manoeuvre authorisation is received to the time the mission is either ended or continued in Non Leading mode, the train front end information shall still be derived from the safe consist length values in front or in rear of the engine, which are stored on-board as Train Data

3.18.3.2.5.2 Note: when no valid Train Data is stored on-board, the continuous availability of the safe consist length information is however necessary to send position reports with train integrity confirmed by external source or to start or continue a mission in Supervised Manoeuvre mode.

3.18.3.3 At standstill, it shall be possible for the driver to enter, modify and revalidate the Train Data that requires driver validation according to the specific train implementation.

3.18.3.3.1 In normal operation after the start of mission, if a train movement is detected while the driver is modifying or revalidating the Train Data, the ERTMS/ETCS on-board equipment shall trigger the brake command.

3.18.3.4 Following any validation of Train data/modification of valid Train Data when a communication session is already established or following the successful establishment of a communication session when valid Train Data are already available (e.g. when approaching a level 2 area or an accepting RBC area), the ERTMS/ETCS on-board equipment of the leading engine shall send the following set of Train Data to the RBC:

   - a) Train category(ies).

   - b) Train length.

   - c) Maximum train speed.

   - d) Loading gauge.

   - e) Axle load category.

   - f) Traction system(s) accepted by the engine.

   - g) Train fitted with airtight system.

   - h) List of National Systems available on-board

   - i) Axle number

3.18.3.4.1 The RBC shall acknowledge the reception of this set of Train Data.

3.18.3.4.2 In case the safe radio connection is lost before the acknowledgement is received, the Train Data shall be sent again once the safe radio connection has been re-established within the ongoing communication session.

3.18.3.5 If the safe consist length information is available and as long as the safe consist length in front of the engine, taking into account the side of the active cab which defines the front of the engine, is different from zero:

   - a) The ERTMS/ETCS on-board equipment shall consider that no valid Train Data is stored on-board

<!-- end of page 211 -->

   - b) By exception to 3.18.3.3, the entry, modification and revalidation of Train Data that requires driver validation shall not be possible

3.18.3.6 For modification of Train Data, which is/are affected by a change of input information from the ERTMS/ETCS on-board equipment external interface, refer to procedure "Changing Train Data from sources different from the driver" described in section 5.17.

3.18.3.7 In case the Train Data regarding train category, axle load category, loading gauge or traction system has been changed and the train is at standstill:

   - a) the location based information stored on-board shall be shortened to the current position of the train. Refer to appendix A.3.4 for the exhaustive list of information, which shall be shortened.

   - b) the stored MA, linking and track description, which have been received from the RBC after a level 2 transition or an RBC transition for a further location has been ordered, shall be deleted.

3.18.3.8 In case valid Train Data is available and the Train Data regarding train length has been increased or in case no valid Train Data is available but the Train Data “safe consist length” is available and has been increased in the direction opposite to the train orientation, the currently used track description, if any, shall be considered as unknown in rear of the former min safe rear end of the train.

3.18.3.9 In order to perform a mission in Supervised Manoeuvre mode with only the Train Data “safe consist length” available, the on-board shall be configured with default Train Data for all items of 3.18.3.2 except item b). From the time the first Supervised Manoeuvre authorisation is received to the time the mission is either ended or continued in Non Leading mode, the ERTMS/ETCS on-board equipment shall use these default Train Data and shall consider that no valid Train Data is stored on-board.

3.18.3.10 In Stand-By mode (only in level 2 when a communication session is already established) and from the time the first Supervised Manoeuvre request is sent to the time the mission is either ended or continued in Non Leading mode or to the time this Supervised Manoeuvre request is refused, the ERTMS/ETCS on-board equipment shall send the safe consist length information for Supervised Manoeuvre to the RBC following any modification of the Train Data “safe consist length” or when the safe consist length information acquired from an external source becomes available or becomes unavailable.

3.18.3.10.1 The RBC shall acknowledge the reception of the safe consist length information for Supervised Manoeuvre.

3.18.3.10.2 In case the safe radio connection is lost before the acknowledgement is received, the safe consist length information for Supervised Manoeuvre shall be sent again once the safe radio connection has been re-established within the ongoing communication session.

<!-- end of page 212 -->

### **3.18.4 Additional Data**

**3.18.4.1 Driver ID**

3.18.4.1.1 The driver ID shall be used to identify the responsible person for operating an active desk.

3.18.4.1.1.1 Note: This data is used for recording purposes only.

3.18.4.1.2 If allowed by a National value, it shall be possible for the driver to change driver ID while the train is running.

3.18.4.1.3 It shall be possible to enter driver ID also in a non-leading engine.

3.18.4.1.4 The unit, range and resolution of the driver ID shall be as specified in A.3.11.

**3.18.4.2 ERTMS/ETCS Level**

3.18.4.2.1 The driver shall have the possibility to enter the ERTMS/ETCS level during a start of a mission.

3.18.4.2.2 The ERTMS/ETCS level information is required for train operation except sleeping mode.

3.18.4.2.3 In normal operation after the start of mission the driver shall not have to select the ERTMS/ETCS level (all other level transitions are executed automatically).

3.18.4.2.4 For operational fallback situations: at standstill, the onboard equipment shall allow the driver to change the ERTMS/ETCS level.

3.18.4.2.4.1 Intentionally deleted.

3.18.4.2.5 If a table of supported levels given by trackside is stored on-board and is applicable, the selection of level by the driver shall be limited to those contained in this table. If no table of trackside supported levels is applicable, the driver can select any level within a default list configured on-board.

#### **3.18.4.3 Radio data: Radio Network type and GSM-R Radio Network identification / RBC contact information**

3.18.4.3.1 The ERTMS/ETCS on-board equipment shall store one valid RBC contact information (RBC identity and, if relevant, its telephone number) at a time, obtained from the last driver data entry, from the last received order to establish a session with an RBC (excluding RBC transition orders) or from the crossing of an RBC/RBC border (see clause 3.15.1.3.7).

3.18.4.3.1.1 Note: If a valid RBC contact information is available on-board, no driver data entry is needed to establish a connection to the RBC when performing a start of mission or after a manual level change to level 2.

<!-- end of page 213 -->

3.18.4.3.2 In level 2 only, at standstill, the ERTMS/ETCS on-board equipment shall offer the driver different means to select the RBC contact information, for details see step S3, section 5.4, Start of Mission procedure.

3.18.4.3.3 Intentionally deleted.

3.18.4.3.4 If the driver selects “Use of EIRENE short number” to contact the RBC and the communication session is successfully established, the ERTMS/ETCS on-board equipment shall store as valid RBC identity and telephone number, the RBC identity reported by EURORADIO and the EIRENE short number, respectively.

3.18.4.3.4.1 Note: If the short number is re-used by the ERTMS/ETCS on-board equipment (e.g. following a loss of safe radio connection) and does not direct to an RBC with the stored RBC ID, the connection will be terminated (EURORADIO functionality).

3.18.4.3.5 The unit, range and resolution of the RBC identity and telephone number shall be as specified in A.3.11.

3.18.4.3.6 At standstill, the ERTMS/ETCS on-board equipment shall offer the possibility to the driver to modify the Radio Network type and/or, if the stored Radio Network type is FRMCS+GSM-R or GSM-R, the GSM-R Radio Network ID.

3.18.4.3.6.1 The ERTMS/ETCS on-board equipment shall terminate the ongoing communication session(s), if any, and shall abort any ongoing attempts to establish a communication session, in case:

   - a) The driver has selected a new Radio Network type different from the previously stored one

   - b) The driver elects to modify the GSM-R Radio Network ID

3.18.4.3.6.2 If the driver has elected to modify the GSM-R Radio Network ID: As soon as the related safe connection is released, if any, the on-board equipment shall acquire an alphanumeric list of available and allowed GSM-R networks, based on a request to the GSM-R Mobile Terminal(s).If the driver selects a new GSM-R Radio Network ID from the proposed list, the registration of the GSM-R Mobile Terminal(s) to this new GSM-R Radio Network shall be ordered.

3.18.4.3.6.3 If not “unknown” the status of the RBC contact information shall be immediately set to “invalid”, as soon as:

   - a) The driver has selected a new Radio Network type different from the previously stored one

   - b) The driver has selected a new GSM-R Radio Network ID

#### **3.18.4.4 ETCS Identity**

3.18.4.4.1 The ETCS identity of an on-board equipment is made of a single identity number. The ETCS identity of an RBC, balise group, loop or RIU is composed of a country/region identity number and of an identity number within the country/region.

<!-- end of page 214 -->

3.18.4.4.2 All on-board equipments in service, balise groups marked as linked, RBC’s, RIU’s, and loops shall be assigned a unique ETCS identity within their respective group.

3.18.4.4.3 The assignment of (unique or not) ETCS identities to balise groups marked as unlinked is the sole responsibility of the entity in charge of the assignment of values (see SUBSET054), depending on the specific trackside implementation.

**3.18.4.5 Train Running Number**

3.18.4.5.1 During the Start of Mission, the ERTMS/ETCS on-board equipment of a leading engine shall acquire the train running number from driver input, from the RBC or from other ERTMS/ETCS external sources.

3.18.4.5.2 It shall be possible to enter train running number also in a non-leading engine.

3.18.4.5.3 It shall be possible to change the train running number while running, from driver input, from the RBC or from other ERTMS/ETCS external sources.

3.18.4.5.4 Following any entry/modification of the train running number when a communication session is already established or following the successful establishment of a communication session when valid train running number is already available, the ERTMS/ETCS on-board equipment shall send the train running number to the RBC.

3.18.4.5.4.1 Exception: if the train running number has been received from the RBC, it shall not be sent back to the RBC by the ERTMS/ETCS on-board equipment.

3.18.4.5.5 The unit, range and resolution of the train running number shall be as specified in A.3.11.

**3.18.4.6 Adhesion Factor**

3.18.4.6.1 The adhesion factor is used to adjust the emergency brake model of the train (see 3.13).

3.18.4.6.2 The adhesion factor may be changed while the train is running.

3.18.4.6.2.1 It shall be possible to update the adhesion factor from trackside and - if permitted by a National value - by the driver. If, following a change of National Values, the update of the adhesion factor is no more permitted to the driver, the adhesion factor previously modified by the driver to slippery rail shall immediately be reset to non slippery rail. Any trackside adhesion profile is not affected.

3.18.4.6.2.2 The adhesion factor shall be sent as profile data from trackside when needed.

3.18.4.6.2.3 The driver shall be informed whether the value of the adhesion factor is “slippery rail”.

3.18.4.6.3 The selection of the adhesion value from trackside or by driver entry shall be limited to the options slippery rail/ non slippery rail.

3.18.4.6.3.1 Intentionally deleted.

3.18.4.6.4 The default value for the adhesion factor shall be the highest value (i.e. not slippery rail).

3.18.4.6.5 Intentionally deleted.

<!-- end of page 215 -->

### **3.18.5 Date and Time**

3.18.5.1 Each ERTMS/ETCS on-board equipment shall be able to provide the date (day, month, year) and time (hour, minute, second) in Universal Time Co-ordinated (UTC) and Local Time.

3.18.5.2 The local time shall be presented to the driver, while the UTC shall be used for the juridical data.

3.18.5.3 Deleted.

**3.18.6 Data view**

3.18.6.1 Outside the context of data entry, the ERTMS/ETCS on-board equipment shall offer the possibility to the driver to view the driver ID, the train running number, the RBC contact information, the Radio Network type, the GSM-R Radio Network ID, the Virtual Balise Cover(s) and the Train Data either modifiable by the driver or modifiable by other ERTMS/ETCS external sources.

3.18.6.2 Only valid data shall be presented to the driver.
