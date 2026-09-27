# **3 Requirements for the Application of the Train Interface functions by Rolling Stock**

3.1.1.1 Table 4 contains the conditions for the application of the Train Interface functions by the rolling stock subsystem covering:

<!-- end of page 22 -->

   - ‘newly developed vehicle designs’ requiring a first authorisation as defined in Article 14 of Commission Implementing Regulation 2018/545

   - ‘all other vehicle types and rolling stock in operation’

3.1.1.2 An optional requirement in Table 4 has to be understood as a designer’s choice which has to be decided by the vehicle designer and/or the train operator depending on the characteristics of the respective vehicle, project requirements or if the corresponding function is implemented (e.g. Eddy current brake).

3.1.1.3 A mandatory requirement in Table 4 means that the function has to be implemented in the rolling stock.

3.1.1.4 For train interface functions that are not mandatory in Table 4, a condition for use shall clearly state that a vehicle has not implemented the corresponding train interface functions.

<!-- end of page 23 -->

|**Train Interface Function**|**Chapter**|**Newly developed vehicle designs**<br>**requiring a first authorisation**|**All other vehicle types and rolling stock**<br>**in operation**|**Optionality by Rolling stock is**<br>**considered in the ERTMS/ETCS**<br>**specification**|
|---|---|---|---|---|
|Sleeping|2.2.1|If vehicles support the operation in multiple o<br>see TSI Loc&Pas 2.2.1(g)) or if more than on<br>same trainset, the rolling stock shall apply the|peration (which implies an electrical coupling,<br>e ERTMS/ETCS on-board is installed on the<br>requirements according to 2.2.1.|-|
|Passive shunting|2.2.2|Optional application.||SUBSET-034, §2.2.2.3.3 “It shall be<br>allowed to configure the passive<br>shunting input permanently as “Passive<br>shunting not permitted”. This is a<br>decision made only by the Railway<br>Undertaking e.g. based on the<br>characteristics of the vehicle.”|
|Non-Leading|2.2.3|Mandatory application for locomotives only.<br>Optional application for trainsets.|Optional application.|-|
|Isolation|2.2.4|Mandatory application|||
|Automatic Driving|2.2.5|If rolling stock is equipped with an ERTMS/AT<br>requirements according to 2.2.5.|O on-board, the rolling stock shall apply the|SUBSET-026, §3.15.11.1 “In case it is<br>interfaced to an ERTMS/ATO on-board,<br>the ERTMS/ETCS on-board equipment<br>supports automatic driving on lines<br>fitted with an ERTMS/ATO trackside<br>subsystem.”|
|Remote Shunting|2.2.6|If the radio remote control is implemented in t<br>the requirements according to 2.2.6.|he rolling stock, the rolling stock shall apply|-|
|Service brake command|2.3.1|If the service brake command is intended to b<br>rolling stock shall apply the requirements acc|e used by the ERTMS/ETCS on-board, the<br>ording to 2.3.1.|SUBSET-026, §3.13.2.2.7.1 “The on-<br>board shall be configured to define<br>whether the service brake command is|

<!-- end of page 24 -->

|**Train Interface Function**|**Chapter**|**Newly developed vehicle designs**<br>**requiring a first authorisation**|**All other vehicle types and rolling stock**<br>**in operation**|**Optionality by Rolling stock is**<br>**considered in the ERTMS/ETCS**<br>**specification**|
|---|---|---|---|---|
|||||implemented or not, i.e. whether a<br>service brake interface is implemented<br>to command a full service brake effort.”|
|Brake pressure|2.3.2|If the service brake feedback function is in<br>according to Subset-026, §3.13.2.2.7.2 an<br>system, the rolling stock shall apply the re|tended to be used for the train interface<br>d if the rolling stock is fitted with UIC brake<br>quirements according to 2.3.2.|SUBSET-026, § A.3.10.2 “The on-<br>board shall consider the service brake<br>feedback as available for use if:<br>a) The service brake feedback is<br>implemented, AND<br>b) The national value does not inhibit its<br>use.”<br>SUBSET-026, §3.13.2.2.7.2 “The on-<br>board shall be configured to define<br>whether the service brake feedback is<br>implemented or not, i.e. whether it is<br>able to acquire from the service brake<br>interface the information that the<br>service brake is currently applied”|
|Emergency brake command|2.3.3|Mandatory application.||-|
|Special brake inhibition area –<br>Trackside orders|2.3.4|If the rolling stock intends to manage this<br>shall apply the requirements according to|track condition automatically, the rolling stock<br>2.3.4|SUBSET-026, §5.18.7.3.1.1 “Note:<br>Whether the operation is automatic or<br>manual is application dependent.”|
|Special brake inhibition – STM<br>Orders|2.3.5|If:<br>`-`there is at least one STM integrated on-<br>`-`at least one of these STMs can trigger t<br>`-`the rolling stock intends to manage this<br>the rolling stock shall apply the requireme|board and<br>his order and<br>track condition automatically,<br>nts according to 2.3.5.|SUBSET-026, §5.10.2.4.1 “b) Level<br>NTC: the concerned National System is<br>available on-board (if an STM is used,<br>refer to SUBSET-035 for further<br>details).”|
|Special brake status|2.3.6|If the ERTMS/ETCS on-board uses the sp<br>ERTMS/ETCS on-board:<br>`-`selects the brake parameters according|ecial brake status depending on whether the<br>to the status of the special brake|According to SUBSET-026, §3.13.2.2.6<br>the on-board can be configured in this|

