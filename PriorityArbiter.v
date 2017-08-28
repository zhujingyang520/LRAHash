// =============================================================================
// Module name: PriorityArbiter
//
// The module accepts an N-bit request and generate an N-bit grant signal, which
// only grants one request among the N requests. The priority port indicates
// which port has the highest priority. (Priority port should be encoded in
// one-hot encoding)
//
// Implementation notes:
// Section 18.4 of `Principles and Practices of Interconnection Networks`
// =============================================================================

module PriorityArbiter # (
  parameter                           N = 4       // bit number
) (
  input wire  [N-1:0]                 request,    // request
  input wire  [N-1:0]                 p,          // priority (one-hot encoding)
  output wire [N-1:0]                 grant       // grant
);

`ifdef LOOP_IMPLEMENT
wire [N:0] carry;
genvar g;

generate
for (g = 0; g < N; g = g + 1) begin: gen_priority_arbiter_chain
  // logic equation in Section 18.4
  assign grant[g] = request[g] & (p[g] | carry[g]);
  assign carry[g+1] = (~request[g]) & (p[g] | carry[g]);
end
endgenerate
assign carry[0] = carry[N];
`else
// -----------------------------------------------------------------------------
// Implementation notes: Sometimes, the tool can not properly deal with the
// cyclic carry chain. Another PriorityArbiter is duplicated where the carry in
// of the first priority arbiter is connected to `0` and the second priority
// arbiter connects to the first one's carry out
// -----------------------------------------------------------------------------
genvar g;
// 1st priority arbiter
wire [N:0] carry_0;
wire [N-1:0] grant_0;
// 2nd priority arbiter
wire [N:0] carry_1;
wire [N-1:0] grant_1;

assign carry_0[0] = 1'b0;
assign carry_1[0] = carry_0[N];
generate
for (g = 0; g < N; g = g + 1) begin: gen_priority_arbiter_0
  assign grant_0[g] = request[g] & (p[g] | carry_0[g]);
  assign carry_0[g+1] = (~request[g]) & (p[g] | carry_0[g]);
end

for (g = 0; g < N; g = g + 1) begin: gen_priority_arbiter_1
  assign grant_1[g] = request[g] & (p[g] | carry_1[g]);
  assign carry_1[g+1] = (~request[g]) & (p[g] | carry_1[g]);
end
endgenerate

assign grant = grant_0 | grant_1;

`endif  // LOOP_IMPLEMENT


endmodule
