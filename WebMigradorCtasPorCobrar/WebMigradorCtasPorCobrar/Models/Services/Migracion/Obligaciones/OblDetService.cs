using WebMigradorCtasPorCobrar.Models.Helpers;
using WebMigradorCtasPorCobrar.Models.Repository.Migracion.Obligaciones;
using WebMigradorCtasPorCobrar.Models.ViewModels;
using static WebMigradorCtasPorCobrar.Models.Helpers.Observaciones;

namespace WebMigradorCtasPorCobrar.Models.Services.Migracion.Obligaciones
{
    public class OblDetService
    {
        public readonly ObligacionRepository _obligacionRepository;

        public OblDetService()
        {
            _obligacionRepository = new ObligacionRepository();
        }

        #region -- copia y equivalencias ---
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
    }
}
