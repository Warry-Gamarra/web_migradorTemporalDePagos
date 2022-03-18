using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace WebMigradorCtasPorCobrar.Models.Entities
{
    public class DetalleObligacionTP
    {
        public int COD_ALU { get; set; }
        public int COD_RC { get; set; }
        public int CUOTA_PAGO { get; set; }
        public int ANO { get; set; }
        public int P { get; set; }
        public int TIPO_OBLIG { get; set; }
        public int CONCEPTO { get; set; }
        public int FCH_VENC { get; set; }
        public int NRO_RECIBO { get; set; }
        public int FCH_PAGO { get; set; }
        public int ID_LUG_PAG { get; set; }
        public int CANTIDAD { get; set; }
        public int MONTO { get; set; }
        public int PAGADO { get; set; }
        public int CONCEPTO_F { get; set; }
        public int FCH_ELIMIN { get; set; }
        public int NRO_EC { get; set; }
        public int FCH_EC { get; set; }
        public int ELIMINADO { get; set; }
        public int PAG_DEMAS { get; set; }
        public int COD_CAJERO { get; set; }
        public int TIPO_PAGO { get; set; }
        public int NO_BANCO { get; set; }
        public int COD_DEP { get; set; }
    }

    public class DetalleObligacionMG
    {
        public int I_RowID { get; set; }
        public int COD_ALU { get; set; }
        public int COD_RC { get; set; }
        public int CUOTA_PAGO { get; set; }
        public int ANO { get; set; }
        public int P { get; set; }
        public int TIPO_OBLIG { get; set; }
        public int CONCEPTO { get; set; }
        public int FCH_VENC { get; set; }
        public int NRO_RECIBO { get; set; }
        public int FCH_PAGO { get; set; }
        public int ID_LUG_PAG { get; set; }
        public int CANTIDAD { get; set; }
        public int MONTO { get; set; }
        public int PAGADO { get; set; }
        public int CONCEPTO_F { get; set; }
        public int FCH_ELIMIN { get; set; }
        public int NRO_EC { get; set; }
        public int FCH_EC { get; set; }
        public int ELIMINADO { get; set; }
        public int PAG_DEMAS { get; set; }
        public int COD_CAJERO { get; set; }
        public int TIPO_PAGO { get; set; }
        public int NO_BANCO { get; set; }
        public int COD_DEP { get; set; }
        public int D_FecCarga { get; set; }
        public int B_Actualizado { get; set; }
        public int D_FecActualiza { get; set; }
        public int B_Migrable { get; set; }
        public int D_FecEvalua { get; set; }
        public int B_Migrado { get; set; }
        public int D_FecMigrado { get; set; }
        public int B_Removido { get; set; }
        public int D_FecRemovido { get; set; }
    }

}