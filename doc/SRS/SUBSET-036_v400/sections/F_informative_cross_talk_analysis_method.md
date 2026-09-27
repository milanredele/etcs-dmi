# **Annex F (Informative), Cross-talk analysis method**

# **F1 Background**

A THR (here referred to as THRcross-talk) is possible to extract from SUBSET-091.

However, THRcross-talk can not be directly interpreted as the THR for the equipment involved in potential crosstalk, because:

- It only refers to the total contribution to the ETCS top hazard coming from potential cross-talk problems in one hour.  There are a number of critical scenarios where cross-talk can happen, which need to be investigated for potential barriers.

- It refers to the hazardous situation, not the technical failures.  Thus, there needs to be a link established between the hazard and the technical failures.

- It needs to be split between track-side and On-board.

Therefore, the following matrix (see clause F2) shall be used as a guideline to determine the requirements for On-board and track-side respectively.

This annex contains a description of the matrix (see clause F2).

The content of the matrix is a recommendation, but the methodology shall be applicable.

The Q values for track-side are given as a guideline.  The overall safety target may also be achieved by refining the Q-value considering the project specific aspects of system implementation (e.g., maintenance, engineering, etc.).  The On-board values are mandatory.

# **F2 Matrix**

## **F2.1 General**

The information herein is split into two parts:

- “Methodology to demonstrate compliance with THR”, which contains the actual calculations.  This is the worksheet referred to in clause F3.

- “I/O diagrams”, which contains a description of what is meant by the failure modes for Balise failures B1, B2, and B3 in the matrix.

<!-- end of page 148 -->

## **F2.2 Methodology to demonstrate compliance with THR**

|**FR = Frequency of vulnerable scenarios [per hour] :**|2<br>0.01<br>0|For cross-talk<br>It is not allowe<br>For cross-talk<br>other permiss|distance3 m (n<br>d to place balises<br>distance 1.4 - 3 m<br>ive data|ormal adjac<br>closer than<br>(adjacent t|ent tracks)<br>1.4 m to an<br>racks closer|other track<br>than norm|al, e.g. before|point) and Ba|lise group c|ontains MA or|
|---|---|---|---|---|---|---|---|---|---|---|
||||||Cross-talk|with cables||Cross|-talk without|cables|
||**Re**|**sulting cross-t**|**alk distance :**|**Scen 1**<br>**3 m**|**Scen 2**<br>**3 m**|**Scen 3**<br>**3 m**|**Scen 4**<br>**3 m**|**Scen 5**<br>**1.4 - 3 m**|**Scen 6**<br>**1.4 - 3 m**|**Scen 7**<br>**1.4 - 3 m**|
|**Failure mode**<br>Balise group failures|**[f/h]**|**MTTR**|**Q [-]**||||||||
|B1<br>Balise group too sensitive to Tele-powering (<10 dB) and Out <Iu3|C.S.|C.S.|5.0E-02|||||||5.0E-02|
|B2<br>Balises energised via Interface'C'and Out <Iu3|C.S.|C.S.|5.0E-02|||5.0E-02|||5.0E-02||
|B3<br>Balise group too strong (from Iu3 to Iu3+20 dB)|C.S.|C.S.|6.0E-06|6.0E-06|6.0E-06|||6.0E-06|||
|BTM function failures|||||||||||
|O1<br>On-board equipment too sensitive to Up-link (<30 dB)|||1.0E-06|||1.0E-06|1.0E-06||1.0E-06||
|O2<br>On-board equipment has too strong Tele-powering (<10 dB)|||1.0E-06||1.0E-06|||1.0E-06||1.0E-06|
|External conditions|||||||||||
|E1<br>Presence of approved cables in ground (first balise)|||0.1|0.1|0.1|0.1|0.1||||
|E2<br>The cables layout are in a systematic way (second balise)|||0.1|0.1|0.1|0.1|0.1||||
|E3<br>Above cables create a group|||0.9|0.9|0.9|0.9|0.9||||
|E4<br>Resonance in both cables near Up-link frequency|||0.01|||0.01|||||
|E5<br>Resonance in both cables near Tele-powering frequency|||0.01||0.01||||||
|E6<br>A second antenna is activating the balises (two antennae case)|||0.01|0.01|||0.01||||
|E7<br>Probability that a fully correct telegram is received|||0.5|0.50|0.50|0.50|0.50|0.50|0.50|0.50|
||||**ProdQ**|2.7E-10|2.7E-16|2.3E-12|4.5E-11|3.0E-12|2.5E-08|2.5E-08|
|**Target Hazard Rate (THR for ETCS_TR05/ETCS_OB08):**|**_1.0E-09_**<br>From|**Resulting**|**Hazard Rate:**|5.4E-10|5.4E-16|4.5E-12|9.0E-11|3.0E-14|2.5E-10|2.5E-10|

