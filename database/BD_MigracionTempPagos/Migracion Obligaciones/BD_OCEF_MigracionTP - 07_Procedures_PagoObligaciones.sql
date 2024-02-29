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
	@T_Anio		  varchar(4) = NULL,
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
												'AND TR_Ec_Obl.Ano = ' + @T_Anio + ' ' +
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
		Inicializar parámetros para validaciones de tablas ec_obl y ec_det segun procedencia	
	===============================================================================================
*/ 


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_Obligaciones_Pagos_MigracionTP_U_InicializarEstadoValidacion')
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

