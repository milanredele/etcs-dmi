## **3.10 Emergency Messages**

### **3.10.1 General**

3.10.1.1 Emergency messages are sent individually to each on-board equipment.

3.10.1.1.1 Intentionally deleted.

3.10.1.2 An emergency message shall contain an identifier decided by the trackside.

3.10.1.3 The same identifier shall be used in case the emergency message is repeated.

3.10.1.3.1 If the on-board receives a new message with the same identifier it shall replace the previous one.

3.10.1.4 Each emergency message to an on-board equipment shall be acknowledged, using the corresponding emergency message identification number.

3.10.1.4.1 This acknowledgement informs the RBC about the use of the emergency message by on-board equipment and is independent from the general acknowledgement for track-totrain messages, as specified in section 3.16.3.5.

### **3.10.2 Emergency Stop**

3.10.2.1 It shall be possible to stop a train with a conditional or an unconditional emergency stop message.

3.10.2.2 A conditional emergency stop message shall contain the information of a new stop location, referred to the LRBG. In case, when receiving this message

   - a) the train has already passed with its min safe front end the new stop location, the emergency stop message shall be rejected.

   - b) the train has not yet passed with its min safe front end the new stop location, the emergency stop message shall be accepted:

      - If this new stop location is not beyond the current EOA/LOA, the on-board shall use it to define a new EOA/SvL with no release speed.

      - If this new stop location is beyond the current EOA and not beyond the current SvL, the on-board shall use it to define a new SvL with no release speed, keeping the current EOA unchanged.

      - If this new stop location is beyond the current SvL, the on-board shall keep the current EOA/SvL and release speed unchanged.

      - If this new stop location is beyond the current LOA, the on-board shall replace the current LOA with a new EOA/SvL at the LOA location, with no release speed.

<!-- end of page 96 -->

- Refer to appendix A.3.4 for the exhaustive list of location based information stored on-board, which shall be deleted accordingly.

3.10.2.3 When receiving an unconditional emergency stop message the train shall be tripped immediately.

3.10.2.4 New movement authority received after any accepted emergency stop message and before the emergency message has been revoked, shall be rejected.

3.10.2.5 Intentionally deleted.

3.10.2.6 Intentionally deleted.

### **3.10.3 Revocation of an Emergency Message**

3.10.3.1 The revocation message shall refer to the identity of the concerned emergency message.

3.10.3.2 The revocation messages shall be acknowledged by the on-board equipment, according to the general acknowledgement procedure (see section 3.16.3.5)

3.10.3.3 The revocation of an emergency message shall have no effect on the management of other emergency messages possibly received.

3.10.3.4 Intentionally deleted.
