# **ANNEX F. (INFORMATIVE) HOW TO CREATE THE LIST OF PERMITTED NETWORKS – EXAMPLE**

## **F.1. READ ALLOWED NETWORKS AND THEIR ALPHANUMERIC NAME FROM THE SIM CARD**

- **Procedure:** 1.) Determine the number of records in EFGsmr and then read all populated records from that EF.

   - 2.) For each record read from EFGsmr, read the corresponding record from EFIC.

   - 3.) For each record read from EFIC, read the corresponding record from EFNW.

   - 4.) From the information read, create an ordered list in the EuroRadio comprising MCC/MNC and alphanumeric network name for all networks read from EFGsmr.

F.1.1.1 Note: Before reading the records, it is necessary to work out how many records there are in the file since the SIM FFFIS only specifies a maximum of 50 records. This can be done by reading the EF status, which returns the overall length and the record size.

F.1.1.2 Table 24 shows an example of how to read the content of EFGsmr.

**Table 24: Read content of EFGsmr**

|`Command andResponse`|`Comment`|
|---|---|
|`AT+CRSM=192,28661,0,0,15`|`Read 15 octets to get status of`<br>`EF 28661=0x6FF5=GSMR`|
|`+CRSM:`<br>`144,0,"0000013B6FF504001A00AA0102010`<br>`9"`<br>`OK`|`Returned file length=0x13B=315 octets`<br>`length of records=9 thus 35 records`|
|`AT+CRSM=178,28661,1,4,9`|`Read record 1 from EFGSMR (home`<br>`network)`|
|`+CRSM: 144,0,"22F203F86F8D6F8E01"`<br>`OK`|`MCC-MNC=222-30`<br>`index into EFIC= 01`|
|`AT+CRSM=178,28661,2,4,9 `|`Read record 2 from EFGSMR`|
|`+CRSM: 144,0,"22F860F96F8D6F8E02"`<br>`OK`|`MCC-MNC=228-06`<br>`index into EFIC = 02`|
|`…`|_`Further records not shown`_|

F.1.1.3 Table 25 shows example of how to read records from EFIC

**Table 25: Read content of EFIC**

|`Command andResponse`|`Comment`|
|---|---|
|`AT+CRSM=178,28557,1,4,7 `|`Read record 1 from EFIC`|
|`+CRSM: 144,0,"F06F8E30F90001"`<br>`OK`|`Index into EFNW= 0x0001 = 1`|
|`AT+CRSM=178,28557,2,4,7 `|`Read record 2`|
|`+CRSM: 144,0,"F06F8E40F10002"`<br>`OK`|`Index into EFNW = 0x0002 = 2`|

<!-- end of page 80 -->

```
Command and ResponseComment
Further records not shown
```

#### F.1.1.4 Table 26 shows example of how to read contents from EFNW

**Table 26: Read content of EFNW**

|`Command andResponse`|`Comment`|
|---|---|
|`AT+CRSM=178,28544,1,4,8 `|`Read record 1 from EFNW`|
|`+CRSM: 144,0,"47534D5220524649"`<br>`OK`|`Network name = "GSM-R I"`|
|`AT+CRSM=178,28544,2,4,8 `|`Read record 2`|
|`+CRSM: 144,0,"47534D52204348FF"`<br>`OK`|`Network name = "GSM-R CH"`|
|`…`|_`Further records not shown`_|

Assuming the information read from the SIM in the previous three sections a list of alphanumeric network names, e.g. "GSM-R I", see [N-9018].

<!-- end of page 81 -->

## **F.2. BUILD LIST OF PERMITTED NETWORKS**

**Procedure :** _0.) Prerequisite: procedure of §_ F.1 _shall have been performed_

- 1.) When demanded by the driver (through T-PERMISSION.request), obtain the list of currently available networks from the MT.

2.) Exclude from this list any networks that are marked as “Forbidden”.

- 3.) Exclude from this list any network whose MCC/MNC does not appear in the list prepared in § F.1 above.

- 4.) Use the filtered set of MCC/MNC values created in previous steps to select the alphanumeric network names from the list created in § F.1 above and create the list of valid ETCS networks.

5.) Display this list to the driver, with the home network first, if that is currently available.

F.2.1.1 Request available network from the MT

**Table 27: Request available network from the MT**

|`Command andResponse`|`Comment`|
|---|---|
|`AT+COPS=?`|`Request available networks`|
|`+COPS: (2,,"GSM-R I","22230")`<br>`(1,,"MobiSir","24021")`<br>`(1,,,"28621")`<br>`(1,,"GSM-R CH","22806")`<br>`(1,,"TIM","22201")`<br>`(3,,"Vodafone","22210")`<br>`,,(0,1,3,4),(0,1,2)`<br>`OK`|`Network 222-30 is current network`<br>`Network 240-21 is available`<br>`Network 286-21 is available`<br>`Network 228-06 is available`<br>`Network 222-01 is available`<br>`Network 222-10 is forbidden`|

F.2.1.2 Filter list according to network suitability

Network 222-10 is forbidden and so is excluded. Network 286-21 is not on the SIM and is therefore excluded. This leaves the following list of networks:

222-30 240-21 228-06 222-01

#### F.2.1.3 Create Final List for Driver

The list created above is then merged with the list of accurate names to create the following list to display to the driver:

GSM-R I GSM-R S GSM-R CH TIM

<!-- end of page 82 -->

Note: It is important to note that in the above list two of the networks have different names from those that were returned in the original response to the +COPS command. The name displayed is that on the SIM rather than in the MT firmware. The home network is “GSM-R I”: this is available and therefore displayed first in the list.

<!-- end of page 83 -->
