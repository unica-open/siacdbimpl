/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac."BILR145_Stampa_giorn_reversali_incasso_emesse" (
  p_ente_prop_id integer,
  p_anno varchar,
  p_num_revers_da integer,
  p_num_revers_a integer,
  p_data_revers_da date,
  p_data_revers_a date,
  p_numero_distinta varchar,
  p_stato_mandato varchar
)
RETURNS TABLE (
  nome_ente varchar,
  partita_iva_ente varchar,
  anno_ese_finanz integer,
  anno_capitolo integer,
  cod_capitolo varchar,
  cod_articolo varchar,
  cod_gestione varchar,
  num_accertamento varchar,
  num_subimpegno varchar,
  importo_lordo_reversale numeric,
  numero_reversale integer,
  data_reversale date,
  importo_stanz_cassa numeric,
  importo_tot_reversali_emessi numeric,
  importo_tot_reversali_dopo_emiss numeric,
  importo_dispon numeric,
  nome_tesoriere varchar,
  desc_causale varchar,
  num_fattura varchar,
  anno_fattura integer,
  importo_fattura numeric,
  versante_cod_fiscale varchar,
  versante_partita_iva varchar,
  versante_nome varchar,
  versante_indirizzo varchar,
  versante_cap varchar,
  versante_localita varchar,
  versante_provincia varchar,
  importo_netto numeric,
  resp_sett_amm varchar,
  tit_tipo_categ varchar,
  transaz_elementare varchar,
  resp_amm varchar,
  anno_primo_accertamento varchar,
  display_error varchar,
  cod_stato_reversale varchar
) AS
$body$
DECLARE
elencoReversali record;
elencoAccertamenti record;
elencoOneri record;
elencoClass record;

DEF_NULL	constant varchar:=''; 
RTN_MESSAGGIO varchar(1000):=DEF_NULL;
appStr VARCHAR;
posizione integer;
numAccertApp VARCHAR;
numSubAccertApp VARCHAR;
numAccert VARCHAR;
annoAccertamento VARCHAR;
importo_ritenuta NUMERIC;
importo_imposta NUMERIC;
anno_eser_int INTEGER;
contaRecord INTEGER;
v_fam_titolotipologiacategoria varchar:='00003';
user_table VARCHAR;
cod_cofog VARCHAR;
cod_trans_europea VARCHAR;
cod_v_livello VARCHAR;
cod_trans_elem VARCHAR;
ricorrente_entrata VARCHAR;
perimetro_sanit_entrata VARCHAR;
cod_siope VARCHAR;
sqlQuery varchar;

BEGIN

nome_ente='';
partita_iva_ente='';
anno_ese_finanz=0;
anno_capitolo=0;
cod_capitolo='';
cod_articolo='';
cod_gestione='';
num_accertamento='';
importo_lordo_reversale=0;
numero_reversale=0;
data_reversale=NULL;
importo_stanz_cassa=0;
importo_tot_reversali_emessi=0;
importo_tot_reversali_dopo_emiss=0;
importo_dispon=0;
nome_tesoriere='';
desc_causale='';
num_fattura='';
anno_fattura=0;
importo_fattura=0;
versante_cod_fiscale='';
versante_partita_iva='';
versante_nome='';
versante_indirizzo='';
versante_cap='';
versante_localita='';
versante_provincia='';
importo_netto=0;
resp_sett_amm='';
transaz_elementare='';
importo_ritenuta=0;
importo_imposta=0;
resp_amm='';
tit_tipo_categ='';
anno_primo_accertamento='';
cod_stato_reversale='';

anno_eser_int=p_anno ::INTEGER;

display_error='';
if p_num_revers_da IS NULL AND p_num_revers_a IS NULL AND p_data_revers_da IS NULL AND
	p_data_revers_a IS NULL AND
    (p_numero_distinta IS NULL OR p_numero_distinta = '') THEN
	display_error='OCCORRE SPECIFICARE ALMENO UNO TRA I PARAMETRI "NUMERO REVERSALE DA/A", "DATA REVERSALE DA/A e "NUMERO DISTINTA".';
    return next;
    return;
end if;

select fnc_siac_random_user()
into	user_table;

