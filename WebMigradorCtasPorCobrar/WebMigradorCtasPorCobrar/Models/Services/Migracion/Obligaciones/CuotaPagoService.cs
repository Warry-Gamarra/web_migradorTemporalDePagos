using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using WebMigradorCtasPorCobrar.Models.Entities.Migracion;
using WebMigradorCtasPorCobrar.Models.Helpers;
using WebMigradorCtasPorCobrar.Models.Repository.Migracion.Obligaciones;
using WebMigradorCtasPorCobrar.Models.ViewModels;
using static WebMigradorCtasPorCobrar.Models.Helpers.Observaciones;

namespace WebMigradorCtasPorCobrar.Models.Services.Migracion.Obligaciones
{
    public class CuotaPagoService
    {
        public Response CopiarRegistrosDesdeTemporalPagos(Procedencia procedencia)
        {
            string schemaDb = Schema.SetSchema(procedencia);
            string codigos_bnc = "''";

            CuotaPagoRepository cuotaPagoRepository = new CuotaPagoRepository();

            switch (procedencia)
            {
                case Procedencia.Pregrado:
                    codigos_bnc = Constant.PREGRADO_TEMPORAL_CODIGOS_BNC;
                    break;
                case Procedencia.Posgrado:
                    codigos_bnc = Constant.POSGRADO_TEMPORAL_CODIGOS_BNC;
                    break;
                case Procedencia.Cuded:
                    codigos_bnc = Constant.EUDED_TEMPORAL_CODIGOS_BNC + ", "
                                + Constant.PROLICE_TEMPORAL_CODIGOS_BNC + ", "
                                + Constant.PROCUNED_TEMPORAL_CODIGOS_BNC;
                    break;
            }

            return cuotaPagoRepository.CopiarRegistros((int)procedencia, schemaDb, codigos_bnc);
        }


        public IEnumerable<Response> EjecutarValidaciones(Procedencia procedencia, int? cuotaPagoRowID)
        {
            List<Response> result = new List<Response>();
            int procedenciaId = (int)procedencia;
            string schemaDb = Schema.SetSchema(procedencia);
            CuotaPagoRepository cuotaPagoRepository = new CuotaPagoRepository();

            _ = cuotaPagoRepository.InicializarEstadoValidacionCuotaPago(cuotaPagoRowID, (int)procedencia);

            result.Add(ValidarDuplicadosCuotaPagoActivos(procedenciaId));
            result.Add(ValidarDuplicadosCuotaPagoEliminados(procedenciaId));
            result.Add(MarcarDuplicadosConDiferenteProcedenciaCuotaPago(procedenciaId));
            result.Add(MarcarEliminadosCuotaPago(cuotaPagoRowID, procedenciaId));
            result.Add(ValidarCuotaPagoSinCategoria(cuotaPagoRowID, procedenciaId));
            result.Add(ValidarCuotaPagoConVariasCategorías(cuotaPagoRowID, procedenciaId));
            result.Add(ValidarCuotaPagoSinAnio(cuotaPagoRowID, procedenciaId, schemaDb));
            result.Add(ValidarMismaCuotaPagoVariosAnios(cuotaPagoRowID, procedenciaId, schemaDb));
            result.Add(ValidarCuotaPagoSinPeriodo(cuotaPagoRowID, procedenciaId, schemaDb));
            result.Add(ValidarMismaCuotaPagoVariosPeriodos(cuotaPagoRowID, procedenciaId, schemaDb));

            return result;
        }

        private Response ValidarDuplicadosCuotaPagoActivos(int procedenciaId)
        {
            Response response;

            CuotaPagoRepository cuotaPagoRepository = new CuotaPagoRepository();

            response = cuotaPagoRepository.ValidarDuplicadosCuotaPagoActivos(procedenciaId);

            response = response.IsDone ? response.Success(false) : response.Error(false);
            int observados = int.TryParse(response.Message, out int obs) ? obs : 0;
            response = observados == 0 ? response : response.Warning(false);
            response.CurrentID = "Observados por código de cuota duplicado activos";
            response.Message += " registros encontrados";


            return response;
        }

        private Response ValidarDuplicadosCuotaPagoEliminados(int procedenciaId)
        {
            Response response;

            CuotaPagoRepository cuotaPagoRepository = new CuotaPagoRepository();

            response = cuotaPagoRepository.ValidarDuplicadosCuotaPagoEliminados(procedenciaId);

            response = response.IsDone ? response.Success(false) : response.Error(false);
            int observados = int.TryParse(response.Message, out int obs) ? obs : 0;
            response = observados == 0 ? response : response.Warning(false);
            response.CurrentID = "Observados por código de cuota duplicado eliminados";
            response.Message += " registros encontrados";


            return response;
        }

