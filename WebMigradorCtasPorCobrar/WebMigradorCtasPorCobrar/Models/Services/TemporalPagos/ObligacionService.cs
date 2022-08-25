using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using WebMigradorCtasPorCobrar.Models.Entities.TemporalPagos;
using WebMigradorCtasPorCobrar.Models.Helpers;
using WebMigradorCtasPorCobrar.Models.Repository.TemporalPagos;

namespace WebMigradorCtasPorCobrar.Models.Services.TemporalPagos
{
    public class ObligacionService
    {
        public IEnumerable<Obligacion> ObtenerObligaciones(Procedencia procedencia)
        {
            string schemaDb = Schema.SetSchema(procedencia);

            return ObligacionRepository.Obtener(schemaDb);
        }
    }
}