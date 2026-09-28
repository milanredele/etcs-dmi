# The ERTMS/ETCS language as data

`etcs_language.toml` describes the variables (SUBSET-026 7.5), the
packets (7.4) and the radio messages (8.6, 8.7) of the ERTMS/ETCS
language, version 4.0.0. It is written by
hand from the PDF (the markdown loses the structure of the packet tables:
which fields belong to a loop or to a condition) and it is the single
source of the generated Ada under this directory (`gen_language.py`).
The generated files are checked in and carry a header naming the
generator; regenerating must give no diff.

## Variables

```toml
[variables.NID_PACKET]
bits = 8                     # length in bits, 1 .. 64 (NID_RADIO is 64)
clause = "7.5.1.93"          # where 7.5 defines it
# optional
min = 0                      # smallest meaningful value, default 0
max = 255                    # largest, default 2**bits - 1
special = { 1023 = "unknown" }   # special values, by value
scale = "Q_SCALE"            # the resolution depends on Q_SCALE (D_, L_)
resolution = "km/h, 5 km/h steps"   # free text otherwise
```

A variable name is exactly the SRS name (upper case, underscores). The
same variable has one definition; where a packet lists `NID_LRBG` as
`10 + 14`, the description uses the two variables `NID_C` (10) and
`NID_BG` (14) in that order, as 7.5.1.90 defines it (the generator emits
the combined field as well, see below).

Clarifications (as the catalogue is written):

- `min`, `max` and the keys of `special` are raw values, what is on the
  wire; the physical unit is in `scale` or `resolution`. A value above
  `max` that is not in `special` is spare (7.3.2.4).
- A negative `min` means the variable is signed, two's complement
  (7.3.2.7); D_REF is the only one.
- A variable whose every value is listed in 7.5 (qualifiers, M_ codes)
  has all its defined values in `special` and `max` = the highest one;
  spare values are not listed. Where spare values sit between defined
  ones (M_MODETEXTDISPLAY), `resolution` says so.
- Bitsets (M_LINEGAUGE, M_LINEAXLELOADCAT, NC_TRAIN, Q_MARQSTREASON) and
  BCD numbers (NID_MN, NID_OPERATIONAL, NID_RADIO) describe their coding
  in `resolution`; they have no `special` except NID_RADIO's all-F value.
- `bits` is 1 .. 32 except NID_RADIO, 64 bits (BCD, 16 digits, 7.5.1.95):
  the generator has to read it as two 32-bit halves or as a 64-bit
  modular type. Its special value 2**64 - 1 is a TOML key (a string), so
  it does not overflow a 64-bit TOML integer.
- `special` may be written as a sub-table `[variables.NAME.special]`
  (TOML inline tables cannot span lines).
- NID_LRBG, NID_PRVLRBG and NID_LTRBG (7.5.1.90, 7.5.1.94, 7.5.1.90.1)
  have no entry; a comment in the file marks their place.

## Packets

```toml
[[packets]]
nid = 5                      # NID_PACKET
name = "Linking"             # the SRS title without "Packet Number n:"
clause = "7.4.2.2"
direction = "track_to_train" # track_to_train | train_to_track
sent_by = ["balise", "rbc", "loop", "riu"]   # from "Transmitted by/to"
fields = [
  { var = "NID_PACKET" },
  { var = "Q_DIR" },
  { var = "L_PACKET" },
  { var = "Q_SCALE" },
  { var = "D_LINK" },
  { var = "Q_NEWCOUNTRY" },
  { if = "Q_NEWCOUNTRY == 1", fields = [ { var = "NID_C" } ] },
  { var = "NID_BG" },
  { var = "Q_LINKORIENTATION" },
  { var = "Q_LINKREACTION" },
  { var = "Q_LOCACC" },
  { var = "N_ITER" },
  { loop = "N_ITER", fields = [
      { var = "D_LINK" },
      { var = "Q_NEWCOUNTRY" },
      { if = "Q_NEWCOUNTRY == 1", fields = [ { var = "NID_C" } ] },
      { var = "NID_BG" },
      { var = "Q_LINKORIENTATION" },
      { var = "Q_LINKREACTION" },
      { var = "Q_LOCACC" },
  ] },
]
```

Field kinds:

