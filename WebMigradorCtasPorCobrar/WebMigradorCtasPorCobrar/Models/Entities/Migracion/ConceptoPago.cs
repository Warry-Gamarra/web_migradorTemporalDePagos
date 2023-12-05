using System;
using System.Collections.Generic;
using Temporal = WebMigradorCtasPorCobrar.Models.Entities.TemporalPagos;
using System.Linq;
using System.Web;

namespace WebMigradorCtasPorCobrar.Models.Entities.Migracion
{
    public class ConceptoPago
    {
        public int I_RowID { get; set; }
        public int Id_cp { get; set; }
        public int Cuota_pago { get; set; }
        public string Ano { get; set; }
        public string P { get; set; }
        public string Cod_rc { get; set; }
        public string Cod_ing { get; set; }
        public bool Tipo_oblig { get; set; }
        public string Clasificad { get; set; }
        public string Clasific_5 { get; set; }
        public double Id_cp_agrp { get; set; }
        public bool Agrupa { get; set; }
        public int Nro_pagos { get; set; }
        public int Id_cp_afec { get; set; }
        public bool Porcentaje { get; set; }
        public decimal Monto { get; set; }
        public bool Eliminado { get; set; }
        public string Descripcio { get; set; }
        public string Calcular { get; set; }
        public int Grado { get; set; }
        public int Tip_alumno { get; set; }
        public string Grupo_rc { get; set; }
        public bool Fraccionable { get; set; }
        public bool Concepto_g { get; set; }
        public string Documento { get; set; }
        public decimal Monto_min { get; set; }
        public string Descrip_l { get; set; }
        public string Cod_dep_pl { get; set; }
        public bool Oblig_mora { get; set; }
        public DateTime D_FecCarga { get; set; }
        public string B_Actualizado { get; set; }
        public DateTime D_FecActualiza { get; set; }
        public bool B_Migrable { get; set; }
        public DateTime D_FecEvalua { get; set; }
        public bool B_Migrado { get; set; }
        public DateTime D_FecMigrado { get; set; }
        public bool B_Removido { get; set; }
        public bool B_Correcto { get; set; }
        public bool B_ExisteCtas { get; set; }
        public DateTime D_FecRemovido { get; set; }

        public int I_TipPerID { get; set; }
        public int I_TipAluID { get; set; }
        public int I_TipGradoID { get; set; }
        public int I_ProcedenciaID { get; set; }
        public IList<CuotaPago> CuotasPago { get; set; }
        public IList<DetalleObligacion> DetalleObligaciones { get; set; }

        public string Cuota_pago_desc { get; set; }

        public ConceptoPago()
        {

        }

        public ConceptoPago(TemporalPagos.ConceptoPago conceptoPago)
        {
            this.Id_cp = conceptoPago.Id_cp;
            this.Cuota_pago = conceptoPago.Cuota_pago;
            this.Ano = conceptoPago.Ano;
            this.P = conceptoPago.P;
            this.Cod_rc = conceptoPago.Cod_rc;
            this.Cod_ing = conceptoPago.Cod_ing;
            this.Tipo_oblig = conceptoPago.Tipo_oblig;
            this.Clasificad = conceptoPago.Clasificad;
            this.Clasific_5 = conceptoPago.Clasific_5;
            this.Id_cp_agrp = conceptoPago.Id_cp_agrp;
            this.Agrupa = conceptoPago.Agrupa;
            this.Nro_pagos = conceptoPago.Nro_pagos;
            this.Id_cp_afec = conceptoPago.Id_cp_afec;
            this.Porcentaje = conceptoPago.Porcentaje;
            this.Monto = conceptoPago.Monto;
            this.Eliminado = conceptoPago.Eliminado;
            this.Descripcio = conceptoPago.Descripcio;
            this.Calcular = conceptoPago.Calcular;
            this.Grado = conceptoPago.Grado;
            this.Tip_alumno = conceptoPago.Tip_alumno;
            this.Grupo_rc = conceptoPago.Grupo_rc;
            this.Fraccionable = conceptoPago.Fraccionable;
            this.Concepto_g = conceptoPago.Concepto_g;
            this.Documento = conceptoPago.Documento;
            this.Monto_min = conceptoPago.Monto_min;
            this.Descrip_l = conceptoPago.Descrip_l;
            this.Cod_dep_pl = conceptoPago.Cod_dep_pl;
            this.Oblig_mora = conceptoPago.Oblig_mora;
        }
    }
}