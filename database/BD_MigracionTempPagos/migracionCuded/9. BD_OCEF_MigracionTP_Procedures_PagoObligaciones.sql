USE BD_OCEF_MigracionTP
GO


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_CtasPorCobrar_I_GrabarPagoBancoPorObligacionID')
BEGIN
	DROP PROCEDURE [dbo].[USP_CtasPorCobrar_I_GrabarPagoBancoPorObligacionID]
END
GO

CREATE PROCEDURE [dbo].[USP_CtasPorCobrar_I_GrabarPagoBancoPorObligacionID]	
(
	@I_OblRowID		 int,
	@D_FecProceso	 datetime,
	@I_TablaID		 int,
	@I_Pagos_Insert	 int OUTPUT
)
AS
BEGIN
	DECLARE @mora decimal(10,2)
	
	SELECT @mora = sum(monto) FROM TR_Ec_Det 
							  WHERE Concepto = 4788 AND I_OblRowID = @I_OblRowID

	INSERT INTO BD_OCEF_CtasPorCobrar.dbo.TR_PagoBanco (I_EntidadFinanID, C_CodOperacion, C_CodDepositante, T_NomDepositante, C_Referencia, D_FecPago, 
														I_Cantidad, C_Moneda, I_MontoPago, T_LugarPago, B_Anulado, I_UsuarioCre, D_FecCre, T_Observacion,
														T_InformacionAdicional, I_CondicionPagoID, I_TipoPagoID, I_CtaDepositoID, I_InteresMora, T_MotivoCoreccion, 
														I_UsuarioMod, D_FecMod, C_CodigoInterno, B_Migrado, I_MigracionTablaID, I_MigracionRowID)
												SELECT  CASE Cod_cajero WHEN 'BCP' THEN 2 ELSE 1 END AS I_EntidadFinanID, nro_recibo, cod_alu, (a.T_ApePaterno + ' ' + a.T_ApeMaterno + ', ' + a.T_Nombre) AS T_NomDepositante, 
														nro_recibo, fch_pago, cantidad, 'PEN', monto, id_lug_pag, eliminado, 1 as usuario, IIF(ISDATE(CAST(Fch_ec as varchar)) = 0, NULL, Fch_ec),
														NULL as observacion, NULL as adicional, 131 as condpago, 133 as tipoPago, cdp.I_CtaDepositoID, ISNULL(@mora, 0) as mora,
														NULL as motivo, NULL, NULL, Nro_recibo, 1 AS migrado, @I_TablaID, det.I_RowID
												  FROM  TR_Ec_Det det
														INNER JOIN  TR_Alumnos a ON det.Cod_alu = a.C_CodAlu AND det.Cod_rc = a.C_RcCod
														INNER JOIN  BD_OCEF_CtasPorCobrar.dbo.TI_CtaDepo_Proceso cdp ON det.cuota_pago = cdp.I_ProcesoID
												 WHERE  I_OblRowID =  @I_OblRowID
														AND Concepto = 0
														AND Concepto_f = 1

	SET @I_Pagos_Insert = @@ROWCOUNT
END
GO


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_CtasPorCobrar_I_GrabarPagoProcesadoPorObligacionID')
BEGIN
	DROP PROCEDURE [dbo].[USP_CtasPorCobrar_I_GrabarPagoProcesadoPorObligacionID]
END
GO

CREATE PROCEDURE [dbo].[USP_CtasPorCobrar_I_GrabarPagoProcesadoPorObligacionID]	
(
	@I_OblRowID		 int,
	@D_FecProceso	 datetime,
	@I_TablaID		 int,
	@I_Pagos_Insert	 int OUTPUT
)
AS
BEGIN

	INSERT INTO BD_OCEF_CtasPorCobrar.dbo.TRI_PagoProcesadoUnfv(I_PagoBancoID, I_CtaDepositoID, I_TasaUnfvID, I_MontoPagado, I_SaldoAPagar, 
																I_PagoDemas, B_PagoDemas, N_NroSIAF, B_Anulado,  D_FecCre, I_UsuarioCre, D_FecMod, 
																I_UsuarioMod, I_ObligacionAluDetID, B_Migrado, I_MigracionTablaID, I_MigracionRowID)
														SELECT  pb.I_PagoBancoID, pb.I_CtaDepositoID, NULL AS I_TasaUnfvID, det.Monto, 0 AS I_SaldoAPagar, 
																0 AS I_PagoDemas, det.pag_demas AS B_PagoDemas, NULL AS N_NroSIAF,  det.Eliminado, @D_FecProceso, 1 AS I_UsuarioCre, NULL AS D_FecMod, 
																NULL AS I_UsuarioMod, ctas_det.I_ObligacionAluDetID, 1 AS B_Migrado, @I_TablaID, det.I_RowID
														  FROM  TR_Ec_Det det
																INNER JOIN  BD_OCEF_CtasPorCobrar.dbo.TR_PagoBanco pb ON det.I_RowID = pb.I_MigracionRowID 
																INNER JOIN  BD_OCEF_CtasPorCobrar.dbo.TR_ObligacionAluDet ctas_det ON det.I_RowID = ctas_det.I_MigracionRowID 
														 WHERE  I_OblRowID = @I_OblRowID 
																AND Pagado = 1 
																AND Concepto_f = 0 
																AND Concepto NOT IN (0, 4788)

	SET @I_Pagos_Insert = @@ROWCOUNT