- `{ var = "NAME" }` — one variable, read with its `bits`. `{ var =
  "NAME", as = "OTHER" }` names the record component differently when the
  same variable occurs twice at one level (the SRS `(k)` and `(n)`
  suffixes are *not* written: the loop gives the index).
- `{ if = "COND", fields = [...] }` — the fields are present when COND
  holds. COND is `VAR op VALUE` with op in `==`, `!=`, `<`, `<=`, `>`,
  `>=`, or `VAR in [v1, v2]`, VAR being a variable already read in this
  packet at this level or an enclosing one (the most recent occurrence).
  An SRS comment such as "If Q_INTEGRITY = 'confirmed by ...'" becomes the
  numeric values of 7.5.
- `{ loop = "VAR", fields = [...] }` — the fields repeat VAR times (VAR is
  `N_ITER`, `L_TEXT`, ... already read). A loop nested in a loop is
  allowed; the generator bounds the arrays with the variable's `max`.
- `{ raw = "VAR" }` — a bit string kept as bytes (`Raw_Bits` and `Raw`
  in the record): `raw = "L_PACKET"` is the rest of the packet (packet
  44's application data), any other VAR gives the length in bits.

Every packet starts with `NID_PACKET` and (track to train) `Q_DIR`, then
`L_PACKET`; the generator checks that. Packet 255 has `NID_PACKET` only.
Track-to-train packet 0 (Virtual Balise Cover marker) is `NID_PACKET`,
`NID_VBCMK` only: 7.3.3.5 exempts it from the header.

Clarifications (as the catalogue is written):

- A record level is the packet or a loop body. The fields of an `if` are
  components of the enclosing record, so the same variable in two `if`
  blocks of one record level (packet 3: M_NVKVINT, unconditional then
  "Only if Q_NVKVINTSET = 1") needs `as`. `as` names are the variable name
  with `_2`, `_3`, ... in reading order; train-to-track packet 1 names its
  second balise group `NID_C_PRVLRBG`, `NID_BG_PRVLRBG`.
- COND names the SRS variable, not an `as` name, and means its most recent
  occurrence read before the condition at this record level or an
  enclosing one. What an `if` block reads is visible only inside it.
- Two `if` blocks in a row may test the same variable (packets 51, 52,
  68, 69, 70: `Q_TRACKINIT == 1` then `Q_TRACKINIT == 0`, the second one
  holding the rest of the packet, "... and the following variables
  follow").
- Where the SRS indents a row without a comment (packets 12 and 15:
  T_SECTIONTIMER under Q_SECTIONTIMER, ...), the condition is the value
  of the qualifier that 7.5 defines as "... information to follow".
- `{ raw = "L_PACKET" }` is the rest of the packet: L_PACKET minus the
  bits read so far (packet 44 in both directions, "Other data depending
  on NID_XUSER").
- `{ loop = "L_TEXT", fields = [ { var = "X_TEXT" } ] }` is the SRS
  `X_TEXT(L_TEXT)` of packet 73.
- For train-to-track packets `sent_by` lists the "Transmitted to" row
  (the receivers, `rbc`, `riu`). "Any" is all four senders.
- `check_catalogue.py` checks all of the above and compares every packet
  with the markdown table; run it after every change.

## Messages

The radio messages of 8.6 (train to track) and 8.7 (track to train).
The codec writes the message list by hand for now (`etcs_messages.ads`);
the generator reads this section in a later round.

```toml
[[messages]]
nid = 4                      # NID_MESSAGE
name = "SM Authorisation"    # the SRS title without "Message n:"
clause = "8.7.2.1"
direction = "track_to_train" # 8.7 track_to_train, 8.6 train_to_track
sent_by = ["rbc"]            # 8.5.3 "Transmitted by" / 8.5.2 "Transmitted to"
fields = [                   # header of 8.4.4.6.1 / 8.4.4.7.1, then the
  { var = "NID_MESSAGE" },   # message variables of the table, in order
  { var = "L_MESSAGE" },
  { var = "T_TRAIN" },
  { var = "M_ACK" },
  { var = "NID_C" },         # NID_LRBG = NID_C + NID_BG
  { var = "NID_BG" },
  { var = "T_TRAIN", as = "T_TRAIN_2" },  # time stamp of the SM request
  { var = "Q_SCALE" },
  { var = "D_REF" },
  { var = "V_SM" },
]
packets = [
  { nid = 15 },              # mandatory packets, in the order of the table
  { nid = 21 },
  { nid = 27 },
  { nid = 3, optional = true },
  { nid = 65, optional = true, repeat = true },
  # ...
]
```

- `fields` uses the field kinds of packets (`var`, `as`, `if`, `loop`);
  the messages of 4.0.0 need only `var` and `as`. Track to train the
  header is NID_MESSAGE, L_MESSAGE, T_TRAIN, M_ACK, NID_LRBG (as NID_C,
  NID_BG); train to track NID_MESSAGE, L_MESSAGE, T_TRAIN, NID_ENGINE.
  Message 38 has no NID_LRBG: its table in 8.7.16 has four fields.
  Distances in message variables (D_REF, D_SR, ...) use the message's
  Q_SCALE.
- `packets` lists the packets of the message's direction: first the
  mandatory ones in the order of the message table (8.4.1.2), then the
  optional ones of 8.4.4.4 (the common optional packets of 8.4.4.4.1.1
  written out), which may come in any order (8.4.1.3).
  - `{ nid = N }` — packet N, mandatory.
  - `{ one_of = [0, 1] }` — exactly one of these packets: the position
    report of train-to-track messages ("Packet 0 or 1", absent from 146,
    154, 155, 156 and 159 by 8.4.4.7.2).
  - `optional = true` — the packet may be absent.
  - `repeat = true` — several instances allowed (8.4.1.4.1 to 8.4.1.4.5:
    44, 65, 66, 88 track to train; 8.4.1.5.1: 44 train to track). Without
    it a track-to-train message has at most one instance per packet and
    Q_DIR (8.4.1.4), a train-to-track message at most one (8.4.1.5).
  - `from = ["riu"]` — only when the message comes from that sender
    (message 24: from RBC 21, 27 and the common optional packets, from
    RIU 44, 45, 143, 180, 254).
- Padding to a whole byte (8.4.4.5) is not written.

## What the generator produces

- `etcs_variables.ads`: enumeration `Variable_T`, `Bits (V)`, `Max (V)`,
  the special values as named constants, all Pure, SPARK.
- One package per packet (`ETCS_Track_Packets.P<n>`,
  `ETCS_Train_Packets.P<n>`) with a record type `Packet_T`, a component
  per field (a loop as `<first component>_List`, a bounded array of
  `<first component>_Item` or of the scalar for a one-variable loop, with
  a count; an `if` block as components of the enclosing record plus a
  `Has_<first component>` Boolean), `Decode (Reader, Packet, OK)` and
  `Encode (Packet, Writer, OK)` in SPARK; `Decode` never raises, fails on
  a truncated or inconsistent packet (L_PACKET not matching what was
  read), and consumes exactly L_PACKET bits on success. Each variable is
  a range type `<V>_T` (two's complement when `min < 0`, `Unsigned_64`
  for 64 bits) with `To_<V>`, `Code` and `Is_Valid` (min .. max or a
  special value). The combined NID_LRBG is
  `ETCS_Variables.Balise_Group_Identity (NID_C, NID_BG)`, not a record
  component.
- The catalogues: `ETCS_Catalogue` (`NID_PACKET` to `Packet_Kind_T`,
  direction, clause, `Check`, `Skip`) and `ETCS_Message_Catalogue` from
  the `[[messages]]` section (fields with the header, the packet rules).
  The framing of telegrams (8.4.2) and radio messages (8.4.4) is written
  by hand in `ETCS_Telegram` and `ETCS_Message` on top of them, and
  `ETCS_Packet_Index` scans one packet.
- `test/src/etcs_language_random.ad[sb]` (host only): random valid
  packets for the round trip tests.

## Rules

- Every packet and variable cites its clause and was read on the PDF
  page, not only in the markdown.
- The language is the one of SRS 4.0.0, which 7.5.1.79 gives as system
  versions 2.0 to 2.3 and 3.0 (M_VERSION codes 32 to 35 and 48; 49 to
  63 are reserved and valid). The codec accepts those and rejects
  versions 0.x and 1.x, whose differences (chapter 6) are phase E7 and
  not in this file.
- Packets of chapter 7 that the plan puts out of scope (NTC: 44 stays in
  as raw data; STM packets of SUBSET-035 are not here) are still
  described when SUBSET-026 defines them, so that a telegram carrying
  them is decoded and the packet skipped knowingly.
