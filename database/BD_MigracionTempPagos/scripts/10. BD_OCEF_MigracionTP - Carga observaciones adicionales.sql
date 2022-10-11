USE BD_OCEF_MigracionTP
GO

INSERT INTO TC_CatalogoObservacion (I_ObservID, T_ObservDesc, T_ObservCod, I_Severidad) VALUES (42, 'La cuota de pago del detalle no es la misma que la cuota de pago del concepto.', 'CUOTA PAGO CP_PRI', NULL)
INSERT INTO TC_CatalogoObservacion (I_ObservID, T_ObservDesc, T_ObservCod, I_Severidad) VALUES (43, 'El año del detalle no coincide con el año del concepto en cp_pri.', 'DIF. AÑO CP_PRI', NULL)
INSERT INTO TC_CatalogoObservacion (I_ObservID, T_ObservDesc, T_ObservCod, I_Severidad) VALUES (44, 'El periodo del detalle no coincide con el año del concepto en cp_pri.', 'DIF. PERIODO CP_PRI', NULL)