SUBSET-091

Comment to O1:  The On-board equipment is more sensitive than specified.  It is assumed that it can not be more than 30 dB more sensitive than a fault-free on-board equipment.

Comment to O2:  The On-board equipment is sending more Tele-powering field than specified.  It is assumed that it cannot send more than 10 dB more than a fault-free on-board equipment.

Comment to E1:  Cables approved according to company specific installation rules that give protection for non faulty equipment.  This cable shall both pass in the vicinity of the balise (e.g., < 2m) and then pass the track at a different position.

Comment to E4:  With "resonance" it is meant that current in cable is amplified due to the lay out of the cable and the impedance to ground.  Without resonance it is assumed that the current at the vicinity of the track is at least 20 dB lower than what i

Comment to E5:  With "resonance" it is meant that current in cable is amplified due to the lay out of the cable and the impedance to ground. Without resonance it is assumed that the current at the vicinity of the track is at least 20 dB lower than what is

<!-- end of page 149 -->

## **F2.3 I/O Diagrams**

<!-- Start of picture text -->
B1: Iu too sensitive Out < Iu3 and<br>Out <(the line O to Iu3/Fid2+10dB)<br>200<br>180<br>160<br>140<br>120<br>100<br>Iu max spec.<br>80<br>60<br>40 Iu too sensitive <Iu3 and I/O>10dB<br>20<br>0<br>0 5 10 15<br>nVs<br>mA<br><!-- End of picture text -->

**Figure 55:  Reduced Size, Failure Mode B1**

<!-- Start of picture text -->
B2: Iu too sensitive Out < Iu3<br>200<br>180<br>160<br>140<br>120<br>100<br>80<br>60 Iu max spec. Iu too sensitive <Iu3<br>40<br>20<br>0<br>0 2 4 6 8 10 12 14 16<br>nVs<br>mA<br><!-- End of picture text -->

**Figure 56:  Reduced Size, Failure Mode B2**

<!-- end of page 150 -->

<!-- Start of picture text -->
B3: Iu too sensitive Out > Iu3 and<br>Out < (the line thrugh O to Iu3/Fid2) and<br>Out <Iu3+20dB<br><!-- End of picture text -->

<!-- Start of picture text -->
2000<br>1800<br>1600<br>1400<br>1200<br>1000 Iu too sensitive >Iu3 and efficency<br>< O - Iu3/Fid2 line<br>800<br>600 Iu max spec.<br>400<br>200<br>0<br>0 20 40 60 80 100<br><!-- End of picture text -->

**Figure 57:  Reduced Size, Failure Mode B3**

<!-- Start of picture text -->
B1: Iu too sensitive Out < Iu3 and<br>Out <(the line O to Iu3/Fid2+10dB)<br>140<br>120<br>100<br>80<br>Iu max spec.<br>60<br>40<br>20 Iu too sensitive <Iu3 and I/O>10dB<br>0<br>0 5 10 15 20 25 30<br>nVs<br>mA<br><!-- End of picture text -->

**Figure 58:  Standard Size, Failure Mode B1**

<!-- end of page 151 -->

<!-- Start of picture text -->
B2: Iu too sensitive Out < Iu3<br>140<br>120<br>100<br>80<br>60<br>40 Iu max spec. Iu too sensitive <Iu3<br>20<br>0<br>0 5 10 15 20 25 30<br>nVs<br>mA<br><!-- End of picture text -->

**Figure 59:  Standard Size, Failure Mode B2**

**B3: Iu too sensitive Out > Iu3 and Out < (the line thrugh O to Iu3/Fid2) and Out <Iu3+20dB**

<!-- Start of picture text -->
1400<br>1200<br>1000<br>800<br>Iu too sensitive >Iu3 and efficency<br>600 < O - Iu3/Fid2 line<br>400 Iu max spec.<br>200<br>0<br>0 20 40 60 80 100 120<br><!-- End of picture text -->

**Figure 60:  Standard Size, Failure Mode B3**

<!-- end of page 152 -->

# **F3 Step-by-step Methodology**

