USE BD_OCEF_MigracionTP
GO

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_IU_CopiarTablaObligacionesPago')
	DROP PROCEDURE [dbo].[USP_IU_CopiarTablaObligacionesPago]
GO

CREATE PROCEDURE USP_IU_CopiarTablaObligacionesPago	
	@I_ProcedenciaID tinyint,
	@T_SchemaDB	  varchar(20),
	@B_Resultado  bit output,
	@T_Message	  nvarchar(4000) OUTPUT	
AS
--declare @I_ProcedenciaID	tinyint = 2,
--		@T_SchemaDB varchar(20) = 'eupg',
--		@B_Resultado  bit,
--		@T_Message	  nvarchar(4000)
--exec USP_IU_CopiarTablaObligacionesPago @I_ProcedenciaID, @T_SchemaDB, @B_Resultado output, @T_Message output
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

		SET @T_SQL = '  DECLARE @D_FecProceso datetime = GETDATE()			 
						UPDATE	TR_Ec_Obl
						SET		TR_Ec_Obl.B_Removido		= 1, 
								TR_Ec_Obl.D_FecRemovido	= @D_FecProceso,
								TR_Ec_Obl.B_Migrable		= 0
						WHERE	NOT EXISTS (SELECT * FROM BD_OCEF_TemporalPagos.' + @T_SchemaDB + '.ec_obl SRC  
											WHERE TR_Ec_Obl.ANO = SRC.ANO AND TR_Ec_Obl.P = SRC.P AND TR_Ec_Obl.COD_ALU = SRC.COD_ALU 
											AND TR_Ec_Obl.COD_RC = SRC.COD_RC AND TR_Ec_Obl.CUOTA_PAGO = SRC.CUOTA_PAGO 
											AND ISNULL(TR_Ec_Obl.FCH_VENC, ''19000101'') = ISNULL(SRC.FCH_VENC, ''19000101'')
											AND ISNULL(TR_Ec_Obl.TIPO_OBLIG, 0) = ISNULL(SRC.TIPO_OBLIG, 0)
											AND TR_Ec_Obl.MONTO = SRC.MONTO AND TR_Ec_Obl.PAGADO = SRC.PAGADO)
								AND TR_Ec_Obl.I_ProcedenciaID = '+ CAST(@I_ProcedenciaID as varchar(3))

		PRINT @T_SQL
		EXEC sp_executesql @T_SQL

		SET @I_Removidos = @@ROWCOUNT

		SET @T_SQL = '	DECLARE @D_FecProceso datetime = GETDATE()
			
						INSERT TR_Ec_Obl(ANO, P, I_Periodo, COD_ALU, COD_RC, CUOTA_PAGO, TIPO_OBLIG, FCH_VENC, MONTO, PAGADO, D_FecCarga, B_Migrable, B_Migrado, I_ProcedenciaID, B_Obligacion)
						SELECT	ANO, P, I_OpcionID as I_periodo, COD_ALU, COD_RC, CUOTA_PAGO, TIPO_OBLIG, FCH_VENC, MONTO, PAGADO, @D_FecProceso, 1, 0, '+ CAST(@I_ProcedenciaID as varchar(3)) + ', 1
						FROM	BD_OCEF_TemporalPagos.' + @T_SchemaDB + '.ec_obl OBL
								LEFT JOIN BD_OCEF_CtasPorCobrar.dbo.TC_CatalogoOpcion cop_per ON OBL.P = cop_per.T_OpcionCod AND cop_per.I_ParametroID = 5
						WHERE	NOT EXISTS (SELECT * FROM TR_Ec_Obl TRG 
											WHERE TRG.ANO = OBL.ANO AND TRG.P = OBL.P AND TRG.COD_ALU = OBL.COD_ALU AND TRG.COD_RC = OBL.COD_RC 
											AND TRG.CUOTA_PAGO = OBL.CUOTA_PAGO AND ISNULL(TRG.FCH_VENC, ''19000101'') = ISNULL(OBL.FCH_VENC, ''19000101'')
											AND ISNULL(TRG.TIPO_OBLIG, 0) = ISNULL(OBL.TIPO_OBLIG, 0) AND TRG.MONTO = OBL.MONTO AND TRG.PAGADO = OBL.PAGADO
											AND TRG.I_ProcedenciaID = '+ CAST(@I_ProcedenciaID as varchar(3)) + ')'

		PRINT @T_SQL
		EXEC sp_executesql @T_SQL

		SET @I_Insertados = @@ROWCOUNT
		
		SET @T_SQL = '(SELECT * FROM BD_OCEF_TemporalPagos.' + @T_SchemaDB + '.ec_obl)'					
		PRINT @T_SQL
		EXEC sp_executesql @T_SQL

		SET @I_EcObl = @@ROWCOUNT

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
	@I_ProcedenciaID tinyint,
	@T_SchemaDB	  varchar(20),
	@B_Resultado  bit output,
	@T_Message	  nvarchar(4000) OUTPUT	
