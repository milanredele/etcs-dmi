# **6 SAFE FUNCTIONAL MODULE**

## **6.1 Service definition**

6.1.1.1 The service interface between safety layer user and safety layer is not mandatory for interoperability.

6.1.1.2 This section specifies an interface between the Safe Functional Module (SFM) and the users of the SFM. It gives the data flows to/from the Safe Functional Module, which provides safe services. In the following, the safe service users will be designated by SaS user. The SaS user exchanges data with the SaS provider.

6.1.1.3 The safety services provide safe connection set-up, and safe data transfer during the connection lifetime. The safe data transfer provides data integrity and data authenticity. The SFM reports the errors that occur in the safety layer and transfers error indications from the lower layers.

### **6.1.2 Model of the safe services**

6.1.2.1 A safety entity communicates with its users through one or more safe service access points (SaSAP) by means of the safe service primitives. The peer safety entities support safe connection exchanges by means of safety protocol data units (SaPDU). These protocol exchanges use the services of the transport layer via one Transport Connection (TC) through one transport service access point (TSAP), i.e. the safety entity plays the role of a TS user. The exchange of SaPDUs is a logical view only. Service primitives transmit data.

<!-- Start of picture text -->
Safety service user Safety service user<br>Data Data<br>SaSAP SaSAP<br>Safe<br>Safe<br>Functional<br>Functional<br>Module<br>Module<br>SaS provider entity SaS provider entity<br>Safety protocol<br>Safety layer entity Safety layer entity<br>TS user entity TS user entity<br>TSAP TSAP<br>Communication  Data Communication<br>Functional  Functional<br>Module Module<br><!-- End of picture text -->

**Figure 5 Model of the safe services**

6.1.2.2 This figure contains a model only. It does not restrict any implementations.

<!-- end of page 21 -->

### **6.1.3 Safe connection set-up**

6.1.3.1 Peer entity authentication is provided by the safety protocol between safety layer entities. At connection set-up request, the safety layer will activate the corresponding safety mechanisms to provide entity authentication.

6.1.3.2 The process of establishing a safe connection is initiated at the time when the SaS user requests a connection to the safety layer. The SaS user will send address information and QoS requirements to the safety layer qualifying the request for connection establishment. This QoS value is forwarded to the Communication Functional Module (CFM) and interpreted as a request for a predefined set of quality of service values.

6.1.3.3 The service of providing a safe connection is realised by the execution of the safety procedure ‘peer entity authentication’. The establishment of a transport connection between trackside and trainborne is a precondition for the establishment of the safety connection.

6.1.3.4 Any error in the execution of the safety procedure ‘peer entity authentication’ will result in the rejection of the connection establishment and in the release of the transport connection.

### **6.1.4 Safe data transfer**

6.1.4.1 The safety layer provides for an exchange of user data in both directions simultaneously, and preserves the integrity and boundaries of user data.

6.1.4.2 The Safe Functional Module entity guarantees safe data transfer for safety related messages. The safe data transfer service makes use of the safety procedure ‘message origin authentication’.

6.1.4.3 The ‘message origin authentication’ procedure provides a protection against message integrity violation and against insertion of new messages by unauthorised users of the transmission channel. Message integrity violation means any modification of a message from an active attack or due to random transmission channel errors.

6.1.4.4 Each time a SFM entity receives a data message, delivered by the transmission system (the messages coming from SaS users are considered safe), it shall verify that the message was sent by its peer entity, and that the message has not been altered during its transmission. Both operations, i.e. authentication of the sender, and confirmation of message integrity are realised by the execution of the procedure ‘message origin authentication’.

### **6.1.5 Release of safe connection**

6.1.5.1 The release of a safe connection is performed by:

   - a) either or both of the SaS users by releasing an established safe connection;

   - b) the safety layer by releasing an established safe connection;

   - c) either or both SaS users by abandoning the safe connection establishment;

   - d) the safety layer by indicating its inability to establish a requested safe connection.

<!-- end of page 22 -->

6.1.5.2 The release of a safe connection is permitted at any time regardless of the current safe connection phase. A request for a release cannot be rejected. The safe service does not guarantee delivery of any Sa user data once the release phase is entered.

6.1.5.3 The request by the SaS user for the release of a safe connection does not need specific safety protection unlike safe connection set-up, because the release of the connection impacts only on availability. In addition, a safe connection is meaningful only if the underlying connections of the lower layers are not released, and a transport or network connection can be released independently from the safety layer.

### **6.1.6 Error reporting**

6.1.6.1 The safety layer provides an error reporting function to the SaS user for the established safe connection.  Errors occurring are either indicated by the release of the safe connection or optionally by an error report. The inability of the safety layer to provide a service will be reported to the SaS user.

<!-- end of page 23 -->

## **6.2 Safety protocol**

### **6.2.1 Introduction**

6.2.1.1 This section provides a precise specification of the safety protocol taking into account the CENELEC standard EN 50159. The method used in the SFM corresponds to the A1 type in EN 50159: cryptographic safety code using secret key.

### **6.2.2 Generic MAC-Calculation**

6.2.2.1 The computation of the MAC in all cases is according to [ISO/IEC 9797-1]. The block cipher used is the single DES with modified MAC algorithm 3, where the last data block in the MAC computation will be computed as encipher with K1, decipher with K2, then encipher with K3 (this is a modification of ISO 9797-1 which uses only two keys, K and K''). ISO 9797-1 Padding Method 1 is used.

6.2.2.2 The CBC-MAC is a value of 64 bits calculated on a message “ _m_ ” using three 64-bit DES keys.

6.2.2.3 To calculate the CBC-MAC on a value X, the length in bits of the value must be a multiple of 64. If necessary, i.e. if the length of a message _m_ in bits is not a multiple of 64, padding is performed prior to the computation of the CBC-MAC. As few zero bits as needed (possibly none) are added at the end of the message _m_ to obtain a multiple of 64 bits. The padding data _p_ is used for CBC-MAC calculation only. It does not become part of the message.

6.2.2.4 The CBC-MAC (K, X) function using a secret triple-key K and the value X = _m_ | _p_ is defined as follows:

6.2.2.5 Let K = K1 | K2 | K3 be a triple-key and K1, K2, K3 its DES-keys, let X be constituted by the 64-bit blocks X1 | X2 | ... | Xq. Let E(Kn,X) be a block cipher function, single DES in CBC mode, enciphering the data string X using the key Kn (n є {1,2,3}). Let E<sup>-1</sup> (Kn,X) be a single DES block decipher function, deciphering the data string X using the key Kn (n є {1,2,3}). Let  be the XOR-operation. Then, CBC-MAC is derived by the following iteration:

6.2.2.6 The initial value H0 is of length 64 bits, all bits are of value “0”. H0 is not enciphered before first usage,

6.2.2.7 Hi = E(K1,Hi-1  Xi), i = 1,2,…, q-1, Hq = E(K3,E<sup>-1</sup> (K2, E(K1,Hq-1  Xq)))

6.2.2.8 The CBC-MAC calculated on the message _m_ is then equal to Hq.

6.2.2.9 An informative example is given in ANNEX B.

### **6.2.3 Functions of the safety layer**

6.2.3.1 The safety layer provides the safe transfer of user data. This includes the establishment and release of the safety connection.

6.2.3.2 **Safety procedures**

#### **6.2.3.2.1 Message origin authentication / Message integrity**

<!-- end of page 24 -->

6.2.3.2.1.1 Message origin authentication/message integrity is a safety procedure ensuring the integrity and authenticity of messages during transmission. It is used to protect the messages against modification and to ensure that no one can masquerade as the originator of the message. In the following, the procedure is simply called message origin authentication because message origin authentication automatically provides message integrity.

#### **Procedure 1: Message Origin Authentication (MAC) on Transmission (m, KS)**

- **Input:** Message m and cryptographic triple key Ks, which is shared between the sender (with the source address SA) and the receiver (with the destination address DA); SA and DA are ETCS Identities.

