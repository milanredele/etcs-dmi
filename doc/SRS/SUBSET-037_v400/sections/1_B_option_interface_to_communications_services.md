# **ANNEX B. (OPTION) INTERFACE TO COMMUNICATIONS SERVICES**

B.1.1.1 Communication services are accessed by means of service primitives similar to the service primitives defined in [ITU-T X.214] for connection mode service.

B.1.1.2 Note: It is a matter of implementation to adapt this interface to implementation needs and constraints, where there is no exchange on the air gap and where there is no impact on the behaviour of the system.

B.1.1.3 The internal interface between the modules SFM and CFM is not mandatory.

B.1.1.4 The interface to communication services can be provided for non-safe applications.

## **B.2. SERVICE PRIMITIVES FOR CONNECTION ESTABLISHMENT**

B.2.1.1 The following table gives the service primitives used for connection establishment and their corresponding parameters.

##### **Table 19 Service primitives of the communication layer for connection set-up**

|**Primitive Parameters**|**T-CONNECT**<br>**request**|**T-CONNECT**<br>**indication**|**T-CONNECT**<br>**response**|**T-CONNECT**<br>**confirm**|
|---|---|---|---|---|
|TCEPID||X|X(=)|X|
|Connection RequestType (CET)|X(D)|X(D)|||
|Called address:<br>Address type<br>Network address<br>Mobile Network ID<br>Called ETCS ID type<br>CalledETCSID|X<br>X(D)<br>X(U)<br>X<br>X|X<br>X||X|
|Calling address:<br>Calling ETCS ID type<br>CallingETCSID|X<br>X|X(=)<br>X(=)|||
|Responding address:<br>Responding ETCS ID type<br>RespondingETCSID|||X<br>X|X(=)<br>X(=)|
|Application type|X|X(=)|||
|QoS class|X(D)||||
|User data|X(U)|X(=)|X(U)|X(=)|

X    Mandatory parameter.

(=) The value of that parameter is identical to the value of the corresponding parameter of the preceding transport primitive.

X(U)  Use of this parameter is a CFM user option.

X(D) Use of this parameter is an user option. If not provided, a default value will be used by CFM internally

B.2.1.2 The parameter **TCEPID** (Transport Connection End Point Identifier) is provided locally to distinguish between different transport connections.

B.2.1.3 The **Address type** qualifies the usage of sub-parameters of called address.

<!-- end of page 65 -->

B.2.1.4 The **Mobile Network ID** identifies the mobile network. The Mobile Network ID shall consist of the Mobile Country Code and the Mobile Network Code according to [ITU-T E.212].

B.2.1.5 In the case of mobile originated calls, the connection request shall contain the subparameter Mobile Network ID, to request the appropriate network associated with the called user.

B.2.1.6 The **Network Address** , if provided, identifies the network address of the called CFM user. This parameter is composed of sub-fields, e.g. the length of the called number, the type of number, the numbering plan, and the number itself.

B.2.1.7 The parameter ETCS ID type together with ETCS ID is unique and are used by the transport layer during connection establishment. The ETCS ID type and ETCS ID together with the application type identifies the service user.”

B.2.1.8 Within the scope of ETCS and refers to ETCS equipment. The ETCS IDs are used by the transport layer during connection establishment. The ETCS ID type and ETCS ID together with the application type identifies the service user. ETCS ID.

B.2.1.9 The **Calling ETCS ID** identifies, together with the application type, the transport connection initiator. The **Called ETCS ID** identifies together with the application type the called CFM user. The **Responding ETCS ID** identifies the accepting/responding CFM user, which was locally selected by the responding transport entity.

B.2.1.10 **Application type** : The application type is identical at the calling and called side (see section 6.3.4.6).

B.2.1.11 The **QoS class** is associated with a set of quality of service parameter values. The QoS parameters will not be negotiated. The requested QoS parameter values have to be accepted by the service provider and the peer application. Otherwise the connection establishment has to be rejected.

B.2.1.12 The user data length is restricted to 32 octets.

B.2.1.13 The following figure shows the sequence of transport service primitives at TSAP for connection establishment:

