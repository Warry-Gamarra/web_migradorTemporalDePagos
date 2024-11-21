using WebMigradorCtasPorCobrar.Models.Helpers;
using WebMigradorCtasPorCobrar.Models.Repository.Migracion.Obligaciones;
using WebMigradorCtasPorCobrar.Models.ViewModels;
using static WebMigradorCtasPorCobrar.Models.Helpers.Observaciones;

namespace WebMigradorCtasPorCobrar.Models.Services.Migracion.Obligaciones
{
    public class OblDetService
    {
        private readonly ObligacionRepository _obligacionRepository;

        public OblDetService()
        {
            _obligacionRepository = new ObligacionRepository();
        }

        #region -- copia y equivalencias ---

        public Response CopiarObligacionesPorAnio(int procedencia, string schema, string anio)
        {

            Response response_det = _obligacionRepository.CopiarRegistrosDetalle(procedencia, schema, anio);
            Response _ = _obligacionRepository.VincularCabeceraDetalle(procedencia, anio);

            response_det = response_det.IsDone ? response_det.Success(false) : response_det.Error(false);

            response_det.DeserializeJsonListMessage("Copia TR_Ec_Det");
            if (response_det.IsDone && response_det.ListObjMessage.Count == 4)
            {
                int total_det = int.Parse(response_det.ListObjMessage[0].Value);
                int insertados_det = int.Parse(response_det.ListObjMessage[1].Value);
                int actualizados_det = int.Parse(response_det.ListObjMessage[2].Value);

                _controlRepository.RegistrarProcesoCopia(Tablas.TR_Ec_Det, procedencia, anio, total_det, insertados_det + actualizados_det, 0);
            }

            return response_det;
        }

        
        public Response InicializarEstadosValidacionCabecera(int procedencia, string anio)
        {
            return _obligacionRepository.InicializarEstadoValidacionDetalleObligacion(procedencia, anio);
        }

        public Response InicializarEstadosValidacionCabecera(int obligacionID)
        {
            return _obligacionRepository.InicializarEstadoValidacionDetalleObligacionPagoPorOblID(obligacionID);
        }


        #endregion


        #region --Validaciones --

        public Response ValidarAnioIgualAnioConcepto(int procedencia, string anio)
        {
            Response result = _obligacionRepository.ValidarAnioDetalleAnioConcepto(procedencia, anio);

            _ = result.ReturnViewValidationsMessage(ObservacionOblDet.ANIO_DETALLE_ANIO_CONCEPTO,
                                                    (int)DetalleObligacionObs.AnioDetalleConcepto,
                                                    "Obligaciones",
                                                    "EjecutarValidacion");

            return result;
        }

        public Response ValidarAnioIgualAnioConcepto(int obligacionId)
        {
            Response result = _obligacionRepository.ValidarAnioDetalleAnioConceptoPorOblID(obligacionId);

            _ = result.ReturnViewValidationsMessage(ObservacionOblDet.ANIO_DETALLE_ANIO_CONCEPTO,
                                                    (int)DetalleObligacionObs.AnioDetalleConcepto,
                                                    "Obligaciones",
                                                    "EjecutarValidacion");

            return result;
        }


        public Response ValidarPeriodoIgualPeriodoConcepto(int procedencia, string anio)
        {
            Response result = _obligacionRepository.ValidarPeriodoDetallePeriodoConcepto(procedencia, anio);

            _ = result.ReturnViewValidationsMessage(ObservacionOblDet.PERIODO_DETALLE_PERIODO_CONCEPTO,
                                                    (int)DetalleObligacionObs.PeriodoDetalleConcepto,
                                                    "Obligaciones",
                                                    "EjecutarValidacion");

            return result;
        }

        public Response ValidarPeriodoIgualPeriodoConcepto(int obligacionId)
        {
            Response result = _obligacionRepository.ValidarPeriodoDetallePeriodoConceptoPorOblID(obligacionId);

            _ = result.ReturnViewValidationsMessage(ObservacionOblDet.PERIODO_DETALLE_PERIODO_CONCEPTO,
                                                    (int)DetalleObligacionObs.PeriodoDetalleConcepto,
                                                    "Obligaciones",
                                                    "EjecutarValidacion");

            return result;
        }


