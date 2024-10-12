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

CREATE PROCEDURE USP_Obligaciones_Pagos_MigracionTP_U_Validar_52_SinObligacionID	
	@I_ProcedenciaID tinyint,
	@T_Anio	      varchar(4),
	@B_Resultado  bit output,
	@T_Message	  nvarchar(4000) OUTPUT	
AS
/*
	DESCRIPCION: Marcar TR_Ec_Det_Pagos con B_Migrable = 0 los pagos con I_OblRowID = NULL  para la procedencia y a�o

	DECLARE	@I_ProcedenciaID	tinyint = 2,
			@T_Anio	      varchar(4) = '2016',
			@B_Resultado  bit,
			@T_Message	  nvarchar(4000)
	EXEC USP_Obligaciones_Pagos_MigracionTP_U_Validar_52_SinObligacionID @I_ProcedenciaID, @T_Anio, @B_Resultado output, @T_Message output
	SELECT @B_Resultado as resultado, @T_Message as mensaje
*/
BEGIN
	DECLARE @I_Observados int = 0
	DECLARE @D_FecProceso datetime = GETDATE() 
	DECLARE @I_ObservID int = 52
	DECLARE @I_TablaID int = 7

	BEGIN TRANSACTION
	BEGIN TRY

		UPDATE TR_Ec_Det_Pagos
		   SET B_Migrable = 0, 
			   D_FecMigrado = @D_FecProceso
		 WHERE I_OblRowID IS NULL
			   AND I_ProcedenciaID = @I_ProcedenciaID
			   AND Ano = @T_Anio
	 
		MERGE TI_ObservacionRegistroTabla AS TRG
		USING (SELECT @I_ObservID AS I_ObservID, @I_TablaID AS I_TablaID, I_RowID AS I_FilaTablaID, @D_FecProceso AS D_FecRegistro 
				 FROM TR_Ec_Det_Pagos 
				WHERE I_OblRowID IS NULL
					  AND I_ProcedenciaID = @I_ProcedenciaID
					  AND Ano = @T_Anio
			  ) AS SRC
		ON TRG.I_ObservID = SRC.I_ObservID AND TRG.I_TablaID = SRC.I_TablaID AND TRG.I_FilaTablaID = SRC.I_FilaTablaID
		WHEN MATCHED AND TRG.I_FilaTablaID = SRC.I_FilaTablaID THEN
			UPDATE SET D_FecRegistro = SRC.D_FecRegistro, 
					   B_Resuelto = 0
		WHEN NOT MATCHED BY TARGET THEN
			INSERT (I_ObservID, I_TablaID, I_FilaTablaID, D_FecRegistro, I_ProcedenciaID)
			VALUES (SRC.I_ObservID, SRC.I_TablaID, SRC.I_FilaTablaID, SRC.D_FecRegistro, @I_ProcedenciaID);


		UPDATE OBS
		   SET D_FecResuelto = @D_FecProceso,
			   B_Resuelto = 1
		  FROM TI_ObservacionRegistroTabla OBS
			   INNER JOIN (SELECT * FROM TR_Ec_Det_Pagos 
							WHERE I_OblRowID IS NOT NULL 
								  AND Ano = @T_Anio 
								  AND I_ProcedenciaID = @I_ProcedenciaID
						  ) DPG 
						  ON OBS.I_FilaTablaID = DPG.I_RowID
							 AND OBS.I_ProcedenciaID = DPG.I_ProcedenciaID
		 WHERE OBS.I_ObservID = @I_ObservID 
			   AND OBS.I_TablaID = @I_TablaID

		SET @I_Observados = (SELECT COUNT(*) 
							  FROM TI_ObservacionRegistroTabla OBS 
									INNER JOIN TR_Ec_Det_Pagos DPG ON OBS.I_FilaTablaID = DPG.I_RowID 
																	  AND DPG.I_ProcedenciaID = OBS.I_ProcedenciaID
																	  AND OBS.I_TablaID = @I_TablaID 
							  WHERE OBS.I_ObservID = @I_ObservID
									AND DPG.Ano = @T_Anio 
									AND OBS.B_Resuelto = 0 
									AND OBS.I_ProcedenciaID = @I_ProcedenciaID)

		SELECT @I_Observados as cant_obs, @D_FecProceso as fec_proceso
		
		COMMIT TRANSACTION;

		SET @B_Resultado = 1
		SET @T_Message =  '{' +
							 'Type: "summary", ' + 
							 'Title: "Observados", ' + 
							 'Value: ' + CAST(@I_Observados AS varchar) +  
						  '}'
	END TRY
	BEGIN CATCH
		IF(@@TRANCOUNT > 0)
		BEGIN
			ROLLBACK TRANSACTION
		END

		SET @B_Resultado = 0
		SET @T_Message = '[{ ' +
							 'Type: "error", ' + 
							 'Title: "Error", ' + 
							 'Value: "' + ERROR_MESSAGE() + ' (Linea: ' + CAST(ERROR_LINE() AS varchar(11)) + ')."'  +
						  '}]' 
	END CATCH
END
GO



IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_Obligaciones_Pagos_MigracionTP_U_Validar_53_MontoPagadoDetalle')
	DROP PROCEDURE [dbo].[USP_Obligaciones_Pagos_MigracionTP_U_Validar_53_MontoPagadoDetalle]
GO

CREATE PROCEDURE USP_Obligaciones_Pagos_MigracionTP_U_Validar_53_MontoPagadoDetalle	
	@I_ProcedenciaID tinyint,
	@T_Anio	      varchar(4),
	@B_Resultado  bit output,
	@T_Message	  nvarchar(4000) OUTPUT	
