GO
DECLARE @I_ProcedenciaID	tinyint = 1,
        @T_SchemaDB   varchar(20) = 'pregrado',
        @T_Anio		  varchar(4) = '2011',
        @B_Resultado  bit,
        @T_Message	  nvarchar(4000)

EXEC USP_Obligaciones_ObligacionCab_TemporalPagos_MigracionTP_IU_CopiarTabla @I_ProcedenciaID, @T_SchemaDB, @T_Anio, @B_Resultado output, @T_Message output
	SELECT @B_Resultado as resultado, @T_Message as mensaje

GO
DECLARE @I_ProcedenciaID	tinyint = 1,
        @T_SchemaDB   varchar(20) = 'pregrado',
        @T_Anio		  varchar(4) = '2011',
        @B_Resultado  bit,
        @T_Message	  nvarchar(4000)
EXEC USP_Obligaciones_ObligacionDet_TemporalPagos_MigracionTP_IU_CopiarTabla @I_ProcedenciaID, @T_SchemaDB, @T_Anio, @B_Resultado output, @T_Message output
	SELECT @B_Resultado as resultado, @T_Message as mensaje
GO

DECLARE @I_ProcedenciaID	tinyint = 1,
        @T_SchemaDB   varchar(20) = 'pregrado',
        @T_Anio		  varchar(4) = '2011',
        @B_Resultado  bit,
        @T_Message	  nvarchar(4000)
EXEC USP_Obligaciones_Pagos_TemporalPagos_MigracionTP_IU_CopiarTabla @I_ProcedenciaID, @T_SchemaDB, @T_Anio, @B_Resultado output, @T_Message output
	SELECT @B_Resultado as resultado, @T_Message as mensaje
GO

DECLARE @I_ProcedenciaID	tinyint = 1,
        @T_SchemaDB   varchar(20) = 'pregrado',
        @T_Anio		  varchar(4) = '2011',
        @B_Resultado  bit,
        @T_Message	  nvarchar(4000)
EXEC USP_Obligaciones_ObligacionDet_MigracionTP_U_AsignarObligacionCabID @I_ProcedenciaID, @T_Anio, @B_Resultado output, @T_Message output
	SELECT @B_Resultado as resultado, @T_Message as mensaje
GO

DECLARE @I_ProcedenciaID	tinyint = 1,
        @T_SchemaDB   varchar(20) = 'pregrado',
        @T_Anio		  varchar(4) = '2011',
        @B_Resultado  bit,
        @T_Message	  nvarchar(4000)
EXEC USP_Obligaciones_Pagos_MigracionTP_U_AsignarObligacionID @I_ProcedenciaID, @T_Anio, @B_Resultado output, @T_Message output
	SELECT @B_Resultado as resultado, @T_Message as mensaje



GO

DECLARE @I_ProcedenciaID	tinyint = 1,
        @T_SchemaDB   varchar(20) = 'pregrado',
        @T_Anio		  varchar(4) = '2011',
        @B_Resultado  bit,
        @T_Message	  nvarchar(4000)
EXEC USP_Obligaciones_ObligacionCab_MigracionTP_U_InicializarEstadoValidacion @I_ProcedenciaID, @T_Anio, @B_Resultado output, @T_Message output
	SELECT @B_Resultado as resultado, @T_Message as mensaje
GO

DECLARE @I_ProcedenciaID	tinyint = 1,
        @T_SchemaDB   varchar(20) = 'pregrado',
        @T_Anio		  varchar(4) = '2011',
        @B_Resultado  bit,
        @T_Message	  nvarchar(4000)
EXEC USP_Obligaciones_ObligacionDet_MigracionTP_U_InicializarEstadoValidacion @I_ProcedenciaID, @T_Anio, @B_Resultado output, @T_Message output
	SELECT @B_Resultado as resultado, @T_Message as mensaje
GO

DECLARE @I_ProcedenciaID	tinyint = 1,
        @T_SchemaDB   varchar(20) = 'pregrado',
        @T_Anio		  varchar(4) = '2011',
        @B_Resultado  bit,
        @T_Message	  nvarchar(4000)
EXEC USP_Obligaciones_Pagos_MigracionTP_U_InicializarEstadoValidacion @I_ProcedenciaID, @T_Anio, @B_Resultado output, @T_Message output
	SELECT @B_Resultado as resultado, @T_Message as mensaje

GO

