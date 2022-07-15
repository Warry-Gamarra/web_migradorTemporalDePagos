using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace WebMigradorCtasPorCobrar.Models.Entities.TemporalPagos
{
    public class Alumno
    {
        public string C_RcCod { get; set; }
        public string C_CodAlu { get; set; }
        public string C_NumDNI { get; set; }
        public string C_CodTipDo { get; set; }
        public string T_ApePater { get; set; }
        public string T_ApeMater { get; set; }
        public string T_Nombre { get; set; }
        public string C_Sexo { get; set; }
        public string D_FecNac { get; set; }
        public string C_CodModIn { get; set; }
        public string C_AnioIngr { get; set; }
    }
}