- **Procedure:** 1.) Set direction flag of message m (value '0' for initiator, value '1' for responder).

   - 2.) Append the destination address (DA) in front of the message m: "DA | m".

   - 3.) Compute length _l_ of string "DA | m" in octets and append length (2 octets<sup>2</sup> ) in front of the string for MAC computation, i.e. _l_ | DA | m

   - 4.) If the length of the message ( _l_ | DA | m) in bits is not a multiple of 64 then perform padding as defined below  for _l_ | DA | m and append padding data p: ( _l_ | DA | m | p)

   - 5.) Compute MAC for the string " _l_ | DA | m | p" using the CBC-MAC function and the cryptographic triple key Ks:

MAC(m)=CBC-MAC(KS,<sup>_l_| DA | m | p), where | denotes concatenation</sup>

- **Output:** If no error occurs MAC(m), which is appended to m. Otherwise, inform the error management.

6.2.3.2.1.2 Message origin authentication is performed as follows:

6.2.3.2.1.3 On transmission of a Data (DT) SaPDU, a Management (MA) SaPDU, the second authentication message (AU2) SaPDU, the third authentication message (AU3) SaPDU, or the Authentication Response (AR) SaPDU, a MAC of length 64 bit is computed using the message m and the cryptographic triple key Ks as input.

6.2.3.2.1.4 For these SaPDUs, the cryptographic triple key Ks used for the computation of the MAC is a session key derived during connection set-up. In addition, in the case of a management SaPDU the triple key Ks is the session key derived during connection setup. The length of the triple key Ks = (K1, K2, K3) has to be 192 bits including parity bits. In order to get three 64-bit DES-keys for the single DES with modified MAC algorithm 3 from the three 64-bit session key generation outputs, each eighth bit of the 192-bits should be set to an odd-parity value as defined in the standard [ANSI X3.92]. However, setting the parity bits is an implementation matter where the key is internal to an equipment.

> 2 The bits in the two octets are numbered from 16 to 1, where bit 1 is the lowest order bit.

<!-- end of page 25 -->

6.2.3.2.1.5 The ETCS Identity of the receiver (DA) is appended before the message "m" for the MAC computation. The Identity is binary coded by 24 bits. If the address is shorter, bits set to zero are added before the address to obtain a receiver identity (DA) of 24 bits.

6.2.3.2.1.6 The length _l_ of the string "DA **|** m" is computed and appended before the string "DA **|** m" for the MAC computation. The length _l_ is binary coded by 16 bits (without sign) and is not transmitted because the receiver can compute it.

6.2.3.2.1.7 The CBC-MAC (KS, _l_ **|** DA **|** m) is then calculated according to the algorithm described in section 6.2.2. If padding is performed prior to MAC calculation, the padding data p is not transmitted because the receiver can compute them, knowing the padding algorithm used.

6.2.3.2.1.8 In the case of a DT SaPDU the message m = ‘000’ **|** MTI **|** DF **|** SaUD consists of the message type identifier (MTI) indicating a DT SaPDU, the direction flag (DF), and the Safety-User Data SaUD.

6.2.3.2.1.9 Concerning the AU2 SaPDU, the message m = ETY **|** MTI **|** DF **|** SA **|** SaF **|** auth2 consists of the ETCS ID type, the message type identifier (MTI) indicating AU2 SaPDU, the direction flag (DF), the source address (SA), the safety features (SaF) and the corresponding authentication message auth2 = "Ra **|** Rb **|** B".

6.2.3.2.1.10 Concerning the AU3 SaPDU, the message m = ‘000’ **|** MTI **|** DF **|** auth3 consists of the message type identifier (MTI) indicating AU3 SaPDU, the direction flag (DF), and the corresponding authentication message auth3 = Rb **|** Ra.

6.2.3.2.1.11 In the case of the AR SaPDU the message m = ‘000’ **|** MTI **|** DF consists of the message type identifier (MTI) indicating the AR SaPDU and the direction flag (DF).

6.2.3.2.1.12 The direction flag is used as a protection against reflection attacks. It is initialised during connection set-up. Its value is zero when the initiator transmits a message and one when the responder of the connection transmits a message.

6.2.3.2.1.13 If an error occurs during the MAC computation the error management is informed and takes over further actions. If no error occurs the output of the MAC computation is the MAC of the message m to be transmitted.

#### **Procedure 2: Message Origin Authentication (MAC) on Reception (m, KS, MAC'(m’))**

- **Input:** Message m including a direction flag, cryptographic triple key KS which is shared between the sender and receiver (DA is the identity of the receiver), and MAC'(m’), which is the MAC computed for m’ by the sender.

- **Procedure:** 1.) Append the destination address (DA) in front of the message m: "DA | m". 2.) Compute length _l_ of the string (DA | m) in octets and append length (2 octets<sup>3</sup> ) in front of the string for MAC computation, e.g. " _l_ | DA | m".

> 3 The bits in the two octets are numbered from 16 to 1, where bit 1 is the lowest order bit.

<!-- end of page 26 -->

   - 3.) If the length of the message ( _l_ | DA | m) in bits is not a multiple of 64 then perform padding as defined above for _l_ | DA | m and append padding data p;" ( _l_ | DA | m | p)

   - 4.) Compute MAC for the string ( _l_ | DA | m | p) using the CBC-MAC function and the cryptographic triple key Ks : CBC-MAC(KS, _l_ | DA | m | p)

   - 5.) Compare MAC with MAC'.

   - 6.) Verify the value of the direction flag

- **Output:** Message m is forwarded to the SaS-user if MAC = MAC' and the value of the direction flag is correct. Otherwise, inform the error management.

6.2.3.2.1.14 On reception of a DT SaPDU, an MA SaPDU, an AU2 SaPDU, an AU3 SaPDU, or an AR SaPDU, a MAC is computed in a similar way to the transmission case. The input parameters are the message m, the cryptographic triple key Ks and the MAC transmitted as part of the received SaPDU. The receiver of the message uses the same parameters, i.e. cryptographic key and algorithms, as the transmitter of the message, derived from the sender and receiver identities and the type of message. The message m consists of the same parts as described above. The receiver adds its ETCS identity (DA) and computes the length _l_ of the string "DA **|** m" which has to be added before the message m for the MAC computation and the padding data p, if necessary.

6.2.3.2.1.15 If this MAC for " _l_ **|** DA **|** m **|** p" is equal to the MAC transmitted as part of the SaPDU and if the value of the direction flag is correct the user data are forwarded to the SaSuser. If an error occurs, e.g. the value of the direction flag is invalid, the MACs are not equal or there exists no cryptographic key for the underlying connection, the error management is informed and takes over further actions. Normally the evaluation starts with checking the MAC and only if it is correct is the information in the PDU used. The AU2 is an exception to this rule since some of the information inside the PDU is needed to calculate the MAC.

#### **6.2.3.2.2 Peer Entity Authentication**

6.2.3.2.2.1 Peer entity authentication is a safety procedure, which is used during connection set-up to compute the session key.

#### **Procedure 3: Peer Entity Authentication (ETCS ID A, ETCS ID B, KAB)**

**Input:** ETCS ID of A and B, authentication triple key (KAB) shared between A and B.

**Procedure:** Peer Entity Authentication Protocol as defined in Figure 6 **Output:** In the non error case: successful authentication of A and B against each other, and a session triple key which A and B share

**Error case** : No safety connection between A and B, and the error management is informed

<!-- end of page 27 -->

6.2.3.2.2.2 Peer entity authentication is performed during connection set-up. Its input parameters are the ETCS IDs of A and B which are authenticated against each other and the authentication triple key KAB shared between A and B. The ETCS IDs of A and B are unique identifiers. The authentication key has been previously established between A and B using a logical or physical key establishment mechanism.

