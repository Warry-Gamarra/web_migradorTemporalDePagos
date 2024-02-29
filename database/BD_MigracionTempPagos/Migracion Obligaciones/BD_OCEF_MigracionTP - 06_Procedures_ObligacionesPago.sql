USE BD_OCEF_MigracionTP
GO

/*	
	====================================================================================
		Copiar tablas ec_obl y ec_det segun procedencia	(solo obligaciones de pago)
	====================================================================================
*/ 

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_IU_CopiarTablaObligacionesPago')
	DROP PROCEDURE [dbo].[USP_IU_CopiarTablaObligacionesPago]
GO

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_Obligaciones_ObligacionCab_TemporalPagos_MigracionTP_IU_CopiarTabla')
	DROP PROCEDURE [dbo].[USP_Obligaciones_ObligacionCab_TemporalPagos_MigracionTP_IU_CopiarTabla]
GO

CREATE PROCEDURE USP_Obligaciones_ObligacionCab_TemporalPagos_MigracionTP_IU_CopiarTabla	
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
--exec USP_Obligaciones_ObligacionCab_TemporalPagos_MigracionTP_IU_CopiarTabla @I_ProcedenciaID, @T_SchemaDB, @T_AnioIni, @T_AnioFin, @B_Resultado output, @T_Message output
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
		SET @T_Message =  '[{ ' +
							 'Type: "summary", ' + 
							 'Title: "Total", '+ 
							 'Value: ' + CAST(@I_EcObl AS varchar) +
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
		ROLLBACK TRANSACTION
		SET @B_Resultado = 0
		SET @T_Message = '[{ ' +
							 'Type: "error", ' + 
							 'Title: "Error", ' + 
							 'Value: ' + ERROR_MESSAGE() + ' (Linea: ' + CAST(ERROR_LINE() AS varchar(11)) + ').'  +
						  '}]' 
	END CATCH
END
GO



IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_IU_CopiarTablaDetalleObligacionesPago')
	DROP PROCEDURE [dbo].[USP_IU_CopiarTablaDetalleObligacionesPago]
GO

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_Obligaciones_ObligacionDet_TemporalPagos_MigracionTP_IU_CopiarTabla')
	DROP PROCEDURE [dbo].[USP_Obligaciones_ObligacionDet_TemporalPagos_MigracionTP_IU_CopiarTabla]
GO

