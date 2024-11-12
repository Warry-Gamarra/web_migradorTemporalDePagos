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

        #region -- Validaciones --

        private Response ValidarMontoPagadoIgualTotalMontoPagado (int procedencia, string anio){
            return new Response();
        }

        private Response ValidarMontoPagadoIgualTotalMontoPagado (int ObligacionId){
            return new Response();
        }


        private Response ValidarExisteEnDestinoConOtroBanco (int procedencia, string anio){
            return new Response();
        }

        private Response ValidarExisteEnDestinoConOtroBanco (int ObligacionId){
            return new Response();
        }


        private Response ValidarDetalleOblgObservedo (int procedencia, string anio){
            return new Response();
        }

        private Response ValidarDetalleOblgObservedo (int ObligacionId){
            return new Response();
        }


        private Response ValidarCabeceraObligacionObservada (int procedencia, string anio){
            return new Response();
        }

        private Response ValidarCabeceraObligacionObservada (int ObligacionId){
            return new Response();
        }


        private Response ValidarMigracionCabeceraObligacion (int procedencia, string anio){
            return new Response();
        }

        private Response ValidarMigracionCabeceraObligacion (int ObligacionId){
            return new Response();
        }


        private Response ValidarMigracionDataPagoCtasxCobrar (int procedencia, string anio){
            return new Response();
        }

        private Response ValidarMigracionDataPagoCtasxCobrar (int ObligacionId){
            return new Response();
        }


        #endregion
    }
}