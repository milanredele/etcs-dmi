# **Annex A (Informative), Additional technical information**

# **A1 Coding background**

## **A1.1 Encoding**

### **A1.1.1 General**

Encoding is done as follows:

1. Choose the 12 scrambling bits.

2. Scramble the data bits (in a way that depends on the scrambling bits).

3. Transform the scrambled data by blocks of 10 bits, thereby expanding each block to an 11-bit word.

4. Check the shaping constraints, as far as possible, on the information bits.  If they are not satisfied, go to 1.

5. Choose the 10 extra shaping bits (if all 2<sup>10</sup> combinations are exhausted, go to 1).

6. Form the check bits.

7. Check the shaping constraints.  If the telegram passes, stop.  Otherwise, go to 5.

These steps are described in sub-clause 4.3.2 on page 37.

The testing in step 4 is not necessary from a purely logical viewpoint.  All the testing could be done in step 7. For efficiency reasons, however, it is preferable to reject candidate telegrams as soon as possible, and to have the “inner loop” 5-6-7 that changes only the extra shaping bits.

The general idea behind the format is as follows.  Every telegram is a code word in a cyclic code that provides ample protection against random bit errors and burst errors.  The 10-to-11-bit transformation improves the protection against bit slips and insertions and excludes long runs of consecutive zeros or consecutive ones.  The testing of the candidate telegrams (steps 4 and 7) excludes telegrams that are potentially vulnerable to bit slips and also excludes long telegrams with bit patterns too “close” to a short telegram.  The scrambling makes sure that, for given user data, sufficiently many alternative candidate telegrams can be formed so that one of them eventually passes the final test.

The advantage of this probabilistic encoding scheme, with repeated encoding attempts, is that certain properties that are required for a rigorous safety proof are easy to test for any given candidate telegram but are very difficult to ensure by a deterministic encoding procedure (unless a significant number of information bits is sacrificed).  However, it is theoretically possible that certain user data cannot be encoded because the shaping bits are exhausted before any candidate telegram passes all tests.  The probability of this is very low (less than 10<sup>-100</sup> for random data).  If it should ever happen, a slight change in the user data (such as, e.g., a decrease of the speed limit by 1 km/h) will suffice to make the data encodable.  It should also be pointed out that the number of candidate telegrams that must be generated before one is found acceptable can be quite large.  In contrast, the receiver is comparatively simple and fast.

<!-- end of page 133 -->

### **A1.1.2 Comment to the 10-to-11-Bit Transformation**

The transformation serves several purposes.  First, it does “run length shaping”.  The length of the longest run of consecutive zeros or ones is at most 8.  This follows from the fact that none of the following 250 words are valid:

00000xxxxxx, xxxxxx00000, 10000000001,

11111xxxxxx, xxxxxx11111, 01111111110.

Secondly, since none of the following 20 words are valid, a shift of up to 4 positions between the extra bits (see sub-clauses 4.3.4.2 (page 41), 4.3.4.3 (page 41), 4.3.4.4 (page 42), and sub-clause A1.1.1 of this Annex), and the corresponding first bits within the considered window can be detected by the receiver:

01010101010, 10101010101,

00100100100, 01001001001, 10010010010,

11011011011, 10110110110, 01101101101,

- 00010001000, 00100010001, 01000100010, 10001000100, 00110011001, 01100110011,

11101110111, 11011101110, 10111011101, 01110111011, 11001100110, 10011001100.

Thirdly, the alphabet was chosen (by empirical search) to support the Off-Synch-Parsing Condition of subclause 4.3.2.5.3 on page 40.  In particular, shifting any valid word by one position, to the left or to the right, with an arbitrary “new” bit, is unlikely to produce a valid word.  Of all words that can be obtained from shifting a valid word to the left, with an arbitrary new bit, only 316 are valid.  Of all right shifts, only 324 words are valid.

Finally, the alphabet is transparent to inversion.  Inverting all bits of a valid word results in another valid word.

## **A1.2 Decoding**

### **A1.2.1 Synchronisation**

Let v = [vn-1, ..., v0] be a length-n block of the bit stream emitted by the Balise (for the long and short format, n=1023 and n=341, respectively).  The block v is a cyclically shifted version of the transmitted telegram, as illustrated in Fig. 3.  In polynomial notation, v(x) = Rx<sup>n</sup> -1[xs·b(x)], where b = [bn-1, ..., b0] is the transmitted telegram and where the integer s is the number of bits elapsed since the beginning of the telegram, see Figure 52.

