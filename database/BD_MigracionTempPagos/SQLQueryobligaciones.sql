

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_IU_MigrarObligacionesCtasPorCobrar')
	DROP PROCEDURE [dbo].[USP_IU_MigrarObligacionesCtasPorCobrar]
GO

CREATE PROCEDURE [dbo].[USP_IU_MigrarObligacionesCtasPorCobrar]
	@I_ProcesoID	int,
	@I_AnioIni		int,
	@B_Resultado	bit output,
	@T_Message		nvarchar(4000) OUTPUT	
AS
--declare @B_Resultado  bit, @I_ProcesoID int, @I_AnioIni int, @I_AnioFin int, @T_Message nvarchar(4000)
--exec USP_IU_MigrarObligacionesCtasPorCobrar @I_ProcesoID = null, @I_AnioIni = null, @I_AnioFin = null, @B_Resultado = @B_Resultado output, @T_Message = @T_Message output
--select @B_Resultado as resultado, @T_Message as mensaje
BEGIN
	DECLARE @D_FecProceso datetime = GETDATE() 
	DECLARE @Tbl_outputProceso AS TABLE (T_Action varchar(20), I_RowID int)
	DECLARE @Tbl_outputCtas AS TABLE (T_Action varchar(20), I_RowID int)
	DECLARE @Tbl_outputCtasCat AS TABLE (T_Action varchar(20), I_RowID int)
	DECLARE @I_Proc_Inserted int = 0
	DECLARE @I_Proc_Updated int = 0
	DECLARE @I_Ctas_Inserted int = 0
	DECLARE @I_Ctas_Updated int = 0
	DECLARE @I_CtaCat_Inserted int = 0
	DECLARE @I_CtaCat_Updated int = 0
	DECLARE @I_ObservID int = 29
	DECLARE @I_TablaID int = 5

	BEGIN TRANSACTION;
	BEGIN TRY 
		DECLARE @I_Anio int
		SET @I_Anio = (SELECT I_Anio FROM TR_Cp_Des WHERE Cuota_pago = @I_ProcesoID)

		MERGE INTO  BD_OCEF_CtasPorCobrar.dbo.TC_MatriculaAlumno AS TRG
		USING (SELECT DISTINCT Ano, I_periodo, Cod_alu, Cod_rc FROM TR_Ec_Obl obl
				WHERE B_Migrable = 1 AND ANO = @I_Anio AND CUOTA_PAGO = @I_ProcesoID
			  ) AS SRC
		ON TRG.C_CodRc = SRC.Cod_rc AND TRG.C_CodAlu = SRC.Cod_alu
			AND TRG.I_Anio = SRC.Ano AND TRG.I_Periodo = SRC.I_periodo
		WHEN NOT MATCHED BY TARGET THEN 
			INSERT (C_CodRc, C_CodAlu, I_Anio, I_Periodo, C_EstMat, C_Ciclo, B_Ingresante, I_CredDesaprob, B_Habilitado, B_Eliminado, B_Migrado)
			VALUES (COD_RC, COD_ALU, ANO, I_periodo, 'S', NULL, NULL, 0, 1, 0, 1);


		DECLARE @I_CuotaPago	int
				,@I_MatAluID	int
				,@I_MontoOblig	decimal(10,2)
				,@D_FecVencto	datetime
				,@B_Pagado		bit
				,@B_Migrado		bit
				,@I_RowID		int

		DECLARE CUR_EcObl CURSOR 
		FOR 
			SELECT OBL.CUOTA_PAGO, MAT.I_MatAluID, OBL.MONTO, OBL.FCH_VENC, OBL.PAGADO, I_RowID 
			FROM TR_Ec_Obl OBL
				INNER JOIN BD_OCEF_CtasPorCobrar.dbo.TC_MatriculaAlumno MAT
					ON MAT.C_CodRc = OBL.COD_RC AND MAT.C_CodAlu = OBL.COD_ALU
						AND MAT.I_Anio = OBL.ANO AND MAT.I_Periodo = OBL.I_periodo
				WHERE OBL.B_Migrable = 1 AND OBL.CUOTA_PAGO = @I_ProcesoID

		OPEN CUR_EcObl
		FETCH NEXT FROM CUR_EcObl INTO @I_CuotaPago, @I_MatAluID, @I_MontoOblig, @D_FecVencto, @B_Pagado, @I_RowID

		WHILE @@FETCH_STATUS = 0
		BEGIN
			DECLARE  @I_ObligacionAluID int = NULL

			SET @I_ObligacionAluID = (SELECT I_ObligacionAluID FROM BD_OCEF_CtasPorCobrar.dbo.TR_ObligacionAluCab 
										WHERE I_ProcesoID = @I_CuotaPago AND I_MatAluID = @I_MatAluID AND D_FecVencto = @D_FecVencto)

			IF ((SELECT I_MontoOblig FROM BD_OCEF_CtasPorCobrar.dbo.TR_ObligacionAluCab WHERE I_ObligacionAluID = @I_ObligacionAluID) <> @I_MontoOblig)
			BEGIN
				IF (@I_ObligacionAluID IS NULL)
				BEGIN
					SET @B_Migrado = 1
					INSERT INTO BD_OCEF_CtasPorCobrar.dbo.TR_ObligacionAluCab 
					(I_ProcesoID, I_MatAluID, C_Moneda, I_MontoOblig, D_FecVencto, B_Pagado, B_Habilitado, B_Eliminado, B_Migrado, I_UsuarioCre, D_FecCre, I_UsuarioMod, D_FecMod)
					VALUES (@I_CuotaPago, @I_MatAluID, 'PEN', @I_MontoOblig, @D_FecVencto, @B_Pagado, 1, 0, @B_Migrado, NULL, @D_FecProceso, NULL, NULL)
				END
				ELSE
				BEGIN
					SET @B_Migrado = 0
					UPDATE TR_Ec_Obl 
					SET B_Migrado = @B_Migrado
					WHERE I_RowID = @I_RowID

					INSERT TI_ObservacionRegistroTabla (I_ObservID, I_TablaID, I_FilaTablaID, D_FecRegistro)
					VALUES (@I_ObservID, @I_TablaID, @I_RowID, @D_FecProceso)
				END
			END
			ELSE
			BEGIN
				SET @B_Migrado = 1
				UPDATE TR_Ec_Obl 
				SET B_Migrado = @B_Migrado
				WHERE I_RowID = @I_RowID

				INSERT TI_ObservacionRegistroTabla (I_ObservID, I_TablaID, I_FilaTablaID, D_FecRegistro)
				VALUES (@I_ObservID, @I_TablaID, @I_RowID, @D_FecProceso)

			END

			FETCH NEXT FROM CUR_EcObl INTO @I_CuotaPago, @I_MatAluID, @I_MontoOblig, @D_FecVencto, @B_Pagado
		END 
		
		CLOSE CUR_EcObl
		DEALLOCATE CUR_EcObl

		MERGE INTO BD_OCEF_CtasPorCobrar.dbo.TR_ObligacionAluDet AS TRG
		USING (SELECT ECD.*, OBL.I_periodo, OAC.I_ObligacionAluID  FROM TR_Ec_Det ECD
					INNER JOIN TR_Ec_Obl OBL ON ECD.CUOTA_PAGO = OBL.CUOTA_PAGO AND ECD.COD_RC = OBL.COD_RC AND ECD.P = OBL.P
												AND ECD.COD_ALU = OBL.COD_ALU AND ECD.FCH_VENC= OBL.FCH_VENC AND OBL.B_Migrado = 1  
					INNER JOIN BD_OCEF_CtasPorCobrar.dbo.TC_MatriculaAlumno MAT ON MAT.C_CodRc = OBL.COD_RC AND MAT.C_CodAlu = OBL.COD_ALU
																			  AND MAT.I_Anio = OBL.ANO AND MAT.I_Periodo = OBL.I_periodo
					INNER JOIN BD_OCEF_CtasPorCobrar.dbo.TR_ObligacionAluCab OAC ON OAC.I_ProcesoID = OBL.CUOTA_PAGO AND OAC.I_MatAluID = MAT.I_MatAluID 
																			  AND OAC.D_FecVencto= OBL.FCH_VENC
				WHERE OBL.CUOTA_PAGO = @I_ProcesoID
			  ) AS SRC
		ON TRG. = SRC. AND TRG. = SRC.
		WHEN NOT MATCHED BY TARGET THEN
			INSERT (I_ObligacionAluID, I_ConcPagID, I_Monto, B_Pagado, D_FecVencto, B_Habilitado, B_Eliminado, I_UsuarioCre, D_FecCre, B_Mora)
			VALUES (@D_FecProceso)
		WHEN MATCHED AND TRG.I_UsuarioCre IS NULL AND TRG.I_UsuarioMod IS NULL THEN
			UPDATE SET	D_FecMod = @D_FecProceso
		OUTPUT $action, SRC.I_CatPagoID INTO @Tbl_outputCtasCat;
		

		UPDATE	TR_Cp_Des 
		SET		B_Migrado = 0 
		WHERE	I_RowID IN (SELECT CD.I_RowID FROM TR_Cp_Des CD LEFT JOIN @Tbl_outputProceso O ON CD.I_RowID = o.I_RowID 
							WHERE CD.B_Migrable = 1 AND O.I_RowID IS NULL)

		MERGE TI_ObservacionRegistroTabla AS TRG
		USING 	(SELECT	@I_ObservID AS I_ObservID, @I_TablaID AS I_TablaID, I_RowID AS I_FilaTablaID, @D_FecProceso AS D_FecRegistro FROM TR_Cp_Des
				  WHERE	I_RowID IN (SELECT CD.I_RowID FROM TR_Cp_Des CD LEFT JOIN @Tbl_outputProceso O ON CD.I_RowID = o.I_RowID 
									WHERE CD.B_Migrable = 1 AND O.I_RowID IS NULL)
				) AS SRC
		ON TRG.I_ObservID = SRC.I_ObservID AND TRG.I_TablaID = SRC.I_TablaID AND TRG.I_FilaTablaID = SRC.I_FilaTablaID
		WHEN MATCHED THEN
			UPDATE SET D_FecRegistro = SRC.D_FecRegistro
		WHEN NOT MATCHED BY TARGET THEN
			INSERT (I_ObservID, I_TablaID, I_FilaTablaID, D_FecRegistro)
			VALUES (SRC.I_ObservID, SRC.I_TablaID, SRC.I_FilaTablaID, SRC.D_FecRegistro)
		WHEN NOT MATCHED BY SOURCE AND TRG.I_ObservID = @I_ObservID THEN
			DELETE;

		SET @I_Proc_Inserted = (SELECT COUNT(*) FROM @Tbl_outputProceso WHERE T_Action = 'INSERT')
		SET @I_Proc_Updated = (SELECT COUNT(*) FROM @Tbl_outputProceso WHERE T_Action = 'UPDATE')
		SET @I_Ctas_Inserted = (SELECT COUNT(*) FROM @Tbl_outputCtas WHERE T_Action = 'INSERT')
		SET @I_Ctas_Updated = (SELECT COUNT(*) FROM @Tbl_outputCtas WHERE T_Action = 'UPDATE')
		SET @I_CtaCat_Inserted = (SELECT COUNT(*) FROM @Tbl_outputCtasCat WHERE T_Action = 'INSERT')
		SET @I_CtaCat_Updated = (SELECT COUNT(*) FROM @Tbl_outputCtasCat WHERE T_Action = 'UPDATE')

		SELECT @I_Proc_Inserted AS proc_count_insert, @I_Proc_Updated AS proc_count_update, 
			   @I_Ctas_Inserted AS ctas_count_insert, @I_Ctas_Updated AS ctas_count_update,
			   @I_CtaCat_Inserted AS ctas_cat_count_insert, @I_CtaCat_Updated AS ctas_cat_count_update

		COMMIT TRANSACTION;

		SET @B_Resultado = 1
		SET @T_Message = CAST(@I_Proc_Inserted AS varchar) + ' | ' + CAST(@I_Proc_Updated AS varchar)
						 + ' | ' + CAST(@I_Ctas_Inserted AS varchar) + ' | ' + CAST(@I_Ctas_Updated AS varchar)
						 + ' | ' + CAST(@I_CtaCat_Inserted AS varchar) + ' | ' + CAST(@I_CtaCat_Updated AS varchar)
	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION;
		SET @B_Resultado = 0
		SET @T_Message = ERROR_MESSAGE() + ' LINE: ' + CAST(ERROR_LINE() AS varchar(10)) 
	END CATCH
