# **ANNEX B. (INFORMATIVE) CBC-MAC CALCULATION**

B.1.1.1 Assume a message _m_ (21 octets) with the following structure in hex notation:

```
00 01 02 03 04 05 06 07
08 09 0A 0B 0C 0D 0E 0F
10 11 12 13 14 .. .. ..
```

B.1.1.2 Because it is not a multiple of 64 bits, _m_ must be padded with zero bits before MAC calculation as follows:

B.1.1.3 A 192 bit triple key is required for MAC calculation, consisting of three 64-bit DES keys (K1, K2, K3). Although not used by the DES algorithm, the key should be as defined by [ANSI], where each eighth bit (the LSB of each octet) is defined as an odd-parity bit.

B.1.1.4 In practice, the triple key to be used to calculate a MAC is the Session Key KsMAC, derived during session establishment (AU1 and AU2) from the KMAC. This example assumes that KsMAC has been generated, so the DES keys referred to below are already parts of the session key.

B.1.1.5 The first DES key (K1, bits b0 to b63 of KsMAC) is:

```
MSB             LSB  hex
b0  - b7 : 0 0 0 0  0 0 0  1    01
b8  - b15: 0 0 0 0  0 0 1  0    02
b16 - b23: 0 0 0 0  0 1 0  0    04
b24 - b31: 0 0 0 0  0 1 1  1    07
b32 - b39: 0 0 0 0  1 0 0  0    08
b40 - b47: 0 0 0 0  1 0 1  1    0B
b48 - b55: 0 0 0 0  1 1 0  1    0D
b56 - b63: 0 0 0 0  1 1 1  0    0E
```

B.1.1.6 The structure of the DES key is defined as follows, with the greatest-weight bit being b0, b8, b16 ..., and each parity bit being b7, b15, b23 (where '|' is the concatenation operator).

```
b0      b7  b8
v       v   v
0000 0001 | 0000 0010 | 0000 0100 | 0000 0111 | 0000 1000 |
 0000 1011 | 0000 1101 | 0000 1110
 ^
b63
```

or in hex notation: K1 = `01 | 02 | 04 | 07 | 08 | 0B | 0D | 0E`

<!-- end of page 51 -->

B.1.1.7 The second DES key (K2, bits b64 to b127 of KsMAC) is:

`MSB           LSB   hex`

`0 0 0 1  0 0 0  0   1 0`

`0 0 0 1  0 0 1  1   1 3`

`0 0 0 1  0 1 0  1   1 5`

`0 0 0 1  0 1 1  0   1 6`

`0 0 0 1  1 0 0  1   1 9`

`0 0 0 1  1 0 1  0   1 A`

`0 0 0 1  1 1 0  0   1 C`

`0 0 0 1  1 1 1  1   1 F`

B.1.1.8 The third DES key (K3, bits b128 to b191 of KsMAC) is:

`MSB           LSB   hex`

`0 0 1 0  0 0 0  0   2 0`

`0 0 1 0  0 0 1  1   2 3`

`0 0 1 0  0 1 0  1   2 5`

`0 0 1 0  0 1 1  0   2 6`

`0 0 1 0  1 0 0  1   2 9`

`0 0 1 0  1 0 1  0   2 A`

`0 0 1 0  1 1 0  0   2 C`

`0 0 1 0  1 1 1  1   2 F`

B.1.1.9 The triple key KsMAC, consisting of the three DES keys K1 | K2 | K3, is therefore: `01 02 04 07 08 0B 0D 0E | 10 13 15 16 19 1A 1C 1F | 20 23 25 26 29 2A 2C 2F`

B.1.1.10 To calculate a CBC-MAC for message _m_ :

1. The DEA input register is initialised with the first 8 octets of the message, and the first DES key is used to encrypt and produce 8 octets of ciphertext output.

```
message block 1:  00 01 02 03 04 05 06 07
DES key K1:  01 02 04 07 08 0B 0D 0E
```

```
> ciphertext1: 0C 61 B5 50 4B 5C FC 5C
```

[Note that since a message block XOR'd with an initialisation vector of 0 is unchanged, it is an implementation matter whether it is done or not.]

2. Ciphertext1 is then exclusive-or'd with message block 2:

```
message block 2:  08 09 0A 0B 0C 0D 0E 0F
ciphertext1: 0C 61 B5 50 4B 5C FC 5C
> XOR2: 04 68 BF 5B 47 51 F2 53
```

3. XOR2 is now the next input to the DES algorithm, encrypting again with DES key K1:

```
XOR2:  04 68 BF 5B 47 51 F2 53
DES key K1:  01 02 04 07 08 0B 0D 0E
> ciphertext2: E0 13 56 59 5B 86 75 31
```

<!-- end of page 52 -->

4. The process is repeated for the last message block: ciphertext2 is exclusive-or'd with message block 3 (containing the padding):

```
message block 3:  10 11 12 13 14 00 00 00
ciphertext2: E0 13 56 59 5B 86 75 31
> XOR3: F0 02 44 4A 4F 86 75 31
```

5. XOR3 is now the next input to the DES algorithm, again encrypting with DES key K1:

```
XOR3:  F0 02 44 4A 4F 86 75 31
DES key K1:  01 02 04 07 08 0B 0D 0E
> ciphertext3: DF 5E BC 63 95 68 0A 93
```

6. So far, the process has been normal single DES. Now it must be processed with modified MAC algorithm 3, that is, ciphertext3 is decrypted with DES key K2:

```
ciphertext3: DF 5E BC 63 95 68 0A 93
DES key K2:  10 13 15 16 19 1A 1C 1F
> ciphertext4: A1 3B 20 90 B5 D5 3D F0
```

7. Then encrypted with DES key K3:

```
ciphertext4: A1 3B 20 90 B5 D5 3D F0
DES key K3:  20 23 25 26 29 2A 2C 2F
> CBC-MAC:  36 1D 43 1E D3 96 C1 75
```

B.1.1.11 The resulting output is the required 8-octet CBC-MAC of message _m_ . Note that the message is not changed by the above process, i.e., the padding is added only for the MAC calculation and is not transmitted.

Note also that this example is generic, i.e., it excludes the process where transmitter and receiver add the destination ETCS identity ( _DA_ ) and length of _DA_ | _m_ for the MAC calculation, but remove them before use, as described above in 6.2.2.9.

<!-- end of page 53 -->
