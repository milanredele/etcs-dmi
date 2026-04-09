# ETCS DMI SRS GAP ANALYSIS (v3.4.0 vs v4.0.0)

This document outlines the findings from a high-level comparison between the current Ada implementation (based on ETCS DMI v3.4.0) and the requirements specified in **SRS 4.0.0** (ERA_ERTMS_015560 v400).

## 1. Functional Implementation Gaps

| Feature / Area | Current Implementation (v3.4.0) | Gap in SRS 4.0.0 |
| :--- | :--- | :--- |
| **Supervision Status** | `NoS`, `IndS`, `OvS`, `WaS`, `IntS` in [src/speed_and_distance.ads](src/speed_and_distance.ads). | **Missing `NAS` (No Applicable Status)**. v4.0.0 Section 7 specifies transitions and conditions for this state. |
| **Monitoring Modes** | `CSM`, `PIM`, `TSM`, `RSM` in [src/speed_and_distance.ads](src/speed_and_distance.ads). | **Missing `OSM` (On-Sight Monitoring)** and updated behavior for **`LS` (Limited Supervision)** as per v4.0.0 Section 7.1.1.2. |
| **Speed Pointer Colors** | Handled in [src/display-b_area-speed_dial-draw_speed_pointer.adb](src/display-b_area-speed_dial-draw_speed_pointer.adb). | **`Indication (IndS)` in `CSM` Mode**. Current code `raises Program_Error` for this case, but v4.0.0 describes specific indication transitions. |
| **Speed Dial Hooks** | Uses `Basic_Speed_Hook_Width` constant in [src/display-b_area-speed_dial.ads](src/display-b_area-speed_dial.ads). | **Refined Hook Geometry**. v4.0.0 Section 8.2.1.4 explicitly defines "Basic Speed Hook" and "Target Speed Hook" with more precise visual rules. |
| **Area B6 (Release Speed)** | Draws `Vrelease` digital text in [src/display-b_area-speed_dial.adb](src/display-b_area-speed_dial.adb). | **Layering & Visibility Rules**. v4.0.0 Section 8.1.1.4 assigns B6 to **Layer -2**. Current code doesn't strictly implement the layer engine required. |

## 2. Technical & Performance Gaps

| Analysis Category | Finding | Recommended Change |
| :--- | :--- | :--- |
| **Embedded Performance** | Use of `Ada.Numerics.Elementary_Functions` (`Sin`/`Cos`) in the main draw loop for Area B ([src/display-b_area-speed_dial.adb](src/display-b_area-speed_dial.adb)). | **Pre-computed Lookup Tables (LUTs)**. For target ARM/POWER MCUs (128kB RAM), dynamic trig is too heavy. Use LUTs for `Speed_To_Angle` mapping. |
| **Layering Model** | Application areas (A, B, C, D) are defined in [src/display.ads](src/display.ads) but lack a **Layering Engine**. | **Three-Layer Model**. v4.0.0 (Section 5) requires Layer 0 (top), Layer -1 (middle), and Layer -2 (bottom). This must be enforced to handle object occlusion (e.g., speed pointer crossing the dial). |
| **Color Precision** | Current palette in `general_parameters.ads` uses v3.4.0 RGB values. | **Refresh Palette**. v4.0.0 (Section 5) updated RGB constants for `GREY`, `MEDIUM_GREY`, and `DARK_GREY` to improve contrast on newer LCDs. |
| **Non-Linear Speed Scale** | `Linear_Scale` type in [src/display-b_area-speed_dial.ads](src/display-b_area-speed_dial.ads). | **Compound Scaling**. v4.0.0 (Section 8.2.1.1.13) defines a non-linear scale for 0-400 km/h where the resolution changes at 200 km/h. Current code uses a simple linear mapping. |

## 3. Version Differences Summary (v3.4.0 → v4.0.0)

1.  **Symbols**: Many bitmaps (e.g., Target speed symbols in B2) have been redrawn in v4.0.0 for better legibility. The `symbol.ads` should be audited against the updated Table 5 in SRS 4.0.0.
2.  **Supervision Transitions**: v4.0.0 Figure 11 provides a much more rigorous state transition graph for P/I/W/S/I status than 3.4.0.
3.  **Audible Information**: Sound priorities and repetition rules in v4.0.0 Section 14 have been clarified for scenarios where multiple alerts occur simultaneously.

## 4. Next Steps for Implementation

1.  **Refactor Area B**: Move from dynamic trig to LUTs.
2.  **Implement Layering**: Add logic to the `Display.Frame_Buffer` or `Display` package to handle Layer 0, -1, -2 correctly.
3.  **Update `Speed_Params`**: Add `NAS` status and update monitoring mode logic to include `OSM`.
4.  **Symbol Redraw**: Use `utils/bmp2ada` to update critical symbols for 4.0.0 compliance.
