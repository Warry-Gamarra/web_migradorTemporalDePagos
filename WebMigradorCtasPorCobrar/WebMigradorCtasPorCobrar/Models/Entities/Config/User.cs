using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace WebMigradorCtasPorCobrar.Models.Entities.Config
{
    public class User
    {
        public string Name { get; }
        public string DefaultPassword { get; }

        public User(string userName, string DefaultPassword)
        {
            this.Name = userName;
            this.DefaultPassword = DefaultPassword;
        }
    }
}