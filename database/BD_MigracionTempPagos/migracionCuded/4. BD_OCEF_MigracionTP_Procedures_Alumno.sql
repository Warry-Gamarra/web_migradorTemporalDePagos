USE BD_OCEF_MigracionTP
GO


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_IU_MigrarDataAlumnosUnfvRepositorio')
	DROP PROCEDURE [dbo].[USP_IU_MigrarDataAlumnosUnfvRepositorio]
GO


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_IU_MigrarDataAlumnosPorAnio_UnfvRepositorio')
	DROP PROCEDURE [dbo].[USP_IU_MigrarDataAlumnosPorAnio_UnfvRepositorio]
GO

CREATE PROCEDURE USP_IU_MigrarDataAlumnosPorAnio_UnfvRepositorio
	@I_ProcedenciaID tinyint,
	@C_AnioIng	  smallint,	
	@B_Resultado  bit OUTPUT,
	@T_Message	  nvarchar(4000) OUTPUT	
AS
--declare @C_AnioIng  smallint = 2012,
--		@I_ProcedenciaID tinyint = 3,
--		@B_Resultado  bit,
--		@T_Message	  nvarchar(4000)
--exec USP_IU_MigrarDataAlumnosUnfvRepositorio @I_ProcedenciaID, @C_AnioIng, @B_Resultado output, @T_Message output
--select @B_Resultado as resultado, @T_Message as mensaje
BEGIN
	
	PRINT 'USP_IU_MigrarDataAlumnosPorAnio_UnfvRepositorio'
		
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



IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_Repositorio_U_ActualizarTablaPersona')
BEGIN
	DROP PROCEDURE dbo.USP_Repositorio_U_ActualizarTablaPersona
END
GO

CREATE PROCEDURE dbo.USP_Repositorio_U_ActualizarTablaPersona
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


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_Repositorio_U_ActualizarTablaAlumno')
BEGIN
	DROP PROCEDURE dbo.USP_Repositorio_U_ActualizarTablaAlumno
END
GO

CREATE PROCEDURE dbo.USP_Repositorio_U_ActualizarTablaAlumno
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


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_Repositorio_I_InsertarTablaAlumno')
BEGIN
	DROP PROCEDURE dbo.USP_Repositorio_I_InsertarTablaAlumno
END
GO

CREATE PROCEDURE dbo.USP_Repositorio_I_InsertarTablaAlumno
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


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_IU_MigrarDataAlumnoPorCodigo_UnfvRepositorio')
	DROP PROCEDURE [dbo].[USP_IU_MigrarDataAlumnoPorCodigo_UnfvRepositorio]
GO


CREATE PROCEDURE USP_IU_MigrarDataAlumnoPorCodigo_UnfvRepositorio
	@I_ProcedenciaID tinyint,
	@C_CodAlu	  varchar(20),
	@B_Resultado  bit OUTPUT,
	@T_Message	  nvarchar(4000) OUTPUT	
AS
--declare @C_CodAlu  varchar(20) = '2014706791',
--		@I_ProcedenciaID tinyint = 3,
--		@B_Resultado  bit,
--		@T_Message	  nvarchar(4000)
--exec USP_IU_MigrarDataAlumnoPorCodigo_UnfvRepositorio @I_ProcedenciaID, @C_CodAlu, @B_Resultado output, @T_Message output
--select @B_Resultado as resultado, @T_Message as mensaje
BEGIN
	
	PRINT 'INICIANDO - USP_IU_MigrarDataAlumnoPorCodigo_UnfvRepositorio'

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
			EXECUTE USP_Repositorio_U_ActualizarTablaPersona @C_CodAlu, @C_RcCod, @D_FecProceso, @B_Correcto, @I_TablaID;

			PRINT 'ACTUALIZANDO ALUMNO CON COD ' + @C_CodAlu + '...'
			EXECUTE USP_Repositorio_U_ActualizarTablaAlumno @C_CodAlu, @C_RcCod, @I_PersonaID, @D_FecProceso, @B_Correcto, @I_TablaID;

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
				EXECUTE USP_Repositorio_U_ActualizarTablaPersona @C_CodAlu, @C_RcCod, @D_FecProceso, @B_Correcto, @I_TablaID;

				PRINT 'INSERTANDO ALUMNO CON COD ' + @C_CodAlu + '...'
				EXECUTE USP_Repositorio_I_InsertarTablaAlumno @C_CodAlu, @C_RcCod, @I_PersonaID, @D_FecProceso, @I_TablaID, @I_RowID;

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
				EXECUTE USP_Repositorio_U_ActualizarTablaPersona @C_CodAlu, @C_RcCod, @D_FecProceso, @B_Correcto, @I_TablaID;

				PRINT 'INSERTANDO ALUMNO CON COD ' + @C_CodAlu + '...'
				EXECUTE USP_Repositorio_I_InsertarTablaAlumno @C_CodAlu, @C_RcCod, @I_PersonaID, @D_FecProceso, @I_TablaID, @I_RowID;

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
				EXECUTE USP_Repositorio_I_InsertarTablaAlumno @C_CodAlu, @C_RcCod, @I_PersonaID, @D_FecProceso, @I_TablaID, @I_RowID;

				UPDATE TR_Alumnos 
				   SET B_Migrado = 1,
					   D_FecMigrado = @D_FecProceso
				 WHERE B_Migrable = 1 AND I_RowID = @I_RowID
			END
		END


		SET @B_Resultado = 1
		SET @T_Message = 'Migrado: ' + @C_CodAlu

		PRINT 'FINALIZANDO - USP_IU_MigrarDataAlumnosPorAnio_UnfvRepositorio'

		COMMIT TRANSACTION
	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION
		SET @B_Resultado = 0
		SET @T_Message = ERROR_MESSAGE() + ' LINE: ' + CAST(ERROR_LINE() AS varchar(10)) 
	END CATCH
