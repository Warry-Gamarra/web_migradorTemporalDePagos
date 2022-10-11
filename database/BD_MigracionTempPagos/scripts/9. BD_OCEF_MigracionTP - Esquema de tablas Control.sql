USE [BD_OCEF_MigracionTP]
GO


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE = 'BASE TABLE' AND TABLE_NAME = 'TR_Ec_Pri')
	DROP TABLE TR_Ec_Pri
GO

CREATE TABLE TS_HistorialResultados (
	I_RowID					int IDENTITY(1, 1) NOT NULL,
	T_TablaOrigenID			int NULL,
	I_Estado				tinyint  NULL,
	T_TablasDestino			varchar(250)  NULL,
	I_Procedencia			tinyint  NULL,
	D_FecCopia				datetime  NULL,
	D_FecValidacion			datetime  NULL,
	D_FecMigracion			datetime  NULL,
	I_CantFilasOrigen		int NULL,
	I_CantFilasMigradas		int NULL,
	I_CantFilasObservadas	int NULL
)
GO

CREATE TABLE TS_DataOrigen (
	I_TablaID			int NULL,
	I_Procedencia		tinyint  NULL,
	I_CantFilas			int  NULL,
	I_CantEliminados	int  NULL,
	D_FecArchivo		datetime  NULL,
	B_Copiado			bit NULL,
	D_FecCopia			datetime  NULL,
)
GO