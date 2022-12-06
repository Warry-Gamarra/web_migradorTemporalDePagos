using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace WebMigradorCtasPorCobrar.Models.Helpers
{
    public class CtasPorCobrar
    {
        public enum Parametro
        {
            TipoAlumno = 1,
            Grado = 2,
            PeriodoAcademico = 5,
            CodigoIngreso = 7,
            MotivoMatricula = 8,
            CondicionPago = 9,
            TipoPago = 10
        }
    }
}