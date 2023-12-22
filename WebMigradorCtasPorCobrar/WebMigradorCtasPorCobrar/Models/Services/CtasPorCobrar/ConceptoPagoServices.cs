using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using WebMigradorCtasPorCobrar.Models.Entities.CtasPorCobrar;
using WebMigradorCtasPorCobrar.Models.Helpers;
using WebMigradorCtasPorCobrar.Models.Repository.CtasPorCobrar;

namespace WebMigradorCtasPorCobrar.Models.Services.CtasPorCobrar
{
    public class ConceptoPagoServices
    {
        public IEnumerable<TI_ConceptoPago> Obtener(Procedencia procedencia)
        {
            return ConceptoPagoRepository.Obtener((int)procedencia);
        }

        public TI_ConceptoPago Obtener(int conceptoPagoId)
        {
            return ConceptoPagoRepository.ObtenerPorID(conceptoPagoId);
        }

    }
}