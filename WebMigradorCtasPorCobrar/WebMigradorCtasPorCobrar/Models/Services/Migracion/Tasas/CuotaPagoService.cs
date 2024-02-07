using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using WebMigradorCtasPorCobrar.Models.Entities.Migracion;
using WebMigradorCtasPorCobrar.Models.Helpers;
using WebMigradorCtasPorCobrar.Models.Repository.Migracion.Tasas;
using WebMigradorCtasPorCobrar.Models.ViewModels;

namespace WebMigradorCtasPorCobrar.Models.Services.Migracion.Tasas
{
    public class CuotaPagoService
    {
        public Response CopiarRegistrosDesdeTemporalPagos(Procedencia procedencia)
        {
            CuotaPagoRepository cuotaPagoRepository = new CuotaPagoRepository();
            string codigos_bnc = "";

            return cuotaPagoRepository.CopiarRegistros((int)procedencia, codigos_bnc);

        }


        public IEnumerable<Response> EjecutarValidaciones(Procedencia procedencia, int? cuotaPagoRowID)
        {
            List<Response> result = new List<Response>();
            CuotaPagoRepository cuotaPagoRepository = new CuotaPagoRepository();

            _ = cuotaPagoRepository.InicializarEstadoValidacionCuotaPago(cuotaPagoRowID, (int)procedencia);

            return result;
        }


        public IEnumerable<Response> MigrarDatosTemporalPagos(Procedencia procedencia)
        {
            List<Response> result = new List<Response>();

            return result;
        }


        public Response Save(CuotaPago cuotaPago, int? tipoObsID)
        {

            return new Response();
        }
    }
}