        private Response MarcarDuplicadosConDiferenteProcedenciaCuotaPago(int procedenciaId)
        {
            Response response;
            CuotaPagoRepository cuotaPagoRepository = new CuotaPagoRepository();

            response = cuotaPagoRepository.MarcarDuplicadosDiferenteProcedenciaCuotaPago(procedenciaId);

            response = response.IsDone ? response.Success(false) : response.Error(false);
            int observados = int.TryParse(response.Message, out int obs) ? obs : 0;
            response = observados == 0 ? response : response.Warning(false);
            response.CurrentID = "Observados por código de cuota duplicado con diferentes procedencias";
            response.Message += " registros encontrados";


            return response;
        }

        private Response MarcarEliminadosCuotaPago(int? cuotaPagoID, int procedenciaId)
        {
            Response response;
            CuotaPagoRepository cuotaPagoRepository = new CuotaPagoRepository();

            response = cuotaPagoRepository.MarcarEliminadosCuotaPago(cuotaPagoID, procedenciaId);

            response = response.IsDone ? response.Success(false) : response.Error(false);
            int observados = int.TryParse(response.Message, out int obs) ? obs : 0;
            response = observados == 0 ? response : response.Warning(false);
            response.CurrentID = "Observados por estado eliminado";
            response.Message += " registros encontrados";


            return response;
        }

        private Response ValidarCuotaPagoSinCategoria(int? cuotaPagoID, int procedenciaId)
        {
            Response response;
            CuotaPagoRepository cuotaPagoRepository = new CuotaPagoRepository();

            response = cuotaPagoRepository.ValidarCuotaPagoSinCategoria(cuotaPagoID, procedenciaId);

            response = response.IsDone ? response.Success(false) : response.Error(false);
            int observados = int.TryParse(response.Message, out int obs) ? obs : 0;
            response = observados == 0 ? response : response.Warning(false);
            response.CurrentID = "Observados por no tener categoría equivalente en cuentas por cobrar";
            response.Message += " registros encontrados";

            return response;
        }

        private Response ValidarCuotaPagoConVariasCategorías(int? cuotaPagoID, int procedenciaId)
        {
            Response response;
            CuotaPagoRepository cuotaPagoRepository = new CuotaPagoRepository();

            response = cuotaPagoRepository.ValidarCuotaPagoVariasCategorias(cuotaPagoID, procedenciaId);

            response = response.IsDone ? response.Success(false) : response.Error(false);
            int observados = int.TryParse(response.Message, out int obs) ? obs : 0;
            response = observados == 0 ? response : response.Warning(false);
            response.CurrentID = "Observados tener más de una posible categoría equivalente en cuentas por cobrar";
            response.Message += " registros encontrados";

            return response;
        }

        private Response ValidarCuotaPagoSinAnio(int? cuotaPagoID, int procedenciaId, string schema)
        {
            Response response;
            CuotaPagoRepository cuotaPagoRepository = new CuotaPagoRepository();

            response = cuotaPagoRepository.ValidarSinAnioCuotaPago(cuotaPagoID, procedenciaId, schema);

            response = response.IsDone ? response.Success(false) : response.Error(false);
            int observados = int.TryParse(response.Message, out int obs) ? obs : 0;
            response = observados == 0 ? response : response.Warning(false);
            response.CurrentID = "Observados por no poder relacionarse año a la cuota";
            response.Message += " registros encontrados";

            return response;
        }

        private Response ValidarMismaCuotaPagoVariosAnios(int? cuotaPagoID, int procedenciaId, string schema)
        {
            Response response;
            CuotaPagoRepository cuotaPagoRepository = new CuotaPagoRepository();

            response = cuotaPagoRepository.ValidarVariosAniosMismaCuotaPago(cuotaPagoID, procedenciaId, schema);

            response = response.IsDone ? response.Success(false) : response.Error(false);
            int observados = int.TryParse(response.Message, out int obs) ? obs : 0;
            response = observados == 0 ? response : response.Warning(false);
            response.CurrentID = "Observados por cuota relacionada a varios años";
            response.Message += " registros encontrados";

            return response;
        }

        private Response ValidarCuotaPagoSinPeriodo(int? cuotaPagoID, int procedenciaId, string schema)
        {
            Response response;
            CuotaPagoRepository cuotaPagoRepository = new CuotaPagoRepository();

            response = cuotaPagoRepository.ValidarSinPeriodoCuotaPago(cuotaPagoID, procedenciaId, schema);

            response = response.IsDone ? response.Success(false) : response.Error(false);
            int observados = int.TryParse(response.Message, out int obs) ? obs : 0;
            response = observados == 0 ? response : response.Warning(false);
            response.CurrentID = "Observados por no tener asignado periodo";
            response.Message += " registros encontrados";

            return response;
        }

