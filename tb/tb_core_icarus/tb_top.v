module tb_top;

`define trace_gate_level_simulation

reg clk;
reg rst;

reg [7:0] mem[131072:0];
integer i;
integer f;

initial
begin
   // 1. Inicializacao em Reset Ativo (High)
   // O codigo original sugeria que rst=1 eh o estado de reset.
   clk = 0;
   rst = 1;
   $display("Starting bench - Time: %0t", $time);

   // Trace (Opcional)
   if (`TRACE) begin
       $dumpfile("waveform.vcd");
       $dumpvars(0, tb_top);
   end

   // 2. Carregar SDF (CRITICO: Antes de usar a memoria)
`ifdef POSTSYN
   $display("Loading SDF for Gate-Level Simulation...");
   // Ajuste o caminho se necessario (ex: 185_MHz ou 190_MHz)
   $sdf_annotate("../deliverables/185_MHz/WORST/riscv_core.sdf", u_dut, , "sdf.log", "TYPICAL", "1.0:1.0:1.0", "FROM_MTM");
   $display("SDF Loaded Successfully.");
`endif

   // 3. Carregar Memoria TCM
   for (i=0;i<131072;i=i+1)
       mem[i] = 0;

   f = $fopen("tcm.bin", "r");
   if (f == 0) begin
       $display("ERRO: Nao foi possivel abrir tcm.bin");
       $finish;
   end
   i = $fread(mem, f);
   $fclose(f);

   for (i=0;i<131072;i=i+1)
       u_mem.write(i, mem[i]);

   $display("Memory loaded. Holding Reset...");

   // 4. Sequencia de Reset (Logica 1 -> 0)
   // Mantem em 1 (Reset) por um tempo
   rst = 1;
   repeat (20) @(posedge clk);

   $display("Releasing reset (rst -> 0)...");
   rst = 0; // Libera o processador para rodar

    // Patch do Stack Pointer (Apenas RTL)
    /*
    `ifndef POSTSYN
    #1;
    u_dut.u_issue.u_regfile.REGFILE.reg_r2_q = 32'h80001FF0;
    $display("PATCH: SP (x2) inicializado para 0x80001FF0");
    `endif
    */
end

initial
begin
    clk = 0;
    // 185 MHz = 5.405 ns period -> half-period = 2.7027 ns
    forever #2.7027 clk = ~clk;
end

wire          mem_i_rd_w;
wire          mem_i_flush_w;
wire          mem_i_invalidate_w;
wire [ 31:0]  mem_i_pc_w;
wire [ 31:0]  mem_d_addr_w;
wire [ 31:0]  mem_d_data_wr_w;
wire          mem_d_rd_w;
wire [  3:0]  mem_d_wr_w;
wire          mem_d_cacheable_w;
wire [ 10:0]  mem_d_req_tag_w;
wire          mem_d_invalidate_w;
wire          mem_d_writeback_w;
wire          mem_d_flush_w;
wire          mem_i_accept_w;
wire          mem_i_valid_w;
wire          mem_i_error_w;
wire [ 63:0]  mem_i_inst_w;
wire [ 31:0]  mem_d_data_rd_w;
wire          mem_d_accept_w;
wire          mem_d_ack_w;
wire          mem_d_error_w;
wire [ 10:0]  mem_d_resp_tag_w;

