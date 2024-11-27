using System.Collections.Generic;
using WebMigradorCtasPorCobrar.Models.Entities.Migracion;
using WebMigradorCtasPorCobrar.Models.Helpers;
using WebMigradorCtasPorCobrar.Models.Repository.Migracion.Obligaciones;
using WebMigradorCtasPorCobrar.Models.ViewModels;
using static WebMigradorCtasPorCobrar.Models.Helpers.Observaciones;
using CrossRepo = WebMigradorCtasPorCobrar.Models.Repository.Migracion.Cross;
using Temporal = WebMigradorCtasPorCobrar.Models.Repository.TemporalPagos.ObligacionRepository;

namespace WebMigradorCtasPorCobrar.Models.Services.Migracion.Obligaciones
{
    public class ObligacionService
    {
        private readonly OblDetService _oblDetService;
        private readonly OblCabService _oblCabService;
        private readonly OblPagoService _oblPagoService;
        private readonly CrossRepo.ControlRepository _controlRepository;
        private readonly CrossRepo.ObligacionRepository _obligacionRepositoryCross;

        public ObligacionService()
        {
            _oblCabService = new OblCabService();
            _oblDetService = new OblDetService();
            _oblPagoService = new OblPagoService();
            _controlRepository = new CrossRepo.ControlRepository();
            _obligacionRepositoryCross = new CrossRepo.ObligacionRepository();
        }


        public IEnumerable<Response> CopiarRegistrosDesdeTemporalPagos(Procedencia procedencia, string anio)
        {
            List<Response> result = new List<Response>();

            string schemaDb = Schema.SetSchema(procedencia);
            int procedenciaId = (int)procedencia;
            if (!string.IsNullOrEmpty(anio))
            {
                result.Add(_oblCabService.CopiarObligacionesPorAnio(procedenciaId, schemaDb, anio));
                result.Add(_oblDetService.CopiarObligacionesPorAnio(procedenciaId, schemaDb, anio));
                result.Add(_oblPagoService.CopiarPagoObligacionesPorAnio(procedenciaId, schemaDb, anio));
            }
            else
            {
                foreach (var tempAnio in Temporal.ObtenerAnios(schemaDb))
                {
                    result.Add(_oblCabService.CopiarObligacionesPorAnio(procedenciaId, schemaDb, tempAnio));
                    result.Add(_oblPagoService.CopiarPagoObligacionesPorAnio(procedenciaId, schemaDb, anio));
                }
            }

            return result;
        }


        public IEnumerable<Response> EjecutarValidaciones(Procedencia procedencia, string anioValidacion)
        {
            List<Response> result = new List<Response>();
            int procedencia_id = (int)procedencia;

            if (!string.IsNullOrEmpty(anioValidacion))
            {
                result = this.EjecutarValidacionesPorAnio(procedencia_id, anioValidacion);
            }
            else
            {
                foreach (var itemAnio in CrossRepo.ObligacionRepository.ObtenerAnios(procedencia_id))
                {
                    result.AddRange(this.EjecutarValidacionesPorAnio(procedencia_id, itemAnio));
                }
            }

            return result;
        }