DECLARE @I_ProcedenciaID	tinyint = 1,
        @T_SchemaDB   varchar(20) = 'pregrado',
        @T_Anio		  varchar(4) = '2011',
        @B_Resultado  bit,
        @T_Message	  nvarchar(4000)
EXEC USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_24_ExisteAlumno @I_ProcedenciaID, @T_Anio, @B_Resultado output, @T_Message output
	SELECT @B_Resultado as resultado, @T_Message as mensaje
GO

DECLARE @I_ProcedenciaID	tinyint = 1,
        @T_SchemaDB   varchar(20) = 'pregrado',
        @T_Anio		  varchar(4) = '2011',
        @B_Resultado  bit,
        @T_Message	  nvarchar(4000)
EXEC USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_26_AnioNumerico @I_ProcedenciaID, @B_Resultado output, @T_Message output
	SELECT @B_Resultado as resultado, @T_Message as mensaje
GO

DECLARE @I_ProcedenciaID	tinyint = 1,
        @T_SchemaDB   varchar(20) = 'pregrado',
        @T_Anio		  varchar(4) = '2011',
        @B_Resultado  bit,
        @T_Message	  nvarchar(4000)
EXEC USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_27_Periodo @I_ProcedenciaID, @T_Anio, @B_Resultado output, @T_Message output
	SELECT @B_Resultado as resultado, @T_Message as mensaje
GO

DECLARE @I_ProcedenciaID	tinyint = 1,
        @T_SchemaDB   varchar(20) = 'pregrado',
        @T_Anio		  varchar(4) = '2011',
        @B_Resultado  bit,
        @T_Message	  nvarchar(4000)
EXEC USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_28_FechaVencimientoCuota @I_ProcedenciaID, @T_Anio, @B_Resultado output, @T_Message output
	SELECT @B_Resultado as resultado, @T_Message as mensaje
GO

DECLARE @I_ProcedenciaID	tinyint = 1,
        @T_SchemaDB   varchar(20) = 'pregrado',
        @T_Anio		  varchar(4) = '2011',
        @B_Resultado  bit,
        @T_Message	  nvarchar(4000)
EXEC USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_32_ObligacionCuotaPagoMigrada @I_ProcedenciaID, @T_Anio, @B_Resultado output, @T_Message output
	SELECT @B_Resultado as resultado, @T_Message as mensaje
GO

DECLARE @I_ProcedenciaID	tinyint = 1,
        @T_SchemaDB   varchar(20) = 'pregrado',
        @T_Anio		  varchar(4) = '2011',
        @B_Resultado  bit,
        @T_Message	  nvarchar(4000)
EXEC USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_34_ProcedenciaCuotaPago @I_ProcedenciaID, @T_Anio, @B_Resultado output, @T_Message output
	SELECT @B_Resultado as resultado, @T_Message as mensaje
GO

DECLARE @I_ProcedenciaID	tinyint = 1,
        @T_SchemaDB   varchar(20) = 'pregrado',
        @T_Anio		  varchar(4) = '2011',
        @B_Resultado  bit,
        @T_Message	  nvarchar(4000)
EXEC USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_40_ObligacionSinDetalle @I_ProcedenciaID, @T_Anio, @B_Resultado output, @T_Message output
	SELECT @B_Resultado as resultado, @T_Message as mensaje
GO

DECLARE @I_ProcedenciaID	tinyint = 1,
        @T_SchemaDB   varchar(20) = 'pregrado',
        @T_Anio		  varchar(4) = '2011',
        @B_Resultado  bit,
        @T_Message	  nvarchar(4000)
EXEC USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_59_ObligacionRepetida @I_ProcedenciaID, @T_Anio, @B_Resultado output, @T_Message output
	SELECT @B_Resultado as resultado, @T_Message as mensaje
GO

DECLARE @I_ProcedenciaID	tinyint = 1,
        @T_SchemaDB   varchar(20) = 'pregrado',
        @T_Anio		  varchar(4) = '2011',
        @B_Resultado  bit,
        @T_Message	  nvarchar(4000)
EXEC USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_36_ConceptoPagoMigrado @I_ProcedenciaID, @T_Anio, @B_Resultado output, @T_Message output
	SELECT @B_Resultado as resultado, @T_Message as mensaje
GO

DECLARE @I_ProcedenciaID	tinyint = 1,
        @T_SchemaDB   varchar(20) = 'pregrado',
        @T_Anio		  varchar(4) = '2011',
        @B_Resultado  bit,
        @T_Message	  nvarchar(4000)
