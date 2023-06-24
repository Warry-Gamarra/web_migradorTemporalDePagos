using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using Migra = WebMigradorCtasPorCobrar.Models.Entities.Migracion;
using Repo = WebMigradorCtasPorCobrar.Models.Entities.UnfvRepositorio;

namespace WebMigradorCtasPorCobrar.Models.ViewModels
{
    public class DatosEstudianteViewModel
    {
        public Migra.Alumno MigracionAlumno { get; set; } 
        public Repo.AlumnoPersona RepositorioAlumno { get; set; }

        public DatosEstudianteViewModel()
        {
            this.MigracionAlumno = new Migra.Alumno();
            this.RepositorioAlumno = new Repo.AlumnoPersona();
        }
    }
}