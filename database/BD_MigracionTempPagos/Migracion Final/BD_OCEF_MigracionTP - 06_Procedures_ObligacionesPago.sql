/*
==================================================================
	BD_OCEF_MigracionTP - 06_Procedures_ObligacionesPago
==================================================================
*/


USE BD_OCEF_MigracionTP
GO




/*	
	===============================================================================================
		Validaciones para migracion de ec_obl (solo obligaciones de pago)	
	===============================================================================================
*/ 


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_U_ValidarExisteAlumnoCabeceraObligacion')
	DROP PROCEDURE [dbo].[USP_U_ValidarExisteAlumnoCabeceraObligacion]
GO

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_24_ExisteAlumno')
	DROP PROCEDURE [dbo].[USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_24_ExisteAlumno]
GO

CREATE PROCEDURE [dbo].[USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_24_ExisteAlumno] 
	@I_ProcedenciaID tinyint,
	@T_Anio		  varchar(4),
	@B_Resultado  bit output,
	@T_Message	  nvarchar(4000) OUTPUT	
AS
/*
	DESCRIPCION: Marcar TR_Ec_Obl con B_Migrable = 0 cuando cod_alu no existe en la lista alumno migrada o en la base de datos de repositorio
				 para el año y procedencia

	DECLARE @I_ProcedenciaID	tinyint = 1,
			@T_Anio		  varchar(4) = '2011',
			@B_Resultado  bit,
			@T_Message	  nvarchar(4000)
	EXEC USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_24_ExisteAlumno @I_ProcedenciaID, @T_Anio, @B_Resultado output, @T_Message output
	SELECT @B_Resultado as resultado, @T_Message as mensaje
*/
BEGIN
	DECLARE @I_Observados int = 0
	DECLARE @D_FecProceso datetime = GETDATE() 
	DECLARE @I_ObservID int = 24
	DECLARE @I_TablaID int = 5

	BEGIN TRANSACTION
	BEGIN TRY 		
	
		UPDATE	ec_obl
		SET		B_Migrable = 0,
				D_FecEvalua = @D_FecProceso
		FROM	TR_Ec_Obl ec_obl
				LEFT JOIN BD_UNFV_Repositorio.dbo.TC_Alumno ec_alu ON ec_obl.Cod_alu = ec_alu.C_CodAlu 
																	  AND ec_obl.Cod_rc = ec_alu.C_RcCod
		WHERE	ec_alu.C_CodAlu IS NULL
				AND ec_obl.Ano = @T_Anio
			    AND ec_obl.I_ProcedenciaID = @I_ProcedenciaID


		MERGE   TI_ObservacionRegistroTabla AS TRG
		USING 	(SELECT	@I_ObservID AS I_ObservID, @I_TablaID AS I_TablaID, ec_obl.I_RowID AS I_FilaTablaID, 
						@D_FecProceso AS D_FecRegistro 
				   FROM	TR_Ec_Obl ec_obl
						LEFT JOIN BD_UNFV_Repositorio.dbo.TC_Alumno ec_alu ON ec_obl.Cod_alu = ec_alu.C_CodAlu 
																			  AND ec_obl.Cod_rc = ec_alu.C_RcCod
				  WHERE	ec_alu.C_CodAlu IS NULL
						AND ec_obl.Ano = @T_Anio
						AND ec_obl.I_ProcedenciaID = @I_ProcedenciaID
				) AS SRC
		ON TRG.I_ObservID = SRC.I_ObservID AND TRG.I_TablaID = SRC.I_TablaID AND TRG.I_FilaTablaID = SRC.I_FilaTablaID
		WHEN MATCHED THEN
			UPDATE SET D_FecRegistro = SRC.D_FecRegistro
		WHEN NOT MATCHED BY TARGET THEN
			INSERT (I_ObservID, I_TablaID, I_FilaTablaID, D_FecRegistro, I_ProcedenciaID)
			VALUES (SRC.I_ObservID, SRC.I_TablaID, SRC.I_FilaTablaID, SRC.D_FecRegistro, @I_ProcedenciaID);


		UPDATE OBS
		   SET D_FecResuelto = @D_FecProceso,
			   B_Resuelto = 1
		  FROM TI_ObservacionRegistroTabla OBS
			   INNER JOIN (SELECT ec_obl.I_RowID, ec_obl.Ano, ec_obl.Cod_alu, ec_obl.Cod_rc, ec_obl.I_ProcedenciaID, ec_alu.C_CodAlu   
							 FROM TR_Ec_Obl ec_obl
								  LEFT JOIN BD_UNFV_Repositorio.dbo.TC_Alumno ec_alu ON ec_obl.Cod_alu = ec_alu.C_CodAlu 
								  														AND ec_obl.Cod_rc = ec_alu.C_RcCod
							WHERE ec_alu.C_CodAlu IS NOT NULL
								  AND ec_obl.Ano = @T_Anio
								  AND ec_obl.I_ProcedenciaID = @I_ProcedenciaID) OBL 
						  ON OBS.I_FilaTablaID = OBL.I_RowID
							 AND OBS.I_ProcedenciaID = OBL.I_ProcedenciaID
		 WHERE OBS.I_ObservID = @I_ObservID 
			   AND OBS.I_TablaID = @I_TablaID

		
		SET @I_Observados = (SELECT COUNT(*) 
							   FROM (SELECT * FROM TR_Ec_Obl WHERE Ano = @T_Anio AND I_ProcedenciaID = @I_ProcedenciaID) OBL
									INNER JOIN (SELECT * FROM TI_ObservacionRegistroTabla WHERE I_ObservID = @I_ObservID AND I_TablaID = @I_TablaID) OBS 
											   ON OBS.I_FilaTablaID = OBL.I_RowID AND OBS.I_ProcedenciaID = OBL.I_ProcedenciaID
							 WHERE  B_Resuelto = 0)
				
		SELECT @I_Observados as cant_obs, @D_FecProceso as fec_proceso


		COMMIT TRANSACTION				
		SET @B_Resultado = 1
		SET @T_Message = '{ ' +
							'Type: "summary", ' + 
							'Title: "Observados", ' + 
							'Value: ' + CAST(@I_Observados AS varchar)  +
						 '}' 
	END TRY
	BEGIN CATCH
		IF (@@TRANCOUNT > 0) 
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


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_24_ExisteAlumnoPorOblID')
	DROP PROCEDURE [dbo].[USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_24_ExisteAlumnoPorOblID]
GO

CREATE PROCEDURE [dbo].[USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_24_ExisteAlumnoPorOblID]	
	@I_RowID	  int = NULL,
	@B_Resultado  bit output,
	@T_Message	  nvarchar(4000) OUTPUT	
AS
/*
	DESCRIPCION: Marcar TR_Ec_Obl con B_Migrable = 0 cuando cod_alu no existe en la lista alumno migrada o en la base de datos de repositorio
				 para el I_RowID de la obligacion

	DECLARE @I_RowID	  int = 5013,
			@B_Resultado  bit,
			@T_Message	  nvarchar(4000)
	EXEC USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_24_ExisteAlumnoPorOblID @I_ProcedenciaID, @I_RowID, @B_Resultado output, @T_Message output
	SELECT @B_Resultado as resultado, @T_Message as mensaje
*/
BEGIN
	DECLARE @I_Observados int = 0
	DECLARE @D_FecProceso datetime = GETDATE() 
	DECLARE @I_ObservID int = 24
	DECLARE @I_TablaID int = 5

	BEGIN TRANSACTION
	BEGIN TRY 


		UPDATE	ec_obl
		SET		B_Migrable = 0,
				D_FecEvalua = @D_FecProceso
		FROM	TR_Ec_Obl ec_obl
				LEFT JOIN BD_UNFV_Repositorio.dbo.TC_Alumno ec_alu ON ec_obl.Cod_alu = ec_alu.C_CodAlu 
																	  AND ec_obl.Cod_rc = ec_alu.C_RcCod
		WHERE	ec_alu.C_CodAlu IS NULL
				AND ec_obl.I_RowID = @I_RowID


		MERGE   TI_ObservacionRegistroTabla AS TRG
		USING 	(SELECT	@I_ObservID AS I_ObservID, @I_TablaID AS I_TablaID, ec_obl.I_RowID AS I_FilaTablaID, 
						@D_FecProceso AS D_FecRegistro, ec_obl.I_ProcedenciaID
				   FROM	TR_Ec_Obl ec_obl
						LEFT JOIN BD_UNFV_Repositorio.dbo.TC_Alumno ec_alu ON ec_obl.Cod_alu = ec_alu.C_CodAlu 
																			  AND ec_obl.Cod_rc = ec_alu.C_RcCod
				  WHERE	ec_alu.C_CodAlu IS NULL
						AND ec_obl.I_RowID = @I_RowID
				) AS SRC
		ON TRG.I_ObservID = SRC.I_ObservID AND TRG.I_TablaID = SRC.I_TablaID AND TRG.I_FilaTablaID = SRC.I_FilaTablaID
		WHEN MATCHED THEN
			UPDATE SET D_FecRegistro = SRC.D_FecRegistro
		WHEN NOT MATCHED BY TARGET THEN
			INSERT (I_ObservID, I_TablaID, I_FilaTablaID, D_FecRegistro, I_ProcedenciaID)
			VALUES (SRC.I_ObservID, SRC.I_TablaID, SRC.I_FilaTablaID, SRC.D_FecRegistro, SRC.I_ProcedenciaID);


		UPDATE OBS
		   SET D_FecResuelto = @D_FecProceso,
			   B_Resuelto = 1
		  FROM TI_ObservacionRegistroTabla OBS
			   INNER JOIN (SELECT ec_obl.I_RowID, ec_obl.Ano, ec_obl.Cod_alu, ec_obl.Cod_rc, ec_obl.I_ProcedenciaID, ec_alu.C_CodAlu   
							 FROM TR_Ec_Obl ec_obl
								  LEFT JOIN BD_UNFV_Repositorio.dbo.TC_Alumno ec_alu ON ec_obl.Cod_alu = ec_alu.C_CodAlu 
								  														AND ec_obl.Cod_rc = ec_alu.C_RcCod
							WHERE ec_alu.C_CodAlu IS NOT NULL
								  AND ec_obl.I_RowID = @I_RowID) OBL 
						  ON OBS.I_FilaTablaID = OBL.I_RowID
		 WHERE OBS.I_ObservID = @I_ObservID 
			   AND OBS.I_TablaID = @I_TablaID

		
		SET @I_Observados = (SELECT COUNT(*) 
							   FROM (SELECT * FROM TR_Ec_Obl WHERE I_RowID = @I_RowID) OBL
									INNER JOIN (SELECT * FROM TI_ObservacionRegistroTabla WHERE I_ObservID = @I_ObservID AND I_TablaID = @I_TablaID) OBS 
											   ON OBS.I_FilaTablaID = OBL.I_RowID AND OBS.I_ProcedenciaID = OBL.I_ProcedenciaID
							  WHERE B_Resuelto = 0)

		SELECT @I_Observados as cant_obs, @D_FecProceso as fec_proceso

		COMMIT TRANSACTION				
		SET @B_Resultado = 1
		SET @T_Message = '{ ' +
							'Type: "summary", ' + 
							'Title: "Observados", ' + 
							'Value: ' + CAST(@I_Observados AS varchar)  +
						 '}' 

	END TRY
	BEGIN CATCH
		IF (@@TRANCOUNT > 0) 
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


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_U_ValidarAnioEnCabeceraObligacion')
	DROP PROCEDURE [dbo].[USP_U_ValidarAnioEnCabeceraObligacion]
GO

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_26_AnioNumerico')
	DROP PROCEDURE [dbo].[USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_26_AnioNumerico]
GO

CREATE PROCEDURE [dbo].[USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_26_AnioNumerico]	
	@I_ProcedenciaID tinyint,
	@B_Resultado  bit output,
	@T_Message	  nvarchar(4000) OUTPUT	
AS
/*
	DESCRIPCION: Marcar TR_Ec_Obl con B_Migrable = 0 cuando no existe un valor válido de año para la procedencia de la obligacion

	DECLARE @I_ProcedenciaID	tinyint = 1, 
			@B_Resultado  bit,
			@T_Message	  nvarchar(4000)
	EXEC USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_26_AnioNumerico @I_ProcedenciaID, @B_Resultado output, @T_Message output
	SELECT @B_Resultado as resultado, @T_Message as mensaje
*/
BEGIN
	DECLARE @I_Observados int = 0
	DECLARE @D_FecProceso datetime = GETDATE() 
	DECLARE @I_ObservID int = 26
	DECLARE @I_TablaID int = 5

	BEGIN TRANSACTION
	BEGIN TRY 
		UPDATE	TR_Ec_Obl
		SET		B_Migrable = 0,
				D_FecEvalua = @D_FecProceso
		WHERE	ISNUMERIC(Ano) = 0
				AND I_ProcedenciaID = @I_ProcedenciaID


		MERGE TI_ObservacionRegistroTabla AS TRG
		USING 	(SELECT	@I_ObservID AS I_ObservID, @I_TablaID AS I_TablaID, I_RowID AS I_FilaTablaID, @D_FecProceso AS D_FecRegistro 
				   FROM	TR_Ec_Obl 
				  WHERE	ISNUMERIC(Ano) = 0 
						AND I_ProcedenciaID = @I_ProcedenciaID
				) AS SRC
		ON TRG.I_ObservID = SRC.I_ObservID AND TRG.I_TablaID = SRC.I_TablaID AND TRG.I_FilaTablaID = SRC.I_FilaTablaID
		WHEN MATCHED THEN
			UPDATE SET D_FecRegistro = SRC.D_FecRegistro
		WHEN NOT MATCHED BY TARGET THEN
			INSERT (I_ObservID, I_TablaID, I_FilaTablaID, D_FecRegistro, I_ProcedenciaID)
			VALUES (SRC.I_ObservID, SRC.I_TablaID, SRC.I_FilaTablaID, SRC.D_FecRegistro, @I_ProcedenciaID);


		UPDATE OBS
		   SET D_FecResuelto = @D_FecProceso,
			   B_Resuelto = 1
		  FROM TI_ObservacionRegistroTabla OBS
			   INNER JOIN (SELECT I_RowID, I_ProcedenciaID FROM TR_Ec_Obl WHERE ISNUMERIC(Ano) = 1) OBL
						   ON OBS.I_FilaTablaID = OBL.I_RowID
							  AND OBS.I_ProcedenciaID = OBL.I_ProcedenciaID
		 WHERE OBS.I_ObservID = @I_ObservID 
			   AND OBS.I_TablaID = @I_TablaID

		SET @I_Observados = (SELECT COUNT(*) FROM TI_ObservacionRegistroTabla 
											WHERE I_ObservID = @I_ObservID 
												  AND I_TablaID = @I_TablaID
												  AND I_ProcedenciaID = @I_ProcedenciaID
												  AND B_Resuelto = 0) 

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
		IF (@@TRANCOUNT > 0) 
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



IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_26_AnioNumericoPorOblID')
	DROP PROCEDURE [dbo].[USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_26_AnioNumericoPorOblID]
GO

CREATE PROCEDURE [dbo].[USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_26_AnioNumericoPorOblID]	
	@I_RowID	  int,
	@B_Resultado  bit output,
	@T_Message	  nvarchar(4000) OUTPUT	
AS
/*
	DESCRIPCION: Marcar TR_Ec_Obl con B_Migrable = 0 cuando no existe un valor válido de año para el ID de la obligacion

	DECLARE @I_RowID	  int = 22553,
			@B_Resultado  bit,
			@T_Message	  nvarchar(4000)
	EXEC USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_26_AnioNumericoPorOblID @I_RowID, @B_Resultado output, @T_Message output
	SELECT @B_Resultado as resultado, @T_Message as mensaje
*/
BEGIN
	DECLARE @I_Observados int = 0
	DECLARE @D_FecProceso datetime = GETDATE() 
	DECLARE @I_ObservID int = 26
	DECLARE @I_TablaID int = 5

	BEGIN TRANSACTION
	BEGIN TRY 
		UPDATE	TR_Ec_Obl
		SET		B_Migrable = 0,
				D_FecEvalua = @D_FecProceso
		WHERE	ISNUMERIC(Ano) = 0
				AND I_RowID = @I_RowID


		MERGE TI_ObservacionRegistroTabla AS TRG
		USING 	(SELECT	@I_ObservID AS I_ObservID, @I_TablaID AS I_TablaID, I_RowID AS I_FilaTablaID, I_ProcedenciaID, @D_FecProceso AS D_FecRegistro 
				   FROM	TR_Ec_Obl 
				  WHERE	ISNUMERIC(Ano) = 0 
						AND I_RowID = @I_RowID
				) AS SRC
		ON TRG.I_ObservID = SRC.I_ObservID AND TRG.I_TablaID = SRC.I_TablaID AND TRG.I_FilaTablaID = SRC.I_FilaTablaID
		WHEN MATCHED THEN
			UPDATE SET D_FecRegistro = SRC.D_FecRegistro
		WHEN NOT MATCHED BY TARGET THEN
			INSERT (I_ObservID, I_TablaID, I_FilaTablaID, D_FecRegistro, I_ProcedenciaID)
			VALUES (SRC.I_ObservID, SRC.I_TablaID, SRC.I_FilaTablaID, SRC.D_FecRegistro, SRC.I_ProcedenciaID);


		UPDATE OBS
		   SET D_FecResuelto = @D_FecProceso,
			   B_Resuelto = 1
		  FROM TI_ObservacionRegistroTabla OBS
			   INNER JOIN (SELECT I_RowID, I_ProcedenciaID FROM TR_Ec_Obl WHERE ISNUMERIC(Ano) = 1) OBL
						   ON OBS.I_FilaTablaID = OBL.I_RowID
							  AND OBS.I_ProcedenciaID = OBL.I_ProcedenciaID
		 WHERE OBS.I_ObservID = @I_ObservID 
			   AND OBS.I_TablaID = @I_TablaID

		SET @I_Observados = (SELECT COUNT(*) FROM TI_ObservacionRegistroTabla 
											WHERE I_ObservID = @I_ObservID AND I_TablaID = @I_TablaID
												  AND I_FilaTablaID = @I_RowID
												  AND B_Resuelto = 0) 

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


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_U_ValidarPeriodoEnCabeceraObligacion')
	DROP PROCEDURE [dbo].[USP_U_ValidarPeriodoEnCabeceraObligacion]
GO

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_27_Periodo')
	DROP PROCEDURE [dbo].[USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_27_Periodo]
GO

