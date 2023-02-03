using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using WebMigradorCtasPorCobrar.Models.Entities.CtasPorCobrar;
using WebMigradorCtasPorCobrar.Models.Entities.Migracion;

namespace WebMigradorCtasPorCobrar.Models.ViewModels
{
    public class DetalleMigracionCuotaPago
    {
        public CuotaPago CuotaPago { get; set; }
        public VW_Proceso Proceso { get; set; }
        public Observacion Observacion { get; set; }

    }
}