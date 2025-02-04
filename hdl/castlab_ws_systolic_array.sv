//----------------------------------------------------------------------------------
//                           CastLab Convolution Accelerator
//                                      Ver 1.0
//                                  Copyright © 2025
//----------------------------------------------------------------------------------
//    Copyright © 2025 by CastLab
//    All rights reserved.
//
//    File         : castlab_ws_systolic_array.sv
//    Design       : castlab_ws_systolic_array
//    Description  : Convolution Accelerator
//    Author       : Quang-Anh Pham <anhpq3105@kaist.ac.kr>
//    Organization : CastLab - Korea Advanced Insititute of Science and Technology
//-----------------------------------------------------------------------------------

`include "castlab_systolic_array_defines.sv"

module castlab_ws_systolic_array #(
  // Input parameters
  parameter IF_WIDTH     = `CFG_IF_WIDTH   ,
  parameter IF_HEIGHT    = `CFG_IF_HEIGHT  ,
  parameter IF_CHANNEL   = `CFG_IF_CHANNEL ,
  parameter IF_BITWIDTH  = `CFG_IF_BITWIDTH,
  parameter IF_FRAC_BIT  = `CFG_IF_FRAC_BIT,
  parameter IF_PORT      = `CFG_IF_PORT    ,
  // Kernel parameters
  parameter K_WIDTH      = `CFG_K_WIDTH    ,
  parameter K_HEIGHT     = `CFG_K_HEIGHT   ,
  parameter K_CHANNEL    = `CFG_K_CHANNEL  ,
  parameter K_BITWIDTH   = `CFG_K_BITWIDTH ,
  parameter K_FRAC_BIT   = `CFG_K_FRAC_BIT ,
  parameter K_PORT       = `CFG_K_PORT     ,
  parameter K_NUM        = `CFG_K_NUM      ,
  // Output parameters
  parameter OF_WIDTH     = `CFG_OF_WIDTH   ,
  parameter OF_HEIGHT    = `CFG_OF_HEIGHT  ,
  parameter OF_CHANNEL   = `CFG_OF_CHANNEL ,
  parameter OF_BITWIDTH  = `CFG_OF_BITWIDTH,
  parameter OF_FRAC_BIT  = `CFG_OF_FRAC_BIT,
  parameter OF_PORT      = `CFG_OF_PORT    ,
  parameter OF_NUM       = `CFG_OF_NUM      
)
(
  // Global signals
  input  logic                                                 clk       , // Clock signal
  input  logic                                                 rst_n     , // Asynchronous reset, active LOW
  // Input data signals
  input  logic                                                 if_start  , // Start input feature prefetching
  input  logic [IF_PORT-1:0][IF_BITWIDTH-1:0]                  if_i_data , // Input feature data
  input  logic [IF_PORT-1:0]                                   if_i_valid, // Input feature prefetching valid
  // Kernel data signals
  input  logic                                                 k_prefetch, // Start kernel data prefetching
  input  logic [K_NUM-1:0  ][K_PORT-1:0     ][K_BITWIDTH-1:0 ] k_i_data  , // Kernel data
  input  logic [K_NUM-1:0  ][K_PORT-1:0     ]                  k_i_valid , // Kernel data prefetching valid
  // Output data signals
  output logic                                                 of_done   , // Done flag for convolution computing process
  output logic [OF_NUM-1:0 ][OF_PORT-1:0    ][OF_BITWIDTH-1:0] of_o_data , // Output feature data
  output logic [OF_NUM-1:0 ][OF_PORT-1:0    ]                  of_o_valid  // Output feature data valid
);

  //==============================================================================
  //                         Internal parameters
  //==============================================================================

  localparam PSUM_BITWIDTH = IF_BITWIDTH + K_BITWIDTH;
  localparam PSUM_FRAC_BIT = IF_FRAC_BIT + K_FRAC_BIT;
  localparam OF_INT_BIT    = OF_BITWIDTH - OF_FRAC_BIT;

  //==============================================================================
  //                           Internal signals
  //==============================================================================

  logic                                             pe_iclr         ;
  logic                                             pe_wclr         ;
  logic [IF_PORT-1:0][K_NUM-1:0]                    pe_iload_i_valid;
  logic [IF_PORT-1:0][K_NUM-1:0]                    pe_wload_i_valid;
  logic [IF_PORT-1:0][K_NUM-1:0][IF_BITWIDTH-1:0  ] pe_if_i_data    ;
  logic [IF_PORT-1:0][K_NUM-1:0][K_BITWIDTH-1:0   ] pe_weight_i_data;
  logic [IF_PORT-1:0][K_NUM-1:0][PSUM_BITWIDTH-1:0] pe_psum_i_data  ;
  logic [IF_PORT-1:0][K_NUM-1:0]                    pe_iload_o_valid;
  logic [IF_PORT-1:0][K_NUM-1:0][IF_BITWIDTH-1:0  ] pe_if_o_data    ;
  logic [IF_PORT-1:0][K_NUM-1:0][K_BITWIDTH-1:0   ] pe_weight_o_data;
  logic [IF_PORT-1:0][K_NUM-1:0][PSUM_BITWIDTH-1:0] pe_psum_o_data  ;
  logic [IF_PORT-1:0][K_NUM-1:0]                    pe_psum_o_valid ;
  logic                                             input_is_valid  ;

  //==============================================================================
  //                               Computing
  //==============================================================================

  genvar i, j;
  
  // ---------------------------
  // WS Processing Element Array
  // ---------------------------
  generate
    for (i = 0; i < IF_PORT; i++) begin : processing_element_loop_i
      for (j = 0; j < K_NUM; j++) begin : processing_element_loop_j
        ws_processing_element #(
          .INPUT_WIDTH      (IF_BITWIDTH              ), // Total length of input number
          .INPUT_INT_WIDTH  (IF_BITWIDTH - IF_FRAC_BIT), // Int width of input number
          .WEIGHT_WIDTH     (K_BITWIDTH               ), // Total length of weight number
          .WEIGHT_INT_WIDTH (K_BITWIDTH - K_FRAC_BIT  )  // Int width of weight number
        ) ws_processing_element (
          .clk          (clk                   ), // Clock signal
          .rst_n        (rst_n                 ), // Asynchronous reset, active LOW
          .iclr         (pe_iclr               ), // Synchronous reset for input data, active HIGH
          .wclr         (pe_wclr               ), // Synchronous reset for kernel data, active HIGH
          .iload_i_valid(pe_iload_i_valid[i][j]), // Input load valid in
          .wload_i_valid(pe_wload_i_valid[i][j]), // Weight load valid
          .if_i_data    (pe_if_i_data[i][j]    ), // Input in
          .weight_i_data(pe_weight_i_data[i][j]), // Weight in
          .psum_i_data  (pe_psum_i_data[i][j]  ), // Psum in
          .iload_o_valid(pe_iload_o_valid[i][j]), // Input load valid out
          .if_o_data    (pe_if_o_data[i][j]    ), // Input out
          .weight_o_data(pe_weight_o_data[i][j]), // Weight out
          .psum_o_data  (pe_psum_o_data[i][j]  ), // Psum out
          .psum_o_valid (pe_psum_o_valid[i][j] )  // Psum out valid
        );
      end
    end
  endgenerate

  // ---------------------------
  // pe_iclr
  // ---------------------------
  assign pe_iclr = if_start;

  // ---------------------------
  // pe_wclr
  // ---------------------------
  assign pe_wclr = k_prefetch;

  // ---------------------------
  // pe_iload_i_valid
  // ---------------------------
  generate
    for (i = 0; i < IF_PORT; i++) begin : pe_iload_i_valid_loop_i
      for (j = 0; j < K_NUM; j++) begin : pe_iload_i_valid_loop_j
        if (j == 0) begin
          assign pe_iload_i_valid[i][j] = if_i_valid[i];
        end
        else begin
          assign pe_iload_i_valid[i][j] = pe_iload_o_valid[i][j-1];
        end
      end
    end
  endgenerate

  // ---------------------------
  // pe_wload_i_valid
  // ---------------------------
  generate
    for (i = 0; i < IF_PORT; i++) begin : pe_wload_i_valid_loop_i
      for (j = 0; j < K_NUM; j++) begin : pe_wload_i_valid_loop_j
        assign pe_wload_i_valid[i][j] = k_i_valid[j];
      end
    end
  endgenerate

  // ---------------------------
  // pe_if_i_data
  // ---------------------------
  generate
    for (i = 0; i < IF_PORT; i++) begin : pe_if_i_data_loop_i
      for (j = 0; j < K_NUM; j++) begin : pe_if_i_data_loop_j
        if (j == 0) begin
          assign pe_if_i_data[i][j] = if_i_data[i];
        end
        else begin
          assign pe_if_i_data[i][j] = pe_if_o_data[i][j-1];
        end
      end
    end
  endgenerate

  // ---------------------------
  // pe_weight_i_data
  // ---------------------------
  generate
    for (i = 0; i < IF_PORT; i++) begin : pe_weight_i_data_loop_i
      for (j = 0; j < K_NUM; j++) begin : pe_weight_i_data_loop_j
        if (i == 0) begin
          assign pe_weight_i_data[i][j] = k_i_data[j];
        end
        else begin
          assign pe_weight_i_data[i][j] = pe_weight_o_data[i-1][j];
        end
      end
    end
  endgenerate

  // ---------------------------
  // pe_psum_i_data
  // ---------------------------
  generate
    for (i = 0; i < IF_PORT; i++) begin : pe_psum_i_data_loop_i
      for (j = 0; j < K_NUM; j++) begin : pe_psum_i_data_loop_j
        if (i == 0) begin
          assign pe_psum_i_data[i][j] = 0;
        end
        else begin
          assign pe_psum_i_data[i][j] = pe_psum_o_data[i-1][j];
        end
      end
    end
  endgenerate

  // input_is_valid
  always_ff @(posedge clk or negedge rst_n) begin : proc_input_is_valid
    if(~rst_n) begin
      input_is_valid <= 0;
    end else begin
      if (of_done) begin
        input_is_valid <= 0;
      end
      else if (pe_iload_o_valid[IF_PORT-1][K_NUM-1]) begin
        input_is_valid <= 1;
      end
    end
  end

  //==============================================================================
  //                             Output signals
  //==============================================================================

  // of_done
  assign of_done = input_is_valid & (~pe_iload_o_valid[IF_PORT-1][K_NUM-1]);

  // of_o_data
  generate
    for (i = 0; i < OF_NUM; i++) begin : of_o_data_loop_i
      assign of_o_data[i] = pe_psum_o_data[IF_PORT-1][i][PSUM_FRAC_BIT+OF_INT_BIT-1:PSUM_FRAC_BIT-OF_FRAC_BIT];
    end
  endgenerate

  // of_o_valid
  generate
    for (i = 0; i < OF_NUM; i++) begin : of_o_valid_loop_i
      assign of_o_valid[i] = pe_psum_o_valid[IF_PORT-1][i];
    end
  endgenerate

endmodule : castlab_ws_systolic_array