RTN_MESSAGGIO:='Estrazione dei dati delle reversali ''.';
raise notice 'ora: % ',clock_timestamp()::varchar;
/*
with titent as 
(select 
e.classif_tipo_desc titent_tipo_desc,
a.classif_id titent_id,
a.classif_code titent_code,
a.classif_desc titent_desc,
a.validita_inizio titent_validita_inizio,
a.validita_fine titent_validita_fine,
a.ente_proprietario_id
from siac_t_class a, siac_r_class_fam_tree b, siac_t_class_fam_tree c, siac_d_class_fam d,siac_d_class_tipo e
where 
a.ente_proprietario_id=p_ente_prop_id
and a.classif_id=b.classif_id
and b.classif_fam_tree_id=c.classif_fam_tree_id
and c.classif_fam_id=d.classif_fam_id
and d.classif_fam_code = v_fam_titolotipologiacategoria--'00003'
and to_timestamp('31/12/'||p_anno,'dd/mm/yyyy') between b.validita_inizio and COALESCE(b.validita_fine,to_timestamp('31/12/'||p_anno,'dd/mm/yyyy'))
and b.classif_id_padre is null
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
and d.data_cancellazione is null
and e.classif_tipo_id=a.classif_tipo_id
),
tipologia as
(
select 
e.classif_tipo_desc tipologia_tipo_desc,
b.classif_id_padre titent_id,
a.classif_id tipologia_id,
a.classif_code tipologia_code,
a.classif_desc tipologia_desc,
a.validita_inizio tipologia_validita_inizio,
a.validita_fine tipologia_validita_fine,
a.ente_proprietario_id
from siac_t_class a, siac_r_class_fam_tree b, siac_t_class_fam_tree c, siac_d_class_fam d,siac_d_class_tipo e
where 
a.ente_proprietario_id=p_ente_prop_id
and a.classif_id=b.classif_id
and b.classif_fam_tree_id=c.classif_fam_tree_id
and c.classif_fam_id=d.classif_fam_id
and d.classif_fam_code = v_fam_titolotipologiacategoria--'00003'
and to_timestamp('31/12/'||p_anno,'dd/mm/yyyy') 
between b.validita_inizio and COALESCE(b.validita_fine,to_timestamp('31/12/'||p_anno,'dd/mm/yyyy'))
and b.classif_id_padre is not null
and b.livello=2
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
and d.data_cancellazione is null
and e.classif_tipo_id=a.classif_tipo_id
),
categoria as (
select 
e.classif_tipo_desc categoria_tipo_desc,
b.classif_id_padre tipologia_id,
a.classif_id categoria_id,
a.classif_code categoria_code,
a.classif_desc categoria_desc,
a.validita_inizio categoria_validita_inizio,
a.validita_fine categoria_validita_fine,
a.ente_proprietario_id
from siac_t_class a, siac_r_class_fam_tree b, siac_t_class_fam_tree c, siac_d_class_fam d,siac_d_class_tipo e
where 
a.ente_proprietario_id=p_ente_prop_id
and a.classif_id=b.classif_id
and b.classif_fam_tree_id=c.classif_fam_tree_id
and c.classif_fam_id=d.classif_fam_id
and d.classif_fam_code = v_fam_titolotipologiacategoria--'00003'
and to_timestamp('31/12/'||p_anno,'dd/mm/yyyy') 
between b.validita_inizio and COALESCE(b.validita_fine,to_timestamp('31/12/'||p_anno,'dd/mm/yyyy'))
and b.classif_id_padre is not null
and b.livello=3
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
and d.data_cancellazione is null
and e.classif_tipo_id=a.classif_tipo_id
)
insert into  siac_rep_tit_tip_cat_riga_anni
select 
titent.titent_tipo_desc,
titent.titent_id,
titent.titent_code,
titent.titent_desc,
titent.titent_validita_inizio,
titent.titent_validita_fine,
tipologia.tipologia_tipo_desc,
tipologia.tipologia_id,
tipologia.tipologia_code,
tipologia.tipologia_desc,
tipologia.tipologia_validita_inizio,
tipologia.tipologia_validita_fine,
categoria.categoria_tipo_desc,
categoria.categoria_id,
categoria.categoria_code,
categoria.categoria_desc,
categoria.categoria_validita_inizio,
categoria.categoria_validita_fine,
categoria.ente_proprietario_id,
user_table
 from titent,tipologia,categoria
where 
titent.titent_id=tipologia.titent_id
 and tipologia.tipologia_id=categoria.tipologia_id
 order by 
 titent.titent_code, tipologia.tipologia_code,categoria.categoria_code ;

insert into siac_rep_cap_eg
select cl.classif_id,
  anno_eserc.anno anno_bilancio,
  e.*, user_table utente
 from 	siac_r_bil_elem_class rc,
 		siac_t_bil_elem e,
        siac_d_class_tipo ct,
		siac_t_class cl,
        siac_t_bil bilancio,
        siac_t_periodo anno_eserc,
        siac_d_bil_elem_tipo tipo_elemento, 
		siac_d_bil_elem_stato stato_capitolo,
        siac_r_bil_elem_stato r_capitolo_stato,
		siac_d_bil_elem_categoria cat_del_capitolo,
        siac_r_bil_elem_categoria r_cat_capitolo
where ct.classif_tipo_code			=	'CATEGORIA'
and ct.classif_tipo_id				=	cl.classif_tipo_id
and cl.classif_id					=	rc.classif_id 
and e.ente_proprietario_id=p_ente_prop_id
and anno_eserc.anno					= 	p_anno
and bilancio.periodo_id				=	anno_eserc.periodo_id 
and e.bil_id						=	bilancio.bil_id 
and e.elem_tipo_id					=	tipo_elemento.elem_tipo_id 
and tipo_elemento.elem_tipo_code 	= 	'CAP-EG'
and e.elem_id						=	rc.elem_id 
and	e.elem_id						=	r_capitolo_stato.elem_id
and	r_capitolo_stato.elem_stato_id	=	stato_capitolo.elem_stato_id
and	stato_capitolo.elem_stato_code	=	'VA'
and	e.elem_id						=	r_cat_capitolo.elem_id
and	r_cat_capitolo.elem_cat_id		=	cat_del_capitolo.elem_cat_id
and	cat_del_capitolo.elem_cat_code	=	'STD'
and e.data_cancellazione 				is null
and	r_capitolo_stato.data_cancellazione	is null
and	r_cat_capitolo.data_cancellazione	is null
and	rc.data_cancellazione				is null
and	ct.data_cancellazione 				is null
and	cl.data_cancellazione 				is null
and	bilancio.data_cancellazione 		is null
and	anno_eserc.data_cancellazione 		is null
and	tipo_elemento.data_cancellazione	is null
and	stato_capitolo.data_cancellazione 	is null
and	cat_del_capitolo.data_cancellazione	is null
and	now() between rc.validita_inizio and coalesce (rc.validita_fine, now())
and	now() between e.validita_inizio and coalesce (e.validita_fine, now())
and	now() between bilancio.validita_inizio and coalesce (bilancio.validita_fine, now())
and	now() between anno_eserc.validita_inizio and coalesce (anno_eserc.validita_fine, now())
and	now() between ct.validita_inizio and coalesce (ct.validita_fine, now())
and	now() between cl.validita_inizio and coalesce (cl.validita_fine, now())
and	now() between tipo_elemento.validita_inizio and coalesce (tipo_elemento.validita_fine, now())
and	now() between stato_capitolo.validita_inizio and coalesce (stato_capitolo.validita_fine, now())
and	now() between r_capitolo_stato.validita_inizio and coalesce (r_capitolo_stato.validita_fine, now())
and	now() between cat_del_capitolo.validita_inizio and coalesce (cat_del_capitolo.validita_fine, now())
and	now() between r_cat_capitolo.validita_inizio and coalesce (r_cat_capitolo.validita_fine, now());
*/

