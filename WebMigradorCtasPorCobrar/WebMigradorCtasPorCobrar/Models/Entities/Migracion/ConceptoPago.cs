using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace WebMigradorCtasPorCobrar.Models.Entities.Migracion
{
    public class ConceptoPago
    {
        public double I_RowID { get; set; }
        public double Id_cp { get; set; }
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
        public double Nro_pagos { get; set; }
        public double Id_cp_afec { get; set; }
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
        public DateTime D_FecRemovido { get; set; }
    }
}