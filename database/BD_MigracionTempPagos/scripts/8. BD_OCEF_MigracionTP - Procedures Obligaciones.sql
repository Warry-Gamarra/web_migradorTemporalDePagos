USE BD_OCEF_MigracionTP
GO

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_IU_CopiarTablaObligacionesPago')
	DROP PROCEDURE [dbo].[USP_IU_CopiarTablaObligacionesPago]
GO

CREATE PROCEDURE USP_IU_CopiarTablaObligacionesPago	
	@I_ProcedenciaID tinyint,
	@T_SchemaDB	  varchar(20),
	@T_AnioIni	  varchar(4) = NULL,
	@T_AnioFin	  varchar(4) = NULL,
	@B_Resultado  bit output,
	@T_Message	  nvarchar(4000) OUTPUT	
AS
--declare @I_ProcedenciaID	tinyint = 2,
--		@T_SchemaDB   varchar(20) = 'eupg',
--		@T_AnioIni	  varchar(4) = null,
--		@T_AnioFin	  varchar(4) = null,
--		@B_Resultado  bit,
--		@T_Message	  nvarchar(4000)
--exec USP_IU_CopiarTablaObligacionesPago @I_ProcedenciaID, @T_SchemaDB, @T_AnioIni, @T_AnioFin, @B_Resultado output, @T_Message output
--select @B_Resultado as resultado, @T_Message as mensaje
BEGIN
	DECLARE @I_EcObl int = 0
	DECLARE @I_Removidos int = 0
	DECLARE @I_Actualizados int = 0
	DECLARE @I_Insertados int = 0
	DECLARE @D_FecProceso datetime = GETDATE() 
	DECLARE @T_SQL nvarchar(max)

	BEGIN TRANSACTION
	BEGIN TRY 

		UPDATE	TR_Ec_Obl
		SET		B_Actualizado = 0, 
				B_Migrable	  = 1, 
				D_FecMigrado  = NULL, 
				B_Migrado	  = 0 
		WHERE   (Ano BETWEEN @T_AnioIni AND @T_AnioFin)
				OR @T_AnioIni is null

		SET @T_SQL = '  DECLARE @D_FecProceso datetime = GETDATE()
					 
						UPDATE	TR_Ec_Obl
						SET		TR_Ec_Obl.B_Removido	= 1, 
								TR_Ec_Obl.D_FecRemovido	= @D_FecProceso,
								TR_Ec_Obl.B_Migrable	= 0
						WHERE	NOT EXISTS (SELECT * FROM BD_OCEF_TemporalPagos.' + @T_SchemaDB + '.ec_obl SRC  
											WHERE TR_Ec_Obl.ANO = SRC.ANO AND TR_Ec_Obl.P = SRC.P AND TR_Ec_Obl.COD_ALU = SRC.COD_ALU 
											AND TR_Ec_Obl.COD_RC = SRC.COD_RC AND TR_Ec_Obl.CUOTA_PAGO = SRC.CUOTA_PAGO 
											AND ISNULL(TR_Ec_Obl.FCH_VENC, ''19000101'') = ISNULL(SRC.FCH_VENC, ''19000101'')
											AND ISNULL(TR_Ec_Obl.TIPO_OBLIG, 0) = ISNULL(SRC.TIPO_OBLIG, 0)
											AND TR_Ec_Obl.MONTO = SRC.MONTO AND TR_Ec_Obl.PAGADO = SRC.PAGADO) '
						
		IF (@T_AnioIni IS NOT NULL AND @T_AnioFin IS NOT NULL)
		BEGIN
			SET @T_SQL = @T_SQL + 'AND (TR_Ec_Obl.ANO BETWEEN ''' + @T_AnioIni + ''' AND ''' + @T_AnioFin + ''') '
		END

		SET @T_SQL = @T_SQL + 'AND TR_Ec_Obl.B_Migrado = 0 
							   AND TR_Ec_Obl.I_ProcedenciaID = '+ CAST(@I_ProcedenciaID as varchar(3)) + ';'

		PRINT @T_SQL
		EXEC sp_executesql @T_SQL

		SET @I_Removidos = @@ROWCOUNT

		
		SET @T_SQL = '	DECLARE @D_FecProceso datetime = GETDATE()
			
						UPDATE	TR_Ec_Obl
						SET		TR_Ec_Obl.I_ProcedenciaID = '+ CAST(@I_ProcedenciaID as varchar(3)) + ', 
								TR_Ec_Obl.B_Obligacion = 1,
								TR_Ec_Obl.D_FecActualiza = @D_FecProceso,
								TR_Ec_Obl.B_Actualizado = 1,
								TR_Ec_Obl.B_Migrable = 0,
								TR_Ec_Obl.D_FecEvalua = NULL,
								TR_Ec_Obl.B_Removido = 0,
								TR_Ec_Obl.D_FecRemovido = NULL
						WHERE	EXISTS (SELECT * FROM BD_OCEF_TemporalPagos.' + @T_SchemaDB + '.ec_obl SRC  
										WHERE TR_Ec_Obl.Ano = SRC.ano AND TR_Ec_Obl.P = SRC.p AND TR_Ec_Obl.Cod_alu = SRC.cod_alu 
										AND TR_Ec_Obl.Cod_rc = SRC.cod_rc AND TR_Ec_Obl.Cuota_pago = SRC.cuota_pago 
										AND ISNULL(TR_Ec_Obl.Fch_venc, ''19000101'') = ISNULL(SRC.fch_venc, ''19000101'')
										AND ISNULL(TR_Ec_Obl.Tipo_oblig, 0) = ISNULL(SRC.tipo_oblig, 0)
										AND TR_Ec_Obl.Monto = SRC.monto AND TR_Ec_Obl.Pagado = SRC.pagado) '

		IF (@T_AnioIni IS NOT NULL AND @T_AnioFin IS NOT NULL)
		BEGIN
			SET @T_SQL = @T_SQL + 'AND (TR_Ec_Obl.ANO BETWEEN ''' + @T_AnioIni + ''' AND ''' + @T_AnioFin + ''') ' 
		END

		SET @T_SQL = @T_SQL + 'AND TR_Ec_Obl.B_Migrado = 0;' 

		PRINT @T_SQL
		EXEC sp_executesql @T_SQL

		SET @I_Actualizados = @@ROWCOUNT


		SET @T_SQL = '	DECLARE @D_FecProceso datetime = GETDATE()
			
						INSERT TR_Ec_Obl(Ano, P, I_Periodo, Cod_alu, Cod_rc, Cuota_pago, Tipo_oblig, Fch_venc, Monto, Pagado, D_FecCarga, B_Migrable, B_Migrado, I_ProcedenciaID, B_Obligacion)
						SELECT	ano, p, I_OpcionID as I_periodo, cod_alu, cod_rc, cuota_pago, tipo_oblig, fch_venc, monto, pagado, @D_FecProceso, 1, 0, '+ CAST(@I_ProcedenciaID as varchar(3)) + ', 1
						FROM	BD_OCEF_TemporalPagos.' + @T_SchemaDB + '.ec_obl OBL
								LEFT JOIN BD_OCEF_CtasPorCobrar.dbo.TC_CatalogoOpcion cop_per ON OBL.P = cop_per.T_OpcionCod AND cop_per.I_ParametroID = 5
						WHERE	NOT EXISTS (SELECT * FROM TR_Ec_Obl TRG 
											WHERE TRG.Ano = OBL.ano AND TRG.P = OBL.p AND TRG.Cod_alu = OBL.COD_ALU AND TRG.Cod_rc = OBL.COD_RC 
											AND TRG.Cuota_pago = OBL.cuota_pago AND ISNULL(TRG.Fch_venc, ''19000101'') = ISNULL(OBL.fch_venc, ''19000101'')
											AND ISNULL(TRG.Tipo_oblig, 0) = ISNULL(OBL.tipo_oblig, 0) AND TRG.Monto = OBL.monto AND TRG.Pagado = OBL.pagado
											AND TRG.I_ProcedenciaID = '+ CAST(@I_ProcedenciaID as varchar(3)) + ') '

		IF (@T_AnioIni IS NOT NULL AND @T_AnioFin IS NOT NULL)
		BEGIN
			SET @T_SQL = @T_SQL + 'AND (OBL.ANO BETWEEN ''' + @T_AnioIni + ''' AND ''' + @T_AnioFin + ''');' 
		END

		PRINT @T_SQL
		EXEC sp_executesql @T_SQL

		SET @I_Insertados = @@ROWCOUNT

		
		SET @T_SQL = '(SELECT * FROM BD_OCEF_TemporalPagos.' + @T_SchemaDB + '.ec_obl'

		IF (@T_AnioIni IS NOT NULL AND @T_AnioFin IS NOT NULL)
		BEGIN
			SET @T_SQL = @T_SQL + ' WHERE ANO BETWEEN ''' + @T_AnioIni + ''' AND ''' + @T_AnioFin + ''''
		END
		
		SET @T_SQL = @T_SQL + ')'

		PRINT @T_SQL
		EXEC sp_executesql @T_SQL

		SET @I_EcObl = @@ROWCOUNT

		SELECT @I_EcObl AS tot_obligaciones, @I_Insertados AS cant_inserted, @I_Actualizados AS cant_updated, @I_Removidos as cant_removed, @D_FecProceso as fec_proceso
		

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
	@I_ProcedenciaID tinyint,
	@T_SchemaDB	  varchar(20),
	@T_AnioIni	  varchar(4) = NULL,
	@T_AnioFin	  varchar(4) = NULL,
	@B_Resultado  bit output,
	@T_Message	  nvarchar(4000) OUTPUT	
AS
--declare @I_ProcedenciaID	tinyint = 2,
--		@T_SchemaDB   varchar(20) = 'eupg',
--		@T_AnioIni	  varchar(4) = '2019',
--		@T_AnioFin	  varchar(4) = '2021',
--		@B_Resultado  bit,
--		@T_Message	  nvarchar(4000)
--exec USP_IU_CopiarTablaDetalleObligacionesPago @I_ProcedenciaID, @T_SchemaDB, @T_AnioIni, @T_AnioFin, @B_Resultado output, @T_Message output
--select @B_Resultado as resultado, @T_Message as mensaje
BEGIN
	DECLARE @I_EcDet int = 0
	DECLARE @I_Removidos int = 0
	DECLARE @I_Actualizados int = 0
	DECLARE @I_Insertados int = 0
	DECLARE @D_FecProceso datetime = GETDATE() 
	DECLARE @T_SQL nvarchar(max)

	CREATE TABLE #Tbl_output
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
				
		DECLARE @T_Source varchar(2000)
		SET @T_Source = 'SELECT obl.I_RowID AS I_OblRowID , det.* 
						 FROM BD_OCEF_TemporalPagos.' + @T_SchemaDB + '.ec_det det
							  LEFT JOIN (SELECT I_RowID, obl2.* FROM TR_Ec_Obl obl1 
										 INNER JOIN (SELECT Ano, P, Cod_alu, Cod_rc, Cuota_pago, Fch_venc, pagado, I_ProcedenciaID
													 FROM TR_Ec_Obl WHERE  I_ProcedenciaID = ' + CAST(@I_ProcedenciaID as varchar(3)) + ' 
													 GROUP BY  I_ProcedenciaID, Ano, P, Cod_alu, Cod_rc, Cuota_pago, Fch_venc, Pagado
													 HAVING count(*) = 1
													) obl2 ON obl1.Ano = obl2.Ano AND obl1.P = obl2.P AND obl1.Cod_alu = obl2.Cod_alu
													 		  AND obl1.Cod_rc = obl2.Cod_rc AND obl1.Cuota_pago = obl2.Cuota_pago 
													 		  AND obl1.Fch_venc = obl2.Fch_venc AND obl1.Pagado = obl2.Pagado 
													 		  AND obl1.I_ProcedenciaID = obl2.I_ProcedenciaID
										) obl ON det.cod_rc = obl.cod_rc AND det.cod_alu = obl.cod_alu 
							  			 		 AND det.ano = obl.ano AND det.p = obl.p AND det.cuota_pago = obl.cuota_pago 
							  			 		 AND det.fch_venc = obl.fch_venc AND det.pagado = obl.Pagado '
							  			 							   
		IF (@T_AnioIni IS NOT NULL AND @T_AnioFin IS NOT NULL)
		BEGIN
			SET @T_Source = @T_Source + ' ' + char(13)+CHAR(10)+ 'WHERE (det.ano BETWEEN ''' + @T_AnioIni + ''' AND ''' + @T_AnioFin + ''')'
		END

		SET @T_SQL = '	DECLARE @D_FecProceso datetime = GETDATE()			 
						MERGE TR_Ec_Det AS TRG
						USING ('+ @T_Source +') AS SRC
						ON	  TRG.Cod_alu = SRC.cod_alu AND
							  TRG.Cod_rc = SRC.cod_rc AND
							  TRG.Cuota_pago = SRC.cuota_pago AND
							  TRG.Ano = SRC.ano AND
							  TRG.P = SRC.p AND
							  TRG.Tipo_oblig = SRC.tipo_oblig AND
							  TRG.Concepto = SRC.concepto AND
							  TRG.Fch_venc = SRC.fch_venc AND
							  TRG.Eliminado = SRC.eliminado AND
							  TRG.Pagado = SRC.pagado AND
							  TRG.Concepto_f = SRC.concepto_f AND
							  TRG.Fch_elimin = SRC.fch_elimin AND
							  TRG.Nro_ec = SRC.nro_ec AND
							  TRG.Fch_ec = SRC.fch_ec
						--WHEN MATCHED AND TRG.B_Migrado = 0 THEN
						--	UPDATE SET Nro_recibo = SRC.nro_recibo, 
						--			   Fch_pago = SRC.fch_pago, 
						--			   Id_lug_pag = SRC.id_lug_pag, 
						--			   Cantidad = SRC.cantidad, 
						--			   Monto = SRC.monto, 
						--			   Documento = CAST(SRC.documento as nvarchar(4000)),
						--			   Nro_ec = SRC.nro_ec, 
						--			   Fch_ec = SRC.fch_ec, 
						--			   Pag_demas = SRC.pag_demas, 
						--			   Cod_cajero = SRC.cod_cajero, 
						--			   Tipo_pago = SRC.tipo_pago, 
						--			   No_banco = SRC.no_banco, 
						--			   Cod_dep = SRC.cod_dep
						WHEN NOT MATCHED BY TARGET THEN
							INSERT (Cod_alu, Cod_rc, Cuota_pago, Ano, P, Tipo_oblig, Concepto, Fch_venc, Nro_recibo, Fch_pago, Id_lug_pag, Cantidad, Monto, Documento, Pagado, Concepto_f, Fch_elimin, 
									Nro_ec, Fch_ec, Eliminado, Pag_demas, Cod_cajero, Tipo_pago, No_banco, Cod_dep, D_FecCarga, B_Migrable, B_Migrado, D_FecMigrado, I_ProcedenciaID, B_Obligacion, I_OblRowID)
							VALUES (cod_alu, cod_rc, cuota_pago, ano, p, tipo_oblig, concepto, fch_venc, nro_recibo, fch_pago, id_lug_pag, cantidad, monto, CAST(SRC.documento as nvarchar(4000)), pagado, concepto_f, fch_elimin, 
									nro_ec, fch_ec, eliminado, pag_demas, cod_cajero, tipo_pago, no_banco, cod_dep, @D_FecProceso, 1, 0, NULL, ' + CAST(@I_ProcedenciaID as varchar(3)) + ', 1, I_OblRowID)
						WHEN NOT MATCHED BY SOURCE AND I_ProcedenciaID = ' + CAST(@I_ProcedenciaID as varchar(3)) + ' THEN
							UPDATE SET	TRG.B_Removido	  = 1, 
										TRG.D_FecRemovido = @D_FecProceso,
										TRG.B_Migrable	  = 0, 
										TRG.D_FecEvalua   = NULL,
										TRG.D_FecMigrado  = NULL, 
										TRG.B_Migrado	  = 0 
						OUTPUT	$ACTION, inserted.I_RowID, inserted.COD_ALU, inserted.COD_RC, inserted.CUOTA_PAGO, inserted.ANO, inserted.P, inserted.TIPO_OBLIG, inserted.CONCEPTO, inserted.FCH_VENC, inserted.ELIMINADO, 
								inserted.NRO_RECIBO, inserted.FCH_PAGO, inserted.ID_LUG_PAG, inserted.CANTIDAD, inserted.MONTO, inserted.PAGADO, inserted.CONCEPTO_F, inserted.FCH_ELIMIN, inserted.NRO_EC, inserted.FCH_EC, 
								inserted.PAG_DEMAS, inserted.COD_CAJERO, inserted.TIPO_PAGO, inserted.NO_BANCO, inserted.COD_DEP, deleted.NRO_RECIBO, deleted.FCH_PAGO, deleted.ID_LUG_PAG, deleted.CANTIDAD, deleted.MONTO, 
								deleted.PAGADO, deleted.CONCEPTO_F, deleted.FCH_ELIMIN, deleted.NRO_EC, deleted.FCH_EC, deleted.PAG_DEMAS, deleted.COD_CAJERO, deleted.TIPO_PAGO, deleted.NO_BANCO, deleted.COD_DEP, 
								deleted.B_Removido INTO #Tbl_output;
					'

		print @T_SQL
		Exec sp_executesql @T_SQL

		
		SET @T_SQL = 'SELECT cuota_pago, concepto, p, ano, fch_venc, cod_alu, cod_rc, monto, pagado, concepto_f FROM BD_OCEF_TemporalPagos.' + @T_SchemaDB + '.ec_det'
		
		IF (@T_AnioIni IS NOT NULL AND @T_AnioFin IS NOT NULL)
		BEGIN
			SET @T_SQL = @T_SQL + ' WHERE (ano BETWEEN ''' + @T_AnioIni + ''' AND ''' + @T_AnioFin + ''') '
		END

		print @T_SQL
		Exec sp_executesql @T_SQL

		SET @I_EcDet = @@ROWCOUNT
		SET @I_Insertados = (SELECT COUNT(*) FROM #Tbl_output WHERE accion = 'INSERT')
		SET @I_Actualizados = (SELECT COUNT(*) FROM #Tbl_output WHERE accion = 'UPDATE' AND B_Removido = 0)
		SET @I_Removidos = (SELECT COUNT(*) FROM #Tbl_output WHERE accion = 'UPDATE' AND B_Removido = 1)

		SELECT @I_EcDet AS tot_obligaciones, @I_Insertados AS cant_inserted, @I_Actualizados as cant_updated, @I_Removidos as cant_removed, @D_FecProceso as fec_proceso
		
		SET @B_Resultado = 1
		SET @T_Message =  'Total: ' + CAST(@I_EcDet AS varchar) + '|Insertados: ' + CAST(@I_Insertados AS varchar) + '|Actualizados: ' + CAST(@I_Actualizados AS varchar) + '|Removidos: ' + CAST(@I_Removidos AS varchar)
	END TRY
	BEGIN CATCH
		SET @B_Resultado = 0
		SET @T_Message = ERROR_MESSAGE() + ' LINE: ' + CAST(ERROR_LINE() AS varchar(10)) 
	END CATCH
END
GO


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_U_ValidarExisteAlumnoCabeceraObligacion')
	DROP PROCEDURE [dbo].[USP_U_ValidarExisteAlumnoCabeceraObligacion]
GO

CREATE PROCEDURE [dbo].[USP_U_ValidarExisteAlumnoCabeceraObligacion]	
	@T_AnioIni	  varchar(4),
	@T_AnioFin	  varchar(4),
	@B_Resultado  bit output,
	@T_Message	  nvarchar(4000) OUTPUT	
AS
--declare
--		@T_AnioIni	  varchar(4) = '2012',
--		@T_AnioFin	  varchar(4) = '2018',
--		@B_Resultado  bit,
--		@T_Message	  nvarchar(4000)
--exec USP_U_ValidarExisteAlumnoCabeceraObligacion @T_AnioIni, @T_AnioFin, @B_Resultado output, @T_Message output
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
				AND Ano BETWEEN @T_AnioIni AND @T_AnioFin
					
		MERGE TI_ObservacionRegistroTabla AS TRG
		USING 	(SELECT	@I_ObservID AS I_ObservID, @I_TablaID AS I_TablaID, I_RowID AS I_FilaTablaID, @D_FecProceso AS D_FecRegistro FROM TR_Ec_Obl
				  WHERE	NOT EXISTS (SELECT * FROM TR_Alumnos b WHERE TR_Ec_Obl.COD_ALU = C_CodAlu and TR_Ec_Obl.COD_RC = C_RcCod)
									AND Ano BETWEEN @T_AnioIni AND @T_AnioFin) AS SRC
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


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_IU_MigrarObligacionesCtasPorCobrar')
	DROP PROCEDURE [dbo].[USP_IU_MigrarObligacionesCtasPorCobrar]
GO

CREATE PROCEDURE [dbo].[USP_IU_MigrarObligacionesCtasPorCobrar]	
	@I_ProcedenciaID tinyint,
	@I_ProcesoID		int = NULL,
	@T_AnioIni			varchar(4) = NULL,
	@T_AnioFin			varchar(4) = NULL,
	@B_Resultado		bit output,
	@T_Message			nvarchar(4000) OUTPUT	
AS
--declare   @I_ProcedenciaID tinyint = 2,
--			@I_ProcesoID int = null, 
--			@T_AnioIni varchar(4) = '2013', 
--			@T_AnioFin varchar(4) = '2018', 
--			@B_Resultado  bit, 
--			@T_Message nvarchar(4000)
--exec USP_IU_MigrarObligacionesCtasPorCobrar @I_ProcedenciaID, @I_ProcesoID, @T_AnioIni, @T_AnioFin, @B_Resultado output, @T_Message output
--select @B_Resultado as resultado, @T_Message as mensaje
BEGIN
	DECLARE @I_Obl_Removidos int = 0
	DECLARE @I_Obl_Actualizados int = 0
	DECLARE @I_Obl_Insertados int = 0
	DECLARE @I_Det_Removidos int = 0
	DECLARE @I_Det_Actualizados int = 0
	DECLARE @I_Det_Insertados int = 0
	DECLARE @D_FecProceso datetime = GETDATE()
	DECLARE @I_MigracionTablaOblID tinyint = 5
	DECLARE @I_MigracionTablaDetID tinyint = 4
	DECLARE @T_Moneda varchar(3) = 'PEN'

	BEGIN TRANSACTION;
	BEGIN TRY 
		DECLARE @I_RowID  int, @Ano	 varchar(4), @P	 varchar(3), @I_Periodo	 int, @Cod_alu	varchar(20), @Cod_rc  varchar(3), 
				@Cuota_pago  int, @Tipo_oblig  bit,@Fch_venc  date, @Monto  decimal(10,2), @Pagado  bit, @I_MatAluID  int; 
								
		SET @I_RowID = IDENT_CURRENT('BD_OCEF_CtasPorCobrar.dbo.TR_ObligacionAluCab')

		SELECT @I_RowID + ROW_NUMBER() OVER (ORDER BY obl.I_RowID ASC) as OblCabAluID, ROW_NUMBER() OVER (ORDER BY obl.I_RowID ASC) as TempRowID, obl.I_RowID, obl.Ano, 
				obl.P, obl.I_Periodo, obl.Cod_alu, obl.Cod_rc, obl.Cuota_pago, obl.Tipo_oblig, obl.Fch_venc, obl.Monto, obl.Pagado, mat.I_MatAluID
		INTO #tmp_obl_migra
		FROM TR_Ec_Obl obl
			 INNER JOIN BD_OCEF_CtasPorCobrar.dbo.TC_MatriculaAlumno mat ON 
						obl.cod_alu = mat.C_CodAlu AND obl.cod_rc = mat.C_CodRc 
						AND obl.ano = CAST(mat.I_Anio as varchar(4)) AND obl.I_Periodo = mat.I_Periodo
		WHERE I_ProcedenciaID = @I_ProcedenciaID
			  AND (Cuota_pago = @I_ProcesoID OR @I_ProcesoID IS NULL)
			  AND (Ano BETWEEN @T_AnioIni AND @T_AnioFin)
			  --AND B_Migrable = 1;

		select * from #tmp_obl_migra

		SET @I_RowID = IDENT_CURRENT('BD_OCEF_CtasPorCobrar.dbo.TR_ObligacionAluDet')

		SELECT @I_RowID + ROW_NUMBER() OVER (ORDER BY det.I_OblRowID ASC) as OblDetAluID, ROW_NUMBER() OVER (ORDER BY det.I_OblRowID ASC) as TempRowID, I_OblRowID, Concepto, det.Monto, det.Pagado, 
				det.Fch_venc, CASE WHEN CAST(Documento as varchar(max)) IS NULL THEN NULL ELSE 138 END AS I_TipoDocumento, CAST(Documento as varchar(max)) AS T_DescDocumento, 
			   1 AS Habilitado, Eliminado, 1 as I_UsuarioCre, @D_FecProceso as D_FecCre, 0 AS Mora, 1 AS Migrado, @I_MigracionTablaDetID as I_MigracionTablaID, det.I_RowID
		INTO #tmp_det_migra
		FROM  TR_Ec_Det det
			  INNER JOIN TR_Ec_Obl obl ON det.I_OblRowID = obl.I_RowID
		WHERE det.I_ProcedenciaID = @I_ProcedenciaID
			  AND (det.Cuota_pago = @I_ProcesoID OR @I_ProcesoID IS NULL)
			  AND (det.Ano BETWEEN @T_AnioIni AND @T_AnioFin)
			  AND det.Concepto_f = 1
			  --AND det.B_Migrable = 1

		select * from #tmp_det_migra

		SET IDENTITY_INSERT BD_OCEF_CtasPorCobrar.dbo.TR_ObligacionAluCab ON

		MERGE INTO BD_OCEF_CtasPorCobrar.dbo.TR_ObligacionAluCab AS TRG
		USING #tmp_obl_migra AS SRC
		ON TRG.I_MigracionRowID = SRC.I_RowID AND
		   TRG.I_MigracionTablaID = @I_MigracionTablaOblID
		WHEN MATCHED THEN
			UPDATE SET TRG.I_ProcesoID = SRC.Cuota_pago, 
					   TRG.I_MatAluID = SRC.I_MatAluID, 
					   TRG.I_MontoOblig = SRC.Monto, 
					   TRG.D_FecVencto = SRC.Fch_venc, 
					   TRG.B_Pagado = SRC.Pagado, 
					   TRG.I_UsuarioMod = 1, 
					   TRG.D_FecMod = @D_FecProceso
		WHEN NOT MATCHED THEN
			INSERT (I_ObligacionAluID, I_ProcesoID, I_MatAluID, C_Moneda, I_MontoOblig, D_FecVencto, B_Pagado, B_Habilitado, 
					B_Eliminado, I_UsuarioCre, D_FecCre, B_Migrado, I_MigracionTablaID, I_MigracionRowID)
			VALUES (SRC.OblCabAluID, SRC.Cuota_pago, SRC.I_MatAluID, @T_Moneda, SRC.Monto, SRC.Fch_venc, SRC.Pagado, 1, 
					0, 1, @D_FecProceso, 1, @I_MigracionTablaOblID, @I_RowID);

		SET IDENTITY_INSERT BD_OCEF_CtasPorCobrar.dbo.TR_ObligacionAluCab OFF


		SET IDENTITY_INSERT BD_OCEF_CtasPorCobrar.dbo.TR_ObligacionAluDet ON

		MERGE INTO BD_OCEF_CtasPorCobrar.dbo.TR_ObligacionAluDet AS TRG
		USING (SELECT obl.I_ObligacionAluID, det.* FROM #tmp_det_migra det 
							INNER JOIN BD_OCEF_CtasPorCobrar.dbo.TR_ObligacionAluCab obl ON det.I_OblRowID = obl.I_MigracionRowID) AS SRC
		ON TRG.I_MigracionRowID = SRC.I_RowID AND
		   TRG.I_MigracionTablaID = @I_MigracionTablaDetID
		WHEN MATCHED THEN
			UPDATE SET TRG.I_ObligacionAluID = SRC.I_ObligacionAluID, 
					   TRG.I_ConcPagID = SRC.Concepto, 
					   TRG.I_Monto = SRC.Monto, 
					   TRG.B_Pagado = SRC.Pagado, 
					   TRG.D_FecVencto = SRC.Fch_venc, 
					   TRG.I_TipoDocumento = SRC.I_TipoDocumento, 
					   TRG.T_DescDocumento = SRC.T_DescDocumento, 
					   TRG.B_Mora = SRC.Mora, 
					   TRG.I_UsuarioMod = 1, 
					   TRG.D_FecMod = @D_FecProceso
		WHEN NOT MATCHED THEN
			INSERT (I_ObligacionAluDetID, I_ObligacionAluID, I_ConcPagID, I_Monto, B_Pagado, D_FecVencto, I_TipoDocumento, T_DescDocumento, 
					B_Habilitado, B_Eliminado, I_UsuarioCre, D_FecCre, B_Mora, B_Migrado, I_MigracionTablaID, I_MigracionRowID)
			VALUES (SRC.OblDetAluID, SRC.I_ObligacionAluID, SRC.Concepto, SRC.Monto, SRC.Pagado, SRC.Fch_venc, SRC.I_TipoDocumento, SRC.T_DescDocumento, 
					SRC.Habilitado, SRC.Eliminado, SRC.I_UsuarioCre, SRC.D_FecCre, SRC.Mora, SRC.Migrado, SRC.I_MigracionTablaID, SRC.I_RowID);

		SET IDENTITY_INSERT BD_OCEF_CtasPorCobrar.dbo.TR_ObligacionAluDet OFF

		--DECLARE CUR_OBL CURSOR
		--FOR
		--SELECT obl.I_RowID, obl.Ano, obl.P, obl.I_Periodo, obl.Cod_alu, obl.Cod_rc, obl.Cuota_pago, obl.Tipo_oblig, 
		--	   obl.Fch_venc, obl.Monto, obl.Pagado, mat.I_MatAluID
		--FROM TR_Ec_Obl obl
		--	 INNER JOIN BD_OCEF_CtasPorCobrar.dbo.TC_MatriculaAlumno mat ON 
		--				obl.cod_alu = mat.C_CodAlu AND obl.cod_rc = mat.C_CodRc 
		--				AND obl.ano = CAST(mat.I_Anio as varchar(4)) AND obl.I_Periodo = mat.I_Periodo
		--WHERE I_ProcedenciaID = @I_ProcedenciaID
		--	  AND (Cuota_pago = @I_ProcesoID OR @I_ProcesoID IS NULL)
		--	  AND (Ano BETWEEN @T_AnioIni AND @T_AnioFin)
		--	  AND B_Migrable = 1;


		--OPEN CUR_OBL
		--FETCH NEXT FROM	CUR_OBL INTO @I_RowID, @Ano, @P, @I_Periodo, @Cod_alu, @Cod_rc, @Cuota_pago, @Tipo_oblig, @Fch_venc, 
		--							 @Monto, @Pagado, @I_MatAluID;

		--	WHILE @@FETCH_STATUS = 0
		--	BEGIN

		--		INSERT INTO BD_OCEF_CtasPorCobrar.dbo.TR_ObligacionAluCab (I_ProcesoID, I_MatAluID, C_Moneda, I_MontoOblig, D_FecVencto, B_Pagado, B_Habilitado, 
		--																	B_Eliminado, I_UsuarioCre, D_FecCre, B_Migrado, I_MigracionTablaID, I_MigracionRowID)
		--														   VALUES (@Cuota_pago, @I_MatAluID, @T_Moneda, @Monto, @Fch_venc, @Pagado, 1, 
		--																	0, 1, @D_FecProceso, 1, @I_MigracionTablaOblID, @I_RowID)

		--		UPDATE TR_Ec_Obl 
		--		   SET B_Migrado = 1,
		--			   D_FecMigrado = @D_FecProceso
		--		WHERE
		--			   I_RowID = @I_RowID
				
		--		SET @I_Obl_Insertados = @I_Obl_Insertados + 1

		--		INSERT INTO BD_OCEF_CtasPorCobrar.dbo.TR_ObligacionAluDet (I_ObligacionAluID, I_ConcPagID, I_Monto, B_Pagado, D_FecVencto, I_TipoDocumento, T_DescDocumento, 
		--																   B_Habilitado, B_Eliminado, I_UsuarioCre, D_FecCre, B_Mora, B_Migrado, I_MigracionTablaID, I_MigracionRowID)
		--		SELECT I_OblRowID, Concepto, Monto, Pagado, Fch_venc, CASE WHEN CAST(Documento as varchar(max)) IS NULL THEN NULL ELSE 138 END AS I_TipoDocumento, 
		--			   CAST(Documento as varchar(max)) AS T_DescDocumento, 1 AS Habilitado, Eliminado, 1, @D_FecProceso, 0 AS Mora, 1 AS Migrado, @I_MigracionTablaDetID, I_RowID
		--		FROM  TR_Ec_Det
		--		WHERE I_OblRowID = @I_RowID
		--			  AND Concepto_f = 1
		--			  AND B_Migrable = 1

		--		UPDATE TR_Ec_Det
		--		   SET B_Migrado = 1,
		--			   D_FecMigrado = @D_FecProceso
		--		WHERE
		--			  I_OblRowID = @I_RowID
		--			  AND Concepto_f = 1
		--			  AND B_Migrable = 1

		--		SET @I_Det_Insertados = @I_Det_Insertados + @@ROWCOUNT

		--		FETCH NEXT FROM	CUR_OBL INTO @I_RowID, @Ano, @P, @I_Periodo, @Cod_alu, @Cod_rc, @Cuota_pago, @Tipo_oblig, @Fch_venc, 
		--									 @Monto, @Pagado, @I_MatAluID;
		--	END;
			
		--	CLOSE CUR_OBL;
		--	DEALLOCATE CUR_OBL;

			SET @B_Resultado = 1
			SET @T_Message = 'Obligaciones migradas:' + CAST(@I_Obl_Insertados AS varchar(10))  + ' | Detalle de obligaciones migradas: ' + CAST(@I_Det_Insertados AS varchar(10))

		COMMIT TRANSACTION;
	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION;
		SET @B_Resultado = 0
		SET @T_Message = ERROR_MESSAGE() + ' LINE: ' + CAST(ERROR_LINE() AS varchar(10)) 
	END CATCH
END
GO



IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_IU_PagoObligacionesCtasPorCobrar')
	DROP PROCEDURE [dbo].[USP_IU_PagoObligacionesCtasPorCobrar]
GO

CREATE PROCEDURE [dbo].[USP_IU_PagoObligacionesCtasPorCobrar]	
	@I_ProcedenciaID tinyint,
	@I_ProcesoID		int = NULL,
	@T_AnioIni			varchar(4) = NULL,
	@T_AnioFin			varchar(4) = NULL,
	@B_Resultado		bit output,
	@T_Message			nvarchar(4000) OUTPUT	
AS
--declare   @I_ProcedenciaID tinyint = 3
--			@I_ProcesoID int = null, 
--			@T_AnioIni varchar(4) = null, 
--			@T_AnioFin varchar(4) = null, 
--			@B_Resultado  bit, 
--			@T_Message nvarchar(4000)
--exec USP_IU_MigrarDetalleObligacionCtasPorCobrar @I_ProcedenciaID, @I_ProcesoID, @I_AnioIni, @I_AnioFin, @B_Resultado output, @T_Message output
--select @B_Resultado as resultado, @T_Message as mensaje
BEGIN
	DECLARE @I_Obl_Removidos int = 0
	DECLARE @I_Obl_Actualizados int = 0
	DECLARE @I_Obl_Insertados int = 0
	DECLARE @I_Det_Removidos int = 0
	DECLARE @I_Det_Actualizados int = 0
	DECLARE @I_Det_Insertados int = 0
	DECLARE @D_FecProceso datetime = GETDATE()
	DECLARE @I_MigracionTablaOblID tinyint = 5
	DECLARE @I_MigracionTablaDetID tinyint = 4
	DECLARE @T_Moneda varchar(3) = 'PEN'

	BEGIN TRANSACTION;
	BEGIN TRY 
		DECLARE @I_RowID  int, @Ano	 varchar(4), @P	 varchar(3), @I_Periodo	 int, @Cod_alu	varchar(20), @Cod_rc  varchar(3), 
				@Cuota_pago  int, @Tipo_oblig  bit,@Fch_venc  date, @Monto  decimal(10,2), @Pagado  bit, @I_MatAluID  int; 
								
		DECLARE CUR_OBL CURSOR
		FOR
		SELECT top 100 obl.I_RowID, obl.Ano, obl.P, obl.I_Periodo, obl.Cod_alu, obl.Cod_rc, obl.Cuota_pago, obl.Tipo_oblig, 
			   obl.Fch_venc, obl.Monto, obl.Pagado, mat.I_MatAluID
		FROM TR_Ec_Obl obl
			 INNER JOIN BD_OCEF_CtasPorCobrar.dbo.TC_MatriculaAlumno mat ON 
						obl.cod_alu = mat.C_CodAlu AND obl.cod_rc = mat.C_CodRc 
						AND obl.ano = CAST(mat.I_Anio as varchar(4)) AND obl.I_Periodo = mat.I_Periodo
		WHERE I_ProcedenciaID = @I_ProcedenciaID
			  AND (Cuota_pago = @I_ProcesoID OR @I_ProcesoID IS NULL)
			  AND (Ano BETWEEN @T_AnioIni AND @T_AnioFin)
			  AND B_Migrable = 1;


		OPEN CUR_OBL
		FETCH NEXT FROM	CUR_OBL INTO @I_RowID, @Ano, @P, @I_Periodo, @Cod_alu, @Cod_rc, @Cuota_pago, @Tipo_oblig, @Fch_venc, 
									 @Monto, @Pagado, @I_MatAluID;

			WHILE @@FETCH_STATUS = 0
			BEGIN

				INSERT INTO BD_OCEF_CtasPorCobrar.dbo.TR_ObligacionAluCab (I_ProcesoID, I_MatAluID, C_Moneda, I_MontoOblig, D_FecVencto, B_Pagado, B_Habilitado, 
																			B_Eliminado, I_UsuarioCre, D_FecCre, B_Migrado, I_MigracionTablaID, I_MigracionRowID)
																   VALUES (@Cuota_pago, @I_MatAluID, @T_Moneda, @Monto, @Fch_venc, @Pagado, 1, 
																			0, 1, @D_FecProceso, 1, @I_MigracionTablaOblID, @I_RowID)

				UPDATE TR_Ec_Obl 
				   SET B_Migrado = 1,
					   D_FecMigrado = @D_FecProceso
				WHERE
					   I_RowID = @I_RowID
				
				SET @I_Obl_Insertados = @I_Obl_Insertados + 1

				--INSERT INTO BD_OCEF_CtasPorCobrar.dbo.TR_ObligacionAluDet (I_ObligacionAluID, I_ConcPagID, I_Monto, B_Pagado, D_FecVencto, I_TipoDocumento, T_DescDocumento, 
				--														   B_Habilitado, B_Eliminado, I_UsuarioCre, D_FecCre, B_Mora, B_Migrado, I_MigracionTablaID, I_MigracionRowID)
				--SELECT I_OblRowID, Concepto, Monto, Pagado, Fch_venc, CASE WHEN CAST(Documento as varchar(max)) IS NULL THEN NULL ELSE 138 END AS I_TipoDocumento, 
				--	   CAST(Documento as varchar(max)) AS T_DescDocumento, 1 AS Habilitado, Eliminado, 1, @D_FecProceso, 0 AS Mora, 1 AS Migrado, @I_MigracionTablaDetID, I_RowID
				--FROM  TR_Ec_Det
				--WHERE I_OblRowID = @I_RowID
				--	  AND Concepto_f = 0
				--	  AND B_Migrable = 1

				--UPDATE TR_Ec_Det
				--   SET B_Migrado = 1,
				--	   D_FecMigrado = @D_FecProceso
				--WHERE
				--	  I_OblRowID = @I_RowID
				--	  AND Concepto_f = 1
				--	  AND B_Migrable = 1

				--SET @I_Det_Insertados = @I_Det_Insertados + @@ROWCOUNT

				FETCH NEXT FROM	CUR_OBL INTO @I_RowID, @Ano, @P, @I_Periodo, @Cod_alu, @Cod_rc, @Cuota_pago, @Tipo_oblig, @Fch_venc, 
											 @Monto, @Pagado, @I_MatAluID;
			END;
			
			CLOSE CUR_OBL;
			DEALLOCATE CUR_OBL;

			SET @B_Resultado = 1
			SET @T_Message = 'Obligaciones migradas:' + CAST(@I_Obl_Insertados AS varchar(10))  + ' | Detalle de obligaciones migradas: ' + CAST(@I_Det_Insertados AS varchar(10))

		COMMIT TRANSACTION;
	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION;
		SET @B_Resultado = 0
		SET @T_Message = ERROR_MESSAGE() + ' LINE: ' + CAST(ERROR_LINE() AS varchar(10)) 
	END CATCH
END
GO
