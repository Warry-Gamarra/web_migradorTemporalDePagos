using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

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
        public static readonly string PAGO_SIN_CABCERA_OBLIGACION_ID= "No se pudo asociar una obligaciòn con el pago registrado";
        public static readonly string PAGO_CON_OBSERVACION_DETALLE = "El pago tiene observaciones de conceptos en el detalle.";
        public static readonly string PAGO_CON_OBSERVACION_CABECERA = "El pago tiene observaciones en la cabecera de la obligacion.";
        public static readonly string PAGO_NO_MIGRADO_CABECERA_SIN_MIGRAR= "El pago de la obligación asociada no pudo migrarse por no tener cabecera migrada.";
    }
    
    
    public class ObservacionOblCab
    {
        public static readonly string MONTO_PAGADO_VS_DETALLE_PAGADO = "";
        public static readonly string MONTO_PAGADO_VS_DETALLE_PAGADO = "";
        public static readonly string MONTO_PAGADO_VS_DETALLE_PAGADO = "";
    }
}