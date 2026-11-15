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
spare = [9, 10, "18..31"]    # spare values within min .. max
bcd = true                   # binary coded decimal
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
  the spare values above it are not listed.
- `spare` lists the spare values that `min`, `max` and `special` cannot
  express: those between defined values (M_MODETEXTDISPLAY 9, 10, 11,
  13), the "not valid" codes of M_VERSION, and the spare codes of a
  bitset (M_LINEGAUGE: 0 and every code with one of the bits 4 .. 7).
  An item is a raw value (an integer) or an inclusive range of raw
  values written as a string `"a..b"`. The items lie within the width
  and within `min` .. `max` (above `max` is spare already), hold no
  special value and do not overlap. A spare value is not valid
  (3.16.1.1.1).
- `bcd = true`: the variable is a number in binary coded decimal of
  `bits / 4` digits (NID_MN 7.5.1.91.1, NID_OPERATIONAL 7.5.1.92,
  NID_RADIO 7.5.1.95): every digit is 0 .. 9, the number is entered
  left adjusted and the special character F fills the digits after its
  last one; a digit A .. E ("Not Used", "Spare") or a digit after an F
  is not valid. A number of no digit (all F) is valid unless `spare`
  lists it (NID_OPERATIONAL: FFFF FFFF spare) or it is a special value
  (NID_RADIO: FFFF FFFF FFFF FFFF, the short number stored on-board).
  `bcd` needs an unsigned variable whose `bits` is a multiple of 4.
- The bitsets describe their coding in `resolution` as well (M_LINEGAUGE,
  M_LINEAXLELOADCAT, NC_TRAIN with `spare`; every code of Q_MARQSTREASON
  is a value).
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
# invariant = true           # 8.5.2 / 8.5.3 "Invariant" Yes (optional,
                             # false when absent): ETCS_Message_Catalogue.Invariant
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

## Older system versions

Chapter 6 (6.5.1.5, 6.5.1.6 for X = 1; 6.5.2.3 for X = 2) replaces some
tables of chapters 7 and 8 for the system versions before 3.0. The
versions are written as the strings `"1.0"`, `"1.1"`, `"2.0"`, `"2.1"`,
`"2.2"`, `"2.3"` (M_VERSION 16, 17, 32 .. 35); 3.0 is the language of
the entries without `versions`. Every entry of 4.0.0 stays as it is: a
packet, message or variable without the key has the one layout of
4.0.0, which is also that of every older version that chapter 6 does
not change.

```toml
[[packets]]                  # a layout of older versions
nid = 80
name = "Mode profile"
clause = "6.5.1.5.18"        # the clause of chapter 6 that gives it
versions = ["1.0", "1.1"]    # the versions it applies to
# table = "7.4.2.23"         # optional: the table its fields follow when
                             # chapter 6 gives none (6.5.2.3.1.1.2: packet
                             # 72 of 2.0, 2.1 is the table of packet 73)
direction = "track_to_train"
sent_by = ["balise", "loop", "rbc", "riu"]   # its "Transmitted by"
fields = [ ... ]             # the full field list as chapter 6 prints it

[[variables.M_MODE.layouts]] # a variable of another width in some versions
versions = ["1.0", "1.1", "2.0", "2.1"]
bits = 4
clause = "6.5.2.3.2.4"
max = 15                     # the keys of a variable, all written out:
[variables.M_MODE.layouts.special]   # nothing is taken from 4.0.0
0 = "Full Supervision"

[variables.M_AXLELOAD]       # a variable that exists only in older versions
versions = ["1.0", "1.1"]
bits = 7
clause = "6.5.1.5.27"

[[packet_lists]]             # a list of chapter 6 replacing 7.4.1.1 / 7.4.1.2
versions = ["1.0", "1.1"]
direction = "track_to_train"
clause = "6.5.1.5.2"
nids = [2, 3, 5, ...]
```

- A packet entry with `versions` is a layout of those versions; the
  layouts of one packet number and direction hold disjoint versions.
  Its fields read, for each variable, the variable's layout whose
  `versions` hold all of the entry's (a layout holding only some of
  them is an error when the entry reads the variable), else the
  variable itself. A packet that exists only in older versions (72,
  76, 200, 203, 206, 207, 239, 245, train to track 3) is such an entry
  with no entry of 4.0.0 beside it.
- A variable with `versions` exists only in those versions: an entry of
  4.0.0 cannot read it. `layouts` belongs to a variable of 4.0.0.
