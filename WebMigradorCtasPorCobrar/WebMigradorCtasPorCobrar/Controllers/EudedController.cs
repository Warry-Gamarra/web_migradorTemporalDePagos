using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;
using WebMigradorCtasPorCobrar.Models.Services;

namespace WebMigradorCtasPorCobrar.Controllers
{
    public class EudedController : Controller
    {
        private readonly CuotaPagoService cuotaPagoService;
        private readonly ConceptoPagoService conceptoPagoService;
        private readonly ObligacionService obligacionService;


        public EudedController()
        {
            cuotaPagoService = new CuotaPagoService();
            conceptoPagoService = new ConceptoPagoService();
            obligacionService = new ObligacionService();
        }

        // GET: Euded
        public ActionResult Index()
        {
            ViewBag.Title = "Euded";
            return View();
        }
        #region ------------------ Cuota de pago ---------------------------

        public ActionResult CuotaPago(int step = 1)
        {
            ViewBag.Group = "Posgrado";
            ViewBag.Title = "Cuotas de Pago";

            ViewBag.Step = $"step_{step}";

            switch (step)
            {
                case 1:
                    ViewBag.Active_1 = "active";
                    ViewBag.Enabled_2 = "disabled";
                    ViewBag.Enabled_3 = "disabled";
                    ViewBag.Enabled_4 = "disabled";

                    ViewBag.Action = "CuotaPagoTemporalPagos";
                    break;
                case 2:
                    ViewBag.Active_2 = "active";
                    ViewBag.Enabled_3 = "disabled";
                    ViewBag.Enabled_4 = "disabled";

                    ViewBag.Action = "CuotaPagoTransformacion";
                    break;
                case 3:
                    ViewBag.Active_3 = "active";
                    ViewBag.Enabled_4 = "disabled";

                    ViewBag.Action = "CuotaPagoResultadoRevision";
                    break;
                case 4:
                    ViewBag.Active_4 = "active";

                    ViewBag.Action = "CuotaPagoResultadoMigracion";
                    break;
            }


            return View();
        }

        public ActionResult CuotaPagoTemporalPagos()
        {
            var model = cuotaPagoService.ObtenerEudedTP();

            return PartialView("CuotaPago_migracion_step1", model);
        }

        public ActionResult CuotaPagoTransformacion()
        {
            var model = cuotaPagoService.ObtenerEudedMG();

            return PartialView("CuotaPago_migracion_step2", model);
        }


        public ActionResult CuotaPagoResultadoRevision()
        {
            var model = cuotaPagoService.ObtenerEudedMG();

            return PartialView("CuotaPago_migracion_step3", model);
        }

        public ActionResult CuotaPagoResultadoMigracion()
        {
            var model = cuotaPagoService.ObtenerEudedMG();

            return PartialView("CuotaPago_migracion_step4", model);
        }

        #endregion


        #region ------------------ Concepto de pago ---------------------------

        public ActionResult ConceptoPago(int step = 1)
        {
            ViewBag.Group = "Posgrado";
            ViewBag.Title = "Concepto de Pago";

            ViewBag.Step = $"step_{step}";

            switch (step)
            {
                case 1:
                    ViewBag.Active_1 = "active";
                    ViewBag.Enabled_2 = "disabled";
                    ViewBag.Enabled_3 = "disabled";
                    ViewBag.Enabled_4 = "disabled";

                    ViewBag.Action = "ConceptoPagoTemporalPagos";
                    break;
                case 2:
                    ViewBag.Active_2 = "active";
                    ViewBag.Enabled_3 = "disabled";
                    ViewBag.Enabled_4 = "disabled";

                    ViewBag.Action = "ConceptoPagoTransformacion";
                    break;
                case 3:
                    ViewBag.Active_3 = "active";
                    ViewBag.Enabled_4 = "disabled";

                    ViewBag.Action = "ConceptoPagoResultadoRevision";
                    break;
                case 4:
                    ViewBag.Active_4 = "active";

                    ViewBag.Action = "ConceptoPagoResultadoMigracion";
                    break;
            }


            return View();
        }

        public ActionResult ConceptoPagoTemporalPagos()
        {
            var model = conceptoPagoService.ObtenerEudedTP();

            return PartialView("ConceptoPago_migracion_step1", model);
        }

        public ActionResult ConceptoPagoTransformacion()
        {
            var model = conceptoPagoService.ObtenerEudedMG();

            return PartialView("ConceptoPago_migracion_step2", model);
        }


        public ActionResult ConceptoPagoResultadoRevision()
        {
            var model = conceptoPagoService.ObtenerEudedMG();

            return PartialView("ConceptoPago_migracion_step3", model);
        }

        public ActionResult ConceptoPagoResultadoMigracion()
        {
            var model = conceptoPagoService.ObtenerEudedMG();

            return PartialView("ConceptoPago_migracion_step4", model);
        }

        #endregion

    }
}