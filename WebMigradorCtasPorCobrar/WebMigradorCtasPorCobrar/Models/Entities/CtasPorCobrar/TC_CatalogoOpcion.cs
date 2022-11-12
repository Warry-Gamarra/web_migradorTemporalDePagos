using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace WebMigradorCtasPorCobrar.Models.Entities.CtasPorCobrar
{
    public class TC_CatalogoOpcion
    {
        public int I_OpcionID { get; set; }
        public int I_ParametroID { get; set; }
        public string T_OpcionCod { get; set; }
        public string T_OpcionDesc { get; set; }
        public string T_OpcionCodDesc { get; set; }
        public bool B_Habilitado { get; set; }
    }
}