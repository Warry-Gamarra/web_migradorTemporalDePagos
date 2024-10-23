/*
==================================================================
	BD_OCEF_MigracionTP - 07_Procedures_PagoObligaciones
==================================================================
*/


USE BD_OCEF_MigracionTP
GO




/*	
	===============================================================================================
		relacionar registros de tablas ec_obl y ec_det segun procedencia (I_OblID)
	===============================================================================================
*/ 

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_Obligaciones_Pagos_MigracionTP_U_AsignarObligacionID')
	DROP PROCEDURE [dbo].[USP_Obligaciones_Pagos_MigracionTP_U_AsignarObligacionID]
GO

CREATE PROCEDURE USP_Obligaciones_Pagos_MigracionTP_U_AsignarObligacionID
(
	@I_ProcedenciaID tinyint,
	@T_Anio		  varchar(4),
	@B_Resultado  bit output,
	@T_Message	  nvarchar(4000) OUTPUT	
)
AS
/*
  declare	@B_Resultado  bit,
			@I_ProcedenciaID	tinyint = 3,
	    	@T_Anio		  varchar(4) = '2005',
			@T_Message	  nvarchar(4000)
  exec USP_Obligaciones_Pagos_MigracionTP_U_AsignarObligacionID @I_ProcedenciaID, @T_Anio, @B_Resultado output, @T_Message output
  select @B_Resultado as resultado, @T_Message as mensaj
*/
BEGIN 
	DECLARE @D_FecProceso datetime = GETDATE() 
	DECLARE @I_Actualizados int = 0

	BEGIN TRANSACTION
	BEGIN TRY
		--obtener ID de obligación que no se encuentren repetidos
		SELECT OBL2.*
		  INTO #temp_obl_pagados_sin_repetir_anio_procedencia 
		  FROM (SELECT Cuota_pago, Ano, P, Cod_alu, Cod_rc, Tipo_oblig, Fch_venc, Pagado, Monto, I_ProcedenciaID
		    	  FROM TR_Ec_Obl
				 WHERE Ano = @T_Anio
					   AND I_ProcedenciaID = @I_ProcedenciaID
					   AND Pagado = 1
				GROUP BY Cuota_pago, Ano, P, Cod_alu, Cod_rc, Tipo_oblig, Fch_venc, Pagado, Monto, I_ProcedenciaID
				HAVING COUNT(*) = 1) OBL1
			   INNER JOIN TR_Ec_Obl OBL2 ON OBL1.I_ProcedenciaID = OBL2.I_ProcedenciaID
											AND OBL1.Cuota_pago = OBL2.Cuota_pago
											AND OBL1.Ano = OBL2.Ano
											AND OBL1.P = OBL2.P
											AND OBL1.Cod_alu = OBL2.Cod_alu
											AND OBL1.Cod_rc = OBL2.Cod_rc
											AND OBL1.Tipo_oblig = OBL2.Tipo_oblig
											AND OBL1.Fch_venc = OBL2.Fch_venc
											AND OBL1.Pagado = OBL2.Pagado
											AND OBL1.Monto = OBL2.Monto


		--1. Se actualiza pagos con ID de obligación del mismo monto
		UPDATE det_pg
		   SET I_OblRowID = obl.I_RowID
		  FROM TR_Ec_Det_Pagos det_pg
			   INNER JOIN #temp_obl_pagados_sin_repetir_anio_procedencia obl 
											ON det_pg.I_ProcedenciaID = obl.I_ProcedenciaID
										   AND det_pg.Cuota_pago = obl.Cuota_pago
										   AND det_pg.Cod_alu = obl.Cod_alu
										   AND det_pg.Cod_rc = obl.Cod_rc
										   AND det_pg.P = obl.P
										   AND det_pg.Fch_venc = obl.Fch_venc
										   AND det_pg.Monto = obl.Monto
		 WHERE det_pg.Ano = @T_Anio
			   AND det_pg.I_ProcedenciaID = @I_ProcedenciaID

		SET @I_Actualizados = @@ROWCOUNT
		--2. Se actualiza pagos por mora con ID de obligación pagada con el mismo número de recibo

		UPDATE pg_mora
		   SET I_OblRowID = det_pg.I_OblRowID
		  FROM (SELECT * FROM TR_Ec_Det_Pagos WHERE Concepto <> 0) pg_mora
			   INNER JOIN (SELECT * FROM TR_Ec_Det_Pagos WHERE Concepto = 0) det_pg 
													ON pg_mora.Nro_recibo = det_pg.Nro_recibo
													AND pg_morA.Fch_pago = det_pg.Fch_pago
		 WHERE det_pg.Ano = @T_Anio
			   AND det_pg.I_ProcedenciaID = @I_ProcedenciaID

		SET @I_Actualizados = @I_Actualizados + @@ROWCOUNT

		COMMIT TRANSACTION
		SET @B_Resultado = 1					
		SET @T_Message =  '{' +
							 'Type: "summary", ' + 
							 'Title: "Actualizados", ' + 
							 'Value: ' + CAST(@I_Actualizados AS varchar) +  
						  '}'
	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION
		SET @B_Resultado = 0
		SET @T_Message = '[{' +
							 'Type: "error", ' + 
							 'Title: "Error", ' + 
							 'Value: "' + ERROR_MESSAGE() + ' (Linea: ' + CAST(ERROR_LINE() AS varchar(11)) + ')."'  +
						  '}]' 
	END CATCH
