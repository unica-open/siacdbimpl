/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
﻿CREATE OR REPLACE FUNCTION siac."BILR027_Entrate_riepilogo_ueb_RISP" (
  p_ente_prop_id integer,
  p_tipo_bilancio varchar,
  p_anno varchar,
  p_capitolo varchar,
  p_articolo varchar,
  p_tipo_fin varchar
)
RETURNS TABLE (
  bil_anno numeric,
  capitolo varchar,
  articolo varchar,
  ueb varchar,
  ueb_id numeric,
  descrizione_capitolo varchar,
  descrizione_2_capitolo varchar,
  settore varchar,
  coel varchar,
  tipo_finanziamento varchar,
  stanziamento_iniziale numeric,
  stanziamento_definitivo numeric,
  variazioni_provvisorie numeric,
  accertato numeric,
  disponibile numeric,
  tipo_capitolo varchar,
  titolo varchar,
  tipologia varchar,
  categoria varchar,
  descrizione_titolo varchar,
  descrizione_tipologia varchar,
  descrizione_categoria varchar,
  flag_rilevante_iva varchar
) AS
$body$
DECLARE
elenco_ueb record;
classificatori_ueb record;
importi_ueb record;
annoCapImp varchar;
elemTipoCode varchar;
TipoImpComp varchar;
TipoImpIni varchar;
tipoimporto varchar;
DEF_NULL	constant varchar:=''; 
RTN_MESSAGGIO varchar(1000):=DEF_NULL;
BEGIN
	annoCapImp:= p_anno; 
	raise notice '%', annoCapImp;
	TipoImpComp='STA';  		-------- competenza
	TipoImpIni='STI'; 			-------- iniziale
	-----elemTipoCode:='CAP-UP'; 	-------- tipo capitolo previsione
	bil_anno=0;
	capitolo='';
	articolo='';
	ueb='';
	ueb_id=0;
	descrizione_capitolo='';
	descrizione_2_capitolo='';
	tipo_finanziamento='';
	settore='';
	coel='';
	titolo='';
    tipologia='';
    categoria='';
    descrizione_titolo='';
    descrizione_tipologia='';
	descrizione_categoria='';
	stanziamento_iniziale=0;
	stanziamento_definitivo=0;
	variazioni_provvisorie=0;
	accertato=0;
	disponibile=0;
	tipo_capitolo='';
    flag_rilevante_iva='';
	raise notice 'parametro ente % ',p_ente_prop_id;
	raise notice 'parametro anno % ',p_anno;
	raise notice 'parametro capitolo % ',p_capitolo;
	raise notice 'parametro articolo % ',p_articolo;
	raise notice 'parametro tipo finanziamento % ',p_tipo_fin; 
for elenco_ueb in
select  		d.elem_id		ueb_id,
					d.elem_code		capitolo,
            		d.elem_code2	articolo,
            		d.elem_code3	ueb,	
					d.elem_desc		descrizione_capitolo,
            		-------------decode (d.elem_desc2,NULL,' ',d.elem_desc2)	descrizione_2_capitolo,
                    COALESCE (d.elem_desc2,' ')	descrizione_2_capitolo,
					b.classif_tipo_id , 
					b.classif_desc, 
           			b.classif_code,
            		c.classif_tipo_code,
            		f.elem_tipo_desc,
            		f.elem_tipo_code  tipo_capitolo               
from 		siac_r_bil_elem_class 	a,
			siac_t_class 			b,
            siac_d_class_tipo 		c,
            siac_t_bil_elem			d,
            siac_d_bil_elem_tipo 	f
