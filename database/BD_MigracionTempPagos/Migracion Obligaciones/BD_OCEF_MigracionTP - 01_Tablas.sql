USE BD_OCEF_MigracionTP
GO

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'TR_Ec_Obl' AND COLUMN_NAME = 'B_MigradoPago')
BEGIN
	ALTER TABLE [dbo].[TR_Ec_Obl]
		ADD B_MigradoPago	bit  NULL
END
GO

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'TR_Ec_Obl' AND COLUMN_NAME = 'D_FecMigradoPago')
BEGIN
	ALTER TABLE [dbo].[TR_Ec_Obl]
		ADD D_FecMigradoPago	datetime  NULL
END
GO

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'TR_Ec_Obl' AND COLUMN_NAME = 'B_Correcto')
BEGIN
	ALTER TABLE [dbo].[TR_Ec_Obl]
		ADD B_Correcto	bit  NULL
END
GO

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'TR_Ec_Det' AND COLUMN_NAME = 'B_Correcto')
BEGIN
	ALTER TABLE [dbo].[TR_Ec_Det]
		ADD B_Correcto	bit  NULL
END
GO

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'TR_Cp_Pri' AND COLUMN_NAME = 'B_Correcto')
BEGIN
	ALTER TABLE [dbo].[TR_Cp_Pri]
		ADD B_Correcto	bit  NULL
END
GO

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'TR_Cp_Des' AND COLUMN_NAME = 'B_Correcto')
BEGIN
	ALTER TABLE [dbo].[TR_Cp_Des]
		ADD B_Correcto	bit  NULL
END
GO



IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'TR_Ec_Det' AND COLUMN_NAME = 'B_MigradoPago')
BEGIN
	ALTER TABLE [dbo].[TR_Ec_Det]
		ADD B_MigradoPago	bit  NULL
END
GO

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'TR_Ec_Det' AND COLUMN_NAME = 'D_FecMigradoPago')
BEGIN
	ALTER TABLE [dbo].[TR_Ec_Det]
		ADD D_FecMigradoPago	datetime  NULL
END
GO

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'TR_Ec_Det' AND COLUMN_NAME = 'D_FecMigradoPago')
BEGIN
	ALTER TABLE [dbo].[TR_Ec_Det]
		ADD D_FecMigradoPago	bit  NULL
END
GO


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'TC_CatalogoObservacion' AND COLUMN_NAME = 'T_ObservDesc')
BEGIN
	ALTER TABLE [dbo].[TC_CatalogoObservacion]
		ALTER COLUMN T_ObservDesc	varchar(150)  NULL
END
GO

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'TC_CatalogoObservacion' AND COLUMN_NAME = 'I_TablaID')
BEGIN
	ALTER TABLE [dbo].[TC_CatalogoObservacion]
		ADD I_TablaID	varchar(150)  NULL
END
GO



IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE = 'BASE TABLE' AND TABLE_NAME = 'TR_Ec_Det_Pagos')
	DROP TABLE TR_Ec_Det_Pagos
GO

CREATE TABLE dbo.TR_Ec_Det_Pagos (
	I_RowID			bigint IDENTITY(1, 1) NOT NULL,
	I_OblRowID		int NULL,
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
	B_Correcto		bit  NULL
) 
GO