<!-- Start of picture text -->
• • • bn-1 bn-2 • • • b0 bn-1 bn-2 • • •<br>s<br>vn-1 • • • v1 v0<br><!-- End of picture text -->

**Figure 52:  The received data in a length-n window**

<!-- end of page 134 -->

To determine the value of s, 0  s<n, the syndrome s f (x) is computed as

### s f (x) = R f(x) [v(x)],

where f(x) = f L (x) for the long format and f(x) = f S (x) for the short format. It can be shown that

s f (x) = R f(x) [x<sup>s</sup> o(x)], (A-2)

with o(x) = g(x) as in sub-clause 4.3.2.4 on page 39.  Furthermore, the value of s f (x) uniquely determines the value of s and thus allows synchronisation.  Finally, it can be shown (by noting that f(x) is not a multiple of x-1) that

which implies that the synchronisation is transparent with respect to the inversion of all bits.

For an error-free telegram, the value of (A-2) is never 0.  However, if v(x) is any length-n vector that is periodic with a period that divides n (but is less than n), it can be shown that

### R f(x) [v(x)] = 0. (A-4)

In particular, if a long-format receiver is given a repeated short telegram as input, the evaluation of (A-1) always results in s f (x)=0.

### **A1.2.2 Comments to the Receiver Operation**

The following comments apply to sub-clause 4.3.4.1 on page 41.

- To 1. The number of extra bits is larger for the short-format receiver to safely exclude long telegrams.  The purpose of setting r = n when 7500 bits have been examined without finding an error-free telegram is to obtain a fixed upper bound, per Balise passage, on the probability of an undetected error (for r as large as n, the probability of accepting a corrupted telegram is “zero”).  The specific number (7500) is somewhat arbitrary.

- To 2. “Shifting the window” is of course only possible as long as there are additional received bits available. The shifting may be done either by one or several bit positions at a time.

- To 3. Testing the extra bits serves several purposes.  For the short format, it guarantees the safe rejection of long telegrams.  For both formats, it is essential for the detection of bit slips and insertions.

- To 4. “Impossible” values: For the short format, only 341 (of 1024) values are possible with an error-free telegram.  In the long-format receiver, an error-free long telegram cannot produce R f(x) [v(x)] = 0, but a repeated error-free short telegram always produces R f(x) [v(x)] = 0.

- To 5. In a practical implementation, it is natural to combine this step with 9.  It is essential, however, that all words are tested, not only those in the shaped-data part of the telegram.

It is recommended that each receiver records how often it uses each of the different “go to 1” branches.  For example, it is conjectured that such branches other than from step 2 and (for a long-format receiver only) from step 4 occur extremely seldom.  Knowing such statistics from the receivers in operation would be valuable for future safety reviews.

<!-- end of page 135 -->

## **A1.3 Safety Considerations**

This is not part of the formal specification.  It outlines the deterministic protection that is guaranteed by the basic receiver.  Probabilistic aspects are not discussed.

### **A1.3.1 Introduction**

The telegram format and the basic receiver were designed together with a safety proof for an upper bound of 10<sup>-18</sup> for the probability, per Balise passage, of accepting a corrupt telegram.  The following hazards were considered:

- random bit errors;

- burst errors;

- bit slips and bit insertions, and all combinations thereof;

- potential problems with telegram change and format misinterpretation (long versus short telegrams);

- some further special error modes.

This safety proof is not reproduced here.

What _is_ given here is a brief discussion of the “rigid” or “deterministic” error detection capabilities of the basic receiver such as the minimum Hamming distance of the cyclic code or the maximum number of bit slips that are always detected.  Note, however, that a rigorous safety analysis cannot be based on such rigid properties alone. For example, the minimum distance is of little help in determining the probability of an undetected error for independent random bit errors that occur with a probability of 10<sup>-2</sup> .

Apart from the distinction between “rigid” (or “deterministic”) and probabilistic, a number of further distinctions are also important for any safety analysis.

**Engineering approximations versus mathematical proofs.** A simple-minded approach to error detection is to choose some code with m check bits and hope that the error probability stays below 2<sup>-m</sup> .  A sufficient safety factor is included for cases where this hope is not fulfilled.  The problem with this approach is to know how much is “sufficient”.  On the other extreme is a rigorous mathematical analysis with explicit upper bounds on the probability of an undetected error for all relevant error models.  Unfortunately, the latter approach is not always feasible.

