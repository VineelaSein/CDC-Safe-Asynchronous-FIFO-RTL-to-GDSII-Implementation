// =============================================================================
// Module      : async_fifo
// Description : CDC-safe asynchronous FIFO. Write side and read side run on
//               completely independent clocks (wclk, rclk) with no fixed
//               phase relationship. Built from three previously-verified
//               building blocks:
//                 - gray_ptr    : write and read pointers, Gray-coded
//                 - sync2ff     : safely crosses each pointer into the
//                                 OTHER domain (2-cycle latency, but safe)
//                 - dual_port_mem : the actual storage
// =============================================================================

module async_fifo #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 4
)(
    input  wire                    wclk,
    input  wire                    wrstn,
    input  wire                    wr_en,
    input  wire [DATA_WIDTH-1:0]   wr_data,
    output wire                    wfull,

    input  wire                    rclk,
    input  wire                    rrstn,
    input  wire                    rd_en,
    output wire [DATA_WIDTH-1:0]   rd_data,
    output wire                    rempty
);

    wire [ADDR_WIDTH:0] wptr_bin,  wptr_gray;
    wire [ADDR_WIDTH:0] rptr_bin,  rptr_gray;
    wire [ADDR_WIDTH:0] wptr_gray_in_rdomain;
    wire [ADDR_WIDTH:0] rptr_gray_in_wdomain;

    gray_ptr #(.WIDTH(ADDR_WIDTH)) u_wptr (
        .clk(wclk), .rstn(wrstn),
        .increment(wr_en & ~wfull),
        .bin_ptr(wptr_bin), .gray_ptr(wptr_gray)
    );

    gray_ptr #(.WIDTH(ADDR_WIDTH)) u_rptr (
        .clk(rclk), .rstn(rrstn),
        .increment(rd_en & ~rempty),
        .bin_ptr(rptr_bin), .gray_ptr(rptr_gray)
    );

    sync2ff #(.WIDTH(ADDR_WIDTH+1)) u_sync_wptr (
        .clk(rclk), .rstn(rrstn),
        .async_in(wptr_gray), .sync_out(wptr_gray_in_rdomain)
    );

    sync2ff #(.WIDTH(ADDR_WIDTH+1)) u_sync_rptr (
        .clk(wclk), .rstn(wrstn),
        .async_in(rptr_gray), .sync_out(rptr_gray_in_wdomain)
    );

    dual_port_mem #(.DATA_WIDTH(DATA_WIDTH), .ADDR_WIDTH(ADDR_WIDTH)) u_mem (
        .wclk(wclk), .wr_en(wr_en & ~wfull), .wr_addr(wptr_bin[ADDR_WIDTH-1:0]), .wr_data(wr_data),
        .rclk(rclk), .rd_addr(rptr_bin[ADDR_WIDTH-1:0]), .rd_data(rd_data)
    );

    assign rempty = (rptr_gray == wptr_gray_in_rdomain);

    assign wfull = (wptr_gray == {~rptr_gray_in_wdomain[ADDR_WIDTH:ADDR_WIDTH-1],
                                    rptr_gray_in_wdomain[ADDR_WIDTH-2:0]});

endmodule