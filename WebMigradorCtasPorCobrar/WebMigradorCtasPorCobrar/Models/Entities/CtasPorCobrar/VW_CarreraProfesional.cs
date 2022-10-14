using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace WebMigradorCtasPorCobrar.Models.Entities.CtasPorCobrar
{
    public class VW_CarreraProfesional
    {
        public string C_RcCod { get; set; }
        public string C_CodEsp { get; set; }
        public string C_CodEsc { get; set; }
        public string C_CodFac { get; set; }
        public string T_EspDesc { get; set; }
        public string T_EscDesc { get; set; }
        public string T_FacDesc { get; set; }
        public string T_CarProfDesc { get; set; }
        public string C_Tipo { get; set; }
        public int I_Duracion { get; set; }
        public string B_Anual { get; set; }
        public string N_Grupo { get; set; }
        public string N_Grado { get; set; }
        public int I_IdAplica { get; set; }
    }
}