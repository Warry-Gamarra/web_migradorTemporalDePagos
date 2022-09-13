declare @B_Resultado  bit,
		@I_ProcedenciaID	tinyint = 1,
		@T_SchemaDB			varchar(20) = 'pregrado',
		@T_Codigo_bnc		varchar(250) = '''0635'', ''0636'', ''0637'', ''0638'', ''0639''',
		@T_Message			nvarchar(4000)
exec USP_IU_CopiarTablaCuotaDePago @I_ProcedenciaID, @T_SchemaDB, @T_Codigo_bnc, @B_Resultado output, @T_Message output
select @B_Resultado as resultado, @T_Message as mensaje
GO

declare @B_Resultado  bit,
		@I_ProcedenciaID tinyint = 1,
		@T_Message	  nvarchar(4000)
exec USP_U_MarcarRepetidosCuotaDePago @I_ProcedenciaID, @B_Resultado output, @T_Message output
select @B_Resultado as resultado, @T_Message as mensaje
GO

declare @B_Resultado  bit,
		@I_ProcedenciaID tinyint = 1,
		@T_SchemaDB		 varchar(20) = 'pregrado',
		@T_Message	  nvarchar(4000)
exec USP_U_AsignarAnioPeriodoCuotaPago @I_ProcedenciaID, @T_SchemaDB, @B_Resultado output, @T_Message output
select @B_Resultado as resultado, @T_Message as mensaje
go


declare @B_Resultado  bit,
		@I_ProcedenciaID tinyint = 1,
		@T_Message	  nvarchar(4000)
exec USP_U_AsignarCategoriaCuotaPago  @I_ProcedenciaID, @B_Resultado output, @T_Message output
select @B_Resultado as resultado, @T_Message as mensaje
go

declare	@B_Resultado  bit, 
			@I_ProcesoID int = NULL,
			@I_AnioIni int = NULL, 
			@I_AnioFin int = NULL,
			@I_ProcedenciaID tinyint = 1,
			@T_Message nvarchar(4000)
exec USP_IU_MigrarDataCuotaDePagoCtasPorCobrar @I_ProcesoID, @I_AnioIni, @I_AnioFin, @I_ProcedenciaID, @B_Resultado output, @T_Message output
select @B_Resultado as resultado, @T_Message as mensaje
go



declare @B_Resultado  bit,
		@I_ProcedenciaID	tinyint = 1,
		@T_SchemaDB			varchar(20) = 'pregrado',
		@T_Codigo_bnc		varchar(250) = '''0635'', ''0636'', ''0637'', ''0638'', ''0639''',
		@T_Message	  nvarchar(4000)
exec USP_IU_CopiarTablaConceptoDePago @I_ProcedenciaID, @T_SchemaDB, @T_Codigo_bnc, @B_Resultado output, @T_Message output
select @B_Resultado as resultado, @T_Message as mensaje
go


declare @B_Resultado  bit,
		@I_ProcedenciaID tinyint = 1,
		@T_Message	  nvarchar(4000)
exec USP_U_MarcarConceptosPagoRepetidos @I_ProcedenciaID, @B_Resultado output, @T_Message output
select @B_Resultado as resultado, @T_Message as mensaje
go


declare @B_Resultado  bit,
		@I_ProcedenciaID tinyint = 1,
		@T_Message	  nvarchar(4000)
exec USP_U_MarcarConceptosPagoObligSinAnioAsignado @I_ProcedenciaID, @B_Resultado output, @T_Message output
select @B_Resultado as resultado, @T_Message as mensaje
go


declare @B_Resultado  bit,
		@I_ProcedenciaID tinyint = 1,
		@T_Message	  nvarchar(4000)
exec USP_U_MarcarConceptosPagoObligSinPeriodoAsignado @I_ProcedenciaID, @B_Resultado output, @T_Message output
select @B_Resultado as resultado, @T_Message as mensaje
go


declare @B_Resultado  bit,
		@I_ProcedenciaID tinyint = 1,
		@T_Message	  nvarchar(4000)
exec USP_U_MarcarConceptosPagoObligSinCuotaPago @I_ProcedenciaID, @B_Resultado output, @T_Message output
select @B_Resultado as resultado, @T_Message as mensaje
go


