USE BD_OCEF_MigracionTP
GO

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_MigracionTP_U_RemoverObservacionObligacion')
	DROP PROCEDURE [dbo].[USP_MigracionTP_U_RemoverObservacionObligacion]
GO

CREATE PROCEDURE [dbo].[USP_MigracionTP_U_RemoverObservacionObligacion]	
	@I_RowID	  int,
	@I_TablaID	  int,
	@I_ObservID	  int,
	@D_FecProceso datetime
AS
BEGIN
	UPDATE	TR_Ec_Obl
	   SET  B_Migrable = 1,
			B_Migrado = 0,
			D_FecEvalua = @D_FecProceso
	 WHERE  I_RowID = I_RowID
			AND B_Migrado = 0

	DELETE FROM TI_ObservacionRegistroTabla 
		WHERE I_TablaID = @I_TablaID 
				AND I_FilaTablaID = @I_RowID 
				AND I_ObservID = @I_ObservID

END
GO


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_MigracionTP_U_RegistrarObservacionObligacion')
	DROP PROCEDURE [dbo].[USP_MigracionTP_U_RegistrarObservacionObligacion]
GO

CREATE PROCEDURE [dbo].[USP_MigracionTP_U_RegistrarObservacionObligacion]	
	@I_RowID	   int,
	@I_TablaID	   int,
	@I_ObservID	   int,
	@D_FecProceso  datetime
AS
BEGIN

	UPDATE	TR_Ec_Obl
	   SET  B_Migrable = 0,
			B_Migrado = 0,
			D_FecEvalua = @D_FecProceso
	 WHERE  I_RowID = I_RowID

	IF EXISTS (SELECT * FROM TI_ObservacionRegistroTabla WHERE I_TablaID = @I_TablaID AND I_FilaTablaID = @I_RowID AND I_ObservID = @I_ObservID)
		UPDATE TI_ObservacionRegistroTabla 
			SET D_FecRegistro = @D_FecProceso
			WHERE I_TablaID = @I_TablaID 
				AND I_FilaTablaID = @I_RowID 
				AND I_ObservID = @I_ObservID
	ELSE
		INSERT INTO TI_ObservacionRegistroTabla (I_ObservID, I_TablaID, I_FilaTablaID, I_ProcedenciaID, D_FecRegistro, B_Resuelto, D_FecResuelto)
						SELECT @I_ObservID, @I_TablaID, I_RowID, I_ProcedenciaID, @D_FecProceso, 0, NULL
						FROM TR_Ec_Obl WHERE I_RowID = @I_RowID 
END
GO


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_U_InicializarEstadoValidacionObligacionPago')
	DROP PROCEDURE [dbo].[USP_U_InicializarEstadoValidacionObligacionPago]
GO

CREATE PROCEDURE USP_U_InicializarEstadoValidacionObligacionPago	
	@I_ProcedenciaID tinyint,
	@I_Anio	      smallint,
	@B_Resultado  bit output,
	@T_Message	  nvarchar(4000) OUTPUT	
AS
--declare	@B_Resultado  bit,
--			@I_ProcedenciaID	tinyint = 3,
--			@I_Anio  	  smallint,
--			@T_Message	  nvarchar(4000)
--exec USP_U_InicializarEstadoValidacionObligacionPago @I_ProcedenciaID, @I_Anio, @B_Resultado output, @T_Message output
--select @B_Resultado as resultado, @T_Message as mensaje
BEGIN
	BEGIN TRANSACTION
	BEGIN TRY 
		UPDATE	TR_Ec_Obl 
		   SET	B_Actualizado = 0, 
				B_Migrable = 1, 
				D_FecMigrado = NULL, 
				B_Migrado = 0
		 WHERE I_ProcedenciaID = @I_ProcedenciaID
			   AND CAST(Ano as smallint) = @I_Anio
			   AND B_Correcto = 0

		SET @T_Message = CAST(@@ROWCOUNT AS varchar)
		SET @B_Resultado = 1

		COMMIT TRANSACTION;
	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION
		SET @B_Resultado = 0
		SET @T_Message = ERROR_MESSAGE() + ' (Linea: ' + CAST(ERROR_LINE() AS varchar(11)) + ').' 
	END CATCH
END
GO


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_U_InicializarEstadoValidacionObligacionPagoPorOblID')
	DROP PROCEDURE [dbo].[USP_U_InicializarEstadoValidacionObligacionPagoPorOblID]
GO

CREATE PROCEDURE USP_U_InicializarEstadoValidacionObligacionPagoPorOblID	
	@I_RowID      int,
	@B_Resultado  bit output,
	@T_Message	  nvarchar(4000) OUTPUT	
AS
--declare	@B_Resultado  bit,
--			@I_ProcedenciaID	tinyint = 3,
--			@I_RowID  	  smallint,
--			@T_Message	  nvarchar(4000)
--exec USP_U_InicializarEstadoValidacionObligacionPago @I_RowID, @B_Resultado output, @T_Message output
--select @B_Resultado as resultado, @T_Message as mensaje
BEGIN
	BEGIN TRANSACTION
	BEGIN TRY 
		UPDATE	TR_Ec_Obl 
		   SET	B_Actualizado = 0, 
				B_Migrable = 1, 
				D_FecMigrado = NULL, 
				B_Migrado = 0
		 WHERE I_RowID = @I_RowID
			   AND B_Correcto = 0

		SET @T_Message = CAST(@@ROWCOUNT AS varchar)
		SET @B_Resultado = 1

		COMMIT TRANSACTION;
	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION
		SET @B_Resultado = 0
		SET @T_Message = ERROR_MESSAGE() + ' (Linea: ' + CAST(ERROR_LINE() AS varchar(11)) + ').' 
	END CATCH
END
GO


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_U_ValidarExisteAlumnoCabeceraObligacion')
	DROP PROCEDURE [dbo].[USP_U_ValidarExisteAlumnoCabeceraObligacion]
GO

CREATE PROCEDURE [dbo].[USP_U_ValidarExisteAlumnoCabeceraObligacion]	
	@I_ProcedenciaID tinyint,
	@I_Anio  	  smallint,
	@B_Resultado  bit output,
	@T_Message	  nvarchar(4000) OUTPUT	
