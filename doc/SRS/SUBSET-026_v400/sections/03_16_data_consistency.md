## **3.16 Data Consistency**

**3.16.1 General**

3.16.1.1 The ERTMS/ETCS on-board equipment shall consider a message received from the trackside as inconsistent if it is not compliant with the ETCS specifications.

3.16.1.1.1 As a minimum, the ERTMS/ETCS on-board equipment shall consider the use of a spare value of a variable as not compliant with the ETCS specifications. Having in mind that the trackside messages are presumed to be compliant with the ETCS specifications, it is however not in the scope of this specification to list the other checks that the ERTMS/ETCS on-board equipment might consider to determine that a message is not compliant with them.

3.16.1.2 For the other inconsistency criteria, reactions and other functionality related to the consistency of the information from balises, see 3.16.2.

3.16.1.3 For the other inconsistency criteria, reactions and other functionality related to the consistency of the information from radio, see 3.16.3.

3.16.1.4 Unless stated otherwise, the ERTMS/ETCS on-board equipment shall reject a message that fulfils any inconsistency criteria.

### **3.16.2 Balises**

**3.16.2.1 Definitions**

3.16.2.1.1 The information that is sent from a balise is called a balise telegram.

3.16.2.1.2 The whole set of information (balise telegram or telegrams) coming from a balise group is called a balise group message.

3.16.2.1.2.1 Note: In case of a balise group containing a single balise, telegram and message coincide.

3.16.2.1.3 Intentionally deleted.

#### **3.16.2.2 General**

3.16.2.2.1 If the on-board is not able to recognise whether a balise group is linked or unlinked (if none of the balises in the balise group can be read correctly), it shall consider it as unlinked.

3.16.2.2.2 A balise within a balise group shall be regarded as missed if

   - a) No balise is detected (see SUBSET-036 sections 4.2.4.1 and 4.2.4.2) within the maximum distance between balises from the previous balise in the group, or

   - b) A following balise within the group is received, or

   - c) A balise from another group is received

<!-- end of page 194 -->

#### **3.16.2.3 Linking Consistency**

3.16.2.3.1 If linking consistency is checked the on-board shall react according to the linking reaction information in the following cases:

   - a) If the location reference of the expected balise group is detected (see SUBSET-036 sections 4.2.4.1 and 4.2.4.2) in rear of the expectation window

   - b) If the location reference of the expected balise group is not detected (see SUBSET036 sections 4.2.4.1 and 4.2.4.2) inside the expectation window

   - c) If inside the expectation window of the expected balise group a balise from another announced balise group, expected later, is received.

3.16.2.3.1.1 For a balise group location reference not detected at all, the ERTMS/ETCS on-board equipment shall consider the criterion 3.16.2.3.1 b) as fulfilled only once the min safe antenna position has passed the last possible location of the balise group plus 1.3m, for a time equal to:

   - a) 100 ms for balise groups to be passed in nominal direction

   - b) Tn (see SUBSET-036 clause 4.2.9) for balise groups to be passed in reverse direction.

3.16.2.3.2 Intentionally deleted.

3.16.2.3.2.1 Intentionally deleted.

3.16.2.3.3 Intentionally deleted.

3.16.2.3.4 If the balise duplicating the location reference balise is used as location reference for the group, and is detected (see SUBSET-036 sections 4.2.4.1 and 4.2.4.2) within the expectation window, no linking reaction shall be applied.

#### **3.16.2.4 Balise Group Message Consistency**

3.16.2.4.1 The on-board shall react according to the linking reaction when the message from a balise group announced by linking, whose location reference was detected (see SUBSET-036 sections 4.2.4.1 and 4.2.4.2) inside its expectation window or whose expectation window is currently supervised, fulfils the general inconsistency criterion 3.16.1.1 or any of the following inconsistency criteria:

   - a) A balise is missed inside the group.

   - b) A balise is detected but no telegram is decoded (e.g. wrong CRC,...).

   - c) Intentionally deleted.

   - d) Message counters do not match (see 3.16.2.4.7)