declare @B_Resultado  bit,
		@I_ProcedenciaID tinyint = 1,
		@T_Message	  nvarchar(4000)
exec USP_U_AsignarIdEquivalenciasConceptoPago @I_ProcedenciaID, @B_Resultado output, @T_Message output
select @B_Resultado as resultado, @T_Message as mensaje
go


declare @B_Resultado  bit,
		@T_Message	  nvarchar(4000)
exec USP_IU_GrabarTablaCatalogoConceptos @B_Resultado output, @T_Message output
select @B_Resultado as resultado, @T_Message as mensaje
go


declare	@B_Resultado  bit, 
			@I_ProcesoID int = NULL,
			@I_AnioIni int = NULL, 
			@I_AnioFin int = NULL,
			@I_ProcedenciaID tinyint = 1,
			@T_Message nvarchar(4000)
exec USP_IU_MigrarDataConceptoPagoObligacionesCtasPorCobrar @I_ProcesoID, @I_AnioIni, @I_AnioFin, @I_ProcedenciaID, @B_Resultado output, @T_Message output
select @B_Resultado as resultado, @T_Message as mensaje
go




declare @I_ProcedenciaID tinyint = 1,
		@T_SchemaDB   varchar(20) = 'pregrado',
		@T_AnioIni	  varchar(4) = null,
		@T_AnioFin	  varchar(4) = null,
		@B_Resultado  bit,
		@T_Message	  nvarchar(4000)
exec USP_IU_CopiarTablaObligacionesPago @I_ProcedenciaID, @T_SchemaDB, @T_AnioIni, @T_AnioFin, @B_Resultado output, @T_Message output
select @B_Resultado as resultado, @T_Message as mensaje
go


declare @I_ProcedenciaID tinyint = 1,
		@T_SchemaDB   varchar(20) = 'pregrado',
		@T_AnioIni	  varchar(4) = 2017,
		@T_AnioFin	  varchar(4) = 2022,
		@B_Resultado  bit,
		@T_Message	  nvarchar(4000)
exec USP_IU_CopiarTablaDetalleObligacionesPago @I_ProcedenciaID, @T_SchemaDB, @T_AnioIni, @T_AnioFin, @B_Resultado output, @T_Message output
select @B_Resultado as resultado, @T_Message as mensaje
go


declare	@B_Resultado  bit,
		@I_ProcedenciaID tinyint = 1,
		@T_AnioIni	  varchar(4) = NULL,
		@T_AnioFin	  varchar(4) = NULL,
		@T_Message	  nvarchar(4000)
exec USP_U_InicializarEstadoValidacionObligacionPago @I_ProcedenciaID, @T_AnioIni, @T_AnioFin, @B_Resultado output, @T_Message output
select @B_Resultado as resultado, @T_Message as mensaje
go


declare	@B_Resultado  bit,
		@I_ProcedenciaID	tinyint = 1,
		@T_AnioIni	  varchar(4) = NULL,
		@T_AnioFin	  varchar(4) = NULL,
		@T_Message	  nvarchar(4000)
exec USP_U_InicializarEstadoValidacionDetalleObligacionPago @I_ProcedenciaID, @T_AnioIni, @T_AnioFin, @B_Resultado output, @T_Message output
select @B_Resultado as resultado, @T_Message as mensaje
go


declare @I_ProcedenciaID tinyint = 1,
		@I_AnioIni	  int = null,
		@I_AnioFin	  int = null,
		@B_Resultado  bit,
		@T_Message	  nvarchar(4000)
exec USP_U_ValidarExisteAlumnoCabeceraObligacion @I_ProcedenciaID, @I_AnioIni, @I_AnioFin, @B_Resultado output, @T_Message output
select @B_Resultado as resultado, @T_Message as mensaje
go


declare @I_ProcedenciaID tinyint = 1, 
		@B_Resultado  bit,
		@T_Message	  nvarchar(4000)
exec USP_U_ValidarAnioEnCabeceraObligacion @I_ProcedenciaID, @B_Resultado output, @T_Message output
select @B_Resultado as resultado, @T_Message as mensaje
go


