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
using WebMigradorCtasPorCobrar.Models.Repository.CtasPorCobrar;

namespace WebMigradorCtasPorCobrar.Models.Services.Migracion
{
    public class CuotaPagoService
    {
        public IEnumerable<CuotaPago> Obtener(Procedencia procedencia, int? tipo_obsID)
        {
            if (tipo_obsID.HasValue)
            {
                return ObtenerConRepo(CuotaPagoRepository.ObtenerObservados((int)procedencia, tipo_obsID.Value, (int)Tablas.TR_Cp_Des), procedencia);
            }

            return ObtenerConRepo(CuotaPagoRepository.Obtener((int)procedencia), procedencia);
        }

        private IEnumerable<CuotaPago> ObtenerConRepo(IEnumerable<CuotaPago> cuotasPago, Procedencia procedencia)
        {
            var cuotasPagoCtas = RepoCtas.ProcesoRepositoty.Obtener((int)procedencia);

            var newCuotasPago = from c in cuotasPago
                                join cr in cuotasPagoCtas on c.Cuota_pago equals cr.I_ProcesoID
                                into cuotasPagoProcesoGroup
                                from cppg in cuotasPagoProcesoGroup.DefaultIfEmpty()
                                select new CuotaPago()
                                {
                                    Cuota_pago = c.Cuota_pago,
                                    Descripcio = c.Descripcio,
                                    I_Anio = c.I_Anio,
                                    PeriodoDesc = c.PeriodoDesc,
                                    N_cta_cte = c.N_cta_cte,
                                    Codigo_bnc = c.Codigo_bnc,
                                    Fch_venc = c.Fch_venc,
                                    Eliminado = c.Eliminado,
                                    B_Migrable = c.B_Migrable,
                                    B_Migrado = c.B_Migrado,
                                    I_RowID = c.I_RowID,
                                    B_ExisteCtas = cppg == null ? false : true
                                };

            return newCuotasPago;
        }

        public CuotaPago Obtener(int cuotaID)
        {
            var result = CuotaPagoRepository.ObtenerPorId(cuotaID);

            if (result.I_CatPagoID.HasValue)
            {
                result.CatPagoDesc = CategoriaPagoRepository.Obtener(result.I_CatPagoID.Value).T_CatPagoDesc;
            }

            return CuotaPagoRepository.ObtenerPorId(cuotaID);
        }

        public CuotaPago ObtenerConRelaciones(int cuotaID)
        {
            var cuotaPago = CuotaPagoRepository.ObtenerPorId(cuotaID);
            cuotaPago.ConceptosPago = new List<ConceptoPago>();
            cuotaPago.Obligaciones = new List<Obligacion>();
            cuotaPago.DetalleObligaciones = new List<DetalleObligacion>();

            string schema = Schema.SetSchema((Procedencia)cuotaPago.I_ProcedenciaID);

            foreach (var Temp_conceptoPago in Temporal.ConceptoPagoRepository.ObtenerPorCuotaPago(schema, cuotaPago.Cuota_pago.ToString()))
            {
                cuotaPago.ConceptosPago.Add(new ConceptoPago(Temp_conceptoPago));
            }

            foreach (var Temp_item in Temporal.ObligacionRepository.ObtenerObligacionPorCuotaPago(schema, cuotaPago.Cuota_pago.ToString())
                                                                   .Select(x => new { x.Ano, x.P, x.Cuota_pago, x.Descripcio })
                                                                   .Distinct())
            {
                var obligacion = new Entities.TemporalPagos.Obligacion()
                {
                    Ano = Temp_item.Ano,
                    P = Temp_item.P,
                    Cuota_pago = Temp_item.Cuota_pago,
                    Descripcio = Temp_item.Descripcio,
                };

                cuotaPago.Obligaciones.Add(new Obligacion(obligacion));
            }

            foreach (var Temp_item in Temporal.ObligacionRepository.ObtenerDetallePorCuotaPago(schema, cuotaPago.Cuota_pago.ToString())//.Where(x => x.Eliminado == false)
                                                                   .Select(x => new { x.Ano, x.P, x.Cuota_pago, x.Concepto, x.Descripcio, x.Eliminado })
                                                                   .Distinct().OrderBy(x => x.Ano))
            {
                var detalle = new Entities.TemporalPagos.DetalleObligacion()
                {
                    Ano = Temp_item.Ano,
                    P = Temp_item.P,
                    Cuota_pago = Temp_item.Cuota_pago,
                    Concepto = Temp_item.Concepto,
                    Descripcio = Temp_item.Descripcio,
                    Eliminado = Temp_item.Eliminado
                };

                cuotaPago.DetalleObligaciones.Add(new DetalleObligacion(detalle));
            }

            return cuotaPago;
        }

