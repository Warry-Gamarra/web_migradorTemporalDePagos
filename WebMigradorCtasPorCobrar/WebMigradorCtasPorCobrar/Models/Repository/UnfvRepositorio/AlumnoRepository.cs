using Dapper;
using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using System.Linq;
using System.Web;
using WebMigradorCtasPorCobrar.Models.Entities.UnfvRepositorio;

namespace WebMigradorCtasPorCobrar.Models.Repository.UnfvRepositorio
{
    public class AlumnoRepository
    {
        public static Alumno ObtenerAlumno(string codRc, string codAlu)
        {
            Alumno result;
            string command;

            try
            {
                using (var _dbConnection = new SqlConnection(Databases.RepositorioUnfvConnectionString))
                {
                    command = "SELECT * FROM TC_Alumno WHERE B_Eliminado = 0 AND C_RcCod = @C_RcCod AND C_CodAlu = @C_CodAlu";

                    result = _dbConnection.QueryFirstOrDefault<Alumno>(command, new { C_RcCod = codRc, C_CodAlu = codAlu }, commandType: CommandType.Text);
                }
            }
            catch (Exception ex)
            {
                throw ex;
            }

            return result;
        }

        public static IEnumerable<AlumnoPersona> Obtener(int procedenciaID)
        {
            IEnumerable<AlumnoPersona> result;
            string command;

            try
            {
                using (var _dbConnection = new SqlConnection(Databases.RepositorioUnfvConnectionString))
                {
                    command = "SELECT * FROM dbo.VW_Alumnos WHERE B_Eliminado = 0";

                    result = _dbConnection.Query<AlumnoPersona>(command, commandType: CommandType.Text);
                }
            }
            catch (Exception ex)
            {
                throw ex;
            }

            return result;
        }

        public static AlumnoPersona Obtener(string codRc, string codAlu)
        {
            AlumnoPersona result;
            string command;

            try
            {
                using (var _dbConnection = new SqlConnection(Databases.RepositorioUnfvConnectionString))
                {
                    command = "SELECT * FROM dbo.VW_Alumnos WHERE B_Eliminado = 0 AND C_RcCod = @C_RcCod AND C_CodAlu = @C_CodAlu";

                    result = _dbConnection.QueryFirstOrDefault<AlumnoPersona>(command, new { C_RcCod = codRc, C_CodAlu = codAlu }, commandType: CommandType.Text);
                }
            }
            catch (Exception ex)
            {
                throw ex;
            }

            return result;
        }

        public static IEnumerable<AlumnoPersona> ObtenerPorDocIdent(string codTipDoc, string numDNI)
        {
            IEnumerable<AlumnoPersona> result;
            string command;

            try
            {
                using (var _dbConnection = new SqlConnection(Databases.RepositorioUnfvConnectionString))
                {
                    command = "SELECT * FROM dbo.VW_Alumnos WHERE B_Eliminado = 0 AND C_CodTipDoc = @C_CodTipDoc AND C_NumDNI = @C_NumDNI";

                    result = _dbConnection.Query<AlumnoPersona>(command, new { C_CodTipDoc = codTipDoc, C_NumDNI = numDNI }, commandType: CommandType.Text);
                }
            }
            catch (Exception ex)
            {
                throw ex;
            }

            return result;
        }

        public static IEnumerable<AlumnoPersona> ObtenerPorCodAlu(string codAlu)
        {
            IEnumerable<AlumnoPersona> result;
            string command;

            try
            {
                using (var _dbConnection = new SqlConnection(Databases.RepositorioUnfvConnectionString))
                {
                    command = "SELECT * FROM dbo.VW_Alumnos WHERE B_Eliminado = 0 AND C_CodAlu = @C_CodAlu";

                    result = _dbConnection.Query<AlumnoPersona>(command, new { C_CodAlu = codAlu }, commandType: CommandType.Text);
                }
            }
            catch (Exception ex)
            {
                throw ex;
            }

            return result;
        }

    }
}