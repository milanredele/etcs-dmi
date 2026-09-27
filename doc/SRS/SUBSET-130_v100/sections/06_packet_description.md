# **6. PACKET DESCRIPTION**

## **6.1 List of Packets**

|**Packet**<br>**Number**|**Packet Name**|**Source**|**Sink**|**Transmitting**<br>**cycle [ms]**|**Data Class [Ref 10]**|**Timeout [ms]**|
|---|---|---|---|---|---|---|
|0|ATO_ETCS_Status|ATO|ETCS|100|Process Data|1000|
|1|ATO_ETCS_DMI|ATO|ETCS|100|Process Data|1000|
|2|ATO_ETCS_Data_Entry_Need|ATO|ETCS|NA|Message Data|-|
|3|ATO_ETCS_Data_Entry_Request|ATO|ETCS|NA|Message Data|-|
|4|ATO_ETCS_Data_View_Values|ATO|ETCS|NA|Message Data|-|
|5|ETCS_ATO_Static|ETCS|ATO|1000|Process Data|3000|
|6|ETCS_ATO_Dynamic|ETCS|ATO|200|Process Data|1000|
|7|ETCS_ATO_Driver_Inputs|ETCS|ATO|100..200|Process Data|1000|
|8|ETCS_ATO_Data_Entry_Values|ETCS|ATO|NA|Message Data|-|
|9|ETCS_ATO_Data_Entry_Flag|ETCS|ATO|NA|Message Data|-|
|10|ETCS_ATO_Data_View_Values_<br>Request|ETCS|ATO|NA|Message Data|-|
|11|ETCS_ATO_BRAKE_DECELERA<br>TIONS|ETCS|ATO|200|Process Data|1000|

#### **Table 2** Packet summary

6.1.1.1 The packets for which no transmitting cycle is defined in Table 2 are sent event-based.

6.1.1.2 The packet numbers defined in Table 2 correspond to NID_PACKET definition given in [Ref 10]. This interface uses Slot 1 (see [Ref 10]).

<!-- end of page 10 -->

## **6.2 User Data**

### **6.2.1 Packets: ATO-OB to ETCS-OB**

6.2.1.1 Packet Number 0: ATO_ETCS_Status

||**_Packet N_**|**_umber_**<br>**_0_**||||
|---|---|---|---|---|---|
|**Item**||**Variable Name**|**Description**|**Data Type **|**Resolution/Formula**|
||Bit|ATO_INFO_SET|ATO information BITSET|BITSET8||
|1|0|Q_AD_MODE_REQUEST|Qualifier to request the ETCS AD<br>Mode.||**Values:**<br>0 = AD Mode not requested|
||||||1 = AD Mode requested|
|2|1..7|Spare||||

**Table 3** Packet Number 0: ATO_ETCS_Status

#### 6.2.1.2 Packet Number 1: ATO_ETCS_DMI

||**_Packet N_**|**_umber_**<br>**_1_**||||
|---|---|---|---|---|---|
|**Item**||**Variable Name**|**Description**|**Data Type **|**Resolution/Formula**|
||Bit|ATO_DMI_INFO|DMI Indicators BITSET|BITSET16||
|1|0..2|M_ATOSTATUS|ATO status to be displayed.||**Values:**<br>0 = ATO Selected<br>1 = ATO ready for engagement<br>2 = ATO Engaged<br>3 = ATO Disengaging<br>4 = ATO Failure<br>5 - 7 = spare|
|2|3..4|Q_STOPACCURACY|Stopping accuracy information to<br>be displayed.||**Values:**<br>0 = No stopping accuracy indication<br>1 = Accurate stop<br>2 = Undershoot<br>3 = Overshoot|
|3|5..6|Q_DWELLTIME_INFO|Dwell Time information to be<br>displayed.||**Values:**<br>0 = No Dwell Time indication<br>1 = Remaining Dwell Time<br>2 = Train Hold<br>3 = Spare|
|4|7..9|Q_DOORINFO|Train door information to be<br>displayed.||**Values:**<br>0 = No information<br>1 = Request driver to close doors<br>2 = Request driver to open doors on<br>both sides<br>3 = Request driver to open right<br>doors<br>4 = Request driver to open left doors<br>5 = Doors are open<br>6 = Doors are closed<br>7 = Doors are beingclosed byATO|
|5|10..11|Q_SKIPSTP|Skip Stopping Point information to<br>be displayed.||**Values:**<br>0 = No information<br>1 = Skip Stopping Point requested<br>by the driver<br>2 = Skip Stopping Point requested<br>by the ATO-TS<br>3 = SkipStoppingPoint Inactive|

<!-- end of page 11 -->

