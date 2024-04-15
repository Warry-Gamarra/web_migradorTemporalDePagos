using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using WebMigradorCtasPorCobrar.Models.Helpers;

namespace WebMigradorCtasPorCobrar.Models.ViewModels
{
    public class ResponseObligacion
    {
        public Response Obligacion { get; set; }
        public List<Response> DetalleObligacion{ get; set; }

        public ResponseObligacion()
        {
            this.DetalleObligacion = new List<Response>();
        }
    }
}