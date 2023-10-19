--------------------------------------------------------------------------------
-- Procesador RISC V uniciclo curso Arquitectura Ordenadores 2023
-- Initial Release G.Sutter jun 2022. Last Rev. sep2023
-- 
--
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use work.RISCV_pack.all;

entity processorRV is
   port(
      Clk      : in  std_logic;                     -- Reloj activo en flanco subida
      Reset    : in  std_logic;                     -- Reset asincrono activo nivel alto
      -- Instruction memory
      IAddr    : out std_logic_vector(31 downto 0); -- Direccion Instr
      IDataIn  : in  std_logic_vector(31 downto 0); -- Instruccion leida
      -- Data memory
      DAddr    : out std_logic_vector(31 downto 0); -- Direccion
      DRdEn    : out std_logic;                     -- Habilitacion lectura
      DWrEn    : out std_logic;                     -- Habilitacion escritura
      DDataOut : out std_logic_vector(31 downto 0); -- Dato escrito
      DDataIn  : in  std_logic_vector(31 downto 0)  -- Dato leido
   );
end processorRV;

architecture rtl of processorRV is

  component alu_RV
    port (
      OpA     : in  std_logic_vector (31 downto 0); -- Operando A
      OpB     : in  std_logic_vector (31 downto 0); -- Operando B
      Control : in  std_logic_vector ( 3 downto 0); -- Codigo de control=op. a ejecutar
      Result  : out std_logic_vector (31 downto 0); -- Resultado
      SignFlag: out std_logic;                      -- Sign Flag
      CarryOut: out std_logic;                      -- Carry bit
      ZFlag   : out std_logic                       -- Flag Z
    );
  end component;

  component reg_bank
     port (
        Clk   : in  std_logic;                      -- Reloj activo en flanco de subida
        Reset : in  std_logic;                      -- Reset asincrono a nivel alto
        A1    : in  std_logic_vector(4 downto 0);   -- Direccion para el primer registro fuente (rs1)
        Rd1   : out std_logic_vector(31 downto 0);  -- Dato del primer registro fuente (rs1)
        A2    : in  std_logic_vector(4 downto 0);   -- Direccion para el segundo registro fuente (rs2)
        Rd2   : out std_logic_vector(31 downto 0);  -- Dato del segundo registro fuente (rs2)
        A3    : in  std_logic_vector(4 downto 0);   -- Direccion para el registro destino (rd)
        Wd3   : in  std_logic_vector(31 downto 0);  -- Dato de entrada para el registro destino (rd)
        We3   : in  std_logic                       -- Habilitacion de la escritura de Wd3 (rd)
     ); 
  end component reg_bank;

  component control_unit
     port (
        -- Entrada = codigo de operacion en la instruccion:
        OpCode   : in  std_logic_vector (6 downto 0);
        -- Seniales para el PC
        Branch   : out  std_logic;                     -- 1 = Ejecutandose instruccion branch
        Ins_Jal  : out  std_logic;                     -- 1 = jal , 0 = otra instruccion, 
        Ins_Jalr : out  std_logic;                     -- 1 = jalr, 0 = otra instruccion, 
        -- Seniales relativas a la memoria y seleccion dato escritura registros
        ResultSrc: out  std_logic_vector(1 downto 0);  -- 00 salida Alu; 01 = salida de la mem.; 10 PC_plus4
        MemWrite : out  std_logic;                     -- Escribir la memoria
        MemRead  : out  std_logic;                     -- Leer la memoria
        -- Seniales para la ALU
        ALUSrc   : out  std_logic;                     -- 0 = oper.B es registro, 1 = es valor inm.
        AuipcLui : out  std_logic_vector (1 downto 0); -- 0 = PC. 1 = zeros, 2 = reg1.
        ALUOp    : out  std_logic_vector (2 downto 0); -- Tipo operacion para control de la ALU
        -- Seniales para el GPR
        RegWrite : out  std_logic                      -- 1 = Escribir registro
     );
  end component;

  component alu_control is
    port (
      -- Entradas:
      ALUOp  : in std_logic_vector (2 downto 0);     -- Codigo de control desde la unidad de control
      Funct3 : in std_logic_vector (2 downto 0);     -- Campo "funct3" de la instruccion (I(14:12))
      Funct7 : in std_logic_vector (6 downto 0);     -- Campo "funct7" de la instruccion (I(31:25))     
      -- Salida de control para la ALU:
      ALUControl : out std_logic_vector (3 downto 0) -- Define operacion a ejecutar por la ALU
    );
  end component alu_control;

 component Imm_Gen is
    port (
        instr     : in std_logic_vector(31 downto 0);
        imm       : out std_logic_vector(31 downto 0)
    );
  end component Imm_Gen;

  ------------- Señales-------------------
  --ALU:
  signal Alu_Op1       : std_logic_vector(31 downto 0); -- ALUSrcA
  signal Alu_Op2        : std_logic_vector(31 downto 0); -- ALUSrcB
  signal Alu_ZERO       : std_logic;                     -- ALUZero
  signal Alu_SIGN       : std_logic;                     -- ALUSign
  signal AluControl     : std_logic_vector(3 downto 0);  -- ALUControl 
  signal Alu_Res        : std_logic_vector(31 downto 0); -- ALUResult
  --Read Data:
  signal reg_RD_data    : std_logic_vector(31 downto 0); -- ReadData
  --Instruction memory:
  signal branch_true    : std_logic;                     -- Decision_jump
  signal PC_next        : std_logic_vector(31 downto 0); -- PCNext
  signal PC_reg         : std_logic_vector(31 downto 0); -- PC
  signal PC_plus4       : std_logic_vector(31 downto 0); -- PCPlus4
  signal Instruction    : std_logic_vector(31 downto 0); -- La instrucción desde lamem de instr
  --Immediate Generator:
  signal Imm_ext        : std_logic_vector(31 downto 0); -- La parte baja de la instrucción extendida de signo
  --Register Bank:
  signal reg_RS1        : std_logic_vector(31 downto 0); -- RD1
  signal reg_RS2        : std_logic_vector(31 downto 0); -- RD2
  signal RS1            : std_logic_vector(4 downto 0);  -- RS1
  signal RS2            : std_logic_vector(4 downto 0);  -- RS2
  signal RD             : std_logic_vector(4 downto 0);  -- We3
  --Datos de memoria:
  signal dataIn_Mem     : std_logic_vector(31 downto 0); -- Dato desde memoria
  --Saltos:
  signal Addr_BranchJal : std_logic_vector(31 downto 0); -- Addr_BranchJal
  signal Addr_Jalr      : std_logic_vector(31 downto 0); -- Addr_Jalr
  signal Addr_Jump_dest : std_logic_vector(31 downto 0); -- Addr_Jump
  signal decision_Jump  : std_logic;                     -- Decision_Jump
  --Control Unit:
  signal Ctrl_Jal       : std_logic;                     -- Jal
  signal Ctrl_Jalr      : std_logic;                     -- Jalr
  signal Ctrl_Branch    : std_logic;                     -- Branch
  signal Ctrl_MemWrite  : std_logic;                     -- MemWrite
  signal Ctrl_MemRead   : std_logic;                     -- MemRead
  signal Ctrl_ALUSrc    : std_logic;                     -- ALUSrc
  signal Ctrl_RegWrite  : std_logic;                     -- RegWrite
  signal Ctrl_ALUOp     : std_logic_vector(2 downto 0);  -- ALUOp
  signal Ctrl_PcLui     : std_logic_vector(1 downto 0);  -- PCIui
  signal Ctrl_ResSrc    : std_logic_vector(1 downto 0);  -- ResSrc
  --ALU Control (Instruction fields):
  signal Funct3         : std_logic_vector(2 downto 0);  -- Funct3
  signal Funct7         : std_logic_vector(6 downto 0);  -- Funct7


  -- Señales para IF/ID Stage
  --Instruction memory:
  signal PC_reg_IF      : std_logic_vector(31 downto 0); -- PC_IF
  signal PC_reg_ID      : std_logic_vector(31 downto 0); -- PC_ID
  signal PC_plus4_IF    : std_logic_vector(31 downto 0); -- PCPlus4_IF
  signal PC_plus4_ID    : std_logic_vector(31 downto 0); -- PCPlus4_ID
  signal Instruction_IF : std_logic_vector(31 downto 0); -- Instr_IF
  signal Instruction_ID : std_logic_vector(31 downto 0); -- Instr_ID
  
  -- Señales para ID/EX Stage
  --Instruction memory:
  signal PC_reg_EX      : std_logic_vector(31 downto 0); -- PC_EX
  signal PC_plus4_EX    : std_logic_vector(31 downto 0); -- PCPlus4_EX
  signal Instruction_EX1: std_logic_vector(2 downto 0); -- Instr_EX1
  signal Instruction_EX2: std_logic_vector(4 downto 0); -- Instr_EX2
  signal Instruction_EX3: std_logic_vector(6 downto 0); -- Instr_EX3
  --Immediate Generator:
  signal Imm_ext_ID     : std_logic_vector(31 downto 0); -- Imm_Gen_ID
  signal Imm_ext_EX     : std_logic_vector(31 downto 0); -- Imm_Gen_EX
  --Register Bank:
  signal reg_RS1_ID     : std_logic_vector(31 downto 0); -- RD1_ID
  signal reg_RS1_EX     : std_logic_vector(31 downto 0); -- RD1_EX
  signal reg_RS2_ID     : std_logic_vector(31 downto 0); -- RD2_ID
  signal reg_RS2_EX     : std_logic_vector(31 downto 0); -- RD2_EX
  --Control Unit:
  signal Ctrl_Jal_ID    : std_logic;                     -- Jal_ID
  signal Ctrl_Jal_EX    : std_logic;                     -- Jal_EX
  signal Ctrl_Jalr_ID   : std_logic;                     -- Jalr_ID
  signal Ctrl_Jalr_EX   : std_logic;                     -- Jalr_EX
  signal Ctrl_Branch_ID : std_logic;                     -- Branch_ID
  signal Ctrl_Branch_EX : std_logic;                     -- Branch_EX
  signal Ctrl_MemWrite_ID: std_logic;                     -- MemWrite_ID
  signal Ctrl_MemWrite_EX: std_logic;                     -- MemWrite_EX
  signal Ctrl_MemRead_ID: std_logic;                     -- MemRead_ID
  signal Ctrl_MemRead_EX: std_logic;                     -- MemRead_EX
  signal Ctrl_ALUSrc_ID : std_logic;                     -- ALUSrc_ID
  signal Ctrl_ALUSrc_EX : std_logic;                     -- ALUSrc_EX
  signal Ctrl_RegWrite_ID: std_logic;                     -- RegWrite_ID
  signal Ctrl_RegWrite_EX: std_logic;                     -- RegWrite_EX
  signal Ctrl_ALUOp_ID  : std_logic_vector(2 downto 0);  -- ALUOp_ID
  signal Ctrl_ALUOp_EX  : std_logic_vector(2 downto 0);  -- ALUOp_EX
  signal Ctrl_PcLui_ID  : std_logic_vector(1 downto 0);  -- PCIui_ID
  signal Ctrl_PcLui_EX  : std_logic_vector(1 downto 0);  -- PCIui_EX
  signal Ctrl_ResSrc_ID : std_logic_vector(1 downto 0);  -- ResSrc_ID
  signal Ctrl_ResSrc_EX : std_logic_vector(1 downto 0);  -- ResSrc_EX

  -- Señales para EX/MEM Stage
  --ALU:
  signal Alu_ZERO_EX    : std_logic;                     -- ALUZero_EX
  signal Alu_ZERO_MEM   : std_logic;                     -- ALUZero_MEM
  signal Alu_SIGN_EX    : std_logic;                     -- ALUSign_EX
  signal Alu_SIGN_MEM   : std_logic;                     -- ALUSign_MEM
  signal Alu_Res_EX     : std_logic_vector(31 downto 0); -- ALUResult_EX
  signal Alu_Res_MEM    : std_logic_vector(31 downto 0); -- ALUResult_MEM
  --Instruction memory:
  signal PC_plus4_MEM   : std_logic_vector(31 downto 0); -- PCPlus4_MEM
  signal Instruction_MEM1: std_logic_vector(2 downto 0); -- Instr_MEM1
  signal Instruction_MEM2: std_logic_vector(4 downto 0); -- Instr_MEM2
  --Register Bank:
  signal reg_RS2_MEM    : std_logic_vector(31 downto 0); -- RD2_MEM
  --Saltos:
  signal Addr_Jump_dest_EX: std_logic_vector(31 downto 0); -- Addr_Jump_EX
  signal Addr_Jump_dest_MEM: std_logic_vector(31 downto 0); -- Addr_Jump_MEM
  --Control Unit:
  signal Ctrl_Jal_MEM   : std_logic;                     -- Jal_MEM
  signal Ctrl_Jalr_MEM  : std_logic;                     -- Jalr_MEM
  signal Ctrl_Branch_MEM: std_logic;                     -- Branch_MEM
  signal Ctrl_MemWrite_MEM: std_logic;                     -- MemWrite_MEM
  signal Ctrl_MemRead_MEM: std_logic;                     -- MemRead_MEM
  signal Ctrl_RegWrite_MEM: std_logic;                     -- RegWrite_MEM
  signal Ctrl_ResSrc_MEM: std_logic_vector(1 downto 0);  -- ResSrc_MEM

  -- Señales para MEM/WB Stage
  --ALU:
  signal Alu_Res_WB     : std_logic_vector(31 downto 0); -- ALUResult_WB
  --Read Data:
  signal reg_RD_data_MEM: std_logic_vector(31 downto 0); -- ReadData_MEM
  signal reg_RD_data_WB: std_logic_vector(31 downto 0); -- ReadData_WB
  --Instruction memory:
  signal PC_plus4_WB    : std_logic_vector(31 downto 0); -- PCPlus4_WB
  signal Instruction_WB : std_logic_vector(4 downto 0); -- Instr_WB
  --Control Unit:
  signal Ctrl_RegWrite_WB: std_logic;                     -- RegWrite_WB
  signal Ctrl_ResSrc_WB : std_logic_vector(1 downto 0);  -- ResSrc_WB


