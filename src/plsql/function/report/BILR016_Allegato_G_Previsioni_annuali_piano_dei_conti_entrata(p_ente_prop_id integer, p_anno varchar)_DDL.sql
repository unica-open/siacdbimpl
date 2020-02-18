/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac."BILR016_Allegato_G_Previsioni_annuali_piano_dei_conti_entrata" (
  p_ente_prop_id integer,
  p_anno varchar
)
RETURNS TABLE (
  pdc_codice varchar,
  pdc_tipo_classificatore varchar,
  pdc_descrizione varchar,
  pdc_livello varchar,
  pdc_id_elemento varchar,
  pdc_id_elemento_padre varchar,
  stanziamento numeric,
  stanziamento_cassa numeric,
  totale_stanziamento numeric,
  totale_cassa numeric
) AS
$body$
DECLARE
PianoContiImportiRec record;

annoCapImp varchar;
tipoStanziamento varchar;
tipoCassa varchar;
elemTipoCode varchar;
stanziato_tot_L4 numeric;
stanziato_tot_L3 numeric;
stanziato_tot_L2 numeric;
stanziato_tot_L1 numeric;
cassa_tot_l4 numeric;
cassa_tot_l3 numeric;
cassa_tot_l2 numeric;
cassa_tot_l1 numeric;

DEF_NULL	constant varchar:=''; 
RTN_MESSAGGIO varchar(1000):=DEF_NULL;
user_table	varchar;

BEGIN

annoCapImp:= p_anno; 
---------------------------------------raise notice '%', annoCapImp;
tipoStanziamento='STA';  	-- competenza
tipoCassa='SCA';  			-- competenza cassa
elemTipoCode='CAP-EP';

pdc_codice='';
pdc_tipo_classificatore='';
pdc_descrizione='';
pdc_livello='';
pdc_id_elemento='';
pdc_id_elemento_padre='';
stanziamento=0;
stanziamento_cassa=0;
totale_stanziamento=0;
totale_cassa=0;
stanziato_tot_L4 =0;
stanziato_tot_L3 =0;
stanziato_tot_L2 =0;
stanziato_tot_L1 =0;
cassa_tot_l4 =0;
cassa_tot_l3 =0;
cassa_tot_l2 =0;
cassa_tot_l1 =0;
  
select fnc_siac_random_user()
into	user_table; 


insert into siac_rep_pdc_entrate
select 	classif_classif_fam_tree_id,
    	classif_fam_tree_id,
    	classif_code,
    	classif_desc,
    	classif_tipo_desc,
    	classif_id,
    	classif_id_padre,
    	ente_proprietario_id,
    	ordine,
    	level,
		user_table 
from	(SELECT tb.classif_classif_fam_tree_id, tb.classif_fam_tree_id, t1.classif_code,
    t1.classif_desc, ti1.classif_tipo_desc, tb.classif_id, tb.classif_id_padre,
    tb.ente_proprietario_id, tb.ordine, tb.level, tb.validita_inizio,
    tb.validita_fine
FROM ( WITH RECURSIVE rqname(classif_classif_fam_tree_id, classif_fam_tree_id,
    classif_id, classif_id_padre, ente_proprietario_id, ordine, livello, validita_inizio, validita_fine, level, arrhierarchy) AS (
    SELECT rt1.classif_classif_fam_tree_id,
                            rt1.classif_fam_tree_id, rt1.classif_id,
                            rt1.classif_id_padre, rt1.ente_proprietario_id,
                            rt1.ordine, rt1.livello, tt1.validita_inizio,
                            tt1.validita_fine, 1,
                            ARRAY[COALESCE(rt1.classif_id, 0)] AS "array"
    FROM siac_r_class_fam_tree rt1,
                            siac_t_class_fam_tree tt1, siac_d_class_fam cf
    WHERE cf.classif_fam_id = tt1.classif_fam_id AND tt1.classif_fam_tree_id =
        rt1.classif_fam_tree_id AND rt1.classif_id_padre IS NULL AND cf.classif_fam_desc::text = 'Piano dei Conti'::text AND tt1.ente_proprietario_id = rt1.ente_proprietario_id
    UNION ALL
    SELECT tn.classif_classif_fam_tree_id,
                            tn.classif_fam_tree_id, tn.classif_id,
                            tn.classif_id_padre, tn.ente_proprietario_id,
                            tn.ordine, tn.livello, tn.validita_inizio,
                            tn.validita_fine, tp.level + 1,
                            tp.arrhierarchy || tn.classif_id
    FROM rqname tp, siac_r_class_fam_tree tn
    WHERE tp.classif_id = tn.classif_id_padre AND tn.ente_proprietario_id =
        tp.ente_proprietario_id
    )
    SELECT rqname.classif_classif_fam_tree_id, rqname.classif_fam_tree_id,
            rqname.classif_id, rqname.classif_id_padre,
            rqname.ente_proprietario_id, rqname.ordine, rqname.livello,
            rqname.validita_inizio, rqname.validita_fine, rqname.level
    FROM rqname
    ORDER BY rqname.arrhierarchy
    ) tb, siac_t_class t1,
    siac_d_class_tipo ti1
WHERE t1.classif_id = tb.classif_id AND ti1.classif_tipo_id =
    t1.classif_tipo_id AND t1.ente_proprietario_id = tb.ente_proprietario_id AND ti1.ente_proprietario_id = t1.ente_proprietario_id) v
