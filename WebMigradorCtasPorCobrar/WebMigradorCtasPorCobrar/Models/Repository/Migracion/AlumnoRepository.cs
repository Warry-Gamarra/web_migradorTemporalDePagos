using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Data.SqlClient;
using WebMigradorCtasPorCobrar.Models.Entities.Migracion;
using System.Data;
using Dapper;
using WebMigradorCtasPorCobrar.Models.Helpers;

namespace WebMigradorCtasPorCobrar.Models.Repository.Migracion
{
    public class AlumnoRepository
    {
        public static IEnumerable<Alumno> Obtener(int procedenciaID)
        {
            IEnumerable<Alumno> result;

            using (var connection = new SqlConnection(Databases.MigracionTPConnectionString))
            {
                result = connection.Query<Alumno>($"SELECT * FROM dbo.TR_Alumnos WHERE I_ProcedenciaID = @I_ProcedenciaID"
                                                   , new { I_ProcedenciaID = procedenciaID } , commandType: CommandType.Text);
            }

            return result;
        }

        public static Alumno ObtenerPorId(int id)
        {
            Alumno result;

            using (var connection = new SqlConnection(Databases.MigracionTPConnectionString))
            {
                result = connection.QuerySingleOrDefault<Alumno>($"SELECT * FROM TR_Alumnos WHERE I_RowID = @I_RowID",
                                                                    new { I_RowID = id }, commandType: CommandType.Text);
            }

            return result;
        }

        public static Response Save(Alumno alumno)
        {
            Response result = new Response();
            DynamicParameters parameters = new DynamicParameters();

            try
            {
                using (var connection = new SqlConnection(Databases.MigracionTPConnectionString))
                {
                    parameters.Add(name: "I_RowID", dbType: DbType.Int32, value: alumno.I_RowID);
                    parameters.Add(name: "C_RcCod", dbType: DbType.String, size: 3, value: alumno.C_RcCod);
                    parameters.Add(name: "C_CodAlu", dbType: DbType.String, size: 20, value: alumno.C_CodAlu);
                    parameters.Add(name: "C_NumDNI", dbType: DbType.String, size: 20, value: alumno.C_NumDNI);
                    parameters.Add(name: "C_CodTipDoc", dbType: DbType.String, size: 5, value: alumno.C_CodTipDoc);
                    parameters.Add(name: "T_ApePaterno", dbType: DbType.String, size: 50, value: alumno.T_ApePaterno);
                    parameters.Add(name: "T_ApeMaterno", dbType: DbType.String, size: 50, value: alumno.T_ApeMaterno);
                    parameters.Add(name: "T_Nombre", dbType: DbType.String, size: 50, value: alumno.T_Nombre);
                    parameters.Add(name: "C_Sexo", dbType: DbType.String, size: 1, value: alumno.C_Sexo);
                    parameters.Add(name: "D_FecNac", dbType: DbType.Date, value: alumno.D_FecNac);
                    parameters.Add(name: "C_CodModIng", dbType: DbType.String, size: 2, value: alumno.C_CodModIng);
                    parameters.Add(name: "C_AnioIngreso", dbType: DbType.Int16, value: alumno.C_AnioIngreso);
                    parameters.Add(name: "I_ProcedenciaID", dbType: DbType.Byte, value: alumno.I_ProcedenciaID);

                    parameters.Add(name: "B_Resultado", dbType: DbType.Boolean, direction: ParameterDirection.Output);
                    parameters.Add(name: "T_Message", dbType: DbType.String, size: 4000, direction: ParameterDirection.Output);

                    connection.Execute("USP_U_ActualizarRegistroAlumno", parameters, commandType: CommandType.StoredProcedure);

                    result.IsDone = parameters.Get<bool>("B_Resultado");
                    result.Message = parameters.Get<string>("T_Message");
                }
            }
            catch (Exception ex)
            {
                result.IsDone = false;
                result.Message = ex.Message;
            }

            return result;
        }

    }
}