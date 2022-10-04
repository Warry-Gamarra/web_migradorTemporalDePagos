	IF EXISTS (SELECT * FROM tempdb.INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = '##TEMP_AlumnoPersona')
	BEGIN
		DROP TABLE ##TEMP_AlumnoPersona
	END 

	CREATE TABLE ##TEMP_AlumnoPersona (
		C_RcCod			varchar(3), 
		C_CodAlu		varchar(20), 
		I_PersonaID		int,
		C_CodModIng		varchar(3),
		C_AnioIngreso	varchar(4),
		B_Migrado		bit	 
	)

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
		C_Sexo			char(1),
		D_FecNac		date,
	)

	SET IDENTITY_INSERT ##TEMP_Persona ON

	INSERT INTO ##TEMP_Persona (I_PersonaID, C_NumDNI, C_CodTipDoc, T_ApePaterno, T_ApeMaterno, T_Nombre, C_Sexo, D_FecNac)
	SELECT	DISTINCT A.I_PersonaID, LTRIM(RTRIM(REPLACE(P.C_NumDNI,' ', ' '))), P.C_CodTipDoc, P.T_ApePaterno, P.T_ApeMaterno, P.T_Nombre, 
			IIF(P.C_Sexo IS NULL, TA.C_Sexo, P.C_Sexo), IIF(P.D_FecNac IS NULL, TA.D_FecNac, P.D_FecNac)
	FROM	BD_UNFV_Repositorio.dbo.TC_Alumno A 
			INNER JOIN BD_UNFV_Repositorio.dbo.TC_Persona P ON A.I_PersonaID = P.I_PersonaID AND P.B_Eliminado = 0 AND A.B_Eliminado = 0
			INNER JOIN TR_Alumnos TA ON TA.C_CodAlu = A.C_CodAlu AND TA.C_RcCod = A.C_RcCod
	WHERE	I_ProcedenciaID = 1
	ORDER BY A.I_PersonaID
		
	SET IDENTITY_INSERT ##TEMP_Persona OFF


	DECLARE @I_TempPersonaID int
	SET @I_TempPersonaID = IDENT_CURRENT('BD_UNFV_Repositorio.dbo.TC_Persona') 

	SET IDENTITY_INSERT ##TEMP_Persona ON

	;WITH alumnos_no_persona (C_RcCod, C_CodAlu, C_NumDNI, C_CodTipDoc, T_ApePaterno, T_ApeMaterno, T_Nombre, I_ProcedenciaID, 
								C_Sexo, D_FecNac, C_CodModIng, C_AnioIngreso, D_FecCarga, B_Migrado, B_Migrable)
	AS
	(SELECT AL.C_RcCod, AL.C_CodAlu, AL.C_NumDNI, AL.C_CodTipDoc, AL.T_ApePaterno, AL.T_ApeMaterno, AL.T_Nombre, AL.I_ProcedenciaID, 
			AL.C_Sexo, AL.D_FecNac, AL.C_CodModIng, AL.C_AnioIngreso, AL.D_FecCarga, AL.B_Migrado, AL.B_Migrable 
		FROM TR_Alumnos AL
			LEFT JOIN (SELECT * FROM ##TEMP_Persona) TP ON ISNULL(LTRIM(RTRIM(REPLACE(AL.C_NumDNI,' ', ' '))), '') = ISNULL(LTRIM(RTRIM(REPLACE(TP.C_NumDNI,' ', ' '))), '')
			AND AL.T_ApePaterno COLLATE Latin1_general_CI_AI = TP.T_ApePaterno COLLATE Latin1_general_CI_AI 
			AND AL.T_ApeMaterno COLLATE Latin1_general_CI_AI = TP.T_ApeMaterno COLLATE Latin1_general_CI_AI 
			AND AL.T_Nombre COLLATE Latin1_general_CI_AI = TP.T_Nombre COLLATE Latin1_general_CI_AI
			--AND ISNULL(AL.D_FecNac, '') = ISNULL(TP.D_FecNac, '') 
			AND ISNULL(AL.C_Sexo, '') = ISNULL(TP.C_Sexo, '') 
	WHERE TP.I_PersonaID IS NULL)

	INSERT INTO ##TEMP_Persona (I_PersonaID, C_NumDNI, C_CodTipDoc, T_ApePaterno, T_ApeMaterno, T_Nombre, C_Sexo, D_FecNac)
	SELECT DISTINCT (@I_TempPersonaID + ROW_NUMBER() OVER(ORDER BY T_ApePaterno)) AS I_PersonaID, C_NumDNI, C_CodTipDoc, 
			T_ApePaterno, T_ApeMaterno, T_Nombre, C_Sexo, D_FecNac
	FROM   (SELECT	DISTINCT LTRIM(RTRIM(REPLACE(TA.C_NumDNI,' ', ' '))) C_NumDNI, 
					IIF(TA.C_CodTipDoc IS NULL, IIF(LEN(TA.C_NumDNI) = 8, 'DI', NULL), TA.C_CodTipDoc) AS C_CodTipDoc, 
					LTRIM(RTRIM(TA.T_ApePaterno)) COLLATE Latin1_general_CI_AI AS T_ApePaterno, 
					LTRIM(RTRIM(TA.T_ApeMaterno)) COLLATE Latin1_general_CI_AI AS T_ApeMaterno, 
					LTRIM(RTRIM(TA.T_Nombre)) COLLATE Latin1_general_CI_AI AS T_Nombre, C_Sexo, NULL AS D_FecNac, TA.B_Migrable
			FROM	BD_UNFV_Repositorio.dbo.TC_Alumno A 
					RIGHT JOIN alumnos_no_persona TA ON TA.C_CodAlu = A.C_CodAlu AND TA.C_RcCod = A.C_RcCod AND TA.B_Migrable = 1					 
			WHERE	A.I_PersonaID IS NULL
					AND TA.B_Migrable = 1
					AND I_ProcedenciaID = 1
		) AS T

	SET IDENTITY_INSERT ##TEMP_Persona OFF

		
	INSERT INTO ##TEMP_AlumnoPersona (I_PersonaID, C_RcCod, C_CodAlu, C_CodModIng, C_AnioIngreso, B_Migrado)
	SELECT A.I_PersonaID, A.C_RcCod, A.C_CodAlu, A.C_CodModIng, IIF(A.C_AnioIngreso IS NULL, TA.C_AnioIngreso, A.C_AnioIngreso), 1 AS B_Migrado
	FROM   BD_UNFV_Repositorio.dbo.TC_Alumno A 
			INNER JOIN (SELECT * FROM TR_Alumnos WHERE B_Migrable = 1) TA ON TA.C_CodAlu = A.C_CodAlu AND TA.C_RcCod = A.C_RcCod
	WHERE  TA.I_ProcedenciaID = 1
	UNION
	SELECT TA.I_PersonaID, TA.C_RcCod, TA.C_CodAlu, TA.C_CodModIng, TA.C_AnioIngreso, TA.B_Migrado
	FROM   BD_UNFV_Repositorio.dbo.TC_Alumno A 
			RIGHT JOIN (SELECT TP.I_PersonaID , AL.C_RcCod, AL.C_CodAlu, AL.C_CodModIng, AL.C_AnioIngreso, AL.B_Migrado, AL.I_ProcedenciaID
						FROM TR_Alumnos AL
								INNER JOIN ##TEMP_Persona TP ON ISNULL(LTRIM(RTRIM(REPLACE(AL.C_NumDNI,' ', ' '))), '') = ISNULL(LTRIM(RTRIM(REPLACE(TP.C_NumDNI,' ', ' '))), '')
								AND AL.T_ApePaterno = TP.T_ApePaterno AND AL.T_ApeMaterno = TP.T_ApeMaterno 
								AND AL.T_Nombre = TP.T_Nombre --AND ISNULL(AL.D_FecNac, '') = ISNULL(TP.D_FecNac, '')
								AND ISNULL(AL.C_Sexo, '') = ISNULL(TP.C_Sexo, '') 
						) TA ON TA.C_CodAlu = A.C_CodAlu AND TA.C_RcCod = A.C_RcCod
	WHERE  A.I_PersonaID IS NULL
		AND TA.I_ProcedenciaID = 1
			  