<!-- end of page 25 -->

|**Train Interface Function**|**Chapter**|**Newly developed vehicle designs**<br>**requiring a first authorisation**<br>**All other vehicle types and rolling stock**<br>**in operation**|**Optionality by Rolling stock is**<br>**considered in the ERTMS/ETCS**<br>**specification**|
|---|---|---|---|
|||and/or<br>`-`selects the national value depending on the status of the special brake,<br>the rolling stock shall apply the requirements according to 2.3.6.|way that special brake status does not<br>affect the brake parameter.<br>SUBSET-026, §3.13.2.2.6.2 “[…] to<br>select the appropriate brake parameter<br>[…]”<br>SUBSET-026, §3.13.2.2.6.4 “[…] to<br>select the corresponding national value<br>[…]”|
|Additional brake status|2.3.7|If the ERTMS/ETCS on-board uses the additional brake status depending on whether the<br>ERTMS/ETCS on-board:<br>`-`selects the national value depending on the status of the additional brake,<br>the rolling stock shall apply the requirements according to 2.3.7.|SUBSET-026, §3.13.2.2.6.4 “The on-<br>board equipment shall be configured to<br>define whether it is allowed to take into<br>account the contribution of a<br>special/additional brake, which is<br>independent from wheel/rail adhesion,<br>for the selection of the maximum<br>emergency brake deceleration under<br>reduced adhesion conditions (see<br>3.13.6.2.1.6).”|
|Change of traction system|2.4.1|If the rolling stock intends to manage this track condition automatically, the rolling stock<br>shall apply the requirements according to 2.4.1.|SUBSET-026, §3.12.1.5.1 “Note:<br>Whether some information shall be<br>filtered (not shown to the driver or not<br>sent to an ERTMS/ETCS external<br>function) is outside the scope of<br>ERTMS/ETCS.”<br>5.18.10.4.1 “Note: Whether the<br>operation is automatic or manual is<br>application dependent.”|
|Powerless section with<br>pantograph to be lowered –<br>Trackside orders|2.4.2|If the rolling stock intends to manage this track condition automatically, the rolling stock<br>shall apply the requirements according to 2.4.2.|SUBSET-026, §3.12.1.5.1 “Note:<br>Whether some information shall be<br>filtered (not shown to the driver or not<br>sent to an ERTMS/ETCS external|

<!-- end of page 26 -->

|**Train Interface Function**|**Chapter**|**Newly developed vehicle designs**<br>**requiring a first authorisation**<br>**All other vehicle types and rolling stock**<br>**in operation**|**Optionality by Rolling stock is**<br>**considered in the ERTMS/ETCS**<br>**specification**|
|---|---|---|---|
||||function) is outside the scope of<br>ERTMS/ETCS.”<br>5.18.2.2.2.1 “Note: Whether the<br>operation is automatic or manual is<br>application dependent.”<br>5.18.2.5.1.1 “Note: Whether the<br>operation is automatic or manual is<br>application dependent.”|
|Pantograph – STM orders|2.4.3|If:<br>`-`there is at least one STM integrated on-board and<br>`-`at least one of these STMs can trigger this order and<br>`-`the rolling stock intends to manage this track condition automatically,<br>the rolling stock shall apply the requirements according to 2.4.3.|SUBSET-026, §5.10.2.4.1 “b) Level<br>NTC: the concerned National System is<br>available on-board”|
|Air tightness area – Trackside<br>orders|2.4.4|If the rolling stock intends to manage this track condition automatically, the rolling stock<br>shall apply the requirements according to 2.4.4.|SUBSET-026, §3.12.1.5.1 “Note:<br>Whether some information shall be<br>filtered (not shown to the driver or not<br>sent to an ERTMS/ETCS external<br>function) is outside the scope of<br>ERTMS/ETCS.”<br>5.18.6.2.2.1 “Note: Whether the<br>operation is automatic or manual is<br>application dependent.”<br>5.18.6.4.1.1 “Note: Whether the<br>operation is automatic or manual is<br>application dependent.”|
|Air tightness – STM orders|2.4.5|If:<br>`-`there is at least one STM integrated on-board and<br>`-`at least one of these STMs can trigger this order and|SUBSET-026, §5.10.2.4.1 “b) Level<br>NTC: the concerned National System is<br>available on-board”|

