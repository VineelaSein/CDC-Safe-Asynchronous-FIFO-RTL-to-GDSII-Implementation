// =============================================================================
// Module      : sync2ff
// Description : Standard 2-flip-flop synchronizer. Passes a signal from
//               a foreign clock domain into this domain safely.
//
//               The FIRST flip-flop is the one that might catch the input
//               mid-transition and go metastable for a moment. The SECOND
//               flip-flop samples the first one's output one full clock
//               cycle later - by then, metastability has almost always
//               resolved, so what comes out of the second flop is safe
//               to use anywhere in this clock domain.
//
//               This does NOT make the value glitch-free instantly - it
//               costs 2 clock cycles of latency to cross domains safely.
//               That's the price of safety, and it's why async FIFOs need
//               careful full/empty logic that accounts for this delay.
// =============================================================================

module sync2ff #(
    parameter WIDTH = 5
)(
    input  wire             clk,      // the RECEIVING domain's clock
    input  wire             rstn,
    input  wire [WIDTH-1:0] async_in, // signal coming from the OTHER clock domain
    output reg  [WIDTH-1:0] sync_out  // safe to use in this clock domain
);

    reg [WIDTH-1:0] stage1; // may go metastable - never used directly elsewhere

    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            stage1   <= {WIDTH{1'b0}};
            sync_out <= {WIDTH{1'b0}};
        end else begin
            stage1   <= async_in; // 1st flop: catches the crossing signal
            sync_out <= stage1;   // 2nd flop: samples the (now-settled) 1st flop
        end
    end

endmodule
