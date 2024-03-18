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
			@T_Anio		  varchar(4) = '2010',
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

		EXEC sp_executesql @T_SQL
		SET @I_Removidos = @@ROWCOUNT


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
							 'Value: ' + ERROR_MESSAGE() + ' (Linea: ' + CAST(ERROR_LINE() AS varchar(11)) + ').'  +
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
	    	@T_Anio		  varchar(4) = '2012',
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
	
		--1. Se actualiza pagos con ID de obligaci�n del mismo monto
		UPDATE det_pg
		   SET I_OblRowID = obl.I_RowID
		  FROM TR_Ec_Det_Pagos det_pg
			   INNER JOIN TR_Ec_Obl obl ON det_pg.I_ProcedenciaID = obl.I_ProcedenciaID
										   AND det_pg.Cuota_pago = obl.Cuota_pago
										   AND det_pg.Cod_alu = obl.Cod_alu
										   AND det_pg.Cod_rc = obl.Cod_rc
										   AND det_pg.P = obl.P
										   AND det_pg.Fch_venc = obl.Fch_venc
										   AND det_pg.Monto = obl.Monto
		 WHERE det_pg.Ano = @T_Anio
			   AND det_pg.I_ProcedenciaID = @I_ProcedenciaID

		SET @I_Actualizados = @@ROWCOUNT
		--2. Se actualiza pagos por mora con ID de obligaci�n pagada con el mismo n�mero de recibo

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
							 'Value: ' + ERROR_MESSAGE() + ' (Linea: ' + CAST(ERROR_LINE() AS varchar(11)) + ').'  +
						  '}]' 
	END CATCH
END
GO



/*	
	===============================================================================================
		Inicializar par�metros para validaciones de tablas ec_obl y ec_det segun procedencia	
	===============================================================================================
*/ 


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_Obligaciones_Pagos_MigracionTP_U_InicializarEstadoValidacion')
	DROP PROCEDURE [dbo].[USP_Obligaciones_Pagos_MigracionTP_U_InicializarEstadoValidacion]
GO

CREATE PROCEDURE USP_Obligaciones_Pagos_MigracionTP_U_InicializarEstadoValidacion	
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
  exec USP_Obligaciones_ObligacionCab_MigracionTP_U_InicializarEstadoValidacion @I_ProcedenciaID, @I_Anio, @B_Resultado output, @T_Message output
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
				   AND Ano = CAST(@I_Anio as varchar)
		)


		UPDATE	det
		   SET	B_Actualizado = IIF(B_Actualizado = 1, B_Actualizado, 0), 
				B_Migrable = 1, 
				D_FecMigrado = NULL, 
				B_Migrado = 0
		  FROM  TR_Ec_Det_Pagos det 
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



/*	
	===============================================================================================
		Validaciones de tablas ec_obl y ec_det segun procedencia y a�o	
	===============================================================================================
*/ 

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_Obligaciones_Pagos_MigracionTP_U_Validar_52_SinObligacionID')
	DROP PROCEDURE [dbo].[USP_Obligaciones_Pagos_MigracionTP_U_Validar_52_SinObligacionID]
GO

CREATE PROCEDURE USP_Obligaciones_Pagos_MigracionTP_U_Validar_52_SinObligacionID	
	@I_ProcedenciaID tinyint,
	@I_Anio	      smallint,
	@B_Resultado  bit output,
	@T_Message	  nvarchar(4000) OUTPUT	
AS
/*
  declare	@B_Resultado  bit,
			@I_ProcedenciaID	tinyint = 3,
	    	@I_Anio  	  smallint = 2012,
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
			   AND Ano = CAST(@I_Anio as varchar(4))

		SET @T_Message = CAST(@@ROWCOUNT AS varchar)

		 
		MERGE TI_ObservacionRegistroTabla AS TRG
		USING (SELECT @I_ObservID_sinOblId AS I_ObservID, @I_TablaID AS I_TablaID, I_RowID AS I_FilaTablaID, @D_FecProceso AS D_FecRegistro 
				 FROM TR_Ec_Det_Pagos 
				WHERE I_OblRowID IS NULL
					  AND I_ProcedenciaID = @I_ProcedenciaID
					  AND Ano = CAST(@I_Anio as varchar(4))
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
															   AND Ano = CAST(@I_Anio as varchar(4))) DPG 
						  ON OBS.I_FilaTablaID = DPG.I_RowID
							 AND OBS.I_ProcedenciaID = DPG.I_ProcedenciaID
		 WHERE OBS.I_ObservID = @I_ObservID_sinOblId 
			   AND OBS.I_TablaID = @I_TablaID
			   AND OBS.I_FilaTablaID = DPG.I_RowID

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
			   

		SET @T_Message = CAST(@@ROWCOUNT AS varchar)

		 
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

		SET @T_Message = CAST(@@ROWCOUNT AS varchar)

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
							 'Value: ' + ERROR_MESSAGE() + ' (Linea: ' + CAST(ERROR_LINE() AS varchar(11)) + ').'  +
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

		SET @T_Message = CAST(@@ROWCOUNT AS varchar)


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
							 'Value: ' + ERROR_MESSAGE() + ' (Linea: ' + CAST(ERROR_LINE() AS varchar(11)) + ').'  +
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

		SET @T_Message = CAST(@@ROWCOUNT AS varchar)

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
							 'Value: ' + ERROR_MESSAGE() + ' (Linea: ' + CAST(ERROR_LINE() AS varchar(11)) + ').'  +
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


		SET @T_Message = CAST(@@ROWCOUNT AS varchar)

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
							 'Value: ' + ERROR_MESSAGE() + ' (Linea: ' + CAST(ERROR_LINE() AS varchar(11)) + ').'  +
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
							 'Value: ' + ERROR_MESSAGE() + ' (Linea: ' + CAST(ERROR_LINE() AS varchar(11)) + ').'  +
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
							 'Value: ' + ERROR_MESSAGE() + ' (Linea: ' + CAST(ERROR_LINE() AS varchar(11)) + ').'  +
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
	declare @I_ProcedenciaID tinyint = 3,
			@T_Anio		 varchar(4) = '2010', 
			@B_Resultado  bit, 
			@T_Message nvarchar(4000)
	exec USP_Obligaciones_Pagos_MigracionTP_CtasPorCobrar_IU_MigrarDataPorAnio @I_ProcedenciaID, @T_Anio, @B_Resultado output, @T_Message output
	select @B_Resultado as resultado, @T_Message as mensaje
*/
BEGIN
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
							 'Value: ' + ERROR_MESSAGE() + ' (Linea: ' + CAST(ERROR_LINE() AS varchar(11)) + ').'  +
						  '}]' 
	END CATCH
END
GO