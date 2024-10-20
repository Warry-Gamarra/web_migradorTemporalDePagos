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
			@T_Anio		  varchar(4) = '2010',
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
			INSERT (I_ObservID, I_TablaID, I_FilaTablaID, D_FecRegistro, I_ProcedenciaID, B_ObligProc)
			VALUES (SRC.I_ObservID, SRC.I_TablaID, SRC.I_FilaTablaID, SRC.D_FecRegistro, @I_ProcedenciaID, 1);


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
			INSERT (I_ObservID, I_TablaID, I_FilaTablaID, D_FecRegistro, I_ProcedenciaID, B_ObligProc)
			VALUES (SRC.I_ObservID, SRC.I_TablaID, SRC.I_FilaTablaID, SRC.D_FecRegistro, SRC.I_ProcedenciaID, 1);


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

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_U_ValidarAnioEnDetalleObligacion')
	DROP PROCEDURE [dbo].[USP_U_ValidarAnioEnDetalleObligacion]
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
			INSERT (I_ObservID, I_TablaID, I_FilaTablaID, D_FecRegistro, I_ProcedenciaID, B_ObligProc)
			VALUES (SRC.I_ObservID, SRC.I_TablaID, SRC.I_FilaTablaID, SRC.D_FecRegistro, @I_ProcedenciaID, 1);


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
			INSERT (I_ObservID, I_TablaID, I_FilaTablaID, D_FecRegistro, I_ProcedenciaID, B_ObligProc)
			VALUES (SRC.I_ObservID, SRC.I_TablaID, SRC.I_FilaTablaID, SRC.D_FecRegistro, SRC.I_ProcedenciaID, 1);


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

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_U_ValidarPeriodoEnDetalleObligacion')
	DROP PROCEDURE [dbo].[USP_U_ValidarPeriodoEnDetalleObligacion]
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
		WHEN MATCHED AND TRG.I_ProcedenciaID = @I_ProcedenciaID THEN
			UPDATE SET D_FecRegistro = SRC.D_FecRegistro
		WHEN NOT MATCHED BY TARGET THEN
			INSERT (I_ObservID, I_TablaID, I_FilaTablaID, D_FecRegistro, I_ProcedenciaID, B_ObligProc)
			VALUES (SRC.I_ObservID, SRC.I_TablaID, SRC.I_FilaTablaID, SRC.D_FecRegistro, @I_ProcedenciaID, 1);


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
			INSERT (I_ObservID, I_TablaID, I_FilaTablaID, D_FecRegistro, I_ProcedenciaID, B_ObligProc)
			VALUES (SRC.I_ObservID, SRC.I_TablaID, SRC.I_FilaTablaID, SRC.D_FecRegistro, SRC.I_ProcedenciaID, 1);


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
			INSERT (I_ObservID, I_TablaID, I_FilaTablaID, D_FecRegistro, I_ProcedenciaID, B_ObligProc)
			VALUES (SRC.I_ObservID, SRC.I_TablaID, SRC.I_FilaTablaID, SRC.D_FecRegistro, @I_ProcedenciaID, 1);


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
			INSERT (I_ObservID, I_TablaID, I_FilaTablaID, D_FecRegistro, I_ProcedenciaID, B_ObligProc)
			VALUES (SRC.I_ObservID, SRC.I_TablaID, SRC.I_FilaTablaID, SRC.D_FecRegistro, SRC.I_ProcedenciaID, 1);


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

	DECLARE @I_ProcedenciaID	tinyint = 1,
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
			INSERT (I_ObservID, I_TablaID, I_FilaTablaID, D_FecRegistro, I_ProcedenciaID, B_ObligProc)
			VALUES (SRC.I_ObservID, SRC.I_TablaID, SRC.I_FilaTablaID, SRC.D_FecRegistro, @I_ProcedenciaID, 1);


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
			INSERT (I_ObservID, I_TablaID, I_FilaTablaID, D_FecRegistro, I_ProcedenciaID, B_ObligProc)
			VALUES (SRC.I_ObservID, SRC.I_TablaID, SRC.I_FilaTablaID, SRC.D_FecRegistro, SRC.I_ProcedenciaID, 1);


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
			INSERT (I_ObservID, I_TablaID, I_FilaTablaID, D_FecRegistro, I_ProcedenciaID, B_ObligProc)
			VALUES (SRC.I_ObservID, SRC.I_TablaID, SRC.I_FilaTablaID, SRC.D_FecRegistro, @I_ProcedenciaID, 1);


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
			INSERT (I_ObservID, I_TablaID, I_FilaTablaID, D_FecRegistro, I_ProcedenciaID, B_ObligProc)
			VALUES (SRC.I_ObservID, SRC.I_TablaID, SRC.I_FilaTablaID, SRC.D_FecRegistro, SRC.I_ProcedenciaID, 1);


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
			INSERT (I_ObservID, I_TablaID, I_FilaTablaID, D_FecRegistro, I_ProcedenciaID, B_ObligProc)
			VALUES (SRC.I_ObservID, SRC.I_TablaID, SRC.I_FilaTablaID, SRC.D_FecRegistro, @I_ProcedenciaID, 1);


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
			INSERT (I_ObservID, I_TablaID, I_FilaTablaID, D_FecRegistro, I_ProcedenciaID, B_ObligProc)
			VALUES (SRC.I_ObservID, SRC.I_TablaID, SRC.I_FilaTablaID, SRC.D_FecRegistro, SRC.I_ProcedenciaID, 1);


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
			INSERT (I_ObservID, I_TablaID, I_FilaTablaID, D_FecRegistro, I_ProcedenciaID, B_ObligProc)
			VALUES (SRC.I_ObservID, SRC.I_TablaID, SRC.I_FilaTablaID, SRC.D_FecRegistro, @I_ProcedenciaID, 1);


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
			INSERT (I_ObservID, I_TablaID, I_FilaTablaID, D_FecRegistro, I_ProcedenciaID, B_ObligProc)
			VALUES (SRC.I_ObservID, SRC.I_TablaID, SRC.I_FilaTablaID, SRC.D_FecRegistro, SRC.I_ProcedenciaID, 1);


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
			INSERT (I_ObservID, I_TablaID, I_FilaTablaID, D_FecRegistro, I_ProcedenciaID, B_ObligProc)
			VALUES (SRC.I_ObservID, SRC.I_TablaID, SRC.I_FilaTablaID, SRC.D_FecRegistro, SRC.I_ProcedenciaID, 1);


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
			INSERT (I_ObservID, I_TablaID, I_FilaTablaID, D_FecRegistro, I_ProcedenciaID, B_ObligProc)
			VALUES (SRC.I_ObservID, SRC.I_TablaID, SRC.I_FilaTablaID, SRC.D_FecRegistro, SRC.I_ProcedenciaID, 1);


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
			@I_ObservID_PerDes int = 44,
			@I_ObservID_PerPri int = 17
	
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
		 WHERE OBS.I_ObservID IN (@I_ObservID_PerDes, @I_ObservID_PerPri)
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
			INSERT (I_ObservID, I_TablaID, I_FilaTablaID, D_FecRegistro, I_ProcedenciaID, B_ObligProc)
			VALUES (SRC.I_ObservID, SRC.I_TablaID, SRC.I_FilaTablaID, SRC.D_FecRegistro, SRC.I_ProcedenciaID, 1);


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
			INSERT (I_ObservID, I_TablaID, I_FilaTablaID, D_FecRegistro, I_ProcedenciaID, B_ObligProc)
			VALUES (SRC.I_ObservID, SRC.I_TablaID, SRC.I_FilaTablaID, SRC.D_FecRegistro, SRC.I_ProcedenciaID, 1);


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
		WHEN NOT MATCHED BY TARGET THEN
			INSERT (I_ObservID, I_TablaID, I_FilaTablaID, D_FecRegistro, I_ProcedenciaID, B_ObligProc)
			VALUES (SRC.I_ObservID, SRC.I_TablaID, SRC.I_FilaTablaID, SRC.D_FecRegistro, @I_ProcedenciaID, 1);


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
		WHEN NOT MATCHED BY TARGET THEN
			INSERT (I_ObservID, I_TablaID, I_FilaTablaID, D_FecRegistro, I_ProcedenciaID, B_ObligProc)
			VALUES (SRC.I_ObservID, SRC.I_TablaID, SRC.I_FilaTablaID, SRC.D_FecRegistro, SRC.I_ProcedenciaID, 1);


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
		  INTO	#temp_det_count_rows
		  FROM  TR_Ec_Det 
		 WHERE  Ano = @T_Anio 
		 		AND I_ProcedenciaID = @I_ProcedenciaID 
		GROUP BY I_OblRowID
		HAVING  COUNT(I_RowID) > 0


		UPDATE	Obl
		SET		B_Migrable = 0,
				D_FecEvalua = @D_FecProceso
		FROM    TR_Ec_Obl Obl
				LEFT JOIN #temp_det_count_rows tmp ON Obl.I_RowID = tmp.I_OblRowID
		WHERE	Obl.Ano = @T_Anio
				AND Obl.I_ProcedenciaID = @I_ProcedenciaID
				AND tmp.I_OblRowID IS NULL
					

		MERGE  TI_ObservacionRegistroTabla AS TRG
		USING  (SELECT @I_ObservID AS I_ObservID, @I_TablaID AS I_TablaID, Obl.I_RowID AS I_FilaTablaID, @D_FecProceso AS D_FecRegistro 
				  FROM TR_Ec_Obl Obl
					   LEFT JOIN #temp_det_count_rows tmp ON Obl.I_RowID = tmp.I_OblRowID
				 WHERE Obl.Ano = @T_Anio
					   AND Obl.I_ProcedenciaID = @I_ProcedenciaID
					   AND tmp.I_OblRowID IS NULL
				) AS SRC
		ON TRG.I_ObservID = SRC.I_ObservID AND TRG.I_TablaID = SRC.I_TablaID AND TRG.I_FilaTablaID = SRC.I_FilaTablaID
		WHEN MATCHED AND TRG.I_ProcedenciaID = @I_ProcedenciaID THEN
			UPDATE SET D_FecRegistro = SRC.D_FecRegistro
		WHEN NOT MATCHED BY TARGET THEN
			INSERT (I_ObservID, I_TablaID, I_FilaTablaID, D_FecRegistro, I_ProcedenciaID, B_ObligProc)
			VALUES (SRC.I_ObservID, SRC.I_TablaID, SRC.I_FilaTablaID, SRC.D_FecRegistro, @I_ProcedenciaID, 1);


		UPDATE OBS
		   SET D_FecResuelto = @D_FecProceso,
		   	   B_Resuelto = 1
		  FROM TI_ObservacionRegistroTabla OBS
		  	   INNER JOIN (SELECT Obl.I_RowID, Obl.I_ProcedenciaID, tmp.I_OblRowID as TempRowID
			   				 FROM TR_Ec_Obl Obl
							      LEFT JOIN #temp_det_count_rows tmp ON Obl.I_RowID = tmp.I_OblRowID
							WHERE Obl.Ano = @T_Anio
								  AND Obl.I_ProcedenciaID = @I_ProcedenciaID
								  AND tmp.I_OblRowID IS NULL
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

		SELECT  I_OblRowID, COUNT(I_RowID) AS count_det
		  INTO	#temp_det_count_rows
		  FROM  TR_Ec_Det 
		GROUP BY I_OblRowID
		HAVING  COUNT(I_RowID) > 0


		UPDATE	Obl
		SET		B_Migrable = 0,
				D_FecEvalua = @D_FecProceso
		FROM    TR_Ec_Obl Obl
				LEFT JOIN #temp_det_count_rows tmp ON Obl.I_RowID = tmp.I_OblRowID
		WHERE	Obl.I_RowID = @I_RowID
				AND tmp.I_OblRowID IS NULL
					

		MERGE  TI_ObservacionRegistroTabla AS TRG
		USING  (SELECT @I_ObservID AS I_ObservID, @I_TablaID AS I_TablaID, Obl.I_RowID AS I_FilaTablaID, 
					   @D_FecProceso AS D_FecRegistro, Obl.I_ProcedenciaID
				  FROM TR_Ec_Obl Obl
					   LEFT JOIN #temp_det_count_rows tmp ON Obl.I_RowID = tmp.I_OblRowID
				 WHERE Obl.I_RowID = @I_RowID
					   AND tmp.I_OblRowID IS NULL
				) AS SRC
		ON TRG.I_ObservID = SRC.I_ObservID AND TRG.I_TablaID = SRC.I_TablaID AND TRG.I_FilaTablaID = SRC.I_FilaTablaID
		WHEN MATCHED AND TRG.I_ProcedenciaID = SRC.I_ProcedenciaID THEN
			UPDATE SET D_FecRegistro = SRC.D_FecRegistro
		WHEN NOT MATCHED BY TARGET THEN
			INSERT (I_ObservID, I_TablaID, I_FilaTablaID, D_FecRegistro, I_ProcedenciaID, B_ObligProc)
			VALUES (SRC.I_ObservID, SRC.I_TablaID, SRC.I_FilaTablaID, SRC.D_FecRegistro, SRC.I_ProcedenciaID, 1);


		UPDATE OBS
		   SET D_FecResuelto = @D_FecProceso,
		   	   B_Resuelto = 1
		  FROM TI_ObservacionRegistroTabla OBS
		  	   INNER JOIN (SELECT Obl.I_RowID, Obl.I_ProcedenciaID, tmp.I_OblRowID as TempRowID
			   				 FROM TR_Ec_Obl Obl
							      LEFT JOIN #temp_det_count_rows tmp ON Obl.I_RowID = tmp.I_OblRowID
							WHERE Obl.I_RowID = @I_RowID
								  AND tmp.I_OblRowID IS NULL
			   			  ) OBL ON OBS.I_FilaTablaID = OBL.I_RowID
						  		   AND OBS.I_ProcedenciaID = OBL.I_ProcedenciaID 
		 WHERE OBS.I_ObservID = @I_ObservID 
		 	   AND OBS.I_TablaID = @I_TablaID 
			   AND OBS.I_FilaTablaID = @I_RowID 
		

		SET @I_Observados = (SELECT COUNT(*) 
							   FROM TI_ObservacionRegistroTabla OBS 
									INNER JOIN TR_Ec_Obl OBL ON OBS.I_FilaTablaID = OBL.I_RowID 
																AND OBL.I_ProcedenciaID = OBS.I_ProcedenciaID
							  WHERE OBS.I_ObservID = @I_ObservID 
									AND OBL.I_RowID = @I_RowID 
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



IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_54_PagoEnObligacionNoPagado')
	DROP PROCEDURE [dbo].[USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_54_PagoEnObligacionNoPagado]
GO

CREATE PROCEDURE [dbo].[USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_54_PagoEnObligacionNoPagado]
	@I_ProcedenciaID tinyint,
	@T_Anio			 varchar(4) = NULL,
	@B_Resultado	 bit output,
	@T_Message		 nvarchar(4000) OUTPUT	
AS
/*
	DESCRIPCION: Marcar TR_Ec_Obl con B_Migrable = 0 cuando se encontró un pago activo para la obligación con estado Pagado = NO para el año y procedencia.

	DECLARE @I_ProcedenciaID tinyint = 1, 
			@T_Anio		  	 varchar(4) = '2010',
			@B_Resultado  	 bit,
			@T_Message    	 nvarchar(4000)
	EXEC USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_54_PagoEnObligacionNoPagado @I_ProcedenciaID, @T_Anio, @B_Resultado output, @T_Message output
	SELECT @B_Resultado as resultado, @T_Message as mensaje
*/
BEGIN
	DECLARE @I_Observados int = 0
	DECLARE @D_FecProceso datetime = GETDATE() 
	DECLARE @I_ObservID int = 40
	DECLARE @I_TablaID int = 5

	BEGIN TRANSACTION
	BEGIN TRY

		SELECT  Obl.I_RowID
		  INTO	#temp_obl_pagado_no_con_pagos
		  FROM  TR_Ec_Obl Obl
		  		INNER JOIN TR_Ec_Det_Pagos Det_pg ON Obl.I_RowID = Det_pg.I_OblRowID
		 WHERE  Obl.Ano = @T_Anio 
		 		AND Obl.I_ProcedenciaID = @I_ProcedenciaID
				AND Obl.Pagado = 0
				AND Det_pg.Eliminado = 0			

		UPDATE	Obl
		SET		B_Migrable = 0,
				D_FecEvalua = @D_FecProceso
		FROM    TR_Ec_Obl Obl
				INNER JOIN #temp_obl_pagado_no_con_pagos tmp ON Obl.I_RowID = tmp.I_RowID
					

		MERGE  TI_ObservacionRegistroTabla AS TRG
		USING  (SELECT @I_ObservID AS I_ObservID, @I_TablaID AS I_TablaID, Obl.I_RowID AS I_FilaTablaID, @D_FecProceso AS D_FecRegistro 
				  FROM TR_Ec_Obl Obl
					   INNER JOIN #temp_obl_pagado_no_con_pagos tmp ON Obl.I_RowID = tmp.I_RowID
				) AS SRC
		ON TRG.I_ObservID = SRC.I_ObservID AND TRG.I_TablaID = SRC.I_TablaID AND TRG.I_FilaTablaID = SRC.I_FilaTablaID
		WHEN MATCHED AND TRG.I_ProcedenciaID = @I_ProcedenciaID THEN
			UPDATE SET D_FecRegistro = SRC.D_FecRegistro
		WHEN NOT MATCHED BY TARGET THEN
			INSERT (I_ObservID, I_TablaID, I_FilaTablaID, D_FecRegistro, I_ProcedenciaID, B_ObligProc)
			VALUES (SRC.I_ObservID, SRC.I_TablaID, SRC.I_FilaTablaID, SRC.D_FecRegistro, @I_ProcedenciaID, 1);


		UPDATE OBS
		   SET D_FecResuelto = @D_FecProceso,
		   	   B_Resuelto = 1
		  FROM TI_ObservacionRegistroTabla OBS
		  	   INNER JOIN (SELECT Obl.I_RowID, Obl.I_ProcedenciaID, tmp.I_RowID as TempRowID
			   				 FROM TR_Ec_Obl Obl
							      LEFT JOIN #temp_obl_pagado_no_con_pagos tmp ON Obl.I_RowID = tmp.I_RowID
							WHERE Obl.Ano = @T_Anio
								  AND Obl.I_ProcedenciaID = @I_ProcedenciaID
								  AND tmp.I_RowID IS NULL
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


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_54_PagoEnObligacionNoPagadoPorOblID')
	DROP PROCEDURE [dbo].[USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_54_PagoEnObligacionNoPagadoPorOblID]
GO

CREATE PROCEDURE [dbo].[USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_54_PagoEnObligacionNoPagadoPorOblID]
	@I_RowID	  int,
	@B_Resultado  bit output,
	@T_Message    nvarchar(4000) OUTPUT	
AS
/*
	DESCRIPCION: Marcar TR_Ec_Obl con B_Migrable = 0 cuando se encontró un pago activo para la obligación con estado Pagado = NO para el ID de obligacion.

	DECLARE @I_RowID	  int,
			@B_Resultado  bit,
			@T_Message    nvarchar(4000)
	EXEC USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_54_PagoEnObligacionNoPagadoPorOblID @I_RowID, @B_Resultado output, @T_Message output
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

		SELECT  Obl.I_RowID
		  INTO	#temp_obl_pagado_no_con_pagos
		  FROM  TR_Ec_Obl Obl
		  		INNER JOIN TR_Ec_Det_Pagos Det_pg ON Obl.I_RowID = Det_pg.I_OblRowID
		 WHERE  Obl.I_RowID = @I_RowID
				AND Obl.Pagado = 0
				AND Det_pg.Eliminado = 0			

		UPDATE	Obl
		   SET	B_Migrable = 0,
				D_FecEvalua = @D_FecProceso
		  FROM  TR_Ec_Obl Obl
				INNER JOIN #temp_obl_pagado_no_con_pagos tmp ON Obl.I_RowID = tmp.I_RowID					

		MERGE  TI_ObservacionRegistroTabla AS TRG
		USING  (SELECT @I_ObservID AS I_ObservID, @I_TablaID AS I_TablaID, Obl.I_RowID AS I_FilaTablaID, 
					   @D_FecProceso AS D_FecRegistro, Obl.I_ProcedenciaID
				  FROM TR_Ec_Obl Obl
					   INNER JOIN #temp_obl_pagado_no_con_pagos tmp ON Obl.I_RowID = tmp.I_RowID
			   ) AS SRC
		ON TRG.I_ObservID = SRC.I_ObservID AND TRG.I_TablaID = SRC.I_TablaID AND TRG.I_FilaTablaID = SRC.I_FilaTablaID
		WHEN MATCHED AND TRG.I_ProcedenciaID = SRC.I_ProcedenciaID THEN
			UPDATE SET D_FecRegistro = SRC.D_FecRegistro
		WHEN NOT MATCHED BY TARGET THEN
			INSERT (I_ObservID, I_TablaID, I_FilaTablaID, D_FecRegistro, I_ProcedenciaID, B_ObligProc)
			VALUES (SRC.I_ObservID, SRC.I_TablaID, SRC.I_FilaTablaID, SRC.D_FecRegistro, SRC.I_ProcedenciaID, 1);


		UPDATE OBS
		   SET D_FecResuelto = @D_FecProceso,
		   	   B_Resuelto = 1
		  FROM TI_ObservacionRegistroTabla OBS
		  	   INNER JOIN (SELECT Obl.I_RowID, Obl.I_ProcedenciaID, tmp.I_RowID as TempRowID
			   				 FROM TR_Ec_Obl Obl
							      LEFT JOIN #temp_obl_pagado_no_con_pagos tmp ON Obl.I_RowID = tmp.I_RowID
							WHERE Obl.I_RowID = @I_RowID
								  AND tmp.I_RowID IS NULL
			   			  ) OBL ON OBS.I_FilaTablaID = OBL.I_RowID
						  		   AND OBS.I_ProcedenciaID = OBL.I_ProcedenciaID 
		 WHERE OBS.I_ObservID = @I_ObservID 
		 	   AND OBS.I_TablaID = @I_TablaID 
			   AND OBS.I_FilaTablaID = @I_RowID 
		

		SET @I_Observados = (SELECT COUNT(*) 
							   FROM TI_ObservacionRegistroTabla OBS 
									INNER JOIN TR_Ec_Obl OBL ON OBS.I_FilaTablaID = OBL.I_RowID 
																AND OBL.I_ProcedenciaID = OBS.I_ProcedenciaID
							  WHERE OBS.I_ObservID = @I_ObservID 
									AND OBL.I_RowID = @I_RowID 
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



/*	
	===============================================================================================
		Validaciones para migracion de ec_det (solo obligaciones de pago)	
	===============================================================================================
*/ 



IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_Obligaciones_ObligacionDet_MigracionTP_U_Validar_15_AnioDetalleAnioConcepto')
	DROP PROCEDURE [dbo].[USP_Obligaciones_ObligacionDet_MigracionTP_U_Validar_15_AnioDetalleAnioConcepto]
GO


CREATE PROCEDURE [dbo].[USP_Obligaciones_ObligacionDet_MigracionTP_U_Validar_15_AnioDetalleAnioConcepto]	
(
	@I_ProcedenciaID tinyint,
	@T_Anio		  varchar(4),
	@B_Resultado  bit output,
	@T_Message	  nvarchar(4000) OUTPUT	
)
AS
/*
	DESCRIPCION: Marcar TR_Ec_Det con B_Migrable = 0 cuando el año del concepto en el detalle no coincide con el año del concepto en cp_pri.

	DECLARE	@B_Resultado  bit,
			@I_ProcedenciaID	tinyint = 2,
			@T_Anio				varchar(4) = '2016',
			@T_Message			nvarchar(4000)
	EXEC USP_Obligaciones_ObligacionDet_MigracionTP_U_Validar_15_AnioDetalleAnioConcepto @I_ProcedenciaID, @T_Anio, @B_Resultado output, @T_Message output
	SELECT @B_Resultado as resultado, @T_Message as mensaje
*/
BEGIN
	DECLARE @I_Observados int = 0
	DECLARE @D_FecProceso datetime = GETDATE() 
	DECLARE @I_ObservID int = 15
	DECLARE @I_TablaID int = 4

	BEGIN TRANSACTION
	BEGIN TRY 
		SELECT	Det.I_RowID 
		INTO	#temp_detalle_anio_no_anio_concepto
		FROM	TR_Ec_Det Det
				INNER JOIN TR_Cp_Pri Pri ON Det.Concepto = Pri.Id_cp
		WHERE	Det.Ano <> Pri.Ano

		UPDATE Det
		SET	B_Migrable = 0,
			D_FecEvalua = @D_FecProceso
		FROM TR_Ec_Det Det 
			 INNER JOIN #temp_detalle_anio_no_anio_concepto tmp ON tmp.I_RowID = Det.I_RowID
		WHERE Ano = @T_Anio
			  AND I_ProcedenciaID = @I_ProcedenciaID

		MERGE TI_ObservacionRegistroTabla AS TRG
		USING (SELECT @I_ObservID AS I_ObservID, @I_TablaID AS I_TablaID, Det.I_RowID AS I_FilaTablaID, @D_FecProceso AS D_FecRegistro 
				 FROM TR_Ec_Det Det
					  INNER JOIN #temp_detalle_anio_no_anio_concepto tmp ON tmp.I_RowID = Det.I_RowID
				WHERE Ano = @T_Anio
					  AND I_ProcedenciaID = @I_ProcedenciaID
			  ) AS SRC
		ON TRG.I_ObservID = SRC.I_ObservID AND TRG.I_TablaID = SRC.I_TablaID AND TRG.I_FilaTablaID = SRC.I_FilaTablaID
		WHEN MATCHED AND TRG.I_ProcedenciaID = @I_ProcedenciaID THEN
			UPDATE SET D_FecRegistro = SRC.D_FecRegistro
		WHEN NOT MATCHED BY TARGET THEN
			INSERT (I_ObservID, I_TablaID, I_FilaTablaID, D_FecRegistro, I_ProcedenciaID, B_ObligProc)
			VALUES (SRC.I_ObservID, SRC.I_TablaID, SRC.I_FilaTablaID, SRC.D_FecRegistro, @I_ProcedenciaID, 1);		

		UPDATE OBS
		   SET D_FecResuelto = @D_FecProceso,
		   	   B_Resuelto = 1
		  FROM TI_ObservacionRegistroTabla OBS
		  	   INNER JOIN (SELECT Det.I_RowID, Det.I_ProcedenciaID, tmp.I_RowID as TempRowID
			   				 FROM TR_Ec_Det Det
								  LEFT JOIN #temp_detalle_anio_no_anio_concepto tmp ON tmp.I_RowID = Det.I_RowID
							WHERE tmp.I_RowID IS NULL
								  AND Ano = @T_Anio
								  AND I_ProcedenciaID = @I_ProcedenciaID
			   			  ) DET ON OBS.I_FilaTablaID = DET.I_RowID
						  		   AND OBS.I_ProcedenciaID = DET.I_ProcedenciaID 
		 WHERE OBS.I_ObservID = @I_ObservID 
		 	   AND OBS.I_TablaID = @I_TablaID 
			   AND OBS.I_ProcedenciaID = @I_ProcedenciaID
		

		SET @I_Observados = (SELECT COUNT(*) 
							   FROM TI_ObservacionRegistroTabla OBS 
									INNER JOIN TR_Ec_Det DET ON OBS.I_FilaTablaID = DET.I_RowID 
																AND DET.I_ProcedenciaID = OBS.I_ProcedenciaID
							  WHERE OBS.I_ObservID = @I_ObservID 
									AND DET.Ano = @T_Anio
									AND DET.I_ProcedenciaID = @I_ProcedenciaID 
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


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_Obligaciones_ObligacionDet_MigracionTP_U_Validar_15_AnioDetalleAnioConceptoPorOblID')
	DROP PROCEDURE [dbo].[USP_Obligaciones_ObligacionDet_MigracionTP_U_Validar_15_AnioDetalleAnioConceptoPorOblID]
GO

CREATE PROCEDURE [dbo].[USP_Obligaciones_ObligacionDet_MigracionTP_U_Validar_15_AnioDetalleAnioConceptoPorOblID]
	@I_OblRowID	  int,
	@B_Resultado  bit output,
	@T_Message    nvarchar(4000) OUTPUT	
AS
/*
	DESCRIPCION: Marcar TR_Ec_Obl con B_Migrable = 0 cuando el año del concepto en el detalle no coincide con el año del concepto en cp_pri para el ID de obligacion.

	DECLARE @I_OblRowID	  int,
			@B_Resultado  bit,
			@T_Message    nvarchar(4000)
	EXEC USP_Obligaciones_ObligacionDet_MigracionTP_U_Validar_15_AnioDetalleAnioConceptoPorOblID @I_OblRowID, @B_Resultado output, @T_Message output
	SELECT @B_Resultado as resultado, @T_Message as mensaje
*/
BEGIN
	DECLARE @I_Observados int = 0
	DECLARE @D_FecProceso datetime = GETDATE() 
	DECLARE @I_ObservID int = 15
	DECLARE @I_TablaID int = 4

	BEGIN TRANSACTION
	BEGIN TRY
		SELECT	Det.I_RowID 
		INTO	#temp_detalle_anio_no_anio_concepto
		FROM	TR_Ec_Det Det
				INNER JOIN TR_Cp_Pri Pri ON Det.Concepto = Pri.Id_cp
		WHERE	Det.Ano <> Pri.Ano

		UPDATE Det
		SET	B_Migrable = 0,
			D_FecEvalua = @D_FecProceso
		FROM TR_Ec_Det Det 
			 INNER JOIN #temp_detalle_anio_no_anio_concepto tmp ON tmp.I_RowID = Det.I_RowID
		WHERE I_OblRowID = @I_OblRowID

		MERGE TI_ObservacionRegistroTabla AS TRG
		USING (SELECT @I_ObservID AS I_ObservID, @I_TablaID AS I_TablaID, Det.I_RowID AS I_FilaTablaID, 
					  @D_FecProceso AS D_FecRegistro, Det.I_ProcedenciaID  
				 FROM TR_Ec_Det Det
					  INNER JOIN #temp_detalle_anio_no_anio_concepto tmp ON tmp.I_RowID = Det.I_RowID
				WHERE I_OblRowID = @I_OblRowID
			  ) AS SRC
		ON TRG.I_ObservID = SRC.I_ObservID AND TRG.I_TablaID = SRC.I_TablaID AND TRG.I_FilaTablaID = SRC.I_FilaTablaID
		WHEN MATCHED AND TRG.I_ProcedenciaID = SRC.I_ProcedenciaID THEN
			UPDATE SET D_FecRegistro = SRC.D_FecRegistro
		WHEN NOT MATCHED BY TARGET THEN
			INSERT (I_ObservID, I_TablaID, I_FilaTablaID, D_FecRegistro, I_ProcedenciaID, B_ObligProc)
			VALUES (SRC.I_ObservID, SRC.I_TablaID, SRC.I_FilaTablaID, SRC.D_FecRegistro, SRC.I_ProcedenciaID, 1);		

		UPDATE OBS
		   SET D_FecResuelto = @D_FecProceso,
		   	   B_Resuelto = 1
		  FROM TI_ObservacionRegistroTabla OBS
		  	   INNER JOIN (SELECT Det.I_RowID, Det.I_ProcedenciaID, tmp.I_RowID as TempRowID
			   				 FROM TR_Ec_Det Det
								  LEFT JOIN #temp_detalle_anio_no_anio_concepto tmp ON tmp.I_RowID = Det.I_RowID
							WHERE tmp.I_RowID IS NULL
								  AND I_OblRowID = @I_OblRowID
			   			  ) DET ON OBS.I_FilaTablaID = DET.I_RowID
						  		   AND OBS.I_ProcedenciaID = DET.I_ProcedenciaID 
		 WHERE OBS.I_ObservID = @I_ObservID 
		 	   AND OBS.I_TablaID = @I_TablaID 
		

		SET @I_Observados = (SELECT COUNT(*) 
							   FROM TI_ObservacionRegistroTabla OBS 
									INNER JOIN TR_Ec_Det DET ON OBS.I_FilaTablaID = DET.I_RowID 
																AND DET.I_ProcedenciaID = OBS.I_ProcedenciaID
							  WHERE OBS.I_ObservID = @I_ObservID 
									AND DET.I_OblRowID = @I_OblRowID  
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


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_Obligaciones_ObligacionDet_MigracionTP_U_Validar_17_PeriodoDetallePeriodoConcepto')
	DROP PROCEDURE [dbo].[USP_Obligaciones_ObligacionDet_MigracionTP_U_Validar_17_PeriodoDetallePeriodoConcepto]
GO


CREATE PROCEDURE [dbo].[USP_Obligaciones_ObligacionDet_MigracionTP_U_Validar_17_PeriodoDetallePeriodoConcepto]	
(
	@I_ProcedenciaID tinyint,
	@T_Anio		  varchar(4),
	@B_Resultado  bit output,
	@T_Message	  nvarchar(4000) OUTPUT	
)
AS
/*
	DESCRIPCION: Marcar TR_Ec_Det con B_Migrable = 0 cuando el periodo del concepto en el detalle no coincide con el periodo del concepto en cp_pri.

	DECLARE	@B_Resultado  bit,
			@I_ProcedenciaID	tinyint = 2,
			@T_Anio				varchar(4) = '2016',
			@T_Message			nvarchar(4000)
	EXEC USP_Obligaciones_ObligacionDet_MigracionTP_U_Validar_17_PeriodoDetallePeriodoConcepto @I_ProcedenciaID, @T_Anio, @B_Resultado output, @T_Message output
	SELECT @B_Resultado as resultado, @T_Message as mensaje
*/
BEGIN
	DECLARE @I_Observados int = 0
	DECLARE @D_FecProceso datetime = GETDATE() 
	DECLARE @I_ObservID int = 17
	DECLARE @I_TablaID int = 4

	BEGIN TRANSACTION
	BEGIN TRY 
		SELECT	Det.I_RowID 
		INTO	#temp_detalle_periodo_no_periodo_concepto
		FROM	TR_Ec_Det Det
				INNER JOIN TR_Cp_Pri Pri ON Det.Concepto = Pri.Id_cp
		WHERE	Det.P <> Pri.P

		UPDATE Det
		SET	B_Migrable = 0,
			D_FecEvalua = @D_FecProceso
		FROM TR_Ec_Det Det 
			 INNER JOIN #temp_detalle_periodo_no_periodo_concepto tmp ON tmp.I_RowID = Det.I_RowID
		WHERE Ano = @T_Anio
			  AND I_ProcedenciaID = @I_ProcedenciaID

		MERGE TI_ObservacionRegistroTabla AS TRG
		USING (SELECT @I_ObservID AS I_ObservID, @I_TablaID AS I_TablaID, Det.I_RowID AS I_FilaTablaID, @D_FecProceso AS D_FecRegistro 
				 FROM TR_Ec_Det Det
					  INNER JOIN #temp_detalle_periodo_no_periodo_concepto tmp ON tmp.I_RowID = Det.I_RowID
				WHERE Ano = @T_Anio
					  AND I_ProcedenciaID = @I_ProcedenciaID
			  ) AS SRC
		ON TRG.I_ObservID = SRC.I_ObservID AND TRG.I_TablaID = SRC.I_TablaID AND TRG.I_FilaTablaID = SRC.I_FilaTablaID
		WHEN MATCHED AND TRG.I_ProcedenciaID = @I_ProcedenciaID THEN
			UPDATE SET D_FecRegistro = SRC.D_FecRegistro
		WHEN NOT MATCHED BY TARGET THEN
			INSERT (I_ObservID, I_TablaID, I_FilaTablaID, D_FecRegistro, I_ProcedenciaID, B_ObligProc)
			VALUES (SRC.I_ObservID, SRC.I_TablaID, SRC.I_FilaTablaID, SRC.D_FecRegistro, @I_ProcedenciaID, 1);		

		UPDATE OBS
		   SET D_FecResuelto = @D_FecProceso,
		   	   B_Resuelto = 1
		  FROM TI_ObservacionRegistroTabla OBS
		  	   INNER JOIN (SELECT Det.I_RowID, Det.I_ProcedenciaID, tmp.I_RowID as TempRowID
			   				 FROM TR_Ec_Det Det
								  LEFT JOIN #temp_detalle_periodo_no_periodo_concepto tmp ON tmp.I_RowID = Det.I_RowID
							WHERE tmp.I_RowID IS NULL
								  AND Ano = @T_Anio
								  AND I_ProcedenciaID = @I_ProcedenciaID
			   			  ) DET ON OBS.I_FilaTablaID = DET.I_RowID
						  		   AND OBS.I_ProcedenciaID = DET.I_ProcedenciaID 
		 WHERE OBS.I_ObservID = @I_ObservID 
		 	   AND OBS.I_TablaID = @I_TablaID 
			   AND OBS.I_ProcedenciaID = @I_ProcedenciaID
		

		SET @I_Observados = (SELECT COUNT(*) 
							   FROM TI_ObservacionRegistroTabla OBS 
									INNER JOIN TR_Ec_Det DET ON OBS.I_FilaTablaID = DET.I_RowID 
																AND DET.I_ProcedenciaID = OBS.I_ProcedenciaID
							  WHERE OBS.I_ObservID = @I_ObservID 
									AND DET.Ano = @T_Anio
									AND DET.I_ProcedenciaID = @I_ProcedenciaID 
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


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_Obligaciones_ObligacionDet_MigracionTP_U_Validar_17_PeriodoDetallePeriodoConceptoPorOblID')
	DROP PROCEDURE [dbo].[USP_Obligaciones_ObligacionDet_MigracionTP_U_Validar_17_PeriodoDetallePeriodoConceptoPorOblID]
GO

CREATE PROCEDURE [dbo].[USP_Obligaciones_ObligacionDet_MigracionTP_U_Validar_17_PeriodoDetallePeriodoConceptoPorOblID]
	@I_OblRowID	  int,
	@B_Resultado  bit output,
	@T_Message    nvarchar(4000) OUTPUT	
AS
/*
	DESCRIPCION: Marcar TR_Ec_Obl con B_Migrable = 0 cuando el periodo del concepto en el detalle no coincide con el periodo del concepto en cp_pri para el ID de obligacion.

	DECLARE @I_OblRowID	  int,
			@B_Resultado  bit,
			@T_Message    nvarchar(4000)
	EXEC USP_Obligaciones_ObligacionDet_MigracionTP_U_Validar_17_PeriodoDetallePeriodoConceptoPorOblID @I_OblRowID, @B_Resultado output, @T_Message output
	SELECT @B_Resultado as resultado, @T_Message as mensaje
*/
BEGIN
	DECLARE @I_Observados int = 0
	DECLARE @D_FecProceso datetime = GETDATE() 
	DECLARE @I_ObservID int = 17
	DECLARE @I_TablaID int = 4

	BEGIN TRANSACTION
	BEGIN TRY
		SELECT	Det.I_RowID 
		INTO	#temp_detalle_periodo_no_periodo_concepto
		FROM	TR_Ec_Det Det
				INNER JOIN TR_Cp_Pri Pri ON Det.Concepto = Pri.Id_cp
		WHERE	Det.Ano <> Pri.Ano

		UPDATE Det
		SET	B_Migrable = 0,
			D_FecEvalua = @D_FecProceso
		FROM TR_Ec_Det Det 
			 INNER JOIN #temp_detalle_periodo_no_periodo_concepto tmp ON tmp.I_RowID = Det.I_RowID
		WHERE I_OblRowID = @I_OblRowID

		MERGE TI_ObservacionRegistroTabla AS TRG
		USING (SELECT @I_ObservID AS I_ObservID, @I_TablaID AS I_TablaID, Det.I_RowID AS I_FilaTablaID, 
					  @D_FecProceso AS D_FecRegistro, Det.I_ProcedenciaID  
				 FROM TR_Ec_Det Det
					  INNER JOIN #temp_detalle_periodo_no_periodo_concepto tmp ON tmp.I_RowID = Det.I_RowID
				WHERE I_OblRowID = @I_OblRowID
			  ) AS SRC
		ON TRG.I_ObservID = SRC.I_ObservID AND TRG.I_TablaID = SRC.I_TablaID AND TRG.I_FilaTablaID = SRC.I_FilaTablaID
		WHEN MATCHED AND TRG.I_ProcedenciaID = SRC.I_ProcedenciaID THEN
			UPDATE SET D_FecRegistro = SRC.D_FecRegistro
		WHEN NOT MATCHED BY TARGET THEN
			INSERT (I_ObservID, I_TablaID, I_FilaTablaID, D_FecRegistro, I_ProcedenciaID, B_ObligProc)
			VALUES (SRC.I_ObservID, SRC.I_TablaID, SRC.I_FilaTablaID, SRC.D_FecRegistro, SRC.I_ProcedenciaID, 1);		

		UPDATE OBS
		   SET D_FecResuelto = @D_FecProceso,
		   	   B_Resuelto = 1
		  FROM TI_ObservacionRegistroTabla OBS
		  	   INNER JOIN (SELECT Det.I_RowID, Det.I_ProcedenciaID, tmp.I_RowID as TempRowID
			   				 FROM TR_Ec_Det Det
								  LEFT JOIN #temp_detalle_periodo_no_periodo_concepto tmp ON tmp.I_RowID = Det.I_RowID
							WHERE tmp.I_RowID IS NULL
								  AND I_OblRowID = @I_OblRowID
			   			  ) DET ON OBS.I_FilaTablaID = DET.I_RowID
						  		   AND OBS.I_ProcedenciaID = DET.I_ProcedenciaID 
		 WHERE OBS.I_ObservID = @I_ObservID 
		 	   AND OBS.I_TablaID = @I_TablaID 
		

		SET @I_Observados = (SELECT COUNT(*) 
							   FROM TI_ObservacionRegistroTabla OBS 
									INNER JOIN TR_Ec_Det DET ON OBS.I_FilaTablaID = DET.I_RowID 
																AND DET.I_ProcedenciaID = OBS.I_ProcedenciaID
							  WHERE OBS.I_ObservID = @I_ObservID 
									AND DET.I_OblRowID = @I_OblRowID  
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
	DECLARE @D_FecProceso datetime = GETDATE() 
	DECLARE @I_ObservID int = 25
	DECLARE @I_TablaID int = 4

	BEGIN TRANSACTION
	BEGIN TRY 
		SELECT	I_RowID 
		INTO	#temp_obl_no_migrable
		FROM	TR_Ec_Obl 
		WHERE	B_Migrable = 0
				AND Ano = @T_Anio
				AND I_ProcedenciaID = @I_ProcedenciaID

		UPDATE Det
		SET	B_Migrable = 0,
			D_FecEvalua = @D_FecProceso
		FROM TR_Ec_Det Det 
			 INNER JOIN #temp_obl_no_migrable tmp ON tmp.I_RowID = Det.I_OblRowID


		MERGE TI_ObservacionRegistroTabla AS TRG
		USING (SELECT @I_ObservID AS I_ObservID, @I_TablaID AS I_TablaID, Det.I_RowID AS I_FilaTablaID, @D_FecProceso AS D_FecRegistro 
				 FROM TR_Ec_Det Det
					  INNER JOIN #temp_obl_no_migrable tmp ON tmp.I_RowID = Det.I_OblRowID
			  ) AS SRC
		ON TRG.I_ObservID = SRC.I_ObservID AND TRG.I_TablaID = SRC.I_TablaID AND TRG.I_FilaTablaID = SRC.I_FilaTablaID
		WHEN MATCHED THEN
			UPDATE SET D_FecRegistro = SRC.D_FecRegistro
		WHEN NOT MATCHED BY TARGET THEN
			INSERT (I_ObservID, I_TablaID, I_FilaTablaID, D_FecRegistro, I_ProcedenciaID, B_ObligProc)
			VALUES (SRC.I_ObservID, SRC.I_TablaID, SRC.I_FilaTablaID, SRC.D_FecRegistro, @I_ProcedenciaID, 1);
		

		UPDATE OBS
		   SET D_FecResuelto = @D_FecProceso,
		   	   B_Resuelto = 1
		  FROM TI_ObservacionRegistroTabla OBS
		  	   INNER JOIN (SELECT Det.I_RowID, Det.I_ProcedenciaID, tmp.I_RowID as TempRowID
			   				 FROM TR_Ec_Det Det
								  LEFT JOIN #temp_obl_no_migrable tmp ON tmp.I_RowID = Det.I_OblRowID
							WHERE tmp.I_RowID IS NULL
							      AND Ano = @T_Anio
								  AND I_ProcedenciaID = @I_ProcedenciaID
			   			  ) DET ON OBS.I_FilaTablaID = DET.I_RowID
						  		   AND OBS.I_ProcedenciaID = DET.I_ProcedenciaID 
		 WHERE OBS.I_ObservID = @I_ObservID 
		 	   AND OBS.I_TablaID = @I_TablaID 
		

		SET @I_Observados = (SELECT COUNT(*) 
							   FROM TI_ObservacionRegistroTabla OBS 
									INNER JOIN TR_Ec_Det DET ON OBS.I_FilaTablaID = DET.I_RowID 
																AND DET.I_ProcedenciaID = OBS.I_ProcedenciaID
							  WHERE OBS.I_ObservID = @I_ObservID 
									AND DET.Ano = @T_Anio
									AND DET.I_ProcedenciaID = @I_ProcedenciaID 
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


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_Obligaciones_ObligacionDet_MigracionTP_U_Validar_25_ObligacionCabIDPorOblID')
	DROP PROCEDURE [dbo].[USP_Obligaciones_ObligacionDet_MigracionTP_U_Validar_25_ObligacionCabIDPorOblID]
GO

CREATE PROCEDURE [dbo].[USP_Obligaciones_ObligacionDet_MigracionTP_U_Validar_25_ObligacionCabIDPorOblID]
	@I_OblRowID	  int,
	@B_Resultado  bit output,
	@T_Message    nvarchar(4000) OUTPUT	
AS
/*
	DESCRIPCION: Marcar TR_Ec_Obl con B_Migrable = 0 cuando la obligacion no tiene registros asociados en el detalle para el ID de obligacion.

	DECLARE @I_OblRowID	  int,
			@B_Resultado  bit,
			@T_Message    nvarchar(4000)
	EXEC USP_Obligaciones_ObligacionDet_MigracionTP_U_Validar_25_ObligacionCabIDPorOblID @I_OblRowID, @B_Resultado output, @T_Message output
	SELECT @B_Resultado as resultado, @T_Message as mensaje
*/
BEGIN
	DECLARE @I_Observados int = 0
	DECLARE @D_FecProceso datetime = GETDATE() 
	DECLARE @I_ObservID int = 25
	DECLARE @I_TablaID int = 4

	BEGIN TRANSACTION
	BEGIN TRY
		SELECT	I_RowID 
		INTO	#temp_obl_no_migrable
		FROM	TR_Ec_Obl 
		WHERE	B_Migrable = 0
				

		UPDATE Det
		   SET B_Migrable = 0,
			   D_FecEvalua = @D_FecProceso
		  FROM TR_Ec_Det Det 
			   INNER JOIN #temp_obl_no_migrable tmp ON tmp.I_RowID = Det.I_OblRowID
		 WHERE Det.I_OblRowID = @I_OblRowID

		MERGE TI_ObservacionRegistroTabla AS TRG
		USING (SELECT @I_ObservID AS I_ObservID, @I_TablaID AS I_TablaID, Det.I_RowID AS I_FilaTablaID, 
					  @D_FecProceso AS D_FecRegistro, Det.I_ProcedenciaID 
				 FROM TR_Ec_Det Det
					  INNER JOIN #temp_obl_no_migrable tmp ON tmp.I_RowID = Det.I_OblRowID
				WHERE Det.I_OblRowID = @I_OblRowID
			  ) AS SRC
		ON TRG.I_ObservID = SRC.I_ObservID AND TRG.I_TablaID = SRC.I_TablaID AND TRG.I_FilaTablaID = SRC.I_FilaTablaID
		WHEN MATCHED THEN
			UPDATE SET D_FecRegistro = SRC.D_FecRegistro
		WHEN NOT MATCHED BY TARGET THEN
			INSERT (I_ObservID, I_TablaID, I_FilaTablaID, D_FecRegistro, I_ProcedenciaID, B_ObligProc)
			VALUES (SRC.I_ObservID, SRC.I_TablaID, SRC.I_FilaTablaID, SRC.D_FecRegistro, SRC.I_ProcedenciaID, 1);
		

		UPDATE OBS
		   SET D_FecResuelto = @D_FecProceso,
		   	   B_Resuelto = 1
		  FROM TI_ObservacionRegistroTabla OBS
		  	   INNER JOIN (SELECT Det.I_RowID, Det.I_ProcedenciaID, tmp.I_RowID as TempRowID
			   				 FROM TR_Ec_Det Det
								  LEFT JOIN #temp_obl_no_migrable tmp ON tmp.I_RowID = Det.I_OblRowID
							WHERE tmp.I_RowID IS NULL
								  AND Det.I_OblRowID = @I_OblRowID
			   			  ) DET ON OBS.I_FilaTablaID = DET.I_RowID
						  		   AND OBS.I_ProcedenciaID = DET.I_ProcedenciaID 
		 WHERE OBS.I_ObservID = @I_ObservID 
		 	   AND OBS.I_TablaID = @I_TablaID 
		

		SET @I_Observados = (SELECT COUNT(*) 
							   FROM TI_ObservacionRegistroTabla OBS 
									INNER JOIN TR_Ec_Det DET ON OBS.I_FilaTablaID = DET.I_RowID 
																AND DET.I_ProcedenciaID = OBS.I_ProcedenciaID
							  WHERE OBS.I_ObservID = @I_ObservID 
									AND DET.I_OblRowID = @I_OblRowID 
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


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_U_ValidarDetalleObligacionConceptoPagoMigrado')
	DROP PROCEDURE [dbo].[USP_U_ValidarDetalleObligacionConceptoPagoMigrado]
GO

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_Obligaciones_ObligacionDet_MigracionTP_U_Validar_33_ConceptoPagoMigrado')
	DROP PROCEDURE [dbo].[USP_Obligaciones_ObligacionDet_MigracionTP_U_Validar_33_ConceptoPagoMigrado]
GO

CREATE PROCEDURE [dbo].[USP_Obligaciones_ObligacionDet_MigracionTP_U_Validar_33_ConceptoPagoMigrado]	
	@I_ProcedenciaID tinyint,
	@T_Anio		  varchar(4),
	@B_Resultado  bit output,
	@T_Message	  nvarchar(4000) OUTPUT	
AS
/*
	DESCRIPCION: Marcar TR_Ec_Det con B_Migrable = 0 cuando el detalle de pago tiene un concepto de pago sin migrar.

	DECLARE	@I_ProcedenciaID	tinyint = 2,
			@T_Anio				varchar(4) = '2016',
			@B_Resultado		bit,
			@T_Message			nvarchar(4000)
	EXEC USP_Obligaciones_ObligacionDet_MigracionTP_U_Validar_42_CuotaDetalleCuotaConcepto @I_ProcedenciaID, @T_Anio, @B_Resultado output, @T_Message output
	SELECT @B_Resultado as resultado, @T_Message as mensaje
*/

BEGIN
	DECLARE @I_Observados int = 0
	DECLARE @D_FecProceso datetime = GETDATE() 
	DECLARE @I_ObservID int = 33
	DECLARE @I_TablaID int = 4

	BEGIN TRANSACTION
	BEGIN TRY

		SELECT Det.I_RowID, Det.I_OblRowID, Det.Concepto, Pri.Id_cp, Pri.I_RowID AS I_PriRowID
		  INTO #temp_detalle_conceptos_sin_migrar
		  FROM TR_Ec_Det Det
			   INNER JOIN TR_Cp_Pri Pri ON Det.Concepto = Pri.Id_cp
		 WHERE Pri.B_Migrado = 0
			   AND Det.I_ProcedenciaID = @I_ProcedenciaID
			   AND Det.Ano = @T_Anio 

		UPDATE	Det
		SET		B_Migrable = 0,
				D_FecEvalua = @D_FecProceso
		FROM    TR_Ec_Det Det
				INNER JOIN #temp_detalle_conceptos_sin_migrar tmp ON Det.I_RowID = tmp.I_RowID
					
		MERGE TI_ObservacionRegistroTabla AS TRG
		USING 	(SELECT	@I_ObservID AS I_ObservID, @I_TablaID AS I_TablaID, Det.I_RowID AS I_FilaTablaID, 
						@D_FecProceso AS D_FecRegistro 
				   FROM TR_Ec_Det Det
						INNER JOIN #temp_detalle_conceptos_sin_migrar tmp ON Det.I_RowID = tmp.I_RowID
				 ) AS SRC
		ON TRG.I_ObservID = SRC.I_ObservID AND TRG.I_TablaID = SRC.I_TablaID AND TRG.I_FilaTablaID = SRC.I_FilaTablaID 
			AND TRG.I_ProcedenciaID = @I_ProcedenciaID
		WHEN MATCHED THEN
			UPDATE SET D_FecRegistro = SRC.D_FecRegistro
		WHEN NOT MATCHED BY TARGET THEN
			INSERT (I_ObservID, I_TablaID, I_FilaTablaID, D_FecRegistro, I_ProcedenciaID, B_ObligProc)
			VALUES (SRC.I_ObservID, SRC.I_TablaID, SRC.I_FilaTablaID, SRC.D_FecRegistro, @I_ProcedenciaID, 1);


		UPDATE OBS
		   SET D_FecResuelto = @D_FecProceso,
		   	   B_Resuelto = 1
		  FROM TI_ObservacionRegistroTabla OBS
		  	   INNER JOIN (SELECT Det.I_RowID, Det.I_ProcedenciaID, tmp.I_RowID as TempRowID
			   				 FROM TR_Ec_Det Det
								  LEFT JOIN #temp_detalle_conceptos_sin_migrar tmp ON tmp.I_RowID = Det.I_OblRowID
							WHERE tmp.I_RowID IS NULL
								  AND Det.Ano = @T_Anio
								  AND Det.I_ProcedenciaID = @I_ProcedenciaID
			   			  ) DET ON OBS.I_FilaTablaID = DET.I_RowID
						  		   AND OBS.I_ProcedenciaID = DET.I_ProcedenciaID 
		 WHERE OBS.I_ObservID = @I_ObservID 
		 	   AND OBS.I_TablaID = @I_TablaID 
		

		SET @I_Observados = (SELECT COUNT(*) 
							   FROM TI_ObservacionRegistroTabla OBS 
									INNER JOIN TR_Ec_Det DET ON OBS.I_FilaTablaID = DET.I_RowID 
																AND DET.I_ProcedenciaID = OBS.I_ProcedenciaID
							  WHERE OBS.I_ObservID = @I_ObservID 
									AND OBS.B_Resuelto = 0
									AND DET.Ano = @T_Anio
									AND DET.I_ProcedenciaID = @I_ProcedenciaID 
							)

		SELECT @I_Observados as cant_obs, @D_FecProceso as fec_proceso		 

		COMMIT TRANSACTION			
		
		SET @B_Resultado = 1
		SET @T_Message = '{ ' +
							 'Type: "summary", ' + 
							 'Title: "Detalles con concepto no migrado", ' + 
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


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_Obligaciones_ObligacionDet_MigracionTP_U_Validar_33_ConceptoPagoMigradoPorOblID')
	DROP PROCEDURE [dbo].[USP_Obligaciones_ObligacionDet_MigracionTP_U_Validar_33_ConceptoPagoMigradoPorOblID]
GO

CREATE PROCEDURE [dbo].[USP_Obligaciones_ObligacionDet_MigracionTP_U_Validar_33_ConceptoPagoMigradoPorOblID]	
	@I_OblRowID	  int,
	@B_Resultado  bit output,
	@T_Message	  nvarchar(4000) OUTPUT	
AS
/*
	DESCRIPCION: Marcar TR_Ec_Det con B_Migrable = 0 cuando el detalle de pago tiene un concepto de pago sin migrar.

	DECLARE @I_OblRowID	  int,
			@B_Resultado  bit,
			@T_Message	  nvarchar(4000)
	EXEC USP_Obligaciones_ObligacionDet_MigracionTP_U_Validar_33_ConceptoPagoMigradoPorOblID @I_OblRowID, @B_Resultado output, @T_Message output
	SELECT @B_Resultado as resultado, @T_Message as mensaje
*/

BEGIN
	DECLARE @I_Observados int = 0
	DECLARE @D_FecProceso datetime = GETDATE() 
	DECLARE @I_ObservID int = 33
	DECLARE @I_TablaID int = 4
	DECLARE @I_TablaOblID int = 5

	BEGIN TRANSACTION
	BEGIN TRY

		SELECT Det.I_RowID, Det.I_OblRowID, Det.Concepto, Pri.Id_cp, Pri.I_RowID AS I_PriRowID
		  INTO #temp_detalle_conceptos_sin_migrar
		  FROM TR_Ec_Det Det
			   INNER JOIN TR_Cp_Pri Pri ON Det.Concepto = Pri.Id_cp
		 WHERE Pri.B_Migrado = 0
			   AND Det.I_OblRowID = @I_OblRowID

		UPDATE	Det
		SET		B_Migrable = 0,
				D_FecEvalua = @D_FecProceso
		FROM    TR_Ec_Det Det
				INNER JOIN #temp_detalle_conceptos_sin_migrar tmp ON Det.I_RowID = tmp.I_RowID

					
		MERGE TI_ObservacionRegistroTabla AS TRG
		USING 	(SELECT	@I_ObservID AS I_ObservID, @I_TablaID AS I_TablaID, Det.I_RowID AS I_FilaTablaID, 
						@D_FecProceso AS D_FecRegistro, Det.I_ProcedenciaID 
				   FROM TR_Ec_Det Det
						INNER JOIN #temp_detalle_conceptos_sin_migrar tmp ON Det.I_RowID = tmp.I_RowID
				 ) AS SRC
		ON TRG.I_ObservID = SRC.I_ObservID AND TRG.I_TablaID = SRC.I_TablaID AND TRG.I_FilaTablaID = SRC.I_FilaTablaID 
			AND TRG.I_ProcedenciaID = SRC.I_ProcedenciaID
		WHEN MATCHED THEN
			UPDATE SET D_FecRegistro = SRC.D_FecRegistro
		WHEN NOT MATCHED BY TARGET THEN
			INSERT (I_ObservID, I_TablaID, I_FilaTablaID, D_FecRegistro, I_ProcedenciaID, B_ObligProc)
			VALUES (SRC.I_ObservID, SRC.I_TablaID, SRC.I_FilaTablaID, SRC.D_FecRegistro, SRC.I_ProcedenciaID, 1);


		UPDATE OBS
		   SET D_FecResuelto = @D_FecProceso,
		   	   B_Resuelto = 1
		  FROM TI_ObservacionRegistroTabla OBS
		  	   INNER JOIN (SELECT Det.I_RowID, Det.I_ProcedenciaID, tmp.I_RowID as TempRowID
			   				 FROM TR_Ec_Det Det
								  LEFT JOIN #temp_detalle_conceptos_sin_migrar tmp ON tmp.I_RowID = Det.I_OblRowID
							WHERE tmp.I_RowID IS NULL
								  AND Det.I_OblRowID = @I_OblRowID
			   			  ) DET ON OBS.I_FilaTablaID = DET.I_RowID
						  		   AND OBS.I_ProcedenciaID = DET.I_ProcedenciaID 
		 WHERE OBS.I_ObservID = @I_ObservID 
		 	   AND OBS.I_TablaID = @I_TablaID 
		

		SET @I_Observados = (SELECT COUNT(*) 
							   FROM TI_ObservacionRegistroTabla OBS 
									INNER JOIN TR_Ec_Det DET ON OBS.I_FilaTablaID = DET.I_RowID 
																AND DET.I_ProcedenciaID = OBS.I_ProcedenciaID
							  WHERE OBS.I_ObservID = @I_ObservID 
									AND OBS.B_Resuelto = 0
									AND DET.I_OblRowID = @I_OblRowID
							)

		SELECT @I_Observados as cant_obs, @D_FecProceso as fec_proceso		 

		COMMIT TRANSACTION	
		
		SET @B_Resultado = 1
		SET @T_Message = '{ ' +
							 'Type: "summary", ' + 
							 'Title: "Detalles con concepto no migrado", ' + 
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


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_U_ValidarDetalleObligacionConceptoPago')
	DROP PROCEDURE [dbo].[USP_U_ValidarDetalleObligacionConceptoPago]
GO

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_Obligaciones_ObligacionDet_MigracionTP_U_Validar_35_ConceptoPago')
	DROP PROCEDURE [dbo].[USP_Obligaciones_ObligacionDet_MigracionTP_U_Validar_35_ConceptoPago]
GO

CREATE PROCEDURE [dbo].[USP_Obligaciones_ObligacionDet_MigracionTP_U_Validar_35_ConceptoPago]	
	@I_ProcedenciaID tinyint,
	@T_Anio			varchar(4) = NULL,
	@B_Resultado	bit output,
	@T_Message		nvarchar(4000) OUTPUT	
AS
/*
	DESCRIPCION: Marcar TR_Ec_Det con B_Migrable = 0 el concepto en el detalle de la obligación no existe en el catálogo de conceptos.

	DECLARE	@I_ProcedenciaID	tinyint = 2,
			@T_Anio				varchar(4) = '2016',
			@B_Resultado		bit,
			@T_Message			nvarchar(4000)
	EXEC USP_Obligaciones_ObligacionDet_MigracionTP_U_Validar_35_ConceptoPago @I_ProcedenciaID, @T_Anio, @B_Resultado output, @T_Message output
	SELECT @B_Resultado as resultado, @T_Message as mensaje
*/
BEGIN
	DECLARE @I_Observados int = 0
	DECLARE @D_FecProceso datetime = GETDATE() 
	DECLARE @I_ObservID int = 35
	DECLARE @I_TablaID int = 4

	BEGIN TRANSACTION
	BEGIN TRY 

		SELECT Det.I_RowID, Det.Concepto, Pri.Id_cp, Det.I_ProcedenciaID, Pri.I_ProcedenciaID AS I_ProcedenciaPriID
		  INTO #temp_detalle_concepto_no_existe
		  FROM TR_Ec_Det Det
			   LEFT JOIN TR_Cp_Pri Pri ON Det.Concepto = Pri.Id_cp
		 WHERE Pri.Id_cp is null
			   AND Det.I_ProcedenciaID = @I_ProcedenciaID
			   AND Det.Ano = @T_Anio

		UPDATE	Det
		SET		B_Migrable = 0,
				D_FecEvalua = @D_FecProceso
		FROM    TR_Ec_Det Det
				INNER JOIN #temp_detalle_concepto_no_existe tmp ON Det.I_RowID = tmp.I_RowID

					
		MERGE TI_ObservacionRegistroTabla AS TRG
		USING 	(SELECT	@I_ObservID AS I_ObservID, @I_TablaID AS I_TablaID, Det.I_RowID AS I_FilaTablaID, @D_FecProceso AS D_FecRegistro 
				   FROM TR_Ec_Det Det
						INNER JOIN #temp_detalle_concepto_no_existe tmp ON Det.I_RowID = tmp.I_RowID
				 ) AS SRC
		ON TRG.I_ObservID = SRC.I_ObservID AND TRG.I_TablaID = SRC.I_TablaID AND TRG.I_FilaTablaID = SRC.I_FilaTablaID
			 AND TRG.I_ProcedenciaID = @I_ProcedenciaID
		WHEN MATCHED THEN
			UPDATE SET D_FecRegistro = SRC.D_FecRegistro
		WHEN NOT MATCHED BY TARGET THEN
			INSERT (I_ObservID, I_TablaID, I_FilaTablaID, D_FecRegistro, I_ProcedenciaID, B_ObligProc)
			VALUES (SRC.I_ObservID, SRC.I_TablaID, SRC.I_FilaTablaID, SRC.D_FecRegistro, @I_ProcedenciaID, 1);


		UPDATE OBS
		   SET D_FecResuelto = @D_FecProceso,
		   	   B_Resuelto = 1
		  FROM TI_ObservacionRegistroTabla OBS
		  	   INNER JOIN (SELECT Det.I_RowID, Det.I_ProcedenciaID, tmp.I_RowID as TempRowID
			   				 FROM TR_Ec_Det Det
								  LEFT JOIN #temp_detalle_concepto_no_existe tmp ON tmp.I_RowID = Det.I_RowID
							WHERE tmp.I_RowID IS NULL
								  AND Det.Ano = @T_Anio
								  AND Det.I_ProcedenciaID = @I_ProcedenciaID
			   			  ) DET ON OBS.I_FilaTablaID = DET.I_RowID
						  		   AND OBS.I_ProcedenciaID = DET.I_ProcedenciaID 
		 WHERE OBS.I_ObservID = @I_ObservID 
		 	   AND OBS.I_TablaID = @I_TablaID 
		

		SET @I_Observados = (SELECT COUNT(*) 
							   FROM TI_ObservacionRegistroTabla OBS 
									INNER JOIN TR_Ec_Det DET ON OBS.I_FilaTablaID = DET.I_RowID 
																AND DET.I_ProcedenciaID = OBS.I_ProcedenciaID
							  WHERE OBS.I_ObservID = @I_ObservID 
									AND Det.Ano = @T_Anio
									AND Det.I_ProcedenciaID = @I_ProcedenciaID 
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


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_Obligaciones_ObligacionDet_MigracionTP_U_Validar_35_ConceptoPagoPorOblID')
	DROP PROCEDURE [dbo].[USP_Obligaciones_ObligacionDet_MigracionTP_U_Validar_35_ConceptoPagoPorOblID]
GO

CREATE PROCEDURE [dbo].[USP_Obligaciones_ObligacionDet_MigracionTP_U_Validar_35_ConceptoPagoPorOblID]	
	@I_OblRowID		int,
	@B_Resultado	bit output,
	@T_Message		nvarchar(4000) OUTPUT	
AS
/*
	DESCRIPCION: Marcar TR_Ec_Det con B_Migrable = 0 el concepto en el detalle de la obligación no existe en el catálogo de conceptos.

	DECLARE	@I_OblRowID	  int,
			@B_Resultado  bit,
			@T_Message			nvarchar(4000)
	EXEC USP_Obligaciones_ObligacionDet_MigracionTP_U_Validar_35_ConceptoPagoPorOblID @I_OblRowID, @B_Resultado output, @T_Message output
	SELECT @B_Resultado as resultado, @T_Message as mensaje
*/
BEGIN
	DECLARE @I_Observados int = 0
	DECLARE @D_FecProceso datetime = GETDATE() 
	DECLARE @I_ObservID int = 35
	DECLARE @I_TablaID int = 4

	BEGIN TRANSACTION
	BEGIN TRY

		SELECT Det.I_RowID, Det.Concepto, Pri.Id_cp, Det.I_ProcedenciaID, Pri.I_ProcedenciaID AS I_ProcedenciaPriID
		  INTO #temp_detalle_concepto_no_existe
		  FROM TR_Ec_Det Det
			   LEFT JOIN TR_Cp_Pri Pri ON Det.Concepto = Pri.Id_cp
		 WHERE Pri.Id_cp is null
			   AND Det.I_OblRowID = @I_OblRowID

		UPDATE	Det
		SET		B_Migrable = 0,
				D_FecEvalua = @D_FecProceso
		FROM    TR_Ec_Det Det
				INNER JOIN #temp_detalle_concepto_no_existe tmp ON Det.I_RowID = tmp.I_RowID

					
		MERGE TI_ObservacionRegistroTabla AS TRG
		USING 	(SELECT	@I_ObservID AS I_ObservID, @I_TablaID AS I_TablaID, Det.I_RowID AS I_FilaTablaID, 
						@D_FecProceso AS D_FecRegistro, Det.I_ProcedenciaID
				  FROM  TR_Ec_Det Det
						INNER JOIN #temp_detalle_concepto_no_existe tmp ON Det.I_RowID = tmp.I_RowID
				 ) AS SRC
		ON TRG.I_ObservID = SRC.I_ObservID AND TRG.I_TablaID = SRC.I_TablaID AND TRG.I_FilaTablaID = SRC.I_FilaTablaID
		WHEN MATCHED AND TRG.I_ProcedenciaID = SRC.I_ProcedenciaID THEN
			UPDATE SET D_FecRegistro = SRC.D_FecRegistro
		WHEN NOT MATCHED BY TARGET THEN
			INSERT (I_ObservID, I_TablaID, I_FilaTablaID, D_FecRegistro, I_ProcedenciaID, B_ObligProc)
			VALUES (SRC.I_ObservID, SRC.I_TablaID, SRC.I_FilaTablaID, SRC.D_FecRegistro, SRC.I_ProcedenciaID, 1);


		UPDATE OBS
		   SET D_FecResuelto = @D_FecProceso,
		   	   B_Resuelto = 1
		  FROM TI_ObservacionRegistroTabla OBS
		  	   INNER JOIN (SELECT Det.I_RowID, Det.I_ProcedenciaID, tmp.I_RowID as TempRowID
			   				 FROM TR_Ec_Det Det
								  LEFT JOIN #temp_detalle_concepto_no_existe tmp ON tmp.I_RowID = Det.I_RowID
							WHERE tmp.I_RowID IS NULL
								  AND Det.I_OblRowID = @I_OblRowID
			   			  ) DET ON OBS.I_FilaTablaID = DET.I_RowID
						  		   AND OBS.I_ProcedenciaID = DET.I_ProcedenciaID 
		 WHERE OBS.I_ObservID = @I_ObservID 
		 	   AND OBS.I_TablaID = @I_TablaID 


		SET @I_Observados = (SELECT COUNT(*) 
							   FROM TI_ObservacionRegistroTabla OBS 
									INNER JOIN TR_Ec_Det DET ON OBS.I_FilaTablaID = DET.I_RowID 
																AND DET.I_ProcedenciaID = OBS.I_ProcedenciaID
							  WHERE OBS.I_ObservID = @I_ObservID 
									AND Det.I_OblRowID = @I_OblRowID
									AND OBS.B_Resuelto = 0
							)

		SELECT @I_Observados as cant_obs_det, @D_FecProceso as fec_proceso

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
	DESCRIPCION: Marcar TR_Ec_Det con B_Migrable = 0 cuando la cuota de pago del detalle no coincide con la cuota de pago del concepto.

	DECLARE	@I_ProcedenciaID tinyint = 2,
			@T_Anio			 varchar(4) = '2016',
			@B_Resultado	 bit,
			@T_Message		 nvarchar(4000)
	EXEC USP_Obligaciones_ObligacionDet_MigracionTP_U_Validar_42_CuotaDetalleCuotaConcepto @I_ProcedenciaID, @T_Anio, @B_Resultado output, @T_Message output
	SELECT @B_Resultado as resultado, @T_Message as mensaje
*/
BEGIN
	DECLARE @I_Observados int = 0
	DECLARE @I_ObservadosObl int = 0
	DECLARE @D_FecProceso datetime = GETDATE() 
	DECLARE @I_ObservID int = 42
	DECLARE @I_TablaID int = 4

	BEGIN TRANSACTION
	BEGIN TRY 
		SELECT  Det.I_RowID, I_OblRowID, Det.Cuota_pago, Concepto
		  INTO	#temp_detalle_cuota_concepto_cuota
		  FROM	TR_Ec_Det Det 
				INNER JOIN TR_Cp_Pri Pri ON Det.Concepto = Pri.Id_cp
		 WHERE	Det.Cuota_pago <> Pri.Cuota_pago
				AND Det.Ano = @T_Anio
				AND Det.I_ProcedenciaID = @I_ProcedenciaID

		UPDATE Det
		   SET B_Migrable = 0,
			   D_FecEvalua = @D_FecProceso
		  FROM TR_Ec_Det Det 
			   INNER JOIN #temp_detalle_cuota_concepto_cuota tmp ON tmp.I_RowID = Det.I_RowID

		MERGE TI_ObservacionRegistroTabla AS TRG
		USING (SELECT @I_ObservID AS I_ObservID, @I_TablaID AS I_TablaID, Det.I_RowID AS I_FilaTablaID, 
					  @D_FecProceso AS D_FecRegistro, Det.I_ProcedenciaID 
				 FROM TR_Ec_Det Det
					  INNER JOIN #temp_detalle_cuota_concepto_cuota tmp ON Det.I_RowID = tmp.I_RowID
			  ) AS SRC
		ON TRG.I_ObservID = SRC.I_ObservID AND TRG.I_TablaID = SRC.I_TablaID AND TRG.I_FilaTablaID = SRC.I_FilaTablaID
		WHEN MATCHED AND TRG.I_ProcedenciaID = SRC.I_ProcedenciaID THEN
			UPDATE SET D_FecRegistro = SRC.D_FecRegistro
		WHEN NOT MATCHED BY TARGET THEN
			INSERT (I_ObservID, I_TablaID, I_FilaTablaID, D_FecRegistro, I_ProcedenciaID, B_ObligProc)
			VALUES (SRC.I_ObservID, SRC.I_TablaID, SRC.I_FilaTablaID, SRC.D_FecRegistro, @I_ProcedenciaID, 1);


		UPDATE OBS
		   SET D_FecResuelto = @D_FecProceso,
		   	   B_Resuelto = 1
		  FROM TI_ObservacionRegistroTabla OBS
		  	   INNER JOIN (SELECT Det.I_RowID, Det.I_ProcedenciaID, tmp.I_RowID as TempRowID
			   				 FROM TR_Ec_Det Det
								  LEFT JOIN #temp_detalle_cuota_concepto_cuota tmp ON tmp.I_RowID = Det.I_RowID
							WHERE tmp.I_RowID IS NULL
								  AND Det.Ano = @T_Anio
								  AND Det.I_ProcedenciaID = @I_ProcedenciaID
			   			  ) DET ON OBS.I_FilaTablaID = DET.I_RowID
						  		   AND OBS.I_ProcedenciaID = DET.I_ProcedenciaID 
		 WHERE OBS.I_ObservID = @I_ObservID 
		 	   AND OBS.I_TablaID = @I_TablaID 
		

		SET @I_Observados = (SELECT COUNT(*) 
							   FROM TI_ObservacionRegistroTabla OBS 
									INNER JOIN TR_Ec_Det DET ON OBS.I_FilaTablaID = DET.I_RowID 
																AND DET.I_ProcedenciaID = OBS.I_ProcedenciaID
							  WHERE OBS.I_ObservID = @I_ObservID 
									AND Det.Ano = @T_Anio
									AND Det.I_ProcedenciaID = @I_ProcedenciaID 
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


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_Obligaciones_ObligacionDet_MigracionTP_U_Validar_42_CuotaDetalleCuotaConceptoPorOblID')
	DROP PROCEDURE [dbo].[USP_Obligaciones_ObligacionDet_MigracionTP_U_Validar_42_CuotaDetalleCuotaConceptoPorOblID]
GO

CREATE PROCEDURE [dbo].[USP_Obligaciones_ObligacionDet_MigracionTP_U_Validar_42_CuotaDetalleCuotaConceptoPorOblID]
	@I_OblRowID	  int,
	@B_Resultado  bit output,
	@T_Message    nvarchar(4000) OUTPUT	
AS
/*
	DESCRIPCION: Marcar TR_Ec_Obl con B_Migrable = 0 cuando la obligacion no tiene registros asociados en el detalle para el ID de obligacion.

	DECLARE @I_OblRowID	  int,
			@B_Resultado  bit,
			@T_Message    nvarchar(4000)
	EXEC USP_Obligaciones_ObligacionDet_MigracionTP_U_Validar_42_CuotaDetalleCuotaConceptoPorOblID @I_OblRowID, @B_Resultado output, @T_Message output
	SELECT @B_Resultado as resultado, @T_Message as mensaje
*/
BEGIN
	DECLARE @I_Observados int = 0
	DECLARE @I_ObservadosObl int = 0
	DECLARE @D_FecProceso datetime = GETDATE() 
	DECLARE @I_ObservID int = 42
	DECLARE @I_TablaID int = 4

	BEGIN TRANSACTION
	BEGIN TRY

		SELECT  Det.I_RowID, I_OblRowID, Det.Cuota_pago, Concepto
		  INTO	#temp_detalle_cuota_concepto_cuota
		  FROM	TR_Ec_Det Det 
				INNER JOIN TR_Cp_Pri Pri ON Det.Concepto = Pri.Id_cp
		 WHERE	Det.Cuota_pago <> Pri.Cuota_pago

		UPDATE Det
		   SET B_Migrable = 0,
			   D_FecEvalua = @D_FecProceso
		  FROM TR_Ec_Det Det 
			   INNER JOIN #temp_detalle_cuota_concepto_cuota tmp ON tmp.I_RowID = Det.I_RowID
		 WHERE Det.I_OblRowID = @I_OblRowID

		MERGE TI_ObservacionRegistroTabla AS TRG
		USING (SELECT @I_ObservID AS I_ObservID, @I_TablaID AS I_TablaID, Det.I_RowID AS I_FilaTablaID, 
					  @D_FecProceso AS D_FecRegistro, Det.I_ProcedenciaID 
				 FROM TR_Ec_Det Det
					  INNER JOIN #temp_detalle_cuota_concepto_cuota tmp ON Det.I_RowID = tmp.I_RowID
				WHERE Det.I_OblRowID = @I_OblRowID
			  ) AS SRC
		ON TRG.I_ObservID = SRC.I_ObservID AND TRG.I_TablaID = SRC.I_TablaID AND TRG.I_FilaTablaID = SRC.I_FilaTablaID
		WHEN MATCHED AND TRG.I_ProcedenciaID = SRC.I_ProcedenciaID THEN
			UPDATE SET D_FecRegistro = SRC.D_FecRegistro
		WHEN NOT MATCHED BY TARGET THEN
			INSERT (I_ObservID, I_TablaID, I_FilaTablaID, D_FecRegistro, I_ProcedenciaID, B_ObligProc)
			VALUES (SRC.I_ObservID, SRC.I_TablaID, SRC.I_FilaTablaID, SRC.D_FecRegistro, SRC.I_ProcedenciaID, 1);


		UPDATE OBS
		   SET D_FecResuelto = @D_FecProceso,
		   	   B_Resuelto = 1
		  FROM TI_ObservacionRegistroTabla OBS
		  	   INNER JOIN (SELECT Det.I_RowID, Det.I_ProcedenciaID, tmp.I_RowID as TempRowID
			   				 FROM TR_Ec_Det Det
								  LEFT JOIN #temp_detalle_cuota_concepto_cuota tmp ON tmp.I_RowID = Det.I_OblRowID
							WHERE tmp.I_RowID IS NULL
								  AND Det.I_OblRowID = @I_OblRowID
			   			  ) DET ON OBS.I_FilaTablaID = DET.I_RowID
						  		   AND OBS.I_ProcedenciaID = DET.I_ProcedenciaID 
		 WHERE OBS.I_ObservID = @I_ObservID 
		 	   AND OBS.I_TablaID = @I_TablaID 
		

		SET @I_Observados = (SELECT COUNT(*) 
							   FROM TI_ObservacionRegistroTabla OBS 
									INNER JOIN TR_Ec_Det DET ON OBS.I_FilaTablaID = DET.I_RowID 
																AND DET.I_ProcedenciaID = OBS.I_ProcedenciaID
							  WHERE OBS.I_ObservID = @I_ObservID 
									AND Det.I_OblRowID = @I_OblRowID
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



IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_Obligaciones_ObligacionDet_MigracionTP_U_Validar_43_AnioDetalleNumerico')
	DROP PROCEDURE [dbo].[USP_Obligaciones_ObligacionDet_MigracionTP_U_Validar_43_AnioDetalleNumerico]
GO


CREATE PROCEDURE [dbo].[USP_Obligaciones_ObligacionDet_MigracionTP_U_Validar_43_AnioDetalleNumerico]	
(
	@I_ProcedenciaID tinyint,
	@B_Resultado  bit output,
	@T_Message	  nvarchar(4000) OUTPUT	
)
AS
/*
	DESCRIPCION: Marcar TR_Ec_Det con B_Migrable = 0 cuando el año en el detalle no es un valor válido

	DECLARE	@I_ProcedenciaID	tinyint = 2,
			@B_Resultado		bit,
			@T_Message			nvarchar(4000)
	EXEC USP_Obligaciones_ObligacionDet_MigracionTP_U_Validar_43_AnioDetalleNumerico @I_ProcedenciaID, @B_Resultado output, @T_Message output
	SELECT @B_Resultado as resultado, @T_Message as mensaje
*/
BEGIN
	DECLARE @I_Observados int = 0
	DECLARE @I_ObservadosObl int = 0
	DECLARE @D_FecProceso datetime = GETDATE() 
	DECLARE @I_ObservID int = 43
	DECLARE @I_TablaID int = 4

	BEGIN TRANSACTION
	BEGIN TRY 
		
		UPDATE	TR_Ec_Det
		SET		B_Migrable = 0,
				D_FecEvalua = @D_FecProceso
		WHERE	ISNUMERIC(Ano) = 0
				AND I_ProcedenciaID = @I_ProcedenciaID


		MERGE TI_ObservacionRegistroTabla AS TRG
		USING 	(SELECT	@I_ObservID AS I_ObservID, @I_TablaID AS I_TablaID, I_RowID AS I_FilaTablaID, @D_FecProceso AS D_FecRegistro 
				   FROM	TR_Ec_Det 
				  WHERE	ISNUMERIC(Ano) = 0 
						AND I_ProcedenciaID = @I_ProcedenciaID
				) AS SRC
		ON TRG.I_ObservID = SRC.I_ObservID AND TRG.I_TablaID = SRC.I_TablaID AND TRG.I_FilaTablaID = SRC.I_FilaTablaID
		WHEN MATCHED AND TRG.I_ProcedenciaID = @I_ProcedenciaID THEN
			UPDATE SET D_FecRegistro = SRC.D_FecRegistro
		WHEN NOT MATCHED BY TARGET THEN
			INSERT (I_ObservID, I_TablaID, I_FilaTablaID, D_FecRegistro, I_ProcedenciaID, B_ObligProc)
			VALUES (SRC.I_ObservID, SRC.I_TablaID, SRC.I_FilaTablaID, SRC.D_FecRegistro, @I_ProcedenciaID, 1);


		UPDATE OBS
		   SET D_FecResuelto = @D_FecProceso,
			   B_Resuelto = 1
		  FROM TI_ObservacionRegistroTabla OBS
			   INNER JOIN (SELECT I_RowID, I_ProcedenciaID FROM TR_Ec_Det WHERE ISNUMERIC(Ano) = 1) DET
						   ON OBS.I_FilaTablaID = DET.I_RowID
							  AND OBS.I_ProcedenciaID = DET.I_ProcedenciaID
		 WHERE OBS.I_ObservID = @I_ObservID 
			   AND OBS.I_TablaID = @I_TablaID

		SET @I_Observados = (SELECT COUNT(*) FROM TI_ObservacionRegistroTabla 
											WHERE I_ObservID = @I_ObservID 
												  AND I_TablaID = @I_TablaID
												  AND I_ProcedenciaID = @I_ProcedenciaID
												  AND B_Resuelto = 0) 

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


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_Obligaciones_ObligacionDet_MigracionTP_U_Validar_43_AnioDetalleNumericoPorOblID')
	DROP PROCEDURE [dbo].[USP_Obligaciones_ObligacionDet_MigracionTP_U_Validar_43_AnioDetalleNumericoPorOblID]
GO

CREATE PROCEDURE [dbo].[USP_Obligaciones_ObligacionDet_MigracionTP_U_Validar_43_AnioDetalleNumericoPorOblID]
	@I_OblRowID	  int,
	@B_Resultado  bit output,
	@T_Message    nvarchar(4000) OUTPUT	
AS
/*
	DESCRIPCION: Marcar TR_Ec_Obl con B_Migrable = 0 cuando el año en el detalle no es un valor válido para el ID de obligacion.

	DECLARE @I_OblRowID	  int,
			@B_Resultado  bit,
			@T_Message    nvarchar(4000)
	EXEC USP_Obligaciones_ObligacionDet_MigracionTP_U_Validar_43_AnioDetalleNumericoPorOblID @I_OblRowID, @B_Resultado output, @T_Message output
	SELECT @B_Resultado as resultado, @T_Message as mensaje
*/
BEGIN
	DECLARE @I_Observados int = 0
	DECLARE @I_ObservadosObl int = 0
	DECLARE @D_FecProceso datetime = GETDATE() 
	DECLARE @I_ObservID int = 40
	DECLARE @I_TablaID int = 4

	BEGIN TRANSACTION
	BEGIN TRY
		UPDATE	TR_Ec_Det
		SET		B_Migrable = 0,
				D_FecEvalua = @D_FecProceso
		WHERE	ISNUMERIC(Ano) = 0
				AND I_OblRowID = @I_OblRowID


		MERGE TI_ObservacionRegistroTabla AS TRG
		USING 	(SELECT	@I_ObservID AS I_ObservID, @I_TablaID AS I_TablaID, I_RowID AS I_FilaTablaID, I_ProcedenciaID, @D_FecProceso AS D_FecRegistro 
				   FROM	TR_Ec_Det 
				  WHERE	ISNUMERIC(Ano) = 0 
						AND I_OblRowID = @I_OblRowID
				) AS SRC
		ON TRG.I_ObservID = SRC.I_ObservID AND TRG.I_TablaID = SRC.I_TablaID AND TRG.I_FilaTablaID = SRC.I_FilaTablaID
		WHEN MATCHED THEN
			UPDATE SET D_FecRegistro = SRC.D_FecRegistro
		WHEN NOT MATCHED BY TARGET THEN
			INSERT (I_ObservID, I_TablaID, I_FilaTablaID, D_FecRegistro, I_ProcedenciaID, B_ObligProc)
			VALUES (SRC.I_ObservID, SRC.I_TablaID, SRC.I_FilaTablaID, SRC.D_FecRegistro, SRC.I_ProcedenciaID, 1);


		UPDATE OBS
		   SET D_FecResuelto = @D_FecProceso,
			   B_Resuelto = 1
		  FROM TI_ObservacionRegistroTabla OBS
			   INNER JOIN (SELECT I_RowID, I_ProcedenciaID FROM TR_Ec_Det 
							WHERE ISNUMERIC(Ano) = 1 AND I_OblRowID = @I_OblRowID) DET
						   ON OBS.I_FilaTablaID = DET.I_RowID
							  AND OBS.I_ProcedenciaID = DET.I_ProcedenciaID
		 WHERE OBS.I_ObservID = @I_ObservID 
			   AND OBS.I_TablaID = @I_TablaID

		SET @I_Observados = (SELECT COUNT(*)
							   FROM TI_ObservacionRegistroTabla OBS
									INNER JOIN (SELECT I_RowID FROM TR_Ec_Det WHERE I_OblRowID = @I_OblRowID) DET ON DET.I_RowID = OBS.I_FilaTablaID
							  WHERE I_ObservID = @I_ObservID 
									AND I_TablaID = @I_TablaID
									AND B_Resuelto = 0) 

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
	DESCRIPCION: Marcar TR_Ec_Det con B_Migrable = 0 el periodo del detalle de la obligacion no tiene equivalencia en la base de datos de Ctas x cobrar.

	DECLARE	@B_Resultado  bit,
			@I_ProcedenciaID	tinyint = 2,
			@T_Anio				varchar(4) = '2016',
			@T_Message			nvarchar(4000)
	EXEC USP_Obligaciones_ObligacionDet_MigracionTP_U_Validar_44_PeriodoDetallePeriodoConcepto @I_ProcedenciaID, @T_Anio, @B_Resultado output, @T_Message output
	SELECT @B_Resultado as resultado, @T_Message as mensaje
*/
BEGIN
	DECLARE @I_Observados int = 0
	DECLARE @D_FecProceso datetime = GETDATE() 
	DECLARE @I_ObservID int = 44
	DECLARE @I_TablaID int = 4

	BEGIN TRANSACTION
	BEGIN TRY 
		SELECT I_RowID, I_OblRowID
		  INTO #temp_detalle_sin_periodo_equiv
		  FROM TR_Ec_Det Det
			   LEFT JOIN BD_OCEF_CtasPorCobrar.dbo.TC_CatalogoOpcion Ctas_Opc 
					  ON Det.P COLLATE SQL_Latin1_General_CP1_CI_AI = Ctas_opc.T_OpcionCod COLLATE SQL_Latin1_General_CP1_CI_AI
		 WHERE Ctas_Opc.I_OpcionID IS NULL
			   AND Ano = @T_Anio 
			   AND I_ProcedenciaID = @I_ProcedenciaID

		UPDATE	Det
		SET		B_Migrable = 0,
				D_FecEvalua = @D_FecProceso
		FROM	TR_Ec_Det Det
				INNER JOIN #temp_detalle_sin_periodo_equiv tmp ON tmp.I_RowID = Det.I_RowID

		MERGE TI_ObservacionRegistroTabla AS TRG
		USING (SELECT @I_ObservID AS I_ObservID, @I_TablaID AS I_TablaID, Det.I_RowID AS I_FilaTablaID, @D_FecProceso AS D_FecRegistro 
				 FROM TR_Ec_Det Det
					  INNER JOIN #temp_detalle_sin_periodo_equiv tmp ON tmp.I_RowID = Det.I_RowID
			  ) AS SRC
		ON TRG.I_ObservID = SRC.I_ObservID AND TRG.I_TablaID = SRC.I_TablaID AND TRG.I_FilaTablaID = SRC.I_FilaTablaID
		WHEN MATCHED AND TRG.I_ProcedenciaID = @I_ProcedenciaID THEN
			UPDATE SET D_FecRegistro = SRC.D_FecRegistro
		WHEN NOT MATCHED BY TARGET THEN
			INSERT (I_ObservID, I_TablaID, I_FilaTablaID, D_FecRegistro, I_ProcedenciaID, B_ObligProc)
			VALUES (SRC.I_ObservID, SRC.I_TablaID, SRC.I_FilaTablaID, SRC.D_FecRegistro, @I_ProcedenciaID, 1);

		UPDATE OBS
		   SET D_FecResuelto = @D_FecProceso,
		   	   B_Resuelto = 1
		  FROM TI_ObservacionRegistroTabla OBS
		  	   INNER JOIN (SELECT Det.I_RowID, Det.I_ProcedenciaID, tmp.I_RowID as TempRowID
			   				 FROM TR_Ec_Det Det
								  LEFT JOIN #temp_detalle_sin_periodo_equiv tmp ON tmp.I_RowID = Det.I_RowID
							WHERE tmp.I_RowID IS NULL
								  AND Ano = @T_Anio 
								  AND I_ProcedenciaID = @I_ProcedenciaID
			   			  ) DET ON OBS.I_FilaTablaID = DET.I_RowID
						  		   AND OBS.I_ProcedenciaID = DET.I_ProcedenciaID 
		 WHERE OBS.I_ObservID = @I_ObservID 
		 	   AND OBS.I_TablaID = @I_TablaID 
			   AND OBS.I_ProcedenciaID = @I_ProcedenciaID

		SET @I_Observados = (SELECT COUNT(*) 
							   FROM TI_ObservacionRegistroTabla OBS 
									INNER JOIN TR_Ec_Det DET ON OBS.I_FilaTablaID = DET.I_RowID 
																AND DET.I_ProcedenciaID = OBS.I_ProcedenciaID
							  WHERE OBS.I_ObservID = @I_ObservID 
									AND DET.Ano = @T_Anio
									AND DET.I_ProcedenciaID = @I_ProcedenciaID 
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


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_Obligaciones_ObligacionDet_MigracionTP_U_Validar_44_PeriodoDetallePeriodoConceptoPorOblID')
	DROP PROCEDURE [dbo].[USP_Obligaciones_ObligacionDet_MigracionTP_U_Validar_44_PeriodoDetallePeriodoConceptoPorOblID]
GO

CREATE PROCEDURE [dbo].[USP_Obligaciones_ObligacionDet_MigracionTP_U_Validar_44_PeriodoDetallePeriodoConceptoPorOblID]
	@I_OblRowID	  int,
	@B_Resultado  bit output,
	@T_Message    nvarchar(4000) OUTPUT	
AS
/*
	DESCRIPCION: Marcar TR_Ec_Obl con B_Migrable = 0 cuando la obligacion no tiene registros asociados en el detalle para el ID de obligacion.

	DECLARE @I_OblRowID	  int,
			@B_Resultado  bit,
			@T_Message    nvarchar(4000)
	EXEC USP_Obligaciones_ObligacionDet_MigracionTP_U_Validar_44_PeriodoDetallePeriodoConceptoPorOblID @I_OblRowID, @B_Resultado output, @T_Message output
	SELECT @B_Resultado as resultado, @T_Message as mensaje
*/
BEGIN
	DECLARE @I_Observados int = 0
	DECLARE @I_ObservadosObl int = 0
	DECLARE @D_FecProceso datetime = GETDATE() 
	DECLARE @I_ObservID int = 44
	DECLARE @I_TablaID int = 4

	BEGIN TRANSACTION
	BEGIN TRY
		SELECT I_RowID, I_OblRowID
		  INTO #temp_detalle_sin_periodo_equiv
		  FROM TR_Ec_Det Det
			   LEFT JOIN BD_OCEF_CtasPorCobrar.dbo.TC_CatalogoOpcion Ctas_Opc 
					  ON Det.P COLLATE SQL_Latin1_General_CP1_CI_AI = Ctas_opc.T_OpcionCod COLLATE SQL_Latin1_General_CP1_CI_AI
		 WHERE Ctas_Opc.I_OpcionID IS NULL

		UPDATE	Det
		SET		B_Migrable = 0,
				D_FecEvalua = @D_FecProceso
		FROM	TR_Ec_Det Det
				INNER JOIN #temp_detalle_sin_periodo_equiv tmp ON tmp.I_RowID = Det.I_RowID
		WHERE	Det.I_OblRowID = @I_OblRowID

		MERGE TI_ObservacionRegistroTabla AS TRG
		USING (SELECT @I_ObservID AS I_ObservID, @I_TablaID AS I_TablaID, Det.I_RowID AS I_FilaTablaID, @D_FecProceso AS D_FecRegistro,  
					  Det.I_ProcedenciaID
				 FROM TR_Ec_Det Det
					  INNER JOIN #temp_detalle_sin_periodo_equiv tmp ON tmp.I_RowID = Det.I_RowID
				WHERE Det.I_OblRowID = @I_OblRowID
			  ) AS SRC
		ON TRG.I_ObservID = SRC.I_ObservID AND TRG.I_TablaID = SRC.I_TablaID AND TRG.I_FilaTablaID = SRC.I_FilaTablaID
		WHEN MATCHED AND TRG.I_ProcedenciaID = SRC.I_ProcedenciaID THEN
			UPDATE SET D_FecRegistro = SRC.D_FecRegistro
		WHEN NOT MATCHED BY TARGET THEN
			INSERT (I_ObservID, I_TablaID, I_FilaTablaID, D_FecRegistro, I_ProcedenciaID, B_ObligProc)
			VALUES (SRC.I_ObservID, SRC.I_TablaID, SRC.I_FilaTablaID, SRC.D_FecRegistro, SRC.I_ProcedenciaID, 1);

		UPDATE OBS
		   SET D_FecResuelto = @D_FecProceso,
		   	   B_Resuelto = 1
		  FROM TI_ObservacionRegistroTabla OBS
		  	   INNER JOIN (SELECT Det.I_RowID, Det.I_ProcedenciaID, tmp.I_RowID as TempRowID
			   				 FROM TR_Ec_Det Det
								  LEFT JOIN #temp_detalle_sin_periodo_equiv tmp ON tmp.I_RowID = Det.I_OblRowID
							WHERE tmp.I_RowID IS NULL
								  AND Det.I_OblRowID = @I_OblRowID
			   			  ) DET ON OBS.I_FilaTablaID = DET.I_RowID
						  		   AND OBS.I_ProcedenciaID = DET.I_ProcedenciaID 
		 WHERE OBS.I_ObservID = @I_ObservID 
		 	   AND OBS.I_TablaID = @I_TablaID 

		SET @I_Observados = (SELECT COUNT(*) 
							   FROM TI_ObservacionRegistroTabla OBS 
									INNER JOIN TR_Ec_Det DET ON OBS.I_FilaTablaID = DET.I_RowID 
																AND DET.I_ProcedenciaID = OBS.I_ProcedenciaID
							  WHERE OBS.I_ObservID = @I_ObservID 
									AND DET.I_OblRowID = @I_OblRowID
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
	DESCRIPCION: Marcar TR_Ec_Det con B_Migrable = 0 cuando la suma de los montos en el detalle no coinciden con el monto de la cabecera para el año y procedencia.

	DECLARE	@B_Resultado  bit,
			@I_ProcedenciaID	tinyint = 2,
			@T_Anio				varchar(4) = '2016',
			@T_Message			nvarchar(4000)
	EXEC USP_Obligaciones_ObligacionDet_MigracionTP_U_Validar_49_MontoDetalleMontoCab @I_ProcedenciaID, @T_Anio, @B_Resultado output, @T_Message output
	SELECT @B_Resultado as resultado, @T_Message as mensaje
*/
BEGIN
	DECLARE @I_Observados int = 0
	DECLARE @D_FecProceso datetime = GETDATE() 
	DECLARE @I_ObservID int = 49
	DECLARE @I_TablaID int = 4

	BEGIN TRANSACTION
	BEGIN TRY 
		SELECT I_OblRowID, SUM(Monto) Monto
		  INTO #temp_detalle_monto_sum
		  FROM TR_Ec_Det
		 WHERE Ano = @T_Anio
			   AND I_ProcedenciaID = @I_ProcedenciaID
			   AND Eliminado = 0
		 GROUP BY I_OblRowID

		SELECT I_OblRowID  
		  INTO #temp_detalle_monto_cabecera_monto
		  FROM TR_Ec_Obl Obl
			   INNER JOIN #temp_detalle_monto_sum tmp ON Obl.I_RowID = tmp.I_OblRowID
		 WHERE Obl.Monto <> tmp.Monto

		UPDATE Det
		   SET B_Migrable = 0,
			   D_FecEvalua = @D_FecProceso
		  FROM TR_Ec_Det Det 
			   INNER JOIN #temp_detalle_monto_cabecera_monto tmp ON Det.I_OblRowID = tmp.I_OblRowID

		MERGE TI_ObservacionRegistroTabla AS TRG
		USING (SELECT @I_ObservID AS I_ObservID, @I_TablaID AS I_TablaID, Det.I_RowID AS I_FilaTablaID, 
					  @D_FecProceso AS D_FecRegistro, Det.I_ProcedenciaID 
				 FROM TR_Ec_Det Det 
					  INNER JOIN #temp_detalle_monto_cabecera_monto tmp ON Det.I_OblRowID = tmp.I_OblRowID
			  ) AS SRC
		ON TRG.I_ObservID = SRC.I_ObservID AND TRG.I_TablaID = SRC.I_TablaID AND TRG.I_FilaTablaID = SRC.I_FilaTablaID
		WHEN MATCHED AND TRG.I_ProcedenciaID = SRC.I_ProcedenciaID THEN
			UPDATE SET D_FecRegistro = SRC.D_FecRegistro
		WHEN NOT MATCHED BY TARGET THEN
			INSERT (I_ObservID, I_TablaID, I_FilaTablaID, D_FecRegistro, I_ProcedenciaID, B_ObligProc)
			VALUES (SRC.I_ObservID, SRC.I_TablaID, SRC.I_FilaTablaID, SRC.D_FecRegistro, @I_ProcedenciaID, 1);
		
		UPDATE OBS
		   SET D_FecResuelto = @D_FecProceso,
		   	   B_Resuelto = 1
		  FROM TI_ObservacionRegistroTabla OBS
		  	   INNER JOIN (SELECT Det.I_RowID, Det.I_ProcedenciaID, tmp.I_OblRowID as TempOblRowID
			   				 FROM TR_Ec_Det Det
								  LEFT JOIN #temp_detalle_monto_cabecera_monto tmp ON tmp.I_OblRowID = Det.I_OblRowID
							WHERE tmp.I_OblRowID IS NULL
								  AND Det.Ano = @T_Anio
								  AND Det.I_ProcedenciaID = @I_ProcedenciaID
			   			  ) DET ON OBS.I_FilaTablaID = DET.I_RowID
						  		   AND OBS.I_ProcedenciaID = DET.I_ProcedenciaID 
		 WHERE OBS.I_ObservID = @I_ObservID 
		 	   AND OBS.I_TablaID = @I_TablaID 
		
		SET @I_Observados = (SELECT COUNT(*) 
							   FROM TI_ObservacionRegistroTabla OBS 
									INNER JOIN TR_Ec_Det DET ON OBS.I_FilaTablaID = DET.I_RowID 
																AND DET.I_ProcedenciaID = OBS.I_ProcedenciaID
							  WHERE OBS.I_ObservID = @I_ObservID 
									AND Det.Ano = @T_Anio
									AND Det.I_ProcedenciaID = @I_ProcedenciaID 
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


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_Obligaciones_ObligacionDet_MigracionTP_U_Validar_49_MontoDetalleMontoCabPorOblID')
	DROP PROCEDURE [dbo].[USP_Obligaciones_ObligacionDet_MigracionTP_U_Validar_49_MontoDetalleMontoCabPorOblID]
GO

CREATE PROCEDURE [dbo].[USP_Obligaciones_ObligacionDet_MigracionTP_U_Validar_49_MontoDetalleMontoCabPorOblID]
	@I_OblRowID	  int,
	@B_Resultado  bit output,
	@T_Message    nvarchar(4000) OUTPUT	
AS
/*
	DESCRIPCION: Marcar TR_Ec_Obl con B_Migrable = 0 cuando la suma de los montos en el detalle no coinciden con el monto de la cabecera para el ID de obligacion.

	DECLARE @I_OblRowID	  int,
			@B_Resultado  bit,
			@T_Message    nvarchar(4000)
	EXEC USP_Obligaciones_ObligacionDet_MigracionTP_U_Validar_49_MontoDetalleMontoCabPorOblID @I_OblRowID, @B_Resultado output, @T_Message output
	SELECT @B_Resultado as resultado, @T_Message as mensaje
*/
BEGIN
	DECLARE @I_Observados int = 0
	DECLARE @D_FecProceso datetime = GETDATE() 
	DECLARE @I_ObservID int = 49
	DECLARE @I_TablaID int = 4

	BEGIN TRANSACTION
	BEGIN TRY
		SELECT I_OblRowID, SUM(Monto) Monto
		  INTO #temp_detalle_monto_sum
		  FROM TR_Ec_Det
		 WHERE Eliminado = 0
			   AND I_RowID = @I_OblRowID
		 GROUP BY I_OblRowID

		SELECT I_OblRowID  
		  INTO #temp_detalle_monto_cabecera_monto
		  FROM TR_Ec_Obl Obl
			   INNER JOIN #temp_detalle_monto_sum tmp ON Obl.I_RowID = tmp.I_OblRowID
		 WHERE Obl.Monto <> tmp.Monto

		UPDATE Det
		   SET B_Migrable = 0,
			   D_FecEvalua = @D_FecProceso
		  FROM TR_Ec_Det Det 
			   INNER JOIN #temp_detalle_monto_cabecera_monto tmp ON Det.I_OblRowID = tmp.I_OblRowID
		 

		MERGE TI_ObservacionRegistroTabla AS TRG
		USING (SELECT @I_ObservID AS I_ObservID, @I_TablaID AS I_TablaID, Det.I_RowID AS I_FilaTablaID, 
					  @D_FecProceso AS D_FecRegistro, Det.I_ProcedenciaID 
				 FROM TR_Ec_Det Det 
					  INNER JOIN #temp_detalle_monto_cabecera_monto tmp ON Det.I_OblRowID = tmp.I_OblRowID
			  ) AS SRC
		ON TRG.I_ObservID = SRC.I_ObservID AND TRG.I_TablaID = SRC.I_TablaID AND TRG.I_FilaTablaID = SRC.I_FilaTablaID
		WHEN MATCHED AND TRG.I_ProcedenciaID = SRC.I_ProcedenciaID THEN
			UPDATE SET D_FecRegistro = SRC.D_FecRegistro
		WHEN NOT MATCHED BY TARGET THEN
			INSERT (I_ObservID, I_TablaID, I_FilaTablaID, D_FecRegistro, I_ProcedenciaID, B_ObligProc)
			VALUES (SRC.I_ObservID, SRC.I_TablaID, SRC.I_FilaTablaID, SRC.D_FecRegistro, SRC.I_ProcedenciaID, 1);
		
		UPDATE OBS
		   SET D_FecResuelto = @D_FecProceso,
		   	   B_Resuelto = 1
		  FROM TI_ObservacionRegistroTabla OBS
		  	   INNER JOIN (SELECT Det.I_RowID, Det.I_ProcedenciaID, tmp.I_OblRowID as TempOblRowID
			   				 FROM TR_Ec_Det Det
								  LEFT JOIN #temp_detalle_monto_cabecera_monto tmp ON tmp.I_OblRowID = Det.I_OblRowID
							WHERE tmp.I_OblRowID IS NULL
								  AND Det.I_OblRowID = @I_OblRowID
			   			  ) DET ON OBS.I_FilaTablaID = DET.I_RowID
						  		   AND OBS.I_ProcedenciaID = DET.I_ProcedenciaID 
		 WHERE OBS.I_ObservID = @I_ObservID 
		 	   AND OBS.I_TablaID = @I_TablaID 
		
		SET @I_Observados = (SELECT COUNT(*) 
							   FROM TI_ObservacionRegistroTabla OBS 
									INNER JOIN TR_Ec_Det DET ON OBS.I_FilaTablaID = DET.I_RowID 
																AND DET.I_ProcedenciaID = OBS.I_ProcedenciaID
							  WHERE OBS.I_ObservID = @I_ObservID 
									AND Det.I_OblRowID = @I_OblRowID
									AND OBS.B_Resuelto = 0
							)
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
		UPDATE	TR_Ec_Det
		SET		B_Migrable = 0,
				D_FecEvalua = @D_FecProceso
		WHERE	I_OblRowID IS NULL
				AND Ano = @T_Anio 
				AND I_ProcedenciaID = @I_ProcedenciaID


		MERGE TI_ObservacionRegistroTabla AS TRG
		USING 	(SELECT	@I_ObservID AS I_ObservID, @I_TablaID AS I_TablaID, I_RowID AS I_FilaTablaID, @D_FecProceso AS D_FecRegistro 
				   FROM	TR_Ec_Det 
				  WHERE	I_OblRowID IS NULL
						AND Ano = @T_Anio 
						AND I_ProcedenciaID = @I_ProcedenciaID
				) AS SRC
		ON TRG.I_ObservID = SRC.I_ObservID AND TRG.I_TablaID = SRC.I_TablaID AND TRG.I_FilaTablaID = SRC.I_FilaTablaID
		WHEN MATCHED AND TRG.I_ProcedenciaID = @I_ProcedenciaID THEN
			UPDATE SET D_FecRegistro = SRC.D_FecRegistro
		WHEN NOT MATCHED BY TARGET THEN
			INSERT (I_ObservID, I_TablaID, I_FilaTablaID, D_FecRegistro, I_ProcedenciaID, B_ObligProc)
			VALUES (SRC.I_ObservID, SRC.I_TablaID, SRC.I_FilaTablaID, SRC.D_FecRegistro, @I_ProcedenciaID, 1);


		UPDATE OBS
		   SET D_FecResuelto = @D_FecProceso,
			   B_Resuelto = 1
		  FROM TI_ObservacionRegistroTabla OBS
			   INNER JOIN (SELECT I_RowID, I_ProcedenciaID FROM TR_Ec_Det 
							WHERE I_OblRowID IS NULL
								  AND Ano = @T_Anio 
								  AND I_ProcedenciaID = @I_ProcedenciaID) DET
						   ON OBS.I_FilaTablaID = DET.I_RowID
							  AND OBS.I_ProcedenciaID = DET.I_ProcedenciaID
		 WHERE OBS.I_ObservID = @I_ObservID 
			   AND OBS.I_TablaID = @I_TablaID

		SET @I_Observados = (SELECT COUNT(*) FROM TI_ObservacionRegistroTabla 
											WHERE I_ObservID = @I_ObservID 
												  AND I_TablaID = @I_TablaID
												  AND I_ProcedenciaID = @I_ProcedenciaID
												  AND B_Resuelto = 0) 

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