<!-- end of page 27 -->

|**Train Interface Function**|**Chapter**|**Newly developed vehicle designs**<br>**requiring a first authorisation**<br>**All other vehicle types and rolling stock**<br>**in operation**|**Optionality by Rolling stock is**<br>**considered in the ERTMS/ETCS**<br>**specification**|
|---|---|---|---|
|||`-`the rolling stock intends to manage this track condition automatically,<br>the rolling stock shall apply the requirements according to 2.4.5.||
|Station platform|2.4.6|If the rolling stock intends to manage this track condition automatically, the rolling stock<br>shall apply the requirements according to 2.4.6.|SUBSET-026, §3.12.1.5.1 “Note:<br>Whether some information shall be<br>filtered (not shown to the driver or not<br>sent to an ERTMS/ETCS external<br>function) is outside the scope of<br>ERTMS/ETCS.”|
|Powerless section with main<br>power switch to be switched off<br>– Trackside orders|2.4.7|If the rolling stock intends to manage this track condition automatically, the rolling stock<br>shall apply the requirements according to 2.4.7.|SUBSET-026, §3.12.1.5.1 “Note:<br>Whether some information shall be<br>filtered (not shown to the driver or not<br>sent to an ERTMS/ETCS external<br>function) is outside the scope of<br>ERTMS/ETCS.”<br>5.18.3.2.2.1 “Note: Whether the<br>operation is automatic or manual is<br>application dependent.”|
|Main power switch – STM<br>orders|2.4.8|If:<br>`-`there is at least one STM integrated on-board and<br>`-`at least one of these STMs can trigger this order and<br>`-`the rolling stock intends to manage this track condition automatically,<br>the rolling stock shall apply the requirements according to 2.4.8.|SUBSET-026, §5.10.2.4.1 “b) Level<br>NTC: the concerned National System is<br>available on-board.”|
|Traction Cut Off|2.4.9|If the traction cut off when reaching the warning limit is configured on board, the rolling<br>stock shall apply the requirements according to 2.4.9.|SUBSET-026, §3.13.2.2.8.1 “The on-<br>board shall be configured to define<br>whether the traction cut-off command is<br>implemented, i.e. whether the interface<br>to the traction system is implemented or<br>not.”|

