TRUNCATE TABLE TR_Ec_Det_Pagos
TRUNCATE TABLE TR_Ec_Det
DELETE dbo.TI_ObservacionRegistroTabla where I_TablaID in (4,5,7)
DECLARE @I_ObsTablaID INT = (SELECT MAX(I_ObsTablaID) FROM TI_ObservacionRegistroTabla)
DBCC CHECKIDENT('TI_ObservacionRegistroTabla', 'RESEED', @I_ObsTablaID)

DELETE TR_Ec_Obl
DBCC CHECKIDENT('TR_Ec_Obl', 'RESEED', 0)



exec sp_change_users_login 'report'
exec sp_change_users_login 'auto_fix', 'UserOCEF'
exec sp_change_users_login 'auto_fix', 'UserUNFV'


UPDATE webpages_Membership SET Password = 'AP4rEZG+/M6zCwEgQfjF5lDadZ3Sr7MCnroZzIXlwDEXCY/Q1esZcx1gPlGIV3ERjA=='