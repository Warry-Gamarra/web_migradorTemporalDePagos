select * from TR_Ec_Obl where I_RowID = 117895
select * from TR_Ec_Det where I_OblRowID = 117895
select * from TR_Ec_Det_Pagos where I_OblRowID = 117895


select * from TR_Ec_Obl where I_RowID = 117918
select * from TR_Ec_Det where I_OblRowID = 117918
select * from TR_Ec_Det_Pagos where I_OblRowID = 117918



select * from TR_Cp_Pri where Id_cp = 4788

select * from TR_Cp_Des where Cuota_pago = 147
select * from BD_OCEF_CtasPorCobrar..TC_CuentaDeposito where C_NumeroCuenta = '110-01-0414438'
select * from BD_OCEF_CtasPorCobrar..TC_Proceso where I_ProcesoID = 147
select * from BD_OCEF_CtasPorCobrar..TI_CtaDepo_Proceso 
where I_ProcesoID = 147
order by I_ProcesoID


select DISTINCT c.T_ObservDesc from TI_ObservacionRegistroTabla o
inner join TC_CatalogoObservacion c on o.I_ObservID = c.I_ObservID
where o.I_TablaID = 7 

select * from TI_ObservacionRegistroTabla where I_TablaID = 7 and I_FilaTablaID = 108275






SELECT CD.I_CtaDepositoID, TP_CD.* 
FROM TR_Cp_Des TP_CD
		INNER JOIN BD_OCEF_CtasPorCobrar.dbo.TC_CuentaDeposito CD ON CD.C_NumeroCuenta COLLATE DATABASE_DEFAULT = TP_CD.N_CTA_CTE COLLATE DATABASE_DEFAULT
WHERE B_Migrable = 1 
		AND (I_Anio BETWEEN 1900 AND 3000) 
		AND (null IS NULL)
		AND I_ProcedenciaID = 2

SELECT I_RowID FROM TR_Ec_Det_Pagos WHERE I_OblRowID = 117123

declare @p5 bit
set @p5=NULL
declare @p6 nvarchar(4000)
set @p6=NULL
exec USP_Obligaciones_CuotaPago_MigracionTP_CtasPorCobrar_IU_MigrarData @I_ProcesoID=NULL,@I_AnioIni=NULL,@I_AnioFin=NULL,@I_ProcedenciaID=3,@B_Resultado=@p5 output,@T_Message=@p6 output
select @p5, @p6

DECLARE @D_FecProceso datetime = GETDATE(),
		@I_ProcesoID int = NULL,
		@I_AnioIni int = NULL,
		@I_AnioFin int = NULL,
		@I_ProcedenciaID int = 2

		SET @I_AnioIni = (SELECT ISNULL(@I_AnioIni, 0))
		SET @I_AnioFin = (SELECT ISNULL(@I_AnioFin, 3000))

DECLARE @Tbl_outputCtas AS TABLE (T_Action varchar(20), I_RowID int)

MERGE INTO BD_OCEF_CtasPorCobrar.dbo.TI_CtaDepo_Proceso AS TRG
USING (SELECT CD.I_CtaDepositoID, TP_CD.* FROM TR_Cp_Des TP_CD
				INNER JOIN BD_OCEF_CtasPorCobrar.dbo.TC_CuentaDeposito CD ON CD.C_NumeroCuenta COLLATE DATABASE_DEFAULT = TP_CD.N_CTA_CTE COLLATE DATABASE_DEFAULT
		WHERE B_Migrable = 1 
				AND (I_Anio BETWEEN @I_AnioIni AND @I_AnioFin) 
				AND (CUOTA_PAGO = @I_ProcesoID OR @I_ProcesoID IS NULL)
				AND I_ProcedenciaID = @I_ProcedenciaID
		) AS SRC
ON TRG.I_ProcesoID = SRC.CUOTA_PAGO AND TRG.I_CtaDepositoID = SRC.I_CtaDepositoID
WHEN NOT MATCHED BY TARGET THEN
	INSERT (I_CtaDepositoID, I_ProcesoID, B_Habilitado, B_Eliminado, D_FecCre)
	VALUES (I_CtaDepositoID, CUOTA_PAGO, 1, ELIMINADO, @D_FecProceso)
WHEN MATCHED AND TRG.I_UsuarioCre IS NULL AND TRG.I_UsuarioMod IS NULL THEN
	UPDATE SET	B_Eliminado = ELIMINADO,
				D_FecMod = @D_FecProceso
OUTPUT $action, SRC.I_RowID INTO @Tbl_outputCtas;
select * from @Tbl_outputCtas


select * from TR_Ec_Det_Pagos where B_Migrable = 0 and Ano = 2005