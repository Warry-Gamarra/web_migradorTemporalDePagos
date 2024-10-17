/*
=========================================================
	BD_OCEF_MigracionTP - 05_Procedures_ConceptoPago
=========================================================
*/


USE BD_OCEF_MigracionTP
GO


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_IU_CopiarTablaConceptoDePago')
	DROP PROCEDURE [dbo].[USP_IU_CopiarTablaConceptoDePago]
GO

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_Obligaciones_ConceptoPago_TemporalPagos_MigracionTP_IU_CopiarTabla')
	DROP PROCEDURE [dbo].[USP_Obligaciones_ConceptoPago_TemporalPagos_MigracionTP_IU_CopiarTabla]
GO

CREATE PROCEDURE [dbo].[USP_Obligaciones_ConceptoPago_TemporalPagos_MigracionTP_IU_CopiarTabla]
	@I_ProcedenciaID tinyint,
	@T_SchemaDB		 varchar(20),
	@T_Codigo_bnc	 varchar(250),
	@B_IgnoreUpdated bit,
	@B_Resultado  bit output,
	@T_Message	  nvarchar(4000) OUTPUT	
AS
/*
	declare @B_Resultado  bit,
			@I_ProcedenciaID	tinyint = 3,
			@T_SchemaDB			varchar(20) = 'euded',
			@T_Codigo_bnc		varchar(250) = '''0658'', ''0685'', ''0687'', ''0688''',
			@B_IgnoreUpdated	bit = 0,
			@T_Message	  nvarchar(4000)
	exec USP_Obligaciones_ConceptoPago_TemporalPagos_MigracionTP_IU_CopiarTabla @I_ProcedenciaID, @T_SchemaDB, @T_Codigo_bnc, @B_Resultado output, @T_Message output
	select @B_Resultado as resultado, @T_Message as mensaje
*/
BEGIN
	DECLARE @T_SQL nvarchar(max)

	DECLARE @I_CpPri int = 0
	DECLARE @I_Removidos int = 0
	DECLARE @I_Actualizados int = 0
	DECLARE @I_Insertados int = 0
	DECLARE @D_FecProceso datetime = GETDATE() 

	CREATE TABLE #Tbl_output  
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
		INS_MONTO		float,			INS_DESCRIPCIO	nvarchar(500),
		INS_CALCULAR	nvarchar(255),	INS_GRADO		float,
		INS_TIP_ALUMNO	float,			INS_GRUPO_RC	nvarchar(255),
		INS_FRACCIONAB	bit,			INS_CONCEPTO_G	bit,
		INS_DOCUMENTO	nvarchar(500),	INS_MONTO_MIN	nvarchar(255),
		INS_DESCRIP_L	nvarchar(1000),	INS_COD_DEP_PL	nvarchar(255),
		
		DEL_CUOTA_PAGO	float, 			DEL_ANO			nvarchar(255),		
		DEL_P			nvarchar(255),	DEL_COD_RC		nvarchar(255),
		DEL_COD_ING		nvarchar(255), 	DEL_TIPO_OBLIG	bit,		
		DEL_CLASIFICAD	nvarchar(255),	DEL_CLASIFIC_5	nvarchar(255),		
		DEL_ID_CP_AGRP	float,			DEL_AGRUPA		bit,		
		DEL_NRO_PAGOS	float,			DEL_ID_CP_AFEC	float,
		DEL_PORCENTAJE	bit,			DEL_MONTO		float,
		DEL_DESCRIPCIO	nvarchar(500),	DEL_CALCULAR	nvarchar(255),
		DEL_GRADO		float,			DEL_TIP_ALUMNO	float,
		DEL_GRUPO_RC	nvarchar(255),	DEL_FRACCIONAB	bit,
		DEL_CONCEPTO_G	bit,			DEL_DOCUMENTO	nvarchar(500),
		DEL_MONTO_MIN	nvarchar(255),	DEL_DESCRIP_L	nvarchar(1000),
		DEL_COD_DEP_PL	nvarchar(255),	DEL_OBLIG_MORA	nvarchar(255)
	)

	BEGIN TRY 
		
		SET @T_SQL = 'DECLARE @D_FecProceso datetime = GETDATE() ' + CHAR(13) + 			 
					 'MERGE TR_Cp_Pri AS TRG ' + CHAR(13) + 
					 'USING (SELECT cp_pri.* FROM BD_OCEF_TemporalPagos.' + @T_SchemaDB + '.cp_pri cp_pri ' + CHAR(13) + 
					 '							  LEFT JOIN BD_OCEF_TemporalPagos.' + @T_SchemaDB + '.cp_des cp_des ON cp_pri.cuota_pago = cp_des.cuota_pago ' + CHAR(13) + 
					 '		  WHERE cp_des.codigo_bnc IN (' + @T_Codigo_bnc + ') AND cp_des.Eliminado = 0) AS SRC ' + CHAR(13) + 
					 'ON TRG.Id_cp = SRC.id_cp ' + CHAR(13) + 
					 '	 AND TRG.Cuota_pago = SRC.cuota_pago ' + CHAR(13) + 
					 '	 AND TRG.Eliminado = SRC.eliminado ' + CHAR(13) + 
						 IIF(@B_IgnoreUpdated = 0, '		AND TRG.B_Actualizado = 0' + CHAR(13),'') +
					 'WHEN MATCHED THEN ' + CHAR(13) + 
					 '	UPDATE SET	TRG.Cuota_pago = SRC.cuota_pago, TRG.Ano = SRC.ano, TRG.P = SRC.p, ' + CHAR(13) + 
					 '				TRG.Cod_rc = SRC.cod_rc, TRG.Cod_Ing = SRC.cod_ing, TRG.Tipo_oblig = SRC.tipo_oblig, ' + CHAR(13) + 
					 '				TRG.Clasificad = SRC.clasificad, TRG.Clasific_5 = SRC.clasific_5, ' + CHAR(13) + 
					 '				TRG.Agrupa = SRC.agrupa, TRG.Nro_pagos = SRC.nro_pagos, TRG.Id_cp_afec = SRC.id_cp_afec, ' + CHAR(13) + 
					 '				TRG.Porcentaje = SRC.porcentaje, TRG.Monto = SRC.monto, TRG.Id_cp_agrp = SRC.id_cp_agrp, ' + CHAR(13) + 
					 '				TRG.Descripcio = SRC.descripcio, TRG.Calcular = SRC.calcular, TRG.Grado = SRC.grado, ' + CHAR(13) + 
					 '				TRG.Tip_alumno = SRC.tip_alumno, TRG.Grupo_rc = SRC.grupo_rc, TRG.Fraccionab = SRC.fraccionab, ' + CHAR(13) + 
					 '				TRG.Concepto_g = SRC.concepto_g, TRG.Documento = SRC.documento, TRG.Monto_min = SRC.monto_min, ' + CHAR(13) + 
					 '				TRG.Descrip_l = SRC.descrip_l, TRG.Cod_dep_pl = SRC.cod_dep_pl, TRG.Oblig_mora = SRC.oblig_mora, ' + CHAR(13) + 
					 '				TRG.I_ProcedenciaID = ' + CAST(@I_ProcedenciaID as varchar(3)) + ' ' + CHAR(13) + 
					 'WHEN NOT MATCHED BY TARGET THEN ' + CHAR(13) + 
					 '	INSERT (Id_cp, Cuota_pago, Ano, P, Cod_rc, Cod_Ing, Tipo_oblig, Clasificad, Clasific_5, Id_cp_agrp, Agrupa, Nro_pagos, Id_cp_afec, Porcentaje, Monto, ' + CHAR(13) + 
					 '			Eliminado, Descripcio, Calcular, Grado, Tip_alumno, Grupo_rc, Fraccionab, Concepto_g, Documento, Monto_min, Descrip_l, Cod_dep_pl, Oblig_mora, ' + CHAR(13) + 
					 '			D_FecCarga, I_ProcedenciaID) ' + CHAR(13) + 
					 '	VALUES (id_cp, cuota_pago, ano, p, cod_rc, cod_ing, tipo_oblig, clasificad, clasific_5, id_cp_agrp, agrupa, nro_pagos, id_cp_afec, porcentaje, monto, ' + CHAR(13) + 
					 '			Eliminado, Descripcio, Calcular, Grado, Tip_alumno, Grupo_rc, Fraccionab, Concepto_g, CAST(documento as varchar(max)), monto_min, CAST(descrip_l as varchar(max)), cod_dep_pl, oblig_mora, ' + CHAR(13) + 
					 '			@D_FecProceso, ' + CAST(@I_ProcedenciaID as varchar(3)) + ') ' + CHAR(13) + 
					 'WHEN NOT MATCHED BY SOURCE AND TRG.I_ProcedenciaID = '+ CAST(@I_ProcedenciaID as varchar(3)) + ' THEN ' + CHAR(13) + 
					 '	UPDATE SET TRG.B_Removido = 1, ' + CHAR(13) + 
					 '			   TRG.D_FecRemovido = @D_FecProceso ' + CHAR(13) + 
					 'OUTPUT	$ACTION, inserted.ID_CP, inserted.ELIMINADO, deleted.B_Removido, inserted.CUOTA_PAGO, inserted.OBLIG_MORA, inserted.ANO, inserted.P, ' + CHAR(13) + 
					 '		inserted.COD_RC, inserted.COD_ING, inserted.TIPO_OBLIG, inserted.CLASIFICAD, inserted.CLASIFIC_5, inserted.ID_CP_AGRP, inserted.AGRUPA, ' + CHAR(13) + 
					 '		inserted.NRO_PAGOS, inserted.ID_CP_AFEC, inserted.PORCENTAJE, inserted.MONTO, inserted.DESCRIPCIO, inserted.CALCULAR, inserted.GRADO, ' + CHAR(13) + 
					 '		inserted.TIP_ALUMNO, inserted.GRUPO_RC, inserted.FRACCIONAB, inserted.CONCEPTO_G, inserted.DOCUMENTO, inserted.MONTO_MIN, inserted.DESCRIP_L, ' + CHAR(13) + 
					 '		inserted.COD_DEP_PL, ' + CHAR(13) + 
					 '		deleted.CUOTA_PAGO, deleted.ANO, deleted.P, deleted.COD_RC, deleted.COD_ING, deleted.TIPO_OBLIG, deleted.CLASIFICAD, deleted.CLASIFIC_5, ' + CHAR(13) + 
					 '		deleted.ID_CP_AGRP, deleted.AGRUPA, deleted.NRO_PAGOS, deleted.ID_CP_AFEC, deleted.PORCENTAJE, deleted.MONTO, deleted.DESCRIPCIO, deleted.CALCULAR, ' + CHAR(13) + 
					 '		deleted.GRADO, deleted.TIP_ALUMNO, deleted.GRUPO_RC, deleted.FRACCIONAB, deleted.CONCEPTO_G, deleted.DOCUMENTO, deleted.MONTO_MIN, deleted.DESCRIP_L, ' + CHAR(13) + 
					 '		deleted.COD_DEP_PL, deleted.OBLIG_MORA INTO #Tbl_output; '

		print @T_SQL
		Exec sp_executesql @T_SQL

		UPDATE	TR_Cp_Pri 
				SET	B_Actualizado = IIF(@B_IgnoreUpdated = 1, 0, B_Actualizado), 
					D_FecEvalua = IIF(@B_IgnoreUpdated = 1, 0, D_FecEvalua), 
					B_Migrable = 0, 
					D_FecMigrado = NULL, 
					B_Migrado = 0,
					I_TipAluID = NULL, I_TipGradoID = NULL, I_TipOblID = NULL, I_TipCalcID = NULL, 
					I_TipPerID = NULL, I_DepID = NULL, I_TipGrpRc = NULL, I_CodIngID = NULL
		WHERE I_ProcedenciaID = @I_ProcedenciaID

		UPDATE	t_CpPri
		SET		t_CpPri.B_Actualizado = 1,
				t_CpPri.D_FecActualiza = @D_FecProceso
		FROM TR_Cp_Pri AS t_CpPri
		INNER JOIN 	#Tbl_output as t_out ON t_out.ID_CP = t_CpPri.ID_CP AND t_out.ELIMINADO = t_CpPri.ELIMINADO 
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


		SET @T_SQL = 'SELECT id_cp FROM BD_OCEF_TemporalPagos.' + @T_SchemaDB + '.cp_pri'
		print @T_SQL
		Exec sp_executesql @T_SQL

		SET @I_CpPri = @@ROWCOUNT
		SET @I_Insertados = (SELECT COUNT(*) FROM #Tbl_output WHERE accion = 'INSERT')
		SET @I_Actualizados = (SELECT COUNT(*) FROM #Tbl_output WHERE accion = 'UPDATE' AND B_Removido = 0)
		SET @I_Removidos = (SELECT COUNT(*) FROM #Tbl_output WHERE accion = 'UPDATE' AND B_Removido = 1)


		SELECT @I_CpPri AS tot_concetoPago, @I_Insertados AS cant_inserted, @I_Actualizados as cant_updated, @I_Removidos as cant_removed, @D_FecProceso as fec_proceso
		
		SET @B_Resultado = 1
		SET @T_Message =  '[{ ' +
							 'Type: "summary", ' + 
							 'Title: "Total", '+ 
							 'Value: ' + CAST(@I_CpPri AS varchar) +
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
		SET @B_Resultado = 0
		SET @T_Message = '[{ ' +
							 'Type: "error", ' + 
							 'Title: "Error", ' + 
							 'Value: "' + ERROR_MESSAGE() + ' (Linea: ' + CAST(ERROR_LINE() AS varchar(11)) + ')."'  +
						  '}]' 
	END CATCH
END
GO




IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_Obligaciones_ConceptoPago_MigracionTP_U_Validar_12_13_Repetidos')
	DROP PROCEDURE [dbo].[USP_Obligaciones_ConceptoPago_MigracionTP_U_Validar_12_13_Repetidos]
GO

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_Obligaciones_ConceptoPago_MigracionTP_U_Validar_12_RepetidoActivo')
	DROP PROCEDURE [dbo].[USP_Obligaciones_ConceptoPago_MigracionTP_U_Validar_12_RepetidoActivo]
GO

CREATE PROCEDURE USP_Obligaciones_ConceptoPago_MigracionTP_U_Validar_12_RepetidoActivo	
	@I_RowID	  int = NULL,
	@I_ProcedenciaID tinyint,
	@B_Resultado  bit output,
	@T_Message	  nvarchar(4000) OUTPUT	
AS
/*
	DESCRIPCION: B_Migrable = 0 cuando el concepto de pago se encuentra repetido con estado ACTIVO.

	DECLARE @I_RowID	  int = NULL,
			@I_ProcedenciaID tinyint = 3,
			@B_Resultado  bit,
			@T_Message	  nvarchar(4000)
	EXEC USP_Obligaciones_ConceptoPago_MigracionTP_U_Validar_12_RepetidoActivo @I_RowID, @I_ProcedenciaID, @B_Resultado output, @T_Message output
	SELECT @B_Resultado as resultado, @T_Message as mensaje
*/
BEGIN
	DECLARE @D_FecProceso datetime = GETDATE() 
	DECLARE @I_ObservID_activo int = 12
	DECLARE @I_TablaID int = 3
	DECLARE @I_Observados_activos int = 0
	
	BEGIN TRANSACTION
	BEGIN TRY 
		
		SELECT Id_cp
		  INTO #temp_repetido_estado_activo
		  FROM TR_Cp_Pri 
		 WHERE I_ProcedenciaID = @I_ProcedenciaID
			   AND Eliminado = 0
		GROUP BY Id_cp HAVING COUNT(Id_cp) > 1 

		UPDATE	TR_Cp_Pri
		SET		B_Migrable = 0,
				D_FecEvalua = @D_FecProceso
		FROM	TR_Cp_Pri c_pri 
				INNER JOIN #temp_repetido_estado_activo tmp ON c_pri.Id_cp = tmp.Id_cp
		WHERE	Eliminado = 0 
				AND ISNULL(B_Correcto, 0) = 0  
				AND I_RowID = ISNULL(@I_RowID, I_RowID)


		MERGE TI_ObservacionRegistroTabla AS TRG
		USING (SELECT	@I_ObservID_activo AS I_ObservID, @I_TablaID AS I_TablaID, I_RowID AS I_FilaTablaID, 
						@D_FecProceso AS D_FecRegistro 
				FROM	TR_Cp_Pri c_pri 
						INNER JOIN #temp_repetido_estado_activo tmp ON c_pri.Id_cp = tmp.Id_cp
				WHERE	Eliminado = 0 
						AND ISNULL(B_Correcto, 0) = 0  
						AND I_RowID = ISNULL(@I_RowID, I_RowID)
			  ) AS SRC
		ON TRG.I_ObservID = SRC.I_ObservID AND TRG.I_TablaID = SRC.I_TablaID AND TRG.I_FilaTablaID = SRC.I_FilaTablaID
		WHEN MATCHED THEN
			UPDATE SET D_FecRegistro = SRC.D_FecRegistro, 
					   B_Resuelto = 0
		WHEN NOT MATCHED BY TARGET THEN
			INSERT (I_ObservID, I_TablaID, I_FilaTablaID, D_FecRegistro, I_ProcedenciaID, B_ObligProc)
			VALUES (SRC.I_ObservID, SRC.I_TablaID, SRC.I_FilaTablaID, SRC.D_FecRegistro, @I_ProcedenciaID, 1)
		WHEN NOT MATCHED BY SOURCE AND TRG.I_ObservID = @I_ObservID_activo  
								   AND TRG.I_ProcedenciaID = @I_ProcedenciaID 
								   AND TRG.I_TablaID = @I_TablaID
								   AND TRG.I_FilaTablaID = ISNULL(@I_RowID, TRG.I_FilaTablaID) THEN
			UPDATE SET D_FecResuelto = @D_FecProceso,
					   B_Resuelto = 1;


		SET @I_Observados_activos = (SELECT COUNT(*) FROM TI_ObservacionRegistroTabla 
									  WHERE I_ObservID = @I_ObservID_activo 
											AND I_TablaID = @I_TablaID 
											AND I_ProcedenciaID = @I_ProcedenciaID
											AND I_FilaTablaID = ISNULL(@I_RowID, I_FilaTablaID)
											AND B_Resuelto = 0)

		COMMIT TRANSACTION

		SET @B_Resultado = 1
		SET @T_Message = CAST(@I_Observados_activos AS varchar)
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


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_Obligaciones_ConceptoPago_MigracionTP_U_Validar_13_RepetidosEliminado')
	DROP PROCEDURE [dbo].[USP_Obligaciones_ConceptoPago_MigracionTP_U_Validar_13_RepetidosEliminado]
GO

CREATE PROCEDURE USP_Obligaciones_ConceptoPago_MigracionTP_U_Validar_13_RepetidosEliminado	
	@I_RowID	  int = NULL,
	@I_ProcedenciaID tinyint,
	@B_Resultado  bit output,
	@T_Message	  nvarchar(4000) OUTPUT	
AS
/*
	DESCRIPCION: B_Migrable = 0 cuando el concepto de pago se encuentra repetido con estado ELIMINADO.

	DECLARE @I_RowID	  int = NULL,
			@I_ProcedenciaID tinyint = 3,
			@B_Resultado  bit,
			@T_Message	  nvarchar(4000)
	EXEC USP_Obligaciones_ConceptoPago_MigracionTP_U_Validar_13_RepetidosEliminado @I_RowID, @I_ProcedenciaID, @B_Resultado output, @T_Message output
	SELECT @B_Resultado as resultado, @T_Message as mensaje
*/
BEGIN
	DECLARE @D_FecProceso datetime = GETDATE() 
	DECLARE @I_ObservID_eliminado int = 13
	DECLARE @I_TablaID int = 3
	DECLARE @I_Observados_eliminados int = 0
	
	BEGIN TRANSACTION
	BEGIN TRY 
		
		SELECT Id_cp
		  INTO #temp_conceptopago_repetido
		  FROM TR_Cp_Pri 
		 WHERE I_ProcedenciaID = @I_ProcedenciaID
		GROUP BY Id_cp HAVING COUNT(Id_cp) > 1 

		UPDATE	TR_Cp_Pri
		SET		B_Migrable = 0,
				D_FecEvalua = @D_FecProceso
		FROM	TR_Cp_Pri c_pri 
				INNER JOIN #temp_conceptopago_repetido tmp ON c_pri.Id_cp = tmp.Id_cp
		WHERE	Eliminado = 1 
				AND ISNULL(B_Correcto, 0) = 0  
				AND I_RowID = ISNULL(@I_RowID, I_RowID)


		MERGE TI_ObservacionRegistroTabla AS TRG
		USING (SELECT @I_ObservID_eliminado AS I_ObservID, @I_TablaID AS I_TablaID, I_RowID AS I_FilaTablaID, 
					  @D_FecProceso AS D_FecRegistro 
				 FROM TR_Cp_Pri c_pri 
					  INNER JOIN #temp_conceptopago_repetido tmp ON c_pri.Id_cp = tmp.Id_cp
				WHERE Eliminado = 1 
					  AND ISNULL(B_Correcto, 0) = 0  
					  AND I_RowID = ISNULL(@I_RowID, I_RowID)
			  ) AS SRC
		ON TRG.I_ObservID = SRC.I_ObservID AND TRG.I_TablaID = SRC.I_TablaID AND TRG.I_FilaTablaID = SRC.I_FilaTablaID
		WHEN MATCHED THEN
			UPDATE SET D_FecRegistro = SRC.D_FecRegistro, 
					   B_Resuelto = 0
		WHEN NOT MATCHED BY TARGET THEN
			INSERT (I_ObservID, I_TablaID, I_FilaTablaID, D_FecRegistro, I_ProcedenciaID, B_ObligProc)
			VALUES (SRC.I_ObservID, SRC.I_TablaID, SRC.I_FilaTablaID, SRC.D_FecRegistro, @I_ProcedenciaID, 1)
		WHEN NOT MATCHED BY SOURCE AND TRG.I_ObservID = @I_ObservID_eliminado 
								   AND TRG.I_ProcedenciaID = @I_ProcedenciaID 
								   AND TRG.I_TablaID = @I_TablaID
								   AND TRG.I_FilaTablaID = ISNULL(@I_RowID, TRG.I_FilaTablaID) THEN
			UPDATE SET D_FecResuelto = @D_FecProceso,
					   B_Resuelto = 1;


		SET @I_Observados_eliminados = (SELECT COUNT(*) FROM TI_ObservacionRegistroTabla 
									     WHERE I_ObservID = @I_ObservID_eliminado 
									   		   AND I_TablaID = @I_TablaID 
									   		   AND I_ProcedenciaID = @I_ProcedenciaID
									   		   AND I_FilaTablaID = ISNULL(@I_RowID, I_FilaTablaID)
									   		   AND B_Resuelto = 0
									   )

		COMMIT TRANSACTION;

		SET @B_Resultado = 1
		SET @T_Message = CAST(@I_Observados_eliminados AS varchar)
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




IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_Obligaciones_ConceptoPago_MigracionTP_U_Validar_14_SinAnio')
	DROP PROCEDURE [dbo].[USP_Obligaciones_ConceptoPago_MigracionTP_U_Validar_14_SinAnio]
GO

CREATE PROCEDURE USP_Obligaciones_ConceptoPago_MigracionTP_U_Validar_14_SinAnio	
	@I_RowID		 int = NULL,
	@I_ProcedenciaID tinyint,
	@B_Resultado	 bit output,
	@T_Message		 nvarchar(4000) OUTPUT	
AS
/*
	DESCRIPCION: B_Migrable = 0 cuando el concepto de pago de obligacion sin año asignado.

	DECLARE @I_RowID	  int = NULL,
			@I_ProcedenciaID tinyint = 3,
			@B_Resultado  bit,
			@T_Message	  nvarchar(4000)
	EXEC USP_Obligaciones_ConceptoPago_MigracionTP_U_Validar_14_SinAnio @I_RowID, @I_ProcedenciaID, @B_Resultado output, @T_Message output
	SELECT @B_Resultado as resultado, @T_Message as mensaje
*/
BEGIN
	DECLARE @D_FecProceso datetime = GETDATE() 
	DECLARE @I_ObservID_sinAnio int = 14
	DECLARE @I_TablaID int = 3
	DECLARE @I_Observados_sinAnio int = 0
	
	BEGIN TRANSACTION
	BEGIN TRY 
		UPDATE	TR_Cp_Pri
		SET		B_Migrable = 0,
				D_FecEvalua = @D_FecProceso
		WHERE	ISNULL(Ano, 0) = 0 
				AND Tipo_oblig = 1
				AND I_ProcedenciaID = @I_ProcedenciaID
				AND Eliminado = 0
				AND I_RowID = ISNULL(@I_RowID, I_RowID)


		MERGE TI_ObservacionRegistroTabla AS TRG
		USING (SELECT @I_ObservID_sinAnio AS I_ObservID, @I_TablaID AS I_TablaID, I_RowID AS I_FilaTablaID, @D_FecProceso AS D_FecRegistro 
				 FROM TR_Cp_Pri 
				WHERE ISNULL(Ano, 0) = 0 
					  AND Tipo_oblig = 1
					  AND I_ProcedenciaID = @I_ProcedenciaID
					  AND Eliminado = 0
					  AND I_RowID = ISNULL(@I_RowID, I_RowID)
			  ) AS SRC
		ON TRG.I_ObservID = SRC.I_ObservID AND TRG.I_TablaID = SRC.I_TablaID AND TRG.I_FilaTablaID = SRC.I_FilaTablaID
		WHEN MATCHED THEN
			UPDATE SET D_FecRegistro = SRC.D_FecRegistro, 
					   B_Resuelto = 0
		WHEN NOT MATCHED BY TARGET THEN
			INSERT (I_ObservID, I_TablaID, I_FilaTablaID, D_FecRegistro, I_ProcedenciaID, B_ObligProc)
			VALUES (SRC.I_ObservID, SRC.I_TablaID, SRC.I_FilaTablaID, SRC.D_FecRegistro, @I_ProcedenciaID, 1)
		WHEN NOT MATCHED BY SOURCE AND TRG.I_ObservID = @I_ObservID_sinAnio 
								   AND TRG.I_ProcedenciaID = @I_ProcedenciaID 
								   AND TRG.I_TablaID = @I_TablaID
								   AND TRG.I_FilaTablaID = ISNULL(@I_RowID, TRG.I_FilaTablaID) THEN
			UPDATE SET D_FecResuelto = @D_FecProceso,
					   B_Resuelto = 1;


		SET @I_Observados_sinAnio = (SELECT COUNT(*) FROM TI_ObservacionRegistroTabla 
									  WHERE I_ObservID = @I_ObservID_sinAnio 
											AND I_TablaID = @I_TablaID 
											AND I_ProcedenciaID = @I_ProcedenciaID
											AND I_FilaTablaID = ISNULL(@I_RowID, I_FilaTablaID)
											AND B_Resuelto = 0
									)

		COMMIT TRANSACTION;

		SET @B_Resultado = 1
		SET @T_Message = CAST(@I_Observados_sinAnio AS varchar)

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


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_U_MarcarConceptosPagoObligSinPeriodoAsignado')
	DROP PROCEDURE [dbo].[USP_U_MarcarConceptosPagoObligSinPeriodoAsignado]
GO

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_Obligaciones_ConceptoPago_MigracionTP_U_Validar_16_SinPeriodoAsignado')
	DROP PROCEDURE [dbo].[USP_Obligaciones_ConceptoPago_MigracionTP_U_Validar_16_SinPeriodoAsignado]
GO

CREATE PROCEDURE USP_Obligaciones_ConceptoPago_MigracionTP_U_Validar_16_SinPeriodoAsignado	
	@I_RowID	  int = NULL,
	@I_ProcedenciaID tinyint,
	@B_Resultado  bit output,
	@T_Message	  nvarchar(4000) OUTPUT	
AS
/*
	DESCRIPCION: B_Migrable = 0 cuando el concepto de pago ha sido ingresado o modificado desde una fuente externa.

	DECLARE @I_RowID	  int = NULL,
			@I_ProcedenciaID tinyint = 3,
			@B_Resultado  bit,
			@T_Message	  nvarchar(4000)
	EXEC USP_Obligaciones_ConceptoPago_MigracionTP_U_Validar_16_SinPeriodoAsignado @I_RowID, @I_ProcedenciaID, @B_Resultado output, @T_Message output
	SELECT @B_Resultado as resultado, @T_Message as mensaje
*/
BEGIN
	DECLARE @D_FecProceso datetime = GETDATE() 
	DECLARE @I_ObservID_sinPer int = 16
	DECLARE @I_TablaID int = 3
	DECLARE @I_Observados_sinPer int = 0
	
	BEGIN TRANSACTION 
	BEGIN TRY 
		UPDATE	TR_Cp_Pri
		SET		B_Migrable = 0,
				D_FecEvalua = @D_FecProceso
		WHERE	ISNULL(P,'') = '' 
				AND TIPO_OBLIG = 1
				AND I_ProcedenciaID = @I_ProcedenciaID
				AND Eliminado = 0
				AND I_RowID = ISNULL(@I_RowID, I_RowID)

		MERGE TI_ObservacionRegistroTabla AS TRG
		USING (SELECT	@I_ObservID_sinPer AS I_ObservID, @I_TablaID AS I_TablaID, I_RowID AS I_FilaTablaID, @D_FecProceso AS D_FecRegistro 
				 FROM	TR_Cp_Pri 
				WHERE	ISNULL(P,'') = '' 
						AND TIPO_OBLIG = 1
						AND I_ProcedenciaID = @I_ProcedenciaID
						AND Eliminado = 0
						AND I_RowID = ISNULL(@I_RowID, I_RowID)
			  ) AS SRC
		ON TRG.I_ObservID = SRC.I_ObservID AND TRG.I_TablaID = SRC.I_TablaID AND TRG.I_FilaTablaID = SRC.I_FilaTablaID
		WHEN MATCHED THEN
			UPDATE SET D_FecRegistro = SRC.D_FecRegistro, 
					   B_Resuelto = 0
		WHEN NOT MATCHED BY TARGET THEN
			INSERT (I_ObservID, I_TablaID, I_FilaTablaID, D_FecRegistro, I_ProcedenciaID, B_ObligProc)
			VALUES (SRC.I_ObservID, SRC.I_TablaID, SRC.I_FilaTablaID, SRC.D_FecRegistro, @I_ProcedenciaID, 1)
		WHEN NOT MATCHED BY SOURCE AND TRG.I_ObservID = @I_ObservID_sinPer 
								   AND TRG.I_ProcedenciaID = @I_ProcedenciaID 
								   AND TRG.I_TablaID = @I_TablaID
								   AND TRG.I_FilaTablaID = ISNULL(@I_RowID, TRG.I_FilaTablaID) THEN
			UPDATE SET D_FecResuelto = @D_FecProceso,
					   B_Resuelto = 1;

		SET @I_Observados_sinPer = (SELECT COUNT(*) FROM TI_ObservacionRegistroTabla 
									 WHERE I_ObservID = @I_ObservID_sinPer  
											AND I_TablaID = @I_TablaID 
											AND I_ProcedenciaID = @I_ProcedenciaID
											AND I_FilaTablaID = ISNULL(@I_RowID, I_FilaTablaID)
											AND B_Resuelto = 0)

		COMMIT TRANSACTION

		SET @B_Resultado = 1
		SET @T_Message = CAST(@I_Observados_sinPer AS varchar)
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


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_Obligaciones_ConceptoPago_MigracionTP_U_Validar_18_SinCuotaPago')
	DROP PROCEDURE [dbo].[USP_Obligaciones_ConceptoPago_MigracionTP_U_Validar_18_SinCuotaPago]
GO

CREATE PROCEDURE USP_Obligaciones_ConceptoPago_MigracionTP_U_Validar_18_SinCuotaPago	
	@I_RowID	  int = NULL,
	@I_ProcedenciaID tinyint,
	@B_Resultado  bit output,
	@T_Message	  nvarchar(4000) OUTPUT	
AS
/*
	DESCRIPCION: B_Migrable = 0 cuando la cuota de pago asociada no es migrable.

	DECLARE @I_RowID	  int = NULL,
			@I_ProcedenciaID tinyint = 3,
			@B_Resultado  bit,
			@T_Message	  nvarchar(4000)
	EXEC USP_Obligaciones_ConceptoPago_MigracionTP_U_Validar_18_SinCuotaPago @I_RowID, @I_ProcedenciaID, @B_Resultado output, @T_Message output
	SELECT @B_Resultado as resultado, @T_Message as mensaje
*/
BEGIN
	DECLARE @D_FecProceso datetime = GETDATE() 
	DECLARE @I_ObservID_sinCuota int = 18
	DECLARE @I_TablaID int = 3
	DECLARE @I_Observados_sinCuota int = 0
	
	BEGIN TRANSACTION
	BEGIN TRY 
		UPDATE	c_pri
		SET		B_Migrable = 0,
				D_FecEvalua = @D_FecProceso
		FROM	TR_Cp_Pri c_pri 
				INNER JOIN TR_Cp_Des c_des ON c_des.Cuota_pago = c_pri.Cuota_Pago 
											  AND c_des.I_ProcedenciaID = c_pri.I_ProcedenciaID
		WHERE	c_pri.Eliminado = 0
				AND c_pri.Tipo_oblig = 1 
				AND c_pri.I_ProcedenciaID = @I_ProcedenciaID
				AND c_pri.I_RowID = ISNULL(@I_RowID, c_pri.I_RowID)

			
		MERGE TI_ObservacionRegistroTabla AS TRG
		USING (SELECT @I_Observados_sinCuota AS I_ObservID, @I_TablaID AS I_TablaID, c_pri.I_RowID AS I_FilaTablaID, @D_FecProceso AS D_FecRegistro 
				 FROM TR_Cp_Pri c_pri 
					  INNER JOIN TR_Cp_Des c_des ON c_des.Cuota_pago = c_pri.Cuota_Pago 
													AND c_des.I_ProcedenciaID = c_pri.I_ProcedenciaID
				WHERE c_pri.Eliminado = 0
					  AND c_pri.Tipo_oblig = 1 
					  AND c_pri.I_ProcedenciaID = @I_ProcedenciaID
					  AND c_pri.I_RowID = ISNULL(@I_RowID, c_pri.I_RowID)
			  ) AS SRC
		ON TRG.I_ObservID = SRC.I_ObservID AND TRG.I_TablaID = SRC.I_TablaID AND TRG.I_FilaTablaID = SRC.I_FilaTablaID
		WHEN MATCHED THEN
			UPDATE SET D_FecRegistro = SRC.D_FecRegistro, 
					   B_Resuelto = 0
		WHEN NOT MATCHED BY TARGET THEN
			INSERT (I_ObservID, I_TablaID, I_FilaTablaID, D_FecRegistro, I_ProcedenciaID, B_ObligProc)
			VALUES (SRC.I_ObservID, SRC.I_TablaID, SRC.I_FilaTablaID, SRC.D_FecRegistro, @I_ProcedenciaID, 1)
		WHEN NOT MATCHED BY SOURCE AND TRG.I_ObservID = @I_Observados_sinCuota 
								   AND TRG.I_ProcedenciaID = @I_ProcedenciaID 
								   AND TRG.I_TablaID = @I_TablaID
								   AND TRG.I_FilaTablaID = ISNULL(@I_RowID, TRG.I_FilaTablaID) THEN
			UPDATE SET D_FecResuelto = @D_FecProceso,
					   B_Resuelto = 1;

		SET @I_Observados_sinCuota = (SELECT COUNT(*) FROM TI_ObservacionRegistroTabla 
									   WHERE I_ObservID = @I_Observados_sinCuota 
									   		 AND I_TablaID = @I_TablaID 
											 AND I_ProcedenciaID = @I_ProcedenciaID
											 AND I_FilaTablaID = ISNULL(@I_RowID, I_FilaTablaID)
											 AND B_Resuelto = 0
									  )

		COMMIT TRANSACTION;

		SET @B_Resultado = 1
		SET @T_Message = CAST(@I_Observados_sinCuota AS varchar)
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


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_Obligaciones_ConceptoPago_MigracionTP_U_Validar_19_SinCuotaPagoMigrada')
	DROP PROCEDURE [dbo].[USP_Obligaciones_ConceptoPago_MigracionTP_U_Validar_19_SinCuotaPagoMigrada]
GO

CREATE PROCEDURE USP_Obligaciones_ConceptoPago_MigracionTP_U_Validar_19_SinCuotaPagoMigrada	
	@I_RowID	  int = NULL,
	@I_ProcedenciaID tinyint,
	@B_Resultado  bit output,
	@T_Message	  nvarchar(4000) OUTPUT	
AS
/*
	DESCRIPCION: B_Migrable = 0 cuando la cuota de pago asociada no es migrable.

	DECLARE @I_RowID	  int = NULL,
			@I_ProcedenciaID tinyint = 3,
			@B_Resultado  bit,
			@T_Message	  nvarchar(4000)
	EXEC USP_Obligaciones_ConceptoPago_MigracionTP_U_Validar_19_SinCuotaPagoMigrada @I_RowID, @I_ProcedenciaID, @B_Resultado output, @T_Message output
	SELECT @B_Resultado as resultado, @T_Message as mensaje
*/
BEGIN
	DECLARE @D_FecProceso datetime = GETDATE() 
	DECLARE @I_ObservID_CuotaNoM int = 19
	DECLARE @I_TablaID int = 3
	DECLARE @I_Observados_CuotaNoM int = 0
	
	BEGIN TRANSACTION
	BEGIN TRY 
		UPDATE	c_pri
		SET		B_Migrable = 0,
				D_FecEvalua = @D_FecProceso
		FROM	TR_Cp_Pri c_pri 
				INNER JOIN TR_Cp_Des c_des ON c_des.Cuota_pago = c_pri.Cuota_Pago 
											  AND c_des.I_ProcedenciaID = c_pri.I_ProcedenciaID
		WHERE	c_des.B_Migrable = 0
				AND c_pri.I_ProcedenciaID = @I_ProcedenciaID
				AND c_pri.I_RowID = ISNULL(@I_RowID, c_pri.I_RowID)

			
		MERGE TI_ObservacionRegistroTabla AS TRG
		USING (SELECT @I_ObservID_CuotaNoM AS I_ObservID, @I_TablaID AS I_TablaID, c_pri.I_RowID AS I_FilaTablaID, @D_FecProceso AS D_FecRegistro 
				 FROM TR_Cp_Pri c_pri 
					  INNER JOIN TR_Cp_Des c_des ON c_des.Cuota_pago = c_pri.Cuota_Pago 
													AND c_des.I_ProcedenciaID = c_pri.I_ProcedenciaID
				WHERE c_des.B_Migrable = 0
					  AND c_pri.I_ProcedenciaID = @I_ProcedenciaID
					  AND c_pri.I_RowID = ISNULL(@I_RowID, c_pri.I_RowID)
			  ) AS SRC
		ON TRG.I_ObservID = SRC.I_ObservID AND TRG.I_TablaID = SRC.I_TablaID AND TRG.I_FilaTablaID = SRC.I_FilaTablaID
		WHEN MATCHED THEN
			UPDATE SET D_FecRegistro = SRC.D_FecRegistro, 
					   B_Resuelto = 0
		WHEN NOT MATCHED BY TARGET THEN
			INSERT (I_ObservID, I_TablaID, I_FilaTablaID, D_FecRegistro, I_ProcedenciaID, B_ObligProc)
			VALUES (SRC.I_ObservID, SRC.I_TablaID, SRC.I_FilaTablaID, SRC.D_FecRegistro, @I_ProcedenciaID, 1)
		WHEN NOT MATCHED BY SOURCE AND TRG.I_ObservID = @I_ObservID_CuotaNoM 
								   AND TRG.I_ProcedenciaID = @I_ProcedenciaID 
								   AND TRG.I_TablaID = @I_TablaID
								   AND TRG.I_FilaTablaID = ISNULL(@I_RowID, TRG.I_FilaTablaID) THEN
			UPDATE SET D_FecResuelto = @D_FecProceso,
					   B_Resuelto = 1;

		SET @I_Observados_CuotaNoM = (SELECT COUNT(*) FROM TI_ObservacionRegistroTabla 
									   WHERE I_ObservID = @I_ObservID_CuotaNoM 
									   		 AND I_TablaID = @I_TablaID 
											 AND I_ProcedenciaID = @I_ProcedenciaID
											 AND I_FilaTablaID = ISNULL(@I_RowID, I_FilaTablaID)
											 AND B_Resuelto = 0
									 )
		
		COMMIT TRANSACTION;

		SET @B_Resultado = 1
		SET @T_Message = CAST(@I_Observados_CuotaNoM AS varchar)
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


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_Obligaciones_ConceptoPago_MigracionTP_U_Validar_20_IngresadoFuenteExterna')
	DROP PROCEDURE [dbo].[USP_Obligaciones_ConceptoPago_MigracionTP_U_Validar_20_IngresadoFuenteExterna]
GO

CREATE PROCEDURE USP_Obligaciones_ConceptoPago_MigracionTP_U_Validar_20_IngresadoFuenteExterna	
	@I_RowID	  int = NULL,
	@I_ProcedenciaID tinyint,
	@B_Resultado  bit output,
	@T_Message	  nvarchar(4000) OUTPUT	
AS
/*
	DESCRIPCION: B_Migrable = 0 cuando el concepto de pago ha sido ingresado o modificado desde una fuente externa.

	DECLARE @I_RowID	  int = NULL,
			@I_ProcedenciaID tinyint = 3,
			@B_Resultado  bit,
			@T_Message	  nvarchar(4000)
	EXEC USP_Obligaciones_ConceptoPago_MigracionTP_U_Validar_20_IngresadoFuenteExterna @I_RowID, @I_ProcedenciaID, @B_Resultado output, @T_Message output
	SELECT @B_Resultado as resultado, @T_Message as mensaje
*/
BEGIN
	DECLARE @D_FecProceso datetime = GETDATE() 
	DECLARE @I_ObservID int = 20
	DECLARE @I_TablaID int = 3
	DECLARE @I_Observados int = 0
	DECLARE @I_UsuarioID int = (SELECT dbo.Func_Config_CtasPorCobrar_I_ObtenerUsuarioMigracionID())

	BEGIN TRANSACTION
	BEGIN TRY 

		UPDATE	cp_pri
		   SET	B_Migrable = 0,
				D_FecEvalua = @D_FecProceso
		  FROM  TR_Cp_Pri cp_pri
				INNER JOIN BD_OCEF_CtasPorCobrar.dbo.TI_ConceptoPago ctas_cp ON cp_pri.Id_cp = ctas_cp.I_ConcPagID
																				AND cp_pri.Cuota_pago = ctas_cp.I_ProcesoID
		WHERE	cp_pri.I_ProcedenciaID = @I_ProcedenciaID
				AND ctas_cp.I_ProcesoID < 513
				AND ISNULL(ctas_cp.I_UsuarioCre, @I_UsuarioID) <> @I_UsuarioID
				AND cp_pri.I_RowID = ISNULL(@I_RowID, cp_pri.I_RowID)

		-- Cuotas de pago entre 2021 y 2022
		UPDATE	cp_pri
		   SET	B_Migrable = 0,
				D_FecEvalua = @D_FecProceso
		  FROM  TR_Cp_Pri cp_pri
				INNER JOIN BD_OCEF_CtasPorCobrar.dbo.TI_ConceptoPago ctas_cp ON cp_pri.Cuota_pago = ctas_cp.I_ProcesoID
																				AND cp_pri.Descripcio = ctas_cp.T_ConceptoPagoDesc
																				AND cp_pri.Monto = ctas_cp.M_Monto
		WHERE	cp_pri.I_ProcedenciaID = @I_ProcedenciaID
				AND ctas_cp.I_ProcesoID BETWEEN 513 AND 522
				AND ISNULL(ctas_cp.I_UsuarioCre, @I_UsuarioID) <> @I_UsuarioID
				AND cp_pri.I_RowID = ISNULL(@I_RowID, cp_pri.I_RowID)


		MERGE TI_ObservacionRegistroTabla AS TRG
		USING (SELECT @I_ObservID AS I_ObservID, @I_TablaID AS I_TablaID, I_RowID AS I_FilaTablaID, @D_FecProceso AS D_FecRegistro 
				 FROM TR_Cp_Pri cp_pri
					  INNER JOIN BD_OCEF_CtasPorCobrar.dbo.TI_ConceptoPago ctas_cp ON cp_pri.Id_cp = ctas_cp.I_ConcPagID
																						AND cp_pri.Cuota_pago = ctas_cp.I_ProcesoID
				WHERE cp_pri.I_ProcedenciaID = @I_ProcedenciaID
					  AND ctas_cp.I_ProcesoID < 513
					  AND ISNULL(ctas_cp.I_UsuarioCre, @I_UsuarioID) <> @I_UsuarioID 
					  AND cp_pri.I_RowID = ISNULL(@I_RowID, cp_pri.I_RowID)
				UNION 
				SELECT @I_ObservID AS I_ObservID, @I_TablaID AS I_TablaID, I_RowID AS I_FilaTablaID, @D_FecProceso AS D_FecRegistro 
				  FROM TR_Cp_Pri cp_pri
					   INNER JOIN BD_OCEF_CtasPorCobrar.dbo.TI_ConceptoPago ctas_cp ON cp_pri.Cuota_pago = ctas_cp.I_ProcesoID
																						AND cp_pri.Descripcio = ctas_cp.T_ConceptoPagoDesc
																						AND cp_pri.Monto = ctas_cp.M_Monto
				 WHERE cp_pri.I_ProcedenciaID = @I_ProcedenciaID
				   	   AND ctas_cp.I_ProcesoID BETWEEN 513 AND 522
					   AND ISNULL(ctas_cp.I_UsuarioCre, @I_UsuarioID) <> @I_UsuarioID 
					   AND cp_pri.I_RowID = ISNULL(@I_RowID, cp_pri.I_RowID)
			  ) AS SRC
		ON TRG.I_ObservID = SRC.I_ObservID AND TRG.I_TablaID = SRC.I_TablaID 
		   AND TRG.I_FilaTablaID = SRC.I_FilaTablaID AND TRG.I_ProcedenciaID = @I_ProcedenciaID
		WHEN MATCHED  THEN
			UPDATE SET D_FecRegistro = SRC.D_FecRegistro,
					   B_Resuelto = 0,
					   B_ObligProc = 1
		WHEN NOT MATCHED BY TARGET THEN
			INSERT (I_ObservID, I_TablaID, I_FilaTablaID, D_FecRegistro, I_ProcedenciaID, B_ObligProc)
			VALUES (SRC.I_ObservID, SRC.I_TablaID, SRC.I_FilaTablaID, SRC.D_FecRegistro, @I_ProcedenciaID, 1)
		WHEN NOT MATCHED BY SOURCE AND TRG.I_ObservID = @I_ObservID 
								   AND TRG.I_ProcedenciaID = @I_ProcedenciaID 
								   AND TRG.I_TablaID = @I_TablaID
								   AND TRG.I_FilaTablaID = ISNULL(@I_RowID, TRG.I_FilaTablaID) THEN
			UPDATE SET D_FecResuelto = @D_FecProceso,
					   B_Resuelto = 1;


		SET @I_Observados = (SELECT COUNT(*) FROM TI_ObservacionRegistroTabla 
							  WHERE I_ObservID = @I_ObservID 
									AND I_TablaID = @I_TablaID 
									AND I_ProcedenciaID = @I_ProcedenciaID
									AND I_FilaTablaID = ISNULL(@I_RowID, I_FilaTablaID)
									AND B_Resuelto = 0
						 )

		COMMIT TRANSACTION

		SET @B_Resultado = 1
		SET @T_Message = CAST(@I_Observados AS varchar)

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


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_Obligaciones_ConceptoPago_MigracionTP_U_Validar_45_Eliminados')
	DROP PROCEDURE [dbo].[USP_Obligaciones_ConceptoPago_MigracionTP_U_Validar_45_Eliminados]
GO

CREATE PROCEDURE USP_Obligaciones_ConceptoPago_MigracionTP_U_Validar_45_Eliminados	
	@I_RowID	  int = NULL,
	@I_ProcedenciaID tinyint,
	@B_Resultado  bit output,
	@T_Message	  nvarchar(4000) OUTPUT	
AS
/*
	DESCRIPCION: B_Migrable = 0 cuando el registro se encuentra con estado Eliminado.

	DECLARE @I_RowID	  int = NULL,
			@I_ProcedenciaID tinyint = 3,
			@B_Resultado  bit,
			@T_Message	  nvarchar(4000)
	EXEC USP_Obligaciones_ConceptoPago_MigracionTP_U_Validar_45_Eliminados @I_RowID, @I_ProcedenciaID, @B_Resultado output, @T_Message output
	SELECT @B_Resultado as resultado, @T_Message as mensaje
*/
BEGIN
	DECLARE @D_FecProceso datetime = GETDATE() 
	DECLARE @I_ObservID int = 45
	DECLARE @I_TablaID int = 3
	DECLARE @I_Observados int = 0
	
	BEGIN TRANSACTION
	BEGIN TRY 
		UPDATE	TR_Cp_Pri
		SET		B_Migrable = 0,
				D_FecEvalua = @D_FecProceso
		WHERE	I_ProcedenciaID = @I_ProcedenciaID
				AND Eliminado = 1
				AND I_RowID = ISNULL(@I_RowID, I_RowID)

		MERGE TI_ObservacionRegistroTabla AS TRG
		USING (SELECT @I_ObservID AS I_ObservID, @I_TablaID AS I_TablaID, I_RowID AS I_FilaTablaID, @D_FecProceso AS D_FecRegistro 
				 FROM TR_Cp_Pri 
				 WHERE I_ProcedenciaID = @I_ProcedenciaID
					   AND Eliminado = 1
					   AND I_RowID = ISNULL(@I_RowID, I_RowID)
			  ) AS SRC
		ON TRG.I_ObservID = SRC.I_ObservID AND TRG.I_TablaID = SRC.I_TablaID 
		   AND TRG.I_FilaTablaID = SRC.I_FilaTablaID AND TRG.I_ProcedenciaID = @I_ProcedenciaID
		WHEN MATCHED  THEN
			UPDATE SET D_FecRegistro = SRC.D_FecRegistro,
					   B_Resuelto = 0,
					   B_ObligProc = 1
		WHEN NOT MATCHED BY TARGET THEN
			INSERT (I_ObservID, I_TablaID, I_FilaTablaID, D_FecRegistro, I_ProcedenciaID, B_ObligProc)
			VALUES (SRC.I_ObservID, SRC.I_TablaID, SRC.I_FilaTablaID, SRC.D_FecRegistro, @I_ProcedenciaID, 1)
		WHEN NOT MATCHED BY SOURCE AND TRG.I_ObservID = @I_ObservID 
								   AND TRG.I_ProcedenciaID = @I_ProcedenciaID 
								   AND TRG.I_TablaID = @I_TablaID
								   AND TRG.I_FilaTablaID = ISNULL(@I_RowID, TRG.I_FilaTablaID) THEN
			UPDATE SET D_FecResuelto = @D_FecProceso,
					   B_Resuelto = 1;


		SET @I_Observados = (SELECT COUNT(*) FROM TI_ObservacionRegistroTabla 
								WHERE I_ObservID = @I_ObservID 
									  AND I_TablaID = @I_TablaID 
									  AND I_ProcedenciaID = @I_ProcedenciaID
									  AND I_FilaTablaID = ISNULL(@I_RowID, I_FilaTablaID)
									  AND B_Resuelto = 0
						 )

		COMMIT TRANSACTION

		SET @B_Resultado = 1
		SET @T_Message = CAST(@I_Observados AS varchar)

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


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_U_MarcarConceptosPagoNoObligacion')
	DROP PROCEDURE [dbo].[USP_U_MarcarConceptosPagoNoObligacion]
GO

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_Obligaciones_ConceptoPago_MigracionTP_U_Validar_46_TipoObligacion')
	DROP PROCEDURE [dbo].[USP_Obligaciones_ConceptoPago_MigracionTP_U_Validar_46_TipoObligacion]
GO

CREATE PROCEDURE USP_Obligaciones_ConceptoPago_MigracionTP_U_Validar_46_TipoObligacion	
	@I_RowID	  int = NULL,
	@I_ProcedenciaID tinyint,
	@B_Resultado  bit output,
	@T_Message	  nvarchar(4000) OUTPUT	
AS
/*
	DESCRIPCION: B_Migrable = 0 cuando el concepto de pago contiene falso en el campo obligación.

	DECLARE @I_RowID	  int = NULL,
			@I_ProcedenciaID tinyint = 3,
			@B_Resultado  bit,
			@T_Message	  nvarchar(4000)
	EXEC USP_Obligaciones_ConceptoPago_MigracionTP_U_Validar_46_TipoObligacion @I_RowID, @I_ProcedenciaID, @B_Resultado output, @T_Message output
	SELECT @B_Resultado as resultado, @T_Message as mensaje
*/
BEGIN
	DECLARE @D_FecProceso datetime = GETDATE() 
	DECLARE @I_ObservID int = 46
	DECLARE @I_TablaID int = 3
	DECLARE @I_Observados int = 0
	
	BEGIN TRY 
		UPDATE	TR_Cp_Pri
		SET		B_Migrable = 0,
				D_FecEvalua = @D_FecProceso
		WHERE	Tipo_oblig = 0
				AND I_ProcedenciaID = @I_ProcedenciaID
				AND Eliminado = 0
				AND I_RowID = ISNULL(@I_RowID, I_RowID)


		MERGE TI_ObservacionRegistroTabla AS TRG
		USING (SELECT @I_ObservID AS I_ObservID, @I_TablaID AS I_TablaID, I_RowID AS I_FilaTablaID, @D_FecProceso AS D_FecRegistro 
				 FROM TR_Cp_Pri 
				WHERE Tipo_oblig = 0 
					  AND Eliminado = 0
					  AND I_ProcedenciaID = @I_ProcedenciaID
					  AND I_RowID = ISNULL(@I_RowID, I_RowID)
			  ) AS SRC
		ON TRG.I_ObservID = SRC.I_ObservID AND TRG.I_TablaID = SRC.I_TablaID AND TRG.I_FilaTablaID = SRC.I_FilaTablaID
		WHEN MATCHED THEN
			UPDATE SET D_FecRegistro = SRC.D_FecRegistro, 
					   B_Resuelto = 0,
					   B_ObligProc = 1
		WHEN NOT MATCHED BY TARGET THEN
			INSERT (I_ObservID, I_TablaID, I_FilaTablaID, D_FecRegistro, I_ProcedenciaID, B_ObligProc)
			VALUES (SRC.I_ObservID, SRC.I_TablaID, SRC.I_FilaTablaID, SRC.D_FecRegistro, @I_ProcedenciaID, 1)
		WHEN NOT MATCHED BY SOURCE AND TRG.I_ObservID = @I_ObservID AND TRG.I_ProcedenciaID = @I_ProcedenciaID  
								   AND TRG.I_FilaTablaID = ISNULL(@I_RowID, TRG.I_FilaTablaID)
								   AND TRG.I_TablaID = @I_TablaID THEN
			UPDATE SET D_FecResuelto = @D_FecProceso,
					   B_Resuelto = 1;


		SET @I_Observados = (SELECT COUNT(*) FROM TI_ObservacionRegistroTabla 
								WHERE I_ObservID = @I_ObservID 
									  AND I_TablaID = @I_TablaID 
									  AND I_ProcedenciaID = @I_ProcedenciaID
									  AND I_FilaTablaID = ISNULL(@I_RowID, I_FilaTablaID)
									  AND B_Resuelto = 0
							)

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


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_Tasas_ConceptoPago_MigracionTP_U_Validar_51_TipoObligacion')
	DROP PROCEDURE [dbo].[USP_Tasas_ConceptoPago_MigracionTP_U_Validar_51_TipoObligacion]
GO

CREATE PROCEDURE dbo.USP_Tasas_ConceptoPago_MigracionTP_U_Validar_51_TipoObligacion
(
	@I_RowID	  int = NULL,
	@I_ProcedenciaID tinyint,
	@B_Resultado  bit output,
	@T_Message	  nvarchar(4000) OUTPUT	
)
AS
/*
	DESCRIPCION: B_Migrable = 0 cuando el concepto de pago de tasas contiene verdadero en el campo obligación

	DECLARE @I_RowID	  int = NULL,
			@I_ProcedenciaID tinyint = 4,
			@B_Resultado  bit,
			@T_Message	  nvarchar(4000)
	EXEC USP_Obligaciones_ConceptoPago_MigracionTP_U_Validar_46_TipoObligacion @I_RowID, @I_ProcedenciaID, @B_Resultado output, @T_Message output
	SELECT @B_Resultado as resultado, @T_Message as mensaje
*/

BEGIN
	DECLARE @D_FecProceso datetime = GETDATE() 
	DECLARE @I_ObservID int = 51
	DECLARE @I_TablaID int = 3
	DECLARE @I_Observados int = 0

	BEGIN TRANSACTION
	BEGIN TRY
		UPDATE	TR_Cp_Pri
		SET		B_Migrable = 0,
				D_FecEvalua = @D_FecProceso
		WHERE	Tipo_oblig = 1
				AND I_ProcedenciaID = @I_ProcedenciaID
				AND Eliminado = 0
				AND I_RowID = ISNULL(@I_RowID, I_RowID)
		
		MERGE TI_ObservacionRegistroTabla AS TRG
		USING (SELECT @I_ObservID AS I_ObservID, @I_TablaID AS I_TablaID, I_RowID AS I_FilaTablaID, @D_FecProceso AS D_FecRegistro 
				 FROM TR_Cp_Pri 
				WHERE Tipo_oblig = 1
					  AND Eliminado = 0
					  AND I_ProcedenciaID = @I_ProcedenciaID
					  AND I_RowID = ISNULL(@I_RowID, I_RowID)
			  ) AS SRC
		ON TRG.I_ObservID = SRC.I_ObservID AND TRG.I_TablaID = SRC.I_TablaID AND TRG.I_FilaTablaID = SRC.I_FilaTablaID
		WHEN MATCHED THEN
			UPDATE SET D_FecRegistro = SRC.D_FecRegistro, 
					   B_Resuelto = 0,
					   B_ObligProc = 0
		WHEN NOT MATCHED BY TARGET THEN
			INSERT (I_ObservID, I_TablaID, I_FilaTablaID, D_FecRegistro, I_ProcedenciaID, B_ObligProc)
			VALUES (SRC.I_ObservID, SRC.I_TablaID, SRC.I_FilaTablaID, SRC.D_FecRegistro, @I_ProcedenciaID, 0)
		WHEN NOT MATCHED BY SOURCE AND TRG.I_ObservID = @I_ObservID AND TRG.I_ProcedenciaID = @I_ProcedenciaID  
								   AND TRG.I_FilaTablaID = ISNULL(@I_RowID, TRG.I_FilaTablaID)
								   AND TRG.I_TablaID = @I_TablaID THEN
			UPDATE SET D_FecResuelto = @D_FecProceso,
					   B_Resuelto = 1;		


		SET @I_Observados = (SELECT COUNT(*) FROM TI_ObservacionRegistroTabla 
											WHERE I_ObservID = @I_ObservID 
												  AND I_TablaID = @I_TablaID 
												  AND I_ProcedenciaID = @I_ProcedenciaID
												  AND I_FilaTablaID = ISNULL(@I_RowID, I_FilaTablaID)
												  AND B_Resuelto = 0
							)

		COMMIT TRANSACTION

		SET @B_Resultado = 1
		SET @T_Message = CAST(@I_Observados AS varchar) 

	END TRY
	BEGIN CATCH
		IF(@@TRANCOUNT > 0)
		BEGIN
			ROLLBACK TRANSACTION
		END

		SET @B_Resultado = 0
		SET @T_Message = ERROR_MESSAGE() + ' LINE: ' + CAST(ERROR_LINE() AS varchar(10)) 
	END CATCH

END
GO



IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_Obligaciones_ConceptoPago_MigracionTP_U_VerificarExisteEnCtas')
	DROP PROCEDURE [dbo].[USP_Obligaciones_ConceptoPago_MigracionTP_U_VerificarExisteEnCtas]
GO

CREATE PROCEDURE USP_Obligaciones_ConceptoPago_MigracionTP_U_VerificarExisteEnCtas	
	@I_RowID	  int = NULL,
	@I_ProcedenciaID tinyint,
	@B_Resultado  bit output,
	@T_Message	  nvarchar(4000) OUTPUT	
AS
/*
	DECLARE @I_RowID	  int = NULL,
			@I_ProcedenciaID tinyint = 3,
			@B_Resultado  bit,
			@T_Message	  nvarchar(4000)
	EXEC USP_Obligaciones_ConceptoPago_MigracionTP_U_VerificarExisteEnCtas @I_RowID, @I_ProcedenciaID, @B_Resultado output, @T_Message output
	SELECT @B_Resultado as resultado, @T_Message as mensaje
*/
BEGIN
	DECLARE @D_FecProceso datetime = GETDATE() 
	DECLARE @I_TablaID	int = 3
	DECLARE @I_Count	int = 0
	
	BEGIN TRY 
		UPDATE	cp_pri
		   SET	cp_pri.B_ExisteCtas = IIF(I_ConcPagID IS NULL, 0, 1)
		  FROM  TR_Cp_Pri cp_pri
				LEFT JOIN BD_OCEF_CtasPorCobrar.dbo.TI_ConceptoPago ctas_cp ON cp_pri.I_EquivDestinoID = ctas_cp.I_ConcPagID
																				AND cp_pri.Cuota_pago = ctas_cp.I_ProcesoID
		WHERE	cp_pri.I_ProcedenciaID = @I_ProcedenciaID
				AND I_RowID = ISNULL(@I_RowID, I_RowID)

		SET @I_Count = (SELECT COUNT(Id_cp) FROM TR_Cp_Pri WHERE I_ProcedenciaID = @I_ProcedenciaID AND B_ExisteCtas = 1)

		SET @B_Resultado = 1
		SET @T_Message = '{ ' +
							 'Type: "summary", ' + 
							 'Title: "Summary", ' + 
							 'Value: "Existen ' + CAST(@I_Count as varchar(11)) + ' conceptos de pago registrados en BD de Recaudaci�n."'  +
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







IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_Obligaciones_ConceptoPago_MigracionTP_U_VerificarMigracionEnCtas')
	DROP PROCEDURE [dbo].[USP_Obligaciones_ConceptoPago_MigracionTP_U_VerificarMigracionEnCtas]
GO

CREATE PROCEDURE USP_Obligaciones_ConceptoPago_MigracionTP_U_VerificarMigracionEnCtas	
	@I_RowID	  int = NULL,
	@I_ProcedenciaID tinyint,
	@B_Resultado  bit output,
	@T_Message	  nvarchar(4000) OUTPUT	
AS
/*
	DECLARE @I_RowID	  int = NULL,
			@I_ProcedenciaID tinyint = 3,
			@B_Resultado  bit,
			@T_Message	  nvarchar(4000)
	EXEC USP_Obligaciones_ConceptoPago_MigracionTP_U_VerificarMigracionEnCtas @I_RowID, @I_ProcedenciaID, @B_Resultado output, @T_Message output
	SELECT @B_Resultado as resultado, @T_Message as mensaje
*/
BEGIN
	DECLARE @D_FecProceso datetime = GETDATE() 
	DECLARE @I_TablaID	int = 3
	DECLARE @I_Count	int = 0
	
	BEGIN TRY 
		UPDATE	cp_pri
		   SET	cp_pri.B_Migrado = ctas_cp.B_Migrado
		  FROM  TR_Cp_Pri cp_pri
				INNER JOIN BD_OCEF_CtasPorCobrar.dbo.TI_ConceptoPago ctas_cp ON cp_pri.Id_cp = ctas_cp.I_ConcPagID
																				AND cp_pri.Cuota_pago = ctas_cp.I_ProcesoID
		WHERE	cp_pri.I_ProcedenciaID = @I_ProcedenciaID
				AND I_RowID = ISNULL(@I_RowID, I_RowID)

		UPDATE	ctas_cp
		   SET	ctas_cp.I_MigracionRowID = cp_pri.I_RowID,
				ctas_cp.I_MigracionTablaID = @I_TablaID
		  FROM  TR_Cp_Pri cp_pri
				INNER JOIN BD_OCEF_CtasPorCobrar.dbo.TI_ConceptoPago ctas_cp ON cp_pri.Id_cp = ctas_cp.I_ConcPagID
																				AND cp_pri.Cuota_pago = ctas_cp.I_ProcesoID
		WHERE	cp_pri.I_ProcedenciaID = @I_ProcedenciaID
				AND ctas_cp.B_Migrado = 1
				AND I_RowID = ISNULL(@I_RowID, I_RowID)


		SET @I_Count = (SELECT COUNT(Id_cp) FROM TR_Cp_Pri WHERE I_ProcedenciaID = @I_ProcedenciaID AND B_Migrado = 1)

		SET @B_Resultado = 1
		SET @T_Message = '{ ' +
							 'Type: "summary", ' + 
							 'Title: "Summary", ' + 
							 'Value: "Existen ' + CAST(@I_Count as varchar(11)) + ' conceptos de pago registrados en BD de Recaudaci�n."'  +
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


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_Obligaciones_ConceptoPago_MigracionTP_U_ActualizarEquivalenciaCtasID')
	DROP PROCEDURE [dbo].[USP_Obligaciones_ConceptoPago_MigracionTP_U_ActualizarEquivalenciaCtasID]
GO

CREATE PROCEDURE USP_Obligaciones_ConceptoPago_MigracionTP_U_ActualizarEquivalenciaCtasID	
	@I_ProcedenciaID tinyint,
	@B_Resultado  bit output,
	@T_Message	  nvarchar(4000) OUTPUT	
AS
/*
	DECLARE @I_ProcedenciaID tinyint = 3,
			@B_Resultado  bit,
			@T_Message	  nvarchar(4000)
	EXEC USP_Obligaciones_ConceptoPago_MigracionTP_U_ActualizarEquivalenciaCtasID @I_ProcedenciaID, @B_Resultado output, @T_Message output
	SELECT @B_Resultado as resultado, @T_Message as mensaje
*/
BEGIN
	DECLARE @D_FecProceso datetime = GETDATE() 
	DECLARE @I_TablaID	int = 3
	DECLARE @I_Count	int = 0
	
	BEGIN TRY 
		-- Cuotas de pago antes del 2021

		UPDATE	cp_pri
		   SET	cp_pri.I_EquivDestinoID = ctas_cp.I_ConcPagID
		  FROM  TR_Cp_Pri cp_pri
				INNER JOIN BD_OCEF_CtasPorCobrar.dbo.TI_ConceptoPago ctas_cp ON cp_pri.Id_cp = ctas_cp.I_ConcPagID
																				AND cp_pri.Cuota_pago = ctas_cp.I_ProcesoID
		WHERE	cp_pri.I_ProcedenciaID = @I_ProcedenciaID
				AND ctas_cp.I_ProcesoID < 513

		-- Cuotas de pago entre 2021 y 2022
		UPDATE	cp_pri
		   SET	cp_pri.I_EquivDestinoID = ctas_cp.I_ConcPagID
		  FROM  TR_Cp_Pri cp_pri
				INNER JOIN BD_OCEF_CtasPorCobrar.dbo.TI_ConceptoPago ctas_cp ON cp_pri.Cuota_pago = ctas_cp.I_ProcesoID
																				AND cp_pri.Descripcio = ctas_cp.T_ConceptoPagoDesc
																				AND cp_pri.Monto = ctas_cp.M_Monto
		WHERE	cp_pri.I_ProcedenciaID = @I_ProcedenciaID
				AND ctas_cp.I_ProcesoID BETWEEN 513 AND 522


		SET @I_Count = (SELECT COUNT(Id_cp) FROM TR_Cp_Pri WHERE I_ProcedenciaID = @I_ProcedenciaID AND B_Migrado = 1)

		SET @B_Resultado = 1
		SET @T_Message = '{ ' +
							 'Type: "summary", ' + 
							 'Title: "Summary", ' + 
							 'Value: "Existen ' + CAST(@I_Count as varchar(11)) + ' conceptos de pago registrados en BD de Recaudaci�n."'  +
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