AS
--declare @I_ProcedenciaID	tinyint = 3,
--		@I_Anio 	  smallint ,
--		@B_Resultado  bit,
--		@T_Message	  nvarchar(4000)
--exec USP_U_ValidarExisteAlumnoCabeceraObligacion @I_ProcedenciaID, @I_Anio, @B_Resultado output, @T_Message output
--select @B_Resultado as resultado, @T_Message as mensaje
BEGIN
	DECLARE @I_Observados int = 0
	DECLARE @D_FecProceso datetime = GETDATE() 
	DECLARE @I_ObservID int = 24
	DECLARE @I_TablaID int = 5

	BEGIN TRANSACTION
	BEGIN TRY 

		UPDATE	TR_Ec_Obl
		SET		B_Migrable = 0,
				D_FecEvalua = @D_FecProceso
		WHERE	NOT EXISTS (SELECT * FROM TR_Alumnos b WHERE TR_Ec_Obl.COD_ALU = C_CodAlu and TR_Ec_Obl.COD_RC = C_RcCod)
				AND Ano = CAST(@I_Anio AS varchar(4))
			    AND TR_Ec_Obl.I_ProcedenciaID = @I_ProcedenciaID
				AND TR_Ec_Obl.B_Correcto = 0
					
		MERGE TI_ObservacionRegistroTabla AS TRG
		USING (SELECT @I_ObservID AS I_ObservID, @I_TablaID AS I_TablaID, ec_obl.I_RowID AS I_FilaTablaID, @D_FecProceso AS D_FecRegistro 
			     FROM TR_Ec_Obl ec_obl
			    WHERE NOT EXISTS (SELECT * FROM TR_Alumnos b WHERE ec_obl.COD_ALU = C_CodAlu and ec_obl.COD_RC = C_RcCod)
					  AND ec_obl.Ano = CAST(@I_Anio AS varchar(4))
					  AND ec_obl.I_ProcedenciaID = @I_ProcedenciaID
					  AND ec_obl.B_Correcto = 0) AS SRC
		ON TRG.I_ObservID = SRC.I_ObservID AND TRG.I_TablaID = SRC.I_TablaID AND TRG.I_FilaTablaID = SRC.I_FilaTablaID
		WHEN MATCHED THEN
			 UPDATE SET D_FecRegistro = SRC.D_FecRegistro
		WHEN NOT MATCHED BY TARGET THEN
			 INSERT (I_ObservID, I_TablaID, I_FilaTablaID, D_FecRegistro, I_ProcedenciaID)
			 VALUES (SRC.I_ObservID, SRC.I_TablaID, SRC.I_FilaTablaID, SRC.D_FecRegistro, @I_ProcedenciaID)
		WHEN NOT MATCHED BY SOURCE AND TRG.I_ObservID = @I_ObservID AND TRG.I_ProcedenciaID = @I_ProcedenciaID 
								   AND TRG.I_TablaID = @I_TablaID THEN
			 DELETE;

		SET @I_Observados = (SELECT COUNT(*) FROM TI_ObservacionRegistroTabla OBS INNER JOIN 
												  TR_Ec_Obl OBL ON OBS.I_FilaTablaID = OBL.I_RowID 
																   AND OBL.I_ProcedenciaID = OBS.I_ProcedenciaID
																   AND OBS.I_TablaID = @I_TablaID 
							  WHERE OBS.I_ObservID = @I_ObservID AND
									OBL.Ano = CAST(@I_Anio AS varchar(4)) AND 
									OBS.I_ProcedenciaID = @I_ProcedenciaID)

		SELECT @I_Observados as cant_obs, @D_FecProceso as fec_proceso

		COMMIT TRANSACTION				

		SET @B_Resultado = 1
		SET @T_Message = CAST(@I_Observados AS varchar)
	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION
		SET @B_Resultado = 0
		SET @T_Message = ERROR_MESSAGE() + ' LINE: ' + CAST(ERROR_LINE() AS varchar(10)) 
	END CATCH

END
GO


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_U_ValidarAnioEnCabeceraObligacion')
	DROP PROCEDURE [dbo].[USP_U_ValidarAnioEnCabeceraObligacion]
GO

CREATE PROCEDURE [dbo].[USP_U_ValidarAnioEnCabeceraObligacion]	
	@I_ProcedenciaID tinyint,
	@B_Resultado  bit output,
	@T_Message	  nvarchar(4000) OUTPUT	
AS
--declare @I_ProcedenciaID	tinyint = 3, 
--		@B_Resultado  bit,
--		@T_Message	  nvarchar(4000)
--exec USP_U_ValidarAnioEnCabeceraObligacion @I_ProcedenciaID, @B_Resultado output, @T_Message output
--select @B_Resultado as resultado, @T_Message as mensaje
BEGIN
	DECLARE @I_Observados int = 0
	DECLARE @D_FecProceso datetime = GETDATE() 
	DECLARE @I_ObservID int = 26
	DECLARE @I_TablaID int = 5

	BEGIN TRANSACTION
	BEGIN TRY 
		UPDATE	TR_Ec_Obl
		   SET	B_Migrable = 0,
				D_FecEvalua = @D_FecProceso
		 WHERE	ISNUMERIC(Ano) = 0
				AND I_ProcedenciaID = @I_ProcedenciaID
				
		MERGE TI_ObservacionRegistroTabla AS TRG
		USING (SELECT @I_ObservID AS I_ObservID, @I_TablaID AS I_TablaID, I_RowID AS I_FilaTablaID, @D_FecProceso AS D_FecRegistro 
				 FROM TR_Ec_Obl 
			    WHERE ISNUMERIC(Ano) = 0 
					  AND I_ProcedenciaID = @I_ProcedenciaID
			  ) AS SRC
		ON TRG.I_ObservID = SRC.I_ObservID AND TRG.I_TablaID = SRC.I_TablaID AND TRG.I_FilaTablaID = SRC.I_FilaTablaID
		WHEN MATCHED THEN
			UPDATE SET D_FecRegistro = SRC.D_FecRegistro
		WHEN NOT MATCHED BY TARGET THEN
			INSERT (I_ObservID, I_TablaID, I_FilaTablaID, D_FecRegistro, I_ProcedenciaID)
			VALUES (SRC.I_ObservID, SRC.I_TablaID, SRC.I_FilaTablaID, SRC.D_FecRegistro, @I_ProcedenciaID)
		WHEN NOT MATCHED BY SOURCE AND TRG.I_ObservID = @I_ObservID AND TRG.I_ProcedenciaID = @I_ProcedenciaID THEN
			DELETE;

		SET @I_Observados = (SELECT COUNT(*) FROM TI_ObservacionRegistroTabla OBS INNER JOIN 
												  TR_Ec_Obl OBL ON OBS.I_FilaTablaID = OBL.I_RowID 
																   AND OBL.I_ProcedenciaID = OBS.I_ProcedenciaID
																   AND OBS.I_TablaID = @I_TablaID 
							  WHERE OBS.I_ObservID = @I_ObservID AND
									OBS.I_ProcedenciaID = @I_ProcedenciaID)

		SELECT @I_Observados as cant_obs, @D_FecProceso as fec_proceso

		COMMIT TRANSACTION				
		SET @B_Resultado = 1
		SET @T_Message = CAST(@I_Observados AS varchar)
	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION
		SET @B_Resultado = 0
		SET @T_Message = ERROR_MESSAGE() + ' LINE: ' + CAST(ERROR_LINE() AS varchar(10)) 
	END CATCH
