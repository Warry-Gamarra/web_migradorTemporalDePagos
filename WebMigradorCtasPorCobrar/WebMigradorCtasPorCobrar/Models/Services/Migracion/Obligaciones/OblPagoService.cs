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

        public Response CopiarPagoObligacionesPorAnio(int procedencia, string schema, string anio){


            Response response_pago = _pagoObligacionRepository.CopiarRegistrosPago(procedencia, schema, anio);
            Response _ = _pagoObligacionRepository.VincularCabeceraPago(procedencia, anio);

            response_pago = response_pago.IsDone ? response_pago.Success(false) : response_pago.Error(false);

            response_pago.DeserializeJsonListMessage("Copia TR_Ec_Det_Pagos");
            if (response_pago.IsDone && response_pago.ListObjMessage.Count == 4)
            {
                int Total_pag = int.Parse(response_pago.ListObjMessage[0].Value);
                int insertados_pag = int.Parse(response_pago.ListObjMessage[1].Value);
                int actualizados_pag = int.Parse(response_pago.ListObjMessage[2].Value);

                _controlRepository.RegistrarProcesoCopia(Tablas.TR_Ec_Det_Pagos, procedencia, anio, Total_pag, insertados_pag + actualizados_pag, 0);
            }

            return response_pago; 
        }

        public Response InicializarEstadosValidacion(int procedencia, string anio)
        {
            return _pagoObligacionRepository.InicializarEstadoValidacion(procedencia, anio);
        }

        public Response InicializarEstadosValidacion(int obligacionID)
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


        public Response ValidarDetalleObligObservado(int procedencia, string anio)
        {
            Response result = _pagoObligacionRepository.ValidarDetalleObligacionObservada(procedencia, anio);

            _ = result.ReturnViewValidationsMessage(ObservacionPago.PAGO_CON_OBSERVACION_DETALLE,
                                                    (int)PagoObligacionObs.DetalleObservado,
                                                    "Obligaciones",
                                                    "EjecutarValidacion");

            return result;
        }

        public Response ValidarDetalleObligObservado(int obligacionId)
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


        public Response ValidarFechaPago(int procedencia, string anio)
        {
            Response result = _pagoObligacionRepository.ValidarFechaPago(procedencia, anio);

            _ = result.ReturnViewValidationsMessage(ObservacionPago.FECHA_PAGO_ERROR,
                                                    (int)PagoObligacionObs.MigracionCabecera,
                                                    "Obligaciones",
                                                    "EjecutarValidacion");

            return result;
        }

        public Response ValidarFechaPago(int obligacionId)
        {
            Response result = _pagoObligacionRepository.ValidarFechaPagoPorOblID(obligacionId);

            _ = result.ReturnViewValidationsMessage(ObservacionPago.FECHA_PAGO_ERROR,
                                                    (int)PagoObligacionObs.MigracionCabecera,
                                                    "Obligaciones",
                                                    "EjecutarValidacion");

            return result;
        }

        #endregion

        #region -- Migracion --

        public Response MigrarObligacionesPorAnio(Procedencia procedencia, string anio)
        {
            int procedencia_id = (int)procedencia;

            Response response_pago = _pagoObligacionRepository.MigrarDataPagoObligacionesCtasPorCobrarPorAnio(procedencia_id, anio);

            response_pago = response_pago.IsDone ? response_pago.Success(false) : response_pago.Error(false);

            response_pago.DeserializeJsonListMessage("Migracion TR_Ec_Det_Pago");
            if (response_pago.IsDone && response_pago.ListObjMessage.Count == 5)
            {
                int total_pag = int.Parse(response_pago.ListObjMessage[0].Value);
                int insertados_pag = int.Parse(response_pago.ListObjMessage[1].Value);
                int insertados_det = int.Parse(response_pago.ListObjMessage[2].Value);
                int actualizados_pag = int.Parse(response_pago.ListObjMessage[3].Value);
                int actualizados_det = int.Parse(response_pago.ListObjMessage[4].Value);

                _controlRepository.RegistrarProcesoMigracion(Tablas.TR_Ec_Det_Pagos, procedencia_id, anio, total_pag, insertados_pag + actualizados_pag,
                                                              total_pag - (insertados_pag + actualizados_pag));
            }

            return response_pago;
        }
            
        #endregion
    }
}
