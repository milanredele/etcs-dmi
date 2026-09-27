# **8. STM STATES**

## **8.1 No Power (NP)**

8.1.1.1 The NP state means that the STM is unpowered.

## **8.2 Power On (PO)**

8.2.1.1 This state is the default state entered by the STM after the STM is switched on.

8.2.1.2 Once in PO state, the STM shall perform the synchronisation of the Safe Time Layer.

8.2.1.3 Once in PO state, the STM shall establish a connection with the ERTMS/ETCS onboard STM Control Function.

8.2.1.4 When the STM has established the connection to the STM Control Function, the STM shall send a “Specific NTC Data Need” information to the STM Control Function indicating whether it needs or not Specific NTC Data.

8.2.1.5 Once the ERTMS/ETCS on-board has sent the bus addresses and safety levels of all available ERTMS/ETCS on-board functions (see 10.1.1.4), it shall allow STM to establish connections with any of these functions.

8.2.1.6 Once the STM Control Function has sent the ETCS status data to an STM in PO state (see chapter 10.5.1.1), it shall allow this STM to request CO state.

## **8.3 Configuration (CO)**

8.3.1.1 The STM CO state is used to wait until all configuration data between STM and ERTMS/ETCS on-board have been exchanged. “Configuration data” means data that is necessary for the national operation, except Specific NTC Data.

8.3.1.2 Configuration data from ERTMS/ETCS on-board to STMs consists of:

   - a) ETCS data (see chapter 10.4)

   - b) Status / availability of the train interface FFFIS STM signals (TIU)

   - c) Status / availability of the brake interface FFFIS STM signals (BIU)

   - d) Odometer performance parameters (see chapter 12.4)

   - e) Brake performance parameters: Maximum time delay for the ERTMS/ETCS on-board to process the STM Emergency and the STM Service Brake commands. This is the time from receiving the brake command from the STM until the ETCS commands the brake.

8.3.1.2.1 Note: Configuration data has not necessarily to be sent in CO state. Some data could be sent in PO state.

8.3.1.2.2 Note: The brake performance parameter can be used by the STM in braking curves calculation.

<!-- end of page 46 -->

8.3.1.3 Once the transmission of configuration data is finished and the Specific NTC Data Entry procedure is started, if the STM does not require any Specific NTC Data, then the STM shall request Cold Standby state to the STM Control Function.

8.3.1.4 If an STM in Configuration State detects that the ERTMS/ETCS on-board is in the mode Non-Leading or Sleeping and has received all the configuration data except for the ETCS data, the STM shall request to go to Cold Standby state.

8.3.1.4.1 Justification: This allows STM operation in Non-Leading or Sleeping in which ETCS Train Data is not available.

8.3.1.5 Once the transmission of configuration data is finished and the Specific NTC Data Entry procedure is started, if the STM does require any Specific NTC Data, then the STM shall request Data Entry state to the STM Control Function.

8.3.1.6 When an STM exits CO state, it shall have the possibility to close any connection except with STM Control Function.

## **8.4 Data Entry (DE)**

8.4.1.1 The state DE is used by any STM that requires Specific NTC Data in order to have all the required national information for operating the train with the STM.

8.4.1.1.1 Note: This state is only entered once at the start up process of the STM.

8.4.1.2 In the state DE, the Specific NTC Data Entry procedure (see chapter 10.7) shall be performed.

8.4.1.3 Once the Specific NTC Data Entry procedure is terminated, the STM shall request Cold Standby state to the STM Control Function.

8.4.1.4 Note: The Specific NTC Data Entry procedure can be terminated without having received the Specific NTC Data (e.g. when the Specific NTC Data Entry procedure is skipped). However, the Cold Standby state is still requested in order to have the same system behaviour when the Specific NTC Data is invalid.

## **8.5 Cold Standby (CS)**

8.5.1.1 Being in the state CS, the STM has been initialised, tested (if required), configured and is in possession of all required information for operating, but is not able to receive a message from the trackside, because the reception is turned off.

8.5.1.1.1 Exception: Specific NTC Data could be invalid, see 10.7.3.3.

## **8.6 Hot Standby (HS)**

8.6.1.1 Being in the state HS, the STM shall be able to process the information from or to the national trackside.

<!-- end of page 47 -->

8.6.1.1.1 Note: In HS state, when receiving national trackside information, the STM treats this information to be prepared to take charge of the train movement supervision once it switches to Data Available state.

8.6.1.2 The STM in HS state shall have the possibility to send an “STM max speed” (V_STMMAX) to the ERTMS/ETCS on-board through the STM Control Function.

8.6.1.2.1 Note: This “STM max speed” is to allow the STM, for national reasons unknown to the ERTMS/ETCS on-board or ETCS Trackside, to request a given train speed at the level transition border in order to have a smooth transition.

8.6.1.3 The STM in HS shall have the possibility to send an “STM system speed” (V_STMSYS) together with an “STM system distance” (D_STMSYS) to the ERTMS/ETCS on-board through the STM Control Function.

8.6.1.3.1 Note: This “STM system speed” together with the “STM system distance” is sent to allow the STM, to request a given train speed at a given position (“STM system distance”) before the level transition border in order to be able to detect its national trackside.

8.6.1.4 When an STM in HS state receives an order to go in CS state, the STM shall have the possibility to close any connection except with STM Control Function.

## **8.7 Data Available (DA)**

8.7.1.1 In DA state, an STM is responsible for the train movement supervision, according to the received national trackside information.

8.7.1.2 When an STM in DA state receives an order to go in CS state, the STM shall have the possibility to close any connection except with STM Control Function.

## **8.8 Failure (FA)**

8.8.1.1 Being in this state, the STM is not able to work any more, due to internal or external reasons.

8.8.1.2 Being in this state, the STM shall not send messages any more on the bus except to report this state to the ERTMS/ETCS on-board functions.

<!-- end of page 48 -->
