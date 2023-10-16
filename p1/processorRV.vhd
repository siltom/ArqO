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

  signal Alu_Op1      : std_logic_vector(31 downto 0);
  signal Alu_Op2      : std_logic_vector(31 downto 0);
  signal Alu_ZERO     : std_logic;
  signal Alu_SIGN     : std_logic;
  signal AluControl   : std_logic_vector(3 downto 0);
  signal reg_RD_data  : std_logic_vector(31 downto 0);

  signal branch_true    : std_logic;
  signal PC_next        : std_logic_vector(31 downto 0);
  signal PC_reg         : std_logic_vector(31 downto 0);
  signal PC_plus4       : std_logic_vector(31 downto 0);

  signal Instruction    : std_logic_vector(31 downto 0); -- La instrucción desde lamem de instr
  signal Imm_ext        : std_logic_vector(31 downto 0); -- La parte baja de la instrucción extendida de signo
  signal reg_RS1        : std_logic_vector(31 downto 0);
  signal reg_RS2        : std_logic_vector(31 downto 0);

  signal dataIn_Mem     : std_logic_vector(31 downto 0); -- Dato desde memoria
  signal Addr_BranchJal : std_logic_vector(31 downto 0);

  signal Ctrl_Jal, Ctrl_Jalr, Ctrl_Branch, Ctrl_MemWrite, Ctrl_MemRead,  Ctrl_ALUSrc, Ctrl_RegWrite : std_logic;
  
  signal Ctrl_ALUOp     : std_logic_vector(2 downto 0);
  signal Ctrl_PcLui     : std_logic_vector(1 downto 0);
  signal Ctrl_ResSrc    : std_logic_vector(1 downto 0);

  signal Addr_Jalr      : std_logic_vector(31 downto 0);
  signal Addr_Jump_dest : std_logic_vector(31 downto 0);
  signal decision_Jump  : std_logic;
  signal Alu_Res        : std_logic_vector(31 downto 0);
  -- Instruction fields:
  signal Funct3         : std_logic_vector(2 downto 0);
  signal Funct7         : std_logic_vector(6 downto 0);
  signal RS1, RS2, RD   : std_logic_vector(4 downto 0);


  -- Señales para IF/ID Stage
  signal pc_ID          : std_logic_vector(31 downto 0);
  signal instruccion_ID : std_logic_vector(31 downto 0);
  
  -- Señales para ID/EX Stage
  signal Branch_EX, ResultSrc_EX, MemWrite_EX, MemRead_EX, ALUSrc_EX, RegWrite_EX: std_logic;
  signal ALUOp_EX: std_logic_vector(3 downto 0);
  signal pc_EX: std_logic_vector(31 downto 0);
  signal OpA_EX, OpB_EX, Imm_ext_EX: std_logic_vector(31 downto 0);
  signal A1_EX, A2_EX : std_logic_vector(4 downto 0);

  -- Señales para EX/MEM Stage
  signal ALUOp_MEM: std_logic_vector(2 downto 0);
  signal Funct3_MEM: std_logic_vector (2 downto 0);
  signal Funct7_MEM: std_logic_vector (6 downto 0);
  signal OpA_MEM, OpB_MEM: std_logic_vector (31 downto 0);
  signal Control_MEM: std_logic_vector (3 downto 0);
  signal Result_MEM: std_logic_vector (31 downto 0);
  signal Branch_MEM, ResultSrc_MEM, MemWrite_MEM, MemRead_MEM, ALUSrc_MEM, RegWrite_MEM: std_logic;
  signal ALUOp_MEM: std_logic_vector(3 downto 0);
  signal pc_MEM: std_logic_vector(31 downto 0);

  -- Señales para MEM/WB Stage
  signal ResultSrc_WB, RegWrite_WB: std_logic;
  signal Result_WB: std_logic_vector(31 downto 0);

