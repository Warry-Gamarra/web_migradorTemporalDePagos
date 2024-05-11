using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace WebMigradorCtasPorCobrar.Models.Helpers
{
    public class Response
    {
        public bool IsDone { get; set; }
        public string Action { get; set; }
        public string Controller { get; set; }
        public string Redirect { get; set; }
        public string Message { get; set; }
        public string Icon { get; set; }
        public string Color { get; set; }
        public string CurrentID { get; set; }
        public ObjResult ObjMessage { get; set; } = new ObjResult();
        public IList<ObjResult> ListObjMessage { get; set; } = new List<ObjResult>();
    }

    public class ObjResult
    {
        public string Type { get; set; }
        public string Title { get; set; }
        public string Value { get; set; }
    }
}