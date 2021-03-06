USE BD_OCEF_MigracionTP
GO


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_U_ActualizarRegistroAlumno')
	DROP PROCEDURE [dbo].[USP_U_ActualizarRegistroAlumno]
GO

CREATE PROCEDURE USP_U_ActualizarRegistroAlumno
	@I_RowID	  int,
	@C_CodAlu	  varchar(20), 
	@C_NumDNI	  varchar(20), 
	@C_CodTipDoc  varchar(5), 
	@T_ApePaterno varchar(50),  
	@T_ApeMaterno varchar(50),  
	@T_Nombre	  varchar(50), 
	@C_Sexo		  char(1), 
	@D_FecNac	  date, 
	@C_CodModIng  varchar(2), 	 
	@C_AnioIngres smallint,
	@B_Resultado  bit output,
	@T_Message	  nvarchar(4000) OUTPUT	
AS
--declare @B_Resultado  bit,
--		  @T_Message	nvarchar(4000)
--exec USP_U_ActualizarRegistroAlumno @B_Resultado output, @T_Message output
--select @B_Resultado as resultado, @T_Message as mensaje
BEGIN

	DECLARE @D_FecProceso datetime = GETDATE() 

	BEGIN TRY 
		UPDATE TR_Alumnos
		SET	C_CodAlu = @C_CodAlu,
			C_NumDNI = @C_NumDNI,
			C_CodTipDoc = @C_CodTipDoc,
			T_ApePaterno = @T_ApePaterno, 
			T_ApeMaterno = @T_ApeMaterno, 
			T_Nombre = @T_Nombre,
			C_Sexo = @C_Sexo,
			D_FecNac = @D_FecNac,
			C_AnioIngreso = @C_AnioIngres
		WHERE 
			I_RowID = @I_RowID

		
		SET @T_Message =  @@ROWCOUNT
		SET @B_Resultado = 1

	END TRY
	BEGIN CATCH
		SET @B_Resultado = 0
		SET @T_Message = ERROR_MESSAGE() + ' (Linea: ' + CAST(ERROR_LINE() AS varchar(11)) + ').' 
	END CATCH
END
GO


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_IU_CopiarTablaAlumno')
	DROP PROCEDURE [dbo].[USP_IU_CopiarTablaAlumno]
GO

CREATE PROCEDURE USP_IU_CopiarTablaAlumno	
	@B_Resultado  bit output,
	@T_Message	  nvarchar(4000) OUTPUT	