        private List<Response> EjecutarValidacionesPorAnio(int procedencia_id, string anio)
        {
            List<Response> result = new List<Response>();

            _ = _oblCabService.InicializarEstadosValidacion(procedencia_id, anio);
            _ = _oblDetService.InicializarEstadosValidacion(procedencia_id, anio);
            _ = _oblPagoService.InicializarEstadosValidacion(procedencia_id, anio);

            result.Add(_oblCabService.ValidarExisteCodigoAlumno(procedencia_id, anio));
            result.Add(_oblCabService.ValidarAnio(procedencia_id, anio));
            result.Add(_oblCabService.ValidarPeriodo(procedencia_id, anio));
            result.Add(_oblCabService.ValidarFechaVencimiento(procedencia_id, anio));
            result.Add(_oblCabService.ValidarCuotaPagoDeObligacionMigrada(procedencia_id, anio));
            result.Add(_oblCabService.ValidarProcedenciaObligProcecedenciaCuotaPago(procedencia_id, anio));
            result.Add(_oblCabService.ValidarTieneDetallesAsociados(procedencia_id, anio));
            result.Add(_oblCabService.ValidarCabeceraObligacionRepetida(procedencia_id, anio));
            result.Add(_oblCabService.ValidarObligacionTieneConceptosMigrados(procedencia_id, anio));
            result.Add(_oblCabService.ValidarNoExistePagoEnObligacionPagada(procedencia_id, anio));
            result.Add(_oblCabService.ValidarNoExistePagoEnObligacionPagada(procedencia_id, anio));
            result.Add(_oblCabService.ValidarExisteConOtroMontoEnCtasxCobrar(procedencia_id, anio));

            result.Add(_oblDetService.ValidarSinObligacionID(procedencia_id, anio));
            result.Add(_oblDetService.ValidarConceptoExisteEnCatalogo(procedencia_id, anio));
            result.Add(_oblDetService.ValidarAnioEsUnNumero(procedencia_id, anio));
            result.Add(_oblDetService.ValidarFechaVencimiento(procedencia_id, anio));
            result.Add(_oblDetService.ValidarTieneConceptoPagoMigrado(procedencia_id, anio));
            result.Add(_oblDetService.ValidarAnioIgualAnioConcepto(procedencia_id, anio));
            result.Add(_oblDetService.ValidarPeriodoIgualPeriodoConcepto(procedencia_id, anio));
            result.Add(_oblDetService.ValidarPeriodoExisteCatologoCtas(procedencia_id, anio));
            result.Add(_oblDetService.ValidarCuotaPagoIgualCuotaPagoConcepto(procedencia_id, anio));
            result.Add(_oblDetService.ValidarTotalMontoIgualMontoCabecera(procedencia_id, anio));

            result.Add(_oblCabService.ValidarSinObservacionesEnDetalle(procedencia_id, anio));
            result.Add(_oblCabService.ValidarObservacionesAnioDetalle(procedencia_id, anio));
            result.Add(_oblCabService.ValidarObservacionesPeriodoDetalle(procedencia_id, anio));

            result.Add(_oblPagoService.ValidarFechaPago(procedencia_id, anio));
            result.Add(_oblPagoService.ValidarCabeceraObligacionObservada(procedencia_id, anio));
            result.Add(_oblPagoService.ValidarDetalleObligObservado(procedencia_id, anio));
            result.Add(_oblPagoService.ValidarCabeceraObligacionID(procedencia_id, anio));
            result.Add(_oblPagoService.ValidarMontoPagadoIgualTotalMontoPagado(procedencia_id, anio));
            result.Add(_oblPagoService.ValidarExisteEnDestinoConOtroBanco(procedencia_id, anio));


            int totalObl = _obligacionRepositoryCross.Obtener(procedencia_id, anio).Count;
            int evaluadosObl = totalObl;

            int totalDet = _obligacionRepositoryCross.ObtenerDetallePorAnio(procedencia_id, anio).Count;
            int evaluadosDet = totalDet;

            int totalDetPagos = _obligacionRepositoryCross.Obtener(procedencia_id, anio).Count;
            int evaluadosDetPagos = totalDetPagos;

            int sinEvaluar = 0;

            _controlRepository.RegistrarProcesoValidacion(Tablas.TR_Ec_Obl, procedencia_id, anio, totalObl, evaluadosObl, sinEvaluar);
            _controlRepository.RegistrarProcesoValidacion(Tablas.TR_Ec_Det, procedencia_id, anio, totalDet, evaluadosDet, sinEvaluar);
            _controlRepository.RegistrarProcesoValidacion(Tablas.TR_Ec_Det_Pagos, procedencia_id, anio, totalDetPagos, evaluadosDetPagos, sinEvaluar);

            return result;
        }

        public IEnumerable<Response> EjecutarValidacionesPorObligacionID(int obligacionID)
        {
            List<Response> result = new List<Response>();

            _ = _oblCabService.InicializarEstadosValidacion(obligacionID);
            _ = _oblDetService.InicializarEstadosValidacion(obligacionID);
            _ = _oblPagoService.InicializarEstadosValidacion(obligacionID);

            result.Add(_oblCabService.ValidarExisteCodigoAlumno(obligacionID));
            result.Add(_oblCabService.ValidarAnio(obligacionID));
            result.Add(_oblCabService.ValidarPeriodo(obligacionID));
            result.Add(_oblCabService.ValidarFechaVencimiento(obligacionID));
            result.Add(_oblCabService.ValidarCuotaPagoDeObligacionMigrada(obligacionID));
            result.Add(_oblCabService.ValidarProcedenciaObligProcecedenciaCuotaPago(obligacionID));
            result.Add(_oblCabService.ValidarTieneDetallesAsociados(obligacionID));
            result.Add(_oblCabService.ValidarCabeceraObligacionRepetida(obligacionID));
            result.Add(_oblCabService.ValidarObligacionTieneConceptosMigrados(obligacionID));
            result.Add(_oblCabService.ValidarNoExistePagoEnObligacionPagada(obligacionID));
            result.Add(_oblCabService.ValidarNoExistePagoEnObligacionPagada(obligacionID));
            result.Add(_oblCabService.ValidarExisteConOtroMontoEnCtasxCobrar(obligacionID));

            result.Add(_oblDetService.ValidarConceptoExisteEnCatalogo(obligacionID));
            result.Add(_oblDetService.ValidarAnioEsUnNumero(obligacionID));
            result.Add(_oblDetService.ValidarFechaVencimiento(obligacionID));
            result.Add(_oblDetService.ValidarTieneConceptoPagoMigrado(obligacionID));
            result.Add(_oblDetService.ValidarAnioIgualAnioConcepto(obligacionID));
            result.Add(_oblDetService.ValidarPeriodoIgualPeriodoConcepto(obligacionID));
            result.Add(_oblDetService.ValidarPeriodoExisteCatologoCtas(obligacionID));
            result.Add(_oblDetService.ValidarCuotaPagoIgualCuotaPagoConcepto(obligacionID));
            result.Add(_oblDetService.ValidarTotalMontoIgualMontoCabecera(obligacionID));

            result.Add(_oblCabService.ValidarSinObservacionesEnDetalle(obligacionID));
            result.Add(_oblCabService.ValidarObservacionesAnioDetalle(obligacionID));
            result.Add(_oblCabService.ValidarObservacionesPeriodoDetalle(obligacionID));

            result.Add(_oblPagoService.ValidarFechaPago(obligacionID));
            result.Add(_oblPagoService.ValidarCabeceraObligacionObservada(obligacionID));
            result.Add(_oblPagoService.ValidarDetalleObligObservado(obligacionID));
            result.Add(_oblPagoService.ValidarMontoPagadoIgualTotalMontoPagado(obligacionID));
            result.Add(_oblPagoService.ValidarExisteEnDestinoConOtroBanco(obligacionID));

            return result;
        }


