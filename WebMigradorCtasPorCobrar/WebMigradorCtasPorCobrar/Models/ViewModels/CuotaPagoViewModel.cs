using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using WebMigradorCtasPorCobrar.Models.Entities.CtasPorCobrar;
using WebMigradorCtasPorCobrar.Models.Entities.Migracion;

namespace WebMigradorCtasPorCobrar.Models.ViewModels
{
    public class CuotaPagoViewModel
    {
        public CuotaPago CuotaMigracion { get; set; }
        public VW_Proceso CuotaCtasCobrar { get; set; }

        public CuotaPagoViewModel()
        {
            this.CuotaCtasCobrar = new VW_Proceso();
            this.CuotaMigracion = new CuotaPago();
        }
    }
}