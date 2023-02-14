using ClosedXML.Excel;
using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Web;
using WebMigradorCtasPorCobrar.Models.Entities.Migracion;
using WebMigradorCtasPorCobrar.Models.Helpers;
using WebMigradorCtasPorCobrar.Models.Repository.Migracion;
using WebMigradorCtasPorCobrar.Models.ViewModels;

namespace WebMigradorCtasPorCobrar.Models.Services.Migracion
{
    public class ObligacionService
    {
        public IEnumerable<Obligacion> ObtenerObligaciones(Procedencia procedencia, int? tipo_obsID)
        {
            if (tipo_obsID.HasValue)
            {
                return ObligacionRepository.ObtenerObservados((int)procedencia, tipo_obsID.Value, (int)Tablas.TR_Ec_Obl);
            }

            return ObligacionRepository.Obtener((int)procedencia);
        }


        public Obligacion ObtenerObligacion(int obligacionID, bool getDetalle)
        {
            var obligacion = ObligacionRepository.ObtenerPorID(obligacionID);

            if (getDetalle)
            {
                obligacion.DetalleObligaciones = ObligacionRepository.ObtenerDetalle(obligacionID).ToList();
            }

            return obligacion;
        }

        public IEnumerable<Obligacion> ObtenerPorAlumno(string codAlu, string codRc)
        {
            IEnumerable<Obligacion> obligaciones;

            obligaciones = ObligacionRepository.ObtenerPorAlumno(codAlu, codRc);

            foreach (var item in obligaciones)
            {
                item.DetalleObligaciones = ObligacionRepository.ObtenerDetallePorAlumno(codAlu, codRc, item.I_RowID).ToList();
            }

            return obligaciones;
        }


        public byte[] ObtenerDatosObservaciones(Procedencia procedencia, int? tipo_obsID)
        {
            XLWorkbook excel_book = new XLWorkbook();
            MemoryStream result = new MemoryStream();

            tipo_obsID = tipo_obsID.HasValue ? tipo_obsID : 0;
            var data = ObligacionRepository.ObtenerReporteObservados((int)procedencia, tipo_obsID.Value, (int)Tablas.TR_Ec_Obl);

            var sheet = excel_book.Worksheets.Add(data, "Observaciones");
            sheet.ColumnsUsed().AdjustToContents();

            excel_book.SaveAs(result);

            return result.ToArray();
        }


        public Response CopiarRegistrosDesdeTemporalPagos(Procedencia procedencia, int? anioIni, int? anioFin)
        {
            Response result = new Response();
            Response result_Cabecera = new Response();
            Response result_Detalle = new Response();
            ObligacionRepository obligacionRepository = new ObligacionRepository();

            string schemaDb = Schema.SetSchema(procedencia);

            result_Cabecera = obligacionRepository.CopiarRegistrosCabecera((int)procedencia, schemaDb, anioIni, anioFin);
            result_Detalle = obligacionRepository.CopiarRegistrosDetalle((int)procedencia, schemaDb, anioIni, anioFin);

            if (result_Cabecera.IsDone && result_Detalle.IsDone)
            {
                result.IsDone = true;
                result.Success(false);
            }
            else
            {
                result.IsDone = false;
                result.Error(false);
            }

            result.Message = $"    <dl class=\"row text-justify\">" +
                             $"        <dt class=\"col-md-4 col-sm-6\">Cabecera de Obligaciones</dt>" +
                             $"        <dd class=\"col-md-8 col-sm-6\">" +
                             $"            <p>{result_Cabecera.Message}</p>" +
                             $"        </dd>" +
                             $"        <dt class=\"col-md-4 col-sm-6\">Detalle de Obligaciones </dt>" +
                             $"        <dd class=\"col-md-8 col-sm-6\">" +
                             $"            <p>{result_Detalle.Message}</p>" +
                             $"        </dd>" +
                             $"    </dl>";


            return result;
        }


