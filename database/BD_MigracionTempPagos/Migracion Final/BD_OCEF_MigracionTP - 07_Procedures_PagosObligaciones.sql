/*
==================================================================
	BD_OCEF_MigracionTP - 07_Procedures_PagoObligaciones
==================================================================
*/


USE BD_OCEF_MigracionTP
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
	DESCRIPCION: Marcar TR_Ec_Det_Pagos con B_Migrable = 0 los pagos con I_OblRowID = NULL  para la procedencia y año

	DECLARE	@I_ProcedenciaID	tinyint = 2,
			@T_Anio	      varchar(4) = '2016',
			@B_Resultado  bit,
			@T_Message	  nvarchar(4000)
	EXEC USP_Obligaciones_Pagos_MigracionTP_U_Validar_52_SinObligacionID @I_ProcedenciaID, @I_Anio, @B_Resultado output, @T_Message output
	SELECT @B_Resultado as resultado, @T_Message as mensaje
*/
BEGIN
	DECLARE @D_FecProceso datetime = GETDATE() 
	DECLARE @I_ObservID int = 52
	DECLARE @I_TablaID int = 7

	BEGIN TRANSACTION
	BEGIN TRY


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
	@I_OblRowID	  int,
	@B_Resultado  bit output,
	@T_Message	  nvarchar(4000) OUTPUT	
AS
/*
  	DESCRIPCION: Marcar TR_Ec_Obl con B_Migrable = 0 las obligaciones con estado Pagado = 1 que no tengan pago en TR_Ec_Det_Pagos o cuyo monto pagado no coincide con el monto en obl 

	DECLARE	@I_OblRowID	      int = 3,
			@B_Resultado      bit,
			@T_Message	      nvarchar(4000)
	EXEC USP_Obligaciones_Pagos_MigracionTP_U_Validar_52_SinObligacionIDPorID @I_OblRowID, @B_Resultado output, @T_Message output
	SELECT @B_Resultado as resultado, @T_Message as mensaje
*/
BEGIN
	DECLARE @D_FecProceso datetime = GETDATE() 
	DECLARE @I_ObservID int = 52
	DECLARE @I_TablaID int = 5

	BEGIN TRANSACTION
	BEGIN TRY


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
  	DESCRIPCION: Marcar TR_Ec_Det_Pagos con B_Migrable = 0 los pagos cuyo monto no coincida con el monto acumulado del detalle con estado pagado = 1 y 
				 eliminado = 0  para la procedencia y año

	DECLARE	@I_ProcedenciaID	tinyint = 3,
			@I_Anio  	  smallint = 2010,
			@B_Resultado  bit,
			@T_Message	  nvarchar(4000)
	EXEC USP_Obligaciones_Pagos_MigracionTP_U_Validar_53_MontoPagadoDetalle @I_ProcedenciaID, @I_Anio, @B_Resultado output, @T_Message output
	SELECT @B_Resultado as resultado, @T_Message as mensaj
*/
BEGIN
	DECLARE @D_FecProceso datetime = GETDATE() 
	DECLARE @I_ObservID int = 53
	DECLARE @I_TablaID int = 7

	BEGIN TRANSACTION
	BEGIN TRY

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
	DECLARE @D_FecProceso datetime = GETDATE() 
	DECLARE @I_ObservID int = 53
	DECLARE @I_TablaID int = 7

	BEGIN TRANSACTION
	BEGIN TRY
		


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
  	DESCRIPCION: Marcar TR_Ec_Det_Pagos con B_Migrable = 0 cuando los estado pagado de la obligacion y el pago no coinciden para la procedencia y año.

	DECLARE	@I_ProcedenciaID	tinyint = 3,
			@I_Anio  	  smallint = 2010,
			@B_Resultado  bit,
			@T_Message	  nvarchar(4000)
	EXEC USP_Obligaciones_Pagos_MigracionTP_U_Validar_54_EstadoPagadoObligacion @I_ProcedenciaID, @I_Anio, @B_Resultado output, @T_Message output
	SELECT @B_Resultado as resultado, @T_Message as mensaje
*/
BEGIN
	DECLARE @D_FecProceso datetime = GETDATE() 
	DECLARE @I_ObservID int = 54
	DECLARE @I_TablaID int = 7

	BEGIN TRANSACTION
	BEGIN TRY


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
	@I_OblRowID	  int,
	@B_Resultado  bit output,
	@T_Message	  nvarchar(4000) OUTPUT	