AS
--declare @B_Resultado  bit,
--		  @T_Message	nvarchar(4000)
--exec USP_IU_CopiarTablaAlumno @B_Resultado output, @T_Message output
--select @B_Resultado as resultado, @T_Message as mensaje
BEGIN
	DECLARE @I_CantAlu int = 0
	DECLARE @I_Removidos int = 0
	DECLARE @I_Actualizados int = 0
	DECLARE @I_Insertados int = 0
	DECLARE @D_FecProceso datetime = GETDATE() 

	DECLARE @Tbl_output AS TABLE 
	(
		accion			  varchar(20), 
		C_RcCod			  varchar(3), 
		C_CodAlu		  varchar(20), 
		INS_C_NumDNI	  varchar(20), 
		INS_C_CodTipDoc   varchar(5),
		INS_T_ApePaterno  varchar(50), 
		INS_T_ApeMaterno  varchar(50), 
		INS_T_Nombre	  varchar(50), 
		INS_C_Sexo		  char(1), 
		INS_D_FecNac	  date, 
		INS_C_CodModIng	  varchar(2), 
		INS_C_AnioIngreso smallint, 
		DEL_C_NumDNI	  varchar(20), 
		DEL_C_CodTipDoc   varchar(5),
		DEL_T_ApePaterno  varchar(50), 
		DEL_T_ApeMaterno  varchar(50), 
		DEL_T_Nombre	  varchar(50), 
		DEL_C_Sexo		  char(1), 
		DEL_D_FecNac	  date, 
		DEL_C_CodModIng	  varchar(2), 
		DEL_C_AnioIngreso smallint, 
		B_Removido	bit
	)

	BEGIN TRY 
	
		MERGE TR_Alumnos AS TRG
		USING (SELECT DISTINCT * FROM BD_OCEF_TemporalPagos.dbo.alumnos) AS SRC
		ON	TRG.C_CodAlu = SRC.C_CodAlu 
			AND TRG.C_RcCod = SRC.C_RcCod
			AND ISNULL(TRG.C_CodModIng, '') = ISNULL(SRC.C_CODMODIN, '')
			AND TRG.C_AnioIngreso = SRC.C_ANIOINGR
		WHEN MATCHED THEN
			UPDATE SET	TRG.C_NumDNI = CASE WHEN SRC.C_NUMDNI = '' THEN NULL ELSE SRC.C_NUMDNI END,
						TRG.C_CodTipDoc = CASE WHEN SRC.C_CODTIPDO = '' THEN NULL ELSE SRC.C_CODTIPDO END,
						TRG.T_ApePaterno = REPLACE(SRC.T_APEPATER, '-', ' '),
						TRG.T_ApeMaterno = REPLACE(SRC.T_APEMATER, '-', ' '),
						TRG.T_Nombre = REPLACE(SRC.T_NOMBRE, '-', ' '),
						TRG.C_Sexo = SRC.C_SEXO,
						TRG.D_FecNac = CASE WHEN TRY_CONVERT(DATE, SRC.D_FECNAC, 103) IS NULL THEN IIF(ISDATE(SRC.D_FECNAC) = 1, SRC.D_FECNAC, NULL) ELSE CONVERT(DATE, SRC.D_FECNAC, 103) END
		WHEN NOT MATCHED BY TARGET THEN
			INSERT (C_RcCod, C_CodAlu, C_NumDNI, C_CodTipDoc, T_ApePaterno, T_ApeMaterno, T_Nombre, C_Sexo, D_FecNac, C_CodModIng, C_AnioIngreso, I_ProcedenciaID, D_FecCarga, B_Actualizado)
			VALUES (SRC.C_RcCod, SRC.C_CodAlu, CASE WHEN SRC.C_NUMDNI = '' THEN NULL ELSE SRC.C_NUMDNI END, CASE WHEN SRC.C_CODTIPDO = '' THEN NULL ELSE SRC.C_CODTIPDO END,
			 REPLACE(SRC.T_APEPATER, '-', ' '), REPLACE(SRC.T_APEMATER, '-', ' '), REPLACE(SRC.T_NOMBRE, '-', ' '), 
					SRC.C_SEXO, CASE WHEN TRY_CONVERT(DATE, SRC.D_FECNAC, 103) IS NULL THEN IIF(ISDATE(SRC.D_FECNAC) = 1, SRC.D_FECNAC, NULL) ELSE CONVERT(DATE, SRC.D_FECNAC, 103) END, 
					SRC.C_CODMODIN, SRC.C_ANIOINGR, 4, @D_FecProceso, 1)
		WHEN NOT MATCHED BY SOURCE THEN
			UPDATE SET TRG.B_Removido = 1, 
					   TRG.D_FecRemovido = @D_FecProceso
		OUTPUT	$ACTION, inserted.C_RcCod, inserted.C_CodAlu, inserted.C_NumDNI, inserted.C_CodTipDoc, inserted.T_ApePaterno,   
				inserted.T_ApeMaterno, inserted.T_Nombre, inserted.C_Sexo, inserted.D_FecNac, inserted.C_CodModIng, inserted.C_AnioIngreso, 
				deleted.C_NumDNI, deleted.C_CodTipDoc, deleted.T_ApePaterno, deleted.T_ApeMaterno, deleted.T_Nombre, 
				deleted.C_Sexo, deleted.D_FecNac, deleted.C_CodModIng, deleted.C_AnioIngreso, deleted.B_Removido INTO @Tbl_output;
		
		UPDATE	TR_Alumnos 
				SET	B_Actualizado = 0, B_Migrable = 1, D_FecMigrado = NULL, B_Migrado = 0

		UPDATE	t_Alu
		SET		t_Alu.B_Actualizado = 1,
				t_Alu.D_FecActualiza = @D_FecProceso
		FROM TR_Alumnos AS t_Alu
				INNER JOIN 	@Tbl_output as t_out ON t_out.C_RcCod = t_Alu.C_RcCod 
				AND t_out.C_CodAlu = t_Alu.C_CodAlu AND t_out.accion = 'UPDATE' AND t_out.B_Removido = 0
		WHERE 
				t_out.INS_C_NumDNI <> t_out.DEL_C_NumDNI OR
				t_out.INS_C_CodTipDoc <> t_out.DEL_C_CodTipDoc OR
				t_out.INS_T_ApePaterno <> t_out.DEL_T_ApePaterno OR
				t_out.INS_T_ApeMaterno <> t_out.DEL_T_ApeMaterno OR
				t_out.INS_T_Nombre <> t_out.DEL_T_Nombre OR
				t_out.INS_C_Sexo <> t_out.DEL_C_Sexo OR
				ISNULL(t_out.INS_D_FecNac, '19010101') <> ISNULL(t_out.DEL_D_FecNac, '19010101') OR
				ISNULL(t_out.INS_C_CodModIng, '') <> ISNULL(t_out.DEL_C_CodModIng, '') OR
				t_out.INS_C_AnioIngreso <> t_out.DEL_C_AnioIngreso

		SET @I_CantAlu = (SELECT COUNT(*) FROM BD_OCEF_TemporalPagos.dbo.alumnos)
		SET @I_Insertados = (SELECT COUNT(*) FROM @Tbl_output WHERE accion = 'INSERT')
		SET @I_Actualizados = (SELECT COUNT(*) FROM @Tbl_output WHERE accion = 'UPDATE' AND B_Removido = 0)
		SET @I_Removidos = (SELECT COUNT(*) FROM @Tbl_output WHERE accion = 'UPDATE' AND B_Removido = 1)

		SET @B_Resultado = 1
		SET @T_Message =  'Total: ' + CAST(@I_CantAlu AS varchar) 

		SELECT @I_CantAlu AS tot_alumnos, @I_Insertados AS cant_inserted, @I_Actualizados as cant_updated, @I_Removidos as cant_removed, @D_FecProceso as fec_proceso
	END TRY
	BEGIN CATCH
		SET @B_Resultado = 0
		SET @T_Message = ERROR_MESSAGE() + ' (Linea: ' + CAST(ERROR_LINE() AS varchar(11)) + ').' 
	END CATCH
END
GO


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_U_ValidarCaracteresEspeciales')
	DROP PROCEDURE [dbo].[USP_U_ValidarCaracteresEspeciales]
GO

CREATE PROCEDURE USP_U_ValidarCaracteresEspeciales	
	@B_Resultado  bit output,
	@T_Message	  nvarchar(4000) OUTPUT	