END
GO


/*	
	===============================================================================================
		Inicializar parámetros para validaciones de tablas ec_obl y ec_det segun procedencia	
	===============================================================================================
*/ 


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_Obligaciones_Pagos_MigracionTP_U_InicializarEstadoValidacion')
	DROP PROCEDURE [dbo].[USP_Obligaciones_Pagos_MigracionTP_U_InicializarEstadoValidacion]
GO

CREATE PROCEDURE USP_Obligaciones_Pagos_MigracionTP_U_InicializarEstadoValidacion	
	@I_ProcedenciaID tinyint,
	@T_Anio	      varchar(4),
	@B_Resultado  bit output,
	@T_Message	  nvarchar(4000) OUTPUT	
AS
/*
   	DESCRIPCION: Reinicia los estados de validacion y migracion de la tabla de pagos 	

	DECLARE @I_ProcedenciaID	tinyint = 1, 
			@T_Anio		  varchar(4) = '2010',
			@B_Resultado  bit,
			@T_Message    nvarchar(4000)
	EXEC USP_Obligaciones_Pagos_MigracionTP_U_InicializarEstadoValidacion @I_ProcedenciaID, @T_Anio, @B_Resultado output, @T_Message output
	SELECT @B_Resultado as resultado, @T_Message as mensaje
*/
BEGIN
	BEGIN TRANSACTION
	BEGIN TRY
		WITH cte_obl_anio (I_OblRowID, Cod_alu, Cod_rc, Cuota_pago, P, Fch_venc, Pagado, Monto)
		AS ( 
			SELECT I_RowID, Cod_alu, Cod_rc, Cuota_pago, P, Fch_venc, Pagado, Monto
			  FROM TR_Ec_Obl 
			 WHERE I_ProcedenciaID = @I_ProcedenciaID
				   AND Ano = @T_Anio
		)


		UPDATE	det
		   SET	B_Actualizado = IIF(B_Actualizado = 1, B_Actualizado, 0), 
				B_Migrable = 1, 
				D_FecMigrado = NULL, 
				B_Migrado = 0
		  FROM  TR_Ec_Det_Pagos det 
				INNER JOIN cte_obl_anio obl ON det.I_OblRowID = obl.I_OblRowID

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