||**_Packet Number_**<br>**_1_**||||
|---|---|---|---|---|
|**Item**|**Variable Name**|**Description**|**Data Type **|**Resolution/Formula**|
|6|12<br>Q_COASTING|Coasting indication to be displayed.||**Values:**<br>0 = No information<br>1 = Coastingadvice|
|7|13<br>Q_WARNINGSOUND|Qualifier indicating if the ATO-OB is<br>requesting<br>the<br>ETCS-OB<br>to<br>produce a warning sound.||**Values:**<br>0 = Warning sound not requested<br>1 = Warningsound requested|
|8|14..15<br>Spare||||
|9|T_DWELLTIME|Remaining Dwell Time to be<br>displayed.|UINT16|**Resolution:**1 s<br>**Special value:**<br>65535 = no remaining Dwell Time<br>indication|
|10|V_TAS|Target<br>Advice<br>Speed<br>to<br>be<br>displayed.|UINT16|**Resolution:**1 cm/s<br>**Special values:**<br>16668 - 65534 = spare<br>65535 = No Target Advice Speed<br>indication|
|11|D_NEXTADVICE|Distance to next advice change to<br>be displayed.|UINT32|**Resolution:**1 cm<br>**Special value:**<br>(2<sup>32</sup>-1)=No information|
|12|T_NEXT_STP_ARRIVAL_TIME|Arrival time to the next Stopping<br>Point or Stopping Points to be<br>skipped to be displayed It is the<br>number of seconds from the<br>reference time 00:00:00 in local<br>time.|UINT32|**Resolution:**1 s<br>**Special value:**<br>86400 … interpreted by ECTS-OB<br>(DMI) as “24:00:00”<br>86401 - (2<sup>32</sup>-2) = spare<br>(2<sup>32</sup>-1)=No information|
|13|L_TEXT_STP|Length of text string in bytes for the<br>name of the next Stopping Point or<br>StoppingPoints to be skipped.|UINT8|**Special values:**<br>0 = No information to display|
|(L_TEXT_STP) - times<br>14|X_TEXT_STP (k)|Name of the next Stopping Point or<br>Stopping Points to be skipped to be<br>displayed.|UINT8|See [Ref 8], Section §8.1.120.|
|15|N_STPDISTANCE_ITER|Number of “distance to the next<br>Stopping Point or Stopping Point to<br>be skipped” elements.|UINT8|**Special values:**<br>0 = No information to display|
|(N_STPDISTANCE_ITER) - times<br>16|D_STPDISTANCE (l)|Distance to the Stopping Point or<br>Stopping Point to be skipped to be<br>displayed.|UINT32|**Resolution:**1 cm|

**Table 4** Packet Number 1: ATO_ETCS_DMI

<!-- end of page 12 -->

6.2.1.3 Packet Number 2: ATO_ETCS_Data_Entry_Need

||**_Packet_**|**_Number_**<br>**_2_**||||
|---|---|---|---|---|---|
|**Item**||**Variable Name**|**Description**|**Data Type **|**Resolution/Formula**|
||Bit|ATO_Data_Entry_Need||BITSET8||
|1|0|Q_ATO_DATAENTRY|Qualifier indicating if the ATO-OB<br>needs Specific ATO Data or not.||**Values:**<br>0 = No Specific ATO Data needed.|
||||||1 = Specific ATO Data needed.|
|2|1..7|Spare||||

**Table 5** Packet Number 2: ATO_ETCS_Data_Entry_Need

6.2.1.4 Packet Number 3: ATO_ETCS_Data_Entry_Request

|**_Pa_**|**_cket N_**|**_umber_**<br>**_3_**||||
|---|---|---|---|---|---|
|**Ite**|**m**|**Variable Name**|**Description**|**Data Type**|**Resolution/Formula**|
|1||N_DER_ITER|Number of Specific ATO Data requested.|UINT8|Special values:<br>0 = “End of Specific ATO Data Entry”<br>16 - 255 = spare|
||2|NID_DATA_ATO (k)|Identifier of the Specific ATO Data.|UINT8|Numbers|
||3|L_CAPTION (k)|See [Ref 8] §8.1.8|UINT8|See [Ref 8] §8.1.8|
|(L_CAPTION (k)) - times|4|X_CAPTION (k, l)|See [Ref 8] §8.1.119|UINT8|See [Ref 8] §8.1.119|
||5|L_VALUE (k)|See [Ref 8] §8.1.12|UINT8|See [Ref 8] §8.1.12|
|(N_DER_ITER) - times<br>(L_VALUE (k)) - times|6|X_VALUE (k, m)|See [Ref 8] §8.1.121|UINT8|See [Ref 8] §8.1.121|
||7|N_DKV_ITER (k)|Number of dedicated keyboard values.|UINT8|Special values:<br>0 = there is no dedicated keyboard|
|s|8|L_VALUE (k, n)|See [Ref 8] §8.1.12|UINT8|See [Ref 8] §8.1.12|
|(N_DKV_ITER) - time|(L_VALUE (k,n)) - times<br>9|X_VALUE (k, n, o)|See [Ref 8] §8.1.121|UINT8|See [Ref 8] §8.1.121|

**Table 6** Packet Number 3: ATO_ETCS_Data_Entry_Request

<!-- end of page 13 -->

6.2.1.5 Packet Number 4: ATO_ETCS_Data_View_Values

