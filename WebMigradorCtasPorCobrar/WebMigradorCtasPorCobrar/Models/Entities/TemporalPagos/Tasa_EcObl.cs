using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace WebMigradorCtasPorCobrar.Models.Entities.TemporalPagos
{
    public class Tasa_EcObl
    {
        public string Ano { get; set; }
        public string P { get; set; }
        public string Cod_alu { get; set; }
        public string Cod_RC { get; set; }
        public int Cuota_pago { get; set; }
        public bool Tipo_oblig { get; set; }
        public DateTime Fch_venc { get; set; }
        public decimal Monto { get; set; }
        public bool Pagado { get; set; }

    }
}