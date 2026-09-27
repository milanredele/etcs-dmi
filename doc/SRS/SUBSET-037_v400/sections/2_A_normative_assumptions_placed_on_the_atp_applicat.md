# **ANNEX A. (NORMATIVE) ASSUMPTIONS PLACED ON THE ATP APPLICATION**

This section defines the conditions and constraints, which shall be covered by the ATP application when using the services provided by SFM.

- a) Safety protection against occurrence of message delay, wrongly sequenced messages, message deletion and message replay shall be provided by the application, if required.

- b) Safe connection monitoring should be provided, if required.

- c) Service primitives have to be issued according to the sequence defined.

- d) In the case of RBC area change or entrance into RBC area, the connection establishment request has to be requested as soon as possible. Normally, safe connection establishment delay is less than the value Testab = 40s.

- e) In the case of registration with a mobile network (roaming into another GSM-R/GPRS), an additional delay has to be taken into account (refer to [Subset-093]).

- f) The maximum length of an application message to be transferred is restricted to 1023 octets.

- g) The transfer of application data has to be finished for both directions before a connection release is requested.

- h) In the case of network caused release of the safe connection or rejected connection establishment request, the application has to request the re-establishment of the safe connection. The on-board ATP shall initiate the safe connection re-establishment. Due to possible loss of user data a resynchronisation of the application data can be required.

- i) If required, the application has to pad the user data to octet boundaries.

- j) The application should check if the called ETCS ID of Sa-CONNECT.indication primitive is the same as its own ETCS ID (see fig.9).

- k) The OBU application has to provide the Mobile Network ID for a safe connection request.

<!-- end of page 50 -->
