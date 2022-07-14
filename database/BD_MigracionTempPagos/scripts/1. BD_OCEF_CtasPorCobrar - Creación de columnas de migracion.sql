USE [BD_OCEF_CtasPorCobrar]
GO

-- CP_DES
ALTER TABLE [dbo].[TC_Proceso]
	ADD I_MigracionTablaID	int
GO

ALTER TABLE [dbo].[TC_Proceso]
	ADD I_MigracionRowID	int
GO

--CP_PRI
ALTER TABLE [dbo].[TI_ConceptoPago]
	ADD I_MigracionTablaID	int
GO

ALTER TABLE [dbo].[TI_ConceptoPago]
	ADD I_MigracionRowID	int
GO


ALTER TABLE [dbo].[TI_ConceptoPago]
	ADD I_MigracionTablaID	int
GO

ALTER TABLE [dbo].[TI_ConceptoPago]
	ADD I_MigracionRowID	int
GO


ALTER TABLE [dbo].[TI_ConceptoPago]
	ADD I_MigracionTablaID	int
GO

ALTER TABLE [dbo].[TI_ConceptoPago]
	ADD I_MigracionRowID	int
GO

