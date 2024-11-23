using System.Collections.Generic;
using WebMigradorCtasPorCobrar.Models.Helpers;
using CrossRepo = WebMigradorCtasPorCobrar.Models.Repository.Migracion.Cross;
using WebMigradorCtasPorCobrar.Models.Repository.Migracion.Obligaciones;
using WebMigradorCtasPorCobrar.Models.ViewModels;
using static WebMigradorCtasPorCobrar.Models.Helpers.Observaciones;

namespace WebMigradorCtasPorCobrar.Models.Services.Migracion.Obligaciones
{
    public class OblCabService
    {
        private readonly ObligacionRepository _obligacionRepository;
        private readonly CrossRepo.ControlRepository _controlRepository;

        public OblCabService()
        {
            _obligacionRepository = new ObligacionRepository();
            _controlRepository = new CrossRepo.ControlRepository();
        }

        #region -- copia y equivalencias ---

        public Response CopiarObligacionesPorAnio(int procedencia, string schema, string anio)
        {

            Response response_obl = _obligacionRepository.CopiarRegistrosCabecera(procedencia, schema, anio);

            response_obl = response_obl.IsDone ? response_obl.Success(false) : response_obl.Error(false);

            response_obl.DeserializeJsonListMessage("Copia TR_Ec_Obl");
            if (response_obl.IsDone && response_obl.ListObjMessage.Count == 4)
            {
                int Total_obl = int.Parse(response_obl.ListObjMessage[0].Value);
                int insertados_obl = int.Parse(response_obl.ListObjMessage[1].Value);
                int actualizados_obl = int.Parse(response_obl.ListObjMessage[2].Value);

                _controlRepository.RegistrarProcesoCopia(Tablas.TR_Ec_Obl, procedencia, anio, Total_obl, insertados_obl + actualizados_obl, 0);
            }

            return response_obl;
        }


        public Response InicializarEstadosValidacion(int procedencia, string anio)
        {
            return _obligacionRepository.InicializarEstadoValidacionObligacionPago(procedencia, anio);
        }

        public Response InicializarEstadosValidacion(int obligacionID)
        {
            return _obligacionRepository.InicializarEstadoValidacionObligacionPagoPorOblID(obligacionID);
        }

        #endregion


        #region -- Valiodaciones --

        public Response ValidarExisteCodigoAlumno(int procedencia, string anio)
        {
            Response result = _obligacionRepository.ValidarAlumnoCabeceraObligacion(procedencia, anio);

            _ = result.ReturnViewValidationsMessage(ObservacionOblCab.CABECERA_SIN_COD_ALU,
                                                    (int)ObligacionesPagoObs.SinAlumno,
                                                    "Obligaciones",
                                                    "EjecutarValidacion");

            return result;
        }

        public Response ValidarExisteCodigoAlumno(int obligacionId)
        {
            Response result = _obligacionRepository.ValidarAlumnoCabeceraObligacionPorID(obligacionId);

            _ = result.ReturnViewValidationsMessage(ObservacionOblCab.CABECERA_SIN_COD_ALU,
                                                    (int)ObligacionesPagoObs.SinAlumno,
                                                    "Obligaciones",
                                                    "EjecutarValidacion");

            return result;
        }


        public Response ValidarAnio(int procedencia, string anio)
        {
            Response result = _obligacionRepository.ValidarAnioEnCabeceraObligacion(procedencia);

            _ = result.ReturnViewValidationsMessage(ObservacionOblCab.ANIO_NO_VALIDO,
                                                    (int)ObligacionesPagoObs.AnioNoValido,
                                                    "Obligaciones",
                                                    "EjecutarValidacion");

            return result;
        }

        public Response ValidarAnio(int obligacionId)
        {
            Response result = _obligacionRepository.ValidarAnioEnCabeceraObligacionPorID(obligacionId);

            _ = result.ReturnViewValidationsMessage(ObservacionOblCab.ANIO_NO_VALIDO,
                                                    (int)ObligacionesPagoObs.AnioNoValido,
                                                    "Obligaciones",
                                                    "EjecutarValidacion");

            return result;
        }


        public Response ValidarPeriodo(int procedencia, string anio)
        {
            Response result = _obligacionRepository.ValidarPeriodoEnCabeceraObligacion(procedencia, anio);

            _ = result.ReturnViewValidationsMessage(ObservacionOblCab.SIN_PERIODO,
                                                    (int)ObligacionesPagoObs.SinPeriodo,
                                                    "Obligaciones",
                                                    "EjecutarValidacion");

            return result;
        }

