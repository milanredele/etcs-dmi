# **ANNEX H. (INFORMATIVE) GSM-R CS – GSM-R PS - FRMCS MODE SELECTION SCHEME**

H.1.1.1 This annex contains the sequence of actions for GSM-R CS / GSM-R PS / FRMCS mode selection, including the simultaneous ETCS DNS queries management, associated to the ETCS ID type and a not unknown ETCS ID contained in the received T- CONNECT.request primitive (if the ETCS ID is unknown see Table 7). It shall be assumed that:

- the FRMCS transmission mode is the preferred choice (table empty or FRMCS explicitly written).

- Refer to [Subset-037-3] for the connection establishment of FRMCS transmission mode.

- the PS status OK box refers to the polling function in § 6.4.6.3.

- the “PPP connect setup?” box also include connect/re-activation/re-setup if necessary, before going to the ‘No’ branch.

<!-- end of page 86 -->

The following figure shows the sequence of actions described above.

<!-- Start of picture text -->
T-Connect  T-Connect  T-Connect  T-Connect<br>T-Disconnect<br>FRMCS check Request Request Request Indication ConfiRmation<br>( in parallel) GSM-R FRMCS&GSM-R FRMCS (CET)<br>Connection  Use of<br>establishment  yes FRMCS = no<br>(FRMCS mode) and FRMCS<br><control plane only> GSM-R = (PS or CS) and/or<br>no GSM-R<br>no Successful?<br>Timeout FRMCS_CED  FRMCS Connection  FRMCS Connection<br>[Subset-037-3] establishment  establishment<br>CET = FRMCS CET = FRMCS<br>FRMCS= YES  no no<br>Successful? Successful?<br>Disconnect yes yes<br>FRMCS= YES<br>End<br>yes yes Use of<br>GSM-R = CS? CS or PS<br>PS check no<br>(in parallel) PDP context = ETCS no<br>PPP connect Setup?<br>no<br>Second MT  yes<br>available?<br>"A" query and "TXT" query;<br>yes<br>repeat if no answer after<br>no PDP context = ETCS dns_lookup_reptime  for max.<br>PPP connect Setup? dns_lookup_timeout<br>yes No "A" field or<br>repeat if no answer after "A" query; "A" field? Timeout TXT field with "txm=cs"? no<br>dns_lookup_reptime  for max.  Answer from DNS yes<br>dns_lookup_timeout  with "A  field yes GSM-R = PS?<br>no<br>No "A" field or<br>Timeout GSM-R= PS  no<br>"A" field? Successful ?<br>yes<br>Answer from DNS No "tp" record<br> with "A  field TXT field with   or timeout GSM-R= CS<br>"tp" record?<br>GSM-R= PS  "tp" record present<br>PS Connection  PS Connection  CS Connection<br>establishment using  establishment using  establishment<br>DNS Parameters Standard Parameters<br>End CET = GSM-R CET = GSM-R CET = GSM-R<br>CET: Connection Establishment Type Establishment resultConnection  Transmission Mode TableRequests to  Transmission Mode TableAction in the<br><!-- End of picture text -->

##### **Figure 19 Sequence of actions for GSM-R CS / GSM-R PS / FRMCS selection, including simultaneous ETCS DNS queries management**

H.1.1.2 Intentionally deleted.

H.1.1.3 Intentionally deleted.

<!-- end of page 87 -->