EXEC USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_54_PagoEnObligacionNoPagado @I_ProcedenciaID, @T_Anio, @B_Resultado output, @T_Message output
	SELECT @B_Resultado as resultado, @T_Message as mensaje
GO

DECLARE @I_ProcedenciaID	tinyint = 1,
        @T_SchemaDB   varchar(20) = 'pregrado',
        @T_Anio		  varchar(4) = '2011',
        @B_Resultado  bit,
        @T_Message	  nvarchar(4000)
EXEC USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_60_SinPagoEnObligacioPagada @I_ProcedenciaID, @T_Anio, @B_Resultado output, @T_Message output
	SELECT @B_Resultado as resultado, @T_Message as mensaje
GO

DECLARE @I_ProcedenciaID	tinyint = 1,
        @T_SchemaDB   varchar(20) = 'pregrado',
        @T_Anio		  varchar(4) = '2011',
        @B_Resultado  bit,
        @T_Message	  nvarchar(4000)
EXEC USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_29_ExisteEnDestino @I_ProcedenciaID, @T_Anio, @B_Resultado output, @T_Message output
	SELECT @B_Resultado as resultado, @T_Message as mensaje
GO

DECLARE @I_ProcedenciaID	tinyint = 1,
        @T_SchemaDB   varchar(20) = 'pregrado',
        @T_Anio		  varchar(4) = '2011',
        @B_Resultado  bit,
        @T_Message	  nvarchar(4000)
EXEC USP_Obligaciones_ObligacionDet_MigracionTP_U_Validar_58_SinObligacionCabID @I_ProcedenciaID, @T_Anio, @B_Resultado output, @T_Message output
	SELECT @B_Resultado as resultado, @T_Message as mensaje
GO

DECLARE @I_ProcedenciaID	tinyint = 1,
        @T_SchemaDB   varchar(20) = 'pregrado',
        @T_Anio		  varchar(4) = '2011',
        @B_Resultado  bit,
        @T_Message	  nvarchar(4000)
EXEC USP_Obligaciones_ObligacionDet_MigracionTP_U_Validar_35_ConceptoPago @I_ProcedenciaID, @T_Anio, @B_Resultado output, @T_Message output
	SELECT @B_Resultado as resultado, @T_Message as mensaje
GO

DECLARE @I_ProcedenciaID	tinyint = 1,
        @T_SchemaDB   varchar(20) = 'pregrado',
        @T_Anio		  varchar(4) = '2011',
        @B_Resultado  bit,
        @T_Message	  nvarchar(4000)
EXEC USP_Obligaciones_ObligacionDet_MigracionTP_U_Validar_43_AnioDetalleNumerico @I_ProcedenciaID, @B_Resultado output, @T_Message output
	SELECT @B_Resultado as resultado, @T_Message as mensaje
GO

DECLARE @I_ProcedenciaID	tinyint = 1,
        @T_SchemaDB   varchar(20) = 'pregrado',
        @T_Anio		  varchar(4) = '2011',
        @B_Resultado  bit,
        @T_Message	  nvarchar(4000)
EXEC USP_Obligaciones_ObligacionDet_MigracionTP_U_Validar_33_ConceptoPagoMigrado @I_ProcedenciaID, @T_Anio, @B_Resultado output, @T_Message output
	SELECT @B_Resultado as resultado, @T_Message as mensaje
GO

DECLARE @I_ProcedenciaID	tinyint = 1,
        @T_SchemaDB   varchar(20) = 'pregrado',
        @T_Anio		  varchar(4) = '2011',
        @B_Resultado  bit,
        @T_Message	  nvarchar(4000)
EXEC USP_Obligaciones_ObligacionDet_MigracionTP_U_Validar_15_AnioDetalleAnioConcepto @I_ProcedenciaID, @T_Anio, @B_Resultado output, @T_Message output
	SELECT @B_Resultado as resultado, @T_Message as mensaje
GO

DECLARE @I_ProcedenciaID	tinyint = 1,
        @T_SchemaDB   varchar(20) = 'pregrado',
        @T_Anio		  varchar(4) = '2011',
        @B_Resultado  bit,
        @T_Message	  nvarchar(4000)
EXEC USP_Obligaciones_ObligacionDet_MigracionTP_U_Validar_17_PeriodoDetallePeriodoConcepto @I_ProcedenciaID, @T_Anio, @B_Resultado output, @T_Message output
	SELECT @B_Resultado as resultado, @T_Message as mensaje
GO

