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
        
        public ObligacionService()
        {
            _oblCabService = new OblCabService();
            _oblDetService = new OblDetService();
            _oblPagoService = new OblPagoService();
        }


        public IEnumerable<Response> CopiarRegistrosDesdeTemporalPagos(Procedencia procedencia, string anio)
        {
            List<Response> result = new List<Response>();

            string schemaDb = Schema.SetSchema(procedencia);

            if (!string.IsNullOrEmpty(anio))
            {
                result = _oblCabService.CopiarObligacionesPorAnio((int)procedencia, schemaDb, anio);
            }
            else
            {
                foreach (var tempAnio in Temporal.ObtenerAnios(schemaDb))
                {
                    result.AddRange(_oblCabService.CopiarObligacionesPorAnio((int)procedencia, schemaDb, tempAnio));
                }
            }

            return result;
        }


        public IEnumerable<Response> EjecutarValidaciones(Procedencia procedencia, string anioValidacion)
        {
            List<Response> result = new List<Response>();
            int procedencia_id = (int)procedencia;
            var pagosService = new PagoOblService();


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

            result.AddRange(pagosService.EjecutarValidaciones(procedencia, anioValidacion));

            return result;
        }


        public IEnumerable<Response> EjecutarValidacionesPorObligacionID(int obligacionID)
        {
            List<Response> result = new List<Response>();
            ObligacionRepository obligacionRepository = new ObligacionRepository();
            var pagosSetvice = new PagoOblService();



            return new List<Response>();
        }


        public Response EjecutarValidacionPorObaservacion(Procedencia procedencia, int observacionId)
        {


            return new Response();
        }


        private List<Response> EjecutarValidacionesPorAnio(int procedencia_id, string anio)
        {
            List<Response> result = new List<Response>();

            _ = _oblCabService.InicializarEstadosValidacionCabecera(procedencia_id, anio);
            _ = _oblDetService.InicializarEstadosValidacionCabecera(procedencia_id, anio);
            _ = _oblPagoService.InicializarEstadosValidacionCabecera(procedencia_id, anio);

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
            result.Add(_oblDetService.ValidarTieneConceptoPagoMigrado(procedencia_id, anio));
            result.Add(_oblDetService.ValidarAnioIgualAnioConcepto(procedencia_id, anio));
            result.Add(_oblDetService.ValidarPeriodoIgualPeriodoConcepto(procedencia_id, anio));
            result.Add(_oblDetService.ValidarPeriodoExisteCatologoCtas(procedencia_id, anio));
            result.Add(_oblDetService.ValidarCuotaPagoIgualCuotaPagoConcepto(procedencia_id, anio));
            result.Add(_oblDetService.ValidarTotalMontoIgualMontoCabecera(procedencia_id, anio));

            result.Add(_oblCabService.ValidarSinObservacionesEnDetalle(procedencia_id, anio));
            result.Add(_oblCabService.ValidarObservacionesAnioDetalle(procedencia_id, anio));
            result.Add(_oblCabService.ValidarObservacionesPeriodoDetalle(procedencia_id, anio));

            result.Add(_oblDetService.ValidarMigracionCabecera(procedencia_id, anio));

            result.Add(_oblPagoService.ValidarCabeceraObligacionObservada(procedencia_id, anio));
            result.Add(_oblPagoService.ValidarDetalleOblgObservedo(procedencia_id, anio));
            result.Add(_oblPagoService.ValidarCabeceraObligacionID(procedencia_id, anio));
            result.Add(_oblPagoService.ValidarMontoPagadoIgualTotalMontoPagado(procedencia_id, anio));
            result.Add(_oblPagoService.ValidarExisteEnDestinoConOtroBanco(procedencia_id, anio));

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
            obligacionRepository.ValidarFechaVencimientoCuotaObligacionPorID(obligacion.I_RowID);
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