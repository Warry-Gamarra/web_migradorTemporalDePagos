using System.Collections.Generic;
using WebMigradorCtasPorCobrar.Models.Entities.Migracion;
using WebMigradorCtasPorCobrar.Models.Helpers;
using WebMigradorCtasPorCobrar.Models.Repository.Migracion.Tasas;
using WebMigradorCtasPorCobrar.Models.ViewModels;
using static WebMigradorCtasPorCobrar.Models.Helpers.Observaciones;

namespace WebMigradorCtasPorCobrar.Models.Services.Migracion.Tasas
{
    public class CuotaPagoService
    {
        public IEnumerable<Response> CopiarRegistrosDesdeTemporalPagos(Procedencia procedencia)
        {
            var result = new List<Response>();
            CuotaPagoRepository cuotaPagoRepository = new CuotaPagoRepository();
            string codigos_bnc = "";

            var response = cuotaPagoRepository.CopiarRegistros((int)procedencia, codigos_bnc);
            response = response.IsDone ? response.Success(false) : response.Error(false);

            result.Add(response);

            return result;
        }


        public IEnumerable<Response> EjecutarValidaciones(Procedencia procedencia, int? cuotaPagoRowID)
        {
            List<Response> result = new List<Response>();
            CuotaPagoRepository cuotaPagoRepository = new CuotaPagoRepository();

            _ = cuotaPagoRepository.InicializarEstadoValidacionCuotaPago(cuotaPagoRowID, (int)procedencia);

            return result;
        }

        public Response EjecutarValidacionPorObsId(int procedencia, int observacionId)
        {
            Response result;
            string schemaDb = Schema.SetSchema((Procedencia)procedencia);

            switch ((CuotaPagoObs)observacionId)
            {
                //case CuotaPagoObs.Repetido:
                //    result = ValidarDuplicadosCuotaPagoActivos(procedencia);
                //    break;
                //case CuotaPagoObs.Eliminado:
                //    result = ValidarDuplicadosCuotaPagoEliminados(procedencia);
                //    break;
                //case CuotaPagoObs.MasDeUnAnio:
                //    result = ValidarMismaCuotaPagoVariosAnios(null, procedencia, schemaDb);
                //    break;
                //case CuotaPagoObs.SinAnio:
                //    result = ValidarCuotaPagoSinAnio(null, procedencia, schemaDb);
                //    break;
                //case CuotaPagoObs.MasDeUnPeriodo:
                //    result = ValidarMismaCuotaPagoVariosPeriodos(null, procedencia, schemaDb);
                //    break;
                //case CuotaPagoObs.SinPeriodo:
                //    result = ValidarCuotaPagoSinPeriodo(null, procedencia, schemaDb);
                //    break;
                //case CuotaPagoObs.MásDeUnaCategoría:
                //    result = ValidarCuotaPagoConVariasCategorías(null, procedencia);
                //    break;
                //case CuotaPagoObs.SinCategoria:
                //    result = ValidarCuotaPagoSinCategoria(null, procedencia);
                //    break;
                //case CuotaPagoObs.Removido:
                //    result = MarcarEliminadosCuotaPago(null, procedencia);
                //    break;
                //case CuotaPagoObs.RepetidoDifProc:
                //    result = MarcarDuplicadosConDiferenteProcedenciaCuotaPago(procedencia);
                //    break;
                default:
                    result = new Response();
                    break;
            }

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