AS
/*
  	DESCRIPCION: Marcar TR_Ec_Det_Pagos con B_Migrable = 0 cuando los estado pagado de la obligacion y el pago no coinciden para la I_OblRowID para la procedencia y año.

	DECLARE	@I_OblRowID	  int = 3,
			@B_Resultado  bit,
			@T_Message	  nvarchar(4000)
	EXEC USP_Obligaciones_Pagos_MigracionTP_U_Validar_54_EstadoPagadoObligacionPorID @I_OblRowID, @B_Resultado output, @T_Message output
	SELECT @B_Resultado as resultado, @T_Message as mensaj
*/
BEGIN
	DECLARE @D_FecProceso datetime = GETDATE() 
	DECLARE @I_ObservID_sinOblId int = 54
	DECLARE @I_TablaID int = 7

	BEGIN TRANSACTION
	BEGIN TRY
		
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
  	DESCRIPCION: Marcar TR_Ec_Det_Pagos con B_Migrable = 0 cuando el pago de la obligacion no migrada existe en la base de datos de destino para la procedencia y año.

	DECLARE @I_ProcedenciaID tinyint = 3,
			@T_Anio		 varchar(4) = '2010', 
			@B_Resultado  bit, 
			@T_Message nvarchar(4000)
	EXEC USP_Obligaciones_Pagos_MigracionTP_U_Validar_55_ExisteEnDestinoConOtroBanco @I_ProcedenciaID, @T_Anio, @B_Resultado output, @T_Message output
	SELECT @B_Resultado as resultado, @T_Message as mensaje
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
	@I_OblRowID			int,
	@B_Resultado		bit output,
	@T_Message			nvarchar(4000) OUTPUT	
AS
/*
  	DESCRIPCION: Marcar TR_Ec_Det_Pagos con B_Migrable = 0 cuando el pago de la obligacion I_OblRowID no migrada existe en la base de datos de destino para la procedencia y año.
	
	DECLARE @I_OblRowID	 int,
			@B_Resultado  bit, 
			@T_Message nvarchar(4000)
	EXEC USP_Obligaciones_Pagos_MigracionTP_U_Validar_55_ExisteEnDestinoConOtroBancoPorID @I_OblRowID, @B_Resultado output, @T_Message output
	SELECT @B_Resultado as resultado, @T_Message as mensaje
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
	DECLARE @D_FecProceso datetime = GETDATE() 
	DECLARE @I_ObservID int = 55
	DECLARE @I_TablaID int = 7
	
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
  	DESCRIPCION: Marcar TR_Ec_Det_Pagos con B_Migrable = 0 cuando los conceptos en el detalle con estado pagado 1 y eliminado 0 tienen B_Migrable = 0
				 para la procedencia y año.

	DECLARE @I_ProcedenciaID	tinyint = 3, 
			@T_Anio		  varchar(4) = '2005',
			@B_Resultado  bit,
			@T_Message    nvarchar(4000)
	EXEC USP_Obligaciones_Pagos_MigracionTP_U_Validar_56_DetalleObservado @I_ProcedenciaID, @T_Anio, @B_Resultado output, @T_Message output
	SELECT @B_Resultado as resultado, @T_Message as mensaje
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


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_Obligaciones_Pagos_MigracionTP_U_Validar_56_DetalleObservadoPorOblID')
	DROP PROCEDURE [dbo].[USP_Obligaciones_Pagos_MigracionTP_U_Validar_56_DetalleObservadoPorOblID]
GO

CREATE PROCEDURE [dbo].[USP_Obligaciones_Pagos_MigracionTP_U_Validar_56_DetalleObservadoPorOblID]
	@I_OblRowID			int,
	@B_Resultado	bit output,
	@T_Message		nvarchar(4000) OUTPUT	
AS
/*
  	DESCRIPCION: Marcar TR_Ec_Det_Pagos con B_Migrable = 0 cuando los conceptos en el detalle con estado pagado 1 y eliminado 0 tienen B_Migrable = 0
				 para la obligacion I_OblRowID	

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

	BEGIN TRANSACTION
	BEGIN TRY
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

	DECLARE @I_ProcedenciaID	tinyint = 3, 
			@T_Anio		  varchar(4) = '2005',
			@B_Resultado  bit,
			@T_Message    nvarchar(4000)
	EXEC USP_Obligaciones_Pagos_MigracionTP_U_Validar_57_CabObligacionObservada @I_ProcedenciaID, @T_Anio, @B_Resultado output, @T_Message output
	SELECT @B_Resultado as resultado, @T_Message as mensaje
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



IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_Obligaciones_Pagos_MigracionTP_U_Validar_57_CabObligacionObservadaPorOblID')
	DROP PROCEDURE [dbo].[USP_Obligaciones_Pagos_MigracionTP_U_Validar_57_CabObligacionObservadaPorOblID]
GO

CREATE PROCEDURE [dbo].[USP_Obligaciones_Pagos_MigracionTP_U_Validar_57_CabObligacionObservadaPorOblID]
	@I_OblRowID			int,
	@B_Resultado	bit output,
	@T_Message		nvarchar(4000) OUTPUT	
AS
/*
  	DESCRIPCION: Marcar TR_Ec_Det_Pagos con B_Migrable = 0 cuando la cabecera de la obligación asociada se encuentra observada para la obligacion I_OblRowID	

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

	BEGIN TRANSACTION
	BEGIN TRY
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
