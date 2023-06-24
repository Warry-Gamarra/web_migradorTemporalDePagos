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
            var data = AlumnoRepository.Obtener(codRc, codAlu);

            if (data == null)
            {
                return new AlumnoPersona();
            }

            return new AlumnoPersona() { 
                C_CodAlu = data.C_CodAlu,
                C_RcCod = data.C_RcCod,
                C_AnioIngreso = data.C_AnioIngreso,
                C_Sexo = data.C_Sexo,
                C_NumDNI = data.C_NumDNI,
                T_ApePaterno = data.T_ApePaterno,
                T_ApeMaterno = data.T_ApeMaterno,
                T_Nombre = data.T_Nombre,
                T_DenomProg = data.T_DenomProg,
                T_FacDesc = data.T_FacDesc,
                T_EscDesc = data.T_EscDesc,
                C_CodTipDoc = data.C_CodTipDoc,
                C_CodModIng = data.C_CodModIng,
                T_ModIngDesc = data.T_ModIngDesc
            };
        }


        public AlumnoPersona ObtenerAlumno(string codAlu)
        {
            return new AlumnoPersona();
        }


        public IEnumerable<AlumnoPersona> ObtenerPorDocIdent(string codTipDoc, string numDNI)
        {
            throw new NotImplementedException();
        }




    }
}