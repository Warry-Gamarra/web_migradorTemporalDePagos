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
    public class TC_Concepto
    {
        public int I_ConceptoID { get; set; }
        public string T_ConceptoDesc { get; set; }
        public string T_Clasificador { get; set; }
        public string T_ClasifCorto { get; set; }
        public bool B_EsObligacion { get; set; }
        public bool B_EsPagoMatricula { get; set; }
        public bool B_EsPagoExtmp { get; set; }
        public bool? B_Fraccionable { get; set; }
        public bool? B_ConceptoGeneral { get; set; }
        public bool? B_AgrupaConcepto { get; set; }
        public int? I_TipoObligacion { get; set; }
        public bool B_Calculado { get; set; }
        public int I_Calculado { get; set; }
        public bool? B_GrupoCodRc { get; set; }
        public int? I_GrupoCodRc { get; set; }
        public bool? B_ModalidadIngreso { get; set; }
        public int? I_ModalidadIngresoID { get; set; }
        public bool B_ConceptoAgrupa { get; set; }
        public int? I_ConceptoAgrupaID { get; set; }
        public byte? N_NroPagos { get; set; }
        public bool? B_Porcentaje { get; set; }
        public string C_Moneda { get; set; }
        public decimal I_Monto { get; set; }
        public decimal I_MontoMinimo { get; set; }
        public string T_DescripcionLarga { get; set; }
        public string T_Documento { get; set; }
        public bool? B_Mora { get; set; }
        public bool B_Habilitado { get; set; }
        public bool B_Eliminado { get; set; }
        public int? I_UsuarioCre { get; set; }
        public DateTime? D_FecCre { get; set; }
        public int? I_UsuarioMod { get; set; }
        public DateTime? D_FecMod { get; set; }

    }
}