CREATE PROCEDURE [dbo].[USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_27_Periodo]	
	@I_ProcedenciaID tinyint,
	@T_Anio		  varchar(4) = NULL,
	@B_Resultado  bit output,
	@T_Message	  nvarchar(4000) OUTPUT	
AS
/*
	DESCRIPCION: Marcar TR_Ec_Obl con B_Migrable = 0 cuando no existe un valor válido para periodo para la procedencia y año de la obligacion 

	DECLARE	@I_ProcedenciaID	tinyint = 1, 
			@T_Anio		  varchar(4) = '2010',
			@B_Resultado  bit,
			@T_Message	  nvarchar(4000)
	EXEC USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_27_Periodo @I_ProcedenciaID, @T_Anio, @B_Resultado output, @T_Message output
	SELECT @B_Resultado as resultado, @T_Message as mensaje
*/
BEGIN
	DECLARE @I_Observados int = 0
	DECLARE @I_TablaID int = 5
	DECLARE @D_FecProceso datetime = GETDATE() 
	DECLARE @I_ObservID int = 27


	BEGIN TRANSACTION
	BEGIN TRY 
			
		UPDATE	TR_Ec_Obl
		SET		B_Migrable = 0,
				D_FecEvalua = @D_FecProceso
		WHERE	I_Periodo IS NULL OR P = ''
				AND I_ProcedenciaID = @I_ProcedenciaID
			    AND Ano = @T_Anio

		MERGE TI_ObservacionRegistroTabla AS TRG
		USING 	(SELECT	@I_ObservID AS I_ObservID, @I_TablaID AS I_TablaID, I_RowID AS I_FilaTablaID, @D_FecProceso AS D_FecRegistro, I_ProcedenciaID
				   FROM TR_Ec_Obl
				  WHERE	I_Periodo IS NULL OR P = ''
						AND I_ProcedenciaID = @I_ProcedenciaID
						AND Ano = @T_Anio
				) AS SRC
		ON TRG.I_ObservID = SRC.I_ObservID AND TRG.I_TablaID = SRC.I_TablaID AND TRG.I_FilaTablaID = SRC.I_FilaTablaID
		WHEN MATCHED AND SRC.I_ProcedenciaID = @I_ProcedenciaID THEN
			UPDATE SET D_FecRegistro = SRC.D_FecRegistro
		WHEN NOT MATCHED BY TARGET AND SRC.I_ProcedenciaID = @I_ProcedenciaID THEN
			INSERT (I_ObservID, I_TablaID, I_FilaTablaID, D_FecRegistro, I_ProcedenciaID)
			VALUES (SRC.I_ObservID, SRC.I_TablaID, SRC.I_FilaTablaID, SRC.D_FecRegistro, @I_ProcedenciaID);


		UPDATE OBS
		   SET D_FecResuelto = @D_FecProceso,
			   B_Resuelto = 1
		  FROM TI_ObservacionRegistroTabla OBS
			   INNER JOIN (SELECT * FROM TR_Ec_Obl 
							WHERE I_Periodo IS NOT NULL AND P <> ''
								  AND Ano = @T_Anio
								  AND I_ProcedenciaID = @I_ProcedenciaID
						  ) OBL 
						  ON OBS.I_FilaTablaID = OBL.I_RowID
							 AND OBS.I_ProcedenciaID = OBL.I_ProcedenciaID
		 WHERE OBS.I_ObservID = @I_ObservID 
			   AND OBS.I_TablaID = @I_TablaID
			

		SET @I_Observados = (SELECT COUNT(*) FROM (SELECT * FROM TR_Ec_Obl WHERE Ano = @T_Anio AND I_ProcedenciaID = @I_ProcedenciaID) OBL
												  INNER JOIN TI_ObservacionRegistroTabla OBS ON OBS.I_FilaTablaID = OBL.I_RowID
																								AND OBS.I_ProcedenciaID = OBL.I_ProcedenciaID
							 WHERE I_ObservID = @I_ObservID AND I_TablaID = @I_TablaID 
								   AND OBS.I_ProcedenciaID = @I_ProcedenciaID
								   AND B_Resuelto = 0)

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
		IF (@@TRANCOUNT > 0) 
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


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_27_PeriodoPorOblID')
	DROP PROCEDURE [dbo].[USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_27_PeriodoPorOblID]
GO

CREATE PROCEDURE [dbo].[USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_27_PeriodoPorOblID]	
	@I_RowID	  int,
	@B_Resultado  bit output,
	@T_Message	  nvarchar(4000) OUTPUT	
AS
/*
	DESCRIPCION: Marcar TR_Ec_Obl con B_Migrable = 0 cuando no existe un valor válido para periodo para el ID de la obligacion 

	DECLARE	@I_RowID		  int = 5013,
			@B_Resultado  bit,
			@T_Message	  nvarchar(4000)
	EXEC USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_27_PeriodoPorOblID @I_RowID, @B_Resultado output, @T_Message output
	SELECT @B_Resultado as resultado, @T_Message as mensaje
*/
BEGIN
	DECLARE @I_Observados int = 0
	DECLARE @I_TablaID int = 5
	DECLARE @D_FecProceso datetime = GETDATE() 
	DECLARE @I_ObservID int = 27

	BEGIN TRANSACTION
	BEGIN TRY 

		UPDATE	TR_Ec_Obl
		SET		B_Migrable = 0,
				D_FecEvalua = @D_FecProceso
		WHERE	I_Periodo IS NULL OR P = ''
				AND I_RowID = @I_RowID
				

		MERGE TI_ObservacionRegistroTabla AS TRG
		USING 	(SELECT	@I_ObservID AS I_ObservID, @I_TablaID AS I_TablaID, I_RowID AS I_FilaTablaID, @D_FecProceso AS D_FecRegistro, I_ProcedenciaID
				   FROM TR_Ec_Obl
				  WHERE	I_Periodo IS NULL OR P = ''
						AND I_RowID = @I_RowID
				) AS SRC
		ON TRG.I_ObservID = SRC.I_ObservID AND TRG.I_TablaID = SRC.I_TablaID AND TRG.I_FilaTablaID = SRC.I_FilaTablaID AND SRC.I_ProcedenciaID = TRG.I_ProcedenciaID
		WHEN MATCHED THEN
			UPDATE SET D_FecRegistro = SRC.D_FecRegistro
		WHEN NOT MATCHED BY TARGET THEN
			INSERT (I_ObservID, I_TablaID, I_FilaTablaID, D_FecRegistro, I_ProcedenciaID)
			VALUES (SRC.I_ObservID, SRC.I_TablaID, SRC.I_FilaTablaID, SRC.D_FecRegistro, SRC.I_ProcedenciaID);


		UPDATE OBS
		   SET D_FecResuelto = @D_FecProceso,
			   B_Resuelto = 1
		  FROM TI_ObservacionRegistroTabla OBS
			   INNER JOIN (SELECT * FROM TR_Ec_Obl 
							WHERE I_Periodo IS NOT NULL AND P <> ''
								  AND I_RowID = @I_RowID
						  ) OBL 
						  ON OBS.I_FilaTablaID = OBL.I_RowID
							 AND OBS.I_ProcedenciaID = OBL.I_ProcedenciaID
		 WHERE OBS.I_ObservID = @I_ObservID 
			   AND OBS.I_TablaID = @I_TablaID
			

		SET @I_Observados = (SELECT COUNT(*) FROM (SELECT * FROM TR_Ec_Obl WHERE I_RowID = @I_RowID) OBL
												  INNER JOIN TI_ObservacionRegistroTabla OBS ON OBS.I_FilaTablaID = OBL.I_RowID
																								AND OBS.I_ProcedenciaID = OBL.I_ProcedenciaID
							 WHERE I_ObservID = @I_ObservID AND I_TablaID = @I_TablaID 
								   AND I_FilaTablaID = @I_RowID
								   AND B_Resuelto = 0)

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
		IF (@@TRANCOUNT > 0) 
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



IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_U_ValidarFechaVencimientoCuotaObligacion')
	DROP PROCEDURE [dbo].[USP_U_ValidarFechaVencimientoCuotaObligacion]
GO

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_28_FechaVencimientoCuota')
	DROP PROCEDURE [dbo].[USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_28_FechaVencimientoCuota]
GO

CREATE PROCEDURE [dbo].[USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_28_FechaVencimientoCuota]	
	@I_ProcedenciaID tinyint,
	@T_Anio			 varchar(4) = NULL,
	@B_Resultado  bit OUTPUT,
	@T_Message	  nvarchar(4000) OUTPUT	
AS
/*
	DESCRIPCION: Marcar TR_Ec_Obl con B_Migrable = 0 cuando la fecha de vencimiento es diferente a la fecha de vencimiento de la cuota de pago para el año y procedencia

	DECLARE	@I_ProcedenciaID	tinyint = 1, 
			@T_Anio				varchar(4) = 2010,
			@B_Resultado		bit,
			@T_Message			nvarchar(4000)
	EXEC USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_28_FechaVencimientoCuota @I_ProcedenciaID, @T_Anio, @B_Resultado output, @T_Message output
	SELECT @B_Resultado as resultado, @T_Message as mensaje
*/
BEGIN
	DECLARE @I_Observados int = 0
	DECLARE @D_FecProceso datetime = GETDATE() 
	DECLARE @I_ObservID int = 28
	DECLARE @I_TablaID int = 5

	BEGIN TRANSACTION
	BEGIN TRY

		SELECT Ano, P, Cod_alu, Cod_rc, obl.Cuota_pago, obl.Fch_venc, Tipo_oblig, Monto, obl.I_RowID
		INTO  #temp_obl_fecVenc_dif_cuota_anio
		FROM  TR_Ec_Obl obl
			  LEFT JOIN TR_Cp_Des cp ON obl.Cuota_pago = cp.Cuota_pago 
										AND obl.I_ProcedenciaID = cp.I_ProcedenciaID
										AND cp.Eliminado = 0
		WHERE obl.I_ProcedenciaID = @I_ProcedenciaID
			  AND Ano = @T_Anio
			  AND obl.Fch_venc <> cp.Fch_venc


		UPDATE	TRG_1
		SET		B_Migrable = 0,
				D_FecEvalua = @D_FecProceso
		FROM	TR_Ec_Obl TRG_1
				INNER JOIN #temp_obl_fecVenc_dif_cuota_anio SRC_1 
				ON TRG_1.I_RowID = SRC_1.I_RowID
		WHERE	ISNULL(TRG_1.B_Correcto, 0) = 0


		MERGE TI_ObservacionRegistroTabla AS TRG
		USING (SELECT @I_ObservID AS I_ObservID, @I_TablaID AS I_TablaID, TRG_1.I_RowID AS I_FilaTablaID, @D_FecProceso AS D_FecRegistro 
				 FROM TR_Ec_Obl TRG_1
					  INNER JOIN #temp_obl_fecVenc_dif_cuota_anio SRC_1 
								ON TRG_1.I_RowID = SRC_1.I_RowID
				 WHERE	TRG_1.Ano = @T_Anio
						AND ISNULL(TRG_1.B_Correcto, 0) = 0
			  ) AS SRC
		ON TRG.I_ObservID = SRC.I_ObservID AND TRG.I_TablaID = SRC.I_TablaID AND TRG.I_FilaTablaID = SRC.I_FilaTablaID
		WHEN MATCHED THEN
			UPDATE SET D_FecRegistro = SRC.D_FecRegistro
		WHEN NOT MATCHED BY TARGET THEN
			INSERT (I_ObservID, I_TablaID, I_FilaTablaID, D_FecRegistro, I_ProcedenciaID)
			VALUES (SRC.I_ObservID, SRC.I_TablaID, SRC.I_FilaTablaID, SRC.D_FecRegistro, @I_ProcedenciaID);


		UPDATE OBS
		   SET D_FecResuelto = @D_FecProceso,
			   B_Resuelto = 1
		  FROM TI_ObservacionRegistroTabla OBS
			   INNER JOIN (SELECT ec_obl.I_RowID, ec_obl.Ano, ec_obl.Cod_alu, ec_obl.Cod_rc, ec_obl.I_ProcedenciaID
							 FROM TR_Ec_Obl ec_obl
								  LEFT JOIN #temp_obl_fecVenc_dif_cuota_anio SRC_1 ON ec_obl.I_RowID = SRC_1.I_RowID
							WHERE SRC_1.I_RowID IS NULL) OBL 
						  ON OBS.I_FilaTablaID = OBL.I_RowID
							 AND OBS.I_ProcedenciaID = OBL.I_ProcedenciaID
		 WHERE OBS.I_ObservID = @I_ObservID 
			   AND OBS.I_TablaID = @I_TablaID

		SET @I_Observados = (SELECT COUNT(*) FROM TI_ObservacionRegistroTabla OBS INNER JOIN 
												  TR_Ec_Obl OBL ON OBS.I_FilaTablaID = OBL.I_RowID 
																	AND OBL.I_ProcedenciaID = OBS.I_ProcedenciaID
																	AND OBS.I_TablaID = @I_TablaID 
							  WHERE I_ObservID = @I_ObservID AND
									OBL.Ano = @T_Anio AND
									OBS.I_ProcedenciaID = @I_ProcedenciaID AND 
									B_Resuelto = 0)

		SELECT @I_Observados as cant_obs, @D_FecProceso as fec_proceso

		COMMIT TRANSACTION				
		SET @B_Resultado = 1
		SET @T_Message = '{ ' +
							 'Type: "summary", ' + 
							 'Title: "Observados ", ' + 
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



IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_28_FechaVencimientoCuotaPorOblID')
	DROP PROCEDURE [dbo].[USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_28_FechaVencimientoCuotaPorOblID]
GO

CREATE PROCEDURE [dbo].[USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_28_FechaVencimientoCuotaPorOblID]	
	@I_RowID	  int,
	@B_Resultado  bit OUTPUT,
	@T_Message	  nvarchar(4000) OUTPUT	
AS
/*
	DESCRIPCION: Marcar TR_Ec_Obl con B_Migrable = 0 cuando la fecha de vencimiento es diferente a la fecha de vencimiento de la cuota de pago de la oblID

	DECLARE	@I_RowID	  int,
			@B_Resultado  bit,
			@T_Message	  nvarchar(4000)
	EXEC USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_28_FechaVencimientoCuotaPorOblID @I_RowID, @B_Resultado output, @T_Message output
	SELECT @B_Resultado as resultado, @T_Message as mensaje
*/
BEGIN
	DECLARE @I_Observados int = 0
	DECLARE @D_FecProceso datetime = GETDATE() 
	DECLARE @I_ObservID int = 28
	DECLARE @I_TablaID int = 5

	BEGIN TRANSACTION
	BEGIN TRY

		SELECT Ano, P, Cod_alu, Cod_rc, obl.Cuota_pago, obl.Fch_venc, Tipo_oblig, Monto, obl.I_RowID
		INTO  #temp_obl_fecVenc_dif_cuota_anio
		FROM  TR_Ec_Obl obl
			  LEFT JOIN TR_Cp_Des cp ON obl.Cuota_pago = cp.Cuota_pago 
										AND obl.I_ProcedenciaID = cp.I_ProcedenciaID
										AND cp.Eliminado = 0
		WHERE obl.I_RowID = @I_RowID
			  AND obl.Fch_venc <> cp.Fch_venc


		UPDATE	TRG_1
		SET		B_Migrable = 0,
				D_FecEvalua = @D_FecProceso
		FROM	TR_Ec_Obl TRG_1
				INNER JOIN #temp_obl_fecVenc_dif_cuota_anio SRC_1 
							ON TRG_1.I_RowID = SRC_1.I_RowID
		WHERE	ISNULL(TRG_1.B_Correcto, 0) = 0


		MERGE TI_ObservacionRegistroTabla AS TRG
		USING (SELECT @I_ObservID AS I_ObservID, @I_TablaID AS I_TablaID, TRG_1.I_RowID AS I_FilaTablaID, 
					  @D_FecProceso AS D_FecRegistro, TRG_1.I_ProcedenciaID, SRC_1.I_RowID
				 FROM TR_Ec_Obl TRG_1
					  LEFT JOIN #temp_obl_fecVenc_dif_cuota_anio SRC_1 
								 ON TRG_1.I_RowID = SRC_1.I_RowID
				WHERE ISNULL(TRG_1.B_Correcto, 0) = 0
					  AND TRG_1.I_RowID = @I_RowID
			  ) AS SRC
		ON TRG.I_ObservID = SRC.I_ObservID AND TRG.I_TablaID = SRC.I_TablaID AND TRG.I_FilaTablaID = SRC.I_FilaTablaID
		WHEN MATCHED AND SRC.I_RowID IS NOT NULL THEN
			UPDATE SET D_FecRegistro = SRC.D_FecRegistro
		WHEN NOT MATCHED BY TARGET THEN
			INSERT (I_ObservID, I_TablaID, I_FilaTablaID, D_FecRegistro, I_ProcedenciaID)
			VALUES (SRC.I_ObservID, SRC.I_TablaID, SRC.I_FilaTablaID, SRC.D_FecRegistro, SRC.I_ProcedenciaID);


		UPDATE OBS
		   SET D_FecResuelto = @D_FecProceso,
			   B_Resuelto = 1
		  FROM TI_ObservacionRegistroTabla OBS
			   INNER JOIN (SELECT ec_obl.I_RowID, ec_obl.Ano, ec_obl.Cod_alu, ec_obl.Cod_rc, ec_obl.I_ProcedenciaID 
							 FROM TR_Ec_Obl ec_obl
								  LEFT JOIN #temp_obl_fecVenc_dif_cuota_anio SRC_1 ON ec_obl.I_RowID = SRC_1.I_RowID
							WHERE ec_obl.I_RowID = @I_RowID
								  AND SRC_1.I_RowID IS NULL
						  ) OBL 
						  ON OBS.I_FilaTablaID = OBL.I_RowID
							 AND OBS.I_ProcedenciaID = OBL.I_ProcedenciaID
		 WHERE OBS.I_ObservID = @I_ObservID 
			   AND OBS.I_TablaID = @I_TablaID
			   AND OBS.I_FilaTablaID = @I_RowID

		SET @I_Observados = (SELECT COUNT(*) FROM TI_ObservacionRegistroTabla OBS INNER JOIN 
												  TR_Ec_Obl OBL ON OBS.I_FilaTablaID = OBL.I_RowID 
																	AND OBL.I_ProcedenciaID = OBS.I_ProcedenciaID
																	AND OBS.I_TablaID = @I_TablaID 
							  WHERE I_ObservID = @I_ObservID
									AND B_Resuelto = 0
									AND OBL.I_RowID = @I_RowID)

		SELECT @I_Observados as cant_obs, @D_FecProceso as fec_proceso

		COMMIT TRANSACTION				
		SET @B_Resultado = 1
		SET @T_Message = '{ ' +
							 'Type: "summary", ' + 
							 'Title: "Observados ", ' + 
							 'Value: ' + CAST(@I_Observados AS varchar) +
						 '}' 
	END TRY
	BEGIN CATCH
		IF (@@TRANCOUNT > 0) 
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


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_29_ExisteEnDestino')
	DROP PROCEDURE [dbo].[USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_29_ExisteEnDestino]
