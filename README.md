# LRAHash
On-going project for LRAHash.

## Microarchitecture

The baseline version contains 128KB on-chip SRAM in each processing element. The
routing network adopts the state-of-the-art wormhole flow control.

There are 4-pipeline stage associated with each NoC router:
- Routing Computation (RC)
- Switch Allocation (SA)
- Switch Traversal (ST)
- Link Traversal (LT)

The datapath of each processing element contains 5-pipeline stages:
- Address Computation (AC)
- Memory Access (MEM)
- Multiplication (MULT)
- Addition (ADD)
- Write Back (WB)

The code (behavior-level and post-syn level) is verified against the golden
vectors exported from MATLAB.
