USE BD_OCEF_MigracionTP
GO

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.VIEWS WHERE TABLE_NAME = 'VW_ObservacionesTabla')
	DROP VIEW [dbo].[VW_ObservacionesTabla]
GO

CREATE VIEW VW_ObservacionesTabla
AS
(
	SELECT  I_ObsTablaID, ORT.D_FecRegistro, ORT.I_TablaID, T_TablaNom, ORT.I_ObservID, CO.T_ObservDesc,
			ORT.I_FilaTablaID, CO.T_ObservCod, CO.I_Severidad
	FROM	TI_ObservacionRegistroTabla ORT
			INNER JOIN TC_CatalogoTabla CT ON ORT.I_TablaID = CT.I_TablaID
			INNER JOIN TC_CatalogoObservacion CO ON ORT.I_ObservID = CO.I_ObservID
)
GO


--IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.VIEWS WHERE TABLE_NAME = 'VW_DetalleObligacionItems')
--	DROP VIEW [dbo].[VW_DetalleObligacionItems]
--GO

--CREATE VIEW VW_DetalleObligacionItems
--AS
--(
--	SELECT  Cod_alu, Cod_rc, Cuota_pago, Ano, P, Tipo_oblig, Concepto, Fch_venc, Nro_recibo, Fch_pago, Id_lug_pag, Cantidad, Monto, 
--			Documento, Pagado, Concepto_f, Fch_elimin, Nro_ec, Fch_ec, Eliminado, Pag_demas, Cod_cajero, Tipo_pago, No_banco, Cod_dep,
--			I_ProcedenciaID, B_Migrable, B_Migrado
--	FROM	TR_Ec_Det
--	WHERE	Concepto_f = 0
--			AND B_Obligacion = 1
--			--AND Cuota_pago NOT IN (SELECT Cuota_pago FROM TR_Cp_Des where Codigo_bnc = '' AND Cuota_pago <> 155)
--)
--GO


--IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.VIEWS WHERE TABLE_NAME = 'VW_DetalleObligacionPagos')
--	DROP VIEW [dbo].[VW_DetalleObligacionPagos]
--GO

--CREATE VIEW VW_DetalleObligacionPagos
--AS
--(
--	SELECT  Cod_alu, Cod_rc, Cuota_pago, Ano, P, Tipo_oblig, Concepto, Fch_venc, Nro_recibo, Fch_pago, Id_lug_pag, Cantidad, Monto, 
--			Documento, Pagado, Concepto_f, Fch_elimin, Nro_ec, Fch_ec, Eliminado, Pag_demas, Cod_cajero, Tipo_pago, No_banco, Cod_dep,
--			I_ProcedenciaID, B_Migrable, B_Migrado
--	FROM	TR_Ec_Det
--	WHERE	CONCEPTO_F = 1
--			AND TIPO_OBLIG = 0
--			AND B_Obligacion = 1
--)
--GO


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'FUNCTION' AND ROUTINE_NAME = 'Func_B_ValidarExisteTablaTemporalPagos')
	DROP FUNCTION [dbo].[Func_B_ValidarExisteTablaTemporalPagos]
GO

CREATE FUNCTION Func_B_ValidarExisteTablaTemporalPagos 
(
	@T_NombreSchema	varchar(50),
	@T_NombreTabla	varchar(50)
)
RETURNS  bit
AS
BEGIN
	DECLARE  @B_Result bit;

	IF EXIStS (SELECT * FROM  BD_OCEF_TemporalPagos.INFORMATION_SCHEMA.TABLES 
				WHERE TABLE_SCHEMA = @T_NombreSchema AND TABLE_NAME = @T_NombreTabla)
	BEGIN
		SET @B_Result = 1;
	END
	ELSE
	BEGIN
		SET @B_Result = 0;
	END

	RETURN @B_Result;
END
GO


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_U_CambiarEstadoMigrableRegistro')
	DROP PROCEDURE [dbo].[USP_U_CambiarEstadoMigrableRegistro]
GO

CREATE PROCEDURE [dbo].[USP_U_CambiarEstadoMigrableRegistro]
	@Tabla		  varchar(20),
	@I_RowID	  int,
	@B_Resultado  bit output,
	@T_Message	  nvarchar(4000) OUTPUT	
AS
--declare @B_Resultado  bit,
--		  @T_Message	nvarchar(4000)
--exec USP_U_CambiarEstadoMigrableRegistro 'TR_Cp_Des', 1, @B_Resultado output, @T_Message output
--select @B_Resultado as resultado, @T_Message as mensaje

BEGIN
	DECLARE @T_Sql nvarchar(1000)
	BEGIN TRY
		SET @T_Sql = '	UPDATE ' + @Tabla + '
					 	SET B_Migrable = ~ B_Migrable
					 	WHERE I_RowID = ' + CAST(@I_RowID AS varchar(11)) + '; ' 
		
		exec sp_executesql @T_Sql

		SET @T_Message = @@ROWCOUNT
		SET @B_Resultado = 1
	END TRY
	BEGIN CATCH
		SET @B_Resultado = 0
		SET @T_Message = ERROR_MESSAGE() + ' (Linea: ' + CAST(ERROR_LINE() AS varchar(11)) + ').' 
	END CATCH
END
GO



IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_U_ActualizarRegistroAlumno')
	DROP PROCEDURE [dbo].[USP_U_ActualizarRegistroAlumno]
GO

CREATE PROCEDURE USP_U_ActualizarRegistroAlumno
	@I_RowID	  int,
	@C_CodAlu	  varchar(20), 
	@C_NumDNI	  varchar(20), 
	@C_CodTipDoc  varchar(5), 
	@T_ApePaterno varchar(50),  
	@T_ApeMaterno varchar(50),  
	@T_Nombre	  varchar(50), 
	@C_Sexo		  char(1), 
	@D_FecNac	  date, 
	@C_CodModIng  varchar(2), 	 
	@C_AnioIngres smallint,
	@B_Resultado  bit output,
	@T_Message	  nvarchar(4000) OUTPUT	
AS
--declare @B_Resultado  bit,
--		  @T_Message	nvarchar(4000)
--exec USP_U_ActualizarRegistroAlumno @B_Resultado output, @T_Message output
--select @B_Resultado as resultado, @T_Message as mensaje
BEGIN

	DECLARE @D_FecProceso datetime = GETDATE() 

	BEGIN TRY 
		UPDATE TR_Alumnos
		SET	C_CodAlu = @C_CodAlu,
			C_NumDNI = @C_NumDNI,
			C_CodTipDoc = @C_CodTipDoc,
			T_ApePaterno = @T_ApePaterno, 
			T_ApeMaterno = @T_ApeMaterno, 
			T_Nombre = @T_Nombre,
			C_Sexo = @C_Sexo,
			D_FecNac = @D_FecNac,
			C_AnioIngreso = @C_AnioIngres
		WHERE 
			I_RowID = @I_RowID

		
		SET @T_Message =  @@ROWCOUNT
		SET @B_Resultado = 1

	END TRY
	BEGIN CATCH
		SET @B_Resultado = 0
		SET @T_Message = ERROR_MESSAGE() + ' (Linea: ' + CAST(ERROR_LINE() AS varchar(11)) + ').' 
	END CATCH
END
GO


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_IU_CopiarTablaAlumno')
	DROP PROCEDURE [dbo].[USP_IU_CopiarTablaAlumno]
GO

CREATE PROCEDURE USP_IU_CopiarTablaAlumno	
	@B_Resultado  bit output,
	@T_Message	  nvarchar(4000) OUTPUT	
AS
--declare @B_Resultado  bit,
--		  @T_Message	nvarchar(4000)
--exec USP_IU_CopiarTablaAlumno @B_Resultado output, @T_Message output
--select @B_Resultado as resultado, @T_Message as mensaje
BEGIN
	DECLARE @I_CantAlu int = 0
	DECLARE @I_Removidos int = 0
	DECLARE @I_Actualizados int = 0
	DECLARE @I_Insertados int = 0
	DECLARE @D_FecProceso datetime = GETDATE() 

	DECLARE @Tbl_output AS TABLE 
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

	BEGIN TRY 
	
		MERGE TR_Alumnos AS TRG
		USING (SELECT cod_fac, cod_esc, cod_esp, cod_rc, cod_alu, nom_alu, nom_pat, nom_mat, nom_nom, sexo, estado, resoluc, motivo, mod_ing, cod_ing, niv_alu, ano_ing, per_ing 
				 FROM BD_OCEF_TemporalPagos.dbo.alumnos) AS SRC
		ON	TRG.C_CodAlu = SRC.COD_ALU 
			AND TRG.C_RcCod = SRC.COD_RC
			AND ISNULL(TRG.C_CodModIng, '') = ISNULL(SRC.MOD_ING, '')
		WHEN MATCHED THEN
			UPDATE SET	--TRG.C_NumDNI = SRC.C_NUMDNI,
						--TRG.C_CodTipDoc = SRC.C_CODTIPDO,
						TRG.T_ApePaterno = REPLACE(SRC.nom_pat, '-', ' '),
						TRG.T_ApeMaterno = REPLACE(SRC.nom_mat, '-', ' '),
						TRG.T_Nombre = REPLACE(SRC.nom_nom, '-', ' '),
						TRG.C_Sexo = SRC.sexo,
						--TRG.D_FecNac = CONVERT(DATE, SRC.fec, 103),
						TRG.C_AnioIngreso = SRC.ano_ing
		WHEN NOT MATCHED BY TARGET THEN
			INSERT (C_RcCod, C_CodAlu, C_NumDNI, C_CodTipDoc, T_ApePaterno, T_ApeMaterno, T_Nombre, C_Sexo, D_FecNac, C_CodModIng, C_AnioIngreso, I_ProcedenciaID, D_FecCarga, B_Actualizado)
			--VALUES (SRC.COD_RC, SRC.COD_ALU, SRC.C_NUMDNI, SRC.C_CODTIPDO, REPLACE(SRC.T_APEPATER, '-', ' '), REPLACE(SRC.T_APEMATER, '-', ' '), REPLACE(SRC.T_NOMBRE, '-', ' '), 
			--		SRC.C_SEXO, CONVERT(DATE, SRC.D_FECNAC, 103), SRC.C_CODMODIN, SRC.C_ANIOINGR, 4, @D_FecProceso, 1)
			VALUES (SRC.COD_RC, SRC.COD_ALU, null, null, REPLACE(SRC.nom_pat, '-', ' '), REPLACE(SRC.nom_mat, '-', ' '), REPLACE(SRC.nom_nom, '-', ' '), 
					SRC.SEXO, null, SRC.cod_ing, SRC.ano_ing, 4, @D_FecProceso, 1)
		WHEN NOT MATCHED BY SOURCE THEN
			UPDATE SET TRG.B_Removido = 1, 
					   TRG.D_FecRemovido = @D_FecProceso
		OUTPUT	$ACTION, inserted.C_RcCod, inserted.C_CodAlu, inserted.C_NumDNI, inserted.C_CodTipDoc, inserted.T_ApePaterno,   
				inserted.T_ApeMaterno, inserted.T_Nombre, inserted.C_Sexo, inserted.D_FecNac, inserted.C_CodModIng, inserted.C_AnioIngreso, 
				deleted.C_NumDNI, deleted.C_CodTipDoc, deleted.T_ApePaterno, deleted.T_ApeMaterno, deleted.T_Nombre, 
				deleted.C_Sexo, deleted.D_FecNac, deleted.C_CodModIng, deleted.C_AnioIngreso, deleted.B_Removido INTO @Tbl_output;
		
		UPDATE	TR_Alumnos 
				SET	B_Actualizado = 0, B_Migrable = 1, D_FecMigrado = NULL, B_Migrado = 0

		UPDATE	t_Alu
		SET		t_Alu.B_Actualizado = 1,
				t_Alu.D_FecActualiza = @D_FecProceso
		FROM TR_Alumnos AS t_Alu
				INNER JOIN 	@Tbl_output as t_out ON t_out.C_RcCod = t_Alu.C_RcCod 
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
		SET @I_Insertados = (SELECT COUNT(*) FROM @Tbl_output WHERE accion = 'INSERT')
		SET @I_Actualizados = (SELECT COUNT(*) FROM @Tbl_output WHERE accion = 'UPDATE' AND B_Removido = 0)
		SET @I_Removidos = (SELECT COUNT(*) FROM @Tbl_output WHERE accion = 'UPDATE' AND B_Removido = 1)

		SET @B_Resultado = 1
		SET @T_Message =  'Total: ' + CAST(@I_CantAlu AS varchar) 

		SELECT @I_CantAlu AS tot_alumnos, @I_Insertados AS cant_inserted, @I_Actualizados as cant_updated, @I_Removidos as cant_removed, @D_FecProceso as fec_proceso
	END TRY
	BEGIN CATCH
		SET @B_Resultado = 0
		SET @T_Message = ERROR_MESSAGE() + ' (Linea: ' + CAST(ERROR_LINE() AS varchar(11)) + ').' 
	END CATCH
END
GO


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_U_ValidarCaracteresEspeciales')
	DROP PROCEDURE [dbo].[USP_U_ValidarCaracteresEspeciales]
GO

CREATE PROCEDURE USP_U_ValidarCaracteresEspeciales	
	@B_Resultado  bit output,
	@T_Message	  nvarchar(4000) OUTPUT	
AS
--declare @B_Resultado  bit,
--		@T_Message	  nvarchar(4000)
--exec USP_U_ValidarCaracteresEspeciales @B_Resultado output, @T_Message output
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
				PATINDEX('%[^a-zA-Z0-9.'' ]%', REPLACE(T_Nombre, '-', ' ')) <> 0 
				OR PATINDEX('%[^a-zA-Z0-9.'' ]%', REPLACE(T_ApePaterno, '-', ' ')) <> 0 
				OR PATINDEX('%[^a-zA-Z0-9.'' ]%', REPLACE(T_ApeMaterno, '-', ' ')) <> 0

		MERGE TI_ObservacionRegistroTabla AS TRG
		USING 	(SELECT	@I_ObservID AS I_ObservID, @I_TablaID AS I_TablaID, I_RowID AS I_FilaTablaID, @D_FecProceso AS D_FecRegistro FROM TR_Alumnos
				  WHERE	PATINDEX('%[^a-zA-Z0-9.'' ]%', REPLACE(T_Nombre, '-', ' ')) <> 0 
						OR PATINDEX('%[^a-zA-Z0-9.'' ]%', REPLACE(T_ApePaterno, '-', ' ')) <> 0 
						OR PATINDEX('%[^a-zA-Z0-9.'' ]%', REPLACE(T_ApeMaterno, '-', ' ')) <> 0) AS SRC
		ON TRG.I_ObservID = SRC.I_ObservID AND TRG.I_TablaID = SRC.I_TablaID AND TRG.I_FilaTablaID = SRC.I_FilaTablaID
		WHEN MATCHED THEN
			UPDATE SET D_FecRegistro = SRC.D_FecRegistro
		WHEN NOT MATCHED BY TARGET THEN
			INSERT (I_ObservID, I_TablaID, I_FilaTablaID, D_FecRegistro)
			VALUES (SRC.I_ObservID, SRC.I_TablaID, SRC.I_FilaTablaID, SRC.D_FecRegistro)
		WHEN NOT MATCHED BY SOURCE AND TRG.I_ObservID = @I_ObservID THEN
			DELETE;

		SET @I_Observados = (SELECT COUNT(*) FROM TI_ObservacionRegistroTabla WHERE I_ObservID = @I_ObservID AND I_TablaID = @I_TablaID)

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
	@B_Resultado  bit output,
	@T_Message	  nvarchar(4000) OUTPUT	
AS
--declare @B_Resultado  bit,
--		@T_Message	  nvarchar(4000)
--exec USP_U_ValidarCodigosAlumnoRepetidos @B_Resultado output, @T_Message output
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
		WHERE	EXISTS (SELECT C_CodAlu, C_RcCod, COUNT(*) FROM TR_Alumnos A 
						WHERE A.C_CodAlu = TR_Alumnos.C_CodAlu AND A.C_RcCod = TR_Alumnos.C_RcCod
						GROUP BY C_CodAlu, C_RcCod HAVING COUNT(*) > 1)
				
		MERGE TI_ObservacionRegistroTabla AS TRG
		USING 	(SELECT	@I_ObservID AS I_ObservID, @I_TablaID AS I_TablaID, I_RowID AS I_FilaTablaID, @D_FecProceso AS D_FecRegistro FROM TR_Alumnos
				  WHERE	EXISTS (SELECT C_CodAlu, C_RcCod, COUNT(*) FROM TR_Alumnos A 
						WHERE A.C_CodAlu = TR_Alumnos.C_CodAlu AND A.C_RcCod = TR_Alumnos.C_RcCod
						GROUP BY C_CodAlu, C_RcCod HAVING COUNT(*) > 1)) AS SRC
		ON TRG.I_ObservID = SRC.I_ObservID AND TRG.I_TablaID = SRC.I_TablaID AND TRG.I_FilaTablaID = SRC.I_FilaTablaID
		WHEN MATCHED THEN
			UPDATE SET D_FecRegistro = SRC.D_FecRegistro
		WHEN NOT MATCHED BY TARGET THEN
			INSERT (I_ObservID, I_TablaID, I_FilaTablaID, D_FecRegistro)
			VALUES (SRC.I_ObservID, SRC.I_TablaID, SRC.I_FilaTablaID, SRC.D_FecRegistro)
		WHEN NOT MATCHED BY SOURCE AND TRG.I_ObservID = @I_ObservID THEN
			DELETE;

		SET @I_Observados = (SELECT COUNT(*) FROM TI_ObservacionRegistroTabla WHERE I_ObservID = @I_ObservID AND I_TablaID = @I_TablaID)

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
	@B_Resultado  bit output,
	@T_Message	  nvarchar(4000) OUTPUT	
AS
--declare @B_Resultado  bit,
--		@T_Message	  nvarchar(4000)
--exec USP_U_ValidarCodigoCarreraAlumno @B_Resultado output, @T_Message output
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
		WHERE	NOT EXISTS (SELECT C_RcCod FROM BD_UNFV_Repositorio.dbo.TI_CarreraProfesional c
							WHERE C.C_RcCod = TR_Alumnos.C_RcCod)
					
		MERGE TI_ObservacionRegistroTabla AS TRG
		USING 	(SELECT	@I_ObservID AS I_ObservID, @I_TablaID AS I_TablaID, I_RowID AS I_FilaTablaID, @D_FecProceso AS D_FecRegistro FROM TR_Alumnos
				  WHERE	NOT EXISTS (SELECT C_RcCod FROM BD_UNFV_Repositorio.dbo.TI_CarreraProfesional c
							WHERE C.C_RcCod = TR_Alumnos.C_RcCod)) AS SRC
		ON TRG.I_ObservID = SRC.I_ObservID AND TRG.I_TablaID = SRC.I_TablaID AND TRG.I_FilaTablaID = SRC.I_FilaTablaID
		WHEN MATCHED THEN
			UPDATE SET D_FecRegistro = SRC.D_FecRegistro
		WHEN NOT MATCHED BY TARGET THEN
			INSERT (I_ObservID, I_TablaID, I_FilaTablaID, D_FecRegistro)
			VALUES (SRC.I_ObservID, SRC.I_TablaID, SRC.I_FilaTablaID, SRC.D_FecRegistro)
		WHEN NOT MATCHED BY SOURCE AND TRG.I_ObservID = @I_ObservID THEN
			DELETE;

		SET @I_Observados = (SELECT COUNT(*) FROM TI_ObservacionRegistroTabla WHERE I_ObservID = @I_ObservID AND I_TablaID = @I_TablaID)

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
	@B_Resultado  bit output,
	@T_Message	  nvarchar(4000) OUTPUT	
