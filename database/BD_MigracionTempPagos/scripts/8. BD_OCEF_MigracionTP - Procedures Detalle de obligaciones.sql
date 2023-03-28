USE BD_OCEF_MigracionTP
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
--		@T_AnioIni	  varchar(4) = null,
--		@T_AnioFin	  varchar(4) = null,
--	 <vbnm;	@B_Resultado  bit,
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
							  			 		 AND det.fch_venc = obl.fch_venc --AND det.pagado = obl.Pagado 
						'
							  			 							   
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
						--WHEN NOT MATCHED BY SOURCE AND I_ProcedenciaID = ' + CAST(@I_ProcedenciaID as varchar(3)) + ' THEN
						--	UPDATE SET	TRG.B_Removido	  = 1, 
						--				TRG.D_FecRemovido = @D_FecProceso,
						--				TRG.B_Migrable	  = 0, 
						--				TRG.D_FecEvalua   = NULL,
						--				TRG.D_FecMigrado  = NULL, 
						--				TRG.B_Migrado	  = 0 
						OUTPUT	$ACTION, inserted.I_RowID, inserted.COD_ALU, inserted.COD_RC, inserted.CUOTA_PAGO, inserted.ANO, inserted.P, inserted.TIPO_OBLIG, inserted.CONCEPTO, inserted.FCH_VENC, inserted.ELIMINADO, 
								inserted.NRO_RECIBO, inserted.FCH_PAGO, inserted.ID_LUG_PAG, inserted.CANTIDAD, inserted.MONTO, inserted.PAGADO, inserted.CONCEPTO_F, inserted.FCH_ELIMIN, inserted.NRO_EC, inserted.FCH_EC, 
								inserted.PAG_DEMAS, inserted.COD_CAJERO, inserted.TIPO_PAGO, inserted.NO_BANCO, inserted.COD_DEP, deleted.NRO_RECIBO, deleted.FCH_PAGO, deleted.ID_LUG_PAG, deleted.CANTIDAD, deleted.MONTO, 
								deleted.PAGADO, deleted.CONCEPTO_F, deleted.FCH_ELIMIN, deleted.NRO_EC, deleted.FCH_EC, deleted.PAG_DEMAS, deleted.COD_CAJERO, deleted.TIPO_PAGO, deleted.NO_BANCO, deleted.COD_DEP, 
								deleted.B_Removido INTO #Tbl_output;
					'

		print @T_SQL
		Exec sp_executesql @T_SQL

		print @T_Source
		
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


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_U_InicializarEstadoValidacionDetalleObligacionPago')
	DROP PROCEDURE [dbo].[USP_U_InicializarEstadoValidacionDetalleObligacionPago]
GO

CREATE PROCEDURE USP_U_InicializarEstadoValidacionDetalleObligacionPago	
	@I_ProcedenciaID tinyint,
	@I_OblRowID	  int = NULL,
	@T_AnioIni	  varchar(4) = NULL,
	@T_AnioFin	  varchar(4) = NULL,
	@B_Resultado  bit output,
	@T_Message	  nvarchar(4000) OUTPUT	
AS
--declare	@B_Resultado  bit,
--			@I_ProcedenciaID	tinyint = 3,
--			@I_OblRowID		int = NULL,
--			@T_AnioIni	  varchar(4) = NULL,
--			@T_AnioFin	  varchar(4) = NULL,
--			@T_Message	  nvarchar(4000)
--exec USP_U_InicializarEstadoValidacionDetalleObligacionPago @I_ProcedenciaID, @I_OblRowID, @T_AnioIni, @T_AnioFin, @B_Resultado output, @T_Message output
--select @B_Resultado as resultado, @T_Message as mensaje
BEGIN
	SET @T_AnioIni = (SELECT ISNULL(@T_AnioIni, '0'))
	SET @T_AnioIni = (SELECT ISNULL(@T_AnioIni, '3000'))

	BEGIN TRANSACTION
	BEGIN TRY 
		UPDATE	TR_Ec_Det 
		   SET	B_Actualizado = IIF(B_Actualizado = 1, B_Actualizado, 0), 
				B_Migrable = 1, 
				D_FecMigrado = NULL, 
				B_Migrado = 0
		 WHERE I_ProcedenciaID = @I_ProcedenciaID
			   AND I_OblRowID = IIF(@I_OblRowID IS NULL, I_OblRowID, @I_OblRowID)
			   AND (Ano BETWEEN @T_AnioIni AND @T_AnioFin)

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


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_U_ValidarAnioEnDetalleObligacion')
	DROP PROCEDURE [dbo].[USP_U_ValidarAnioEnDetalleObligacion]
GO

CREATE PROCEDURE [dbo].[USP_U_ValidarAnioEnDetalleObligacion]	
	@I_ProcedenciaID tinyint,
	@I_OblRowID	  int = NULL,
	@B_Resultado  bit output,
	@T_Message	  nvarchar(4000) OUTPUT	
AS
--declare	@I_ProcedenciaID	tinyint = 3, 
--			@I_OblRowID		int = NULL,
--			@B_Resultado  bit,
--			@T_Message	  nvarchar(4000)
--exec USP_U_ValidarAnioEnDetalleObligacion @I_ProcedenciaID, @I_OblRowID, @B_Resultado output, @T_Message output
--select @B_Resultado as resultado, @T_Message as mensaje
BEGIN
	DECLARE @I_Observados int = 0
	DECLARE @I_ObservadosObl int = 0
	DECLARE @D_FecProceso datetime = GETDATE() 
	DECLARE @I_ObservID int = 26
	DECLARE @I_TablaID int = 4

	BEGIN TRANSACTION
	BEGIN TRY
	 
		UPDATE	TR_Ec_Det
		SET		B_Migrable = 0,
				D_FecEvalua = @D_FecProceso
		WHERE	ISNUMERIC(ANO) = 0
				AND I_OblRowID = IIF(@I_OblRowID IS NULL, I_OblRowID, @I_OblRowID)
				AND I_ProcedenciaID = @I_ProcedenciaID
				
		MERGE TI_ObservacionRegistroTabla AS TRG
		USING 	(SELECT	@I_ObservID AS I_ObservID, @I_TablaID AS I_TablaID, I_RowID AS I_FilaTablaID, @D_FecProceso AS D_FecRegistro 
				 FROM	TR_Ec_Det 
				 WHERE	ISNUMERIC(ANO) = 0 
						AND I_OblRowID = IIF(@I_OblRowID IS NULL, I_OblRowID, @I_OblRowID) 
						AND I_ProcedenciaID = @I_ProcedenciaID) AS SRC
		ON TRG.I_ObservID = SRC.I_ObservID AND TRG.I_TablaID = SRC.I_TablaID AND TRG.I_FilaTablaID = SRC.I_FilaTablaID
		WHEN MATCHED THEN
			UPDATE SET D_FecRegistro = SRC.D_FecRegistro
		WHEN NOT MATCHED BY TARGET THEN
			INSERT (I_ObservID, I_TablaID, I_FilaTablaID, D_FecRegistro, I_ProcedenciaID)
			VALUES (SRC.I_ObservID, SRC.I_TablaID, SRC.I_FilaTablaID, SRC.D_FecRegistro, @I_ProcedenciaID)
		WHEN NOT MATCHED BY SOURCE AND TRG.I_ObservID = @I_ObservID AND TRG.I_ProcedenciaID = @I_ProcedenciaID THEN
			DELETE;

		SET @I_Observados = (SELECT COUNT(*) FROM TI_ObservacionRegistroTabla 
							 WHERE I_ObservID = @I_ObservID AND I_TablaID = @I_TablaID AND I_ProcedenciaID = @I_ProcedenciaID)

		SET @I_TablaID = 5
		SET @I_ObservID = 37

		UPDATE	Ec_obl
		SET		B_Migrable = 0,
				D_FecEvalua = @D_FecProceso
		FROM    TR_Ec_Obl Ec_obl 
				INNER JOIN TR_Ec_Det Ec_det ON Ec_obl.I_RowID = Ec_det.I_OblRowID
		WHERE	ISNUMERIC(Ec_det.ANO) = 0
				AND I_OblRowID = IIF(@I_OblRowID IS NULL, I_OblRowID, @I_OblRowID) 
				AND Ec_det.I_ProcedenciaID = @I_ProcedenciaID

		MERGE   TI_ObservacionRegistroTabla AS TRG
		USING 	(SELECT	@I_ObservID AS I_ObservID, @I_TablaID AS I_TablaID, Ec_obl.I_RowID AS I_FilaTablaID, @D_FecProceso AS D_FecRegistro 
				 FROM   TR_Ec_Obl Ec_obl 
						INNER JOIN TR_Ec_Det Ec_det ON Ec_obl.I_RowID = Ec_det.I_OblRowID
				 WHERE	ISNUMERIC(Ec_det.ANO) = 0
						AND Ec_det.I_ProcedenciaID = @I_ProcedenciaID) AS SRC
		ON TRG.I_ObservID = SRC.I_ObservID AND TRG.I_TablaID = SRC.I_TablaID AND TRG.I_FilaTablaID = SRC.I_FilaTablaID
		WHEN MATCHED THEN
			UPDATE SET D_FecRegistro = SRC.D_FecRegistro
		WHEN NOT MATCHED BY TARGET THEN
			INSERT (I_ObservID, I_TablaID, I_FilaTablaID, D_FecRegistro)
			VALUES (SRC.I_ObservID, SRC.I_TablaID, SRC.I_FilaTablaID, SRC.D_FecRegistro)
		WHEN NOT MATCHED BY SOURCE AND TRG.I_ObservID = @I_ObservID AND TRG.I_ProcedenciaID = @I_ProcedenciaID THEN
			DELETE;

		SET @I_ObservadosObl = (SELECT COUNT(*) FROM TI_ObservacionRegistroTabla 
								WHERE I_ObservID = @I_ObservID AND I_TablaID = @I_TablaID AND I_ProcedenciaID = @I_ProcedenciaID)

		SELECT @I_Observados as cant_obs_det, @I_ObservadosObl as cant_obs_obl, @D_FecProceso as fec_proceso

		COMMIT TRANSACTION				

		SET @B_Resultado = 1
		SET @T_Message = CAST(@I_Observados AS varchar) + ' detalles sin obligación. | ' + CAST(@I_ObservadosObl AS varchar) + ' obligaciones sin detalle.'
	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION
		SET @B_Resultado = 0
		SET @T_Message = ERROR_MESSAGE() + ' LINE: ' + CAST(ERROR_LINE() AS varchar(10)) 
	END CATCH