END
GO


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_U_ValidarPeriodoEnCabeceraObligacion')
	DROP PROCEDURE [dbo].[USP_U_ValidarPeriodoEnCabeceraObligacion]
GO

CREATE PROCEDURE [dbo].[USP_U_ValidarPeriodoEnCabeceraObligacion]	
	@I_ProcedenciaID tinyint,
	@I_Anio		  smallint,
	@B_Resultado  bit output,
	@T_Message	  nvarchar(4000) OUTPUT	
AS
--declare	@I_ProcedenciaID	tinyint = 3, 
--			@I_Anio		  smallint,
--			@B_Resultado  bit,
--			@T_Message	  nvarchar(4000)
--exec USP_U_ValidarPeriodoEnCabeceraObligacion @I_ProcedenciaID, @I_Anio, @B_Resultado output, @T_Message output
--select @B_Resultado as resultado, @T_Message as mensaje
BEGIN
	DECLARE @I_Observados int = 0
	DECLARE @I_TablaID int = 5

	BEGIN TRANSACTION
	BEGIN TRY 
		DECLARE @D_FecProceso datetime = GETDATE() 
		DECLARE @I_ObservID int = 27

		UPDATE	TR_Ec_Obl
		SET		B_Migrable = 0,
				D_FecEvalua = @D_FecProceso
		WHERE	I_Periodo IS NULL OR P = ''
				AND I_ProcedenciaID = @I_ProcedenciaID
			    AND Ano = CAST(@I_Anio AS varchar)
				AND B_Correcto = 0

		MERGE TI_ObservacionRegistroTabla AS TRG
		USING 	(SELECT	@I_ObservID AS I_ObservID, @I_TablaID AS I_TablaID, I_RowID AS I_FilaTablaID, @D_FecProceso AS D_FecRegistro, I_ProcedenciaID
				   FROM TR_Ec_Obl
				  WHERE	I_Periodo IS NULL
				  		AND I_ProcedenciaID = @I_ProcedenciaID
						AND Ano = CAST(@I_Anio as varchar(4))
						AND B_Correcto = 0
				) AS SRC
		ON TRG.I_ObservID = SRC.I_ObservID AND TRG.I_TablaID = SRC.I_TablaID AND TRG.I_FilaTablaID = SRC.I_FilaTablaID
		WHEN MATCHED AND SRC.I_ProcedenciaID = @I_ProcedenciaID THEN
			UPDATE SET D_FecRegistro = SRC.D_FecRegistro
		WHEN NOT MATCHED BY TARGET AND SRC.I_ProcedenciaID = @I_ProcedenciaID THEN
			INSERT (I_ObservID, I_TablaID, I_FilaTablaID, D_FecRegistro, I_ProcedenciaID)
			VALUES (SRC.I_ObservID, SRC.I_TablaID, SRC.I_FilaTablaID, SRC.D_FecRegistro, @I_ProcedenciaID)
		WHEN NOT MATCHED BY SOURCE AND TRG.I_ObservID = @I_ObservID AND TRG.I_ProcedenciaID = @I_ProcedenciaID 
								   AND TRG.I_TablaID = @I_TablaID THEN
			DELETE;

		SET @I_Observados = (SELECT COUNT(*) FROM TI_ObservacionRegistroTabla OBS INNER JOIN 
												  TR_Ec_Obl OBL ON OBS.I_FilaTablaID = OBL.I_RowID 
																   AND OBL.I_ProcedenciaID = OBS.I_ProcedenciaID
																   AND OBS.I_TablaID = @I_TablaID 
							  WHERE OBS.I_ObservID = @I_ObservID AND
									OBL.Ano = CAST(@I_Anio AS varchar(4)) AND 
									OBS.I_ProcedenciaID = @I_ProcedenciaID)

		SELECT @I_Observados as cant_obs, @D_FecProceso as fec_proceso

		COMMIT TRANSACTION
					
		SET @B_Resultado = 1
		SET @T_Message = CAST(@I_Observados AS varchar)
	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION
		SET @B_Resultado = 0
		SET @T_Message = ERROR_MESSAGE() + ' LINE: ' + CAST(ERROR_LINE() AS varchar(10)) 
	END CATCH
END
GO


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_U_ValidarFechaVencimientoCuotaObligacion')
	DROP PROCEDURE [dbo].[USP_U_ValidarFechaVencimientoCuotaObligacion]
GO

CREATE PROCEDURE [dbo].[USP_U_ValidarFechaVencimientoCuotaObligacion]	
	@I_ProcedenciaID tinyint,
	@I_Anio		  smallint,
	@B_Resultado  bit OUTPUT,
	@T_Message	  nvarchar(4000) OUTPUT	
