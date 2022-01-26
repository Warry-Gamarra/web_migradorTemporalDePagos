select distinct cp.cuota_pago, cp.descripcio --, obl.* 
from PRE_ec_obl obl
	 inner join PRE_cp_des cp on cp.cuota_pago = obl.cuota_pago


select * from PRE_ec_obl 
where cuota_pago in (324, 321, 51, 8)
order by ano, cod_alu desc


select COUNT(*) 
from PRE_ec_obl WHERE pagado = 1


SELECT *
FROM dbo.PRE_ec_det 
WHERE eliminado = 1
	  AND pagado = 1
	  AND concepto_f = 1
	 
SELECT DISTINCT tipo_pago
FROM PRE_ec_det 

SELECT * FROM PRE_ec_det WHERE tipo_pago = 1-- AND concepto_f = 1

SELECT * FROM cp_pri WHERE ID_CP = 3008


SELECT det.ano, concepto, det.cuota_pago, pri.descripcio
--SELECT distinct det.ano, concepto, COUNT (concepto) 
FROM dbo.PRE_ec_det det
inner join dbo.pre_cp_pri pri on det.concepto = pri.id_cp --and det.cuota_pago = pri.cuota_pago
WHERE det.eliminado = 0
	  AND pagado = 1
	  AND concepto_f = 1
	 -- and det.tipo_oblig = 1
	  --and concepto = 4788
group by det.ano, concepto
order by 1 asc


select * from PRE_cp_pri
where id_cp = 6924