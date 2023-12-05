using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace WebMigradorCtasPorCobrar.Models.Entities.CtasPorCobrar
{
    public class TR_ObligacionAluCab
    {
        public int I_ObligacionAluID { get; set; }
        public int I_ProcesoID { get; set; }
        public int I_MatAluID { get; set; }
        public string C_Moneda { get; set; }
        public decimal I_MontoOblig { get; set; }
        public DateTime D_FecVencto { get; set; }
        public bool B_Pagado { get; set; }
        public bool B_Habilitado { get; set; }
        public bool B_Eliminado { get; set; }
        public int I_UsuarioCre { get; set; }
        public DateTime D_FecCre { get; set; }
        public int I_UsuarioMod { get; set; }
        public DateTime D_FecMod { get; set; }
        public bool B_Migrado { get; set; }
        public int I_MigracionTablaID { get; set; }
        public int I_MigracionRowID { get; set; }
    }
}