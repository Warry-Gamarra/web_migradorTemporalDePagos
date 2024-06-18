using System.Collections.Generic;
using WebMigradorCtasPorCobrar.Models.Entities.Migracion;
using WebMigradorCtasPorCobrar.Models.Helpers;
using CrossRepo = WebMigradorCtasPorCobrar.Models.Repository.Migracion.Cross;
using WebMigradorCtasPorCobrar.Models.Repository.Migracion.Obligaciones;
using Temporal = WebMigradorCtasPorCobrar.Models.Repository.TemporalPagos.ObligacionRepository;
using WebMigradorCtasPorCobrar.Models.ViewModels;
using static WebMigradorCtasPorCobrar.Models.Helpers.Observaciones;

namespace WebMigradorCtasPorCobrar.Models.Services.Migracion.Obligaciones
{
    public class ObligacionService
    {
        public IEnumerable<Response> CopiarRegistrosDesdeTemporalPagos(Procedencia procedencia, string anio)
        {
            List<Response> result = new List<Response>();

            string schemaDb = Schema.SetSchema(procedencia);

            if (!string.IsNullOrEmpty(anio))
            {
                result = this.CopiarRegistrosPorAnio((int)procedencia, schemaDb, anio);
            }
            else
            {
                foreach (var itemAnio in Temporal.ObtenerAnios(schemaDb))
                {
                    result.AddRange(this.CopiarRegistrosPorAnio((int)procedencia, schemaDb, itemAnio));
                }
            }

            return result;
        }


        private List<Response> CopiarRegistrosPorAnio(int procedencia, string schema, string anio)
        {
            List<Response> result = new List<Response>();
            ObligacionRepository obligacionRepository = new ObligacionRepository();
            PagoObligacionRepository pagoObligacionRepository = new PagoObligacionRepository();

            Response result_Pago = pagoObligacionRepository.CopiarRegistrosPago(procedencia, schema, anio);
            Response result_Cabecera = obligacionRepository.CopiarRegistrosCabecera(procedencia, schema, anio);
            Response result_Detalle = obligacionRepository.CopiarRegistrosDetalle(procedencia, schema, anio);
            
            Response _ = obligacionRepository.VincularCabeceraDetalle(procedencia, anio);
            Response _p = pagoObligacionRepository.VincularCabeceraPago(procedencia, anio);

            result_Cabecera = result_Cabecera.IsDone ? result_Cabecera.Success(false) : result_Cabecera.Error(false);
            result_Detalle = result_Detalle.IsDone ? result_Detalle.Success(false) : result_Detalle.Error(false);
            result_Pago = result_Pago.IsDone ? result_Pago.Success(false) : result_Pago.Error(false);

            result.Add(result_Cabecera);
            result.Add(result_Detalle);
            result.Add(result_Pago);

            return result;
        }


        public IEnumerable<Response> EjecutarValidaciones(Procedencia procedencia, string anioValidacion)
        {
            List<Response> result = new List<Response>();
            int procedencia_id = (int)procedencia;
            var pagosSetvice = new PagoObligacionService();
            
            result.Add(ValidarAnioEnCabeceraObligacion(procedencia_id));

            if (!string.IsNullOrEmpty(anioValidacion))
            {
                result = this.EjecutarValidacionesPorAnio(procedencia_id, anioValidacion);
            }
            else
            {
                foreach (var itemAnio in CrossRepo.ObligacionRepository.ObtenerAnios(procedencia_id))
                {
                    result.AddRange(this.EjecutarValidacionesPorAnio(procedencia_id, itemAnio));
                }
            }

            result.AddRange(pagosSetvice.EjecutarValidaciones(procedencia, anioValidacion));

            return result;
        }

        private List<Response> EjecutarValidacionesPorAnio(int procedencia_id, string anio)
        {
            List<Response> result = new List<Response>();
            ObligacionRepository obligacionRepository = new ObligacionRepository();
            PagoObligacionRepository pagoObligacionRepository = new PagoObligacionRepository();

            _ = obligacionRepository.InicializarEstadoValidacionObligacionPago(procedencia_id, anio);

            result.Add(ValidarAlumnoCabeceraObligacion(procedencia_id, anio));
            result.Add(ValidarPeriodoEnCabeceraObligacion(procedencia_id, anio));
            result.Add(ValidarCabeceraObligacionSinDetalle(procedencia_id, anio));

            result.Add(ValidarObligacionCuotaPagoMigrada(procedencia_id, anio));
            result.Add(ValidarProcedenciaObligacionCuotaPago(procedencia_id, anio));

            _ = obligacionRepository.InicializarEstadoValidacionDetalleObligacion(procedencia_id, anio);
            result.Add(ValidarDetalleObligacionSinCabeceraID(procedencia_id, anio));
            result.Add(ValidarDetalleObligacionConceptoPago(procedencia_id, anio));
            result.Add(ValidarDetalleObligacionConceptoPagoMigrado(procedencia_id, anio));
            result.Add(ValidarCabeceraObligacionConceptoPagoMigrado(procedencia_id, anio));

            _ = pagoObligacionRepository.InicializarEstadoValidacion(procedencia_id, anio);

            return result;

        }