AS
--declare @I_ProcedenciaID	tinyint = 3,
--		@T_SchemaDB varchar(20) = 'euded',
--		@B_Resultado  bit,
--		@T_Message	  nvarchar(4000)
--exec USP_IU_CopiarTablaDetalleObligacionesPago @I_ProcedenciaID, @T_SchemaDB, @B_Resultado output, @T_Message output
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
	
		--DELETE TR_Ec_Det
			
		SET @T_SQL = '	DECLARE @D_FecProceso datetime = GETDATE()			 
						MERGE TR_Ec_Det AS TRG
						USING (SELECT * FROM BD_OCEF_TemporalPagos.' + @T_SchemaDB + '.ec_det) AS SRC
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
									NRO_EC, FCH_EC, ELIMINADO, PAG_DEMAS, COD_CAJERO, TIPO_PAGO, NO_BANCO, COD_DEP, @D_FecProceso, 1, 0, NULL, ' + CAST(@I_ProcedenciaID as varchar(3)) + ', 1)
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
								deleted.B_Removido INTO #Tbl_output;
					'
		print @T_SQL
		Exec sp_executesql @T_SQL

		SET @T_SQL = 'SELECT cuota_pago, concepto, p, ano, fch_venc, cod_alu, cod_rc, monto, pagado FROM BD_OCEF_TemporalPagos.' + @T_SchemaDB + '.ec_det'
		print @T_SQL
		Exec sp_executesql @T_SQL

		SET @I_EcDet = @@ROWCOUNT
		SET @I_Insertados = (SELECT COUNT(*) FROM #Tbl_output WHERE accion = 'INSERT')
		SET @I_Removidos = (SELECT COUNT(*) FROM #Tbl_output WHERE accion = 'UPDATE' AND B_Removido = 1)

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
--exec USP_U_ValidarA?oEnCabeceraObligacion @B_Resultado output, @T_Message output
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
	@I_AnioIni			int = NULL,
	@I_AnioFin			int = NULL,
	@B_Resultado		bit output,
	@T_Message			nvarchar(4000) OUTPUT	
AS
--declare   @I_ProcedenciaID tinyint = 3
--			@I_ProcesoID int = null, 
--			@I_AnioIni int = null, 
--			@I_AnioFin int = null, 
--			@B_Resultado  bit, 
--			@T_Message nvarchar(4000)
--exec USP_IU_MigrarObligacionesCtasPorCobrar @I_ProcedenciaID, @I_ProcesoID, @I_AnioIni, @I_AnioFin, @B_Resultado output, @T_Message output
--select @B_Resultado as resultado, @T_Message as mensaje
BEGIN
	DECLARE @I_Removidos int = 0
	DECLARE @I_Actualizados int = 0
	DECLARE @I_Insertados int = 0
	DECLARE @D_FecProceso datetime = GETDATE()
	DECLARE @I_I_MigracionTablaID tinyint = 5
	DECLARE @T_Moneda varchar(3) = 'PEN'

	BEGIN TRANSACTION;
	BEGIN TRY 

		DECLARE CUR_OBL CURSOR
		FOR
		SELECT obl.*, mat.I_MatAluID
		FROM TR_Ec_Obl obl
			 INNER JOIN BD_OCEF_CtasPorCobrar.dbo.TC_MatriculaAlumno mat ON obl.cod_alu = mat.C_CodAlu and obl.cod_rc = mat.C_CodRc and obl.ano = CAST(mat.I_Anio as varchar(4)) and obl.I_Periodo = mat.I_Periodo
		WHERE I_ProcedenciaID = @I_ProcedenciaID
			  AND (Cuota_pago = @I_ProcesoID OR @I_ProcesoID IS NULL)
			  AND (Ano BETWEEN @I_AnioIni AND @I_AnioFin)
			  AND B_Migrable = 1;

		INSERT INTO BD_OCEF_CtasPorCobrar.dbo.TR_ObligacionAluCab (I_ProcesoID, I_MatAluID, C_Moneda, I_MontoOblig, D_FecVencto, B_Pagado, B_Habilitado, B_Eliminado, I_UsuarioCre, D_FecCre, B_Migrado, I_MigracionTablaID, I_MigracionRowID)
		SELECT obl.Cuota_pago, mat.I_MatAluID, @T_Moneda, obl.Monto, obl.Fch_venc, 0 AS Pagado, 1 AS Habilitado, 0 AS Eliminado, 1, @D_FecProceso, 1 AS Migrado, @I_I_MigracionTablaID, obl.I_RowID 
		FROM TR_Ec_Obl obl
			 INNER JOIN BD_OCEF_CtasPorCobrar.dbo.TC_MatriculaAlumno mat ON obl.cod_alu = mat.C_CodAlu and obl.cod_rc = mat.C_CodRc and obl.ano = CAST(mat.I_Anio as varchar(4)) and obl.I_Periodo = mat.I_Periodo
		WHERE I_ProcedenciaID = @I_ProcedenciaID
			  AND (Cuota_pago = @I_ProcesoID OR @I_ProcesoID IS NULL)
			  AND (Ano BETWEEN @I_AnioIni AND @I_AnioFin)
			  AND B_Migrable = 1;

		INSERT INTO BD_OCEF_CtasPorCobrar.dbo.TR_ObligacionAluDet (I_ObligacionAluID, I_ConcPagID, I_Monto, B_Pagado, D_FecVencto, I_TipoDocumento, T_DescDocumento, B_Habilitado, B_Eliminado, I_UsuarioCre, D_FecCre, B_Mora, B_Migrado, I_MigracionTablaID, I_MigracionRowID)
		SELECT cab.I_ObligacionAluID, det.Concepto, det.Monto, B_Pagado, D_FecVencto, CASE WHEN CAST(det.Documento as varchar(max)) IS NULL THEN NULL ELSE 138 END AS I_TipoDocumento, CAST(det.Documento as varchar(max)) AS T_DescDocumento, 1 AS Habilitado, det.Eliminado, 1, @D_FecProceso, 0 AS Mora, 1 AS Migrado, 4 AS TablaID, det.I_RowID
		FROM TR_Ec_Det det
			 INNER JOIN BD_OCEF_CtasPorCobrar.dbo.TR_ObligacionAluCab cab ON cab.I_MigracionRowID = det.I_OblRowID
		WHERE det.Concepto_f = 0
			
			  AND det.B_Migrable = 1

		OPEN CUR_OBL
		FETCH NEXT

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
	@I_AnioIni			int = NULL,
	@I_AnioFin			int = NULL,
	@B_Resultado		bit output,
	@T_Message			nvarchar(4000) OUTPUT	
AS
--declare   @I_ProcedenciaID tinyint = 3
--			@I_ProcesoID int = null, 
--			@I_AnioIni int = null, 
--			@I_AnioFin int = null, 
--			@B_Resultado  bit, 
--			@T_Message nvarchar(4000)
--exec USP_IU_MigrarDetalleObligacionCtasPorCobrar @I_ProcedenciaID, @I_ProcesoID, @I_AnioIni, @I_AnioFin, @B_Resultado output, @T_Message output
--select @B_Resultado as resultado, @T_Message as mensaje
BEGIN
	DECLARE @I_Removidos int = 0
	DECLARE @I_Actualizados int = 0
	DECLARE @I_Insertados int = 0
	DECLARE @D_FecProceso datetime = GETDATE()

	BEGIN TRANSACTION;
	BEGIN TRY 
		select * from TR_Ec_Det

		COMMIT TRANSACTION;
	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION;
		SET @B_Resultado = 0
		SET @T_Message = ERROR_MESSAGE() + ' LINE: ' + CAST(ERROR_LINE() AS varchar(10)) 
	END CATCH
END
GO
