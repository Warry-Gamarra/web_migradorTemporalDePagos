using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace WebMigradorCtasPorCobrar.Models.Entities
{
    public class ConceptoPago
    {
        public double I_RowID { get; set; }
        public double ID_CP { get; set; }
        public int CUOTA_PAGO { get; set; }
        public string ANO { get; set; }
        public string P { get; set; }
        public string COD_RC { get; set; }
        public string COD_ING { get; set; }
        public string TIPO_OBLIG { get; set; }
        public string CLASIFICAD { get; set; }
        public string CLASIFIC_5 { get; set; }
        public double ID_CP_AGRP { get; set; }
        public bool AGRUPA { get; set; }
        public double NRO_PAGOS { get; set; }
        public double ID_CP_AFEC { get; set; }
        public bool PORCENTAJE { get; set; }
        public decimal MONTO { get; set; }
        public bool ELIMINADO { get; set; }
        public string DESCRIPCIO { get; set; }
        public string CALCULAR { get; set; }
        public int GRADO { get; set; }
        public int TIP_ALUMNO { get; set; }
        public string GRUPO_RC { get; set; }
        public bool FRACCIONAB { get; set; }
        public bool CONCEPTO_G { get; set; }
        public string DOCUMENTO  { get; set; }
        public decimal MONTO_MIN  { get; set; }
        public string DESCRIP_L { get; set; }
        public string COD_DEP_PL  { get; set; }
        public bool OBLIG_MORA { get; set; }

    }
}