        public byte[] ObtenerDatosObservaciones(Procedencia procedencia, int? tipo_obsID)
        {
            XLWorkbook excel_book = new XLWorkbook();
            MemoryStream result = new MemoryStream();

            tipo_obsID = tipo_obsID.HasValue ? tipo_obsID : 0;
            var data = CuotaPagoRepository.ObtenerReporteObservados((int)procedencia, tipo_obsID.Value, (int)Tablas.TR_Cp_Des);

            var sheet = excel_book.Worksheets.Add(data, "Observaciones");
            sheet.ColumnsUsed().AdjustToContents();

            excel_book.SaveAs(result);

            return result.ToArray();
        }


        public Response CopiarRegistrosDesdeTemporalPagos(Procedencia procedencia)
        {
            Response result = new Response();
            CuotaPagoRepository cuotaPagoRepository = new CuotaPagoRepository();

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

            result = cuotaPagoRepository.CopiarRegistros((int)procedencia, schemaDb, codigos_bnc);

            return result.IsDone ? result.Success(false) : result.Error(false);
        }

        public Response EjecutarValidaciones(Procedencia procedencia, int? cuotaPagoRowID)
        {
            Response result = new Response();
            CuotaPagoRepository cuotaPagoRepository = new CuotaPagoRepository();

            Response result_InicializarEstados = new Response();
            Response result_duplicados = new Response();
            Response result_categorias = new Response();
            Response result_anio = new Response();
            Response result_periodo = new Response();
            Response result_removido = new Response();

            string schemaDb = Schema.SetSchema(procedencia);

            result_InicializarEstados = cuotaPagoRepository.InicializarEstadoValidacionCuotaPago(cuotaPagoRowID, (int)procedencia);
            result_duplicados = cuotaPagoRepository.MarcarDuplicadosCuotaPago((int)procedencia);
            result_removido = cuotaPagoRepository.MarcarEliminadosCuotaPago(cuotaPagoRowID, (int)procedencia);
            result_categorias = cuotaPagoRepository.AsignarCategoriaCuotaPago(cuotaPagoRowID, (int)procedencia);
            result_anio = cuotaPagoRepository.AsignarAnioCuotaPago(cuotaPagoRowID, (int)procedencia, schemaDb);
            result_periodo = cuotaPagoRepository.AsignarPeriodoCuotaPago(cuotaPagoRowID, (int)procedencia, schemaDb);

            result.IsDone = result_duplicados.IsDone &&
                            result_removido.IsDone &&
                            result_categorias.IsDone &&
                            result_anio.IsDone &&
                            result_periodo.IsDone;

            result.Message = $"    <dl class=\"row text-justify pt-3\">" +
                             $"        <dt class=\"col-md-6 col-sm-8 col-10 text-right\">Con código de cuota duplicado :</dt>" +
                             $"        <dd class=\"col-md-6 col-sm-4 col-2\">" +
                             $"            <p>{result_duplicados.Message}</p>" +
                             $"        </dd>" +
                             $"        <dt class=\"col-md-6 col-sm-8 col-10 text-right\">Sin categoría equivalente en cuentas por cobrar :</dt>" +
                             $"        <dd class=\"col-md-6 col-sm-4 col-2\">" +
                             $"            <p>{result_categorias.Message}</p>" +
                             $"        </dd>" +
                             $"        <dt class=\"col-md-6 col-sm-8 col-10 text-right\">Observaciones en Año de la cuota de pago :</dt>" +
                             $"        <dd class=\"col-md-6 col-sm-4 col-2\">" +
                             $"            <p>{result_anio.Message}</p>" +
                             $"        </dd>" +
                             $"        <dt class=\"col-md-6 col-sm-8 col-10 text-right\">Observaciones en Periodo de la cuota de pago :</dt>" +
                             $"        <dd class=\"col-md-6 col-sm-4 col-2\">" +
                             $"            <p>{result_periodo.Message}</p>" +
                             $"        </dd>" +
                             $"        <dt class=\"col-md-6 col-sm-8 col-10 text-right\">Observados por estado eliminado :</dt>" +
                             $"        <dd class=\"col-md-6 col-sm-4 col-2\">" +
                             $"            <p>{result_removido.Message}</p>" +
                             $"        </dd>" +
                             //$"        <dt class=\"col-md-6 col-sm-8 col-10 text-right\">Observados por Modalidades de ingreso :</dt>" +
                             //$"        <dd class=\"col-md-6 col-sm-4 col-2\">" +
                             //$"            <p>{result_ModIngresoAlumno.Message}</p>" +
                             //$"        </dd>" +
                             //$"        <dt class=\"col-md-6 col-sm-8 col-10 text-right\">Observados por Número de documento :</dt>" +
                             //$"        <dd class=\"col-md-6 col-sm-4 col-2\">" +
                             //$"            <p>{result_CorrespondenciaNumDoc.Message}</p>" +
                             //$"        </dd>" +
                             //$"        <dt class=\"col-md-6 col-sm-8 col-10 text-right\">Observados por Sexo duplicado :</dt>" +
                             //$"        <dd class=\"col-md-6 col-sm-4 col-2\">" +
                             //$"            <p>{result_SexoDiferenteMismoDoc.Message}</p>" +
                             //$"        </dd>" +
                             $"    </dl>";


            return result.IsDone ? result.Success(false) : result.Error(false);
        }

