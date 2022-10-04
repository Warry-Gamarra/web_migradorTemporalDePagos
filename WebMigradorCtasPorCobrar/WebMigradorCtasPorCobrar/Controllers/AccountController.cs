using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Security;
using System.Web.Mvc;
using WebMatrix.WebData;
using WebMigradorCtasPorCobrar.Models.ViewModels;
using WebMigradorCtasPorCobrar.Models.Entities.Config;
using WebMigradorCtasPorCobrar.Models.Helpers;
using WebMigradorCtasPorCobrar.Models.Repository.Config;

namespace WebMigradorCtasPorCobrar.Controllers
{
    public class AccountController : Controller
    {
        private readonly UserServices _userService;

        public AccountController()
        {
            _userService = new UserServices();
        }
        // GET: Account
        public ActionResult Login(string returnUrl)
        {
            foreach (var user in _userService.GetDefaultAccountValues())
            {
                if (!WebSecurity.UserExists(user.Name))
                {
                    WebSecurity.CreateUserAndAccount(user.Name, user.DefaultPassword);
                }

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


        public ActionResult ChangePassword()
        {
            return PartialView("_ChangePassword");
        }


        [HttpPost]
        [ValidateAntiForgeryToken]
        public ActionResult ChangePassword(Password model)
        {
            Response result = new Response();

            try
            {
                result.IsDone = WebSecurity.ChangePassword(User.Identity.Name, model.CurrentPassword, model.NewPassword);
            }
            catch (Exception ex)
            {
                result.IsDone = false;
                result.Message = ex.Message;
            }

            result = result.IsDone ? result.Success("La contraseña ha sido modificada.", false) 
                                   : result.Error("La contraseña no pudo ser actualizada.", false);

            return PartialView("_MsgPartial", result);
        }

        public ActionResult ResetPassword()
        {
            ViewBag.Users = new SelectList(_userService.GetDefaultAccountValues(), "Name", "Name");

            return PartialView("_ResetPassword");
        }


        [HttpPost]
        public ActionResult ResetPassword(string usuario)
        {
            User user = _userService.GetDefaultAccountValue(usuario);
            Response result = new Response();

            try
            {
                string s_token = WebSecurity.GeneratePasswordResetToken(user.Name);

                result.IsDone = WebSecurity.ResetPassword(s_token, user.DefaultPassword);
            }
            catch (Exception ex)
            {
                result.IsDone = false;
                result.Message = ex.Message;
            }

            result = result.IsDone ? result.Success("La contraseña ha sido modificada: " + user.DefaultPassword, false)
                                   : result.Error("La contraseña no pudo ser actualizada.", false);

            return PartialView("_MsgPartial", result);
        }
    }
}