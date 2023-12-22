USE BD_OCEF_MigracionTP
GO


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_U_ValidarCuotaPagoRepetidaDiferentesProcedencias')
BEGIN
	DROP PROCEDURE [dbo].[USP_U_ValidarCuotaPagoRepetidaDiferentesProcedencias]
END
GO

CREATE PROCEDURE USP_U_ValidarCuotaPagoRepetidaDiferentesProcedencias
	@I_ProcedenciaID tinyint,
	@B_Resultado  bit output,
	@T_Message	  nvarchar(4000) OUTPUT	
AS
--declare @B_Resultado  bit,
--		@I_ProcedenciaID tinyint = 3,
--		@T_Message	  nvarchar(4000)
--exec USP_U_ValidarCuotaPagoRepetidaDiferentesProcedencias @I_ProcedenciaID, @B_Resultado output, @T_Message output
--select @B_Resultado as resultado, @T_Message as mensaje
BEGIN	
	DECLARE @D_FecProceso datetime = GETDATE() 
	DECLARE @I_ObservID int = 50
	DECLARE @I_TablaID int = 2 
	DECLARE @I_Observados int = 0

	BEGIN TRY 
		UPDATE	TR_Cp_Des
		SET		B_Migrable = 0,
				B_Migrado = 0,
				D_FecEvalua = @D_FecProceso
		WHERE	Cuota_pago IN (SELECT DISTINCT reps.Cuota_pago 
								 FROM (SELECT Cuota_pago FROM TR_Cp_Des 
									   GROUP BY Cuota_pago HAVING COUNT(Cuota_pago) > 1) AS reps
									  INNER JOIN (SELECT Cuota_pago, I_ProcedenciaID FROM TR_Cp_Des
												  GROUP BY Cuota_pago, I_ProcedenciaID HAVING COUNT(Cuota_pago) = 1) noRepsProc 
												 ON reps.Cuota_pago = noRepsProc.Cuota_pago
							  )
				AND ISNULL(B_Correcto, 0) = 0

		MERGE TI_ObservacionRegistroTabla AS TRG
		USING (SELECT @I_ObservID AS I_ObservID, @I_TablaID AS I_TablaID, I_RowID AS I_FilaTablaID, @D_FecProceso AS D_FecRegistro 
				 FROM TR_Cp_Des 
				WHERE Cuota_pago IN (SELECT DISTINCT reps.Cuota_pago 
									   FROM (SELECT Cuota_pago FROM TR_Cp_Des 
										     GROUP BY Cuota_pago HAVING COUNT(Cuota_pago) > 1) AS reps
										    INNER JOIN (SELECT Cuota_pago, I_ProcedenciaID FROM TR_Cp_Des
													    GROUP BY Cuota_pago, I_ProcedenciaID HAVING COUNT(Cuota_pago) = 1) noRepsProc 
													   ON reps.Cuota_pago = noRepsProc.Cuota_pago
									)
					  AND ISNULL(B_Correcto, 0) = 0
			  ) AS SRC
		ON TRG.I_ObservID = SRC.I_ObservID AND TRG.I_TablaID = SRC.I_TablaID AND TRG.I_FilaTablaID = SRC.I_FilaTablaID
		WHEN MATCHED THEN
			UPDATE SET D_FecRegistro = SRC.D_FecRegistro, 
					   B_Resuelto = 0
		WHEN NOT MATCHED BY TARGET THEN
			INSERT (I_ObservID, I_TablaID, I_FilaTablaID, D_FecRegistro, I_ProcedenciaID)
			VALUES (SRC.I_ObservID, SRC.I_TablaID, SRC.I_FilaTablaID, SRC.D_FecRegistro, @I_ProcedenciaID)
		WHEN NOT MATCHED BY SOURCE AND TRG.I_ObservID = @I_ObservID AND TRG.I_ProcedenciaID = @I_ProcedenciaID THEN
			UPDATE SET D_FecResuelto = GETDATE(),
					   B_Resuelto = 1;

		SET @I_Observados = (SELECT COUNT(*) FROM TI_ObservacionRegistroTabla WHERE I_ObservID = @I_ObservID AND I_TablaID = @I_TablaID AND I_ProcedenciaID = @I_ProcedenciaID AND B_Resuelto = 0)

		SET @B_Resultado = 1
		SET @T_Message = CAST(@I_Observados AS varchar) + ' encontrados'
	END TRY
	BEGIN CATCH
		SET @B_Resultado = 0
		SET @T_Message = ERROR_MESSAGE() + ' LINE: ' + CAST(ERROR_LINE() AS varchar(10)) 
	END CATCH