AS
--declare @B_Resultado  bit,
--		@T_Message	  nvarchar(4000)
--exec USP_U_ValidarCaracteresEspeciales @B_Resultado output, @T_Message output
--select @B_Resultado as resultado, @T_Message as mensaje
BEGIN
	DECLARE @I_Observados int = 0
	DECLARE @D_FecProceso datetime = GETDATE() 
	DECLARE @I_ObservID int = 1
	DECLARE @I_TablaID int = 1

	BEGIN TRANSACTION
	BEGIN TRY 
		UPDATE	TR_Alumnos
		SET		B_Migrable = 0,
				D_FecEvalua = @D_FecProceso
		WHERE	
				PATINDEX('%[^a-zA-Z0-9.'' ]%', REPLACE(T_Nombre, '-', ' ')) <> 0 
				OR PATINDEX('%[^a-zA-Z0-9.'' ]%', REPLACE(T_ApePaterno, '-', ' ')) <> 0 
				OR PATINDEX('%[^a-zA-Z0-9.'' ]%', REPLACE(T_ApeMaterno, '-', ' ')) <> 0

		MERGE TI_ObservacionRegistroTabla AS TRG
		USING 	(SELECT	@I_ObservID AS I_ObservID, @I_TablaID AS I_TablaID, I_RowID AS I_FilaTablaID, @D_FecProceso AS D_FecRegistro FROM TR_Alumnos
				  WHERE	PATINDEX('%[^a-zA-Z0-9.'' ]%', REPLACE(T_Nombre, '-', ' ')) <> 0 
						OR PATINDEX('%[^a-zA-Z0-9.'' ]%', REPLACE(T_ApePaterno, '-', ' ')) <> 0 
						OR PATINDEX('%[^a-zA-Z0-9.'' ]%', REPLACE(T_ApeMaterno, '-', ' ')) <> 0) AS SRC
		ON TRG.I_ObservID = SRC.I_ObservID AND TRG.I_TablaID = SRC.I_TablaID AND TRG.I_FilaTablaID = SRC.I_FilaTablaID
		WHEN MATCHED THEN
			UPDATE SET D_FecRegistro = SRC.D_FecRegistro
		WHEN NOT MATCHED BY TARGET THEN
			INSERT (I_ObservID, I_TablaID, I_FilaTablaID, D_FecRegistro)
			VALUES (SRC.I_ObservID, SRC.I_TablaID, SRC.I_FilaTablaID, SRC.D_FecRegistro)
		WHEN NOT MATCHED BY SOURCE AND TRG.I_ObservID = @I_ObservID THEN
			DELETE;

		SET @I_Observados = (SELECT COUNT(*) FROM TI_ObservacionRegistroTabla WHERE I_ObservID = @I_ObservID AND I_TablaID = @I_TablaID)

		SELECT @I_Observados as cant_obs, @D_FecProceso as fec_proceso
				
		COMMIT TRANSACTION
		SET @B_Resultado = 1
		SET @T_Message = CAST(@I_Observados AS varchar)
	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION
		SET @B_Resultado = 0
		SET @T_Message = ERROR_MESSAGE() + ' (Linea: ' + CAST(ERROR_LINE() AS varchar(11)) + ').' 
	END CATCH
END
GO


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_U_ValidarCodigosAlumnoRepetidos')
	DROP PROCEDURE [dbo].[USP_U_ValidarCodigosAlumnoRepetidos]
GO

CREATE PROCEDURE USP_U_ValidarCodigosAlumnoRepetidos	
	@B_Resultado  bit output,
	@T_Message	  nvarchar(4000) OUTPUT	
AS
--declare @B_Resultado  bit,
--		@T_Message	  nvarchar(4000)
--exec USP_U_ValidarCodigosAlumnoRepetidos @B_Resultado output, @T_Message output
--select @B_Resultado as resultado, @T_Message as mensaje
BEGIN
	DECLARE @I_Observados int = 0
	DECLARE @D_FecProceso datetime = GETDATE() 
	DECLARE @I_ObservID int = 2
	DECLARE @I_TablaID int = 1

	BEGIN TRANSACTION
	BEGIN TRY 
		UPDATE	TR_Alumnos
		SET		B_Migrable = 0,
				D_FecEvalua = @D_FecProceso
		WHERE	EXISTS (SELECT C_CodAlu, C_RcCod, COUNT(*) FROM TR_Alumnos A 
						WHERE A.C_CodAlu = TR_Alumnos.C_CodAlu AND A.C_RcCod = TR_Alumnos.C_RcCod
						GROUP BY C_CodAlu, C_RcCod HAVING COUNT(*) > 1)
				
		MERGE TI_ObservacionRegistroTabla AS TRG
		USING 	(SELECT	@I_ObservID AS I_ObservID, @I_TablaID AS I_TablaID, I_RowID AS I_FilaTablaID, @D_FecProceso AS D_FecRegistro FROM TR_Alumnos
				  WHERE	EXISTS (SELECT C_CodAlu, C_RcCod, COUNT(*) FROM TR_Alumnos A 
						WHERE A.C_CodAlu = TR_Alumnos.C_CodAlu AND A.C_RcCod = TR_Alumnos.C_RcCod
						GROUP BY C_CodAlu, C_RcCod HAVING COUNT(*) > 1)) AS SRC
		ON TRG.I_ObservID = SRC.I_ObservID AND TRG.I_TablaID = SRC.I_TablaID AND TRG.I_FilaTablaID = SRC.I_FilaTablaID
		WHEN MATCHED THEN
			UPDATE SET D_FecRegistro = SRC.D_FecRegistro
		WHEN NOT MATCHED BY TARGET THEN
			INSERT (I_ObservID, I_TablaID, I_FilaTablaID, D_FecRegistro)
			VALUES (SRC.I_ObservID, SRC.I_TablaID, SRC.I_FilaTablaID, SRC.D_FecRegistro)
		WHEN NOT MATCHED BY SOURCE AND TRG.I_ObservID = @I_ObservID THEN
			DELETE;

		SET @I_Observados = (SELECT COUNT(*) FROM TI_ObservacionRegistroTabla WHERE I_ObservID = @I_ObservID AND I_TablaID = @I_TablaID)

		SELECT @I_Observados as cant_obs, @D_FecProceso as fec_proceso
				
		COMMIT TRANSACTION
		SET @B_Resultado = 1
		SET @T_Message = CAST(@I_Observados AS varchar)
	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION
		SET @B_Resultado = 0
		SET @T_Message = ERROR_MESSAGE() + ' (Linea: ' + CAST(ERROR_LINE() AS varchar(11)) + ').' 
	END CATCH
