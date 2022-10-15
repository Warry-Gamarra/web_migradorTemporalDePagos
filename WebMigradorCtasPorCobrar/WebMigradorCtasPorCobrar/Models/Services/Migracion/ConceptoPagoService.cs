using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using WebMigradorCtasPorCobrar.Models.Repository.Migracion;
using WebMigradorCtasPorCobrar.Models.Entities.Migracion;
using WebMigradorCtasPorCobrar.Models.Helpers;
using WebMigradorCtasPorCobrar.Models.ViewModels;
using ClosedXML.Excel;
using System.IO;
using static WebMigradorCtasPorCobrar.Models.Helpers.Observaciones;
using WebMigradorCtasPorCobrar.Models.Services.CtasPorCobrar;

namespace WebMigradorCtasPorCobrar.Models.Services.Migracion
{
    public class ConceptoPagoService
    {
        private readonly EquivalenciasServices _equivalenciaServices;

        public ConceptoPagoService()
        {
            _equivalenciaServices = new EquivalenciasServices();
        }

        public IEnumerable<ConceptoPago> Obtener(Procedencia procedencia, int? tipo_obsID)
        {
            if (tipo_obsID.HasValue)
            {
                return ConceptoPagoRepository.ObtenerObservados((int)procedencia, tipo_obsID.Value, (int)Tablas.TR_Cp_Pri);
            }

            return ConceptoPagoRepository.Obtener((int)procedencia);
        }

        public ConceptoPago Obtener(int cuotaID)
        {
            return ConceptoPagoRepository.ObtenerPorId(cuotaID);
        }


        public byte[] ObtenerDatosObservaciones(Procedencia procedencia, int? tipo_obsID)
        {
            XLWorkbook excel_book = new XLWorkbook();
            MemoryStream result = new MemoryStream();

            tipo_obsID = tipo_obsID.HasValue ? tipo_obsID : 0;
            var data = ConceptoPagoRepository.ObtenerReporteObservados((int)procedencia, tipo_obsID.Value, (int)Tablas.TR_Cp_Pri);

            var sheet = excel_book.Worksheets.Add(data, "Observaciones");
            sheet.ColumnsUsed().AdjustToContents();

            excel_book.SaveAs(result);

            return result.ToArray();
        }

        public Response CopiarRegistrosDesdeTemporalPagos(Procedencia procedencia)
        {
            Response result = new Response();
            ConceptoPagoRepository conceptoPagoRepository = new ConceptoPagoRepository();

            string schemaDb = Schema.SetSchema(procedencia);
            string codigos_bnc = "";

            switch (procedencia)
            {
                case Procedencia.Pregrado:
                    codigos_bnc = Constant.PREGRADO_TEMPORAL_CODIGOS_BNC;
                    break;
                case Procedencia.Posgrado:
                    codigos_bnc = Constant.POSGRADO_TEMPORAL_CODIGOS_BNC;
                    break;
                case Procedencia.Cuded:
                    codigos_bnc = Constant.EUDED_TEMPORAL_CODIGOS_BNC + ", "
                                + Constant.PROLICE_TEMPORAL_CODIGOS_BNC + ", "
                                + Constant.PROCUNED_TEMPORAL_CODIGOS_BNC;
                    break;
                default:
                    codigos_bnc = "''";
                    break;
            }

            result = conceptoPagoRepository.CopiarRegistros((int)procedencia, schemaDb, codigos_bnc);

            return result.IsDone ? result.Success(false) : result.Error(false);
        }

