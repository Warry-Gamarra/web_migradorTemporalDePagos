/*
======================================================
	BD_OCEF_MigracionTP - 02_Data
======================================================
*/


USE BD_OCEF_MigracionTP
GO

UPDATE TC_ProcedenciaData SET T_ProcedenciaDesc = 'TASAS' WHERE I_ProcedenciaID = 4
GO

IF NOT EXISTS (SELECT * FROM TC_CatalogoTabla WHERE I_TablaID BETWEEN 8 AND 10)
BEGIN
	INSERT INTO TC_CatalogoTabla (I_TablaID, T_TablaNom) VALUES (8, 'TR_Tasas_Ec_Obl')
	INSERT INTO TC_CatalogoTabla (I_TablaID, T_TablaNom) VALUES (9, 'TR_Tasas_Ec_Det')
	INSERT INTO TC_CatalogoTabla (I_TablaID, T_TablaNom) VALUES (10, 'TR_Tasas_Ec_Det_Pagos')
END
GO



UPDATE TC_CatalogoObservacion
   SET T_ObservDesc = 'El año en el detalle de la obligacion no es un valor válido',
	   T_ObservCod = 'AÑO NO VALIDO'
 WHERE I_ObservID = 43
GO


UPDATE TC_CatalogoObservacion
   SET T_ObservDesc = 'Periodo en el detalle la obligacion no tiene equivalencia en la base de datos de Ctas por cobrar',
	   T_ObservCod = 'SIN PERIODO'
 WHERE I_ObservID = 44
GO

IF NOT EXISTS (SELECT * FROM TC_CatalogoObservacion WHERE I_ObservID = 51)
BEGIN
	INSERT INTO TC_CatalogoObservacion (I_ObservID, T_ObservDesc, T_ObservCod, I_Severidad, I_TablaID) 
								VALUES (51, 'El concepto de pago contiene verdadero en el campo obligación', 'NO OBLIGACION', NULL, 3)
END
GO


IF NOT EXISTS (SELECT * FROM TC_CatalogoObservacion WHERE I_ObservID = 57)
BEGIN
	INSERT INTO TC_CatalogoObservacion (I_ObservID, T_ObservDesc, T_ObservCod, I_Severidad, I_TablaID) 
								VALUES (57, 'El pago tiene observaciones en la cabecera de la obligacion.', 'OBSERVACIÓN OBLIG.', NULL, 7)
END
GO

IF NOT EXISTS (SELECT * FROM TC_CatalogoObservacion WHERE I_ObservID = 58)
BEGIN
	INSERT INTO TC_CatalogoObservacion (I_ObservID, T_ObservDesc, T_ObservCod, I_Severidad, I_TablaID) 
								VALUES (58, 'El detalle de la obligacion no tiene asociado un ID de la obligacion.', 'SIN OBLIGACION', NULL, 4)
END
GO

IF NOT EXISTS (SELECT * FROM TC_CatalogoObservacion WHERE I_ObservID = 59)
BEGIN
	INSERT INTO TC_CatalogoObservacion (I_ObservID, T_ObservDesc, T_ObservCod, I_Severidad, I_TablaID) 
								VALUES (59, 'La cabecera de obligacion se encuentra duplicada.', 'OBL duplicado', NULL, 5)
END
GO


IF NOT EXISTS (SELECT * FROM TC_EtapaProceso)
BEGIN
	INSERT INTO TC_EtapaProceso (I_EtapaProcesoID, T_EtapaProcDesc) VALUES (1, 'Copia de datos')
	INSERT INTO TC_EtapaProceso (I_EtapaProcesoID, T_EtapaProcDesc) VALUES (2, 'Validación de consistencia')
	INSERT INTO TC_EtapaProceso (I_EtapaProcesoID, T_EtapaProcDesc) VALUES (3, 'Migración a Recaudación de Ingresos')
END
GO


DELETE dbo.TI_ObservacionRegistroTabla where I_TablaID in (4,5,7)
DECLARE @I_ObsTablaID INT = (SELECT ISNULL(MAX(I_ObsTablaID), 0) FROM TI_ObservacionRegistroTabla)
DBCC CHECKIDENT('TI_ObservacionRegistroTabla', 'RESEED', @I_ObsTablaID)

SELECT * INTO #temp_observados FROM TI_ObservacionRegistroTabla

TRUNCATE TABLE dbo.TI_ObservacionRegistroTabla

INSERT INTO TI_ObservacionRegistroTabla (I_ObservID, I_TablaID, I_FilaTablaID, I_ProcedenciaID, D_FecRegistro, B_Resuelto, D_FecResuelto, B_ObligProc)
SELECT I_ObservID, I_TablaID, I_FilaTablaID, I_ProcedenciaID, D_FecRegistro, B_Resuelto, D_FecResuelto, B_ObligProc
FROM #temp_observados


UPDATE Obs
   SET I_ProcedenciaID = CP.I_ProcedenciaID
  FROM TI_ObservacionRegistroTabla Obs
	   INNER JOIN TR_Cp_Des CP ON Obs.I_FilaTablaID = CP.I_RowID
								  AND Obs.I_TablaID = 2
 WHERE Obs.I_ProcedenciaID IS NULL


 UPDATE Obs
   SET I_ProcedenciaID = CP.I_ProcedenciaID
  FROM TI_ObservacionRegistroTabla Obs
	   INNER JOIN TR_Cp_Pri CP ON Obs.I_FilaTablaID = CP.I_RowID
								  AND Obs.I_TablaID = 3
 WHERE Obs.I_ProcedenciaID IS NULL