declare @I_ProcedenciaID tinyint = 1, 
		@B_Resultado  bit,
		@T_Message	  nvarchar(4000)
exec USP_U_ValidarAnioEnDetalleObligacion @I_ProcedenciaID, @B_Resultado output, @T_Message output
select @B_Resultado as resultado, @T_Message as mensaje
go


declare @I_ProcedenciaID tinyint = 1, 
		@B_Resultado  bit,
		@T_Message	  nvarchar(4000)
exec USP_U_ValidarPeriodoEnCabeceraObligacion @I_ProcedenciaID, @B_Resultado output, @T_Message output
select @B_Resultado as resultado, @T_Message as mensaje
go


declare @I_ProcedenciaID tinyint = 1, 
		@B_Resultado  bit,
		@T_Message	  nvarchar(4000)
exec USP_U_ValidarPeriodoEnDetalleObligacion @I_ProcedenciaID, @B_Resultado output, @T_Message output
select @B_Resultado as resultado, @T_Message as mensaje
go


declare @I_ProcedenciaID tinyint = 1, 
		  @B_Resultado  bit,
		  @T_Message    nvarchar(4000)
exec USP_U_ValidarFechaVencimientoCuotaObligacion @I_ProcedenciaID, @B_Resultado output, @T_Message output
select @B_Resultado as resultado, @T_Message as mensaje
go


declare @I_ProcedenciaID tinyint = 1, 
		  @B_Resultado  bit,
		  @T_Message    nvarchar(4000)
exec USP_U_ValidarObligacionCuotaPagoMigrada @I_ProcedenciaID, @B_Resultado output, @T_Message output
select @B_Resultado as resultado, @T_Message as mensaje
go


declare @I_ProcedenciaID tinyint = 1, 
		  @B_Resultado  bit,
		  @T_Message    nvarchar(4000)
exec USP_U_ValidarProcedenciaObligacionCuotaPago @I_ProcedenciaID, @B_Resultado output, @T_Message output
select @B_Resultado as resultado, @T_Message as mensaje
go


declare @I_ProcedenciaID tinyint = 1, 
		  @B_Resultado  bit,
 		  @T_Message	nvarchar(4000)
exec USP_U_ValidarDetalleObligacion @I_ProcedenciaID, @B_Resultado output, @T_Message output
select @B_Resultado as resultado, @T_Message as mensaje
go


declare @I_ProcedenciaID tinyint = 1, 
		  @B_Resultado  bit,
		  @T_Message    nvarchar(4000)
exec USP_U_ValidarDetalleObligacionConceptoPago @I_ProcedenciaID, @B_Resultado output, @T_Message output
select @B_Resultado as resultado, @T_Message as mensaje
go


declare @I_ProcedenciaID tinyint = 1, 
		  @B_Resultado  bit,
		  @T_Message    nvarchar(4000)
exec USP_U_ValidarDetalleObligacionConceptoPagoMigrado @I_ProcedenciaID, @B_Resultado output, @T_Message output
select @B_Resultado as resultado, @T_Message as mensaje
go



declare   @I_ProcedenciaID tinyint = 1,
			@I_ProcesoID int = null, 
			@I_AnioIni	 int = null, 
			@I_AnioFin	 int = null, 
			@B_Resultado  bit, 
			@T_Message nvarchar(4000)
exec USP_IU_MigrarObligacionesCtasPorCobrar @I_ProcedenciaID, @I_ProcesoID, @I_AnioIni, @I_AnioFin, @B_Resultado output, @T_Message output
select @B_Resultado as resultado, @T_Message as mensaje
go


declare   @I_ProcedenciaID tinyint = 1,
			@I_ProcesoID int = null, 
			@I_AnioIni	 int = null, 
			@I_AnioFin	 int = null, 
			@B_Resultado  bit, 
			@T_Message nvarchar(4000)
exec USP_IU_MigrarPagoObligacionesCtasPorCobrar @I_ProcedenciaID, @I_ProcesoID, @I_AnioIni, @I_AnioFin, @B_Resultado output, @T_Message output
select @B_Resultado as resultado, @T_Message as mensaje
go