END
GO



IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_U_ValidarPeriodoEnDetalleObligacion')
	DROP PROCEDURE [dbo].[USP_U_ValidarPeriodoEnDetalleObligacion]
GO

CREATE PROCEDURE [dbo].[USP_U_ValidarPeriodoEnDetalleObligacion]	
	@I_ProcedenciaID tinyint,
	@I_OblRowID	  int = NULL,
	@B_Resultado  bit output,
	@T_Message	  nvarchar(4000) OUTPUT	
AS
--declare	@I_ProcedenciaID	tinyint = 3, 
--			@I_OblRowID		int = NULL,
--			@B_Resultado  bit,/0.

*-*/
--			@T_Message	  nvarchar(4000)
--exec USP_U_ValidarPeriodoEnDetalleObligacion @I_ProcedenciaID, @I_OblRowID, @B_Resultado output, @T_Message output
--select @B_Resultado as resultado, @T_Message as mensaje
BEGIN
	DECLARE @I_Observados int = 0
	DECLARE @I_TablaID int = 5

	BEGIN TRANSACTION
	BEGIN TRY 
	DECLARE @D_FecProceso datetime = GETDATE() 
	DECLARE @I_ObservID int = 27

		UPDATE	TR_Ec_Det
		SET		B_Migrable = 0,
				D_FecEvalua = @D_FecProceso
		WHERE	P IS NULL OR P = ''
				AND I_ProcedenciaID = @I_ProcedenciaID
					
		MERGE TI_ObservacionRegistroTabla AS TRG
		USING 	(SELECT	@I_ObservID AS I_ObservID, @I_TablaID AS I_TablaID, I_RowID AS I_FilaTablaID, @D_FecProceso AS D_FecRegistro, I_ProcedenciaID
				   FROM TR_Ec_Obl
				  WHERE	I_Periodo IS NULL
				  		AND I_ProcedenciaID = @I_ProcedenciaID
				) AS SRC
		ON TRG.I_ObservID = SRC.I_ObservID AND TRG.I_TablaID = SRC.I_TablaID AND TRG.I_FilaTablaID = SRC.I_FilaTablaID
		WHEN MATCHED AND SRC.I_ProcedenciaID = @I_ProcedenciaID THEN
			UPDATE SET D_FecRegistro = SRC.D_FecRegistro
		WHEN NOT MATCHED BY TARGET AND SRC.I_ProcedenciaID = @I_ProcedenciaID THEN
			INSERT (I_ObservID, I_TablaID, I_FilaTablaID, D_FecRegistro, I_ProcedenciaID)
			VALUES (SRC.I_ObservID, SRC.I_TablaID, SRC.I_FilaTablaID, SRC.D_FecRegistro, @I_ProcedenciaID)
		WHEN NOT MATCHED BY SOURCE AND TRG.I_ObservID = @I_ObservID AND TRG.I_ProcedenciaID = @I_ProcedenciaID THEN
			DELETE;

		SET @I_Observados = (SELECT COUNT(*) FROM TI_ObservacionRegistroTabla 
							 WHERE I_ObservID = @I_ObservID AND I_TablaID = @I_TablaID AND I_ProcedenciaID = @I_ProcedenciaID)

		UPDATE	TR_Ec_Obl
		SET		B_Migrable = 0,
				D_FecEvalua = @D_FecProceso
		WHERE	I_Periodo IS NULL
				AND I_ProcedenciaID = @I_ProcedenciaID
					
		MERGE TI_ObservacionRegistroTabla AS TRG
		USING 	(SELECT	@I_ObservID AS I_ObservID, @I_TablaID AS I_TablaID, I_RowID AS I_FilaTablaID, @D_FecProceso AS D_FecRegistro, I_ProcedenciaID
				   FROM TR_Ec_Obl
				  WHERE	I_Periodo IS NULL
				  		AND I_ProcedenciaID = @I_ProcedenciaID
				) AS SRC
		ON TRG.I_ObservID = SRC.I_ObservID AND TRG.I_TablaID = SRC.I_TablaID AND TRG.I_FilaTablaID = SRC.I_FilaTablaID
		WHEN MATCHED AND SRC.I_ProcedenciaID = @I_ProcedenciaID THEN
			UPDATE SET D_FecRegistro = SRC.D_FecRegistro
		WHEN NOT MATCHED BY TARGET AND SRC.I_ProcedenciaID = @I_ProcedenciaID THEN
			INSERT (I_ObservID, I_TablaID, I_FilaTablaID, D_FecRegistro, I_ProcedenciaID)
			VALUES (SRC.I_ObservID, SRC.I_TablaID, SRC.I_FilaTablaID, SRC.D_FecRegistro, @I_ProcedenciaID)
		WHEN NOT MATCHED BY SOURCE AND TRG.I_ObservID = @I_ObservID AND TRG.I_ProcedenciaID = @I_ProcedenciaID THEN
			DELETE;

		SET @I_Observados = (SELECT COUNT(*) FROM TI_ObservacionRegistroTabla 
							 WHERE I_ObservID = @I_ObservID AND I_TablaID = @I_TablaID AND I_ProcedenciaID = @I_ProcedenciaID)

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
	@I_ProcedenciaID tinyint,
	@I_OblRowID	  int = NULL,
	@B_Resultado  bit output,
	@T_Message	  nvarchar(4000) OUTPUT	
