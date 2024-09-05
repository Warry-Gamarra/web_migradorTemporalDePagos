USE BD_OCEF_MigracionTP
GO


/*
	copiar ec_obl y ec_det
*/
IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_Tasas_TemporalPagos_MigracionTP_IU_CopiarTablaObl')
BEGIN
	DROP PROCEDURE dbo.USP_Tasas_TemporalPagos_MigracionTP_IU_CopiarTablaObl
END
GO



CREATE PROCEDURE dbo.USP_Tasas_TemporalPagos_MigracionTP_IU_CopiarTablaObl
(
	@I_Anio		  varchar(4),
	@B_Resultado  bit output,
	@T_Message	  nvarchar(4000) OUTPUT	
) 
AS
/*
	declare @I_Anio		  varchar(4) = 2010,
			@B_Resultado  bit,
			@T_Message	  nvarchar(4000)
	exec USP_Tasas_TemporalPagos_MigracionTP_IU_CopiarTablaObl @I_RowID, @I_ProcedenciaID, @B_Resultado output, @T_Message output
	select @B_Resultado as resultado, @T_Message as mensaje
*/
BEGIN
	DECLARE @D_FecProceso datetime = GETDATE(),
			@I_ProcedenciaID int = 4

	DELETE TR_Tasas_Ec_Det WHERE  EXISTS (SELECT * FROM TR_Tasas_Ec_Obl WHERE TR_Tasas_Ec_Obl.I_RowID = I_OblRowID
																			  AND TR_Tasas_Ec_Obl.Ano = @I_Anio 
																			  AND TR_Tasas_Ec_Obl.B_Migrado = 0);

	DELETE TR_Tasas_Ec_Det WHERE I_OblRowID IS NULL AND Ano = @I_Anio;

	DELETE TR_Tasas_Ec_Obl WHERE TR_Tasas_Ec_Obl.Ano = @I_Anio AND TR_Tasas_Ec_Obl.B_Migrado = 0;

	DELETE FROM TI_ObservacionRegistroTabla 				
				WHERE I_TablaID = 9 
					  AND NOT EXISTS (SELECT I_RowID FROM TR_Tasas_Ec_Det 
										WHERE I_RowID = I_FilaTablaID
											  AND Ano = @I_Anio);

	DELETE FROM TI_ObservacionRegistroTabla 				
				WHERE I_TablaID = 8 
					  AND NOT EXISTS (SELECT I_RowID FROM TR_Tasas_Ec_Obl 
										WHERE I_RowID = I_FilaTablaID
											  AND Ano = @I_Anio);

	INSERT TR_Ec_Obl (Ano, P, I_Periodo, Cod_alu, Cod_rc, Cuota_pago, Tipo_oblig, Fch_venc, Monto, Pagado, 
					  D_FecCarga, B_Migrable, B_Migrado, I_ProcedenciaID, B_Obligacion) 
			   SELECT ano, p, I_OpcionID as I_periodo, cod_alu, cod_rc, cuota_pago, tipo_oblig, fch_venc, monto, pagado, 
					  @D_FecProceso, 1, 0, @I_ProcedenciaID, 0
				 FROM BD_OCEF_TemporalTasas.dbo.ec_obl OBL 
					  LEFT JOIN BD_OCEF_CtasPorCobrar.dbo.TC_CatalogoOpcion cop_per ON OBL.P = cop_per.T_OpcionCod AND cop_per.I_ParametroID = 5 
				WHERE NOT EXISTS (SELECT * FROM TR_Ec_Obl TRG 
								   WHERE TRG.Ano = OBL.ano AND TRG.P = OBL.p AND TRG.Cod_alu = OBL.COD_ALU  
										 AND TRG.Cod_rc = OBL.COD_RC AND TRG.Cuota_pago = OBL.cuota_pago 
										 AND ISNULL(TRG.Fch_venc, '19000101') = ISNULL(OBL.fch_venc, '19000101') 
										 AND ISNULL(TRG.Tipo_oblig, 0) = ISNULL(OBL.tipo_oblig, 0) AND TRG.Monto = OBL.monto 
										 AND TRG.Pagado = OBL.pagado)
					  AND OBL.Ano = @I_Anio;

END
GO


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_Tasas_TemporalPagos_MigracionTP_IU_CopiarTablaDet')
BEGIN
	DROP PROCEDURE dbo.USP_Tasas_TemporalPagos_MigracionTP_IU_CopiarTablaDet
END
GO



CREATE PROCEDURE dbo.USP_Tasas_TemporalPagos_MigracionTP_IU_CopiarTablaDet
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
	exec USP_Tasas_TemporalPagos_MigracionTP_IU_CopiarTablaDet @I_RowID, @I_ProcedenciaID, @B_Resultado output, @T_Message output
	select @B_Resultado as resultado, @T_Message as mensaje
*/
BEGIN
	DECLARE @D_FecProceso datetime = GETDATE() 


END
GO