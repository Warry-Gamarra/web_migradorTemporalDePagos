using System.Collections.Generic;
using WebMigradorCtasPorCobrar.Models.Entities.Migracion;
using WebMigradorCtasPorCobrar.Models.Helpers;
using WebMigradorCtasPorCobrar.Models.Repository.Migracion.Obligaciones;
using WebMigradorCtasPorCobrar.Models.Services.CtasPorCobrar;
using WebMigradorCtasPorCobrar.Models.ViewModels;
using static WebMigradorCtasPorCobrar.Models.Helpers.Observaciones;

namespace WebMigradorCtasPorCobrar.Models.Services.Migracion.Obligaciones
{
    public class ConceptoPagoService
    {
        private readonly EquivalenciasServices _equivalenciaServices;
        private readonly string _controller;
        private readonly string _action;

        public ConceptoPagoService()
        {
            _equivalenciaServices = new EquivalenciasServices();
            _controller = "ConceptoPago";
            _action = "EjecutarValidacion";
        }

        public Response CopiarRegistrosDesdeTemporalPagos(Procedencia procedencia)
        {
            Response result = new Response();
            ConceptoPagoRepository conceptoPagoRepository = new ConceptoPagoRepository();

            string schemaDb = Schema.SetSchema(procedencia);
            string codigos_bnc = "";

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

            result = conceptoPagoRepository.CopiarRegistros((int)procedencia, schemaDb, codigos_bnc);

            return result.IsDone ? result.Success(false) : result.Error(false);
        }


        public IEnumerable<Response> EjecutarValidaciones(Procedencia procedencia, int? cuotaPagoRowID)
        {
            List<Response> result = new List<Response>();
            int procedenciaId = (int)procedencia;

            ConceptoPagoRepository conceptoPagoRepository = new ConceptoPagoRepository();

            _ = conceptoPagoRepository.InicializarEstadoValidacionCuotaPago(cuotaPagoRowID, procedenciaId);

            result.Add(ValidarDuplicadoConceptosPago(cuotaPagoRowID, procedenciaId));
            result.Add(ValidarEliminadoConceptosPago(cuotaPagoRowID, procedenciaId));
            result.Add(ValidarConceptosPagoNoObligacion(cuotaPagoRowID, procedenciaId));
            result.Add(ValidarConceptosPagoObligSinAnioAsignado(cuotaPagoRowID, procedenciaId));
            result.Add(ValidarConceptosPagoConAnioDiferenteCuotaPago(cuotaPagoRowID, procedenciaId));
            result.Add(ValidarConceptosPagoObligSinPeriodoAsignado(cuotaPagoRowID, procedenciaId));
            result.Add(ValidarConceptosPagoConPeriodoDiferenteCuotaPago(cuotaPagoRowID, procedenciaId));
            result.Add(ValidarConceptosPagoObligSinCuotaPago(cuotaPagoRowID, procedenciaId));
            result.Add(AsignarIdEquivalenciasConceptoPago(cuotaPagoRowID, procedenciaId));
            result.Add(GrabarTablaCatalogoConceptos(cuotaPagoRowID, procedenciaId));

            return result;
        }


        private Response GrabarTablaCatalogoConceptos(int? cuotaPagoRowID, int procedenciaId)
        {
            Response response;
            ConceptoPagoRepository conceptoPagoRepository = new ConceptoPagoRepository();

            response = conceptoPagoRepository.GrabarTablaCatalogoConceptos(procedenciaId);

            response.FormatResponse("Grabar en tabla de conceptos", "Grabar en tabla de conceptos", 0, _controller, _action);

            return response;
        }


        private Response AsignarIdEquivalenciasConceptoPago(int? cuotaPagoRowID, int procedenciaId)
        {
            Response response;
            ConceptoPagoRepository conceptoPagoRepository = new ConceptoPagoRepository();

            response = conceptoPagoRepository.AsignarIdEquivalenciasConceptoPago(cuotaPagoRowID, procedenciaId);

            response.FormatResponse("Observados por no tener id de equivalencia en catalogo de conceptos de pago", "Sin Id catálogo concepto", 0, _controller, _action);

            return response;
        }

        private Response ValidarConceptosPagoObligSinCuotaPago(int? cuotaPagoRowID, int procedenciaId)
        {
            Response response;
            ConceptoPagoRepository conceptoPagoRepository = new ConceptoPagoRepository();

            response = conceptoPagoRepository.ValidarConceptosPagoObligSinCuotaPago(cuotaPagoRowID, procedenciaId);

            response.FormatResponse("Observados por no tener cuota de pago asociada", "Sin cuota de pago", (int)ConceptoPagoObs.SinCuotaPago, _controller, _action);

            return response;
        }

