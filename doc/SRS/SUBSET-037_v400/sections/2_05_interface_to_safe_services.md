# **5 INTERFACE TO SAFE SERVICES**

## **5.1 General**

5.1.1.1 The safe services provided by the SFM are accessed by means of safe service primitives with their corresponding parameters at the SaSAP. The safe service primitives are similar to the service primitives defined in [ITU-T X.214] for connection mode service.

5.1.1.2 The interface is mandatory at functional level only.

5.1.1.3 Note: It is a matter of implementation to adapt this interface to implementation needs and constraints, which do not require any exchange on the air gap and have no impact on the behaviour of the system.

5.1.1.4 Two different types of service primitives are specified:

   - a)      service primitives for safe services

   - b)      service primitives for interworking with the mobile network (out of scope of this FIS)

5.1.1.5 The service primitives for safe services allow the set-up, disconnection of the connection and the safe data transfer.

5.1.1.6 The service primitives for interworking with the mobile network apply to the on-boards only. The service primitives are not safety relevant and have no impact on the safety protocol. They allow the registration to the network and to check the permitted mobile networks for ETCS. These service primitives are applicable if no safe connection exists. These service primitives are described in [Subset-037-1].

## **5.2 Service primitives for safe connection set-up**

5.2.1.1 The safe connection set-up service is based on the use of the following primitives:

**Table 1 Service primitives of the safety layer for connection set-up**

|**SaS-Primitive**<br>**Parameter**|**Sa-CONNECT.**<br>**request**|**Sa-CONNECT.**<br>**indication**|**Sa-CONNECT.**<br>**response**|**Sa-CONNECT.**<br>**confirm**|
|---|---|---|---|---|
|SaCEPID||X|X(=)|X|
|Connection Request Type (CET)|X(D)|X(D)|||
|Called address<br>•<br>Address type<br>•<br>Network address<br>•<br>Mobile Network ID<br>•<br>Called ETCSID type<br>•<br>Called ETCS ID|X<br>X(D)<br>X(U)<br>X<br>X|X<br>X||X|
|Calling address<br>•<br>Calling ETCS ID type<br>•<br>CallingETCSID|X(D)<br>X(D)|X(=)<br>X(=)|||
|Responding address|||||
|•<br>Responding ETCS ID type<br>•<br>RespondingETCSID|||X(D)<br>X(D)|X(=)<br>X(=)|
|Application type|X|X(=)|||
|Quality of service class|X(D)||||

<!-- end of page 14 -->

X: mandatory parameter.

(=):  the value of that parameter is identical to the value of the corresponding parameter of the preceding SaS primitive, if any.

X(U) Use of this parameter is an user option

X(D) Use of this parameter is an user option. If not provided, a default value will be used.

5.2.1.2 **SaCEPID:** The local parameter "Safe connection endpoint identifier (SaCEPID)" is provided locally to identify each safe connection at a SaSAP.

5.2.1.3 The **Called address** identifies the called SFM user.

5.2.1.4 The **Address type** qualifies the usage of sub-parameters of called address (refer to [Subset-037-1] Call and ID-Management section for details).

5.2.1.5 The **Network address** contains the network address of the called SaS user. This parameter is composed of sub-fields, e.g. the length of the called number, the type of number, the numbering plan, and the number itself.

5.2.1.6 The **Mobile Network ID** identifies the mobile network. The Mobile Network ID shall consist of the Mobile Country Code and the Mobile Network Code according to [ITU-T E.212].

5.2.1.7 In the case of mobile originated calls, the connection request shall contain the subparameter Mobile Network ID, to request the appropriate network associated with the called SaS-user.

5.2.1.8 The parameter **ETCS ID type** together with **ETCS ID** is unique within the scope of ETCS and refers to ETCS equipment. The ETCS IDs are used by the safety layer during peer entity authentication. The ETCS-ID type and ETCS ID together with the application type identifies the safety service user.

5.2.1.9 **Called ETCS ID:** The Called ETCS ID parameter conveys the ETCS ID associated with the SaS-user to which the safe connection is to be established.

5.2.1.10 **Calling ETCS ID:** The Calling ETCS ID parameter conveys the ETCS ID of the requesting SaS-user from which the safe connection has been requested.

