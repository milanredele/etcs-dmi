# Specifications

The ERTMS/ETCS specifications this project implements or builds against.
All are public at
[ERA, CCS TSI Appendix A](https://www.era.europa.eu/era-folder/1-ccs-tsi-appendix-mandatory-specifications-etcs-b4-r1-rmr-gsm-r-b1-mr1-frmcs-b0-ato-b1)
(Baseline 4 release 1). Each folder holds the PDF, which is the reference,
its text as markdown in `sections/` for searching (tables that span pages
split, figures lost: check the PDF page named in the
`<!-- end of page N -->` comments), and a README with the index and what
this project takes from the document. The imports are made by the scripts
in [tools/](tools/README.md).

| Specification | Version | Folder | Title | Used for |
|---|---|---|---|---|
| ERA_ERTMS_015560 | 4.0.0 | [ERA_ERTMS_015560_v400](ERA_ERTMS_015560_v400/) | ETCS Driver Machine Interface | The DMI: layout, symbols, sounds, dialogues. The specification of the first product of the repository. |
| SUBSET-026 | 4.0.0 | [SUBSET-026_v400](SUBSET-026_v400/README.md) | System Requirements Specification | The on-board logic the EVC implements (levels 0, 1, 2; modes, procedures, language and messages); reference [2] of the DMI specification. |
| SUBSET-034 | 4.0.0 | [SUBSET-034_v400](SUBSET-034_v400/README.md) | Train Interface FIS | The TIU port: the signals between the on-board and the vehicle, as typed values. |
| SUBSET-041 | 4.0.0 | [SUBSET-041_v400](SUBSET-041_v400/README.md) | Performance Requirements for Interoperability | Response times of the on-board and accuracy of odometry and clock: the timing budget of the cyclic executive and what `sim/` models for the odometer port. |
| SUBSET-130 | 1.0.0 | [SUBSET-130_v100](SUBSET-130_v100/README.md) | ATO-OB / ETCS-OB FFFIS Application Layer | The ATO port: the packets between the ATO on-board and the EVC. |
| SUBSET-125 | 1.1.0 | [SUBSET-125_v110](SUBSET-125_v110/README.md) | ERTMS/ATO System Requirements Specification | The ATO side of Automatic Driving, behind SUBSET-026 4.4.16 and 3.15.11 and the ATO module on the ATO port. |
| SUBSET-027 | 4.0.0 | [SUBSET-027_v400](SUBSET-027_v400/README.md) | FIS Juridical Recording | The JRU port: which events are recorded, with which message. |
| SUBSET-036 | 4.0.0 | [SUBSET-036_v400](SUBSET-036_v400/README.md) | FFFIS for Eurobalise | Below the BTM port, out of scope: the port delivers decoded telegrams. |
| SUBSET-037 | 4.0.0 | [SUBSET-037_v400](SUBSET-037_v400/README.md) | EuroRadio FIS, parts 1 to 3 | Below the RTM port, out of scope: the safety layer and the mobile network; the session management of SUBSET-026 3.5 sits on its services. |
| SUBSET-035 | 4.0.0 | [SUBSET-035_v400](SUBSET-035_v400/README.md) | Specific Transmission Module FFFIS | Out of scope (no STM interface); for the boundary with level NTC and mode SN. |
| SUBSET-076 | 4.0.0 | [SUBSET-076_v400](SUBSET-076_v400/README.md) | Test specifications (part 7 in the folder; test cases 5-2 and sequences 6-3 by link) | Validation of the on-board in phases E3 to E5. |

Referenced but not in the repository: SUBSET-023 (glossary), SUBSET-040
(dimensioning and engineering rules), SUBSET-094 (reference test facility),
SUBSET-143 (on-board communication layers under SUBSET-130), SUBSET-126
(ATO-OB / ATO-TS).
