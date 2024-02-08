USE BD_OCEF_MigracionTP
GO


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_IU_MigrarDataAlumnosUnfvRepositorio')
	DROP PROCEDURE [dbo].[USP_IU_MigrarDataAlumnosUnfvRepositorio]
GO

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_IU_MigrarDataAlumnosPorAnio_UnfvRepositorio')
	DROP PROCEDURE [dbo].[USP_IU_MigrarDataAlumnosPorAnio_UnfvRepositorio]
GO

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_MigracionTP_Repositorio_Alumnos_IU_MigrarDataPorAnio')
	DROP PROCEDURE [dbo].[USP_MigracionTP_Repositorio_Alumnos_IU_MigrarDataPorAnio]
GO

CREATE PROCEDURE [dbo].[USP_MigracionTP_Repositorio_Alumnos_IU_MigrarDataPorAnio]
(
	@I_ProcedenciaID tinyint,
	@C_AnioIng	  smallint,	
	@B_Resultado  bit OUTPUT,
	@T_Message	  nvarchar(4000) OUTPUT	
)
AS
--declare @C_AnioIng  smallint = 2012,
--		@I_ProcedenciaID tinyint = 3,
--		@B_Resultado  bit,
--		@T_Message	  nvarchar(4000)
--exec USP_MigracionTP_Repositorio_Cross_IU_MigrarDataAlumnosPorAnio @I_ProcedenciaID, @C_AnioIng, @B_Resultado output, @T_Message output
--select @B_Resultado as resultado, @T_Message as mensaje
BEGIN
	PRINT 'INICIANDO - USP_MigracionTP_Repositorio_Alumnos_IU_MigrarDataPorAnio'
		
	DECLARE @D_FecProceso	datetime = GETDATE() 
	DECLARE @I_TablaID		int = 1
	DECLARE @Count_Alumno_existe_repositorio  int = 0
	DECLARE @Count_Alumno_noExiste_repositorio  int = 0
	DECLARE @Count_DniPersona_repositorio  int = 0
	DECLARE @Count_NombrePersona_repositorio  int = 0
	DECLARE @Count_ToInsert_repositorio  int = 0

	DECLARE @I_Actualizados_persona int = 0
	DECLARE @I_Actualizados_alumno int = 0
	DECLARE @I_Insertados_persona int = 0
	DECLARE @I_Insertados_alumno int = 0

	BEGIN TRANSACTION
	BEGIN TRY 
		SELECT * INTO #Temp_AlumnosAnio FROM TR_Alumnos WHERE C_AnioIngreso = @C_AnioIng AND I_ProcedenciaID = @I_ProcedenciaID

		SELECT TAA.*, VA.I_PersonaID INTO #Temp_AlumnoPersonaRepo FROM #Temp_AlumnosAnio TAA INNER JOIN BD_UNFV_Repositorio.dbo.VW_Alumnos VA ON TAA.C_CodAlu = VA.C_CodAlu AND TAA.C_RcCod =  VA.C_RcCod
		
		SET @Count_Alumno_existe_repositorio = (SELECT COUNT(*) FROM #Temp_AlumnoPersonaRepo)
		PRINT 'SE ENCONTRARON ' + CAST(@Count_Alumno_existe_repositorio AS varchar) + ' COINCIDENCIAS EN EL REPOSITORIO'


		IF ( @Count_Alumno_existe_repositorio > 0)
		BEGIN
			PRINT 'ACTUALIZANDO DATOS EXISTENTES EN TABLA REPOSITORIO PERSONA '
			UPDATE BD_UNFV_Repositorio.dbo.TC_Persona
			   SET C_NumDNI = TA.C_NumDNI
				   ,T_ApePaterno = TA.T_ApePaterno
				   ,T_ApeMaterno = TA.T_ApeMaterno
				   ,T_Nombre = TA.T_Nombre
				   ,D_FecNac = TA.D_FecNac
				   ,C_Sexo = TA.C_Sexo
		   		   ,D_FecMod = @D_FecProceso
				   ,I_MigracionRowID = I_RowID
				   ,I_MigracionTablaID = @I_TablaID
			FROM #Temp_AlumnoPersonaRepo TA 
		     WHERE BD_UNFV_Repositorio.dbo.TC_Persona.I_PersonaID = TA.I_PersonaID
				   AND TA.B_Correcto = 1

			SET @I_Actualizados_persona = @I_Actualizados_persona + @@ROWCOUNT


			PRINT 'ACTUALIZANDO DATOS EXISTENTES EN TABLA REPOSITORIO ALUMNO'
			UPDATE BD_UNFV_Repositorio.dbo.TC_Alumno
			   SET C_AnioIngreso = TA.C_AnioIngreso
				   ,I_UsuarioMod = 1
				   ,D_FecMod = @D_FecProceso
				   ,I_MigracionRowID = I_RowID
				   ,I_MigracionTablaID = @I_TablaID
			  FROM #Temp_AlumnoPersonaRepo TA 
		     WHERE BD_UNFV_Repositorio.dbo.TC_Alumno.C_CodAlu = TA.C_CodAlu
				   AND BD_UNFV_Repositorio.dbo.TC_Alumno.C_RcCod = TA.C_RcCod
				   AND TA.B_Correcto = 1	
			
			SET @I_Actualizados_alumno = @I_Actualizados_alumno + @@ROWCOUNT


			UPDATE TR_Alumnos 
			   SET B_Migrado = 1 
				   ,D_FecMigrado = @D_FecProceso
			  FROM #Temp_AlumnoPersonaRepo
			 WHERE TR_Alumnos.I_RowID = #Temp_AlumnoPersonaRepo.I_RowID 
				   AND  #Temp_AlumnoPersonaRepo.B_Migrable = 1

		END


		SELECT TAA.* INTO #Temp_PersonaAlumnosNoRepo 
		  FROM #Temp_AlumnosAnio TAA 
			   LEFT JOIN BD_UNFV_Repositorio.dbo.VW_Alumnos VA ON TAA.C_CodAlu = VA.C_CodAlu AND TAA.C_RcCod =  VA.C_RcCod
		 WHERE VA.I_PersonaID IS NULL
		
		SET @Count_Alumno_noExiste_repositorio = (SELECT COUNT(*) FROM #Temp_PersonaAlumnosNoRepo)

		PRINT 'SE ENCONTRARON ' + CAST(@Count_Alumno_noExiste_repositorio AS varchar) + ' CUYO COD_ALU NO EXISTE EN EL REPOSITORIO'


		IF (@Count_Alumno_noExiste_repositorio > 0)
		BEGIN
			PRINT 'VERIFICANDO SI DATOS DE PERSONA EXISTEN EN REPOSITORIO...'
			PRINT 'VERIFICANDO POR DNI...'

			SELECT ROW_NUMBER() OVER (PARTITION BY SRC.C_CodAlu, SRC.C_RcCod ORDER BY SRC.I_RowID) AS ORD, SRC.*
			  INTO #Temp_PersonaAlumnosDniRepo
			  FROM (SELECT TPANR.*, P.I_PersonaID 
				   	  FROM #Temp_PersonaAlumnosNoRepo TPANR 
				   		   INNER JOIN BD_UNFV_Repositorio.dbo.TC_Persona P ON LTRIM(RTRIM(REPLACE(TPANR.C_NumDNI,' ', ' '))) = P.C_NumDNI
				     WHERE P.B_Eliminado = 0
				   ) SRC

			SET @Count_DniPersona_repositorio = (SELECT COUNT(*) FROM #Temp_PersonaAlumnosDniRepo) 
			
			PRINT 'SE ENCONTRARON ' + CAST(@Count_DniPersona_repositorio AS varchar) + 'COINCIDENCIAS POR DNI EN EL REPOSITORIO'


			IF (@Count_DniPersona_repositorio > 0)
			BEGIN
				PRINT 'ACTUALIZANDO DATOS EXISTENTES EN TABLA REPOSITORIO PERSONA '
				UPDATE BD_UNFV_Repositorio.dbo.TC_Persona
				   SET C_NumDNI = TA.C_NumDNI
					   ,T_ApePaterno = TA.T_ApePaterno
					   ,T_ApeMaterno = TA.T_ApeMaterno
					   ,T_Nombre = TA.T_Nombre
					   ,D_FecNac = TA.D_FecNac
					   ,C_Sexo = TA.C_Sexo
		   			   ,D_FecMod = @D_FecProceso
					   ,I_MigracionRowID = I_RowID
					   ,I_MigracionTablaID = @I_TablaID
				  FROM #Temp_PersonaAlumnosDniRepo TA 
				 WHERE BD_UNFV_Repositorio.dbo.TC_Persona.I_PersonaID = TA.I_PersonaID
					   AND TA.B_Correcto = 1
			
				SET @I_Actualizados_persona = @I_Actualizados_persona + @@ROWCOUNT
			

				PRINT 'AGREGANDO DATOS DE ALUMNO PARA DATOS EXISTENTES EN TABLA REPOSITORIO PERSONA.'
				INSERT INTO BD_UNFV_Repositorio.dbo.TC_Alumno(C_RcCod, C_CodAlu, I_PersonaID, C_CodModIng, C_AnioIngreso, B_Habilitado, B_Eliminado, D_FecCre)
											SELECT C_RcCod, C_CodAlu, I_PersonaID, C_CodModIng, C_AnioIngreso, 1 AS B_Habilitado , 0 AS B_Eliminado, @D_FecProceso 
											  FROM #Temp_PersonaAlumnosDniRepo 
											 WHERE ORD = 1
				  
				SET @I_Insertados_alumno = @I_Insertados_alumno + @@ROWCOUNT


				UPDATE TR_Alumnos 
				   SET B_Migrado = 1, 
					   D_FecMigrado = @D_FecProceso
				  FROM #Temp_PersonaAlumnosDniRepo
				 WHERE TR_Alumnos.I_RowID = #Temp_PersonaAlumnosDniRepo.I_RowID 
					   AND  #Temp_PersonaAlumnosDniRepo.B_Migrado = 1

			END

			PRINT 'VERIFICANDO POR NOMBRES...'
			SELECT TPANR.*
			  INTO #Temp_PersonaAlumnosNoDniRepo
			  FROM #Temp_PersonaAlumnosNoRepo TPANR 
				   LEFT JOIN BD_UNFV_Repositorio.dbo.TC_Persona P ON LTRIM(RTRIM(REPLACE(TPANR.C_NumDNI,' ', ' '))) = P.C_NumDNI AND P.B_Eliminado = 0
			 WHERE P.I_PersonaID IS NULL

			PRINT 'BUSCANDO COINCIDENCIAS POR NOMBRES...'
			SELECT ROW_NUMBER() OVER (PARTITION BY SRC.C_CodAlu, SRC.C_RcCod ORDER BY SRC.I_RowID) AS ORD, SRC.*
			  INTO #Temp_PersonaAlumnoNombreRepo
			FROM  (SELECT DISTINCT A.*, VA.I_PersonaID 
				     FROM #Temp_PersonaAlumnosNoDniRepo A
					      INNER JOIN BD_UNFV_Repositorio.dbo.VW_Alumnos VA ON ISNULL(VA.T_ApePaterno, '') COLLATE Latin1_general_CI_AI = ISNULL(LTRIM(RTRIM(REPLACE(A.T_ApePaterno,' ', ' '))), '') COLLATE Latin1_general_CI_AI 
									 AND ISNULL(VA.T_ApeMaterno, '') COLLATE Latin1_general_CI_AI = ISNULL(LTRIM(RTRIM(REPLACE(A.T_ApeMaterno,' ', ' '))), '') COLLATE Latin1_general_CI_AI 
									 AND ISNULL(VA.T_Nombre, '') COLLATE Latin1_general_CI_AI = ISNULL(LTRIM(RTRIM(REPLACE(A.T_Nombre,' ', ' '))), '') COLLATE Latin1_general_CI_AI
						           --AND ISNULL(VA.C_Sexo, '') COLLATE Latin1_general_CI_AI = ISNULL(LTRIM(RTRIM(REPLACE(A.C_Sexo,' ', ' '))), '') COLLATE Latin1_general_CI_AI
				  ) SRC

			SET @Count_NombrePersona_repositorio = (SELECT COUNT(*) FROM #Temp_PersonaAlumnoNombreRepo)

			IF(@Count_NombrePersona_repositorio > 0)
			BEGIN
				PRINT 'ACTUALIZANDO COINCIDENCIAS POR NOMBRES EN TABLA PERSONAS REPOSITORIO...'

				UPDATE BD_UNFV_Repositorio.dbo.TC_Persona
				   SET C_NumDNI = TA.C_NumDNI
					   ,T_ApePaterno = TA.T_ApePaterno
					   ,T_ApeMaterno = TA.T_ApeMaterno
					   ,T_Nombre = TA.T_Nombre
					   ,D_FecNac = TA.D_FecNac
					   ,C_Sexo = TA.C_Sexo
		   			   ,D_FecMod = @D_FecProceso
					   ,I_MigracionRowID = I_RowID
					   ,I_MigracionTablaID = @I_TablaID
			   FROM #Temp_PersonaAlumnoNombreRepo TA 
				 WHERE BD_UNFV_Repositorio.dbo.TC_Persona.I_PersonaID = TA.I_PersonaID
					   AND TA.B_Correcto = 1
				 
				SET @I_Actualizados_persona = @I_Actualizados_persona + @@ROWCOUNT


				PRINT 'AGREGANDO DATOS DE ALUMNO DE COINCIDENCIA POR NOMNBRE EN TABLA ALMUNO.'
				INSERT INTO BD_UNFV_Repositorio.dbo.TC_Alumno(C_RcCod, C_CodAlu, I_PersonaID, C_CodModIng, C_AnioIngreso, B_Habilitado, B_Eliminado, D_FecCre, I_MigracionRowID, I_MigracionTablaID)
											SELECT C_RcCod, C_CodAlu, I_PersonaID, C_CodModIng, C_AnioIngreso, 1 AS B_Habilitado , 0 AS B_Eliminado, @D_FecProceso, I_RowID, @I_TablaID 
											  FROM #Temp_PersonaAlumnoNombreRepo 
											 WHERE ORD = 1

				SET @I_Insertados_alumno = @I_Insertados_alumno + @@ROWCOUNT
				  

				UPDATE TR_Alumnos 
				   SET B_Migrado = 1, 
					   D_FecMigrado = @D_FecProceso
				  FROM #Temp_PersonaAlumnoNombreRepo
				 WHERE TR_Alumnos.I_RowID = #Temp_PersonaAlumnoNombreRepo.I_RowID 
					   AND  #Temp_PersonaAlumnoNombreRepo.B_Migrado = 1

			END


			SELECT TPANDR.*, TPANR.I_PersonaID INTO #Temp_PersonaAlumnoToRepoInsert
			  FROM #Temp_PersonaAlumnosNoDniRepo TPANDR
				   LEFT JOIN #Temp_PersonaAlumnoNombreRepo TPANR ON TPANDR.I_RowID = TPANR.I_RowID 
			 WHERE TPANR.I_RowID IS NULL

			 SET @Count_ToInsert_repositorio = (SELECT COUNT(*) FROM #Temp_PersonaAlumnoToRepoInsert)

			IF(@Count_ToInsert_repositorio > 0)
			BEGIN
				PRINT 'AGREGANDO DATOS ALUMNO EN TABLA PERSONAS REPOSITORIO...'
				INSERT INTO BD_UNFV_Repositorio.dbo.TC_Persona (C_NumDNI, C_CodTipDoc, T_ApePaterno, T_ApeMaterno, T_Nombre, C_Sexo, D_FecNac, B_Habilitado, B_Eliminado, D_FecCre, I_MigracionRowID, I_MigracionTablaID)
													  SELECT SRC.C_NUMDNI, SRC.C_CodTipDoc, SRC.T_ApePaterno, SRC.T_ApeMaterno, SRC.T_Nombre, SRC.C_Sexo, SRC.D_FecNac, 1, 0, @D_FecProceso, I_RowID, @I_TablaID
													  	FROM #Temp_PersonaAlumnoToRepoInsert SRC
				 
				SET @I_Insertados_persona = @I_Insertados_persona + @@ROWCOUNT


				PRINT 'AGREGANDO DATOS DE ALUMNO DE COINCIDENCIA POR NOMNBRE EN TABLA ALMUNO.'
				INSERT INTO BD_UNFV_Repositorio.dbo.TC_Alumno(C_RcCod, C_CodAlu, I_PersonaID, C_CodModIng, C_AnioIngreso, B_Habilitado, B_Eliminado, D_FecCre, I_MigracionRowID, I_MigracionTablaID)
											SELECT DISTINCT C_RcCod, C_CodAlu, P.I_PersonaID, C_CodModIng, C_AnioIngreso, 1 AS B_Habilitado , 0 AS B_Eliminado, @D_FecProceso, SRC.I_RowID, @I_TablaID 
											  FROM #Temp_PersonaAlumnoToRepoInsert SRC
												   INNER JOIN BD_UNFV_Repositorio.dbo.TC_Persona P ON SRC.I_RowID = P.I_MigracionRowID
												   
				  
				SET @I_Insertados_alumno = @I_Insertados_alumno + @@ROWCOUNT


				UPDATE TR_Alumnos 
				   SET B_Migrado = 1, 
					   D_FecMigrado = @D_FecProceso
				  FROM #Temp_PersonaAlumnoToRepoInsert
				 WHERE TR_Alumnos.I_RowID = #Temp_PersonaAlumnoToRepoInsert.I_RowID 
					   AND  #Temp_PersonaAlumnoToRepoInsert.B_Migrable = 1

			END

		END

		COMMIT TRANSACTION

		PRINT 'FINALIZANDO - USP_MigracionTP_Repositorio_Alumnos_IU_MigrarDataPorAnio'

		SET @B_Resultado = 1
		SET @T_Message =  'Insertados Persona: ' + CAST(@I_Insertados_persona AS varchar) + ' | Insertados Alumno: ' + CAST(@I_Insertados_alumno AS varchar)
						+ ' | Actualizados Persona: ' + CAST(@I_Actualizados_persona AS varchar) + ' | Actualizados Alumno: ' + CAST(@I_Actualizados_alumno AS varchar)

	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION
		SET @B_Resultado = 0
		SET @T_Message = ERROR_MESSAGE() + ' LINE: ' + CAST(ERROR_LINE() AS varchar(10)) 
	END CATCH

END
GO


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_Repositorio_Alumnos_U_ActualizarTablaPersona')
BEGIN
	DROP PROCEDURE dbo.USP_Repositorio_Alumnos_U_ActualizarTablaPersona
END
GO

CREATE PROCEDURE dbo.USP_Repositorio_Alumnos_U_ActualizarTablaPersona
(
	@C_CodAlu		varchar(20),
	@C_RcCod		varchar(5),
	@D_FecProceso	datetime,
	@B_Correcto	    bit,
	@I_TablaID		tinyint
)
AS
BEGIN
	IF (@B_Correcto = 1)
	BEGIN 	
		UPDATE P
		   SET C_NumDNI = TA.C_NumDNI
		   	   ,T_ApePaterno = TA.T_ApePaterno
		   	   ,T_ApeMaterno = TA.T_ApeMaterno
		   	   ,T_Nombre = TA.T_Nombre
			   ,D_FecNac = TA.D_FecNac
			   ,C_Sexo = TA.C_Sexo
		   	   ,D_FecMod = @D_FecProceso
			   ,I_MigracionRowID = I_RowID
			   ,I_MigracionTablaID = @I_TablaID
		  FROM TR_Alumnos TA
			   INNER JOIN BD_UNFV_Repositorio.dbo.VW_Alumnos VA ON TA.C_CodAlu = VA.C_CodAlu AND TA.C_RcCod = VA.C_RcCod
			   INNER JOIN BD_UNFV_Repositorio.dbo.TC_Persona P ON P.I_PersonaID = VA.I_PersonaID
		 WHERE 
		   	   TA.C_CodAlu = @C_CodAlu 
			   AND TA.C_RcCod = @C_RcCod
		   	   AND TA.B_Correcto = 1;
	END
	ELSE
	BEGIN
		UPDATE P 
		   SET I_MigracionRowID = TA.I_RowID
			   ,I_MigracionTablaID = @I_TablaID
			   ,D_FecMod = @D_FecProceso
		  FROM TR_Alumnos TA
			   INNER JOIN BD_UNFV_Repositorio.dbo.VW_Alumnos VA ON TA.C_CodAlu = VA.C_CodAlu AND TA.C_RcCod = VA.C_RcCod
			   INNER JOIN BD_UNFV_Repositorio.dbo.TC_Persona P ON P.I_PersonaID = VA.I_PersonaID
		 WHERE 
		   	   TA.C_CodAlu = @C_CodAlu 
			   AND TA.C_RcCod = @C_RcCod;
	END

END
GO


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_Repositorio_Alumnos_U_ActualizarTablaAlumno')
BEGIN
	DROP PROCEDURE dbo.USP_Repositorio_Alumnos_U_ActualizarTablaAlumno
END
GO

CREATE PROCEDURE dbo.USP_Repositorio_Alumnos_U_ActualizarTablaAlumno
(
	@C_CodAlu		varchar(20),
	@C_RcCod		varchar(5),
	@I_PersonaID	int,
	@D_FecProceso	datetime,
	@B_Correcto	    bit,
	@I_TablaID		tinyint
)
AS
BEGIN
	IF (@B_Correcto = 1)
	BEGIN 		

		UPDATE A
		   SET I_PersonaID = @I_PersonaID
			   ,C_AnioIngreso = TA.C_AnioIngreso
			   ,I_UsuarioMod = 1
			   ,D_FecMod	 = @D_FecProceso
		  FROM TR_Alumnos TA
			   INNER JOIN BD_UNFV_Repositorio.dbo.TC_Alumno A ON TA.C_CodAlu = A.C_CodAlu AND TA.C_RcCod = A.C_RcCod
		 WHERE 
			   TA.C_CodAlu = @C_CodAlu
			   AND TA.C_RcCod = @C_RcCod
			   AND TA.B_Correcto = 1;
	END
	ELSE
	BEGIN

		UPDATE A 
		   SET I_MigracionRowID = TA.I_RowID
			   ,I_MigracionTablaID = @I_TablaID
			   ,D_FecMod = @D_FecProceso
		  FROM TR_Alumnos TA
			   INNER JOIN BD_UNFV_Repositorio.dbo.TC_Alumno A ON TA.C_CodAlu = A.C_CodAlu AND TA.C_RcCod = A.C_RcCod
		 WHERE 
			   TA.C_CodAlu = @C_CodAlu
			   AND TA.C_RcCod = @C_RcCod;
	END

END
GO


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_Repositorio_Alumnos_I_InsertarAlumnoTablaAlumno')
BEGIN
	DROP PROCEDURE dbo.USP_Repositorio_Alumnos_I_InsertarAlumnoTablaAlumno
END
GO

CREATE PROCEDURE dbo.USP_Repositorio_Alumnos_I_InsertarAlumnoTablaAlumno
(
	@C_CodAlu		varchar(20),
	@C_RcCod		varchar(5),
	@I_PersonaID	int,
	@D_FecProceso	datetime,
	@I_TablaID		tinyint,
	@I_RowID		int
)
AS
BEGIN
	 
	INSERT INTO BD_UNFV_Repositorio.dbo.TC_Alumno(C_RcCod, C_CodAlu, I_PersonaID, C_CodModIng, C_AnioIngreso, B_Habilitado, B_Eliminado, D_FecCre, I_MigracionRowID, I_MigracionTablaID)
										SELECT C_RcCod, C_CodAlu, @I_PersonaID, C_CodModIng, C_AnioIngreso, 1 AS B_Habilitado , 0 AS B_Eliminado, @D_FecProceso, @I_RowID, @I_TablaID
										  FROM TR_Alumnos 
										 WHERE C_CodAlu = @C_CodAlu
											   AND C_RcCod = @C_RcCod;

END
GO


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_MigracionTP_Repositorio_Alumnos_IU_MigrarDataPorCodigo')
	DROP PROCEDURE [dbo].[USP_MigracionTP_Repositorio_Alumnos_IU_MigrarDataPorCodigo]
GO


CREATE PROCEDURE USP_MigracionTP_Repositorio_Alumnos_IU_MigrarDataPorCodigo
	@I_ProcedenciaID tinyint,
	@C_CodAlu	  varchar(20),
	@B_Resultado  bit OUTPUT,
	@T_Message	  nvarchar(4000) OUTPUT	
AS
--declare @C_CodAlu  varchar(20) = '2014706791',
--		@I_ProcedenciaID tinyint = 3,
--		@B_Resultado  bit,
--		@T_Message	  nvarchar(4000)
--exec USP_MigracionTP_Repositorio_Alumnos_IU_MigrarDataPorCodigo @I_ProcedenciaID, @C_CodAlu, @B_Resultado output, @T_Message output
--select @B_Resultado as resultado, @T_Message as mensaje
BEGIN
	
	PRINT 'INICIANDO - USP_MigracionTP_Repositorio_Alumnos_IU_MigrarDataPorCodigo'

	BEGIN TRANSACTION
	BEGIN TRY 

		DECLARE @num_dni		varchar(20)
		DECLARE @num_dni_repo	varchar(20)
		DECLARE @C_RcCod		varchar(5)
		DECLARE @I_PersonaID	int
		DECLARE @I_RowID		int
		DECLARE @B_Correcto		bit
		DECLARE @D_FecProceso	datetime = GETDATE() 
		DECLARE @I_TablaID		int = 1

		SELECT @I_RowID = I_RowID, @num_dni = C_NumDNI, @C_RcCod = C_RcCod, @B_Correcto = B_Correcto FROM TR_Alumnos WHERE C_CodAlu = @C_CodAlu 
		SELECT @num_dni_repo = C_NumDNI, @I_PersonaID = I_PersonaID FROM BD_UNFV_Repositorio.dbo.VW_Alumnos WHERE C_CodAlu = @C_CodAlu

		IF (@I_PersonaID IS NOT NULL)
		BEGIN
			PRINT 'PERSONA EXISTE EN BD_REPOSITORIO'

			PRINT 'ACTUALIZANDO REGISTRO CON ID ' + CAST(@I_PersonaID as varchar(10)) + '...'
			EXECUTE USP_Repositorio_Alumnos_U_ActualizarTablaPersona @C_CodAlu, @C_RcCod, @D_FecProceso, @B_Correcto, @I_TablaID;

			PRINT 'ACTUALIZANDO ALUMNO CON COD ' + @C_CodAlu + '...'
			EXECUTE USP_Repositorio_Alumnos_U_ActualizarTablaAlumno @C_CodAlu, @C_RcCod, @I_PersonaID, @D_FecProceso, @B_Correcto, @I_TablaID;

			UPDATE TR_Alumnos 
			   SET B_Migrado = 1,
			       D_FecMigrado = @D_FecProceso
			 WHERE B_Migrable = 1 AND I_RowID = @I_RowID 
		END
		ELSE
		BEGIN
			PRINT 'COD_ALU NO TIENE PERSONA RELACIONADA. VERIFICANDO EXISTENCIA DE PERSONA'
			PRINT 'POR DNI'
			SET @I_PersonaID = (SELECT I_PersonaID FROM BD_UNFV_Repositorio.dbo.TC_Persona WHERE C_NumDNI = @num_dni)

			IF (@I_PersonaID IS NOT NULL)
			BEGIN
				PRINT 'ACTUALIZANDO REGISTRO CON ID ' +  CAST(@I_PersonaID as varchar(10)) + '...'
				EXECUTE USP_Repositorio_Alumnos_U_ActualizarTablaPersona @C_CodAlu, @C_RcCod, @D_FecProceso, @B_Correcto, @I_TablaID;

				PRINT 'INSERTANDO ALUMNO CON COD ' + @C_CodAlu + '...'
				EXECUTE USP_Repositorio_Alumnos_I_InsertarAlumnoTablaAlumno @C_CodAlu, @C_RcCod, @I_PersonaID, @D_FecProceso, @I_TablaID, @I_RowID;

				UPDATE TR_Alumnos 
				   SET B_Migrado = 1,
					   D_FecMigrado = @D_FecProceso
				 WHERE B_Migrable = 1 AND I_RowID = @I_RowID 
			END
			ELSE IF EXISTS (SELECT VA.* FROM BD_UNFV_Repositorio.dbo.VW_Alumnos VA 
							INNER JOIN TR_Alumnos A ON ISNULL(VA.T_ApePaterno, '') COLLATE Latin1_general_CI_AI = ISNULL(LTRIM(RTRIM(REPLACE(A.T_ApePaterno,' ', ' '))), '') COLLATE Latin1_general_CI_AI 
													   AND ISNULL(VA.T_ApeMaterno, '') COLLATE Latin1_general_CI_AI = ISNULL(LTRIM(RTRIM(REPLACE(A.T_ApeMaterno,' ', ' '))), '') COLLATE Latin1_general_CI_AI 
													   AND ISNULL(VA.T_Nombre, '') COLLATE Latin1_general_CI_AI = ISNULL(LTRIM(RTRIM(REPLACE(A.T_Nombre,' ', ' '))), '') COLLATE Latin1_general_CI_AI
													   --AND ISNULL(VA.C_Sexo, '') COLLATE Latin1_general_CI_AI = ISNULL(LTRIM(RTRIM(REPLACE(A.C_Sexo,' ', ' '))), '') COLLATE Latin1_general_CI_AI 
							WHERE VA.C_CodAlu = @C_CodAlu AND VA.C_RcCod = @C_RcCod
							)
			BEGIN
				PRINT 'POR NOMBRE'

				SET @I_PersonaID = (SELECT MAX(VA.I_PersonaID) FROM BD_UNFV_Repositorio.dbo.VW_Alumnos VA 
									INNER JOIN TR_Alumnos A ON ISNULL(VA.T_ApePaterno, '') COLLATE Latin1_general_CI_AI = ISNULL(LTRIM(RTRIM(REPLACE(A.T_ApePaterno,' ', ' '))), '') COLLATE Latin1_general_CI_AI 
																AND ISNULL(VA.T_ApeMaterno, '') COLLATE Latin1_general_CI_AI = ISNULL(LTRIM(RTRIM(REPLACE(A.T_ApeMaterno,' ', ' '))), '') COLLATE Latin1_general_CI_AI 
																AND ISNULL(VA.T_Nombre, '') COLLATE Latin1_general_CI_AI = ISNULL(LTRIM(RTRIM(REPLACE(A.T_Nombre,' ', ' '))), '') COLLATE Latin1_general_CI_AI
																--AND ISNULL(VA.C_Sexo, '') COLLATE Latin1_general_CI_AI = ISNULL(LTRIM(RTRIM(REPLACE(A.C_Sexo,' ', ' '))), '') COLLATE Latin1_general_CI_AI 
								   	WHERE VA.C_CodAlu = @C_CodAlu AND VA.C_RcCod = @C_RcCod
								   )

				PRINT 'ACTUALIZANDO REGISTRO CON ID ' + CAST(@I_PersonaID as varchar(10)) + '...'
				EXECUTE USP_Repositorio_Alumnos_U_ActualizarTablaPersona @C_CodAlu, @C_RcCod, @D_FecProceso, @B_Correcto, @I_TablaID;

				PRINT 'INSERTANDO ALUMNO CON COD ' + @C_CodAlu + '...'
				EXECUTE USP_Repositorio_Alumnos_I_InsertarAlumnoTablaAlumno @C_CodAlu, @C_RcCod, @I_PersonaID, @D_FecProceso, @I_TablaID, @I_RowID;

				UPDATE TR_Alumnos 
				   SET B_Migrado = 1,
					   D_FecMigrado = @D_FecProceso
				 WHERE B_Migrable = 1 AND I_RowID = @I_RowID 
			END
			ELSE
			BEGIN
				PRINT 'PERSONA NO EXISTE EN BD_REPOSITORIO'

				PRINT 'INSERTANDO PERSONA EN BD_REPOSITORIO...'
				INSERT INTO BD_UNFV_Repositorio.dbo.TC_Persona (C_NumDNI, C_CodTipDoc, T_ApePaterno, T_ApeMaterno, T_Nombre, D_FecNac, C_Sexo, B_Habilitado, B_Eliminado, I_UsuarioCre, D_FecCre, I_MigracionRowID, I_MigracionTablaID)
												SELECT ISNULL(LTRIM(RTRIM(REPLACE(C_NumDNI,' ', ' '))),  ''), C_CodTipDoc, T_ApePaterno, T_ApeMaterno, T_Nombre, D_FecNac, C_Sexo, 1, 0, 1, @D_FecProceso, @I_RowID, @I_TablaID
												  FROM TR_Alumnos
												 WHERE C_CodAlu = @C_CodAlu AND C_RcCod = @C_RcCod;

				SET @I_PersonaID = SCOPE_IDENTITY();

				PRINT 'INSERTAR ALUMNO CON COD ' + @C_CodAlu + '...'
				EXECUTE USP_Repositorio_Alumnos_I_InsertarAlumnoTablaAlumno @C_CodAlu, @C_RcCod, @I_PersonaID, @D_FecProceso, @I_TablaID, @I_RowID;

				UPDATE TR_Alumnos 
				   SET B_Migrado = 1,
					   D_FecMigrado = @D_FecProceso
				 WHERE B_Migrable = 1 AND I_RowID = @I_RowID
			END
		END

		SET @B_Resultado = 1
		SET @T_Message = 'Migrado: ' + @C_CodAlu

		PRINT 'FINALIZANDO - USP_MigracionTP_Repositorio_Alumnos_IU_MigrarDataPorCodigo'

		COMMIT TRANSACTION
	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION
		SET @B_Resultado = 0
		SET @T_Message = ERROR_MESSAGE() + ' LINE: ' + CAST(ERROR_LINE() AS varchar(10)) 
	END CATCH
END
GO


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_MigracionTP_Alumnos_U_RemoverObservacionPorAlumno')
	DROP PROCEDURE [dbo].[USP_MigracionTP_Alumnos_U_RemoverObservacionPorAlumno]
GO

CREATE PROCEDURE [dbo].[USP_MigracionTP_Alumnos_U_RemoverObservacionPorAlumno]	
	@I_RowID	  int,
	@I_TablaID	  int,
	@I_ObservID	  int,
	@D_FecProceso datetime
AS
BEGIN
	UPDATE	TR_Alumnos
		SET	B_Migrable = 1,
			B_Migrado = 0,
			D_FecEvalua = @D_FecProceso
		WHERE  I_RowID = @I_RowID
			   AND B_Migrado = 0

	DELETE FROM TI_ObservacionRegistroTabla 
		WHERE I_TablaID = @I_TablaID 
				AND I_FilaTablaID = @I_RowID 
				AND I_ObservID = @I_ObservID

END
GO


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_MigracionTP_Alumnos_U_RegistrarObservacionPorAlumno')
	DROP PROCEDURE [dbo].[USP_MigracionTP_Alumnos_U_RegistrarObservacionPorAlumno]
GO

CREATE PROCEDURE [dbo].[USP_MigracionTP_Alumnos_U_RegistrarObservacionPorAlumno]	
	@I_RowID	   int,
	@I_TablaID	   int,
	@I_ObservID	   int,
	@D_FecProceso  datetime
AS
BEGIN
	UPDATE	TR_Alumnos
		SET	B_Migrable = 0,
			D_FecEvalua = @D_FecProceso
		WHERE  I_RowID = @I_RowID

	IF EXISTS (SELECT * FROM TI_ObservacionRegistroTabla WHERE I_TablaID = @I_TablaID AND I_FilaTablaID = @I_RowID AND I_ObservID = @I_ObservID)
		UPDATE TI_ObservacionRegistroTabla 
			SET D_FecRegistro = @D_FecProceso
			WHERE I_TablaID = @I_TablaID 
				AND I_FilaTablaID = @I_RowID 
				AND I_ObservID = @I_ObservID
	ELSE
		INSERT INTO TI_ObservacionRegistroTabla (I_ObservID, I_TablaID, I_FilaTablaID, I_ProcedenciaID, D_FecRegistro, B_Resuelto, D_FecResuelto)
						SELECT @I_ObservID, @I_TablaID, I_RowID, I_ProcedenciaID, @D_FecProceso, 0, NULL
						FROM TR_Alumnos WHERE I_RowID = @I_RowID 

END
GO


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_U_InicializarEstadoValidacionAlumno')
	DROP PROCEDURE [dbo].[USP_U_InicializarEstadoValidacionAlumno]
GO

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_MigracionTP_Alumnos_U_InicializarEstadoValidacion')
	DROP PROCEDURE [dbo].[USP_MigracionTP_Alumnos_U_InicializarEstadoValidacion]
GO

CREATE PROCEDURE [dbo].[USP_MigracionTP_Alumnos_U_InicializarEstadoValidacion]	
	@I_ProcedenciaID tinyint,
	@B_Resultado  bit output,
	@T_Message	  nvarchar(4000) OUTPUT	
AS
--declare @B_Resultado  bit,
--		@I_ProcedenciaID	tinyint = 3,
--		@T_Message	  nvarchar(4000)
--exec USP_MigracionTP_Alumnos_U_InicializarEstadoValidacion @I_ProcedenciaID, @B_Resultado output, @T_Message output
--select @B_Resultado as resultado, @T_Message as mensaje
BEGIN
	BEGIN TRANSACTION
	BEGIN TRY 
		UPDATE	TR_Alumnos 
		   SET	B_Actualizado = 0, 
				B_Migrable = 1, 
				D_FecMigrado = NULL, 
				B_Migrado = 0
		 WHERE I_ProcedenciaID = @I_ProcedenciaID
		       AND B_Migrable = 0
			   AND B_Migrado = 0
				
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


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_MigracionTP_Alumnos_U_InicializarEstadoValidacionPorAlumnoID')
	DROP PROCEDURE [dbo].[USP_MigracionTP_Alumnos_U_InicializarEstadoValidacionPorAlumnoID]
GO

CREATE PROCEDURE USP_MigracionTP_Alumnos_U_InicializarEstadoValidacionPorAlumnoID	
	@I_RowID      int,
	@B_Resultado  bit output,
	@T_Message	  nvarchar(4000) OUTPUT	
AS
--declare @B_Resultado  bit,
--		@I_ProcedenciaID	tinyint = 3,
--		@T_Message	  nvarchar(4000)
--exec USP_MigracionTP_Alumnos_U_InicializarEstadoValidacionPorAlumnoID @I_RowID, @B_Resultado output, @T_Message output
--select @B_Resultado as resultado, @T_Message as mensaje
BEGIN
	BEGIN TRANSACTION
	BEGIN TRY 
		UPDATE	TR_Alumnos 
		   SET	B_Actualizado = 0, 
				B_Migrable = 1, 
				D_FecMigrado = NULL, 
				B_Migrado = 0
		 WHERE I_RowID = @I_RowID

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


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_U_ValidarCaracteresEspeciales')
	DROP PROCEDURE [dbo].[USP_U_ValidarCaracteresEspeciales]
GO

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_MigracionTP_Alumnos_U_ValidarCaracteresEspeciales')
	DROP PROCEDURE [dbo].[USP_MigracionTP_Alumnos_U_ValidarCaracteresEspeciales]
GO

CREATE PROCEDURE USP_MigracionTP_Alumnos_U_ValidarCaracteresEspeciales	
	@I_ProcedenciaID tinyint,
	@B_Resultado  bit output,
	@T_Message	  nvarchar(4000) OUTPUT	
AS
--declare @B_Resultado  bit,
--		@I_ProcedenciaID	tinyint = 3,
--		@T_Message	  nvarchar(4000)
--exec USP_MigracionTP_Alumnos_U_ValidarCaracteresEspeciales @I_ProcedenciaID, @B_Resultado output, @T_Message output
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
				(PATINDEX('%[^a-zA-Z0-9.'' ]%', REPLACE(T_Nombre, '-', ' ')) <> 0 
				OR PATINDEX('%[^a-zA-Z0-9.'' ]%', REPLACE(T_ApePaterno, '-', ' ')) <> 0 
				OR PATINDEX('%[^a-zA-Z0-9.'' ]%', REPLACE(T_ApeMaterno, '-', ' ')) <> 0)
				AND I_ProcedenciaID = @I_ProcedenciaID

		MERGE TI_ObservacionRegistroTabla AS TRG
		USING 	(SELECT	@I_ObservID AS I_ObservID, @I_TablaID AS I_TablaID, I_RowID AS I_FilaTablaID, @D_FecProceso AS D_FecRegistro FROM TR_Alumnos
				  WHERE	(PATINDEX('%[^a-zA-Z0-9.'' ]%', REPLACE(T_Nombre, '-', ' ')) <> 0 
						OR PATINDEX('%[^a-zA-Z0-9.'' ]%', REPLACE(T_ApePaterno, '-', ' ')) <> 0 
						OR PATINDEX('%[^a-zA-Z0-9.'' ]%', REPLACE(T_ApeMaterno, '-', ' ')) <> 0)
						AND I_ProcedenciaID = @I_ProcedenciaID
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


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_MigracionTP_Alumnos_U_ValidarCaracteresEspecialesPorAlumnoID')
	DROP PROCEDURE [dbo].[USP_MigracionTP_Alumnos_U_ValidarCaracteresEspecialesPorAlumnoID]
GO

CREATE PROCEDURE USP_MigracionTP_Alumnos_U_ValidarCaracteresEspecialesPorAlumnoID	
	@I_RowID	  int,
	@B_Resultado  bit output,
	@T_Message	  nvarchar(4000) OUTPUT	
AS
--declare @B_Resultado  bit,
--		  @I_ProcedenciaID	tinyint = 3,
--		  @T_Message	  nvarchar(4000)
--exec USP_MigracionTP_Alumnos_U_ValidarCaracteresEspecialesPorAlumnoID @I_RowID, @B_Resultado output, @T_Message output
--select @B_Resultado as resultado, @T_Message as mensaje
BEGIN
	DECLARE @I_Observados int = 0
	DECLARE @D_FecProceso datetime = GETDATE() 
	DECLARE @I_ObservID int = 1
	DECLARE @I_TablaID int = 1

	BEGIN TRANSACTION
	BEGIN TRY 

		DECLARE @B_Correcto		bit
		DECLARE @I_CaractEsp	int = 0

		SELECT @B_Correcto = B_Correcto FROM TR_Alumnos WHERE I_RowID = @I_RowID 

		IF (@B_Correcto = 1)
		BEGIN
			EXECUTE USP_MigracionTP_Alumnos_U_RemoverObservacionPorAlumno @I_RowID, @I_TablaID, @I_ObservID, @D_FecProceso
		END
		ELSE
		BEGIN
			SET @I_CaractEsp = (SELECT PATINDEX('%[^a-zA-Z0-9.'' ]%', REPLACE(T_Nombre, '-', ' ')) +
									   PATINDEX('%[^a-zA-Z0-9.'' ]%', REPLACE(T_ApePaterno, '-', ' ')) +		
									   PATINDEX('%[^a-zA-Z0-9.'' ]%', REPLACE(T_ApeMaterno, '-', ' ')) 
								  FROM TR_Alumnos 
								 WHERE I_RowID = @I_RowID)
			
			IF (@I_CaractEsp = 0)
			BEGIN
				EXECUTE USP_MigracionTP_Alumnos_U_RemoverObservacionPorAlumno @I_RowID, @I_TablaID, @I_ObservID, @D_FecProceso
			END
			ELSE
			BEGIN
				EXECUTE USP_MigracionTP_Alumnos_U_RegistrarObservacionPorAlumno @I_RowID, @I_TablaID, @I_ObservID, @D_FecProceso
			END
		END		

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

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_MigracionTP_Alumnos_U_ValidarAnioIngreso')
	DROP PROCEDURE [dbo].[USP_MigracionTP_Alumnos_U_ValidarAnioIngreso]
GO

CREATE PROCEDURE USP_MigracionTP_Alumnos_U_ValidarAnioIngreso	
	@I_ProcedenciaID tinyint,
	@B_Resultado  bit output,
	@T_Message	  nvarchar(4000) OUTPUT	
AS
--declare @B_Resultado  bit,
--		@I_ProcedenciaID tinyint = 3,
--		@T_Message	  nvarchar(4000)
--exec USP_MigracionTP_Alumnos_U_ValidarAnioIngreso @I_ProcedenciaID, @B_Resultado output, @T_Message output
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
		WHERE	(C_AnioIngreso IS NULL OR C_AnioIngreso = 0)
				AND I_ProcedenciaID = @I_ProcedenciaID
					
		MERGE TI_ObservacionRegistroTabla AS TRG
		USING 	(SELECT	@I_ObservID AS I_ObservID, @I_TablaID AS I_TablaID, I_RowID AS I_FilaTablaID, @D_FecProceso AS D_FecRegistro FROM TR_Alumnos
				  WHERE	(C_AnioIngreso IS NULL OR C_AnioIngreso = 0)
						AND I_ProcedenciaID = @I_ProcedenciaID
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


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_MigracionTP_Alumnos_U_ValidarAnioIngresoPorAlumnoID')
	DROP PROCEDURE [dbo].[USP_MigracionTP_Alumnos_U_ValidarAnioIngresoPorAlumnoID]
GO

CREATE PROCEDURE USP_MigracionTP_Alumnos_U_ValidarAnioIngresoPorAlumnoID	
	@I_RowID	  int,
	@B_Resultado  bit output,
	@T_Message	  nvarchar(4000) OUTPUT	
AS
--declare @B_Resultado  bit,
--		@I_ProcedenciaID tinyint = 3,
--		@T_Message	  nvarchar(4000)
--exec USP_U_ValidarAnioIngresopAlumnoPorAlumnoID @I_RowID, @B_Resultado output, @T_Message output
--select @B_Resultado as resultado, @T_Message as mensaje
BEGIN
	DECLARE @I_Observados int = 0
	DECLARE @D_FecProceso datetime = GETDATE() 
	DECLARE @I_ObservID int = 22
	DECLARE @I_TablaID int = 1

	BEGIN TRANSACTION
	BEGIN TRY 
		
		DECLARE @B_Correcto		bit
		DECLARE @C_CodModIng	varchar(5)

		SELECT @C_CodModIng = C_CodModIng, @B_Correcto = B_Correcto FROM TR_Alumnos WHERE I_RowID = @I_RowID 

		IF (@B_Correcto = 1)
		BEGIN
			EXECUTE USP_MigracionTP_Alumnos_U_RemoverObservacionPorAlumno @I_RowID, @I_TablaID, @I_ObservID, @D_FecProceso
		END
		ELSE
		BEGIN
			IF EXISTS(SELECT C_CodModIng FROM BD_UNFV_Repositorio.dbo.TC_ModalidadIngreso WHERE C_CodModIng = @C_CodModIng)
			BEGIN
				EXECUTE USP_MigracionTP_Alumnos_U_RemoverObservacionPorAlumno @I_RowID, @I_TablaID, @I_ObservID, @D_FecProceso
			END
			ELSE
			BEGIN
				EXECUTE USP_MigracionTP_Alumnos_U_RegistrarObservacionPorAlumno @I_RowID, @I_TablaID, @I_ObservID, @D_FecProceso
			END
		END		

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

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_MigracionTP_Alumnos_U_ValidarCodigoCarrera')
	DROP PROCEDURE [dbo].[USP_MigracionTP_Alumnos_U_ValidarCodigoCarrera]
GO

CREATE PROCEDURE USP_MigracionTP_Alumnos_U_ValidarCodigoCarrera	
	@I_ProcedenciaID tinyint,
	@B_Resultado  bit output,
	@T_Message	  nvarchar(4000) OUTPUT	
AS
--declare @B_Resultado  bit,
--		@I_ProcedenciaID tinyint = 3,
--		@T_Message	  nvarchar(4000)
--exec USP_MigracionTP_Alumnos_U_ValidarCodigoCarrera @I_ProcedenciaID, @B_Resultado output, @T_Message output
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
		WHERE	I_ProcedenciaID = @I_ProcedenciaID 
				AND NOT EXISTS (SELECT C_RcCod FROM BD_UNFV_Repositorio.dbo.TI_CarreraProfesional c
								WHERE C.C_RcCod = TR_Alumnos.C_RcCod)
					
		MERGE TI_ObservacionRegistroTabla AS TRG
		USING 	(SELECT	@I_ObservID AS I_ObservID, @I_TablaID AS I_TablaID, I_RowID AS I_FilaTablaID, @D_FecProceso AS D_FecRegistro FROM TR_Alumnos
				  WHERE	I_ProcedenciaID = @I_ProcedenciaID 
						AND NOT EXISTS (SELECT C_RcCod FROM BD_UNFV_Repositorio.dbo.TI_CarreraProfesional c
										WHERE C.C_RcCod = TR_Alumnos.C_RcCod)
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


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_MigracionTP_Alumnos_U_ValidarCodigoCarreraPorAlumnoID')
	DROP PROCEDURE [dbo].[USP_MigracionTP_Alumnos_U_ValidarCodigoCarreraPorAlumnoID]
GO

CREATE PROCEDURE USP_MigracionTP_Alumnos_U_ValidarCodigoCarreraPorAlumnoID	
	@I_RowID	  int,
	@B_Resultado  bit output,
	@T_Message	  nvarchar(4000) OUTPUT	
AS
--declare @B_Resultado  bit,
--		@I_ProcedenciaID tinyint = 3,
--		@T_Message	  nvarchar(4000)
--exec USP_U_ValidarCodigoCarreraAlumnoPorAlumnoID @I_RowID, @B_Resultado output, @T_Message output
--select @B_Resultado as resultado, @T_Message as mensaje
BEGIN
	DECLARE @I_Observados int = 0
	DECLARE @D_FecProceso datetime = GETDATE() 
	DECLARE @I_ObservID int = 21
	DECLARE @I_TablaID int = 1

	BEGIN TRANSACTION
	BEGIN TRY 
		DECLARE @B_Correcto		bit
		DECLARE @C_RcCod		varchar(3)

		SELECT @C_RcCod = C_RcCod, @B_Correcto = B_Correcto FROM TR_Alumnos WHERE I_RowID = @I_RowID 

		IF (@B_Correcto = 1)
		BEGIN
			EXECUTE USP_MigracionTP_Alumnos_U_RemoverObservacionPorAlumno @I_RowID, @I_TablaID, @I_ObservID, @D_FecProceso
		END
		ELSE
		BEGIN
			IF EXISTS (SELECT * FROM BD_UNFV_Repositorio.dbo.TI_CarreraProfesional WHERE C_RcCod = @C_RcCod)
			BEGIN
				EXECUTE USP_MigracionTP_Alumnos_U_RemoverObservacionPorAlumno @I_RowID, @I_TablaID, @I_ObservID, @D_FecProceso
			END
			ELSE
			BEGIN
				EXECUTE USP_MigracionTP_Alumnos_U_RegistrarObservacionPorAlumno @I_RowID, @I_TablaID, @I_ObservID, @D_FecProceso
			END
		END		
		
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

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_MigracionTP_Alumnos_U_ValidarModalidadIngreso')
	DROP PROCEDURE [dbo].[USP_MigracionTP_Alumnos_U_ValidarModalidadIngreso]
GO

CREATE PROCEDURE USP_MigracionTP_Alumnos_U_ValidarModalidadIngreso	
	@I_ProcedenciaID tinyint,
	@B_Resultado  bit output,
	@T_Message	  nvarchar(4000) OUTPUT	
AS
--declare @B_Resultado  bit,
--		@I_ProcedenciaID tinyint = 3,
--		@T_Message	  nvarchar(4000)
--exec USP_MigracionTP_Alumnos_U_ValidarModalidadIngreso @I_ProcedenciaID, @B_Resultado output, @T_Message output
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
		WHERE	I_ProcedenciaID = @I_ProcedenciaID 
				AND NOT EXISTS (SELECT C_CodModIng FROM BD_UNFV_Repositorio.dbo.TC_ModalidadIngreso MI
								WHERE MI.C_CodModIng = TR_Alumnos.C_CodModIng)
		
		MERGE TI_ObservacionRegistroTabla AS TRG
		USING 	(SELECT	@I_ObservID AS I_ObservID, @I_TablaID AS I_TablaID, I_RowID AS I_FilaTablaID, @D_FecProceso AS D_FecRegistro FROM TR_Alumnos
				  WHERE	I_ProcedenciaID = @I_ProcedenciaID 
						AND NOT EXISTS (SELECT C_CodModIng FROM BD_UNFV_Repositorio.dbo.TC_ModalidadIngreso MI
										WHERE MI.C_CodModIng = TR_Alumnos.C_CodModIng)) AS SRC
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


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_MigracionTP_Alumnos_U_ValidarModalidadIngresoPorAlumnoID')
	DROP PROCEDURE [dbo].[USP_MigracionTP_Alumnos_U_ValidarModalidadIngresoPorAlumnoID]
GO

CREATE PROCEDURE USP_MigracionTP_Alumnos_U_ValidarModalidadIngresoPorAlumnoID	
	@I_RowID	  int,
	@B_Resultado  bit output,
	@T_Message	  nvarchar(4000) OUTPUT	
AS
--declare @B_Resultado  bit,
--		@I_ProcedenciaID tinyint = 3,
--		@T_Message	  nvarchar(4000)
--exec USP_MigracionTP_Alumnos_U_ValidarModalidadIngresoPorAlumnoID @I_ProcedenciaID, @B_Resultado output, @T_Message output
--select @B_Resultado as resultado, @T_Message as mensaje
BEGIN
	DECLARE @I_Observados int = 0
	DECLARE @D_FecProceso datetime = GETDATE() 
	DECLARE @I_ObservID int = 23
	DECLARE @I_TablaID int = 1

	BEGIN TRANSACTION
	BEGIN TRY 
		
		DECLARE @B_Correcto		bit
		DECLARE @C_AnioIngreso	smallint

		SELECT @C_AnioIngreso = C_AnioIngreso, @B_Correcto = B_Correcto FROM TR_Alumnos WHERE I_RowID = @I_RowID 

		IF (@B_Correcto = 1)
		BEGIN
			EXECUTE USP_MigracionTP_Alumnos_U_RemoverObservacionPorAlumno @I_RowID, @I_TablaID, @I_ObservID, @D_FecProceso
		END
		ELSE
		BEGIN
			IF (ISNULL(@C_AnioIngreso, 0) > 0)
			BEGIN
				EXECUTE USP_MigracionTP_Alumnos_U_RemoverObservacionPorAlumno @I_RowID, @I_TablaID, @I_ObservID, @D_FecProceso
			END
			ELSE
			BEGIN
				EXECUTE USP_MigracionTP_Alumnos_U_RegistrarObservacionPorAlumno @I_RowID, @I_TablaID, @I_ObservID, @D_FecProceso
			END
		END		
				
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


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_U_UnfvRepo_ValidarSexoDiferenteMismoAlumno')
	DROP PROCEDURE [dbo].[USP_U_UnfvRepo_ValidarSexoDiferenteMismoAlumno]
GO

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_MigracionTP_Alumnos_U_ValidarSexoDiferenteMismoAlumno')
	DROP PROCEDURE [dbo].[USP_MigracionTP_Alumnos_U_ValidarSexoDiferenteMismoAlumno]
GO

CREATE PROCEDURE USP_MigracionTP_Alumnos_U_ValidarSexoDiferenteMismoAlumno	
	@I_ProcedenciaID tinyint,
	@B_Resultado  bit output,
	@T_Message	  nvarchar(4000) OUTPUT	
AS
--declare @B_Resultado  bit,
--		@I_ProcedenciaID tinyint = 1,
--		@T_Message	  nvarchar(4000)
--exec USP_MigracionTP_Alumnos_U_ValidarSexoDiferenteMismoAlumno @I_ProcedenciaID, @B_Resultado output, @T_Message output
--select @B_Resultado as resultado, @T_Message as mensaje
BEGIN
	DECLARE @I_Observados int = 0
	DECLARE @D_FecProceso datetime = GETDATE() 
	DECLARE @I_ObservID int = 47
	DECLARE @I_TablaID int = 1


	IF EXISTS (SELECT * FROM tempdb.INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = '##AlumnoPersona_Repositorio')
	BEGIN
		DROP TABLE ##AlumnoPersona_Repositorio
	END 
	
	BEGIN TRANSACTION
	BEGIN TRY

		SELECT A.C_CodAlu, A.C_RcCod, A.C_AnioIngreso, A.C_CodModIng,
				LTRIM(RTRIM(REPLACE(C_NumDNI,' ', ' '))) AS C_NumDNI, C_CodTipDoc, 
				LTRIM(RTRIM(T_ApePaterno)) AS T_ApePaterno, 
				LTRIM(RTRIM(T_ApeMaterno)) AS T_ApeMaterno, 
				LTRIM(RTRIM(T_Nombre)) AS T_Nombre,
				LTRIM(RTRIM(C_Sexo)) AS C_Sexo
		INTO   ##AlumnoPersona_Repositorio
		FROM   BD_UNFV_Repositorio.dbo.TC_Persona P
				INNER JOIN BD_UNFV_Repositorio.dbo.TC_Alumno A ON P.I_PersonaID = A.I_PersonaID
		WHERE  A.B_Eliminado = 0 AND P.B_Eliminado = 0 
		

		IF EXISTS (SELECT * FROM tempdb.INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = '##Alumno_Repetidos_sexo_diferente')
		BEGIN
			DROP TABLE ##Alumno_Repetidos_sexo_diferente
		END 

		SELECT A.I_RowID, A.C_NumDNI, A.C_CodTipDoc, A.T_ApePaterno, A.T_ApeMaterno, A.T_Nombre, A.C_Sexo,
			   APR.C_Sexo AS Repo_C_Sexo
		  INTO ##Alumno_Repetidos_sexo_diferente
		  FROM ##AlumnoPersona_Repositorio APR 
			   INNER JOIN TR_Alumnos A ON A.C_RcCod = APR.C_RcCod AND A.C_CodAlu = APR.C_CodAlu
		WHERE  LTRIM(RTRIM(REPLACE(ISNULL(A.C_Sexo,''),' ', ' '))) <> ISNULL(APR.C_Sexo, '' ) 
			   AND LTRIM(RTRIM(REPLACE(ISNULL(A.C_Sexo,''),' ', ' '))) <> ''
			   AND ISNULL(APR.C_Sexo, '' ) <> ''
			   AND I_ProcedenciaID = @I_ProcedenciaID 
		ORDER BY T_ApePaterno, T_ApeMaterno


		UPDATE	TR_Alumnos
		SET		B_Migrable = 0,
				D_FecEvalua = @D_FecProceso
		WHERE	EXISTS (SELECT * FROM ##Alumno_Repetidos_sexo_diferente ARSD WHERE ARSD.I_RowID = TR_Alumnos.I_RowID)
				AND I_ProcedenciaID = @I_ProcedenciaID
				AND ISNULL(B_Correcto, 0) <> 1

		MERGE TI_ObservacionRegistroTabla AS TRG
		USING 	(SELECT	@I_ObservID AS I_ObservID, @I_TablaID AS I_TablaID, I_RowID AS I_FilaTablaID, @D_FecProceso AS D_FecRegistro FROM TR_Alumnos
				  WHERE	EXISTS (SELECT * FROM ##Alumno_Repetidos_sexo_diferente ARSD WHERE ARSD.I_RowID = TR_Alumnos.I_RowID)
						AND I_ProcedenciaID = @I_ProcedenciaID
						AND ISNULL(B_Correcto, 0) <> 1
				) AS SRC
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

	IF EXISTS (SELECT * FROM tempdb.INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = '##NumDoc_Repetidos_sexo_diferente')
	BEGIN
		DROP TABLE ##AlumnoPersona_Repositorio
	END 
		IF EXISTS (SELECT * FROM tempdb.INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = '##TEMP_Persona')
	BEGIN
		DROP TABLE ##Alumno_Repetidos_sexo_diferente
	END
END
GO


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_MigracionTP_Alumnos_U_ValidarSexoDiferenteMismoAlumnoPorAlumnoID')
	DROP PROCEDURE [dbo].[USP_MigracionTP_Alumnos_U_ValidarSexoDiferenteMismoAlumnoPorAlumnoID]
GO

CREATE PROCEDURE [dbo].[USP_MigracionTP_Alumnos_U_ValidarSexoDiferenteMismoAlumnoPorAlumnoID]
	@I_RowID	  int,
	@B_Resultado  bit output,
	@T_Message	  nvarchar(4000) OUTPUT	
AS
--declare @B_Resultado  bit,
--		@I_RowID tinyint = 1,
--		@T_Message	  nvarchar(4000)
--exec USP_MigracionTP_Alumnos_U_ValidarSexoDiferenteMismoAlumnoPorAlumnoID @I_RowID, @B_Resultado output, @T_Message output
--select @B_Resultado as resultado, @T_Message as mensaje
BEGIN
	DECLARE @I_Observados int = 0
	DECLARE @D_FecProceso datetime = GETDATE() 
	DECLARE @I_ObservID int = 47
	DECLARE @I_TablaID int = 1

	
	BEGIN TRANSACTION
	BEGIN TRY
		
		DECLARE @num_dni		varchar(20)
		DECLARE @C_Sexo			varchar(2)
		DECLARE @C_Sexo_Repo	varchar(2)
		DECLARE @B_Correcto		bit
		DECLARE @C_RcCod		varchar(5)
		DECLARE @C_CodAlu		varchar(20)

		SELECT @num_dni = ISNULL(LTRIM(RTRIM(REPLACE(C_NumDNI,' ', ' '))), ''), @C_Sexo = ISNULL(C_Sexo, ''), 
			   @B_Correcto = B_Correcto, @C_CodAlu = C_CodAlu, @C_RcCod = C_RcCod
		FROM TR_Alumnos WHERE I_RowID = @I_RowID
		
		IF (@B_Correcto = 1)
		BEGIN
			EXECUTE USP_MigracionTP_Alumnos_U_RemoverObservacionPorAlumno @I_RowID, @I_TablaID, @I_ObservID, @D_FecProceso
		END
		ELSE
		BEGIN

			SELECT @C_Sexo_Repo = ISNULL(C_Sexo, '') FROM BD_UNFV_Repositorio.dbo.VW_Alumnos 
			WHERE C_CodAlu = @C_CodAlu AND C_RcCod = @C_RcCod


			IF (@C_Sexo_Repo = @C_Sexo)
			BEGIN
				EXECUTE USP_MigracionTP_Alumnos_U_RemoverObservacionPorAlumno @I_RowID, @I_TablaID, @I_ObservID, @D_FecProceso
			END
			ELSE
			BEGIN
				EXECUTE USP_MigracionTP_Alumnos_U_RegistrarObservacionPorAlumno @I_RowID, @I_TablaID, @I_ObservID, @D_FecProceso
			END
		END			

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

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_MigracionTP_Alumnos_U_ValidarSexoDiferenteMismoDocumento')
	DROP PROCEDURE [dbo].[USP_MigracionTP_Alumnos_U_ValidarSexoDiferenteMismoDocumento]
GO

CREATE PROCEDURE USP_MigracionTP_Alumnos_U_ValidarSexoDiferenteMismoDocumento	
	@I_ProcedenciaID tinyint,
	@B_Resultado  bit output,
	@T_Message	  nvarchar(4000) OUTPUT	
AS
--declare @B_Resultado  bit,
--		@I_ProcedenciaID tinyint = 3,
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


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_MigracionTP_Alumnos_U_ValidarSexoDiferenteMismoDocumentoPorAlumnoID')
	DROP PROCEDURE [dbo].[USP_MigracionTP_Alumnos_U_ValidarSexoDiferenteMismoDocumentoPorAlumnoID]
GO

CREATE PROCEDURE USP_MigracionTP_Alumnos_U_ValidarSexoDiferenteMismoDocumentoPorAlumnoID	
	@I_RowID	  int,
	@B_Resultado  bit output,
	@T_Message	  nvarchar(4000) OUTPUT	
AS
--declare @B_Resultado  bit,
--		@I_RowID tinyint = 3,
--		@T_Message	  nvarchar(4000)
--exec USP_MigracionTP_Alumnos_U_ValidarSexoDiferenteMismoDocumentoPorAlumnoID @I_RowID, @B_Resultado output, @T_Message output
--select @B_Resultado as resultado, @T_Message as mensaje
BEGIN
	DECLARE @I_Observados int = 0
	DECLARE @D_FecProceso datetime = GETDATE() 
	DECLARE @I_ObservID int = 31
	DECLARE @I_TablaID int = 1

	BEGIN TRANSACTION
	BEGIN TRY 
		
		DECLARE @num_dni		varchar(20)
		DECLARE @C_Sexo			varchar(2)
		DECLARE @I_Distincts	int
		DECLARE @B_Correcto		bit
		DECLARE @T_ApePaterno	varchar(100)
		DECLARE @T_ApeMaterno	varchar(100)
		DECLARE @T_Nombre		varchar(100)

		SELECT @num_dni = ISNULL(LTRIM(RTRIM(REPLACE(C_NumDNI,' ', ' '))), ''), 
			   @T_ApePaterno = LTRIM(RTRIM(T_ApePaterno)) COLLATE Modern_Spanish_CI_AI,
			   @T_ApeMaterno = LTRIM(RTRIM(T_ApeMaterno)) COLLATE Modern_Spanish_CI_AI,
			   @T_Nombre = LTRIM(RTRIM(T_Nombre)) COLLATE Modern_Spanish_CI_AI,
			   @C_Sexo = C_Sexo, @B_Correcto = B_Correcto 
		FROM TR_Alumnos WHERE I_RowID = @I_RowID
		
		IF (@B_Correcto = 1)
		BEGIN
			EXECUTE USP_MigracionTP_Alumnos_U_RemoverObservacionPorAlumno @I_RowID, @I_TablaID, @I_ObservID, @D_FecProceso
		END
		ELSE
		BEGIN
			SET @I_Distincts = (SELECT COUNT(*) 
							     FROM (SELECT DISTINCT C_NumDNI, C_Sexo
										 FROM TR_Alumnos 
										WHERE ISNULL(LTRIM(RTRIM(REPLACE(C_NumDNI,' ', ' '))), '') = @num_dni
											  AND T_ApePaterno COLLATE Modern_Spanish_CI_AI = @T_ApePaterno
											  AND T_Apematerno COLLATE Modern_Spanish_CI_AI = @T_ApeMaterno
											  AND T_Nombre COLLATE Modern_Spanish_CI_AI = @T_Nombre
										) TBL)

			IF (ISNULL(@I_Distincts, 1) = 1)
			BEGIN
				EXECUTE USP_MigracionTP_Alumnos_U_RemoverObservacionPorAlumno @I_RowID, @I_TablaID, @I_ObservID, @D_FecProceso
			END
			ELSE
			BEGIN
				EXECUTE USP_MigracionTP_Alumnos_U_RegistrarObservacionPorAlumno @I_RowID, @I_TablaID, @I_ObservID, @D_FecProceso
			END
		END		
		
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


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_U_ValidarCorrespondenciaNumDocRepositorioPersona')
	DROP PROCEDURE [dbo].[USP_U_ValidarCorrespondenciaNumDocRepositorioPersona]
GO

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_MigracionTP_Alumnos_U_ValidarCorrespondenciaNumDocRepositorioPersona')
	DROP PROCEDURE [dbo].[USP_MigracionTP_Alumnos_U_ValidarCorrespondenciaNumDocRepositorioPersona]
GO

CREATE PROCEDURE USP_MigracionTP_Alumnos_U_ValidarCorrespondenciaNumDocRepositorioPersona	
	@I_ProcedenciaID tinyint,
	@B_Resultado  bit output,
	@T_Message	  nvarchar(4000) OUTPUT	
AS
--declare @B_Resultado  bit,
--		@I_ProcedenciaID tinyint = 3,
--		@T_Message	  nvarchar(4000)
--exec USP_MigracionTP_Alumnos_U_ValidarCorrespondenciaNumDocRepositorioPersona @I_ProcedenciaID, @B_Resultado output, @T_Message output
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
		WHERE  PRG.C_NumDNI IS NULL AND P.B_Eliminado = 0
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


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_MigracionTP_Alumnos_U_ValidarCorrespondenciaNumDocRepositorioPersonaPorAlumnoID')
	DROP PROCEDURE [dbo].[USP_MigracionTP_Alumnos_U_ValidarCorrespondenciaNumDocRepositorioPersonaPorAlumnoID]
GO

CREATE PROCEDURE USP_MigracionTP_Alumnos_U_ValidarCorrespondenciaNumDocRepositorioPersonaPorAlumnoID	
	@I_RowID	  int,
	@B_Resultado  bit output,
	@T_Message	  nvarchar(4000) OUTPUT	
AS
--declare @B_Resultado  bit,
--		@I_RowID int = 7765,
--		@T_Message	  nvarchar(4000)
--exec USP_MigracionTP_Alumnos_U_ValidarCorrespondenciaNumDocRepositorioPersonaPorAlumnoID @I_RowID, @B_Resultado output, @T_Message output
--select @B_Resultado as resultado, @T_Message as mensaje
BEGIN
	DECLARE @I_Observados int = 0
	DECLARE @D_FecProceso datetime = GETDATE() 
	DECLARE @I_ObservID int = 41
	DECLARE @I_TablaID int = 1

	BEGIN TRANSACTION
	BEGIN TRY 

		DECLARE @num_dni		varchar(20)
		DECLARE @num_dni_repo	varchar(20)
		DECLARE @T_ApePaterno	varchar(100)
		DECLARE @T_ApeMaterno	varchar(100)
		DECLARE @T_Nombre		varchar(100)
		DECLARE @B_Correcto		bit
		DECLARE @I_PersonaID	int

		SELECT @num_dni = ISNULL(LTRIM(RTRIM(REPLACE(C_NumDNI,' ', ' '))), ''),
			   @T_ApePaterno = LTRIM(RTRIM(T_ApePaterno)) COLLATE Modern_Spanish_CI_AI,
			   @T_ApeMaterno = LTRIM(RTRIM(T_ApeMaterno)) COLLATE Modern_Spanish_CI_AI,
			   @T_Nombre = LTRIM(RTRIM(T_Nombre)) COLLATE Modern_Spanish_CI_AI,
			   @B_Correcto = B_Correcto 
		FROM TR_Alumnos WHERE I_RowID = @I_RowID
		
		IF (@B_Correcto = 1)
		BEGIN
			EXECUTE USP_MigracionTP_Alumnos_U_RemoverObservacionPorAlumno @I_RowID, @I_TablaID, @I_ObservID, @D_FecProceso
		END
		ELSE
		BEGIN
			SET @num_dni_repo = (SELECT TOP 1 C_NumDNI FROM BD_UNFV_Repositorio..TC_Persona WHERE C_NumDNI = @num_dni)

			SET @I_PersonaID = (SELECT DISTINCT I_PersonaID FROM BD_UNFV_Repositorio..TC_Persona 
								 WHERE ISNULL(C_NumDNI, '') = ISNULL(@num_dni, '')
									   AND T_ApePaterno COLLATE Modern_Spanish_CI_AI = @T_ApePaterno COLLATE Modern_Spanish_CI_AI
									   AND T_Apematerno COLLATE Modern_Spanish_CI_AI = @T_ApeMaterno COLLATE Modern_Spanish_CI_AI
									   AND T_Nombre COLLATE Modern_Spanish_CI_AI = @T_Nombre COLLATE Modern_Spanish_CI_AI
									   AND B_Eliminado = 0)

			IF (ISNULL(@num_dni_repo,'') = ISNULL(@num_dni,'') AND @I_PersonaID IS NOT NULL)
			BEGIN
				EXECUTE USP_MigracionTP_Alumnos_U_RemoverObservacionPorAlumno @I_RowID, @I_TablaID, @I_ObservID, @D_FecProceso
			END
			ELSE
			BEGIN
				EXECUTE USP_MigracionTP_Alumnos_U_RegistrarObservacionPorAlumno @I_RowID, @I_TablaID, @I_ObservID, @D_FecProceso
			END
		END					   
				
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

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_MigracionTP_Alumnos_U_ValidarCorrespondenciaNumDocumentoPersona')
	DROP PROCEDURE [dbo].[USP_MigracionTP_Alumnos_U_ValidarCorrespondenciaNumDocumentoPersona]
GO

CREATE PROCEDURE USP_MigracionTP_Alumnos_U_ValidarCorrespondenciaNumDocumentoPersona	
	@I_ProcedenciaID tinyint,
	@B_Resultado  bit output,
	@T_Message	  nvarchar(4000) OUTPUT	
AS
--declare @B_Resultado  bit,
--		@I_ProcedenciaID tinyint = 3,
--		@T_Message	  nvarchar(4000)
--exec USP_MigracionTP_Alumnos_U_ValidarCorrespondenciaNumDocumentoPersona @I_ProcedenciaID, @B_Resultado output, @T_Message output
--select @B_Resultado as resultado, @T_Message as mensaje
BEGIN
	DECLARE @I_Observados int = 0
	DECLARE @D_FecProceso datetime = GETDATE() 
	DECLARE @I_ObservID int = 30
	DECLARE @I_TablaID int = 1

	BEGIN TRANSACTION
	BEGIN TRY 
		
		SELECT I_RowID, C_RcCod, C_CodAlu, A.C_NumDNI, C_CodTipDoc, A.T_ApePaterno, A.T_ApeMaterno, A.T_Nombre, I_ProcedenciaID, C_Sexo, D_FecNac, C_CodModIng, C_AnioIngreso
		INTO #NumDoc_Repetidos_nombres_diferentes
		FROM TR_Alumnos A
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


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_MigracionTP_Alumnos_U_ValidarCorrespondenciaNumDocumentoPersonaPorAlumnoID')
	DROP PROCEDURE [dbo].[USP_MigracionTP_Alumnos_U_ValidarCorrespondenciaNumDocumentoPersonaPorAlumnoID]
GO

CREATE PROCEDURE USP_MigracionTP_Alumnos_U_ValidarCorrespondenciaNumDocumentoPersonaPorAlumnoID	
	@I_RowID tinyint,
	@B_Resultado  bit output,
	@T_Message	  nvarchar(4000) OUTPUT	
AS
--declare @B_Resultado  bit,
--		@I_RowID	  int = 2,
--		@T_Message	  nvarchar(4000)
--exec USP_MigracionTP_Alumnos_U_ValidarCorrespondenciaNumDocumentoPersonaPorAlumnoID @I_RowID, @B_Resultado output, @T_Message output
--select @B_Resultado as resultado, @T_Message as mensaje
BEGIN
	DECLARE @I_Observados int = 0
	DECLARE @D_FecProceso datetime = GETDATE() 
	DECLARE @I_ObservID int = 30
	DECLARE @I_TablaID int = 1

	BEGIN TRANSACTION
	BEGIN TRY 
		
		DECLARE @num_dni		varchar(20)
		DECLARE @T_ApePaterno	varchar(100)
		DECLARE @T_ApeMaterno	varchar(100)
		DECLARE @T_Nombre		varchar(100)
		DECLARE @I_Distincts	int
		DECLARE @B_Correcto		bit

		SELECT @num_dni = LTRIM(RTRIM(REPLACE(C_NumDNI,' ', ' '))), 
			   @T_ApePaterno = LTRIM(RTRIM(T_ApePaterno)) COLLATE Modern_Spanish_CI_AI,
			   @T_ApeMaterno = LTRIM(RTRIM(T_ApeMaterno)) COLLATE Modern_Spanish_CI_AI,
			   @T_Nombre = LTRIM(RTRIM(T_Nombre)) COLLATE Modern_Spanish_CI_AI,
			   @B_Correcto = B_Correcto 
		FROM TR_Alumnos WHERE I_RowID = @I_RowID
		
		IF (@B_Correcto = 1)
		BEGIN
			EXECUTE USP_MigracionTP_Alumnos_U_RemoverObservacionPorAlumno @I_RowID, @I_TablaID, @I_ObservID, @D_FecProceso
		END
		ELSE
		BEGIN
			SET @I_Distincts = (SELECT COUNT(*) 
							      FROM (SELECT DISTINCT C_NumDNI, T_ApePaterno, T_ApeMaterno, T_Nombre 
										  FROM TR_Alumnos 
										 WHERE LTRIM(RTRIM(REPLACE(C_NumDNI,' ', ' '))) = @num_dni
											   AND C_NumDNI IS NOT NULL
									   ) TBL
								)
			
			IF (ISNULL(@I_Distincts, 1) <= 1)
			BEGIN
				EXECUTE USP_MigracionTP_Alumnos_U_RemoverObservacionPorAlumno @I_RowID, @I_TablaID, @I_ObservID, @D_FecProceso
			END
			ELSE
			BEGIN
				EXECUTE USP_MigracionTP_Alumnos_U_RegistrarObservacionPorAlumno @I_RowID, @I_TablaID, @I_ObservID, @D_FecProceso
			END
		END		

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


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_U_ValidarCodigosAlumnoRemovidos')
	DROP PROCEDURE [dbo].[USP_U_ValidarCodigosAlumnoRemovidos]
GO

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_MigracionTP_Alumnos_U_ValidarCodigosRemovidos')
	DROP PROCEDURE [dbo].[USP_MigracionTP_Alumnos_U_ValidarCodigosRemovidos]
GO

CREATE PROCEDURE USP_MigracionTP_Alumnos_U_ValidarCodigosRemovidos	
	@I_ProcedenciaID tinyint,
	@B_Resultado	 bit output,
	@T_Message		 nvarchar(4000) OUTPUT	
AS
--declare @B_Resultado  bit,
--		@I_ProcedenciaID tinyint = 3,
--		@T_Message	  nvarchar(4000)
--exec USP_MigracionTP_Alumnos_U_ValidarCodigosRemovidos @I_ProcedenciaID, @B_Resultado output, @T_Message output
--select @B_Resultado as resultado, @T_Message as mensaje
BEGIN
	DECLARE @I_Observados int = 0
	DECLARE @D_FecProceso datetime = GETDATE() 
	DECLARE @I_ObservID int = 45
	DECLARE @I_TablaID int = 1

	BEGIN TRANSACTION
	BEGIN TRY 
		UPDATE	TR_Alumnos
		SET		B_Migrable = 0,
				D_FecEvalua = @D_FecProceso
		WHERE	I_ProcedenciaID = @I_ProcedenciaID
				AND B_Removido = 1
				
		MERGE TI_ObservacionRegistroTabla AS TRG
		USING 	(SELECT	@I_ObservID AS I_ObservID, @I_TablaID AS I_TablaID, I_RowID AS I_FilaTablaID, @D_FecProceso AS D_FecRegistro FROM TR_Alumnos
				  WHERE	I_ProcedenciaID = @I_ProcedenciaID
						AND B_Removido = 1
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


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_MigracionTP_Alumnos_U_ValidarCodigosRemovidosPorAlumnoID')
	DROP PROCEDURE [dbo].[USP_MigracionTP_Alumnos_U_ValidarCodigosRemovidosPorAlumnoID]
GO

CREATE PROCEDURE USP_MigracionTP_Alumnos_U_ValidarCodigosRemovidosPorAlumnoID	
	@I_RowID	  tinyint,
	@B_Resultado  bit output,
	@T_Message	  nvarchar(4000) OUTPUT	
AS
--declare @B_Resultado  bit,
--		@I_ProcedenciaID tinyint = 3,
--		@T_Message	  nvarchar(4000)
--exec USP_U_ValidarCodigosAlumnoRemovidosPorAlumnoID @I_RowID, @B_Resultado output, @T_Message output
--select @B_Resultado as resultado, @T_Message as mensaje
BEGIN
	DECLARE @I_Observados int = 0
	DECLARE @D_FecProceso datetime = GETDATE() 
	DECLARE @I_ObservID int = 45
	DECLARE @I_TablaID int = 1

	BEGIN TRANSACTION
	BEGIN TRY 
		DECLARE @B_Correcto		bit
		DECLARE @B_Removido		bit

		SELECT @B_Removido = B_Removido, @B_Correcto = B_Correcto FROM TR_Alumnos WHERE I_RowID = @I_RowID 


		IF (@B_Correcto = 1)
		BEGIN
			EXECUTE USP_MigracionTP_Alumnos_U_RemoverObservacionPorAlumno @I_RowID, @I_TablaID, @I_ObservID, @D_FecProceso
		END
		ELSE
		BEGIN
			IF (@B_Removido = 0)
			BEGIN
				EXECUTE USP_MigracionTP_Alumnos_U_RemoverObservacionPorAlumno @I_RowID, @I_TablaID, @I_ObservID, @D_FecProceso
			END
			ELSE
			BEGIN
				EXECUTE USP_MigracionTP_Alumnos_U_RegistrarObservacionPorAlumno @I_RowID, @I_TablaID, @I_ObservID, @D_FecProceso
			END
		END		
				
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

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_MigracionTP_Alumnos_U_ValidarCodigosRepetidos')
	DROP PROCEDURE [dbo].[USP_MigracionTP_Alumnos_U_ValidarCodigosRepetidos]
GO

CREATE PROCEDURE USP_MigracionTP_Alumnos_U_ValidarCodigosRepetidos	
	@I_ProcedenciaID tinyint,
	@B_Resultado  bit output,
	@T_Message	  nvarchar(4000) OUTPUT	
AS
--declare @B_Resultado  bit,
--		@I_ProcedenciaID tinyint = 3,
--		@T_Message	  nvarchar(4000)
--exec USP_MigracionTP_Alumnos_U_ValidarCodigosRepetidos @I_ProcedenciaID, @B_Resultado output, @T_Message output
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
		WHERE	I_ProcedenciaID = @I_ProcedenciaID
				AND EXISTS (SELECT C_CodAlu, C_RcCod, COUNT(*) FROM TR_Alumnos A 
							WHERE A.C_CodAlu = TR_Alumnos.C_CodAlu AND A.C_RcCod = TR_Alumnos.C_RcCod AND B_Removido <> 1
							GROUP BY C_CodAlu, C_RcCod HAVING COUNT(*) > 1)
				
		MERGE TI_ObservacionRegistroTabla AS TRG
		USING 	(SELECT	@I_ObservID AS I_ObservID, @I_TablaID AS I_TablaID, I_RowID AS I_FilaTablaID, @D_FecProceso AS D_FecRegistro FROM TR_Alumnos
				  WHERE	I_ProcedenciaID = @I_ProcedenciaID 
						AND EXISTS (SELECT C_CodAlu, C_RcCod, COUNT(*) FROM TR_Alumnos A 
									WHERE A.C_CodAlu = TR_Alumnos.C_CodAlu AND A.C_RcCod = TR_Alumnos.C_RcCod AND B_Removido <> 1
									GROUP BY C_CodAlu, C_RcCod HAVING COUNT(*) > 1)
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


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_MigracionTP_Alumnos_U_ValidarCodigosRepetidosPorAlumnoID')
	DROP PROCEDURE [dbo].[USP_MigracionTP_Alumnos_U_ValidarCodigosRepetidosPorAlumnoID]
GO

CREATE PROCEDURE USP_MigracionTP_Alumnos_U_ValidarCodigosRepetidosPorAlumnoID	
	@I_RowID		 int,
	@B_Resultado  bit output,
	@T_Message	  nvarchar(4000) OUTPUT	
AS
--declare @B_Resultado  bit,
--		@I_RowID	  int = 3,
--		@T_Message	  nvarchar(4000)
--exec USP_MigracionTP_Alumnos_U_ValidarCodigosRepetidosPorAlumnoID @I_RowID, @B_Resultado output, @T_Message output
--select @B_Resultado as resultado, @T_Message as mensaje
BEGIN
	DECLARE @I_Observados int = 0
	DECLARE @D_FecProceso datetime = GETDATE() 
	DECLARE @I_ObservID int = 2
	DECLARE @I_TablaID int = 1

	BEGIN TRANSACTION
	BEGIN TRY 
		DECLARE @C_RcCod		varchar(5)
		DECLARE @C_CodAlu		varchar(20)
		DECLARE @B_Correcto		bit
		DECLARE @I_Repetidos	int = 0

		SELECT @C_CodAlu = C_CodAlu, @C_RcCod = C_RcCod, @B_Correcto = B_Correcto FROM TR_Alumnos WHERE I_RowID = @I_RowID 

		IF (@B_Correcto = 1)
		BEGIN
			EXECUTE USP_MigracionTP_Alumnos_U_RemoverObservacionPorAlumno @I_RowID, @I_TablaID, @I_ObservID, @D_FecProceso
		END
		ELSE
		BEGIN
			SET @I_Repetidos = (SELECT COUNT(*) FROM TR_Alumnos WHERE C_CodAlu = @C_CodAlu AND C_RcCod = @C_RcCod AND B_Removido <> 1)
			
			IF (@I_Repetidos <= 1)
			BEGIN
				EXECUTE USP_MigracionTP_Alumnos_U_RemoverObservacionPorAlumno @I_RowID, @I_TablaID, @I_ObservID, @D_FecProceso
			END
			ELSE
			BEGIN
				EXECUTE USP_MigracionTP_Alumnos_U_RegistrarObservacionPorAlumno @I_RowID, @I_TablaID, @I_ObservID, @D_FecProceso
			END
		END

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


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_U_ValidarTipoDocumentoIdentidadAlumno')
	DROP PROCEDURE [dbo].[USP_U_ValidarTipoDocumentoIdentidadAlumno]
GO

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_MigracionTP_Alumnos_U_ValidarTipoDocumentoIdentidad')
	DROP PROCEDURE [dbo].[USP_MigracionTP_Alumnos_U_ValidarTipoDocumentoIdentidad]
GO

CREATE PROCEDURE USP_MigracionTP_Alumnos_U_ValidarTipoDocumentoIdentidad	
	@I_ProcedenciaID tinyint,
	@B_Resultado  bit output,
	@T_Message	  nvarchar(4000) OUTPUT	
AS
--declare @B_Resultado  bit,
--		@I_ProcedenciaID tinyint = 3,
--		@T_Message	  nvarchar(4000)
--exec USP_MigracionTP_Alumnos_U_ValidarTipoDocumentoIdentidad @I_ProcedenciaID, @B_Resultado output, @T_Message output
--select @B_Resultado as resultado, @T_Message as mensaje
BEGIN
	DECLARE @I_Observados_NULL int = 0
	DECLARE @I_Observados_SEQV int = 0
	DECLARE @D_FecProceso datetime = GETDATE() 
	DECLARE @I_ObservID int
	DECLARE @I_TablaID int = 1

	BEGIN TRANSACTION
	BEGIN TRY 

		SET @I_ObservID = 23
		UPDATE	A1
		SET		B_Migrable = 0,
				D_FecEvalua = @D_FecProceso
		FROM	TR_Alumnos A1
				INNER JOIN (SELECT * FROM TR_Alumnos WHERE C_NumDNI IS NOT NULL) A2 ON A1.C_CodAlu = A2.C_CodAlu AND A1.C_RcCod = A2.C_RcCod
		WHERE	A1.I_ProcedenciaID = @I_ProcedenciaID 
				AND A1.C_CodTipDoc IS NULL
		
		MERGE TI_ObservacionRegistroTabla AS TRG
		USING 	(SELECT	@I_ObservID AS I_ObservID, @I_TablaID AS I_TablaID, I_RowID AS I_FilaTablaID, @D_FecProceso AS D_FecRegistro FROM TR_Alumnos
				  WHERE	I_ProcedenciaID = @I_ProcedenciaID 
						AND NOT EXISTS (SELECT C_CodModIng FROM BD_UNFV_Repositorio.dbo.TC_ModalidadIngreso MI
										WHERE MI.C_CodModIng = TR_Alumnos.C_CodModIng)) AS SRC
		ON TRG.I_ObservID = SRC.I_ObservID AND TRG.I_TablaID = SRC.I_TablaID 
			AND TRG.I_FilaTablaID = SRC.I_FilaTablaID 
		WHEN MATCHED THEN
			UPDATE SET D_FecRegistro = SRC.D_FecRegistro
		WHEN NOT MATCHED BY TARGET THEN
			INSERT (I_ObservID, I_TablaID, I_FilaTablaID, I_ProcedenciaID, D_FecRegistro)
			VALUES (SRC.I_ObservID, SRC.I_TablaID, SRC.I_FilaTablaID, @I_ProcedenciaID, SRC.D_FecRegistro)
		WHEN NOT MATCHED BY SOURCE AND TRG.I_TablaID = @I_TablaID AND TRG.I_ObservID = @I_ObservID AND TRG.I_ProcedenciaID = @I_ProcedenciaID THEN
			DELETE;

		SET @I_Observados_NULL = (SELECT COUNT(*) FROM TI_ObservacionRegistroTabla WHERE I_ObservID = @I_ObservID AND I_TablaID = @I_TablaID AND I_ProcedenciaID = @I_ProcedenciaID)

		SET @I_ObservID = 23
		UPDATE	A1
		SET		B_Migrable = 0,
				D_FecEvalua = @D_FecProceso
		FROM	TR_Alumnos A1
				INNER JOIN BD_UNFV_Repositorio.dbo.TC_TipoDocumentoIdentidad TD ON A1.C_CodTipDoc = TD.C_CodTipDoc
		WHERE	A1.I_ProcedenciaID = @I_ProcedenciaID 
				AND TD.C_CodTipDoc IS NULL

		MERGE TI_ObservacionRegistroTabla AS TRG
		USING 	(SELECT	@I_ObservID AS I_ObservID, @I_TablaID AS I_TablaID, I_RowID AS I_FilaTablaID, @D_FecProceso AS D_FecRegistro FROM TR_Alumnos
				  WHERE	I_ProcedenciaID = @I_ProcedenciaID 
						AND NOT EXISTS (SELECT C_CodModIng FROM BD_UNFV_Repositorio.dbo.TC_ModalidadIngreso MI
										WHERE MI.C_CodModIng = TR_Alumnos.C_CodModIng)) AS SRC
		ON TRG.I_ObservID = SRC.I_ObservID AND TRG.I_TablaID = SRC.I_TablaID 
			AND TRG.I_FilaTablaID = SRC.I_FilaTablaID 
		WHEN MATCHED THEN
			UPDATE SET D_FecRegistro = SRC.D_FecRegistro
		WHEN NOT MATCHED BY TARGET THEN
			INSERT (I_ObservID, I_TablaID, I_FilaTablaID, I_ProcedenciaID, D_FecRegistro)
			VALUES (SRC.I_ObservID, SRC.I_TablaID, SRC.I_FilaTablaID, @I_ProcedenciaID, SRC.D_FecRegistro)
		WHEN NOT MATCHED BY SOURCE AND TRG.I_ObservID = @I_ObservID AND TRG.I_ProcedenciaID = @I_ProcedenciaID THEN
			DELETE;

		SET @I_Observados_SEQV = (SELECT COUNT(*) FROM TI_ObservacionRegistroTabla WHERE I_ObservID = @I_ObservID AND I_TablaID = @I_TablaID AND I_ProcedenciaID = @I_ProcedenciaID)

		SELECT @I_Observados_NULL as cant_obs_null, @I_Observados_SEQV as cant_obs_seqv, @D_FecProceso as fec_proceso
				
		COMMIT TRANSACTION
		SET @B_Resultado = 1
		SET @T_Message = CAST(@I_Observados_NULL AS varchar) + ' | ' + CAST(@I_Observados_SEQV AS varchar)
	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION
		SET @B_Resultado = 0
		SET @T_Message = ERROR_MESSAGE() + ' (Linea: ' + CAST(ERROR_LINE() AS varchar(11)) + ').' 
	END CATCH
END
GO


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_U_UnfvRepo_ValidarDocumentoDiferenteMismoAlumno')
	DROP PROCEDURE [dbo].[USP_U_UnfvRepo_ValidarDocumentoDiferenteMismoAlumno]
GO

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_MigracionTP_Alumnos_U_ValidarDocumentoDiferenteMismoAlumno')
	DROP PROCEDURE [dbo].[USP_MigracionTP_Alumnos_U_ValidarDocumentoDiferenteMismoAlumno]
GO

CREATE PROCEDURE USP_MigracionTP_Alumnos_U_ValidarDocumentoDiferenteMismoAlumno	
	@I_ProcedenciaID tinyint,
	@B_Resultado  bit output,
	@T_Message	  nvarchar(4000) OUTPUT	
AS
--declare @B_Resultado  bit,
--		@I_ProcedenciaID tinyint = 3,
--		@T_Message	  nvarchar(4000)
--exec USP_MigracionTP_Alumnos_U_ValidarDocumentoDiferenteMismoAlumno @I_ProcedenciaID, @B_Resultado output, @T_Message output
--select @B_Resultado as resultado, @T_Message as mensaje
BEGIN
	DECLARE @I_Observados int = 0
	DECLARE @D_FecProceso datetime = GETDATE() 
	DECLARE @I_ObservID int = 48
	DECLARE @I_TablaID int = 1

	BEGIN TRANSACTION
	BEGIN TRY 
	

		SELECT A.C_CodAlu, A.C_RcCod, A.C_AnioIngreso, A.C_CodModIng,
				LTRIM(RTRIM(REPLACE(C_NumDNI,' ', ' '))) AS C_NumDNI, C_CodTipDoc, 
				LTRIM(RTRIM(T_ApePaterno)) AS T_ApePaterno, 
				LTRIM(RTRIM(T_ApeMaterno)) AS T_ApeMaterno, 
				LTRIM(RTRIM(T_Nombre)) AS T_Nombre	
		INTO   #AlumnoPersona_Repositorio
		FROM   BD_UNFV_Repositorio.dbo.TC_Persona P
				INNER JOIN BD_UNFV_Repositorio.dbo.TC_Alumno A ON P.I_PersonaID = A.I_PersonaID
		WHERE  A.B_Eliminado = 0 AND P.B_Eliminado = 0 

		UPDATE	TR_Alumnos
		SET		B_Migrable = 0,
				D_FecEvalua = @D_FecProceso
		WHERE	EXISTS  (SELECT A.*, APR.* 
						   FROM #AlumnoPersona_Repositorio APR
								INNER JOIN TR_Alumnos A ON A.C_RcCod = APR.C_RcCod AND A.C_CodAlu = APR.C_CodAlu
						  WHERE  LTRIM(RTRIM(REPLACE(ISNULL(A.C_NumDNI,''),' ', ' '))) <> ISNULL(APR.C_NumDNI, '' ) 
								 AND LTRIM(RTRIM(REPLACE(ISNULL(A.C_NumDNI,''),' ', ' '))) <> ''
								 AND APR.C_NumDNI <> ''
								 AND A.I_RowID = TR_Alumnos.I_RowID)
				AND I_ProcedenciaID = @I_ProcedenciaID 
				AND ISNULL(B_Correcto, 0) <> 1


		MERGE TI_ObservacionRegistroTabla AS TRG
		USING 	(SELECT	@I_ObservID AS I_ObservID, @I_TablaID AS I_TablaID, I_RowID AS I_FilaTablaID, @D_FecProceso AS D_FecRegistro FROM TR_Alumnos
				  WHERE	EXISTS  (SELECT A.*, APR.* 
								   FROM #AlumnoPersona_Repositorio APR
										INNER JOIN TR_Alumnos A ON A.C_RcCod = APR.C_RcCod AND A.C_CodAlu = APR.C_CodAlu
								  WHERE LTRIM(RTRIM(REPLACE(ISNULL(A.C_NumDNI,''),' ', ' '))) <> ISNULL(APR.C_NumDNI, '' ) 
										AND LTRIM(RTRIM(REPLACE(ISNULL(A.C_NumDNI,''),' ', ' '))) <> ''
										AND APR.C_NumDNI <> ''
										AND A.I_RowID = TR_Alumnos.I_RowID)
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


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_MigracionTP_Alumnos_U_ValidarDocumentoDiferenteMismoAlumnoPorAlumnoID')
	DROP PROCEDURE [dbo].[USP_MigracionTP_Alumnos_U_ValidarDocumentoDiferenteMismoAlumnoPorAlumnoID]
GO

CREATE PROCEDURE [dbo].[USP_MigracionTP_Alumnos_U_ValidarDocumentoDiferenteMismoAlumnoPorAlumnoID]	
	@I_RowID	  int,
	@B_Resultado  bit output,
	@T_Message	  nvarchar(4000) OUTPUT	
AS
--declare @B_Resultado  bit,
--		@I_RowID	  int,
--		@T_Message	  nvarchar(4000)
--exec USP_MigracionTP_Alumnos_U_ValidarDocumentoDiferenteMismoAlumnoPorAlumnoID @I_RowID, @B_Resultado output, @T_Message output
--select @B_Resultado as resultado, @T_Message as mensaje
BEGIN
	DECLARE @I_Observados int = 0
	DECLARE @D_FecProceso datetime = GETDATE() 
	DECLARE @I_ObservID int = 48
	DECLARE @I_TablaID int = 1

	BEGIN TRANSACTION
	BEGIN TRY 

		DECLARE @num_dni		varchar(20)
		DECLARE @num_dni_repo	varchar(20)
		DECLARE @C_RcCod		varchar(5)
		DECLARE @C_CodAlu		varchar(20)
		DECLARE @I_PersonaID	int
		DECLARE @B_Correcto		bit

		SELECT @C_CodAlu = C_CodAlu, @num_dni = ISNULL(LTRIM(RTRIM(REPLACE(C_NumDNI,' ', ' '))), ''), @C_RcCod = C_RcCod, @B_Correcto = B_Correcto FROM TR_Alumnos WHERE I_RowID = @I_RowID 
		SELECT @num_dni_repo = ISNULL(C_NumDNI, ''), @I_PersonaID = I_PersonaID FROM BD_UNFV_Repositorio.dbo.VW_Alumnos WHERE C_CodAlu = @C_CodAlu AND C_RcCod = @C_RcCod

		IF (@B_Correcto = 1)
		BEGIN
			EXECUTE USP_MigracionTP_Alumnos_U_RemoverObservacionPorAlumno @I_RowID, @I_TablaID, @I_ObservID, @D_FecProceso
		END
		ELSE
		BEGIN
			IF(@num_dni = @num_dni_repo)
			BEGIN
				EXECUTE USP_MigracionTP_Alumnos_U_RemoverObservacionPorAlumno @I_RowID, @I_TablaID, @I_ObservID, @D_FecProceso
			END
			ELSE
			BEGIN
				EXECUTE USP_MigracionTP_Alumnos_U_RegistrarObservacionPorAlumno @I_RowID, @I_TablaID, @I_ObservID, @D_FecProceso
			END
		END

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


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_IU_CopiarTablaAlumno')
	DROP PROCEDURE [dbo].[USP_IU_CopiarTablaAlumno]
GO

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_MigracionTP_Alumnos_IU_CopiarTabla')
	DROP PROCEDURE [dbo].[USP_MigracionTP_Alumnos_IU_CopiarTabla]
GO

CREATE PROCEDURE USP_MigracionTP_Alumnos_IU_CopiarTabla	
	@I_ProcedenciaID tinyint,
	@T_SchemaDB		 varchar(20),
	@B_Resultado  bit output,
	@T_Message	  nvarchar(4000) OUTPUT	
AS
--declare @B_Resultado  bit,
--		  @I_ProcedenciaID	tinyint = 1,
--		  @T_SchemaDB	varchar(20) = 'pregrado',
--		  @T_Message	nvarchar(4000)
--exec USP_MigracionTP_Alumnos_IU_CopiarTabla @I_ProcedenciaID, @T_SchemaDB, @B_Resultado output, @T_Message output
--select @B_Resultado as resultado, @T_Message as mensaje
BEGIN
	DECLARE @T_SQL nvarchar(max)

	DECLARE @I_CantAlu int = 0
	DECLARE @I_CantAlu_schema int = 0
	DECLARE @I_Removidos int = 0
	DECLARE @I_Actualizados int = 0
	DECLARE @I_Insertados int = 0
	DECLARE @D_FecProceso datetime = GETDATE() 

	CREATE TABLE #Tbl_output  
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

	BEGIN TRANSACTION;
	BEGIN TRY 
	
		SET @T_SQL = 'DECLARE @D_FecProceso datetime = GETDATE()			 

					  MERGE TR_Alumnos AS TRG
					  USING (SELECT C_RCCOD, C_CODALU, T_APEPATER, T_APEMATER, T_NOMBRE, C_NUMDNI, C_CODTIPDO, C_CODMODIN, C_ANIOINGR, D_FECNAC, C_SEXO 
					  		 FROM BD_OCEF_TemporalPagos.dbo.alumnos A
					  			  INNER JOIN (SELECT DISTINCT Cod_alu, Cod_rc FROM BD_OCEF_TemporalPagos.' + @T_SchemaDB + '.ec_pri) O ON A.C_CODALU = O.cod_alu AND A.C_RCCOD = O.cod_rc 
							 UNION 
							 SELECT C_RCCOD, C_CODALU, T_APEPATER, T_APEMATER, T_NOMBRE, C_NUMDNI, C_CODTIPDO, C_CODMODIN, C_ANIOINGR, D_FECNAC, C_SEXO 
					  		 FROM BD_OCEF_TemporalPagos.dbo.alumnos A
					  			  INNER JOIN (SELECT DISTINCT Cod_alu, Cod_rc FROM BD_OCEF_TemporalPagos.' + @T_SchemaDB + '.ec_obl) O ON A.C_CODALU = O.cod_alu AND A.C_RCCOD = O.cod_rc 
					  	     GROUP BY C_RCCOD, C_CODALU, T_APEPATER, T_APEMATER, T_NOMBRE, C_NUMDNI, C_CODTIPDO, C_CODMODIN, C_ANIOINGR, D_FECNAC, C_SEXO) AS SRC
					  ON TRG.C_CodAlu = SRC.C_CodAlu 
					  	 AND TRG.C_RcCod = SRC.C_RcCod
					  	 AND ISNULL(TRG.C_CodModIng, '''') = ISNULL(SRC.C_CODMODIN, '''')
					  	 AND TRG.C_AnioIngreso = SRC.C_ANIOINGR
					  WHEN MATCHED THEN
					  	UPDATE SET	TRG.C_NumDNI = CASE WHEN LTRIM(RTRIM(REPLACE(SRC.C_NumDNI,'' '', '' ''))) = '''' THEN NULL ELSE LTRIM(RTRIM(REPLACE(SRC.C_NumDNI,'' '', '' ''))) END,
					  				TRG.C_CodTipDoc = CASE WHEN SRC.C_CODTIPDO = '''' THEN NULL ELSE SRC.C_CODTIPDO END,
					  				TRG.T_ApePaterno = REPLACE(SRC.T_APEPATER, ''-'', '' ''),
					  				TRG.T_ApeMaterno = REPLACE(SRC.T_APEMATER, ''-'', '' ''),
					  				TRG.T_Nombre = REPLACE(SRC.T_NOMBRE, ''-'', '' ''),
					  				TRG.C_Sexo = SRC.C_SEXO,
					  				TRG.D_FecNac = CASE WHEN TRY_CONVERT(DATE, SRC.D_FECNAC, 103) IS NULL THEN IIF(ISDATE(SRC.D_FECNAC) = 1, SRC.D_FECNAC, NULL) ELSE CONVERT(DATE, SRC.D_FECNAC, 103) END
					  WHEN NOT MATCHED BY TARGET THEN
					  	INSERT (C_RcCod, C_CodAlu, C_NumDNI, C_CodTipDoc, T_ApePaterno, T_ApeMaterno, T_Nombre, C_Sexo, D_FecNac, C_CodModIng, C_AnioIngreso, I_ProcedenciaID, D_FecCarga, B_Actualizado)
					  	VALUES (SRC.C_RcCod, SRC.C_CodAlu, CASE WHEN LTRIM(RTRIM(REPLACE(SRC.C_NumDNI,'' '', '' ''))) = '''' THEN NULL ELSE LTRIM(RTRIM(REPLACE(SRC.C_NumDNI,'' '', '' ''))) END, 
								CASE WHEN SRC.C_CODTIPDO = '''' THEN NULL ELSE SRC.C_CODTIPDO END, REPLACE(SRC.T_APEPATER, ''-'', '' ''), REPLACE(SRC.T_APEMATER, ''-'', '' ''), REPLACE(SRC.T_NOMBRE, ''-'', '' ''), 							  	
					  			SRC.C_SEXO, CASE WHEN TRY_CONVERT(DATE, SRC.D_FECNAC, 103) IS NULL THEN IIF(ISDATE(SRC.D_FECNAC) = 1, SRC.D_FECNAC, NULL) ELSE CONVERT(DATE, SRC.D_FECNAC, 103) END, 
					  			SRC.C_CODMODIN, SRC.C_ANIOINGR, ' + CAST(@I_ProcedenciaID as varchar(3)) + ', @D_FecProceso, 1)
					  WHEN NOT MATCHED BY SOURCE AND TRG.I_ProcedenciaID = '+ CAST(@I_ProcedenciaID as varchar(3)) + ' THEN
					  	UPDATE SET TRG.B_Removido = 1, 
					  			   TRG.D_FecRemovido = @D_FecProceso
					  OUTPUT $ACTION, inserted.C_RcCod, inserted.C_CodAlu, inserted.C_NumDNI, inserted.C_CodTipDoc, inserted.T_ApePaterno,   
					  		 inserted.T_ApeMaterno, inserted.T_Nombre, inserted.C_Sexo, inserted.D_FecNac, inserted.C_CodModIng, inserted.C_AnioIngreso, 
					  		 deleted.C_NumDNI, deleted.C_CodTipDoc, deleted.T_ApePaterno, deleted.T_ApeMaterno, deleted.T_Nombre, 
					  		 deleted.C_Sexo, deleted.D_FecNac, deleted.C_CodModIng, deleted.C_AnioIngreso, deleted.B_Removido INTO #Tbl_output;		
					'

		print @T_SQL
		Exec sp_executesql @T_SQL

		UPDATE	TR_Alumnos 
				SET	B_Actualizado = 0, B_Migrable = 0, D_FecMigrado = NULL, B_Migrado = 0
		WHERE  I_ProcedenciaID = @I_ProcedenciaID

		UPDATE	t_Alu
		SET		t_Alu.B_Actualizado = 1,
				t_Alu.D_FecActualiza = @D_FecProceso
		FROM TR_Alumnos AS t_Alu
				INNER JOIN 	#Tbl_output as t_out ON t_out.C_RcCod = t_Alu.C_RcCod 
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
		SET @I_Insertados = (SELECT COUNT(*) FROM #Tbl_output WHERE accion = 'INSERT')
		SET @I_Actualizados = (SELECT COUNT(*) FROM #Tbl_output WHERE accion = 'UPDATE' AND B_Removido = 0)
		SET @I_Removidos = (SELECT COUNT(*) FROM #Tbl_output WHERE accion = 'UPDATE' AND B_Removido = 1)
		
		SET @T_SQL = 'SELECT A.* FROM BD_OCEF_TemporalPagos.dbo.alumnos A 
					  INNER JOIN (SELECT DISTINCT Cod_alu, Cod_rc FROM BD_OCEF_TemporalPagos.' + @T_SchemaDB + '.ec_pri) O ON A.C_CODALU = O.cod_alu AND A.C_RCCOD = O.cod_rc 
					  UNION 
					  SELECT A.* FROM BD_OCEF_TemporalPagos.dbo.alumnos A 
					  INNER JOIN (SELECT DISTINCT Cod_alu, Cod_rc FROM BD_OCEF_TemporalPagos.' + @T_SchemaDB + '.ec_obl) O ON A.C_CODALU = O.cod_alu AND A.C_RCCOD = O.cod_rc '

		exec sp_executesql @T_SQL
		SET @I_CantAlu_schema = @@ROWCOUNT

		SELECT @I_CantAlu AS tot_alumnos, @I_Insertados AS cant_inserted, @I_Actualizados as cant_updated, @I_Removidos as cant_removed, @D_FecProceso as fec_proceso

		COMMIT TRANSACTION;

		SET @B_Resultado = 1
		SET @T_Message =  'Total Alumnos: ' + CAST(@I_CantAlu AS varchar) + ' | Total ' + @T_SchemaDB + ': ' + CAST(@I_CantAlu_schema AS varchar) + 
						  '| Insertados: ' + CAST(@I_Insertados AS varchar) + ' | Actualizados: ' + CAST(@I_Actualizados AS varchar) + ' | Removidos: ' + CAST(@I_Removidos AS varchar)

	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION;
		SET @B_Resultado = 0
		SET @T_Message = ERROR_MESSAGE() + ' (Linea: ' + CAST(ERROR_LINE() AS varchar(11)) + ').' 
	END CATCH
END
GO


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_U_ActualizarRegistroAlumno')
	DROP PROCEDURE [dbo].[USP_U_ActualizarRegistroAlumno]
GO

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_MigracionTP_Alumnos_U_ActualizarRegistro')
	DROP PROCEDURE [dbo].[USP_MigracionTP_Alumnos_U_ActualizarRegistro]
GO

CREATE PROCEDURE USP_MigracionTP_Alumnos_U_ActualizarRegistro
	@I_RowID	  int,
	@C_RcCod	  varchar(3),
	@C_CodAlu	  varchar(20), 
	@C_NumDNI	  varchar(20), 
	@C_CodTipDoc  varchar(5), 
	@T_ApePaterno varchar(50),  
	@T_ApeMaterno varchar(50),  
	@T_Nombre	  varchar(50), 
	@C_Sexo		  char(1), 
	@D_FecNac	  date, 
	@C_CodModIng  varchar(2), 	 
	@C_AnioIngreso	 smallint,
	@I_ProcedenciaID tinyint,
	@B_Correcto   bit,
	@B_Removido   bit,
	@B_Resultado  bit output,
	@T_Message	  nvarchar(4000) OUTPUT	
AS
--declare @I_RowID		int,
--		  @C_RcCod		varchar(3),
--		  @C_CodAlu		varchar(20),
--		  @C_NumDNI		varchar(20),
--		  @C_CodTipDoc  varchar(5), 
--		  @T_ApePaterno varchar(50),
--		  @T_ApeMaterno varchar(50),
--		  @T_Nombre		varchar(50),
--		  @C_Sexo		char(1), 
--		  @D_FecNac		date, 
--		  @C_CodModIng  varchar(2), 
--		  @C_AnioIngreso	smallint,
--		  @I_ProcedenciaID	tinyint,
--		  @B_Correcto   bit,
--		  @B_Removido   bit,
--		  @B_Resultado  bit output,
--		  @T_Message	nvarchar(4000)
--exec USP_U_ActualizarRegistroAlumno @B_Resultado output, @T_Message output
--select @B_Resultado as resultado, @T_Message as mensaje
BEGIN

	DECLARE @D_FecProceso datetime = GETDATE() 
	DECLARE @I_ProcedenciaID_Old int

	SET @I_ProcedenciaID_Old = (SELECT I_ProcedenciaID  FROM TR_Alumnos WHERE I_RowID = @I_RowID)

	BEGIN TRANSACTION;
	BEGIN TRY 
		UPDATE TR_Alumnos
		SET	C_CodAlu = @C_CodAlu,
			C_RcCod = @C_RcCod,
			C_NumDNI = @C_NumDNI,
			C_CodTipDoc = @C_CodTipDoc,
			T_ApePaterno = @T_ApePaterno, 
			T_ApeMaterno = @T_ApeMaterno, 
			T_Nombre = @T_Nombre,
			C_Sexo = @C_Sexo,
			D_FecNac = @D_FecNac,
			C_AnioIngreso = @C_AnioIngreso,
			C_CodModIng = @C_CodModIng,
			I_ProcedenciaID = @I_ProcedenciaID,
			B_Correcto = @B_Correcto
		WHERE 
			I_RowID = @I_RowID

		IF (@B_Removido <> (SELECT B_Removido FROM TR_Alumnos WHERE I_RowID = @I_RowID))
		BEGIN
			UPDATE TR_Alumnos
			SET	B_Removido = @B_Removido,
				D_FecRemovido = @D_FecProceso
			WHERE 
				I_RowID = @I_RowID
		END

		IF (@I_ProcedenciaID_Old <> @I_ProcedenciaID)
		BEGIN
			UPDATE TI_ObservacionRegistroTabla 
			   SET I_ProcedenciaID = @I_ProcedenciaID
			WHERE 
				I_FilaTablaID = @I_RowID
				AND I_TablaID = 1
		END

		COMMIT TRANSACTION;
		
		SET @T_Message =  'Actualizado'
		SET @B_Resultado = 1

	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION;
		SET @B_Resultado = 0
		SET @T_Message = ERROR_MESSAGE() + ' (Linea: ' + CAST(ERROR_LINE() AS varchar(11)) + ').' 
	END CATCH
END
GO

