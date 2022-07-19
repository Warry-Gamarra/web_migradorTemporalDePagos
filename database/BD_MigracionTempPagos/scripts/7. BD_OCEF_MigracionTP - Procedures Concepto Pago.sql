USE BD_OCEF_MigracionTP
GO

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_IU_CopiarTablaConceptoDePago')
	DROP PROCEDURE [dbo].[USP_IU_CopiarTablaConceptoDePago]
GO

CREATE PROCEDURE USP_IU_CopiarTablaConceptoDePago
	@I_ProcedenciaID tinyint,
	@T_SchemaDB		 varchar(20),
	@T_Codigo_bnc	 varchar(250),
	@B_Resultado  bit output,
	@T_Message	  nvarchar(4000) OUTPUT	
AS
--declare @B_Resultado  bit,
--		@I_ProcedenciaID	tinyint = 3,
--		@T_SchemaDB			varchar(20) = 'euded',
--		@T_Codigo_bnc		varchar(250) = '''0658'', ''0685'', ''0687'', ''0688''',
--		@T_Message	  nvarchar(4000)
--exec USP_IU_CopiarTablaConceptoDePago @I_ProcedenciaID, @T_SchemaDB, @T_Codigo_bnc, @B_Resultado output, @T_Message output
--select @B_Resultado as resultado, @T_Message as mensaje
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
		
		SET @T_SQL = 'DECLARE @D_FecProceso datetime = GETDATE()			 
					  MERGE TR_Cp_Pri AS TRG
					  USING (SELECT cp_pri.* FROM BD_OCEF_TemporalPagos.' + @T_SchemaDB + '.cp_pri cp_pri 
									  INNER JOIN BD_OCEF_TemporalPagos.' + @T_SchemaDB + '.cp_des cp_des ON cp_pri.cuota_pago = cp_des.cuota_pago 
									  WHERE cp_des.codigo_bnc IN (' + @T_Codigo_bnc + ') AND cp_des.Eliminado = 0) AS SRC
					  ON	TRG.Id_cp = SRC.id_cp 
						AND TRG.Cuota_pago = SRC.cuota_pago 
					  	AND TRG.Eliminado = SRC.eliminado
					  WHEN MATCHED THEN
					  	UPDATE SET	TRG.Cuota_pago = SRC.cuota_pago, TRG.Ano = SRC.ano, TRG.P = SRC.p,
					  				TRG.Cod_rc = SRC.cod_rc, TRG.Cod_Ing = SRC.cod_ing, TRG.Tipo_oblig = SRC.tipo_oblig,
					  				TRG.Clasificad = SRC.clasificad, TRG.Clasific_5 = SRC.clasific_5, 
					  				TRG.Agrupa = SRC.agrupa, TRG.Nro_pagos = SRC.nro_pagos, TRG.Id_cp_afec = SRC.id_cp_afec,
					  				TRG.Porcentaje = SRC.porcentaje, TRG.Monto = SRC.monto, TRG.Id_cp_agrp = SRC.id_cp_agrp,
					  				TRG.Descripcio = SRC.descripcio, TRG.Calcular = SRC.calcular, TRG.Grado = SRC.grado,
					  				TRG.Tip_alumno = SRC.tip_alumno, TRG.Grupo_rc = SRC.grupo_rc, TRG.Fraccionab = SRC.fraccionab,
					  				TRG.Concepto_g = SRC.concepto_g, TRG.Documento = SRC.documento, TRG.Monto_min = SRC.monto_min,
					  				TRG.Descrip_l = SRC.descrip_l, TRG.Cod_dep_pl = SRC.cod_dep_pl, TRG.Oblig_mora = SRC.oblig_mora,
									TRG.I_ProcedenciaID = ' + CAST(@I_ProcedenciaID as varchar(3)) + '
					  WHEN NOT MATCHED BY TARGET THEN
					  	INSERT (Id_cp, Cuota_pago, Ano, P, Cod_rc, Cod_Ing, Tipo_oblig, Clasificad, Clasific_5, Id_cp_agrp, Agrupa, Nro_pagos, Id_cp_afec, Porcentaje, Monto, 
					  			Eliminado, Descripcio, Calcular, Grado, Tip_alumno, Grupo_rc, Fraccionab, Concepto_g, Documento, Monto_min, Descrip_l, Cod_dep_pl, Oblig_mora,
					  			D_FecCarga, I_ProcedenciaID)
					  	VALUES (id_cp, cuota_pago, ano, p, cod_rc, cod_ing, tipo_oblig, clasificad, clasific_5, id_cp_agrp, agrupa, nro_pagos, id_cp_afec, porcentaje, monto,
					  			Eliminado, Descripcio, Calcular, Grado, Tip_alumno, Grupo_rc, Fraccionab, Concepto_g, CAST(documento as varchar(max)), monto_min, CAST(descrip_l as varchar(max)), cod_dep_pl, oblig_mora,
					  			@D_FecProceso, ' + CAST(@I_ProcedenciaID as varchar(3)) + ')
					  WHEN NOT MATCHED BY SOURCE AND TRG.I_ProcedenciaID = '+ CAST(@I_ProcedenciaID as varchar(3)) + ' THEN
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
					  		deleted.COD_DEP_PL, deleted.OBLIG_MORA INTO #Tbl_output;
					'
		print @T_SQL
		Exec sp_executesql @T_SQL

		UPDATE	TR_Cp_Pri 
				SET	B_Actualizado = 0, B_Migrable = 1, D_FecMigrado = NULL, B_Migrado = 0,
					I_TipAluID = NULL, I_TipGradoID = NULL, I_TipOblID = NULL, I_TipCalcID = NULL, 
					I_TipPerID = NULL, I_DepID = NULL, I_TipGrpRc = NULL, I_CodIngID = NULL

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
