using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace WebMigradorCtasPorCobrar.Models.Entities.CtasPorCobrar
{
    public class TR_ObligacionAluDet
    {
        public long I_ObligacionAluDetID {get; set;} 
        public int I_ObligacionAluID { get; set; }
        public int I_ConcPagID { get; set; }
        public decimal I_Monto { get; set; }
        public bool B_Pagado { get; set; }
        public DateTime D_FecVencto { get; set; }
        public int I_TipoDocumento { get; set; }
        public string T_DescDocumento { get; set; }
        public bool B_Habilitado { get; set; }
        public bool B_Eliminado { get; set; }
        public int I_UsuarioCre { get; set; }
        public DateTime D_FecCre { get; set; }
        public int I_UsuarioMod { get; set; }
        public DateTime D_FecMod { get; set; }
        public bool B_Mora { get; set; }
        public bool B_Migrado { get; set; }
        public int I_MigracionTablaID { get; set; }
        public int I_MigracionRowID { get; set; }
    }
}