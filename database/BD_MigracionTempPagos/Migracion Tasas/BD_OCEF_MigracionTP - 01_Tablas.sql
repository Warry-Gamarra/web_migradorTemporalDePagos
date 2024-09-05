USE BD_OCEF_MigracionTP
GO


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE = 'BASE TABLE' AND TABLE_NAME = 'TC_EtapaProceso')
	DROP TABLE TC_EtapaProceso
GO

CREATE TABLE dbo.TC_EtapaProceso (
	I_EtapaProcesoID tinyint  NOT NULL,
	T_EtapaProcDesc	 varchar(100)  NOT NULL
)
GO



IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE = 'BASE TABLE' AND TABLE_NAME = 'TR_ControlTasas')
	DROP TABLE TR_ControlTasas
GO

CREATE TABLE dbo.TR_ControlTasas (
	I_Anio			 int  NOT NULL,
	I_TablaID		 int  NOT NULL,
	I_EtapaProcesoID int  NOT NULL,
	I_TotalOrigen	 int  NULL,
	I_CountCopiados	 int  NULL,
	I_CountSnCopiar	 int  NULL,
	D_LastCopia		 int  NULL,
	I_CountValidados int  NULL,
	D_LastValidacion int  NULL,
	I_CountSnValidar int  NULL,
	I_CountMigrados  int  NULL,
	I_CountSnMigrar  int  NULL,
	D_LastMigracion int  NULL,
)
GO



IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE = 'BASE TABLE' AND TABLE_NAME = 'TR_Tasas_Ec_Obl')
	DROP TABLE TR_Tasas_Ec_Obl
GO

CREATE TABLE dbo.TR_Ec_Obl_Tasas (
	I_RowID			int IDENTITY(1, 1) NOT NULL,
	Ano				varchar(4) NULL,
	P				varchar(3) NULL,
	I_Periodo		int	NULL,
	Cod_alu			varchar(20)  NULL,
	Cod_rc			varchar(3) NULL,
	Cuota_pago		int  NULL,
	Tipo_oblig		bit  NULL,
	Fch_venc		date  NULL,
	Monto			decimal(10,2)  NULL,
	Pagado			bit  NULL,
	I_ProcedenciaID	int  NOT NULL,
	B_Obligacion	bit  NOT NULL,
	D_FecCarga		datetime  NULL,
	B_Actualizado	bit  NOT NULL DEFAULT 0,
	D_FecActualiza	datetime  NULL,
	B_Migrable		bit  NOT NULL DEFAULT 0,
	D_FecEvalua		datetime  NULL,
	B_Migrado		bit  NOT NULL DEFAULT 0,
	D_FecMigrado	datetime  NULL,
	B_Removido		bit  NOT NULL DEFAULT 0,
	D_FecRemovido	datetime  NULL,
) 
GO




IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE = 'BASE TABLE' AND TABLE_NAME = 'TR_Tasas_Ec_Det')
	DROP TABLE TR_Tasas_Ec_Det
GO

CREATE TABLE dbo.TR_Tasas_Ec_Det (
	I_RowID			bigint IDENTITY(1, 1) NOT NULL,
	Cod_alu			varchar(20)  NULL,
	Cod_rc			varchar(3) NULL,
	Cuota_pago		int  NULL,
	Ano				varchar(4) NULL,
	P				varchar(3) NULL,
	Tipo_oblig		bit  NULL,
	Concepto		int  NULL,
	Fch_venc		date  NULL,
	Nro_recibo		varchar(20)  NULL,
	Fch_pago		date  NULL,
	Id_lug_pag		varchar(10)  NULL,
	Cantidad		decimal(10,2)  NULL,
	Monto			decimal(10,2)  NULL,
	Documento		nvarchar(4000)  NULL,
	Pagado			bit  NULL,
	Concepto_f		bit  NULL,
	Fch_elimin		date  NULL,
	Nro_ec			bigint  NULL,
	Fch_ec			date  NULL,
	Eliminado		bit  NULL,
	Pag_demas		bit  NULL,
	Cod_cajero		varchar(20)  NULL,
	Tipo_pago		bit  NULL,
	No_banco		bit  NULL,
	Cod_dep			varchar(10)  NULL,
	I_ProcedenciaID	int  NOT NULL,
	B_Obligacion	bit  NOT NULL,
	D_FecCarga		datetime  NULL,
	B_Actualizado	bit  NOT NULL DEFAULT 0,
	D_FecActualiza	datetime  NULL,
	B_Migrable		bit  NOT NULL DEFAULT 0,
	D_FecEvalua		datetime  NULL,
	B_Migrado		bit  NOT NULL DEFAULT 0,
	D_FecMigrado	datetime  NULL,
	B_Removido		bit  NOT NULL DEFAULT 0,
	D_FecRemovido	datetime  NULL,
	B_Correcto		bit  NULL,
	I_CtasPagoBncTableRowID	int,
	B_EsTasa		bit  NULL
) 
GO


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE = 'BASE TABLE' AND TABLE_NAME = 'TR_Tasas_Ec_Det_Pagos')
	DROP TABLE TR_Tasas_Ec_Det_Pagos
GO

CREATE TABLE dbo.TR_Tasas_Ec_Det_Pagos (
	I_RowID			bigint IDENTITY(1, 1) NOT NULL,
	Cod_alu			varchar(20)  NULL,
	Cod_rc			varchar(3) NULL,
	Cuota_pago		int  NULL,
	Ano				varchar(4) NULL,
	P				varchar(3) NULL,
	Tipo_oblig		bit  NULL,
	Concepto		int  NULL,
	Fch_venc		date  NULL,
	Nro_recibo		varchar(20)  NULL,
	Fch_pago		date  NULL,
	Id_lug_pag		varchar(10)  NULL,
	Cantidad		decimal(10,2)  NULL,
	Monto			decimal(10,2)  NULL,
	Documento		nvarchar(4000)  NULL,
	Pagado			bit  NULL,
	Concepto_f		bit  NULL,
	Fch_elimin		date  NULL,
	Nro_ec			bigint  NULL,
	Fch_ec			date  NULL,
	Eliminado		bit  NULL,
	Pag_demas		bit  NULL,
	Cod_cajero		varchar(20)  NULL,
	Tipo_pago		bit  NULL,
	No_banco		bit  NULL,
	Cod_dep			varchar(10)  NULL,
	I_ProcedenciaID	int  NOT NULL,
	B_Obligacion	bit  NOT NULL,
	D_FecCarga		datetime  NULL,
	B_Actualizado	bit  NOT NULL DEFAULT 0,
	D_FecActualiza	datetime  NULL,
	B_Migrable		bit  NOT NULL DEFAULT 0,
	D_FecEvalua		datetime  NULL,
	B_Migrado		bit  NOT NULL DEFAULT 0,
	D_FecMigrado	datetime  NULL,
	B_Removido		bit  NOT NULL DEFAULT 0,
	D_FecRemovido	datetime  NULL,
	B_Correcto		bit  NULL,
	I_CtasPagoBncTableRowID	int,
	B_EsTasa		bit  NULL
) 
GO

