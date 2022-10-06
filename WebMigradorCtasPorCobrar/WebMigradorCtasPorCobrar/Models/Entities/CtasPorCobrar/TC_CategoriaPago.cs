using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace WebMigradorCtasPorCobrar.Models.Entities.CtasPorCobrar
{
    public class TC_CategoriaPago
    {
        public int? I_CatPagoID { get; set; }
        public string T_CatPagoDesc { get; set; }
        public int I_Prioridad { get; set; }
        public string N_CodBanco { get; set; }
        public bool B_Habilitado { get; set; }
    }
}