|**_Pac_**|**_ket Number_**<br>**_4_**||||
|---|---|---|---|---|
|**Item**|**Variable Name**|**Description**|**Data Type **|**Resolution/Formula**|
|1|N_DVV_ITER|Number of Data View values.|UINT8|**Special values:**<br>0 = “No Specific ATO Data values”<br>16 - 255 = spare|
|2|NID_DATA_ATO (k)|Identifier of the Specific ATO Data.|UINT8|Numbers|
|3|L_CAPTION(k)|See[Ref 8] §8.1.8|UINT8|See[Ref 8] §8.1.8|
|_ITER) - times<br>(L_CAPTION (k)) - times<br>4|X_CAPTION (k, l)|See [Ref 8] §8.1.119|UINT8|See [Ref 8] §8.1.119|
|DVV<br>5|L_VALUE(k)|See[Ref 8] §8.1.12|UINT8|See[Ref 8] §8.1.12|
|(N_<br>(L_VALUE (k)) - times<br>6|X_VALUE (k, m)|See [Ref 8] §8.1.121|UINT8|See [Ref 8] §8.1.121|

**Table 7** Packet Number 4: ATO_ETCS_Data_View_Values

<!-- end of page 14 -->

### **6.2.2 Packets: ETCS-OB to ATO-OB**

6.2.2.1 Packet Number 5: ETCS_ATO_Static

|**_P_**|**_acket Number_**<br>**_5_**||||
|---|---|---|---|---|
|**Item**|**Variable Name**|**Description**|**Data Type **|**Resolution/Formula**|
||Bit<br>ETCS_DATA|ETCS valid dataqualifiers set|BITSET8||
|1|0<br>Q_TRAIN_DATA_<br>VALID|Qualifier indicating if the ETCS Train Data are<br>valid.||**Values:**<br>0 = ETCS Train Data not valid<br>1 = ETCS Train Data valid|
|2|1<br>Q_OPERATIONA<br>L_DATA_VALID|Qualifier indicating if the ETCS Operational<br>Data (NID_OPERATIONAL and DRIVER_ID)<br>are valid.||**Values:**<br>0 = ETCS Operational Data not valid<br>1 = ETCS Operational Data valid|
|3|2..7<br>Spare||||
|4|NID_ENGINE|See [Ref 4]§7.5.1.88|UINT32|See [Ref 4]§7.5.1.88|
|5|NID_ANTENNA|Identification of the antenna.|UINT8|**Values**:<br>0 = antenna 1<br>1 = antenna 2<br>2 = antenna 3<br>3 = antenna 4<br>**Special Values**:<br>4 .. 255|
|6|D_ANTENNA|Distance from antenna to the train front end.|UINT16|**Resolution:**1 cm|
|7|N_ANTENNA_ITER|Number of additional antennas installed on-<br>board|UINT8|**Values:**<br>0 .. 3<br>**Special Values:**<br>4 .. 255|
|ANTENNA_ITER)-times<br>8|<br>NID_ANTENNA(i)|Identification of the additional antenna|UINT8|**Values:**<br>0 = antenna 1<br>1 = antenna 2<br>2 = antenna 3<br>3 = antenna 4<br>**Special Values:**<br>4 .. 255|
|(N_<br>9|<br>D_ANTENNA(i)|Distance from additional antenna to the train<br>front end.|UINT16|**Resolution:**1 cm|
|10|L_TRAIN|[If Q_TRAIN_DATA_VALID = 1]<br>See [Ref 4]§7.5.1.56|UINT16|See [Ref 4] §7.5.1.56|
|11|V_MAXTRAIN|[If Q_TRAIN_DATA_VALID = 1]<br>See [Ref 4]§7.5.1.160|UINT8|See [Ref 4] §7.5.1.160|
|12|NC_CDTRAIN|[If Q_TRAIN_DATA_VALID = 1]<br>See [Ref 4]§7.5.1.82.2|UINT8|See [Ref 4] §7.5.1.82.2|
|13|NC_TRAIN|[If Q_TRAIN_DATA_VALID = 1]<br>See[Ref 4] §7.5.1.84|BITSET16|See [Ref 4] §7.5.1.84|
|14|M_AXLELOADCAT|[If Q_TRAIN_DATA_VALID = 1]<br>See[Ref 4] §7.5.1.62|UINT8|See [Ref 4] §7.5.1.62|
|15|M_NOM_ROT_MASS|[If Q_TRAIN_DATA_VALID = 1]<br>See [Ref 5] §4.2.4.2|UINT8|See [Ref 5] §4.2.4.2|
|16|M_BRAKE_PERCENTAGE_<br>ATO|<br>[If Q_TRAIN_DATA_VALID = 1]<br>Brake percentage from ETCS Train Data.|UINT8|**Resolution:**1 %<br>**Special Values:**<br>251 - 254 = spare<br>255 = Not relevant for trains on<br>which the braking models are<br>captured as Train Data|

<!-- end of page 15 -->

|**_P_**|**_acket Number_**<br>**_5_**||||
|---|---|---|---|---|
|**Item**|**Variable Name**|**Description**|**Data Type **|**Resolution/Formula**|
|17|M_BRAKE_POSITION_ATO|[If Q_TRAIN_DATA_VALID = 1]<br>Brake position from ETCS Train Data.|UINT8|**Values:**<br>0 = Passenger train in P<br>1 = Freight train in P<br>2 = Freight train in G<br>**Special Values:**<br>3 - 255 = spare|
|18|Q_INDEX_GAMMA_CONF|[If Q_TRAIN_DATA_VALID = 1]<br>Qualifier indicating the set of full service<br>braking models preconfigured in the ETCS-<br>OB, which are currently applicable according<br>to the capture of the ETCS Train Data.|UINT8|**Special Values:**<br>255 = Not relevant for trains on<br>which the brake percentage is<br>acquired as part of Train Data and<br>the conversion model is applicable|
|19|NID_OPERATIONAL|[If Q_OPERATIONAL_DATA_VALID = 1]<br>See[Ref 4] §7.5.1.92|BCD32|See [Ref 4] §7.5.1.92|
|20|DRIVER_ID|[If Q_OPERATIONAL_DATA_VALID = 1]<br>See [Ref 5]§4.2.3.7 and [Ref 4]§A.3.11|STRING16|See [Ref 5] §4.2.3.7<br>See [Ref 4]§A.3.11|

**Table 8** Packet Number 5: ETCS_ATO_Static

<!-- end of page 16 -->

6.2.2.2 Packet Number 6: ETCS_ATO_Dynamic

|**_Pack_**|**_et Numbe_**|**_r_**<br>**_6_**||||
|---|---|---|---|---|---|
|**Item**||**Variable Name**|**Description**|**Data Type **|**Resolution/Formula**|
||Bit|ETCS_ATO_INFO_SET|ETCS Information BITSET|BITSET8||
|1|0|M_ADHESION_DRIVER|Adhesion factor set by the driver.||**Values:**<br>0 = slippery rail is set by the<br>driver<br>1 = slippery rail is not set by<br>the driver|
|2|1|Q_APPCOND|Qualifier<br>indicating<br>if<br>the<br>ETCS<br>applicable<br>conditions<br>for<br>ATO<br>Operational are fulfilled.||**Values:**<br>0 = ETCS applicable<br>conditions for ATO<br>Operational are not fulfilled<br>1 = ETCS applicable<br>conditions for ATO<br>Operational are fulfilled|
|3|2..3|Q_RC|Factor to indicate whether a movement<br>in the direction of the train orientation<br>corresponds to an increase or a<br>decrease of the position counter.||**Values:**<br>0 = unknown (no train<br>orientation)<br>1 = Increase (factor = 1)<br>2 = Decrease (factor = -1)|
|4|4..7|Spare||||
|**Positionin**|**g Inform**|**ation**||||
||Bit|POSITION_REPORT_SET|Position Report BITSET|BITSET8||
|5|0..1|Q_DIRSOLR|See[Ref 5] §4.2.3.5||See[Ref 5] §4.2.3.5|
|6|2..3|Q_DSOLR|See [Ref 5]§4.2.3.5||See [Ref 5]§4.2.3.5|
|7|4..7|Spare||||
|8|N_LO|C_REF|Value of the position counter at the<br>moment the data of the packet is<br>determined.|INT32|**Resolution:**1 cm<br>**Special value:**<br>(2<sup>31</sup>-1) = spare<br>Note: the “spare” value is used<br>as a special value in other<br>variables which depend on this<br>counter (e.g.<br>N_LOC_REFBALISE).|
|9|T_LO|C_REF|Time at which the position counter is<br>determined.|UINT32|**Resolution:**1 ms<br>**Special value:**<br>(2<sup>32</sup>-1)=unknown|
|10|N_LO|C_REFBALISE|Value of the position counter at the<br>center of balise used as location<br>reference by the ETCS on-board, i.e.<br>the reference balise of the ETCS SOLR<br>or the balise duplicating this one, see<br>[Ref 4]§3.16.2.3.3.|INT32|**Resolution:**1 cm<br>**Special value:**<br>(2<sup>31</sup>-1) = unknown|
|11|NID_A|CTIVE_ANTENNA_SOLR|Identification of the antenna active<br>when the reference balise of the ETCS<br>SOLR was passed|UINT8|**Values:**<br>0 = antenna 1<br>1 = antenna 2<br>2 = antenna 3<br>3 = antenna 4<br>**Special Values:**<br>4 - 255 = spare|

<!-- end of page 17 -->

|**_Pack_**<br>**Item**|**_et Number_**<br>**_6_**<br>**Variable Name**|**Description**|**Data Type **|**Resolution/Formula**|
|---|---|---|---|---|
|12|NID_REFBALISE|Identification of the balise used as<br>location reference by the ETCS on-<br>board, i.e. the reference balise of the<br>ETCS SOLR or the balise duplicating<br>this one, see [Ref 4]  §3.16.2.3.3.|BITSET32|**Values:**<br>Bit00 to bit02 = N_PIG as<br>defined in [Ref 4] § 7.5.1.81<br>Bit03 to bit16 = NID_BG as<br>defined in [Ref 4] § 7.5.1.85<br>Bit17 to bit26 = NID_C as<br>defined in [Ref 4] § 7.5.1.86<br>Bit27 to bit31 = not relevant<br>**Special values:**<br>(2<sup>32</sup>-1) = unknown|
|13|T_LOC_REFBALISE|Time at which the position counter was<br>equal to N_LOC_REFBALISE.|UINT32|**Resolution:**1 ms<br>**Special value:**<br>(2<sup>32</sup>-1)=unknown|
|14|N_LOC_BALISERUNOVER1|Value of the position counter at the last<br>balise passed.|INT32|<br>**Resolution:**1 cm<br>**Special value:**<br>(2<sup>31</sup>-1)=unknown|
|15|NID_ACTIVE_ANTENNA_BRO1|Identification of the antenna active<br>when the last balise was passed|UINT8|**Values:**<br>0 = antenna 1<br>1 = antenna 2<br>2 = antenna 3<br>3 = antenna 4<br>**Special Values:**<br>4-255=spare|
|16|NID_BALISERUNOVER1|Identification of the last balise passed.|BITSET32|<br>**Values:**<br>Bit00 to bit02 = N_PIG as<br>defined in [Ref 4] § 7.5.1.81<br>Bit03 to bit16 = NID_BG as<br>defined in [Ref 4] § 7.5.1.85<br>Bit17 to bit26 = NID_C as<br>defined in [Ref 4] § 7.5.1.86<br>Bit27 to bit31 = not relevant<br>**Special values:**<br>(2<sup>32</sup>-1)= unknown|
|17|T_LOC_BALISERUNOVER1|Time at which the position counter was<br>equal to N_LOC_BALISERUNOVER1.|UINT32|**Resolution:**1 ms<br>**Special value:**<br>(2<sup>32</sup>-1)=unknown|
|18|N_LOC_BALISERUNOVER2|Value of the position counter at the<br>balise<br>passed<br>before<br>NID_BALISERUNOVER1.|INT32|<br>**Resolution:**1 cm<br>**Special value:**<br>(2<sup>31</sup>-1) = unknown|
|19|NID_ACTIVE_ANTENNA_BRO2|Identification of the antenna active<br>when<br>the<br>last<br>balise<br>before<br>NID_BALISERUNOVER1 was passed|UINT8|**Values:**<br>0 = antenna 1<br>1 = antenna 2<br>2 = antenna 3<br>3 = antenna 4<br>**Special Values:**<br>4 - 255 = spare|
|20|NID_BALISERUNOVER2|Identification of the balise passed<br>before NID_BALISERUNOVER1.|BITSET32|**Values:**<br>Bit00 to bit02 = N_PIG as<br>defined in [Ref 4] § 7.5.1.81<br>Bit03 to bit16 = NID_BG as<br>defined in [Ref 4] § 7.5.1.85<br>Bit17 to bit26 = NID_C as<br>defined in [Ref 4] § 7.5.1.86<br>Bit27 to bit31 = not relevant<br>**Special values:**<br>(2<sup>32</sup>-1) = unknown|

<!-- end of page 18 -->

|**_Pack_**<br>**Item**|**_et Number_**<br>**_6_**<br>**Variable Name**|**Description**|**Data Type **|**Resolution/Formula**|
|---|---|---|---|---|
|21|T_LOC_BALISERUNOVER2|Time at which the position counter was<br>equal to N_LOC_BALISERUNOVER2.|UINT32|**Resolution:**1 ms<br>**Special value:**<br>(2<sup>32</sup>-1) = unknown|
|22|L_UNCERTAINTY_OVERREADING|Over-reading amount of the confidence<br>interval to the train position referred to<br>the SOLR.|UINT32|**Resolution:**1 cm<br>**Special values:**<br>(2<sup>32</sup>-1)= unknown|
|23|L_UNCERTAINTY_UNDERREADIN<br>G|Under-reading<br>amount<br>of<br>the<br>confidence interval to the train position<br>referred to the SOLR.|UINT32|**Resolution:**1 cm<br>**Special values:**<br>(2<sup>32</sup>-1) = unknown|
|**Supervisio**|**n Information**||||
|24|M_MODE|See[Ref 4] §7.5.1.72|UINT8|See[Ref 4] §7.5.1.72|
|25|N_LOC_EBI|[If M_MODE is equal to FS, AD or OS]<br>Estimated value of the position counter<br>at the closest Emergency Brake<br>supervision limit for the current speed<br>of the train.|INT32|**Resolution:**1 cm<br>**Special value:**<br>(2<sup>31</sup>-1) = No EBI supervised by<br>the ETCS-OB.|
|26|A_GRADIENT|[If M_MODE is equal to FS, AD or OS]<br>Applicable<br>value<br>of<br>acceleration/deceleration due to the<br>gradient from the maximum safe front<br>end of the train.|INT16|**Resolution:**1 mm/s<sup>2</sup><br>**Values:**<br>-2500 … +2500 = Acceleration<br>(negative, declining section)<br>/Deceleration (positive,<br>inclining section) due to<br>gradient<br>**Special Values:**<br>-32768 …  -2501 = spare<br>2501 … 32766 = spare<br>32767 = unknown|
|27|N_GRAD_ITER|[If M_MODE is equal to FS, AD or OS]<br>Number of gradient changes.|UINT8|**Special values:**<br>0 = no gradient information<br>available<br>52 - 255 = spare|
|28|N_LOC_GRADCHANGE (k)|[If M_MODE is equal to FS, AD or OS]<br>Estimated value of the position counter<br>at the A_GRADIENT change.|INT32|**Resolution:**1 cm<br>**Special value:**<br>(2<sup>31</sup>-1) = not allowed|
|(N_GRAD_ITER)-times<br>29|A_GRADIENT (k)|[If M_MODE is equal to FS, AD or OS]<br>Applicable<br>value<br>of<br>acceleration/deceleration due to the<br>gradient from the estimated value of the<br>position counter at the A_GRADIENT<br>change.|INT16|**Resolution:**1 mm/s<sup>2</sup><br>**Values:**<br>-2500 … +2500 = Acceleration<br>(negative, declining section)<br>/Deceleration (positive,<br>inclining section) due to<br>gradient<br>**Special values:**<br>-32768 …  -2501 = spare<br>2501 – 32766 = spare<br>32767 = close the gradient<br>profile|
|30|A_MAXREDADH|[If M_MODE is equal to FS, AD or OS]<br>Maximum deceleration due to reduced<br>adhesion conditions from the maximum<br>safe front end of the train.|UINT16|**Resolution:**1 mm/s2<br>**Special** **value**:<br>65535 = no maximum<br>deceleration|

<!-- end of page 19 -->

|**_Pack_**<br>**Item**|**_et Number_**<br>**_6_**<br>**Variable Name**|**Description**|**Data Type **|**Resolution/Formula**|
|---|---|---|---|---|
|31|N_ADHE_ITER|[If M_MODE is equal to FS, AD or OS]<br>Number of A_MAXREDADH changes.|UINT8|**Special values:**<br>0 = no reduced adhesion<br>conditions announced<br>22 - 255 = spare|
|times<br>32|N_LOC_ADHCHANGE (l)|[If M_MODE is equal to FS, AD or OS]<br>Estimated value of the position counter<br>at the A_MAXREDADH change.|INT32|**Resolution:**1 cm<br>**Special value:**<br>(2<sup>31</sup>-1) = not allowed|
|(N_ADHE_ITER)- <br>33|A_MAXREDADH (l)|[If M_MODE is equal to FS, AD or OS]<br>Maximum deceleration due to reduced<br>adhesion conditions from the estimated<br>value of the position counter at the<br>A_MAXREDADH change..|UINT16|**Resolution:**1 mm/s2<br>**Special** **value**:<br>65534 = close the adhesion<br>profile<br>65535 = no maximum<br>deceleration|
|34|V_MRSP|[If M_MODE is equal to FS, AD or OS]<br>Speed from the minimum safe front end<br>of the train.|UINT16|**Resolution:**1 cm/s<br>**Special values:**<br>16668 - 65534 = spare<br>65535 = unknown|
|35|N_MRSP_ITER|[If M_MODE is equal to FS, AD or OS]<br>Number of MRSP iterations.<br>See [Ref 4]§3.13.7.2|UINT8|**Special values:**<br>51 - 255 = spare|
|- times<br>36|N_LOC_MRSP (p)|[If M_MODE is equal to FS, AD or OS]<br>Estimated value of the position counter<br>at the MRSP change including train<br>length compensation.|INT32|**Resolution:**1 cm<br>**Special values:**<br>(2<sup>31</sup>-1) = not allowed|
|(N_MRSP_ITER)<br>37|V_MRSP (p)|[If M_MODE is equal to FS, AD or OS]<br>Speed from the estimated value of the<br>position counter at the MRSP change.|UINT16|**Resolution:**1 cm/s<br>**Special values:**<br>16668 - 65534 = spare<br>65535 = Non numerical value<br>telling that the MRSP ends at<br>N_LOC_MRSP(n).|
|38|N_LOC_EOALOA|[If M_MODE is equal to FS, AD or OS]<br>Estimated value of the position counter<br>at<br>the<br>EOA<br>or<br>LOA<br>(including<br>temporary EoAs) currently supervised<br>bythe ETCS-OB.|INT32|**Resolution:**1 cm<br>**Special value:**<br>(2<sup>31</sup>-1) = no EOA nor LOA<br>supervised by ETCS|
|39|V_EOALOA|[If M_MODE is equal to FS, AD or OS]<br>Permitted speed at the EOA or LOA<br>currently supervised by the ETCS-OB|UINT16|**Resolution:**1 cm/s<br>**Special values:**<br>16668 - 65534 = spare<br>65535 = no EOA nor LOA<br>supervised by ETCS|
|40|N_LOC_SVL|[If M_MODE is equal to FS, AD or OS]<br>Estimated value of the position counter<br>at the supervised location (SvL).|INT32|<br>**Resolution:**1 cm<br>**Special value:**<br>(2<sup>31</sup>-1) = No SvL supervised by<br>ETCS|
|41|T_TRACTION|[If M_MODE is equal to FS, AD or OS]<br>Time during which the traction effort is<br>still present after the Emergency brake<br>intervention. If conversion model is<br>used, this variable is to be used only<br>when braking to standstill. See [Ref 4]<br>§3.13.9.3.2.2<br>a)<br>but<br>without<br>the<br>expected brake build up time reduction<br>as per A.3.12 of [Ref 4].|UINT16|<br>**Resolution:**10 ms|

