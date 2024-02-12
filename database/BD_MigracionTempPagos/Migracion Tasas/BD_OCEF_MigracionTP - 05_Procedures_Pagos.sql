USE BD_OCEF_MigracionTP
GO

/*
	copiar ec_obl y ec_det
*/
IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_MigracionTP_Tasas_IU_Pagos_CopiarTablaTemporalPagos')
BEGIN
	DROP PROCEDURE dbo.USP_MigracionTP_Tasas_IU_Pagos_CopiarTablaTemporalPagos
END
GO


CREATE PROCEDURE dbo.USP_MigracionTP_Tasas_IU_Pagos_CopiarTablaTemporalPagos
(
	@I_RowID	  int = NULL,
	@I_ProcedenciaID tinyint,
	@B_Resultado  bit output,
	@T_Message	  nvarchar(4000) OUTPUT	
) 
AS
BEGIN
	DECLARE @D_FecProceso datetime = GETDATE() 
	
	BEGIN TRANSACTION 
	BEGIN TRY
		SELECT *
		  INTO #Tmp_cp_des_tasas
		  FROM TR_Cp_Des 
		 WHERE I_ProcedenciaID = @I_ProcedenciaID

		INSERT INTO TR_Ec_Obl (Ano, P, I_Periodo, Cod_alu, Cod_rc, Cuota_pago, Tipo_oblig, Fch_venc, Monto, Pagado, 
							   I_ProcedenciaID, B_Obligacion, D_FecCarga, B_Migrable, B_Migrado)
						SELECT ano, P, CO.I_OpcionID as I_Periodo, OBL.cuota_pago, tipo_oblig, OBL.fch_venc, monto, pagado, 
							   @I_ProcedenciaID, 0 as B_Obligacion, @D_FecProceso, 0 as B_Migrable, 0 as B_Migrado
						  FROM BD_OCEF_TemporalTasas.dbo.ec_obl OBL 
							   INNER JOIN #Tmp_cp_des_tasas CP ON CP.Cuota_pago = OBL.cuota_pago
							   LEFT JOIN BD_OCEF_CtasPorCobrar.dbo.TC_CatalogoOpcion CO ON OBL.p = CO.T_OpcionCod 

		INSERT INTO TR_Ec_Det (I_OblRowID, Cod_alu, Cod_rc, Cuota_pago, Ano, P, Tipo_oblig, Concepto, Fch_venc, Nro_recibo, Fch_pago, 
							   Id_lug_pag, Cantidad, Monto, Documento, Pagado, Concepto_f, Fch_elimin, Nro_ec, Fch_ec, Eliminado, Pag_demas, 
							   Cod_cajero, Tipo_pago, No_banco, Cod_dep, I_ProcedenciaID, B_Obligacion, D_FecCarga, B_Migrable, B_Migrado)
						SELECT *
						  FROM BD_OCEF_TemporalTasas.dbo.ec_det det
							   LEFT JOIN TR_Ec_Obl obl ON det.cod_rc = obl.cod_rc AND det.cod_alu = obl.cod_alu 
														  AND det.ano = obl.ano AND det.p = obl.p AND det.cuota_pago = obl.cuota_pago 
														  AND det.fch_venc = obl.fch_venc
	END TRY
	BEGIN CATCH
		SET @B_Resultado = 0
		SET @T_Message = ERROR_MESSAGE() + ' LINE: ' + CAST(ERROR_LINE() AS varchar(10)) 
	END CATCH
END
GO


/*
	Inicializar estados para validaciones
*/



/*
	Tasas no deben tener registros en ec_obl
*/



/*
	Marcar registro como existente en
*/