3.16.2.4.2 Exception: Even if it considers the message as inconsistent due to either a) or b) above but the balise missed, or not decoded, is duplicated within the balise group and the duplicating one is correctly read, the ERTMS/ETCS on-board equipment shall not reject the message and shall not apply the linking reaction.

<!-- end of page 195 -->

3.16.2.4.3 If linking consistency is checked, the expected balise group is referred in the linking information with a balise group with ID not set to “unknown”, and the on-board rejects the message from a balise group marked as linked as per 3.4.4.4.2, no reaction shall be applied, even if errors in the reading of the balise group occur.

3.16.2.4.3.1 If linking consistency is checked, the expected balise group is referred in the linking information with a balise group with ID “unknown”, and the on-board rejects the message from a balise group marked as linked because one of the conditions of 3.4.4.4.2.1 is not fulfilled:

   - a) in case the condition 3.4.4.4.2.1 a) is fulfilled but the condition 3.4.4.4.2.1 c) is not fulfilled, no reaction shall be applied, even if errors in the reading of the balise group occur. Rationale: the balise group can for sure not be the expected one (i.e. the one which contains repositioning information valid for the train orientation);

   - b) in all other cases and if an error in the reading of the balise group occurs, the linking reaction shall be applied. Rationale: it cannot be excluded that the balise group is the expected one (i.e. the one which contains repositioning information valid for the train orientation) because e.g. one of the missed or not decoded balise(s) does contain the repositioning information valid for the train orientation or e.g. although a balise containing repositioning information has been correctly received the balise group orientation cannot be determined from the balise group itself.

3.16.2.4.4 If linking consistency is not checked, the on-board shall command application of the service brake when the message from a balise group marked as linked fulfils the general inconsistency criterion 3.16.1.1 or any of the following inconsistency criteria:

   - a) A balise is missed inside the group.

   - b) A balise is detected, but no telegram is decoded (e.g. wrong CRC).

   - c) Intentionally deleted.

   - d) Message counters do not match (see 3.16.2.4.7)

3.16.2.4.4.1 Exceptions: Even if it considers the message as inconsistent due to either a) or b) of clause 3.16.2.4.4, the ERTMS/ETCS on-board equipment:

   - a) shall not reject the message and shall not command application of the service brake if the balise missed, or not decoded, is duplicated within the balise group, the duplicating one is correctly read and contains:

      - directional information while the orientation of the balise group can still be evaluated, or

      - only information valid for both directions, or

      - neither directional information nor information valid for both directions, or

      - only data to be used by applications outside ERTMS/ETCS, or

      - only data to be used by applications outside ERTMS/ETCS together with other information valid for both directions.

<!-- end of page 196 -->

   - b) shall not command application of the service brake if the telegram correctly read from another balise of the group contains the information “Inhibition of balise group message consistency reaction”.

3.16.2.4.4.2 Concerning clause 3.16.2.4.4, if the service brake is applied, the location based information stored on-board shall be shortened to the current position when the train has reached standstill. Refer to appendix A.3.4 for the exhaustive list of information, which shall be shortened.

3.16.2.4.4.3 Concerning clause 3.16.2.4.4, if the service brake is applied, the driver shall be informed that this is due to a balise group message consistency problem.

3.16.2.4.4.4 Exception: Concerning clause 3.16.2.4.4, if the balise group was the last announced one by linking and the linking consistency is no longer checked as per 3.4.4.4.6 a), the on-board shall apply the clause 3.16.2.4.1 instead.

3.16.2.4.5 A message counter shall be attached to each balise telegram indicating which balise group message the telegram fits to.

3.16.2.4.6 Instead of a message counter corresponding to a given balise group message, it shall be possible to identify a telegram as always fitting all possible messages of the group.

3.16.2.4.6.1 It shall also be possible to identify a telegram as never fitting any message of the group.

