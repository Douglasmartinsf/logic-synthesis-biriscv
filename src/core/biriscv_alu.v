//-----------------------------------------------------------------
//                         biRISC-V CPU
//                            V0.8.1
//                     Ultra-Embedded.com
//                     Copyright 2019-2020
//
//                   admin@ultra-embedded.com
//
//                     License: Apache 2.0
//-----------------------------------------------------------------
module biriscv_alu
(
    // Inputs
     input  [  3:0]  alu_op_i,
     input  [ 31:0]  alu_a_i,
     input  [ 31:0]  alu_b_i,

     // Outputs
     output [ 31:0]  alu_p_o
);
//-----------------------------------------------------------------
// Includes
//-----------------------------------------------------------------
`include "biriscv_defs.v"

//-----------------------------------------------------------------
// Internal Wires (Purely Combinational ALU)
//-----------------------------------------------------------------
wire [3:0]   alu_op_r;
wire [31:0]  alu_a_r;
wire [31:0]  alu_b_r;

assign alu_op_r = alu_op_i;
assign alu_a_r  = alu_a_i;
assign alu_b_r  = alu_b_i;

//-----------------------------------------------------------------
// Internal Registers (Combinational logic)
//-----------------------------------------------------------------
reg [31:0]      result_r;

// --- MUDANÇA INICIA ---
// Registradores intermediários do shifter removidos.
// Adicionada uma wire 'signed' para o shift aritmético.
wire signed [31:0] alu_a_signed = alu_a_r;
// --- MUDANÇA TERMINA ---

wire [31:0]     sub_res_w = alu_a_r - alu_b_r;

//-----------------------------------------------------------------
// ALU (combinational section)
//-----------------------------------------------------------------
always @(*) begin

    // --- MUDANÇA INICIA ---
    // Inicializações dos regs do shifter antigo foram removidas.
    // --- MUDANÇA TERMINA ---

    case (alu_op_r)
       //----------------------------------------------
       // Shift Left
       //----------------------------------------------   
       `ALU_SHIFTL :
       begin
            // --- MUDANÇA INICIA ---
            // Substituído o ripple shifter de 5 estágios por um
            // barrel shifter paralelo inferido pelo sintetizador.
            // O shift só considera os 5 bits inferiores de alu_b_r.
            result_r = alu_a_r << alu_b_r[4:0];
            // --- MUDANÇA TERMINA ---
       end
       //----------------------------------------------
       // Shift Right
       //----------------------------------------------
       `ALU_SHIFTR, `ALU_SHIFTR_ARITH:
       begin
            // --- MUDANÇA INICIA ---
            // Substituído o ripple shifter por operadores de shift
            // nativos do Verilog. O sintetizador criará o hardware
            // de shift mais rápido para '>>' (lógico) e '>>>' (aritmético).

            if (alu_op_r == `ALU_SHIFTR_ARITH)
                // Shift aritmético (usa a wire 'signed')
                result_r = alu_a_signed >>> alu_b_r[4:0];
            else
                // Shift lógico
                result_r = alu_a_r >> alu_b_r[4:0];
            // --- MUDANÇA TERMINA ---
       end       
       //----------------------------------------------
       // Arithmetic
       //----------------------------------------------
       `ALU_ADD : 
            result_r = alu_a_r + alu_b_r;
       `ALU_SUB : 
            result_r = sub_res_w;
       //----------------------------------------------
       // Logical
       //----------------------------------------------       
       `ALU_AND : 
            result_r = alu_a_r & alu_b_r;
       `ALU_OR  : 
            result_r = alu_a_r | alu_b_r;
       `ALU_XOR : 
            result_r = alu_a_r ^ alu_b_r;
       //----------------------------------------------
       // Comparison
       //----------------------------------------------
       `ALU_LESS_THAN : 
            result_r = (alu_a_r < alu_b_r) ? 32'h1 : 32'h0;
       `ALU_LESS_THAN_SIGNED : 
       begin
            if (alu_a_r[31] != alu_b_r[31])
                result_r = alu_a_r[31] ? 32'h1 : 32'h0;
            else
                result_r = sub_res_w[31] ? 32'h1 : 32'h0;            
       end       
       default  : 
            result_r = alu_a_r;
    endcase
end

//-----------------------------------------------------------------
// Output (Combinational)
//-----------------------------------------------------------------
assign alu_p_o = result_r;

endmodule