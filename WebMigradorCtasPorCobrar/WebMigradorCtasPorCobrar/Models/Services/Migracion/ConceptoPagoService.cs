using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using WebMigradorCtasPorCobrar.Models.Repository.Migracion;
using WebMigradorCtasPorCobrar.Models.Entities.Migracion;
using WebMigradorCtasPorCobrar.Models.Helpers;

namespace WebMigradorCtasPorCobrar.Models.Services.Migracion
{
    public class ConceptoPagoService
    {
        public IEnumerable<ConceptoPago> Obtener(Procedencia procedencia)
        {
            return ConceptoPagoRepository.Obtener((int)procedencia);
        }
    }
}