riscv_core
u_dut
//-----------------------------------------------------------------
// Ports
//-----------------------------------------------------------------
(
    // Inputs
     .clk(clk)
    ,.rst_n(rst)
    ,.mem_d_data_rd_i(mem_d_data_rd_w)
    ,.mem_d_accept_i(mem_d_accept_w)
    ,.mem_d_ack_i(mem_d_ack_w)
    ,.mem_d_error_i(mem_d_error_w)
    ,.mem_d_resp_tag_i(mem_d_resp_tag_w)
    ,.mem_i_accept_i(mem_i_accept_w)
    ,.mem_i_valid_i(mem_i_valid_w)
    ,.mem_i_error_i(mem_i_error_w)
    ,.mem_i_inst_i(mem_i_inst_w)
    ,.intr_i(1'b0)
    ,.reset_vector_i(32'h80000054)
    ,.cpu_id_i('b0)

    // Outputs
    ,.mem_d_addr_o(mem_d_addr_w)
    ,.mem_d_data_wr_o(mem_d_data_wr_w)
    ,.mem_d_rd_o(mem_d_rd_w)
    ,.mem_d_wr_o(mem_d_wr_w)
    ,.mem_d_cacheable_o(mem_d_cacheable_w)
    ,.mem_d_req_tag_o(mem_d_req_tag_w)
    ,.mem_d_invalidate_o(mem_d_invalidate_w)
    ,.mem_d_writeback_o(mem_d_writeback_w)
    ,.mem_d_flush_o(mem_d_flush_w)
    ,.mem_i_rd_o(mem_i_rd_w)
    ,.mem_i_flush_o(mem_i_flush_w)
    ,.mem_i_invalidate_o(mem_i_invalidate_w)
    ,.mem_i_pc_o(mem_i_pc_w)
);

tcm_mem
u_mem
(
    // Inputs
     .clk_i(clk)
    ,.rst_i(rst)
    ,.mem_i_rd_i(mem_i_rd_w)
    ,.mem_i_flush_i(mem_i_flush_w)
    ,.mem_i_invalidate_i(mem_i_invalidate_w)
    ,.mem_i_pc_i(mem_i_pc_w)
    ,.mem_d_addr_i(mem_d_addr_w)
    ,.mem_d_data_wr_i(mem_d_data_wr_w)
    ,.mem_d_rd_i(mem_d_rd_w)
    ,.mem_d_wr_i(mem_d_wr_w)
    ,.mem_d_cacheable_i(mem_d_cacheable_w)
    ,.mem_d_req_tag_i(mem_d_req_tag_w)
    ,.mem_d_invalidate_i(mem_d_invalidate_w)
    ,.mem_d_writeback_i(mem_d_writeback_w)
    ,.mem_d_flush_i(mem_d_flush_w)

    // Outputs
    ,.mem_i_accept_o(mem_i_accept_w)
    ,.mem_i_valid_o(mem_i_valid_w)
    ,.mem_i_error_o(mem_i_error_w)
    ,.mem_i_inst_o(mem_i_inst_w)
    ,.mem_d_data_rd_o(mem_d_data_rd_w)
    ,.mem_d_accept_o(mem_d_accept_w)
    ,.mem_d_ack_o(mem_d_ack_w)
    ,.mem_d_error_o(mem_d_error_w)
    ,.mem_d_resp_tag_o(mem_d_resp_tag_w)
);

`ifdef trace_gate_level_simulation

biriscv_trace_sim_gls
trace_inst_0
(
     .valid_i(mem_i_valid_w)
    ,.opcode_i(mem_i_inst_w[31:0])
);

biriscv_trace_sim_gls
trace_inst_1
(
     .valid_i(mem_i_valid_w)
    ,.opcode_i(mem_i_inst_w[63:32])
);

`endif

initial begin
    // Aguarda tempo suficiente para o algoritmo rodar (ajuste se necessario)
    #500000; 
    
    $display("\n=============================================");
    $display("=== DUMP DE MEMORIA (Valores Nao-Nulos) ===");
    $display("=============================================");
    
    // Varre a memoria (ajuste o tamanho 16384 conforme a declaracao real da u_ram)
    for (i = 0; i < 16384; i = i + 1) begin
        // Acesse a hierarquia interna da RAM (verifique se eh u_mem.u_ram.ram ou similar)
        // Usamos !== 0 para pegar qualquer coisa valida
        if (u_mem.u_ram.ram[i] !== 0) begin
             $display("RAM_IDX[%0d] (Addr aprox 0x%x) = %h", i, i*4, u_mem.u_ram.ram[i]);
        end
    end
    
    $display("=============================================\n");
    $finish;
end

endmodule