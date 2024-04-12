using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace WebMigradorCtasPorCobrar.Models.Helpers
{
    public enum FaseMigracion
    {
        Copiar = 1,
        Validar = 2,
        Migrar = 3
    }
}