<!-- end of page 20 -->

|**_Pack_**<br>**Item**|**_et Number_**<br>**_6_**<br>**Variable Name**|**Description**|**Data Type **|**Resolution/Formula**|
|---|---|---|---|---|
|42|T_TRACTION_SPEED|[If M_MODE is equal to FS, AD or OS]<br>Time during which the traction effort is<br>still present after the Emergency brake<br>intervention when braking to a target<br>speed > 0 km/h if conversion model is<br>used. See [Ref 4] §3.13.9.3.2.2 a) but<br>without the expected brake build up<br>time reduction asper A.3.12 of [Ref 4].|UINT16|**Resolution:**10 ms<br>**Special value:**<br>65535 = Not relevant in case<br>conversion model is not used|
|43|T_BE_REACT|[If M_MODE is equal to FS, AD or OS]<br>Safe brake reaction time during which<br>the braking effort is not yet present after<br>the Emergency brake intervention. It is<br>the interval between the command of<br>the brake by the on-board and the<br>moment the brake force starts to build<br>up. See [Ref 4]§3.13.6.2.2.3.|UINT16|**Resolution:**10 ms|
|44|T_BEREM|[If M_MODE is equal to FS, AD or OS]<br>Remaining time during which the<br>traction effort is not present until the full<br>application of the braking effort is<br>reached. If conversion model is used,<br>this variable is to be used only when<br>braking to standstill. See [Ref 4]<br>§3.13.9.3.2.2 b) but without the safe<br>brake build up reduction as per A.3.12<br>of [Ref 4].|UINT16|**Resolution:**10 ms|
|45|T_BEREM_SPEED|<br>[If M_MODE is equal to FS, AD or OS]<br>Remaining time during which the<br>traction effort is not present until the full<br>application of the braking effort is<br>reached when braking to a target speed<br>> 0 km/h if conversion model is used.<br>See [Ref 4] §3.13.9.3.2.2 b) but without<br>the safe brake build up reduction as per<br>A.3.12 of [Ref 4].|UINT16|**Resolution:**10 ms<br>**Special value:**<br>65535 = Not relevant in case<br>conversion model is not used|
|46|V_PERMITTED|[If M_MODE is equal to FS, AD or OS]<br>Permitted speed at the current location<br>(P).|UINT16|**Resolution:**1 cm/s<br>**Special values:**<br>16668 - 65534 = spare<br>65535 = unknown|
|47|V_RELEASE_ATO|[If M_MODE is equal to FS, AD or OS]<br>Current release speed of the ETCS-<br>OB.|UINT16|**Resolution:**1 cm/s<br>**Special values:**<br>16668 - 65534 = spare<br>65535 = no release speed<br>available|
|48|N_LOC_RSM|[If M_MODE is equal to FS, AD or OS]<br>Estimated value of the position counter|INT32|**Resolution:**1 cm<br>**Special value:**<br>|
|||at the RSM start location.||(2<sup>31</sup>-1) = no release speed<br>|
|**Speed an**|**d Acceleration Information**|||available|
|49|V_EST|Current<br>estimated<br>train<br>speed<br>calculated by ETCS Odometry.|UINT16|**Resolution:**1 cm/s<br>**Special values:**<br>16668 - 65534 = spare<br>65535 = unknown|
|50|V_DELTA0|Compensation of the inaccuracy of the<br>speed measurement. See [Ref 4]<br>§3.13.9.3.2.10.|UINT16|**Resolution:**1 cm/s<br>**Special values:**<br>16668 - 65534 = spare<br>65535 = unknown|

