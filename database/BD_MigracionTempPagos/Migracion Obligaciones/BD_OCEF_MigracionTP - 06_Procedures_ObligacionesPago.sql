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
	@T_Anio		  varchar(4),
	@B_Resultado  bit output,
	@T_Message	  nvarchar(4000) OUTPUT	
AS
/*
	declare @I_ProcedenciaID	tinyint = 1,
			@T_SchemaDB   varchar(20) = 'pregrado',
			@T_Anio		  varchar(4) = '2010',
			@B_Resultado  bit,
			@T_Message	  nvarchar(4000)
	exec USP_Obligaciones_ObligacionCab_TemporalPagos_MigracionTP_IU_CopiarTabla @I_ProcedenciaID, @T_SchemaDB, @T_Anio, @B_Resultado output, @T_Message output
	select @B_Resultado as resultado, @T_Message as mensaje
*/
BEGIN
	DECLARE @I_EcObl int = 0
	DECLARE @I_Removidos int = 0
	DECLARE @I_Actualizados int = 0
	DECLARE @I_Insertados int = 0
	DECLARE @D_FecProceso datetime = GETDATE() 
	DECLARE @T_SQL nvarchar(max)

	BEGIN TRANSACTION
	BEGIN TRY 
		SET @T_SQL = 'DELETE TR_Ec_Det_Pagos ' +
					'WHERE I_ProcedenciaID = '+ CAST(@I_ProcedenciaID as varchar(3)) + ' ' +
						'AND EXISTS (SELECT * FROM TR_Ec_Obl ' + 
										'WHERE TR_Ec_Obl.I_RowID = I_OblRowID ' + 
											'AND TR_Ec_Obl.Ano = ''' + @T_Anio + ''' ' + 
											'AND TR_Ec_Obl.B_Migrado = 0 ' + 
											'AND TR_Ec_Obl.I_ProcedenciaID = I_ProcedenciaID);'


		SET @T_SQL = 'DELETE TR_Ec_Det ' +
					  'WHERE I_ProcedenciaID = '+ CAST(@I_ProcedenciaID as varchar(3)) + ' ' +
							'AND EXISTS (SELECT * FROM TR_Ec_Obl ' + 
										 'WHERE TR_Ec_Obl.I_RowID = I_OblRowID ' + 
												'AND TR_Ec_Obl.Ano = ''' + @T_Anio + ''' ' + 
												'AND TR_Ec_Obl.B_Migrado = 0 ' + 
												'AND TR_Ec_Obl.I_ProcedenciaID = I_ProcedenciaID);'

		PRINT @T_SQL
		EXEC sp_executesql @T_SQL

						
		SET @T_SQL = 'DELETE TR_Ec_Det ' +
					  'WHERE I_ProcedenciaID = '+ CAST(@I_ProcedenciaID as varchar(3)) + ' ' +
							'AND I_OblRowID IS NULL ' +
							'AND Ano = ''' + @T_Anio + ''' '
						
		PRINT @T_SQL
		EXEC sp_executesql @T_SQL

		
		SET @T_SQL = 'DELETE TR_Ec_Obl ' +
					  'WHERE I_ProcedenciaID = '+ CAST(@I_ProcedenciaID as varchar(3)) + ' ' +
							'AND TR_Ec_Obl.Ano = ''' + @T_Anio + ''' ' +
							'AND TR_Ec_Obl.B_Migrado = 0;'

		PRINT @T_SQL
		EXEC sp_executesql @T_SQL
		SET @I_Removidos = @I_Removidos + @@ROWCOUNT


		DELETE FROM TI_ObservacionRegistroTabla 				
			  WHERE I_TablaID = 4 
					AND I_ProcedenciaID = @I_ProcedenciaID
					AND NOT EXISTS (SELECT I_RowID FROM TR_Ec_Det 
									WHERE I_RowID = I_FilaTablaID
										  AND Ano = @T_Anio);


		SET @T_SQL = 'DECLARE @D_FecProceso datetime = GETDATE(); ' +
			
					  'INSERT TR_Ec_Obl (Ano, P, I_Periodo, Cod_alu, Cod_rc, Cuota_pago, Tipo_oblig, Fch_venc, Monto, Pagado, ' + 
										'D_FecCarga, B_Migrable, B_Migrado, I_ProcedenciaID, B_Obligacion) ' +
								 'SELECT ano, p, I_OpcionID as I_periodo, cod_alu, cod_rc, cuota_pago, tipo_oblig, fch_venc, monto, pagado, ' + 
										'@D_FecProceso, 1, 0, ' + CAST(@I_ProcedenciaID as varchar(3)) + ', 1 ' +
								   'FROM BD_OCEF_TemporalPagos.' + @T_SchemaDB + '.ec_obl OBL ' +
								 		'LEFT JOIN BD_OCEF_CtasPorCobrar.dbo.TC_CatalogoOpcion cop_per ON OBL.P = cop_per.T_OpcionCod AND cop_per.I_ParametroID = 5 ' +
								  'WHERE NOT EXISTS (SELECT * FROM TR_Ec_Obl TRG ' +
								 					'WHERE TRG.Ano = OBL.ano AND TRG.P = OBL.p AND TRG.Cod_alu = OBL.COD_ALU  ' + 
														  'AND TRG.Cod_rc = OBL.COD_RC AND TRG.Cuota_pago = OBL.cuota_pago ' +
								 						  'AND ISNULL(TRG.Fch_venc, ''19000101'') = ISNULL(OBL.fch_venc, ''19000101'') ' +
								 						  'AND ISNULL(TRG.Tipo_oblig, 0) = ISNULL(OBL.tipo_oblig, 0) AND TRG.Monto = OBL.monto ' +
								 						  'AND TRG.Pagado = OBL.pagado AND TRG.I_ProcedenciaID = '+ CAST(@I_ProcedenciaID as varchar(3)) + ') ' +
								 	   'AND OBL.Ano = ''' + @T_Anio + ''' '

		PRINT @T_SQL
		EXEC sp_executesql @T_SQL
		SET @I_Insertados = @@ROWCOUNT

		
		SET @T_SQL = 'SELECT * FROM BD_OCEF_TemporalPagos.' + @T_SchemaDB + '.ec_obl WHERE Ano = ''' + @T_Anio + ''' '

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
					AND NOT EXISTS (SELECT I_RowID FROM TR_Ec_Det 
									WHERE I_RowID = I_FilaTablaID
										  AND Ano = @T_Anio);


		SELECT @I_EcObl AS tot_obligaciones, @I_Insertados AS cant_inserted, @I_Actualizados AS cant_updated, @I_Removidos as cant_removed, @D_FecProceso as fec_proceso;
		

		COMMIT TRANSACTION
		SET @B_Resultado = 1					
		SET @T_Message =  '[{ ' +
							 'Type: "summary", ' + 
							 'Title: "EC_OBL Total ' + @T_Anio + ':", '+ 
							 'Value: ' + CAST(@I_EcObl AS varchar) +
						  '}, ' + 
						  '{ ' +
							 'Type: "detail", ' + 
							 'Title: "Insertados ' + @T_Anio + ':", ' + 
							 'Value: ' + CAST(@I_Insertados AS varchar) +
						  '}, ' +
						  '{ ' +
							 'Type: "detail", ' + 
							 'Title: "Actualizados ' + @T_Anio + ':", ' + 
							 'Value: ' + CAST(@I_Actualizados AS varchar) +  
						  '}, ' +
						  '{ ' +
							 'Type: "detail", ' + 
							 'Title: "Removidos ' + @T_Anio + ':", ' + 
							 'Value: ' + CAST(@I_Removidos AS varchar)+ 
						  '}]'

	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION
		SET @B_Resultado = 0
		SET @T_Message = '[{ ' +
							 'Type: "error", ' + 
							 'Title: "Error", ' + 
							 'Value: "' + ERROR_MESSAGE() + ' (Linea: ' + CAST(ERROR_LINE() AS varchar(11)) + ')."'  +
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
	@T_Anio		  varchar(4),
	@B_Resultado  bit output,
	@T_Message	  nvarchar(4000) OUTPUT	
AS
/*
	declare @I_ProcedenciaID	tinyint = 1,
			@T_SchemaDB   varchar(20) = 'pregrado',
			@T_Anio	  varchar(4) = '2010',
	 		@B_Resultado  bit,
			@T_Message	  nvarchar(4000)
	exec USP_Obligaciones_ObligacionDet_TemporalPagos_MigracionTP_IU_CopiarTabla @I_ProcedenciaID, @T_SchemaDB, @T_Anio, @B_Resultado output, @T_Message output
	select @B_Resultado as resultado, @T_Message as mensaje
*/
BEGIN
	DECLARE @I_EcDet int = 0
	DECLARE @I_Removidos int = 0
	DECLARE @I_Actualizados int = 0
	DECLARE @I_Insertados int = 0
	DECLARE @D_FecProceso datetime = GETDATE() 
	DECLARE @T_SQL nvarchar(max)

	BEGIN TRANSACTION
	BEGIN TRY 	

		SET @T_SQL = 'DELETE TR_Ec_Det ' +
					  'WHERE I_ProcedenciaID = '+ CAST(@I_ProcedenciaID as varchar(3)) + 
							'AND B_Migrado = 0 ' +
							'AND Ano = ''' + @T_Anio + '''; '						

		PRINT @T_SQL
		EXEC sp_executesql @T_SQL
		SET @I_Removidos = @@ROWCOUNT


		SET @T_SQL = 'DECLARE @D_FecProceso datetime = GETDATE() ' + 

					 'INSERT INTO TR_Ec_Det (Cod_alu, Cod_rc, Cuota_pago, Ano, P, Tipo_oblig, Concepto, Fch_venc, Nro_recibo, Fch_pago, ' + 
											'Id_lug_pag, Cantidad, Monto, Documento, Pagado, Concepto_f, Fch_elimin, Nro_ec, Fch_ec, ' +
											'Eliminado, Pag_demas, Cod_cajero, Tipo_pago, No_banco, Cod_dep, D_FecCarga, B_Migrable, ' +
											'B_Migrado, D_FecMigrado, I_ProcedenciaID, B_Obligacion) ' +
									'SELECT  cod_alu, cod_rc, cuota_pago, ano, p, tipo_oblig, concepto, fch_venc, nro_recibo, fch_pago, ' + 
										    'id_lug_pag, cantidad, monto, CAST(documento as nvarchar(max)), pagado, concepto_f, fch_elimin, nro_ec, fch_ec, ' + 
										    'eliminado, pag_demas, cod_cajero, tipo_pago, no_banco, cod_dep, @D_FecProceso as D_FecCarga, 1 as B_Migrable, ' + 
										    '0 as B_Migrado,  NULL as D_FecMigrado, ' + CAST(@I_ProcedenciaID as varchar(3)) + ' as I_ProcedenciaID, 1 as B_Obligacion ' +
									  'FROM BD_OCEF_TemporalPagos.' + @T_SchemaDB + '.ec_det ' +
									 'WHERE Concepto_f = 0' +
										   'AND Ano = ''' + @T_Anio + '''; '

		print @T_SQL
		Exec sp_executesql @T_SQL

		SET @I_EcDet = @@ROWCOUNT


		DELETE FROM TI_ObservacionRegistroTabla 
			  WHERE	I_TablaID = 4 
					AND I_ProcedenciaID = @I_ProcedenciaID
					AND NOT EXISTS (SELECT I_RowID FROM TR_Ec_Det WHERE I_RowID = I_FilaTablaID);

		IF(@I_Removidos > 0)
		BEGIN
			SET @I_Insertados = @I_EcDet - @I_Removidos
			SET @I_Actualizados =   @I_EcDet - @I_Insertados
		END
		ELSE
		BEGIN
			SET @I_Insertados = @I_EcDet
			SET @I_Actualizados =  @I_EcDet - @I_Insertados
		END

		SELECT @I_EcDet AS tot_obligaciones, @I_Insertados AS cant_inserted, @I_Actualizados as cant_updated, @I_Removidos as cant_removed, @D_FecProceso as fec_proceso
		
		COMMIT TRANSACTION
		SET @B_Resultado = 1
		SET @T_Message =  '[{ ' +
							 'Type: "summary", ' + 
							 'Title: "EC_DET Total ' + @T_Anio + ':", ' +
							 'Value: ' + CAST(@I_EcDet AS varchar) +
						  '}, ' + 
						  '{ ' +
							 'Type: "detail", ' + 
							 'Title: "Insertados ' + @T_Anio + ':", ' +
							 'Value: ' + CAST(@I_Insertados AS varchar) +
						  '}, ' +
						  '{ ' +
							 'Type: "detail", ' + 
							 'Title: "Actualizados ' + @T_Anio + ':", ' + 
							 'Value: ' + CAST(@I_Actualizados AS varchar) +  
						  '}, ' +
						  '{ ' +
							 'Type: "detail", ' + 
							 'Title: "Removidos ' + @T_Anio + ':", ' +
							 'Value: ' + CAST(@I_Removidos AS varchar)+ 
						  '}]'
	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION
		SET @B_Resultado = 0
		SET @T_Message = '[{ ' +
							 'Type: "error", ' + 
							 'Title: "Error", ' + 
							 'Value: "' + ERROR_MESSAGE() + ' (Linea: ' + CAST(ERROR_LINE() AS varchar(11)) + ')."'  +
						  '}]' 
	END CATCH
END
GO


/*	
	===============================================================================================
		relacionar registros de tablas ec_obl y ec_det segun procedencia (I_OblID)
	===============================================================================================
*/ 

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_Obligaciones_ObligacionDet_MigracionTP_U_AsignarObligacionCabID')
	DROP PROCEDURE [dbo].[USP_Obligaciones_ObligacionDet_MigracionTP_U_AsignarObligacionCabID]
GO


CREATE PROCEDURE USP_Obligaciones_ObligacionDet_MigracionTP_U_AsignarObligacionCabID 
(
	@I_ProcedenciaID tinyint,
	@T_Anio		  varchar(4),
	@B_Resultado  bit output,
	@T_Message	  nvarchar(4000) OUTPUT	
)
AS
/*
  declare	@B_Resultado  bit,
			@I_ProcedenciaID	tinyint = 1,
	    	@T_Anio		  varchar(4) = '2010s',
			@T_Message	  nvarchar(4000)
  exec USP_Obligaciones_ObligacionDet_MigracionTP_U_AsignarObligacionCabID @I_ProcedenciaID, @T_Anio, @B_Resultado output, @T_Message output
  select @B_Resultado as resultado, @T_Message as mensaje
*/
BEGIN 
	DECLARE @D_FecProceso datetime = GETDATE() 
	DECLARE @I_Actualizados int = 0

	BEGIN TRANSACTION
	BEGIN TRY
		
		--Para obtener ID de obligación que no se encuentren repetidos
		SELECT OBL2.*
		  INTO #temp_obl_sin_repetir_anio_procedencia 
		  FROM (SELECT Cuota_pago, Ano, P, Cod_alu, Cod_rc, Tipo_oblig, Fch_venc, Pagado, Monto, I_ProcedenciaID
		    	  FROM TR_Ec_Obl
				 WHERE Ano = @T_Anio
					   AND I_ProcedenciaID = @I_ProcedenciaID
				GROUP BY Cuota_pago, Ano, P, Cod_alu, Cod_rc, Tipo_oblig, Fch_venc, Pagado, Monto, I_ProcedenciaID
				HAVING COUNT(*) = 1) OBL1
			   INNER JOIN TR_Ec_Obl OBL2 ON OBL1.I_ProcedenciaID = OBL2.I_ProcedenciaID
											AND OBL1.Cuota_pago = OBL2.Cuota_pago
											AND OBL1.Ano = OBL2.Ano
											AND OBL1.P = OBL2.P
											AND OBL1.Cod_alu = OBL2.Cod_alu
											AND OBL1.Cod_rc = OBL2.Cod_rc
											AND OBL1.Tipo_oblig = OBL2.Tipo_oblig
											AND OBL1.Fch_venc = OBL2.Fch_venc
											AND OBL1.Pagado = OBL2.Pagado
											AND OBL1.Monto = OBL2.Monto

		--Se actualiza los detalles con ID de obligación que no se encuentre repetido

		UPDATE det
		   SET I_OblRowID = obl.I_RowID
		  FROM TR_Ec_Det det
			   INNER JOIN #temp_obl_sin_repetir_anio_procedencia obl ON det.I_ProcedenciaID = obl.I_ProcedenciaID
																		AND det.Cuota_pago = obl.Cuota_pago
																		AND det.Ano = obl.Ano
																		AND det.P = obl.P
																		AND det.Cod_alu = obl.Cod_alu
																		AND det.Cod_rc = obl.Cod_rc
																		AND det.Fch_venc = obl.Fch_venc
		 WHERE det.Ano = @T_Anio
			   AND det.I_ProcedenciaID = @I_ProcedenciaID

		
		----Para obtener ID de obligación que se encuentran repetidos 
		--SELECT OBL2.*
		--  INTO #temp_obl_repetido_anio_procedencia
		--  FROM (SELECT Cuota_pago, Ano, P, Cod_alu, Cod_rc, Tipo_oblig, Fch_venc, Pagado, Monto, I_ProcedenciaID
		--    	  FROM TR_Ec_Obl
		--		 WHERE Ano = @T_Anio
		--			   AND I_ProcedenciaID = @I_ProcedenciaID
		--		GROUP BY Cuota_pago, Ano, P, Cod_alu, Cod_rc, Tipo_oblig, Fch_venc, Pagado, Monto, I_ProcedenciaID
		--		HAVING COUNT(*) > 1) OBL1
		--	   INNER JOIN TR_Ec_Obl OBL2 ON OBL1.I_ProcedenciaID = OBL2.I_ProcedenciaID
		--									AND OBL1.Cuota_pago = OBL2.Cuota_pago
		--									AND OBL1.Ano = OBL2.Ano
		--									AND OBL1.P = OBL2.P
		--									AND OBL1.Cod_alu = OBL2.Cod_alu
		--									AND OBL1.Cod_rc = OBL2.Cod_rc
		--									AND OBL1.Tipo_oblig = OBL2.Tipo_oblig
		--									AND OBL1.Fch_venc = OBL2.Fch_venc
		--									AND OBL1.Pagado = OBL2.Pagado
		--									AND OBL1.Monto = OBL2.Monto

		--Se actualiza los detalles con ID de obligación que no se encuentre repetido

		UPDATE det
		   SET I_OblRowID = obl.I_RowID
		  FROM TR_Ec_Det det
			   INNER JOIN #temp_obl_sin_repetir_anio_procedencia obl ON det.I_ProcedenciaID = obl.I_ProcedenciaID
																		AND det.Cuota_pago = obl.Cuota_pago
																		AND det.Ano = obl.Ano
																		AND det.P = obl.P
																		AND det.Cod_alu = obl.Cod_alu
																		AND det.Cod_rc = obl.Cod_rc
																		AND det.Fch_venc = obl.Fch_venc
		 WHERE det.Ano = @T_Anio
			   AND det.I_ProcedenciaID = @I_ProcedenciaID




		COMMIT TRANSACTION
		SET @B_Resultado = 1					
		SET @T_Message =  '{' +
							 'Type: "summary", ' + 
							 'Title: "Actualizados", ' + 
							 'Value: ' + CAST(@I_Actualizados AS varchar) +  
						  '}'
	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION
		SET @B_Resultado = 0
		SET @T_Message = '[{' +
							 'Type: "error", ' + 
							 'Title: "Error", ' + 
							 'Value: "' + ERROR_MESSAGE() + ' (Linea: ' + CAST(ERROR_LINE() AS varchar(11)) + ')."'  +
						  '}]' 
	END CATCH
END
GO



IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_Obligaciones_ObligacionDet_MigracionTP_U_AsignarObligacionIdDetalleId')
	DROP PROCEDURE [dbo].[USP_Obligaciones_ObligacionDet_MigracionTP_U_AsignarObligacionIdDetalleId]
GO


CREATE PROCEDURE USP_Obligaciones_ObligacionDet_MigracionTP_U_AsignarObligacionIdDetalleId 
(
	@I_OblRowID	  int,
	@I_DetRowID	  int,
	@B_Resultado  bit output,
	@T_Message	  nvarchar(4000) OUTPUT	
)
AS
/*
  declare	@B_Resultado  bit,
			@I_OblRowID	  int = 2783702,
			@I_DetRowID	  int = 2783702,
			@T_Message	  nvarchar(4000)
  exec USP_Obligaciones_ObligacionDet_MigracionTP_U_AsignarObligacionIdDetalleId @I_OblRowID, @I_DetRowID, @B_Resultado output, @T_Message output
  select @B_Resultado as resultado, @T_Message as mensaj
*/
BEGIN 
	DECLARE @D_FecProceso datetime = GETDATE() 

	BEGIN TRANSACTION
	BEGIN TRY
		
		UPDATE TR_Ec_Det
		   SET I_OblRowID = @I_OblRowID
		 WHERE I_RowID = @I_DetRowID

		COMMIT TRANSACTION
		SET @B_Resultado = 1					
		SET @T_Message =  '{' +
							 'Type: "summary", ' + 
							 'Title: "Actualizados", ' + 
							 'Value: ' + CAST(@I_DetRowID AS varchar) +  
						  '}'
	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION
		SET @B_Resultado = 0
		SET @T_Message = '[{' +
							 'Type: "error", ' + 
							 'Title: "Error", ' + 
							 'Value: "' + ERROR_MESSAGE() + ' (Linea: ' + CAST(ERROR_LINE() AS varchar(11)) + ')."'  +
						  '}]' 
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
	@T_Anio	      varchar(4),
	@B_Resultado  bit output,
	@T_Message	  nvarchar(4000) OUTPUT	
AS
/*
	declare	@B_Resultado  bit,
				@I_ProcedenciaID	tinyint = 2,
				@T_Anio  	  varchar(4) = '2016',
				@T_Message	  nvarchar(4000)
	exec USP_Obligaciones_ObligacionCab_MigracionTP_U_InicializarEstadoValidacion @I_ProcedenciaID, @T_Anio, @B_Resultado output, @T_Message output
	select @B_Resultado as resultado, @T_Message as mensaje
*/
BEGIN
	BEGIN TRANSACTION
	BEGIN TRY 
		UPDATE	TR_Ec_Obl 
		   SET	B_Actualizado = 0, 
				B_Migrable = 1, 
				D_FecMigrado = NULL, 
				B_Migrado = 0
		 WHERE I_ProcedenciaID = @I_ProcedenciaID
			   AND Ano = @T_Anio
			   AND ISNULL(B_Correcto, 0) = 0

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
							 'Value: "' + ERROR_MESSAGE() + ' (Linea: ' + CAST(ERROR_LINE() AS varchar(11)) + ')."'  +
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
/*
	declare	@B_Resultado  bit,
				@I_RowID  	  smallint,
				@T_Message	  nvarchar(4000)
	exec USP_Obligaciones_ObligacionCab_MigracionTP_U_InicializarEstadoValidacionPorID @I_RowID, @B_Resultado output, @T_Message output
	select @B_Resultado as resultado, @T_Message as mensaje
*/
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
							 'Value: "' + ERROR_MESSAGE() + ' (Linea: ' + CAST(ERROR_LINE() AS varchar(11)) + ')."'  +
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
	@T_Anio	      varchar(4),
	@B_Resultado  bit output,
	@T_Message	  nvarchar(4000) OUTPUT	
AS
/*
	declare	@B_Resultado  bit,
			@I_ProcedenciaID	tinyint = 3,
			@T_Anio	      varchar(4) = 2010,
			@T_Message	  nvarchar(4000)
	exec USP_Obligaciones_ObligacionDet_MigracionTP_U_InicializarEstadoValidacion @I_ProcedenciaID, @T_Anio, @B_Resultado output, @T_Message output
	select @B_Resultado as resultado, @T_Message as mensaje
*/
BEGIN
	BEGIN TRANSACTION
	BEGIN TRY
		WITH cte_obl_anio (I_OblRowID, Cod_alu, Cod_rc, Cuota_pago, P, Fch_venc, Pagado, Monto)
		AS ( 
			SELECT I_RowID, Cod_alu, Cod_rc, Cuota_pago, P, Fch_venc, Pagado, Monto
			  FROM TR_Ec_Obl 
			 WHERE I_ProcedenciaID = @I_ProcedenciaID
				   AND Ano = @T_Anio
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
							 'Value: "' + ERROR_MESSAGE() + ' (Linea: ' + CAST(ERROR_LINE() AS varchar(11)) + ')."'  +
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
/*
	declare	@B_Resultado  bit,
			@I_OblRowID		int = NULL,
			@T_Message	  nvarchar(4000)
	exec USP_Obligaciones_ObligacionDet_MigracionTP_U_InicializarEstadoValidacionPorID @I_OblRowID, @B_Resultado output, @T_Message output
	select @B_Resultado as resultado, @T_Message as mensaje
*/
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
							 'Value: "' + ERROR_MESSAGE() + ' (Linea: ' + CAST(ERROR_LINE() AS varchar(11)) + ')."'  +
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

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_24_ExisteAlumno')
	DROP PROCEDURE [dbo].[USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_24_ExisteAlumno]
GO

CREATE PROCEDURE [dbo].[USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_24_ExisteAlumno] 
	@I_ProcedenciaID tinyint,
	@T_Anio		  varchar(4),
	@B_Resultado  bit output,
	@T_Message	  nvarchar(4000) OUTPUT	
AS
/*
	declare @I_ProcedenciaID	tinyint = 3,
			@T_Anio		  varchar(4) = '2010',
			@B_Resultado  bit,
			@T_Message	  nvarchar(4000)
	exec USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_24_ExisteAlumno @I_ProcedenciaID, @T_Anio, @B_Resultado output, @T_Message output
	select @B_Resultado as resultado, @T_Message as mensaje
*/
BEGIN
	DECLARE @I_Observados int = 0
	DECLARE @D_FecProceso datetime = GETDATE() 
	DECLARE @I_ObservID int = 24
	DECLARE @I_TablaID int = 5

	BEGIN TRANSACTION
	BEGIN TRY 

		UPDATE	ec_obl
		SET		B_Migrable = 0,
				D_FecEvalua = @D_FecProceso
		FROM	TR_Ec_Obl ec_obl
				LEFT JOIN TR_Alumnos ec_alu ON ec_obl.Cod_alu = ec_alu.C_CodAlu and ec_obl.Cod_rc = ec_alu.C_RcCod
		WHERE	ec_alu.I_RowID is null
				AND ec_obl.Ano = @T_Anio
			    AND ec_obl.I_ProcedenciaID = @I_ProcedenciaID

					
		MERGE TI_ObservacionRegistroTabla AS TRG
		USING 	(SELECT	@I_ObservID AS I_ObservID, @I_TablaID AS I_TablaID, ec_obl.I_RowID AS I_FilaTablaID, @D_FecProceso AS D_FecRegistro 
				   FROM	TR_Ec_Obl ec_obl
						LEFT JOIN TR_Alumnos ec_alu ON ec_obl.Cod_alu = ec_alu.C_CodAlu and ec_obl.Cod_rc = ec_alu.C_RcCod
				  WHERE	ec_alu.I_RowID is null
						AND ec_obl.Ano = @T_Anio
						AND ec_obl.I_ProcedenciaID = @I_ProcedenciaID
				) AS SRC
		ON TRG.I_ObservID = SRC.I_ObservID AND TRG.I_TablaID = SRC.I_TablaID AND TRG.I_FilaTablaID = SRC.I_FilaTablaID
		WHEN MATCHED THEN
			UPDATE SET D_FecRegistro = SRC.D_FecRegistro
		WHEN NOT MATCHED BY TARGET THEN
			INSERT (I_ObservID, I_TablaID, I_FilaTablaID, D_FecRegistro, I_ProcedenciaID)
			VALUES (SRC.I_ObservID, SRC.I_TablaID, SRC.I_FilaTablaID, SRC.D_FecRegistro, @I_ProcedenciaID);


		UPDATE OBS
		   SET D_FecResuelto = @D_FecProceso,
			   B_Resuelto = 1
		  FROM TI_ObservacionRegistroTabla OBS
			   INNER JOIN (SELECT ec_obl.*, ec_alu.I_RowID AS I_AluRowID  
							 FROM TR_Ec_Obl ec_obl
								  LEFT JOIN TR_Alumnos ec_alu ON ec_obl.Cod_alu = ec_alu.C_CodAlu and ec_obl.Cod_rc = ec_alu.C_RcCod
							WHERE ec_alu.I_RowID IS NOT NULL
								  AND ec_obl.Ano = @T_Anio
								  AND ec_obl.I_ProcedenciaID = @I_ProcedenciaID) OBL 
						  ON OBS.I_FilaTablaID = OBL.I_RowID
							 AND OBS.I_ProcedenciaID = OBL.I_ProcedenciaID
		 WHERE OBS.I_ObservID = @I_ObservID 
			   AND OBS.I_TablaID = @I_TablaID


		SET @I_Observados = (SELECT COUNT(*) 
							   FROM (SELECT * FROM TR_Ec_Obl WHERE Ano = @T_Anio AND I_ProcedenciaID = @I_ProcedenciaID) OBL
									INNER JOIN (SELECT * FROM TI_ObservacionRegistroTabla WHERE I_ObservID = @I_ObservID AND I_TablaID = @I_TablaID) OBS 
											   ON OBS.I_FilaTablaID = OBL.I_RowID AND OBS.I_ProcedenciaID = OBL.I_ProcedenciaID)

		SELECT @I_Observados as cant_obs, @D_FecProceso as fec_proceso

		COMMIT TRANSACTION				
		SET @B_Resultado = 1
		SET @T_Message = '{ ' +
							 'Type: "summary", ' + 
							 'Title: "Observados", ' + 
							 'Value: ' + CAST(@I_Observados AS varchar)  +
						  '}' 
	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION
		SET @B_Resultado = 0
		SET @T_Message = '[{ ' +
							 'Type: "error", ' + 
							 'Title: "Error", ' + 
							 'Value: "' + ERROR_MESSAGE() + ' (Linea: ' + CAST(ERROR_LINE() AS varchar(11)) + ')."'  +
						  '}]' 
	END CATCH

END
GO

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_24_ExisteAlumnoPorOblID')
	DROP PROCEDURE [dbo].[USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_24_ExisteAlumnoPorOblID]
GO

CREATE PROCEDURE [dbo].[USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_24_ExisteAlumnoPorOblID]	
	@I_ProcedenciaID tinyint,
	@I_RowID	  int = NULL,
	@B_Resultado  bit output,
	@T_Message	  nvarchar(4000) OUTPUT	
AS
/*
	declare @I_RowID	  int = NULL,
			@I_ProcedenciaID	tinyint = 3,
			@B_Resultado  bit,
			@T_Message	  nvarchar(4000)
	exec USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_24_ExisteAlumnoPorOblID @I_ProcedenciaID, @I_RowID, @B_Resultado output, @T_Message output
	select @B_Resultado as resultado, @T_Message as mensaje
*/
BEGIN
	DECLARE @I_Observados int = 0
	DECLARE @D_FecProceso datetime = GETDATE() 
	DECLARE @I_ObservID int = 24
	DECLARE @I_TablaID int = 5

	BEGIN TRANSACTION
	BEGIN TRY 

		UPDATE	ec_obl
		SET		B_Migrable = 0,
				D_FecEvalua = @D_FecProceso
		FROM	TR_Ec_Obl ec_obl
				LEFT JOIN TR_Alumnos ec_alu ON ec_obl.Cod_alu = ec_alu.C_CodAlu and ec_obl.Cod_rc = ec_alu.C_RcCod
		WHERE	ec_alu.I_RowID is null
				AND ec_obl.I_RowID =  @I_RowID

					
		MERGE TI_ObservacionRegistroTabla AS TRG
		USING 	(SELECT	@I_ObservID AS I_ObservID, @I_TablaID AS I_TablaID, ec_obl.I_RowID AS I_FilaTablaID, @D_FecProceso AS D_FecRegistro 
				   FROM	TR_Ec_Obl ec_obl
						LEFT JOIN TR_Alumnos ec_alu ON ec_obl.Cod_alu = ec_alu.C_CodAlu and ec_obl.Cod_rc = ec_alu.C_RcCod
				  WHERE	ec_alu.I_RowID is null
						AND ec_obl.I_RowID =  @I_RowID) AS SRC
		ON TRG.I_ObservID = SRC.I_ObservID AND TRG.I_TablaID = SRC.I_TablaID AND TRG.I_FilaTablaID = SRC.I_FilaTablaID
		WHEN MATCHED THEN
			UPDATE SET D_FecRegistro = SRC.D_FecRegistro
		WHEN NOT MATCHED BY TARGET THEN
			INSERT (I_ObservID, I_TablaID, I_FilaTablaID, D_FecRegistro, I_ProcedenciaID)
			VALUES (SRC.I_ObservID, SRC.I_TablaID, SRC.I_FilaTablaID, SRC.D_FecRegistro, @I_ProcedenciaID);


		UPDATE OBS
		   SET D_FecResuelto = @D_FecProceso,
			   B_Resuelto = 1
		  FROM TI_ObservacionRegistroTabla OBS
			   INNER JOIN (SELECT ec_obl.*, ec_alu.I_RowID AS I_AluRowID  
							 FROM TR_Ec_Obl ec_obl
								  LEFT JOIN TR_Alumnos ec_alu ON ec_obl.Cod_alu = ec_alu.C_CodAlu 
																 AND ec_obl.Cod_rc = ec_alu.C_RcCod
							WHERE ec_alu.I_RowID IS NOT NULL
								  AND ec_obl.I_RowID =  @I_RowID) OBL 
						  ON OBS.I_FilaTablaID = OBL.I_RowID
							 AND OBS.I_ProcedenciaID = OBL.I_ProcedenciaID
		 WHERE OBS.I_ObservID = @I_ObservID 
			   AND OBS.I_TablaID = @I_TablaID

		SET @I_Observados = (SELECT COUNT(*) FROM TI_ObservacionRegistroTabla 
							  WHERE I_ObservID = @I_ObservID AND I_TablaID = @I_TablaID
									AND I_FilaTablaID = @I_RowID AND I_ProcedenciaID = @I_ProcedenciaID) 
											   

		COMMIT TRANSACTION				
		SET @B_Resultado = 1
		SET @T_Message = '{ ' +
							 'Type: "summary", ' + 
							 'Title: "Observados", ' + 
							 'Value: ' + CAST(@I_Observados AS varchar) +
						  '}' 

	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION
		SET @B_Resultado = 0
		SET @T_Message = '[{ ' +
							 'Type: "error", ' + 
							 'Title: "Error", ' + 
							 'Value: "' + ERROR_MESSAGE() + ' (Linea: ' + CAST(ERROR_LINE() AS varchar(11)) + ')."'  +
						  '}]' 
	END CATCH

END
GO





IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_U_ValidarAnioEnCabeceraObligacion')
	DROP PROCEDURE [dbo].[USP_U_ValidarAnioEnCabeceraObligacion]
GO

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_26_AnioNumerico')
	DROP PROCEDURE [dbo].[USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_26_AnioNumerico]
GO

CREATE PROCEDURE [dbo].[USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_26_AnioNumerico]	
	@I_ProcedenciaID tinyint,
	@I_RowID	  int = NULL,
	@B_Resultado  bit output,
	@T_Message	  nvarchar(4000) OUTPUT	
AS
/*
	declare @I_ProcedenciaID	tinyint = 3, 
			@I_RowID	  int = NULL,
			@B_Resultado  bit,
			@T_Message	  nvarchar(4000)
	exec USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_26_AnioNumerico @I_ProcedenciaID, @I_RowID, @B_Resultado output, @T_Message output
	select @B_Resultado as resultado, @T_Message as mensaje
*/
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
		WHERE	ISNUMERIC(Ano) = 0
				AND I_ProcedenciaID = @I_ProcedenciaID
				AND I_RowID = IIF(@I_RowID IS NULL, I_RowID, @I_RowID)
				
		MERGE TI_ObservacionRegistroTabla AS TRG
		USING 	(SELECT	@I_ObservID AS I_ObservID, @I_TablaID AS I_TablaID, I_RowID AS I_FilaTablaID, @D_FecProceso AS D_FecRegistro 
				 FROM	TR_Ec_Obl 
				 WHERE	ISNUMERIC(Ano) = 0 
						AND I_ProcedenciaID = @I_ProcedenciaID
						AND I_RowID = IIF(@I_RowID IS NULL, I_RowID, @I_RowID)
				) AS SRC
		ON TRG.I_ObservID = SRC.I_ObservID AND TRG.I_TablaID = SRC.I_TablaID AND TRG.I_FilaTablaID = SRC.I_FilaTablaID
		WHEN MATCHED THEN
			UPDATE SET D_FecRegistro = SRC.D_FecRegistro
		WHEN NOT MATCHED BY TARGET THEN
			INSERT (I_ObservID, I_TablaID, I_FilaTablaID, D_FecRegistro, I_ProcedenciaID)
			VALUES (SRC.I_ObservID, SRC.I_TablaID, SRC.I_FilaTablaID, SRC.D_FecRegistro, @I_ProcedenciaID);


		UPDATE OBS
		   SET D_FecResuelto = @D_FecProceso,
			   B_Resuelto = 1
		  FROM TI_ObservacionRegistroTabla OBS
			   INNER JOIN (SELECT * FROM TR_Ec_Obl WHERE ISNUMERIC(Ano) = 1) OBL
						   ON OBS.I_FilaTablaID = OBL.I_RowID
							  AND OBS.I_ProcedenciaID = OBL.I_ProcedenciaID
		 WHERE OBS.I_ObservID = @I_ObservID 
			   AND OBS.I_TablaID = @I_TablaID


		SET @I_Observados = (SELECT COUNT(*) FROM TI_ObservacionRegistroTabla 
											WHERE I_ObservID = @I_ObservID AND I_TablaID = @I_TablaID
												  AND I_ProcedenciaID = @I_ProcedenciaID
												  AND I_FilaTablaID = IIF(@I_RowID IS NULL, I_FilaTablaID, @I_RowID)) 

		SELECT @I_Observados as cant_obs, @D_FecProceso as fec_proceso

		COMMIT TRANSACTION				
		SET @B_Resultado = 1
		SET @T_Message = '{ ' +
							 'Type: "summary", ' + 
							 'Title: "Observados", ' + 
							 'Value: ' + CAST(@I_Observados AS varchar) +
						 '}' 
	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION
		SET @B_Resultado = 0
		SET @T_Message = '[{ ' +
							 'Type: "error", ' + 
							 'Title: "Error", ' + 
							 'Value: "' + ERROR_MESSAGE() + ' (Linea: ' + CAST(ERROR_LINE() AS varchar(11)) + ')."'  +
						  '}]' 
	END CATCH
END
GO


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_U_ValidarPeriodoEnCabeceraObligacion')
	DROP PROCEDURE [dbo].[USP_U_ValidarPeriodoEnCabeceraObligacion]
GO

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_27_Periodo')
	DROP PROCEDURE [dbo].[USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_27_Periodo]
GO

CREATE PROCEDURE [dbo].[USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_27_Periodo]	
	@I_ProcedenciaID tinyint,
	@T_Anio		  varchar(4) = NULL,
	@I_RowID	  int = NULL,
	@B_Resultado  bit output,
	@T_Message	  nvarchar(4000) OUTPUT	
AS
/*
	declare	@I_ProcedenciaID	tinyint = 3, 
			@T_Anio		  varchar(4) = '2010',
			@I_RowID	  int = NULL,
			@B_Resultado  bit,
			@T_Message	  nvarchar(4000)
	exec USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_27_Periodo @I_ProcedenciaID, @T_Anio, @I_RowID, @B_Resultado output, @T_Message output
	select @B_Resultado as resultado, @T_Message as mensaje
*/
BEGIN
	DECLARE @I_Observados int = 0
	DECLARE @I_TablaID int = 5

	BEGIN TRANSACTION
	BEGIN TRY 
		DECLARE @D_FecProceso datetime = GETDATE() 
		DECLARE @I_ObservID int = 27

		UPDATE	TR_Ec_Obl
		SET		B_Migrable = 0,
				D_FecEvalua = @D_FecProceso
		WHERE	I_Periodo IS NULL OR P = ''
				AND I_ProcedenciaID = @I_ProcedenciaID
			    AND Ano = @T_Anio
				AND I_RowID = IIF(@I_RowID IS NULL, I_RowID, @I_RowID) 
				
		MERGE TI_ObservacionRegistroTabla AS TRG
		USING 	(SELECT	@I_ObservID AS I_ObservID, @I_TablaID AS I_TablaID, I_RowID AS I_FilaTablaID, @D_FecProceso AS D_FecRegistro, I_ProcedenciaID
				   FROM TR_Ec_Obl
				  WHERE	I_Periodo IS NULL OR P = ''
						AND I_ProcedenciaID = @I_ProcedenciaID
						AND Ano = @T_Anio
						AND I_RowID = IIF(@I_RowID IS NULL, I_RowID, @I_RowID) 
				) AS SRC
		ON TRG.I_ObservID = SRC.I_ObservID AND TRG.I_TablaID = SRC.I_TablaID AND TRG.I_FilaTablaID = SRC.I_FilaTablaID
		WHEN MATCHED AND SRC.I_ProcedenciaID = @I_ProcedenciaID THEN
			UPDATE SET D_FecRegistro = SRC.D_FecRegistro
		WHEN NOT MATCHED BY TARGET AND SRC.I_ProcedenciaID = @I_ProcedenciaID THEN
			INSERT (I_ObservID, I_TablaID, I_FilaTablaID, D_FecRegistro, I_ProcedenciaID)
			VALUES (SRC.I_ObservID, SRC.I_TablaID, SRC.I_FilaTablaID, SRC.D_FecRegistro, @I_ProcedenciaID);


		UPDATE OBS
		   SET D_FecResuelto = @D_FecProceso,
			   B_Resuelto = 1
		  FROM TI_ObservacionRegistroTabla OBS
			   INNER JOIN (SELECT * FROM TR_Ec_Obl 
							WHERE I_Periodo IS NOT NULL AND P <> ''
								  AND Ano = @T_Anio
								  AND I_RowID = IIF(@I_RowID IS NULL, I_RowID, @I_RowID)
						  ) OBL 
						  ON OBS.I_FilaTablaID = OBL.I_RowID
							 AND OBS.I_ProcedenciaID = OBL.I_ProcedenciaID
		 WHERE OBS.I_ObservID = @I_ObservID 
			   AND OBS.I_TablaID = @I_TablaID
			

		SET @I_Observados = (SELECT COUNT(*) FROM (SELECT * FROM TR_Ec_Obl WHERE Ano = @T_Anio) OBL
												  INNER JOIN TI_ObservacionRegistroTabla OBS ON OBS.I_FilaTablaID = OBL.I_RowID
																								AND OBS.I_ProcedenciaID = OBL.I_ProcedenciaID
							 WHERE I_ObservID = @I_ObservID AND I_TablaID = @I_TablaID 
								   AND OBS.I_ProcedenciaID = @I_ProcedenciaID
								   AND I_FilaTablaID = IIF(@I_RowID IS NULL, I_FilaTablaID, @I_RowID))

		SELECT @I_Observados as cant_obs, @D_FecProceso as fec_proceso

		COMMIT TRANSACTION
					
		SET @B_Resultado = 1
		SET @T_Message = '{ ' +
							 'Type: "summary", ' + 
							 'Title: "Observados", ' + 
							 'Value: ' + CAST(@I_Observados AS varchar) +
						 '}' 
	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION
		SET @B_Resultado = 0
		SET @T_Message = '[{ ' +
							 'Type: "error", ' + 
							 'Title: "Error", ' + 
							 'Value: "' + ERROR_MESSAGE() + ' (Linea: ' + CAST(ERROR_LINE() AS varchar(11)) + ')."'  +
						  '}]' 
	END CATCH
END
GO



IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_U_ValidarDetalleObligacionConceptoPago')
	DROP PROCEDURE [dbo].[USP_U_ValidarDetalleObligacionConceptoPago]
GO

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_Obligaciones_ObligacionDet_MigracionTP_U_Validar_35_ConceptoPago')
	DROP PROCEDURE [dbo].[USP_Obligaciones_ObligacionDet_MigracionTP_U_Validar_35_ConceptoPago]
GO

CREATE PROCEDURE [dbo].[USP_Obligaciones_ObligacionDet_MigracionTP_U_Validar_35_ConceptoPago]	
	@I_ProcedenciaID tinyint,
	@T_Anio			varchar(4) = NULL,
	@B_Resultado	bit output,
	@T_Message		nvarchar(4000) OUTPUT	
AS
/*
	declare @I_ProcedenciaID	tinyint = 1, 
			@T_Anio		  varchar(4) = '2010',
			@B_Resultado  bit,
			@T_Message    nvarchar(4000)
	exec USP_Obligaciones_ObligacionDet_MigracionTP_U_Validar_35_ConceptoPago @I_ProcedenciaID, @T_Anio, @B_Resultado output, @T_Message output
	select @B_Resultado as resultado, @T_Message as mensaje
*/
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
				AND Det.Ano = @T_Anio

					
		MERGE TI_ObservacionRegistroTabla AS TRG
		USING 	(SELECT	@I_ObservID AS I_ObservID, @I_TablaID AS I_TablaID, I_RowID AS I_FilaTablaID, @D_FecProceso AS D_FecRegistro 
				 FROM TR_Ec_Det Det
						LEFT JOIN (SELECT Id_cp, I_ProcedenciaID FROM TR_Cp_Pri) Pri ON Det.Concepto = Pri.Id_cp AND Det.I_ProcedenciaID = Pri.I_ProcedenciaID
				 WHERE	Pri.Id_cp is null
						AND Det.I_ProcedenciaID = @I_ProcedenciaID
						AND Det.Ano = @T_Anio
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


		SELECT @I_Observados as cant_obs_det, @I_ObservadosObl as cant_obs_obl, @D_FecProceso as fec_proceso

		COMMIT TRANSACTION
					
		SET @B_Resultado = 1
		SET @T_Message = '{ ' +
							 'Type: "summary", ' + 
							 'Title: "Observados", ' + 
							 'Value: ' + CAST(@I_Observados AS varchar) +
						 '}' 
	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION
		SET @B_Resultado = 0
		SET @T_Message = '[{ ' +
							 'Type: "error", ' + 
							 'Title: "Error", ' + 
							 'Value: "' + ERROR_MESSAGE() + ' (Linea: ' + CAST(ERROR_LINE() AS varchar(11)) + ')."'  +
						  '}]' 
	END CATCH
END
GO




IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_39_DetalleObservado')
	DROP PROCEDURE [dbo].[USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_39_DetalleObservado]
GO

CREATE PROCEDURE [dbo].[USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_39_DetalleObservado]
	@I_ProcedenciaID tinyint,
	@T_Anio			varchar(4) = NULL,
	@B_Resultado	bit output,
	@T_Message		nvarchar(4000) OUTPUT	
AS
/*
	declare @I_ProcedenciaID	tinyint = 3, 
			@T_Anio		  varchar(4) = '2005',
			@B_Resultado  bit,
			@T_Message    nvarchar(4000)
	exec USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_39_DetalleObservado @I_ProcedenciaID, @T_Anio, @B_Resultado output, @T_Message output
	select @B_Resultado as resultado, @T_Message as mensaje
*/
BEGIN
	DECLARE @I_Observados int = 0
	DECLARE @I_ObservadosObl int = 0
	DECLARE @D_FecProceso datetime = GETDATE() 
	DECLARE @I_ObservID int = 39
	DECLARE @I_TablaID int = 5

	BEGIN TRANSACTION
	BEGIN TRY
		COMMIT TRANSACTION

		UPDATE	Obl
		SET		B_Migrable = 0,
				D_FecEvalua = @D_FecProceso
		FROM    TR_Ec_Obl Obl
				INNER JOIN TR_Ec_Det Det ON Obl.I_RowID = Det.I_OblRowID
		WHERE	Det.B_Migrable = 0
				AND Obl.Ano = @T_Anio
				AND Det.Eliminado = 0
				AND Det.I_ProcedenciaID = @I_ProcedenciaID
					
		MERGE	TI_ObservacionRegistroTabla AS TRG
		USING 	(SELECT	@I_ObservID AS I_ObservID, @I_TablaID AS I_TablaID, Obl.I_RowID AS I_FilaTablaID, @D_FecProceso AS D_FecRegistro 
				 FROM   TR_Ec_Obl Obl
						INNER JOIN TR_Ec_Det Det ON Obl.I_RowID = Det.I_OblRowID
				 WHERE	Det.B_Migrable = 0
						AND Obl.Ano = @T_Anio
						AND Det.Eliminado = 0
						AND Det.I_ProcedenciaID = @I_ProcedenciaID
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

		SET @B_Resultado = 1
		SET @T_Message = '{ ' +
							 'Type: "summary", ' + 
							 'Title: "Observados", ' + 
							 'Value: ' + CAST(@I_ObservadosObl AS varchar) +
						 '}' 
	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION
		SET @B_Resultado = 0
		SET @T_Message = '[{ ' +
							 'Type: "error", ' + 
							 'Title: "Error", ' + 
							 'Value: "' + ERROR_MESSAGE() + ' (Linea: ' + CAST(ERROR_LINE() AS varchar(11)) + ')."'  +
						  '}]' 
	END CATCH
END
GO




IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_40_ObligacionSinDetalle')
	DROP PROCEDURE [dbo].[USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_40_ObligacionSinDetalle]
GO

CREATE PROCEDURE [dbo].[USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_40_ObligacionSinDetalle]
	@I_ProcedenciaID tinyint,
	@T_Anio			varchar(4) = NULL,
	@B_Resultado	bit output,
	@T_Message		nvarchar(4000) OUTPUT	
AS
/*
	declare @I_ProcedenciaID	tinyint = 2, 
			@T_Anio		  varchar(4) = '2019',
			@B_Resultado  bit,
			@T_Message    nvarchar(4000)
	exec USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_40_ObligacionSinDetalle @I_ProcedenciaID, @T_Anio, @B_Resultado output, @T_Message output
	select @B_Resultado as resultado, @T_Message as mensaje
*/
BEGIN
	DECLARE @I_Observados int = 0
	DECLARE @I_ObservadosObl int = 0
	DECLARE @D_FecProceso datetime = GETDATE() 
	DECLARE @I_ObservID int = 40
	DECLARE @I_TablaID int = 5

	BEGIN TRANSACTION
	BEGIN TRY
		COMMIT TRANSACTION

		UPDATE	Obl
		SET		B_Migrable = 0,
				D_FecEvalua = @D_FecProceso
		FROM    TR_Ec_Obl Obl
				LEFT JOIN TR_Ec_Det Det ON Obl.I_RowID = Det.I_OblRowID
		WHERE	Obl.Ano = @T_Anio
				AND Obl.I_ProcedenciaID = @I_ProcedenciaID
				AND Det.I_OblRowID IS NULL
					
		MERGE	TI_ObservacionRegistroTabla AS TRG
		USING 	(SELECT	@I_ObservID AS I_ObservID, @I_TablaID AS I_TablaID, Obl.I_RowID AS I_FilaTablaID, @D_FecProceso AS D_FecRegistro 
				   FROM TR_Ec_Obl Obl
						LEFT JOIN TR_Ec_Det Det ON Obl.I_RowID = Det.I_OblRowID
				  WHERE	Obl.Ano = @T_Anio
						AND Obl.I_ProcedenciaID = @I_ProcedenciaID
						AND Det.I_OblRowID IS NULL
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

		SET @B_Resultado = 1
		SET @T_Message = '{ ' +
							 'Type: "summary", ' + 
							 'Title: "Observados", ' + 
							 'Value: ' + CAST(@I_ObservadosObl AS varchar) +
						 '}' 
	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION
		SET @B_Resultado = 0
		SET @T_Message = '[{ ' +
							 'Type: "error", ' + 
							 'Title: "Error", ' + 
							 'Value: "' + ERROR_MESSAGE() + ' (Linea: ' + CAST(ERROR_LINE() AS varchar(11)) + ')."'  +
						  '}]' 
	END CATCH
END
GO



IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_U_ValidarProcedenciaObligacionCuotaPago')
	DROP PROCEDURE [dbo].[USP_U_ValidarProcedenciaObligacionCuotaPago]
GO

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_34_ProcedenciaCuotaPago')
	DROP PROCEDURE [dbo].[USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_34_ProcedenciaCuotaPago]
GO

CREATE PROCEDURE [dbo].[USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_34_ProcedenciaCuotaPago]	
	@I_ProcedenciaID tinyint,
	@T_Anio			 varchar(4) = NULL,
	@B_Resultado  bit output,
	@T_Message	  nvarchar(4000) OUTPUT	
AS
/*
	Declare	@I_ProcedenciaID	tinyint = 2, 
			@T_Anio				varchar(4) = 2016,
			@B_Resultado		bit,
			@T_Message			nvarchar(4000)
	exec USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_34_ProcedenciaCuotaPago @I_ProcedenciaID, @T_Anio, @B_Resultado output, @T_Message output
	select @B_Resultado as resultado, @T_Message as mensaje
*/
BEGIN
	DECLARE @I_Observados int = 0
	DECLARE @D_FecProceso datetime = GETDATE() 
	DECLARE @I_ObservID int = 34
	DECLARE @I_TablaID int = 5

	BEGIN TRANSACTION
	BEGIN TRY
		
		SELECT Ano, P, Cod_alu, Cod_rc, obl.Cuota_pago, obl.Fch_venc, Tipo_oblig, Monto, obl.I_RowID
		INTO  #temp_obl_procedencia_dif_cuota_anio
		FROM  TR_Ec_Obl obl
			  LEFT JOIN TR_Cp_Des cp ON obl.Cuota_pago = cp.Cuota_pago 
										AND obl.I_ProcedenciaID = cp.I_ProcedenciaID
										AND cp.Eliminado = 0
		WHERE obl.I_ProcedenciaID = @I_ProcedenciaID
			  AND Ano = @T_Anio 
			  AND cp.I_RowID is null

		UPDATE	OBL
		SET		B_Migrable = 0,
				D_FecEvalua = @D_FecProceso
		FROM	TR_Ec_Obl OBL 
				INNER JOIN #temp_obl_procedencia_dif_cuota_anio TMP ON OBL.I_RowID = TMP.I_RowID
		WHERE	I_ProcedenciaID = @I_ProcedenciaID
				AND OBL.Ano = @T_Anio 

		MERGE TI_ObservacionRegistroTabla AS TRG
		USING (SELECT @I_ObservID AS I_ObservID, @I_TablaID AS I_TablaID, OBL.I_RowID AS I_FilaTablaID, @D_FecProceso AS D_FecRegistro 
			     FROM TR_Ec_Obl OBL 
					  INNER JOIN #temp_obl_procedencia_dif_cuota_anio TMP ON OBL.I_RowID = TMP.I_RowID
				WHERE I_ProcedenciaID = @I_ProcedenciaID
					  AND OBL.Ano = @T_Anio 
			  ) AS SRC
		ON TRG.I_ObservID = SRC.I_ObservID AND TRG.I_TablaID = SRC.I_TablaID AND TRG.I_FilaTablaID = SRC.I_FilaTablaID
		WHEN MATCHED THEN
			UPDATE SET D_FecRegistro = SRC.D_FecRegistro
		WHEN NOT MATCHED BY TARGET THEN
			INSERT (I_ObservID, I_TablaID, I_FilaTablaID, D_FecRegistro, I_ProcedenciaID)
			VALUES (SRC.I_ObservID, SRC.I_TablaID, SRC.I_FilaTablaID, SRC.D_FecRegistro, @I_ProcedenciaID)
		WHEN NOT MATCHED BY SOURCE AND TRG.I_ObservID = @I_ObservID AND TRG.I_ProcedenciaID = @I_ProcedenciaID THEN
			DELETE;

		SET @I_Observados = (SELECT COUNT(*) FROM TI_ObservacionRegistroTabla OBS INNER JOIN 
												  TR_Ec_Obl OBL ON OBS.I_FilaTablaID = OBL.I_RowID 
																	AND OBL.I_ProcedenciaID = OBS.I_ProcedenciaID
																	AND OBS.I_TablaID = @I_TablaID 
							  WHERE I_ObservID = @I_ObservID AND
									OBL.Ano = @T_Anio AND 
									OBS.I_ProcedenciaID = @I_ProcedenciaID)

		SELECT @I_Observados as cant_obs, @D_FecProceso as fec_proceso

		COMMIT TRANSACTION				
		SET @B_Resultado = 1
		SET @T_Message = '{ ' +
							 'Type: "summary", ' + 
							 'Title: "Observados", ' + 
							 'Value: ' + CAST(@I_Observados AS varchar) +
						 '}' 
	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION
		SET @B_Resultado = 0
		SET @T_Message = '[{ ' +
							 'Type: "error", ' + 
							 'Title: "Error", ' + 
							 'Value: "' + ERROR_MESSAGE() + ' (Linea: ' + CAST(ERROR_LINE() AS varchar(10)) + ')."'  +
						  '}]' 
	END CATCH
END
GO



IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_U_ValidarObligacionCuotaPagoMigrada')
	DROP PROCEDURE [dbo].[USP_U_ValidarObligacionCuotaPagoMigrada]
GO

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_32_ValidarObligacionCuotaPagoMigrada')
	DROP PROCEDURE [dbo].[USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_32_ValidarObligacionCuotaPagoMigrada]
GO

CREATE PROCEDURE [dbo].[USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_32_ValidarObligacionCuotaPagoMigrada]	
	@I_ProcedenciaID tinyint,
	@T_Anio			 varchar(4) = NULL,
	@B_Resultado  bit output,
	@T_Message	  nvarchar(4000) OUTPUT	
AS
/*
	declare	@I_ProcedenciaID	tinyint = 2, 
			@T_Anio				varchar(4) = 2016,
			@B_Resultado		bit,
			@T_Message			nvarchar(4000)
	exec USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_32_ValidarObligacionCuotaPagoMigrada @I_ProcedenciaID, @T_Anio, @B_Resultado output, @T_Message output
	select @B_Resultado as resultado, @T_Message as mensaje
*/
BEGIN
	DECLARE @I_Observados int = 0
	DECLARE @D_FecProceso datetime = GETDATE() 
	DECLARE @I_ObservID int = 32
	DECLARE @I_TablaID int = 5

	BEGIN TRANSACTION
	BEGIN TRY

		SELECT Ano, P, Cod_alu, Cod_rc, obl.Cuota_pago, obl.Fch_venc, Tipo_oblig, Monto, obl.I_RowID
		INTO  #temp_obl_cuota_no_migrada
		FROM  TR_Ec_Obl obl
			  LEFT JOIN TR_Cp_Des cp ON obl.Cuota_pago = cp.Cuota_pago 
										AND obl.I_ProcedenciaID = cp.I_ProcedenciaID
										AND cp.B_Migrado = 1
		WHERE obl.I_ProcedenciaID = @I_ProcedenciaID
			  AND Ano = @T_Anio
			  AND cp.I_RowID is null

		UPDATE	OBL
		SET		B_Migrable = 0,
				D_FecEvalua = @D_FecProceso
		 FROM	TR_Ec_Obl OBL
				INNER JOIN #temp_obl_cuota_no_migrada TMP ON OBL.I_RowID = TMP.I_RowID
		WHERE	I_ProcedenciaID = @I_ProcedenciaID
				AND OBL.Ano = @T_Anio
								  
		MERGE TI_ObservacionRegistroTabla AS TRG
		USING 	(SELECT	@I_ObservID AS I_ObservID, @I_TablaID AS I_TablaID, OBL.I_RowID AS I_FilaTablaID, @D_FecProceso AS D_FecRegistro 
				   FROM	TR_Ec_Obl OBL
						INNER JOIN #temp_obl_cuota_no_migrada TMP ON OBL.I_RowID = TMP.I_RowID
				  WHERE	I_ProcedenciaID = @I_ProcedenciaID
						AND OBL.Ano = @T_Anio
				 ) AS SRC
		ON TRG.I_ObservID = SRC.I_ObservID AND TRG.I_TablaID = SRC.I_TablaID AND TRG.I_FilaTablaID = SRC.I_FilaTablaID
		WHEN MATCHED THEN
			UPDATE SET D_FecRegistro = SRC.D_FecRegistro
		WHEN NOT MATCHED BY TARGET THEN
			INSERT (I_ObservID, I_TablaID, I_FilaTablaID, D_FecRegistro, I_ProcedenciaID)
			VALUES (SRC.I_ObservID, SRC.I_TablaID, SRC.I_FilaTablaID, SRC.D_FecRegistro, @I_ProcedenciaID)
		WHEN NOT MATCHED BY SOURCE AND TRG.I_ObservID = @I_ObservID AND TRG.I_ProcedenciaID = @I_ProcedenciaID THEN
			DELETE;

		SET @I_Observados = (SELECT COUNT(*) FROM TI_ObservacionRegistroTabla OBS INNER JOIN 
												  TR_Ec_Obl OBL ON OBS.I_FilaTablaID = OBL.I_RowID 
																	AND OBL.I_ProcedenciaID = OBS.I_ProcedenciaID
																	AND OBS.I_TablaID = @I_TablaID 
							  WHERE I_ObservID = @I_ObservID AND
									OBL.Ano = @T_Anio AND 
									OBS.I_ProcedenciaID = @I_ProcedenciaID)

		SELECT @I_Observados as cant_obs, @D_FecProceso as fec_proceso

		COMMIT TRANSACTION				
		SET @B_Resultado = 1
		SET @T_Message = '{ ' +
							 'Type: "summary", ' + 
							 'Title: "Observados", ' + 
							 'Value: ' + CAST(@I_Observados AS varchar) +
						 '}' 
	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION
		SET @B_Resultado = 0
		SET @T_Message = '[{ ' +
							 'Type: "error", ' + 
							 'Title: "Error", ' + 
							 'Value: "' + ERROR_MESSAGE() + ' (Linea: ' + CAST(ERROR_LINE() AS varchar(11)) + ')."'  +
						  '}]' 
	END CATCH
END
GO


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_U_ValidarFechaVencimientoCuotaObligacion')
	DROP PROCEDURE [dbo].[USP_U_ValidarFechaVencimientoCuotaObligacion]
GO

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_28_FechaVencimientoCuota')
	DROP PROCEDURE [dbo].[USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_28_FechaVencimientoCuota]
GO

CREATE PROCEDURE [dbo].[USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_28_FechaVencimientoCuota]	
	@I_ProcedenciaID tinyint,
	@T_Anio			 varchar(4) = NULL,
	@B_Resultado  bit OUTPUT,
	@T_Message	  nvarchar(4000) OUTPUT	
AS
/*
	declare	@I_ProcedenciaID	tinyint = 2, 
			@T_Anio				varchar(4) = 2016,
			@B_Resultado		bit,
			@T_Message			nvarchar(4000)
	exec USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_28_FechaVencimientoCuota @I_ProcedenciaID, @T_Anio, @B_Resultado output, @T_Message output
	select @B_Resultado as resultado, @T_Message as mensaje
*/
BEGIN
	DECLARE @I_Observados int = 0
	DECLARE @D_FecProceso datetime = GETDATE() 
	DECLARE @I_ObservID int = 28
	DECLARE @I_TablaID int = 5

	BEGIN TRANSACTION
	BEGIN TRY

		SELECT Ano, P, Cod_alu, Cod_rc, obl.Cuota_pago, obl.Fch_venc, Tipo_oblig, Monto, obl.I_RowID
		INTO  #temp_obl_fecVenc_dif_cuota_anio
		FROM  TR_Ec_Obl obl
			  LEFT JOIN TR_Cp_Des cp ON obl.Cuota_pago = cp.Cuota_pago 
										AND obl.I_ProcedenciaID = cp.I_ProcedenciaID
										AND cp.Eliminado = 0
		WHERE obl.I_ProcedenciaID = @I_ProcedenciaID
			  AND Ano = @T_Anio
			  AND obl.Fch_venc <> cp.Fch_venc


		UPDATE	TRG_1
		SET		B_Migrable = 0,
				D_FecEvalua = @D_FecProceso
		FROM	TR_Ec_Obl TRG_1
				INNER JOIN #temp_obl_fecVenc_dif_cuota_anio SRC_1 
				ON TRG_1.I_RowID = SRC_1.I_RowID
		WHERE	TRG_1.Ano = @T_Anio
				AND TRG_1.B_Correcto = 0

					
		MERGE TI_ObservacionRegistroTabla AS TRG
		USING (SELECT @I_ObservID AS I_ObservID, @I_TablaID AS I_TablaID, TRG_1.I_RowID AS I_FilaTablaID, @D_FecProceso AS D_FecRegistro 
				 FROM TR_Ec_Obl TRG_1
					  INNER JOIN #temp_obl_fecVenc_dif_cuota_anio SRC_1 
								ON TRG_1.I_RowID = SRC_1.I_RowID
				 WHERE	TRG_1.Ano = @T_Anio
						AND TRG_1.B_Correcto = 0
				 ) AS SRC
		ON TRG.I_ObservID = SRC.I_ObservID AND TRG.I_TablaID = SRC.I_TablaID AND TRG.I_FilaTablaID = SRC.I_FilaTablaID
		WHEN MATCHED THEN
			UPDATE SET D_FecRegistro = SRC.D_FecRegistro
		WHEN NOT MATCHED BY TARGET THEN
			INSERT (I_ObservID, I_TablaID, I_FilaTablaID, D_FecRegistro, I_ProcedenciaID)
			VALUES (SRC.I_ObservID, SRC.I_TablaID, SRC.I_FilaTablaID, SRC.D_FecRegistro, @I_ProcedenciaID)
		WHEN NOT MATCHED BY SOURCE AND TRG.I_ObservID = @I_ObservID AND TRG.I_ProcedenciaID = @I_ProcedenciaID 
								   AND TRG.I_TablaID = @I_TablaID THEN
			DELETE;

		SET @I_Observados = (SELECT COUNT(*) FROM TI_ObservacionRegistroTabla OBS INNER JOIN 
												  TR_Ec_Obl OBL ON OBS.I_FilaTablaID = OBL.I_RowID 
																	AND OBL.I_ProcedenciaID = OBS.I_ProcedenciaID
																	AND OBS.I_TablaID = @I_TablaID 
							  WHERE I_ObservID = @I_ObservID AND
									OBL.Ano = @T_Anio AND
									OBS.I_ProcedenciaID = @I_ProcedenciaID)

		SELECT @I_Observados as cant_obs, @D_FecProceso as fec_proceso

		COMMIT TRANSACTION				
		SET @B_Resultado = 1
		SET @T_Message = '{ ' +
							 'Type: "summary", ' + 
							 'Title: "Observados ", ' + 
							 'Value: ' + CAST(@I_Observados AS varchar) +
						 '}' 
	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION
		SET @B_Resultado = 0
		SET @T_Message = '[{ ' +
							 'Type: "error", ' + 
							 'Title: "Error", ' + 
							 'Value: "' + ERROR_MESSAGE() + ' (Linea: ' + CAST(ERROR_LINE() AS varchar(11)) + ')."'  +
						  '}]' 
	END CATCH
END
GO


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_U_ValidarDetalleObligacion')
	DROP PROCEDURE [dbo].[USP_U_ValidarDetalleObligacion]
GO

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_Obligaciones_ObligacionDet_MigracionTP_U_Validar_25_ObligacionCabID')
	DROP PROCEDURE [dbo].[USP_Obligaciones_ObligacionDet_MigracionTP_U_Validar_25_ObligacionCabID]
GO


CREATE PROCEDURE [dbo].[USP_Obligaciones_ObligacionDet_MigracionTP_U_Validar_25_ObligacionCabID]	
(
	@I_ProcedenciaID tinyint,
	@T_Anio		  varchar(4),
	@B_Resultado  bit output,
	@T_Message	  nvarchar(4000) OUTPUT	
)
AS
/*
  declare	@B_Resultado  bit,
			@I_ProcedenciaID	tinyint = 2,
	    	@T_Anio				varchar(4) = '2016',
			@T_Message			nvarchar(4000)
  exec USP_Obligaciones_ObligacionDet_MigracionTP_U_Validar_25_ObligacionCabID @I_ProcedenciaID, @T_Anio, @B_Resultado output, @T_Message output
  select @B_Resultado as resultado, @T_Message as mensaje
*/
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
				AND Ano = @T_Anio 
				AND TR_Ec_Det.I_ProcedenciaID = @I_ProcedenciaID
					
		MERGE TI_ObservacionRegistroTabla AS TRG
		USING (SELECT @I_ObservID AS I_ObservID, @I_TablaID AS I_TablaID, I_RowID AS I_FilaTablaID, @D_FecProceso AS D_FecRegistro 
				 FROM TR_Ec_Det
				WHERE TIPO_OBLIG IS NOT NULL
					  AND I_OblRowID IS NULL
					  AND Ano = @T_Anio 
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


		SELECT @I_Observados as cant_obs_det, @D_FecProceso as fec_proceso

		SET @B_Resultado = 1
		SET @T_Message = '{ ' +
							 'Type: "summary", ' + 
							 'Title: "Observados sin OblId", ' + 
							 'Value: ' + CAST(@I_Observados AS varchar) +
						 '}' 

		COMMIT TRANSACTION;
	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION
		SET @B_Resultado = 0
		SET @T_Message = '[{ ' +
							 'Type: "error", ' + 
							 'Title: "Error", ' + 
							 'Value: "' + ERROR_MESSAGE() + ' (Linea: ' + CAST(ERROR_LINE() AS varchar(11)) + ')."'  +
						  '}]' 
	END CATCH
END
GO



IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_36_ConceptoPagoMigrado')
	DROP PROCEDURE [dbo].[USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_36_ConceptoPagoMigrado]
GO

CREATE PROCEDURE [dbo].USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_36_ConceptoPagoMigrado	
	@I_ProcedenciaID tinyint,
	@T_Anio		  varchar(4),
	@B_Resultado  bit output,
	@T_Message	  nvarchar(4000) OUTPUT	
AS
/*
	declare @I_ProcedenciaID	tinyint = 2, 
	    	@T_Anio				varchar(4) = '2008',
			@B_Resultado		bit,
			@T_Message			nvarchar(4000)
	exec [USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_36_ConceptoPagoMigrado] @I_ProcedenciaID, @T_Anio, @B_Resultado output, @T_Message output
	select @B_Resultado as resultado, @T_Message as mensaje
*/
BEGIN
	DECLARE @I_Observados int = 0
	DECLARE @D_FecProceso datetime = GETDATE() 
	DECLARE @I_ObservID int = 36
	DECLARE @I_TablaID int = 4
	DECLARE @I_TablaOblID int = 5

	BEGIN TRANSACTION
	BEGIN TRY

		UPDATE	Obl
		SET		B_Migrable = 0,
				D_FecEvalua = @D_FecProceso
		FROM    TR_Ec_Obl Obl
				INNER JOIN TR_Ec_Det Det ON Obl.I_RowID = Det.I_OblRowID
				LEFT JOIN (SELECT Id_cp, I_ProcedenciaID FROM TR_Cp_Pri WHERE B_Migrado = 1) Pri 
						  ON Det.Concepto = Pri.Id_cp AND Det.I_ProcedenciaID = Pri.I_ProcedenciaID
		WHERE	Pri.Id_cp IS NULL
			AND Det.I_ProcedenciaID = @I_ProcedenciaID
			AND Det.Ano = @T_Anio 

		MERGE TI_ObservacionRegistroTabla AS TRG
		USING (SELECT DISTINCT @I_ObservID AS I_ObservID, @I_TablaOblID AS I_TablaID, Obl.I_RowID AS I_FilaTablaID, @D_FecProceso AS D_FecRegistro 
				 FROM TR_Ec_Obl Obl
					  INNER JOIN TR_Ec_Det Det ON Obl.I_RowID = Det.I_OblRowID
					  LEFT JOIN (SELECT Id_cp, I_ProcedenciaID FROM TR_Cp_Pri WHERE B_Migrado = 1) Pri 
								 ON Det.Concepto = Pri.Id_cp AND Det.I_ProcedenciaID = Pri.I_ProcedenciaID
				WHERE Pri.Id_cp IS NULL
					  AND Det.I_ProcedenciaID = @I_ProcedenciaID
					  AND Det.Ano = @T_Anio 
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
								WHERE I_ObservID = @I_ObservID AND I_TablaID = @I_TablaOblID AND I_ProcedenciaID = @I_ProcedenciaID)

		SELECT @I_Observados as cant_obs_obl, @D_FecProceso as fec_proceso

		COMMIT TRANSACTION				
		SET @B_Resultado = 1
		SET @T_Message = '{ ' +
							 'Type: "summary", ' + 
							 'Title: "Obligaciones con concepto no migrado", ' + 
							 'Value: ' + CAST(@I_Observados AS varchar) +
						 '}' 
	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION
		SET @B_Resultado = 0
		SET @T_Message = '[{ ' +
							 'Type: "error", ' + 
							 'Title: "Error", ' + 
							 'Value: "' + ERROR_MESSAGE() + ' (Linea: ' + CAST(ERROR_LINE() AS varchar(11)) + ')."'  +
						  '}]' 
	END CATCH
END
GO

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_U_ValidarDetalleObligacionConceptoPagoMigrado')
	DROP PROCEDURE [dbo].[USP_U_ValidarDetalleObligacionConceptoPagoMigrado]
GO

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_Obligaciones_ObligacionDet_MigracionTP_U_Validar_33_ConceptoPagoMigrado')
	DROP PROCEDURE [dbo].[USP_Obligaciones_ObligacionDet_MigracionTP_U_Validar_33_ConceptoPagoMigrado]
GO

CREATE PROCEDURE [dbo].[USP_Obligaciones_ObligacionDet_MigracionTP_U_Validar_33_ConceptoPagoMigrado]	
	@I_ProcedenciaID tinyint,
	@T_Anio		  varchar(4),
	@B_Resultado  bit output,
	@T_Message	  nvarchar(4000) OUTPUT	
AS
/*
	declare @I_ProcedenciaID	tinyint = 3, 
	    	@T_Anio				varchar(4) = '2008',
			@B_Resultado		bit,
			@T_Message			nvarchar(4000)
	exec USP_Obligaciones_ObligacionDet_MigracionTP_U_Validar_33_ConceptoPagoMigrado @I_ProcedenciaID, @T_Anio, @B_Resultado output, @T_Message output
	select @B_Resultado as resultado, @T_Message as mensaje
*/
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
				AND Ano = @T_Anio 
					
		MERGE TI_ObservacionRegistroTabla AS TRG
		USING 	(SELECT	@I_ObservID AS I_ObservID, @I_TablaID AS I_TablaID, I_RowID AS I_FilaTablaID, @D_FecProceso AS D_FecRegistro 
				 FROM   TR_Ec_Det Det
						LEFT JOIN (SELECT Id_cp, I_ProcedenciaID FROM TR_Cp_Pri WHERE B_Migrado = 1) Pri 
								  ON Det.Concepto = Pri.Id_cp AND Det.I_ProcedenciaID = Pri.I_ProcedenciaID
				 WHERE	Pri.Id_cp IS NULL
						AND Det.I_ProcedenciaID = @I_ProcedenciaID
						AND Ano = @T_Anio 
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

		SELECT @I_Observados as cant_obs_det, @I_ObservadosObl as cant_obs_obl, @D_FecProceso as fec_proceso

		COMMIT TRANSACTION				
		SET @B_Resultado = 1
		SET @T_Message = '{ ' +
							 'Type: "summary", ' + 
							 'Title: "Detalles con concepto no migrado", ' + 
							 'Value: ' + CAST(@I_Observados AS varchar) +
						 '}' 
	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION
		SET @B_Resultado = 0
		SET @T_Message = '[{ ' +
							 'Type: "error", ' + 
							 'Title: "Error", ' + 
							 'Value: "' + ERROR_MESSAGE() + ' (Linea: ' + CAST(ERROR_LINE() AS varchar(11)) + ')."'  +
						  '}]' 
	END CATCH
END
GO


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_IU_MigrarObligacionesCtasPorCobrar')
	DROP PROCEDURE [dbo].[USP_IU_MigrarObligacionesCtasPorCobrar]
GO


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_Obligaciones_MigracionTP_CtasPorCobrar_IU_MigrarDataPorAnio')
	DROP PROCEDURE [dbo].[USP_Obligaciones_MigracionTP_CtasPorCobrar_IU_MigrarDataPorAnio]
GO


CREATE PROCEDURE [dbo].[USP_Obligaciones_MigracionTP_CtasPorCobrar_IU_MigrarDataPorAnio]	
	@I_ProcedenciaID	tinyint,
	@T_Anio				varchar(4),
	@B_Resultado		bit output,
	@T_Message			nvarchar(4000) OUTPUT	
AS
/*
	declare @I_ProcedenciaID tinyint = 2,
			@T_Anio		 varchar(4) = '2008', 
			@B_Resultado  bit, 
			@T_Message nvarchar(4000)
	exec USP_Obligaciones_MigracionTP_CtasPorCobrar_IU_MigrarDataPorAnio @I_ProcedenciaID, @T_Anio, @B_Resultado output, @T_Message output
	select @B_Resultado as resultado, @T_Message as mensaje
*/
BEGIN
	DECLARE @D_FecProceso datetime = GETDATE() 
	DECLARE @I_TablaID_Obl int = 5
	DECLARE @I_TablaID_Det int = 4
	DECLARE @I_UsuarioID int = (SELECT dbo.Func_Config_CtasPorCobrar_I_ObtenerUsuarioMigracionID())
	DECLARE @I_CtasCabObl_RowID  int
	DECLARE @I_CtasDetObl_RowID  int
	DECLARE @T_Moneda varchar(3) = 'PEN'

	DECLARE @I_Obl_Actualizados int = 0
	DECLARE @I_Obl_Insertados int = 0

	DECLARE @I_Det_Actualizados int = 0
	DECLARE @I_Det_Insertados int = 0

	DECLARE @I_Mat_Actualizados int = 0
	DECLARE @I_Mat_Insertados int = 0

	DECLARE @Tbl_outputMat AS TABLE (T_Action varchar(20), I_RowID int, I_Inserted_RowID int, I_Deleted_RowID int)
	DECLARE @Tbl_outputObl AS TABLE (T_Action varchar(20), I_RowID int, I_Inserted_RowID int, I_Deleted_RowID int)
	DECLARE @Tbl_outputDet AS TABLE (T_Action varchar(20), I_RowID int, I_Inserted_RowID int, I_Deleted_RowID int)

	BEGIN TRANSACTION;
	BEGIN TRY 
		
		SELECT ROW_NUMBER() OVER(PARTITION BY Ano, P, Cod_alu, Cod_rc ORDER BY I_RowID) as I_Obl_Nro, 
			   Ano, P, I_Periodo, Cod_alu, Cod_rc, Cuota_pago, Tipo_oblig, Fch_venc, Monto, 0 as Pagado, 
			   D_FecCarga, B_Migrable, B_Migrado, I_ProcedenciaID, B_Obligacion, I_RowID
		  INTO #temp_obl_migrable_anio
		  FROM TR_Ec_Obl
		 WHERE B_Migrable = 1 
			   AND I_ProcedenciaID = @I_ProcedenciaID
		 	   AND Ano = @T_Anio
		
		MERGE INTO BD_OCEF_CtasPorCobrar.dbo.TC_MatriculaAlumno AS TRG
		USING (SELECT Cod_alu, Cod_rc, Ano, P, I_Periodo, I_RowID
				 FROM #temp_obl_migrable_anio WHERE I_Obl_Nro = 1) AS SRC
		ON TRG.C_CodAlu = SRC.cod_alu 
		   AND TRG.C_CodRc = SRC.cod_rc 
		   AND TRG.I_Anio  = CAST(SRC.ano AS int) 
		   AND TRG.I_Periodo = SRC.I_Periodo
		WHEN MATCHED THEN
			UPDATE SET TRG.I_MigracionTablaID = @I_TablaID_Obl, 
					   TRG.I_MigracionRowID = SRC.I_RowID,
					   TRG.D_FecMod = @D_FecProceso,
					   TRG.I_UsuarioMod = @I_UsuarioID,
					   TRG.B_Migrado = 1
		WHEN NOT MATCHED THEN
			INSERT (C_CodRc, C_CodAlu, I_Anio, I_Periodo, C_EstMat, C_Ciclo, B_Ingresante, I_CredDesaprob, I_UsuarioCre,   
					D_FecCre, B_Habilitado, B_Eliminado, B_Migrado, I_MigracionRowID, I_MigracionTablaID)
			VALUES (SRC.Cod_rc, SRC.Cod_alu, CAST(SRC.Ano as int), SRC.I_Periodo, 'S', NULL, NULL, NULL, @I_UsuarioID,
					@D_FecProceso, 1, 0, 1, SRC.I_RowID, @I_TablaID_Obl)
		OUTPUT $action, SRC.I_RowID, inserted.I_MatAluID, deleted.I_MatAluID INTO @Tbl_outputMat;

		SET @I_Mat_Insertados = (SELECT COUNT(*) FROM @Tbl_outputMat WHERE T_Action = 'INSERT')
		SET @I_Mat_Actualizados = (SELECT COUNT(*) FROM @Tbl_outputMat WHERE T_Action = 'UPDATE')

		UPDATE Obl
		   SET I_CtasMatTableRowID = OM.I_Inserted_RowID
		  FROM @Tbl_outputMat OM
			   INNER JOIN TR_Ec_Obl Obl ON OM.I_RowID = Obl.I_RowID

		UPDATE Obl
		   SET I_CtasMatTableRowID = OblMat.I_CtasMatTableRowID
		  FROM TR_Ec_Obl Obl
			   INNER JOIN (SELECT * FROM TR_Ec_Obl WHERE I_CtasMatTableRowID IS NOT NULL) OblMat 
							ON obl.Ano = OblMat.Ano	
							   AND obl.I_Periodo = OblMat.I_Periodo
							   AND obl.Cod_alu = OblMat.Cod_alu
							   AND obl.Cod_rc = OblMat.Cod_rc


		;WITH CTE_OBL_MIGRABLE (CTE_RowID, I_OblRowID, Ano, P, I_Periodo, Cod_alu, Cod_rc, Cuota_pago, 
								Tipo_oblg, Fch_venc, Monto, Pagado, I_MatAluID, I_MigracionTablaID )
		AS
		(
			SELECT ROW_NUMBER() OVER (ORDER BY obl.I_RowID ASC) as CTE_RowID, obl.I_RowID as I_OblRowID, 
				   obl.Ano, obl.P, obl.I_Periodo, obl.Cod_alu, obl.Cod_rc, obl.Cuota_pago, obl.Tipo_oblig, 
				   obl.Fch_venc, obl.Monto, obl.Pagado, mat.I_MatAluID, mat.I_MigracionTablaID 
			  FROM #temp_obl_migrable_anio obl
				   LEFT JOIN BD_OCEF_CtasPorCobrar.dbo.TC_MatriculaAlumno mat ON CAST(obl.Ano AS int) = mat.I_Anio	
																				 AND obl.I_Periodo = mat.I_Periodo
																				 AND obl.Cod_alu = mat.C_CodAlu
																				 AND obl.Cod_rc = mat.C_CodRc
			 WHERE mat.I_MigracionRowID IS NOT NULL
		)

		MERGE INTO BD_OCEF_CtasPorCobrar.dbo.TR_ObligacionAluCab AS TRG
		USING CTE_OBL_MIGRABLE AS SRC
		ON TRG.I_MigracionRowID = SRC.I_OblRowID AND
		   TRG.I_MigracionTablaID = SRC.I_MigracionTablaID
		WHEN MATCHED AND TRG.B_Migrado = 1 THEN
			UPDATE SET TRG.I_ProcesoID = SRC.Cuota_pago, 
					   TRG.I_MatAluID = SRC.I_MatAluID, 
					   TRG.I_MontoOblig = SRC.Monto, 
					   TRG.D_FecVencto = SRC.Fch_venc, 
					   TRG.B_Pagado = SRC.Pagado, 
					   TRG.I_UsuarioMod = @I_UsuarioID, 
					   TRG.D_FecMod = @D_FecProceso
		WHEN NOT MATCHED THEN
			INSERT (I_ProcesoID, I_MatAluID, C_Moneda, I_MontoOblig, D_FecVencto, B_Pagado, B_Habilitado, 
					B_Eliminado, I_UsuarioCre, D_FecCre, B_Migrado, I_MigracionTablaID, I_MigracionRowID)
			VALUES (SRC.Cuota_pago, SRC.I_MatAluID, @T_Moneda, SRC.Monto, SRC.Fch_venc, 0, 1, 
					0, @I_UsuarioID, @D_FecProceso, 1, I_MigracionTablaID, SRC.I_OblRowID)
		OUTPUT $action, SRC.I_OblRowID, inserted.I_ObligacionAluID, deleted.I_ObligacionAluID INTO @Tbl_outputObl;
			
		UPDATE OBL
		   SET B_Migrado = 1,
			   D_FecMigrado = @D_FecProceso,
			   I_CtasCabTableRowID = I_Inserted_RowID
		  FROM TR_Ec_Obl OBL
			   INNER JOIN @Tbl_outputObl O ON O.I_RowID = OBL.I_RowID
		 WHERE O.T_Action = 'INSERT'

		UPDATE OBL
		   SET B_Migrado = 1,
			   D_FecMigrado = @D_FecProceso,
			   I_CtasCabTableRowID = I_Inserted_RowID
		  FROM TR_Ec_Obl OBL
			   INNER JOIN @Tbl_outputObl O ON O.I_RowID = OBL.I_RowID
		 WHERE O.T_Action = 'UPDATE'


		SET @I_Obl_Insertados = (SELECT COUNT(*) FROM @Tbl_outputObl WHERE T_Action = 'INSERT')
		SET @I_Obl_Actualizados = (SELECT COUNT(*) FROM @Tbl_outputObl WHERE T_Action = 'UPDATE')


		select * from  @Tbl_outputObl


		SELECT I_OblRowID, I_RowID, Ano, P, Cod_alu, Cod_rc, Cuota_pago, Tipo_oblig, Cantidad, Monto, 
			   Concepto, Tipo_pago, No_banco, Fch_elimin, Concepto_f, Fch_venc, 0 as Pagado, Documento, 
			   Eliminado, D_FecCarga, B_Migrable, B_Migrado, I_ProcedenciaID, B_Obligacion
		  INTO #temp_det_migrable_anio
		  FROM TR_Ec_Det
		 WHERE B_Migrable = 1 
			   AND I_ProcedenciaID = @I_ProcedenciaID
		 	   AND Ano = @T_Anio


		;WITH CTE_DET_MIGRABLE (I_MigracionTablaID, CTE_RowID, I_OblRowID, I_DetRowID, I_CtasOblID, Concepto, Monto, Pagado,
								Fch_venc, I_TipoDocumento, T_DescDocumento, Habilitado, Eliminado, D_FecCre, Mora)
		AS
		(
			SELECT @I_TablaID_Det, ROW_NUMBER() OVER (ORDER BY det.I_OblRowID, det.I_RowID ASC) as CTE_RowID, 
				   det.I_OblRowID, det.I_RowID, obl.I_Inserted_RowID as I_CtasOblID, det.Concepto, det.Monto, 0 as Pagado, det.Fch_venc, 
				   CASE WHEN CAST(Documento as varchar(max)) IS NULL THEN NULL ELSE 138 END AS I_TipoDocumento, 
				   CAST(Documento as varchar(max)) AS T_DescDocumento, IIF(Eliminado = 1, 0, 1) AS Habilitado, Eliminado, @D_FecProceso, 0 as Mora
			  FROM #temp_det_migrable_anio det
				   INNER JOIN @Tbl_outputObl obl ON obl.I_RowID = det.I_OblRowID
		)

		MERGE INTO BD_OCEF_CtasPorCobrar.dbo.TR_ObligacionAluDet AS TRG
		USING (SELECT obl.I_ObligacionAluID, det.*
				 FROM CTE_DET_MIGRABLE det 
					  INNER JOIN BD_OCEF_CtasPorCobrar.dbo.TR_ObligacionAluCab obl ON det.I_OblRowID = obl.I_MigracionRowID
			  ) AS SRC
		ON TRG.I_MigracionRowID = SRC.I_DetRowID AND
		   TRG.I_MigracionTablaID = SRC.I_MigracionTablaID
		WHEN MATCHED AND TRG.B_Migrado = 1 THEN
			UPDATE SET TRG.I_ObligacionAluID = SRC.I_ObligacionAluID, 
					   TRG.I_ConcPagID = SRC.Concepto, 
					   TRG.I_Monto = SRC.Monto, 
					   TRG.B_Pagado = SRC.Pagado, 
					   TRG.D_FecVencto = SRC.Fch_venc, 
					   TRG.I_TipoDocumento = SRC.I_TipoDocumento, 
					   TRG.T_DescDocumento = SRC.T_DescDocumento, 
					   TRG.B_Mora = SRC.Mora, 
					   TRG.I_UsuarioMod = @I_UsuarioID, 
					   TRG.D_FecMod = @D_FecProceso
		WHEN NOT MATCHED THEN
			INSERT (I_ObligacionAluID, I_ConcPagID, I_Monto, B_Pagado, D_FecVencto, I_TipoDocumento, T_DescDocumento, 
					B_Habilitado, B_Eliminado, I_UsuarioCre, D_FecCre, B_Mora, B_Migrado, I_MigracionTablaID, I_MigracionRowID)
			VALUES (SRC.I_ObligacionAluID, SRC.Concepto, SRC.Monto, SRC.Pagado, SRC.Fch_venc, SRC.I_TipoDocumento, SRC.T_DescDocumento, 
					SRC.Habilitado, SRC.Eliminado, @I_UsuarioID, SRC.D_FecCre, SRC.Mora, 1, I_MigracionTablaID, SRC.I_DetRowID)
		OUTPUT $action, SRC.I_DetRowID, inserted.I_ObligacionAluDetID, deleted.I_ObligacionAluDetID INTO @Tbl_outputDet;

		UPDATE DET
		   SET B_Migrado = 1,
			   D_FecMigrado = @D_FecProceso,
			   I_CtasDetTableRowID = o.I_Inserted_RowID
		  FROM TR_Ec_Det DET
			   INNER JOIN @Tbl_outputDet O ON O.I_RowID = DET.I_RowID
		 WHERE O.T_Action = 'INSERT'

		UPDATE DET
		   SET B_Migrado = 1,
			   D_FecMigrado = @D_FecProceso, 
			   I_CtasDetTableRowID = o.I_Inserted_RowID
		  FROM TR_Ec_Det DET
			   INNER JOIN @Tbl_outputDet O ON O.I_RowID = DET.I_RowID
		 WHERE O.T_Action = 'UPDATE'


		SET @I_Det_Insertados = (SELECT COUNT(*) FROM @Tbl_outputDet WHERE T_Action = 'INSERT')
		SET @I_Det_Actualizados = (SELECT COUNT(*) FROM @Tbl_outputDet WHERE T_Action = 'UPDATE')


		COMMIT TRANSACTION
					
		SET @B_Resultado = 1
		SET @T_Message = '[{ ' +
							 'Type: "summary", ' + 
							 'Title: "Insertados Cabecera Obligacion", ' + 
							 'Value: ' + CAST(@I_Obl_Insertados AS varchar) +
						  '},
						  { ' +
							 'Type: "summary", ' + 
							 'Title: "Actualizados Cabecera Obligacion", ' + 
							 'Value: ' + CAST(@I_Obl_Actualizados AS varchar) +
						  '},
						  { ' +
							 'Type: "summary", ' + 
							 'Title: "Insertados Detalle Obligacion", ' + 
							 'Value: ' + CAST(@I_Det_Insertados AS varchar) +
						  '},
						  { ' +
							 'Type: "summary", ' + 
							 'Title: "Actualizados Detalle Obligacion", ' + 
							 'Value: ' + CAST(@I_Det_Actualizados AS varchar) +
						  '}]' 
	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION
		SET @B_Resultado = 0
		SET @T_Message = '[{ ' +
							 'Type: "error", ' + 
							 'Title: "Error", ' + 
							 'Value: "' + ERROR_MESSAGE() + ' (Linea: ' + CAST(ERROR_LINE() AS varchar(11)) + ')."'  +
						  '}]' 
	END CATCH
END
GO




IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_CtasPorCobrar_U_GrabarMatriculaPorObligacionID')
BEGIN
	DROP PROCEDURE [dbo].[USP_CtasPorCobrar_U_GrabarMatriculaPorObligacionID]
END
GO

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_Obligaciones_MigracionTP_CtasPorCobrar_I_GrabarMatriculaPorObligacionID')
BEGIN
	DROP PROCEDURE [dbo].[USP_Obligaciones_MigracionTP_CtasPorCobrar_I_GrabarMatriculaPorObligacionID]
END
GO

CREATE PROCEDURE [dbo].[USP_Obligaciones_MigracionTP_CtasPorCobrar_I_GrabarMatriculaPorObligacionID]	
(
	@I_RowID			int,
	@D_FecProceso		datetime,
	@I_TablaOblID	    int,
	@I_MatAluID			int OUTPUT
)
AS
BEGIN
	DECLARE @I_UsuarioID	int = 15

	INSERT INTO BD_OCEF_CtasPorCobrar.dbo.TC_MatriculaAlumno(C_CodRc, C_CodAlu, I_Anio, I_Periodo, C_EstMat, C_Ciclo, B_Ingresante, I_CredDesaprob, I_UsuarioCre, 
															 B_Habilitado, B_Eliminado, B_Migrado, D_FecCre, I_MigracionTablaID, I_MigracionRowID)
								                     SELECT	SRC.Cod_rc, SRC.Cod_alu, CAST(SRC.Ano as int), SRC.I_Periodo, 'S' as matricula, NULL as ciclo, NULL as ingresante, NULL as cred_desaprob, 
															@I_UsuarioID, 1 as habilitado, 0 as eliminado, 1 as migrado, @D_FecProceso, @I_TablaOblID, @I_RowID
													   FROM TR_Ec_Obl SRC 
													  WHERE I_RowID = @I_RowID	

	SET @I_MatAluID = SCOPE_IDENTITY()
END
GO


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'U_GrabarMatriculaPorObligacionID')
BEGIN
	DROP PROCEDURE [dbo].[USP_CtasPorCobrar_U_GrabarMatriculaPorObligacionID]
END
GO

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_Obligaciones_MigracionTP_CtasPorCobrar_U_GrabarMatriculaPorObligacionID')
BEGIN
	DROP PROCEDURE [dbo].[USP_Obligaciones_MigracionTP_CtasPorCobrar_U_GrabarMatriculaPorObligacionID]
END
GO

CREATE PROCEDURE [dbo].[USP_Obligaciones_MigracionTP_CtasPorCobrar_U_GrabarMatriculaPorObligacionID]	
(
	@I_RowID			int,
	@I_MatAluID			int,
	@I_TablaOblID	    int,
	@D_FecProceso		datetime
)
AS
BEGIN
	UPDATE BD_OCEF_CtasPorCobrar.dbo.TC_MatriculaAlumno
	   SET C_CodRc = SRC.Cod_rc, 
		   C_CodAlu = SRC.Cod_alu, 
		   I_Anio = CAST(SRC.Ano as int), 
		   I_Periodo = SRC.I_Periodo, 
		   D_FecMod = @D_FecProceso,
		   I_MigracionTablaID = @I_TablaOblID, 
		   I_MigracionRowID = @I_MatAluID
	  FROM (SELECT * FROM TR_Ec_Obl WHERE I_RowID = @I_RowID) SRC
     WHERE I_MatAluID = @I_MatAluID
END
GO



IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_CtasPorCobrar_I_GrabarDetalleObligacionPorObligacionID')
BEGIN
	DROP PROCEDURE [dbo].[USP_CtasPorCobrar_I_GrabarDetalleObligacionPorObligacionID]
END
GO

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_Obligaciones_MigracionTP_CtasPorCobrar_I_GrabarDetObligPorObligacionID')
BEGIN
	DROP PROCEDURE [dbo].[USP_Obligaciones_MigracionTP_CtasPorCobrar_I_GrabarDetObligPorObligacionID]
END
GO

CREATE PROCEDURE [dbo].[USP_Obligaciones_MigracionTP_CtasPorCobrar_I_GrabarDetObligPorObligacionID]	
(
	@I_OblRowID			int,
	@I_ObligacionAluID	int,
	@D_FecProceso		datetime,
	@I_TablaID			int,
	@I_Det_Insertados	int OUTPUT
)
AS
BEGIN
	
	DECLARE @I_UsuarioID	int = 15

	INSERT INTO BD_OCEF_CtasPorCobrar.dbo.TR_ObligacionAluDet (I_ObligacionAluID, I_ConcPagID, I_Monto, B_Pagado, D_FecVencto, I_TipoDocumento, 
															   T_DescDocumento, B_Habilitado, B_Eliminado, I_UsuarioCre, D_FecCre, B_Mora, 
															   B_Migrado, I_MigracionTablaID, I_MigracionRowID)
														SELECT @I_ObligacionAluID, SRC.Concepto, SRC.Monto, 0 as pagado, SRC.Fch_venc, CASE WHEN CAST(Documento as varchar(max)) IS NULL THEN NULL ELSE 138 END AS I_TipoDocumento, 
															   CAST(Documento as varchar(max)) AS T_DescDocumento, 1 as habilitado,  Eliminado as eliminado, @I_UsuarioID as I_UsuarioCre, @D_FecProceso, 0 AS Mora, 
															   1 as migrado, @I_TablaID, I_RowID
														  FROM TR_Ec_Det SRC
														 WHERE SRC.I_OblRowID =  @I_OblRowID
															   AND Concepto <> 0
															   AND Concepto_f = 0

	SET @I_Det_Insertados = @@ROWCOUNT
END
GO



IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_IU_MigrarObligacionesCtasPorCobrarPorObligacionID')
	DROP PROCEDURE [dbo].[USP_IU_MigrarObligacionesCtasPorCobrarPorObligacionID]
GO


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_Obligaciones_MigracionTP_CtasPorCobrar_IU_MigrarDataPorID')
BEGIN
	DROP PROCEDURE [dbo].[USP_Obligaciones_MigracionTP_CtasPorCobrar_IU_MigrarDataPorID]
END
GO

CREATE PROCEDURE [dbo].[USP_Obligaciones_MigracionTP_CtasPorCobrar_IU_MigrarDataPorID]	
(
	@I_RowID		int ,
	@I_OblAluID		int OUTPUT,
	@B_Resultado	bit OUTPUT,
	@T_Message		nvarchar(4000) OUTPUT	
)
AS
/*
	declare   @I_RowID	 int = 2830, 
				@I_OblAluID int,
				@B_Resultado  bit, 
				@T_Message nvarchar(4000)
	exec USP_Obligaciones_MigracionTP_CtasPorCobrar_IU_MigrarDataPorID @I_RowID, @I_OblAluID output, @B_Resultado output, @T_Message output
	select @B_Resultado as resultado, @T_Message as mensaje
*/
BEGIN
	DECLARE @I_Det_Removidos int = 0
	DECLARE @I_Det_Actualizados int = 0
	DECLARE @I_Det_Insertados int = 0

	DECLARE @D_FecProceso datetime = GETDATE()
	DECLARE @I_MigracionTablaOblID tinyint = 5
	DECLARE @I_MigracionTablaDetID tinyint = 4
	DECLARE @T_Moneda varchar(3) = 'PEN'

	BEGIN TRANSACTION;
	BEGIN TRY 
		DECLARE @I_ObligacionAluID  int 
		DECLARE @I_CountDetOblID	int 
		DECLARE @Cod_alu			varchar(20)
		DECLARE @Cod_Rc				varchar(5)
		DECLARE @I_Periodo			int
		DECLARE @I_Anio				int
		
		DECLARE @I_MatAluID  int 
		DECLARE @I_MatAluID_Obl  int 
		DECLARE @I_UsuarioID	int = 15


		SELECT @Cod_alu = Cod_alu, @I_Periodo = I_Periodo, @I_Anio = CAST(Ano as int), @Cod_Rc = Cod_rc
		  FROM TR_Ec_Obl
		 WHERE I_RowID = @I_RowID

		SELECT @I_MatAluID = I_MatAluID
		  FROM BD_OCEF_CtasPorCobrar.dbo.TC_MatriculaAlumno
		 WHERE C_CodAlu = @Cod_alu AND C_CodRc = @Cod_Rc 
			   AND I_Periodo = @I_Periodo AND I_Anio = @I_Anio
			   AND B_Eliminado = 0
		 		
		
		SELECT @I_ObligacionAluID = I_ObligacionAluID, @I_MatAluID_Obl = I_MatAluID
		  FROM BD_OCEF_CtasPorCobrar.dbo.TR_ObligacionAluCab
		 WHERE I_MigracionRowID = @I_RowID AND I_MigracionTablaID = @I_MigracionTablaOblID

		SELECT @I_CountDetOblID = COUNT(*) FROM BD_OCEF_CtasPorCobrar.dbo.TR_ObligacionAluDet
		 WHERE I_ObligacionAluID = @I_ObligacionAluID 
			   AND I_MigracionTablaID = @I_MigracionTablaDetID

		IF(@I_ObligacionAluID IS NULL)
		BEGIN
			IF(@I_MatAluID IS NULL)
			BEGIN
				EXECUTE USP_Obligaciones_MigracionTP_CtasPorCobrar_I_GrabarMatriculaPorObligacionID @I_RowID, @D_FecProceso, @I_MigracionTablaOblID, @I_MatAluID
			END
			ELSE
			BEGIN
				EXECUTE USP_Obligaciones_MigracionTP_CtasPorCobrar_U_GrabarMatriculaPorObligacionID @I_RowID, @I_MatAluID, @I_MigracionTablaOblID, @D_FecProceso
			END

			INSERT INTO BD_OCEF_CtasPorCobrar.dbo.TR_ObligacionAluCab (I_ProcesoID, I_MatAluID, C_Moneda, I_MontoOblig, D_FecVencto, B_Pagado, B_Habilitado, 
																	   B_Eliminado, I_UsuarioCre, D_FecCre, B_Migrado, I_MigracionTablaID, I_MigracionRowID)
																SELECT SRC.Cuota_pago, @I_MatAluID, @T_Moneda, SRC.Monto, SRC.Fch_venc, 0 as B_Pagado, 1 as B_Habilitado, 
																	   0 as eliminado, @I_UsuarioID, @D_FecProceso, 1 as B_Migrado, @I_MigracionTablaOblID, SRC.I_RowID
																		  FROM TR_Ec_Obl SRC
																 WHERE SRC.I_RowID = @I_RowID

			SET @I_ObligacionAluID = SCOPE_IDENTITY();

			EXECUTE USP_Obligaciones_MigracionTP_CtasPorCobrar_I_GrabarDetObligPorObligacionID @I_RowID, @I_ObligacionAluID, @D_FecProceso, @I_MigracionTablaDetID, @I_Det_Insertados

		END
		ELSE
		BEGIN
			IF (ISNULL(@I_MatAluID, 1) <> ISNULL(@I_MatAluID_Obl, 1))
			BEGIN
				SET @B_Resultado = 0
				SET @T_Message = 'La matricula en el repositorio, no coincide con la del temporal de pagos.'

				GOTO END_TRANSACTION
			END
			
			IF(@I_MatAluID IS NULL)
			BEGIN
				EXECUTE USP_Obligaciones_MigracionTP_CtasPorCobrar_I_GrabarMatriculaPorObligacionID @I_RowID, @D_FecProceso, @I_MigracionTablaOblID, @I_MatAluID
			END
			ELSE
			BEGIN
				EXECUTE USP_Obligaciones_MigracionTP_CtasPorCobrar_U_GrabarMatriculaPorObligacionID @I_RowID, @I_MatAluID, @I_MigracionTablaOblID, @D_FecProceso
			END

			UPDATE BD_OCEF_CtasPorCobrar.dbo.TR_ObligacionAluCab
			   SET I_ProcesoID = SRC.Cuota_pago, 
				   I_MatAluID = @I_MatAluID, 
				   I_MontoOblig = SRC.Monto, 
				   D_FecVencto = SRC.Fch_venc, 
				   I_MigracionTablaID = @I_MigracionTablaOblID, 
				   I_MigracionRowID = @I_RowID, 
				   B_Pagado = 0, 
				   I_UsuarioMod = 1, 
				   D_FecMod = @D_FecProceso
			  FROM (SELECT * FROM TR_Ec_Obl WHERE I_RowID = @I_RowID) SRC
			 WHERE I_ObligacionAluID = @I_ObligacionAluID

			IF (@I_CountDetOblID = 0)
			BEGIN
				EXECUTE USP_Obligaciones_MigracionTP_CtasPorCobrar_I_GrabarDetObligPorObligacionID @I_RowID, @I_ObligacionAluID, @D_FecProceso, @I_MigracionTablaDetID, @I_Det_Insertados
			END
			ELSE
			BEGIN
				DECLARE @Tbl_outputObl AS TABLE (T_Action varchar(20), I_RowID int)

				MERGE INTO BD_OCEF_CtasPorCobrar.dbo.TR_ObligacionAluDet AS TRG
				USING (SELECT @I_ObligacionAluID as I_ObligacionAluID, Concepto, Monto, 0 as pagado, Fch_venc, 0 AS Mora, 1 as habilitado, Eliminado as eliminado, 
							  CASE WHEN CAST(Documento as varchar(max)) IS NULL THEN NULL ELSE 138 END AS I_TipoDocumento, 1 as migrado, 
							  CAST(Documento as varchar(max)) AS T_DescDocumento, NULL as I_UsuarioCre, @D_FecProceso as D_FecMod, 
							  @I_MigracionTablaDetID as I_MigracionTablaID, I_RowID as I_DetMigracionRowID
						FROM TR_Ec_Det SRC
						WHERE SRC.I_OblRowID = @I_RowID
							  AND Concepto <> 0
							  AND Concepto_f = 0
					  ) AS SRC
				ON TRG.I_MigracionRowID = SRC.I_DetMigracionRowID AND
				   TRG.I_MigracionTablaID = @I_MigracionTablaDetID
				WHEN MATCHED THEN
					UPDATE SET TRG.I_ObligacionAluID = SRC.I_ObligacionAluID, 
							   TRG.I_ConcPagID = SRC.Concepto, 
							   TRG.I_Monto = SRC.Monto, 
							   TRG.B_Pagado = 0, 
							   TRG.D_FecVencto = SRC.Fch_venc, 
							   TRG.I_TipoDocumento = SRC.I_TipoDocumento, 
							   TRG.T_DescDocumento = SRC.T_DescDocumento, 
							   TRG.B_Mora = SRC.Mora, 
							   TRG.B_Eliminado = SRC.Eliminado, 
							   TRG.I_UsuarioMod = 1, 
							   TRG.D_FecMod = @D_FecProceso
				WHEN NOT MATCHED THEN
					INSERT (I_ObligacionAluID, I_ConcPagID, I_Monto, B_Pagado, D_FecVencto, I_TipoDocumento, T_DescDocumento, B_Mora, 
							B_Habilitado, B_Eliminado, I_UsuarioCre, D_FecCre, B_Migrado, I_MigracionTablaID, I_MigracionRowID)
					VALUES (SRC.I_ObligacionAluID, SRC.Concepto, SRC.Monto, 0, SRC.Fch_venc, SRC.I_TipoDocumento, SRC.T_DescDocumento, SRC.Mora, 
							SRC.Habilitado, SRC.Eliminado, 1, @D_FecProceso, 1, @I_MigracionTablaDetID, SRC.I_DetMigracionRowID)
				OUTPUT $action, SRC.I_DetMigracionRowID INTO @Tbl_outputObl;

				SET @I_Det_Insertados = (SELECT COUNT(*) FROM @Tbl_outputObl WHERE T_Action = 'INSERT')
				SET @I_Det_Actualizados = (SELECT COUNT(*) FROM @Tbl_outputObl WHERE T_Action = 'UPDATE')

			END
		END
		
		UPDATE EC_OBL 
		   SET B_Migrado = 1,
		   	   D_FecMigrado = @D_FecProceso
		  FROM TR_Ec_Obl EC_OBL
		 	   INNER JOIN BD_OCEF_CtasPorCobrar.dbo.TR_ObligacionAluCab CTAS_CAB ON EC_OBL.I_RowID = CTAS_CAB.I_MigracionRowID
		 WHERE EC_OBL.I_RowID = @I_RowID
		 
		
		SET @B_Resultado = 1
		SET @T_Message = 'Detalle de obligaciones actualizadas:' + CAST(@I_Det_Actualizados AS varchar(10))  + ' | Detalle de obligaciones insertadas: ' + CAST(@I_Det_Insertados AS varchar(10))

		END_TRANSACTION:
			SET @I_OblAluID = ISNULL(@I_ObligacionAluID, 0)
			COMMIT TRANSACTION;
	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION;

		SET @I_OblAluID = ISNULL(@I_ObligacionAluID, 0)
		SET @B_Resultado = 0
		SET @T_Message = ERROR_MESSAGE() + ' LINE: ' + CAST(ERROR_LINE() AS varchar(10)) 
	END CATCH
END
GO


