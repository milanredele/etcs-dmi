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
| `EVC_Received` | What came from the track: the last accepted telegram and radio message (bits plus packet index), the counts by status, a reader on packet I. |

The ERTMS/ETCS language (SUBSET-026 chapters 7 and 8) is in `language/`:

| Package | Role |
|---|---|
| `ETCS_Bits` | `Reader` and `Writer` of bit strings, MSB first, variables of 1 to 64 bits; total operations with a sticky `Failed` flag. |
| `ETCS_Variables` | *Generated.* One type per variable of 7.5, the special values, `To_X`, `Code`, `Is_Valid`, `Bits (V)`, `Max (V)`. |
| `ETCS_Track_Packets.P<n>`, `ETCS_Train_Packets.P<n>` | *Generated.* One package per packet: `Packet_T` (loops as bounded arrays with their count, conditions as components plus `Has_` flags), `Decode`, `Encode`. |
| `ETCS_Catalogue` | *Generated.* NID_PACKET to kind, direction, name, clause, senders; `Check` (decode any kind), `Skip` by L_PACKET. |
| `ETCS_Message_Catalogue` | *Generated.* The radio messages of 8.6 and 8.7: variables and packet rules. |
| `ETCS_Packet_Index` | Scan of one packet: header, length, decode check; the index entry. |
| `ETCS_Telegram` | The Eurobalise telegram of 8.4.2: header checks, versions, index of the packets; building (header, 255, padding with ones). |
| `ETCS_Message` | The radio message of 8.4.4: L_MESSAGE, variables, mandatory and optional packets by the message catalogue; building. |

The generated units come from `language/etcs_language.toml` (format:
`language/SCHEMA.md`) by `language/gen_language.py`, never by hand:
`python3 evc/language/gen_language.py` regenerates, `--check` fails when
a checked-in file differs, `--stats` prints the sizes of the packet
records (a packet is decoded on the stack, on demand). The generator also
writes `test/src/etcs_language_random.ad[sb]`, the random valid packets
of the tests.

What phase E0 does: power-up in NP, NP -> SB (condition [4]), isolation
by the driver from any mode (condition [1], driver action 20), and every
cycle MSG_MODE_LEVEL and MSG_ONBOARD on the DMI port; a JRU event on every
mode change. Inputs of the wrong shape are ignored and counted. Phase E1: the
telegrams and radio messages are parsed at the next cycle, the last
accepted of each is kept and recorded on the JRU port, the rejections are
counted by reason.

Checks:

```
evc/prove.sh           # gnatprove: flow and proof, no unproved check
obj/evc_test           # golden runner (test/golden/evc/), UPDATE=1 records
obj/evc_fuzz           # random inputs, must end with raised: 0
python3 evc/language/gen_language.py --check   # generated code up to date
```

The hosted TCP main is `ports/hosted/evc.adb`, built as `obj/evc_onboard`
(`obj/evc` is the object directory of `etcs_evc.gpr`): it takes the hub
port 1338 of `evc_sim` and moves DMI protocol frames between the socket
and the DMI port.
