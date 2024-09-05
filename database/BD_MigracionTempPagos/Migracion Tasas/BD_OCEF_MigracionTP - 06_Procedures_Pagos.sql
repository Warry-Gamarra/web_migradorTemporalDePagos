USE BD_OCEF_MigracionTP
GO

/*
	copiar ec_obl y ec_det
*/
IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_Tasas_PagoTasas_TemporalPagos_MigracionTP_IU_CopiarTabla')
BEGIN
	DROP PROCEDURE dbo.USP_Tasas_PagoTasas_TemporalPagos_MigracionTP_IU_CopiarTabla
END
GO


CREATE PROCEDURE dbo.USP_Tasas_PagoTasas_TemporalPagos_MigracionTP_IU_CopiarTabla
(
	@I_RowID	  int = NULL,
	@I_ProcedenciaID tinyint,
	@B_Resultado  bit output,
	@T_Message	  nvarchar(4000) OUTPUT	
) 
AS
/*
	declare @I_ProcedenciaID	tinyint = 4,
			@I_RowID	  int = NULL
			@B_Resultado  bit,
			@T_Message	  nvarchar(4000)
	exec USP_Tasas_PagoTasas_TemporalPagos_MigracionTP_IU_CopiarTabla @I_RowID, @I_ProcedenciaID, @B_Resultado output, @T_Message output
	select @B_Resultado as resultado, @T_Message as mensaje
*/
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

		INSERT INTO TR_Ec_Det_Tasas (I_OblRowID, Cod_alu, Cod_rc, Cuota_pago, Ano, P, Tipo_oblig, Concepto, Fch_venc, Nro_recibo, Fch_pago, 
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
		SET @T_Message = '[{ ' +
							 'Type: "error", ' + 
							 'Title: "Error", ' + 
							 'Value: ' + ERROR_MESSAGE() + ' (Linea: ' + CAST(ERROR_LINE() AS varchar(11)) + ').'  +
						  '}]' 
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




/*
	Migrar Tasa por lotes
*/

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_Tasas_PagoTasas_MigracionTP_CtasPorCobrar_IU_MigrarData')
BEGIN
	DROP PROCEDURE [dbo].[USP_Tasas_PagoTasas_MigracionTP_CtasPorCobrar_IU_MigrarData]
END
GO

CREATE PROCEDURE [dbo].[USP_Tasas_PagoTasas_MigracionTP_CtasPorCobrar_IU_MigrarData]
(
	@I_RowID	int,
	@I_ProcedenciaID tinyint,
	@B_Resultado  bit output,
	@T_Message	  nvarchar(4000) OUTPUT	
)
AS
--declare @I_ProcedenciaID	tinyint = 4,
--		@I_RowID	  int = NULL
--		@B_Resultado  bit,
--		@T_Message	  nvarchar(4000)
--exec USP_Tasas_PagoTasas_MigracionTP_CtasPorCobrar_IU_MigrarData @I_RowID, @I_ProcedenciaID, @B_Resultado output, @T_Message output
--select @B_Resultado as resultado, @T_Message as mensaje
BEGIN 
	DECLARE @D_FecProceso datetime = GETDATE() 

	BEGIN TRANSACTION 
	BEGIN TRY
		SELECT * FROM TR_Ec_Det 
	END TRY
	BEGIN CATCH
		SET @B_Resultado = 0
		SET @T_Message = '[{ ' +
							 'Type: "error", ' + 
							 'Title: "Error", ' + 
							 'Value: ' + ERROR_MESSAGE() + ' (Linea: ' + CAST(ERROR_LINE() AS varchar(11)) + ').'  +
						  '}]' 
	END CATCH

END
GO



/*
	Migrar una Tasa a la vez
*/

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_Tasas_PagoTasas_MigracionTP_CtasPorCobrar_IU_MigrarDataPorID')
BEGIN
	DROP PROCEDURE [dbo].[USP_Tasas_PagoTasas_MigracionTP_CtasPorCobrar_IU_MigrarDataPorID]
END
GO

CREATE PROCEDURE [dbo].[USP_Tasas_PagoTasas_MigracionTP_CtasPorCobrar_IU_MigrarDataPorID]
(
	@I_RowID	int,
	@I_ProcedenciaID tinyint,
	@B_Resultado  bit output,
	@T_Message	  nvarchar(4000) OUTPUT	
)
AS
--declare @I_ProcedenciaID	tinyint = 4,
--		@I_RowID	  int = NULL
--		@B_Resultado  bit,
--		@T_Message	  nvarchar(4000)
--exec USP_Tasas_PagoTasas_MigracionTP_CtasPorCobrar_IU_MigrarDataPorID @I_RowID, @I_ProcedenciaID, @B_Resultado output, @T_Message output
--select @B_Resultado as resultado, @T_Message as mensaje
BEGIN 
	DECLARE @D_FecProceso datetime = GETDATE() 

	BEGIN TRANSACTION 
	BEGIN TRY
		SELECT * FROM TR_Ec_Det 
	END TRY
	BEGIN CATCH
		SET @B_Resultado = 0
		SET @T_Message = '[{ ' +
							 'Type: "error", ' + 
							 'Title: "Error", ' + 
							 'Value: ' + ERROR_MESSAGE() + ' (Linea: ' + CAST(ERROR_LINE() AS varchar(11)) + ').'  +
						  '}]' 
	END CATCH

END
GO