        public Response EjecutarValidacionPorObsId(int procedencia, int observacionId)
        {
            throw new System.NotImplementedException();
        }


        private Response ValidarProcedenciaObligacionCuotaPago(int procedencia, string anio)
        {
            ObligacionRepository obligacionRepository = new ObligacionRepository();
            Response result_Procedencia = obligacionRepository.ValidarProcedenciaObligacionCuotaPago(procedencia, anio);

            result_Procedencia.ReturnViewValidationsMessage($"Año {anio} - Observado por procedencia de la cuota de pago",
                                                            (int)ObligacionesPagoObs.ProcedenciaNoCoincide,
                                                            "Obligaciones", "EjecutarValidacion");

            return result_Procedencia;
        }

        private Response ValidarObligacionCuotaPagoMigrada(int procedencia, string anio)
        {
            ObligacionRepository obligacionRepository = new ObligacionRepository();
            Response result_CuotaPagoMigrada = obligacionRepository.ValidarObligacionCuotaPagoMigrada(procedencia, anio);

            result_CuotaPagoMigrada.ReturnViewValidationsMessage($"Año {anio} - Observado por cuota de pago sin migrar",
                                                                   (int)ObligacionesPagoObs.SinCuotaPagoMigrable,
                                                                   "Obligaciones", "EjecutarValidacion");

            return result_CuotaPagoMigrada;
        }

        private Response ValidarFechaVencimientoCuotaObligacion(int procedencia, string anio)
        {
            ObligacionRepository obligacionRepository = new ObligacionRepository();
            Response result_FecVencimiento = obligacionRepository.ValidarFechaVencimientoCuotaObligacion(procedencia, anio);

            result_FecVencimiento.ReturnViewValidationsMessage($"Año {anio} - Observado por fecha de vencimiento repetido para diferentes cuotas de pago",
                                                                (int)ObligacionesPagoObs.FchVencRepetido,
                                                                "Obligaciones", "EjecutarValidacion");

            return result_FecVencimiento;
        }

        private Response ValidarAlumnoCabeceraObligacion(int procedencia, string anio)
        {
            ObligacionRepository obligacionRepository = new ObligacionRepository();
            Response result_Alumnos = obligacionRepository.ValidarAlumnoCabeceraObligacion(procedencia, anio);

            result_Alumnos.ReturnViewValidationsMessage($"Año {anio} - Observados por código de alumno inexistente en la relación de alumnos.",
                                                         (int)ObligacionesPagoObs.SinAlumno,
                                                         "Obligaciones", "EjecutarValidacion");

            return result_Alumnos;
        }

        private Response ValidarAnioEnCabeceraObligacion(int procedencia)
        {
            ObligacionRepository obligacionRepository = new ObligacionRepository();
            Response result_Anio = obligacionRepository.ValidarAnioEnCabeceraObligacion(procedencia);

            result_Anio.ReturnViewValidationsMessage($"Observados por año errado en la obligación.",
                                                       (int)ObligacionesPagoObs.AnioNoValido,
                                                       "Obligaciones", "EjecutarValidacion");

            return result_Anio;
        }

        private Response ValidarPeriodoEnCabeceraObligacion(int procedencia, string anio)
        {
            ObligacionRepository obligacionRepository = new ObligacionRepository();
            Response result_Periodo = obligacionRepository.ValidarPeriodoEnCabeceraObligacion(procedencia, anio);

            result_Periodo.ReturnViewValidationsMessage($"Observados por año errado en la obligación.",
                                                        (int)ObligacionesPagoObs.SinPeriodo,
                                                        "Obligaciones", "EjecutarValidacion");
            return result_Periodo;
        }

        private Response ValidarCabeceraObligacionSinDetalle(int procedencia, string anio)
        {
            ObligacionRepository obligacionRepository = new ObligacionRepository();
            Response result = obligacionRepository.ValidarCabeceraObligacionSinDetalle(procedencia, anio);

            result.ReturnViewValidationsMessage($"Año {anio} - Observados por no tener detalle para la obligación.",
                                                 (int)ObligacionesPagoObs.SinDetalle,
                                                 "Obligaciones", "EjecutarValidacion");

            return result;
        }

        private Response ValidarDetalleObligacionSinCabeceraID(int procedencia, string anio)
        {
            ObligacionRepository obligacionRepository = new ObligacionRepository();
            Response result_Detalle = obligacionRepository.ValidarDetalleObligacionSinCabeceraID(procedencia, anio);

            result_Detalle.ReturnViewValidationsMessage($"Año {anio} - Observados por no tener Id de obligacion.",
                                                         (int)DetalleObligacionObs.SinObligacionMigrada,
                                                         "Obligaciones", "EjecutarValidacion");

            return result_Detalle;
        }


