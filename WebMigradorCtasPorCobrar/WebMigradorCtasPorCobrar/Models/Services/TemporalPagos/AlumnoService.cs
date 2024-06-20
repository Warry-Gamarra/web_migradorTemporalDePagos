using System.Collections.Generic;
using WebMigradorCtasPorCobrar.Models.Entities.TemporalPagos;
using WebMigradorCtasPorCobrar.Models.Helpers;
using WebMigradorCtasPorCobrar.Models.Repository.TemporalPagos;
using MigraRepo = WebMigradorCtasPorCobrar.Models.Repository.Migracion.Cross;

namespace WebMigradorCtasPorCobrar.Models.Services.TemporalPagos
{
    public class AlumnoService
    {
        public IEnumerable<Alumno> Obtener(TipoData tipo, Procedencia procedencia)
        {
            string schemaDb = Schema.SetSchema(procedencia);
            if (tipo == TipoData.ConObligaciones)
            {
                return AlumnoRepository.Obtener(schemaDb);
            }
            else
            {
                return AlumnoRepository.ObtenerSinOblig(schemaDb, BuildRcCodlist(procedencia));
            }
        }

        private string BuildRcCodlist(Procedencia procedencia) 
        {
            byte procedenciaID = (byte)procedencia;
            string carrerasFilter = string.Empty;

            var carrerasProcedencia = MigraRepo.ProcedenciaRepository.ObtenerCarreraByProcID(procedenciaID);

            foreach (var item in carrerasProcedencia)
            {
                carrerasFilter += $"'{item.C_RcCod}',";
            }

            int length = carrerasFilter.Length > 0 ? carrerasFilter.Length - 1: carrerasFilter.Length;

            return carrerasFilter.Substring(0, length);
        }
    }
}