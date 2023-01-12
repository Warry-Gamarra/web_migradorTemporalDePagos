using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace WebMigradorCtasPorCobrar.Models.Entities.UnfvRepositorio
{
    public class Alumno
    {
        public int I_PersonaID { get; set; }
        public string C_RcCod { get; set; }
        public string C_CodAlu { get; set; }
        public string C_CodModIng { get; set; }
        public short? C_AnioIngreso { get; set; }
        public int? I_IdPlan { get; set; }
        public bool B_Habilitado { get; set; }
        public bool B_Eliminado { get; set; }
        public int I_UsuarioCre { get; set; }
        public DateTime D_FecCre { get; set; }
        public int I_UsuarioMod { get; set; }
        public DateTime D_FecMod { get; set; }
    }
}