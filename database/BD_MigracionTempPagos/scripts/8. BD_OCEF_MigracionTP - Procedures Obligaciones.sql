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
--declare @I_ProcedenciaID	tinyint = 3,
--		@T_SchemaDB   varchar(20) = 'euded',
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

		SET @T_SQL = '  DELETE TR_Ec_Det
						WHERE I_ProcedenciaID = '+ CAST(@I_ProcedenciaID as varchar(3)) + '
							  AND EXISTS (SELECT * FROM TR_Ec_Obl WHERE TR_Ec_Obl.I_RowID = I_OblRowID'
						


		IF (ISNULL(@T_AnioIni, '') <> '' AND ISNULL(@T_AnioFin, '') <> '')
		BEGIN
			SET @T_SQL = @T_SQL + ' AND (TR_Ec_Obl.ANO BETWEEN ''' + @T_AnioIni + ''' AND ''' + @T_AnioFin + ''') '
		END

		SET @T_SQL = @T_SQL + ' AND TR_Ec_Obl.B_Migrado = 0 
							    AND TR_Ec_Obl.I_ProcedenciaID = '+ CAST(@I_ProcedenciaID as varchar(3)) + ');'

		--PRINT @T_SQL
		EXEC sp_executesql @T_SQL
		SET @I_Removidos = @@ROWCOUNT

		
		SET @T_SQL = 'DELETE TR_Ec_Obl
					  WHERE I_ProcedenciaID = '+ CAST(@I_ProcedenciaID as varchar(3)) + '
					 '

		IF (ISNULL(@T_AnioIni, '') <> '' AND ISNULL(@T_AnioFin, '') <> '')
		BEGIN
			SET @T_SQL = @T_SQL + ' AND (TR_Ec_Obl.ANO BETWEEN ''' + @T_AnioIni + ''' AND ''' + @T_AnioFin + ''')' 
		END

		SET @T_SQL = @T_SQL + ' AND TR_Ec_Obl.B_Migrado = 0;' 

		--PRINT @T_SQL
		EXEC sp_executesql @T_SQL
		SET @I_Removidos = @I_Removidos + @@ROWCOUNT


		DELETE FROM TI_ObservacionRegistroTabla 
		WHERE			
				I_TablaID = 4 
				AND I_ProcedenciaID = @I_ProcedenciaID
				AND NOT EXISTS (SELECT I_RowID FROM TR_Ec_Det WHERE I_RowID = I_FilaTablaID);


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

		IF (ISNULL(@T_AnioIni, '') <> '' AND ISNULL(@T_AnioFin, '') <> '')
		BEGIN
			SET @T_SQL = @T_SQL + 'AND (OBL.ANO BETWEEN ''' + @T_AnioIni + ''' AND ''' + @T_AnioFin + ''');' 
		END

		--PRINT @T_SQL
		EXEC sp_executesql @T_SQL
		SET @I_Insertados = @@ROWCOUNT

		
		SET @T_SQL = '(SELECT * FROM BD_OCEF_TemporalPagos.' + @T_SchemaDB + '.ec_obl'

		IF (ISNULL(@T_AnioIni, '') <> '' AND ISNULL(@T_AnioFin, '') <> '')
		BEGIN
			SET @T_SQL = @T_SQL + ' WHERE ANO BETWEEN ''' + @T_AnioIni + ''' AND ''' + @T_AnioFin + ''''
		END
		
		SET @T_SQL = @T_SQL + ')'

		PRINT @T_SQL
		EXEC sp_executesql @T_SQL
		SET @I_EcObl = @@ROWCOUNT


		IF(@I_Removidos <> 0)
		BEGIN
			SET @I_Actualizados = @I_Insertados
		END
				
		DELETE FROM TI_ObservacionRegistroTabla 
		WHERE	I_TablaID = 5  
				AND I_ProcedenciaID = @I_ProcedenciaID
				AND NOT EXISTS (SELECT I_RowID FROM TR_Ec_Obl WHERE I_RowID = I_FilaTablaID);


		SELECT @I_EcObl AS tot_obligaciones, @I_Insertados AS cant_inserted, @I_Actualizados AS cant_updated, @I_Removidos as cant_removed, @D_FecProceso as fec_proceso;
		

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


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_U_InicializarEstadoValidacionObligacionPago')
	DROP PROCEDURE [dbo].[USP_U_InicializarEstadoValidacionObligacionPago]
GO

CREATE PROCEDURE USP_U_InicializarEstadoValidacionObligacionPago	
	@I_ProcedenciaID tinyint,
	@I_RowID	  int = NULL,
	@T_AnioIni	  varchar(4) = NULL,
	@T_AnioFin	  varchar(4) = NULL,
	@B_Resultado  bit output,
	@T_Message	  nvarchar(4000) OUTPUT	
AS
--declare	@B_Resultado  bit,
--			@I_ProcedenciaID	tinyint = 3,
--			@I_RowID	  int = NULL,
--			@T_AnioIni	  varchar(4) = NULL,
--			@T_AnioFin	  varchar(4) = NULL,
--			@T_Message	  nvarchar(4000)
--exec USP_U_InicializarEstadoValidacionObligacionPago @I_ProcedenciaID, @I_RowID, @T_AnioIni, @T_AnioFin, @B_Resultado output, @T_Message output
--select @B_Resultado as resultado, @T_Message as mensaje
BEGIN
	SET @T_AnioIni = (SELECT ISNULL(@T_AnioIni, '0'))
	SET @T_AnioFin = (SELECT ISNULL(@T_AnioFin, '3000'))

	BEGIN TRANSACTION
	BEGIN TRY 
		UPDATE	TR_Ec_Obl 
		   SET	B_Actualizado = 0, 
				B_Migrable = 1, 
				D_FecMigrado = NULL, 
				B_Migrado = 0
		 WHERE I_ProcedenciaID = @I_ProcedenciaID
			   AND I_RowID = IIF(@I_RowID IS NULL, I_RowID, @I_RowID) 
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


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_U_ValidarExisteAlumnoCabeceraObligacion')
	DROP PROCEDURE [dbo].[USP_U_ValidarExisteAlumnoCabeceraObligacion]
GO

CREATE PROCEDURE [dbo].[USP_U_ValidarExisteAlumnoCabeceraObligacion]	
	@I_ProcedenciaID tinyint,
	@I_RowID	  int = NULL,
	@I_AnioIni	  int = NULL,
	@I_AnioFin	  int = NULL,
	@B_Resultado  bit output,
	@T_Message	  nvarchar(4000) OUTPUT	
AS
--declare @I_ProcedenciaID	tinyint = 3,
--		@I_RowID	  int = NULL,
--		@I_AnioIni	  int = null,
--		@I_AnioFin	  int = null,
--		@B_Resultado  bit,
--		@T_Message	  nvarchar(4000)
--exec USP_U_ValidarExisteAlumnoCabeceraObligacion @I_ProcedenciaID, @I_RowID, @I_AnioIni, @I_AnioFin, @B_Resultado output, @T_Message output
--select @B_Resultado as resultado, @T_Message as mensaje
BEGIN
	DECLARE @I_Observados int = 0
	DECLARE @D_FecProceso datetime = GETDATE() 
	DECLARE @I_ObservID int = 24
	DECLARE @I_TablaID int = 5

	SET @I_AnioIni = (SELECT ISNULL(@I_AnioIni, 0))
	SET @I_AnioFin = (SELECT ISNULL(@I_AnioFin, 3000))

	BEGIN TRANSACTION
	BEGIN TRY 
		SELECT * 
		INTO #Numeric_Year_Ec_Obl
		FROM TR_Ec_Obl
		WHERE ISNUMERIC(ANO) = 1
			  AND I_ProcedenciaID = @I_ProcedenciaID
			  AND I_RowID = IIF(@I_RowID IS NULL, I_RowID, @I_RowID)

		UPDATE	ec_obl
		SET		B_Migrable = 0,
				D_FecEvalua = @D_FecProceso
		FROM	TR_Ec_Obl ec_obl
				INNER JOIN #Numeric_Year_Ec_Obl num_ec_obl ON ec_obl.I_RowID = num_ec_obl.I_RowID
		WHERE	NOT EXISTS (SELECT * FROM TR_Alumnos b WHERE ec_obl.COD_ALU = C_CodAlu and ec_obl.COD_RC = C_RcCod)
				AND CAST(num_ec_obl.Ano AS int) BETWEEN @I_AnioIni AND @I_AnioFin
			    AND ec_obl.I_ProcedenciaID = @I_ProcedenciaID
				AND (num_ec_obl.Ano BETWEEN @I_AnioIni AND @I_AnioFin)

					
		MERGE TI_ObservacionRegistroTabla AS TRG
		USING 	(SELECT	@I_ObservID AS I_ObservID, @I_TablaID AS I_TablaID, ec_obl.I_RowID AS I_FilaTablaID, @D_FecProceso AS D_FecRegistro 
				 FROM	TR_Ec_Obl ec_obl
						INNER JOIN #Numeric_Year_Ec_Obl num_ec_obl ON ec_obl.I_RowID = num_ec_obl.I_RowID
				 WHERE	NOT EXISTS (SELECT * FROM TR_Alumnos b WHERE ec_obl.COD_ALU = C_CodAlu and ec_obl.COD_RC = C_RcCod)
						AND CAST(num_ec_obl.Ano AS int) BETWEEN @I_AnioIni AND @I_AnioFin
						AND ec_obl.I_ProcedenciaID = @I_ProcedenciaID
						AND (num_ec_obl.Ano BETWEEN @I_AnioIni AND @I_AnioFin)) AS SRC
		ON TRG.I_ObservID = SRC.I_ObservID AND TRG.I_TablaID = SRC.I_TablaID AND TRG.I_FilaTablaID = SRC.I_FilaTablaID
		WHEN MATCHED THEN
			UPDATE SET D_FecRegistro = SRC.D_FecRegistro
		WHEN NOT MATCHED BY TARGET THEN
			INSERT (I_ObservID, I_TablaID, I_FilaTablaID, D_FecRegistro, I_ProcedenciaID)
			VALUES (SRC.I_ObservID, SRC.I_TablaID, SRC.I_FilaTablaID, SRC.D_FecRegistro, @I_ProcedenciaID)
		WHEN NOT MATCHED BY SOURCE AND TRG.I_ObservID = @I_ObservID AND TRG.I_ProcedenciaID = @I_ProcedenciaID 
								   AND TRG.I_TablaID = @I_TablaID AND TRG.I_FilaTablaID = @I_RowID THEN
			DELETE;

		SET @I_Observados = (SELECT COUNT(*) FROM #Numeric_Year_Ec_Obl OBL
												  INNER JOIN (SELECT * FROM TI_ObservacionRegistroTabla 
															  WHERE I_ObservID = @I_ObservID AND I_TablaID = @I_TablaID
																	AND I_FilaTablaID = IIF(@I_RowID IS NULL, I_FilaTablaID, @I_RowID)) OBS 
															  ON OBS.I_FilaTablaID = OBL.I_RowID)

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

	IF OBJECT_ID ('#Numeric_Year_Ec_Obl') IS NOT NULL
	BEGIN 
		DROP TABLE #Numeric_Year_Ec_Obl
	END 
END
GO


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_U_ValidarAnioEnCabeceraObligacion')
	DROP PROCEDURE [dbo].[USP_U_ValidarAnioEnCabeceraObligacion]
GO

CREATE PROCEDURE [dbo].[USP_U_ValidarAnioEnCabeceraObligacion]	
	@I_ProcedenciaID tinyint,
	@I_RowID	  int = NULL,
	@B_Resultado  bit output,
	@T_Message	  nvarchar(4000) OUTPUT	
AS
--declare @I_ProcedenciaID	tinyint = 3, 
--		@I_RowID	  int = NULL,
--		@B_Resultado  bit,
--		@T_Message	  nvarchar(4000)
--exec USP_U_ValidarAnioEnCabeceraObligacion @I_ProcedenciaID, @I_RowID, @B_Resultado output, @T_Message output
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
				AND I_ProcedenciaID = @I_ProcedenciaID
				AND I_RowID = IIF(@I_RowID IS NULL, I_RowID, @I_RowID)
				
		MERGE TI_ObservacionRegistroTabla AS TRG
		USING 	(SELECT	@I_ObservID AS I_ObservID, @I_TablaID AS I_TablaID, I_RowID AS I_FilaTablaID, @D_FecProceso AS D_FecRegistro 
				 FROM	TR_Ec_Obl 
				 WHERE	ISNUMERIC(ANO) = 0 
						AND I_ProcedenciaID = @I_ProcedenciaID
						AND I_RowID = IIF(@I_RowID IS NULL, I_RowID, @I_RowID)
				) AS SRC
		ON TRG.I_ObservID = SRC.I_ObservID AND TRG.I_TablaID = SRC.I_TablaID AND TRG.I_FilaTablaID = SRC.I_FilaTablaID
		WHEN MATCHED THEN
			UPDATE SET D_FecRegistro = SRC.D_FecRegistro
		WHEN NOT MATCHED BY TARGET THEN
			INSERT (I_ObservID, I_TablaID, I_FilaTablaID, D_FecRegistro, I_ProcedenciaID)
			VALUES (SRC.I_ObservID, SRC.I_TablaID, SRC.I_FilaTablaID, SRC.D_FecRegistro, @I_ProcedenciaID)
		WHEN NOT MATCHED BY SOURCE AND TRG.I_ObservID = @I_ObservID AND TRG.I_ProcedenciaID = @I_ProcedenciaID 
								   AND TRG.I_TablaID = @I_TablaID AND TRG.I_FilaTablaID = @I_RowID  THEN
			DELETE;

		SET @I_Observados = (SELECT COUNT(*) FROM TR_Ec_Obl OBL
												  INNER JOIN (SELECT * FROM TI_ObservacionRegistroTabla 
															  WHERE I_ObservID = @I_ObservID AND I_TablaID = @I_TablaID
																	AND I_FilaTablaID = IIF(@I_RowID IS NULL, I_FilaTablaID, @I_RowID)) OBS 
															  ON OBS.I_FilaTablaID = OBL.I_RowID)

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
	@I_ProcedenciaID tinyint,
	@T_AnioIni	  varchar(4) = NULL,
	@T_AnioFin	  varchar(4) = NULL,
	@I_RowID	  int = NULL,
	@B_Resultado  bit output,
	@T_Message	  nvarchar(4000) OUTPUT	
AS
--declare	@I_ProcedenciaID	tinyint = 3, 
--			@T_AnioIni	  varchar(4) = NULL,
--			@T_AnioFin	  varchar(4) = NULL,
--			@I_RowID	  int = NULL,
--			@B_Resultado  bit,
--			@T_Message	  nvarchar(4000)
--exec USP_U_ValidarPeriodoEnCabeceraObligacion @I_ProcedenciaID, @T_AnioIni, @T_AnioFin, @I_RowID, @B_Resultado output, @T_Message output
--select @B_Resultado as resultado, @T_Message as mensaje
BEGIN
	DECLARE @I_Observados int = 0
	DECLARE @I_TablaID int = 5

	SET @T_AnioIni = (SELECT ISNULL(@T_AnioIni, '0'))
	SET @T_AnioFin = (SELECT ISNULL(@T_AnioFin, '3000'))

	BEGIN TRANSACTION
	BEGIN TRY 
		DECLARE @D_FecProceso datetime = GETDATE() 
		DECLARE @I_ObservID int = 27

		UPDATE	TR_Ec_Obl
		SET		B_Migrable = 0,
				D_FecEvalua = @D_FecProceso
		WHERE	I_Periodo IS NULL OR P = ''
				AND I_ProcedenciaID = @I_ProcedenciaID
				AND I_RowID = IIF(@I_RowID IS NULL, I_RowID, @I_RowID) 
			    AND (Ano BETWEEN @T_AnioIni AND @T_AnioFin)
				
		MERGE TI_ObservacionRegistroTabla AS TRG
		USING 	(SELECT	@I_ObservID AS I_ObservID, @I_TablaID AS I_TablaID, I_RowID AS I_FilaTablaID, @D_FecProceso AS D_FecRegistro, I_ProcedenciaID
				   FROM TR_Ec_Obl
				  WHERE	I_Periodo IS NULL
				  		AND I_ProcedenciaID = @I_ProcedenciaID
						AND I_RowID = IIF(@I_RowID IS NULL, I_RowID, @I_RowID) 
						AND (Ano BETWEEN @T_AnioIni AND @T_AnioFin)
				) AS SRC
		ON TRG.I_ObservID = SRC.I_ObservID AND TRG.I_TablaID = SRC.I_TablaID AND TRG.I_FilaTablaID = SRC.I_FilaTablaID
		WHEN MATCHED AND SRC.I_ProcedenciaID = @I_ProcedenciaID THEN
			UPDATE SET D_FecRegistro = SRC.D_FecRegistro
		WHEN NOT MATCHED BY TARGET AND SRC.I_ProcedenciaID = @I_ProcedenciaID THEN
			INSERT (I_ObservID, I_TablaID, I_FilaTablaID, D_FecRegistro, I_ProcedenciaID)
			VALUES (SRC.I_ObservID, SRC.I_TablaID, SRC.I_FilaTablaID, SRC.D_FecRegistro, @I_ProcedenciaID)
		WHEN NOT MATCHED BY SOURCE AND TRG.I_ObservID = @I_ObservID AND TRG.I_ProcedenciaID = @I_ProcedenciaID 
								   AND TRG.I_TablaID = @I_TablaID AND TRG.I_FilaTablaID = @I_RowID  THEN
			DELETE;

		SET @I_Observados = (SELECT COUNT(*) FROM TI_ObservacionRegistroTabla 
							 WHERE I_ObservID = @I_ObservID AND I_TablaID = @I_TablaID AND I_ProcedenciaID = @I_ProcedenciaID
								   AND I_FilaTablaID = IIF(@I_RowID IS NULL, I_FilaTablaID, @I_RowID))

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
	@I_RowID	  int = NULL,
	@T_AnioIni	  varchar(4) = NULL,
	@T_AnioFin	  varchar(4) = NULL,
	@B_Resultado  bit output,
	@T_Message	  nvarchar(4000) OUTPUT	
AS
--declare	@I_ProcedenciaID	tinyint = 3, 
--			@I_RowID	  int = NULL,
--			@T_AnioIni	  varchar(4) = NULL,
--			@T_AnioFin	  varchar(4) = NULL,
--			@B_Resultado  bit,
--			@T_Message    nvarchar(4000)
--exec USP_U_ValidarFechaVencimientoCuotaObligacion @I_ProcedenciaID, @T_AnioIni, @T_AnioFin, @B_Resultado output, @T_Message output
--select @B_Resultado as resultado, @T_Message as mensaje
BEGIN
	DECLARE @I_Observados int = 0
	DECLARE @D_FecProceso datetime = GETDATE() 
	DECLARE @I_ObservID int = 28
	DECLARE @I_TablaID int = 5

	SET @T_AnioIni = (SELECT ISNULL(@T_AnioIni, '0'))
	SET @T_AnioFin = (SELECT ISNULL(@T_AnioFin, '3000'))

	BEGIN TRANSACTION
	BEGIN TRY

		UPDATE	TRG_1
		SET		B_Migrable = 0,
				D_FecEvalua = @D_FecProceso
		FROM	TR_Ec_Obl TRG_1
				INNER JOIN (SELECT ANO, P, COD_ALU, COD_RC, CUOTA_PAGO, FCH_VENC, TIPO_OBLIG, MONTO
							FROM  TR_Ec_Obl
							WHERE I_ProcedenciaID = @I_ProcedenciaID
								  AND I_RowID = IIF(@I_RowID IS NULL, I_RowID, @I_RowID)
								  AND (Ano BETWEEN @T_AnioIni AND @T_AnioFin)
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
									  AND I_RowID = IIF(@I_RowID IS NULL, I_RowID, @I_RowID)
									  AND (Ano BETWEEN @T_AnioIni AND @T_AnioFin)
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
		WHEN NOT MATCHED BY SOURCE AND TRG.I_ObservID = @I_ObservID AND TRG.I_ProcedenciaID = @I_ProcedenciaID 
								   AND TRG.I_TablaID = @I_TablaID AND TRG.I_FilaTablaID = @I_RowID THEN
			DELETE;

		SET @I_Observados = (SELECT COUNT(*) FROM TI_ObservacionRegistroTabla 
							  WHERE I_ObservID = @I_ObservID AND I_TablaID = @I_TablaID AND I_ProcedenciaID = @I_ProcedenciaID
									AND I_FilaTablaID = IIF(@I_RowID IS NULL, I_FilaTablaID, @I_RowID))

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
	@I_RowID	  int = NULL,
	@T_AnioIni	  varchar(4) = NULL,
	@T_AnioFin	  varchar(4) = NULL,
	@B_Resultado  bit output,
	@T_Message	  nvarchar(4000) OUTPUT	
AS
--declare	@I_ProcedenciaID	tinyint = 3, 
--			@I_RowID	  int = NULL,
--			@T_AnioIni	  varchar(4) = NULL,
--			@T_AnioFin	  varchar(4) = NULL,
--			@B_Resultado  bit,
--			@T_Message    nvarchar(4000)
--exec USP_U_ValidarObligacionCuotaPagoMigrada @I_ProcedenciaID, @B_Resultado output, @T_Message output
--select @B_Resultado as resultado, @T_Message as mensaje
BEGIN
	DECLARE @I_Observados int = 0
	DECLARE @D_FecProceso datetime = GETDATE() 
	DECLARE @I_ObservID int = 32
	DECLARE @I_TablaID int = 5

	SET @T_AnioIni = (SELECT ISNULL(@T_AnioIni, '0'))
	SET @T_AnioFin = (SELECT ISNULL(@T_AnioFin, '3000'))

	BEGIN TRANSACTION
	BEGIN TRY

		UPDATE	TR_Ec_Obl
		SET		B_Migrable = 0,
				D_FecEvalua = @D_FecProceso
		WHERE	Cuota_pago IN (SELECT Cuota_pago FROM TR_Cp_Des WHERE B_Migrado = 0 AND I_ProcedenciaID = @I_ProcedenciaID)
				AND I_ProcedenciaID = @I_ProcedenciaID
				AND I_RowID = IIF(@I_RowID IS NULL, I_RowID, @I_RowID)
				AND (Ano BETWEEN @T_AnioIni AND @T_AnioFin)
								  
		MERGE TI_ObservacionRegistroTabla AS TRG
		USING 	(SELECT	@I_ObservID AS I_ObservID, @I_TablaID AS I_TablaID, I_RowID AS I_FilaTablaID, @D_FecProceso AS D_FecRegistro 
				 FROM TR_Ec_Obl
				 WHERE	Cuota_pago IN (SELECT Cuota_pago FROM TR_Cp_Des WHERE B_Migrado = 0 AND I_ProcedenciaID = @I_ProcedenciaID)
						AND I_ProcedenciaID = @I_ProcedenciaID 
						AND I_RowID = IIF(@I_RowID IS NULL, I_RowID, @I_RowID)
						AND (Ano BETWEEN @T_AnioIni AND @T_AnioFin)
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
							  WHERE I_ObservID = @I_ObservID AND I_TablaID = @I_TablaID AND I_ProcedenciaID = @I_ProcedenciaID
									AND I_FilaTablaID = IIF(@I_RowID IS NULL, I_FilaTablaID, @I_RowID))

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
	@I_RowID	  int = NULL,
	@T_AnioIni	  varchar(4) = NULL,
	@T_AnioFin	  varchar(4) = NULL,
	@B_Resultado  bit output,
	@T_Message	  nvarchar(4000) OUTPUT	
AS
--declare	@I_ProcedenciaID	tinyint = 3, 
--			@I_RowID	  int = NULL,
--			@T_AnioIni	  varchar(4) = NULL,
--			@T_AnioFin	  varchar(4) = NULL,
--			@B_Resultado  bit,
--			@T_Message    nvarchar(4000)
--exec USP_U_ValidarProcedenciaObligacionCuotaPago @I_ProcedenciaID, @I_RowID, @T_AnioIni, @T_AnioFin, @B_Resultado output, @T_Message output
--select @B_Resultado as resultado, @T_Message as mensaje
BEGIN
	DECLARE @I_Observados int = 0
	DECLARE @D_FecProceso datetime = GETDATE() 
	DECLARE @I_ObservID int = 34
	DECLARE @I_TablaID int = 5

	SET @T_AnioIni = (SELECT ISNULL(@T_AnioIni, '0'))
	SET @T_AnioFin = (SELECT ISNULL(@T_AnioFin, '3000'))

	BEGIN TRANSACTION
	BEGIN TRY

		UPDATE	TR_Ec_Obl
		SET		B_Migrable = 0,
				D_FecEvalua = @D_FecProceso
		WHERE	Cuota_pago NOT IN (SELECT Cuota_pago FROM TR_Cp_Des WHERE I_ProcedenciaID = @I_ProcedenciaID)
				AND I_ProcedenciaID = @I_ProcedenciaID
				AND I_RowID = IIF(@I_RowID IS NULL, I_RowID, @I_RowID)
				AND (Ano BETWEEN @T_AnioIni AND @T_AnioFin)	

		MERGE TI_ObservacionRegistroTabla AS TRG
		USING 	(SELECT	@I_ObservID AS I_ObservID, @I_TablaID AS I_TablaID, I_RowID AS I_FilaTablaID, @D_FecProceso AS D_FecRegistro 
				 FROM TR_Ec_Obl
				 WHERE	Cuota_pago NOT IN (SELECT Cuota_pago FROM TR_Cp_Des WHERE I_ProcedenciaID = @I_ProcedenciaID)
						AND I_ProcedenciaID = @I_ProcedenciaID
						AND I_RowID = IIF(@I_RowID IS NULL, I_RowID, @I_RowID)
						AND (Ano BETWEEN @T_AnioIni AND @T_AnioFin)
				) AS SRC
		ON TRG.I_ObservID = SRC.I_ObservID AND TRG.I_TablaID = SRC.I_TablaID AND TRG.I_FilaTablaID = SRC.I_FilaTablaID
		WHEN MATCHED THEN
			UPDATE SET D_FecRegistro = SRC.D_FecRegistro
		WHEN NOT MATCHED BY TARGET THEN
			INSERT (I_ObservID, I_TablaID, I_FilaTablaID, D_FecRegistro, I_ProcedenciaID)
			VALUES (SRC.I_ObservID, SRC.I_TablaID, SRC.I_FilaTablaID, SRC.D_FecRegistro, @I_ProcedenciaID)
		WHEN NOT MATCHED BY SOURCE AND TRG.I_ObservID = @I_ObservID AND TRG.I_ProcedenciaID = @I_ProcedenciaID AND TRG.I_FilaTablaID = @I_RowID THEN
			DELETE;

		SET @I_Observados = (SELECT COUNT(*) FROM TI_ObservacionRegistroTabla 
							  WHERE I_ObservID = @I_ObservID AND I_TablaID = @I_TablaID AND I_ProcedenciaID = @I_ProcedenciaID
									AND I_FilaTablaID = IIF(@I_RowID IS NULL, I_FilaTablaID, @I_RowID))

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



IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_IU_MigrarMatriculaObligacionesCtasPorCobrar')
	DROP PROCEDURE [dbo].[USP_IU_MigrarMatriculaObligacionesCtasPorCobrar]
GO


CREATE PROCEDURE [dbo].[USP_IU_MigrarMatriculaObligacionesCtasPorCobrar]	
	@I_ProcedenciaID	tinyint,
	@I_ProcesoID		int = NULL,
	@I_Anio				int = NULL,
	@B_Resultado		bit output,
	@T_Message			nvarchar(4000) OUTPUT	
AS
--declare   @I_ProcedenciaID tinyint = 3,
--			@I_ProcesoID	 int = null, 
--			@I_Anio			 int = 2011, 
--			@B_Resultado	 bit, 
--			@T_Message nvarchar(4000)
--exec USP_IU_MigrarMatriculaObligacionesCtasPorCobrar @I_ProcedenciaID, @I_ProcesoID, @I_Anio, @B_Resultado output, @T_Message output
--select @B_Resultado as resultado, @T_Message as mensaje
BEGIN
	BEGIN TRANSACTION

	BEGIN TRY
	WITH alumnos_matricula AS (
		SELECT DISTINCT Cod_alu, Cod_rc, CAST(Ano as int) AS Ano, I_Periodo, 'S' AS C_EstMat 
		FROM TR_Ec_Obl
		WHERE ISNUMERIC(ANO) = 1
			  AND I_ProcedenciaID = @I_ProcedenciaID
			  AND B_Migrable = 1
	)

	INSERT INTO BD_OCEF_CtasPorCobrar.dbo.TC_MatriculaAlumno (C_CodRc, C_CodAlu, I_Anio, I_Periodo, C_EstMat, C_Ciclo, B_Ingresante, I_CredDesaprob, B_Habilitado, B_Eliminado, B_Migrado)
	SELECT A.Cod_rc, A.Cod_alu, A.Ano, A.I_Periodo, A.C_EstMat, NULL as C_Ciclo, NULL as B_Ingresante, NULL as I_CredDesaprob, 1 as B_Habilitado, 0 as B_Eliminado, 1 as B_Migrado
	  FROM alumnos_matricula A 
		   LEFT JOIN BD_OCEF_CtasPorCobrar.dbo.TC_MatriculaAlumno MA ON MA.C_CodAlu = A.Cod_alu 
																		AND MA.C_CodRc = A.Cod_rc 
																		AND MA.I_Anio  = A.Ano
																		AND MA.I_Periodo = A.I_Periodo
	WHERE Ano = @I_Anio
		  AND MA.I_MatAluID IS NULL;

	SET @T_Message = CAST(@@ROWCOUNT AS varchar);
	SET @B_Resultado = 1;

	COMMIT TRANSACTION;

	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION
		SET @T_Message = 'DESCRIPCION: ' + CAST(ERROR_MESSAGE() AS varchar) + CHAR(10) +  CHAR(13) +  
						 'LINEA: '  + CAST(ERROR_LINE() AS varchar);
		SET @B_Resultado = 1;
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
								
		--SELECT * 
		--INTO #Numeric_Year_Ec_Obl
		--FROM TR_Ec_Obl
		--WHERE ISNUMERIC(ANO) = 1
		--	  AND I_ProcedenciaID = @I_ProcedenciaID

		--MERGE INTO BD_OCEF_CtasPorCobrar.dbo.TC_MatriculaAlumno AS TRG
		--USING (SELECT DISTINCT Cod_alu, Cod_rc, Ano, P, I_Periodo FROM  #Numeric_Year_Ec_Obl
		--		WHERE CAST(Ano AS int) BETWEEN @I_AnioIni AND @I_AnioFin) AS SRC
		--ON TRG.C_CodAlu = SRC.cod_alu 
		--   AND TRG.C_CodRc = SRC.cod_rc 
		--   AND TRG.I_Anio  = CAST(SRC.ano AS int) 
		--   AND TRG.I_Periodo = SRC.I_Periodo
		--WHEN NOT MATCHED THEN
		--	INSERT (C_CodRc, C_CodAlu, I_Anio, I_Periodo, C_EstMat, C_Ciclo, B_Ingresante, I_CredDesaprob, B_Habilitado, B_Eliminado, B_Migrado)
		--	VALUES (SRC.Cod_rc, SRC.Cod_alu, CAST(SRC.Ano as int), SRC.I_Periodo, 'S', NULL, NULL, NULL, 1, 0, 1);

		
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

	IF OBJECT_ID('tempdb..#Numeric_Year_Ec_Obl') IS NOT NULL
	BEGIN
		DROP TABLE #Numeric_Year_Ec_Obl
	END
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
		T_Action	varchar(20), 
		I_rowID		float,
	)

	CREATE TABLE #Tbl_output_pago_det  
	(
		T_Action	varchar(20), 
		I_rowID		float,
	)

	BEGIN TRANSACTION;

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
				
		SELECT * INTO #temp_pagos_conceptos FROM #temp_det_migrados --TR_Ec_Det 
		WHERE Pagado = 1 AND Concepto_f = 0 AND Concepto NOT IN (0, 4788) AND (CAST(Ano AS int) BETWEEN @I_AnioIni AND @I_AnioFin);		

		--DROP TABLE #temp_obl_migrados 
		DROP TABLE #temp_det_migrados

		MERGE INTO BD_OCEF_CtasPorCobrar.dbo.TR_PagoBanco AS TRG
		USING (SELECT DISTINCT CASE det.Cod_cajero WHEN 'BCP' THEN 2 ELSE 1 END AS I_EntidadFinanID, det.Nro_recibo, det.Cod_alu, det.Cod_rc, 
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

		COMMIT TRANSACTION;
	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION;
		SET @B_Resultado = 0
		SET @T_Message = ERROR_MESSAGE() + ' LINE: ' + CAST(ERROR_LINE() AS varchar(10)) 
	END CATCH

	IF OBJECT_ID('tempdb..#temp_pagos_interes_mora') IS NOT NULL
	BEGIN	
		DROP TABLE #temp_pagos_interes_mora
	END

	IF OBJECT_ID('tempdb..#temp_pagos_banco') IS NOT NULL
	BEGIN
		DROP TABLE #temp_pagos_banco
	END

	IF OBJECT_ID('tempdb..#temp_pagos_conceptos') IS NOT NULL
	BEGIN
		DROP TABLE #temp_pagos_conceptos 
	END

END
GO