AS
--declare	@I_ProcedenciaID	tinyint = 3, 
--			@I_OblRowID		int = NULL,
--			@B_Resultado  bit,
--			 @T_Message    nvarchar(4000)
--exec USP_U_ValidarFechaVencimientoCuotaObligacion @I_ProcedenciaID, @B_Resultado output, @T_Message output
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
							WHERE I_ProcedenciaID = @I_ProcedenciaID
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
								WHERE I_ProcedenciaID = @I_ProcedenciaID
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
			INSERT (I_ObservID, I_TablaID, I_FilaTablaID, D_FecRegistro, I_ProcedenciaID)
			VALUES (SRC.I_ObservID, SRC.I_TablaID, SRC.I_FilaTablaID, SRC.D_FecRegistro, @I_ProcedenciaID)
		WHEN NOT MATCHED BY SOURCE AND TRG.I_ObservID = @I_ObservID AND TRG.I_ProcedenciaID = @I_ProcedenciaID THEN
			DELETE;

		SET @I_Observados = (SELECT COUNT(*) FROM TI_ObservacionRegistroTabla 
							 WHERE I_ObservID = @I_ObservID AND I_TablaID = @I_TablaID AND I_ProcedenciaID = @I_ProcedenciaID)

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


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_U_ValidarObligacionCuotaPagoMigrada')
	DROP PROCEDURE [dbo].[USP_U_ValidarObligacionCuotaPagoMigrada]
GO

CREATE PROCEDURE [dbo].[USP_U_ValidarObligacionCuotaPagoMigrada]	
	@I_ProcedenciaID tinyint,
	@B_Resultado  bit output,
	@T_Message	  nvarchar(4000) OUTPUT	
AS
--declare @I_ProcedenciaID	tinyint = 3, 
--		  @B_Resultado  bit,
--		  @T_Message    nvarchar(4000)
--exec USP_U_ValidarObligacionCuotaPagoMigrada @I_ProcedenciaID, @B_Resultado output, @T_Message output
--select @B_Resultado as resultado, @T_Message as mensaje
BEGIN
	DECLARE @I_Observados int = 0
	DECLARE @D_FecProceso datetime = GETDATE() 
	DECLARE @I_ObservID int = 32
	DECLARE @I_TablaID int = 5

	BEGIN TRANSACTION
	BEGIN TRY

		UPDATE	TR_Ec_Obl
		SET		B_Migrable = 0,
				D_FecEvalua = @D_FecProceso
		WHERE	Cuota_pago IN (SELECT Cuota_pago FROM TR_Cp_Des WHERE B_Migrado = 0 AND I_ProcedenciaID = @I_ProcedenciaID)
				AND I_ProcedenciaID = @I_ProcedenciaID
					
		MERGE TI_ObservacionRegistroTabla AS TRG
		USING 	(SELECT	@I_ObservID AS I_ObservID, @I_TablaID AS I_TablaID, I_RowID AS I_FilaTablaID, @D_FecProceso AS D_FecRegistro 
				 FROM TR_Ec_Obl
				 WHERE	Cuota_pago IN (SELECT Cuota_pago FROM TR_Cp_Des WHERE B_Migrado = 0 AND I_ProcedenciaID = @I_ProcedenciaID)
						AND I_ProcedenciaID = @I_ProcedenciaID 
				 ) AS SRC
		ON TRG.I_ObservID = SRC.I_ObservID AND TRG.I_TablaID = SRC.I_TablaID AND TRG.I_FilaTablaID = SRC.I_FilaTablaID
		WHEN MATCHED THEN
			UPDATE SET D_FecRegistro = SRC.D_FecRegistro
		WHEN NOT MATCHED BY TARGET THEN
			INSERT (I_ObservID, I_TablaID, I_FilaTablaID, D_FecRegistro, I_ProcedenciaID)
			VALUES (SRC.I_ObservID, SRC.I_TablaID, SRC.I_FilaTablaID, SRC.D_FecRegistro, @I_ProcedenciaID)
		WHEN NOT MATCHED BY SOURCE AND TRG.I_ObservID = @I_ObservID AND TRG.I_ProcedenciaID = @I_ProcedenciaID THEN
			DELETE;

		SET @I_Observados = (SELECT COUNT(*) FROM TI_ObservacionRegistroTabla 
							 WHERE I_ObservID = @I_ObservID AND I_TablaID = @I_TablaID AND I_ProcedenciaID = @I_ProcedenciaID)

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


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_U_ValidarProcedenciaObligacionCuotaPago')
	DROP PROCEDURE [dbo].[USP_U_ValidarProcedenciaObligacionCuotaPago]
GO

CREATE PROCEDURE [dbo].[USP_U_ValidarProcedenciaObligacionCuotaPago]	
	@I_ProcedenciaID tinyint,
	@B_Resultado  bit output,
	@T_Message	  nvarchar(4000) OUTPUT	
AS
--declare @I_ProcedenciaID	tinyint = 3, 
--		  @B_Resultado  bit,
--		  @T_Message    nvarchar(4000)
--exec USP_U_ValidarProcedenciaObligacionCuotaPago @I_ProcedenciaID, @B_Resultado output, @T_Message output
--select @B_Resultado as resultado, @T_Message as mensaje
BEGIN
	DECLARE @I_Observados int = 0
	DECLARE @D_FecProceso datetime = GETDATE() 
	DECLARE @I_ObservID int = 34
	DECLARE @I_TablaID int = 5

	BEGIN TRANSACTION
	BEGIN TRY

		UPDATE	TR_Ec_Obl
		SET		B_Migrable = 0,
				D_FecEvalua = @D_FecProceso
		WHERE	Cuota_pago NOT IN (SELECT Cuota_pago FROM TR_Cp_Des WHERE I_ProcedenciaID = @I_ProcedenciaID)
				AND I_ProcedenciaID = @I_ProcedenciaID
					
		MERGE TI_ObservacionRegistroTabla AS TRG
		USING 	(SELECT	@I_ObservID AS I_ObservID, @I_TablaID AS I_TablaID, I_RowID AS I_FilaTablaID, @D_FecProceso AS D_FecRegistro 
				 FROM TR_Ec_Obl
				 WHERE	Cuota_pago NOT IN (SELECT Cuota_pago FROM TR_Cp_Des WHERE I_ProcedenciaID = @I_ProcedenciaID)
						AND I_ProcedenciaID = @I_ProcedenciaID
				 ) AS SRC
		ON TRG.I_ObservID = SRC.I_ObservID AND TRG.I_TablaID = SRC.I_TablaID AND TRG.I_FilaTablaID = SRC.I_FilaTablaID
		WHEN MATCHED THEN
			UPDATE SET D_FecRegistro = SRC.D_FecRegistro
		WHEN NOT MATCHED BY TARGET THEN
			INSERT (I_ObservID, I_TablaID, I_FilaTablaID, D_FecRegistro, I_ProcedenciaID)
			VALUES (SRC.I_ObservID, SRC.I_TablaID, SRC.I_FilaTablaID, SRC.D_FecRegistro, @I_ProcedenciaID)
		WHEN NOT MATCHED BY SOURCE AND TRG.I_ObservID = @I_ObservID AND TRG.I_ProcedenciaID = @I_ProcedenciaID THEN
			DELETE;

		SET @I_Observados = (SELECT COUNT(*) FROM TI_ObservacionRegistroTabla 
							  WHERE I_ObservID = @I_ObservID AND I_TablaID = @I_TablaID AND I_ProcedenciaID = @I_ProcedenciaID)

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
	@I_ProcedenciaID tinyint,
	@B_Resultado  bit output,
	@T_Message	  nvarchar(4000) OUTPUT	
