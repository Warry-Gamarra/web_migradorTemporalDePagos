using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using WebMigradorCtasPorCobrar.Models.Helpers;

namespace WebMigradorCtasPorCobrar.Models.Entities.Migracion
{
    public class DatosResultados
    {
        public string TablaOrigen { get; set; }
        public List<string> TablasDestino { get; set; }
        public Procedencia ProcedenciaData { get; set; }
        public DateTime FecProceso { get; set; }
        public int CantFilasOrigen { get; set; }
        public int CantFilasMigradas { get; set; }
        public int CantFilasObservadas { get; set; }
        public IList<Observacion> Observaciones { get; set; }
    }
}