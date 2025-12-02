`timescale 1ns/1ps

module tb_top;

// `define trace_gate_level_simulation - DISABLED for post-synthesis simulation

reg clk;
reg rst;

reg [7:0] mem[131072:0];
integer i;
integer f;
integer __wd_count;

// Clock generation - 190 MHz = 5.263ns period (half-period = 2.6315ns)
always #2.6315 clk = ~clk;

initial
begin
    $display("Starting bench");

    if (`TRACE)
    begin
        $dumpfile("waveform.vcd");
        $dumpvars(0, tb_top);
    end

    // Reset
    clk = 0;
    rst = 1;
    repeat (5) @(posedge clk);
    rst = 0;

    // Load TCM memory
    for (i=0;i<131072;i=i+1)
        mem[i] = 0;

    if (`ELF_FILE != "")
    begin
        $display("Loading %s", `ELF_FILE);
        $readmemh(`ELF_FILE, mem);
    end

    // Load into target memory
    for (i=0;i<131072;i=i+1)
        u_tcm.u_ram.ram[i/8][((i%8)*8)+7-:8] = mem[i];

    @(posedge clk);
end

// Watchdog to avoid infinite simulation hangs: finish after MAX_CYCLES
initial
begin
    __wd_count = 0;
    forever begin
        @(posedge clk);
        __wd_count = __wd_count + 1;
        if (__wd_count >= 1000000) begin
            $display("[WATCHDOG] Reached %0d cycles - calling $finish", __wd_count);
            $finish;
        end
    end
end

wire        clk_w = clk;
wire        rst_w = rst;
wire        rst_cpu_w = rst_w;
wire [31:0] reset_vector_w = 32'h80000000;
wire        intr_w = 1'b0;
wire        mem_i_rd_w;
wire        mem_i_flush_w;
wire        mem_i_invalidate_w;
wire        mem_i_pc_w;
wire [63:0] mem_i_inst_w;
wire        mem_i_valid_w;
wire        mem_i_error_w;
wire [31:0] mem_d_addr_w;
wire [31:0] mem_d_data_wr_w;
wire        mem_d_rd_w;
wire [3:0]  mem_d_wr_w;
wire        mem_d_cacheable_w;
wire [10:0] mem_d_req_tag_w;
wire        mem_d_invalidate_w;
wire        mem_d_flush_w;
wire [31:0] mem_d_data_rd_w;
wire        mem_d_accept_w;
wire        mem_d_ack_w;
wire        mem_d_error_w;
wire [10:0] mem_d_resp_tag_w;

riscv_core
u_dut
(
     .clk(clk_w)
    ,.rst_n(rst_cpu_w)

    ,.intr_i(intr_w)
    ,.reset_vector_i(reset_vector_w)
    ,.cpu_id_i(32'h00000000)

    ,.mem_i_accept_i(1'b1)
    ,.mem_i_valid_i(mem_i_valid_w)
    ,.mem_i_error_i(mem_i_error_w)
    ,.mem_i_inst_i(mem_i_inst_w)
    ,.mem_i_rd_o(mem_i_rd_w)
    ,.mem_i_flush_o(mem_i_flush_w)
    ,.mem_i_invalidate_o(mem_i_invalidate_w)
    ,.mem_i_pc_o(mem_i_pc_w)

    ,.mem_d_data_rd_i(mem_d_data_rd_w)
    ,.mem_d_accept_i(mem_d_accept_w)
    ,.mem_d_ack_i(mem_d_ack_w)
    ,.mem_d_error_i(mem_d_error_w)
    ,.mem_d_resp_tag_i(mem_d_resp_tag_w)
    ,.mem_d_addr_o(mem_d_addr_w)
    ,.mem_d_data_wr_o(mem_d_data_wr_w)
    ,.mem_d_rd_o(mem_d_rd_w)
    ,.mem_d_wr_o(mem_d_wr_w)
    ,.mem_d_cacheable_o(mem_d_cacheable_w)
    ,.mem_d_req_tag_o(mem_d_req_tag_w)
    ,.mem_d_invalidate_o(mem_d_invalidate_w)
    ,.mem_d_writeback_o(/* not used */)
    ,.mem_d_flush_o(mem_d_flush_w)
);

tcm_mem
u_tcm
(
     .clk_i(clk_w)
    ,.rst_i(rst_cpu_w)

    ,.mem_i_pc_i(mem_i_pc_w)
    ,.mem_i_rd_i(mem_i_rd_w)
    ,.mem_i_flush_i(mem_i_flush_w)
    ,.mem_i_invalidate_i(mem_i_invalidate_w)
    ,.mem_i_inst_o(mem_i_inst_w)
    ,.mem_i_valid_o(mem_i_valid_w)
    ,.mem_i_error_o(mem_i_error_w)
    ,.mem_i_accept_o(/* Not used */)

    ,.mem_d_addr_i(mem_d_addr_w)
    ,.mem_d_data_wr_i(mem_d_data_wr_w)
    ,.mem_d_rd_i(mem_d_rd_w)
    ,.mem_d_wr_i(mem_d_wr_w)
    ,.mem_d_cacheable_i(mem_d_cacheable_w)
    ,.mem_d_req_tag_i(mem_d_req_tag_w)
    ,.mem_d_invalidate_i(mem_d_invalidate_w)
    ,.mem_d_writeback_i(1'b0)
    ,.mem_d_flush_i(mem_d_flush_w)
    ,.mem_d_data_rd_o(mem_d_data_rd_w)
    ,.mem_d_accept_o(mem_d_accept_w)
    ,.mem_d_ack_o(mem_d_ack_w)
    ,.mem_d_error_o(mem_d_error_w)
    ,.mem_d_resp_tag_o(mem_d_resp_tag_w)
);

// NO TRACE for post-synthesis simulation - biriscv_trace_sim_gls not included

endmodule
