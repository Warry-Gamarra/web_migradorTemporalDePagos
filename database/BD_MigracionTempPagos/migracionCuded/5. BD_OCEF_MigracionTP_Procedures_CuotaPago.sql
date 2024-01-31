USE BD_OCEF_MigracionTP
GO


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_U_ValidarCuotaPagoRepetidaDiferentesProcedencias')
BEGIN
	DROP PROCEDURE [dbo].[USP_U_ValidarCuotaPagoRepetidaDiferentesProcedencias]
END
GO

CREATE PROCEDURE USP_U_ValidarCuotaPagoRepetidaDiferentesProcedencias
	@I_ProcedenciaID tinyint,
	@B_Resultado  bit output,
	@T_Message	  nvarchar(4000) OUTPUT	
AS
--declare @B_Resultado  bit,
--		@I_ProcedenciaID tinyint = 3,
--		@T_Message	  nvarchar(4000)
--exec USP_U_ValidarCuotaPagoRepetidaDiferentesProcedencias @I_ProcedenciaID, @B_Resultado output, @T_Message output
--select @B_Resultado as resultado, @T_Message as mensaje
BEGIN	
	DECLARE @D_FecProceso datetime = GETDATE() 
	DECLARE @I_ObservID int = 50
	DECLARE @I_TablaID int = 2 
	DECLARE @I_Observados int = 0

	BEGIN TRY 
		UPDATE	TR_Cp_Des
		SET		B_Migrable = 0,
				B_Migrado = 0,
				D_FecEvalua = @D_FecProceso
		WHERE	Cuota_pago IN (SELECT DISTINCT reps.Cuota_pago 
								 FROM (SELECT Cuota_pago FROM TR_Cp_Des 
									   GROUP BY Cuota_pago HAVING COUNT(Cuota_pago) > 1) AS reps
									  INNER JOIN (SELECT Cuota_pago, I_ProcedenciaID FROM TR_Cp_Des
												  GROUP BY Cuota_pago, I_ProcedenciaID HAVING COUNT(Cuota_pago) = 1) noRepsProc 
												 ON reps.Cuota_pago = noRepsProc.Cuota_pago
							  )
				AND ISNULL(B_Correcto, 0) = 0

		MERGE TI_ObservacionRegistroTabla AS TRG
		USING (SELECT @I_ObservID AS I_ObservID, @I_TablaID AS I_TablaID, I_RowID AS I_FilaTablaID, @D_FecProceso AS D_FecRegistro 
				 FROM TR_Cp_Des 
				WHERE Cuota_pago IN (SELECT DISTINCT reps.Cuota_pago 
									   FROM (SELECT Cuota_pago FROM TR_Cp_Des 
										     GROUP BY Cuota_pago HAVING COUNT(Cuota_pago) > 1) AS reps
										    INNER JOIN (SELECT Cuota_pago, I_ProcedenciaID FROM TR_Cp_Des
													    GROUP BY Cuota_pago, I_ProcedenciaID HAVING COUNT(Cuota_pago) = 1) noRepsProc 
													   ON reps.Cuota_pago = noRepsProc.Cuota_pago
									)
					  AND ISNULL(B_Correcto, 0) = 0
			  ) AS SRC
		ON TRG.I_ObservID = SRC.I_ObservID AND TRG.I_TablaID = SRC.I_TablaID AND TRG.I_FilaTablaID = SRC.I_FilaTablaID
		WHEN MATCHED THEN
			UPDATE SET D_FecRegistro = SRC.D_FecRegistro, 
					   B_Resuelto = 0
		WHEN NOT MATCHED BY TARGET THEN
			INSERT (I_ObservID, I_TablaID, I_FilaTablaID, D_FecRegistro, I_ProcedenciaID)
			VALUES (SRC.I_ObservID, SRC.I_TablaID, SRC.I_FilaTablaID, SRC.D_FecRegistro, @I_ProcedenciaID)
		WHEN NOT MATCHED BY SOURCE AND TRG.I_ObservID = @I_ObservID AND TRG.I_ProcedenciaID = @I_ProcedenciaID THEN
			UPDATE SET D_FecResuelto = GETDATE(),
					   B_Resuelto = 1;

		SET @I_Observados = (SELECT COUNT(*) FROM TI_ObservacionRegistroTabla WHERE I_ObservID = @I_ObservID AND I_TablaID = @I_TablaID AND I_ProcedenciaID = @I_ProcedenciaID AND B_Resuelto = 0)

		SET @B_Resultado = 1
		SET @T_Message = CAST(@I_Observados AS varchar) + ' encontrados'
	END TRY
	BEGIN CATCH
		SET @B_Resultado = 0
		SET @T_Message = ERROR_MESSAGE() + ' LINE: ' + CAST(ERROR_LINE() AS varchar(10)) 
	END CATCH
