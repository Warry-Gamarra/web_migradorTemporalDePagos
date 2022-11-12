USE BD_OCEF_MigracionTP
GO


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_IU_CopiarTablaCuotaDePago')
	DROP PROCEDURE [dbo].[USP_IU_CopiarTablaCuotaDePago]
GO

CREATE PROCEDURE USP_IU_CopiarTablaCuotaDePago
	@I_ProcedenciaID tinyint,
	@T_SchemaDB		 varchar(20),
	@T_Codigo_bnc	 varchar(250),
	@B_Resultado	 bit output,
	@T_Message		 nvarchar(4000) OUTPUT	
AS
--declare @B_Resultado  bit,
--		@I_ProcedenciaID	tinyint = 3,
--		@T_SchemaDB			varchar(20) = 'euded',
--		@T_Codigo_bnc		varchar(250) = '''0658'', ''0685'', ''0687'', ''0688''',
--		@T_Message			nvarchar(4000)
--exec USP_IU_CopiarTablaCuotaDePago @I_ProcedenciaID, @T_SchemaDB, @T_Codigo_bnc, @B_Resultado output, @T_Message output
--select @B_Resultado as resultado, @T_Message as mensaje
BEGIN
	DECLARE @T_SQL nvarchar(max)

	DECLARE @I_CpDes int = 0
	DECLARE @I_Removidos int = 0
	DECLARE @I_Actualizados int = 0
	DECLARE @I_Insertados int = 0
	DECLARE @D_FecProceso datetime = GETDATE()

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

	BEGIN TRY 
	
		SET @T_SQL = 'DECLARE @D_FecProceso datetime = GETDATE()			 
		 
					  MERGE TR_Cp_Des AS TRG
					  USING (SELECT * FROM BD_OCEF_TemporalPagos.' + @T_SchemaDB + '.cp_des WHERE codigo_bnc IN (' + @T_Codigo_bnc + ')) AS SRC
					  ON	TRG.Cuota_pago = SRC.cuota_pago 
				  		AND TRG.Eliminado = SRC.eliminado
						AND TRG.Codigo_bnc = SRC.codigo_bnc
					  WHEN MATCHED THEN
				  		UPDATE SET	TRG.Descripcio = SRC.descripcio,
				  					TRG.N_cta_cte = SRC.n_cta_cte,
				  					TRG.Codigo_bnc = SRC.codigo_bnc,
				  					TRG.Fch_venc = SRC.fch_venc,
				  					TRG.Prioridad = SRC.prioridad,
				  					TRG.C_mora = SRC.c_mora
					  WHEN NOT MATCHED BY TARGET THEN
				  		INSERT (Cuota_pago, Descripcio, N_cta_cte, Eliminado, Codigo_bnc, Fch_venc, Prioridad, C_mora, I_ProcedenciaID, D_FecCarga, B_Actualizado)
				  		VALUES (SRC.cuota_pago, SRC.descripcio, SRC.n_cta_cte, SRC.eliminado, SRC.codigo_bnc, SRC.fch_venc, SRC.prioridad, SRC.c_mora, ' + CAST(@I_ProcedenciaID as varchar(3)) + ', @D_FecProceso, 1)
					  WHEN NOT MATCHED BY SOURCE AND TRG.I_ProcedenciaID = '+ CAST(@I_ProcedenciaID as varchar(3)) + ' THEN
				  		UPDATE SET TRG.B_Removido = 1, 
				  				   TRG.D_FecRemovido = @D_FecProceso
					  OUTPUT	$ACTION, inserted.CUOTA_PAGO, inserted.ELIMINADO, inserted.DESCRIPCIO, inserted.N_CTA_CTE,  
				  			inserted.CODIGO_BNC, inserted.FCH_VENC, inserted.PRIORIDAD, inserted.C_MORA, deleted.DESCRIPCIO, 
				  			deleted.N_CTA_CTE, deleted.CODIGO_BNC, deleted.FCH_VENC, deleted.PRIORIDAD, deleted.C_MORA, 
				  			deleted.B_Removido INTO #Tbl_output;
					'

		print @T_SQL
		Exec sp_executesql @T_SQL

		UPDATE	TR_Cp_Des 
				SET	B_Actualizado = 0, B_Migrable = 0, 
					D_FecMigrado = NULL, B_Migrado = 0,
					I_Anio = NULL, I_CatPagoID = NULL, I_Periodo = NULL
		WHERE	I_ProcedenciaID = @I_ProcedenciaID

		UPDATE	t_CpDes
		SET		t_CpDes.B_Actualizado = 1,
				t_CpDes.D_FecActualiza = @D_FecProceso
		FROM TR_Cp_Des  AS t_CpDes
		INNER JOIN 	#Tbl_output as t_out ON t_out.CUOTA_PAGO = t_CpDes.Cuota_pago 
					AND t_out.ELIMINADO = t_CpDes.Eliminado AND t_out.accion = 'UPDATE' AND t_out.B_Removido = 0
		WHERE 
				t_out.INS_DESCRIPCIO <> t_out.DEL_DESCRIPCIO OR
				t_out.INS_N_CTA_CTE <> t_out.DEL_N_CTA_CTE OR
				t_out.INS_CODIGO_BNC <> t_out.DEL_CODIGO_BNC OR
				t_out.INS_FCH_VENC <> t_out.DEL_FCH_VENC OR
				t_out.INS_PRIORIDAD <> t_out.DEL_PRIORIDAD OR
				t_out.INS_C_MORA <> t_out.DEL_C_MORA
		
		SET @T_SQL = 'SELECT cuota_pago FROM BD_OCEF_TemporalPagos.' + @T_SchemaDB + '.cp_des'
		print @T_SQL
		Exec sp_executesql @T_SQL

		SET @I_CpDes = @@ROWCOUNT

		SET @I_Insertados = (SELECT COUNT(*) FROM #Tbl_output WHERE accion = 'INSERT')
		SET @I_Actualizados = (SELECT COUNT(*) FROM #Tbl_output WHERE accion = 'UPDATE' AND B_Removido = 0)
		SET @I_Removidos = (SELECT COUNT(*) FROM #Tbl_output WHERE accion = 'UPDATE' AND B_Removido = 1)

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


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_U_InicializarEstadoValidacionCuotaPago')
	DROP PROCEDURE [dbo].[USP_U_InicializarEstadoValidacionCuotaPago]
GO

CREATE PROCEDURE USP_U_InicializarEstadoValidacionCuotaPago	
	@I_ProcedenciaID tinyint,
	@B_Resultado  bit output,
	@T_Message	  nvarchar(4000) OUTPUT	
AS
--declare @B_Resultado  bit,
--		@I_ProcedenciaID	tinyint = 3,
--		@T_Message	  nvarchar(4000)
--exec USP_U_InicializarEstadoValidacionCuotaPago @I_ProcedenciaID, @B_Resultado output, @T_Message output
--select @B_Resultado as resultado, @T_Message as mensaje
BEGIN
	BEGIN TRANSACTION
	BEGIN TRY 
		UPDATE	TR_Cp_Des 
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


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_U_MarcarRepetidosCuotaDePago')
	DROP PROCEDURE [dbo].[USP_U_MarcarRepetidosCuotaDePago]
GO

CREATE PROCEDURE USP_U_MarcarRepetidosCuotaDePago
	@I_ProcedenciaID tinyint,
	@B_Resultado  bit output,
	@T_Message	  nvarchar(4000) OUTPUT	
AS
--declare @B_Resultado  bit,
--		@I_ProcedenciaID tinyint = 3,
--		@T_Message	  nvarchar(4000)
--exec USP_U_MarcarRepetidosCuotaDePago @I_ProcedenciaID, @B_Resultado output, @T_Message output
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
		WHERE	CUOTA_PAGO IN (SELECT CUOTA_PAGO FROM TR_Cp_Des WHERE I_ProcedenciaID = @I_ProcedenciaID AND ELIMINADO = 0 
							   GROUP BY CUOTA_PAGO HAVING COUNT(CUOTA_PAGO) > 1
								UNION
							   SELECT CUOTA_PAGO FROM TR_Cp_Des WHERE I_ProcedenciaID = @I_ProcedenciaID AND ELIMINADO = 1 
							   GROUP BY CUOTA_PAGO HAVING COUNT(CUOTA_PAGO) > 1)
				
		IF EXISTS (SELECT CUOTA_PAGO FROM TR_Cp_Des WHERE I_ProcedenciaID = @I_ProcedenciaID GROUP BY CUOTA_PAGO HAVING COUNT(CUOTA_PAGO) > 1)
		BEGIN
			UPDATE	TR_Cp_Des
			SET		B_Migrable = 0,
					D_FecEvalua = @D_FecProceso
			WHERE	CUOTA_PAGO IN (SELECT CUOTA_PAGO FROM TR_Cp_Des WHERE I_ProcedenciaID = @I_ProcedenciaID
								   GROUP BY CUOTA_PAGO HAVING COUNT(CUOTA_PAGO) > 1)
					AND Eliminado = 1
		END

		MERGE TI_ObservacionRegistroTabla AS TRG
		USING (SELECT @I_ObservID_activo AS I_ObservID, @I_TablaID AS I_TablaID, I_RowID AS I_FilaTablaID, @D_FecProceso AS D_FecRegistro 
				 FROM TR_Cp_Des 
				 WHERE CUOTA_PAGO IN (SELECT CUOTA_PAGO FROM TR_Cp_Des WHERE I_ProcedenciaID = @I_ProcedenciaID AND ELIMINADO = 0 
									  GROUP BY CUOTA_PAGO HAVING COUNT(CUOTA_PAGO) > 1)
			  ) AS SRC
		ON TRG.I_ObservID = SRC.I_ObservID AND TRG.I_TablaID = SRC.I_TablaID AND TRG.I_FilaTablaID = SRC.I_FilaTablaID
		WHEN MATCHED THEN
			UPDATE SET D_FecRegistro = SRC.D_FecRegistro
		WHEN NOT MATCHED BY TARGET THEN
			INSERT (I_ObservID, I_TablaID, I_FilaTablaID, D_FecRegistro, I_ProcedenciaID)
			VALUES (SRC.I_ObservID, SRC.I_TablaID, SRC.I_FilaTablaID, SRC.D_FecRegistro, @I_ProcedenciaID)
		WHEN NOT MATCHED BY SOURCE AND TRG.I_ObservID = @I_ObservID_activo AND TRG.I_ProcedenciaID = @I_ProcedenciaID THEN
			DELETE;


		MERGE TI_ObservacionRegistroTabla AS TRG
		USING (SELECT @I_ObservID_eliminado AS I_ObservID, @I_TablaID AS I_TablaID, I_RowID AS I_FilaTablaID, @D_FecProceso AS D_FecRegistro 
				 FROM TR_Cp_Des 
				 WHERE CUOTA_PAGO IN (SELECT CUOTA_PAGO FROM TR_Cp_Des WHERE I_ProcedenciaID = @I_ProcedenciaID AND ELIMINADO = 1 
									  GROUP BY CUOTA_PAGO HAVING COUNT(CUOTA_PAGO) > 1)
			  ) AS SRC
		ON TRG.I_ObservID = SRC.I_ObservID AND TRG.I_TablaID = SRC.I_TablaID AND TRG.I_FilaTablaID = SRC.I_FilaTablaID
		WHEN MATCHED THEN
			UPDATE SET D_FecRegistro = SRC.D_FecRegistro
		WHEN NOT MATCHED BY TARGET THEN
			INSERT (I_ObservID, I_TablaID, I_FilaTablaID, D_FecRegistro, I_ProcedenciaID)
			VALUES (SRC.I_ObservID, SRC.I_TablaID, SRC.I_FilaTablaID, SRC.D_FecRegistro, @I_ProcedenciaID)
		WHEN NOT MATCHED BY SOURCE AND TRG.I_ObservID = @I_ObservID_eliminado AND TRG.I_ProcedenciaID = @I_ProcedenciaID THEN
			DELETE;


		MERGE TI_ObservacionRegistroTabla AS TRG
		USING (SELECT @I_ObservID_eliminado AS I_ObservID, @I_TablaID AS I_TablaID, I_RowID AS I_FilaTablaID, @D_FecProceso AS D_FecRegistro 
				 FROM TR_Cp_Des 
				 WHERE CUOTA_PAGO IN (SELECT CUOTA_PAGO FROM TR_Cp_Des WHERE I_ProcedenciaID = @I_ProcedenciaID 
									  GROUP BY CUOTA_PAGO HAVING COUNT(CUOTA_PAGO) > 1)
					   AND Eliminado = 1
			  ) AS SRC
		ON TRG.I_ObservID = SRC.I_ObservID AND TRG.I_TablaID = SRC.I_TablaID AND TRG.I_FilaTablaID = SRC.I_FilaTablaID
		WHEN MATCHED THEN
			UPDATE SET D_FecRegistro = SRC.D_FecRegistro
		WHEN NOT MATCHED BY TARGET THEN
			INSERT (I_ObservID, I_TablaID, I_FilaTablaID, D_FecRegistro, I_ProcedenciaID)
			VALUES (SRC.I_ObservID, SRC.I_TablaID, SRC.I_FilaTablaID, SRC.D_FecRegistro, @I_ProcedenciaID)
		WHEN NOT MATCHED BY SOURCE AND TRG.I_ObservID = @I_ObservID_eliminado AND TRG.I_ProcedenciaID = @I_ProcedenciaID THEN
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
	@I_ProcedenciaID tinyint,
	@T_SchemaDB		 varchar(20),
	@B_Resultado  bit output,
	@T_Message	  nvarchar(4000) OUTPUT	
AS
--declare @B_Resultado  bit,
--		@I_ProcedenciaID tinyint = 3,
--		@T_SchemaDB		 varchar(20) = 'euded',
--		@T_Message	  nvarchar(4000)
--exec USP_U_AsignarAnioPeriodoCuotaPago @I_ProcedenciaID, @T_SchemaDB, @B_Resultado output, @T_Message output
--select @B_Resultado as resultado, @T_Message as mensaje
BEGIN
	DECLARE @D_FecProceso datetime = GETDATE() 
	DECLARE @T_SQL nvarchar(max)
	
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
		IF EXISTS (SELECT * FROM tempdb.INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = '##cuota_anio')
		BEGIN
			DROP TABLE ##cuota_anio
		END

		IF EXISTS (SELECT * FROM tempdb.INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = '##periodo')
		BEGIN
			DROP TABLE ##periodo
		END
	 
		--1. ASIGNAR AÑO CUOTA PAGO
		CREATE TABLE ##cuota_anio (cuota_pago int, anio_cuota varchar(4))
		CREATE TABLE ##periodo (cuota_pago int, I_Periodo int, C_CodPeriodo varchar(5), T_Descripcion varchar(50))

			--CUOTAS DE PAGO CON AÑO EN CP_PRI
		INSERT INTO ##cuota_anio(cuota_pago, anio_cuota)
			SELECT DISTINCT D.CUOTA_PAGO, ISNULL(P.ANO, SUBSTRING(RTRIM(LTRIM(D.DESCRIPCIO)), 1,4)) AS ANO 
			  FROM TR_Cp_Des D LEFT JOIN TR_cp_pri P ON D.CUOTA_PAGO = P.CUOTA_PAGO
			 WHERE ISNUMERIC(ISNULL(P.ANO, SUBSTRING(D.DESCRIPCIO, 1,4))) = 1
				   AND D.I_ProcedenciaID = @I_ProcedenciaID;


			--CUOTAS DE PAGO SIN AÑO EN CP_PRI PERO CON AÑO EN EC_OBL

		SET @T_SQL = 'INSERT INTO ##cuota_anio(cuota_pago, anio_cuota)
					  SELECT DISTINCT o.CUOTA_PAGO, o.ANO FROM BD_OCEF_TemporalPagos.' + @T_SchemaDB + '.ec_obl o 
							 INNER JOIN (SELECT cd.CUOTA_PAGO FROM TR_Cp_Des cd
											LEFT JOIN ##cuota_anio ca ON cd.CUOTA_PAGO = ca.cuota_pago 
											WHERE anio_cuota IS NULL
												  AND cd.I_ProcedenciaID = ' + CAST(@I_ProcedenciaID as varchar) + ') cdca
								ON cdca.CUOTA_PAGO = o.CUOTA_PAGO'
			 
		PRINT @T_SQL
		EXEC sp_executesql @T_SQL

		UPDATE	TR_Cp_Des
		SET		B_Migrable = 0,
				D_FecEvalua = @D_FecProceso
		WHERE	CUOTA_PAGO IN (SELECT cuota_pago FROM ##cuota_anio GROUP BY cuota_pago HAVING COUNT(*) > 1)
				AND B_Actualizado = 0
				
		UPDATE	TR_Cp_Des
		SET		B_Migrable = 0,
				D_FecEvalua = @D_FecProceso
		WHERE	CUOTA_PAGO IN (SELECT cd.CUOTA_PAGO FROM TR_Cp_Des cd
							  LEFT JOIN ##cuota_anio ca ON cd.CUOTA_PAGO = ca.cuota_pago
							  WHERE anio_cuota IS NULL
									AND cd.I_ProcedenciaID = @I_ProcedenciaID)
				AND B_Actualizado = 0
	

		MERGE TI_ObservacionRegistroTabla AS TRG
		USING 	(SELECT	@I_ObsMasUnAnio AS I_ObservID, @I_TablaID AS I_TablaID, I_RowID AS I_FilaTablaID, @D_FecProceso AS D_FecRegistro FROM TR_Cp_Des
				 WHERE CUOTA_PAGO IN (SELECT cuota_pago FROM ##cuota_anio GROUP BY cuota_pago HAVING COUNT(*) > 1)
					   AND B_Actualizado = 0) AS SRC
		ON TRG.I_ObservID = SRC.I_ObservID AND TRG.I_TablaID = SRC.I_TablaID AND TRG.I_FilaTablaID = SRC.I_FilaTablaID
		WHEN MATCHED THEN
			UPDATE SET D_FecRegistro = SRC.D_FecRegistro
		WHEN NOT MATCHED BY TARGET THEN
			INSERT (I_ObservID, I_TablaID, I_FilaTablaID, D_FecRegistro, I_ProcedenciaID)
			VALUES (SRC.I_ObservID, SRC.I_TablaID, SRC.I_FilaTablaID, SRC.D_FecRegistro, @I_ProcedenciaID)
		WHEN NOT MATCHED BY SOURCE AND TRG.I_ObservID = @I_ObsMasUnAnio AND TRG.I_ProcedenciaID = @I_ProcedenciaID THEN
			DELETE;


		MERGE TI_ObservacionRegistroTabla AS TRG
		USING 	(SELECT	@I_ObsSinAnio AS I_ObservID, @I_TablaID AS I_TablaID, I_RowID AS I_FilaTablaID, @D_FecProceso AS D_FecRegistro FROM TR_Cp_Des
				  WHERE	CUOTA_PAGO IN (SELECT cd.CUOTA_PAGO FROM TR_Cp_Des cd LEFT JOIN ##cuota_anio ca ON cd.CUOTA_PAGO = ca.cuota_pago WHERE anio_cuota IS NULL
										AND cd.I_ProcedenciaID = @I_ProcedenciaID)
					    AND B_Actualizado = 0) AS SRC
		ON TRG.I_ObservID = SRC.I_ObservID AND TRG.I_TablaID = SRC.I_TablaID AND TRG.I_FilaTablaID = SRC.I_FilaTablaID
		WHEN MATCHED THEN
			UPDATE SET D_FecRegistro = SRC.D_FecRegistro
		WHEN NOT MATCHED BY TARGET THEN
			INSERT (I_ObservID, I_TablaID, I_FilaTablaID, D_FecRegistro, I_ProcedenciaID)
			VALUES (SRC.I_ObservID, SRC.I_TablaID, SRC.I_FilaTablaID, SRC.D_FecRegistro, @I_ProcedenciaID)
		WHEN NOT MATCHED BY SOURCE AND TRG.I_ObservID = @I_ObsSinAnio AND TRG.I_ProcedenciaID = @I_ProcedenciaID THEN
			DELETE;


		UPDATE	tb_des  
		SET		I_Anio = a1.anio_cuota,
				D_FecEvalua = @D_FecProceso
		FROM	TR_Cp_Des tb_des
				INNER JOIN ##cuota_anio a1 ON tb_des.CUOTA_PAGO = a1.cuota_pago
				INNER JOIN (SELECT cuota_pago FROM ##cuota_anio GROUP BY cuota_pago HAVING COUNT(*) = 1) a2
				ON a1.cuota_pago= a2.cuota_pago

		--2. ASIGNAR PERIODO CUOTA PAGO
		SET @T_SQL = 'INSERT INTO ##periodo (cuota_pago, I_Periodo, C_CodPeriodo, T_Descripcion)
					  SELECT DISTINCT pri.CUOTA_PAGO, I_OpcionID, T_OpcionCod, T_OpcionDesc 
					  FROM	 BD_OCEF_CtasPorCobrar.dbo.TC_CatalogoOpcion per 
					  		 INNER JOIN BD_OCEF_TemporalPagos.' + @T_SchemaDB + '.cp_pri pri ON per.T_OpcionCod = pri.P
					  WHERE  I_ParametroID = 5'

		PRINT @T_SQL
		EXEC sp_executesql @T_SQL


		UPDATE	TR_Cp_Des
		SET		B_Migrable = 0,
				D_FecEvalua = @D_FecProceso
		WHERE	CUOTA_PAGO IN (SELECT cuota_pago FROM ##periodo GROUP BY cuota_pago HAVING COUNT(*) > 1)
				AND I_ProcedenciaID = @I_ProcedenciaID
				AND B_Actualizado = 0
	
		MERGE TI_ObservacionRegistroTabla AS TRG
		USING 	(SELECT	@I_ObsMasUnPeriodo AS I_ObservID, @I_TablaID AS I_TablaID, I_RowID AS I_FilaTablaID, @D_FecProceso AS D_FecRegistro FROM TR_Cp_Des
				 WHERE CUOTA_PAGO IN (SELECT cuota_pago FROM ##periodo GROUP BY cuota_pago HAVING COUNT(*) > 1) 
					   AND B_Actualizado = 0) AS SRC
		ON TRG.I_ObservID = SRC.I_ObservID AND TRG.I_TablaID = SRC.I_TablaID AND TRG.I_FilaTablaID = SRC.I_FilaTablaID
		WHEN MATCHED THEN
			UPDATE SET D_FecRegistro = SRC.D_FecRegistro
		WHEN NOT MATCHED BY TARGET THEN
			INSERT (I_ObservID, I_TablaID, I_FilaTablaID, D_FecRegistro, I_ProcedenciaID)
			VALUES (SRC.I_ObservID, SRC.I_TablaID, SRC.I_FilaTablaID, SRC.D_FecRegistro, @I_ProcedenciaID)
		WHEN NOT MATCHED BY SOURCE AND TRG.I_ObservID = @I_ObsMasUnPeriodo AND TRG.I_ProcedenciaID = @I_ProcedenciaID THEN
			DELETE;

		UPDATE	tb_des  
		SET		I_Periodo = per1.I_Periodo,
				D_FecEvalua = @D_FecProceso
		FROM	TR_Cp_Des tb_des
				INNER JOIN ##periodo per1 ON tb_des.CUOTA_PAGO = per1.cuota_pago
				INNER JOIN (SELECT cuota_pago FROM ##periodo GROUP BY cuota_pago HAVING COUNT(*) = 1) per2
				ON per1.CUOTA_PAGO = per2.cuota_pago

		UPDATE	TR_Cp_Des
		SET		B_Migrable = 0,
				D_FecEvalua = @D_FecProceso
		WHERE	I_Periodo IS NULL
				AND Cuota_pago NOT IN (SELECT cuota_pago FROM ##periodo GROUP BY cuota_pago HAVING COUNT(*) > 1)
				AND I_ProcedenciaID = @I_ProcedenciaID 
				AND B_Actualizado = 0

		MERGE TI_ObservacionRegistroTabla AS TRG
		USING 	(SELECT	@I_ObsSinPeriodo AS I_ObservID, @I_TablaID AS I_TablaID, I_RowID AS I_FilaTablaID, @D_FecProceso AS D_FecRegistro FROM TR_Cp_Des
				 WHERE I_Periodo IS NULL 
					   AND Cuota_pago NOT IN (SELECT cuota_pago FROM ##periodo GROUP BY cuota_pago HAVING COUNT(*) > 1)
					   AND I_ProcedenciaID = @I_ProcedenciaID					   
					   AND B_Actualizado = 0) AS SRC
		ON TRG.I_ObservID = SRC.I_ObservID AND TRG.I_TablaID = SRC.I_TablaID AND TRG.I_FilaTablaID = SRC.I_FilaTablaID
		WHEN MATCHED THEN
			UPDATE SET D_FecRegistro = SRC.D_FecRegistro
		WHEN NOT MATCHED BY TARGET THEN
			INSERT (I_ObservID, I_TablaID, I_FilaTablaID, D_FecRegistro, I_ProcedenciaID)
			VALUES (SRC.I_ObservID, SRC.I_TablaID, SRC.I_FilaTablaID, SRC.D_FecRegistro, @I_ProcedenciaID)
		WHEN NOT MATCHED BY SOURCE AND TRG.I_ObservID = @I_ObsSinPeriodo AND TRG.I_ProcedenciaID = @I_ProcedenciaID THEN
			DELETE;
	
		SET @I_cant_MasUnAnio = (SELECT COUNT(*) FROM TI_ObservacionRegistroTabla WHERE I_ObservID = @I_ObsMasUnAnio AND I_TablaID = @I_TablaID)
		SET @I_cant_SinAnio = (SELECT COUNT(*) FROM TI_ObservacionRegistroTabla WHERE I_ObservID = @I_ObsSinAnio AND I_TablaID = @I_TablaID)
		SET @I_cant_MasUnPeriodo = (SELECT COUNT(*) FROM TI_ObservacionRegistroTabla WHERE I_ObservID = @I_ObsMasUnPeriodo AND I_TablaID = @I_TablaID)
		SET @I_cant_SinPeriodo = (SELECT COUNT(*) FROM TI_ObservacionRegistroTabla WHERE I_ObservID = @I_ObsSinPeriodo AND I_TablaID = @I_TablaID)

		IF EXISTS (SELECT * FROM tempdb.INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = '##cuota_anio')
		BEGIN
			DROP TABLE ##cuota_anio
		END

		IF EXISTS (SELECT * FROM tempdb.INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = '##periodo')
		BEGIN
			DROP TABLE ##periodo
		END

		SET @B_Resultado = 1
		SET @T_Message = CAST(@I_cant_MasUnAnio AS varchar) + ' más de un año | ' + CAST(@I_cant_SinAnio AS varchar) + '  sin año| ' + 
						 CAST(@I_cant_MasUnPeriodo AS varchar) + ' más de un periodo| ' + CAST(@I_cant_SinPeriodo AS varchar) + ' Sin periodo.' 
	END TRY
	BEGIN CATCH
		IF EXISTS (SELECT * FROM tempdb.INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = '##cuota_anio')
		BEGIN
			DROP TABLE ##cuota_anio
		END

		IF EXISTS (SELECT * FROM tempdb.INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = '##periodo')
		BEGIN
			DROP TABLE ##periodo
		END


		SET @B_Resultado = 0
		SET @T_Message = ERROR_MESSAGE() + ' LINE: ' + CAST(ERROR_LINE() AS varchar(10)) 
	END CATCH
END
GO


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_U_AsignarCategoriaCuotaPago')
	DROP PROCEDURE [dbo].[USP_U_AsignarCategoriaCuotaPago]
GO

CREATE PROCEDURE USP_U_AsignarCategoriaCuotaPago
	@I_ProcedenciaID tinyint,
	@B_Resultado  bit output,
	@T_Message	  nvarchar(4000) OUTPUT	
AS
--declare @B_Resultado  bit,
--		@I_ProcedenciaID tinyint = 3,
--		@T_Message	  nvarchar(4000)
--exec USP_U_AsignarCategoriaCuotaPago @I_ProcedenciaID, @B_Resultado output, @T_Message output
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
			WHERE Eliminado = 0 AND I_ProcedenciaID = @I_ProcedenciaID

		UPDATE	tb_des  
		SET		I_CatPagoID = cat1.I_CatPagoID,
				D_FecEvalua = @D_FecProceso
		FROM	TR_Cp_Des tb_des
				INNER JOIN @categoria_pago cat1 ON tb_des.CUOTA_PAGO = cat1.cuota_pago
				INNER JOIN (SELECT cuota_pago FROM @categoria_pago GROUP BY cuota_pago HAVING COUNT(*) = 1) cat2
				ON cat1.CUOTA_PAGO = cat2.cuota_pago
		WHERE	tb_des.I_CatPagoID IS NULL
				AND tb_des.I_ProcedenciaID = @I_ProcedenciaID

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
			
		UPDATE	TR_Cp_Des
		SET		B_Migrable = 0,
				D_FecEvalua = @D_FecProceso
		WHERE	I_CatPagoID IS NULL
				AND I_ProcedenciaID = @I_ProcedenciaID

		MERGE TI_ObservacionRegistroTabla AS TRG
		USING 	(SELECT	@I_ObsSinCategoria AS I_ObservID, @I_TablaID AS I_TablaID, I_RowID AS I_FilaTablaID, @D_FecProceso AS D_FecRegistro FROM TR_Cp_Des
				  WHERE	I_CatPagoID IS NULL AND I_ProcedenciaID = @I_ProcedenciaID) AS SRC
		ON TRG.I_ObservID = SRC.I_ObservID AND TRG.I_TablaID = SRC.I_TablaID AND TRG.I_FilaTablaID = SRC.I_FilaTablaID
		WHEN MATCHED THEN
			UPDATE SET D_FecRegistro = SRC.D_FecRegistro
		WHEN NOT MATCHED BY TARGET THEN
			INSERT (I_ObservID, I_TablaID, I_FilaTablaID, D_FecRegistro, I_ProcedenciaID)
			VALUES (SRC.I_ObservID, SRC.I_TablaID, SRC.I_FilaTablaID, SRC.D_FecRegistro, @I_ProcedenciaID)
		WHEN NOT MATCHED BY SOURCE AND TRG.I_ObservID = @I_ObsSinCategoria AND TRG.I_ProcedenciaID = @I_ProcedenciaID THEN
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
	@I_ProcedenciaID tinyint,
	@B_Resultado  bit output,
	@T_Message	  nvarchar(4000) OUTPUT	
AS
--declare	@B_Resultado  bit, 
--			@I_ProcesoID int = NULL,
--			@I_AnioIni int = NULL, 
--			@I_AnioFin int = NULL,
--			@I_ProcedenciaID tinyint = 3,
--			@T_Message nvarchar(4000)
--exec USP_IU_MigrarDataCuotaDePagoCtasPorCobrar @I_ProcesoID, @I_AnioIni, @I_AnioFin, @I_ProcedenciaID, @B_Resultado output, @T_Message output
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
				WHERE B_Migrable = 1 
					  AND (I_Anio BETWEEN @I_AnioIni AND @I_AnioFin)
					  AND (CUOTA_PAGO = @I_ProcesoID OR @I_ProcesoID IS NULL)
					  AND I_ProcedenciaID = @I_ProcedenciaID
			  ) AS SRC
		ON TRG.I_ProcesoID = SRC.CUOTA_PAGO 
		WHEN NOT MATCHED BY TARGET THEN 
			 INSERT (I_ProcesoID, I_CatPagoID, T_ProcesoDesc, I_Anio, I_Periodo, N_CodBanco, D_FecVencto, I_Prioridad, B_Mora, 
					 B_Migrado, D_FecCre, B_Habilitado, B_Eliminado, I_MigracionTablaID, I_MigracionRowID)
			 VALUES (CUOTA_PAGO, I_CatPagoID, DESCRIPCIO
			 , I_Anio, I_Periodo, CODIGO_BNC, FCH_VENC, PRIORIDAD, C_MORA, 
					 1, @D_FecProceso, 1, ELIMINADO, @I_TablaID, I_RowID)
					
		WHEN MATCHED AND TRG.B_Migrado = 1 AND TRG.I_UsuarioMod IS NULL THEN 
			 UPDATE SET I_CatPagoID = SRC.I_CatPagoID, 
					 T_ProcesoDesc = SRC.DESCRIPCIO,
					 I_Anio = SRC.I_Anio, 
					 I_Periodo = SRC.I_Periodo,
					 N_CodBanco = SRC.CODIGO_BNC, 
					 D_FecVencto = SRC.FCH_VENC, 
					 I_Prioridad = SRC.PRIORIDAD, 
					 D_FecMod = @D_FecProceso,
					 B_Mora = SRC.C_MORA,
					 I_MigracionTablaID = @I_TablaID,
					 I_MigracionRowID = I_RowID
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
					WHERE B_Migrable = 1 
						AND (I_Anio BETWEEN @I_AnioIni AND @I_AnioFin) 
						AND (CUOTA_PAGO = @I_ProcesoID OR @I_ProcesoID IS NULL)
						AND I_ProcedenciaID = @I_ProcedenciaID
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
				WHERE B_Migrable = 1 
					  AND I_ProcedenciaID = @I_ProcedenciaID					  
					  AND (I_Anio BETWEEN @I_AnioIni AND @I_AnioFin)) AS SRC
		ON TRG.I_CatPagoID = SRC.I_CatPagoID AND TRG.I_CtaDepositoID = SRC.I_CtaDepositoID
		WHEN NOT MATCHED BY TARGET THEN
			INSERT (I_CtaDepositoID, I_CatPagoID, B_Habilitado, B_Eliminado, D_FecCre)
			VALUES (I_CtaDepositoID, I_CatPagoID, 1, 0, @D_FecProceso)
		WHEN MATCHED AND TRG.I_UsuarioCre IS NULL AND TRG.I_UsuarioMod IS NULL THEN
			UPDATE SET	D_FecMod = @D_FecProceso
		OUTPUT $action, SRC.I_CatPagoID INTO @Tbl_outputCtasCat;
		

		SELECT * FROM @Tbl_outputProceso

		UPDATE	TR_Cp_Des 
		SET		B_Migrado = 1, 
				D_FecMigrado = @D_FecProceso
		WHERE	I_RowID IN (SELECT I_RowID FROM @Tbl_outputProceso)
				AND I_ProcedenciaID = @I_ProcedenciaID

		UPDATE	TR_Cp_Des 
		SET		B_Migrado = 0 
		WHERE	I_RowID IN (SELECT CD.I_RowID FROM TR_Cp_Des CD LEFT JOIN @Tbl_outputProceso O ON CD.I_RowID = o.I_RowID 
							WHERE CD.B_Migrable = 1 AND O.I_RowID IS NULL)
				AND I_ProcedenciaID = @I_ProcedenciaID

		MERGE TI_ObservacionRegistroTabla AS TRG
		USING 	(SELECT	@I_ObservID AS I_ObservID, @I_TablaID AS I_TablaID, I_RowID AS I_FilaTablaID, @D_FecProceso AS D_FecRegistro FROM TR_Cp_Des
				  WHERE	I_RowID IN (SELECT CD.I_RowID FROM TR_Cp_Des CD LEFT JOIN @Tbl_outputProceso O ON CD.I_RowID = o.I_RowID 
									WHERE CD.B_Migrable = 1 AND O.I_RowID IS NULL)
						AND I_ProcedenciaID = @I_ProcedenciaID
				) AS SRC
		ON TRG.I_ObservID = SRC.I_ObservID AND TRG.I_TablaID = SRC.I_TablaID AND TRG.I_FilaTablaID = SRC.I_FilaTablaID
		WHEN MATCHED THEN
			UPDATE SET D_FecRegistro = SRC.D_FecRegistro
		WHEN NOT MATCHED BY TARGET THEN
			INSERT (I_ObservID, I_TablaID, I_FilaTablaID, D_FecRegistro)
			VALUES (SRC.I_ObservID, SRC.I_TablaID, SRC.I_FilaTablaID, SRC.D_FecRegistro)
		WHEN NOT MATCHED BY SOURCE AND TRG.I_ObservID = @I_ObservID AND TRG.I_ProcedenciaID = @I_ProcedenciaID THEN
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