<!-- Start of picture text -->
partner A partner B<br>(called) (calling)<br>(AU1) "Text1  RB “<br>(AU2) "Text2  RA  CBC-MAC  (KS, Text3   RA  RB  DA  p )”<br>(AU3) “Text4  CBC-MAC  (KS, Text5   RB  RA   p )”<br><!-- End of picture text -->

**Figure 6 Sa-Protocol used for peer entity authentication and key generation**

6.2.3.2.2.3 The initiator B of the connection set-up starts the safety association (SA) protocol (see Figure 6) when requesting a transport connection. For the computation of the MAC it makes use of the message origin authentication procedure.

6.2.3.2.2.4 The initiator B transmits a random number RB of length 64 bits which is generated by B as part of the first authentication message AU1SaPDU to his communication partner A. The random number RB must be stored (dedicated to the link) before sending AU1SaPDU. After receiving this message, A generates as part of a second authentication message AU2 SaPDU, a random number RA of length 64 bits, and a MAC computed over the text field text3, the two random numbers RA and RB, the identity of B (in this context B is the calling ETCS ID) and padding bits. For the computation of the MAC the session key KS is computed using the session key generation function as described in section 6.2.3.2.3 and the parameters RA, RB and the authentication key KAB. After receiving the message AU2 SaPDU and deriving the key KS, B checks the correctness of the second authentication message received from A. Then, B computes a MAC over the text field text5, and the two random numbers RA and RB and transmits it as part of AU3 SaPDU to A. Finally, A checks AU3 SaPDU using the triple key KS.

6.2.3.2.2.5 The fields:

text1 = "ETY **|** MTI **|** DF **|** SA **|** SaF", where SA = calling ETCS ID,

text2 = "ETY **|** MTI **|** DF **|** SA **|** SaF", where SA = responding ETCS ID, text3 = " _l_ **|** DA **|** ETY **|** MTI **|** DF **|** SA **|** SaF",

where DA = calling ETCS ID and SA = responding ETCS ID, text4 = " ‘000’ **|** MTI **|** DF",

<!-- end of page 28 -->

text5 = " _l_ **|** DA **|** ‘000’ **|** MTI **|** DF", where DA = responding ETCS ID

consist of the ETCS ID type (ETY), the message type identifier (MTI) indicating an authentication SaPDU, the direction flag (DF), the source address (SA) (ETCS Identity on 24 bits), the destination address (DA) (ETCS Identity on 24 bits), and the safety feature SaF.

6.2.3.2.2.6 If no error occurs the output of the peer entity authentication procedure is a successful authentication of A and B against each other and a session key, which is shared between A and B. If an error occurs during the peer entity authentication procedure, then the error management is informed and takes over. No safety connection is established between A and B in this case.

#### **6.2.3.2.3 Cryptographic Keys**

6.2.3.2.3.1 Note: key management activities are the matter of other UNISIG Subsets.

6.2.3.2.3.2 The following table describes a three level key hierarchy.

**Table 5 Extended key hierarchy**

|**Level**|**Purpose**|
|---|---|
|3 Transport keys<br>(KTRANS)|Protection of management communication between KMC and RBC or train for<br>establishment or revocation of authentication keys.|
|2 Authentication keys<br>(KMAC)|Session key derivation in connection establishment.|
|1 Session keys<br>(KSMAC)|Protection of data transfer between safety entities.|

6.2.3.2.3.3 The level 3 keys (KTRANS) are used by the Key Management Centre to distribute level 2 keys or to change key assignments permanently, including revocation of keys and the introduction of new entities. The Key Management Centre shares a transport key with each entity.

6.2.3.2.3.4 The level 2 keys (KMAC; also referred as KAB) are used for session key derivation. Authentication keys (KMAC keys) are level 2 keys, which have been assigned to particular entities. Two entities sharing a common level 2 key can set up a safety association.

6.2.3.2.3.5 The key validity period shall be checked using UTC time and only before establishing a safe connection with a peer entity

6.2.3.2.3.6 Note: management of UTC time (for example derivation and unavailability) is an implementation matter.

6.2.3.2.3.7 Note: if the validity period expires while a safe connection is established, this will not lead to connection release.

6.2.3.2.3.8 The length of a level 2 triple key has to be 192 bits including parity bits, consisting of three 64-bit DES-keys for the single DES with modified MAC algorithm 3.

6.2.3.2.3.9 The level 1 keys (KSMAC; also referred as KS) are derived during peer entity authentication by use of level 2 keys. They are used for the protection during connection

<!-- end of page 29 -->

set-up and data transfer, i.e. MAC computation, in a single session only. They are connection specific and can only be shared by entities that share an authentication key (KMAC key).

6.2.3.2.3.10 Session keys (KSMAC) are DES triple keys, which are used symmetrically, i.e. for both communication directions.

6.2.3.2.3.11 The length of a level 1 triple key is equal to 192 bits consisting of three 64-bit DESkeys.

6.2.3.2.3.12 Session keys are generated using the key derivation function as described in the section below. Both communication partners contribute with their 64-bit (pseudo) random number to the session key.

6.2.3.2.3.13 During the peer entity authentication a session key is derived between two communicating entities using the common authentication triple key KMAC = (K1, K2, K3) of these entities. One 192-bit KSMAC triple key shall be generated by the key derivation procedure. The derivation of the corresponding DES session keys is specified as follows between entities A and B:

6.2.3.2.3.14 The random numbers RX (X {A,B}) are split into a left (RX<sup>L</sup> ) and a right (RX<sup>R</sup> ) 32bit block:

RA = RA<sup>L</sup> **|** RA<sup>R</sup> RB = RB<sup>L</sup> **|** RB<sup>R</sup>

