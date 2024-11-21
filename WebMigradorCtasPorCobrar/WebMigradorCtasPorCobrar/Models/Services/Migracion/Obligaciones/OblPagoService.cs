using System.Collections.Generic;
using WebMigradorCtasPorCobrar.Models.Helpers;
using CrossRepo = WebMigradorCtasPorCobrar.Models.Repository.Migracion.Cross;
using WebMigradorCtasPorCobrar.Models.Repository.Migracion.Obligaciones;
using WebMigradorCtasPorCobrar.Models.ViewModels;
using static WebMigradorCtasPorCobrar.Models.Helpers.Observaciones;

namespace WebMigradorCtasPorCobrar.Models.Services.Migracion.Obligaciones
{
    public class OblPagoService
    {
        private readonly OblPagoRepository _pagoObligacionRepository;
        private readonly CrossRepo.ControlRepository _controlRepository;

        public OblPagoService()
        {
            _pagoObligacionRepository = new OblPagoRepository();
            _controlRepository = new CrossRepo.ControlRepository();
        }

        #region -- copia y equivalencias ---

        public List<Response> CopiarPagoObligacionesPorAnio(int procedencia, string schema, string anio){

            List<Response> result = new List<Response>();

            Response result_copia = _pagoObligacionRepository.CopiarRegistrosPago(procedencia, schema, anio);
            Response _ = _pagoObligacionRepository.VincularCabeceraPago(procedencia, anio);

            result_copia = result_copia.IsDone ? result_copia.Success(false) : result_copia.Error(false);

            result.Add(result_copia);

            result_copia.DeserializeJsonListMessage("Copia TR_Ec_Det_Pagos");
            if (result_copia.IsDone && result_copia.ListObjMessage.Count == 4)
            {
                int Total_pag = int.Parse(result_copia.ListObjMessage[0].Value);
                int insertados_pag = int.Parse(result_copia.ListObjMessage[1].Value);
                int actualizados_pag = int.Parse(result_copia.ListObjMessage[2].Value);

                _controlRepository.RegistrarProcesoCopia(Tablas.TR_Ec_Det_Pagos, procedencia, anio, Total_pag, insertados_pag + actualizados_pag, 0);
            }

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