AS
--declare @B_Resultado  bit,
--		@T_Message	  nvarchar(4000)
--exec USP_U_ValidarAnioIngresoAlumno @B_Resultado output, @T_Message output
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
		WHERE	C_AnioIngreso IS NULL OR C_AnioIngreso = 0
					
		MERGE TI_ObservacionRegistroTabla AS TRG
		USING 	(SELECT	@I_ObservID AS I_ObservID, @I_TablaID AS I_TablaID, I_RowID AS I_FilaTablaID, @D_FecProceso AS D_FecRegistro FROM TR_Alumnos
				  WHERE	C_AnioIngreso IS NULL OR C_AnioIngreso = 0) AS SRC
		ON TRG.I_ObservID = SRC.I_ObservID AND TRG.I_TablaID = SRC.I_TablaID AND TRG.I_FilaTablaID = SRC.I_FilaTablaID
		WHEN MATCHED THEN
			UPDATE SET D_FecRegistro = SRC.D_FecRegistro
		WHEN NOT MATCHED BY TARGET THEN
			INSERT (I_ObservID, I_TablaID, I_FilaTablaID, D_FecRegistro)
			VALUES (SRC.I_ObservID, SRC.I_TablaID, SRC.I_FilaTablaID, SRC.D_FecRegistro)
		WHEN NOT MATCHED BY SOURCE AND TRG.I_ObservID = @I_ObservID THEN
			DELETE;

		SET @I_Observados = (SELECT COUNT(*) FROM TI_ObservacionRegistroTabla WHERE I_ObservID = @I_ObservID AND I_TablaID = @I_TablaID)

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
	@B_Resultado  bit output,
	@T_Message	  nvarchar(4000) OUTPUT	
AS
--declare @B_Resultado  bit,
--		@T_Message	  nvarchar(4000)
--exec USP_U_ValidarModalidadIngresoAlumno @B_Resultado output, @T_Message output
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
		WHERE	NOT EXISTS (SELECT C_CodModIng FROM BD_UNFV_Repositorio.dbo.TC_ModalidadIngreso MI
							WHERE MI.C_CodModIng = TR_Alumnos.C_CodModIng)
		
		MERGE TI_ObservacionRegistroTabla AS TRG
		USING 	(SELECT	@I_ObservID AS I_ObservID, @I_TablaID AS I_TablaID, I_RowID AS I_FilaTablaID, @D_FecProceso AS D_FecRegistro FROM TR_Alumnos
				  WHERE	NOT EXISTS (SELECT C_CodModIng FROM BD_UNFV_Repositorio.dbo.TC_ModalidadIngreso MI
									WHERE MI.C_CodModIng = TR_Alumnos.C_CodModIng)) AS SRC
		ON TRG.I_ObservID = SRC.I_ObservID AND TRG.I_TablaID = SRC.I_TablaID AND TRG.I_FilaTablaID = SRC.I_FilaTablaID
		WHEN MATCHED THEN
			UPDATE SET D_FecRegistro = SRC.D_FecRegistro
		WHEN NOT MATCHED BY TARGET THEN
			INSERT (I_ObservID, I_TablaID, I_FilaTablaID, D_FecRegistro)
			VALUES (SRC.I_ObservID, SRC.I_TablaID, SRC.I_FilaTablaID, SRC.D_FecRegistro)
		WHEN NOT MATCHED BY SOURCE AND TRG.I_ObservID = @I_ObservID THEN
			DELETE;

		SET @I_Observados = (SELECT COUNT(*) FROM TI_ObservacionRegistroTabla WHERE I_ObservID = @I_ObservID AND I_TablaID = @I_TablaID)

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


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_U_ValidarCorrespondenciaNumDocumentoPersona')
	DROP PROCEDURE [dbo].[USP_U_ValidarCorrespondenciaNumDocumentoPersona]
GO

CREATE PROCEDURE USP_U_ValidarCorrespondenciaNumDocumentoPersona	
	@B_Resultado  bit output,
	@T_Message	  nvarchar(4000) OUTPUT	
