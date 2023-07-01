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
	SET NOCOUNT ON
	
	DECLARE @I_CantAlu int = 0
	DECLARE @I_Removidos int = 0
	DECLARE @I_Actualizados_persona int = 0
	DECLARE @I_Actualizados_alumno int = 0
	DECLARE @I_Insertados_persona int = 0
	DECLARE @I_Insertados_alumno int = 0
	DECLARE @D_FecProceso datetime = GETDATE() 
	DECLARE @I_UserId int = 1 

	BEGIN TRANSACTION
	BEGIN TRY 

		DECLARE @I_TempPersonaID int
		SET @I_TempPersonaID = IDENT_CURRENT('BD_UNFV_Repositorio.dbo.TC_Persona') 

		DECLARE @tbl_alumnos_persona_repo AS TABLE (
			I_PersonaID		int,
			C_NumDNI		varchar(20),
			C_CodTipDoc		varchar(5),
			T_ApePaterno	varchar(50),
			T_ApeMaterno	varchar(50),
			T_Nombre		varchar(50),
			C_Sexo			char(1),
			C_RcCod			varchar(3), 
			C_CodAlu		varchar(20), 
			C_AnioIngreso	smallint, 
			C_CodModIng		varchar(2), 
			I_RowID			int,
			D_FecNac		date,
			C_RepoCodAlu	varchar(20)
		)


		;WITH cte_alumnos_persona_repo (I_PersonaID, C_NumDNI, C_CodTipDoc, T_ApePaterno, T_ApeMaterno, T_Nombre, C_Sexo,
									   C_CodAlu, C_RcCod, C_CodModIng,I_RowID, C_AnioIngreso, D_FecNac, C_RepoCodAlu)
		AS
		(
			SELECT	A.I_PersonaID, LTRIM(RTRIM(REPLACE(ISNULL(P.C_NumDNI, TA.C_NumDNI),' ', ' '))) AS C_NumDNI, 
					ISNULL(P.C_CodTipDoc, TA.C_CodTipDoc) as C_CodTipDoc, ISNULL(P.T_ApePaterno, TA.T_ApePaterno) as T_ApePaterno, 
					ISNULL(P.T_ApeMaterno, TA.T_ApeMaterno) as T_ApeMaterno, ISNULL(P.T_Nombre, TA.T_Nombre) as T_Nombre, 
					IIF(P.C_Sexo IS NULL, TA.C_Sexo, P.C_Sexo) AS C_Sexo, TA.C_CodAlu, TA.C_RcCod, TA.C_CodModIng, TA.I_RowID, 
					ISNULL(A.C_AnioIngreso, TA.C_AnioIngreso) as C_AnioIngreso, ISNULL(P.D_FecNac, TA.D_FecNac) AS D_FecNac,
					A.C_CodAlu as C_RepoCodAlu
			FROM	BD_UNFV_Repositorio.dbo.TC_Persona P
					INNER JOIN BD_UNFV_Repositorio.dbo.TC_Alumno A ON A.I_PersonaID = P.I_PersonaID 
					RIGHT JOIN TR_Alumnos TA ON TA.C_CodAlu = A.C_CodAlu AND TA.C_RcCod = A.C_RcCod 
			WHERE   TA.B_Migrable = 1
					AND P.B_Eliminado = 0
					AND A.B_Eliminado = 0
					AND TA.I_ProcedenciaID = @I_ProcedenciaID
		)


		INSERT INTO @tbl_alumnos_persona_repo (I_PersonaID, C_NumDNI, C_CodTipDoc, T_ApePaterno, T_ApeMaterno, T_Nombre, C_Sexo,
											   C_CodAlu, C_RcCod, C_CodModIng, C_AnioIngreso, I_RowID, C_RepoCodAlu)
									    SELECT DISTINCT I_PersonaID, C_NumDNI, C_CodTipDoc, T_ApePaterno, T_ApeMaterno, T_Nombre, C_Sexo,
										 	   C_CodAlu, C_RcCod, C_CodModIng, C_AnioIngreso, I_RowID, C_RepoCodAlu
									      FROM cte_alumnos_persona_repo

		UPDATE P
		   SET C_NumDNI = TA.C_NumDNI
			   ,T_ApePaterno = TA.T_ApePaterno
			   ,T_ApeMaterno = TA.T_ApeMaterno
			   ,T_Nombre = TA.T_Nombre
			   ,C_AnioIngreso = TA.C_AnioIngreso
			   ,D_FecNac = TA.D_FecNac
		  FROM @tbl_alumnos_persona_repo P 
			   INNER JOIN TR_Alumnos TA ON TA.C_CodAlu = P.C_CodAlu AND TA.C_RcCod = P.C_RcCod
		 WHERE 
			   TA.B_Correcto = 1

		SET @I_CantAlu = (SELECT COUNT(*) FROM @tbl_alumnos_persona_repo)


		DECLARE @I_RowID		int, 
				@I_PersonaID	int,
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
				@C_AnioIngreso	smallint,
				@C_RepoCodAlu	varchar(20)

		DECLARE cursor_alumnos_migracion CURSOR FAST_FORWARD
			FOR SELECT I_RowID, C_RcCod, C_CodAlu, C_NumDNI, C_CodTipDoc, T_ApePaterno, T_ApeMaterno, 
					   T_Nombre, C_Sexo, D_FecNac, C_CodModIng, C_AnioIngreso, I_PersonaID, C_RepoCodAlu
				  FROM @tbl_alumnos_persona_repo 
				 WHERE C_AnioIngreso = ISNULL(@C_AnioIng, C_AnioIngreso)
					   AND C_CodAlu = ISNULL(@C_CodAlu, C_CodAlu)


		OPEN cursor_alumnos_migracion;

		FETCH NEXT FROM cursor_alumnos_migracion INTO @I_RowID, @C_RcCod, @C_CodAluCur, @C_NumDNI, @C_CodTipDoc, 
													  @T_ApePaterno, @T_ApeMaterno, @T_Nombre, @C_Sexo, @D_FecNac, 
													  @C_CodModIng, @C_AnioIngreso, @I_PersonaID, @C_RepoCodAlu
						
		WHILE @@FETCH_STATUS = 0
		BEGIN
			IF (@I_PersonaID IS NULL)
			BEGIN

				INSERT INTO BD_UNFV_Repositorio.dbo.TC_Persona (C_NumDNI, C_CodTipDoc, T_ApePaterno, T_ApeMaterno, T_Nombre, 
																D_FecNac, C_Sexo, B_Habilitado, B_Eliminado, I_UsuarioMod, D_FecMod)
														VALUES (@C_NumDNI, @C_CodTipDoc, @T_ApePaterno, @T_ApeMaterno, @T_Nombre,
																@D_FecNac, @C_Sexo, 1, 0, @I_UserId, @D_FecProceso)

				SET @I_PersonaID = SCOPE_IDENTITY();
				SET @I_Insertados_persona = @I_Insertados_persona + 1
			END
			ELSE
			BEGIN 

				UPDATE BD_UNFV_Repositorio.dbo.TC_Persona
				   SET C_NumDNI	 = @C_NumDNI,
				   	   C_CodTipDoc	 = @C_CodTipDoc,
				   	   T_ApePaterno = @T_ApePaterno,
				   	   T_ApeMaterno = @T_ApeMaterno,
				   	   T_Nombre	 = @T_Nombre,
				   	   C_Sexo		 = @C_Sexo,
				   	   I_UsuarioMod = @I_UserId,
				   	   D_FecMod	 = @D_FecProceso
				WHERE I_PersonaID = @I_PersonaID

				SET @I_Actualizados_persona = @I_Actualizados_persona + 1
			END

			IF (@C_RepoCodAlu IS NULL)
			BEGIN
				UPDATE BD_UNFV_Repositorio.dbo.TC_Alumno
					SET C_AnioIngreso =  ISNULL(C_AnioIngreso, @C_AnioIngreso),
						C_CodModIng = ISNULL(C_CodModIng, @C_CodModIng),
						I_UsuarioMod = @I_UserId,
						D_FecMod = @D_FecProceso
					WHERE
						C_CodAlu = @C_CodAlu 
						AND C_RcCod = @C_RcCod

				SET @I_Actualizados_alumno = @I_Actualizados_alumno + 1 
			END
			ELSE
			BEGIN 
				INSERT INTO BD_UNFV_Repositorio.dbo.TC_Alumno (C_RcCod, C_CodAlu, I_PersonaID, C_CodModIng, C_AnioIngreso, B_Habilitado, B_Eliminado, I_UsuarioMod, D_FecMod)
														VALUES (@C_RcCod, @C_CodAluCur, @I_PersonaID, @C_CodModIng, @C_AnioIngreso, 1, 0, @I_UserId, @D_FecProceso)

				SET @I_Insertados_alumno = @I_Insertados_alumno + 1
				 
			END


			UPDATE TR_Alumnos
			   SET B_Migrado = 1
			 WHERE I_RowID = @I_RowID

			PRINT  @C_RcCod + '|' + @C_CodAluCur

			FETCH NEXT FROM cursor_alumnos_migracion INTO @I_RowID, @C_RcCod, @C_CodAluCur, @C_NumDNI, @C_CodTipDoc, 
														  @T_ApePaterno, @T_ApeMaterno, @T_Nombre, @C_Sexo, @D_FecNac, 
														  @C_CodModIng, @C_AnioIngreso, @I_PersonaID,@C_RepoCodAlu
						
		END


		COMMIT TRANSACTION
		SET @B_Resultado = 1
		SET @T_Message =  'Total: ' + CAST(@I_CantAlu AS varchar) + ' | Insertados Persona: ' + CAST(@I_Insertados_persona AS varchar) + ' | Insertados Alumno: ' + CAST(@I_Insertados_alumno AS varchar)
						+ ' | Actualizados Persona: ' + CAST(@I_Actualizados_persona AS varchar) + ' | Actualizados Alumno: ' + CAST(@I_Actualizados_alumno AS varchar)

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