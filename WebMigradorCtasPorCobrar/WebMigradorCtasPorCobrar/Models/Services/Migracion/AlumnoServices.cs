using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using WebMigradorCtasPorCobrar.Models.Repository.Migracion;
using WebMigradorCtasPorCobrar.Models.Entities.Migracion;
using WebMigradorCtasPorCobrar.Models.Helpers;

namespace WebMigradorCtasPorCobrar.Models.Services.Migracion
{
    public class AlumnoServices
    {
        public IEnumerable<Alumno> Obtener(Procedencia procedencia)
        {
            string schemaDb = Schema.SetSchema(procedencia);

            return AlumnoRepository.Obtener(schemaDb);
        }
    }
}