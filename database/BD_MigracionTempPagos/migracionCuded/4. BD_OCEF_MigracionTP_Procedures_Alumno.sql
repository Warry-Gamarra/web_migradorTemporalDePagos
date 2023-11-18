USE BD_OCEF_MigracionTP
GO


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_IU_MigrarDataAlumnosUnfvRepositorio')
	DROP PROCEDURE [dbo].[USP_IU_MigrarDataAlumnosUnfvRepositorio]
GO


CREATE PROCEDURE USP_IU_MigrarDataAlumnosUnfvRepositorio
	@I_ProcedenciaID tinyint,
	@B_Resultado  bit OUTPUT,
	@T_Message	  nvarchar(4000) OUTPUT	
AS
--declare @I_ProcedenciaID tinyint = 3,
--		@B_Resultado  bit,
--		@T_Message	  nvarchar(4000)
--exec USP_IU_MigrarDataAlumnosUnfvRepositorio @I_ProcedenciaID, @B_Resultado output, @T_Message output
--select @B_Resultado as resultado, @T_Message as mensaje
BEGIN
	PRINT 'USP_IU_MigrarDataAlumnosUnfvRepositorio'

END
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
		
	DECLARE @D_FecProceso datetime = GETDATE() 
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
			  FROM #Temp_AlumnoPersonaRepo TA 
		     WHERE BD_UNFV_Repositorio.dbo.TC_Persona.I_PersonaID = TA.I_PersonaID
				   AND TA.B_Correcto = 1

			SET @I_Actualizados_persona = @I_Actualizados_persona + @@ROWCOUNT


			PRINT 'ACTUALIZANDO DATOS EXISTENTES EN TABLA REPOSITORIO ALUMNO'
			UPDATE BD_UNFV_Repositorio.dbo.TC_Alumno
			   SET C_AnioIngreso = TA.C_AnioIngreso
				   ,I_UsuarioMod = 1
				   ,D_FecMod = @D_FecProceso
			  FROM #Temp_AlumnoPersonaRepo TA 
		     WHERE BD_UNFV_Repositorio.dbo.TC_Alumno.C_CodAlu = TA.C_CodAlu
				   AND BD_UNFV_Repositorio.dbo.TC_Alumno.C_RcCod = TA.C_RcCod
				   AND TA.B_Correcto = 1	
			
			SET @I_Actualizados_alumno = @I_Actualizados_alumno + @@ROWCOUNT


			UPDATE TR_Alumnos 
			   SET B_Migrado = 1, 
				   D_FecMigrado = @D_FecProceso
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

			SELECT TPANR.*, P.I_PersonaID 
			  INTO #Temp_PersonaAlumnosDniRepo
			  FROM #Temp_PersonaAlumnosNoRepo TPANR 
				   INNER JOIN BD_UNFV_Repositorio.dbo.TC_Persona P ON LTRIM(RTRIM(REPLACE(TPANR.C_NumDNI,' ', ' '))) = P.C_NumDNI
			 WHERE P.B_Eliminado = 0


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
				  FROM #Temp_PersonaAlumnosDniRepo TA 
				 WHERE BD_UNFV_Repositorio.dbo.TC_Persona.I_PersonaID = TA.I_PersonaID
					   AND TA.B_Correcto = 1
			
				SET @I_Actualizados_persona = @I_Actualizados_persona + @@ROWCOUNT
			

				PRINT 'AGREGANDO DATOS DE ALUMNO PARA DATOS EXISTENTES EN TABLA REPOSITORIO PERSONA.'
				INSERT INTO BD_UNFV_Repositorio.dbo.TC_Alumno(C_RcCod, C_CodAlu, I_PersonaID, C_CodModIng, C_AnioIngreso, B_Habilitado, B_Eliminado, D_FecCre)
											SELECT C_RcCod, C_CodAlu, I_PersonaID, C_CodModIng, C_AnioIngreso, 1 AS B_Habilitado , 0 AS B_Eliminado, @D_FecProceso 
											  FROM #Temp_PersonaAlumnosDniRepo 
				  
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
				   LEFT JOIN BD_UNFV_Repositorio.dbo.TC_Persona P ON LTRIM(RTRIM(REPLACE(TPANR.C_NumDNI,' ', ' '))) = P.C_NumDNI
			 WHERE P.B_Eliminado = 0
				   AND P.I_PersonaID IS NULL

			PRINT 'BUSCANDO COINCIDENCIAS POR NOMBRES...'
			SELECT A.*, VA.I_PersonaID
			  INTO #Temp_PersonaAlumnoNombreRepo
			  FROM #Temp_PersonaAlumnosNoDniRepo A
				   INNER JOIN BD_UNFV_Repositorio.dbo.VW_Alumnos VA ON ISNULL(VA.T_ApePaterno, '') COLLATE Latin1_general_CI_AI = ISNULL(LTRIM(RTRIM(REPLACE(A.T_ApePaterno,' ', ' '))), '') COLLATE Latin1_general_CI_AI 
						  AND ISNULL(VA.T_ApeMaterno, '') COLLATE Latin1_general_CI_AI = ISNULL(LTRIM(RTRIM(REPLACE(A.T_ApeMaterno,' ', ' '))), '') COLLATE Latin1_general_CI_AI 
						  AND ISNULL(VA.T_Nombre, '') COLLATE Latin1_general_CI_AI = ISNULL(LTRIM(RTRIM(REPLACE(A.T_Nombre,' ', ' '))), '') COLLATE Latin1_general_CI_AI
						  --AND ISNULL(VA.C_Sexo, '') COLLATE Latin1_general_CI_AI = ISNULL(LTRIM(RTRIM(REPLACE(A.C_Sexo,' ', ' '))), '') COLLATE Latin1_general_CI_AI 			 

			SET @Count_NombrePersona_repositorio = (SELECT COUNT(*) FROM #Temp_PersonaAlumnoNombreRepo)

			IF(@Count_NombrePersona_repositorio > 0)
			BEGIN
				PRINT 'ACTUALIZANDO COINCIDENCIAS POR NOMBRES EN TABLA PERSONAS REPOSITORIO...'

				UPDATE BD_UNFV_Repositorio.dbo.TC_Persona
				   SET C_NumDNI = TA.C_NumDNI
					   ,T_ApePaterno = TA.T_ApePaterno
					   ,T_ApeMaterno = TA.T_ApeMaterno
					   ,T_Nombre = TA.T_Nombre
				  FROM #Temp_PersonaAlumnoNombreRepo TA 
				 WHERE BD_UNFV_Repositorio.dbo.TC_Persona.I_PersonaID = TA.I_PersonaID
					   AND TA.B_Correcto = 1
				 
				SET @I_Actualizados_persona = @I_Actualizados_persona + @@ROWCOUNT


				PRINT 'AGREGANDO DATOS DE ALUMNO DE COINCIDENCIA POR NOMNBRE EN TABLA ALMUNO.'
				INSERT INTO BD_UNFV_Repositorio.dbo.TC_Alumno(C_RcCod, C_CodAlu, I_PersonaID, C_CodModIng, C_AnioIngreso, B_Habilitado, B_Eliminado, D_FecCre)
											SELECT C_RcCod, C_CodAlu, I_PersonaID, C_CodModIng, C_AnioIngreso, 1 AS B_Habilitado , 0 AS B_Eliminado, @D_FecProceso 
											  FROM #Temp_PersonaAlumnoNombreRepo 

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
				INSERT INTO BD_UNFV_Repositorio.dbo.TC_Persona (C_NumDNI, C_CodTipDoc, T_ApePaterno, T_ApeMaterno, T_Nombre, C_Sexo, D_FecNac, B_Habilitado, B_Eliminado, D_FecCre)
													  SELECT SRC.C_NUMDNI, SRC.C_CodTipDoc, SRC.T_ApePaterno, SRC.T_ApeMaterno, SRC.T_Nombre, SRC.C_Sexo, SRC.D_FecNac, 1, 0, @D_FecProceso
													  	FROM #Temp_PersonaAlumnoToRepoInsert SRC
				 
				SET @I_Insertados_persona = @I_Insertados_persona + @@ROWCOUNT


				PRINT 'AGREGANDO DATOS DE ALUMNO DE COINCIDENCIA POR NOMNBRE EN TABLA ALMUNO.'
				INSERT INTO BD_UNFV_Repositorio.dbo.TC_Alumno(C_RcCod, C_CodAlu, I_PersonaID, C_CodModIng, C_AnioIngreso, B_Habilitado, B_Eliminado, D_FecCre)
											SELECT C_RcCod, C_CodAlu, I_PersonaID, C_CodModIng, C_AnioIngreso, 1 AS B_Habilitado , 0 AS B_Eliminado, @D_FecProceso 
											  FROM #Temp_PersonaAlumnoToRepoInsert 
				  
				SET @I_Insertados_alumno = @I_Insertados_alumno + @@ROWCOUNT

				UPDATE TR_Alumnos 
				   SET B_Migrado = 1, 
					   D_FecMigrado = @D_FecProceso
				  FROM #Temp_PersonaAlumnoNombreRepo
				 WHERE TR_Alumnos.I_RowID = #Temp_PersonaAlumnoNombreRepo.I_RowID 
					   AND  #Temp_PersonaAlumnoNombreRepo.B_Migrado = 1

			END

		END

		COMMIT TRANSACTION

		SET @B_Resultado = 0
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
	@D_FecProceso	datetime,
	@B_Correcto	    bit,
	@I_TablaID		tinyint
)
AS
BEGIN
	IF (@B_Correcto = 1)
	BEGIN 	
		UPDATE BD_UNFV_Repositorio.dbo.TC_Persona 
		   SET C_NumDNI = ISNULL(TA.C_NumDNI, TC_Persona.C_NumDNI)
		   	   ,T_ApePaterno = TA.T_ApePaterno
		   	   ,T_ApeMaterno = TA.T_ApeMaterno
		   	   ,T_Nombre = TA.T_Nombre
		   	   ,D_FecMod = @D_FecProceso
		  FROM TR_Alumnos TA 
		 WHERE 
		   	TA.C_CodAlu = @C_CodAlu
		   	AND TA.B_Correcto = 1;
	END
	ELSE
	BEGIN
		UPDATE BD_UNFV_Repositorio.dbo.TC_Persona 
		   SET I_MigracionRowID = TA.I_RowID
			   ,I_MigracionTablaID = @I_TablaID
			   ,D_FecMod = @D_FecProceso
		  FROM TR_Alumnos TA 
		 WHERE 
			   TA.C_CodAlu = @C_CodAlu	
	END

	RETURN @@ROWCOUNT
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
	@I_PersonaID	int,
	@D_FecProceso	datetime,
	@B_Correcto	    bit,
	@I_TablaID		tinyint
)
AS
BEGIN
	IF (@B_Correcto = 1)
	BEGIN 		
		UPDATE BD_UNFV_Repositorio.dbo.TC_Alumno 
			SET I_PersonaID = @I_PersonaID
				,C_AnioIngreso = TA.C_AnioIngreso
				,I_UsuarioMod = 1
				,D_FecMod	 = @D_FecProceso
			FROM TR_Alumnos TA 
			WHERE 
				TA.C_CodAlu = @C_CodAlu
				AND TA.B_Correcto = 1;
	END
	ELSE
	BEGIN
		UPDATE BD_UNFV_Repositorio.dbo.TC_Alumno 
		   SET I_MigracionRowID = TA.I_RowID
			   ,I_MigracionTablaID = @I_TablaID
			   ,D_FecMod = @D_FecProceso
		  FROM TR_Alumnos TA 
		 WHERE 
			   TA.C_CodAlu = @C_CodAlu	
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
										 WHERE C_CodAlu = @C_CodAlu;

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
	
	PRINT 'INICIANDO - USP_IU_MigrarDataAlumnosPorAnio_UnfvRepositorio'

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
			EXECUTE USP_Repositorio_U_ActualizarTablaPersona @C_CodAlu, @D_FecProceso, @B_Correcto, @I_TablaID;

			PRINT 'ACTUALIZANDO ALUMNO CON COD ' + @C_CodAlu + '...'
			EXECUTE USP_Repositorio_U_ActualizarTablaAlumno @C_CodAlu, @I_PersonaID, @D_FecProceso, @B_Correcto, @I_TablaID;

		END
		ELSE
		BEGIN
			PRINT 'COD_ALU NO TIENE PERSONA RELACIONADA. VERIFICANDO EXISTENCIA DE PERSONA'
			PRINT 'POR DNI'
			SET @I_PersonaID = (SELECT I_PersonaID FROM BD_UNFV_Repositorio.dbo.TC_Persona WHERE C_NumDNI = @num_dni)

			IF (@I_PersonaID IS NOT NULL)
			BEGIN
				PRINT 'ACTUALIZANDO REGISTRO CON ID ' +  CAST(@I_PersonaID as varchar(10)) + '...'
				EXECUTE USP_Repositorio_U_ActualizarTablaPersona @C_CodAlu, @D_FecProceso, @B_Correcto, @I_TablaID;

				PRINT 'INSERTANDO ALUMNO CON COD ' + @C_CodAlu + '...'
				EXECUTE USP_Repositorio_I_InsertarTablaAlumno @C_CodAlu, @I_PersonaID, @D_FecProceso, @I_TablaID, @I_RowID;

			END
			ELSE IF EXISTS (SELECT VA.* FROM BD_UNFV_Repositorio.dbo.VW_Alumnos VA 
							INNER JOIN TR_Alumnos A ON ISNULL(VA.T_ApePaterno, '') COLLATE Latin1_general_CI_AI = ISNULL(LTRIM(RTRIM(REPLACE(A.T_ApePaterno,' ', ' '))), '') COLLATE Latin1_general_CI_AI 
													   AND ISNULL(VA.T_ApeMaterno, '') COLLATE Latin1_general_CI_AI = ISNULL(LTRIM(RTRIM(REPLACE(A.T_ApeMaterno,' ', ' '))), '') COLLATE Latin1_general_CI_AI 
													   AND ISNULL(VA.T_Nombre, '') COLLATE Latin1_general_CI_AI = ISNULL(LTRIM(RTRIM(REPLACE(A.T_Nombre,' ', ' '))), '') COLLATE Latin1_general_CI_AI
													   --AND ISNULL(VA.C_Sexo, '') COLLATE Latin1_general_CI_AI = ISNULL(LTRIM(RTRIM(REPLACE(A.C_Sexo,' ', ' '))), '') COLLATE Latin1_general_CI_AI 
							WHERE VA.C_CodAlu = @C_CodAlu
							)
			BEGIN
				PRINT 'POR NOMBRE'

				SET @I_PersonaID = (SELECT MAX(VA.I_PersonaID) FROM BD_UNFV_Repositorio.dbo.VW_Alumnos VA 
									INNER JOIN TR_Alumnos A ON ISNULL(VA.T_ApePaterno, '') COLLATE Latin1_general_CI_AI = ISNULL(LTRIM(RTRIM(REPLACE(A.T_ApePaterno,' ', ' '))), '') COLLATE Latin1_general_CI_AI 
																AND ISNULL(VA.T_ApeMaterno, '') COLLATE Latin1_general_CI_AI = ISNULL(LTRIM(RTRIM(REPLACE(A.T_ApeMaterno,' ', ' '))), '') COLLATE Latin1_general_CI_AI 
																AND ISNULL(VA.T_Nombre, '') COLLATE Latin1_general_CI_AI = ISNULL(LTRIM(RTRIM(REPLACE(A.T_Nombre,' ', ' '))), '') COLLATE Latin1_general_CI_AI
																--AND ISNULL(VA.C_Sexo, '') COLLATE Latin1_general_CI_AI = ISNULL(LTRIM(RTRIM(REPLACE(A.C_Sexo,' ', ' '))), '') COLLATE Latin1_general_CI_AI 
								   	WHERE VA.C_CodAlu = @C_CodAlu
								   )

				PRINT 'ACTUALIZANDO REGISTRO CON ID ' + CAST(@I_PersonaID as varchar(10)) + '...'
				EXECUTE USP_Repositorio_U_ActualizarTablaPersona @C_CodAlu, @D_FecProceso, @B_Correcto, @I_TablaID;

				PRINT 'INSERTANDO ALUMNO CON COD ' + @C_CodAlu + '...'
				EXECUTE USP_Repositorio_I_InsertarTablaAlumno @C_CodAlu, @I_PersonaID, @D_FecProceso, @I_TablaID, @I_RowID;

			END
			ELSE
			BEGIN
				PRINT 'PERSONA NO EXISTE EN BD_REPOSITORIO'

				PRINT 'INSERTANDO PERSONA EN BD_REPOSITORIO...'
				INSERT INTO BD_UNFV_Repositorio.dbo.TC_Persona (C_NumDNI, C_CodTipDoc, T_ApePaterno, T_ApeMaterno, T_Nombre, D_FecNac, C_Sexo, B_Habilitado, B_Eliminado, I_UsuarioCre, D_FecCre)
												SELECT ISNULL(LTRIM(RTRIM(REPLACE(C_NumDNI,' ', ' '))),  ''), C_CodTipDoc, T_ApePaterno, T_ApeMaterno, T_Nombre, D_FecNac, C_Sexo, 1, 0, 1, @D_FecProceso
												  FROM TR_Alumnos
												 WHERE C_CodAlu = @C_CodAlu

				SET @I_PersonaID = SCOPE_IDENTITY();

				PRINT 'INSERTAR ALUMNO CON COD ' + @C_CodAlu + '...'
				EXECUTE USP_Repositorio_I_InsertarTablaAlumno @C_CodAlu, @I_PersonaID, @D_FecProceso, @I_TablaID, @I_RowID;

			END
		END


		IF(@@ROWCOUNT > 0)
		BEGIN
			UPDATE TR_Alumnos 
			   SET B_Migrado = 1,
				   D_FecMigrado = @D_FecProceso
			 WHERE B_Migrable = 1 AND I_RowID = @I_RowID
		END

		SET @B_Resultado = 1
		SET @T_Message = 'Migrado:' + @C_CodAlu

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