END
GO


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_U_ValidarCodigoCarreraAlumno')
	DROP PROCEDURE [dbo].[USP_U_ValidarCodigoCarreraAlumno]
GO

CREATE PROCEDURE USP_U_ValidarCodigoCarreraAlumno	
	@B_Resultado  bit output,
	@T_Message	  nvarchar(4000) OUTPUT	
AS
--declare @B_Resultado  bit,
--		@T_Message	  nvarchar(4000)
--exec USP_U_ValidarCodigoCarreraAlumno @B_Resultado output, @T_Message output
--select @B_Resultado as resultado, @T_Message as mensaje
BEGIN
	DECLARE @I_Observados int = 0
	DECLARE @D_FecProceso datetime = GETDATE() 
	DECLARE @I_ObservID int = 21
	DECLARE @I_TablaID int = 1

	BEGIN TRANSACTION
	BEGIN TRY 
		UPDATE	TR_Alumnos
		SET		B_Migrable = 0,
				D_FecEvalua = @D_FecProceso
		WHERE	NOT EXISTS (SELECT C_RcCod FROM BD_UNFV_Repositorio.dbo.TI_CarreraProfesional c
							WHERE C.C_RcCod = TR_Alumnos.C_RcCod)
					
		MERGE TI_ObservacionRegistroTabla AS TRG
		USING 	(SELECT	@I_ObservID AS I_ObservID, @I_TablaID AS I_TablaID, I_RowID AS I_FilaTablaID, @D_FecProceso AS D_FecRegistro FROM TR_Alumnos
				  WHERE	NOT EXISTS (SELECT C_RcCod FROM BD_UNFV_Repositorio.dbo.TI_CarreraProfesional c
							WHERE C.C_RcCod = TR_Alumnos.C_RcCod)) AS SRC
		ON TRG.I_ObservID = SRC.I_ObservID AND TRG.I_TablaID = SRC.I_TablaID AND TRG.I_FilaTablaID = SRC.I_FilaTablaID
		WHEN MATCHED THEN
			UPDATE SET D_FecRegistro = SRC.D_FecRegistro
		WHEN NOT MATCHED BY TARGET THEN
			INSERT (I_ObservID, I_TablaID, I_FilaTablaID, D_FecRegistro)
			VALUES (SRC.I_ObservID, SRC.I_TablaID, SRC.I_FilaTablaID, SRC.D_FecRegistro)
		WHEN NOT MATCHED BY SOURCE AND TRG.I_ObservID = @I_ObservID THEN
			DELETE;

		SET @I_Observados = (SELECT COUNT(*) FROM TI_ObservacionRegistroTabla WHERE I_ObservID = @I_ObservID AND I_TablaID = @I_TablaID)

		SELECT @I_Observados as cant_obs, @D_FecProceso as fec_proceso
				
		COMMIT TRANSACTION
		SET @B_Resultado = 1
		SET @T_Message = CAST(@I_Observados AS varchar)
	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION
		SET @B_Resultado = 0
		SET @T_Message = ERROR_MESSAGE() + ' (Linea: ' + CAST(ERROR_LINE() AS varchar(11)) + ').' 
	END CATCH
END
GO


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_U_ValidarAnioIngresoAlumno')
	DROP PROCEDURE [dbo].[USP_U_ValidarAnioIngresoAlumno]
GO

CREATE PROCEDURE USP_U_ValidarAnioIngresoAlumno	
	@B_Resultado  bit output,
	@T_Message	  nvarchar(4000) OUTPUT	
AS
--declare @B_Resultado  bit,
--		@T_Message	  nvarchar(4000)
--exec USP_U_ValidarAnioIngresoAlumno @B_Resultado output, @T_Message output
--select @B_Resultado as resultado, @T_Message as mensaje
BEGIN
	DECLARE @I_Observados int = 0
	DECLARE @D_FecProceso datetime = GETDATE() 
	DECLARE @I_ObservID int = 22
	DECLARE @I_TablaID int = 1

	BEGIN TRANSACTION
	BEGIN TRY 
		UPDATE	TR_Alumnos
		SET		B_Migrable = 0,
				D_FecEvalua = @D_FecProceso
		WHERE	C_AnioIngreso IS NULL OR C_AnioIngreso = 0
					
		MERGE TI_ObservacionRegistroTabla AS TRG
		USING 	(SELECT	@I_ObservID AS I_ObservID, @I_TablaID AS I_TablaID, I_RowID AS I_FilaTablaID, @D_FecProceso AS D_FecRegistro FROM TR_Alumnos
				  WHERE	C_AnioIngreso IS NULL OR C_AnioIngreso = 0) AS SRC
		ON TRG.I_ObservID = SRC.I_ObservID AND TRG.I_TablaID = SRC.I_TablaID AND TRG.I_FilaTablaID = SRC.I_FilaTablaID
		WHEN MATCHED THEN
			UPDATE SET D_FecRegistro = SRC.D_FecRegistro
		WHEN NOT MATCHED BY TARGET THEN
			INSERT (I_ObservID, I_TablaID, I_FilaTablaID, D_FecRegistro)
			VALUES (SRC.I_ObservID, SRC.I_TablaID, SRC.I_FilaTablaID, SRC.D_FecRegistro)
		WHEN NOT MATCHED BY SOURCE AND TRG.I_ObservID = @I_ObservID THEN
			DELETE;

		SET @I_Observados = (SELECT COUNT(*) FROM TI_ObservacionRegistroTabla WHERE I_ObservID = @I_ObservID AND I_TablaID = @I_TablaID)

		SELECT @I_Observados as cant_obs, @D_FecProceso as fec_proceso

		COMMIT TRANSACTION				
		SET @B_Resultado = 1
		SET @T_Message = CAST(@I_Observados AS varchar)
	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION
		SET @B_Resultado = 0
		SET @T_Message = ERROR_MESSAGE() + ' (Linea: ' + CAST(ERROR_LINE() AS varchar(11)) + ').' 
	END CATCH
