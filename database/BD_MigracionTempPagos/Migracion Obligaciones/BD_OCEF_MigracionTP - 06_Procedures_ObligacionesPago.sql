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
	declare @I_ProcedenciaID	tinyint = 3,
			@T_SchemaDB   varchar(20) = 'euded',
			@T_Anio		  varchar(4) = '2010',
			@B_Resultado  bit,
			@T_Message	  nvarchar(4000)
	exec USP_Obligaciones_ObligacionCab_TemporalPagos_MigracionTP_IU_CopiarTabla @I_ProcedenciaID, @T_SchemaDB, @T_AnioIni, @T_AnioFin, @B_Resultado output, @T_Message output
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

		SET @T_SQL = 'DELETE TR_Ec_Det ' +
					  'WHERE I_ProcedenciaID = '+ CAST(@I_ProcedenciaID as varchar(3)) + 
							'AND EXISTS (SELECT * FROM TR_Ec_Obl ' +
										 'WHERE TR_Ec_Obl.I_RowID = I_OblRowID ' + 
												'AND TR_Ec_Obl.Ano = ''' + @T_Anio + ''' ' +
												'AND TR_Ec_Obl.B_Migrado = 0 ' +
												'AND TR_Ec_Obl.I_ProcedenciaID = I_ProcedenciaID);'
						

		PRINT @T_SQL
		EXEC sp_executesql @T_SQL
		SET @I_Removidos = @@ROWCOUNT

		
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


		SET @T_SQL = 'DECLARE @D_FecProceso datetime = GETDATE()' +
			
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

		
		SET @T_SQL = '(SELECT * FROM BD_OCEF_TemporalPagos.' + @T_SchemaDB + '.ec_obl WHERE Ano = ''' + @T_Anio + ''' '

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
	@T_Anio		  varchar(4),
	@B_Resultado  bit output,
	@T_Message	  nvarchar(4000) OUTPUT	
AS
/*
	declare @I_ProcedenciaID	tinyint = 3,
			@T_SchemaDB   varchar(20) = 'euded',
			@T_AnioIni	  varchar(4) = null,
			@T_AnioFin	  varchar(4) = null,
	 		@B_Resultado  bit,
			@T_Message	  nvarchar(4000)
	exec USP_Obligaciones_ObligacionDet_TemporalPagos_MigracionTP_IU_CopiarTabla @I_ProcedenciaID, @T_SchemaDB, @T_AnioIni, @T_AnioFin, @B_Resultado output, @T_Message output
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
										    'id_lug_pag, cantidad, monto, CAST(SRC.documento as nvarchar(max)), pagado, concepto_f, fch_elimin, nro_ec, fch_ec, ' + 
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

		SELECT @I_EcDet AS tot_obligaciones, @I_Insertados AS cant_inserted, @I_Actualizados as cant_updated, @I_Removidos as cant_removed, @D_FecProceso as fec_proceso
		
		COMMIT TRANSACTION
		SET @B_Resultado = 1
		SET @T_Message =  '[{ ' +
							 'Type: "summary", ' + 
							 'Title: "Total", '+ 
							 'Value: ' + CAST(@I_EcDet AS varchar) +
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
		SET @T_Message = ERROR_MESSAGE() + ' LINE: ' + CAST(ERROR_LINE() AS varchar(10)) 
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
			@I_ProcedenciaID	tinyint = 3,
	    	@T_Anio		  varchar(4) = '2012',
			@T_Message	  nvarchar(4000)
  exec USP_Obligaciones_ObligacionDet_MigracionTP_U_AsignarObligacionCabID @I_ProcedenciaID, @T_Anio, @B_Resultado output, @T_Message output
  select @B_Resultado as resultado, @T_Message as mensaj
*/
BEGIN 
	DECLARE @D_FecProceso datetime = GETDATE() 
	DECLARE @I_Actualizados int = 0

	BEGIN TRANSACTION
	BEGIN TRY
		
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
							 'Value: ' + ERROR_MESSAGE() + ' (Linea: ' + CAST(ERROR_LINE() AS varchar(11)) + ').'  +
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
							 'Value: ' + ERROR_MESSAGE() + ' (Linea: ' + CAST(ERROR_LINE() AS varchar(11)) + ').'  +
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
	@I_Anio	      smallint,
	@B_Resultado  bit output,
	@T_Message	  nvarchar(4000) OUTPUT	
AS
/*
	declare	@B_Resultado  bit,
				@I_ProcedenciaID	tinyint = 3,
				@I_Anio  	  smallint,
				@T_Message	  nvarchar(4000)
	exec USP_Obligaciones_ObligacionCab_MigracionTP_U_InicializarEstadoValidacion @I_ProcedenciaID, @I_Anio, @B_Resultado output, @T_Message output
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
/*
	declare	@B_Resultado  bit,
			@I_ProcedenciaID	tinyint = 3,
			@I_Anio	      smallint = 2010,
			@T_Message	  nvarchar(4000)
	exec USP_Obligaciones_ObligacionDet_MigracionTP_U_InicializarEstadoValidacion @I_ProcedenciaID, @I_Anio, @B_Resultado output, @T_Message output
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
		SET @T_Message = '[{ ' +
							 'Type: "summary", ' + 
							 'Title: "Observados", ' + 
							 'Value: ' + CAST(@I_Observados AS varchar)  +
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
		SET @T_Message = '[{ ' +
							 'Type: "summary", ' + 
							 'Title: "Observados", ' + 
							 'Value: ' + CAST(@I_Observados AS varchar) +
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
		SET @T_Message = '[{ ' +
							 'Type: "summary", ' + 
							 'Title: "Observados", ' + 
							 'Value: ' + CAST(@I_Observados AS varchar) +
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
		SET @T_Message = '[{ ' +
							 'Type: "summary", ' + 
							 'Title: "Observados", ' + 
							 'Value: ' + CAST(@I_Observados AS varchar) +
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


