USE [BD_OCEF_MigracionTP]
GO

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE = 'BASE TABLE' AND TABLE_NAME = 'TR_MG_EcPri')
	DROP TABLE TR_MG_EcPri
GO

CREATE TABLE TR_MG_EcPri (
	I_RowID			int IDENTITY(1, 1) NOT NULL,
	COD_ALU			nvarchar(255)  NULL,
	COD_RC			nvarchar(255)  NULL,
	TOT_APAGAR		float  NULL,
	NRO_EC			float  NULL,
	FCH_EC			datetime  NULL,
	TOT_PAGADO		float  NULL,
	SALDO			float  NULL,
	ANO				nvarchar(255)  NULL,
	P				nvarchar(255)  NULL,
	ELIMINADO		bit  NULL,
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


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE = 'BASE TABLE' AND TABLE_NAME = 'TR_MG_EcObl')
	DROP TABLE TR_MG_EcObl
GO

CREATE TABLE dbo.TR_MG_EcObl (
	I_RowID			int IDENTITY(1, 1) NOT NULL,
	ANO				nvarchar(255)  NULL,
	P				nvarchar(255)  NULL,
	I_Periodo		int	NULL,
	COD_ALU			nvarchar(255)  NULL,
	COD_RC			nvarchar(255)  NULL,
	CUOTA_PAGO		float  NULL,
	TIPO_OBLIG		bit  NULL,
	FCH_VENC		datetime  NULL,
	MONTO			float  NULL,
	PAGADO			bit  NULL,
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


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE = 'BASE TABLE' AND TABLE_NAME = 'TR_MG_EcDet')
	DROP TABLE TR_MG_EcDet
GO

CREATE TABLE TR_MG_EcDet (
	I_RowID			bigint IDENTITY(1, 1) NOT NULL,
	COD_ALU			nvarchar(50)  NULL,
	COD_RC			nvarchar(50)  NULL,
	CUOTA_PAGO		float  NULL,
	ANO				nvarchar(50)  NULL,
	P				nvarchar(50)  NULL,
	TIPO_OBLIG		varchar(50)  NULL,
	CONCEPTO		float  NULL,
	FCH_VENC		nvarchar(50)  NULL,
	NRO_RECIBO		nvarchar(50)  NULL,
	FCH_PAGO		nvarchar(50)  NULL,
	ID_LUG_PAG		nvarchar(50)  NULL,
	CANTIDAD		nvarchar(50)  NULL,
	MONTO			nvarchar(50)  NULL,
	PAGADO			nvarchar(50)  NULL,
	CONCEPTO_F		nvarchar(50)  NULL,
	FCH_ELIMIN		nvarchar(50)  NULL,
	NRO_EC			float  NULL,
	FCH_EC			nvarchar(50)  NULL,
	ELIMINADO		nvarchar(50)  NULL,
	PAG_DEMAS		nvarchar(50)  NULL,
	COD_CAJERO		nvarchar(50)  NULL,
	TIPO_PAGO		nvarchar(50)  NULL,
	NO_BANCO		nvarchar(50)  NULL,
	COD_DEP			nvarchar(50)  NULL,
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

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE = 'BASE TABLE' AND TABLE_NAME = 'TR_MG_CpDes')
	DROP TABLE TR_MG_CpDes
GO

CREATE TABLE TR_MG_CpDes(
	I_RowID			int IDENTITY(1, 1) NOT NULL,
	CUOTA_PAGO		float  NULL,
	DESCRIPCIO		nvarchar(255)  NULL,
	N_CTA_CTE		nvarchar(255)  NULL,
	ELIMINADO		bit NULL,
	CODIGO_BNC		nvarchar(255)  NULL,
	FCH_VENC		datetime  NULL,
	PRIORIDAD		nvarchar(255)  NULL,
	C_MORA			nvarchar(255)  NULL,
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


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE = 'BASE TABLE' AND TABLE_NAME = 'TR_MG_CpPri')
	DROP TABLE TR_MG_CpPri
GO

CREATE TABLE TR_MG_CpPri (
	I_RowID			int IDENTITY(1, 1) NOT NULL,
	ID_CP			float  NULL,
	CUOTA_PAGO		float  NULL,
	ANO				nvarchar(255) NULL,
	P				nvarchar(255) NULL,
	COD_RC			nvarchar(255) NULL,
	COD_ING			nvarchar(255) NULL,
	TIPO_OBLIG		bit  NULL,
	CLASIFICAD		nvarchar(255) NULL,
	CLASIFIC_5		nvarchar(255) NULL,
	ID_CP_AGRP		float  NULL,
	AGRUPA			bit  NULL,
	NRO_PAGOS		float  NULL,
	ID_CP_AFEC		float  NULL,
	PORCENTAJE		bit  NULL,
	MONTO			float  NULL,
	ELIMINADO		bit  NULL,
	DESCRIPCIO		nvarchar(255)  NULL,
	CALCULAR		nvarchar(255)  NULL,
	GRADO			float  NULL,
	TIP_ALUMNO		float  NULL,
	GRUPO_RC		nvarchar(255)  NULL,
	FRACCIONAB		bit  NULL,
	CONCEPTO_G		bit  NULL,
	DOCUMENTO		nvarchar(255)  NULL,
	MONTO_MIN		nvarchar(255)  NULL,
	DESCRIP_L		nvarchar(255)  NULL,
	COD_DEP_PL		nvarchar(255)  NULL,
	OBLIG_MORA		nvarchar(255)  NULL,
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


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE = 'BASE TABLE' AND TABLE_NAME = 'TR_MG_Alumnos')
	DROP TABLE TR_MG_Alumnos
GO

CREATE TABLE TR_MG_Alumnos
(
	I_RowID			int IDENTITY(1, 1) NOT NULL,
	C_RcCod			varchar(3), 
	C_CodAlu		varchar(20), 
	C_NumDNI		varchar(20), 
	C_CodTipDoc		varchar(5),
	T_ApePaterno	varchar(50), 
	T_ApeMaterno	varchar(50), 
	T_Nombre		varchar(50), 
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

