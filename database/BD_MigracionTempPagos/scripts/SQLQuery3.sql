select distinct cp.cuota_pago, cp.descripcio --, obl.* 
from EUDED_ec_obl obl
	 inner join EUDED_cp_des cp on cp.cuota_pago = obl.cuota_pago


select COUNT(*) from EUDED_ec_obl where tipo_oblig = 1
select COUNT(*) from EUDED_ec_obl 


select * from EUDED_ec_obl 
where cuota_pago in (253, 235, 234, 198)
and ano = '2013'
order by ano, cod_alu desc


SELECT distinct ano, concepto, COUNT (concepto) 
FROM dbo.EUDED_ec_det 
WHERE eliminado = 0
	  AND pagado = 1
	  AND concepto_f = 1
	  ---and concepto = 4788
group by ano, concepto
order by 1 asc




select COUNT(*) from EUDED_ec_obl WHERE pagado = 1


SELECT COUNT (*)
FROM dbo.EUDED_ec_det 
WHERE eliminado = 0
	  AND pagado = 1
	  AND concepto_f = 1
	  AND cuota_pago = 0

