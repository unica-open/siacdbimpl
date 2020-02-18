/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac."BILR027_Entrate_riepilogo_ueb_RISP_VINCOLI" (
  p_ente_prop_id integer,
  p_tipo_bilancio varchar,
  p_anno varchar,
  p_capitolo varchar,
  p_articolo varchar,
  p_tipo_fin varchar
)
RETURNS TABLE (
  cod_capitolo_entrata varchar,
  capitolo varchar,
  articolo varchar,
  ueb varchar,
  ueb_id numeric,
  descrizione_capitolo varchar,
  descrizione_2_capitolo varchar,
  n_vincolo numeric,
  capitolo_di_entrata varchar,
  articolo_di_entrata varchar,
  ueb_di_entrata varchar
) AS
$body$
DECLARE
capitolo_entrata record;
elenco_ueb record;
BEGIN
	cod_capitolo_entrata='';
	capitolo='';
	articolo='';
	ueb='';
	ueb_id=0;
	descrizione_capitolo='';
	descrizione_2_capitolo='';
    n_vincolo=0;
    raise notice 'prima del capitolo entrata';
    capitolo_di_entrata='';
    raise notice 'prima articolo entrata';
	articolo_di_entrata='';
    raise notice 'prima ueb entrata';
	ueb_di_entrata='';
	raise notice 'parametro ente % ',p_ente_prop_id;
	raise notice 'parametro anno % ',p_anno;
	raise notice 'parametro capitolo % ',p_capitolo;
	raise notice 'parametro articolo % ',p_articolo;
	raise notice 'parametro tipo finanziamento % ',p_tipo_fin; 
for capitolo_entrata in
select  d.elem_id		cod_capitolo_entrata,
		d.elem_code		capitolo_di_entrata,
        d.elem_code2	articolo_di_entrata,
        d.elem_code3	ueb_di_entrata                  
from 	siac_r_bil_elem_class 	a,
		siac_t_class 			b,
		siac_d_class_tipo 		c,
		siac_t_bil_elem			d,	
        siac_d_bil_elem_tipo 	f
where 		d.elem_code 		=	p_capitolo 	
	and 	d.elem_code2 		=	p_articolo
	and 	d.elem_id			=	a.elem_id 
	and 	b.classif_id 		= 	a.classif_id
	and 	b.classif_tipo_id	= 	c.classif_tipo_id
	and 	c.classif_tipo_code in ('TIPO_FINANZIAMENTO')
	and		b.classif_code      = 	p_tipo_fin
	and 	d.elem_tipo_id		= 	f.elem_tipo_id
	and 	substr(f.elem_tipo_code,5,2) = p_tipo_bilancio
	and 	d.ente_proprietario_id = p_ente_prop_id
loop
	raise notice 'dentro loop elementi del biancio';
    raise notice '---------->>>>>>>>ueb_id % ',capitolo_entrata.cod_capitolo_entrata;
	cod_capitolo_entrata:=capitolo_entrata.cod_capitolo_entrata;
    capitolo_di_entrata:=capitolo_entrata.capitolo_di_entrata;
    articolo_di_entrata:=capitolo_entrata.articolo_di_entrata;
    ueb_di_entrata:=capitolo_entrata.ueb_di_entrata;
    
	begin
	for elenco_ueb in
    	select 	vincolo_capitolo.vincolo_id n_vincolo
		from   	siac_r_vincolo_bil_elem vincolo_capitolo			
 		where 	vincolo_capitolo.elem_id = capitolo_entrata.cod_capitolo_entrata
 		loop
    		begin
			for elenco_ueb in
    		select 	capitolo_spesa.elem_id			ueb_id,
            		capitolo_spesa.elem_code		capitolo,
					capitolo_spesa.elem_code2		articolo,
         			capitolo_spesa.elem_code3		ueb,
					capitolo_spesa.elem_desc		descrizione_capitolo,
        			decode (capitolo_spesa.elem_desc2,NULL,' ',capitolo_spesa.elem_desc2)	descrizione_2_capitolo
 			from 		siac_r_vincolo_bil_elem 	vincolo_capitolo,
						siac_t_bil_elem 			capitolo_spesa,
           				siac_d_bil_elem_tipo		tipo_capitolo
 			where 			vincolo_capitolo.vincolo_id 	= elenco_ueb.n_vincolo
 					and 	vincolo_capitolo.elem_id 		= capitolo_spesa.elem_id
 					and 	capitolo_spesa.elem_tipo_id 	= tipo_capitolo.elem_tipo_id
 					and		substr(tipo_capitolo.elem_tipo_code,5,2) in ('UG','UP')
                    and date_trunc('day',CURRENT_TIMESTAMP) 	> vincolo_capitolo.validita_inizio and
	 					 ((date_trunc('day',CURRENT_TIMESTAMP) < vincolo_capitolo.validita_fine)
							or (vincolo_capitolo.validita_fine is null)) 
			loop
            		raise notice '-->>>>>capitolo % ',elenco_ueb.capitolo;
					raise notice '-->>>>>articolo % ',elenco_ueb.articolo;
					raise notice '-->>>>>ueb % ',elenco_ueb.ueb;
					raise notice '-->>>>>descrizione % ',elenco_ueb.descrizione_capitolo;
					raise notice '-->>>>>descrizione 2 % ',elenco_ueb.descrizione_2_capitolo;
                    capitolo:= elenco_ueb.capitolo;
					articolo:= elenco_ueb.articolo;
					ueb:= elenco_ueb.ueb;
					ueb_id:=elenco_ueb.ueb_id;
					descrizione_capitolo:= elenco_ueb.descrizione_capitolo;
					descrizione_2_capitolo:= elenco_ueb.descrizione_2_capitolo;
                    ---raise notice '-->>>>>vincolo % ',elenco_ueb.n_vincolo;
    				
                    ------n_vincolo:=elenco_ueb.n_vincolo;
                    	return next;
    		end loop;
            	
    		end;
            		
 		end loop;

        cod_capitolo_entrata='';
		capitolo='';
		articolo='';
		ueb='';
		ueb_id=0;
		descrizione_capitolo='';
		descrizione_2_capitolo='';
    	n_vincolo=0;
    exception
	when no_data_found THEN
		raise notice 'capitoli spesa non trovati' ;
		--return next;
	when others  THEN
		raise notice 'errore nella lettura capitoli di spesa ';
        return;
end;
raise notice 'fine OK';
end loop;
 exception
	when no_data_found THEN
		raise notice 'capitolo entrata non trovato' ;
		--return next;
	when others  THEN
		raise notice 'errore nella lettura capitolo di entrata ';
        return;
return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100 ROWS 1000;