---------siac_v_bko_pdc_anni v 
where 	v.ente_proprietario_id =p_ente_prop_id 
		and substr(v.classif_code,1,1)='E'
        and
        to_timestamp('01/01/'||p_anno,'dd/mm/yyyy')
		between v.validita_inizio and
		COALESCE(v.validita_fine, to_timestamp('31/12/'||p_anno,'dd/mm/yyyy'))
order by classif_code	desc;


insert into siac_rep_cap_ep_imp
select 		capitolo_importi.elem_id,
			capitolo_imp_periodo.anno 				BIL_ELE_IMP_ANNO,
           	capitolo_imp_tipo.elem_det_tipo_code 	TIPO_IMP,
            capitolo_importi.ente_proprietario_id,
            user_table utente,
            sum(capitolo_importi.elem_det_importo)     
from 		siac_t_bil_elem_det capitolo_importi,
         	siac_d_bil_elem_det_tipo capitolo_imp_tipo,
         	siac_t_periodo capitolo_imp_periodo,
            siac_t_bil_elem capitolo,
            siac_d_bil_elem_tipo tipo_elemento,
            siac_t_bil bilancio,
	 		siac_t_periodo anno_eserc, 
			siac_d_bil_elem_stato stato_capitolo, 
            siac_r_bil_elem_stato r_capitolo_stato,
			siac_d_bil_elem_categoria cat_del_capitolo, 
           	siac_r_bil_elem_categoria r_cat_capitolo
    where 	capitolo_importi.ente_proprietario_id = p_ente_prop_id  
    	/*and	capitolo_importi.ente_proprietario_id =capitolo_imp_tipo.ente_proprietario_id
        and	capitolo_importi.ente_proprietario_id =capitolo_imp_periodo.ente_proprietario_id
   		and capitolo_importi.ente_proprietario_id=capitolo_imp_tipo.ente_proprietario_id	
        and capitolo_importi.ente_proprietario_id=capitolo.ente_proprietario_id
        and	capitolo_importi.ente_proprietario_id=bilancio.ente_proprietario_id
        and	capitolo_importi.ente_proprietario_id=anno_eserc.ente_proprietario_id
        and	capitolo_importi.ente_proprietario_id=stato_capitolo.ente_proprietario_id
        and	capitolo_importi.ente_proprietario_id=r_capitolo_stato.ente_proprietario_id
        and	capitolo_importi.ente_proprietario_id=cat_del_capitolo.ente_proprietario_id
        and	capitolo_importi.ente_proprietario_id=r_cat_capitolo.ente_proprietario_id*/
        and	anno_eserc.anno						= p_anno 												
    	and	bilancio.periodo_id					=anno_eserc.periodo_id 								
        and	capitolo.bil_id						=bilancio.bil_id 			 
        and	capitolo.elem_id					=capitolo_importi.elem_id 
        and	capitolo.elem_tipo_id				=tipo_elemento.elem_tipo_id 						
        and	tipo_elemento.elem_tipo_code	 	= elemTipoCode
        and	capitolo_importi.elem_det_tipo_id	=capitolo_imp_tipo.elem_det_tipo_id 		
        and	capitolo_imp_periodo.periodo_id		=capitolo_importi.periodo_id 			  
        and	capitolo_imp_periodo.anno in (annoCapImp)
        and	capitolo.elem_id					=	r_capitolo_stato.elem_id
		and	r_capitolo_stato.elem_stato_id		=	stato_capitolo.elem_stato_id
		and	stato_capitolo.elem_stato_code		=	'VA'
		and	capitolo.elem_id					=	r_cat_capitolo.elem_id
		and	r_cat_capitolo.elem_cat_id			=	cat_del_capitolo.elem_cat_id
		and	cat_del_capitolo.elem_cat_code		=	'STD' 
        and capitolo_importi.data_cancellazione				is null
        AND capitolo_imp_tipo.data_cancellazione				is null
        and capitolo_imp_periodo.data_cancellazione			is null
        AND capitolo.data_cancellazione						is null
        and tipo_elemento.data_cancellazione					is null
        and bilancio.data_cancellazione						is null
	 	and anno_eserc.data_cancellazione						is null 
		and stato_capitolo.data_cancellazione					is null 
        and r_capitolo_stato.data_cancellazione				is null
		and cat_del_capitolo.data_cancellazione				is null 
        and r_cat_capitolo.data_cancellazione					is null
      	/*and	now() between capitolo_importi.validita_inizio and coalesce (capitolo_importi.validita_fine, now())
        and	now() between capitolo_imp_periodo.validita_inizio and coalesce (capitolo_imp_periodo.validita_fine, now())
        and	now() between capitolo.validita_inizio and coalesce (capitolo.validita_fine, now())
        and	now() between capitolo_imp_tipo.validita_inizio and coalesce (capitolo_imp_tipo.validita_fine, now())  
    	and	now() between tipo_elemento.validita_inizio and coalesce (tipo_elemento.validita_fine, now())
        and	now() between bilancio.validita_inizio and coalesce (bilancio.validita_fine, now())
        and	now() between anno_eserc.validita_inizio and coalesce (anno_eserc.validita_fine, now())
        and	now() between stato_capitolo.validita_inizio and coalesce (stato_capitolo.validita_fine, now())
        and	now() between r_capitolo_stato.validita_inizio and coalesce (r_capitolo_stato.validita_fine, now())
        and	now() between cat_del_capitolo.validita_inizio and coalesce (cat_del_capitolo.validita_fine, now())
        and	now() between r_cat_capitolo.validita_inizio and coalesce (r_cat_capitolo.validita_fine, now())*/
    group by   capitolo_importi.elem_id,capitolo_imp_tipo.elem_det_tipo_code,capitolo_imp_periodo.anno,capitolo_importi.ente_proprietario_id, utente
    order by   capitolo_imp_tipo.elem_det_tipo_code, capitolo_imp_periodo.anno;



