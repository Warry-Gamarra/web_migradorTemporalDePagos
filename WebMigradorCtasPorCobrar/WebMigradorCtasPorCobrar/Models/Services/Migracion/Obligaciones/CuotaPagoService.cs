using System.Collections.Generic;
using WebMigradorCtasPorCobrar.Models.Entities.Migracion;
using WebMigradorCtasPorCobrar.Models.Helpers;
using WebMigradorCtasPorCobrar.Models.Repository.Migracion.Obligaciones;
using WebMigradorCtasPorCobrar.Models.ViewModels;
using static WebMigradorCtasPorCobrar.Models.Helpers.Observaciones;

namespace WebMigradorCtasPorCobrar.Models.Services.Migracion.Obligaciones
{
    public class CuotaPagoService
    {
        private readonly string _controller;
        private readonly string _action;

        public CuotaPagoService()
        {
            _controller = "CuotaPago";
            _action = "EjecutarValidacion";
        }

        public IEnumerable<Response> CopiarRegistrosDesdeTemporalPagos(Procedencia procedencia)
        {
            var result = new List<Response>();
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

            var response = cuotaPagoRepository.CopiarRegistros((int)procedencia, schemaDb, codigos_bnc);
            response = response.IsDone ? response.Success(false) : response.Error(false);

            result.Add(response);

            return result;
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

            response.FormatResponse("Observados por código de cuota duplicado activos", "Duplicados activos",
                                    (int)CuotaPagoObs.Repetido, _controller, _action);

            return response;
        }

        private Response ValidarDuplicadosCuotaPagoEliminados(int procedenciaId)
        {
            Response response;

            CuotaPagoRepository cuotaPagoRepository = new CuotaPagoRepository();

            response = cuotaPagoRepository.ValidarDuplicadosCuotaPagoEliminados(procedenciaId);

            response.FormatResponse("Observados por código de cuota duplicado eliminados", "Duplicados eliminados",
                                    (int)CuotaPagoObs.Eliminado, _controller, _action);

            return response;
        }

        private Response MarcarDuplicadosConDiferenteProcedenciaCuotaPago(int procedenciaId)
        {
            Response response;
            CuotaPagoRepository cuotaPagoRepository = new CuotaPagoRepository();

            response = cuotaPagoRepository.MarcarDuplicadosDiferenteProcedenciaCuotaPago(procedenciaId);

            response.FormatResponse("Observados por código de cuota duplicado con diferentes procedencias", "Duplicados dif. procedencia",
                                    (int)CuotaPagoObs.RepetidoDifProc, _controller, _action);

            return response;
        }

        private Response MarcarEliminadosCuotaPago(int? cuotaPagoID, int procedenciaId)
        {
            Response response;
            CuotaPagoRepository cuotaPagoRepository = new CuotaPagoRepository();

            response = cuotaPagoRepository.MarcarEliminadosCuotaPago(cuotaPagoID, procedenciaId);

            response.FormatResponse("Observados por estado eliminado", "Estado eliminado",
                                    (int)CuotaPagoObs.Removido, _controller, _action);

            return response;
        }

        private Response ValidarCuotaPagoSinCategoria(int? cuotaPagoID, int procedenciaId)
        {
            Response response;
            CuotaPagoRepository cuotaPagoRepository = new CuotaPagoRepository();

            response = cuotaPagoRepository.ValidarCuotaPagoSinCategoria(cuotaPagoID, procedenciaId);

            response.FormatResponse("Observados por no tener categoría equivalente en cuentas por cobrar", "Sin categoría Ctas x Cobrar",
                                    (int)CuotaPagoObs.SinCategoria, _controller, _action);

            return response;
        }

        private Response ValidarCuotaPagoConVariasCategorías(int? cuotaPagoID, int procedenciaId)
        {
            Response response;
            CuotaPagoRepository cuotaPagoRepository = new CuotaPagoRepository();

            response = cuotaPagoRepository.ValidarCuotaPagoVariasCategorias(cuotaPagoID, procedenciaId);

            response.FormatResponse("Observados por tener más de una posible categoría equivalente en cuentas por cobrar",
                                    "Varias posibles categorías Ctas",
                                    (int)CuotaPagoObs.MásDeUnaCategoría, _controller, _action);

            return response;
        }