        public Response ValidarPeriodo(int obligacionId)
        {
            Response result = _obligacionRepository.ValidarPeriodoEnCabeceraObligacionPorID(obligacionId);

            _ = result.ReturnViewValidationsMessage(ObservacionOblCab.SIN_PERIODO,
                                                    (int)ObligacionesPagoObs.SinPeriodo,
                                                    "Obligaciones",
                                                    "EjecutarValidacion");

            return result;
        }


        public Response ValidarFechaVencimiento(int procedencia, string anio)
        {
            Response result = _obligacionRepository.ValidarFechaVencimientoCuotaObligacion(procedencia, anio);

            _ = result.ReturnViewValidationsMessage(ObservacionOblCab.FEC_VENC_DIF_CUOTA_PAGO,
                                                    (int)ObligacionesPagoObs.FchVencCuotaPago,
                                                    "Obligaciones",
                                                    "EjecutarValidacion");

            return result;
        }

        public Response ValidarFechaVencimiento(int obligacionId)
        {
            Response result = _obligacionRepository.ValidarFechaVencimientoCuotaObligacionPorID(obligacionId);

            _ = result.ReturnViewValidationsMessage(ObservacionOblCab.FEC_VENC_DIF_CUOTA_PAGO,
                                                    (int)ObligacionesPagoObs.FchVencCuotaPago,
                                                    "Obligaciones",
                                                    "EjecutarValidacion");

            return result;
        }


        public Response ValidarExisteConOtroMontoEnCtasxCobrar(int procedencia, string anio)
        {
            Response result = _obligacionRepository.ValidarObligacionExisteCtasxCobrar(procedencia, anio);

            _ = result.ReturnViewValidationsMessage(ObservacionOblCab.OBLIG_EXISTE_CON_OTRO_MONTO,
                                                    (int)ObligacionesPagoObs.ExisteConOtroMonto,
                                                    "Obligaciones",
                                                    "EjecutarValidacion");

            return result;
        }

        public Response ValidarExisteConOtroMontoEnCtasxCobrar(int obligacionId)
        {
            Response result = _obligacionRepository.ValidarObligacionExisteCtasxCobrarPorID(obligacionId);

            _ = result.ReturnViewValidationsMessage(ObservacionOblCab.OBLIG_EXISTE_CON_OTRO_MONTO,
                                                    (int)ObligacionesPagoObs.ExisteConOtroMonto,
                                                    "Obligaciones",
                                                    "EjecutarValidacion");

            return result;
        }


        public Response ValidarCuotaPagoDeObligacionMigrada(int procedencia, string anio)
        {
            Response result = _obligacionRepository.ValidarObligacionCuotaPagoMigrada(procedencia, anio);

            _ = result.ReturnViewValidationsMessage(ObservacionOblCab.SIN_CUOTAPAGO_MIGRADA,
                                                    (int)ObligacionesPagoObs.SinCuotaPagoMigrable,
                                                    "Obligaciones",
                                                    "EjecutarValidacion");

            return result;
        }

        public Response ValidarCuotaPagoDeObligacionMigrada(int obligacionId)
        {
            Response result = _obligacionRepository.ValidarObligacionCuotaPagoMigradaPorObligacionID(obligacionId);

            _ = result.ReturnViewValidationsMessage(ObservacionOblCab.SIN_CUOTAPAGO_MIGRADA,
                                                    (int)ObligacionesPagoObs.SinCuotaPagoMigrable,
                                                    "Obligaciones",
                                                    "EjecutarValidacion");

            return result;
        }


        public Response ValidarProcedenciaObligProcecedenciaCuotaPago(int procedencia, string anio)
        {
            Response result = _obligacionRepository.ValidarProcedenciaObligacionCuotaPago(procedencia, anio);

            _ = result.ReturnViewValidationsMessage(ObservacionOblCab.PROCEDENCIA_DIF_PROC_CUOTA,
                                                    (int)ObligacionesPagoObs.ProcedenciaNoCoincide,
                                                    "Obligaciones",
                                                    "EjecutarValidacion");

            return result;
        }

        public Response ValidarProcedenciaObligProcecedenciaCuotaPago(int obligacionId)
        {
            Response result = _obligacionRepository.ValidarProcedenciaObligacionCuotaPagoPorOblID(obligacionId);

            _ = result.ReturnViewValidationsMessage(ObservacionOblCab.PROCEDENCIA_DIF_PROC_CUOTA,
                                                    (int)ObligacionesPagoObs.ProcedenciaNoCoincide,
                                                    "Obligaciones",
                                                    "EjecutarValidacion");

            return result;
        }


        public Response ValidarObligacionTieneConceptosMigrados(int procedencia, string anio)
        {
            Response result = _obligacionRepository.ValidarCabeceraConceptoPagoMigrable(procedencia, anio);

            _ = result.ReturnViewValidationsMessage(ObservacionOblCab.SIN_DET_CONCEPTOS_MIGRABLES,
                                                    (int)ObligacionesPagoObs.SinConceptoMigrable,
                                                    "Obligaciones",
                                                    "EjecutarValidacion");

            return result;
        }