AS
/*
  	DESCRIPCION: Marcar TR_Ec_Det_Pagos con B_Migrable = 0 los pagos cuyo monto no coincida con el monto acumulado del detalle con estado pagado = 1 y 
				 eliminado = 0  para la procedencia y a�o

	DECLARE	@I_ProcedenciaID	tinyint = 1,
			@T_Anio	      varchar(4) = '2010',
			@B_Resultado  bit,
			@T_Message	  nvarchar(4000)
	EXEC USP_Obligaciones_Pagos_MigracionTP_U_Validar_53_MontoPagadoDetalle @I_ProcedenciaID, @T_Anio, @B_Resultado output, @T_Message output
	SELECT @B_Resultado as resultado, @T_Message as mensaj
*/
BEGIN
	DECLARE @I_Observados int = 0
	DECLARE @D_FecProceso datetime = GETDATE() 
	DECLARE @I_ObservID int = 53
	DECLARE @I_TablaID int = 7

	BEGIN TRANSACTION
	BEGIN TRY

		SELECT I_OblRowID, SUM(Monto) Monto
		  INTO #temp_detalle_monto_sum
		  FROM TR_Ec_Det
		 WHERE Ano = @T_Anio
			   AND I_ProcedenciaID = @I_ProcedenciaID
			   AND Eliminado = 0
			   AND Pagado = 1
		 GROUP BY I_OblRowID

		SELECT det_pg.I_OblRowID  
		  INTO #temp_detalle_monto_pago_monto
		  FROM TR_Ec_Det_Pagos det_pg
			   INNER JOIN #temp_detalle_monto_sum tmp ON det_pg.I_OblRowID = tmp.I_OblRowID
		 WHERE det_pg.Monto <> tmp.Monto
		 	   AND Concepto = 0
			   AND Pagado = 1
			   AND Eliminado = 0

		UPDATE Det_pg
		   SET B_Migrable = 0,
			   D_FecEvalua = @D_FecProceso
		  FROM TR_Ec_Det_Pagos Det_pg 
			   INNER JOIN #temp_detalle_monto_pago_monto tmp ON Det_pg.I_OblRowID = tmp.I_OblRowID

		MERGE TI_ObservacionRegistroTabla AS TRG
		USING (SELECT @I_ObservID AS I_ObservID, @I_TablaID AS I_TablaID, Det_pg.I_RowID AS I_FilaTablaID, 
					  @D_FecProceso AS D_FecRegistro, Det_pg.I_ProcedenciaID 
				 FROM TR_Ec_Det_Pagos Det_pg  
			   		  INNER JOIN #temp_detalle_monto_pago_monto tmp ON Det_pg.I_OblRowID = tmp.I_OblRowID
			  ) AS SRC
		ON TRG.I_ObservID = SRC.I_ObservID AND TRG.I_TablaID = SRC.I_TablaID AND TRG.I_FilaTablaID = SRC.I_FilaTablaID
		WHEN MATCHED AND TRG.I_ProcedenciaID = SRC.I_ProcedenciaID THEN
			UPDATE SET D_FecRegistro = SRC.D_FecRegistro
		WHEN NOT MATCHED BY TARGET THEN
			INSERT (I_ObservID, I_TablaID, I_FilaTablaID, D_FecRegistro, I_ProcedenciaID)
			VALUES (SRC.I_ObservID, SRC.I_TablaID, SRC.I_FilaTablaID, SRC.D_FecRegistro, @I_ProcedenciaID);
		
		UPDATE OBS
		   SET D_FecResuelto = @D_FecProceso,
		   	   B_Resuelto = 1
		  FROM TI_ObservacionRegistroTabla OBS
		  	   INNER JOIN (SELECT det_pg.I_RowID, det_pg.I_ProcedenciaID, tmp.I_OblRowID as TempOblRowID
			   				 FROM TR_Ec_Det_Pagos det_pg
								  LEFT JOIN #temp_detalle_monto_pago_monto tmp ON tmp.I_OblRowID = det_pg.I_OblRowID
							WHERE tmp.I_OblRowID IS NULL
								  AND det_pg.Ano = @T_Anio
								  AND det_pg.I_ProcedenciaID = @I_ProcedenciaID
			   			  ) DET_PG ON OBS.I_FilaTablaID = DET_PG.I_RowID
						  		   AND OBS.I_ProcedenciaID = DET_PG.I_ProcedenciaID 
		 WHERE OBS.I_ObservID = @I_ObservID 
		 	   AND OBS.I_TablaID = @I_TablaID 
		
		SET @I_Observados = (SELECT COUNT(*) 
							   FROM TI_ObservacionRegistroTabla OBS 
									INNER JOIN TR_Ec_Det_Pagos DET_PG ON OBS.I_FilaTablaID = DET_PG.I_RowID 
																	  AND DET_PG.I_ProcedenciaID = OBS.I_ProcedenciaID
							  WHERE OBS.I_ObservID = @I_ObservID 
									AND DET_PG.Ano = @T_Anio
									AND DET_PG.I_ProcedenciaID = @I_ProcedenciaID 
									AND OBS.B_Resuelto = 0
							)

		SELECT @I_Observados as cant_obs, @D_FecProceso as fec_proceso		 

		COMMIT TRANSACTION;

		SET @B_Resultado = 1
		SET @T_Message = '{ ' +
							 'Type: "summary", ' + 
							 'Title: "Observados", ' + 
							 'Value: ' + CAST(@I_Observados AS varchar) +
						 '}' 


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


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_Obligaciones_Pagos_MigracionTP_U_Validar_53_MontoPagadoDetallePorID')
	DROP PROCEDURE [dbo].[USP_Obligaciones_Pagos_MigracionTP_U_Validar_53_MontoPagadoDetallePorID]
GO

CREATE PROCEDURE USP_Obligaciones_Pagos_MigracionTP_U_Validar_53_MontoPagadoDetallePorID	
	@I_OblRowID	  int,
	@B_Resultado  bit output,
	@T_Message	  nvarchar(4000) OUTPUT	
AS
/*
  	DESCRIPCION: Marcar TR_Ec_Det_Pagos con B_Migrable = 0 el pago cuyo monto no coincida con el monto acumulado del detalle con estado pagado = 1 y eliminado = 0 para el I_OblRowID

	DECLARE	@I_OblRowID	  int = 3,
			@B_Resultado  bit,
			@T_Message	  nvarchar(4000)
	EXEC USP_Obligaciones_Pagos_MigracionTP_U_Validar_53_MontoPagadoDetallePorID @I_OblRowID, @B_Resultado output, @T_Message output
	SELECT @B_Resultado as resultado, @T_Message as mensaj
*/
BEGIN
	DECLARE @I_Observados int = 0
	DECLARE @D_FecProceso datetime = GETDATE() 
	DECLARE @I_ObservID int = 53
	DECLARE @I_TablaID int = 7

	BEGIN TRANSACTION
	BEGIN TRY

		SELECT I_OblRowID, SUM(Monto) Monto
		  INTO #temp_detalle_monto_sum
		  FROM TR_Ec_Det
		 WHERE Eliminado = 0
		 	   AND Pagado = 1
		 	   AND I_OblRowID = @I_OblRowID
		 GROUP BY I_OblRowID

		SELECT det_pg.I_OblRowID  
		  INTO #temp_detalle_monto_pago_monto
		  FROM TR_Ec_Det_Pagos det_pg
			   INNER JOIN #temp_detalle_monto_sum tmp ON det_pg.I_OblRowID = tmp.I_OblRowID
		 WHERE det_pg.Monto <> tmp.Monto
		 	   AND Concepto = 0
			   AND Pagado = 1
			   AND Eliminado = 0

		UPDATE Det_pg
		   SET B_Migrable = 0,
			   D_FecEvalua = @D_FecProceso
		  FROM TR_Ec_Det_Pagos Det_pg 
			   INNER JOIN #temp_detalle_monto_pago_monto tmp ON Det_pg.I_OblRowID = tmp.I_OblRowID

		MERGE TI_ObservacionRegistroTabla AS TRG
		USING (SELECT @I_ObservID AS I_ObservID, @I_TablaID AS I_TablaID, Det_pg.I_RowID AS I_FilaTablaID, 
					  @D_FecProceso AS D_FecRegistro, Det_pg.I_ProcedenciaID 
				 FROM TR_Ec_Det_Pagos Det_pg  
			   		  INNER JOIN #temp_detalle_monto_pago_monto tmp ON Det_pg.I_OblRowID = tmp.I_OblRowID
			  ) AS SRC
		ON TRG.I_ObservID = SRC.I_ObservID AND TRG.I_TablaID = SRC.I_TablaID AND TRG.I_FilaTablaID = SRC.I_FilaTablaID
		WHEN MATCHED AND TRG.I_ProcedenciaID = SRC.I_ProcedenciaID THEN
			UPDATE SET D_FecRegistro = SRC.D_FecRegistro
		WHEN NOT MATCHED BY TARGET THEN
			INSERT (I_ObservID, I_TablaID, I_FilaTablaID, D_FecRegistro, I_ProcedenciaID)
			VALUES (SRC.I_ObservID, SRC.I_TablaID, SRC.I_FilaTablaID, SRC.D_FecRegistro, SRC.I_ProcedenciaID);
		
		UPDATE OBS
		   SET D_FecResuelto = @D_FecProceso,
		   	   B_Resuelto = 1
		  FROM TI_ObservacionRegistroTabla OBS
		  	   INNER JOIN (SELECT det_pg.I_RowID, det_pg.I_ProcedenciaID, tmp.I_OblRowID as TempOblRowID
			   				 FROM TR_Ec_Det_Pagos det_pg
								  LEFT JOIN #temp_detalle_monto_pago_monto tmp ON tmp.I_OblRowID = det_pg.I_OblRowID
							WHERE tmp.I_OblRowID IS NULL
								  AND det_pg.I_OblRowID = @I_OblRowID
			   			  ) DET_PG ON OBS.I_FilaTablaID = DET_PG.I_RowID
						  		   AND OBS.I_ProcedenciaID = DET_PG.I_ProcedenciaID 
		 WHERE OBS.I_ObservID = @I_ObservID 
		 	   AND OBS.I_TablaID = @I_TablaID 
		
		SET @I_Observados = (SELECT COUNT(*) 
							   FROM TI_ObservacionRegistroTabla OBS 
									INNER JOIN TR_Ec_Det_Pagos DET_PG ON OBS.I_FilaTablaID = DET_PG.I_RowID 
																	  AND DET_PG.I_ProcedenciaID = OBS.I_ProcedenciaID
							  WHERE OBS.I_ObservID = @I_ObservID 
									AND DET_PG.I_OblRowID = @I_OblRowID 
									AND OBS.B_Resuelto = 0
							)

		SELECT @I_Observados as cant_obs, @D_FecProceso as fec_proceso		 

		COMMIT TRANSACTION;

		SET @B_Resultado = 1
		SET @T_Message = '{ ' +
							 'Type: "summary", ' + 
							 'Title: "Observados", ' + 
							 'Value: ' + CAST(@I_Observados AS varchar) +
						 '}' 
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


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_Obligaciones_Pagos_MigracionTP_U_Validar_54_EstadoPagadoObligacion')
	DROP PROCEDURE [dbo].[USP_Obligaciones_Pagos_MigracionTP_U_Validar_54_EstadoPagadoObligacion]
