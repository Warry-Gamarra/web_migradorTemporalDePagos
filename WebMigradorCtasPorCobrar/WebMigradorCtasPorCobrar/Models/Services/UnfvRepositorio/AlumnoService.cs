using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using WebMigradorCtasPorCobrar.Models.Entities.UnfvRepositorio;
using WebMigradorCtasPorCobrar.Models.Helpers;

namespace WebMigradorCtasPorCobrar.Models.Services.UnfvRepositorio
{
    public class AlumnoService
    {
        public IEnumerable<AlumnoPersona> Obtener()
        {
            throw new NotImplementedException();
        }

        public IEnumerable<AlumnoPersona> Obtener(Procedencia procedencia)
        {
            List<AlumnoPersona> result = new List<AlumnoPersona>();


            return result;
        }

        public IEnumerable<Alumno> ObtenerAlumnos(Procedencia procedencia)
        {
            List<Alumno> result = new List<Alumno>();


            return result;
        }

        public IEnumerable<Persona> ObtenerPersonas(Procedencia procedencia)
        {
            List<Persona> result = new List<Persona>();


            return result;
        }

        public AlumnoPersona ObtenerAlumno(string codRc, string codAlu)
        {
            throw new NotImplementedException();
        }


        public Alumno ObtenerAlumno(string codAlu)
        {
            throw new NotImplementedException();
        }


        public IEnumerable<AlumnoPersona> ObtenerPorDocIdent(string codTipDoc, string numDNI)
        {
            throw new NotImplementedException();
        }




    }
}