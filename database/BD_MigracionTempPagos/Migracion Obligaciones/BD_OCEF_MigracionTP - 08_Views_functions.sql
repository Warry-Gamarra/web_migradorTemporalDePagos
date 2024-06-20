USE BD_OCEF_MigracionTP
GO

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.VIEWS WHERE TABLE_NAME = 'VW_ObservacionesTabla')
	DROP VIEW [dbo].[VW_ObservacionesTabla]
GO

CREATE VIEW VW_ObservacionesTabla
AS
(
	SELECT  I_ObsTablaID, ORT.D_FecRegistro, ORT.I_TablaID, T_TablaNom, ORT.I_ObservID, CO.T_ObservDesc, B_ObligProc,
			ORT.I_FilaTablaID, CO.T_ObservCod, CO.I_Severidad, ORT.I_ProcedenciaID, ORT.B_Resuelto, ORT.D_FecResuelto
	FROM	TI_ObservacionRegistroTabla ORT
			INNER JOIN TC_CatalogoTabla CT ON ORT.I_TablaID = CT.I_TablaID
			INNER JOIN TC_CatalogoObservacion CO ON ORT.I_ObservID = CO.I_ObservID
)
GO



/****************************************************************
 ****************************************************************
							FUNCIONES
 ****************************************************************
 ****************************************************************/


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'FUNCTION' AND ROUTINE_NAME = 'Func_Config_CtasPorCobrar_I_ObtenerUsuarioMigracionID')
	DROP FUNCTION [dbo].[Func_Config_CtasPorCobrar_I_ObtenerUsuarioMigracionID]
GO

CREATE FUNCTION dbo.Func_Config_CtasPorCobrar_I_ObtenerUsuarioMigracionID ()
RETURNS INT
AS
BEGIN
	RETURN (SELECT UserId FROM BD_OCEF_CtasPorCobrar.dbo.TC_Usuario WHERE UserName = 'User_Migracion')
END
GO
