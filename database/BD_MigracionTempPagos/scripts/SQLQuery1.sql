select distinct cp.cuota_pago, cp.descripcio --, obl.* 
from EUPG_ec_obl obl
	 inner join EUPG_cp_des cp on cp.cuota_pago = obl.cuota_pago


select * from EUPG_ec_obl 
where cuota_pago in (170,
171,
198)

select * from EUPG_cp_des where cuota_pago = 54
select * from EUPG_cp_pri where id_cp in (
838	,
2185,
1747,
3047)

select * from EUPG_ec_obl 
where 
cuota_pago = 142
--AND ano = '2005'
--AND p = '2'
AND cod_alu = '2004314525'

SELECT * FROM PRE_ec_det WHERE cuota_pago = 142

select * from EUPG_ec_det where COD_ALU = '0009662048'


select COUNT(*) 
from EUPG_ec_obl WHERE pagado = 1

SELECT distinct ano, concepto, COUNT (concepto) 
FROM dbo.EUPG_ec_det 
WHERE eliminado = 0
	  AND pagado = 1
	  AND concepto_f = 1
	  and tipo_oblig = 1
	  --and concepto = 4788
group by ano, concepto
order by 1 asc


SELECT COUNT (*)
FROM dbo.EUPG_ec_det 
WHERE eliminado = 0
	  AND pagado = 1
	 -- AND concepto_f = 1
	  AND tipo_oblig <> 1

SELECT COUNT (*)
FROM dbo.EUPG_ec_det 
WHERE eliminado = 0
	  AND pagado = 1
	  AND concepto_f = 1
	  AND tipo_oblig = 1


SELECT *
FROM dbo.EUPG_ec_det 
WHERE eliminado = 0
	  AND pagado = 1
	  AND concepto_f = 1