END
GO


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_U_ValidarModalidadIngresoAlumno')
	DROP PROCEDURE [dbo].[USP_U_ValidarModalidadIngresoAlumno]
GO

CREATE PROCEDURE USP_U_ValidarModalidadIngresoAlumno	
	@B_Resultado  bit output,
	@T_Message	  nvarchar(4000) OUTPUT	
AS
--declare @B_Resultado  bit,
--		@T_Message	  nvarchar(4000)
--exec USP_U_ValidarModalidadIngresoAlumno @B_Resultado output, @T_Message output
--select @B_Resultado as resultado, @T_Message as mensaje
BEGIN
	DECLARE @I_Observados int = 0
	DECLARE @D_FecProceso datetime = GETDATE() 
	DECLARE @I_ObservID int = 23
	DECLARE @I_TablaID int = 1

	BEGIN TRANSACTION
	BEGIN TRY 
		UPDATE	TR_Alumnos
		SET		B_Migrable = 0,
				D_FecEvalua = @D_FecProceso
		WHERE	NOT EXISTS (SELECT C_CodModIng FROM BD_UNFV_Repositorio.dbo.TC_ModalidadIngreso MI
							WHERE MI.C_CodModIng = TR_Alumnos.C_CodModIng)
		
		MERGE TI_ObservacionRegistroTabla AS TRG
		USING 	(SELECT	@I_ObservID AS I_ObservID, @I_TablaID AS I_TablaID, I_RowID AS I_FilaTablaID, @D_FecProceso AS D_FecRegistro FROM TR_Alumnos
				  WHERE	NOT EXISTS (SELECT C_CodModIng FROM BD_UNFV_Repositorio.dbo.TC_ModalidadIngreso MI
									WHERE MI.C_CodModIng = TR_Alumnos.C_CodModIng)) AS SRC
		ON TRG.I_ObservID = SRC.I_ObservID AND TRG.I_TablaID = SRC.I_TablaID AND TRG.I_FilaTablaID = SRC.I_FilaTablaID
		WHEN MATCHED THEN
			UPDATE SET D_FecRegistro = SRC.D_FecRegistro
		WHEN NOT MATCHED BY TARGET THEN
			INSERT (I_ObservID, I_TablaID, I_FilaTablaID, D_FecRegistro)
			VALUES (SRC.I_ObservID, SRC.I_TablaID, SRC.I_FilaTablaID, SRC.D_FecRegistro)
		WHEN NOT MATCHED BY SOURCE AND TRG.I_ObservID = @I_ObservID THEN
			DELETE;

		SET @I_Observados = (SELECT COUNT(*) FROM TI_ObservacionRegistroTabla WHERE I_ObservID = @I_ObservID AND I_TablaID = @I_TablaID)

		SELECT @I_Observados as cant_obs, @D_FecProceso as fec_proceso
				
		COMMIT TRANSACTION
		SET @B_Resultado = 1
		SET @T_Message = CAST(@I_Observados AS varchar)
	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION
		SET @B_Resultado = 0
		SET @T_Message = ERROR_MESSAGE() + ' (Linea: ' + CAST(ERROR_LINE() AS varchar(11)) + ').' 
	END CATCH
END
GO


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_U_ValidarCorrespondenciaNumDocumentoPersona')
	DROP PROCEDURE [dbo].[USP_U_ValidarCorrespondenciaNumDocumentoPersona]
GO

CREATE PROCEDURE USP_U_ValidarCorrespondenciaNumDocumentoPersona	
	@B_Resultado  bit output,
	@T_Message	  nvarchar(4000) OUTPUT	
