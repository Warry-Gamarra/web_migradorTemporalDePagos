/*
======================================================
	BD_OCEF_MigracionTP - 04_Procedures_CuotaPago
======================================================
*/

USE BD_OCEF_MigracionTP
GO


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_IU_CopiarTablaCuotaDePago')
	DROP PROCEDURE [dbo].[USP_IU_CopiarTablaCuotaDePago]
GO

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_Obligaciones_CuotaPago_TemporalPagos_MigracionTP_IU_CopiarTabla')
	DROP PROCEDURE [dbo].[USP_Obligaciones_CuotaPago_TemporalPagos_MigracionTP_IU_CopiarTabla]
GO

CREATE PROCEDURE USP_Obligaciones_CuotaPago_TemporalPagos_MigracionTP_IU_CopiarTabla
	@I_ProcedenciaID tinyint,
	@T_SchemaDB		 varchar(20),
	@T_Codigo_bnc	 varchar(250),
	@B_IgnoreUpdated bit,
	@B_Resultado	 bit output,
	@T_Message		 nvarchar(4000) OUTPUT	
AS
/*
	declare @B_Resultado		bit,
			@I_ProcedenciaID	tinyint = 2,
			@T_SchemaDB			varchar(20) = 'eupg',
			@T_Codigo_bnc		varchar(250) = '''0670'', ''0671'', ''0672'', ''0673'', ''0674'', ''0675'', 
                                                ''0676'', ''0677'', ''0678'', ''0679'', ''0680'', ''0681'', 
                                                ''0682'', ''0683'', ''0695'', ''0696'', ''0697'', ''0698''',
			@B_IgnoreUpdated	bit = 0,
			@T_Message			nvarchar(4000)
	exec USP_Obligaciones_CuotaPago_TemporalPagos_MigracionTP_IU_CopiarTabla @I_ProcedenciaID, @T_SchemaDB, @T_Codigo_bnc, @B_IgnoreUpdated, @B_Resultado output, @T_Message output
	select @B_Resultado as resultado, @T_Message as mensaje
*/
BEGIN
	DECLARE @T_SQL nvarchar(max)

	DECLARE @I_TablaID tinyint = 2 
	DECLARE @I_CpDes int = 0
	DECLARE @I_EtapaProcesoID tinyint = 0
	DECLARE @I_Removidos int = 0
	DECLARE @I_Actualizados int = 0
	DECLARE @I_Insertados int = 0
	DECLARE @D_FecProceso datetime = GETDATE()
	DECLARE @I_Anio smallint = 0
 
	CREATE TABLE #Tbl_output  
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
	
	BEGIN TRANSACTION
	BEGIN TRY 

		SET @T_SQL = 'DECLARE @D_FecProceso datetime = GETDATE() ' + CHAR(10) + CHAR(13) +
					 'MERGE TR_Cp_Des AS TRG ' + CHAR(13) + 
					 'USING (SELECT * FROM BD_OCEF_TemporalPagos.' + @T_SchemaDB + '.cp_des WHERE codigo_bnc IN (' + @T_Codigo_bnc + ')' + CHAR(13) + 
					 '		) AS SRC ' + CHAR(13) + 
					 'ON	TRG.Cuota_pago = SRC.cuota_pago ' + CHAR(13) + 
				  	 '		AND TRG.Eliminado = SRC.eliminado ' + CHAR(13) + 
					 '		AND TRG.Codigo_bnc = SRC.codigo_bnc ' + CHAR(13) + 
					 'WHEN MATCHED ' + IIF(@B_IgnoreUpdated = 0, ' AND TRG.B_Actualizado = 0' + CHAR(13),'') + ' THEN ' + CHAR(13) + 
				  	 '	UPDATE SET	TRG.Descripcio = SRC.descripcio, ' + CHAR(13) + 
				  	 '			TRG.N_cta_cte = SRC.n_cta_cte, ' + CHAR(13) +
				  	 '			TRG.Codigo_bnc = SRC.codigo_bnc, ' + CHAR(13) +
				  	 '			TRG.Fch_venc = SRC.fch_venc, ' + CHAR(13) + 
				  	 '			TRG.Prioridad = SRC.prioridad, ' + CHAR(13) + 
				  	 '			TRG.C_mora = SRC.c_mora ' + CHAR(13) + 
					 'WHEN NOT MATCHED BY TARGET THEN ' + CHAR(13) + 
				  	 '	INSERT (Cuota_pago, Descripcio, N_cta_cte, Eliminado, Codigo_bnc, Fch_venc, Prioridad, C_mora, I_ProcedenciaID, D_FecCarga, B_Actualizado) ' + CHAR(13) + 
				  	 '	VALUES (SRC.cuota_pago, SRC.descripcio, SRC.n_cta_cte, SRC.eliminado, SRC.codigo_bnc, SRC.fch_venc, SRC.prioridad, SRC.c_mora, ' + CAST(@I_ProcedenciaID as varchar(3)) + ', @D_FecProceso, 1) ' + CHAR(13) +
					 'WHEN NOT MATCHED BY SOURCE AND TRG.I_ProcedenciaID = '+ CAST(@I_ProcedenciaID as varchar(3)) + IIF(@B_IgnoreUpdated = 0, ' AND TRG.B_Actualizado = 0','') + ' THEN ' + CHAR(13) +
				  	 '	UPDATE SET TRG.B_Removido = 1, ' +CHAR(13) +
				  	 '			   TRG.D_FecRemovido = @D_FecProceso ' + CHAR(13) +
					 'OUTPUT  $ACTION, inserted.CUOTA_PAGO, inserted.ELIMINADO, inserted.DESCRIPCIO, inserted.N_CTA_CTE, ' + CHAR(13) +  
				  	 '		inserted.CODIGO_BNC, inserted.FCH_VENC, inserted.PRIORIDAD, inserted.C_MORA, deleted.DESCRIPCIO, ' + CHAR(13) +
				  	 '		deleted.N_CTA_CTE, deleted.CODIGO_BNC, deleted.FCH_VENC, deleted.PRIORIDAD, deleted.C_MORA, ' + CHAR(13) +
				  	 '		deleted.B_Removido INTO #Tbl_output;'

		EXEC sp_executesql @T_SQL


		UPDATE	TR_Cp_Des 
				SET	B_Actualizado = IIF(@B_IgnoreUpdated = 1, 0, B_Actualizado), 
					D_FecActualiza = IIF(@B_IgnoreUpdated = 1, NULL, D_FecActualiza), 
					B_Migrable = 0, D_FecEvalua = NULL,
					D_FecMigrado = NULL, B_Migrado = 0,
					I_Anio = NULL, I_CatPagoID = NULL, I_Periodo = NULL
		 WHERE	I_ProcedenciaID = @I_ProcedenciaID

		
		SET @T_SQL = 'SELECT cuota_pago FROM BD_OCEF_TemporalPagos.' + @T_SchemaDB + '.cp_des WHERE codigo_bnc IN (' + @T_Codigo_bnc + ')'
		print @T_SQL
		Exec sp_executesql @T_SQL

		SET @I_CpDes = @@ROWCOUNT

		SET @I_Insertados = (SELECT COUNT(*) FROM #Tbl_output WHERE accion = 'INSERT')
		SET @I_Actualizados = (SELECT COUNT(*) FROM #Tbl_output WHERE accion = 'UPDATE' AND B_Removido = 0)
		SET @I_Removidos = (SELECT COUNT(*) FROM #Tbl_output WHERE accion = 'UPDATE' AND B_Removido = 1)

		DECLARE @I_ToDo int = @I_CpDes
		DECLARE @I_Done int = @I_Insertados + @I_Actualizados
		DECLARE @I_Progress int = @I_CpDes - @I_Done

		EXEC USP_Shared_ControlTabla_MigracionTP_IU_RegistrarCopiados @I_TablaID, @I_ProcedenciaID, @I_Anio, @I_ToDo, 
																	  @I_Done, @I_Progress, @D_FecProceso

		SELECT @I_CpDes AS tot_cuotaPago, @I_Insertados AS cant_inserted, @I_Actualizados as cant_updated, 
			   @I_Removidos as cant_removed, @D_FecProceso as fec_proceso

		COMMIT TRANSACTION

		SET @B_Resultado = 1

		SET @T_Message =  '[{ ' +
							 'Type: "summary", ' + 
							 'Title: "Total:", '+ 
							 'Value: ' + CAST(@I_CpDes AS varchar) +
						  '}, ' + 
						  '{ ' +
							 'Type: "detail", ' + 
							 'Title: "Insertados", ' + 
							 'Value: ' + CAST(@I_Insertados AS varchar) +
						  '}, ' +
						  '{ ' +
							 'Type: "detail", ' + 
							 'Title: "Actualizados", ' + 
							 'Value: ' + CAST(@I_Actualizados AS varchar) +  
						  '}, ' +
						  '{ ' +
							 'Type: "detail", ' + 
							 'Title: "Removidos", ' + 
							 'Value: ' + CAST(@I_Removidos AS varchar)+ 
						  '}]'

	END TRY
	BEGIN CATCH
		IF(@@TRANCOUNT > 0)
		BEGIN
			ROLLBACK TRANSACTION 
		END

		SET @B_Resultado = 0
		SET @T_Message = '[{ ' +
							 'Type: "error", ' + 
							 'Title: "Error", ' + 
							 'Value: "' + ERROR_MESSAGE() + ' (Linea: ' + CAST(ERROR_LINE() AS varchar(11)) + ')."'  +
						  '}]' 
	END CATCH
END
GO






IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_U_AsignarCategoriaCuotaPago')
	DROP PROCEDURE [dbo].[USP_U_AsignarCategoriaCuotaPago]
GO

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_Obligaciones_CuotaPago_MigracionTP_U_Validar_09_VariasCategoriasAsignadas')
	DROP PROCEDURE [dbo].[USP_Obligaciones_CuotaPago_MigracionTP_U_Validar_09_VariasCategoriasAsignadas]
GO

CREATE PROCEDURE USP_Obligaciones_CuotaPago_MigracionTP_U_Validar_09_VariasCategoriasAsignadas
	@I_RowID	  int = NULL,
	@I_ProcedenciaID tinyint,
	@B_Resultado  bit output,
	@T_Message	  nvarchar(4000) OUTPUT	
AS
/*
	DESCRIPCION: B_Migrable = 0, cuando la cuota de pago presenta más de una categoría según codBanco

	DECLARE @I_RowID	  int = NULL,
			@I_ProcedenciaID tinyint = 3,
			@B_Resultado  bit,
			@T_Message	  nvarchar(4000)
	EXEC USP_Obligaciones_CuotaPago_MigracionTP_U_Validar_09_VariasCategoriasAsignadas @I_RowID, @I_ProcedenciaID, @B_Resultado output, @T_Message output
	SELECT @B_Resultado as resultado, @T_Message as mensaje
*/
BEGIN
	DECLARE @D_FecProceso datetime = GETDATE() 
	DECLARE @I_TablaID int = 2
	DECLARE @I_ObsMasUnCategoria int = 9
	DECLARE @I_cant_masCategorias int = 0
	
	BEGIN TRANSACTION
	BEGIN TRY 
		DECLARE @categoria_pago AS TABLE (cuota_pago int, I_CatPagoID int, N_CodBanco varchar(10))

		INSERT INTO @categoria_pago (cuota_pago, I_CatPagoID, N_CodBanco)
			SELECT	d.Cuota_pago, c.I_CatPagoID, c.N_CodBanco FROM TR_Cp_Des d
					LEFT JOIN BD_OCEF_CtasPorCobrar.dbo.TC_CategoriaPago c ON d.Codigo_bnc = c.N_CodBanco
			WHERE	I_ProcedenciaID = @I_ProcedenciaID 


		SELECT  cat1.*
		  INTO  #temp_cuota_una_categorias
		  FROM  @categoria_pago cat1
				INNER JOIN (SELECT cuota_pago 
							  FROM @categoria_pago 
							GROUP BY cuota_pago HAVING COUNT(*) = 1) cat2 ON cat1.cuota_pago = cat2.cuota_pago


		UPDATE	tb_des  
		   SET	I_CatPagoID = cat1.I_CatPagoID,
				D_FecEvalua = @D_FecProceso
		  FROM	TR_Cp_Des tb_des
			    INNER JOIN #temp_cuota_varias_categorias tmp ON tb_des.I_RowID = tmp.I_RowID


		UPDATE	tb_des  
		SET		I_CatPagoID = CASE WHEN(tb_des.Descripcio) LIKE '%REG%' THEN 18 
								   WHEN(tb_des.Descripcio) LIKE '%ING%' THEN 17 
								   ELSE NULL END,
				D_FecEvalua = @D_FecProceso
		FROM	TR_Cp_Des tb_des
				INNER JOIN (SELECT DISTINCT cuota_pago FROM @categoria_pago WHERE N_CodBanco = '0685') cat2
				ON tb_des.Cuota_pago = cat2.cuota_pago
		WHERE	tb_des.I_CatPagoID IS NULL
				AND I_ProcedenciaID = @I_ProcedenciaID
				AND tb_des.I_RowID = IIF(@I_RowID IS NULL, tb_des.I_RowID, @I_RowID)
			

		SET @I_cant_masCategorias = (SELECT COUNT(*) FROM TI_ObservacionRegistroTabla WHERE I_ObservID = @I_ObsMasUnCategoria AND I_TablaID = @I_TablaID AND I_ProcedenciaID = @I_ProcedenciaID AND B_Resuelto = 0)
		
		COMMIT TRANSACTION
		SET @B_Resultado = 1
		SET @T_Message = CAST(@I_cant_masCategorias AS varchar)

	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION
 		SET @B_Resultado = 0
		SET @T_Message = '{ ' +
							 'Type: "error", ' + 
							 'Title: "Error", ' + 
							 'Value: "' + ERROR_MESSAGE() + ' (Linea: ' + CAST(ERROR_LINE() AS varchar(11)) + ')."'  +
						 '}' 
	END CATCH
END
GO


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_Obligaciones_CuotaPago_MigracionTP_U_Validar_10_SinCategoriaAsingada')
	DROP PROCEDURE [dbo].[USP_Obligaciones_CuotaPago_MigracionTP_U_Validar_10_SinCategoriaAsingada]
GO

CREATE PROCEDURE USP_Obligaciones_CuotaPago_MigracionTP_U_Validar_10_SinCategoriaAsingada
	@I_RowID	  int = NULL,
	@I_ProcedenciaID tinyint,
	@B_Resultado  bit output,
	@T_Message	  nvarchar(4000) OUTPUT	
AS
/*
	DESCRIPCION: B_Migrable = 0, cuando cuota de pago no presenta una categoria asociada según codigo_bnc.
	
	DECLARE @I_RowID	  int = NULL,
			@I_ProcedenciaID tinyint = 3,
			@B_Resultado  bit,
			@T_Message	  nvarchar(4000)
	EXEC USP_Obligaciones_CuotaPago_MigracionTP_U_Validar_10_SinCategoriaAsingada @I_RowID, @I_ProcedenciaID, @B_Resultado output, @T_Message output
	SELECT @B_Resultado as resultado, @T_Message as mensaje
*/
BEGIN
	DECLARE @D_FecProceso datetime = GETDATE() 
	DECLARE @I_TablaID int = 2
	DECLARE @I_ObsSinCategoria int = 10
	DECLARE @I_cant_sinCategorias int = 0
	
	BEGIN TRANSACTION
	BEGIN TRY 

		UPDATE	TR_Cp_Des
		SET		B_Migrable = 0,
				D_FecEvalua = @D_FecProceso
		WHERE	I_CatPagoID IS NULL
				AND Eliminado = 0
				AND I_ProcedenciaID = @I_ProcedenciaID
				AND I_RowID = ISNULL(@I_RowID, I_RowID)

		MERGE TI_ObservacionRegistroTabla AS TRG
		USING 	(SELECT	@I_ObsSinCategoria AS I_ObservID, @I_TablaID AS I_TablaID, I_RowID AS I_FilaTablaID, @D_FecProceso AS D_FecRegistro FROM TR_Cp_Des
				  WHERE	I_CatPagoID IS NULL 
						AND Eliminado = 0
						AND I_ProcedenciaID = @I_ProcedenciaID
						AND I_RowID = ISNULL(@I_RowID, I_RowID)
				) AS SRC
		ON TRG.I_ObservID = SRC.I_ObservID AND TRG.I_TablaID = SRC.I_TablaID AND TRG.I_FilaTablaID = SRC.I_FilaTablaID
		WHEN MATCHED THEN
			UPDATE SET D_FecRegistro = SRC.D_FecRegistro
		WHEN NOT MATCHED BY TARGET THEN
			INSERT (I_ObservID, I_TablaID, I_FilaTablaID, D_FecRegistro, I_ProcedenciaID)
			VALUES (SRC.I_ObservID, SRC.I_TablaID, SRC.I_FilaTablaID, SRC.D_FecRegistro, @I_ProcedenciaID)
		WHEN NOT MATCHED BY SOURCE 
				AND TRG.I_ObservID = @I_ObsSinCategoria 
				AND TRG.I_ProcedenciaID = @I_ProcedenciaID
				AND TRG.I_TablaID = @I_TablaID
				AND TRG.I_FilaTablaID = IIF(@I_RowID IS NULL, TRG.I_FilaTablaID, @I_RowID) THEN
			UPDATE SET D_FecResuelto = @D_FecProceso,
					   B_Resuelto = 1;


		SET @I_cant_sinCategorias = (SELECT COUNT(*) 
									   FROM TI_ObservacionRegistroTabla 
									  WHERE I_ObservID = @I_ObsSinCategoria 
									  		AND I_TablaID = @I_TablaID 
									  		AND I_ProcedenciaID = @I_ProcedenciaID 
											AND B_Resuelto = 0)
		
		COMMIT TRANSACTION

		SET @B_Resultado = 1
		SET @T_Message = CAST(@I_cant_sinCategorias AS varchar)
	END TRY
	BEGIN CATCH
		IF(@@TRANCOUNT > 0)
		BEGIN
			ROLLBACK TRANSACTION
		END

 		SET @B_Resultado = 0
		SET @T_Message = '{ ' +
							 'Type: "error", ' + 
							 'Title: "Error", ' + 
							 'Value: "' + ERROR_MESSAGE() + ' (Linea: ' + CAST(ERROR_LINE() AS varchar(11)) + ')."'  +
						  '}' 
	END CATCH
END
GO


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_Obligaciones_CuotaPago_MigracionTP_U_Validar_45_Eliminados')
	DROP PROCEDURE [dbo].[USP_Obligaciones_CuotaPago_MigracionTP_U_Validar_45_Eliminados]
GO

CREATE PROCEDURE USP_Obligaciones_CuotaPago_MigracionTP_U_Validar_45_Eliminados	
	@I_RowID	  int = NULL,
	@I_ProcedenciaID tinyint,
	@B_Resultado  bit output,
	@T_Message	  nvarchar(4000) OUTPUT	
AS
/*
	DECLARE @I_RowID	  int = NULL,
			@I_ProcedenciaID	tinyint = 3,
			@B_Resultado  bit,
			@T_Message	  nvarchar(4000)
	EXEC USP_Obligaciones_CuotaPago_MigracionTP_U_Validar_45_Eliminados @I_RowID, @I_ProcedenciaID, @B_Resultado output, @T_Message output
	SELECT @B_Resultado as resultado, @T_Message as mensaje
*/
BEGIN
	DECLARE @D_FecProceso datetime = GETDATE() 
	DECLARE @I_ObservID int = 45
	DECLARE @I_TablaID int = 2 

	BEGIN TRANSACTION
	BEGIN TRY 
		UPDATE	TR_Cp_Des 
		SET		B_Migrable = 0,
				D_FecEvalua = @D_FecProceso
		 WHERE	I_ProcedenciaID = @I_ProcedenciaID
				AND Eliminado = 1
				AND I_RowID = ISNULL(@I_RowID, I_RowID)

		MERGE TI_ObservacionRegistroTabla AS TRG
		USING (SELECT @I_ObservID AS I_ObservID, @I_TablaID AS I_TablaID, I_RowID AS I_FilaTablaID, @D_FecProceso AS D_FecRegistro 
				 FROM TR_Cp_Des 
				WHERE I_ProcedenciaID = @I_ProcedenciaID
					  AND Eliminado = 1
					  AND I_RowID = ISNULL(@I_RowID, I_RowID)
			  ) AS SRC
		ON TRG.I_ObservID = SRC.I_ObservID AND TRG.I_TablaID = SRC.I_TablaID AND TRG.I_FilaTablaID = SRC.I_FilaTablaID
		WHEN MATCHED THEN
			UPDATE SET D_FecRegistro = SRC.D_FecRegistro, 
					   B_Resuelto = 0
		WHEN NOT MATCHED BY TARGET THEN
			INSERT (I_ObservID, I_TablaID, I_FilaTablaID, D_FecRegistro, I_ProcedenciaID)
			VALUES (SRC.I_ObservID, SRC.I_TablaID, SRC.I_FilaTablaID, SRC.D_FecRegistro, @I_ProcedenciaID)
		WHEN NOT MATCHED BY SOURCE AND TRG.I_ObservID = @I_ObservID AND TRG.I_ProcedenciaID = @I_ProcedenciaID
								   AND TRG.I_FilaTablaID = ISNULL(@I_RowID, TRG.I_FilaTablaID) 
								   AND TRG.I_TablaID = @I_TablaID THEN
			UPDATE SET D_FecResuelto = GETDATE(),
					   B_Resuelto = 1;

		SET @T_Message = CAST(@@ROWCOUNT AS varchar)
		SET @B_Resultado = 1

		COMMIT TRANSACTION;
	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION
		SET @B_Resultado = 0
		SET @T_Message = '{ ' +
							 'Type: "error", ' + 
							 'Title: "Error", ' + 
							 'Value: "' + ERROR_MESSAGE() + ' (Linea: ' + CAST(ERROR_LINE() AS varchar(11)) + ')."'  +
						 '}' 
	END CATCH
END
GO



IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_Obligaciones_CuotaPago_MigracionTP_U_Validar_50_RepetidoConDiferentesProcedencias')
BEGIN
	DROP PROCEDURE [dbo].[USP_Obligaciones_CuotaPago_MigracionTP_U_Validar_50_RepetidoConDiferentesProcedencias]
END
GO

CREATE PROCEDURE USP_Obligaciones_CuotaPago_MigracionTP_U_Validar_50_RepetidoConDiferentesProcedencias
	@I_ProcedenciaID tinyint,
	@B_Resultado  bit output,
	@T_Message	  nvarchar(4000) OUTPUT	
AS
/*
	DECLARE @I_ProcedenciaID tinyint = 3,
			@B_Resultado  bit,
			@T_Message	  nvarchar(4000)
	EXEC USP_Obligaciones_CuotaPago_MigracionTP_U_Validar_50_RepetidoConDiferentesProcedencias @I_ProcedenciaID, @B_Resultado output, @T_Message output
	SELECT @B_Resultado as resultado, @T_Message as mensaje
*/
BEGIN	
	DECLARE @D_FecProceso datetime = GETDATE() 
	DECLARE @I_ObservID int = 50
	DECLARE @I_TablaID int = 2 
	DECLARE @I_Observados int = 0

	BEGIN TRY
		SELECT DISTINCT reps.Cuota_pago
		  INTO #temp_cuota_repetida_dif_procedencia
		  FROM (SELECT Cuota_pago FROM TR_Cp_Des 
				GROUP BY Cuota_pago HAVING COUNT(Cuota_pago) > 1) AS reps
				INNER JOIN (SELECT Cuota_pago, I_ProcedenciaID FROM TR_Cp_Des
							GROUP BY Cuota_pago, I_ProcedenciaID HAVING COUNT(Cuota_pago) = 1) noRepsProc 
						   ON reps.Cuota_pago = noRepsProc.Cuota_pago
		

		UPDATE	TR_Cp_Des
		   SET	B_Migrable = 0,
				D_FecEvalua = @D_FecProceso
		  FROM	TR_Cp_Des cp_des
				INNER JOIN #temp_cuota_repetida_dif_procedencia tmp ON cp_des.Cuota_pago = tmp.Cuota_pago
		  WHERE ISNULL(B_Correcto, 0) = 0


		MERGE TI_ObservacionRegistroTabla AS TRG
		USING (SELECT @I_ObservID AS I_ObservID, @I_TablaID AS I_TablaID, I_RowID AS I_FilaTablaID, 
					  @D_FecProceso AS D_FecRegistro 
				 FROM TR_Cp_Des cp_des
					  INNER JOIN #temp_cuota_repetida_dif_procedencia tmp ON cp_des.Cuota_pago = tmp.Cuota_pago
		  		WHERE ISNULL(B_Correcto, 0) = 0
			  ) AS SRC
		ON TRG.I_ObservID = SRC.I_ObservID AND TRG.I_TablaID = SRC.I_TablaID AND TRG.I_FilaTablaID = SRC.I_FilaTablaID
		WHEN MATCHED THEN
			UPDATE SET D_FecRegistro = SRC.D_FecRegistro, 
					   B_Resuelto = 0
		WHEN NOT MATCHED BY TARGET THEN
			INSERT (I_ObservID, I_TablaID, I_FilaTablaID, D_FecRegistro, I_ProcedenciaID)
			VALUES (SRC.I_ObservID, SRC.I_TablaID, SRC.I_FilaTablaID, SRC.D_FecRegistro, @I_ProcedenciaID)
		WHEN NOT MATCHED BY SOURCE AND TRG.I_ObservID = @I_ObservID AND TRG.I_ProcedenciaID = @I_ProcedenciaID
								   AND TRG.I_TablaID = @I_TablaID THEN
			UPDATE SET D_FecResuelto = GETDATE(),
					   B_Resuelto = 1;


		SET @I_Observados = (SELECT COUNT(*) FROM TI_ObservacionRegistroTabla 
							  WHERE I_ObservID = @I_ObservID 
									AND I_TablaID = @I_TablaID 
									AND I_ProcedenciaID = @I_ProcedenciaID 
									AND B_Resuelto = 0)

		SET @B_Resultado = 1
		SET @T_Message = CAST(@I_Observados AS varchar) 
	END TRY
	BEGIN CATCH
		SET @B_Resultado = 0
		SET @T_Message = '{ ' +
							 'Type: "error", ' + 
							 'Title: "Error", ' + 
							 'Value: "' + ERROR_MESSAGE() + ' (Linea: ' + CAST(ERROR_LINE() AS varchar(11)) + ')."'  +
						  '}' 
	END CATCH
END
GO



-----

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_Obligaciones_CuotaPago_MigracionTP_U_ValidarExisteProcesoEnCtasxCobrar')
	DROP PROCEDURE [dbo].[USP_Obligaciones_CuotaPago_MigracionTP_U_ValidarExisteProcesoEnCtasxCobrar]
GO

CREATE PROCEDURE USP_Obligaciones_CuotaPago_MigracionTP_U_ValidarExisteProcesoEnCtasxCobrar
(	
	@I_ProcedenciaID tinyint,
	@B_Resultado  	 bit output,
	@T_Message	  	 nvarchar(4000) OUTPUT	
)
AS
/*
	DECLARE @I_ProcedenciaID tinyint = 3,
			@B_Resultado  	 bit,
			@T_Message	  	 nvarchar(4000)
	EXEC USP_Obligaciones_CuotaPago_MigracionTP_U_ValidarExisteProcesoEnCtasxCobrar @I_ProcedenciaID, @B_Resultado output, @T_Message output
	SELECT @B_Resultado as resultado, @T_Message as mensaje
*/
BEGIN
	DECLARE @I_TablaID int = 2
	DECLARE @I_CountCtas int = 0

	BEGIN TRY 
		
		UPDATE D
		   SET B_ExisteCtas = IIF(P.I_ProcesoID IS NULL, 0, 1)
		  FROM TR_Cp_Des D
		  	   LEFT JOIN BD_OCEF_CtasPorCobrar.dbo.TC_Proceso P ON D.cuota_pago = P.I_ProcesoID 
			   			 										   AND D.Eliminado = P.B_Eliminado
		 WHERE D.I_ProcedenciaID = @I_ProcedenciaID


		SET @I_CountCtas = (SELECT COUNT(*) FROM TR_Cp_Des WHERE B_ExisteCtas = 1 AND I_ProcedenciaID = @I_ProcedenciaID);

		SET @B_Resultado = 1
		SET @T_Message = '{ ' +
							 'Type: "summary", ' + 
							 'Title: "Summary", ' + 
							 'Value: "Cuotas de pago que ya existen en BD Recaudación ' + CAST(@I_CountCtas AS varchar(11)) + '."'  + 
						 '}' 
	END TRY
	BEGIN CATCH
		SET @B_Resultado = 0
		SET @T_Message = '{ ' +
							 'Type: "error", ' + 
							 'Title: "Error", ' + 
							 'Value: "' + ERROR_MESSAGE() + ' (Linea: ' + CAST(ERROR_LINE() AS varchar(11)) + ')."'  +
						 '}' 
	END CATCH
END
GO



IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_Obligaciones_CuotaPago_MigracionTP_U_ValidarExisteCtaDepoEnCtasxCobrar')
	DROP PROCEDURE [dbo].[USP_Obligaciones_CuotaPago_MigracionTP_U_ValidarExisteCtaDepoEnCtasxCobrar]
GO

CREATE PROCEDURE USP_Obligaciones_CuotaPago_MigracionTP_U_ValidarExisteCtaDepoEnCtasxCobrar
(	
	@I_ProcedenciaID tinyint,
	@B_Resultado  	 bit output,
	@T_Message	  	 nvarchar(4000) OUTPUT	
)
AS
/*
	DECLARE @I_ProcedenciaID tinyint = 3,
			@B_Resultado  	 bit,
			@T_Message	  	 nvarchar(4000)
	EXEC USP_Obligaciones_CuotaPago_MigracionTP_U_ValidarExisteCtaDepoEnCtasxCobrar @I_ProcedenciaID, @B_Resultado output, @T_Message output
	SELECT @B_Resultado as resultado, @T_Message as mensaje
*/
BEGIN
	DECLARE @I_TablaID int = 2
	DECLARE @I_CountCtas int = 0

	BEGIN TRY 

		WITH CTE_CtasDepositoProceso AS (
			SELECT CD.I_CtaDepositoID, CD.C_NumeroCuenta, CDP.I_CtaDepoProID, CDP.I_ProcesoID
			  FROM BD_OCEF_CtasPorCobrar.dbo.TC_CuentaDeposito CD 
				   INNER JOIN BD_OCEF_CtasPorCobrar.dbo.TI_CtaDepo_Proceso CDP ON CD.I_CtaDepositoID = CDP.I_CtaDepositoID
			 WHERE CD.B_Habilitado = 1
				   AND CD.I_EntidadFinanID = 1
			 	   AND CDP.B_Habilitado = 1
		)
		
		UPDATE D
		   SET I_CtaDepoProID = CDP.I_CtaDepoProID
		  FROM TR_Cp_Des D
		  	   LEFT JOIN CTE_CtasDepositoProceso CDP ON D.cuota_pago = CDP.I_ProcesoID 
			   										AND D.N_cta_cte = CDP.C_NumeroCuenta
		 WHERE D.I_ProcedenciaID = @I_ProcedenciaID
			   AND Eliminado = 0 

		SET @I_CountCtas = (SELECT COUNT(*) FROM TR_Cp_Des WHERE I_CtaDepoProID IS NOT NULL AND I_ProcedenciaID = @I_ProcedenciaID);

		SET @B_Resultado = 1
		SET @T_Message = '{ ' +
							 'Type: "summary", ' + 
							 'Title: "Summary", ' + 
							 'Value: "Cuentas de deposito proceso que ya existen en BD Recaudación ' + CAST(@I_CountCtas AS varchar(11)) + '."'  + 
						 '}' 
	END TRY
	BEGIN CATCH
		SET @B_Resultado = 0
		SET @T_Message = '{ ' +
							 'Type: "error", ' + 
							 'Title: "Error", ' + 
							 'Value: "' + ERROR_MESSAGE() + ' (Linea: ' + CAST(ERROR_LINE() AS varchar(11)) + ')."'  +
						 '}' 
	END CATCH
END
GO



IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_Obligaciones_CuotaPago_MigracionTP_CtasPorCobrar_I_MigrarCtaDeposito')
	DROP PROCEDURE [dbo].[USP_Obligaciones_CuotaPago_MigracionTP_CtasPorCobrar_I_MigrarCtaDeposito]
GO

CREATE PROCEDURE USP_Obligaciones_CuotaPago_MigracionTP_CtasPorCobrar_I_MigrarCtaDeposito
(	
	@I_ProcesoID	  int = NULL,
	@I_ProcedenciaID tinyint,
	@B_Resultado  	 bit output,
	@T_Message	  	 nvarchar(4000) OUTPUT	
)
AS
/*
	DECLARE @I_ProcesoID	  int = NULL,
			@I_ProcedenciaID tinyint = 3,
			@B_Resultado  	 bit,
			@T_Message	  	 nvarchar(4000)
	EXEC USP_Obligaciones_CuotaPago_MigracionTP_CtasPorCobrar_I_MigrarCtaDeposito @I_ProcesoID, @I_ProcedenciaID, @B_Resultado output, @T_Message output
	SELECT @B_Resultado as resultado, @T_Message as mensaje
*/
BEGIN
	DECLARE @I_TablaID int = 2
	DECLARE @I_CountCtas int = 0
	DECLARE @D_FecProceso datetime = GETDATE() 
	DECLARE @I_UsuarioID int = (SELECT dbo.Func_Config_CtasPorCobrar_I_ObtenerUsuarioMigracionID())

	BEGIN TRY 

		DECLARE @Tbl_outputCtas AS TABLE (T_Action varchar(20), I_RowID int)

		MERGE INTO BD_OCEF_CtasPorCobrar.dbo.TI_CtaDepo_Proceso AS TRG
		USING (SELECT CD.I_CtaDepositoID, TP_CD.* FROM TR_Cp_Des TP_CD
					  INNER JOIN BD_OCEF_CtasPorCobrar.dbo.TC_CuentaDeposito CD ON CD.C_NumeroCuenta COLLATE DATABASE_DEFAULT = TP_CD.N_CTA_CTE COLLATE DATABASE_DEFAULT
				WHERE B_ExisteCtas = 1 
					  AND TP_CD.Eliminado = 0
					  AND cuota_pago = ISNULL(@I_ProcesoID, cuota_pago)
					  AND I_ProcedenciaID = @I_ProcedenciaID
			   ) AS SRC
		ON TRG.I_ProcesoID = SRC.CUOTA_PAGO AND TRG.I_CtaDepositoID = SRC.I_CtaDepositoID
		WHEN NOT MATCHED BY TARGET THEN
			INSERT (I_CtaDepositoID, I_ProcesoID, B_Habilitado, B_Eliminado, D_FecCre, I_UsuarioCre)
			VALUES (I_CtaDepositoID, CUOTA_PAGO, 1, ELIMINADO, @D_FecProceso, @I_UsuarioID)
		OUTPUT $action, SRC.I_RowID INTO @Tbl_outputCtas;

		SET @I_CountCtas = (SELECT COUNT(*) FROM @Tbl_outputCtas);

		
		DECLARE @B_Resultado2  	 bit,
				@T_Message2	  	 nvarchar(4000)

		EXEC USP_Obligaciones_CuotaPago_MigracionTP_U_ValidarExisteCtaDepoEnCtasxCobrar @I_ProcedenciaID, @B_Resultado2 OUTPUT, @T_Message2 OUTPUT


		SET @B_Resultado = 1
		SET @T_Message = '{ ' +
							 'Type: "summary", ' + 
							 'Title: "Summary", ' + 
							 'Value: "Se registraron ' + CAST(@I_CountCtas AS varchar(11)) + ' nuevas cuentas de deposito proceso en la BD de recaudación."'  + 
						 '}' 
	END TRY
	BEGIN CATCH
		SET @B_Resultado = 0
		SET @T_Message = '{ ' +
							 'Type: "error", ' + 
							 'Title: "Error", ' + 
							 'Value: "' + ERROR_MESSAGE() + ' (Linea: ' + CAST(ERROR_LINE() AS varchar(11)) + ')."'  +
						 '}' 
	END CATCH
END
GO


