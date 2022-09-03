using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using WebMigradorCtasPorCobrar.Models.Entities.Migracion;
using WebMigradorCtasPorCobrar.Models.Helpers;
using WebMigradorCtasPorCobrar.Models.Repository.Migracion;

namespace WebMigradorCtasPorCobrar.Models.Services.Migracion
{
    public class ObservacionService
    {
        public IEnumerable<Observacion> Obtener_TipoObservacionesTabla(Tablas tabla, Procedencia procedenciaID)
        {
            return ObservacionRepository.Obtener((int)tabla).Where(x => x.I_ProcedenciaID == (int)procedenciaID);
        }

        public IEnumerable<Observacion> Obtener_ObservacionesAlumno(int filaId)
        {
            int tablaId = (int)Tablas.TR_Alumnos;

            return ObservacionRepository.Obtener(filaId, tablaId);
        }

        public IEnumerable<Observacion> Obtener_ObservacionesCuotaPago(int filaId)
        {
            int tablaId = (int)Tablas.TR_Cp_Des;

            return ObservacionRepository.Obtener(filaId, tablaId);
        }

        public IEnumerable<Observacion> Obtener_ObservacionesConceptoPago(int filaId)
        {
            int tablaId = (int)Tablas.TR_Cp_Pri;

            return ObservacionRepository.Obtener(filaId, tablaId);
        }

        public IEnumerable<Observacion> Obtener_ObservacionesObligacion(int filaId)
        {
            int tablaId = (int)Tablas.TR_Ec_Obl;

            return ObservacionRepository.Obtener(filaId, tablaId);
        }

        public IEnumerable<Observacion> Obtener_ObservacionesDetalleObligacion(int filaId)
        {
            int tablaId = (int)Tablas.TR_Ec_Det;

            return ObservacionRepository.Obtener(filaId, tablaId);
        }

    }
}