        public Response EjecutarValidacionPorObaservacion(Procedencia procedencia, int observacionId)
        {


            return new Response();
        }


        public IEnumerable<ResponseObligacion> MigrarDatosTemporalPagosObligacion(Procedencia procedencia, string anio)
        {
            var result = new List<ResponseObligacion>();
            int procedenciaID = (int)procedencia;

            var resultCab = _oblCabService.MigrarObligacionesPorAnio(procedencia, anio);
            var resultDet = _oblDetService.MigrarObligacionesPorAnio(procedencia, anio, resultCab);
            var resultPag = _oblPagoService.MigrarObligacionesPorAnio(procedencia, anio);

            _oblCabService.ValidarMigracionDatosMatricula(procedenciaID, anio);
            _oblDetService.ValidarMigracionCabecera(procedenciaID, anio);
            _oblPagoService.ValidarMigracionCabeceraObligacion(procedenciaID, anio);

            result.Add(new ResponseObligacion()
            {
                Obligacion = resultCab,
                DetalleObligacion = new List<Response>() { resultDet }
            });

            return result;
        }

        public IEnumerable<Response> MigrarDatosTemporalPagosObligacionID(int obl_rowId)
        {
            List<Response> result = new List<Response>();


    
        return result;
        }


        public Response Save(Obligacion obligacion, int tipoObserv)
        {
            Response result = new Response();
            ObligacionRepository obligacionRepository = new ObligacionRepository();

            switch ((ObligacionesPagoObs)tipoObserv)
            {
                case ObligacionesPagoObs.SinAlumno:
                    result = obligacionRepository.SaveEstudianteObligacion(obligacion);
                    break;
                case ObligacionesPagoObs.AnioNoValido:
                    result = obligacionRepository.SaveAnioObligacion(obligacion);
                    break;
                case ObligacionesPagoObs.SinPeriodo:
                    result = obligacionRepository.SavePeriodoObligacion(obligacion);
                    break;
                case ObligacionesPagoObs.FchVencCuotaPago:
                    result = obligacionRepository.SaveFecVencObligacion(obligacion);
                    break;
                case ObligacionesPagoObs.ExisteConOtroMonto:
                    result = obligacionRepository.SaveMontoObligacion(obligacion);
                    break;
                case ObligacionesPagoObs.SinCuotaPagoMigrable:
                    result = obligacionRepository.SaveCuotaPagoObligacion(obligacion);
                    break;
            }

            obligacionRepository.ValidarAlumnoCabeceraObligacionPorID(obligacion.I_RowID);
            obligacionRepository.ValidarAnioEnCabeceraObligacionPorID(obligacion.I_RowID);
            obligacionRepository.ValidarPeriodoEnCabeceraObligacionPorID(obligacion.I_RowID);
            obligacionRepository.ValidarFechaVencimientoPorID(obligacion.I_RowID);
            obligacionRepository.ValidarObligacionCuotaPagoMigradaPorObligacionID(obligacion.I_RowID);
            obligacionRepository.ValidarProcedenciaObligacionCuotaPagoPorOblID(obligacion.I_RowID);

            return result.IsDone ? result.Success(false) : result.Error(false);
        }

        public string ObtenerComponenteId(int obsID)
        {
            string componentID;
            ObligacionesPagoObs obligacionesPagoObs = (ObligacionesPagoObs)obsID;

            switch (obligacionesPagoObs)
            {
                case ObligacionesPagoObs.SinAlumno:
                    componentID = "#Cod_alu";
                    break;
                case ObligacionesPagoObs.AnioNoValido:
                    componentID = "#Ano";
                    break;
                case ObligacionesPagoObs.SinPeriodo:
                    componentID = "#I_Periodo";
                    break;
                case ObligacionesPagoObs.FchVencCuotaPago:
                    componentID = "#Fch_venc";
                    break;
                case ObligacionesPagoObs.ExisteConOtroMonto:
                    componentID = "#Monto";
                    break;
                case ObligacionesPagoObs.SinCuotaPagoMigrable:
                    componentID = "#Cuota_pago";
                    break;
                default:
                    componentID = string.Empty;
                    break;
            }

            return componentID;
        }

    }
}