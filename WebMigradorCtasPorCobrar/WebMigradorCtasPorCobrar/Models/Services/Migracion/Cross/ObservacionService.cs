using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using WebMigradorCtasPorCobrar.Models.Entities.Migracion;
using WebMigradorCtasPorCobrar.Models.Helpers;
using WebMigradorCtasPorCobrar.Models.Repository.Migracion;

namespace WebMigradorCtasPorCobrar.Models.Services.Migracion.Cross
{
    public class ObservacionService
    {
        public IEnumerable<Observacion> Obtener_TipoObservacionesTabla(TipoData tipo, Tablas tabla, Procedencia procedenciaID)
        {
            return ObservacionRepository.Obtener((int)tabla, Convert.ToBoolean(tipo)).Where(x => x.I_ProcedenciaID == (int)procedenciaID);
        }

        public IEnumerable<Observacion> Obtener_ObservacionesAlumno(int filaId)
        {
            return ObservacionRepository.Obtener(filaId, (int)Tablas.TR_Alumnos);
        }

        public IEnumerable<Observacion> Obtener_ObservacionesCuotaPago(int filaId)
        {
            return ObservacionRepository.Obtener(filaId, (int)Tablas.TR_Cp_Des);
        }

        public IEnumerable<Observacion> Obtener_ObservacionesConceptoPago(int filaId)
        {
            return ObservacionRepository.Obtener(filaId, (int)Tablas.TR_Cp_Pri);
        }

        public IEnumerable<Observacion> Obtener_ObservacionesObligacion(int filaId)
        {
            return ObservacionRepository.ObtenerDeCabecercaObligacion(filaId);
        }

        public IEnumerable<Observacion> Obtener_ObservacionesDetalleObligacion(int filaId)
        {
            return ObservacionRepository.ObtenerDeDetalleObligacion(filaId);
        }

        public IEnumerable<Observacion> ObtenerCatalogo()
        {
            return ObservacionRepository.ObtenerCatalogo();
        }

        public Observacion ObtenerCatalogo(int observacionID)
        {

            return ObservacionRepository.ObtenerCatalogo(observacionID) ?? new Observacion();
        }
    }
}
