USE BD_OCEF_MigracionTP
GO


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_U_MarcarConceptosPagoObligSinCuotaPago')
	DROP PROCEDURE [dbo].[USP_U_MarcarConceptosPagoObligSinCuotaPago]
GO

CREATE PROCEDURE [dbo].[USP_U_MarcarConceptosPagoObligSinCuotaPago]	
	@I_RowID	  int = NULL,
	@I_ProcedenciaID tinyint,
	@B_Resultado  bit output,
	@T_Message	  nvarchar(4000) OUTPUT	
AS
--declare @B_Resultado  bit,
--		@I_RowID	  int = NULL,
--		@I_ProcedenciaID tinyint = 3,
--		@T_Message	  nvarchar(4000)
--exec USP_U_MarcarConceptosPagoObligSinCuotaPago @I_RowID, @I_ProcedenciaID, @B_Resultado output, @T_Message output
--select @B_Resultado as resultado, @T_Message as mensaje
BEGIN
	DECLARE @D_FecProceso datetime = GETDATE() 
	DECLARE @I_ObservID_sinCuota int = 18
	DECLARE @I_ObservID_CuotaNoM int = 19
	DECLARE @I_TablaID int = 3
	DECLARE @I_Observados_sinCuota int = 0
	DECLARE @I_Observados_CuotaNoM int = 0
	
	BEGIN TRY 
		UPDATE	TR_Cp_Pri
		SET		B_Migrable = 0,
				D_FecEvalua = @D_FecProceso
		WHERE	NOT EXISTS (SELECT * FROM TR_Cp_Des WHERE CUOTA_PAGO = TR_Cp_Pri.CUOTA_PAGO) AND TIPO_OBLIG = 1
				AND Eliminado = 0
				AND I_ProcedenciaID = @I_ProcedenciaID
				AND I_RowID = IIF(@I_RowID IS NULL, I_RowID, @I_RowID)

		MERGE TI_ObservacionRegistroTabla AS TRG
		USING (SELECT @I_ObservID_sinCuota AS I_ObservID, @I_TablaID AS I_TablaID, I_RowID AS I_FilaTablaID, @D_FecProceso AS D_FecRegistro 
				 FROM TR_Cp_Pri WHERE NOT EXISTS (SELECT * FROM TR_Cp_Des WHERE CUOTA_PAGO = TR_Cp_Pri.CUOTA_PAGO) 
									  AND TIPO_OBLIG = 1
									  AND I_ProcedenciaID = @I_ProcedenciaID
									  AND Eliminado = 0
			  ) AS SRC
		ON TRG.I_ObservID = SRC.I_ObservID AND TRG.I_TablaID = SRC.I_TablaID AND TRG.I_FilaTablaID = SRC.I_FilaTablaID
		WHEN MATCHED AND TRG.I_FilaTablaID = IIF(@I_RowID IS NULL, TRG.I_FilaTablaID, @I_RowID) THEN
			UPDATE SET D_FecRegistro = SRC.D_FecRegistro, 
					   B_Resuelto = 0
		WHEN NOT MATCHED BY TARGET AND SRC.I_FilaTablaID = IIF(@I_RowID IS NULL, SRC.I_FilaTablaID, @I_RowID) THEN
			INSERT (I_ObservID, I_TablaID, I_FilaTablaID, D_FecRegistro, I_ProcedenciaID)
			VALUES (SRC.I_ObservID, SRC.I_TablaID, SRC.I_FilaTablaID, SRC.D_FecRegistro, @I_ProcedenciaID)
		WHEN NOT MATCHED BY SOURCE AND TRG.I_ObservID = @I_ObservID_sinCuota AND TRG.I_ProcedenciaID = @I_ProcedenciaID 
								   AND TRG.I_FilaTablaID = IIF(@I_RowID IS NULL, TRG.I_FilaTablaID, @I_RowID) THEN
			UPDATE SET D_FecResuelto = GETDATE(),
					   B_Resuelto = 1;


		UPDATE	TR_Cp_Pri
		SET		B_Migrable = 0,
				D_FecEvalua = @D_FecProceso
		WHERE	EXISTS (SELECT * FROM TR_Cp_Des WHERE CUOTA_PAGO = TR_Cp_Pri.CUOTA_PAGO 
													  AND Eliminado = 0 AND B_Migrable = 0)
				AND I_ProcedenciaID = @I_ProcedenciaID
			
		MERGE TI_ObservacionRegistroTabla AS TRG
		USING (SELECT @I_ObservID_CuotaNoM AS I_ObservID, @I_TablaID AS I_TablaID, I_RowID AS I_FilaTablaID, @D_FecProceso AS D_FecRegistro 
				 FROM TR_Cp_Pri WHERE EXISTS (SELECT * FROM TR_Cp_Des WHERE CUOTA_PAGO = TR_Cp_Pri.CUOTA_PAGO 
																			AND Eliminado = 0 AND B_Migrable = 0)
									  AND I_ProcedenciaID = @I_ProcedenciaID
			  ) AS SRC
		ON TRG.I_ObservID = SRC.I_ObservID AND TRG.I_TablaID = SRC.I_TablaID AND TRG.I_FilaTablaID = SRC.I_FilaTablaID
		WHEN MATCHED AND TRG.I_FilaTablaID = IIF(@I_RowID IS NULL, TRG.I_FilaTablaID, @I_RowID) THEN
			UPDATE SET D_FecRegistro = SRC.D_FecRegistro, 
					   B_Resuelto = 0
		WHEN NOT MATCHED BY TARGET AND SRC.I_FilaTablaID = IIF(@I_RowID IS NULL, SRC.I_FilaTablaID, @I_RowID) THEN
			INSERT (I_ObservID, I_TablaID, I_FilaTablaID, D_FecRegistro, I_ProcedenciaID)
			VALUES (SRC.I_ObservID, SRC.I_TablaID, SRC.I_FilaTablaID, SRC.D_FecRegistro, @I_ProcedenciaID)
		WHEN NOT MATCHED BY SOURCE AND TRG.I_ObservID = @I_ObservID_CuotaNoM AND TRG.I_ProcedenciaID = @I_ProcedenciaID
								   AND TRG.I_FilaTablaID = IIF(@I_RowID IS NULL, TRG.I_FilaTablaID, @I_RowID) THEN
			UPDATE SET D_FecResuelto = GETDATE(),
					   B_Resuelto = 1;

		SET @I_Observados_sinCuota = (SELECT COUNT(*) FROM TI_ObservacionRegistroTabla WHERE I_ObservID = @I_ObservID_sinCuota AND I_TablaID = @I_TablaID)
		SET @I_Observados_CuotaNoM = (SELECT COUNT(*) FROM TI_ObservacionRegistroTabla WHERE I_ObservID = @I_ObservID_CuotaNoM AND I_TablaID = @I_TablaID)

		SET @B_Resultado = 1
		SET @T_Message = CAST(@I_Observados_sinCuota AS varchar) + ' sin cuota de pago |' + CAST(@I_Observados_CuotaNoM AS varchar) +  ' con cuota de pago sin migrar.'
	END TRY
	BEGIN CATCH
		SET @B_Resultado = 0
		SET @T_Message = ERROR_MESSAGE() + ' LINE: ' + CAST(ERROR_LINE() AS varchar(10)) 
	END CATCH
END
