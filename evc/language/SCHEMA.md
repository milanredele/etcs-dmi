# The ERTMS/ETCS language as data

`etcs_language.toml` describes the variables (SUBSET-026 7.5) and the
packets (7.4) of the ERTMS/ETCS language, version 4.0.0. It is written by
hand from the PDF (the markdown loses the structure of the packet tables:
which fields belong to a loop or to a condition) and it is the single
source of the generated Ada under this directory (`gen_language.py`).
The generated files are checked in and carry a header naming the
generator; regenerating must give no diff.

## Variables

```toml
[variables.NID_PACKET]
bits = 8                     # length in bits, 1 .. 32
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
clause = "7.4.2.3"
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
- `{ raw = "VAR" }` — a bit string whose length in bits is the value of
  VAR read before (packet 44's application data, packet 8/... where the
  SRS says "data"); kept as bytes.

Every packet starts with `NID_PACKET` and (track to train) `Q_DIR`, then
`L_PACKET`; the generator checks that. Packet 255 has `NID_PACKET` only.

## What the generator produces

- `etcs_variables.ads`: enumeration `Variable_T`, `Bits (V)`, `Max (V)`,
  the special values as named constants, all Pure, SPARK.
- One record type per packet with a component per field (loops as
  bounded arrays with a count, conditionals as components plus a
  `Has_X` Boolean), `Decode (Reader, Packet, OK)` and `Encode (Packet,
  Writer, OK)` in SPARK; `Decode` never raises, fails on a truncated or
  inconsistent packet (L_PACKET not matching what was read), and
  consumes exactly L_PACKET bits on success.
- The catalogue: `NID_PACKET` to `Packet_Kind_T`, direction, the
  clause; the framing of telegrams (8.4.2) and radio messages (8.4.4) is
  written by hand in `etcs_telegram.ads` and `etcs_messages.ads` with the
  message list of 8.5 to 8.7 as data (which packets a message carries,
  optional or mandatory).

## Rules

- Every packet and variable cites its clause and was read on the PDF
  page, not only in the markdown.
- The version is 4.0.0 (M_VERSION 2.x). Chapter 6 differences for older
  versions are phase E7 and not in this file.
- Packets of chapter 7 that the plan puts out of scope (NTC: 44 stays in
  as raw data; STM packets of SUBSET-035 are not here) are still
  described when SUBSET-026 defines them, so that a telegram carrying
  them is decoded and the packet skipped knowingly.
