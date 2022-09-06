using System;
using System.Collections.Generic;
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
        public IEnumerable<Obligacion> ObtenerObligaciones(Procedencia procedencia)
        {
            return ObligacionRepository.Obtener((int) procedencia);
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

            Response result_InicializarEstadosCabecera = new Response();
            Response result_InicializarEstadosDetalle = new Response();
            Response result_Alumnos = new Response();
            Response result_Anio = new Response();
            Response result_Periodo = new Response();
            Response result_FecVencimiento = new Response();
            Response result_CuotaPagoMigrada = new Response();
            Response result_Procedencia = new Response();
            Response result_Detalle = new Response();
            Response result_ConceptoPago = new Response();
            Response result_ConceptoPagoMigrado = new Response();

            string schemaDb = Schema.SetSchema(procedencia);

            result_InicializarEstadosCabecera = obligacionRepository.InicializarEstadoValidacionObligacionPago((int)procedencia);
            result_InicializarEstadosDetalle = obligacionRepository.InicializarEstadoValidacionDetalleObligacionPago((int)procedencia);

            result_Alumnos = obligacionRepository.ValidarAlumnoCabeceraObligacion((int)procedencia, null, null);
            result_Anio = obligacionRepository.ValidarAnioEnCabeceraObligacion((int)procedencia);
            result_Periodo = obligacionRepository.ValidarPeriodoEnCabeceraObligacion((int)procedencia);
            result_FecVencimiento = obligacionRepository.ValidarFechaVencimientoCuotaObligacion((int)procedencia);
            result_CuotaPagoMigrada = obligacionRepository.ValidarObligacionCuotaPagoMigrada((int)procedencia);
            result_Procedencia = obligacionRepository.ValidarProcedenciaObligacionCuotaPago((int)procedencia);
            result_Detalle = obligacionRepository.ValidarDetalleObligacion((int)procedencia);
            result_ConceptoPago = obligacionRepository.ValidarDetalleObligacionConceptoPago((int)procedencia);
            result_ConceptoPagoMigrado = obligacionRepository.ValidarDetalleObligacionConceptoPagoMigrado((int)procedencia);

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


            if (result.IsDone)
            {
                result.Success(false);
            }
            else
            {
                result.Warning(false);
            }

            return result;
        }


        public Response MigrarDatosTemporalPagos(Procedencia procedencia)
        {
            Response result = new Response();
            Response result2 = new Response();
            string schemaDb = Schema.SetSchema(procedencia);

            ObligacionRepository obligacionRepository = new ObligacionRepository();

            for (int anio = 2005; anio < 2007; anio++)
            {
                result = obligacionRepository.MigrarDataObligacionesCtasPorCobrar((int)procedencia, null, anio, anio);
                result2 = obligacionRepository.MigrarDataPagoObligacionesCtasPorCobrar((int)procedencia, null, anio, anio);

                result.Message += "\r\n" + result2.Message;
            }


            if (result.IsDone && result2.IsDone)
            {
                result.Success(false);
            }
            else
            {
                result.Error(false);
            }

            return result;
        }
    }
}