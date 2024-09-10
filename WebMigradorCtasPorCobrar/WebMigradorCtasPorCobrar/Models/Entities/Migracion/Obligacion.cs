using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace WebMigradorCtasPorCobrar.Models.Entities.Migracion
{
    public class Obligacion
    {
        public int I_RowID { get; set; }
        public string Ano { get; set; }
        public string P { get; set; }
        public int I_Periodo { get; set; }
        public string Cod_alu { get; set; }
        public string NomAlumno { get; set; }
        public string Cod_RC { get; set; }
        public string T_Carrera { get; set; }
        public int Cuota_pago { get; set; }
        public string Cuota_pago_desc { get; set; }
        public bool Tipo_oblig { get; set; }
        public DateTime Fch_venc { get; set; }
        public decimal Monto { get; set; }
        public bool Pagado { get; set; }
        public DateTime D_FecCarga { get; set; }
        public bool B_Actualizado { get; set; }
        public DateTime D_FecActualiza { get; set; }
        public bool B_Migrable { get; set; }
        public DateTime D_FecEvalua { get; set; }
        public bool B_Migrado { get; set; }
        public DateTime D_FecMigrado { get; set; }
        public bool B_Removido { get; set; }
        public DateTime D_FecRemovido { get; set; }
        public IList<DetalleObligacion> DetalleObligaciones { get; set; }
        public int I_ProcedenciaID { get; set; }
        public int? I_CtasMatTableRowID { get; set; }
        public int? I_CtasCabTableRowID { get; set; }
        public bool B_ExisteCtas { get; set; }


        public Obligacion() { }

        public Obligacion(IEnumerable<DetalleObligacion> detalle)
        {
            this.DetalleObligaciones = detalle.ToList();
        }


        public Obligacion(TemporalPagos.Obligacion obligacion)
        {
            this.Ano = obligacion.Ano;
            this.P = obligacion.P;
            this.Cod_alu = obligacion.Cod_alu;
            this.Cod_RC = obligacion.Cod_RC;
            this.Cuota_pago = obligacion.Cuota_pago;
            this.Cuota_pago_desc = obligacion.Descripcio;
            this.Tipo_oblig = obligacion.Tipo_oblig;
            this.Fch_venc = obligacion.Fch_venc;
            this.Monto = obligacion.Monto;
            this.Pagado = obligacion.Pagado;
        }
    }
}
