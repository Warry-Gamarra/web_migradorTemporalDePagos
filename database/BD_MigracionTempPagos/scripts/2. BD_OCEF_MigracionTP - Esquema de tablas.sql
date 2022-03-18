USE [BD_OCEF_MigracionTP]
GO

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE = 'BASE TABLE' AND TABLE_NAME = 'TR_Ec_Pri')
	DROP TABLE TR_Ec_Pri
GO

CREATE TABLE TR_Ec_Pri (
	I_RowID			int IDENTITY(1, 1) NOT NULL,
	Cod_alu			varchar(20)  NULL,
	Cod_rc			varchar(3) NULL,
	Tot_apagar		decimal(10,2)  NULL,
	Nro_ec			bigint  NULL,
	Fch_ec			date  NULL,
	Tot_pagado		float  NULL,
	Saldo			decimal(10,2)  NULL,
	Ano				varchar(4) NULL,
	P				varchar(3) NULL,
	Eliminado		bit  NULL,
	I_ProcedenciaID	int  NOT NULL,
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


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE = 'BASE TABLE' AND TABLE_NAME = 'TR_Ec_Obl')
	DROP TABLE TR_Ec_Obl
GO

CREATE TABLE dbo.TR_Ec_Obl (
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


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE = 'BASE TABLE' AND TABLE_NAME = 'TR_Ec_Det')
	DROP TABLE TR_Ec_Det
GO

CREATE TABLE TR_Ec_Det (
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

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE = 'BASE TABLE' AND TABLE_NAME = 'TR_Cp_Des')
	DROP TABLE TR_Cp_Des
GO

CREATE TABLE TR_Cp_Des(
	I_RowID			int IDENTITY(1, 1) NOT NULL,
	Cuota_pago		int  NULL,
	Descripcio		varchar(50)  NULL,
	N_cta_cte		varchar(50)  NULL,
	Eliminado		bit NULL,
	Codigo_bnc		varchar(10)  NULL,
	Fch_venc		date  NULL,
	Prioridad		varchar(1)  NULL,
	C_mora			bit  NULL,
	I_ProcedenciaID	int  NOT NULL,
	I_CatPagoID		int  NULL, 
	I_Anio			smallint  NULL,
	I_Periodo		int	 NULL,
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


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE = 'BASE TABLE' AND TABLE_NAME = 'TR_Cp_Pri')
	DROP TABLE TR_Cp_Pri
GO

CREATE TABLE TR_Cp_Pri (
	I_RowID			int IDENTITY(1, 1) NOT NULL,
	Id_cp			int  NULL,
	Cuota_pago		int  NULL,
	Ano				varchar(4) NULL,
	P				varchar(3) NULL,
	Cod_rc			varchar(3) NULL,
	Cod_ing			varchar(3) NULL,
	Tipo_oblig		bit  NULL,
	Clasificad		varchar(15) NULL,
	Clasific_5		varchar(5) NULL,
	Id_cp_agrp		int  NULL,
	Agrupa			bit  NULL,
	Nro_pagos		smallint  NULL,
	Id_cp_afec		int  NULL,
	Porcentaje		bit  NULL,
	Monto			decimal(10, 2)  NULL,
	Eliminado		bit  NULL,
	Descripcio		varchar(255)  NULL,
	Calcular		varchar(3)  NULL,
	Grado			tinyint  NULL,
	Tip_alumno		tinyint  NULL,
	Grupo_rc		varchar(3)  NULL,
	Fraccionab		bit  NULL,
	Concepto_g		bit  NULL,
	Documento		nvarchar(4000)  NULL,
	Monto_min		decimal(10, 2)  NULL,
	Descrip_l		nvarchar(4000)  NULL,
	Cod_dep_pl		varchar(20)  NULL,
	Oblig_mora		bit  NULL,
	I_ProcedenciaID	int  NOT NULL,
	I_TipAluID		int  NULL,
	I_TipGradoID	int  NULL,
	I_TipOblID		int  NULL,
	I_TipCalcID		int  NULL,
	I_TipPerID		int  NULL,
	I_DepID			int  NULL,
	I_TipGrpRc		int	 NULL,
	I_CodIngID		int  NULL,
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


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE = 'BASE TABLE' AND TABLE_NAME = 'TR_Alumnos')
	DROP TABLE TR_Alumnos
GO

CREATE TABLE TR_Alumnos
(
	I_RowID			int IDENTITY(1, 1) NOT NULL,
	C_RcCod			varchar(3), 
	C_CodAlu		varchar(20), 
	C_NumDNI		varchar(20), 
	C_CodTipDoc		varchar(5),
	T_ApePaterno	varchar(50), 
	T_ApeMaterno	varchar(50), 
	T_Nombre		varchar(50), 
	I_ProcedenciaID	int  NOT NULL,
	C_Sexo			char(1), 
	D_FecNac		date, 
	C_CodModIng		varchar(2), 
	C_AnioIngreso	smallint, 
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

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE = 'BASE TABLE' AND TABLE_NAME = 'TC_ProcedenciaData')
	DROP TABLE TC_ProcedenciaData
GO

CREATE TABLE TC_ProcedenciaData
(
	I_ProcedenciaID		tinyint,
	T_ProcedenciaDesc	varchar(100)
	CONSTRAINT PK_ProcedenciaData PRIMARY KEY (I_ProcedenciaID)
)
GO



IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE = 'BASE TABLE' AND TABLE_NAME = 'TI_ObservacionRegistroTabla')
	DROP TABLE TI_ObservacionRegistroTabla
GO

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE = 'BASE TABLE' AND TABLE_NAME = 'TC_CatalogoObservacion')
	DROP TABLE TC_CatalogoObservacion
GO

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE = 'BASE TABLE' AND TABLE_NAME = 'TC_CatalogoTabla')
	DROP TABLE TC_CatalogoTabla
GO


CREATE TABLE TC_CatalogoObservacion
(
	I_ObservID		tinyint,
	T_ObservDesc	varchar(100),
	T_ObservCod		varchar(20),
	I_Severidad		smallint,
	CONSTRAINT PK_CatalogoObservacion PRIMARY KEY (I_ObservID)
)
GO


CREATE TABLE TC_CatalogoTabla
(
	I_TablaID	tinyint,
	T_TablaNom	varchar(50)
	CONSTRAINT PK_CatalogoTabla PRIMARY KEY (I_TablaID)
)
GO


CREATE TABLE TI_ObservacionRegistroTabla
(
	I_ObsTablaID	int IDENTITY(1, 1),
	I_ObservID		tinyint,
	I_TablaID		tinyint,
	I_FilaTablaID	int,
	D_FecRegistro	datetime,
	CONSTRAINT PK_ObservacionRegistroTabla PRIMARY KEY (I_ObsTablaID),
	CONSTRAINT FK_CatalogoObservacion_ObservacionRegistroTabla FOREIGN KEY (I_ObservID) REFERENCES TC_CatalogoObservacion (I_ObservID),
	CONSTRAINT FK_CatalogoTabla_ObservacionRegistroTabla FOREIGN KEY (I_TablaID) REFERENCES TC_CatalogoTabla (I_TablaID)
)
GO

