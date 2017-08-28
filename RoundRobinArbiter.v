// =============================================================================
// Module name: RoundRobinArbiter
//
// The module takes an N-bit request, and issue one grant among the N-bit
// request. The priority is determined based on the round robin fashion. More
// specifically, the request that was just served should have the lowest
// priority on the next round of arbitration.
//
// Implementation notes:
// Section 18.4 of `Principles and Practices of Interconnection Networks`
// =============================================================================

module RoundRobinArbiter #(
  parameter                           N = 4         // bit number
) (
  input wire                          clk,          // system clock
  input wire                          rst,          // system reset
  input wire  [N-1:0]                 request,      // request
  output wire [N-1:0]                 grant         // grant
);

reg [N-1:0] p;
wire [N-1:0] p_next;

// --------------------
// prioirty registers
// --------------------
always @ (posedge clk or posedge rst) begin
  if (rst) begin
    p       <= 1;
  end else begin
    p       <= p_next;
  end
end
// Next logic: Refer to Fig. 18.6
assign p_next = (|grant) ? {grant[N-2:0], grant[N-1]} : p;

// -------------------------------
// PriorityArbiter Instantiation
// -------------------------------
PriorityArbiter # (
  .N            (N)           // bit number
) priority_arbiter (
  .request      (request),    // request
  .p            (p),          // priority (one-hot encoding)
  .grant        (grant)       // grant
);

endmodule
