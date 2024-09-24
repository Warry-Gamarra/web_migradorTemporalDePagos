using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace WebMigradorCtasPorCobrar.Models.Entities.Migracion
{
    public class CuotaPago
    {
        public int I_RowID { get; set; }
        public int Cuota_pago { get; set; }
        public string Descripcio { get; set; }
        public string N_cta_cte { get; set; }
        public bool Eliminado { get; set; }
        public string Codigo_bnc { get; set; }
        public DateTime Fch_venc { get; set; }
        public string Fch_venc_s { get; set; } 
        public string Prioridad { get; set; }
        public bool C_mora { get; set; }
        public int I_Anio { get; set; }
        public int I_Periodo { get; set; }
        public string PeriodoDesc { get; set; }
        public int? I_CatPagoID { get; set; }
        public string CatPagoDesc { get; set; }
        public int I_ProcedenciaID { get; set; }
        public DateTime D_FecCarga { get; set; }
        public string B_Actualizado { get; set; }
        public DateTime D_FecActualiza { get; set; }
        public bool B_MantenerAnio { get; set; }
        public bool B_MantenerPeriodo { get; set; }
        public bool B_Migrable { get; set; }
        public DateTime D_FecEvalua { get; set; }
        public bool B_Migrado { get; set; }
        public DateTime D_FecMigrado { get; set; }
        public bool B_Removido { get; set; }
        public DateTime D_FecRemovido { get; set; }
        public IList<ConceptoPago> ConceptosPago { get; set; }
        public IList<Obligacion> Obligaciones { get; set; }
        public IList<DetalleObligacion> DetalleObligaciones { get; set; }
        public bool B_ExisteCtas { get; set; }
        public bool B_Correcto { get; set; }
        public int? I_CtaDepoProID { get; set; }
    }



}