/*	
	===============================================================================================
		Validaciones de tablas de pagos	
	===============================================================================================
*/ 


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
			INSERT (I_ObservID, I_TablaID, I_FilaTablaID, D_FecRegistro, I_ProcedenciaID, B_ObligProc)
			VALUES (SRC.I_ObservID, SRC.I_TablaID, SRC.I_FilaTablaID, SRC.D_FecRegistro, @I_ProcedenciaID, 1);


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
			UPDATE SET D_FecRegistro = SRC.D_FecRegistro,
					   B_Resuelto = 0
		WHEN NOT MATCHED BY TARGET THEN
			INSERT (I_ObservID, I_TablaID, I_FilaTablaID, D_FecRegistro, I_ProcedenciaID, B_ObligProc)
			VALUES (SRC.I_ObservID, SRC.I_TablaID, SRC.I_FilaTablaID, SRC.D_FecRegistro, @I_ProcedenciaID, 1);
		
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
			UPDATE SET D_FecRegistro = SRC.D_FecRegistro,
					   B_Resuelto = 0
		WHEN NOT MATCHED BY TARGET THEN
			INSERT (I_ObservID, I_TablaID, I_FilaTablaID, D_FecRegistro, I_ProcedenciaID, B_ObligProc)
			VALUES (SRC.I_ObservID, SRC.I_TablaID, SRC.I_FilaTablaID, SRC.D_FecRegistro, SRC.I_ProcedenciaID, 1);
		
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

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_Obligaciones_Pagos_MigracionTP_U_Validar_54_EstadoPagadoObligacionPorID')
	DROP PROCEDURE [dbo].[USP_Obligaciones_Pagos_MigracionTP_U_Validar_54_EstadoPagadoObligacionPorID]
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
  	DESCRIPCION: Marcar TR_Ec_Det_Pagos con B_Migrable = 0 cuando el pago de la obligacion no migrada existe en la base de datos de destino con otro banco para la procedencia y año.

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
		WHEN NOT MATCHED BY TARGET THEN
			INSERT (I_ObservID, I_TablaID, I_FilaTablaID, D_FecRegistro, I_ProcedenciaID, B_ObligProc)
			VALUES (SRC.I_ObservID, SRC.I_TablaID, SRC.I_FilaTablaID, SRC.D_FecRegistro, @I_ProcedenciaID, 1);

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
			INSERT (I_ObservID, I_TablaID, I_FilaTablaID, D_FecRegistro, I_ProcedenciaID, B_ObligProc)
			VALUES (SRC.I_ObservID, SRC.I_TablaID, SRC.I_FilaTablaID, SRC.D_FecRegistro, SRC.I_ProcedenciaID, 1);

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
  	DESCRIPCION: Marcar TR_Ec_Det_Pagos con B_Migrable = 0 cuando el pago tiene observaciones de conceptos en el detalle para la procedencia y año.

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
		  INTO #temp_pago_det_observada
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
			   INNER JOIN #temp_pago_det_observada tmp ON Det_Pagos.I_OblRowID = tmp.I_OblRowID 

		MERGE TI_ObservacionRegistroTabla AS TRG
		USING (SELECT @I_ObservID AS I_ObservID, @I_TablaID AS I_TablaID, Det_Pagos.I_RowID AS I_FilaTablaID, @D_FecProceso AS D_FecRegistro 
				 FROM TR_Ec_Det_Pagos Det_Pagos
				      INNER JOIN #temp_pago_det_observada tmp ON Det_Pagos.I_OblRowID = tmp.I_OblRowID 
			  ) AS SRC
		ON TRG.I_ObservID = SRC.I_ObservID AND TRG.I_TablaID = SRC.I_TablaID AND TRG.I_FilaTablaID = SRC.I_FilaTablaID
		WHEN MATCHED AND TRG.I_FilaTablaID = SRC.I_FilaTablaID THEN
			UPDATE SET D_FecRegistro = SRC.D_FecRegistro, 
					   B_Resuelto = 0
		WHEN NOT MATCHED BY TARGET THEN
			INSERT (I_ObservID, I_TablaID, I_FilaTablaID, D_FecRegistro, I_ProcedenciaID, B_ObligProc)
			VALUES (SRC.I_ObservID, SRC.I_TablaID, SRC.I_FilaTablaID, SRC.D_FecRegistro, @I_ProcedenciaID, 1);


		UPDATE OBS
		   SET D_FecResuelto = @D_FecProceso,
			   B_Resuelto = 1
		  FROM TI_ObservacionRegistroTabla OBS
			   INNER JOIN (SELECT EDP.* FROM TR_Ec_Det_Pagos EDP
								  LEFT JOIN #temp_pago_det_observada tmp ON EDP.I_OblRowID = tmp.I_OblRowID
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
  	DESCRIPCION: Marcar TR_Ec_Det_Pagos con B_Migrable = 0 cuando el pago tiene observaciones de conceptos en el detalle para la obligación I_OblRowID	

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
			INSERT (I_ObservID, I_TablaID, I_FilaTablaID, D_FecRegistro, I_ProcedenciaID, B_ObligProc)
			VALUES (SRC.I_ObservID, SRC.I_TablaID, SRC.I_FilaTablaID, SRC.D_FecRegistro, SRC.I_ProcedenciaID, 1);


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
		  INTO #temp_pago_cab_observada
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
			   INNER JOIN #temp_pago_cab_observada tmp ON Det_Pagos.I_OblRowID = tmp.I_RowID 

		MERGE TI_ObservacionRegistroTabla AS TRG
		USING (SELECT @I_ObservID AS I_ObservID, @I_TablaID AS I_TablaID, Det_Pagos.I_RowID AS I_FilaTablaID, @D_FecProceso AS D_FecRegistro 
				 FROM TR_Ec_Det_Pagos Det_Pagos
				      INNER JOIN #temp_pago_cab_observada tmp ON Det_Pagos.I_OblRowID = tmp.I_RowID 
			  ) AS SRC
		ON TRG.I_ObservID = SRC.I_ObservID AND TRG.I_TablaID = SRC.I_TablaID AND TRG.I_FilaTablaID = SRC.I_FilaTablaID
		WHEN MATCHED AND TRG.I_FilaTablaID = SRC.I_FilaTablaID THEN
			UPDATE SET D_FecRegistro = SRC.D_FecRegistro, 
					   B_Resuelto = 0
		WHEN NOT MATCHED BY TARGET THEN
			INSERT (I_ObservID, I_TablaID, I_FilaTablaID, D_FecRegistro, I_ProcedenciaID, B_ObligProc)
			VALUES (SRC.I_ObservID, SRC.I_TablaID, SRC.I_FilaTablaID, SRC.D_FecRegistro, @I_ProcedenciaID, 1);


		UPDATE OBS
		   SET D_FecResuelto = @D_FecProceso,
			   B_Resuelto = 1
		  FROM TI_ObservacionRegistroTabla OBS
			   INNER JOIN (SELECT EDP.* FROM TR_Ec_Det_Pagos EDP
								  LEFT JOIN #temp_pago_cab_observada tmp ON EDP.I_OblRowID = tmp.I_RowID
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
			INSERT (I_ObservID, I_TablaID, I_FilaTablaID, D_FecRegistro, I_ProcedenciaID, B_ObligProc)
			VALUES (SRC.I_ObservID, SRC.I_TablaID, SRC.I_FilaTablaID, SRC.D_FecRegistro, SRC.I_ProcedenciaID, 1);


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


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_Obligaciones_Pagos_MigracionTP_CtasPorCobrar_IU_MigrarDataPorID2')
	DROP PROCEDURE [dbo].[USP_Obligaciones_Pagos_MigracionTP_CtasPorCobrar_IU_MigrarDataPorID2]
GO


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_Obligaciones_Pagos_MigracionTP_CtasPorCobrar_IU_MigrarDataPorID')
	DROP PROCEDURE [dbo].[USP_Obligaciones_Pagos_MigracionTP_CtasPorCobrar_IU_MigrarDataPorID]
GO

CREATE PROCEDURE [dbo].[USP_Obligaciones_Pagos_MigracionTP_CtasPorCobrar_IU_MigrarDataPorID2]	
	@I_OblRowID		int,
	@I_UsuarioID	int,
	@I_PagoBancoID	int output,
	@B_Resultado	bit output,
	@T_Message		nvarchar(4000) OUTPUT	
AS
/*
	DECLARE @I_OblRowID		int = 117895,
			@I_UsuarioID	int = 15,
			@I_PagoBancoID	int,
			@B_Resultado	bit,
			@T_Message		nvarchar(4000)
	EXEC USP_Obligaciones_Pagos_MigracionTP_CtasPorCobrar_IU_MigrarDataPorID @I_OblRowID, @I_UsuarioID, @I_PagoBancoID output, @B_Resultado output, @T_Message output
	select @I_PagoBancoID as I_PagoBancoID, @B_Resultado as resultado, @T_Message as mensaje
*/
BEGIN
	DECLARE @D_FecProceso datetime = GETDATE(); 
	DECLARE @I_TablaID_Obl int = 5;
	DECLARE @I_TablaID_Det int = 4;
	DECLARE @I_TablaID_Det_Pago int = 7;
	DECLARE @I_CtasMora_RowID  int;
	DECLARE @T_Moneda varchar(3) = 'PEN';
	DECLARE @mora decimal(10,2);
	
	DECLARE @I_Pagos_Actualizados int = 0;
	DECLARE @I_Pagos_Insertados int = 0;

	DECLARE @I_Det_Actualizados int = 0;
	DECLARE @I_Det_Insertados int = 0;

	BEGIN TRANSACTION;
	BEGIN TRY 
		SELECT I_RowID, I_OblRowID, Cod_alu, Cod_rc, Cuota_pago, Ano, P, Tipo_oblig, Concepto, Fch_venc, Nro_recibo, 
			   Fch_pago, Id_lug_pag, Cantidad, Monto, Documento, Pagado, Concepto_f, Fch_elimin, Nro_ec, Fch_ec, Eliminado, 
			   Pag_demas, Cod_cajero, Tipo_pago, No_banco, Cod_dep, det.I_ProcedenciaID, B_Obligacion, det.B_Migrable, 
			   det.I_CtasDetTableRowID, det.I_CtasPagoProcTableRowID  
		  INTO #temp_det_obl
		  FROM TR_Ec_Det det
		 WHERE I_OblRowID = @I_OblRowID
			   AND det.B_Migrable = 1;

		SELECT det.I_RowID, I_OblRowID, Cod_alu, Cod_rc, Cuota_pago, Ano, P, Tipo_oblig, Concepto, Fch_venc, Nro_recibo, 
			   Fch_pago, Id_lug_pag, Cantidad, Monto, Documento, Pagado, Concepto_f, Fch_elimin, Nro_ec, Fch_ec, Eliminado, 
			   Pag_demas, Cod_cajero, Tipo_pago, No_banco, Cod_dep, det.I_ProcedenciaID, B_Obligacion, det.B_Migrable, 
			   (a.T_ApePaterno + ' ' + a.T_ApeMaterno + ', ' + a.T_Nombre) AS T_NomDepositante, cdp.I_CtaDepositoID,
			   det.I_CtasPagoBncTableRowID
		  INTO #temp_det_pago
		  FROM TR_Ec_Det_Pagos det
			   INNER JOIN  TR_Alumnos a ON det.Cod_alu = a.C_CodAlu AND det.Cod_rc = a.C_RcCod
			   INNER JOIN  BD_OCEF_CtasPorCobrar.dbo.TI_CtaDepo_Proceso cdp ON det.cuota_pago = cdp.I_ProcesoID
		 WHERE I_OblRowID = @I_OblRowID
			   AND Concepto = 0
			   AND det.B_Migrable = 1
			   AND cdp.B_Eliminado = 0;
	
		SELECT I_RowID, I_OblRowID, Monto 
		  INTO #temp_det_pago_mora
		  FROM TR_Ec_Det_Pagos
		 WHERE I_OblRowID = @I_OblRowID
			   AND Concepto <> 0
			   AND B_Migrable = 1
			   AND Eliminado = 0;

		SET @mora = (SELECT SUM(monto) FROM #temp_det_pago_mora WHERE I_OblRowID = @I_OblRowID);
		SET @I_CtasMora_RowID = (SELECT TOP 1 I_RowID FROM #temp_det_pago_mora WHERE I_OblRowID = @I_OblRowID);

		/*
			insert new pago banco in ctas x cobrar
		*/
		INSERT INTO BD_OCEF_CtasPorCobrar.dbo.TR_PagoBanco (I_EntidadFinanID, C_CodOperacion, C_CodDepositante, T_NomDepositante, C_Referencia, 
													D_FecPago, I_Cantidad, C_Moneda, I_MontoPago, T_LugarPago, B_Anulado, I_UsuarioCre, 
													D_FecCre, T_Observacion, T_InformacionAdicional, I_CondicionPagoID, I_TipoPagoID, 
													I_CtaDepositoID, I_InteresMora, B_Migrado, T_MotivoCoreccion, C_CodigoInterno, 
													I_MigracionTablaID, I_MigracionRowID, I_MigracionMoraRowID)
											SELECT  IIF(Cod_cajero = 'BCP', 2, 1) AS I_EntidadFinanID, Nro_recibo, Cod_alu, T_NomDepositante,  
													Nro_recibo, Fch_pago, Cantidad, @T_Moneda, Monto, Id_lug_pag, Eliminado, @I_UsuarioID, 
													@D_FecProceso, NULL as observacion, NULL as adicional, 131 as condpago, 133 as tipoPago, 
													I_CtaDepositoID, ISNULL(@mora, 0) as mora, 1 AS migrado, NULL as motivo, Nro_recibo, 
													@I_TablaID_Det_Pago, I_RowID, @I_CtasMora_RowID
												FROM	#temp_det_pago
												WHERE I_CtasPagoBncTableRowID IS NULL;

		SET @I_Pagos_Insertados = @@ROWCOUNT;

		/*
			uptdat if exists pago banco in ctas x cobrar
		*/
		UPDATE cta_pago_banco
		   SET T_NomDepositante = SRC_pago.T_NomDepositante,
			   C_Referencia = SRC_pago.Nro_recibo,
			   D_FecPago = SRC_pago.Fch_pago,
			   C_Moneda = @T_Moneda,
			   I_MontoPago = SRC_pago.Monto,
			   T_LugarPago = SRC_pago.Id_lug_pag,
			   B_Migrado = 1,
			   D_FecMod = @D_FecProceso
		  FROM BD_OCEF_CtasPorCobrar.dbo.TR_PagoBanco cta_pago_banco
			   INNER JOIN #temp_det_pago SRC_pago ON cta_pago_banco.I_PagoBancoID = SRC_pago.I_CtasPagoBncTableRowID
													 AND cta_pago_banco.I_MigracionTablaID = SRC_pago.I_RowID
		 WHERE I_CtasPagoBncTableRowID IS NOT NULL;
		 
		 SET @I_Pagos_Actualizados = @@ROWCOUNT;


		/*	UPDATE REGISTROS PAGO	*/
		UPDATE det_pagos
		   SET I_CtasPagoBncTableRowID = cta_pago_banco.I_PagoBancoID,
			   B_Migrado = 1,
			   D_FecMigrado = @D_FecProceso
		  FROM TR_Ec_Det_Pagos det_pagos
			   INNER JOIN BD_OCEF_CtasPorCobrar.dbo.TR_PagoBanco cta_pago_banco ON det_pagos.I_RowID = cta_pago_banco.I_MigracionRowID
		 WHERE I_OblRowID = @I_OblRowID;

		UPDATE temp_det_pagos
		   SET I_CtasPagoBncTableRowID = det_pagos.I_CtasPagoBncTableRowID
		  FROM #temp_det_pago temp_det_pagos
			   INNER JOIN TR_Ec_Det_Pagos det_pagos ON det_pagos.I_RowID = temp_det_pagos.I_RowID;

		/*	UPDATE REGISTROS MORA	*/
		UPDATE det_pagos 
		   SET I_CtasPagoBncTableRowID = cta_pago_banco.I_PagoBancoID,
			   B_Migrado = 1,
			   D_FecMigrado = @D_FecProceso
		  FROM TR_Ec_Det_Pagos det_pagos
			   INNER JOIN BD_OCEF_CtasPorCobrar.dbo.TR_PagoBanco cta_pago_banco ON det_pagos.I_RowID = cta_pago_banco.I_MigracionMoraRowID
		 WHERE I_OblRowID = @I_OblRowID
			   AND Concepto <> 0
			   AND B_Migrable = 1;

		/*
			upsert pago procesado in ctas x cobrar
		*/

		INSERT INTO BD_OCEF_CtasPorCobrar.dbo.TRI_PagoProcesadoUnfv(I_PagoBancoID, I_CtaDepositoID, I_TasaUnfvID, I_MontoPagado, I_SaldoAPagar, 
																	I_PagoDemas, B_PagoDemas, N_NroSIAF, B_Anulado,  D_FecCre, I_UsuarioCre, D_FecMod, 
																	I_UsuarioMod, I_ObligacionAluDetID, B_Migrado, I_MigracionTablaID, I_MigracionRowID)
															SELECT  temp_det_pagos.I_CtasPagoBncTableRowID, temp_det_pagos.I_CtaDepositoID, NULL, tmp_det.Monto, 0,
																	0, tmp_det.Pag_demas, NULL, tmp_det.Eliminado, @D_FecProceso, @I_UsuarioID, NULL, 
																	NULL, tmp_det.I_CtasDetTableRowID, 1, @I_TablaID_Det, tmp_det.I_RowID
															  FROM  #temp_det_obl tmp_det 
																	INNER JOIN #temp_det_pago temp_det_pagos ON tmp_det.I_OblRowID = temp_det_pagos.I_OblRowID
																												AND tmp_det.Pagado = temp_det_pagos.Pagado
																												AND tmp_det.Eliminado = temp_det_pagos.Eliminado
															 WHERE  temp_det_pagos.I_CtasPagoBncTableRowID IS NOT NULL
																	AND tmp_det.I_CtasPagoProcTableRowID IS NULL;

		SET @I_Det_Insertados = @@ROWCOUNT;

		UPDATE pago_proc
		   SET I_CtaDepositoID = temp_det_pagos.I_CtaDepositoID,
			   B_Anulado = tmp_det.Eliminado,
			   D_FecMod = @D_FecProceso,
			   I_MontoPagado = tmp_det.Monto,						   
			   B_Migrado = 1,
			   I_MigracionTablaID = @I_TablaID_Det
		  FROM BD_OCEF_CtasPorCobrar.dbo.TRI_PagoProcesadoUnfv pago_proc
			   INNER JOIN #temp_det_obl tmp_det ON pago_proc.I_MigracionRowID = tmp_det.I_RowID
			   INNER JOIN #temp_det_pago temp_det_pagos ON tmp_det.I_OblRowID = temp_det_pagos.I_OblRowID
		 WHERE tmp_det.I_CtasPagoProcTableRowID IS NOT NULL;

		 SET @I_Det_Actualizados = @@ROWCOUNT;

		/*		
			Actualizar tmp_det con el id de pago procesado creado	
		*/
		UPDATE tmp_det
		   SET I_CtasPagoProcTableRowID = pago_proc.I_PagoProcesID
		  FROM #temp_det_obl tmp_det
			   INNER JOIN BD_OCEF_CtasPorCobrar.dbo.TRI_PagoProcesadoUnfv pago_proc ON tmp_det.I_RowID = pago_proc.I_MigracionRowID;
			
		/*		
			Actualizar pagado de TR_Ec_Det con los registros que tienen id de pago proc	
		*/
		UPDATE ec_det
		   SET I_CtasPagoProcTableRowID = tmp_det.I_CtasPagoProcTableRowID,
			   Pagado = tmp_det.Pagado
		  FROM TR_Ec_Det ec_det
			   INNER JOIN #temp_det_obl tmp_det ON tmp_det.I_RowID = ec_det.I_RowID;

		/*		
			Actualizar pagado de CtasPorCobrar TR_ObligacionAluDet con los registros que tienen id de pago proc	
		*/
		UPDATE alu_det
		   SET B_Pagado = 1
		  FROM BD_OCEF_CtasPorCobrar.dbo.TR_ObligacionAluDet alu_det
			   INNER JOIN #temp_det_obl tmp_det ON alu_det.I_MigracionRowID = tmp_det.I_RowID
												   AND alu_det.I_ObligacionAluDetID = tmp_det.I_CtasDetTableRowID
		WHERE tmp_det.I_CtasPagoProcTableRowID IS NOT NULL;

		COMMIT TRANSACTION;
					
		SET @I_PagoBancoID = (SELECT TOP 1 ISNULL(I_CtasPagoBncTableRowID, 0) FROM #temp_det_pago WHERE I_OblRowID = @I_OblRowID AND Eliminado = 0)
		SET @B_Resultado = 1
		SET @T_Message = '[{ ' +
							 'Type: "summary", ' + 
							 'Title: "Pagos Banco Insertados (OBL_ID: ' + CAST(@I_OblRowID AS varchar) + ')", ' + 
							 'Value: ' + CAST(@I_Pagos_Insertados AS varchar) +
						  '}, ' + 
						  '{ ' +
							 'Type: "summary", ' + 
							 'Title: "Pagos Procesados Insertados (OBL_ID: ' + CAST(@I_OblRowID AS varchar) + ')", ' + 
							 'Value: ' + CAST(@I_Det_Insertados AS varchar) +
						  '}, ' + 
						  '{ ' +
							 'Type: "summary", ' + 
							 'Title: "Pagos Banco Actualizados (OBL_ID: ' + CAST(@I_OblRowID AS varchar) + ')", ' + 
							 'Value: ' + CAST(@I_Pagos_Actualizados AS varchar) +
						  '}, ' + 
						  '{ ' +
							 'Type: "summary", ' + 
							 'Title: "Pagos Procesados Actualizados (OBL_ID: ' + CAST(@I_OblRowID AS varchar) + ')", ' + 
							 'Value: ' + CAST(@I_Det_Actualizados AS varchar) +
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