3.16.2.4.7 Comparing message counters of the received telegrams of a balise group message, excluding the ones complying with 3.16.2.4.6 and the ones that are not used by the onboard to compose the message (see 3.16.2.4.8.2), if their values are not all identical, or at least one of them complies with 3.16.2.4.6.1, the message shall be considered as inconsistent.

3.16.2.4.7.1 In case of single balise group, if the message counter of the received telegram complies with 3.16.2.4.6.1, the message shall also be considered as inconsistent.

3.16.2.4.8 It shall be possible to indicate failures in the system underlying the balise/loop/RIU (e.g. the Lineside Electronic Unit, LEU) by sending a balise telegram, a loop message or a RIU message including the information "default balise/loop/RIU information".

3.16.2.4.8.1 If one (and only one) out of a pair of duplicated balise telegrams received by the onboard includes the information “default balise information”, the on-board shall ignore any other information included in this telegram and shall consider information from the telegram not containing “default balise information".

3.16.2.4.8.2 When duplicated balises are both received and decoded correctly, and both, or none of them, contain "default balise information", the ERTMS/ETCS on-board equipment shall compose the message using only the information from the last received balise telegram out of the pair.

<!-- end of page 197 -->

3.16.2.4.8.2.1 Exception: The ERTMS/ETCS on-board equipment shall also include in the message all received data that is to be forwarded to a National System through the STM interface (see 3.15.6) which is contained in the first received balise telegram out of the pair.

3.16.2.4.9 If a message has been received containing the information "default balise information", the driver shall be informed.

**3.16.2.5 Unlinked Balise Group Message Consistency**

3.16.2.5.1 The on-board equipment shall command application of the service brake when the message received from a balise group marked as unlinked fulfils the general inconsistency criterion 3.16.1.1 or any of the following inconsistency criteria:

   - a) A balise is missed inside the unlinked balise group.

   - b) A balise is detected, but no telegram is decoded (e.g. wrong CRC).

   - c) Intentionally deleted.

   - d) Message counters do not match (see 3.16.2.4.7)

3.16.2.5.1.1 Exceptions: Even if it considers the message as inconsistent due to either a) or b) of clause 3.16.2.5.1, the ERTMS/ETCS on-board equipment:

   - a)  shall not reject the message and shall not command application of the service brake if the balise missed, or not decoded, is duplicated within the balise group, the duplicating one is correctly read and contains:

      - directional information while the orientation of the balise group can still be evaluated, or

      - only information valid for both directions, or

      - neither directional information nor information valid for both directions, or

      - only data to be used by applications outside ERTMS/ETCS, or

      - only data to be used by applications outside ERTMS/ETCS together with other information valid for both directions.

   - b) shall not command application of the service brake if the telegram correctly read from another balise of the group contains the information “Inhibition of balise group message consistency reaction”.

3.16.2.5.2 Concerning clause 3.16.2.5.1, if the service brake is applied, the location based information stored on-board shall be shortened to the current position when the train has reached standstill. Refer to appendix A.3.4 for the exhaustive list of information, which shall be shortened.

3.16.2.5.3 Concerning clause 3.16.2.5.1, if the service brake is applied, the driver shall be informed that this is due to a balise group message consistency problem.

<!-- end of page 198 -->

#### **3.16.2.6 Linking Reactions**

3.16.2.6.1 When the linking reaction leads to train trip or a service brake application, the driver shall be informed that the intervention is due to data consistency problem with the expected balise group.

3.16.2.6.2 If the service brake is initiated due to the linking reaction, the location based information stored on-board shall be shortened to the current position when the train has reached standstill. Refer to appendix A.3.4 for the exhaustive list of information, which shall be shortened.

#### **3.16.2.7 RAMS related supervision functions**

#### **3.16.2.7.1 Mitigation of balise detection degradation**

