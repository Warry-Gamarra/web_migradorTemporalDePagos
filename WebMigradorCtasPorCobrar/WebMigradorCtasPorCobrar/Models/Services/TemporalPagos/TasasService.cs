using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using WebMigradorCtasPorCobrar.Models.Entities.TemporalPagos;
using WebMigradorCtasPorCobrar.Models.Repository.TemporalPagos;

namespace WebMigradorCtasPorCobrar.Models.Services.TemporalPagos
{
    public class TasasService
    {
        public IEnumerable<Tasa_EcObl> ObtenerEcObl()
        {
            return TasasRepository.Obtener_EcObl();
        }

    }
}