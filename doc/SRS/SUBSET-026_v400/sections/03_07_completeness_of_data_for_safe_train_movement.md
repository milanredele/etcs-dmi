## **3.7 Completeness of data for safe train movement**

### **3.7.1 Completeness of data**

3.7.1.1 To control the train movement in an ERTMS/ETCS based system the ERTMS/ETCS onboard equipment shall be given information from the trackside system both concerning the route set for the train and the track description for that route. The following information shall be given from the trackside

   - a) Permission and distance to run, the Movement Authority (MA) (see section 3.8)

   - b) When needed, limitations related to the movement authority, i.e. Mode profile for On Sight, Limited Supervision or Shunting and signalling related speed restriction (see sections 3.12.4 and 3.11.6). Mode profile and Signalling related Speed restriction shall always be sent together with the MA to which the information belongs

   - c) Track description covering as a minimum the whole distance defined by the MA. Track description includes the following information

      - The Static Speed Profile (SSP) (see section 3.11.3).

      - The gradient profile (see section 3.11.12).

      - Optionally Axle load Speed Profile (ASP) (see section 3.11.4)

      - Optionally Speed restriction to ensure a given permitted braking distance (see section 3.11.11)

      - Optionally track conditions (see section 3.12.1).

      - Optionally route suitability data (see section 3.12.2).

      - Optionally areas where reversing is permitted (see section 3.15.4).

      - Optionally changed adhesion factor (see section 3.18.4.5.5).

   - d) Linking information when available.

### **3.7.2 Responsibility for completeness of information**

3.7.2.1 The Movement Authority (MA) shall be given to the on-board equipment

   - Together with the other information (as listed in section 3.7.1.1 c) and d)) or

<!-- end of page 71 -->

   - Separately, if the other information has already been correctly received by the onboard equipment.

3.7.2.2 The trackside shall be responsible for that the on-board equipment has received the information valid for the distance covered by the Movement Authority.

3.7.2.2.1 In case of LOA, trackside shall be responsible for including any track description beyond the LOA relevant for calculating safe supervision limits.

3.7.2.3 The MA and the related mode profile, if any, shall not be accepted by the on-board equipment if the SSP and gradient already available on-board or given together with the MA do not cover the full length of the MA.

3.7.2.3.1 For a non-infill MA full length means at least from the estimated front end of the train to the supervised location, while for an infill MA full length means at least from the infill location reference (refer to 3.6.2.3.1) to the supervised location.

3.7.2.3.2 For an MA that is part of a Supervised Manoeuvre authorisation and whose validity direction is opposite to the current train orientation, full length means at least from the estimated front end of the train derived from the new train orientation (see 4.4.21.1.7 a)) to the supervised location.

3.7.2.4 It shall be possible for the trackside to send additional information when needed. The information referred to is

   - Emergency messages (from RBC only)

   - Request to shorten MA (from RBC only)

   - Temporary speed restrictions

   - National values

   - Level transition information

   - LX speed restrictions

   - Inhibition of revocable TSRs from balises in level 2 (from RBC only)

   - Virtual Balise Cover orders

### **3.7.3 Extension, replacement and deletion of location based information**

3.7.3.1 New track description and linking information shall replace (in the ERTMS/ETCS onboard equipment) stored information as detailed below:

- a) New Static Speed Profile information shall replace all stored Static Speed Profile information from the start location of the new information.

- b) New Gradient Profile information shall replace all stored Gradient Profile information from the start location of the new information.

- c) New Axle Load Speed Profile information shall replace all stored Axle Load Speed Profile information from the start location of the first element of the new information.

<!-- end of page 72 -->

   - d) New Speed Restriction to ensure Permitted Braking Distance information shall replace all stored Speed Restriction to ensure Permitted Braking Distance information from the start location of the first element of the new information.

   - e) New track condition Change of Traction System information shall replace all stored Change of Traction System information.

   - f) New track condition Big Metal Masses information shall replace all stored Big Metal Masses information from the start location of the first element of the new information.

   - g) New track condition information of at least one of the types listed here, i.e., sound horn, non stopping area, tunnel stopping area, powerless section - lower pantograph, powerless section - switch off the main power switch, radio hole, air tightness, switch off regenerative brake, switch off eddy current brake for service brake, switch off eddy current brake for emergency brake, switch off magnetic shoe brake, shall replace all stored track condition information of the listed types from the start location of the first element of the new information.

   - h) New route suitability loading gauge information shall replace all stored route suitability loading gauge information.

   - i) New route suitability traction system information shall replace all stored route suitability traction system information.

   - j) New route suitability axle load information shall replace all stored route suitability axle load information.

   - k) New reversing area information shall replace all stored reversing area information.

   - l) New adhesion factor information shall replace all stored adhesion factor information from the start location of the new information.

   - m) New linking information received as non-infill information shall replace all stored linking information from the reference balise group of the new linking information.

   - n) New linking information received as infill information shall replace all stored linking information from the reference location of the infill information (i.e. the balise group at next main signal).

   - o) New track condition Station Platform information shall replace all stored Station Platform information from the start location of the first element of the new information.

   - p) New track condition Allowed Current Consumption information shall replace all stored Allowed Current Consumption information.

