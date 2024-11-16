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
            SinAnioIngreso = 22,
            SinCarrera = 21,
            SinModIng = 23,
            DniRepetido = 30,
            SexoErrado = 31,
            DniExiste = 41,
            Removido = 45,
            SexoDifente = 47,
            DniDiferente = 48
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
            Removido = 45,
            RepetidoDifProc = 50
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
            Externo = 20,
            NoObligacion = 46,
            Removido = 45,
        }

        public enum ObligacionesPagoObs
        {
            SinAlumno = 24,
            AnioNoValido = 26,
            SinPeriodo = 27,
            FchVencCuotaPago = 28,
            ExisteConOtroMonto = 29,
            SinCuotaPagoMigrable= 32,
            ProcedenciaNoCoincide = 34,
            SinConceptoMigrable = 36,
            ObsAnioDetalle =37,
            ObsPeriodoDetalle =38,
            ObsConceptoDetalle =39,
            SinDetalle =40,
            Removido = 45,
            PagoEnObligacionNoPagado = 54,
            ObligacionRepetida = 59,
            SinPagoEnObligacioPagada = 60,
            MigracionMatricula = 61
        }

        public enum DetalleObligacionObs
        {
            AnioDetalleConcepto = 15,
            PeriodoDetalleConcepto = 17,
            SinObligacionMigrable= 25,
            SinConceptoMigrado = 33,
            ConceptoNoExiste = 35,
            CuotaConceptoNoCoincide = 42,
            AnioNoValido = 43,
            PeriodoSinEquivalenciaDtas = 44,
            Removido = 45,
            MontoDetalleMontoCab = 49,
            SinObligacionCabID = 58,
            MigracionCabecera = 62
        }

        public enum PagoObligacionObs
        {
            SinObligacionId = 52,
            MontoPagadoDetalle = 53,
            ExisteEnDestinoConOtroBanco = 55,
            DetalleObservado = 56,
            CabObligacionObservada = 57,
            MigracionCabecera = 63
        }

    }
}