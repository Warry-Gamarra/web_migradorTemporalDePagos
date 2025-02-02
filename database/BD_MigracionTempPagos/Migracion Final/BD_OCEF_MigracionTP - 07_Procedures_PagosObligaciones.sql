/*
==================================================================
	BD_OCEF_MigracionTP - 07_Procedures_PagoObligaciones
==================================================================
*/


USE BD_OCEF_MigracionTP
GO

/*	
	=================================================================================
		Copiar tablas ec_obl y ec_det segun procedencia	(pagos de obligaciones)
	=================================================================================
*/ 

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_Obligaciones_Pagos_TemporalPagos_MigracionTP_IU_CopiarTabla')
	DROP PROCEDURE [dbo].[USP_Obligaciones_Pagos_TemporalPagos_MigracionTP_IU_CopiarTabla]
GO


CREATE PROCEDURE USP_Obligaciones_Pagos_TemporalPagos_MigracionTP_IU_CopiarTabla	
	@I_ProcedenciaID tinyint,
	@T_SchemaDB	  varchar(20),
	@T_Anio		  varchar(4),
	@B_Resultado  bit output,
	@T_Message	  nvarchar(4000) OUTPUT	
AS 
/*
	DECLARE @I_ProcedenciaID	tinyint = 3,
			@T_SchemaDB   varchar(20) = 'euded',
			@T_Anio		  varchar(4) = '2005',
			@B_Resultado  bit,
			@T_Message	  nvarchar(4000)
	EXEC USP_Obligaciones_Pagos_TemporalPagos_MigracionTP_IU_CopiarTabla @I_ProcedenciaID, @T_SchemaDB, @T_Anio, 
																		 @B_Resultado output, @T_Message output
	SELECT @B_Resultado as resultado, @T_Message as mensaje
*/
BEGIN
	DECLARE @I_EcDet int = 0
	DECLARE @I_Removidos int = 0
	DECLARE @I_Actualizados int = 0
	DECLARE @I_Insertados int = 0
	DECLARE @D_FecProceso datetime = GETDATE() 
	DECLARE @T_SQL nvarchar(max)

	DECLARE @I_Proced_pregrado int = 1
	DECLARE @I_Proced_eupg int = 2
	DECLARE @I_Proced_euded int = 3

	BEGIN TRANSACTION
	BEGIN TRY
		
		DECLARE @T_variables_conceptos as nvarchar(500)
		DECLARE @T_filtros_conceptos as nvarchar(500)

		IF (@I_ProcedenciaID = @I_Proced_pregrado)
		BEGIN
			SET @T_variables_conceptos = 'DECLARE @recibo_pago int = 0 ' + CHAR(13) +
										 'DECLARE @deudas_anteriores_2017 int = 6924 ' + CHAR(10) + CHAR(13) 


			SET @T_filtros_conceptos = '@recibo_pago, @deudas_anteriores_2017'
		END
		ELSE IF (@I_ProcedenciaID = @I_Proced_eupg)
		BEGIN
			SET @T_variables_conceptos = 'DECLARE @recibo_pago int = 0 ' + CHAR(13) +
										 'DECLARE @mora_pensiones int = 4788 ' + CHAR(13) +
										 'DECLARE @mat_ext_ma_reg_2008 int = 4817 ' + CHAR(13) +
										 'DECLARE @mat_ext_do_reg_2008 int = 4818 ' + CHAR(10) + CHAR(13) 

			SET @T_filtros_conceptos = '@recibo_pago, @mora_pensiones, @mat_ext_ma_reg_2008, @mat_ext_do_reg_2008'

		END
		ELSE IF (@I_ProcedenciaID = @I_Proced_euded)
		BEGIN
			SET @T_variables_conceptos = 'DECLARE @recibo_pago int = 0 ' +CHAR(13) +
										 'DECLARE @mora_pensiones int = 4788 ' +CHAR(13) +
										 'DECLARE @mat_2007_1 int = 304 ' + CHAR(13) +
										 'DECLARE @pen_2007_1 int = 305 ' + CHAR(13) +
										 'DECLARE @pen_2006_2 int = 301 ' + CHAR(13) +
										 'DECLARE @mat_2006_2 int = 300 ' + CHAR(13) +
										 'DECLARE @pen_2005_2 int = 54 ' + CHAR(13) +
										 'DECLARE @pen_ing_2014_2 int = 6645 ' + CHAR(10) + CHAR(13) 

			SET @T_filtros_conceptos = '@recibo_pago, @mora_pensiones, @mat_2007_1, @mat_2006_2, @pen_2007_1, @pen_2006_2, @pen_2005_2, @pen_ing_2014_2'

		END


		SET @T_SQL = 'DELETE TR_Ec_Det_Pagos ' + CHAR(13) +
					 ' WHERE I_ProcedenciaID = '+ CAST(@I_ProcedenciaID as varchar(3)) + ' ' + CHAR(13) +
							'AND EXISTS (SELECT * FROM TR_Ec_Obl ' + CHAR(13) +
										 'WHERE TR_Ec_Obl.I_RowID = I_OblRowID ' + CHAR(13) +
												'AND TR_Ec_Obl.Ano = ''' + @T_Anio + ''' ' + CHAR(13) +
												'AND TR_Ec_Obl.B_Migrado = 0 ' + CHAR(13) +
												'AND TR_Ec_Obl.I_ProcedenciaID = I_ProcedenciaID);'

		PRINT @T_SQL
		EXEC sp_executesql @T_SQL
		SET @I_Removidos = @@ROWCOUNT

						
		SET @T_SQL = 'DELETE TR_Ec_Det_Pagos ' + CHAR(13) +
					  'WHERE I_ProcedenciaID = '+ CAST(@I_ProcedenciaID as varchar(3)) + ' ' + CHAR(13) +
							'AND I_OblRowID IS NULL ' + CHAR(13) +
							'AND Ano = ''' + @T_Anio + ''' '
						
		PRINT @T_SQL
		EXEC sp_executesql @T_SQL
		SET @I_Removidos = @I_Removidos + @@ROWCOUNT



		SET @T_SQL = 'DECLARE @D_FecProceso datetime = GETDATE() ' + @T_variables_conceptos + CHAR(10) + CHAR(13) +
					 'INSERT INTO TR_Ec_Det_Pagos (Cod_alu, Cod_rc, Cuota_pago, Ano, P, Tipo_oblig, Concepto, Fch_venc, Nro_recibo, Fch_pago, ' + CHAR(13) +
												  'Id_lug_pag, Cantidad, Monto, Documento, Pagado, Concepto_f, Fch_elimin, Nro_ec, Fch_ec, ' + CHAR(13) +
												  'Pag_demas, Tipo_pago, No_banco, Cod_dep, I_ProcedenciaID, Eliminado, B_Obligacion, D_FecCarga, ' + CHAR(13) +
												  'Cod_cajero, B_Migrable, D_FecEvalua, B_Migrado, D_FecMigrado) ' + CHAR(13) +
										   'SELECT Cod_alu, Cod_rc, Cuota_pago, Ano, P, Tipo_oblig, Concepto, Fch_venc, Nro_recibo, Fch_pago, Id_lug_pag, ' + CHAR(13) +
												  'Cantidad, Monto, Documento, Pagado, Concepto_f, Fch_elimin, Nro_ec, Fch_ec, Pag_demas, Tipo_pago, No_banco, ' + CHAR(13) +
												  'Cod_dep, '+ CAST(@I_ProcedenciaID as varchar(3)) + ', Eliminado, 1 as B_Obligacion, @D_FecProceso as D_FecCarga, ' + CHAR(13) +
												  'Cod_cajero, 0 as B_Migrable, NULL as D_FecEvalua, 0  as B_Migrado, NULL as D_FecMigrado ' + CHAR(13) +
											'FROM  BD_OCEF_TemporalPagos.' + @T_SchemaDB + '.ec_det ' + CHAR(13) +
											'WHERE ' + CHAR(13) +
												  'Pagado = 1 ' + CHAR(13) +
						 						  'AND Ano = ''' + @T_Anio + ''' ' + CHAR(13) +
												  'AND Concepto_f = 1 ' + CHAR(13) +
												  'AND concepto IN (' + @T_filtros_conceptos +')' 

		PRINT @T_SQL
		EXEC sp_executesql @T_SQL
		SET @I_Insertados = @@ROWCOUNT

		SET @T_SQL =  @T_variables_conceptos + CHAR(13) + 
					 'SELECT * FROM BD_OCEF_TemporalPagos.' + @T_SchemaDB + '.ec_det ' + CHAR(13) +								
					 'WHERE Pagado = 1 ' + CHAR(13) +
							'AND Ano = ''' + @T_Anio + ''' ' + CHAR(13) +
							'AND Concepto_f = 1 ' + CHAR(13) +
							'AND concepto IN (' + @T_filtros_conceptos +')' 

		PRINT @T_SQL
		EXEC sp_executesql @T_SQL
		SET @I_EcDet = @@ROWCOUNT
		
		IF(@I_Removidos > 0)
		BEGIN
			SET @I_Actualizados =   @I_EcDet - @I_Insertados
		END
		ELSE
		BEGIN
			SET @I_Insertados = @I_EcDet
		END

		COMMIT TRANSACTION
		SET @B_Resultado = 1					
		SET @T_Message =  '[{ ' +
							 'Type: "summary", ' + 
							 'Title: "EC_DET (Pagos) Total ' + @T_Anio + ':", ' +
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
		IF(@@TRANCOUNT > 0)
		BEGIN
			ROLLBACK TRANSACTION
		END

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

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_Obligaciones_Pagos_MigracionTP_U_AsignarObligacionID')
	DROP PROCEDURE [dbo].[USP_Obligaciones_Pagos_MigracionTP_U_AsignarObligacionID]
GO

CREATE PROCEDURE USP_Obligaciones_Pagos_MigracionTP_U_AsignarObligacionID
(
	@I_ProcedenciaID tinyint,
	@T_Anio		  varchar(4),
	@B_Resultado  bit output,
	@T_Message	  nvarchar(4000) OUTPUT	
)
AS
/*
   	DESCRIPCION: Asigna el Id de obligacion a la pago para el año y procedecia

	DECLARE	@I_ProcedenciaID	tinyint = 1,
			@T_Anio				varchar(4) = '2008',
			@B_Resultado		bit,
			@T_Message			nvarchar(4000)
	EXEC USP_Obligaciones_Pagos_MigracionTP_U_AsignarObligacionID @I_ProcedenciaID, @T_Anio, @B_Resultado output, @T_Message output
	SELECT @B_Resultado as resultado, @T_Message as mensaj
*/
BEGIN 
	DECLARE @D_FecProceso datetime = GETDATE() 
	DECLARE @I_Actualizados int = 0

	BEGIN TRANSACTION
	BEGIN TRY
		--obtener ID de obligación que no se encuentren repetidos
		SELECT OBL2.*
		  INTO #temp_obl_pagados_sin_repetir_anio_procedencia 
		  FROM (SELECT Cuota_pago, Ano, P, Cod_alu, Cod_rc, Tipo_oblig, Fch_venc, Pagado, Monto, I_ProcedenciaID
		    	  FROM TR_Ec_Obl
				 WHERE Ano = @T_Anio
					   AND I_ProcedenciaID = @I_ProcedenciaID
					   AND Pagado = 1
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


		--1. Se actualiza pagos con ID de obligación del mismo monto
		UPDATE det_pg
		   SET I_OblRowID = obl.I_RowID
		  FROM TR_Ec_Det_Pagos det_pg
			   INNER JOIN #temp_obl_pagados_sin_repetir_anio_procedencia obl 
											ON det_pg.I_ProcedenciaID = obl.I_ProcedenciaID
										   AND det_pg.Cuota_pago = obl.Cuota_pago
										   AND det_pg.Cod_alu = obl.Cod_alu
										   AND det_pg.Cod_rc = obl.Cod_rc
										   AND det_pg.P = obl.P
										   AND det_pg.Fch_venc = obl.Fch_venc
										   AND det_pg.Monto = obl.Monto
										   AND det_pg.Pagado = obl.Pagado
		 WHERE det_pg.Ano = @T_Anio
			   AND det_pg.I_ProcedenciaID = @I_ProcedenciaID

		UPDATE det_pg
		   SET I_OblRowID = obl.I_RowID
		  FROM TR_Ec_Det_Pagos det_pg
			   INNER JOIN #temp_obl_pagados_sin_repetir_anio_procedencia obl 
											ON det_pg.I_ProcedenciaID = obl.I_ProcedenciaID
										   AND det_pg.Cuota_pago = obl.Cuota_pago
										   AND det_pg.Cod_alu = obl.Cod_alu
										   AND det_pg.Cod_rc = obl.Cod_rc
										   AND det_pg.P = obl.P
										   AND det_pg.Fch_venc = obl.Fch_venc
										   AND det_pg.Monto = obl.Monto
		 WHERE det_pg.Ano = @T_Anio
			   AND det_pg.I_ProcedenciaID = @I_ProcedenciaID 
               AND det_pg.I_OblRowID IS NULL
               

		SET @I_Actualizados = @@ROWCOUNT
		--2. Se actualiza pagos por mora con ID de obligación pagada con el mismo número de recibo

		UPDATE pg_mora
		   SET I_OblRowID = det_pg.I_OblRowID
		  FROM (SELECT * FROM TR_Ec_Det_Pagos WHERE Concepto <> 0) pg_mora
			   INNER JOIN (SELECT * FROM TR_Ec_Det_Pagos WHERE Concepto = 0) det_pg 
													ON pg_mora.Nro_recibo = det_pg.Nro_recibo
													AND pg_morA.Fch_pago = det_pg.Fch_pago
		 WHERE det_pg.Ano = @T_Anio
			   AND det_pg.I_ProcedenciaID = @I_ProcedenciaID


		SET @I_Actualizados = @I_Actualizados + @@ROWCOUNT

		COMMIT TRANSACTION
		SET @B_Resultado = 1					
		SET @T_Message =  '{' +
							 'Type: "summary", ' + 
							 'Title: "CabeceraObligacion asignados", ' + 
							 'Value: ' + CAST(@I_Actualizados AS varchar) +  
						  '}'
	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION
		SET @B_Resultado = 0
		SET @T_Message = '[{' +
							 'Type: "error", ' + 
							 'Title: "CabeceraObligacion asignados", ' + 
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


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_Obligaciones_Pagos_MigracionTP_U_InicializarEstadoValidacion')
	DROP PROCEDURE [dbo].[USP_Obligaciones_Pagos_MigracionTP_U_InicializarEstadoValidacion]
GO

CREATE PROCEDURE USP_Obligaciones_Pagos_MigracionTP_U_InicializarEstadoValidacion	
	@I_ProcedenciaID tinyint,
	@T_Anio	      varchar(4),
	@B_Resultado  bit output,
	@T_Message	  nvarchar(4000) OUTPUT	
AS
/*
   	DESCRIPCION: Reinicia los estados de validacion y migracion de la tabla de pagos 	

	DECLARE @I_ProcedenciaID	tinyint = 1, 
			@T_Anio		  varchar(4) = '2010',
			@B_Resultado  bit,
			@T_Message    nvarchar(4000)
	EXEC USP_Obligaciones_Pagos_MigracionTP_U_InicializarEstadoValidacion @I_ProcedenciaID, @T_Anio, @B_Resultado output, @T_Message output
	SELECT @B_Resultado as resultado, @T_Message as mensaje
*/
BEGIN
	BEGIN TRANSACTION
	BEGIN TRY
		DECLARE @Row_count int;
		DECLARE @I_TablaID INT = 7
		DECLARE @I_ObsTablaID INT 

		DELETE TI_ObservacionRegistroTabla
		 WHERE I_TablaID = @I_TablaID
		 	   AND I_ProcedenciaID = @I_ProcedenciaID
		 	   AND EXISTS (SELECT I_RowID FROM TR_Tasas_Ec_Det_Pagos DET
							WHERE DET.I_ProcedenciaID = TI_ObservacionRegistroTabla.I_ProcedenciaID
								  AND DET.I_RowID = TI_ObservacionRegistroTabla.I_FilaTablaID
								  AND Ano = @T_Anio)

		SET @I_ObsTablaID = ISNULL((SELECT MAX(I_ObsTablaID) FROM TI_ObservacionRegistroTabla), 0)

		DBCC CHECKIDENT('TI_ObservacionRegistroTabla', 'RESEED', @I_ObsTablaID);

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
		  FROM  TR_Ec_Det_Pagos det 
				INNER JOIN cte_obl_anio obl ON det.I_OblRowID = obl.I_OblRowID

		SET @Row_count = @@ROWCOUNT

		SET @B_Resultado = 1
		SET @T_Message =  '{' +
							 'Type: "summary", ' + 
							 'Type: "Estado validación actualizados", ' + 
							 'Value: ' + CAST(@Row_count AS varchar) +  
						  '}'

		COMMIT TRANSACTION;
	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION
		SET @B_Resultado = 0
		SET @T_Message = '[{ ' +
							 'Type: "error", ' + 
							 'Title: "Estado validación actualizados", ' + 
							 'Value: "' + ERROR_MESSAGE() + ' (Linea: ' + CAST(ERROR_LINE() AS varchar(11)) + ')."'  +
						  '}]' 
	END CATCH
END
GO


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_Obligaciones_Pagos_MigracionTP_U_InicializarEstadoValidacionPorID')
	DROP PROCEDURE [dbo].[USP_Obligaciones_Pagos_MigracionTP_U_InicializarEstadoValidacionPorID]
GO

CREATE PROCEDURE USP_Obligaciones_Pagos_MigracionTP_U_InicializarEstadoValidacionPorID	
	@I_OblRowID   int,
	@B_Resultado  bit output,
	@T_Message	  nvarchar(4000) OUTPUT	
AS
/*
	DECLARE @I_RowID  	  int,
			@B_Resultado  bit,
			@T_Message	  nvarchar(4000)
	EXEC USP_Obligaciones_Pagos_MigracionTP_U_InicializarEstadoValidacionPorID @I_RowID, @B_Resultado output, @T_Message output
	SELECT @B_Resultado as resultado, @T_Message as mensaje
*/
BEGIN
	DECLARE @I_TablaID INT = 7
	DECLARE @I_ObsTablaID INT

	BEGIN TRANSACTION
	BEGIN TRY 
		DELETE TI_ObservacionRegistroTabla
		 WHERE I_TablaID = @I_TablaID
		 	   AND EXISTS (SELECT I_RowID FROM TR_Ec_Det_Pagos Det
							WHERE Det.I_ProcedenciaID = TI_ObservacionRegistroTabla.I_ProcedenciaID
								  AND Det.I_RowID = TI_ObservacionRegistroTabla.I_FilaTablaID
								  AND Det.I_OblRowID = @I_OblRowID)
		
		SET @I_ObsTablaID = ISNULL((SELECT MAX(I_ObsTablaID) FROM TI_ObservacionRegistroTabla), 0)

		UPDATE	TR_Ec_Det
		   SET	B_Actualizado = IIF(B_Actualizado = 1, B_Actualizado, 0), 
				B_Migrable = 1, 
				D_FecMigrado = NULL, 
				B_Migrado = 0
		 WHERE	I_OblRowID = I_OblRowID

		SET @T_Message =  '{' +
							 'Type: "summary", ' + 
							 'Title: "Estados de validación de detalle actualizados", ' + 
							 'Value: ' + CAST(@@ROWCOUNT AS varchar) +  
						  '}'
		SET @B_Resultado = 1

		COMMIT TRANSACTION;
	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION
		SET @B_Resultado = 0
		SET @T_Message = '[{ ' +
							 'Type: "error", ' + 
							 'Title: "Estados de validación de detalle actualizados", ' + 
							 'Value: "' + ERROR_MESSAGE() + ' (Linea: ' + CAST(ERROR_LINE() AS varchar(11)) + ')."'  +
						  '}]' 
	END CATCH
END
GO




/*	
	===============================================================================================
		Validaciones de tablas de pagos	
	===============================================================================================
*/ 


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_Obligaciones_Pagos_MigracionTP_U_Validar_52_SinObligacionIDPorID')
	DROP PROCEDURE [dbo].USP_Obligaciones_Pagos_MigracionTP_U_Validar_52_SinObligacionIDPorID
GO

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_Obligaciones_Pagos_MigracionTP_U_Validar_52_SinObligacionID')
	DROP PROCEDURE [dbo].[USP_Obligaciones_Pagos_MigracionTP_U_Validar_52_SinObligacionID]
GO

CREATE PROCEDURE USP_Obligaciones_Pagos_MigracionTP_U_Validar_52_SinObligacionID	
	@I_ProcedenciaID tinyint,
	@T_Anio	      varchar(4),
	@B_Resultado  bit output,
	@T_Message	  nvarchar(4000) OUTPUT	
AS
/*
	DESCRIPCION: Marcar TR_Ec_Det_Pagos con B_Migrable = 0 los pagos con I_OblRowID = NULL  para la procedencia y a�o

	DECLARE	@I_ProcedenciaID	tinyint = 2,
			@T_Anio	      varchar(4) = '2016',
			@B_Resultado  bit,
			@T_Message	  nvarchar(4000)
	EXEC USP_Obligaciones_Pagos_MigracionTP_U_Validar_52_SinObligacionID @I_ProcedenciaID, @T_Anio, @B_Resultado output, @T_Message output
	SELECT @B_Resultado as resultado, @T_Message as mensaje
*/
BEGIN
	DECLARE @I_Observados int = 0
	DECLARE @D_FecProceso datetime = GETDATE() 
	DECLARE @I_ObservID int = 52
	DECLARE @I_TablaID int = 7

	BEGIN TRANSACTION
	BEGIN TRY

		UPDATE TR_Ec_Det_Pagos
		   SET B_Migrable = 0, 
			   D_FecMigrado = @D_FecProceso
		 WHERE I_OblRowID IS NULL
			   AND I_ProcedenciaID = @I_ProcedenciaID
			   AND Ano = @T_Anio
	 
		MERGE TI_ObservacionRegistroTabla AS TRG
		USING (SELECT DISTINCT @I_ObservID AS I_ObservID, @I_TablaID AS I_TablaID, I_RowID AS I_FilaTablaID, @D_FecProceso AS D_FecRegistro 
				 FROM TR_Ec_Det_Pagos 
				WHERE I_OblRowID IS NULL
					  AND I_ProcedenciaID = @I_ProcedenciaID
					  AND Ano = @T_Anio
			  ) AS SRC
		ON TRG.I_ObservID = SRC.I_ObservID AND TRG.I_TablaID = SRC.I_TablaID AND TRG.I_FilaTablaID = SRC.I_FilaTablaID
		WHEN MATCHED AND TRG.I_FilaTablaID = SRC.I_FilaTablaID THEN
			UPDATE SET D_FecRegistro = SRC.D_FecRegistro, 
					   B_Resuelto = 0
		WHEN NOT MATCHED BY TARGET THEN
			INSERT (I_ObservID, I_TablaID, I_FilaTablaID, D_FecRegistro, I_ProcedenciaID, B_ObligProc)
			VALUES (SRC.I_ObservID, SRC.I_TablaID, SRC.I_FilaTablaID, SRC.D_FecRegistro, @I_ProcedenciaID, 1);


		UPDATE OBS
		   SET D_FecResuelto = @D_FecProceso,
			   B_Resuelto = 1
		  FROM TI_ObservacionRegistroTabla OBS
			   INNER JOIN (SELECT * FROM TR_Ec_Det_Pagos 
							WHERE I_OblRowID IS NOT NULL 
								  AND Ano = @T_Anio 
								  AND I_ProcedenciaID = @I_ProcedenciaID
						  ) DPG 
						  ON OBS.I_FilaTablaID = DPG.I_RowID
							 AND OBS.I_ProcedenciaID = DPG.I_ProcedenciaID
		 WHERE OBS.I_ObservID = @I_ObservID 
			   AND OBS.I_TablaID = @I_TablaID

		SET @I_Observados = (SELECT COUNT(*) 
							  FROM TI_ObservacionRegistroTabla OBS 
									INNER JOIN TR_Ec_Det_Pagos DPG ON OBS.I_FilaTablaID = DPG.I_RowID 
																	  AND DPG.I_ProcedenciaID = OBS.I_ProcedenciaID
																	  AND OBS.I_TablaID = @I_TablaID 
							  WHERE OBS.I_ObservID = @I_ObservID
									AND DPG.Ano = @T_Anio 
									AND OBS.B_Resuelto = 0 
									AND OBS.I_ProcedenciaID = @I_ProcedenciaID)

		SELECT @I_Observados as cant_obs, @D_FecProceso as fec_proceso
		
		COMMIT TRANSACTION;

		SET @B_Resultado = 1
		SET @T_Message =  '{' +
							 'Type: "summary", ' + 
							 'Title: "Validar_52_SinObligacionID", ' + 
							 'Value: ' + CAST(@I_Observados AS varchar) +  
						  '}'
	END TRY
	BEGIN CATCH
		IF(@@TRANCOUNT > 0)
		BEGIN
			ROLLBACK TRANSACTION
		END

		SET @B_Resultado = 0
		SET @T_Message = '[{ ' +
							 'Type: "error", ' + 
							 'Title: "Validar_52_SinObligacionID", ' + 
							 'Value: "' + ERROR_MESSAGE() + ' (Linea: ' + CAST(ERROR_LINE() AS varchar(11)) + ')."'  +
						  '}]' 
	END CATCH
END
GO



IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_Obligaciones_Pagos_MigracionTP_U_Validar_53_MontoPagadoDetalle')
	DROP PROCEDURE [dbo].[USP_Obligaciones_Pagos_MigracionTP_U_Validar_53_MontoPagadoDetalle]
GO

CREATE PROCEDURE USP_Obligaciones_Pagos_MigracionTP_U_Validar_53_MontoPagadoDetalle	
	@I_ProcedenciaID tinyint,
	@T_Anio	      varchar(4),
	@B_Resultado  bit output,
	@T_Message	  nvarchar(4000) OUTPUT	
AS
/*
  	DESCRIPCION: Marcar TR_Ec_Det_Pagos con B_Migrable = 0 los pagos cuyo monto no coincida con el monto acumulado del detalle con estado pagado = 1 y 
				 eliminado = 0  para la procedencia y a�o

	DECLARE	@I_ProcedenciaID	tinyint = 1,
			@T_Anio	      varchar(4) = '2010',
			@B_Resultado  bit,
			@T_Message	  nvarchar(4000)
	EXEC USP_Obligaciones_Pagos_MigracionTP_U_Validar_53_MontoPagadoDetalle @I_ProcedenciaID, @T_Anio, @B_Resultado output, @T_Message output
	SELECT @B_Resultado as resultado, @T_Message as mensaj
*/
BEGIN
	DECLARE @I_Observados int = 0
	DECLARE @D_FecProceso datetime = GETDATE() 
	DECLARE @I_ObservID int = 53
	DECLARE @I_TablaID int = 7

	BEGIN TRANSACTION
	BEGIN TRY

		SELECT I_OblRowID, SUM(Monto) Monto
		  INTO #temp_detalle_monto_sum
		  FROM TR_Ec_Det
		 WHERE Ano = @T_Anio
			   AND I_ProcedenciaID = @I_ProcedenciaID
			   AND Eliminado = 0
			   AND Pagado = 1
		 GROUP BY I_OblRowID

		SELECT det_pg.I_OblRowID  
		  INTO #temp_detalle_monto_pago_monto
		  FROM TR_Ec_Det_Pagos det_pg
			   INNER JOIN #temp_detalle_monto_sum tmp ON det_pg.I_OblRowID = tmp.I_OblRowID
		 WHERE det_pg.Monto <> tmp.Monto
		 	   AND Concepto = 0
			   AND Pagado = 1
			   AND Eliminado = 0

		UPDATE Det_pg
		   SET B_Migrable = 0,
			   D_FecEvalua = @D_FecProceso
		  FROM TR_Ec_Det_Pagos Det_pg 
			   INNER JOIN #temp_detalle_monto_pago_monto tmp ON Det_pg.I_OblRowID = tmp.I_OblRowID

		MERGE TI_ObservacionRegistroTabla AS TRG
		USING (SELECT @I_ObservID AS I_ObservID, @I_TablaID AS I_TablaID, Det_pg.I_RowID AS I_FilaTablaID, 
					  @D_FecProceso AS D_FecRegistro, Det_pg.I_ProcedenciaID 
				 FROM TR_Ec_Det_Pagos Det_pg  
			   		  INNER JOIN #temp_detalle_monto_pago_monto tmp ON Det_pg.I_OblRowID = tmp.I_OblRowID
			  ) AS SRC
		ON TRG.I_ObservID = SRC.I_ObservID AND TRG.I_TablaID = SRC.I_TablaID AND TRG.I_FilaTablaID = SRC.I_FilaTablaID
		WHEN MATCHED AND TRG.I_ProcedenciaID = SRC.I_ProcedenciaID THEN
			UPDATE SET D_FecRegistro = SRC.D_FecRegistro,
					   B_Resuelto = 0
		WHEN NOT MATCHED BY TARGET THEN
			INSERT (I_ObservID, I_TablaID, I_FilaTablaID, D_FecRegistro, I_ProcedenciaID, B_ObligProc)
			VALUES (SRC.I_ObservID, SRC.I_TablaID, SRC.I_FilaTablaID, SRC.D_FecRegistro, @I_ProcedenciaID, 1);
		
		UPDATE OBS
		   SET D_FecResuelto = @D_FecProceso,
		   	   B_Resuelto = 1
		  FROM TI_ObservacionRegistroTabla OBS
		  	   INNER JOIN (SELECT det_pg.I_RowID, det_pg.I_ProcedenciaID, tmp.I_OblRowID as TempOblRowID
			   				 FROM TR_Ec_Det_Pagos det_pg
								  LEFT JOIN #temp_detalle_monto_pago_monto tmp ON tmp.I_OblRowID = det_pg.I_OblRowID
							WHERE tmp.I_OblRowID IS NULL
								  AND det_pg.Ano = @T_Anio
								  AND det_pg.I_ProcedenciaID = @I_ProcedenciaID
			   			  ) DET_PG ON OBS.I_FilaTablaID = DET_PG.I_RowID
						  		   AND OBS.I_ProcedenciaID = DET_PG.I_ProcedenciaID 
		 WHERE OBS.I_ObservID = @I_ObservID 
		 	   AND OBS.I_TablaID = @I_TablaID 
		
		SET @I_Observados = (SELECT COUNT(*) 
							   FROM TI_ObservacionRegistroTabla OBS 
									INNER JOIN TR_Ec_Det_Pagos DET_PG ON OBS.I_FilaTablaID = DET_PG.I_RowID 
																	  AND DET_PG.I_ProcedenciaID = OBS.I_ProcedenciaID
							  WHERE OBS.I_ObservID = @I_ObservID 
									AND DET_PG.Ano = @T_Anio
									AND DET_PG.I_ProcedenciaID = @I_ProcedenciaID 
									AND OBS.B_Resuelto = 0
							)

		SELECT @I_Observados as cant_obs, @D_FecProceso as fec_proceso		 

		COMMIT TRANSACTION;

		SET @B_Resultado = 1
		SET @T_Message = '{ ' +
							 'Type: "summary", ' + 
							 'Title: "Validar_53_MontoPagadoDetalle", ' + 
							 'Value: ' + CAST(@I_Observados AS varchar) +
						 '}' 


	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION
		SET @B_Resultado = 0
		SET @T_Message = '[{ ' +
							 'Type: "error", ' + 
							 'Title: "Validar_53_MontoPagadoDetalle", ' + 
							 'Value: "' + ERROR_MESSAGE() + ' (Linea: ' + CAST(ERROR_LINE() AS varchar(11)) + ')."'  +
						  '}]' 
	END CATCH
END
GO


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_Obligaciones_Pagos_MigracionTP_U_Validar_53_MontoPagadoDetallePorID')
	DROP PROCEDURE [dbo].[USP_Obligaciones_Pagos_MigracionTP_U_Validar_53_MontoPagadoDetallePorID]
GO

CREATE PROCEDURE USP_Obligaciones_Pagos_MigracionTP_U_Validar_53_MontoPagadoDetallePorID	
	@I_OblRowID	  int,
	@B_Resultado  bit output,
	@T_Message	  nvarchar(4000) OUTPUT	
AS
/*
  	DESCRIPCION: Marcar TR_Ec_Det_Pagos con B_Migrable = 0 el pago cuyo monto no coincida con el monto acumulado del detalle con estado pagado = 1 y eliminado = 0 para el I_OblRowID

	DECLARE	@I_OblRowID	  int = 3,
			@B_Resultado  bit,
			@T_Message	  nvarchar(4000)
	EXEC USP_Obligaciones_Pagos_MigracionTP_U_Validar_53_MontoPagadoDetallePorID @I_OblRowID, @B_Resultado output, @T_Message output
	SELECT @B_Resultado as resultado, @T_Message as mensaj
*/
BEGIN
	DECLARE @I_Observados int = 0
	DECLARE @D_FecProceso datetime = GETDATE() 
	DECLARE @I_ObservID int = 53
	DECLARE @I_TablaID int = 7

	BEGIN TRANSACTION
	BEGIN TRY

		SELECT I_OblRowID, SUM(Monto) Monto
		  INTO #temp_detalle_monto_sum
		  FROM TR_Ec_Det
		 WHERE Eliminado = 0
		 	   AND Pagado = 1
		 	   AND I_OblRowID = @I_OblRowID
		 GROUP BY I_OblRowID

		SELECT det_pg.I_OblRowID  
		  INTO #temp_detalle_monto_pago_monto
		  FROM TR_Ec_Det_Pagos det_pg
			   INNER JOIN #temp_detalle_monto_sum tmp ON det_pg.I_OblRowID = tmp.I_OblRowID
		 WHERE det_pg.Monto <> tmp.Monto
		 	   AND Concepto = 0
			   AND Pagado = 1
			   AND Eliminado = 0

		UPDATE Det_pg
		   SET B_Migrable = 0,
			   D_FecEvalua = @D_FecProceso
		  FROM TR_Ec_Det_Pagos Det_pg 
			   INNER JOIN #temp_detalle_monto_pago_monto tmp ON Det_pg.I_OblRowID = tmp.I_OblRowID

		MERGE TI_ObservacionRegistroTabla AS TRG
		USING (SELECT @I_ObservID AS I_ObservID, @I_TablaID AS I_TablaID, Det_pg.I_RowID AS I_FilaTablaID, 
					  @D_FecProceso AS D_FecRegistro, Det_pg.I_ProcedenciaID 
				 FROM TR_Ec_Det_Pagos Det_pg  
			   		  INNER JOIN #temp_detalle_monto_pago_monto tmp ON Det_pg.I_OblRowID = tmp.I_OblRowID
			  ) AS SRC
		ON TRG.I_ObservID = SRC.I_ObservID AND TRG.I_TablaID = SRC.I_TablaID AND TRG.I_FilaTablaID = SRC.I_FilaTablaID
		WHEN MATCHED AND TRG.I_ProcedenciaID = SRC.I_ProcedenciaID THEN
			UPDATE SET D_FecRegistro = SRC.D_FecRegistro,
					   B_Resuelto = 0
		WHEN NOT MATCHED BY TARGET THEN
			INSERT (I_ObservID, I_TablaID, I_FilaTablaID, D_FecRegistro, I_ProcedenciaID, B_ObligProc)
			VALUES (SRC.I_ObservID, SRC.I_TablaID, SRC.I_FilaTablaID, SRC.D_FecRegistro, SRC.I_ProcedenciaID, 1);
		
		UPDATE OBS
		   SET D_FecResuelto = @D_FecProceso,
		   	   B_Resuelto = 1
		  FROM TI_ObservacionRegistroTabla OBS
		  	   INNER JOIN (SELECT det_pg.I_RowID, det_pg.I_ProcedenciaID, tmp.I_OblRowID as TempOblRowID
			   				 FROM TR_Ec_Det_Pagos det_pg
								  LEFT JOIN #temp_detalle_monto_pago_monto tmp ON tmp.I_OblRowID = det_pg.I_OblRowID
							WHERE tmp.I_OblRowID IS NULL
								  AND det_pg.I_OblRowID = @I_OblRowID
			   			  ) DET_PG ON OBS.I_FilaTablaID = DET_PG.I_RowID
						  		   AND OBS.I_ProcedenciaID = DET_PG.I_ProcedenciaID 
		 WHERE OBS.I_ObservID = @I_ObservID 
		 	   AND OBS.I_TablaID = @I_TablaID 
		
		SET @I_Observados = (SELECT COUNT(*) 
							   FROM TI_ObservacionRegistroTabla OBS 
									INNER JOIN TR_Ec_Det_Pagos DET_PG ON OBS.I_FilaTablaID = DET_PG.I_RowID 
																	  AND DET_PG.I_ProcedenciaID = OBS.I_ProcedenciaID
							  WHERE OBS.I_ObservID = @I_ObservID 
									AND DET_PG.I_OblRowID = @I_OblRowID 
									AND OBS.B_Resuelto = 0
							)

		SELECT @I_Observados as cant_obs, @D_FecProceso as fec_proceso		 

		COMMIT TRANSACTION;

		SET @B_Resultado = 1
		SET @T_Message = '{ ' +
							 'Type: "summary", ' + 
							 'Title: "Validar_53_MontoPagadoDetallePorID", ' + 
							 'Value: ' + CAST(@I_Observados AS varchar) +
						 '}' 
	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION
		SET @B_Resultado = 0
		SET @T_Message = '[{ ' +
							 'Type: "error", ' + 
							 'Title: "Validar_53_MontoPagadoDetallePorID", ' + 
							 'Value: "' + ERROR_MESSAGE() + ' (Linea: ' + CAST(ERROR_LINE() AS varchar(11)) + ')."'  +
						  '}]' 
	END CATCH
END
GO

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_Obligaciones_Pagos_MigracionTP_U_Validar_54_EstadoPagadoObligacion')
	DROP PROCEDURE [dbo].[USP_Obligaciones_Pagos_MigracionTP_U_Validar_54_EstadoPagadoObligacion]
GO

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_Obligaciones_Pagos_MigracionTP_U_Validar_54_EstadoPagadoObligacionPorID')
	DROP PROCEDURE [dbo].[USP_Obligaciones_Pagos_MigracionTP_U_Validar_54_EstadoPagadoObligacionPorID]
GO


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_Obligaciones_Pagos_MigracionTP_U_Validar_55_ExisteEnDestinoConOtroBanco')
	DROP PROCEDURE [dbo].[USP_Obligaciones_Pagos_MigracionTP_U_Validar_55_ExisteEnDestinoConOtroBanco]
GO


CREATE PROCEDURE [dbo].[USP_Obligaciones_Pagos_MigracionTP_U_Validar_55_ExisteEnDestinoConOtroBanco]	
	@I_ProcedenciaID	tinyint,
	@T_Anio				varchar(4),
	@B_Resultado		bit output,
	@T_Message			nvarchar(4000) OUTPUT	
AS
/*
  	DESCRIPCION: Marcar TR_Ec_Det_Pagos con B_Migrable = 0 cuando el pago de la obligacion no migrada existe en la base de datos de destino con otro banco para la procedencia y año.

	DECLARE @I_ProcedenciaID tinyint = 1,
			@T_Anio		 varchar(4) = '2010', 
			@B_Resultado  bit, 
			@T_Message nvarchar(4000)
	EXEC USP_Obligaciones_Pagos_MigracionTP_U_Validar_55_ExisteEnDestinoConOtroBanco @I_ProcedenciaID, @T_Anio, @B_Resultado output, @T_Message output
	SELECT @B_Resultado as resultado, @T_Message as mensaje
*/
BEGIN
	DECLARE @I_Observados int = 0
	DECLARE @D_FecProceso datetime = GETDATE() 
	DECLARE @I_ObservID int = 55
	DECLARE @I_TablaID int = 7

	BEGIN TRANSACTION
	BEGIN TRY
		
		SELECT Det_pg.* 
		  INTO #temp_pago_existe_otro_banco 
		  FROM BD_OCEF_CtasPorCobrar.dbo.TR_PagoBanco Ctas_pbco 
			   INNER JOIN TR_Ec_Det_Pagos Det_pg ON Ctas_pbco.C_CodOperacion = Det_pg.Nro_recibo
			   										AND Ctas_pbco.I_MontoPago = Det_pg.Monto
													AND Ctas_pbco.D_FecPago = Det_pg.Fch_pago
													AND Ctas_pbco.C_CodDepositante = Det_pg.Cod_alu
		 WHERE Ctas_pbco.I_EntidadFinanID <> 1
			   AND ISNULL(Ctas_pbco.B_Migrado, 0) = 0
			   AND Det_pg.Concepto = 0
			   AND Det_pg.Ano = @T_Anio 
			   AND Det_pg.I_ProcedenciaID = @I_ProcedenciaID 

		UPDATE Det_pg
		   SET B_Migrable = 0,
		   	   D_FecEvalua = @D_FecProceso
		  FROM TR_Ec_Det_Pagos Det_pg
			   INNER JOIN #temp_pago_existe_otro_banco tmp ON Det_pg.I_RowID = tmp.I_RowID
		 
		MERGE TI_ObservacionRegistroTabla AS TRG
		USING (SELECT @I_ObservID AS I_ObservID, @I_TablaID AS I_TablaID, EDP.I_RowID AS I_FilaTablaID, @D_FecProceso AS D_FecRegistro 
				 FROM TR_Ec_Det_Pagos EDP
					  INNER JOIN #temp_pago_existe_otro_banco tmp ON EDP.I_RowID = tmp.I_RowID
			  ) AS SRC
		ON TRG.I_ObservID = SRC.I_ObservID AND TRG.I_TablaID = SRC.I_TablaID AND TRG.I_FilaTablaID = SRC.I_FilaTablaID
		WHEN MATCHED AND TRG.I_FilaTablaID = SRC.I_FilaTablaID THEN
			UPDATE SET D_FecRegistro = SRC.D_FecRegistro, 
					   B_Resuelto = 0
		WHEN NOT MATCHED BY TARGET THEN
			INSERT (I_ObservID, I_TablaID, I_FilaTablaID, D_FecRegistro, I_ProcedenciaID, B_ObligProc)
			VALUES (SRC.I_ObservID, SRC.I_TablaID, SRC.I_FilaTablaID, SRC.D_FecRegistro, @I_ProcedenciaID, 1);

		UPDATE OBS
		   SET D_FecResuelto = @D_FecProceso,
			   B_Resuelto = 1
		  FROM TI_ObservacionRegistroTabla OBS
			   INNER JOIN (SELECT EDP.* FROM TR_Ec_Det_Pagos EDP
								  LEFT JOIN #temp_pago_existe_otro_banco tmp ON EDP.I_RowID = tmp.I_RowID
							WHERE EDP.I_ProcedenciaID = @I_ProcedenciaID
								  AND EDP.Ano = @T_Anio
								  AND EDP.Concepto = 0
								  AND tmp.I_RowID IS NULL 
						  ) DPG ON OBS.I_FilaTablaID = DPG.I_RowID
		 WHERE OBS.I_ObservID = @I_ObservID 
			   AND OBS.I_TablaID = @I_TablaID


		SET @I_Observados = (SELECT COUNT(*) 
							   FROM TI_ObservacionRegistroTabla OBS 
									INNER JOIN TR_Ec_Det_Pagos DET_PG ON OBS.I_FilaTablaID = DET_PG.I_RowID 
																	  	 AND DET_PG.I_ProcedenciaID = OBS.I_ProcedenciaID
							  WHERE OBS.I_ObservID = @I_ObservID 
							  		AND OBS.I_TablaID = @I_TablaID
									AND DET_PG.I_ProcedenciaID = @I_ProcedenciaID 
									AND OBS.B_Resuelto = 0
							)

		SELECT @I_Observados as cant_obs, @D_FecProceso as fec_proceso		 

		COMMIT TRANSACTION;

		SET @B_Resultado = 1
		SET @T_Message = '{ ' +
							 'Type: "summary", ' + 
							 'Title: "Validar_55_ExisteEnDestinoConOtroBanco", ' + 
							 'Value: ' + CAST(@I_Observados AS varchar) +
						 '}' 
	END TRY
	BEGIN CATCH
		IF(@@TRANCOUNT > 0)
		BEGIN
			ROLLBACK TRANSACTION
		END

		SET @B_Resultado = 0
		SET @T_Message = '[{ ' +
							 'Type: "error", ' + 
							 'Title: "Validar_55_ExisteEnDestinoConOtroBanco", ' + 
							 'Value: "' + ERROR_MESSAGE() + ' (Linea: ' + CAST(ERROR_LINE() AS varchar(11)) + ')."'  +
						  '}]' 
	END CATCH
END
GO


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_Obligaciones_Pagos_MigracionTP_U_Validar_55_ExisteEnDestinoConOtroBancoPorID')
	DROP PROCEDURE [dbo].[USP_Obligaciones_Pagos_MigracionTP_U_Validar_55_ExisteEnDestinoConOtroBancoPorID]
GO


CREATE PROCEDURE [dbo].[USP_Obligaciones_Pagos_MigracionTP_U_Validar_55_ExisteEnDestinoConOtroBancoPorID]	
	@I_OblRowID			int,
	@B_Resultado		bit output,
	@T_Message			nvarchar(4000) OUTPUT	
AS
/*
  	DESCRIPCION: Marcar TR_Ec_Det_Pagos con B_Migrable = 0 cuando el pago de la obligacion I_OblRowID no migrada existe en la base de datos de destino para la procedencia y a�o.
	
	DECLARE @I_OblRowID	 int,
			@B_Resultado  bit, 
			@T_Message nvarchar(4000)
	EXEC USP_Obligaciones_Pagos_MigracionTP_U_Validar_55_ExisteEnDestinoConOtroBancoPorID @I_OblRowID, @B_Resultado output, @T_Message output
	SELECT @B_Resultado as resultado, @T_Message as mensaje
*/
BEGIN

	DECLARE @I_Observados int = 0
	DECLARE @D_FecProceso datetime = GETDATE() 
	DECLARE @I_ObservID int = 55
	DECLARE @I_TablaID int = 7
	
	BEGIN TRANSACTION;
	BEGIN TRY 
		
		SELECT Det_pg.* 
		  INTO #temp_pago_existe_otro_banco 
		  FROM BD_OCEF_CtasPorCobrar.dbo.TR_PagoBanco Ctas_pbco 
			   INNER JOIN TR_Ec_Det_Pagos Det_pg ON Ctas_pbco.C_CodOperacion = Det_pg.Nro_recibo
			   										AND Ctas_pbco.I_MontoPago = Det_pg.Monto
													AND Ctas_pbco.D_FecPago = Det_pg.Fch_pago
													AND Ctas_pbco.C_CodDepositante = Det_pg.Cod_alu
		 WHERE Ctas_pbco.I_EntidadFinanID <> 1
			   AND ISNULL(Ctas_pbco.B_Migrado, 0) = 0
			   AND Det_pg.Concepto = 0
			   AND Det_pg.I_OblRowID = @I_OblRowID

		UPDATE Det_pg
		   SET B_Migrable = 0,
		   	   D_FecEvalua = @D_FecProceso
		  FROM TR_Ec_Det_Pagos Det_pg
			   INNER JOIN #temp_pago_existe_otro_banco tmp ON Det_pg.I_RowID = tmp.I_RowID
		 
		MERGE TI_ObservacionRegistroTabla AS TRG
		USING (SELECT @I_ObservID AS I_ObservID, @I_TablaID AS I_TablaID, EDP.I_RowID AS I_FilaTablaID, 
					  @D_FecProceso AS D_FecRegistro, EDP.I_ProcedenciaID 
				 FROM TR_Ec_Det_Pagos EDP
					  INNER JOIN #temp_pago_existe_otro_banco tmp ON EDP.I_RowID = tmp.I_RowID
			  ) AS SRC
		ON TRG.I_ObservID = SRC.I_ObservID AND TRG.I_TablaID = SRC.I_TablaID AND TRG.I_FilaTablaID = SRC.I_FilaTablaID
		WHEN MATCHED AND TRG.I_FilaTablaID = SRC.I_FilaTablaID THEN
			UPDATE SET D_FecRegistro = SRC.D_FecRegistro, 
					   B_Resuelto = 0
		WHEN NOT MATCHED BY TARGET THEN
			INSERT (I_ObservID, I_TablaID, I_FilaTablaID, D_FecRegistro, I_ProcedenciaID, B_ObligProc)
			VALUES (SRC.I_ObservID, SRC.I_TablaID, SRC.I_FilaTablaID, SRC.D_FecRegistro, SRC.I_ProcedenciaID, 1);

		UPDATE OBS
		   SET D_FecResuelto = @D_FecProceso,
			   B_Resuelto = 1
		  FROM TI_ObservacionRegistroTabla OBS
			   INNER JOIN (SELECT EDP.* FROM TR_Ec_Det_Pagos EDP
								  LEFT JOIN #temp_pago_existe_otro_banco tmp ON EDP.I_RowID = tmp.I_RowID
							WHERE EDP.I_OblRowID = @I_OblRowID
								  AND EDP.Concepto = 0
								  AND tmp.I_RowID IS NULL 
						  ) DPG ON OBS.I_FilaTablaID = DPG.I_RowID
		 WHERE OBS.I_ObservID = @I_ObservID 
			   AND OBS.I_TablaID = @I_TablaID


		SET @I_Observados = (SELECT COUNT(*) 
							   FROM TI_ObservacionRegistroTabla OBS 
									INNER JOIN TR_Ec_Det_Pagos DET_PG ON OBS.I_FilaTablaID = DET_PG.I_RowID 
																	  	 AND DET_PG.I_ProcedenciaID = OBS.I_ProcedenciaID
							  WHERE OBS.I_ObservID = @I_ObservID 
							  		AND OBS.I_TablaID = @I_TablaID
									AND DET_PG.I_OblRowID = @I_OblRowID 
									AND OBS.B_Resuelto = 0
							)

		SELECT @I_Observados as cant_obs, @D_FecProceso as fec_proceso		 

		COMMIT TRANSACTION
					
		SET @B_Resultado = 1
		SET @T_Message = '[{ ' +
							 'Type: "summary", ' + 
							 'Title: "Validar_55_ExisteEnDestinoConOtroBancoPorID", ' + 
							 'Value: ' + CAST(@I_Observados AS varchar) +
						  '}]' 
	END TRY
	BEGIN CATCH
		IF(@@TRANCOUNT > 0)
		BEGIN
			ROLLBACK TRANSACTION
		END

		SET @B_Resultado = 0
		SET @T_Message = '[{ ' +
							 'Type: "error", ' + 
							 'Title: "Validar_55_ExisteEnDestinoConOtroBancoPorID", ' + 
							 'Value: "' + ERROR_MESSAGE() + ' (Linea: ' + CAST(ERROR_LINE() AS varchar(11)) + ')."'  +
						  '}]' 
	END CATCH
END
GO


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_Obligaciones_Pagos_MigracionTP_U_Validar_56_DetalleObservado')
	DROP PROCEDURE [dbo].[USP_Obligaciones_Pagos_MigracionTP_U_Validar_56_DetalleObservado]
GO

CREATE PROCEDURE [dbo].[USP_Obligaciones_Pagos_MigracionTP_U_Validar_56_DetalleObservado]
	@I_ProcedenciaID tinyint,
	@T_Anio			varchar(4) = NULL,
	@B_Resultado	bit output,
	@T_Message		nvarchar(4000) OUTPUT	
AS
/*
  	DESCRIPCION: Marcar TR_Ec_Det_Pagos con B_Migrable = 0 cuando el pago tiene observaciones de conceptos en el detalle para la procedencia y año.

	DECLARE @I_ProcedenciaID	tinyint = 3, 
			@T_Anio		  varchar(4) = '2005',
			@B_Resultado  bit,
			@T_Message    nvarchar(4000)
	EXEC USP_Obligaciones_Pagos_MigracionTP_U_Validar_56_DetalleObservado @I_ProcedenciaID, @T_Anio, @B_Resultado output, @T_Message output
	SELECT @B_Resultado as resultado, @T_Message as mensaje
*/
BEGIN
	DECLARE @I_Observados int = 0
	DECLARE @D_FecProceso datetime = GETDATE() 
	DECLARE @I_ObservID int = 56
	DECLARE @I_TablaID int = 7
	DECLARE @I_DetTablaID int = 4

	BEGIN TRANSACTION
	BEGIN TRY
		
		SELECT Det.*
		  INTO #temp_pago_det_observada
		  FROM TR_Ec_Det Det 
			   INNER JOIN TI_ObservacionRegistroTabla Obs ON Det.I_RowID = Obs.I_FilaTablaID
															 AND Det.I_ProcedenciaID = Obs.I_ProcedenciaID
															 AND Obs.I_TablaID = @I_DetTablaID
		 WHERE Obs.B_Resuelto = 0
			   AND Det.Ano = @T_Anio 
			   AND Det.I_ProcedenciaID = @I_ProcedenciaID


		UPDATE Det_Pagos 
		   SET B_Migrable = 0, 
			   D_FecMigrado = @D_FecProceso
		  FROM TR_Ec_Det_Pagos Det_Pagos
			   INNER JOIN #temp_pago_det_observada tmp ON Det_Pagos.I_OblRowID = tmp.I_OblRowID 

		MERGE TI_ObservacionRegistroTabla AS TRG
		USING (SELECT DISTINCT @I_ObservID AS I_ObservID, @I_TablaID AS I_TablaID, Det_Pagos.I_RowID AS I_FilaTablaID, @D_FecProceso AS D_FecRegistro 
				 FROM TR_Ec_Det_Pagos Det_Pagos
				      INNER JOIN #temp_pago_det_observada tmp ON Det_Pagos.I_OblRowID = tmp.I_OblRowID 
			  ) AS SRC
		ON TRG.I_ObservID = SRC.I_ObservID AND TRG.I_TablaID = SRC.I_TablaID AND TRG.I_FilaTablaID = SRC.I_FilaTablaID
		WHEN MATCHED AND TRG.I_FilaTablaID = SRC.I_FilaTablaID THEN
			UPDATE SET D_FecRegistro = SRC.D_FecRegistro, 
					   B_Resuelto = 0
		WHEN NOT MATCHED BY TARGET THEN
			INSERT (I_ObservID, I_TablaID, I_FilaTablaID, D_FecRegistro, I_ProcedenciaID, B_ObligProc)
			VALUES (SRC.I_ObservID, SRC.I_TablaID, SRC.I_FilaTablaID, SRC.D_FecRegistro, @I_ProcedenciaID, 1);


		UPDATE OBS
		   SET D_FecResuelto = @D_FecProceso,
			   B_Resuelto = 1
		  FROM TI_ObservacionRegistroTabla OBS
			   INNER JOIN (SELECT EDP.* FROM TR_Ec_Det_Pagos EDP
								  LEFT JOIN #temp_pago_det_observada tmp ON EDP.I_OblRowID = tmp.I_OblRowID
							WHERE EDP.I_ProcedenciaID = @I_ProcedenciaID
								  AND EDP.Ano = @T_Anio
								  AND tmp.I_RowID IS NULL 
						  ) DPG ON OBS.I_FilaTablaID = DPG.I_RowID
		 WHERE OBS.I_ObservID = @I_ObservID 
			   AND OBS.I_TablaID = @I_TablaID


		SET @I_Observados = (SELECT COUNT(*) 
							   FROM TI_ObservacionRegistroTabla OBS 
									INNER JOIN TR_Ec_Det_Pagos DET_PG ON OBS.I_FilaTablaID = DET_PG.I_RowID 
																	  	 AND DET_PG.I_ProcedenciaID = OBS.I_ProcedenciaID
							  WHERE OBS.I_ObservID = @I_ObservID 
							  		AND OBS.I_TablaID = @I_TablaID
									AND DET_PG.I_ProcedenciaID = @I_ProcedenciaID 
									AND OBS.B_Resuelto = 0
							)

		SELECT @I_Observados as cant_obs, @D_FecProceso as fec_proceso		 

		COMMIT TRANSACTION 

		SET @B_Resultado = 1
		SET @T_Message = '{ ' +
							 'Type: "summary", ' + 
							 'Title: "Validar_56_DetalleObservado", ' + 
							 'Value: ' + CAST(@I_Observados AS varchar) +
						 '}' 
	END TRY
	BEGIN CATCH
		IF(@@TRANCOUNT > 0)
		BEGIN
			ROLLBACK TRANSACTION
		END

		SET @B_Resultado = 0
		SET @T_Message = '[{ ' +
							 'Type: "error", ' + 
							 'Title: "Validar_56_DetalleObservado", ' + 
							 'Value: "' + ERROR_MESSAGE() + ' (Linea: ' + CAST(ERROR_LINE() AS varchar(11)) + ')."'  +
						  '}]' 
	END CATCH
END
GO


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_Obligaciones_Pagos_MigracionTP_U_Validar_56_DetalleObservadoPorOblID')
	DROP PROCEDURE [dbo].[USP_Obligaciones_Pagos_MigracionTP_U_Validar_56_DetalleObservadoPorOblID]
GO

CREATE PROCEDURE [dbo].[USP_Obligaciones_Pagos_MigracionTP_U_Validar_56_DetalleObservadoPorOblID]
	@I_OblRowID			int,
	@B_Resultado	bit output,
	@T_Message		nvarchar(4000) OUTPUT	
AS
/*
  	DESCRIPCION: Marcar TR_Ec_Det_Pagos con B_Migrable = 0 cuando el pago tiene observaciones de conceptos en el detalle para la obligación I_OblRowID	

	DECLARE @I_OblRowID	  int,
			@B_Resultado  bit,
			@T_Message    nvarchar(4000)
	EXEC USP_Obligaciones_Pagos_MigracionTP_U_Validar_56_DetalleObservadoPorOblID @I_OblRowID, @B_Resultado output, @T_Message output
	SELECT @B_Resultado as resultado, @T_Message as mensaje
*/
BEGIN
	DECLARE @I_Observados int = 0
	DECLARE @I_ObservadosObl int = 0
	DECLARE @D_FecProceso datetime = GETDATE() 
	DECLARE @I_ObservID int = 56
	DECLARE @I_TablaID int = 7
	DECLARE @I_DetTablaID int = 4

	BEGIN TRANSACTION
	BEGIN TRY
		
		SELECT Det.*
		  INTO #temp_obl_det_observada
		  FROM TR_Ec_Det Det 
			   INNER JOIN TI_ObservacionRegistroTabla Obs ON Det.I_RowID = Obs.I_FilaTablaID
															 AND Det.I_ProcedenciaID = Obs.I_ProcedenciaID
															 AND Obs.I_TablaID = @I_DetTablaID
		 WHERE Obs.B_Resuelto = 0
			   AND Det.I_OblRowID = @I_OblRowID


		UPDATE Det_Pagos 
		   SET B_Migrable = 0, 
			   D_FecMigrado = @D_FecProceso
		  FROM TR_Ec_Det_Pagos Det_Pagos
			   INNER JOIN #temp_obl_det_observada tmp ON Det_Pagos.I_OblRowID = tmp.I_OblRowID 

		MERGE TI_ObservacionRegistroTabla AS TRG
		USING (SELECT DISTINCT @I_ObservID AS I_ObservID, @I_TablaID AS I_TablaID, Det_Pagos.I_RowID AS I_FilaTablaID, 
				      @D_FecProceso AS D_FecRegistro, Det_Pagos.I_ProcedenciaID 
				 FROM TR_Ec_Det_Pagos Det_Pagos
				      INNER JOIN #temp_obl_det_observada tmp ON Det_Pagos.I_OblRowID = tmp.I_OblRowID 
			  ) AS SRC
		ON TRG.I_ObservID = SRC.I_ObservID AND TRG.I_TablaID = SRC.I_TablaID AND TRG.I_FilaTablaID = SRC.I_FilaTablaID
		WHEN MATCHED AND TRG.I_FilaTablaID = SRC.I_FilaTablaID THEN
			UPDATE SET D_FecRegistro = SRC.D_FecRegistro, 
					   B_Resuelto = 0
		WHEN NOT MATCHED BY TARGET THEN
			INSERT (I_ObservID, I_TablaID, I_FilaTablaID, D_FecRegistro, I_ProcedenciaID, B_ObligProc)
			VALUES (SRC.I_ObservID, SRC.I_TablaID, SRC.I_FilaTablaID, SRC.D_FecRegistro, SRC.I_ProcedenciaID, 1);


		UPDATE OBS
		   SET D_FecResuelto = @D_FecProceso,
			   B_Resuelto = 1
		  FROM TI_ObservacionRegistroTabla OBS
			   INNER JOIN (SELECT EDP.* FROM TR_Ec_Det_Pagos EDP
								  LEFT JOIN #temp_obl_det_observada tmp ON EDP.I_OblRowID = tmp.I_OblRowID
							WHERE EDP.I_OblRowID = @I_OblRowID
								  AND tmp.I_RowID IS NULL 
						  ) DPG ON OBS.I_FilaTablaID = DPG.I_RowID
		 WHERE OBS.I_ObservID = @I_ObservID 
			   AND OBS.I_TablaID = @I_TablaID


		SET @I_Observados = (SELECT COUNT(*) 
							   FROM TI_ObservacionRegistroTabla OBS 
									INNER JOIN TR_Ec_Det_Pagos DET_PG ON OBS.I_FilaTablaID = DET_PG.I_RowID 
																	  	 AND DET_PG.I_ProcedenciaID = OBS.I_ProcedenciaID
							  WHERE OBS.I_ObservID = @I_ObservID 
							  		AND OBS.I_TablaID = @I_TablaID
									AND DET_PG.I_OblRowID = @I_OblRowID  
									AND OBS.B_Resuelto = 0
							)
		
		SELECT @I_Observados as cant_obs, @D_FecProceso as fec_proceso		 

		COMMIT TRANSACTION 

		SET @B_Resultado = 1
		SET @T_Message = '{ ' +
							 'Type: "summary", ' + 
							 'Title: "Validar_56_DetalleObservadoPorOblID", ' + 
							 'Value: ' + CAST(@I_Observados AS varchar) +
						 '}' 
	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION
		SET @B_Resultado = 0
		SET @T_Message = '[{ ' +
							 'Type: "error", ' + 
							 'Title: "Validar_56_DetalleObservadoPorOblID", ' + 
							 'Value: "' + ERROR_MESSAGE() + ' (Linea: ' + CAST(ERROR_LINE() AS varchar(11)) + ')."'  +
						  '}]' 
	END CATCH
END
GO


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_Obligaciones_Pagos_MigracionTP_U_Validar_57_CabObligacionObservada')
	DROP PROCEDURE [dbo].[USP_Obligaciones_Pagos_MigracionTP_U_Validar_57_CabObligacionObservada]
GO

CREATE PROCEDURE [dbo].[USP_Obligaciones_Pagos_MigracionTP_U_Validar_57_CabObligacionObservada]
	@I_ProcedenciaID tinyint,
	@T_Anio			varchar(4) = NULL,
	@B_Resultado	bit output,
	@T_Message		nvarchar(4000) OUTPUT	
AS
/*
  	DESCRIPCION: Marcar TR_Ec_Det_Pagos con B_Migrable = 0 cuando la cabecera de la obligación asociada se encuentra observada para la procedencia y año.	

	DECLARE @I_ProcedenciaID	tinyint = 1, 
			@T_Anio		  varchar(4) = '2010',
			@B_Resultado  bit,
			@T_Message    nvarchar(4000)
	EXEC USP_Obligaciones_Pagos_MigracionTP_U_Validar_57_CabObligacionObservada @I_ProcedenciaID, @T_Anio, @B_Resultado output, @T_Message output
	SELECT @B_Resultado as resultado, @T_Message as mensaje
*/
BEGIN
	DECLARE @I_Observados int = 0
	DECLARE @D_FecProceso datetime = GETDATE() 
	DECLARE @I_ObservID int = 57
	DECLARE @I_OblTablaID int = 5
	DECLARE @I_TablaID int = 7

	BEGIN TRANSACTION
	BEGIN TRY
		
		SELECT DISTINCT Obl.*
		  INTO #temp_pago_cab_observada
		  FROM TR_Ec_Obl Obl 
			   INNER JOIN TI_ObservacionRegistroTabla Obs ON Obl.I_RowID = Obs.I_FilaTablaID
															 AND Obl.I_ProcedenciaID = Obs.I_ProcedenciaID
															 AND Obs.I_TablaID = @I_OblTablaID
		 WHERE Obs.B_Resuelto = 0
			   AND Obl.Ano = @T_Anio 
			   AND Obl.I_ProcedenciaID = @I_ProcedenciaID


		UPDATE Det_Pagos 
		   SET B_Migrable = 0, 
			   D_FecMigrado = @D_FecProceso
		  FROM TR_Ec_Det_Pagos Det_Pagos
			   INNER JOIN #temp_pago_cab_observada tmp ON Det_Pagos.I_OblRowID = tmp.I_RowID 

		MERGE TI_ObservacionRegistroTabla AS TRG
		USING (SELECT DISTINCT @I_ObservID AS I_ObservID, @I_TablaID AS I_TablaID, Det_Pagos.I_RowID AS I_FilaTablaID, @D_FecProceso AS D_FecRegistro 
				 FROM TR_Ec_Det_Pagos Det_Pagos
				      INNER JOIN #temp_pago_cab_observada tmp ON Det_Pagos.I_OblRowID = tmp.I_RowID
			  ) AS SRC
		ON TRG.I_ObservID = SRC.I_ObservID AND TRG.I_TablaID = SRC.I_TablaID AND TRG.I_FilaTablaID = SRC.I_FilaTablaID
		WHEN MATCHED AND TRG.I_FilaTablaID = SRC.I_FilaTablaID THEN
			UPDATE SET D_FecRegistro = SRC.D_FecRegistro, 
					   B_Resuelto = 0
		WHEN NOT MATCHED BY TARGET THEN
			INSERT (I_ObservID, I_TablaID, I_FilaTablaID, D_FecRegistro, I_ProcedenciaID, B_ObligProc)
			VALUES (SRC.I_ObservID, SRC.I_TablaID, SRC.I_FilaTablaID, SRC.D_FecRegistro, @I_ProcedenciaID, 1);


		UPDATE OBS
		   SET D_FecResuelto = @D_FecProceso,
			   B_Resuelto = 1
		  FROM TI_ObservacionRegistroTabla OBS
			   INNER JOIN (SELECT EDP.* FROM TR_Ec_Det_Pagos EDP
								  LEFT JOIN #temp_pago_cab_observada tmp ON EDP.I_OblRowID = tmp.I_RowID
							WHERE EDP.I_ProcedenciaID = @I_ProcedenciaID
								  AND EDP.Ano = @T_Anio
								  AND tmp.I_RowID IS NULL 
						  ) DPG ON OBS.I_FilaTablaID = DPG.I_RowID
		 WHERE OBS.I_ObservID = @I_ObservID 
			   AND OBS.I_TablaID = @I_TablaID


		SET @I_Observados = (SELECT COUNT(*) 
							   FROM TI_ObservacionRegistroTabla OBS 
									INNER JOIN TR_Ec_Det_Pagos DET_PG ON OBS.I_FilaTablaID = DET_PG.I_RowID 
																	  	 AND DET_PG.I_ProcedenciaID = OBS.I_ProcedenciaID
							  WHERE OBS.I_ObservID = @I_ObservID 
							  		AND OBS.I_TablaID = @I_TablaID
									AND DET_PG.I_ProcedenciaID = @I_ProcedenciaID 
									AND OBS.B_Resuelto = 0
							)

		SELECT @I_Observados as cant_obs, @D_FecProceso as fec_proceso		 

		COMMIT TRANSACTION 

		SET @B_Resultado = 1
		SET @T_Message = '{ ' +
							 'Type: "summary", ' + 
							 'Title: "Validar_57_CabObligacionObservada", ' + 
							 'Value: ' + CAST(@I_Observados AS varchar) +
						 '}' 
	END TRY
	BEGIN CATCH
		IF(@@TRANCOUNT > 0)
		BEGIN
			ROLLBACK TRANSACTION
		END

		SET @B_Resultado = 0
		SET @T_Message = '[{ ' +
							 'Type: "error", ' + 
							 'Title: "Validar_57_CabObligacionObservada", ' + 
							 'Value: "' + ERROR_MESSAGE() + ' (Linea: ' + CAST(ERROR_LINE() AS varchar(11)) + ')."'  +
						  '}]' 
	END CATCH
END
GO



IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_Obligaciones_Pagos_MigracionTP_U_Validar_57_CabObligacionObservadaPorOblID')
	DROP PROCEDURE [dbo].[USP_Obligaciones_Pagos_MigracionTP_U_Validar_57_CabObligacionObservadaPorOblID]
GO

CREATE PROCEDURE [dbo].[USP_Obligaciones_Pagos_MigracionTP_U_Validar_57_CabObligacionObservadaPorOblID]
	@I_OblRowID			int,
	@B_Resultado	bit output,
	@T_Message		nvarchar(4000) OUTPUT	
AS
/*
  	DESCRIPCION: Marcar TR_Ec_Det_Pagos con B_Migrable = 0 cuando la cabecera de la obligaci�n asociada se encuentra observada para la obligacion I_OblRowID	

	DECLARE @I_OblRowID	  int,
			@B_Resultado  bit,
			@T_Message    nvarchar(4000)
	EXEC USP_Obligaciones_Pagos_MigracionTP_U_Validar_57_CabObligacionObservadaPorOblID @I_OblRowID, @B_Resultado output, @T_Message output
	SELECT @B_Resultado as resultado, @T_Message as mensaje
*/
BEGIN
	DECLARE @I_Observados int = 0
	DECLARE @I_ObservadosObl int = 0
	DECLARE @D_FecProceso datetime = GETDATE() 
	DECLARE @I_ObservID int = 56
	DECLARE @I_TablaID int = 7
	DECLARE @I_OblTablaID int = 5

	BEGIN TRANSACTION
	BEGIN TRY
		
		SELECT Obl.*
		  INTO #temp_obl_cab_observada
		  FROM TR_Ec_Obl Obl 
			   INNER JOIN TI_ObservacionRegistroTabla Obs ON Obl.I_RowID = Obs.I_FilaTablaID
															 AND Obl.I_ProcedenciaID = Obs.I_ProcedenciaID
															 AND Obs.I_TablaID = @I_OblTablaID
		 WHERE Obs.B_Resuelto = 0
			   AND Obl.I_RowID = @I_OblRowID


		UPDATE Det_Pagos 
		   SET B_Migrable = 0, 
			   D_FecMigrado = @D_FecProceso
		  FROM TR_Ec_Det_Pagos Det_Pagos
			   INNER JOIN #temp_obl_cab_observada tmp ON Det_Pagos.I_OblRowID = tmp.I_RowID 

		MERGE TI_ObservacionRegistroTabla AS TRG
		USING (SELECT DISTINCT @I_ObservID AS I_ObservID, @I_TablaID AS I_TablaID, Det_Pagos.I_RowID AS I_FilaTablaID, 
				      @D_FecProceso AS D_FecRegistro, Det_Pagos.I_ProcedenciaID 
				 FROM TR_Ec_Det_Pagos Det_Pagos
				      INNER JOIN #temp_obl_cab_observada tmp ON Det_Pagos.I_OblRowID = tmp.I_RowID 
			  ) AS SRC
		ON TRG.I_ObservID = SRC.I_ObservID AND TRG.I_TablaID = SRC.I_TablaID AND TRG.I_FilaTablaID = SRC.I_FilaTablaID
		WHEN MATCHED AND TRG.I_FilaTablaID = SRC.I_FilaTablaID THEN
			UPDATE SET D_FecRegistro = SRC.D_FecRegistro, 
					   B_Resuelto = 0
		WHEN NOT MATCHED BY TARGET THEN
			INSERT (I_ObservID, I_TablaID, I_FilaTablaID, D_FecRegistro, I_ProcedenciaID, B_ObligProc)
			VALUES (SRC.I_ObservID, SRC.I_TablaID, SRC.I_FilaTablaID, SRC.D_FecRegistro, SRC.I_ProcedenciaID, 1);


		UPDATE OBS
		   SET D_FecResuelto = @D_FecProceso,
			   B_Resuelto = 1
		  FROM TI_ObservacionRegistroTabla OBS
			   INNER JOIN (SELECT EDP.* FROM TR_Ec_Det_Pagos EDP
								  LEFT JOIN #temp_obl_cab_observada tmp ON EDP.I_OblRowID = tmp.I_RowID
							WHERE EDP.I_OblRowID = @I_OblRowID
								  AND tmp.I_RowID IS NULL 
						  ) DPG ON OBS.I_FilaTablaID = DPG.I_RowID
		 WHERE OBS.I_ObservID = @I_ObservID 
			   AND OBS.I_TablaID = @I_TablaID


		SET @I_Observados = (SELECT COUNT(*) 
							   FROM TI_ObservacionRegistroTabla OBS 
									INNER JOIN TR_Ec_Det_Pagos DET_PG ON OBS.I_FilaTablaID = DET_PG.I_RowID 
																	  	 AND DET_PG.I_ProcedenciaID = OBS.I_ProcedenciaID
							  WHERE OBS.I_ObservID = @I_ObservID 
							  		AND OBS.I_TablaID = @I_TablaID
									AND DET_PG.I_OblRowID = @I_OblRowID  
									AND OBS.B_Resuelto = 0
							)
		
		SELECT @I_Observados as cant_obs, @D_FecProceso as fec_proceso		 

		COMMIT TRANSACTION 

		SET @B_Resultado = 1
		SET @T_Message = '{ ' +
							 'Type: "summary", ' + 
							 'Title: "Validar_57_CabObligacionObservadaPorOblID", ' + 
							 'Value: ' + CAST(@I_Observados AS varchar) +
						 '}' 
	END TRY
	BEGIN CATCH
		IF(@@TRANCOUNT > 0)
		BEGIN
			ROLLBACK TRANSACTION
		END

		SET @B_Resultado = 0
		SET @T_Message = '[{ ' +
							 'Type: "error", ' + 
							 'Title: "Validar_57_CabObligacionObservadaPorOblID", ' + 
							 'Value: "' + ERROR_MESSAGE() + ' (Linea: ' + CAST(ERROR_LINE() AS varchar(11)) + ')."'  +
						  '}]' 
	END CATCH
END
GO



IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_Obligaciones_Pagos_MigracionTP_U_Validar_63_MigracionCabecera')
	DROP PROCEDURE [dbo].[USP_Obligaciones_Pagos_MigracionTP_U_Validar_63_MigracionCabecera]
GO

CREATE PROCEDURE [dbo].[USP_Obligaciones_Pagos_MigracionTP_U_Validar_63_MigracionCabecera]	
(
	@I_ProcedenciaID tinyint,
	@T_Anio		  varchar(4),
	@B_Resultado  bit output,
	@T_Message	  nvarchar(4000) OUTPUT	
)
AS
/*
	DESCRIPCION: Marcar TR_Ec_Det con B_Migrable = 0 cuando la cabecera de la obligacion asociada al pago no fue migrada para el año y procedencia.

	DECLARE	@I_ProcedenciaID	tinyint = 2,
			@T_Anio				varchar(4) = '2016',
			@B_Resultado		bit,
			@T_Message			nvarchar(4000)
	EXEC USP_Obligaciones_Pagos_MigracionTP_U_Validar_63_MigracionCabecera @I_ProcedenciaID, @T_Anio, @B_Resultado output, @T_Message output
	SELECT @B_Resultado as resultado, @T_Message as mensaje
*/
BEGIN
	DECLARE @I_Observados int = 0
	DECLARE @D_FecProceso datetime = GETDATE() 
	DECLARE @I_ObservID int = 63
	DECLARE @I_TablaID int = 7

	BEGIN TRANSACTION
	BEGIN TRY 

		SELECT I_OblRowID
		  INTO #temp_det_migrable_obl_no_migrado
		  FROM TR_Ec_Det_Pagos det
			   INNER JOIN TR_Ec_Obl obl ON det.I_OblRowID = obl.I_RowID
		 WHERE obl.Ano = @T_Anio
			   AND obl.I_ProcedenciaID = @I_ProcedenciaID
			   AND obl.B_Migrado = 0			   

		UPDATE Det
		   SET B_Migrable = 0,
			   D_FecEvalua = @D_FecProceso
		  FROM TR_Ec_Det_Pagos Det 
			   INNER JOIN #temp_det_migrable_obl_no_migrado tmp ON Det.I_OblRowID = tmp.I_OblRowID
		 WHERE B_Migrable = 1

		MERGE TI_ObservacionRegistroTabla AS TRG
		USING (SELECT @I_ObservID AS I_ObservID, @I_TablaID AS I_TablaID, Det.I_RowID AS I_FilaTablaID, 
					  @D_FecProceso AS D_FecRegistro, Det.I_ProcedenciaID 
				 FROM TR_Ec_Det Det 
					  INNER JOIN #temp_det_migrable_obl_no_migrado tmp ON Det.I_OblRowID = tmp.I_OblRowID
				WHERE B_Migrable = 1
			  ) AS SRC
		ON TRG.I_ObservID = SRC.I_ObservID AND TRG.I_TablaID = SRC.I_TablaID AND TRG.I_FilaTablaID = SRC.I_FilaTablaID
		WHEN MATCHED AND TRG.I_ProcedenciaID = SRC.I_ProcedenciaID THEN
			UPDATE SET D_FecRegistro = SRC.D_FecRegistro, 
					   B_Resuelto = 0
		WHEN NOT MATCHED BY TARGET THEN
			INSERT (I_ObservID, I_TablaID, I_FilaTablaID, D_FecRegistro, I_ProcedenciaID, B_ObligProc)
			VALUES (SRC.I_ObservID, SRC.I_TablaID, SRC.I_FilaTablaID, SRC.D_FecRegistro, @I_ProcedenciaID, 1);
		
		UPDATE OBS
		   SET D_FecResuelto = @D_FecProceso,
		   	   B_Resuelto = 1
		  FROM TI_ObservacionRegistroTabla OBS
		  	   INNER JOIN (SELECT Det.I_RowID, Det.I_ProcedenciaID, tmp.I_OblRowID as TempOblRowID
			   				 FROM TR_Ec_Det_Pagos Det
								  LEFT JOIN #temp_det_migrable_obl_no_migrado tmp ON tmp.I_OblRowID = Det.I_OblRowID
							WHERE tmp.I_OblRowID IS NULL
								  AND Det.Ano = @T_Anio
								  AND Det.I_ProcedenciaID = @I_ProcedenciaID
			   			  ) DET ON OBS.I_FilaTablaID = DET.I_RowID
						  		   AND OBS.I_ProcedenciaID = DET.I_ProcedenciaID 
		 WHERE OBS.I_ObservID = @I_ObservID 
		 	   AND OBS.I_TablaID = @I_TablaID 
		
		SET @I_Observados = (SELECT COUNT(*) 
							   FROM TI_ObservacionRegistroTabla OBS 
									INNER JOIN TR_Ec_Det_Pagos DET ON OBS.I_FilaTablaID = DET.I_RowID 
																	  AND DET.I_ProcedenciaID = OBS.I_ProcedenciaID
							  WHERE OBS.I_ObservID = @I_ObservID 
									AND Det.Ano = @T_Anio
									AND Det.I_ProcedenciaID = @I_ProcedenciaID 
									AND OBS.B_Resuelto = 0
							)

		SELECT @I_Observados as cant_obs, @D_FecProceso as fec_proceso		 

		COMMIT TRANSACTION;

		SET @B_Resultado = 1
		SET @T_Message = '{ ' +
							 'Type: "summary", ' + 
							 'Title: "Validar_63_MigracionCabecera", ' + 
							 'Value: ' + CAST(@I_Observados AS varchar) +
						 '}' 

	END TRY
	BEGIN CATCH
		IF (@@TRANCOUNT > 0)
		BEGIN
			ROLLBACK TRANSACTION
		END

		SET @B_Resultado = 0
		SET @T_Message = '[{ ' +
							 'Type: "error", ' + 
							 'Title: "Validar_63_MigracionCabecera", ' + 
							 'Value: "' + ERROR_MESSAGE() + ' (Linea: ' + CAST(ERROR_LINE() AS varchar(11)) + ')."'  +
						  '}]' 
	END CATCH
END
GO


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_Obligaciones_Pagos_MigracionTP_U_Validar_63_MigracionCabeceraPorOblID')
	DROP PROCEDURE [dbo].[USP_Obligaciones_Pagos_MigracionTP_U_Validar_63_MigracionCabeceraPorOblID]
GO

CREATE PROCEDURE [dbo].[USP_Obligaciones_Pagos_MigracionTP_U_Validar_63_MigracionCabeceraPorOblID]
	@I_OblRowID	  int,
	@B_Resultado  bit output,
	@T_Message    nvarchar(4000) OUTPUT	
AS
/*
	DESCRIPCION: Marcar TR_Ec_Obl con B_Migrable = 0 cuando la suma de los montos en el detalle no coinciden con el monto de la cabecera para el ID de obligacion.

	DECLARE @I_OblRowID	  int,
			@B_Resultado  bit,
			@T_Message    nvarchar(4000)
	EXEC USP_Obligaciones_Pagos_MigracionTP_U_Validar_63_MigracionCabeceraPorOblID @I_OblRowID, @B_Resultado output, @T_Message output
	SELECT @B_Resultado as resultado, @T_Message as mensaje
*/
BEGIN
	DECLARE @I_Observados int = 0
	DECLARE @D_FecProceso datetime = GETDATE() 
	DECLARE @I_ObservID int = 63
	DECLARE @I_TablaID int = 7

	BEGIN TRANSACTION
	BEGIN TRY

		SELECT I_OblRowID
		  INTO #temp_det_migrable_obl_no_migrado
		  FROM TR_Ec_Det_Pagos det
			   INNER JOIN TR_Ec_Obl obl ON det.I_OblRowID = obl.I_RowID
		 WHERE obl.I_RowID = @I_OblRowID
			   AND obl.B_Migrado = 0			   
			   AND obl.B_Migrable = 1

		UPDATE Det
		   SET B_Migrable = 0,
			   D_FecEvalua = @D_FecProceso
		  FROM TR_Ec_Det_Pagos Det 
			   INNER JOIN #temp_det_migrable_obl_no_migrado tmp ON Det.I_OblRowID = tmp.I_OblRowID


		MERGE TI_ObservacionRegistroTabla AS TRG
		USING (SELECT @I_ObservID AS I_ObservID, @I_TablaID AS I_TablaID, Det.I_RowID AS I_FilaTablaID, 
					  @D_FecProceso AS D_FecRegistro, Det.I_ProcedenciaID 
				 FROM TR_Ec_Det_Pagos Det 
					  INNER JOIN #temp_det_migrable_obl_no_migrado tmp ON Det.I_OblRowID = tmp.I_OblRowID
			  ) AS SRC
		ON TRG.I_ObservID = SRC.I_ObservID AND TRG.I_TablaID = SRC.I_TablaID AND TRG.I_FilaTablaID = SRC.I_FilaTablaID
		WHEN MATCHED AND TRG.I_ProcedenciaID = SRC.I_ProcedenciaID THEN
			UPDATE SET D_FecRegistro = SRC.D_FecRegistro, 
					   B_Resuelto = 0
		WHEN NOT MATCHED BY TARGET THEN
			INSERT (I_ObservID, I_TablaID, I_FilaTablaID, D_FecRegistro, I_ProcedenciaID, B_ObligProc)
			VALUES (SRC.I_ObservID, SRC.I_TablaID, SRC.I_FilaTablaID, SRC.D_FecRegistro, SRC.I_ProcedenciaID, 1);
		
		UPDATE OBS
		   SET D_FecResuelto = @D_FecProceso,
		   	   B_Resuelto = 1
		  FROM TI_ObservacionRegistroTabla OBS
		  	   INNER JOIN (SELECT Det.I_RowID, Det.I_ProcedenciaID, tmp.I_OblRowID as TempOblRowID
			   				 FROM TR_Ec_Det_Pagos Det
								  LEFT JOIN #temp_det_migrable_obl_no_migrado tmp ON tmp.I_OblRowID = Det.I_OblRowID
							WHERE tmp.I_OblRowID IS NULL
								  AND Det.I_OblRowID = @I_OblRowID
			   			  ) DET ON OBS.I_FilaTablaID = DET.I_RowID
						  		   AND OBS.I_ProcedenciaID = DET.I_ProcedenciaID 
		 WHERE OBS.I_ObservID = @I_ObservID 
		 	   AND OBS.I_TablaID = @I_TablaID 
		
		SET @I_Observados = (SELECT COUNT(*) 
							   FROM TI_ObservacionRegistroTabla OBS 
									INNER JOIN TR_Ec_Det_Pagos DET ON OBS.I_FilaTablaID = DET.I_RowID 
																AND DET.I_ProcedenciaID = OBS.I_ProcedenciaID
							  WHERE OBS.I_ObservID = @I_ObservID 
									AND Det.I_OblRowID = @I_OblRowID
									AND OBS.B_Resuelto = 0
							)
		COMMIT TRANSACTION

		SET @B_Resultado = 1
		SET @T_Message = '{ ' +
							 'Type: "summary", ' + 
							 'Title: "Validar_63_MigracionCabeceraPorOblID", ' + 
							 'Value: ' + CAST(@I_Observados AS varchar) +
						 '}' 
	END TRY
	BEGIN CATCH
		IF (@@TRANCOUNT > 0)
		BEGIN
			ROLLBACK TRANSACTION
		END

		SET @B_Resultado = 0
		SET @T_Message = '[{ ' +
							 'Type: "error", ' + 
							 'Title: "Validar_63_MigracionCabeceraPorOblID", ' + 
							 'Value: "' + ERROR_MESSAGE() + ' (Linea: ' + CAST(ERROR_LINE() AS varchar(11)) + ')."'  +
						  '}]' 
	END CATCH
END
GO


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_Obligaciones_Pagos_MigracionTP_U_Validar_65_FechaPago')
	DROP PROCEDURE [dbo].[USP_Obligaciones_Pagos_MigracionTP_U_Validar_65_FechaPago]
GO

CREATE PROCEDURE [dbo].[USP_Obligaciones_Pagos_MigracionTP_U_Validar_65_FechaPago]	
	@I_ProcedenciaID tinyint,
	@T_Anio			 varchar(4) = NULL,
	@B_Resultado  bit OUTPUT,
	@T_Message	  nvarchar(4000) OUTPUT	
AS
/*
	DESCRIPCION: Marcar TR_Ec_Det con B_Migrable = 0 cuando la fecha de vencimiento no es un datetime válido

	DECLARE	@I_ProcedenciaID	tinyint = 3, 
			@T_Anio				varchar(4) = 2007,
			@B_Resultado		bit,
			@T_Message			nvarchar(4000)
	EXEC USP_Obligaciones_Pagos_MigracionTP_U_Validar_65_FechaPago @I_ProcedenciaID, @T_Anio, @B_Resultado output, @T_Message output
	SELECT @B_Resultado as resultado, @T_Message as mensaje
*/
BEGIN
	DECLARE @I_Observados int = 0
	DECLARE @D_FecProceso datetime = GETDATE() 
	DECLARE @I_ObservID int = 65
	DECLARE @I_TablaID int = 7

	BEGIN TRANSACTION
	BEGIN TRY

		SELECT DISTINCT Ano, P, Cod_alu, Cod_rc, Cuota_pago, Fch_venc, Fch_pago, Tipo_oblig, Monto, I_RowID, I_OblRowID
		  INTO #temp_det_fecPago
		  FROM TR_Ec_Det_Pagos det
		 WHERE I_ProcedenciaID = @I_ProcedenciaID
		 	   AND Ano = @T_Anio
			  AND ISDATE(CONVERT(VARCHAR, Fch_pago, 112)) = 0

		UPDATE	TRG_1
		   SET	B_Migrable = 0,
				D_FecEvalua = @D_FecProceso
		  FROM	TR_Ec_Det_Pagos TRG_1
				INNER JOIN #temp_det_fecPago SRC_1 ON TRG_1.I_RowID = SRC_1.I_RowID
		 WHERE	ISNULL(TRG_1.B_Correcto, 0) = 0


		MERGE TI_ObservacionRegistroTabla AS TRG
		USING (SELECT DISTINCT @I_ObservID AS I_ObservID, @I_TablaID AS I_TablaID, TRG_1.I_RowID AS I_FilaTablaID, @D_FecProceso AS D_FecRegistro 
				 FROM TR_Ec_Det_Pagos TRG_1
					  INNER JOIN #temp_det_fecPago SRC_1 
								ON TRG_1.I_RowID = SRC_1.I_RowID
				 WHERE	TRG_1.Ano = @T_Anio
						AND ISNULL(TRG_1.B_Correcto, 0) = 0
			  ) AS SRC
		ON TRG.I_ObservID = SRC.I_ObservID AND TRG.I_TablaID = SRC.I_TablaID AND TRG.I_FilaTablaID = SRC.I_FilaTablaID
		WHEN MATCHED THEN
			UPDATE SET D_FecRegistro = SRC.D_FecRegistro, 
					   B_Resuelto = 0
		WHEN NOT MATCHED BY TARGET THEN
			INSERT (I_ObservID, I_TablaID, I_FilaTablaID, D_FecRegistro, I_ProcedenciaID, B_ObligProc)
			VALUES (SRC.I_ObservID, SRC.I_TablaID, SRC.I_FilaTablaID, SRC.D_FecRegistro, @I_ProcedenciaID, 1);


		UPDATE OBS
		   SET D_FecResuelto = @D_FecProceso,
			   B_Resuelto = 1
		  FROM TI_ObservacionRegistroTabla OBS
			   INNER JOIN (SELECT ec_det.I_RowID, ec_det.Ano, ec_det.Cod_alu, ec_det.Cod_rc, ec_det.I_ProcedenciaID
							 FROM TR_Ec_Det_Pagos USP_Obligaciones_Pagos_MigracionTP_U_AsignarObligacionID
								  LEFT JOIN #temp_det_fecPago SRC_1 ON ec_det.I_RowID = SRC_1.I_RowID
							WHERE SRC_1.I_RowID IS NULL) DET 
						  ON OBS.I_FilaTablaID = DET.I_RowID
							 AND OBS.I_ProcedenciaID = DET.I_ProcedenciaID
		 WHERE OBS.I_ObservID = @I_ObservID 
			   AND OBS.I_TablaID = @I_TablaID

		SET @I_Observados = (SELECT COUNT(*) FROM TI_ObservacionRegistroTabla OBS INNER JOIN 
												  TR_Ec_Det_Pagos DET ON OBS.I_FilaTablaID = DET.I_RowID 
																	AND DET.I_ProcedenciaID = OBS.I_ProcedenciaID
																	AND OBS.I_TablaID = @I_TablaID 
							  WHERE I_ObservID = @I_ObservID AND
									DET.Ano = @T_Anio AND
									OBS.I_ProcedenciaID = @I_ProcedenciaID AND 
									B_Resuelto = 0)

		SELECT @I_Observados as cant_obs, @D_FecProceso as fec_proceso

		COMMIT TRANSACTION				
		SET @B_Resultado = 1
		SET @T_Message = '{ ' +
							 'Type: "summary", ' + 
							 'Title: "Validar_65_FechaPago", ' + 
							 'Value: ' + CAST(@I_Observados AS varchar) +
						 '}' 
	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION
		SET @B_Resultado = 0
		SET @T_Message = '[{ ' +
							 'Type: "error", ' + 
							 'Title: "Validar_65_FechaPago", ' + 
							 'Value: "' + ERROR_MESSAGE() + ' (Linea: ' + CAST(ERROR_LINE() AS varchar(11)) + ')."'  +
						  '}]' 
	END CATCH
END
GO


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_Obligaciones_Pagos_MigracionTP_U_Validar_65_FechaPagoPorOblID')
	DROP PROCEDURE [dbo].[USP_Obligaciones_Pagos_MigracionTP_U_Validar_65_FechaPagoPorOblID]
GO

CREATE PROCEDURE [dbo].[USP_Obligaciones_Pagos_MigracionTP_U_Validar_65_FechaPagoPorOblID]	
	@I_RowID	  int,
	@B_Resultado  bit OUTPUT,
	@T_Message	  nvarchar(4000) OUTPUT	
AS
/*
	DESCRIPCION: Marcar TR_Ec_Det_Pagos con B_Migrable = 0 cuando la fecha de vencimiento es un datetime válido para la oblID

	DECLARE	@I_RowID	  int,
			@B_Resultado  bit,
			@T_Message	  nvarchar(4000)
	EXEC USP_Obligaciones_Pagos_MigracionTP_U_Validar_65_FechaPagoPorOblID @I_RowID, @B_Resultado output, @T_Message output
	SELECT @B_Resultado as resultado, @T_Message as mensaje
*/
BEGIN
	DECLARE @I_Observados int = 0
	DECLARE @D_FecProceso datetime = GETDATE() 
	DECLARE @I_ObservID int = 65
	DECLARE @I_TablaID int = 7

	BEGIN TRANSACTION
	BEGIN TRY

		SELECT Ano, P, Cod_alu, Cod_rc, Cuota_pago, Fch_venc, Fch_pago, Tipo_oblig, Monto, I_RowID
		INTO  #temp_det_fecPago
		FROM  TR_Ec_Det_Pagos 
		WHERE I_RowID = @I_RowID
			  AND ISDATE(CONVERT(VARCHAR, Fch_pago, 112)) = 0


		UPDATE	TRG_1
		SET		B_Migrable = 0,
				D_FecEvalua = @D_FecProceso
		FROM	TR_Ec_Det_Pagos TRG_1
				INNER JOIN #temp_det_fecPago SRC_1 
							ON TRG_1.I_RowID = SRC_1.I_RowID
		WHERE	ISNULL(TRG_1.B_Correcto, 0) = 0


		MERGE TI_ObservacionRegistroTabla AS TRG
		USING (SELECT @I_ObservID AS I_ObservID, @I_TablaID AS I_TablaID, TRG_1.I_RowID AS I_FilaTablaID, 
					  @D_FecProceso AS D_FecRegistro, TRG_1.I_ProcedenciaID, SRC_1.I_RowID
				 FROM TR_Ec_Det_Pagos TRG_1
					  LEFT JOIN #temp_det_fecPago SRC_1 
								 ON TRG_1.I_RowID = SRC_1.I_RowID
				WHERE ISNULL(TRG_1.B_Correcto, 0) = 0
					  AND TRG_1.I_RowID = @I_RowID
			  ) AS SRC
		ON TRG.I_ObservID = SRC.I_ObservID AND TRG.I_TablaID = SRC.I_TablaID AND TRG.I_FilaTablaID = SRC.I_FilaTablaID
		WHEN MATCHED AND SRC.I_RowID IS NOT NULL THEN
			UPDATE SET D_FecRegistro = SRC.D_FecRegistro, 
					   B_Resuelto = 0
		WHEN NOT MATCHED BY TARGET THEN
			INSERT (I_ObservID, I_TablaID, I_FilaTablaID, D_FecRegistro, I_ProcedenciaID, B_ObligProc)
			VALUES (SRC.I_ObservID, SRC.I_TablaID, SRC.I_FilaTablaID, SRC.D_FecRegistro, SRC.I_ProcedenciaID, 1);


		UPDATE OBS
		   SET D_FecResuelto = @D_FecProceso,
			   B_Resuelto = 1
		  FROM TI_ObservacionRegistroTabla OBS
			   INNER JOIN (SELECT ec_det.I_RowID, ec_det.Ano, ec_det.Cod_alu, ec_det.Cod_rc, ec_det.I_ProcedenciaID 
							 FROM TR_Ec_Det_Pagos ec_det
								  LEFT JOIN #temp_det_fecPago SRC_1 ON ec_det.I_RowID = SRC_1.I_RowID
							WHERE ec_det.I_RowID = @I_RowID
								  AND SRC_1.I_RowID IS NULL
						  ) OBL 
						  ON OBS.I_FilaTablaID = OBL.I_RowID
							 AND OBS.I_ProcedenciaID = OBL.I_ProcedenciaID
		 WHERE OBS.I_ObservID = @I_ObservID 
			   AND OBS.I_TablaID = @I_TablaID
			   AND OBS.I_FilaTablaID = @I_RowID

		SET @I_Observados = (SELECT COUNT(*) FROM TI_ObservacionRegistroTabla OBS INNER JOIN 
												  TR_Ec_Det_Pagos DET ON OBS.I_FilaTablaID = DET.I_RowID 
																	AND DET.I_ProcedenciaID = OBS.I_ProcedenciaID
																	AND OBS.I_TablaID = @I_TablaID 
							  WHERE I_ObservID = @I_ObservID
									AND B_Resuelto = 0
									AND DET.I_RowID = @I_RowID)

		SELECT @I_Observados as cant_obs, @D_FecProceso as fec_proceso

		COMMIT TRANSACTION				
		SET @B_Resultado = 1
		SET @T_Message = '{ ' +
							 'Type: "summary", ' + 
							 'Title: "Validar_65_FechaPagoPorOblID ", ' + 
							 'Value: ' + CAST(@I_Observados AS varchar) +
						 '}' 
	END TRY
	BEGIN CATCH
		IF (@@TRANCOUNT > 0) 
		BEGIN
			ROLLBACK TRANSACTION
		END

		SET @B_Resultado = 0
		SET @T_Message = '[{ ' +
							 'Type: "error", ' + 
							 'Title: "Validar_65_FechaPagoPorOblID", ' + 
							 'Value: "' + ERROR_MESSAGE() + ' (Linea: ' + CAST(ERROR_LINE() AS varchar(11)) + ')."'  +
						  '}]' 
	END CATCH
END
GO


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_Obligaciones_Pagos_MigracionTP_CtasPorCobrar_IU_MigrarDataPorID2')
	DROP PROCEDURE [dbo].[USP_Obligaciones_Pagos_MigracionTP_CtasPorCobrar_IU_MigrarDataPorID2]
GO


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_Obligaciones_Pagos_MigracionTP_CtasPorCobrar_IU_MigrarDataPorID')
	DROP PROCEDURE [dbo].[USP_Obligaciones_Pagos_MigracionTP_CtasPorCobrar_IU_MigrarDataPorID]
GO

CREATE PROCEDURE [dbo].[USP_Obligaciones_Pagos_MigracionTP_CtasPorCobrar_IU_MigrarDataPorID]	
	@I_OblRowID		int,
	@I_UsuarioID	int,
	@I_PagoBancoID	int output,
	@B_Resultado	bit output,
	@T_Message		nvarchar(4000) OUTPUT	
AS
/*
	DECLARE @I_OblRowID		int = 117895,
			@I_UsuarioID	int = 15,
			@I_PagoBancoID	int,
			@B_Resultado	bit,
			@T_Message		nvarchar(4000)
	EXEC USP_Obligaciones_Pagos_MigracionTP_CtasPorCobrar_IU_MigrarDataPorID @I_OblRowID, @I_UsuarioID, @I_PagoBancoID output, @B_Resultado output, @T_Message output
	SELECT @I_PagoBancoID as I_PagoBancoID, @B_Resultado as resultado, @T_Message as mensaje
*/
BEGIN
	DECLARE @D_FecProceso datetime = GETDATE(); 
	DECLARE @I_TablaID_Obl int = 5;
	DECLARE @I_TablaID_Det int = 4;
	DECLARE @I_TablaID_Det_Pago int = 7;
	DECLARE @I_CtasMora_RowID  int;
	DECLARE @T_Moneda varchar(3) = 'PEN';
	DECLARE @mora decimal(10,2);
	
	DECLARE @I_Pagos_Actualizados int = 0;
	DECLARE @I_Pagos_Insertados int = 0;

	DECLARE @I_Det_Actualizados int = 0;
	DECLARE @I_Det_Insertados int = 0;


	IF NOT EXISTS (SELECT I_RowID FROM TR_Ec_Det_Pagos WHERE I_OblRowID = @I_OblRowID)
	BEGIN
		SET @I_PagoBancoID = 0
		SET @B_Resultado = 1
		SET @T_Message = '[{ ' +
							 'Type: "summary", ' + 
							 'Title: "Pagos Banco Insertados (OBL_ID: ' + CAST(@I_OblRowID AS varchar) + ')", ' + 
							 'Value: ' + CAST(@I_Pagos_Insertados AS varchar) +
						  '}, ' + 
						  '{ ' +
							 'Type: "summary", ' + 
							 'Title: "Pagos Procesados Insertados (OBL_ID: ' + CAST(@I_OblRowID AS varchar) + ')", ' + 
							 'Value: ' + CAST(@I_Det_Insertados AS varchar) +
						  '}, ' + 
						  '{ ' +
							 'Type: "summary", ' + 
							 'Title: "Pagos Banco Actualizados (OBL_ID: ' + CAST(@I_OblRowID AS varchar) + ')", ' + 
							 'Value: ' + CAST(@I_Pagos_Actualizados AS varchar) +
						  '}, ' + 
						  '{ ' +
							 'Type: "summary", ' + 
							 'Title: "Pagos Procesados Actualizados (OBL_ID: ' + CAST(@I_OblRowID AS varchar) + ')", ' + 
							 'Value: ' + CAST(@I_Det_Actualizados AS varchar) +
						  '}]'
		RETURN 0;
	END

	BEGIN TRANSACTION;
	BEGIN TRY 
		SELECT I_RowID, I_OblRowID, Cod_alu, Cod_rc, Cuota_pago, Ano, P, Tipo_oblig, Concepto, Fch_venc, Nro_recibo, 
			   Fch_pago, Id_lug_pag, Cantidad, Monto, Documento, Pagado, Concepto_f, Fch_elimin, Nro_ec, Fch_ec, Eliminado, 
			   Pag_demas, Cod_cajero, Tipo_pago, No_banco, Cod_dep, det.I_ProcedenciaID, B_Obligacion, det.B_Migrable, 
			   det.I_CtasDetTableRowID, det.I_CtasPagoProcTableRowID  
		  INTO #temp_det_obl
		  FROM TR_Ec_Det det
		 WHERE I_OblRowID = @I_OblRowID
			   AND det.B_Migrable = 1;

		SELECT det.I_RowID, I_OblRowID, Cod_alu, Cod_rc, Cuota_pago, Ano, P, Tipo_oblig, Concepto, Fch_venc, Nro_recibo, 
			   Fch_pago, Id_lug_pag, Cantidad, Monto, Documento, Pagado, Concepto_f, Fch_elimin, Nro_ec, Fch_ec, Eliminado, 
			   Pag_demas, Cod_cajero, Tipo_pago, No_banco, Cod_dep, det.I_ProcedenciaID, B_Obligacion, det.B_Migrable, 
			   (a.T_ApePaterno + ' ' + a.T_ApeMaterno + ', ' + a.T_Nombre) AS T_NomDepositante, cdp.I_CtaDepositoID,
			   det.I_CtasPagoBncTableRowID
		  INTO #temp_det_pago
		  FROM TR_Ec_Det_Pagos det
			   INNER JOIN  TR_Alumnos a ON det.Cod_alu = a.C_CodAlu AND det.Cod_rc = a.C_RcCod
			   INNER JOIN  BD_OCEF_CtasPorCobrar.dbo.TI_CtaDepo_Proceso cdp ON det.cuota_pago = cdp.I_ProcesoID
		 WHERE I_OblRowID = @I_OblRowID
			   AND Concepto = 0
			   AND det.B_Migrable = 1
			   AND cdp.B_Eliminado = 0;
	
		SELECT I_RowID, I_OblRowID, Monto 
		  INTO #temp_det_pago_mora
		  FROM TR_Ec_Det_Pagos
		 WHERE I_OblRowID = @I_OblRowID
			   AND Concepto <> 0
			   AND B_Migrable = 1
			   AND Eliminado = 0;

		SET @mora = (SELECT SUM(monto) FROM #temp_det_pago_mora WHERE I_OblRowID = @I_OblRowID);
		SET @I_CtasMora_RowID = (SELECT TOP 1 I_RowID FROM #temp_det_pago_mora WHERE I_OblRowID = @I_OblRowID);

		/*
			uptdate if exists pago banco in ctas x cobrar
		*/
		UPDATE cta_pago_banco
		   SET T_NomDepositante = SRC_pago.T_NomDepositante,
			   C_Referencia = SRC_pago.Nro_recibo,
			   D_FecPago = SRC_pago.Fch_pago,
			   C_Moneda = @T_Moneda,
			   I_MontoPago = SRC_pago.Monto,
			   T_LugarPago = SRC_pago.Id_lug_pag,
			   B_Migrado = 1,
			   D_FecMod = @D_FecProceso,
			   I_UsuarioMod = @I_UsuarioID
		  FROM BD_OCEF_CtasPorCobrar.dbo.TR_PagoBanco cta_pago_banco
			   INNER JOIN #temp_det_pago SRC_pago ON cta_pago_banco.I_PagoBancoID = SRC_pago.I_CtasPagoBncTableRowID
													 AND cta_pago_banco.I_MigracionTablaID = SRC_pago.I_RowID
		 
		 SET @I_Pagos_Actualizados = @@ROWCOUNT;


		/*
			insert new pago banco in ctas x cobrar
		*/
		INSERT INTO BD_OCEF_CtasPorCobrar.dbo.TR_PagoBanco (I_EntidadFinanID, C_CodOperacion, C_CodDepositante, T_NomDepositante, C_Referencia, 
															D_FecPago, I_Cantidad, C_Moneda, I_MontoPago, T_LugarPago, B_Anulado, I_UsuarioCre, 
															D_FecCre, T_Observacion, T_InformacionAdicional, I_CondicionPagoID, I_TipoPagoID, 
															I_CtaDepositoID, I_InteresMora, B_Migrado, T_MotivoCoreccion, C_CodigoInterno, 
															I_MigracionTablaID, I_MigracionRowID, I_MigracionMoraRowID)
													SELECT  IIF(Cod_cajero = 'BCP', 2, 1) AS I_EntidadFinanID, Nro_recibo, Cod_alu, T_NomDepositante,  
															Nro_recibo, Fch_pago, Cantidad, @T_Moneda, Monto, Id_lug_pag, Eliminado, @I_UsuarioID, 
															@D_FecProceso, NULL as observacion, NULL as adicional, 131 as condpago, 133 as tipoPago, 
															I_CtaDepositoID, ISNULL(@mora, 0) as mora, 1 AS migrado, NULL as motivo, Nro_recibo, 
															@I_TablaID_Det_Pago, I_RowID, @I_CtasMora_RowID
													FROM	#temp_det_pago
													WHERE  I_CtasPagoBncTableRowID IS NULL;

		SET @I_Pagos_Insertados = @@ROWCOUNT;


		/*	UPDATE REGISTROS PAGO	*/
		UPDATE det_pagos
		   SET I_CtasPagoBncTableRowID = cta_pago_banco.I_PagoBancoID,
			   B_Migrado = 1,
			   D_FecMigrado = @D_FecProceso
		  FROM TR_Ec_Det_Pagos det_pagos
			   INNER JOIN BD_OCEF_CtasPorCobrar.dbo.TR_PagoBanco cta_pago_banco ON det_pagos.I_RowID = cta_pago_banco.I_MigracionRowID
		 WHERE I_OblRowID = @I_OblRowID;

		UPDATE temp_det_pagos
		   SET I_CtasPagoBncTableRowID = det_pagos.I_CtasPagoBncTableRowID
		  FROM #temp_det_pago temp_det_pagos
			   INNER JOIN TR_Ec_Det_Pagos det_pagos ON det_pagos.I_RowID = temp_det_pagos.I_RowID;

		/*	UPDATE REGISTROS MORA	*/
		UPDATE det_pagos 
		   SET I_CtasPagoBncTableRowID = cta_pago_banco.I_PagoBancoID,
			   B_Migrado = 1,
			   D_FecMigrado = @D_FecProceso
		  FROM TR_Ec_Det_Pagos det_pagos
			   INNER JOIN BD_OCEF_CtasPorCobrar.dbo.TR_PagoBanco cta_pago_banco ON det_pagos.I_RowID = cta_pago_banco.I_MigracionMoraRowID
		 WHERE I_OblRowID = @I_OblRowID
			   AND Concepto <> 0
			   AND B_Migrable = 1;

		/*
			upsert pago procesado in ctas x cobrar
		*/

		UPDATE pago_proc
		   SET I_CtaDepositoID = temp_det_pagos.I_CtaDepositoID,
			   B_Anulado = tmp_det.Eliminado,
			   D_FecMod = @D_FecProceso,
			   I_MontoPagado = tmp_det.Monto,						   
			   B_Migrado = 1,
			   I_MigracionTablaID = @I_TablaID_Det
		  FROM BD_OCEF_CtasPorCobrar.dbo.TRI_PagoProcesadoUnfv pago_proc
			   INNER JOIN #temp_det_obl tmp_det ON pago_proc.I_MigracionRowID = tmp_det.I_RowID
			   INNER JOIN #temp_det_pago temp_det_pagos ON tmp_det.I_OblRowID = temp_det_pagos.I_OblRowID
		 WHERE tmp_det.I_CtasPagoProcTableRowID IS NOT NULL;

		 SET @I_Det_Actualizados = @@ROWCOUNT;


		INSERT INTO BD_OCEF_CtasPorCobrar.dbo.TRI_PagoProcesadoUnfv(I_PagoBancoID, I_CtaDepositoID, I_TasaUnfvID, I_MontoPagado, I_SaldoAPagar, 
																	I_PagoDemas, B_PagoDemas, N_NroSIAF, B_Anulado,  D_FecCre, I_UsuarioCre, D_FecMod, 
																	I_UsuarioMod, I_ObligacionAluDetID, B_Migrado, I_MigracionTablaID, I_MigracionRowID)
															SELECT  temp_det_pagos.I_CtasPagoBncTableRowID, temp_det_pagos.I_CtaDepositoID, NULL, tmp_det.Monto, 0,
																	0, tmp_det.Pag_demas, NULL, tmp_det.Eliminado, @D_FecProceso, @I_UsuarioID, NULL, 
																	NULL, tmp_det.I_CtasDetTableRowID, 1, @I_TablaID_Det, tmp_det.I_RowID
															  FROM  #temp_det_obl tmp_det 
																	INNER JOIN #temp_det_pago temp_det_pagos ON tmp_det.I_OblRowID = temp_det_pagos.I_OblRowID
																												AND tmp_det.Pagado = temp_det_pagos.Pagado
																												AND tmp_det.Eliminado = temp_det_pagos.Eliminado
															 WHERE  temp_det_pagos.I_CtasPagoBncTableRowID IS NOT NULL
																	AND tmp_det.I_CtasPagoProcTableRowID IS NULL;

		SET @I_Det_Insertados = @@ROWCOUNT;

		/*		
			Actualizar tmp_det con el id de pago procesado creado	
		*/
		UPDATE tmp_det
		   SET I_CtasPagoProcTableRowID = pago_proc.I_PagoProcesID
		  FROM #temp_det_obl tmp_det
			   INNER JOIN BD_OCEF_CtasPorCobrar.dbo.TRI_PagoProcesadoUnfv pago_proc ON tmp_det.I_RowID = pago_proc.I_MigracionRowID;
			
		/*		
			Actualizar pagado de TR_Ec_Det con los registros que tienen id de pago proc	
		*/
		UPDATE ec_det
		   SET I_CtasPagoProcTableRowID = tmp_det.I_CtasPagoProcTableRowID,
			   Pagado = tmp_det.Pagado
		  FROM TR_Ec_Det ec_det
			   INNER JOIN #temp_det_obl tmp_det ON tmp_det.I_RowID = ec_det.I_RowID;

		/*		
			Actualizar pagado de CtasPorCobrar TR_ObligacionAluDet con los registros que tienen id de pago proc	
		*/
		UPDATE alu_det
		   SET B_Pagado = 1
		  FROM BD_OCEF_CtasPorCobrar.dbo.TR_ObligacionAluDet alu_det
			   INNER JOIN #temp_det_obl tmp_det ON alu_det.I_MigracionRowID = tmp_det.I_RowID
												   AND alu_det.I_ObligacionAluDetID = tmp_det.I_CtasDetTableRowID
		WHERE tmp_det.I_CtasPagoProcTableRowID IS NOT NULL;

		COMMIT TRANSACTION;
					
		SET @I_PagoBancoID = (SELECT TOP 1 ISNULL(I_CtasPagoBncTableRowID, 0) FROM #temp_det_pago WHERE I_OblRowID = @I_OblRowID AND Eliminado = 0)
		SET @B_Resultado = 1
		SET @T_Message = '[{ ' +
							 'Type: "summary", ' + 
							 'Title: "Pagos Banco Insertados (OBL_ID: ' + CAST(@I_OblRowID AS varchar) + ')", ' + 
							 'Value: ' + CAST(@I_Pagos_Insertados AS varchar) +
						  '}, ' + 
						  '{ ' +
							 'Type: "summary", ' + 
							 'Title: "Pagos Procesados Insertados (OBL_ID: ' + CAST(@I_OblRowID AS varchar) + ')", ' + 
							 'Value: ' + CAST(@I_Det_Insertados AS varchar) +
						  '}, ' + 
						  '{ ' +
							 'Type: "summary", ' + 
							 'Title: "Pagos Banco Actualizados (OBL_ID: ' + CAST(@I_OblRowID AS varchar) + ')", ' + 
							 'Value: ' + CAST(@I_Pagos_Actualizados AS varchar) +
						  '}, ' + 
						  '{ ' +
							 'Type: "summary", ' + 
							 'Title: "Pagos Procesados Actualizados (OBL_ID: ' + CAST(@I_OblRowID AS varchar) + ')", ' + 
							 'Value: ' + CAST(@I_Det_Actualizados AS varchar) +
						  '}]' 

	END TRY
	BEGIN CATCH
		IF(@@TRANCOUNT > 0)
		BEGIN
			ROLLBACK TRANSACTION
		END

		SET @B_Resultado = 0
		SET @T_Message = '[{ ' +
							 'Type: "error", ' + 
							 'Title: "Error", ' + 
							 'Value: "' + ERROR_MESSAGE() + ' (Linea: ' + CAST(ERROR_LINE() AS varchar(11)) + ')."'  +
						  '}]' 
	END CATCH
END
GO



IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_IU_MigrarPagoObligacionesCtasPorCobrar')
	DROP PROCEDURE [dbo].[USP_IU_MigrarPagoObligacionesCtasPorCobrar]
GO


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_Obligaciones_Pagos_MigracionTP_CtasPorCobrar_IU_MigrarDataPorAnio')
	DROP PROCEDURE [dbo].[USP_Obligaciones_Pagos_MigracionTP_CtasPorCobrar_IU_MigrarDataPorAnio]
GO

CREATE PROCEDURE [dbo].[USP_Obligaciones_Pagos_MigracionTP_CtasPorCobrar_IU_MigrarDataPorAnio]	
	@I_ProcedenciaID	tinyint,
	@T_Anio				varchar(4),
	@B_Resultado		bit output,
	@T_Message			nvarchar(4000) OUTPUT	
AS
/*
	DECLARE @I_ProcedenciaID tinyint = 2,
			@T_Anio		  varchar(4) = '2008', 
			@B_Resultado  bit, 
			@T_Message	  nvarchar(4000)
	EXEC USP_Obligaciones_Pagos_MigracionTP_CtasPorCobrar_IU_MigrarDataPorAnio @I_ProcedenciaID, @T_Anio, @B_Resultado output, @T_Message output
	SELECT @B_Resultado as resultado, @T_Message as mensaje
*/
BEGIN
	DECLARE @D_FecProceso datetime = GETDATE() 
	DECLARE @I_TablaID_Obl int = 5
	DECLARE @I_TablaID_Det int = 4
	DECLARE @I_UsuarioID int = (SELECT dbo.Func_Config_CtasPorCobrar_I_ObtenerUsuarioMigracionID())

	DECLARE @I_TablaID_Det_Pago int = 7;
	DECLARE @T_Moneda varchar(3) = 'PEN';
	
	DECLARE @I_Pagos_Actualizados int = 0;
	DECLARE @I_Pagos_Insertados int = 0;

	DECLARE @I_Det_Actualizados int = 0
	DECLARE @I_Det_Insertados int = 0
	DECLARE @I_Total_pagos int = 0

	BEGIN TRANSACTION;
	BEGIN TRY 
		SELECT I_RowID, I_OblRowID, Cod_alu, Cod_rc, Cuota_pago, Ano, P, Tipo_oblig, Concepto, Fch_venc, Nro_recibo, 
			   Fch_pago, Id_lug_pag, Cantidad, Monto, Documento, Pagado, Concepto_f, Fch_elimin, Nro_ec, Fch_ec, Eliminado, 
			   Pag_demas, Cod_cajero, Tipo_pago, No_banco, Cod_dep, det.I_ProcedenciaID, B_Obligacion, det.B_Migrable, 
			   det.I_CtasDetTableRowID, det.I_CtasPagoProcTableRowID  
		  INTO #temp_det_obl
		  FROM TR_Ec_Det det
		 WHERE Ano = @T_Anio
			   AND I_ProcedenciaID = @I_ProcedenciaID
			   AND det.B_Migrable = 1;


		SELECT det.I_RowID, I_OblRowID, Cod_alu, Cod_rc, Cuota_pago, Ano, P, Tipo_oblig, Concepto, Fch_venc, Nro_recibo, 
			   Fch_pago, Id_lug_pag, Cantidad, Monto, Documento, Pagado, Concepto_f, Fch_elimin, Nro_ec, Fch_ec, Eliminado, 
			   Pag_demas, Cod_cajero, Tipo_pago, No_banco, Cod_dep, det.I_ProcedenciaID, B_Obligacion, det.B_Migrable, 
			   (a.T_ApePaterno + ' ' + a.T_ApeMaterno + ', ' + a.T_Nombre) AS T_NomDepositante, cdp.I_CtaDepositoID,
			   det.I_CtasPagoBncTableRowID
		  INTO #temp_det_pago
		  FROM TR_Ec_Det_Pagos det
			   INNER JOIN  TR_Alumnos a ON det.Cod_alu = a.C_CodAlu AND det.Cod_rc = a.C_RcCod
			   INNER JOIN  BD_OCEF_CtasPorCobrar.dbo.TI_CtaDepo_Proceso cdp ON det.cuota_pago = cdp.I_ProcesoID
		 WHERE det.Ano = @T_Anio
			   AND det.I_ProcedenciaID = @I_ProcedenciaID
			   AND det.Concepto = 0
			   AND det.B_Migrable = 1
			   AND cdp.B_Eliminado = 0;
	
		SELECT I_RowID, I_OblRowID, Monto 
		  INTO #temp_det_pago_mora
		  FROM TR_Ec_Det_Pagos
		 WHERE Ano = @T_Anio
			   AND I_ProcedenciaID = @I_ProcedenciaID
			   AND Concepto <> 0
			   AND B_Migrable = 1
			   AND Eliminado = 0;

		SET @I_Total_pagos = (SELECT COUNT(*) FROM #temp_det_pago)
		/*
			uptdate if exists pago banco in ctas x cobrar
		*/	
		UPDATE cta_pago_banco
		   SET T_NomDepositante = SRC_pago.T_NomDepositante,
			   C_Referencia = SRC_pago.Nro_recibo,
			   D_FecPago = SRC_pago.Fch_pago,
			   C_Moneda = @T_Moneda,
			   I_MontoPago = SRC_pago.Monto,
			   T_LugarPago = SRC_pago.Id_lug_pag,
			   B_Migrado = 1,
			   D_FecMod = @D_FecProceso,
			   I_UsuarioMod = @I_UsuarioID
		  FROM BD_OCEF_CtasPorCobrar.dbo.TR_PagoBanco cta_pago_banco
			   INNER JOIN #temp_det_pago SRC_pago ON cta_pago_banco.I_PagoBancoID = SRC_pago.I_CtasPagoBncTableRowID
													 AND cta_pago_banco.I_MigracionRowID = SRC_pago.I_RowID
		 
		 SET @I_Pagos_Actualizados = @@ROWCOUNT;


		/*
			insert new pago banco in ctas x cobrar
		*/
		INSERT INTO BD_OCEF_CtasPorCobrar.dbo.TR_PagoBanco (I_EntidadFinanID, C_CodOperacion, C_CodDepositante, T_NomDepositante, C_Referencia, 
															D_FecPago, I_Cantidad, C_Moneda, I_MontoPago, T_LugarPago, B_Anulado, I_UsuarioCre, 
															D_FecCre, T_Observacion, T_InformacionAdicional, I_CondicionPagoID, I_TipoPagoID, 
															I_CtaDepositoID, B_Migrado, T_MotivoCoreccion, C_CodigoInterno, I_MigracionTablaID, 
															I_MigracionRowID, I_InteresMora, I_MigracionMoraRowID)
													SELECT  IIF(Cod_cajero = 'BCP', 2, 1) AS I_EntidadFinanID, Nro_recibo, Cod_alu, T_NomDepositante,  
															Nro_recibo, Fch_pago, Cantidad, @T_Moneda, Monto, Id_lug_pag, Eliminado, @I_UsuarioID, 
															@D_FecProceso, NULL as observacion, NULL as adicional, 131 as condpago, 133 as tipoPago, 
															I_CtaDepositoID, 1 AS migrado, NULL as motivo, Nro_recibo, @I_TablaID_Det_Pago, I_RowID,
															ISNULL((SELECT SUM(monto) FROM #temp_det_pago_mora WHERE I_OblRowID = tmp.I_OblRowID), 0) as mora, 
															(SELECT TOP 1 I_RowID FROM #temp_det_pago_mora WHERE I_OblRowID = tmp.I_OblRowID) as I_MoraRowID
													FROM	#temp_det_pago tmp
													WHERE  I_CtasPagoBncTableRowID IS NULL;

		SET @I_Pagos_Insertados = @@ROWCOUNT;


		/*	UPDATE REGISTROS PAGO	*/
		UPDATE det_pagos
		   SET I_CtasPagoBncTableRowID = cta_pago_banco.I_PagoBancoID,
			   B_Migrado = 1,
			   D_FecMigrado = @D_FecProceso
		  FROM TR_Ec_Det_Pagos det_pagos
			   INNER JOIN BD_OCEF_CtasPorCobrar.dbo.TR_PagoBanco cta_pago_banco ON det_pagos.I_RowID = cta_pago_banco.I_MigracionRowID
		 WHERE det_pagos.Ano = @T_Anio
		 	   AND det_pagos.I_ProcedenciaID = @I_ProcedenciaID
			   AND det_pagos.B_Migrable = 1

		UPDATE temp_det_pagos
		   SET I_CtasPagoBncTableRowID = det_pagos.I_CtasPagoBncTableRowID
		  FROM #temp_det_pago temp_det_pagos
			   INNER JOIN TR_Ec_Det_Pagos det_pagos ON det_pagos.I_RowID = temp_det_pagos.I_RowID;


		/*	UPDATE REGISTROS MORA	*/
		UPDATE det_pagos 
		   SET I_CtasPagoBncTableRowID = cta_pago_banco.I_PagoBancoID,
			   B_Migrado = 1,
			   D_FecMigrado = @D_FecProceso
		  FROM TR_Ec_Det_Pagos det_pagos
			   INNER JOIN (SELECT I_OblRowID, I_PagoBancoID 
			   				 FROM #temp_det_pago_mora dpm 
			   					  INNER JOIN BD_OCEF_CtasPorCobrar.dbo.TR_PagoBanco cta_pago_banco 
											 ON dpm.I_RowID = cta_pago_banco.I_MigracionMoraRowID
						  ) cta_pago_banco ON det_pagos.I_OblRowID = cta_pago_banco.I_OblRowID
		 WHERE det_pagos.Ano = @T_Anio
		 	   AND det_pagos.I_ProcedenciaID = @I_ProcedenciaID 
			   AND Concepto <> 0
			   AND B_Migrable = 1;


		/*
			upsert pago procesado in ctas x cobrar
		*/

		UPDATE pago_proc
		   SET I_CtaDepositoID = temp_det_pagos.I_CtaDepositoID,
			   B_Anulado = tmp_det.Eliminado,
			   D_FecMod = @D_FecProceso,
			   I_MontoPagado = tmp_det.Monto,						   
			   B_Migrado = 1,
			   I_MigracionTablaID = @I_TablaID_Det,
			   I_ObligacionAluDetID = tmp_det.I_CtasDetTableRowID
		  FROM BD_OCEF_CtasPorCobrar.dbo.TRI_PagoProcesadoUnfv pago_proc
			   INNER JOIN #temp_det_obl tmp_det ON pago_proc.I_MigracionRowID = tmp_det.I_RowID
			   INNER JOIN #temp_det_pago temp_det_pagos ON tmp_det.I_OblRowID = temp_det_pagos.I_OblRowID
		 WHERE tmp_det.I_CtasPagoProcTableRowID IS NOT NULL
		 	   AND temp_det_pagos.I_CtasPagoBncTableRowID IS NOT NULL

		 SET @I_Det_Actualizados = @@ROWCOUNT;


		INSERT INTO BD_OCEF_CtasPorCobrar.dbo.TRI_PagoProcesadoUnfv(I_PagoBancoID, I_CtaDepositoID, I_TasaUnfvID, I_MontoPagado, I_SaldoAPagar, 
																	I_PagoDemas, B_PagoDemas, N_NroSIAF, B_Anulado,  D_FecCre, I_UsuarioCre, D_FecMod, 
																	I_UsuarioMod, I_ObligacionAluDetID, B_Migrado, I_MigracionTablaID, I_MigracionRowID)
															SELECT  temp_det_pagos.I_CtasPagoBncTableRowID, temp_det_pagos.I_CtaDepositoID, NULL, tmp_det.Monto, 0,
																	0, tmp_det.Pag_demas, NULL, tmp_det.Eliminado, @D_FecProceso, @I_UsuarioID, NULL, 
																	NULL, tmp_det.I_CtasDetTableRowID, 1, @I_TablaID_Det, tmp_det.I_RowID
															  FROM  #temp_det_obl tmp_det 
																	INNER JOIN #temp_det_pago temp_det_pagos ON tmp_det.I_OblRowID = temp_det_pagos.I_OblRowID
																												AND tmp_det.Pagado = temp_det_pagos.Pagado
																												AND tmp_det.Eliminado = temp_det_pagos.Eliminado
															 WHERE  temp_det_pagos.I_CtasPagoBncTableRowID IS NOT NULL
																	AND tmp_det.I_CtasPagoProcTableRowID IS NULL;

		SET @I_Det_Insertados = @@ROWCOUNT;


		/*		
			Actualizar tmp_det con el id de pago procesado creado	
		*/
		UPDATE tmp_det
		   SET I_CtasPagoProcTableRowID = pago_proc.I_PagoProcesID
		  FROM #temp_det_obl tmp_det
			   INNER JOIN BD_OCEF_CtasPorCobrar.dbo.TRI_PagoProcesadoUnfv pago_proc ON tmp_det.I_RowID = pago_proc.I_MigracionRowID;


		/*		
			Actualizar pagado de TR_Ec_Det con los registros que tienen id de pago proc	
		*/
		UPDATE ec_det
		   SET I_CtasPagoProcTableRowID = tmp_det.I_CtasPagoProcTableRowID,
			   Pagado = tmp_det.Pagado
		  FROM TR_Ec_Det ec_det
			   INNER JOIN #temp_det_obl tmp_det ON tmp_det.I_RowID = ec_det.I_RowID;


		/*		
			Actualizar pagado de CtasPorCobrar TR_ObligacionAluDet con los registros que tienen id de pago proc	
		*/
		UPDATE alu_det
		   SET B_Pagado = 1, 
		   	   D_FecMod = @D_FecProceso
		  FROM BD_OCEF_CtasPorCobrar.dbo.TR_ObligacionAluDet alu_det
			   INNER JOIN #temp_det_obl tmp_det ON alu_det.I_MigracionRowID = tmp_det.I_RowID
												   AND alu_det.I_ObligacionAluDetID = tmp_det.I_CtasDetTableRowID
		 WHERE tmp_det.I_CtasPagoProcTableRowID IS NOT NULL;


		COMMIT TRANSACTION;

		SET @B_Resultado = 1
		SET @T_Message = '[{ ' +
							 'Type: "summary", ' + 
							 'Title: "Total pagos", ' + 
							 'Value: ' + CAST(@I_Total_pagos AS varchar) +
						  '}, ' + 
						  '{ ' +
							 'Type: "detail", ' + 
							 'Title: "Pagos Banco Insertados", ' + 
							 'Value: ' + CAST(@I_Pagos_Insertados AS varchar) +
						  '}, ' + 
						  '{ ' +
							 'Type: "detail", ' + 
							 'Title: "Pagos Procesados Insertados", ' + 
							 'Value: ' + CAST(@I_Det_Insertados AS varchar) +
						  '}, ' + 
						  '{ ' +
							 'Type: "detail", ' + 
							 'Title: "Pagos Banco Actualizados", ' + 
							 'Value: ' + CAST(@I_Pagos_Actualizados AS varchar) +
						  '}, ' + 
						  '{ ' +
							 'Type: "summary", ' + 
							 'Title: "Pagos Procesados Actualizados", ' + 
							 'Value: ' + CAST(@I_Det_Actualizados AS varchar) +
						  '}]' 

	END TRY
	BEGIN CATCH
		IF(@@TRANCOUNT > 0)
		BEGIN
			ROLLBACK TRANSACTION
		END

		SET @B_Resultado = 0
		SET @T_Message = '[{ ' +
							 'Type: "error", ' + 
							 'Title: "Error", ' + 
							 'Value: "' + ERROR_MESSAGE() + ' (Linea: ' + CAST(ERROR_LINE() AS varchar(10)) + ')."'  +
						  '}]' 
	END CATCH
END
GO