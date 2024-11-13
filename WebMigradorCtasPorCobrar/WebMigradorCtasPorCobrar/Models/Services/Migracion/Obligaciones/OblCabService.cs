using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using WebMigradorCtasPorCobrar.Models.Repository.Migracion.Obligaciones;

namespace WebMigradorCtasPorCobrar.Models.Services.Migracion.Obligaciones
{
    public class OblCabService
    {
        private readonly ObligacionRepository _obligacionRepository;

        public OblCabService() { 
            _obligacionRepository = new ObligacionRepository();
        }

        #region -- copia y equivalencias ---
            
        #endregion
        

        #region -- Valiodaciones --

        private Response ValidarExisteCodigoAlumno (int procedencia, string anio){
            return new Response();
        }

        private Response ValidarExisteCodigoAlumno (int ObligacionId){
            return new Response();
        }


        private Response ValidarAnio (int procedencia, string anio){
            return new Response();
        }

        private Response ValidarAnio (int ObligacionId){
            return new Response();
        }


        private Response ValidarPeriodo (int procedencia, string anio){
            return new Response();
        }

        private Response ValidarPeriodo (int ObligacionId){
            return new Response();
        }


        private Response ValidarFechaVencimiento (int procedencia, string anio){
            return new Response();
        }

        private Response ValidarFechaVencimiento (int ObligacionId){
            return new Response();
        }


        private Response ValidarExisteConOtroMontoEnCtasxCobrar (int procedencia, string anio){
            return new Response();
        }

        private Response ValidarExisteConOtroMontoEnCtasxCobrar (int ObligacionId){
            return new Response();
        }


        private Response ValidarCuotaPagoDeObligacionMigrada (int procedencia, string anio){
            return new Response();
        }

        private Response ValidarCuotaPagoDeObligacionMigrada (int ObligacionId){
            return new Response();
        }


        private Response ValidarProcedenciaObligProcecedenciaCuotaPago (int procedencia, string anio){
            return new Response();
        }

        private Response ValidarProcedenciaObligProcecedenciaCuotaPago (int ObligacionId){
            return new Response();
        }


        private Response ValidarObligacionTieneConceptosMigrados (int procedencia, string anio){
            return new Response();
        }

        private Response ValidarObligacionTieneConceptosMigrados (int ObligacionId){
            return new Response();
        }


        private Response ValidarSinObservacionesEnDetalle (int procedencia, string anio){
            return new Response();
        }

        private Response ValidarSinObservacionesEnDetalle (int ObligacionId){
            return new Response();
        }


        private Response ValidarTieneDetallesAsociados (int procedencia, string anio){
            return new Response();
        }

        private Response ValidarTieneDetallesAsociados (int ObligacionId){
            return new Response();
        }


        private Response ValidarNoPagadoConRegistroPago (int procedencia, string anio){
            return new Response();
        }

        private Response ValidarNoPagadoConRegistroPago (int ObligacionId){
            return new Response();
        }


        private Response ValidarCabeceraOligacionRepetida(int procedencia, string anio){
            return new Response();
        }

        private Response ValidarCabeceraOligacionRepetida (int ObligacionId){
            return new Response();
        }


        private Response ValidarPagodoTieneRegistroPago (int procedencia, string anio){
            return new Response();
        }

        private Response ValidarPagodoTieneRegistroPago (int ObligacionId){
            return new Response();
        }


        private Response ValidarMigracionDatosMatricula (int procedencia, string anio){
            return new Response();
        }

        private Response ValidarMigracionDatosMatricula (int ObligacionId){
            return new Response();
        }


        #endregion
    }
}