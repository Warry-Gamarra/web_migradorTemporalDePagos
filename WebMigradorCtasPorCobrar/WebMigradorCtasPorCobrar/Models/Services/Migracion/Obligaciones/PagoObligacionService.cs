using System.Collections.Generic;
using WebMigradorCtasPorCobrar.Models.Helpers;
using WebMigradorCtasPorCobrar.Models.Repository.Migracion.Obligaciones;
using CrossRepo = WebMigradorCtasPorCobrar.Models.Repository.Migracion.Cross;
using WebMigradorCtasPorCobrar.Models.ViewModels;
using static WebMigradorCtasPorCobrar.Models.Helpers.Observaciones;

namespace WebMigradorCtasPorCobrar.Models.Services.Migracion.Obligaciones
{
    public class PagoObligacionService
    {

        public IEnumerable<Response> MigrarDatosTemporalPagosObligacionID(int obl_rowId)
        {
            List<Response> result = new List<Response>();
            ObligacionRepository obligacionRepository = new ObligacionRepository();
            PagoObligacionRepository pagoObligacionRepository = new PagoObligacionRepository();

            Response responseObl = obligacionRepository.MigrarDataObligacionesCtasPorCobrarPorObligacionID(obl_rowId);

            Response responsePago;
            if (responseObl.IsDone)
            {
                responsePago = pagoObligacionRepository.MigrarDataPagoObligacionesCtasPorCobrarPorObligacionID(obl_rowId);
            }
            else
            {
                responsePago = new Response() { IsDone = false, Message = "No se encontraron obligación migrada para la migración del pago" };
            }

            responseObl = responseObl.IsDone ? responseObl.Success(false) : responseObl.Error(false);
            responseObl.Action = "Migración de la obligación...";

            responsePago = responsePago.IsDone ? responsePago.Success(false) : responsePago.Error(false);
            responsePago.Action = "Migración del pago de la obligación...";

            result.Add(responseObl);
            result.Add(responsePago);

            return result;
        }

        public IEnumerable<ResponseObligacion> MigrarDatosPagoTemporalPagos(Procedencia procedencia, string anio)
        {

            int procedencia_id = (int)procedencia;
            List<ResponseObligacion> result = new List<ResponseObligacion>();

            if (!string.IsNullOrEmpty(anio))
            {
                result.Add(this.MigrarPagoObligacionAnio(procedencia_id, anio));
            }
            else
            {
                ResponseObligacion OblPago;
                foreach (var itemAnio in CrossRepo.ObligacionRepository.ObtenerAnios(procedencia_id))
                {
                    OblPago = this.MigrarPagoObligacionAnio(procedencia_id, itemAnio);
                    result.Add(OblPago);
                }
            }

            return result;
        }


        private ResponseObligacion MigrarPagoObligacionAnio (int procedencia_Id, string anio)
        {
            ResponseObligacion resultPagos = new ResponseObligacion();

            ObligacionRepository obligacionRepository = new ObligacionRepository();
            PagoObligacionRepository pagoObligacionRepository = new PagoObligacionRepository();

            resultPagos.Obligacion = obligacionRepository.MigrarDataObligacionesCtasPorCobrar(procedencia_Id, anio);

            if (!resultPagos.Obligacion.IsDone) return resultPagos;

            foreach (var obligacion in obligacionRepository.ObtenerMigrablesPorAnio(procedencia_Id, anio))
            {
                resultPagos.DetalleObligacion.Add(pagoObligacionRepository.MigrarDataPagoObligacionesCtasPorCobrarPorObligacionID(obligacion.I_RowID));
            }

            return resultPagos;
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
            PagoObligacionRepository pagoObligacionRepository = new PagoObligacionRepository();

            _ = pagoObligacionRepository.InicializarEstadoValidacion(procedencia_id, anio);

            result.Add(ValidarObligacionIdEnPagoObligacion(procedencia_id, anio));
            result.Add(ValidarDetallesEnPagoObligacion(procedencia_id, anio));
            result.Add(ValidarCabObligacionObservada(procedencia_id, anio));


            return result;

        }

        private Response ValidarObligacionIdEnPagoObligacion(int procedencia, string anio)
        {
            PagoObligacionRepository pagoObligacionRepository = new PagoObligacionRepository();
            Response result = pagoObligacionRepository.ValidarObligacionIdEnPagoObligacion(procedencia, anio);

            result.ReturnViewValidationsMessage($"Año {anio} - Observado por id de obligacion en pago",
                                                (int)PagoObligacionObs.SinObligacionId,
                                                "Obligaciones", "EjecutarValidacion");

            return result;
        }


        private Response ValidarDetallesEnPagoObligacion(int procedencia, string anio)
        {
            PagoObligacionRepository pagoObligacionRepository = new PagoObligacionRepository();
            Response result = pagoObligacionRepository.ValidarDetallesEnPagoObligacion(procedencia, anio);

            result.ReturnViewValidationsMessage($"Año {anio} - Observado por error en detalle",
                                                (int)PagoObligacionObs.ErrorDetalleOblig,
                                                "Obligaciones", "EjecutarValidacion");

            return result;
        }

        private Response ValidarCabObligacionObservada(int procedencia, string anio)
        {
            PagoObligacionRepository pagoObligacionRepository = new PagoObligacionRepository();
            Response result = pagoObligacionRepository.ValidarCabObligacionObservada(procedencia, anio);

            result.ReturnViewValidationsMessage($"Año {anio} - Observado por error en cabecera de obligación",
                                                (int)PagoObligacionObs.ErrorEnCabObligacion,
                                                "Obligaciones", "EjecutarValidacion");

            return result;
        }


    }
}