END
GO


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_IU_MigrarPagoObligacionesCtasPorCobrarPorObligacionID')
BEGIN
	DROP PROCEDURE [dbo].[USP_IU_MigrarPagoObligacionesCtasPorCobrarPorObligacionID]
END
GO

CREATE PROCEDURE [dbo].[USP_IU_MigrarPagoObligacionesCtasPorCobrarPorObligacionID]
(
	@I_RowID		int,
	@I_OblAluID		int OUTPUT,
	@B_Resultado	bit OUTPUT,
	@T_Message		nvarchar(4000) OUTPUT	
)
AS
--declare   @I_RowID	 int, 
--			@B_Resultado  bit, 
--			@T_Message nvarchar(4000)
--exec USP_IU_MigrarPagoObligacionesCtasPorCobrarPorObligacionID @I_RowID, @I_OblAluID OUTPUT, @B_Resultado output, @T_Message output
--select @B_Resultado as resultado, @T_Message as mensaje
BEGIN
	DECLARE @I_Det_Actualizados int = 0
	DECLARE @I_Det_Insertados int = 0

	DECLARE @D_FecProceso datetime = GETDATE()
	DECLARE @I_MigracionTablaOblID tinyint = 5
	DECLARE @I_MigracionTablaDetID tinyint = 4
	DECLARE @T_Moneda varchar(3) = 'PEN'

	BEGIN TRANSACTION;
	BEGIN TRY 
		DECLARE @I_ObligacionAluID  int 
		DECLARE @I_CountPagoBancoID	int 
		DECLARE @I_CountPagoProcID	int 
		DECLARE @Cod_alu			varchar(20)
		DECLARE @Cod_Rc				varchar(5)
		DECLARE @I_Periodo			int
		DECLARE @I_Anio				int

		CREATE TABLE #Tbl_output_pago_obl (T_Action	varchar(20), I_rowID float)
		CREATE TABLE #Tbl_output_pago_det (T_Action	varchar(20), I_rowID float)
		

		SELECT @Cod_alu = Cod_alu, @I_Periodo = I_Periodo, @I_Anio = CAST(Ano as int)
		  FROM TR_Ec_Obl
		 WHERE I_RowID = @I_RowID
		 		
		SELECT @I_ObligacionAluID = I_ObligacionAluID
		  FROM BD_OCEF_CtasPorCobrar.dbo.TR_ObligacionAluCab
		 WHERE I_MigracionRowID = @I_RowID AND I_MigracionTablaID = @I_MigracionTablaOblID


		IF(@I_ObligacionAluID IS NULL)
		BEGIN
			SET @B_Resultado = 0
			SET @T_Message = 'No se encontró obligación migrada para el detalle en base de datos destino' 
		
			GOTO END_TRANSACTION
		END
		
		SELECT @I_CountPagoBancoID = COUNT(*) 
		  FROM BD_OCEF_CtasPorCobrar.dbo.TR_PagoBanco PB
			   INNER JOIN TR_Ec_Det D ON D.I_RowID = PB.I_MigracionRowID AND I_MigracionTablaID = @I_MigracionTablaDetID
		 WHERE I_OblRowID = @I_RowID 


		SELECT  @I_CountPagoProcID = COUNT(*) 
		  FROM BD_OCEF_CtasPorCobrar.dbo.TRI_PagoProcesadoUnfv PPU
			   INNER JOIN BD_OCEF_CtasPorCobrar.dbo.TR_ObligacionAluDet D ON PPU.I_MigracionRowID = D.I_MigracionRowID
		 WHERE I_ObligacionAluID = @I_ObligacionAluID
			   AND PPU.I_MigracionTablaID = @I_MigracionTablaDetID

		IF (@I_CountPagoBancoID = 0)
		BEGIN
			EXECUTE USP_CtasPorCobrar_I_GrabarPagoBancoPorObligacionID @I_RowID, @D_FecProceso, @I_MigracionTablaDetID, @I_Det_Insertados
		END
		ELSE
		BEGIN
			DECLARE @mora decimal(10,2)
	
			SELECT @mora = sum(monto) FROM TR_Ec_Det 
									  WHERE Concepto = 4788 AND I_OblRowID = @I_RowID

			MERGE INTO BD_OCEF_CtasPorCobrar.dbo.TR_PagoBanco AS TRG
			USING (SELECT CASE Cod_cajero WHEN 'BCP' THEN 2 ELSE 1 END AS I_EntidadFinanID, cod_alu, nro_recibo, id_lug_pag, 133 AS tipoPago, 
						  (a.T_ApePaterno + ' ' + a.T_ApeMaterno + ', ' + a.T_Nombre) AS T_NomDepositante, fch_pago, cantidad, monto,  
					 	  'PEN' AS moneda, eliminado, 1 AS usuario, IIF(ISDATE(CAST(Fch_ec as varchar)) = 0, NULL, Fch_ec) AS Fch_ec,
					 	  NULL AS observacion, NULL AS adicional, 131 AS condpago, cdp.I_CtaDepositoID, ISNULL(@mora, 0) as Interes_mora,
					 	  NULL AS motivo, NULL AS user_mod, NULL AS fec_mod, 1 AS migrado, @I_MigracionTablaDetID q, det.I_RowID
					 FROM TR_Ec_Det det
					 	  INNER JOIN  TR_Alumnos a ON det.Cod_alu = a.C_CodAlu AND det.Cod_rc = a.C_RcCod
					 	  INNER JOIN  BD_OCEF_CtasPorCobrar.dbo.TI_CtaDepo_Proceso cdp ON det.cuota_pago = cdp.I_ProcesoID
				    WHERE I_OblRowID =  @I_RowID
					 	  AND Concepto = 0
					 	  AND Concepto_f = 1) AS SRC
			ON
				TRG.C_CodOperacion = SRC.Nro_recibo
				AND TRG.C_CodDepositante = SRC.Cod_alu
				AND CAST(TRG.D_FecPago AS date) = CAST(SRC.Fch_pago AS date)
				AND TRG.I_MigracionTablaID = SRC.I_RowID
			WHEN MATCHED THEN
				UPDATE SET TRG.T_NomDepositante = SRC.T_NomDepositante,
						   TRG.C_Referencia = SRC.Nro_recibo,
						   TRG.D_FecPago = SRC.Fch_pago,
						   TRG.I_MontoPago = SRC.Monto,
						   TRG.T_LugarPago = SRC.Id_lug_pag,
						   TRG.B_Migrado = 1,
						   TRG.D_FecMod = @D_FecProceso
			WHEN NOT MATCHED THEN
				INSERT (I_EntidadFinanID, C_CodOperacion, C_CodDepositante, T_NomDepositante, C_Referencia, D_FecPago, I_Cantidad, C_Moneda, I_MontoPago, T_LugarPago, B_Anulado, 
						I_UsuarioCre, D_FecCre, T_Observacion, T_InformacionAdicional, I_CondicionPagoID, I_TipoPagoID, I_CtaDepositoID, I_InteresMora, T_MotivoCoreccion, I_UsuarioMod, 
						D_FecMod, C_CodigoInterno, B_Migrado, I_MigracionTablaID, I_MigracionRowID)
				VALUES (SRC.I_EntidadFinanID, SRC.nro_recibo, SRC.cod_alu, SRC.T_NomDepositante, SRC.nro_recibo, SRC.fch_pago, SRC.cantidad, 'PEN', SRC.monto, SRC.id_lug_pag, SRC.eliminado, 
						NULL, IIF(ISDATE(CAST(SRC.Fch_ec as varchar)) = 0, NULL,SRC.Fch_ec), NULL, NULL, SRC.condpago, SRC.tipoPago, SRC.I_CtaDepositoID, SRC.Interes_mora, NULL, NULL, 
						NULL, NULL, 1, @I_MigracionTablaDetID, SRC.I_RowID)
			OUTPUT	$ACTION, inserted.I_MigracionRowID INTO #Tbl_output_pago_obl;
		END

		UPDATE OblCab
		   SET B_Pagado = 1
		  FROM BD_OCEF_CtasPorCobrar.dbo.TR_ObligacionAluCab OblCab
			   INNER JOIN #Tbl_output_pago_obl O_pagos ON OblCab.I_MigracionRowID = O_pagos.I_rowID
		 WHERE OblCab.I_MigracionRowID = @I_RowID


		IF (@I_CountPagoProcID = 0)
		BEGIN
			EXECUTE USP_CtasPorCobrar_I_GrabarPagoProcesadoPorObligacionID @I_RowID, @D_FecProceso, @I_MigracionTablaDetID, @I_Det_Insertados
		END
		ELSE
		BEGIN
			MERGE INTO BD_OCEF_CtasPorCobrar.dbo.TRI_PagoProcesadoUnfv AS TRG
			USING (SELECT pb.I_PagoBancoID, pb.I_CtaDepositoID, NULL AS I_TasaUnfvID, det.Monto, 0 AS I_SaldoAPagar, @D_FecProceso as fec_cre, 
						  0 AS I_PagoDemas, det.pag_demas AS B_PagoDemas, NULL AS N_NroSIAF, det.Eliminado, 1 AS I_UsuarioCre, NULL AS D_FecMod, 
						  NULL AS I_UsuarioMod, ctas_det.I_ObligacionAluDetID, 1 AS B_Migrado, @I_MigracionTablaDetID as tabla_det, det.I_RowID
					 FROM TR_Ec_Det det
						  INNER JOIN  BD_OCEF_CtasPorCobrar.dbo.TR_PagoBanco pb ON det.I_RowID = pb.I_MigracionRowID 
						  INNER JOIN  BD_OCEF_CtasPorCobrar.dbo.TR_ObligacionAluDet ctas_det ON det.I_RowID = ctas_det.I_MigracionRowID 
					WHERE I_OblRowID = @I_RowID
						  AND Pagado = 1 
						  AND Concepto_f = 0 
						  AND Concepto NOT IN (0, 4788)) AS SRC
			ON
				TRG.I_PagoBancoID = SRC.I_PagoBancoID
				AND TRG.I_ObligacionAluDetID = SRC.I_ObligacionAluDetID
			WHEN MATCHED THEN
				UPDATE SET TRG.B_Migrado = 1,
						   TRG.I_CtaDepositoID = SRC.I_CtaDepositoID,
						   TRG.D_FecMod = @D_FecProceso,
						   TRG.I_MontoPagado = SRC.Monto
			WHEN NOT MATCHED THEN
				INSERT (I_PagoBancoID, I_CtaDepositoID, I_TasaUnfvID, I_MontoPagado, I_SaldoAPagar, I_PagoDemas, B_PagoDemas, N_NroSIAF, B_Anulado,  
						D_FecCre, I_UsuarioCre, D_FecMod, I_UsuarioMod, I_ObligacionAluDetID, B_Migrado, I_MigracionTablaID, I_MigracionRowID)
				VALUES (SRC.I_PagoBancoID, SRC.I_CtaDepositoID, SRC.I_TasaUnfvID, SRC.Monto, SRC.I_SaldoAPagar, SRC.I_PagoDemas, SRC.B_PagoDemas, SRC.N_NroSIAF, SRC.Eliminado,
						SRC.fec_cre, SRC.I_UsuarioCre, SRC.D_FecMod, SRC.I_UsuarioMod,SRC.I_ObligacionAluDetID, SRC.B_Migrado, SRC.tabla_det, SRC.I_RowID)
			OUTPUT $ACTION, inserted.I_MigracionRowID INTO #Tbl_output_pago_det;

		END
		
		UPDATE OblDet
		   SET B_Pagado = 1
		  FROM BD_OCEF_CtasPorCobrar.dbo.TR_ObligacionAluDet OblDet
			   INNER JOIN #Tbl_output_pago_det O_pagos ON OblDet.I_MigracionRowID = O_pagos.I_rowID
		 WHERE OblDet.I_ObligacionAluID = @I_ObligacionAluID


		 UPDATE EC_DET 
		    SET B_MigradoPago = 1,
				D_FecMigradoPago = @D_FecProceso
		   FROM TR_Ec_Det EC_DET
				INNER JOIN BD_OCEF_CtasPorCobrar.dbo.TR_PagoBanco PB ON EC_DET.I_RowID = PB.I_MigracionRowID
				INNER JOIN BD_OCEF_CtasPorCobrar.dbo.TRI_PagoProcesadoUnfv PPU ON EC_DET.I_RowID = PPU.I_MigracionRowID
		  WHERE EC_DET.I_OblRowID = @I_RowID

		SET @B_Resultado = 1
		SET @T_Message = 'OK' 

		END_TRANSACTION:
			SET @I_OblAluID = ISNULL(@I_ObligacionAluID, 0)
			COMMIT TRANSACTION;

	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION;
		SET @I_OblAluID = ISNULL(@I_ObligacionAluID, 0)
		SET @B_Resultado = 0
		SET @T_Message = ERROR_MESSAGE() + ' LINE: ' + CAST(ERROR_LINE() AS varchar(10)) 
	END CATCH
END
GO

