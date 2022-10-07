using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using WebMigradorCtasPorCobrar.Models.Entities.CtasPorCobrar;
using WebMigradorCtasPorCobrar.Models.Repository.CtasPorCobrar;
using static WebMigradorCtasPorCobrar.Models.Helpers.CtasPorCobrar;

namespace WebMigradorCtasPorCobrar.Models.Services.CtasPorCobrar
{
    public class EquivalenciasServices
    {
        public IEnumerable<TC_CategoriaPago> ObtenerCategoriasPago(string cod_bnc)
        {
            return CategoriaPagoRepository.Obtener().Where(x => x.N_CodBanco == cod_bnc);
        }

        public IEnumerable<TC_CatalogoOpcion> ObtenerPeriodosAcademicos()
        {
            return CatalogoOpcionRepository.Obtener((int)Parametro.PeriodoAcademico);
        }

    }
}