begin

  ---------------------------------------------------------------------------------------------------
  -- IF stage
  PC_next <= Addr_Jump_dest when decision_Jump = '1' else PC_plus4;
  ---------------------------------------------------------------------------------------------------
  -- Pipeline reg: IF/ID
  IF_ID_reg: process(clk,reset)
  begin
    if reset = '1' then
      pc_ID <= (others=>'0');
      instruccion_ID <= (others=>'0');
    elsif rising_edge(clk) then
      pc_ID <= PC_plus4;
      instrucción_ID <= IDataIn;
    end if;
  end process;
  ---------------------------------------------------------------------------------------------------
  -- Pipeline reg: ID/EX
  ID_EX_reg: process(clk,reset)
  begin
    if reset = '1' then
      -- Unidad de Control:
      Branch_EX <= '0';
      ResultSrc_EX <= '0';
      MemWrite_EX <= '0';
      MemRead_EX <= '0';
      ALUSrc_EX <= '0';
      RegWrite_EX <= '0';
      ALUOp_EX <= (others=>'0');
      -- PC:
      PC_EX <= (others=>'0');
      -- Banco de registros:
      OpA_EX <= (others=>'0');
      OpB_EX <= (others=>'0');
      A1_EX <= (others=>'0');
      A2_EX <= (others=>'0');
      -- Generador de inmediatos:
      Imm_ext_EX <= (others=>'0');
    elsif rising_edge(clk) then
      -- Unidad de Control:
      Branch_EX <= Branch;
      ResultSrc_EX <= ResultSrc;
      MemWrite_EX <= MemWrite;
      MemRead_EX <= MemRead;
      ALUSrc_EX <= ALUSrc;
      RegWrite_EX <= RegWrite;
      ALUOp_EX <= ALUOp;
      -- PC:
      pc_EX <= pc_ID;
      -- Banco de registros:
      OpA_EX <= OpA;
      OpB_EX <= OpB;
      A1_EX <= A1;
      A2_EX <= A2;
      -- Generador de inmediatos:
      Imm_ext_EX <= Imm_ext;
    end if;
  end process;

  ---------------------------------------------------------------------------------------------------
  -- Pipeline reg: EX/MEM
  EX_MEM_reg: process(clk,reset)
  begin
    if reset = '1' then
      -- ALU:
      ALUOp_MEM <= (others=>'0');
      Funct3_MEM <= (others=>'0');
      Funct7_MEM <= (others=>'0');
      OpA_MEM <= (others=>'0');
      OpB_MEM <= (others=>'0');
      Control_MEM <= (others=>'0');
      Result_MEM <= (others=>'0');
      -- Unidad de Control:
      Branch_MEM <= '0';
      ResultSrc_MEM <= '0';
      MemWrite_MEM <= '0';
      MemRead_MEM <= '0';
      ALUSrc_MEM <= '0';
      RegWrite_MEM <= '0';
      ALUOp_MEM <= (others=>'0');
      -- PC:
      pc_MEM <= (others=>'0');
    elsif rising_edge(clk) then
      -- ALU:
      ALUOp_MEM <= ALUOp_EX;
      Funct3_MEM <= Instruccion_ID(14 downto 12);
      Funct7_MEM <= Instruccion_ID(31 downto 24);
      OpA_MEM <= OpA_EX;
      OpB_MEM <= OpB_EX;
      Control_MEM <= ALUControl;
      Result_MEM <= Result;
      -- Unidad de Control:
      Branch_MEM <= Branch_EX;
      ResultSrc_MEM <= ResultSrc_EX;
      MemWrite_MEM <= MemWrite_EX;
      MemRead_MEM <= MemRead_EX;
      ALUSrc_MEM <= ALUSrc_EX;
      RegWrite_MEM <= RegWrite_EX;
      -- PC:
      pc_MEM <= pc_EX;
  ---------------------------------------------------------------------------------------------------
  -- Pipeline reg: MEM/WB
  MEM_WB_reg: process(clk,reset)
  begin
    if reset = '1' then
      ResultSrc_WB <= '0';
      RegWrite_WB <= '0';
      Result_WB <= (others => '0');
    elsif rising_edge(clk) then
      ResultSrc_WB <= ResultSrc_MEM;
      RegWrite_WB <= RegWrite_MEM;
      Result_WB <= Result_MEM;
      
  ---------------------------------------------------------------------------------------------------

  -- Program Counter
  PC_reg_proc: process(Clk, Reset)
  begin
    if Reset = '1' then
      PC_reg <= (22 => '1', others => '0'); -- 0040_0000
    elsif rising_edge(Clk) then
      PC_reg <= PC_next;
    end if;
  end process;

  PC_plus4    <= PC_reg + 4;
  IAddr       <= PC_reg;
  Instruction <= IDataIn;
  Funct3      <= instruction(14 downto 12); -- Campo "funct3" de la instruccion
  Funct7      <= instruction(31 downto 25); -- Campo "funct7" de la instruccion
  RD          <= Instruction(11 downto 7);
  RS1         <= Instruction(19 downto 15);
  RS2         <= Instruction(24 downto 20);

  RegsRISCV : reg_bank
  port map (
    Clk   => Clk,
    Reset => Reset,
    A1    => RS1, --Instruction(19 downto 15), --rs1
    Rd1   => reg_RS1,
    A2    => RS2, --Instruction(24 downto 20), --rs2
    Rd2   => reg_RS2,
    A3    => RD, --Instruction(11 downto 7),,
    Wd3   => reg_RD_data,
    We3   => Ctrl_RegWrite
  );

  UnidadControl : control_unit
  port map(
    OpCode   => Instruction(6 downto 0),
    -- Señales para el PC
    Branch   => Ctrl_Branch,
    Ins_Jal  => Ctrl_Jal,
    Ins_Jalr => Ctrl_Jalr,
    -- Señales para la memoria y seleccion dato escritura registros
    ResultSrc=> Ctrl_ResSrc,
    MemWrite => Ctrl_MemWrite,
    MemRead  => Ctrl_MemRead,
    -- Señales para la ALU
    ALUSrc   => Ctrl_ALUSrc,
    AuipcLui => Ctrl_PcLui,
    ALUOp    => Ctrl_ALUOp,
    -- Señales para el GPR
    RegWrite => Ctrl_RegWrite
  );

  immed_op : Imm_Gen
  port map (
        instr    => Instruction,
        imm      => Imm_ext 
  );

  Addr_BranchJal <= PC_reg  + Imm_ext;
  Addr_Jalr      <= reg_RS1 + Imm_ext;

  decision_Jump  <= Ctrl_Jal or Ctrl_Jalr or (Ctrl_Branch and branch_true);
  branch_true    <= '1' when ( ((Funct3 = BR_F3_BEQ) and (Alu_ZERO = '1')) or
                               ((Funct3 = BR_F3_BNE) and (Alu_ZERO = '0')) or
                               ((Funct3 = BR_F3_BLT) and (Alu_SIGN = '1')) or
                               ((Funct3 = BR_F3_BGE) and (Alu_SIGN = '0')) ) else
                    '0';
 
  Addr_Jump_dest <= Addr_Jalr   when Ctrl_Jalr = '1' else
                    Addr_BranchJal when (Ctrl_Branch='1') or (Ctrl_Jal='1') else
                    (others =>'0');

  Alu_control_i: alu_control
  port map(
    -- Entradas:
    ALUOp   => Ctrl_ALUOp, -- Codigo de control desde la unidad de control
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
    Result   => Alu_Res,
    Signflag => Alu_SIGN,
    CarryOut => open,
    Zflag    => Alu_ZERO
  );

  Alu_Op1    <= PC_reg           when Ctrl_PcLui = "00" else
                (others => '0')  when Ctrl_PcLui = "01" else
                reg_RS1; -- any other 
  Alu_Op2    <= reg_RS2 when Ctrl_ALUSrc = '0' else Imm_ext;


  DAddr      <= Alu_Res;
  DDataOut   <= reg_RS2;
  DWrEn      <= Ctrl_MemWrite;
  DRdEn      <= Ctrl_MemRead;
  dataIn_Mem <= DDataIn;

  reg_RD_data <= dataIn_Mem when Ctrl_ResSrc = "01" else
                 PC_plus4   when Ctrl_ResSrc = "10" else 
                 Alu_Res; -- When 00

end architecture;