        public Response EjecutarValidaciones(Procedencia procedencia)
        {
            Response result = new Response();
            ObligacionRepository obligacionRepository = new ObligacionRepository();
            _ = Schema.SetSchema(procedencia);
            _ = obligacionRepository.InicializarEstadoValidacionObligacionPago((int)procedencia);
            _ = obligacionRepository.InicializarEstadoValidacionDetalleObligacionPago((int)procedencia);

            Response result_Alumnos = obligacionRepository.ValidarAlumnoCabeceraObligacion((int)procedencia, null, null);
            Response result_Anio = obligacionRepository.ValidarAnioEnCabeceraObligacion((int)procedencia);
            Response result_Periodo = obligacionRepository.ValidarPeriodoEnCabeceraObligacion((int)procedencia);
            Response result_FecVencimiento = obligacionRepository.ValidarFechaVencimientoCuotaObligacion((int)procedencia);
            Response result_CuotaPagoMigrada = obligacionRepository.ValidarObligacionCuotaPagoMigrada((int)procedencia);
            Response result_Procedencia = obligacionRepository.ValidarProcedenciaObligacionCuotaPago((int)procedencia);
            Response result_Detalle = obligacionRepository.ValidarDetalleObligacion((int)procedencia);
            Response result_ConceptoPago = obligacionRepository.ValidarDetalleObligacionConceptoPago((int)procedencia);
            Response result_ConceptoPagoMigrado = obligacionRepository.ValidarDetalleObligacionConceptoPagoMigrado((int)procedencia);

            result.IsDone = result_Alumnos.IsDone &&
                            result_Anio.IsDone &&
                            result_Periodo.IsDone &&
                            result_FecVencimiento.IsDone &&
                            result_CuotaPagoMigrada.IsDone &&
                            result_Detalle.IsDone &&
                            result_ConceptoPago.IsDone &&
                            result_ConceptoPagoMigrado.IsDone;

            result.Message = $"    <dl class=\"row text-justify\">" +
                             $"        <dt class=\"col-md-4 col-sm-6\">Código de alumno no migrado</dt>" +
                             $"        <dd class=\"col-md-8 col-sm-6\">" +
                             $"            <p>{result_Alumnos.Message}</p>" +
                             $"        </dd>" +
                             $"        <dt class=\"col-md-4 col-sm-6\">Error en el año de la obligación</dt>" +
                             $"        <dd class=\"col-md-8 col-sm-6\">" +
                             $"            <p>{result_Anio.Message}</p>" +
                             $"        </dd>" +
                             $"        <dt class=\"col-md-4 col-sm-6\">Error en el periodo de la obligación</dt>" +
                             $"        <dd class=\"col-md-8 col-sm-6\">" +
                             $"            <p>{result_Periodo.Message}</p>" +
                             $"        </dd>" +
                             $"        <dt class=\"col-md-4 col-sm-6\">Observado por fecha de vencimiento</dt>" +
                             $"        <dd class=\"col-md-8 col-sm-6\">" +
                             $"            <p>{result_FecVencimiento.Message}</p>" +
                             $"        </dd>" +
                             $"        <dt class=\"col-md-4 col-sm-6\">Cuota de pago de migrada</dt>" +
                             $"        <dd class=\"col-md-8 col-sm-6\">" +
                             $"            <p>{result_CuotaPagoMigrada.Message}</p>" +
                             $"        </dd>" +
                             $"        <dt class=\"col-md-4 col-sm-6\">Obligación no migrada</dt>" +
                             $"        <dd class=\"col-md-8 col-sm-6\">" +
                             $"            <p>{result_Detalle.Message}</p>" +
                             $"        </dd>" +
                             $"        <dt class=\"col-md-4 col-sm-6\">Observaciones en el codigo de concepto</dt>" +
                             $"        <dd class=\"col-md-8 col-sm-6\">" +
                             $"            <p>{result_ConceptoPago.Message}</p>" +
                             $"        </dd>" +
                             $"        <dt class=\"col-md-4 col-sm-6\">Concepto de pago no migrado</dt>" +
                             $"        <dd class=\"col-md-8 col-sm-6\">" +
                             $"            <p>{result_ConceptoPagoMigrado.Message}</p>" +
                             $"        </dd>" +
                             $"    </dl>";


            return result.IsDone ? result.Success(false) : result.Error(false);
        }


        public Response MigrarDatosTemporalPagos(Procedencia procedencia)
        {
            Response result = new Response();
            Response result2 = new Response();
            string schemaDb = Schema.SetSchema(procedencia);

            ObligacionRepository obligacionRepository = new ObligacionRepository();

            for (int anio = 2005; anio < 2023; anio++)
            {
                result = obligacionRepository.MigrarDataObligacionesCtasPorCobrar((int)procedencia, null, anio, anio);
                result2 = obligacionRepository.MigrarDataPagoObligacionesCtasPorCobrar((int)procedencia, null, anio, anio);

                result.Message += "\r\n" + result2.Message;
            }

            return result.IsDone ? result.Success(false) : result.Error(false);
        }

    }
}