sqlQuery='with ord as (
select upper(d_ord_stato.ord_stato_code) ord_stato_code, 
		d_ord_stato.ord_stato_desc,
        t_ordinativo.ord_anno, t_ordinativo.ord_numero,
        t_ordinativo.ente_proprietario_id , t_ordinativo_ts.ord_ts_id,
        t_ordinativo.ord_emissione_data, t_ordinativo.ord_id,
        COALESCE(t_ordinativo.ord_cast_emessi,0) ord_cast_emessi,
        COALESCE(t_ordinativo.ord_cast_cassa,0) ord_cast_cassa,
         -- se la reversale è annullata l''importo è 0
        case when d_ord_stato.ord_stato_code <>''A''
        	then COALESCE(t_ord_ts_det.ord_ts_det_importo,0) 
            else 0 end ord_ts_det_importo,
        t_ordinativo.ord_cast_competenza,
        t_ordinativo.ord_desc, t_periodo.anno anno_eser
FROM siac_d_ordinativo_tipo d_ordinativo_tipo,
	siac_t_ordinativo_ts t_ordinativo_ts,
    siac_t_ordinativo_ts_det t_ord_ts_det,
    siac_d_ordinativo_ts_det_tipo d_ord_ts_det_tipo,
    siac_r_ordinativo_stato r_ord_stato,
    siac_d_ordinativo_stato d_ord_stato,
    siac_t_bil t_bil,
    siac_t_periodo t_periodo,
	siac_t_ordinativo t_ordinativo	               	
      LEFT JOIN siac_d_distinta d_distinta
              ON (d_distinta.dist_id=t_ordinativo.dist_id
                  AND d_distinta.data_cancellazione IS NULL) 