6.2.3.2.3.15 The three 64-bit DES keys KS1, KS2 and KS3 are calculated according the formulas: KS1 := MAC (RA<sup>L</sup> **|** RB<sup>L</sup> , KAB) = DES (K3, DES<sup>-1</sup> (K2 , DES(K1, RA<sup>L</sup> **|** RB<sup>L</sup> ))) KS2 := MAC (RA<sup>R</sup> **|** RB<sup>R</sup> , KAB) = DES (K3, DES<sup>-1</sup> (K2 , DES(K1, RA<sup>R</sup> **|** RB<sup>R</sup> ))) KS3 := MAC (RA<sup>L</sup> **|** RB<sup>L</sup> , K'AB) = DES (K1, DES<sup>-1</sup> (K2 , DES(K3, RA<sup>L</sup> **|** RB<sup>L</sup> ))) where **|** is the concatenation operator, _DES_ is the DES encryption function, and _DES_<sup>_-1_</sup> is the inverse DES encryption function, or decryption.

6.2.3.2.3.16 The length of a level 1 triple key is equal to 192 bits including parity bits. In order to get three 64-bit DES-keys for the single DES with modified MAC algorithm 3 from the three 64-bit session key generator outputs, each eighth bit of the 192 bits should be set to an odd-parity value as defined in the standard [ANSI X3.92]. However, setting the parity bits is an implementation matter where the key is internal to an equipment.

6.2.3.3 **Communication procedures**

#### **6.2.3.3.1 Connection establishment**

6.2.3.3.1.1 The following procedures are applied during connection establishment:

   - The safety address information is passed to the CFM

   - The peer entity authentication procedure is applied.

#### **6.2.3.3.2 Data transfer**

<!-- end of page 30 -->

6.2.3.3.2.1 The purpose of the data transfer phase is to permit the safe transfer of normal user data between the two SaS-users connected by the safety connection. The following procedures are applied:

   - The message origin authentication procedure (refer to section 6.2.3.2.1.1) for normal data;

   - The service primitive’s procedures provided by the transport layer.

#### **6.2.3.3.3 Connection release**

6.2.3.3.3.1 The safety connection is released by a SaS-user request, by a transport service provider action, or by an error handling action of the safety layer.

6.2.3.3.3.2 The authentication of the connection release phase is not required.

#### **6.2.3.3.4 Error handling**

6.2.3.3.4.1 Errors can occur during the connection set-up in the peer entity authentication, during the data transfer, and in the management of the safety protocol.

6.2.3.3.4.2 All errors have to be reported to the local SaS-user by the Sa-REPORT.indication or by the Sa-DISCONNECT.indication primitives.

6.2.3.3.4.3 Different error cases are handled by different strategies:

   - Ignore the safety relevant event;

   - Optionally, ignore the safety relevant event and indicate the error to the SaS-user by Sa-REPORT.indication primitive;

   - Release the safety connection, release of transport connection and indicate the error to the SaS-user by Sa-DISCONNECT.indication primitive.

6.2.3.3.4.4 It is the matter of the SaS user to react to the indicated event in a proper way.

6.2.3.3.4.5 Note: Registration of safety relevant errors is the matter of the application.

### **6.2.4 Time sequences**

6.2.4.1 The flow of control information and user data is described in this chapter.

#### 6.2.4.2 **Connection establishment**

6.2.4.2.1 When the Sa-CONNECT.request primitive requests a safety connection, the safety layer requests transport connection establishment by means of the service primitive T- CONNECT.request. This service primitive includes the first message of the peer entity authentication procedure (AU1 SaPDU) as user-data.

6.2.4.2.2 Note: AU1 and AU2 SaPDUs are exchanged by means of T-CONNECT primitives.

6.2.4.2.3 The called peer transport entity indicates the transport connection establishment request to its safety layer using the service primitive T-CONNECT.indication. The AU1 SaPDU is forwarded to the safety layer in this service primitive as user-data. At the end of the first step the called safety layer entity evaluates the AU1 SaPDU.

<!-- end of page 31 -->

6.2.4.2.4 If it is accepted, the safety entity responds to the TC establishment request by means of the service primitive T-CONNECT.response. It includes the second message of the peer entity authentication protocol (AU2 SaPDU) as user-data.

6.2.4.2.5 There is no QoS negotiation between peer entities.

6.2.4.2.6 AU1 and AU2 SaPDUs can be used for safety feature negotiation, corresponding to a version number. The initiating safety entity may request in the AU1 SaPDU a certain safety feature. The safety feature in the AU2 SaPDU will be the version accepted by the responding safety entity. If the initiating safety entity requests a safety feature not available, the safety feature in the AU2 SaPDU will be the default value.

6.2.4.2.7 On reception, the calling transport entity informs the safety layer of the successful establishment of the transport connection using the service primitive T- CONNECT.confirmation. The AU2 SaPDU is forwarded to the safety layer as user-data within this service primitive.

6.2.4.2.8 The safety entity then generates the AU3 SaPDU that contains the third message of the authentication protocol (auth3), as user-data. It uses the T-DATA.request service primitive to forward this message to the transport layer.

6.2.4.2.9 On reception, the transport entity uses the service primitive T-DATA.indication to forward the AU3 SaPDU to the safety layer as user-data. The safety entity evaluates the AU3 SaPDU.

6.2.4.2.10 In the case of a successful AU3 SaPDU evaluation, the safety entity forwards the service primitive Sa-CONNECT.indication to the safety user (i.e. ATP application).

6.2.4.2.11 If the safety user accepts the safety connection establishment request, it responds using the service primitive Sa-CONNECT.response.

6.2.4.2.12 The safety entity on the called side sends the authentication response message in the AR SaPDU by means of the T-DATA.request and T-DATA.indication primitives to its peer safety entity.

6.2.4.2.13  Note: The authentication response message is not required by the peer entity authentication procedure. It is added to provide an OSI-like confirmed service.

6.2.4.2.14 After a successful evaluation of this SaPDU including the authentication data, the safety entity informs the SaS-user that a safety connection is now successfully established, using the service primitive Sa-CONNECT.confirmation.

6.2.4.2.15 When the Sa-CONNECT.confirmation is received, the calling SaS user is able to send data to the peer user through the safe connection. The called SaS user is able to request the data transfer immediately after the Sa-CONNECT.response primitive.

<!-- end of page 32 -->

###### Safety layer

Safety layer

<!-- Start of picture text -->
Sa-CONN.request<br>T-CONN.req<br>Set Testab<br>AU1SaPDU<br>T-CONN.ind<br>T-CONN.resp<br>AU2 SaPDU<br>T-CONN.conf<br>T-DATA.request<br>AU3 SaPDU<br>T-DATA.ind<br>Sa-CONN.ind<br>Sa-CONN.resp<br>T-DATA.req<br>AR SaPDU<br>T-DATA.ind<br>Sa-CONN.conf<br>Stop T estab<br>Logical data flow (Safety PDU)<br>Physical data flow (service primitive)<br><!-- End of picture text -->

**Figure 7 Time sequence during connection establishment**

<!-- end of page 33 -->

6.2.4.2.16 The maximum connection establishment delay timer is used for detecting unacceptable delay during the connection establishment. The timer Testab is set after reception of the SaCONNECT.request and is stopped before generation of the Sa-CONNECT.confirmation. In the case of time-out, a Sa-DISCONNECT.indication is generated including a proper reason. All SaPDUs will be ignored if received after the timer elapses.

6.2.4.2.17 The safety layer entity of an RBC must be able to handle the establishment of more than one safe connection at the same time. The on-board system must be able to have contact with two entities at the same time to allow seamless area change. Other situations may also require this feature.

6.2.4.3 **Data Transfer**

6.2.4.3.1 The protocol sequence of Figure 8 shows how data are transmitted by the SFM. The user data of a Sa-DATA.request primitive are included in the user data part of the DT SaPDU. The transfer of the DT SaPDU uses the transport service primitives T-DATA.request and T-DATA.indication.

<!-- Start of picture text -->
Safety layer Safety layer<br>Sa-DATA.req<br>T-DATA.req<br>Sa-DATA.req DT SaPDU<br>T-DATA.ind<br>Sa-DATA.ind<br>Sa-DATA.req<br>Sa-DATA.ind<br>Error<br>Sa-REPORT.ind<br><!-- End of picture text -->

**Figure 8 Time sequence during data transfer (example)**

6.2.4.3.2 The receiving safety layer entity:

   - Checks the format of the SaPDU and the protocol control information;

   - Checks the MAC and integrity.

6.2.4.3.3 The user data of a safe transmitted DT SaPDU are included in a Sa-DATA.indication primitive.

6.2.4.3.4 In the case of a safety problem with the DT SaPDU, the Sa-REPORT.indication or the SaDISCONNECT.indication indicates this to the safety user.

6.2.4.4 **Connection Release**

<!-- end of page 34 -->

6.2.4.4.1 The connection release is requested by means of the primitive Sa-DISCONNECT.request. The safety layer then requests the transport layer to disconnect by means of T- DISCONNECT.request. The DI SaPDU is included in the user data of the T- DISCONNECT.request primitive (Figure 9).

6.2.4.4.2 Peer entities are informed about the disconnection by means of T- DISCONNECT.indication and Sa-DISCONNECT.indication.

6.2.4.4.3 Authentication of the connection release phase is not required.

6.2.4.4.4 In the case of a service provider or safety layer originated connection release, this release will be indicated to both SaS-users by Sa-DISCONNECT.indication containing the respective reason.

6.2.4.4.5 Note: In the case of a service-provider-caused release, SaPDUs can be lost due to corrupted TPDUs.

<!-- Start of picture text -->
Safety layer Safety layer<br>Sa-DISC.request<br>T-DISC.req<br>DI SaPDU<br>T-DISC.ind<br>Sa-DISC.indication<br><!-- End of picture text -->

**Figure 9  Time sequence during connection release (SaS-user originated)**

### **6.2.5 Structure and encoding of safety PDUs**

#### 6.2.5.1 **General structure of SaPDUs**

6.2.5.1.1 All the safety protocol data units (SaPDUs) shall contain an integral number of octets. The octets in a SaPDU are numbered starting from 1 and increasing in the order they are put into a SaPDU. The bits in an octet are numbered from 8 to 1, where bit 1 is the lowest order bit. If a SaPDU field uses more than one octet, bit 8 of the first octet contains the most significant bit of the field.

6.2.5.1.2 When consecutive octets are used to represent a binary number, the lower octet number has the most significant value.

6.2.5.1.3 The meaning of an indication ”Reserved” is:

   - The transmitting side has to insert the value ”0”;

   - The receiving side has to interpret as ”Don’t care”.

6.2.5.1.4 SaPDUs shall contain, in the following order:

<!-- end of page 35 -->

   - The header (consisting of the message type identifier field and the direction flag field);

   - The data field (if present);

   - The MAC field (if applicable).

6.2.5.1.5 The structure is illustrated in Table 6.

**Table 6 Structure of a Safety PDU**

|**Header**||**Data**|**MAC**|
|---|---|---|---|
|**Type + Direction**|||Not used for AU1 or DI SaPDU|
|1 Octet|Variable||8 octets|

#### **6.2.5.1.6 Message Type Identifier field**

6.2.5.1.6.1 The message type identifier (MTI) specifies the type of the SaPDU (Table 7).

**Table 7 Safety PDUs**

|**Type**|**Type Code**|**Name**|
|---|---|---|
|AU1 SaPDU|0001|First authentication SaPDU (AU1)|
|AU2 SaPDU|0010|Second authentication SaPDU (AU2)|
|AU3 SaPDU|0011|Third authentication SaPDU (AU3)|
|AR SaPDU|1001|Response to third authentication SaPDU (AR)|
|DT SaPDU|0101|Data SaPDU (DT)|
|DI SaPDU|1000|Disconnect SaPDU (DI)|

#### **6.2.5.1.7 Direction flag field**

6.2.5.1.7.1 The direction flag is used as a protection against reflection attacks. It is initialised during connection set-up. Its value is zero when the connection initiator transmits a message and one when the responder of the connection transmits a message.

6.2.5.1.7.2 The message type identifier field and direction flag field together make up the header.

#### **6.2.5.1.8 MAC field**

6.2.5.1.8.1 The MAC computation is specified in the section 6.2.2.

#### 6.2.5.2 **Connection establishment PDU**

6.2.5.2.1 AU1 and AU2 SaPDUs are exchanged by means of T-CONNECT primitives.

6.2.5.2.2 The **first authentication SaPDU** consists of the fields specified in Table 8.

**Table 8 Structure of the AU1 SaPDU**

|**Octet**|**Bit**<br>**`8765 4321`**|**Field**<br>**name**||**Field**|
|---|---|---|---|---|
|1|`xxx. ....`|”ETY”|ETCS ID type of the field ”SA”||
||`000. ....`<br>`001. ....`<br>`010. ....`<br>`011. ....`||Radio in-fill unit<br>RBC<br>Engine<br>Reservedfor Balise||

<!-- end of page 36 -->

||`100. ....`<br>`101. ....`<br>`110. ....`||Reserved for Field element (level crossing etc)<br>Key management entity<br>Interlockingrelated entity|
|---|---|---|---|
|1|`...0 001.`|”MTI”|Message Type Identifier:**AU1**|
|1|`.... ...0`|”DF”|Direction Flag: ’0’B indicates the direction to the responder|
|2<br>3<br>4|`xxxx xxxx`<br>`xxxx xxxx`<br>`xxxx xxxx`|”SA”|Calling ETCS ID|
|5|`Xxxx xxxx`<br>`0000 0001`|”SaF”|Requested Safety feature<br>Single DES with modified MAC algorithm 3<br>All other values are reserved|
|6<br>...<br>13|`Xxxx xxxx`<br>`...`<br>`xxxx xxxx`|"RB"|Random number RBof the first authentication message|

#### 6.2.5.2.3 The **second authentication SaPDU** consists of the fields specified in Table 9.

**Table 9 Structure of the AU2 SaPDU**

|**Octet**|**Bit**<br>**`8765 4321`**|**Field**<br>**name**|**Field**|
|---|---|---|---|
|1|`xxx. ....`|”ETY”|ETCS ID type of the field ”SA”<br>See Table 8|
|1|`...0 010.`|”MTI”|Message Type Identifier:**AU2**|
|1|`.... ...1`|”DF”|Direction Flag: ’1’B indicates the direction to the initiator|
|2<br>3<br>4|`xxxx xxxx`<br>`xxxx xxxx`<br>`xxxx xxxx`|”SA”|Responding ETCS Id.|
|5|`xxxx xxxx`<br>`0000 0001`|”SaF”|Accepted safety features.<br>Single DES with modified MAC algorithm 3<br>All other values are reserved.|
|6<br>...<br>13|`xxxx xxxx`<br>`...`<br>`xxxx xxxx`|"RA"|Random number RAof the second authentication message|
|14<br>...<br>21|`xxxx xxxx`<br>`...`<br>`xxxx xxxx`||MAC field.<br>The MAC is computed according to the rules given in the peer entity<br>and message origin authentication procedure.|

#### 6.2.5.2.4 The **third authentication SaPDU** consists of the fields specified in Table 10.

##### **Table 10 Structure of the AU3 SaPDU**

|**Octet**|**Bit**<br>**`8765 4321`**|**Field**<br>**name**|**Field**|
|---|---|---|---|
|1|`000. ....`|”ETY”|Reserved|
|1|`...0 011.`|”MTI”|Message Type Identifier:**AU3**|
|1|`.... ...0`|”DF”|Direction Flag: ’0’B indicates the direction to the responder|
|2<br>...<br>9|`xxxx xxxx`<br>`...`<br>`xxxx xxxx`||MAC field.<br>The MAC is computed according to the rules given in the peer entity<br>and message origin authentication procedure|

<!-- end of page 37 -->

#### 6.2.5.2.5 The **Authentication Response SaPDU** consists of the fields specified in Table 11.

##### **Table 11 Structure of the AR SaPDU**

|**Octet**|**Bit**<br>**`8765 4321`**|**Field**<br>**name**|**Field**|
|---|---|---|---|
|1|`000. ....`|”ETY”|Reserved|
|1|`...1 001.`|”MTI”|Message Type Identifier:**AR**|
|1|`.... ...1`|”DF”|Direction Flag: ’1’B indicates the direction to the initiator|
|2<br>...<br>9|`xxxx xxxx`<br>`...`<br>`xxxx xxxx`||MAC field.<br>the MAC computed according to the rules given in the peer entity and<br>message origin authentication procedure|

#### 6.2.5.3 **Data Transfer SaPDU**

#### 6.2.5.3.1 The **Data SaPDU** consists of the fields specified in Table 12.

**Table 12 Structure of the DT SaPDU**

|**Octet**|**Bit**<br>**`8765 4321`**|**Field**<br>**name**|**Field**|
|---|---|---|---|
|1|`000. ....`|||
|1|`...0 101.`|”MTI”|Message Type Identifier:**DT**|
|1|`.... ...x`|”DF”|Direction Flag|
|2<br>...<br>2+n-1|`xxxx xxxx`<br>`...`<br>`xxxx xxxx`||User data (length n>=1 octet):<br>user data of the corresponding SaPDU|
|2+n|`xxxx xxxx`||MAC field.|
|...<br>2+n+7|`...`<br>`xxxx xxxx`|||

#### 6.2.5.4 **Disconnect SaPDU**

#### 6.2.5.4.1 The **Disconnect SaPDU** consists of the fields specified in Table 13.

##### **Table 13 Structure of the DI SaPDU**

|**Octet**|**Bit**<br>**`8765 4321`**|**Field**<br>**name**|**Field**|
|---|---|---|---|
|1|`000. ....`|||
|1|`...1 000.`|”MTI”|Message Type Identifier:**DI**|
|1|`.... ...x`|”DF”|Direction flag.|
|2|`xxxx xxxx`||Reason field: the reason for the disconnect.|
|3|`xxxx xxxx`||SUB-reason field: the sub-reason for the disconnect.|

### **6.2.6 State table**

6.2.6.1 The state transition diagram and the state table are symmetrical for on-board and trackside SFM.

<!-- end of page 38 -->

#### 6.2.6.2 **General**

6.2.6.2.1 This section describes the safety protocol in terms of state tables. The state tables show the state of a safety layer entity, the events that occur in the protocol, the actions taken and the resultant state. The state tables are conceptual and do not impose any constraints on the implementation.

6.2.6.2.2 The state tables also define the mapping between safety service primitives and protocol events that safety service users (SaS users) can expect.

6.2.6.2.3 The state tables do not necessarily describe all possible combinations of sequences of events at safety and transport service boundary, nor do they describe the exact mapping between SaPDUs and TSDUs.

#### 6.2.6.3 **Conventions**

6.2.6.3.1 States are represented in the tables by their abbreviation, as defined in Table 14.

##### **Table 14 States**

|**State abbreviation**|**State name**|
|---|---|
|WFTC|Wait for transport connection|
|WFAR|Wait for the authentication response SaPDU|
|DATA|Safety connection is opened and ready for data transfer|
|WFAU3|Wait for the third authentication message|
|WFRESP|Wait for Sa-CONNECT.response|
|IDLE|Safety connection is closed or does not exist|

<!-- end of page 39 -->

<!-- Start of picture text -->
Outgoing connection establishment Incoming connection establishment<br>Sa-CONN.req IDLE<br>T-CONN.ind<br>(+AU1 SaPDU)<br>WFTC WFAU3<br>T_CONN.conf T-DATA.ind<br>(+AU2 SaPDU) (+AU3 SaPDU)<br>WFAR DI SaPDU WFRESP<br>Sa-DISC.req<br>T-DATA.ind<br>(+AR SaPDU) Sa-CONN.resp<br>DATA<br>normal transition<br>DT SaPDU<br>abnormal transition<br><!-- End of picture text -->

##### **Figure 10 State transition diagram of the safety layer entity**

6.2.6.3.2 The intersection of each state and incoming event that is invalid is left blank in the state tables. The action to be taken in this case shall be one of the following:

   - for an event related to the safety service (i.e. coming from the SaS-user), take no action;

   - for an event related to a received SaPDU, follow the procedure for treatment of protocol errors if the state of the supporting transport connection makes it possible;

   - for an event falling into neither of the above categories (including those which are impossible by the definition of the behaviour of the safety entity or SaS-provider), take no action.

6.2.6.3.3 At each intersection of state and event which is valid, the state tables specify an action which may include one of the following:

   - one action constituted of a list of any number of outgoing events (none, one, or more) given by their abbreviation defined in Table 16 followed by certain special actions (see Table 18), if applicable, and the abbreviation of the resultant state (see Table 14);

   - conditional actions separated by a semi-colon (;). Each conditional action contains a predicate followed by a colon (:) and by an action as defined in a). The predicates are Boolean expressions given by their abbreviation and defined in Table 17. Only the action corresponding to the true predicate shall be taken.