<!-- Start of picture text -->
CFM CFM<br>T-CONNECT.req<br>T-CONNECT.ind<br>T-CONNECT.resp<br>T-CONNECT.conf<br><!-- End of picture text -->

**Figure 17 Sequence of primitives for connection set up**

<!-- end of page 66 -->

## **B.3. SERVICE PRIMITIVES FOR DATA TRANSFER**

B.3.1.1 The following table gives the service primitives of the communication layer used for data transfer:

**Table 20 Service primitives of the communication layer for data transfer**

|**Primitive Parameters**|**T-DATA.request**|**T-DATA.indication**|
|---|---|---|
|TCEPID|X|X|
|User data|X|X(=)|

B.3.1.2 A request for data transfer is made by a service user (after a successful transport connection set up) through the use of the T-DATA.request service primitive, with user data as a parameter. These data are delivered to the intended user through the use of the primitive T-DATA.indication with user data as a parameter.

B.3.1.3 User data are transparent to the CFM. The recommended length is <= 123 octets. If more than 123 octets are requested, the CFM segments/reassembles the user data.

## **B.4. SERVICE PRIMITIVES FOR CONNECTION RELEASE**

B.4.1.1 The transport connection release is provided by the communication layer through the service primitive T-DISCONNECT.request. The connection release is indicated to the user using the service primitive T-DISCONNECT.indication. The connection release is indicated to the communication layer user as a consequence of a disconnection request issued by the user (normal release), as a consequence of connection establishment rejection or because of a network failure.

B.4.1.2 The following table gives the service primitives used for connection release.

<!-- end of page 67 -->

**Table 21 Service primitives of the communication layer for connection release**

|**Primitive Parameters**|**T-DISCONNECT.request**|**T-DISCONNECT.indication**|
|---|---|---|
|TCEPID|X|X|
|Reason||X(U)<sup>1</sup>|
|User data|X(U)|X(=)|
|Note:|||

1. It has to be used in the error case.

B.4.1.3 If the disconnect is caused by a deregistration of the mobile, T-DISCONNECT.indication shall be sent before T-REGISTRATION.indication to the service user.

B.4.1.4 Optionally, user data can be included (maximum 64 octets).

B.4.1.5 The following figure shows the sequence of transport service primitives at TSAP for connection release.

<!-- Start of picture text -->
CFM CFM<br>T-DISC.req<br>T-DISC.ind<br><!-- End of picture text -->

**Figure 18 Sequence of primitives for connection release initiated by a CFM user**

## **B.5. SERVICE PRIMITIVES FOR NETWORK REGISTRATION**

B.5.1.1 Two service primitives are provided for mobile network registration of Mobile Terminations (MT) and FRMCS (see Table 22):

   - to request mobile network registration (GSM-R only) and

   - to indicate mobile network registration status

B.5.1.2 These service primitives apply to on-boards only.

**Table 22 Service primitives for mobile network registration**

||**Primitive**|**T-REGISTRATION.request**|**T-REGISTRATION.indication**|
|---|---|---|---|
|**Parameter**||||
|MNID list||X (>= 0 MNIDs)|X (>= 0 MNIDs)|

B.5.1.3 By means of the service primitive “T-REGISTRATION.request” the service user is able to request the registration of one or more Mobile Terminations with one or more mobile networks. Registration to FRMCS shall be ignored because it is performed internally by the CFM FRMCS.

<!-- end of page 68 -->

B.5.1.4 A **Mobile Network ID** identifies the mobile network a local Mobile Termination is requested to register with. The Mobile Network ID shall consist of the Mobile Country Code and the Mobile Network Code according to [ITU-T E.212].

B.5.1.5 The interpretation of the MNID list is matter of implementation. An example can be:

   - Empty:

All available Mobile Terminations are requested to be registered using automatic mobile network registration from GSM-R on-board radio equipment (see 3GPP 22.011).

One entry:

All available Mobile Terminations are requested to be registered on the mobile network defined by the entry using manual mobile network registration from the GSMR on-board radio equipment.

