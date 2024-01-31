USE BD_OCEF_MigracionTP
GO

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_MigracionTP_Tasas_IU_ConceptoPago_CopiarTablaTemporalPagos')
BEGIN
	DROP PROCEDURE dbo.USP_MigracionTP_Tasas_IU_ConceptoPago_CopiarTablaTemporalPagos
END
GO

CREATE PROCEDURE dbo.USP_MigracionTP_Tasas_IU_ConceptoPago_CopiarTablaTemporalPagos
(
	@I_ProcedenciaID tinyint,
	@T_Codigo_bnc	 varchar(250),
	@B_Resultado	 bit output,
	@T_Message		 nvarchar(4000) OUTPUT
)
AS
--declare @B_Resultado  bit,
--		@I_ProcedenciaID	tinyint = 4,
--		@T_Codigo_bnc		nvarchar(250) = N'',
--		@T_Message			nvarchar(4000)
--exec USP_MigracionTP_Tasas_IU_ConceptoPago_CopiarTablaTemporalPagos @I_ProcedenciaID, @T_Codigo_bnc, @B_Resultado output, @T_Message output
--select @B_Resultado as resultado, @T_Message as mensaje
BEGIN
	DECLARE @D_FecProceso datetime = GETDATE()
	DECLARE @I_CpPri int = 0
	DECLARE @I_Removidos int = 0
	DECLARE @I_Actualizados int = 0
	DECLARE @I_Insertados int = 0

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

	BEGIN TRANSACTION
	BEGIN TRY
		
		MERGE TR_Cp_Pri AS TRG
		USING (SELECT cp_pri.* FROM BD_OCEF_TemporalTasas.dbo.cp_pri cp_pri 
						INNER JOIN BD_OCEF_TemporalTasas.dbo.cp_des cp_des ON cp_pri.cuota_pago = cp_des.cuota_pago 
				  WHERE cp_des.codigo_bnc = '' AND cp_des.Eliminado = 0) AS SRC
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
						TRG.I_ProcedenciaID = @I_ProcedenciaID
		WHEN NOT MATCHED BY TARGET THEN
			INSERT (Id_cp, Cuota_pago, Ano, P, Cod_rc, Cod_Ing, Tipo_oblig, Clasificad, Clasific_5, Id_cp_agrp, Agrupa, Nro_pagos, Id_cp_afec, Porcentaje, Monto, 
					Eliminado, Descripcio, Calcular, Grado, Tip_alumno, Grupo_rc, Fraccionab, Concepto_g, Documento, Monto_min, Descrip_l, Cod_dep_pl, Oblig_mora,
					D_FecCarga, I_ProcedenciaID)
			VALUES (id_cp, cuota_pago, ano, p, cod_rc, cod_ing, tipo_oblig, clasificad, clasific_5, id_cp_agrp, agrupa, nro_pagos, id_cp_afec, porcentaje, monto,
					Eliminado, Descripcio, Calcular, Grado, Tip_alumno, Grupo_rc, Fraccionab, Concepto_g, CAST(documento as varchar(max)), monto_min, CAST(descrip_l as varchar(max)), cod_dep_pl, oblig_mora,
					@D_FecProceso, @I_ProcedenciaID)
		WHEN NOT MATCHED BY SOURCE AND TRG.I_ProcedenciaID = @I_ProcedenciaID THEN
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

		UPDATE	TR_Cp_Pri 
				SET	B_Actualizado = 0, B_Migrable = 0, D_FecMigrado = NULL, B_Migrado = 0,
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
		
		SET @I_CpPri = (SELECT COUNT(cp_pri.descripcio) FROM BD_OCEF_TemporalTasas.dbo.cp_pri cp_pri 
								INNER JOIN BD_OCEF_TemporalTasas.dbo.cp_des cp_des ON cp_pri.cuota_pago = cp_des.cuota_pago 
						  WHERE cp_des.codigo_bnc = '' AND cp_des.Eliminado = 0)

		SET @I_Insertados = (SELECT COUNT(*) FROM #Tbl_output WHERE accion = 'INSERT')
		SET @I_Actualizados = (SELECT COUNT(*) FROM #Tbl_output WHERE accion = 'UPDATE' AND B_Removido = 0)
		SET @I_Removidos = (SELECT COUNT(*) FROM #Tbl_output WHERE accion = 'UPDATE' AND B_Removido = 1)

		SELECT @I_CpPri AS tot_concetoPago, @I_Insertados AS cant_inserted, @I_Actualizados as cant_updated, @I_Removidos as cant_removed, @D_FecProceso as fec_proceso
		
		SET @B_Resultado = 1
		SET @T_Message =  'Total: ' + CAST(@I_CpPri AS varchar) + '|Insertados: ' + CAST(@I_Insertados AS varchar) 
						+ '|Actualizados: ' + CAST(@I_Actualizados AS varchar) + '|Removidos: ' + CAST(@I_Removidos AS varchar)

		COMMIT TRANSACTION
	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION
		SET @B_Resultado = 0
		SET @T_Message = ERROR_MESSAGE() + ' LINE: ' + CAST(ERROR_LINE() AS varchar(10)) 
	END CATCH
	
END
GO


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_MigracionTP_Tasas_U_ConceptoPago_InicializarEstadosValidacion')
	DROP PROCEDURE [dbo].[USP_MigracionTP_Tasas_U_ConceptoPago_InicializarEstadosValidacion]
GO

CREATE PROCEDURE dbo.USP_MigracionTP_Tasas_U_ConceptoPago_InicializarEstadosValidacion	
	@I_RowID	  int = NULL,
	@I_ProcedenciaID tinyint,
	@B_Resultado  bit output,
	@T_Message	  nvarchar(4000) OUTPUT	
AS
--declare @B_Resultado  bit,
--		@I_RowID	  int = NULL,
--		@I_ProcedenciaID	tinyint = 3,
--		@T_Message	  nvarchar(4000)
--exec USP_MigracionTP_Tasas_U_ConceptoPago_InicializarEstadosValidacion @I_RowID, @I_ProcedenciaID, @B_Resultado output, @T_Message output
--select @B_Resultado as resultado, @T_Message as mensaje
BEGIN
	BEGIN TRANSACTION
	BEGIN TRY 
		UPDATE	TR_Cp_Pri 
		   SET	B_Actualizado = IIF(B_Actualizado = 1, B_Actualizado, 0), 
				B_Migrable = 1, 
				D_FecMigrado = NULL
		 WHERE	I_ProcedenciaID = @I_ProcedenciaID 
				AND (I_RowID = IIF(@I_RowID IS NULL, I_RowID, @I_RowID))

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


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_MigracionTP_Tasas_U_ConceptoPago_ValidarTipoObligacion')
	DROP PROCEDURE [dbo].[USP_MigracionTP_Tasas_U_ConceptoPago_ValidarTipoObligacion]
GO

CREATE PROCEDURE dbo.USP_MigracionTP_Tasas_U_ConceptoPago_ValidarTipoObligacion
(
	@I_RowID	  int = NULL,
	@I_ProcedenciaID tinyint,
	@B_Resultado  bit output,
	@T_Message	  nvarchar(4000) OUTPUT	
)
AS
--declare @B_Resultado  bit,
--		@I_RowID	  int = NULL,
--		@I_ProcedenciaID tinyint = 4,
--		@T_Message	  nvarchar(4000)
--exec USP_MigracionTP_Tasas_U_ConceptoPago_ValidarTipoObligacion @I_RowID, @I_ProcedenciaID, @B_Resultado output, @T_Message output
--select @B_Resultado as resultado, @T_Message as mensaje

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
				AND (I_RowID = IIF(@I_RowID IS NULL, I_RowID, @I_RowID))
		
		MERGE TI_ObservacionRegistroTabla AS TRG
		USING (SELECT @I_ObservID AS I_ObservID, @I_TablaID AS I_TablaID, I_RowID AS I_FilaTablaID, @D_FecProceso AS D_FecRegistro 
				 FROM TR_Cp_Pri 
				WHERE Tipo_oblig = 1
					  AND Eliminado = 0
					  AND I_ProcedenciaID = @I_ProcedenciaID
			  ) AS SRC
		ON TRG.I_ObservID = SRC.I_ObservID AND TRG.I_TablaID = SRC.I_TablaID AND TRG.I_FilaTablaID = SRC.I_FilaTablaID
		WHEN MATCHED AND TRG.I_FilaTablaID = IIF(@I_RowID IS NULL, TRG.I_FilaTablaID, @I_RowID) THEN
			UPDATE SET D_FecRegistro = SRC.D_FecRegistro, 
					   B_Resuelto = 0
		WHEN NOT MATCHED BY TARGET AND SRC.I_FilaTablaID = IIF(@I_RowID IS NULL, SRC.I_FilaTablaID, @I_RowID) THEN
			INSERT (I_ObservID, I_TablaID, I_FilaTablaID, D_FecRegistro, I_ProcedenciaID)
			VALUES (SRC.I_ObservID, SRC.I_TablaID, SRC.I_FilaTablaID, SRC.D_FecRegistro, @I_ProcedenciaID)
		WHEN NOT MATCHED BY SOURCE AND TRG.I_ObservID = @I_ObservID AND TRG.I_ProcedenciaID = @I_ProcedenciaID  
								   AND TRG.I_FilaTablaID = IIF(@I_RowID IS NULL, TRG.I_FilaTablaID, @I_RowID)
								   AND TRG.I_TablaID = @I_TablaID THEN
			UPDATE SET D_FecResuelto = GETDATE(),
					   B_Resuelto = 1;		


		SET @I_Observados = (SELECT COUNT(*) FROM TI_ObservacionRegistroTabla 
											WHERE I_ObservID = @I_ObservID AND I_TablaID = @I_TablaID 
												  AND I_ProcedenciaID = @I_ProcedenciaID
												  AND I_FilaTablaID = IIF(@I_RowID IS NULL, I_FilaTablaID, @I_RowID) 
												  AND B_Resuelto = 0
							)

		SET @B_Resultado = 1
		SET @T_Message = CAST(@I_Observados AS varchar) + ' con estado tipo_obligacion verdadero' 


		COMMIT TRANSACTION
	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION
		SET @B_Resultado = 0
		SET @T_Message = ERROR_MESSAGE() + ' LINE: ' + CAST(ERROR_LINE() AS varchar(10)) 
	END CATCH

END
GO








IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_MigracionTP_Tasas_IU_ConceptoPago_MigrarDataTemporalPagos')
BEGIN
	DROP PROCEDURE dbo.USP_MigracionTP_Tasas_IU_ConceptoPago_MigrarDataTemporalPagos
END
GO

CREATE PROCEDURE dbo.USP_MigracionTP_Tasas_IU_ConceptoPago_MigrarDataTemporalPagos
(
	@I_RowID	  int = NULL,
	@I_ProcedenciaID tinyint,
	@B_Resultado  bit output,
	@T_Message	  nvarchar(4000) OUTPUT	
)
AS
BEGIN
	BEGIN TRANSACTION
	BEGIN TRY
		
		

		COMMIT TRANSACTION
	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION
		SET @B_Resultado = 0
		SET @T_Message = ERROR_MESSAGE() + ' LINE: ' + CAST(ERROR_LINE() AS varchar(10)) 
	END CATCH

END
GO


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_MigracionTP_Tasas_IU_ConceptoPago_MigrarDataTemporalPagosPorRowID')
BEGIN
	DROP PROCEDURE dbo.USP_MigracionTP_Tasas_IU_ConceptoPago_MigrarDataTemporalPagosPorRowID
END
GO

CREATE PROCEDURE dbo.USP_MigracionTP_Tasas_IU_ConceptoPago_MigrarDataTemporalPagosPorRowID
(
	@I_RowID	  int = NULL,
	@I_ProcedenciaID tinyint,
	@B_Resultado  bit output,
	@T_Message	  nvarchar(4000) OUTPUT	
)
AS
BEGIN
	BEGIN TRANSACTION
	BEGIN TRY
		



		COMMIT TRANSACTION
	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION
		SET @B_Resultado = 0
		SET @T_Message = ERROR_MESSAGE() + ' LINE: ' + CAST(ERROR_LINE() AS varchar(10)) 
	END CATCH

END
GO
