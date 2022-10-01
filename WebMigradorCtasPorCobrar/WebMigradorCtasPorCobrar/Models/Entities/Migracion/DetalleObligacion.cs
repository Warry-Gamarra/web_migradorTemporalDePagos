using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace WebMigradorCtasPorCobrar.Models.Entities.Migracion
{
    public class DetalleObligacion
    {
        public int I_RowID { get; set; }
        public string Cod_alu { get; set; }
        public string Cod_rc { get; set; }
        public string Cuota_pago { get; set; }
        public string Ano { get; set; }
        public string P { get; set; }
        public bool Tipo_oblig { get; set; }
        public int Concepto { get; set; }
        public DateTime Fch_venc { get; set; }
        public string Nro_recibo { get; set; }
        public DateTime Fch_pago { get; set; }
        public string Id_lug_pag { get; set; }
        public decimal Cantidad { get; set; }
        public decimal Monto { get; set; }
        public bool Pagado { get; set; }
        public bool Concepto_f { get; set; }
        public DateTime Fch_elimin { get; set; }
        public int Nro_ec { get; set; }
        public DateTime Fch_ec { get; set; }
        public bool Eliminado { get; set; }
        public bool Pag_demas { get; set; }
        public string Cod_cajero { get; set; }
        public bool Tipo_pago { get; set; }
        public bool No_banco { get; set; }
        public string Cod_dep { get; set; }
        public DateTime D_FecCarga { get; set; }
        public bool B_Actualizado { get; set; }
        public DateTime D_FecActualiza { get; set; }
        public bool B_Migrable { get; set; }
        public DateTime D_FecEvalua { get; set; }
        public bool B_Migrado { get; set; }
        public DateTime D_FecMigrado { get; set; }
        public bool B_Removido { get; set; }
        public DateTime D_FecRemovido { get; set; }
    }
}