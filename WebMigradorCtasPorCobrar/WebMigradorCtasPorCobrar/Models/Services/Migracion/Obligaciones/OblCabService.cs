using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using WebMigradorCtasPorCobrar.Models.Repository.Migracion.Obligaciones;

namespace WebMigradorCtasPorCobrar.Models.Services.Migracion.Obligaciones
{
    public class OblCabService
    {
        private readonly ObligacionRepository _obligacionRepository;
        private readonly PagoObligacionRepository _pagoObligacionRepository;

        public OblCabService() { 
            _obligacionRepository = new ObligacionRepository();
            _pagoObligacionRepository = new PagoObligacionRepository();
        }


    }
}