<!-- end of page 28 -->

|**Train Interface Function**|**Chapter**|**Newly developed vehicle designs**<br>**requiring a first authorisation**|**All other vehicle types and rolling stock**<br>**in operation**|**Optionality by Rolling stock is**<br>**considered in the ERTMS/ETCS**<br>**specification**|
|---|---|---|---|---|
|||OR if:<br>`-`there is at least one STM integrated on-b<br>`-`at least one of these STMs can trigger the<br>`-`the use of the traction cut-off command is<br>the rolling stock shall apply the requirement|oard and<br>TCO command and<br>configured on-board<br>s according to 2.4.9.|SUBSET-026, §5.10.2.4.1 “b) Level<br>NTC: the concerned National System is<br>available on-board.”<br>SUBSET-058 §7.7.3 Packet STM-141:<br>Train interface command configuration<br>to STM, M_TITR_C_CMD_AVAIL|
|Change of allowed current<br>consumption|2.4.10|If the rolling stock intends to manage this tra<br>shall apply the requirements according to 2.|ck condition automatically, the rolling stock<br>4.10.|SUBSET-026, §3.12.1.5.1 “Note:<br>Whether some information shall be<br>filtered (not shown to the driver or not<br>sent to an ERTMS/ETCS external<br>function) is outside the scope of<br>ERTMS/ETCS.”|
|Engine orientation in Supervised<br>Manoeuvre|2.4.11|Optional application.<br>Note: Engine orientation in Supervised Man<br>stock and not specified in TSI LOC&PAS.|oeuvre is not part of the subsystem Rolling|See §2.4.11.1|
|Cab Status|2.5.1|Mandatory application.||-|
|Direction Controller|2.5.2|Mandatory application.|Optional application in case the direction<br>controller information cannot be obtained<br>from the rolling stock|SUBSET-026, §3.14.2.1 “Note: This<br>protection is only applicable if the<br>required information can be obtained<br>from the direction controller.”<br>SUBSET-026, §5.13.1.4 “If the<br>ERTMS/ETCS onboard detects the<br>driver’s intention to reverse (e.g. from a<br>direction controller in reverse position),<br>the ERTMS/ETCS on-board equipment<br>shall ask the driver to acknowledge<br>transition to RV mode.”|
|Train integrity|2.5.3|Optional application.||-|

<!-- end of page 29 -->

|**Train Interface Function**|**Chapter**|**Newly developed vehicle designs**<br>**requiring a first authorisation**|**All other vehicle types and rolling stock**<br>**in operation**|**Optionality by Rolling stock is**<br>**considered in the ERTMS/ETCS**<br>**specification**|
|---|---|---|---|---|
|||Note: Train integrity is not part of the sub<br>LOC&PAS.|system Rolling stock and not specified in TSI||
|Traction status|2.5.3.1|If<br>`-`there is at least one STM integrated on<br>`-`at least one of these STMs can make u<br>the rolling stock shall apply the requireme|-board and<br>se of this information,<br>nts according to 2.5.4.|SUBSET-058 §7.7.3 Packet STM-139:<br>Train interface inputs status/availability<br>to STM M_TITR_STATUS|
|Set Speed|2.5.5|Optional application.<br>Note: set speed is not part of the subsyst<br>LOC&PAS.|em Rolling stock and not specified in TSI||
|Type of train data entry|2.6.1|Optional application.<br>Note: Type of train data entry is not part o<br>in TSI LOC&PAS.|f the subsystem Rolling stock and not specified|ERA_ERTMS_015560, §11.3.9.6“It<br>shall be possible to select by means of<br>an input signal from the train interface<br>the kind of train data entry configuration<br>to be applied […].”|
|Overall consist length<br>information|2.6.2|Optional application.<br>Note: Overall consist length information is<br>specified in TSI LOC&PAS.|not part of the subsystem Rolling stock and not|See §2.6.2.1|
|Other train data information|2.6.3|Optional application.<br>Note: Other train data information is not p<br>specified in TSI LOC&PAS.|art of the subsystem Rolling stock and not|SUBSET-026, §3.18.3.2.1 “The Train<br>Data may come from ERTMS/ETCS<br>external sources (e.g. the Train<br>Interface), from pre-configured values<br>or from the driver.”|
|Train Category Cant Deficiency|2.6.3|Optional application.||See §2.6.3.2 and §2.6.3.4.4|
|Train length|2.6.3|Optional application.||See §2.6.3.2 and §2.6.3.4.4|
|Traction / brake parameter set:<br>Traction model|2.6.3|Optional application.||See §2.6.3.2 and §2.6.3.4.4|

