# **11. TIU AND BIU FUNCTIONS**

11.1.1.1 The TIU Function shall transmit train interface inputs status / availability :

   - a) To any STM with an established connection to the TIU Function whenever a train interface inputs status / availability changes.

   - b) To any connecting STM when the connection to the TIU Function is established.

11.1.1.1.1 The TIU Function shall transmit train interface commands configuration to any connecting STM when the connection to the TIU Function is established.

11.1.1.2 The BIU Function shall transmit the brake performance parameters to any connecting STM when the connection to the BIU Function is established.

11.1.1.3 The BIU Function shall transmit the brake status / availability :

   - a) To any STM with an established connection to the BIU Function whenever a brake status / availability changes.

   - b) To any connecting STM when the connection to the BIU Function is established.

11.1.1.4 When the service brake is commanded by an STM, the STM shall indicate in its request if the service brake shall be backed up automatically by the ERTMS/ETCS on-board with an Emergency Brake command if the service brake fails to be applied.

11.1.1.4.1 Note: If it is not the case, this has to be considered as an exception to [1].

<!-- end of page 70 -->