END
GO





select * from TR_Ec_Obl where I_ProcedenciaID = 1 order by ano, Cod_alu, Cod_rc, p, Cuota_pago, Fch_venc--, Monto

select ano, Cod_alu, Cod_rc, p, Cuota_pago, Fch_venc, count(*) from TR_Ec_Obl 
where I_ProcedenciaID = 3 
group by ano, Cod_alu, Cod_rc, p, Cuota_pago, Fch_venc
having count(*) > 1

select ano, Cod_alu, Cod_rc, p, Cuota_pago, Fch_venc, count(*) from TR_Ec_Obl 
where I_ProcedenciaID = 3
group by ano, Cod_alu, Cod_rc, p, Cuota_pago, Fch_venc
having count(*) = 2

select ano, Cod_alu, Cod_rc, p, Cuota_pago, Fch_venc, count(*) from TR_Ec_Obl 
where I_ProcedenciaID = 3 
group by ano, Cod_alu, Cod_rc, p, Cuota_pago, Fch_venc
having count(*) = 3

select ano, Cod_alu, Cod_rc, p, Cuota_pago, Fch_venc, count(*) from TR_Ec_Obl 
where I_ProcedenciaID = 3 
group by ano, Cod_alu, Cod_rc, p, Cuota_pago, Fch_venc
having count(*) = 4

select ano, Cod_alu, Cod_rc, p, Cuota_pago, Fch_venc, count(*) from TR_Ec_Obl 
where I_ProcedenciaID = 3
group by ano, Cod_alu, Cod_rc, p, Cuota_pago, Fch_venc
having count(*) = 5

select ano, Cod_alu, Cod_rc, p, Cuota_pago, Fch_venc, count(*) from TR_Ec_Obl 
where I_ProcedenciaID = 3
group by ano, Cod_alu, Cod_rc, p, Cuota_pago, Fch_venc
having count(*) = 7

select ano, Cod_alu, Cod_rc, p, Cuota_pago, Fch_venc, count(*) from TR_Ec_Obl 
where I_ProcedenciaID = 3 
group by ano, Cod_alu, Cod_rc, p, Cuota_pago, Fch_venc
having count(*) = 6


select * from BD_OCEF_TemporalPagos.euded.ec_obl 
where ano = '2011' and Cod_alu = '2008703916' and Cod_rc = 'E01' and
p = '0'  and Cuota_pago = 418
order by ano, Cod_alu, Cod_rc, p, Cuota_pago, Fch_venc--, Monto


select eliminado, * from BD_OCEF_TemporalPagos.euded.ec_det 
where ano = '2011' and Cod_alu = '2008703916' and Cod_rc = 'E01' and
p = '0'  and Cuota_pago = 418
order by ano, Cod_alu, Cod_rc, p, Cuota_pago, Fch_venc--, Monto

select * from BD_OCEF_TemporalPagos.euded.ec_obl  
where ano = '2018' and Cod_alu = '2014710778' and Cod_rc = 'E01' and
p = '2' and Cuota_pago = 454
order by ano, Cod_alu, Cod_rc, p, Cuota_pago, Fch_venc--, Monto

select eliminado as elim, * from BD_OCEF_TemporalPagos.euded.ec_det  
where ano = '2018' and Cod_alu = '2014710778' and Cod_rc = 'E01' and
p = '2' and Cuota_pago = 454
order by ano, Cod_alu, Cod_rc, p, Cuota_pago, Fch_venc, eliminado

select * from TR_Cp_Des where Cuota_pago = 330
select * from BD_OCEF_CtasPorCobrar..TC_Proceso where I_ProcesoID = 330
select * from BD_OCEF_CtasPorCobrar..TC_Proceso where I_Anio = 2016

select * from BD_OCEF_TemporalPagos.pregrado.ec_obl where cuota_pago = 330
select * from BD_OCEF_TemporalPagos.euded.ec_obl where cuota_pago = 330

select ano, Cod_alu, Cod_rc, p, Cuota_pago, Fch_venc, count(*) from BD_OCEF_TemporalPagos.euded.ec_obl   
group by ano, Cod_alu, Cod_rc, p, Cuota_pago, Fch_venc
having count(*) > 1




delete TI_ObservacionRegistroTabla where I_TablaID in (4, 5)
delete TR_Ec_Det
delete TR_Ec_Obl