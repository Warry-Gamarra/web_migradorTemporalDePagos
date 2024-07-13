USE BD_OCEF_MigracionTP
GO

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE = 'BASE TABLE' AND TABLE_NAME = 'TR_Ec_Det_Tasas')
	DROP TABLE TR_Ec_Det_Tasas
GO

CREATE TABLE dbo.TR_Ec_Det_Tasas (
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
	I_CtasPagoBncTableRowID	int
) 
GO


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE = 'BASE TABLE' AND TABLE_NAME = 'TR_Ec_Det_Tasas_Pagos')
	DROP TABLE TR_Ec_Det_Tasas_Pagos
GO

CREATE TABLE dbo.TR_Ec_Det_Tasas_Pagos (
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
	I_CtasPagoBncTableRowID	int
) 
GO