AS
--declare @I_ProcedenciaID	tinyint = 3, 
--		  @B_Resultado  bit,
-- 		  @T_Message	nvarchar(4000)
--exec USP_U_ValidarDetalleObligacion @I_ProcedenciaID, @B_Resultado output, @T_Message output
--select @B_Resultado as resultado, @T_Message as mensaje
BEGIN
	DECLARE @I_Observados int = 0
	DECLARE @I_ObservadosObl int = 0
	DECLARE @D_FecProceso datetime = GETDATE() 
	DECLARE @I_ObservID int = 25
	DECLARE @I_TablaID int = 4

	BEGIN TRANSACTION
	BEGIN TRY 
		UPDATE	TR_Ec_Det
		SET		B_Migrable = 0,
				D_FecEvalua = @D_FecProceso
		WHERE	TIPO_OBLIG IS NOT NULL
				AND I_OblRowID IS NULL
				AND TR_Ec_Det.I_ProcedenciaID = @I_ProcedenciaID
					
		MERGE TI_ObservacionRegistroTabla AS TRG
		USING (SELECT @I_ObservID AS I_ObservID, @I_TablaID AS I_TablaID, I_RowID AS I_FilaTablaID, @D_FecProceso AS D_FecRegistro 
				FROM  TR_Ec_Det
			   WHERE  TIPO_OBLIG IS NOT NULL
					  AND I_OblRowID IS NULL
					  AND TR_Ec_Det.I_ProcedenciaID = @I_ProcedenciaID
			  ) AS SRC
		ON TRG.I_ObservID = SRC.I_ObservID AND TRG.I_TablaID = SRC.I_TablaID AND TRG.I_FilaTablaID = SRC.I_FilaTablaID
		WHEN MATCHED THEN
			UPDATE SET D_FecRegistro = SRC.D_FecRegistro
		WHEN NOT MATCHED BY TARGET THEN
			INSERT (I_ObservID, I_TablaID, I_FilaTablaID, D_FecRegistro, I_ProcedenciaID)
			VALUES (SRC.I_ObservID, SRC.I_TablaID, SRC.I_FilaTablaID, SRC.D_FecRegistro, @I_ProcedenciaID)
		WHEN NOT MATCHED BY SOURCE AND TRG.I_ObservID = @I_ObservID AND TRG.I_ProcedenciaID = @I_ProcedenciaID THEN
			DELETE;

		SET @I_Observados = (SELECT COUNT(*) FROM TI_ObservacionRegistroTabla 
							  WHERE I_ObservID = @I_ObservID AND I_TablaID = @I_TablaID AND I_ProcedenciaID = @I_ProcedenciaID)

		SET @I_ObservID = 40
		SET @I_TablaID = 5

		UPDATE	Obl
		SET		B_Migrable = 0,
				D_FecEvalua = @D_FecProceso
		FROM	TR_Ec_Obl Obl
				LEFT JOIN TR_Ec_Det Det ON Obl.I_RowID = Det.I_OblRowID
		WHERE	Obl.TIPO_OBLIG IS NOT NULL
				AND I_OblRowID IS NULL
				AND Det.I_ProcedenciaID = @I_ProcedenciaID
					
		MERGE TI_ObservacionRegistroTabla AS TRG
		USING (SELECT @I_ObservID AS I_ObservID, @I_TablaID AS I_TablaID, Obl.I_RowID AS I_FilaTablaID, @D_FecProceso AS D_FecRegistro 
				FROM  TR_Ec_Obl Obl
					  LEFT JOIN TR_Ec_Det Det ON Obl.I_RowID = Det.I_OblRowID
			    WHERE Obl.TIPO_OBLIG IS NOT NULL
					  AND I_OblRowID IS NULL
					  AND Det.I_ProcedenciaID = @I_ProcedenciaID
			  ) AS SRC
		ON TRG.I_ObservID = SRC.I_ObservID AND TRG.I_TablaID = SRC.I_TablaID AND TRG.I_FilaTablaID = SRC.I_FilaTablaID
		WHEN MATCHED THEN
			UPDATE SET D_FecRegistro = SRC.D_FecRegistro
		WHEN NOT MATCHED BY TARGET THEN
			INSERT (I_ObservID, I_TablaID, I_FilaTablaID, D_FecRegistro, I_ProcedenciaID)
			VALUES (SRC.I_ObservID, SRC.I_TablaID, SRC.I_FilaTablaID, SRC.D_FecRegistro, @I_ProcedenciaID)
		WHEN NOT MATCHED BY SOURCE AND TRG.I_ObservID = @I_ObservID AND TRG.I_ProcedenciaID = @I_ProcedenciaID THEN
			DELETE;

		SET @I_ObservadosObl = (SELECT COUNT(*) FROM TI_ObservacionRegistroTabla 
								 WHERE I_ObservID = @I_ObservID AND I_TablaID = @I_TablaID AND I_ProcedenciaID = @I_ProcedenciaID)


		SELECT @I_Observados as cant_obs_det, @I_ObservadosObl as cant_obs_obl, @D_FecProceso as fec_proceso

		COMMIT TRANSACTION				

		SET @B_Resultado = 1
		SET @T_Message = CAST(@I_Observados AS varchar) + ' detalles sin obligación. | ' + CAST(@I_ObservadosObl AS varchar) + ' obligaciones sin detalle.'

	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION
		SET @B_Resultado = 0
		SET @T_Message = ERROR_MESSAGE() + ' LINE: ' + CAST(ERROR_LINE() AS varchar(10)) 
	END CATCH
END
GO


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_U_ValidarDetalleObligacionConceptoPago')
	DROP PROCEDURE [dbo].[USP_U_ValidarDetalleObligacionConceptoPago]
GO

CREATE PROCEDURE [dbo].[USP_U_ValidarDetalleObligacionConceptoPago]	
	@I_ProcedenciaID tinyint,
	@B_Resultado	bit output,
	@T_Message		nvarchar(4000) OUTPUT	
