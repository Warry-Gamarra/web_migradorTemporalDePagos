USE BD_OCEF_MigracionTP
GO


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_MigracionTP_U_RemoverObservacionDetalleObligacion')
	DROP PROCEDURE [dbo].[USP_MigracionTP_U_RemoverObservacionDetalleObligacion]
GO

CREATE PROCEDURE [dbo].[USP_MigracionTP_U_RemoverObservacionDetalleObligacion]	
	@I_RowID	  int,
	@I_TablaID	  int,
	@I_ObservID	  int,
	@D_FecProceso datetime
AS
BEGIN
	UPDATE	TR_Ec_Det
	   SET  B_Migrable = 1,
			B_Migrado = 0,
			D_FecEvalua = @D_FecProceso
	 WHERE  I_RowID = I_RowID
			AND B_Migrado = 0

	DELETE FROM TI_ObservacionRegistroTabla 
		WHERE I_TablaID = @I_TablaID 
				AND I_FilaTablaID = @I_RowID 
				AND I_ObservID = @I_ObservID

END
GO


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_MigracionTP_U_RegistrarObservacionDetalleObligacion')
	DROP PROCEDURE [dbo].[USP_MigracionTP_U_RegistrarObservacionDetalleObligacion]
GO

CREATE PROCEDURE [dbo].[USP_MigracionTP_U_RegistrarObservacionDetalleObligacion]	
	@I_RowID	   int,
	@I_TablaID	   int,
	@I_ObservID	   int,
	@D_FecProceso  datetime
AS
BEGIN

	UPDATE	TR_Ec_Det
	   SET  B_Migrable = 0,
			B_Migrado = 0,
			D_FecEvalua = @D_FecProceso
	 WHERE  I_RowID = I_RowID

	IF EXISTS (SELECT * FROM TI_ObservacionRegistroTabla WHERE I_TablaID = @I_TablaID AND I_FilaTablaID = @I_RowID AND I_ObservID = @I_ObservID)
		UPDATE TI_ObservacionRegistroTabla 
			SET D_FecRegistro = @D_FecProceso
			WHERE I_TablaID = @I_TablaID 
				AND I_FilaTablaID = @I_RowID 
				AND I_ObservID = @I_ObservID
	ELSE
		INSERT INTO TI_ObservacionRegistroTabla (I_ObservID, I_TablaID, I_FilaTablaID, I_ProcedenciaID, D_FecRegistro, B_Resuelto, D_FecResuelto)
						SELECT @I_ObservID, @I_TablaID, I_RowID, I_ProcedenciaID, @D_FecProceso, 0, NULL
						FROM TR_Ec_Det WHERE I_RowID = @I_RowID 
END
GO



IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_U_43_ValidarAnioConceptoDetalleObligacionPorDetOblID')
	DROP PROCEDURE [dbo].[USP_U_43_ValidarAnioConceptoDetalleObligacionPorDetOblID]
GO

CREATE PROCEDURE [dbo].[USP_U_43_ValidarAnioConceptoDetalleObligacionPorDetOblID]	
	@I_RowID	 tinyint,
	@B_Resultado bit output,
	@T_Message	 nvarchar(4000) OUTPUT	
AS
--declare	@I_RowID  	     int,
--			@B_Resultado	 bit,
--			@T_Message		 nvarchar(4000)
--exec USP_U_43_ValidarAnioConceptoDetalleObligacionPorDetOblID @I_RowID, @B_Resultado output, @T_Message output
--select @B_Resultado as resultado, @T_Message as mensaje
BEGIN
	DECLARE @I_Observados int = 0
	DECLARE @D_FecProceso datetime = GETDATE() 
	DECLARE @I_ObservID int = 43
	DECLARE @I_TablaID int = 4

	BEGIN TRANSACTION
	BEGIN TRY 		
		DECLARE @Cod_alu	varchar(20)
		DECLARE @Cod_Rc		varchar(5)
		DECLARE @Cuota_Pago	int
		DECLARE @Concepto	int
		DECLARE @P			varchar(3)
		DECLARE @T_Anio		varchar(5)
		DECLARE @T_Anio_pri	varchar(5)
		DECLARE @B_Correcto	int
		
		SELECT @Concepto = Concepto, @T_Anio = Ano, @B_Correcto = B_Correcto
		  FROM TR_Ec_Det
		 WHERE I_RowID = @I_RowID

		IF (@B_Correcto = 1)
		BEGIN
			EXECUTE USP_MigracionTP_U_RemoverObservacionDetalleObligacion @I_RowID, @I_TablaID, @I_ObservID, @D_FecProceso
		END
		ELSE
		BEGIN
			SELECT @T_Anio_pri = Ano FROM TR_Cp_Pri WHERE Id_cp = @Concepto

			IF (@T_Anio_pri = @T_Anio)
			BEGIN
				EXECUTE USP_MigracionTP_U_RemoverObservacionDetalleObligacion @I_RowID, @I_TablaID, @I_ObservID, @D_FecProceso
			END
			ELSE
			BEGIN
				EXECUTE USP_MigracionTP_U_RegistrarObservacionDetalleObligacion @I_RowID, @I_TablaID, @I_ObservID, @D_FecProceso
			END
		END

		COMMIT TRANSACTION;
		SET @T_Message = CAST(@@ROWCOUNT AS varchar)
		SET @B_Resultado = 1
	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION
		SET @B_Resultado = 0
		SET @T_Message = ERROR_MESSAGE() + ' (Linea: ' + CAST(ERROR_LINE() AS varchar(11)) + ').' 
	END CATCH
