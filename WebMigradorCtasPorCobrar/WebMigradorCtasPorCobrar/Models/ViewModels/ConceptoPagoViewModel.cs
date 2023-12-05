using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using WebMigradorCtasPorCobrar.Models.Entities.Migracion;
using WebMigradorCtasPorCobrar.Models.Entities.CtasPorCobrar;

namespace WebMigradorCtasPorCobrar.Models.ViewModels
{
    public class ConceptoPagoViewModel
    {
        public ConceptoPago ConceptoPagoMigracion { get; set; }
        public TI_ConceptoPago ConceptoPagoCtasCobrar { get; set; }

        public ConceptoPagoViewModel()
        {
            this.ConceptoPagoMigracion = new ConceptoPago();
            this.ConceptoPagoCtasCobrar = new TI_ConceptoPago();
        }
    }
}