<!-- end of page 21 -->

|**_Pack_**|**_et Number_**<br>**_6_**||||
|---|---|---|---|---|
|**Item**|**Variable Name**|**Description**|**Data Type **|**Resolution/Formula**|
|51<br>**Linking In**|A_EST<br>**formation**<br>|Current estimated train acceleration<br>calculated by ETCS-OB.<br>|INT16<br>|**Resolution:**1 mm/s<sup>2</sup><br>**Values:**<br>-5000 … +5000 = Deceleration<br>(negative)/Acceleration<br>(positive)<br>**Special Values:**<br>-32768 …  -5001 = spare<br>5001 … 32766 = spare<br>**Special values:**<br>32767 = unknown<br>|
|52|N_LINK_ITER|Number of next linked Balise Groups<br>announced.|UINT8|**Special values:**<br>31 - 255 = spare (See [Ref 6]<br>§4.3.2.1.1 i)).|
|53|N_LOC_LINKNBG (q)|Estimated value of the position counter<br>at the linked Balise Group. The position<br>is referenced to the balise with the<br>N_PIG = 0.|INT32|**Resolution:**1 cm<br>**Special values:**<br>(2<sup>31</sup>-1) = spare|
|(N_LINK_ITER) - times<br>54|NID_LINKNBG (q)|Identification of the linked Balise<br>Group. N_PIG is always 0.|BITSET32|**Values:**<br>Bit00 to bit02 = N_PIG as<br>defined in [Ref 4] § 7.5.1.81<br>Bit03 to bit16 = NID_BG as<br>defined in [Ref 4] § 7.5.1.85<br>Bit17 to bit26 = NID_C as<br>defined in [Ref 4] § 7.5.1.86<br>Bit27 to bit31 = not relevant<br>**Special values:**<br>(2<sup>32</sup>-1) = unknown|

