# **9. STM MANAGER SYSTEM – REQUIREMENTS ON STM**

## **9.1 Scope**

9.1.1.1 The scope of this chapter is to define how the STM handles its state.

## **9.2 STM States transitions table**

#### 9.2.1.1 Transitions table for STM

|**NP**|< 15|< 15|< 15|< 15|< 15|< 15|< 15|
|---|---|---|---|---|---|---|---|
|1 >|**PO**|||||||
||2 >|**CO**||||||
|||3 >|**DE**|||||
|||4a >|4a >|**CS**|< 4a|< 4a<br>< 4b||
|||||6 >|**HS**|||
|||||9 >|9 >|**DA**||
||16 >|16 >|16 >|16 >|16 >|16 >|**FA**|
||17 >|17 >|17 >|17 >|17 >|17 >||

9.2.1.2 Transitions conditions table

9.2.1.2.1 Note: This table only contains the event(s) that triggers the transition. It does not describe the reasons why this(these) event(s) happens. ETCS orders referred to below are described in chapter 10.3.2.

#### **Condition Content of the conditions Id**

|1|STM is powered on|
|---|---|
|2|ETCS order “Configuration”|
|3|ETCS order “Data Entry”|
|4a|ETCS unconditional order “Cold Standby”|
|4b|(ETCS conditional order “Cold Standby” has been received) AND (STM does not or<br>no more report National Trip Procedure)|
|5|_intentionally deleted_|
|6|ETCS order “Hot Standby”|
|7|_intentionally deleted_|
|8|_intentionally deleted_|
|9|ETCS order “Data Available”|

<!-- end of page 49 -->

|**Condition**<br>**Id**|**Content of the conditions**|
|---|---|
|10|_intentionally deleted_|
|11|_intentionally deleted_|
|12|_intentionally deleted_|
|13|_intentionally deleted_|
|14|_intentionally deleted_|
|15|STM is powered off|
|16|ETCS order “Failure”|
|17|The STM decides itself to go in FA state|

9.2.1.3 Note: As long as an STM in DA state is in a National Trip Procedure in SN mode, the STM sends cyclically the “National Trip Procedure” information to the STM Control Function in order to fulfil the timeout requirements defined in 10.3.2.4 (transitions E16 and F16). If the mode changes to TR, the STM is expected to enter CS state even if its National Trip Procedure is not finished, as the Trip procedure is handed over by ERTMS/ETCS on-board (otherwise, the STM would be ordered to FA state through transition Q16 once the TR mode is exited).

## **9.3 General STM requirements**

9.3.1.1 The STM antenna shall not energise trackside equipment, and shall not read trackside data, and shall not transmit data to trackside, except:

   - a) in HS or DA state,

   - b) for test purpose.

9.3.1.2 If the STM receives from the ERTMS/ETCS on-board a state transition order, which is not allowed by the state transition table (9.2.1.2), then the STM shall go in FA state.

9.3.1.3 The STM shall report its NID_STM on all point-to-point connections with the ERTMS/ETCS on-board:

   - a) intentionally deleted

   - b) with each transmitted application message from the STM to the ERTMS/ETCS onboard function or DMI channel.

9.3.1.4 The STM shall report its current state on all point-to-point connections with the ERTMS/ETCS on-board:

   - a) intentionally deleted

   - b) with each transmitted application message from the STM to the ERTMS/ETCS onboard function or DMI channel, and

   - c) whenever the STM state is changed, while the connection to the respective ERTMS/ETCS on-board function or DMI channel is established.

<!-- end of page 50 -->

9.3.1.4.1 Exception: The FA state shall be reported if possible. Due to a failure of the STM itself it may not be possible to report the FA state.

<!-- end of page 51 -->
