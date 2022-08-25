using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace WebMigradorCtasPorCobrar.Models.Entities.Migracion
{
    public class Obligacion
    {
        public double I_RowID { get; set; }
        public string Ano { get; set; }
        public string P { get; set; }
        public string Cod_alu { get; set; }
        public string  Cod_RC { get; set; }
        public int Cuota_pago { get; set; }
        public bool Tipo_oblig { get; set; }
        public DateTime Fch_venc { get; set; }
        public decimal Monto { get; set; }
        public bool Pagado { get; set; }
        public DateTime D_FecCarga { get; set; }
        public string B_Actualizado { get; set; }
        public DateTime D_FecActualiza { get; set; }
        public bool B_Migrable { get; set; }
        public DateTime D_FecEvalua { get; set; }
        public bool B_Migrado { get; set; }
        public DateTime D_FecMigrado { get; set; }
        public bool B_Removido { get; set; }
        public DateTime D_FecRemovido { get; set; }
    }
}