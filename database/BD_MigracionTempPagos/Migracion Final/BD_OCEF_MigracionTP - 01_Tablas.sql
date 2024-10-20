/*
======================================================
	BD_OCEF_MigracionTP - 01_Tablas
======================================================
*/


USE BD_OCEF_MigracionTP
GO

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'TR_Alumnos' AND COLUMN_NAME = 'B_ObligProc')
BEGIN
	ALTER TABLE [dbo].[TR_Alumnos]
		ADD B_ObligProc	bit  NULL
END
GO


IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'TI_ObservacionRegistroTabla' AND COLUMN_NAME = 'B_ObligProc')
BEGIN
	ALTER TABLE [dbo].[TI_ObservacionRegistroTabla]
		ADD B_ObligProc	bit  NULL
END
GO


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE = 'BASE TABLE' AND TABLE_NAME = 'TS_DataOrigen')
	DROP TABLE TS_DataOrigen
GO


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE = 'BASE TABLE' AND TABLE_NAME = 'TS_HistorialResultados')
	DROP TABLE TS_HistorialResultados
GO



IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'TR_Cp_Des' AND COLUMN_NAME = 'B_ExisteCtas')
BEGIN
	ALTER TABLE [dbo].[TR_Cp_Des]
		ADD B_ExisteCtas	bit  NULL
END
GO

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'TR_Cp_Des' AND COLUMN_NAME = 'I_CtaDepoProID')
BEGIN
	ALTER TABLE [dbo].[TR_Cp_Des]
		ADD I_CtaDepoProID	int  NULL
END
GO


IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'TR_Cp_Pri' AND COLUMN_NAME = 'B_ExisteCtas')
BEGIN
	ALTER TABLE [dbo].[TR_Cp_Pri]
		ADD B_ExisteCtas	bit  NULL
END
GO




IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE = 'BASE TABLE' AND TABLE_NAME = 'TC_EtapaProceso')
	DROP TABLE TC_EtapaProceso
GO

CREATE TABLE dbo.TC_EtapaProceso (
	I_EtapaProcesoID tinyint  NOT NULL,
	T_EtapaProcDesc	 varchar(100)  NOT NULL
)
GO



IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE = 'BASE TABLE' AND TABLE_NAME = 'TR_ControlTablas')
	DROP TABLE TR_ControlTablas
GO

CREATE TABLE dbo.TR_ControlTablas (
	I_ControlID		 int IDENTITY (1, 1),
	I_TablaID		 tinyint  NOT NULL,
	I_ProcedenciaID	 tinyint  NOT NULL,
	I_Anio			 int  NOT NULL,
	I_CurrentEtapaID tinyint  NOT NULL,
	I_TotalCopiar	 int  NULL,
	I_CountCopiados	 int  NULL,
	I_CountSnCopiar	 int  NULL,
	D_LastCopia		 datetime  NULL,
	I_TotalValidar	 int  NULL,
	I_CountValidados int  NULL,
	I_CountSnValidar int  NULL,
	D_LastValidacion datetime  NULL,
	I_TotalMigrar	 int  NULL,
	I_CountMigrados  int  NULL,
	I_CountSnMigrar  int  NULL,
	D_LastMigracion  datetime  NULL,
	B_Habilitado	 bit  NOT NULL DEFAULT (1)
)
GO

ALTER TABLE dbo.TR_ControlTablas 
	ADD CONSTRAINT PK_ControlTablas PRIMARY KEY (I_ControlID)
GO


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE = 'BASE TABLE' AND TABLE_NAME = 'TR_Tasas_Ec_Obl')
	DROP TABLE TR_Tasas_Ec_Obl
GO

CREATE TABLE dbo.TR_Tasas_Ec_Obl (
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
	CONSTRAINT PK_TasasEcObl PRIMARY KEY (I_RowID)
) 
GO


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE = 'BASE TABLE' AND TABLE_NAME = 'TR_Tasas_Ec_Det')
	DROP TABLE TR_Tasas_Ec_Det
GO


CREATE TABLE dbo.TR_Tasas_Ec_Det (
	I_RowID			bigint IDENTITY(1, 1) NOT NULL,
	I_OblRowID		int  NULL,
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
	CONSTRAINT PK_TasasEcDet PRIMARY KEY (I_RowID),
	CONSTRAINT FK_TasasEcObl_TasasEcDet FOREIGN KEY (I_OblRowID) REFERENCES TR_Tasas_Ec_Obl(I_RowID)
) 
GO



IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE = 'BASE TABLE' AND TABLE_NAME = 'TR_Tasas_Ec_Det_Pagos')
	DROP TABLE TR_Tasas_Ec_Det_Pagos
GO

CREATE TABLE dbo.TR_Tasas_Ec_Det_Pagos (
	I_RowID			bigint IDENTITY(1, 1) NOT NULL,
	I_OblRowID		int  NULL,
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
	CONSTRAINT PK_TasasEcDetPagos PRIMARY KEY (I_RowID),
	CONSTRAINT FK_TasasEcObl_TasasEcDetPagos FOREIGN KEY (I_OblRowID) REFERENCES TR_Tasas_Ec_Obl(I_RowID)
) 
GO

