using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using WebMigradorCtasPorCobrar.Models.Helpers;

namespace WebMigradorCtasPorCobrar.Models.Entities.Migracion
{
    public class HistorialResultados
    {
        public string T_TablaOrigen { get; set; }
        public int T_TablaOrigenID { get; set; }
        public EstadoMigracion I_Estado { get; set; }
        public string T_TablasDestino { get; set; }
        public List<string> TablasDestino { get; set; }
        public Procedencia I_Procedencia { get; set; }
        public DateTime D_FecCopia { get; set; }
        public DateTime D_FecValidacion { get; set; }
        public DateTime D_FecMigracion { get; set; }
        public int I_CantFilasOrigen { get; set; }
        public int I_CantFilasMigradas { get; set; }
        public int I_CantFilasObservadas { get; set; }
        public IList<Observacion> Observaciones { get; set; }
    }

    public enum EstadoMigracion {
        Copiado = 1,
        EnValidacion = 2,
        Migrado = 3
    }
}