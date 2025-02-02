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
  parameter INPUT_WIDTH_1 = 16                           ,
  parameter INPUT_WIDTH_2 = 16                           ,
  parameter OUTPUT_WIDTH  = INPUT_WIDTH_1 + INPUT_WIDTH_2 
)
(
  input  logic [INPUT_WIDTH_1-1:0] multiplier  , // Multiplier
  input  logic [INPUT_WIDTH_2-1:0] multiplicand, // Multiplicand
  output logic [OUTPUT_WIDTH-1:0 ] result        // Result
);

  // Assume that negative numbers have been represented in 2's complement

  //==============================================================================
  //                           Internal signals
  //==============================================================================

  logic [INPUT_WIDTH_2-1:0][OUTPUT_WIDTH-1:0] pre_result; // Pre result
  logic [INPUT_WIDTH_2-1:0][OUTPUT_WIDTH-1:0] sum       ; // Summary

  //==============================================================================
  //                               Computing
  //==============================================================================

  // pre_result
  genvar i;
  generate
    for (i = INPUT_WIDTH_2-1; i >= 0; i--) begin
      if (i == INPUT_WIDTH_2-1) begin
        always_comb begin : proc_pre_result_iw_max
          pre_result[i] = ({1'b1, (multiplier[INPUT_WIDTH_1-1] & multiplicand[i]), 
                           ~({(INPUT_WIDTH_1-1){multiplicand[i]}} & multiplier[INPUT_WIDTH_1-2:0])} << i);
        end
      end
      else if (i == 0) begin
        always_comb begin : proc_pre_result_iw_0
          pre_result[i] = ({1'b1, (~(multiplier[INPUT_WIDTH_1-1] & multiplicand[i])), 
                            {(INPUT_WIDTH_1-1){multiplicand[i]}} & multiplier[INPUT_WIDTH_1-2:0]} << i);
        end
      end
      else begin
        always_comb begin : proc_pre_result_iw_normal
          pre_result[i] = ({(~(multiplier[INPUT_WIDTH_1-1] & multiplicand[i])), 
                            {(INPUT_WIDTH_1-1){multiplicand[i]}} & multiplier[INPUT_WIDTH_1-2:0]}) << i;
        end
      end
    end
  endgenerate

  // sum
  assign sum[0] = pre_result[0];
  generate
    for (i = 1; i < INPUT_WIDTH_2; i++) begin
      assign sum[i] = pre_result[i] + sum[i-1];
    end
  endgenerate

  // result
  assign result = sum[INPUT_WIDTH_2-1];

endmodule : baugh_wooley_mult