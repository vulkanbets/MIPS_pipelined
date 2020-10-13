`timescale 1ns / 1ps

module top # (  parameter WL = 32, MEM_Depth = 512 )
(
    input CLK                                                   // Clock
);
    wire [WL - 1 : 0] PCSrcMuxOut;                              // PCSrc Mux Out
    wire [WL - 1 : 0] PCJumpMuxOut;                             // PCJump Mux Out
    wire [WL - 1 : 0] pc_Out;                                   // Program Counter
    wire [WL - 1 : 0] PCPlus1;                                  // Program Counter                  NOT USED!!!
    wire [WL - 1 : 0] PCPlus1F;                                 // Program Counter Fetch
    wire [WL - 1 : 0] PCPlus1D;                                 // Program Counter Decode
    wire [WL - 1 : 0] instruction;                              // Instruction Memory               NOT USED!!!
    wire [WL - 1 : 0] InstrF;                                   // Instruction Memory Fetch
    wire [WL - 1 : 0] InstrD;                                   // Instruction Memory Decode
    wire [5 : 0] opcode = control_Unit.opcode;                  // Control Unit
    wire [4 : 0] rs = control_Unit.rs;                          // Control Unit
    wire [4 : 0] rt = control_Unit.rt;                          // Control Unit
    wire [4 : 0] rd = control_Unit.rd;                          // Control Unit
    wire [15 : 0] Imm = control_Unit.Imm;                       // Control Unit
    wire [4 : 0] shamt = control_Unit.shamt;                    // Control Unit
    wire [5 : 0] funct = control_Unit.funct;                    // Control Unit
    wire [25 : 0] Jaddr = control_Unit.Jaddr;                   // Control Unit
    wire signed [WL - 1 : 0] SImm = control_Unit.SImm;          // Control Unit
    wire [WL - 1 : 0] PCJump = { PCPlus1[31:26], Jaddr };       // PC Jump Wire
    
    wire RegWriteD;                                             // Control Unit
    wire MemtoReg;                                              // Control Unit
    wire MemWriteD;                                             // Control Unit
    wire Branch;                                                // Control Unit
    wire [3 : 0] ALUControlD;                                   // Control Unit
    wire ALUSrc;                                                // Control Unit
    wire RegDst;                                                // Control Unit
    wire Jump;                                                  // Control Unit
    
    wire [4 : 0] WriteReg;                                      // Write Reg mux out
    wire [WL - 1 : 0] RFRD1;                                    // Register File
    wire [WL - 1 : 0] RFRD2;                                    // Register File
    wire [4 : 0] RFR1 = registerFile.RFR1;                      // Register File
    wire [4 : 0] RFR2 = registerFile.RFR2;                      // Register File
    
    wire RegWriteE;                                             // decode_execute_register
    wire MemtoRegE;                                             // decode_execute_register
    wire MemWriteE;                                             // decode_execute_register
    wire BranchE;                                               // decode_execute_register
    wire [3 : 0] ALUControlE;                                   // decode_execute_register
    wire ALUSrcE;                                               // decode_execute_register
    wire RegDstE;                                               // decode_execute_register
    wire [WL - 1 : 0] RFRD1E;                                   // decode_execute_register
    wire [WL - 1 : 0] RFRD2E;                                   // decode_execute_register
    wire [4 : 0] rtE;                                           // decode_execute_register
    wire [4 : 0] rdE;                                           // decode_execute_register
    wire [WL - 1 : 0] SImmE;                                    // decode_execute_register
    wire [WL - 1 : 0] PCPlus1E;                                 // decode_execute_register
    
    wire [WL - 1 : 0] PCBranch;                                 // PCBranch Adder Out
    wire [WL - 1 : 0] ALUSrcOut;                                // ALU Source mux out
    wire signed [WL - 1 : 0] ALU_Out;                           // ALU
    wire zero;                                                  // ALU zero flag
    wire PCSrc;                                                 // Branch AND gate
    wire [WL - 1 : 0] DMA;                                      // Data Memory
    wire [WL - 1 : 0] DMWD = RFRD2;                             // Data Memory
    wire [WL - 1 : 0] DMRD;                                     // Data Memory
    wire [WL - 1 : 0] Result;                                   // Result mux out
    
    
    mux # ( .WL(WL) )                                                                                   // PCSrc Mux
        PCSrcMux( .A(PCBranch), .B(PCPlus1F), .sel(PCSrc), .out(PCSrcMuxOut) );                         // PCSrc Mux
    
    
    mux # ( .WL(WL) )                                                                                   // PCJump Mux
        PCJumpMux( .A(PCJump), .B(PCSrcMuxOut), .sel(Jump), .out(PCJumpMuxOut) );                       // PCJump Mux
    
    
    pc # ( .WL(WL) )                                                                                    // Program Counter
        programCounter( .CLK(CLK), .pc_In(PCJumpMuxOut), .pc_Out(pc_Out) );                             // Program Counter
    
    
    adder # ( .WL(WL) )                                                                                 // Program Counter Adder
        pcAdder( .pc_Out(pc_Out), .PCPlus1(PCPlus1F) );                                                 // Program Counter Adder
    
    
    inst_Mem # ( .WL(WL), .MEM_Depth(MEM_Depth) )                                                       // Instruction Memory
        instMemory( .addr(pc_Out), .instruction(InstrF) );                                              // Instruction Memory
    
    
    fetch_decode_register  fetch_decode_register( .CLK(CLK), .InstrF(InstrF),                           // Fetch/Decode Register
        .PCPlus1F(PCPlus1F), .InstrD(InstrD),  .PCPlus1D(PCPlus1D) );                                   // Fetch/Decode Register
    
    
    control_Unit # ( .WL(WL) )                                                                          // Control Unit
        control_Unit( .instruction(InstrD), .RegWriteD(RegWriteD), .MemWriteD(MemWriteD),               // Control Unit
                        .ALUControlD(ALUControlD), .ALUSrc(ALUSrc), .MemtoReg(MemtoReg),                // Control Unit
                            .RegDst(RegDst), .Branch(Branch), .Jump(Jump) );                            // Control Unit
    
    
    reg_File # ( .WL(WL) )                                                                              // Register File
        registerFile( .CLK(CLK), .RegWriteW(RegWriteE), .RFR1(rs), .RFR2(rt), .RFWA(WriteReg),          // Register File
                        .RFWD(Result), .RFRD1(RFRD1), .RFRD2(RFRD2) );                                  // Register File
    
    
    decode_execute_register decode_execute_register(  .CLK(CLK), .RegWriteD(RegWriteD),                 // Decode/Execute Register
    .MemtoReg(MemtoReg), .MemWriteD(MemWriteD), .Branch(Branch), .ALUControlD(ALUControlD),             // Decode/Execute Register
    .ALUSrc(ALUSrc), .RegDst(RegDst), .RFRD1(RFRD1), .RFRD2(RFRD2), .rt(rt), .rd(rd),                   // Decode/Execute Register
    .SImm(SImm), .PCPlus1D(PCPlus1D), .RegWriteE(RegWriteE), .MemtoRegE(MemtoRegE),                     // Decode/Execute Register
    .MemWriteE(MemWriteE), .BranchE(BranchE), .ALUControlE(ALUControlE), .ALUSrcE(ALUSrcE),             // Decode/Execute Register
    .RegDstE(RegDstE), .RFRD1E(RFRD1E), .RFRD2E(RFRD2E), .rtE(rtE), .rdE(rdE),                          // Decode/Execute Register
    .SImmE(SImmE), .PCPlus1E(PCPlus1E) );                                                               // Decode/Execute Register
    
    
    mux # ( .WL(5) )                                                                                 // WriteReg mux
        WriteRegMux( .A(rdE), .B(rtE), .sel(RegDstE), .out(WriteReg) );                               // WriteReg mux
    
    
    mux # ( .WL(WL) )                                                                                   // ALU source mux
        ALUSrcMux( .A(SImmE), .B(RFRD2E), .sel(ALUSrcE), .out(ALUSrcOut) );                           // ALU source mux
    
    
    PCBranchAdder # (.WL(WL))                                                                        // PCBranch Adder
        myPCBranchAdder( .A(SImmE), .B(PCPlus1E), .out(PCBranch) );                                 // PCBranch Adder
    
    
    alu # (  .WL(WL) )                                                                                  // ALU
        alu( .A(RFRD1E), .B(ALUSrcOut), .shamt(shamt), .ALU_Out(ALU_Out), .zero(zero),                   // ALU
                .ALUControlE(ALUControlE) );                                                            // ALU
    
    
    AndGatePCSrc andGate( .A(BranchE), .B(zero), .out(PCSrc) );                                          // PCSrc AND gate
    
    
    data_Mem # ( .WL(WL), .MEM_Depth(MEM_Depth) )                                                       // Data Memory
        dataMemory( .CLK(CLK), .MemWriteM(MemWriteE), .DMA(ALU_Out), .DMWD(RFRD2E), .DMRD(DMRD) );       // Data Memory
    
    
    mux # ( .WL(WL) )                                                                                   // result mux
        resultMux( .A(DMRD), .B(ALU_Out), .sel(MemtoRegE), .out(Result) );                               // result mux
    
endmodule
