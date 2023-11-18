USE BD_OCEF_MigracionTP
GO


-- ACTUALIZAR ESTADO DE REGISTROS MIGRADOS DEL TEMPORAL DEL PAGOS.

UPDATE OBL
   SET OBL.B_Migrable = 1, 
	   OBL.B_Migrado = 1,
	   OBL.D_FecMigrado = TBL.D_FecCre
  FROM TR_Ec_Obl OBL
	   INNER JOIN (SELECT o.* FROM BD_OCEF_CtasPorCobrar.dbo.TR_ObligacionAluCab o
			INNER JOIN BD_OCEF_CtasPorCobrar.dbo.TC_Proceso p on o.I_ProcesoID = p.I_ProcesoID
			WHERE o.B_Migrado = 1) TBL ON OBL.I_RowID = TBL.I_MigracionRowID AND TBL.I_MigracionTablaID = 5
GO

-- ACTUALIZAR CUOTA PROCEDENCIA

DECLARE @row_id  int

DELETE TI_ObservacionRegistroTabla 
WHERE I_TablaID = 5 AND I_FilaTablaID IN (SELECT I_RowID FROM  TR_Ec_Obl WHERE Cod_alu = '0009662048' AND Cuota_pago = 142 AND Ano = '2005' AND I_ProcedenciaID = 3)

UPDATE TR_Ec_Obl 
SET I_ProcedenciaID = 2
WHERE I_RowID IN (SELECT I_RowID FROM  TR_Ec_Obl WHERE Cod_alu = '0009662048' AND Cuota_pago = 142 AND Ano = '2005' AND I_ProcedenciaID = 3)


DELETE TI_ObservacionRegistroTabla 
WHERE I_TablaID = 5 AND I_FilaTablaID IN (SELECT I_RowID FROM  TR_Ec_Obl WHERE Cod_alu = '2002319959' AND Cuota_pago = 133 AND Ano = '2009' AND I_ProcedenciaID = 3)

UPDATE TR_Ec_Obl 
SET I_ProcedenciaID = 2
WHERE I_RowID IN (SELECT I_RowID FROM  TR_Ec_Obl WHERE Cod_alu = '2002319959' AND Cuota_pago = 133 AND Ano = '2009' AND I_ProcedenciaID = 3)


DELETE TI_ObservacionRegistroTabla 
WHERE I_TablaID = 5 AND I_FilaTablaID IN (SELECT I_RowID FROM  TR_Ec_Obl WHERE Cod_alu = '2002319959' AND Cuota_pago = 134 AND Ano = '2009' AND I_ProcedenciaID = 3)

UPDATE TR_Ec_Obl 
SET I_ProcedenciaID = 2
WHERE I_RowID IN (SELECT I_RowID FROM  TR_Ec_Obl WHERE Cod_alu = '2002319959' AND Cuota_pago = 134 AND Ano = '2009' AND I_ProcedenciaID = 3)

GO