        public Response ValidarObligacionTieneConceptosMigrados(int obligacionId)
        {
            Response result = _obligacionRepository.ValidarCabeceraConceptoPagoMigrablePorOblID(obligacionId);

            _ = result.ReturnViewValidationsMessage(ObservacionOblCab.SIN_DET_CONCEPTOS_MIGRABLES,
                                                    (int)ObligacionesPagoObs.SinConceptoMigrable,
                                                    "Obligaciones",
                                                    "EjecutarValidacion");

            return result;
        }


        public Response ValidarSinObservacionesEnDetalle(int procedencia, string anio)
        {
            Response result = _obligacionRepository.ValidarObservacionDetalle(procedencia, anio);

            _ = result.ReturnViewValidationsMessage(ObservacionOblCab.CONCEPTOS_DETALLE,
                                                    (int)ObligacionesPagoObs.ObsConceptoDetalle,
                                                    "Obligaciones",
                                                    "EjecutarValidacion");

            return result;
        }

        public Response ValidarSinObservacionesEnDetalle(int obligacionId)
        {
            Response result = _obligacionRepository.ValidarObservacionDetallePorOblID(obligacionId);

            _ = result.ReturnViewValidationsMessage(ObservacionOblCab.CONCEPTOS_DETALLE,
                                                    (int)ObligacionesPagoObs.ObsConceptoDetalle,
                                                    "Obligaciones",
                                                    "EjecutarValidacion");

            return result;
        }


        public Response ValidarObservacionesAnioDetalle(int procedencia, string anio)
        {
            Response result = _obligacionRepository.ValidarObservacionAnioDetalle(procedencia, anio);

            _ = result.ReturnViewValidationsMessage(ObservacionOblCab.ANIO_DETALLE,
                                                    (int)ObligacionesPagoObs.ObsAnioDetalle,
                                                    "Obligaciones",
                                                    "EjecutarValidacion");

            return result;
        }

        public Response ValidarObservacionesAnioDetalle(int obligacionId)
        {
            Response result = _obligacionRepository.ValidarObservacionAnioDetallePorOblID(obligacionId);

            _ = result.ReturnViewValidationsMessage(ObservacionOblCab.ANIO_DETALLE,
                                                    (int)ObligacionesPagoObs.ObsAnioDetalle,
                                                    "Obligaciones",
                                                    "EjecutarValidacion");

            return result;
        }


        public Response ValidarObservacionesPeriodoDetalle(int procedencia, string anio)
        {
            Response result = _obligacionRepository.ValidarObservacionPeriodoDetalle(procedencia, anio);

            _ = result.ReturnViewValidationsMessage(ObservacionOblCab.PERIODO_DETALLE,
                                                    (int)ObligacionesPagoObs.ObsPeriodoDetalle,
                                                    "Obligaciones",
                                                    "EjecutarValidacion");

            return result;
        }

        public Response ValidarObservacionesPeriodoDetalle(int obligacionId)
        {
            Response result = _obligacionRepository.ValidarObservacionPeriodoDetallePorOblID(obligacionId);

            _ = result.ReturnViewValidationsMessage(ObservacionOblCab.PERIODO_DETALLE,
                                                    (int)ObligacionesPagoObs.ObsPeriodoDetalle,
                                                    "Obligaciones",
                                                    "EjecutarValidacion");

            return result;
        }


        public Response ValidarTieneDetallesAsociados(int procedencia, string anio)
        {
            Response result = _obligacionRepository.ValidarCabeceraObligacionSinDetalle(procedencia, anio);

            _ = result.ReturnViewValidationsMessage(ObservacionOblCab.SIN_DETALLES,
                                                    (int)ObligacionesPagoObs.SinDetalle,
                                                    "Obligaciones",
                                                    "EjecutarValidacion");

            return result;
        }

        public Response ValidarTieneDetallesAsociados(int obligacionId)
        {
            Response result = _obligacionRepository.ValidarCabeceraObligacionSinDetallePorOblID(obligacionId);

            _ = result.ReturnViewValidationsMessage(ObservacionOblCab.SIN_DETALLES,
                                                    (int)ObligacionesPagoObs.SinDetalle,
                                                    "Obligaciones",
                                                    "EjecutarValidacion");

            return result;
        }


        public Response ValidarNoPagadoConRegistroPago(int procedencia, string anio)
        {
            Response result = _obligacionRepository.ValidarExistePagoParaObligacionNoPagada(procedencia, anio);

            _ = result.ReturnViewValidationsMessage(ObservacionOblCab.PAGO_EN_OBLG_NO_PAGADO,
                                                    (int)ObligacionesPagoObs.PagoEnObligacionNoPagado,
                                                    "Obligaciones",
                                                    "EjecutarValidacion");

            return result;
        }

