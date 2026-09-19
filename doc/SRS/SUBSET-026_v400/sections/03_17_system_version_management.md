## **3.17 System Version Management**

**3.17.1 Introduction**

3.17.1.1 Definitions, high level principles and rules regarding the offline management of ERTMS/ETCS system version during the ERTMS/ETCS system life time are given in SUBSET-104.

3.17.1.2 The objective of this section is to define requirements applicable to ERTMS/ETCS onboard equipment and to trackside constituents, when different versions of the ERTMS/ETCS system have been defined.

3.17.1.3 Intentionally deleted.

<!-- end of page 203 -->

### **3.17.2 Determination of the operated system version**

3.17.2.1 The on-board equipment shall be able to operate with (i.e. shall support) any of the ERTMS/ETCS system version numbers X included in its envelope of supported system versions, as defined in chapter 6.

3.17.2.1.1 Within one of its supported system version numbers X, the on-board equipment shall always operate the highest system version number Y defined in its envelope of supported system versions, regardless of the system version number Y transmitted by the trackside.

3.17.2.2 The on-board equipment shall operate with only one system version at a time, i.e. it shall behave according to the whole set of requirements applicable to a system version (refer to chapter 6 in case the operated system version is older than the last one introduced in this release of the SRS).

3.17.2.3 The on-board equipment shall determine the operated system version number X, in relation to non-RBC trackside constituents, as the highest system version number X transmitted in the telegrams forming a balise group message (i.e. the telegrams which are not ignored as per a clause referred to in the column "Telegram" of the Table 17), or as the system version number X transmitted by a loop whose message is not ignored as per a clause referred to in the column "Message" of the Table 17, or as the system version number X transmitted by an RIU, if this system version number X is higher than the currently operated one.

3.17.2.4 It shall be possible from balise group to order the on-board equipment to operate a system version.

3.17.2.5 Once a balise group message has been received, if one of the telegrams forming the message (i.e. a telegram which is not ignored as per a clause referred to in the column "Telegram" of the Table 17) includes an order to operate system version which would not be ignored as per a clause referred to in the column "Individual information" of the Table 17, the on-board equipment shall immediately operate the system version number X given in the order, regardless of the clauses 3.17.2.3 and 3.17.2.6. After the order is executed, the clauses 3.17.2.3 and 3.17.2.6 shall again apply for any further received balise group/loop message or any further contacted RIU.

3.17.2.5.1 Note: the system version order is to be used wherever it is necessary to enforce an operated system version number X lower than the currently operated one.

3.17.2.6 If a mismatch has been detected between the country or region identifier read from a balise group/loop and the corresponding identifier(s) of the applicable set of national values, the on-board equipment shall consider the highest system version number X transmitted in the telegrams forming the balise group message (i.e. telegrams which are not ignored as per a clause referred to in the column "Telegram" of the Table 17) or the system version number X transmitted by the loop whose message is not ignored as per a clause referred to in the column "Message" of the Table 17, as the operated one and shall comply again with requirement 3.17.2.3. For balise groups, the on-board equipment

<!-- end of page 204 -->

shall take into account, if any, the country or region identifier(s) of a set of national values applicable immediately, which is included in a telegram forming the balise group message and which would not be ignored as per a clause referred to in the column "Individual information" of the Table 17.

3.17.2.7 If the on-board equipment does not support the system version number X transmitted by a non-RBC trackside constituent or the one specified in the balise group order, it shall consider the operated system version as unchanged.

3.17.2.8 In case of communication session established with an RBC, the system version number X of the RBC shall take precedence on the operated system version in relation to nonRBC constituents and on system version ordered from balise group; the operated system version number X shall be determined according to the following principles:

   - a) if the on-board equipment is in level 0, NTC or 1 (e.g. entrance in level 2 area), the RBC system version number X shall be operated when the transition to level 2 is executed;

   - b) if the on-board equipment is in level 2 (SoM procedure or order received from trackside), the RBC system version number X shall be operated immediately;

   - c) in case of session established with an accepting RBC (RBC/RBC Handover), the accepting RBC system version number X shall be operated as soon as the train has passed the RBC/RBC border location with its maximum safe front end;

   - d) in case the on-board equipment switches from level 2 to another level (e.g. exit from a level 2 area), the system version control in relation to non-RBC constituents shall be again applied and the balise group orders shall be again considered;

   - e) in case the engine passes the RBC/RBC border location with its maximum safe front end and no session is established with the accepting RBC, the system version control in relation to non-RBC constituents shall be again applied and the balise group orders shall be again considered.

3.17.2.8.1 For item a): if the switch from level 0, NTC or 1 to level 2 results from an immediate level transition order or a conditional level transition order received from balise group and if the RBC system version number X is different from the system version number X operated before the level transition, the checks of the raw balise group message and the evaluation of its whole content shall be performed taking into account the RBC system version and shall substitute the checks and evaluation performed beforehand with regards to the previously operated system version.

3.17.2.8.2 For item d): if the switch from level 2 to another level results from an immediate level transition order or a conditional level transition order received from balise group, the clauses 3.17.2.3, 3.17.2.5 and 3.17.2.6 shall be immediately checked to determine whether a change of operated system version occurs. If so, the checks of the raw balise group message and the evaluation of its whole content shall be performed taking into account the new operated system version and shall substitute the checks and evaluation performed beforehand with regards to the previously operated system version.

