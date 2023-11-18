USE BD_OCEF_CtasPorCobrar
GO


SELECT o.* FROM TR_ObligacionAluCab o
INNER JOIN TC_Proceso p on o.I_ProcesoID = p.I_ProcesoID
WHERE o.B_Migrado = 1 AND p.I_Anio > 2019

SELECT * FROM TRI_PagoProcesadoUnfv WHERE I_MigracionRowID IS NOT NULL

SELECT * FROM TR_ObligacionAluDet
INNER JOIN (SELECT O.* FROM TR_ObligacionAluCab O
					  INNER JOIN TC_Proceso p on O.I_ProcesoID = P.I_ProcesoID
				 WHERE O.B_Migrado = 1 AND P.I_Anio > 2019) TBL
ON TR_ObligacionAluDet.I_ObligacionAluID = TBL.I_ObligacionAluID

SELECT * FROM TR_PagoBanco PB
		 INNER JOIN BD_OCEF_MigracionTP.dbo.TR_Ec_Det d on PB.I_MigracionRowID = d.I_RowID
WHERE PB.B_Migrado = 1 AND d.Ano > 2019



DELETE TRI_PagoProcesadoUnfv
FROM (SELECT PB.* FROM TR_PagoBanco PB
				INNER JOIN BD_OCEF_MigracionTP.dbo.TR_Ec_Det d on PB.I_MigracionRowID = d.I_RowID
		WHERE PB.B_Migrado = 1 AND d.Ano > 2019) TBL
WHERE TRI_PagoProcesadoUnfv.I_PagoBancoID = TBL.I_PagoBancoID
GO


DELETE TRI_PagoProcesadoUnfv
FROM (SELECT PB.* FROM TRI_PagoProcesadoUnfv PB
				INNER JOIN BD_OCEF_MigracionTP.dbo.TR_Ec_Det d on PB.I_MigracionRowID = d.I_RowID
		WHERE PB.B_Migrado = 1 AND d.Ano > 2019) TBL
WHERE TRI_PagoProcesadoUnfv.I_MigracionRowID = TBL.I_MigracionRowID
	  AND TRI_PagoProcesadoUnfv.I_MigracionTablaID = 4
GO


DELETE TR_PagoBanco
FROM (SELECT PB.* FROM TR_PagoBanco PB
				INNER JOIN BD_OCEF_MigracionTP.dbo.TR_Ec_Det d on PB.I_MigracionRowID = d.I_RowID
		WHERE PB.B_Migrado = 1 AND d.Ano > 2019) TBL
WHERE TR_PagoBanco.I_PagoBancoID = TBL.I_PagoBancoID
GO


DELETE TR_ObligacionAluDet
FROM (SELECT O.* FROM TR_ObligacionAluCab O
					  INNER JOIN TC_Proceso p on O.I_ProcesoID = P.I_ProcesoID
				 WHERE O.B_Migrado = 1 AND P.I_Anio > 2019) TBL
WHERE TR_ObligacionAluDet.I_ObligacionAluID = TBL.I_ObligacionAluID
	  AND I_ObligacionAluDetID NOT IN (6012442, 6257678, 6257679, 6257680, 6257681)
GO


DELETE TR_ObligacionAluCab
FROM (SELECT O.* FROM TR_ObligacionAluCab O
					  INNER JOIN TC_Proceso p on O.I_ProcesoID = P.I_ProcesoID
					  INNER JOIN TR_ObligacionAluDet D ON D.I_ObligacionAluID = O.I_ObligacionAluID
				 WHERE O.B_Migrado = 1 AND P.I_Anio > 2019 
					  AND D. I_ObligacionAluDetID NOT IN (6012442, 6257678, 6257679, 6257680, 6257681)) TBL
WHERE TR_ObligacionAluCab.I_ObligacionAluID = TBL.I_ObligacionAluID
GO




DELETE TR_ObligacionAluDet
FROM (SELECT O.* FROM TR_ObligacionAluCab O
					  INNER JOIN TC_Proceso p on O.I_ProcesoID = P.I_ProcesoID
				 WHERE O.B_Migrado = 1 AND P.I_Anio > 2019) TBL
WHERE TR_ObligacionAluDet.I_ObligacionAluID = TBL.I_ObligacionAluID
	  AND ISNULL(TR_ObligacionAluDet.I_ObligacionAluDetID, 0) NOT IN (SELECT ppu.I_ObligacionAluDetID FROM TRI_PagoProcesadoUnfv ppu
																		INNER JOIN (SELECT D.* FROM TR_ObligacionAluCab O
																							  INNER JOIN TC_Proceso p on O.I_ProcesoID = P.I_ProcesoID
																							  INNER JOIN TR_ObligacionAluDet D ON D.I_ObligacionAluID = O.I_ObligacionAluID
																						 WHERE O.B_Migrado = 1 AND P.I_Anio > 2019) TBL ON ppu.I_ObligacionAluDetID = TBL.I_ObligacionAluDetID
																		WHERE ppu.I_MigracionRowID IS NULL)
GO


DELETE TR_ObligacionAluCab
FROM (SELECT O.*, D.I_ObligacionAluDetID FROM TR_ObligacionAluCab O
					  INNER JOIN TC_Proceso p on O.I_ProcesoID = P.I_ProcesoID
					  LEFT JOIN TR_ObligacionAluDet D ON D.I_ObligacionAluID = O.I_ObligacionAluID
				 WHERE O.B_Migrado = 1 AND P.I_Anio > 2019 
					  AND ISNULL(D. I_ObligacionAluDetID, 0) NOT IN (SELECT ppu.I_ObligacionAluDetID FROM TRI_PagoProcesadoUnfv ppu
															INNER JOIN (SELECT D.* FROM TR_ObligacionAluCab O
																				  INNER JOIN TC_Proceso p on O.I_ProcesoID = P.I_ProcesoID
																				  LEFT JOIN TR_ObligacionAluDet D ON D.I_ObligacionAluID = O.I_ObligacionAluID
																			 WHERE O.B_Migrado = 1 AND P.I_Anio > 2019) TBL ON ppu.I_ObligacionAluDetID = TBL.I_ObligacionAluDetID
															WHERE ppu.I_MigracionRowID IS NULL)
	) TBL2
WHERE TR_ObligacionAluCab.I_ObligacionAluID = TBL2.I_ObligacionAluID
GO

