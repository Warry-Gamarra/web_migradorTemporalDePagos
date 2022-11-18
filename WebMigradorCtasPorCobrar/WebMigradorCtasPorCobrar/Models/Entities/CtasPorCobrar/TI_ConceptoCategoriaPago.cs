using Dapper;
using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace WebMigradorCtasPorCobrar.Models.Entities.CtasPorCobrar
{
    public class TI_ConceptoCategoriaPago
    {
        public int? I_CatPagoID { get; set; }
        public int? I_ConceptoID { get; set; }
        public string T_CatPagoDesc { get; set; }
        public string T_ConceptoDesc { get; set; }
        public string T_Clasificador { get; set; }
        public decimal I_Monto { get; set; }
        public decimal I_MontoMinimo { get; set; }
   
    }
}