5.2.1.11 **Responding ETCS ID:** The Responding ETCS ID parameter conveys the ETCS ID of the SaS-user to which the safe connection has been established.

5.2.1.12 **Application type:** The application type is identical at the calling and called side (see section [Subset-037-1] Addressing section).

5.2.1.13 **Quality of Service class:** The QoS parameters give SFM users a method of specifying their needs, and give the CFM a basis for selection of the protocol or for requesting services of lower layers. The QoS class is associated with a set of quality of service parameter values (see [Subset-037-1] QoS parameters section). The service parameter value’s applicability can be subject to the transmission mode (CS or PS) for the specific connection. For applicable parameters, the QoS parameters will not be negotiated. The requested and applicable QoS parameter values have to be accepted by the service provider and the peer application, otherwise the connection establishment has to be rejected.

<!-- end of page 15 -->

<!-- Start of picture text -->
Safety Layer Safety Layer<br>Sa_CONN.request<br>Sa_CONN.ind<br>Execution of the safety procedure<br>Peer entity authentication<br>Sa_CONN.resp<br>Sa_CONN.confirm<br>Logical data  flow (SaPDU)<br>Physical data  flow (service primitives)<br><!-- End of picture text -->

**Figure 2 Sequence of primitives for safe connection set-up**

5.2.1.14 **Sa-CONNECT.request** initiates the establishment of a safe connection. The safety protocol enforces a connection set-up of the underlying transmission system by using T- CONNECT.request.

5.2.1.15 **Sa-CONNECT.indication** is used by the called safety layer entity to inform the called SaS user about the safe connection establishment request.

5.2.1.16 **Sa-CONNECT.response** is used by the responding SaS user to accept the connection to the safety layer entity.

5.2.1.17 **Sa-CONNECT.confirm** is used by the initiating safety layer entity to inform the calling SaS user about the successful establishment of the safe connection after a response of the called SaS user was obtained.

5.2.1.18 Simultaneous requests for safe connection set-up at two SaSAP’s are handled independently by the safety layer. These simultaneous requests result in a corresponding number of safe connections. It is the matter of the requesting SaS user to distinguish between confirmations of pending Sa-CONNECT.requests.

<!-- end of page 16 -->

## **5.3 Service primitives for safe data transfer**

5.3.1.1 For the data transmission two service primitives for the transmission and reception of messages are defined.

**Table 2 Service primitives of the safety layer for data transfer**

||**Primitive**|**Sa-DATA.request**|**Sa-DATA.indication**|
|---|---|---|---|
|**Parameter**||||
|SaCEPID||X|X|
|Sa user data||X<sup>1</sup>|X(=)|

Note1: The length has to be at least 1 octet.

5.3.1.2 Sa-DATA.request on transmission and Sa-DATA.indication on reception perform the safe transfer and the safety procedure ‘message origin authentication’. After the execution of the safety procedure ‘message origin authentication’ the transmitting safety entity forwards the data (user data expanded with a Message Authentication Code) to the transport layer.

5.3.1.3 The user data are transported transparently by the SFM. The recommended size of Sa user data is  114 octets. The maximum length of SaS user data to be transferred is restricted to 1023 octets.

5.3.1.4 On reception, after successful execution of the procedure ‘message origin authentication’, the user data are delivered to the SaS user using the service primitive Sa-DATA.indication. In the error case, a Sa-REPORT.indication or a Sa-DISCONNECT.indication is delivered.

###### Safety Layer

<!-- Start of picture text -->
Sa_DATA.request<br><!-- End of picture text -->

<!-- Start of picture text -->
Safety Layer<br><!-- End of picture text -->

<!-- Start of picture text -->
Sa_DATA.indication<br><!-- End of picture text -->

**Figure 3 Sequence of primitives for safe data transfer**

5.3.1.5 The operation of the safety layer in transferring SaS user data can be modelled as a queue. The ability of a SaS user to issue a Sa-DATA.request depends on the state of the queue. The ability of the safety layer to issue a Sa-DATA.indication depends on the receiving SaS user.

## **5.4 Service primitives for connection release**

5.4.1.1 Connection release, i.e. disconnect, is supported by the following two service primitives.

**Table 3 Service primitives of the safety layer for connection release**