END
GO




IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_Repositorio_U_RemoverObservacionPorAlumno')
	DROP PROCEDURE [dbo].[USP_Repositorio_U_RemoverObservacionPorAlumno]
GO


CREATE PROCEDURE [dbo].[USP_Repositorio_U_RemoverObservacionPorAlumno]	
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


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_Repositorio_U_RegistrarObservacionPorAlumno')
	DROP PROCEDURE [dbo].[USP_Repositorio_U_RegistrarObservacionPorAlumno]
GO


CREATE PROCEDURE [dbo].[USP_Repositorio_U_RegistrarObservacionPorAlumno]	
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

CREATE PROCEDURE USP_U_InicializarEstadoValidacionAlumno	
	@I_ProcedenciaID tinyint,
	@B_Resultado  bit output,
	@T_Message	  nvarchar(4000) OUTPUT	
AS
--declare @B_Resultado  bit,
--		@I_ProcedenciaID	tinyint = 3,
--		@T_Message	  nvarchar(4000)
--exec USP_U_InicializarEstadoValidacionAlumno @I_ProcedenciaID, @B_Resultado output, @T_Message output
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



IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_U_InicializarEstadoValidacionPorAlumno')
	DROP PROCEDURE [dbo].[USP_U_InicializarEstadoValidacionPorAlumno]
GO

CREATE PROCEDURE USP_U_InicializarEstadoValidacionPorAlumno	
	@I_RowID      int,
	@B_Resultado  bit output,
	@T_Message	  nvarchar(4000) OUTPUT	
AS
--declare @B_Resultado  bit,
--		@I_ProcedenciaID	tinyint = 3,
--		@T_Message	  nvarchar(4000)
--exec USP_U_InicializarEstadoValidacionPorAlumno @I_RowID, @B_Resultado output, @T_Message output
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



IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_U_UnfvRepo_ValidarSexoDiferenteMismoAlumnoPorAlumnoID')
	DROP PROCEDURE [dbo].[USP_U_UnfvRepo_ValidarSexoDiferenteMismoAlumnoPorAlumnoID]
GO

CREATE PROCEDURE USP_U_UnfvRepo_ValidarSexoDiferenteMismoAlumnoPorAlumnoID	
	@I_RowID	  int,
	@B_Resultado  bit output,
	@T_Message	  nvarchar(4000) OUTPUT	
AS
--declare @B_Resultado  bit,
--		@I_RowID tinyint = 1,
--		@T_Message	  nvarchar(4000)
--exec USP_U_UnfvRepo_ValidarSexoDiferenteMismoAlumnoPorAlumnoID @I_RowID, @B_Resultado output, @T_Message output
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
			EXECUTE USP_Repositorio_U_RemoverObservacionPorAlumno @I_RowID, @I_TablaID, @I_ObservID, @D_FecProceso
		END
		ELSE
		BEGIN

			SELECT @C_Sexo_Repo = ISNULL(C_Sexo, '') FROM BD_UNFV_Repositorio.dbo.VW_Alumnos 
			WHERE C_CodAlu = @C_CodAlu AND C_RcCod = @C_RcCod


			IF (@C_Sexo_Repo = @C_Sexo)
			BEGIN
				EXECUTE USP_Repositorio_U_RemoverObservacionPorAlumno @I_RowID, @I_TablaID, @I_ObservID, @D_FecProceso
			END
			ELSE
			BEGIN
				EXECUTE USP_Repositorio_U_RegistrarObservacionPorAlumno @I_RowID, @I_TablaID, @I_ObservID, @D_FecProceso
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



IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_U_ValidarSexoDiferenteMismoDocumentoPorAlumno')
	DROP PROCEDURE [dbo].[USP_U_ValidarSexoDiferenteMismoDocumentoPorAlumno]
GO

CREATE PROCEDURE USP_U_ValidarSexoDiferenteMismoDocumentoPorAlumno	
	@I_RowID	  int,
	@B_Resultado  bit output,
	@T_Message	  nvarchar(4000) OUTPUT	
AS
--declare @B_Resultado  bit,
--		@I_RowID tinyint = 3,
--		@T_Message	  nvarchar(4000)
--exec USP_U_ValidarSexoDiferenteMismoDocumentoPorAlumno @I_RowID, @B_Resultado output, @T_Message output
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
			EXECUTE USP_Repositorio_U_RemoverObservacionPorAlumno @I_RowID, @I_TablaID, @I_ObservID, @D_FecProceso
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
				EXECUTE USP_Repositorio_U_RemoverObservacionPorAlumno @I_RowID, @I_TablaID, @I_ObservID, @D_FecProceso
			END
			ELSE
			BEGIN
				EXECUTE USP_Repositorio_U_RegistrarObservacionPorAlumno @I_RowID, @I_TablaID, @I_ObservID, @D_FecProceso
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


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_U_ValidarCorrespondenciaNumDocRepositorioPersonaPorAlumno')
	DROP PROCEDURE [dbo].[USP_U_ValidarCorrespondenciaNumDocRepositorioPersonaPorAlumno]
GO

CREATE PROCEDURE USP_U_ValidarCorrespondenciaNumDocRepositorioPersonaPorAlumno	
	@I_RowID	  int,
	@B_Resultado  bit output,
	@T_Message	  nvarchar(4000) OUTPUT	
AS
--declare @B_Resultado  bit,
--		@I_RowID int = 7765,
--		@T_Message	  nvarchar(4000)
--exec USP_U_ValidarCorrespondenciaNumDocRepositorioPersonaPorAlumno @I_RowID, @B_Resultado output, @T_Message output
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
			EXECUTE USP_Repositorio_U_RemoverObservacionPorAlumno @I_RowID, @I_TablaID, @I_ObservID, @D_FecProceso
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
				EXECUTE USP_Repositorio_U_RemoverObservacionPorAlumno @I_RowID, @I_TablaID, @I_ObservID, @D_FecProceso
			END
			ELSE
			BEGIN
				EXECUTE USP_Repositorio_U_RegistrarObservacionPorAlumno @I_RowID, @I_TablaID, @I_ObservID, @D_FecProceso
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


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_U_ValidarCorrespondenciaNumDocumentoPersonaPorAlumno')
	DROP PROCEDURE [dbo].[USP_U_ValidarCorrespondenciaNumDocumentoPersonaPorAlumno]
GO

CREATE PROCEDURE USP_U_ValidarCorrespondenciaNumDocumentoPersonaPorAlumno	
	@I_RowID tinyint,
	@B_Resultado  bit output,
	@T_Message	  nvarchar(4000) OUTPUT	
AS
--declare @B_Resultado  bit,
--		@I_RowID	  int = 2,
--		@T_Message	  nvarchar(4000)
--exec USP_U_ValidarCorrespondenciaNumDocumentoPersonaPorAlumno @I_RowID, @B_Resultado output, @T_Message output
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
			EXECUTE USP_Repositorio_U_RemoverObservacionPorAlumno @I_RowID, @I_TablaID, @I_ObservID, @D_FecProceso
		END
		ELSE
		BEGIN
			SET @I_Distincts = (SELECT COUNT(*) 
							    FROM (SELECT DISTINCT C_NumDNI, T_ApePaterno, T_ApeMaterno, T_Nombre 
										FROM TR_Alumnos 
									WHERE LTRIM(RTRIM(REPLACE(C_NumDNI,' ', ' '))) = @num_dni
										  AND C_NumDNI IS NOT NULL
									) TBL)
			

			IF (ISNULL(@I_Distincts, 1) <= 1)
			BEGIN
				EXECUTE USP_Repositorio_U_RemoverObservacionPorAlumno @I_RowID, @I_TablaID, @I_ObservID, @D_FecProceso
			END
			ELSE
			BEGIN
				EXECUTE USP_Repositorio_U_RegistrarObservacionPorAlumno @I_RowID, @I_TablaID, @I_ObservID, @D_FecProceso
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


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_U_ValidarModalidadIngresoAlumnoPorAlumnoID')
	DROP PROCEDURE [dbo].[USP_U_ValidarModalidadIngresoAlumnoPorAlumnoID]
