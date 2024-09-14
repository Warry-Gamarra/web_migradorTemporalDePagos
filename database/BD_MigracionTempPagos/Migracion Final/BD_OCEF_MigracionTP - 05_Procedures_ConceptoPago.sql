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


