using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace WebMigradorCtasPorCobrar.Models.Helpers
{
    public enum Procedencia
    {
        Pregrado = 1,
        Posgrado = 2,
        Cuded = 3,
        Tasas = 4,
        Indefinido = 5
    }

    public class Schema
    {
        public static string SetSchema(Procedencia procedencia)
        {
            string schemaName;

            switch (procedencia)
            {
                case Procedencia.Pregrado:
                    schemaName = "pregrado";
                    break;
                case Procedencia.Posgrado:
                    schemaName = "eupg";
                    break;
                case Procedencia.Cuded:
                    schemaName = "euded";
                    break;
                case Procedencia.Indefinido:
                    schemaName = "";
                    break;
                default:
                    schemaName = "dbo";
                    break;
            }

            return schemaName;
        }
    }
}
