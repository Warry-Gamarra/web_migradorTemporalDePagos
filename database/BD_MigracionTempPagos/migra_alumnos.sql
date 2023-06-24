IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_IU_MigrarDataAlumnosUnfvRepositorio')
	DROP PROCEDURE [dbo].[USP_IU_MigrarDataAlumnosUnfvRepositorio]
GO

CREATE PROCEDURE USP_IU_MigrarDataAlumnosUnfvRepositorio
	@I_ProcedenciaID tinyint,
	@C_CodAlu	  varchar(20) = NULL,
	@C_AnioIng	  smallint = NULL,	
	@B_Resultado  bit output,
	@T_Message	  nvarchar(4000) OUTPUT	
AS
--declare @C_CodAlu  varchar(20) = null,
--		@C_AnioIng  smallint = null,
--		@I_ProcedenciaID tinyint = 3,
--		@B_Resultado  bit,
--		@T_Message	  nvarchar(4000)
--exec USP_IU_MigrarDataAlumnosUnfvRepositorio @I_ProcedenciaID, @C_CodAlu, @C_AnioIng, @B_Resultado output, @T_Message output
--select @B_Resultado as resultado, @T_Message as mensaje
BEGIN
	
	DECLARE @I_CantAlu int = 0
	DECLARE @I_Removidos int = 0
	DECLARE @I_Actualizados_persona int = 0
	DECLARE @I_Actualizados_alumno int = 0
	DECLARE @I_Insertados_persona int = 0
	DECLARE @I_Insertados_alumno int = 0
	DECLARE @D_FecProceso datetime = GETDATE() 

	BEGIN TRANSACTION
	BEGIN TRY 

		DECLARE @I_TempPersonaID int
		SET @I_TempPersonaID = IDENT_CURRENT('BD_UNFV_Repositorio.dbo.TC_Persona') 

		DECLARE @tbl_personas_repo AS TABLE (
			I_PersonaID		int,
			C_NumDNI		varchar(20),
			C_CodTipDoc		varchar(5),
			T_ApePaterno	varchar(50),
			T_ApeMaterno	varchar(50),
			T_Nombre		varchar(50),
			C_Sexo			char(1)
		)


		WITH cte_alumnos_persona_repo (I_PersonaID, C_NumDNI, C_CodTipDoc, T_ApePaterno, T_ApeMaterno, T_Nombre, C_Sexo)
		AS
		(
			SELECT	DISTINCT A.I_PersonaID, LTRIM(RTRIM(REPLACE(P.C_NumDNI,' ', ' '))) AS C_NumDNI, P.C_CodTipDoc,  
					P.T_ApePaterno, P.T_ApeMaterno, P.T_Nombre, IIF(P.C_Sexo IS NULL, TA.C_Sexo, P.C_Sexo) AS C_Sexo
			FROM	BD_UNFV_Repositorio.dbo.TC_Persona P
					INNER JOIN BD_UNFV_Repositorio.dbo.TC_Alumno A ON A.I_PersonaID = P.I_PersonaID
					INNER JOIN TR_Alumnos TA ON TA.C_CodAlu = A.C_CodAlu AND TA.C_RcCod = A.C_RcCod
		)


		INSERT INTO @tbl_personas_repo (I_PersonaID, C_NumDNI, C_CodTipDoc, T_ApePaterno, T_ApeMaterno, T_Nombre, C_Sexo)
								 SELECT I_PersonaID, C_NumDNI, C_CodTipDoc, T_ApePaterno, T_ApeMaterno, T_Nombre, C_Sexo
								   FROM cte_alumnos_persona_repo
								 ORDER BY I_PersonaID


		UPDATE P
		   SET C_NumDNI = TA.C_NumDNI
			   ,T_ApePaterno = TA.T_ApePaterno
			   ,T_ApeMaterno = TA.T_ApeMaterno
			   ,T_Nombre = TA.T_Nombre
		  FROM TR_Alumnos TA 
			   INNER JOIN BD_UNFV_Repositorio.dbo.TC_Alumno A ON TA.C_CodAlu = A.C_CodAlu AND TA.C_RcCod = A.C_RcCod
			   INNER JOIN @tbl_personas_repo P ON A.I_PersonaID = P.I_PersonaID
		 WHERE 
			   TA.B_Correcto = 1



		DECLARE @I_RowID		int, 
				@C_RcCod		varchar(3),
				@C_CodAluCur	varchar(20), 
				@C_NumDNI		varchar(20), 
				@C_CodTipDoc	varchar(5), 
				@T_ApePaterno	varchar(50), 
				@T_ApeMaterno	varchar(50), 
				@T_Nombre		varchar(50), 
				@C_Sexo			char(1), 
				@D_FecNac		date, 
				@C_CodModIng	varchar(2), 
				@C_AnioIngreso	smallint

		DECLARE cursor_alumnos_migracion CURSOR FAST_FORWARD
			FOR SELECT I_RowID, C_RcCod, C_CodAlu, C_NumDNI, C_CodTipDoc, T_ApePaterno, T_ApeMaterno, 
					   T_Nombre, C_Sexo, D_FecNac, C_CodModIng, C_AnioIngreso 
				  FROM TR_Alumnos 
				 WHERE B_Migrable = 1 
					   AND I_ProcedenciaID = @I_ProcedenciaID
					   AND C_AnioIngreso = ISNULL(@C_AnioIng, C_AnioIngreso)
					   AND C_CodAlu = ISNULL(@C_CodAlu, C_CodAlu)


		OPEN cursor_alumnos_migracion;

		FETCH NEXT FROM cursor_alumnos_migracion INTO @I_RowID, @C_RcCod, @C_CodAlu, @C_NumDNI, @C_CodTipDoc, 
													  @T_ApePaterno, @T_ApeMaterno, @T_Nombre,@C_Sexo, 
													  @D_FecNac, @C_CodModIng, @C_AnioIngreso
						
		WHILE @@FETCH_STATUS = 0
		BEGIN
			
			IF EXISTS (SELECT I_PersonaID FROM @tbl_personas_repo WHERE C_NumDNI = @C_NumDNI)
			BEGIN
				UPDATE BD_UNFV_Repositorio.dbo.TC_Persona
				   SET C_NumDNI	 = SRC.C_NumDNI,
				   	   C_CodTipDoc	 = SRC.C_CodTipDoc,
				   	   T_ApePaterno = SRC.T_ApePaterno,
				   	   T_ApeMaterno = SRC.T_ApeMaterno,
				   	   T_Nombre	 = SRC.T_Nombre,
				   	   C_Sexo		 = SRC.C_Sexo,
				   	   I_UsuarioMod = 1,
				   	   D_FecMod	 = @D_FecProceso


			END
			ELSE
			BEGIN 


			END



			FETCH NEXT FROM cursor_alumnos_migracion INTO @I_RowID, @C_RcCod, @C_CodAlu, @C_NumDNI, @C_CodTipDoc, 
														  @T_ApePaterno, @T_ApeMaterno, @T_Nombre,@C_Sexo, 
														  @D_FecNac, @C_CodModIng, @C_AnioIngreso

		END


	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION
		SET @B_Resultado = 0
		SET @T_Message = ERROR_MESSAGE() + ' LINE: ' + CAST(ERROR_LINE() AS varchar(10)) 
	END CATCH

	IF EXISTS (SELECT * FROM tempdb.INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = '##TEMP_Persona')
	BEGIN
		DROP TABLE ##TEMP_Persona
	END

	IF EXISTS (SELECT * FROM tempdb.INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = '##TEMP_AlumnoPersona')
	BEGIN
		DROP TABLE ##TEMP_AlumnoPersona
	END

END
GO