where 	d.elem_code 		=	p_capitolo 	
and 	d.elem_code2 		=	p_articolo
and 	d.elem_id			=	a.elem_id 
and 	b.classif_id 		= 	a.classif_id
and 	b.classif_tipo_id	= 	c.classif_tipo_id
and 	c.classif_tipo_code in ('TIPO_FINANZIAMENTO')
and		b.classif_code      = 	p_tipo_fin
and 	d.elem_tipo_id		= 	f.elem_tipo_id
and 	substr(f.elem_tipo_code,5,2) = p_tipo_bilancio
and 	d.ente_proprietario_id = p_ente_prop_id
order by tipo_capitolo ,capitolo, articolo,ueb
loop
	raise notice 'dentro loop elementi del biancio';
	raise notice 'capitolo % ',elenco_ueb.capitolo;
	raise notice 'articolo % ',elenco_ueb.articolo;
	raise notice 'ueb % ',elenco_ueb.ueb;
	raise notice 'descrizione % ',elenco_ueb.descrizione_capitolo;
	raise notice 'descrizione 2 % ',elenco_ueb.descrizione_2_capitolo;
	capitolo:= elenco_ueb.capitolo;
	articolo:= elenco_ueb.articolo;
	ueb:= elenco_ueb.ueb;
	ueb_id:=elenco_ueb.ueb_id;
	descrizione_capitolo:= elenco_ueb.descrizione_capitolo;
	descrizione_2_capitolo:= elenco_ueb.descrizione_2_capitolo;
	tipo_capitolo:= elenco_ueb.tipo_capitolo;
	raise notice 'Fine elementi bilancio';
	bil_anno:=p_anno;
	begin
	for classificatori_ueb in
	select 		
		(select  b.classif_code
        	from 	siac_r_bil_elem_class 	a,
					siac_t_class 			b,
        			siac_d_class_tipo 		c
			where 
					d.elem_id			=	a.elem_id 
			and		b.classif_id 		= 	a.classif_id
			and 	b.classif_tipo_id 	= 	c.classif_tipo_id
			and 	c.classif_tipo_code in ('CLASSIFICATORE_41'))coel,

		(select b.classif_code
        	from siac_r_bil_elem_class 	a,
						siac_t_class 			b,
        				siac_d_class_tipo 		c
			where 
					d.elem_id			=	a.elem_id 
			and		b.classif_id 		= 	a.classif_id
			and 	b.classif_tipo_id 	= 	c.classif_tipo_id
			and 	c.classif_tipo_code in ('CDC'))	settore,
        (select b.classif_code
        	from siac_r_bil_elem_class 	a,
						siac_t_class 			b,
        				siac_d_class_tipo 		c
			where 
					d.elem_id			=	a.elem_id 
			and		b.classif_id 		= 	a.classif_id
			and 	b.classif_tipo_id 	= 	c.classif_tipo_id
			and 	c.classif_tipo_code in ('TIPO_FINANZIAMENTO'))tipo_finanziamento,
        (select e_tipologia.classif_desc 
      		from siac_r_bil_elem_class a, siac_d_class_tipo b, siac_t_class c,  siac_r_class_fam_tree d_categoria,
      		siac_t_class e_tipologia
     		 where a.elem_id = d.elem_id
      		and a.classif_id = c.classif_id
      		and c.classif_tipo_id = b.classif_tipo_id
      		and b.classif_tipo_code IN('CATEGORIA')
      		and d_categoria.classif_id = a.classif_id
      		and d_categoria.classif_id_padre = e_tipologia.classif_id)descrizione_tipologia,
	(select e_tipologia.classif_code
      from siac_r_bil_elem_class a, siac_d_class_tipo b, siac_t_class c,  siac_r_class_fam_tree d_categoria,
      siac_t_class e_tipologia
      where a.elem_id = d.elem_id
      and a.classif_id = c.classif_id
      and c.classif_tipo_id = b.classif_tipo_id
      and b.classif_tipo_code IN('CATEGORIA')
      and d_categoria.classif_id = a.classif_id
      and d_categoria.classif_id_padre = e_tipologia.classif_id)tipologia,
    (select c.classif_desc
      from siac_r_bil_elem_class a, siac_d_class_tipo b, siac_t_class c
      where a.elem_id = d.elem_id
      and a.classif_id = c.classif_id
      and c.classif_tipo_id = b.classif_tipo_id
      and b.classif_tipo_code IN('CATEGORIA'))descrizione_categoria,
    (select c.classif_code
      from siac_r_bil_elem_class a, siac_d_class_tipo b, siac_t_class c
      where a.elem_id = d.elem_id
      and a.classif_id = c.classif_id
      and c.classif_tipo_id = b.classif_tipo_id
      and b.classif_tipo_code IN('CATEGORIA'))categoria,
	(select f_titolo.classif_desc 
      from siac_r_bil_elem_class a, siac_d_class_tipo b, siac_t_class c,  siac_r_class_fam_tree d_categoria,
      siac_t_class e_tipologia, siac_t_class f_titolo, siac_r_class_fam_tree g_tipologia
      where a.elem_id = d.elem_id
      and a.classif_id = c.classif_id
      and c.classif_tipo_id = b.classif_tipo_id
      and b.classif_tipo_code IN('CATEGORIA')
      and d_categoria.classif_id = a.classif_id
      and d_categoria.classif_id_padre = e_tipologia.classif_id
      and g_tipologia.classif_id=e_tipologia.classif_id
      and g_tipologia.classif_id_padre = f_titolo.classif_id)descrizione_titolo,
	(select f_titolo.classif_code
      from siac_r_bil_elem_class a, siac_d_class_tipo b, siac_t_class c,  siac_r_class_fam_tree d_categoria,
      siac_t_class e_tipologia, siac_t_class f_titolo, siac_r_class_fam_tree g_tipologia
      where a.elem_id = d.elem_id
      and a.classif_id = c.classif_id
      and c.classif_tipo_id = b.classif_tipo_id
      and b.classif_tipo_code IN('CATEGORIA')
      and d_categoria.classif_id = a.classif_id
      and d_categoria.classif_id_padre = e_tipologia.classif_id
      and g_tipologia.classif_id=e_tipologia.classif_id
      and g_tipologia.classif_id_padre = f_titolo.classif_id)titolo,
        (select COALESCE (boolean,'N')	   from siac_r_bil_elem_attr a, siac_t_attr b
      		where 	a.elem_id 	= d.elem_id 
      		and 	a.attr_id 	= b.attr_id
      		and 	b.attr_code ='FlagRilevanteIva')flag_rilevante_iva              
	from 	  siac_t_bil_elem	d
		where 
			d.elem_id			= 	elenco_ueb.ueb_id
	loop
		begin
		for importi_ueb in
		-------------select 	 decode(sum (a.elem_det_importo),NULL,0,sum(a.elem_det_importo)) stanziamento_definitivo
        select coalesce (sum(a.elem_det_importo),0) stanziamento_definitivo
		from 		siac_t_bil_elem_det a, 
					siac_d_bil_elem_det_tipo b, 
            		siac_t_periodo c
		where 		a.elem_id 				= elenco_ueb.ueb_id
		and 		a.elem_det_tipo_id 		= b.elem_det_tipo_id
		-----and 		a.elem_det_flag 		='E'
		and 		b.elem_det_tipo_code 	in ('STA')
		and 		a.periodo_id 			= c.periodo_id
		and 		c.anno 					=  p_anno  --------anno_parametro 
		loop
          	raise notice '--------->>>>>>>>>>>>>>sta % ',tipoimporto;
                	stanziamento_definitivo:=importi_ueb.stanziamento_definitivo;
  		end loop;
        exception
		when no_data_found THEN
			raise notice 'stanziamento definitivo non trovato' ;
            ------		return;
		when others  THEN
        	RTN_MESSAGGIO:='errore nella lettura stanziamento definitivo';
 			RAISE EXCEPTION '% Errore : %-%.',RTN_MESSAGGIO,SQLSTATE,substring(SQLERRM from 1 for 500);
    		return;
        end;
        begin
		for importi_ueb in
        select coalesce (sum(a.elem_det_importo),0) stanziamento_iniziale
		from 		siac_t_bil_elem_det a, 
					siac_d_bil_elem_det_tipo b, 
            		siac_t_periodo c
		where 		a.elem_id 				= elenco_ueb.ueb_id
		and 		a.elem_det_tipo_id 		= b.elem_det_tipo_id
		-----and 		a.elem_det_flag 		='E'
		and 		b.elem_det_tipo_code 	in ('STI')
		and 		a.periodo_id 			= c.periodo_id
		and 		c.anno 					=  p_anno  --------anno_parametro 
		loop
                stanziamento_iniziale:=importi_ueb.stanziamento_iniziale;
    	end loop;
        exception
		when no_data_found THEN
			raise notice 'stanziamento iniziale non trovato' ;
            ------		return;
		when others  THEN
            RTN_MESSAGGIO:='errore nella lettura stanziamento iniziale';
 			RAISE EXCEPTION '% Errore : %-%.',RTN_MESSAGGIO,SQLSTATE,substring(SQLERRM from 1 for 500);
    		return;
        end;
        begin
		for importi_ueb in
        select coalesce (sum(a.elem_det_importo),0) variazioni_provvisorie
		from 	siac_t_bil_elem_det_var a,
				siac_r_variazione_stato b,
    			siac_d_variazione_stato c,
    			siac_d_variazione_tipo d,
    			siac_t_variazione e,
    			siac_t_bil_elem f
		where f.elem_id = elenco_ueb.ueb_id
		and	a.elem_id = f.elem_id
		and	a.variazione_stato_id = b.variazione_stato_id
		and b.variazione_stato_tipo_id = c.variazione_stato_tipo_id
		and c.variazione_stato_tipo_code not in ('A','D')
		and b.variazione_id = e.variazione_id
		and e.variazione_tipo_id =d.variazione_tipo_id
        -- 15/06/2016: cambiati i tipi di variazione. 
		--and d.variazione_tipo_code in ('ST','VA')
        and d.variazione_tipo_code in ('ST','VA','VR','PF','AS')
		loop
                variazioni_provvisorie:=importi_ueb.variazioni_provvisorie;
    	end loop;
        exception
        when no_data_found THEN
			raise notice 'variazioni provvisorie non trovato' ;
            ------		return;
		when others  THEN
        	RTN_MESSAGGIO:='errore nella lettura variazioni provvisorie';
 			RAISE EXCEPTION '% Errore : %-%.',RTN_MESSAGGIO,SQLSTATE,substring(SQLERRM from 1 for 500);
    		return;
        end;
	raise notice 'Fine classificatori';
	coel:= classificatori_ueb.coel;
	settore:=classificatori_ueb.settore;
	tipo_finanziamento:=classificatori_ueb.tipo_finanziamento;
	titolo:=classificatori_ueb.titolo;
    descrizione_titolo:=classificatori_ueb.descrizione_titolo;
    tipologia:=classificatori_ueb.tipologia;
    descrizione_tipologia:=classificatori_ueb.descrizione_tipologia;
    categoria:=classificatori_ueb.categoria;
    descrizione_categoria:=classificatori_ueb.descrizione_categoria;
    flag_rilevante_iva:=classificatori_ueb.flag_rilevante_iva;
	return next;
	end loop;
    exception
	when no_data_found THEN
			raise notice 'classificatore  non trovato' ;
	when others  THEN
            RTN_MESSAGGIO:='errore nella ricerca dei classificatori';
 			RAISE EXCEPTION '% Errore : %-%.',RTN_MESSAGGIO,SQLSTATE,substring(SQLERRM from 1 for 500);
    	    return;
	end;
raise notice 'fine OK';
end loop;  
exception
when no_data_found THEN
	raise notice 'UEB non trovata';
	return;
when others  THEN
	RTN_MESSAGGIO:='errore nella lettura della UEB';
 	RAISE EXCEPTION '% Errore : %-%.',RTN_MESSAGGIO,SQLSTATE,substring(SQLERRM from 1 for 500);
    return;
return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100 ROWS 1000;