<!-- end of page 205 -->

3.17.2.9 The system version currently operated when the on-board equipment is switched off (i.e. enters No Power mode) shall be retained and re-used when powered on.

3.17.2.9.1 If the on-board equipment loses the information (failure situation), the highest supported system version shall be used.

**3.17.3 Handling of trackside data in relation to system version**

3.17.3.1 Every telegram transmitted by a balise, and every message transmitted by Euroloop and Radio Infill Unit shall contain only the data related to one system version. It is not allowed for the balise, Euroloop and Radio Infill Unit to transmit data correspondent to several system versions.

3.17.3.2 All messages transmitted by an RBC shall contain data only related to one major system version X and, within one communication session, they shall contain only data for one minor system version Y.

3.17.3.3 Except for the balises whose telegram is ignored as per clause 3.14.3.6 or 3.15.9.3 a), the on-board equipment shall check the system version transmitted by the balises/loops and then shall determine the operated system version prior to any further checks (data consistency, ...) and evaluation of the other data included in a balise group/loop message, as they may depend on the system version.

3.17.3.4 If any of the further checks that are referred to in the column "Message" of the Table 17 leads to the rejection of the whole balise group/loop message, any change of operated system version due to the application of clause 3.17.2.3, 3.17.2.5 or 3.17.2.6 shall be revoked by the on-board equipment, i.e. the operated system version prior to the reception of the balise group/loop message remains unchanged.

3.17.3.4.1 Note: the clauses 3.17.3.3 and 3.17.3.4 imply that on reception of a balise group/loop message the on-board equipment checks first the information which may impact the determination of the operated system version as per clauses 3.17.2.3, 3.17.2.5 or 3.17.2.6 (i.e. the system version transmitted by the balises/loop/RIU, the country or region identifiers of a set of National Values applicable immediately and a system version order). Then, upon a change of operated system version, the other information included in the message received from the balise group or loop will be checked and evaluated considering the newly operated system version. However, should the whole balise group/loop message be rejected due to e.g. linking, no change of operated system version will take place.

3.17.3.4.2 Intentionally deleted.

3.17.3.5 The on-board equipment shall check the ERTMS/ETCS system version number X transmitted by any balise:

   - a) In all levels, if this system version number X equals to 0, the balise information shall be ignored.

<!-- end of page 206 -->

   - b) In all levels, if this system version number X is different from 0 and lower than the lowest system version number X supported by the on-board equipment, it shall be able to interpret the balise information, to the extent defined for each type of information (see chapter 6 for detailed requirements). If the on-board is not able to interpret the information, the balise group message shall be considered as inconsistent in the sense of the clause 3.16.1.1.

   - c) In all levels, if this system version number X is amongst its supported ones, the onboard equipment shall be able to interpret the balise information. See chapter 6 for detailed requirements.

   - d) In levels 1 and 2, if this system version number X is greater than the highest version number X supported by the on-board equipment, the information from this balise shall be ignored, the train shall be tripped and an indication shall be given to the driver.

   - e) In levels 0 and NTC, if this system version number X is greater than the highest version number X supported by the on-board equipment, the information from this balise shall be ignored and no reaction shall be applied.

3.17.3.6 In level 1 the on-board equipment shall check the ERTMS/ETCS system version number X transmitted by any Euroloop:

   - a) if this system version number X is lower than the lowest system version number X supported by the on-board equipment, it shall be able to interpret the loop information, to the extent defined for each type of information (see chapter 6 for detailed requirements). If the on-board is not able to interpret the information, the loop message shall be considered as inconsistent in the sense of the clause 3.16.1.1.

   - b) if this system version number X is amongst its supported ones, the on-board equipment shall be able to interpret the loop information. See chapter 6 for detailed requirements.

   - c) If this system version number X is greater than the highest version number X supported by the on-board equipment, no reaction shall be applied and the information from this loop shall be ignored.

3.17.3.7 The on-board equipment shall check the ERTMS/ETCS system version number X transmitted the first time any RBC is contacted (including RBC hand over) or any RIU is contacted. Refer to section 3.5.3.7 d) for details.

3.17.3.8 Intentionally deleted.

3.17.3.9 Intentionally deleted.

3.17.3.10 Intentionally deleted.

3.17.3.11 For trackside information only differing by Y with regards to the highest system version number X supported by on-board, the on-board equipment shall not consider the reception of unknown packet/message as a message data consistency error (i.e. use of spare value for NID_PACKET or NID_MESSAGE) and shall ignore the content of the unknown packet/message in the following cases:

<!-- end of page 207 -->

   - a) unknown packet included in a balise telegram/loop message related to the higher system version;

   - b) unknown radio message from an RBC or RIU operating with the higher system version;

   - c) unknown packet from an RBC or RIU operating with the higher system version, included in a message in which one or more optional packet can be added according to the version operated by on-board.

3.17.3.12 Intentionally deleted.

3.17.3.12.1 Intentionally deleted.

3.17.3.13 Intentionally deleted.
