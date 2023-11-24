USE BD_OCEF_MigracionTP
GO

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_CtasPorCobrar_I_GrabarMatriculaPorAlumno')
	DROP PROCEDURE [dbo].[USP_CtasPorCobrar_I_GrabarMatriculaPorAlumno]
GO

CREATE PROCEDURE [dbo].[USP_CtasPorCobrar_I_GrabarMatriculaPorAlumno]	
(
	@I_RowID			int,
	@D_FecProceso		datetime,
	@I_MatAluID			int OUTPUT
)
AS
BEGIN
	INSERT INTO BD_OCEF_CtasPorCobrar.dbo.TC_MatriculaAlumno(C_CodRc, C_CodAlu, I_Anio, I_Periodo, C_EstMat, C_Ciclo, B_Ingresante, 
															 I_CredDesaprob, B_Habilitado, B_Eliminado, B_Migrado, D_FecCre)
								                     SELECT	SRC.Cod_rc, SRC.Cod_alu, CAST(SRC.Ano as int), SRC.I_Periodo, 'S' as ciclo, NULL as ingresante, 
															NULL as ingresante, NULL as cred_desaprob, 1 as habilitado, 0 as eliminado, 1 as migrado, @D_FecProceso
													   FROM TR_Ec_Obl SRC 
													  WHERE I_RowID = @I_RowID	

	SET @I_MatAluID = SCOPE_IDENTITY()
END
GO


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_CtasPorCobrar_U_GrabarMatriculaPorAlumno')
	DROP PROCEDURE [dbo].[USP_CtasPorCobrar_U_GrabarMatriculaPorAlumno]
GO

CREATE PROCEDURE [dbo].[USP_CtasPorCobrar_U_GrabarMatriculaPorAlumno]	
(
	@I_RowID			int,
	@I_MatAluID			int,
	@D_FecProceso		datetime
)
AS
BEGIN
	UPDATE BD_OCEF_CtasPorCobrar.dbo.TC_MatriculaAlumno
	   SET C_CodRc = SRC.Cod_rc, 
		   C_CodAlu = SRC.Cod_alu, 
		   I_Anio = CAST(SRC.Ano as int), 
		   I_Periodo = SRC.I_Periodo, 
		   D_FecMod = @D_FecProceso
	  FROM (SELECT * FROM TR_Ec_Obl WHERE I_RowID = @I_RowID) SRC
     WHERE I_MatAluID = @I_MatAluID
END
GO


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_IU_MigrarObligacionesCtasPorCobrarPorAlumno')
	DROP PROCEDURE [dbo].[USP_IU_MigrarObligacionesCtasPorCobrarPorAlumno]
GO

CREATE PROCEDURE [dbo].[USP_IU_MigrarObligacionesCtasPorCobrarPorAlumno]	
(
	@I_RowID			int = NULL,
	@B_Resultado		bit OUTPUT,
	@T_Message			nvarchar(4000) OUTPUT	
)
AS
--declare   @I_RowID	 int, 
--			@B_Resultado  bit, 
--			@T_Message nvarchar(4000)
--exec USP_IU_MigrarObligacionesCtasPorCobrar @I_ProcedenciaID, @I_ProcesoID, @I_AnioIni, @I_AnioFin, @B_Resultado output, @T_Message output
--select @B_Resultado as resultado, @T_Message as mensaje
BEGIN
	DECLARE @I_Obl_Removidos int = 0
	DECLARE @I_Obl_Actualizados int = 0
	DECLARE @I_Obl_Insertados int = 0
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
		DECLARE @Cod_alu			varchar(20)
		DECLARE @Cod_Rc				varchar(5)
		DECLARE @I_Periodo			int
		DECLARE @I_Anio				int
		
		DECLARE @I_MatAluID  int 
		--DECLARE @I_ObligacionAluID  int 
		--DECLARE @I_ObligacionAluID  int 

		SELECT @Cod_alu = Cod_alu, @I_Periodo = I_Periodo, @I_Anio = CAST(Ano as int)
		  FROM TR_Ec_Obl
		 WHERE I_RowID = @I_RowID

		SELECT @I_MatAluID = I_MatAluID
		  FROM BD_OCEF_CtasPorCobrar.dbo.TC_MatriculaAlumno
		 WHERE C_CodAlu = @Cod_alu AND C_CodRc = @Cod_Rc 
			   AND I_Periodo = @I_Periodo AND I_Anio = @I_Anio
			   AND B_Eliminado = 0
		 		
		
		SELECT @I_ObligacionAluID = I_ObligacionAluID
		  FROM BD_OCEF_CtasPorCobrar.dbo.TR_ObligacionAluCab
		 WHERE I_MigracionRowID = @I_RowID AND I_MigracionTablaID = @I_MigracionTablaOblID


		IF(@I_ObligacionAluID IS NOT NULL)
		BEGIN
			IF(@I_MatAluID IS NULL)
			BEGIN
				EXECUTE USP_CtasPorCobrar_I_GrabarMatriculaPorAlumno @I_RowID, @D_FecProceso, @I_MatAluID
			END
			ELSE
			BEGIN
				EXECUTE USP_CtasPorCobrar_U_GrabarMatriculaPorAlumno @I_RowID, @I_MatAluID, @D_FecProceso
			END

			INSERT INTO BD_OCEF_CtasPorCobrar.dbo.TR_ObligacionAluCab (I_ProcesoID, I_MatAluID, C_Moneda, I_MontoOblig, D_FecVencto, B_Pagado, B_Habilitado, 
																	   B_Eliminado, I_UsuarioCre, D_FecCre, B_Migrado, I_MigracionTablaID, I_MigracionRowID)
																SELECT SRC.Cuota_pago, @I_MatAluID, @T_Moneda, SRC.Monto, SRC.Fch_venc, 0 as B_Pagado, 1 as B_Habilitado, 
																		0, NULL as I_UsuarioCre, @D_FecProceso, 1 as B_Migrado, @I_MigracionTablaOblID, SRC.I_RowID
																  FROM TR_Ec_Obl SRC
																 WHERE SRC.I_RowID =  @I_RowID
			SET @I_ObligacionAluID = SCOPE_IDENTITY();

			INSERT INTO BD_OCEF_CtasPorCobrar.dbo.TR_ObligacionAluDet (I_ObligacionAluID, I_ConcPagID, I_Monto, B_Pagado, D_FecVencto, I_TipoDocumento, 
																	   T_DescDocumento, B_Habilitado, B_Eliminado, I_UsuarioCre, D_FecCre, B_Mora, 
																	   B_Migrado, I_MigracionTablaID, I_MigracionRowID)
																SELECT @I_ObligacionAluID, SRC.Concepto, SRC.Monto, 0, SRC.Fch_venc, CASE WHEN CAST(Documento as varchar(max)) IS NULL THEN NULL ELSE 138 END AS I_TipoDocumento, 
																	   CAST(Documento as varchar(max)) AS T_DescDocumento, 1 as habilitado,  0 as eliminado,  NULL as I_UsuarioCre, @D_FecProceso, 0 AS Mora, 
																	   1 as migrado, @I_MigracionTablaDetID, I_RowID
																  FROM TR_Ec_Det SRC
																 WHERE SRC.I_OblRowID =  @I_RowID
		END
		ELSE
		BEGIN
			PRINT 'AQUI SE ACTUALIZA'
		END






		COMMIT TRANSACTION;
	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION;
		SET @B_Resultado = 0
		SET @T_Message = ERROR_MESSAGE() + ' LINE: ' + CAST(ERROR_LINE() AS varchar(10)) 
	END CATCH
END
GO