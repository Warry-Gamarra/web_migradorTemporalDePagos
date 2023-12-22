using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using Temporal = WebMigradorCtasPorCobrar.Models.Repository.TemporalPagos;
using RepoCtas = WebMigradorCtasPorCobrar.Models.Repository.CtasPorCobrar;
using WebMigradorCtasPorCobrar.Models.Repository.Migracion;
using WebMigradorCtasPorCobrar.Models.Entities.Migracion;
using WebMigradorCtasPorCobrar.Models.Helpers;
using WebMigradorCtasPorCobrar.Models.ViewModels;
using ClosedXML.Excel;
using System.IO;
using static WebMigradorCtasPorCobrar.Models.Helpers.Observaciones;
using WebMigradorCtasPorCobrar.Models.Services.CtasPorCobrar;

namespace WebMigradorCtasPorCobrar.Models.Services.Migracion
{
    public class ConceptoPagoService
    {
        private readonly EquivalenciasServices _equivalenciaServices;

        public ConceptoPagoService()
        {
            _equivalenciaServices = new EquivalenciasServices();
        }

        public IEnumerable<ConceptoPago> Obtener(Procedencia procedencia, int? tipo_obsID)
        {
            if (tipo_obsID.HasValue)
            {
                return ObtenerConRepo(ConceptoPagoRepository.ObtenerObservados((int)procedencia, tipo_obsID.Value, (int)Tablas.TR_Cp_Pri), procedencia);
            }

            return ObtenerConRepo(ConceptoPagoRepository.Obtener((int)procedencia), procedencia);
        }

        private IEnumerable<ConceptoPago> ObtenerConRepo(IEnumerable<ConceptoPago> conceptosPago, Procedencia procedencia)
        {
            var conceptosPagoCtas = RepoCtas.ConceptoPagoRepository.Obtener((int)procedencia);

            var newCuotasPago = from c in conceptosPago
                                join cr in conceptosPagoCtas on c.Id_cp equals cr.I_ConcPagID
                                into conceptosPagoConceptosPagoCtasGroup
                                from cpg in conceptosPagoConceptosPagoCtasGroup.DefaultIfEmpty()
                                select new ConceptoPago()
                                {
                                    Id_cp = c.Id_cp,
                                    Cuota_pago = c.Cuota_pago,
                                    Descripcio = c.Descripcio,
                                    Ano = c.Ano,
                                    P = c.P,
                                    Cuota_pago_desc = c.Cuota_pago_desc,
                                    Tipo_oblig = c.Tipo_oblig,
                                    Eliminado = c.Eliminado,
                                    Monto = c.Monto,
                                    B_Migrable = c.B_Migrable,
                                    B_Migrado = c.B_Migrado,
                                    I_RowID = c.I_RowID,
                                    B_ExisteCtas = cpg == null ? false : true
                                };

            return newCuotasPago;
        }

        public ConceptoPago Obtener(int cuotaID)
        {
            return ConceptoPagoRepository.ObtenerPorId(cuotaID);
        }


        public byte[] ObtenerDatosObservaciones(Procedencia procedencia, int? tipo_obsID)
        {
            XLWorkbook excel_book = new XLWorkbook();
            MemoryStream result = new MemoryStream();

            tipo_obsID = tipo_obsID.HasValue ? tipo_obsID : 0;
            var data = ConceptoPagoRepository.ObtenerReporteObservados((int)procedencia, tipo_obsID.Value, (int)Tablas.TR_Cp_Pri);

            var sheet = excel_book.Worksheets.Add(data, "Observaciones");
            sheet.ColumnsUsed().AdjustToContents();

            excel_book.SaveAs(result);

            return result.ToArray();
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
                default:
                    codigos_bnc = "''";
                    break;
            }

            result = conceptoPagoRepository.CopiarRegistros((int)procedencia, schemaDb, codigos_bnc);

            return result.IsDone ? result.Success(false) : result.Error(false);
        }


        public IEnumerable<Response> EjecutarValidaciones(Procedencia procedencia, int? cuotaPagoRowID)
        {
            List<Response> result = new List<Response>();
            int procedenciaId = (int)procedencia;
            string schemaDb = Schema.SetSchema(procedencia);

            ConceptoPagoRepository conceptoPagoRepository = new ConceptoPagoRepository();


            _ = conceptoPagoRepository.InicializarEstadoValidacionCuotaPago(null, (int)procedencia);

            result.Add(ValidarDuplicadoConceptosPago(cuotaPagoRowID, procedenciaId));
            result.Add(ValidarEliminadoConceptosPago(cuotaPagoRowID,procedenciaId));
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

            response = response.IsDone ? response.Success(false) : response.Error(false);
            int observados = int.TryParse(response.Message, out int obs) ? obs : 0;
            response = observados == 0 ? response : response.Warning(false);
            response.CurrentID = "Grabar en tabla de conceptos";
            response.Message += " filas registradas";

            return response;
        }

