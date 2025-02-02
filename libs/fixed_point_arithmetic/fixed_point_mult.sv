//----------------------------------------------------------------------------------
//                           CastLab Convolution Accelerator
//                                      Ver 1.0
//                                  Copyright © 2025
//----------------------------------------------------------------------------------
//    Copyright © 2025 by CastLab
//    All rights reserved.
//
//    File         : fixed_point_mult.sv
//    Design       : fixed_point_mult
//    Description  : Convolution Accelerator
//    Author       : Quang-Anh Pham <anhpq3105@kaist.ac.kr>
//    Organization : CastLab - Korea Advanced Insititute of Science and Technology
//-----------------------------------------------------------------------------------

module fixed_point_mult #(
  parameter WORD_WIDTH_IN_1 = 16                               , // Total length of the number
  parameter WORD_WIDTH_IN_2 = 16                               , // Total length of the number
  parameter WORD_WIDTH_OUT  = WORD_WIDTH_IN_1 + WORD_WIDTH_IN_2 
)
(
  input  logic [WORD_WIDTH_IN_1-1:0] multiplier  , // Multiplier
  input  logic [WORD_WIDTH_IN_2-1:0] multiplicand, // Multiplicand
  output logic [WORD_WIDTH_OUT-1:0 ] result        // Result = multiplier * multiplicand
);

  //==============================================================================
  //                               Computing
  //==============================================================================

  // ------
  // result
  // ------
  baugh_wooley_mult #(
    .INPUT_WIDTH_1(WORD_WIDTH_IN_1),
    .INPUT_WIDTH_2(WORD_WIDTH_IN_2),
    .OUTPUT_WIDTH (WORD_WIDTH_OUT )
  ) baugh_wooley_mult (
    .multiplier  (multiplier  ),
    .multiplicand(multiplicand),
    .result      (result      ) 
  );

endmodule : fixed_point_mult