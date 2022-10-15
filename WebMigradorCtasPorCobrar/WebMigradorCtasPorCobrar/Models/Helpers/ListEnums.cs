using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace WebMigradorCtasPorCobrar.Models.Helpers
{
    public class ListEnums
    {
        public int Value { get; set; }
        public string Descripcion { get; set; }

        public static IEnumerable<ListEnums> Procedencias()
        {
            List<ListEnums> result = new List<ListEnums>();

            foreach (var item in Enum.GetValues(typeof(Procedencia)).Cast<Procedencia>())
            {
                result.Add(new ListEnums()
                {
                    Value = (int)item,
                    Descripcion = item.ToString().ToUpper()
                });
            }

            return result;
        }

        public static IEnumerable<ListEnums> Tablas()
        {
            List<ListEnums> result = new List<ListEnums>();

            foreach (var item in Enum.GetValues(typeof(Tablas)).Cast<Tablas>())
            {
                result.Add(new ListEnums()
                {
                    Value = (int)item,
                    Descripcion = item.ToString()
                });
            }

            return result;
        }

    }
}