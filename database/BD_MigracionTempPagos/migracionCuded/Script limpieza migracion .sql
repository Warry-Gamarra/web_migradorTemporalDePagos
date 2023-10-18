USE BD_OCEF_CtasPorCobrar
GO

SELECT o.* FROM TR_ObligacionAluCab o
INNER JOIN TC_Proceso p on o.I_ProcesoID = p.I_ProcesoID
WHERE o.B_Migrado = 1 AND p.I_Anio > 2019


SELECT * FROM TR_ObligacionAluDet
INNER JOIN (SELECT O.* FROM TR_ObligacionAluCab O
					  INNER JOIN TC_Proceso p on O.I_ProcesoID = P.I_ProcesoID
				 WHERE O.B_Migrado = 1 AND P.I_Anio > 2019) TBL
ON TR_ObligacionAluDet.I_ObligacionAluID = TBL.I_ObligacionAluID

SELECT * FROM TR_PagoBanco PB
		 INNER JOIN BD_OCEF_MigracionTP.dbo.TR_Ec_Det d on PB.I_MigracionRowID = d.I_RowID
WHERE PB.B_Migrado = 1 AND d.Ano > 2019



DELETE TR_ObligacionAluDet
FROM (SELECT O.* FROM TR_ObligacionAluCab O
					  INNER JOIN TC_Proceso p on O.I_ProcesoID = P.I_ProcesoID
				 WHERE O.B_Migrado = 1 AND P.I_Anio > 2019) TBL
WHERE TR_ObligacionAluDet.I_ObligacionAluID = TBL.I_ObligacionAluID


DELETE TR_ObligacionAluCab
FROM (SELECT O.* FROM TR_ObligacionAluCab O
					  INNER JOIN TC_Proceso p on O.I_ProcesoID = P.I_ProcesoID
				 WHERE O.B_Migrado = 1 AND P.I_Anio > 2019) TBL
WHERE TR_ObligacionAluCab.I_ObligacionAluID = TBL.I_ObligacionAluID
