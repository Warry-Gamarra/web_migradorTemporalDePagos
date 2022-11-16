using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace WebMigradorCtasPorCobrar.Models.Entities.Migracion
{
    public class Observacion
    {
        public int I_ObsTablaID { get; set; }
        public DateTime D_FecRegistro { get; set; }
        public int I_TablaID { get; set; }
        public string T_TablaNom { get; set; }
        public int I_ObservID { get; set; }
        public string T_ObservDesc { get; set; }
        public int I_FilaTablaID { get; set; }
        public string T_ObservCod { get; set; }
        public int I_Severidad { get; set; }
        public int I_ProcedenciaID { get; set; }
        public bool B_Resuelto { get; set; }
        public DateTime D_FecResuelto { get; set; }
    }
}