        private Response ValidarConceptosPagoConPeriodoDiferenteCuotaPago(int? cuotaPagoRowID, int procedenciaId)
        {
            Response response;
            ConceptoPagoRepository conceptoPagoRepository = new ConceptoPagoRepository();

            response = conceptoPagoRepository.ValidarConceptosPagoConPeriodoDiferenteCuotaPago(cuotaPagoRowID, procedenciaId);

            response.FormatResponse("Observado por tener periodo de concepto de pago diferente al periodo de la cuota de pago asociada",
                                    "Periodo cuota de pago",
                                    (int)ConceptoPagoObs.ErrorConPeriodoCuota,
                                    _controller,
                                    _action);

            return response;
        }

        private Response ValidarConceptosPagoObligSinPeriodoAsignado(int? cuotaPagoRowID, int procedenciaId)
        {
            Response response;
            ConceptoPagoRepository conceptoPagoRepository = new ConceptoPagoRepository();

            response = conceptoPagoRepository.ValidarConceptosPagoObligSinPeriodoAsignado(cuotaPagoRowID, procedenciaId);

            response.FormatResponse("Observado por no tener periodo asignado a la cuota de pago", "Sin periodo",
                                    (int)ConceptoPagoObs.SinPeriodo, _controller, _action);

            return response;
        }

        private Response ValidarConceptosPagoConAnioDiferenteCuotaPago(int? cuotaPagoRowID, int procedenciaId)
        {
            Response response;
            ConceptoPagoRepository conceptoPagoRepository = new ConceptoPagoRepository();

            response = conceptoPagoRepository.ValidarConceptosPagoConAnioDiferenteCuotaPago(cuotaPagoRowID, procedenciaId);

            response.FormatResponse("Observado por tener año de concepto de pago diferente al año de la cuota de pago asociada",
                                    "Año cuota de pago", (int)ConceptoPagoObs.ErrorConAnioCuota, _controller, _action);


            return response;
        }

        private Response ValidarConceptosPagoObligSinAnioAsignado(int? cuotaPagoRowID, int procedenciaId)
        {
            Response response;
            ConceptoPagoRepository conceptoPagoRepository = new ConceptoPagoRepository();

            response = conceptoPagoRepository.ValidarConceptosPagoObligSinAnioAsignado(cuotaPagoRowID, procedenciaId);

            response.FormatResponse("Observados por no tener un año asignado en el concepto de pago", "Sin año asignado",
                                    (int)ConceptoPagoObs.SinAnio, _controller, _action);

            return response;
        }

        private Response ValidarConceptosPagoNoObligacion(int? cuotaPagoRowID, int procedenciaId)
        {
            Response response;
            ConceptoPagoRepository conceptoPagoRepository = new ConceptoPagoRepository();

            response = conceptoPagoRepository.ValidarConceptosPagoNoObligacion(cuotaPagoRowID, procedenciaId);

            response.FormatResponse("Observado por no tener obligaciones asociadas", "Tipo obligacion no",
                                    (int)ConceptoPagoObs.NoObligacion, _controller, _action);

            return response;
        }

        private Response ValidarEliminadoConceptosPago(int? cuotaPagoRowID, int procedenciaId)
        {
            Response response;
            ConceptoPagoRepository conceptoPagoRepository = new ConceptoPagoRepository();

            response = conceptoPagoRepository.ValidarEliminadoConceptosPago(cuotaPagoRowID, procedenciaId);

            response.FormatResponse("Observador por tener estado eliminado en el concepto de pago", "Estado eliminado",
                                    (int)ConceptoPagoObs.Removido, _controller, _action);

            return response;
        }

        private Response ValidarDuplicadoConceptosPago(int? cuotaPagoRowID, int procedenciaId)
        {
            Response response;
            ConceptoPagoRepository conceptoPagoRepository = new ConceptoPagoRepository();

            response = conceptoPagoRepository.ValidarDuplicadoConceptosPago(cuotaPagoRowID, procedenciaId);

            response.FormatResponse("Observados por tener código de concepto duplicado", "Concepto pago duplicado",
                                    (int)ConceptoPagoObs.Repetido, _controller, _action);

            return response;
        }