AS
--declare	@I_ProcedenciaID  tinyint = 3, 
--			@I_Anio			  smallint,
--			@B_Resultado	  bit,
--			@T_Message		  nvarchar(4000)
--exec USP_U_ValidarFechaVencimientoCuotaObligacion @I_ProcedenciaID, @I_Anio, @B_Resultado output, @T_Message output
--select @B_Resultado as resultado, @T_Message as mensaje
BEGIN
	DECLARE @I_Observados int = 0
	DECLARE @D_FecProceso datetime = GETDATE() 
	DECLARE @I_ObservID int = 28
	DECLARE @I_TablaID int = 5

	BEGIN TRANSACTION
	BEGIN TRY
		UPDATE	TRG_1
		SET		B_Migrable = 0,
				D_FecEvalua = @D_FecProceso
		FROM	TR_Ec_Obl TRG_1
				INNER JOIN (SELECT ANO, P, COD_ALU, COD_RC, CUOTA_PAGO, FCH_VENC, TIPO_OBLIG, MONTO
							FROM  TR_Ec_Obl
							WHERE I_ProcedenciaID = @I_ProcedenciaID
								  AND Ano = CAST(@I_Anio AS varchar(4))
							GROUP BY ANO, P, COD_ALU, COD_RC, CUOTA_PAGO, FCH_VENC, TIPO_OBLIG, MONTO
							HAVING COUNT(*) > 1) SRC_1 
				ON TRG_1.ANO = SRC_1.ANO AND TRG_1.P = SRC_1.P AND TRG_1.COD_ALU = SRC_1.COD_ALU AND TRG_1.COD_RC = SRC_1.COD_RC 
					AND TRG_1.CUOTA_PAGO = SRC_1.CUOTA_PAGO AND TRG_1.FCH_VENC = SRC_1.FCH_VENC 
					AND TRG_1.TIPO_OBLIG = SRC_1.TIPO_OBLIG AND TRG_1.MONTO = SRC_1.MONTO
		WHERE	TRG_1.Ano = CAST(@I_Anio AS varchar(4))
				AND TRG_1.B_Correcto = 0

					
		MERGE TI_ObservacionRegistroTabla AS TRG
		USING (SELECT @I_ObservID AS I_ObservID, @I_TablaID AS I_TablaID, I_RowID AS I_FilaTablaID, @D_FecProceso AS D_FecRegistro 
				 FROM TR_Ec_Obl TRG_1
					  INNER JOIN (SELECT ANO, P, COD_ALU, COD_RC, CUOTA_PAGO, FCH_VENC, TIPO_OBLIG, MONTO
					  			    FROM TR_Ec_Obl
					  			   WHERE I_ProcedenciaID = @I_ProcedenciaID
					  			    	 AND Ano = CAST(@I_Anio AS varchar(4))
					  			GROUP BY ANO, P, COD_ALU, COD_RC, CUOTA_PAGO, FCH_VENC, TIPO_OBLIG, MONTO
					  			HAVING COUNT(*) > 1) SRC_1 
					  	ON TRG_1.ANO = SRC_1.ANO AND TRG_1.P = SRC_1.P AND TRG_1.COD_ALU = SRC_1.COD_ALU AND TRG_1.COD_RC = SRC_1.COD_RC 
					  		AND TRG_1.CUOTA_PAGO = SRC_1.CUOTA_PAGO AND TRG_1.FCH_VENC = SRC_1.FCH_VENC 
					  		   AND TRG_1.TIPO_OBLIG = SRC_1.TIPO_OBLIG AND TRG_1.MONTO = SRC_1.MONTO
				 WHERE	TRG_1.Ano = CAST(@I_Anio AS varchar(4))
						AND TRG_1.B_Correcto = 0
				 ) AS SRC
		ON TRG.I_ObservID = SRC.I_ObservID AND TRG.I_TablaID = SRC.I_TablaID AND TRG.I_FilaTablaID = SRC.I_FilaTablaID
		WHEN MATCHED THEN
			UPDATE SET D_FecRegistro = SRC.D_FecRegistro
		WHEN NOT MATCHED BY TARGET THEN
			INSERT (I_ObservID, I_TablaID, I_FilaTablaID, D_FecRegistro, I_ProcedenciaID)
			VALUES (SRC.I_ObservID, SRC.I_TablaID, SRC.I_FilaTablaID, SRC.D_FecRegistro, @I_ProcedenciaID)
		WHEN NOT MATCHED BY SOURCE AND TRG.I_ObservID = @I_ObservID AND TRG.I_ProcedenciaID = @I_ProcedenciaID 
								   AND TRG.I_TablaID = @I_TablaID THEN
			DELETE;

		SET @I_Observados = (SELECT COUNT(*) FROM TI_ObservacionRegistroTabla OBS INNER JOIN 
												  TR_Ec_Obl OBL ON OBS.I_FilaTablaID = OBL.I_RowID 
																	AND OBL.I_ProcedenciaID = OBS.I_ProcedenciaID
																	AND OBS.I_TablaID = @I_TablaID 
							  WHERE I_ObservID = @I_ObservID AND
									OBL.Ano = CAST(@I_Anio AS varchar(4)) AND 
									OBS.I_ProcedenciaID = @I_ProcedenciaID)

		SELECT @I_Observados as cant_obs, @D_FecProceso as fec_proceso

		COMMIT TRANSACTION				
		SET @B_Resultado = 1
		SET @T_Message = CAST(@I_Observados AS varchar)
	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION
		SET @B_Resultado = 0
		SET @T_Message = ERROR_MESSAGE() + ' LINE: ' + CAST(ERROR_LINE() AS varchar(10)) 
	END CATCH
END
GO


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_U_ValidarObligacionCuotaPagoMigrada')
	DROP PROCEDURE [dbo].[USP_U_ValidarObligacionCuotaPagoMigrada]
GO

CREATE PROCEDURE [dbo].[USP_U_ValidarObligacionCuotaPagoMigrada]	
	@I_ProcedenciaID tinyint,
	@I_Anio		  smallint,
	@B_Resultado  bit output,
	@T_Message	  nvarchar(4000) OUTPUT	
AS
--declare	@I_ProcedenciaID	tinyint = 3, 
--			@I_Anio		  smallint,
--			@B_Resultado  bit,
--			@T_Message    nvarchar(4000)
--exec USP_U_ValidarObligacionCuotaPagoMigrada @I_ProcedenciaID, @I_Anio, @B_Resultado output, @T_Message output
--select @B_Resultado as resultado, @T_Message as mensaje
BEGIN
	DECLARE @I_Observados int = 0
	DECLARE @D_FecProceso datetime = GETDATE() 
	DECLARE @I_ObservID int = 32
	DECLARE @I_TablaID int = 5

	BEGIN TRANSACTION
	BEGIN TRY

		UPDATE	TR_Ec_Obl
		SET		B_Migrable = 0,
				D_FecEvalua = @D_FecProceso
		WHERE	Cuota_pago NOT IN (SELECT Cuota_pago FROM TR_Cp_Des WHERE B_Migrado = 1 AND Eliminado = 0 AND I_ProcedenciaID = @I_ProcedenciaID)
				AND I_ProcedenciaID = @I_ProcedenciaID
				AND Ano = CAST(@I_Anio as varchar(4))
								  
		MERGE TI_ObservacionRegistroTabla AS TRG
		USING 	(SELECT	@I_ObservID AS I_ObservID, @I_TablaID AS I_TablaID, I_RowID AS I_FilaTablaID, @D_FecProceso AS D_FecRegistro 
				   FROM TR_Ec_Obl
				  WHERE	Cuota_pago NOT IN (SELECT Cuota_pago FROM TR_Cp_Des WHERE B_Migrado = 1 AND Eliminado = 0 AND I_ProcedenciaID = @I_ProcedenciaID)
						AND I_ProcedenciaID = @I_ProcedenciaID
						AND Ano = CAST(@I_Anio as varchar(4))
				 ) AS SRC
		ON TRG.I_ObservID = SRC.I_ObservID AND TRG.I_TablaID = SRC.I_TablaID AND TRG.I_FilaTablaID = SRC.I_FilaTablaID
		WHEN MATCHED THEN
			UPDATE SET D_FecRegistro = SRC.D_FecRegistro
		WHEN NOT MATCHED BY TARGET THEN
			INSERT (I_ObservID, I_TablaID, I_FilaTablaID, D_FecRegistro, I_ProcedenciaID)
			VALUES (SRC.I_ObservID, SRC.I_TablaID, SRC.I_FilaTablaID, SRC.D_FecRegistro, @I_ProcedenciaID)
		WHEN NOT MATCHED BY SOURCE AND TRG.I_ObservID = @I_ObservID AND TRG.I_ProcedenciaID = @I_ProcedenciaID THEN
			DELETE;

		SET @I_Observados = (SELECT COUNT(*) FROM TI_ObservacionRegistroTabla OBS INNER JOIN 
												  TR_Ec_Obl OBL ON OBS.I_FilaTablaID = OBL.I_RowID 
																	AND OBL.I_ProcedenciaID = OBS.I_ProcedenciaID
																	AND OBS.I_TablaID = @I_TablaID 
							  WHERE I_ObservID = @I_ObservID AND
									OBL.Ano = CAST(@I_Anio AS varchar(4)) AND 
									OBS.I_ProcedenciaID = @I_ProcedenciaID)

		SELECT @I_Observados as cant_obs, @D_FecProceso as fec_proceso

		COMMIT TRANSACTION				
		SET @B_Resultado = 1
		SET @T_Message = CAST(@I_Observados AS varchar)
	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION
		SET @B_Resultado = 0
		SET @T_Message = ERROR_MESSAGE() + ' LINE: ' + CAST(ERROR_LINE() AS varchar(10)) 
	END CATCH
