using Dapper;
using System;
using System.Data;
using System.Data.SqlClient;
using WebMigradorCtasPorCobrar.Models.Helpers;

namespace WebMigradorCtasPorCobrar.Models.Repository.Migracion.Cross
{
    public class ControlRepository
    {
        public void RegistrarProcesoCopia(Tablas tablaID, int procedenciaID, string anio, int toDo, int done, int inProgress)
        {
            Response result = new Response();
            DynamicParameters parameters = new DynamicParameters();

            try
            {
                using (var connection = new SqlConnection(Databases.MigracionTPConnectionString))
                {
                    parameters.Add(name: "I_TablaID", dbType: DbType.Byte, value: (byte)tablaID);
                    parameters.Add(name: "I_ProcedenciaID", dbType: DbType.Byte, value: procedenciaID);
                    parameters.Add(name: "I_Anio", dbType: DbType.Int16, value: int.Parse(anio));
                    parameters.Add(name: "I_ValueToDo", dbType: DbType.Int32, value: toDo);
                    parameters.Add(name: "I_ValueDone", dbType: DbType.Int32, value: done);
                    parameters.Add(name: "I_ValueProgress", dbType: DbType.Int32, value: inProgress);
                    parameters.Add(name: "D_FecProceso", dbType: DbType.DateTime, value: DateTime.Now);

                    connection.Execute("USP_Shared_ControlTabla_MigracionTP_IU_RegistrarCopiados", parameters, commandTimeout: 360, commandType: CommandType.StoredProcedure);
                }
            }
            catch (Exception ex)
            {
                throw ex;
            }

        }

        public void RegistrarProcesoValidacion(Tablas tablaID, int procedenciaID, string anio, int toDo, int done, int inProgress)
        {
            Response result = new Response();
            DynamicParameters parameters = new DynamicParameters();

            try
            {
                using (var connection = new SqlConnection(Databases.MigracionTPConnectionString))
                {
                    parameters.Add(name: "I_TablaID", dbType: DbType.Byte, value: (byte)tablaID);
                    parameters.Add(name: "I_ProcedenciaID", dbType: DbType.Byte, value: procedenciaID);
                    parameters.Add(name: "I_Anio", dbType: DbType.Int16, value: int.Parse(anio));
                    parameters.Add(name: "I_ValueToDo", dbType: DbType.Int32, value: toDo);
                    parameters.Add(name: "I_ValueDone", dbType: DbType.Int32, value: done);
                    parameters.Add(name: "I_ValueProgress", dbType: DbType.Int32, value: inProgress);
                    parameters.Add(name: "D_FecProceso", dbType: DbType.DateTime, value: DateTime.Now);

                    connection.Execute("USP_Shared_ControlTabla_MigracionTP_IU_RegistrarValidacion", parameters, commandTimeout: 360, commandType: CommandType.StoredProcedure);
                }
            }
            catch (Exception ex)
            {
                throw ex;
            }

        }

        public void RegistrarProcesoMigracion(Tablas tablaID, int procedenciaID, string anio, int toDo, int done, int inProgress)
        {
            Response result = new Response();
            DynamicParameters parameters = new DynamicParameters();

            try
            {
                using (var connection = new SqlConnection(Databases.MigracionTPConnectionString))
                {
                    parameters.Add(name: "I_TablaID", dbType: DbType.Byte, value: (byte)tablaID);
                    parameters.Add(name: "I_ProcedenciaID", dbType: DbType.Byte, value: procedenciaID);
                    parameters.Add(name: "I_Anio", dbType: DbType.Int16, value: int.Parse(anio));
                    parameters.Add(name: "I_ValueToDo", dbType: DbType.Int32, value: toDo);
                    parameters.Add(name: "I_ValueDone", dbType: DbType.Int32, value: done);
                    parameters.Add(name: "I_ValueProgress", dbType: DbType.Int32, value: inProgress);
                    parameters.Add(name: "D_FecProceso", dbType: DbType.DateTime, value: DateTime.Now);

                    connection.Execute("USP_Shared_ControlTabla_MigracionTP_IU_RegistrarMigracion", parameters, commandTimeout: 360, commandType: CommandType.StoredProcedure);
                }
            }
            catch (Exception ex)
            {
                throw ex;
            }

        }
    }
}