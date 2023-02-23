
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


	IF EXISTS (SELECT * FROM tempdb.INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = '##TEMP_Persona')
	BEGIN
		DROP TABLE ##TEMP_Persona
	END 

	CREATE TABLE ##TEMP_Persona (
		I_PersonaID		int IDENTITY (1, 1),
		C_NumDNI		varchar(20),
		C_CodTipDoc		varchar(5),
		T_ApePaterno	varchar(50),
		T_ApeMaterno	varchar(50),
		T_Nombre		varchar(50),
		C_Sexo			char(1)
	)	
	
	
	BEGIN TRANSACTION
	BEGIN TRY

		SET IDENTITY_INSERT ##TEMP_Persona ON

		INSERT INTO ##TEMP_Persona (I_PersonaID, C_NumDNI, C_CodTipDoc, T_ApePaterno, T_ApeMaterno, T_Nombre, C_Sexo)
		SELECT	DISTINCT A.I_PersonaID, LTRIM(RTRIM(REPLACE(P.C_NumDNI,' ', ' '))), P.C_CodTipDoc, P.T_ApePaterno, P.T_ApeMaterno, P.T_Nombre, 
				IIF(P.C_Sexo IS NULL, TA.C_Sexo, P.C_Sexo)
		FROM	BD_UNFV_Repositorio.dbo.TC_Alumno A 
				INNER JOIN BD_UNFV_Repositorio.dbo.TC_Persona P ON A.I_PersonaID = P.I_PersonaID
				INNER JOIN TR_Alumnos TA ON TA.C_CodAlu = A.C_CodAlu AND TA.C_RcCod = A.C_RcCod
		WHERE	P.B_Eliminado = 0 
				AND A.B_Eliminado = 0
				AND I_ProcedenciaID = @I_ProcedenciaID
		ORDER BY A.I_PersonaID
		
		SET IDENTITY_INSERT ##TEMP_Persona OFF


		--DECLARE @I_TempPersonaID int
		--SET @I_TempPersonaID = IDENT_CURRENT('BD_UNFV_Repositorio.dbo.TC_Persona') 

		--SET IDENTITY_INSERT ##TEMP_Persona ON

		--;WITH alumnos_no_persona (C_RcCod, C_CodAlu, C_NumDNI, C_CodTipDoc, T_ApePaterno, T_ApeMaterno, T_Nombre, I_ProcedenciaID, 
		--						 C_Sexo, D_FecNac, C_CodModIng, C_AnioIngreso, D_FecCarga, B_Migrado, B_Migrable)
		--AS
		--(SELECT AL.C_RcCod, AL.C_CodAlu, AL.C_NumDNI, AL.C_CodTipDoc, AL.T_ApePaterno, AL.T_ApeMaterno, AL.T_Nombre, AL.I_ProcedenciaID, 
		--		AL.C_Sexo, AL.D_FecNac, AL.C_CodModIng, AL.C_AnioIngreso, AL.D_FecCarga, AL.B_Migrado, AL.B_Migrable 
		--   FROM TR_Alumnos AL
		--		LEFT JOIN ##TEMP_Persona TP ON ISNULL(LTRIM(RTRIM(REPLACE(AL.C_NumDNI,' ', ' '))), '') COLLATE Latin1_general_CI_AI = ISNULL(LTRIM(RTRIM(REPLACE(TP.C_NumDNI,' ', ' '))), '') COLLATE Latin1_general_CI_AI 
		--				  AND ISNULL(LTRIM(RTRIM(REPLACE(AL.T_ApePaterno,' ', ' '))), '') COLLATE Latin1_general_CI_AI = ISNULL(LTRIM(RTRIM(REPLACE(TP.T_ApePaterno,' ', ' '))), '') COLLATE Latin1_general_CI_AI 
		--				  AND ISNULL(LTRIM(RTRIM(REPLACE(AL.T_ApeMaterno,' ', ' '))), '') COLLATE Latin1_general_CI_AI = ISNULL(LTRIM(RTRIM(REPLACE(TP.T_ApeMaterno,' ', ' '))), '') COLLATE Latin1_general_CI_AI 
		--				  AND ISNULL(LTRIM(RTRIM(REPLACE(AL.T_Nombre,' ', ' '))), '') COLLATE Latin1_general_CI_AI = ISNULL(LTRIM(RTRIM(REPLACE(TP.T_Nombre,' ', ' '))), '') COLLATE Latin1_general_CI_AI
		--				  --AND ISNULL(AL.D_FecNac, '') = ISNULL(TP.D_FecNac, '') 
		--				  AND ISNULL(LTRIM(RTRIM(REPLACE(AL.C_Sexo,' ', ' '))), '') COLLATE Latin1_general_CI_AI = ISNULL(LTRIM(RTRIM(REPLACE(TP.C_Sexo,' ', ' '))), '') COLLATE Latin1_general_CI_AI 
		--  WHERE TP.I_PersonaID IS NULL
		--)

		--INSERT INTO ##TEMP_Persona (I_PersonaID, C_NumDNI, C_CodTipDoc, T_ApePaterno, T_ApeMaterno, T_Nombre, C_Sexo)
		--SELECT DISTINCT (@I_TempPersonaID + ROW_NUMBER() OVER(ORDER BY T_ApePaterno)) AS I_PersonaID, C_NumDNI, C_CodTipDoc, 
		--		T_ApePaterno, T_ApeMaterno, T_Nombre, C_Sexo
		--FROM   (SELECT	DISTINCT LTRIM(RTRIM(REPLACE(TA.C_NumDNI,' ', ' '))) C_NumDNI, 
		--				IIF(TA.C_CodTipDoc IS NULL, IIF(LEN(TA.C_NumDNI) = 8, 'DI', NULL), IIF(TA.C_NumDNI IS NULL, NULL,TA.C_CodTipDoc)) AS C_CodTipDoc, 
		--				LTRIM(RTRIM(TA.T_ApePaterno)) COLLATE Latin1_general_CI_AI AS T_ApePaterno, 
		--				LTRIM(RTRIM(TA.T_ApeMaterno)) COLLATE Latin1_general_CI_AI AS T_ApeMaterno, 
		--				LTRIM(RTRIM(TA.T_Nombre)) COLLATE Latin1_general_CI_AI AS T_Nombre, C_Sexo, TA.B_Migrable
		--		FROM	BD_UNFV_Repositorio.dbo.TC_Alumno A 
		--				RIGHT JOIN alumnos_no_persona TA ON TA.C_CodAlu = A.C_CodAlu AND TA.C_RcCod = A.C_RcCod AND TA.B_Migrable = 1					 
		--		WHERE	A.I_PersonaID IS NULL
		--				AND TA.B_Migrable = 1
		--				AND I_ProcedenciaID = @I_ProcedenciaID
		--	) AS T

		--SET IDENTITY_INSERT ##TEMP_Persona OFF


		IF EXISTS (SELECT * FROM tempdb.INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = '##TEMP_Persona')
		BEGIN
			DROP TABLE ##NumDoc_Repetidos_nombres_diferentes
		END 

		SELECT A.C_NumDNI, C_CodTipDoc, A.T_ApePaterno, A.T_ApeMaterno, A.T_Nombre,  @I_ProcedenciaID as I_ProcedenciaID, C_Sexo
		INTO ##NumDoc_Repetidos_nombres_diferentes
		FROM ##TEMP_Persona A
			 INNER JOIN (SELECT C_NumDNI, COUNT(*) Count_dni FROM ##TEMP_Persona WHERE C_NumDNI IS NOT NULL GROUP BY C_NumDNI HAVING COUNT(*) > 1) AR ON A.C_NumDNI = AR.C_NumDNI 
			 LEFT JOIN (SELECT C_NumDNI, T_ApePaterno COLLATE Modern_Spanish_CI_AI AS T_ApePaterno, T_ApeMaterno COLLATE Modern_Spanish_CI_AI AS T_ApeMaterno, 
							   T_Nombre COLLATE Modern_Spanish_CI_AI AS T_Nombre
						  FROM ##TEMP_Persona
						 WHERE C_NumDNI IS NOT NULL
						GROUP BY C_NumDNI, T_ApePaterno COLLATE Modern_Spanish_CI_AI, T_ApeMaterno COLLATE Modern_Spanish_CI_AI, T_Nombre COLLATE Modern_Spanish_CI_AI
						HAVING COUNT(*) > 1
					   ) AD ON AR.C_NumDNI = AD.C_NumDNI AND A.T_ApePaterno COLLATE Modern_Spanish_CI_AI = AD.T_ApePaterno COLLATE Modern_Spanish_CI_AI
							   AND A.T_ApeMaterno COLLATE Modern_Spanish_CI_AI = AD.T_ApeMaterno COLLATE Modern_Spanish_CI_AI
							   AND A.T_Nombre COLLATE Modern_Spanish_CI_AI = AD.T_Nombre COLLATE Modern_Spanish_CI_AI
		WHERE AD.C_NumDNI IS NULL 
		ORDER BY C_NumDNI

		--UPDATE	TR_Alumnos
		--SET		B_Migrable = 0,
		--		D_FecEvalua = @D_FecProceso
		--WHERE	EXISTS (SELECT * FROM ##NumDoc_Repetidos_nombres_diferentes WHERE C_NumDNI = TR_Alumnos.C_NumDNI)
		--		AND I_ProcedenciaID = @I_ProcedenciaID

		--MERGE TI_ObservacionRegistroTabla AS TRG
		--USING 	(SELECT	@I_ObservID AS I_ObservID, @I_TablaID AS I_TablaID, I_RowID AS I_FilaTablaID, @D_FecProceso AS D_FecRegistro FROM TR_Alumnos
		--		  WHERE	EXISTS (SELECT * FROM ##NumDoc_Repetidos_nombres_diferentes WHERE I_RowID = TR_Alumnos.I_RowID)
		--				AND I_ProcedenciaID = @I_ProcedenciaID) AS SRC
		--ON TRG.I_ObservID = SRC.I_ObservID AND TRG.I_TablaID = SRC.I_TablaID 
		--	AND TRG.I_FilaTablaID = SRC.I_FilaTablaID
		--WHEN MATCHED THEN
		--	UPDATE SET D_FecRegistro = SRC.D_FecRegistro
		--WHEN NOT MATCHED BY TARGET THEN
		--	INSERT (I_ObservID, I_TablaID, I_FilaTablaID, I_ProcedenciaID, D_FecRegistro)
		--	VALUES (SRC.I_ObservID, SRC.I_TablaID, SRC.I_FilaTablaID, @I_ProcedenciaID, SRC.D_FecRegistro)
		--WHEN NOT MATCHED BY SOURCE AND TRG.I_ObservID = @I_ObservID AND TRG.I_ProcedenciaID = @I_ProcedenciaID THEN
		--	DELETE;

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
--exec USP_U_UnfvRepo_ValidarSexoDiferenteMismoDocumento @I_ProcedenciaID, @B_Resultado output, @T_Message output
--select @B_Resultado as resultado, @T_Message as mensaje
BEGIN
	DECLARE @I_Observados int = 0
	DECLARE @D_FecProceso datetime = GETDATE() 
	DECLARE @I_ObservID int = 30
	DECLARE @I_TablaID int = 1


	IF EXISTS (SELECT * FROM tempdb.INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = '##TEMP_Persona')
	BEGIN
		DROP TABLE ##TEMP_Persona
	END 

	CREATE TABLE ##TEMP_Persona (
		I_PersonaID		int IDENTITY (1, 1),
		C_NumDNI		varchar(20),
		C_CodTipDoc		varchar(5),
		T_ApePaterno	varchar(50),
		T_ApeMaterno	varchar(50),
		T_Nombre		varchar(50),
		C_Sexo			char(1)
	)	
	
	
	BEGIN TRANSACTION
	BEGIN TRY

		SET IDENTITY_INSERT ##TEMP_Persona ON

		INSERT INTO ##TEMP_Persona (I_PersonaID, C_NumDNI, C_CodTipDoc, T_ApePaterno, T_ApeMaterno, T_Nombre, C_Sexo)
		SELECT	DISTINCT A.I_PersonaID, LTRIM(RTRIM(REPLACE(P.C_NumDNI,' ', ' '))), P.C_CodTipDoc, P.T_ApePaterno, P.T_ApeMaterno, P.T_Nombre, 
				IIF(P.C_Sexo IS NULL, TA.C_Sexo, P.C_Sexo)
		FROM	BD_UNFV_Repositorio.dbo.TC_Alumno A 
				INNER JOIN BD_UNFV_Repositorio.dbo.TC_Persona P ON A.I_PersonaID = P.I_PersonaID
				INNER JOIN TR_Alumnos TA ON TA.C_CodAlu = A.C_CodAlu AND TA.C_RcCod = A.C_RcCod
		WHERE	P.B_Eliminado = 0 
				AND A.B_Eliminado = 0
				AND I_ProcedenciaID = @I_ProcedenciaID
		ORDER BY A.I_PersonaID
		
		SET IDENTITY_INSERT ##TEMP_Persona OFF


		DECLARE @I_TempPersonaID int
		SET @I_TempPersonaID = IDENT_CURRENT('BD_UNFV_Repositorio.dbo.TC_Persona') 

		--SET IDENTITY_INSERT ##TEMP_Persona ON

		--;WITH alumnos_no_persona (C_RcCod, C_CodAlu, C_NumDNI, C_CodTipDoc, T_ApePaterno, T_ApeMaterno, T_Nombre, I_ProcedenciaID, 
		--						 C_Sexo, D_FecNac, C_CodModIng, C_AnioIngreso, D_FecCarga, B_Migrado, B_Migrable)
		--AS
		--(SELECT AL.C_RcCod, AL.C_CodAlu, AL.C_NumDNI, AL.C_CodTipDoc, AL.T_ApePaterno, AL.T_ApeMaterno, AL.T_Nombre, AL.I_ProcedenciaID, 
		--		AL.C_Sexo, AL.D_FecNac, AL.C_CodModIng, AL.C_AnioIngreso, AL.D_FecCarga, AL.B_Migrado, AL.B_Migrable 
		--   FROM TR_Alumnos AL
		--		LEFT JOIN ##TEMP_Persona TP ON ISNULL(LTRIM(RTRIM(REPLACE(AL.C_NumDNI,' ', ' '))), '') COLLATE Latin1_general_CI_AI = ISNULL(LTRIM(RTRIM(REPLACE(TP.C_NumDNI,' ', ' '))), '') COLLATE Latin1_general_CI_AI 
		--				  AND ISNULL(LTRIM(RTRIM(REPLACE(AL.T_ApePaterno,' ', ' '))), '') COLLATE Latin1_general_CI_AI = ISNULL(LTRIM(RTRIM(REPLACE(TP.T_ApePaterno,' ', ' '))), '') COLLATE Latin1_general_CI_AI 
		--				  AND ISNULL(LTRIM(RTRIM(REPLACE(AL.T_ApeMaterno,' ', ' '))), '') COLLATE Latin1_general_CI_AI = ISNULL(LTRIM(RTRIM(REPLACE(TP.T_ApeMaterno,' ', ' '))), '') COLLATE Latin1_general_CI_AI 
		--				  AND ISNULL(LTRIM(RTRIM(REPLACE(AL.T_Nombre,' ', ' '))), '') COLLATE Latin1_general_CI_AI = ISNULL(LTRIM(RTRIM(REPLACE(TP.T_Nombre,' ', ' '))), '') COLLATE Latin1_general_CI_AI
		--				  --AND ISNULL(AL.D_FecNac, '') = ISNULL(TP.D_FecNac, '') 
		--				  AND ISNULL(LTRIM(RTRIM(REPLACE(AL.C_Sexo,' ', ' '))), '') COLLATE Latin1_general_CI_AI = ISNULL(LTRIM(RTRIM(REPLACE(TP.C_Sexo,' ', ' '))), '') COLLATE Latin1_general_CI_AI 
		--  WHERE TP.I_PersonaID IS NULL
		--)

		--INSERT INTO ##TEMP_Persona (I_PersonaID, C_NumDNI, C_CodTipDoc, T_ApePaterno, T_ApeMaterno, T_Nombre, C_Sexo)
		--SELECT DISTINCT (@I_TempPersonaID + ROW_NUMBER() OVER(ORDER BY T_ApePaterno)) AS I_PersonaID, C_NumDNI, C_CodTipDoc, 
		--		T_ApePaterno, T_ApeMaterno, T_Nombre, C_Sexo
		--FROM   (SELECT	DISTINCT LTRIM(RTRIM(REPLACE(TA.C_NumDNI,' ', ' '))) C_NumDNI, 
		--				IIF(TA.C_CodTipDoc IS NULL, IIF(LEN(TA.C_NumDNI) = 8, 'DI', NULL), IIF(TA.C_NumDNI IS NULL, NULL,TA.C_CodTipDoc)) AS C_CodTipDoc, 
		--				LTRIM(RTRIM(TA.T_ApePaterno)) COLLATE Latin1_general_CI_AI AS T_ApePaterno, 
		--				LTRIM(RTRIM(TA.T_ApeMaterno)) COLLATE Latin1_general_CI_AI AS T_ApeMaterno, 
		--				LTRIM(RTRIM(TA.T_Nombre)) COLLATE Latin1_general_CI_AI AS T_Nombre, C_Sexo, TA.B_Migrable
		--		FROM	BD_UNFV_Repositorio.dbo.TC_Alumno A 
		--				RIGHT JOIN alumnos_no_persona TA ON TA.C_CodAlu = A.C_CodAlu AND TA.C_RcCod = A.C_RcCod AND TA.B_Migrable = 1					 
		--		WHERE	A.I_PersonaID IS NULL
		--				AND TA.B_Migrable = 1
		--				AND I_ProcedenciaID = @I_ProcedenciaID
		--	) AS T

		--SET IDENTITY_INSERT ##TEMP_Persona OFF

		IF EXISTS (SELECT * FROM tempdb.INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = '##NumDoc_Repetidos_sexo_diferente')
		BEGIN
			DROP TABLE ##NumDoc_Repetidos_sexo_diferente
		END 

		SELECT I_PersonaID, C_NumDNI, C_CodTipDoc, T_ApePaterno, T_ApeMaterno, T_Nombre, C_Sexo
		INTO ##NumDoc_Repetidos_sexo_diferente
		FROM ##TEMP_Persona WHERE C_NumDNI IN (
				SELECT C_NumDNI FROM (SELECT C_NumDNI, COUNT(*) R FROM ##TEMP_Persona
						WHERE C_NumDNI IS NOT NULL
						GROUP BY C_NumDNI
						HAVING COUNT(*) > 1) T1
				WHERE NOT EXISTS (SELECT C_NumDNI, C_Sexo, COUNT(*) R FROM ##TEMP_Persona
									WHERE C_NumDNI IS NOT NULL AND T1.C_NumDNI = C_NumDNI
									GROUP BY C_NumDNI, C_Sexo
									HAVING COUNT(*) > 1)
		)
		order by T_ApePaterno, T_ApeMaterno

		--UPDATE	TR_Alumnos
		--SET		B_Migrable = 0,
		--		D_FecEvalua = @D_FecProceso
		--WHERE	EXISTS (SELECT * FROM ##NumDoc_Repetidos_sexo_diferente WHERE I_RowID = TR_Alumnos.I_RowID)
		--		AND I_ProcedenciaID = @I_ProcedenciaID

		--MERGE TI_ObservacionRegistroTabla AS TRG
		--USING 	(SELECT	@I_ObservID AS I_ObservID, @I_TablaID AS I_TablaID, I_RowID AS I_FilaTablaID, @D_FecProceso AS D_FecRegistro FROM TR_Alumnos
		--		  WHERE	EXISTS (SELECT * FROM ##NumDoc_Repetidos_sexo_diferente WHERE I_RowID = TR_Alumnos.I_RowID)
		--				AND I_ProcedenciaID = @I_ProcedenciaID) AS SRC
		--ON  TRG.I_ObservID = SRC.I_ObservID AND TRG.I_TablaID = SRC.I_TablaID 
		--	AND TRG.I_FilaTablaID = SRC.I_FilaTablaID
		--WHEN MATCHED THEN
		--	UPDATE SET D_FecRegistro = SRC.D_FecRegistro
		--WHEN NOT MATCHED BY TARGET THEN
		--	INSERT (I_ObservID, I_TablaID, I_FilaTablaID, I_ProcedenciaID, D_FecRegistro)
		--	VALUES (SRC.I_ObservID, SRC.I_TablaID, SRC.I_FilaTablaID, @I_ProcedenciaID, SRC.D_FecRegistro)
		--WHEN NOT MATCHED BY SOURCE AND TRG.I_ObservID = @I_ObservID AND TRG.I_ProcedenciaID = @I_ProcedenciaID THEN
		--	DELETE;

		--SET @I_Observados = (SELECT COUNT(*) FROM TI_ObservacionRegistroTabla WHERE I_ObservID = @I_ObservID AND I_TablaID = @I_TablaID AND I_ProcedenciaID = @I_ProcedenciaID)

		--SELECT @I_Observados as cant_obs, @D_FecProceso as fec_proceso
				
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