END
GO


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_U_ValidarProcedenciaObligacionCuotaPago')
	DROP PROCEDURE [dbo].[USP_U_ValidarProcedenciaObligacionCuotaPago]
GO

CREATE PROCEDURE [dbo].[USP_U_ValidarProcedenciaObligacionCuotaPago]	
	@I_ProcedenciaID tinyint,
	@I_Anio		  smallint,
	@B_Resultado  bit output,
	@T_Message	  nvarchar(4000) OUTPUT	
AS
--declare	@I_ProcedenciaID	tinyint = 3, 
--			@I_Anio		  smallint,
--			@B_Resultado  bit,
--			@T_Message    nvarchar(4000)
--exec USP_U_ValidarProcedenciaObligacionCuotaPago @I_ProcedenciaID, @I_Anio, @B_Resultado output, @T_Message output
--select @B_Resultado as resultado, @T_Message as mensaje
BEGIN
	DECLARE @I_Observados int = 0
	DECLARE @D_FecProceso datetime = GETDATE() 
	DECLARE @I_ObservID int = 34
	DECLARE @I_TablaID int = 5

	BEGIN TRANSACTION
	BEGIN TRY

		UPDATE	TR_Ec_Obl
		SET		B_Migrable = 0,
				D_FecEvalua = @D_FecProceso
		WHERE	Cuota_pago NOT IN (SELECT Cuota_pago FROM TR_Cp_Des WHERE I_ProcedenciaID = @I_ProcedenciaID)
				AND I_ProcedenciaID = @I_ProcedenciaID
				AND Ano = CAST(@I_Anio as varchar(4))	

		MERGE TI_ObservacionRegistroTabla AS TRG
		USING (SELECT @I_ObservID AS I_ObservID, @I_TablaID AS I_TablaID, I_RowID AS I_FilaTablaID, @D_FecProceso AS D_FecRegistro 
			     FROM TR_Ec_Obl
			    WHERE Cuota_pago NOT IN (SELECT Cuota_pago FROM TR_Cp_Des WHERE I_ProcedenciaID = @I_ProcedenciaID)
			  		  AND I_ProcedenciaID = @I_ProcedenciaID
			  		  AND Ano = CAST(@I_Anio as varchar(4))
			  ) AS SRC
		ON TRG.I_ObservID = SRC.I_ObservID AND TRG.I_TablaID = SRC.I_TablaID AND TRG.I_FilaTablaID = SRC.I_FilaTablaID
		WHEN MATCHED THEN
			UPDATE SET D_FecRegistro = SRC.D_FecRegistro
		WHEN NOT MATCHED BY TARGET THEN
			INSERT (I_ObservID, I_TablaID, I_FilaTablaID, D_FecRegistro, I_ProcedenciaID)
			VALUES (SRC.I_ObservID, SRC.I_TablaID, SRC.I_FilaTablaID, SRC.D_FecRegistro, @I_ProcedenciaID)
		WHEN NOT MATCHED BY SOURCE AND TRG.I_ObservID = @I_ObservID AND TRG.I_ProcedenciaID = @I_ProcedenciaID THEN
			DELETE;

		SET @I_Observados = (SELECT COUNT(*) FROM TI_ObservacionRegistroTabla OBS INNER JOIN 
												  TR_Ec_Obl OBL ON OBS.I_FilaTablaID = OBL.I_RowID 
																	AND OBL.I_ProcedenciaID = OBS.I_ProcedenciaID
																	AND OBS.I_TablaID = @I_TablaID 
							  WHERE I_ObservID = @I_ObservID AND
									OBL.Ano = CAST(@I_Anio AS varchar(4)) AND 
									OBS.I_ProcedenciaID = @I_ProcedenciaID)

		SELECT @I_Observados as cant_obs, @D_FecProceso as fec_proceso

		COMMIT TRANSACTION				
		SET @B_Resultado = 1
		SET @T_Message = CAST(@I_Observados AS varchar)
	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION
		SET @B_Resultado = 0
		SET @T_Message = ERROR_MESSAGE() + ' LINE: ' + CAST(ERROR_LINE() AS varchar(10)) 
	END CATCH
END
GO


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_U_ValidarFechaVencimientoCuotaObligacionPorID')
	DROP PROCEDURE [dbo].[USP_U_ValidarFechaVencimientoCuotaObligacionPorID]
GO

CREATE PROCEDURE [dbo].[USP_U_ValidarFechaVencimientoCuotaObligacionPorID]	
	@I_RowID	  int = NULL,
	@B_Resultado  bit output,
	@T_Message	  nvarchar(4000) OUTPUT	
AS
--declare	@I_RowID	  int = NULL,
--			@B_Resultado  bit,
--			@T_Message    nvarchar(4000)
--exec USP_U_ValidarFechaVencimientoCuotaObligacion @I_RowID, @B_Resultado output, @T_Message output
--select @B_Resultado as resultado, @T_Message as mensaje
BEGIN
	DECLARE @I_RepetidosFecVenc int = 0
	DECLARE @D_FecProceso		datetime = GETDATE() 
	DECLARE @I_ObservID			int = 28
	DECLARE @I_TablaID			int = 5

	BEGIN TRANSACTION
	BEGIN TRY
		DECLARE @Cod_alu	varchar(20)
		DECLARE @Cod_Rc		varchar(5)
		DECLARE @Cuota_Pago	int
		DECLARE @Monto		decimal(10,2)
		DECLARE @Fch_Venc	date
		DECLARE @P			int
		DECLARE @I_Anio		int
		DECLARE @B_Correcto	int

		SELECT @Cod_alu = Cod_alu, @Monto = Monto, @P = P, @I_Anio = CAST(Ano as int),
			   @Fch_Venc = Fch_venc, @Cod_Rc = Cod_rc, @B_Correcto = B_Correcto
		  FROM TR_Ec_Obl
		 WHERE I_RowID = @I_RowID

		IF (@B_Correcto = 1)
		BEGIN
			EXEC USP_MigracionTP_U_RemoverObservacionObligacion @I_RowID, @I_TablaID, @I_ObservID, @D_FecProceso

			SET @B_Resultado = 1
			SET @T_Message = 'OK'

			GOTO END_TRANSACTION
		END

		SET @I_RepetidosFecVenc = (SELECT COUNT(*) FROM TR_Ec_Obl
									WHERE Cod_alu = @Cod_alu AND P = @P AND Cod_rc = @Cod_Rc
										  AND Cuota_pago = @Cuota_Pago)

		IF (@I_RepetidosFecVenc = 1)
		BEGIN
			EXEC USP_MigracionTP_U_RemoverObservacionObligacion @I_RowID, @I_TablaID, @I_ObservID, @D_FecProceso

			SET @B_Resultado = 1
			SET @T_Message = 'OK'
		END
		ELSE
		BEGIN
			EXEC USP_MigracionTP_U_RegistrarObservacionObligacion @I_RowID, @I_TablaID, @I_ObservID, @D_FecProceso

			SET @B_Resultado = 1
			SET @T_Message = 'La obligación se encuentra repetida, revisar obligaciones con la misma cuota de pago y fecha de vencimiento.'

		END

		END_TRANSACTION:
			COMMIT TRANSACTION				

	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION
		SET @B_Resultado = 0
		SET @T_Message = ERROR_MESSAGE() + ' LINE: ' + CAST(ERROR_LINE() AS varchar(10)) 
	END CATCH
