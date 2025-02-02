//----------------------------------------------------------------------------------
//                           CastLab Convolution Accelerator
//                                      Ver 1.0
//                                  Copyright © 2025
//----------------------------------------------------------------------------------
//    Copyright © 2025 by CastLab
//    All rights reserved.
//
//    File         : fixed_point_add.sv
//    Design       : fixed_point_add
//    Description  : Convolution Accelerator
//    Author       : Quang-Anh Pham <anhpq3105@kaist.ac.kr>
//    Organization : CastLab - Korea Advanced Insititute of Science and Technology
//-----------------------------------------------------------------------------------

module fixed_point_add #(
  parameter WORD_WIDTH_1   = 16                               , // Total length of the operand 1
  parameter INT_WIDTH_1    = 8                                , // Int width of the operand 1
  parameter FRAC_WIDTH_1   = WORD_WIDTH_1 - INT_WIDTH_1       , // Factional width of operand 1
  parameter WORD_WIDTH_2   = 16                               , // Total length of the operand 2
  parameter INT_WIDTH_2    = 8                                , // Int width of the operand 2
  parameter FRAC_WIDTH_2   = WORD_WIDTH_2 - INT_WIDTH_2       , // Factional width of operand 2
  parameter INT_WIDTH_OUT  = (INT_WIDTH_1 >= INT_WIDTH_2) ?    
                              INT_WIDTH_1 : INT_WIDTH_2       , // Int width of the output
  parameter FRAC_WIDTH_OUT = (FRAC_WIDTH_1 >= FRAC_WIDTH_2) ?  
                              FRAC_WIDTH_1 : FRAC_WIDTH_2     , // Fractional width of the output
  parameter WORD_WIDTH_OUT = INT_WIDTH_OUT + FRAC_WIDTH_OUT     // Total length of the output
)
(
  input  logic [WORD_WIDTH_1-1:0  ] operand_1, // Operand 1
  input  logic [WORD_WIDTH_2-1:0  ] operand_2, // Operand 2
  output logic [WORD_WIDTH_OUT-1:0] result     // Result = operand 1 + operand 2
);
  
  // Assume that negative numbers have been represented in 2's complement

  //==============================================================================
  //                           Internal signals
  //==============================================================================

  logic [WORD_WIDTH_OUT-1:0] signed_ex_op_1  ; // Signed extended of the operand 1
  logic [INT_WIDTH_OUT-1:0 ] int_extend_op_1 ; // Int extended of the operand 1
  logic [FRAC_WIDTH_OUT-1:0] frac_extend_op_1; // Fractional extended of the operand 1
  logic [WORD_WIDTH_OUT-1:0] signed_ex_op_2  ; // Signed extended of the operand 2
  logic [INT_WIDTH_OUT-1:0 ] int_extend_op_2 ; // Int extended of the operand 2
  logic [FRAC_WIDTH_OUT-1:0] frac_extend_op_2; // Fractional extended of the operand 2

  //==============================================================================
  //                               Computing
  //==============================================================================

  // ----------
  // int_extend
  // ----------
  generate
    if (INT_WIDTH_1 > INT_WIDTH_2) begin
      assign int_extend_op_1 = operand_1[WORD_WIDTH_1-1:FRAC_WIDTH_1];
      assign int_extend_op_2 = {{(INT_WIDTH_1 - INT_WIDTH_2){1'b0}}, 
                                 operand_2[WORD_WIDTH_2-1:FRAC_WIDTH_2]};
    end
    else if (INT_WIDTH_1 < INT_WIDTH_2) begin
      assign int_extend_op_1 = {{(INT_WIDTH_2 - INT_WIDTH_1){1'b0}}, 
                                  operand_1[WORD_WIDTH_1-1:FRAC_WIDTH_1]};
      assign int_extend_op_2 = operand_2[WORD_WIDTH_2-1:FRAC_WIDTH_2];
    end
    else begin
      assign int_extend_op_1 = operand_1[WORD_WIDTH_1-1:FRAC_WIDTH_1];
      assign int_extend_op_2 = operand_2[WORD_WIDTH_2-1:FRAC_WIDTH_2];
    end
  endgenerate

  // -----------
  // frac_extend
  // -----------
  generate
    if (FRAC_WIDTH_1 > FRAC_WIDTH_2) begin
      assign frac_extend_op_1 = operand_1[FRAC_WIDTH_1-1:0];
      assign frac_extend_op_2 = {operand_2[FRAC_WIDTH_2-1:0]          , 
                                 {(FRAC_WIDTH_1 - FRAC_WIDTH_2){1'b0}}};
    end
    else if (FRAC_WIDTH_1 < FRAC_WIDTH_2) begin
      assign frac_extend_op_1 = {operand_1[FRAC_WIDTH_1-1:0]          , 
                                 {(FRAC_WIDTH_2 - FRAC_WIDTH_1){1'b0}}};
      assign frac_extend_op_2 = operand_2[FRAC_WIDTH_2-1:0];
    end
    else begin
      assign frac_extend_op_1 = operand_1[FRAC_WIDTH_1:0];
      assign frac_extend_op_2 = operand_2[FRAC_WIDTH_2:0];
    end
  endgenerate

  // -------------
  // signed_extend
  // -------------
  assign signed_ex_op_1 = {int_extend_op_1, frac_extend_op_1};
  assign signed_ex_op_2 = {int_extend_op_2, frac_extend_op_2};

  // ------
  // result
  // ------
  assign result = signed_ex_op_1 + signed_ex_op_2;

endmodule : fixed_point_add