using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using Temporal = WebMigradorCtasPorCobrar.Models.Repository.TemporalPagos;
using RepoCtas = WebMigradorCtasPorCobrar.Models.Repository.CtasPorCobrar;
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

        private IEnumerable<ConceptoPago> ObtenerConRepo(IEnumerable<ConceptoPago> conceptosPago, Procedencia procedencia)
        {
            var conceptosPagoCtas = RepoCtas.ConceptoPagoRepository.Obtener((int)procedencia);

            var newCuotasPago = from c in conceptosPago
                                join cr in conceptosPagoCtas on c.Id_cp equals cr.I_ConcPagID
                                into conceptosPagoConceptosPagoCtasGroup
                                from cpg in conceptosPagoConceptosPagoCtasGroup.DefaultIfEmpty()
                                select new ConceptoPago()
                                {
                                    Id_cp = c.Id_cp,
                                    Cuota_pago = c.Cuota_pago,
                                    Descripcio = c.Descripcio,
                                    Ano = c.Ano,
                                    P = c.P,
                                    Cuota_pago_desc = c.Cuota_pago_desc,
                                    Tipo_oblig = c.Tipo_oblig,
                                    Eliminado = c.Eliminado,
                                    Monto = c.Monto,
                                    B_Migrable = c.B_Migrable,
                                    B_Migrado = c.B_Migrado,
                                    I_RowID = c.I_RowID,
                                    B_ExisteCtas = cpg == null ? false : true
                                };

            return newCuotasPago;
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
            Response result_removidos = new Response();
            Response result_noObligacion = new Response();
            Response result_anio = new Response();
            Response result_anioCp = new Response();
            Response result_periodo = new Response();
            Response result_periodoCp = new Response();
            Response result_cuotaPago = new Response();
            Response result_equivalencias = new Response();
            Response result_catalogoConceptos = new Response();

            string schemaDb = Schema.SetSchema(procedencia);

            result_inicializarEstados = conceptoPagoRepository.InicializarEstadoValidacionCuotaPago(null, (int)procedencia);

            result_duplicados = conceptoPagoRepository.ValidarDuplicadoConceptosPago(null, (int)procedencia);
            result_removidos = conceptoPagoRepository.ValidarEliminadoConceptosPago(null, (int)procedencia);
            result_noObligacion = conceptoPagoRepository.ValidarConceptosPagoNoObligacion(null, (int)procedencia);
            result_anio = conceptoPagoRepository.ValidarConceptosPagoObligSinAnioAsignado(null, (int)procedencia);
            result_anioCp = conceptoPagoRepository.ValidarConceptosPagoConAnioDiferenteCuotaPago(null, (int)procedencia);
            result_periodo = conceptoPagoRepository.ValidarConceptosPagoObligSinPeriodoAsignado(null, (int)procedencia);
            result_periodoCp = conceptoPagoRepository.ValidarConceptosPagoConPeriodoDiferenteCuotaPago(null, (int)procedencia);
            result_cuotaPago = conceptoPagoRepository.ValidarConceptosPagoObligSinCuotaPago(null, (int)procedencia);
            result_equivalencias = conceptoPagoRepository.AsignarIdEquivalenciasConceptoPago(null, (int)procedencia);
            result_catalogoConceptos = conceptoPagoRepository.GrabarTablaCatalogoConceptos((int)procedencia);

            result.IsDone = result_duplicados.IsDone &&
                            result_removidos.IsDone &&
                            result_noObligacion.IsDone &&
                            result_anio.IsDone &&
                            result_anioCp.IsDone &&
                            result_periodo.IsDone &&
                            result_periodoCp.IsDone &&
                            result_cuotaPago.IsDone &&
                            result_equivalencias.IsDone;

            result.Message = $"    <dl class=\"row text-justify pt-3\">" +
                             $"        <dt class=\"col-md-6 col-sm-8 col-10 text-right\">Con código de concepto duplicado</dt>" +
                             $"        <dd class=\"col-md-6 col-sm-4 col-2\">" +
                             $"            <p>{result_duplicados.Message}</p>" +
                             $"        </dd>" +
                             $"        <dt class=\"col-md-6 col-sm-8 col-10 text-right\">Estados del concepto de pago </dt>" +
                             $"        <dd class=\"col-md-6 col-sm-4 col-2\">" +
                             $"            <p>{result_removidos.Message} | {result_noObligacion.Message}</p>" +
                             $"        </dd>" +
                             $"        <dt class=\"col-md-6 col-sm-8 col-10 text-right\">No se identificó año del concepto de pago</dt>" +
                             $"        <dd class=\"col-md-6 col-sm-4 col-2\">" +
                             $"            <p>{result_anio.Message} | {result_anioCp.Message}</p>" +
                             $"        </dd>" +
                             $"        <dt class=\"col-md-6 col-sm-8 col-10 text-right\">No se identificó periodo del concepto de pago</dt>" +
                             $"        <dd class=\"col-md-6 col-sm-4 col-2\">" +
                             $"            <p>{result_periodo.Message} | {result_periodoCp.Message}</p>" +
                             $"        </dd>" +
                             $"        <dt class=\"col-md-6 col-sm-8 col-10 text-right\">Concepto sin cuota de pago</dt>" +
                             $"        <dd class=\"col-md-6 col-sm-4 col-2\">" +
                             $"            <p>{result_cuotaPago.Message}</p>" +
                             $"        </dd>" +
                             $"        <dt class=\"col-md-6 col-sm-8 col-10 text-right\">Codigos de equivalencia para migración</dt>" +
                             $"        <dd class=\"col-md-6 col-sm-4 col-2\">" +
                             $"            <p>{result_equivalencias.Message}</p>" +
                             $"        </dd>" +
                             $"    </dl>";


            return result.IsDone ? result.Success(false) : result.Error(false);
        }

        public ConceptoPago ObtenerConRelaciones(int conceptoPagoID)
        {
            ConceptoPago conceptoPago = ConceptoPagoRepository.ObtenerPorId(conceptoPagoID);

            conceptoPago.CuotasPago = new List<CuotaPago>();
            conceptoPago.DetalleObligaciones = new List<DetalleObligacion>();

            string schema = Schema.SetSchema((Procedencia)conceptoPago.I_ProcedenciaID);
            string str_conceptoPago = conceptoPago.Id_cp.ToString();

            foreach (var concepto in ConceptoPagoRepository.Obtener(conceptoPago.I_ProcedenciaID).Where(x => x.Id_cp == conceptoPago.Id_cp))
            {
                foreach (var cuotaPago in CuotaPagoRepository.Obtener(concepto.I_ProcedenciaID).Where(x => x.Cuota_pago == concepto.Cuota_pago))
                {
                    conceptoPago.CuotasPago.Add(cuotaPago);
                }
            }

            foreach (var obligacion in Temporal.ObligacionRepository.ObtenerObligacionPorConceptoPago(schema, str_conceptoPago))
            {

            }

            foreach (var detalleObligacion in Temporal.ObligacionRepository.ObtenerDetallePorConceptoPago(schema, str_conceptoPago)//.Where (x => x.Eliminado == false)
                                                                           .Select(x => new { x.Cuota_pago, x.Ano, x.P, x.Concepto,
                                                                                              x.Descripcio, x.Eliminado }).Distinct())
            {
                conceptoPago.DetalleObligaciones.Add(new DetalleObligacion()
                                                     {
                                                         Cuota_pago = detalleObligacion.Cuota_pago,
                                                         Ano = detalleObligacion.Ano,
                                                         P = detalleObligacion.P,
                                                         Concepto = detalleObligacion.Concepto,
                                                         Descripcio = detalleObligacion.Descripcio,
                                                         Eliminado = detalleObligacion.Eliminado
                                                     });
            }

            return conceptoPago;
        }

        public Response Save(ConceptoPago conceptoPago, int tipoObserv)
        {
            Response result = new Response();
            ConceptoPagoRepository conceptoPagoRepository = new ConceptoPagoRepository();
            conceptoPago.P = _equivalenciaServices.ObtenerPorId(conceptoPago.I_TipPerID).T_OpcionCod;

            conceptoPagoRepository.InicializarEstadoValidacionCuotaPago(conceptoPago.I_RowID, conceptoPago.I_ProcedenciaID);

            switch ((ConceptoPagoObs)tipoObserv)
            {
                case ConceptoPagoObs.Repetido:
                    result = conceptoPagoRepository.SaveRepetido(conceptoPago);
                    break;
                case ConceptoPagoObs.SinCuotaPago:
                    result = conceptoPagoRepository.SaveCuotaPago(conceptoPago);
                    break;
                case ConceptoPagoObs.SinAnio:
                    result = conceptoPagoRepository.SaveAnio(conceptoPago);
                    break;
                case ConceptoPagoObs.SinPeriodo:
                    result = conceptoPagoRepository.SavePeriodo(conceptoPago);
                    break;
                case ConceptoPagoObs.ErrorConAnioCuota:
                    result = conceptoPagoRepository.SaveAnio(conceptoPago);
                    break;
                case ConceptoPagoObs.ErrorConPeriodoCuota:
                    result = conceptoPagoRepository.SavePeriodo(conceptoPago);
                    break;
                case ConceptoPagoObs.NoObligacion:
                    result = conceptoPagoRepository.SaveEstadoObligacion(conceptoPago);
                    break;

            }

            conceptoPagoRepository.ValidarDuplicadoConceptosPago(conceptoPago.I_RowID,  conceptoPago.I_ProcedenciaID);
            conceptoPagoRepository.ValidarEliminadoConceptosPago(conceptoPago.I_RowID, conceptoPago.I_ProcedenciaID);
            conceptoPagoRepository.ValidarConceptosPagoNoObligacion(conceptoPago.I_RowID, conceptoPago.I_ProcedenciaID);
            conceptoPagoRepository.ValidarConceptosPagoObligSinAnioAsignado(conceptoPago.I_RowID,  conceptoPago.I_ProcedenciaID);
            conceptoPagoRepository.ValidarConceptosPagoConAnioDiferenteCuotaPago(conceptoPago.I_RowID,  conceptoPago.I_ProcedenciaID);
            conceptoPagoRepository.ValidarConceptosPagoObligSinPeriodoAsignado(conceptoPago.I_RowID,  conceptoPago.I_ProcedenciaID);
            conceptoPagoRepository.ValidarConceptosPagoConPeriodoDiferenteCuotaPago(conceptoPago.I_RowID,  conceptoPago.I_ProcedenciaID);
            conceptoPagoRepository.ValidarConceptosPagoObligSinCuotaPago(conceptoPago.I_RowID,  conceptoPago.I_ProcedenciaID);
            conceptoPagoRepository.AsignarIdEquivalenciasConceptoPago(conceptoPago.I_RowID,  conceptoPago.I_ProcedenciaID);

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