END
GO


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_U_ValidarExisteAlumnoCabeceraObligacionPorObligID')
	DROP PROCEDURE [dbo].[USP_U_ValidarExisteAlumnoCabeceraObligacionPorObligID]
GO

CREATE PROCEDURE [dbo].[USP_U_ValidarExisteAlumnoCabeceraObligacionPorObligID]	
	@I_RowID	  int = NULL,
	@B_Resultado  bit output,
	@T_Message	  nvarchar(4000) OUTPUT	
AS
--declare @I_RowID	  int = NULL,
--		@B_Resultado  bit,
--		@T_Message	  nvarchar(4000)
--exec USP_U_ValidarExisteAlumnoCabeceraObligacionPorObligID @I_RowID, @B_Resultado output, @T_Message output
--select @B_Resultado as resultado, @T_Message as mensaje
BEGIN
	DECLARE @D_FecProceso datetime = GETDATE() 
	DECLARE @I_ObservID int = 24
	DECLARE @I_TablaID int = 5

	BEGIN TRANSACTION
	BEGIN TRY 
		DECLARE @Cod_alu			varchar(20)
		DECLARE @Cod_Rc				varchar(5)
		DECLARE @I_Periodo			int
		DECLARE @I_Anio				int
		
		SELECT @Cod_alu = Cod_alu, @I_Periodo = I_Periodo, @I_Anio = CAST(Ano as int), @Cod_Rc = Cod_rc
		  FROM TR_Ec_Obl
		 WHERE I_RowID = @I_RowID

		IF EXISTS(SELECT I_RowID FROM TR_Alumnos WHERE C_CodAlu = @Cod_alu and C_RcCod = @Cod_Rc)
		BEGIN
			EXECUTE USP_MigracionTP_U_RemoverObservacionObligacion @I_RowID, @I_TablaID, @I_ObservID, @D_FecProceso

			SET @B_Resultado = 1
			SET @T_Message = 'OK'

		END
		ELSE
		BEGIN
			EXECUTE USP_MigracionTP_U_RegistrarObservacionObligacion @I_RowID, @I_TablaID, @I_ObservID, @D_FecProceso
		 
			SET @B_Resultado = 0
			SET @T_Message = 'No se encontró código en tabla alumnos para obligación'
		END

		COMMIT TRANSACTION				

	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION
		SET @B_Resultado = 0
		SET @T_Message = ERROR_MESSAGE() + ' LINE: ' + CAST(ERROR_LINE() AS varchar(10)) 
	END CATCH
END
GO


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_U_ValidarProcedenciaObligacionCuotaPagoPorOblID')
	DROP PROCEDURE [dbo].[USP_U_ValidarProcedenciaObligacionCuotaPagoPorOblID]
GO

CREATE PROCEDURE [dbo].[USP_U_ValidarProcedenciaObligacionCuotaPagoPorOblID]	
	@I_RowID	  int = NULL,
	@B_Resultado  bit output,
	@T_Message	  nvarchar(4000) OUTPUT	
AS
--declare	@I_RowID	  int = NULL,
--			@B_Resultado  bit,
--			@T_Message    nvarchar(4000)
--exec USP_U_ValidarProcedenciaObligacionCuotaPagoPorOblID @I_RowID, @B_Resultado output, @T_Message output
--select @B_Resultado as resultado, @T_Message as mensaje
BEGIN
	DECLARE @I_Observados int = 0
	DECLARE @D_FecProceso datetime = GETDATE() 
	DECLARE @I_ObservID int = 34
	DECLARE @I_TablaID int = 5

	BEGIN TRANSACTION
	BEGIN TRY
		DECLARE @I_ProcedenciaID int
		DECLARE @Cuota_Pago	 int

		SELECT @I_ProcedenciaID = I_ProcedenciaID, @Cuota_Pago = Cuota_pago  FROM TR_Ec_Obl
		 WHERE I_RowID = @I_RowID

		IF ((SELECT I_ProcedenciaID FROM TR_Cp_Des WHERE Cuota_pago = @Cuota_Pago) = @I_ProcedenciaID)
		BEGIN
			EXEC USP_MigracionTP_U_RemoverObservacionObligacion @I_RowID, @I_TablaID, @I_ObservID, @D_FecProceso

			SET @B_Resultado = 1
			SET @T_Message = 'OK'
		END
		ELSE
		BEGIN
			EXEC USP_MigracionTP_U_RegistrarObservacionObligacion @I_RowID, @I_TablaID, @I_ObservID, @D_FecProceso

			SET @B_Resultado = 1
			SET @T_Message = 'La procedencia de la cuota de pago y la procedencia de la obligación son diferentes.'
		END

		COMMIT TRANSACTION				
		SET @B_Resultado = 1
		SET @T_Message = CAST(@I_Observados AS varchar)
	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION
		SET @B_Resultado = 0
		SET @T_Message = ERROR_MESSAGE() + ' LINE: ' + CAST(ERROR_LINE() AS varchar(10)) 
	END CATCH
END
GO


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_U_ValidarObligacionCuotaPagoMigradaPorOblID')
	DROP PROCEDURE [dbo].[USP_U_ValidarObligacionCuotaPagoMigradaPorOblID]
GO

CREATE PROCEDURE [dbo].[USP_U_ValidarObligacionCuotaPagoMigradaPorOblID]	
	@I_RowID	  int = NULL,
	@B_Resultado  bit output,
	@T_Message	  nvarchar(4000) OUTPUT	
