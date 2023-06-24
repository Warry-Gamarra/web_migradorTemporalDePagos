BEGIN TRANSACTION DEL_OBL_MIGRATION;
BEGIN TRY
	DELETE cabecera_obligaciones  
	FROM BD_OCEF_CtasPorCobrar.dbo.TR_ObligacionAluCab cabecera_obligaciones
		 LEFT JOIN BD_OCEF_CtasPorCobrar.dbo.TR_ObligacionAluDet detalle_obligaciones 
				   ON cabecera_obligaciones.I_ObligacionAluID = detalle_obligaciones.I_ObligacionAluID
		 WHERE cabecera_obligaciones.B_Migrado = 1 AND detalle_obligaciones.I_ObligacionAluID IS NULL
	
	DELETE matricula_alumno
	FROM BD_OCEF_CtasPorCobrar.dbo.TC_MatriculaAlumno matricula_alumno
		 
		 WHERE matricula_alumno.B_Migrado = 1
	
	DECLARE @I_ObligacionAluID int,
			@I_MatAluID int

	SET @I_MatAluID = IDENT_CURRENT('BD_OCEF_CtasPorCobrar.dbo.TC_MatriculaAlumno');
	SET @I_ObligacionAluID = IDENT_CURRENT('BD_OCEF_CtasPorCobrar.dbo.TR_ObligacionAluCab');
	SELECT @I_MatAluID AS 'TC_MatriculaAlumno', @I_ObligacionAluID AS 'TR_ObligacionAluCab'


	SET @I_MatAluID = (SELECT MAX(I_MatAluID) FROM BD_OCEF_CtasPorCobrar.dbo.TC_MatriculaAlumno);
	SET @I_ObligacionAluID = (SELECT MAX(I_ObligacionAluID) FROM BD_OCEF_CtasPorCobrar.dbo.TR_ObligacionAluCab);

	DBCC CHECKIDENT('BD_OCEF_CtasPorCobrar.dbo.TC_MatriculaAlumno', 'RESEED', @I_MatAluID)
	DBCC CHECKIDENT('BD_OCEF_CtasPorCobrar.dbo.TR_ObligacionAluCab', 'RESEED', @I_ObligacionAluID)


	SET @I_MatAluID = IDENT_CURRENT('BD_OCEF_CtasPorCobrar.dbo.TC_MatriculaAlumno');
	SET @I_ObligacionAluID = IDENT_CURRENT('BD_OCEF_CtasPorCobrar.dbo.TR_ObligacionAluCab');
	SELECT @I_MatAluID AS 'TC_MatriculaAlumno', @I_ObligacionAluID AS 'TR_ObligacionAluCab'

	COMMIT TRANSACTION DEL_OBL_MIGRATION;
END TRY
BEGIN CATCH
	ROLLBACK TRANSACTION DEL_OBL_MIGRATION;
END CATCH
GO



IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_IU_CopiarEstadoCuentaObligaciones')
	DROP PROCEDURE [dbo].[USP_IU_CopiarEstadoCuentaObligaciones]
GO

CREATE PROCEDURE [dbo].[USP_IU_CopiarEstadoCuentaObligaciones]	
	@I_ProcedenciaID	tinyint,
	@T_SchemaDB			varchar(20),
	@I_ProcesoID		int = NULL,
	@I_Anio				int = NULL,
	@B_Resultado		bit output,
	@T_Message			nvarchar(4000) OUTPUT	
