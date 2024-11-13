using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

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

            result.ReturnViewValidationsMessage()
            return result;
        }

        private Response ValidarMontoPagadoIgualTotalMontoPagado (int ObligacionId){
            Response result = new Response();

            return result;
        }


        private Response ValidarExisteEnDestinoConOtroBanco (int procedencia, string anio){
            Response result = new Response();

            return result;
        }

        private Response ValidarExisteEnDestinoConOtroBanco (int ObligacionId){
            Response result = new Response();

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