        public Response ValidarNoPagadoConRegistroPago(int obligacionId)
        {
            Response result = _obligacionRepository.ValidarExistePagoParaObligacionNoPagadaPorOblID(obligacionId);

            _ = result.ReturnViewValidationsMessage(ObservacionOblCab.PAGO_EN_OBLG_NO_PAGADO,
                                                    (int)ObligacionesPagoObs.PagoEnObligacionNoPagado,
                                                    "Obligaciones",
                                                    "EjecutarValidacion");

            return result;
        }


        public Response ValidarCabeceraObligacionRepetida(int procedencia, string anio)
        {
            Response result = _obligacionRepository.ValidarCabeceraObligacionRepetida(procedencia, anio);

            _ = result.ReturnViewValidationsMessage(ObservacionOblCab.OBLIGACION_REPETIDA,
                                                    (int)ObligacionesPagoObs.ObligacionRepetida,
                                                    "Obligaciones",
                                                    "EjecutarValidacion");

            return result;
        }

        public Response ValidarCabeceraOligacionRepetida(int obligacionId)
        {
            Response result = _obligacionRepository.ValidarCabeceraObligacionRepetidaPorOblID(obligacionId);

            _ = result.ReturnViewValidationsMessage(ObservacionOblCab.OBLIGACION_REPETIDA,
                                                    (int)ObligacionesPagoObs.ObligacionRepetida,
                                                    "Obligaciones",
                                                    "EjecutarValidacion");

            return result;
        }


        public Response ValidarNoExistePagoEnObligacionPagada(int procedencia, string anio)
        {
            Response result = _obligacionRepository.ValidarNoExistePagoParaObligacionPagada(procedencia, anio);

            _ = result.ReturnViewValidationsMessage(ObservacionOblCab.SIN_PAGO_EN_OBLIG_PAGADO,
                                                    (int)ObligacionesPagoObs.SinPagoEnObligacioPagada,
                                                    "Obligaciones",
                                                    "EjecutarValidacion");

            return result;
        }

        public Response ValidarNoExistePagoEnObligacionPagada(int obligacionId)
        {
            Response result = _obligacionRepository.ValidarNoExistePagoParaObligacionPagadaPorOblID(obligacionId);

            _ = result.ReturnViewValidationsMessage(ObservacionOblCab.SIN_PAGO_EN_OBLIG_PAGADO,
                                                    (int)ObligacionesPagoObs.MigracionMatricula,
                                                    "Obligaciones",
                                                    "EjecutarValidacion");

            return result;
        }


        public Response ValidarMigracionDatosMatricula(int procedencia, string anio)
        {
            Response result = _obligacionRepository.ValidarAlumnoCabeceraObligacion(procedencia, anio);

            _ = result.ReturnViewValidationsMessage(ObservacionOblCab.MIGRACION_MATRICULA,
                                                    (int)ObligacionesPagoObs.MigracionMatricula,
                                                    "Obligaciones",
                                                    "EjecutarValidacion");

            return result;
        }

        public Response ValidarMigracionDatosMatricula(int obligacionId)
        {
            Response result = _obligacionRepository.ValidarAlumnoCabeceraObligacionPorID(obligacionId);

            _ = result.ReturnViewValidationsMessage(ObservacionOblCab.MIGRACION_MATRICULA,
                                                    (int)ObligacionesPagoObs.MigracionMatricula,
                                                    "Obligaciones",
                                                    "EjecutarValidacion");

            return result;
        }


        #endregion
    
        #region -- Migracion --

        public Response MigrarObligacionesPorAnio(Procedencia procedencia, string anio)
        {
            int procedencia_id = (int)procedencia;

            Response response_obl = _obligacionRepository.MigrarDataObligacionesCtasPorCobrar(procedencia_id, anio);

            response_obl = response_obl.IsDone ? response_obl.Success(false) : response_obl.Error(false);

            response_obl.DeserializeJsonListMessage("Migracion TR_Ec_Obl");
            if (response_obl.IsDone && response_obl.ListObjMessage.Count == 6)
            {
                int total_obl = int.Parse(response_obl.ListObjMessage[0].Value);
                int insertados_obl = int.Parse(response_obl.ListObjMessage[1].Value);
                int actualizados_obl = int.Parse(response_obl.ListObjMessage[2].Value);

                _controlRepository.RegistrarProcesoMigracion(Tablas.TR_Ec_Obl, procedencia_id, anio, total_obl, insertados_obl + actualizados_obl,
                                                              total_obl - (insertados_obl + actualizados_obl));
            }

            return response_obl;
        }
            
        #endregion
    }
}