delete TI_CtaDepo_Proceso
delete TC_Proceso

delete TC_CuentaDeposito_CategoriaPago
delete TC_CategoriaPago

dbcc checkident(TC_CuentaDeposito_CategoriaPago,reseed, 0)
dbcc checkident(TC_CategoriaPago,reseed, 0)
dbcc checkident(TI_CtaDepo_Proceso,reseed, 0)
dbcc checkident(TC_Proceso,reseed, 0)


delete TI_ConceptoPago
delete TC_Concepto
dbcc checkident(TI_ConceptoPago,reseed, 0)
dbcc checkident(TC_Concepto,reseed, 0)


SELECT SUBSTRING(C_DepCodPl, 6, 5), * FROM TC_DependenciaUNFV
ORDER BY 1

SELECT DISTINCT LEN(C_DepCodPl) FROM TC_DependenciaUNFV


