using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace WebMigradorCtasPorCobrar.Models.Helpers
{
    public class Observaciones
    {
        public enum AlumnoObs
        {

        }

        public enum CuotaPagoObs
        {
            Repetido = 3,
            Eliminado = 4,
            MasDeUnAnio = 5,
            SinAnio = 6,
            MasDeUnPeriodo = 7,
            SinPeriodo = 8,
            MásDeUnaCategoría = 9,
            SinCategoria = 10,
        }

        public enum ConceptoPagoObs
        {
            SinPeriodo = 1,
            SinAnio = 2
        }

        public enum ObligacionesPagoObs
        {
            SinPeriodo = 1,
            SinAnio = 2
        }

    }
}