/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac."BILR167_registrazioni_stato_notificato_entrate" (
  p_ente_proprietario_id integer,
  p_anno_bilancio varchar,
  p_ambito varchar,
  p_tipo_evento varchar,
  p_data_reg_da date,
  p_data_reg_a date,
  p_anno_capitolo varchar,
  p_num_capitolo varchar,
  p_code_soggetto varchar,
  p_cod_conto_fin varchar
)
RETURNS TABLE (
  pdce_conto_fin_code varchar,
  pdce_conto_fin_desc varchar,
  pdce_conto_fin_code_agg varchar,
  pdce_conto_fin_desc_agg varchar,
  bil_elem_code varchar,
  bil_elem_code2 varchar,
  bil_elem_code3 varchar,
  anno_bil_elem varchar,
  evento_code varchar,
  evento_tipo_code varchar,
  tipo_coll_code varchar,
  ambito_code varchar,
  data_registrazione date,
  numero_movimento varchar,
  anno_movimento varchar,
  code_soggetto varchar,
  desc_soggetto varchar,
  display_error varchar,
  regmovfin_id integer
) AS
$body$
DECLARE

bilancio_id integer;
RTN_MESSAGGIO text;
sql_query VARCHAR;
contaDate INTEGER;
contaDatiCap INTEGER;
cod_soggetto_verif VARCHAR;
cod_pdce_verif VARCHAR;

BEGIN
  RTN_MESSAGGIO:='select 1';
    
  /*IF introdotta per motivi prestazionali (SIAC-6112).
  Per fare in modo che la funizone venga lanciata solo se il valore del parametro p_tipo_evento
  si riferisce ad un evento di entrata*/   
  IF p_tipo_evento in ('A', 'DE', 'OI', 'RS', 'RT') THEN
  
  /* QUESTA PROCEDURA e' richiamata oltre che dal report BILR167
  		anche dal BILR168 */
          
  select a.bil_id into bilancio_id from siac_t_bil a,siac_t_periodo b
  where a.ente_proprietario_id = p_ente_proprietario_id 
  and b.periodo_id = a.periodo_id
  and b.anno = p_anno_bilancio;

display_error:='';
contaDate:=0;
contaDatiCap:=0;

if p_data_reg_da IS NOT NULL THEN
	contaDate = contaDate+1;
end if;
if p_data_reg_a IS NOT NULL THEN
	contaDate = contaDate+1;
end if;   

if contaDate = 1 THEN
	display_error:='OCCORRE SPECIFICARE ENTRAMBE LE DATE DELL''INTERVALLO ''DATA REGISTRAZIONE DA'' / ''DATA REGISTRAZIONE A''';
    return next;
    return;
end if;

if p_anno_capitolo is not null AND p_anno_capitolo <> '' THEN
	contaDatiCap:=contaDatiCap+1;
end if;
if p_num_capitolo is not null AND p_num_capitolo <> '' THEN
	contaDatiCap:=contaDatiCap+1;
end if;
if contaDatiCap = 1 THEN
	display_error:='OCCORRE SPECIFICARE SIA L''ANNO CHE IL NUMERO DEL CAPITOLO';
    return next;
    return;
end if;

if p_anno_capitolo is not null AND p_anno_capitolo <> '' AND	
	p_anno_capitolo <> p_anno_bilancio THEN
    display_error:='L''ANNO DEL CAPITOLO DEVE ESSERE IDENTICO A QUELLO DEL BILANCIO.';
    return next;
    return;
end if;
if p_code_soggetto is not null and p_code_soggetto <> '' THEN
	cod_soggetto_verif:='';
	select a.soggetto_code
    	into cod_soggetto_verif
    from siac_t_soggetto a
    where a.soggetto_code=trim(p_code_soggetto)
    	and a.ente_proprietario_id =p_ente_proprietario_id
    	and a.data_cancellazione is null;
    IF NOT FOUND THEN
		select a.soggetto_classe_code
    		into cod_soggetto_verif
    	from siac_d_soggetto_classe a
    	where a.soggetto_classe_code=trim(p_code_soggetto)
        	and a.ente_proprietario_id =p_ente_proprietario_id
    		and a.data_cancellazione is null;
    	IF NOT FOUND THEN
        	display_error:='IL CODICE SOGGETTO INDICATO NON ESISTE.';
    		return next;
    		return;
        end if;
    END IF;
end if;
if p_ambito ='AMBITO_FIN' AND 
	(p_cod_conto_fin is not null and p_cod_conto_fin <> '') then
    	cod_pdce_verif:='';
        select t_class.classif_code
        into cod_pdce_verif
        from siac_t_class t_class,
        	siac_d_class_tipo d_class_tipo
        where d_class_tipo.classif_tipo_id=t_class.classif_tipo_id
        and t_class.ente_proprietario_id=p_ente_proprietario_id
        and t_class.classif_code=p_cod_conto_fin
        and d_class_tipo.classif_tipo_code like 'PDC_%';
    IF NOT FOUND THEN
    	display_error:='IL CODICE CONTO FINANZIARIO INDICATO NON ESISTE.';
    	return next;
    	return;
    end if;
    