- The layouts are made for the fields and the widths. A variable whose
  width is that of 4.0.0 keeps the values of 4.0.0 in an older layout,
  even where chapter 6 replaces its table (M_LEVELTEXTDISPLAY,
  M_LEVELTR, M_ERROR, NC_TRAIN, ...): a layout decodes the raw value,
  and what the value means in the older version, a code spare in 4.0.0
  included, is a rule of the reader of the layout, not of this file.
  A layout of a variable carries the table of its clause; where two
  versions share a width and their tables differ, one layout serves
  both and its comment says which table it carries (M_MODE of 4 bits:
  the 16 codes of 2.0, 15 being spare in 1.0, 1.1).
- `packet_lists` gives the packets of a version and direction (track
  to train by the version of the telegram or of the RBC / RIU, train to
  track by that of the RBC / RIU). Every packet listed has a layout in
  the version (its own or that of 4.0.0) and every layout's packet is
  listed; a version without a list of a direction has every packet of
  4.0.0 and its own layouts.
- Names: the layout of the lowest version of `versions` names it,
  `ETCS_Track_Packets.P80_V1_0` (packet 80 of 1.0, 1.1; file
  `etcs_track_packets-p80_v1_0.ads`), `P45_V2_0` (2.0 .. 2.3), the
  variable `M_MODE_V1_0` (its type `M_MODE_V1_0_T`, a literal of
  `Variable_T`). A layout is a child of the packets' parent like the
  packet of 4.0.0, so it sees the same types and has the same Decode,
  Encode and Valid; its record type is its own `Packet_T`.
- `check_catalogue.py` compares every layout with the table of its
  clause (or `table`) in chapter 6 as it compares chapter 7, requires
  every packet table of chapter 6 to be a layout or to equal the packet
  of 4.0.0, the packet lists to equal those of chapter 6, and the width
  of every variable table of chapter 6 to be that of the variable, of
  one of its layouts or of the variable of older versions under that
  clause.

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
  read), and consumes exactly L_PACKET bits on success; it is
  structural: `Valid (P)` of the package is the conjunction of
  `Is_Valid` of every variable read (those of the conditional blocks
  present, of the loop items within the count), in SPARK. Each variable
  is a range type `<V>_T` (two's complement when `min < 0`,
  `Unsigned_64` for 64 bits) with `To_<V>`, `Code` and `Is_Valid` (min
  .. max or a special value, not a `spare` one, a BCD number where
  `bcd`: `Valid_BCD`). `Valid_Code (Var, Code)` is `Is_Valid` of any
  variable from its code (the message variables). The combined NID_LRBG
  is `ETCS_Variables.Balise_Group_Identity (NID_C, NID_BG)`, not a
  record component.
- The catalogues: `ETCS_Catalogue` (`NID_PACKET` to `Packet_Kind_T`,
  direction, clause, senders, `Check`: decodes and says whether the
  packet is `Valid`, `Skip`) and `ETCS_Message_Catalogue` from
  the `[[messages]]` section (fields with the header, the packet rules).
  `ETCS_Catalogue` also has the layouts by version: `Layout_T`
  (`Not_In_Version`, `Current` for the layout of 4.0.0, then one literal
  per layout of older versions, `Old_Layout_T`), `Layout (Direction,
  NID, Version)` with the M_VERSION code, `NID_Of_Layout`,
  `Direction_Of_Layout`, `Layout_Name`, `Layout_Clause` and
  `Check_Layout`.
  The framing of telegrams (8.4.2) and radio messages (8.4.4) is written
  by hand in `ETCS_Telegram` and `ETCS_Message` on top of them, and
  `ETCS_Packet_Index` scans one packet.
- `test/src/etcs_language_random.ad[sb]` (host only): random valid
  packets for the round trip tests (no spare value: a `spare` variable
  is drawn until `Valid_Code`, a `bcd` one digit by digit); a round
  trip also checks that the decoded packet is `Valid`.

## Rules

- Every packet and variable cites its clause and was read on the PDF
  page, not only in the markdown.
- The language is the one of SRS 4.0.0, which 7.5.1.79 gives as system
  versions 2.0 to 2.3 and 3.0 (M_VERSION codes 32 to 35 and 48; 49 to
  63 are reserved and valid). The entries without `versions` are that
  language; the layouts of chapter 6 for the versions 1.0 .. 2.3 are
  entries with `versions` (see "Older system versions"). `ETCS_Telegram`
  and `ETCS_Message` (written) still read every telegram and message in
  the layouts of 4.0.0 and refuse the versions 0.x and 1.x.
- Packets of chapter 7 that the plan puts out of scope (NTC: 44 stays in
  as raw data; STM packets of SUBSET-035 are not here) are still
  described when SUBSET-026 defines them, so that a telegram carrying
  them is decoded and the packet skipped knowingly.