GO

CREATE PROCEDURE USP_U_ValidarModalidadIngresoAlumnoPorAlumnoID	
	@I_RowID	  int,
	@B_Resultado  bit output,
	@T_Message	  nvarchar(4000) OUTPUT	
AS
--declare @B_Resultado  bit,
--		@I_ProcedenciaID tinyint = 3,
--		@T_Message	  nvarchar(4000)
--exec USP_U_ValidarModalidadIngresoAlumnoPorAlumnoID @I_ProcedenciaID, @B_Resultado output, @T_Message output
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
			EXECUTE USP_Repositorio_U_RemoverObservacionPorAlumno @I_RowID, @I_TablaID, @I_ObservID, @D_FecProceso
		END
		ELSE
		BEGIN
			IF (ISNULL(@C_AnioIngreso, 0) > 0)
			BEGIN
				EXECUTE USP_Repositorio_U_RemoverObservacionPorAlumno @I_RowID, @I_TablaID, @I_ObservID, @D_FecProceso
			END
			ELSE
			BEGIN
				EXECUTE USP_Repositorio_U_RegistrarObservacionPorAlumno @I_RowID, @I_TablaID, @I_ObservID, @D_FecProceso
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


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_U_ValidarAnioIngresopAlumnoPorAlumnoID')
	DROP PROCEDURE [dbo].[USP_U_ValidarAnioIngresopAlumnoPorAlumnoID]
GO

CREATE PROCEDURE USP_U_ValidarAnioIngresopAlumnoPorAlumnoID	
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
			EXECUTE USP_Repositorio_U_RemoverObservacionPorAlumno @I_RowID, @I_TablaID, @I_ObservID, @D_FecProceso
		END
		ELSE
		BEGIN
			IF EXISTS(SELECT C_CodModIng FROM BD_UNFV_Repositorio.dbo.TC_ModalidadIngreso WHERE C_CodModIng = @C_CodModIng)
			BEGIN
				EXECUTE USP_Repositorio_U_RemoverObservacionPorAlumno @I_RowID, @I_TablaID, @I_ObservID, @D_FecProceso
			END
			ELSE
			BEGIN
				EXECUTE USP_Repositorio_U_RegistrarObservacionPorAlumno @I_RowID, @I_TablaID, @I_ObservID, @D_FecProceso
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



IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_U_ValidarCodigoCarreraAlumnoPorAlumnoID')
	DROP PROCEDURE [dbo].[USP_U_ValidarCodigoCarreraAlumnoPorAlumnoID]
GO

CREATE PROCEDURE USP_U_ValidarCodigoCarreraAlumnoPorAlumnoID	
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
			EXECUTE USP_Repositorio_U_RemoverObservacionPorAlumno @I_RowID, @I_TablaID, @I_ObservID, @D_FecProceso
		END
		ELSE
		BEGIN
			IF EXISTS (SELECT * FROM BD_UNFV_Repositorio.dbo.TI_CarreraProfesional WHERE C_RcCod = @C_RcCod)
			BEGIN
				EXECUTE USP_Repositorio_U_RemoverObservacionPorAlumno @I_RowID, @I_TablaID, @I_ObservID, @D_FecProceso
			END
			ELSE
			BEGIN
				EXECUTE USP_Repositorio_U_RegistrarObservacionPorAlumno @I_RowID, @I_TablaID, @I_ObservID, @D_FecProceso
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



IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_U_ValidarCodigosAlumnoRemovidosPorAlumnoID')
	DROP PROCEDURE [dbo].[USP_U_ValidarCodigosAlumnoRemovidosPorAlumnoID]
GO

CREATE PROCEDURE USP_U_ValidarCodigosAlumnoRemovidosPorAlumnoID	
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
			EXECUTE USP_Repositorio_U_RemoverObservacionPorAlumno @I_RowID, @I_TablaID, @I_ObservID, @D_FecProceso
		END
		ELSE
		BEGIN
			IF (@B_Removido = 0)
			BEGIN
				EXECUTE USP_Repositorio_U_RemoverObservacionPorAlumno @I_RowID, @I_TablaID, @I_ObservID, @D_FecProceso
			END
			ELSE
			BEGIN
				EXECUTE USP_Repositorio_U_RegistrarObservacionPorAlumno @I_RowID, @I_TablaID, @I_ObservID, @D_FecProceso
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


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_U_ValidarCaracteresEspecialesPorAlumnoID')
	DROP PROCEDURE [dbo].[USP_U_ValidarCaracteresEspecialesPorAlumnoID]