GO

CREATE PROCEDURE [dbo].[USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_29_ExisteEnDestino] 
	@I_ProcedenciaID tinyint,
	@T_Anio		  varchar(4),
	@B_Resultado  bit output,
	@T_Message	  nvarchar(4000) OUTPUT	
AS
/*
	DESCRIPCION: Marcar TR_Ec_Obl con B_Migrable = 0 cuando la obligacion ya existe con otro monto en la base de datos de cuentas por cobrar
				 para el año y procedencia

	DECLARE @I_ProcedenciaID	tinyint = 3,
			@T_Anio		  varchar(4) = '2010',
			@B_Resultado  bit,
			@T_Message	  nvarchar(4000)
	EXEC USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_29_ExisteEnDestino @I_ProcedenciaID, @T_Anio, @B_Resultado output, @T_Message output
	SELECT @B_Resultado as resultado, @T_Message as mensaje
*/
BEGIN
	DECLARE @I_Observados int = 0
	DECLARE @D_FecProceso datetime = GETDATE() 
	DECLARE @I_ObservID int = 29
	DECLARE @I_TablaID int = 5

	BEGIN TRANSACTION
	BEGIN TRY 
		
		SELECT Ano, P, obl.I_Periodo, Cod_alu, Cod_rc, obl.Cuota_pago, obl.Fch_venc, Tipo_oblig, Monto, obl.I_RowID, Ctas_obl.I_MontoOblig
		INTO  #temp_obl_Monto_dif_Ctas_anio
		FROM  TR_Ec_Obl obl
				LEFT JOIN (SELECT I_ObligacionAluID, I_ProcesoID, I_MontoOblig, D_FecVencto, M.C_CodAlu, M.C_CodRc, 
								M.I_Anio, M.I_Periodo, C.B_Pagado 
							FROM BD_OCEF_CtasPorCobrar.dbo.TR_ObligacionAluCab C 
								INNER JOIN BD_OCEF_CtasPorCobrar.dbo.TC_MatriculaAlumno M ON C.I_MatAluID = M.I_MatAluID
						  ) Ctas_obl ON obl.Cuota_pago = Ctas_obl.I_ProcesoID
										AND obl.I_Periodo = Ctas_obl.I_Periodo
										AND obl.Ano = CAST(Ctas_obl.I_Anio as varchar(4))
										AND obl.Cod_alu = Ctas_obl.C_CodAlu
										AND obl.Cod_rc = Ctas_obl.C_CodRc
										AND obl.Fch_venc = Ctas_obl.D_FecVencto									 
		WHERE obl.I_ProcedenciaID = @I_ProcedenciaID
			  AND Ctas_obl.I_ObligacionAluID IS NOT NULL
			  AND Ano = @T_Anio 
			  AND ISNULL(B_Correcto, 0) = 0 
			  AND obl.Monto <> ISNULL(Ctas_obl.I_MontoOblig, 0)
		ORDER BY Ano, obl.I_Periodo, Cuota_pago, Cod_rc, Cod_alu 


		UPDATE	TRG_1
		SET		B_Migrable = 0,
				D_FecEvalua = @D_FecProceso
		FROM	TR_Ec_Obl TRG_1
				INNER JOIN #temp_obl_Monto_dif_Ctas_anio SRC_1 
				ON TRG_1.I_RowID = SRC_1.I_RowID
		WHERE	TRG_1.Ano = @T_Anio
				AND ISNULL(TRG_1.B_Correcto, 0) = 0 

					
		MERGE TI_ObservacionRegistroTabla AS TRG
		USING (SELECT @I_ObservID AS I_ObservID, @I_TablaID AS I_TablaID, TRG_1.I_RowID AS I_FilaTablaID, @D_FecProceso AS D_FecRegistro 
				 FROM TR_Ec_Obl TRG_1
					  INNER JOIN #temp_obl_Monto_dif_Ctas_anio SRC_1 ON TRG_1.I_RowID = SRC_1.I_RowID
				WHERE TRG_1.Ano = @T_Anio
					  AND ISNULL(TRG_1.B_Correcto, 0) = 0 
			  ) AS SRC
		ON TRG.I_ObservID = SRC.I_ObservID AND TRG.I_TablaID = SRC.I_TablaID AND TRG.I_FilaTablaID = SRC.I_FilaTablaID
		WHEN MATCHED THEN
			UPDATE SET D_FecRegistro = SRC.D_FecRegistro
		WHEN NOT MATCHED BY TARGET THEN
			INSERT (I_ObservID, I_TablaID, I_FilaTablaID, D_FecRegistro, I_ProcedenciaID)
			VALUES (SRC.I_ObservID, SRC.I_TablaID, SRC.I_FilaTablaID, SRC.D_FecRegistro, @I_ProcedenciaID);


		UPDATE OBS
		   SET D_FecResuelto = @D_FecProceso,
			   B_Resuelto = 1
		  FROM TI_ObservacionRegistroTabla OBS
			   INNER JOIN (SELECT TRG_1.Ano, TRG_1.P, TRG_1.I_Periodo, TRG_1.Cod_alu, TRG_1.Cod_rc, TRG_1.Cuota_pago, TRG_1.Fch_venc, 
								  TRG_1.Tipo_oblig, TRG_1.Monto, TRG_1.I_RowID, TRG_1.I_ProcedenciaID 
							 FROM TR_Ec_Obl TRG_1
								  LEFT JOIN #temp_obl_Monto_dif_Ctas_anio SRC_1 ON TRG_1.I_RowID = SRC_1.I_RowID
							WHERE TRG_1.Ano = @T_Anio
								  AND SRC_1.I_RowID IS NULL
								  AND ISNULL(TRG_1.B_Correcto, 0) = 0 
						  ) OBL 
						  ON OBS.I_FilaTablaID = OBL.I_RowID
							 AND OBS.I_ProcedenciaID = OBL.I_ProcedenciaID
		 WHERE OBS.I_ObservID = @I_ObservID 
			   AND OBS.I_TablaID = @I_TablaID


		SET @I_Observados = (SELECT COUNT(*) FROM TI_ObservacionRegistroTabla OBS INNER JOIN 
												  TR_Ec_Obl OBL ON OBS.I_FilaTablaID = OBL.I_RowID 
																	AND OBL.I_ProcedenciaID = OBS.I_ProcedenciaID
																	AND OBS.I_TablaID = @I_TablaID 
							  WHERE OBS.I_ObservID = @I_ObservID AND
									OBL.Ano = @T_Anio AND
									OBS.B_Resuelto = 0 AND
									OBS.I_ProcedenciaID = @I_ProcedenciaID)

		SELECT @I_Observados as cant_obs, @D_FecProceso as fec_proceso


		COMMIT TRANSACTION				
		SET @B_Resultado = 1
		SET @T_Message = '{ ' +
							 'Type: "summary", ' + 
							 'Title: "Observados", ' + 
							 'Value: ' + CAST(@I_Observados AS varchar)  +
						  '}' 
	END TRY
	BEGIN CATCH
		IF (@@TRANCOUNT > 0)
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


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_29_ExisteEnDestinoPorOblID')
	DROP PROCEDURE [dbo].[USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_29_ExisteEnDestinoPorOblID]
GO

CREATE PROCEDURE [dbo].[USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_29_ExisteEnDestinoPorOblID]	
	@I_RowID	  int = NULL,
	@B_Resultado  bit output,
	@T_Message	  nvarchar(4000) OUTPUT	
AS
/*
	DESCRIPCION: Marcar TR_Ec_Obl con B_Migrable = 0 cuando la obligacion ya existe con otro monto en la base de datos de cuentas por cobrar
				 para el I_RowID de la obligacion

	DECLARE @I_RowID	  int = NULL,
			@B_Resultado  bit,
			@T_Message	  nvarchar(4000)
	EXEC USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_29_ExisteEnDestinoPorOblID @I_ProcedenciaID, @I_RowID, @B_Resultado output, @T_Message output
	SELECT @B_Resultado as resultado, @T_Message as mensaje
*/
BEGIN
	DECLARE @I_Observados int = 0
	DECLARE @D_FecProceso datetime = GETDATE() 
	DECLARE @I_ObservID int = 29
	DECLARE @I_TablaID int = 5

	BEGIN TRANSACTION
	BEGIN TRY 
		
		SELECT Ano, P, obl.I_Periodo, Cod_alu, Cod_rc, obl.Cuota_pago, obl.Fch_venc, Tipo_oblig, Monto, obl.I_RowID, Ctas_obl.I_MontoOblig
		INTO  #temp_obl_Monto_dif_CtasObl
		FROM  TR_Ec_Obl obl
				LEFT JOIN (SELECT I_ObligacionAluID, I_ProcesoID, I_MontoOblig, D_FecVencto, M.C_CodAlu, M.C_CodRc, 
								M.I_Anio, M.I_Periodo, C.B_Pagado 
							FROM BD_OCEF_CtasPorCobrar.dbo.TR_ObligacionAluCab C 
								INNER JOIN BD_OCEF_CtasPorCobrar.dbo.TC_MatriculaAlumno M ON C.I_MatAluID = M.I_MatAluID
						  ) Ctas_obl ON obl.Cuota_pago = Ctas_obl.I_ProcesoID
										AND obl.I_Periodo = Ctas_obl.I_Periodo
										AND obl.Ano = CAST(Ctas_obl.I_Anio as varchar(4))
										AND obl.Cod_alu = Ctas_obl.C_CodAlu
										AND obl.Cod_rc = Ctas_obl.C_CodRc
										AND obl.Fch_venc = Ctas_obl.D_FecVencto									 
		WHERE Ctas_obl.I_ObligacionAluID IS NOT NULL
			  AND obl.I_RowID = @I_RowID 
			  AND ISNULL(obl.B_Correcto, 0) = 0 
			  AND obl.Monto <> ISNULL(Ctas_obl.I_MontoOblig, 0)
		ORDER BY obl.Ano, obl.I_Periodo, obl.Cuota_pago, obl.Cod_rc, obl.Cod_alu 


		UPDATE	TRG_1
		SET		B_Migrable = 0,
				D_FecEvalua = @D_FecProceso
		FROM	TR_Ec_Obl TRG_1
				INNER JOIN #temp_obl_Monto_dif_CtasObl SRC_1 
				ON TRG_1.I_RowID = SRC_1.I_RowID
		WHERE	TRG_1.I_RowID = @I_RowID
				AND ISNULL(TRG_1.B_Correcto, 0) = 0 

					
		MERGE TI_ObservacionRegistroTabla AS TRG
		USING (SELECT @I_ObservID AS I_ObservID, @I_TablaID AS I_TablaID, TRG_1.I_RowID AS I_FilaTablaID, 
					  @D_FecProceso AS D_FecRegistro, TRG_1.I_ProcedenciaID
				 FROM TR_Ec_Obl TRG_1
					  LEFT JOIN #temp_obl_Monto_dif_CtasObl SRC_1 ON TRG_1.I_RowID = SRC_1.I_RowID
				WHERE TRG_1.I_RowID = @I_RowID
					  AND ISNULL(TRG_1.B_Correcto, 0) = 0 
			  ) AS SRC
		ON TRG.I_ObservID = SRC.I_ObservID AND TRG.I_TablaID = SRC.I_TablaID AND TRG.I_FilaTablaID = SRC.I_FilaTablaID
		WHEN MATCHED THEN
			UPDATE SET D_FecRegistro = SRC.D_FecRegistro
		WHEN NOT MATCHED BY TARGET THEN
			INSERT (I_ObservID, I_TablaID, I_FilaTablaID, D_FecRegistro, I_ProcedenciaID)
			VALUES (SRC.I_ObservID, SRC.I_TablaID, SRC.I_FilaTablaID, SRC.D_FecRegistro, SRC.I_ProcedenciaID);


		UPDATE OBS
		   SET D_FecResuelto = @D_FecProceso,
			   B_Resuelto = 1
		  FROM TI_ObservacionRegistroTabla OBS
			   INNER JOIN (SELECT  TRG_1.Ano, TRG_1.P, TRG_1.I_Periodo, TRG_1.Cod_alu, TRG_1.Cod_rc, TRG_1.Cuota_pago, TRG_1.Fch_venc, 
								   TRG_1.Tipo_oblig, TRG_1.Monto, TRG_1.I_RowID, TRG_1.I_ProcedenciaID
							 FROM TR_Ec_Obl TRG_1
								  LEFT JOIN #temp_obl_Monto_dif_CtasObl SRC_1 ON TRG_1.I_RowID = SRC_1.I_RowID
							WHERE TRG_1.I_RowID = @I_RowID
								  AND SRC_1.I_RowID IS NULL
								  AND ISNULL(TRG_1.B_Correcto, 0) = 0 
						  ) OBL 
						  ON OBS.I_FilaTablaID = OBL.I_RowID
							 AND OBS.I_ProcedenciaID = OBL.I_ProcedenciaID
		 WHERE OBS.I_ObservID = @I_ObservID 
			   AND OBS.I_TablaID = @I_TablaID
			   AND OBS.I_FilaTablaID = @I_RowID


		SET @I_Observados = (SELECT COUNT(*) FROM TI_ObservacionRegistroTabla OBS INNER JOIN 
												  TR_Ec_Obl OBL ON OBS.I_FilaTablaID = OBL.I_RowID 
																	AND OBL.I_ProcedenciaID = OBS.I_ProcedenciaID
																	AND OBS.I_TablaID = @I_TablaID 
							  WHERE OBS.I_ObservID = @I_ObservID AND
									OBS.B_Resuelto = 0 AND
									OBS.I_FilaTablaID = @I_RowID)

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


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_U_ValidarObligacionCuotaPagoMigrada')
	DROP PROCEDURE [dbo].[USP_U_ValidarObligacionCuotaPagoMigrada]
GO

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_32_ValidarObligacionCuotaPagoMigrada')
	DROP PROCEDURE [dbo].[USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_32_ValidarObligacionCuotaPagoMigrada]
GO

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_32_ObligacionCuotaPagoMigrada')
	DROP PROCEDURE [dbo].[USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_32_ObligacionCuotaPagoMigrada]
GO

CREATE PROCEDURE [dbo].[USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_32_ObligacionCuotaPagoMigrada]	
	@I_ProcedenciaID tinyint,
	@T_Anio			 varchar(4) = NULL,
	@B_Resultado  bit output,
	@T_Message	  nvarchar(4000) OUTPUT	
AS
/*
	DESCRIPCION: Marcar TR_Ec_Obl con B_Migrable = 0 cuando la cuota de pago de la obligacion para la procedencia y año no ha sido migrada, o no se encuentra en la base de datos de ctas x cobrar

	DECLARE	@I_ProcedenciaID	tinyint = 1, 
			@T_Anio				varchar(4) = 2010,
			@B_Resultado		bit,
			@T_Message			nvarchar(4000)
	EXEC USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_32_ObligacionCuotaPagoMigrada @I_ProcedenciaID, @T_Anio, @B_Resultado output, @T_Message output
	SELECT @B_Resultado as resultado, @T_Message as mensaje
*/
BEGIN
	DECLARE @I_Observados int = 0
	DECLARE @D_FecProceso datetime = GETDATE() 
	DECLARE @I_ObservID int = 32
	DECLARE @I_TablaID int = 5

	BEGIN TRANSACTION
	BEGIN TRY

		SELECT Ano, P, Cod_alu, Cod_rc, obl.Cuota_pago, obl.Fch_venc, Tipo_oblig, Monto, obl.I_RowID
		INTO  #temp_obl_cuota_no_migrada
		FROM  TR_Ec_Obl obl
			  LEFT JOIN TR_Cp_Des cp ON obl.Cuota_pago = cp.Cuota_pago 
										AND cp.B_ExisteCtas = 1
		WHERE cp.I_ProcedenciaID = @I_ProcedenciaID
			  AND obl.Ano = @T_Anio
			  AND cp.I_RowID is null


		UPDATE	OBL
		SET		B_Migrable = 0,
				D_FecEvalua = @D_FecProceso
		 FROM	TR_Ec_Obl OBL
				INNER JOIN #temp_obl_cuota_no_migrada TMP ON OBL.I_RowID = TMP.I_RowID
		WHERE	I_ProcedenciaID = @I_ProcedenciaID
				AND OBL.Ano = @T_Anio


		MERGE TI_ObservacionRegistroTabla AS TRG
		USING 	(SELECT	@I_ObservID AS I_ObservID, @I_TablaID AS I_TablaID, OBL.I_RowID AS I_FilaTablaID, @D_FecProceso AS D_FecRegistro 
				   FROM	TR_Ec_Obl OBL
						INNER JOIN #temp_obl_cuota_no_migrada TMP ON OBL.I_RowID = TMP.I_RowID
				  WHERE	OBL.I_ProcedenciaID = @I_ProcedenciaID
						AND OBL.Ano = @T_Anio
				) AS SRC
		ON TRG.I_ObservID = SRC.I_ObservID AND TRG.I_TablaID = SRC.I_TablaID AND TRG.I_FilaTablaID = SRC.I_FilaTablaID
		WHEN MATCHED THEN
			UPDATE SET D_FecRegistro = SRC.D_FecRegistro
		WHEN NOT MATCHED BY TARGET THEN
			INSERT (I_ObservID, I_TablaID, I_FilaTablaID, D_FecRegistro, I_ProcedenciaID)
			VALUES (SRC.I_ObservID, SRC.I_TablaID, SRC.I_FilaTablaID, SRC.D_FecRegistro, @I_ProcedenciaID);


		UPDATE OBS
		   SET D_FecResuelto = @D_FecProceso,
			   B_Resuelto = 1
		  FROM TI_ObservacionRegistroTabla OBS
			   INNER JOIN (SELECT  TRG_1.Ano, TRG_1.P, TRG_1.I_Periodo, TRG_1.Cod_alu, TRG_1.Cod_rc, TRG_1.Cuota_pago, TRG_1.Fch_venc, 
								   TRG_1.Tipo_oblig, TRG_1.Monto, TRG_1.I_RowID, TRG_1.I_ProcedenciaID
							 FROM TR_Ec_Obl TRG_1
								  LEFT JOIN #temp_obl_cuota_no_migrada SRC_1 ON TRG_1.I_RowID = SRC_1.I_RowID
							WHERE TRG_1.Ano = @T_Anio
								  AND TRG_1.I_ProcedenciaID	= @I_ProcedenciaID
								  AND SRC_1.I_RowID IS NULL
								  AND ISNULL(TRG_1.B_Correcto, 0) = 0 
						  ) OBL 
						  ON OBS.I_FilaTablaID = OBL.I_RowID
							 AND OBS.I_ProcedenciaID = OBL.I_ProcedenciaID
		 WHERE OBS.I_ObservID = @I_ObservID 
			   AND OBS.I_TablaID = @I_TablaID

		SET @I_Observados = (SELECT COUNT(*) FROM TI_ObservacionRegistroTabla OBS INNER JOIN 
												  TR_Ec_Obl OBL ON OBS.I_FilaTablaID = OBL.I_RowID 
																	AND OBL.I_ProcedenciaID = OBS.I_ProcedenciaID
																	AND OBS.I_TablaID = @I_TablaID 
							  WHERE OBS.I_ObservID = @I_ObservID AND
									OBS.B_Resuelto = 0 AND
									OBL.Ano = @T_Anio AND
									OBL.I_ProcedenciaID = @I_ProcedenciaID)

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


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_32_ObligacionCuotaPagoMigradaPorOblID')
	DROP PROCEDURE [dbo].[USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_32_ObligacionCuotaPagoMigradaPorOblID]
