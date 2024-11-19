using System.Collections.Generic;
using WebMigradorCtasPorCobrar.Models.Helpers;
using WebMigradorCtasPorCobrar.Models.Repository.Migracion.Obligaciones;
using WebMigradorCtasPorCobrar.Models.ViewModels;
using static WebMigradorCtasPorCobrar.Models.Helpers.Observaciones;

namespace WebMigradorCtasPorCobrar.Models.Services.Migracion.Obligaciones
{
    public class OblPagoService
    {
        public readonly PagoObligacionRepository _pagoObligacionRepository;

        public OblPagoService()
        {
            _pagoObligacionRepository = new PagoObligacionRepository();
        }

        #region -- copia y equivalencias ---

        public List<Response> CopiarPagoObligacionesPorAnio(int procedencia, string schema, string anio){

            List<Response> result = new List<Response>();

            Response result_copia = _pagoObligacionRepository.CopiarRegistrosPago(procedencia, schema, anio);
            Response result_vincular = _pagoObligacionRepository.VincularCabeceraPago(procedencia, anio);

            result_copia = result_copia.IsDone ? result_copia.Success(false) : result_copia.Error(false);
            result_vincular = result_vincular.IsDone ? result_vincular.Success(false) : result_vincular.Error(false);

            result.Add(result_copia);
            result.Add(result_vincular);

            return result; 
        }

        public Response InicializarEstadosValidacionCabecera(int procedencia, string anio)
        {
            return _pagoObligacionRepository.InicializarEstadoValidacion(procedencia, anio);
        }

        public Response InicializarEstadosValidacionCabecera(int obligacionID)
        {
            return _pagoObligacionRepository.InicializarEstadoValidacionPorOblID(obligacionID);
        }


        #endregion


        #region -- Validaciones --

        public Response ValidarMontoPagadoIgualTotalMontoPagado(int procedencia, string anio)
        {
            Response result = _pagoObligacionRepository.ValidarTotalMontoPagadoDetalle(procedencia, anio);

            _ = result.ReturnViewValidationsMessage(ObservacionPago.MONTO_PAGO_VS_DETALLE_PAGADO,
                                                    (int)PagoObligacionObs.MontoPagadoDetalle,
                                                    "Obligaciones",
                                                    "EjecutarValidacion");

            return result;
        }

        public Response ValidarMontoPagadoIgualTotalMontoPagado(int obligacionId)
        {
            Response result = _pagoObligacionRepository.ValidarTotalMontoPagadoDetallePorOblID(obligacionId);

            _ = result.ReturnViewValidationsMessage(ObservacionPago.MONTO_PAGO_VS_DETALLE_PAGADO,
                                                    (int)PagoObligacionObs.MontoPagadoDetalle,
                                                    "Obligaciones",
                                                    "EjecutarValidacion");

            return result;
        }


        public Response ValidarExisteEnDestinoConOtroBanco(int procedencia, string anio)
        {
            Response result = _pagoObligacionRepository.ValidarPagoExisteEnDestinoConOtroBanco(procedencia, anio);

            _ = result.ReturnViewValidationsMessage(ObservacionPago.PAGO_EXISTE_CTAS_OTRO_BNC,
                                                    (int)PagoObligacionObs.ExisteEnDestinoConOtroBanco,
                                                    "Obligaciones",
                                                    "EjecutarValidacion");

            return result;
        }

        public Response ValidarExisteEnDestinoConOtroBanco(int obligacionId)
        {
            Response result = _pagoObligacionRepository.ValidarPagoExisteEnDestinoConOtroBancoPorOblID(obligacionId);

            _ = result.ReturnViewValidationsMessage(ObservacionPago.PAGO_EXISTE_CTAS_OTRO_BNC,
                                                    (int)PagoObligacionObs.ExisteEnDestinoConOtroBanco,
                                                    "Obligaciones",
                                                    "EjecutarValidacion");

            return result;
        }


        public Response ValidarDetalleOblgObservedo(int procedencia, string anio)
        {
            Response result = _pagoObligacionRepository.ValidarDetalleObligacionObservada(procedencia, anio);

            _ = result.ReturnViewValidationsMessage(ObservacionPago.PAGO_CON_OBSERVACION_DETALLE,
                                                    (int)PagoObligacionObs.DetalleObservado,
                                                    "Obligaciones",
                                                    "EjecutarValidacion");

            return result;
        }

        public Response ValidarDetalleOblgObservedo(int obligacionId)
        {
            Response result = _pagoObligacionRepository.ValidarDetalleObligacionObservadaPorOblID(obligacionId);

            _ = result.ReturnViewValidationsMessage(ObservacionPago.PAGO_CON_OBSERVACION_DETALLE,
                                                    (int)PagoObligacionObs.MontoPagadoDetalle,
                                                    "Obligaciones",
                                                    "EjecutarValidacion");

            return result;
        }


        public Response ValidarCabeceraObligacionObservada(int procedencia, string anio)
        {
            Response result = _pagoObligacionRepository.ValidarCabeceraObligacionObservada(procedencia, anio);

            _ = result.ReturnViewValidationsMessage(ObservacionPago.PAGO_CON_OBSERVACION_CABECERA,
                                                    (int)PagoObligacionObs.CabObligacionObservada,
                                                    "Obligaciones",
                                                    "EjecutarValidacion");

            return result;
        }

        public Response ValidarCabeceraObligacionObservada(int obligacionId)
        {
            Response result = _pagoObligacionRepository.ValidarCabeceraObligacionObservadaPorOblID(obligacionId);

            _ = result.ReturnViewValidationsMessage(ObservacionPago.PAGO_CON_OBSERVACION_CABECERA,
                                                    (int)PagoObligacionObs.CabObligacionObservada,
                                                    "Obligaciones",
                                                    "EjecutarValidacion");

            return result;
        }


        public Response ValidarMigracionCabeceraObligacion(int procedencia, string anio)
        {
            Response result = _pagoObligacionRepository.ValidarMigracionCabeceraObligacion(procedencia, anio);

            _ = result.ReturnViewValidationsMessage(ObservacionPago.PAGO_NO_MIGRADO_CABECERA_SIN_MIGRAR,
                                                    (int)PagoObligacionObs.MigracionCabecera,
                                                    "Obligaciones",
                                                    "EjecutarValidacion");

            return result;
        }

        public Response ValidarMigracionCabeceraObligacion(int obligacionId)
        {
            Response result = _pagoObligacionRepository.ValidarMigracionCabeceraObligacionPorOblID(obligacionId);

            _ = result.ReturnViewValidationsMessage(ObservacionPago.PAGO_NO_MIGRADO_CABECERA_SIN_MIGRAR,
                                                    (int)PagoObligacionObs.MigracionCabecera,
                                                    "Obligaciones",
                                                    "EjecutarValidacion");

            return result;
        }


        public Response ValidarCabeceraObligacionID(int procedencia, string anio)
        {
            Response result = _pagoObligacionRepository.ValidarPagoSinObligacionID(procedencia, anio);

            _ = result.ReturnViewValidationsMessage(ObservacionPago.PAGO_SIN_CABECERA_OBLIGACION_ID,
                                                    (int)PagoObligacionObs.SinObligacionId,
                                                    "Obligaciones",
                                                    "EjecutarValidacion");

            return result;
        }

        #endregion
    }
}