USE BD_OCEF_MigracionTP
GO

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_Tasas_CuotaPago_TemporalTasas_MigracionTP_IU_CopiarTabla')
BEGIN
	DROP PROCEDURE dbo.USP_Tasas_CuotaPago_TemporalTasas_MigracionTP_IU_CopiarTabla
END
GO

CREATE PROCEDURE dbo.USP_Tasas_CuotaPago_TemporalTasas_MigracionTP_IU_CopiarTabla
(
	@I_ProcedenciaID tinyint,
	@T_Codigo_bnc	 varchar(250),
	@B_Resultado	 bit output,
	@T_Message		 nvarchar(4000) OUTPUT
)
AS
/*
	declare @B_Resultado  bit,
			@I_ProcedenciaID	tinyint = 4,
			@T_Codigo_bnc		nvarchar(250) = N'',
			@T_Message			nvarchar(4000)
	exec USP_Tasas_CuotaPago_TemporalTasas_MigracionTP_IU_CopiarTabla @I_ProcedenciaID, @T_Codigo_bnc, @B_Resultado output, @T_Message output
	select @B_Resultado as resultado, @T_Message as mensaje
*/
BEGIN
	DECLARE @D_FecProceso datetime = GETDATE()
	DECLARE @I_CpDes int = 0
	DECLARE @I_Removidos int = 0
	DECLARE @I_Actualizados int = 0
	DECLARE @I_Insertados int = 0

	CREATE TABLE #Tbl_output  
	(
		accion  varchar(20), 
		CUOTA_PAGO	float, 
		ELIMINADO bit,
		INS_DESCRIPCIO varchar(255), 
		INS_N_CTA_CTE varchar(255), 
		INS_CODIGO_BNC varchar(255), 
		INS_FCH_VENC date, 
		INS_PRIORIDAD varchar(255), 
		INS_C_MORA varchar(255), 
		DEL_DESCRIPCIO varchar(255), 
		DEL_N_CTA_CTE varchar(255), 
		DEL_CODIGO_BNC varchar(255), 
		DEL_FCH_VENC date, 
		DEL_PRIORIDAD varchar(255), 
		DEL_C_MORA varchar(255),
		B_Removido	bit
	)

	BEGIN TRANSACTION
	BEGIN TRY
		
		MERGE TR_Cp_Des AS TRG
		USING (SELECT * FROM BD_OCEF_TemporalTasas.dbo.cp_des WHERE codigo_bnc = @T_Codigo_bnc) AS SRC
		   ON TRG.Cuota_pago = SRC.cuota_pago 
			  AND TRG.Eliminado = SRC.eliminado
			  AND TRG.Codigo_bnc = SRC.codigo_bnc
		WHEN MATCHED THEN
			  UPDATE SET TRG.Descripcio = SRC.descripcio,
				  		 TRG.N_cta_cte = SRC.n_cta_cte,
				  		 TRG.Codigo_bnc = SRC.codigo_bnc,
				  		 TRG.Fch_venc = SRC.fch_venc,
				  		 TRG.Prioridad = SRC.prioridad,
				  		 TRG.C_mora = SRC.c_mora
		WHEN NOT MATCHED BY TARGET THEN
			 INSERT (Cuota_pago, Descripcio, N_cta_cte, Eliminado, Codigo_bnc, Fch_venc, Prioridad, C_mora, I_ProcedenciaID, D_FecCarga, B_Actualizado)
			 VALUES (SRC.cuota_pago, SRC.descripcio, SRC.n_cta_cte, SRC.eliminado, SRC.codigo_bnc, SRC.fch_venc, SRC.prioridad, SRC.c_mora, @I_ProcedenciaID, @D_FecProceso, 1)
		WHEN NOT MATCHED BY SOURCE AND TRG.I_ProcedenciaID = @I_ProcedenciaID THEN
			 UPDATE SET TRG.B_Removido = 1, 
				  		TRG.D_FecRemovido = @D_FecProceso
		OUTPUT	$ACTION, inserted.CUOTA_PAGO, inserted.ELIMINADO, inserted.DESCRIPCIO, inserted.N_CTA_CTE,  
				inserted.CODIGO_BNC, inserted.FCH_VENC, inserted.PRIORIDAD, inserted.C_MORA, deleted.DESCRIPCIO, 
				deleted.N_CTA_CTE, deleted.CODIGO_BNC, deleted.FCH_VENC, deleted.PRIORIDAD, deleted.C_MORA, 
				deleted.B_Removido INTO #Tbl_output;

		UPDATE	TR_Cp_Des 
		   SET	B_Actualizado = 0, B_Migrable = 0, 
				D_FecMigrado = NULL, B_Migrado = 0,
				I_Anio = NULL, I_CatPagoID = NULL, I_Periodo = NULL
		WHERE	I_ProcedenciaID = @I_ProcedenciaID

		UPDATE	t_CpDes
		   SET	t_CpDes.B_Actualizado = 1,
				t_CpDes.D_FecActualiza = @D_FecProceso
		  FROM  TR_Cp_Des  AS t_CpDes
				INNER JOIN 	#Tbl_output as t_out ON t_out.CUOTA_PAGO = t_CpDes.Cuota_pago 
							AND t_out.ELIMINADO = t_CpDes.Eliminado AND t_out.accion = 'UPDATE' AND t_out.B_Removido = 0
		WHERE 
				t_out.INS_DESCRIPCIO <> t_out.DEL_DESCRIPCIO OR
				t_out.INS_N_CTA_CTE <> t_out.DEL_N_CTA_CTE OR
				t_out.INS_CODIGO_BNC <> t_out.DEL_CODIGO_BNC OR
				t_out.INS_FCH_VENC <> t_out.DEL_FCH_VENC OR
				t_out.INS_PRIORIDAD <> t_out.DEL_PRIORIDAD OR
				t_out.INS_C_MORA <> t_out.DEL_C_MORA

		

		SET @I_CpDes = (SELECT COUNT(cuota_pago) FROM BD_OCEF_TemporalTasas.dbo.cp_des WHERE codigo_bnc = @T_Codigo_bnc)
		SET @I_Insertados = (SELECT COUNT(*) FROM #Tbl_output WHERE accion = 'INSERT')
		SET @I_Actualizados = (SELECT COUNT(*) FROM #Tbl_output WHERE accion = 'UPDATE' AND B_Removido = 0)
		SET @I_Removidos = (SELECT COUNT(*) FROM #Tbl_output WHERE accion = 'UPDATE' AND B_Removido = 1)

		SELECT @I_CpDes AS tot_cuotaPago, @I_Insertados AS cant_inserted, @I_Actualizados as cant_updated, @I_Removidos as cant_removed, @D_FecProceso as fec_proceso
		
		SET @B_Resultado = 1

		SET @T_Message =  '[{ ' +
							 'Type: "summary", ' + 
							 'Title: "Total:", '+ 
							 'Value: ' + CAST(@I_CpDes AS varchar) +
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

		COMMIT TRANSACTION
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


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_Tasas_CuotaPago_MigracionTP_U_InicializarEstadosValidacion')
	DROP PROCEDURE [dbo].[USP_Tasas_CuotaPago_MigracionTP_U_InicializarEstadosValidacion]
GO

CREATE PROCEDURE USP_Tasas_CuotaPago_MigracionTP_U_InicializarEstadosValidacion	
	@I_RowID	  int = NULL,
	@I_ProcedenciaID tinyint,
	@B_Resultado  bit output,
	@T_Message	  nvarchar(4000) OUTPUT	
AS
--declare @B_Resultado  bit,
--		@I_RowID	  int = NULL,
--		@I_ProcedenciaID	tinyint = 3,
--		@T_Message	  nvarchar(4000)
--exec USP_Tasas_CuotaPago_MigracionTP_U_InicializarEstadosValidacion @I_RowID, @I_ProcedenciaID, @B_Resultado output, @T_Message output
--select @B_Resultado as resultado, @T_Message as mensaje
BEGIN
	BEGIN TRANSACTION
	BEGIN TRY 
		UPDATE	TR_Cp_Des 
		   SET	B_Actualizado = IIF(B_Actualizado = 1, B_Actualizado, 0), 
				B_Migrable = 1, 
				D_FecMigrado = NULL
		 WHERE	I_ProcedenciaID = @I_ProcedenciaID 
				AND (I_RowID = IIF(@I_RowID IS NULL, I_RowID, @I_RowID))

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






IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_Tasas_CuotaPago_MigracionTP_IU_AsignarServicioCtasPorCobrar')
BEGIN
	DROP PROCEDURE dbo.USP_Tasas_CuotaPago_MigracionTP_IU_AsignarServicioCtasPorCobrar
END
GO

CREATE PROCEDURE dbo.USP_Tasas_CuotaPago_MigracionTP_IU_AsignarServicioCtasPorCobrar
(
	@I_ProcedenciaID tinyint,
	@T_Codigo_bnc	 varchar(250),
	@B_Resultado	 bit output,
	@T_Message		 nvarchar(4000) OUTPUT
)
AS
--declare @B_Resultado  bit,
--		@I_ProcedenciaID	tinyint = 4,
--		@T_Codigo_bnc		nvarchar(250) = N'',
--		@T_Message			nvarchar(4000)
--exec USP_Tasas_CuotaPago_MigracionTP_IU_AsignarServicioCtasPorCobrar @I_ProcedenciaID, @T_Codigo_bnc, @B_Resultado output, @T_Message output
--select @B_Resultado as resultado, @T_Message as mensaje
BEGIN
	DECLARE @D_FecProceso datetime = GETDATE()

	BEGIN TRANSACTION
	BEGIN TRY
		
		SET @B_Resultado = 1


		COMMIT TRANSACTION
	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION
		SET @B_Resultado = 0
		SET @T_Message = ERROR_MESSAGE() + ' LINE: ' + CAST(ERROR_LINE() AS varchar(10)) 
	END CATCH
	
END
GO