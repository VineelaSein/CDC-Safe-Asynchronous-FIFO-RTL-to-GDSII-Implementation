`timescale 1ns/1ps
module async_fifo_tb;
    parameter DATA_WIDTH = 8;
    parameter ADDR_WIDTH = 4; // depth = 16

    reg wclk = 0, rclk = 0;
    reg wrstn = 0, rrstn = 0;
    reg wr_en = 0, rd_en = 0;
    reg [DATA_WIDTH-1:0] wr_data;
    wire [DATA_WIDTH-1:0] rd_data;
    wire wfull, rempty;

    // Genuinely unrelated clocks: wclk period 10ns, rclk period 7ns
    always #5   wclk = ~wclk;
    always #3.5 rclk = ~rclk;

    async_fifo #(.DATA_WIDTH(DATA_WIDTH), .ADDR_WIDTH(ADDR_WIDTH)) dut (
        .wclk(wclk), .wrstn(wrstn), .wr_en(wr_en), .wr_data(wr_data), .wfull(wfull),
        .rclk(rclk), .rrstn(rrstn), .rd_en(rd_en), .rd_data(rd_data), .rempty(rempty)
    );

    integer i, errors;
    reg [DATA_WIDTH-1:0] expected_q [0:31];
    integer wr_count, rd_count;

    initial begin
        $dumpfile("sim/async_fifo.vcd");
        $dumpvars(0, async_fifo_tb);

        errors = 0; wr_count = 0; rd_count = 0;
        wr_en = 0; rd_en = 0; wr_data = 0;
        wrstn = 0; rrstn = 0;
        repeat (4) @(posedge wclk);
        wrstn = 1; rrstn = 1;

        // ---- Test 1: fill the FIFO completely (16 writes), check wfull asserts ----
        for (i = 0; i < 16; i = i + 1) begin
            @(negedge wclk);
            wr_en = 1;
            wr_data = i;
            expected_q[i] = i;
        end
        @(negedge wclk);
        wr_en = 0;
        @(posedge wclk);

        if (wfull !== 1'b1) begin
            $display("FAIL: expected wfull=1 after 16 writes into a 16-deep FIFO, got %b", wfull);
            errors = errors + 1;
        end else
            $display("PASS: wfull correctly asserted after filling FIFO");

        // Try writing while full - should be ignored (increment gated by ~wfull)
        @(negedge wclk);
        wr_en = 1; wr_data = 8'hFF;
        @(negedge wclk);
        wr_en = 0;

        // ---- Test 2: drain all 16 entries from the READ domain, check data + rempty ----
        repeat (6) @(posedge rclk);

        for (i = 0; i < 16; i = i + 1) begin
            @(negedge rclk);
            rd_en = 1;
            @(negedge rclk);
            rd_en = 0;
            if (rd_data !== expected_q[i]) begin
                $display("FAIL: read %0d expected %0d got %0d", i, expected_q[i], rd_data);
                errors = errors + 1;
            end else begin
                $display("PASS: read %0d = %0d correctly", i, rd_data);
            end
        end

        repeat (6) @(posedge rclk);
        if (rempty !== 1'b1) begin
            $display("FAIL: expected rempty=1 after draining all 16 entries, got %b", rempty);
            errors = errors + 1;
        end else
            $display("PASS: rempty correctly asserted after draining FIFO");

        if (errors == 0)
            $display("\n===== ALL FIFO TESTS PASSED =====");
        else
            $display("\n===== %0d TEST(S) FAILED =====", errors);

        $finish;
    end
endmodule
