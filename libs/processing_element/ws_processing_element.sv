//----------------------------------------------------------------------------------
//                           CastLab Convolution Accelerator
//                                      Ver 1.0
//                                  Copyright © 2025
//----------------------------------------------------------------------------------
//    Copyright © 2025 by CastLab
//    All rights reserved.
//
//    File         : ws_processing_element.sv
//    Design       : ws_processing_element
//    Description  : Convolution Accelerator
//    Author       : Quang-Anh Pham <anhpq3105@kaist.ac.kr>
//    Organization : CastLab - Korea Advanced Insititute of Science and Technology
//-----------------------------------------------------------------------------------

module ws_processing_element #(
  parameter INPUT_WIDTH       = 16                                , // Total length of input number
  parameter INPUT_INT_WIDTH   = 8                                 , // Int width of input number
  parameter INPUT_FRAC_WIDTH  = INPUT_WIDTH - INPUT_INT_WIDTH     , // Factional width of input number
  parameter WEIGHT_WIDTH      = 8                                 , // Total length of weight number
  parameter WEIGHT_INT_WIDTH  = 2                                 , // Int width of weight number
  parameter WEIGHT_FRAC_WIDTH = WEIGHT_WIDTH - WEIGHT_INT_WIDTH   , // Factional width of weight number
  parameter PSUM_WIDTH        = INPUT_WIDTH + WEIGHT_WIDTH        , // Total length of psum number
  parameter PSUM_INT_WIDTH    = INPUT_INT_WIDTH + WEIGHT_INT_WIDTH, // Int width of psum number
  parameter PSUM_FRAC_WIDTH   = PSUM_WIDTH - PSUM_INT_WIDTH         // Factional width of psum number
)
(
  input  logic                    clk          , // Clock signal
  input  logic                    rst_n        , // Asynchronous reset, active LOW
  input  logic                    iclr         , // Synchronous reset for input data, active HIGH
  input  logic                    wclr         , // Synchronous reset for kernel data, active HIGH
  input  logic                    iload_i_valid, // Input load valid in
  input  logic                    wload_i_valid, // Weight load valid in
  input  logic [INPUT_WIDTH-1:0 ] if_i_data    , // Input in
  input  logic [WEIGHT_WIDTH-1:0] weight_i_data, // Weight in
  input  logic [PSUM_WIDTH-1:0  ] psum_i_data  , // Psum in
  output logic                    iload_o_valid, // Input load valid out
  output logic [INPUT_WIDTH-1:0 ] if_o_data    , // Input out
  output logic [WEIGHT_WIDTH-1:0] weight_o_data, // Weight out
  output logic [PSUM_WIDTH-1:0  ] psum_o_data  , // Psum out
  output logic                    psum_o_valid   // Psum out valid
);
  
  //==============================================================================
  //                           Internal signals
  //==============================================================================

  logic [INPUT_WIDTH-1:0 ] if_i_data_reg    ; // Latched if_i_data
  logic [WEIGHT_WIDTH-1:0] prefetched_weight; // Prefetched weight
  logic [PSUM_WIDTH-1:0  ] pre_psum         ; // Pre psum
  logic [PSUM_WIDTH-1:0  ] psum             ; // Psum
  logic [PSUM_WIDTH-1:0  ] psum_reg         ; // Latched psum

  //==============================================================================
  //                               Computing
  //==============================================================================

  // if_i_data_reg
  always_ff @(posedge clk or negedge rst_n) begin : proc_if_i_data_reg
    if(~rst_n) begin
      if_i_data_reg <= 0;
    end else begin
      if (iclr) begin
        if_i_data_reg <= 0;
      end
      else if (iload_i_valid) begin
        if_i_data_reg <= if_i_data;
      end
    end
  end

  // prefetched_weight
  always_ff @(posedge clk or negedge rst_n) begin : proc_prefetched_weight
    if(~rst_n) begin
      prefetched_weight <= 0;
    end else begin
      if (wclr) begin
        prefetched_weight <= 0;
      end
      else if (wload_i_valid) begin
        prefetched_weight <= weight_i_data;
      end
    end
  end

  // iload_o_valid
  always_ff @(posedge clk or negedge rst_n) begin : proc_iload_o_valid
    if(~rst_n) begin
      iload_o_valid <= 0;
    end else begin
      iload_o_valid <= iload_i_valid;
    end
  end

  // pre_psum
  fixed_point_mult #(
    .WORD_WIDTH_IN_1(INPUT_WIDTH ), // Total length of the number
    .WORD_WIDTH_IN_2(WEIGHT_WIDTH)  // Total length of the number
  ) fixed_point_mult_pre_psum (
    .multiplier  (if_i_data_reg    ), // Multiplier
    .multiplicand(prefetched_weight), // Multiplicand
    .result      (pre_psum         )  // Result = multiplier * multiplicand
  );

  // psum
  fixed_point_add #(
    .WORD_WIDTH_1(PSUM_WIDTH    ), // Total length of the operand 1
    .INT_WIDTH_1 (PSUM_INT_WIDTH), // Int width of the operand 1
    .WORD_WIDTH_2(PSUM_WIDTH    ), // Total length of the operand 2
    .INT_WIDTH_2 (PSUM_INT_WIDTH)  // Int width of the operand 2
  ) fixed_point_add_psum (
    .operand_1(psum_i_data), // Operand 1
    .operand_2(pre_psum   ), // Operand 2
    .result   (psum       )  // Result = operand 1 + operand 2
  );

  // if_o_data
  assign if_o_data = if_i_data_reg;

  // weight_o_data
  assign weight_o_data = prefetched_weight;

  // psum_o_data
  always_ff @(posedge clk or negedge rst_n) begin : proc_psum_o_data
    if(~rst_n) begin
      psum_o_data <= 0;
    end else begin
      if (iclr | wclr) begin
        psum_o_data <= 0;
      end
      else begin
        psum_o_data <= psum;
      end
    end
  end

  // psum_o_valid
  always_ff @(posedge clk or negedge rst_n) begin : proc_psum_o_valid
    if(~rst_n) begin
      psum_o_valid <= 0;
    end else begin
      psum_o_valid <= iload_i_valid;
    end
  end

endmodule : ws_processing_element