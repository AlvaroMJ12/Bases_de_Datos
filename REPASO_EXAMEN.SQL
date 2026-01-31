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

-- DML

/* 10. Queremos actualizar los nombres de los países a mayúsculas, para aquellos países que han
ganado medallas en más de 5 deportes diferentes. (RA3 0.75 puntos , RA4 2 puntos)
*/
-- Usamos el IN para decir que los nombres que esstén ahi dentro se pongan en mayúsculas

update paises set nombre = upper(nombre) where nombre in (	
	SELECT p.nombre
		from atletas a
		join paises p on p.id_pais = a.id_pais 
		join resultados r on r.id_atleta = a.id_atleta
		join deportes d on d.id_deporte = r.id_deporte
		where r.medalla is not null
		group by p.id_pais
		having count(distinct(d.id_deporte)) > 5
);


/*
11. Queremos cambiar el país de los atletas que han ganado un mínimo de dos medallas a un
país ficticio "Olímpicos" con id_pais y código de país con valor 999, y continente "Olimpia",
simulando así una nacionalidad honorífica. Todo en un solo comando. (RA3 0.75 RA4 2
puntos)
*/
WITH crear_nacionalidad AS (
    -- PARTE 1: Definimos el país ficticio si no existe
    INSERT INTO paises (id_pais, nombre, codigo_pais, continente)
    VALUES (999, 'Olímpicos', '999', 'Olimpia')
    ON CONFLICT (id_pais) DO NOTHING -- Seguridad: si ya existe, no da error
)
-- PARTE 2: El comando principal (el UPDATE)
UPDATE atletas
SET id_pais = 999
WHERE id_atleta IN (
    -- Filtramos: solo los que tienen un mínimo de 2 medallas
    SELECT id_atleta
    FROM resultados
    GROUP BY id_atleta
    HAVING COUNT(id_resultado) >= 2
);

/*
12. Queremos cambiar las medallas de plata a oro para deportistas que tenían menos de 30
años en el momento de ganarlas, como un incentivo a la juventud. (RA4 2 puntos)
*/

UPDATE resultados 
SET medalla = 'oro' 
WHERE id_resultado IN ( -- Filtramos la fila exacta, no al atleta completo
    SELECT r.id_resultado
    FROM resultados r
    JOIN atletas a ON a.id_atleta = r.id_atleta
    WHERE r.medalla = 'plata' 
    AND (EXTRACT(YEAR FROM r.fecha_evento) - EXTRACT(YEAR FROM a.fecha_nacimiento)) < 30
);

/*
13. Queremos añadir el sufijo " - Doble" al apellido de los atletas que han ganado más de una
medalla (RA4 2 puntos)
*/

UPDATE atletas SET apellido = apellido || ' - Doble' where id_atleta  in (
	SELECT a.id_atleta
	from atletas a
	join resultados r on r.id_atleta = a.id_atleta
	group by a.id_atleta
	having count(r.medalla) > 1
)	

/*
14. Actualizar el nombre del país añadiendo tantos * al nombre como medallas de oro ha
obtenido. (RA4 2 puntos).
*/
UPDATE paises p set  nombre = nombre || REPEAT('*', (
	SELECT count(r.medalla)
	from atletas a
	join resultados r on r.id_atleta = a.id_atleta
	where r.medalla = 'oro' and p.id_pais = a.id_pais
)) where id_pais in(
	select p.id_pais
	from atletas a
	join paises p on p.id_pais = a.id_pais 
	join resultados r on r.id_atleta = a.id_atleta
	where r.medalla = 'oro'
	group by p.id_pais
);

/*
15. Crear una función llamada contar_medallas_pais, que reciba el nombre de un país y
devuelva el número total de medallas (oro, plata, bronce) que ha ganado. Si el país no
existe o no tiene medallas, debe devolver 0. (RA5 1.25 puntos)
*/
CREATE OR REPLACE FUNCTION contar_medallas_pais(p_nombre_pais text)
returns integer as $$
declare
	v_total_medallas integer:= 0;
begin
			select count(r.medalla)
			into v_total_medallas
			from atletas a
			join paises p on p.id_pais = a.id_pais 
			join resultados r on r.id_atleta = a.id_atleta
			where p.nombre = p_p_nombre_pais;

			RETURN v_total_medallas;
end;
$$ language plpgsql;


/*
16. Crear un procedimiento llamado registrar_medalla, que registre una nueva medalla en la
tabla resultados, recibiendo id_atleta, id_deporte, medalla y fecha_evento. Debe verificar
que el atleta, deporte existan antes de insertar. Además, el tipo de medalla debe ser oro o
plata o bronce, si al insertar no se cumple algo de lo antes dicho de debe generar una
excepción. Los mensajes serían Atleta xx no existe, Deporte xx no existe y Medalla xx no
válida. (RA5 1.25 puntos)
*/
begin;
CREATE OR REPLACE PROCEDURE registrar_medalla(p_id_atleta INTEGER, p_id_deporte INTEGER, p_medalla TEXT, p_fecha_evento DATE)
AS $$
DECLARE
BEGIN
	IF NOT EXISTS(
		select id_atleta
		from atletas 
		where id_atleta=p_id_atleta
		) THEN RAISE EXCEPTION 'Atleta % no existe', p_id_atleta;
	ELSIF NOT EXISTS(
		select id_deporte 
		from deportes 
		where id_deporte=p_id_deporte
		) THEN RAISE EXCEPTION 'Deporte % no existe', p_id_deporte;
	ELSIF p_medalla NOT IN('oro', 'plata', 'bronce') 
		THEN RAISE EXCEPTION 'Medalla % no válida', p_medalla;
	ELSE 
		INSERT INTO resultados(id_atleta, id_deporte, medalla, fecha_evento)
		VALUES (p_id_atleta, p_id_deporte, p_medalla, p_fecha_evento /*NO SE SI PONER CURRENT_DATE O LA FECHA QUE HE PUESTO*/);
	END IF;
END;
$$ LANGUAGE plpgsql;

rollback;