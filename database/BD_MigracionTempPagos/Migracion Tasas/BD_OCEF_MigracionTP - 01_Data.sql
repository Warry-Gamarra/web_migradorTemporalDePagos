USE BD_OCEF_MigracionTP
GO

UPDATE TC_ProcedenciaData SET T_ProcedenciaDesc = 'TASAS' WHERE I_ProcedenciaID = 4
GO


INSERT INTO TC_CatalogoObservacion (I_ObservID, T_ObservDesc, T_ObservCod, I_Severidad, I_TablaID) VALUES (51, 'El concepto de pago contiene verdadero en el campo obligación', 'NO OBLIGACION', NULL, 3)
GO