Two different entries (MNID#1, MNID#2):

The available Mobile Terminations have to be split in two parts and to register first part on the mobile network defined by MNID #1 and second part on the mobile network defined by MNID #2.

In case not enough Mobile Terminations are available to perform registration on both mobile networks, registration shall be provided according to MNID priority ranking.

B.5.1.6 The status of registration with mobile networks is indicated by the service primitive “TREGISTRATION.indication” to the service user. The service primitive contains a list of Mobile Network IDs, which are usable because Mobile Termination(s) are registered with them.

B.5.1.7 Note: the association between MT and MNID in these service primitives is an implementation matter.

B.5.1.8 For the GSM-R mobiles the following scheme shall be used for the list of Mobile Network IDs:

   - Only one Mobile Termination is registered to network A: 1xMNID-A

   - wo or more Mobile Terminations are registered to network A: 2xMNID-A

   - Mobile Terminations are registered to two networks A and B: 1xMNID-A, 1xMNID-B.

B.5.1.9 FRMCS Registration shall be stated using MNID “901 999” and name “FRMCS”.

B.5.1.10 If the indicated list of Mobile Network IDs is empty, the registration of Mobile Terminations was not possible, or the coverage has been lost.

B.5.1.11 The mobile network registration indication can be given independently of a request. In case of a network registration status change (GSM-R or FRMCS) the user shall be informed via registration indication message.

B.5.1.12 After a successful mobile network registration, GPRS attach shall be initiated on all MTs, but the PDP context activation at least on one MT, see ANNEX G of Subset-037-1.

B.5.1.13 If GPRS attach or PDP context activation is not successful, the correct network registration has to be reported by T-REGISTRATION.indication.

      - © _This document has been developed and released by UNISIG_

<!-- end of page 69 -->

## **B.6. SERVICE PRIMITIVES FOR PERMITTED NETWORKS**

B.6.1.1 Two service primitives are provided for indication of allowed mobile networks (see Table 23):

   - to request a list of permitted mobile networks and

   - to indicate this permitted list.

B.6.1.2 These services are limited to GSM-R networks only.

B.6.1.3 These service primitives apply to on-boards only.

##### **Table 23 Service primitives for permitted mobile networks**

||**Primitive**|**T-PERMISSION.request**|**T-PERMISSION.indication**|
|---|---|---|---|
|**Parameter**||||
|MNID list||X (= 0 MNIDs)|X ( >= 0 MNIDs)|

B.6.1.4 By means of the service primitive “T-PERMISSION.request” the service user is able to request the indication of permitted mobile networks. **MNID list** parameter is empty for the request primitive.

B.6.1.5 The permitted mobile networks are indicated by the service primitive “TPERMISSION.indication” to the service user. The service primitive shall contain a list of MNIDs provided with their respective alphanumeric network names.

B.6.1.6 A **Mobile Network ID** shall consist of the Mobile Country Code and the Mobile Network Code according to [ITU-T E.212].

B.6.1.7 An unsolicited mobile network permission indication shall not be used.

B.6.1.8 If the indicated list of Mobile Network IDs is empty, no permitted mobile network is found.

B.6.1.9 The list of allowed mobile networks shall be formed by information read from the SIM card (see [EuroRadio FFFIS]).

B.6.1.10 The needed information is stored in three elementary files on the SIM: EFGsmr, EFIC and EFNW:

   - EFGsmr contain the MNIDs.

   - EFNW contain the alphanumeric network names.

   - EFIC contain an index that connects the records in EFGsmr and EFNW.

   - For details, see [SIM FFFIS].

B.6.1.11 The list of available mobile networks shall be found through a scan of the available and allowed networks (see [EuroRadio FFFIS]). A mobile network shall be considered as available if reported as such by at least one MT.

B.6.1.12 Mobile networks marked as ‘forbidden’ in the response are excluded from the list of available mobile networks.

B.6.1.13 The list of permitted mobile networks shall be composed only of the mobile networks which are part of both the list of available mobile networks and the list of allowed mobile networks.

<!-- end of page 70 -->

B.6.1.14 See ANNEX F for an informative example of how to create the list of permitted mobile networks.

<!-- end of page 71 -->
