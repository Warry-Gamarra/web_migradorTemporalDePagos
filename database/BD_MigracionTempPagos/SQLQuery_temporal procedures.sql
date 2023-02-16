
IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_U_UnfvRepo_ValidarCorrespondenciaNumDocPersona')
	DROP PROCEDURE [dbo].[USP_U_UnfvRepo_ValidarCorrespondenciaNumDocPersona]
GO

CREATE PROCEDURE USP_U_UnfvRepo_ValidarCorrespondenciaNumDocPersona	
	@I_ProcedenciaID tinyint,
	@B_Resultado  bit output,
	@T_Message	  nvarchar(4000) OUTPUT	
AS
--declare @B_Resultado  bit,
--		@I_ProcedenciaID tinyint = 3,
--		@T_Message	  nvarchar(4000)
--exec USP_U_UnfvRepo_ValidarCorrespondenciaNumDocPersona @I_ProcedenciaID, @B_Resultado output, @T_Message output
--select @B_Resultado as resultado, @T_Message as mensaje
BEGIN
	DECLARE @I_Observados int = 0
	DECLARE @D_FecProceso datetime = GETDATE() 
	DECLARE @I_ObservID int = 30
	DECLARE @I_TablaID int = 1

	BEGIN TRANSACTION
	BEGIN TRY
		--1.- Validar duplicados en BD Repositorio

		SELECT RA.C_CodAlu, A.C_CodAlu, RA.C_RcCod, A.C_RcCod, RA.C_NumDNI, A.C_NumDNI, iif(LTRIM(RTRIM(REPLACE(RA.C_NumDNI,' ', ' '))) = LTRIM(RTRIM(REPLACE(A.C_NumDNI,' ', ' '))), 1, 0) 
		  FROM BD_UNFV_Repositorio.dbo.VW_Alumnos RA
			   INNER JOIN TR_Alumnos A ON RA.C_CodAlu = A.C_CodAlu AND RA.C_RcCod = A.C_RcCod
		 WHERE IIF(LTRIM(RTRIM(REPLACE(RA.C_NumDNI,' ', ' '))) = LTRIM(RTRIM(REPLACE(A.C_NumDNI,' ', ' '))), 1, 0) = 0
		
		SELECT  C_RcCod, C_CodAlu, A.C_NumDNI, C_CodTipDoc, A.T_ApePaterno, A.T_ApeMaterno, A.T_Nombre, I_ProcedenciaID, C_Sexo, D_FecNac, C_CodModIng, C_AnioIngreso
		INTO #NumDoc_Repetidos_nombres_diferentes
		FROM BD_UNFV_Repositorio.dbo.VW_Alumnos A
			 INNER JOIN (SELECT C_NumDNI, COUNT(*) Count_dni FROM TR_Alumnos WHERE C_NumDNI IS NOT NULL GROUP BY C_NumDNI HAVING COUNT(*) > 1) AR ON A.C_NumDNI = AR.C_NumDNI 
			 LEFT JOIN (SELECT C_NumDNI, T_ApePaterno COLLATE Modern_Spanish_CI_AI AS T_ApePaterno, T_ApeMaterno COLLATE Modern_Spanish_CI_AI AS T_ApeMaterno, 
							   T_Nombre COLLATE Modern_Spanish_CI_AI AS T_Nombre
						  FROM TR_Alumnos
						 WHERE C_NumDNI IS NOT NULL
						GROUP BY C_NumDNI, T_ApePaterno COLLATE Modern_Spanish_CI_AI, T_ApeMaterno COLLATE Modern_Spanish_CI_AI, T_Nombre COLLATE Modern_Spanish_CI_AI
						HAVING COUNT(*) > 1
					   ) AD ON AR.C_NumDNI = AD.C_NumDNI AND A.T_ApePaterno COLLATE Modern_Spanish_CI_AI = AD.T_ApePaterno COLLATE Modern_Spanish_CI_AI
							   AND A.T_ApeMaterno COLLATE Modern_Spanish_CI_AI = AD.T_ApeMaterno COLLATE Modern_Spanish_CI_AI
							   AND A.T_Nombre COLLATE Modern_Spanish_CI_AI = AD.T_Nombre COLLATE Modern_Spanish_CI_AI
		WHERE AD.C_NumDNI IS NULL 
		ORDER BY C_NumDNI

		UPDATE	TR_Alumnos
		SET		B_Migrable = 0,
				D_FecEvalua = @D_FecProceso
		WHERE	EXISTS (SELECT * FROM #NumDoc_Repetidos_nombres_diferentes WHERE C_NumDNI = TR_Alumnos.C_NumDNI)
				AND I_ProcedenciaID = @I_ProcedenciaID

		MERGE TI_ObservacionRegistroTabla AS TRG
		USING 	(SELECT	@I_ObservID AS I_ObservID, @I_TablaID AS I_TablaID, I_RowID AS I_FilaTablaID, @D_FecProceso AS D_FecRegistro FROM TR_Alumnos
				  WHERE	EXISTS (SELECT * FROM #NumDoc_Repetidos_nombres_diferentes WHERE I_RowID = TR_Alumnos.I_RowID)
						AND I_ProcedenciaID = @I_ProcedenciaID) AS SRC
		ON TRG.I_ObservID = SRC.I_ObservID AND TRG.I_TablaID = SRC.I_TablaID 
			AND TRG.I_FilaTablaID = SRC.I_FilaTablaID
		WHEN MATCHED THEN
			UPDATE SET D_FecRegistro = SRC.D_FecRegistro
		WHEN NOT MATCHED BY TARGET THEN
			INSERT (I_ObservID, I_TablaID, I_FilaTablaID, I_ProcedenciaID, D_FecRegistro)
			VALUES (SRC.I_ObservID, SRC.I_TablaID, SRC.I_FilaTablaID, @I_ProcedenciaID, SRC.D_FecRegistro)
		WHEN NOT MATCHED BY SOURCE AND TRG.I_ObservID = @I_ObservID AND TRG.I_ProcedenciaID = @I_ProcedenciaID THEN
			DELETE;

		SET @I_Observados = (SELECT COUNT(*) FROM TI_ObservacionRegistroTabla WHERE I_ObservID = @I_ObservID AND I_TablaID = @I_TablaID AND I_ProcedenciaID = @I_ProcedenciaID)

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


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_U_UnfvRepo_ValidarRepetidoNumDocPersona')
	DROP PROCEDURE [dbo].[USP_U_UnfvRepo_ValidarRepetidoNumDocPersona]
GO

CREATE PROCEDURE USP_U_UnfvRepo_ValidarRepetidoNumDocPersona	
	@I_ProcedenciaID tinyint,
	@B_Resultado  bit output,
	@T_Message	  nvarchar(4000) OUTPUT	
AS
--declare @B_Resultado  bit,
--		@I_ProcedenciaID tinyint = 2,
--		@T_Message	  nvarchar(4000)
--exec USP_U_UnfvRepo_ValidarRepetidoNumDocPersona @I_ProcedenciaID, @B_Resultado output, @T_Message output
--select @B_Resultado as resultado, @T_Message as mensaje
BEGIN
	DECLARE @I_Observados int = 0
	DECLARE @D_FecProceso datetime = GETDATE() 
	DECLARE @I_ObservID int = 41
	DECLARE @I_TablaID int = 1

	BEGIN TRANSACTION
	BEGIN TRY 
		
		;WITH Personas_repo (C_NumDNI, C_CodTipDoc, T_ApePaterno, T_ApeMaterno, T_Nombre)
		AS
		(
			SELECT LTRIM(RTRIM(REPLACE(C_NumDNI,' ', ' '))) AS C_NumDNI, C_CodTipDoc, 
					LTRIM(RTRIM(T_ApePaterno)) AS T_ApePaterno, 
					LTRIM(RTRIM(T_ApeMaterno)) AS T_ApeMaterno, 
					LTRIM(RTRIM(T_Nombre)) AS T_Nombre					
			FROM   BD_UNFV_Repositorio..TC_Persona P
			WHERE  C_NumDNI IS NOT NULL AND P.B_Eliminado = 0 
			UNION
			SELECT DISTINCT LTRIM(RTRIM(REPLACE(C_NumDNI,' ', ' '))) AS C_NumDNI, C_CodTipDoc, 
					LTRIM(RTRIM(T_ApePaterno)) COLLATE Modern_Spanish_CI_AI AS T_ApePaterno, 
					LTRIM(RTRIM(T_ApeMaterno)) COLLATE Modern_Spanish_CI_AI AS T_ApeMaterno, 
					LTRIM(RTRIM(T_Nombre)) COLLATE Modern_Spanish_CI_AI AS T_Nombre
			FROM   TR_Alumnos
			WHERE  C_NumDNI IS NOT NULL
		)

		SELECT P.* 
		INTO  #NumDoc_Repetidos_nombres
		FROM  BD_UNFV_Repositorio..TC_Persona P
			  INNER JOIN (SELECT C_NumDNI, COUNT(*) Cant_reps FROM Personas_repo WHERE C_NumDNI IS NOT NULL GROUP BY C_NumDNI HAVING COUNT(*) > 1) PR ON P.C_NumDNI = PR.C_NumDNI 
			  LEFT JOIN (SELECT C_NumDNI, T_ApePaterno COLLATE Modern_Spanish_CI_AI AS T_ApePaterno, T_ApeMaterno COLLATE Modern_Spanish_CI_AI AS T_ApeMaterno, 
							   T_Nombre COLLATE Modern_Spanish_CI_AI AS T_Nombre, COUNT(*) AS Cant_reps
						  FROM Personas_repo
						  WHERE C_NumDNI IS NOT NULL
						  GROUP BY C_NumDNI, T_ApePaterno COLLATE Modern_Spanish_CI_AI, T_ApeMaterno COLLATE Modern_Spanish_CI_AI, T_Nombre COLLATE Modern_Spanish_CI_AI
						  HAVING COUNT(*) > 1) PRG ON PR.C_NumDNI = PRG.C_NumDNI
		WHERE  PRG.C_NumDNI IS NULL
		ORDER BY P.C_NumDNI

		UPDATE	TR_Alumnos
		SET		B_Migrable = 0,
				D_FecEvalua = @D_FecProceso
		WHERE	EXISTS (SELECT * FROM #NumDoc_Repetidos_nombres WHERE C_NumDNI = LTRIM(RTRIM(REPLACE(TR_Alumnos.C_NumDNI,' ', ' '))))
				AND I_ProcedenciaID = @I_ProcedenciaID
				AND ISNULL(B_Correcto, 0) <> 1

		MERGE TI_ObservacionRegistroTabla AS TRG
		USING 	(SELECT	@I_ObservID AS I_ObservID, @I_TablaID AS I_TablaID, I_RowID AS I_FilaTablaID, @D_FecProceso AS D_FecRegistro FROM TR_Alumnos
				  WHERE	EXISTS (SELECT * FROM #NumDoc_Repetidos_nombres WHERE C_NumDNI = TR_Alumnos.C_NumDNI)
						AND I_ProcedenciaID = @I_ProcedenciaID 
						AND ISNULL(B_Correcto, 0) <> 1
				) AS SRC
		ON TRG.I_ObservID = SRC.I_ObservID AND TRG.I_TablaID = SRC.I_TablaID 
			AND TRG.I_FilaTablaID = SRC.I_FilaTablaID
		WHEN MATCHED THEN
			UPDATE SET D_FecRegistro = SRC.D_FecRegistro
		WHEN NOT MATCHED BY TARGET THEN
			INSERT (I_ObservID, I_TablaID, I_FilaTablaID, I_ProcedenciaID, D_FecRegistro)
			VALUES (SRC.I_ObservID, SRC.I_TablaID, SRC.I_FilaTablaID, @I_ProcedenciaID, SRC.D_FecRegistro)
		WHEN NOT MATCHED BY SOURCE AND TRG.I_ObservID = @I_ObservID AND TRG.I_ProcedenciaID = @I_ProcedenciaID THEN
			DELETE;

		SET @I_Observados = (SELECT COUNT(*) FROM TI_ObservacionRegistroTabla WHERE I_ObservID = @I_ObservID AND I_TablaID = @I_TablaID AND I_ProcedenciaID = @I_ProcedenciaID)

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


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_U_UnfvRepo_ValidarSexoDiferenteMismoDocumento')
	DROP PROCEDURE [dbo].[USP_U_UnfvRepo_ValidarSexoDiferenteMismoDocumento]
GO

CREATE PROCEDURE USP_U_UnfvRepo_ValidarSexoDiferenteMismoDocumento	
	@I_ProcedenciaID tinyint,
	@B_Resultado  bit output,
	@T_Message	  nvarchar(4000) OUTPUT	
AS
--declare @B_Resultado  bit,
--		@I_ProcedenciaID tinyint = 3,
--		@T_Message	  nvarchar(4000)
--exec USP_U_UnfvRepo_ValidarSexoDiferenteMismoDocumento @B_Resultado output, @T_Message output
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
		FROM BD_UNFV_Repositorio.dbo.VW_Alumnos A
			 INNER JOIN TC_CarreraProfesionalProcedencia CPP ON A.C_RcCod = CPP.C_CodRc AND CPP.I_ProcedenciaID = @I_ProcedenciaID
		WHERE C_NumDNI IN (
				SELECT C_NumDNI FROM (SELECT C_NumDNI, COUNT(*) R FROM BD_UNFV_Repositorio.dbo.VW_Alumnos
						WHERE C_NumDNI IS NOT NULL
						GROUP BY C_NumDNI
						HAVING COUNT(*) > 1) T1
				WHERE NOT EXISTS (SELECT C_NumDNI, C_Sexo, COUNT(*) R FROM BD_UNFV_Repositorio.dbo.VW_Alumnos
									WHERE C_NumDNI IS NOT NULL AND T1.C_NumDNI = C_NumDNI
									GROUP BY C_NumDNI, C_Sexo
									HAVING COUNT(*) > 1)
		)
		order by T_ApePaterno, T_ApeMaterno

		UPDATE	TR_Alumnos
		SET		B_Migrable = 0,
				D_FecEvalua = @D_FecProceso
		WHERE	EXISTS (SELECT * FROM #NumDoc_Repetidos_sexo_diferente WHERE I_RowID = TR_Alumnos.I_RowID)
				AND I_ProcedenciaID = @I_ProcedenciaID
		
		MERGE TI_ObservacionRegistroTabla AS TRG
		USING 	(SELECT	@I_ObservID AS I_ObservID, @I_TablaID AS I_TablaID, I_RowID AS I_FilaTablaID, @D_FecProceso AS D_FecRegistro FROM TR_Alumnos
				  WHERE	EXISTS (SELECT * FROM #NumDoc_Repetidos_sexo_diferente WHERE I_RowID = TR_Alumnos.I_RowID)
						AND I_ProcedenciaID = @I_ProcedenciaID) AS SRC
		ON  TRG.I_ObservID = SRC.I_ObservID AND TRG.I_TablaID = SRC.I_TablaID 
			AND TRG.I_FilaTablaID = SRC.I_FilaTablaID
		WHEN MATCHED THEN
			UPDATE SET D_FecRegistro = SRC.D_FecRegistro
		WHEN NOT MATCHED BY TARGET THEN
			INSERT (I_ObservID, I_TablaID, I_FilaTablaID, I_ProcedenciaID, D_FecRegistro)
			VALUES (SRC.I_ObservID, SRC.I_TablaID, SRC.I_FilaTablaID, @I_ProcedenciaID, SRC.D_FecRegistro)
		WHEN NOT MATCHED BY SOURCE AND TRG.I_ObservID = @I_ObservID AND TRG.I_ProcedenciaID = @I_ProcedenciaID THEN
			DELETE;

		SET @I_Observados = (SELECT COUNT(*) FROM TI_ObservacionRegistroTabla WHERE I_ObservID = @I_ObservID AND I_TablaID = @I_TablaID AND I_ProcedenciaID = @I_ProcedenciaID)

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
