USE [BD_OCEF_CtasPorCobrar]
GO

-- CP_DES
ALTER TABLE [dbo].[TC_Proceso]
	ADD I_MigracionTablaID	int  NULL
GO

ALTER TABLE [dbo].[TC_Proceso]
	ADD I_MigracionRowID	int  NULL
GO

--CP_PRI
ALTER TABLE [dbo].[TI_ConceptoPago]
	ADD I_MigracionTablaID	int  NULL
GO

ALTER TABLE [dbo].[TI_ConceptoPago]
	ADD I_MigracionRowID	int  NULL
GO

--EC_OBL
ALTER TABLE [dbo].[TR_ObligacionAluCab]
	ADD B_Migrado	bit  NULL
GO

ALTER TABLE [dbo].[TR_ObligacionAluCab]
	ADD I_MigracionTablaID	int  NULL
GO

ALTER TABLE [dbo].[TR_ObligacionAluCab]
	ADD I_MigracionRowID	int  NULL
GO



--EC_DET
ALTER TABLE [dbo].[TR_ObligacionAluDet]
	ADD B_Migrado	bit  NULL
GO

ALTER TABLE [dbo].[TR_ObligacionAluDet]
	ADD I_MigracionTablaID	int  NULL
GO

ALTER TABLE [dbo].[TR_ObligacionAluDet]
	ADD I_MigracionRowID	int  NULL
GO

ALTER TABLE [dbo].[TR_ObligacionAluDet]
	ALTER COLUMN T_DescDocumento varchar(max)
GO

ALTER TABLE [dbo].[TR_PagoBanco]
	ADD B_Migrado	bit  NULL
GO

ALTER TABLE [dbo].[TR_PagoBanco]
	ADD I_MigracionTablaID	int  NULL
GO

ALTER TABLE [dbo].[TR_PagoBanco]
	ADD I_MigracionRowID	int  NULL
GO


ALTER TABLE [dbo].[TRI_PagoProcesadoUnfv]
	ADD B_Migrado	bit  NULL
GO

ALTER TABLE [dbo].[TRI_PagoProcesadoUnfv]
	ADD I_MigracionTablaID	int  NULL
GO

ALTER TABLE [dbo].[TRI_PagoProcesadoUnfv]
	ADD I_MigracionRowID	int  NULL
GO

