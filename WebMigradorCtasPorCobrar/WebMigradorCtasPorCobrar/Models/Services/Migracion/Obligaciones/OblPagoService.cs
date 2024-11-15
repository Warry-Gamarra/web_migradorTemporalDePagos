using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using WebMigradorCtasPorCobrar.Models.Helpers;
using WebMigradorCtasPorCobrar.Models.Repository.Migracion.Obligaciones;
using WebMigradorCtasPorCobrar.Models.ViewModels;
using static WebMigradorCtasPorCobrar.Models.Helpers.Observaciones;

namespace WebMigradorCtasPorCobrar.Models.Services.Migracion.Obligaciones
{
    public class OblPagoService
    {
        private readonly PagoObligacionRepository _pagoObligacionRepository;

        public OblPagoService() 
        { 
            _pagoObligacionRepository = new PagoObligacionRepository();
        }

        #region -- copia y equivalencias ---
            
        #endregion


        #region -- Validaciones --

        private Response ValidarMontoPagadoIgualTotalMontoPagado (int procedencia, string anio){
            Response result = _pagoObligacionRepository.ValidarTotalMontoPagadoDetalle(procedencia, anio);

            _ = result.ReturnViewValidationsMessage(ObservacionPago.MONTO_PAGO_VS_DETALLE_PAGADO,
                                                    (int)PagoObligacionObs.MontoPagadoDetalle,
                                                    "Obligaciones",
                                                    "EjecutarValidacion");

            return result;
        }

        private Response ValidarMontoPagadoIgualTotalMontoPagado (int ObligacionId){
            Response result = _pagoObligacionRepository.ValidarTotalMontoPagadoDetallePorOblID(ObligacionId);

            _ = result.ReturnViewValidationsMessage(ObservacionPago.MONTO_PAGO_VS_DETALLE_PAGADO,
                                                    (int)PagoObligacionObs.MontoPagadoDetalle,
                                                    "Obligaciones",
                                                    "EjecutarValidacion");

            return result;
        }


        private Response ValidarExisteEnDestinoConOtroBanco (int procedencia, string anio){
            Response result = _pagoObligacionRepository.ValidarPagoExisteEnDestinoConOtroBanco(procedencia, anio);

            _ = result.ReturnViewValidationsMessage(ObservacionPago.PAGO_EXISTE_CTAS_OTRO_BNC,
                                                    (int)PagoObligacionObs.ExisteEnDestinoConOtroBanco,
                                                    "Obligaciones",
                                                    "EjecutarValidacion");

            return result;
        }

        private Response ValidarExisteEnDestinoConOtroBanco (int ObligacionId){
            Response result = _pagoObligacionRepository.ValidarPagoExisteEnDestinoConOtroBancoPorOblID(ObligacionId);

            _ = result.ReturnViewValidationsMessage(ObservacionPago.PAGO_EXISTE_CTAS_OTRO_BNC,
                                                    (int)PagoObligacionObs.ExisteEnDestinoConOtroBanco,
                                                    "Obligaciones",
                                                    "EjecutarValidacion");

            return result;
        }


        private Response ValidarDetalleOblgObservedo (int procedencia, string anio){
            Response result = new Response();

            return result;
        }

        private Response ValidarDetalleOblgObservedo (int ObligacionId){
            Response result = new Response();

            return result;
        }


        private Response ValidarCabeceraObligacionObservada (int procedencia, string anio){
            Response result = new Response();

            return result;
        }

        private Response ValidarCabeceraObligacionObservada (int ObligacionId){
            Response result = new Response();

            return result;
        }


        private Response ValidarMigracionCabeceraObligacion (int procedencia, string anio){
            Response result = new Response();

            return result;
        }

        private Response ValidarMigracionCabeceraObligacion (int ObligacionId){
            Response result = new Response();

            return result;
        }


        private Response ValidarMigracionDataPagoCtasxCobrar (int procedencia, string anio){
            Response result = new Response();

            return result;
        }

        private Response ValidarMigracionDataPagoCtasxCobrar (int ObligacionId){
            Response result = new Response();

            return result;
        }


        #endregion
    }
}