        public Response Save(ConceptoPago conceptoPago, int tipoObserv)
        {
            Response result = new Response();
            ConceptoPagoRepository conceptoPagoRepository = new ConceptoPagoRepository();
            conceptoPago.P = _equivalenciaServices.ObtenerPorId(conceptoPago.I_TipPerID).T_OpcionCod;

            conceptoPagoRepository.InicializarEstadoValidacionCuotaPago(conceptoPago.I_RowID, conceptoPago.I_ProcedenciaID);

            switch ((ConceptoPagoObs)tipoObserv)
            {
                case ConceptoPagoObs.Repetido:
                    result = conceptoPagoRepository.SaveRepetido(conceptoPago);
                    break;
                case ConceptoPagoObs.SinCuotaPago:
                    result = conceptoPagoRepository.SaveCuotaPago(conceptoPago);
                    break;
                case ConceptoPagoObs.SinAnio:
                    result = conceptoPagoRepository.SaveAnio(conceptoPago);
                    break;
                case ConceptoPagoObs.SinPeriodo:
                    result = conceptoPagoRepository.SavePeriodo(conceptoPago);
                    break;
                case ConceptoPagoObs.ErrorConAnioCuota:
                    result = conceptoPagoRepository.SaveAnio(conceptoPago);
                    break;
                case ConceptoPagoObs.ErrorConPeriodoCuota:
                    result = conceptoPagoRepository.SavePeriodo(conceptoPago);
                    break;
                case ConceptoPagoObs.NoObligacion:
                    result = conceptoPagoRepository.SaveEstadoObligacion(conceptoPago);
                    break;
                default:
                    result = conceptoPagoRepository.Save(conceptoPago);
                    break;
            }

            conceptoPagoRepository.ValidarDuplicadoConceptosPago(conceptoPago.I_RowID, conceptoPago.I_ProcedenciaID);
            conceptoPagoRepository.ValidarEliminadoConceptosPago(conceptoPago.I_RowID, conceptoPago.I_ProcedenciaID);
            conceptoPagoRepository.ValidarConceptosPagoNoObligacion(conceptoPago.I_RowID, conceptoPago.I_ProcedenciaID);
            conceptoPagoRepository.ValidarConceptosPagoObligSinAnioAsignado(conceptoPago.I_RowID, conceptoPago.I_ProcedenciaID);
            conceptoPagoRepository.ValidarConceptosPagoConAnioDiferenteCuotaPago(conceptoPago.I_RowID, conceptoPago.I_ProcedenciaID);
            conceptoPagoRepository.ValidarConceptosPagoObligSinPeriodoAsignado(conceptoPago.I_RowID, conceptoPago.I_ProcedenciaID);
            conceptoPagoRepository.ValidarConceptosPagoConPeriodoDiferenteCuotaPago(conceptoPago.I_RowID, conceptoPago.I_ProcedenciaID);
            conceptoPagoRepository.ValidarConceptosPagoObligSinCuotaPago(conceptoPago.I_RowID, conceptoPago.I_ProcedenciaID);
            conceptoPagoRepository.AsignarIdEquivalenciasConceptoPago(conceptoPago.I_RowID, conceptoPago.I_ProcedenciaID);

            return result.IsDone ? result.Success(false) : result.Error(false);
        }

        public IEnumerable<Response> MigrarDatosTemporalPagos(Procedencia procedencia)
        {
            List<Response> result = new List<Response>();
            string schemaDb = Schema.SetSchema(procedencia);

            ConceptoPagoRepository conceptoPagoRepository = new ConceptoPagoRepository();

            Response result_part = conceptoPagoRepository.MigrarDataConceptoPagoCtasPorCobrar((int)procedencia, null, null, null);

            result.Add(result_part.IsDone ? result_part.Success(false) : result_part.Error(false));

            return result;
        }


        public Response EjecutarValidacionPorObsId(int procedencia, int observacionId)
        {
            Response result;
            string schemaDb = Schema.SetSchema((Procedencia)procedencia);

            switch ((ConceptoPagoObs)observacionId)
            {
                case ConceptoPagoObs.Repetido:
                    result = ValidarDuplicadoConceptosPago(null, procedencia);
                    break;
                case ConceptoPagoObs.SinAnio:
                    result = ValidarConceptosPagoObligSinAnioAsignado(null, procedencia);
                    break;
                case ConceptoPagoObs.ErrorConAnioCuota:
                    result = ValidarConceptosPagoConAnioDiferenteCuotaPago(null, procedencia);
                    break;
                case ConceptoPagoObs.SinPeriodo:
                    result = ValidarConceptosPagoObligSinPeriodoAsignado(null, procedencia);
                    break;
                case ConceptoPagoObs.ErrorConPeriodoCuota:
                    result = ValidarConceptosPagoConPeriodoDiferenteCuotaPago(null, procedencia);
                    break;
                case ConceptoPagoObs.SinCuotaPago:
                    result = ValidarConceptosPagoObligSinCuotaPago(null, procedencia);
                    break;
                case ConceptoPagoObs.SinCuotaMigrada:
                    result = new Response();
                    break;
                case ConceptoPagoObs.Externo:
                    result = new Response();
                    break;
                case ConceptoPagoObs.NoObligacion:
                    result = ValidarConceptosPagoNoObligacion(null, procedencia);
                    break;
                case ConceptoPagoObs.Removido:
                    result = ValidarEliminadoConceptosPago(null, procedencia);
                    break;
                default:
                    result = new Response();
                    break;
            }

            return result;
        }

    }


}