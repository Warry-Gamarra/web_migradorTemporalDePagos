USE BD_OCEF_MigracionTP
GO

UPDATE TC_ProcedenciaData SET T_ProcedenciaDesc = 'TASAS' WHERE I_ProcedenciaID = 4
GO

--INSERT INTO TC_CatalogoTabla (I_TablaID, T_TablaNom) VALUES (8, 'TR_Tasas_Cp_Des')
--INSERT INTO TC_CatalogoTabla (I_TablaID, T_TablaNom) VALUES (9, 'TR_Tasas_Cp_Pri')
INSERT INTO TC_CatalogoTabla (I_TablaID, T_TablaNom) VALUES (10, 'TR_Tasas_Ec_Obl')
INSERT INTO TC_CatalogoTabla (I_TablaID, T_TablaNom) VALUES (11, 'TR_Tasas_Ec_Det')
INSERT INTO TC_CatalogoTabla (I_TablaID, T_TablaNom) VALUES (12, 'TR_Tasas_Ec_Det_Pagos')
GO


INSERT INTO TC_CatalogoObservacion (I_ObservID, T_ObservDesc, T_ObservCod, I_Severidad, I_TablaID) VALUES (51, 'El concepto de pago contiene verdadero en el campo obligaci�n', 'NO OBLIGACION', NULL, 3)
GO