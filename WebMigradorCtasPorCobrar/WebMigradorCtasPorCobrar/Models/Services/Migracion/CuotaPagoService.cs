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

namespace WebMigradorCtasPorCobrar.Models.Services.Migracion
{
    public class CuotaPagoService
    {
        public IEnumerable<CuotaPago> Obtener(Procedencia procedencia, int? tipo_obsID)
        {
            if (tipo_obsID.HasValue)
            {
                return CuotaPagoRepository.ObtenerObservados((int)procedencia, tipo_obsID.Value, (int)Tablas.TR_Cp_Des);
            }

            return CuotaPagoRepository.Obtener((int)procedencia);
        }

        public CuotaPago Obtener(int cuotaID)
        {
            return CuotaPagoRepository.ObtenerPorId(cuotaID);
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

        public Response EjecutarValidaciones(Procedencia procedencia)
        {
            Response result = new Response();
            CuotaPagoRepository cuotaPagoRepository = new CuotaPagoRepository();

            Response result_InicializarEstados = new Response();
            Response result_duplicados = new Response();
            Response result_categorias = new Response();
            Response result_anioPeriodo = new Response();
            string schemaDb = Schema.SetSchema(procedencia);

            result_InicializarEstados = cuotaPagoRepository.InicializarEstadoValidacionCuotaPago((int)procedencia);
            result_duplicados = cuotaPagoRepository.MarcarDuplicadosCuotaPago((int)procedencia);
            result_categorias = cuotaPagoRepository.AsignarCategoriaCuotaPago((int)procedencia);
            result_anioPeriodo = cuotaPagoRepository.AsignarAnioPeriodoCuotaPago((int)procedencia, schemaDb);

            result.IsDone = result_duplicados.IsDone &&
                            result_categorias.IsDone &&
                            result_anioPeriodo.IsDone;
            
            result.Message = $"    <dl class=\"row text-justify\">" +
                             $"        <dt class=\"col-md-4 col-sm-6\">Con código de cuota duplicado</dt>" +
                             $"        <dd class=\"col-md-8 col-sm-6\">" +
                             $"            <p>{result_duplicados.Message}</p>" +
                             $"        </dd>" +
                             $"        <dt class=\"col-md-4 col-sm-6\">Sin categoría equivalente en cuentas por cobrar </dt>" +
                             $"        <dd class=\"col-md-8 col-sm-6\">" +
                             $"            <p>{result_categorias.Message}</p>" +
                             $"        </dd>" +
                             $"        <dt class=\"col-md-4 col-sm-6\">No se identificó Año de la cuota de pago</dt>" +
                             $"        <dd class=\"col-md-8 col-sm-6\">" +
                             $"            <p>{result_anioPeriodo.Message}</p>" +
                             $"        </dd>" +
                             //$"        <dt class=\"col-md-4 col-sm-6\">Observados por Años de ingreso</dt>" +
                             //$"        <dd class=\"col-md-8 col-sm-6\">" +
                             //$"            <p>{result_AnioIngresoAlumno.Message}</p>" +
                             //$"        </dd>" +
                             //$"        <dt class=\"col-md-4 col-sm-6\">Observados por Modalidades de ingreso</dt>" +
                             //$"        <dd class=\"col-md-8 col-sm-6\">" +
                             //$"            <p>{result_ModIngresoAlumno.Message}</p>" +
                             //$"        </dd>" +
                             //$"        <dt class=\"col-md-4 col-sm-6\">Observados por Número de documento</dt>" +
                             //$"        <dd class=\"col-md-8 col-sm-6\">" +
                             //$"            <p>{result_CorrespondenciaNumDoc.Message}</p>" +
                             //$"        </dd>" +
                             //$"        <dt class=\"col-md-4 col-sm-6\">Observados por Sexo duplicado</dt>" +
                             //$"        <dd class=\"col-md-8 col-sm-6\">" +
                             //$"            <p>{result_SexoDiferenteMismoDoc.Message}</p>" +
                             //$"        </dd>" +
                             $"    </dl>";


            return result.IsDone ? result.Success(false) : result.Error(false);
        }

        public Response Save(int Id, int I_PeriodoID)
        {
            Response result = new Response();
            CuotaPagoRepository cuotaPagoRepository = new CuotaPagoRepository();

            //result = cuotaPagoRepository.Save(Id, I_PeriodoID);

            return result;
        }

        public Response MigrarDatosTemporalPagos(Procedencia procedencia)
        {
            Response result = new Response();
            string schemaDb = Schema.SetSchema(procedencia);

            CuotaPagoRepository cuotaPagoRepository = new CuotaPagoRepository();

            result = cuotaPagoRepository.MigrarDataCuotaPagoCtasPorCobrar((int)procedencia, null, null, null);

            return result.IsDone ? result.Success(false): result.Error(false);
        }
    }
}