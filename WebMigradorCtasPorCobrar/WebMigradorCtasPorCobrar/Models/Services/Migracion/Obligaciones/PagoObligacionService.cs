using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using WebMigradorCtasPorCobrar.Models.Helpers;
using WebMigradorCtasPorCobrar.Models.Repository.Migracion.Obligaciones;
using CrossRepo = WebMigradorCtasPorCobrar.Models.Repository.Migracion.Cross;
using WebMigradorCtasPorCobrar.Models.ViewModels;

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

            foreach (var obligacion in obligacionRepository.ObtenerMigrablesPorAnio(procedencia_Id, anio))
            {
                resultPagos.DetalleObligacion.Add(pagoObligacionRepository.MigrarDataPagoObligacionesCtasPorCobrarPorObligacionID(obligacion.I_RowID));
            }


            return resultPagos;
        }

    }
}