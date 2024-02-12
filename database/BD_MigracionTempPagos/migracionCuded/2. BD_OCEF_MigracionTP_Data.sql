USE BD_OCEF_MigracionTP
GO

UPDATE TC_CatalogoObservacion SET I_TablaID = 1  WHERE I_ObservID IN (1, 2, 21, 22, 23, 30, 31, 41, 47, 48)
UPDATE TC_CatalogoObservacion SET I_TablaID = 2  WHERE I_ObservID IN (3, 4, 5, 6, 7, 8, 9, 10, 11)
UPDATE TC_CatalogoObservacion SET I_TablaID = 3  WHERE I_ObservID IN (12, 13, 14, 16, 18, 19, 20, 46)
UPDATE TC_CatalogoObservacion SET I_TablaID = 4  WHERE I_ObservID IN (15, 17, 25, 33, 35, 42, 43, 44)
UPDATE TC_CatalogoObservacion SET I_TablaID = 5  WHERE I_ObservID IN (24, 26, 27, 28, 29, 32, 34, 36, 37, 38, 39, 40, 49)
GO


UPDATE TC_CatalogoObservacion
   SET T_ObservDesc = 'A�o del concepto en el detalle no coincide con a�o del concepto en cp_pri'
 WHERE I_ObservID = 43
GO

UPDATE TC_CatalogoObservacion
   SET T_ObservDesc = 'Periodo del concepto en el detalle no coincide con periodo del concepto en cp_pri'
 WHERE I_ObservID = 44
GO

UPDATE TC_CatalogoObservacion
   SET T_ObservDesc = 'El a�o del concepto en el detalle de la obligaci�n no coincide con el a�o del concepto en cp_pri'
 WHERE I_ObservID = 15
GO

UPDATE TC_CatalogoObservacion
   SET T_ObservDesc = 'El periodo del concepto en el detalle de la obligaci�n. no coincide con el periodo del concepto en cp_pri.'
 WHERE I_ObservID = 17
GO


INSERT INTO TC_CatalogoObservacion (I_ObservID, T_ObservDesc, T_ObservCod, I_Severidad, I_TablaID) VALUES (49, 'El monto acumulado de los conceptos en el detalle no corresponde con el monto indicado en la obligaci�n', 'ERROR MONTO', NULL, 4)
INSERT INTO TC_CatalogoObservacion (I_ObservID, T_ObservDesc, T_ObservCod, I_Severidad, I_TablaID) VALUES (50, 'La cuota de pago existe repetida en otra procedenca', 'REPETIDO', NULL, 2)
GO


--INSERT INTO TC_CatalogoObservacion (I_ObservID, T_ObservDesc, T_ObservCod, I_Severidad) VALUES (49, 'A�o del concepto en el detalle no coincide con a�o del concepto en cp_pri', 'A�O CONCEPTO', NULL)
--INSERT INTO TC_CatalogoObservacion (I_ObservID, T_ObservDesc, T_ObservCod, I_Severidad) VALUES (49, 'A�o del concepto en el detalle no coincide con a�o del concepto en cp_pri', 'A�O CONCEPTO', NULL)
--INSERT INTO TC_CatalogoObservacion (I_ObservID, T_ObservDesc, T_ObservCod, I_Severidad) VALUES (49, 'A�o del concepto en el detalle no coincide con a�o del concepto en cp_pri', 'A�O CONCEPTO', NULL)
--select LEN('El a�o del concepto en el detalle de la obligaci�n no corresponde con el a�o del concepto en cp_pri')