END
GO


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_U_43_ValidarAnioConceptoDetalleObligacion')
	DROP PROCEDURE [dbo].[USP_U_43_ValidarAnioConceptoDetalleObligacion]
GO

CREATE PROCEDURE [dbo].[USP_U_43_ValidarAnioConceptoDetalleObligacion]	
	@I_RowID	 tinyint,
	@B_Resultado bit output,
	@T_Message	 nvarchar(4000) OUTPUT	
AS
--declare	@I_RowID  	     int,
--			@B_Resultado	 bit,
--			@T_Message		 nvarchar(4000)
--exec USP_U_InicializarEstadoValidacionObligacionPago @I_ProcedenciaID, @I_Anio, @B_Resultado output, @T_Message output
--select @B_Resultado as resultado, @T_Message as mensaje
BEGIN
	DECLARE @I_Observados int = 0
	DECLARE @D_FecProceso datetime = GETDATE() 
	DECLARE @I_ObservID int = 43
	DECLARE @I_TablaID int = 4

	BEGIN TRANSACTION
	BEGIN TRY 
	
		


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



IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_U_44_ValidarPeriodoConceptoDetalleObligacionPorDetOblID')
	DROP PROCEDURE [dbo].[USP_U_44_ValidarPeriodoConceptoDetalleObligacionPorDetOblID]
GO

CREATE PROCEDURE [dbo].[USP_U_44_ValidarPeriodoConceptoDetalleObligacionPorDetOblID]	
	@I_RowID	 tinyint,
	@B_Resultado bit output,
	@T_Message	 nvarchar(4000) OUTPUT	
AS
--declare	@I_RowID  	     int,
--			@B_Resultado	 bit,
--			@T_Message		 nvarchar(4000)
--exec USP_U_44_ValidarPeriodoConceptoDetalleObligacionPorDetOblID @I_RowID, @B_Resultado output, @T_Message output
--select @B_Resultado as resultado, @T_Message as mensaje
BEGIN
	DECLARE @I_Observados int = 0
	DECLARE @D_FecProceso datetime = GETDATE() 
	DECLARE @I_ObservID int = 44
	DECLARE @I_TablaID int = 4

	BEGIN TRANSACTION
	BEGIN TRY 
		DECLARE @Cod_alu	varchar(20)
		DECLARE @Cod_Rc		varchar(5)
		DECLARE @Cuota_Pago	int
		DECLARE @Concepto	int
		DECLARE @P			varchar(3)
		DECLARE @T_Anio		int
		DECLARE @T_P_pri	varchar(3)
		DECLARE @B_Correcto	int
		
		SELECT @Concepto = Concepto, @P = P, @B_Correcto = B_Correcto
		  FROM TR_Ec_Det
		 WHERE I_RowID = @I_RowID

		IF (@B_Correcto = 1)
		BEGIN
			EXECUTE USP_MigracionTP_U_RemoverObservacionDetalleObligacion @I_RowID, @I_TablaID, @I_ObservID, @D_FecProceso
		END
		ELSE
		BEGIN
			SELECT @T_P_pri = P FROM TR_Cp_Pri WHERE Id_cp = @Concepto

			IF (@T_P_pri = @P)
			BEGIN
				EXECUTE USP_MigracionTP_U_RemoverObservacionDetalleObligacion @I_RowID, @I_TablaID, @I_ObservID, @D_FecProceso
			END
			ELSE
			BEGIN
				EXECUTE USP_MigracionTP_U_RegistrarObservacionDetalleObligacion @I_RowID, @I_TablaID, @I_ObservID, @D_FecProceso
			END
		END
		COMMIT TRANSACTION;
			SET @T_Message = CAST(@@ROWCOUNT AS varchar)
			SET @B_Resultado = 1
	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION
		SET @B_Resultado = 0
		SET @T_Message = ERROR_MESSAGE() + ' (Linea: ' + CAST(ERROR_LINE() AS varchar(11)) + ').' 
	END CATCH