        public Response ValidarTieneConceptoPagoMigrado(int procedencia, string anio)
        {
            Response result = _obligacionRepository.ValidarDetalleConceptoPagoMigrado(procedencia, anio);

            _ = result.ReturnViewValidationsMessage(ObservacionOblDet.CONCEPTO_PAGO_SIN_MIGRAR,
                                                    (int)DetalleObligacionObs.SinConceptoMigrado,
                                                    "Obligaciones",
                                                    "EjecutarValidacion");

            return result;
        }

        public Response ValidarTieneConceptoPagoMigrado(int obligacionId)
        {
            Response result = _obligacionRepository.ValidarDetalleConceptoPagoMigradoPorOblID(obligacionId);

            _ = result.ReturnViewValidationsMessage(ObservacionOblDet.CONCEPTO_PAGO_SIN_MIGRAR,
                                                    (int)DetalleObligacionObs.SinConceptoMigrado,
                                                    "Obligaciones",
                                                    "EjecutarValidacion");

            return result;
        }


        public Response ValidarConceptoExisteEnCatalogo(int procedencia, string anio)
        {
            Response result = _obligacionRepository.ValidarDetalleExisteConceptoPago(procedencia, anio);

            _ = result.ReturnViewValidationsMessage(ObservacionOblDet.CONCEPTO_PAGO_NO_EXISTE,
                                                    (int)DetalleObligacionObs.ConceptoNoExiste,
                                                    "Obligaciones",
                                                    "EjecutarValidacion");

            return result;
        }

        public Response ValidarConceptoExisteEnCatalogo(int obligacionId)
        {
            Response result = _obligacionRepository.ValidarDetalleExisteConceptoPagoPorOblID(obligacionId);

            _ = result.ReturnViewValidationsMessage(ObservacionOblDet.CONCEPTO_PAGO_NO_EXISTE,
                                                    (int)DetalleObligacionObs.ConceptoNoExiste,
                                                    "Obligaciones",
                                                    "EjecutarValidacion");

            return result;
        }


        public Response ValidarCuotaPagoIgualCuotaPagoConcepto(int procedencia, string anio)
        {
            Response result = _obligacionRepository.ValidarCuotaDetalleCuotaConcepto(procedencia, anio);

            _ = result.ReturnViewValidationsMessage(ObservacionOblDet.CUOTA_DETALLE_DIF_CUOTA_CONCEPTO,
                                                    (int)DetalleObligacionObs.CuotaConceptoNoCoincide,
                                                    "Obligaciones",
                                                    "EjecutarValidacion");

            return result;
        }

        public Response ValidarCuotaPagoIgualCuotaPagoConcepto(int obligacionId)
        {
            Response result = _obligacionRepository.ValidarCuotaDetalleCuotaConceptoPorOblID(obligacionId);

            _ = result.ReturnViewValidationsMessage(ObservacionOblDet.CUOTA_DETALLE_DIF_CUOTA_CONCEPTO,
                                                    (int)DetalleObligacionObs.CuotaConceptoNoCoincide,
                                                    "Obligaciones",
                                                    "EjecutarValidacion");

            return result;
        }


        public Response ValidarAnioEsUnNumero(int procedencia, string anio)
        {
            Response result = _obligacionRepository.ValidarAnioDetalleNumerico(procedencia, anio);

            _ = result.ReturnViewValidationsMessage(ObservacionOblDet.ANIO_NO_VALIDO,
                                                    (int)DetalleObligacionObs.AnioNoValido,
                                                    "Obligaciones",
                                                    "EjecutarValidacion");

            return result;
        }

        public Response ValidarAnioEsUnNumero(int obligacionId)
        {
            Response result = _obligacionRepository.ValidarAnioDetalleNumericoPorOblID(obligacionId);

            _ = result.ReturnViewValidationsMessage(ObservacionOblDet.ANIO_NO_VALIDO,
                                                    (int)DetalleObligacionObs.AnioNoValido,
                                                    "Obligaciones",
                                                    "EjecutarValidacion");

            return result;
        }