**Table 9** Packet Number 6: ETCS_ATO_Dynamic

#### 6.2.2.3 Packet Number 7: ETCS_ATO_Driver_Inputs

|**_Pa_**|**_cket Number_**<br>**_7_**||||
|---|---|---|---|---|
|**Item**|**Variable Name**|**Description**|**Data Type **|**Resolution/Formula**|
|1|N_ATOENGAGE_SELECTION|ATO Engage selection counter.|UINT8||
|2|N_SKIPSTPREQ_SELECTION|SkipStoppingPoint Request selection counter.|UINT8||
|3|N_SKIPSTPREV_SELECTION|SkipStoppingPoint Revocation selection counter.|UINT8||

**Table 10** Packet Number 7: ETCS_ATO_Driver_Inputs

<!-- end of page 22 -->

#### 6.2.2.4 Packet Number 8: ETCS_ATO_Data_Entry_Values

|**_Pack_**|**_et Number_**<br>**_8_**||||
|---|---|---|---|---|
|**Item**|**Variable Name**|**Description**|**Data Type **|**Resolution/Formula**|
|1|N_DEV_ITER|Number of data entry values.|UINT8|**Special values:**<br>16 - 255 = spare|
|2|NID_DATA_ATO (k)|One value of this variable represents a Specific<br>ATO Data required bythe ATO-OB.|UINT8|Numbers|
|imes<br>3|L_VALUE(k)|See[Ref 8] §8.1.12|UINT8|See[Ref 8] §8.1.12|
|(N_DEV_ITER)-t<br>(L_VALUE (k)) - times<br>4|X_VALUE (k, l)|See [Ref 8] §8.1.121|UINT8|See [Ref 8] §8.1.121|

