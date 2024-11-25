namespace WebMigradorCtasPorCobrar.Models.Helpers
{
    public class Constant
    {
        public static readonly string PREGRADO_TEMPORAL_CODIGOS_BNC = "'0635', '0636', '0637', '0638', '0639'";
        public static readonly string POSGRADO_TEMPORAL_CODIGOS_BNC = "'0670', '0671', '0672', '0673', '0674', '0675', " +
                                                                      "'0676', '0677', '0678', '0679', '0680', '0681', " +
                                                                      "'0682', '0683', '0695', '0696', '0697', '0698'";
        public static readonly string EUDED_TEMPORAL_CODIGOS_BNC = "'0658', '0685', '0687', '0688'";
        public static readonly string PROLICE_TEMPORAL_CODIGOS_BNC = "'0689', '0690'";
        public static readonly string PROCUNED_TEMPORAL_CODIGOS_BNC = "'0691', '0692'";
    }


    public class ObservacionPago
    {
        public static readonly string MONTO_PAGO_VS_DETALLE_PAGADO = "El monto pagado no corresponde con la suma de los conceptos relacionados en el detalle";
        public static readonly string PAGO_EXISTE_CTAS_OTRO_BNC = "Se encontró un pago para la misma obligación con una entidad diferente en la BD destino.";
        public static readonly string PAGO_SIN_CABECERA_OBLIGACION_ID = "No se pudo asociar una obligaciòn con el pago registrado";
        public static readonly string PAGO_CON_OBSERVACION_DETALLE = "El pago tiene observaciones de conceptos en el detalle.";
        public static readonly string PAGO_CON_OBSERVACION_CABECERA = "El pago tiene observaciones en la cabecera de la obligacion.";
        public static readonly string PAGO_NO_MIGRADO_CABECERA_SIN_MIGRAR = "El pago de la obligación no pudo migrarse por no tener cabecera migrada.";
        public static readonly string FECHA_PAGO_ERROR = "La columna fch_pago no tiene un valor de fecha válido.";
    }


    public class ObservacionOblCab
    {
        public static readonly string CABECERA_SIN_COD_ALU = "No se encontró un alumno para el codigo de alumno y carrera de la obligación.";
        public static readonly string ANIO_NO_VALIDO = "El AÑO de la obligacion no es un valor válido.";
        public static readonly string SIN_PERIODO = "El PERIODO de la obligación no tiene equivalencia en base de datos de Ctas por cobrar.";
        public static readonly string FEC_VENC_ERROR = "La fecha de vencimiento no es un valor de fecha válido.";
        public static readonly string OBLIG_EXISTE_CON_OTRO_MONTO = "La obligación ya existe en la base de datos de destino con otro monto.";
        public static readonly string SIN_CUOTAPAGO_MIGRADA = "La obligación tiene una cuota de pago sin migrar.";
        public static readonly string PROCEDENCIA_DIF_PROC_CUOTA = "La procedencia de la obligación no coincide con la procedencia de la cuota de pago.";
        public static readonly string SIN_DET_CONCEPTOS_MIGRABLES = "La obligación tiene conceptos que no pueden ser migrados.";
        public static readonly string ANIO_DETALLE = "La obligación tiene observaciones de año en el detalle.";
        public static readonly string PERIODO_DETALLE = "La obligación tiene observaciones de periodo en el detalle.";
        public static readonly string CONCEPTOS_DETALLE = "La obligación tiene observaciones de conceptos en el detalle.";
        public static readonly string SIN_DETALLES = "La obligación no tiene asociado registros en el detalle.";
        public static readonly string REMOVIDO = "El registro se encuentra con estado Eliminado y no será parte de la migración.";
        public static readonly string PAGO_EN_OBLG_NO_PAGADO = "Se encontró un pago para una obligación con estado Pagado = NO.";
        public static readonly string OBLIGACION_REPETIDA = "La cabecera de obligacion se encuentra duplicada.";
        public static readonly string SIN_PAGO_EN_OBLIG_PAGADO = "La cabecera de obligacion con estado pagado = SI no tiene un pago asociado.";
        public static readonly string MIGRACION_MATRICULA = "La cabecera de obligación no pudo asociarse registrarse en la tabla de matricula.";
    }


    public class ObservacionOblDet
    {
        public static readonly string ANIO_DETALLE_ANIO_CONCEPTO = "El año del concepto en el detalle de la obligación no coincide con el año del concepto en cp_pri";
        public static readonly string PERIODO_DETALLE_PERIODO_CONCEPTO = "El periodo del concepto en el detalle de la obligación, no coincide con el periodo del concepto en cp_pri.";
        public static readonly string CABECERA_NO_MIGRABLE = "La obligación correspondiente no es migrable.";
        public static readonly string CONCEPTO_PAGO_SIN_MIGRAR = "El detalle de pago tiene un concepto de pago sin migrar.";
        public static readonly string CONCEPTO_PAGO_NO_EXISTE = "El concepto en el detalle de la obligación no existe en el catálogo de conceptos.";
        public static readonly string CUOTA_DETALLE_DIF_CUOTA_CONCEPTO = "La cuota de pago del detalle no es la misma que la cuota de pago del concepto.";
        public static readonly string ANIO_NO_VALIDO = "El año en el detalle de la obligacion no es un valor válido";
        public static readonly string PERIODO_SIN_EQUIVALENCIA = "Periodo en el detalle la obligacion no tiene equivalencia en la base de datos de Ctas por cobrar";
        public static readonly string TOTAL_MONTO_DETALLE_MONTO_CAB = "El monto acumulado de los conceptos en el detalle no corresponde con el monto indicado en la obligación";
        public static readonly string SIN_CABECERA_ID = "El detalle de la obligacion no tiene asociado un ID de la obligacion.";
        public static readonly string CABECERA_NO_MIGRADA = "El detalle de la obligación asociada no pudo migrarse por no tener cabecera migrada.";
        public static readonly string FEC_VENC_ERROR = "La columna fch_venc no tiene un valor de fecha válido.";
    }

}