        private Response AsignarIdEquivalenciasConceptoPago(int? cuotaPagoRowID, int procedenciaId)
        {
            Response response;
            ConceptoPagoRepository conceptoPagoRepository = new ConceptoPagoRepository();

            response = conceptoPagoRepository.AsignarIdEquivalenciasConceptoPago(cuotaPagoRowID, procedenciaId);

            response = response.IsDone ? response.Success(false) : response.Error(false);
            int observados = int.TryParse(response.Message, out int obs) ? obs : 0;
            response = observados == 0 ? response : response.Warning(false);
            response.CurrentID = "Observados por no tener id de equivalencia en catalogo de conceptos de pago";
            response.Message += " registros encontrados";

            return response;
        }

        private Response ValidarConceptosPagoObligSinCuotaPago(int? cuotaPagoRowID, int procedenciaId)
        {
            Response response;
            ConceptoPagoRepository conceptoPagoRepository = new ConceptoPagoRepository();

            response = conceptoPagoRepository.ValidarConceptosPagoObligSinCuotaPago(cuotaPagoRowID, procedenciaId);

            response = response.IsDone ? response.Success(false) : response.Error(false);
            int observados = int.TryParse(response.Message, out int obs) ? obs : 0;
            response = observados == 0 ? response : response.Warning(false);
            response.CurrentID = "Observados por no tener cuota de pago asociada";
            response.Message += " registros encontrados";

            return response;
        }

        private Response ValidarConceptosPagoConPeriodoDiferenteCuotaPago(int? cuotaPagoRowID, int procedenciaId)
        {
            Response response;
            ConceptoPagoRepository conceptoPagoRepository = new ConceptoPagoRepository();

            response = conceptoPagoRepository.ValidarConceptosPagoConPeriodoDiferenteCuotaPago(cuotaPagoRowID, procedenciaId);

            response = response.IsDone ? response.Success(false) : response.Error(false);
            int observados = int.TryParse(response.Message, out int obs) ? obs : 0;
            response = observados == 0 ? response : response.Warning(false);
            response.CurrentID = "Observado por tener periodo de concepto de pago diferente al periodo de la cuota de pago asociada";
            response.Message += " registros encontrados";

            return response;
        }

        private Response ValidarConceptosPagoObligSinPeriodoAsignado(int? cuotaPagoRowID, int procedenciaId)
        {
            Response response;
            ConceptoPagoRepository conceptoPagoRepository = new ConceptoPagoRepository();

            response = conceptoPagoRepository.ValidarConceptosPagoObligSinPeriodoAsignado(cuotaPagoRowID, procedenciaId);

            response = response.IsDone ? response.Success(false) : response.Error(false);
            int observados = int.TryParse(response.Message, out int obs) ? obs : 0;
            response = observados == 0 ? response : response.Warning(false);
            response.CurrentID = "Observado por no tener periodo asignado a la cuota de pago";
            response.Message += " registros encontrados";

            return response;
        }

        private Response ValidarConceptosPagoConAnioDiferenteCuotaPago(int? cuotaPagoRowID, int procedenciaId)
        {
            Response response;
            ConceptoPagoRepository conceptoPagoRepository = new ConceptoPagoRepository();

            response = conceptoPagoRepository.ValidarConceptosPagoConAnioDiferenteCuotaPago(cuotaPagoRowID, procedenciaId);

            response = response.IsDone ? response.Success(false) : response.Error(false);
            int observados = int.TryParse(response.Message, out int obs) ? obs : 0;
            response = observados == 0 ? response : response.Warning(false);
            response.CurrentID = "Observado por tener año de concepto de pago diferente al año de la cuota de pago asociada";
            response.Message += " registros encontrados";

            return response;
        }