        public Response ValidarPeriodoExisteCatologoCtas(int procedencia, string anio)
        {
            Response result = _obligacionRepository.ValidarPeriodoDetalleEquivPeriodoCtas(procedencia, anio);

            _ = result.ReturnViewValidationsMessage(ObservacionOblDet.PERIODO_SIN_EQUIVALENCIA,
                                                    (int)DetalleObligacionObs.AnioDetalleConcepto,
                                                    "Obligaciones",
                                                    "EjecutarValidacion");

            return result;
        }

        public Response ValidarPeriodoExisteCatologoCtas(int obligacionId)
        {
            Response result = _obligacionRepository.ValidarPeriodoDetalleEquivPeriodoCtasPorOblID(obligacionId);

            _ = result.ReturnViewValidationsMessage(ObservacionOblDet.PERIODO_SIN_EQUIVALENCIA,
                                                    (int)DetalleObligacionObs.AnioDetalleConcepto,
                                                    "Obligaciones",
                                                    "EjecutarValidacion");

            return result;
        }


        public Response ValidarTotalMontoIgualMontoCabecera(int procedencia, string anio)
        {
            Response result = _obligacionRepository.ValidarMontoDetalleMontoCabecera(procedencia, anio);

            _ = result.ReturnViewValidationsMessage(ObservacionOblDet.TOTAL_MONTO_DETALLE_MONTO_CAB,
                                                    (int)DetalleObligacionObs.MontoDetalleMontoCab,
                                                    "Obligaciones",
                                                    "EjecutarValidacion");

            return result;
        }

        public Response ValidarTotalMontoIgualMontoCabecera(int obligacionId)
        {
            Response result = _obligacionRepository.ValidarMontoDetalleMontoCabeceraPorOblID(obligacionId);

            _ = result.ReturnViewValidationsMessage(ObservacionOblDet.TOTAL_MONTO_DETALLE_MONTO_CAB,
                                                    (int)DetalleObligacionObs.MontoDetalleMontoCab,
                                                    "Obligaciones",
                                                    "EjecutarValidacion");

            return result;
        }


        public Response ValidarSinObligacionID(int procedencia, string anio)
        {
            Response result = _obligacionRepository.ValidarDetalleSinCabeceraObligacionID(procedencia, anio);

            _ = result.ReturnViewValidationsMessage(ObservacionOblDet.SIN_CABECERA_ID,
                                                    (int)DetalleObligacionObs.SinObligacionCabID,
                                                    "Obligaciones",
                                                    "EjecutarValidacion");

            return result;
        }


        public Response ValidarMigracionCabecera(int procedencia, string anio)
        {
            Response result = _obligacionRepository.ValidarMigracionCabecera(procedencia, anio);

            _ = result.ReturnViewValidationsMessage(ObservacionOblDet.CABECERA_NO_MIGRADA,
                                                    (int)DetalleObligacionObs.MigracionCabecera,
                                                    "Obligaciones",
                                                    "EjecutarValidacion");

            return result;
        }

        public Response ValidarMigracionCabecera(int obligacionId)
        {
            Response result = _obligacionRepository.ValidarMigracionCabeceraPorOblIDPorOblID(obligacionId);

            _ = result.ReturnViewValidationsMessage(ObservacionOblDet.CABECERA_NO_MIGRADA,
                                                    (int)DetalleObligacionObs.MigracionCabecera,
                                                    "Obligaciones",
                                                    "EjecutarValidacion");

            return result;
        }


        #endregion


        #region -- Migracion --

        public Response MigrarObligacionesPorAnio(Procedencia procedencia, string anio, Response result_cab)
        {
            int procedencia_id = (int)procedencia;

            Response response_det = result_cab.IsDone ? result_cab.Success(false) : result_cab.Error(false);

            if (response_det.IsDone && response_det.ListObjMessage.Count == 6)
            {
                int total_det = int.parse(response_det.ListObjMessage[3].Value)
                int insertados_det = int.Parse(response_det.ListObjMessage[4].Value);
                int actualizados_det = int.Parse(response_det.ListObjMessage[5].Value);

                _controlRepository.RegistrarProcesoMigracion(Tablas.TR_Ec_Det, procedencia, anio, total_det, insertados_det + actualizados_det,
                                                              total_det - (insertados_det + actualizados_det));
            }

            return response_det;
        }
            


        #endregion
    }
}
