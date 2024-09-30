/*
==================================================================
	BD_OCEF_MigracionTP - 07_Procedures_PagoObligaciones
==================================================================
*/


USE BD_OCEF_MigracionTP
GO


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_Obligaciones_Pagos_MigracionTP_U_Validar_52_SinObligacionID')
	DROP PROCEDURE [dbo].[USP_Obligaciones_Pagos_MigracionTP_U_Validar_52_SinObligacionID]
GO

CREATE PROCEDURE USP_Obligaciones_Pagos_MigracionTP_U_Validar_52_SinObligacionIDPorID	
	@I_ProcedenciaID tinyint,
	@I_RowID	  int,
	@B_Resultado  bit output,
	@T_Message	  nvarchar(4000) OUTPUT	
AS
/*
  DECLARE	@I_ProcedenciaID  tinyint = 3,
			@I_RowID	      int = 3,
            @B_Resultado      bit,
			@T_Message	      nvarchar(4000)
  EXEC USP_Obligaciones_Pagos_MigracionTP_U_Validar_52_SinObligacionIDPorID @I_ProcedenciaID, @I_RowID, @B_Resultado output, @T_Message output
  SELECT @B_Resultado as resultado, @T_Message as mensaje
*/
BEGIN
	DECLARE @D_FecProceso datetime = GETDATE() 
	DECLARE @I_ObservID_sinOblId int = 52
	DECLARE @I_TablaID int = 7
	DECLARE @I_OblRowID int

	BEGIN TRANSACTION
	BEGIN TRY

		SET @I_OblRowID = (SELECT I_OblRowID FROM TR_Ec_Det_Pagos WHERE I_RowID = @I_RowID)

		UPDATE TR_Ec_Det_Pagos
		   SET B_Migrable = 0, 
			   D_FecEvalua = @D_FecProceso,
               D_FecMigrado = NULL
		 WHERE I_OblRowID IS NULL
			   AND I_RowID = @I_RowID
			   
 
		MERGE TI_ObservacionRegistroTabla AS TRG
		USING (SELECT @I_ObservID_sinOblId AS I_ObservID, @I_TablaID AS I_TablaID, I_RowID AS I_FilaTablaID, @D_FecProceso AS D_FecRegistro 
				 FROM TR_Ec_Det_Pagos 
				WHERE I_OblRowID IS NULL 
					  AND I_RowID = @I_RowID
			  ) AS SRC
		ON TRG.I_ObservID = SRC.I_ObservID AND TRG.I_TablaID = SRC.I_TablaID AND TRG.I_FilaTablaID = SRC.I_FilaTablaID
		WHEN MATCHED AND TRG.I_FilaTablaID = SRC.I_FilaTablaID THEN
			UPDATE SET D_FecRegistro = SRC.D_FecRegistro, 
					   B_Resuelto = 0
		WHEN NOT MATCHED BY TARGET AND SRC.I_FilaTablaID = SRC.I_FilaTablaID THEN
			INSERT (I_ObservID, I_TablaID, I_FilaTablaID, D_FecRegistro, I_ProcedenciaID)
			VALUES (SRC.I_ObservID, SRC.I_TablaID, SRC.I_FilaTablaID, SRC.D_FecRegistro, @I_ProcedenciaID);


		UPDATE OBS
		   SET D_FecResuelto = @D_FecProceso,
			   B_Resuelto = 1
		  FROM TI_ObservacionRegistroTabla OBS
			   INNER JOIN (SELECT * FROM TR_Ec_Det_Pagos WHERE I_OblRowID IS NOT NULL 
															   AND I_RowID = @I_RowID) DPG 
						  ON OBS.I_FilaTablaID = DPG.I_RowID
							 AND OBS.I_ProcedenciaID = DPG.I_ProcedenciaID
		 WHERE OBS.I_ObservID = @I_ObservID_sinOblId 
			   AND OBS.I_TablaID = @I_TablaID


		SET @B_Resultado = 1
		SET @T_Message =  '{' +
							 'Type: "summary", ' + 
							 'Title: "Actualizados", ' + 
							 'Value: ' + CAST(@@ROWCOUNT AS varchar) +  
						  '}'

		COMMIT TRANSACTION;
	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION
		SET @B_Resultado = 0
		SET @T_Message = '[{ ' +
							 'Type: "error", ' + 
							 'Title: "Error", ' + 
							 'Value: "' + ERROR_MESSAGE() + ' (Linea: ' + CAST(ERROR_LINE() AS varchar(11)) + ')."'  +
						  '}]' 
	END CATCH
END
GO
