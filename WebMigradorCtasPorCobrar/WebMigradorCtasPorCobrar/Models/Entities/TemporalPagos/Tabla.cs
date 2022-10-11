using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using WebMigradorCtasPorCobrar.Models.Helpers;

namespace WebMigradorCtasPorCobrar.Models.Entities.TemporalPagos
{
    public class Tabla
    {
        public int I_TablaID { get; set; }
        public string T_Nombre { get; set; }
        public int I_CantFilas { get; set; }
        public int I_CantEliminados { get; set; }
        public DateTime D_FecArchivo { get; set; }
        public Procedencia I_Procedencia { get; set; }
        public bool B_Copiado { get; set; }
    }
}