        private Response ValidarCuotaPagoSinAnio(int? cuotaPagoID, int procedenciaId, string schema)
        {
            Response response;
            CuotaPagoRepository cuotaPagoRepository = new CuotaPagoRepository();

            response = cuotaPagoRepository.ValidarSinAnioCuotaPago(cuotaPagoID, procedenciaId, schema);

            response.FormatResponse("Observados por no poder relacionarse año a la cuota", "Sin Año",
                                    (int)CuotaPagoObs.SinAnio, _controller, _action);

            return response;
        }

        private Response ValidarMismaCuotaPagoVariosAnios(int? cuotaPagoID, int procedenciaId, string schema)
        {
            Response response;
            CuotaPagoRepository cuotaPagoRepository = new CuotaPagoRepository();

            response = cuotaPagoRepository.ValidarVariosAniosMismaCuotaPago(cuotaPagoID, procedenciaId, schema);

            response.FormatResponse("Observados por cuota relacionada a varios años", "Varios años misma cuota",
                                    (int)CuotaPagoObs.SinAnio, _controller, _action);

            return response;
        }

        private Response ValidarCuotaPagoSinPeriodo(int? cuotaPagoID, int procedenciaId, string schema)
        {
            Response response;
            CuotaPagoRepository cuotaPagoRepository = new CuotaPagoRepository();

            response = cuotaPagoRepository.ValidarSinPeriodoCuotaPago(cuotaPagoID, procedenciaId, schema);

            response.FormatResponse("Observados por no tener asignado periodo", "Sin periodo",
                                    (int)CuotaPagoObs.SinPeriodo, _controller, _action);

            return response;
        }

        private Response ValidarMismaCuotaPagoVariosPeriodos(int? cuotaPagoID, int procedenciaId, string schema)
        {
            Response response;
            CuotaPagoRepository cuotaPagoRepository = new CuotaPagoRepository();

            response = cuotaPagoRepository.ValidarVariosPeriodoMismaCuotaPago(cuotaPagoID, procedenciaId, schema);

            response.FormatResponse("Observados por cuota relacionada a varios periodos", "Varios periodos misma cuota",
                                    (int)CuotaPagoObs.MasDeUnPeriodo, _controller, _action);

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

        public Response EjecutarValidacionPorObsId(int procedencia, int observacionId)
        {
            Response result;
            string schemaDb = Schema.SetSchema((Procedencia)procedencia);

            switch ((CuotaPagoObs)observacionId)
            {
                case CuotaPagoObs.Repetido:
                    result = ValidarDuplicadosCuotaPagoActivos(procedencia);
                    break;
                case CuotaPagoObs.Eliminado:
                    result = ValidarDuplicadosCuotaPagoEliminados(procedencia);
                    break;
                case CuotaPagoObs.MasDeUnAnio:
                    result = ValidarMismaCuotaPagoVariosAnios(null, procedencia, schemaDb);
                    break;
                case CuotaPagoObs.SinAnio:
                    result = ValidarCuotaPagoSinAnio(null, procedencia, schemaDb);
                    break;
                case CuotaPagoObs.MasDeUnPeriodo:
                    result = ValidarMismaCuotaPagoVariosPeriodos(null, procedencia, schemaDb);
                    break;
                case CuotaPagoObs.SinPeriodo:
                    result = ValidarCuotaPagoSinPeriodo(null, procedencia, schemaDb);
                    break;
                case CuotaPagoObs.MásDeUnaCategoría:
                    result = ValidarCuotaPagoConVariasCategorías(null, procedencia);
                    break;
                case CuotaPagoObs.SinCategoria:
                    result = ValidarCuotaPagoSinCategoria(null, procedencia);
                    break;
                case CuotaPagoObs.Removido:
                    result = MarcarEliminadosCuotaPago(null, procedencia);
                    break;
                case CuotaPagoObs.RepetidoDifProc:
                    result = MarcarDuplicadosConDiferenteProcedenciaCuotaPago(procedencia);
                    break;
                default:
                    result = new Response();
                    break;
            }

            return result;
        }

    }
}