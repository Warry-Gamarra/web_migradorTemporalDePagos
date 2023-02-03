using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using WebMigradorCtasPorCobrar.Models.Entities.CtasPorCobrar;
using WebMigradorCtasPorCobrar.Models.Helpers;
using WebMigradorCtasPorCobrar.Models.Repository.CtasPorCobrar;

namespace WebMigradorCtasPorCobrar.Models.Services.CtasPorCobrar
{
    public class ProcesoServices
    {
        public IEnumerable<VW_Proceso> Obtener(Procedencia procedencia)
        {
            return ProcesoRepositoty.Obtener((int)procedencia);
        }
    }
}