END
GO


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_U_44_ValidarPeriodoConceptoDetalleObligacion')
	DROP PROCEDURE [dbo].[USP_U_44_ValidarPeriodoConceptoDetalleObligacion]
GO

CREATE PROCEDURE [dbo].[USP_U_44_ValidarPeriodoConceptoDetalleObligacion]	
	@I_RowID	 tinyint,
	@B_Resultado bit output,
	@T_Message	 nvarchar(4000) OUTPUT	
AS
--declare	@I_RowID  	     int,
--			@B_Resultado	 bit,
--			@T_Message		 nvarchar(4000)
--exec USP_U_InicializarEstadoValidacionObligacionPago @I_ProcedenciaID, @I_Anio, @B_Resultado output, @T_Message output
--select @B_Resultado as resultado, @T_Message as mensaje
BEGIN
	DECLARE @I_Observados int = 0
	DECLARE @D_FecProceso datetime = GETDATE() 
	DECLARE @I_ObservID int = 43
	DECLARE @I_TablaID int = 4

	BEGIN TRANSACTION
	BEGIN TRY 
	
		


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



IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_U_15_ValidarAnioConceptoDetalleCuotaPagoPorDetOblID')
	DROP PROCEDURE [dbo].[USP_U_15_ValidarAnioConceptoDetalleCuotaPagoPorDetOblID]
GO

CREATE PROCEDURE [dbo].[USP_U_15_ValidarAnioConceptoDetalleCuotaPagoPorDetOblID]	
	@I_RowID	 tinyint,
	@B_Resultado bit output,
	@T_Message	 nvarchar(4000) OUTPUT	
AS
--declare	@I_RowID  	     int,
--			@B_Resultado	 bit,
--			@T_Message		 nvarchar(4000)
--exec USP_U_15_ValidarAnioConceptoDetalleCuotaPagoPorDetOblID @I_RowID, @B_Resultado output, @T_Message output
--select @B_Resultado as resultado, @T_Message as mensaje
BEGIN
	DECLARE @I_Observados int = 0
	DECLARE @D_FecProceso datetime = GETDATE() 
	DECLARE @I_ObservID int = 15
	DECLARE @I_TablaID int = 4

	BEGIN TRANSACTION
	BEGIN TRY 
		DECLARE @Cod_alu	varchar(20)
		DECLARE @Cod_Rc		varchar(5)
		DECLARE @Cuota_Pago	int
		DECLARE @Concepto	int
		DECLARE @T_Anio		varchar(5)
		DECLARE @T_Anio_des	varchar(5)
		DECLARE @T_Anio_pri	varchar(5)
		DECLARE @B_Correcto	int
		
		SELECT @Concepto = Concepto, @B_Correcto = B_Correcto,
			   @T_Anio = Ano, @Cuota_Pago = Cuota_pago
		  FROM TR_Ec_Det
		 WHERE I_RowID = @I_RowID

		IF (@B_Correcto = 1)
		BEGIN
			EXECUTE USP_MigracionTP_U_RemoverObservacionDetalleObligacion @I_RowID, @I_TablaID, @I_ObservID, @D_FecProceso
		END
		ELSE
		BEGIN
			SELECT @T_Anio_pri = Ano FROM TR_Cp_Pri WHERE Id_cp = @Concepto
			SELECT @T_Anio_des = CAST(I_Anio as varchar) FROM TR_Cp_Des WHERE Cuota_pago = @Cuota_Pago

			IF (@T_Anio_pri = @T_Anio_des)
			BEGIN
				EXECUTE USP_MigracionTP_U_RemoverObservacionDetalleObligacion @I_RowID, @I_TablaID, @I_ObservID, @D_FecProceso
			END
			ELSE
			BEGIN
				EXECUTE USP_MigracionTP_U_RegistrarObservacionDetalleObligacion @I_RowID, @I_TablaID, @I_ObservID, @D_FecProceso
			END
		END
		COMMIT TRANSACTION;
			SET @T_Message = CAST(@@ROWCOUNT AS varchar)
			SET @B_Resultado = 1
	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION
		SET @B_Resultado = 0
		SET @T_Message = ERROR_MESSAGE() + ' (Linea: ' + CAST(ERROR_LINE() AS varchar(11)) + ').' 
	END CATCH
END
GO


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_U_15_ValidarPeriodoConceptoDetalleCuotaPago')
	DROP PROCEDURE [dbo].[USP_U_15_ValidarPeriodoConceptoDetalleCuotaPago]
GO

