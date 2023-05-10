USE BD_OCEF_MigracionTP
GO


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.VIEWS WHERE TABLE_NAME = 'VW_ObservacionesEcDet')
	DROP VIEW [dbo].[VW_ObservacionesEcDet]
GO

CREATE VIEW VW_ObservacionesEcDet
AS
(
	SELECT  I_ObsTablaID, ORT.D_FecRegistro, ORT.I_ObservID, CO.T_ObservDesc,
			ORT.I_FilaTablaID, CO.T_ObservCod, CO.I_Severidad, ORT.I_ProcedenciaID, ORT.B_Resuelto, ORT.D_FecResuelto
	FROM	TI_ObservacionRegistroTabla ORT
			INNER JOIN TC_CatalogoObservacion CO ON ORT.I_ObservID = CO.I_ObservID
	WHERE	ORT.I_TablaID = 4
)
GO


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.VIEWS WHERE TABLE_NAME = 'VW_ObservacionesEcObl')
	DROP VIEW [dbo].[VW_ObservacionesEcObl]
GO

CREATE VIEW VW_ObservacionesEcObl
AS
(
	SELECT  I_ObsTablaID, ORT.D_FecRegistro, ORT.I_ObservID, CO.T_ObservDesc,
			ORT.I_FilaTablaID, CO.T_ObservCod, CO.I_Severidad, ORT.I_ProcedenciaID, ORT.B_Resuelto, ORT.D_FecResuelto
	FROM	TI_ObservacionRegistroTabla ORT
			INNER JOIN TC_CatalogoObservacion CO ON ORT.I_ObservID = CO.I_ObservID
	WHERE	ORT.I_TablaID = 5
)
GO
