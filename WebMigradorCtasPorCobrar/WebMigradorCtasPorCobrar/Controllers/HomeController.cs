using System.Collections.Generic;
using System.Web.Mvc;
using WebMigradorCtasPorCobrar.Models.Helpers;
using WebMigradorCtasPorCobrar.Models.Services.Config;

namespace WebMigradorCtasPorCobrar.Controllers
{
    [Authorize]
    public class HomeController : Controller
    {
        private readonly DatabaseServices _databaseServices;
        public HomeController()
        {
            _databaseServices = new DatabaseServices();
        }
        public ActionResult Index()
        {
            var conexiones = new List<Response>();

            conexiones.Add(_databaseServices.IsDatabaseConnected("BD_OCEF_TemporalPagos"));
            conexiones.Add(_databaseServices.IsDatabaseConnected("BD_OCEF_TemporalTasas"));
            conexiones.Add(_databaseServices.IsDatabaseConnected("BD_UNFV_Repositorio"));
            conexiones.Add(_databaseServices.IsDatabaseConnected("BD_OCEF_CtasPorCobrar"));

            ViewBag.Conexiones = conexiones;

            return View();
        }

    }
}