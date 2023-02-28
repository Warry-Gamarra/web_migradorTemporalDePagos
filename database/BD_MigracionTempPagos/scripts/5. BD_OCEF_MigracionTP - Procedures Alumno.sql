USE BD_OCEF_MigracionTP
GO


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_U_ActualizarRegistroAlumno')
	DROP PROCEDURE [dbo].[USP_U_ActualizarRegistroAlumno]
GO

CREATE PROCEDURE USP_U_ActualizarRegistroAlumno
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


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_IU_CopiarTablaAlumno')
	DROP PROCEDURE [dbo].[USP_IU_CopiarTablaAlumno]
GO

CREATE PROCEDURE USP_IU_CopiarTablaAlumno	
	@I_ProcedenciaID tinyint,
	@T_SchemaDB		 varchar(20),
	@B_Resultado  bit output,
	@T_Message	  nvarchar(4000) OUTPUT	
AS
--declare @B_Resultado  bit,
--		  @I_ProcedenciaID	tinyint = 1,
--		  @T_SchemaDB	varchar(20) = 'pregrado',
--		  @T_Message	nvarchar(4000)
--exec USP_IU_CopiarTablaAlumno @I_ProcedenciaID, @T_SchemaDB, @B_Resultado output, @T_Message output
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

CREATE PROCEDURE USP_U_ValidarCaracteresEspeciales	
	@I_ProcedenciaID tinyint,
	@B_Resultado  bit output,
	@T_Message	  nvarchar(4000) OUTPUT	
AS
--declare @B_Resultado  bit,
--		@I_ProcedenciaID	tinyint = 3,
--		@T_Message	  nvarchar(4000)
--exec USP_U_ValidarCaracteresEspeciales @I_ProcedenciaID, @B_Resultado output, @T_Message output
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


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_U_ValidarCodigosAlumnoRepetidos')
	DROP PROCEDURE [dbo].[USP_U_ValidarCodigosAlumnoRepetidos]
GO

CREATE PROCEDURE USP_U_ValidarCodigosAlumnoRepetidos	
	@I_ProcedenciaID tinyint,
	@B_Resultado  bit output,
	@T_Message	  nvarchar(4000) OUTPUT	
AS
--declare @B_Resultado  bit,
--		@I_ProcedenciaID tinyint = 3,
--		@T_Message	  nvarchar(4000)
--exec USP_U_ValidarCodigosAlumnoRepetidos @I_ProcedenciaID, @B_Resultado output, @T_Message output
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


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_U_ValidarCodigosAlumnoRemovidos')
	DROP PROCEDURE [dbo].[USP_U_ValidarCodigosAlumnoRemovidos]
GO

CREATE PROCEDURE USP_U_ValidarCodigosAlumnoRemovidos	
	@I_ProcedenciaID tinyint,
	@B_Resultado	 bit output,
	@T_Message		 nvarchar(4000) OUTPUT	
AS
--declare @B_Resultado  bit,
--		@I_ProcedenciaID tinyint = 3,
--		@T_Message	  nvarchar(4000)
--exec USP_U_ValidarCodigosAlumnoRemovidos @I_ProcedenciaID, @B_Resultado output, @T_Message output
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


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_U_ValidarCodigoCarreraAlumno')
	DROP PROCEDURE [dbo].[USP_U_ValidarCodigoCarreraAlumno]
GO

CREATE PROCEDURE USP_U_ValidarCodigoCarreraAlumno	
	@I_ProcedenciaID tinyint,
	@B_Resultado  bit output,
	@T_Message	  nvarchar(4000) OUTPUT	
AS
--declare @B_Resultado  bit,
--		@I_ProcedenciaID tinyint = 3,
--		@T_Message	  nvarchar(4000)
--exec USP_U_ValidarCodigoCarreraAlumno @I_ProcedenciaID, @B_Resultado output, @T_Message output
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


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_U_ValidarAnioIngresoAlumno')
	DROP PROCEDURE [dbo].[USP_U_ValidarAnioIngresoAlumno]
GO

CREATE PROCEDURE USP_U_ValidarAnioIngresoAlumno	
	@I_ProcedenciaID tinyint,
	@B_Resultado  bit output,
	@T_Message	  nvarchar(4000) OUTPUT	
AS
--declare @B_Resultado  bit,
--		@I_ProcedenciaID tinyint = 3,
--		@T_Message	  nvarchar(4000)
--exec USP_U_ValidarAnioIngresoAlumno @I_ProcedenciaID, @B_Resultado output, @T_Message output
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


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_U_ValidarModalidadIngresoAlumno')
	DROP PROCEDURE [dbo].[USP_U_ValidarModalidadIngresoAlumno]
GO

CREATE PROCEDURE USP_U_ValidarModalidadIngresoAlumno	
	@I_ProcedenciaID tinyint,
	@B_Resultado  bit output,
	@T_Message	  nvarchar(4000) OUTPUT	
