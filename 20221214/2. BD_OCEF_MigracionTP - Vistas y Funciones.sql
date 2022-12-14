USE BD_OCEF_MigracionTP
GO


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.VIEWS WHERE TABLE_NAME = 'VW_EquivalenciasCtasPorCobrar')
	DROP VIEW [dbo].[VW_EquivalenciasCtasPorCobrar]
GO

CREATE VIEW VW_EquivalenciasCtasPorCobrar
AS
(
	SELECT  I_OpcionID, T_OpcionCod, T_OpcionDesc, I_ParametroID, B_Eliminado
	FROM	BD_OCEF_CtasPorCobrar.dbo.TC_CatalogoOpcion co
)
GO


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.VIEWS WHERE TABLE_NAME = 'VW_Categor�asDePagoCtasPorCobrar')
	DROP VIEW [dbo].[VW_Categor�asDePagoCtasPorCobrar]
GO

CREATE VIEW VW_Categor�asDePagoCtasPorCobrar
AS
(
	SELECT  I_CatPagoID, T_CatPagoDesc, I_TipoAlumno, N_CodBanco, B_Eliminado
	FROM	BD_OCEF_CtasPorCobrar.dbo.TC_CategoriaPago co
)
GO