END
GO


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_IU_MigrarDataCuotaDePagoCtasPorCobrar')
BEGIN
	DROP PROCEDURE [dbo].[USP_IU_MigrarDataCuotaDePagoCtasPorCobrar]
END
GO

CREATE PROCEDURE [dbo].[USP_IU_MigrarDataCuotaDePagoCtasPorCobrar]
	@I_ProcesoID	  int = NULL,
	@I_AnioIni	  int = NULL,
	@I_AnioFin	  int = NULL,
	@I_ProcedenciaID tinyint,
	@B_Resultado  bit output,
	@T_Message	  nvarchar(4000) OUTPUT	
AS
--declare	@B_Resultado  bit, 
--			@I_ProcesoID int = NULL,
--			@I_AnioIni int = NULL, 
--			@I_AnioFin int = NULL,
--			@I_ProcedenciaID tinyint = 3,
--			@T_Message nvarchar(4000)
--exec USP_IU_MigrarDataCuotaDePagoCtasPorCobrar @I_ProcesoID, @I_AnioIni, @I_AnioFin, @I_ProcedenciaID, @B_Resultado output, @T_Message output
--select @B_Resultado as resultado, @T_Message as mensaje
BEGIN
	DECLARE @D_FecProceso datetime = GETDATE() 
	DECLARE @Tbl_outputProceso AS TABLE (T_Action varchar(20), I_RowID int)
	DECLARE @Tbl_outputCtas AS TABLE (T_Action varchar(20), I_RowID int)
	DECLARE @Tbl_outputCtasCat AS TABLE (T_Action varchar(20), I_RowID int)
	DECLARE @I_Proc_Inserted int = 0
	DECLARE @I_Proc_Updated int = 0
	DECLARE @I_Ctas_Inserted int = 0
	DECLARE @I_Ctas_Updated int = 0
	DECLARE @I_CtaCat_Inserted int = 0
	DECLARE @I_CtaCat_Updated int = 0
	DECLARE @I_ObservID int = 11
	DECLARE @I_TablaID int = 2

	BEGIN TRANSACTION;
	BEGIN TRY 
		SET @I_AnioIni = (SELECT ISNULL(@I_AnioIni, 0))
		SET @I_AnioFin = (SELECT ISNULL(@I_AnioFin, 3000))

		SET IDENTITY_INSERT BD_OCEF_CtasPorCobrar.dbo.TC_Proceso ON;

		MERGE INTO  BD_OCEF_CtasPorCobrar.dbo.TC_Proceso AS TRG
		USING (SELECT * FROM TR_Cp_Des 
				WHERE B_Migrable = 1 
					  AND (I_Anio BETWEEN @I_AnioIni AND @I_AnioFin)
					  AND (CUOTA_PAGO = @I_ProcesoID OR @I_ProcesoID IS NULL)
					  AND I_ProcedenciaID = @I_ProcedenciaID
			  ) AS SRC
		ON TRG.I_ProcesoID = SRC.CUOTA_PAGO 
		WHEN NOT MATCHED BY TARGET THEN 
			 INSERT (I_ProcesoID, I_CatPagoID, T_ProcesoDesc, I_Anio, I_Periodo, N_CodBanco, D_FecVencto, I_Prioridad, B_Mora, 
					 B_Migrado, D_FecCre, B_Habilitado, B_Eliminado, I_MigracionTablaID, I_MigracionRowID)
			 VALUES (CUOTA_PAGO, I_CatPagoID, DESCRIPCIO
			 , I_Anio, I_Periodo, CODIGO_BNC, FCH_VENC, PRIORIDAD, C_MORA, 
					 1, @D_FecProceso, 1, ELIMINADO, @I_TablaID, I_RowID)
					
		WHEN MATCHED AND TRG.B_Migrado = 1 AND TRG.I_UsuarioMod IS NULL THEN 
			 UPDATE SET I_CatPagoID = SRC.I_CatPagoID, 
					 T_ProcesoDesc = SRC.DESCRIPCIO,
					 I_Anio = SRC.I_Anio, 
					 I_Periodo = SRC.I_Periodo,
					 N_CodBanco = SRC.CODIGO_BNC, 
					 D_FecVencto = SRC.FCH_VENC, 
					 I_Prioridad = SRC.PRIORIDAD, 
					 D_FecMod = @D_FecProceso,
					 B_Mora = SRC.C_MORA,
					 I_MigracionTablaID = @I_TablaID,
					 I_MigracionRowID = I_RowID,
					 B_Eliminado = SRC.Eliminado
		OUTPUT $action, SRC.I_RowID INTO @Tbl_outputProceso;
		
		SET IDENTITY_INSERT BD_OCEF_CtasPorCobrar.dbo.TC_Proceso OFF
		
		IF(@I_ProcesoID IS NULL)
		BEGIN
			SET @I_ProcesoID = (SELECT MAX(CAST(CUOTA_PAGO as int)) FROM TR_Cp_Des) + 1 
			DBCC CHECKIDENT([BD_OCEF_CtasPorCobrar.dbo.TC_Proceso], RESEED, @I_ProcesoID)
		END

		MERGE INTO BD_OCEF_CtasPorCobrar.dbo.TI_CtaDepo_Proceso AS TRG
		USING (SELECT CD.I_CtaDepositoID, TP_CD.* FROM TR_Cp_Des TP_CD
					  INNER JOIN BD_OCEF_CtasPorCobrar.dbo.TC_CuentaDeposito CD ON CD.C_NumeroCuenta COLLATE DATABASE_DEFAULT = TP_CD.N_CTA_CTE COLLATE DATABASE_DEFAULT
				WHERE B_Migrable = 1 
						AND (I_Anio BETWEEN @I_AnioIni AND @I_AnioFin) 
						AND (CUOTA_PAGO = @I_ProcesoID OR @I_ProcesoID IS NULL)
						AND I_ProcedenciaID = @I_ProcedenciaID
			   ) AS SRC
		ON TRG.I_ProcesoID = SRC.CUOTA_PAGO AND TRG.I_CtaDepositoID = SRC.I_CtaDepositoID
		WHEN NOT MATCHED BY TARGET THEN
			INSERT (I_CtaDepositoID, I_ProcesoID, B_Habilitado, B_Eliminado, D_FecCre)
			VALUES (I_CtaDepositoID, CUOTA_PAGO, 1, ELIMINADO, @D_FecProceso)
		WHEN MATCHED AND TRG.I_UsuarioCre IS NULL AND TRG.I_UsuarioMod IS NULL THEN
			UPDATE SET	B_Eliminado = ELIMINADO,
						D_FecMod = @D_FecProceso
		OUTPUT $action, SRC.I_RowID INTO @Tbl_outputCtas;


		MERGE INTO BD_OCEF_CtasPorCobrar.dbo.TC_CuentaDeposito_CategoriaPago AS TRG
		USING (SELECT DISTINCT CD.I_CtaDepositoID, TP_CD.I_CatPagoID FROM TR_Cp_Des TP_CD
				INNER JOIN BD_OCEF_CtasPorCobrar.dbo.TC_CuentaDeposito CD ON CD.C_NumeroCuenta COLLATE DATABASE_DEFAULT = TP_CD.N_CTA_CTE COLLATE DATABASE_DEFAULT
				WHERE B_Migrable = 1 
					  AND I_ProcedenciaID = @I_ProcedenciaID					  
					  AND (I_Anio BETWEEN @I_AnioIni AND @I_AnioFin)) AS SRC
		ON TRG.I_CatPagoID = SRC.I_CatPagoID AND TRG.I_CtaDepositoID = SRC.I_CtaDepositoID
		WHEN NOT MATCHED BY TARGET THEN
			INSERT (I_CtaDepositoID, I_CatPagoID, B_Habilitado, B_Eliminado, D_FecCre)
			VALUES (I_CtaDepositoID, I_CatPagoID, 1, 0, @D_FecProceso)
		WHEN MATCHED AND TRG.I_UsuarioCre IS NULL AND TRG.I_UsuarioMod IS NULL THEN
			UPDATE SET	D_FecMod = @D_FecProceso
		OUTPUT $action, SRC.I_CatPagoID INTO @Tbl_outputCtasCat;
		

		SELECT * FROM @Tbl_outputProceso

		UPDATE	TR_Cp_Des 
		SET		B_Migrado = 1, 
				D_FecMigrado = @D_FecProceso
		WHERE	I_RowID IN (SELECT I_RowID FROM @Tbl_outputProceso)
				AND I_ProcedenciaID = @I_ProcedenciaID

		UPDATE	TR_Cp_Des 
		SET		B_Migrado = 0 
		WHERE	I_RowID IN (SELECT CD.I_RowID FROM TR_Cp_Des CD LEFT JOIN @Tbl_outputProceso O ON CD.I_RowID = o.I_RowID 
							WHERE CD.B_Migrable = 1 AND O.I_RowID IS NULL)
				AND I_ProcedenciaID = @I_ProcedenciaID

		MERGE TI_ObservacionRegistroTabla AS TRG
		USING 	(SELECT	@I_ObservID AS I_ObservID, @I_TablaID AS I_TablaID, I_RowID AS I_FilaTablaID, @D_FecProceso AS D_FecRegistro FROM TR_Cp_Des
				  WHERE	I_RowID IN (SELECT CD.I_RowID FROM TR_Cp_Des CD LEFT JOIN @Tbl_outputProceso O ON CD.I_RowID = o.I_RowID 
									WHERE CD.B_Migrable = 1 AND O.I_RowID IS NULL)
						AND I_ProcedenciaID = @I_ProcedenciaID
				) AS SRC
		ON TRG.I_ObservID = SRC.I_ObservID AND TRG.I_TablaID = SRC.I_TablaID AND TRG.I_FilaTablaID = SRC.I_FilaTablaID
		WHEN MATCHED THEN
			UPDATE SET D_FecRegistro = SRC.D_FecRegistro
		WHEN NOT MATCHED BY TARGET THEN
			INSERT (I_ObservID, I_TablaID, I_FilaTablaID, D_FecRegistro)
			VALUES (SRC.I_ObservID, SRC.I_TablaID, SRC.I_FilaTablaID, SRC.D_FecRegistro)
		WHEN NOT MATCHED BY SOURCE AND TRG.I_ObservID = @I_ObservID AND TRG.I_ProcedenciaID = @I_ProcedenciaID THEN
			DELETE;

		SET @I_Proc_Inserted = (SELECT COUNT(*) FROM @Tbl_outputProceso WHERE T_Action = 'INSERT')
		SET @I_Proc_Updated = (SELECT COUNT(*) FROM @Tbl_outputProceso WHERE T_Action = 'UPDATE')
		SET @I_Ctas_Inserted = (SELECT COUNT(*) FROM @Tbl_outputCtas WHERE T_Action = 'INSERT')
		SET @I_Ctas_Updated = (SELECT COUNT(*) FROM @Tbl_outputCtas WHERE T_Action = 'UPDATE')
		SET @I_CtaCat_Inserted = (SELECT COUNT(*) FROM @Tbl_outputCtasCat WHERE T_Action = 'INSERT')
		SET @I_CtaCat_Updated = (SELECT COUNT(*) FROM @Tbl_outputCtasCat WHERE T_Action = 'UPDATE')

		SELECT @I_Proc_Inserted AS proc_count_insert, @I_Proc_Updated AS proc_count_update, 
			   @I_Ctas_Inserted AS ctas_count_insert, @I_Ctas_Updated AS ctas_count_update,
			   @I_CtaCat_Inserted AS ctas_cat_count_insert, @I_CtaCat_Updated AS ctas_cat_count_update

		COMMIT TRANSACTION;

		SET @B_Resultado = 1
		SET @T_Message = CAST(@I_Proc_Inserted AS varchar) + ' procesos insertados | ' + CAST(@I_Proc_Updated AS varchar) + ' procesos actualizados ' 
						 + ' | ' + CAST(@I_Ctas_Inserted AS varchar) + ' cuentas insertadas | ' + CAST(@I_Ctas_Updated AS varchar) + ' cuentas actualizados ' 
						 + ' | ' + CAST(@I_CtaCat_Inserted AS varchar) + ' cuenta-categoría insertados | ' + CAST(@I_CtaCat_Updated AS varchar) + '  cuenta-categoría actualizados'
	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION;
		SET @B_Resultado = 0
		SET @T_Message = ERROR_MESSAGE() + ' LINE: ' + CAST(ERROR_LINE() AS varchar(10)) 
	END CATCH
END
GO