        private Response ValidarConceptosPagoObligSinAnioAsignado(int? cuotaPagoRowID, int procedenciaId)
        {
            Response response;
            ConceptoPagoRepository conceptoPagoRepository = new ConceptoPagoRepository();

            response = conceptoPagoRepository.ValidarConceptosPagoObligSinAnioAsignado(cuotaPagoRowID, procedenciaId);

            response = response.IsDone ? response.Success(false) : response.Error(false);
            int observados = int.TryParse(response.Message, out int obs) ? obs : 0;
            response = observados == 0 ? response : response.Warning(false);
            response.CurrentID = "Observados por no tener un año asignado en el concepto de pago";
            response.Message += " registros encontrados";

            return response;
        }

        private Response ValidarConceptosPagoNoObligacion(int? cuotaPagoRowID, int procedenciaId)
        {
            Response response;
            ConceptoPagoRepository conceptoPagoRepository = new ConceptoPagoRepository();

            response = conceptoPagoRepository.ValidarConceptosPagoNoObligacion(cuotaPagoRowID, procedenciaId);

            response = response.IsDone ? response.Success(false) : response.Error(false);
            int observados = int.TryParse(response.Message, out int obs) ? obs : 0;
            response = observados == 0 ? response : response.Warning(false);
            response.CurrentID = "Observado por no tener obligaciones asociadas";
            response.Message += " registros encontrados";

            return response;
        }

        private Response ValidarEliminadoConceptosPago(int? cuotaPagoRowID, int procedenciaId)
        {
            Response response;
            ConceptoPagoRepository conceptoPagoRepository = new ConceptoPagoRepository();

            response = conceptoPagoRepository.ValidarEliminadoConceptosPago(cuotaPagoRowID, procedenciaId);

            response = response.IsDone ? response.Success(false) : response.Error(false);
            int observados = int.TryParse(response.Message, out int obs) ? obs : 0;
            response = observados == 0 ? response : response.Warning(false);
            response.CurrentID = "Observador por tener estado eliminado en el concepto de pago";
            response.Message += " registros encontrados";

            return response;
        }

        private Response ValidarDuplicadoConceptosPago(int? cuotaPagoRowID, int procedenciaId)
        {
            Response response;
            ConceptoPagoRepository conceptoPagoRepository = new ConceptoPagoRepository();

            response = conceptoPagoRepository.ValidarDuplicadoConceptosPago(cuotaPagoRowID, procedenciaId);

            response = response.IsDone ? response.Success(false) : response.Error(false);
            int observados = int.TryParse(response.Message, out int obs) ? obs : 0;
            response = observados == 0 ? response : response.Warning(false);
            response.CurrentID = "Observados por tener código de concepto duplicado";
            response.Message += " registros encontrados";

            return response;
        }


        public ConceptoPago ObtenerConRelaciones(int conceptoPagoID)
        {
            ConceptoPago conceptoPago = ConceptoPagoRepository.ObtenerPorId(conceptoPagoID);

            conceptoPago.CuotasPago = new List<CuotaPago>();
            conceptoPago.DetalleObligaciones = new List<DetalleObligacion>();

            string schema = Schema.SetSchema((Procedencia)conceptoPago.I_ProcedenciaID);
            string str_conceptoPago = conceptoPago.Id_cp.ToString();

            foreach (var concepto in ConceptoPagoRepository.Obtener(conceptoPago.I_ProcedenciaID).Where(x => x.Id_cp == conceptoPago.Id_cp))
            {
                foreach (var cuotaPago in CuotaPagoRepository.Obtener(concepto.I_ProcedenciaID).Where(x => x.Cuota_pago == concepto.Cuota_pago))
                {
                    conceptoPago.CuotasPago.Add(cuotaPago);
                }
            }

            foreach (var obligacion in Temporal.ObligacionRepository.ObtenerObligacionPorConceptoPago(schema, str_conceptoPago))
            {

            }

            foreach (var detalleObligacion in Temporal.ObligacionRepository.ObtenerDetallePorConceptoPago(schema, str_conceptoPago)//.Where (x => x.Eliminado == false)
                                                                           .Select(x => new
                                                                           {
                                                                               x.Cuota_pago,
                                                                               x.Ano,
                                                                               x.P,
                                                                               x.Concepto,
                                                                               x.Descripcio,
                                                                               x.Eliminado
                                                                           }).Distinct())
            {
                conceptoPago.DetalleObligaciones.Add(new DetalleObligacion()
                {
                    Cuota_pago = detalleObligacion.Cuota_pago,
                    Ano = detalleObligacion.Ano,
                    P = detalleObligacion.P,
                    Concepto = detalleObligacion.Concepto,
                    Descripcio = detalleObligacion.Descripcio,
                    Eliminado = detalleObligacion.Eliminado
                });
            }

            return conceptoPago;
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
    }


}