CREATE PROCEDURE USP_Obligaciones_ObligacionDet_TemporalPagos_MigracionTP_IU_CopiarTabla	
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
--	 	@B_Resultado  bit,
--		@T_Message	  nvarchar(4000)
--exec USP_Obligaciones_ObligacionDet_TemporalPagos_MigracionTP_IU_CopiarTabla @I_ProcedenciaID, @T_SchemaDB, @T_AnioIni, @T_AnioFin, @B_Resultado output, @T_Message output
--select @B_Resultado as resultado, @T_Message as mensaje
BEGIN
	DECLARE @I_EcDet int = 0
	DECLARE @I_Removidos int = 0
	DECLARE @I_Actualizados int = 0
	DECLARE @I_Insertados int = 0
	DECLARE @D_FecProceso datetime = GETDATE() 
	DECLARE @T_SQL nvarchar(max)

	BEGIN TRY 	
	
		SET @T_SQL = 'DELETE FROM TR_Ec_Det WHERE B_Migrado = 0 AND I_ProcedenciaID = '+ CAST(@I_ProcedenciaID as varchar(3)) + ''

		IF (ISNULL(@T_AnioIni, '') <> '' AND ISNULL(@T_AnioFin, '') <> '')
		BEGIN
			SET @T_SQL = @T_SQL + 'AND (ANO BETWEEN ''' + @T_AnioIni + ''' AND ''' + @T_AnioFin + ''');' 
		END

		print @T_SQL
		Exec sp_executesql @T_SQL

		--print @T_Source
		

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

		IF (ISNULL(@T_AnioIni, '') <> '' AND ISNULL(@T_AnioFin, '') <> '')
		BEGIN
			SET @T_Source = @T_Source + ' ' + char(13)+CHAR(10)+ 'WHERE (det.ano BETWEEN ''' + @T_AnioIni + ''' AND ''' + @T_AnioFin + ''')'
		END


		SET @T_SQL = 'DECLARE @D_FecProceso datetime = GETDATE() 
					  INSERT INTO TR_Ec_Det (Cod_alu, Cod_rc, Cuota_pago, Ano, P, Tipo_oblig, Concepto, Fch_venc, Nro_recibo, Fch_pago, Id_lug_pag, Cantidad, Monto, Documento, Pagado, Concepto_f, Fch_elimin, 
											Nro_ec, Fch_ec, Eliminado, Pag_demas, Cod_cajero, Tipo_pago, No_banco, Cod_dep, D_FecCarga, B_Migrable, B_Migrado, D_FecMigrado, I_ProcedenciaID, B_Obligacion, I_OblRowID)
					  SELECT cod_alu, cod_rc, cuota_pago, ano, p, tipo_oblig, concepto, fch_venc, nro_recibo, fch_pago, id_lug_pag, cantidad, monto, CAST(SRC.documento as nvarchar(4000)), pagado, concepto_f, fch_elimin, 
							 nro_ec, fch_ec, eliminado, pag_demas, cod_cajero, tipo_pago, no_banco, cod_dep, @D_FecProceso, 1, 0, NULL, ' + CAST(@I_ProcedenciaID as varchar(3)) + ', 1, I_OblRowID
					    FROM ('+ @T_Source +') AS SRC'

	

		print @T_SQL
		Exec sp_executesql @T_SQL

		SET @I_EcDet = @@ROWCOUNT
		SET @I_Insertados = @I_EcDet


		DELETE FROM TI_ObservacionRegistroTabla 
		WHERE			
				I_TablaID = 4 
				AND I_ProcedenciaID = @I_ProcedenciaID
				AND NOT EXISTS (SELECT I_RowID FROM TR_Ec_Det WHERE I_RowID = I_FilaTablaID);

		IF(@I_Removidos <> 0)
		BEGIN
			SET @I_Actualizados = @I_Insertados
		END

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



/*	
	===============================================================================================
		Inicializar parámetros para validaciones de tablas ec_obl y ec_det segun procedencia	
	===============================================================================================
*/ 

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_U_InicializarEstadoValidacionObligacionPago')
	DROP PROCEDURE [dbo].[USP_U_InicializarEstadoValidacionObligacionPago]
GO

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_Obligaciones_ObligacionCab_MigracionTP_U_InicializarEstadoValidacion')
	DROP PROCEDURE [dbo].[USP_Obligaciones_ObligacionCab_MigracionTP_U_InicializarEstadoValidacion]
GO

CREATE PROCEDURE USP_Obligaciones_ObligacionCab_MigracionTP_U_InicializarEstadoValidacion	
	@I_ProcedenciaID tinyint,
	@I_Anio	      smallint,
	@B_Resultado  bit output,
	@T_Message	  nvarchar(4000) OUTPUT	
AS
--declare	@B_Resultado  bit,
--			@I_ProcedenciaID	tinyint = 3,
--			@I_Anio  	  smallint,
--			@T_Message	  nvarchar(4000)
--exec USP_Obligaciones_ObligacionCab_MigracionTP_U_InicializarEstadoValidacion @I_ProcedenciaID, @I_Anio, @B_Resultado output, @T_Message output
--select @B_Resultado as resultado, @T_Message as mensaje
BEGIN
	BEGIN TRANSACTION
	BEGIN TRY 
		UPDATE	TR_Ec_Obl 
		   SET	B_Actualizado = 0, 
				B_Migrable = 1, 
				D_FecMigrado = NULL, 
				B_Migrado = 0
		 WHERE I_ProcedenciaID = @I_ProcedenciaID
			   AND Ano = CAST(@I_Anio as varchar)
			   AND B_Correcto = 0

		SET @T_Message = CAST(@@ROWCOUNT AS varchar)
		SET @B_Resultado = 1

		COMMIT TRANSACTION;
	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION
		SET @B_Resultado = 0
		SET @T_Message = '[{ ' +
							 'Type: "error", ' + 
							 'Title: "Error", ' + 
							 'Value: ' + ERROR_MESSAGE() + ' (Linea: ' + CAST(ERROR_LINE() AS varchar(11)) + ').'  +
						  '}]' 
	END CATCH
END
GO


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_Obligaciones_ObligacionCab_MigracionTP_U_InicializarEstadoValidacionPorID')
	DROP PROCEDURE [dbo].[USP_Obligaciones_ObligacionCab_MigracionTP_U_InicializarEstadoValidacionPorID]
GO

CREATE PROCEDURE USP_Obligaciones_ObligacionCab_MigracionTP_U_InicializarEstadoValidacionPorID	
	@I_RowID      int,
	@B_Resultado  bit output,
	@T_Message	  nvarchar(4000) OUTPUT	
AS
--declare	@B_Resultado  bit,
--			@I_RowID  	  smallint,
--			@T_Message	  nvarchar(4000)
--exec USP_Obligaciones_ObligacionCab_MigracionTP_U_InicializarEstadoValidacionPorID @I_RowID, @B_Resultado output, @T_Message output
--select @B_Resultado as resultado, @T_Message as mensaje
BEGIN
	BEGIN TRANSACTION
	BEGIN TRY 
		UPDATE	TR_Ec_Obl 
		   SET	B_Actualizado = 0, 
				B_Migrable = 1, 
				D_FecMigrado = NULL, 
				B_Migrado = 0
		 WHERE I_RowID = @I_RowID
			   AND B_Correcto = 0

		SET @T_Message = CAST(@@ROWCOUNT AS varchar)
		SET @B_Resultado = 1

		COMMIT TRANSACTION;
	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION
		SET @B_Resultado = 0
		SET @T_Message = '[{ ' +
							 'Type: "error", ' + 
							 'Title: "Error", ' + 
							 'Value: ' + ERROR_MESSAGE() + ' (Linea: ' + CAST(ERROR_LINE() AS varchar(11)) + ').'  +
						  '}]' 
	END CATCH
END
GO



IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_U_InicializarEstadoValidacionDetalleObligacionPago')
	DROP PROCEDURE [dbo].[USP_U_InicializarEstadoValidacionDetalleObligacionPago]
GO

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_Obligaciones_ObligacionDet_MigracionTP_U_InicializarEstadoValidacion')
	DROP PROCEDURE [dbo].[USP_Obligaciones_ObligacionDet_MigracionTP_U_InicializarEstadoValidacion]
GO

CREATE PROCEDURE USP_Obligaciones_ObligacionDet_MigracionTP_U_InicializarEstadoValidacion	
	@I_ProcedenciaID tinyint,
	@I_Anio	      smallint,
	@B_Resultado  bit output,
	@T_Message	  nvarchar(4000) OUTPUT	
AS
--declare	@B_Resultado  bit,
--			@I_ProcedenciaID	tinyint = 3,
--			@I_OblRowID		int = NULL,
--			@I_Anio	      smallint = 2010,
--			@T_Message	  nvarchar(4000)
--exec USP_Obligaciones_ObligacionDet_MigracionTP_U_InicializarEstadoValidacion @I_ProcedenciaID, @I_Anio, @B_Resultado output, @T_Message output
--select @B_Resultado as resultado, @T_Message as mensaje
BEGIN
	BEGIN TRANSACTION
	BEGIN TRY
		WITH cte_obl_anio (I_OblRowID, Cod_alu, Cod_rc, Cuota_pago, P, Fch_venc, Pagado, Monto)
		AS ( 
			SELECT I_RowID, Cod_alu, Cod_rc, Cuota_pago, P, Fch_venc, Pagado, Monto
			  FROM TR_Ec_Obl 
			 WHERE I_ProcedenciaID = @I_ProcedenciaID
				   AND Ano = CAST(@I_Anio as varchar)
		)


		UPDATE	det
		   SET	B_Actualizado = IIF(B_Actualizado = 1, B_Actualizado, 0), 
				B_Migrable = 1, 
				D_FecMigrado = NULL, 
				B_Migrado = 0
		  FROM  TR_Ec_Det det 
				INNER JOIN cte_obl_anio obl ON det.I_OblRowID = obl.I_OblRowID

		SET @T_Message = CAST(@@ROWCOUNT AS varchar)
		SET @B_Resultado = 1

		COMMIT TRANSACTION;
	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION
		SET @B_Resultado = 0
		SET @T_Message = '[{ ' +
							 'Type: "error", ' + 
							 'Title: "Error", ' + 
							 'Value: ' + ERROR_MESSAGE() + ' (Linea: ' + CAST(ERROR_LINE() AS varchar(11)) + ').'  +
						  '}]' 
	END CATCH
END
GO


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_Obligaciones_ObligacionDet_MigracionTP_U_InicializarEstadoValidacionPorID')
	DROP PROCEDURE [dbo].[USP_Obligaciones_ObligacionDet_MigracionTP_U_InicializarEstadoValidacionPorID]
GO

CREATE PROCEDURE USP_Obligaciones_ObligacionDet_MigracionTP_U_InicializarEstadoValidacionPorID	
	@I_OblRowID   int,
	@B_Resultado  bit output,
	@T_Message	  nvarchar(4000) OUTPUT	
AS
--declare	@B_Resultado  bit,
--			@I_OblRowID		int = NULL,
--			@T_Message	  nvarchar(4000)
--exec USP_Obligaciones_ObligacionDet_MigracionTP_U_InicializarEstadoValidacionPorID @I_OblRowID, @B_Resultado output, @T_Message output
--select @B_Resultado as resultado, @T_Message as mensaje
BEGIN
	BEGIN TRANSACTION
	BEGIN TRY

		UPDATE	TR_Ec_Det
		   SET	B_Actualizado = IIF(B_Actualizado = 1, B_Actualizado, 0), 
				B_Migrable = 1, 
				D_FecMigrado = NULL, 
				B_Migrado = 0
		 WHERE	I_OblRowID = I_OblRowID

		SET @T_Message = CAST(@@ROWCOUNT AS varchar)
		SET @B_Resultado = 1

		COMMIT TRANSACTION;
	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION
		SET @B_Resultado = 0
		SET @T_Message = '[{ ' +
							 'Type: "error", ' + 
							 'Title: "Error", ' + 
							 'Value: ' + ERROR_MESSAGE() + ' (Linea: ' + CAST(ERROR_LINE() AS varchar(11)) + ').'  +
						  '}]' 
	END CATCH
END
GO


/*	
	===============================================================================================
		Validaciones para migracion de ec_obl y ec_det (solo obligaciones de pago)	
	===============================================================================================
*/ 





IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_U_ValidarExisteAlumnoCabeceraObligacion')
	DROP PROCEDURE [dbo].[USP_U_ValidarExisteAlumnoCabeceraObligacion]
GO

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_Obligaciones_ObligacionCab_MigracionTP_U_ValidarExisteAlumno')
	DROP PROCEDURE [dbo].[USP_Obligaciones_ObligacionCab_MigracionTP_U_ValidarExisteAlumno]
GO

CREATE PROCEDURE [dbo].[USP_Obligaciones_ObligacionCab_MigracionTP_U_ValidarExisteAlumno]	
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
--exec USP_Obligaciones_ObligacionCab_MigracionTP_U_ValidarExisteAlumno @I_ProcedenciaID, @I_RowID, @I_AnioIni, @I_AnioFin, @B_Resultado output, @T_Message output
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
		SET @T_Message = '[{ ' +
							 'Type: "error", ' + 
							 'Title: "Error", ' + 
							 'Value: ' + ERROR_MESSAGE() + ' (Linea: ' + CAST(ERROR_LINE() AS varchar(11)) + ').'  +
						  '}]' 
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

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_Obligaciones_ObligacionCab_MigracionTP_U_ValidarAnioEnCabeceraObligacion')
	DROP PROCEDURE [dbo].[USP_Obligaciones_ObligacionCab_MigracionTP_U_ValidarAnioEnCabeceraObligacion]
GO

CREATE PROCEDURE [dbo].[USP_Obligaciones_ObligacionCab_MigracionTP_U_ValidarAnioEnCabeceraObligacion]	
	@I_ProcedenciaID tinyint,
	@I_RowID	  int = NULL,
	@B_Resultado  bit output,
	@T_Message	  nvarchar(4000) OUTPUT	
AS
--declare @I_ProcedenciaID	tinyint = 3, 
--		@I_RowID	  int = NULL,
--		@B_Resultado  bit,
--		@T_Message	  nvarchar(4000)
--exec USP_Obligaciones_ObligacionCab_MigracionTP_U_ValidarAnioEnCabeceraObligacion @I_ProcedenciaID, @I_RowID, @B_Resultado output, @T_Message output
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

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_Obligaciones_ObligacionCab_MigracionTP_U_ValidarPeriodoEnCabeceraObligacion')
	DROP PROCEDURE [dbo].[USP_Obligaciones_ObligacionCab_MigracionTP_U_ValidarPeriodoEnCabeceraObligacion]
GO

CREATE PROCEDURE [dbo].[USP_Obligaciones_ObligacionCab_MigracionTP_U_ValidarPeriodoEnCabeceraObligacion]	
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


