# **Annex G (Informative), Guidelines related to Metallic Masses**

# **G1 Introduction**

This guideline provides a step by step instruction for interpreting and applying the requirements related to metallic objects.  It clarifies the relations between already defined requirements.  The categories herein refer to the definitions of sub-clause 6.5.2 on page 125.  The requirements of the main text take precedence in the unlikely case that there become inconsistencies.

# **G2 Guidelines for Determining Applicable Rules**

## **G2.1 Step 1**

Is the top surface of the object situated lower than 80 mm below the top of rail ?

If the answer is YES, this is a category 3 object, and:

- This does not impose any constraints for the purpose of the On-board system.

- The installation of the Balises needs only to fulfil the normal installation rules as defined in sub-clauses 5.6 and 5.7.10.

If the answer is NO:

- Go to Step 2.

<!-- end of page 155 -->

## **G2.2 Step 2**

Does the top surface of the object fit into the following ranges ?

|**Width**|**Highest distance from top of rail**<sup>**61**</sup>|
|---|---|
|**[mm]**|**[mm]**|
|100 – 120|-80 – +42|
|100 – 200|-80 – 0|
|> 200|-80 – -50|

If the answer is YES, this is a category 2 object, and:

- This does not impose any constraints for the purpose of the On-board system.

- The installation of the Balises needs to fulfil the normal installation rules as defined in sub-clauses 5.6 and 5.7.10, and in addition respect the dobject  1.1 m as defined in sub-clause 6.2.1.8 on page 113.

If the width is less than 100 mm, but the distance is still within the ranges defined in the table above, then it is a category 3 object, and:

- See consequences according section Step 1 above.

If the top surface of the object is situated higher than the upper limit of the ranges defined in the table above, then:

- Go to Step 3.

<!-- end of page 156 -->

## **G2.3 Step 3**

Does the top surface of the object fit into the following ranges and the length is less than 10 m ?

|**Width**|**Highest distance from top of rail**<sup>**62**</sup>|
|---|---|
|**[mm]**|**[mm]**|
|120|+42 – +92|
|200|0 – +50|
|> 200|-50 – 0|

If the answer is YES, this is a category 1 object, and:

- This does not impose any constraints for the purpose of the On-board system.

- The installation of the Balises needs to fulfil the normal installation rules as defined in sub-clauses 5.6 and 5.7.10, and in addition respect the _d object_  .035 • _lobject_ + 1.1 m as defined in sub-clause

   - 6.2.1.8 on page 113.

If the top surface of the object is situated higher than the upper limit of the ranges defined in the table above, then:

- Go to Step 4.

If the top surface of the object is within the ranges defined in the table above, but the length is exceeding 10 m, then:

- Go to Step 4.

## **G2.4 Step 4**

When reaching this step, we have an object that is considered outside the allowed metallic mask.  The consequences are:

- The On-board Transmission Equipment is allowed to give an alarm to the ERTMS/ETCS Kernel.  The ERTMS/ETCS Kernel shall ignore this alarm by having been informed in advance, e.g., by the appropriate Balise information (as defined in sub-clause 6.2.1.7 on page 113).

- In addition to the normal Balise installation rules as defined in sub-clauses 5.6 and 5.7.10, the distance from the end of such a metal mass to the centre of a Balise shall exceed db [m]  0.2 [s] • Maximum Permitted Speed [km/h] / 3.6 (as defined in sub-clause 6.2.1.7 on page 113).

- In order to generally treat two nearby metallic objects, concluded being outside the allowed metallic mask, as constituting two separated objects, the minimum distance between such objects shall be more than 2*(0.2 [s]*Maximum Permitted Speed [km/h] / 3.6) (twice the distance defined in sub-clause 6.2.1.7 on page 113).

<!-- end of page 157 -->