The following step-by-step methodology shall be followed when working with the cross-talk matrix of clause F2:

1. Decide on failure modes

The list of failure modes, second column, shall first be finalised according to expert judgement.

2. Set up scenarios

Each scenario is set up according to expert judgement, and is made up of the combination of the failure modes that are necessary for obtaining cross-talk.  For the failure modes that are a part of the scenario, the value in fifth column, “Q-value”, is copied to the scenario column.

3. Fill in frequency of vulnerable scenarios

The frequencies (FR) of the cells including “frequency of vulnerable scenarios” are filled in according to the input from SUBSET-091.

4. Calculate Hazard Rate for all scenarios by HR=FR*ProdQ

For all scenarios, the Resulting Hazard Rate is calculated according to HR=FR*ProdQ, where ProdQ is the product of all Q-values in the scenario.

5. Output: iterate on Q to achieve Hazard Rate < THRcross-talk for all scenarios

The result from the matrix is obtained by manually iterating on Q for the technical failures, so that the Resulting Hazard Rate becomes less than the initial target THRcross-talk (considering a reasonable margin for undefined phenomena). Finally, the yellow fields give the Requirements (Q-value) for each technical failure, after completed iteration.

Note that Q-values (unavailability) are defined herein because it allows for flexibility in MTTR (Maintenance requirements).

The Q-values and the equipment failure rate  relates to each other by MTTR, or vice versa, through the equations Q  1-e<sup>-(*MTTR) 59</sup> , or Q  1-2e<sup>-(*MTTR)</sup> +e<sup>-(2*MTTR)60</sup> .  Failure rates and MTTR are supplier specific.

> 59 Single failure calculation.

> 60 Double failure calculation.

<!-- end of page 153 -->

# **F4 Description of Scenarios**

The scenarios that are in the current version of the matrix are briefly outlined here:

|**Scenario**|**Description**|
|---|---|
|1|Both Balises in a Balise Group are able to output too much energy.  A second antenna that is mov-<br>ing over the Balise Group in a similar pattern as the first antenna (i.e., two trains running in paral-<br>lel) energises them.  Cables in the ground are present for both Balises, and they create a consistent<br>group in the wrong track.  The cables need not be resonant.|
|2|Both Balises in a Balise Group are able to output too much energy.  They are energised by the train<br>itself, which outputs too much Tele powering.  In this case, it is also necessary to have resonance<br>near 27 MHz; otherwise the Tele powering will not energise the Balise.|
|3|Both Balises in a Balise Group are erroneously energised via Interface ‘C’.  If cables are present,<br>the on-board equipment can receive the Up-link signal if the receiver is too sensitive.  The cables<br>have to be resonant at 4.5 MHz.|
|4|A second antenna that is moving over the Balise group in a similar pattern as the first antenna (i.e.,<br>two trains running in parallel) energises them.  Cables in the ground are present for both Balises,<br>and they create a consistent group in the wrong track.  The cables need not be resonant.  The On-<br>board equipment can receive the Up-link signal if the receiver is too sensitive.|
|5|Both Balises in a Balise Group are able to output too much energy.  They are energised by the train<br>itself, which has too strong Tele powering.  The train can receive the Balise Group if the distance is<br>closer than 3 m.|
|6|Both Balises in a Balise Group are erroneously energised via Interface ‘C’.  If the distance is closer<br>than 3 metres, the Up-link signal can be received by the On-board equipment in case the receiver is<br>too sensitive.|
|7|Both Balises in a Balise Group are too sensitive to Tele powering, so they start transmitting if they<br>are energised by the train itself, which has too strong Tele-powering.  If the distance if closer than<br>3 metres, the Up-link signal can be received by the train.|

Note that scenarios 5, 6, and 7 (cross-talk distances from 1,4 m to 3 m) can only happen in specific cases (e.g., before points).  In this case, no other train can run (due to loading gauge).  Therefore, on one hand, only the single antenna case is applicable.  On the other hand, from a signalling point of view, cross-talk data received from the other track should usually not contain Movement Authority (MA) or other permissive data, which are in contradiction to the current route set.  Nevertheless, exceptions are possible like repositioning information. However, if two consecutive repositioning information points (Balise Groups) are found, this shall result in a safe reaction by the On-board system.  This rule is defined in SUBSET-091.

Note that some scenarios may, if justified, be excluded in specific applications, and others might be added if shown relevant.

<!-- end of page 154 -->