AS
--declare @I_ProcedenciaID	tinyint = 3, 
--		  @B_Resultado  bit,
--		  @T_Message    nvarchar(4000)
--exec USP_U_ValidarDetalleObligacionConceptoPago @I_ProcedenciaID, @B_Resultado output, @T_Message output
--select @B_Resultado as resultado, @T_Message as mensaje
BEGIN
	DECLARE @I_Observados int = 0
	DECLARE @I_ObservadosObl int = 0
	DECLARE @D_FecProceso datetime = GETDATE() 
	DECLARE @I_ObservID int = 35
	DECLARE @I_TablaID int = 4

	BEGIN TRANSACTION
	BEGIN TRY

		UPDATE	Det
		SET		B_Migrable = 0,
				D_FecEvalua = @D_FecProceso
		FROM    TR_Ec_Det Det
				LEFT JOIN (SELECT Id_cp, I_ProcedenciaID FROM TR_Cp_Pri) Pri ON Det.Concepto = Pri.Id_cp and Det.I_ProcedenciaID = Pri.I_ProcedenciaID
		WHERE	Pri.Id_cp is null
				AND Det.I_ProcedenciaID = @I_ProcedenciaID
				AND Concepto_f = 0 
					
		MERGE TI_ObservacionRegistroTabla AS TRG
		USING 	(SELECT	@I_ObservID AS I_ObservID, @I_TablaID AS I_TablaID, I_RowID AS I_FilaTablaID, @D_FecProceso AS D_FecRegistro 
				 FROM TR_Ec_Det Det
						LEFT JOIN (SELECT Id_cp, I_ProcedenciaID FROM TR_Cp_Pri) Pri ON Det.Concepto = Pri.Id_cp AND Det.I_ProcedenciaID = Pri.I_ProcedenciaID
				 WHERE	Pri.Id_cp is null
						AND Det.I_ProcedenciaID = @I_ProcedenciaID
						AND Concepto_f = 0 
				 ) AS SRC
		ON TRG.I_ObservID = SRC.I_ObservID AND TRG.I_TablaID = SRC.I_TablaID AND TRG.I_FilaTablaID = SRC.I_FilaTablaID
		WHEN MATCHED AND TRG.I_ProcedenciaID = @I_ProcedenciaID THEN
			UPDATE SET D_FecRegistro = SRC.D_FecRegistro
		WHEN NOT MATCHED BY TARGET THEN
			INSERT (I_ObservID, I_TablaID, I_FilaTablaID, D_FecRegistro, I_ProcedenciaID)
			VALUES (SRC.I_ObservID, SRC.I_TablaID, SRC.I_FilaTablaID, SRC.D_FecRegistro, @I_ProcedenciaID)
		WHEN NOT MATCHED BY SOURCE AND TRG.I_ObservID = @I_ObservID AND TRG.I_ProcedenciaID = @I_ProcedenciaID THEN
			DELETE;

		SET @I_Observados = (SELECT COUNT(*) FROM TI_ObservacionRegistroTabla 
							  WHERE I_ObservID = @I_ObservID AND I_TablaID = @I_TablaID AND I_ProcedenciaID = @I_ProcedenciaID)

		SET @I_ObservID = 39
		SET @I_TablaID  = 5

		UPDATE	Obl
		SET		B_Migrable = 0,
				D_FecEvalua = @D_FecProceso
		FROM    TR_Ec_Obl Obl
				INNER JOIN TR_Ec_Det Det ON Obl.I_RowID = Det.I_OblRowID
				LEFT JOIN (SELECT Id_cp, I_ProcedenciaID FROM TR_Cp_Pri) Pri ON Det.Concepto = Pri.Id_cp and Det.I_ProcedenciaID = Pri.I_ProcedenciaID
		WHERE	Pri.Id_cp is null
				AND Det.I_ProcedenciaID = @I_ProcedenciaID
				AND Concepto_f = 0 
					
		MERGE	TI_ObservacionRegistroTabla AS TRG
		USING 	(SELECT	@I_ObservID AS I_ObservID, @I_TablaID AS I_TablaID, Obl.I_RowID AS I_FilaTablaID, @D_FecProceso AS D_FecRegistro 
				 FROM   TR_Ec_Obl Obl
				 		INNER JOIN TR_Ec_Det Det ON Obl.I_RowID = Det.I_OblRowID
				 		LEFT JOIN (SELECT Id_cp, I_ProcedenciaID FROM TR_Cp_Pri) Pri ON Det.Concepto = Pri.Id_cp and Det.I_ProcedenciaID = Pri.I_ProcedenciaID
				 WHERE	Pri.Id_cp IS NULL
						AND Det.I_ProcedenciaID = @I_ProcedenciaID
						AND Concepto_f = 0 
				) AS SRC
		ON TRG.I_ObservID = SRC.I_ObservID AND TRG.I_TablaID = SRC.I_TablaID AND TRG.I_FilaTablaID = SRC.I_FilaTablaID
		WHEN MATCHED AND TRG.I_ProcedenciaID = @I_ProcedenciaID THEN
			UPDATE SET D_FecRegistro = SRC.D_FecRegistro
		WHEN NOT MATCHED BY TARGET THEN
			INSERT (I_ObservID, I_TablaID, I_FilaTablaID, D_FecRegistro, I_ProcedenciaID)
			VALUES (SRC.I_ObservID, SRC.I_TablaID, SRC.I_FilaTablaID, SRC.D_FecRegistro, @I_ProcedenciaID)
		WHEN NOT MATCHED BY SOURCE AND TRG.I_ObservID = @I_ObservID AND TRG.I_ProcedenciaID = @I_ProcedenciaID THEN
			DELETE;

		SET @I_ObservadosObl = (SELECT COUNT(*) FROM TI_ObservacionRegistroTabla 
								WHERE I_ObservID = @I_ObservID AND I_TablaID = @I_TablaID AND I_ProcedenciaID = @I_ProcedenciaID)

		SELECT @I_Observados as cant_obs_det, @I_ObservadosObl as cant_obs_obl, @D_FecProceso as fec_proceso

		COMMIT TRANSACTION				
		SET @B_Resultado = 1
		SET @T_Message = CAST(@I_Observados AS varchar) + ' detalles observados | ' + CAST(@I_ObservadosObl AS varchar) + ' obligaciones observadas.'
	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION
		SET @B_Resultado = 0
		SET @T_Message = ERROR_MESSAGE() + ' LINE: ' + CAST(ERROR_LINE() AS varchar(10)) 
	END CATCH
END
GO


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_U_ValidarDetalleObligacionConceptoPagoMigrado')
	DROP PROCEDURE [dbo].[USP_U_ValidarDetalleObligacionConceptoPagoMigrado]
GO

CREATE PROCEDURE [dbo].[USP_U_ValidarDetalleObligacionConceptoPagoMigrado]	
	@I_ProcedenciaID tinyint,
	@B_Resultado  bit output,
	@T_Message	  nvarchar(4000) OUTPUT	
AS
--declare @I_ProcedenciaID	tinyint = 3, 
--		  @B_Resultado  bit,
--		  @T_Message    nvarchar(4000)
--exec USP_U_ValidarDetalleObligacionConceptoPagoMigrado @I_ProcedenciaID, @B_Resultado output, @T_Message output
--select @B_Resultado as resultado, @T_Message as mensaje
BEGIN
	DECLARE @I_Observados int = 0
	DECLARE @I_ObservadosObl int = 0
	DECLARE @D_FecProceso datetime = GETDATE() 
	DECLARE @I_ObservID int = 33
	DECLARE @I_TablaID int = 4
	DECLARE @I_TablaOblID int = 5

	BEGIN TRANSACTION
	BEGIN TRY

		UPDATE	Det
		SET		B_Migrable = 0,
				D_FecEvalua = @D_FecProceso
		FROM    TR_Ec_Det Det
				LEFT JOIN (SELECT Id_cp, I_ProcedenciaID FROM TR_Cp_Pri WHERE B_Migrado = 1) Pri 
						  ON Det.Concepto = Pri.Id_cp AND Det.I_ProcedenciaID = Pri.I_ProcedenciaID
		WHERE	Pri.Id_cp IS NULL
			AND Det.I_ProcedenciaID = @I_ProcedenciaID
			AND Concepto_f = 0 
					
		MERGE TI_ObservacionRegistroTabla AS TRG
		USING 	(SELECT	@I_ObservID AS I_ObservID, @I_TablaID AS I_TablaID, I_RowID AS I_FilaTablaID, @D_FecProceso AS D_FecRegistro 
				 FROM   TR_Ec_Det Det
						LEFT JOIN (SELECT Id_cp, I_ProcedenciaID FROM TR_Cp_Pri WHERE B_Migrado = 1) Pri 
								  ON Det.Concepto = Pri.Id_cp AND Det.I_ProcedenciaID = Pri.I_ProcedenciaID
				 WHERE	Pri.Id_cp IS NULL
					AND Det.I_ProcedenciaID = @I_ProcedenciaID
					AND Concepto_f = 0 
				 ) AS SRC
		ON TRG.I_ObservID = SRC.I_ObservID AND TRG.I_TablaID = SRC.I_TablaID AND TRG.I_FilaTablaID = SRC.I_FilaTablaID
		WHEN MATCHED AND TRG.I_ProcedenciaID = @I_ProcedenciaID THEN
			UPDATE SET D_FecRegistro = SRC.D_FecRegistro
		WHEN NOT MATCHED BY TARGET THEN
			INSERT (I_ObservID, I_TablaID, I_FilaTablaID, D_FecRegistro, I_ProcedenciaID)
			VALUES (SRC.I_ObservID, SRC.I_TablaID, SRC.I_FilaTablaID, SRC.D_FecRegistro, @I_ProcedenciaID)
		WHEN NOT MATCHED BY SOURCE AND TRG.I_ObservID = @I_ObservID AND TRG.I_ProcedenciaID = @I_ProcedenciaID THEN
			DELETE;

		SET @I_Observados = (SELECT COUNT(*) FROM TI_ObservacionRegistroTabla 
							  WHERE I_ObservID = @I_ObservID AND I_TablaID = @I_TablaID AND I_ProcedenciaID = @I_ProcedenciaID)

		SET @I_ObservID = 36

		UPDATE	Obl
		SET		B_Migrable = 0,
				D_FecEvalua = @D_FecProceso
		FROM    TR_Ec_Obl Obl
				INNER JOIN TR_Ec_Det Det ON Obl.I_RowID = Det.I_OblRowID
				LEFT JOIN (SELECT Id_cp, I_ProcedenciaID FROM TR_Cp_Pri WHERE B_Migrado = 1) Pri 
						  ON Det.Concepto = Pri.Id_cp AND Det.I_ProcedenciaID = Pri.I_ProcedenciaID
		WHERE	Pri.Id_cp IS NULL
			AND Det.I_ProcedenciaID = @I_ProcedenciaID
			AND Det.Concepto_f = 0 

		MERGE TI_ObservacionRegistroTabla AS TRG
		USING (SELECT @I_ObservID AS I_ObservID, @I_TablaOblID AS I_TablaID, Obl.I_RowID AS I_FilaTablaID, @D_FecProceso AS D_FecRegistro 
				 FROM TR_Ec_Obl Obl
					  INNER JOIN TR_Ec_Det Det ON Obl.I_RowID = Det.I_OblRowID
					  LEFT JOIN (SELECT Id_cp, I_ProcedenciaID FROM TR_Cp_Pri WHERE B_Migrado = 1) Pri 
								 ON Det.Concepto = Pri.Id_cp AND Det.I_ProcedenciaID = Pri.I_ProcedenciaID
				WHERE Pri.Id_cp IS NULL
					  AND Det.I_ProcedenciaID = @I_ProcedenciaID
					  AND Det.Concepto_f = 0 
			  ) AS SRC
		ON TRG.I_ObservID = SRC.I_ObservID AND TRG.I_TablaID = SRC.I_TablaID AND TRG.I_FilaTablaID = SRC.I_FilaTablaID
		WHEN MATCHED AND TRG.I_ProcedenciaID = @I_ProcedenciaID THEN
			UPDATE SET D_FecRegistro = SRC.D_FecRegistro
		WHEN NOT MATCHED BY TARGET THEN
			INSERT (I_ObservID, I_TablaID, I_FilaTablaID, D_FecRegistro, I_ProcedenciaID)
			VALUES (SRC.I_ObservID, SRC.I_TablaID, SRC.I_FilaTablaID, SRC.D_FecRegistro, @I_ProcedenciaID)
		WHEN NOT MATCHED BY SOURCE AND TRG.I_ObservID = @I_ObservID AND TRG.I_ProcedenciaID = @I_ProcedenciaID THEN
			DELETE;

		SET @I_ObservadosObl = (SELECT COUNT(*) FROM TI_ObservacionRegistroTabla 
								WHERE I_ObservID = @I_ObservID AND I_TablaID = @I_TablaOblID AND I_ProcedenciaID = @I_ProcedenciaID)

		SELECT @I_Observados as cant_obs_det, @I_ObservadosObl as cant_obs_obl, @D_FecProceso as fec_proceso

		COMMIT TRANSACTION				
		SET @B_Resultado = 1
		SET @T_Message = CAST(@I_Observados AS varchar) + ' detalles observados | ' + CAST(@I_ObservadosObl AS varchar) + ' obligaciones observadas.'
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
	@I_ProcedenciaID	tinyint,
	@I_ProcesoID		int = NULL,
	@I_AnioIni			int = NULL,
	@I_AnioFin			int = NULL,
	@B_Resultado		bit output,
	@T_Message			nvarchar(4000) OUTPUT	
