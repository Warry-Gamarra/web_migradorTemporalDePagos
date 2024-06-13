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
	declare @I_ProcedenciaID	tinyint = 3,
			@T_SchemaDB   varchar(20) = 'euded',
			@T_Anio		  varchar(4) = '2005',
			@B_Resultado  bit,
			@T_Message	  nvarchar(4000)
	exec USP_Obligaciones_Pagos_TemporalPagos_MigracionTP_IU_CopiarTabla @I_ProcedenciaID, @T_SchemaDB, @T_Anio, 
																		 @B_Resultado output, @T_Message output
	select @B_Resultado as resultado, @T_Message as mensaje
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
			SET @T_variables_conceptos = 'DECLARE @recibo_pago int = 0 ' +
										 'DECLARE @deudas_anteriores_2017 int = 6924 '


			SET @T_filtros_conceptos = '@recibo_pago, @deudas_anteriores_2017'
		END
		ELSE IF (@I_ProcedenciaID = @I_Proced_eupg)
		BEGIN
			SET @T_variables_conceptos = 'DECLARE @recibo_pago int = 0 ' +
										 'DECLARE @mora_pensiones int = 4788 ' +
										 'DECLARE @mat_ext_ma_reg_2008 int = 4817 ' +
										 'DECLARE @mat_ext_do_reg_2008 int = 4818 '

			SET @T_filtros_conceptos = '@recibo_pago, @mora_pensiones, @mat_ext_ma_reg_2008, @mat_ext_do_reg_2008'

		END
		ELSE IF (@I_ProcedenciaID = @I_Proced_euded)
		BEGIN
			SET @T_variables_conceptos = 'DECLARE @recibo_pago int = 0 ' +
										 'DECLARE @mora_pensiones int = 4788 ' +
										 'DECLARE @mat_2007_1 int = 304 ' +
										 'DECLARE @pen_2007_1 int = 305 ' +
										 'DECLARE @pen_2006_2 int = 301 ' +
										 'DECLARE @mat_2006_2 int = 300 ' +
										 'DECLARE @pen_2005_2 int = 54 ' +
										 'DECLARE @pen_ing_2014_2 int = 6645 ' 

			SET @T_filtros_conceptos = '@recibo_pago, @mora_pensiones, @mat_2007_1, @mat_2006_2, @pen_2007_1, @pen_2006_2, @pen_2005_2, @pen_ing_2014_2'

		END


		SET @T_SQL = 'DELETE TR_Ec_Det_Pagos ' + 
					 ' WHERE I_ProcedenciaID = '+ CAST(@I_ProcedenciaID as varchar(3)) + ' ' +
							'AND EXISTS (SELECT * FROM TR_Ec_Obl ' + 
										 'WHERE TR_Ec_Obl.I_RowID = I_OblRowID ' +
												'AND TR_Ec_Obl.Ano = ''' + @T_Anio + ''' ' +
												'AND TR_Ec_Obl.B_Migrado = 0 ' +
												'AND TR_Ec_Obl.I_ProcedenciaID = I_ProcedenciaID);'

		PRINT @T_SQL
		EXEC sp_executesql @T_SQL
		SET @I_Removidos = @@ROWCOUNT

						
		SET @T_SQL = 'DELETE TR_Ec_Det_Pagos ' +
					  'WHERE I_ProcedenciaID = '+ CAST(@I_ProcedenciaID as varchar(3)) + ' ' +
							'AND I_OblRowID IS NULL ' +
							'AND Ano = ''' + @T_Anio + ''' '
						
		PRINT @T_SQL
		EXEC sp_executesql @T_SQL
		SET @I_Removidos = @I_Removidos + @@ROWCOUNT


		DELETE FROM TI_ObservacionRegistroTabla 
			  WHERE	I_TablaID = 7 
					AND I_ProcedenciaID = @I_ProcedenciaID
					AND NOT EXISTS (SELECT I_RowID FROM TR_Ec_Det_Pagos WHERE I_RowID = I_FilaTablaID);

		

		SET @T_SQL = 'DECLARE @D_FecProceso datetime = GETDATE() ' + @T_variables_conceptos +
					 
					 
					 'INSERT INTO TR_Ec_Det_Pagos (Cod_alu, Cod_rc, Cuota_pago, Ano, P, Tipo_oblig, Concepto, Fch_venc, Nro_recibo, Fch_pago, ' +
												  'Id_lug_pag, Cantidad, Monto, Documento, Pagado, Concepto_f, Fch_elimin, Nro_ec, Fch_ec, ' +
												  'Pag_demas, Tipo_pago, No_banco, Cod_dep, I_ProcedenciaID, Eliminado, B_Obligacion, D_FecCarga, ' +
												  'Cod_cajero, B_Migrable, D_FecEvalua, B_Migrado, D_FecMigrado) ' +
										   'SELECT Cod_alu, Cod_rc, Cuota_pago, Ano, P, Tipo_oblig, Concepto, Fch_venc, Nro_recibo, Fch_pago, Id_lug_pag, ' +
												  'Cantidad, Monto, Documento, Pagado, Concepto_f, Fch_elimin, Nro_ec, Fch_ec, Pag_demas, Tipo_pago, No_banco, ' +
												  'Cod_dep, '+ CAST(@I_ProcedenciaID as varchar(3)) + ', Eliminado, 1 as B_Obligacion, @D_FecProceso as D_FecCarga, ' +
												  'Cod_cajero, 0 as B_Migrable, NULL as D_FecEvalua, 0  as B_Migrado, NULL as D_FecMigrado ' +											
											'FROM  BD_OCEF_TemporalPagos.' + @T_SchemaDB + '.ec_det ' +
											'WHERE ' +
												  'Pagado = 1 ' +
												  'AND Concepto_f = 1' +
												  'AND concepto IN (' + @T_filtros_conceptos +')' 

		PRINT @T_SQL
		EXEC sp_executesql @T_SQL
		SET @I_EcDet = @@ROWCOUNT

		IF(@I_Removidos > 0)
		BEGIN
			SET @I_Insertados = @I_EcDet - @I_Removidos
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
  declare	@B_Resultado  bit,
			@I_ProcedenciaID	tinyint = 3,
	    	@T_Anio		  varchar(4) = '2005',
			@T_Message	  nvarchar(4000)
  exec USP_Obligaciones_Pagos_MigracionTP_U_AsignarObligacionID @I_ProcedenciaID, @T_Anio, @B_Resultado output, @T_Message output
  select @B_Resultado as resultado, @T_Message as mensaj
*/
BEGIN 
	DECLARE @D_FecProceso datetime = GETDATE() 
	DECLARE @T_SQL nvarchar(max)
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
		 WHERE det_pg.Ano = @T_Anio
			   AND det_pg.I_ProcedenciaID = @I_ProcedenciaID

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
  declare	@B_Resultado  bit,
			@I_ProcedenciaID	tinyint = 3,
	    	@T_Anio  	  varchar(4) = '2005',
			@T_Message	  nvarchar(4000)
  exec USP_Obligaciones_Pagos_MigracionTP_U_InicializarEstadoValidacion @I_ProcedenciaID, @T_Anio, @B_Resultado output, @T_Message output
  select @B_Resultado as resultado, @T_Message as mensaj
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
		  FROM  TR_Ec_Det_Pagos det 
				INNER JOIN cte_obl_anio obl ON det.I_OblRowID = obl.I_OblRowID

		SET @B_Resultado = 1
		SET @T_Message =  '{' +
							 'Type: "summary", ' + 
							 'Title: "Actualizados", ' + 
							 'Value: ' + CAST(@@ROWCOUNT AS varchar) +  
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



/*	
	===============================================================================================
		Validaciones de tablas ec_obl y ec_det segun procedencia y año	
	===============================================================================================
*/ 

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
  declare	@B_Resultado  bit,
			@I_ProcedenciaID	tinyint = 2,
	    	@T_Anio	      varchar(4) = '2016',
			@T_Message	  nvarchar(4000)
  exec USP_Obligaciones_Pagos_MigracionTP_U_Validar_52_SinObligacionID @I_ProcedenciaID, @I_Anio, @B_Resultado output, @T_Message output
  select @B_Resultado as resultado, @T_Message as mensaje
*/
BEGIN
	DECLARE @D_FecProceso datetime = GETDATE() 
	DECLARE @I_ObservID_sinOblId int = 52
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
		USING (SELECT @I_ObservID_sinOblId AS I_ObservID, @I_TablaID AS I_TablaID, I_RowID AS I_FilaTablaID, @D_FecProceso AS D_FecRegistro 
				 FROM TR_Ec_Det_Pagos 
				WHERE I_OblRowID IS NULL
					  AND I_ProcedenciaID = @I_ProcedenciaID
					  AND Ano = @T_Anio
			  ) AS SRC
		ON TRG.I_ObservID = SRC.I_ObservID AND TRG.I_TablaID = SRC.I_TablaID AND TRG.I_FilaTablaID = SRC.I_FilaTablaID
		WHEN MATCHED AND TRG.I_FilaTablaID = SRC.I_FilaTablaID THEN
			UPDATE SET D_FecRegistro = SRC.D_FecRegistro, 
					   B_Resuelto = 0
		WHEN NOT MATCHED BY TARGET AND SRC.I_FilaTablaID = SRC.I_FilaTablaID THEN
			INSERT (I_ObservID, I_TablaID, I_FilaTablaID, D_FecRegistro, I_ProcedenciaID)
			VALUES (SRC.I_ObservID, SRC.I_TablaID, SRC.I_FilaTablaID, SRC.D_FecRegistro, @I_ProcedenciaID);


		UPDATE OBS
		   SET D_FecResuelto = @D_FecProceso,
			   B_Resuelto = 1
		  FROM TI_ObservacionRegistroTabla OBS
			   INNER JOIN (SELECT * FROM TR_Ec_Det_Pagos WHERE I_OblRowID IS NOT NULL 
															   AND Ano = @T_Anio) DPG 
						  ON OBS.I_FilaTablaID = DPG.I_RowID
							 AND OBS.I_ProcedenciaID = DPG.I_ProcedenciaID
		 WHERE OBS.I_ObservID = @I_ObservID_sinOblId 
			   AND OBS.I_TablaID = @I_TablaID
			   AND OBS.I_FilaTablaID = DPG.I_RowID

		SET @B_Resultado = 1
		SET @T_Message =  '{' +
							 'Type: "summary", ' + 
							 'Title: "Actualizados", ' + 
							 'Value: ' + CAST(@@ROWCOUNT AS varchar) +  
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


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_Obligaciones_Pagos_MigracionTP_U_Validar_52_SinObligacionIDPorID')
	DROP PROCEDURE [dbo].[USP_Obligaciones_Pagos_MigracionTP_U_Validar_52_SinObligacionIDPorID]
GO

CREATE PROCEDURE USP_Obligaciones_Pagos_MigracionTP_U_Validar_52_SinObligacionIDPorID	
	@I_ProcedenciaID tinyint,
	@I_RowID	  int,
	@B_Resultado  bit output,
	@T_Message	  nvarchar(4000) OUTPUT	
AS
/*
  declare	@B_Resultado  bit,
			@I_ProcedenciaID	tinyint = 3,
			@I_RowID	  int = 3,
			@T_Message	  nvarchar(4000)
  exec USP_Obligaciones_Pagos_MigracionTP_U_Validar_52_SinObligacionIDPorID @I_ProcedenciaID, @I_RowID, @B_Resultado output, @T_Message output
  select @B_Resultado as resultado, @T_Message as mensaje
*/
BEGIN
	DECLARE @D_FecProceso datetime = GETDATE() 
	DECLARE @I_ObservID_sinOblId int = 52
	DECLARE @I_TablaID int = 7
	DECLARE @I_OblRowID int

	BEGIN TRANSACTION
	BEGIN TRY

		SET @I_OblRowID = (SELECT I_OblRowID FROM TR_Ec_Det_Pagos WHERE I_RowID = @I_RowID)

		UPDATE TR_Ec_Det_Pagos
		   SET B_Migrable = 0, 
			   D_FecMigrado = @D_FecProceso
		 WHERE I_OblRowID IS NULL
			   AND I_RowID = @I_RowID
			   
 
		MERGE TI_ObservacionRegistroTabla AS TRG
		USING (SELECT @I_ObservID_sinOblId AS I_ObservID, @I_TablaID AS I_TablaID, I_RowID AS I_FilaTablaID, @D_FecProceso AS D_FecRegistro 
				 FROM TR_Ec_Det_Pagos 
				WHERE I_OblRowID IS NULL 
					  AND I_RowID = @I_RowID
			  ) AS SRC
		ON TRG.I_ObservID = SRC.I_ObservID AND TRG.I_TablaID = SRC.I_TablaID AND TRG.I_FilaTablaID = SRC.I_FilaTablaID
		WHEN MATCHED AND TRG.I_FilaTablaID = SRC.I_FilaTablaID THEN
			UPDATE SET D_FecRegistro = SRC.D_FecRegistro, 
					   B_Resuelto = 0
		WHEN NOT MATCHED BY TARGET AND SRC.I_FilaTablaID = SRC.I_FilaTablaID THEN
			INSERT (I_ObservID, I_TablaID, I_FilaTablaID, D_FecRegistro, I_ProcedenciaID)
			VALUES (SRC.I_ObservID, SRC.I_TablaID, SRC.I_FilaTablaID, SRC.D_FecRegistro, @I_ProcedenciaID);


		UPDATE OBS
		   SET D_FecResuelto = @D_FecProceso,
			   B_Resuelto = 1
		  FROM TI_ObservacionRegistroTabla OBS
			   INNER JOIN (SELECT * FROM TR_Ec_Det_Pagos WHERE I_OblRowID IS NOT NULL 
															   AND I_RowID = @I_RowID) DPG 
						  ON OBS.I_FilaTablaID = DPG.I_RowID
							 AND OBS.I_ProcedenciaID = DPG.I_ProcedenciaID
		 WHERE OBS.I_ObservID = @I_ObservID_sinOblId 
			   AND OBS.I_TablaID = @I_TablaID


		SET @B_Resultado = 1
		SET @T_Message =  '{' +
							 'Type: "summary", ' + 
							 'Title: "Actualizados", ' + 
							 'Value: ' + CAST(@@ROWCOUNT AS varchar) +  
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



IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_Obligaciones_Pagos_MigracionTP_U_Validar_53_MontoPagadoDetalle')
	DROP PROCEDURE [dbo].[USP_Obligaciones_Pagos_MigracionTP_U_Validar_53_MontoPagadoDetalle]
GO

CREATE PROCEDURE USP_Obligaciones_Pagos_MigracionTP_U_Validar_53_MontoPagadoDetalle	
	@I_ProcedenciaID tinyint,
	@I_Anio	      smallint,
	@B_Resultado  bit output,
	@T_Message	  nvarchar(4000) OUTPUT	
AS
/*
  declare	@B_Resultado  bit,
			@I_ProcedenciaID	tinyint = 3,
	    	@I_Anio  	  smallint = 2010,
			@T_Message	  nvarchar(4000)
  exec USP_Obligaciones_Pagos_MigracionTP_U_Validar_53_MontoPagadoDetalle @I_ProcedenciaID, @I_Anio, @B_Resultado output, @T_Message output
  select @B_Resultado as resultado, @T_Message as mensaj
*/
BEGIN
	DECLARE @D_FecProceso datetime = GETDATE() 
	DECLARE @I_ObservID_sinOblId int = 53
	DECLARE @I_TablaID int = 7

	BEGIN TRANSACTION
	BEGIN TRY
		
		SELECT I_OblRowID, SUM(Monto) as Sum_Monto 
		  INTO #temp_pagos_detalle
		  FROM TR_Ec_Det 
		 WHERE Concepto_f = 0 AND Pagado = 1
				AND Ano = CAST(@I_Anio as varchar(4))
				AND I_ProcedenciaID = @I_ProcedenciaID
		GROUP BY I_OblRowID


		UPDATE EDP
		   SET B_Migrable = 0, 
			   D_FecMigrado = @D_FecProceso
		  FROM TR_Ec_Det_Pagos EDP
			   INNER JOIN #temp_pagos_detalle ED ON EDP.I_OblRowID = ED.I_OblRowID
		 WHERE EDP.Monto <> ED.Sum_Monto 

		SET @T_Message =  '{' +
							 'Type: "summary", ' + 
							 'Title: "Actualizados", ' + 
							 'Value: ' + CAST(@@ROWCOUNT AS varchar) +  
						  '}'

		MERGE TI_ObservacionRegistroTabla AS TRG
		USING (SELECT @I_ObservID_sinOblId AS I_ObservID, @I_TablaID AS I_TablaID, I_RowID AS I_FilaTablaID, @D_FecProceso AS D_FecRegistro 
				 FROM TR_Ec_Det_Pagos EDP
					  INNER JOIN #temp_pagos_detalle ED ON EDP.I_OblRowID = ED.I_OblRowID
				WHERE EDP.Monto <> ED.Sum_Monto 
			  ) AS SRC
		ON TRG.I_ObservID = SRC.I_ObservID AND TRG.I_TablaID = SRC.I_TablaID AND TRG.I_FilaTablaID = SRC.I_FilaTablaID
		WHEN MATCHED AND TRG.I_FilaTablaID = SRC.I_FilaTablaID THEN
			UPDATE SET D_FecRegistro = SRC.D_FecRegistro, 
					   B_Resuelto = 0
		WHEN NOT MATCHED BY TARGET AND SRC.I_FilaTablaID = SRC.I_FilaTablaID THEN
			INSERT (I_ObservID, I_TablaID, I_FilaTablaID, D_FecRegistro, I_ProcedenciaID)
			VALUES (SRC.I_ObservID, SRC.I_TablaID, SRC.I_FilaTablaID, SRC.D_FecRegistro, @I_ProcedenciaID);


		UPDATE OBS
		   SET D_FecResuelto = @D_FecProceso,
			   B_Resuelto = 1
		  FROM TI_ObservacionRegistroTabla OBS
			   INNER JOIN (SELECT EDP.I_RowID, EDP.I_OblRowID 
							 FROM TR_Ec_Det_Pagos EDP
								  INNER JOIN #temp_pagos_detalle ED ON EDP.I_OblRowID = ED.I_OblRowID
							WHERE EDP.Monto = ED.Sum_Monto 
						  ) DPG ON OBS.I_FilaTablaID = DPG.I_RowID
		 WHERE OBS.I_ObservID = @I_ObservID_sinOblId 
			   AND OBS.I_TablaID = @I_TablaID

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


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_Obligaciones_Pagos_MigracionTP_U_Validar_53_MontoPagadoDetallePorID')
	DROP PROCEDURE [dbo].[USP_Obligaciones_Pagos_MigracionTP_U_Validar_53_MontoPagadoDetallePorID]
GO

CREATE PROCEDURE USP_Obligaciones_Pagos_MigracionTP_U_Validar_53_MontoPagadoDetallePorID	
	@I_ProcedenciaID tinyint,
	@I_RowID	  int,
	@B_Resultado  bit output,
	@T_Message	  nvarchar(4000) OUTPUT	
AS
/*
  declare	@B_Resultado  bit,
			@I_ProcedenciaID	tinyint = 3,
			@I_RowID	  int = 3,
			@T_Message	  nvarchar(4000)
  exec USP_Obligaciones_Pagos_MigracionTP_U_Validar_53_MontoPagadoDetallePorID @I_ProcedenciaID, @I_RowID, @B_Resultado output, @T_Message output
  select @B_Resultado as resultado, @T_Message as mensaj
*/
BEGIN
	DECLARE @D_FecProceso datetime = GETDATE() 
	DECLARE @I_ObservID_sinOblId int = 53
	DECLARE @I_TablaID int = 7
	DECLARE @I_OblRowID int

	BEGIN TRANSACTION
	BEGIN TRY
		
		SET @I_OblRowID = (SELECT I_OblRowID FROM TR_Ec_Det_Pagos WHERE I_RowID = @I_RowID)
		
		SELECT I_OblRowID, SUM(Monto) as Sum_Monto 
		  INTO #temp_pagos_detalle
		  FROM TR_Ec_Det 
		 WHERE Concepto_f = 0 AND Pagado = 1
				AND I_OblRowID = @I_OblRowID
				AND I_ProcedenciaID = @I_ProcedenciaID
		GROUP BY I_OblRowID


		UPDATE EDP
		   SET B_Migrable = 0, 
			   D_FecMigrado = @D_FecProceso
		  FROM TR_Ec_Det_Pagos EDP
			   INNER JOIN #temp_pagos_detalle ED ON EDP.I_OblRowID = ED.I_OblRowID
		 WHERE EDP.Monto <> ED.Sum_Monto
			   AND EDP.I_RowID = @I_RowID

		SET @T_Message =  '{' +
							 'Type: "summary", ' + 
							 'Title: "Actualizados", ' + 
							 'Value: ' + CAST(@@ROWCOUNT AS varchar) +  
						  '}'


		MERGE TI_ObservacionRegistroTabla AS TRG
		USING (SELECT @I_ObservID_sinOblId AS I_ObservID, @I_TablaID AS I_TablaID, I_RowID AS I_FilaTablaID, @D_FecProceso AS D_FecRegistro 
				 FROM TR_Ec_Det_Pagos EDP
					  INNER JOIN #temp_pagos_detalle ED ON EDP.I_OblRowID = ED.I_OblRowID
				WHERE EDP.Monto <> ED.Sum_Monto 
					  AND EDP.I_RowID = @I_RowID
			  ) AS SRC
		ON TRG.I_ObservID = SRC.I_ObservID AND TRG.I_TablaID = SRC.I_TablaID AND TRG.I_FilaTablaID = SRC.I_FilaTablaID
		WHEN MATCHED AND TRG.I_FilaTablaID = SRC.I_FilaTablaID THEN
			UPDATE SET D_FecRegistro = SRC.D_FecRegistro, 
					   B_Resuelto = 0
		WHEN NOT MATCHED BY TARGET AND SRC.I_FilaTablaID = SRC.I_FilaTablaID THEN
			INSERT (I_ObservID, I_TablaID, I_FilaTablaID, D_FecRegistro, I_ProcedenciaID)
			VALUES (SRC.I_ObservID, SRC.I_TablaID, SRC.I_FilaTablaID, SRC.D_FecRegistro, @I_ProcedenciaID);


		UPDATE OBS
		   SET D_FecResuelto = @D_FecProceso,
			   B_Resuelto = 1
		  FROM TI_ObservacionRegistroTabla OBS
			   INNER JOIN (SELECT EDP.I_RowID, EDP.I_OblRowID 
							 FROM TR_Ec_Det_Pagos EDP
								  INNER JOIN #temp_pagos_detalle ED ON EDP.I_OblRowID = ED.I_OblRowID
							WHERE EDP.Monto = ED.Sum_Monto 
						  ) DPG ON OBS.I_FilaTablaID = DPG.I_RowID
		 WHERE OBS.I_ObservID = @I_ObservID_sinOblId 
			   AND OBS.I_TablaID = @I_TablaID
			   AND OBS.I_FilaTablaID = @I_RowID

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


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_Obligaciones_Pagos_MigracionTP_U_Validar_54_EstadoPagadoObligacion')
	DROP PROCEDURE [dbo].[USP_Obligaciones_Pagos_MigracionTP_U_Validar_54_EstadoPagadoObligacion]
GO

CREATE PROCEDURE USP_Obligaciones_Pagos_MigracionTP_U_Validar_54_EstadoPagadoObligacion	
	@I_ProcedenciaID tinyint,
	@I_Anio	      smallint,
	@B_Resultado  bit output,
	@T_Message	  nvarchar(4000) OUTPUT	
AS
/*
  declare	@B_Resultado  bit,
			@I_ProcedenciaID	tinyint = 3,
	    	@I_Anio  	  smallint = 2010,
			@T_Message	  nvarchar(4000)
  exec USP_Obligaciones_Pagos_MigracionTP_U_Validar_54_EstadoPagadoObligacion @I_ProcedenciaID, @I_Anio, @B_Resultado output, @T_Message output
  select @B_Resultado as resultado, @T_Message as mensaj
*/
BEGIN
	DECLARE @D_FecProceso datetime = GETDATE() 
	DECLARE @I_ObservID_sinOblId int = 54
	DECLARE @I_TablaID int = 7

	BEGIN TRANSACTION
	BEGIN TRY
		

		UPDATE EDP
		   SET B_Migrable = 0, 
			   D_FecMigrado = @D_FecProceso
		  FROM TR_Ec_Det_Pagos EDP
			   INNER JOIN TR_Ec_Obl EO ON EDP.I_OblRowID = EO.I_RowID
		 WHERE ISNULL(EO.Pagado, 0) <> ISNULL(EDP.Pagado, 0)

		SET @T_Message =  '{' +
							 'Type: "summary", ' + 
							 'Title: "Actualizados", ' + 
							 'Value: ' + CAST(@@ROWCOUNT AS varchar) +  
						  '}'

		MERGE TI_ObservacionRegistroTabla AS TRG
		USING (SELECT @I_ObservID_sinOblId AS I_ObservID, @I_TablaID AS I_TablaID, EDP.I_RowID AS I_FilaTablaID, @D_FecProceso AS D_FecRegistro 
				 FROM TR_Ec_Det_Pagos EDP
					  INNER JOIN TR_Ec_Obl EO ON EDP.I_OblRowID = EO.I_RowID
				WHERE ISNULL(EO.Pagado, 0) <> ISNULL(EDP.Pagado, 0) 
			  ) AS SRC
		ON TRG.I_ObservID = SRC.I_ObservID AND TRG.I_TablaID = SRC.I_TablaID AND TRG.I_FilaTablaID = SRC.I_FilaTablaID
		WHEN MATCHED AND TRG.I_FilaTablaID = SRC.I_FilaTablaID THEN
			UPDATE SET D_FecRegistro = SRC.D_FecRegistro, 
					   B_Resuelto = 0
		WHEN NOT MATCHED BY TARGET AND SRC.I_FilaTablaID = SRC.I_FilaTablaID THEN
			INSERT (I_ObservID, I_TablaID, I_FilaTablaID, D_FecRegistro, I_ProcedenciaID)
			VALUES (SRC.I_ObservID, SRC.I_TablaID, SRC.I_FilaTablaID, SRC.D_FecRegistro, @I_ProcedenciaID);


		UPDATE OBS
		   SET D_FecResuelto = @D_FecProceso,
			   B_Resuelto = 1
		  FROM TI_ObservacionRegistroTabla OBS
			   INNER JOIN (SELECT EDP.* FROM TR_Ec_Det_Pagos EDP
								  INNER JOIN TR_Ec_Obl EO ON EDP.I_OblRowID = EO.I_RowID
							WHERE ISNULL(EO.Pagado, 0) = ISNULL(EDP.Pagado, 0) 
						  ) DPG ON OBS.I_FilaTablaID = DPG.I_RowID
		 WHERE OBS.I_ObservID = @I_ObservID_sinOblId 
			   AND OBS.I_TablaID = @I_TablaID

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


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_Obligaciones_Pagos_MigracionTP_U_Validar_54_EstadoPagadoObligacionPorID')
	DROP PROCEDURE [dbo].[USP_Obligaciones_Pagos_MigracionTP_U_Validar_54_EstadoPagadoObligacionPorID]
GO

CREATE PROCEDURE USP_Obligaciones_Pagos_MigracionTP_U_Validar_54_EstadoPagadoObligacionPorID	
	@I_ProcedenciaID tinyint,
	@I_RowID	  int,
	@B_Resultado  bit output,
	@T_Message	  nvarchar(4000) OUTPUT	
AS
/*
  declare	@B_Resultado  bit,
			@I_ProcedenciaID	tinyint = 3,
			@I_RowID	  int = 3,
			@T_Message	  nvarchar(4000)
  exec USP_Obligaciones_Pagos_MigracionTP_U_Validar_54_EstadoPagadoObligacionPorID @I_ProcedenciaID, @I_RowID, @B_Resultado output, @T_Message output
  select @B_Resultado as resultado, @T_Message as mensaj
*/
BEGIN
	DECLARE @D_FecProceso datetime = GETDATE() 
	DECLARE @I_ObservID_sinOblId int = 54
	DECLARE @I_TablaID int = 7
	DECLARE @I_OblRowID int

	BEGIN TRANSACTION
	BEGIN TRY
		
		SET @I_OblRowID = (SELECT I_OblRowID FROM TR_Ec_Det_Pagos WHERE I_RowID = @I_RowID)
		
		UPDATE EDP
		   SET B_Migrable = 0, 
			   D_FecMigrado = @D_FecProceso
		  FROM TR_Ec_Det_Pagos EDP
			   INNER JOIN TR_Ec_Obl EO ON EDP.I_OblRowID = EO.I_RowID 
		 WHERE EDP.Pagado <> EO.Pagado 
			   AND EDP.I_RowID = @I_RowID

		SET @T_Message =  '{' +
							 'Type: "summary", ' + 
							 'Title: "Actualizados", ' + 
							 'Value: ' + CAST(@@ROWCOUNT AS varchar) +  
						  '}'

		MERGE TI_ObservacionRegistroTabla AS TRG
		USING (SELECT @I_ObservID_sinOblId AS I_ObservID, @I_TablaID AS I_TablaID, EDP.I_RowID AS I_FilaTablaID, @D_FecProceso AS D_FecRegistro 
				 FROM TR_Ec_Det_Pagos EDP
					  INNER JOIN TR_Ec_Obl EO ON EDP.I_OblRowID = EO.I_RowID 
				WHERE EDP.Pagado <> EO.Pagado 
					  AND EDP.I_RowID = @I_RowID
			  ) AS SRC
		ON TRG.I_ObservID = SRC.I_ObservID AND TRG.I_TablaID = SRC.I_TablaID AND TRG.I_FilaTablaID = SRC.I_FilaTablaID
		WHEN MATCHED AND TRG.I_FilaTablaID = SRC.I_FilaTablaID THEN
			UPDATE SET D_FecRegistro = SRC.D_FecRegistro, 
					   B_Resuelto = 0
		WHEN NOT MATCHED BY TARGET AND SRC.I_FilaTablaID = SRC.I_FilaTablaID THEN
			INSERT (I_ObservID, I_TablaID, I_FilaTablaID, D_FecRegistro, I_ProcedenciaID)
			VALUES (SRC.I_ObservID, SRC.I_TablaID, SRC.I_FilaTablaID, SRC.D_FecRegistro, @I_ProcedenciaID);


		UPDATE OBS
		   SET D_FecResuelto = @D_FecProceso,
			   B_Resuelto = 1
		  FROM TI_ObservacionRegistroTabla OBS
			   INNER JOIN (SELECT EDP.I_RowID, EDP.I_OblRowID 
							 FROM TR_Ec_Det_Pagos EDP
								  INNER JOIN TR_Ec_Obl EO ON EDP.I_OblRowID = EO.I_RowID 
							WHERE EDP.Pagado = EO.Pagado 
						  ) DPG ON OBS.I_FilaTablaID = DPG.I_RowID
		 WHERE OBS.I_ObservID = @I_ObservID_sinOblId 
			   AND OBS.I_TablaID = @I_TablaID
			   AND OBS.I_FilaTablaID = @I_RowID

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
	declare @I_ProcedenciaID tinyint = 3,
			@T_Anio		 varchar(4) = '2010', 
			@B_Resultado  bit, 
			@T_Message nvarchar(4000)
	exec USP_Obligaciones_Pagos_MigracionTP_U_Validar_55_ExisteEnDestinoConOtroBanco @I_ProcedenciaID, @T_Anio, @B_Resultado output, @T_Message output
	select @B_Resultado as resultado, @T_Message as mensaje
*/
BEGIN
	DECLARE @I_Observados int = 0

	BEGIN TRANSACTION;
	BEGIN TRY 


	
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
							 'Value: "' + ERROR_MESSAGE() + ' (Linea: ' + CAST(ERROR_LINE() AS varchar(11)) + ')."'  +
						  '}]' 
	END CATCH
END
GO


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_Obligaciones_Pagos_MigracionTP_U_Validar_55_ExisteEnDestinoConOtroBancoPorID')
	DROP PROCEDURE [dbo].[USP_Obligaciones_Pagos_MigracionTP_U_Validar_55_ExisteEnDestinoConOtroBancoPorID]
GO


CREATE PROCEDURE [dbo].[USP_Obligaciones_Pagos_MigracionTP_U_Validar_55_ExisteEnDestinoConOtroBancoPorID]	
	@I_ProcedenciaID	tinyint,
	@I_RowID			int,
	@B_Resultado		bit output,
	@T_Message			nvarchar(4000) OUTPUT	
AS
/*
	declare @I_ProcedenciaID tinyint = 3,
			@I_RowID	 int,
			@B_Resultado  bit, 
			@T_Message nvarchar(4000)
	exec USP_Obligaciones_Pagos_MigracionTP_U_Validar_55_ExisteEnDestinoConOtroBancoPorID @I_ProcedenciaID, @I_RowID, @B_Resultado output, @T_Message output
	select @B_Resultado as resultado, @T_Message as mensaje
*/
BEGIN
	DECLARE @Cuota_pago int
	DECLARE @Anio int
	DECLARE @P varchar(3)
	DECLARE @fch_venc date
	DECLARE @monto decimal(10,2)
	DECLARE @cod_alu varchar(20)
	DECLARE @cod_rc varchar(5)
	DECLARE @Nro_recibo varchar(20)

	DECLARE @I_Observados int = 0
	
	BEGIN TRANSACTION;
	BEGIN TRY 

		SELECT @Cod_Alu = Cod_Alu,
			   @Cod_rc = Cod_rc,
			   @Cuota_pago = Cuota_pago,
			   @P = P,
			   @Fch_venc = Fch_venc,
			   @Monto = Monto
		  FROM TR_Ec_Obl
		 WHERE I_RowID = @I_RowID
	
		SET @Nro_recibo = (SELECT DISTINCT Nro_recibo FROM TR_Ec_Det WHERE I_RowID = @I_RowID)



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
	declare @I_ProcedenciaID	tinyint = 3, 
			@T_Anio		  varchar(4) = '2005',
			@B_Resultado  bit,
			@T_Message    nvarchar(4000)
	exec USP_Obligaciones_Pagos_MigracionTP_U_Validar_56_DetalleObservado @I_ProcedenciaID, @T_Anio, @B_Resultado output, @T_Message output
	select @B_Resultado as resultado, @T_Message as mensaje
*/
BEGIN
	DECLARE @I_Observados int = 0
	DECLARE @I_ObservadosObl int = 0
	DECLARE @D_FecProceso datetime = GETDATE() 
	DECLARE @I_ObservID int = 56
	DECLARE @I_TablaID int = 7

	BEGIN TRANSACTION
	BEGIN TRY
		COMMIT TRANSACTION

		UPDATE	pago
		SET		B_Migrable = 0,
				D_FecEvalua = @D_FecProceso
		FROM    TR_Ec_Det_Pagos pago
				INNER JOIN TR_Ec_Det Det ON pago.I_OblRowID = Det.I_OblRowID
		WHERE	Det.B_Migrable = 0
				AND pago.Ano = @T_Anio
				AND Det.Eliminado = 0
				AND Det.I_ProcedenciaID = @I_ProcedenciaID
					
		MERGE	TI_ObservacionRegistroTabla AS TRG
		USING 	(SELECT	@I_ObservID AS I_ObservID, @I_TablaID AS I_TablaID, pago.I_RowID AS I_FilaTablaID, @D_FecProceso AS D_FecRegistro 
				 FROM   TR_Ec_Det_Pagos pago
						INNER JOIN TR_Ec_Det Det ON pago.I_OblRowID = Det.I_OblRowID
				 WHERE	Det.B_Migrable = 0
						AND pago.Ano = @T_Anio
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
	declare @I_ProcedenciaID	tinyint = 2, 
			@T_Anio		  varchar(4) = '2016',
			@B_Resultado  bit,
			@T_Message    nvarchar(4000)
	exec USP_Obligaciones_Pagos_MigracionTP_U_Validar_57_CabObligacionObservada @I_ProcedenciaID, @T_Anio, @B_Resultado output, @T_Message output
	select @B_Resultado as resultado, @T_Message as mensaje
*/
BEGIN
	DECLARE @I_Observados int = 0
	DECLARE @I_ObservadosObl int = 0
	DECLARE @D_FecProceso datetime = GETDATE() 
	DECLARE @I_ObservID int = 57
	DECLARE @I_TablaID int = 7

	BEGIN TRANSACTION
	BEGIN TRY
		COMMIT TRANSACTION

		UPDATE	pago
		SET		B_Migrable = 0,
				D_FecEvalua = @D_FecProceso
		FROM    TR_Ec_Det_Pagos pago
				INNER JOIN TR_Ec_Obl Obl ON pago.I_OblRowID = Obl.I_RowID
		WHERE	Obl.B_Migrable = 0
				AND pago.Ano = @T_Anio
				AND Obl.I_ProcedenciaID = @I_ProcedenciaID
					
		MERGE	TI_ObservacionRegistroTabla AS TRG
		USING 	(SELECT	@I_ObservID AS I_ObservID, @I_TablaID AS I_TablaID, pago.I_RowID AS I_FilaTablaID, @D_FecProceso AS D_FecRegistro 
				 FROM   TR_Ec_Det_Pagos pago
						INNER JOIN TR_Ec_Obl Obl ON pago.I_OblRowID = Obl.I_RowID
				 WHERE	Obl.B_Migrable = 0
						AND pago.Ano = @T_Anio
						AND Obl.I_ProcedenciaID = @I_ProcedenciaID
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



/*	
	===============================================================================================
		Migrar datos de tabla TR_Ec_Det_Pagos
	===============================================================================================
*/ 




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
	declare @I_ProcedenciaID tinyint = 3,
			@T_Anio		 varchar(4) = '2016', 
			@B_Resultado  bit, 
			@T_Message nvarchar(4000)
	exec USP_Obligaciones_Pagos_MigracionTP_CtasPorCobrar_IU_MigrarDataPorAnio @I_ProcedenciaID, @T_Anio, @B_Resultado output, @T_Message output
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

	DECLARE @Tbl_outputObl AS TABLE (T_Action varchar(20), I_RowID int, I_Inserted_RowID int, I_Deleted_RowID int)
	DECLARE @Tbl_outputDet AS TABLE (T_Action varchar(20), I_RowID int, I_Inserted_RowID int, I_Deleted_RowID int)

	BEGIN TRANSACTION;
	BEGIN TRY 

		SELECT I_RowID, Cuota_pago, Ano, P, I_Periodo, Cod_alu, Cod_rc, Tipo_oblig, Fch_venc, Monto, Pagado
		  INTO #temp_obl_migrable
		  FROM TR_Ec_Obl 
		 WHERE B_Migrable = 1
		 	   AND B_Migrado = 0
		 	   AND Ano = @T_Anio
		 	   AND I_ProcedenciaID = @I_ProcedenciaID

		SELECT I_RowID, Cuota_pago, Ano, P, I_Periodo, Cod_alu, Cod_rc, Tipo_oblig, Fch_venc, Monto, Pagado, 
			   I_CtasMatTableRowID, I_CtasCabTableRowID
		  INTO #temp_obl_migrado
		  FROM TR_Ec_Obl 
		 WHERE B_Migrable = 1
		 	   AND B_Migrado = 1
		 	   AND Ano = @T_Anio
		 	   AND I_ProcedenciaID = @I_ProcedenciaID
		 	   
		DECLARE @mora decimal(10,2)
		DECLARE @I_RowID  int


		DECLARE Cur_obl_migrable CURSOR
		FOR SELECT I_RowID FROM #temp_obl_migrable

		OPEN Cur_obl_migrable
		FETCH NEXT FROM Cur_obl_migrable INTO @I_RowID
		
		WHILE @@FETCH_STATUS = 0
		BEGIN

			DECLARE @I_OblRowID		int = @I_RowID,
					@I_OblAluID		int,
					@B_OblResultado bit,
					@T_OblMessage	nvarchar(4000)

			exec USP_Obligaciones_Pagos_MigracionTP_CtasPorCobrar_IU_MigrarDataPorID @I_OblRowID, @I_OblAluID output, @B_Resultado output, @T_Message output

			select @B_Resultado as resultado, @I_OblAluID as CtasOblID, @T_Message as mensaje

			FETCH NEXT FROM Cur_obl_migrable INTO @I_RowID
		END

		CLOSE Cur_obl_migrable
		DEALLOCATE Cur_obl_migrable


		COMMIT TRANSACTION
					
		SET @B_Resultado = 1
		SET @T_Message = '[{ ' +
							 'Type: "summary", ' + 
							 'Title: "Pagos Insertados", ' + 
							 'Value: ' + CAST(@I_Obl_Insertados AS varchar) +
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



IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_IU_MigrarPagoObligacionesCtasPorCobrar')
	DROP PROCEDURE [dbo].[USP_IU_MigrarPagoObligacionesCtasPorCobrar]
GO


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_Obligaciones_Pagos_MigracionTP_CtasPorCobrar_IU_MigrarDataPorID')
	DROP PROCEDURE [dbo].[USP_Obligaciones_Pagos_MigracionTP_CtasPorCobrar_IU_MigrarDataPorID]
GO


CREATE PROCEDURE [dbo].[USP_Obligaciones_Pagos_MigracionTP_CtasPorCobrar_IU_MigrarDataPorID]	
	@I_OblRowID		int,
	@I_OblAluID		int output,
	@B_Resultado	bit output,
	@T_Message		nvarchar(4000) OUTPUT	
AS
/*
	declare @I_OblRowID	  int = 626180,
			@I_OblAluID		int,
			@B_Resultado  bit,
			@T_Message nvarchar(4000)
	exec USP_Obligaciones_Pagos_MigracionTP_CtasPorCobrar_IU_MigrarDataPorID @I_OblRowID, @I_OblAluID output, @B_Resultado output, @T_Message output
	select @B_Resultado as resultado, @T_Message as mensaje
*/
BEGIN
	DECLARE @D_FecProceso datetime = GETDATE() 
	DECLARE @I_TablaID_Obl int = 5
	DECLARE @I_TablaID_Det int = 4
	DECLARE @I_TablaID_Det_Pago int = 7
	DECLARE @I_UsuarioID int = (SELECT dbo.Func_Config_CtasPorCobrar_I_ObtenerUsuarioMigracionID())
	DECLARE @I_CtasPagoBnc_RowID  int
	DECLARE @I_CtasPagoProc_RowID  int
	DECLARE @I_CtasMora_RowID  int
	DECLARE @T_Moneda varchar(3) = 'PEN'

	DECLARE @I_Pagos_Actualizados int = 0
	DECLARE @I_Pagos_Insertados int = 0

	DECLARE @I_Det_Actualizados int = 0
	DECLARE @I_Det_Insertados int = 0

	DECLARE @Tbl_outputObl AS TABLE (T_Action varchar(20), I_RowID int, I_Inserted_RowID int, I_Deleted_RowID int)
	DECLARE @Tbl_outputDet AS TABLE (T_Action varchar(20), I_RowID int, I_Inserted_RowID int, I_Deleted_RowID int)

	BEGIN TRANSACTION;
	BEGIN TRY 
		
		SELECT det.I_RowID, I_OblRowID, Cod_alu, Cod_rc, Cuota_pago, Ano, P, Tipo_oblig, Concepto, Fch_venc, Nro_recibo, 
			   Fch_pago, Id_lug_pag, Cantidad, Monto, Documento, Pagado, Concepto_f, Fch_elimin, Nro_ec, Fch_ec, Eliminado, 
			   Pag_demas, Cod_cajero, Tipo_pago, No_banco, Cod_dep, det.I_ProcedenciaID, B_Obligacion, det.B_Migrable, 
			   det.I_CtasDetTableRowID, det.I_CtasPagoProcTableRowID  
		  INTO #temp_det_obl
		  FROM TR_Ec_Det det
		 WHERE I_OblRowID = @I_OblRowID
			   AND det.B_Migrable = 1

		SELECT * FROM #temp_det_obl

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
			   AND cdp.B_Eliminado = 0

		SELECT * FROM #temp_det_pago
	
		SELECT I_RowID, I_OblRowID, Monto 
		  INTO #temp_det_pago_mora
		  FROM TR_Ec_Det_Pagos
		 WHERE I_OblRowID = @I_OblRowID
			   AND Concepto <> 0
			   AND B_Migrable = 1
			   AND Eliminado = 0

		SELECT * FROM #temp_det_pago_mora

		DECLARE @mora decimal(10,2)
		DECLARE @I_RowPagoID	int, 
				@I_RowDetID		int, 
				@Nro_recibo		varchar(20), 
				@Fch_pago		date, 
				@Id_lug_pag		varchar(10), 
				@Pagado			bit, 
				@Pagado_det		bit, 
				@Pag_demas		bit, 
				@Cod_cajero		varchar(20),
				@Cod_alu		varchar(20),
				@NombreDep		varchar(200),
				@Cantidad		decimal,
				@Monto			decimal(15, 2),
				@Eliminado		bit,
				@Fch_ec			date, 
				@Nro_ec			bigint, 
				@I_CtaDepID		int,
				@I_CtasBncID	int,
				@I_CtasDetID	int,
				@I_CtasProcID	int


		DECLARE pago_Cursor CURSOR 
		FOR SELECT I_RowID, Nro_recibo, Fch_pago, Id_lug_pag, Pagado, Pag_demas, Cod_cajero, Monto, Cantidad, T_NomDepositante, 
				   Cod_alu, Eliminado, Nro_ec, Fch_ec, I_CtaDepositoID, I_CtasPagoBncTableRowID 
			  FROM #temp_det_pago

		OPEN pago_Cursor
		FETCH NEXT FROM pago_Cursor INTO @I_RowPagoID, @Nro_recibo, @Fch_pago, @Id_lug_pag, @Pagado, @Pag_demas, @Cod_cajero, @Monto, 
										 @Cantidad, @NombreDep, @Cod_alu, @Eliminado, @Nro_ec, @Fch_ec, @I_CtaDepID, @I_CtasBncID;


		WHILE @@FETCH_STATUS = 0
		BEGIN

			SET @mora = (SELECT SUM(monto) FROM #temp_det_pago_mora WHERE I_OblRowID = @I_OblRowID)
			SET @I_CtasMora_RowID = (SELECT TOP 1 I_RowID FROM #temp_det_pago_mora WHERE I_OblRowID = @I_OblRowID)

			IF (@I_CtasBncID IS NULL)
			BEGIN
				INSERT INTO BD_OCEF_CtasPorCobrar.dbo.TR_PagoBanco (I_EntidadFinanID, C_CodOperacion, C_CodDepositante, T_NomDepositante, C_Referencia, 
																	D_FecPago, I_Cantidad, C_Moneda, I_MontoPago, T_LugarPago, B_Anulado, I_UsuarioCre, 
																	D_FecCre, T_Observacion, T_InformacionAdicional, I_CondicionPagoID, I_TipoPagoID, 
																	I_CtaDepositoID, I_InteresMora, B_Migrado, T_MotivoCoreccion, C_CodigoInterno, 
																	I_MigracionTablaID, I_MigracionRowID, I_MigracionMoraRowID)
															SELECT  IIF(@Cod_cajero = 'BCP', 2, 1) AS I_EntidadFinanID, @Nro_recibo, @Cod_alu, @NombreDep,  
																	@Nro_recibo, @Fch_pago, @Cantidad, @T_Moneda, @Monto, @Id_lug_pag, @Eliminado, @I_UsuarioID, 
																	@D_FecProceso, NULL as observacion, NULL as adicional, 131 as condpago, 133 as tipoPago, 
																	@I_CtaDepID, ISNULL(@mora, 0) as mora, 1 AS migrado, NULL as motivo, @Nro_recibo, 
																	@I_TablaID_Det_Pago, @I_RowPagoID, @I_CtasMora_RowID


				SET @I_CtasPagoBnc_RowID = SCOPE_IDENTITY()
				SET @I_Pagos_Insertados = @I_Pagos_Insertados + 1
			END
			ELSE
			BEGIN
				UPDATE BD_OCEF_CtasPorCobrar.dbo.TR_PagoBanco
				   SET T_NomDepositante = @NombreDep,
					   C_Referencia = @Nro_recibo,
					   D_FecPago = @Fch_pago,
					   C_Moneda = @T_Moneda,
					   I_MontoPago = @Monto,
					   T_LugarPago = @Id_lug_pag,
					   B_Migrado = 1,
					   D_FecMod = @D_FecProceso
				 WHERE I_PagoBancoID = @I_CtasBncID

				SET @I_CtasPagoBnc_RowID = @I_CtasBncID
				SET @I_Pagos_Actualizados = @I_Pagos_Actualizados + 1
			END

			UPDATE TR_Ec_Det_Pagos 
			   SET I_CtasPagoBncTableRowID = @I_CtasPagoBnc_RowID,
				   B_Migrado = 1,
				   D_FecMigrado = @D_FecProceso
			 WHERE I_RowID = @I_RowPagoID

			 UPDATE TR_Ec_Det_Pagos 
			   SET I_CtasPagoBncTableRowID = @I_CtasPagoBnc_RowID,
				   B_Migrado = 1,
				   D_FecMigrado = @D_FecProceso
			 WHERE I_OblRowID = @I_OblRowID
				   AND Concepto <> 0
				   AND B_Migrable = 1
				   AND Eliminado = 0


			DECLARE Det_Cursor CURSOR 
			FOR SELECT I_RowID, Nro_recibo, Fch_pago, Id_lug_pag, Pagado, Pag_demas, Cod_cajero, Monto, 
					   Eliminado, Fch_ec, I_CtasDetTableRowID, I_CtasPagoProcTableRowID 
				  FROM #temp_det_obl
				 WHERE Nro_recibo = @Nro_recibo
					   AND Pagado = @Pagado
					   AND Fch_pago = @Fch_pago
					   AND Eliminado = @Eliminado

			OPEN Det_Cursor
			FETCH NEXT FROM Det_Cursor INTO @I_RowDetID, @Nro_recibo, @Fch_pago, @Id_lug_pag, @Pagado_det, @Pag_demas, @Cod_cajero, @Monto, 
											@Eliminado, @Fch_ec, @I_CtasDetID, @I_CtasProcID;

			WHILE @@FETCH_STATUS = 0
			BEGIN

				IF (@I_CtasProcID IS NULL)
				BEGIN 
					INSERT INTO BD_OCEF_CtasPorCobrar.dbo.TRI_PagoProcesadoUnfv(I_PagoBancoID, I_CtaDepositoID, I_TasaUnfvID, I_MontoPagado, I_SaldoAPagar, 
																				I_PagoDemas, B_PagoDemas, N_NroSIAF, B_Anulado,  D_FecCre, I_UsuarioCre, D_FecMod, 
																				I_UsuarioMod, I_ObligacionAluDetID, B_Migrado, I_MigracionTablaID, I_MigracionRowID)
																		VALUES (@I_CtasPagoBnc_RowID, @I_CtaDePID, NULL, @Monto, 0,
																				0, @Pag_demas, NULL, @Eliminado, @D_FecProceso, @I_UsuarioID, NULL, 
																				NULL, @I_CtasDetID, 1, @I_TablaID_Det, @I_RowDetID)

					SET @I_CtasPagoProc_RowID = SCOPE_IDENTITY()
					 SET @I_Det_Insertados = @I_Det_Insertados + 1
				END
				ELSE 
				BEGIN
					UPDATE BD_OCEF_CtasPorCobrar.dbo.TRI_PagoProcesadoUnfv
					   SET I_CtaDepositoID = @I_CtaDepID,
						   B_Anulado = @Eliminado,
						   D_FecMod = @D_FecProceso,
						   I_MontoPagado = @Monto,						   
						   B_Migrado = 1,
						   I_MigracionTablaID = @I_TablaID_Det,
						   I_MigracionRowID = @I_RowDetID
					 WHERE I_PagoProcesID = @I_CtasProcID

					 SET @I_CtasPagoProc_RowID = @I_CtasProcID
					 SET @I_Det_Actualizados = @I_Det_Actualizados + 1
				END

				UPDATE BD_OCEF_CtasPorCobrar.dbo.TR_ObligacionAluDet
					SET B_Pagado = @Pagado_det
				 WHERE I_ObligacionAluDetID = @I_CtasDetID

				UPDATE TR_Ec_Det 
				   SET D_FecMigradoPago = @D_FecProceso,
					   B_MigradoPago = 1,
					   I_CtasPagoProcTableRowID = @I_CtasPagoProc_RowID
				 WHERE I_RowID = @I_RowDetID



				FETCH NEXT FROM Det_Cursor INTO @I_RowDetID, @Nro_recibo, @Fch_pago, @Id_lug_pag, @Pagado_det, @Pag_demas, @Cod_cajero, @Monto, 
												@Eliminado, @Fch_ec, @I_CtasDetID, @I_CtasProcID;
			END

			CLOSE Det_Cursor
			DEALLOCATE Det_Cursor


			UPDATE BD_OCEF_CtasPorCobrar.dbo.TR_ObligacionAluCab
			   SET B_Pagado = (SELECT B_Pagado FROM TR_Ec_Obl O WHERE O.I_RowID = @I_OblRowID)
			 WHERE I_MigracionRowID = @I_OblRowID
				   AND I_MigracionTablaID = @I_TablaID_Obl


			FETCH NEXT FROM pago_Cursor INTO @I_RowPagoID, @Nro_recibo, @Fch_pago, @Id_lug_pag, @Pagado, @Pag_demas, @Cod_cajero, @Monto, 
											 @Cantidad, @NombreDep, @Cod_alu, @Eliminado, @Nro_ec, @Fch_ec, @I_CtaDepID, @I_CtasBncID;

		END

		CLOSE pago_Cursor
		DEALLOCATE pago_Cursor

		COMMIT TRANSACTION
					
		SET @I_OblAluID = @I_CtasPagoBnc_RowID
		SET @B_Resultado = 1
		SET @T_Message = '[{ ' +
							 'Type: "summary", ' + 
							 'Title: "Pagos Banco Insertados", ' + 
							 'Value: ' + CAST(@I_Pagos_Insertados AS varchar) +
						  '}, ' + 
						  '{ ' +
							 'Type: "summary", ' + 
							 'Title: "Pagos Procesados Insertados", ' + 
							 'Value: ' + CAST(@I_Det_Insertados AS varchar) +
						  '}, ' + 
						  '{ ' +
							 'Type: "summary", ' + 
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


CREATE PROCEDURE [dbo].[USP_Obligaciones_Pagos_MigracionTP_CtasPorCobrar_IU_MigrarDataPorID2]	
	@I_OblRowID		int,
	@I_OblAluID		int output,
	@B_Resultado	bit output,
	@T_Message		nvarchar(4000) OUTPUT	
AS
/*
	declare @I_OblRowID	  int = 626180,
			@I_OblAluID		int,
			@B_Resultado  bit,
			@T_Message nvarchar(4000)
	exec USP_Obligaciones_Pagos_MigracionTP_CtasPorCobrar_IU_MigrarDataPorID2 @I_OblRowID, @I_OblAluID output, @B_Resultado output, @T_Message output
	select @B_Resultado as resultado, @T_Message as mensaje
*/
BEGIN
	DECLARE @D_FecProceso datetime = GETDATE() 
	DECLARE @I_TablaID_Obl int = 5
	DECLARE @I_TablaID_Det int = 4
	DECLARE @I_TablaID_Det_Pago int = 7
	DECLARE @I_UsuarioID int = (SELECT dbo.Func_Config_CtasPorCobrar_I_ObtenerUsuarioMigracionID())
	DECLARE @I_CtasPagoBnc_RowID  int
	DECLARE @I_CtasPagoProc_RowID  int
	DECLARE @I_CtasMora_RowID  int
	DECLARE @T_Moneda varchar(3) = 'PEN'

	DECLARE @I_Pagos_Actualizados int = 0
	DECLARE @I_Pagos_Insertados int = 0

	DECLARE @I_Det_Actualizados int = 0
	DECLARE @I_Det_Insertados int = 0

	DECLARE @Tbl_outputObl AS TABLE (T_Action varchar(20), I_RowID int, I_Inserted_RowID int, I_Deleted_RowID int)
	DECLARE @Tbl_outputDet AS TABLE (T_Action varchar(20), I_RowID int, I_Inserted_RowID int, I_Deleted_RowID int)

	BEGIN TRANSACTION;
	BEGIN TRY 
		
		SELECT det.I_RowID, I_OblRowID, Cod_alu, Cod_rc, Cuota_pago, Ano, P, Tipo_oblig, Concepto, Fch_venc, Nro_recibo, 
			   Fch_pago, Id_lug_pag, Cantidad, Monto, Documento, Pagado, Concepto_f, Fch_elimin, Nro_ec, Fch_ec, Eliminado, 
			   Pag_demas, Cod_cajero, Tipo_pago, No_banco, Cod_dep, det.I_ProcedenciaID, B_Obligacion, det.B_Migrable, 
			   det.I_CtasDetTableRowID, det.I_CtasPagoProcTableRowID  
		  INTO #temp_det_obl
		  FROM TR_Ec_Det det
		 WHERE I_OblRowID = @I_OblRowID
			   AND det.B_Migrable = 1

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
			   AND cdp.B_Eliminado = 0
	
		SELECT I_RowID, I_OblRowID, Monto 
		  INTO #temp_det_pago_mora
		  FROM TR_Ec_Det_Pagos
		 WHERE I_OblRowID = @I_OblRowID
			   AND Concepto <> 0
			   AND B_Migrable = 1
			   AND Eliminado = 0


		DECLARE @mora decimal(10,2)

		SET @mora = (SELECT SUM(monto) FROM #temp_det_pago_mora WHERE I_OblRowID = @I_OblRowID)
		SET @I_CtasMora_RowID = (SELECT TOP 1 I_RowID FROM #temp_det_pago_mora WHERE I_OblRowID = @I_OblRowID)

		/*
			insert new pago banco in ctas x cobrar
		*/
		INSERT INTO BD_OCEF_CtasPorCobrar.dbo.TR_PagoBanco (I_EntidadFinanID, C_CodOperacion, C_CodDepositante, T_NomDepositante, C_Referencia, 
															D_FecPago, I_Cantidad, C_Moneda, I_MontoPago, T_LugarPago, B_Anulado, I_UsuarioCre, 
															D_FecCre, T_Observacion, T_InformacionAdicional, I_CondicionPagoID, I_TipoPagoID, 
															I_CtaDepositoID, I_InteresMora, B_Migrado, T_MotivoCoreccion, C_CodigoInterno, 
															I_MigracionTablaID, I_MigracionRowID, I_MigracionMoraRowID)
													SELECT  IIF(Cod_cajero = 'BCP', 2, 1) AS I_EntidadFinanID, Nro_recibo, Cod_alu, NombreDep,  
															Nro_recibo, Fch_pago, Cantidad, T_Moneda, Monto, Id_lug_pag, Eliminado, @I_UsuarioID, 
															@D_FecProceso, NULL as observacion, NULL as adicional, 131 as condpago, 133 as tipoPago, 
															I_CtaDepositoID, ISNULL(@mora, 0) as mora, 1 AS migrado, NULL as motivo, Nro_recibo, 
															@I_TablaID_Det_Pago, I_RowID, @I_CtasMora_RowID
													  FROM	#temp_det_pago
													  WHERE I_CtasPagoBncTableRowID IS NULL


		/*
			uptdat if exists pago banco in ctas x cobrar
		*/

		UPDATE BD_OCEF_CtasPorCobrar.dbo.TR_PagoBanco
			SET T_NomDepositante = SRC_pago.T_NomDepositante,
				C_Referencia = SRC_pago.Nro_recibo,
				D_FecPago = SRC_pago.Fch_pago,
				C_Moneda = @T_Moneda,
				I_MontoPago = SRC_pago.Monto,
				T_LugarPago = SRC_pago.Id_lug_pag,
				B_Migrado = 1,
				D_FecMod = @D_FecProceso
		   FROM BD_OCEF_CtasPorCobrar.dbo.TR_PagoBanco cta_pago_banco
				INNER JOIN #temp_det_pago SRC_pago ON cta_pago_banco.I_PagoBancoID = SRC_pago.I_CtasPagoBncTableRowID
													  AND SRC_pago.I_RowID = cta_pago_banco.I_MigracionTablaID
		  WHERE I_CtasPagoBncTableRowID IS NOT NULL

		/*UPDATE REGISTROS PAGO*/
		UPDATE det_pagos
		   SET I_CtasPagoBncTableRowID = cta_pago_banco.I_PagoBancoID,
			   B_Migrado = 1,
			   D_FecMigrado = @D_FecProceso
		  FROM TR_Ec_Det_Pagos det_pagos
			   INNER JOIN BD_OCEF_CtasPorCobrar.dbo.TR_PagoBanco cta_pago_banco ON det_pagos.I_RowID = cta_pago_banco.I_MigracionRowID
		 WHERE I_OblRowID = @I_OblRowID


		/*UPDATE REGISTROS MORA*/

		UPDATE det_pagos_mora 
		SET I_CtasPagoBncTableRowID = cta_pago_banco.I_PagoBancoID,
			B_Migrado = 1,
			D_FecMigrado = @D_FecProceso
		  FROM TR_Ec_Det_Pagos det_pagos_mora
			   INNER JOIN BD_OCEF_CtasPorCobrar.dbo.TR_PagoBanco cta_pago_banco ON det_pagos_mora.I_RowID = cta_pago_banco.I_MigracionMoraRowID
		WHERE I_OblRowID = @I_OblRowID
			AND Concepto <> 0
			AND B_Migrable = 1
			AND Eliminado = 0


		/*
			insert new pago procesado in ctas x cobrar
		*/



			DECLARE Det_Cursor CURSOR 
			FOR SELECT I_RowID, Nro_recibo, Fch_pago, Id_lug_pag, Pagado, Pag_demas, Cod_cajero, Monto, 
					   Eliminado, Fch_ec, I_CtasDetTableRowID, I_CtasPagoProcTableRowID 
				  FROM #temp_det_obl
				 WHERE Nro_recibo = @Nro_recibo
					   AND Pagado = @Pagado
					   AND Fch_pago = @Fch_pago
					   AND Eliminado = @Eliminado

			OPEN Det_Cursor
			FETCH NEXT FROM Det_Cursor INTO @I_RowDetID, @Nro_recibo, @Fch_pago, @Id_lug_pag, @Pagado_det, @Pag_demas, @Cod_cajero, @Monto, 
											@Eliminado, @Fch_ec, @I_CtasDetID, @I_CtasProcID;

			WHILE @@FETCH_STATUS = 0
			BEGIN

				IF (@I_CtasProcID IS NULL)
				BEGIN 
					INSERT INTO BD_OCEF_CtasPorCobrar.dbo.TRI_PagoProcesadoUnfv(I_PagoBancoID, I_CtaDepositoID, I_TasaUnfvID, I_MontoPagado, I_SaldoAPagar, 
																				I_PagoDemas, B_PagoDemas, N_NroSIAF, B_Anulado,  D_FecCre, I_UsuarioCre, D_FecMod, 
																				I_UsuarioMod, I_ObligacionAluDetID, B_Migrado, I_MigracionTablaID, I_MigracionRowID)
																		VALUES (@I_CtasPagoBnc_RowID, @I_CtaDePID, NULL, @Monto, 0,
																				0, @Pag_demas, NULL, @Eliminado, @D_FecProceso, @I_UsuarioID, NULL, 
																				NULL, @I_CtasDetID, 1, @I_TablaID_Det, @I_RowDetID)

					SET @I_CtasPagoProc_RowID = SCOPE_IDENTITY()
					 SET @I_Det_Insertados = @I_Det_Insertados + 1
				END
				ELSE 
				BEGIN
					UPDATE BD_OCEF_CtasPorCobrar.dbo.TRI_PagoProcesadoUnfv
					   SET I_CtaDepositoID = @I_CtaDepID,
						   B_Anulado = @Eliminado,
						   D_FecMod = @D_FecProceso,
						   I_MontoPagado = @Monto,						   
						   B_Migrado = 1,
						   I_MigracionTablaID = @I_TablaID_Det,
						   I_MigracionRowID = @I_RowDetID
					 WHERE I_PagoProcesID = @I_CtasProcID

					 SET @I_CtasPagoProc_RowID = @I_CtasProcID
					 SET @I_Det_Actualizados = @I_Det_Actualizados + 1
				END

				UPDATE BD_OCEF_CtasPorCobrar.dbo.TR_ObligacionAluDet
					SET B_Pagado = @Pagado_det
				 WHERE I_ObligacionAluDetID = @I_CtasDetID

				UPDATE TR_Ec_Det 
				   SET D_FecMigradoPago = @D_FecProceso,
					   B_MigradoPago = 1,
					   I_CtasPagoProcTableRowID = @I_CtasPagoProc_RowID
				 WHERE I_RowID = @I_RowDetID



				FETCH NEXT FROM Det_Cursor INTO @I_RowDetID, @Nro_recibo, @Fch_pago, @Id_lug_pag, @Pagado_det, @Pag_demas, @Cod_cajero, @Monto, 
												@Eliminado, @Fch_ec, @I_CtasDetID, @I_CtasProcID;
			END

			CLOSE Det_Cursor
			DEALLOCATE Det_Cursor


			UPDATE BD_OCEF_CtasPorCobrar.dbo.TR_ObligacionAluCab
			   SET B_Pagado = (SELECT B_Pagado FROM TR_Ec_Obl O WHERE O.I_RowID = @I_OblRowID)
			 WHERE I_MigracionRowID = @I_OblRowID
				   AND I_MigracionTablaID = @I_TablaID_Obl


		COMMIT TRANSACTION
					
		SET @I_OblAluID = @I_CtasPagoBnc_RowID
		SET @B_Resultado = 1
		SET @T_Message = '[{ ' +
							 'Type: "summary", ' + 
							 'Title: "Pagos Banco Insertados", ' + 
							 'Value: ' + CAST(@I_Pagos_Insertados AS varchar) +
						  '}, ' + 
						  '{ ' +
							 'Type: "summary", ' + 
							 'Title: "Pagos Procesados Insertados", ' + 
							 'Value: ' + CAST(@I_Det_Insertados AS varchar) +
						  '}, ' + 
						  '{ ' +
							 'Type: "summary", ' + 
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