AS
--declare   @I_ProcedenciaID tinyint = 3,
--			@T_SchemaDB   varchar(20) = 'euded',
--			@I_ProcesoID	 int = null, 
--			@I_Anio			 int = 2012, 
--			@B_Resultado	 bit, 
--			@T_Message nvarchar(4000)
--exec USP_IU_CopiarEstadoCuentaObligaciones @I_ProcedenciaID, @T_SchemaDB, @I_ProcesoID, @I_Anio, @B_Resultado output, @T_Message output
--select @B_Resultado as resultado, @T_Message as mensaje
BEGIN
	DECLARE @I_EcObl int = 0
	DECLARE @I_Removidos int = 0
	DECLARE @I_Actualizados int = 0
	DECLARE @I_Insertados int = 0
	DECLARE @D_FecProceso datetime = GETDATE() 
	DECLARE @T_SQL nvarchar(max)

	BEGIN TRANSACTION
	BEGIN TRY

		SET @T_SQL = '  DELETE TR_Ec_Pri
						WHERE I_ProcedenciaID = '+ CAST(@I_ProcedenciaID as varchar(3)) + ''


		IF (ISNULL(@I_Anio, '') <> '')
		BEGIN
			SET @T_SQL = @T_SQL + ' AND TR_Ec_Pri.Ano = ''' + CAST(@I_Anio as varchar) + ''' '
		END

		EXEC sp_executesql @T_SQL
		SET @I_Removidos = @@ROWCOUNT


		SET @T_SQL = '	DECLARE @D_FecProceso datetime = GETDATE()

						INSERT TR_Ec_Pri(Cod_alu, Cod_rc, Tot_apagar, Nro_ec, Fch_ec, Tot_pagado, Saldo, Ano, P, Eliminado, 
										 I_ProcedenciaID, D_FecCarga, B_Actualizado, D_FecActualiza, B_Migrable)
								  SELECT pri.cod_alu, pri.cod_rc, pri.tot_apagar, pri.nro_ec, pri.fch_ec, pri.tot_pagado, pri.saldo, pri.ano, pri.p, pri.eliminado, ' 
										 + CAST(@I_ProcedenciaID as varchar(3)) + ', @D_FecProceso, 0, NULL, 0
								    FROM BD_OCEF_TemporalPagos.' + @T_SchemaDB + '.ec_pri pri
										 LEFT JOIN TR_Ec_Pri TRG ON TRG.Nro_ec = pri.nro_ec  
													AND TRG.I_ProcedenciaID = '+ CAST(@I_ProcedenciaID as varchar(3)) + ' 
												    AND pri.Ano = TRG.Ano 	
								   WHERE TRG.Nro_ec IS NULL'
		
		IF (ISNULL(@I_Anio, '') <> '')
		BEGIN
			SET @T_SQL = @T_SQL + ' AND pri.Ano = ''' + CAST(@I_Anio as varchar) + ''' '
		END

		print @T_SQL
		EXEC sp_executesql @T_SQL
		SET @I_Insertados = @@ROWCOUNT

		SET @T_Message = 'Total Eliminado: ' + CAST(@I_Removidos AS varchar) + CHAR(13) + CHAR(10) + 'Total insertados: ' + CAST(@I_Insertados AS varchar);
		SET @B_Resultado = 1;

		COMMIT TRANSACTION;

	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION
		SET @T_Message = 'DESCRIPCION: ' + ERROR_MESSAGE() + CHAR(13) + CHAR(10) +  
						 'LINEA: '  + CAST(ERROR_LINE() AS varchar);
		SET @B_Resultado = 0;
	END CATCH
END
GO



IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_IU_MigrarMatriculaObligacionesCtasPorCobrar')
	DROP PROCEDURE [dbo].[USP_IU_MigrarMatriculaObligacionesCtasPorCobrar]
GO


CREATE PROCEDURE [dbo].[USP_IU_MigrarMatriculaObligacionesCtasPorCobrar]	
	@I_ProcedenciaID	tinyint,
	@I_ProcesoID		int = NULL,
	@I_Anio				int = NULL,
	@B_Resultado		bit output,
	@T_Message			nvarchar(4000) OUTPUT	
AS
--declare   @I_ProcedenciaID tinyint = 3,
--			@I_ProcesoID	 int = null, 
--			@I_Anio			 int = 2011, 
--			@B_Resultado	 bit, 
--			@T_Message nvarchar(4000)
--exec USP_IU_MigrarMatriculaObligacionesCtasPorCobrar @I_ProcedenciaID, @I_ProcesoID, @I_Anio, @B_Resultado output, @T_Message output
--select @B_Resultado as resultado, @T_Message as mensaje
BEGIN
	BEGIN TRANSACTION

	BEGIN TRY
	WITH alumnos_matricula AS (
		SELECT DISTINCT Cod_alu, Cod_rc, CAST(Ano as int) AS Ano, I_Periodo, 'S' AS C_EstMat 
		FROM TR_Ec_Obl
		WHERE ISNUMERIC(ANO) = 1
			  AND I_ProcedenciaID = @I_ProcedenciaID
			  AND B_Migrable = 1
	)

	INSERT INTO BD_OCEF_CtasPorCobrar.dbo.TC_MatriculaAlumno (C_CodRc, C_CodAlu, I_Anio, I_Periodo, C_EstMat, C_Ciclo, B_Ingresante, I_CredDesaprob, B_Habilitado, B_Eliminado, B_Migrado)
	SELECT A.Cod_rc, A.Cod_alu, A.Ano, A.I_Periodo, A.C_EstMat, NULL as C_Ciclo, NULL as B_Ingresante, NULL as I_CredDesaprob, 1 as B_Habilitado, 0 as B_Eliminado, 1 as B_Migrado
	  FROM alumnos_matricula A 
		   LEFT JOIN BD_OCEF_CtasPorCobrar.dbo.TC_MatriculaAlumno MA ON MA.C_CodAlu = A.Cod_alu 
																		AND MA.C_CodRc = A.Cod_rc 
																		AND MA.I_Anio  = A.Ano
																		AND MA.I_Periodo = A.I_Periodo
	WHERE Ano = @I_Anio
		  AND MA.I_MatAluID IS NULL;

	SET @T_Message = CAST(@@ROWCOUNT AS varchar);
	SET @B_Resultado = 1;

	COMMIT TRANSACTION;

	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION
		SET @T_Message = 'DESCRIPCION: ' + ERROR_MESSAGE() + CHAR(10) +  CHAR(13) +  
						 'LINEA: '  + CAST(ERROR_LINE() AS varchar);
		SET @B_Resultado = 1;
	END CATCH
END
GO



IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_IU_MigrarObligacionesCtasPorCobrar')
	DROP PROCEDURE [dbo].[USP_IU_MigrarObligacionesCtasPorCobrar]
GO


CREATE PROCEDURE [dbo].[USP_IU_MigrarObligacionesCtasPorCobrar]	
	@I_ProcedenciaID	tinyint,
	@I_ProcesoID		int = NULL,
	@I_Anio				int = NULL,
	@B_Resultado		bit output,
	@T_Message			nvarchar(4000) OUTPUT	
AS
--declare   @I_ProcedenciaID tinyint = 3,
--			@I_ProcesoID	 int = null, 
--			@I_Anio			 int = null, 
--			@B_Resultado	 bit, 
--			@T_Message nvarchar(4000)
--exec USP_IU_MigrarObligacionesCtasPorCobrar @I_ProcedenciaID, @I_ProcesoID, @I_Anio, @B_Resultado output, @T_Message output
--select @B_Resultado as resultado, @T_Message as mensaje
BEGIN

	DECLARE @D_FecProceso datetime = GETDATE()
	DECLARE @I_MigracionTablaOblID tinyint = 5
	DECLARE @I_MigracionTablaDetID tinyint = 4
	DECLARE @T_Moneda varchar(3) = 'PEN'

	DECLARE @I_OblRowID int = 0
	DECLARE @Cuota_pago  int
	DECLARE @I_MatAluID  int
	DECLARE @I_Monto int = 0
	DECLARE @B_Pagado bit = 0
	DECLARE @D_FecVencto date

	DECLARE @I_TipoDocumento int = 0
	DECLARE @T_DescDocumento varchar(max) = 0
	DECLARE @B_Mora bit = 0 


	BEGIN TRANSACTION;
	BEGIN TRY 

		WITH obligaciones_migracion AS (
			SELECT * 
			FROM TR_Ec_Obl
			WHERE ISNUMERIC(ANO) = 1
				  AND I_ProcedenciaID = @I_ProcedenciaID
				  AND B_Migrable = 1
		),
		obligaciones_migracion_anio AS (
			SELECT * 
			FROM  obligaciones_migracion
			WHERE Ano = @I_Anio
		)


		--I_ObligacionAluID, I_ProcesoID, I_MatAluID, C_Moneda, I_MontoOblig, D_FecVencto, B_Pagado, B_Habilitado, 
		--B_Eliminado, I_UsuarioCre, D_FecCre, I_UsuarioMod, D_FecMod, B_Migrado, I_MigracionTablaID, I_MigracionRowID

		SELECT obl.Cuota_pago, mat.I_MatAluID, obl.Monto, obl.Fch_venc, obl.Pagado, obl.I_RowID
		  INTO #obligaciones_migracion_anio
		  FROM obligaciones_migracion_anio obl
			   INNER JOIN BD_OCEF_CtasPorCobrar.dbo.TC_MatriculaAlumno mat ON 
						  obl.cod_alu = mat.C_CodAlu 
						  AND obl.cod_rc = mat.C_CodRc 
						  AND CAST(obl.ano AS int) = mat.I_Anio 
						  AND obl.I_Periodo = mat.I_Periodo


		--I_ObligacionAluDetID, I_ObligacionAluID, I_ConcPagID, I_Monto, B_Pagado, D_FecVencto, I_TipoDocumento, T_DescDocumento, 
		--B_Habilitado, B_Eliminado, I_UsuarioCre, D_FecCre, I_UsuarioMod, D_FecMod, B_Mora, B_Migrado, I_MigracionTablaID, I_MigracionRowID

		SELECT det.I_OblRowID, det.Concepto, det.Monto, det.Pagado, det.Fch_venc, 
			   CASE WHEN CAST(det.Documento as varchar(max)) IS NULL THEN NULL ELSE 138 END AS I_TipoDocumento, 
			   CAST(det.Documento as varchar(max)) AS T_DescDocumento, det.Eliminado, det.I_RowID,
			   CASE WHEN cp_pri.Id_cp IS NULL THEN 0 ELSE 1 END AS B_Mora
		  INTO #detalle_obligaciones_migracion
		  FROM TR_Ec_Det det
			   INNER JOIN #obligaciones_migracion_anio obl ON det.I_OblRowID = obl.I_RowID
			   LEFT JOIN TR_Cp_Pri cp_pri ON cp_pri.Id_cp = det.Concepto AND cp_pri.Descripcio like '%Mora_%'
		 WHERE det.Concepto_f = 0
			   AND det.B_Migrable = 1


		DECLARE cursor_obligaciones CURSOR
			FOR SELECT Cuota_pago, I_MatAluID, Monto, Fch_venc, Pagado, I_RowID 
				  FROM #obligaciones_migracion_anio;

		OPEN cursor_obligaciones;

		FETCH NEXT FROM cursor_obligaciones INTO
						@Cuota_pago, @I_MatAluID, @I_Monto, @D_FecVencto, @B_Pagado, @I_OblRowID;


		WHILE @@FETCH_STATUS = 0
		BEGIN
			DECLARE @I_ObligacionAluID int = (SELECT I_ObligacionAluID FROM BD_OCEF_CtasPorCobrar.dbo.TR_ObligacionAluCab 
											  WHERE I_MigracionRowID = @I_OblRowID AND I_MigracionTablaID = @I_MigracionTablaOblID)

			IF (@I_ObligacionAluID IS NULL)
			BEGIN

				INSERT INTO BD_OCEF_CtasPorCobrar.dbo.TR_ObligacionAluCab (I_ProcesoID, I_MatAluID, C_Moneda, I_MontoOblig, 
																		   D_FecVencto, B_Pagado, B_Habilitado, B_Eliminado, I_UsuarioCre, 
																		   D_FecCre, B_Migrado, I_MigracionTablaID, I_MigracionRowID)
																   VALUES (@Cuota_pago, @I_MatAluID,@T_Moneda, @I_Monto,
																		   @D_FecVencto, @B_Pagado,1, 0, NULL, 
																		   NULL, 1, @I_MigracionTablaOblID, @I_OblRowID)
			END
			ELSE
			BEGIN 

				UPDATE BD_OCEF_CtasPorCobrar.dbo.TR_ObligacionAluCab
				   SET I_ProcesoID = @Cuota_pago, 
					   I_MatAluID = @I_MatAluID, 
					   I_MontoOblig = @I_Monto, 
					   D_FecVencto = @D_FecVencto, 
					   B_Pagado = 0, 
					   I_UsuarioMod = NULL, 
					   D_FecMod = @D_FecProceso
				 WHERE I_ObligacionAluID = @I_OblRowID;


				MERGE INTO BD_OCEF_CtasPorCobrar.dbo.TR_ObligacionAluDet AS TRG
				USING (SELECT * FROM #detalle_obligaciones_migracion WHERE I_OblRowID = @I_OblRowID) AS SRC
				ON TRG.I_MigracionRowID = SRC.I_RowID AND
					TRG.I_MigracionTablaID = @I_MigracionTablaDetID
				WHEN MATCHED AND TRG.I_UsuarioCre IS NULL THEN
					UPDATE SET TRG.I_ObligacionAluID = SRC.I_OblRowID, 
								TRG.I_ConcPagID = SRC.Concepto, 
								TRG.I_Monto = SRC.Monto, 
								TRG.B_Pagado = 0, 
								TRG.D_FecVencto = SRC.Fch_venc, 
								TRG.I_TipoDocumento = SRC.I_TipoDocumento, 
								TRG.T_DescDocumento = SRC.T_DescDocumento, 
								TRG.B_Mora = SRC.B_Mora, 
								TRG.I_UsuarioMod = 1, 
								TRG.D_FecMod = @D_FecProceso
				WHEN NOT MATCHED THEN
					INSERT (I_ObligacionAluID, I_ConcPagID, I_Monto, B_Pagado, D_FecVencto, I_TipoDocumento, T_DescDocumento, 
							B_Habilitado, B_Eliminado, I_UsuarioCre, D_FecCre, B_Mora, B_Migrado, I_MigracionTablaID, I_MigracionRowID)
					VALUES (SRC.I_OblRowID, SRC.Concepto, SRC.Monto, 0, SRC.Fch_venc, SRC.I_TipoDocumento, SRC.T_DescDocumento, 
							1, SRC.Eliminado, NULL, NULL, SRC.B_Mora, 1, @I_MigracionTablaDetID, SRC.I_RowID);

			END

			FETCH NEXT FROM cursor_obligaciones INTO
							@Cuota_pago, @I_MatAluID, @I_Monto, @D_FecVencto, @B_Pagado, @I_OblRowID;
		END

		COMMIT TRANSACTION;
	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION;
		SET @B_Resultado = 0
		SET @T_Message = 'DESCRIPCION: ' + ERROR_MESSAGE() + CHAR(10) +  CHAR(13) +  
						 'LINEA: ' + CAST(ERROR_LINE() AS varchar(10)) 
	END CATCH

END
GO



IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_IU_MigrarPagoObligacionesCtasPorCobrar')
	DROP PROCEDURE [dbo].[USP_IU_MigrarPagoObligacionesCtasPorCobrar]
GO


CREATE PROCEDURE [dbo].[USP_IU_MigrarPagoObligacionesCtasPorCobrar]	
	@I_ProcedenciaID	tinyint,
	@I_ProcesoID		int = NULL,
	@I_Anio				int = NULL,
	@B_Resultado		bit output,
	@T_Message			nvarchar(4000) OUTPUT	
AS
--declare   @I_ProcedenciaID tinyint = 3,
--			@I_ProcesoID	 int = null, 
--			@I_Anio			 int = null, 
--			@B_Resultado	 bit, 
--			@T_Message nvarchar(4000)
--exec USP_IU_MigrarObligacionesCtasPorCobrar @I_ProcedenciaID, @I_ProcesoID, @I_Anio, @B_Resultado output, @T_Message output
--select @B_Resultado as resultado, @T_Message as mensaje
BEGIN

	DECLARE @D_FecProceso datetime = GETDATE()
	DECLARE @I_MigracionTablaOblID tinyint = 5
	DECLARE @I_MigracionTablaDetID tinyint = 4

	DECLARE @I_ObligacionAluID int = 0
	DECLARE @I_OblRowID int = 0
	DECLARE @B_Pagado bit = 0
	DECLARE @I_CondicionPagoID int = 131
	DECLARE @I_TipoPagoID int = 133
	DECLARE @T_Moneda varchar(3) = 'PEN'

	DECLARE @I_EntidadFinanID int, 
			@C_CodOperacion varchar(50), 
			@C_CodDepositante varchar(20), 
			@T_NomDepositante varchar(200), 
			@C_Referencia, 
			@D_FecPago, 
			@I_Cantidad, 
			@I_MontoPago, 
			@T_LugarPago, 
			@B_Anulado, 
			@T_Observacion,  
			@T_InformacionAdicional, 
			@I_CtaDepositoID, 
			@I_InteresMora, 
			@D_FecCre,
			@I_UsuarioMod, 
			@D_FecMod
			
	BEGIN TRANSACTION;
	BEGIN TRY 

		WITH obligaciones_migracion AS (
			SELECT * 
			  FROM TR_Ec_Obl
			 WHERE ISNUMERIC(ANO) = 1
				   AND I_ProcedenciaID = @I_ProcedenciaID
				   AND B_Migrable = 1
		),
		obligaciones_migracion_anio AS (
			SELECT * 
			FROM  obligaciones_migracion
			WHERE Ano = IIF(@I_Anio IS NULL, Ano, CAST(@I_Anio as varchar(4)))
		)


		SELECT obl.I_RowID, obl.Pagado, ctas_obl.I_ObligacionAluID, cdp.I_CtaDepositoID
		  INTO #obligaciones_pagos_migracion
		  FROM obligaciones_migracion_anio obl
			   INNER JOIN BD_OCEF_CtasPorCobrar.dbo.TI_CtaDepo_Proceso cdp ON obl.cuota_pago = cdp.I_ProcesoID
			   LEFT JOIN BD_OCEF_CtasPorCobrar.dbo.TR_ObligacionAluCab ctas_obl 
						 ON obl.I_RowID = ctas_obl.I_MigracionRowID

		SELECT det.I_OblRowID, det.I_RowID, Monto
		  INTO #temp_pagos_interes_mora
		  FROM TR_Ec_Det det
			   INNER JOIN #obligaciones_pagos_migracion obl ON det.I_OblRowID = obl.I_RowID
		WHERE Concepto = 4788 AND CAST(det.Ano AS int) = IIF(@I_Anio IS NULL, Ano, CAST(@I_Anio as varchar(4)))


		SELECT DISTINCT det.I_OblRowID, det.Pagado, det.Nro_recibo, det.Monto, det.Id_lug_pag, det.Cod_alu, det.Cod_cajero,
			   det.Fch_pago, alu.T_ApePaterno + SPACE(1) + alu.T_ApeMaterno + ',' + SPACE(1) + alu.T_Nombre as T_NombreAlumno,
			   CASE det.Cod_cajero WHEN 'BCP' THEN 2 ELSE 1 END AS I_EntidadFinanID, det.Cantidad, det.Eliminado, det.Fch_venc,
			   det.I_RowID, ctas_det.I_ObligacionAluDetID, ctas_det.I_ObligacionAluID, obl.I_CtaDepositoID, concepto,
			   CAST(det.Documento as varchar(max)) AS Documento
		  INTO #detalle_pagos_migracion
		  FROM TR_Ec_Det det
			   INNER JOIN #obligaciones_pagos_migracion obl ON det.I_OblRowID = obl.I_RowID
			   INNER JOIN TR_Alumnos alu ON alu.C_CodAlu = det.Cod_alu AND alu.C_RcCod = det.Cod_rc
			    LEFT JOIN BD_OCEF_CtasPorCobrar.dbo.TR_ObligacionAluDet ctas_det ON ctas_det.I_MigracionRowID = det.I_RowID
				LEFT JOIN #temp_pagos_interes_mora mora ON mora.I_OblRowID = det.I_OblRowID
		 WHERE det.B_Migrable = 1


		SELECT I_ObligacionAluDetID, I_ObligacionAluID, Pagado, Monto, I_RowID, I_OblRowID
		  INTO #pagos_interes_mora 
		  FROM #detalle_pagos_migracion 
		 WHERE Concepto = 4788

		DECLARE cursor_pago_obligaciones CURSOR
			FOR SELECT I_RowID, I_ObligacionAluID, Pagado 
				  FROM #obligaciones_pagos_migracion;

		OPEN cursor_pago_obligaciones;

		FETCH NEXT FROM cursor_pago_obligaciones INTO
						@I_ObligacionAluID, @B_Pagado, @I_OblRowID;


		WHILE @@FETCH_STATUS = 0
		BEGIN
			UPDATE BD_OCEF_CtasPorCobrar.dbo.TR_ObligacionAluCab
				   SET B_Pagado = @B_Pagado,
					   C_Moneda = 'PEN'
				 WHERE I_ObligacionAluID = @I_ObligacionAluID;


			UPDATE ctas_det
			   SET B_Pagado = @B_Pagado
			  FROM BD_OCEF_CtasPorCobrar.dbo.TR_ObligacionAluDet ctas_det
				   INNER JOIN #detalle_pagos_migracion det ON det.I_ObligacionAluID = ctas_det.I_ObligacionAluID
															  AND det.I_ObligacionAluDetID = ctas_det.I_ObligacionAluDetID
			 WHERE ctas_det.I_ObligacionAluID = @I_ObligacionAluID

			DECLARE cursor_pago_detalle CURSOR
				FOR SELECT det.I_EntidadFinanID, det.Nro_recibo, det.Cod_alu, det.T_NombreAlumno, det.Nro_recibo, det.Fch_pago, det.Cantidad, 
						   det.Id_lug_pag, det.Eliminado, det.I_CtaDepositoID, ISNULL(mora.Monto, 0) as I_InteresMora, det.Fch_venc, 
						   det.Monto, det.I_RowID, IIF(ISDATE(CAST(det.Fch_ec as varchar)) = 0, NULL,det.Fch_ec)  
					FROM   #detalle_pagos_migracion det 
						   LEFT JOIN #temp_pagos_interes_mora mora ON det.I_OblRowID = mora.I_OblRowID
					WHERE  det.I_ObligacionAluID = @I_OblRowID
					
			OPEN cursor_pago_detalle;

			FETCH NEXT FROM cursor_pago_detalle INTO
							;


			INSERT INTO BD_OCEF_CtasPorCobrar.dbo.TR_PagoBanco (I_EntidadFinanID, C_CodOperacion, C_CodDepositante, T_NomDepositante, C_Referencia, 
																D_FecPago, I_Cantidad, C_Moneda, I_MontoPago, T_LugarPago, B_Anulado, T_Observacion,  
																T_InformacionAdicional, I_CondicionPagoID, I_TipoPagoID, I_CtaDepositoID, I_InteresMora, 
																I_UsuarioCre, D_FecCre,I_UsuarioMod, D_FecMod, C_CodigoInterno, I_ProcesoIDArchivo, 
																T_ProcesoDescArchivo, D_FecVenctoArchivo, B_Migrado, I_MigracionTablaID, I_MigracionRowID)

														SELECT  det.I_EntidadFinanID, det.Nro_recibo, det.Cod_alu, det.T_NombreAlumno, det.Nro_recibo, 
																det.Fch_pago, det.Cantidad, @T_Moneda, det.Monto, det.Id_lug_pag, det.Eliminado, NULL,
																NULL, @I_CondicionPagoID, @I_TipoPagoID, det.I_CtaDepositoID, ISNULL(mora.Monto, 0),
																NULL, IIF(ISDATE(CAST(det.Fch_ec as varchar)) = 0, NULL,det.Fch_ec), NULL, NULL, NULL, NULL,
																NULL, det.Fch_venc, 1, @I_MigracionTablaDetID, det.I_RowID
														  FROM  #detalle_pagos_migracion det 
																LEFT JOIN #temp_pagos_interes_mora mora ON det.I_OblRowID = mora.I_OblRowID
														 WHERE  det.I_ObligacionAluID = @I_OblRowID

			INSERT INTO 

			FETCH NEXT FROM cursor_obligaciones INTO
							@Cuota_pago, @I_MatAluID, @I_Monto, @D_FecVencto, @B_Pagado, @I_OblRowID;
		END

		COMMIT TRANSACTION;
	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION;
		SET @B_Resultado = 0
		SET @T_Message = 'DESCRIPCION: ' + ERROR_MESSAGE() + CHAR(10) +  CHAR(13) +  
						 'LINEA: ' + CAST(ERROR_LINE() AS varchar(10)) 
	END CATCH

END
GO