END
GO




IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_IU_MigrarDataPagosObligacionesCtasPorCobrar')
	DROP PROCEDURE [dbo].[USP_IU_MigrarDataPagosObligacionesCtasPorCobrar]
GO

CREATE PROCEDURE [dbo].[USP_IU_MigrarDataPagosObligacionesCtasPorCobrar]
	@I_ProcesoID	int,
	@B_Resultado	bit output,
	@T_Message		nvarchar(4000) OUTPUT	
AS
--declare @B_Resultado  bit, @I_ProcesoID int, @I_AnioIni int, @I_AnioFin int, @T_Message nvarchar(4000)
--exec USP_IU_MigrarDataPagosObligacionesCtasPorCobrar @I_ProcesoID = null, @I_AnioIni = null, @I_AnioFin = null, @B_Resultado = @B_Resultado output, @T_Message = @T_Message output
--select @B_Resultado as resultado, @T_Message as mensaje
BEGIN
	DECLARE @D_FecProceso datetime = GETDATE() 
	DECLARE @Tbl_outputProceso AS TABLE (T_Action varchar(20), I_RowID int)
	DECLARE @Tbl_outputCtas AS TABLE (T_Action varchar(20), I_RowID int)
	DECLARE @Tbl_outputCtasCat AS TABLE (T_Action varchar(20), I_RowID int)
	DECLARE @I_Proc_Inserted int = 0
	DECLARE @I_Proc_Updated int = 0
	DECLARE @I_Ctas_Inserted int = 0
	DECLARE @I_Ctas_Updated int = 0
	DECLARE @I_CtaCat_Inserted int = 0
	DECLARE @I_CtaCat_Updated int = 0
	DECLARE @I_ObservID int = 29
	DECLARE @I_TablaID int = 5

	BEGIN TRANSACTION;
	BEGIN TRY 
		DECLARE @I_Anio int
		SET @I_Anio = (SELECT I_Anio FROM TR_Cp_Des WHERE CUOTA_PAGO = @I_ProcesoID)

		MERGE INTO  BD_OCEF_CtasPorCobrar.dbo.TC_MatriculaAlumno AS TRG
		USING (SELECT DISTINCT ANO, I_periodo, COD_ALU, COD_RC FROM TR_Ec_Obl obl
				WHERE B_Migrable = 1 AND ANO = @I_Anio AND CUOTA_PAGO = @I_ProcesoID
			  ) AS SRC
		ON TRG.C_CodRc = SRC.COD_RC AND TRG.C_CodAlu = SRC.COD_ALU
			AND TRG.I_Anio = SRC.ANO AND TRG.I_Periodo = SRC.I_periodo
		WHEN NOT MATCHED BY TARGET THEN 
			INSERT (C_CodRc, C_CodAlu, I_Anio, I_Periodo, C_EstMat, C_Ciclo, B_Ingresante, I_CredDesaprob, B_Habilitado, B_Eliminado, B_Migrado)
			VALUES (COD_RC, COD_ALU, ANO, I_periodo, 'S', NULL, NULL, 0, 1, 0, 1);


		DECLARE @I_CuotaPago	int
				,@I_MatAluID	int
				,@I_MontoOblig	decimal(10,2)
				,@D_FecVencto	datetime
				,@B_Pagado		bit
				,@B_Migrado		bit
				,@I_RowID		int

		DECLARE CUR_EcObl CURSOR 
		FOR 
			SELECT OBL.CUOTA_PAGO, MAT.I_MatAluID, OBL.MONTO, OBL.FCH_VENC, OBL.PAGADO, I_RowID 
			FROM TR_Ec_Obl OBL
				INNER JOIN BD_OCEF_CtasPorCobrar.dbo.TC_MatriculaAlumno MAT
					ON MAT.C_CodRc = OBL.COD_RC AND MAT.C_CodAlu = OBL.COD_ALU
						AND MAT.I_Anio = OBL.ANO AND MAT.I_Periodo = OBL.I_periodo
				WHERE OBL.B_Migrable = 1 AND OBL.CUOTA_PAGO = @I_ProcesoID

		OPEN CUR_EcObl
		FETCH NEXT FROM CUR_EcObl INTO @I_CuotaPago, @I_MatAluID, @I_MontoOblig, @D_FecVencto, @B_Pagado, @I_RowID

		WHILE @@FETCH_STATUS = 0
		BEGIN
			DECLARE  @I_ObligacionAluID int = NULL

			SET @I_ObligacionAluID = (SELECT I_ObligacionAluID FROM BD_OCEF_CtasPorCobrar.dbo.TR_ObligacionAluCab 
										WHERE I_ProcesoID = @I_CuotaPago AND I_MatAluID = @I_MatAluID AND D_FecVencto = @D_FecVencto)

			IF ((SELECT I_MontoOblig FROM BD_OCEF_CtasPorCobrar.dbo.TR_ObligacionAluCab WHERE I_ObligacionAluID = @I_ObligacionAluID) <> @I_MontoOblig)
			BEGIN
				IF (@I_ObligacionAluID IS NULL)
				BEGIN
					SET @B_Migrado = 1
					INSERT INTO BD_OCEF_CtasPorCobrar.dbo.TR_ObligacionAluCab 
					(I_ProcesoID, I_MatAluID, C_Moneda, I_MontoOblig, D_FecVencto, B_Pagado, B_Habilitado, B_Eliminado, B_Migrado, I_UsuarioCre, D_FecCre, I_UsuarioMod, D_FecMod)
					VALUES (@I_CuotaPago, @I_MatAluID, 'PEN', @I_MontoOblig, @D_FecVencto, @B_Pagado, 1, 0, @B_Migrado, NULL, @D_FecProceso, NULL, NULL)
				END
				ELSE
				BEGIN
					SET @B_Migrado = 0
					UPDATE TR_Ec_Obl 
					SET B_Migrado = @B_Migrado
					WHERE I_RowID = @I_RowID

					INSERT TI_ObservacionRegistroTabla (I_ObservID, I_TablaID, I_FilaTablaID, D_FecRegistro)
					VALUES (@I_ObservID, @I_TablaID, @I_RowID, @D_FecProceso)
				END
			END
			ELSE
			BEGIN
				SET @B_Migrado = 1
				UPDATE TR_Ec_Obl 
				SET B_Migrado = @B_Migrado
				WHERE I_RowID = @I_RowID

				INSERT TI_ObservacionRegistroTabla (I_ObservID, I_TablaID, I_FilaTablaID, D_FecRegistro)
				VALUES (@I_ObservID, @I_TablaID, @I_RowID, @D_FecProceso)

			END

			FETCH NEXT FROM CUR_EcObl INTO @I_CuotaPago, @I_MatAluID, @I_MontoOblig, @D_FecVencto, @B_Pagado
		END 
		
		CLOSE CUR_EcObl
		DEALLOCATE CUR_EcObl

		MERGE INTO BD_OCEF_CtasPorCobrar.dbo.TR_ObligacionAluDet AS TRG
		USING (SELECT ECD.*, OBL.I_periodo, OAC.I_ObligacionAluID  FROM TR_Ec_Det ECD
					INNER JOIN TR_Ec_Obl OBL ON ECD.CUOTA_PAGO = OBL.CUOTA_PAGO AND ECD.COD_RC = OBL.COD_RC AND ECD.P = OBL.P
												AND ECD.COD_ALU = OBL.COD_ALU AND ECD.FCH_VENC= OBL.FCH_VENC AND OBL.B_Migrado = 1  
					INNER JOIN BD_OCEF_CtasPorCobrar.dbo.TC_MatriculaAlumno MAT ON MAT.C_CodRc = OBL.COD_RC AND MAT.C_CodAlu = OBL.COD_ALU
																			  AND MAT.I_Anio = OBL.ANO AND MAT.I_Periodo = OBL.I_periodo
					INNER JOIN BD_OCEF_CtasPorCobrar.dbo.TR_ObligacionAluCab OAC ON OAC.I_ProcesoID = OBL.CUOTA_PAGO AND OAC.I_MatAluID = MAT.I_MatAluID 
																			  AND OAC.D_FecVencto= OBL.FCH_VENC
				WHERE OBL.CUOTA_PAGO = @I_ProcesoID
			  ) AS SRC
		ON TRG. = SRC. AND TRG. = SRC.
		WHEN NOT MATCHED BY TARGET THEN
			INSERT (I_ObligacionAluID, I_ConcPagID, I_Monto, B_Pagado, D_FecVencto, B_Habilitado, B_Eliminado, I_UsuarioCre, D_FecCre, B_Mora)
			VALUES (@D_FecProceso)
		WHEN MATCHED AND TRG.I_UsuarioCre IS NULL AND TRG.I_UsuarioMod IS NULL THEN
			UPDATE SET	D_FecMod = @D_FecProceso
		OUTPUT $action, SRC.I_CatPagoID INTO @Tbl_outputCtasCat;
		

		UPDATE	TR_Cp_Des 
		SET		B_Migrado = 0 
		WHERE	I_RowID IN (SELECT CD.I_RowID FROM TR_Cp_Des CD LEFT JOIN @Tbl_outputProceso O ON CD.I_RowID = o.I_RowID 
							WHERE CD.B_Migrable = 1 AND O.I_RowID IS NULL)

		MERGE TI_ObservacionRegistroTabla AS TRG
		USING 	(SELECT	@I_ObservID AS I_ObservID, @I_TablaID AS I_TablaID, I_RowID AS I_FilaTablaID, @D_FecProceso AS D_FecRegistro FROM TR_Cp_Des
				  WHERE	I_RowID IN (SELECT CD.I_RowID FROM TR_Cp_Des CD LEFT JOIN @Tbl_outputProceso O ON CD.I_RowID = o.I_RowID 
									WHERE CD.B_Migrable = 1 AND O.I_RowID IS NULL)
				) AS SRC
		ON TRG.I_ObservID = SRC.I_ObservID AND TRG.I_TablaID = SRC.I_TablaID AND TRG.I_FilaTablaID = SRC.I_FilaTablaID
		WHEN MATCHED THEN
			UPDATE SET D_FecRegistro = SRC.D_FecRegistro
		WHEN NOT MATCHED BY TARGET THEN
			INSERT (I_ObservID, I_TablaID, I_FilaTablaID, D_FecRegistro)
			VALUES (SRC.I_ObservID, SRC.I_TablaID, SRC.I_FilaTablaID, SRC.D_FecRegistro)
		WHEN NOT MATCHED BY SOURCE AND TRG.I_ObservID = @I_ObservID THEN
			DELETE;

		SET @I_Proc_Inserted = (SELECT COUNT(*) FROM @Tbl_outputProceso WHERE T_Action = 'INSERT')
		SET @I_Proc_Updated = (SELECT COUNT(*) FROM @Tbl_outputProceso WHERE T_Action = 'UPDATE')
		SET @I_Ctas_Inserted = (SELECT COUNT(*) FROM @Tbl_outputCtas WHERE T_Action = 'INSERT')
		SET @I_Ctas_Updated = (SELECT COUNT(*) FROM @Tbl_outputCtas WHERE T_Action = 'UPDATE')
		SET @I_CtaCat_Inserted = (SELECT COUNT(*) FROM @Tbl_outputCtasCat WHERE T_Action = 'INSERT')
		SET @I_CtaCat_Updated = (SELECT COUNT(*) FROM @Tbl_outputCtasCat WHERE T_Action = 'UPDATE')

		SELECT @I_Proc_Inserted AS proc_count_insert, @I_Proc_Updated AS proc_count_update, 
			   @I_Ctas_Inserted AS ctas_count_insert, @I_Ctas_Updated AS ctas_count_update,
			   @I_CtaCat_Inserted AS ctas_cat_count_insert, @I_CtaCat_Updated AS ctas_cat_count_update

		COMMIT TRANSACTION;

		SET @B_Resultado = 1
		SET @T_Message = CAST(@I_Proc_Inserted AS varchar) + ' | ' + CAST(@I_Proc_Updated AS varchar)
						 + ' | ' + CAST(@I_Ctas_Inserted AS varchar) + ' | ' + CAST(@I_Ctas_Updated AS varchar)
						 + ' | ' + CAST(@I_CtaCat_Inserted AS varchar) + ' | ' + CAST(@I_CtaCat_Updated AS varchar)
	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION;
		SET @B_Resultado = 0
		SET @T_Message = ERROR_MESSAGE() + ' LINE: ' + CAST(ERROR_LINE() AS varchar(10)) 
	END CATCH
END
GO




