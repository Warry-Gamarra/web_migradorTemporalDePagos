
USE BD_OCEF_MigracionTP
GO


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_CtasPorCobrar_I_GrabarMatriculaPorObligacionID')
BEGIN
	DROP PROCEDURE [dbo].[USP_CtasPorCobrar_I_GrabarMatriculaPorObligacionID]
END
GO

CREATE PROCEDURE [dbo].[USP_CtasPorCobrar_I_GrabarMatriculaPorObligacionID]	
(
	@I_RowID			int,
	@D_FecProceso		datetime,
	@I_TablaOblID	    int,
	@I_MatAluID			int OUTPUT
)
AS
BEGIN
	INSERT INTO BD_OCEF_CtasPorCobrar.dbo.TC_MatriculaAlumno(C_CodRc, C_CodAlu, I_Anio, I_Periodo, C_EstMat, C_Ciclo, B_Ingresante, I_CredDesaprob, 
															 B_Habilitado, B_Eliminado, B_Migrado, D_FecCre, I_MigracionTablaID, I_MigracionRowID)
								                     SELECT	SRC.Cod_rc, SRC.Cod_alu, CAST(SRC.Ano as int), SRC.I_Periodo, 'S' as matricula, NULL as ciclo, NULL as ingresante, NULL as cred_desaprob, 
															1 as habilitado, 0 as eliminado, 1 as migrado, @D_FecProceso, @I_TablaOblID, @I_RowID
													   FROM TR_Ec_Obl SRC 
													  WHERE I_RowID = @I_RowID	

	SET @I_MatAluID = SCOPE_IDENTITY()
END
GO


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_CtasPorCobrar_U_GrabarMatriculaPorObligacionID')
BEGIN
	DROP PROCEDURE [dbo].[USP_CtasPorCobrar_U_GrabarMatriculaPorObligacionID]
END
GO

CREATE PROCEDURE [dbo].[USP_CtasPorCobrar_U_GrabarMatriculaPorObligacionID]	
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
	  FROM (SELECT * FROM TR_Ec_Obl WHERE I_RowID = @I_RowID) SRC
     WHERE I_MatAluID = @I_MatAluID
END
GO


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_CtasPorCobrar_I_GrabarDetalleObligacionPorObligacionID')
BEGIN
	DROP PROCEDURE [dbo].[USP_CtasPorCobrar_I_GrabarDetalleObligacionPorObligacionID]
END
GO