<!-- end of page 40 -->

6.2.6.3.4 There is a unique association between the safety connection and the transport connection used. The mapping of the local references (SaCEPID and TCEPID) is a matter of the implementation.

6.2.6.3.5 Table 15 specifies the names and abbreviation of the incoming events classified as event originated by TS-provider, SaS-user or safety layer entity.

**Table 15 Incoming events**

|**Abbreviation**|**Origin of event**|**Name**|
|---|---|---|
|Sa-CONN.req|SaS-user|Sa-CONNECT.request primitive|
|Sa-CONN.resp|SaS-user|Sa-CONNECT.response primitive|
|Sa-DATA.req|SaS-user|Sa-DATA.request primitive|
|Sa-DISC.req|SaS-user|Sa-DISCONNECT.request primitive|
|T-DISC.ind|TS-provider|T-DISCONNECT.indication primitive|
|T-CONN.ind<br>(+AU1SaPDU)|TS-provider|T-CONNECT.indication primitive|
|T-CONN.conf<br>(+AU2SaPDU)|TS-provider|T-CONNECT.confirmation primitive|
|AU3 SaPDU|Safety layer entity|Authentication 3 SaPDU|
|AR SaPDU|Safety layer entity|Authentication response SaPDU|
|DI SaPDU|Safety layer entity|Disconnect Request SaPDU|
|DT SaPDU|Safety layer entity|Data SaPDU|
|time-out Testab|Safety layer entity|Connection establishment timer|