WHERE r_ord_stato.ord_id=t_ordinativo.ord_id
	AND d_ord_stato.ord_stato_id=r_ord_stato.ord_stato_id
    AND t_ordinativo_ts.ord_id=t_ordinativo.ord_id
    AND d_ordinativo_tipo.ord_tipo_id=t_ordinativo.ord_tipo_id 
    AND t_ord_ts_det.ord_ts_id=t_ordinativo_ts.ord_ts_id   
    AND d_ord_ts_det_tipo.ord_ts_det_tipo_id= t_ord_ts_det.ord_ts_det_tipo_id
    AND t_bil.bil_id=t_ordinativo.bil_id
	AND t_periodo.periodo_id= t_bil.periodo_id   
    AND d_ordinativo_tipo.ord_tipo_code=''I'' /* INCASSO */ 
    AND d_ord_ts_det_tipo.ord_ts_det_tipo_code =''A'' -- Importo Attuale
    AND t_ordinativo.ente_proprietario_id='||p_ente_prop_id;
  sqlQuery=sqlQuery|| ' AND t_ordinativo.ord_anno='||anno_eser_int;
      sqlQuery=sqlQuery|| ' and t_periodo.anno='''||p_anno||'''';
      if p_num_revers_da IS NOT NULL AND p_num_revers_a IS NOT NULL then
          sqlQuery=sqlQuery|| ' and t_ordinativo.ord_numero between '||p_num_revers_da;
          sqlQuery=sqlQuery|| ' and ' ||p_num_revers_a;   
      elsif p_num_revers_da IS NOT NULL AND p_num_revers_a IS  NULL then
          sqlQuery=sqlQuery|| ' and t_ordinativo.ord_numero = '||p_num_revers_da;
      elsif p_num_revers_da IS  NULL AND p_num_revers_a IS NOT NULL then
          sqlQuery=sqlQuery|| ' and t_ordinativo.ord_numero = '||p_num_revers_a;
      end if;  
      
      if p_data_revers_da IS NOT NULL AND p_data_revers_a IS NOT NULL then
          sqlQuery=sqlQuery || ' and to_timestamp(to_char(t_ordinativo.ord_emissione_data,''yyyy-mm-dd''),''yyyy-mm-dd'') between to_timestamp('''|| p_data_revers_da||'''::varchar,''yyyy-mm-dd'')' || ' and to_timestamp(''' ||p_data_revers_a||'''::varchar,''yyyy-mm-dd'')';    	
      elsif  p_data_revers_da IS NOT NULL AND p_data_revers_a IS NULL then
          sqlQuery=sqlQuery || ' and to_timestamp(to_char(t_ordinativo.ord_emissione_data,''yyyy-mm-dd''),''yyyy-mm-dd'') = to_timestamp('''|| p_data_revers_da||'''::varchar,''yyyy-mm-dd'')';    
      elsif  p_data_revers_da IS  NULL AND p_data_revers_a IS NOT NULL then
          sqlQuery=sqlQuery || ' and to_timestamp(to_char(t_ordinativo.ord_emissione_data,''yyyy-mm-dd''),''yyyy-mm-dd'') = to_timestamp('''|| p_data_revers_a||'''::varchar,''yyyy-mm-dd'')';    	        	
      end if;
      
      if p_numero_distinta IS NOT NULL AND  p_numero_distinta <>'' then 
          sqlQuery=sqlQuery|| ' and d_distinta.dist_code='''||p_numero_distinta||'''';
      end if;
      if p_stato_mandato <> 'TT' then
          sqlQuery=sqlQuery|| ' and d_ord_stato.ord_stato_code='''||p_stato_mandato||'''';
      end if;
        
    
    sqlQuery=sqlQuery|| ' AND d_ord_stato.data_cancellazione IS NULL
	AND r_ord_stato.data_cancellazione IS NULL
    AND r_ord_stato.validita_fine IS NULL
    AND t_ordinativo_ts.data_cancellazione IS NULL
    AND t_ordinativo.data_cancellazione IS NULL
    AND d_ordinativo_tipo.data_cancellazione IS NULL
    AND t_ord_ts_det.data_cancellazione IS NULL
    AND d_ord_ts_det_tipo.data_cancellazione IS NULL
    AND t_periodo.data_cancellazione IS NULL
    AND t_bil.data_cancellazione IS NULL 
    ),
strut_bil as (
  select *  
      from fnc_bilr_struttura_cap_bilancio_entrate ('||p_ente_prop_id||',
      		'''||p_anno||''','''||user_table||''')  ) ,    
ele_cap as (
select cl.classif_id,
  anno_eserc.anno anno_bilancio,
  e.*
 from 	siac_r_bil_elem_class rc,
 		siac_t_bil_elem e,
        siac_d_class_tipo ct,
		siac_t_class cl,
        siac_t_bil bilancio,
        siac_t_periodo anno_eserc,
        siac_d_bil_elem_tipo tipo_elemento, 
		siac_d_bil_elem_stato stato_capitolo,
        siac_r_bil_elem_stato r_capitolo_stato,
		siac_d_bil_elem_categoria cat_del_capitolo,
        siac_r_bil_elem_categoria r_cat_capitolo
where ct.classif_tipo_code			=	''CATEGORIA''
and ct.classif_tipo_id				=	cl.classif_tipo_id
and cl.classif_id					=	rc.classif_id 
and e.ente_proprietario_id			=   '||p_ente_prop_id||'
and anno_eserc.anno					= 	'''||p_anno||'''
and bilancio.periodo_id				=	anno_eserc.periodo_id 
and e.bil_id						=	bilancio.bil_id 
and e.elem_tipo_id					=	tipo_elemento.elem_tipo_id 
and tipo_elemento.elem_tipo_code 	= 	''CAP-EG''
and e.elem_id						=	rc.elem_id 
and	e.elem_id						=	r_capitolo_stato.elem_id
and	r_capitolo_stato.elem_stato_id	=	stato_capitolo.elem_stato_id
and	stato_capitolo.elem_stato_code	=	''VA''
and	e.elem_id						=	r_cat_capitolo.elem_id
and	r_cat_capitolo.elem_cat_id		=	cat_del_capitolo.elem_cat_id
and	cat_del_capitolo.elem_cat_code	=	''STD''
and e.data_cancellazione 				is null
and	r_capitolo_stato.data_cancellazione	is null
and	r_cat_capitolo.data_cancellazione	is null
and	rc.data_cancellazione				is null
and	ct.data_cancellazione 				is null
and	cl.data_cancellazione 				is null
and	bilancio.data_cancellazione 		is null
and	anno_eserc.data_cancellazione 		is null
and	tipo_elemento.data_cancellazione	is null
and	stato_capitolo.data_cancellazione 	is null
and	cat_del_capitolo.data_cancellazione	is null
and	now() between rc.validita_inizio and coalesce (rc.validita_fine, now())
and	now() between e.validita_inizio and coalesce (e.validita_fine, now())
and	now() between bilancio.validita_inizio and coalesce (bilancio.validita_fine, now())
and	now() between anno_eserc.validita_inizio and coalesce (anno_eserc.validita_fine, now())
and	now() between ct.validita_inizio and coalesce (ct.validita_fine, now())
and	now() between cl.validita_inizio and coalesce (cl.validita_fine, now())
and	now() between tipo_elemento.validita_inizio and coalesce (tipo_elemento.validita_fine, now())
and	now() between stato_capitolo.validita_inizio and coalesce (stato_capitolo.validita_fine, now())
and	now() between r_capitolo_stato.validita_inizio and coalesce (r_capitolo_stato.validita_fine, now())
and	now() between cat_del_capitolo.validita_inizio and coalesce (cat_del_capitolo.validita_fine, now())
and	now() between r_cat_capitolo.validita_inizio and coalesce (r_cat_capitolo.validita_fine, now())
),
cap as (
	select r_ordinativo_bil_elem.ord_id,
 		strutt_capitoli.categoria_code, strutt_capitoli.tipologia_code,
        strutt_capitoli.titolo_code,
        t_bil_elem.elem_code,t_bil_elem.elem_code2,
        t_bil_elem.elem_id
	from siac_r_ordinativo_bil_elem r_ordinativo_bil_elem,
        siac_t_bil_elem t_bil_elem  
        left join ele_cap rep_cap_eg
          ON (rep_cap_eg.elem_id=t_bil_elem.elem_id)
        LEFT JOIN strut_bil   strutt_capitoli 
 				ON (strutt_capitoli.categoria_id = rep_cap_eg.classif_id    
           			and strutt_capitoli.ente_proprietario_id='||p_ente_prop_id||'
					and	strutt_capitoli.ente_proprietario_id=rep_cap_eg.ente_proprietario_id)                           
    where r_ordinativo_bil_elem.elem_id=t_bil_elem.elem_id 
    	and r_ordinativo_bil_elem.ente_proprietario_id ='||p_ente_prop_id; 
        sqlQuery=sqlQuery|| ' and r_ordinativo_bil_elem.data_cancellazione IS NULL
        and t_bil_elem.data_cancellazione IS NULL) ,
ente as (
	select  COALESCE(OL.ente_oil_resp_ord,'''') ente_oil_resp_ord, 
        COALESCE(OL.ente_oil_tes_desc,'''') ente_oil_tes_desc, 
        COALESCE(OL.ente_oil_resp_amm,'''') ente_oil_resp_amm,  
        ep.ente_denominazione, ep.codice_fiscale cod_fisc_ente,
        ep.ente_proprietario_id
		from siac_t_ente_proprietario ep,
        		siac_t_ente_oil OL
    where  ep.ente_proprietario_id =OL.ente_proprietario_id
        and ep.ente_proprietario_id='||p_ente_prop_id;   
        sqlQuery=sqlQuery|| ' and ep.data_cancellazione IS NULL
        and ol.data_cancellazione IS NULL),
