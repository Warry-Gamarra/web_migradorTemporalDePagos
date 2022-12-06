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
            Caracteres = 1,
            Repetido = 2,
            SinAnioIngres0 = 22,
            SinCarrera = 21,
            SinModIng = 23,
            DniRepetido = 30,
            SexoErrado = 31,
            DniExiste = 41
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
            Repetido = 12,
            SinAnio = 14,
            ErrorConAnioCuota = 15,
            SinPeriodo = 16,
            ErrorConPeriodoCuota = 17,
            SinCuotaPago = 18,
            SinCuotaMigrada = 19,
            Externo = 20
        }

        public enum ObligacionesPagoObs
        {
            SinAlumno = 24,
            AnioNoValido = 26,
            SinPeriodo = 27,
            FchVencRepetido = 28,
            ExisteConOtroMonto = 29,
            SinCuotaPagoMigrable= 32,
            SinConceptoMigrable = 36,
            ObsAnioDetalle =37,
            ObsPeriodoDetalle =38,
            ObsConceptoDetalle =38,
            SinDetalle =40
        }

        public enum DetalleObligacionObs
        {
            SinObligacionMigrada = 25,
            SinConceptoMigrado = 33,
            ProcedenciaNoCoincide = 34,
            ConceptoNoExiste = 35,
            CuotaConceptoNoCoincide = 42,
            AnioConceptoNoCoincide = 43,
            PeriodoConceptoNoCoincide = 44
        }

    }
}