AS
--declare @B_Resultado  bit,
--		@T_Message	  nvarchar(4000)
--exec USP_U_ValidarCorrespondenciaNumDocumentoPersona @B_Resultado output, @T_Message output
--select @B_Resultado as resultado, @T_Message as mensaje
BEGIN
	DECLARE @I_Observados int = 0
	DECLARE @D_FecProceso datetime = GETDATE() 
	DECLARE @I_ObservID int = 30
	DECLARE @I_TablaID int = 1

	BEGIN TRANSACTION
	BEGIN TRY 
		
		SELECT I_RowID, C_RcCod, C_CodAlu, C_NumDNI, C_CodTipDoc, T_ApePaterno, T_ApeMaterno, T_Nombre, I_ProcedenciaID, C_Sexo, D_FecNac, C_CodModIng, C_AnioIngreso
		INTO #NumDoc_Repetidos_nombres_diferentes
		FROM TR_Alumnos WHERE C_NumDNI IN (
			SELECT C_NumDNI FROM (SELECT C_NumDNI, COUNT(*) R FROM TR_Alumnos
									WHERE C_NumDNI IS NOT NULL
									GROUP BY C_NumDNI
									HAVING COUNT(*) > 1) T1
			WHERE NOT EXISTS (
				SELECT C_NumDNI, T_ApePaterno COLLATE Modern_Spanish_CI_AI, T_ApeMaterno COLLATE Modern_Spanish_CI_AI
					, T_Nombre COLLATE Modern_Spanish_CI_AI, COUNT(*) R
				FROM TR_Alumnos
				WHERE C_NumDNI IS NOT NULL AND T1.C_NumDNI = C_NumDNI
				GROUP BY C_NumDNI, T_ApePaterno COLLATE Modern_Spanish_CI_AI, T_ApeMaterno COLLATE Modern_Spanish_CI_AI, T_Nombre COLLATE Modern_Spanish_CI_AI
				HAVING COUNT(*) > 1
			)
		)

		UPDATE	TR_Alumnos
		SET		B_Migrable = 0,
				D_FecEvalua = @D_FecProceso
		WHERE	EXISTS (SELECT * FROM #NumDoc_Repetidos_nombres_diferentes WHERE I_RowID = TR_Alumnos.I_RowID)
		
		MERGE TI_ObservacionRegistroTabla AS TRG
		USING 	(SELECT	@I_ObservID AS I_ObservID, @I_TablaID AS I_TablaID, I_RowID AS I_FilaTablaID, @D_FecProceso AS D_FecRegistro FROM TR_Alumnos
				  WHERE	EXISTS (SELECT * FROM #NumDoc_Repetidos_nombres_diferentes WHERE I_RowID = TR_Alumnos.I_RowID)) AS SRC
		ON TRG.I_ObservID = SRC.I_ObservID AND TRG.I_TablaID = SRC.I_TablaID AND TRG.I_FilaTablaID = SRC.I_FilaTablaID
		WHEN MATCHED THEN
			UPDATE SET D_FecRegistro = SRC.D_FecRegistro
		WHEN NOT MATCHED BY TARGET THEN
			INSERT (I_ObservID, I_TablaID, I_FilaTablaID, D_FecRegistro)
			VALUES (SRC.I_ObservID, SRC.I_TablaID, SRC.I_FilaTablaID, SRC.D_FecRegistro)
		WHEN NOT MATCHED BY SOURCE AND TRG.I_ObservID = @I_ObservID THEN
			DELETE;

		SET @I_Observados = (SELECT COUNT(*) FROM TI_ObservacionRegistroTabla WHERE I_ObservID = @I_ObservID AND I_TablaID = @I_TablaID)

		SELECT @I_Observados as cant_obs, @D_FecProceso as fec_proceso
				
		COMMIT TRANSACTION
		SET @B_Resultado = 1
		SET @T_Message = CAST(@I_Observados AS varchar)
	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION
		SET @B_Resultado = 0
		SET @T_Message = ERROR_MESSAGE() + ' (Linea: ' + CAST(ERROR_LINE() AS varchar(11)) + ').' 
	END CATCH
END
GO


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_U_ValidarSexoDiferenteMismoDocumento')
	DROP PROCEDURE [dbo].[USP_U_ValidarSexoDiferenteMismoDocumento]
GO

CREATE PROCEDURE USP_U_ValidarSexoDiferenteMismoDocumento	
	@B_Resultado  bit output,
	@T_Message	  nvarchar(4000) OUTPUT	
AS
--declare @B_Resultado  bit,
--		@T_Message	  nvarchar(4000)
--exec USP_U_ValidarSexoDiferenteMismoDocumento @B_Resultado output, @T_Message output
--select @B_Resultado as resultado, @T_Message as mensaje
BEGIN
	DECLARE @I_Observados int = 0
	DECLARE @D_FecProceso datetime = GETDATE() 
	DECLARE @I_ObservID int = 31
	DECLARE @I_TablaID int = 1

	BEGIN TRANSACTION
	BEGIN TRY 
		
		SELECT I_RowID, C_RcCod, C_CodAlu, C_NumDNI, C_CodTipDoc, T_ApePaterno, T_ApeMaterno, T_Nombre, I_ProcedenciaID, C_Sexo, D_FecNac, C_CodModIng, C_AnioIngreso
		INTO #NumDoc_Repetidos_sexo_diferente
		FROM TR_Alumnos WHERE C_NumDNI IN (
				SELECT C_NumDNI FROM (SELECT C_NumDNI, COUNT(*) R FROM TR_Alumnos
						WHERE C_NumDNI IS NOT NULL
						GROUP BY C_NumDNI
						HAVING COUNT(*) > 1) T1
				WHERE NOT EXISTS (SELECT C_NumDNI, C_Sexo, COUNT(*) R FROM TR_Alumnos
									WHERE C_NumDNI IS NOT NULL AND T1.C_NumDNI = C_NumDNI
									GROUP BY C_NumDNI, C_Sexo
									HAVING COUNT(*) > 1)
		)

		UPDATE	TR_Alumnos
		SET		B_Migrable = 0,
				D_FecEvalua = @D_FecProceso
		WHERE	EXISTS (SELECT * FROM #NumDoc_Repetidos_sexo_diferente WHERE I_RowID = TR_Alumnos.I_RowID)
		
		MERGE TI_ObservacionRegistroTabla AS TRG
		USING 	(SELECT	@I_ObservID AS I_ObservID, @I_TablaID AS I_TablaID, I_RowID AS I_FilaTablaID, @D_FecProceso AS D_FecRegistro FROM TR_Alumnos
				  WHERE	EXISTS (SELECT * FROM #NumDoc_Repetidos_sexo_diferente WHERE I_RowID = TR_Alumnos.I_RowID)) AS SRC
		ON TRG.I_ObservID = SRC.I_ObservID AND TRG.I_TablaID = SRC.I_TablaID AND TRG.I_FilaTablaID = SRC.I_FilaTablaID
		WHEN MATCHED THEN
			UPDATE SET D_FecRegistro = SRC.D_FecRegistro
		WHEN NOT MATCHED BY TARGET THEN
			INSERT (I_ObservID, I_TablaID, I_FilaTablaID, D_FecRegistro)
			VALUES (SRC.I_ObservID, SRC.I_TablaID, SRC.I_FilaTablaID, SRC.D_FecRegistro)
		WHEN NOT MATCHED BY SOURCE AND TRG.I_ObservID = @I_ObservID THEN
			DELETE;

		SET @I_Observados = (SELECT COUNT(*) FROM TI_ObservacionRegistroTabla WHERE I_ObservID = @I_ObservID AND I_TablaID = @I_TablaID)

		SELECT @I_Observados as cant_obs, @D_FecProceso as fec_proceso
				
		COMMIT TRANSACTION
		SET @B_Resultado = 1
		SET @T_Message = CAST(@I_Observados AS varchar)
	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION
		SET @B_Resultado = 0
		SET @T_Message = ERROR_MESSAGE() + ' (Linea: ' + CAST(ERROR_LINE() AS varchar(11)) + ').' 
	END CATCH
END
GO



IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_IU_MigrarDataAlumnosUnfvRepositorio')
	DROP PROCEDURE [dbo].[USP_IU_MigrarDataAlumnosUnfvRepositorio]
GO

CREATE PROCEDURE USP_IU_MigrarDataAlumnosUnfvRepositorio
	@C_CodAlu	  varchar(20) = NULL,
	@C_AnioIng	  smallint = NULL,	
	@B_Resultado  bit output,
	@T_Message	  nvarchar(4000) OUTPUT	
AS
--declare @B_Resultado  bit,
--		@T_Message	  nvarchar(4000)
--exec USP_IU_MigrarDataAlumnosUnfvRepositorio NULL, NULL, @B_Resultado output, @T_Message output
--select @B_Resultado as resultado, @T_Message as mensaje
BEGIN
	DECLARE @I_CantAlu int = 0
	DECLARE @I_Removidos int = 0
	DECLARE @I_Actualizados_persona int = 0
	DECLARE @I_Actualizados_alumno int = 0
	DECLARE @I_Insertados_persona int = 0
	DECLARE @I_Insertados_alumno int = 0
	DECLARE @D_FecProceso datetime = GETDATE() 

	DECLARE @Tbl_output_persona AS TABLE 
	(
		accion			varchar(20), 
		INS_NumDNI		varchar(20), 
		INS_CodTipDoc	varchar(5),
		INS_ApePaterno	varchar(50), 
		INS_ApeMaterno	varchar(50), 
		INS_Nombre		varchar(50), 
		INS_Sexo		char(1), 
		INS_FecNac		date, 
		DEL_NumDNI		varchar(20), 
		DEL_CodTipDoc	varchar(5),
		DEL_ApePaterno	varchar(50), 
		DEL_ApeMaterno	varchar(50), 
		DEL_Nombre		varchar(50), 
		DEL_Sexo		char(1), 
		DEL_FecNac		date,
		I_RowID			int,
		B_Removido		bit
	)

	DECLARE @Tbl_output_alumno AS TABLE 
	(
		accion			  varchar(20), 
		C_RcCod			  varchar(3), 
		C_CodAlu		  varchar(20), 
		INS_I_PersonaID	  int, 
		INS_C_CodModIng	  varchar(2), 
		INS_C_AnioIngreso smallint, 
		DEL_I_PersonaID	  int, 
		DEL_C_CodModIng	  varchar(2), 
		DEL_C_AnioIngreso smallint,
		I_RowID			  int,
		B_Removido		  bit
	)

	IF EXISTS (SELECT * FROM tempdb.INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = '##TEMP_AlumnoPersona')
	BEGIN
		DROP TABLE ##TEMP_AlumnoPersona
	END 

	CREATE TABLE ##TEMP_AlumnoPersona (
		I_PersonaID		int IDENTITY (1, 1),
		I_RowID			int,
		C_RcCod			varchar(3), 
		C_CodAlu		varchar(20),
		C_NumDNI		varchar(20),
		C_CodTipDoc		varchar(5)
	)

	BEGIN TRANSACTION
	BEGIN TRY 
		SET IDENTITY_INSERT ##TEMP_AlumnoPersona ON

		INSERT INTO ##TEMP_AlumnoPersona (I_PersonaID, I_RowID, C_RcCod, C_CodAlu, C_NumDNI, C_CodTipDoc)
		SELECT	A.I_PersonaID, I_RowID, A.C_RcCod, A.C_CodAlu, P.C_NumDNI, P.C_CodTipDoc
		FROM	BD_UNFV_Repositorio.dbo.TC_Alumno A 
				INNER JOIN BD_UNFV_Repositorio.dbo.TC_Persona P ON A.I_PersonaID = P.I_PersonaID AND P.B_Eliminado = 0 AND A.B_Eliminado = 0
				INNER JOIN TR_Alumnos TA ON TA.C_CodAlu = A.C_CodAlu AND TA.C_RcCod = A.C_RcCod
		--WHERE (A.C_CodAlu = @C_CodAlu OR @C_CodAlu IS NULL) OR (A.C_AnioIngreso = @C_AnioIng OR @C_AnioIng IS NULL)
		ORDER BY A.I_PersonaID
		
		SET IDENTITY_INSERT ##TEMP_AlumnoPersona OFF

		--SELECT IDENT_CURRENT('##TEMP_AlumnoPersona')

		INSERT INTO ##TEMP_AlumnoPersona (I_RowID, C_RcCod, C_CodAlu, C_NumDNI, C_CodTipDoc)
		SELECT	I_RowID, TA.C_RcCod, TA.C_CodAlu, TA.C_NumDNI, TA.C_CodTipDoc
		FROM	BD_UNFV_Repositorio.dbo.TC_Alumno A 
				RIGHT JOIN TR_Alumnos TA ON TA.C_CodAlu = A.C_CodAlu AND TA.C_RcCod = A.C_RcCod  
		WHERE --((A.C_CodAlu = @C_CodAlu OR @C_CodAlu IS NULL) OR (A.C_AnioIngreso = @C_AnioIng OR @C_AnioIng IS NULL))
			 -- AND 
			  A.I_PersonaID IS NULL

		--SELECT * FROM ##TEMP_AlumnoPersona ORDER BY I_PersonaID

		SET IDENTITY_INSERT BD_UNFV_Repositorio.dbo.TC_Persona ON

		MERGE BD_UNFV_Repositorio.dbo.TC_Persona AS TRG
		USING (SELECT DISTINCT AP.I_PersonaID, A.* FROM ##TEMP_AlumnoPersona AP 
				INNER JOIN TR_Alumnos A ON AP.I_RowID = A.I_RowID AND A.B_Migrable = 1) AS SRC
		ON TRG.I_PersonaID = SRC.I_PersonaID
		WHEN MATCHED AND B_Migrado = 0 THEN
			UPDATE SET	TRG.C_NumDNI	 = SRC.C_NumDNI,
						TRG.C_CodTipDoc	 = SRC.C_CodTipDoc,
						TRG.T_ApePaterno = SRC.T_ApePaterno,
						TRG.T_ApeMaterno = SRC.T_ApeMaterno,
						TRG.T_Nombre	 = SRC.T_Nombre,
						TRG.C_Sexo		 = SRC.C_Sexo
		WHEN NOT MATCHED BY TARGET THEN
			INSERT (I_PersonaID, C_NumDNI, C_CodTipDoc, T_ApePaterno, T_ApeMaterno, T_Nombre, C_Sexo, D_FecNac, B_Habilitado, B_Eliminado)
			VALUES (SRC.I_PersonaID,SRC.C_NUMDNI, SRC.C_CodTipDoc, SRC.T_ApePaterno, SRC.T_ApeMaterno, SRC.T_Nombre, SRC.C_Sexo, D_FecNac, 1, 0)
		OUTPUT	$ACTION, inserted.C_NumDNI, inserted.C_CodTipDoc, inserted.T_ApePaterno, inserted.T_ApeMaterno, inserted.T_Nombre, 
				inserted.C_Sexo, inserted.D_FecNac,deleted.C_NumDNI, deleted.C_CodTipDoc, deleted.T_ApePaterno, deleted.T_ApeMaterno, 
				deleted.T_Nombre, deleted.C_Sexo, deleted.D_FecNac, SRC.I_RowID, 0 INTO @Tbl_output_persona;		
		
		SET IDENTITY_INSERT BD_UNFV_Repositorio.dbo.TC_Persona OFF


		MERGE BD_UNFV_Repositorio.dbo.TC_Alumno AS TRG
		USING (SELECT DISTINCT AP.I_PersonaID, A.* FROM ##TEMP_AlumnoPersona AP 
				INNER JOIN TR_Alumnos A ON AP.I_RowID = A.I_RowID AND A.B_Migrable = 1) AS SRC
		ON	TRG.C_RcCod = SRC.C_RcCod 
			AND TRG.C_CodAlu = SRC.C_CodAlu
			AND TRG.C_CodModIng	 = SRC.C_CodModIng
			AND TRG.C_AnioIngreso = SRC.C_AnioIngreso		
		WHEN MATCHED AND B_Migrado = 0 THEN
			UPDATE SET	TRG.I_PersonaID	 = SRC.I_PersonaID
		WHEN NOT MATCHED BY TARGET THEN
			INSERT (C_RcCod, C_CodAlu, I_PersonaID, C_CodModIng, C_AnioIngreso, B_Habilitado, B_Eliminado)
			VALUES (SRC.C_RcCod, SRC.C_CodAlu, SRC.I_PersonaID, SRC.C_CodModIng, SRC.C_AnioIngreso, 1, 0)
		OUTPUT	$ACTION, inserted.C_RcCod, inserted.C_CodAlu, inserted.I_PersonaID, inserted.C_CodModIng, inserted.C_AnioIngreso, 
				deleted.I_PersonaID, deleted.C_CodModIng, deleted.C_AnioIngreso, SRC.I_RowID, 0 INTO @Tbl_output_alumno;
		

		UPDATE	t_Alumnos
		SET		t_Alumnos.B_Migrado = 1,
				t_Alumnos.D_FecMigrado = @D_FecProceso
		FROM TR_Alumnos AS t_Alumnos
		INNER JOIN 	@Tbl_output_persona as t_out_p ON t_out_p.I_RowID = t_Alumnos.I_RowID
		INNER JOIN 	@Tbl_output_alumno as t_out_a ON t_out_a.I_RowID = t_Alumnos.I_RowID

		SET @I_CantAlu = (SELECT COUNT(*) FROM ##TEMP_AlumnoPersona AP INNER JOIN TR_Alumnos A ON AP.I_RowID = A.I_RowID AND A.B_Migrable = 1)
		SET @I_Insertados_persona = (SELECT COUNT(*) FROM @Tbl_output_persona WHERE accion = 'INSERT')
		SET @I_Insertados_alumno = (SELECT COUNT(*) FROM @Tbl_output_alumno WHERE accion = 'INSERT')
		SET @I_Actualizados_persona = (SELECT COUNT(*) FROM @Tbl_output_persona WHERE accion = 'UPDATE' AND B_Removido = 0)
		SET @I_Actualizados_alumno = (SELECT COUNT(*) FROM @Tbl_output_alumno WHERE accion = 'UPDATE' AND B_Removido = 0)
		
		IF EXISTS (SELECT * FROM tempdb.INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = '##TEMP_AlumnoPersona')
		BEGIN
			DROP TABLE ##TEMP_AlumnoPersona
		END

		COMMIT TRANSACTION
		SET @B_Resultado = 1
		SET @T_Message =  'Total: ' + CAST(@I_CantAlu AS varchar) + '|Insertados Persona: ' + CAST(@I_Insertados_persona AS varchar) + '|Insertados Alumno: ' + CAST(@I_Insertados_alumno AS varchar)
						+ '|Actualizados Persona: ' + CAST(@I_Actualizados_persona AS varchar) + '|Actualizados Alumno: ' + CAST(@I_Actualizados_alumno AS varchar)

	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION
		SET @B_Resultado = 0
		SET @T_Message = ERROR_MESSAGE() + ' LINE: ' + CAST(ERROR_LINE() AS varchar(10)) 
	END CATCH
END
GO

