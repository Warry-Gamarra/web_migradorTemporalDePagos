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
    public class PersonaRepository
    {
        public static IEnumerable<Persona> ObtenerPorDocumento(string codTipDoc, string numDNI)
        {
            IEnumerable<Persona> result;
            string command;

            try
            {
                using (var _dbConnection = new SqlConnection(Databases.RepositorioUnfvConnectionString))
                {
                    command = "SELECT * FROM TC_Persona WHERE B_Eliminado = 0 AND C_NumDNI = @C_NumDNI AND C_CodTipDoc = @C_CodTipDoc";

                    result = _dbConnection.Query<Persona>(command, new { C_NumDNI = numDNI, C_CodTipDoc = codTipDoc }, commandType: CommandType.Text);
                }
            }
            catch (Exception ex)
            {
                throw ex;
            }

            return result;
        }

        public static Persona ObtenerPorID(int personaID)
        {
            Persona result;
            string command;

            try
            {
                using (var _dbConnection = new SqlConnection(Databases.RepositorioUnfvConnectionString))
                {
                    command = "SELECT * FROM TC_Persona WHERE I_PersonaID = @I_PersonaID";

                    result = _dbConnection.QueryFirstOrDefault<Persona>(command, new { I_PersonaID = personaID }, commandType: CommandType.Text);
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