# **12. ODOMETER FUNCTION**

## **12.1 General**

12.1.1.1 The FFFIS STM specifies the odometer information to be transmitted from ERTMS/ETCS on-board to all STMs via FFFIS STM.

12.1.1.2 The ERTMS/ETCS on-board shall transmit odometer information via the FFFIS STM interface at regular intervals. This information shall include current values of estimated distance, direction, estimated speed, confidence interval of measurement of distance (i.e. minimum and maximum distances) and confidence interval for speed (i.e. minimum and maximum speeds).

12.1.1.3 Every transmitted odometer information report shall be time stamped. The time base for timestamp shall be the Reference Time obtained from the Safe Time Layer, see 5.2.2. The time in the timestamp shall be the time when the odometer data were valid.

12.1.1.3.1 Justification: this time information allows an STM to extrapolate distance and speed to fit its algorithms and processing cycles.

12.1.1.4 Positive movement direction is defined as a movements in the forward direction in relation to cab A. It shall be indicated with positive speed and increasing odometer distance values.

12.1.1.5 Negative movement direction is defined as movements in the backward direction in relation to cab A. It shall be indicated with negative speed and decreasing odometer distance values.

12.1.1.5.1 Note: Allocation of cab(s) on a specific train is a pure ERTMS/ETCS on-board implementation issue.

12.1.1.6 The ERTMS/ETCS on-board shall not reset the odometer distance values as long as the ERTMS/ETCS on-board is powered-on.

12.1.1.6.1 Justification: The ETCS odometer information is used as a common reference within the FFFIS STM.

12.1.1.7 The ERTMS/ETCS on-board shall transmit odometer configuration data (see chapter 12.4) to the STMs.

## **12.2 Speed**

12.2.1.1 **Estimated speed, V_Est,** shall be the estimated speed as used by the ERTMS/ETCS on-board (also referred as the train speed in [1]).

12.2.1.2 **Maximum speed, V_Max,** is defined as the most positive speed, i.e. the highest possible physical speed including under-reading amount, in case of movement in positive direction (V_Max = V_Est + |V_ura|). For movements in negative direction V_Max reports the lowest possible speed in absolute value, i.e. including over-reading amount (V_Max = V_Est + |V_ora|).

<!-- end of page 71 -->

12.2.1.3 **Minimum speed, V_Min,** is defined as the most negative speed, i.e. the lowest possible physical speed including over-reading amount, in case of movement in positive direction (V_Min = V_Est - |V_ora|). For movements in negative direction V_Min reports the highest possible speed in absolute value, i.e. including under-reading amount (V_Min = V_Est - |V_ura|).

<!-- Start of picture text -->
measured V_Max<br>speed<br>V_Nom<br>V_Min<br>physical<br>speed<br><!-- End of picture text -->

**Figure 9 – Example of transmitted speed information**

## **12.3 Distance**

12.3.1.1 The estimated distance, **D_Est** , shall be the most probable position of the vehicle in the vehicle coordinate system at the time given in the odometer packet, with reference to the vehicle position at the last reset of the odometry.

12.3.1.2 Note: For any train movement, the  most probable distance travelled between any two track positions can be computed as the difference between the measurement values of D_Est at the two positions.

12.3.1.3 **D_Max** is defined as the most positive position of the vehicle in the vehicle coordinate system at the time given in the odometer packet, with all over- and under-reading amounts accumulated since the last reset of the odometry.

12.3.1.4 **D_Min** is defined as the most negative position of the vehicle in the vehicle coordinate system at the time given in the odometer packet, with all over- and under-reading amounts accumulated since the last reset of the odometry.

12.3.1.5 The confidence interval shall comply with the relevant requirements specified in [7].

12.3.1.6 The resolution part of an odometer report shall be given as a parameter in each odometer report from the ETCS Odometer Function. This allows for sensor technologies with varying resolution.

12.3.1.7 Note: The STM can then compute the maximum and minimum travelled distances at the current vehicle position p2 with regards to any reference location p1 by using the resolution information, maximum and minimum distances at the these locations, as follows:

<!-- end of page 72 -->

max_distance(p1→p2) = max(D_Res(p1), D_Res(p2)) + D_Max(p2) – D_Max(p1)

min_distance(p1→p2) = - max(D_Res(p1), D_Res(p2)) + D_Min(p2) – D_Min(p1)

12.3.1.8 The distance parameters D_Est, D_Max and D_Min are allowed to wrap when exceeding the value range. The parameters wrap individually.

## **12.4 Configuration information**

12.4.1.1 The ERTMS/ETCS on-board Odometer Function shall transmit performance related information (configuration data) over the FFFIS STM. The transmission shall be repeated to support restarting STMs.

12.4.1.1.1 Note: The STM may use the performance-related information (e.g. ageing) to adjust its supervision, e.g. braking curves.

<!-- Start of picture text -->
Sensor Compute Bus STM<br>Cycle<br>time<br>Bus delay (token cycle)<br>Production delay<br>(including bus delay)<br><!-- End of picture text -->

**Figure 10 – Odometer cycle and delay times**

12.4.1.2 **Typical cycle time, T_OdoCycle** is the typical time for the odometer cycle time between each generating of new odometer data.

12.4.1.3 Note: The actual cycle time may well exceed T_OdoCycle.

12.4.1.4 **Maximum production delay time, T_OdoMaxProd** is the maximum ageing of odometer data from when the data was true until the data is available on the bus. This shall include clock synchronisation inaccuracy of the Odometer Function.

12.4.1.5 Note: The actual production delay time should not exceed T_OdoMaxProd.

<!-- end of page 73 -->
