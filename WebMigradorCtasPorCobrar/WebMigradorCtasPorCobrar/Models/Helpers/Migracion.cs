using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace WebMigradorCtasPorCobrar.Models.Helpers
{
    public enum FasesMigracion
    {
        Copia_datos = 1,
        Valifacion = 2,
        Migrar_data = 3
    }
}