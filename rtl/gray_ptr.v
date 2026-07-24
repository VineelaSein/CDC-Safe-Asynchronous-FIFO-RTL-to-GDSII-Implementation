// =============================================================================
// Module      : gray_ptr
// Description : Maintains a pointer as both binary (used internally for
//               addressing memory and comparing full/empty) and Gray code
//               (used when this pointer needs to cross into the other clock
//               domain, since Gray code only ever changes one bit per step).
//
//               bin_ptr  : (WIDTH+1) bits - binary, used for addressing/compare
//               gray_ptr : (WIDTH+1) bits - Gray-coded version of bin_ptr
//
// Note: pointer width is WIDTH+1, one bit wider than needed to address
// 2^WIDTH memory locations. That extra MSB is the classic async-FIFO trick
// for distinguishing "completely full" from "completely empty" - both cases
// would otherwise look identical (read pointer == write pointer). More on
// this when we build the full/empty logic.
// =============================================================================

module gray_ptr #(
    parameter WIDTH = 4  // pointer covers 2^WIDTH FIFO depth
)(
    input  wire             clk,
    input  wire             rstn,
    input  wire             increment,
    output reg  [WIDTH:0]   bin_ptr,
    output reg  [WIDTH:0]   gray_ptr
);

    wire [WIDTH:0] bin_next  = bin_ptr + (increment ? 1'b1 : 1'b0);
    wire [WIDTH:0] gray_next = bin_next ^ (bin_next >> 1); // binary-to-Gray conversion

    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            bin_ptr  <= {(WIDTH+1){1'b0}};
            gray_ptr <= {(WIDTH+1){1'b0}};
        end else begin
            bin_ptr  <= bin_next;
            gray_ptr <= gray_next;
        end
    end

endmodule