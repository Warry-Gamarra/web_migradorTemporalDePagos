using Antlr.Runtime.Misc;
using System;
using System.Web.Helpers;
using System.Web.Mvc;
using WebMigradorCtasPorCobrar.Models.Entities.Migracion;
using WebMigradorCtasPorCobrar.Models.Helpers;
using static WebMigradorCtasPorCobrar.Models.Helpers.Observaciones;

namespace WebMigradorCtasPorCobrar.Models.ViewModels
{
    public static class ResponseViewModel
    {
        public static Response Success(this Response response, bool display = true)
        {
            response.Color = "success";
            response.Icon = "fa fa-check-circle";
            response.CurrentID = display ? "display: show;" : "display: none;";

            return response;
        }

        public static Response Success(this Response response, string message, bool display = true)
        {
            response.Color = "success";
            response.Icon = "fa fa-check-circle";
            response.CurrentID = display ? "display: show;" : "display: none;";
            response.Message = message;

            return response;
        }


        public static Response Warning(this Response response, bool display = true)
        {
            response.Color = "warning";
            response.Icon = "fa fa-exclamation-triangle";
            response.CurrentID = display ? "display: show;" : "display: none;";

            return response;
        }

        public static Response Warning(this Response response, string message, bool display = true)
        {
            response.Color = "warning";
            response.Icon = "fa fa-exclamation-triangle";
            response.CurrentID = display ? "display: show;" : "display: none;";
            response.Message = message;

            return response;
        }


        public static Response Error(this Response response, bool display = true)
        {
            response.Color = "danger";
            response.Icon = "fa fa-times-circle";
            response.CurrentID = display ? "display: show;" : "display: none;";

            return response;
        }

        public static Response Error(this Response response, string message, bool display = true)
        {
            response.Color = "danger";
            response.Icon = "fa fa-times-circle";
            response.CurrentID = display ? "display: show;" : "display: none;";
            response.Message = message;

            return response;
        }


        public static Response Info(this Response response, bool display = true)
        {
            response.Color = "info";
            response.Icon = "fa fa-info-circle";
            response.CurrentID = display ? "display: show;" : "display: none;";

            return response;
        }

        public static Response Info(this Response response, string message, bool display = true)
        {
            response.Color = "info";
            response.Icon = "fa fa-info-circle";
            response.CurrentID = display ? "display: show;" : "display: none;";
            response.Message = message;

            return response;
        }

        public static Response DeserializeJsonMessage(this Response response, string validation)
        {
            try
            {
                var result = Json.Decode<ObjResult>(response.Message);

                response.ObjMessage = result;
            }
            catch (Exception )
            {
                response.ObjMessage = new ObjResult() {
                    Type = "Error",
                    Title = validation,
                    Value = response.Message
                };
            }

            return response;
        }


        public static Response ReturnViewValidationsMessage(this Response response, string headerText, int observacionID, string controller = "", string action = "")
        {
            response.DeserializeJsonMessage(headerText);
            int observados = int.TryParse(response.ObjMessage.Value, out int obs) ? obs : 0;

            response = response.IsDone ? response.Success(false) : response.Error(false);
            response = observados == 0 ? response : response.Warning(false);
            response.CurrentID = headerText;

            response.Controller = controller;
            response.Action = action;
            response.Redirect = observacionID.ToString();

            return response;
        }

        public static Response ReturnViewMigrationMessage(this Response response, string headerText)
        {
            response.DeserializeJsonMessage(headerText);
            int observados = int.TryParse(response.ObjMessage.Value, out int obs) ? obs : 0;

            response = response.IsDone ? response.Success(false) : response.Error(false);
            response = observados == 0 ? response : response.Warning(false);
            response.CurrentID = headerText;

            return response;
        }

        public static Response FormatResponse(this Response response, string validationTitle, string header, int observacionID, string controller = "", string action = "")
        {
            if (response.IsDone)
            {
                response = response.Success(false);
                int observados = int.TryParse(response.Message, out int obs) ? obs : 0;
                response = observados == 0 ? response : response.Warning(false);
                response.CurrentID = header;
                response.ObjMessage = new ObjResult()
                {
                    Title = validationTitle,
                    Type = observados == 0 ? "success" : "warning",
                    Value = $"{observados} registros encontrados"
                };
            }
            else
            {
                response = response.Error(false);

                var jsonMessage = Json.Decode(response.Message);
                response.ObjMessage = new ObjResult()
                {
                    Title = jsonMessage["Title"].ToString(),
                    Type = jsonMessage["Type"].ToString(),
                    Value = $"{jsonMessage["Value"]} registros encontrados",
                };
            }

            response.Controller = controller;
            response.Action = action;
            response.Redirect = observacionID.ToString();


            return response;
        }


    }
}