using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using WebMigradorCtasPorCobrar.Models.Entities.Migracion;
using WebMigradorCtasPorCobrar.Models.Helpers;
using WebMigradorCtasPorCobrar.Models.Repository.Migracion.Cross;
using Obligacion = WebMigradorCtasPorCobrar.Models.Repository.Migracion.Obligaciones;
using WebMigradorCtasPorCobrar.Models.ViewModels;
using static WebMigradorCtasPorCobrar.Models.Helpers.Observaciones;

namespace WebMigradorCtasPorCobrar.Models.Services.Migracion.Cross
{
    public class ObligacionDetalleService
    {
        public DetalleObligacion ObtenerDatosDetalle(int detOblID)
        {
            return DetalleObligacionRepository.ObtenerDatosDetalle(detOblID);
        }

        public IEnumerable<DetalleObligacion> ObtenerDetalleObligacion(int obligID)
        {
            return DetalleObligacionRepository.Obtener(obligID);
        }

        public Response EjecutarValidacionesDetalleObligacion(Procedencia procedencia, int obligacionID)
        {
            Response result = new Response();
            Obligacion.DetalleObligacionRepository detalleObligacionRepository = new Obligacion.DetalleObligacionRepository();

            _ = Schema.SetSchema(procedencia);
            _ = detalleObligacionRepository.InicializarEstadoValidacionDetalleObligacionPago((int)procedencia, obligacionID);

            Response result_Detalle = detalleObligacionRepository.ValidarDetalleObligacion((int)procedencia);
            Response result_ConceptoPagoMigrado = detalleObligacionRepository.ValidarDetalleObligacionConceptoPagoMigrado((int)procedencia);
            Response result_ConceptoPago = detalleObligacionRepository.ValidarDetalleObligacionConceptoPago((int)procedencia);

            result.IsDone = result_Detalle.IsDone && result_ConceptoPagoMigrado.IsDone;

            result.Message = $"    <dl class=\"row text-justify\">" +
                             $"        <dt class=\"col-md-4 col-sm-6\">Obligación no migrada</dt>" +
                             $"        <dd class=\"col-md-8 col-sm-6\">" +
                             $"            <p>{result_Detalle.Message}</p>" +
                             $"        </dd>" +
                             $"        <dt class=\"col-md-4 col-sm-6\">Concepto de pago no migrado</dt>" +
                             $"        <dd class=\"col-md-8 col-sm-6\">" +
                             $"            <p>{result_ConceptoPagoMigrado.Message}</p>" +
                             $"        </dd>" +
                             $"        <dt class=\"col-md-4 col-sm-6\">Observaciones en el codigo de concepto</dt>" +
                             $"        <dd class=\"col-md-8 col-sm-6\">" +
                             $"            <p>{result_ConceptoPago.Message}</p>" +
                             $"        </dd>" +
                             $"    </dl>";

            return result.IsDone ? result.Success(false) : result.Error(false);
        }


        public Response Save(DetalleObligacion detalleObligacion, int tipoObserv)
        {
            Response result = new Response();
            Obligacion.DetalleObligacionRepository detalleObligacionRepository = new Obligacion.DetalleObligacionRepository();

            detalleObligacionRepository.InicializarEstadoValidacionDetalleObligacionPago(detalleObligacion.I_RowID, detalleObligacion.I_ProcedenciaID);

            switch ((DetalleObligacionObs)tipoObserv)
            {
                case DetalleObligacionObs.AnioConceptoNoCoincide:
                    result = detalleObligacionRepository.SaveAnioObligacion(detalleObligacion);
                    break;
                case DetalleObligacionObs.ConceptoNoExiste:
                    result = detalleObligacionRepository.SaveConceptoPagoObligacion(detalleObligacion);
                    break;
                case DetalleObligacionObs.CuotaConceptoNoCoincide:
                    result = detalleObligacionRepository.SaveCuotaPagoObligacion(detalleObligacion);
                    break;
                case DetalleObligacionObs.PeriodoConceptoNoCoincide:
                    result = detalleObligacionRepository.SavePeriodoObligacion(detalleObligacion);
                    break;
                case DetalleObligacionObs.ProcedenciaNoCoincide:
                    result = detalleObligacionRepository.SaveProcedenciaObligacion(detalleObligacion);
                    break;
                case DetalleObligacionObs.SinConceptoMigrado:
                    result = detalleObligacionRepository.SaveConceptoPagoObligacion(detalleObligacion);
                    break;
            }

            detalleObligacionRepository.ValidarDetalleObligacion(detalleObligacion.I_ProcedenciaID);
            detalleObligacionRepository.ValidarDetalleObligacionConceptoPagoMigrado(detalleObligacion.I_ProcedenciaID);

            return result.IsDone ? result.Success(false) : result.Error(false);
        }
    }
}