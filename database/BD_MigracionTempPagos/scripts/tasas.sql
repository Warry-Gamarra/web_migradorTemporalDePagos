USE BD_OCEF_CtasPorCobrar
GO


-----------------------------------------------------------------
----------- CENTRO CULTURAL FEDERICO VILLARREAL  - CCFV							
-----------------------------------------------------------------




-----------------------------------------------------------------
------------CENTRO CULTURAL FEDERICO VILLARREAL  - CCFV							
-----------------------------------------------------------------

DECLARE @last_id as int

INSERT INTO TC_Concepto (T_ConceptoDesc, I_Monto, I_MontoMinimo, B_EsPagoMatricula, B_EsPagoExtmp, B_ConceptoAgrupa, B_Calculado, I_Calculado, B_Habilitado, B_Eliminado) VALUES ('CURSO TALLER ARTISTICO', 0, 0, 0, 0, 0, 0, 0, 1, 0)
SET @last_id = SCOPE_IDENTITY()

--INSERT INTO TI_ConceptoPago (I_ProcesoID, I_ConceptoID, T_ConceptoPagoDesc, B_Fraccionable, B_ConceptoGeneral, B_AgrupaConcepto, I_AlumnosDestino, I_GradoDestino, I_TipoObligacion, T_Clasificador, C_CodTasa, B_Calculado, I_Calculado, B_AnioPeriodo, I_Anio, I_Periodo, B_Especialidad, C_CodRc, B_Dependencia, C_DepCod, B_GrupoCodRc, I_GrupoCodRc, B_ModalidadIngreso, I_ModalidadIngresoID, B_ConceptoAgrupa, I_ConceptoAgrupaID, B_ConceptoAfecta, I_ConceptoAfectaID, N_NroPagos, B_Porcentaje, C_Moneda, M_Monto, M_MontoMinimo, T_DescripcionLarga, T_Documento, B_Migrado, B_Habilitado, B_Eliminado, I_TipoDescuentoID)
--SELECT 
--FROM temporal_pagos.dbo.cp_pri