using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Security;
using System.Web.Mvc;
using WebMatrix.WebData;
using WebMigradorCtasPorCobrar.Models.ViewModels;

namespace WebMigradorCtasPorCobrar.Controllers
{
    public class AccountController : Controller
    {
        // GET: Account
        public ActionResult Login(string returnUrl)
        {
            if (!WebSecurity.UserExists("administrador"))
            {
                WebSecurity.CreateUserAndAccount("administrador", "admin@OCGTI");
            }

            if (!WebSecurity.UserExists("tesoreria"))
            {
                WebSecurity.CreateUserAndAccount("tesoreria", "admin@OT");
            }

            ViewBag.ReturnUrl = returnUrl;
            return View();
        }

        [HttpPost]
        [AllowAnonymous]
        public ActionResult Login(LoginViewModel model, string returnUrl)
        {
            if (User.Identity.IsAuthenticated)
            {
                WebSecurity.Logout();
            }

            if (WebSecurity.UserExists(model.UserName))
            {
                if (ModelState.IsValid && WebSecurity.Login(model.UserName, model.Password, persistCookie: model.RememberMe))
                {
                    return RedirectToLocal(returnUrl);
                }
            }
            ModelState.AddModelError("", "El nombre de usuario no existe.");

            return View(model);
        }


        private ActionResult RedirectToLocal(string returnUrl)
        {
            if (Url.IsLocalUrl(returnUrl))
            {
                return Redirect(returnUrl);
            }
            else
            {
                return RedirectToAction("Index", "Home", new { area = "" });
            }
        }

        public ActionResult LogOut()
        {
            WebSecurity.Logout();

            return RedirectToAction("Login", "Account");
        }

    }
}