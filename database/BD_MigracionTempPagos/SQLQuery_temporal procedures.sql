
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
	DECLARE @I_ObservID int = 41
	DECLARE @I_TablaID int = 1

	IF EXISTS (SELECT * FROM tempdb.INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = '##TEMP_Persona')
	BEGIN
		DROP TABLE ##TEMP_Persona
	END 

	CREATE TABLE ##TEMP_Persona (
		C_NumDNI		varchar(20),
		C_CodTipDoc		varchar(5),
		T_ApePaterno	varchar(50),
		T_ApeMaterno	varchar(50),
		T_Nombre		varchar(50)
	)		
	
	BEGIN TRANSACTION
	BEGIN TRY
		
		;WITH Personas_repo (C_NumDNI, C_CodTipDoc, T_ApePaterno, T_ApeMaterno, T_Nombre, C_CodAlu, C_RcCod)
		AS
		(
			SELECT ISNULL(LTRIM(RTRIM(REPLACE(C_NumDNI,' ', ' '))), '') AS C_NumDNI, C_CodTipDoc, 
				   ISNULL(LTRIM(RTRIM(REPLACE(T_ApePaterno,' ', ' '))), '') COLLATE Modern_Spanish_CI_AI AS T_ApePaterno, 
				   ISNULL(LTRIM(RTRIM(REPLACE(T_ApeMaterno,' ', ' '))), '') COLLATE Modern_Spanish_CI_AI AS T_ApeMaterno, 
				   ISNULL(LTRIM(RTRIM(REPLACE(T_Nombre,' ', ' '))), '') COLLATE Modern_Spanish_CI_AI AS T_Nombre,
				   A.C_CodAlu, A.C_RcCod
			FROM   BD_UNFV_Repositorio..TC_Persona P
				   INNER JOIN BD_UNFV_Repositorio.dbo.TC_Alumno A ON A.I_PersonaID = P.I_PersonaID
			WHERE  P.B_Eliminado = 0 AND A.B_Eliminado = 0
			UNION
			SELECT DISTINCT ISNULL(LTRIM(RTRIM(REPLACE(C_NumDNI,' ', ' '))), '') AS C_NumDNI, C_CodTipDoc, 
				   ISNULL(LTRIM(RTRIM(REPLACE(T_ApePaterno,' ', ' '))), '') COLLATE Modern_Spanish_CI_AI AS T_ApePaterno, 
				   ISNULL(LTRIM(RTRIM(REPLACE(T_ApeMaterno,' ', ' '))), '') COLLATE Modern_Spanish_CI_AI AS T_ApeMaterno, 
				   ISNULL(LTRIM(RTRIM(REPLACE(T_Nombre,' ', ' '))), '') COLLATE Modern_Spanish_CI_AI AS T_Nombre,
				   C_CodAlu, C_RcCod
			FROM   TR_Alumnos
			WHERE  I_ProcedenciaID = @I_ProcedenciaID
		)
		

		INSERT INTO ##TEMP_Persona (C_CodTipDoc, C_NumDNI, T_ApePaterno, T_ApeMaterno, T_Nombre)
		SELECT DISTINCT IIF(TA.C_CodTipDoc IS NULL, IIF(LEN(TA.C_NumDNI) = 8, 'DI', NULL), IIF(TA.C_NumDNI IS NULL, NULL,TA.C_CodTipDoc)) AS C_CodTipDoc, 
						TA.C_NumDNI, TA.T_ApePaterno, TA.T_ApeMaterno, TA.T_Nombre
		FROM   TR_Alumnos A
			   INNER JOIN Personas_repo TA ON TA.C_CodAlu = A.C_CodAlu AND TA.C_RcCod = A.C_RcCod	
		WHERE  I_ProcedenciaID = @I_ProcedenciaID
			    AND A.C_NumDNI <> ''

		IF EXISTS (SELECT * FROM tempdb.INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = '##NumDoc_Repetidos_nombres_diferentes')
		BEGIN
			DROP TABLE ##NumDoc_Repetidos_nombres_diferentes
		END 

		SELECT A.C_NumDNI, C_CodTipDoc, A.T_ApePaterno, A.T_ApeMaterno, A.T_Nombre,  @I_ProcedenciaID as I_ProcedenciaID
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

		UPDATE	TR_Alumnos
		SET		B_Migrable = 0,
				D_FecEvalua = @D_FecProceso
		WHERE	EXISTS (SELECT * FROM ##NumDoc_Repetidos_nombres_diferentes WHERE C_NumDNI = TR_Alumnos.C_NumDNI)
				AND I_ProcedenciaID = @I_ProcedenciaID
				AND ISNULL(B_Correcto, 0) <> 1

		MERGE TI_ObservacionRegistroTabla AS TRG
		USING 	(SELECT	@I_ObservID AS I_ObservID, @I_TablaID AS I_TablaID, I_RowID AS I_FilaTablaID, @D_FecProceso AS D_FecRegistro FROM TR_Alumnos
				  WHERE	EXISTS (SELECT * FROM ##NumDoc_Repetidos_nombres_diferentes WHERE C_NumDNI = TR_Alumnos.C_NumDNI)
						AND I_ProcedenciaID = @I_ProcedenciaID
						AND ISNULL(B_Correcto, 0) <> 1) AS SRC
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

	IF EXISTS (SELECT * FROM tempdb.INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = '##NumDoc_Repetidos_nombres_diferentes')
	BEGIN
		DROP TABLE ##NumDoc_Repetidos_nombres_diferentes
	END 

	IF EXISTS (SELECT * FROM tempdb.INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = '##TEMP_Persona')
	BEGIN
		DROP TABLE ##TEMP_Persona
	END 
END
GO