3.16.2.7.1.1 If no balise is detected between the start of the expectation window of a balise group announced by linking and the end of the expectation window of the next balise group announced by linking, the ERTMS/ETCS on-board shall command the service brake and the driver shall be informed. At standstill, the location based information stored on-board shall be shortened to the current position. Refer to appendix A.3.4 for the exhaustive list of information, which shall be shortened.

#### **3.16.2.7.2 Mitigation of balise cross-talk while expecting repositioning information**

3.16.2.7.2.1 If repositioning is announced and the expected repositioning balise group has been received, the ERTMS/ETCS on-board equipment shall keep looking for a balise group that satisfies the same criteria as this previously expected and already received repositioning balise group, until one of the following events occurs:

   - a) the min safe antenna position leaves the expectation window of the repositioning balise group that was announced and already received

   - b) a linked balise group that has been announced with known identity is received.

3.16.2.7.2.2 If a second balise group is received that satisfies the same criteria as the previously expected and already received repositioning balise group, the ERTMS/ETCS on-board equipment shall command the service brake and the driver shall be informed. At standstill, the location based information stored on-board shall be shortened to the current position. Refer to appendix A.3.4 for the exhaustive list of information, which shall be shortened.

3.16.2.7.2.3 Note: this function is independent from linking consistency check function, i.e. the rules related to linking always apply. This means that once a repositioning balise group has been received and if this latter contains new linking information, the ERTMS/ETCS on-board equipment will start expecting the first balise group announced in this new linking information in parallel with the monitoring specified in 3.16.2.7.2.1.

<!-- end of page 199 -->

### **3.16.3 Radio**

#### **3.16.3.1 General issues**

3.16.3.1.1 In addition to the check of the general inconsistency criteria 3.16.1.1, a radio message is inconsistent when any of the applicable checks among the following is not completed successfully:

   - a) Checks performed by Euroradio protocol (see Subset-037)

   - b) Time stamps check (see 3.16.3.3.3)

   - c) Message length check (see 8.4.4.2.1).

3.16.3.1.1.1 Intentionally deleted.

3.16.3.1.1.2 The on-board shall inform the trackside if an inconsistent message is received.

3.16.3.1.2 Intentionally deleted.

3.16.3.1.3 Intentionally deleted.

3.16.3.1.3.1 Intentionally deleted.

3.16.3.1.4 Intentionally deleted.

#### **3.16.3.2 Time stamping**

3.16.3.2.1 The trackside shall always transmit its information with reference to the train time.

3.16.3.2.2 To time-stamp its messages, the trackside shall make a safe estimation of the on-board time, based on the time-stamp of the received messages and the internal processing times. The estimation shall be made in such a way that the on-board time estimated by the trackside shall not be in advance of the real on-board time.

3.16.3.2.3 Wrap around of the onboard timer can occur during a communication session and shall have no impact on system behaviour.

**3.16.3.3 Supervision of Sequence**

3.16.3.3.1 The trackside shall time-stamp a message with a value corresponding to the time of sending.

3.16.3.3.2 There shall always be a time stamp increment between consecutive messages.

3.16.3.3.3 The on-board shall consider a message as inconsistent if its time stamp is lower than or equal to the time stamp of the preceding message.

3.16.3.3.3.1 Intentionally deleted.

3.16.3.3.3.2 Note: The supervision does not detect a lost message. This has to be assured by means of the “acknowledge” function.

3.16.3.3.4 Intentionally deleted.

<!-- end of page 200 -->

<!-- Start of picture text -->
RBC Train<br>T_TRAIN1<br>T_TRAIN1 + 1<br>T_TRAIN2<br>T_TRAIN2 + 2<br>Accepted<br>Rejected<br><!-- End of picture text -->

**Figure 60: Supervision of sequence**

#### **3.16.3.4 Supervision of safe radio connection**

3.16.3.4.1 When the difference between the time stamp of the latest received message and the current on-board time is greater than the T_NVCONTACT parameter (national value), the on-board shall apply the reaction required by trackside (see 3.16.3.4.2).

