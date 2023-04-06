using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace WebMigradorCtasPorCobrar.Models.Helpers
{
    public class AnioObligacion
    {
        public int Anio { get; set; }
        public int IsValid { get; set; }

    }

    public enum PeriodosValidacion
    {
        Anterior_hasta_2009 = 1,
        Del_2010_al_2015 = 2,
        Del_2016_al_2020 = 3
    }
}