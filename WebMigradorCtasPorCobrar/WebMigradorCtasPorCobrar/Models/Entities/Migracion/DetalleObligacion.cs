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
        public int Cuota_pago { get; set; }
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

        public string Descripcio { get; set; }

        public DetalleObligacion()
        {

        }

        public DetalleObligacion(TemporalPagos.DetalleObligacion detalleObligacion)
        {
            this.Cod_alu = detalleObligacion.Cod_alu;
            this.Cod_rc = detalleObligacion.Cod_rc;
            this.Cuota_pago = detalleObligacion.Cuota_pago;
            this.Ano = detalleObligacion.Ano;
            this.P = detalleObligacion.P;
            this.Tipo_oblig = detalleObligacion.Tipo_oblig;
            this.Concepto = detalleObligacion.Concepto;
            this.Fch_venc = detalleObligacion.Fch_venc;
            this.Nro_recibo = detalleObligacion.Nro_recibo;
            this.Fch_pago = detalleObligacion.Fch_pago;
            this.Id_lug_pag = detalleObligacion.Id_lug_pag;
            this.Cantidad = detalleObligacion.Cantidad;
            this.Monto = detalleObligacion.Monto;
            this.Pagado = detalleObligacion.Pagado;
            this.Concepto_f = detalleObligacion.Concepto_f;
            this.Fch_elimin = detalleObligacion.Fch_elimin;
            this.Nro_ec = detalleObligacion.Nro_ec;
            this.Fch_ec = detalleObligacion.Fch_ec;
            this.Eliminado = detalleObligacion.Eliminado;
            this.Pag_demas = detalleObligacion.Pag_demas;
            this.Cod_cajero = detalleObligacion.Cod_cajero;
            this.Tipo_pago = detalleObligacion.Tipo_pago;
            this.No_banco = detalleObligacion.No_banco;
            this.Cod_dep = detalleObligacion.Cod_dep;
            this.Descripcio = detalleObligacion.Descripcio;
        }
    }
}