<!-- end of page 30 -->

|**Train Interface Function**|**Chapter**|**Newly developed vehicle designs**<br>**requiring a first authorisation**|**All other vehicle types and rolling stock**<br>**in operation**|**Optionality by Rolling stock is**<br>**considered in the ERTMS/ETCS**<br>**specification**|
|---|---|---|---|---|
|Traction / brake parameter set:<br>Brake build up time model and<br>speed dependent deceleration<br>model|2.6.3|Optional application.||See §2.6.3.2 and §2.6.3.4.4|
|Traction / brake parameter set:<br>Brake percentage|2.6.3|Optional application.||See §2.6.3.2 and §2.6.3.4.4|
|Traction / brake parameter set:<br>Traction model|2.6.3|Optional application.||See §2.6.3.2 and §2.6.3.4.4|
|Traction / brake parameter set:<br>Brake position|2.6.3|Optional application.||See §2.6.3.2 and §2.6.3.4.4|
|Traction / brake parameter set:<br>Nominal rotating mass|2.6.3|Optional application.||See §2.6.3.2 and §2.6.3.4.4|
|Maximum train speed|2.6.3|Optional application.||See §2.6.3.2 and §2.6.3.4.4|
|Loading gauge|2.6.3|Optional application.||See §2.6.3.2 and §2.6.3.4.4|
|Axle load category|2.6.3|Optional application.||See §2.6.3.2 and §2.6.3.4.4|
|Traction system(s) accepted by<br>the engine|2.6.3|Optional application.||See §2.6.3.2 and §2.6.3.4.4|
|Train fitted with airtight system|2.6.3|Optional application.||See §2.6.3.2 and §2.6.3.4.4|
|Type of Train Configuration|2.6.3.4.3|Optional application.||See §2.6.3.2, §2.6.3.4.1 and §2.6.3.4.4|
|Train Running Number|2.7.1|Optional application.<br>Note: Train Running Number is not part o<br>in TSI LOC&PAS.|f the subsystem Rolling stock and not specified|SUBSET-026, §3.18.4.5.3 “It shall be<br>possible to change the train running<br>number while running, from driver input,<br>from the RBC or from other<br>ERTMS/ETCS external sources.”|
|National system isolation|2.8|If the corresponding NTC is interfaced wi<br>interface, the rolling stock shall apply the|th the ERTMS/ETCS on-board through an STM<br>requirements according to 2.8.|SUBSET-034, §2.8.1.2 “A NTC<br>isolation input shall be used by the<br>ERTMS/ETCS on-board equipment in|

<!-- end of page 31 -->

|**Train Interface Function**|**Chapter**|**Newly developed vehicle designs**<br>**requiring a first authorisation**|**All other vehicle types and rolling stock**<br>**in operation**|**Optionality by Rolling stock is**<br>**considered in the ERTMS/ETCS**<br>**specification**|
|---|---|---|---|---|
|||Note: National system isolation is not part<br>specified in TSI LOC&PAS.|of the subsystem Rolling stock and not|case it is interfaced to the National<br>System through an STM and this<br>National System requires isolation of<br>the STM to be implemented.”|

**Table 4 – Requirements for the application of the Train Interface functions for rolling stock**

<!-- end of page 32 -->
