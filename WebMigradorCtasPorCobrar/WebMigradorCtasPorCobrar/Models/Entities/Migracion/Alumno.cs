using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace WebMigradorCtasPorCobrar.Models.Entities.Migracion
{
    public class Alumno
    {
        public int I_RowID { get; set; }
        public string C_RcCod { get; set; }
        public string T_Carrera { get; set; }
        public string C_CodAlu { get; set; }
        public string C_NumDNI { get; set; }
        public string C_CodTipDoc { get; set; }
        public string T_ApePaterno { get; set; }
        public string T_ApeMaterno { get; set; }
        public string T_Nombre { get; set; }
        public string C_Sexo { get; set; }
        public DateTime? D_FecNac { get; set; }
        public string C_CodModIng { get; set; }
        public string T_ModalidadIng { get; set; }
        public string C_AnioIngreso { get; set; }
        public byte I_ProcedenciaID { get; set; }
        public DateTime D_FecCarga { get; set; }
        public bool B_Actualizado { get; set; }
        public DateTime D_FecActualiza { get; set; }
        public bool B_Migrable { get; set; }
        public DateTime D_FecEvalua { get; set; }
        public bool B_Migrado { get; set; }
        public DateTime D_FecMigrado { get; set; }
        public bool B_Removido { get; set; }
        public DateTime D_FecRemovido { get; set; }
    }
}