        private Response ValidarDetalleObligacionConceptoPago(int procedencia, string anio)
        {
            ObligacionRepository obligacionRepository = new ObligacionRepository();
            Response result_Detalle = obligacionRepository.ValidarDetalleObligacionConceptoPago(procedencia, anio);

            result_Detalle.ReturnViewValidationsMessage($"Año {anio} - Observados por no existir en cp_pri.",
                                                         (int)DetalleObligacionObs.ConceptoNoExiste,
                                                         "Obligaciones", "EjecutarValidacion");

            return result_Detalle;
        }

        private Response ValidarCabeceraObligacionConceptoPagoMigrado(int procedencia, string anio)
        {
            ObligacionRepository obligacionRepository = new ObligacionRepository();
            Response result_Detalle = obligacionRepository.ValidarCabObligacionConceptoPagoMigrado(procedencia, anio);

            result_Detalle.ReturnViewValidationsMessage($"Año {anio} - Cabecera observados por no tener el concepto migrado.",
                                                         (int)DetalleObligacionObs.SinConceptoMigrado,
                                                         "Obligaciones", "EjecutarValidacion");

            return result_Detalle;
        }


        private Response ValidarDetalleObligacionConceptoPagoMigrado(int procedencia, string anio)
        {
            ObligacionRepository obligacionRepository = new ObligacionRepository();
            Response result_Detalle = obligacionRepository.ValidarDetalleObligacionConceptoPagoMigrado(procedencia, anio);

            result_Detalle.ReturnViewValidationsMessage($"Año {anio} - Detalle Observados por no tener el concepto migrado.",
                                                         (int)DetalleObligacionObs.SinConceptoMigrado,
                                                         "Obligaciones", "EjecutarValidacion");

            return result_Detalle;
        }



        public Response Save(Obligacion obligacion, int tipoObserv)
        {
            Response result = new Response();
            ObligacionRepository obligacionRepository = new ObligacionRepository();

            switch ((ObligacionesPagoObs)tipoObserv)
            {
                case ObligacionesPagoObs.SinAlumno:
                    result = obligacionRepository.SaveEstudianteObligacion(obligacion);
                    break;
                case ObligacionesPagoObs.AnioNoValido:
                    result = obligacionRepository.SaveAnioObligacion(obligacion);
                    break;
                case ObligacionesPagoObs.SinPeriodo:
                    result = obligacionRepository.SavePeriodoObligacion(obligacion);
                    break;
                case ObligacionesPagoObs.FchVencRepetido:
                    result = obligacionRepository.SaveFecVencObligacion(obligacion);
                    break;
                case ObligacionesPagoObs.ExisteConOtroMonto:
                    result = obligacionRepository.SaveMontoObligacion(obligacion);
                    break;
                case ObligacionesPagoObs.SinCuotaPagoMigrable:
                    result = obligacionRepository.SaveCuotaPagoObligacion(obligacion);
                    break;
            }

            obligacionRepository.ValidarAlumnoCabeceraObligacionPorID(obligacion.I_RowID);
            obligacionRepository.ValidarAnioEnCabeceraObligacionPorID(obligacion.I_RowID);
            obligacionRepository.ValidarPeriodoEnCabeceraObligacionPorID(obligacion.I_RowID);
            obligacionRepository.ValidarFechaVencimientoCuotaObligacionPorID(obligacion.I_RowID);
            obligacionRepository.ValidarObligacionCuotaPagoMigradaPorObligacionID(obligacion.I_RowID);
            obligacionRepository.ValidarProcedenciaObligacionCuotaPagoPorOblID(obligacion.I_RowID);

            return result.IsDone ? result.Success(false) : result.Error(false);
        }

        public string ObtenerComponenteId(int obsID)
        {
            string componentID;
            ObligacionesPagoObs obligacionesPagoObs = (ObligacionesPagoObs)obsID;

            switch (obligacionesPagoObs)
            {
                case ObligacionesPagoObs.SinAlumno:
                    componentID = "#Cod_alu";
                    break;
                case ObligacionesPagoObs.AnioNoValido:
                    componentID = "#Ano";
                    break;
                case ObligacionesPagoObs.SinPeriodo:
                    componentID = "#I_Periodo";
                    break;
                case ObligacionesPagoObs.FchVencRepetido:
                    componentID = "#Fch_venc";
                    break;
                case ObligacionesPagoObs.ExisteConOtroMonto:
                    componentID = "#Monto";
                    break;
                case ObligacionesPagoObs.SinCuotaPagoMigrable:
                    componentID = "#Cuota_pago";
                    break;
                default:
                    componentID = string.Empty;
                    break;
            }

            return componentID;
        }

    }
}