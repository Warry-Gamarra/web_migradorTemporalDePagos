USE [BD_OCEF_MigracionTP]
GO

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'TR_Alumnos' AND COLUMN_NAME = 'B_Correcto')
BEGIN
	ALTER TABLE [dbo].[TR_Alumnos]
		ADD B_Correcto	bit  NULL
END
GO


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE = 'BASE TABLE' AND TABLE_NAME = 'TS_HistorialResultados')
	DROP TABLE TS_HistorialResultados
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


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE = 'BASE TABLE' AND TABLE_NAME = 'TS_DataOrigen')
	DROP TABLE TS_DataOrigen
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

-- Cambio estructura para version 20221115

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'TI_ObservacionRegistroTabla' AND COLUMN_NAME = 'B_Resuelto')
BEGIN
	ALTER TABLE [dbo].[TI_ObservacionRegistroTabla]
		ADD B_Resuelto		bit	 NULL DEFAULT 0,
			D_FecResuelto	datetime NULL
END
GO

UPDATE TI_ObservacionRegistroTabla 
   SET B_Resuelto = 0
 WHERE B_Resuelto IS NULL
GO


IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'TR_Cp_Des' AND COLUMN_NAME = 'B_MantenerAnio')
BEGIN
	ALTER TABLE [dbo].[TR_Cp_Des]
		ADD B_MantenerAnio		bit	 NULL DEFAULT 0,
			B_MantenerPeriodo	bit	 NULL DEFAULT 0
END
GO


UPDATE TR_Cp_Des 
   SET B_MantenerAnio = 0
 WHERE B_MantenerAnio IS NULL
GO

UPDATE TR_Cp_Des 
   SET B_MantenerPeriodo = 0
 WHERE B_MantenerPeriodo IS NULL
 GO


IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'TR_Cp_Pri' AND COLUMN_NAME = 'I_EquivDestinoID')
BEGIN
	ALTER TABLE [dbo].[TR_Cp_Pri]
		ADD I_EquivDestinoID	int  NULL
END
GO



-- Cambio estructura para version 20221205

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'TR_Cp_Pri' AND COLUMN_NAME = 'B_MantenerAnio')
BEGIN
	ALTER TABLE [dbo].[TR_Cp_Pri]
		ADD B_MantenerAnio		bit	 NULL DEFAULT 0,
			B_MantenerPeriodo	bit	 NULL DEFAULT 0
END
GO


UPDATE TR_Cp_Pri 
   SET B_MantenerAnio = 0
 WHERE B_MantenerAnio IS NULL
GO

UPDATE TR_Cp_Pri 
   SET B_MantenerPeriodo = 0
 WHERE B_MantenerPeriodo IS NULL
 GO


 DELETE FROM TI_ObservacionRegistroTabla WHERE I_ProcedenciaID IS NULL
 GO