GO

CREATE PROCEDURE [dbo].[USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_32_ObligacionCuotaPagoMigradaPorOblID]	
	@I_RowID	  int,
	@B_Resultado  bit OUTPUT,
	@T_Message	  nvarchar(4000) OUTPUT	
AS
/*
	DESCRIPCION: Marcar TR_Ec_Obl con B_Migrable = 0 cuando la cuota de pago de la oblID no ha sido migrada, o no se encuentra en la base de datos de ctas x cobrar

	DECLARE	@I_RowID	  int,
			@B_Resultado  bit,
			@T_Message	  nvarchar(4000)
	EXEC USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_32_ObligacionCuotaPagoMigradaPorOblID @I_RowID, @B_Resultado output, @T_Message output
	SELECT @B_Resultado as resultado, @T_Message as mensaje
*/
BEGIN
	DECLARE @I_Observados int = 0
	DECLARE @D_FecProceso datetime = GETDATE() 
	DECLARE @I_ObservID int = 32
	DECLARE @I_TablaID int = 5

	BEGIN TRANSACTION
	BEGIN TRY

		SELECT Ano, P, Cod_alu, Cod_rc, obl.Cuota_pago, obl.Fch_venc, Tipo_oblig, Monto, obl.I_RowID
		INTO  #temp_obl_cuota_no_migrada
		FROM  TR_Ec_Obl obl
			  LEFT JOIN TR_Cp_Des cp ON obl.Cuota_pago = cp.Cuota_pago 
										AND cp.B_ExisteCtas = 1
		WHERE cp.I_RowID is null


		UPDATE	OBL
		SET		B_Migrable = 0,
				D_FecEvalua = @D_FecProceso
		 FROM	TR_Ec_Obl OBL
				INNER JOIN #temp_obl_cuota_no_migrada TMP ON OBL.I_RowID = TMP.I_RowID
		WHERE	OBL.I_RowID = @I_RowID


		MERGE TI_ObservacionRegistroTabla AS TRG
		USING 	(SELECT	@I_ObservID AS I_ObservID, @I_TablaID AS I_TablaID, OBL.I_RowID AS I_FilaTablaID, 
						@D_FecProceso AS D_FecRegistro, I_ProcedenciaID 
				   FROM	TR_Ec_Obl OBL
						INNER JOIN #temp_obl_cuota_no_migrada TMP ON OBL.I_RowID = TMP.I_RowID
				  WHERE	OBL.I_RowID = @I_RowID
				) AS SRC
		ON TRG.I_ObservID = SRC.I_ObservID AND TRG.I_TablaID = SRC.I_TablaID AND TRG.I_FilaTablaID = SRC.I_FilaTablaID
		WHEN MATCHED THEN
			UPDATE SET D_FecRegistro = SRC.D_FecRegistro
		WHEN NOT MATCHED BY TARGET THEN
			INSERT (I_ObservID, I_TablaID, I_FilaTablaID, D_FecRegistro, I_ProcedenciaID)
			VALUES (SRC.I_ObservID, SRC.I_TablaID, SRC.I_FilaTablaID, SRC.D_FecRegistro, SRC.I_ProcedenciaID);


		UPDATE OBS
		   SET D_FecResuelto = @D_FecProceso,
			   B_Resuelto = 1
		  FROM TI_ObservacionRegistroTabla OBS
			   INNER JOIN (SELECT  TRG_1.Ano, TRG_1.P, TRG_1.I_Periodo, TRG_1.Cod_alu, TRG_1.Cod_rc, TRG_1.Cuota_pago, TRG_1.Fch_venc, 
								   TRG_1.Tipo_oblig, TRG_1.Monto, TRG_1.I_RowID, TRG_1.I_ProcedenciaID
							 FROM TR_Ec_Obl TRG_1
								  LEFT JOIN #temp_obl_cuota_no_migrada SRC_1 ON TRG_1.I_RowID = SRC_1.I_RowID
							WHERE TRG_1.I_RowID = @I_RowID 
								  AND SRC_1.I_RowID IS NULL
								  AND ISNULL(TRG_1.B_Correcto, 0) = 0 
						  ) OBL 
						  ON OBS.I_FilaTablaID = OBL.I_RowID
							 AND OBS.I_ProcedenciaID = OBL.I_ProcedenciaID
		 WHERE OBS.I_ObservID = @I_ObservID 
			   AND OBS.I_TablaID = @I_TablaID

		SET @I_Observados = (SELECT COUNT(*) FROM TI_ObservacionRegistroTabla OBS INNER JOIN 
												  TR_Ec_Obl OBL ON OBS.I_FilaTablaID = OBL.I_RowID 
																	AND OBL.I_ProcedenciaID = OBS.I_ProcedenciaID
																	AND OBS.I_TablaID = @I_TablaID 
							  WHERE OBS.I_ObservID = @I_ObservID AND
									OBS.B_Resuelto = 0 AND
									OBL.I_RowID = @I_RowID)

		SELECT @I_Observados as cant_obs, @D_FecProceso as fec_proceso		


		COMMIT TRANSACTION				
		SET @B_Resultado = 1
		SET @T_Message = '{ ' +
							 'Type: "summary", ' + 
							 'Title: "Observados ", ' + 
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



IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_U_ValidarProcedenciaObligacionCuotaPago')
	DROP PROCEDURE [dbo].[USP_U_ValidarProcedenciaObligacionCuotaPago]
GO

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_34_ProcedenciaCuotaPago')
	DROP PROCEDURE [dbo].[USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_34_ProcedenciaCuotaPago]
GO

CREATE PROCEDURE [dbo].[USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_34_ProcedenciaCuotaPago]	
	@I_ProcedenciaID tinyint,
	@T_Anio			 varchar(4) = NULL,
	@B_Resultado  bit output,
	@T_Message	  nvarchar(4000) OUTPUT	
AS
/*
	DESCRIPCION: Marcar TR_Ec_Obl con B_Migrable = 0 cuando la procedencia de la obligación no coincide con la procedencia de la cuota de pago migrada 
						o en la base de datos de ctas x cobrar para el año y procedencia

	DECLARE	@I_ProcedenciaID	tinyint = 2, 
			@T_Anio				varchar(4) = 2016,
			@B_Resultado		bit,
			@T_Message			nvarchar(4000)
	EXEC USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_34_ProcedenciaCuotaPago @I_ProcedenciaID, @T_Anio, @B_Resultado output, @T_Message output
	SELECT @B_Resultado as resultado, @T_Message as mensaje
*/
BEGIN
	DECLARE @I_Observados int = 0
	DECLARE @D_FecProceso datetime = GETDATE() 
	DECLARE @I_ObservID int = 34
	DECLARE @I_TablaID int = 5

	BEGIN TRANSACTION
	BEGIN TRY
		
		SELECT Ano, P, Cod_alu, Cod_rc, obl.Cuota_pago, obl.Fch_venc, Tipo_oblig, Monto, obl.I_RowID
		  INTO #temp_obl_procedencia_dif_cuota_anio
		  FROM TR_Ec_Obl obl
		 	   LEFT JOIN TR_Cp_Des cp ON obl.Cuota_pago = cp.Cuota_pago 
										AND obl.I_ProcedenciaID = cp.I_ProcedenciaID
										AND cp.Eliminado = 0
										AND B_ExisteCtas = 1
		 WHERE obl.I_ProcedenciaID = @I_ProcedenciaID
		 	   AND Ano = @T_Anio 
		 	   AND cp.I_RowID is null


		UPDATE	OBL
		SET		B_Migrable = 0,
				D_FecEvalua = @D_FecProceso
		FROM	TR_Ec_Obl OBL 
				INNER JOIN #temp_obl_procedencia_dif_cuota_anio TMP ON OBL.I_RowID = TMP.I_RowID
		WHERE	I_ProcedenciaID = @I_ProcedenciaID
				AND OBL.Ano = @T_Anio 


		MERGE TI_ObservacionRegistroTabla AS TRG
		USING (SELECT @I_ObservID AS I_ObservID, @I_TablaID AS I_TablaID, OBL.I_RowID AS I_FilaTablaID, @D_FecProceso AS D_FecRegistro 
			     FROM TR_Ec_Obl OBL 
					  INNER JOIN #temp_obl_procedencia_dif_cuota_anio TMP ON OBL.I_RowID = TMP.I_RowID
				WHERE I_ProcedenciaID = @I_ProcedenciaID
					  AND OBL.Ano = @T_Anio 
			  ) AS SRC
		ON TRG.I_ObservID = SRC.I_ObservID AND TRG.I_TablaID = SRC.I_TablaID AND TRG.I_FilaTablaID = SRC.I_FilaTablaID
		WHEN MATCHED THEN
			UPDATE SET D_FecRegistro = SRC.D_FecRegistro
		WHEN NOT MATCHED BY TARGET THEN
			INSERT (I_ObservID, I_TablaID, I_FilaTablaID, D_FecRegistro, I_ProcedenciaID)
			VALUES (SRC.I_ObservID, SRC.I_TablaID, SRC.I_FilaTablaID, SRC.D_FecRegistro, @I_ProcedenciaID);


		UPDATE OBS
		   SET D_FecResuelto = @D_FecProceso,
			   B_Resuelto = 1
		  FROM TI_ObservacionRegistroTabla OBS
			   INNER JOIN (SELECT  TRG_1.Ano, TRG_1.P, TRG_1.I_Periodo, TRG_1.Cod_alu, TRG_1.Cod_rc, TRG_1.Cuota_pago, TRG_1.Fch_venc, 
								   TRG_1.Tipo_oblig, TRG_1.Monto, TRG_1.I_RowID, TRG_1.I_ProcedenciaID
							 FROM TR_Ec_Obl TRG_1
								  LEFT JOIN #temp_obl_procedencia_dif_cuota_anio SRC_1 ON TRG_1.I_RowID = SRC_1.I_RowID
							WHERE TRG_1.I_ProcedenciaID = @I_ProcedenciaID
								  AND TRG_1.Ano = @T_Anio
								  AND SRC_1.I_RowID IS NULL
								  AND ISNULL(TRG_1.B_Correcto, 0) = 0 
						  ) OBL 
						  ON OBS.I_FilaTablaID = OBL.I_RowID
							 AND OBS.I_ProcedenciaID = OBL.I_ProcedenciaID
		 WHERE OBS.I_ObservID = @I_ObservID 
			   AND OBS.I_TablaID = @I_TablaID


		SET @I_Observados = (SELECT COUNT(*) 
							   FROM TI_ObservacionRegistroTabla OBS 
									INNER JOIN TR_Ec_Obl OBL ON OBS.I_FilaTablaID = OBL.I_RowID 
																AND OBL.I_ProcedenciaID = OBS.I_ProcedenciaID
																AND OBS.I_TablaID = @I_TablaID
							  WHERE OBS.I_ObservID = @I_ObservID AND
									OBS.I_ProcedenciaID = @I_ProcedenciaID AND 
									OBL.Ano = @T_Anio AND 
									OBS.B_Resuelto = 0)

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
							 'Value: "' + ERROR_MESSAGE() + ' (Linea: ' + CAST(ERROR_LINE() AS varchar(10)) + ')."'  +
						  '}]' 
	END CATCH
END
GO


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_34_ProcedenciaCuotaPagoPorOblID')
	DROP PROCEDURE [dbo].[USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_34_ProcedenciaCuotaPagoPorOblID]
GO

CREATE PROCEDURE [dbo].[USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_34_ProcedenciaCuotaPagoPorOblID]	
	@I_RowID	  int,
	@B_Resultado  bit OUTPUT,
	@T_Message	  nvarchar(4000) OUTPUT	
AS
/*
	DESCRIPCION: Marcar TR_Ec_Obl con B_Migrable = 0 cuando la procedencia de la obligación no coincide con la procedencia de la cuota de pago migrada 
				 o en la base de datos de ctas x cobrar para el Id de la obligacion

	DECLARE	@I_RowID	  int,
			@B_Resultado  bit,
			@T_Message	  nvarchar(4000)
	EXEC USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_34_ProcedenciaCuotaPagoPorOblID @I_RowID, @B_Resultado output, @T_Message output
	SELECT @B_Resultado as resultado, @T_Message as mensaje
*/
BEGIN
	DECLARE @I_Observados int = 0
	DECLARE @D_FecProceso datetime = GETDATE() 
	DECLARE @I_ObservID int = 34
	DECLARE @I_TablaID int = 5

	BEGIN TRANSACTION
	BEGIN TRY
		
		SELECT Ano, P, Cod_alu, Cod_rc, obl.Cuota_pago, obl.Fch_venc, Tipo_oblig, Monto, obl.I_RowID
		  INTO #temp_obl_procedencia_dif_cuota
		  FROM TR_Ec_Obl obl
		 	   LEFT JOIN TR_Cp_Des cp ON obl.Cuota_pago = cp.Cuota_pago 
										AND obl.I_ProcedenciaID = cp.I_ProcedenciaID
										AND cp.Eliminado = 0
										AND B_ExisteCtas = 1
		 WHERE cp.I_RowID is null


		UPDATE	OBL
		SET		B_Migrable = 0,
				D_FecEvalua = @D_FecProceso
		FROM	TR_Ec_Obl OBL 
				INNER JOIN #temp_obl_procedencia_dif_cuota TMP ON OBL.I_RowID = TMP.I_RowID
		WHERE	OBL.I_RowID = @I_RowID


		MERGE TI_ObservacionRegistroTabla AS TRG
		USING (SELECT @I_ObservID AS I_ObservID, @I_TablaID AS I_TablaID, OBL.I_RowID AS I_FilaTablaID, 
					  @D_FecProceso AS D_FecRegistro, I_ProcedenciaID
			     FROM TR_Ec_Obl OBL 
					  INNER JOIN #temp_obl_procedencia_dif_cuota TMP ON OBL.I_RowID = TMP.I_RowID
				WHERE OBL.I_RowID = @I_RowID
			  ) AS SRC
		ON TRG.I_ObservID = SRC.I_ObservID AND TRG.I_TablaID = SRC.I_TablaID AND TRG.I_FilaTablaID = SRC.I_FilaTablaID
		WHEN MATCHED THEN
			UPDATE SET D_FecRegistro = SRC.D_FecRegistro
		WHEN NOT MATCHED BY TARGET THEN
			INSERT (I_ObservID, I_TablaID, I_FilaTablaID, D_FecRegistro, I_ProcedenciaID)
			VALUES (SRC.I_ObservID, SRC.I_TablaID, SRC.I_FilaTablaID, SRC.D_FecRegistro, SRC.I_ProcedenciaID);


		UPDATE OBS
		   SET D_FecResuelto = @D_FecProceso,
			   B_Resuelto = 1
		  FROM TI_ObservacionRegistroTabla OBS
			   INNER JOIN (SELECT  TRG_1.Ano, TRG_1.P, TRG_1.I_Periodo, TRG_1.Cod_alu, TRG_1.Cod_rc, TRG_1.Cuota_pago, TRG_1.Fch_venc, 
								   TRG_1.Tipo_oblig, TRG_1.Monto, TRG_1.I_RowID, TRG_1.I_ProcedenciaID
							 FROM TR_Ec_Obl TRG_1
								  LEFT JOIN #temp_obl_procedencia_dif_cuota SRC_1 ON TRG_1.I_RowID = SRC_1.I_RowID
							WHERE TRG_1.I_RowID = @I_RowID
								  AND SRC_1.I_RowID IS NULL
								  AND ISNULL(TRG_1.B_Correcto, 0) = 0 
						  ) OBL 
						  ON OBS.I_FilaTablaID = OBL.I_RowID
							 AND OBS.I_ProcedenciaID = OBL.I_ProcedenciaID
		 WHERE OBS.I_ObservID = @I_ObservID 
			   AND OBS.I_TablaID = @I_TablaID
			   AND OBS.I_FilaTablaID = @I_RowID


		SET @I_Observados = (SELECT COUNT(*) 
							   FROM TI_ObservacionRegistroTabla OBS 
									INNER JOIN TR_Ec_Obl OBL ON OBS.I_FilaTablaID = OBL.I_RowID 
																AND OBL.I_ProcedenciaID = OBS.I_ProcedenciaID
																AND OBS.I_TablaID = @I_TablaID 
							  WHERE I_ObservID = @I_ObservID AND
									OBS.I_FilaTablaID = @I_RowID AND 
									OBS.B_Resuelto = 0)

		SELECT @I_Observados as cant_obs, @D_FecProceso as fec_proceso


		COMMIT TRANSACTION				
		SET @B_Resultado = 1
		SET @T_Message = '{ ' +
							 'Type: "summary", ' + 
							 'Title: "Observados ", ' + 
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


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_36_ConceptoPagoMigrado')
	DROP PROCEDURE [dbo].[USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_36_ConceptoPagoMigrado]
GO

CREATE PROCEDURE [dbo].[USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_36_ConceptoPagoMigrado]	
	@I_ProcedenciaID tinyint,
	@T_Anio		  varchar(4),
	@B_Resultado  bit output,
	@T_Message	  nvarchar(4000) OUTPUT	
