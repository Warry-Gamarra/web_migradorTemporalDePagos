USE BD_OCEF_CtasPorCobrar
GO

DELETE TRI_PagoProcesadoUnfv WHERE B_Migrado = 1
DELETE TR_PagoBanco WHERE B_Migrado = 1
DELETE TR_ObligacionAluDet WHERE B_Migrado = 1
DELETE TR_ObligacionAluCab WHERE B_Migrado = 1 

DECLARE @I_PagoBancoID int
DECLARE @I_PagoProcID int
DECLARE @I_ObligacionAluDetID int
DECLARE @I_ObligacionAluCabID int

SET @I_PagoBancoID = (SELECT MAX(I_PagoBancoID) FROM TR_PagoBanco)
SET @I_PagoProcID  = (SELECT MAX(I_PagoProcesID) FROM TRI_PagoProcesadoUnfv)
SET @I_ObligacionAluDetID  = (SELECT MAX(I_ObligacionAluDetID) FROM TR_ObligacionAluDet)
SET @I_ObligacionAluCabID  = (SELECT MAX(I_ObligacionAluID) FROM TR_ObligacionAluCab)


DBCC CHECKIDENT('TR_PagoBanco', 'RESEED', @I_PagoBancoID)
DBCC CHECKIDENT('TRI_PagoProcesadoUnfv', 'RESEED', @I_PagoProcID)
DBCC CHECKIDENT('TR_ObligacionAluDet', 'RESEED', @I_ObligacionAluDetID)
DBCC CHECKIDENT('TR_ObligacionAluCab', 'RESEED', @I_ObligacionAluCabID)