using System.Web;
using System.Web.Optimization;

namespace WebMigradorCtasPorCobrar
{
    public class BundleConfig
    {
        // Para obtener más información sobre las uniones, visite https://go.microsoft.com/fwlink/?LinkId=301862
        public static void RegisterBundles(BundleCollection bundles)
        {
            bundles.Add(new StyleBundle("~/content/css").Include(
                "~/Assets/bootstrap/css/bootstrap.min.css",
                "~/Assets/grid-mvc/css/Gridmvc.css",
                "~/Assets/toastr/css/toastr.min.css",
                "~/Assets/application/css/main.css",
                "~/Assets/application/css/loaders.css",
                "~/Assets/application/css/sidebar.css"));

            bundles.Add(new StyleBundle("~/content/datetime").Include(
                    "~/Assets/bootstrap-datepicker/css/bootstrap-datepicker.css",
                    "~/Assets/bootstrap-datepicker/css/bootstrap-timepicker.css"));

            bundles.Add(new StyleBundle("~/content/fonts").Include(
                "~/Assets/font-awesome/css/font-awesome.min.css",
                "~/Assets/bootstrap/css/bootstrap-icons.css"));

            bundles.Add(new StyleBundle("~/content/select").Include(
                "~/Assets/select2/css/select2.min.css",
                "~/Assets/select2/css/select2-bootstrap4.min.css"));

            bundles.Add(new StyleBundle("~/content/sweetalert2").Include(
                "~/Assets/sweetalert2/css/sweetalert2.min.css"));

            bundles.Add(new StyleBundle("~/content/bootstrap4toggle").Include(
                "~/Assets/bootstrap-toggle/css/bootstrap4-toggle.min.css"));

            bundles.Add(new StyleBundle("~/content/datatables").Include(
                "~/Assets/datatables/css/datatables.min.css",
                "~/Assets/datatables/css/dataTables.bootstrap4.min.css"));

            bundles.Add(new ScriptBundle("~/bundles/jquery").Include(
                "~/Assets/jquery/jquery-3.3.1.min.js"));

            bundles.Add(new ScriptBundle("~/bundles/jqueryval").Include(
                "~/Assets/jquery/jquery.validate*"));

            bundles.Add(new ScriptBundle("~/bundles/bootstrap").Include(
                "~/Assets/bootstrap/js/popper.min.js",
                "~/Assets/bootstrap/js/bootstrap.min.js"));

            bundles.Add(new ScriptBundle("~/bundles/select").Include(
                "~/Assets/select2/js/select2.min.js"));

            bundles.Add(new ScriptBundle("~/bundles/sweetalert2").Include(
                "~/Assets/sweetalert2/js/sweetalert2.min.js"));

            bundles.Add(new ScriptBundle("~/bundles/bootstrap4toggle").Include(
                "~/Assets/bootstrap-toggle/js/bootstrap4-toggle.min.js"));

            bundles.Add(new ScriptBundle("~/bundles/datatables").Include(
                "~/Assets/datatables/js/datatables.min.js",
                "~/Assets/datatables/js/dataTables.bootrstrap4.min.js"));

            bundles.Add(new ScriptBundle("~/bundles/datetime").Include(
                "~/Assets/bootstrap-datepicker/js/bootstrap-datepicker.js",
                "~/Assets/bootstrap-datepicker/js/bootstrap-datepicker.es.js",
                "~/Assets/bootstrap-datepicker/js/bootstrap-timepicker.js",
                "~/Assets/bootstrap-datepicker/js/datetimepicker.js"));

            bundles.Add(new ScriptBundle("~/bundles/app").Include(
                "~/Assets/grid-mvc/js/gridmvc.js",
                "~/Assets/toastr/js/toastr.min.js",
                "~/Assets/toastr/js/toastr.config.js",
                "~/Assets/application/js/main.js",
                "~/Assets/application/js/sidebar.js"));
        }
    }
}