AS
--declare @B_Resultado  bit,
--		@I_ProcedenciaID tinyint = 3,
--		@T_Message	  nvarchar(4000)
--exec USP_U_ValidarModalidadIngresoAlumno @I_ProcedenciaID, @B_Resultado output, @T_Message output
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


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_U_ValidarTipoDocumentoIdentidadAlumno')
	DROP PROCEDURE [dbo].[USP_U_ValidarTipoDocumentoIdentidadAlumno]
GO

CREATE PROCEDURE USP_U_ValidarTipoDocumentoIdentidadAlumno	
	@I_ProcedenciaID tinyint,
	@B_Resultado  bit output,
	@T_Message	  nvarchar(4000) OUTPUT	
AS
--declare @B_Resultado  bit,
--		@I_ProcedenciaID tinyint = 3,
--		@T_Message	  nvarchar(4000)
--exec USP_U_ValidarTipoDocumentoIdentidadAlumno @I_ProcedenciaID, @B_Resultado output, @T_Message output
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
		WHEN NOT MATCHED BY SOURCE AND TRG.I_ObservID = @I_ObservID AND TRG.I_ProcedenciaID = @I_ProcedenciaID THEN
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


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_U_ValidarCorrespondenciaNumDocumentoPersona')
	DROP PROCEDURE [dbo].[USP_U_ValidarCorrespondenciaNumDocumentoPersona]
GO

CREATE PROCEDURE USP_U_ValidarCorrespondenciaNumDocumentoPersona	
	@I_ProcedenciaID tinyint,
	@B_Resultado  bit output,
	@T_Message	  nvarchar(4000) OUTPUT	
AS
--declare @B_Resultado  bit,
--		@I_ProcedenciaID tinyint = 3,
--		@T_Message	  nvarchar(4000)
--exec USP_U_ValidarCorrespondenciaNumDocumentoPersona @I_ProcedenciaID, @B_Resultado output, @T_Message output
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


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_U_ValidarCorrespondenciaNumDocRepositorioPersona')
	DROP PROCEDURE [dbo].[USP_U_ValidarCorrespondenciaNumDocRepositorioPersona]
GO

CREATE PROCEDURE USP_U_ValidarCorrespondenciaNumDocRepositorioPersona	
	@I_ProcedenciaID tinyint,
	@B_Resultado  bit output,
	@T_Message	  nvarchar(4000) OUTPUT	
AS
--declare @B_Resultado  bit,
--		@I_ProcedenciaID tinyint = 3,
--		@T_Message	  nvarchar(4000)
--exec USP_U_ValidarCorrespondenciaNumDocRepositorioPersona @I_ProcedenciaID, @B_Resultado output, @T_Message output
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


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_U_ValidarSexoDiferenteMismoDocumento')
	DROP PROCEDURE [dbo].[USP_U_ValidarSexoDiferenteMismoDocumento]
GO

CREATE PROCEDURE USP_U_ValidarSexoDiferenteMismoDocumento	
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



IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_U_UnfvRepo_ValidarSexoDiferenteMismoDocumento')
	DROP PROCEDURE [dbo].[USP_U_UnfvRepo_ValidarSexoDiferenteMismoDocumento]
GO

CREATE PROCEDURE USP_U_UnfvRepo_ValidarSexoDiferenteMismoDocumento	
	@I_ProcedenciaID tinyint,
	@B_Resultado  bit output,
	@T_Message	  nvarchar(4000) OUTPUT	