DECLARE @I_ProcedenciaID	tinyint = 1,
        @T_SchemaDB   varchar(20) = 'pregrado',
        @T_Anio		  varchar(4) = '2011',
        @B_Resultado  bit,
        @T_Message	  nvarchar(4000)
EXEC USP_Obligaciones_ObligacionDet_MigracionTP_U_Validar_44_PeriodoDetalleEquivPeriodoCtas @I_ProcedenciaID, @T_Anio, @B_Resultado output, @T_Message output
	SELECT @B_Resultado as resultado, @T_Message as mensaje
GO

DECLARE @I_ProcedenciaID	tinyint = 1,
        @T_SchemaDB   varchar(20) = 'pregrado',
        @T_Anio		  varchar(4) = '2011',
        @B_Resultado  bit,
        @T_Message	  nvarchar(4000)
EXEC USP_Obligaciones_ObligacionDet_MigracionTP_U_Validar_42_CuotaDetalleCuotaConcepto @I_ProcedenciaID, @T_Anio, @B_Resultado output, @T_Message output
	SELECT @B_Resultado as resultado, @T_Message as mensaje
GO

DECLARE @I_ProcedenciaID	tinyint = 1,
        @T_SchemaDB   varchar(20) = 'pregrado',
        @T_Anio		  varchar(4) = '2011',
        @B_Resultado  bit,
        @T_Message	  nvarchar(4000)
EXEC USP_Obligaciones_ObligacionDet_MigracionTP_U_Validar_49_MontoDetalleMontoCab @I_ProcedenciaID, @T_Anio, @B_Resultado output, @T_Message output
	SELECT @B_Resultado as resultado, @T_Message as mensaje
GO

DECLARE @I_ProcedenciaID	tinyint = 1,
        @T_SchemaDB   varchar(20) = 'pregrado',
        @T_Anio		  varchar(4) = '2011',
        @B_Resultado  bit,
        @T_Message	  nvarchar(4000)
EXEC USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_39_DetalleObservado @I_ProcedenciaID, @T_Anio, @B_Resultado output, @T_Message output
	SELECT @B_Resultado as resultado, @T_Message as mensaje
GO

DECLARE @I_ProcedenciaID	tinyint = 1,
        @T_SchemaDB   varchar(20) = 'pregrado',
        @T_Anio		  varchar(4) = '2011',
        @B_Resultado  bit,
        @T_Message	  nvarchar(4000)
EXEC USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_37_ObservacionAnioDetalle @I_ProcedenciaID, @T_Anio, @B_Resultado output, @T_Message output
	SELECT @B_Resultado as resultado, @T_Message as mensaje
GO

DECLARE @I_ProcedenciaID	tinyint = 1,
        @T_SchemaDB   varchar(20) = 'pregrado',
        @T_Anio		  varchar(4) = '2011',
        @B_Resultado  bit,
        @T_Message	  nvarchar(4000)
EXEC USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_38_ObservacionPeriodoDetalle @I_ProcedenciaID, @T_Anio, @B_Resultado output, @T_Message output
	SELECT @B_Resultado as resultado, @T_Message as mensaje
GO

DECLARE @I_ProcedenciaID	tinyint = 1,
        @T_SchemaDB   varchar(20) = 'pregrado',
        @T_Anio		  varchar(4) = '2011',
        @B_Resultado  bit,
        @T_Message	  nvarchar(4000)
EXEC USP_Obligaciones_ObligacionDet_MigracionTP_U_Validar_25_ObligacionCabID @I_ProcedenciaID, @T_Anio, @B_Resultado output, @T_Message output
	SELECT @B_Resultado as resultado, @T_Message as mensaje
GO

DECLARE @I_ProcedenciaID	tinyint = 1,
        @T_SchemaDB   varchar(20) = 'pregrado',
        @T_Anio		  varchar(4) = '2011',
        @B_Resultado  bit,
        @T_Message	  nvarchar(4000)
EXEC USP_Obligaciones_Pagos_MigracionTP_U_Validar_57_CabObligacionObservada @I_ProcedenciaID, @T_Anio, @B_Resultado output, @T_Message output
	SELECT @B_Resultado as resultado, @T_Message as mensaje
GO

DECLARE @I_ProcedenciaID	tinyint = 1,
        @T_SchemaDB   varchar(20) = 'pregrado',
        @T_Anio		  varchar(4) = '2011',
        @B_Resultado  bit,
        @T_Message	  nvarchar(4000)
EXEC USP_Obligaciones_Pagos_MigracionTP_U_Validar_56_DetalleObservado @I_ProcedenciaID, @T_Anio, @B_Resultado output, @T_Message output
	SELECT @B_Resultado as resultado, @T_Message as mensaje
