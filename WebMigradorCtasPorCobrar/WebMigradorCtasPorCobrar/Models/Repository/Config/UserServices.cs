using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using WebMigradorCtasPorCobrar.Models.Entities.Config;

namespace WebMigradorCtasPorCobrar.Models.Repository.Config
{
    public class UserServices
    {
        public IEnumerable<User> GetDefaultAccountValues()
        {
            List<User> result = new List<User>
            {
                new User("administrador", "admin@OCGTI"),
                new User("tesorería_01", "tesorería@01"),
                new User("tesorería_02", "tesorería@02"),
                new User("tesorería_03", "tesorería@03")
            };

            return result;
        }

        public User GetDefaultAccountValue(string userName)
        {
            return GetDefaultAccountValues().Single(x => x.Name == userName);
        }

    }
}