        public IEnumerable<Response> MigrarDatosTemporalPagos(Procedencia procedencia)
        {
            List<Response> result = new List<Response>();
            string schemaDb = Schema.SetSchema(procedencia);

            CuotaPagoRepository cuotaPagoRepository = new CuotaPagoRepository();

            Response result_part = cuotaPagoRepository.MigrarDataCuotaPagoCtasPorCobrar((int)procedencia, null, null, null);

            result.Add(result_part.IsDone ? result_part.Success(false) : result_part.Error(false));

            return result;
        }


        public Response Save(CuotaPago cuotaPago, int tipoObsID)
        {
            Response result = new Response();
            string schemaDb = Schema.SetSchema((Procedencia)cuotaPago.I_ProcedenciaID);
            cuotaPago.Fch_venc = !string.IsNullOrEmpty(cuotaPago.Fch_venc_s) ? DateTime.Parse(cuotaPago.Fch_venc_s) : cuotaPago.Fch_venc;

            CuotaPagoRepository cuotaPagoRepository = new CuotaPagoRepository();
            cuotaPagoRepository.InicializarEstadoValidacionCuotaPago(cuotaPago.I_RowID, cuotaPago.I_ProcedenciaID);

            switch ((CuotaPagoObs)tipoObsID)
            {
                case CuotaPagoObs.Repetido:
                    result = cuotaPagoRepository.SaveRepetido(cuotaPago);
                    break;
                case CuotaPagoObs.MasDeUnAnio:
                    result = cuotaPagoRepository.SaveAnio(cuotaPago);
                    break;
                case CuotaPagoObs.SinAnio:
                    result = cuotaPagoRepository.SaveAnio(cuotaPago);
                    break;
                case CuotaPagoObs.MasDeUnPeriodo:
                    result = cuotaPagoRepository.SavePeriodo(cuotaPago);
                    break;
                case CuotaPagoObs.SinPeriodo:
                    result = cuotaPagoRepository.SavePeriodo(cuotaPago);
                    break;
                case CuotaPagoObs.MásDeUnaCategoría:
                    result = cuotaPagoRepository.SaveCategoria(cuotaPago);
                    break;
                case CuotaPagoObs.SinCategoria:
                    result = cuotaPagoRepository.SaveCategoria(cuotaPago);
                    break;
            }

            cuotaPagoRepository.MarcarDuplicadosCuotaPago(cuotaPago.I_ProcedenciaID);
            cuotaPagoRepository.AsignarCategoriaCuotaPago(cuotaPago.I_RowID, cuotaPago.I_ProcedenciaID);
            cuotaPagoRepository.AsignarAnioCuotaPago(cuotaPago.I_RowID, cuotaPago.I_ProcedenciaID, schemaDb);
            cuotaPagoRepository.AsignarPeriodoCuotaPago(cuotaPago.I_RowID, cuotaPago.I_ProcedenciaID, schemaDb);

            return result.IsDone ? result.Success(false) : result.Error(false);
        }
    }
}