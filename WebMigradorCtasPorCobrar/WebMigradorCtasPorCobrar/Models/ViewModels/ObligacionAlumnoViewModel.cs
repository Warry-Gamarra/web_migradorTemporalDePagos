using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using WebMigradorCtasPorCobrar.Models.Entities.Migracion;

namespace WebMigradorCtasPorCobrar.Models.ViewModels
{
    public class ObligacionAlumnoViewModel
    {
        public Alumno Estudiante { get; set; }
        public IList<Obligacion> Obligaciones { get; set; }
    }
}