AS
--declare   @I_ProcedenciaID tinyint = 3,
--			@I_ProcesoID int = null, 
--			@I_AnioIni	 int = null, 
--			@I_AnioFin	 int = null, 
--			@B_Resultado  bit, 
--			@T_Message nvarchar(4000)
--exec USP_IU_MigrarObligacionesCtasPorCobrar @I_ProcedenciaID, @I_ProcesoID, @I_AnioIni, @I_AnioFin, @B_Resultado output, @T_Message output
--select @B_Resultado as resultado, @T_Message as mensaje
BEGIN
	DECLARE @I_Obl_Removidos int = 0
	DECLARE @I_Obl_Actualizados int = 0
	DECLARE @I_Obl_Insertados int = 0
	DECLARE @I_Det_Removidos int = 0
	DECLARE @I_Det_Actualizados int = 0
	DECLARE @I_Det_Insertados int = 0
	DECLARE @Tbl_outputMat AS TABLE (T_Action varchar(20), I_RowID int)
	DECLARE @Tbl_outputObl AS TABLE (T_Action varchar(20), I_RowID int)
	DECLARE @Tbl_outputDet AS TABLE (T_Action varchar(20), I_RowID int)

	DECLARE @D_FecProceso datetime = GETDATE()
	DECLARE @I_MigracionTablaOblID tinyint = 5
	DECLARE @I_MigracionTablaDetID tinyint = 4
	DECLARE @T_Moneda varchar(3) = 'PEN'

	SET @I_AnioIni = (SELECT ISNULL(@I_AnioIni, 0))
	SET @I_AnioFin = (SELECT ISNULL(@I_AnioFin, 3000))


	BEGIN TRANSACTION;
	BEGIN TRY 
		DECLARE @I_RowID  int
								
		SELECT * 
		INTO #Numeric_Year_Ec_Obl
		FROM TR_Ec_Obl
		WHERE ISNUMERIC(ANO) = 1
			  AND I_ProcedenciaID = @I_ProcedenciaID

		MERGE INTO BD_OCEF_CtasPorCobrar.dbo.TC_MatriculaAlumno AS TRG
		USING (SELECT DISTINCT Cod_alu, Cod_rc, Ano, P, I_Periodo FROM  #Numeric_Year_Ec_Obl
				WHERE CAST(Ano AS int) BETWEEN @I_AnioIni AND @I_AnioFin) AS SRC
		ON TRG.C_CodAlu = SRC.cod_alu 
		   AND TRG.C_CodRc = SRC.cod_rc 
		   AND TRG.I_Anio  = CAST(SRC.ano AS int) 
		   AND TRG.I_Periodo = SRC.I_Periodo
		WHEN NOT MATCHED THEN
			INSERT (C_CodRc, C_CodAlu, I_Anio, I_Periodo, C_EstMat, C_Ciclo, B_Ingresante, I_CredDesaprob, B_Habilitado, B_Eliminado, B_Migrado)
			VALUES (SRC.Cod_rc, SRC.Cod_alu, CAST(SRC.Ano as int), SRC.I_Periodo, 'S', NULL, NULL, NULL, 1, 0, 1);


		SET @I_RowID = IDENT_CURRENT('BD_OCEF_CtasPorCobrar.dbo.TR_ObligacionAluCab')

		SELECT @I_RowID + ROW_NUMBER() OVER (ORDER BY obl.I_RowID ASC) as OblCabAluID, ROW_NUMBER() OVER (ORDER BY obl.I_RowID ASC) as TempRowID, obl.I_RowID, 
			   obl.Ano, obl.P, obl.I_Periodo, obl.Cod_alu, obl.Cod_rc, obl.Cuota_pago, obl.Tipo_oblig, obl.Fch_venc, obl.Monto, obl.Pagado, mat.I_MatAluID
		INTO #tmp_obl_migra
		FROM #Numeric_Year_Ec_Obl obl
			 INNER JOIN BD_OCEF_CtasPorCobrar.dbo.TC_MatriculaAlumno mat ON 
						obl.cod_alu = mat.C_CodAlu 
						AND obl.cod_rc = mat.C_CodRc 
						AND CAST(obl.ano AS int) = mat.I_Anio 
						AND obl.I_Periodo = mat.I_Periodo
		WHERE obl.I_ProcedenciaID = @I_ProcedenciaID
			  AND obl.Cuota_pago = IIF(@I_ProcesoID IS NULL, obl.Cuota_pago, @I_ProcesoID)
			  AND (CAST(obl.Ano AS int) BETWEEN @I_AnioIni AND @I_AnioFin)
			  AND B_Migrable = 1;


		SET @I_RowID = IDENT_CURRENT('BD_OCEF_CtasPorCobrar.dbo.TR_ObligacionAluDet')

		SELECT @I_RowID + ROW_NUMBER() OVER (ORDER BY det.I_OblRowID ASC) as OblDetAluID, ROW_NUMBER() OVER (ORDER BY det.I_OblRowID ASC) as TempRowID, I_OblRowID, Concepto, 
			   det.Monto, det.Pagado, det.Fch_venc, CASE WHEN CAST(Documento as varchar(max)) IS NULL THEN NULL ELSE 138 END AS I_TipoDocumento, 
			   CAST(Documento as varchar(max)) AS T_DescDocumento, 1 AS Habilitado, Eliminado, 1 as I_UsuarioCre, @D_FecProceso as D_FecCre, 0 AS Mora, det.I_RowID
		INTO #tmp_det_migra
		FROM  TR_Ec_Det det
			  INNER JOIN TR_Ec_Obl obl ON det.I_OblRowID = obl.I_RowID
		WHERE det.I_ProcedenciaID = @I_ProcedenciaID
			  AND det.Cuota_pago = IIF(@I_ProcesoID IS NULL, det.Cuota_pago, @I_ProcesoID)
			  AND (CAST(det.Ano AS int) BETWEEN @I_AnioIni AND @I_AnioFin)
			  AND det.Concepto_f = 0
			  AND det.B_Migrable = 1


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
					   TRG.B_Pagado = 0, 
					   TRG.I_UsuarioMod = NULL, 
					   TRG.D_FecMod = @D_FecProceso
		WHEN NOT MATCHED THEN
			INSERT (I_ObligacionAluID, I_ProcesoID, I_MatAluID, C_Moneda, I_MontoOblig, D_FecVencto, B_Pagado, B_Habilitado, 
					B_Eliminado, I_UsuarioCre, D_FecCre, B_Migrado, I_MigracionTablaID, I_MigracionRowID)
			VALUES (SRC.OblCabAluID, SRC.Cuota_pago, SRC.I_MatAluID, @T_Moneda, SRC.Monto, SRC.Fch_venc, 0, 1, 
					0, NULL, @D_FecProceso, 1, @I_MigracionTablaOblID, SRC.I_RowID)
		OUTPUT $action, SRC.I_RowID INTO @Tbl_outputObl;

		SET IDENTITY_INSERT BD_OCEF_CtasPorCobrar.dbo.TR_ObligacionAluCab OFF

		SELECT * FROM @Tbl_outputObl

		SET @I_Obl_Insertados = (SELECT COUNT(*) FROM @Tbl_outputObl WHERE T_Action = 'INSERT')
		SET @I_Obl_Actualizados = (SELECT COUNT(*) FROM @Tbl_outputObl WHERE T_Action = 'UPDATE')

		
		SET IDENTITY_INSERT BD_OCEF_CtasPorCobrar.dbo.TR_ObligacionAluDet ON

		MERGE INTO BD_OCEF_CtasPorCobrar.dbo.TR_ObligacionAluDet AS TRG
		USING (SELECT obl.I_ObligacionAluID, det.* FROM #tmp_det_migra det 
							INNER JOIN BD_OCEF_CtasPorCobrar.dbo.TR_ObligacionAluCab obl ON det.I_OblRowID = obl.I_MigracionRowID) AS SRC
		ON TRG.I_MigracionRowID = SRC.I_RowID AND
		   TRG.I_MigracionTablaID = @I_MigracionTablaDetID
		WHEN MATCHED AND TRG.I_UsuarioCre IS NULL THEN
			UPDATE SET TRG.I_ObligacionAluID = SRC.I_ObligacionAluID, 
					   TRG.I_ConcPagID = SRC.Concepto, 
					   TRG.I_Monto = SRC.Monto, 
					   TRG.B_Pagado = 0, 
					   TRG.D_FecVencto = SRC.Fch_venc, 
					   TRG.I_TipoDocumento = SRC.I_TipoDocumento, 
					   TRG.T_DescDocumento = SRC.T_DescDocumento, 
					   TRG.B_Mora = SRC.Mora, 
					   TRG.I_UsuarioMod = 1, 
					   TRG.D_FecMod = @D_FecProceso
		WHEN NOT MATCHED THEN
			INSERT (I_ObligacionAluDetID, I_ObligacionAluID, I_ConcPagID, I_Monto, B_Pagado, D_FecVencto, I_TipoDocumento, T_DescDocumento, 
					B_Habilitado, B_Eliminado, I_UsuarioCre, D_FecCre, B_Mora, B_Migrado, I_MigracionTablaID, I_MigracionRowID)
			VALUES (SRC.OblDetAluID, SRC.I_ObligacionAluID, SRC.Concepto, SRC.Monto, 0, SRC.Fch_venc, SRC.I_TipoDocumento, SRC.T_DescDocumento, 
					SRC.Habilitado, SRC.Eliminado, SRC.I_UsuarioCre, SRC.D_FecCre, SRC.Mora, 1, @I_MigracionTablaDetID, SRC.I_RowID)
		OUTPUT $action, SRC.I_RowID INTO @Tbl_outputDet;

		SET IDENTITY_INSERT BD_OCEF_CtasPorCobrar.dbo.TR_ObligacionAluDet OFF

		SELECT * FROM @Tbl_outputDet

		SET @I_Det_Insertados = (SELECT COUNT(*) FROM @Tbl_outputDet WHERE T_Action = 'INSERT')
		SET @I_Det_Actualizados = (SELECT COUNT(*) FROM @Tbl_outputDet WHERE T_Action = 'UPDATE')

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



IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_IU_MigrarPagoObligacionesCtasPorCobrar')
	DROP PROCEDURE [dbo].[USP_IU_MigrarPagoObligacionesCtasPorCobrar]
GO

CREATE PROCEDURE [dbo].[USP_IU_MigrarPagoObligacionesCtasPorCobrar]	
	@I_ProcedenciaID tinyint,
	@I_ProcesoID		int = NULL,
	@I_AnioIni			int = NULL,
	@I_AnioFin			int = NULL,
	@B_Resultado		bit output,
	@T_Message			nvarchar(4000) OUTPUT	
AS
--declare   @I_ProcedenciaID tinyint = 3,
--			@I_ProcesoID int = null, 
--			@T_AnioIni varchar(4) = null, 
--			@T_AnioFin varchar(4) = null, 
--			@B_Resultado  bit, 
--			@T_Message nvarchar(4000)
--exec USP_IU_MigrarPagoObligacionesCtasPorCobrar @I_ProcedenciaID, @I_ProcesoID, @I_AnioIni, @I_AnioFin, @B_Resultado output, @T_Message output
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
	DECLARE @I_CondicionPagoID int = 131
	DECLARE @I_TipoPagoID int = 133

	SET @I_AnioIni = (SELECT ISNULL(@I_AnioIni, 0))
	SET @I_AnioFin = (SELECT ISNULL(@I_AnioFin, 3000))

	CREATE TABLE #Tbl_output_pago_obl  
	(
		T_Action		varchar(20), 
		I_rowID		float,
	)

	CREATE TABLE #Tbl_output_pago_det  
	(
		T_Action		varchar(20), 
		I_rowID		float,
	)

	BEGIN TRANSACTION;
	BEGIN TRY 
		DECLARE @I_RowID  int
					
		--SELECT * INTO #temp_obl_migrados FROM TR_Ec_Obl 
		--WHERE	ISDATE(CAST(Fch_pago as varchar)) = 1 
		--		AND I_ProcedenciaID = @I_ProcedenciaID AND B_Migrable = 1
		--		AND (CAST(Ano AS int) BETWEEN @I_AnioIni AND @I_AnioFin)

		SELECT * INTO #temp_det_migrados FROM TR_Ec_Det 
		WHERE	ISDATE(CAST(Fch_pago as varchar)) = 1 
				AND I_ProcedenciaID = @I_ProcedenciaID AND B_Migrable = 1
				AND (CAST(Ano AS int) BETWEEN @I_AnioIni AND @I_AnioFin);
	
		SELECT * INTO #temp_pagos_interes_mora FROM	#temp_det_migrados --TR_Ec_Det 
		WHERE Concepto = 4788 AND (CAST(Ano AS int) BETWEEN @I_AnioIni AND @I_AnioFin);		

		SELECT * INTO #temp_pagos_banco FROM #temp_det_migrados --TR_Ec_Det 
		WHERE Concepto = 0 AND Concepto_f = 1 AND (CAST(Ano AS int) BETWEEN @I_AnioIni AND @I_AnioFin);
				
		SELECT * INTO #temp_pagos_conceptos FROM #temp_det_migrados  --TR_Ec_Det 
		WHERE Pagado = 1 AND Concepto_f = 0 AND Concepto NOT IN (0, 4788) AND (CAST(Ano AS int) BETWEEN @I_AnioIni AND @I_AnioFin);		

		--DROP TABLE #temp_obl_migrados 
		DROP TABLE #temp_det_migrados

		MERGE INTO BD_OCEF_CtasPorCobrar.dbo.TR_PagoBanco AS TRG
		USING (SELECT distinct CASE det.Cod_cajero WHEN 'BCP' THEN 2 ELSE 1 END AS I_EntidadFinanID, det.Nro_recibo, det.Cod_alu, det.Cod_rc, 
					  (a.T_ApePaterno + ' ' + a.T_ApeMaterno + ', ' + a.T_Nombre) AS T_NomDepositante, det.Fch_pago, det.Cantidad, det.Monto, 
					  det.Id_lug_pag, det.Eliminado, null AS T_Observacion, cast(det.Documento as varchar(max)) AS Documento, cdp.I_CtaDepositoID,  
					  det.Fch_ec, 131 AS I_CondicionPagoID, 133 AS I_TipoPagoID, ISNULL(mora.Monto, 0) AS Interes_mora, det.I_OblRowID
				FROM  #temp_pagos_banco det
					  INNER JOIN  TR_Alumnos a ON det.Cod_alu = a.C_CodAlu AND det.Cod_rc = a.C_RcCod
					  INNER JOIN  BD_OCEF_CtasPorCobrar.dbo.TI_CtaDepo_Proceso cdp ON det.cuota_pago = cdp.I_ProcesoID
					  LEFT JOIN  #temp_pagos_interes_mora mora ON det.Ano = mora.Ano AND det.P = mora.P AND det.Cuota_pago = mora.Cuota_pago 
																  AND det.Cod_Alu = mora.Cod_Alu AND det.Cod_rc = mora.Cod_rc
			  ) AS SRC
		ON
			TRG.C_CodOperacion = SRC.Nro_recibo
			AND TRG.C_CodDepositante = SRC.Cod_alu
			AND CAST(TRG.D_FecPago AS date) = CAST(SRC.Fch_pago AS date)
		WHEN MATCHED AND TRG.B_Migrado = 1 AND TRG.I_UsuarioMod IS NULL THEN
			UPDATE SET TRG.T_NomDepositante = SRC.T_NomDepositante,
					   TRG.C_Referencia = SRC.Nro_recibo,
					   TRG.D_FecPago = SRC.Fch_pago,
					   TRG.I_MontoPago = SRC.Monto,
					   TRG.T_LugarPago = SRC.Id_lug_pag				
		WHEN NOT MATCHED THEN
			INSERT (I_EntidadFinanID, C_CodOperacion, C_CodDepositante, T_NomDepositante, C_Referencia, D_FecPago, I_Cantidad, C_Moneda, I_MontoPago, T_LugarPago, B_Anulado, 
					I_UsuarioCre, D_FecCre, T_Observacion, T_InformacionAdicional, I_CondicionPagoID, I_TipoPagoID, I_CtaDepositoID, I_InteresMora, T_MotivoCoreccion, I_UsuarioMod, 
					D_FecMod, C_CodigoInterno, B_Migrado, I_MigracionTablaID, I_MigracionRowID)
			VALUES (SRC.I_EntidadFinanID, SRC.nro_recibo, SRC.cod_alu, SRC.T_NomDepositante, SRC.nro_recibo, SRC.fch_pago, SRC.cantidad, 'PEN', SRC.monto, SRC.id_lug_pag, SRC.eliminado, 
					NULL, IIF(ISDATE(CAST(SRC.Fch_ec as varchar)) = 0, NULL,SRC.Fch_ec), NULL, NULL, SRC.I_CondicionPagoID, SRC.I_TipoPagoID, SRC.I_CtaDepositoID, SRC.Interes_mora, NULL, NULL, 
					NULL, NULL, 1, @I_MigracionTablaDetID, SRC.I_OblRowID)
		OUTPUT	$ACTION, inserted.I_MigracionRowID INTO #Tbl_output_pago_obl;

		UPDATE OblCab
		   SET B_Pagado = 1
		FROM   BD_OCEF_CtasPorCobrar.dbo.TR_ObligacionAluCab OblCab
			   INNER JOIN #Tbl_output_pago_obl O_pagos ON OblCab.I_MigracionRowID = O_pagos.I_rowID


		MERGE INTO BD_OCEF_CtasPorCobrar.dbo.TRI_PagoProcesadoUnfv AS TRG
		USING (SELECT  distinct pagos.I_PagoBancoID, cdp.I_CtaDepositoID, NULL AS I_TasaUnfvID, det.Monto, 0 AS I_SaldoAPagar, 0 AS I_PagoDemas, det.pag_demas AS B_PagoDemas, 
						NULL AS N_NroSIAF, det.Eliminado, NULL AS D_FecCre, NULL AS I_UsuarioCre, NULL AS D_FecMod, NULL AS I_UsuarioMod, alu_det.I_ObligacionAluDetID, 
						1 AS B_Migrado, @I_MigracionTablaDetID AS I_MigracionTablaID, det.I_RowID AS I_MigracionRowID
				FROM   #temp_pagos_conceptos det
						INNER JOIN #temp_pagos_banco pagos_det ON det.I_OblRowID = pagos_det.I_OblRowID
						INNER JOIN BD_OCEF_CtasPorCobrar.dbo.TR_ObligacionAluDet alu_det ON det.I_RowID = alu_det.I_MigracionRowID
						INNER JOIN  BD_OCEF_CtasPorCobrar.dbo.TR_PagoBanco pagos ON pagos_det.I_RowID = pagos.I_MigracionRowID
						INNER JOIN  BD_OCEF_CtasPorCobrar.dbo.TI_CtaDepo_Proceso cdp ON det.cuota_pago = cdp.I_ProcesoID
				WHERE  det.B_Migrable = 1) AS SRC
		ON
			TRG.I_PagoBancoID = SRC.I_PagoBancoID
			AND TRG.I_ObligacionAluDetID = SRC.I_ObligacionAluDetID
		WHEN MATCHED AND TRG.B_Migrado = 1 AND TRG.I_UsuarioMod IS NULL THEN
			UPDATE SET TRG.B_Migrado = 1,
					   TRG.I_MontoPagado = SRC.Monto
		WHEN NOT MATCHED THEN
			INSERT (I_PagoBancoID, I_CtaDepositoID, I_TasaUnfvID, I_MontoPagado, I_SaldoAPagar, I_PagoDemas, B_PagoDemas, N_NroSIAF, B_Anulado,  D_FecCre, 
					I_UsuarioCre, D_FecMod, I_UsuarioMod, I_ObligacionAluDetID, B_Migrado, I_MigracionTablaID, I_MigracionRowID)
			VALUES (SRC.I_PagoBancoID, SRC.I_CtaDepositoID, SRC.I_TasaUnfvID, SRC.Monto, SRC.I_SaldoAPagar, SRC.I_PagoDemas, SRC.B_PagoDemas, SRC.N_NroSIAF, SRC.Eliminado,
					SRC.D_FecCre, SRC.I_UsuarioCre, SRC.D_FecMod, SRC.I_UsuarioMod,SRC.I_ObligacionAluDetID, SRC.B_Migrado, SRC.I_MigracionTablaID, SRC.I_MigracionRowID)
		OUTPUT	$ACTION, inserted.I_MigracionRowID INTO #Tbl_output_pago_det;


		UPDATE OblDet
		   SET B_Pagado = 1
		FROM   BD_OCEF_CtasPorCobrar.dbo.TR_ObligacionAluDet OblDet
			   INNER JOIN #Tbl_output_pago_det O_pagos ON OblDet.I_MigracionRowID = O_pagos.I_rowID

		SET @I_Obl_Insertados = (SELECT COUNT(*) FROM #Tbl_output_pago_obl)
		SET @I_Det_Insertados = (SELECT COUNT(*) FROM #Tbl_output_pago_det)

		SET @B_Resultado = 1
		SET @T_Message = 'Obligaciones migradas:' + CAST(@I_Obl_Insertados AS varchar(10))  + ' | Detalle de obligaciones migradas: ' + CAST(@I_Det_Insertados AS varchar(10))

		DROP TABLE #temp_pagos_interes_mora
		DROP TABLE #temp_pagos_banco
		DROP TABLE #temp_pagos_conceptos 

		COMMIT TRANSACTION;
	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION;
		SET @B_Resultado = 0
		SET @T_Message = ERROR_MESSAGE() + ' LINE: ' + CAST(ERROR_LINE() AS varchar(10)) 
	END CATCH
END
GO