AS
--declare	@I_RowID	  int = NULL,
--			@B_Resultado  bit,
--			@T_Message    nvarchar(4000)
--exec USP_U_ValidarObligacionCuotaPagoMigradaPorOblID @I_RowID, @B_Resultado output, @T_Message output
--select @B_Resultado as resultado, @T_Message as mensaje
BEGIN
	DECLARE @D_FecProceso datetime = GETDATE() 
	DECLARE @I_ObservID int = 32
	DECLARE @I_TablaID int = 5

	BEGIN TRANSACTION
	BEGIN TRY
		DECLARE @Cod_alu	 varchar(20)
		DECLARE @Cod_Rc		 varchar(5)
		DECLARE @Cuota_Pago	 int
		DECLARE @I_Anio		 int
		DECLARE @B_Migrado   int

		SELECT @Cod_alu = Cod_alu, @Cod_Rc = Cod_rc, @Cuota_Pago = Cuota_pago, @I_Anio = CAST(Ano as int)
		  FROM TR_Ec_Obl
		 WHERE I_RowID = @I_RowID
		 
		SET @B_Migrado = (SELECT B_Migrado FROM TR_Cp_Des WHERE Cuota_pago = @Cuota_Pago AND I_Anio = @I_Anio)

		IF (@B_Migrado = 1)
		BEGIN
			EXEC USP_MigracionTP_U_RemoverObservacionObligacion @I_RowID, @I_TablaID, @I_ObservID, @D_FecProceso

			SET @B_Resultado = 1
			SET @T_Message = 'OK'
		END
		ELSE
		BEGIN
			EXEC USP_MigracionTP_U_RegistrarObservacionObligacion @I_RowID, @I_TablaID, @I_ObservID, @D_FecProceso

			SET @B_Resultado = 1
			SET @T_Message = 'La cuota de pago de la obligacion no se encuentra migrada.'
		END


		COMMIT TRANSACTION				

	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION
		SET @B_Resultado = 0
		SET @T_Message = ERROR_MESSAGE() + ' LINE: ' + CAST(ERROR_LINE() AS varchar(10)) 
	END CATCH
END
GO


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_U_ValidarAnioEnCabeceraObligacionPorID')
	DROP PROCEDURE [dbo].[USP_U_ValidarAnioEnCabeceraObligacionPorID]
GO

CREATE PROCEDURE [dbo].[USP_U_ValidarAnioEnCabeceraObligacionPorID]	
	@I_RowID	  int = NULL,
	@B_Resultado  bit output,
	@T_Message	  nvarchar(4000) OUTPUT	
AS
--declare @I_RowID	  int = NULL,
--		@B_Resultado  bit,
--		@T_Message	  nvarchar(4000)
--exec ValidarAnioEnCabeceraObligacionPorID @I_RowID, @B_Resultado output, @T_Message output
--select @B_Resultado as resultado, @T_Message as mensaje
BEGIN

	DECLARE @D_FecProceso datetime = GETDATE() 
	DECLARE @I_ObservID int = 26
	DECLARE @I_TablaID int = 5

	BEGIN TRANSACTION
	BEGIN TRY 
		DECLARE @Cod_alu			varchar(20)
		DECLARE @Cod_Rc				varchar(5)
		DECLARE @I_Periodo			int
		DECLARE @I_Anio				int
		
		SELECT @I_Anio = ISNUMERIC(Ano)
		  FROM TR_Ec_Obl
		 WHERE I_RowID = @I_RowID

		IF (@I_Anio = 1)
		BEGIN
			EXECUTE USP_MigracionTP_U_RemoverObservacionObligacion @I_RowID, @I_TablaID, @I_ObservID, @D_FecProceso

			SET @B_Resultado = 1
			SET @T_Message = 'OK'
		END
		ELSE
		BEGIN
			EXECUTE USP_MigracionTP_U_RegistrarObservacionObligacion @I_RowID, @I_TablaID, @I_ObservID, @D_FecProceso
		 
			SET @B_Resultado = 0
			SET @T_Message = 'El campo año no contiene un valor numérico'
		END

		COMMIT TRANSACTION				
	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION
		SET @B_Resultado = 0
		SET @T_Message = ERROR_MESSAGE() + ' LINE: ' + CAST(ERROR_LINE() AS varchar(10)) 
	END CATCH
END
GO


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_U_ValidarPeriodoEnCabeceraObligacionPorID')
	DROP PROCEDURE [dbo].[USP_U_ValidarPeriodoEnCabeceraObligacionPorID]
GO

CREATE PROCEDURE [dbo].[USP_U_ValidarPeriodoEnCabeceraObligacionPorID]	
	@I_RowID	  int = NULL,
	@B_Resultado  bit output,
	@T_Message	  nvarchar(4000) OUTPUT	
AS
--declare	@I_RowID	  int = NULL,
--			@B_Resultado  bit,
--			@T_Message	  nvarchar(4000)
--exec USP_U_ValidarPeriodoEnCabeceraObligacionPorID @I_RowID, @B_Resultado output, @T_Message output
--select @B_Resultado as resultado, @T_Message as mensaje
BEGIN
	DECLARE @I_TablaID int = 5
	DECLARE @D_FecProceso datetime = GETDATE() 
	DECLARE @I_ObservID int = 27

	BEGIN TRANSACTION
	BEGIN TRY 
		DECLARE @Cod_alu	varchar(20)
		DECLARE @Cod_Rc		varchar(5)
		DECLARE @I_Periodo	int
		DECLARE @P			int
		DECLARE @I_Anio		int
		
		SELECT @Cod_alu = Cod_alu, @I_Periodo = I_Periodo, @P = P, @I_Anio = CAST(Ano as int)
		  FROM TR_Ec_Obl
		 WHERE I_RowID = @I_RowID

		IF(@I_Periodo IS NULL OR @P = '')
		BEGIN 
			EXECUTE USP_MigracionTP_U_RegistrarObservacionObligacion @I_RowID, @I_TablaID, @I_ObservID, @D_FecProceso
		 
			SET @B_Resultado = 0
			SET @T_Message = 'El campo periodo no contiene un valor válido'

		END 
		ELSE
		BEGIN 
			EXECUTE USP_MigracionTP_U_RemoverObservacionObligacion @I_RowID, @I_TablaID, @I_ObservID, @D_FecProceso

			SET @B_Resultado = 1
			SET @T_Message = 'OK'

		END

		COMMIT TRANSACTION
	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION
		SET @B_Resultado = 0
		SET @T_Message = ERROR_MESSAGE() + ' LINE: ' + CAST(ERROR_LINE() AS varchar(10)) 
	END CATCH
END
GO

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_U_49_ValidarSumaMontoDetalleObligacionPorObligID')
	DROP PROCEDURE [dbo].[USP_U_49_ValidarSumaMontoDetalleObligacionPorObligID]
GO

CREATE PROCEDURE [dbo].[USP_U_49_ValidarSumaMontoDetalleObligacionPorObligID]	
	@I_OblRowID	 tinyint,
	@B_Resultado bit output,
	@T_Message	 nvarchar(4000) OUTPUT	