        public Response EjecutarValidaciones(Procedencia procedencia)
        {
            Response result = new Response();
            ConceptoPagoRepository conceptoPagoRepository = new ConceptoPagoRepository();

            Response result_inicializarEstados = new Response();
            Response result_duplicados = new Response();
            Response result_anio = new Response();
            Response result_periodo = new Response();
            Response result_cuotaPago = new Response();
            Response result_equivalencias = new Response();
            Response result_catalogoConceptos = new Response();

            string schemaDb = Schema.SetSchema(procedencia);

            result_inicializarEstados = conceptoPagoRepository.InicializarEstadoValidacionCuotaPago((int)procedencia);

            result_duplicados = conceptoPagoRepository.ValidarDuplicadoConceptosPago((int)procedencia);
            result_anio = conceptoPagoRepository.ValidarConceptosPagoObligSinAnioAsignado((int)procedencia);
            result_periodo = conceptoPagoRepository.ValidarConceptosPagoObligSinPeriodoAsignado((int)procedencia);
            result_cuotaPago = conceptoPagoRepository.ValidarConceptosPagoObligSinCuotaPago((int)procedencia);
            result_equivalencias = conceptoPagoRepository.AsignarIdEquivalenciasConceptoPago((int)procedencia);
            result_catalogoConceptos = conceptoPagoRepository.GrabarTablaCatalogoConceptos((int)procedencia);

            result.IsDone = result_duplicados.IsDone &&
                            result_anio.IsDone &&
                            result_periodo.IsDone &&
                            result_cuotaPago.IsDone &&
                            result_equivalencias.IsDone;

            result.Message = $"    <dl class=\"row text-justify\">" +
                             $"        <dt class=\"col-md-4 col-sm-6\">Con código de concepto duplicado</dt>" +
                             $"        <dd class=\"col-md-8 col-sm-6\">" +
                             $"            <p>{result_duplicados.Message}</p>" +
                             $"        </dd>" +
                             $"        <dt class=\"col-md-4 col-sm-6\">No se identificó año del concepto de pago</dt>" +
                             $"        <dd class=\"col-md-8 col-sm-6\">" +
                             $"            <p>{result_anio.Message}</p>" +
                             $"        </dd>" +
                             $"        <dt class=\"col-md-4 col-sm-6\">No se identificó periodo del concepto de pago</dt>" +
                             $"        <dd class=\"col-md-8 col-sm-6\">" +
                             $"            <p>{result_periodo.Message}</p>" +
                             $"        </dd>" +
                             $"        <dt class=\"col-md-4 col-sm-6\">Concepto sin cuota de pago</dt>" +
                             $"        <dd class=\"col-md-8 col-sm-6\">" +
                             $"            <p>{result_cuotaPago.Message}</p>" +
                             $"        </dd>" +
                             $"        <dt class=\"col-md-4 col-sm-6\">Codigos de equivalencia para migración</dt>" +
                             $"        <dd class=\"col-md-8 col-sm-6\">" +
                             $"            <p>{result_equivalencias.Message}</p>" +
                             $"        </dd>" +
                             //$"        <dt class=\"col-md-4 col-sm-6\">Observados por Número de documento</dt>" +
                             //$"        <dd class=\"col-md-8 col-sm-6\">" +
                             //$"            <p>{result_catalogoConceptos.Message}</p>" +
                             //$"        </dd>" +
                             //$"        <dt class=\"col-md-4 col-sm-6\">Observados por Sexo duplicado</dt>" +
                             //$"        <dd class=\"col-md-8 col-sm-6\">" +
                             //$"            <p>{result_SexoDiferenteMismoDoc.Message}</p>" +
                             //$"        </dd>" +
                             $"    </dl>";


            return result.IsDone ? result.Success(false) : result.Error(false);
        }

        public ConceptoPago ObtenerConRelaciones(int conceptoPagoID)
        {
            ConceptoPago conceptoPago = ConceptoPagoRepository.ObtenerPorId(conceptoPagoID);
            conceptoPago.I_Periodo = _equivalenciaServices.ObtenerPeriodosAcademicos(conceptoPago.P).I_OpcionID;

            conceptoPago.CuotasPago = new List<CuotaPago>();

            return conceptoPago;
        }

        public Response Save(ConceptoPago conceptoPago, int tipoObserv)
        {
            Response result = new Response();

            switch ((ConceptoPagoObs)tipoObserv)
            {
                case ConceptoPagoObs.Repetido:
                    result = ConceptoPagoRepository.Save();
                    break;
                case ConceptoPagoObs.SinCuotaPago:
                    result = ConceptoPagoRepository.Save();
                    break;
                case ConceptoPagoObs.SinCuotaMigrada:
                    result = ConceptoPagoRepository.Save();
                    break;
                case ConceptoPagoObs.SinAnio:
                    result = ConceptoPagoRepository.Save();
                    break;
                case ConceptoPagoObs.Externo:
                    result = ConceptoPagoRepository.Save();
                    break;
                case ConceptoPagoObs.SinPeriodo:
                    result = ConceptoPagoRepository.Save();
                    break;
                case ConceptoPagoObs.ErrorConAnioCuota:
                    result = ConceptoPagoRepository.Save();
                    break;
                case ConceptoPagoObs.ErroConPeriodoCuota:
                    result = ConceptoPagoRepository.Save();
                    break;
            }

            return result.IsDone ? result.Success(false) : result.Error(false);
        }

        public Response MigrarDatosTemporalPagos(Procedencia procedencia)
        {
            Response result = new Response();
            string schemaDb = Schema.SetSchema(procedencia);

            ConceptoPagoRepository conceptoPagoRepository = new ConceptoPagoRepository();

            result = conceptoPagoRepository.MigrarDataConceptoPagoCtasPorCobrar((int)procedencia, null, null, null);

            return result.IsDone ? result.Success(false) : result.Error(false);
        }
    }


}