**Table 11** Packet Number 8: ETCS_ATO_Data_Entry_Values

<!-- end of page 23 -->

6.2.2.5 Packet Number 9: ETCS_ATO_Data_Entry_Flag

||**_Packet_**|**_Number_**<br>**_9_**||||
|---|---|---|---|---|---|
|**Item**||**Variable Name**|**Description**|**Data Type **|**Resolution/Formula**|
||Bit|ATO_DATA_ENTRY_FLAG||BITSET8||
|1|0|M_ATO_DATAENTRYFLAG|Indicate the beginning or the end of<br>the Specific ATO Data Entry<br>procedure.||**Values:**<br>0 = Stop<br>1 = Start|
|2|1..7|Spare||||

**Table 12** Packet Number 9: ETCS_ATO_Data_Entry_Flag

6.2.2.6 Packet Number 10: ETCS_ATO_Data_View_Values_Request

6.2.2.6.1 This packet does not contain user data.

#### 6.2.2.7 Packet Number 11: ETCS_ATO_BRAKE_DECELERATIONS

|**_Pa_**|**_cket Number_**<br>**_11_**||||
|---|---|---|---|---|
|**Item**|**Variable Name**|**Description**|**Data Type **|**Resolution/Formula**|
|1|N_LOC_REF|Value of the position counter at the<br>moment the data of the packet is<br>determined.|INT32|**Resolution:**1 cm<br>**Special value:**<br>(2<sup>31</sup>-1) = spare<br>Note: the “spare” value is<br>used as a special value in<br>other variables which<br>depend on this counter<br>(e.g.<br>N_LOC_REFBALISE).|
|2|T_LOC_REF|Time at which the position counter of<br>this packet is determined.|UINT32|**Resolution:**1 ms<br>**Special value:**<br>(2<sup>32</sup>-1) = unknown|
|3|A_BRAKE_SAFE|A_BRAKE_SAFE<br>value<br>applicable<br>from zero speed, related to the brake<br>model applicable from the maximum<br>safe front end of the train|UINT16|**Resolution:**1 mm/s<sup>2</sup><br>**Special** **value**:<br>65535 = unknown|
|4|N_BRAKE_SAFE_ITER|Number of A_BRAKE_SAFE changes<br>related to the brake model applicable<br>from the maximum safe front end of the<br>train.|UINT8|**Special values:**<br>0 = no A_BRAKE_SAFE<br>changes available<br>10 - 255 = spare|
|ITER)-times<br>5|V_CHANGE_BRAKE (m)|Value of the speed from which (and<br>excluding)<br>the<br>value<br>of<br>A_BRAKE_SAFE (m) is applicable.|UINT16|**Resolution:**1 cm/s<br>**Special values:**<br>16668 – 65535 = spare|
|(N_BRAKE_SAFE_<br>6|A_BRAKE_SAFE (m)|Applicable value of A_BRAKE_SAFE.|UINT16|**Resolution:**1 mm/s<sup>2</sup>|

<!-- end of page 24 -->

|**_Pac_**|**_ket Number_**<br>**_11_**||||
|---|---|---|---|---|
|**Item**|**Variable Name**|**Description**|**Data Type **|**Resolution/Formula**|
|7|N_SEBDM_ITER|Number of location changes of safe<br>emergency brake deceleration models<br>(e.g. inhibition of special brakes).|UINT8|**Special values:**<br>0 = no changes in brake<br>model<br>41 - 255 = spare|
|8|N_LOC_SEBDM_CHANGE (n)|Estimated value of the position counter<br>from which the safe emergency brake<br>deceleration model is applicable.|INT32|**Resolution:**1 cm<br>**Special value:**<br>(2<sup>31</sup>-1) = not allowed|
|s<br>9|A_BRAKE_SAFE (n)|A_BRAKE_SAFE<br>value<br>applicable<br>from zero speed, related to the brake<br>model<br>applicable<br>from<br>N_LOC_SEBDM_CHANGE (n)|UINT16|**Resolution:**1 mm/s<sup>2</sup>|
|EBDM_ITER)-time<br>10|N_BRAKE_SAFE_ITER (n)|Number of A_BRAKE_SAFE changes<br>for the brake model applicable from<br>N_LOC_SEBDM_CHANGE (n).|UINT8|**Special values:**<br>0 = no A_BRAKE_SAFE<br>changes available<br>10 - 255 = spare|
|(N_S<br>ITER)-times<br>11|V_CHANGE_BRAKE (n, o)|Value of the speed from which (and<br>excluding)<br>the<br>value<br>of<br>A_BRAKE_SAFE (n,o) is applicable.|UINT16|**Resolution:**1 cm/s<br>**Special values:**<br>16668 – 65535 = spare|
|(N_BRAKE_SAFE_<br>12|A_BRAKE_SAFE (n, o)|Applicable value of A_BRAKE_SAFE.|UINT16|**Resolution:**1 mm/s<sup>2</sup>|

**Table 13 Packet Number 11: ETCS_ATO_BRAKE_DECELERATIONS**

<!-- end of page 25 -->
