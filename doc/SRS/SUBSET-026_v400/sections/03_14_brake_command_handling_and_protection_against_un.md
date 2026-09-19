## **3.14 Brake Command Handling and Protection against Undesirable Train Movement**

**3.14.1 Brake Command Handling**

3.14.1.1 Note: Whenever the type of brake used is not specified explicitly in the text, it shall be interpreted as not being important for technical interoperability and being a property of the specific implementation.

3.14.1.2 In case only the application of (the non-vital) service brake has been commanded and the service brake fails to be applied, the emergency brake command shall be given.

3.14.1.3 If the emergency brake command was triggered due to a trip condition (see chapter 4) the emergency brake command shall be released at standstill and after driver acknowledgement of the trip condition.

3.14.1.4 For handling of brake commands resulting from the speed and distance monitoring, refer to section 3.13.10.

3.14.1.5 If the brake command was triggered due to roll away protection, unauthorised direction movement protection, standstill supervision, or detection of a train movement while modifying/revalidating train data or while entering SR speed/distance limits, the brake command shall be released at standstill and after driver acknowledgement.

3.14.1.6 If the brake command was triggered due to linking error, balise group message inconsistency or RAMS related supervision error, the brake command shall be released at standstill.

3.14.1.7 If the brake command was triggered due to supervision of the safe radio connection (T_NVCONTACT) the brake command shall be released at standstill or if a new message has been received from the RBC.

3.14.1.7.1 If the brake command was triggered due to an overpassed reversing distance related to a reversing area or due to any further movement in the direction opposite to the train orientation while the reversing distance is still overpassed, the brake command shall be released if the reversing distance becomes extended so that the reversing distance is no longer overpassed, or at standstill after driver acknowledgement.

3.14.1.7.2 If the brake command was triggered due to change of Train Data while running (see section 5.17 procedure "Changing Train Data from sources different from the driver”), the brake command shall be released at standstill and after driver acknowledgement.

3.14.1.7.3 If the brake command was triggered due to the driver not having acknowledged a mode or level change ordered from trackside (see sections 5.7, 5.9, 5.10 and 5.19), the brake command shall be released after the driver has acknowledged the mode or level transition.

<!-- end of page 179 -->

3.14.1.7.4 If the brake command was triggered due to an overpassed distance allowed for reverse movement in Post Trip mode or due to any further movement in the direction opposite to the train orientation while the distance allowed for reverse movement in Post Trip mode is still overpassed, the brake command shall be released at standstill and after driver acknowledgement.

3.14.1.7.5 If the brake command was triggered due to the driver not having acknowledged a text message, the brake command shall be released after the driver has acknowledged the text message.

3.14.1.7.6 If the brake command was triggered due to the safe consist length information having become unavailable, the brake command shall be released at standstill.

3.14.1.7.7 For handling of brake commands resulting from the STM control function, refer to SUBSET-035.

3.14.1.8 A brake command reason that pertains to one of the above clauses 3.14.1.3 to 3.14.1.7.7 shall be considered as applicable from the time the brake command is triggered to the time the release condition specified in the concerned above clause is fulfilled or to the time it is revoked due to a mode change.

3.14.1.9 Whenever an acknowledgement is requested together with standstill for the release condition of a brake command, it shall be requested to the driver only when the train reaches standstill.

3.14.1.10 In case more than one reason to command the brake is applicable at the same time, the brake command shall be released only when the release conditions specified for each of the above clauses 3.14.1.3 to 3.14.1.7.7 including the concerned reasons have been fulfilled. In particular, if several brake command reasons applicable at the same time are included in several clauses where a driver acknowledgement is required, there shall be as many individual driver acknowledgements required as concerned clauses.

3.14.1.10.1 In some of the above clauses 3.14.1.3 to 3.14.1.7.7, brake reasons are grouped: in case several brake command reasons are applicable at the same time and they are all pertaining to the same clause, only one driver acknowledgement shall be required in relation to these brake reasons.

3.14.1.11 In case a change of mode occurs while a brake command due to one or more reasons is still ongoing, see section 4.12 specifying for every individual brake command reason whether it shall be revoked or it shall remain applicable.

3.14.1.11.1 Upon a mode change, the ERTMS/ETCS on-board equipment shall maintain the brake command if at least one individual brake command reason remains applicable, until the corresponding release conditions have been all fulfilled.

3.14.1.11.2 If an individual brake command reason is revoked on a mode change, the release conditions specified in the clause including this brake reason shall not apply anymore, unless another brake reason included in the same clause remains applicable further to this mode change.

<!-- end of page 180 -->

### **3.14.2 Roll Away Protection**

3.14.2.1 Note: This protection is only applicable if the required information can be obtained from the direction controller.

3.14.2.2 The Roll Away Protection (RAP) shall prevent the train from moving in a direction, which conflicts with the current position of the direction controller in the active desk.

3.14.2.3 If the controller is in neutral position, the RAP shall prevent forward and reverse movements of the train.

3.14.2.4 As soon as a movement conflicting with the position of the direction controller is detected, the ERTMS/ETCS on-board shall start supervising (see section 3.6.7) whether the train travels away, from the location when the conflicting movement was detected, over a distance longer than the national value for the allowed roll away distance. In case this roll away distance is exceeded, the brake command shall be triggered.

3.14.2.5 Refer to section 3.14.1.

3.14.2.6 An indication shall be given to the driver showing when the RAP is commanding the brakes.

3.14.2.7 After revocation of the brake command, the RAP shall be re-initialised, i.e. the clause 3.14.2.4 shall be applied again.

**3.14.3 Unauthorised Direction Movement Protection** 3.14.3.1 The Unauthorised Direction Movement Protection (UDMP) shall prevent the train from moving in the opposite direction to the permitted one. The permitted movement direction of a train shall be the one of the currently valid MA, if available on-board. See chapter 4 concerning permitted direction for special cases.

3.14.3.2 As soon as a movement opposite to the authorised direction is detected, the ERTMS/ETCS on-board shall start supervising (see section 3.6.7) whether the train travels away, from the location when the opposite movement was detected, over a distance longer than a distance specified by the national value. In case this distance is exceeded, the brake command shall be triggered.

3.14.3.3 Refer to section 3.14.1.

3.14.3.4 An indication shall be given to the driver showing when the UDMP is commanding the brakes.

3.14.3.5 After revocation of the brake command, the UDMP shall be reinitialised, i.e. the clause 3.14.3.2 shall be applied again.

3.14.3.6 Information received from balises during movement opposite to the authorised direction shall be ignored.

<!-- end of page 181 -->

**3.14.4 Intentionally deleted**
