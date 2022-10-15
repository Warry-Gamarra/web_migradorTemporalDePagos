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

        public TC_CatalogoOpcion ObtenerPeriodosAcademicos(string cod_per)
        {
            var result = CatalogoOpcionRepository.Obtener((int)Parametro.PeriodoAcademico)
                                                 .SingleOrDefault(x => x.T_OpcionCod == cod_per);

            return result ?? new TC_CatalogoOpcion();
        }


        public IEnumerable<TC_CatalogoOpcion> ObtenerModalidadIngreso()
        {
            return CatalogoOpcionRepository.Obtener((int)Parametro.CodigoIngreso);
        }

        public TC_CatalogoOpcion ObtenerModalidadIngreso(string codIng)
        {
            var result = CatalogoOpcionRepository.Obtener((int)Parametro.CodigoIngreso)
                                                 .SingleOrDefault(x => x.T_OpcionCod == codIng);

            return result ?? new TC_CatalogoOpcion();
        }



        public IEnumerable<VW_CarreraProfesional> ObtenerCarreraProfesional()
        {
            return CarreraProfesionalRepository.Obtener();
        }

        public VW_CarreraProfesional ObtenerCarreraProfesional(string cod_rc)
        {
            return CarreraProfesionalRepository.Obtener(cod_rc);
        }

    }
}