end if;
    
/*
Possibili ambiti: AMBITO_GSA o AMBITO_FIN
*/
sql_query= '
 -- return query
  select zz.* from (
  with capall as(
 with cap as (
  select cl.classif_id,
  anno_eserc.anno anno_cap,
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
and e.ente_proprietario_id			=	'||p_ente_proprietario_id||'
and anno_eserc.anno					= 	'''||p_anno_bilancio||'''
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
--and	cat_del_capitolo.elem_cat_code	=	''STD''
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
and now() between rc.validita_inizio and COALESCE(rc.validita_fine,now())
and now() between r_cat_capitolo.validita_inizio and COALESCE(r_cat_capitolo.validita_fine,now())
  ), 
  dati_registro_mov as(
  WITH registro_mov AS (
  select 
  	d_ambito.ambito_code, d_evento.evento_code , d_evento_tipo.evento_tipo_code,
 	d_reg_movfin_stato.regmovfin_stato_code,
  	t_reg_movfin.data_creazione data_registrazione,
    d_coll_tipo.collegamento_tipo_code,d_coll_tipo.collegamento_tipo_desc,  
    t_reg_movfin.*,t_class.classif_code pdce_conto_fin_code, 
    t_class.classif_desc pdce_conto_fin_desc,
    t_class2.classif_code pdce_conto_fin_code_agg, 
    t_class2.classif_desc pdce_conto_fin_desc_agg,
    r_ev_reg_movfin.campo_pk_id, r_ev_reg_movfin.campo_pk_id_2
from siac_t_reg_movfin t_reg_movfin
		LEFT JOIN siac_t_class t_class
        	ON (t_class.classif_id= t_reg_movfin.classif_id_iniziale
            	AND t_class.data_cancellazione IS NULL)
		LEFT JOIN siac_t_class t_class2
        	ON (t_class2.classif_id= t_reg_movfin.classif_id_aggiornato
            	AND t_class2.data_cancellazione IS NULL),            
	siac_r_reg_movfin_stato r_reg_movfin_stato,
    siac_d_reg_movfin_stato d_reg_movfin_stato, 
    siac_d_ambito d_ambito,
    siac_r_evento_reg_movfin r_ev_reg_movfin,
    siac_d_evento d_evento,
    siac_d_evento_tipo d_evento_tipo,
    siac_d_collegamento_tipo d_coll_tipo,
    siac_t_bil t_bil,
    siac_t_periodo t_periodo
where t_reg_movfin.regmovfin_id= r_reg_movfin_stato.regmovfin_id
and r_reg_movfin_stato.regmovfin_stato_id=d_reg_movfin_stato.regmovfin_stato_id
and d_ambito.ambito_id=t_reg_movfin.ambito_id
and d_coll_tipo.collegamento_tipo_id=d_evento.collegamento_tipo_id
and r_ev_reg_movfin.regmovfin_id=t_reg_movfin.regmovfin_id
and d_evento.evento_id=r_ev_reg_movfin.evento_id
and d_evento_tipo.evento_tipo_id=d_evento.evento_tipo_id
and t_reg_movfin.bil_id=t_bil.bil_id
and t_bil.periodo_id=t_periodo.periodo_id
and t_reg_movfin.ente_proprietario_id='||p_ente_proprietario_id||'
and t_periodo.anno='''||p_anno_bilancio||'''
and d_reg_movfin_stato.regmovfin_stato_code=''N'' --Notificato
and d_ambito.ambito_code = '''||p_ambito||''' 
and d_evento_tipo.evento_tipo_code ='''||p_tipo_evento||''' ';
if contaDate = 2 THEN  --inserito filtro sulle date.
	sql_query=sql_query|| ' and date_trunc(''day'',t_reg_movfin.data_creazione) between '''||p_data_reg_da||''' and '''||p_data_reg_a||''' ';
end if;
sql_query=sql_query||' and t_reg_movfin.data_cancellazione IS NULL   
and r_reg_movfin_stato.data_cancellazione IS NULL
and d_reg_movfin_stato.data_cancellazione IS NULL
and d_ambito.data_cancellazione IS NULL
and r_ev_reg_movfin.data_cancellazione IS NULL
and d_evento.data_cancellazione IS NULL
and d_coll_tipo.data_cancellazione IS NULL
and t_bil.data_cancellazione IS NULL
and t_periodo.data_cancellazione IS NULL
and d_evento_tipo.data_cancellazione IS NULL
  ),  
  collegamento_MMGS_MMGE_a AS ( 
  SELECT DISTINCT rmbe.elem_id, tm.mod_id,
  		movgest.movgest_anno anno_movimento, 
        movgest.movgest_numero numero_movimento,
        r_movgest_ts_sog.soggetto_id, r_movgest_ts_sog_classe.soggetto_classe_id
  FROM  siac_t_modifica tm, siac_r_modifica_stato rms, siac_d_modifica_stato dms,
        siac_t_movgest_ts_det_mod tmtdm, 
        siac_t_movgest_ts tmt
        	LEFT JOIN siac_r_movgest_ts_sog r_movgest_ts_sog
            	ON (r_movgest_ts_sog.movgest_ts_id=tmt.movgest_ts_id
                	 AND   r_movgest_ts_sog.data_cancellazione IS NULL)
            LEFT JOIN siac_r_movgest_ts_sogclasse r_movgest_ts_sog_classe
            	ON (r_movgest_ts_sog_classe.movgest_ts_id=tmt.movgest_ts_id
                	 AND   r_movgest_ts_sog_classe.data_cancellazione IS NULL),
        siac_r_movgest_bil_elem rmbe, siac_t_movgest movgest
  WHERE rms.ente_proprietario_id = '||p_ente_proprietario_id||'
  AND   tm.mod_id = rms.mod_id  
  AND   rms.mod_stato_id = dms.mod_stato_id
  AND   tmtdm.mod_stato_r_id = rms.mod_stato_r_id
  AND   tmt.movgest_ts_id = tmtdm.movgest_ts_id
  AND   rmbe.movgest_id = tmt.movgest_id
  AND 	movgest.movgest_id=tmt.movgest_id
  AND   dms.mod_stato_code = ''V''
  AND   movgest.bil_id='||bilancio_id||'
  AND   tm.data_cancellazione IS NULL
  AND   rms.data_cancellazione IS NULL
  AND   dms.data_cancellazione IS NULL
  AND   tmtdm.data_cancellazione IS NULL
  AND   tmt.data_cancellazione IS NULL
  AND   rmbe.data_cancellazione IS NULL
  AND 	movgest.data_cancellazione IS NULL
  ), 
  collegamento_MMGS_MMGE_b AS (
  SELECT DISTINCT rmbe.elem_id, tm.mod_id, 
  		movgest.movgest_anno anno_movimento, 
        movgest.movgest_numero numero_movimento,
        r_movgest_ts_sog.soggetto_id, r_movgest_ts_sog_classe.soggetto_classe_id
  FROM  siac_t_modifica tm, siac_r_modifica_stato rms, siac_d_modifica_stato dms,
        siac_r_movgest_ts_sog_mod rmtsm, 
        siac_t_movgest_ts tmt
        	LEFT JOIN siac_r_movgest_ts_sog r_movgest_ts_sog
            	ON (r_movgest_ts_sog.movgest_ts_id=tmt.movgest_ts_id
                	 AND   r_movgest_ts_sog.data_cancellazione IS NULL)
            LEFT JOIN siac_r_movgest_ts_sogclasse r_movgest_ts_sog_classe
            	ON (r_movgest_ts_sog_classe.movgest_ts_id=tmt.movgest_ts_id
                	 AND   r_movgest_ts_sog_classe.data_cancellazione IS NULL),                     
        siac_r_movgest_bil_elem rmbe, siac_t_movgest movgest
  WHERE rms.ente_proprietario_id = '||p_ente_proprietario_id||'
  AND   tm.mod_id = rms.mod_id  
  AND   rms.mod_stato_id = dms.mod_stato_id
  AND   rmtsm.mod_stato_r_id = rms.mod_stato_r_id
  AND   tmt.movgest_ts_id = rmtsm.movgest_ts_id
  AND   rmbe.movgest_id = tmt.movgest_id
  AND 	movgest.movgest_id=tmt.movgest_id
  AND   dms.mod_stato_code = ''V''
  AND   movgest.bil_id='||bilancio_id||'
  AND   tm.data_cancellazione IS NULL
  AND   rms.data_cancellazione IS NULL
  AND   dms.data_cancellazione IS NULL
  AND   rmtsm.data_cancellazione IS NULL
  AND   tmt.data_cancellazione IS NULL
  AND   rmbe.data_cancellazione IS NULL
  AND 	movgest.data_cancellazione IS NULL
  ), 
  collegamento_I_A AS (
  SELECT DISTINCT a.elem_id, a.movgest_id, 
  b.movgest_anno anno_movimento, b.movgest_numero numero_movimento,
  		r_movgest_ts_sog.soggetto_id, r_movgest_ts_sog_classe.soggetto_classe_id
  FROM   siac_r_movgest_bil_elem a, siac_t_movgest b,
  		siac_d_movgest_ts_tipo movgest_ts_tipo,
  		siac_t_movgest_ts tmt
        	LEFT JOIN siac_r_movgest_ts_sog r_movgest_ts_sog
            	ON (r_movgest_ts_sog.movgest_ts_id=tmt.movgest_ts_id
                	 AND   r_movgest_ts_sog.data_cancellazione IS NULL)
            LEFT JOIN siac_r_movgest_ts_sogclasse r_movgest_ts_sog_classe
            	ON (r_movgest_ts_sog_classe.movgest_ts_id=tmt.movgest_ts_id
                	 AND   r_movgest_ts_sog_classe.data_cancellazione IS NULL)                
  WHERE  a.movgest_id=b.movgest_id
  AND	 b.movgest_id = tmt.movgest_id
  AND 	 tmt.movgest_ts_tipo_id = movgest_ts_tipo.movgest_ts_tipo_id
  AND    a.ente_proprietario_id = '||p_ente_proprietario_id||'
  AND 	 movgest_ts_tipo.movgest_ts_tipo_code=''T''
  AND    b.bil_id='||bilancio_id||'
  AND    a.data_cancellazione IS NULL
  AND  	 b.data_cancellazione IS NULL
  AND	 movgest_ts_tipo.data_cancellazione IS NULL
  ),
  collegamento_SI_SA AS (
  SELECT DISTINCT b.elem_id, a.movgest_ts_id,
  	c.movgest_anno anno_movimento, 
     --12/10/2017: in caso di SUB aggiunto anche il codice al numero impegno
    c.movgest_numero||'' - ''||a.movgest_ts_code numero_movimento,
    r_movgest_ts_sog.soggetto_id, r_movgest_ts_sog_classe.soggetto_classe_id
  FROM  siac_t_movgest_ts a
  		LEFT JOIN siac_r_movgest_ts_sog r_movgest_ts_sog
            	ON (r_movgest_ts_sog.movgest_ts_id=a.movgest_ts_id
                	 AND   r_movgest_ts_sog.data_cancellazione IS NULL)
        LEFT JOIN siac_r_movgest_ts_sogclasse r_movgest_ts_sog_classe
            ON (r_movgest_ts_sog_classe.movgest_ts_id=a.movgest_ts_id
                 AND   r_movgest_ts_sog_classe.data_cancellazione IS NULL),
  	siac_r_movgest_bil_elem b, siac_t_movgest c
  WHERE a.ente_proprietario_id = '||p_ente_proprietario_id||'
  AND   a.movgest_id = b.movgest_id
  AND   a.movgest_id = c.movgest_id
  AND   c.bil_id='||bilancio_id||'
  AND   a.data_cancellazione IS NULL
  AND   b.data_cancellazione IS NULL
  AND  	c.data_cancellazione IS NULL
  ), 
  collegamento_SS_SE AS (
  SELECT DISTINCT c.elem_id, t_subdoc.subdoc_id,  
  t_doc.doc_anno anno_movimento, 
  t_doc.doc_numero||''-''||t_subdoc.subdoc_numero numero_movimento,
  r_doc_sog.soggetto_id
  FROM siac_t_doc t_doc  
  inner join siac_t_subdoc t_subdoc on t_subdoc.doc_id = t_doc.doc_id 
  left join  siac_r_subdoc_movgest_ts a on (a.subdoc_id = t_subdoc.subdoc_id
                                           and (a.data_cancellazione IS NULL OR (a.data_cancellazione IS NOT NULL
  				                                and a.validita_fine IS NOT NULL
                                                and a.validita_fine > to_timestamp(''31/12/'||p_anno_bilancio||''',''dd/mm/yyyy''))))                                                  
  left join  siac_t_movgest_ts b on (a.movgest_ts_id = b.movgest_ts_id 
                                           and (b.data_cancellazione IS NULL OR (b.data_cancellazione IS NOT NULL
  				                                and b.validita_fine IS NOT NULL
                                                and b.validita_fine > to_timestamp(''31/12/'||p_anno_bilancio||''',''dd/mm/yyyy''))))  
  left join  siac_t_movgest d on (d.movgest_id = b.movgest_id 
                                           and (d.data_cancellazione IS NULL OR (d.data_cancellazione IS NOT NULL
  				                                and d.validita_fine IS NOT NULL
                                                and d.validita_fine > to_timestamp(''31/12/'||p_anno_bilancio||''',''dd/mm/yyyy''))))  
  left join  siac_r_movgest_bil_elem c on (d.movgest_id = c.movgest_id
                                             and c.data_cancellazione IS NULL)
  left join  siac_r_doc_sog r_doc_sog on (r_doc_sog.doc_id=t_doc.doc_id
                	                      and r_doc_sog.data_cancellazione IS NULL)  
  WHERE  t_doc.ente_proprietario_id = '||p_ente_proprietario_id||'
  AND    COALESCE(d.bil_id,'||bilancio_id||')='||bilancio_id;
 
  /* 	Si deve testare la data di fine validita' perche' (da mail di Irene):
     "a causa della doppia gestione che purtroppo non e' stata implementata sui documenti!!!! 
     E' stato trovato questo escamotage per cui la relazione 2016 viene chiusa con una
data dell''anno nuovo (in questo caso 2017) e viene creata quella nuova del 2017
(quella che tra l''altro vediamo da sistema anche sul 2016).
Per cui l''unica soluzione e' recuperare nella tabella r_subdoc_movgest_ts  la
relazione 2016 che troverai non piu' valida."
  */ 