AS
/*
	DESCRIPCION: Marcar TR_Ec_Obl con B_Migrable = 0 cuando la obligacion tiene conceptos que no estan migrados o no son migrables para el año y procedencia

	DECLARE @I_ProcedenciaID	tinyint = 2, 
	    	@T_Anio				varchar(4) = '2008',
			@B_Resultado		bit,
			@T_Message			nvarchar(4000)
	EXEC USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_36_ConceptoPagoMigrado @I_ProcedenciaID, @T_Anio, @B_Resultado output, @T_Message output
	SELECT @B_Resultado as resultado, @T_Message as mensaje
*/
BEGIN
	DECLARE @I_Observados int = 0
	DECLARE @D_FecProceso datetime = GETDATE() 
	DECLARE @I_ObservID int = 36
	DECLARE @I_ObservDetID int = 35
	DECLARE @I_TablaDetID int = 4
	DECLARE @I_TablaID int = 5

	BEGIN TRANSACTION
	BEGIN TRY

		SELECT Obl.*
		  INTO #temp_observados_detalle_concepto_sin_migrar
		  FROM TR_Ec_Obl Obl
			   INNER JOIN TR_Ec_Det Det ON Obl.I_RowID = Det.I_OblRowID
			   INNER JOIN TI_ObservacionRegistroTabla OBS ON OBS.I_FilaTablaID = Det.I_RowID AND 
						  									 OBS.I_ProcedenciaID = Det.I_ProcedenciaID 
		 WHERE OBS.I_ObservID = @I_ObservDetID 
			   AND OBS.I_TablaID = @I_TablaDetID
			   AND OBS.B_Resuelto = 0
			   AND Obl.I_ProcedenciaID = @I_ProcedenciaID
			   AND Obl.Ano = @T_Anio 										  


		UPDATE	Obl
		   SET	B_Migrable = 0,
				D_FecEvalua = @D_FecProceso
		  FROM  TR_Ec_Obl Obl
				INNER JOIN #temp_observados_detalle_concepto_sin_migrar tmp ON Obl.I_RowID = tmp.I_RowID
		 WHERE	ISNULL(Obl.B_Correcto, 0) = 0


		MERGE TI_ObservacionRegistroTabla AS TRG
		USING (SELECT	DISTINCT @I_ObservID AS I_ObservID, @I_TablaID AS I_TablaID, Obl.I_RowID AS I_FilaTablaID, @D_FecProceso AS D_FecRegistro 
				 FROM	TR_Ec_Obl Obl
						INNER JOIN #temp_observados_detalle_concepto_sin_migrar tmp ON Obl.I_RowID = tmp.I_RowID
				WHERE	ISNULL(Obl.B_Correcto, 0) = 0 
			  ) AS SRC
		ON TRG.I_ObservID = SRC.I_ObservID AND TRG.I_TablaID = SRC.I_TablaID AND TRG.I_FilaTablaID = SRC.I_FilaTablaID
		WHEN MATCHED AND TRG.I_ProcedenciaID = @I_ProcedenciaID THEN
			UPDATE SET D_FecRegistro = SRC.D_FecRegistro
		WHEN NOT MATCHED BY TARGET THEN
			INSERT (I_ObservID, I_TablaID, I_FilaTablaID, D_FecRegistro, I_ProcedenciaID)
			VALUES (SRC.I_ObservID, SRC.I_TablaID, SRC.I_FilaTablaID, SRC.D_FecRegistro, @I_ProcedenciaID);


		UPDATE OBS
		   SET D_FecResuelto = @D_FecProceso,
			   B_Resuelto = 1
		  FROM TI_ObservacionRegistroTabla OBS
			   INNER JOIN (SELECT  TRG_1.Ano, TRG_1.P, TRG_1.I_Periodo, TRG_1.Cod_alu, TRG_1.Cod_rc, TRG_1.Cuota_pago, TRG_1.Fch_venc, 
								   TRG_1.Tipo_oblig, TRG_1.Monto, TRG_1.I_RowID, TRG_1.I_ProcedenciaID
							 FROM TR_Ec_Obl TRG_1
								  LEFT JOIN #temp_observados_detalle_concepto_sin_migrar SRC_1 ON TRG_1.I_RowID = SRC_1.I_RowID
							WHERE TRG_1.I_ProcedenciaID = @I_ProcedenciaID
								  AND TRG_1.Ano = @T_Anio
								  AND SRC_1.I_RowID IS NULL
								  AND ISNULL(TRG_1.B_Correcto, 0) = 0 
						  ) OBL 
						  ON OBS.I_FilaTablaID = OBL.I_RowID
							 AND OBS.I_ProcedenciaID = OBL.I_ProcedenciaID
		 WHERE OBS.I_ObservID = @I_ObservID 
			   AND OBS.I_TablaID = @I_TablaID


		SET @I_Observados = (SELECT COUNT(*) 
							   FROM TI_ObservacionRegistroTabla OBS 
									INNER JOIN TR_Ec_Obl OBL ON OBS.I_FilaTablaID = OBL.I_RowID 
																AND OBL.I_ProcedenciaID = OBS.I_ProcedenciaID
																AND OBS.I_TablaID = @I_TablaID
							  WHERE OBS.I_ObservID = @I_ObservID AND
									OBS.I_ProcedenciaID = @I_ProcedenciaID AND 
									OBL.Ano = @T_Anio AND 
									OBS.B_Resuelto = 0)

		SELECT @I_Observados as cant_obs, @D_FecProceso as fec_proceso

		COMMIT TRANSACTION				
		SET @B_Resultado = 1
		SET @T_Message = '{ ' +
							 'Type: "summary", ' + 
							 'Title: "Obligaciones con concepto no migrado", ' + 
							 'Value: ' + CAST(@I_Observados AS varchar) +
						 '}' 
	END TRY
	BEGIN CATCH
		IF (@@TRANCOUNT > 0)
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



IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_36_ConceptoPagoMigradoPorOblID')
	DROP PROCEDURE [dbo].[USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_36_ConceptoPagoMigradoPorOblID]
GO

CREATE PROCEDURE [dbo].[USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_36_ConceptoPagoMigradoPorOblID]	
	@I_RowID	  int,
	@B_Resultado  bit OUTPUT,
	@T_Message	  nvarchar(4000) OUTPUT	
