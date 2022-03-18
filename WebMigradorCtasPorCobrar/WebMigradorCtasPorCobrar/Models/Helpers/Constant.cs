using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace WebMigradorCtasPorCobrar.Models.Helpers
{
    public class Constant
    {
        public static readonly string PREGRADO_TEMPORAL_CUOTA_PAGO = "PRE_CP_DES";
        public static readonly string PREGRADO_TEMPORAL_CONCEPTO_PAGO = "PRE_CP_PRI";
        public static readonly string PREGRADO_TEMPORAL_OBLIGACION = "PRE_EC_OBL";
        public static readonly string PREGRADO_TEMPORAL_DETALLE_OBLIGACION = "PRE_EC_DET";
        public static readonly string PREGRADO_TEMPORAL_ESTADO_CUENTA = "PRE_EC_PRI";
        public static readonly string PREGRADO_TEMPORAL_ESTADO_CUENTA_NRO = "PRE_EC_NRO";

        public static readonly string POSGRADO_TEMPORAL_CUOTA_PAGO = "EUPG_CP_DES";
        public static readonly string POSGRADO_TEMPORAL_CONCEPTO_PAGO = "EUPG_CP_PRI";
        public static readonly string POSGRADO_TEMPORAL_OBLIGACION = "EUPG_EC_OBL";
        public static readonly string POSGRADO_TEMPORAL_DETALLE_OBLIGACION = "EUPG_EC_DET";
        public static readonly string POSGRADO_TEMPORAL_ESTADO_CUENTA = "EUPG_EC_PRI";
        public static readonly string POSGRADO_TEMPORAL_ESTADO_CUENTA_NRO = "EUPG_EC_NRO";

        public static readonly string EUDED_TEMPORAL_CUOTA_PAGO = "EUDED_CP_DES";
        public static readonly string EUDED_TEMPORAL_CONCEPTO_PAGO = "EUDED_CP_PRI";
        public static readonly string EUDED_TEMPORAL_OBLIGACION = "EUDED_EC_OBL";
        public static readonly string EUDED_TEMPORAL_DETALLE_OBLIGACION = "EUDED_EC_DET";
        public static readonly string EUDED_TEMPORAL_ESTADO_CUENTA = "EUDED_EC_PRI";
        public static readonly string EUDED_TEMPORAL_ESTADO_CUENTA_NRO = "EUDED_EC_NRO";

        public static readonly int PREGRADO_MIGRACION_CUOTA_PAGO = 0;
        public static readonly int PREGRADO_MIGRACION_CONCEPTO_PAGO = 0;
        public static readonly int PREGRADO_MIGRACION_OBLIGACION = 0;
        public static readonly int PREGRADO_MIGRACION_DETALLE_OBLIGACION = 0;
        public static readonly int PREGRADO_MIGRACION_ESTADO_CUENTA = 0;
        public static readonly int POSGRADO_MIGRACION_CUOTA_PAGO = 0;
        public static readonly int POSGRADO_MIGRACION_CONCEPTO_PAGO = 0;
        public static readonly int POSGRADO_MIGRACION_OBLIGACION = 0;
        public static readonly int POSGRADO_MIGRACION_DETALLE_OBLIGACION = 0;
        public static readonly int POSGRADO_MIGRACION_ESTADO_CUENTA = 0;
        public static readonly int EUDED_MIGRACION_CUOTA_PAGO = 0;
        public static readonly int EUDED_MIGRACION_CONCEPTO_PAGO = 0;
        public static readonly int EUDED_MIGRACION_OBLIGACION = 0;
        public static readonly int EUDED_MIGRACION_DETALLE_OBLIGACION = 0;
        public static readonly int EUDED_MIGRACION_ESTADO_CUENTA = 0;
    }
}