sql_query = sql_query || '
  AND	 t_subdoc.data_cancellazione IS NULL
  AND	 t_doc.data_cancellazione IS NULL
  ),
  collegamento_OP_OI AS (
  SELECT DISTINCT a.elem_id, a.ord_id,
  	t_ord.ord_anno anno_movimento, t_ord.ord_numero numero_movimento,
    siac_r_ordinativo_soggetto.soggetto_id
  FROM   siac_r_ordinativo_bil_elem a, 
  	siac_t_ordinativo t_ord
    	LEFT JOIN siac_r_ordinativo_soggetto
        	ON (siac_r_ordinativo_soggetto.ord_id=t_ord.ord_id
                	 AND   siac_r_ordinativo_soggetto.data_cancellazione IS NULL)
  WHERE  a.ente_proprietario_id = '||p_ente_proprietario_id||'
  AND 	 t_ord.ord_id = a.ord_id
  AND    a.data_cancellazione IS NULL
  AND    t_ord.data_cancellazione IS NULL  
  ),
  collegamento_L AS (
  SELECT DISTINCT c.elem_id, a.liq_id,
    	t_liq.liq_anno anno_movimento, t_liq.liq_numero numero_movimento,
        r_liq_sogg.soggetto_id
  FROM   siac_r_liquidazione_movgest a, siac_t_movgest_ts b, 
  siac_r_movgest_bil_elem c,
  siac_t_movgest d,
  siac_t_liquidazione t_liq
  		LEFT JOIN siac_r_liquidazione_soggetto r_liq_sogg
        	ON (r_liq_sogg.liq_id = t_liq.liq_id
            	AND r_liq_sogg.data_cancellazione IS NULL)
  WHERE  b.ente_proprietario_id = '||p_ente_proprietario_id||'
  AND    a.movgest_ts_id = b.movgest_ts_id
  AND    b.movgest_id = c.movgest_id
  AND    d.movgest_id = b.movgest_id
  AND    d.bil_id='||bilancio_id||'
  AND 	 t_liq.liq_id = a.liq_id
  AND    a.data_cancellazione IS NULL
  AND    b.data_cancellazione IS NULL
  AND    c.data_cancellazione IS NULL
  AND    d.data_cancellazione IS NULL
  AND	 t_liq.data_cancellazione IS NULL
  ),
  collegamento_RR AS (
  SELECT DISTINCT d.elem_id, a.gst_id,
  	movgest.movgest_anno anno_movimento, movgest.movgest_numero numero_movimento,
    r_movgest_ts_sog.soggetto_id, r_movgest_ts_sog_classe.soggetto_classe_id
  FROM  siac_t_giustificativo a, siac_r_richiesta_econ_movgest b, 
  siac_t_movgest_ts c
  		LEFT JOIN siac_r_movgest_ts_sog r_movgest_ts_sog
            	ON (r_movgest_ts_sog.movgest_ts_id=c.movgest_ts_id
                	 AND   r_movgest_ts_sog.data_cancellazione IS NULL)
        LEFT JOIN siac_r_movgest_ts_sogclasse r_movgest_ts_sog_classe
            ON (r_movgest_ts_sog_classe.movgest_ts_id=c.movgest_ts_id
                 AND   r_movgest_ts_sog_classe.data_cancellazione IS NULL),
  siac_r_movgest_bil_elem d, siac_t_movgest movgest
  WHERE a.ente_proprietario_id = '||p_ente_proprietario_id||'
  AND   a.ricecon_id = b.ricecon_id
  AND   b.movgest_ts_id = c.movgest_ts_id
  AND   c.movgest_id = d.movgest_id
  AND	c.movgest_id = movgest.movgest_id
  AND   movgest.bil_id='||bilancio_id||'
  AND   a.data_cancellazione  IS NULL
  AND   b.data_cancellazione  IS NULL
  AND   c.data_cancellazione  IS NULL
  AND   d.data_cancellazione  IS NULL
  AND   movgest.data_cancellazione  IS NULL
  ),
  collegamento_RE AS (
  SELECT DISTINCT c.elem_id, a.ricecon_id,
  movgest.movgest_anno anno_movimento, movgest.movgest_numero numero_movimento,
  r_movgest_ts_sog.soggetto_id, r_movgest_ts_sog_classe.soggetto_classe_id
  FROM  siac_r_richiesta_econ_movgest a, 
  	siac_t_movgest_ts b
    	LEFT JOIN siac_r_movgest_ts_sog r_movgest_ts_sog
            	ON (r_movgest_ts_sog.movgest_ts_id=b.movgest_ts_id
                	 AND   r_movgest_ts_sog.data_cancellazione IS NULL)
    	LEFT JOIN siac_r_movgest_ts_sogclasse r_movgest_ts_sog_classe
            ON (r_movgest_ts_sog_classe.movgest_ts_id=b.movgest_ts_id
                 AND   r_movgest_ts_sog_classe.data_cancellazione IS NULL),
  	siac_r_movgest_bil_elem c, siac_t_movgest movgest
  WHERE b.ente_proprietario_id = '||p_ente_proprietario_id||'
  AND   a.movgest_ts_id = b.movgest_ts_id
  AND   b.movgest_id = c.movgest_id
  AND	b.movgest_id = movgest.movgest_id
  AND   movgest.bil_id='||bilancio_id||'
  AND   a.data_cancellazione  IS NULL
  AND   b.data_cancellazione  IS NULL
  AND   c.data_cancellazione  IS NULL
  AND   movgest.data_cancellazione  IS NULL
  ),
  /* NOTE DI CREDITO
    In questo caso occorre prendere l''impegno del documento collegato e non quello della nota di 
    credito che non esiste */
  collegamento_SS_SE_NCD AS (  
  select c.elem_id, t_subdoc.subdoc_id,
  t_doc.doc_anno anno_movimento, 
  t_doc.doc_numero||''-''||t_subdoc.subdoc_numero numero_movimento,
  r_doc_sog.soggetto_id
  from siac_t_doc t_doc  
  inner join siac_t_subdoc t_subdoc on t_subdoc.doc_id = t_doc.doc_id 
  left join  siac_r_subdoc_movgest_ts a on (a.subdoc_id = t_subdoc.subdoc_id
                                           and (a.data_cancellazione IS NULL OR (a.data_cancellazione IS NOT NULL
  				                                and a.validita_fine IS NOT NULL
                                                and a.validita_fine > to_timestamp(''31/12/'||p_anno_bilancio||''',''dd/mm/yyyy''))))                                                  
  left join  siac_t_movgest_ts b on (a.movgest_ts_id = b.movgest_ts_id 
                                           and (b.data_cancellazione IS NULL OR (b.data_cancellazione IS NOT NULL
  				                                and b.validita_fine IS NOT NULL
                                                and b.validita_fine > to_timestamp(''31/12/'||p_anno_bilancio||''',''dd/mm/yyyy''))))  
  left join  siac_t_movgest d on (d.movgest_id = b.movgest_id 
                                           and (d.data_cancellazione IS NULL OR (d.data_cancellazione IS NOT NULL
  				                                and d.validita_fine IS NOT NULL
                                                and d.validita_fine > to_timestamp(''31/12/'||p_anno_bilancio||''',''dd/mm/yyyy''))))  
  left join  siac_r_movgest_bil_elem c on (d.movgest_id = c.movgest_id
                                             and c.data_cancellazione IS NULL)
  left join  siac_r_doc_sog r_doc_sog on (r_doc_sog.doc_id=t_doc.doc_id
                	                      and r_doc_sog.data_cancellazione IS NULL)  
  WHERE  t_doc.ente_proprietario_id = '||p_ente_proprietario_id||' 
  AND    COALESCE(d.bil_id,'||bilancio_id||')='||bilancio_id||'
  AND	 t_subdoc.data_cancellazione IS NULL
  AND	 t_doc.data_cancellazione IS NULL
  )
  SELECT 
  registro_mov.pdce_conto_fin_code,
  registro_mov.pdce_conto_fin_desc,
  registro_mov.pdce_conto_fin_code_agg,
  registro_mov.pdce_conto_fin_desc_agg,  
  registro_mov.evento_code,registro_mov.evento_tipo_code,
  registro_mov.ambito_code,registro_mov.data_registrazione,
  registro_mov.collegamento_tipo_code,
  registro_mov.regmovfin_id,
  COALESCE(COALESCE(COALESCE(COALESCE(COALESCE(COALESCE(COALESCE(COALESCE(COALESCE(collegamento_MMGS_MMGE_a.elem_id, collegamento_MMGS_MMGE_b.elem_id),collegamento_SS_SE.elem_id),collegamento_I_A.elem_id),collegamento_SI_SA.elem_id),collegamento_OP_OI.elem_id),collegamento_L.elem_id),collegamento_RR.elem_id),collegamento_RE.elem_id), collegamento_SS_SE_NCD.elem_id) elem_id,
  COALESCE(COALESCE(COALESCE(COALESCE(COALESCE(COALESCE(COALESCE(COALESCE(COALESCE(COALESCE(collegamento_MMGS_MMGE_a.numero_movimento::varchar,collegamento_MMGS_MMGE_b.numero_movimento::varchar),collegamento_I_A.numero_movimento::varchar),collegamento_SI_SA.numero_movimento::varchar),collegamento_SS_SE.numero_movimento::varchar),collegamento_OP_OI.numero_movimento::varchar),collegamento_L.numero_movimento::varchar),collegamento_RR.numero_movimento::varchar),collegamento_RE.numero_movimento::varchar),collegamento_SS_SE_NCD.numero_movimento::varchar),'''') numero_movimento,
  COALESCE(COALESCE(COALESCE(COALESCE(COALESCE(COALESCE(COALESCE(COALESCE(COALESCE(COALESCE(collegamento_MMGS_MMGE_a.anno_movimento::varchar,collegamento_MMGS_MMGE_b.anno_movimento::varchar),collegamento_I_A.anno_movimento::varchar),collegamento_SI_SA.anno_movimento::varchar),collegamento_SS_SE.anno_movimento::varchar),collegamento_OP_OI.anno_movimento::varchar),collegamento_L.anno_movimento::varchar),collegamento_RR.anno_movimento::varchar),collegamento_RE.anno_movimento::varchar),collegamento_SS_SE_NCD.numero_movimento::varchar),'''') anno_movimento,
  COALESCE(COALESCE(COALESCE(COALESCE(COALESCE(COALESCE(COALESCE(COALESCE(COALESCE(COALESCE(collegamento_MMGS_MMGE_a.soggetto_id,collegamento_MMGS_MMGE_b.soggetto_id), collegamento_I_A.soggetto_id),collegamento_SI_SA.soggetto_id),collegamento_SS_SE.soggetto_id),collegamento_OP_OI.soggetto_id),collegamento_L.soggetto_id),collegamento_RR.soggetto_id),collegamento_RE.soggetto_id),collegamento_SS_SE_NCD.soggetto_id),0) soggetto_id,
  COALESCE(COALESCE(COALESCE(COALESCE(COALESCE(COALESCE(collegamento_MMGS_MMGE_a.soggetto_classe_id,collegamento_MMGS_MMGE_b.soggetto_classe_id), collegamento_I_A.soggetto_classe_id),collegamento_SI_SA.soggetto_classe_id),collegamento_RR.soggetto_classe_id),collegamento_RE.soggetto_classe_id), 0) soggetto_classe_id
  FROM   registro_mov
  	-- ModificaMovimentoGestioneSpesa O ModificaMovimentoGestioneEntrata
  LEFT   JOIN collegamento_MMGS_MMGE_a ON collegamento_MMGS_MMGE_a.mod_id = registro_mov.campo_pk_id
                                       AND registro_mov.collegamento_tipo_code IN (''MMGS'',''MMGE'') 
  	-- ModificaMovimentoGestioneSpesa O ModificaMovimentoGestioneEntrata
  LEFT   JOIN collegamento_MMGS_MMGE_b ON collegamento_MMGS_MMGE_b.mod_id = registro_mov.campo_pk_id
                                       AND registro_mov.collegamento_tipo_code IN (''MMGS'',''MMGE'')
    -- Impegno o Accertamento                                   
  LEFT   JOIN collegamento_I_A ON collegamento_I_A.movgest_id = registro_mov.campo_pk_id
                                       AND registro_mov.collegamento_tipo_code IN (''I'',''A'')
	-- SubImpegno o SubAccertamento
  LEFT   JOIN collegamento_SI_SA ON collegamento_SI_SA.movgest_ts_id = registro_mov.campo_pk_id
                                       AND registro_mov.collegamento_tipo_code IN (''SI'',''SA'')                                     
  LEFT   JOIN collegamento_SS_SE ON collegamento_SS_SE.subdoc_id = registro_mov.campo_pk_id
                                       AND registro_mov.collegamento_tipo_code IN (''SS'',''SE'')
  LEFT   JOIN collegamento_OP_OI ON collegamento_OP_OI.ord_id = registro_mov.campo_pk_id
                                       AND registro_mov.collegamento_tipo_code IN (''OP'',''OI'')
  LEFT   JOIN collegamento_L ON collegamento_L.liq_id = registro_mov.campo_pk_id
                                       AND registro_mov.collegamento_tipo_code = ''L''
  LEFT   JOIN collegamento_RR ON collegamento_RR.gst_id = registro_mov.campo_pk_id
                                       AND registro_mov.collegamento_tipo_code = ''RR''
  LEFT   JOIN collegamento_RE ON collegamento_RE.ricecon_id = registro_mov.campo_pk_id
                                       AND registro_mov.collegamento_tipo_code = ''RE''
  --20/09/2017: collegamento per note di credito. Si usa campo_pk_id_2
  LEFT	 JOIN collegamento_SS_SE_NCD ON collegamento_SS_SE_NCD.subdoc_id = registro_mov.campo_pk_id_2
  										AND registro_mov.collegamento_tipo_code IN (''SS'',''SE'')                                       
  ) ,
  elenco_soggetti as (
  	select t_sogg.soggetto_id, t_sogg.soggetto_code, t_sogg.soggetto_desc
		from siac_t_soggetto t_sogg
        where t_sogg.ente_proprietario_id ='||p_ente_proprietario_id||'
		and t_sogg.data_cancellazione IS NULL
  ) ,
    elenco_soggetti_classe as (
  	select d_sogg_classe.soggetto_classe_id, d_sogg_classe.soggetto_classe_code, 
    	d_sogg_classe.soggetto_classe_desc
		from siac_d_soggetto_classe d_sogg_classe
        where d_sogg_classe.ente_proprietario_id ='||p_ente_proprietario_id||'
		and d_sogg_classe.data_cancellazione IS NULL
  )                    
  select
  cap.elem_id bil_ele_id,
  cap.elem_code bil_ele_code,
  cap.elem_desc bil_ele_desc,
  cap.elem_code2 bil_ele_code2,
  cap.elem_desc2 bil_ele_desc2,
  cap.elem_id_padre bil_ele_id_padre,
  cap.elem_code3 bil_ele_code3,
  cap.anno_cap,
  dati_registro_mov.*,
  elenco_soggetti.*,
  elenco_soggetti_classe.*
  from dati_registro_mov 
  	left join cap on cap.elem_id = dati_registro_mov.elem_id  
    left join elenco_soggetti on elenco_soggetti.soggetto_id = dati_registro_mov.soggetto_id
    left join elenco_soggetti_classe on elenco_soggetti_classe.soggetto_classe_id = dati_registro_mov.soggetto_classe_id    
  )
  select DISTINCT
      COALESCE(capall.pdce_conto_fin_code,'''')::VARCHAR,
      COALESCE(capall.pdce_conto_fin_desc,'''')::VARCHAR,   
      CASE WHEN capall.pdce_conto_fin_code_agg = capall.pdce_conto_fin_code
      	THEN ''''::VARCHAR
        ELSE COALESCE(capall.pdce_conto_fin_code_agg,'''')::VARCHAR END pdce_conto_fin_code_agg,
      CASE WHEN capall.pdce_conto_fin_desc_agg = capall.pdce_conto_fin_desc
      THEN ''''::VARCHAR
        ELSE COALESCE(capall.pdce_conto_fin_desc_agg,'''')::VARCHAR END pdce_conto_fin_desc_agg,
      COALESCE(capall.bil_ele_code,'''')::VARCHAR,
      COALESCE(capall.bil_ele_code2,'''')::VARCHAR,
      COALESCE(capall.bil_ele_code3,'''')::VARCHAR,
      COALESCE(capall.anno_cap,'''')::VARCHAR,
      capall.evento_code::VARCHAR,
      capall.evento_tipo_code::VARCHAR,
      capall.collegamento_tipo_code::VARCHAR,
      capall.ambito_code::VARCHAR,
      capall.data_registrazione::DATE,
      capall.numero_movimento::VARCHAR,
      capall.anno_movimento::VARCHAR,
      CASE WHEN capall.soggetto_code IS NULL
      	THEN capall.soggetto_classe_code::VARCHAR
        ELSE capall.soggetto_code::VARCHAR END soggetto_code,
      CASE WHEN capall.soggetto_desc IS NULL
      	THEN capall.soggetto_classe_desc::VARCHAR
        ELSE capall.soggetto_desc::VARCHAR END soggetto_desc,
      ''''::VARCHAR,
      capall.regmovfin_id
     from capall ';
     /* se sono stati specificati i parametri per capitolo, soggetto e
     	pdce, inserisco le condizioni */
    if contaDatiCap = 2 THEN
    	sql_query = sql_query || ' where capall.anno_cap ='''||p_anno_capitolo|| '''
        	and capall.bil_ele_code ='''||p_num_capitolo|| '''';
 	end if;
    if p_code_soggetto is not null  and p_code_soggetto <> '' THEN
    	 if contaDatiCap = 2 THEN
         	sql_query = sql_query || ' AND (capall.soggetto_code = '''||p_code_soggetto||'''
            	OR capall.soggetto_classe_code = '''||p_code_soggetto||''')';
         else
         	sql_query = sql_query || ' WHERE (capall.soggetto_code = '''||p_code_soggetto||'''
            	OR capall.soggetto_classe_code = '''||p_code_soggetto||''')';
         end if;         
    end if;
    if p_cod_conto_fin is not null  and p_cod_conto_fin <> '' THEN
    	if contaDatiCap = 2 OR 
        	(p_code_soggetto is not null  and p_code_soggetto <> '') THEN
            	sql_query = sql_query || ' AND capall.pdce_conto_fin_code ='''||p_cod_conto_fin||''' ';
    	else
        		sql_query = sql_query || ' WHERE capall.pdce_conto_fin_code ='''||p_cod_conto_fin||''' ';
    	end if;
    end if;
    
    sql_query = sql_query || ' ) as zz; ';

raise notice 'sql_query = %', sql_query;
return query execute sql_query;

END IF;

  exception
  when no_data_found THEN
  raise notice 'nessun dato trovato per struttura bilancio';
  return;
  when others  THEN
  RAISE EXCEPTION '% Errore : %-%.',RTN_MESSAGGIO,SQLSTATE,substring(SQLERRM from 1 for 500);
  return;
    
    
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100 ROWS 1000;