GO

DECLARE @I_ProcedenciaID	tinyint = 1,
        @T_SchemaDB   varchar(20) = 'pregrado',
        @T_Anio		  varchar(4) = '2011',
        @B_Resultado  bit,
        @T_Message	  nvarchar(4000)
EXEC USP_Obligaciones_Pagos_MigracionTP_U_Validar_52_SinObligacionID @I_ProcedenciaID, @T_Anio, @B_Resultado output, @T_Message output
	SELECT @B_Resultado as resultado, @T_Message as mensaje

GO

DECLARE @I_ProcedenciaID	tinyint = 1,
        @T_SchemaDB   varchar(20) = 'pregrado',
        @T_Anio		  varchar(4) = '2011',
        @B_Resultado  bit,
        @T_Message	  nvarchar(4000)
        EXEC USP_Obligaciones_Pagos_MigracionTP_U_Validar_53_MontoPagadoDetalle @I_ProcedenciaID, @T_Anio, @B_Resultado output, @T_Message output
	SELECT @B_Resultado as resultado, @T_Message as mensaje
GO

DECLARE @I_ProcedenciaID	tinyint = 1,
        @T_SchemaDB   varchar(20) = 'pregrado',
        @T_Anio		  varchar(4) = '2011',
        @B_Resultado  bit,
        @T_Message	  nvarchar(4000)
EXEC USP_Obligaciones_Pagos_MigracionTP_U_Validar_55_ExisteEnDestinoConOtroBanco @I_ProcedenciaID, @T_Anio, @B_Resultado output, @T_Message output
	SELECT @B_Resultado as resultado, @T_Message as mensaje


--PROCESO DE MIGRAGION--
GO

DECLARE @I_ProcedenciaID	tinyint = 1,
        @T_SchemaDB   varchar(20) = 'pregrado',
        @T_Anio		  varchar(4) = '2011',
        @B_Resultado  bit,
        @T_Message	  nvarchar(4000)
EXEC USP_Obligaciones_MigracionTP_CtasPorCobrar_IU_MigrarDataPorAnio @I_ProcedenciaID, @T_Anio, @B_Resultado output, @T_Message output
	SELECT @B_Resultado as resultado, @T_Message as mensaje
GO

DECLARE @I_ProcedenciaID	tinyint = 1,
        @T_SchemaDB   varchar(20) = 'pregrado',
        @T_Anio		  varchar(4) = '2011',
        @B_Resultado  bit,
        @T_Message	  nvarchar(4000)
EXEC USP_Obligaciones_Pagos_MigracionTP_CtasPorCobrar_IU_MigrarDataPorAnio @I_ProcedenciaID, @T_Anio, @B_Resultado output, @T_Message output
	SELECT @B_Resultado as resultado, @T_Message as mensaje
GO

DECLARE @I_ProcedenciaID	tinyint = 1,
        @T_SchemaDB   varchar(20) = 'pregrado',
        @T_Anio		  varchar(4) = '2011',
        @B_Resultado  bit,
        @T_Message	  nvarchar(4000)
EXEC USP_Obligaciones_ObligacionCab_MigracionTP_U_Validar_61_MigracionMatricula @I_ProcedenciaID, @T_Anio, @B_Resultado output, @T_Message output
	SELECT @B_Resultado as resultado, @T_Message as mensaje
GO

DECLARE @I_ProcedenciaID	tinyint = 1,
        @T_SchemaDB   varchar(20) = 'pregrado',
        @T_Anio		  varchar(4) = '2011',
        @B_Resultado  bit,
        @T_Message	  nvarchar(4000)
EXEC USP_Obligaciones_ObligacionDet_MigracionTP_U_Validar_62_MigracionCabecera @I_ProcedenciaID, @T_Anio, @B_Resultado output, @T_Message output
	SELECT @B_Resultado as resultado, @T_Message as mensaje
GO

DECLARE @I_ProcedenciaID	tinyint = 1,
        @T_SchemaDB   varchar(20) = 'pregrado',
        @T_Anio		  varchar(4) = '2011',
        @B_Resultado  bit,
        @T_Message	  nvarchar(4000)
EXEC USP_Obligaciones_Pagos_MigracionTP_U_Validar_63_MigracionCabecera @I_ProcedenciaID, @T_Anio, @B_Resultado output, @T_Message output
	SELECT @B_Resultado as resultado, @T_Message as mensaje


