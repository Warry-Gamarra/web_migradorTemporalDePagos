using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using WebMigradorCtasPorCobrar.Models.Repository.TemporalPagos;
using WebMigradorCtasPorCobrar.Models.Entities.TemporalPagos;
using WebMigradorCtasPorCobrar.Models.Helpers;

namespace WebMigradorCtasPorCobrar.Models.Services.TemporalPagos
{
    public class ConceptoPagoService
    {
        public IEnumerable<ConceptoPago> Obtener(Procedencia procedencia)
        {
            string schemaDb = Schema.SetSchema(procedencia);

            return ConceptoPagoRepository.Obtener(schemaDb);
        }
    }
}