3.16.3.4.1.1 After the on-board equipment has switched to Level 2  with no communication session established, the current onboard time shall be compared with the on-board time at the moment of the level transition (instead of the time stamp of the latest received message) until a new message has been received.

3.16.3.4.1.2 When an RBC/RBC handover has been announced, the current onboard time shall be compared with the time stamp of the latest message from the Handing over RBC until the train considers the Accepting RBC as the supervising one (refer to 3.15.1.3.5). From then on the current onboard time shall be compared with the time stamp of the latest received message from the Accepting RBC.

3.16.3.4.1.2.1 Exception: in case an RBC/RBC handover is announced when another RBC/RBC handover is already ongoing and this announcement changes the Handing Over RBC (refer to 3.15.1.3.2), then the current on-board time shall be compared with the time stamp of the latest received message.

3.16.3.4.1.3 As long as the engine, taking into account its front and rear ends, overlaps an announced radio hole, the ERTMS/ETCS on-board equipment shall stop the supervision of the safe radio connection. Afterwards, until a new message has been received, the current onboard time shall be compared with the on-board time when the engine rear/front end left the radio hole, depending on whether the train orientation is the same as/opposite to the active cab (instead of the time stamp of the latest received message).

<!-- end of page 201 -->

<!-- Start of picture text -->
T_TRAIN1<br>T_TRAIN1 + 1<br>T_NVCONTACT<br>T_TRAIN2<br>T_TRAIN2 + 2<br><!-- End of picture text -->

**Figure 61: Supervision of the safe radio connection (Message received within the Window)**

<!-- Start of picture text -->
T_TRAIN T_TRAIN1 1<br>T_TRAIN T_TRAIN1 1 +  1<br>T_NVCONTACT T_CONTACT<br>T_TRAIN T_TRAIN2 2<br>T_TRAIN T_TRAIN2 2 +  2<br>Apply reaction<br>M_NVCONTACT<br><!-- End of picture text -->

**Figure 62: Supervision of the safe radio connection (No message received within the Window)**

3.16.3.4.2 It shall be possible to select one of the following reactions (National value) :

   - a) Train trip

   - b) Apply service brake

   - c) No reaction

3.16.3.4.3 For all reactions, if no new message has been received after an additional delay time (as defined in A.3.1), the on-board shall release the safe radio connection and then set-up it again (maintaining the communication session).

3.16.3.4.4 When the reaction leads to train trip or a service brake application, the driver shall be informed that no radio message has been received in due time.

3.16.3.4.5 If the service brake is initiated, the following reaction shall be taken;

   - a) For brake command release conditions refer to section 3.14.1.7.

<!-- end of page 202 -->

   - b) If no new message is received until the train reaches standstill, the location based information stored on-board shall be shortened to the current position. Refer to appendix A.3.4 for the exhaustive list of information, which shall be shortened.

3.16.3.4.6 Intentionally deleted.

3.16.3.4.7 To avoid the expiration of the on-board timer and if no new information is needed to be sent, the RBC shall send an empty message.

**3.16.3.5 Message Acknowledgement**

3.16.3.5.1 When a message including the request for acknowledgement is received and unless this message is considered as inconsistent, the on-board shall send an acknowledgement to the trackside.

3.16.3.5.1.1 Note: In order to ensure trackside that the on-board has correctly received transmitted information, the trackside may ask the on-board to acknowledge.

3.16.3.5.2 Intentionally deleted

3.16.3.5.3 The acknowledgement message shall refer to the time stamp of the concerned message sent by the trackside.

3.16.3.5.4 Intentionally deleted.

### **3.16.4 Error reporting to RBC**

3.16.4.1 In level 2, if a radio communication session is established, errors shall be reported as soon as the availability of a safe radio connection permits.

3.16.4.2 This refers to balise group errors, odometer accuracy related errors and radio message errors regardless if there is an error reaction.

3.16.4.3 If linking consistency is checked on-board, no error reporting shall be done for balise groups marked as linked but not included in the linking information.
