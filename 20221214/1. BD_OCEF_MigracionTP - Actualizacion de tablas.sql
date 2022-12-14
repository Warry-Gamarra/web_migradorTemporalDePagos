USE [BD_OCEF_MigracionTP]
GO

INSERT INTO TC_CatalogoObservacion (I_ObservID, T_ObservDesc, T_ObservCod, I_Severidad) VALUES (46, 'El concepto de pago contiene falso en el campo obligación.', 'NO OBLIGACION', NULL)
GO


IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'TR_Cp_Pri' AND COLUMN_NAME = 'B_MantenerAnio')
BEGIN
	ALTER TABLE [dbo].[TR_Cp_Pri]
		ADD B_MantenerAnio		bit	 NULL DEFAULT 0,
			B_MantenerPeriodo	bit	 NULL DEFAULT 0
END
GO


UPDATE TR_Cp_Pri 
   SET B_MantenerAnio = 0
 WHERE B_MantenerAnio IS NULL
GO

UPDATE TR_Cp_Pri 
   SET B_MantenerPeriodo = 0
 WHERE B_MantenerPeriodo IS NULL
 GO


DELETE FROM TI_ObservacionRegistroTabla WHERE I_ProcedenciaID IS NULL
GO
 

DELETE FROM TI_ObservacionRegistroTabla WHERE I_TablaID = 3
GO
