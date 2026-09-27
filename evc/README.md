# evc/ — the ETCS on-board

The ETCS on-board of SUBSET-026 v4.0.0, built in phases
([doc/EVC-PLAN.md](../doc/EVC-PLAN.md)). Every unit here is SPARK
(`SPARK_Mode => On`) and proven with gnatprove; none uses `common/`,
Ada.Streams, tasking, allocation, floating point or anything host-only, so
the same sources build for the host, wasm32 and a bare-board light runtime
(`etcs_evc.gpr`).

| Package | Role |
|---|---|
| `EVC_Core` | The core: `Initialise`, `Handle_Input (Port, Payload)`, `Tick (Dt_Ms)`, `Take_Outputs`, `Enter_Failure` / `Failed`. One `Tick` is one cycle, in the order of the plan: read ports, position, stored information, monitoring, mode machine, outputs. |
| `EVC_Modes` | The 19 modes of 4.3.2 (`M_FS` .. `M_RV`), the levels (0, NTC, 1, 2), the status of the stored level, and the transitions table of 4.6.2 with its priorities. |
| `EVC_Ports` | The ports (BTM, RTM, odometer, TIU, DMI, ATO, JRU), the maximum payload of each and the documented shape of every payload; `Valid_Input` checks it. |
| `EVC_DMI_Port` | The frames of the DMI protocol v2 the on-board accepts and sends, byte by byte (the constants repeat `common/dmi_protocol.ads`; `evc_test` checks them). |
| `EVC_Outbox` | The bounded queue of outputs: records `port u8, length u16, payload`. |
| `EVC_Bytes` | Bytes and little endian fields, read and written byte by byte. |

What phase E0 does: power-up in NP, NP -> SB (condition [4]), isolation
by the driver from any mode (condition [1], driver action 20), and every
cycle MSG_MODE_LEVEL and MSG_ONBOARD on the DMI port; a JRU event on every
mode change. Inputs of the wrong shape are ignored and counted.

Checks:

```
evc/prove.sh           # gnatprove: flow and proof, no unproved check
obj/evc_test           # golden runner (test/golden/evc/), UPDATE=1 records
obj/evc_fuzz           # random inputs, must end with raised: 0
```

The hosted TCP main is `ports/hosted/evc.adb`, built as `obj/evc_onboard`
(`obj/evc` is the object directory of `etcs_evc.gpr`): it takes the hub
port 1338 of `evc_sim` and moves DMI protocol frames between the socket
and the DMI port.