        private Response ValidarMismaCuotaPagoVariosPeriodos(int? cuotaPagoID, int procedenciaId, string schema)
        {
            Response response;
            CuotaPagoRepository cuotaPagoRepository = new CuotaPagoRepository();

            response = cuotaPagoRepository.ValidarVariosPeriodoMismaCuotaPago(cuotaPagoID, procedenciaId, schema);

            response = response.IsDone ? response.Success(false) : response.Error(false);
            int observados = int.TryParse(response.Message, out int obs) ? obs : 0;
            response = observados == 0 ? response : response.Warning(false);
            response.CurrentID = "Observados por cuota relacionada a varios periodos";
            response.Message += " registros encontrados";

            return response;
        }

        public IEnumerable<Response> MigrarDatosTemporalPagos(Procedencia procedencia)
        {
            List<Response> result = new List<Response>();
            string schemaDb = Schema.SetSchema(procedencia);

            CuotaPagoRepository cuotaPagoRepository = new CuotaPagoRepository();

            Response result_part = cuotaPagoRepository.MigrarDataCuotaPagoCtasPorCobrar((int)procedencia, null, null, null);

            result.Add(result_part.IsDone ? result_part.Success(false) : result_part.Error(false));

            return result;
        }


        public Response Save(CuotaPago cuotaPago, int? tipoObsID)
        {
            Response result;
            string schemaDb = Schema.SetSchema((Procedencia)cuotaPago.I_ProcedenciaID);

            CuotaPagoRepository cuotaPagoRepository = new CuotaPagoRepository();
            cuotaPagoRepository.InicializarEstadoValidacionCuotaPago(cuotaPago.I_RowID, cuotaPago.I_ProcedenciaID);

            switch ((CuotaPagoObs)(tipoObsID ?? 0))
            {
                case CuotaPagoObs.Repetido:
                    result = cuotaPagoRepository.SaveRepetido(cuotaPago);
                    break;
                case CuotaPagoObs.MasDeUnAnio:
                    result = cuotaPagoRepository.SaveAnio(cuotaPago);
                    break;
                case CuotaPagoObs.SinAnio:
                    result = cuotaPagoRepository.SaveAnio(cuotaPago);
                    break;
                case CuotaPagoObs.MasDeUnPeriodo:
                    result = cuotaPagoRepository.SavePeriodo(cuotaPago);
                    break;
                case CuotaPagoObs.SinPeriodo:
                    result = cuotaPagoRepository.SavePeriodo(cuotaPago);
                    break;
                case CuotaPagoObs.MásDeUnaCategoría:
                    result = cuotaPagoRepository.SaveCategoria(cuotaPago);
                    break;
                case CuotaPagoObs.SinCategoria:
                    result = cuotaPagoRepository.SaveCategoria(cuotaPago);
                    break;
                default:
                    result = cuotaPagoRepository.SaveCorrecto(cuotaPago);
                    break;
            }

            cuotaPagoRepository.ValidarDuplicadosCuotaPagoActivos(cuotaPago.I_ProcedenciaID);
            cuotaPagoRepository.ValidarDuplicadosCuotaPagoEliminados(cuotaPago.I_ProcedenciaID);
            cuotaPagoRepository.MarcarDuplicadosDiferenteProcedenciaCuotaPago(cuotaPago.I_ProcedenciaID);
            cuotaPagoRepository.ValidarCuotaPagoSinCategoria(cuotaPago.I_RowID, cuotaPago.I_ProcedenciaID);
            cuotaPagoRepository.ValidarCuotaPagoVariasCategorias(cuotaPago.I_RowID, cuotaPago.I_ProcedenciaID);
            cuotaPagoRepository.ValidarSinAnioCuotaPago(cuotaPago.I_RowID, cuotaPago.I_ProcedenciaID, schemaDb);
            cuotaPagoRepository.ValidarVariosAniosMismaCuotaPago(cuotaPago.I_RowID, cuotaPago.I_ProcedenciaID, schemaDb);
            cuotaPagoRepository.ValidarSinPeriodoCuotaPago(cuotaPago.I_RowID, cuotaPago.I_ProcedenciaID, schemaDb);
            cuotaPagoRepository.ValidarVariosPeriodoMismaCuotaPago(cuotaPago.I_RowID, cuotaPago.I_ProcedenciaID, schemaDb);

            return result;
        }

    }
}