6.2.6.3.6 Table 16 specifies the names and abbreviations of the outgoing events classified as event originated by SaS-provider, TS-user or safety layer entity.

**Table 16 Outgoing events**

|**Abbreviation**|**Origin of event**|**Name**|
|---|---|---|
|Sa-CONN.ind|SaS-provider|Sa-CONNECT.indication primitive|
|Sa-CONN.conf|SaS-provider|Sa-CONNECT.confirmationprimitive|
|Sa-DATA.ind|SaS-provider|Sa-DATA.indication primitive|
|Sa-DISC.ind|SaS-provider|Sa-DISCONNECT.indication primitive|
|Sa-REPORT.ind|SaS-provider|Sa-REPORT.indication primitive|
|T-CONN.req<br>(+AU1SaPDU)|TS-user|T-CONNECT.request primitive|
|T-CONN.resp<br>(+AU2SaPDU)|TS-user|T-CONNECT.response primitive|
|T-DISC.req|TS-user|T-DISCONNECT.request primitive|
|AU3 SaPDU|Safety layer entity|Authentication 3  SaPDU|
|AR SaPDU|Safety layer entity|Authentication response SaPDU|

<!-- end of page 41 -->

|**Abbreviation**|**Origin of event**|**Name**|
|---|---|---|
|DI SaPDU|Safety layer entity|Disconnect Request SaPDU|
|DT SaPDU|Safety layer entity|Data SaPDU|

**Table 17 Predicates**

|**Name**|**Description**|
|---|---|
|Pre0|Sa-CONNECT. request unacceptable<br>•<br>at least the following parameter is required : application type<br>•<br>applicationtype error|
|Pre1|Unacceptable T-CONNECT.indication,<br>•<br>at least the following parameters are required : application type, user data<br>•<br>application type error<br>Unacceptable AU1 SaPDU<br>•<br>AU1 SaPDU format error<br>•<br>ETY,MTI,DF or SaF error<br>•<br>KMACnot available|
|Pre2|Unacceptable T-CONNECT.confirmation,<br>•<br>at least the following parameter is required:  user data<br>Unacceptable AU2 SaPDU<br>•<br>AU2 SaPDU format error<br>•<br>ETY,MTI,DF or SaF error<br>•<br>KMAC not available<br>•<br>MAC error|
|Pre3|Unacceptable AU3 SaPDU<br>•<br>AU3 SaPDU format error<br>•<br>ETY, MTI or DF error<br>•<br>MAC error|
|Pre4|Unacceptable AR SaPDU<br>•<br>AR SaPDU format error<br>•<br>ETY, MTI or DF error<br>•<br>MAC error|
|Pre 5|Erroneous SaPDU<br>•<br>MAC errorof DTSaPDU|
|Pre6|Unacceptable DT SaPDU<br>•<br>DT SaPDU length error<br>•<br>MTI error<br>•<br>DFerror(condition: noMAC error)|

6.2.6.3.7 The state table specifies the precise protocol to provide interoperability, but does not specify the implementation of the protocol.

##### **Table 18 Timer definitions**

|**Symbol**|**Name**|**Definition**|
|---|---|---|
|Testab|Connection<br>establishment  time|An upper bound for the time after which the local safety<br>entity will initiate the error handling procedure, if it does not<br>receive the authentication response message.|

##### **Table 19 Integrity actions**

<!-- end of page 42 -->