CREATE PROCEDURE [dbo].[USP_U_15_ValidarPeriodoConceptoDetalleCuotaPago]	
	@I_RowID	 tinyint,
	@B_Resultado bit output,
	@T_Message	 nvarchar(4000) OUTPUT	
AS
--declare	@I_RowID  	     int,
--			@B_Resultado	 bit,
--			@T_Message		 nvarchar(4000)
--exec USP_U_15_ValidarAnioConceptoDetalleCuotaPago @I_RowID, @B_Resultado output, @T_Message output
--select @B_Resultado as resultado, @T_Message as mensaje
BEGIN
	DECLARE @I_Observados int = 0
	DECLARE @D_FecProceso datetime = GETDATE() 
	DECLARE @I_ObservID int = 43
	DECLARE @I_TablaID int = 4

	BEGIN TRANSACTION
	BEGIN TRY 
	
		DECLARE @Cuota_Pago	int
		DECLARE @Concepto	int
		DECLARE @P			varchar(3)
		DECLARE @T_P_pri	varchar(3)
		


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



IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_U_17_ValidarPeriodoConceptoDetalleCuotaDePagoPorDetOblID')
	DROP PROCEDURE [dbo].[USP_U_17_ValidarPeriodoConceptoDetalleCuotaDePagoPorDetOblID]
GO

CREATE PROCEDURE [dbo].[USP_U_17_ValidarPeriodoConceptoDetalleCuotaDePagoPorDetOblID]	
	@I_RowID	 tinyint,
	@B_Resultado bit output,
	@T_Message	 nvarchar(4000) OUTPUT	
AS
--declare	@I_RowID  	     int,
--			@B_Resultado	 bit,
--			@T_Message		 nvarchar(4000)
--exec USP_U_17_ValidarPeriodoConceptoDetalleCuotaDePagoPorDetOblID @I_RowID, @B_Resultado output, @T_Message output
--select @B_Resultado as resultado, @T_Message as mensaje
BEGIN
	DECLARE @I_Observados int = 0
	DECLARE @D_FecProceso datetime = GETDATE() 
	DECLARE @I_ObservID int = 17
	DECLARE @I_TablaID int = 4

	BEGIN TRANSACTION
	BEGIN TRY 
	
		DECLARE @Cuota_Pago	int
		DECLARE @Concepto	int
		DECLARE @I_PerDetID	int
		DECLARE @P			varchar(3)
		DECLARE @I_Periodo	int

		SELECT @Cuota_Pago = Cuota_pago, @P = DET.P, @I_PerDetID = CCO.I_OpcionID 
		  FROM TR_Ec_Det DET
		       INNER JOIN BD_OCEF_CtasPorCobrar.dbo.TC_CatalogoOpcion CCO ON DET.P = CCO.T_OpcionCod AND CCO.I_ParametroID = 5
		 WHERE I_RowID = @I_RowID

		SELECT @I_Periodo = I_Periodo FROM TR_Cp_Des WHERE Cuota_pago = @Cuota_Pago

		IF (@I_PerDetID = @I_Periodo)
		BEGIN
			EXECUTE USP_MigracionTP_U_RemoverObservacionDetalleObligacion @I_RowID, @I_TablaID, @I_ObservID, @D_FecProceso
		END
		ELSE
		BEGIN
			EXECUTE USP_MigracionTP_U_RegistrarObservacionDetalleObligacion @I_RowID, @I_TablaID, @I_ObservID, @D_FecProceso
		END

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


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_U_17_ValidarPeriodoConceptoDetalleCuotaDePago')
	DROP PROCEDURE [dbo].[USP_U_17_ValidarPeriodoConceptoDetalleCuotaDePago]
GO

CREATE PROCEDURE [dbo].[USP_U_17_ValidarPeriodoConceptoDetalleCuotaDePago]	
	@I_RowID	 tinyint,
	@B_Resultado bit output,
	@T_Message	 nvarchar(4000) OUTPUT	
AS
--declare	@I_RowID  	     int,
--			@B_Resultado	 bit,
--			@T_Message		 nvarchar(4000)
--exec USP_U_InicializarEstadoValidacionObligacionPago @I_ProcedenciaID, @I_Anio, @B_Resultado output, @T_Message output
--select @B_Resultado as resultado, @T_Message as mensaje
BEGIN
	DECLARE @I_Observados int = 0
	DECLARE @D_FecProceso datetime = GETDATE() 
	DECLARE @I_ObservID int = 43
	DECLARE @I_TablaID int = 4

	BEGIN TRANSACTION
	BEGIN TRY 
	
		DECLARE @Cuota_Pago	int
		DECLARE @Concepto	int
		DECLARE @P			varchar(3)
		DECLARE @T_P_pri	varchar(3)
		


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