begin

  ---------------------------------------------------------------------------------------------------
  -- IF stage
  PC_next <= Addr_Jump_dest_MEM when decision_Jump = '1' else PC_plus4_IF;
  ---------------------------------------------------------------------------------------------------
  -- Pipeline reg: IF/ID
  IF_ID_reg: process(clk,reset)
  begin
    if reset = '1' then
      --Instruction memory:
      PC_reg_ID <= (others=>'0'); -- PC_ID
      PC_plus4_ID <= (others=>'0'); -- PCPlus4_ID
      Instruction_ID <= (others=>'0'); -- Instr_ID
    elsif rising_edge(clk) then
      --Instruction memory:
      PC_reg_ID <= PC_reg_IF; -- PC_ID
      PC_plus4_ID <= PC_plus4_IF; -- PCPlus4_ID
      Instruction_ID <= Instruction_IF; -- Instr_ID
    end if;
  end process;
  ---------------------------------------------------------------------------------------------------
  -- Pipeline reg: ID/EX
  ID_EX_reg: process(clk,reset)
  begin
    if reset = '1' then
      --Instruction memory:
      PC_reg_EX <= (others=>'0'); -- PC_EX
      PC_plus4_EX <= (others=>'0'); -- PCPlus4_EX
      Instruction_EX1 <= (others=>'0'); -- Instr_EX1
      Instruction_EX2 <= (others=>'0'); -- Instr_EX2
      Instruction_EX3 <= (others=>'0'); -- Instr_EX3
      --Immediate Generator:
      Imm_ext_EX <= (others=>'0'); -- Imm_Gen_EX
      --Register Bank:
      reg_RS1_EX <= (others=>'0'); -- RD1_EX
      reg_RS2_EX <= (others=>'0'); -- RD2_EX
      --Control Unit:
      Ctrl_Jal_EX <= '0'; -- Jal_EX
      Ctrl_Jalr_EX <= '0'; -- Jalr_EX
      Ctrl_Branch_EX <= '0'; -- Branch_EX
      Ctrl_MemWrite_EX <= '0'; -- MemWrite_EX
      Ctrl_MemRead_EX <= '0'; -- MemRead_EX
      Ctrl_ALUSrc_EX <= '0'; -- ALUSrc_EX
      Ctrl_RegWrite_EX <= '0'; -- RegWrite_EX
      Ctrl_ALUOp_EX <= (others=>'0'); -- ALUOp_EX
      Ctrl_PcLui_EX <= (others=>'0'); -- PCIui_EX
      Ctrl_ResSrc_EX <= (others=>'0'); -- ResSrc_EX
    elsif rising_edge(clk) then
      --Instruction memory:
      PC_reg_EX <= PC_reg_ID; -- PC_EX
      PC_plus4_EX <= PC_plus4_ID; -- PCPlus4_EX
      Instruction_EX1 <= Instruction_ID(14 downto 12); -- Instr_EX1
      Instruction_EX2 <= Instruction_ID(11 downto 7); -- Instr_EX2
      Instruction_EX3 <= Instruction_ID(31 downto 24); -- Instr_EX3
      --Immediate Generator:
      Imm_ext_EX <= Imm_ext_ID; -- Imm_Gen_EX
      --Register Bank:
      reg_RS1_EX <= reg_RS1_ID; -- RD1_EX
      reg_RS2_EX <= reg_RS2_ID; -- RD2_EX
      --Control Unit:
      Ctrl_Jal_EX <= Ctrl_Jal_ID; -- Jal_EX
      Ctrl_Jalr_EX <= Ctrl_Jalr_ID; -- Jalr_EX
      Ctrl_Branch_EX <= Ctrl_Branch_ID; -- Branch_EX
      Ctrl_MemWrite_EX <= Ctrl_MemWrite_ID; -- MemWrite_EX
      Ctrl_MemRead_EX <= Ctrl_MemRead_ID; -- MemRead_EX
      Ctrl_ALUSrc_EX <= Ctrl_ALUSrc_ID; -- ALUSrc_EX
      Ctrl_RegWrite_EX <= Ctrl_RegWrite_ID; -- RegWrite_EX
      Ctrl_ALUOp_EX <= Ctrl_ALUOp_ID; -- ALUOp_EX
      Ctrl_PcLui_EX <= Ctrl_PcLui_ID; -- PCIui_EX
      Ctrl_ResSrc_EX <= Ctrl_ResSrc_ID; -- ResSrc_EX
    end if;
  end process;
  ---------------------------------------------------------------------------------------------------
  -- Pipeline reg: EX/MEM
  EX_MEM_reg: process(clk,reset)
  begin
    if reset = '1' then
      --ALU:
      Alu_ZERO_MEM <= '0'; -- ALUZero_MEM
      Alu_SIGN_MEM <= '0'; -- ALUSign_MEM
      Alu_Res_MEM <= (others=>'0'); -- ALUResult_MEM
      --Instruction memory:
      PC_plus4_MEM <= (others=>'0'); -- PCPlus4_MEM
      Instruction_MEM1 <= (others=>'0'); -- Instr_MEM1
      Instruction_MEM2 <= (others=>'0'); -- Instr_MEM2
      --Register Bank:
      reg_RS2_MEM <= (others=>'0'); -- RD2_MEM
      --Saltos:
      Addr_Jump_dest_MEM <= (others=>'0'); -- Addr_Jump_MEM
      --Control Unit:
      Ctrl_Jal_MEM <= '0'; -- Jal_MEM
      Ctrl_Jalr_MEM <= '0'; -- Jalr_MEM
      Ctrl_Branch_MEM <= '0'; -- Branch_MEM
      Ctrl_MemWrite_MEM <= '0'; -- MemWrite_MEM
      Ctrl_MemRead_MEM <= '0'; -- MemRead_MEM
      Ctrl_RegWrite_MEM <= '0'; -- RegWrite_MEM
      Ctrl_ResSrc_MEM <= (others=>'0'); -- ResSrc_MEM
    elsif rising_edge(clk) then
      --ALU:
      Alu_ZERO_MEM <= Alu_ZERO_EX; -- ALUZero_MEM
      Alu_SIGN_MEM <= Alu_SIGN_EX; -- ALUSign_MEM
      Alu_Res_MEM <= Alu_Res_EX; -- ALUResult_MEM
      --Instruction memory:
      PC_plus4_MEM <= PC_plus4_EX; -- PCPlus4_MEM
      Instruction_MEM1 <= Instruction_EX1; -- Instr_MEM1
      Instruction_MEM2 <= Instruction_EX2; -- Instr_MEM2
      --Register Bank:
      reg_RS2_MEM <= reg_RS2_EX; -- RD2_MEM
      --Saltos:
      Addr_Jump_dest_MEM <= Addr_Jump_dest_EX; -- Addr_Jump_MEM
      --Control Unit:
      Ctrl_Jal_MEM <= Ctrl_Jal_EX; -- Jal_MEM
      Ctrl_Jalr_MEM <= Ctrl_Jalr_EX; -- Jalr_MEM
      Ctrl_Branch_MEM <= Ctrl_Branch_EX; -- Branch_MEM
      Ctrl_MemWrite_MEM <= Ctrl_MemWrite_EX; -- MemWrite_MEM
      Ctrl_MemRead_MEM <= Ctrl_MemRead_EX; -- MemRead_MEM
      Ctrl_RegWrite_MEM <= Ctrl_RegWrite_EX; -- RegWrite_MEM
      Ctrl_ResSrc_MEM <= Ctrl_ResSrc_EX; -- ResSrc_MEM
    end if;
  end process;
  ---------------------------------------------------------------------------------------------------
  -- Pipeline reg: MEM/WB
  MEM_WB_reg: process(clk,reset)
  begin
    if reset = '1' then
      --ALU:
      Alu_Res_WB <= (others=>'0'); -- ALUResult_WB
      --Read Data:
      reg_RD_data_WB <= (others=>'0'); -- ReadData_WB
      --Instruction memory:
      PC_plus4_WB <= (others=>'0'); -- PCPlus4_WB
      Instruction_WB <= (others=>'0'); -- Instr_WB
      --Control Unit:
      Ctrl_RegWrite_WB <= '0'; -- RegWrite_WB
      Ctrl_ResSrc_WB <= (others=>'0'); -- ResSrc_WB
    elsif rising_edge(clk) then
      --ALU:
      Alu_Res_WB <= Alu_Res_MEM; -- ALUResult_WB
      --Read Data:
      reg_RD_data_WB <= reg_RD_data_MEM; -- ReadData_WB
      --Instruction memory:
      PC_plus4_WB <= PC_plus4_MEM; -- PCPlus4_WB
      Instruction_WB <= Instruction_MEM2; -- Instr_WB
      --Control Unit:
      Ctrl_RegWrite_WB <= Ctrl_RegWrite_MEM; -- RegWrite_WB
      Ctrl_ResSrc_WB <= Ctrl_ResSrc_MEM; -- ResSrc_WB
    end if;
  end process;

  ---------------------------------------------------------------------------------------------------
  -- Program Counter
  PC_reg_proc: process(Clk, Reset)
  begin
    if Reset = '1' then
      PC_reg_IF <= (22 => '1', others => '0'); -- 0040_0000
    elsif rising_edge(Clk) then
      PC_reg_IF <= PC_next;
    end if;
  end process;

  PC_plus4_IF <= PC_reg_IF + 4;
  IAddr       <= PC_reg_IF;
  Instruction_IF <= IDataIn;
  Funct3      <= Instruction_EX1; -- Campo "funct3" de la instruccion
  Funct7      <= Instruction_EX3; -- Campo "funct7" de la instruccion
  RD          <= Instruction_EX2;
  RS1         <= Instruction_ID(19 downto 15);
  RS2         <= Instruction_ID(24 downto 20);

  RegsRISCV : reg_bank
  port map (
    Clk   => Clk,
    Reset => Reset,
    A1    => RS1, --Instruction(19 downto 15), --rs1
    Rd1   => reg_RS1_ID,
    A2    => RS2, --Instruction(24 downto 20), --rs2
    Rd2   => reg_RS2_ID,
    A3    => RD, --Instruction(11 downto 7),,
    Wd3   => reg_RD_data,
    We3   => Ctrl_RegWrite_WB
  );

  UnidadControl : control_unit
  port map(
    OpCode   => Instruction_ID(6 downto 0),
    -- Señales para el PC
    Branch   => Ctrl_Branch_ID,
    Ins_Jal  => Ctrl_Jal_ID,
    Ins_Jalr => Ctrl_Jalr_ID,
    -- Señales para la memoria y seleccion dato escritura registros
    ResultSrc=> Ctrl_ResSrc_ID,
    MemWrite => Ctrl_MemWrite_ID,
    MemRead  => Ctrl_MemRead_ID,
    -- Señales para la ALU
    ALUSrc   => Ctrl_ALUSrc_ID,
    AuipcLui => Ctrl_PcLui_ID,
    ALUOp    => Ctrl_ALUOp_ID,
    -- Señales para el GPR
    RegWrite => Ctrl_RegWrite_ID
  );

  immed_op : Imm_Gen
  port map (
        instr    => Instruction_ID,
        imm      => Imm_ext_ID
  );

  Addr_BranchJal <= PC_reg_EX  + Imm_ext_EX;
  Addr_Jalr      <= reg_RS1_EX + Imm_ext_EX;

  decision_Jump  <= Ctrl_Jal_MEM or Ctrl_Jalr_MEM or (Ctrl_Branch_MEM and branch_true);
  branch_true    <= '1' when ( ((Funct3 = BR_F3_BEQ) and (Alu_ZERO_MEM = '1')) or
                               ((Funct3 = BR_F3_BNE) and (Alu_ZERO_MEM = '0')) or
                               ((Funct3 = BR_F3_BLT) and (Alu_SIGN_MEM = '1')) or
                               ((Funct3 = BR_F3_BGE) and (Alu_SIGN_MEM = '0')) ) else
                    '0';
 
  Addr_Jump_dest_EX <= Addr_Jalr   when Ctrl_Jalr_EX = '1' else
                    Addr_BranchJal when (Ctrl_Branch_EX ='1') or (Ctrl_Jal_EX ='1') else
                    (others =>'0');

  Alu_control_i: alu_control
  port map(
    -- Entradas:
    ALUOp   => Ctrl_ALUOp_EX, -- Codigo de control desde la unidad de control
    Funct3  => Funct3,    -- Campo "funct3" de la instruccion
    Funct7  => Funct7,    -- Campo "funct7" de la instruccion
    -- Salida de control para la ALU:
    ALUControl => AluControl -- Define operacion a ejecutar por la ALU
  );

  Alu_RISCV : alu_RV
  port map (
    OpA      => Alu_Op1,
    OpB      => Alu_Op2,
    Control  => AluControl,
    Result   => Alu_Res_EX,
    Signflag => Alu_SIGN_EX,
    CarryOut => open,
    Zflag    => Alu_ZERO_EX
  );

  Alu_Op1    <= PC_reg_EX        when Ctrl_PcLui_EX = "00" else
                (others => '0')  when Ctrl_PcLui_EX = "01" else
                reg_RS1_EX; -- any other 
  Alu_Op2    <= reg_RS2_EX when Ctrl_ALUSrc_EX = '0' else Imm_ext_EX;


  DAddr      <= Alu_Res_MEM;
  DDataOut   <= reg_RS2_MEM;
  DWrEn      <= Ctrl_MemWrite_MEM;
  DRdEn      <= Ctrl_MemRead_MEM;
  dataIn_Mem <= DDataIn;

  reg_RD_data_MEM <= dataIn_Mem when Ctrl_ResSrc_WB = "01" else
                 PC_plus4_WB   when Ctrl_ResSrc_WB = "10" else 
                 Alu_Res_WB; -- When 00

end architecture;