AS
/*
	DESCRIPCION: Marcar TR_Ec_Obl con B_Migrable = 0 cuando la obligacion tiene conceptos que no estan migrados o no son migrables para el Id de la obligacion

	DECLARE	@I_RowID	  int,
			@B_Resultado  bit,
			@T_Message	  nvarchar(4000)
	EXEC USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_36_ConceptoPagoMigrado @I_RowID, @B_Resultado output, @T_Message output
	SELECT @B_Resultado as resultado, @T_Message as mensaje
*/
BEGIN
	DECLARE @I_Observados int = 0
	DECLARE @D_FecProceso datetime = GETDATE() 
	DECLARE @I_ObservID int = 36
	DECLARE @I_ObservDetID int = 35
	DECLARE @I_TablaDetID int = 4
	DECLARE @I_TablaID int = 5

	BEGIN TRANSACTION
	BEGIN TRY

		SELECT Obl.*
		  INTO #temp_observados_detalle_concepto_sin_migrar
		  FROM TR_Ec_Obl Obl
			   INNER JOIN TR_Ec_Det Det ON Obl.I_RowID = Det.I_OblRowID
			   INNER JOIN TI_ObservacionRegistroTabla OBS ON OBS.I_FilaTablaID = Det.I_RowID AND 
						  									 OBS.I_ProcedenciaID = Det.I_ProcedenciaID 
		 WHERE OBS.I_ObservID = @I_ObservDetID 
			   AND OBS.I_TablaID = @I_TablaDetID
			   AND OBS.B_Resuelto = 0
			   AND Obl.I_RowID = @I_RowID 										  


		UPDATE	Obl
		SET		B_Migrable = 0,
				D_FecEvalua = @D_FecProceso
		FROM    TR_Ec_Obl Obl
				INNER JOIN #temp_observados_detalle_concepto_sin_migrar tmp ON Obl.I_RowID = tmp.I_RowID
		 WHERE	ISNULL(Obl.B_Correcto, 0) = 0
				AND Obl.I_RowID = @I_RowID 


		MERGE TI_ObservacionRegistroTabla AS TRG
		USING (SELECT DISTINCT @I_ObservID AS I_ObservID, @I_TablaID AS I_TablaID, Obl.I_RowID AS I_FilaTablaID, 
					  @D_FecProceso AS D_FecRegistro, Obl.I_ProcedenciaID
				 FROM TR_Ec_Obl Obl
					  INNER JOIN #temp_observados_detalle_concepto_sin_migrar tmp ON Obl.I_RowID = tmp.I_RowID
				WHERE ISNULL(Obl.B_Correcto, 0) = 0 
					  AND Obl.I_RowID = @I_RowID 
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
			   INNER JOIN (SELECT TRG_1.Ano, TRG_1.P, TRG_1.I_Periodo, TRG_1.Cod_alu, TRG_1.Cod_rc, TRG_1.Cuota_pago, TRG_1.Fch_venc, 
								  TRG_1.Tipo_oblig, TRG_1.Monto, TRG_1.I_ProcedenciaID, SRC_1.I_RowID
							 FROM TR_Ec_Obl TRG_1
								  LEFT JOIN #temp_observados_detalle_concepto_sin_migrar SRC_1 ON TRG_1.I_RowID = SRC_1.I_RowID
							WHERE SRC_1.I_RowID IS NULL
								  AND ISNULL(TRG_1.B_Correcto, 0) = 0 
						  ) OBL 
						  ON OBS.I_FilaTablaID = OBL.I_RowID
							 AND OBS.I_ProcedenciaID = OBL.I_ProcedenciaID
		 WHERE OBS.I_ObservID = @I_ObservID 
			   AND OBS.I_TablaID = @I_TablaID
			   AND OBS.I_FilaTablaID = @I_RowID


		SET @I_Observados = (SELECT COUNT(*) 
							   FROM TI_ObservacionRegistroTabla OBS 
									INNER JOIN TR_Ec_Obl OBL ON OBS.I_FilaTablaID = OBL.I_RowID 
																AND OBL.I_ProcedenciaID = OBS.I_ProcedenciaID
							  WHERE OBS.I_ObservID = @I_ObservID 
									AND OBS.I_FilaTablaID = @I_RowID  
									AND OBS.I_TablaID = @I_TablaID 
									AND OBS.B_Resuelto = 0)

		SELECT @I_Observados as cant_obs, @D_FecProceso as fec_proceso

		COMMIT TRANSACTION				
		SET @B_Resultado = 1
		SET @T_Message = '{ ' +
							 'Type: "summary", ' + 
							 'Title: "Observados ", ' + 
							 'Value: ' + CAST(@I_Observados AS varchar) +
						 '}' 
	END TRY
	BEGIN CATCH
		IF (@@TRANCOUNT > 0)
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



IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_37_ObservacionAnioDetalle')
	DROP PROCEDURE [dbo].[USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_37_ObservacionAnioDetalle]
GO

CREATE PROCEDURE [dbo].[USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_37_ObservacionAnioDetalle]	
	@I_ProcedenciaID tinyint,
	@T_Anio		  varchar(4),
	@B_Resultado  bit output,
	@T_Message	  nvarchar(4000) OUTPUT	
AS
/*
	DESCRIPCION: Marcar TR_Ec_Obl con B_Migrable = 0 cuando la obligacion tiene observaciones de año en el detalle o no son migrables para el año y procedencia

	DECLARE @I_ProcedenciaID	tinyint = 2, 
	    	@T_Anio				varchar(4) = '2008',
			@B_Resultado		bit,
			@T_Message			nvarchar(4000)
	EXEC USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_37_ObservacionAnioDetalle @I_ProcedenciaID, @T_Anio, @B_Resultado output, @T_Message output
	SELECT @B_Resultado as resultado, @T_Message as mensaje
*/
BEGIN
	DECLARE @I_Observados int = 0
	DECLARE @D_FecProceso datetime = GETDATE() 
	DECLARE @I_ObservID int = 37,
			@I_ObservID_AnioDes int = 43,
			@I_ObservID_AnioPri int = 15
	
	DECLARE @I_TablaID int = 5,
			@I_TablaDetID int = 4

	BEGIN TRANSACTION
	BEGIN TRY

		SELECT Obl.*
		  INTO #temp_observados_detalle_anio_cuota_concepto
		  FROM TR_Ec_Obl Obl
			   INNER JOIN TR_Ec_Det Det ON Obl.I_RowID = Det.I_OblRowID
			   INNER JOIN TI_ObservacionRegistroTabla OBS ON OBS.I_FilaTablaID = Det.I_RowID AND 
						  									 OBS.I_ProcedenciaID = Det.I_ProcedenciaID 
		 WHERE OBS.I_ObservID IN (@I_ObservID_AnioDes, @I_ObservID_AnioPri)
			   AND OBS.I_TablaID = @I_TablaDetID
			   AND OBS.B_Resuelto = 0										  


		UPDATE	Obl
		SET		B_Migrable = 0,
				D_FecEvalua = @D_FecProceso
		FROM    TR_Ec_Obl Obl
				INNER JOIN #temp_observados_detalle_anio_cuota_concepto tmp ON Obl.I_RowID = tmp.I_RowID
		WHERE	Obl.I_ProcedenciaID = @I_ProcedenciaID
				AND Obl.Ano = @T_Anio


		MERGE TI_ObservacionRegistroTabla AS TRG
		USING (SELECT	DISTINCT @I_ObservID AS I_ObservID, @I_TablaID AS I_TablaID, Obl.I_RowID AS I_FilaTablaID, 
						@D_FecProceso AS D_FecRegistro, Obl.I_ProcedenciaID
				 FROM   TR_Ec_Obl Obl
						INNER JOIN #temp_observados_detalle_anio_cuota_concepto tmp ON Obl.I_RowID = tmp.I_RowID
				WHERE	Obl.I_ProcedenciaID = @I_ProcedenciaID
						AND Obl.Ano = @T_Anio
			  ) AS SRC
		ON TRG.I_ObservID = SRC.I_ObservID AND TRG.I_TablaID = SRC.I_TablaID AND TRG.I_FilaTablaID = SRC.I_FilaTablaID
		WHEN MATCHED AND TRG.I_ProcedenciaID = @I_ProcedenciaID THEN
			UPDATE SET D_FecRegistro = SRC.D_FecRegistro
		WHEN NOT MATCHED BY TARGET THEN
			INSERT (I_ObservID, I_TablaID, I_FilaTablaID, D_FecRegistro, I_ProcedenciaID)
			VALUES (SRC.I_ObservID, SRC.I_TablaID, SRC.I_FilaTablaID, SRC.D_FecRegistro, SRC.I_ProcedenciaID);


		UPDATE OBS
		   SET D_FecResuelto = @D_FecProceso,
			   B_Resuelto = 1
		  FROM TI_ObservacionRegistroTabla OBS
			   INNER JOIN (SELECT TRG_1.Ano, TRG_1.P, TRG_1.I_Periodo, TRG_1.Cod_alu, TRG_1.Cod_rc, TRG_1.Cuota_pago, TRG_1.Fch_venc, 
								  TRG_1.Tipo_oblig, TRG_1.Monto, TRG_1.I_ProcedenciaID, SRC_1.I_RowID
							 FROM TR_Ec_Obl TRG_1
								  LEFT JOIN #temp_observados_detalle_anio_cuota_concepto SRC_1 ON TRG_1.I_RowID = SRC_1.I_RowID
							WHERE SRC_1.I_RowID IS NULL
								  AND ISNULL(TRG_1.B_Correcto, 0) = 0 
						  ) OBL 
						  ON OBS.I_FilaTablaID = OBL.I_RowID
							 AND OBS.I_ProcedenciaID = OBL.I_ProcedenciaID
		 WHERE OBS.I_ObservID = @I_ObservID 
			   AND OBS.I_ProcedenciaID = @I_ProcedenciaID 
			   AND OBS.I_TablaID = @I_TablaID


		SET @I_Observados = (SELECT COUNT(*) 
							   FROM TI_ObservacionRegistroTabla OBS 
									INNER JOIN TR_Ec_Obl OBL ON OBS.I_FilaTablaID = OBL.I_RowID 
																AND OBL.I_ProcedenciaID = OBS.I_ProcedenciaID
							  WHERE OBS.I_ObservID = @I_ObservID 
									AND OBS.I_ProcedenciaID = @I_ProcedenciaID  
									AND OBS.I_TablaID = @I_TablaID 
									AND OBS.B_Resuelto = 0)

		SELECT @I_Observados as cant_obs, @D_FecProceso as fec_proceso		

		COMMIT TRANSACTION		
		
		SET @B_Resultado = 1
		SET @T_Message = '{ ' +
							 'Type: "summary", ' + 
							 'Title: "Obligaciones con concepto no migrado", ' + 
							 'Value: ' + CAST(@I_Observados AS varchar) +
						 '}' 
	END TRY
	BEGIN CATCH
		IF (@@TRANCOUNT > 0)
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



IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_37_ObservacionAnioDetallePorOblID')
	DROP PROCEDURE [dbo].[USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_37_ObservacionAnioDetallePorOblID]
GO

CREATE PROCEDURE [dbo].[USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_37_ObservacionAnioDetallePorOblID]	
	@I_RowID	  int,
	@B_Resultado  bit OUTPUT,
	@T_Message	  nvarchar(4000) OUTPUT	
AS
/*
	DESCRIPCION: Marcar TR_Ec_Obl con B_Migrable = 0 cuando la obligacion tiene conceptos que no estan migrados o no son migrables para el Id de la obligacion

	DECLARE	@I_RowID	  int,
			@B_Resultado  bit,
			@T_Message	  nvarchar(4000)
	EXEC USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_37_ObservacionAnioDetalle @I_RowID, @B_Resultado output, @T_Message output
	SELECT @B_Resultado as resultado, @T_Message as mensaje
*/
BEGIN
	DECLARE @I_Observados int = 0
	DECLARE @D_FecProceso datetime = GETDATE() 
	DECLARE @I_ObservID int = 37,
			@I_ObservID_AnioDes int = 43,
			@I_ObservID_AnioPri int = 15
	
	DECLARE @I_TablaID int = 5,
			@I_TablaDetID int = 4

	BEGIN TRANSACTION
	BEGIN TRY

		SELECT Obl.*
		  INTO #temp_observados_detalle_anio_cuota_concepto
		  FROM TR_Ec_Obl Obl
			   INNER JOIN TR_Ec_Det Det ON Obl.I_RowID = Det.I_OblRowID
			   INNER JOIN TI_ObservacionRegistroTabla OBS ON OBS.I_FilaTablaID = Det.I_RowID AND 
						  									 OBS.I_ProcedenciaID = Det.I_ProcedenciaID 
		 WHERE OBS.I_ObservID IN (@I_ObservID_AnioDes, @I_ObservID_AnioPri)
			   AND OBS.I_TablaID = @I_TablaDetID
			   AND OBS.B_Resuelto = 0										  


		UPDATE	Obl
		SET		B_Migrable = 0,
				D_FecEvalua = @D_FecProceso
		FROM    TR_Ec_Obl Obl
				INNER JOIN #temp_observados_detalle_anio_cuota_concepto tmp ON Obl.I_RowID = tmp.I_RowID
		WHERE	Obl.I_RowID = @I_RowID


		MERGE TI_ObservacionRegistroTabla AS TRG
		USING (SELECT	DISTINCT @I_ObservID AS I_ObservID, @I_TablaID AS I_TablaID, Obl.I_RowID AS I_FilaTablaID, 
						@D_FecProceso AS D_FecRegistro, Obl.I_ProcedenciaID
				 FROM   TR_Ec_Obl Obl
						INNER JOIN #temp_observados_detalle_anio_cuota_concepto tmp ON Obl.I_RowID = tmp.I_RowID
				WHERE	Obl.I_RowID = @I_RowID
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
			   INNER JOIN (SELECT TRG_1.Ano, TRG_1.P, TRG_1.I_Periodo, TRG_1.Cod_alu, TRG_1.Cod_rc, TRG_1.Cuota_pago, TRG_1.Fch_venc, 
								  TRG_1.Tipo_oblig, TRG_1.Monto, TRG_1.I_ProcedenciaID, SRC_1.I_RowID
							 FROM TR_Ec_Obl TRG_1
								  LEFT JOIN #temp_observados_detalle_anio_cuota_concepto SRC_1 ON TRG_1.I_RowID = SRC_1.I_RowID
							WHERE SRC_1.I_RowID IS NULL
								  AND ISNULL(TRG_1.B_Correcto, 0) = 0 
						  ) OBL 
						  ON OBS.I_FilaTablaID = OBL.I_RowID 
							 AND OBS.I_ProcedenciaID = OBL.I_ProcedenciaID
		 WHERE OBS.I_ObservID = @I_ObservID 
			   AND OBS.I_TablaID = @I_TablaID
			   AND OBS.I_FilaTablaID = @I_RowID


		SET @I_Observados = (SELECT COUNT(*) 
							   FROM TI_ObservacionRegistroTabla OBS 
									INNER JOIN TR_Ec_Obl OBL ON OBS.I_FilaTablaID = OBL.I_RowID 
																AND OBL.I_ProcedenciaID = OBS.I_ProcedenciaID
							  WHERE OBS.I_ObservID = @I_ObservID 
									AND OBS.I_ProcedenciaID = @I_RowID 
									AND OBS.B_Resuelto = 0)

		SELECT @I_Observados as cant_obs, @D_FecProceso as fec_proceso		

		COMMIT TRANSACTION				
		SET @B_Resultado = 1
		SET @T_Message = '{ ' +
							 'Type: "summary", ' + 
							 'Title: "Observados ", ' + 
							 'Value: ' + CAST(@I_Observados AS varchar) +
						 '}' 
	END TRY
	BEGIN CATCH
		IF (@@TRANCOUNT > 0)
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

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_38_ObservacionPeriodoDetalle')
	DROP PROCEDURE [dbo].[USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_38_ObservacionPeriodoDetalle]
GO

CREATE PROCEDURE [dbo].[USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_38_ObservacionPeriodoDetalle]	
	@I_ProcedenciaID tinyint,
	@T_Anio		  varchar(4),
	@B_Resultado  bit output,
	@T_Message	  nvarchar(4000) OUTPUT	
AS
/*
	DESCRIPCION: Marcar TR_Ec_Obl con B_Migrable = 0 cuando la obligacion tiene conceptos que no estan migrados o no son migrables para el año y procedencia

	DECLARE @I_ProcedenciaID	tinyint = 1, 
	    	@T_Anio				varchar(4) = '2010',
			@B_Resultado		bit,
			@T_Message			nvarchar(4000)
	EXEC USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_38_ObservacionPeriodoDetalle @I_ProcedenciaID, @T_Anio, @B_Resultado output, @T_Message output
	SELECT @B_Resultado as resultado, @T_Message as mensaje
*/
BEGIN
	DECLARE @I_Observados int = 0
	DECLARE @D_FecProceso datetime = GETDATE() 
	DECLARE @I_ObservID int = 38,
			@I_ObservID_AnioDes int = 44,
			@I_ObservID_AnioPri int = 17
	
	DECLARE @I_TablaID int = 5,
			@I_TablaDetID int = 4

	BEGIN TRANSACTION
	BEGIN TRY

		SELECT Obl.*
		  INTO #temp_observados_detalle_periodo_cuota_concepto
		  FROM TR_Ec_Obl Obl
			   INNER JOIN TR_Ec_Det Det ON Obl.I_RowID = Det.I_OblRowID
			   INNER JOIN TI_ObservacionRegistroTabla OBS ON OBS.I_FilaTablaID = Det.I_RowID AND 
						  									 OBS.I_ProcedenciaID = Det.I_ProcedenciaID 
		 WHERE OBS.I_ObservID IN (@I_ObservID_AnioDes, @I_ObservID_AnioPri)
			   AND OBS.I_TablaID = @I_TablaDetID
			   AND OBS.B_Resuelto = 0										  


		UPDATE	Obl
		SET		B_Migrable = 0,
				D_FecEvalua = @D_FecProceso
		FROM    TR_Ec_Obl Obl
				INNER JOIN #temp_observados_detalle_periodo_cuota_concepto tmp ON Obl.I_RowID = tmp.I_RowID
		WHERE	
				Obl.I_ProcedenciaID = @I_ProcedenciaID
				AND Obl.Ano = @T_Anio


		MERGE TI_ObservacionRegistroTabla AS TRG
		USING (SELECT	DISTINCT @I_ObservID AS I_ObservID, @I_TablaID AS I_TablaID, Obl.I_RowID AS I_FilaTablaID, 
						@D_FecProceso AS D_FecRegistro, Obl.I_ProcedenciaID
				 FROM   TR_Ec_Obl Obl
						INNER JOIN #temp_observados_detalle_periodo_cuota_concepto tmp ON Obl.I_RowID = tmp.I_RowID
				WHERE	Obl.I_ProcedenciaID = @I_ProcedenciaID
						AND Obl.Ano = @T_Anio
			  ) AS SRC
		ON TRG.I_ObservID = SRC.I_ObservID AND TRG.I_TablaID = SRC.I_TablaID AND TRG.I_FilaTablaID = SRC.I_FilaTablaID
		WHEN MATCHED AND TRG.I_ProcedenciaID = @I_ProcedenciaID THEN
			UPDATE SET D_FecRegistro = SRC.D_FecRegistro
		WHEN NOT MATCHED BY TARGET THEN
			INSERT (I_ObservID, I_TablaID, I_FilaTablaID, D_FecRegistro, I_ProcedenciaID)
			VALUES (SRC.I_ObservID, SRC.I_TablaID, SRC.I_FilaTablaID, SRC.D_FecRegistro, SRC.I_ProcedenciaID);


		UPDATE OBS
		   SET D_FecResuelto = @D_FecProceso,
			   B_Resuelto = 1
		  FROM TI_ObservacionRegistroTabla OBS
			   INNER JOIN (SELECT TRG_1.Ano, TRG_1.P, TRG_1.I_Periodo, TRG_1.Cod_alu, TRG_1.Cod_rc, TRG_1.Cuota_pago, TRG_1.Fch_venc, 
								  TRG_1.Tipo_oblig, TRG_1.Monto, TRG_1.I_ProcedenciaID, SRC_1.I_RowID
							 FROM TR_Ec_Obl TRG_1
								  LEFT JOIN #temp_observados_detalle_periodo_cuota_concepto SRC_1 ON TRG_1.I_RowID = SRC_1.I_RowID
							WHERE SRC_1.I_RowID IS NULL
								  AND ISNULL(TRG_1.B_Correcto, 0) = 0 
						  ) OBL 
						  ON OBS.I_FilaTablaID = OBL.I_RowID
							 AND OBS.I_ProcedenciaID = OBL.I_ProcedenciaID
		 WHERE OBS.I_ObservID = @I_ObservID 
			   AND OBS.I_ProcedenciaID = @I_ProcedenciaID 
			   AND OBS.I_TablaID = @I_TablaID

		SET @I_Observados = (SELECT COUNT(*) 
							   FROM TI_ObservacionRegistroTabla OBS 
									INNER JOIN TR_Ec_Obl OBL ON OBS.I_FilaTablaID = OBL.I_RowID 
																AND OBL.I_ProcedenciaID = OBS.I_ProcedenciaID
							  WHERE OBS.I_ObservID = @I_ObservID 
									AND OBS.I_ProcedenciaID = @I_ProcedenciaID  
									AND OBS.I_TablaID = @I_TablaID 
									AND OBS.B_Resuelto = 0)

		SELECT @I_Observados as cant_obs, @D_FecProceso as fec_proceso		

		COMMIT TRANSACTION				
		SET @B_Resultado = 1
		SET @T_Message = '{ ' +
							 'Type: "summary", ' + 
							 'Title: "Obligaciones con concepto no migrado", ' + 
							 'Value: ' + CAST(@I_Observados AS varchar) +
						 '}' 
	END TRY
	BEGIN CATCH
		IF (@@TRANCOUNT > 0)
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



IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_38_ObservacionPeriodoDetallePorOblID')
	DROP PROCEDURE [dbo].[USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_38_ObservacionPeriodoDetallePorOblID]
GO

CREATE PROCEDURE [dbo].[USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_38_ObservacionPeriodoDetallePorOblID]	
	@I_RowID	  int,
	@B_Resultado  bit OUTPUT,
	@T_Message	  nvarchar(4000) OUTPUT	
AS
/*
	DESCRIPCION: Marcar TR_Ec_Obl con B_Migrable = 0 cuando la obligacion tiene conceptos que no estan migrados o no son migrables para el Id de la obligacion

	DECLARE	@I_RowID	  int,
			@B_Resultado  bit,
			@T_Message	  nvarchar(4000)
	EXEC USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_38_ObservacionPeriodoDetalle @I_RowID, @B_Resultado output, @T_Message output
	SELECT @B_Resultado as resultado, @T_Message as mensaje
*/
BEGIN
	DECLARE @I_Observados int = 0
	DECLARE @D_FecProceso datetime = GETDATE() 
	DECLARE @I_ObservID int = 38,
			@I_ObservID_AnioDes int = 44,
			@I_ObservID_AnioPri int = 17
	
	DECLARE @I_TablaID int = 5,
			@I_TablaDetID int = 4

	BEGIN TRANSACTION
	BEGIN TRY

		SELECT Obl.*
		  INTO #temp_observados_detalle_periodo_cuota_concepto
		  FROM TR_Ec_Obl Obl
			   INNER JOIN TR_Ec_Det Det ON Obl.I_RowID = Det.I_OblRowID
			   INNER JOIN TI_ObservacionRegistroTabla OBS ON OBS.I_FilaTablaID = Det.I_RowID AND 
						  									 OBS.I_ProcedenciaID = Det.I_ProcedenciaID 
		 WHERE OBS.I_ObservID IN (@I_ObservID_AnioDes, @I_ObservID_AnioPri)
			   AND OBS.I_TablaID = @I_TablaDetID
			   AND OBS.B_Resuelto = 0										  


		UPDATE	Obl
		SET		B_Migrable = 0,
				D_FecEvalua = @D_FecProceso
		FROM    TR_Ec_Obl Obl
				INNER JOIN #temp_observados_detalle_periodo_cuota_concepto tmp ON Obl.I_RowID = tmp.I_RowID
		WHERE	Obl.I_RowID = @I_RowID


		MERGE TI_ObservacionRegistroTabla AS TRG
		USING (SELECT	DISTINCT @I_ObservID AS I_ObservID, @I_TablaID AS I_TablaID, Obl.I_RowID AS I_FilaTablaID, 
						@D_FecProceso AS D_FecRegistro, Obl.I_ProcedenciaID
				 FROM   TR_Ec_Obl Obl
						INNER JOIN #temp_observados_detalle_periodo_cuota_concepto tmp ON Obl.I_RowID = tmp.I_RowID
				WHERE	Obl.I_RowID = @I_RowID 
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
			   INNER JOIN (SELECT TRG_1.Ano, TRG_1.P, TRG_1.I_Periodo, TRG_1.Cod_alu, TRG_1.Cod_rc, TRG_1.Cuota_pago, TRG_1.Fch_venc, 
								  TRG_1.Tipo_oblig, TRG_1.Monto, TRG_1.I_ProcedenciaID, SRC_1.I_RowID
							 FROM TR_Ec_Obl TRG_1
								  LEFT JOIN #temp_observados_detalle_periodo_cuota_concepto SRC_1 ON TRG_1.I_RowID = SRC_1.I_RowID
							WHERE SRC_1.I_RowID IS NULL
								  AND ISNULL(TRG_1.B_Correcto, 0) = 0 
						  ) OBL 
						  ON OBS.I_FilaTablaID = OBL.I_RowID
							 AND OBS.I_ProcedenciaID = OBL.I_ProcedenciaID
		 WHERE OBS.I_ObservID = @I_ObservID 
			   AND OBS.I_TablaID = @I_TablaID
			   AND OBS.I_FilaTablaID = @I_RowID


		SET @I_Observados = (SELECT COUNT(*) 
							   FROM TI_ObservacionRegistroTabla OBS 
									INNER JOIN TR_Ec_Obl OBL ON OBS.I_FilaTablaID = OBL.I_RowID 
																AND OBL.I_ProcedenciaID = OBS.I_ProcedenciaID
							  WHERE OBS.I_ObservID = @I_ObservID 
									AND OBS.I_FilaTablaID = @I_RowID 
									AND OBS.B_Resuelto = 0)

		SELECT @I_Observados as cant_obs, @D_FecProceso as fec_proceso	

		COMMIT TRANSACTION				
		SET @B_Resultado = 1
		SET @T_Message = '{ ' +
							 'Type: "summary", ' + 
							 'Title: "Observados ", ' + 
							 'Value: ' + CAST(@I_Observados AS varchar) +
						 '}' 
	END TRY
	BEGIN CATCH
		IF (@@TRANCOUNT > 0)
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



IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_39_DetalleObservado')
	DROP PROCEDURE [dbo].[USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_39_DetalleObservado]
GO

CREATE PROCEDURE [dbo].[USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_39_DetalleObservado]
	@I_ProcedenciaID tinyint,
	@T_Anio			varchar(4) = NULL,
	@B_Resultado	bit output,
	@T_Message		nvarchar(4000) OUTPUT	
AS
/*
	DESCRIPCION: Marcar TR_Ec_Obl con B_Migrable = 0 cuando la obligacion tiene registros observados en el detalle para el año y procedencia

	DECLARE @I_ProcedenciaID	tinyint = 3, 
			@T_Anio		  varchar(4) = '2005',
			@B_Resultado  bit,
			@T_Message    nvarchar(4000)
	EXEC USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_39_DetalleObservado @I_ProcedenciaID, @T_Anio, @B_Resultado output, @T_Message output
	SELECT @B_Resultado as resultado, @T_Message as mensaje
*/
BEGIN
	DECLARE @I_Observados int = 0
	DECLARE @D_FecProceso datetime = GETDATE() 
	DECLARE @I_ObservID int = 39
	DECLARE @I_TablaID int = 5

	BEGIN TRANSACTION
	BEGIN TRY

		SELECT Obl.*
		  INTO #temp_observados_detalle
		  FROM TR_Ec_Obl Obl
		  	   INNER JOIN TR_Ec_Det Det ON Obl.I_RowID = Det.I_OblRowID
		 WHERE Det.B_Migrable = 0
		 	   AND Obl.Ano = @T_Anio
			   AND Obl.I_ProcedenciaID = @I_ProcedenciaID

		
		UPDATE Obl
		   SET B_Migrable = 0,
		   	   D_FecEvalua = @D_FecProceso 
		  FROM TR_Ec_Obl Obl
		  	   INNER JOIN #temp_observados_detalle tmp ON Obl.I_RowID = tmp.I_RowID
		 WHERE ISNULL(Obl.B_Correcto, 0) = 0


		MERGE TI_ObservacionRegistroTabla AS TRG
		USING 	(SELECT	@I_ObservID AS I_ObservID, @I_TablaID AS I_TablaID, Obl.I_RowID AS I_FilaTablaID, 
						@D_FecProceso AS D_FecRegistro, Obl.I_ProcedenciaID
				   FROM TR_Ec_Obl Obl
						INNER JOIN #temp_observados_detalle tmp ON Obl.I_RowID = tmp.I_RowID
				  WHERE ISNULL(Obl.B_Correcto, 0) = 0
				) AS SRC
		ON TRG.I_ObservID = SRC.I_ObservID AND TRG.I_TablaID = SRC.I_TablaID AND TRG.I_FilaTablaID = SRC.I_FilaTablaID
		WHEN MATCHED AND TRG.I_ProcedenciaID = @I_ProcedenciaID THEN
			UPDATE SET D_FecRegistro = SRC.D_FecRegistro
		WHEN NOT MATCHED BY TARGET AND SRC.I_ProcedenciaID = @I_ProcedenciaID THEN
			INSERT (I_ObservID, I_TablaID, I_FilaTablaID, D_FecRegistro, I_ProcedenciaID)
			VALUES (SRC.I_ObservID, SRC.I_TablaID, SRC.I_FilaTablaID, SRC.D_FecRegistro, @I_ProcedenciaID);


		UPDATE OBS
		   SET D_FecResuelto = @D_FecProceso,
		   	   B_Resuelto = 1
		  FROM TI_ObservacionRegistroTabla OBS
		  	   INNER JOIN (SELECT Obl.*, tmp.I_RowID as TmpRowID
			   				 FROM TR_Ec_Obl Obl
							 	  LEFT JOIN #temp_observados_detalle tmp ON Obl.I_RowID = tmp.I_RowID 
							WHERE tmp.I_RowID IS NULL
								  AND Obl.Ano = @T_Anio
								  AND Obl.I_ProcedenciaID = @I_ProcedenciaID
			   			  ) OBL ON OBS.I_FilaTablaID = OBL.I_RowID
						  		   AND OBS.I_ProcedenciaID = OBL.I_ProcedenciaID 
		 WHERE OBS.I_ObservID = @I_ObservID 
		 	   AND OBS.I_TablaID = @I_TablaID


		SET @I_Observados = (SELECT COUNT(*) 
							   FROM TI_ObservacionRegistroTabla OBS 
									INNER JOIN TR_Ec_Obl OBL ON OBS.I_FilaTablaID = OBL.I_RowID 
																AND OBL.I_ProcedenciaID = OBS.I_ProcedenciaID
							  WHERE OBS.I_ObservID = @I_ObservID 
									AND OBL.Ano = @T_Anio 
									AND OBL.I_ProcedenciaID = @I_ProcedenciaID 
									AND OBS.B_Resuelto = 0)

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
		IF (@@TRANCOUNT > 0)
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



IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_39_DetalleObservadoPorOblID')
	DROP PROCEDURE [dbo].[USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_39_DetalleObservadoPorOblID]
GO

CREATE PROCEDURE [dbo].[USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_39_DetalleObservadoPorOblID]	
	@I_RowID	  int,
	@B_Resultado  bit OUTPUT,
	@T_Message	  nvarchar(4000) OUTPUT	
AS
/*
	DESCRIPCION: Marcar TR_Ec_Obl con B_Migrable = 0 cuando la obligacion tiene conceptos que no estan migrados o no son migrables para el Id de la obligacion

	DECLARE	@I_RowID	  int,
			@B_Resultado  bit,
			@T_Message	  nvarchar(4000)
	EXEC USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_39_DetalleObservado @I_RowID, @B_Resultado output, @T_Message output
	SELECT @B_Resultado as resultado, @T_Message as mensaje
*/
BEGIN
	DECLARE @I_Observados int = 0
	DECLARE @D_FecProceso datetime = GETDATE() 
	DECLARE @I_ObservID int = 39
	DECLARE @I_TablaID int = 5

	BEGIN TRANSACTION
	BEGIN TRY

		SELECT Obl.*
		  INTO #temp_observados_detalle
		  FROM TR_Ec_Obl Obl
		  	   INNER JOIN TR_Ec_Det Det ON Obl.I_RowID = Det.I_OblRowID
		 WHERE Det.B_Migrable = 0
		 	   AND Obl.I_RowID = @I_RowID
		
		UPDATE Obl
		   SET B_Migrable = 0,
		   	   D_FecEvalua = @D_FecProceso 
		  FROM TR_Ec_Obl Obl
		  	   INNER JOIN #temp_observados_detalle tmp ON Obl.I_RowID = tmp.I_RowID
		 WHERE ISNULL(Obl.B_Correcto, 0) = 0


		MERGE TI_ObservacionRegistroTabla AS TRG
		USING 	(SELECT	@I_ObservID AS I_ObservID, @I_TablaID AS I_TablaID, Obl.I_RowID AS I_FilaTablaID, 
						@D_FecProceso AS D_FecRegistro, Obl.I_ProcedenciaID
				   FROM TR_Ec_Obl Obl
						INNER JOIN #temp_observados_detalle tmp ON Obl.I_RowID = tmp.I_RowID
				  WHERE ISNULL(Obl.B_Correcto, 0) = 0
				) AS SRC
		ON TRG.I_ObservID = SRC.I_ObservID AND TRG.I_TablaID = SRC.I_TablaID AND TRG.I_FilaTablaID = SRC.I_FilaTablaID
		WHEN MATCHED AND TRG.I_ProcedenciaID = SRC.I_ProcedenciaID THEN
			UPDATE SET D_FecRegistro = SRC.D_FecRegistro
		WHEN NOT MATCHED BY TARGET AND SRC.I_ProcedenciaID = SRC.I_ProcedenciaID THEN
			INSERT (I_ObservID, I_TablaID, I_FilaTablaID, D_FecRegistro, I_ProcedenciaID)
			VALUES (SRC.I_ObservID, SRC.I_TablaID, SRC.I_FilaTablaID, SRC.D_FecRegistro, SRC.I_ProcedenciaID);


		UPDATE OBS
		   SET D_FecResuelto = @D_FecProceso,
		   	   B_Resuelto = 1
		  FROM TI_ObservacionRegistroTabla OBS
		  	   INNER JOIN (SELECT Obl.*, tmp.I_RowID as TmpRowID
			   				 FROM TR_Ec_Obl Obl
							 	  LEFT JOIN #temp_observados_detalle tmp ON Obl.I_RowID = tmp.I_RowID 
							WHERE tmp.I_RowID IS NULL
								  AND Obl.I_RowID = @I_RowID
			   			  ) OBL ON OBS.I_FilaTablaID = OBL.I_RowID
						  		   AND OBS.I_ProcedenciaID = OBL.I_ProcedenciaID 
		 WHERE OBS.I_ObservID = @I_ObservID 
		 	   AND OBS.I_TablaID = @I_TablaID


		SET @I_Observados = (SELECT COUNT(*) 
							   FROM TI_ObservacionRegistroTabla OBS 
									INNER JOIN TR_Ec_Obl OBL ON OBS.I_FilaTablaID = OBL.I_RowID 
																AND OBL.I_ProcedenciaID = OBS.I_ProcedenciaID
							  WHERE OBS.I_ObservID = @I_ObservID 
									AND OBL.I_RowID = @I_RowID
									AND OBS.B_Resuelto = 0)

		SELECT @I_Observados as cant_obs, @D_FecProceso as fec_proceso	

		COMMIT TRANSACTION				
		SET @B_Resultado = 1
		SET @T_Message = '{ ' +
							 'Type: "summary", ' + 
							 'Title: "Observados ", ' + 
							 'Value: ' + CAST(@I_Observados AS varchar) +
						 '}' 
	END TRY
	BEGIN CATCH
		IF (@@TRANCOUNT > 0)
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



IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_40_ObligacionSinDetalle')
	DROP PROCEDURE [dbo].[USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_40_ObligacionSinDetalle]
GO

CREATE PROCEDURE [dbo].[USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_40_ObligacionSinDetalle]
	@I_ProcedenciaID tinyint,
	@T_Anio			varchar(4) = NULL,
	@B_Resultado	bit output,
	@T_Message		nvarchar(4000) OUTPUT	
AS
/*
	DESCRIPCION: Marcar TR_Ec_Obl con B_Migrable = 0 cuando la obligacion no tiene registros asociados en el detalle para el año y procedencia.

	DECLARE @I_ProcedenciaID	tinyint = 1, 
			@T_Anio		  varchar(4) = '2010',
			@B_Resultado  bit,
			@T_Message    nvarchar(4000)
	EXEC USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_40_ObligacionSinDetalle @I_ProcedenciaID, @T_Anio, @B_Resultado output, @T_Message output
	SELECT @B_Resultado as resultado, @T_Message as mensaje
*/
BEGIN
	DECLARE @I_Observados int = 0
	DECLARE @D_FecProceso datetime = GETDATE() 
	DECLARE @I_ObservID int = 40
	DECLARE @I_TablaID int = 5

	BEGIN TRANSACTION
	BEGIN TRY

		SELECT  I_OblRowID, COUNT(I_RowID) AS count_det
		  INTO	temp_det_count_rows
		  FROM  TR_Ec_Det 
		 WHERE  Ano = @T_Anio 
		 		AND I_ProcedenciaID = @I_ProcedenciaID 
		GROUP BY I_OblRowID
		HAVING  COUNT(I_RowID) > 0

		UPDATE	Obl
		SET		B_Migrable = 0,
				D_FecEvalua = @D_FecProceso
		FROM    TR_Ec_Obl Obl
				LEFT JOIN TR_Ec_Det Det 
				ON Obl.I_RowID = Det.I_OblRowID
		WHERE	Obl.Ano = @T_Anio
				AND Obl.I_ProcedenciaID = @I_ProcedenciaID
				AND Det.I_OblRowID IS NULL
					

		MERGE  TI_ObservacionRegistroTabla AS TRG
		USING  (SELECT @I_ObservID AS I_ObservID, @I_TablaID AS I_TablaID, Obl.I_RowID AS I_FilaTablaID, @D_FecProceso AS D_FecRegistro 
				  FROM TR_Ec_Obl Obl
					   LEFT JOIN TR_Ec_Det Det ON Obl.I_RowID = Det.I_OblRowID
				 WHERE Obl.Ano = @T_Anio
					   AND Obl.I_ProcedenciaID = @I_ProcedenciaID
					   AND Det.I_OblRowID IS NULL
				) AS SRC
		ON TRG.I_ObservID = SRC.I_ObservID AND TRG.I_TablaID = SRC.I_TablaID AND TRG.I_FilaTablaID = SRC.I_FilaTablaID
		WHEN MATCHED AND TRG.I_ProcedenciaID = @I_ProcedenciaID THEN
			UPDATE SET D_FecRegistro = SRC.D_FecRegistro
		WHEN NOT MATCHED BY TARGET THEN
			INSERT (I_ObservID, I_TablaID, I_FilaTablaID, D_FecRegistro, I_ProcedenciaID)
			VALUES (SRC.I_ObservID, SRC.I_TablaID, SRC.I_FilaTablaID, SRC.D_FecRegistro, @I_ProcedenciaID);


		UPDATE OBS
		   SET D_FecResuelto = @D_FecProceso,
		   	   B_Resuelto = 1
		  FROM TI_ObservacionRegistroTabla OBS
		  	   INNER JOIN (SELECT Obl.*, Det.I_RowID as DetRowID
			   				 FROM TR_Ec_Obl Obl
								  LEFT JOIN TR_Ec_Det Det ON Obl.I_RowID = Det.I_OblRowID
							WHERE Det.I_RowID IS NULL
								  AND Obl.I_ProcedenciaID = @I_ProcedenciaID  
								  AND Obl.Ano = @T_Anio 
			   			  ) OBL ON OBS.I_FilaTablaID = OBL.I_RowID
						  		   AND OBS.I_ProcedenciaID = OBL.I_ProcedenciaID 
		 WHERE OBS.I_ObservID = @I_ObservID 
		 	   AND OBS.I_TablaID = @I_TablaID
		

		SET @I_Observados = (SELECT COUNT(*) 
							   FROM TI_ObservacionRegistroTabla 
							  WHERE I_ObservID = @I_ObservID 
							  		AND I_TablaID = @I_TablaID 
									AND I_ProcedenciaID = @I_ProcedenciaID
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
		  IF (@@TRANCOUNT > 0)
		SET @B_Resultado = 0
		SET @T_Message = '[{ ' +
							 'Type: "error", ' + 
							 'Title: "Error", ' + 
							 'Value: "' + ERROR_MESSAGE() + ' (Linea: ' + CAST(ERROR_LINE() AS varchar(11)) + ')."'  +
						  '}]' 
	END CATCH
END
GO


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_40_ObligacionSinDetallePorOblID')
	DROP PROCEDURE [dbo].[USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_40_ObligacionSinDetallePorOblID]
GO

CREATE PROCEDURE [dbo].[USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_40_ObligacionSinDetallePorOblID]
	@I_RowID	  int,
	@B_Resultado  bit output,
	@T_Message    nvarchar(4000) OUTPUT	
AS
/*
	DESCRIPCION: Marcar TR_Ec_Obl con B_Migrable = 0 cuando la obligacion no tiene registros asociados en el detalle para el ID de obligacion.

	DECLARE @I_RowID	  int,
			@B_Resultado  bit,
			@T_Message    nvarchar(4000)
	EXEC USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_40_ObligacionSinDetallePorOblID @I_RowID, @B_Resultado output, @T_Message output
	SELECT @B_Resultado as resultado, @T_Message as mensaje
*/
BEGIN
	DECLARE @I_Observados int = 0
	DECLARE @I_ObservadosObl int = 0
	DECLARE @D_FecProceso datetime = GETDATE() 
	DECLARE @I_ObservID int = 40
	DECLARE @I_TablaID int = 5

	BEGIN TRANSACTION
	BEGIN TRY

		COMMIT TRANSACTION

		SET @B_Resultado = 1
		SET @T_Message = '{ ' +
							 'Type: "summary", ' + 
							 'Title: "Observados", ' + 
							 'Value: ' + CAST(@I_ObservadosObl AS varchar) +
						 '}' 
	END TRY
	BEGIN CATCH
		  IF (@@TRANCOUNT > 0)
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
		Validaciones para migracion de ec_det (solo obligaciones de pago)	
	===============================================================================================
*/ 



IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_U_ValidarDetalleObligacion')
	DROP PROCEDURE [dbo].[USP_U_ValidarDetalleObligacion]
GO

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_Obligaciones_ObligacionDet_MigracionTP_U_Validar_25_ObligacionCabID')
	DROP PROCEDURE [dbo].[USP_Obligaciones_ObligacionDet_MigracionTP_U_Validar_25_ObligacionCabID]
GO


CREATE PROCEDURE [dbo].[USP_Obligaciones_ObligacionDet_MigracionTP_U_Validar_25_ObligacionCabID]	
(
	@I_ProcedenciaID tinyint,
	@T_Anio		  varchar(4),
	@B_Resultado  bit output,
	@T_Message	  nvarchar(4000) OUTPUT	
)
AS
/*
	DESCRIPCION: Marcar TR_Ec_Det con B_Migrable = 0 cuando la obligacion asociada tiene estado B_Migrable = 0.

	DECLARE	@B_Resultado  bit,
			@I_ProcedenciaID	tinyint = 2,
			@T_Anio				varchar(4) = '2016',
			@T_Message			nvarchar(4000)
	EXEC USP_Obligaciones_ObligacionDet_MigracionTP_U_Validar_25_ObligacionCabID @I_ProcedenciaID, @T_Anio, @B_Resultado output, @T_Message output
	SELECT @B_Resultado as resultado, @T_Message as mensaje
*/
BEGIN
	DECLARE @I_Observados int = 0
	DECLARE @I_ObservadosObl int = 0
	DECLARE @D_FecProceso datetime = GETDATE() 
	DECLARE @I_ObservID int = 25
	DECLARE @I_TablaID int = 4

	BEGIN TRANSACTION
	BEGIN TRY 


		COMMIT TRANSACTION;

		SET @B_Resultado = 1
		SET @T_Message = '{ ' +
							 'Type: "summary", ' + 
							 'Title: "Observados sin OblId", ' + 
							 'Value: ' + CAST(@I_Observados AS varchar) +
						 '}' 

	END TRY
	BEGIN CATCH
		  IF (@@TRANCOUNT > 0)
		SET @B_Resultado = 0
		SET @T_Message = '[{ ' +
							 'Type: "error", ' + 
							 'Title: "Error", ' + 
							 'Value: "' + ERROR_MESSAGE() + ' (Linea: ' + CAST(ERROR_LINE() AS varchar(11)) + ')."'  +
						  '}]' 
	END CATCH
END
GO


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_Obligaciones_ObligacionDet_MigracionTP_U_Validar_25_ObligacionCabIDPorOblID')
	DROP PROCEDURE [dbo].[USP_Obligaciones_ObligacionDet_MigracionTP_U_Validar_25_ObligacionCabIDPorOblID]
GO

CREATE PROCEDURE [dbo].[USP_Obligaciones_ObligacionDet_MigracionTP_U_Validar_25_ObligacionCabIDPorOblID]
	@I_RowID	  int,
	@B_Resultado  bit output,
	@T_Message    nvarchar(4000) OUTPUT	
AS
/*
	DESCRIPCION: Marcar TR_Ec_Obl con B_Migrable = 0 cuando la obligacion no tiene registros asociados en el detalle para el ID de obligacion.

	DECLARE @I_RowID	  int,
			@B_Resultado  bit,
			@T_Message    nvarchar(4000)
	EXEC USP_Obligaciones_ObligacionDet_MigracionTP_U_Validar_25_ObligacionCabIDPorOblID @I_RowID, @B_Resultado output, @T_Message output
	SELECT @B_Resultado as resultado, @T_Message as mensaje
*/
BEGIN
	DECLARE @I_Observados int = 0
	DECLARE @I_ObservadosObl int = 0
	DECLARE @D_FecProceso datetime = GETDATE() 
	DECLARE @I_ObservID int = 40
	DECLARE @I_TablaID int = 5

	BEGIN TRANSACTION
	BEGIN TRY

		COMMIT TRANSACTION

		SET @B_Resultado = 1
		SET @T_Message = '{ ' +
							 'Type: "summary", ' + 
							 'Title: "Observados", ' + 
							 'Value: ' + CAST(@I_ObservadosObl AS varchar) +
						 '}' 
	END TRY
	BEGIN CATCH
		  IF (@@TRANCOUNT > 0)
		SET @B_Resultado = 0
		SET @T_Message = '[{ ' +
							 'Type: "error", ' + 
							 'Title: "Error", ' + 
							 'Value: "' + ERROR_MESSAGE() + ' (Linea: ' + CAST(ERROR_LINE() AS varchar(11)) + ')."'  +
						  '}]' 
	END CATCH
END
GO



IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_Obligaciones_ObligacionDet_MigracionTP_U_Validar_42_CuotaDetalleCuotaConcepto')
	DROP PROCEDURE [dbo].[USP_Obligaciones_ObligacionDet_MigracionTP_U_Validar_42_CuotaDetalleCuotaConcepto]
GO


CREATE PROCEDURE [dbo].[USP_Obligaciones_ObligacionDet_MigracionTP_U_Validar_42_CuotaDetalleCuotaConcepto]	
(
	@I_ProcedenciaID tinyint,
	@T_Anio		  varchar(4),
	@B_Resultado  bit output,
	@T_Message	  nvarchar(4000) OUTPUT	
)
AS
/*
	DESCRIPCION: Marcar TR_Ec_Det con B_Migrable = 0 cuando la obligacion asociada tiene estado B_Migrable = 0.

	DECLARE	@B_Resultado  bit,
			@I_ProcedenciaID	tinyint = 2,
			@T_Anio				varchar(4) = '2016',
			@T_Message			nvarchar(4000)
	EXEC USP_Obligaciones_ObligacionDet_MigracionTP_U_Validar_42_CuotaDetalleCuotaConcepto @I_ProcedenciaID, @T_Anio, @B_Resultado output, @T_Message output
	SELECT @B_Resultado as resultado, @T_Message as mensaje
*/
BEGIN
	DECLARE @I_Observados int = 0
	DECLARE @I_ObservadosObl int = 0
	DECLARE @D_FecProceso datetime = GETDATE() 
	DECLARE @I_ObservID int = 25
	DECLARE @I_TablaID int = 4

	BEGIN TRANSACTION
	BEGIN TRY 


		COMMIT TRANSACTION;

		SET @B_Resultado = 1
		SET @T_Message = '{ ' +
							 'Type: "summary", ' + 
							 'Title: "Observados sin OblId", ' + 
							 'Value: ' + CAST(@I_Observados AS varchar) +
						 '}' 

	END TRY
	BEGIN CATCH
		  IF (@@TRANCOUNT > 0)
		SET @B_Resultado = 0
		SET @T_Message = '[{ ' +
							 'Type: "error", ' + 
							 'Title: "Error", ' + 
							 'Value: "' + ERROR_MESSAGE() + ' (Linea: ' + CAST(ERROR_LINE() AS varchar(11)) + ')."'  +
						  '}]' 
	END CATCH
END
GO


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_Obligaciones_ObligacionDet_MigracionTP_U_Validar_42_CuotaDetalleCuotaConceptoPorOblID')
	DROP PROCEDURE [dbo].[USP_Obligaciones_ObligacionDet_MigracionTP_U_Validar_42_CuotaDetalleCuotaConceptoPorOblID]
GO

CREATE PROCEDURE [dbo].[USP_Obligaciones_ObligacionDet_MigracionTP_U_Validar_42_CuotaDetalleCuotaConceptoPorOblID]
	@I_RowID	  int,
	@B_Resultado  bit output,
	@T_Message    nvarchar(4000) OUTPUT	
AS
/*
	DESCRIPCION: Marcar TR_Ec_Obl con B_Migrable = 0 cuando la obligacion no tiene registros asociados en el detalle para el ID de obligacion.

	DECLARE @I_RowID	  int,
			@B_Resultado  bit,
			@T_Message    nvarchar(4000)
	EXEC USP_Obligaciones_ObligacionDet_MigracionTP_U_Validar_42_CuotaDetalleCuotaConceptoPorOblID @I_RowID, @B_Resultado output, @T_Message output
	SELECT @B_Resultado as resultado, @T_Message as mensaje
*/
BEGIN
	DECLARE @I_Observados int = 0
	DECLARE @I_ObservadosObl int = 0
	DECLARE @D_FecProceso datetime = GETDATE() 
	DECLARE @I_ObservID int = 40
	DECLARE @I_TablaID int = 5

	BEGIN TRANSACTION
	BEGIN TRY

		COMMIT TRANSACTION

		SET @B_Resultado = 1
		SET @T_Message = '{ ' +
							 'Type: "summary", ' + 
							 'Title: "Observados", ' + 
							 'Value: ' + CAST(@I_ObservadosObl AS varchar) +
						 '}' 
	END TRY
	BEGIN CATCH
		  IF (@@TRANCOUNT > 0)
		SET @B_Resultado = 0
		SET @T_Message = '[{ ' +
							 'Type: "error", ' + 
							 'Title: "Error", ' + 
							 'Value: "' + ERROR_MESSAGE() + ' (Linea: ' + CAST(ERROR_LINE() AS varchar(11)) + ')."'  +
						  '}]' 
	END CATCH
END
GO



IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_Obligaciones_ObligacionDet_MigracionTP_U_Validar_43_AnioDetalleAnioConcepto')
	DROP PROCEDURE [dbo].[USP_Obligaciones_ObligacionDet_MigracionTP_U_Validar_43_AnioDetalleAnioConcepto]
GO


CREATE PROCEDURE [dbo].[USP_Obligaciones_ObligacionDet_MigracionTP_U_Validar_43_AnioDetalleAnioConcepto]	
(
	@I_ProcedenciaID tinyint,
	@T_Anio		  varchar(4),
	@B_Resultado  bit output,
	@T_Message	  nvarchar(4000) OUTPUT	
)
AS
/*
	DESCRIPCION: Marcar TR_Ec_Det con B_Migrable = 0 cuando la obligacion asociada tiene estado B_Migrable = 0.

	DECLARE	@B_Resultado  bit,
			@I_ProcedenciaID	tinyint = 2,
			@T_Anio				varchar(4) = '2016',
			@T_Message			nvarchar(4000)
	EXEC USP_Obligaciones_ObligacionDet_MigracionTP_U_Validar_43_AnioDetalleAnioConcepto @I_ProcedenciaID, @T_Anio, @B_Resultado output, @T_Message output
	SELECT @B_Resultado as resultado, @T_Message as mensaje
*/
BEGIN
	DECLARE @I_Observados int = 0
	DECLARE @I_ObservadosObl int = 0
	DECLARE @D_FecProceso datetime = GETDATE() 
	DECLARE @I_ObservID int = 25
	DECLARE @I_TablaID int = 4

	BEGIN TRANSACTION
	BEGIN TRY 


		COMMIT TRANSACTION;

		SET @B_Resultado = 1
		SET @T_Message = '{ ' +
							 'Type: "summary", ' + 
							 'Title: "Observados sin OblId", ' + 
							 'Value: ' + CAST(@I_Observados AS varchar) +
						 '}' 

	END TRY
	BEGIN CATCH
		  IF (@@TRANCOUNT > 0)
		SET @B_Resultado = 0
		SET @T_Message = '[{ ' +
							 'Type: "error", ' + 
							 'Title: "Error", ' + 
							 'Value: "' + ERROR_MESSAGE() + ' (Linea: ' + CAST(ERROR_LINE() AS varchar(11)) + ')."'  +
						  '}]' 
	END CATCH
END
GO


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_Obligaciones_ObligacionDet_MigracionTP_U_Validar_43_AnioDetalleAnioConceptoPorOblID')
	DROP PROCEDURE [dbo].[USP_Obligaciones_ObligacionDet_MigracionTP_U_Validar_43_AnioDetalleAnioConceptoPorOblID]
GO

CREATE PROCEDURE [dbo].[USP_Obligaciones_ObligacionDet_MigracionTP_U_Validar_43_AnioDetalleAnioConceptoPorOblID]
	@I_RowID	  int,
	@B_Resultado  bit output,
	@T_Message    nvarchar(4000) OUTPUT	
AS
/*
	DESCRIPCION: Marcar TR_Ec_Obl con B_Migrable = 0 cuando la obligacion no tiene registros asociados en el detalle para el ID de obligacion.

	DECLARE @I_RowID	  int,
			@B_Resultado  bit,
			@T_Message    nvarchar(4000)
	EXEC USP_Obligaciones_ObligacionDet_MigracionTP_U_Validar_43_AnioDetalleAnioConceptoPorOblID @I_RowID, @B_Resultado output, @T_Message output
	SELECT @B_Resultado as resultado, @T_Message as mensaje
*/
BEGIN
	DECLARE @I_Observados int = 0
	DECLARE @I_ObservadosObl int = 0
	DECLARE @D_FecProceso datetime = GETDATE() 
	DECLARE @I_ObservID int = 40
	DECLARE @I_TablaID int = 5

	BEGIN TRANSACTION
	BEGIN TRY

		COMMIT TRANSACTION

		SET @B_Resultado = 1
		SET @T_Message = '{ ' +
							 'Type: "summary", ' + 
							 'Title: "Observados", ' + 
							 'Value: ' + CAST(@I_ObservadosObl AS varchar) +
						 '}' 
	END TRY
	BEGIN CATCH
		  IF (@@TRANCOUNT > 0)
		SET @B_Resultado = 0
		SET @T_Message = '[{ ' +
							 'Type: "error", ' + 
							 'Title: "Error", ' + 
							 'Value: "' + ERROR_MESSAGE() + ' (Linea: ' + CAST(ERROR_LINE() AS varchar(11)) + ')."'  +
						  '}]' 
	END CATCH
END
GO


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_Obligaciones_ObligacionDet_MigracionTP_U_Validar_44_PeriodoDetallePeriodoConcepto')
	DROP PROCEDURE [dbo].[USP_Obligaciones_ObligacionDet_MigracionTP_U_Validar_44_PeriodoDetallePeriodoConcepto]
GO


CREATE PROCEDURE [dbo].[USP_Obligaciones_ObligacionDet_MigracionTP_U_Validar_44_PeriodoDetallePeriodoConcepto]	
(
	@I_ProcedenciaID tinyint,
	@T_Anio		  varchar(4),
	@B_Resultado  bit output,
	@T_Message	  nvarchar(4000) OUTPUT	
)
AS
/*
	DESCRIPCION: Marcar TR_Ec_Det con B_Migrable = 0 cuando la obligacion asociada tiene estado B_Migrable = 0.

	DECLARE	@B_Resultado  bit,
			@I_ProcedenciaID	tinyint = 2,
			@T_Anio				varchar(4) = '2016',
			@T_Message			nvarchar(4000)
	EXEC USP_Obligaciones_ObligacionDet_MigracionTP_U_Validar_44_PeriodoDetallePeriodoConcepto @I_ProcedenciaID, @T_Anio, @B_Resultado output, @T_Message output
	SELECT @B_Resultado as resultado, @T_Message as mensaje
*/
BEGIN
	DECLARE @I_Observados int = 0
	DECLARE @I_ObservadosObl int = 0
	DECLARE @D_FecProceso datetime = GETDATE() 
	DECLARE @I_ObservID int = 25
	DECLARE @I_TablaID int = 4

	BEGIN TRANSACTION
	BEGIN TRY 


		COMMIT TRANSACTION;

		SET @B_Resultado = 1
		SET @T_Message = '{ ' +
							 'Type: "summary", ' + 
							 'Title: "Observados sin OblId", ' + 
							 'Value: ' + CAST(@I_Observados AS varchar) +
						 '}' 

	END TRY
	BEGIN CATCH
		  IF (@@TRANCOUNT > 0)
		SET @B_Resultado = 0
		SET @T_Message = '[{ ' +
							 'Type: "error", ' + 
							 'Title: "Error", ' + 
							 'Value: "' + ERROR_MESSAGE() + ' (Linea: ' + CAST(ERROR_LINE() AS varchar(11)) + ')."'  +
						  '}]' 
	END CATCH
END
GO


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_Obligaciones_ObligacionDet_MigracionTP_U_Validar_44_PeriodoDetallePeriodoConceptoPorOblID')
	DROP PROCEDURE [dbo].[USP_Obligaciones_ObligacionDet_MigracionTP_U_Validar_44_PeriodoDetallePeriodoConceptoPorOblID]
GO

CREATE PROCEDURE [dbo].[USP_Obligaciones_ObligacionDet_MigracionTP_U_Validar_44_PeriodoDetallePeriodoConceptoPorOblID]
	@I_RowID	  int,
	@B_Resultado  bit output,
	@T_Message    nvarchar(4000) OUTPUT	
AS
/*
	DESCRIPCION: Marcar TR_Ec_Obl con B_Migrable = 0 cuando la obligacion no tiene registros asociados en el detalle para el ID de obligacion.

	DECLARE @I_RowID	  int,
			@B_Resultado  bit,
			@T_Message    nvarchar(4000)
	EXEC USP_Obligaciones_ObligacionDet_MigracionTP_U_Validar_44_PeriodoDetallePeriodoConceptoPorOblID @I_RowID, @B_Resultado output, @T_Message output
	SELECT @B_Resultado as resultado, @T_Message as mensaje
*/
BEGIN
	DECLARE @I_Observados int = 0
	DECLARE @I_ObservadosObl int = 0
	DECLARE @D_FecProceso datetime = GETDATE() 
	DECLARE @I_ObservID int = 40
	DECLARE @I_TablaID int = 5

	BEGIN TRANSACTION
	BEGIN TRY

		COMMIT TRANSACTION

		SET @B_Resultado = 1
		SET @T_Message = '{ ' +
							 'Type: "summary", ' + 
							 'Title: "Observados", ' + 
							 'Value: ' + CAST(@I_ObservadosObl AS varchar) +
						 '}' 
	END TRY
	BEGIN CATCH
		  IF (@@TRANCOUNT > 0)
		SET @B_Resultado = 0
		SET @T_Message = '[{ ' +
							 'Type: "error", ' + 
							 'Title: "Error", ' + 
							 'Value: "' + ERROR_MESSAGE() + ' (Linea: ' + CAST(ERROR_LINE() AS varchar(11)) + ')."'  +
						  '}]' 
	END CATCH
END
GO


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_Obligaciones_ObligacionDet_MigracionTP_U_Validar_49_MontoDetalleMontoCab')
	DROP PROCEDURE [dbo].[USP_Obligaciones_ObligacionDet_MigracionTP_U_Validar_49_MontoDetalleMontoCab]
GO


CREATE PROCEDURE [dbo].[USP_Obligaciones_ObligacionDet_MigracionTP_U_Validar_49_MontoDetalleMontoCab]	
(
	@I_ProcedenciaID tinyint,
	@T_Anio		  varchar(4),
	@B_Resultado  bit output,
	@T_Message	  nvarchar(4000) OUTPUT	
)
AS
/*
	DESCRIPCION: Marcar TR_Ec_Det con B_Migrable = 0 cuando la obligacion asociada tiene estado B_Migrable = 0.

	DECLARE	@B_Resultado  bit,
			@I_ProcedenciaID	tinyint = 2,
			@T_Anio				varchar(4) = '2016',
			@T_Message			nvarchar(4000)
	EXEC USP_Obligaciones_ObligacionDet_MigracionTP_U_Validar_49_MontoDetalleMontoCab @I_ProcedenciaID, @T_Anio, @B_Resultado output, @T_Message output
	SELECT @B_Resultado as resultado, @T_Message as mensaje
*/
BEGIN
	DECLARE @I_Observados int = 0
	DECLARE @I_ObservadosObl int = 0
	DECLARE @D_FecProceso datetime = GETDATE() 
	DECLARE @I_ObservID int = 25
	DECLARE @I_TablaID int = 4

	BEGIN TRANSACTION
	BEGIN TRY 


		COMMIT TRANSACTION;

		SET @B_Resultado = 1
		SET @T_Message = '{ ' +
							 'Type: "summary", ' + 
							 'Title: "Observados sin OblId", ' + 
							 'Value: ' + CAST(@I_Observados AS varchar) +
						 '}' 

	END TRY
	BEGIN CATCH
		  IF (@@TRANCOUNT > 0)
		SET @B_Resultado = 0
		SET @T_Message = '[{ ' +
							 'Type: "error", ' + 
							 'Title: "Error", ' + 
							 'Value: "' + ERROR_MESSAGE() + ' (Linea: ' + CAST(ERROR_LINE() AS varchar(11)) + ')."'  +
						  '}]' 
	END CATCH
END
GO


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_Obligaciones_ObligacionDet_MigracionTP_U_Validar_49_MontoDetalleMontoCabPorOblID')
	DROP PROCEDURE [dbo].[USP_Obligaciones_ObligacionDet_MigracionTP_U_Validar_49_MontoDetalleMontoCabPorOblID]
GO

CREATE PROCEDURE [dbo].[USP_Obligaciones_ObligacionDet_MigracionTP_U_Validar_49_MontoDetalleMontoCabPorOblID]
	@I_OblRowID	  int,
	@B_Resultado  bit output,
	@T_Message    nvarchar(4000) OUTPUT	
AS
/*
	DESCRIPCION: Marcar TR_Ec_Obl con B_Migrable = 0 cuando la obligacion no tiene registros asociados en el detalle para el ID de obligacion.

	DECLARE @I_OblRowID	  int,
			@B_Resultado  bit,
			@T_Message    nvarchar(4000)
	EXEC USP_Obligaciones_ObligacionDet_MigracionTP_U_Validar_49_MontoDetalleMontoCabPorOblID @I_OblRowID, @B_Resultado output, @T_Message output
	SELECT @B_Resultado as resultado, @T_Message as mensaje
*/
BEGIN
	DECLARE @I_Observados int = 0
	DECLARE @I_ObservadosObl int = 0
	DECLARE @D_FecProceso datetime = GETDATE() 
	DECLARE @I_ObservID int = 40
	DECLARE @I_TablaID int = 5

	BEGIN TRANSACTION
	BEGIN TRY

		COMMIT TRANSACTION

		SET @B_Resultado = 1
		SET @T_Message = '{ ' +
							 'Type: "summary", ' + 
							 'Title: "Observados", ' + 
							 'Value: ' + CAST(@I_ObservadosObl AS varchar) +
						 '}' 
	END TRY
	BEGIN CATCH
		  IF (@@TRANCOUNT > 0)
		SET @B_Resultado = 0
		SET @T_Message = '[{ ' +
							 'Type: "error", ' + 
							 'Title: "Error", ' + 
							 'Value: "' + ERROR_MESSAGE() + ' (Linea: ' + CAST(ERROR_LINE() AS varchar(11)) + ')."'  +
						  '}]' 
	END CATCH
END
GO


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_Obligaciones_ObligacionDet_MigracionTP_U_Validar_58_SinObligacionCabID')
	DROP PROCEDURE [dbo].[USP_Obligaciones_ObligacionDet_MigracionTP_U_Validar_58_SinObligacionCabID]
GO


CREATE PROCEDURE [dbo].[USP_Obligaciones_ObligacionDet_MigracionTP_U_Validar_58_SinObligacionCabID]	
(
	@I_ProcedenciaID tinyint,
	@T_Anio		  varchar(4),
	@B_Resultado  bit output,
	@T_Message	  nvarchar(4000) OUTPUT	
)
AS
/*
	DESCRIPCION: Marcar TR_Ec_Det con B_Migrable = 0 cuando NO tiene asociada un ID de obligacion.

	DECLARE	@I_ProcedenciaID	tinyint = 2,
			@T_Anio				varchar(4) = '2016',
			@B_Resultado  bit,
			@T_Message			nvarchar(4000)
	EXEC USP_Obligaciones_ObligacionDet_MigracionTP_U_Validar_58_ObligacionCabID @I_ProcedenciaID, @T_Anio, @B_Resultado output, @T_Message output
	SELECT @B_Resultado as resultado, @T_Message as mensaje
*/
BEGIN
	DECLARE @I_Observados int = 0
	DECLARE @I_ObservadosObl int = 0
	DECLARE @D_FecProceso datetime = GETDATE() 
	DECLARE @I_ObservID int = 58
	DECLARE @I_TablaID int = 4

	BEGIN TRANSACTION
	BEGIN TRY 


		COMMIT TRANSACTION;

		SET @B_Resultado = 1
		SET @T_Message = '{ ' +
							 'Type: "summary", ' + 
							 'Title: "Observados sin OblId", ' + 
							 'Value: ' + CAST(@I_Observados AS varchar) +
						 '}' 

	END TRY
	BEGIN CATCH
		  IF (@@TRANCOUNT > 0)
		SET @B_Resultado = 0
		SET @T_Message = '[{ ' +
							 'Type: "error", ' + 
							 'Title: "Error", ' + 
							 'Value: "' + ERROR_MESSAGE() + ' (Linea: ' + CAST(ERROR_LINE() AS varchar(11)) + ')."'  +
						  '}]' 
	END CATCH
END
GO



