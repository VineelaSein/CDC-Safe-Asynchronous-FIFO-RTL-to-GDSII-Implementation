// =============================================================================
// Module      : dual_port_mem
// Description : The FIFO's actual storage. Write port and read port are
//               completely independent - different clocks, different
//               addresses, at the same time if needed. This is standard
//               for FIFO memories and is what makes read-while-write safe
//               AS LONG AS the full/empty logic (built separately) prevents
//               reading empty slots or writing to a full FIFO.
// =============================================================================

module dual_port_mem #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 4   // depth = 2^ADDR_WIDTH
)(
    // write port
    input  wire                     wclk,
    input  wire                     wr_en,
    input  wire [ADDR_WIDTH-1:0]    wr_addr,
    input  wire [DATA_WIDTH-1:0]    wr_data,

    // read port
    input  wire                     rclk,
    input  wire [ADDR_WIDTH-1:0]    rd_addr,
    output reg  [DATA_WIDTH-1:0]    rd_data
);

    reg [DATA_WIDTH-1:0] mem [0:(1<<ADDR_WIDTH)-1];

    // Write port: synchronous write on wclk
    always @(posedge wclk) begin
        if (wr_en)
            mem[wr_addr] <= wr_data;
    end

    // Read port: synchronous read on rclk (registered output = 1 cycle latency,
    // but avoids read-during-write glitches and matches real SRAM behavior)
    always @(posedge rclk) begin
        rd_data <= mem[rd_addr];
    end

endmodule
