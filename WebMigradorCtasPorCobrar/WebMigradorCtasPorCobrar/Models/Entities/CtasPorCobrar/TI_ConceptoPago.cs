using System;
using System.Collections.Generic;
using System.Text;
using System.Threading.Tasks;

namespace WebMigradorCtasPorCobrar.Models.Entities.CtasPorCobrar
{
    public class TI_ConceptoPago
    {
        public int I_ConcPagID { get; set; }
        public int I_ProcesoID { get; set; }
        public int I_ConceptoID { get; set; }
        public string T_ConceptoPagoDesc { get; set; }
        public bool? B_Fraccionable { get; set; }
        public bool? B_ConceptoGeneral { get; set; }
        public bool? B_AgrupaConcepto { get; set; }
        public int? I_AlumnosDestino { get; set; }
        public int? I_GradoDestino { get; set; }
        public int? I_TipoObligacion { get; set; }
        public string T_Clasificador { get; set; }
        public string C_CodTasa { get; set; }
        public bool? B_Calculado { get; set; }
        public int? I_Calculado { get; set; }
        public bool? B_AnioPeriodo { get; set; }
        public int? I_Anio { get; set; }
        public int? I_Periodo { get; set; }
        public bool? B_Especialidad { get; set; }
        public char? C_CodRc { get; set; }
        public bool? B_Dependencia { get; set; }
        public int? C_DepCod { get; set; }
        public bool? B_GrupoCodRc { get; set; }
        public int? I_GrupoCodRc { get; set; }
        public bool? B_ModalidadIngreso { get; set; }
        public int? I_ModalidadIngresoID { get; set; }
        public bool? B_ConceptoAgrupa { get; set; }
        public int? I_ConceptoAgrupaID { get; set; }
        public bool? B_ConceptoAfecta { get; set; }
        public int? I_ConceptoAfectaID { get; set; }
        public int? N_NroPagos { get; set; }
        public bool? B_Porcentaje { get; set; }
        public decimal? M_Monto { get; set; }
        public decimal? M_MontoMinimo { get; set; }
        public string T_DescripcionLarga { get; set; }
        public string T_Documento { get; set; }
        public bool? B_Mora { get; set; }
        public bool? B_Habilitado { get; set; }
        public bool? B_Eliminado { get; set; }
        public int? I_UsuarioCre { get; set; }
        public DateTime? D_FecCre { get; set; }
        public int? I_UsuarioMod { get; set; }
        public DateTime? D_FecMod { get; set; }

    }
}
