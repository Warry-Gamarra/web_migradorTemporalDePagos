using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace WebMigradorCtasPorCobrar.Models.Entities.UnfvRepositorio
{
    public class AlumnoPersona
    {
        public int I_PersonaID { get; set; }
        public string C_CodTipDoc { get; set; }
        public string T_TipDocDesc { get; set; }
        public string C_NumDNI { get; set; }
        public string T_ApePaterno { get; set; }
        public string T_ApeMaterno { get; set; }
        public string T_Nombre { get; set; }
        public string T_NomCompleto { get; }
        public DateTime? D_FecNac { get; set; }
        public string C_Sexo { get; set; }
        public string C_CodAlu { get; set; }
        public string C_RcCod { get; set; }
        public string C_CodEsp { get; set; }
        public string C_CodEsc { get; set; }
        public string T_EscDesc { get; set; }
        public string C_CodFac { get; set; }
        public string T_FacDesc { get; set; }
        public string C_CodProg { get; set; }
        public string T_DenomProg { get; set; }
        public string C_CodModIng { get; set; }
        public string T_ModIngDesc { get; set; }
        public string N_Grado { get; set; }
        public string T_GradoDesc { get; set; }
        public string N_Grupo { get; set; }
        public int? C_AnioIngreso { get; set; }
        public int? I_IdPlan { get; set; }
        public bool B_Habilitado { get; set; }
        public int? I_DependenciaID { get; set; }

        public AlumnoPersona()
        {
            this.T_NomCompleto = $"{T_ApePaterno} {T_ApeMaterno}, {T_Nombre}";
        }
    }
}