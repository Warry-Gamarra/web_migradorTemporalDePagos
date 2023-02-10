using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using WebMigradorCtasPorCobrar.Models.Entities.UnfvRepositorio;
using WebMigradorCtasPorCobrar.Models.Helpers;
using WebMigradorCtasPorCobrar.Models.Repository.UnfvRepositorio;

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
            return AlumnoRepository.Obtener((int)procedencia);
        }

        //public IEnumerable<Alumno> ObtenerAlumnos(Procedencia procedencia)
        //{
        //    return new IAsyncResult = '');
        //}

        public IEnumerable<Persona> ObtenerPersonas(Procedencia procedenciaID)
        {
            return PersonaRepository.Obtener((int)procedenciaID);
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