AS
--declare	@I_RowID  	     int,
--			@B_Resultado	 bit,
--			@T_Message		 nvarchar(4000)
--exec USP_U_49_ValidarSumaMontoDetalleObligacionPorObligID @I_OblRowID, @B_Resultado output, @T_Message output
--select @B_Resultado as resultado, @T_Message as mensaje
BEGIN
	DECLARE @I_Observados int = 0
	DECLARE @D_FecProceso datetime = GETDATE() 
	DECLARE @I_ObservID int = 43
	DECLARE @I_TablaID int = 5

	BEGIN TRANSACTION
	BEGIN TRY 

		DECLARE @tot_monto_det	decimal(10,2)
		DECLARE @monto_obl		decimal(10,2)
		
		SELECT @tot_monto_det = sum(monto) FROM TR_Ec_Det 
		 WHERE I_OblRowID = @I_OblRowID 
			   AND Concepto <> 0 
			   AND Concepto_f = 0

		SELECT @monto_obl = monto FROM TR_Ec_Obl 
		 WHERE I_RowID = @I_OblRowID

		IF(@tot_monto_det = @monto_obl)
		BEGIN
			EXECUTE USP_MigracionTP_U_RemoverObservacionObligacion @I_OblRowID, @I_TablaID, @I_ObservID, @D_FecProceso
		END
		ELSE	
		BEGIN 
			EXECUTE USP_MigracionTP_U_RegistrarObservacionObligacion @I_OblRowID, @I_TablaID, @I_ObservID, @D_FecProceso
		END

		SET @T_Message = CAST(@@ROWCOUNT AS varchar)
		SET @B_Resultado = 1

		COMMIT TRANSACTION;
	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION
		SET @B_Resultado = 0
		SET @T_Message = ERROR_MESSAGE() + ' (Linea: ' + CAST(ERROR_LINE() AS varchar(11)) + ').' 
	END CATCH
END
GO


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_U_49_ValidarSumaMontoDetalleObligacion')
	DROP PROCEDURE [dbo].[USP_U_49_ValidarSumaMontoDetalleObligacion]
GO

CREATE PROCEDURE [dbo].[USP_U_49_ValidarSumaMontoDetalleObligacion]	
	@I_RowID	 tinyint,
	@B_Resultado bit output,
	@T_Message	 nvarchar(4000) OUTPUT	
AS
--declare	@I_RowID  	     int,
--			@B_Resultado	 bit,
--			@T_Message		 nvarchar(4000)
--exec USP_U_49_ValidarSumaMontoDetalleObligacion @I_RowID, @B_Resultado output, @T_Message output
--select @B_Resultado as resultado, @T_Message as mensaje
BEGIN
	DECLARE @I_Observados int = 0
	DECLARE @D_FecProceso datetime = GETDATE() 
	DECLARE @I_ObservID int = 43
	DECLARE @I_TablaID int = 4

	BEGIN TRANSACTION
	BEGIN TRY 
	
		DECLARE @Cuota_Pago	int
		DECLARE @tot_monto	decimal(10, 2)
		DECLARE @P			varchar(3)
		


		SET @T_Message = CAST(@@ROWCOUNT AS varchar)
		SET @B_Resultado = 1

		COMMIT TRANSACTION;
	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION
		SET @B_Resultado = 0
		SET @T_Message = ERROR_MESSAGE() + ' (Linea: ' + CAST(ERROR_LINE() AS varchar(11)) + ').' 
	END CATCH
END
GO



IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_U_29_ValidarMontoObligacionQueExisteEnCtasPorObligID')
	DROP PROCEDURE [dbo].[USP_U_29_ValidarMontoObligacionQueExisteEnCtasPorObligID]
GO

CREATE PROCEDURE [dbo].[USP_U_29_ValidarMontoObligacionQueExisteEnCtasPorObligID]	
	@I_RowID	 tinyint,
	@B_Resultado bit output,
	@T_Message	 nvarchar(4000) OUTPUT	
AS
--declare	@I_RowID  	     int,
--			@B_Resultado	 bit,
--			@T_Message		 nvarchar(4000)
--exec USP_U_29_ValidarMontoObligacionQueExisteEnCtasPorObligID @I_OblRowID, @B_Resultado output, @T_Message output
--select @B_Resultado as resultado, @T_Message as mensaje
BEGIN
	DECLARE @I_Observados int = 0
	DECLARE @D_FecProceso datetime = GETDATE() 
	DECLARE @I_ObservID int = 29
	DECLARE @I_TablaID int = 5

	BEGIN TRANSACTION
	BEGIN TRY 

		DECLARE @monto_Ctas	decimal(10,2)
		DECLARE @monto		decimal(10,2)
		DECLARE @cod_alu	varchar(20)
		DECLARE @cod_rc		varchar(5)
		DECLARE @cuota_pago	int
		DECLARE @anio		varchar(4)
		DECLARE @I_Periodo  int
		DECLARE @D_FecVenc  date


		SELECT @cod_alu = Cod_alu, @cod_rc = Cod_rc, @cuota_pago = Cuota_pago, 
			   @anio = Ano, @I_Periodo = I_Periodo, @monto = monto, @D_FecVenc = Fch_venc
		  FROM TR_Ec_Obl WHERE I_RowID = @I_RowID

		SELECT @monto_Ctas = I_MontoOblig 
		  FROM BD_OCEF_CtasPorCobrar.dbo.TR_ObligacionAluCab O
			   INNER JOIN BD_OCEF_CtasPorCobrar.dbo.TC_MatriculaAlumno MA ON O.I_MatAluID = MA.I_MatAluID
			   INNER JOIN BD_OCEF_CtasPorCobrar.dbo.TC_Proceso P ON P.I_ProcesoID = O.I_ProcesoID
	     WHERE O.I_ProcesoID = @cuota_pago
			   AND C_CodAlu = @cod_alu
			   AND C_CodRc = @cod_rc
			   AND CAST(P.I_Anio AS varchar) = @anio
			   AND P.I_Periodo = @I_Periodo
			   AND O.D_FecVencto = @D_FecVenc

		IF(@monto = @monto_Ctas)
		BEGIN
			EXECUTE USP_MigracionTP_U_RemoverObservacionObligacion @I_RowID, @I_TablaID, @I_ObservID, @D_FecProceso
		END
		ELSE	
		BEGIN 
			EXECUTE USP_MigracionTP_U_RegistrarObservacionObligacion @I_RowID, @I_TablaID, @I_ObservID, @D_FecProceso
		END

		SET @T_Message = CAST(@@ROWCOUNT AS varchar)
		SET @B_Resultado = 1

		COMMIT TRANSACTION;
	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION
		SET @B_Resultado = 0
		SET @T_Message = ERROR_MESSAGE() + ' (Linea: ' + CAST(ERROR_LINE() AS varchar(11)) + ').' 
	END CATCH
END
GO