|**Abbreviation**|**Action**|
|---|---|
|a5|Set timer Testab|
|a6|Stop timer Testab|
|a19|Stop all timers; reset all counters.|

**Table 20 State table**

|**State**<br>**Event**|**IDLE**|**WFTC**|**WFAR**|**DATA**|**WFAU3**|**WFRESP**|
|---|---|---|---|---|---|---|
|Sa-CONN.req|Pre0: Sa-<br>DISC.ind,<br>IDLE;<br>not Pre0:<br>T-<br>CONN.req<br>(AU1<br>SaPDU),<br>a5,WFTC||||||
|Sa-CONN.resp||||||AR SaPDU,<br>DATA|
|Sa-DATA.req||||DT SaPDU,<br>DATA|||
|Sa-DISC.req||T-DISC.req<br>a19, IDLE<br>Note1|T-DISC.req<br>(+DI SaPDU),<br>a19, IDLE|<br>T-DISC.req<br>(+DI SaPDU),<br>a19, IDLE||T-DISC.req<br>(+DI SaPDU)<br>a19, IDLE|
|T-CONN.ind<br>(+AU1SaPDU)|Pre1:T-<br>DISC.req<br>(+DI SaPDU),<br>IDLE;<br>not Pre1:<br>T-CONN.resp<br>(+AU2 SaPDU)<br>WFAU3||||||
|T-CONN.conf<br>(+AU2SaPDU)||Pre2: Sa-<br>DISC.ind,<br>T-DISC.req,<br>a19, IDLE<br>Note1<br>not Pre2:<br>AU3 SaPDU,<br>WFAR|||||
|T-DISC.ind<br>or<br>T-DISC.ind<br>(+DI SaPDU)||Sa-DISC.ind,<br>a19, IDLE|Sa-DISC.ind,<br>a19, IDLE|<br>Sa-DISC.ind<br>a19, IDLE|a19, IDLE|Sa-DISC.ind<br>a19, IDLE|
|AU3 SaPDU|||||Pre3:<br>T-DISC.req<br>(+DI SaPDU),<br>a19, IDLE<br>not Pre3: Sa-<br>CONN.ind,<br>WFRESP||

<!-- end of page 43 -->

|**State**<br>**Event**|**IDLE**|**WFTC**|**WFAR**|**DATA**|**WFAU3**|**WFRESP**|
|---|---|---|---|---|---|---|
|AR SaPDU|||not Pre4: Sa-<br>CONN.conf,<br>a6, DATA;<br>Pre4:<br>Sa-DISC.ind,<br>T-DISC.req<br>(+DI SaPDU),<br>a19, IDLE||||
|DT SaPDU||||not Pre5 and not<br>Pre6:<br>Sa-DATA.ind,<br>DATA;<br>Pre5:<br>Sa-REPORT.ind,<br>DATA Note 2<br>Pre6:<br>Sa-DISC.ind,<br>T-DISC.req (+DI<br>SaPDU), a19,<br>IDLE|||
|time-out Testab||Sa-DISC.ind,<br>T-DISC.req,<br>a19, IDLE<br>Note1|<br>Sa-DISC.ind,<br>T-DISC.req<br>(+DI SaPDU),<br>a19,IDLE||||

Notes:

> 1. The DI SaPDU is not contained.

> 2. Optional Sa-REPORT.indication delivered to the SaS user, if supported.

## **6.3 Safety Protocol Management**

### **6.3.1 Functions of the Safety Protocol Management**

6.3.1.1 The safety protocol management defines the configuration management needed to handle the parameters of the safety protocol, and the supervision and diagnostics of the safety protocol. The main emphasis is placed on achieving technical interoperability between the on-board and the trackside unit with respect to the safety protocol management.

6.3.1.2 All details of the specification, which are implementation dependent like the generation, storage, and deletion of keys, or error logging are not covered by this specification.

6.3.1.3 The over-the-air updating of keys is possible, but not specified here, see [Subset-137].

6.3.1.4 The management of the safety layer protocol is embedded in the SFM sub-system. Parts of it are clearly safety related and have to be realised in a safe environment whereas other parts are not. The details depend on the particular implementation and are not covered by this specification.

### **6.3.2 Configuration Management**

6.3.2.1 The configuration management defines the parameters needed for the execution of the safety protocol and its management, and the functions to manage them.

6.3.2.2 **Address Parameters**

<!-- end of page 44 -->

6.3.2.2.1 The safety protocol uses the ETCS Identities for addressing. The ETCS Identities are unique within the scope of the respective ETCS ID type. The ETCS ID together with the application type identifies the safety service user.

**Table 21 ETCS Identity (see ETCS SRS [Subset-026] chapter 7)**

|ETCS ID|Range of values<br>**Octet1         Octet2          Octet3**<br>**8765 4321 8765 4321 8765 4321**|<br>Description|
|---|---|---|
|ETCS ID of on-<br>board|`tttt tttt tttt tttt tttt tttt`||
|ETCS ID of RBC|`cccc cccc ccrr rrrr rrrr rrrr`<br>`.... .... ..11 1111 1111 1111`|c…c   Country or region ID<br>r…r    RBC ID<br>ETCSIDunknown|
|ETCS ID of radio<br>in-fill unit (ETCS<br>level1)|`cccc cccc ccrr rrrr rrrr rrrr`<br>`.... .... ..11 1111 1111 1111`|c…c   Country or region ID<br>r…r    RIU ID<br>ETCSIDunknown|
|ETCS ID of KM<br>entity|`cccc cccc cckk kkkk kkkk kkkk`|c…c   Country or region ID<br>k…k    Keymanagement entityID|

6.3.2.2.2 Note: The definition of ETCS ID structure and values is out of scope for this FIS.

6.3.2.2.3 Identities are used during the connection set-up to compute the corresponding safety association, i.e. the ETCS IDs are relevant for the execution of the safety procedure peer entity authentication.

6.3.2.2.4 A safety association is defined between two ETCS-Identities as soon as they share a common authentication key to set up a safe connection. Besides the authentication key, also the other parameters have to be defined for every safety association.

6.3.2.2.5 Additionally, the transport service access points (TSAPs) are used by the safety layer to access the transport layer.

#### 6.3.2.3 **Timer Parameter**

6.3.2.3.1 The parameter maximum connection establishment delay is used for detecting unacceptable delay during the connection establishment.

**Table 22 Safety layer timer parameter**

|**Parameter**|**Symbol**|**Applied value**|**Comments**|
|---|---|---|---|
|Maximum connection<br>establishment delay|Testab|40 s|Depends on the<br>communication network|

### **6.3.3 Supervision and Diagnostics**

6.3.3.1 The supervision and diagnostics describes the error management of the safety layer and the monitoring and auditing of safety relevant events.

6.3.3.2 The error management defines the error handling, and the error reporting to the application layer, as far as it is needed for interoperability reasons.

6.3.3.3 Note: Error logging by SFM is not required. It has to be done by the application, if required.

<!-- end of page 45 -->

#### 6.3.3.4 **Error Reporting**

6.3.3.4.1 All safety relevant errors that occur in the safety layer which are treated by the application have to be reported to the application immediately after their occurrence. Errors handled internally by the safety layer management, may be reported to the application but do not have to be.  There are two possibilities for reporting errors to the application:

   - If the error leads to a mandatory connection release, it can be reported to the application using the service primitive Sa-DISCONNECT.indication. The application is informed about the type of the error using the parameter **disconnect reason** .

   - If the error is only treated internally by the safety layer management or does not lead to a mandatory connection release it can be reported optionally to the application using the service primitive Sa-REPORT.indication. The application is informed about the type of the error by the parameter pair ( **reason code, sub-reason code)** .

#### 6.3.3.5 **Error Handling**

6.3.3.5.1 If an error occurs in the safety layer the error management has to undertake the following actions depending on the reason and sub-reason of this error. One indicated reason may be caused by different sub-reasons which may be detected by symptoms requiring different error handling actions. The pairs (reason code, sub-reason code) are applied in the Sa-DISCONNECT.indication and Sa-REPORT.indication to indicate the type of the error to the user of the service.

