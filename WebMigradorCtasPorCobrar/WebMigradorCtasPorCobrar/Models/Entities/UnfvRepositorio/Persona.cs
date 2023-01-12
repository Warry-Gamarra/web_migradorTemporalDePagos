using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace WebMigradorCtasPorCobrar.Models.Entities.UnfvRepositorio
{
    public class Persona
    {
        public int I_PersonaID { get; set; }
        public string C_NumDNI { get; set; }
        public string C_CodTipDoc { get; set; }
        public string T_ApePaterno { get; set; }
        public string T_ApeMaterno { get; set; }
        public string T_Nombre { get; set; }
        public string T_NomCompleto { get; set; }
        public DateTime? D_FecNac { get; set; }
        public string C_Sexo { get; set; }
        public bool B_Habilitado { get; set; }
        public bool B_Eliminado { get; set; }
        public int? I_UsuarioCre { get; set; }
        public DateTime? D_FecCre { get; set; }
        public int? I_UsuarioMod { get; set; }
        public DateTime? D_FecMod { get; set; }

        public Persona()
        {
            this.T_NomCompleto = $"{T_ApePaterno} {T_ApeMaterno}, {T_Nombre}";
        }
    }
}