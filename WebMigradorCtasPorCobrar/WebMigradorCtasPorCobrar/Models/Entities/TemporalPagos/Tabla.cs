using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using WebMigradorCtasPorCobrar.Models.Helpers;

namespace WebMigradorCtasPorCobrar.Models.Entities.TemporalPagos
{
    public class Tabla
    {
        public string Nombre { get; set; }
        public int CantFilas { get; set; }
        public int CantEliminados { get; set; }
        public DateTime FecArchivo { get; set; }
        public Procedencia ProcedenciaData { get; set; }
        public string Condicion { get; set; }
    }
}