**Uniform versus data-dependent protection.** The protection of a linear code (such as the cyclic code of the present format) against random bit errors and additive burst errors is independent of the user data.  All code words enjoy exactly the same protection.  On the other hand, the protection by the same code against bit slips depends strongly on the particular code word, with variations from “absolutely safe” to “essentially unprotected”.

**“Random” versus worst-case telegram.** In the average, over all possible telegrams, the protection against bit slips and insertions as provided by g(x) alone is excellent.  This gives little comfort, however, when one of the weak telegrams happens to be the standard message of a Balise outside the central station.  Any rigorous safety analysis therefore faces the possibility that the worst-case telegram is in use.  Similar worst-case considerations apply also to telegram change (see sub-clause A1.3.4 of this Annex) and format mixing (see sub-clause A1.3.5 of this Annex).

### **A1.3.2 Random Bit Errors and Burst Errors**

The cyclic codes determined by g(x) provide excellent protection against random bit errors and (additive) burst errors.  The minimum distance of the code for the long format is (at least) 15.  That of the short format is (at least) 17.  Less errors within the window are always detected by the basic receiver.

Any burst error of length at most 75 bits is also detected by the code.  Many combinations of shorter bursts are also guaranteed to be detected.  For example, any two bursts of length not exceeding 41 and 24, respectively, are always detected.

<!-- end of page 136 -->

### **A1.3.3 Bit Slips and Insertions**

Any combination of bit slips and insertions with a total of not more than 3 events within the window (length n+r) is always detected by the basic receiver (as with random bit errors, most cases with more events are also detected).

### **A1.3.4 Telegram Change**

We distinguish between two cases, depending on the position of the receiver’s length n+r window.  For the purpose of clarity, it is assumed that the transition is marked by (at least) 75 intermediate zeros.  The case of intermediate ones is analogous.

- **Case 1:** The window starts (or ends) within the transition and contains at most 75 bits from the transition.  In this case, at least n consecutive bits are not affected by the telegram change.  On these n bits, the full protection by the cyclic code applies.

- **Case 2:** The window overlaps the transition or contains more than 75 bits from the transition.  Consider 75 bits within the transition (in the absence of transmission errors, these 75 bits are either all zeros or all ones).  Whatever was received outside the 75 bits determines a unique code word; only _one_ 75-bit pattern can thus possibly be accepted by the receiver.  If that unique acceptable pattern has less than 13 ones, no error can occur because any such pattern is rejected by step 5 (checking valid words) of the receiver.  Therefore, any undetectable error pattern has at least 13 ones within these 75 bits.

### **A1.3.5 Format Mixing**

**Long telegram and short-format receiver.** The discrimination relies exclusively on testing the 121 extra bits. The Aperiodicity Condition (see sub-clause 4.3.2.5.4 on page 40) gives a Hamming distance of at least 15 if there are no bit slips, and a Hamming distance of at least 4 if there are up to 3 bit slips or insertions.

**Short telegram and long-format receiver.** A repeated short telegram is “almost” a valid long telegram: it satisfies the parity check with respect to the long format (see equation (4) of sub-clause 4.3.2.4 on page 39) as well as the Alphabet Condition, the Off-Synch-Parsing Condition, and the Under-sampling Condition of subclause 4.3.2.5 on page 39 (the last of these is actually not needed here).  The only two conditions that are not satisfied are the Aperiodicity Condition and the “impossible” synchronisation value s f (x)=0 (see equation (A-4) of sub-clause A1.2.1 of this Annex), neither of which has any safety role in the long-format receiver.  In other words, a repeated short telegram is treated and protected exactly like a long telegram, except that synchronisation fails because of the “impossible” synchronisation value s f (x)=0.

### **A1.3.6 Over-sampling and Under-sampling**

Over-sampling by a factor k is the process of repeating each bit k times.  Under-sampling was defined in subclause 4.3.2.5.5 on page 40.  Such events are unlikely to occur during normal operation but might be caused by defect hardware.  The reason for considering such error modes is that cyclic codes have a systematic weakness against over-sampling or under-sampling by a power of 2 (because a(x<sup>2</sup> )=a(x)<sup>2</sup> for any binary polynomial a(x)).

Over-sampling by a factor larger than 8 results in too long runs of zeros and ones that are detected by testing the Alphabet Condition.  Over-sampling by an even factor smaller than 8 is covered by the extra bits (which are shifted with respect to the corresponding first r bits in the telegram).

Under-sampling by a factor of 2, 4, 8, or 16 is covered by the Under-sampling Condition.  A large Hamming distance is not required in these cases because the under-sampled pattern is a code word in, and thus protected by, the cyclic code.

<!-- end of page 137 -->
