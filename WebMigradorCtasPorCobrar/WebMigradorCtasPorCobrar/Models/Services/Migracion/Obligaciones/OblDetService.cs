using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace WebMigradorCtasPorCobrar.Models.Services.Migracion.Obligaciones
{
    public class OblDetService
    {
        private readonly ObligacionRepository _obligacionRepository;

        public OblDetService()
        {
            _obligacionRepository = new ObligacionRepository();
        }


        #region --Validaciones --

        private Response ValidarAnioIgualAnioConcepto (int procedencia, string anio){
            return new Response();
        }

        private Response ValidarAnioIgualAnioConcepto (int ObligacionId){
            return new Response();
        }

        
        private Response ValidarPeriodoIgualPeriodoConcepto (int procedencia, string anio){
            return new Response();
        }

        private Response ValidarPeriodoIgualPeriodoConcepto (int ObligacionId){
            return new Response();
        }


        private Response ValidarTieneConceptoPagoMigrado (int procedencia, string anio){
            return new Response();
        }

        private Response ValidarTieneConceptoPagoMigrado (int ObligacionId){
            return new Response();
        }

             
        private Response ValidarConceptoExisteEnCatalogo (int procedencia, string anio){
            return new Response();
        }

        private Response ValidarConceptoExisteEnCatalogo (int ObligacionId){
            return new Response();
        }


        private Response ValidarCuotaPagoIgualCuotaPagoConcepto (int procedencia, string anio){
            return new Response();
        }

        private Response ValidarCuotaPagoIgualCuotaPagoConcepto (int ObligacionId){
            return new Response();
        }


        private Response ValidarAnioEsUnNumero (int procedencia, string anio){
            return new Response();
        }

        private Response ValidarAnioEsUnNumero (int ObligacionId){
            return new Response();
        }


        private Response ValidarPeriodoExisteCatologoCtas (int procedencia, string anio){
            return new Response();
        }

        private Response ValidarPeriodoExisteCatologoCtas (int ObligacionId){
            return new Response();
        }

  
        private Response ValidarTotalMontoIgualMontoCabecera (int procedencia, string anio){
            return new Response();
        }

        private Response ValidarTotalMontoIgualMontoCabecera (int ObligacionId){
            return new Response();
        }

  
        private Response ValidarMigracionCabecera (int procedencia, string anio){
            return new Response();
        }

        private Response ValidarMigracionCabecera (int ObligacionId){
            return new Response();
        }

            
        #endregion
    }
}