6.3.3.5.2 An error handling action implies the sending of T-DISCONNECT.request (+DI SaPDU), if requested according to state table.

6.3.3.5.3 When error information is transmitted to the application by Sa-DISCONNECT.indication, it is the responsibility of the application for further action.

6.3.3.5.4 The error indication provided by T-DISCONNECT.indication shall be handled by the safety layer:

   - When reason = Network error is received, this error is forwarded to the application.

   - The reason = Called TS user not available should not be received from the Communication Layer, as the ATP is supposed to be supported by the peer entity. However, if this reason is received by the safety layer, the application will be informed.

**Table 23 Normal release**

|**Reason**<br>**Code**|**Sub-**<br>**reason**<br>**Code**|**Description**|**Error handling action**|
|---|---|---|---|
|0||Normal release requested by peer SFM<br>user|Sa-DISCONNECT.indication|

##### **Table 24 Sub-reasons for the reason 'No transport service available'**

<!-- end of page 46 -->

|**Reason**<br>**Code**|**Sub-**<br>**reason**<br>**Code**|**Description**|**Error handling action**|
|---|---|---|---|
|1|1|Network error|Sa-DISCONNECT.indication<br>The application should try to establish<br>again the connection|
|1|2|Network resource not available|Sa-DISCONNECT.indication<br>The application should try to establish<br>again the connection|
|1|3|Service or option is temporarily not<br>available|Sa-DISCONNECT.indication<br>The application should try to establish<br>again the connection with a modified<br>parameter.|
|1|5|Reason unknown|Sa-DISCONNECT.indication|
|1|6|Called TS user  not available|Sa-DISCONNECT.indication<br>The application should try to establish<br>again the connection with short dialling<br>code|
|1|8|No Mobile Termination has been registered|Sa-DISCONNECT.indication<br>The application should re-try  network<br>registration|

Note: 1.The sub-reason is equivalent to the reason of T-DISCONNECT.indication.

2. Sub-reasons are a matter of implementation. The error codes are not transmitted via the air interface

##### **Table 25 Sub-reasons for the reason 'Missing parameter or invalid parameter value'**

|**Reason**<br>**Code**|**Sub-**<br>**reason**<br>**Code**|**Description**|**Error handling action**|
|---|---|---|---|
|3|2|Missing authentication key|Sa-DISCONNECT.indication.|
|3|3|Other problem related to the key<br>management (e.g. loss of session key).|Sa-DISCONNECT.indication. The SFM user<br>can set-up a new connection.|
|3|4|Authentication key not currently valid|Sa-DISCONNECT.indication.|
|3|29|Requested safety feature is not supported|Sa-DISCONNECT.indication|

##### **Table 26 Sub-reasons for the reason 'Invalid MAC'**

|**Reason**<br>**Code**|**Sub-**<br>**reason**<br>**Code**|**Description**|**Error handling action**|
|---|---|---|---|
|4|1|MAC error|Sa-REPORT.indication|
|4|2|MAC error in AU2 SaPDU.|Sa-DISCONNECT.indication.|
|4|3|MAC error in AU3 SaPDU|T-DISCONNECT.request.|
|4|4|MAC error in AR SaPDU|Sa-DISCONNECT.indication|

##### **Table 27 Sub-reasons for the error type 'failure in sequence integrity'**

<!-- end of page 47 -->

|**Reason**<br>**Code**|**Sub-**<br>**reason**<br>**Code**|**Description**|**Error handling action**|
|---|---|---|---|
|5|1|Replay of  authentication message (AU1<br>SaPDU, AU2 SaPDU, AU3 SaPDU, AR<br>SaPDU) after connection establishment.<br>Error code is used, if the error is not<br>covered by reason code 9.|Sa-DISCONNECT.indication|

#### 6.3.3.5.5 Error type: Failure in the direction flag

6.3.3.5.6 This check is performed after the check of the MAC (not in the case of AU1 or DI SaPDU). If there is a transmission error that affects the flag, the MAC will detect this, and the reaction will be as in Table 25. If the MAC is correct, but the flag is not correct, there will be a SA-DISCONNECT.indication.

**Table 28 Sub-reasons for the reason 'Failure in the direction flag'**

|**Reason**<br>**Code**|**Sub-**<br>**reason**<br>**Code**|**Description**|**Error handling action**|
|---|---|---|---|
|6|1|Value of direction flag '0' instead of '1'|Sa-DISCONNECT.indication<br>The application is supposed to request a<br>new connection establishment.|
|6|2|Value of direction flag '1' instead of '0'|Sa-DISCONNECT.indication (after previous<br>Sa-CONNECT.indication)|
||||The application is supposed to request a<br>new connection establishment.|

##### **Table 29 Sub-reasons for the reason ‘Time out at connection establishment’**

|**Reason**<br>**Code**|**Sub-**<br>**reason**<br>**Code**|**Description**|**Error handling action**|
|---|---|---|---|
|7|3|Time out of  Testabwithout receiving the AR<br>SaPDU|Sa-DISCONNECT.indication<br>The application is supposed to request a<br>new connection establishment.|

**Table 30 Sub-reasons for the reason 'Invalid SaPDU field'**

|**Reason**<br>**Code**|**Sub-**<br>**reason**<br>**Code**|**Description**|**Error handling action**|
|---|---|---|---|
|8|1|Invalid information field|Rejection of SaPDU|
|8|4|Invalid responding ETCS Id in AU2, i.e.<br>ETCS-Identity does not correspond to an<br>acceptable ETCS ID.<sup>4</sup>|Sa-DISCONNECT.indication|
|8|5|Invalid AU1 SaPDU : the header indicates a<br>AU1SaPDU, but therest ofthe SaPDU|Rejection of SaPDU|

4 If there is a call establishment request to an unknown RBC any one of the possible RBCs can be an expected one.

<!-- end of page 48 -->

|**Reason**|**Sub-**|**Description**|**Error handling action**|
|---|---|---|---|
|**Code**|**reason**<br>**Code**|||
|||does not match with the structure of an AU1<br>SaPDU.||

##### **Table 31 Sub-reasons for the reason 'Failure in sequence of the SaPDUs during connection set-up'**

|**Reason**<br>**Code**|**Sub-**<br>**reason**<br>**Code**|**Description**|**Error handling action**|
|---|---|---|---|
|9|1|Transmission of AU1 SaPDU but a<br>message different from AU2 SaPDU is<br>obtained.|Sa-DISCONNECT.indication|
|9|2|Transmission of AU2 SaPDU but a<br>message different from AU3 SaPDU is<br>obtained.|T-DISCONNECT.request|
|9|3|Transmission of AU3 SaPDU but a<br>message different from AR SAPDU is<br>obtained.|Sa-DISCONNECT.indication|

**Table 32 Sub-reasons for the reason ' SaPDU length error '**

|**Reason**<br>**Code**|**Sub-**<br>**reason**<br>**Code**|**Description**|**Error handling action**|
|---|---|---|---|
|10|1|AU1 SaPDU  length error|Rejection of AU1 SaPDU|
|10|2|AU2 SaPDU  length error|Sa-DISCONNECT.indication|
|10|3|AU3 SaPDU  length error|T-DISCONNECT.request|
|10|5|DT SaPDU  length error|Sa-DISCONNECT.indication|
|10|8|AR SaPDU  length error|Sa-DISCONNECT.indication|

6.3.3.5.7 The code 127 (unknown) has to be used, when:

   - no proper reason code or sub-reason code can be selected;

   - the reason code or sub-reason code is undefined.

6.3.3.5.8 The reason codes 12-126 are reserved for future use. The reason codes 128-255 are reserved for national use / implementation-specific use. For these reason codes the subreason codes (0...126, 128...255) are also reserved for national use / implementationspecific use.

<!-- end of page 49 -->
