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


IF NOT EXISTS (SELECT * FROM TC_CatalogoObservacion WHERE I_ObservID = 51)
BEGIN
	INSERT INTO TC_CatalogoObservacion (I_ObservID, T_ObservDesc, T_ObservCod, I_Severidad, I_TablaID) 
								VALUES (51, 'El concepto de pago contiene verdadero en el campo obligaci�n', 'NO OBLIGACION', NULL, 3)
END
GO


IF NOT EXISTS (SELECT * FROM TC_CatalogoObservacion WHERE I_ObservID = 57)
BEGIN
	INSERT INTO TC_CatalogoObservacion (I_ObservID, T_ObservDesc, T_ObservCod, I_Severidad, I_TablaID) 
								VALUES (57, 'El pago tiene observaciones en la cabecera de la obligacion.', 'OBSERVACI�N OBLIG.', NULL, 7)
END
GO

IF NOT EXISTS (SELECT * FROM TC_CatalogoObservacion WHERE I_ObservID = 58)
BEGIN
	INSERT INTO TC_CatalogoObservacion (I_ObservID, T_ObservDesc, T_ObservCod, I_Severidad, I_TablaID) 
								VALUES (58, 'El detalle de la obligacion no tiene asociado un ID de la obligacion.', 'SIN OBLIGACION', NULL, 4)
END
GO



IF NOT EXISTS (SELECT * FROM TC_EtapaProceso)
BEGIN
	INSERT INTO TC_EtapaProceso (I_EtapaProcesoID, T_EtapaProcDesc) VALUES (1, 'Copia de datos')
	INSERT INTO TC_EtapaProceso (I_EtapaProcesoID, T_EtapaProcDesc) VALUES (2, 'Validaci�n de consistencia')
	INSERT INTO TC_EtapaProceso (I_EtapaProcesoID, T_EtapaProcDesc) VALUES (3, 'Migraci�n a Recaudaci�n de Ingresos')
END
GO