|**Primitive**<br>**Sa-DISCONNECT.request**|**Sa-DISCONNECT.indication**|
|---|---|

**Parameter**

<!-- end of page 17 -->

|SaCEPID|X|X|
|---|---|---|
|Disconnect reason|X|X|
|Disconnect sub-reason|X(U)|X|

5.4.1.2 Sa-DISCONNECT.request is used by the SaS user to enforce a release of the safe connection.

5.4.1.3 Sa-DISCONNECT.indication is used to inform the SaS user about a connection release of the safe connection.

5.4.1.4 The reason and sub-reason codes are defined in section 6.3.3.5 ”Error handling”.

5.4.1.5 Normal release requested by a SaS user shall contain the reason code 0; the sub-reason code can be set by the SaS user according to its needs in the range 0...255.

<!-- Start of picture text -->
Safety Layer Safety Layer<br>Sa_DISC.request<br>Sa_DISC.indication<br><!-- End of picture text -->

**Figure 4 Sequence of primitives for connection release initiated by a SaS user**

5.4.1.6 The safety layer can issue an unsolicited Sa-DISCONNECT.indication at any time during the connection set-up phase or during the data transfer phase. The release of the connection can be caused by inability of the safety layer to provide a given service.

5.4.1.7 Other sequences of primitives for connection release are possible.

<!-- end of page 18 -->

## **5.5 Service primitives for error reporting**

5.5.1.1 Optionally, error reporting is supported by the service primitive Sa-REPORT.indication.

**Table 4 Service primitives for error reporting**

||**Primitive**|**Sa-REPORT.indication**|
|---|---|---|
|**Parameter**|||
|SaCEPID||X|
|Report type||X|
|Number of pairs||X|
|List of pairs||X|

5.5.1.2 The safety layer uses the service primitive Sa-REPORT.indication to inform the SaS user about errors that occur in the safety layer or in the lower layers. The Sa-REPORT.indication is triggered automatically (if the Sa-REPORT.indication is the specified error reaction). The service primitive can be used also for reporting information other than errors (e.g. diagnostics).

5.5.1.3 The parameter **report type** is used to distinguish between the different kinds of information reports. Currently, only report type =1 is defined for error reports.

5.5.1.4 A pair contains two parameters (reason, sub-reason). Refers to section 6.3.3.5 for details about error coding.

## **5.6 Service primitives for mobile network registration**

5.6.1.1 Two service primitives are provided for mobile network registration of Mobile Terminations (MT):

   - Sa-REGISTRATION.request: to request mobile network registration.

   - Sa-REGISTRATION.indication: to indicate mobile network registration status.

5.6.1.2 These service primitives do not provide safe services (i.e. they are not safety relevant and have no impact on the safety protocol).

5.6.1.3 The service primitives are forwarded to/from the Communication Functional Module (CFM) refers to [Subset-037-1] for more details.

5.6.1.4 By means of the service primitive “Sa-REGISTRATION.request” the service user is able to request the registration of one or more Mobile Terminations with one or more mobile networks.

5.6.1.5 The status of registration with mobile networks is indicated by the service primitive “SaREGISTRATION.indication” to the service user.

## **5.7 Service primitives for Permitted Mobile Networks**

5.7.1.1 It is necessary to indicate a list of 'Permitted' Mobile Networks to the driver. This list comprises mobile networks that are both 'available', i.e. the mobile detects their presence,

<!-- end of page 19 -->

and 'Allowed', i.e. a previously-stored list of mobile networks to which the mobile is allowed to register.

5.7.1.2 Two service primitives are provided for indication of allowed mobile networks:

   - Sa-PERMISSION.request: to request a list of permitted mobile networks.

   - Sa-PERMISSION.indication: to indicate this permitted list.

5.7.1.3 These service primitives do not provide safe services (i.e. they are not safety relevant and have no impact on the safety protocol).

5.7.1.4 The service primitives are command/response between the Communication Functional Module (CFM) and the mobile terminal (MT). Refers to the communication functional module in [Subset-037-1] for more details.

5.7.1.5 By means of the service primitive “Sa-PERMISSION.request” the service user is able to request the indication of permitted mobile networks.

5.7.1.6 The permitted mobile networks are indicated by the service primitive “SaPERMISSION.indication” to the service user.

<!-- end of page 20 -->
