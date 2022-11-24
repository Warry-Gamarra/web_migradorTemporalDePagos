USE BD_OCEF_MigracionTP
GO

INSERT INTO TC_CatalogoObservacion (I_ObservID, T_ObservDesc, T_ObservCod, I_Severidad) VALUES (42, 'La cuota de pago del detalle no es la misma que la cuota de pago del concepto.', 'CUOTA PAGO CP_PRI', NULL)
INSERT INTO TC_CatalogoObservacion (I_ObservID, T_ObservDesc, T_ObservCod, I_Severidad) VALUES (43, 'El año del detalle no coincide con el año del concepto en cp_pri.', 'DIF. AÑO CP_PRI', NULL)
INSERT INTO TC_CatalogoObservacion (I_ObservID, T_ObservDesc, T_ObservCod, I_Severidad) VALUES (44, 'El periodo del detalle no coincide con el año del concepto en cp_pri.', 'DIF. PERIODO CP_PRI', NULL)
INSERT INTO TC_CatalogoObservacion (I_ObservID, T_ObservDesc, T_ObservCod, I_Severidad) VALUES (45, 'El registro se encuentra con estado Eliminado y no será parte de la migración.', 'REMOVIDO', NULL)


GO


UPDATE tb_obs
   SET tb_obs.I_ProcedenciaID = cp_des.I_ProcedenciaID
  FROM TI_ObservacionRegistroTabla tb_obs 
	   INNER JOIN TR_Cp_Des cp_des on cp_des.I_RowID = tb_obs.I_FilaTablaID AND tb_obs.I_TablaID = 2
GO


