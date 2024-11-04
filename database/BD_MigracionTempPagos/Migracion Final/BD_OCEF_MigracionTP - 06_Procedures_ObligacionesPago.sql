/*
==================================================================
	BD_OCEF_MigracionTP - 06_Procedures_ObligacionesPago
==================================================================
*/


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
	DECLARE @I_ProcedenciaID	tinyint = 1,
			@T_SchemaDB   varchar(20) = 'pregrado',
			@T_Anio		  varchar(4) = '2010',
			@B_Resultado  bit,
			@T_Message	  nvarchar(4000)
	EXEC USP_Obligaciones_ObligacionCab_TemporalPagos_MigracionTP_IU_CopiarTabla @I_ProcedenciaID, @T_SchemaDB, @T_Anio, 
																		 @B_Resultado output, @T_Message output
	SELECT @B_Resultado as resultado, @T_Message as mensaje
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
		SET @T_SQL = 'DELETE TR_Ec_Det_Pagos ' + CHAR(13) +
					 ' WHERE Ano = ''' + @T_Anio + ''' ' + CHAR(13) +
							'AND B_Migrado = 0 ' + CHAR(13) +
							'AND I_ProcedenciaID = '+ CAST(@I_ProcedenciaID as varchar(3)) + ';'

		PRINT @T_SQL
		EXEC sp_executesql @T_SQL


		SET @T_SQL = 'DELETE TR_Ec_Det ' + CHAR(13) +
					  'WHERE Ano = ''' + @T_Anio + ''' ' + CHAR(13) +
							'AND B_Migrado = 0 ' + CHAR(13) +
							'AND I_ProcedenciaID = '+ CAST(@I_ProcedenciaID as varchar(3)) + ';'

		PRINT @T_SQL
		EXEC sp_executesql @T_SQL

		DELETE TI_ObservacionRegistroTabla 				
		 WHERE I_TablaID = 4 
			   AND I_ProcedenciaID = @I_ProcedenciaID
			   AND NOT EXISTS (SELECT I_RowID 
								 FROM TR_Ec_Det 
								WHERE I_RowID = I_FilaTablaID AND Ano = @T_Anio);


		SET @T_SQL = 'DELETE TR_Ec_Obl ' +  CHAR(13) +
					  'WHERE I_ProcedenciaID = '+ CAST(@I_ProcedenciaID as varchar(3)) + ' ' +  CHAR(13) +
							'AND TR_Ec_Obl.Ano = ''' + @T_Anio + ''' ' +  CHAR(13) +
							'AND TR_Ec_Obl.B_Migrado = 0;'

		PRINT @T_SQL
		EXEC sp_executesql @T_SQL

		DELETE FROM TI_ObservacionRegistroTabla 
			  WHERE	I_TablaID = 5  
					AND I_ProcedenciaID = @I_ProcedenciaID
					AND NOT EXISTS (SELECT I_RowID 
									  FROM TR_Ec_Det 
									 WHERE I_RowID = I_FilaTablaID AND Ano = @T_Anio);


		SET @T_SQL = 'DECLARE @D_FecProceso datetime = GETDATE(); ' + CHAR(10) + CHAR(13) +
					  'INSERT TR_Ec_Obl (Ano, P, I_Periodo, Cod_alu, Cod_rc, Cuota_pago, Tipo_oblig, Fch_venc, Monto, Pagado, ' + CHAR(13) +
										'D_FecCarga, B_Migrable, B_Migrado, I_ProcedenciaID, B_Obligacion) ' + CHAR(13) +
								 'SELECT ano, p, I_OpcionID as I_periodo, cod_alu, cod_rc, cuota_pago, tipo_oblig, fch_venc, monto, pagado, ' + CHAR(13) +
										'@D_FecProceso, 1, 0, ' + CAST(@I_ProcedenciaID as varchar(3)) + ', 1 ' + CHAR(13) +
								   'FROM BD_OCEF_TemporalPagos.' + @T_SchemaDB + '.ec_obl OBL ' + CHAR(13) +
								 		'LEFT JOIN BD_OCEF_CtasPorCobrar.dbo.TC_CatalogoOpcion cop_per ON OBL.P = cop_per.T_OpcionCod AND cop_per.I_ParametroID = 5 ' + CHAR(13) +
								  'WHERE NOT EXISTS (SELECT I_RowID FROM TR_Ec_Obl TRG ' + CHAR(13) +
								 					'WHERE TRG.Ano = OBL.Ano AND TRG.P = OBL.p AND TRG.Cod_alu = OBL.cod_alu  ' + CHAR(13) +
														  'AND TRG.Cod_rc = OBL.cod_rc AND TRG.Cuota_pago = OBL.cuota_pago ' + CHAR(13) +
								 						  'AND ISNULL(TRG.Fch_venc, ''19000101'') = ISNULL(OBL.fch_venc, ''19000101'') ' + CHAR(13) +
								 						  'AND ISNULL(TRG.Tipo_oblig, 0) = ISNULL(OBL.tipo_oblig, 0) AND TRG.Monto = OBL.monto ' + CHAR(13) +
								 						  'AND TRG.Pagado = OBL.pagado AND TRG.I_ProcedenciaID = '+ CAST(@I_ProcedenciaID as varchar(3)) + ') ' + CHAR(13) +
								 	   'AND OBL.ano = ''' + @T_Anio + ''';'

		PRINT @T_SQL
		EXEC sp_executesql @T_SQL
		SET @I_Insertados = @@ROWCOUNT

		SET @T_SQL = 'SELECT * FROM BD_OCEF_TemporalPagos.' + @T_SchemaDB + '.ec_obl WHERE Ano = ''' + @T_Anio + ''';'

		PRINT @T_SQL
		EXEC sp_executesql @T_SQL
		SET @I_EcObl = @@ROWCOUNT

		IF(@I_Removidos <> 0)
		BEGIN
			SET @I_Actualizados = @I_Insertados
		END

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

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_Obligaciones_ObligacionDet_MigracionTP_U_AsignarObligacionIdDetalleId')
	DROP PROCEDURE [dbo].[USP_Obligaciones_ObligacionDet_MigracionTP_U_AsignarObligacionIdDetalleId]
GO

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
	DECLARE @I_ProcedenciaID	tinyint = 1,
			@T_Anio		  varchar(4) = '2010',
			@B_Resultado  bit,
			@T_Message	  nvarchar(4000)
	EXEC USP_Obligaciones_ObligacionDet_MigracionTP_U_AsignarObligacionCabID @I_ProcedenciaID, @T_Anio, @B_Resultado output, @T_Message output
	SELECT @B_Resultado as resultado, @T_Message as mensaje
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
	DECLARE @I_ProcedenciaID	tinyint = 1,
			@T_Anio		  varchar(4) = '2010',
			@B_Resultado  bit,
			@T_Message	  nvarchar(4000)
	EXEC USP_Obligaciones_ObligacionCab_MigracionTP_U_InicializarEstadoValidacion @I_ProcedenciaID, @T_Anio, 
																		 @B_Resultado output, @T_Message output
	SELECT @B_Resultado as resultado, @T_Message as mensaje
*/
BEGIN
	DECLARE @I_TablaID INT = 5
	DECLARE @I_FilaTablaID INT = (SELECT MAX(I_FilaTablaID) FROM TI_ObservacionRegistroTabla)

	BEGIN TRANSACTION
	BEGIN TRY 
		DELETE TI_ObservacionRegistroTabla
		 WHERE I_TablaID = @I_TablaID
		 	   AND I_ProcedenciaID = @I_ProcedenciaID
		 	   AND EXISTS (SELECT I_RowID FROM TR_Ec_Obl OBL
							WHERE OBL.I_ProcedenciaID = TI_ObservacionRegistroTabla.I_ProcedenciaID
								  AND OBL.I_RowID = TI_ObservacionRegistroTabla.I_FilaTablaID
								  AND Ano = @T_Anio)

		DBCC CHECKIDENT('TI_ObservacionRegistroTabla', 'RESEED', @I_FilaTablaID)

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
	DECLARE @I_RowID  	  int,
			@B_Resultado  bit,
			@T_Message	  nvarchar(4000)
	EXEC USP_Obligaciones_ObligacionCab_MigracionTP_U_InicializarEstadoValidacionPorID @I_RowID, @B_Resultado output, @T_Message output
	SELECT @B_Resultado as resultado, @T_Message as mensaje
*/
BEGIN
	DECLARE @I_TablaID INT = 5
	DECLARE @I_FilaTablaID INT = (SELECT MAX(I_FilaTablaID) FROM TI_ObservacionRegistroTabla)
	BEGIN TRANSACTION
	BEGIN TRY 
		DELETE TI_ObservacionRegistroTabla
		 WHERE I_TablaID = @I_TablaID
		 	   AND I_FilaTablaID = @I_RowID

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
	DECLARE @I_ProcedenciaID	tinyint = 1,
			@T_Anio		  varchar(4) = '2010',
			@B_Resultado  bit,
			@T_Message	  nvarchar(4000)
	EXEC USP_Obligaciones_ObligacionDet_MigracionTP_U_InicializarEstadoValidacion @I_ProcedenciaID, @T_Anio, 
																		 @B_Resultado output, @T_Message output
	SELECT @B_Resultado as resultado, @T_Message as mensaje
*/
BEGIN
	DECLARE @I_TablaID INT = 4
	DECLARE @I_FilaTablaID INT = (SELECT MAX(I_FilaTablaID) FROM TI_ObservacionRegistroTabla)

	BEGIN TRANSACTION
	BEGIN TRY
		DELETE TI_ObservacionRegistroTabla
		 WHERE I_TablaID = @I_TablaID
		 	   AND I_ProcedenciaID = @I_ProcedenciaID
		 	   AND EXISTS (SELECT I_RowID FROM TR_Ec_Det DET
							WHERE DET.I_ProcedenciaID = TI_ObservacionRegistroTabla.I_ProcedenciaID
								  AND DET.I_RowID = TI_ObservacionRegistroTabla.I_FilaTablaID
								  AND Ano = @T_Anio)

		DBCC CHECKIDENT('TI_ObservacionRegistroTabla', 'RESEED', @I_FilaTablaID);


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
	DECLARE @I_RowID  	  int,
			@B_Resultado  bit,
			@T_Message	  nvarchar(4000)
	EXEC USP_Obligaciones_ObligacionDet_MigracionTP_U_InicializarEstadoValidacionPorID @I_RowID, @B_Resultado output, @T_Message output
	SELECT @B_Resultado as resultado, @T_Message as mensaje
*/
BEGIN
	DECLARE @I_TablaID INT = 5
	DECLARE @I_FilaTablaID INT = (SELECT MAX(I_FilaTablaID) FROM TI_ObservacionRegistroTabla)

	BEGIN TRANSACTION
	BEGIN TRY 
		DELETE TI_ObservacionRegistroTabla
		 WHERE I_TablaID = @I_TablaID
		 	   AND EXISTS (SELECT I_RowID FROM TR_Ec_Det Det
							WHERE Det.I_ProcedenciaID = TI_ObservacionRegistroTabla.I_ProcedenciaID
								  AND Det.I_RowID = TI_ObservacionRegistroTabla.I_FilaTablaID
								  AND Det.I_OblRowID = @I_OblRowID)


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
		Validaciones para migracion de ec_obl (solo obligaciones de pago)	
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
	DESCRIPCION: Marcar TR_Ec_Obl con B_Migrable = 0 cuando cod_alu no existe en la lista alumno migrada o en la base de datos de repositorio
				 para el año y procedencia

	DECLARE @I_ProcedenciaID	tinyint = 1,
			@T_Anio		  varchar(4) = '2010',
			@B_Resultado  bit,
			@T_Message	  nvarchar(4000)
	EXEC USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_24_ExisteAlumno @I_ProcedenciaID, @T_Anio, @B_Resultado output, @T_Message output
	SELECT @B_Resultado as resultado, @T_Message as mensaje
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
				LEFT JOIN BD_UNFV_Repositorio.dbo.TC_Alumno ec_alu ON ec_obl.Cod_alu = ec_alu.C_CodAlu 
																	  AND ec_obl.Cod_rc = ec_alu.C_RcCod
		WHERE	ec_alu.C_CodAlu IS NULL
				AND ec_obl.Ano = @T_Anio
			    AND ec_obl.I_ProcedenciaID = @I_ProcedenciaID


		MERGE   TI_ObservacionRegistroTabla AS TRG
		USING 	(SELECT	@I_ObservID AS I_ObservID, @I_TablaID AS I_TablaID, ec_obl.I_RowID AS I_FilaTablaID, 
						@D_FecProceso AS D_FecRegistro 
				   FROM	TR_Ec_Obl ec_obl
						LEFT JOIN BD_UNFV_Repositorio.dbo.TC_Alumno ec_alu ON ec_obl.Cod_alu = ec_alu.C_CodAlu 
																			  AND ec_obl.Cod_rc = ec_alu.C_RcCod
				  WHERE	ec_alu.C_CodAlu IS NULL
						AND ec_obl.Ano = @T_Anio
						AND ec_obl.I_ProcedenciaID = @I_ProcedenciaID
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
			   INNER JOIN (SELECT ec_obl.I_RowID, ec_obl.Ano, ec_obl.Cod_alu, ec_obl.Cod_rc, ec_obl.I_ProcedenciaID, ec_alu.C_CodAlu   
							 FROM TR_Ec_Obl ec_obl
								  LEFT JOIN BD_UNFV_Repositorio.dbo.TC_Alumno ec_alu ON ec_obl.Cod_alu = ec_alu.C_CodAlu 
								  														AND ec_obl.Cod_rc = ec_alu.C_RcCod
							WHERE ec_alu.C_CodAlu IS NOT NULL
								  AND ec_obl.Ano = @T_Anio
								  AND ec_obl.I_ProcedenciaID = @I_ProcedenciaID) OBL 
						  ON OBS.I_FilaTablaID = OBL.I_RowID
							 AND OBS.I_ProcedenciaID = OBL.I_ProcedenciaID
		 WHERE OBS.I_ObservID = @I_ObservID 
			   AND OBS.I_TablaID = @I_TablaID

		
		SET @I_Observados = (SELECT COUNT(*) 
							   FROM (SELECT * FROM TR_Ec_Obl WHERE Ano = @T_Anio AND I_ProcedenciaID = @I_ProcedenciaID) OBL
									INNER JOIN (SELECT * FROM TI_ObservacionRegistroTabla WHERE I_ObservID = @I_ObservID AND I_TablaID = @I_TablaID) OBS 
											   ON OBS.I_FilaTablaID = OBL.I_RowID AND OBS.I_ProcedenciaID = OBL.I_ProcedenciaID
							 WHERE  B_Resuelto = 0)
				
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
		IF (@@TRANCOUNT > 0) 
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


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_24_ExisteAlumnoPorOblID')
	DROP PROCEDURE [dbo].[USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_24_ExisteAlumnoPorOblID]
GO

CREATE PROCEDURE [dbo].[USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_24_ExisteAlumnoPorOblID]	
	@I_RowID	  int = NULL,
	@B_Resultado  bit output,
	@T_Message	  nvarchar(4000) OUTPUT	
AS
/*
	DESCRIPCION: Marcar TR_Ec_Obl con B_Migrable = 0 cuando cod_alu no existe en la lista alumno migrada o en la base de datos de repositorio
				 para el I_RowID de la obligacion

	DECLARE @I_RowID	  int = 5013,
			@B_Resultado  bit,
			@T_Message	  nvarchar(4000)
	EXEC USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_24_ExisteAlumnoPorOblID @I_ProcedenciaID, @I_RowID, @B_Resultado output, @T_Message output
	SELECT @B_Resultado as resultado, @T_Message as mensaje
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
				LEFT JOIN BD_UNFV_Repositorio.dbo.TC_Alumno ec_alu ON ec_obl.Cod_alu = ec_alu.C_CodAlu 
																	  AND ec_obl.Cod_rc = ec_alu.C_RcCod
		WHERE	ec_alu.C_CodAlu IS NULL
				AND ec_obl.I_RowID = @I_RowID


		MERGE   TI_ObservacionRegistroTabla AS TRG
		USING 	(SELECT	@I_ObservID AS I_ObservID, @I_TablaID AS I_TablaID, ec_obl.I_RowID AS I_FilaTablaID, 
						@D_FecProceso AS D_FecRegistro, ec_obl.I_ProcedenciaID
				   FROM	TR_Ec_Obl ec_obl
						LEFT JOIN BD_UNFV_Repositorio.dbo.TC_Alumno ec_alu ON ec_obl.Cod_alu = ec_alu.C_CodAlu 
																			  AND ec_obl.Cod_rc = ec_alu.C_RcCod
				  WHERE	ec_alu.C_CodAlu IS NULL
						AND ec_obl.I_RowID = @I_RowID
				) AS SRC
		ON TRG.I_ObservID = SRC.I_ObservID AND TRG.I_TablaID = SRC.I_TablaID AND TRG.I_FilaTablaID = SRC.I_FilaTablaID
		WHEN MATCHED THEN
			UPDATE SET D_FecRegistro = SRC.D_FecRegistro, 
					   B_Resuelto = 0
		WHEN NOT MATCHED BY TARGET THEN
			INSERT (I_ObservID, I_TablaID, I_FilaTablaID, D_FecRegistro, I_ProcedenciaID, B_ObligProc)
			VALUES (SRC.I_ObservID, SRC.I_TablaID, SRC.I_FilaTablaID, SRC.D_FecRegistro, SRC.I_ProcedenciaID, 1);


		UPDATE OBS
		   SET D_FecResuelto = @D_FecProceso,
			   B_Resuelto = 1
		  FROM TI_ObservacionRegistroTabla OBS
			   INNER JOIN (SELECT ec_obl.I_RowID, ec_obl.Ano, ec_obl.Cod_alu, ec_obl.Cod_rc, ec_obl.I_ProcedenciaID, ec_alu.C_CodAlu   
							 FROM TR_Ec_Obl ec_obl
								  LEFT JOIN BD_UNFV_Repositorio.dbo.TC_Alumno ec_alu ON ec_obl.Cod_alu = ec_alu.C_CodAlu 
								  														AND ec_obl.Cod_rc = ec_alu.C_RcCod
							WHERE ec_alu.C_CodAlu IS NOT NULL
								  AND ec_obl.I_RowID = @I_RowID) OBL 
						  ON OBS.I_FilaTablaID = OBL.I_RowID
		 WHERE OBS.I_ObservID = @I_ObservID 
			   AND OBS.I_TablaID = @I_TablaID

		
		SET @I_Observados = (SELECT COUNT(*) 
							   FROM (SELECT * FROM TR_Ec_Obl WHERE I_RowID = @I_RowID) OBL
									INNER JOIN (SELECT * FROM TI_ObservacionRegistroTabla WHERE I_ObservID = @I_ObservID AND I_TablaID = @I_TablaID) OBS 
											   ON OBS.I_FilaTablaID = OBL.I_RowID AND OBS.I_ProcedenciaID = OBL.I_ProcedenciaID
							  WHERE B_Resuelto = 0)

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
		IF (@@TRANCOUNT > 0) 
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


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_U_ValidarAnioEnCabeceraObligacion')
	DROP PROCEDURE [dbo].[USP_U_ValidarAnioEnCabeceraObligacion]
GO

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_U_ValidarAnioEnDetalleObligacion')
	DROP PROCEDURE [dbo].[USP_U_ValidarAnioEnDetalleObligacion]
GO

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_26_AnioNumerico')
	DROP PROCEDURE [dbo].[USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_26_AnioNumerico]
GO

CREATE PROCEDURE [dbo].[USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_26_AnioNumerico]	
	@I_ProcedenciaID tinyint,
	@B_Resultado  bit output,
	@T_Message	  nvarchar(4000) OUTPUT	
AS
/*
	DESCRIPCION: Marcar TR_Ec_Obl con B_Migrable = 0 cuando no existe un valor válido de año para la procedencia de la obligacion

	DECLARE @I_ProcedenciaID	tinyint = 1, 
			@B_Resultado  bit,
			@T_Message	  nvarchar(4000)
	EXEC USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_26_AnioNumerico @I_ProcedenciaID, @B_Resultado output, @T_Message output
	SELECT @B_Resultado as resultado, @T_Message as mensaje
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


		MERGE TI_ObservacionRegistroTabla AS TRG
		USING 	(SELECT	@I_ObservID AS I_ObservID, @I_TablaID AS I_TablaID, I_RowID AS I_FilaTablaID, @D_FecProceso AS D_FecRegistro 
				   FROM	TR_Ec_Obl 
				  WHERE	ISNUMERIC(Ano) = 0 
						AND I_ProcedenciaID = @I_ProcedenciaID
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
			   INNER JOIN (SELECT I_RowID, I_ProcedenciaID FROM TR_Ec_Obl WHERE ISNUMERIC(Ano) = 1) OBL
						   ON OBS.I_FilaTablaID = OBL.I_RowID
							  AND OBS.I_ProcedenciaID = OBL.I_ProcedenciaID
		 WHERE OBS.I_ObservID = @I_ObservID 
			   AND OBS.I_TablaID = @I_TablaID

		SET @I_Observados = (SELECT COUNT(*) FROM TI_ObservacionRegistroTabla 
											WHERE I_ObservID = @I_ObservID 
												  AND I_TablaID = @I_TablaID
												  AND I_ProcedenciaID = @I_ProcedenciaID
												  AND B_Resuelto = 0) 

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
		IF (@@TRANCOUNT > 0) 
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



IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_26_AnioNumericoPorOblID')
	DROP PROCEDURE [dbo].[USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_26_AnioNumericoPorOblID]
GO

CREATE PROCEDURE [dbo].[USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_26_AnioNumericoPorOblID]	
	@I_RowID	  int,
	@B_Resultado  bit output,
	@T_Message	  nvarchar(4000) OUTPUT	
AS
/*
	DESCRIPCION: Marcar TR_Ec_Obl con B_Migrable = 0 cuando no existe un valor válido de año para el ID de la obligacion

	DECLARE @I_RowID	  int = 22553,
			@B_Resultado  bit,
			@T_Message	  nvarchar(4000)
	EXEC USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_26_AnioNumericoPorOblID @I_RowID, @B_Resultado output, @T_Message output
	SELECT @B_Resultado as resultado, @T_Message as mensaje
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
				AND I_RowID = @I_RowID


		MERGE TI_ObservacionRegistroTabla AS TRG
		USING 	(SELECT	@I_ObservID AS I_ObservID, @I_TablaID AS I_TablaID, I_RowID AS I_FilaTablaID, I_ProcedenciaID, @D_FecProceso AS D_FecRegistro 
				   FROM	TR_Ec_Obl 
				  WHERE	ISNUMERIC(Ano) = 0 
						AND I_RowID = @I_RowID
				) AS SRC
		ON TRG.I_ObservID = SRC.I_ObservID AND TRG.I_TablaID = SRC.I_TablaID AND TRG.I_FilaTablaID = SRC.I_FilaTablaID
		WHEN MATCHED THEN
			UPDATE SET D_FecRegistro = SRC.D_FecRegistro, 
					   B_Resuelto = 0
		WHEN NOT MATCHED BY TARGET THEN
			INSERT (I_ObservID, I_TablaID, I_FilaTablaID, D_FecRegistro, I_ProcedenciaID, B_ObligProc)
			VALUES (SRC.I_ObservID, SRC.I_TablaID, SRC.I_FilaTablaID, SRC.D_FecRegistro, SRC.I_ProcedenciaID, 1);


		UPDATE OBS
		   SET D_FecResuelto = @D_FecProceso,
			   B_Resuelto = 1
		  FROM TI_ObservacionRegistroTabla OBS
			   INNER JOIN (SELECT I_RowID, I_ProcedenciaID FROM TR_Ec_Obl WHERE ISNUMERIC(Ano) = 1) OBL
						   ON OBS.I_FilaTablaID = OBL.I_RowID
							  AND OBS.I_ProcedenciaID = OBL.I_ProcedenciaID
		 WHERE OBS.I_ObservID = @I_ObservID 
			   AND OBS.I_TablaID = @I_TablaID

		SET @I_Observados = (SELECT COUNT(*) FROM TI_ObservacionRegistroTabla 
											WHERE I_ObservID = @I_ObservID AND I_TablaID = @I_TablaID
												  AND I_FilaTablaID = @I_RowID
												  AND B_Resuelto = 0) 

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

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_U_ValidarPeriodoEnDetalleObligacion')
	DROP PROCEDURE [dbo].[USP_U_ValidarPeriodoEnDetalleObligacion]
GO

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_27_Periodo')
	DROP PROCEDURE [dbo].[USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_27_Periodo]
GO

CREATE PROCEDURE [dbo].[USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_27_Periodo]	
	@I_ProcedenciaID tinyint,
	@T_Anio		  varchar(4) = NULL,
	@B_Resultado  bit output,
	@T_Message	  nvarchar(4000) OUTPUT	
AS
/*
	DESCRIPCION: Marcar TR_Ec_Obl con B_Migrable = 0 cuando no existe un valor válido para periodo para la procedencia y año de la obligacion 

	DECLARE	@I_ProcedenciaID	tinyint = 1, 
			@T_Anio		  varchar(4) = '2010',
			@B_Resultado  bit,
			@T_Message	  nvarchar(4000)
	EXEC USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_27_Periodo @I_ProcedenciaID, @T_Anio, @B_Resultado output, @T_Message output
	SELECT @B_Resultado as resultado, @T_Message as mensaje
*/
BEGIN
	DECLARE @I_Observados int = 0
	DECLARE @I_TablaID int = 5
	DECLARE @D_FecProceso datetime = GETDATE() 
	DECLARE @I_ObservID int = 27


	BEGIN TRANSACTION
	BEGIN TRY 
			
		UPDATE	TR_Ec_Obl
		SET		B_Migrable = 0,
				D_FecEvalua = @D_FecProceso
		WHERE	I_Periodo IS NULL OR P = ''
				AND I_ProcedenciaID = @I_ProcedenciaID
			    AND Ano = @T_Anio

		MERGE TI_ObservacionRegistroTabla AS TRG
		USING 	(SELECT	@I_ObservID AS I_ObservID, @I_TablaID AS I_TablaID, I_RowID AS I_FilaTablaID, @D_FecProceso AS D_FecRegistro, I_ProcedenciaID
				   FROM TR_Ec_Obl
				  WHERE	I_Periodo IS NULL OR P = ''
						AND I_ProcedenciaID = @I_ProcedenciaID
						AND Ano = @T_Anio
				) AS SRC
		ON TRG.I_ObservID = SRC.I_ObservID AND TRG.I_TablaID = SRC.I_TablaID AND TRG.I_FilaTablaID = SRC.I_FilaTablaID
		WHEN MATCHED AND TRG.I_ProcedenciaID = @I_ProcedenciaID THEN
			UPDATE SET D_FecRegistro = SRC.D_FecRegistro, 
					   B_Resuelto = 0
		WHEN NOT MATCHED BY TARGET THEN
			INSERT (I_ObservID, I_TablaID, I_FilaTablaID, D_FecRegistro, I_ProcedenciaID, B_ObligProc)
			VALUES (SRC.I_ObservID, SRC.I_TablaID, SRC.I_FilaTablaID, SRC.D_FecRegistro, @I_ProcedenciaID, 1);


		UPDATE OBS
		   SET D_FecResuelto = @D_FecProceso,
			   B_Resuelto = 1
		  FROM TI_ObservacionRegistroTabla OBS
			   INNER JOIN (SELECT * FROM TR_Ec_Obl 
							WHERE I_Periodo IS NOT NULL AND P <> ''
								  AND Ano = @T_Anio
								  AND I_ProcedenciaID = @I_ProcedenciaID
						  ) OBL 
						  ON OBS.I_FilaTablaID = OBL.I_RowID
							 AND OBS.I_ProcedenciaID = OBL.I_ProcedenciaID
		 WHERE OBS.I_ObservID = @I_ObservID 
			   AND OBS.I_TablaID = @I_TablaID
			

		SET @I_Observados = (SELECT COUNT(*) FROM (SELECT * FROM TR_Ec_Obl WHERE Ano = @T_Anio AND I_ProcedenciaID = @I_ProcedenciaID) OBL
												  INNER JOIN TI_ObservacionRegistroTabla OBS ON OBS.I_FilaTablaID = OBL.I_RowID
																								AND OBS.I_ProcedenciaID = OBL.I_ProcedenciaID
							 WHERE I_ObservID = @I_ObservID AND I_TablaID = @I_TablaID 
								   AND OBS.I_ProcedenciaID = @I_ProcedenciaID
								   AND B_Resuelto = 0)

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
		IF (@@TRANCOUNT > 0) 
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


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_27_PeriodoPorOblID')
	DROP PROCEDURE [dbo].[USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_27_PeriodoPorOblID]
GO

CREATE PROCEDURE [dbo].[USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_27_PeriodoPorOblID]	
	@I_RowID	  int,
	@B_Resultado  bit output,
	@T_Message	  nvarchar(4000) OUTPUT	
AS
/*
	DESCRIPCION: Marcar TR_Ec_Obl con B_Migrable = 0 cuando no existe un valor válido para periodo para el ID de la obligacion 

	DECLARE	@I_RowID		  int = 5013,
			@B_Resultado  bit,
			@T_Message	  nvarchar(4000)
	EXEC USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_27_PeriodoPorOblID @I_RowID, @B_Resultado output, @T_Message output
	SELECT @B_Resultado as resultado, @T_Message as mensaje
*/
BEGIN
	DECLARE @I_Observados int = 0
	DECLARE @I_TablaID int = 5
	DECLARE @D_FecProceso datetime = GETDATE() 
	DECLARE @I_ObservID int = 27

	BEGIN TRANSACTION
	BEGIN TRY 

		UPDATE	TR_Ec_Obl
		SET		B_Migrable = 0,
				D_FecEvalua = @D_FecProceso
		WHERE	I_Periodo IS NULL OR P = ''
				AND I_RowID = @I_RowID
				

		MERGE TI_ObservacionRegistroTabla AS TRG
		USING 	(SELECT	@I_ObservID AS I_ObservID, @I_TablaID AS I_TablaID, I_RowID AS I_FilaTablaID, @D_FecProceso AS D_FecRegistro, I_ProcedenciaID
				   FROM TR_Ec_Obl
				  WHERE	I_Periodo IS NULL OR P = ''
						AND I_RowID = @I_RowID
				) AS SRC
		ON TRG.I_ObservID = SRC.I_ObservID AND TRG.I_TablaID = SRC.I_TablaID AND TRG.I_FilaTablaID = SRC.I_FilaTablaID AND SRC.I_ProcedenciaID = TRG.I_ProcedenciaID
		WHEN MATCHED THEN
			UPDATE SET D_FecRegistro = SRC.D_FecRegistro, 
					   B_Resuelto = 0
		WHEN NOT MATCHED BY TARGET THEN
			INSERT (I_ObservID, I_TablaID, I_FilaTablaID, D_FecRegistro, I_ProcedenciaID, B_ObligProc)
			VALUES (SRC.I_ObservID, SRC.I_TablaID, SRC.I_FilaTablaID, SRC.D_FecRegistro, SRC.I_ProcedenciaID, 1);


		UPDATE OBS
		   SET D_FecResuelto = @D_FecProceso,
			   B_Resuelto = 1
		  FROM TI_ObservacionRegistroTabla OBS
			   INNER JOIN (SELECT * FROM TR_Ec_Obl 
							WHERE I_Periodo IS NOT NULL AND P <> ''
								  AND I_RowID = @I_RowID
						  ) OBL 
						  ON OBS.I_FilaTablaID = OBL.I_RowID
							 AND OBS.I_ProcedenciaID = OBL.I_ProcedenciaID
		 WHERE OBS.I_ObservID = @I_ObservID 
			   AND OBS.I_TablaID = @I_TablaID
			

		SET @I_Observados = (SELECT COUNT(*) FROM (SELECT * FROM TR_Ec_Obl WHERE I_RowID = @I_RowID) OBL
												  INNER JOIN TI_ObservacionRegistroTabla OBS ON OBS.I_FilaTablaID = OBL.I_RowID
																								AND OBS.I_ProcedenciaID = OBL.I_ProcedenciaID
							 WHERE I_ObservID = @I_ObservID AND I_TablaID = @I_TablaID 
								   AND I_FilaTablaID = @I_RowID
								   AND B_Resuelto = 0)

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
		IF (@@TRANCOUNT > 0) 
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
	DESCRIPCION: Marcar TR_Ec_Obl con B_Migrable = 0 cuando la fecha de vencimiento es diferente a la fecha de vencimiento de la cuota de pago para el año y procedencia

	DECLARE	@I_ProcedenciaID	tinyint = 1, 
			@T_Anio				varchar(4) = 2010,
			@B_Resultado		bit,
			@T_Message			nvarchar(4000)
	EXEC USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_28_FechaVencimientoCuota @I_ProcedenciaID, @T_Anio, @B_Resultado output, @T_Message output
	SELECT @B_Resultado as resultado, @T_Message as mensaje
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
		WHERE	ISNULL(TRG_1.B_Correcto, 0) = 0


		MERGE TI_ObservacionRegistroTabla AS TRG
		USING (SELECT @I_ObservID AS I_ObservID, @I_TablaID AS I_TablaID, TRG_1.I_RowID AS I_FilaTablaID, @D_FecProceso AS D_FecRegistro 
				 FROM TR_Ec_Obl TRG_1
					  INNER JOIN #temp_obl_fecVenc_dif_cuota_anio SRC_1 
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
			   INNER JOIN (SELECT ec_obl.I_RowID, ec_obl.Ano, ec_obl.Cod_alu, ec_obl.Cod_rc, ec_obl.I_ProcedenciaID
							 FROM TR_Ec_Obl ec_obl
								  LEFT JOIN #temp_obl_fecVenc_dif_cuota_anio SRC_1 ON ec_obl.I_RowID = SRC_1.I_RowID
							WHERE SRC_1.I_RowID IS NULL) OBL 
						  ON OBS.I_FilaTablaID = OBL.I_RowID
							 AND OBS.I_ProcedenciaID = OBL.I_ProcedenciaID
		 WHERE OBS.I_ObservID = @I_ObservID 
			   AND OBS.I_TablaID = @I_TablaID

		SET @I_Observados = (SELECT COUNT(*) FROM TI_ObservacionRegistroTabla OBS INNER JOIN 
												  TR_Ec_Obl OBL ON OBS.I_FilaTablaID = OBL.I_RowID 
																	AND OBL.I_ProcedenciaID = OBS.I_ProcedenciaID
																	AND OBS.I_TablaID = @I_TablaID 
							  WHERE I_ObservID = @I_ObservID AND
									OBL.Ano = @T_Anio AND
									OBS.I_ProcedenciaID = @I_ProcedenciaID AND 
									B_Resuelto = 0)

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



IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_28_FechaVencimientoCuotaPorOblID')
	DROP PROCEDURE [dbo].[USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_28_FechaVencimientoCuotaPorOblID]
GO

CREATE PROCEDURE [dbo].[USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_28_FechaVencimientoCuotaPorOblID]	
	@I_RowID	  int,
	@B_Resultado  bit OUTPUT,
	@T_Message	  nvarchar(4000) OUTPUT	
AS
/*
	DESCRIPCION: Marcar TR_Ec_Obl con B_Migrable = 0 cuando la fecha de vencimiento es diferente a la fecha de vencimiento de la cuota de pago de la oblID

	DECLARE	@I_RowID	  int,
			@B_Resultado  bit,
			@T_Message	  nvarchar(4000)
	EXEC USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_28_FechaVencimientoCuotaPorOblID @I_RowID, @B_Resultado output, @T_Message output
	SELECT @B_Resultado as resultado, @T_Message as mensaje
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
		WHERE obl.I_RowID = @I_RowID
			  AND obl.Fch_venc <> cp.Fch_venc


		UPDATE	TRG_1
		SET		B_Migrable = 0,
				D_FecEvalua = @D_FecProceso
		FROM	TR_Ec_Obl TRG_1
				INNER JOIN #temp_obl_fecVenc_dif_cuota_anio SRC_1 
							ON TRG_1.I_RowID = SRC_1.I_RowID
		WHERE	ISNULL(TRG_1.B_Correcto, 0) = 0


		MERGE TI_ObservacionRegistroTabla AS TRG
		USING (SELECT @I_ObservID AS I_ObservID, @I_TablaID AS I_TablaID, TRG_1.I_RowID AS I_FilaTablaID, 
					  @D_FecProceso AS D_FecRegistro, TRG_1.I_ProcedenciaID, SRC_1.I_RowID
				 FROM TR_Ec_Obl TRG_1
					  LEFT JOIN #temp_obl_fecVenc_dif_cuota_anio SRC_1 
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
			   INNER JOIN (SELECT ec_obl.I_RowID, ec_obl.Ano, ec_obl.Cod_alu, ec_obl.Cod_rc, ec_obl.I_ProcedenciaID 
							 FROM TR_Ec_Obl ec_obl
								  LEFT JOIN #temp_obl_fecVenc_dif_cuota_anio SRC_1 ON ec_obl.I_RowID = SRC_1.I_RowID
							WHERE ec_obl.I_RowID = @I_RowID
								  AND SRC_1.I_RowID IS NULL
						  ) OBL 
						  ON OBS.I_FilaTablaID = OBL.I_RowID
							 AND OBS.I_ProcedenciaID = OBL.I_ProcedenciaID
		 WHERE OBS.I_ObservID = @I_ObservID 
			   AND OBS.I_TablaID = @I_TablaID
			   AND OBS.I_FilaTablaID = @I_RowID

		SET @I_Observados = (SELECT COUNT(*) FROM TI_ObservacionRegistroTabla OBS INNER JOIN 
												  TR_Ec_Obl OBL ON OBS.I_FilaTablaID = OBL.I_RowID 
																	AND OBL.I_ProcedenciaID = OBS.I_ProcedenciaID
																	AND OBS.I_TablaID = @I_TablaID 
							  WHERE I_ObservID = @I_ObservID
									AND B_Resuelto = 0
									AND OBL.I_RowID = @I_RowID)

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
		IF (@@TRANCOUNT > 0) 
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


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_29_ExisteEnDestino')
	DROP PROCEDURE [dbo].[USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_29_ExisteEnDestino]
GO

CREATE PROCEDURE [dbo].[USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_29_ExisteEnDestino] 
	@I_ProcedenciaID tinyint,
	@T_Anio		  varchar(4),
	@B_Resultado  bit output,
	@T_Message	  nvarchar(4000) OUTPUT	
AS
/*
	DESCRIPCION: Marcar TR_Ec_Obl con B_Migrable = 0 cuando la obligacion ya existe con otro monto en la base de datos de cuentas por cobrar
				 para el año y procedencia

	DECLARE @I_ProcedenciaID	tinyint = 1,
			@T_Anio		  varchar(4) = '2010',
			@B_Resultado  bit,
			@T_Message	  nvarchar(4000)
	EXEC USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_29_ExisteEnDestino @I_ProcedenciaID, @T_Anio, @B_Resultado output, @T_Message output
	SELECT @B_Resultado as resultado, @T_Message as mensaje
*/
BEGIN
	DECLARE @I_Observados int = 0
	DECLARE @D_FecProceso datetime = GETDATE() 
	DECLARE @I_ObservID int = 29
	DECLARE @I_TablaID int = 5

	BEGIN TRANSACTION
	BEGIN TRY 
		
		SELECT Ano, P, obl.I_Periodo, Cod_alu, Cod_rc, obl.Cuota_pago, obl.Fch_venc, Tipo_oblig, Monto, obl.I_RowID, Ctas_obl.I_MontoOblig
		INTO  #temp_obl_Monto_dif_Ctas_anio
		FROM  TR_Ec_Obl obl
				LEFT JOIN (SELECT I_ObligacionAluID, I_ProcesoID, I_MontoOblig, D_FecVencto, M.C_CodAlu, M.C_CodRc, 
								M.I_Anio, M.I_Periodo, C.B_Pagado 
							FROM BD_OCEF_CtasPorCobrar.dbo.TR_ObligacionAluCab C 
								INNER JOIN BD_OCEF_CtasPorCobrar.dbo.TC_MatriculaAlumno M ON C.I_MatAluID = M.I_MatAluID
						  ) Ctas_obl ON obl.Cuota_pago = Ctas_obl.I_ProcesoID
										AND obl.I_Periodo = Ctas_obl.I_Periodo
										AND obl.Ano = CAST(Ctas_obl.I_Anio as varchar(4))
										AND obl.Cod_alu = Ctas_obl.C_CodAlu
										AND obl.Cod_rc = Ctas_obl.C_CodRc
										AND obl.Fch_venc = Ctas_obl.D_FecVencto									 
		WHERE obl.I_ProcedenciaID = @I_ProcedenciaID
			  AND Ctas_obl.I_ObligacionAluID IS NOT NULL
			  AND Ano = @T_Anio 
			  AND ISNULL(B_Correcto, 0) = 0 
			  AND obl.Monto <> ISNULL(Ctas_obl.I_MontoOblig, 0)
		ORDER BY Ano, obl.I_Periodo, Cuota_pago, Cod_rc, Cod_alu 


		UPDATE	TRG_1
		SET		B_Migrable = 0,
				D_FecEvalua = @D_FecProceso
		FROM	TR_Ec_Obl TRG_1
				INNER JOIN #temp_obl_Monto_dif_Ctas_anio SRC_1 
				ON TRG_1.I_RowID = SRC_1.I_RowID
		WHERE	TRG_1.Ano = @T_Anio
				AND ISNULL(TRG_1.B_Correcto, 0) = 0 

					
		MERGE TI_ObservacionRegistroTabla AS TRG
		USING (SELECT @I_ObservID AS I_ObservID, @I_TablaID AS I_TablaID, TRG_1.I_RowID AS I_FilaTablaID, @D_FecProceso AS D_FecRegistro 
				 FROM TR_Ec_Obl TRG_1
					  INNER JOIN #temp_obl_Monto_dif_Ctas_anio SRC_1 ON TRG_1.I_RowID = SRC_1.I_RowID
				WHERE TRG_1.Ano = @T_Anio
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
			   INNER JOIN (SELECT TRG_1.Ano, TRG_1.P, TRG_1.I_Periodo, TRG_1.Cod_alu, TRG_1.Cod_rc, TRG_1.Cuota_pago, TRG_1.Fch_venc, 
								  TRG_1.Tipo_oblig, TRG_1.Monto, TRG_1.I_RowID, TRG_1.I_ProcedenciaID 
							 FROM TR_Ec_Obl TRG_1
								  LEFT JOIN #temp_obl_Monto_dif_Ctas_anio SRC_1 ON TRG_1.I_RowID = SRC_1.I_RowID
							WHERE TRG_1.Ano = @T_Anio
								  AND SRC_1.I_RowID IS NULL
								  AND ISNULL(TRG_1.B_Correcto, 0) = 0 
						  ) OBL 
						  ON OBS.I_FilaTablaID = OBL.I_RowID
							 AND OBS.I_ProcedenciaID = OBL.I_ProcedenciaID
		 WHERE OBS.I_ObservID = @I_ObservID 
			   AND OBS.I_TablaID = @I_TablaID


		SET @I_Observados = (SELECT COUNT(*) FROM TI_ObservacionRegistroTabla OBS INNER JOIN 
												  TR_Ec_Obl OBL ON OBS.I_FilaTablaID = OBL.I_RowID 
																	AND OBL.I_ProcedenciaID = OBS.I_ProcedenciaID
																	AND OBS.I_TablaID = @I_TablaID 
							  WHERE OBS.I_ObservID = @I_ObservID AND
									OBL.Ano = @T_Anio AND
									OBS.B_Resuelto = 0 AND
									OBS.I_ProcedenciaID = @I_ProcedenciaID)

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
		IF (@@TRANCOUNT > 0)
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


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_29_ExisteEnDestinoPorOblID')
	DROP PROCEDURE [dbo].[USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_29_ExisteEnDestinoPorOblID]
GO

CREATE PROCEDURE [dbo].[USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_29_ExisteEnDestinoPorOblID]	
	@I_RowID	  int = NULL,
	@B_Resultado  bit output,
	@T_Message	  nvarchar(4000) OUTPUT	
AS
/*
	DESCRIPCION: Marcar TR_Ec_Obl con B_Migrable = 0 cuando la obligacion ya existe con otro monto en la base de datos de cuentas por cobrar
				 para el I_RowID de la obligacion

	DECLARE @I_RowID	  int = NULL,
			@B_Resultado  bit,
			@T_Message	  nvarchar(4000)
	EXEC USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_29_ExisteEnDestinoPorOblID @I_ProcedenciaID, @I_RowID, @B_Resultado output, @T_Message output
	SELECT @B_Resultado as resultado, @T_Message as mensaje
*/
BEGIN
	DECLARE @I_Observados int = 0
	DECLARE @D_FecProceso datetime = GETDATE() 
	DECLARE @I_ObservID int = 29
	DECLARE @I_TablaID int = 5

	BEGIN TRANSACTION
	BEGIN TRY 
		
		SELECT Ano, P, obl.I_Periodo, Cod_alu, Cod_rc, obl.Cuota_pago, obl.Fch_venc, Tipo_oblig, Monto, obl.I_RowID, Ctas_obl.I_MontoOblig
		INTO  #temp_obl_Monto_dif_CtasObl
		FROM  TR_Ec_Obl obl
				LEFT JOIN (SELECT I_ObligacionAluID, I_ProcesoID, I_MontoOblig, D_FecVencto, M.C_CodAlu, M.C_CodRc, 
								M.I_Anio, M.I_Periodo, C.B_Pagado 
							FROM BD_OCEF_CtasPorCobrar.dbo.TR_ObligacionAluCab C 
								INNER JOIN BD_OCEF_CtasPorCobrar.dbo.TC_MatriculaAlumno M ON C.I_MatAluID = M.I_MatAluID
						  ) Ctas_obl ON obl.Cuota_pago = Ctas_obl.I_ProcesoID
										AND obl.I_Periodo = Ctas_obl.I_Periodo
										AND obl.Ano = CAST(Ctas_obl.I_Anio as varchar(4))
										AND obl.Cod_alu = Ctas_obl.C_CodAlu
										AND obl.Cod_rc = Ctas_obl.C_CodRc
										AND obl.Fch_venc = Ctas_obl.D_FecVencto									 
		WHERE Ctas_obl.I_ObligacionAluID IS NOT NULL
			  AND obl.I_RowID = @I_RowID 
			  AND ISNULL(obl.B_Correcto, 0) = 0 
			  AND obl.Monto <> ISNULL(Ctas_obl.I_MontoOblig, 0)
		ORDER BY obl.Ano, obl.I_Periodo, obl.Cuota_pago, obl.Cod_rc, obl.Cod_alu 


		UPDATE	TRG_1
		SET		B_Migrable = 0,
				D_FecEvalua = @D_FecProceso
		FROM	TR_Ec_Obl TRG_1
				INNER JOIN #temp_obl_Monto_dif_CtasObl SRC_1 
				ON TRG_1.I_RowID = SRC_1.I_RowID
		WHERE	TRG_1.I_RowID = @I_RowID
				AND ISNULL(TRG_1.B_Correcto, 0) = 0 

					
		MERGE TI_ObservacionRegistroTabla AS TRG
		USING (SELECT @I_ObservID AS I_ObservID, @I_TablaID AS I_TablaID, TRG_1.I_RowID AS I_FilaTablaID, 
					  @D_FecProceso AS D_FecRegistro, TRG_1.I_ProcedenciaID
				 FROM TR_Ec_Obl TRG_1
					  LEFT JOIN #temp_obl_Monto_dif_CtasObl SRC_1 ON TRG_1.I_RowID = SRC_1.I_RowID
				WHERE TRG_1.I_RowID = @I_RowID
					  AND ISNULL(TRG_1.B_Correcto, 0) = 0 
			  ) AS SRC
		ON TRG.I_ObservID = SRC.I_ObservID AND TRG.I_TablaID = SRC.I_TablaID AND TRG.I_FilaTablaID = SRC.I_FilaTablaID
		WHEN MATCHED THEN
			UPDATE SET D_FecRegistro = SRC.D_FecRegistro, 
					   B_Resuelto = 0
		WHEN NOT MATCHED BY TARGET THEN
			INSERT (I_ObservID, I_TablaID, I_FilaTablaID, D_FecRegistro, I_ProcedenciaID, B_ObligProc)
			VALUES (SRC.I_ObservID, SRC.I_TablaID, SRC.I_FilaTablaID, SRC.D_FecRegistro, SRC.I_ProcedenciaID, 1);


		UPDATE OBS
		   SET D_FecResuelto = @D_FecProceso,
			   B_Resuelto = 1
		  FROM TI_ObservacionRegistroTabla OBS
			   INNER JOIN (SELECT  TRG_1.Ano, TRG_1.P, TRG_1.I_Periodo, TRG_1.Cod_alu, TRG_1.Cod_rc, TRG_1.Cuota_pago, TRG_1.Fch_venc, 
								   TRG_1.Tipo_oblig, TRG_1.Monto, TRG_1.I_RowID, TRG_1.I_ProcedenciaID
							 FROM TR_Ec_Obl TRG_1
								  LEFT JOIN #temp_obl_Monto_dif_CtasObl SRC_1 ON TRG_1.I_RowID = SRC_1.I_RowID
							WHERE TRG_1.I_RowID = @I_RowID
								  AND SRC_1.I_RowID IS NULL
								  AND ISNULL(TRG_1.B_Correcto, 0) = 0 
						  ) OBL 
						  ON OBS.I_FilaTablaID = OBL.I_RowID
							 AND OBS.I_ProcedenciaID = OBL.I_ProcedenciaID
		 WHERE OBS.I_ObservID = @I_ObservID 
			   AND OBS.I_TablaID = @I_TablaID
			   AND OBS.I_FilaTablaID = @I_RowID


		SET @I_Observados = (SELECT COUNT(*) FROM TI_ObservacionRegistroTabla OBS INNER JOIN 
												  TR_Ec_Obl OBL ON OBS.I_FilaTablaID = OBL.I_RowID 
																	AND OBL.I_ProcedenciaID = OBS.I_ProcedenciaID
																	AND OBS.I_TablaID = @I_TablaID 
							  WHERE OBS.I_ObservID = @I_ObservID AND
									OBS.B_Resuelto = 0 AND
									OBS.I_FilaTablaID = @I_RowID)

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


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_U_ValidarObligacionCuotaPagoMigrada')
	DROP PROCEDURE [dbo].[USP_U_ValidarObligacionCuotaPagoMigrada]
GO

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_32_ValidarObligacionCuotaPagoMigrada')
	DROP PROCEDURE [dbo].[USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_32_ValidarObligacionCuotaPagoMigrada]
GO

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_32_ObligacionCuotaPagoMigrada')
	DROP PROCEDURE [dbo].[USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_32_ObligacionCuotaPagoMigrada]
GO

CREATE PROCEDURE [dbo].[USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_32_ObligacionCuotaPagoMigrada]	
	@I_ProcedenciaID tinyint,
	@T_Anio			 varchar(4) = NULL,
	@B_Resultado  bit output,
	@T_Message	  nvarchar(4000) OUTPUT	
AS
/*
	DESCRIPCION: Marcar TR_Ec_Obl con B_Migrable = 0 cuando la cuota de pago de la obligacion para la procedencia y año no ha sido migrada, o no se encuentra en la base de datos de ctas x cobrar

	DECLARE	@I_ProcedenciaID	tinyint = 1, 
			@T_Anio				varchar(4) = 2010,
			@B_Resultado		bit,
			@T_Message			nvarchar(4000)
	EXEC USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_32_ObligacionCuotaPagoMigrada @I_ProcedenciaID, @T_Anio, @B_Resultado output, @T_Message output
	SELECT @B_Resultado as resultado, @T_Message as mensaje
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
										AND cp.B_ExisteCtas = 1
		WHERE cp.I_ProcedenciaID = @I_ProcedenciaID
			  AND obl.Ano = @T_Anio
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
				  WHERE	OBL.I_ProcedenciaID = @I_ProcedenciaID
						AND OBL.Ano = @T_Anio
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
			   INNER JOIN (SELECT  TRG_1.Ano, TRG_1.P, TRG_1.I_Periodo, TRG_1.Cod_alu, TRG_1.Cod_rc, TRG_1.Cuota_pago, TRG_1.Fch_venc, 
								   TRG_1.Tipo_oblig, TRG_1.Monto, TRG_1.I_RowID, TRG_1.I_ProcedenciaID
							 FROM TR_Ec_Obl TRG_1
								  LEFT JOIN #temp_obl_cuota_no_migrada SRC_1 ON TRG_1.I_RowID = SRC_1.I_RowID
							WHERE TRG_1.Ano = @T_Anio
								  AND TRG_1.I_ProcedenciaID	= @I_ProcedenciaID
								  AND SRC_1.I_RowID IS NULL
								  AND ISNULL(TRG_1.B_Correcto, 0) = 0 
						  ) OBL 
						  ON OBS.I_FilaTablaID = OBL.I_RowID
							 AND OBS.I_ProcedenciaID = OBL.I_ProcedenciaID
		 WHERE OBS.I_ObservID = @I_ObservID 
			   AND OBS.I_TablaID = @I_TablaID

		SET @I_Observados = (SELECT COUNT(*) FROM TI_ObservacionRegistroTabla OBS INNER JOIN 
												  TR_Ec_Obl OBL ON OBS.I_FilaTablaID = OBL.I_RowID 
																	AND OBL.I_ProcedenciaID = OBS.I_ProcedenciaID
																	AND OBS.I_TablaID = @I_TablaID 
							  WHERE OBS.I_ObservID = @I_ObservID AND
									OBS.B_Resuelto = 0 AND
									OBL.Ano = @T_Anio AND
									OBL.I_ProcedenciaID = @I_ProcedenciaID)

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


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_32_ObligacionCuotaPagoMigradaPorOblID')
	DROP PROCEDURE [dbo].[USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_32_ObligacionCuotaPagoMigradaPorOblID]
GO

CREATE PROCEDURE [dbo].[USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_32_ObligacionCuotaPagoMigradaPorOblID]	
	@I_RowID	  int,
	@B_Resultado  bit OUTPUT,
	@T_Message	  nvarchar(4000) OUTPUT	
AS
/*
	DESCRIPCION: Marcar TR_Ec_Obl con B_Migrable = 0 cuando la cuota de pago de la oblID no ha sido migrada, o no se encuentra en la base de datos de ctas x cobrar

	DECLARE	@I_RowID	  int,
			@B_Resultado  bit,
			@T_Message	  nvarchar(4000)
	EXEC USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_32_ObligacionCuotaPagoMigradaPorOblID @I_RowID, @B_Resultado output, @T_Message output
	SELECT @B_Resultado as resultado, @T_Message as mensaje
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
										AND cp.B_ExisteCtas = 1
		WHERE cp.I_RowID is null


		UPDATE	OBL
		SET		B_Migrable = 0,
				D_FecEvalua = @D_FecProceso
		 FROM	TR_Ec_Obl OBL
				INNER JOIN #temp_obl_cuota_no_migrada TMP ON OBL.I_RowID = TMP.I_RowID
		WHERE	OBL.I_RowID = @I_RowID


		MERGE TI_ObservacionRegistroTabla AS TRG
		USING 	(SELECT	@I_ObservID AS I_ObservID, @I_TablaID AS I_TablaID, OBL.I_RowID AS I_FilaTablaID, 
						@D_FecProceso AS D_FecRegistro, I_ProcedenciaID 
				   FROM	TR_Ec_Obl OBL
						INNER JOIN #temp_obl_cuota_no_migrada TMP ON OBL.I_RowID = TMP.I_RowID
				  WHERE	OBL.I_RowID = @I_RowID
				) AS SRC
		ON TRG.I_ObservID = SRC.I_ObservID AND TRG.I_TablaID = SRC.I_TablaID AND TRG.I_FilaTablaID = SRC.I_FilaTablaID
		WHEN MATCHED THEN
			UPDATE SET D_FecRegistro = SRC.D_FecRegistro, 
					   B_Resuelto = 0
		WHEN NOT MATCHED BY TARGET THEN
			INSERT (I_ObservID, I_TablaID, I_FilaTablaID, D_FecRegistro, I_ProcedenciaID, B_ObligProc)
			VALUES (SRC.I_ObservID, SRC.I_TablaID, SRC.I_FilaTablaID, SRC.D_FecRegistro, SRC.I_ProcedenciaID, 1);


		UPDATE OBS
		   SET D_FecResuelto = @D_FecProceso,
			   B_Resuelto = 1
		  FROM TI_ObservacionRegistroTabla OBS
			   INNER JOIN (SELECT  TRG_1.Ano, TRG_1.P, TRG_1.I_Periodo, TRG_1.Cod_alu, TRG_1.Cod_rc, TRG_1.Cuota_pago, TRG_1.Fch_venc, 
								   TRG_1.Tipo_oblig, TRG_1.Monto, TRG_1.I_RowID, TRG_1.I_ProcedenciaID
							 FROM TR_Ec_Obl TRG_1
								  LEFT JOIN #temp_obl_cuota_no_migrada SRC_1 ON TRG_1.I_RowID = SRC_1.I_RowID
							WHERE TRG_1.I_RowID = @I_RowID 
								  AND SRC_1.I_RowID IS NULL
								  AND ISNULL(TRG_1.B_Correcto, 0) = 0 
						  ) OBL 
						  ON OBS.I_FilaTablaID = OBL.I_RowID
							 AND OBS.I_ProcedenciaID = OBL.I_ProcedenciaID
		 WHERE OBS.I_ObservID = @I_ObservID 
			   AND OBS.I_TablaID = @I_TablaID

		SET @I_Observados = (SELECT COUNT(*) FROM TI_ObservacionRegistroTabla OBS INNER JOIN 
												  TR_Ec_Obl OBL ON OBS.I_FilaTablaID = OBL.I_RowID 
																	AND OBL.I_ProcedenciaID = OBS.I_ProcedenciaID
																	AND OBS.I_TablaID = @I_TablaID 
							  WHERE OBS.I_ObservID = @I_ObservID AND
									OBS.B_Resuelto = 0 AND
									OBL.I_RowID = @I_RowID)

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
	DESCRIPCION: Marcar TR_Ec_Obl con B_Migrable = 0 cuando la procedencia de la obligación no coincide con la procedencia de la cuota de pago migrada 
						o en la base de datos de ctas x cobrar para el año y procedencia

	DECLARE	@I_ProcedenciaID	tinyint = 2, 
			@T_Anio				varchar(4) = 2016,
			@B_Resultado		bit,
			@T_Message			nvarchar(4000)
	EXEC USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_34_ProcedenciaCuotaPago @I_ProcedenciaID, @T_Anio, @B_Resultado output, @T_Message output
	SELECT @B_Resultado as resultado, @T_Message as mensaje
*/
BEGIN
	DECLARE @I_Observados int = 0
	DECLARE @D_FecProceso datetime = GETDATE() 
	DECLARE @I_ObservID int = 34
	DECLARE @I_TablaID int = 5

	BEGIN TRANSACTION
	BEGIN TRY
		
		SELECT Ano, P, Cod_alu, Cod_rc, obl.Cuota_pago, obl.Fch_venc, Tipo_oblig, Monto, obl.I_RowID
		  INTO #temp_obl_procedencia_dif_cuota_anio
		  FROM TR_Ec_Obl obl
		 	   LEFT JOIN TR_Cp_Des cp ON obl.Cuota_pago = cp.Cuota_pago 
										AND obl.I_ProcedenciaID = cp.I_ProcedenciaID
										AND cp.Eliminado = 0
										AND B_ExisteCtas = 1
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
			UPDATE SET D_FecRegistro = SRC.D_FecRegistro, 
					   B_Resuelto = 0
		WHEN NOT MATCHED BY TARGET THEN
			INSERT (I_ObservID, I_TablaID, I_FilaTablaID, D_FecRegistro, I_ProcedenciaID, B_ObligProc)
			VALUES (SRC.I_ObservID, SRC.I_TablaID, SRC.I_FilaTablaID, SRC.D_FecRegistro, @I_ProcedenciaID, 1);


		UPDATE OBS
		   SET D_FecResuelto = @D_FecProceso,
			   B_Resuelto = 1
		  FROM TI_ObservacionRegistroTabla OBS
			   INNER JOIN (SELECT  TRG_1.Ano, TRG_1.P, TRG_1.I_Periodo, TRG_1.Cod_alu, TRG_1.Cod_rc, TRG_1.Cuota_pago, TRG_1.Fch_venc, 
								   TRG_1.Tipo_oblig, TRG_1.Monto, TRG_1.I_RowID, TRG_1.I_ProcedenciaID
							 FROM TR_Ec_Obl TRG_1
								  LEFT JOIN #temp_obl_procedencia_dif_cuota_anio SRC_1 ON TRG_1.I_RowID = SRC_1.I_RowID
							WHERE TRG_1.I_ProcedenciaID = @I_ProcedenciaID
								  AND TRG_1.Ano = @T_Anio
								  AND SRC_1.I_RowID IS NULL
								  AND ISNULL(TRG_1.B_Correcto, 0) = 0 
						  ) OBL 
						  ON OBS.I_FilaTablaID = OBL.I_RowID
							 AND OBS.I_ProcedenciaID = OBL.I_ProcedenciaID
		 WHERE OBS.I_ObservID = @I_ObservID 
			   AND OBS.I_TablaID = @I_TablaID


		SET @I_Observados = (SELECT COUNT(*) 
							   FROM TI_ObservacionRegistroTabla OBS 
									INNER JOIN TR_Ec_Obl OBL ON OBS.I_FilaTablaID = OBL.I_RowID 
																AND OBL.I_ProcedenciaID = OBS.I_ProcedenciaID
																AND OBS.I_TablaID = @I_TablaID
							  WHERE OBS.I_ObservID = @I_ObservID AND
									OBS.I_ProcedenciaID = @I_ProcedenciaID AND 
									OBL.Ano = @T_Anio AND 
									OBS.B_Resuelto = 0)

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


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_34_ProcedenciaCuotaPagoPorOblID')
	DROP PROCEDURE [dbo].[USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_34_ProcedenciaCuotaPagoPorOblID]
GO

CREATE PROCEDURE [dbo].[USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_34_ProcedenciaCuotaPagoPorOblID]	
	@I_RowID	  int,
	@B_Resultado  bit OUTPUT,
	@T_Message	  nvarchar(4000) OUTPUT	
AS
/*
	DESCRIPCION: Marcar TR_Ec_Obl con B_Migrable = 0 cuando la procedencia de la obligación no coincide con la procedencia de la cuota de pago migrada 
				 o en la base de datos de ctas x cobrar para el Id de la obligacion

	DECLARE	@I_RowID	  int,
			@B_Resultado  bit,
			@T_Message	  nvarchar(4000)
	EXEC USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_34_ProcedenciaCuotaPagoPorOblID @I_RowID, @B_Resultado output, @T_Message output
	SELECT @B_Resultado as resultado, @T_Message as mensaje
*/
BEGIN
	DECLARE @I_Observados int = 0
	DECLARE @D_FecProceso datetime = GETDATE() 
	DECLARE @I_ObservID int = 34
	DECLARE @I_TablaID int = 5

	BEGIN TRANSACTION
	BEGIN TRY
		
		SELECT Ano, P, Cod_alu, Cod_rc, obl.Cuota_pago, obl.Fch_venc, Tipo_oblig, Monto, obl.I_RowID
		  INTO #temp_obl_procedencia_dif_cuota
		  FROM TR_Ec_Obl obl
		 	   LEFT JOIN TR_Cp_Des cp ON obl.Cuota_pago = cp.Cuota_pago 
										AND obl.I_ProcedenciaID = cp.I_ProcedenciaID
										AND cp.Eliminado = 0
										AND B_ExisteCtas = 1
		 WHERE cp.I_RowID is null


		UPDATE	OBL
		SET		B_Migrable = 0,
				D_FecEvalua = @D_FecProceso
		FROM	TR_Ec_Obl OBL 
				INNER JOIN #temp_obl_procedencia_dif_cuota TMP ON OBL.I_RowID = TMP.I_RowID
		WHERE	OBL.I_RowID = @I_RowID


		MERGE TI_ObservacionRegistroTabla AS TRG
		USING (SELECT @I_ObservID AS I_ObservID, @I_TablaID AS I_TablaID, OBL.I_RowID AS I_FilaTablaID, 
					  @D_FecProceso AS D_FecRegistro, I_ProcedenciaID
			     FROM TR_Ec_Obl OBL 
					  INNER JOIN #temp_obl_procedencia_dif_cuota TMP ON OBL.I_RowID = TMP.I_RowID
				WHERE OBL.I_RowID = @I_RowID
			  ) AS SRC
		ON TRG.I_ObservID = SRC.I_ObservID AND TRG.I_TablaID = SRC.I_TablaID AND TRG.I_FilaTablaID = SRC.I_FilaTablaID
		WHEN MATCHED THEN
			UPDATE SET D_FecRegistro = SRC.D_FecRegistro, 
					   B_Resuelto = 0
		WHEN NOT MATCHED BY TARGET THEN
			INSERT (I_ObservID, I_TablaID, I_FilaTablaID, D_FecRegistro, I_ProcedenciaID, B_ObligProc)
			VALUES (SRC.I_ObservID, SRC.I_TablaID, SRC.I_FilaTablaID, SRC.D_FecRegistro, SRC.I_ProcedenciaID, 1);


		UPDATE OBS
		   SET D_FecResuelto = @D_FecProceso,
			   B_Resuelto = 1
		  FROM TI_ObservacionRegistroTabla OBS
			   INNER JOIN (SELECT  TRG_1.Ano, TRG_1.P, TRG_1.I_Periodo, TRG_1.Cod_alu, TRG_1.Cod_rc, TRG_1.Cuota_pago, TRG_1.Fch_venc, 
								   TRG_1.Tipo_oblig, TRG_1.Monto, TRG_1.I_RowID, TRG_1.I_ProcedenciaID
							 FROM TR_Ec_Obl TRG_1
								  LEFT JOIN #temp_obl_procedencia_dif_cuota SRC_1 ON TRG_1.I_RowID = SRC_1.I_RowID
							WHERE TRG_1.I_RowID = @I_RowID
								  AND SRC_1.I_RowID IS NULL
								  AND ISNULL(TRG_1.B_Correcto, 0) = 0 
						  ) OBL 
						  ON OBS.I_FilaTablaID = OBL.I_RowID
							 AND OBS.I_ProcedenciaID = OBL.I_ProcedenciaID
		 WHERE OBS.I_ObservID = @I_ObservID 
			   AND OBS.I_TablaID = @I_TablaID
			   AND OBS.I_FilaTablaID = @I_RowID


		SET @I_Observados = (SELECT COUNT(*) 
							   FROM TI_ObservacionRegistroTabla OBS 
									INNER JOIN TR_Ec_Obl OBL ON OBS.I_FilaTablaID = OBL.I_RowID 
																AND OBL.I_ProcedenciaID = OBS.I_ProcedenciaID
																AND OBS.I_TablaID = @I_TablaID 
							  WHERE I_ObservID = @I_ObservID AND
									OBS.I_FilaTablaID = @I_RowID AND 
									OBS.B_Resuelto = 0)

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


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_36_ConceptoPagoMigrado')
	DROP PROCEDURE [dbo].[USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_36_ConceptoPagoMigrado]
GO

CREATE PROCEDURE [dbo].[USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_36_ConceptoPagoMigrado]	
	@I_ProcedenciaID tinyint,
	@T_Anio		  varchar(4),
	@B_Resultado  bit output,
	@T_Message	  nvarchar(4000) OUTPUT	
AS
/*
	DESCRIPCION: Marcar TR_Ec_Obl con B_Migrable = 0 cuando la obligacion tiene conceptos que no estan migrados o no son migrables para el año y procedencia

	DECLARE @I_ProcedenciaID	tinyint = 2, 
	    	@T_Anio				varchar(4) = '2008',
			@B_Resultado		bit,
			@T_Message			nvarchar(4000)
	EXEC USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_36_ConceptoPagoMigrado @I_ProcedenciaID, @T_Anio, @B_Resultado output, @T_Message output
	SELECT @B_Resultado as resultado, @T_Message as mensaje
*/
BEGIN
	DECLARE @I_Observados int = 0
	DECLARE @D_FecProceso datetime = GETDATE() 
	DECLARE @I_ObservID int = 36
	DECLARE @I_ObservDetID int = 35
	DECLARE @I_TablaDetID int = 4
	DECLARE @I_TablaID int = 5

	BEGIN TRANSACTION
	BEGIN TRY

		SELECT Obl.*
		  INTO #temp_observados_detalle_concepto_sin_migrar
		  FROM TR_Ec_Obl Obl
			   INNER JOIN TR_Ec_Det Det ON Obl.I_RowID = Det.I_OblRowID
			   INNER JOIN TI_ObservacionRegistroTabla OBS ON OBS.I_FilaTablaID = Det.I_RowID AND 
						  									 OBS.I_ProcedenciaID = Det.I_ProcedenciaID 
		 WHERE OBS.I_ObservID = @I_ObservDetID 
			   AND OBS.I_TablaID = @I_TablaDetID
			   AND OBS.B_Resuelto = 0
			   AND Obl.I_ProcedenciaID = @I_ProcedenciaID
			   AND Obl.Ano = @T_Anio 										  


		UPDATE	Obl
		   SET	B_Migrable = 0,
				D_FecEvalua = @D_FecProceso
		  FROM  TR_Ec_Obl Obl
				INNER JOIN #temp_observados_detalle_concepto_sin_migrar tmp ON Obl.I_RowID = tmp.I_RowID
		 WHERE	ISNULL(Obl.B_Correcto, 0) = 0


		MERGE TI_ObservacionRegistroTabla AS TRG
		USING (SELECT	DISTINCT @I_ObservID AS I_ObservID, @I_TablaID AS I_TablaID, Obl.I_RowID AS I_FilaTablaID, @D_FecProceso AS D_FecRegistro 
				 FROM	TR_Ec_Obl Obl
						INNER JOIN #temp_observados_detalle_concepto_sin_migrar tmp ON Obl.I_RowID = tmp.I_RowID
				WHERE	ISNULL(Obl.B_Correcto, 0) = 0 
			  ) AS SRC
		ON TRG.I_ObservID = SRC.I_ObservID AND TRG.I_TablaID = SRC.I_TablaID AND TRG.I_FilaTablaID = SRC.I_FilaTablaID
		WHEN MATCHED AND TRG.I_ProcedenciaID = @I_ProcedenciaID THEN
			UPDATE SET D_FecRegistro = SRC.D_FecRegistro, 
					   B_Resuelto = 0
		WHEN NOT MATCHED BY TARGET THEN
			INSERT (I_ObservID, I_TablaID, I_FilaTablaID, D_FecRegistro, I_ProcedenciaID, B_ObligProc)
			VALUES (SRC.I_ObservID, SRC.I_TablaID, SRC.I_FilaTablaID, SRC.D_FecRegistro, @I_ProcedenciaID, 1);


		UPDATE OBS
		   SET D_FecResuelto = @D_FecProceso,
			   B_Resuelto = 1
		  FROM TI_ObservacionRegistroTabla OBS
			   INNER JOIN (SELECT  TRG_1.Ano, TRG_1.P, TRG_1.I_Periodo, TRG_1.Cod_alu, TRG_1.Cod_rc, TRG_1.Cuota_pago, TRG_1.Fch_venc, 
								   TRG_1.Tipo_oblig, TRG_1.Monto, TRG_1.I_RowID, TRG_1.I_ProcedenciaID
							 FROM TR_Ec_Obl TRG_1
								  LEFT JOIN #temp_observados_detalle_concepto_sin_migrar SRC_1 ON TRG_1.I_RowID = SRC_1.I_RowID
							WHERE TRG_1.I_ProcedenciaID = @I_ProcedenciaID
								  AND TRG_1.Ano = @T_Anio
								  AND SRC_1.I_RowID IS NULL
								  AND ISNULL(TRG_1.B_Correcto, 0) = 0 
						  ) OBL 
						  ON OBS.I_FilaTablaID = OBL.I_RowID
							 AND OBS.I_ProcedenciaID = OBL.I_ProcedenciaID
		 WHERE OBS.I_ObservID = @I_ObservID 
			   AND OBS.I_TablaID = @I_TablaID


		SET @I_Observados = (SELECT COUNT(*) 
							   FROM TI_ObservacionRegistroTabla OBS 
									INNER JOIN TR_Ec_Obl OBL ON OBS.I_FilaTablaID = OBL.I_RowID 
																AND OBL.I_ProcedenciaID = OBS.I_ProcedenciaID
																AND OBS.I_TablaID = @I_TablaID
							  WHERE OBS.I_ObservID = @I_ObservID AND
									OBS.I_ProcedenciaID = @I_ProcedenciaID AND 
									OBL.Ano = @T_Anio AND 
									OBS.B_Resuelto = 0)

		SELECT @I_Observados as cant_obs, @D_FecProceso as fec_proceso

		COMMIT TRANSACTION		
		
		SET @B_Resultado = 1
		SET @T_Message = '{ ' +
							 'Type: "summary", ' + 
							 'Title: "Obligaciones con concepto no migrado", ' + 
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
							 'Title: "Error", ' + 
							 'Value: "' + ERROR_MESSAGE() + ' (Linea: ' + CAST(ERROR_LINE() AS varchar(11)) + ')."'  +
						  '}]' 
	END CATCH
END
GO



IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_36_ConceptoPagoMigradoPorOblID')
	DROP PROCEDURE [dbo].[USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_36_ConceptoPagoMigradoPorOblID]
GO

CREATE PROCEDURE [dbo].[USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_36_ConceptoPagoMigradoPorOblID]	
	@I_RowID	  int,
	@B_Resultado  bit OUTPUT,
	@T_Message	  nvarchar(4000) OUTPUT	
AS
/*
	DESCRIPCION: Marcar TR_Ec_Obl con B_Migrable = 0 cuando la obligacion tiene conceptos que no estan migrados o no son migrables para el Id de la obligacion

	DECLARE	@I_RowID	  int,
			@B_Resultado  bit,
			@T_Message	  nvarchar(4000)
	EXEC USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_36_ConceptoPagoMigrado @I_RowID, @B_Resultado output, @T_Message output
	SELECT @B_Resultado as resultado, @T_Message as mensaje
*/
BEGIN
	DECLARE @I_Observados int = 0
	DECLARE @D_FecProceso datetime = GETDATE() 
	DECLARE @I_ObservID int = 36
	DECLARE @I_ObservDetID int = 35
	DECLARE @I_TablaDetID int = 4
	DECLARE @I_TablaID int = 5

	BEGIN TRANSACTION
	BEGIN TRY

		SELECT Obl.*
		  INTO #temp_observados_detalle_concepto_sin_migrar
		  FROM TR_Ec_Obl Obl
			   INNER JOIN TR_Ec_Det Det ON Obl.I_RowID = Det.I_OblRowID
			   INNER JOIN TI_ObservacionRegistroTabla OBS ON OBS.I_FilaTablaID = Det.I_RowID AND 
						  									 OBS.I_ProcedenciaID = Det.I_ProcedenciaID 
		 WHERE OBS.I_ObservID = @I_ObservDetID 
			   AND OBS.I_TablaID = @I_TablaDetID
			   AND OBS.B_Resuelto = 0
			   AND Obl.I_RowID = @I_RowID 										  


		UPDATE	Obl
		SET		B_Migrable = 0,
				D_FecEvalua = @D_FecProceso
		FROM    TR_Ec_Obl Obl
				INNER JOIN #temp_observados_detalle_concepto_sin_migrar tmp ON Obl.I_RowID = tmp.I_RowID
		 WHERE	ISNULL(Obl.B_Correcto, 0) = 0
				AND Obl.I_RowID = @I_RowID 


		MERGE TI_ObservacionRegistroTabla AS TRG
		USING (SELECT DISTINCT @I_ObservID AS I_ObservID, @I_TablaID AS I_TablaID, Obl.I_RowID AS I_FilaTablaID, 
					  @D_FecProceso AS D_FecRegistro, Obl.I_ProcedenciaID
				 FROM TR_Ec_Obl Obl
					  INNER JOIN #temp_observados_detalle_concepto_sin_migrar tmp ON Obl.I_RowID = tmp.I_RowID
				WHERE ISNULL(Obl.B_Correcto, 0) = 0 
					  AND Obl.I_RowID = @I_RowID 
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
			   INNER JOIN (SELECT TRG_1.Ano, TRG_1.P, TRG_1.I_Periodo, TRG_1.Cod_alu, TRG_1.Cod_rc, TRG_1.Cuota_pago, TRG_1.Fch_venc, 
								  TRG_1.Tipo_oblig, TRG_1.Monto, TRG_1.I_ProcedenciaID, SRC_1.I_RowID
							 FROM TR_Ec_Obl TRG_1
								  LEFT JOIN #temp_observados_detalle_concepto_sin_migrar SRC_1 ON TRG_1.I_RowID = SRC_1.I_RowID
							WHERE SRC_1.I_RowID IS NULL
								  AND ISNULL(TRG_1.B_Correcto, 0) = 0 
						  ) OBL 
						  ON OBS.I_FilaTablaID = OBL.I_RowID
							 AND OBS.I_ProcedenciaID = OBL.I_ProcedenciaID
		 WHERE OBS.I_ObservID = @I_ObservID 
			   AND OBS.I_TablaID = @I_TablaID
			   AND OBS.I_FilaTablaID = @I_RowID


		SET @I_Observados = (SELECT COUNT(*) 
							   FROM TI_ObservacionRegistroTabla OBS 
									INNER JOIN TR_Ec_Obl OBL ON OBS.I_FilaTablaID = OBL.I_RowID 
																AND OBL.I_ProcedenciaID = OBS.I_ProcedenciaID
							  WHERE OBS.I_ObservID = @I_ObservID 
									AND OBS.I_FilaTablaID = @I_RowID  
									AND OBS.I_TablaID = @I_TablaID 
									AND OBS.B_Resuelto = 0)

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
		IF (@@TRANCOUNT > 0)
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



IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_37_ObservacionAnioDetalle')
	DROP PROCEDURE [dbo].[USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_37_ObservacionAnioDetalle]
GO

CREATE PROCEDURE [dbo].[USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_37_ObservacionAnioDetalle]	
	@I_ProcedenciaID tinyint,
	@T_Anio		  varchar(4),
	@B_Resultado  bit output,
	@T_Message	  nvarchar(4000) OUTPUT	
AS
/*
	DESCRIPCION: Marcar TR_Ec_Obl con B_Migrable = 0 cuando la obligacion tiene observaciones de año en el detalle o no son migrables para el año y procedencia

	DECLARE @I_ProcedenciaID	tinyint = 2, 
	    	@T_Anio				varchar(4) = '2008',
			@B_Resultado		bit,
			@T_Message			nvarchar(4000)
	EXEC USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_37_ObservacionAnioDetalle @I_ProcedenciaID, @T_Anio, @B_Resultado output, @T_Message output
	SELECT @B_Resultado as resultado, @T_Message as mensaje
*/
BEGIN
	DECLARE @I_Observados int = 0
	DECLARE @D_FecProceso datetime = GETDATE() 
	DECLARE @I_ObservID int = 37,
			@I_ObservID_AnioDes int = 43,
			@I_ObservID_AnioPri int = 15
	
	DECLARE @I_TablaID int = 5,
			@I_TablaDetID int = 4

	BEGIN TRANSACTION
	BEGIN TRY

		SELECT Obl.*
		  INTO #temp_observados_detalle_anio_cuota_concepto
		  FROM TR_Ec_Obl Obl
			   INNER JOIN TR_Ec_Det Det ON Obl.I_RowID = Det.I_OblRowID
			   INNER JOIN TI_ObservacionRegistroTabla OBS ON OBS.I_FilaTablaID = Det.I_RowID AND 
						  									 OBS.I_ProcedenciaID = Det.I_ProcedenciaID 
		 WHERE OBS.I_ObservID IN (@I_ObservID_AnioDes, @I_ObservID_AnioPri)
			   AND OBS.I_TablaID = @I_TablaDetID
			   AND OBS.B_Resuelto = 0										  


		UPDATE	Obl
		SET		B_Migrable = 0,
				D_FecEvalua = @D_FecProceso
		FROM    TR_Ec_Obl Obl
				INNER JOIN #temp_observados_detalle_anio_cuota_concepto tmp ON Obl.I_RowID = tmp.I_RowID
		WHERE	Obl.I_ProcedenciaID = @I_ProcedenciaID
				AND Obl.Ano = @T_Anio


		MERGE TI_ObservacionRegistroTabla AS TRG
		USING (SELECT	DISTINCT @I_ObservID AS I_ObservID, @I_TablaID AS I_TablaID, Obl.I_RowID AS I_FilaTablaID, 
						@D_FecProceso AS D_FecRegistro, Obl.I_ProcedenciaID
				 FROM   TR_Ec_Obl Obl
						INNER JOIN #temp_observados_detalle_anio_cuota_concepto tmp ON Obl.I_RowID = tmp.I_RowID
				WHERE	Obl.I_ProcedenciaID = @I_ProcedenciaID
						AND Obl.Ano = @T_Anio
			  ) AS SRC
		ON TRG.I_ObservID = SRC.I_ObservID AND TRG.I_TablaID = SRC.I_TablaID AND TRG.I_FilaTablaID = SRC.I_FilaTablaID
		WHEN MATCHED AND TRG.I_ProcedenciaID = @I_ProcedenciaID THEN
			UPDATE SET D_FecRegistro = SRC.D_FecRegistro, 
					   B_Resuelto = 0
		WHEN NOT MATCHED BY TARGET THEN
			INSERT (I_ObservID, I_TablaID, I_FilaTablaID, D_FecRegistro, I_ProcedenciaID, B_ObligProc)
			VALUES (SRC.I_ObservID, SRC.I_TablaID, SRC.I_FilaTablaID, SRC.D_FecRegistro, SRC.I_ProcedenciaID, 1);


		UPDATE OBS
		   SET D_FecResuelto = @D_FecProceso,
			   B_Resuelto = 1
		  FROM TI_ObservacionRegistroTabla OBS
			   INNER JOIN (SELECT TRG_1.Ano, TRG_1.P, TRG_1.I_Periodo, TRG_1.Cod_alu, TRG_1.Cod_rc, TRG_1.Cuota_pago, TRG_1.Fch_venc, 
								  TRG_1.Tipo_oblig, TRG_1.Monto, TRG_1.I_ProcedenciaID, SRC_1.I_RowID
							 FROM TR_Ec_Obl TRG_1
								  LEFT JOIN #temp_observados_detalle_anio_cuota_concepto SRC_1 ON TRG_1.I_RowID = SRC_1.I_RowID
							WHERE SRC_1.I_RowID IS NULL
								  AND ISNULL(TRG_1.B_Correcto, 0) = 0 
						  ) OBL 
						  ON OBS.I_FilaTablaID = OBL.I_RowID
							 AND OBS.I_ProcedenciaID = OBL.I_ProcedenciaID
		 WHERE OBS.I_ObservID = @I_ObservID 
			   AND OBS.I_ProcedenciaID = @I_ProcedenciaID 
			   AND OBS.I_TablaID = @I_TablaID


		SET @I_Observados = (SELECT COUNT(*) 
							   FROM TI_ObservacionRegistroTabla OBS 
									INNER JOIN TR_Ec_Obl OBL ON OBS.I_FilaTablaID = OBL.I_RowID 
																AND OBL.I_ProcedenciaID = OBS.I_ProcedenciaID
							  WHERE OBS.I_ObservID = @I_ObservID 
									AND OBS.I_ProcedenciaID = @I_ProcedenciaID  
									AND OBS.I_TablaID = @I_TablaID 
									AND OBS.B_Resuelto = 0)

		SELECT @I_Observados as cant_obs, @D_FecProceso as fec_proceso		

		COMMIT TRANSACTION		
		
		SET @B_Resultado = 1
		SET @T_Message = '{ ' +
							 'Type: "summary", ' + 
							 'Title: "Obligaciones con concepto no migrado", ' + 
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
							 'Title: "Error", ' + 
							 'Value: "' + ERROR_MESSAGE() + ' (Linea: ' + CAST(ERROR_LINE() AS varchar(11)) + ')."'  +
						  '}]' 
	END CATCH
END
GO



IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_37_ObservacionAnioDetallePorOblID')
	DROP PROCEDURE [dbo].[USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_37_ObservacionAnioDetallePorOblID]
GO

CREATE PROCEDURE [dbo].[USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_37_ObservacionAnioDetallePorOblID]	
	@I_RowID	  int,
	@B_Resultado  bit OUTPUT,
	@T_Message	  nvarchar(4000) OUTPUT	
AS
/*
	DESCRIPCION: Marcar TR_Ec_Obl con B_Migrable = 0 cuando la obligacion tiene conceptos que no estan migrados o no son migrables para el Id de la obligacion

	DECLARE	@I_RowID	  int,
			@B_Resultado  bit,
			@T_Message	  nvarchar(4000)
	EXEC USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_37_ObservacionAnioDetalle @I_RowID, @B_Resultado output, @T_Message output
	SELECT @B_Resultado as resultado, @T_Message as mensaje
*/
BEGIN
	DECLARE @I_Observados int = 0
	DECLARE @D_FecProceso datetime = GETDATE() 
	DECLARE @I_ObservID int = 37,
			@I_ObservID_AnioDes int = 43,
			@I_ObservID_AnioPri int = 15
	
	DECLARE @I_TablaID int = 5,
			@I_TablaDetID int = 4

	BEGIN TRANSACTION
	BEGIN TRY

		SELECT Obl.*
		  INTO #temp_observados_detalle_anio_cuota_concepto
		  FROM TR_Ec_Obl Obl
			   INNER JOIN TR_Ec_Det Det ON Obl.I_RowID = Det.I_OblRowID
			   INNER JOIN TI_ObservacionRegistroTabla OBS ON OBS.I_FilaTablaID = Det.I_RowID AND 
						  									 OBS.I_ProcedenciaID = Det.I_ProcedenciaID 
		 WHERE OBS.I_ObservID IN (@I_ObservID_AnioDes, @I_ObservID_AnioPri)
			   AND OBS.I_TablaID = @I_TablaDetID
			   AND OBS.B_Resuelto = 0										  


		UPDATE	Obl
		SET		B_Migrable = 0,
				D_FecEvalua = @D_FecProceso
		FROM    TR_Ec_Obl Obl
				INNER JOIN #temp_observados_detalle_anio_cuota_concepto tmp ON Obl.I_RowID = tmp.I_RowID
		WHERE	Obl.I_RowID = @I_RowID


		MERGE TI_ObservacionRegistroTabla AS TRG
		USING (SELECT	DISTINCT @I_ObservID AS I_ObservID, @I_TablaID AS I_TablaID, Obl.I_RowID AS I_FilaTablaID, 
						@D_FecProceso AS D_FecRegistro, Obl.I_ProcedenciaID
				 FROM   TR_Ec_Obl Obl
						INNER JOIN #temp_observados_detalle_anio_cuota_concepto tmp ON Obl.I_RowID = tmp.I_RowID
				WHERE	Obl.I_RowID = @I_RowID
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
			   INNER JOIN (SELECT TRG_1.Ano, TRG_1.P, TRG_1.I_Periodo, TRG_1.Cod_alu, TRG_1.Cod_rc, TRG_1.Cuota_pago, TRG_1.Fch_venc, 
								  TRG_1.Tipo_oblig, TRG_1.Monto, TRG_1.I_ProcedenciaID, SRC_1.I_RowID
							 FROM TR_Ec_Obl TRG_1
								  LEFT JOIN #temp_observados_detalle_anio_cuota_concepto SRC_1 ON TRG_1.I_RowID = SRC_1.I_RowID
							WHERE SRC_1.I_RowID IS NULL
								  AND ISNULL(TRG_1.B_Correcto, 0) = 0 
						  ) OBL 
						  ON OBS.I_FilaTablaID = OBL.I_RowID 
							 AND OBS.I_ProcedenciaID = OBL.I_ProcedenciaID
		 WHERE OBS.I_ObservID = @I_ObservID 
			   AND OBS.I_TablaID = @I_TablaID
			   AND OBS.I_FilaTablaID = @I_RowID


		SET @I_Observados = (SELECT COUNT(*) 
							   FROM TI_ObservacionRegistroTabla OBS 
									INNER JOIN TR_Ec_Obl OBL ON OBS.I_FilaTablaID = OBL.I_RowID 
																AND OBL.I_ProcedenciaID = OBS.I_ProcedenciaID
							  WHERE OBS.I_ObservID = @I_ObservID 
									AND OBS.I_ProcedenciaID = @I_RowID 
									AND OBS.B_Resuelto = 0)

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
		IF (@@TRANCOUNT > 0)
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

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_38_ObservacionPeriodoDetalle')
	DROP PROCEDURE [dbo].[USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_38_ObservacionPeriodoDetalle]
GO

CREATE PROCEDURE [dbo].[USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_38_ObservacionPeriodoDetalle]	
	@I_ProcedenciaID tinyint,
	@T_Anio		  varchar(4),
	@B_Resultado  bit output,
	@T_Message	  nvarchar(4000) OUTPUT	
AS
/*
	DESCRIPCION: Marcar TR_Ec_Obl con B_Migrable = 0 cuando la obligacion tiene conceptos que no estan migrados o no son migrables para el año y procedencia

	DECLARE @I_ProcedenciaID	tinyint = 1, 
	    	@T_Anio				varchar(4) = '2010',
			@B_Resultado		bit,
			@T_Message			nvarchar(4000)
	EXEC USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_38_ObservacionPeriodoDetalle @I_ProcedenciaID, @T_Anio, @B_Resultado output, @T_Message output
	SELECT @B_Resultado as resultado, @T_Message as mensaje
*/
BEGIN
	DECLARE @I_Observados int = 0
	DECLARE @D_FecProceso datetime = GETDATE() 
	DECLARE @I_ObservID int = 38,
			@I_ObservID_PerDes int = 44,
			@I_ObservID_PerPri int = 17
	
	DECLARE @I_TablaID int = 5,
			@I_TablaDetID int = 4

	BEGIN TRANSACTION
	BEGIN TRY

		SELECT Obl.*
		  INTO #temp_observados_detalle_periodo_cuota_concepto
		  FROM TR_Ec_Obl Obl
			   INNER JOIN TR_Ec_Det Det ON Obl.I_RowID = Det.I_OblRowID
			   INNER JOIN TI_ObservacionRegistroTabla OBS ON OBS.I_FilaTablaID = Det.I_RowID AND 
						  									 OBS.I_ProcedenciaID = Det.I_ProcedenciaID 
		 WHERE OBS.I_ObservID IN (@I_ObservID_PerDes, @I_ObservID_PerPri)
			   AND OBS.I_TablaID = @I_TablaDetID
			   AND OBS.B_Resuelto = 0										  


		UPDATE	Obl
		SET		B_Migrable = 0,
				D_FecEvalua = @D_FecProceso
		FROM    TR_Ec_Obl Obl
				INNER JOIN #temp_observados_detalle_periodo_cuota_concepto tmp ON Obl.I_RowID = tmp.I_RowID
		WHERE	
				Obl.I_ProcedenciaID = @I_ProcedenciaID
				AND Obl.Ano = @T_Anio


		MERGE TI_ObservacionRegistroTabla AS TRG
		USING (SELECT	DISTINCT @I_ObservID AS I_ObservID, @I_TablaID AS I_TablaID, Obl.I_RowID AS I_FilaTablaID, 
						@D_FecProceso AS D_FecRegistro, Obl.I_ProcedenciaID
				 FROM   TR_Ec_Obl Obl
						INNER JOIN #temp_observados_detalle_periodo_cuota_concepto tmp ON Obl.I_RowID = tmp.I_RowID
				WHERE	Obl.I_ProcedenciaID = @I_ProcedenciaID
						AND Obl.Ano = @T_Anio
			  ) AS SRC
		ON TRG.I_ObservID = SRC.I_ObservID AND TRG.I_TablaID = SRC.I_TablaID AND TRG.I_FilaTablaID = SRC.I_FilaTablaID
		WHEN MATCHED AND TRG.I_ProcedenciaID = @I_ProcedenciaID THEN
			UPDATE SET D_FecRegistro = SRC.D_FecRegistro, 
					   B_Resuelto = 0
		WHEN NOT MATCHED BY TARGET THEN
			INSERT (I_ObservID, I_TablaID, I_FilaTablaID, D_FecRegistro, I_ProcedenciaID, B_ObligProc)
			VALUES (SRC.I_ObservID, SRC.I_TablaID, SRC.I_FilaTablaID, SRC.D_FecRegistro, SRC.I_ProcedenciaID, 1);


		UPDATE OBS
		   SET D_FecResuelto = @D_FecProceso,
			   B_Resuelto = 1
		  FROM TI_ObservacionRegistroTabla OBS
			   INNER JOIN (SELECT TRG_1.Ano, TRG_1.P, TRG_1.I_Periodo, TRG_1.Cod_alu, TRG_1.Cod_rc, TRG_1.Cuota_pago, TRG_1.Fch_venc, 
								  TRG_1.Tipo_oblig, TRG_1.Monto, TRG_1.I_ProcedenciaID, SRC_1.I_RowID
							 FROM TR_Ec_Obl TRG_1
								  LEFT JOIN #temp_observados_detalle_periodo_cuota_concepto SRC_1 ON TRG_1.I_RowID = SRC_1.I_RowID
							WHERE SRC_1.I_RowID IS NULL
								  AND ISNULL(TRG_1.B_Correcto, 0) = 0 
						  ) OBL 
						  ON OBS.I_FilaTablaID = OBL.I_RowID
							 AND OBS.I_ProcedenciaID = OBL.I_ProcedenciaID
		 WHERE OBS.I_ObservID = @I_ObservID 
			   AND OBS.I_ProcedenciaID = @I_ProcedenciaID 
			   AND OBS.I_TablaID = @I_TablaID

		SET @I_Observados = (SELECT COUNT(*) 
							   FROM TI_ObservacionRegistroTabla OBS 
									INNER JOIN TR_Ec_Obl OBL ON OBS.I_FilaTablaID = OBL.I_RowID 
																AND OBL.I_ProcedenciaID = OBS.I_ProcedenciaID
							  WHERE OBS.I_ObservID = @I_ObservID 
									AND OBS.I_ProcedenciaID = @I_ProcedenciaID  
									AND OBS.I_TablaID = @I_TablaID 
									AND OBS.B_Resuelto = 0)

		SELECT @I_Observados as cant_obs, @D_FecProceso as fec_proceso		

		COMMIT TRANSACTION				
		SET @B_Resultado = 1
		SET @T_Message = '{ ' +
							 'Type: "summary", ' + 
							 'Title: "Obligaciones con concepto no migrado", ' + 
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
							 'Title: "Error", ' + 
							 'Value: "' + ERROR_MESSAGE() + ' (Linea: ' + CAST(ERROR_LINE() AS varchar(11)) + ')."'  +
						  '}]' 
	END CATCH
END
GO



IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_38_ObservacionPeriodoDetallePorOblID')
	DROP PROCEDURE [dbo].[USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_38_ObservacionPeriodoDetallePorOblID]
GO

CREATE PROCEDURE [dbo].[USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_38_ObservacionPeriodoDetallePorOblID]	
	@I_RowID	  int,
	@B_Resultado  bit OUTPUT,
	@T_Message	  nvarchar(4000) OUTPUT	
AS
/*
	DESCRIPCION: Marcar TR_Ec_Obl con B_Migrable = 0 cuando la obligacion tiene conceptos que no estan migrados o no son migrables para el Id de la obligacion

	DECLARE	@I_RowID	  int,
			@B_Resultado  bit,
			@T_Message	  nvarchar(4000)
	EXEC USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_38_ObservacionPeriodoDetalle @I_RowID, @B_Resultado output, @T_Message output
	SELECT @B_Resultado as resultado, @T_Message as mensaje
*/
BEGIN
	DECLARE @I_Observados int = 0
	DECLARE @D_FecProceso datetime = GETDATE() 
	DECLARE @I_ObservID int = 38,
			@I_ObservID_AnioDes int = 44,
			@I_ObservID_AnioPri int = 17
	
	DECLARE @I_TablaID int = 5,
			@I_TablaDetID int = 4

	BEGIN TRANSACTION
	BEGIN TRY

		SELECT Obl.*
		  INTO #temp_observados_detalle_periodo_cuota_concepto
		  FROM TR_Ec_Obl Obl
			   INNER JOIN TR_Ec_Det Det ON Obl.I_RowID = Det.I_OblRowID
			   INNER JOIN TI_ObservacionRegistroTabla OBS ON OBS.I_FilaTablaID = Det.I_RowID AND 
						  									 OBS.I_ProcedenciaID = Det.I_ProcedenciaID 
		 WHERE OBS.I_ObservID IN (@I_ObservID_AnioDes, @I_ObservID_AnioPri)
			   AND OBS.I_TablaID = @I_TablaDetID
			   AND OBS.B_Resuelto = 0										  


		UPDATE	Obl
		SET		B_Migrable = 0,
				D_FecEvalua = @D_FecProceso
		FROM    TR_Ec_Obl Obl
				INNER JOIN #temp_observados_detalle_periodo_cuota_concepto tmp ON Obl.I_RowID = tmp.I_RowID
		WHERE	Obl.I_RowID = @I_RowID


		MERGE TI_ObservacionRegistroTabla AS TRG
		USING (SELECT	DISTINCT @I_ObservID AS I_ObservID, @I_TablaID AS I_TablaID, Obl.I_RowID AS I_FilaTablaID, 
						@D_FecProceso AS D_FecRegistro, Obl.I_ProcedenciaID
				 FROM   TR_Ec_Obl Obl
						INNER JOIN #temp_observados_detalle_periodo_cuota_concepto tmp ON Obl.I_RowID = tmp.I_RowID
				WHERE	Obl.I_RowID = @I_RowID 
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
			   INNER JOIN (SELECT TRG_1.Ano, TRG_1.P, TRG_1.I_Periodo, TRG_1.Cod_alu, TRG_1.Cod_rc, TRG_1.Cuota_pago, TRG_1.Fch_venc, 
								  TRG_1.Tipo_oblig, TRG_1.Monto, TRG_1.I_ProcedenciaID, SRC_1.I_RowID
							 FROM TR_Ec_Obl TRG_1
								  LEFT JOIN #temp_observados_detalle_periodo_cuota_concepto SRC_1 ON TRG_1.I_RowID = SRC_1.I_RowID
							WHERE SRC_1.I_RowID IS NULL
								  AND ISNULL(TRG_1.B_Correcto, 0) = 0 
						  ) OBL 
						  ON OBS.I_FilaTablaID = OBL.I_RowID
							 AND OBS.I_ProcedenciaID = OBL.I_ProcedenciaID
		 WHERE OBS.I_ObservID = @I_ObservID 
			   AND OBS.I_TablaID = @I_TablaID
			   AND OBS.I_FilaTablaID = @I_RowID


		SET @I_Observados = (SELECT COUNT(*) 
							   FROM TI_ObservacionRegistroTabla OBS 
									INNER JOIN TR_Ec_Obl OBL ON OBS.I_FilaTablaID = OBL.I_RowID 
																AND OBL.I_ProcedenciaID = OBS.I_ProcedenciaID
							  WHERE OBS.I_ObservID = @I_ObservID 
									AND OBS.I_FilaTablaID = @I_RowID 
									AND OBS.B_Resuelto = 0)

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
		IF (@@TRANCOUNT > 0)
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
	DESCRIPCION: Marcar TR_Ec_Obl con B_Migrable = 0 cuando la obligacion tiene registros observados en el detalle para el año y procedencia

	DECLARE @I_ProcedenciaID	tinyint = 3, 
			@T_Anio		  varchar(4) = '2005',
			@B_Resultado  bit,
			@T_Message    nvarchar(4000)
	EXEC USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_39_DetalleObservado @I_ProcedenciaID, @T_Anio, @B_Resultado output, @T_Message output
	SELECT @B_Resultado as resultado, @T_Message as mensaje
*/
BEGIN
	DECLARE @I_Observados int = 0
	DECLARE @D_FecProceso datetime = GETDATE() 
	DECLARE @I_ObservID int = 39
	DECLARE @I_TablaID int = 5

	BEGIN TRANSACTION
	BEGIN TRY

		SELECT Obl.*
		  INTO #temp_observados_detalle
		  FROM TR_Ec_Obl Obl
		  	   INNER JOIN TR_Ec_Det Det ON Obl.I_RowID = Det.I_OblRowID
		 WHERE Det.B_Migrable = 0
		 	   AND Obl.Ano = @T_Anio
			   AND Obl.I_ProcedenciaID = @I_ProcedenciaID

		
		UPDATE Obl
		   SET B_Migrable = 0,
		   	   D_FecEvalua = @D_FecProceso 
		  FROM TR_Ec_Obl Obl
		  	   INNER JOIN #temp_observados_detalle tmp ON Obl.I_RowID = tmp.I_RowID
		 WHERE ISNULL(Obl.B_Correcto, 0) = 0


		MERGE TI_ObservacionRegistroTabla AS TRG
		USING 	(SELECT	@I_ObservID AS I_ObservID, @I_TablaID AS I_TablaID, Obl.I_RowID AS I_FilaTablaID, 
						@D_FecProceso AS D_FecRegistro, Obl.I_ProcedenciaID
				   FROM TR_Ec_Obl Obl
						INNER JOIN #temp_observados_detalle tmp ON Obl.I_RowID = tmp.I_RowID
				  WHERE ISNULL(Obl.B_Correcto, 0) = 0
				) AS SRC
		ON TRG.I_ObservID = SRC.I_ObservID AND TRG.I_TablaID = SRC.I_TablaID AND TRG.I_FilaTablaID = SRC.I_FilaTablaID
		WHEN MATCHED AND TRG.I_ProcedenciaID = @I_ProcedenciaID THEN
			UPDATE SET D_FecRegistro = SRC.D_FecRegistro, 
					   B_Resuelto = 0
		WHEN NOT MATCHED BY TARGET THEN
			INSERT (I_ObservID, I_TablaID, I_FilaTablaID, D_FecRegistro, I_ProcedenciaID, B_ObligProc)
			VALUES (SRC.I_ObservID, SRC.I_TablaID, SRC.I_FilaTablaID, SRC.D_FecRegistro, @I_ProcedenciaID, 1);


		UPDATE OBS
		   SET D_FecResuelto = @D_FecProceso,
		   	   B_Resuelto = 1
		  FROM TI_ObservacionRegistroTabla OBS
		  	   INNER JOIN (SELECT Obl.*, tmp.I_RowID as TmpRowID
			   				 FROM TR_Ec_Obl Obl
							 	  LEFT JOIN #temp_observados_detalle tmp ON Obl.I_RowID = tmp.I_RowID 
							WHERE tmp.I_RowID IS NULL
								  AND Obl.Ano = @T_Anio
								  AND Obl.I_ProcedenciaID = @I_ProcedenciaID
			   			  ) OBL ON OBS.I_FilaTablaID = OBL.I_RowID
						  		   AND OBS.I_ProcedenciaID = OBL.I_ProcedenciaID 
		 WHERE OBS.I_ObservID = @I_ObservID 
		 	   AND OBS.I_TablaID = @I_TablaID


		SET @I_Observados = (SELECT COUNT(*) 
							   FROM TI_ObservacionRegistroTabla OBS 
									INNER JOIN TR_Ec_Obl OBL ON OBS.I_FilaTablaID = OBL.I_RowID 
																AND OBL.I_ProcedenciaID = OBS.I_ProcedenciaID
							  WHERE OBS.I_ObservID = @I_ObservID 
									AND OBL.Ano = @T_Anio 
									AND OBL.I_ProcedenciaID = @I_ProcedenciaID 
									AND OBS.B_Resuelto = 0)

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
		IF (@@TRANCOUNT > 0)
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



IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_39_DetalleObservadoPorOblID')
	DROP PROCEDURE [dbo].[USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_39_DetalleObservadoPorOblID]
GO

CREATE PROCEDURE [dbo].[USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_39_DetalleObservadoPorOblID]	
	@I_RowID	  int,
	@B_Resultado  bit OUTPUT,
	@T_Message	  nvarchar(4000) OUTPUT	
AS
/*
	DESCRIPCION: Marcar TR_Ec_Obl con B_Migrable = 0 cuando la obligacion tiene conceptos que no estan migrados o no son migrables para el Id de la obligacion

	DECLARE	@I_RowID	  int,
			@B_Resultado  bit,
			@T_Message	  nvarchar(4000)
	EXEC USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_39_DetalleObservado @I_RowID, @B_Resultado output, @T_Message output
	SELECT @B_Resultado as resultado, @T_Message as mensaje
*/
BEGIN
	DECLARE @I_Observados int = 0
	DECLARE @D_FecProceso datetime = GETDATE() 
	DECLARE @I_ObservID int = 39
	DECLARE @I_TablaID int = 5

	BEGIN TRANSACTION
	BEGIN TRY

		SELECT Obl.*
		  INTO #temp_observados_detalle
		  FROM TR_Ec_Obl Obl
		  	   INNER JOIN TR_Ec_Det Det ON Obl.I_RowID = Det.I_OblRowID
		 WHERE Det.B_Migrable = 0
		 	   AND Obl.I_RowID = @I_RowID
		
		UPDATE Obl
		   SET B_Migrable = 0,
		   	   D_FecEvalua = @D_FecProceso 
		  FROM TR_Ec_Obl Obl
		  	   INNER JOIN #temp_observados_detalle tmp ON Obl.I_RowID = tmp.I_RowID
		 WHERE ISNULL(Obl.B_Correcto, 0) = 0


		MERGE TI_ObservacionRegistroTabla AS TRG
		USING 	(SELECT	@I_ObservID AS I_ObservID, @I_TablaID AS I_TablaID, Obl.I_RowID AS I_FilaTablaID, 
						@D_FecProceso AS D_FecRegistro, Obl.I_ProcedenciaID
				   FROM TR_Ec_Obl Obl
						INNER JOIN #temp_observados_detalle tmp ON Obl.I_RowID = tmp.I_RowID
				  WHERE ISNULL(Obl.B_Correcto, 0) = 0
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
		  	   INNER JOIN (SELECT Obl.*, tmp.I_RowID as TmpRowID
			   				 FROM TR_Ec_Obl Obl
							 	  LEFT JOIN #temp_observados_detalle tmp ON Obl.I_RowID = tmp.I_RowID 
							WHERE tmp.I_RowID IS NULL
								  AND Obl.I_RowID = @I_RowID
			   			  ) OBL ON OBS.I_FilaTablaID = OBL.I_RowID
						  		   AND OBS.I_ProcedenciaID = OBL.I_ProcedenciaID 
		 WHERE OBS.I_ObservID = @I_ObservID 
		 	   AND OBS.I_TablaID = @I_TablaID


		SET @I_Observados = (SELECT COUNT(*) 
							   FROM TI_ObservacionRegistroTabla OBS 
									INNER JOIN TR_Ec_Obl OBL ON OBS.I_FilaTablaID = OBL.I_RowID 
																AND OBL.I_ProcedenciaID = OBS.I_ProcedenciaID
							  WHERE OBS.I_ObservID = @I_ObservID 
									AND OBL.I_RowID = @I_RowID
									AND OBS.B_Resuelto = 0)

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
		IF (@@TRANCOUNT > 0)
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
	DESCRIPCION: Marcar TR_Ec_Obl con B_Migrable = 0 cuando la obligacion no tiene registros asociados en el detalle para el año y procedencia.

	DECLARE @I_ProcedenciaID	tinyint = 1, 
			@T_Anio		  varchar(4) = '2010',
			@B_Resultado  bit,
			@T_Message    nvarchar(4000)
	EXEC USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_40_ObligacionSinDetalle @I_ProcedenciaID, @T_Anio, @B_Resultado output, @T_Message output
	SELECT @B_Resultado as resultado, @T_Message as mensaje
*/
BEGIN
	DECLARE @I_Observados int = 0
	DECLARE @D_FecProceso datetime = GETDATE() 
	DECLARE @I_ObservID int = 40
	DECLARE @I_TablaID int = 5

	BEGIN TRANSACTION
	BEGIN TRY

		SELECT  I_OblRowID, COUNT(I_RowID) AS count_det
		  INTO	#temp_det_count_rows
		  FROM  TR_Ec_Det 
		 WHERE  Ano = @T_Anio 
		 		AND I_ProcedenciaID = @I_ProcedenciaID 
		GROUP BY I_OblRowID
		HAVING  COUNT(I_RowID) > 0


		UPDATE	Obl
		SET		B_Migrable = 0,
				D_FecEvalua = @D_FecProceso
		FROM    TR_Ec_Obl Obl
				LEFT JOIN #temp_det_count_rows tmp ON Obl.I_RowID = tmp.I_OblRowID
		WHERE	Obl.Ano = @T_Anio
				AND Obl.I_ProcedenciaID = @I_ProcedenciaID
				AND tmp.I_OblRowID IS NULL
					

		MERGE  TI_ObservacionRegistroTabla AS TRG
		USING  (SELECT @I_ObservID AS I_ObservID, @I_TablaID AS I_TablaID, Obl.I_RowID AS I_FilaTablaID, @D_FecProceso AS D_FecRegistro 
				  FROM TR_Ec_Obl Obl
					   LEFT JOIN #temp_det_count_rows tmp ON Obl.I_RowID = tmp.I_OblRowID
				 WHERE Obl.Ano = @T_Anio
					   AND Obl.I_ProcedenciaID = @I_ProcedenciaID
					   AND tmp.I_OblRowID IS NULL
				) AS SRC
		ON TRG.I_ObservID = SRC.I_ObservID AND TRG.I_TablaID = SRC.I_TablaID AND TRG.I_FilaTablaID = SRC.I_FilaTablaID
		WHEN MATCHED AND TRG.I_ProcedenciaID = @I_ProcedenciaID THEN
			UPDATE SET D_FecRegistro = SRC.D_FecRegistro, 
					   B_Resuelto = 0
		WHEN NOT MATCHED BY TARGET THEN
			INSERT (I_ObservID, I_TablaID, I_FilaTablaID, D_FecRegistro, I_ProcedenciaID, B_ObligProc)
			VALUES (SRC.I_ObservID, SRC.I_TablaID, SRC.I_FilaTablaID, SRC.D_FecRegistro, @I_ProcedenciaID, 1);


		UPDATE OBS
		   SET D_FecResuelto = @D_FecProceso,
		   	   B_Resuelto = 1
		  FROM TI_ObservacionRegistroTabla OBS
		  	   INNER JOIN (SELECT Obl.I_RowID, Obl.I_ProcedenciaID, tmp.I_OblRowID as TempRowID
			   				 FROM TR_Ec_Obl Obl
							      LEFT JOIN #temp_det_count_rows tmp ON Obl.I_RowID = tmp.I_OblRowID
							WHERE Obl.Ano = @T_Anio
								  AND Obl.I_ProcedenciaID = @I_ProcedenciaID
								  AND tmp.I_OblRowID IS NULL
			   			  ) OBL ON OBS.I_FilaTablaID = OBL.I_RowID
						  		   AND OBS.I_ProcedenciaID = OBL.I_ProcedenciaID 
		 WHERE OBS.I_ObservID = @I_ObservID 
		 	   AND OBS.I_TablaID = @I_TablaID
		

		SET @I_Observados = (SELECT COUNT(*) 
							   FROM TI_ObservacionRegistroTabla OBS 
									INNER JOIN TR_Ec_Obl OBL ON OBS.I_FilaTablaID = OBL.I_RowID 
																AND OBL.I_ProcedenciaID = OBS.I_ProcedenciaID
							  WHERE OBS.I_ObservID = @I_ObservID 
									AND OBL.Ano = @T_Anio 
									AND OBL.I_ProcedenciaID = @I_ProcedenciaID 
									AND OBS.B_Resuelto = 0
							)

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
		IF (@@TRANCOUNT > 0)
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


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_40_ObligacionSinDetallePorOblID')
	DROP PROCEDURE [dbo].[USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_40_ObligacionSinDetallePorOblID]
GO

CREATE PROCEDURE [dbo].[USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_40_ObligacionSinDetallePorOblID]
	@I_RowID	  int,
	@B_Resultado  bit output,
	@T_Message    nvarchar(4000) OUTPUT	
AS
/*
	DESCRIPCION: Marcar TR_Ec_Obl con B_Migrable = 0 cuando la obligacion no tiene registros asociados en el detalle para el ID de obligacion.

	DECLARE @I_RowID	  int,
			@B_Resultado  bit,
			@T_Message    nvarchar(4000)
	EXEC USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_40_ObligacionSinDetallePorOblID @I_RowID, @B_Resultado output, @T_Message output
	SELECT @B_Resultado as resultado, @T_Message as mensaje
*/
BEGIN
	DECLARE @I_Observados int = 0
	DECLARE @I_ObservadosObl int = 0
	DECLARE @D_FecProceso datetime = GETDATE() 
	DECLARE @I_ObservID int = 40
	DECLARE @I_TablaID int = 5

	BEGIN TRANSACTION
	BEGIN TRY

		SELECT  I_OblRowID, COUNT(I_RowID) AS count_det
		  INTO	#temp_det_count_rows
		  FROM  TR_Ec_Det 
		GROUP BY I_OblRowID
		HAVING  COUNT(I_RowID) > 0


		UPDATE	Obl
		SET		B_Migrable = 0,
				D_FecEvalua = @D_FecProceso
		FROM    TR_Ec_Obl Obl
				LEFT JOIN #temp_det_count_rows tmp ON Obl.I_RowID = tmp.I_OblRowID
		WHERE	Obl.I_RowID = @I_RowID
				AND tmp.I_OblRowID IS NULL
					

		MERGE  TI_ObservacionRegistroTabla AS TRG
		USING  (SELECT @I_ObservID AS I_ObservID, @I_TablaID AS I_TablaID, Obl.I_RowID AS I_FilaTablaID, 
					   @D_FecProceso AS D_FecRegistro, Obl.I_ProcedenciaID
				  FROM TR_Ec_Obl Obl
					   LEFT JOIN #temp_det_count_rows tmp ON Obl.I_RowID = tmp.I_OblRowID
				 WHERE Obl.I_RowID = @I_RowID
					   AND tmp.I_OblRowID IS NULL
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
		  	   INNER JOIN (SELECT Obl.I_RowID, Obl.I_ProcedenciaID, tmp.I_OblRowID as TempRowID
			   				 FROM TR_Ec_Obl Obl
							      LEFT JOIN #temp_det_count_rows tmp ON Obl.I_RowID = tmp.I_OblRowID
							WHERE Obl.I_RowID = @I_RowID
								  AND tmp.I_OblRowID IS NULL
			   			  ) OBL ON OBS.I_FilaTablaID = OBL.I_RowID
						  		   AND OBS.I_ProcedenciaID = OBL.I_ProcedenciaID 
		 WHERE OBS.I_ObservID = @I_ObservID 
		 	   AND OBS.I_TablaID = @I_TablaID 
			   AND OBS.I_FilaTablaID = @I_RowID 
		

		SET @I_Observados = (SELECT COUNT(*) 
							   FROM TI_ObservacionRegistroTabla OBS 
									INNER JOIN TR_Ec_Obl OBL ON OBS.I_FilaTablaID = OBL.I_RowID 
																AND OBL.I_ProcedenciaID = OBS.I_ProcedenciaID
							  WHERE OBS.I_ObservID = @I_ObservID 
									AND OBL.I_RowID = @I_RowID 
									AND OBS.B_Resuelto = 0
							)

		SELECT @I_Observados as cant_obs, @D_FecProceso as fec_proceso

		COMMIT TRANSACTION

		SET @B_Resultado = 1
		SET @T_Message = '{ ' +
							 'Type: "summary", ' + 
							 'Title: "Observados", ' + 
							 'Value: ' + CAST(@I_ObservadosObl AS varchar) +
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
							 'Title: "Error", ' + 
							 'Value: "' + ERROR_MESSAGE() + ' (Linea: ' + CAST(ERROR_LINE() AS varchar(11)) + ')."'  +
						  '}]' 
	END CATCH
END
GO



IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_54_PagoEnObligacionNoPagado')
	DROP PROCEDURE [dbo].[USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_54_PagoEnObligacionNoPagado]
GO

CREATE PROCEDURE [dbo].[USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_54_PagoEnObligacionNoPagado]
	@I_ProcedenciaID tinyint,
	@T_Anio			 varchar(4) = NULL,
	@B_Resultado	 bit output,
	@T_Message		 nvarchar(4000) OUTPUT	
AS
/*
	DESCRIPCION: Marcar TR_Ec_Obl con B_Migrable = 0 cuando se encontró un pago activo para la obligación con estado Pagado = NO para el año y procedencia.

	DECLARE @I_ProcedenciaID tinyint = 1, 
			@T_Anio		  	 varchar(4) = '2010',
			@B_Resultado  	 bit,
			@T_Message    	 nvarchar(4000)
	EXEC USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_54_PagoEnObligacionNoPagado @I_ProcedenciaID, @T_Anio, @B_Resultado output, @T_Message output
	SELECT @B_Resultado as resultado, @T_Message as mensaje
*/
BEGIN
	DECLARE @I_Observados int = 0
	DECLARE @D_FecProceso datetime = GETDATE() 
	DECLARE @I_ObservID int = 40
	DECLARE @I_TablaID int = 5

	BEGIN TRANSACTION
	BEGIN TRY

		SELECT  Obl.I_RowID
		  INTO	#temp_obl_pagado_no_con_pagos
		  FROM  TR_Ec_Obl Obl
		  		INNER JOIN TR_Ec_Det_Pagos Det_pg ON Obl.I_RowID = Det_pg.I_OblRowID
		 WHERE  Obl.Ano = @T_Anio 
		 		AND Obl.I_ProcedenciaID = @I_ProcedenciaID
				AND Obl.Pagado = 0
				AND Det_pg.Eliminado = 0			

		UPDATE	Obl
		SET		B_Migrable = 0,
				D_FecEvalua = @D_FecProceso
		FROM    TR_Ec_Obl Obl
				INNER JOIN #temp_obl_pagado_no_con_pagos tmp ON Obl.I_RowID = tmp.I_RowID
					

		MERGE  TI_ObservacionRegistroTabla AS TRG
		USING  (SELECT @I_ObservID AS I_ObservID, @I_TablaID AS I_TablaID, Obl.I_RowID AS I_FilaTablaID, @D_FecProceso AS D_FecRegistro 
				  FROM TR_Ec_Obl Obl
					   INNER JOIN #temp_obl_pagado_no_con_pagos tmp ON Obl.I_RowID = tmp.I_RowID
				) AS SRC
		ON TRG.I_ObservID = SRC.I_ObservID AND TRG.I_TablaID = SRC.I_TablaID AND TRG.I_FilaTablaID = SRC.I_FilaTablaID
		WHEN MATCHED AND TRG.I_ProcedenciaID = @I_ProcedenciaID THEN
			UPDATE SET D_FecRegistro = SRC.D_FecRegistro, 
					   B_Resuelto = 0
		WHEN NOT MATCHED BY TARGET THEN
			INSERT (I_ObservID, I_TablaID, I_FilaTablaID, D_FecRegistro, I_ProcedenciaID, B_ObligProc)
			VALUES (SRC.I_ObservID, SRC.I_TablaID, SRC.I_FilaTablaID, SRC.D_FecRegistro, @I_ProcedenciaID, 1);


		UPDATE OBS
		   SET D_FecResuelto = @D_FecProceso,
		   	   B_Resuelto = 1
		  FROM TI_ObservacionRegistroTabla OBS
		  	   INNER JOIN (SELECT Obl.I_RowID, Obl.I_ProcedenciaID, tmp.I_RowID as TempRowID
			   				 FROM TR_Ec_Obl Obl
							      LEFT JOIN #temp_obl_pagado_no_con_pagos tmp ON Obl.I_RowID = tmp.I_RowID
							WHERE Obl.Ano = @T_Anio
								  AND Obl.I_ProcedenciaID = @I_ProcedenciaID
								  AND tmp.I_RowID IS NULL
			   			  ) OBL ON OBS.I_FilaTablaID = OBL.I_RowID
						  		   AND OBS.I_ProcedenciaID = OBL.I_ProcedenciaID 
		 WHERE OBS.I_ObservID = @I_ObservID 
		 	   AND OBS.I_TablaID = @I_TablaID
		

		SET @I_Observados = (SELECT COUNT(*) 
							   FROM TI_ObservacionRegistroTabla OBS 
									INNER JOIN TR_Ec_Obl OBL ON OBS.I_FilaTablaID = OBL.I_RowID 
																AND OBL.I_ProcedenciaID = OBS.I_ProcedenciaID
							  WHERE OBS.I_ObservID = @I_ObservID 
									AND OBL.Ano = @T_Anio 
									AND OBL.I_ProcedenciaID = @I_ProcedenciaID 
									AND OBS.B_Resuelto = 0
							)

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
		IF (@@TRANCOUNT > 0)
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


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_54_PagoEnObligacionNoPagadoPorOblID')
	DROP PROCEDURE [dbo].[USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_54_PagoEnObligacionNoPagadoPorOblID]
GO

CREATE PROCEDURE [dbo].[USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_54_PagoEnObligacionNoPagadoPorOblID]
	@I_RowID	  int,
	@B_Resultado  bit output,
	@T_Message    nvarchar(4000) OUTPUT	
AS
/*
	DESCRIPCION: Marcar TR_Ec_Obl con B_Migrable = 0 cuando se encontró un pago activo para la obligación con estado Pagado = NO para el ID de obligacion.

	DECLARE @I_RowID	  int,
			@B_Resultado  bit,
			@T_Message    nvarchar(4000)
	EXEC USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_54_PagoEnObligacionNoPagadoPorOblID @I_RowID, @B_Resultado output, @T_Message output
	SELECT @B_Resultado as resultado, @T_Message as mensaje
*/
BEGIN
	DECLARE @I_Observados int = 0
	DECLARE @I_ObservadosObl int = 0
	DECLARE @D_FecProceso datetime = GETDATE() 
	DECLARE @I_ObservID int = 40
	DECLARE @I_TablaID int = 5

	BEGIN TRANSACTION
	BEGIN TRY

		SELECT  Obl.I_RowID
		  INTO	#temp_obl_pagado_no_con_pagos
		  FROM  TR_Ec_Obl Obl
		  		INNER JOIN TR_Ec_Det_Pagos Det_pg ON Obl.I_RowID = Det_pg.I_OblRowID
		 WHERE  Obl.I_RowID = @I_RowID
				AND Obl.Pagado = 0
				AND Det_pg.Eliminado = 0			

		UPDATE	Obl
		   SET	B_Migrable = 0,
				D_FecEvalua = @D_FecProceso
		  FROM  TR_Ec_Obl Obl
				INNER JOIN #temp_obl_pagado_no_con_pagos tmp ON Obl.I_RowID = tmp.I_RowID					

		MERGE  TI_ObservacionRegistroTabla AS TRG
		USING  (SELECT @I_ObservID AS I_ObservID, @I_TablaID AS I_TablaID, Obl.I_RowID AS I_FilaTablaID, 
					   @D_FecProceso AS D_FecRegistro, Obl.I_ProcedenciaID
				  FROM TR_Ec_Obl Obl
					   INNER JOIN #temp_obl_pagado_no_con_pagos tmp ON Obl.I_RowID = tmp.I_RowID
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
		  	   INNER JOIN (SELECT Obl.I_RowID, Obl.I_ProcedenciaID, tmp.I_RowID as TempRowID
			   				 FROM TR_Ec_Obl Obl
							      LEFT JOIN #temp_obl_pagado_no_con_pagos tmp ON Obl.I_RowID = tmp.I_RowID
							WHERE Obl.I_RowID = @I_RowID
								  AND tmp.I_RowID IS NULL
			   			  ) OBL ON OBS.I_FilaTablaID = OBL.I_RowID
						  		   AND OBS.I_ProcedenciaID = OBL.I_ProcedenciaID 
		 WHERE OBS.I_ObservID = @I_ObservID 
		 	   AND OBS.I_TablaID = @I_TablaID 
			   AND OBS.I_FilaTablaID = @I_RowID 
		

		SET @I_Observados = (SELECT COUNT(*) 
							   FROM TI_ObservacionRegistroTabla OBS 
									INNER JOIN TR_Ec_Obl OBL ON OBS.I_FilaTablaID = OBL.I_RowID 
																AND OBL.I_ProcedenciaID = OBS.I_ProcedenciaID
							  WHERE OBS.I_ObservID = @I_ObservID 
									AND OBL.I_RowID = @I_RowID 
									AND OBS.B_Resuelto = 0
							)

		SELECT @I_Observados as cant_obs, @D_FecProceso as fec_proceso

		COMMIT TRANSACTION

		SET @B_Resultado = 1
		SET @T_Message = '{ ' +
							 'Type: "summary", ' + 
							 'Title: "Observados", ' + 
							 'Value: ' + CAST(@I_ObservadosObl AS varchar) +
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
							 'Title: "Error", ' + 
							 'Value: "' + ERROR_MESSAGE() + ' (Linea: ' + CAST(ERROR_LINE() AS varchar(11)) + ')."'  +
						  '}]' 
	END CATCH
END
GO


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_59_ObligacionRepetida')
	DROP PROCEDURE [dbo].[USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_59_ObligacionRepetida]
GO

CREATE PROCEDURE [dbo].[USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_59_ObligacionRepetida]
	@I_ProcedenciaID tinyint,
	@T_Anio			 varchar(4) = NULL,
	@B_Resultado	 bit output,
	@T_Message		 nvarchar(4000) OUTPUT	
AS
/*
	DESCRIPCION: Marcar TR_Ec_Obl con B_Migrable = 0 cuando la cabecera de obligacion se encuentra duplicada para el año y procedencia.

	DECLARE @I_ProcedenciaID tinyint = 1, 
			@T_Anio		  	 varchar(4) = '2010',
			@B_Resultado  	 bit,
			@T_Message    	 nvarchar(4000)
	EXEC USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_59_ObligacionRepetida @I_ProcedenciaID, @T_Anio, @B_Resultado output, @T_Message output
	SELECT @B_Resultado as resultado, @T_Message as mensaje
*/
BEGIN
	DECLARE @I_Observados int = 0
	DECLARE @D_FecProceso datetime = GETDATE() 
	DECLARE @I_ObservID int = 59
	DECLARE @I_TablaID int = 5

	BEGIN TRANSACTION
	BEGIN TRY

		SELECT  Obl.I_RowID
		  INTO	#temp_obl_duplicados
		  FROM  TR_Ec_Obl Obl
		  		INNER JOIN (SELECT Cuota_pago, Ano, P, Cod_alu, Cod_rc, Tipo_oblig, Fch_venc, Pagado, Monto, I_ProcedenciaID
		    				  FROM TR_Ec_Obl
							 WHERE Ano = @T_Anio
								   AND I_ProcedenciaID = @I_ProcedenciaID
							GROUP BY Cuota_pago, Ano, P, Cod_alu, Cod_rc, Tipo_oblig, Fch_venc, Pagado, Monto, I_ProcedenciaID
							HAVING COUNT(*) > 1) OBL1 ON OBL1.I_ProcedenciaID = Obl.I_ProcedenciaID
														AND OBL1.Cuota_pago = Obl.Cuota_pago
														AND OBL1.Ano = Obl.Ano
														AND OBL1.P = Obl.P
														AND OBL1.Cod_alu = Obl.Cod_alu
														AND OBL1.Cod_rc = Obl.Cod_rc
														AND OBL1.Tipo_oblig = Obl.Tipo_oblig
														AND OBL1.Fch_venc = Obl.Fch_venc
														AND OBL1.Pagado = Obl.Pagado
														AND OBL1.Monto = Obl.Monto		

		UPDATE	Obl
		SET		B_Migrable = 0,
				D_FecEvalua = @D_FecProceso
		FROM    TR_Ec_Obl Obl
				INNER JOIN #temp_obl_duplicados tmp ON Obl.I_RowID = tmp.I_RowID
		WHERE	ISNULL(Obl.B_Correcto, 0) = 0
			

		MERGE  TI_ObservacionRegistroTabla AS TRG
		USING  (SELECT @I_ObservID AS I_ObservID, @I_TablaID AS I_TablaID, Obl.I_RowID AS I_FilaTablaID, @D_FecProceso AS D_FecRegistro 
				  FROM TR_Ec_Obl Obl
					   INNER JOIN #temp_obl_duplicados tmp ON Obl.I_RowID = tmp.I_RowID
				 WHERE ISNULL(Obl.B_Correcto, 0) = 0
				) AS SRC
		ON TRG.I_ObservID = SRC.I_ObservID AND TRG.I_TablaID = SRC.I_TablaID AND TRG.I_FilaTablaID = SRC.I_FilaTablaID
		WHEN MATCHED AND TRG.I_ProcedenciaID = @I_ProcedenciaID THEN
			UPDATE SET D_FecRegistro = SRC.D_FecRegistro, 
					   B_Resuelto = 0
		WHEN NOT MATCHED BY TARGET THEN
			INSERT (I_ObservID, I_TablaID, I_FilaTablaID, D_FecRegistro, I_ProcedenciaID, B_ObligProc)
			VALUES (SRC.I_ObservID, SRC.I_TablaID, SRC.I_FilaTablaID, SRC.D_FecRegistro, @I_ProcedenciaID, 1);


		UPDATE OBS
		   SET D_FecResuelto = @D_FecProceso,
		   	   B_Resuelto = 1
		  FROM TI_ObservacionRegistroTabla OBS
		  	   INNER JOIN (SELECT Obl.I_RowID, Obl.I_ProcedenciaID, tmp.I_RowID as TempRowID
			   				 FROM TR_Ec_Obl Obl
							      LEFT JOIN #temp_obl_duplicados tmp ON Obl.I_RowID = tmp.I_RowID
							WHERE Obl.Ano = @T_Anio
								  AND Obl.I_ProcedenciaID = @I_ProcedenciaID
								  AND tmp.I_RowID IS NULL
			   			  ) OBL ON OBS.I_FilaTablaID = OBL.I_RowID
						  		   AND OBS.I_ProcedenciaID = OBL.I_ProcedenciaID 
		 WHERE OBS.I_ObservID = @I_ObservID 
		 	   AND OBS.I_TablaID = @I_TablaID
		

		SET @I_Observados = (SELECT COUNT(*) 
							   FROM TI_ObservacionRegistroTabla OBS 
									INNER JOIN TR_Ec_Obl OBL ON OBS.I_FilaTablaID = OBL.I_RowID 
																AND OBL.I_ProcedenciaID = OBS.I_ProcedenciaID
							  WHERE OBS.I_ObservID = @I_ObservID 
									AND OBL.Ano = @T_Anio 
									AND OBL.I_ProcedenciaID = @I_ProcedenciaID 
									AND OBS.B_Resuelto = 0
							)

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
		IF (@@TRANCOUNT > 0)
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


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_59_ObligacionRepetidaPorOblID')
	DROP PROCEDURE [dbo].[USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_59_ObligacionRepetidaPorOblID]
GO

CREATE PROCEDURE [dbo].[USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_59_ObligacionRepetidaPorOblID]
	@I_RowID	  int,
	@B_Resultado  bit output,
	@T_Message    nvarchar(4000) OUTPUT	
AS
/*
	DESCRIPCION: Marcar TR_Ec_Obl con B_Migrable = 0 cuando la cabecera de obligacion se encuentra duplicada para el ID de obligacion.

	DECLARE @I_RowID	  int,
			@B_Resultado  bit,
			@T_Message    nvarchar(4000)
	EXEC USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_59_ObligacionRepetidaPorOblID @I_RowID, @B_Resultado output, @T_Message output
	SELECT @B_Resultado as resultado, @T_Message as mensaje
*/
BEGIN
	DECLARE @I_Observados int = 0
	DECLARE @I_ObservadosObl int = 0
	DECLARE @D_FecProceso datetime = GETDATE() 
	DECLARE @I_ObservID int = 59
	DECLARE @I_TablaID int = 5

	BEGIN TRANSACTION
	BEGIN TRY
		SELECT  Obl.I_RowID
		  INTO	#temp_obl_duplicados
		  FROM  (SELECT * FROM TR_Ec_Obl WHERE I_RowID = @I_RowID) Obl
		  		INNER JOIN (SELECT Cuota_pago, Ano, P, Cod_alu, Cod_rc, Tipo_oblig, Fch_venc, Pagado, Monto, I_ProcedenciaID
		    				  FROM TR_Ec_Obl
							GROUP BY Cuota_pago, Ano, P, Cod_alu, Cod_rc, Tipo_oblig, Fch_venc, Pagado, Monto, I_ProcedenciaID
							HAVING COUNT(*) > 1) OBL1 ON OBL1.I_ProcedenciaID = Obl.I_ProcedenciaID
														AND OBL1.Cuota_pago = Obl.Cuota_pago
														AND OBL1.Ano = Obl.Ano
														AND OBL1.P = Obl.P
														AND OBL1.Cod_alu = Obl.Cod_alu
														AND OBL1.Cod_rc = Obl.Cod_rc
														AND OBL1.Tipo_oblig = Obl.Tipo_oblig
														AND OBL1.Fch_venc = Obl.Fch_venc
														AND OBL1.Pagado = Obl.Pagado
														AND OBL1.Monto = Obl.Monto		

		UPDATE	Obl
		SET		B_Migrable = 0,
				D_FecEvalua = @D_FecProceso
		FROM    TR_Ec_Obl Obl
				INNER JOIN #temp_obl_duplicados tmp ON Obl.I_RowID = tmp.I_RowID
		WHERE	ISNULL(Obl.B_Correcto, 0) = 0
			

		MERGE  TI_ObservacionRegistroTabla AS TRG
		USING  (SELECT @I_ObservID AS I_ObservID, @I_TablaID AS I_TablaID, Obl.I_RowID AS I_FilaTablaID, 
					   @D_FecProceso AS D_FecRegistro, Obl.I_ProcedenciaID
				  FROM TR_Ec_Obl Obl
					   INNER JOIN #temp_obl_duplicados tmp ON Obl.I_RowID = tmp.I_RowID
				 WHERE ISNULL(Obl.B_Correcto, 0) = 0
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
		  	   INNER JOIN (SELECT Obl.I_RowID, Obl.I_ProcedenciaID, tmp.I_RowID as TempRowID
			   				 FROM TR_Ec_Obl Obl
							      LEFT JOIN #temp_obl_duplicados tmp ON Obl.I_RowID = tmp.I_RowID
							WHERE Obl.I_RowID = @I_RowID
								  AND tmp.I_RowID IS NULL
			   			  ) OBL ON OBS.I_FilaTablaID = OBL.I_RowID
						  		   AND OBS.I_ProcedenciaID = OBL.I_ProcedenciaID 
		 WHERE OBS.I_ObservID = @I_ObservID 
		 	   AND OBS.I_TablaID = @I_TablaID 
			   AND OBS.I_FilaTablaID = @I_RowID 
		

		SET @I_Observados = (SELECT COUNT(*) 
							   FROM TI_ObservacionRegistroTabla OBS 
									INNER JOIN TR_Ec_Obl OBL ON OBS.I_FilaTablaID = OBL.I_RowID 
																AND OBL.I_ProcedenciaID = OBS.I_ProcedenciaID
							  WHERE OBS.I_ObservID = @I_ObservID 
									AND OBL.I_RowID = @I_RowID 
									AND OBS.B_Resuelto = 0
							)

		SELECT @I_Observados as cant_obs, @D_FecProceso as fec_proceso

		COMMIT TRANSACTION

		SET @B_Resultado = 1
		SET @T_Message = '{ ' +
							 'Type: "summary", ' + 
							 'Title: "Observados", ' + 
							 'Value: ' + CAST(@I_ObservadosObl AS varchar) +
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
							 'Title: "Error", ' + 
							 'Value: "' + ERROR_MESSAGE() + ' (Linea: ' + CAST(ERROR_LINE() AS varchar(11)) + ')."'  +
						  '}]' 
	END CATCH
END
GO


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_60_SinPagoEnObligacioPagada')
	DROP PROCEDURE [dbo].[USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_60_SinPagoEnObligacioPagada]
GO

CREATE PROCEDURE [dbo].[USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_60_SinPagoEnObligacioPagada]
	@I_ProcedenciaID tinyint,
	@T_Anio			 varchar(4) = NULL,
	@B_Resultado	 bit output,
	@T_Message		 nvarchar(4000) OUTPUT	
AS
/*
	DESCRIPCION: Marcar TR_Ec_Obl con B_Migrable = 0 cuando la cabecera de obligacion se encuentra duplicada para el año y procedencia.

	DECLARE @I_ProcedenciaID tinyint = 1, 
			@T_Anio		  	 varchar(4) = '2010',
			@B_Resultado  	 bit,
			@T_Message    	 nvarchar(4000)
	EXEC USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_60_SinPagoEnObligacioPagada @I_ProcedenciaID, @T_Anio, @B_Resultado output, @T_Message output
	SELECT @B_Resultado as resultado, @T_Message as mensaje
*/
BEGIN
	DECLARE @I_Observados int = 0
	DECLARE @D_FecProceso datetime = GETDATE() 
	DECLARE @I_ObservID int = 60
	DECLARE @I_TablaID int = 5

	BEGIN TRANSACTION
	BEGIN TRY

		SELECT  Obl.I_RowID
		  INTO	#temp_obl_pagado_no_sin_pagos
		  FROM  TR_Ec_Obl Obl
		  		LEFT JOIN TR_Ec_Det_Pagos Det_pg ON Obl.I_RowID = Det_pg.I_OblRowID 
		 WHERE	Det_pg.I_RowID IS NULL
				AND Obl.Ano = @T_Anio
				AND Obl.I_ProcedenciaID = @I_ProcedenciaID
				AND Obl.Pagado = 1

		UPDATE	Obl
		SET		B_Migrable = 0,
				D_FecEvalua = @D_FecProceso
		FROM    TR_Ec_Obl Obl
				INNER JOIN #temp_obl_pagado_no_sin_pagos tmp ON Obl.I_RowID = tmp.I_RowID
		WHERE	ISNULL(Obl.B_Correcto, 0) = 0
			

		MERGE  TI_ObservacionRegistroTabla AS TRG
		USING  (SELECT @I_ObservID AS I_ObservID, @I_TablaID AS I_TablaID, Obl.I_RowID AS I_FilaTablaID, @D_FecProceso AS D_FecRegistro 
				  FROM TR_Ec_Obl Obl
					   INNER JOIN #temp_obl_pagado_no_sin_pagos tmp ON Obl.I_RowID = tmp.I_RowID
				 WHERE ISNULL(Obl.B_Correcto, 0) = 0
				) AS SRC
		ON TRG.I_ObservID = SRC.I_ObservID AND TRG.I_TablaID = SRC.I_TablaID AND TRG.I_FilaTablaID = SRC.I_FilaTablaID
		WHEN MATCHED AND TRG.I_ProcedenciaID = @I_ProcedenciaID THEN
			UPDATE SET D_FecRegistro = SRC.D_FecRegistro, 
					   B_Resuelto = 0
		WHEN NOT MATCHED BY TARGET THEN
			INSERT (I_ObservID, I_TablaID, I_FilaTablaID, D_FecRegistro, I_ProcedenciaID, B_ObligProc)
			VALUES (SRC.I_ObservID, SRC.I_TablaID, SRC.I_FilaTablaID, SRC.D_FecRegistro, @I_ProcedenciaID, 1);


		UPDATE OBS
		   SET D_FecResuelto = @D_FecProceso,
		   	   B_Resuelto = 1
		  FROM TI_ObservacionRegistroTabla OBS
		  	   INNER JOIN (SELECT Obl.I_RowID, Obl.I_ProcedenciaID, tmp.I_RowID as TempRowID
			   				 FROM TR_Ec_Obl Obl
							      LEFT JOIN #temp_obl_pagado_no_sin_pagos tmp ON Obl.I_RowID = tmp.I_RowID
							WHERE Obl.Ano = @T_Anio
								  AND Obl.I_ProcedenciaID = @I_ProcedenciaID
								  AND tmp.I_RowID IS NULL
			   			  ) OBL ON OBS.I_FilaTablaID = OBL.I_RowID
						  		   AND OBS.I_ProcedenciaID = OBL.I_ProcedenciaID 
		 WHERE OBS.I_ObservID = @I_ObservID 
		 	   AND OBS.I_TablaID = @I_TablaID
		

		SET @I_Observados = (SELECT COUNT(*) 
							   FROM TI_ObservacionRegistroTabla OBS 
									INNER JOIN TR_Ec_Obl OBL ON OBS.I_FilaTablaID = OBL.I_RowID 
																AND OBL.I_ProcedenciaID = OBS.I_ProcedenciaID
							  WHERE OBS.I_ObservID = @I_ObservID 
									AND OBL.Ano = @T_Anio 
									AND OBL.I_ProcedenciaID = @I_ProcedenciaID 
									AND OBS.B_Resuelto = 0
							)

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
		IF (@@TRANCOUNT > 0)
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


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_60_SinPagoEnObligacioPagadaPorOblID')
	DROP PROCEDURE [dbo].[USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_60_SinPagoEnObligacioPagadaPorOblID]
GO

CREATE PROCEDURE [dbo].[USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_60_SinPagoEnObligacioPagadaPorOblID]
	@I_RowID	  int,
	@B_Resultado  bit output,
	@T_Message    nvarchar(4000) OUTPUT	
AS
/*
	DESCRIPCION: Marcar TR_Ec_Obl con B_Migrable = 0 cuando la cabecera de obligacion se encuentra duplicada para el ID de obligacion.

	DECLARE @I_RowID	  int,
			@B_Resultado  bit,
			@T_Message    nvarchar(4000)
	EXEC USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_60_SinPagoEnObligacioPagadaPorOblID @I_RowID, @B_Resultado output, @T_Message output
	SELECT @B_Resultado as resultado, @T_Message as mensaje
*/
BEGIN
	DECLARE @I_Observados int = 0
	DECLARE @I_ObservadosObl int = 0
	DECLARE @D_FecProceso datetime = GETDATE() 
	DECLARE @I_ObservID int = 60
	DECLARE @I_TablaID int = 5

	BEGIN TRANSACTION
	BEGIN TRY
		SELECT  Obl.I_RowID
		  INTO	#temp_obl_pagado_no_sin_pagos
		  FROM  TR_Ec_Obl Obl
		  		LEFT JOIN TR_Ec_Det_Pagos Det_pg ON Obl.I_RowID = Det_pg.I_OblRowID 
		 WHERE	Det_pg.I_RowID IS NULL
				AND Obl.I_RowID = @I_RowID
				AND Obl.Pagado = 1


		UPDATE	Obl
		SET		B_Migrable = 0,
				D_FecEvalua = @D_FecProceso
		FROM    TR_Ec_Obl Obl
				INNER JOIN #temp_obl_pagado_no_sin_pagos tmp ON Obl.I_RowID = tmp.I_RowID
		WHERE	ISNULL(Obl.B_Correcto, 0) = 0
			

		MERGE  TI_ObservacionRegistroTabla AS TRG
		USING  (SELECT @I_ObservID AS I_ObservID, @I_TablaID AS I_TablaID, Obl.I_RowID AS I_FilaTablaID, 
					   @D_FecProceso AS D_FecRegistro, Obl.I_ProcedenciaID
				  FROM TR_Ec_Obl Obl
					   INNER JOIN #temp_obl_pagado_no_sin_pagos tmp ON Obl.I_RowID = tmp.I_RowID
				 WHERE ISNULL(Obl.B_Correcto, 0) = 0
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
		  	   INNER JOIN (SELECT Obl.I_RowID, Obl.I_ProcedenciaID, tmp.I_RowID as TempRowID
			   				 FROM TR_Ec_Obl Obl
							      LEFT JOIN #temp_obl_pagado_no_sin_pagos tmp ON Obl.I_RowID = tmp.I_RowID
							WHERE Obl.I_RowID = @I_RowID
								  AND tmp.I_RowID IS NULL
			   			  ) OBL ON OBS.I_FilaTablaID = OBL.I_RowID
						  		   AND OBS.I_ProcedenciaID = OBL.I_ProcedenciaID 
		 WHERE OBS.I_ObservID = @I_ObservID 
		 	   AND OBS.I_TablaID = @I_TablaID 
			   AND OBS.I_FilaTablaID = @I_RowID 
		

		SET @I_Observados = (SELECT COUNT(*) 
							   FROM TI_ObservacionRegistroTabla OBS 
									INNER JOIN TR_Ec_Obl OBL ON OBS.I_FilaTablaID = OBL.I_RowID 
																AND OBL.I_ProcedenciaID = OBS.I_ProcedenciaID
							  WHERE OBS.I_ObservID = @I_ObservID 
									AND OBL.I_RowID = @I_RowID 
									AND OBS.B_Resuelto = 0
							)

		SELECT @I_Observados as cant_obs, @D_FecProceso as fec_proceso

		COMMIT TRANSACTION

		SET @B_Resultado = 1
		SET @T_Message = '{ ' +
							 'Type: "summary", ' + 
							 'Title: "Observados", ' + 
							 'Value: ' + CAST(@I_ObservadosObl AS varchar) +
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
							 'Title: "Error", ' + 
							 'Value: "' + ERROR_MESSAGE() + ' (Linea: ' + CAST(ERROR_LINE() AS varchar(11)) + ')."'  +
						  '}]' 
	END CATCH
END
GO



IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_61_MigracionMatricula')
	DROP PROCEDURE [dbo].[USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_61_MigracionMatricula]
GO

CREATE PROCEDURE [dbo].[USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_61_MigracionMatricula]
	@I_ProcedenciaID tinyint,
	@T_Anio			 varchar(4) = NULL,
	@B_Resultado	 bit output,
	@T_Message		 nvarchar(4000) OUTPUT	
AS
/*
	DESCRIPCION: Marcar TR_Ec_Obl con B_Migrable = 0 cuando la cabecera de obligacion no pudo ser migrada a la tabla TC_MatriculaAlumno para el año y procedencia.

	DECLARE @I_ProcedenciaID tinyint = 1, 
			@T_Anio		  	 varchar(4) = '2010',
			@B_Resultado  	 bit,
			@T_Message    	 nvarchar(4000)
	EXEC USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_61_MigracionMatricula @I_ProcedenciaID, @T_Anio, @B_Resultado output, @T_Message output
	SELECT @B_Resultado as resultado, @T_Message as mensaje
*/
BEGIN
	DECLARE @I_Observados int = 0
	DECLARE @D_FecProceso datetime = GETDATE() 
	DECLARE @I_ObservID int = 61
	DECLARE @I_TablaID int = 5

	BEGIN TRANSACTION
	BEGIN TRY

		UPDATE	Obl
		SET		B_Migrable = 0,
				D_FecEvalua = @D_FecProceso
		FROM    TR_Ec_Obl Obl
		WHERE	I_CtasMatTableRowID IS NULL
				AND B_Migrable = 1
				AND I_ProcedenciaID = @I_ProcedenciaID
				AND Ano = @T_Anio
			

		MERGE  TI_ObservacionRegistroTabla AS TRG
		USING  (SELECT @I_ObservID AS I_ObservID, @I_TablaID AS I_TablaID, Obl.I_RowID AS I_FilaTablaID, @D_FecProceso AS D_FecRegistro 
				  FROM TR_Ec_Obl Obl
				 WHERE I_CtasMatTableRowID IS NULL
					   AND B_Migrable = 1
					   AND I_ProcedenciaID = @I_ProcedenciaID
					   AND Ano = @T_Anio
				) AS SRC
		ON TRG.I_ObservID = SRC.I_ObservID AND TRG.I_TablaID = SRC.I_TablaID AND TRG.I_FilaTablaID = SRC.I_FilaTablaID
		WHEN MATCHED AND TRG.I_ProcedenciaID = @I_ProcedenciaID THEN
			UPDATE SET D_FecRegistro = SRC.D_FecRegistro, 
					   B_Resuelto = 0
		WHEN NOT MATCHED BY TARGET THEN
			INSERT (I_ObservID, I_TablaID, I_FilaTablaID, D_FecRegistro, I_ProcedenciaID, B_ObligProc)
			VALUES (SRC.I_ObservID, SRC.I_TablaID, SRC.I_FilaTablaID, SRC.D_FecRegistro, @I_ProcedenciaID, 1);


		UPDATE OBS
		   SET D_FecResuelto = @D_FecProceso,
		   	   B_Resuelto = 1
		  FROM TI_ObservacionRegistroTabla OBS
		  	   INNER JOIN (SELECT Obl.I_RowID, Obl.I_ProcedenciaID
			   				 FROM TR_Ec_Obl Obl
							WHERE Obl.I_CtasMatTableRowID IS NULL
								  AND Obl.B_Migrable = 1
								  AND I_ProcedenciaID = @I_ProcedenciaID
								  AND Ano = @T_Anio
			   			  ) OBL ON OBS.I_FilaTablaID = OBL.I_RowID
						  		   AND OBS.I_ProcedenciaID = OBL.I_ProcedenciaID 
		 WHERE OBS.I_ObservID = @I_ObservID 
		 	   AND OBS.I_TablaID = @I_TablaID
		

		SET @I_Observados = (SELECT COUNT(*) 
							   FROM TI_ObservacionRegistroTabla OBS 
									INNER JOIN TR_Ec_Obl OBL ON OBS.I_FilaTablaID = OBL.I_RowID 
																AND OBL.I_ProcedenciaID = OBS.I_ProcedenciaID
							  WHERE OBS.I_ObservID = @I_ObservID 
									AND OBL.Ano = @T_Anio 
									AND OBL.I_ProcedenciaID = @I_ProcedenciaID 
									AND OBS.B_Resuelto = 0
							)

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
		IF (@@TRANCOUNT > 0)
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


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_61_MigracionMatriculaPorOblID')
	DROP PROCEDURE [dbo].[USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_61_MigracionMatriculaPorOblID]
GO

CREATE PROCEDURE [dbo].[USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_61_MigracionMatriculaPorOblID]
	@I_RowID	  int,
	@B_Resultado  bit output,
	@T_Message    nvarchar(4000) OUTPUT	
AS
/*
	DESCRIPCION: Marcar TR_Ec_Obl con B_Migrable = 0 cuando la cabecera de obligacion se encuentra duplicada para el ID de obligacion.

	DECLARE @I_RowID	  int,
			@B_Resultado  bit,
			@T_Message    nvarchar(4000)
	EXEC USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_61_MigracionMatriculaPorOblID @I_RowID, @B_Resultado output, @T_Message output
	SELECT @B_Resultado as resultado, @T_Message as mensaje
*/
BEGIN
	DECLARE @I_Observados int = 0
	DECLARE @I_ObservadosObl int = 0
	DECLARE @D_FecProceso datetime = GETDATE() 
	DECLARE @I_ObservID int = 61
	DECLARE @I_TablaID int = 5

	BEGIN TRANSACTION
	BEGIN TRY

		UPDATE	Obl
		SET		B_Migrable = 0,
				D_FecEvalua = @D_FecProceso
		FROM    TR_Ec_Obl Obl
		WHERE	I_CtasMatTableRowID IS NULL
				AND B_Migrable = 1
				AND I_RowID = @I_RowID
			

		MERGE  TI_ObservacionRegistroTabla AS TRG
		USING  (SELECT @I_ObservID AS I_ObservID, @I_TablaID AS I_TablaID, Obl.I_RowID AS I_FilaTablaID, 
					   @D_FecProceso AS D_FecRegistro, Obl.I_ProcedenciaID
				  FROM TR_Ec_Obl Obl
				 WHERE I_CtasMatTableRowID IS NULL
					   AND B_Migrable = 1
					   AND I_RowID = @I_RowID
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
		  	   INNER JOIN (SELECT Obl.I_RowID, Obl.I_ProcedenciaID 
			   				 FROM TR_Ec_Obl Obl
							WHERE I_CtasMatTableRowID IS NULL
								   AND B_Migrable = 1
								   AND I_RowID = @I_RowID
			   			  ) OBL ON OBS.I_FilaTablaID = OBL.I_RowID
						  		   AND OBS.I_ProcedenciaID = OBL.I_ProcedenciaID 
		 WHERE OBS.I_ObservID = @I_ObservID 
		 	   AND OBS.I_TablaID = @I_TablaID 
			   AND OBS.I_FilaTablaID = @I_RowID 
		

		SET @I_Observados = (SELECT COUNT(*) 
							   FROM TI_ObservacionRegistroTabla OBS 
									INNER JOIN TR_Ec_Obl OBL ON OBS.I_FilaTablaID = OBL.I_RowID 
																AND OBL.I_ProcedenciaID = OBS.I_ProcedenciaID
							  WHERE OBS.I_ObservID = @I_ObservID 
									AND OBL.I_RowID = @I_RowID 
									AND OBS.B_Resuelto = 0
							)

		SELECT @I_Observados as cant_obs, @D_FecProceso as fec_proceso

		COMMIT TRANSACTION

		SET @B_Resultado = 1
		SET @T_Message = '{ ' +
							 'Type: "summary", ' + 
							 'Title: "Observados", ' + 
							 'Value: ' + CAST(@I_ObservadosObl AS varchar) +
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
							 'Title: "Error", ' + 
							 'Value: "' + ERROR_MESSAGE() + ' (Linea: ' + CAST(ERROR_LINE() AS varchar(11)) + ')."'  +
						  '}]' 
	END CATCH
END
GO



/*	
	===============================================================================================
		Validaciones para migracion de ec_det (solo obligaciones de pago)	
	===============================================================================================
*/ 



IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_Obligaciones_ObligacionDet_MigracionTP_U_Validar_15_AnioDetalleAnioConcepto')
	DROP PROCEDURE [dbo].[USP_Obligaciones_ObligacionDet_MigracionTP_U_Validar_15_AnioDetalleAnioConcepto]
GO


CREATE PROCEDURE [dbo].[USP_Obligaciones_ObligacionDet_MigracionTP_U_Validar_15_AnioDetalleAnioConcepto]	
(
	@I_ProcedenciaID tinyint,
	@T_Anio		  varchar(4),
	@B_Resultado  bit output,
	@T_Message	  nvarchar(4000) OUTPUT	
)
AS
/*
	DESCRIPCION: Marcar TR_Ec_Det con B_Migrable = 0 cuando el año del concepto en el detalle no coincide con el año del concepto en cp_pri.

	DECLARE	@B_Resultado  bit,
			@I_ProcedenciaID	tinyint = 2,
			@T_Anio				varchar(4) = '2016',
			@T_Message			nvarchar(4000)
	EXEC USP_Obligaciones_ObligacionDet_MigracionTP_U_Validar_15_AnioDetalleAnioConcepto @I_ProcedenciaID, @T_Anio, @B_Resultado output, @T_Message output
	SELECT @B_Resultado as resultado, @T_Message as mensaje
*/
BEGIN
	DECLARE @I_Observados int = 0
	DECLARE @D_FecProceso datetime = GETDATE() 
	DECLARE @I_ObservID int = 15
	DECLARE @I_TablaID int = 4

	BEGIN TRANSACTION
	BEGIN TRY 
		SELECT	Det.I_RowID 
		INTO	#temp_detalle_anio_no_anio_concepto
		FROM	TR_Ec_Det Det
				INNER JOIN TR_Cp_Pri Pri ON Det.Concepto = Pri.Id_cp
		WHERE	Det.Ano <> Pri.Ano

		UPDATE Det
		SET	B_Migrable = 0,
			D_FecEvalua = @D_FecProceso
		FROM TR_Ec_Det Det 
			 INNER JOIN #temp_detalle_anio_no_anio_concepto tmp ON tmp.I_RowID = Det.I_RowID
		WHERE Ano = @T_Anio
			  AND I_ProcedenciaID = @I_ProcedenciaID

		MERGE TI_ObservacionRegistroTabla AS TRG
		USING (SELECT @I_ObservID AS I_ObservID, @I_TablaID AS I_TablaID, Det.I_RowID AS I_FilaTablaID, @D_FecProceso AS D_FecRegistro 
				 FROM TR_Ec_Det Det
					  INNER JOIN #temp_detalle_anio_no_anio_concepto tmp ON tmp.I_RowID = Det.I_RowID
				WHERE Ano = @T_Anio
					  AND I_ProcedenciaID = @I_ProcedenciaID
			  ) AS SRC
		ON TRG.I_ObservID = SRC.I_ObservID AND TRG.I_TablaID = SRC.I_TablaID AND TRG.I_FilaTablaID = SRC.I_FilaTablaID
		WHEN MATCHED AND TRG.I_ProcedenciaID = @I_ProcedenciaID THEN
			UPDATE SET D_FecRegistro = SRC.D_FecRegistro, 
					   B_Resuelto = 0
		WHEN NOT MATCHED BY TARGET THEN
			INSERT (I_ObservID, I_TablaID, I_FilaTablaID, D_FecRegistro, I_ProcedenciaID, B_ObligProc)
			VALUES (SRC.I_ObservID, SRC.I_TablaID, SRC.I_FilaTablaID, SRC.D_FecRegistro, @I_ProcedenciaID, 1);		

		UPDATE OBS
		   SET D_FecResuelto = @D_FecProceso,
		   	   B_Resuelto = 1
		  FROM TI_ObservacionRegistroTabla OBS
		  	   INNER JOIN (SELECT Det.I_RowID, Det.I_ProcedenciaID, tmp.I_RowID as TempRowID
			   				 FROM TR_Ec_Det Det
								  LEFT JOIN #temp_detalle_anio_no_anio_concepto tmp ON tmp.I_RowID = Det.I_RowID
							WHERE tmp.I_RowID IS NULL
								  AND Ano = @T_Anio
								  AND I_ProcedenciaID = @I_ProcedenciaID
			   			  ) DET ON OBS.I_FilaTablaID = DET.I_RowID
						  		   AND OBS.I_ProcedenciaID = DET.I_ProcedenciaID 
		 WHERE OBS.I_ObservID = @I_ObservID 
		 	   AND OBS.I_TablaID = @I_TablaID 
			   AND OBS.I_ProcedenciaID = @I_ProcedenciaID
		

		SET @I_Observados = (SELECT COUNT(*) 
							   FROM TI_ObservacionRegistroTabla OBS 
									INNER JOIN TR_Ec_Det DET ON OBS.I_FilaTablaID = DET.I_RowID 
																AND DET.I_ProcedenciaID = OBS.I_ProcedenciaID
							  WHERE OBS.I_ObservID = @I_ObservID 
									AND DET.Ano = @T_Anio
									AND DET.I_ProcedenciaID = @I_ProcedenciaID 
									AND OBS.B_Resuelto = 0
							)

		SELECT @I_Observados as cant_obs, @D_FecProceso as fec_proceso

		COMMIT TRANSACTION;

		SET @B_Resultado = 1
		SET @T_Message = '{ ' +
							 'Type: "summary", ' + 
							 'Title: "Observados", ' + 
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
							 'Title: "Error", ' + 
							 'Value: "' + ERROR_MESSAGE() + ' (Linea: ' + CAST(ERROR_LINE() AS varchar(11)) + ')."'  +
						  '}]' 
	END CATCH
END
GO


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_Obligaciones_ObligacionDet_MigracionTP_U_Validar_15_AnioDetalleAnioConceptoPorOblID')
	DROP PROCEDURE [dbo].[USP_Obligaciones_ObligacionDet_MigracionTP_U_Validar_15_AnioDetalleAnioConceptoPorOblID]
GO

CREATE PROCEDURE [dbo].[USP_Obligaciones_ObligacionDet_MigracionTP_U_Validar_15_AnioDetalleAnioConceptoPorOblID]
	@I_OblRowID	  int,
	@B_Resultado  bit output,
	@T_Message    nvarchar(4000) OUTPUT	
AS
/*
	DESCRIPCION: Marcar TR_Ec_Obl con B_Migrable = 0 cuando el año del concepto en el detalle no coincide con el año del concepto en cp_pri para el ID de obligacion.

	DECLARE @I_OblRowID	  int,
			@B_Resultado  bit,
			@T_Message    nvarchar(4000)
	EXEC USP_Obligaciones_ObligacionDet_MigracionTP_U_Validar_15_AnioDetalleAnioConceptoPorOblID @I_OblRowID, @B_Resultado output, @T_Message output
	SELECT @B_Resultado as resultado, @T_Message as mensaje
*/
BEGIN
	DECLARE @I_Observados int = 0
	DECLARE @D_FecProceso datetime = GETDATE() 
	DECLARE @I_ObservID int = 15
	DECLARE @I_TablaID int = 4

	BEGIN TRANSACTION
	BEGIN TRY
		SELECT	Det.I_RowID 
		INTO	#temp_detalle_anio_no_anio_concepto
		FROM	TR_Ec_Det Det
				INNER JOIN TR_Cp_Pri Pri ON Det.Concepto = Pri.Id_cp
		WHERE	Det.Ano <> Pri.Ano

		UPDATE Det
		SET	B_Migrable = 0,
			D_FecEvalua = @D_FecProceso
		FROM TR_Ec_Det Det 
			 INNER JOIN #temp_detalle_anio_no_anio_concepto tmp ON tmp.I_RowID = Det.I_RowID
		WHERE I_OblRowID = @I_OblRowID

		MERGE TI_ObservacionRegistroTabla AS TRG
		USING (SELECT @I_ObservID AS I_ObservID, @I_TablaID AS I_TablaID, Det.I_RowID AS I_FilaTablaID, 
					  @D_FecProceso AS D_FecRegistro, Det.I_ProcedenciaID  
				 FROM TR_Ec_Det Det
					  INNER JOIN #temp_detalle_anio_no_anio_concepto tmp ON tmp.I_RowID = Det.I_RowID
				WHERE I_OblRowID = @I_OblRowID
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
		  	   INNER JOIN (SELECT Det.I_RowID, Det.I_ProcedenciaID, tmp.I_RowID as TempRowID
			   				 FROM TR_Ec_Det Det
								  LEFT JOIN #temp_detalle_anio_no_anio_concepto tmp ON tmp.I_RowID = Det.I_RowID
							WHERE tmp.I_RowID IS NULL
								  AND I_OblRowID = @I_OblRowID
			   			  ) DET ON OBS.I_FilaTablaID = DET.I_RowID
						  		   AND OBS.I_ProcedenciaID = DET.I_ProcedenciaID 
		 WHERE OBS.I_ObservID = @I_ObservID 
		 	   AND OBS.I_TablaID = @I_TablaID 
		

		SET @I_Observados = (SELECT COUNT(*) 
							   FROM TI_ObservacionRegistroTabla OBS 
									INNER JOIN TR_Ec_Det DET ON OBS.I_FilaTablaID = DET.I_RowID 
																AND DET.I_ProcedenciaID = OBS.I_ProcedenciaID
							  WHERE OBS.I_ObservID = @I_ObservID 
									AND DET.I_OblRowID = @I_OblRowID  
									AND OBS.B_Resuelto = 0
							)

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
		IF (@@TRANCOUNT > 0)
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


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_Obligaciones_ObligacionDet_MigracionTP_U_Validar_17_PeriodoDetallePeriodoConcepto')
	DROP PROCEDURE [dbo].[USP_Obligaciones_ObligacionDet_MigracionTP_U_Validar_17_PeriodoDetallePeriodoConcepto]
GO


CREATE PROCEDURE [dbo].[USP_Obligaciones_ObligacionDet_MigracionTP_U_Validar_17_PeriodoDetallePeriodoConcepto]	
(
	@I_ProcedenciaID tinyint,
	@T_Anio		  varchar(4),
	@B_Resultado  bit output,
	@T_Message	  nvarchar(4000) OUTPUT	
)
AS
/*
	DESCRIPCION: Marcar TR_Ec_Det con B_Migrable = 0 cuando el periodo del concepto en el detalle no coincide con el periodo del concepto en cp_pri.

	DECLARE	@B_Resultado  bit,
			@I_ProcedenciaID	tinyint = 2,
			@T_Anio				varchar(4) = '2016',
			@T_Message			nvarchar(4000)
	EXEC USP_Obligaciones_ObligacionDet_MigracionTP_U_Validar_17_PeriodoDetallePeriodoConcepto @I_ProcedenciaID, @T_Anio, @B_Resultado output, @T_Message output
	SELECT @B_Resultado as resultado, @T_Message as mensaje
*/
BEGIN
	DECLARE @I_Observados int = 0
	DECLARE @D_FecProceso datetime = GETDATE() 
	DECLARE @I_ObservID int = 17
	DECLARE @I_TablaID int = 4

	BEGIN TRANSACTION
	BEGIN TRY 
		SELECT	Det.I_RowID 
		INTO	#temp_detalle_periodo_no_periodo_concepto
		FROM	TR_Ec_Det Det
				INNER JOIN TR_Cp_Pri Pri ON Det.Concepto = Pri.Id_cp
		WHERE	Det.P <> Pri.P

		UPDATE Det
		SET	B_Migrable = 0,
			D_FecEvalua = @D_FecProceso
		FROM TR_Ec_Det Det 
			 INNER JOIN #temp_detalle_periodo_no_periodo_concepto tmp ON tmp.I_RowID = Det.I_RowID
		WHERE Ano = @T_Anio
			  AND I_ProcedenciaID = @I_ProcedenciaID

		MERGE TI_ObservacionRegistroTabla AS TRG
		USING (SELECT @I_ObservID AS I_ObservID, @I_TablaID AS I_TablaID, Det.I_RowID AS I_FilaTablaID, @D_FecProceso AS D_FecRegistro 
				 FROM TR_Ec_Det Det
					  INNER JOIN #temp_detalle_periodo_no_periodo_concepto tmp ON tmp.I_RowID = Det.I_RowID
				WHERE Ano = @T_Anio
					  AND I_ProcedenciaID = @I_ProcedenciaID
			  ) AS SRC
		ON TRG.I_ObservID = SRC.I_ObservID AND TRG.I_TablaID = SRC.I_TablaID AND TRG.I_FilaTablaID = SRC.I_FilaTablaID
		WHEN MATCHED AND TRG.I_ProcedenciaID = @I_ProcedenciaID THEN
			UPDATE SET D_FecRegistro = SRC.D_FecRegistro, 
					   B_Resuelto = 0
		WHEN NOT MATCHED BY TARGET THEN
			INSERT (I_ObservID, I_TablaID, I_FilaTablaID, D_FecRegistro, I_ProcedenciaID, B_ObligProc)
			VALUES (SRC.I_ObservID, SRC.I_TablaID, SRC.I_FilaTablaID, SRC.D_FecRegistro, @I_ProcedenciaID, 1);		

		UPDATE OBS
		   SET D_FecResuelto = @D_FecProceso,
		   	   B_Resuelto = 1
		  FROM TI_ObservacionRegistroTabla OBS
		  	   INNER JOIN (SELECT Det.I_RowID, Det.I_ProcedenciaID, tmp.I_RowID as TempRowID
			   				 FROM TR_Ec_Det Det
								  LEFT JOIN #temp_detalle_periodo_no_periodo_concepto tmp ON tmp.I_RowID = Det.I_RowID
							WHERE tmp.I_RowID IS NULL
								  AND Ano = @T_Anio
								  AND I_ProcedenciaID = @I_ProcedenciaID
			   			  ) DET ON OBS.I_FilaTablaID = DET.I_RowID
						  		   AND OBS.I_ProcedenciaID = DET.I_ProcedenciaID 
		 WHERE OBS.I_ObservID = @I_ObservID 
		 	   AND OBS.I_TablaID = @I_TablaID 
			   AND OBS.I_ProcedenciaID = @I_ProcedenciaID
		

		SET @I_Observados = (SELECT COUNT(*) 
							   FROM TI_ObservacionRegistroTabla OBS 
									INNER JOIN TR_Ec_Det DET ON OBS.I_FilaTablaID = DET.I_RowID 
																AND DET.I_ProcedenciaID = OBS.I_ProcedenciaID
							  WHERE OBS.I_ObservID = @I_ObservID 
									AND DET.Ano = @T_Anio
									AND DET.I_ProcedenciaID = @I_ProcedenciaID 
									AND OBS.B_Resuelto = 0
							)

		SELECT @I_Observados as cant_obs, @D_FecProceso as fec_proceso

		COMMIT TRANSACTION;

		SET @B_Resultado = 1
		SET @T_Message = '{ ' +
							 'Type: "summary", ' + 
							 'Title: "Observados", ' + 
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
							 'Title: "Error", ' + 
							 'Value: "' + ERROR_MESSAGE() + ' (Linea: ' + CAST(ERROR_LINE() AS varchar(11)) + ')."'  +
						  '}]' 
	END CATCH
END
GO


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_Obligaciones_ObligacionDet_MigracionTP_U_Validar_17_PeriodoDetallePeriodoConceptoPorOblID')
	DROP PROCEDURE [dbo].[USP_Obligaciones_ObligacionDet_MigracionTP_U_Validar_17_PeriodoDetallePeriodoConceptoPorOblID]
GO

CREATE PROCEDURE [dbo].[USP_Obligaciones_ObligacionDet_MigracionTP_U_Validar_17_PeriodoDetallePeriodoConceptoPorOblID]
	@I_OblRowID	  int,
	@B_Resultado  bit output,
	@T_Message    nvarchar(4000) OUTPUT	
AS
/*
	DESCRIPCION: Marcar TR_Ec_Obl con B_Migrable = 0 cuando el periodo del concepto en el detalle no coincide con el periodo del concepto en cp_pri para el ID de obligacion.

	DECLARE @I_OblRowID	  int,
			@B_Resultado  bit,
			@T_Message    nvarchar(4000)
	EXEC USP_Obligaciones_ObligacionDet_MigracionTP_U_Validar_17_PeriodoDetallePeriodoConceptoPorOblID @I_OblRowID, @B_Resultado output, @T_Message output
	SELECT @B_Resultado as resultado, @T_Message as mensaje
*/
BEGIN
	DECLARE @I_Observados int = 0
	DECLARE @D_FecProceso datetime = GETDATE() 
	DECLARE @I_ObservID int = 17
	DECLARE @I_TablaID int = 4

	BEGIN TRANSACTION
	BEGIN TRY
		SELECT	Det.I_RowID 
		INTO	#temp_detalle_periodo_no_periodo_concepto
		FROM	TR_Ec_Det Det
				INNER JOIN TR_Cp_Pri Pri ON Det.Concepto = Pri.Id_cp
		WHERE	Det.Ano <> Pri.Ano

		UPDATE Det
		SET	B_Migrable = 0,
			D_FecEvalua = @D_FecProceso
		FROM TR_Ec_Det Det 
			 INNER JOIN #temp_detalle_periodo_no_periodo_concepto tmp ON tmp.I_RowID = Det.I_RowID
		WHERE I_OblRowID = @I_OblRowID

		MERGE TI_ObservacionRegistroTabla AS TRG
		USING (SELECT @I_ObservID AS I_ObservID, @I_TablaID AS I_TablaID, Det.I_RowID AS I_FilaTablaID, 
					  @D_FecProceso AS D_FecRegistro, Det.I_ProcedenciaID  
				 FROM TR_Ec_Det Det
					  INNER JOIN #temp_detalle_periodo_no_periodo_concepto tmp ON tmp.I_RowID = Det.I_RowID
				WHERE I_OblRowID = @I_OblRowID
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
		  	   INNER JOIN (SELECT Det.I_RowID, Det.I_ProcedenciaID, tmp.I_RowID as TempRowID
			   				 FROM TR_Ec_Det Det
								  LEFT JOIN #temp_detalle_periodo_no_periodo_concepto tmp ON tmp.I_RowID = Det.I_RowID
							WHERE tmp.I_RowID IS NULL
								  AND I_OblRowID = @I_OblRowID
			   			  ) DET ON OBS.I_FilaTablaID = DET.I_RowID
						  		   AND OBS.I_ProcedenciaID = DET.I_ProcedenciaID 
		 WHERE OBS.I_ObservID = @I_ObservID 
		 	   AND OBS.I_TablaID = @I_TablaID 
		

		SET @I_Observados = (SELECT COUNT(*) 
							   FROM TI_ObservacionRegistroTabla OBS 
									INNER JOIN TR_Ec_Det DET ON OBS.I_FilaTablaID = DET.I_RowID 
																AND DET.I_ProcedenciaID = OBS.I_ProcedenciaID
							  WHERE OBS.I_ObservID = @I_ObservID 
									AND DET.I_OblRowID = @I_OblRowID  
									AND OBS.B_Resuelto = 0
							)

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
		IF (@@TRANCOUNT > 0)
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
	DESCRIPCION: Marcar TR_Ec_Det con B_Migrable = 0 cuando la obligacion asociada tiene estado B_Migrable = 0.

	DECLARE	@B_Resultado  bit,
			@I_ProcedenciaID	tinyint = 2,
			@T_Anio				varchar(4) = '2016',
			@T_Message			nvarchar(4000)
	EXEC USP_Obligaciones_ObligacionDet_MigracionTP_U_Validar_25_ObligacionCabID @I_ProcedenciaID, @T_Anio, @B_Resultado output, @T_Message output
	SELECT @B_Resultado as resultado, @T_Message as mensaje
*/
BEGIN
	DECLARE @I_Observados int = 0
	DECLARE @D_FecProceso datetime = GETDATE() 
	DECLARE @I_ObservID int = 25
	DECLARE @I_TablaID int = 4

	BEGIN TRANSACTION
	BEGIN TRY 
		SELECT	I_RowID 
		INTO	#temp_obl_no_migrable
		FROM	TR_Ec_Obl 
		WHERE	B_Migrable = 0
				AND Ano = @T_Anio
				AND I_ProcedenciaID = @I_ProcedenciaID

		UPDATE Det
		SET	B_Migrable = 0,
			D_FecEvalua = @D_FecProceso
		FROM TR_Ec_Det Det 
			 INNER JOIN #temp_obl_no_migrable tmp ON tmp.I_RowID = Det.I_OblRowID


		MERGE TI_ObservacionRegistroTabla AS TRG
		USING (SELECT @I_ObservID AS I_ObservID, @I_TablaID AS I_TablaID, Det.I_RowID AS I_FilaTablaID, @D_FecProceso AS D_FecRegistro 
				 FROM TR_Ec_Det Det
					  INNER JOIN #temp_obl_no_migrable tmp ON tmp.I_RowID = Det.I_OblRowID
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
		  	   INNER JOIN (SELECT Det.I_RowID, Det.I_ProcedenciaID, tmp.I_RowID as TempRowID
			   				 FROM TR_Ec_Det Det
								  LEFT JOIN #temp_obl_no_migrable tmp ON tmp.I_RowID = Det.I_OblRowID
							WHERE tmp.I_RowID IS NULL
							      AND Ano = @T_Anio
								  AND I_ProcedenciaID = @I_ProcedenciaID
			   			  ) DET ON OBS.I_FilaTablaID = DET.I_RowID
						  		   AND OBS.I_ProcedenciaID = DET.I_ProcedenciaID 
		 WHERE OBS.I_ObservID = @I_ObservID 
		 	   AND OBS.I_TablaID = @I_TablaID 
		

		SET @I_Observados = (SELECT COUNT(*) 
							   FROM TI_ObservacionRegistroTabla OBS 
									INNER JOIN TR_Ec_Det DET ON OBS.I_FilaTablaID = DET.I_RowID 
																AND DET.I_ProcedenciaID = OBS.I_ProcedenciaID
							  WHERE OBS.I_ObservID = @I_ObservID 
									AND DET.Ano = @T_Anio
									AND DET.I_ProcedenciaID = @I_ProcedenciaID 
									AND OBS.B_Resuelto = 0
							)

		SELECT @I_Observados as cant_obs, @D_FecProceso as fec_proceso

		COMMIT TRANSACTION;

		SET @B_Resultado = 1
		SET @T_Message = '{ ' +
							 'Type: "summary", ' + 
							 'Title: "Observados", ' + 
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
							 'Title: "Error", ' + 
							 'Value: "' + ERROR_MESSAGE() + ' (Linea: ' + CAST(ERROR_LINE() AS varchar(11)) + ')."'  +
						  '}]' 
	END CATCH
END
GO


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_Obligaciones_ObligacionDet_MigracionTP_U_Validar_25_ObligacionCabIDPorOblID')
	DROP PROCEDURE [dbo].[USP_Obligaciones_ObligacionDet_MigracionTP_U_Validar_25_ObligacionCabIDPorOblID]
GO

CREATE PROCEDURE [dbo].[USP_Obligaciones_ObligacionDet_MigracionTP_U_Validar_25_ObligacionCabIDPorOblID]
	@I_OblRowID	  int,
	@B_Resultado  bit output,
	@T_Message    nvarchar(4000) OUTPUT	
AS
/*
	DESCRIPCION: Marcar TR_Ec_Obl con B_Migrable = 0 cuando la obligacion no tiene registros asociados en el detalle para el ID de obligacion.

	DECLARE @I_OblRowID	  int,
			@B_Resultado  bit,
			@T_Message    nvarchar(4000)
	EXEC USP_Obligaciones_ObligacionDet_MigracionTP_U_Validar_25_ObligacionCabIDPorOblID @I_OblRowID, @B_Resultado output, @T_Message output
	SELECT @B_Resultado as resultado, @T_Message as mensaje
*/
BEGIN
	DECLARE @I_Observados int = 0
	DECLARE @D_FecProceso datetime = GETDATE() 
	DECLARE @I_ObservID int = 25
	DECLARE @I_TablaID int = 4

	BEGIN TRANSACTION
	BEGIN TRY
		SELECT	I_RowID 
		INTO	#temp_obl_no_migrable
		FROM	TR_Ec_Obl 
		WHERE	B_Migrable = 0
				

		UPDATE Det
		   SET B_Migrable = 0,
			   D_FecEvalua = @D_FecProceso
		  FROM TR_Ec_Det Det 
			   INNER JOIN #temp_obl_no_migrable tmp ON tmp.I_RowID = Det.I_OblRowID
		 WHERE Det.I_OblRowID = @I_OblRowID

		MERGE TI_ObservacionRegistroTabla AS TRG
		USING (SELECT @I_ObservID AS I_ObservID, @I_TablaID AS I_TablaID, Det.I_RowID AS I_FilaTablaID, 
					  @D_FecProceso AS D_FecRegistro, Det.I_ProcedenciaID 
				 FROM TR_Ec_Det Det
					  INNER JOIN #temp_obl_no_migrable tmp ON tmp.I_RowID = Det.I_OblRowID
				WHERE Det.I_OblRowID = @I_OblRowID
			  ) AS SRC
		ON TRG.I_ObservID = SRC.I_ObservID AND TRG.I_TablaID = SRC.I_TablaID AND TRG.I_FilaTablaID = SRC.I_FilaTablaID
		WHEN MATCHED THEN
			UPDATE SET D_FecRegistro = SRC.D_FecRegistro, 
					   B_Resuelto = 0
		WHEN NOT MATCHED BY TARGET THEN
			INSERT (I_ObservID, I_TablaID, I_FilaTablaID, D_FecRegistro, I_ProcedenciaID, B_ObligProc)
			VALUES (SRC.I_ObservID, SRC.I_TablaID, SRC.I_FilaTablaID, SRC.D_FecRegistro, SRC.I_ProcedenciaID, 1);
		

		UPDATE OBS
		   SET D_FecResuelto = @D_FecProceso,
		   	   B_Resuelto = 1
		  FROM TI_ObservacionRegistroTabla OBS
		  	   INNER JOIN (SELECT Det.I_RowID, Det.I_ProcedenciaID, tmp.I_RowID as TempRowID
			   				 FROM TR_Ec_Det Det
								  LEFT JOIN #temp_obl_no_migrable tmp ON tmp.I_RowID = Det.I_OblRowID
							WHERE tmp.I_RowID IS NULL
								  AND Det.I_OblRowID = @I_OblRowID
			   			  ) DET ON OBS.I_FilaTablaID = DET.I_RowID
						  		   AND OBS.I_ProcedenciaID = DET.I_ProcedenciaID 
		 WHERE OBS.I_ObservID = @I_ObservID 
		 	   AND OBS.I_TablaID = @I_TablaID 
		

		SET @I_Observados = (SELECT COUNT(*) 
							   FROM TI_ObservacionRegistroTabla OBS 
									INNER JOIN TR_Ec_Det DET ON OBS.I_FilaTablaID = DET.I_RowID 
																AND DET.I_ProcedenciaID = OBS.I_ProcedenciaID
							  WHERE OBS.I_ObservID = @I_ObservID 
									AND DET.I_OblRowID = @I_OblRowID 
									AND OBS.B_Resuelto = 0
							)

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
		IF (@@TRANCOUNT > 0)
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
	DESCRIPCION: Marcar TR_Ec_Det con B_Migrable = 0 cuando el detalle de pago tiene un concepto de pago sin migrar.

	DECLARE	@I_ProcedenciaID	tinyint = 2,
			@T_Anio				varchar(4) = '2016',
			@B_Resultado		bit,
			@T_Message			nvarchar(4000)
	EXEC USP_Obligaciones_ObligacionDet_MigracionTP_U_Validar_42_CuotaDetalleCuotaConcepto @I_ProcedenciaID, @T_Anio, @B_Resultado output, @T_Message output
	SELECT @B_Resultado as resultado, @T_Message as mensaje
*/

BEGIN
	DECLARE @I_Observados int = 0
	DECLARE @D_FecProceso datetime = GETDATE() 
	DECLARE @I_ObservID int = 33
	DECLARE @I_TablaID int = 4

	BEGIN TRANSACTION
	BEGIN TRY

		SELECT Det.I_RowID, Det.I_OblRowID, Det.Concepto, Pri.Id_cp, Pri.I_RowID AS I_PriRowID
		  INTO #temp_detalle_conceptos_sin_migrar
		  FROM TR_Ec_Det Det
			   INNER JOIN TR_Cp_Pri Pri ON Det.Concepto = Pri.Id_cp
		 WHERE Pri.B_Migrado = 0
			   AND Det.I_ProcedenciaID = @I_ProcedenciaID
			   AND Det.Ano = @T_Anio 

		UPDATE	Det
		SET		B_Migrable = 0,
				D_FecEvalua = @D_FecProceso
		FROM    TR_Ec_Det Det
				INNER JOIN #temp_detalle_conceptos_sin_migrar tmp ON Det.I_RowID = tmp.I_RowID
					
		MERGE TI_ObservacionRegistroTabla AS TRG
		USING 	(SELECT	@I_ObservID AS I_ObservID, @I_TablaID AS I_TablaID, Det.I_RowID AS I_FilaTablaID, 
						@D_FecProceso AS D_FecRegistro 
				   FROM TR_Ec_Det Det
						INNER JOIN #temp_detalle_conceptos_sin_migrar tmp ON Det.I_RowID = tmp.I_RowID
				 ) AS SRC
		ON TRG.I_ObservID = SRC.I_ObservID AND TRG.I_TablaID = SRC.I_TablaID AND TRG.I_FilaTablaID = SRC.I_FilaTablaID 
			AND TRG.I_ProcedenciaID = @I_ProcedenciaID
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
		  	   INNER JOIN (SELECT Det.I_RowID, Det.I_ProcedenciaID, tmp.I_RowID as TempRowID
			   				 FROM TR_Ec_Det Det
								  LEFT JOIN #temp_detalle_conceptos_sin_migrar tmp ON tmp.I_RowID = Det.I_OblRowID
							WHERE tmp.I_RowID IS NULL
								  AND Det.Ano = @T_Anio
								  AND Det.I_ProcedenciaID = @I_ProcedenciaID
			   			  ) DET ON OBS.I_FilaTablaID = DET.I_RowID
						  		   AND OBS.I_ProcedenciaID = DET.I_ProcedenciaID 
		 WHERE OBS.I_ObservID = @I_ObservID 
		 	   AND OBS.I_TablaID = @I_TablaID 
		

		SET @I_Observados = (SELECT COUNT(*) 
							   FROM TI_ObservacionRegistroTabla OBS 
									INNER JOIN TR_Ec_Det DET ON OBS.I_FilaTablaID = DET.I_RowID 
																AND DET.I_ProcedenciaID = OBS.I_ProcedenciaID
							  WHERE OBS.I_ObservID = @I_ObservID 
									AND OBS.B_Resuelto = 0
									AND DET.Ano = @T_Anio
									AND DET.I_ProcedenciaID = @I_ProcedenciaID 
							)

		SELECT @I_Observados as cant_obs, @D_FecProceso as fec_proceso		 

		COMMIT TRANSACTION			
		
		SET @B_Resultado = 1
		SET @T_Message = '{ ' +
							 'Type: "summary", ' + 
							 'Title: "Detalles con concepto no migrado", ' + 
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
							 'Title: "Error", ' + 
							 'Value: "' + ERROR_MESSAGE() + ' (Linea: ' + CAST(ERROR_LINE() AS varchar(11)) + ')."'  +
						  '}]' 
	END CATCH
END
GO


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_Obligaciones_ObligacionDet_MigracionTP_U_Validar_33_ConceptoPagoMigradoPorOblID')
	DROP PROCEDURE [dbo].[USP_Obligaciones_ObligacionDet_MigracionTP_U_Validar_33_ConceptoPagoMigradoPorOblID]
GO

CREATE PROCEDURE [dbo].[USP_Obligaciones_ObligacionDet_MigracionTP_U_Validar_33_ConceptoPagoMigradoPorOblID]	
	@I_OblRowID	  int,
	@B_Resultado  bit output,
	@T_Message	  nvarchar(4000) OUTPUT	
AS
/*
	DESCRIPCION: Marcar TR_Ec_Det con B_Migrable = 0 cuando el detalle de pago tiene un concepto de pago sin migrar.

	DECLARE @I_OblRowID	  int,
			@B_Resultado  bit,
			@T_Message	  nvarchar(4000)
	EXEC USP_Obligaciones_ObligacionDet_MigracionTP_U_Validar_33_ConceptoPagoMigradoPorOblID @I_OblRowID, @B_Resultado output, @T_Message output
	SELECT @B_Resultado as resultado, @T_Message as mensaje
*/

BEGIN
	DECLARE @I_Observados int = 0
	DECLARE @D_FecProceso datetime = GETDATE() 
	DECLARE @I_ObservID int = 33
	DECLARE @I_TablaID int = 4
	DECLARE @I_TablaOblID int = 5

	BEGIN TRANSACTION
	BEGIN TRY

		SELECT Det.I_RowID, Det.I_OblRowID, Det.Concepto, Pri.Id_cp, Pri.I_RowID AS I_PriRowID
		  INTO #temp_detalle_conceptos_sin_migrar
		  FROM TR_Ec_Det Det
			   INNER JOIN TR_Cp_Pri Pri ON Det.Concepto = Pri.Id_cp
		 WHERE Pri.B_Migrado = 0
			   AND Det.I_OblRowID = @I_OblRowID

		UPDATE	Det
		SET		B_Migrable = 0,
				D_FecEvalua = @D_FecProceso
		FROM    TR_Ec_Det Det
				INNER JOIN #temp_detalle_conceptos_sin_migrar tmp ON Det.I_RowID = tmp.I_RowID

					
		MERGE TI_ObservacionRegistroTabla AS TRG
		USING 	(SELECT	@I_ObservID AS I_ObservID, @I_TablaID AS I_TablaID, Det.I_RowID AS I_FilaTablaID, 
						@D_FecProceso AS D_FecRegistro, Det.I_ProcedenciaID 
				   FROM TR_Ec_Det Det
						INNER JOIN #temp_detalle_conceptos_sin_migrar tmp ON Det.I_RowID = tmp.I_RowID
				 ) AS SRC
		ON TRG.I_ObservID = SRC.I_ObservID AND TRG.I_TablaID = SRC.I_TablaID AND TRG.I_FilaTablaID = SRC.I_FilaTablaID 
			AND TRG.I_ProcedenciaID = SRC.I_ProcedenciaID
		WHEN MATCHED THEN
			UPDATE SET D_FecRegistro = SRC.D_FecRegistro, 
					   B_Resuelto = 0
		WHEN NOT MATCHED BY TARGET THEN
			INSERT (I_ObservID, I_TablaID, I_FilaTablaID, D_FecRegistro, I_ProcedenciaID, B_ObligProc)
			VALUES (SRC.I_ObservID, SRC.I_TablaID, SRC.I_FilaTablaID, SRC.D_FecRegistro, SRC.I_ProcedenciaID, 1);


		UPDATE OBS
		   SET D_FecResuelto = @D_FecProceso,
		   	   B_Resuelto = 1
		  FROM TI_ObservacionRegistroTabla OBS
		  	   INNER JOIN (SELECT Det.I_RowID, Det.I_ProcedenciaID, tmp.I_RowID as TempRowID
			   				 FROM TR_Ec_Det Det
								  LEFT JOIN #temp_detalle_conceptos_sin_migrar tmp ON tmp.I_RowID = Det.I_OblRowID
							WHERE tmp.I_RowID IS NULL
								  AND Det.I_OblRowID = @I_OblRowID
			   			  ) DET ON OBS.I_FilaTablaID = DET.I_RowID
						  		   AND OBS.I_ProcedenciaID = DET.I_ProcedenciaID 
		 WHERE OBS.I_ObservID = @I_ObservID 
		 	   AND OBS.I_TablaID = @I_TablaID 
		

		SET @I_Observados = (SELECT COUNT(*) 
							   FROM TI_ObservacionRegistroTabla OBS 
									INNER JOIN TR_Ec_Det DET ON OBS.I_FilaTablaID = DET.I_RowID 
																AND DET.I_ProcedenciaID = OBS.I_ProcedenciaID
							  WHERE OBS.I_ObservID = @I_ObservID 
									AND OBS.B_Resuelto = 0
									AND DET.I_OblRowID = @I_OblRowID
							)

		SELECT @I_Observados as cant_obs, @D_FecProceso as fec_proceso		 

		COMMIT TRANSACTION	
		
		SET @B_Resultado = 1
		SET @T_Message = '{ ' +
							 'Type: "summary", ' + 
							 'Title: "Detalles con concepto no migrado", ' + 
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
	DESCRIPCION: Marcar TR_Ec_Det con B_Migrable = 0 el concepto en el detalle de la obligación no existe en el catálogo de conceptos.

	DECLARE	@I_ProcedenciaID	tinyint = 2,
			@T_Anio				varchar(4) = '2016',
			@B_Resultado		bit,
			@T_Message			nvarchar(4000)
	EXEC USP_Obligaciones_ObligacionDet_MigracionTP_U_Validar_35_ConceptoPago @I_ProcedenciaID, @T_Anio, @B_Resultado output, @T_Message output
	SELECT @B_Resultado as resultado, @T_Message as mensaje
*/
BEGIN
	DECLARE @I_Observados int = 0
	DECLARE @D_FecProceso datetime = GETDATE() 
	DECLARE @I_ObservID int = 35
	DECLARE @I_TablaID int = 4

	BEGIN TRANSACTION
	BEGIN TRY 

		SELECT Det.I_RowID, Det.Concepto, Pri.Id_cp, Det.I_ProcedenciaID, Pri.I_ProcedenciaID AS I_ProcedenciaPriID
		  INTO #temp_detalle_concepto_no_existe
		  FROM TR_Ec_Det Det
			   LEFT JOIN TR_Cp_Pri Pri ON Det.Concepto = Pri.Id_cp
		 WHERE Pri.Id_cp is null
			   AND Det.I_ProcedenciaID = @I_ProcedenciaID
			   AND Det.Ano = @T_Anio

		UPDATE	Det
		SET		B_Migrable = 0,
				D_FecEvalua = @D_FecProceso
		FROM    TR_Ec_Det Det
				INNER JOIN #temp_detalle_concepto_no_existe tmp ON Det.I_RowID = tmp.I_RowID

					
		MERGE TI_ObservacionRegistroTabla AS TRG
		USING 	(SELECT	@I_ObservID AS I_ObservID, @I_TablaID AS I_TablaID, Det.I_RowID AS I_FilaTablaID, @D_FecProceso AS D_FecRegistro 
				   FROM TR_Ec_Det Det
						INNER JOIN #temp_detalle_concepto_no_existe tmp ON Det.I_RowID = tmp.I_RowID
				 ) AS SRC
		ON TRG.I_ObservID = SRC.I_ObservID AND TRG.I_TablaID = SRC.I_TablaID AND TRG.I_FilaTablaID = SRC.I_FilaTablaID
			 AND TRG.I_ProcedenciaID = @I_ProcedenciaID
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
		  	   INNER JOIN (SELECT Det.I_RowID, Det.I_ProcedenciaID, tmp.I_RowID as TempRowID
			   				 FROM TR_Ec_Det Det
								  LEFT JOIN #temp_detalle_concepto_no_existe tmp ON tmp.I_RowID = Det.I_RowID
							WHERE tmp.I_RowID IS NULL
								  AND Det.Ano = @T_Anio
								  AND Det.I_ProcedenciaID = @I_ProcedenciaID
			   			  ) DET ON OBS.I_FilaTablaID = DET.I_RowID
						  		   AND OBS.I_ProcedenciaID = DET.I_ProcedenciaID 
		 WHERE OBS.I_ObservID = @I_ObservID 
		 	   AND OBS.I_TablaID = @I_TablaID 
		

		SET @I_Observados = (SELECT COUNT(*) 
							   FROM TI_ObservacionRegistroTabla OBS 
									INNER JOIN TR_Ec_Det DET ON OBS.I_FilaTablaID = DET.I_RowID 
																AND DET.I_ProcedenciaID = OBS.I_ProcedenciaID
							  WHERE OBS.I_ObservID = @I_ObservID 
									AND Det.Ano = @T_Anio
									AND Det.I_ProcedenciaID = @I_ProcedenciaID 
									AND OBS.B_Resuelto = 0
							)

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


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_Obligaciones_ObligacionDet_MigracionTP_U_Validar_35_ConceptoPagoPorOblID')
	DROP PROCEDURE [dbo].[USP_Obligaciones_ObligacionDet_MigracionTP_U_Validar_35_ConceptoPagoPorOblID]
GO

CREATE PROCEDURE [dbo].[USP_Obligaciones_ObligacionDet_MigracionTP_U_Validar_35_ConceptoPagoPorOblID]	
	@I_OblRowID		int,
	@B_Resultado	bit output,
	@T_Message		nvarchar(4000) OUTPUT	
AS
/*
	DESCRIPCION: Marcar TR_Ec_Det con B_Migrable = 0 el concepto en el detalle de la obligación no existe en el catálogo de conceptos.

	DECLARE	@I_OblRowID	  int,
			@B_Resultado  bit,
			@T_Message			nvarchar(4000)
	EXEC USP_Obligaciones_ObligacionDet_MigracionTP_U_Validar_35_ConceptoPagoPorOblID @I_OblRowID, @B_Resultado output, @T_Message output
	SELECT @B_Resultado as resultado, @T_Message as mensaje
*/
BEGIN
	DECLARE @I_Observados int = 0
	DECLARE @D_FecProceso datetime = GETDATE() 
	DECLARE @I_ObservID int = 35
	DECLARE @I_TablaID int = 4

	BEGIN TRANSACTION
	BEGIN TRY

		SELECT Det.I_RowID, Det.Concepto, Pri.Id_cp, Det.I_ProcedenciaID, Pri.I_ProcedenciaID AS I_ProcedenciaPriID
		  INTO #temp_detalle_concepto_no_existe
		  FROM TR_Ec_Det Det
			   LEFT JOIN TR_Cp_Pri Pri ON Det.Concepto = Pri.Id_cp
		 WHERE Pri.Id_cp is null
			   AND Det.I_OblRowID = @I_OblRowID

		UPDATE	Det
		SET		B_Migrable = 0,
				D_FecEvalua = @D_FecProceso
		FROM    TR_Ec_Det Det
				INNER JOIN #temp_detalle_concepto_no_existe tmp ON Det.I_RowID = tmp.I_RowID

					
		MERGE TI_ObservacionRegistroTabla AS TRG
		USING 	(SELECT	@I_ObservID AS I_ObservID, @I_TablaID AS I_TablaID, Det.I_RowID AS I_FilaTablaID, 
						@D_FecProceso AS D_FecRegistro, Det.I_ProcedenciaID
				  FROM  TR_Ec_Det Det
						INNER JOIN #temp_detalle_concepto_no_existe tmp ON Det.I_RowID = tmp.I_RowID
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
		  	   INNER JOIN (SELECT Det.I_RowID, Det.I_ProcedenciaID, tmp.I_RowID as TempRowID
			   				 FROM TR_Ec_Det Det
								  LEFT JOIN #temp_detalle_concepto_no_existe tmp ON tmp.I_RowID = Det.I_RowID
							WHERE tmp.I_RowID IS NULL
								  AND Det.I_OblRowID = @I_OblRowID
			   			  ) DET ON OBS.I_FilaTablaID = DET.I_RowID
						  		   AND OBS.I_ProcedenciaID = DET.I_ProcedenciaID 
		 WHERE OBS.I_ObservID = @I_ObservID 
		 	   AND OBS.I_TablaID = @I_TablaID 


		SET @I_Observados = (SELECT COUNT(*) 
							   FROM TI_ObservacionRegistroTabla OBS 
									INNER JOIN TR_Ec_Det DET ON OBS.I_FilaTablaID = DET.I_RowID 
																AND DET.I_ProcedenciaID = OBS.I_ProcedenciaID
							  WHERE OBS.I_ObservID = @I_ObservID 
									AND Det.I_OblRowID = @I_OblRowID
									AND OBS.B_Resuelto = 0
							)

		SELECT @I_Observados as cant_obs_det, @D_FecProceso as fec_proceso

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


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_Obligaciones_ObligacionDet_MigracionTP_U_Validar_42_CuotaDetalleCuotaConcepto')
	DROP PROCEDURE [dbo].[USP_Obligaciones_ObligacionDet_MigracionTP_U_Validar_42_CuotaDetalleCuotaConcepto]
GO


CREATE PROCEDURE [dbo].[USP_Obligaciones_ObligacionDet_MigracionTP_U_Validar_42_CuotaDetalleCuotaConcepto]	
(
	@I_ProcedenciaID tinyint,
	@T_Anio		  varchar(4),
	@B_Resultado  bit output,
	@T_Message	  nvarchar(4000) OUTPUT	
)
AS
/*
	DESCRIPCION: Marcar TR_Ec_Det con B_Migrable = 0 cuando la cuota de pago del detalle no coincide con la cuota de pago del concepto.

	DECLARE	@I_ProcedenciaID tinyint = 2,
			@T_Anio			 varchar(4) = '2016',
			@B_Resultado	 bit,
			@T_Message		 nvarchar(4000)
	EXEC USP_Obligaciones_ObligacionDet_MigracionTP_U_Validar_42_CuotaDetalleCuotaConcepto @I_ProcedenciaID, @T_Anio, @B_Resultado output, @T_Message output
	SELECT @B_Resultado as resultado, @T_Message as mensaje
*/
BEGIN
	DECLARE @I_Observados int = 0
	DECLARE @I_ObservadosObl int = 0
	DECLARE @D_FecProceso datetime = GETDATE() 
	DECLARE @I_ObservID int = 42
	DECLARE @I_TablaID int = 4

	BEGIN TRANSACTION
	BEGIN TRY 
		SELECT  Det.I_RowID, I_OblRowID, Det.Cuota_pago, Concepto
		  INTO	#temp_detalle_cuota_concepto_cuota
		  FROM	TR_Ec_Det Det 
				INNER JOIN TR_Cp_Pri Pri ON Det.Concepto = Pri.Id_cp
		 WHERE	Det.Cuota_pago <> Pri.Cuota_pago
				AND Det.Ano = @T_Anio
				AND Det.I_ProcedenciaID = @I_ProcedenciaID

		UPDATE Det
		   SET B_Migrable = 0,
			   D_FecEvalua = @D_FecProceso
		  FROM TR_Ec_Det Det 
			   INNER JOIN #temp_detalle_cuota_concepto_cuota tmp ON tmp.I_RowID = Det.I_RowID

		MERGE TI_ObservacionRegistroTabla AS TRG
		USING (SELECT @I_ObservID AS I_ObservID, @I_TablaID AS I_TablaID, Det.I_RowID AS I_FilaTablaID, 
					  @D_FecProceso AS D_FecRegistro, Det.I_ProcedenciaID 
				 FROM TR_Ec_Det Det
					  INNER JOIN #temp_detalle_cuota_concepto_cuota tmp ON Det.I_RowID = tmp.I_RowID
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
		  	   INNER JOIN (SELECT Det.I_RowID, Det.I_ProcedenciaID, tmp.I_RowID as TempRowID
			   				 FROM TR_Ec_Det Det
								  LEFT JOIN #temp_detalle_cuota_concepto_cuota tmp ON tmp.I_RowID = Det.I_RowID
							WHERE tmp.I_RowID IS NULL
								  AND Det.Ano = @T_Anio
								  AND Det.I_ProcedenciaID = @I_ProcedenciaID
			   			  ) DET ON OBS.I_FilaTablaID = DET.I_RowID
						  		   AND OBS.I_ProcedenciaID = DET.I_ProcedenciaID 
		 WHERE OBS.I_ObservID = @I_ObservID 
		 	   AND OBS.I_TablaID = @I_TablaID 
		

		SET @I_Observados = (SELECT COUNT(*) 
							   FROM TI_ObservacionRegistroTabla OBS 
									INNER JOIN TR_Ec_Det DET ON OBS.I_FilaTablaID = DET.I_RowID 
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
							 'Title: "Observados", ' + 
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
							 'Title: "Error", ' + 
							 'Value: "' + ERROR_MESSAGE() + ' (Linea: ' + CAST(ERROR_LINE() AS varchar(11)) + ')."'  +
						  '}]' 
	END CATCH
END
GO


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_Obligaciones_ObligacionDet_MigracionTP_U_Validar_42_CuotaDetalleCuotaConceptoPorOblID')
	DROP PROCEDURE [dbo].[USP_Obligaciones_ObligacionDet_MigracionTP_U_Validar_42_CuotaDetalleCuotaConceptoPorOblID]
GO

CREATE PROCEDURE [dbo].[USP_Obligaciones_ObligacionDet_MigracionTP_U_Validar_42_CuotaDetalleCuotaConceptoPorOblID]
	@I_OblRowID	  int,
	@B_Resultado  bit output,
	@T_Message    nvarchar(4000) OUTPUT	
AS
/*
	DESCRIPCION: Marcar TR_Ec_Obl con B_Migrable = 0 cuando la obligacion no tiene registros asociados en el detalle para el ID de obligacion.

	DECLARE @I_OblRowID	  int,
			@B_Resultado  bit,
			@T_Message    nvarchar(4000)
	EXEC USP_Obligaciones_ObligacionDet_MigracionTP_U_Validar_42_CuotaDetalleCuotaConceptoPorOblID @I_OblRowID, @B_Resultado output, @T_Message output
	SELECT @B_Resultado as resultado, @T_Message as mensaje
*/
BEGIN
	DECLARE @I_Observados int = 0
	DECLARE @I_ObservadosObl int = 0
	DECLARE @D_FecProceso datetime = GETDATE() 
	DECLARE @I_ObservID int = 42
	DECLARE @I_TablaID int = 4

	BEGIN TRANSACTION
	BEGIN TRY

		SELECT  Det.I_RowID, I_OblRowID, Det.Cuota_pago, Concepto
		  INTO	#temp_detalle_cuota_concepto_cuota
		  FROM	TR_Ec_Det Det 
				INNER JOIN TR_Cp_Pri Pri ON Det.Concepto = Pri.Id_cp
		 WHERE	Det.Cuota_pago <> Pri.Cuota_pago

		UPDATE Det
		   SET B_Migrable = 0,
			   D_FecEvalua = @D_FecProceso
		  FROM TR_Ec_Det Det 
			   INNER JOIN #temp_detalle_cuota_concepto_cuota tmp ON tmp.I_RowID = Det.I_RowID
		 WHERE Det.I_OblRowID = @I_OblRowID

		MERGE TI_ObservacionRegistroTabla AS TRG
		USING (SELECT @I_ObservID AS I_ObservID, @I_TablaID AS I_TablaID, Det.I_RowID AS I_FilaTablaID, 
					  @D_FecProceso AS D_FecRegistro, Det.I_ProcedenciaID 
				 FROM TR_Ec_Det Det
					  INNER JOIN #temp_detalle_cuota_concepto_cuota tmp ON Det.I_RowID = tmp.I_RowID
				WHERE Det.I_OblRowID = @I_OblRowID
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
		  	   INNER JOIN (SELECT Det.I_RowID, Det.I_ProcedenciaID, tmp.I_RowID as TempRowID
			   				 FROM TR_Ec_Det Det
								  LEFT JOIN #temp_detalle_cuota_concepto_cuota tmp ON tmp.I_RowID = Det.I_OblRowID
							WHERE tmp.I_RowID IS NULL
								  AND Det.I_OblRowID = @I_OblRowID
			   			  ) DET ON OBS.I_FilaTablaID = DET.I_RowID
						  		   AND OBS.I_ProcedenciaID = DET.I_ProcedenciaID 
		 WHERE OBS.I_ObservID = @I_ObservID 
		 	   AND OBS.I_TablaID = @I_TablaID 
		

		SET @I_Observados = (SELECT COUNT(*) 
							   FROM TI_ObservacionRegistroTabla OBS 
									INNER JOIN TR_Ec_Det DET ON OBS.I_FilaTablaID = DET.I_RowID 
																AND DET.I_ProcedenciaID = OBS.I_ProcedenciaID
							  WHERE OBS.I_ObservID = @I_ObservID 
									AND Det.I_OblRowID = @I_OblRowID
									AND OBS.B_Resuelto = 0
							)

		SELECT @I_Observados as cant_obs, @D_FecProceso as fec_proceso		 

		COMMIT TRANSACTION

		SET @B_Resultado = 1
		SET @T_Message = '{ ' +
							 'Type: "summary", ' + 
							 'Title: "Observados", ' + 
							 'Value: ' + CAST(@I_ObservadosObl AS varchar) +
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
							 'Title: "Error", ' + 
							 'Value: "' + ERROR_MESSAGE() + ' (Linea: ' + CAST(ERROR_LINE() AS varchar(11)) + ')."'  +
						  '}]' 
	END CATCH
END
GO



IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_Obligaciones_ObligacionDet_MigracionTP_U_Validar_43_AnioDetalleNumerico')
	DROP PROCEDURE [dbo].[USP_Obligaciones_ObligacionDet_MigracionTP_U_Validar_43_AnioDetalleNumerico]
GO


CREATE PROCEDURE [dbo].[USP_Obligaciones_ObligacionDet_MigracionTP_U_Validar_43_AnioDetalleNumerico]	
(
	@I_ProcedenciaID tinyint,
	@B_Resultado  bit output,
	@T_Message	  nvarchar(4000) OUTPUT	
)
AS
/*
	DESCRIPCION: Marcar TR_Ec_Det con B_Migrable = 0 cuando el año en el detalle no es un valor válido

	DECLARE	@I_ProcedenciaID	tinyint = 2,
			@B_Resultado		bit,
			@T_Message			nvarchar(4000)
	EXEC USP_Obligaciones_ObligacionDet_MigracionTP_U_Validar_43_AnioDetalleNumerico @I_ProcedenciaID, @B_Resultado output, @T_Message output
	SELECT @B_Resultado as resultado, @T_Message as mensaje
*/
BEGIN
	DECLARE @I_Observados int = 0
	DECLARE @I_ObservadosObl int = 0
	DECLARE @D_FecProceso datetime = GETDATE() 
	DECLARE @I_ObservID int = 43
	DECLARE @I_TablaID int = 4

	BEGIN TRANSACTION
	BEGIN TRY 
		
		UPDATE	TR_Ec_Det
		SET		B_Migrable = 0,
				D_FecEvalua = @D_FecProceso
		WHERE	ISNUMERIC(Ano) = 0
				AND I_ProcedenciaID = @I_ProcedenciaID


		MERGE TI_ObservacionRegistroTabla AS TRG
		USING 	(SELECT	@I_ObservID AS I_ObservID, @I_TablaID AS I_TablaID, I_RowID AS I_FilaTablaID, @D_FecProceso AS D_FecRegistro 
				   FROM	TR_Ec_Det 
				  WHERE	ISNUMERIC(Ano) = 0 
						AND I_ProcedenciaID = @I_ProcedenciaID
				) AS SRC
		ON TRG.I_ObservID = SRC.I_ObservID AND TRG.I_TablaID = SRC.I_TablaID AND TRG.I_FilaTablaID = SRC.I_FilaTablaID
		WHEN MATCHED AND TRG.I_ProcedenciaID = @I_ProcedenciaID THEN
			UPDATE SET D_FecRegistro = SRC.D_FecRegistro, 
					   B_Resuelto = 0
		WHEN NOT MATCHED BY TARGET THEN
			INSERT (I_ObservID, I_TablaID, I_FilaTablaID, D_FecRegistro, I_ProcedenciaID, B_ObligProc)
			VALUES (SRC.I_ObservID, SRC.I_TablaID, SRC.I_FilaTablaID, SRC.D_FecRegistro, @I_ProcedenciaID, 1);


		UPDATE OBS
		   SET D_FecResuelto = @D_FecProceso,
			   B_Resuelto = 1
		  FROM TI_ObservacionRegistroTabla OBS
			   INNER JOIN (SELECT I_RowID, I_ProcedenciaID FROM TR_Ec_Det WHERE ISNUMERIC(Ano) = 1) DET
						   ON OBS.I_FilaTablaID = DET.I_RowID
							  AND OBS.I_ProcedenciaID = DET.I_ProcedenciaID
		 WHERE OBS.I_ObservID = @I_ObservID 
			   AND OBS.I_TablaID = @I_TablaID

		SET @I_Observados = (SELECT COUNT(*) FROM TI_ObservacionRegistroTabla 
											WHERE I_ObservID = @I_ObservID 
												  AND I_TablaID = @I_TablaID
												  AND I_ProcedenciaID = @I_ProcedenciaID
												  AND B_Resuelto = 0) 

		SELECT @I_Observados as cant_obs, @D_FecProceso as fec_proceso

		COMMIT TRANSACTION;

		SET @B_Resultado = 1
		SET @T_Message = '{ ' +
							 'Type: "summary", ' + 
							 'Title: "Observados", ' + 
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
							 'Title: "Error", ' + 
							 'Value: "' + ERROR_MESSAGE() + ' (Linea: ' + CAST(ERROR_LINE() AS varchar(11)) + ')."'  +
						  '}]' 
	END CATCH
END
GO


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_Obligaciones_ObligacionDet_MigracionTP_U_Validar_43_AnioDetalleNumericoPorOblID')
	DROP PROCEDURE [dbo].[USP_Obligaciones_ObligacionDet_MigracionTP_U_Validar_43_AnioDetalleNumericoPorOblID]
GO

CREATE PROCEDURE [dbo].[USP_Obligaciones_ObligacionDet_MigracionTP_U_Validar_43_AnioDetalleNumericoPorOblID]
	@I_OblRowID	  int,
	@B_Resultado  bit output,
	@T_Message    nvarchar(4000) OUTPUT	
AS
/*
	DESCRIPCION: Marcar TR_Ec_Obl con B_Migrable = 0 cuando el año en el detalle no es un valor válido para el ID de obligacion.

	DECLARE @I_OblRowID	  int,
			@B_Resultado  bit,
			@T_Message    nvarchar(4000)
	EXEC USP_Obligaciones_ObligacionDet_MigracionTP_U_Validar_43_AnioDetalleNumericoPorOblID @I_OblRowID, @B_Resultado output, @T_Message output
	SELECT @B_Resultado as resultado, @T_Message as mensaje
*/
BEGIN
	DECLARE @I_Observados int = 0
	DECLARE @I_ObservadosObl int = 0
	DECLARE @D_FecProceso datetime = GETDATE() 
	DECLARE @I_ObservID int = 40
	DECLARE @I_TablaID int = 4

	BEGIN TRANSACTION
	BEGIN TRY
		UPDATE	TR_Ec_Det
		SET		B_Migrable = 0,
				D_FecEvalua = @D_FecProceso
		WHERE	ISNUMERIC(Ano) = 0
				AND I_OblRowID = @I_OblRowID


		MERGE TI_ObservacionRegistroTabla AS TRG
		USING 	(SELECT	@I_ObservID AS I_ObservID, @I_TablaID AS I_TablaID, I_RowID AS I_FilaTablaID, I_ProcedenciaID, @D_FecProceso AS D_FecRegistro 
				   FROM	TR_Ec_Det 
				  WHERE	ISNUMERIC(Ano) = 0 
						AND I_OblRowID = @I_OblRowID
				) AS SRC
		ON TRG.I_ObservID = SRC.I_ObservID AND TRG.I_TablaID = SRC.I_TablaID AND TRG.I_FilaTablaID = SRC.I_FilaTablaID
		WHEN MATCHED THEN
			UPDATE SET D_FecRegistro = SRC.D_FecRegistro, 
					   B_Resuelto = 0
		WHEN NOT MATCHED BY TARGET THEN
			INSERT (I_ObservID, I_TablaID, I_FilaTablaID, D_FecRegistro, I_ProcedenciaID, B_ObligProc)
			VALUES (SRC.I_ObservID, SRC.I_TablaID, SRC.I_FilaTablaID, SRC.D_FecRegistro, SRC.I_ProcedenciaID, 1);


		UPDATE OBS
		   SET D_FecResuelto = @D_FecProceso,
			   B_Resuelto = 1
		  FROM TI_ObservacionRegistroTabla OBS
			   INNER JOIN (SELECT I_RowID, I_ProcedenciaID FROM TR_Ec_Det 
							WHERE ISNUMERIC(Ano) = 1 AND I_OblRowID = @I_OblRowID) DET
						   ON OBS.I_FilaTablaID = DET.I_RowID
							  AND OBS.I_ProcedenciaID = DET.I_ProcedenciaID
		 WHERE OBS.I_ObservID = @I_ObservID 
			   AND OBS.I_TablaID = @I_TablaID

		SET @I_Observados = (SELECT COUNT(*)
							   FROM TI_ObservacionRegistroTabla OBS
									INNER JOIN (SELECT I_RowID FROM TR_Ec_Det WHERE I_OblRowID = @I_OblRowID) DET ON DET.I_RowID = OBS.I_FilaTablaID
							  WHERE I_ObservID = @I_ObservID 
									AND I_TablaID = @I_TablaID
									AND B_Resuelto = 0) 

		SELECT @I_Observados as cant_obs, @D_FecProceso as fec_proceso

		COMMIT TRANSACTION

		SET @B_Resultado = 1
		SET @T_Message = '{ ' +
							 'Type: "summary", ' + 
							 'Title: "Observados", ' + 
							 'Value: ' + CAST(@I_ObservadosObl AS varchar) +
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
							 'Title: "Error", ' + 
							 'Value: "' + ERROR_MESSAGE() + ' (Linea: ' + CAST(ERROR_LINE() AS varchar(11)) + ')."'  +
						  '}]' 
	END CATCH
END
GO


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_Obligaciones_ObligacionDet_MigracionTP_U_Validar_44_PeriodoDetallePeriodoConcepto')
	DROP PROCEDURE [dbo].[USP_Obligaciones_ObligacionDet_MigracionTP_U_Validar_44_PeriodoDetallePeriodoConcepto]
GO

CREATE PROCEDURE [dbo].[USP_Obligaciones_ObligacionDet_MigracionTP_U_Validar_44_PeriodoDetallePeriodoConcepto]	
(
	@I_ProcedenciaID tinyint,
	@T_Anio		  varchar(4),
	@B_Resultado  bit output,
	@T_Message	  nvarchar(4000) OUTPUT	
)
AS
/*
	DESCRIPCION: Marcar TR_Ec_Det con B_Migrable = 0 el periodo del detalle de la obligacion no tiene equivalencia en la base de datos de Ctas x cobrar.

	DECLARE	@B_Resultado  bit,
			@I_ProcedenciaID	tinyint = 2,
			@T_Anio				varchar(4) = '2016',
			@T_Message			nvarchar(4000)
	EXEC USP_Obligaciones_ObligacionDet_MigracionTP_U_Validar_44_PeriodoDetallePeriodoConcepto @I_ProcedenciaID, @T_Anio, @B_Resultado output, @T_Message output
	SELECT @B_Resultado as resultado, @T_Message as mensaje
*/
BEGIN
	DECLARE @I_Observados int = 0
	DECLARE @D_FecProceso datetime = GETDATE() 
	DECLARE @I_ObservID int = 44
	DECLARE @I_TablaID int = 4

	BEGIN TRANSACTION
	BEGIN TRY 
		SELECT I_RowID, I_OblRowID
		  INTO #temp_detalle_sin_periodo_equiv
		  FROM TR_Ec_Det Det
			   LEFT JOIN BD_OCEF_CtasPorCobrar.dbo.TC_CatalogoOpcion Ctas_Opc 
					  ON Det.P COLLATE SQL_Latin1_General_CP1_CI_AI = Ctas_opc.T_OpcionCod COLLATE SQL_Latin1_General_CP1_CI_AI
		 WHERE Ctas_Opc.I_OpcionID IS NULL
			   AND Ano = @T_Anio 
			   AND I_ProcedenciaID = @I_ProcedenciaID

		UPDATE	Det
		SET		B_Migrable = 0,
				D_FecEvalua = @D_FecProceso
		FROM	TR_Ec_Det Det
				INNER JOIN #temp_detalle_sin_periodo_equiv tmp ON tmp.I_RowID = Det.I_RowID

		MERGE TI_ObservacionRegistroTabla AS TRG
		USING (SELECT @I_ObservID AS I_ObservID, @I_TablaID AS I_TablaID, Det.I_RowID AS I_FilaTablaID, @D_FecProceso AS D_FecRegistro 
				 FROM TR_Ec_Det Det
					  INNER JOIN #temp_detalle_sin_periodo_equiv tmp ON tmp.I_RowID = Det.I_RowID
			  ) AS SRC
		ON TRG.I_ObservID = SRC.I_ObservID AND TRG.I_TablaID = SRC.I_TablaID AND TRG.I_FilaTablaID = SRC.I_FilaTablaID
		WHEN MATCHED AND TRG.I_ProcedenciaID = @I_ProcedenciaID THEN
			UPDATE SET D_FecRegistro = SRC.D_FecRegistro, 
					   B_Resuelto = 0
		WHEN NOT MATCHED BY TARGET THEN
			INSERT (I_ObservID, I_TablaID, I_FilaTablaID, D_FecRegistro, I_ProcedenciaID, B_ObligProc)
			VALUES (SRC.I_ObservID, SRC.I_TablaID, SRC.I_FilaTablaID, SRC.D_FecRegistro, @I_ProcedenciaID, 1);

		UPDATE OBS
		   SET D_FecResuelto = @D_FecProceso,
		   	   B_Resuelto = 1
		  FROM TI_ObservacionRegistroTabla OBS
		  	   INNER JOIN (SELECT Det.I_RowID, Det.I_ProcedenciaID, tmp.I_RowID as TempRowID
			   				 FROM TR_Ec_Det Det
								  LEFT JOIN #temp_detalle_sin_periodo_equiv tmp ON tmp.I_RowID = Det.I_RowID
							WHERE tmp.I_RowID IS NULL
								  AND Ano = @T_Anio 
								  AND I_ProcedenciaID = @I_ProcedenciaID
			   			  ) DET ON OBS.I_FilaTablaID = DET.I_RowID
						  		   AND OBS.I_ProcedenciaID = DET.I_ProcedenciaID 
		 WHERE OBS.I_ObservID = @I_ObservID 
		 	   AND OBS.I_TablaID = @I_TablaID 
			   AND OBS.I_ProcedenciaID = @I_ProcedenciaID

		SET @I_Observados = (SELECT COUNT(*) 
							   FROM TI_ObservacionRegistroTabla OBS 
									INNER JOIN TR_Ec_Det DET ON OBS.I_FilaTablaID = DET.I_RowID 
																AND DET.I_ProcedenciaID = OBS.I_ProcedenciaID
							  WHERE OBS.I_ObservID = @I_ObservID 
									AND DET.Ano = @T_Anio
									AND DET.I_ProcedenciaID = @I_ProcedenciaID 
									AND OBS.B_Resuelto = 0
							)

		SELECT @I_Observados as cant_obs, @D_FecProceso as fec_proceso

		COMMIT TRANSACTION;

		SET @B_Resultado = 1
		SET @T_Message = '{ ' +
							 'Type: "summary", ' + 
							 'Title: "Observados", ' + 
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
							 'Title: "Error", ' + 
							 'Value: "' + ERROR_MESSAGE() + ' (Linea: ' + CAST(ERROR_LINE() AS varchar(11)) + ')."'  +
						  '}]' 
	END CATCH
END
GO


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_Obligaciones_ObligacionDet_MigracionTP_U_Validar_44_PeriodoDetallePeriodoConceptoPorOblID')
	DROP PROCEDURE [dbo].[USP_Obligaciones_ObligacionDet_MigracionTP_U_Validar_44_PeriodoDetallePeriodoConceptoPorOblID]
GO

CREATE PROCEDURE [dbo].[USP_Obligaciones_ObligacionDet_MigracionTP_U_Validar_44_PeriodoDetallePeriodoConceptoPorOblID]
	@I_OblRowID	  int,
	@B_Resultado  bit output,
	@T_Message    nvarchar(4000) OUTPUT	
AS
/*
	DESCRIPCION: Marcar TR_Ec_Obl con B_Migrable = 0 cuando la obligacion no tiene registros asociados en el detalle para el ID de obligacion.

	DECLARE @I_OblRowID	  int,
			@B_Resultado  bit,
			@T_Message    nvarchar(4000)
	EXEC USP_Obligaciones_ObligacionDet_MigracionTP_U_Validar_44_PeriodoDetallePeriodoConceptoPorOblID @I_OblRowID, @B_Resultado output, @T_Message output
	SELECT @B_Resultado as resultado, @T_Message as mensaje
*/
BEGIN
	DECLARE @I_Observados int = 0
	DECLARE @I_ObservadosObl int = 0
	DECLARE @D_FecProceso datetime = GETDATE() 
	DECLARE @I_ObservID int = 44
	DECLARE @I_TablaID int = 4

	BEGIN TRANSACTION
	BEGIN TRY
		SELECT I_RowID, I_OblRowID
		  INTO #temp_detalle_sin_periodo_equiv
		  FROM TR_Ec_Det Det
			   LEFT JOIN BD_OCEF_CtasPorCobrar.dbo.TC_CatalogoOpcion Ctas_Opc 
					  ON Det.P COLLATE SQL_Latin1_General_CP1_CI_AI = Ctas_opc.T_OpcionCod COLLATE SQL_Latin1_General_CP1_CI_AI
		 WHERE Ctas_Opc.I_OpcionID IS NULL

		UPDATE	Det
		SET		B_Migrable = 0,
				D_FecEvalua = @D_FecProceso
		FROM	TR_Ec_Det Det
				INNER JOIN #temp_detalle_sin_periodo_equiv tmp ON tmp.I_RowID = Det.I_RowID
		WHERE	Det.I_OblRowID = @I_OblRowID

		MERGE TI_ObservacionRegistroTabla AS TRG
		USING (SELECT @I_ObservID AS I_ObservID, @I_TablaID AS I_TablaID, Det.I_RowID AS I_FilaTablaID, @D_FecProceso AS D_FecRegistro,  
					  Det.I_ProcedenciaID
				 FROM TR_Ec_Det Det
					  INNER JOIN #temp_detalle_sin_periodo_equiv tmp ON tmp.I_RowID = Det.I_RowID
				WHERE Det.I_OblRowID = @I_OblRowID
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
		  	   INNER JOIN (SELECT Det.I_RowID, Det.I_ProcedenciaID, tmp.I_RowID as TempRowID
			   				 FROM TR_Ec_Det Det
								  LEFT JOIN #temp_detalle_sin_periodo_equiv tmp ON tmp.I_RowID = Det.I_OblRowID
							WHERE tmp.I_RowID IS NULL
								  AND Det.I_OblRowID = @I_OblRowID
			   			  ) DET ON OBS.I_FilaTablaID = DET.I_RowID
						  		   AND OBS.I_ProcedenciaID = DET.I_ProcedenciaID 
		 WHERE OBS.I_ObservID = @I_ObservID 
		 	   AND OBS.I_TablaID = @I_TablaID 

		SET @I_Observados = (SELECT COUNT(*) 
							   FROM TI_ObservacionRegistroTabla OBS 
									INNER JOIN TR_Ec_Det DET ON OBS.I_FilaTablaID = DET.I_RowID 
																AND DET.I_ProcedenciaID = OBS.I_ProcedenciaID
							  WHERE OBS.I_ObservID = @I_ObservID 
									AND DET.I_OblRowID = @I_OblRowID
									AND OBS.B_Resuelto = 0
							)

		SELECT @I_Observados as cant_obs, @D_FecProceso as fec_proceso

		COMMIT TRANSACTION

		SET @B_Resultado = 1
		SET @T_Message = '{ ' +
							 'Type: "summary", ' + 
							 'Title: "Observados", ' + 
							 'Value: ' + CAST(@I_ObservadosObl AS varchar) +
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
							 'Title: "Error", ' + 
							 'Value: "' + ERROR_MESSAGE() + ' (Linea: ' + CAST(ERROR_LINE() AS varchar(11)) + ')."'  +
						  '}]' 
	END CATCH
END
GO



IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_Obligaciones_ObligacionDet_MigracionTP_U_Validar_49_MontoDetalleMontoCab')
	DROP PROCEDURE [dbo].[USP_Obligaciones_ObligacionDet_MigracionTP_U_Validar_49_MontoDetalleMontoCab]
GO

CREATE PROCEDURE [dbo].[USP_Obligaciones_ObligacionDet_MigracionTP_U_Validar_49_MontoDetalleMontoCab]	
(
	@I_ProcedenciaID tinyint,
	@T_Anio		  varchar(4),
	@B_Resultado  bit output,
	@T_Message	  nvarchar(4000) OUTPUT	
)
AS
/*
	DESCRIPCION: Marcar TR_Ec_Det con B_Migrable = 0 cuando la suma de los montos en el detalle no coinciden con el monto de la cabecera para el año y procedencia.

	DECLARE	@B_Resultado  bit,
			@I_ProcedenciaID	tinyint = 2,
			@T_Anio				varchar(4) = '2016',
			@T_Message			nvarchar(4000)
	EXEC USP_Obligaciones_ObligacionDet_MigracionTP_U_Validar_49_MontoDetalleMontoCab @I_ProcedenciaID, @T_Anio, @B_Resultado output, @T_Message output
	SELECT @B_Resultado as resultado, @T_Message as mensaje
*/
BEGIN
	DECLARE @I_Observados int = 0
	DECLARE @D_FecProceso datetime = GETDATE() 
	DECLARE @I_ObservID int = 49
	DECLARE @I_TablaID int = 4

	BEGIN TRANSACTION
	BEGIN TRY 
		SELECT I_OblRowID, SUM(Monto) Monto
		  INTO #temp_detalle_monto_sum
		  FROM TR_Ec_Det
		 WHERE Ano = @T_Anio
			   AND I_ProcedenciaID = @I_ProcedenciaID
			   AND Eliminado = 0
		 GROUP BY I_OblRowID

		SELECT I_OblRowID  
		  INTO #temp_detalle_monto_cabecera_monto
		  FROM TR_Ec_Obl Obl
			   INNER JOIN #temp_detalle_monto_sum tmp ON Obl.I_RowID = tmp.I_OblRowID
		 WHERE Obl.Monto <> tmp.Monto

		UPDATE Det
		   SET B_Migrable = 0,
			   D_FecEvalua = @D_FecProceso
		  FROM TR_Ec_Det Det 
			   INNER JOIN #temp_detalle_monto_cabecera_monto tmp ON Det.I_OblRowID = tmp.I_OblRowID

		MERGE TI_ObservacionRegistroTabla AS TRG
		USING (SELECT @I_ObservID AS I_ObservID, @I_TablaID AS I_TablaID, Det.I_RowID AS I_FilaTablaID, 
					  @D_FecProceso AS D_FecRegistro, Det.I_ProcedenciaID 
				 FROM TR_Ec_Det Det 
					  INNER JOIN #temp_detalle_monto_cabecera_monto tmp ON Det.I_OblRowID = tmp.I_OblRowID
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
			   				 FROM TR_Ec_Det Det
								  LEFT JOIN #temp_detalle_monto_cabecera_monto tmp ON tmp.I_OblRowID = Det.I_OblRowID
							WHERE tmp.I_OblRowID IS NULL
								  AND Det.Ano = @T_Anio
								  AND Det.I_ProcedenciaID = @I_ProcedenciaID
			   			  ) DET ON OBS.I_FilaTablaID = DET.I_RowID
						  		   AND OBS.I_ProcedenciaID = DET.I_ProcedenciaID 
		 WHERE OBS.I_ObservID = @I_ObservID 
		 	   AND OBS.I_TablaID = @I_TablaID 
		
		SET @I_Observados = (SELECT COUNT(*) 
							   FROM TI_ObservacionRegistroTabla OBS 
									INNER JOIN TR_Ec_Det DET ON OBS.I_FilaTablaID = DET.I_RowID 
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
							 'Title: "Observados", ' + 
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
							 'Title: "Error", ' + 
							 'Value: "' + ERROR_MESSAGE() + ' (Linea: ' + CAST(ERROR_LINE() AS varchar(11)) + ')."'  +
						  '}]' 
	END CATCH
END
GO


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_Obligaciones_ObligacionDet_MigracionTP_U_Validar_49_MontoDetalleMontoCabPorOblID')
	DROP PROCEDURE [dbo].[USP_Obligaciones_ObligacionDet_MigracionTP_U_Validar_49_MontoDetalleMontoCabPorOblID]
GO

CREATE PROCEDURE [dbo].[USP_Obligaciones_ObligacionDet_MigracionTP_U_Validar_49_MontoDetalleMontoCabPorOblID]
	@I_OblRowID	  int,
	@B_Resultado  bit output,
	@T_Message    nvarchar(4000) OUTPUT	
AS
/*
	DESCRIPCION: Marcar TR_Ec_Obl con B_Migrable = 0 cuando la suma de los montos en el detalle no coinciden con el monto de la cabecera para el ID de obligacion.

	DECLARE @I_OblRowID	  int,
			@B_Resultado  bit,
			@T_Message    nvarchar(4000)
	EXEC USP_Obligaciones_ObligacionDet_MigracionTP_U_Validar_49_MontoDetalleMontoCabPorOblID @I_OblRowID, @B_Resultado output, @T_Message output
	SELECT @B_Resultado as resultado, @T_Message as mensaje
*/
BEGIN
	DECLARE @I_Observados int = 0
	DECLARE @D_FecProceso datetime = GETDATE() 
	DECLARE @I_ObservID int = 49
	DECLARE @I_TablaID int = 4

	BEGIN TRANSACTION
	BEGIN TRY
		SELECT I_OblRowID, SUM(Monto) Monto
		  INTO #temp_detalle_monto_sum
		  FROM TR_Ec_Det
		 WHERE Eliminado = 0
			   AND I_RowID = @I_OblRowID
		 GROUP BY I_OblRowID

		SELECT I_OblRowID  
		  INTO #temp_detalle_monto_cabecera_monto
		  FROM TR_Ec_Obl Obl
			   INNER JOIN #temp_detalle_monto_sum tmp ON Obl.I_RowID = tmp.I_OblRowID
		 WHERE Obl.Monto <> tmp.Monto

		UPDATE Det
		   SET B_Migrable = 0,
			   D_FecEvalua = @D_FecProceso
		  FROM TR_Ec_Det Det 
			   INNER JOIN #temp_detalle_monto_cabecera_monto tmp ON Det.I_OblRowID = tmp.I_OblRowID
		 

		MERGE TI_ObservacionRegistroTabla AS TRG
		USING (SELECT @I_ObservID AS I_ObservID, @I_TablaID AS I_TablaID, Det.I_RowID AS I_FilaTablaID, 
					  @D_FecProceso AS D_FecRegistro, Det.I_ProcedenciaID 
				 FROM TR_Ec_Det Det 
					  INNER JOIN #temp_detalle_monto_cabecera_monto tmp ON Det.I_OblRowID = tmp.I_OblRowID
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
			   				 FROM TR_Ec_Det Det
								  LEFT JOIN #temp_detalle_monto_cabecera_monto tmp ON tmp.I_OblRowID = Det.I_OblRowID
							WHERE tmp.I_OblRowID IS NULL
								  AND Det.I_OblRowID = @I_OblRowID
			   			  ) DET ON OBS.I_FilaTablaID = DET.I_RowID
						  		   AND OBS.I_ProcedenciaID = DET.I_ProcedenciaID 
		 WHERE OBS.I_ObservID = @I_ObservID 
		 	   AND OBS.I_TablaID = @I_TablaID 
		
		SET @I_Observados = (SELECT COUNT(*) 
							   FROM TI_ObservacionRegistroTabla OBS 
									INNER JOIN TR_Ec_Det DET ON OBS.I_FilaTablaID = DET.I_RowID 
																AND DET.I_ProcedenciaID = OBS.I_ProcedenciaID
							  WHERE OBS.I_ObservID = @I_ObservID 
									AND Det.I_OblRowID = @I_OblRowID
									AND OBS.B_Resuelto = 0
							)
		COMMIT TRANSACTION

		SET @B_Resultado = 1
		SET @T_Message = '{ ' +
							 'Type: "summary", ' + 
							 'Title: "Observados", ' + 
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
							 'Title: "Error", ' + 
							 'Value: "' + ERROR_MESSAGE() + ' (Linea: ' + CAST(ERROR_LINE() AS varchar(11)) + ')."'  +
						  '}]' 
	END CATCH
END
GO



IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_Obligaciones_ObligacionDet_MigracionTP_U_Validar_58_SinObligacionCabID')
	DROP PROCEDURE [dbo].[USP_Obligaciones_ObligacionDet_MigracionTP_U_Validar_58_SinObligacionCabID]
GO

CREATE PROCEDURE [dbo].[USP_Obligaciones_ObligacionDet_MigracionTP_U_Validar_58_SinObligacionCabID]	
(
	@I_ProcedenciaID tinyint,
	@T_Anio		  varchar(4),
	@B_Resultado  bit output,
	@T_Message	  nvarchar(4000) OUTPUT	
)
AS
/*
	DESCRIPCION: Marcar TR_Ec_Det con B_Migrable = 0 cuando NO tiene asociada un ID de obligacion.

	DECLARE	@I_ProcedenciaID	tinyint = 2,
			@T_Anio				varchar(4) = '2016',
			@B_Resultado  bit,
			@T_Message			nvarchar(4000)
	EXEC USP_Obligaciones_ObligacionDet_MigracionTP_U_Validar_58_ObligacionCabID @I_ProcedenciaID, @T_Anio, @B_Resultado output, @T_Message output
	SELECT @B_Resultado as resultado, @T_Message as mensaje
*/
BEGIN
	DECLARE @I_Observados int = 0
	DECLARE @I_ObservadosObl int = 0
	DECLARE @D_FecProceso datetime = GETDATE() 
	DECLARE @I_ObservID int = 58
	DECLARE @I_TablaID int = 4

	BEGIN TRANSACTION
	BEGIN TRY 
		UPDATE	TR_Ec_Det
		SET		B_Migrable = 0,
				D_FecEvalua = @D_FecProceso
		WHERE	I_OblRowID IS NULL
				AND Ano = @T_Anio 
				AND I_ProcedenciaID = @I_ProcedenciaID


		MERGE TI_ObservacionRegistroTabla AS TRG
		USING 	(SELECT	@I_ObservID AS I_ObservID, @I_TablaID AS I_TablaID, I_RowID AS I_FilaTablaID, @D_FecProceso AS D_FecRegistro 
				   FROM	TR_Ec_Det 
				  WHERE	I_OblRowID IS NULL
						AND Ano = @T_Anio 
						AND I_ProcedenciaID = @I_ProcedenciaID
				) AS SRC
		ON TRG.I_ObservID = SRC.I_ObservID AND TRG.I_TablaID = SRC.I_TablaID AND TRG.I_FilaTablaID = SRC.I_FilaTablaID
		WHEN MATCHED AND TRG.I_ProcedenciaID = @I_ProcedenciaID THEN
			UPDATE SET D_FecRegistro = SRC.D_FecRegistro, 
					   B_Resuelto = 0
		WHEN NOT MATCHED BY TARGET THEN
			INSERT (I_ObservID, I_TablaID, I_FilaTablaID, D_FecRegistro, I_ProcedenciaID, B_ObligProc)
			VALUES (SRC.I_ObservID, SRC.I_TablaID, SRC.I_FilaTablaID, SRC.D_FecRegistro, @I_ProcedenciaID, 1);


		UPDATE OBS
		   SET D_FecResuelto = @D_FecProceso,
			   B_Resuelto = 1
		  FROM TI_ObservacionRegistroTabla OBS
			   INNER JOIN (SELECT I_RowID, I_ProcedenciaID FROM TR_Ec_Det 
							WHERE I_OblRowID IS NULL
								  AND Ano = @T_Anio 
								  AND I_ProcedenciaID = @I_ProcedenciaID) DET
						   ON OBS.I_FilaTablaID = DET.I_RowID
							  AND OBS.I_ProcedenciaID = DET.I_ProcedenciaID
		 WHERE OBS.I_ObservID = @I_ObservID 
			   AND OBS.I_TablaID = @I_TablaID

		SET @I_Observados = (SELECT COUNT(*) FROM TI_ObservacionRegistroTabla 
											WHERE I_ObservID = @I_ObservID 
												  AND I_TablaID = @I_TablaID
												  AND I_ProcedenciaID = @I_ProcedenciaID
												  AND B_Resuelto = 0) 

		SELECT @I_Observados as cant_obs, @D_FecProceso as fec_proceso		

		COMMIT TRANSACTION;

		SET @B_Resultado = 1
		SET @T_Message = '{ ' +
							 'Type: "summary", ' + 
							 'Title: "Observados", ' + 
							 'Value: ' + CAST(@I_Observados AS varchar) +
						 '}' 

	END TRY
	BEGIN CATCH
		  IF (@@TRANCOUNT > 0)
		SET @B_Resultado = 0
		SET @T_Message = '[{ ' +
							 'Type: "error", ' + 
							 'Title: "Error", ' + 
							 'Value: "' + ERROR_MESSAGE() + ' (Linea: ' + CAST(ERROR_LINE() AS varchar(11)) + ')."'  +
						  '}]' 
	END CATCH
END
GO



IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_Obligaciones_ObligacionDet_MigracionTP_U_Validar_62_MigracionCabecera')
	DROP PROCEDURE [dbo].[USP_Obligaciones_ObligacionDet_MigracionTP_U_Validar_62_MigracionCabecera]
GO

CREATE PROCEDURE [dbo].[USP_Obligaciones_ObligacionDet_MigracionTP_U_Validar_62_MigracionCabecera]	
(
	@I_ProcedenciaID tinyint,
	@T_Anio		  varchar(4),
	@B_Resultado  bit output,
	@T_Message	  nvarchar(4000) OUTPUT	
)
AS
/*
	DESCRIPCION: Marcar TR_Ec_Det con B_Migrable = 0 cuando la cabecera de la obligacion asociada al detella no fue migrada para el año y procedencia.

	DECLARE	@B_Resultado  bit,
			@I_ProcedenciaID	tinyint = 2,
			@T_Anio				varchar(4) = '2016',
			@T_Message			nvarchar(4000)
	EXEC USP_Obligaciones_ObligacionDet_MigracionTP_U_Validar_62_MigracionCabecera @I_ProcedenciaID, @T_Anio, @B_Resultado output, @T_Message output
	SELECT @B_Resultado as resultado, @T_Message as mensaje
*/
BEGIN
	DECLARE @I_Observados int = 0
	DECLARE @D_FecProceso datetime = GETDATE() 
	DECLARE @I_ObservID int = 62
	DECLARE @I_TablaID int = 4

	BEGIN TRANSACTION
	BEGIN TRY 

		SELECT I_OblRowID
		  INTO #temp_det_migrable_obl_no_migrado
		  FROM TR_Ec_Det det
			   INNER JOIN TR_Ec_Obl obl ON det.I_OblRowID = obl.I_RowID
		 WHERE obl.Ano = @T_Anio
			   AND obl.I_ProcedenciaID = @I_ProcedenciaID
			   AND obl.B_Migrado = 0			   

		UPDATE Det
		   SET B_Migrable = 0,
			   D_FecEvalua = @D_FecProceso
		  FROM TR_Ec_Det Det 
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
			   				 FROM TR_Ec_Det Det
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
									INNER JOIN TR_Ec_Det DET ON OBS.I_FilaTablaID = DET.I_RowID 
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
							 'Title: "Observados", ' + 
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
							 'Title: "Error", ' + 
							 'Value: "' + ERROR_MESSAGE() + ' (Linea: ' + CAST(ERROR_LINE() AS varchar(11)) + ')."'  +
						  '}]' 
	END CATCH
END
GO


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_Obligaciones_ObligacionDet_MigracionTP_U_Validar_62_MigracionCabeceraPorOblID')
	DROP PROCEDURE [dbo].[USP_Obligaciones_ObligacionDet_MigracionTP_U_Validar_62_MigracionCabeceraPorOblID]
GO

CREATE PROCEDURE [dbo].[USP_Obligaciones_ObligacionDet_MigracionTP_U_Validar_62_MigracionCabeceraPorOblID]
	@I_OblRowID	  int,
	@B_Resultado  bit output,
	@T_Message    nvarchar(4000) OUTPUT	
AS
/*
	DESCRIPCION: Marcar TR_Ec_Obl con B_Migrable = 0 cuando la suma de los montos en el detalle no coinciden con el monto de la cabecera para el ID de obligacion.

	DECLARE @I_OblRowID	  int,
			@B_Resultado  bit,
			@T_Message    nvarchar(4000)
	EXEC USP_Obligaciones_ObligacionDet_MigracionTP_U_Validar_62_MigracionCabeceraPorOblID @I_OblRowID, @B_Resultado output, @T_Message output
	SELECT @B_Resultado as resultado, @T_Message as mensaje
*/
BEGIN
	DECLARE @I_Observados int = 0
	DECLARE @D_FecProceso datetime = GETDATE() 
	DECLARE @I_ObservID int = 62
	DECLARE @I_TablaID int = 4

	BEGIN TRANSACTION
	BEGIN TRY

		SELECT I_OblRowID
		  INTO #temp_det_migrable_obl_no_migrado
		  FROM TR_Ec_Det det
			   INNER JOIN TR_Ec_Obl obl ON det.I_OblRowID = obl.I_RowID
		 WHERE obl.I_RowID = @I_OblRowID
			   AND obl.B_Migrado = 0			   
			   AND obl.B_Migrable = 1

		UPDATE Det
		   SET B_Migrable = 0,
			   D_FecEvalua = @D_FecProceso
		  FROM TR_Ec_Det Det 
			   INNER JOIN #temp_det_migrable_obl_no_migrado tmp ON Det.I_OblRowID = tmp.I_OblRowID


		MERGE TI_ObservacionRegistroTabla AS TRG
		USING (SELECT @I_ObservID AS I_ObservID, @I_TablaID AS I_TablaID, Det.I_RowID AS I_FilaTablaID, 
					  @D_FecProceso AS D_FecRegistro, Det.I_ProcedenciaID 
				 FROM TR_Ec_Det Det 
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
			   				 FROM TR_Ec_Det Det
								  LEFT JOIN #temp_det_migrable_obl_no_migrado tmp ON tmp.I_OblRowID = Det.I_OblRowID
							WHERE tmp.I_OblRowID IS NULL
								  AND Det.I_OblRowID = @I_OblRowID
			   			  ) DET ON OBS.I_FilaTablaID = DET.I_RowID
						  		   AND OBS.I_ProcedenciaID = DET.I_ProcedenciaID 
		 WHERE OBS.I_ObservID = @I_ObservID 
		 	   AND OBS.I_TablaID = @I_TablaID 
		
		SET @I_Observados = (SELECT COUNT(*) 
							   FROM TI_ObservacionRegistroTabla OBS 
									INNER JOIN TR_Ec_Det DET ON OBS.I_FilaTablaID = DET.I_RowID 
																AND DET.I_ProcedenciaID = OBS.I_ProcedenciaID
							  WHERE OBS.I_ObservID = @I_ObservID 
									AND Det.I_OblRowID = @I_OblRowID
									AND OBS.B_Resuelto = 0
							)
		COMMIT TRANSACTION

		SET @B_Resultado = 1
		SET @T_Message = '{ ' +
							 'Type: "summary", ' + 
							 'Title: "Observados", ' + 
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
	@I_UsuarioID		int,
	@D_FecProceso		datetime,
	@I_TablaOblID	    int,
	@I_MatAluID			int OUTPUT
)
AS
BEGIN

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
	  FROM (SELECT Cod_rc, Cod_alu, Ano, I_Periodo 
			  FROM TR_Ec_Obl 
			 WHERE I_RowID = @I_RowID) SRC
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
	@I_UsuarioID		int,
	@D_FecProceso		datetime,
	@I_TablaID			int,
	@I_Det_Insertados	int OUTPUT
)
AS
BEGIN
	INSERT INTO BD_OCEF_CtasPorCobrar.dbo.TR_ObligacionAluDet (I_ObligacionAluID, I_ConcPagID, I_Monto, B_Pagado, D_FecVencto, I_TipoDocumento, 
															   T_DescDocumento, B_Habilitado, B_Eliminado, I_UsuarioCre, D_FecCre, B_Mora, 
															   B_Migrado, I_MigracionTablaID, I_MigracionRowID)
														SELECT @I_ObligacionAluID, SRC.Concepto, SRC.Monto, 0 as pagado, SRC.Fch_venc, CASE WHEN CAST(Documento as varchar(max)) IS NULL THEN NULL ELSE 138 END AS I_TipoDocumento, 
															   CAST(Documento as varchar(max)) AS T_DescDocumento, 1 as habilitado,  Eliminado as eliminado, @I_UsuarioID as I_UsuarioCre, @D_FecProceso, 0 AS Mora, 
															   1 as migrado, @I_TablaID, I_RowID
														  FROM TR_Ec_Det SRC
														 WHERE SRC.I_OblRowID =  @I_OblRowID

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
	DECLARE @I_RowID	  int = 2830, 
			@I_OblAluID   int,
			@B_Resultado  bit, 
			@T_Message	  nvarchar(4000)
	EXEC USP_Obligaciones_MigracionTP_CtasPorCobrar_IU_MigrarDataPorID @I_RowID, @I_OblAluID output, @B_Resultado output, @T_Message output
	SELECT @B_Resultado as resultado, @T_Message as mensaje
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
		
		DECLARE @Cod_alu	varchar(20)
		DECLARE @Cod_Rc		varchar(5)
		DECLARE @I_Periodo	int
		DECLARE @I_Anio		int

		DECLARE @I_MatAluID		 int 
		DECLARE @I_MatAluID_Obl  int 
		DECLARE @I_UsuarioID	 int = (SELECT dbo.Func_Config_CtasPorCobrar_I_ObtenerUsuarioMigracionID())


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
		 WHERE I_MigracionRowID = @I_RowID 
			   AND I_MigracionTablaID = @I_MigracionTablaOblID


		SELECT @I_CountDetOblID = COUNT(*) FROM BD_OCEF_CtasPorCobrar.dbo.TR_ObligacionAluDet
		 WHERE I_ObligacionAluID = @I_ObligacionAluID 
			   AND I_MigracionTablaID = @I_MigracionTablaDetID


		IF(@I_MatAluID IS NULL)
		BEGIN
			EXECUTE USP_Obligaciones_MigracionTP_CtasPorCobrar_I_GrabarMatriculaPorObligacionID @I_RowID, @I_UsuarioID, @D_FecProceso, @I_MigracionTablaOblID, @I_MatAluID
		END
		ELSE
		BEGIN
			EXECUTE USP_Obligaciones_MigracionTP_CtasPorCobrar_U_GrabarMatriculaPorObligacionID @I_RowID, @I_MatAluID, @I_MigracionTablaOblID, @D_FecProceso
		END


		IF(@I_ObligacionAluID IS NULL)
		BEGIN
			INSERT INTO BD_OCEF_CtasPorCobrar.dbo.TR_ObligacionAluCab (I_ProcesoID, I_MatAluID, C_Moneda, I_MontoOblig, D_FecVencto, B_Pagado, B_Habilitado, 
																	   B_Eliminado, I_UsuarioCre, D_FecCre, B_Migrado, I_MigracionTablaID, I_MigracionRowID)
																SELECT SRC.Cuota_pago, @I_MatAluID, @T_Moneda, SRC.Monto, SRC.Fch_venc, 0 as B_Pagado, 1 as B_Habilitado, 
																	   0 as eliminado, @I_UsuarioID, @D_FecProceso, 1 as B_Migrado, @I_MigracionTablaOblID, SRC.I_RowID
																		  FROM TR_Ec_Obl SRC
																 WHERE SRC.I_RowID = @I_RowID

			SET @I_ObligacionAluID = SCOPE_IDENTITY();

			EXECUTE USP_Obligaciones_MigracionTP_CtasPorCobrar_I_GrabarDetObligPorObligacionID @I_RowID, @I_ObligacionAluID, @I_UsuarioID, @D_FecProceso, @I_MigracionTablaDetID, @I_Det_Insertados

		END
		ELSE
		BEGIN
			IF (ISNULL(@I_MatAluID, 1) <> ISNULL(@I_MatAluID_Obl, 1))
			BEGIN
				SET @B_Resultado = 0
				SET @T_Message = 'La matricula en el repositorio, no coincide con la del temporal de pagos.'

				GOTO END_TRANSACTION
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

		END
		
		IF (@I_CountDetOblID = 0)
		BEGIN
			EXECUTE USP_Obligaciones_MigracionTP_CtasPorCobrar_I_GrabarDetObligPorObligacionID @I_RowID, @I_ObligacionAluID, @I_UsuarioID, @D_FecProceso, @I_MigracionTablaDetID, @I_Det_Insertados
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
							TRG.I_UsuarioMod = @I_UsuarioID, 
							TRG.D_FecMod = @D_FecProceso
			WHEN NOT MATCHED THEN
				INSERT (I_ObligacionAluID, I_ConcPagID, I_Monto, B_Pagado, D_FecVencto, I_TipoDocumento, T_DescDocumento, B_Mora, 
						B_Habilitado, B_Eliminado, I_UsuarioCre, D_FecCre, B_Migrado, I_MigracionTablaID, I_MigracionRowID)
				VALUES (SRC.I_ObligacionAluID, SRC.Concepto, SRC.Monto, 0, SRC.Fch_venc, SRC.I_TipoDocumento, SRC.T_DescDocumento, SRC.Mora, 
						SRC.Habilitado, SRC.Eliminado, @I_UsuarioID, @D_FecProceso, 1, @I_MigracionTablaDetID, SRC.I_DetMigracionRowID)
			OUTPUT $action, SRC.I_DetMigracionRowID INTO @Tbl_outputObl;

			SET @I_Det_Insertados = (SELECT COUNT(*) FROM @Tbl_outputObl WHERE T_Action = 'INSERT')
			SET @I_Det_Actualizados = (SELECT COUNT(*) FROM @Tbl_outputObl WHERE T_Action = 'UPDATE')
		END


		UPDATE EC_OBL 
		   SET B_Migrado = 1,
		   	   D_FecMigrado = @D_FecProceso
		  FROM TR_Ec_Obl EC_OBL
		 	   INNER JOIN BD_OCEF_CtasPorCobrar.dbo.TR_ObligacionAluCab CTAS_CAB ON EC_OBL.I_RowID = CTAS_CAB.I_MigracionRowID
		 WHERE EC_OBL.I_RowID = @I_RowID
		 

		END_TRANSACTION:
			SET @I_OblAluID = ISNULL(@I_ObligacionAluID, 0)
			COMMIT TRANSACTION;

		SET @B_Resultado = 1
		SET @T_Message = '[{ ' +
							 'Type: "summary", ' + 
							 'Title: "Detalle de obligaciones insertados (OBL_ID: ' + CAST(@I_RowID AS varchar) + ')", ' + 
							 'Value: ' + CAST(@I_Det_Insertados AS varchar(10)) +
						  '}, ' + 
						  '{ ' +
							 'Type: "summary", ' + 
							 'Title: "Detalle de obligaciones actualizados (OBL_ID: ' + CAST(@I_RowID AS varchar) + ')", ' + 
							 'Value: ' + CAST(@I_Det_Actualizados AS varchar(10)) +
						  '}]'

	END TRY
	BEGIN CATCH
		IF(@@TRANCOUNT > 0)
		BEGIN
			ROLLBACK TRANSACTION
		END

		SET @I_OblAluID = ISNULL(@I_ObligacionAluID, 0)
		SET @B_Resultado = 0
		SET @T_Message = '[{ ' +
							 'Type: "error", ' + 
							 'Title: "Error", ' + 
							 'Value: "' + ERROR_MESSAGE() + ' (Linea: ' + CAST(ERROR_LINE() AS varchar(10)) + ')."'  +
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
	DECLARE @I_ProcedenciaID tinyint = 2,
			@T_Anio		  varchar(4) = '2008', 
			@B_Resultado  bit, 
			@T_Message	  nvarchar(4000)
	EXEC USP_Obligaciones_MigracionTP_CtasPorCobrar_IU_MigrarDataPorAnio @I_ProcedenciaID, @T_Anio, @B_Resultado output, @T_Message output
	SELECT @B_Resultado as resultado, @T_Message as mensaje
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

	DECLARE @Tbl_outputMat AS TABLE (T_Action varchar(20), I_RowID int, I_Inserted_MatID int, I_Deleted_MatD int)
	DECLARE @Tbl_outputObl AS TABLE (T_Action varchar(20), I_RowID int, I_Inserted_OblID int, I_Deleted_OblID int)
	DECLARE @Tbl_outputDet AS TABLE (T_Action varchar(20), I_RowID int, I_Inserted_DetID int, I_Deleted_DetD int)

	BEGIN TRANSACTION;
	BEGIN TRY 
		
		SELECT ROW_NUMBER() OVER(PARTITION BY Ano, P, Cod_alu, Cod_rc ORDER BY I_RowID) as I_Obl_Nro, Ano, P, I_Periodo, 
			   Cod_alu, Cod_rc, Cuota_pago, Tipo_oblig, Fch_venc, Monto, 0 as Pagado, D_FecCarga, B_Migrable, B_Migrado, 
			   I_ProcedenciaID, B_Obligacion, I_RowID, I_CtasMatTableRowID, @I_TablaID_Obl as I_MigracionTablaID 
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
		   SET I_CtasMatTableRowID = Mat.I_MatAluID
		  FROM TR_Ec_Obl Obl
			   INNER JOIN BD_OCEF_CtasPorCobrar.dbo.TC_MatriculaAlumno Mat ON Mat.I_MigracionRowID = Obl.I_RowID

		UPDATE temp_obl
		   SET I_CtasMatTableRowID = Obl.I_CtasMatTableRowID
		  FROM TR_Ec_Obl Obl
			   INNER JOIN #temp_obl_migrable_anio temp_obl ON temp_obl.I_RowID = Obl.I_RowID


		MERGE INTO BD_OCEF_CtasPorCobrar.dbo.TR_ObligacionAluCab AS TRG
		USING (SELECT * FROM #temp_obl_migrable_anio 
				WHERE I_CtasMatTableRowID IS NOT NULL) AS SRC
		ON TRG.I_MigracionRowID = SRC.I_RowID AND
		   TRG.I_MigracionTablaID = SRC.I_MigracionTablaID
		WHEN MATCHED AND TRG.B_Migrado = 1 THEN
			UPDATE SET TRG.I_ProcesoID = SRC.Cuota_pago, 
					   TRG.I_MatAluID = SRC.I_CtasMatTableRowID, 
					   TRG.I_MontoOblig = SRC.Monto, 
					   TRG.D_FecVencto = SRC.Fch_venc, 
					   TRG.B_Pagado = SRC.Pagado, 
					   TRG.I_UsuarioMod = @I_UsuarioID, 
					   TRG.D_FecMod = @D_FecProceso
		WHEN NOT MATCHED THEN
			INSERT (I_ProcesoID, I_MatAluID, C_Moneda, I_MontoOblig, D_FecVencto, B_Pagado, B_Habilitado, 
					B_Eliminado, I_UsuarioCre, D_FecCre, B_Migrado, I_MigracionTablaID, I_MigracionRowID)
			VALUES (SRC.Cuota_pago, SRC.I_CtasMatTableRowID, @T_Moneda, SRC.Monto, SRC.Fch_venc, 0, 1, 
					0, @I_UsuarioID, @D_FecProceso, 1, I_MigracionTablaID, SRC.I_RowID)
		OUTPUT $action, SRC.I_RowID, inserted.I_ObligacionAluID, deleted.I_ObligacionAluID INTO @Tbl_outputObl;


		UPDATE OBL
		   SET B_Migrado = 1,
			   D_FecMigrado = @D_FecProceso,
			   I_CtasCabTableRowID = I_Inserted_OblID
		  FROM TR_Ec_Obl OBL
			   INNER JOIN @Tbl_outputObl O ON O.I_RowID = OBL.I_RowID
		 WHERE O.T_Action = 'INSERT'

		UPDATE OBL
		   SET B_Migrado = 1,
			   D_FecMigrado = @D_FecProceso,
			   I_CtasCabTableRowID = I_Inserted_OblID
		  FROM TR_Ec_Obl OBL
			   INNER JOIN @Tbl_outputObl O ON O.I_RowID = OBL.I_RowID
		 WHERE O.T_Action = 'UPDATE'


		SET @I_Obl_Insertados = (SELECT COUNT(*) FROM @Tbl_outputObl WHERE T_Action = 'INSERT')
		SET @I_Obl_Actualizados = (SELECT COUNT(*) FROM @Tbl_outputObl WHERE T_Action = 'UPDATE')


		SELECT I_OblRowID, det.I_RowID, det.Ano, det.P, det.Cod_alu, det.Cod_rc, det.Cuota_pago, det.Tipo_oblig, 
			   det.Cantidad, det.Monto, Concepto, Tipo_pago, No_banco, Fch_elimin, Concepto_f, det.Fch_venc, 
			   0 as Pagado, Eliminado, det.D_FecCarga, CAST(Documento as varchar(max)) AS T_DescDocumento, 
			   CASE WHEN CAST(Documento as varchar(max)) IS NULL THEN NULL ELSE 138 END AS I_TipoDocumento,
			   IIF(Eliminado = 1, 0, 1) AS Habilitado, 0 as Mora, obl.I_CtasCabTableRowID as I_CtasOblID, 
			   det.B_Migrable, det.B_Migrado, det.B_Obligacion, @I_TablaID_Det as I_MigracionTablaID
		  INTO #temp_det_migrable_anio
		  FROM TR_Ec_Det det
			   INNER JOIN TR_Ec_Obl obl ON obl.I_RowID = det.I_OblRowID
		 WHERE det.B_Migrable = 1 
			   AND obl.I_ProcedenciaID = @I_ProcedenciaID
		 	   AND obl.Ano = @T_Anio


		MERGE INTO BD_OCEF_CtasPorCobrar.dbo.TR_ObligacionAluDet AS TRG
		USING (SELECT I_CtasOblID as I_ObligacionAluID, det.*
				 FROM #temp_det_migrable_anio det 
				WHERE I_CtasOblID IS NOT NULL
			  ) AS SRC
		ON TRG.I_MigracionRowID = SRC.I_RowID AND
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
					SRC.Habilitado, SRC.Eliminado, @I_UsuarioID, @D_FecProceso, SRC.Mora, 1, I_MigracionTablaID, SRC.I_RowID)
		OUTPUT $action, SRC.I_ObligacionAluID, inserted.I_ObligacionAluDetID, deleted.I_ObligacionAluDetID INTO @Tbl_outputDet;


		UPDATE DET
		   SET B_Migrado = 1,
			   D_FecMigrado = @D_FecProceso,
			   I_CtasDetTableRowID = o.I_Inserted_DetID
		  FROM TR_Ec_Det DET
			   INNER JOIN @Tbl_outputDet O ON O.I_RowID = DET.I_RowID
		 WHERE O.T_Action = 'INSERT'

		UPDATE DET
		   SET B_Migrado = 1,
			   D_FecMigrado = @D_FecProceso, 
			   I_CtasDetTableRowID = o.I_Inserted_DetID
		  FROM TR_Ec_Det DET
			   INNER JOIN @Tbl_outputDet O ON O.I_RowID = DET.I_RowID
		 WHERE O.T_Action = 'UPDATE'


		SET @I_Det_Insertados = (SELECT COUNT(*) FROM @Tbl_outputDet WHERE T_Action = 'INSERT')
		SET @I_Det_Actualizados = (SELECT COUNT(*) FROM @Tbl_outputDet WHERE T_Action = 'UPDATE')


		COMMIT TRANSACTION;

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