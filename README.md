# LRAHash
On-going project for LRAHash.

## Microarchitecture

The baseline version contains 128KB on-chip SRAM in each processing element. The
routing network adopts the state-of-the-art wormhole flow control. (Note: since
the packet is relatively simple, consists of 1-flit, the flow control can also
be regarded as the store-and-forward/cut-through).

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

## Revision History
- 2017.8.15: Split buffer in the input unit of NoC router architecture. It can
  resolve the additional bubble caused by the back-to-back packet stall. The
  execution cycle of short and fat matrix can be reduced by twice.