sogg as (
	select	r_ord_soggetto.ord_id,
    	COALESCE(t_soggetto.codice_fiscale,''9999999999999999'') codice_fiscale,
        COALESCE(t_soggetto.partita_iva,'''') partita_iva, 
        COALESCE(t_soggetto.soggetto_desc,'''') soggetto_desc,                 
        COALESCE(d_via_tipo.via_tipo_desc,'''') via_tipo_desc, 
        COALESCE(t_ind_soggetto.toponimo,'''') toponimo, 
        COALESCE(t_ind_soggetto.numero_civico,'''') numero_civico,
        	-- se indirizzo e cap sono vuoti, il cap diventa 00000
        case when trim(COALESCE(d_via_tipo.via_tipo_desc,'''')||
        		'' ''||COALESCE(t_ind_soggetto.toponimo,'''')||
    			'' ''||COALESCE(t_ind_soggetto.numero_civico,'''')) =''''
            THEN COALESCE(t_ind_soggetto.zip_code,''00000'')
            ELSE COALESCE(t_ind_soggetto.zip_code,'''') end zip_code,            
        --COALESCE(t_ind_soggetto.zip_code,'''') zip_code, 
        COALESCE(t_comune.comune_desc,'''') comune_desc, 
        COALESCE(t_provincia.sigla_automobilistica,'''') sigla_automobilistica,
        COALESCE (t_ind_soggetto.frazione,'''') frazione,
        t_ind_soggetto.soggetto_id,t_ind_soggetto.indirizzo_id
    from  siac_r_ordinativo_soggetto r_ord_soggetto,
          siac_t_soggetto t_soggetto
            LEFT JOIN siac_t_indirizzo_soggetto t_ind_soggetto
                ON (t_ind_soggetto.soggetto_id=t_soggetto.soggetto_id
                    AND t_ind_soggetto.principale=''S''
                    AND t_ind_soggetto.data_cancellazione IS NULL)
            LEFT JOIN siac_d_via_tipo d_via_tipo
                ON (d_via_tipo.via_tipo_id=t_ind_soggetto.via_tipo_id
                    AND d_via_tipo.data_cancellazione IS NULL)
            LEFT JOIN siac_t_comune t_comune
                ON (t_comune.comune_id=t_ind_soggetto.comune_id
                    AND t_comune.data_cancellazione IS NULL)
            LEFT JOIN siac_r_comune_provincia r_comune_provincia
                ON (r_comune_provincia.comune_id=t_comune.comune_id
                    AND r_comune_provincia.data_cancellazione IS NULL)
            LEFT JOIN siac_t_provincia t_provincia
                ON (t_provincia.provincia_id=r_comune_provincia.provincia_id
                    AND t_provincia.data_cancellazione IS NULL)   
    where t_soggetto.soggetto_id=r_ord_soggetto.soggetto_id
    	and r_ord_soggetto.ente_proprietario_id='||p_ente_prop_id; 
        sqlQuery=sqlQuery|| ' AND t_soggetto.data_cancellazione IS NULL 
        and r_ord_soggetto.data_cancellazione IS NULL ),
doc as (
      select r_subdoc_ordinativo_ts.ord_ts_id,
          COALESCE(t_doc.doc_numero,'''') num_fattura, 
          COALESCE(t_doc.doc_anno,0) anno_fattura, 
          COALESCE(t_doc.doc_importo,0) importo_fattura,
          t_doc.doc_id, t_subdoc.subdoc_id,
          COALESCE(t_subdoc.subdoc_numero,0) num_subdoc, 
          COALESCE(t_subdoc.subdoc_importo,0) importo_subdoc, 
          COALESCE(d_doc_tipo.doc_tipo_code,'''') doc_tipo_code
    from siac_r_subdoc_ordinativo_ts r_subdoc_ordinativo_ts,
            siac_t_subdoc t_subdoc,
            siac_t_doc 	t_doc
            LEFT JOIN siac_d_doc_tipo d_doc_tipo
                ON (d_doc_tipo.doc_tipo_id=t_doc.doc_tipo_id
                    AND d_doc_tipo.data_cancellazione IS NULL)
    where t_subdoc.subdoc_id= r_subdoc_ordinativo_ts.subdoc_id
        AND t_doc.doc_id=  t_subdoc.doc_id
        and r_subdoc_ordinativo_ts.ente_proprietario_id='||p_ente_prop_id||' 
        AND r_subdoc_ordinativo_ts.data_cancellazione IS NULL
        AND t_subdoc.data_cancellazione IS NULL
        AND t_doc.data_cancellazione IS NULL),
classif as ( 
  	select *  
    from fnc_bilr145_tab_classif  ('||p_ente_prop_id||')  ),
accertamenti as ( 
  	select *  
    from fnc_bilr145_tab_accertamenti  ('||p_ente_prop_id||')  ) ,
oneri as ( 
  	select ord_id, COALESCE(importo_imposta,0) importo_imposta,
    	   COALESCE(importo_ritenuta,0) importo_ritenuta
    from fnc_bilr145_tab_oneri  ('||p_ente_prop_id||')  )                                      
select ente.ente_denominazione::varchar nome_ente,
		ente.cod_fisc_ente::varchar partita_iva_ente, 
        ord.anno_eser::integer anno_ese_finanz,
		ord.ord_anno::integer anno_capitolo,
        cap.elem_code::varchar cod_capitolo,
        cap.elem_code2::varchar cod_articolo,
		classif.cod_gestione::varchar,
  		accertamenti.num_accertamento::varchar,
		''''::varchar num_subimpegno,
		ord.ord_ts_det_importo::numeric importo_lordo_reversale,
		ord.ord_numero::integer numero_reversale,
		ord.ord_emissione_data::date data_reversale,
		ord.ord_cast_cassa::numeric importo_stanz_cassa,
		ord.ord_cast_emessi::numeric importo_tot_reversali_emessi,
		(ord.ord_cast_emessi+ord.ord_ts_det_importo)::numeric importo_tot_reversali_dopo_emiss,
        case when ord.ord_cast_cassa >= (ord.ord_cast_emessi+ord.ord_ts_det_importo) 
			THEN (ord.ord_cast_cassa - (ord.ord_cast_emessi+ord.ord_ts_det_importo))::numeric
            ELSE 0::numeric end importo_dispon, 
        ente.ente_oil_tes_desc::varchar nome_tesoriere,
		ord.ord_desc::varchar desc_causale,
 		case when COALESCE(doc.num_fattura,'''')=''''	
        	THEN ''''::varchar 
            ELSE (doc.num_fattura||''/''||doc.num_subdoc::varchar)::varchar end num_fattura,
        case when COALESCE(doc.num_fattura,'''')=''''
        	THEN 0::integer 
            ELSE doc.anno_fattura::integer end anno_fattura,
        case when COALESCE(doc.num_fattura,'''')=''''
        	THEN 0::numeric 
            ELSE doc.importo_subdoc::numeric end importo_fattura,            
		case when sogg.partita_iva=''''
        	THEN sogg.codice_fiscale::varchar
            ELSE ''''::varchar end versante_cod_fiscale,
        sogg.partita_iva::varchar versante_partita_iva,
        sogg.soggetto_desc::varchar versante_nome,       
        upper(sogg.via_tipo_desc||'' ''||sogg.toponimo||
    		'' ''||sogg.numero_civico)::varchar versante_indirizzo,
        sogg.zip_code::varchar versante_cap,       
 /*   if elencoReversali.zip_code ='' and versante_indirizzo <> '' THEN
    	versante_cap=''00000'';
    else 
    	versante_cap=elencoReversali.zip_code;
    end if;*/
    	sogg.comune_desc::varchar versante_localita,
    	sogg.sigla_automobilistica::varchar versante_provincia,
		(COALESCE(ord.ord_ts_det_importo,0) - 
         COALESCE(oneri.importo_ritenuta,0) -
         COALESCE(oneri.importo_imposta,0))::numeric importo_netto,               
        ente.ente_oil_resp_ord::varchar resp_sett_amm,
 		substr(cap.tipologia_code,1,5)::varchar tit_tipo_categ,
		classif.transaz_elementare::varchar transaz_elementare,
		ente.ente_oil_resp_amm::varchar resp_amm,
        accertamenti.anno_primo_accertamento::varchar  anno_primo_accertamento,
  		''''::varchar display_error,
  		ord.ord_stato_code::varchar cod_stato_reversale                         
	from ord
			left join sogg on ord.ord_id=sogg.ord_id
            left join doc on ord.ord_ts_id=doc.ord_ts_id
            left join classif on ord.ord_id= classif.ord_id
            left join accertamenti on ord.ord_id= accertamenti.ord_id
            left join oneri on ord.ord_id= oneri.ord_id, 
        cap, ente 
where ord.ord_id=cap.ord_id
and ord.ente_proprietario_id=ente.ente_proprietario_id
and ord.ente_proprietario_id='||p_ente_prop_id; 
sqlQuery=sqlQuery||  
' order by ord.ord_numero, ord.ord_emissione_data, 
doc.num_fattura, doc.num_subdoc';

--sqlQuery=sqlQuery|| ' and ord.ord_numero between 1 and 100
--AND ord.ord_anno=2016';
raise notice 'sqlQuery = %',sqlQuery;   

return query execute sqlQuery;
  

exception
	when no_data_found THEN
		raise notice 'Nessuna reversale trovata' ;
		return;
	when others  THEN
 		RAISE EXCEPTION '% Errore : %-%.',RTN_MESSAGGIO,SQLSTATE,substring(SQLERRM from 1 for 500);
        return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY DEFINER
COST 100 ROWS 1000;