USE BD_OCEF_MigracionTP
GO

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.VIEWS WHERE TABLE_NAME = 'VW_ObservacionesTabla')
	DROP VIEW [dbo].[VW_ObservacionesTabla]
GO

CREATE VIEW VW_ObservacionesTabla
AS
(
	SELECT  I_ObsTablaID, ORT.D_FecRegistro, ORT.I_TablaID, T_TablaNom, ORT.I_ObservID, CO.T_ObservDesc,
			ORT.I_FilaTablaID, CO.T_ObservCod, CO.I_Severidad, ORT.I_ProcedenciaID, ORT.B_Resuelto, ORT.D_FecResuelto
	FROM	TI_ObservacionRegistroTabla ORT
			INNER JOIN TC_CatalogoTabla CT ON ORT.I_TablaID = CT.I_TablaID
			INNER JOIN TC_CatalogoObservacion CO ON ORT.I_ObservID = CO.I_ObservID
)
GO


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.VIEWS WHERE TABLE_NAME = 'VW_DetalleObligacionItems')
	DROP VIEW [dbo].[VW_DetalleObligacionItems]
GO

CREATE VIEW VW_DetalleObligacionItems
AS
(
	SELECT  Cod_alu, Cod_rc, Cuota_pago, Ano, P, Tipo_oblig, Concepto, Fch_venc, Nro_recibo, Fch_pago, Id_lug_pag, Cantidad, Monto, 
			Documento, Pagado, Concepto_f, Fch_elimin, Nro_ec, Fch_ec, Eliminado, Pag_demas, Cod_cajero, Tipo_pago, No_banco, Cod_dep,
			I_ProcedenciaID, B_Migrable, B_Migrado
	FROM	TR_Ec_Det
	WHERE	Concepto_f = 0
			AND B_Obligacion = 1
)
GO


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.VIEWS WHERE TABLE_NAME = 'VW_DetalleObligacionPagos')
	DROP VIEW [dbo].[VW_DetalleObligacionPagos]
GO

CREATE VIEW VW_DetalleObligacionPagos
AS
(
	SELECT  Cod_alu, Cod_rc, Cuota_pago, Ano, P, Tipo_oblig, Concepto, Fch_venc, Nro_recibo, Fch_pago, Id_lug_pag, Cantidad, Monto, 
			Documento, Pagado, Concepto_f, Fch_elimin, Nro_ec, Fch_ec, Eliminado, Pag_demas, Cod_cajero, Tipo_pago, No_banco, Cod_dep,
			I_ProcedenciaID, B_Migrable, B_Migrado
	FROM	TR_Ec_Det
	WHERE	CONCEPTO_F = 1
			AND B_Obligacion = 1
)
GO


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'FUNCTION' AND ROUTINE_NAME = 'Func_B_ValidarExisteTablaTemporalPagos')
	DROP FUNCTION [dbo].[Func_B_ValidarExisteTablaTemporalPagos]
GO

CREATE FUNCTION Func_B_ValidarExisteTablaTemporalPagos 
(
	@T_NombreSchema	varchar(50),
	@T_NombreTabla	varchar(50)
)
RETURNS  bit
AS
BEGIN
	DECLARE  @B_Result bit;

	IF EXIStS (SELECT * FROM  BD_OCEF_TemporalPagos.INFORMATION_SCHEMA.TABLES 
				WHERE TABLE_SCHEMA = @T_NombreSchema AND TABLE_NAME = @T_NombreTabla)
	BEGIN
		SET @B_Result = 1;
	END
	ELSE
	BEGIN
		SET @B_Result = 0;
	END

	RETURN @B_Result;
END
GO


-- cambios 20221212

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


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.VIEWS WHERE TABLE_NAME = 'VW_CategoríasDePagoCtasPorCobrar')
	DROP VIEW [dbo].[VW_CategoríasDePagoCtasPorCobrar]
GO

CREATE VIEW VW_CategoríasDePagoCtasPorCobrar
AS
(
	SELECT  I_CatPagoID, T_CatPagoDesc, I_TipoAlumno, N_CodBanco, B_Eliminado
	FROM	BD_OCEF_CtasPorCobrar.dbo.TC_CategoriaPago co
)
GO