GO

CREATE PROCEDURE USP_U_ValidarCaracteresEspecialesPorAlumnoID	
	@I_RowID	  int,
	@B_Resultado  bit output,
	@T_Message	  nvarchar(4000) OUTPUT	
AS
--declare @B_Resultado  bit,
--		@I_ProcedenciaID	tinyint = 3,
--		@T_Message	  nvarchar(4000)
--exec USP_U_ValidarCaracteresEspecialesPorAlumnoID @I_RowID, @B_Resultado output, @T_Message output
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
			EXECUTE USP_Repositorio_U_RemoverObservacionPorAlumno @I_RowID, @I_TablaID, @I_ObservID, @D_FecProceso
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
				EXECUTE USP_Repositorio_U_RemoverObservacionPorAlumno @I_RowID, @I_TablaID, @I_ObservID, @D_FecProceso
			END
			ELSE
			BEGIN
				EXECUTE USP_Repositorio_U_RegistrarObservacionPorAlumno @I_RowID, @I_TablaID, @I_ObservID, @D_FecProceso
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



IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_U_ValidarCodigosAlumnoRepetidosPorAlumnoID')
	DROP PROCEDURE [dbo].[USP_U_ValidarCodigosAlumnoRepetidosPorAlumnoID]
GO

CREATE PROCEDURE USP_U_ValidarCodigosAlumnoRepetidosPorAlumnoID	
	@I_RowID		 int,
	@B_Resultado  bit output,
	@T_Message	  nvarchar(4000) OUTPUT	
AS
--declare @B_Resultado  bit,
--		@I_RowID	  int = 3,
--		@T_Message	  nvarchar(4000)
--exec USP_U_ValidarCodigosAlumnoRepetidosPorAlumnoID @I_RowID, @B_Resultado output, @T_Message output
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
			EXECUTE USP_Repositorio_U_RemoverObservacionPorAlumno @I_RowID, @I_TablaID, @I_ObservID, @D_FecProceso
		END
		ELSE
		BEGIN
			SET @I_Repetidos = (SELECT COUNT(*) FROM TR_Alumnos WHERE C_CodAlu = @C_CodAlu AND C_RcCod = @C_RcCod AND B_Removido <> 1)
			
			IF (@I_Repetidos <= 1)
			BEGIN
				EXECUTE USP_Repositorio_U_RemoverObservacionPorAlumno @I_RowID, @I_TablaID, @I_ObservID, @D_FecProceso
			END
			ELSE
			BEGIN
				EXECUTE USP_Repositorio_U_RegistrarObservacionPorAlumno @I_RowID, @I_TablaID, @I_ObservID, @D_FecProceso
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


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_U_UnfvRepo_ValidarDocumentoDiferenteMismoAlumnoPorAlumnoID')
	DROP PROCEDURE [dbo].[USP_U_UnfvRepo_ValidarDocumentoDiferenteMismoAlumnoPorAlumnoID]
GO


CREATE PROCEDURE [dbo].[USP_U_UnfvRepo_ValidarDocumentoDiferenteMismoAlumnoPorAlumnoID]	
	@I_RowID	  int,
	@B_Resultado  bit output,
	@T_Message	  nvarchar(4000) OUTPUT	
AS
--declare @B_Resultado  bit,
--		@I_RowID	  int,
--		@T_Message	  nvarchar(4000)
--exec USP_U_UnfvRepo_ValidarDocumentoDiferenteMismoAlumnoPorAlumnoID @I_RowID, @B_Resultado output, @T_Message output
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
			EXECUTE USP_Repositorio_U_RemoverObservacionPorAlumno @I_RowID, @I_TablaID, @I_ObservID, @D_FecProceso
		END
		ELSE
		BEGIN
			IF(@num_dni = @num_dni_repo)
			BEGIN
				EXECUTE USP_Repositorio_U_RemoverObservacionPorAlumno @I_RowID, @I_TablaID, @I_ObservID, @D_FecProceso
			END
			ELSE
			BEGIN
				EXECUTE USP_Repositorio_U_RegistrarObservacionPorAlumno @I_RowID, @I_TablaID, @I_ObservID, @D_FecProceso
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