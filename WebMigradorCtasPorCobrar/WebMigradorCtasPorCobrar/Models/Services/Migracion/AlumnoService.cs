using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using WebMigradorCtasPorCobrar.Models.Repository.Migracion;
using WebMigradorCtasPorCobrar.Models.Entities.Migracion;
using WebMigradorCtasPorCobrar.Models.Helpers;
using WebMigradorCtasPorCobrar.Models.ViewModels;

namespace WebMigradorCtasPorCobrar.Models.Services.Migracion
{
    public class AlumnoService
    {
        public IEnumerable<Alumno> Obtener(Procedencia procedencia)
        {
            return AlumnoRepository.Obtener((int)procedencia);
        }

        public Alumno Obtener(int alumnoId)
        {
            return AlumnoRepository.ObtenerPorId(alumnoId);
        }


        public Response Save(Alumno alumno)
        {
            Response result = new Response();

            result = AlumnoRepository.Save(alumno);

            if (result.IsDone)
            {
                result.Success(false);
            }
            else
            {
                result.Error(false);
            }

            return result;
        }
    }
}