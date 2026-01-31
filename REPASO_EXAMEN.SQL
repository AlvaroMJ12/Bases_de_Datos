-- DQL 

/* AgregaciónFunciones como COUNT(), SUM(), AVG(), MAX(), MIN().
Se usan en el SELECT para calcular un valor único para un grupo de filas.
- GROUP BY Agrupa filas con valores idénticos en columnas específicas.
    Cuando usas una función de agregación, cualquier columna en el SELECT que no sea una función de agregación debe aparecer aquí.
- HAVING Filtra los resultados de la agregación.
    Se usa después del GROUP BY para aplicar condiciones sobre los totales (ej., "solo grupos con COUNT > 10").
- WHERE Filtra las filas antes de la agregación.
    Se usa antes del GROUP BY para descartar filas individuales (ej., "solo medallas = 'oro'"). */

-- 5. Queremos obtener un informe que muestre cuántos atletas de cada continente han ganado
--una medalla de oro en los eventos de las olimpiadas, así como los países del continente que--
--la han obtenido. (RA3 2 puntos) (string_agg) -- 


-- Se utiliza string_agg para que la salida sea como en el ejercicio
select p.continente, count(r.medalla) || ' oros' as medallas_totales, string_agg(distinct p.nombre, ', ' order by p.nombre) as Paises
from atletas a
join paises p on p.id_pais = a.id_pais 
join resultados r on r.id_atleta = a.id_atleta
where r.medalla = 'oro'
group by p.continente;


-- 6. Queremos un informe que muestre el número total de medallas (oro, plata y bronce)
-- ganadas por continente. Además, incluiremos un ranking. (RA3 1.5 puntos)

-- utilizamos el rank para hacer el ranking

select upper(p.continente), count(r.medalla) as total_medallas, rank() over (order by count(r.medalla) desc) as ranking
from atletas a
join paises p on p.id_pais = a.id_pais 
join resultados r on r.id_atleta = a.id_atleta
where r.medalla is not null
group by p.continente;


-- 7. Queremos calcular el promedio de edad de los atletas que han ganado medallas (oro, plata
-- o bronce) en el momento del evento. (RA3 1.5 puntos)

-- Utilizamos round(que queremos redondear, numero de decimales que queremos)
-- extract(que queremos extraer "year,week,day" from donde queramos)
select 
	'Medalla de ' || initcap(r.medalla) as "Tipo medalla", 
	round(AVG((extract(year from r.fecha_evento))-(extract(year from a.fecha_nacimiento))),1) ||' años' as "Promedio de edad",
	count(a.id_atleta) as "Total de atletas"
from atletas a
join paises p on p.id_pais = a.id_pais 
join resultados r on r.id_atleta = a.id_atleta
where r.medalla is not null
group by r.medalla
order by round(AVG((extract(year from r.fecha_evento))-(extract(year from a.fecha_nacimiento))),1) desc;



--8. Queremos identificar a los atletas que ganaron una medalla el mismo día de su cumpleaños
--(misma fecha y mes, ignorando el año), mostrando su nombre completo, tipo de medalla y
--la edad que tenían ese día. (RA3 1.5 puntos)

-- Usamos to_char(fecha, lo que queramos extraer'DD/MM/YYYY')  * EXTRACT Obtener valores numéricos  * TO_CHAR Formatear la fecha como texto
select 
	a.nombre || ' ' || a.apellido as nombre_completo, 
	r.medalla as tipo_medalla,
	extract(year from r.fecha_evento)-extract(year from a.fecha_nacimiento) as edad_en_evento
from atletas a
join paises p on p.id_pais = a.id_pais 
join resultados r on r.id_atleta = a.id_atleta
where r.medalla is not null and to_char(r.fecha_evento, 'DD/MM') = to_char(a.fecha_nacimiento, 'DD/MM');



--9. Queremos listar los países que han ganado medallas, ordenadas por oro, luego por plata
--y finalmente por bronce (RA3 2 puntos)

-- Usamos SUM() y CASE WHEN (condicion) THEN (resultado) ELSE (otro resultado) NED
select 
	p.nombre as pais, 
	sum(case when r.medalla = 'oro' then 1 else 0 end) as oros,
	sum(case when r.medalla = 'plata' then 1 else 0 end) as platas,
	sum(case when r.medalla = 'bronce' then 1 else 0 end) as bronces
from atletas a
join paises p on p.id_pais = a.id_pais 
join resultados r on r.id_atleta = a.id_atleta
where r.medalla is not null
group by p.nombre
order by oros desc;