insert into siac_rep_cap_ep_imp_riga
select  tb1.elem_id, 
  		coalesce (tb1.importo,0)   as 		stanziamento,
        0,
        0,
        0,
        0,
        coalesce (tb2.importo,0)   as 		stanziamento_cassa,
        tb1.ente_proprietario,
        user_table utente
from   
	siac_rep_cap_ep_imp tb1, siac_rep_cap_ep_imp tb2
	where			tb1.elem_id	=	tb2.elem_id								
    				and	
        			tb1.periodo_anno = annoCapImp		AND	tb1.tipo_imp =	tipoStanziamento	
                    AND
        			tb2.periodo_anno = tb1.periodo_anno	AND	tb2.tipo_imp = 	tipoCassa
                    and tb1.utente 	= 	tb2.utente	
        			and	tb2.utente	=	user_table;	
        

for PianoContiImportiRec in
select 	tb1.classif_code										pdc_codice,
		tb1.classif_tipo_desc									pdc_tipo_classificatore,
        tb1.classif_desc										pdc_descrizione,
        tb1.livello												pdc_livello,		
        tb1.classif_id											pdc_id_elemento,
        tb1.classif_id_padre									pdc_id_elemento_padre,
        COALESCE(sum (tb3.stanziamento_prev_anno),0)			stanziamento,
        COALESCE(sum(tb3.stanziamento_prev_cassa_anno),0)		stanziamento_cassa					
	from siac_rep_pdc_entrate	tb1
    	left join	 siac_r_bil_elem_class	tb2
        on	(tb1.classif_id	=	tb2.classif_id
        	and	tb1.ente_proprietario_id	=	p_ente_prop_id
        	------and	tb1.ente_proprietario_id	=	tb2.ente_proprietario_id
            and	tb2.validita_fine	is NULL)
    	LEFT join 	siac_rep_cap_ep_imp_riga	tb3
        on	(tb2.elem_id	=	tb3.elem_id
        	-------and	tb2.ente_proprietario_id	=	tb3.ente_proprietario_id
            and	tb2.validita_fine	is NULL)
     where tb1.utente = user_table   
    group by	1,2,3,4,5,6	 
        order by pdc_codice	desc

