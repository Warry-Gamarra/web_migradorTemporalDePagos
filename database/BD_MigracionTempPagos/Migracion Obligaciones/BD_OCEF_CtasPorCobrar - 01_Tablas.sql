USE BD_OCEF_CtasPorCobrar
GO


IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'TC_MatriculaAlumno' AND COLUMN_NAME = 'I_MigracionRowID')
BEGIN
	ALTER TABLE [dbo].[TC_MatriculaAlumno]
		ADD I_MigracionRowID	int  NULL
END
GO

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'TC_MatriculaAlumno' AND COLUMN_NAME = 'I_MigracionTablaID')
BEGIN
	ALTER TABLE [dbo].[TC_MatriculaAlumno]
		ADD I_MigracionTablaID	int  NULL
END
GO


IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'TR_PagoBanco' AND COLUMN_NAME = 'I_MigracionMoraRowID')
BEGIN
	ALTER TABLE [dbo].[TR_PagoBanco]
		ADD I_MigracionMoraRowID	int  NULL
END
GO