CREATE PROCEDURE [dbo].[USP_CtasPorCobrar_I_GrabarDetalleObligacionPorObligacionID]	
(
	@I_OblRowID			int,
	@I_ObligacionAluID	int,
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
															   CAST(Documento as varchar(max)) AS T_DescDocumento, 1 as habilitado,  Eliminado as eliminado,  1 as I_UsuarioCre, @D_FecProceso, 0 AS Mora, 
															   1 as migrado, @I_TablaID, I_RowID
														  FROM TR_Ec_Det SRC
														 WHERE SRC.I_OblRowID =  @I_OblRowID
															   AND Concepto <> 0
															   AND Concepto_f = 0

	SET @I_Det_Insertados = @@ROWCOUNT
END
GO


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_IU_MigrarObligacionesCtasPorCobrarPorObligacionID')
BEGIN
	DROP PROCEDURE [dbo].[USP_IU_MigrarObligacionesCtasPorCobrarPorObligacionID]
END
GO

CREATE PROCEDURE [dbo].[USP_IU_MigrarObligacionesCtasPorCobrarPorObligacionID]	
(
	@I_RowID		int ,
	@I_OblAluID		int OUTPUT,
	@B_Resultado	bit OUTPUT,
	@T_Message		nvarchar(4000) OUTPUT	
)
AS
--declare   @I_RowID	 int, 
--			@B_Resultado  bit, 
--			@T_Message nvarchar(4000)
--exec USP_IU_MigrarObligacionesCtasPorCobrarPorObligacionID @I_RowID, @I_OblAluID output, @B_Resultado output, @T_Message output
--select @B_Resultado as resultado, @T_Message as mensaje
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
		DECLARE @Cod_alu			varchar(20)
		DECLARE @Cod_Rc				varchar(5)
		DECLARE @I_Periodo			int
		DECLARE @I_Anio				int
		
		DECLARE @I_MatAluID  int 
		DECLARE @I_MatAluID_Obl  int 
		--DECLARE @I_ObligacionAluID  int 
		--DECLARE @I_ObligacionAluID  int 

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
		 WHERE I_MigracionRowID = @I_RowID AND I_MigracionTablaID = @I_MigracionTablaOblID

		SELECT @I_CountDetOblID = COUNT(*) FROM BD_OCEF_CtasPorCobrar.dbo.TR_ObligacionAluDet
		 WHERE I_ObligacionAluID = @I_ObligacionAluID 
			   AND I_MigracionTablaID = @I_MigracionTablaDetID

		IF(@I_ObligacionAluID IS NULL)
		BEGIN
			IF(@I_MatAluID IS NULL)
			BEGIN
				EXECUTE USP_CtasPorCobrar_I_GrabarMatriculaPorObligacionID @I_RowID, @D_FecProceso, @I_MigracionTablaOblID, @I_MatAluID
			END
			ELSE
			BEGIN
				EXECUTE USP_CtasPorCobrar_U_GrabarMatriculaPorObligacionID @I_RowID, @I_MatAluID, @I_MigracionTablaOblID, @D_FecProceso
			END

			INSERT INTO BD_OCEF_CtasPorCobrar.dbo.TR_ObligacionAluCab (I_ProcesoID, I_MatAluID, C_Moneda, I_MontoOblig, D_FecVencto, B_Pagado, B_Habilitado, 
																	   B_Eliminado, I_UsuarioCre, D_FecCre, B_Migrado, I_MigracionTablaID, I_MigracionRowID)
																SELECT SRC.Cuota_pago, @I_MatAluID, @T_Moneda, SRC.Monto, SRC.Fch_venc, 0 as B_Pagado, 1 as B_Habilitado, 
																	   0 as eliminado, 1 as I_UsuarioCre, @D_FecProceso, 1 as B_Migrado, @I_MigracionTablaOblID, SRC.I_RowID
																		  FROM TR_Ec_Obl SRC
																 WHERE SRC.I_RowID = @I_RowID

			SET @I_ObligacionAluID = SCOPE_IDENTITY();

			EXECUTE USP_CtasPorCobrar_I_GrabarDetalleObligacionPorObligacionID @I_RowID, @I_ObligacionAluID, @D_FecProceso, @I_MigracionTablaDetID, @I_Det_Insertados

		END
		ELSE
		BEGIN
			IF (ISNULL(@I_MatAluID, 1) <> ISNULL(@I_MatAluID_Obl, 1))
			BEGIN
				SET @B_Resultado = 0
				SET @T_Message = 'La matricula en el repositorio, no coincide con la del temporal de pagos.'

				GOTO END_TRANSACTION
			END
			
			IF(@I_MatAluID IS NULL)
			BEGIN
				EXECUTE USP_CtasPorCobrar_I_GrabarMatriculaPorObligacionID @I_RowID, @D_FecProceso, @I_MigracionTablaOblID, @I_MatAluID
			END
			ELSE
			BEGIN
				EXECUTE USP_CtasPorCobrar_U_GrabarMatriculaPorObligacionID @I_RowID, @I_MatAluID, @I_MigracionTablaOblID, @D_FecProceso
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

			IF (@I_CountDetOblID = 0)
			BEGIN
				EXECUTE USP_CtasPorCobrar_I_GrabarDetalleObligacionPorObligacionID @I_RowID, @I_ObligacionAluID, @D_FecProceso, @I_MigracionTablaDetID, @I_Det_Insertados
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
							  AND Concepto <> 0
							  AND Concepto_f = 0
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
							   TRG.I_UsuarioMod = 1, 
							   TRG.D_FecMod = @D_FecProceso
				WHEN NOT MATCHED THEN
					INSERT (I_ObligacionAluID, I_ConcPagID, I_Monto, B_Pagado, D_FecVencto, I_TipoDocumento, T_DescDocumento, B_Mora, 
							B_Habilitado, B_Eliminado, I_UsuarioCre, D_FecCre, B_Migrado, I_MigracionTablaID, I_MigracionRowID)
					VALUES (SRC.I_ObligacionAluID, SRC.Concepto, SRC.Monto, 0, SRC.Fch_venc, SRC.I_TipoDocumento, SRC.T_DescDocumento, SRC.Mora, 
							SRC.Habilitado, SRC.Eliminado, 1, @D_FecProceso, 1, @I_MigracionTablaDetID, SRC.I_DetMigracionRowID)
				OUTPUT $action, SRC.I_DetMigracionRowID INTO @Tbl_outputObl;

				SET @I_Det_Insertados = (SELECT COUNT(*) FROM @Tbl_outputObl WHERE T_Action = 'INSERT')
				SET @I_Det_Actualizados = (SELECT COUNT(*) FROM @Tbl_outputObl WHERE T_Action = 'UPDATE')

			END
		END
		
		UPDATE EC_OBL 
		   SET B_Migrado = 1,
		   	   D_FecMigrado = @D_FecProceso
		  FROM TR_Ec_Obl EC_OBL
		 	   INNER JOIN BD_OCEF_CtasPorCobrar.dbo.TR_ObligacionAluCab CTAS_CAB ON EC_OBL.I_RowID = CTAS_CAB.I_MigracionRowID
		 WHERE EC_OBL.I_RowID = @I_RowID
		 
		
		SET @B_Resultado = 1
		SET @T_Message = 'Detalle de obligaciones actualizadas:' + CAST(@I_Det_Actualizados AS varchar(10))  + ' | Detalle de obligaciones insertadas: ' + CAST(@I_Det_Insertados AS varchar(10))

		END_TRANSACTION:
			SET @I_OblAluID = ISNULL(@I_ObligacionAluID, 0)
			COMMIT TRANSACTION;
	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION;

		SET @I_OblAluID = ISNULL(@I_ObligacionAluID, 0)
		SET @B_Resultado = 0
		SET @T_Message = ERROR_MESSAGE() + ' LINE: ' + CAST(ERROR_LINE() AS varchar(10)) 
	END CATCH
END
GO


