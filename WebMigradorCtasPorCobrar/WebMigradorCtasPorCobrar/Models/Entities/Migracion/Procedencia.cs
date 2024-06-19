using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace WebMigradorCtasPorCobrar.Models.Entities.Migracion
{
    public class Procedencia
    {
        public byte I_ProcedenciaID { get; set; }
        public string T_ProcedenciaDesc { get; set; }
    }

    public class CarreraProcedencia
    {
        public string C_RcCod { get; set; }
        public string T_CarreraNom { get; set; }
        public byte I_ProcedenciaID { get; set; }
    }
}