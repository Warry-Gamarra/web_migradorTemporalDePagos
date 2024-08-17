using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using WebMigradorCtasPorCobrar.Models.Helpers;

namespace WebMigradorCtasPorCobrar.Models.Services.Config
{
    public class DatabaseServices
    {
        private readonly Databases _databases;
        public DatabaseServices()
        {
            _databases = new Databases();
        }

        public Response IsDatabaseConnected(string dataBaseName)
        {
            string connectionStringName;

            switch (dataBaseName)
            {
                case "BD_OCEF_CtasPorCobrar":
                    connectionStringName = "BD_CtasPorCobrarConnection";
                    break;
                case "BD_OCEF_MigracionTP":
                    connectionStringName = "BD_MigracionTPConnection";
                    break;
                case "BD_UNFV_Repositorio":
                    connectionStringName = "BD_RepositorioConnection";
                    break;
                case "BD_OCEF_TemporalPagos":
                    connectionStringName = "BD_TemporalPagoConnection";
                    break;
                case "BD_OCEF_TemporalTasas":
                    connectionStringName = "BD_TemporalTasasConnection";
                    break;
                default:
                    return new Response()
                    {
                        Color = "secondary",
                        IsDone = false,
                        Message = "No se encontró una cadena de conexión para la base de datos",
                        Icon = "bi-exclamation-circle-fill text-secondary",
                        CurrentID = dataBaseName
                    };
            }

            bool isConnected = _databases.IsDatabaseConnected(connectionStringName);

            if (isConnected)
            {
                return new Response()
                {
                    Color = "info",
                    IsDone = true,
                    Message = $"Conectado ",
                    Icon = "bi-check-circle-fill text-success",
                    CurrentID = dataBaseName
                };
            }

            return new Response()
            {
                Color = "danger",
                IsDone = false,
                Message = $"Sin conexión ",
                Icon = "bi-x-circle-fill text-danger",
                CurrentID = dataBaseName
            };
        }
    }
}