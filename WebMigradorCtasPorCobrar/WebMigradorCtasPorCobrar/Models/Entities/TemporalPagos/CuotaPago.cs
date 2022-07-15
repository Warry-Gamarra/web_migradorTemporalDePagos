using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace WebMigradorCtasPorCobrar.Models.Entities.TemporalPagos
{
    public class CuotaPago
    {
        public int Cuota_pago { get; set; }
        public string Descripcio { get; set; }
        public string N_cta_cte { get; set; }
        public bool Eliminado { get; set; }
        public string Codigo_bnc { get; set; }
        public DateTime Fch_venc { get; set; }
        public string Prioridad { get; set; }
        public bool C_mora { get; set; }
    }
}