AS
--declare @B_Resultado  bit,
--		@I_ProcedenciaID tinyint = 1,
--		@T_Message	  nvarchar(4000)
--exec USP_U_UnfvRepo_ValidarSexoDiferenteMismoDocumento @I_ProcedenciaID, @B_Resultado output, @T_Message output
--select @B_Resultado as resultado, @T_Message as mensaje
BEGIN
	DECLARE @I_Observados int = 0
	DECLARE @D_FecProceso datetime = GETDATE() 
	DECLARE @I_ObservID int = 47
	DECLARE @I_TablaID int = 1


	IF EXISTS (SELECT * FROM tempdb.INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = '##TEMP_Persona')
	BEGIN
		DROP TABLE ##TEMP_Persona
	END 

	CREATE TABLE ##TEMP_Persona (
		I_AlumnoRowID	int,
		C_NumDNI		varchar(20),
		C_CodTipDoc		varchar(5),
		T_ApePaterno	varchar(50),
		T_ApeMaterno	varchar(50),
		T_Nombre		varchar(50),
		C_Sexo			char(1)
	)	
	
	
	BEGIN TRANSACTION
	BEGIN TRY

		INSERT INTO ##TEMP_Persona (I_AlumnoRowID, C_NumDNI, C_CodTipDoc, T_ApePaterno, T_ApeMaterno, T_Nombre, C_Sexo)
		SELECT	DISTINCT TA.I_RowID, LTRIM(RTRIM(REPLACE(P.C_NumDNI,' ', ' '))), P.C_CodTipDoc, P.T_ApePaterno, P.T_ApeMaterno, P.T_Nombre, 
				IIF(P.C_Sexo IS NULL, TA.C_Sexo, P.C_Sexo)
		FROM	BD_UNFV_Repositorio.dbo.TC_Alumno A 
				INNER JOIN BD_UNFV_Repositorio.dbo.TC_Persona P ON A.I_PersonaID = P.I_PersonaID
				INNER JOIN TR_Alumnos TA ON TA.C_CodAlu = A.C_CodAlu AND TA.C_RcCod = A.C_RcCod
		WHERE	P.B_Eliminado = 0 
				AND A.B_Eliminado = 0
				AND I_ProcedenciaID = @I_ProcedenciaID
		ORDER BY TA.I_RowID
		

		IF EXISTS (SELECT * FROM tempdb.INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = '##NumDoc_Repetidos_sexo_diferente')
		BEGIN
			DROP TABLE ##NumDoc_Repetidos_sexo_diferente
		END 

		SELECT I_AlumnoRowID, C_NumDNI, C_CodTipDoc, T_ApePaterno, T_ApeMaterno, T_Nombre, C_Sexo
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
		ORDER BY T_ApePaterno, T_ApeMaterno

		---
		INSERT INTO ##NumDoc_Repetidos_sexo_diferente (I_AlumnoRowID, C_NumDNI, C_CodTipDoc, T_ApePaterno, T_ApeMaterno, T_Nombre, C_Sexo)
		SELECT TP.I_AlumnoRowID, TP.C_NumDNI, TP.C_CodTipDoc, TP.T_ApePaterno, TP.T_ApeMaterno, TP.T_Nombre, TP.C_Sexo
		  FROM ##TEMP_Persona TP
			   LEFT JOIN ##NumDoc_Repetidos_sexo_diferente NDR ON ISNULL(NDR.T_ApePaterno, '') COLLATE Latin1_general_CI_AI = ISNULL(TP.T_ApePaterno, '') COLLATE Latin1_general_CI_AI
																  AND ISNULL(NDR.T_ApeMaterno, '') COLLATE Latin1_general_CI_AI = ISNULL(TP.T_ApeMaterno, '') COLLATE Latin1_general_CI_AI
																  AND ISNULL(NDR.T_Nombre, '') COLLATE Latin1_general_CI_AI = ISNULL(TP.T_Nombre, '') COLLATE Latin1_general_CI_AI
																  AND ISNULL(NDR.C_Sexo, '') COLLATE Latin1_general_CI_AI = ISNULL(TP.C_Sexo, '') COLLATE Latin1_general_CI_AI
		WHERE EXISTS (SELECT * FROM (SELECT TP1.T_ApePaterno, TP1.T_ApeMaterno, TP1.T_Nombre, COUNT(*) R
									   FROM ##TEMP_Persona TP1				
									 GROUP BY TP1.T_ApePaterno, TP1.T_ApeMaterno, TP1.T_Nombre 
									 HAVING COUNT(*) > 1) TP2
					   WHERE NOT EXISTS (SELECT T_ApePaterno, T_ApeMaterno, T_Nombre, C_Sexo, COUNT(*) R FROM ##TEMP_Persona
										 WHERE TP2.T_ApePaterno = T_ApePaterno 
											   AND TP2.T_ApeMaterno = T_ApeMaterno 
											   AND TP2.T_Nombre = T_Nombre
					   					 GROUP BY T_ApePaterno, T_ApeMaterno, T_Nombre , C_Sexo
										 HAVING COUNT(*) > 1
										)
							 AND TP.T_ApePaterno =  TP2.T_ApePaterno
							 AND TP.T_ApeMaterno =  TP2.T_ApeMaterno
							 AND TP.T_Nombre =  TP2.T_Nombre
					 )
			  AND NDR.I_AlumnoRowID IS NULL	
		ORDER BY T_ApePaterno, T_ApeMaterno, T_Nombre
		--

		UPDATE	TR_Alumnos
		SET		B_Migrable = 0,
				D_FecEvalua = @D_FecProceso
		WHERE	EXISTS (SELECT * FROM ##NumDoc_Repetidos_sexo_diferente WHERE I_AlumnoRowID = TR_Alumnos.I_RowID)
				AND I_ProcedenciaID = @I_ProcedenciaID
				AND ISNULL(B_Correcto, 0) <> 1

		MERGE TI_ObservacionRegistroTabla AS TRG
		USING 	(SELECT	@I_ObservID AS I_ObservID, @I_TablaID AS I_TablaID, I_RowID AS I_FilaTablaID, @D_FecProceso AS D_FecRegistro FROM TR_Alumnos
				  WHERE	EXISTS (SELECT * FROM ##NumDoc_Repetidos_sexo_diferente WHERE I_AlumnoRowID = TR_Alumnos.I_RowID)
						AND I_ProcedenciaID = @I_ProcedenciaID
						AND ISNULL(B_Correcto, 0) <> 1) AS SRC
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

	--IF EXISTS (SELECT * FROM tempdb.INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = '##NumDoc_Repetidos_sexo_diferente')
	--BEGIN
	--	DROP TABLE ##NumDoc_Repetidos_sexo_diferente
	--END 
	--	IF EXISTS (SELECT * FROM tempdb.INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = '##TEMP_Persona')
	--BEGIN
	--	DROP TABLE ##TEMP_Persona
	--END
END
GO


USE BD_OCEF_MigracionTP
GO

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
--		@I_ProcedenciaID tinyint = 1,
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

	CREATE TABLE #Tbl_output_persona  
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
		I_PersonaID		int,
		B_Removido		bit
	)

	CREATE TABLE #Tbl_output_alumno  
	(
		accion			  varchar(20), 
		C_RcCod			  varchar(3), 
		C_CodAlu		  varchar(20), 
		C_AnioIngreso smallint, 
		C_CodModIng	  varchar(2), 
		INS_I_PersonaID	  int, 
		DEL_I_PersonaID	  int, 
		B_Removido		  bit
	)

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
	)

	DECLARE @tbl_personas AS TABLE (
		I_PersonaID		int,
		C_NumDNI		varchar(20),
		C_CodTipDoc		varchar(5),
		T_ApePaterno	varchar(50),
		T_ApeMaterno	varchar(50),
		T_Nombre		varchar(50),
		C_Sexo			char(1)
	)

	DECLARE @tbl_personas2 AS TABLE (
		I_PersonaID		int,
		C_NumDNI		varchar(20),
		C_CodTipDoc		varchar(5),
		T_ApePaterno	varchar(50),
		T_ApeMaterno	varchar(50),
		T_Nombre		varchar(50),
		C_Sexo			char(1)
	)

	BEGIN TRANSACTION
	BEGIN TRY 
		DECLARE @I_TempPersonaID int
		SET @I_TempPersonaID = IDENT_CURRENT('BD_UNFV_Repositorio.dbo.TC_Persona') 


		;WITH cte_alumnos_persona_codalu (I_PersonaID, C_NumDNI, C_CodTipDoc, T_ApePaterno, T_ApeMaterno, T_Nombre, C_Sexo)
		AS
		(
			SELECT	DISTINCT A.I_PersonaID, LTRIM(RTRIM(REPLACE(P.C_NumDNI,' ', ' '))) AS C_NumDNI, P.C_CodTipDoc,  
					P.T_ApePaterno, P.T_ApeMaterno, P.T_Nombre, IIF(P.C_Sexo IS NULL, TA.C_Sexo, P.C_Sexo) AS C_Sexo
			FROM	BD_UNFV_Repositorio.dbo.TC_Persona P
					INNER JOIN BD_UNFV_Repositorio.dbo.TC_Alumno A ON A.I_PersonaID = P.I_PersonaID
					INNER JOIN TR_Alumnos TA ON TA.C_CodAlu = A.C_CodAlu AND TA.C_RcCod = A.C_RcCod
			WHERE	A.C_CodAlu = ISNULL(@C_CodAlu, A.C_CodAlu) 
					AND ISNULL(A.C_AnioIngreso, '') = ISNULL(@C_AnioIng, ISNULL(A.C_AnioIngreso, ''))
					AND P.B_Eliminado = 0 
					AND A.B_Eliminado = 0
		)

		INSERT INTO @tbl_personas (I_PersonaID, C_NumDNI, C_CodTipDoc, T_ApePaterno, T_ApeMaterno, T_Nombre, C_Sexo)
							SELECT I_PersonaID, C_NumDNI, C_CodTipDoc, T_ApePaterno, T_ApeMaterno, T_Nombre, C_Sexo
							  FROM cte_alumnos_persona_codalu
							ORDER BY I_PersonaID

		select * from @tbl_personas
		ORDER BY I_PersonaID

		;WITH cte_alumnos_persona_numdoc(I_PersonaID, C_NumDNI, C_CodTipDoc, T_ApePaterno, T_ApeMaterno, T_Nombre, C_Sexo)
		AS
		(
			SELECT	DISTINCT A.I_PersonaID, LTRIM(RTRIM(REPLACE(P.C_NumDNI,' ', ' '))) AS C_NumDNI, P.C_CodTipDoc,  
					P.T_ApePaterno, P.T_ApeMaterno, P.T_Nombre, IIF(P.C_Sexo IS NULL, TA.C_Sexo, P.C_Sexo) AS C_Sexo
			FROM	BD_UNFV_Repositorio.dbo.TC_Alumno A 
					INNER JOIN BD_UNFV_Repositorio.dbo.TC_Persona P ON A.I_PersonaID = P.I_PersonaID
					INNER JOIN TR_Alumnos TA ON TA.C_NumDNI = P.C_NumDNI
			WHERE	A.C_CodAlu = ISNULL(@C_CodAlu, A.C_CodAlu) 
					AND ISNULL(A.C_AnioIngreso, '') = ISNULL(@C_AnioIng, ISNULL(A.C_AnioIngreso, ''))
					AND P.B_Eliminado = 0 
					AND A.B_Eliminado = 0
		)

		INSERT INTO @tbl_personas (I_PersonaID, C_NumDNI, C_CodTipDoc, T_ApePaterno, T_ApeMaterno, T_Nombre, C_Sexo)
							SELECT CAP.I_PersonaID, CAP.C_NumDNI, CAP.C_CodTipDoc, CAP.T_ApePaterno, CAP.T_ApeMaterno, CAP.T_Nombre, CAP.C_Sexo
							  FROM cte_alumnos_persona_numdoc CAP
							       LEFT JOIN @tbl_personas TP ON CAP.I_PersonaID = TP.I_PersonaID
							 WHERE TP.I_PersonaID IS NULL


		;WITH cte_alumnos_no_persona (C_RcCod, C_CodAlu, C_NumDNI, C_CodTipDoc, T_ApePaterno, T_ApeMaterno, T_Nombre, I_ProcedenciaID, 
									  C_Sexo, D_FecNac, C_CodModIng, C_AnioIngreso, D_FecCarga, B_Migrado, B_Migrable)
		AS
		(SELECT AL.C_RcCod, AL.C_CodAlu, AL.C_NumDNI, AL.C_CodTipDoc, AL.T_ApePaterno, AL.T_ApeMaterno, AL.T_Nombre, AL.I_ProcedenciaID, 
				AL.C_Sexo, AL.D_FecNac, AL.C_CodModIng, AL.C_AnioIngreso, AL.D_FecCarga, AL.B_Migrado, AL.B_Migrable				
		   FROM TR_Alumnos AL
				LEFT JOIN @tbl_personas TP ON ISNULL(LTRIM(RTRIM(REPLACE(AL.C_NumDNI,' ', ' '))), '') COLLATE Latin1_general_CI_AI = ISNULL(LTRIM(RTRIM(REPLACE(TP.C_NumDNI,' ', ' '))), '') COLLATE Latin1_general_CI_AI 
						  AND ISNULL(LTRIM(RTRIM(REPLACE(AL.T_ApePaterno,' ', ' '))), '') COLLATE Latin1_general_CI_AI = ISNULL(LTRIM(RTRIM(REPLACE(TP.T_ApePaterno,' ', ' '))), '') COLLATE Latin1_general_CI_AI 
						  AND ISNULL(LTRIM(RTRIM(REPLACE(AL.T_ApeMaterno,' ', ' '))), '') COLLATE Latin1_general_CI_AI = ISNULL(LTRIM(RTRIM(REPLACE(TP.T_ApeMaterno,' ', ' '))), '') COLLATE Latin1_general_CI_AI 
						  AND ISNULL(LTRIM(RTRIM(REPLACE(AL.T_Nombre,' ', ' '))), '') COLLATE Latin1_general_CI_AI = ISNULL(LTRIM(RTRIM(REPLACE(TP.T_Nombre,' ', ' '))), '') COLLATE Latin1_general_CI_AI
						  AND ISNULL(LTRIM(RTRIM(REPLACE(AL.C_Sexo,' ', ' '))), '') COLLATE Latin1_general_CI_AI = ISNULL(LTRIM(RTRIM(REPLACE(TP.C_Sexo,' ', ' '))), '') COLLATE Latin1_general_CI_AI 
		  WHERE TP.I_PersonaID IS NULL
				AND AL.I_ProcedenciaID = @I_ProcedenciaID
		)
		
		INSERT INTO @tbl_personas2 (C_NumDNI, C_CodTipDoc, T_ApePaterno, T_ApeMaterno, T_Nombre, C_Sexo)
		SELECT DISTINCT LTRIM(RTRIM(REPLACE(TA.C_NumDNI,' ', ' '))) AS C_NumDNI, 
				IIF(TA.C_CodTipDoc IS NULL, IIF(LEN(TA.C_NumDNI) = 8, 'DI', NULL), IIF(TA.C_NumDNI IS NULL, NULL,TA.C_CodTipDoc)) AS C_CodTipDoc, 
				LTRIM(RTRIM(TA.T_ApePaterno)) COLLATE Latin1_general_CI_AI AS T_ApePaterno, 
				LTRIM(RTRIM(TA.T_ApeMaterno)) COLLATE Latin1_general_CI_AI AS T_ApeMaterno, 
				LTRIM(RTRIM(TA.T_Nombre)) COLLATE Latin1_general_CI_AI AS T_Nombre, C_Sexo	
		FROM    cte_alumnos_no_persona TA 
		WHERE	TA.B_Migrable = 1
				AND I_ProcedenciaID = @I_ProcedenciaID
		ORDER BY 1


		SET IDENTITY_INSERT ##TEMP_Persona ON

		INSERT INTO ##TEMP_Persona (I_PersonaID, C_NumDNI, C_CodTipDoc, T_ApePaterno, T_ApeMaterno, T_Nombre, C_Sexo)
							 SELECT I_PersonaID, C_NumDNI, C_CodTipDoc, T_ApePaterno, T_ApeMaterno, T_Nombre, C_Sexo
							   FROM @tbl_personas

		UPDATE ##TEMP_Persona
		   SET T_ApePaterno = T2.T_ApePaterno,
			   T_ApeMaterno = T2.T_ApeMaterno,
			   T_Nombre = T2.T_Nombre,
			   C_Sexo = T2.C_Sexo
		  FROM @tbl_personas2 T2
		 WHERE ##TEMP_Persona.C_NumDNI = T2.C_NumDNI

		DELETE  @tbl_personas2
		 WHERE  C_NumDNI IN (SELECT	T2.C_NumDNI
							   FROM	@tbl_personas2 T2
									INNER JOIN @tbl_personas T1 ON T2.C_NumDNI = T1.C_NumDNI)

		select * from @tbl_personas2

				
		INSERT INTO ##TEMP_Persona (I_PersonaID, C_NumDNI, C_CodTipDoc, T_ApePaterno, T_ApeMaterno, T_Nombre, C_Sexo)
							SELECT (@I_TempPersonaID + ROW_NUMBER() OVER(ORDER BY T2.T_ApePaterno)) AS I_PersonaID, 
									T2.C_NumDNI, T2.C_CodTipDoc, T2.T_ApePaterno, T2.T_ApeMaterno, T2.T_Nombre, T2.C_Sexo
							FROM	@tbl_personas2 T2
							WHERE   NOT EXISTS (SELECT I_PersonaID FROM BD_UNFV_Repositorio.dbo.TC_Persona T1 
												 WHERE ISNULL(T2.T_ApePaterno, '') COLLATE Latin1_general_CI_AI = ISNULL(T1.T_ApePaterno, '') COLLATE Latin1_general_CI_AI 
													   AND ISNULL(T2.T_ApeMaterno, '') COLLATE Latin1_general_CI_AI = ISNULL(T1.T_ApeMaterno, '') COLLATE Latin1_general_CI_AI 
													   AND ISNULL(T2.T_Nombre, '') COLLATE Latin1_general_CI_AI = ISNULL(T1.T_Nombre, '') COLLATE Latin1_general_CI_AI
													   AND ISNULL(T2.C_Sexo, '') COLLATE Latin1_general_CI_AI = ISNULL(T1.C_Sexo, '') COLLATE Latin1_general_CI_AI
												)
									AND NOT EXISTS (SELECT * FROM @tbl_personas2 TP
													WHERE EXISTS (SELECT TP1.T_ApePaterno, TP1.T_ApeMaterno, TP1.T_Nombre, COUNT(*) FROM @tbl_personas2 TP1				
																  GROUP BY TP1.T_ApePaterno, TP1.T_ApeMaterno, TP1.T_Nombre 
																  HAVING COUNT(*) > 1
																		 AND TP.T_ApePaterno =  TP1.T_ApePaterno
																		 AND TP.T_ApeMaterno =  TP1.T_ApeMaterno
																		 AND TP.T_Nombre =  TP1.T_Nombre
																  )
														AND TP.C_NumDNI IS NULL
														AND T2.T_ApePaterno =  TP.T_ApePaterno
														AND T2.T_ApeMaterno =  TP.T_ApeMaterno
														AND T2.T_Nombre =  TP.T_Nombre
													)

		SET IDENTITY_INSERT ##TEMP_Persona OFF

		SELECT * FROM ##TEMP_Persona


		--SET IDENTITY_INSERT BD_UNFV_Repositorio.dbo.TC_Persona ON

		--MERGE BD_UNFV_Repositorio.dbo.TC_Persona AS TRG
		--USING (SELECT DISTINCT  AP.I_PersonaID, AP.C_NumDNI, AP.C_CodTipDoc, AP.T_ApePaterno, AP.T_ApeMaterno, AP.T_Nombre,
		--						AP.C_Sexo, NULL AS D_FecNac, 1 AS B_Migrado
		--	   FROM ##TEMP_Persona AP) AS SRC
		--ON TRG.I_PersonaID = SRC.I_PersonaID
		--WHEN MATCHED AND SRC.B_Migrado = 0 THEN
		--	UPDATE SET	TRG.C_NumDNI	 = SRC.C_NumDNI,
		--				TRG.C_CodTipDoc	 = SRC.C_CodTipDoc,
		--				TRG.T_ApePaterno = SRC.T_ApePaterno,
		--				TRG.T_ApeMaterno = SRC.T_ApeMaterno,
		--				TRG.T_Nombre	 = SRC.T_Nombre,
		--				TRG.C_Sexo		 = SRC.C_Sexo,
		--				TRG.I_UsuarioMod = 1,
		--				TRG.D_FecMod	 = @D_FecProceso
		--WHEN NOT MATCHED BY TARGET THEN
		--	INSERT (I_PersonaID, C_NumDNI, C_CodTipDoc, T_ApePaterno, T_ApeMaterno, T_Nombre, C_Sexo, D_FecNac, B_Habilitado, B_Eliminado, D_FecCre)
		--	VALUES (SRC.I_PersonaID,SRC.C_NUMDNI, SRC.C_CodTipDoc, SRC.T_ApePaterno, SRC.T_ApeMaterno, SRC.T_Nombre, SRC.C_Sexo, SRC.D_FecNac, 1, 0, @D_FecProceso)
		--OUTPUT	$ACTION, inserted.C_NumDNI, inserted.C_CodTipDoc, inserted.T_ApePaterno, inserted.T_ApeMaterno, inserted.T_Nombre, 
		--		inserted.C_Sexo, inserted.D_FecNac, deleted.C_NumDNI, deleted.C_CodTipDoc, deleted.T_ApePaterno, deleted.T_ApeMaterno, 
		--		deleted.T_Nombre, deleted.C_Sexo, deleted.D_FecNac, inserted.I_PersonaID, 0 INTO #Tbl_output_persona;		
		
		--SET IDENTITY_INSERT BD_UNFV_Repositorio.dbo.TC_Persona OFF

		
		INSERT INTO ##TEMP_AlumnoPersona (I_PersonaID, C_RcCod, C_CodAlu, C_CodModIng, C_AnioIngreso, B_Migrado)
		SELECT A.I_PersonaID, A.C_RcCod, A.C_CodAlu, A.C_CodModIng, IIF(A.C_AnioIngreso IS NULL, TA.C_AnioIngreso, A.C_AnioIngreso), 1 AS B_Migrado
		FROM   BD_UNFV_Repositorio.dbo.TC_Alumno A 
			   INNER JOIN (SELECT * FROM TR_Alumnos WHERE B_Migrable = 1) TA ON TA.C_CodAlu = A.C_CodAlu AND TA.C_RcCod = A.C_RcCod
		WHERE  TA.I_ProcedenciaID = @I_ProcedenciaID
		UNION
		SELECT TA.I_PersonaID, TA.C_RcCod, TA.C_CodAlu, TA.C_CodModIng, TA.C_AnioIngreso, TA.B_Migrado
		FROM   BD_UNFV_Repositorio.dbo.TC_Alumno A 
			   RIGHT JOIN (SELECT TP.I_PersonaID, AL.C_RcCod, AL.C_CodAlu, AL.C_CodModIng, AL.C_AnioIngreso, AL.B_Migrado, AL.I_ProcedenciaID
							 FROM TR_Alumnos AL
								  INNER JOIN ##TEMP_Persona TP ON ISNULL(LTRIM(RTRIM(REPLACE(AL.C_NumDNI,' ', ' '))), '') COLLATE Latin1_general_CI_AI = ISNULL(LTRIM(RTRIM(REPLACE(TP.C_NumDNI,' ', ' '))), '') COLLATE Latin1_general_CI_AI 
											AND AL.T_ApePaterno COLLATE Latin1_general_CI_AI = TP.T_ApePaterno COLLATE Latin1_general_CI_AI 
											AND AL.T_ApeMaterno COLLATE Latin1_general_CI_AI = TP.T_ApeMaterno COLLATE Latin1_general_CI_AI 
											AND AL.T_Nombre COLLATE Latin1_general_CI_AI = TP.T_Nombre COLLATE Latin1_general_CI_AI
											AND ISNULL(AL.C_Sexo, '') COLLATE Latin1_general_CI_AI = ISNULL(TP.C_Sexo, '') COLLATE Latin1_general_CI_AI 
						    WHERE B_Migrable = 1
							UNION
							SELECT TP.I_PersonaID, AL.C_RcCod, AL.C_CodAlu, AL.C_CodModIng, AL.C_AnioIngreso, AL.B_Migrado, AL.I_ProcedenciaID
							 FROM TR_Alumnos AL
								  INNER JOIN ##TEMP_Persona TP ON AL.T_ApePaterno COLLATE Latin1_general_CI_AI = TP.T_ApePaterno COLLATE Latin1_general_CI_AI 
											AND AL.T_ApeMaterno COLLATE Latin1_general_CI_AI = TP.T_ApeMaterno COLLATE Latin1_general_CI_AI 
											AND AL.T_Nombre COLLATE Latin1_general_CI_AI = TP.T_Nombre COLLATE Latin1_general_CI_AI
											AND ISNULL(AL.C_Sexo, '') COLLATE Latin1_general_CI_AI = ISNULL(TP.C_Sexo, '') COLLATE Latin1_general_CI_AI 
						    WHERE B_Migrable = 1
							) TA ON TA.C_CodAlu = A.C_CodAlu AND TA.C_RcCod = A.C_RcCod
		WHERE  A.I_PersonaID IS NULL
			   AND TA.I_ProcedenciaID = @I_ProcedenciaID
			  
		SELECT * FROM ##TEMP_AlumnoPersona

		--MERGE BD_UNFV_Repositorio.dbo.TC_Alumno AS TRG
		--USING (SELECT DISTINCT AP.I_PersonaID, AP.C_RcCod, AP.C_CodAlu, AP.C_CodModIng, AP.C_AnioIngreso, AP.B_Migrado 
		--		FROM ##TEMP_AlumnoPersona AP) AS SRC
		--ON	TRG.C_RcCod COLLATE Latin1_general_CI_AI = SRC.C_RcCod COLLATE Latin1_general_CI_AI 
		--	AND TRG.C_CodAlu COLLATE Latin1_general_CI_AI = SRC.C_CodAlu COLLATE Latin1_general_CI_AI 
		--	AND ISNULL(TRG.C_CodModIng, '')	COLLATE Latin1_general_CI_AI = ISNULL(SRC.C_CodModIng, '') COLLATE Latin1_general_CI_AI
		--WHEN MATCHED AND SRC.B_Migrado = 0 THEN
		--	UPDATE SET	TRG.I_PersonaID	 = SRC.I_PersonaID,
		--				TRG.C_AnioIngreso = SRC.C_AnioIngreso,	
		--				TRG.I_UsuarioMod = 1,
		--				TRG.D_FecMod	 = @D_FecProceso
		--WHEN NOT MATCHED BY TARGET THEN
		--	INSERT (C_RcCod, C_CodAlu, I_PersonaID, C_CodModIng, C_AnioIngreso, B_Habilitado, B_Eliminado, D_FecCre)
		--	VALUES (SRC.C_RcCod, SRC.C_CodAlu, SRC.I_PersonaID, SRC.C_CodModIng, SRC.C_AnioIngreso, 1, 0, @D_FecProceso)
		--OUTPUT	$ACTION, inserted.C_RcCod, inserted.C_CodAlu, inserted.C_AnioIngreso, inserted.C_CodModIng, 
		--		inserted.I_PersonaID, deleted.I_PersonaID, 0 INTO #Tbl_output_alumno;		

		--UPDATE	t_Alumnos
		--SET		t_Alumnos.B_Migrado = 1,
		--		t_Alumnos.D_FecMigrado = @D_FecProceso
		--FROM TR_Alumnos AS t_Alumnos
		--	 INNER JOIN 	#Tbl_output_alumno as t_out_a ON t_out_a.C_RcCod = t_Alumnos.C_RcCod AND t_out_a.C_CodAlu COLLATE Latin1_general_CI_AI = t_Alumnos.C_CodAlu COLLATE Latin1_general_CI_AI 
		--	 			AND ISNULL(t_out_a.C_CodModIng, '') COLLATE Latin1_general_CI_AI  = ISNULL(t_Alumnos.C_CodModIng, '') COLLATE Latin1_general_CI_AI 
		--	 INNER JOIN 	#Tbl_output_persona as t_out_p ON t_out_p.I_PersonaID = t_out_a.INS_I_PersonaID


		SET @I_CantAlu = (SELECT COUNT(*) FROM ##TEMP_AlumnoPersona AP 
											   INNER JOIN TR_Alumnos A ON AP.C_CodAlu COLLATE Latin1_general_CI_AI = A.C_CodAlu COLLATE Latin1_general_CI_AI 
																	      AND AP.C_RcCod COLLATE Latin1_general_CI_AI = A.C_RcCod COLLATE Latin1_general_CI_AI 
																		  AND A.B_Migrable = 1)

		SET @I_Insertados_persona = (SELECT COUNT(*) FROM #Tbl_output_persona WHERE accion = 'INSERT')
		SET @I_Insertados_alumno = (SELECT COUNT(*) FROM #Tbl_output_alumno WHERE accion = 'INSERT')
		SET @I_Actualizados_persona = (SELECT COUNT(*) FROM #Tbl_output_persona WHERE accion = 'UPDATE' AND B_Removido = 0)
		SET @I_Actualizados_alumno = (SELECT COUNT(*) FROM #Tbl_output_alumno WHERE accion = 'UPDATE' AND B_Removido = 0)
		

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


	--IF EXISTS (SELECT * FROM tempdb.INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = '##TEMP_Persona')
	--BEGIN
	--	DROP TABLE ##TEMP_Persona
	--END

	--IF EXISTS (SELECT * FROM tempdb.INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = '##TEMP_AlumnoPersona')
	--BEGIN
	--	DROP TABLE ##TEMP_AlumnoPersona
	--END

END
GO

