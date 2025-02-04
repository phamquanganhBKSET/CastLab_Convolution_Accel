//----------------------------------------------------------------------------------
//                           CastLab Convolution Accelerator
//                                      Ver 1.0
//                                  Copyright © 2025
//----------------------------------------------------------------------------------
//    Copyright © 2025 by CastLab
//    All rights reserved.
//
//    File         : baugh_wooley_mult.sv
//    Design       : baugh_wooley_mult
//    Description  : Convolution Accelerator
//    Author       : Quang-Anh Pham <anhpq3105@kaist.ac.kr>
//    Organization : CastLab - Korea Advanced Insititute of Science and Technology
//-----------------------------------------------------------------------------------

module baugh_wooley_mult #(
  parameter INPUT_WIDTH  = 16             ,
  parameter OUTPUT_WIDTH = 2 * INPUT_WIDTH 
)
(
  input  logic [INPUT_WIDTH-1:0 ] multiplicand, // Multiplicand
  input  logic [INPUT_WIDTH-1:0 ] multiplier  , // Multiplier
  output logic [OUTPUT_WIDTH-1:0] result        // Result
);

  // Assume that negative numbers have been represented in 2's complement

  //==============================================================================
  //                           Internal signals
  //==============================================================================

  logic [INPUT_WIDTH-1:0][2*INPUT_WIDTH-1:0] pre_result; // Pre result
  logic [INPUT_WIDTH-1:0][2*INPUT_WIDTH-1:0] sum       ; // Summary

  //==============================================================================
  //                               Computing
  //==============================================================================

  // pre_result
  genvar i;
  generate
    for (i = INPUT_WIDTH-1; i >= 0; i--) begin
      if (i == INPUT_WIDTH-1) begin
        assign pre_result[i] = ({1'b1, (multiplicand[INPUT_WIDTH-1] & multiplier[i]), 
                                ~({(INPUT_WIDTH-1){multiplier[i]}} & multiplicand[INPUT_WIDTH-2:0])} << i);
      end
      else if (i == 0) begin
        assign pre_result[i] = ({1'b1, (~(multiplicand[INPUT_WIDTH-1] & multiplier[i])), 
                                {(INPUT_WIDTH-1){multiplier[i]}} & multiplicand[INPUT_WIDTH-2:0]} << i);
      end
      else begin
        assign pre_result[i] = ({(~(multiplicand[INPUT_WIDTH-1] & multiplier[i])), 
                                {(INPUT_WIDTH-1){multiplier[i]}} & multiplicand[INPUT_WIDTH-2:0]}) << i;
      end
    end
  endgenerate

  // sum
  assign sum[0] = pre_result[0];
  generate
    for (i = 1; i < INPUT_WIDTH; i++) begin
      assign sum[i] = pre_result[i] + sum[i-1];
    end
  endgenerate

  // result
  assign result = sum[INPUT_WIDTH-1];

endmodule : baugh_wooley_mult