3.7.3.1.1 Exception to 3.7.3.1 a): in case the start location of the new Static Speed Profile is relocated as per clause 3.6.4.2.5 b) or 3.6.4.2.5 c) towards a BG not received earlier than its former reference BG, the resulting Static Speed Profile information shall, over a distance starting from its start location as if it would be relocated as per 3.6.4.2.5 b) or c) 3<sup>rd</sup> bullet to its start location as if it would be relocated as per 3.6.4.2.5 b) or c) 2<sup>nd</sup> bullet, be composed of the lowest speed parts of each element of the stored Static Speed Profile and the new Static Speed Profile, taking into account the categories the train belongs to.

<!-- end of page 73 -->

   - From the start location of the new Static Speed Profile as if it would be relocated as per 3.6.4.2.5 b) or c) 2<sup>nd</sup> bullet, 3.7.3.1 a) shall apply by analogy.

3.7.3.1.2 Exception to 3.7.3.1 b): in case the start location of the new Gradient Profile is relocated as per clause 3.6.4.2.5 b) or 3.6.4.2.5 c) towards a BG not received earlier than its former reference BG, the resulting Gradient Profile information shall, over a distance starting from its start location as if it would be relocated as per 3.6.4.2.5 b) or c) 3<sup>rd</sup> bullet to its start location as if it would be relocated as per 3.6.4.2.5 b) or c) 2<sup>nd</sup> bullet, be composed of the lowest gradient parts of each element of the stored Gradient Profile and the new Gradient Profile. From the start location of the new Gradient Profile as if it would be relocated as per 3.6.4.2.5 b) or c) 2<sup>nd</sup> bullet, 3.7.3.1 b) shall apply by analogy.

3.7.3.1.3 Exception to 3.7.3.1 c): in case the new Axle Load Speed Profile is relocated as per clause 3.6.4.2.5 b) or 3.6.4.2.5 c) towards a BG not received earlier than its former reference BG, the resulting Axle Load Speed Profile information shall, over a distance starting from the start location of its first element as if it would be relocated as per 3.6.4.2.5 b) or c) 3<sup>rd</sup> bullet to the start location of its first element as if it would be relocated as per 3.6.4.2.5 b) or c) 2<sup>nd</sup> bullet, take into account the lowest speed part in any overlap between the element(s) of the stored Axle Load Speed profile and the element(s) of the new Axle Load Speed Profile, taking into account the axle load category of the train. From the start location of the first element of the new Axle Load Speed Profile as if it would be relocated as per 3.6.4.2.5 b) or c) 2<sup>nd</sup> bullet, 3.7.3.1 c) shall apply by analogy.

3.7.3.1.4 Exception to 3.7.3.1 d): in case the new Speed Restriction to ensure Permitted Braking Distance information is relocated as per clause 3.6.4.2.5 b) or 3.6.4.2.5 c) towards a BG not received earlier than its former reference BG, the resulting Speed Restriction to ensure Permitted Braking Distance information shall, over a distance starting from the start location of its first element as if it would be relocated as per 3.6.4.2.5 b) or c) 3<sup>rd</sup> bullet to the start location of its first element as if it would be relocated as per 3.6.4.2.5 b) or c) 2<sup>nd</sup> bullet, take into account the lowest speed part in any overlap between the element(s) of the stored Speed Restriction to ensure Permitted Braking Distance information and the element(s) of the new Speed Restriction to ensure Permitted Braking Distance information. From the start location of the first element of the new Speed Restriction to ensure Permitted Braking Distance information as if it would be relocated as per 3.6.4.2.5 b) or c) 2<sup>nd</sup> bullet, 3.7.3.1 d) shall apply by analogy.

3.7.3.2 When requested by trackside, the ERTMS/ETCS on-board equipment shall resume initial states beyond a given location individually:

   - a) for stored Speed Restriction to ensure Permitted Braking Distance information (for initial state, refer to 3.11.11.11)

   - b) for stored axle load speed profile information (for initial state, refer to 3.11.4.5)

   - c) through a single request, for all stored track condition information of the following types: sound horn, non stopping area, tunnel stopping area, powerless section – lower pantograph, powerless section – switch off the main power switch, radio hole, air tightness, switch off regenerative brake, switch off eddy current brake for service

<!-- end of page 74 -->

brake, switch off eddy current brake for emergency brake and switch off magnetic shoe brake (for initial states, refer to 3.12.1.3)

   - d) through a single request, for all stored route suitability information (for initial state, refer to 3.12.2.10).

   - e) through a single request, for all stored track condition information of the type Station Platform (for initial state, refer to 3.12.1.3).

3.7.3.3 In some situations, the location based information shall be deleted (or initial state shall be resumed) by the on-board equipment. These various cases where the data is affected (e.g. the MA is shortened) are described in detail in Appendix A.3.4.

- 3.7.3.4

   - Upon reception of a Supervised Manoeuvre authorisation:

   - a) If the validity direction of the new Movement Authority is the same as the current train orientation, the clause 3.7.3.1 shall apply.

   - b) If the validity direction of the new Movement Authority is opposite to the current train orientation, the clause 3.7.3.1 shall not apply and all previously stored location based information shall be deleted.

- 3.7.3.5

   - Deleted.

3.7.3.6 Note: regarding the handling of Temporary Speed Restrictions and Level Crossings, see also sections 3.11.5 and 3.12.4.7.