loop

pdc_codice := PianoContiImportiRec.pdc_codice;
pdc_tipo_classificatore := PianoContiImportiRec.pdc_tipo_classificatore;
pdc_descrizione := PianoContiImportiRec.pdc_descrizione;
pdc_livello := PianoContiImportiRec.pdc_livello;
pdc_id_elemento := PianoContiImportiRec.pdc_id_elemento;
pdc_id_elemento_padre := PianoContiImportiRec.pdc_id_elemento_padre;
stanziamento:= PianoContiImportiRec.stanziamento;
stanziamento_cassa:= PianoContiImportiRec.stanziamento_cassa;

if PianoContiImportiRec.pdc_livello = '5' then
	stanziato_tot_L4 = stanziato_tot_L4 + stanziamento;
    totale_stanziamento = stanziamento;
    cassa_tot_L4 = cassa_tot_L4 + stanziamento_cassa;
    totale_cassa = stanziamento_cassa;
end if;

if PianoContiImportiRec.pdc_livello = '4' then
	stanziato_tot_L4 = stanziato_tot_L4 + stanziamento;
    totale_stanziamento = stanziato_tot_L4;
    stanziato_tot_L3 = stanziato_tot_L3 + stanziato_tot_L4;
    stanziato_tot_L4 = 0;
    cassa_tot_L4 = cassa_tot_L4 + stanziamento_cassa;
    totale_cassa = cassa_tot_L4;
    cassa_tot_L3 = cassa_tot_L3 + cassa_tot_L4;
    cassa_tot_L4 = 0;
end if;

if PianoContiImportiRec.pdc_livello = '3' then
	stanziato_tot_L3 = stanziato_tot_L3 + stanziamento;
    totale_stanziamento = stanziato_tot_L3;
    stanziato_tot_L2 = stanziato_tot_L2 + stanziato_tot_L3;
    stanziato_tot_L3 = 0;
	cassa_tot_L3 = cassa_tot_L3 + stanziamento_cassa;
    totale_cassa = cassa_tot_L3;
    cassa_tot_L2 = cassa_tot_L2 + cassa_tot_L3;
    cassa_tot_L3 = 0;
end if;

if PianoContiImportiRec.pdc_livello = '2' then
	stanziato_tot_L2 = stanziato_tot_L2 + stanziamento;
    totale_stanziamento = stanziato_tot_L2;
    stanziato_tot_L1 = stanziato_tot_L1 + stanziato_tot_L2;
    stanziato_tot_L2 = 0;
    cassa_tot_L2 = cassa_tot_L2 + stanziamento_cassa;
    totale_cassa = cassa_tot_L2;
    cassa_tot_L1 = cassa_tot_L1 + cassa_tot_L2;
    cassa_tot_L2 = 0;
end if;

if PianoContiImportiRec.pdc_livello = '1' then
	stanziato_tot_L1 = stanziato_tot_L1 + stanziamento;
    totale_stanziamento = stanziato_tot_L1;
    stanziato_tot_L1 = 0;
    cassa_tot_L1 = cassa_tot_L1 + stanziamento_cassa;
    totale_cassa = cassa_tot_L1;
    cassa_tot_L1 = 0;
end if;

stanziamento=0;
stanziamento_cassa=0;

return next;
pdc_codice='';
pdc_tipo_classificatore='';
pdc_descrizione='';
pdc_livello='';
pdc_id_elemento='';
pdc_id_elemento_padre='';
stanziamento=0;
stanziamento_cassa=0;

end loop;

delete from siac_rep_pdc_entrate where utente=user_table;

delete from siac_rep_cap_ep_imp where utente=user_table;

delete from siac_rep_cap_ep_imp_riga where utente=user_table;


raise notice 'fine OK';
exception
	when no_data_found THEN
		raise notice 'errore lettura ---' ;
		return;
	when others  THEN
        RTN_MESSAGGIO:='capitolo altro errore';
 		RAISE EXCEPTION '% Errore : %-%.',RTN_MESSAGGIO,SQLSTATE,substring(SQLERRM from 1 for 500);
        return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100 ROWS 1000;