GO

CREATE PROCEDURE USP_Obligaciones_Pagos_MigracionTP_U_Validar_54_EstadoPagadoObligacion	
	@I_ProcedenciaID tinyint,
	@T_Anio	      varchar(4),
	@B_Resultado  bit output,
	@T_Message	  nvarchar(4000) OUTPUT	
AS
/*
  	DESCRIPCION: Marcar TR_Ec_Det_Pagos con B_Migrable = 0 cuando los estado pagado de la obligacion y el pago no coinciden para la procedencia y año.

	DECLARE	@I_ProcedenciaID	tinyint = 1,
			@T_Anio	      varchar(4) = '2010',
			@B_Resultado  bit,
			@T_Message	  nvarchar(4000)
	EXEC USP_Obligaciones_Pagos_MigracionTP_U_Validar_54_EstadoPagadoObligacion @I_ProcedenciaID, @T_Anio, @B_Resultado output, @T_Message output
	SELECT @B_Resultado as resultado, @T_Message as mensaje
*/
BEGIN
	DECLARE @I_Observados int = 0
	DECLARE @D_FecProceso datetime = GETDATE() 
	DECLARE @I_ObservID int = 54
	DECLARE @I_TablaID int = 7

	BEGIN TRANSACTION
	BEGIN TRY
		UPDATE EDP
		   SET B_Migrable = 0, 
			   D_FecMigrado = @D_FecProceso
		  FROM TR_Ec_Det_Pagos EDP
			   INNER JOIN TR_Ec_Obl EO ON EDP.I_OblRowID = EO.I_RowID
			   							  AND EDP.Eliminado = 0
		 WHERE ISNULL(EO.Pagado, 0) <> ISNULL(EDP.Pagado, 0)
		 	   AND Concepto = 0
			   AND EDP.I_ProcedenciaID = @I_ProcedenciaID
			   AND EDP.Ano = @T_Anio
		
		MERGE TI_ObservacionRegistroTabla AS TRG
		USING (SELECT @I_ObservID AS I_ObservID, @I_TablaID AS I_TablaID, EDP.I_RowID AS I_FilaTablaID, @D_FecProceso AS D_FecRegistro 
				 FROM TR_Ec_Det_Pagos EDP
					  INNER JOIN TR_Ec_Obl EO ON EDP.I_OblRowID = EO.I_RowID
												 AND EDP.Eliminado = 0
				WHERE ISNULL(EO.Pagado, 0) <> ISNULL(EDP.Pagado, 0)
					  AND EDP.I_ProcedenciaID = @I_ProcedenciaID
					  AND EDP.Ano = @T_Anio
					  AND Concepto = 0
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
			   INNER JOIN (SELECT EDP.* FROM TR_Ec_Det_Pagos EDP
								  INNER JOIN TR_Ec_Obl EO ON EDP.I_OblRowID = EO.I_RowID
							WHERE ISNULL(EO.Pagado, 0) = ISNULL(EDP.Pagado, 0) 
								  AND EDP.I_ProcedenciaID = @I_ProcedenciaID
								  AND EDP.Ano = @T_Anio
								  AND Concepto = 0
						  ) DPG ON OBS.I_FilaTablaID = DPG.I_RowID
		 WHERE OBS.I_ObservID = @I_ObservID 
			   AND OBS.I_TablaID = @I_TablaID


		SET @I_Observados = (SELECT COUNT(*) 
							   FROM TI_ObservacionRegistroTabla OBS 
									INNER JOIN TR_Ec_Det_Pagos DET_PG ON OBS.I_FilaTablaID = DET_PG.I_RowID 
																	  	 AND DET_PG.I_ProcedenciaID = OBS.I_ProcedenciaID
							  WHERE OBS.I_ObservID = @I_ObservID 
							  		AND OBS.I_TablaID = @I_TablaID
									AND DET_PG.I_ProcedenciaID = @I_ProcedenciaID 
									AND OBS.B_Resuelto = 0
							)

		SELECT @I_Observados as cant_obs, @D_FecProceso as fec_proceso		 

		COMMIT TRANSACTION;

		SET @B_Resultado = 1
		SET @T_Message = '{ ' +
							 'Type: "summary", ' + 
							 'Title: "Observados", ' + 
							 'Value: ' + CAST(@I_Observados AS varchar) +
						 '}' 
	END TRY
	BEGIN CATCH
		IF(@@TRANCOUNT > 0)
		BEGIN
			ROLLBACK TRANSACTION
		END

		SET @B_Resultado = 0
		SET @T_Message = '[{ ' +
							 'Type: "error", ' + 
							 'Title: "Error", ' + 
							 'Value: "' + ERROR_MESSAGE() + ' (Linea: ' + CAST(ERROR_LINE() AS varchar(11)) + ')."'  +
						  '}]' 
	END CATCH
END
GO



IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_Obligaciones_Pagos_MigracionTP_U_Validar_54_EstadoPagadoObligacionPorID')
	DROP PROCEDURE [dbo].[USP_Obligaciones_Pagos_MigracionTP_U_Validar_54_EstadoPagadoObligacionPorID]
GO

CREATE PROCEDURE USP_Obligaciones_Pagos_MigracionTP_U_Validar_54_EstadoPagadoObligacionPorID	
	@I_OblRowID	  int,
	@B_Resultado  bit output,
	@T_Message	  nvarchar(4000) OUTPUT	
AS
/*
  	DESCRIPCION: Marcar TR_Ec_Det_Pagos con B_Migrable = 0 cuando los estado pagado de la obligacion y el pago no coinciden para la I_OblRowID para la procedencia y a�o.

	DECLARE	@I_OblRowID	  int = 3,
			@B_Resultado  bit,
			@T_Message	  nvarchar(4000)
	EXEC USP_Obligaciones_Pagos_MigracionTP_U_Validar_54_EstadoPagadoObligacionPorID @I_OblRowID, @B_Resultado output, @T_Message output
	SELECT @B_Resultado as resultado, @T_Message as mensaj
*/
BEGIN
	DECLARE @I_Observados int = 0
	DECLARE @D_FecProceso datetime = GETDATE() 
	DECLARE @I_ObservID int = 54
	DECLARE @I_TablaID int = 7

	BEGIN TRANSACTION
	BEGIN TRY
		UPDATE EDP
		   SET B_Migrable = 0, 
			   D_FecMigrado = @D_FecProceso
		  FROM TR_Ec_Det_Pagos EDP
			   INNER JOIN TR_Ec_Obl EO ON EDP.I_OblRowID = EO.I_RowID
			   							  AND EDP.Eliminado = 0
		 WHERE ISNULL(EO.Pagado, 0) <> ISNULL(EDP.Pagado, 0)
		 	   AND Concepto = 0
			   AND EDP.I_OblRowID = @I_OblRowID
		
		MERGE TI_ObservacionRegistroTabla AS TRG
		USING (SELECT @I_ObservID AS I_ObservID, @I_TablaID AS I_TablaID, EDP.I_RowID AS I_FilaTablaID, 
					  @D_FecProceso AS D_FecRegistro, EDP.I_ProcedenciaID
				 FROM TR_Ec_Det_Pagos EDP
					  INNER JOIN TR_Ec_Obl EO ON EDP.I_OblRowID = EO.I_RowID
												 AND EDP.Eliminado = 0
				WHERE ISNULL(EO.Pagado, 0) <> ISNULL(EDP.Pagado, 0)
					  AND EDP.I_OblRowID = @I_OblRowID
					  AND Concepto = 0
			  ) AS SRC
		ON TRG.I_ObservID = SRC.I_ObservID AND TRG.I_TablaID = SRC.I_TablaID AND TRG.I_FilaTablaID = SRC.I_FilaTablaID
		WHEN MATCHED AND TRG.I_FilaTablaID = SRC.I_FilaTablaID THEN
			UPDATE SET D_FecRegistro = SRC.D_FecRegistro, 
					   B_Resuelto = 0
		WHEN NOT MATCHED BY TARGET AND SRC.I_FilaTablaID = SRC.I_FilaTablaID THEN
			INSERT (I_ObservID, I_TablaID, I_FilaTablaID, D_FecRegistro, I_ProcedenciaID)
			VALUES (SRC.I_ObservID, SRC.I_TablaID, SRC.I_FilaTablaID, SRC.D_FecRegistro, SRC.I_ProcedenciaID);

		UPDATE OBS
		   SET D_FecResuelto = @D_FecProceso,
			   B_Resuelto = 1
		  FROM TI_ObservacionRegistroTabla OBS
			   INNER JOIN (SELECT EDP.* FROM TR_Ec_Det_Pagos EDP
								  INNER JOIN TR_Ec_Obl EO ON EDP.I_OblRowID = EO.I_RowID
							WHERE ISNULL(EO.Pagado, 0) = ISNULL(EDP.Pagado, 0) 
								  AND EDP.I_OblRowID = @I_OblRowID
								  AND Concepto = 0
						  ) DPG ON OBS.I_FilaTablaID = DPG.I_RowID
		 WHERE OBS.I_ObservID = @I_ObservID 
			   AND OBS.I_TablaID = @I_TablaID


		SET @I_Observados = (SELECT COUNT(*) 
							   FROM TI_ObservacionRegistroTabla OBS 
									INNER JOIN TR_Ec_Det_Pagos DET_PG ON OBS.I_FilaTablaID = DET_PG.I_RowID 
																	  	 AND DET_PG.I_ProcedenciaID = OBS.I_ProcedenciaID
							  WHERE OBS.I_ObservID = @I_ObservID 
							  		AND OBS.I_TablaID = @I_TablaID
									AND DET_PG.I_OblRowID = @I_OblRowID 
									AND OBS.B_Resuelto = 0
							)

		SELECT @I_Observados as cant_obs, @D_FecProceso as fec_proceso		 

		COMMIT TRANSACTION;

		SET @B_Resultado = 1
		SET @T_Message = '{ ' +
							 'Type: "summary", ' + 
							 'Title: "Observados", ' + 
							 'Value: ' + CAST(@I_Observados AS varchar) +
						 '}' 
	END TRY
	BEGIN CATCH
		IF(@@TRANCOUNT > 0)
		BEGIN
			ROLLBACK TRANSACTION
		END

		SET @B_Resultado = 0
		SET @T_Message = '[{ ' +
							 'Type: "error", ' + 
							 'Title: "Error", ' + 
							 'Value: "' + ERROR_MESSAGE() + ' (Linea: ' + CAST(ERROR_LINE() AS varchar(11)) + ')."'  +
						  '}]' 
	END CATCH
END
GO


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_Obligaciones_Pagos_MigracionTP_U_Validar_55_ExisteEnDestinoConOtroBanco')
	DROP PROCEDURE [dbo].[USP_Obligaciones_Pagos_MigracionTP_U_Validar_55_ExisteEnDestinoConOtroBanco]
GO


CREATE PROCEDURE [dbo].[USP_Obligaciones_Pagos_MigracionTP_U_Validar_55_ExisteEnDestinoConOtroBanco]	
	@I_ProcedenciaID	tinyint,
	@T_Anio				varchar(4),
	@B_Resultado		bit output,
	@T_Message			nvarchar(4000) OUTPUT	
AS
/*
  	DESCRIPCION: Marcar TR_Ec_Det_Pagos con B_Migrable = 0 cuando el pago de la obligacion no migrada existe en la base de datos de destino para la procedencia y año.

	DECLARE @I_ProcedenciaID tinyint = 1,
			@T_Anio		 varchar(4) = '2010', 
			@B_Resultado  bit, 
			@T_Message nvarchar(4000)
	EXEC USP_Obligaciones_Pagos_MigracionTP_U_Validar_55_ExisteEnDestinoConOtroBanco @I_ProcedenciaID, @T_Anio, @B_Resultado output, @T_Message output
	SELECT @B_Resultado as resultado, @T_Message as mensaje
*/
BEGIN
	DECLARE @I_Observados int = 0
	DECLARE @D_FecProceso datetime = GETDATE() 
	DECLARE @I_ObservID int = 55
	DECLARE @I_TablaID int = 7

	BEGIN TRANSACTION
	BEGIN TRY
		
		SELECT Det_pg.* 
		  INTO #temp_pago_existe_otro_banco 
		  FROM BD_OCEF_CtasPorCobrar.dbo.TR_PagoBanco Ctas_pbco 
			   INNER JOIN TR_Ec_Det_Pagos Det_pg ON Ctas_pbco.C_CodOperacion = Det_pg.Nro_recibo
			   										AND Ctas_pbco.I_MontoPago = Det_pg.Monto
													AND Ctas_pbco.D_FecPago = Det_pg.Fch_pago
													AND Ctas_pbco.C_CodDepositante = Det_pg.Cod_alu
		 WHERE Ctas_pbco.I_EntidadFinanID <> 1
			   AND ISNULL(Ctas_pbco.B_Migrado, 0) = 0
			   AND Det_pg.Concepto = 0
			   AND Det_pg.Ano = @T_Anio 
			   AND Det_pg.I_ProcedenciaID = @I_ProcedenciaID 

		UPDATE Det_pg
		   SET B_Migrable = 0,
		   	   D_FecEvalua = @D_FecProceso
		  FROM TR_Ec_Det_Pagos Det_pg
			   INNER JOIN #temp_pago_existe_otro_banco tmp ON Det_pg.I_RowID = tmp.I_RowID
		 
		MERGE TI_ObservacionRegistroTabla AS TRG
		USING (SELECT @I_ObservID AS I_ObservID, @I_TablaID AS I_TablaID, EDP.I_RowID AS I_FilaTablaID, @D_FecProceso AS D_FecRegistro 
				 FROM TR_Ec_Det_Pagos EDP
					  INNER JOIN #temp_pago_existe_otro_banco tmp ON EDP.I_RowID = tmp.I_RowID
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
			   INNER JOIN (SELECT EDP.* FROM TR_Ec_Det_Pagos EDP
								  LEFT JOIN #temp_pago_existe_otro_banco tmp ON EDP.I_RowID = tmp.I_RowID
							WHERE EDP.I_ProcedenciaID = @I_ProcedenciaID
								  AND EDP.Ano = @T_Anio
								  AND EDP.Concepto = 0
								  AND tmp.I_RowID IS NULL 
						  ) DPG ON OBS.I_FilaTablaID = DPG.I_RowID
		 WHERE OBS.I_ObservID = @I_ObservID 
			   AND OBS.I_TablaID = @I_TablaID


		SET @I_Observados = (SELECT COUNT(*) 
							   FROM TI_ObservacionRegistroTabla OBS 
									INNER JOIN TR_Ec_Det_Pagos DET_PG ON OBS.I_FilaTablaID = DET_PG.I_RowID 
																	  	 AND DET_PG.I_ProcedenciaID = OBS.I_ProcedenciaID
							  WHERE OBS.I_ObservID = @I_ObservID 
							  		AND OBS.I_TablaID = @I_TablaID
									AND DET_PG.I_ProcedenciaID = @I_ProcedenciaID 
									AND OBS.B_Resuelto = 0
							)

		SELECT @I_Observados as cant_obs, @D_FecProceso as fec_proceso		 

		COMMIT TRANSACTION;

		SET @B_Resultado = 1
		SET @T_Message = '{ ' +
							 'Type: "summary", ' + 
							 'Title: "Observados", ' + 
							 'Value: ' + CAST(@I_Observados AS varchar) +
						 '}' 
	END TRY
	BEGIN CATCH
		IF(@@TRANCOUNT > 0)
		BEGIN
			ROLLBACK TRANSACTION
		END

		SET @B_Resultado = 0
		SET @T_Message = '[{ ' +
							 'Type: "error", ' + 
							 'Title: "Error", ' + 
							 'Value: "' + ERROR_MESSAGE() + ' (Linea: ' + CAST(ERROR_LINE() AS varchar(11)) + ')."'  +
						  '}]' 
	END CATCH
END
GO


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_Obligaciones_Pagos_MigracionTP_U_Validar_55_ExisteEnDestinoConOtroBancoPorID')
	DROP PROCEDURE [dbo].[USP_Obligaciones_Pagos_MigracionTP_U_Validar_55_ExisteEnDestinoConOtroBancoPorID]
GO


CREATE PROCEDURE [dbo].[USP_Obligaciones_Pagos_MigracionTP_U_Validar_55_ExisteEnDestinoConOtroBancoPorID]	
	@I_OblRowID			int,
	@B_Resultado		bit output,
	@T_Message			nvarchar(4000) OUTPUT	
AS
/*
  	DESCRIPCION: Marcar TR_Ec_Det_Pagos con B_Migrable = 0 cuando el pago de la obligacion I_OblRowID no migrada existe en la base de datos de destino para la procedencia y a�o.
	
	DECLARE @I_OblRowID	 int,
			@B_Resultado  bit, 
			@T_Message nvarchar(4000)
	EXEC USP_Obligaciones_Pagos_MigracionTP_U_Validar_55_ExisteEnDestinoConOtroBancoPorID @I_OblRowID, @B_Resultado output, @T_Message output
	SELECT @B_Resultado as resultado, @T_Message as mensaje
*/
BEGIN

	DECLARE @I_Observados int = 0
	DECLARE @D_FecProceso datetime = GETDATE() 
	DECLARE @I_ObservID int = 55
	DECLARE @I_TablaID int = 7
	
	BEGIN TRANSACTION;
	BEGIN TRY 
		
		SELECT Det_pg.* 
		  INTO #temp_pago_existe_otro_banco 
		  FROM BD_OCEF_CtasPorCobrar.dbo.TR_PagoBanco Ctas_pbco 
			   INNER JOIN TR_Ec_Det_Pagos Det_pg ON Ctas_pbco.C_CodOperacion = Det_pg.Nro_recibo
			   										AND Ctas_pbco.I_MontoPago = Det_pg.Monto
													AND Ctas_pbco.D_FecPago = Det_pg.Fch_pago
													AND Ctas_pbco.C_CodDepositante = Det_pg.Cod_alu
		 WHERE Ctas_pbco.I_EntidadFinanID <> 1
			   AND ISNULL(Ctas_pbco.B_Migrado, 0) = 0
			   AND Det_pg.Concepto = 0
			   AND Det_pg.I_OblRowID = @I_OblRowID

		UPDATE Det_pg
		   SET B_Migrable = 0,
		   	   D_FecEvalua = @D_FecProceso
		  FROM TR_Ec_Det_Pagos Det_pg
			   INNER JOIN #temp_pago_existe_otro_banco tmp ON Det_pg.I_RowID = tmp.I_RowID
		 
		MERGE TI_ObservacionRegistroTabla AS TRG
		USING (SELECT @I_ObservID AS I_ObservID, @I_TablaID AS I_TablaID, EDP.I_RowID AS I_FilaTablaID, 
					  @D_FecProceso AS D_FecRegistro, EDP.I_ProcedenciaID 
				 FROM TR_Ec_Det_Pagos EDP
					  INNER JOIN #temp_pago_existe_otro_banco tmp ON EDP.I_RowID = tmp.I_RowID
			  ) AS SRC
		ON TRG.I_ObservID = SRC.I_ObservID AND TRG.I_TablaID = SRC.I_TablaID AND TRG.I_FilaTablaID = SRC.I_FilaTablaID
		WHEN MATCHED AND TRG.I_FilaTablaID = SRC.I_FilaTablaID THEN
			UPDATE SET D_FecRegistro = SRC.D_FecRegistro, 
					   B_Resuelto = 0
		WHEN NOT MATCHED BY TARGET THEN
			INSERT (I_ObservID, I_TablaID, I_FilaTablaID, D_FecRegistro, I_ProcedenciaID)
			VALUES (SRC.I_ObservID, SRC.I_TablaID, SRC.I_FilaTablaID, SRC.D_FecRegistro, SRC.I_ProcedenciaID);

		UPDATE OBS
		   SET D_FecResuelto = @D_FecProceso,
			   B_Resuelto = 1
		  FROM TI_ObservacionRegistroTabla OBS
			   INNER JOIN (SELECT EDP.* FROM TR_Ec_Det_Pagos EDP
								  LEFT JOIN #temp_pago_existe_otro_banco tmp ON EDP.I_RowID = tmp.I_RowID
							WHERE EDP.I_OblRowID = @I_OblRowID
								  AND EDP.Concepto = 0
								  AND tmp.I_RowID IS NULL 
						  ) DPG ON OBS.I_FilaTablaID = DPG.I_RowID
		 WHERE OBS.I_ObservID = @I_ObservID 
			   AND OBS.I_TablaID = @I_TablaID


		SET @I_Observados = (SELECT COUNT(*) 
							   FROM TI_ObservacionRegistroTabla OBS 
									INNER JOIN TR_Ec_Det_Pagos DET_PG ON OBS.I_FilaTablaID = DET_PG.I_RowID 
																	  	 AND DET_PG.I_ProcedenciaID = OBS.I_ProcedenciaID
							  WHERE OBS.I_ObservID = @I_ObservID 
							  		AND OBS.I_TablaID = @I_TablaID
									AND DET_PG.I_OblRowID = @I_OblRowID 
									AND OBS.B_Resuelto = 0
							)

		SELECT @I_Observados as cant_obs, @D_FecProceso as fec_proceso		 

		COMMIT TRANSACTION
					
		SET @B_Resultado = 1
		SET @T_Message = '[{ ' +
							 'Type: "summary", ' + 
							 'Title: "Observados", ' + 
							 'Value: ' + CAST(@I_Observados AS varchar) +
						  '}]' 
	END TRY
	BEGIN CATCH
		IF(@@TRANCOUNT > 0)
		BEGIN
			ROLLBACK TRANSACTION
		END

		SET @B_Resultado = 0
		SET @T_Message = '[{ ' +
							 'Type: "error", ' + 
							 'Title: "Error", ' + 
							 'Value: "' + ERROR_MESSAGE() + ' (Linea: ' + CAST(ERROR_LINE() AS varchar(11)) + ')."'  +
						  '}]' 
	END CATCH
END
GO


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_Obligaciones_Pagos_MigracionTP_U_Validar_56_DetalleObservado')
	DROP PROCEDURE [dbo].[USP_Obligaciones_Pagos_MigracionTP_U_Validar_56_DetalleObservado]
GO

CREATE PROCEDURE [dbo].[USP_Obligaciones_Pagos_MigracionTP_U_Validar_56_DetalleObservado]
	@I_ProcedenciaID tinyint,
	@T_Anio			varchar(4) = NULL,
	@B_Resultado	bit output,
	@T_Message		nvarchar(4000) OUTPUT	
AS
/*
  	DESCRIPCION: Marcar TR_Ec_Det_Pagos con B_Migrable = 0 cuando los conceptos en el detalle con estado pagado 1 y eliminado 0 tienen B_Migrable = 0
				 para la procedencia y a�o.

	DECLARE @I_ProcedenciaID	tinyint = 3, 
			@T_Anio		  varchar(4) = '2005',
			@B_Resultado  bit,
			@T_Message    nvarchar(4000)
	EXEC USP_Obligaciones_Pagos_MigracionTP_U_Validar_56_DetalleObservado @I_ProcedenciaID, @T_Anio, @B_Resultado output, @T_Message output
	SELECT @B_Resultado as resultado, @T_Message as mensaje
*/
BEGIN
	DECLARE @I_Observados int = 0
	DECLARE @D_FecProceso datetime = GETDATE() 
	DECLARE @I_ObservID int = 56
	DECLARE @I_TablaID int = 7
	DECLARE @I_DetTablaID int = 4

	BEGIN TRANSACTION
	BEGIN TRY
		
		SELECT Det.*
		  INTO #temp_obl_det_observada
		  FROM TR_Ec_Det Det 
			   INNER JOIN TI_ObservacionRegistroTabla Obs ON Det.I_RowID = Obs.I_FilaTablaID
															 AND Det.I_ProcedenciaID = Obs.I_ProcedenciaID
															 AND Obs.I_TablaID = @I_DetTablaID
		 WHERE Obs.B_Resuelto = 0
			   AND Det.Ano = @T_Anio 
			   AND Det.I_ProcedenciaID = @I_ProcedenciaID


		UPDATE Det_Pagos 
		   SET B_Migrable = 0, 
			   D_FecMigrado = @D_FecProceso
		  FROM TR_Ec_Det_Pagos Det_Pagos
			   INNER JOIN #temp_obl_det_observada tmp ON Det_Pagos.I_OblRowID = tmp.I_OblRowID 

		MERGE TI_ObservacionRegistroTabla AS TRG
		USING (SELECT @I_ObservID AS I_ObservID, @I_TablaID AS I_TablaID, Det_Pagos.I_RowID AS I_FilaTablaID, @D_FecProceso AS D_FecRegistro 
				 FROM TR_Ec_Det_Pagos Det_Pagos
				      INNER JOIN #temp_obl_det_observada tmp ON Det_Pagos.I_OblRowID = tmp.I_OblRowID 
			  ) AS SRC
		ON TRG.I_ObservID = SRC.I_ObservID AND TRG.I_TablaID = SRC.I_TablaID AND TRG.I_FilaTablaID = SRC.I_FilaTablaID
		WHEN MATCHED AND TRG.I_FilaTablaID = SRC.I_FilaTablaID THEN
			UPDATE SET D_FecRegistro = SRC.D_FecRegistro, 
					   B_Resuelto = 0
		WHEN NOT MATCHED BY TARGET THEN
			INSERT (I_ObservID, I_TablaID, I_FilaTablaID, D_FecRegistro, I_ProcedenciaID)
			VALUES (SRC.I_ObservID, SRC.I_TablaID, SRC.I_FilaTablaID, SRC.D_FecRegistro, @I_ProcedenciaID);


		UPDATE OBS
		   SET D_FecResuelto = @D_FecProceso,
			   B_Resuelto = 1
		  FROM TI_ObservacionRegistroTabla OBS
			   INNER JOIN (SELECT EDP.* FROM TR_Ec_Det_Pagos EDP
								  LEFT JOIN #temp_obl_det_observada tmp ON EDP.I_OblRowID = tmp.I_OblRowID
							WHERE EDP.I_ProcedenciaID = @I_ProcedenciaID
								  AND EDP.Ano = @T_Anio
								  AND tmp.I_RowID IS NULL 
						  ) DPG ON OBS.I_FilaTablaID = DPG.I_RowID
		 WHERE OBS.I_ObservID = @I_ObservID 
			   AND OBS.I_TablaID = @I_TablaID


		SET @I_Observados = (SELECT COUNT(*) 
							   FROM TI_ObservacionRegistroTabla OBS 
									INNER JOIN TR_Ec_Det_Pagos DET_PG ON OBS.I_FilaTablaID = DET_PG.I_RowID 
																	  	 AND DET_PG.I_ProcedenciaID = OBS.I_ProcedenciaID
							  WHERE OBS.I_ObservID = @I_ObservID 
							  		AND OBS.I_TablaID = @I_TablaID
									AND DET_PG.I_ProcedenciaID = @I_ProcedenciaID 
									AND OBS.B_Resuelto = 0
							)

		SELECT @I_Observados as cant_obs, @D_FecProceso as fec_proceso		 

		COMMIT TRANSACTION 

		SET @B_Resultado = 1
		SET @T_Message = '{ ' +
							 'Type: "summary", ' + 
							 'Title: "Observados", ' + 
							 'Value: ' + CAST(@I_Observados AS varchar) +
						 '}' 
	END TRY
	BEGIN CATCH
		IF(@@TRANCOUNT > 0)
		BEGIN
			ROLLBACK TRANSACTION
		END

		SET @B_Resultado = 0
		SET @T_Message = '[{ ' +
							 'Type: "error", ' + 
							 'Title: "Error", ' + 
							 'Value: "' + ERROR_MESSAGE() + ' (Linea: ' + CAST(ERROR_LINE() AS varchar(11)) + ')."'  +
						  '}]' 
	END CATCH
END
GO


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_Obligaciones_Pagos_MigracionTP_U_Validar_56_DetalleObservadoPorOblID')
	DROP PROCEDURE [dbo].[USP_Obligaciones_Pagos_MigracionTP_U_Validar_56_DetalleObservadoPorOblID]
GO

CREATE PROCEDURE [dbo].[USP_Obligaciones_Pagos_MigracionTP_U_Validar_56_DetalleObservadoPorOblID]
	@I_OblRowID			int,
	@B_Resultado	bit output,
	@T_Message		nvarchar(4000) OUTPUT	
AS
/*
  	DESCRIPCION: Marcar TR_Ec_Det_Pagos con B_Migrable = 0 cuando los conceptos en el detalle con estado pagado 1 y eliminado 0 tienen B_Migrable = 0
				 para la obligacion I_OblRowID	

	DECLARE @I_OblRowID	  int,
			@B_Resultado  bit,
			@T_Message    nvarchar(4000)
	EXEC USP_Obligaciones_Pagos_MigracionTP_U_Validar_56_DetalleObservadoPorOblID @I_OblRowID, @B_Resultado output, @T_Message output
	SELECT @B_Resultado as resultado, @T_Message as mensaje
*/
BEGIN
	DECLARE @I_Observados int = 0
	DECLARE @I_ObservadosObl int = 0
	DECLARE @D_FecProceso datetime = GETDATE() 
	DECLARE @I_ObservID int = 56
	DECLARE @I_TablaID int = 7
	DECLARE @I_DetTablaID int = 4

	BEGIN TRANSACTION
	BEGIN TRY
		
		SELECT Det.*
		  INTO #temp_obl_det_observada
		  FROM TR_Ec_Det Det 
			   INNER JOIN TI_ObservacionRegistroTabla Obs ON Det.I_RowID = Obs.I_FilaTablaID
															 AND Det.I_ProcedenciaID = Obs.I_ProcedenciaID
															 AND Obs.I_TablaID = @I_DetTablaID
		 WHERE Obs.B_Resuelto = 0
			   AND Det.I_OblRowID = @I_OblRowID


		UPDATE Det_Pagos 
		   SET B_Migrable = 0, 
			   D_FecMigrado = @D_FecProceso
		  FROM TR_Ec_Det_Pagos Det_Pagos
			   INNER JOIN #temp_obl_det_observada tmp ON Det_Pagos.I_OblRowID = tmp.I_OblRowID 

		MERGE TI_ObservacionRegistroTabla AS TRG
		USING (SELECT @I_ObservID AS I_ObservID, @I_TablaID AS I_TablaID, Det_Pagos.I_RowID AS I_FilaTablaID, 
				      @D_FecProceso AS D_FecRegistro, Det_Pagos.I_ProcedenciaID 
				 FROM TR_Ec_Det_Pagos Det_Pagos
				      INNER JOIN #temp_obl_det_observada tmp ON Det_Pagos.I_OblRowID = tmp.I_OblRowID 
			  ) AS SRC
		ON TRG.I_ObservID = SRC.I_ObservID AND TRG.I_TablaID = SRC.I_TablaID AND TRG.I_FilaTablaID = SRC.I_FilaTablaID
		WHEN MATCHED AND TRG.I_FilaTablaID = SRC.I_FilaTablaID THEN
			UPDATE SET D_FecRegistro = SRC.D_FecRegistro, 
					   B_Resuelto = 0
		WHEN NOT MATCHED BY TARGET THEN
			INSERT (I_ObservID, I_TablaID, I_FilaTablaID, D_FecRegistro, I_ProcedenciaID)
			VALUES (SRC.I_ObservID, SRC.I_TablaID, SRC.I_FilaTablaID, SRC.D_FecRegistro, SRC.I_ProcedenciaID);


		UPDATE OBS
		   SET D_FecResuelto = @D_FecProceso,
			   B_Resuelto = 1
		  FROM TI_ObservacionRegistroTabla OBS
			   INNER JOIN (SELECT EDP.* FROM TR_Ec_Det_Pagos EDP
								  LEFT JOIN #temp_obl_det_observada tmp ON EDP.I_OblRowID = tmp.I_OblRowID
							WHERE EDP.I_OblRowID = @I_OblRowID
								  AND tmp.I_RowID IS NULL 
						  ) DPG ON OBS.I_FilaTablaID = DPG.I_RowID
		 WHERE OBS.I_ObservID = @I_ObservID 
			   AND OBS.I_TablaID = @I_TablaID


		SET @I_Observados = (SELECT COUNT(*) 
							   FROM TI_ObservacionRegistroTabla OBS 
									INNER JOIN TR_Ec_Det_Pagos DET_PG ON OBS.I_FilaTablaID = DET_PG.I_RowID 
																	  	 AND DET_PG.I_ProcedenciaID = OBS.I_ProcedenciaID
							  WHERE OBS.I_ObservID = @I_ObservID 
							  		AND OBS.I_TablaID = @I_TablaID
									AND DET_PG.I_OblRowID = @I_OblRowID  
									AND OBS.B_Resuelto = 0
							)
		
		SELECT @I_Observados as cant_obs, @D_FecProceso as fec_proceso		 

		COMMIT TRANSACTION 

		SET @B_Resultado = 1
		SET @T_Message = '{ ' +
							 'Type: "summary", ' + 
							 'Title: "Observados", ' + 
							 'Value: ' + CAST(@I_Observados AS varchar) +
						 '}' 
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


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_Obligaciones_Pagos_MigracionTP_U_Validar_57_CabObligacionObservada')
	DROP PROCEDURE [dbo].[USP_Obligaciones_Pagos_MigracionTP_U_Validar_57_CabObligacionObservada]
GO

CREATE PROCEDURE [dbo].[USP_Obligaciones_Pagos_MigracionTP_U_Validar_57_CabObligacionObservada]
	@I_ProcedenciaID tinyint,
	@T_Anio			varchar(4) = NULL,
	@B_Resultado	bit output,
	@T_Message		nvarchar(4000) OUTPUT	
AS
/*
  	DESCRIPCION: Marcar TR_Ec_Det_Pagos con B_Migrable = 0 cuando la cabecera de la obligación asociada se encuentra observada para la procedencia y año.	

	DECLARE @I_ProcedenciaID	tinyint = 1, 
			@T_Anio		  varchar(4) = '2010',
			@B_Resultado  bit,
			@T_Message    nvarchar(4000)
	EXEC USP_Obligaciones_Pagos_MigracionTP_U_Validar_57_CabObligacionObservada @I_ProcedenciaID, @T_Anio, @B_Resultado output, @T_Message output
	SELECT @B_Resultado as resultado, @T_Message as mensaje
*/
BEGIN
	DECLARE @I_Observados int = 0
	DECLARE @I_ObservadosObl int = 0
	DECLARE @D_FecProceso datetime = GETDATE() 
	DECLARE @I_ObservID int = 57
	DECLARE @I_OblTablaID int = 5
	DECLARE @I_TablaID int = 7

	BEGIN TRANSACTION
	BEGIN TRY
		
		SELECT Obl.*
		  INTO #temp_obl_cab_observada
		  FROM TR_Ec_Obl Obl 
			   INNER JOIN TI_ObservacionRegistroTabla Obs ON Obl.I_RowID = Obs.I_FilaTablaID
															 AND Obl.I_ProcedenciaID = Obs.I_ProcedenciaID
															 AND Obs.I_TablaID = @I_OblTablaID
		 WHERE Obs.B_Resuelto = 0
			   AND Obl.Ano = @T_Anio 
			   AND Obl.I_ProcedenciaID = @I_ProcedenciaID


		UPDATE Det_Pagos 
		   SET B_Migrable = 0, 
			   D_FecMigrado = @D_FecProceso
		  FROM TR_Ec_Det_Pagos Det_Pagos
			   INNER JOIN #temp_obl_cab_observada tmp ON Det_Pagos.I_OblRowID = tmp.I_RowID 

		MERGE TI_ObservacionRegistroTabla AS TRG
		USING (SELECT @I_ObservID AS I_ObservID, @I_TablaID AS I_TablaID, Det_Pagos.I_RowID AS I_FilaTablaID, @D_FecProceso AS D_FecRegistro 
				 FROM TR_Ec_Det_Pagos Det_Pagos
				      INNER JOIN #temp_obl_cab_observada tmp ON Det_Pagos.I_OblRowID = tmp.I_RowID 
			  ) AS SRC
		ON TRG.I_ObservID = SRC.I_ObservID AND TRG.I_TablaID = SRC.I_TablaID AND TRG.I_FilaTablaID = SRC.I_FilaTablaID
		WHEN MATCHED AND TRG.I_FilaTablaID = SRC.I_FilaTablaID THEN
			UPDATE SET D_FecRegistro = SRC.D_FecRegistro, 
					   B_Resuelto = 0
		WHEN NOT MATCHED BY TARGET THEN
			INSERT (I_ObservID, I_TablaID, I_FilaTablaID, D_FecRegistro, I_ProcedenciaID)
			VALUES (SRC.I_ObservID, SRC.I_TablaID, SRC.I_FilaTablaID, SRC.D_FecRegistro, @I_ProcedenciaID);


		UPDATE OBS
		   SET D_FecResuelto = @D_FecProceso,
			   B_Resuelto = 1
		  FROM TI_ObservacionRegistroTabla OBS
			   INNER JOIN (SELECT EDP.* FROM TR_Ec_Det_Pagos EDP
								  LEFT JOIN #temp_obl_cab_observada tmp ON EDP.I_OblRowID = tmp.I_RowID
							WHERE EDP.I_ProcedenciaID = @I_ProcedenciaID
								  AND EDP.Ano = @T_Anio
								  AND tmp.I_RowID IS NULL 
						  ) DPG ON OBS.I_FilaTablaID = DPG.I_RowID
		 WHERE OBS.I_ObservID = @I_ObservID 
			   AND OBS.I_TablaID = @I_TablaID


		SET @I_Observados = (SELECT COUNT(*) 
							   FROM TI_ObservacionRegistroTabla OBS 
									INNER JOIN TR_Ec_Det_Pagos DET_PG ON OBS.I_FilaTablaID = DET_PG.I_RowID 
																	  	 AND DET_PG.I_ProcedenciaID = OBS.I_ProcedenciaID
							  WHERE OBS.I_ObservID = @I_ObservID 
							  		AND OBS.I_TablaID = @I_TablaID
									AND DET_PG.I_ProcedenciaID = @I_ProcedenciaID 
									AND OBS.B_Resuelto = 0
							)

		SELECT @I_Observados as cant_obs, @D_FecProceso as fec_proceso		 

		COMMIT TRANSACTION 

		SET @B_Resultado = 1
		SET @T_Message = '{ ' +
							 'Type: "summary", ' + 
							 'Title: "Observados", ' + 
							 'Value: ' + CAST(@I_ObservadosObl AS varchar) +
						 '}' 
	END TRY
	BEGIN CATCH
		IF(@@TRANCOUNT > 0)
		BEGIN
			ROLLBACK TRANSACTION
		END

		SET @B_Resultado = 0
		SET @T_Message = '[{ ' +
							 'Type: "error", ' + 
							 'Title: "Error", ' + 
							 'Value: "' + ERROR_MESSAGE() + ' (Linea: ' + CAST(ERROR_LINE() AS varchar(11)) + ')."'  +
						  '}]' 
	END CATCH
END
GO



IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_Obligaciones_Pagos_MigracionTP_U_Validar_57_CabObligacionObservadaPorOblID')
	DROP PROCEDURE [dbo].[USP_Obligaciones_Pagos_MigracionTP_U_Validar_57_CabObligacionObservadaPorOblID]
GO

CREATE PROCEDURE [dbo].[USP_Obligaciones_Pagos_MigracionTP_U_Validar_57_CabObligacionObservadaPorOblID]
	@I_OblRowID			int,
	@B_Resultado	bit output,
	@T_Message		nvarchar(4000) OUTPUT	
AS
/*
  	DESCRIPCION: Marcar TR_Ec_Det_Pagos con B_Migrable = 0 cuando la cabecera de la obligaci�n asociada se encuentra observada para la obligacion I_OblRowID	

	DECLARE @I_OblRowID	  int,
			@B_Resultado  bit,
			@T_Message    nvarchar(4000)
	EXEC USP_Obligaciones_Pagos_MigracionTP_U_Validar_57_CabObligacionObservadaPorOblID @I_OblRowID, @B_Resultado output, @T_Message output
	SELECT @B_Resultado as resultado, @T_Message as mensaje
*/
BEGIN
	DECLARE @I_Observados int = 0
	DECLARE @I_ObservadosObl int = 0
	DECLARE @D_FecProceso datetime = GETDATE() 
	DECLARE @I_ObservID int = 56
	DECLARE @I_TablaID int = 7
	DECLARE @I_OblTablaID int = 5

	BEGIN TRANSACTION
	BEGIN TRY
		
		SELECT Obl.*
		  INTO #temp_obl_cab_observada
		  FROM TR_Ec_Obl Obl 
			   INNER JOIN TI_ObservacionRegistroTabla Obs ON Obl.I_RowID = Obs.I_FilaTablaID
															 AND Obl.I_ProcedenciaID = Obs.I_ProcedenciaID
															 AND Obs.I_TablaID = @I_OblTablaID
		 WHERE Obs.B_Resuelto = 0
			   AND Obl.I_RowID = @I_OblRowID


		UPDATE Det_Pagos 
		   SET B_Migrable = 0, 
			   D_FecMigrado = @D_FecProceso
		  FROM TR_Ec_Det_Pagos Det_Pagos
			   INNER JOIN #temp_obl_cab_observada tmp ON Det_Pagos.I_OblRowID = tmp.I_RowID 

		MERGE TI_ObservacionRegistroTabla AS TRG
		USING (SELECT @I_ObservID AS I_ObservID, @I_TablaID AS I_TablaID, Det_Pagos.I_RowID AS I_FilaTablaID, 
				      @D_FecProceso AS D_FecRegistro, Det_Pagos.I_ProcedenciaID 
				 FROM TR_Ec_Det_Pagos Det_Pagos
				      INNER JOIN #temp_obl_cab_observada tmp ON Det_Pagos.I_OblRowID = tmp.I_RowID 
			  ) AS SRC
		ON TRG.I_ObservID = SRC.I_ObservID AND TRG.I_TablaID = SRC.I_TablaID AND TRG.I_FilaTablaID = SRC.I_FilaTablaID
		WHEN MATCHED AND TRG.I_FilaTablaID = SRC.I_FilaTablaID THEN
			UPDATE SET D_FecRegistro = SRC.D_FecRegistro, 
					   B_Resuelto = 0
		WHEN NOT MATCHED BY TARGET THEN
			INSERT (I_ObservID, I_TablaID, I_FilaTablaID, D_FecRegistro, I_ProcedenciaID)
			VALUES (SRC.I_ObservID, SRC.I_TablaID, SRC.I_FilaTablaID, SRC.D_FecRegistro, SRC.I_ProcedenciaID);


		UPDATE OBS
		   SET D_FecResuelto = @D_FecProceso,
			   B_Resuelto = 1
		  FROM TI_ObservacionRegistroTabla OBS
			   INNER JOIN (SELECT EDP.* FROM TR_Ec_Det_Pagos EDP
								  LEFT JOIN #temp_obl_cab_observada tmp ON EDP.I_OblRowID = tmp.I_RowID
							WHERE EDP.I_OblRowID = @I_OblRowID
								  AND tmp.I_RowID IS NULL 
						  ) DPG ON OBS.I_FilaTablaID = DPG.I_RowID
		 WHERE OBS.I_ObservID = @I_ObservID 
			   AND OBS.I_TablaID = @I_TablaID


		SET @I_Observados = (SELECT COUNT(*) 
							   FROM TI_ObservacionRegistroTabla OBS 
									INNER JOIN TR_Ec_Det_Pagos DET_PG ON OBS.I_FilaTablaID = DET_PG.I_RowID 
																	  	 AND DET_PG.I_ProcedenciaID = OBS.I_ProcedenciaID
							  WHERE OBS.I_ObservID = @I_ObservID 
							  		AND OBS.I_TablaID = @I_TablaID
									AND DET_PG.I_OblRowID = @I_OblRowID  
									AND OBS.B_Resuelto = 0
							)
		
		SELECT @I_Observados as cant_obs, @D_FecProceso as fec_proceso		 

		COMMIT TRANSACTION 

		SET @B_Resultado = 1
		SET @T_Message = '{ ' +
							 'Type: "summary", ' + 
							 'Title: "Observados", ' + 
							 'Value: ' + CAST(@I_Observados AS varchar) +
						 '}' 
	END TRY
	BEGIN CATCH
		IF(@@TRANCOUNT > 0)
		BEGIN
			ROLLBACK TRANSACTION
		END

		SET @B_Resultado = 0
		SET @T_Message = '[{ ' +
							 'Type: "error", ' + 
							 'Title: "Error", ' + 
							 'Value: "' + ERROR_MESSAGE() + ' (Linea: ' + CAST(ERROR_LINE() AS varchar(11)) + ')."'  +
						  '}]' 
	END CATCH
END
GO