AS
--declare @B_Resultado  bit,
--		@T_Message	  nvarchar(4000)
--exec USP_U_ValidarCorrespondenciaNumDocumentoPersona @B_Resultado output, @T_Message output
--select @B_Resultado as resultado, @T_Message as mensaje
BEGIN
	DECLARE @I_Observados int = 0
	DECLARE @D_FecProceso datetime = GETDATE() 
	DECLARE @I_ObservID int = 30
	DECLARE @I_TablaID int = 1

	BEGIN TRANSACTION
	BEGIN TRY 
		
		SELECT I_RowID, C_RcCod, C_CodAlu, C_NumDNI, C_CodTipDoc, T_ApePaterno, T_ApeMaterno, T_Nombre, I_ProcedenciaID, C_Sexo, D_FecNac, C_CodModIng, C_AnioIngreso
		INTO #NumDoc_Repetidos_nombres_diferentes
		FROM TR_Alumnos WHERE C_NumDNI IN (
			SELECT C_NumDNI FROM (SELECT C_NumDNI, COUNT(*) R FROM TR_Alumnos
									WHERE C_NumDNI IS NOT NULL
									GROUP BY C_NumDNI
									HAVING COUNT(*) > 1) T1
			WHERE NOT EXISTS (
				SELECT C_NumDNI, T_ApePaterno COLLATE Modern_Spanish_CI_AI, T_ApeMaterno COLLATE Modern_Spanish_CI_AI
					, T_Nombre COLLATE Modern_Spanish_CI_AI, COUNT(*) R
				FROM TR_Alumnos
				WHERE C_NumDNI IS NOT NULL AND T1.C_NumDNI = C_NumDNI
				GROUP BY C_NumDNI, T_ApePaterno COLLATE Modern_Spanish_CI_AI, T_ApeMaterno COLLATE Modern_Spanish_CI_AI, T_Nombre COLLATE Modern_Spanish_CI_AI
				HAVING COUNT(*) > 1
			)
		)

		UPDATE	TR_Alumnos
		SET		B_Migrable = 0,
				D_FecEvalua = @D_FecProceso
		WHERE	EXISTS (SELECT * FROM #NumDoc_Repetidos_nombres_diferentes WHERE I_RowID = TR_Alumnos.I_RowID)
		
		MERGE TI_ObservacionRegistroTabla AS TRG
		USING 	(SELECT	@I_ObservID AS I_ObservID, @I_TablaID AS I_TablaID, I_RowID AS I_FilaTablaID, @D_FecProceso AS D_FecRegistro FROM TR_Alumnos
				  WHERE	EXISTS (SELECT * FROM #NumDoc_Repetidos_nombres_diferentes WHERE I_RowID = TR_Alumnos.I_RowID)) AS SRC
		ON TRG.I_ObservID = SRC.I_ObservID AND TRG.I_TablaID = SRC.I_TablaID AND TRG.I_FilaTablaID = SRC.I_FilaTablaID
		WHEN MATCHED THEN
			UPDATE SET D_FecRegistro = SRC.D_FecRegistro
		WHEN NOT MATCHED BY TARGET THEN
			INSERT (I_ObservID, I_TablaID, I_FilaTablaID, D_FecRegistro)
			VALUES (SRC.I_ObservID, SRC.I_TablaID, SRC.I_FilaTablaID, SRC.D_FecRegistro)
		WHEN NOT MATCHED BY SOURCE AND TRG.I_ObservID = @I_ObservID THEN
			DELETE;

		SET @I_Observados = (SELECT COUNT(*) FROM TI_ObservacionRegistroTabla WHERE I_ObservID = @I_ObservID AND I_TablaID = @I_TablaID)

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
	@B_Resultado  bit output,
	@T_Message	  nvarchar(4000) OUTPUT	
AS
--declare @B_Resultado  bit,
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

		UPDATE	TR_Alumnos
		SET		B_Migrable = 0,
				D_FecEvalua = @D_FecProceso
		WHERE	EXISTS (SELECT * FROM #NumDoc_Repetidos_sexo_diferente WHERE I_RowID = TR_Alumnos.I_RowID)
		
		MERGE TI_ObservacionRegistroTabla AS TRG
		USING 	(SELECT	@I_ObservID AS I_ObservID, @I_TablaID AS I_TablaID, I_RowID AS I_FilaTablaID, @D_FecProceso AS D_FecRegistro FROM TR_Alumnos
				  WHERE	EXISTS (SELECT * FROM #NumDoc_Repetidos_sexo_diferente WHERE I_RowID = TR_Alumnos.I_RowID)) AS SRC
		ON TRG.I_ObservID = SRC.I_ObservID AND TRG.I_TablaID = SRC.I_TablaID AND TRG.I_FilaTablaID = SRC.I_FilaTablaID
		WHEN MATCHED THEN
			UPDATE SET D_FecRegistro = SRC.D_FecRegistro
		WHEN NOT MATCHED BY TARGET THEN
			INSERT (I_ObservID, I_TablaID, I_FilaTablaID, D_FecRegistro)
			VALUES (SRC.I_ObservID, SRC.I_TablaID, SRC.I_FilaTablaID, SRC.D_FecRegistro)
		WHEN NOT MATCHED BY SOURCE AND TRG.I_ObservID = @I_ObservID THEN
			DELETE;

		SET @I_Observados = (SELECT COUNT(*) FROM TI_ObservacionRegistroTabla WHERE I_ObservID = @I_ObservID AND I_TablaID = @I_TablaID)

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



IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_IU_MigrarDataAlumnosUnfvRepositorio')
	DROP PROCEDURE [dbo].[USP_IU_MigrarDataAlumnosUnfvRepositorio]
GO

CREATE PROCEDURE USP_IU_MigrarDataAlumnosUnfvRepositorio
	@C_CodAlu	  varchar(20) = NULL,
	@C_AnioIng	  smallint = NULL,	
	@B_Resultado  bit output,
	@T_Message	  nvarchar(4000) OUTPUT	
AS
--declare @B_Resultado  bit,
--		@T_Message	  nvarchar(4000)
--exec USP_IU_MigrarDataAlumnosUnfvRepositorio NULL, NULL, @B_Resultado output, @T_Message output
--select @B_Resultado as resultado, @T_Message as mensaje
BEGIN
	DECLARE @I_CantAlu int = 0
	DECLARE @I_Removidos int = 0
	DECLARE @I_Actualizados_persona int = 0
	DECLARE @I_Actualizados_alumno int = 0
	DECLARE @I_Insertados_persona int = 0
	DECLARE @I_Insertados_alumno int = 0
	DECLARE @D_FecProceso datetime = GETDATE() 

	DECLARE @Tbl_output_persona AS TABLE 
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
		I_RowID			int,
		B_Removido		bit
	)

	DECLARE @Tbl_output_alumno AS TABLE 
	(
		accion			  varchar(20), 
		C_RcCod			  varchar(3), 
		C_CodAlu		  varchar(20), 
		INS_I_PersonaID	  int, 
		INS_C_CodModIng	  varchar(2), 
		INS_C_AnioIngreso smallint, 
		DEL_I_PersonaID	  int, 
		DEL_C_CodModIng	  varchar(2), 
		DEL_C_AnioIngreso smallint,
		I_RowID			  int,
		B_Removido		  bit
	)

	IF EXISTS (SELECT * FROM tempdb.INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = '##TEMP_AlumnoPersona')
	BEGIN
		DROP TABLE ##TEMP_AlumnoPersona
	END 

	CREATE TABLE ##TEMP_AlumnoPersona (
		I_PersonaID		int IDENTITY (1, 1),
		I_RowID			int,
		C_RcCod			varchar(3), 
		C_CodAlu		varchar(20),
		C_NumDNI		varchar(20),
		C_CodTipDoc		varchar(5)
	)

	BEGIN TRANSACTION
	BEGIN TRY 
		SET IDENTITY_INSERT ##TEMP_AlumnoPersona ON

		INSERT INTO ##TEMP_AlumnoPersona (I_PersonaID, I_RowID, C_RcCod, C_CodAlu, C_NumDNI, C_CodTipDoc)
		SELECT	A.I_PersonaID, I_RowID, A.C_RcCod, A.C_CodAlu, P.C_NumDNI, P.C_CodTipDoc
		FROM	BD_UNFV_Repositorio.dbo.TC_Alumno A 
				INNER JOIN BD_UNFV_Repositorio.dbo.TC_Persona P ON A.I_PersonaID = P.I_PersonaID AND P.B_Eliminado = 0 AND A.B_Eliminado = 0
				INNER JOIN TR_Alumnos TA ON TA.C_CodAlu = A.C_CodAlu AND TA.C_RcCod = A.C_RcCod
		--WHERE (A.C_CodAlu = @C_CodAlu OR @C_CodAlu IS NULL) OR (A.C_AnioIngreso = @C_AnioIng OR @C_AnioIng IS NULL)
		ORDER BY A.I_PersonaID
		
		SET IDENTITY_INSERT ##TEMP_AlumnoPersona OFF

		--SELECT IDENT_CURRENT('##TEMP_AlumnoPersona')

		INSERT INTO ##TEMP_AlumnoPersona (I_RowID, C_RcCod, C_CodAlu, C_NumDNI, C_CodTipDoc)
		SELECT	I_RowID, TA.C_RcCod, TA.C_CodAlu, TA.C_NumDNI, TA.C_CodTipDoc
		FROM	BD_UNFV_Repositorio.dbo.TC_Alumno A 
				RIGHT JOIN TR_Alumnos TA ON TA.C_CodAlu = A.C_CodAlu AND TA.C_RcCod = A.C_RcCod  
		WHERE --((A.C_CodAlu = @C_CodAlu OR @C_CodAlu IS NULL) OR (A.C_AnioIngreso = @C_AnioIng OR @C_AnioIng IS NULL))
			 -- AND 
			  A.I_PersonaID IS NULL

		--SELECT * FROM ##TEMP_AlumnoPersona ORDER BY I_PersonaID

		SET IDENTITY_INSERT BD_UNFV_Repositorio.dbo.TC_Persona ON

		MERGE BD_UNFV_Repositorio.dbo.TC_Persona AS TRG
		USING (SELECT DISTINCT AP.I_PersonaID, A.* FROM ##TEMP_AlumnoPersona AP 
				INNER JOIN TR_Alumnos A ON AP.I_RowID = A.I_RowID AND A.B_Migrable = 1) AS SRC
		ON TRG.I_PersonaID = SRC.I_PersonaID
		WHEN MATCHED AND B_Migrado = 0 THEN
			UPDATE SET	TRG.C_NumDNI	 = SRC.C_NumDNI,
						TRG.C_CodTipDoc	 = SRC.C_CodTipDoc,
						TRG.T_ApePaterno = SRC.T_ApePaterno,
						TRG.T_ApeMaterno = SRC.T_ApeMaterno,
						TRG.T_Nombre	 = SRC.T_Nombre,
						TRG.C_Sexo		 = SRC.C_Sexo
		WHEN NOT MATCHED BY TARGET THEN
			INSERT (I_PersonaID, C_NumDNI, C_CodTipDoc, T_ApePaterno, T_ApeMaterno, T_Nombre, C_Sexo, D_FecNac, B_Habilitado, B_Eliminado)
			VALUES (SRC.I_PersonaID,SRC.C_NUMDNI, SRC.C_CodTipDoc, SRC.T_ApePaterno, SRC.T_ApeMaterno, SRC.T_Nombre, SRC.C_Sexo, D_FecNac, 1, 0)
		OUTPUT	$ACTION, inserted.C_NumDNI, inserted.C_CodTipDoc, inserted.T_ApePaterno, inserted.T_ApeMaterno, inserted.T_Nombre, 
				inserted.C_Sexo, inserted.D_FecNac,deleted.C_NumDNI, deleted.C_CodTipDoc, deleted.T_ApePaterno, deleted.T_ApeMaterno, 
				deleted.T_Nombre, deleted.C_Sexo, deleted.D_FecNac, SRC.I_RowID, 0 INTO @Tbl_output_persona;		
		
		SET IDENTITY_INSERT BD_UNFV_Repositorio.dbo.TC_Persona OFF


		MERGE BD_UNFV_Repositorio.dbo.TC_Alumno AS TRG
		USING (SELECT AP.I_PersonaID, A.* FROM ##TEMP_AlumnoPersona AP 
				INNER JOIN TR_Alumnos A ON AP.I_RowID = A.I_RowID AND A.B_Migrable = 1) AS SRC
		ON	TRG.C_RcCod = SRC.C_RcCod 
			AND TRG.C_CodAlu = SRC.C_CodAlu
		WHEN MATCHED AND B_Migrado = 0 THEN
			UPDATE SET	TRG.I_PersonaID	 = SRC.I_PersonaID,
						TRG.C_CodModIng	 = SRC.C_CodModIng,
						TRG.C_AnioIngreso = SRC.C_AnioIngreso
		WHEN NOT MATCHED BY TARGET THEN
			INSERT (C_RcCod, C_CodAlu, I_PersonaID, C_CodModIng, C_AnioIngreso, B_Habilitado, B_Eliminado)
			VALUES (SRC.C_RcCod, SRC.C_CodAlu, SRC.I_PersonaID, SRC.C_CodModIng, SRC.C_AnioIngreso, 1, 0)
		OUTPUT	$ACTION, inserted.C_RcCod, inserted.C_CodAlu, inserted.I_PersonaID, inserted.C_CodModIng, inserted.C_AnioIngreso, 
				deleted.I_PersonaID, deleted.C_CodModIng, deleted.C_AnioIngreso, SRC.I_RowID, 0 INTO @Tbl_output_alumno;
		

		UPDATE	t_Alumnos
		SET		t_Alumnos.B_Migrado = 1,
				t_Alumnos.D_FecMigrado = @D_FecProceso
		FROM TR_Alumnos AS t_Alumnos
		INNER JOIN 	@Tbl_output_persona as t_out_p ON t_out_p.I_RowID = t_Alumnos.I_RowID
		INNER JOIN 	@Tbl_output_alumno as t_out_a ON t_out_a.I_RowID = t_Alumnos.I_RowID

		SET @I_CantAlu = (SELECT COUNT(*) FROM ##TEMP_AlumnoPersona AP INNER JOIN TR_Alumnos A ON AP.I_RowID = A.I_RowID AND A.B_Migrable = 1)
		SET @I_Insertados_persona = (SELECT COUNT(*) FROM @Tbl_output_persona WHERE accion = 'INSERT')
		SET @I_Insertados_alumno = (SELECT COUNT(*) FROM @Tbl_output_alumno WHERE accion = 'INSERT')
		SET @I_Actualizados_persona = (SELECT COUNT(*) FROM @Tbl_output_persona WHERE accion = 'UPDATE' AND B_Removido = 0)
		SET @I_Actualizados_alumno = (SELECT COUNT(*) FROM @Tbl_output_alumno WHERE accion = 'UPDATE' AND B_Removido = 0)
		
		IF EXISTS (SELECT * FROM tempdb.INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = '##TEMP_AlumnoPersona')
		BEGIN
			DROP TABLE ##TEMP_AlumnoPersona
		END

		COMMIT TRANSACTION
		SET @B_Resultado = 1
		SET @T_Message =  'Total: ' + CAST(@I_CantAlu AS varchar) + '|Insertados Persona: ' + CAST(@I_Insertados_persona AS varchar) + '|Insertados Alumno: ' + CAST(@I_Insertados_alumno AS varchar)
						+ '|Actualizados Persona: ' + CAST(@I_Actualizados_persona AS varchar) + '|Actualizados Alumno: ' + CAST(@I_Actualizados_alumno AS varchar)

	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION
		SET @B_Resultado = 0
		SET @T_Message = ERROR_MESSAGE() + ' LINE: ' + CAST(ERROR_LINE() AS varchar(10)) 
	END CATCH
END
GO


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_IU_CopiarTablaCuotaDePago')
	DROP PROCEDURE [dbo].[USP_IU_CopiarTablaCuotaDePago]
GO

CREATE PROCEDURE USP_IU_CopiarTablaCuotaDePago
	@T_Schema	  varchar(10),
	@I_SchemaID	  int,
	@B_Resultado  bit output,
	@T_Message	  nvarchar(4000) OUTPUT	
AS
--declare @B_Resultado  bit,
--		@T_Message	  nvarchar(4000)
--exec USP_IU_CopiarTablaCuotaDePago 'pregrado', 2, @B_Resultado output, @T_Message output
--select @B_Resultado as resultado, @T_Message as mensaje
BEGIN
	DECLARE @I_CpDes int = 0
	DECLARE @I_Removidos int = 0
	DECLARE @I_Actualizados int = 0
	DECLARE @I_Insertados int = 0
	DECLARE @D_FecProceso datetime = GETDATE() 
	DECLARE @T_SQL nvarchar(max)


	DECLARE @Tbl_output AS TABLE 
	(
		accion  varchar(20), 
		CUOTA_PAGO	float, 
		ELIMINADO bit,
		INS_DESCRIPCIO varchar(255), 
		INS_N_CTA_CTE varchar(255), 
		INS_CODIGO_BNC varchar(255), 
		INS_FCH_VENC date, 
		INS_PRIORIDAD varchar(255), 
		INS_C_MORA varchar(255), 
		DEL_DESCRIPCIO varchar(255), 
		DEL_N_CTA_CTE varchar(255), 
		DEL_CODIGO_BNC varchar(255), 
		DEL_FCH_VENC date, 
		DEL_PRIORIDAD varchar(255), 
		DEL_C_MORA varchar(255),
		B_Removido	bit
	)

	BEGIN TRY 
		
		MERGE TR_Cp_Des AS TRG
		USING BD_OCEF_TemporalPagos.eupg.cp_des AS SRC
		ON	TRG.CUOTA_PAGO = SRC.CUOTA_PAGO 
			AND TRG.ELIMINADO = SRC.ELIMINADO
		WHEN MATCHED THEN
			UPDATE SET	TRG.DESCRIPCIO = SRC.DESCRIPCIO,
						TRG.N_CTA_CTE = SRC.N_CTA_CTE,
						TRG.CODIGO_BNC = SRC.CODIGO_BNC,
						TRG.FCH_VENC = SRC.FCH_VENC,
						TRG.PRIORIDAD = SRC.PRIORIDAD,
						TRG.C_MORA = SRC.C_MORA
		WHEN NOT MATCHED BY TARGET THEN
			INSERT (CUOTA_PAGO, DESCRIPCIO, N_CTA_CTE, ELIMINADO, CODIGO_BNC, FCH_VENC, PRIORIDAD, C_MORA, I_ProcedenciaID, D_FecCarga, B_Actualizado)
			VALUES (SRC.CUOTA_PAGO, SRC.DESCRIPCIO, SRC.N_CTA_CTE, SRC.ELIMINADO, SRC.CODIGO_BNC, SRC.FCH_VENC, SRC.PRIORIDAD, SRC.C_MORA, @I_SchemaID, @D_FecProceso, 1)
		WHEN NOT MATCHED BY SOURCE THEN
			UPDATE SET TRG.B_Removido = 1, 
					   TRG.D_FecRemovido = @D_FecProceso
		OUTPUT	$ACTION, inserted.CUOTA_PAGO, inserted.ELIMINADO, inserted.DESCRIPCIO, inserted.N_CTA_CTE,  
				inserted.CODIGO_BNC, inserted.FCH_VENC, inserted.PRIORIDAD, inserted.C_MORA, deleted.DESCRIPCIO, 
				deleted.N_CTA_CTE, deleted.CODIGO_BNC, deleted.FCH_VENC, deleted.PRIORIDAD, deleted.C_MORA, 
				deleted.B_Removido INTO @Tbl_output;
		
		UPDATE	TR_Cp_Des 
				SET	B_Actualizado = 0, B_Migrable = 1, 
					D_FecMigrado = NULL, B_Migrado = 0,
					I_Anio = NULL, I_CatPagoID = NULL, I_Periodo = NULL

		UPDATE	t_CpDes
		SET		t_CpDes.B_Actualizado = 1,
				t_CpDes.D_FecActualiza = @D_FecProceso
		FROM TR_Cp_Des  AS t_CpDes
		INNER JOIN 	@Tbl_output as t_out ON t_out.CUOTA_PAGO = t_CpDes.CUOTA_PAGO 
					AND t_out.ELIMINADO = t_CpDes.ELIMINADO AND t_out.accion = 'UPDATE' AND t_out.B_Removido = 0
		WHERE 
				t_out.INS_DESCRIPCIO <> t_out.DEL_DESCRIPCIO OR
				t_out.INS_N_CTA_CTE <> t_out.DEL_N_CTA_CTE OR
				t_out.INS_CODIGO_BNC <> t_out.DEL_CODIGO_BNC OR
				t_out.INS_FCH_VENC <> t_out.DEL_FCH_VENC OR
				t_out.INS_PRIORIDAD <> t_out.DEL_PRIORIDAD OR
				t_out.INS_C_MORA <> t_out.DEL_C_MORA

		SET @I_CpDes = (SELECT COUNT(*) FROM BD_OCEF_TemporalPagos.eupg.cp_des)
		SET @I_Insertados = (SELECT COUNT(*) FROM @Tbl_output WHERE accion = 'INSERT')
		SET @I_Actualizados = (SELECT COUNT(*) FROM @Tbl_output WHERE accion = 'UPDATE' AND B_Removido = 0)
		SET @I_Removidos = (SELECT COUNT(*) FROM @Tbl_output WHERE accion = 'UPDATE' AND B_Removido = 1)

		SELECT @I_CpDes AS tot_cuotaPago, @I_Insertados AS cant_inserted, @I_Actualizados as cant_updated, @I_Removidos as cant_removed, @D_FecProceso as fec_proceso
		
		SET @B_Resultado = 1
		SET @T_Message =  'Total: ' + CAST(@I_CpDes AS varchar) + '|Insertados: ' + CAST(@I_Insertados AS varchar) 
						+ '|Actualizados: ' + CAST(@I_Actualizados AS varchar) + '|Removidos: ' + CAST(@I_Removidos AS varchar)
	END TRY
	BEGIN CATCH
		SET @B_Resultado = 0
		SET @T_Message = ERROR_MESSAGE() + ' LINE: ' + CAST(ERROR_LINE() AS varchar(10)) 
	END CATCH
END
GO


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_U_MarcarRepetidosCuotaDePago')
	DROP PROCEDURE [dbo].[USP_U_MarcarRepetidosCuotaDePago]
GO

CREATE PROCEDURE USP_U_MarcarRepetidosCuotaDePago
	@B_Resultado  bit output,
	@T_Message	  nvarchar(4000) OUTPUT	
AS
--declare @B_Resultado  bit,
--		@T_Message	  nvarchar(4000)
--exec USP_U_MarcarRepetidosCuotaDePago @B_Resultado output, @T_Message output
--select @B_Resultado as resultado, @T_Message as mensaje
BEGIN	
	DECLARE @D_FecProceso datetime = GETDATE() 
	DECLARE @I_ObservID_activo int = 3
	DECLARE @I_ObservID_eliminado int = 4
	DECLARE @I_TablaID int = 2
	DECLARE @I_Observados_activos int = 0
	DECLARE @I_Observados_eliminados int = 0

	BEGIN TRY 
		UPDATE	TR_Cp_Des
		SET		B_Migrable = 0,
				D_FecEvalua = @D_FecProceso
		WHERE	CUOTA_PAGO IN (SELECT CUOTA_PAGO FROM TR_Cp_Des WHERE ELIMINADO = 0 GROUP BY CUOTA_PAGO HAVING COUNT(CUOTA_PAGO) > 1
								UNION
							   SELECT CUOTA_PAGO FROM TR_Cp_Des WHERE ELIMINADO = 1 GROUP BY CUOTA_PAGO HAVING COUNT(CUOTA_PAGO) > 1)

		MERGE TI_ObservacionRegistroTabla AS TRG
		USING (SELECT @I_ObservID_activo AS I_ObservID, @I_TablaID AS I_TablaID, I_RowID AS I_FilaTablaID, @D_FecProceso AS D_FecRegistro 
				 FROM TR_Cp_Des 
				 WHERE CUOTA_PAGO IN (SELECT CUOTA_PAGO FROM TR_Cp_Des WHERE ELIMINADO = 0 GROUP BY CUOTA_PAGO HAVING COUNT(CUOTA_PAGO) > 1)
			  ) AS SRC
		ON TRG.I_ObservID = SRC.I_ObservID AND TRG.I_TablaID = SRC.I_TablaID AND TRG.I_FilaTablaID = SRC.I_FilaTablaID
		WHEN MATCHED THEN
			UPDATE SET D_FecRegistro = SRC.D_FecRegistro
		WHEN NOT MATCHED BY TARGET THEN
			INSERT (I_ObservID, I_TablaID, I_FilaTablaID, D_FecRegistro)
			VALUES (SRC.I_ObservID, SRC.I_TablaID, SRC.I_FilaTablaID, SRC.D_FecRegistro)
		WHEN NOT MATCHED BY SOURCE AND TRG.I_ObservID = @I_ObservID_activo THEN
			DELETE;

		MERGE TI_ObservacionRegistroTabla AS TRG
		USING (SELECT @I_ObservID_eliminado AS I_ObservID, @I_TablaID AS I_TablaID, I_RowID AS I_FilaTablaID, @D_FecProceso AS D_FecRegistro 
				 FROM TR_Cp_Des 
				 WHERE CUOTA_PAGO IN (SELECT CUOTA_PAGO FROM TR_Cp_Des WHERE ELIMINADO = 1 GROUP BY CUOTA_PAGO HAVING COUNT(CUOTA_PAGO) > 1)
			  ) AS SRC
		ON TRG.I_ObservID = SRC.I_ObservID AND TRG.I_TablaID = SRC.I_TablaID AND TRG.I_FilaTablaID = SRC.I_FilaTablaID
		WHEN MATCHED THEN
			UPDATE SET D_FecRegistro = SRC.D_FecRegistro
		WHEN NOT MATCHED BY TARGET THEN
			INSERT (I_ObservID, I_TablaID, I_FilaTablaID, D_FecRegistro)
			VALUES (SRC.I_ObservID, SRC.I_TablaID, SRC.I_FilaTablaID, SRC.D_FecRegistro)
		WHEN NOT MATCHED BY SOURCE AND TRG.I_ObservID = @I_ObservID_eliminado THEN
			DELETE;

		SET @I_Observados_activos = (SELECT COUNT(*) FROM TI_ObservacionRegistroTabla WHERE I_ObservID = @I_ObservID_activo AND I_TablaID = @I_TablaID)
		SET @I_Observados_eliminados = (SELECT COUNT(*) FROM TI_ObservacionRegistroTabla WHERE I_ObservID = @I_ObservID_eliminado AND I_TablaID = @I_TablaID)

		SET @B_Resultado = 1
		SET @T_Message = CAST(@I_Observados_activos AS varchar) + ' con estado activo |' + CAST(@I_Observados_eliminados AS varchar) +  ' con estado eliminado'
	END TRY
	BEGIN CATCH
		SET @B_Resultado = 0
		SET @T_Message = ERROR_MESSAGE() + ' LINE: ' + CAST(ERROR_LINE() AS varchar(10)) 
	END CATCH
END
GO


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_U_AsignarAnioPeriodoCuotaPago')
	DROP PROCEDURE [dbo].[USP_U_AsignarAnioPeriodoCuotaPago]
GO

CREATE PROCEDURE USP_U_AsignarAnioPeriodoCuotaPago
	@B_Resultado  bit output,
	@T_Message	  nvarchar(4000) OUTPUT	
AS
--declare @B_Resultado  bit,
--		@T_Message	  nvarchar(4000)
--exec USP_U_AsignarAnioPeriodoCuotaPago @B_Resultado output, @T_Message output
--select @B_Resultado as resultado, @T_Message as mensaje
BEGIN
	DECLARE @D_FecProceso datetime = GETDATE() 
	DECLARE @I_TablaID int = 2
	DECLARE @I_ObsMasUnAnio int = 5
	DECLARE @I_ObsSinAnio int = 6
	DECLARE @I_ObsMasUnPeriodo int = 7
	DECLARE @I_ObsSinPeriodo int = 8

	DECLARE @I_cant_MasUnAnio int = 0
	DECLARE @I_cant_SinAnio int = 0
	DECLARE @I_cant_MasUnPeriodo int = 0
	DECLARE @I_cant_SinPeriodo int = 0

	BEGIN TRY 
		--1. ASIGNAR AÑO CUOTA PAGO
		DECLARE @cuota_anio AS TABLE (cuota_pago int, anio_cuota varchar(4))
		DECLARE @periodo AS TABLE (cuota_pago int, I_Periodo int, C_CodPeriodo varchar(5), T_Descripcion varchar(50))

			--CUOTAS DE PAGO CON AÑO EN CP_PRI
		INSERT INTO @cuota_anio(cuota_pago, anio_cuota)
			SELECT DISTINCT D.CUOTA_PAGO, ISNULL(P.ANO, SUBSTRING(D.DESCRIPCIO, 1,4)) AS ANO 
			  FROM TR_Cp_Des D LEFT JOIN TR_cp_pri P ON D.CUOTA_PAGO = P.CUOTA_PAGO 
			 WHERE ISNUMERIC(ISNULL(P.ANO, SUBSTRING(D.DESCRIPCIO, 1,4))) = 1;

			--CUOTAS DE PAGO SIN AÑO EN CP_PRI PERO CON AÑO EN EC_DET
		INSERT INTO @cuota_anio(cuota_pago, anio_cuota)
		SELECT DISTINCT ed.CUOTA_PAGO, ed.ANO FROM TR_ec_det ed 
				INNER JOIN (SELECT cd.CUOTA_PAGO FROM TR_Cp_Des cd
							LEFT JOIN @cuota_anio ca ON cd.CUOTA_PAGO = ca.cuota_pago
							WHERE anio_cuota IS NULL) cdca
				ON cdca.CUOTA_PAGO = ed.CUOTA_PAGO

		UPDATE	TR_Cp_Des
		SET		B_Migrable = 0,
				D_FecEvalua = @D_FecProceso
		WHERE	CUOTA_PAGO IN (SELECT cuota_pago FROM @cuota_anio GROUP BY cuota_pago HAVING COUNT(*) > 1)
		
		UPDATE	TR_Cp_Des
		SET		B_Migrable = 0,
				D_FecEvalua = @D_FecProceso
		WHERE	CUOTA_PAGO IN (SELECT cd.CUOTA_PAGO FROM TR_Cp_Des cd
							  LEFT JOIN @cuota_anio ca ON cd.CUOTA_PAGO = ca.cuota_pago
							  WHERE anio_cuota IS NULL)
	
		MERGE TI_ObservacionRegistroTabla AS TRG
		USING 	(SELECT	@I_ObsMasUnAnio AS I_ObservID, @I_TablaID AS I_TablaID, I_RowID AS I_FilaTablaID, @D_FecProceso AS D_FecRegistro FROM TR_Cp_Des
				 WHERE CUOTA_PAGO IN (SELECT cuota_pago FROM @cuota_anio GROUP BY cuota_pago HAVING COUNT(*) > 1)) AS SRC
		ON TRG.I_ObservID = SRC.I_ObservID AND TRG.I_TablaID = SRC.I_TablaID AND TRG.I_FilaTablaID = SRC.I_FilaTablaID
		WHEN MATCHED THEN
			UPDATE SET D_FecRegistro = SRC.D_FecRegistro
		WHEN NOT MATCHED BY TARGET THEN
			INSERT (I_ObservID, I_TablaID, I_FilaTablaID, D_FecRegistro)
			VALUES (SRC.I_ObservID, SRC.I_TablaID, SRC.I_FilaTablaID, SRC.D_FecRegistro)
		WHEN NOT MATCHED BY SOURCE AND TRG.I_ObservID = @I_ObsMasUnAnio THEN
			DELETE;

		MERGE TI_ObservacionRegistroTabla AS TRG
		USING 	(SELECT	@I_ObsSinAnio AS I_ObservID, @I_TablaID AS I_TablaID, I_RowID AS I_FilaTablaID, @D_FecProceso AS D_FecRegistro FROM TR_Cp_Des
				  WHERE	CUOTA_PAGO IN (SELECT cd.CUOTA_PAGO FROM TR_Cp_Des cd LEFT JOIN @cuota_anio ca ON cd.CUOTA_PAGO = ca.cuota_pago WHERE anio_cuota IS NULL)
				) AS SRC
		ON TRG.I_ObservID = SRC.I_ObservID AND TRG.I_TablaID = SRC.I_TablaID AND TRG.I_FilaTablaID = SRC.I_FilaTablaID
		WHEN MATCHED THEN
			UPDATE SET D_FecRegistro = SRC.D_FecRegistro
		WHEN NOT MATCHED BY TARGET THEN
			INSERT (I_ObservID, I_TablaID, I_FilaTablaID, D_FecRegistro)
			VALUES (SRC.I_ObservID, SRC.I_TablaID, SRC.I_FilaTablaID, SRC.D_FecRegistro)
		WHEN NOT MATCHED BY SOURCE AND TRG.I_ObservID = @I_ObsSinAnio THEN
			DELETE;

		UPDATE	tb_des  
		SET		I_Anio = a1.anio_cuota,
				D_FecEvalua = @D_FecProceso
		FROM	TR_Cp_Des tb_des
				INNER JOIN @cuota_anio a1 ON tb_des.CUOTA_PAGO = a1.cuota_pago
				INNER JOIN (SELECT cuota_pago FROM @cuota_anio GROUP BY cuota_pago HAVING COUNT(*) = 1) a2
				ON a1.cuota_pago= a2.cuota_pago

		--2. ASIGNAR PERIODO CUOTA PAGO
		INSERT INTO @periodo (cuota_pago, I_Periodo, C_CodPeriodo, T_Descripcion)
			SELECT	DISTINCT pri.CUOTA_PAGO, I_OpcionID, T_OpcionCod, T_OpcionDesc 
			FROM	BD_OCEF_CtasPorCobrar.dbo.TC_CatalogoOpcion per 
					INNER JOIN BD_OCEF_TemporalPagos.pregrado.cp_pri pri ON per.T_OpcionCod = pri.P
			WHERE I_ParametroID = 5

		UPDATE	TR_Cp_Des
		SET		B_Migrable = 0,
				D_FecEvalua = @D_FecProceso
		WHERE	CUOTA_PAGO IN (SELECT cuota_pago FROM @periodo GROUP BY cuota_pago HAVING COUNT(*) > 1)
	
		MERGE TI_ObservacionRegistroTabla AS TRG
		USING 	(SELECT	@I_ObsMasUnPeriodo AS I_ObservID, @I_TablaID AS I_TablaID, I_RowID AS I_FilaTablaID, @D_FecProceso AS D_FecRegistro FROM TR_Cp_Des
				 WHERE CUOTA_PAGO IN (SELECT cuota_pago FROM @periodo GROUP BY cuota_pago HAVING COUNT(*) > 1)) AS SRC
		ON TRG.I_ObservID = SRC.I_ObservID AND TRG.I_TablaID = SRC.I_TablaID AND TRG.I_FilaTablaID = SRC.I_FilaTablaID
		WHEN MATCHED THEN
			UPDATE SET D_FecRegistro = SRC.D_FecRegistro
		WHEN NOT MATCHED BY TARGET THEN
			INSERT (I_ObservID, I_TablaID, I_FilaTablaID, D_FecRegistro)
			VALUES (SRC.I_ObservID, SRC.I_TablaID, SRC.I_FilaTablaID, SRC.D_FecRegistro)
		WHEN NOT MATCHED BY SOURCE AND TRG.I_ObservID = @I_ObsMasUnPeriodo THEN
			DELETE;

		UPDATE	tb_des  
		SET		I_Periodo = per1.I_Periodo,
				D_FecEvalua = @D_FecProceso
		FROM	TR_Cp_Des tb_des
				INNER JOIN @periodo per1 ON tb_des.CUOTA_PAGO = per1.cuota_pago
				INNER JOIN (SELECT cuota_pago FROM @periodo GROUP BY cuota_pago HAVING COUNT(*) = 1) per2
				ON per1.CUOTA_PAGO = per2.cuota_pago

		UPDATE	TR_Cp_Des
		SET		B_Migrable = 0,
				D_FecEvalua = @D_FecProceso
		WHERE	I_Periodo IS NULL

		MERGE TI_ObservacionRegistroTabla AS TRG
		USING 	(SELECT	@I_ObsSinPeriodo AS I_ObservID, @I_TablaID AS I_TablaID, I_RowID AS I_FilaTablaID, @D_FecProceso AS D_FecRegistro FROM TR_Cp_Des
				 WHERE I_Periodo IS NULL) AS SRC
		ON TRG.I_ObservID = SRC.I_ObservID AND TRG.I_TablaID = SRC.I_TablaID AND TRG.I_FilaTablaID = SRC.I_FilaTablaID
		WHEN MATCHED THEN
			UPDATE SET D_FecRegistro = SRC.D_FecRegistro
		WHEN NOT MATCHED BY TARGET THEN
			INSERT (I_ObservID, I_TablaID, I_FilaTablaID, D_FecRegistro)
			VALUES (SRC.I_ObservID, SRC.I_TablaID, SRC.I_FilaTablaID, SRC.D_FecRegistro)
		WHEN NOT MATCHED BY SOURCE AND TRG.I_ObservID = @I_ObsSinPeriodo THEN
			DELETE;
	
		SET @I_cant_MasUnAnio = (SELECT COUNT(*) FROM TI_ObservacionRegistroTabla WHERE I_ObservID = @I_ObsMasUnAnio AND I_TablaID = @I_TablaID)
		SET @I_cant_SinAnio = (SELECT COUNT(*) FROM TI_ObservacionRegistroTabla WHERE I_ObservID = @I_ObsSinAnio AND I_TablaID = @I_TablaID)
		SET @I_cant_MasUnPeriodo = (SELECT COUNT(*) FROM TI_ObservacionRegistroTabla WHERE I_ObservID = @I_ObsMasUnPeriodo AND I_TablaID = @I_TablaID)
		SET @I_cant_SinPeriodo = (SELECT COUNT(*) FROM TI_ObservacionRegistroTabla WHERE I_ObservID = @I_ObsSinPeriodo AND I_TablaID = @I_TablaID)

		SET @B_Resultado = 1
		SET @T_Message = CAST(@I_cant_MasUnAnio AS varchar) + ' | ' + CAST(@I_cant_SinAnio AS varchar) + ' | ' + 
						 CAST(@I_cant_MasUnPeriodo AS varchar) + ' | ' + CAST(@I_cant_SinPeriodo AS varchar)
	END TRY
	BEGIN CATCH
		SET @B_Resultado = 0
		SET @T_Message = ERROR_MESSAGE() + ' LINE: ' + CAST(ERROR_LINE() AS varchar(10)) 
	END CATCH
END
GO


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_U_AsignarCategoriaCuotaPago')
	DROP PROCEDURE [dbo].[USP_U_AsignarCategoriaCuotaPago]
GO

CREATE PROCEDURE USP_U_AsignarCategoriaCuotaPago
	@B_Resultado  bit output,
	@T_Message	  nvarchar(4000) OUTPUT	
AS
--declare @B_Resultado  bit,
--		@T_Message	  nvarchar(4000)
--exec USP_U_AsignarCategoriaCuotaPago @B_Resultado output, @T_Message output
--select @B_Resultado as resultado, @T_Message as mensaje
BEGIN
	DECLARE @D_FecProceso datetime = GETDATE() 
	DECLARE @I_TablaID int = 2
	DECLARE @I_ObsMasUnCategoria int = 9
	DECLARE @I_ObsSinCategoria int = 10
	DECLARE @I_cant_masCategorias int = 0
	DECLARE @I_cant_sinCategorias int = 0
	
	BEGIN TRANSACTION
	BEGIN TRY 
		DECLARE @categoria_pago AS TABLE (cuota_pago int, I_CatPagoID int, N_CodBanco varchar(10))
		INSERT INTO @categoria_pago (cuota_pago, I_CatPagoID, N_CodBanco)
			SELECT d.CUOTA_PAGO, c.I_CatPagoID, c.N_CodBanco FROM TR_Cp_Des d
			LEFT JOIN BD_OCEF_CtasPorCobrar.dbo.TC_CategoriaPago c ON d.CODIGO_BNC = c.N_CodBanco

		UPDATE	TR_Cp_Des
		SET		B_Migrable = 0,
				D_FecEvalua = @D_FecProceso
		WHERE	CUOTA_PAGO IN (SELECT cuota_pago FROM @categoria_pago GROUP BY cuota_pago HAVING COUNT(*) > 1)

		MERGE TI_ObservacionRegistroTabla AS TRG
		USING 	(SELECT	@I_ObsMasUnCategoria AS I_ObservID, @I_TablaID AS I_TablaID, I_RowID AS I_FilaTablaID, @D_FecProceso AS D_FecRegistro FROM TR_Cp_Des
				  WHERE	CUOTA_PAGO IN (SELECT cuota_pago FROM @categoria_pago GROUP BY cuota_pago HAVING COUNT(*) > 1)) AS SRC
		ON TRG.I_ObservID = SRC.I_ObservID AND TRG.I_TablaID = SRC.I_TablaID AND TRG.I_FilaTablaID = SRC.I_FilaTablaID
		WHEN MATCHED THEN
			UPDATE SET D_FecRegistro = SRC.D_FecRegistro
		WHEN NOT MATCHED BY TARGET THEN
			INSERT (I_ObservID, I_TablaID, I_FilaTablaID, D_FecRegistro)
			VALUES (SRC.I_ObservID, SRC.I_TablaID, SRC.I_FilaTablaID, SRC.D_FecRegistro)
		WHEN NOT MATCHED BY SOURCE AND TRG.I_ObservID = @I_ObsMasUnCategoria THEN
			DELETE;

		UPDATE	tb_des  
		SET		I_CatPagoID = cat1.I_CatPagoID,
				D_FecEvalua = @D_FecProceso
		FROM	TR_Cp_Des tb_des
				INNER JOIN @categoria_pago cat1 ON tb_des.CUOTA_PAGO = cat1.cuota_pago
				INNER JOIN (SELECT cuota_pago FROM @categoria_pago GROUP BY cuota_pago HAVING COUNT(*) = 1) cat2
				ON cat1.CUOTA_PAGO = cat2.cuota_pago

		UPDATE	TR_Cp_Des
		SET		B_Migrable = 0,
				D_FecEvalua = @D_FecProceso
		WHERE	I_CatPagoID IS NULL

		MERGE TI_ObservacionRegistroTabla AS TRG
		USING 	(SELECT	@I_ObsSinCategoria AS I_ObservID, @I_TablaID AS I_TablaID, I_RowID AS I_FilaTablaID, @D_FecProceso AS D_FecRegistro FROM TR_Cp_Des
				  WHERE	I_CatPagoID IS NULL) AS SRC
		ON TRG.I_ObservID = SRC.I_ObservID AND TRG.I_TablaID = SRC.I_TablaID AND TRG.I_FilaTablaID = SRC.I_FilaTablaID
		WHEN MATCHED THEN
			UPDATE SET D_FecRegistro = SRC.D_FecRegistro
		WHEN NOT MATCHED BY TARGET THEN
			INSERT (I_ObservID, I_TablaID, I_FilaTablaID, D_FecRegistro)
			VALUES (SRC.I_ObservID, SRC.I_TablaID, SRC.I_FilaTablaID, SRC.D_FecRegistro)
		WHEN NOT MATCHED BY SOURCE AND TRG.I_ObservID = @I_ObsMasUnCategoria THEN
			DELETE;

		SET @I_cant_masCategorias = (SELECT COUNT(*) FROM TI_ObservacionRegistroTabla WHERE I_ObservID = @I_ObsMasUnCategoria AND I_TablaID = @I_TablaID)
		SET @I_cant_sinCategorias = (SELECT COUNT(*) FROM TI_ObservacionRegistroTabla WHERE I_ObservID = @I_ObsSinCategoria AND I_TablaID = @I_TablaID)
		
		COMMIT TRANSACTION
		SET @B_Resultado = 1
		SET @T_Message = CAST(@I_cant_masCategorias AS varchar) + ' | ' + CAST(@I_cant_sinCategorias AS varchar)
	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION
 		SET @B_Resultado = 0
		SET @T_Message = ERROR_MESSAGE() + ' LINE: ' + CAST(ERROR_LINE() AS varchar(10)) 
	END CATCH
END
GO


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_IU_MigrarDataCuotaDePagoCtasPorCobrar')
	DROP PROCEDURE [dbo].[USP_IU_MigrarDataCuotaDePagoCtasPorCobrar]
GO

CREATE PROCEDURE USP_IU_MigrarDataCuotaDePagoCtasPorCobrar
	@I_ProcesoID	  int = NULL,
	@I_AnioIni	  int = NULL,
	@I_AnioFin	  int = NULL,
	@B_Resultado  bit output,
	@T_Message	  nvarchar(4000) OUTPUT	
AS
--declare @B_Resultado  bit, @I_ProcesoID int, @I_AnioIni int, @I_AnioFin int, @T_Message nvarchar(4000)
--exec USP_IU_MigrarDataCuotaDePagoCtasPorCobrar @I_ProcesoID = null, @I_AnioIni = null, @I_AnioFin = null, @B_Resultado = @B_Resultado output, @T_Message = @T_Message output
--select @B_Resultado as resultado, @T_Message as mensaje
BEGIN
	DECLARE @D_FecProceso datetime = GETDATE() 
	DECLARE @Tbl_outputProceso AS TABLE (T_Action varchar(20), I_RowID int)
	DECLARE @Tbl_outputCtas AS TABLE (T_Action varchar(20), I_RowID int)
	DECLARE @Tbl_outputCtasCat AS TABLE (T_Action varchar(20), I_RowID int)
	DECLARE @I_Proc_Inserted int = 0
	DECLARE @I_Proc_Updated int = 0
	DECLARE @I_Ctas_Inserted int = 0
	DECLARE @I_Ctas_Updated int = 0
	DECLARE @I_CtaCat_Inserted int = 0
	DECLARE @I_CtaCat_Updated int = 0
	DECLARE @I_ObservID int = 11
	DECLARE @I_TablaID int = 2

	BEGIN TRANSACTION;
	BEGIN TRY 
		SET @I_AnioIni = (SELECT ISNULL(@I_AnioIni, 0))
		SET @I_AnioFin = (SELECT ISNULL(@I_AnioFin, 3000))

		SET IDENTITY_INSERT BD_OCEF_CtasPorCobrar.dbo.TC_Proceso ON;

		MERGE INTO  BD_OCEF_CtasPorCobrar.dbo.TC_Proceso AS TRG
		USING (SELECT * FROM TR_Cp_Des 
				WHERE B_Migrable = 1 AND I_Anio BETWEEN @I_AnioIni AND @I_AnioFin
					  AND (CUOTA_PAGO = @I_ProcesoID OR @I_ProcesoID IS NULL)
			  ) AS SRC
		ON TRG.I_ProcesoID = SRC.CUOTA_PAGO 
		WHEN NOT MATCHED BY TARGET THEN 
			 INSERT (I_ProcesoID, I_CatPagoID, T_ProcesoDesc, I_Anio, I_Periodo, N_CodBanco, D_FecVencto, I_Prioridad, B_Mora, B_Migrado, D_FecCre, B_Habilitado, B_Eliminado)
			 VALUES (CUOTA_PAGO, I_CatPagoID, DESCRIPCIO, I_Anio, I_Periodo, CODIGO_BNC, FCH_VENC, PRIORIDAD, 
					C_MORA, 1, @D_FecProceso, 1, ELIMINADO)
		WHEN MATCHED AND TRG.B_Migrado = 1 AND TRG.I_UsuarioMod IS NULL THEN 
			 UPDATE SET I_CatPagoID = SRC.I_CatPagoID, 
					 T_ProcesoDesc = SRC.DESCRIPCIO, 
					 I_Anio = SRC.I_Anio, 
					 I_Periodo = SRC.I_Periodo,
					 N_CodBanco = SRC.CODIGO_BNC, 
					 D_FecVencto = SRC.FCH_VENC, 
					 I_Prioridad = SRC.PRIORIDAD, 
					 D_FecMod = @D_FecProceso,
					 B_Mora = SRC.C_MORA
		OUTPUT $action, SRC.I_RowID INTO @Tbl_outputProceso;
		
		SET IDENTITY_INSERT BD_OCEF_CtasPorCobrar.dbo.TC_Proceso OFF
		
		IF(@I_ProcesoID IS NULL)
		BEGIN
			SET @I_ProcesoID = (SELECT MAX(CAST(CUOTA_PAGO as int)) FROM TR_Cp_Des) + 1 
			DBCC CHECKIDENT([BD_OCEF_CtasPorCobrar.dbo.TC_Proceso], RESEED, @I_ProcesoID)
		END

		MERGE INTO BD_OCEF_CtasPorCobrar.dbo.TI_CtaDepo_Proceso AS TRG
		USING (SELECT CD.I_CtaDepositoID, TP_CD.* FROM TR_Cp_Des TP_CD
					INNER JOIN BD_OCEF_CtasPorCobrar.dbo.TC_CuentaDeposito CD ON CD.C_NumeroCuenta COLLATE DATABASE_DEFAULT = TP_CD.N_CTA_CTE COLLATE DATABASE_DEFAULT
					WHERE B_Migrable = 1 AND I_Anio BETWEEN @I_AnioIni AND @I_AnioFin AND (CUOTA_PAGO = @I_ProcesoID OR @I_ProcesoID IS NULL)
			   ) AS SRC
		ON TRG.I_ProcesoID = SRC.CUOTA_PAGO AND TRG.I_CtaDepositoID = SRC.I_CtaDepositoID
		WHEN NOT MATCHED BY TARGET THEN
			INSERT (I_CtaDepositoID, I_ProcesoID, B_Habilitado, B_Eliminado, D_FecCre)
			VALUES (I_CtaDepositoID, CUOTA_PAGO, 1, ELIMINADO, @D_FecProceso)
		WHEN MATCHED AND TRG.I_UsuarioCre IS NULL AND TRG.I_UsuarioMod IS NULL THEN
			UPDATE SET	B_Eliminado = ELIMINADO,
						D_FecMod = @D_FecProceso
		OUTPUT $action, SRC.I_RowID INTO @Tbl_outputCtas;


		MERGE INTO BD_OCEF_CtasPorCobrar.dbo.TC_CuentaDeposito_CategoriaPago AS TRG
		USING (SELECT DISTINCT CD.I_CtaDepositoID, TP_CD.I_CatPagoID FROM TR_Cp_Des TP_CD
				INNER JOIN BD_OCEF_CtasPorCobrar.dbo.TC_CuentaDeposito CD ON CD.C_NumeroCuenta COLLATE DATABASE_DEFAULT = TP_CD.N_CTA_CTE COLLATE DATABASE_DEFAULT
				WHERE B_Migrable = 1 AND I_Anio BETWEEN @I_AnioIni AND @I_AnioFin) AS SRC
		ON TRG.I_CatPagoID = SRC.I_CatPagoID AND TRG.I_CtaDepositoID = SRC.I_CtaDepositoID
		WHEN NOT MATCHED BY TARGET THEN
			INSERT (I_CtaDepositoID, I_CatPagoID, B_Habilitado, B_Eliminado, D_FecCre)
			VALUES (I_CtaDepositoID, I_CatPagoID, 1, 0, @D_FecProceso)
		WHEN MATCHED AND TRG.I_UsuarioCre IS NULL AND TRG.I_UsuarioMod IS NULL THEN
			UPDATE SET	D_FecMod = @D_FecProceso
		OUTPUT $action, SRC.I_CatPagoID INTO @Tbl_outputCtasCat;
		
		UPDATE	TR_Cp_Des 
		SET		B_Migrado = 1, 
				D_FecMigrado = @D_FecProceso
		WHERE	I_RowID IN (SELECT I_RowID FROM @Tbl_outputProceso)

		UPDATE	TR_Cp_Des 
		SET		B_Migrado = 0 
		WHERE	I_RowID IN (SELECT CD.I_RowID FROM TR_Cp_Des CD LEFT JOIN @Tbl_outputProceso O ON CD.I_RowID = o.I_RowID 
							WHERE CD.B_Migrable = 1 AND O.I_RowID IS NULL)

		MERGE TI_ObservacionRegistroTabla AS TRG
		USING 	(SELECT	@I_ObservID AS I_ObservID, @I_TablaID AS I_TablaID, I_RowID AS I_FilaTablaID, @D_FecProceso AS D_FecRegistro FROM TR_Cp_Des
				  WHERE	I_RowID IN (SELECT CD.I_RowID FROM TR_Cp_Des CD LEFT JOIN @Tbl_outputProceso O ON CD.I_RowID = o.I_RowID 
									WHERE CD.B_Migrable = 1 AND O.I_RowID IS NULL)
				) AS SRC
		ON TRG.I_ObservID = SRC.I_ObservID AND TRG.I_TablaID = SRC.I_TablaID AND TRG.I_FilaTablaID = SRC.I_FilaTablaID
		WHEN MATCHED THEN
			UPDATE SET D_FecRegistro = SRC.D_FecRegistro
		WHEN NOT MATCHED BY TARGET THEN
			INSERT (I_ObservID, I_TablaID, I_FilaTablaID, D_FecRegistro)
			VALUES (SRC.I_ObservID, SRC.I_TablaID, SRC.I_FilaTablaID, SRC.D_FecRegistro)
		WHEN NOT MATCHED BY SOURCE AND TRG.I_ObservID = @I_ObservID THEN
			DELETE;

		SET @I_Proc_Inserted = (SELECT COUNT(*) FROM @Tbl_outputProceso WHERE T_Action = 'INSERT')
		SET @I_Proc_Updated = (SELECT COUNT(*) FROM @Tbl_outputProceso WHERE T_Action = 'UPDATE')
		SET @I_Ctas_Inserted = (SELECT COUNT(*) FROM @Tbl_outputCtas WHERE T_Action = 'INSERT')
		SET @I_Ctas_Updated = (SELECT COUNT(*) FROM @Tbl_outputCtas WHERE T_Action = 'UPDATE')
		SET @I_CtaCat_Inserted = (SELECT COUNT(*) FROM @Tbl_outputCtasCat WHERE T_Action = 'INSERT')
		SET @I_CtaCat_Updated = (SELECT COUNT(*) FROM @Tbl_outputCtasCat WHERE T_Action = 'UPDATE')

		SELECT @I_Proc_Inserted AS proc_count_insert, @I_Proc_Updated AS proc_count_update, 
			   @I_Ctas_Inserted AS ctas_count_insert, @I_Ctas_Updated AS ctas_count_update,
			   @I_CtaCat_Inserted AS ctas_cat_count_insert, @I_CtaCat_Updated AS ctas_cat_count_update

		COMMIT TRANSACTION;

		SET @B_Resultado = 1
		SET @T_Message = CAST(@I_Proc_Inserted AS varchar) + ' | ' + CAST(@I_Proc_Updated AS varchar)
						 + ' | ' + CAST(@I_Ctas_Inserted AS varchar) + ' | ' + CAST(@I_Ctas_Updated AS varchar)
						 + ' | ' + CAST(@I_CtaCat_Inserted AS varchar) + ' | ' + CAST(@I_CtaCat_Updated AS varchar)
	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION;
		SET @B_Resultado = 0
		SET @T_Message = ERROR_MESSAGE() + ' LINE: ' + CAST(ERROR_LINE() AS varchar(10)) 
	END CATCH
END
GO



IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_IU_CopiarTablaConceptoDePago')
	DROP PROCEDURE [dbo].[USP_IU_CopiarTablaConceptoDePago]
GO

CREATE PROCEDURE USP_IU_CopiarTablaConceptoDePago
	@B_Resultado  bit output,
	@T_Message	  nvarchar(4000) OUTPUT	
AS
--declare @B_Resultado  bit,
--		@T_Message	  nvarchar(4000)
--exec USP_IU_CopiarTablaConceptoDePago @B_Resultado output, @T_Message output
--select @B_Resultado as resultado, @T_Message as mensaje
BEGIN
	DECLARE @I_CpPri int = 0
	DECLARE @I_Removidos int = 0
	DECLARE @I_Actualizados int = 0
	DECLARE @I_Insertados int = 0
	DECLARE @D_FecProceso datetime = GETDATE() 

	DECLARE @Tbl_output AS TABLE 
	(
		accion		varchar(20), 
		ID_CP		float,
		ELIMINADO	bit,
		B_Removido	bit,
		INS_CUOTA_PAGO	float,			INS_OBLIG_MORA	nvarchar(255),	
		INS_ANO			nvarchar(255), 	INS_P			nvarchar(255),
		INS_COD_RC		nvarchar(255),	INS_COD_ING		nvarchar(255),
		INS_TIPO_OBLIG	bit,			INS_CLASIFICAD	nvarchar(255),
		INS_CLASIFIC_5	nvarchar(255),	INS_ID_CP_AGRP	float,
		INS_AGRUPA		bit,			INS_NRO_PAGOS	float,
		INS_ID_CP_AFEC	float,			INS_PORCENTAJE	bit,
		INS_MONTO		float,			INS_DESCRIPCIO	nvarchar(255),
		INS_CALCULAR	nvarchar(255),	INS_GRADO		float,
		INS_TIP_ALUMNO	float,			INS_GRUPO_RC	nvarchar(255),
		INS_FRACCIONAB	bit,			INS_CONCEPTO_G	bit,
		INS_DOCUMENTO	nvarchar(255),	INS_MONTO_MIN	nvarchar(255),
		INS_DESCRIP_L	nvarchar(255),	INS_COD_DEP_PL	nvarchar(255),
		
		DEL_CUOTA_PAGO	float, 			DEL_ANO			nvarchar(255),		
		DEL_P			nvarchar(255),	DEL_COD_RC		nvarchar(255),
		DEL_COD_ING		nvarchar(255), 	DEL_TIPO_OBLIG	bit,		
		DEL_CLASIFICAD	nvarchar(255),	DEL_CLASIFIC_5	nvarchar(255),		
		DEL_ID_CP_AGRP	float,			DEL_AGRUPA		bit,		
		DEL_NRO_PAGOS	float,			DEL_ID_CP_AFEC	float,
		DEL_PORCENTAJE	bit,			DEL_MONTO		float,
		DEL_DESCRIPCIO	nvarchar(255),	DEL_CALCULAR	nvarchar(255),
		DEL_GRADO		float,			DEL_TIP_ALUMNO	float,
		DEL_GRUPO_RC	nvarchar(255),	DEL_FRACCIONAB	bit,
		DEL_CONCEPTO_G	bit,			DEL_DOCUMENTO	nvarchar(255),
		DEL_MONTO_MIN	nvarchar(255),	DEL_DESCRIP_L	nvarchar(255),
		DEL_COD_DEP_PL	nvarchar(255),	DEL_OBLIG_MORA	nvarchar(255)
	)

	BEGIN TRY 
		
		MERGE TR_Cp_Pri AS TRG
		USING [BD_OCEF_TemporalPagos].pregrado.cp_pri AS SRC
		ON	TRG.ID_CP = SRC.ID_CP 
			AND TRG.ELIMINADO = SRC.ELIMINADO
		WHEN MATCHED THEN
			UPDATE SET	TRG.CUOTA_PAGO = SRC.CUOTA_PAGO, TRG.ANO = SRC.ANO, TRG.P = SRC.P,
						TRG.COD_RC = SRC.COD_RC, TRG.COD_ING = SRC.COD_ING, TRG.TIPO_OBLIG = SRC.TIPO_OBLIG,
						TRG.CLASIFICAD = SRC.CLASIFICAD, TRG.CLASIFIC_5 = SRC.CLASIFIC_5, 
						TRG.AGRUPA = SRC.AGRUPA, TRG.NRO_PAGOS = SRC.NRO_PAGOS, TRG.ID_CP_AFEC = SRC.ID_CP_AFEC,
						TRG.PORCENTAJE = SRC.PORCENTAJE, TRG.MONTO = SRC.MONTO, TRG.ID_CP_AGRP = SRC.ID_CP_AGRP,
						TRG.DESCRIPCIO = SRC.DESCRIPCIO, TRG.CALCULAR = SRC.CALCULAR, TRG.GRADO = SRC.GRADO,
						TRG.TIP_ALUMNO = SRC.TIP_ALUMNO, TRG.GRUPO_RC = SRC.GRUPO_RC, TRG.FRACCIONAB = SRC.FRACCIONAB,
						TRG.CONCEPTO_G = SRC.CONCEPTO_G, TRG.DOCUMENTO = SRC.DOCUMENTO, TRG.MONTO_MIN = SRC.MONTO_MIN,
						TRG.DESCRIP_L = SRC.DESCRIP_L, TRG.COD_DEP_PL = SRC.COD_DEP_PL, TRG.OBLIG_MORA = SRC.OBLIG_MORA
		WHEN NOT MATCHED BY TARGET THEN
			INSERT (ID_CP, CUOTA_PAGO, ANO, P, COD_RC, COD_ING, TIPO_OBLIG, CLASIFICAD, CLASIFIC_5, ID_CP_AGRP, AGRUPA, NRO_PAGOS, ID_CP_AFEC, PORCENTAJE, MONTO, 
					ELIMINADO, DESCRIPCIO, CALCULAR, GRADO, TIP_ALUMNO, GRUPO_RC, FRACCIONAB, CONCEPTO_G, DOCUMENTO, MONTO_MIN, DESCRIP_L, COD_DEP_PL, OBLIG_MORA,
					D_FecCarga, I_ProcedenciaID)
			VALUES (ID_CP, CUOTA_PAGO, ANO, P, COD_RC, COD_ING, TIPO_OBLIG, CLASIFICAD, CLASIFIC_5, ID_CP_AGRP, AGRUPA, NRO_PAGOS, ID_CP_AFEC, PORCENTAJE, MONTO, 
					ELIMINADO, DESCRIPCIO, CALCULAR, GRADO, TIP_ALUMNO, GRUPO_RC, FRACCIONAB, CONCEPTO_G, CAST(DOCUMENTO as varchar), MONTO_MIN, CAST(DESCRIP_L as varchar), COD_DEP_PL, OBLIG_MORA,
					@D_FecProceso, 0)
		WHEN NOT MATCHED BY SOURCE THEN
			UPDATE SET TRG.B_Removido = 1, 
					   TRG.D_FecRemovido = @D_FecProceso
		OUTPUT	$ACTION, inserted.ID_CP, inserted.ELIMINADO, deleted.B_Removido, inserted.CUOTA_PAGO, inserted.OBLIG_MORA, inserted.ANO, inserted.P, 
				inserted.COD_RC, inserted.COD_ING, inserted.TIPO_OBLIG, inserted.CLASIFICAD, inserted.CLASIFIC_5, inserted.ID_CP_AGRP, inserted.AGRUPA, 
				inserted.NRO_PAGOS, inserted.ID_CP_AFEC, inserted.PORCENTAJE, inserted.MONTO, inserted.DESCRIPCIO, inserted.CALCULAR, inserted.GRADO, 
				inserted.TIP_ALUMNO, inserted.GRUPO_RC, inserted.FRACCIONAB, inserted.CONCEPTO_G, inserted.DOCUMENTO, inserted.MONTO_MIN, inserted.DESCRIP_L, 
				inserted.COD_DEP_PL, 
				deleted.CUOTA_PAGO, deleted.ANO, deleted.P, deleted.COD_RC, deleted.COD_ING, deleted.TIPO_OBLIG, deleted.CLASIFICAD, deleted.CLASIFIC_5, 
				deleted.ID_CP_AGRP, deleted.AGRUPA, deleted.NRO_PAGOS, deleted.ID_CP_AFEC, deleted.PORCENTAJE, deleted.MONTO, deleted.DESCRIPCIO, deleted.CALCULAR, 
				deleted.GRADO, deleted.TIP_ALUMNO, deleted.GRUPO_RC, deleted.FRACCIONAB, deleted.CONCEPTO_G, deleted.DOCUMENTO, deleted.MONTO_MIN, deleted.DESCRIP_L, 
				deleted.COD_DEP_PL, deleted.OBLIG_MORA INTO @Tbl_output;
		
		UPDATE	TR_Cp_Pri 
				SET	B_Actualizado = 0, B_Migrable = 1, D_FecMigrado = NULL, B_Migrado = 0,
					I_TipAluID = NULL, I_TipGradoID = NULL, I_TipOblID = NULL, I_TipCalcID = NULL, 
					I_TipPerID = NULL, I_DepID = NULL, I_TipGrpRc = NULL, I_CodIngID = NULL

		UPDATE	t_CpPri
		SET		t_CpPri.B_Actualizado = 1,
				t_CpPri.D_FecActualiza = @D_FecProceso
		FROM TR_Cp_Pri AS t_CpPri
		INNER JOIN 	@Tbl_output as t_out ON t_out.ID_CP = t_CpPri.ID_CP AND t_out.ELIMINADO = t_CpPri.ELIMINADO 
					AND t_out.accion = 'UPDATE' AND t_out.B_Removido = 0
		WHERE 
				t_out.INS_CUOTA_PAGO <> t_out.DEL_CUOTA_PAGO OR
				t_out.INS_ANO		 <> t_out.DEL_ANO		 OR
				t_out.INS_P			 <> t_out.DEL_P			 OR
				t_out.INS_COD_RC	 <> t_out.DEL_COD_RC	 OR
				t_out.INS_COD_ING	 <> t_out.DEL_COD_ING	 OR
				t_out.INS_TIPO_OBLIG <> t_out.DEL_TIPO_OBLIG OR
				t_out.INS_CLASIFICAD <> t_out.DEL_CLASIFICAD OR
				t_out.INS_CLASIFIC_5 <> t_out.DEL_CLASIFIC_5 OR
				t_out.INS_ID_CP_AGRP <> t_out.DEL_ID_CP_AGRP OR
				t_out.INS_AGRUPA	 <> t_out.DEL_AGRUPA	 OR
				t_out.INS_NRO_PAGOS	 <> t_out.DEL_NRO_PAGOS	 OR
				t_out.INS_ID_CP_AFEC <> t_out.DEL_ID_CP_AFEC OR
				t_out.INS_PORCENTAJE <> t_out.DEL_PORCENTAJE OR
				t_out.INS_MONTO		 <> t_out.DEL_MONTO		 OR
				t_out.INS_DESCRIPCIO <> t_out.DEL_DESCRIPCIO OR
				t_out.INS_CALCULAR	 <> t_out.DEL_CALCULAR	 OR
				t_out.INS_GRADO		 <> t_out.DEL_GRADO		 OR
				t_out.INS_TIP_ALUMNO <> t_out.DEL_TIP_ALUMNO OR
				t_out.INS_GRUPO_RC	 <> t_out.DEL_GRUPO_RC	 OR
				t_out.INS_FRACCIONAB <> t_out.DEL_FRACCIONAB OR
				t_out.INS_CONCEPTO_G <> t_out.DEL_CONCEPTO_G OR
				t_out.INS_DOCUMENTO  <> t_out.DEL_DOCUMENTO  OR
				t_out.INS_MONTO_MIN  <> t_out.DEL_MONTO_MIN  OR
				t_out.INS_DESCRIP_L  <> t_out.DEL_DESCRIP_L  OR
				t_out.INS_COD_DEP_PL <> t_out.DEL_COD_DEP_PL OR
				t_out.INS_OBLIG_MORA <> t_out.DEL_OBLIG_MORA


		SET @I_CpPri = (SELECT COUNT(*) FROM [BD_OCEF_TemporalPagos].pregrado.cp_pri)
		SET @I_Insertados = (SELECT COUNT(*) FROM @Tbl_output WHERE accion = 'INSERT')
		SET @I_Actualizados = (SELECT COUNT(*) FROM @Tbl_output WHERE accion = 'UPDATE' AND B_Removido = 0)
		SET @I_Removidos = (SELECT COUNT(*) FROM @Tbl_output WHERE accion = 'UPDATE' AND B_Removido = 1)

		SELECT @I_CpPri AS tot_concetoPago, @I_Insertados AS cant_inserted, @I_Actualizados as cant_updated, @I_Removidos as cant_removed, @D_FecProceso as fec_proceso
		
		SET @B_Resultado = 1
		SET @T_Message =  'Total: ' + CAST(@I_CpPri AS varchar) + '|Insertados: ' + CAST(@I_Insertados AS varchar) 
						+ '|Actualizados: ' + CAST(@I_Actualizados AS varchar) + '|Removidos: ' + CAST(@I_Removidos AS varchar)
	END TRY
	BEGIN CATCH
		SET @B_Resultado = 0
		SET @T_Message = ERROR_MESSAGE() + ' LINE: ' + CAST(ERROR_LINE() AS varchar(10)) 
	END CATCH
END
GO


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_U_MarcarConceptosPagoRepetidos')
	DROP PROCEDURE [dbo].[USP_U_MarcarConceptosPagoRepetidos]
GO

CREATE PROCEDURE USP_U_MarcarConceptosPagoRepetidos	
	@B_Resultado  bit output,
	@T_Message	  nvarchar(4000) OUTPUT	
AS
--declare @B_Resultado  bit,
--		@T_Message	  nvarchar(4000)
--exec USP_U_MarcarConceptosPagoRepetidos @B_Resultado output, @T_Message output
--select @B_Resultado as resultado, @T_Message as mensaje
BEGIN
	DECLARE @D_FecProceso datetime = GETDATE() 
	DECLARE @I_ObservID_activo int = 12
	DECLARE @I_ObservID_eliminado int = 13
	DECLARE @I_TablaID int = 3
	DECLARE @I_Observados_activos int = 0
	DECLARE @I_Observados_eliminados int = 0
	
	BEGIN TRY 
		UPDATE	TR_Cp_Pri
		SET		B_Migrable = 0,
				D_FecEvalua = @D_FecProceso
		WHERE	ID_CP IN (SELECT ID_CP FROM TR_Cp_Pri WHERE ELIMINADO = 0 GROUP BY ID_CP HAVING COUNT(ID_CP) > 1
						  UNION
						  SELECT ID_CP FROM TR_Cp_Pri WHERE ELIMINADO = 1 GROUP BY ID_CP HAVING COUNT(ID_CP) > 1)

		MERGE TI_ObservacionRegistroTabla AS TRG
		USING (SELECT @I_ObservID_activo AS I_ObservID, @I_TablaID AS I_TablaID, I_RowID AS I_FilaTablaID, @D_FecProceso AS D_FecRegistro 
				 FROM TR_Cp_Pri 
				 WHERE ID_CP IN (SELECT ID_CP FROM TR_Cp_Pri WHERE ELIMINADO = 0 GROUP BY ID_CP HAVING COUNT(ID_CP) > 1)
			  ) AS SRC
		ON TRG.I_ObservID = SRC.I_ObservID AND TRG.I_TablaID = SRC.I_TablaID AND TRG.I_FilaTablaID = SRC.I_FilaTablaID
		WHEN MATCHED THEN
			UPDATE SET D_FecRegistro = SRC.D_FecRegistro
		WHEN NOT MATCHED BY TARGET THEN
			INSERT (I_ObservID, I_TablaID, I_FilaTablaID, D_FecRegistro)
			VALUES (SRC.I_ObservID, SRC.I_TablaID, SRC.I_FilaTablaID, SRC.D_FecRegistro)
		WHEN NOT MATCHED BY SOURCE AND TRG.I_ObservID = @I_ObservID_activo THEN
			DELETE;

		MERGE TI_ObservacionRegistroTabla AS TRG
		USING (SELECT @I_ObservID_eliminado AS I_ObservID, @I_TablaID AS I_TablaID, I_RowID AS I_FilaTablaID, @D_FecProceso AS D_FecRegistro 
				 FROM TR_Cp_Pri 
				 WHERE ID_CP IN (SELECT ID_CP FROM TR_Cp_Pri WHERE ELIMINADO = 1 GROUP BY ID_CP HAVING COUNT(ID_CP) > 1)
			  ) AS SRC
		ON TRG.I_ObservID = SRC.I_ObservID AND TRG.I_TablaID = SRC.I_TablaID AND TRG.I_FilaTablaID = SRC.I_FilaTablaID
		WHEN MATCHED THEN
			UPDATE SET D_FecRegistro = SRC.D_FecRegistro
		WHEN NOT MATCHED BY TARGET THEN
			INSERT (I_ObservID, I_TablaID, I_FilaTablaID, D_FecRegistro)
			VALUES (SRC.I_ObservID, SRC.I_TablaID, SRC.I_FilaTablaID, SRC.D_FecRegistro)
		WHEN NOT MATCHED BY SOURCE AND TRG.I_ObservID = @I_ObservID_eliminado THEN
			DELETE;

		SET @I_Observados_activos = (SELECT COUNT(*) FROM TI_ObservacionRegistroTabla WHERE I_ObservID = @I_ObservID_activo AND I_TablaID = @I_TablaID)
		SET @I_Observados_eliminados = (SELECT COUNT(*) FROM TI_ObservacionRegistroTabla WHERE I_ObservID = @I_ObservID_eliminado AND I_TablaID = @I_TablaID)

		SET @B_Resultado = 1
		SET @T_Message = CAST(@I_Observados_activos AS varchar) + ' con estado activo |' + CAST(@I_ObservID_eliminado AS varchar) +  ' con estado eliminado'
	END TRY
	BEGIN CATCH
		SET @B_Resultado = 0
		SET @T_Message = ERROR_MESSAGE() + ' LINE: ' + CAST(ERROR_LINE() AS varchar(10)) 
	END CATCH
END
GO


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_U_MarcarConceptosPagoObligSinAnioAsignado')
	DROP PROCEDURE [dbo].[USP_U_MarcarConceptosPagoObligSinAnioAsignado]
GO

CREATE PROCEDURE USP_U_MarcarConceptosPagoObligSinAnioAsignado	
	@B_Resultado  bit output,
	@T_Message	  nvarchar(4000) OUTPUT	
AS
--declare @B_Resultado  bit,
--		@T_Message	  nvarchar(4000)
--exec USP_U_MarcarConceptosPagoObligSinAnioAsignado @B_Resultado output, @T_Message output
--select @B_Resultado as resultado, @T_Message as mensaje
BEGIN
	DECLARE @D_FecProceso datetime = GETDATE() 
	DECLARE @I_ObservID_sinAnio int = 14
	DECLARE @I_ObservID_AnioDif int = 15
	DECLARE @I_TablaID int = 3
	DECLARE @I_Observados_sinAnio int = 0
	DECLARE @I_Observados_AnioDif int = 0
	
	BEGIN TRY 
		UPDATE	TR_Cp_Pri
		SET		B_Migrable = 0,
				D_FecEvalua = @D_FecProceso
		WHERE	(ANO IS NULL OR ANO = 0) AND TIPO_OBLIG = 1

		MERGE TI_ObservacionRegistroTabla AS TRG
		USING (SELECT @I_ObservID_sinAnio AS I_ObservID, @I_TablaID AS I_TablaID, I_RowID AS I_FilaTablaID, @D_FecProceso AS D_FecRegistro 
				 FROM TR_Cp_Pri WHERE (ANO IS NULL OR ANO = 0) AND TIPO_OBLIG = 1
			  ) AS SRC
		ON TRG.I_ObservID = SRC.I_ObservID AND TRG.I_TablaID = SRC.I_TablaID AND TRG.I_FilaTablaID = SRC.I_FilaTablaID
		WHEN MATCHED THEN
			UPDATE SET D_FecRegistro = SRC.D_FecRegistro
		WHEN NOT MATCHED BY TARGET THEN
			INSERT (I_ObservID, I_TablaID, I_FilaTablaID, D_FecRegistro)
			VALUES (SRC.I_ObservID, SRC.I_TablaID, SRC.I_FilaTablaID, SRC.D_FecRegistro)
		WHEN NOT MATCHED BY SOURCE AND TRG.I_ObservID = @I_ObservID_sinAnio THEN
			DELETE;

		UPDATE	TR_Cp_Pri
		SET		B_Migrable = 0,
				D_FecEvalua = @D_FecProceso
				--T_Observacion = ISNULL(T_Observacion, '') + '012 - NO COINCIDE AÑO : ('+ CONVERT(varchar, @D_FecProceso, 112) + '). Año del concepto de pago de obligacion no coincide con el año de la cuota de pagos.|'
		WHERE	NOT EXISTS (SELECT * FROM TR_Cp_Des WHERE I_Anio = TR_Cp_Pri.ANO) AND TIPO_OBLIG = 1

		MERGE TI_ObservacionRegistroTabla AS TRG
		USING (SELECT @I_ObservID_sinAnio AS I_ObservID, @I_TablaID AS I_TablaID, I_RowID AS I_FilaTablaID, @D_FecProceso AS D_FecRegistro 
				 FROM TR_Cp_Pri WHERE NOT EXISTS (SELECT * FROM TR_Cp_Des WHERE I_Anio = TR_Cp_Pri.ANO) AND TIPO_OBLIG = 1
			  ) AS SRC
		ON TRG.I_ObservID = SRC.I_ObservID AND TRG.I_TablaID = SRC.I_TablaID AND TRG.I_FilaTablaID = SRC.I_FilaTablaID
		WHEN MATCHED THEN
			UPDATE SET D_FecRegistro = SRC.D_FecRegistro
		WHEN NOT MATCHED BY TARGET THEN
			INSERT (I_ObservID, I_TablaID, I_FilaTablaID, D_FecRegistro)
			VALUES (SRC.I_ObservID, SRC.I_TablaID, SRC.I_FilaTablaID, SRC.D_FecRegistro)
		WHEN NOT MATCHED BY SOURCE AND TRG.I_ObservID = @I_ObservID_sinAnio THEN
			DELETE;

		SET @I_Observados_sinAnio = (SELECT COUNT(*) FROM TI_ObservacionRegistroTabla WHERE I_ObservID = @I_ObservID_sinAnio AND I_TablaID = @I_TablaID)
		SET @I_Observados_AnioDif = (SELECT COUNT(*) FROM TI_ObservacionRegistroTabla WHERE I_ObservID = @I_ObservID_AnioDif AND I_TablaID = @I_TablaID)

		SET @B_Resultado = 1
		SET @T_Message = CAST(@I_Observados_sinAnio AS varchar) + ' sin año asignado |' + CAST(@I_Observados_AnioDif AS varchar) +  ' año no coincide con cuota de pago.'
	END TRY
	BEGIN CATCH
		SET @B_Resultado = 0
		SET @T_Message = ERROR_MESSAGE() + ' LINE: ' + CAST(ERROR_LINE() AS varchar(10)) 
	END CATCH
END
GO


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_U_MarcarConceptosPagoObligSinPeriodoAsignado')
	DROP PROCEDURE [dbo].[USP_U_MarcarConceptosPagoObligSinPeriodoAsignado]
GO

CREATE PROCEDURE USP_U_MarcarConceptosPagoObligSinPeriodoAsignado	
	@B_Resultado  bit output,
	@T_Message	  nvarchar(4000) OUTPUT	
AS
--declare @B_Resultado  bit,
--		@T_Message	  nvarchar(4000)
--exec USP_U_MarcarConceptosPagoObligSinPeriodoAsignado @B_Resultado output, @T_Message output
--select @B_Resultado as resultado, @T_Message as mensaje
BEGIN
	DECLARE @D_FecProceso datetime = GETDATE() 
	DECLARE @I_ObservID_sinPer int = 16
	DECLARE @I_ObservID_PerDif int = 17
	DECLARE @I_TablaID int = 3
	DECLARE @I_Observados_sinPer int = 0
	DECLARE @I_Observados_PerDif int = 0
	
	BEGIN TRY 
		UPDATE	TR_Cp_Pri
		SET		B_Migrable = 0,
				D_FecEvalua = @D_FecProceso
		WHERE	(P IS NULL OR P = '') AND TIPO_OBLIG = 1

		MERGE TI_ObservacionRegistroTabla AS TRG
		USING (SELECT @I_ObservID_sinPer AS I_ObservID, @I_TablaID AS I_TablaID, I_RowID AS I_FilaTablaID, @D_FecProceso AS D_FecRegistro 
				 FROM TR_Cp_Pri WHERE (P IS NULL OR P = '') AND TIPO_OBLIG = 1
			  ) AS SRC
		ON TRG.I_ObservID = SRC.I_ObservID AND TRG.I_TablaID = SRC.I_TablaID AND TRG.I_FilaTablaID = SRC.I_FilaTablaID
		WHEN MATCHED THEN
			UPDATE SET D_FecRegistro = SRC.D_FecRegistro
		WHEN NOT MATCHED BY TARGET THEN
			INSERT (I_ObservID, I_TablaID, I_FilaTablaID, D_FecRegistro)
			VALUES (SRC.I_ObservID, SRC.I_TablaID, SRC.I_FilaTablaID, SRC.D_FecRegistro)
		WHEN NOT MATCHED BY SOURCE AND TRG.I_ObservID = @I_ObservID_sinPer THEN
			DELETE;

		UPDATE	TR_Cp_Pri
		SET		B_Migrable = 0,
				D_FecEvalua = @D_FecProceso
		WHERE	NOT EXISTS (SELECT * FROM TR_Cp_Des WHERE P = TR_Cp_Pri.P) AND TIPO_OBLIG = 1

		MERGE TI_ObservacionRegistroTabla AS TRG
		USING (SELECT @I_ObservID_PerDif AS I_ObservID, @I_TablaID AS I_TablaID, I_RowID AS I_FilaTablaID, @D_FecProceso AS D_FecRegistro 
				 FROM TR_Cp_Pri WHERE NOT EXISTS (SELECT * FROM TR_Cp_Des WHERE P = TR_Cp_Pri.P) AND TIPO_OBLIG = 1
			  ) AS SRC
		ON TRG.I_ObservID = SRC.I_ObservID AND TRG.I_TablaID = SRC.I_TablaID AND TRG.I_FilaTablaID = SRC.I_FilaTablaID
		WHEN MATCHED THEN
			UPDATE SET D_FecRegistro = SRC.D_FecRegistro
		WHEN NOT MATCHED BY TARGET THEN
			INSERT (I_ObservID, I_TablaID, I_FilaTablaID, D_FecRegistro)
			VALUES (SRC.I_ObservID, SRC.I_TablaID, SRC.I_FilaTablaID, SRC.D_FecRegistro)
		WHEN NOT MATCHED BY SOURCE AND TRG.I_ObservID = @I_ObservID_PerDif THEN
			DELETE;

		SET @I_Observados_sinPer = (SELECT COUNT(*) FROM TI_ObservacionRegistroTabla WHERE I_ObservID = @I_ObservID_sinPer AND I_TablaID = @I_TablaID)
		SET @I_Observados_PerDif = (SELECT COUNT(*) FROM TI_ObservacionRegistroTabla WHERE I_ObservID = @I_ObservID_PerDif AND I_TablaID = @I_TablaID)

		SET @B_Resultado = 1
		SET @T_Message = CAST(@I_Observados_sinPer AS varchar) + ' sin periodo asignado |' + CAST(@I_Observados_PerDif AS varchar) +  ' periodo no coincide con cuota de pago.'
	END TRY
	BEGIN CATCH
		SET @B_Resultado = 0
		SET @T_Message = ERROR_MESSAGE() + ' LINE: ' + CAST(ERROR_LINE() AS varchar(10)) 
	END CATCH
END
GO


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_U_MarcarConceptosPagoObligSinCuotaPago')
	DROP PROCEDURE [dbo].[USP_U_MarcarConceptosPagoObligSinCuotaPago]
GO

CREATE PROCEDURE USP_U_MarcarConceptosPagoObligSinCuotaPago	
	@B_Resultado  bit output,
	@T_Message	  nvarchar(4000) OUTPUT	
AS
--declare @B_Resultado  bit,
--		@T_Message	  nvarchar(4000)
--exec USP_U_MarcarConceptosPagoObligSinCuotaPago @B_Resultado output, @T_Message output
--select @B_Resultado as resultado, @T_Message as mensaje
BEGIN
	DECLARE @D_FecProceso datetime = GETDATE() 
	DECLARE @I_ObservID_sinCuota int = 18
	DECLARE @I_ObservID_CuotaNoM int = 19
	DECLARE @I_TablaID int = 3
	DECLARE @I_Observados_sinCuota int = 0
	DECLARE @I_Observados_CuotaNoM int = 0
	
	BEGIN TRY 
		UPDATE	TR_Cp_Pri
		SET		B_Migrable = 0,
				D_FecEvalua = @D_FecProceso
		WHERE	NOT EXISTS (SELECT * FROM TR_Cp_Des WHERE CUOTA_PAGO = TR_Cp_Pri.CUOTA_PAGO) AND TIPO_OBLIG = 1

		MERGE TI_ObservacionRegistroTabla AS TRG
		USING (SELECT @I_ObservID_sinCuota AS I_ObservID, @I_TablaID AS I_TablaID, I_RowID AS I_FilaTablaID, @D_FecProceso AS D_FecRegistro 
				 FROM TR_Cp_Pri WHERE NOT EXISTS (SELECT * FROM TR_Cp_Des WHERE CUOTA_PAGO = TR_Cp_Pri.CUOTA_PAGO) AND TIPO_OBLIG = 1
			  ) AS SRC
		ON TRG.I_ObservID = SRC.I_ObservID AND TRG.I_TablaID = SRC.I_TablaID AND TRG.I_FilaTablaID = SRC.I_FilaTablaID
		WHEN MATCHED THEN
			UPDATE SET D_FecRegistro = SRC.D_FecRegistro
		WHEN NOT MATCHED BY TARGET THEN
			INSERT (I_ObservID, I_TablaID, I_FilaTablaID, D_FecRegistro)
			VALUES (SRC.I_ObservID, SRC.I_TablaID, SRC.I_FilaTablaID, SRC.D_FecRegistro)
		WHEN NOT MATCHED BY SOURCE AND TRG.I_ObservID = @I_ObservID_sinCuota THEN
			DELETE;


		UPDATE	TR_Cp_Pri
		SET		B_Migrable = 0,
				D_FecEvalua = @D_FecProceso
		WHERE	EXISTS (SELECT * FROM TR_Cp_Des WHERE CUOTA_PAGO = TR_Cp_Pri.CUOTA_PAGO AND B_Migrable = 0)

		MERGE TI_ObservacionRegistroTabla AS TRG
		USING (SELECT @I_ObservID_CuotaNoM AS I_ObservID, @I_TablaID AS I_TablaID, I_RowID AS I_FilaTablaID, @D_FecProceso AS D_FecRegistro 
				 FROM TR_Cp_Pri WHERE EXISTS (SELECT * FROM TR_Cp_Des WHERE CUOTA_PAGO = TR_Cp_Pri.CUOTA_PAGO AND B_Migrable = 0)
			  ) AS SRC
		ON TRG.I_ObservID = SRC.I_ObservID AND TRG.I_TablaID = SRC.I_TablaID AND TRG.I_FilaTablaID = SRC.I_FilaTablaID
		WHEN MATCHED THEN
			UPDATE SET D_FecRegistro = SRC.D_FecRegistro
		WHEN NOT MATCHED BY TARGET THEN
			INSERT (I_ObservID, I_TablaID, I_FilaTablaID, D_FecRegistro)
			VALUES (SRC.I_ObservID, SRC.I_TablaID, SRC.I_FilaTablaID, SRC.D_FecRegistro)
		WHEN NOT MATCHED BY SOURCE AND TRG.I_ObservID = @I_ObservID_CuotaNoM THEN
			DELETE;

		SET @I_Observados_sinCuota = (SELECT COUNT(*) FROM TI_ObservacionRegistroTabla WHERE I_ObservID = @I_ObservID_sinCuota AND I_TablaID = @I_TablaID)
		SET @I_Observados_CuotaNoM = (SELECT COUNT(*) FROM TI_ObservacionRegistroTabla WHERE I_ObservID = @I_ObservID_CuotaNoM AND I_TablaID = @I_TablaID)

		SET @B_Resultado = 1
		SET @T_Message = CAST(@I_Observados_sinCuota AS varchar) + ' sin cuota de pago |' + CAST(@I_Observados_CuotaNoM AS varchar) +  ' con cuota de pago sin migrar.'
	END TRY
	BEGIN CATCH
		SET @B_Resultado = 0
		SET @T_Message = ERROR_MESSAGE() + ' LINE: ' + CAST(ERROR_LINE() AS varchar(10)) 
	END CATCH
END
GO


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_U_AsignarIdEquivalenciasConceptoPago')
	DROP PROCEDURE [dbo].[USP_U_AsignarIdEquivalenciasConceptoPago]
GO

CREATE PROCEDURE [dbo].[USP_U_AsignarIdEquivalenciasConceptoPago]
	@B_Resultado  bit output,
	@T_Message	  nvarchar(4000) OUTPUT	
AS
--declare @B_Resultado  bit,
--		@T_Message	  nvarchar(4000)
--exec USP_U_AsignarIdEquivalenciasConceptoPago @B_Resultado output, @T_Message output
--select @B_Resultado as resultado, @T_Message as mensaje
BEGIN
	DECLARE @D_FecProceso datetime = GETDATE() 
	
	BEGIN TRY 
		DECLARE @tipo_alumno AS TABLE (I_TipAluID int, C_CodTipAlu varchar(5), T_Descripcion varchar(50))
		DECLARE @tipo_grado	 AS TABLE (I_TipGradoID int, C_CodTipGrado varchar(5), T_Descripcion varchar(50))
		DECLARE @tipo_obligacion AS TABLE (I_TipOblID int, C_CodTipObl varchar(5), T_Descripcion varchar(50))
		DECLARE @tipo_calculado AS TABLE (I_TipCalcID int, C_CodCalc varchar(5), T_Descripcion varchar(50))
		DECLARE @tipo_periodo	AS TABLE (I_TipPerID int, C_CodTipPer varchar(5), T_Descripcion varchar(50))
		DECLARE @grupo_rc	AS TABLE (I_TipGrpRc int, C_CodGrpRc varchar(5), T_Descripcion varchar(50))
		DECLARE @codigo_ing AS TABLE (I_CodIngID int, C_CodIng varchar(5), T_Descripcion varchar(50))
		DECLARE @unfv_dep	AS TABLE (I_DepID int, C_CodDep varchar(50), C_DepCodPl varchar(50))

		INSERT INTO @tipo_alumno (I_TipAluID, C_CodTipAlu, T_Descripcion)
			SELECT I_OpcionID, T_OpcionCod, T_OpcionDesc FROM BD_OCEF_CtasPorCobrar.dbo.TC_CatalogoOpcion WHERE I_ParametroID = 1

		INSERT INTO @tipo_grado (I_TipGradoID, C_CodTipGrado, T_Descripcion)
			SELECT I_OpcionID, T_OpcionCod, T_OpcionDesc FROM BD_OCEF_CtasPorCobrar.dbo.TC_CatalogoOpcion WHERE I_ParametroID = 2

		INSERT INTO @tipo_obligacion (I_TipOblID, C_CodTipObl, T_Descripcion)
			SELECT I_OpcionID, T_OpcionCod, T_OpcionDesc FROM BD_OCEF_CtasPorCobrar.dbo.TC_CatalogoOpcion WHERE I_ParametroID = 3

		INSERT INTO @tipo_calculado (I_TipCalcID, C_CodCalc, T_Descripcion)
			SELECT I_OpcionID, T_OpcionCod, T_OpcionDesc FROM BD_OCEF_CtasPorCobrar.dbo.TC_CatalogoOpcion WHERE I_ParametroID = 4

		INSERT INTO @tipo_periodo (I_TipPerID, C_CodTipPer, T_Descripcion)
			SELECT I_OpcionID, T_OpcionCod, T_OpcionDesc FROM BD_OCEF_CtasPorCobrar.dbo.TC_CatalogoOpcion WHERE I_ParametroID = 5

		INSERT INTO @grupo_rc (I_TipGrpRc, C_CodGrpRc, T_Descripcion)
			SELECT I_OpcionID, T_OpcionCod, T_OpcionDesc FROM BD_OCEF_CtasPorCobrar.dbo.TC_CatalogoOpcion WHERE I_ParametroID = 6

		INSERT INTO @codigo_ing (I_CodIngID, C_CodIng, T_Descripcion)
			SELECT I_OpcionID, T_OpcionCod, T_OpcionDesc FROM BD_OCEF_CtasPorCobrar.dbo.TC_CatalogoOpcion WHERE I_ParametroID = 7

		INSERT INTO @unfv_dep (I_DepID, C_CodDep, C_DepCodPl)
			SELECT I_DependenciaID, C_DepCod, C_DepCodPl FROM BD_OCEF_CtasPorCobrar.dbo.TC_DependenciaUNFV

		UPDATE	tb_pri  
		SET		tb_pri.I_TipAluID	= t_alu.I_TipAluID,
				tb_pri.I_TipGradoID = t_grd.I_TipGradoID,
				tb_pri.I_TipOblID	= t_obl.I_TipOblID,
				tb_pri.I_TipCalcID	= t_clc.I_TipCalcID,
				tb_pri.I_TipPerID	= t_per.I_TipPerID,
				tb_pri.I_DepID		= dep.I_DepID,
				tb_pri.I_TipGrpRc	= t_grc.I_TipGrpRc,
				tb_pri.I_CodIngID	= c_ing.I_CodIngID
		FROM	TR_Cp_Pri tb_pri
				LEFT JOIN @tipo_alumno t_alu ON tb_pri.TIP_ALUMNO = CAST(t_alu.C_CodTipAlu AS float)
				LEFT JOIN @tipo_grado t_grd ON tb_pri.GRADO = CAST(t_grd.C_CodTipGrado AS float)
				LEFT JOIN @tipo_obligacion t_obl ON tb_pri.TIPO_OBLIG = CAST(t_obl.C_CodTipObl AS bit)
				LEFT JOIN @tipo_calculado t_clc ON tb_pri.CALCULAR = t_clc.C_CodCalc
				LEFT JOIN @tipo_periodo t_per ON tb_pri.P = t_per.C_CodTipPer
				LEFT JOIN @grupo_rc t_grc ON tb_pri.GRUPO_RC = t_grc.C_CodGrpRc
				LEFT JOIN @codigo_ing c_ing ON tb_pri.COD_ING = c_ing.C_CodIng
				LEFT JOIN @unfv_dep dep ON tb_pri.COD_DEP_PL = dep.C_DepCodPl AND LEN(dep.C_DepCodPl) > 0
		
		SELECT * FROM TR_Cp_Pri

		SET @B_Resultado = 1
		SET @T_Message = 'Ok'
	END TRY
	BEGIN CATCH
		SET @B_Resultado = 0
		SET @T_Message = ERROR_MESSAGE() + ' LINE: ' + CAST(ERROR_LINE() AS varchar(10)) 
	END CATCH
END
GO


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_IU_GrabarTablaCatalogoConceptos')
	DROP PROCEDURE [dbo].[USP_IU_GrabarTablaCatalogoConceptos]
GO

CREATE PROCEDURE USP_IU_GrabarTablaCatalogoConceptos	
	@B_Resultado  bit output,
	@T_Message	  nvarchar(4000) OUTPUT	
AS
--declare @B_Resultado  bit,
--		@T_Message	  nvarchar(4000)
--exec USP_IU_GrabarTablaCatalogoConceptos @B_Resultado output, @T_Message output
--select @B_Resultado as resultado, @T_Message as mensaje
BEGIN
	IF NOT EXISTS (SELECT * FROM BD_OCEF_CtasPorCobrar.dbo.TC_Concepto WHERE I_ConceptoID = 0)
	BEGIN
		SET IDENTITY_INSERT BD_OCEF_CtasPorCobrar.dbo.TC_Concepto ON;
		INSERT INTO BD_OCEF_CtasPorCobrar.dbo.TC_Concepto (I_ConceptoID, T_ConceptoDesc, B_EsObligacion, B_Habilitado, B_Eliminado)
													VALUES (0, 'CONCEPTO MIGRADO', 1, 1, 0);
		SET IDENTITY_INSERT BD_OCEF_CtasPorCobrar.dbo.TC_Concepto OFF;
	END

	SET @B_Resultado = 1
	SET @T_Message = 'Ok'
END
GO


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_IU_MigrarDataConceptoPagoObligacionesCtasPorCobrar')
	DROP PROCEDURE [dbo].[USP_IU_MigrarDataConceptoPagoObligacionesCtasPorCobrar]
GO

CREATE PROCEDURE USP_IU_MigrarDataConceptoPagoObligacionesCtasPorCobrar
	@I_ProcesoID	  int = NULL,
	@I_AnioIni	  int = NULL,
	@I_AnioFin	  int = NULL,
	@B_Resultado  bit output,
	@T_Message	  nvarchar(4000) OUTPUT	
AS
--declare @B_Resultado  bit, @I_ProcesoID int, @I_AnioIni int, @I_AnioFin int, @T_Message	  nvarchar(4000)
--exec USP_IU_MigrarDataConceptoPagoObligacionesCtasPorCobrar @I_ProcesoID = null, @I_AnioIni = null, @I_AnioFin = null, @B_Resultado = @B_Resultado output, @T_Message = @T_Message output
--select @B_Resultado as resultado, @T_Message as mensaje
BEGIN
	DECLARE @D_FecProceso datetime = GETDATE() 
	DECLARE @I_ConceptoPago_Inserted int = 0
	DECLARE @I_ConceptoPago_Updated int = 0
	DECLARE @Tbl_outputConceptosPago AS TABLE (T_Action varchar(20), I_RowID int)
	DECLARE @I_ObservID int = 20
	DECLARE @I_TablaID int = 3

	BEGIN TRANSACTION;
	BEGIN TRY 
		SET @I_AnioIni = (SELECT ISNULL(@I_AnioIni, 0))
		SET @I_AnioFin = (SELECT ISNULL(@I_AnioFin, 3000))
	
		SET IDENTITY_INSERT BD_OCEF_CtasPorCobrar.dbo.TI_ConceptoPago ON;

		MERGE INTO  BD_OCEF_CtasPorCobrar.dbo.TI_ConceptoPago AS TRG
		USING (SELECT * FROM TR_Cp_Pri 
				WHERE B_Migrable = 1 AND TIPO_OBLIG = 1 AND (CUOTA_PAGO = @I_ProcesoID OR @I_ProcesoID IS NULL) AND ANO BETWEEN @I_AnioIni AND @I_AnioFin
			  ) AS SRC
		ON TRG.I_ConcPagID = SRC.ID_CP
		WHEN NOT MATCHED BY TARGET THEN 
			INSERT (I_ConcPagID, I_ProcesoID, I_ConceptoID, T_ConceptoPagoDesc, B_Fraccionable, B_ConceptoGeneral, B_AgrupaConcepto, I_AlumnosDestino, 
					I_GradoDestino, I_TipoObligacion, T_Clasificador, C_CodTasa, B_Calculado, I_Calculado, B_AnioPeriodo, I_Anio, I_Periodo, B_Especialidad, 
					C_CodRc, B_Dependencia, C_DepCod, B_GrupoCodRc, I_GrupoCodRc, B_ModalidadIngreso, I_ModalidadIngresoID, B_ConceptoAgrupa, I_ConceptoAgrupaID, 
					B_ConceptoAfecta, I_ConceptoAfectaID, N_NroPagos, B_Porcentaje, C_Moneda, M_Monto, M_MontoMinimo, T_DescripcionLarga, T_Documento, B_Mora, 
					B_Migrado, B_Habilitado, B_Eliminado, I_TipoDescuentoID, B_EsPagoMatricula, B_EsPagoExtmp)
			VALUES (SRC.ID_CP, SRC.CUOTA_PAGO, 0, SRC.DESCRIPCIO, SRC.FRACCIONAB, SRC.CONCEPTO_G, SRC.AGRUPA, SRC.I_TipAluID, SRC.I_TipGradoID, SRC.I_TipOblID, 
					SRC.CLASIFICAD, SRC.CLASIFIC_5, CASE WHEN SRC.I_TipCalcID IS NULL THEN 0 ELSE 1 END, SRC.I_TipCalcID, CASE CAST(SRC.ANO AS int) WHEN 0 THEN 0 ELSE 1 END, SRC.ANO, SRC.I_TipPerID, 
					CASE LEN(LTRIM(RTRIM(SRC.COD_RC))) WHEN 0 THEN 0 ELSE 1 END, CASE LEN(LTRIM(RTRIM(SRC.COD_RC))) WHEN 0 THEN NULL ELSE SRC.COD_RC END, 
					CASE LEN(LTRIM(RTRIM(SRC.COD_DEP_PL))) WHEN 0 THEN 0 ELSE 1 END, SRC.I_DepID, CASE WHEN SRC.I_TipGrpRc IS NULL THEN 0 ELSE 1 END, SRC.I_TipGrpRc, 
					CASE WHEN SRC.I_CodIngID IS NULL THEN 0 ELSE 1 END, SRC.I_CodIngID, CASE SRC.ID_CP_AGRP WHEN 0 THEN 0 ELSE 1 END, 
					CASE SRC.ID_CP_AGRP WHEN 0 THEN NULL ELSE SRC.ID_CP_AGRP END, CASE SRC.ID_CP_AFEC WHEN 0 THEN 0 ELSE 1 END,
					CASE SRC.ID_CP_AFEC WHEN 0 THEN NULL ELSE SRC.ID_CP_AFEC END, SRC.NRO_PAGOS, SRC.PORCENTAJE, 'PEN', SRC.MONTO, 
					CAST(REPLACE(SRC.MONTO_MIN, ',', '.') as float), SRC.DESCRIP_L, SRC.DOCUMENTO, 
					SRC.OBLIG_MORA,
					1, 1, SRC.ELIMINADO, NULL, NULL, NULL)
		WHEN MATCHED AND TRG.B_Migrado = 1 AND TRG.I_UsuarioMod IS NULL THEN 
			 UPDATE SET T_ConceptoPagoDesc = SRC.DESCRIPCIO, 
					 B_Fraccionable = SRC.FRACCIONAB, 
					 B_ConceptoGeneral = SRC.CONCEPTO_G,
					 B_AgrupaConcepto = SRC.AGRUPA, 
					 I_AlumnosDestino = SRC.I_TipAluID, 
					 I_GradoDestino = SRC.I_TipOblID, 
					 T_Clasificador = SRC.CLASIFICAD, 
					 C_CodTasa = SRC.CLASIFIC_5, 
					 B_Calculado = SRC.CALCULAR, 
					 I_Calculado = SRC.I_TipCalcID, 
					 B_AnioPeriodo = (CASE CAST(SRC.ANO AS int) WHEN 0 THEN 0 ELSE 1 END), 
					 I_Anio = SRC.ANO, 
					 I_Periodo = SRC.I_TipPerID, 
					 B_Especialidad = (CASE LEN(LTRIM(RTRIM(SRC.COD_RC))) WHEN 0 THEN 0 ELSE 1 END), 
					 C_CodRc = (CASE LEN(LTRIM(RTRIM(SRC.COD_RC))) WHEN 0 THEN NULL ELSE SRC.COD_RC END), 
					 B_Dependencia = (CASE LEN(LTRIM(RTRIM(SRC.I_DepID))) WHEN 0 THEN 0 ELSE 1 END), 
					 C_DepCod = I_DepID, 
					 B_GrupoCodRc = (CASE WHEN SRC.I_TipGrpRc IS NULL THEN 0 ELSE 1 END), 
					 I_GrupoCodRc = SRC.I_TipGrpRc, 
					 B_ModalidadIngreso = (CASE WHEN SRC.I_CodIngID IS NULL THEN 0 ELSE 1 END), 
					 I_ModalidadIngresoID = SRC.I_CodIngID, 
					 B_ConceptoAgrupa = (CASE SRC.ID_CP_AGRP WHEN 0 THEN 0 ELSE 1 END), 
					 I_ConceptoAgrupaID = SRC.ID_CP_AGRP,
					 B_ConceptoAfecta = (CASE SRC.ID_CP_AFEC WHEN 0 THEN 0 ELSE 1 END), 
					 I_ConceptoAfectaID = (CASE SRC.ID_CP_AFEC WHEN 0 THEN NULL ELSE SRC.ID_CP_AFEC END), 
					 B_Porcentaje = SRC.PORCENTAJE, 
					 M_Monto = SRC.MONTO,
					 M_MontoMinimo = CAST(REPLACE(SRC.MONTO_MIN, ',', '.') as float), 
					 T_DescripcionLarga = SRC.DESCRIP_L, 
					 T_Documento = SRC.DOCUMENTO,
					 B_Mora = SRC.OBLIG_MORA, 
					 I_TipoDescuentoID = NULL, 
					 --B_EsPagoMatricula = NULL, 
					 --B_EsPagoExtmp = NULL, 
					 D_FecMod = @D_FecProceso
		WHEN NOT MATCHED BY SOURCE AND TRG.B_Migrado = 1 AND TRG.I_UsuarioMod IS NULL AND TRG.B_EsPagoMatricula IS NULL AND TRG.B_EsPagoExtmp IS NULL  THEN
			DELETE  		 
		OUTPUT $action, SRC.I_RowID INTO @Tbl_outputConceptosPago;

		SET IDENTITY_INSERT BD_OCEF_CtasPorCobrar.dbo.TI_ConceptoPago OFF;

		UPDATE	TR_Cp_Pri 
		SET		B_Migrado = 1, 
				D_FecMigrado = @D_FecProceso
		WHERE	I_RowID IN (SELECT I_RowID FROM @Tbl_outputConceptosPago)

		UPDATE	TR_Cp_Des 
		SET		B_Migrado = 0 
		WHERE	I_RowID IN (SELECT CD.I_RowID FROM TR_Cp_Des CD LEFT JOIN @Tbl_outputConceptosPago O ON CD.I_RowID = o.I_RowID 
							WHERE CD.B_Migrable = 1 AND O.I_RowID IS NULL)

		MERGE TI_ObservacionRegistroTabla AS TRG
		USING 	(SELECT	@I_ObservID AS I_ObservID, @I_TablaID AS I_TablaID, I_RowID AS I_FilaTablaID, @D_FecProceso AS D_FecRegistro FROM TR_Cp_Des
				  WHERE	I_RowID IN (SELECT CP.I_RowID FROM TR_Cp_Pri CP LEFT JOIN @Tbl_outputConceptosPago O ON CP.I_RowID = o.I_RowID 
									WHERE CP.B_Migrable = 1 AND O.I_RowID IS NULL)
				) AS SRC
		ON TRG.I_ObservID = SRC.I_ObservID AND TRG.I_TablaID = SRC.I_TablaID AND TRG.I_FilaTablaID = SRC.I_FilaTablaID
		WHEN MATCHED THEN
			UPDATE SET D_FecRegistro = SRC.D_FecRegistro
		WHEN NOT MATCHED BY TARGET THEN
			INSERT (I_ObservID, I_TablaID, I_FilaTablaID, D_FecRegistro)
			VALUES (SRC.I_ObservID, SRC.I_TablaID, SRC.I_FilaTablaID, SRC.D_FecRegistro)
		WHEN NOT MATCHED BY SOURCE AND TRG.I_ObservID = @I_ObservID THEN
			DELETE;

		SET @I_ConceptoPago_Inserted = (SELECT COUNT(*) FROM @Tbl_outputConceptosPago WHERE T_Action = 'INSERT')
		SET @I_ConceptoPago_Updated = (SELECT COUNT(*) FROM @Tbl_outputConceptosPago WHERE T_Action = 'UPDATE')

		SELECT @I_ConceptoPago_Inserted AS concepto_count_insert, @I_ConceptoPago_Updated AS concepto_count_update 

		COMMIT TRANSACTION;

		SET @B_Resultado = 1
		SET @T_Message = CAST(@I_ConceptoPago_Inserted AS varchar) + ' | ' + CAST(@I_ConceptoPago_Updated AS varchar)
	END TRY
	BEGIN CATCH
		SET @B_Resultado = 0
		SET @T_Message = ERROR_MESSAGE() + ' LINE: ' + CAST(ERROR_LINE() AS varchar(10)) 
		ROLLBACK TRANSACTION;
	END CATCH
END
GO


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_IU_CopiarTablaObligacionesPago')
	DROP PROCEDURE [dbo].[USP_IU_CopiarTablaObligacionesPago]
GO

CREATE PROCEDURE USP_IU_CopiarTablaObligacionesPago	
	@B_Resultado  bit output,
	@T_Message	  nvarchar(4000) OUTPUT	
AS
--declare @B_Resultado  bit,
--		@T_Message	  nvarchar(4000)
--exec USP_IU_CopiarTablaObligacionesPago @B_Resultado output, @T_Message output
--select @B_Resultado as resultado, @T_Message as mensaje
BEGIN
	DECLARE @I_EcObl int = 0
	DECLARE @I_Removidos int = 0
	DECLARE @I_Actualizados int = 0
	DECLARE @I_Insertados int = 0
	DECLARE @D_FecProceso datetime = GETDATE() 

	BEGIN TRANSACTION
	BEGIN TRY 

		UPDATE	TR_Ec_Obl
		SET		B_Actualizado = 0, 
				B_Migrable	  = 1, 
				D_FecMigrado  = NULL, 
				B_Migrado	  = 0 

		UPDATE	TR_Ec_Obl
		SET		TR_Ec_Obl.B_Removido		= 1, 
				TR_Ec_Obl.D_FecRemovido	= @D_FecProceso,
				TR_Ec_Obl.B_Migrable		= 0
		WHERE	NOT EXISTS (SELECT * FROM BD_OCEF_TemporalPagos.pregrado.ec_obl SRC  
							WHERE TR_Ec_Obl.ANO = SRC.ANO AND TR_Ec_Obl.P = SRC.P AND TR_Ec_Obl.COD_ALU = SRC.COD_ALU 
							AND TR_Ec_Obl.COD_RC = SRC.COD_RC AND TR_Ec_Obl.CUOTA_PAGO = SRC.CUOTA_PAGO 
							AND ISNULL(TR_Ec_Obl.FCH_VENC, '19000101') = ISNULL(SRC.FCH_VENC, '19000101')
							AND ISNULL(TR_Ec_Obl.TIPO_OBLIG, 0) = ISNULL(SRC.TIPO_OBLIG, 0)
							AND TR_Ec_Obl.MONTO = SRC.MONTO AND TR_Ec_Obl.PAGADO = SRC.PAGADO)

		SET @I_Removidos = @@ROWCOUNT

		INSERT TR_Ec_Obl(ANO, P, I_Periodo, COD_ALU, COD_RC, CUOTA_PAGO, TIPO_OBLIG, FCH_VENC, MONTO, PAGADO, D_FecCarga, B_Migrable, B_Migrado, I_ProcedenciaID, B_Obligacion)
		SELECT	ANO, P, I_OpcionID as I_periodo, COD_ALU, COD_RC, CUOTA_PAGO, TIPO_OBLIG, FCH_VENC, MONTO, PAGADO, @D_FecProceso, 1, 0, 1, 1
		FROM	BD_OCEF_TemporalPagos.pregrado.ec_obl OBL
				LEFT JOIN BD_OCEF_CtasPorCobrar.dbo.TC_CatalogoOpcion cop_per ON OBL.P = cop_per.T_OpcionCod AND cop_per.I_ParametroID = 5
		WHERE	NOT EXISTS (SELECT * FROM TR_Ec_Obl TRG 
							WHERE TRG.ANO = OBL.ANO AND TRG.P = OBL.P AND TRG.COD_ALU = OBL.COD_ALU AND TRG.COD_RC = OBL.COD_RC 
							AND TRG.CUOTA_PAGO = OBL.CUOTA_PAGO AND ISNULL(TRG.FCH_VENC, '19000101') = ISNULL(OBL.FCH_VENC, '19000101')
							AND ISNULL(TRG.TIPO_OBLIG, 0) = ISNULL(OBL.TIPO_OBLIG, 0) AND TRG.MONTO = OBL.MONTO AND TRG.PAGADO = OBL.PAGADO)
		
		SET @I_Insertados = @@ROWCOUNT


		SET @I_EcObl = (SELECT COUNT(*) FROM BD_OCEF_TemporalPagos.pregrado.ec_obl)

		SELECT @I_EcObl AS tot_obligaciones, @I_Insertados AS cant_inserted, @I_Removidos as cant_removed, @D_FecProceso as fec_proceso
		
		COMMIT TRANSACTION
		SET @B_Resultado = 1
		SET @T_Message =  'Total: ' + CAST(@I_EcObl AS varchar) + '|Insertados: ' + CAST(@I_Insertados AS varchar) 
						+ '|Actualizados: ' + CAST(@I_Actualizados AS varchar) + '|Removidos: ' + CAST(@I_Removidos AS varchar)
	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION
		SET @B_Resultado = 0
		SET @T_Message = ERROR_MESSAGE() + ' LINE: ' + CAST(ERROR_LINE() AS varchar(10)) 
	END CATCH
END
GO


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_IU_CopiarTablaDetalleObligacionesPago')
	DROP PROCEDURE [dbo].[USP_IU_CopiarTablaDetalleObligacionesPago]
GO

CREATE PROCEDURE USP_IU_CopiarTablaDetalleObligacionesPago	
	@B_Resultado  bit output,
	@T_Message	  nvarchar(4000) OUTPUT	
AS
--declare @B_Resultado  bit,
--		@T_Message	  nvarchar(4000)
--exec USP_IU_CopiarTablaDetalleObligacionesPago @B_Resultado output, @T_Message output
--select @B_Resultado as resultado, @T_Message as mensaje
BEGIN
	DECLARE @I_EcDet int = 0
	DECLARE @I_Removidos int = 0
	DECLARE @I_Actualizados int = 0
	DECLARE @I_Insertados int = 0
	DECLARE @D_FecProceso datetime = GETDATE() 

	DECLARE @Tbl_output AS TABLE 
	(
		accion			varchar(20),
		I_RowID			int, 
		COD_ALU			nvarchar(50),
		COD_RC			nvarchar(50),
		CUOTA_PAGO		float,
		ANO				nvarchar(50),
		P				nvarchar(50),
		TIPO_OBLIG		varchar(50),
		CONCEPTO		float,
		FCH_VENC		nvarchar(50),
		ELIMINADO		nvarchar(50),
		INS_NRO_RECIBO	nvarchar(50),
		INS_FCH_PAGO	nvarchar(50),
		INS_ID_LUG_PAG	nvarchar(50),
		INS_CANTIDAD	nvarchar(50),
		INS_MONTO		nvarchar(50),
		INS_PAGADO		nvarchar(50),
		INS_CONCEPTO_F	nvarchar(50),
		INS_FCH_ELIMIN	nvarchar(50),
		INS_NRO_EC		float,
		INS_FCH_EC		nvarchar(50),
		INS_PAG_DEMAS	nvarchar(50),
		INS_COD_CAJERO	nvarchar(50),
		INS_TIPO_PAGO	nvarchar(50),
		INS_NO_BANCO	nvarchar(50),
		INS_COD_DEP		nvarchar(50),
		DEL_NRO_RECIBO	nvarchar(50),
		DEL_FCH_PAGO	nvarchar(50),
		DEL_ID_LUG_PAG	nvarchar(50),
		DEL_CANTIDAD	nvarchar(50),
		DEL_MONTO		nvarchar(50),
		DEL_PAGADO		nvarchar(50),
		DEL_CONCEPTO_F	nvarchar(50),
		DEL_FCH_ELIMIN	nvarchar(50),
		DEL_NRO_EC		float,
		DEL_FCH_EC		nvarchar(50),
		DEL_PAG_DEMAS	nvarchar(50),
		DEL_COD_CAJERO	nvarchar(50),
		DEL_TIPO_PAGO	nvarchar(50),
		DEL_NO_BANCO	nvarchar(50),
		DEL_COD_DEP		nvarchar(50),
		B_Removido		bit
	)

	BEGIN TRY 	
	
		DELETE TR_Ec_Det
			
		MERGE TR_Ec_Det AS TRG
		USING (SELECT * FROM BD_OCEF_TemporalPagos.pregrado.ec_det) AS SRC
		ON	  TRG.COD_ALU = SRC.COD_ALU AND
			  TRG.COD_RC = SRC.COD_RC AND
			  TRG.CUOTA_PAGO = SRC.CUOTA_PAGO AND
			  TRG.ANO = SRC.ANO AND
			  TRG.P = SRC.P AND
			  TRG.TIPO_OBLIG = SRC.TIPO_OBLIG AND
			  TRG.CONCEPTO = SRC.CONCEPTO AND
			  TRG.ELIMINADO = SRC.ELIMINADO
		WHEN NOT MATCHED BY TARGET THEN
			INSERT (COD_ALU, COD_RC, CUOTA_PAGO, ANO, P, TIPO_OBLIG, CONCEPTO, FCH_VENC, NRO_RECIBO, FCH_PAGO, ID_LUG_PAG, CANTIDAD, MONTO, PAGADO, CONCEPTO_F, FCH_ELIMIN, 
					NRO_EC, FCH_EC, ELIMINADO, PAG_DEMAS, COD_CAJERO, TIPO_PAGO, NO_BANCO, COD_DEP, D_FecCarga, B_Migrable, B_Migrado, D_FecMigrado, I_ProcedenciaID, B_Obligacion)
			VALUES (COD_ALU, COD_RC, CUOTA_PAGO, ANO, P, TIPO_OBLIG, CONCEPTO, FCH_VENC, NRO_RECIBO, FCH_PAGO, ID_LUG_PAG, CANTIDAD, MONTO, PAGADO, CONCEPTO_F, FCH_ELIMIN, 
					NRO_EC, FCH_EC, ELIMINADO, PAG_DEMAS, COD_CAJERO, TIPO_PAGO, NO_BANCO, COD_DEP, @D_FecProceso, 1, 0, NULL, 1, 1)
		WHEN NOT MATCHED BY SOURCE THEN
			UPDATE SET	TRG.B_Removido		= 1, 
						TRG.D_FecRemovido	= @D_FecProceso,
						TRG.B_Migrable		= 0, 
						TRG.D_FecMigrado	= 0, 
						TRG.B_Migrado		= 0 
		OUTPUT	$ACTION, inserted.I_RowID, inserted.COD_ALU, inserted.COD_RC, inserted.CUOTA_PAGO, inserted.ANO, inserted.P, inserted.TIPO_OBLIG, inserted.CONCEPTO, inserted.FCH_VENC, inserted.ELIMINADO, 
				inserted.NRO_RECIBO, inserted.FCH_PAGO, inserted.ID_LUG_PAG, inserted.CANTIDAD, inserted.MONTO, inserted.PAGADO, inserted.CONCEPTO_F, inserted.FCH_ELIMIN, inserted.NRO_EC, inserted.FCH_EC, 
				inserted.PAG_DEMAS, inserted.COD_CAJERO, inserted.TIPO_PAGO, inserted.NO_BANCO, inserted.COD_DEP, deleted.NRO_RECIBO, deleted.FCH_PAGO, deleted.ID_LUG_PAG, deleted.CANTIDAD, deleted.MONTO, 
				deleted.PAGADO, deleted.CONCEPTO_F, deleted.FCH_ELIMIN, deleted.NRO_EC, deleted.FCH_EC, deleted.PAG_DEMAS, deleted.COD_CAJERO, deleted.TIPO_PAGO, deleted.NO_BANCO, deleted.COD_DEP, 
				deleted.B_Removido INTO @Tbl_output;
				

		SET @I_EcDet = (SELECT COUNT(*) FROM BD_OCEF_TemporalPagos.pregrado.ec_det)
		SET @I_Insertados = (SELECT COUNT(*) FROM @Tbl_output WHERE accion = 'INSERT')
		SET @I_Removidos = (SELECT COUNT(*) FROM @Tbl_output WHERE accion = 'UPDATE' AND B_Removido = 1)

		SELECT @I_EcDet AS tot_obligaciones, @I_Insertados AS cant_inserted, @I_Actualizados as cant_updated, @I_Removidos as cant_removed, @D_FecProceso as fec_proceso
		
		SET @B_Resultado = 1
		SET @T_Message =  'Total: ' + CAST(@I_EcDet AS varchar) + '|Insertados: ' + CAST(@I_Insertados AS varchar) + '|Removidos: ' + CAST(@I_Removidos AS varchar)
	END TRY
	BEGIN CATCH
		SET @B_Resultado = 0
		SET @T_Message = ERROR_MESSAGE() + ' LINE: ' + CAST(ERROR_LINE() AS varchar(10)) 
	END CATCH
END
GO


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_U_ValidarAlumnosEnCabeceraObligacion')
	DROP PROCEDURE [dbo].[USP_U_ValidarAlumnosEnCabeceraObligacion]
GO

CREATE PROCEDURE [dbo].[USP_U_ValidarAlumnosEnCabeceraObligacion]	
	@B_Resultado  bit output,
	@T_Message	  nvarchar(4000) OUTPUT	
AS
--declare @B_Resultado  bit,
--		@T_Message	  nvarchar(4000)
--exec USP_U_ValidarAlumnosEnCabeceraObligacion @B_Resultado output, @T_Message output
--select @B_Resultado as resultado, @T_Message as mensaje
BEGIN
	DECLARE @I_Observados int = 0
	DECLARE @D_FecProceso datetime = GETDATE() 
	DECLARE @I_ObservID int = 24
	DECLARE @I_TablaID int = 5

	BEGIN TRANSACTION
	BEGIN TRY 
		UPDATE	TR_Ec_Obl
		SET		B_Migrable = 0,
				D_FecEvalua = @D_FecProceso
		WHERE	NOT EXISTS (SELECT * FROM TR_Alumnos b WHERE TR_Ec_Obl.COD_ALU = C_CodAlu and TR_Ec_Obl.COD_RC = C_RcCod)
					
		MERGE TI_ObservacionRegistroTabla AS TRG
		USING 	(SELECT	@I_ObservID AS I_ObservID, @I_TablaID AS I_TablaID, I_RowID AS I_FilaTablaID, @D_FecProceso AS D_FecRegistro FROM TR_Ec_Obl
				  WHERE	NOT EXISTS (SELECT * FROM TR_Alumnos b WHERE TR_Ec_Obl.COD_ALU = C_CodAlu and TR_Ec_Obl.COD_RC = C_RcCod)) AS SRC
		ON TRG.I_ObservID = SRC.I_ObservID AND TRG.I_TablaID = SRC.I_TablaID AND TRG.I_FilaTablaID = SRC.I_FilaTablaID
		WHEN MATCHED THEN
			UPDATE SET D_FecRegistro = SRC.D_FecRegistro
		WHEN NOT MATCHED BY TARGET THEN
			INSERT (I_ObservID, I_TablaID, I_FilaTablaID, D_FecRegistro)
			VALUES (SRC.I_ObservID, SRC.I_TablaID, SRC.I_FilaTablaID, SRC.D_FecRegistro)
		WHEN NOT MATCHED BY SOURCE AND TRG.I_ObservID = @I_ObservID THEN
			DELETE;

		SET @I_Observados = (SELECT COUNT(*) FROM TI_ObservacionRegistroTabla WHERE I_ObservID = @I_ObservID AND I_TablaID = @I_TablaID)

		SELECT @I_Observados as cant_obs, @D_FecProceso as fec_proceso

		COMMIT TRANSACTION				
		SET @B_Resultado = 1
		SET @T_Message = CAST(@I_Observados AS varchar)
	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION
		SET @B_Resultado = 0
		SET @T_Message = ERROR_MESSAGE() + ' LINE: ' + CAST(ERROR_LINE() AS varchar(10)) 
	END CATCH
END
GO


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_U_ValidarAnioEnCabeceraObligacion')
	DROP PROCEDURE [dbo].[USP_U_ValidarAnioEnCabeceraObligacion]
GO

CREATE PROCEDURE [dbo].[USP_U_ValidarAnioEnCabeceraObligacion]	
	@B_Resultado  bit output,
	@T_Message	  nvarchar(4000) OUTPUT	
AS
--declare @B_Resultado  bit,
--		@T_Message	  nvarchar(4000)
--exec USP_U_ValidarAñoEnCabeceraObligacion @B_Resultado output, @T_Message output
--select @B_Resultado as resultado, @T_Message as mensaje
BEGIN
	DECLARE @I_Observados int = 0
	DECLARE @D_FecProceso datetime = GETDATE() 
	DECLARE @I_ObservID int = 26
	DECLARE @I_TablaID int = 5

	BEGIN TRANSACTION
	BEGIN TRY 
		UPDATE	TR_Ec_Obl
		SET		B_Migrable = 0,
				D_FecEvalua = @D_FecProceso
		WHERE	ISNUMERIC(ANO) = 0
					
		MERGE TI_ObservacionRegistroTabla AS TRG
		USING 	(SELECT	@I_ObservID AS I_ObservID, @I_TablaID AS I_TablaID, I_RowID AS I_FilaTablaID, @D_FecProceso AS D_FecRegistro FROM TR_Ec_Obl
				  WHERE	ISNUMERIC(ANO) = 0) AS SRC
		ON TRG.I_ObservID = SRC.I_ObservID AND TRG.I_TablaID = SRC.I_TablaID AND TRG.I_FilaTablaID = SRC.I_FilaTablaID
		WHEN MATCHED THEN
			UPDATE SET D_FecRegistro = SRC.D_FecRegistro
		WHEN NOT MATCHED BY TARGET THEN
			INSERT (I_ObservID, I_TablaID, I_FilaTablaID, D_FecRegistro)
			VALUES (SRC.I_ObservID, SRC.I_TablaID, SRC.I_FilaTablaID, SRC.D_FecRegistro)
		WHEN NOT MATCHED BY SOURCE AND TRG.I_ObservID = @I_ObservID THEN
			DELETE;

		SET @I_Observados = (SELECT COUNT(*) FROM TI_ObservacionRegistroTabla WHERE I_ObservID = @I_ObservID AND I_TablaID = @I_TablaID)

		SELECT @I_Observados as cant_obs, @D_FecProceso as fec_proceso

		COMMIT TRANSACTION				
		SET @B_Resultado = 1
		SET @T_Message = CAST(@I_Observados AS varchar)
	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION
		SET @B_Resultado = 0
		SET @T_Message = ERROR_MESSAGE() + ' LINE: ' + CAST(ERROR_LINE() AS varchar(10)) 
	END CATCH
END
GO


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_U_ValidarPeriodoEnCabeceraObligacion')
	DROP PROCEDURE [dbo].[USP_U_ValidarPeriodoEnCabeceraObligacion]
GO

CREATE PROCEDURE [dbo].[USP_U_ValidarPeriodoEnCabeceraObligacion]	
	@B_Resultado  bit output,
	@T_Message	  nvarchar(4000) OUTPUT	
AS
--declare @B_Resultado  bit,
--		@T_Message	  nvarchar(4000)
--exec USP_U_ValidarPeriodoEnCabeceraObligacion @B_Resultado output, @T_Message output
--select @B_Resultado as resultado, @T_Message as mensaje
BEGIN
	DECLARE @I_Observados int = 0
	DECLARE @D_FecProceso datetime = GETDATE() 
	DECLARE @I_ObservID int = 27
	DECLARE @I_TablaID int = 5

	BEGIN TRANSACTION
	BEGIN TRY 
		UPDATE	TR_Ec_Obl
		SET		B_Migrable = 0,
				D_FecEvalua = @D_FecProceso
		WHERE	I_Periodo IS NULL
					
		MERGE TI_ObservacionRegistroTabla AS TRG
		USING 	(SELECT	@I_ObservID AS I_ObservID, @I_TablaID AS I_TablaID, I_RowID AS I_FilaTablaID, @D_FecProceso AS D_FecRegistro FROM TR_Ec_Obl
				  WHERE	I_Periodo IS NULL) AS SRC
		ON TRG.I_ObservID = SRC.I_ObservID AND TRG.I_TablaID = SRC.I_TablaID AND TRG.I_FilaTablaID = SRC.I_FilaTablaID
		WHEN MATCHED THEN
			UPDATE SET D_FecRegistro = SRC.D_FecRegistro
		WHEN NOT MATCHED BY TARGET THEN
			INSERT (I_ObservID, I_TablaID, I_FilaTablaID, D_FecRegistro)
			VALUES (SRC.I_ObservID, SRC.I_TablaID, SRC.I_FilaTablaID, SRC.D_FecRegistro)
		WHEN NOT MATCHED BY SOURCE AND TRG.I_ObservID = @I_ObservID THEN
			DELETE;

		SET @I_Observados = (SELECT COUNT(*) FROM TI_ObservacionRegistroTabla WHERE I_ObservID = @I_ObservID AND I_TablaID = @I_TablaID)

		SELECT @I_Observados as cant_obs, @D_FecProceso as fec_proceso

		COMMIT TRANSACTION				
		SET @B_Resultado = 1
		SET @T_Message = CAST(@I_Observados AS varchar)
	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION
		SET @B_Resultado = 0
		SET @T_Message = ERROR_MESSAGE() + ' LINE: ' + CAST(ERROR_LINE() AS varchar(10)) 
	END CATCH
END
GO



IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_U_ValidarFechaVencimientoCuotaObligacion')
	DROP PROCEDURE [dbo].[USP_U_ValidarFechaVencimientoCuotaObligacion]
GO

CREATE PROCEDURE [dbo].[USP_U_ValidarFechaVencimientoCuotaObligacion]	
	@B_Resultado  bit output,
	@T_Message	  nvarchar(4000) OUTPUT	
AS
--declare @B_Resultado  bit,
--		  @T_Message    nvarchar(4000)
--exec USP_U_ValidarFechaVencimientoCuotaObligacion @B_Resultado output, @T_Message output
--select @B_Resultado as resultado, @T_Message as mensaje
BEGIN
	DECLARE @I_Observados int = 0
	DECLARE @D_FecProceso datetime = GETDATE() 
	DECLARE @I_ObservID int = 28
	DECLARE @I_TablaID int = 5

	BEGIN TRANSACTION
	BEGIN TRY

		UPDATE	TRG_1
		SET		B_Migrable = 0,
				D_FecEvalua = @D_FecProceso
		FROM	TR_Ec_Obl TRG_1
				INNER JOIN (SELECT ANO, P, COD_ALU, COD_RC, CUOTA_PAGO, FCH_VENC, TIPO_OBLIG, MONTO
							FROM  TR_Ec_Obl
							GROUP BY ANO, P, COD_ALU, COD_RC, CUOTA_PAGO, FCH_VENC, TIPO_OBLIG, MONTO
							HAVING COUNT(*) > 1) SRC_1 
				ON TRG_1.ANO = SRC_1.ANO AND TRG_1.P = SRC_1.P AND TRG_1.COD_ALU = SRC_1.COD_ALU AND TRG_1.COD_RC = SRC_1.COD_RC 
					AND TRG_1.CUOTA_PAGO = SRC_1.CUOTA_PAGO AND TRG_1.FCH_VENC = SRC_1.FCH_VENC 
					AND TRG_1.TIPO_OBLIG = SRC_1.TIPO_OBLIG AND TRG_1.MONTO = SRC_1.MONTO
					
		MERGE TI_ObservacionRegistroTabla AS TRG
		USING 	(SELECT	@I_ObservID AS I_ObservID, @I_TablaID AS I_TablaID, I_RowID AS I_FilaTablaID, @D_FecProceso AS D_FecRegistro 
				 FROM TR_Ec_Obl TRG_1
					INNER JOIN (SELECT ANO, P, COD_ALU, COD_RC, CUOTA_PAGO, FCH_VENC, TIPO_OBLIG, MONTO
								FROM  TR_Ec_Obl
								GROUP BY ANO, P, COD_ALU, COD_RC, CUOTA_PAGO, FCH_VENC, TIPO_OBLIG, MONTO
								HAVING COUNT(*) > 1) SRC_1 
					ON TRG_1.ANO = SRC_1.ANO AND TRG_1.P = SRC_1.P AND TRG_1.COD_ALU = SRC_1.COD_ALU AND TRG_1.COD_RC = SRC_1.COD_RC 
						AND TRG_1.CUOTA_PAGO = SRC_1.CUOTA_PAGO AND TRG_1.FCH_VENC = SRC_1.FCH_VENC 
						AND TRG_1.TIPO_OBLIG = SRC_1.TIPO_OBLIG AND TRG_1.MONTO = SRC_1.MONTO
				 ) AS SRC
		ON TRG.I_ObservID = SRC.I_ObservID AND TRG.I_TablaID = SRC.I_TablaID AND TRG.I_FilaTablaID = SRC.I_FilaTablaID
		WHEN MATCHED THEN
			UPDATE SET D_FecRegistro = SRC.D_FecRegistro
		WHEN NOT MATCHED BY TARGET THEN
			INSERT (I_ObservID, I_TablaID, I_FilaTablaID, D_FecRegistro)
			VALUES (SRC.I_ObservID, SRC.I_TablaID, SRC.I_FilaTablaID, SRC.D_FecRegistro)
		WHEN NOT MATCHED BY SOURCE AND TRG.I_ObservID = @I_ObservID THEN
			DELETE;

		SET @I_Observados = (SELECT COUNT(*) FROM TI_ObservacionRegistroTabla WHERE I_ObservID = @I_ObservID AND I_TablaID = @I_TablaID)

		SELECT @I_Observados as cant_obs, @D_FecProceso as fec_proceso

		COMMIT TRANSACTION				
		SET @B_Resultado = 1
		SET @T_Message = CAST(@I_Observados AS varchar)
	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION
		SET @B_Resultado = 0
		SET @T_Message = ERROR_MESSAGE() + ' LINE: ' + CAST(ERROR_LINE() AS varchar(10)) 
	END CATCH
END
GO


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_U_ValidarDetalleObligacion')
	DROP PROCEDURE [dbo].[USP_U_ValidarDetalleObligacion]
GO

CREATE PROCEDURE [dbo].[USP_U_ValidarDetalleObligacion]	
	@B_Resultado  bit output,
	@T_Message	  nvarchar(4000) OUTPUT	
AS
--declare @B_Resultado  bit,
-- 		  @T_Message	nvarchar(4000)
--exec USP_U_ValidarDetalleObligacion @B_Resultado output, @T_Message output
--select @B_Resultado as resultado, @T_Message as mensaje
BEGIN
	DECLARE @I_Observados int = 0
	DECLARE @D_FecProceso datetime = GETDATE() 
	DECLARE @I_ObservID int = 25
	DECLARE @I_TablaID int = 4

	BEGIN TRANSACTION
	BEGIN TRY 
		UPDATE	TR_Ec_Det
		SET		B_Migrable = 0,
				D_FecEvalua = @D_FecProceso
		WHERE	TIPO_OBLIG = 'T' AND
				NOT EXISTS (SELECT * FROM TR_Ec_Obl b 
							WHERE	TR_Ec_Det.ANO = b.ANO 
									AND TR_Ec_Det.P = b.P
									AND TR_Ec_Det.CUOTA_PAGO = b.CUOTA_PAGO
									AND TR_Ec_Det.COD_ALU = b.COD_ALU
									AND TR_Ec_Det.COD_RC = b.COD_RC
									AND CONVERT(DATETIME, FCH_VENC, 102) = b.FCH_VENC
							)

					
		MERGE TI_ObservacionRegistroTabla AS TRG
		USING 	(SELECT	@I_ObservID AS I_ObservID, @I_TablaID AS I_TablaID, I_RowID AS I_FilaTablaID, @D_FecProceso AS D_FecRegistro FROM TR_Ec_Det
				  WHERE	TIPO_OBLIG = 'T' AND
						NOT EXISTS (SELECT * FROM TR_Ec_Obl b 
									WHERE	TR_Ec_Det.ANO = b.ANO 
											AND TR_Ec_Det.P = b.P
											AND TR_Ec_Det.CUOTA_PAGO = b.CUOTA_PAGO
											AND TR_Ec_Det.COD_ALU = b.COD_ALU
											AND TR_Ec_Det.COD_RC = b.COD_RC
											AND CONVERT(DATETIME, FCH_VENC, 102) = b.FCH_VENC
								)) AS SRC
		ON TRG.I_ObservID = SRC.I_ObservID AND TRG.I_TablaID = SRC.I_TablaID AND TRG.I_FilaTablaID = SRC.I_FilaTablaID
		WHEN MATCHED THEN
			UPDATE SET D_FecRegistro = SRC.D_FecRegistro
		WHEN NOT MATCHED BY TARGET THEN
			INSERT (I_ObservID, I_TablaID, I_FilaTablaID, D_FecRegistro)
			VALUES (SRC.I_ObservID, SRC.I_TablaID, SRC.I_FilaTablaID, SRC.D_FecRegistro)
		WHEN NOT MATCHED BY SOURCE AND TRG.I_ObservID = @I_ObservID THEN
			DELETE;

		SET @I_Observados = (SELECT COUNT(*) FROM TI_ObservacionRegistroTabla WHERE I_ObservID = @I_ObservID AND I_TablaID = @I_TablaID)

		SELECT @I_Observados as cant_obs, @D_FecProceso as fec_proceso

		COMMIT TRANSACTION				
		SET @B_Resultado = 1
		SET @T_Message = CAST(@I_Observados AS varchar)
	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION
		SET @B_Resultado = 0
		SET @T_Message = ERROR_MESSAGE() + ' LINE: ' + CAST(ERROR_LINE() AS varchar(10)) 
	END CATCH
END
GO


