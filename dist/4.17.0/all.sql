/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
--SIAC-7090 - Maurizio - INIZIO

DROP FUNCTION if exists siac."BILR063_giornaliera_pagamenti"(p_ente_prop_id integer, p_anno varchar, p_periodo_dal date, p_periodo_al date);

CREATE OR REPLACE FUNCTION siac."BILR063_giornaliera_pagamenti" (
  p_ente_prop_id integer,
  p_anno varchar,
  p_periodo_dal date,
  p_periodo_al date
)
RETURNS TABLE (
  anno_quietanza varchar,
  data_quietanza date,
  importo_quietanza numeric,
  numero_quietanza numeric,
  anno_ord integer,
  numero_ord numeric,
  quota varchar,
  tipo_finanziamento varchar,
  creditore varchar,
  codice_creditore varchar,
  causale varchar,
  exist_mutui_mezzi varchar,
  desc_ente varchar
) AS
$body$
DECLARE

giornalieraPagamenti record;

DEF_NULL	constant varchar:=''; 
RTN_MESSAGGIO 		varchar(1000):=DEF_NULL;
data_inizio_anno_app varchar (10):=DEF_NULL;
data_inizio_anno date:=NULL;
conta_classif integer;
flag_mutui_mezzi varchar;
bilancio_id integer;

BEGIN

anno_quietanza='';
data_quietanza=NULL;
importo_quietanza=0;
anno_ord=0;
numero_ord=0;
quota='';
tipo_finanziamento='';
creditore='';
codice_creditore ='';
causale='';
numero_quietanza=0;
desc_ente='';
/*
L'estrazione dei dati deve partire dal 1/1 dell'anno in input perche' nel report
serve presentare giorno per giorno il totale precedente.
Sara' quindi il report a limitare la presentazione dei dati al periodo
specificato dall'utente.
*/
data_inizio_anno_app='01/01'||p_anno;
data_inizio_anno=to_date(data_inizio_anno_app,'dd/MM/YYYY');

conta_classif=0;
      /* 03/02/2016: verifico se per l'ente esiste la possibilita' di classificare il capitolo
      	con tipo finanziamento = MU o MB.
        In caso affermativo il report visualizzera' le colonne MUTUI e MEZZI,
        altrimenti presentera' solo la colonna con le altre tipologie di finanziamento 
        La modifica e' stata messa in produzione il 26/04/2016 */
BEGIN            
  SELECT count(classificazioni.classif_code)
      into conta_classif
  from siac_t_class 	classificazioni,
      siac_d_class_tipo	tipo_classif
  where tipo_classif.classif_tipo_id = classificazioni.classif_tipo_id
      and tipo_classif.classif_tipo_code='TIPO_FINANZIAMENTO'
      and  classificazioni.classif_code in ('MB','MU')
      and  classificazioni.ente_proprietario_id=p_ente_prop_id
      AND classificazioni.data_cancellazione IS NULL
      AND tipo_classif.data_cancellazione IS NULL;     
  IF NOT FOUND THEN
	conta_classif=0;
  END IF;      
  
if conta_classif > 0 THEN
	flag_mutui_mezzi ='S';
  else
	 flag_mutui_mezzi ='N';
 end if;  
END;      

select bilancio.bil_id into bilancio_id
from siac_t_bil       bilancio,
     siac_t_periodo      anno_eserc
where bilancio.periodo_id =anno_eserc.periodo_id
	and bilancio.ente_proprietario_id= p_ente_prop_id
	and anno_eserc.anno= p_anno  
    and bilancio.data_cancellazione IS NULL
    and anno_eserc.data_cancellazione IS NULL;
IF NOT FOUND THEN
	bilancio_id=0;
END IF; 
  
RTN_MESSAGGIO:='estrazione dei dati e preparazione dati in output ''.';                

/*select liquidazione.liq_anno    anno_quietanza,  ----sara' sostituita da quietanza
		liquidazione.liq_emissione_data   data_quietanza, ----sara' sostituita da quietanza
        liquidazione.liq_importo   importo_quietanza, ----sara' sostituita da quietanza
        liquidazione.liq_numero		numero_quietanza, ----sara' sostituita da quietanza
        ordinativo.ord_anno    anno_ord,
        ordinativo.ord_numero   numero_ord,
        ts_ordinativo.ord_ts_code quota,
        classificazioni.classif_code  tipo_finanziamento,
       soggetto.soggetto_desc  creditore,
       soggetto.soggetto_code  codice_creditore,
       ordinativo.ord_desc   causale
       --ts_ordinativo.ord_ts_desc
from   	siac_t_bil       bilancio,
		siac_t_periodo      anno_eserc,
        siac_r_liquidazione_ord r_liqu_ord,
        siac_t_liquidazione	liquidazione,
        siac_t_ordinativo    ordinativo,
        siac_t_ordinativo_ts   ts_ordinativo,
        siac_d_ordinativo_tipo   tipo_ordinativo,
        siac_r_liquidazione_movgest  liquidazione_mov_gest,
        siac_t_movgest_ts    ts_movimenti,
        siac_r_movgest_bil_elem    r_capitolo_movimento,
        siac_t_bil_elem 	bil_elem,
        siac_t_class			classificazioni,
		siac_d_class_tipo 		tipo_classif,
         siac_r_bil_elem_class	r_capitolo_class,
        siac_t_soggetto			soggetto,
        siac_r_liquidazione_soggetto   r_soggetto_liquid
where anno_eserc.anno      =  p_anno
	  and bilancio.ente_proprietario_id = p_ente_prop_id    
      and bilancio.periodo_id     = anno_eserc.periodo_id
       and	r_liqu_ord.ente_proprietario_id=bilancio.ente_proprietario_id
       and	r_liqu_ord.sord_id= ordinativo.ord_id
       and ordinativo.ord_tipo_id   = tipo_ordinativo.ord_tipo_id
       and tipo_ordinativo.ord_tipo_code  =  'P'  ------ PAGATO
       and ordinativo.bil_id = bilancio.bil_id
       and ts_ordinativo.ord_id = ordinativo.ord_id
      -- utilizzo come data DA il 1/1 dell'anno in input e non il parametro.
      -- and (liquidazione.liq_emissione_data>= p_periodo_dal AND
      and (liquidazione.liq_emissione_data>= data_inizio_anno AND      
       		liquidazione.liq_emissione_data<= p_periodo_al)
       and r_liqu_ord.liq_id = liquidazione_mov_gest.liq_id 
       and liquidazione.liq_id = r_liqu_ord.liq_id
       and liquidazione_mov_gest.movgest_ts_id=ts_movimenti.movgest_ts_id
       and r_capitolo_movimento.movgest_id = ts_movimenti.movgest_id
       and bil_elem.elem_id = r_capitolo_movimento.elem_id
       and tipo_classif.classif_tipo_id=classificazioni.classif_tipo_id
		and classificazioni.classif_id=r_capitolo_class.classif_id
		and r_capitolo_class.elem_id=r_capitolo_movimento.elem_id
		and tipo_classif.classif_tipo_code='TIPO_FINANZIAMENTO'
       --and classificazioni.classif_code in ('MB','MU')
       and r_soggetto_liquid.liq_id = liquidazione.liq_id
       and r_soggetto_liquid.soggetto_id = soggetto.soggetto_id
 		and now() between bilancio.validita_inizio and coalesce (bilancio.validita_fine, now())
		and now() between anno_eserc.validita_inizio and coalesce (anno_eserc.validita_fine, now())
		and now() between tipo_classif.validita_inizio and coalesce (tipo_classif.validita_fine, now())
		and now() between classificazioni.validita_inizio and coalesce (classificazioni.validita_fine, now())
		and now() between r_capitolo_class.validita_inizio and coalesce (r_capitolo_class.validita_fine, now())
		and now() between ordinativo.validita_inizio and coalesce (ordinativo.validita_fine, now())
		and now() between r_liqu_ord.validita_inizio and coalesce (r_liqu_ord.validita_fine, now())
		and now() between ts_ordinativo.validita_inizio and coalesce (ts_ordinativo.validita_fine, now())       
        and now() between tipo_ordinativo.validita_inizio and coalesce (tipo_ordinativo.validita_fine, now()) 
        and now() between liquidazione_mov_gest.validita_inizio and coalesce (liquidazione_mov_gest.validita_fine, now()) 
        and now() between ts_movimenti.validita_inizio and coalesce (ts_movimenti.validita_fine, now()) 
        and now() between r_capitolo_movimento.validita_inizio and coalesce (r_capitolo_movimento.validita_fine, now()) 
        and now() between bil_elem.validita_inizio and coalesce (bil_elem.validita_fine, now()) 
        and now() between soggetto.validita_inizio and coalesce (soggetto.validita_fine, now()) 
        and now() between r_soggetto_liquid.validita_inizio and coalesce (r_soggetto_liquid.validita_fine, now()) 
        and now() between liquidazione.validita_inizio and coalesce (liquidazione.validita_fine, now())              
	order by data_quietanza, numero_ord, quota*/         

/* 03/02/2016. E' stata introdotta la data di quietanza al posto di quella della
	liquidazione.
    Si prendono solo quelli con questa data valorizzata (quietanziati).    
    La data e' ord_trasm_oil_data su SIAC_T_ORDINATIVO.
    Il numero di quietanza e' presente sulla tabella siac_r_ordinativo_quietanza.
    Non per tutti gli enti pero' viene valorizzato, ma solo per quelli per cui
    c'e' il dato di ritorno dal tesoriere.
    Nel caso non esista sara' valorizzato a 0 ed il report non lo visualizzera'.
    
    Inoltre non si filtra sul tipo di finanziamento (MU/BU) perche' presentiamo tutti i
    dati per ogni tipologia di finanziamento.
    E' il report che si preoccupa di presentare in modo opportuno (MUTUI/MEZZI/ALTRO)
    i dati.
    Questo perche' il tipo di finanziamento sul capitolo non e' obbligatorio e quindi
    potrebbero non esserci pagamenti su MU e BU anche se previsti per l'ente.    

*/                            

/* 14/10/2019: SIAC-7090.
	Riscritta la query usanto "return query" e "with" per problemi di prestazioni.
    l'id del bilancio e' letto all'inizio della procedura per evitare il join
    con le tabelle siac_t_bil e siac_t_periodo.
*/    
return query 
with dati_pagamenti as (  
select liquidazione.liq_anno    anno_quietanza,  
        liquidazione.liq_emissione_data    , 
        liquidazione.liq_importo   , 
        liquidazione.liq_numero        , 
        ordinativo.ord_trasm_oil_data  data_quietanza,
		ts_det_ordinativo.ord_ts_det_importo importo_quietanza,      
        ordinativo.ord_anno    anno_ord,
        ordinativo.ord_numero   numero_ord,
        ordinativo.ord_trasm_oil_data ,
        ts_ordinativo.ord_ts_code quota,
        soggetto.soggetto_desc  creditore,
         soggetto.soggetto_code  codice_creditore,
       ordinativo.ord_desc   causale,
       ts_ordinativo.ord_ts_desc, bil_elem.elem_id, r_ord_quietanza.ord_quietanza_numero,
       t_ente_prop.ente_denominazione
from       	siac_r_liquidazione_ord r_liqu_ord,
        	siac_t_liquidazione    liquidazione
                left join siac_r_liquidazione_soggetto r_soggetto_liquid
                    on (r_soggetto_liquid.liq_id = liquidazione.liq_id
                        AND r_soggetto_liquid.data_cancellazione IS NULL)
                left join siac_t_soggetto soggetto
                    on (r_soggetto_liquid.soggetto_id = soggetto.soggetto_id
                        AND soggetto.data_cancellazione IS NULL),
        	siac_t_ordinativo    ordinativo
                LEFT JOIN siac_r_ordinativo_quietanza r_ord_quietanza
                    on (r_ord_quietanza.ord_id=ordinativo.ord_id
                        AND r_ord_quietanza.data_cancellazione IS NULL),
            siac_t_ordinativo_ts   ts_ordinativo,
            siac_t_ordinativo_ts_det   ts_det_ordinativo,
            siac_d_ordinativo_ts_det_tipo d_ord_ts_det_tipo,
            siac_d_ordinativo_tipo   tipo_ordinativo,
            siac_r_liquidazione_movgest  liquidazione_mov_gest,
            siac_t_movgest_ts    ts_movimenti,
            siac_r_movgest_bil_elem    r_capitolo_movimento,
            siac_t_bil_elem     bil_elem,
            siac_t_ente_proprietario  t_ente_prop
where  r_liqu_ord.sord_id= ts_ordinativo.ord_ts_id
       and ordinativo.ord_tipo_id   = tipo_ordinativo.ord_tipo_id              
       and ts_ordinativo.ord_id = ordinativo.ord_id
       and ts_det_ordinativo.ord_ts_id=ts_ordinativo.ord_ts_id
       and d_ord_ts_det_tipo.ord_ts_det_tipo_id=ts_det_ordinativo.ord_ts_det_tipo_id      
       and r_liqu_ord.liq_id = liquidazione_mov_gest.liq_id
       and liquidazione.liq_id = r_liqu_ord.liq_id
       and liquidazione_mov_gest.movgest_ts_id=ts_movimenti.movgest_ts_id
       and r_capitolo_movimento.movgest_id = ts_movimenti.movgest_id
       and bil_elem.elem_id = r_capitolo_movimento.elem_id
       and t_ente_prop.ente_proprietario_id = bil_elem.ente_proprietario_id
       and r_liqu_ord.ente_proprietario_id = p_ente_prop_id 
       and ordinativo.bil_id = bilancio_id                   
       and tipo_ordinativo.ord_tipo_code  =  'P'  ------ PAGATO
       and d_ord_ts_det_tipo.ord_ts_det_tipo_code='A'
       -- ord_trasm_oil_data e' la data quietanza
       and (ordinativo.ord_trasm_oil_data is not null AND
       		ordinativo.ord_trasm_oil_data between data_inizio_anno and p_periodo_al)
      -- and liquidazione.liq_emissione_data between data_inizio_anno and p_periodo_al             			
		and now() between ordinativo.validita_inizio and coalesce (ordinativo.validita_fine, now())
		and now() between r_liqu_ord.validita_inizio and coalesce (r_liqu_ord.validita_fine, now())
		and now() between ts_ordinativo.validita_inizio and coalesce (ts_ordinativo.validita_fine, now())       
        and now() between tipo_ordinativo.validita_inizio and coalesce (tipo_ordinativo.validita_fine, now()) 
        and now() between liquidazione_mov_gest.validita_inizio and coalesce (liquidazione_mov_gest.validita_fine, now()) 
        and now() between ts_movimenti.validita_inizio and coalesce (ts_movimenti.validita_fine, now()) 
        and now() between r_capitolo_movimento.validita_inizio and coalesce (r_capitolo_movimento.validita_fine, now()) 
        and now() between bil_elem.validita_inizio and coalesce (bil_elem.validita_fine, now()) 
        and now() between soggetto.validita_inizio and coalesce (soggetto.validita_fine, now()) 
        and now() between r_soggetto_liquid.validita_inizio and coalesce (r_soggetto_liquid.validita_fine, now()) 
        and now() between liquidazione.validita_inizio and coalesce (liquidazione.validita_fine, now())            
        and liquidazione.data_cancellazione IS NULL
       -- and r_soggetto_liquid.data_cancellazione IS NULL
       -- and soggetto.data_cancellazione IS NULL
        and r_liqu_ord.data_cancellazione IS NULL 
        and ordinativo.data_cancellazione IS NULL
        and ts_ordinativo.data_cancellazione IS NULL
        and t_ente_prop.data_cancellazione IS NULL
        and r_capitolo_movimento.data_cancellazione IS NULL
        and bil_elem.data_cancellazione IS NULL ),
classific as  (select r_capitolo_class.elem_id, classificazioni.classif_code
             from  siac_r_bil_elem_class r_capitolo_class,
                      siac_t_class classificazioni,
                      siac_d_class_tipo         tipo_classif
             where classificazioni.classif_id = r_capitolo_class.classif_id
                  and tipo_classif.classif_tipo_id = classificazioni.classif_tipo_id
                  and tipo_classif.classif_tipo_code='TIPO_FINANZIAMENTO'
                  --and  classificazioni.classif_code in ('MB','MU')
                  and r_capitolo_class.ente_proprietario_id =p_ente_prop_id
                  and classificazioni.data_cancellazione IS NULL
                  and r_capitolo_class.data_cancellazione IS NULL
                  and tipo_classif.data_cancellazione IS NULL) 
select      
  dati_pagamenti.anno_quietanza::varchar anno_quietanza,
  dati_pagamenti.data_quietanza::date data_quietanza,
  COALESCE(dati_pagamenti.importo_quietanza,0)::numeric importo_quietanza,
  COALESCE(dati_pagamenti.ord_quietanza_numero,0)::numeric numero_quietanza,
  dati_pagamenti.anno_ord::integer anno_ord,
  dati_pagamenti.numero_ord::numeric numero_ord,
  dati_pagamenti.quota::varchar quota,
  classific.classif_code::varchar tipo_finanziamento,
  dati_pagamenti.creditore::varchar creditore,
  dati_pagamenti.codice_creditore::varchar codice_creditore,
  dati_pagamenti.causale::varchar causale,
  flag_mutui_mezzi::varchar exist_mutui_mezzi,
  dati_pagamenti.ente_denominazione::varchar desc_ente   
from dati_pagamenti
	left join classific          
       		on (classific.elem_id=dati_pagamenti.elem_id)  
order by dati_pagamenti.data_quietanza, dati_pagamenti.numero_ord, dati_pagamenti.quota;     

raise notice 'fine OK';
    exception
    when no_data_found THEN
    raise notice 'nessun dato trovato per giornaliera pagamenti';
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

--SIAC-7090 - Maurizio - FINE

--SIAC-6985 - Maurizio - INIZIO

drop view if exists siac_v_dwh_inventario_cespiti;

create or replace view siac.siac_v_dwh_inventario_cespiti as
with cespiti as (
select t_cespiti.ente_proprietario_id,
	t_cespiti.ces_id,
	t_cespiti.ces_code code_scheda_cespite, 
    t_cespiti.ces_desc desc_scheda_cespite,
	d_cespiti_bene_tipo.ces_bene_tipo_code code_tipo_bene,
    d_cespiti_bene_tipo.ces_bene_tipo_desc desc_tipo_bene,
    d_cespiti_categ.cescat_code code_cespite_categ, 
    d_cespiti_categ.cescat_desc desc_cespite_categ,
    r_cespiti_categ_calcolo.aliquota_annua perc_ammortamento,
    d_cespiti_categ_calcolo.cescat_calcolo_tipo_code code_tipo_calcolo, 
    d_cespiti_categ_calcolo.cescat_calcolo_tipo_desc desc_tipo_calcolo,
    COALESCE(r_cespiti_bene_tipo.pdce_conto_patrimoniale_code, '') code_conto_patrimoniale,
    COALESCE(r_cespiti_bene_tipo.pdce_conto_patrimoniale_desc, '') desc_conto_patrimoniale,
    COALESCE(d_cespiti_bene_tipo.pdce_conto_ammortamento_code, '') code_conto_ammortamento,
    COALESCE(d_cespiti_bene_tipo.pdce_conto_ammortamento_desc, '') desc_conto_ammortamento,
    COALESCE(d_cespiti_bene_tipo.evento_ammortamento_code, '') code_evento_ammortamento,
    COALESCE(d_cespiti_bene_tipo.evento_ammortamento_desc, '') desc_evento_ammortamento,
    COALESCE(d_cespiti_bene_tipo.pdce_conto_fondo_ammortamento_code, '') code_conto_fondo_ammortamento,
    COALESCE(d_cespiti_bene_tipo.pdce_conto_fondo_ammortamento_desc, '') desc_conto_fondo_ammortamento,
    COALESCE(d_cespiti_bene_tipo.pdce_conto_plusvalenza_code,'') code_conto_plusvalenza_alienazione,
  	COALESCE(d_cespiti_bene_tipo.pdce_conto_plusvalenza_desc, '') desc_conto_plusvalenza_alienazione,
    COALESCE(d_cespiti_bene_tipo.pdce_conto_minusvalenza_code,'') code_conto_minusvalenza_alienazione,
  	COALESCE(d_cespiti_bene_tipo.pdce_conto_minusvalenza_desc, '') desc_conto_minusvalenza_alienazione,
	COALESCE(d_cespiti_bene_tipo.pdce_conto_incremento_code,'') code_conto_incremento_valore,
  	COALESCE(d_cespiti_bene_tipo.pdce_conto_incremento_desc, '') desc_conto_incremento_valore,
    COALESCE(d_cespiti_bene_tipo.evento_incremento_code,'') code_evento_incremento_valore,
  	COALESCE(d_cespiti_bene_tipo.evento_incremento_desc, '') desc_evento_incremento_valore,
    COALESCE(d_cespiti_bene_tipo.pdce_conto_decremento_code,'') code_conto_decremento_valore,
  	COALESCE(d_cespiti_bene_tipo.pdce_conto_decremento_desc, '') desc_conto_decremento_valore,
    COALESCE(d_cespiti_bene_tipo.evento_decremento_code,'') code_evento_decremento_valore,
  	COALESCE(d_cespiti_bene_tipo.evento_decremento_desc, '') desc_evento_decremento_valore,
    COALESCE(d_cespiti_bene_tipo.pdce_conto_alienazione_code,'') code_conto_credito_alienazione,
  	COALESCE(d_cespiti_bene_tipo.pdce_conto_alienazione_desc, '') desc_conto_credito_alienazione,
    COALESCE(d_cespiti_bene_tipo.pdce_conto_donazione_code,'') code_conto_donazione_rinvenimento,
  	COALESCE(d_cespiti_bene_tipo.pdce_conto_donazione_desc, '') desc_conto_donazione_rinvenimento,
    d_cespiti_class_giuri.ces_class_giu_code code_classificazione_giuridica,
    d_cespiti_class_giuri.ces_class_giu_desc desc_classificazione_giuridica,
    case when t_cespiti.soggetto_beni_culturali = true then 'SI' else 'NO' end soggetto_beni_culturali,
    case when t_cespiti.flg_donazione_rinvenimento = true then 'SI' else 'NO' end donazione_rinvenimento,
    t_cespiti.num_inventario numero_inventario,
    t_cespiti.data_ingresso_inventario data_ingresso_inventario,
    t_cespiti.valore_iniziale,
    t_cespiti.descrizione_stato,
    t_cespiti.ubicazione,
    case when t_cespiti.flg_stato_bene = true then 'SI' else 'NO' end attivo,
    t_cespiti.ces_dismissioni_id,
    case when t_cespiti.flg_donazione_rinvenimento = true then 
    	t_cespiti.valore_attuale else 0 end importo_donazione
from siac_t_cespiti t_cespiti,		
	siac_d_cespiti_bene_tipo d_cespiti_bene_tipo,
    siac_r_cespiti_bene_tipo_conto_patr_cat r_cespiti_bene_tipo,
    siac_d_cespiti_categoria d_cespiti_categ,
    siac_r_cespiti_categoria_aliquota_calcolo_tipo r_cespiti_categ_calcolo,
    siac_d_cespiti_categoria_calcolo_tipo d_cespiti_categ_calcolo,
    siac_d_cespiti_classificazione_giuridica d_cespiti_class_giuri       
where t_cespiti.ces_bene_tipo_id=d_cespiti_bene_tipo.ces_bene_tipo_id
	and r_cespiti_bene_tipo.ces_bene_tipo_id=d_cespiti_bene_tipo.ces_bene_tipo_id    
	and d_cespiti_categ.cescat_id=r_cespiti_bene_tipo.cescat_id
    and r_cespiti_categ_calcolo.cescat_id=d_cespiti_categ.cescat_id
    and d_cespiti_categ_calcolo.cescat_calcolo_tipo_id=r_cespiti_categ_calcolo.cescat_calcolo_tipo_id
    and d_cespiti_class_giuri.ces_class_giu_id= t_cespiti.ces_class_giu_id
	and t_cespiti.data_cancellazione IS NULL
    and t_cespiti.validita_fine IS NULL 
	and d_cespiti_bene_tipo.data_cancellazione IS NULL
    and d_cespiti_bene_tipo.validita_fine IS NULL  
    and r_cespiti_bene_tipo.data_cancellazione IS NULL
    and r_cespiti_bene_tipo.validita_fine IS NULL 
	and d_cespiti_categ.data_cancellazione IS NULL
    and d_cespiti_categ.validita_fine IS NULL   
    and d_cespiti_bene_tipo.validita_fine IS NULL  
    and r_cespiti_categ_calcolo.data_cancellazione IS NULL
    and r_cespiti_categ_calcolo.validita_fine IS NULL 
	and d_cespiti_categ_calcolo.data_cancellazione IS NULL
    and d_cespiti_categ_calcolo.validita_fine IS NULL 
    and d_cespiti_class_giuri.data_cancellazione IS NULL
    and d_cespiti_class_giuri.validita_fine IS NULL),
documenti as (select r_cesp_mov_ep_det.ente_proprietario_id,
				 r_cesp_mov_ep_det.ces_id, t_doc.doc_id, t_doc.doc_anno, t_doc.doc_numero, 
				t_subdoc.subdoc_id, t_subdoc.subdoc_numero, t_subdoc.subdoc_importo,
                t_class.classif_code pdce_conto_code, t_class.classif_desc pdce_conto_desc,
                t_reg_movfin.classif_id_aggiornato, t_reg_movfin.pdce_conto_id,
                t_soggetto.soggetto_id, t_soggetto.soggetto_code,
                t_soggetto.soggetto_desc, t_doc.doc_data_emissione,
                d_doc_tipo.doc_tipo_code, d_doc_tipo.doc_tipo_desc,
                d_doc_fam_tipo.doc_fam_tipo_code, d_doc_fam_tipo.doc_fam_tipo_desc
              from siac_r_cespiti_mov_ep_det r_cesp_mov_ep_det,
                siac_t_mov_ep_det t_mov_ep_det,
                siac_t_mov_ep t_mov_ep,
                siac_t_reg_movfin t_reg_movfin
                	LEFT JOIN siac_t_class t_class
                    	ON (t_class.classif_id = t_reg_movfin.classif_id_aggiornato
                        	and t_class.ente_proprietario_id = t_reg_movfin.ente_proprietario_id
                            and t_class.data_cancellazione IS NULL
                            and t_class.validita_fine IS NULL),
                siac_r_evento_reg_movfin r_evento_reg_movfin ,
                siac_t_subdoc t_subdoc,
                siac_t_doc t_doc,
                siac_t_soggetto t_soggetto,
                siac_r_doc_sog r_doc_sog,
                siac_d_doc_tipo d_doc_tipo,
                siac_d_doc_fam_tipo d_doc_fam_tipo
              where r_cesp_mov_ep_det.movep_det_id=t_mov_ep_det.movep_det_id
                and t_mov_ep_det.movep_id=t_mov_ep.movep_id
                and t_mov_ep.regmovfin_id=t_reg_movfin.regmovfin_id
                and t_reg_movfin.regmovfin_id=r_evento_reg_movfin.regmovfin_id
                and (r_evento_reg_movfin.campo_pk_id=t_subdoc.subdoc_id or r_evento_reg_movfin.campo_pk_id=t_doc.doc_id)
                and t_doc.doc_id=t_subdoc.doc_id
                and t_mov_ep.ambito_id=t_reg_movfin.ambito_id
                and r_doc_sog.doc_id = t_doc.doc_id
                and r_doc_sog.soggetto_id = t_soggetto.soggetto_id
                and t_doc.doc_tipo_id= d_doc_tipo.doc_tipo_id
                and d_doc_tipo.doc_fam_tipo_id = d_doc_fam_tipo.doc_fam_tipo_id
                and r_cesp_mov_ep_det.data_cancellazione IS NULL
                and r_cesp_mov_ep_det.validita_fine IS NULL
                and t_mov_ep_det.data_cancellazione IS NULL
                and t_mov_ep_det.validita_fine IS NULL
                and t_mov_ep.data_cancellazione IS NULL
                and t_mov_ep.validita_fine IS NULL
                and t_reg_movfin.data_cancellazione IS NULL
                and t_reg_movfin.validita_fine IS NULL
                and r_evento_reg_movfin.data_cancellazione IS NULL
                and r_evento_reg_movfin.validita_fine IS NULL
                and t_subdoc.data_cancellazione IS NULL
                and t_subdoc.validita_fine IS NULL
                and t_doc.data_cancellazione IS NULL
                and t_doc.validita_fine IS NULL
                and t_soggetto.data_cancellazione IS NULL
                and t_soggetto.validita_fine IS NULL
                and r_doc_sog.data_cancellazione IS NULL
                and r_doc_sog.validita_fine IS NULL
                and d_doc_tipo.data_cancellazione IS NULL
                and d_doc_tipo.validita_fine IS NULL
                and d_doc_fam_tipo.data_cancellazione IS NULL
                and d_doc_fam_tipo.validita_fine IS NULL),    
		impegni as (select t_movgest_ts.movgest_ts_id, t_movgest.movgest_anno, 
        				t_movgest.movgest_numero,
        				t_movgest_ts.movgest_ts_code, t_movgest_ts_det.movgest_ts_det_importo,
                        r_subdoc_movgest_ts.subdoc_id, t_movgest.ente_proprietario_id, 
                        t_soggetto.soggetto_code, t_soggetto.soggetto_desc,
                        t_soggetto.soggetto_id, d_movgest_ts_tipo.movgest_ts_tipo_code,
                        importi_imp.importo_impegno
                    from  siac_t_movgest t_movgest
                    	LEFT JOIN (select  a.movgest_id, a.ente_proprietario_id, e.movgest_ts_det_importo importo_impegno
                                    from siac_t_movgest a,
                                        siac_t_movgest_ts b,
                                        siac_d_movgest_tipo c,
                                        siac_d_movgest_ts_tipo d,
                                        siac_t_movgest_ts_det e,
                                        siac_d_movgest_ts_det_tipo f
                                    where a.movgest_id=b.movgest_id
                                        and a.movgest_tipo_id=c.movgest_tipo_id
                                        and b.movgest_ts_tipo_id=d.movgest_ts_tipo_id
                                        and b.movgest_ts_id=e.movgest_ts_id
                                        and e.movgest_ts_det_tipo_id=f.movgest_ts_det_tipo_id
                                        and c.movgest_tipo_code='I'
                                        and d.movgest_ts_tipo_code='T'
                                        and f.movgest_ts_det_tipo_code='A'
                                        and a.data_cancellazione IS NULL
                                        and a.validita_fine IS NULL
                                        and b.data_cancellazione IS NULL
                                        and b.validita_fine IS NULL
                                        and c.data_cancellazione IS NULL
                                        and c.validita_fine IS NULL  
                                        and d.data_cancellazione IS NULL
                                        and d.validita_fine IS NULL
                                        and e.data_cancellazione IS NULL
                                        and e.validita_fine IS NULL
                                        and f.data_cancellazione IS NULL
                                        and f.validita_fine IS NULL) importi_imp
                              ON (importi_imp.movgest_id=t_movgest.movgest_id
                              		and importi_imp.ente_proprietario_id=t_movgest.ente_proprietario_id),
                      siac_t_movgest_ts t_movgest_ts,        
                      siac_d_movgest_ts_tipo d_movgest_ts_tipo,             	
                      siac_t_movgest_ts_det t_movgest_ts_det,
                      siac_d_movgest_ts_det_tipo d_movgest_ts_det_tipo,
                      siac_r_subdoc_movgest_ts r_subdoc_movgest_ts,
                      siac_d_movgest_tipo d_movgest_tipo,
                      siac_r_movgest_ts_sog r_movgest_ts_sogg,
                      siac_t_soggetto t_soggetto
                    where t_movgest.movgest_id =  t_movgest_ts.movgest_id
                    	and d_movgest_ts_tipo.movgest_ts_tipo_id=t_movgest_ts.movgest_ts_tipo_id
                    	and t_movgest_ts_det.movgest_ts_id=t_movgest_ts.movgest_ts_id
                        and d_movgest_ts_det_tipo.movgest_ts_det_tipo_id=t_movgest_ts_det.movgest_ts_det_tipo_id
                    	and t_movgest_ts.movgest_ts_id = r_subdoc_movgest_ts.movgest_ts_id 
                        and d_movgest_tipo.movgest_tipo_id = t_movgest.movgest_tipo_id
                        and r_movgest_ts_sogg.movgest_ts_id = t_movgest_ts.movgest_ts_id
                        and r_movgest_ts_sogg.soggetto_id = t_soggetto.soggetto_id
                        and d_movgest_ts_det_tipo.movgest_ts_det_tipo_code= 'A' -- Importo Attuale                       
                        and d_movgest_tipo.movgest_tipo_code= 'I'
                        and t_movgest.data_cancellazione IS NULL
                        and t_movgest.validita_fine IS NULL
                        and t_movgest_ts.data_cancellazione IS NULL
                        and t_movgest_ts.validita_fine IS NULL
                        and d_movgest_ts_tipo.data_cancellazione IS NULL
                        and d_movgest_ts_tipo.validita_fine IS NULL
                        and t_movgest_ts_det.data_cancellazione IS NULL
                        and t_movgest_ts.validita_fine IS NULL
                        and d_movgest_ts_det_tipo.data_cancellazione IS NULL
                        and d_movgest_ts_det_tipo.validita_fine IS NULL
                        and r_subdoc_movgest_ts.data_cancellazione IS NULL
                        and r_subdoc_movgest_ts.validita_fine IS NULL
                        and r_movgest_ts_sogg.data_cancellazione IS NULL
                        and r_movgest_ts_sogg.validita_fine IS NULL
                        and t_soggetto.data_cancellazione IS NULL
                        and t_soggetto.validita_fine IS NULL),   
         liquidazioni as (select t_liq.liq_id, t_liq.ente_proprietario_id,
         				t_liq.liq_anno, t_liq.liq_numero, t_liq.liq_importo,
                        r_subdoc_liq.subdoc_id, t_soggetto.soggetto_code,
                        t_soggetto.soggetto_desc, t_soggetto.soggetto_id
         			from siac_r_subdoc_liquidazione r_subdoc_liq,
                    	siac_t_liquidazione t_liq,
                        siac_r_liquidazione_soggetto r_liq_sogg,
                        siac_t_soggetto t_soggetto
                    where r_subdoc_liq.liq_id = t_liq.liq_id
                    	and t_liq.liq_id = r_liq_sogg.liq_id
                    	and r_liq_sogg.soggetto_id= t_soggetto.soggetto_id
                    	and r_subdoc_liq.data_cancellazione IS NULL
                        and r_subdoc_liq.validita_fine IS NULL
                        and t_liq.data_cancellazione IS NULL
                        and t_liq.validita_fine IS NULL
                        and r_liq_sogg.data_cancellazione IS NULL
                        and r_liq_sogg.validita_fine IS NULL
                        and t_soggetto.data_cancellazione IS NULL
                        and t_soggetto.validita_fine IS NULL),
         dismissioni as (select t_cespiti_dism.ces_dismissioni_id,
         				 t_cespiti_dism.ente_proprietario_id,
                         t_cespiti_dism.data_cessazione, 
                         t_atto_amm.attoamm_anno, t_atto_amm.attoamm_numero,
                         d_atto_amm_tipo.attoamm_tipo_code, d_atto_amm_tipo.attoamm_tipo_desc
         			from siac_t_cespiti_dismissioni t_cespiti_dism,
                    		siac_t_atto_amm t_atto_amm,
                            siac_d_atto_amm_tipo d_atto_amm_tipo
        			where t_cespiti_dism.attoamm_id= t_atto_amm.attoamm_id
                    	and d_atto_amm_tipo.attoamm_tipo_id = t_atto_amm.attoamm_tipo_id
                        and t_cespiti_dism.data_cancellazione IS NULL
    					and t_cespiti_dism.validita_fine IS NULL
                        and t_atto_amm.data_cancellazione IS NULL
    					and t_atto_amm.validita_fine IS NULL 
                        and d_atto_amm_tipo.data_cancellazione IS NULL
    					and d_atto_amm_tipo.validita_fine IS NULL),   
         cespiti_rivalutazioni as (select t_cespiti_var.ces_id, 
                                  t_cespiti_var.ente_proprietario_id,
                                  sum(ces_var_importo)  importo_rivalutazione        
                  from siac_t_cespiti_variazione t_cespiti_var,
                      siac_d_cespiti_variazione_stato d_cespiti_var_stato
                  where t_cespiti_var.ces_var_stato_id=d_cespiti_var_stato.ces_var_stato_id
                      and d_cespiti_var_stato.ces_var_stato_code <>'A'
                      and t_cespiti_var.flg_tipo_variazione_incr = true 
                      and t_cespiti_var.data_cancellazione IS NULL
                      and t_cespiti_var.validita_fine IS NULL
                      and d_cespiti_var_stato.data_cancellazione IS NULL
                      and d_cespiti_var_stato.validita_fine IS NULL
                  group by t_cespiti_var.ces_id , t_cespiti_var.ente_proprietario_id),   
		cespiti_svalutazioni as (select t_cespiti_var.ces_id, 
        					t_cespiti_var.ente_proprietario_id,
                          sum(ces_var_importo)  importo_svalutazione        
                  from siac_t_cespiti_variazione t_cespiti_var,
                      siac_d_cespiti_variazione_stato d_cespiti_var_stato
                  where t_cespiti_var.ces_var_stato_id=d_cespiti_var_stato.ces_var_stato_id
                      and d_cespiti_var_stato.ces_var_stato_code <>'A'
                      and t_cespiti_var.flg_tipo_variazione_incr = false
                      and t_cespiti_var.data_cancellazione IS NULL
                      and t_cespiti_var.validita_fine IS NULL
                      and d_cespiti_var_stato.data_cancellazione IS NULL
                      and d_cespiti_var_stato.validita_fine IS NULL
                  group by t_cespiti_var.ces_id, t_cespiti_var.ente_proprietario_id ), 
		dati_ammortamento as ( select t_cespiti_ammort.ces_id, t_cespiti_ammort.ente_proprietario_id,
        						t_cespiti_ammort_dett.ces_amm_dett_id,
                                t_cespiti_ammort.ces_amm_ultimo_anno_reg, 
                                t_cespiti_ammort.ces_amm_importo_tot_reg,
                                t_cespiti_ammort_dett.ces_amm_dett_anno,
                                t_cespiti_ammort_dett.ces_amm_dett_importo,
                                t_cespiti_ammort_dett.ces_amm_dett_data,
                                t_cespiti_ammort_dett.pnota_id,
                                t_cespiti_ammort_dett.num_reg_def_ammortamento
        					from siac_t_cespiti_ammortamento t_cespiti_ammort,
                        		siac_t_cespiti_ammortamento_dett t_cespiti_ammort_dett
                       		where t_cespiti_ammort.ces_amm_id= t_cespiti_ammort_dett.ces_amm_id
                            	and t_cespiti_ammort.data_cancellazione IS NULL
                                and t_cespiti_ammort.validita_fine IS NULL
                                and t_cespiti_ammort_dett.data_cancellazione IS NULL
                                and t_cespiti_ammort_dett.validita_fine IS NULL),
		dismissioni_importo as (select t_cespiti_dismis.ces_dismissioni_id,
                        t_mov_ep_det.movep_det_importo, t_cespiti_dismis.ente_proprietario_id
                    from siac_t_cespiti t_cesp,
                        siac_t_cespiti_dismissioni t_cespiti_dismis,
                        siac_r_cespiti_dismissioni_prima_nota r_cesp_dismi_prima_nota,
                        siac_t_prima_nota t_prima_nota,
                        siac_t_mov_ep t_mov_ep,
                        siac_t_mov_ep_det t_mov_ep_det,
                        siac_r_evento_causale r_ev_causale,
                        siac_d_evento d_evento,
                        siac_t_cespiti_ammortamento_dett  t_cesp_ammort_dett
                    where t_cesp.ces_dismissioni_id=t_cespiti_dismis.ces_dismissioni_id
                        and t_cespiti_dismis.ces_dismissioni_id= r_cesp_dismi_prima_nota.ces_dismissioni_id
                        and r_cesp_dismi_prima_nota.pnota_id= t_prima_nota.pnota_id
                        and t_prima_nota.pnota_id=t_mov_ep.regep_id       
                        and t_mov_ep_det.movep_id=t_mov_ep.movep_id
                        and r_ev_causale.causale_ep_id=t_mov_ep.causale_ep_id
                        and d_evento.evento_id=r_ev_causale.evento_id
                        and t_cesp_ammort_dett.ces_amm_dett_id=r_cesp_dismi_prima_nota.ces_amm_dett_id
                        and d_evento.evento_code='DIS'
                        and t_mov_ep_det.movep_det_segno='Dare'
                        and t_mov_ep_det.movep_det_id in(select max(a.movep_det_id)
                                        from siac_t_mov_ep_det a
                                        where a.movep_id=t_mov_ep_det.movep_id
                                            and a.data_cancellazione IS NULL
                                            and a.validita_fine IS NULL)
                        and t_cesp.data_cancellazione IS NULL
                        and t_cesp.validita_fine IS NULL 
                        and t_cespiti_dismis.data_cancellazione IS NULL
                        and t_cespiti_dismis.validita_fine IS NULL 
                        and r_cesp_dismi_prima_nota.data_cancellazione IS NULL
                        and r_cesp_dismi_prima_nota.validita_fine IS NULL 
                        and t_prima_nota.data_cancellazione IS NULL
                        and t_prima_nota.validita_fine IS NULL 
                        and t_mov_ep.data_cancellazione IS NULL
                        and t_mov_ep.validita_fine IS NULL 
                        and t_mov_ep_det.data_cancellazione IS NULL
                        and t_mov_ep_det.validita_fine IS NULL      
                        and r_ev_causale.data_cancellazione IS NULL
                        and r_ev_causale.validita_fine IS NULL  
                        and d_evento.data_cancellazione IS NULL
                        and d_evento.validita_fine IS NULL       
                        and t_cesp_ammort_dett.data_cancellazione IS NULL
                        and t_cesp_ammort_dett.validita_fine IS NULL )                                                                                                                          
select cespiti.ente_proprietario_id::INTEGER, 
	cespiti.ces_id::INTEGER, 
	cespiti.code_scheda_cespite::VARCHAR(200),
    cespiti.desc_scheda_cespite::VARCHAR(500),
    cespiti.code_tipo_bene::VARCHAR(200),
    cespiti.desc_tipo_bene::VARCHAR(500),
    cespiti.code_cespite_categ::VARCHAR(200),
    cespiti.desc_cespite_categ::VARCHAR(500),
    cespiti.perc_ammortamento::NUMERIC,
    cespiti.code_tipo_calcolo::VARCHAR(200),
    cespiti.desc_tipo_calcolo::VARCHAR(500),
    cespiti.code_conto_patrimoniale::VARCHAR(200),
    cespiti.desc_conto_patrimoniale::VARCHAR(500),
    cespiti.code_conto_ammortamento::VARCHAR(200),
    cespiti.desc_conto_ammortamento::VARCHAR(500),
    cespiti.code_evento_ammortamento::VARCHAR(200),
    cespiti.desc_evento_ammortamento::VARCHAR(500),
    cespiti.code_conto_fondo_ammortamento::VARCHAR(200),
    cespiti.desc_conto_fondo_ammortamento::VARCHAR(500),
    cespiti.code_conto_plusvalenza_alienazione::VARCHAR(200) code_conto_plusvalenza_alien,
    cespiti.desc_conto_plusvalenza_alienazione::VARCHAR(500) desc_conto_plusvalenza_alien,
    cespiti.code_conto_minusvalenza_alienazione::VARCHAR(200) code_conto_minusvalenza_alien,
    cespiti.desc_conto_minusvalenza_alienazione::VARCHAR(500) desc_conto_minusvalenza_alien,
    cespiti.code_conto_incremento_valore::VARCHAR(200),
    cespiti.desc_conto_incremento_valore::VARCHAR(500),
    cespiti.code_evento_incremento_valore::VARCHAR(200),
    cespiti.desc_evento_incremento_valore::VARCHAR(500),
    cespiti.code_conto_decremento_valore::VARCHAR(200),
    cespiti.desc_conto_decremento_valore::VARCHAR(500),
    cespiti.code_evento_decremento_valore::VARCHAR(200),
    cespiti.desc_evento_decremento_valore::VARCHAR(500),
    cespiti.code_conto_credito_alienazione::VARCHAR(200) code_conto_credito_alien,
    cespiti.desc_conto_credito_alienazione::VARCHAR(500) desc_conto_credito_alien,
    cespiti.code_conto_donazione_rinvenimento::VARCHAR(200) code_conto_donazione_rinven,
    cespiti.desc_conto_donazione_rinvenimento::VARCHAR(500) desc_conto_donazione_rinven,
    cespiti.code_classificazione_giuridica::VARCHAR(200) code_classificazione_giurid,
    cespiti.desc_classificazione_giuridica::VARCHAR(500) desc_classificazione_giurid,
    cespiti.soggetto_beni_culturali::VARCHAR(2),
    cespiti.donazione_rinvenimento::VARCHAR(2),
    cespiti.numero_inventario::VARCHAR(10),
    cespiti.data_ingresso_inventario::TIMESTAMP,
    cespiti.valore_iniziale::NUMERIC,
    documenti.doc_id::INTEGER id_fattura,
    documenti.doc_anno::INTEGER anno_fattura,
    COALESCE(documenti.doc_numero, '')::VARCHAR(200) numero_fattura,
    documenti.soggetto_id::INTEGER soggetto_id_fattura, 
    COALESCE(documenti.soggetto_code, '')::VARCHAR(200) code_soggetto_fattura,
    COALESCE(documenti.soggetto_desc, '')::VARCHAR(500) desc_soggetto_fattura,
    COALESCE(documenti.doc_tipo_code, '')::VARCHAR(200) code_tipo_fattura,
    COALESCE(documenti.doc_fam_tipo_code, '')::VARCHAR(200) code_tipo_fam_fattura,
    documenti.doc_data_emissione::TIMESTAMP data_fattura,
    documenti.subdoc_numero::INTEGER numero_quota,
    documenti.subdoc_importo::NUMERIC importo_quota,
    impegni.movgest_anno::INTEGER anno_impegno, 
    impegni.movgest_numero::NUMERIC numero_impegno,
    --impegni.movgest_ts_tipo_code::VARCHAR tipo_impegno,
    impegni.importo_impegno::NUMERIC importo_impegno,
    COALESCE(impegni.movgest_ts_code, '')::VARCHAR(200) numero_subimpegno,    
    impegni.movgest_ts_det_importo::NUMERIC importo_subimpegno,
    impegni.soggetto_id::INTEGER soggetto_id_impegno,
    COALESCE(impegni.soggetto_code, '')::VARCHAR(200) code_soggetto_impegno,
    COALESCE(impegni.soggetto_desc, '')::VARCHAR(500) desc_soggetto_impegno,
    COALESCE(documenti.pdce_conto_code, '')::VARCHAR(200) code_pdce_finanziario,
    COALESCE(documenti.pdce_conto_desc, '')::VARCHAR(500) desc_pdce_finanziario,
    liquidazioni.liq_anno::INTEGER anno_liquidazione,
    liquidazioni.liq_numero::NUMERIC numero_liquidazione,
    liquidazioni.liq_importo::NUMERIC importo_liquidazione,
    liquidazioni.soggetto_id::INTEGER soggetto_id_liquidazione,
    COALESCE(liquidazioni.soggetto_code, '')::VARCHAR(200) code_soggetto_liquidazione,
    COALESCE(liquidazioni.soggetto_desc, '')::VARCHAR(500) desc_soggetto_liquidazione,
    cespiti.attivo::VARCHAR(2),
    cespiti.descrizione_stato::VARCHAR(200),
    cespiti.ubicazione::VARCHAR(2000),
    dati_ammortamento.ces_amm_dett_anno::INTEGER anno_ammortamento_massivo,
    dati_ammortamento.ces_amm_dett_data::TIMESTAMP data_ammortamento_massivo,
    dati_ammortamento.ces_amm_dett_importo::NUMERIC importo_ammortamento_massivo,
    -- i dati dell'ammortamento annuo sono gli stessi dell'ammortamento massivo ma solo
 	-- se e' stata creata la prima nota o e e' valorizzato num_reg_def_ammortamento.
    case when (dati_ammortamento.pnota_id IS NOT NULL OR
               dati_ammortamento.num_reg_def_ammortamento IS NOT NULL) then               
		dati_ammortamento.ces_amm_dett_anno::INTEGER else NULL end anno_ammortamento_annuo,
     case when (dati_ammortamento.pnota_id IS NOT NULL OR
               dati_ammortamento.num_reg_def_ammortamento IS NOT NULL) then               
    	dati_ammortamento.ces_amm_dett_importo::NUMERIC else NULL end importo_ammortamento_annuo,
    dismissioni.data_cessazione::TIMESTAMP data_cessazione_dismis,
    dismissioni.attoamm_anno::VARCHAR(200) anno_provvedimento_dismis,
    dismissioni.attoamm_numero::INTEGER numero_provvedimento_dismis,
    dismissioni.attoamm_tipo_desc::VARCHAR(500) tipo_provvedimento_dismis,
    COALESCE(dismissioni_importo.movep_det_importo,0)::NUMERIC importo_dismis,
    cespiti_rivalutazioni.importo_rivalutazione::NUMERIC importo_rivalutazione,
    cespiti_svalutazioni.importo_svalutazione::NUMERIC importo_svalutazione,
    cespiti.importo_donazione::NUMERIC
from cespiti     
	LEFT JOIN documenti
    	ON (documenti.ces_id=cespiti.ces_id and
        	documenti.ente_proprietario_id=cespiti.ente_proprietario_id)
    LEFT JOIN impegni
    	ON (impegni.subdoc_id = documenti.subdoc_id and
        	impegni.ente_proprietario_id=documenti.ente_proprietario_id)
    LEFT JOIN liquidazioni
    	ON (liquidazioni.subdoc_id = documenti.subdoc_id and
        	liquidazioni.ente_proprietario_id=documenti.ente_proprietario_id)  
    LEFT JOIN dismissioni
    	ON (dismissioni.ces_dismissioni_id = cespiti.ces_dismissioni_id and
        	dismissioni.ente_proprietario_id=cespiti.ente_proprietario_id)              
    LEFT JOIN cespiti_rivalutazioni
    	ON (cespiti_rivalutazioni.ces_id = cespiti.ces_id and
        	cespiti_rivalutazioni.ente_proprietario_id=cespiti.ente_proprietario_id)                                   
    LEFT JOIN cespiti_svalutazioni
    	ON (cespiti_svalutazioni.ces_id = cespiti.ces_id and
        	cespiti_svalutazioni.ente_proprietario_id=cespiti.ente_proprietario_id)      
    LEFT JOIN dati_ammortamento
    	ON (dati_ammortamento.ces_id = cespiti.ces_id and
        	dati_ammortamento.ente_proprietario_id=cespiti.ente_proprietario_id) 
    LEFT JOIN dismissioni_importo
    	ON (dismissioni_importo.ces_dismissioni_id = dismissioni.ces_dismissioni_id and
        	dismissioni_importo.ente_proprietario_id=dismissioni.ente_proprietario_id)                                                                            
order by cespiti.ente_proprietario_id, cespiti.code_scheda_cespite;

--SIAC-6985 - Maurizio - FINE



-- SIAC-SIAC-7089 - Sofia - 14.10.2019 - inizio 

drop function if exists fnc_pagopa_t_elaborazione_riconc_esegui
(
  filePagoPaElabId                integer,
  annoBilancioElab                integer,
  enteProprietarioId              integer,
  loginOperazione                 varchar,
  dataElaborazione                timestamp,
  out codicerisultato             integer,
  out messaggiorisultato          varchar
);

CREATE OR REPLACE FUNCTION fnc_pagopa_t_elaborazione_riconc_esegui
(
  filePagoPaElabId                integer,
  annoBilancioElab                integer,
  enteProprietarioId              integer,
  loginOperazione                 varchar,
  dataElaborazione                timestamp,
  out codicerisultato             integer,
  out messaggiorisultato          varchar
)
RETURNS record AS
$body$
DECLARE

	strMessaggio VARCHAR(2500):=''; -- 09.10.2019 Sofia
	strMessaggioBck VARCHAR(2500):=''; -- 09.10.2019 Sofia
    strMessaggioLog VARCHAR(2500):='';

	strMessaggioFinale VARCHAR(1500):='';
    strErrore  VARCHAR(1500):='';
    pagoPaCodeErr varchar(50):='';
	codResult integer:=null;
    codResult1 integer:=null;
    docid integer:=null;
    subDocId integer:=null;
    nProgressivo integer=null;




    -- stati ammessi per procedere con elaborazione
    -- file XML caricato correttamente pronto x elaborazione
	ACQUISITO_ST              CONSTANT  varchar :='ACQUISITO';
    -- file XML caricato correttamente, elaborazione in corso, flussi in fase di elaborazione
    ELABORATO_IN_CORSO_ST     CONSTANT  varchar :='ELABORATO_IN_CORSO'; -- senza errori  e scarti
    ELABORATO_IN_CORSO_ER_ST     CONSTANT  varchar :='ELABORATO_IN_CORSO_ER';  -- con errori
    ELABORATO_IN_CORSO_SC_ST     CONSTANT  varchar :='ELABORATO_IN_CORSO_SC'; -- con scarti
    -- stati ammessi per procedere con elaborazione


    -- stati per chiusura con errore
    ELABORATO_SCARTATO_ST     CONSTANT  varchar :='ELABORATO_SCARTATO';
    ELABORATO_ERRATO_ST       CONSTANT  varchar :='ELABORATO_ERRATO';
    ANNULLATO_ST              CONSTANT  varchar :='ANNULLATO';
	RIFIUTATO_ST              CONSTANT  varchar :='RIFIUTATO';
    -- stati per chiusura con errore

    -- stati per chiusura con successo con o senza scarti
    -- file XML caricato, ELABORAZIONE TERMINATA E CONCLUSA
    ELABORATO_OK_ST           CONSTANT  varchar :='ELABORATO_OK'; -- documenti  emessi
    ELABORATO_KO_ST           CONSTANT  varchar :='ELABORATO_KO'; -- documenti emessi - presenza di errori-scarti
    -- stati per chiusura con successo con o senza scarti

	ESERCIZIO_PROVVISORIO_ST CONSTANT  varchar :='E'; -- esercizio provvisorio
    ESERCIZIO_GESTIONE_ST    CONSTANT  varchar :='G'; -- esercizio gestione

	-- errori di elaborazione su dettagli
	PAGOPA_ERR_1	CONSTANT  varchar :='1'; --ANNULLATO
	PAGOPA_ERR_2	CONSTANT  varchar :='2'; --SCARTATO
	PAGOPA_ERR_3	CONSTANT  varchar :='3'; --ERRORE GENERICO
	PAGOPA_ERR_4	CONSTANT  varchar :='4'; --FILE NON ESISTENTE O STATO NON RICHIESTO
	PAGOPA_ERR_5	CONSTANT  varchar :='5'; --FILE CARICATO DIVERSE VOLTE PER filepagopaFileXMLId
	PAGOPA_ERR_6	CONSTANT  varchar :='6'; --DATI DI RICONCILIAZIONE NON PRESENTI
	PAGOPA_ERR_7	CONSTANT  varchar :='7'; --DATI DI RICONCILIAZIONE DA ELABORARE NON PRESENTI
	PAGOPA_ERR_8	CONSTANT  varchar :='8'; --DATI DI RICONCILIAZIONE NON PRESENTI PER filepagopaFileXMLId
	PAGOPA_ERR_9	CONSTANT  varchar :='9'; --DATI DI RICONCILIAZIONE PRESENTI PER DIVERSO FILE E STESSO filepagopaFileXMLId
	PAGOPA_ERR_10	CONSTANT  varchar :='10';--DATI DI RICONCILIAZIONE ASSOCIATI A DIVERSI VALORI DI ANNO ESERCIZIO
	PAGOPA_ERR_11	CONSTANT  varchar :='11';--DATI DI RICONCILIAZIONE ASSOCIATI A ANNO ESERCIZIO SUCCESSIVO A ANNO BILANCIO
	PAGOPA_ERR_12	CONSTANT  varchar :='12';--DATI DI RICONCILIAZIONE SENZA ANNO ESERCIZIO INDICATO
	PAGOPA_ERR_13	CONSTANT  varchar :='13';--DATI DI RICONCILIAZIONE SENZA ESTREMI PROVVISORIO DI CASSA
	PAGOPA_ERR_14	CONSTANT  varchar :='14';--DATI DI RICONCILIAZIONE SENZA ESTREMI ACCERTAMENTO
	PAGOPA_ERR_15	CONSTANT  varchar :='15';--DATI DI RICONCILIAZIONE SENZA ESTREMI VOCE/SOTTOVOCE
	PAGOPA_ERR_16	CONSTANT  varchar :='16';--DATI DI RICONCILIAZIONE SENZA IMPORTO
	PAGOPA_ERR_17	CONSTANT  varchar :='17';--ERRORE IN INSERIMENTO DATI DI ELABORAZIONE FILE
	PAGOPA_ERR_18	CONSTANT  varchar :='18';--ANNO BILANCIO DI ELABORAZIONE NON ESISTENTE O FASE NON AMMESSA
	PAGOPA_ERR_19	CONSTANT  varchar :='19';--ERRORE IN INSERIMENTO DATI DI ELABORAZIONE FLUSSO DI RICONCILIAZIONE
	PAGOPA_ERR_20	CONSTANT  varchar :='20';--DATI DI ELABORAZIONE NON ESISTENTI O IN STATO NON AMMESSO
	PAGOPA_ERR_21	CONSTANT  varchar :='21';--ERRORE IN INSERIMENTO DATI DI DETTAGLIO ELABORAZIONE FLUSSO DI RICONCILIAZIONE
	PAGOPA_ERR_22	CONSTANT  varchar :='22';--DATI DI RICONCILIAZIONE ASSOCIATI A PROVVISORIO DI CASSA NON ESISTENTE
	PAGOPA_ERR_23	CONSTANT  varchar :='23';--DATI DI RICONCILIAZIONE ASSOCIATI A ACCERTAMENTO NON ESISTENTE
  	PAGOPA_ERR_24	CONSTANT  varchar :='24';--TIPO DOCUMENTO IPA NON ESISTENTE
    PAGOPA_ERR_25   CONSTANT  varchar :='25';--BOLLO ESENTE NON ESISTENTE
    PAGOPA_ERR_26   CONSTANT  varchar :='26';--STATO VALIDO DOCUMENTO NON ESISTENTE
    PAGOPA_ERR_27   CONSTANT  varchar :='27';--IDENTIFICATIVO CDC/CDR NON ESISTENTE
    PAGOPA_ERR_28   CONSTANT  varchar :='28';--IDENTIFICATIVO TIPO QUOTA DOCUMENTO NON ESISTENTE
    PAGOPA_ERR_29   CONSTANT  varchar :='29';--IDENTIFICATIVI VARI INESISTENTI
    PAGOPA_ERR_30   CONSTANT  varchar :='30';--ERRORE IN FASE DI INSERIMENTO DOCUMENTO
    PAGOPA_ERR_31   CONSTANT  varchar :='31';--ERRORE IN FASE DI ADEGUAMENTO IMPORTO ACCERTAMENTO
    PAGOPA_ERR_32   CONSTANT  varchar :='32';--ERRORE IN FASE DI VERIFICA DISPONIBILITA PROVVOSORIO DI CASSA
    PAGOPA_ERR_33   CONSTANT  varchar :='33';--DISPONIBILITA INSUFFICIENTE PER PROVVOSORIO DI CASSA
    PAGOPA_ERR_34   CONSTANT  varchar :='34';--DATI DI RICONCILIAZIONE ASSOCIATI A SOGGETTO NON ESISTENTE
    PAGOPA_ERR_35   CONSTANT  varchar :='35';--DATI DI RICONCILIAZIONE ASSOCIATI A STRUTTURA AMMINISTRATIVA NON ESISTENTE

    PAGOPA_ERR_36   CONSTANT  varchar :='36';--DATI DI RICONCILIAZIONE SCARTATI PER ANOMALIA SU GENERAZIONE DOC. PER PROV. CASSA

    PAGOPA_ERR_37   CONSTANT  varchar :='37';--ERRORE IN LETTURA PROGRESSIVI DOCUMENTI
    PAGOPA_ERR_38   CONSTANT  varchar :='38';--DATI DI RICONCILIAZIONE ASSOCIATI A PROVVISORIO DI CASSA REGOLARIZZATO
    PAGOPA_ERR_39   CONSTANT  varchar :='39';--PROVVISORIO DI CASSA REGOLARIZZATO


	-- 31.05.2019 siac-6720
	PAGOPA_ERR_41   CONSTANT  varchar :='41';--ESTREMI SOGGETTO NON PRESENTI PER DETTAGLIO
	PAGOPA_ERR_42   CONSTANT  varchar :='42';--DATI RICONCILIAZIONE DETTAGLIO FAT. ASSOCIATI A ESTREMI SOGGETTO NON PRESENTE
	PAGOPA_ERR_43   CONSTANT  varchar :='43';--DATI RICONCILIAZIONE DETTAGLIO FAT. ASSOCIATI A ESTREMI SOGGETTO NON VALIDO
 	PAGOPA_ERR_44   CONSTANT  varchar :='44';--DATI RICONCILIAZIONE DETTAGLIO FAT. ASSOCIATI A ESTREMI SOGGETTO VALIDO NON UNIVOCO COD.FISC.
 	PAGOPA_ERR_45   CONSTANT  varchar :='45';--DATI RICONCILIAZIONE DETTAGLIO FAT. ASSOCIATI A ESTREMI SOGGETTO VALIDO NON UNIVOCO PIVA
 	PAGOPA_ERR_46   CONSTANT  varchar :='46';--DATI RICONCILIAZIONE DETTAGLIO FAT. SENZA IDENTIFICATIVO SOGGETTO ASSOCIATO
 	PAGOPA_ERR_47   CONSTANT  varchar :='47';--ERRORE IN LETTURA IDENTIFICATIVO ATTRIBUTI ACCERTAMENTO
    PAGOPA_ERR_48   CONSTANT  varchar :='48';--TIPO DOCUMENTO NON PRESENTE SU DATI DI RICONCILIAZIONE
    PAGOPA_ERR_49   CONSTANT  varchar :='49';--DETTAGLI NON PRESENTI SU DATI DI RICONCILIAZIONE CON DETT
    PAGOPA_ERR_50   CONSTANT  varchar :='50';--DATI RICONCILIAZIONE DETTAGLIO FAT. PRIVI DI IMPORTO

    -- 22.07.2019 Sofia siac-6963 - inizio
	PAGOPA_ERR_51   CONSTANT  varchar :='51';--DATI RICONCILIAZIONE CON ACCERTAMENTO PRIVO DI SOGGETTO O INESISTENTE

    DOC_STATO_VALIDO    CONSTANT  varchar :='V';
	DOC_TIPO_IPA    CONSTANT  varchar :='IPA';
    --- 12.06.2019 SIAC-6720
    DOC_TIPO_COR    CONSTANT  varchar :='COR';
    DOC_TIPO_FAT    CONSTANT  varchar :='FTV';

    -- attributi siac_t_doc
	ANNO_REPERTORIO_ATTR CONSTANT varchar:='anno_repertorio';
	NUM_REPERTORIO_ATTR CONSTANT varchar:='num_repertorio';
	DATA_REPERTORIO_ATTR CONSTANT varchar:='data_repertorio';
	REG_REPERTORIO_ATTR CONSTANT varchar:='registro_repertorio';
	ARROTONDAMENTO_ATTR CONSTANT varchar:='arrotondamento';

	CAUS_SOSPENSIONE_ATTR CONSTANT varchar:='causale_sospensione';
	DATA_SOSPENSIONE_ATTR CONSTANT varchar:='data_sospensione';
    DATA_RIATTIVAZIONE_ATTR CONSTANT varchar:='data_riattivazione';
    DATA_SCAD_SOSP_ATTR CONSTANT varchar:='dataScadenzaDopoSospensione';
    TERMINE_PAG_ATTR CONSTANT varchar:='terminepagamento';
    NOTE_PAG_INC_ATTR CONSTANT varchar:='notePagamentoIncasso';
    DATA_PAG_INC_ATTR CONSTANT varchar:='dataOperazionePagamentoIncasso';

	FL_AGG_QUOTE_ELE_ATTR CONSTANT varchar:='flagAggiornaQuoteDaElenco';
    FL_SENZA_NUM_ATTR CONSTANT varchar:='flagSenzaNumero';
    FL_REG_RES_ATTR CONSTANT varchar:='flagDisabilitaRegistrazioneResidui';
    FL_PAGATA_INC_ATTR CONSTANT varchar:='flagPagataIncassata';
    COD_FISC_PIGN_ATTR CONSTANT varchar:='codiceFiscalePignorato';
    DATA_RIC_PORTALE_ATTR CONSTANT varchar:='dataRicezionePortale';

	FL_AVVISO_ATTR	 CONSTANT varchar:='flagAvviso';
    FL_ESPROPRIO_ATTR	 CONSTANT varchar:='flagEsproprio';
    FL_ORD_MANUALE_ATTR	 CONSTANT varchar:='flagOrdinativoManuale';
    FL_ORD_SINGOLO_ATTR	 CONSTANT varchar:='flagOrdinativoSingolo';
    FL_RIL_IVA_ATTR	 CONSTANT varchar:='flagRilevanteIVA';

    CAUS_ORDIN_ATTR	 CONSTANT varchar:='causaleOrdinativo';
    DATA_ESEC_PAG_ATTR	 CONSTANT varchar:='dataEsecuzionePagamento';


    TERMINE_PAG_DEF  CONSTANT integer=30;

    provvisorioId integer:=null;
    bilancioId integer:=null;
    periodoId integer:=null;

    filePagoPaId                    integer:=null;
    filePagoPaFileXMLId             varchar:=null;

    bElabora boolean:=true;
    bErrore boolean:=false;

    docTipoId integer:=null;

    --- 12.06.2019 Siac-6720
    docTipoFatId integer:=null;
    docTipoCorId integer:=null;
    docTipoCorNumAutom integer:=null;
    docTipoFatNumAutom integer:=null;
    nProgressivoFat integer:=null;
    nProgressivoCor integer:=null;
    nProgressivoTemp integer:=null;
	isDocIPA boolean:=false;

    codBolloId integer:=null;
    dDocImporto numeric:=null;
    dispAccertamento numeric:=null;
	dispProvvisorioCassa numeric:=null;

    strElencoFlussi varchar:=null;
    docStatoValId   integer:=null;
    cdrTipoId integer:=null;
    cdcTipoId integer:=null;
    subDocTipoId integer:=null;
	movgestTipoId  integer:=null;
    movgestTsTipoId integer:=null;
    movgestStatoId integer:=null;
    provvisorioTipoId integer:=null;
	movgestTsDetTipoId integer:=null;
	dnumQuote integer:=0;
    movgestTsId integer:=null;
    subdocMovgestTsId integer:=null;

    annoBilancio integer:=null;

    -- 11.06.2019 SIAC-6720
	numModifica  integer:=null;
    attoAmmId    integer:=null;
    modificaTipoId integer:=null;
    modifId       integer:=null;
    modifStatoId  integer:=null;
    modStatoRId   integer:=Null;

	-- 13.09.2019 Sofia SIAC-7034
    numeroFattura varchar(250):=null;

    fncRec record;
    pagoPaFlussoRec record;
    pagoPaFlussoQuoteRec record;
    elabRec record;

	-- 12.08.2019 Sofia SIAC-6978 - fine
    docIUV varchar(150):=null;
BEGIN

	strMessaggioFinale:='Elaborazione rinconciliazione PAGOPA per '||
                        'Id. elaborazione filePagoPaElabId='||filePagoPaElabId::varchar||
                        ' AnnoBilancioElab='||annoBilancioElab::varchar||'.';

    strMessaggioLog:='Inizio fnc_pagopa_t_elaborazione_riconc_esegui - '||strMessaggioFinale;
--    raise notice '%',strMessaggioLog;

	insert into pagopa_t_elaborazione_log
    (
     pagopa_elab_id,
     pagopa_elab_file_id,
     pagopa_elab_log_operazione,
     ente_proprietario_id,
     login_operazione,
     data_creazione
    )
    values
    (
     filePagoPaElabId,
     null,
     strMessaggioLog,
	 enteProprietarioId,
     loginOperazione,
     clock_timestamp()
    );
    GET DIAGNOSTICS codResult = ROW_COUNT;
--    raise notice '2222%',strMessaggioLog;
--    raise notice '2222-codResult- %',codResult;
    codResult:=null;
    codiceRisultato:=0;
    messaggioRisultato:='';


    strMessaggio:='Verifica esistenza elaborazione.';
    --select elab.file_pagopa_id, elab.pagopa_elab_file_id into filePagoPaId, filePagoPaFileXMLId
    select 1 into codResult
    from pagopa_t_elaborazione elab, pagopa_d_elaborazione_stato stato
    where elab.pagopa_elab_id=filePagoPaElabId
    and   stato.pagopa_elab_stato_id=elab.pagopa_elab_stato_id
    and   stato.pagopa_elab_stato_code in (ELABORATO_IN_CORSO_ST, ELABORATO_IN_CORSO_ER_ST,ELABORATO_IN_CORSO_SC_ST)
    and   stato.ente_proprietario_id=enteProprietarioId
    and   elab.data_cancellazione is null
    and   elab.validita_fine  is null;
--    raise notice '2222strMessaggio%',strMessaggio;

--	if filePagoPaId is null or filePagoPaFileXMLId is null then
    if codResult is null then
        pagoPaCodeErr:=PAGOPA_ERR_20;
        strErrore:=' Non esistente.';
        codResult:=-1;
        bElabora:=false;
    else codResult:=null;
    end if;

/*  elaborazioni multi file
    if codResult is null then
     strMessaggio:='Verifica esistenza file di elaborazione per filePagoPaId='||filePagoPaId::varchar||
                   ' filePagoPaFileXMLId='||filePagoPaFileXMLId||'.';
     select 1 into codResult
     from siac_t_file_pagopa file, siac_d_file_pagopa_stato stato
     where file.file_pagopa_id=filePagoPaId
     and   file.file_pagopa_code=filePagoPaFileXMLId
     and   stato.file_pagopa_stato_id=file.file_pagopa_stato_id
     and   stato.file_pagopa_stato_code in (ELABORATO_IN_CORSO_ST, ELABORATO_IN_CORSO_ER_ST,ELABORATO_IN_CORSO_SC_ST)
     and   stato.ente_proprietario_id=enteProprietarioId
     and   file.data_cancellazione is null
     and   file.validita_fine  is null;

     if codResult is null then
    	pagoPaCodeErr:=PAGOPA_ERR_4;
        strErrore:=' Non esistente.';
        codResult:=-1;
        bElabora:=false;
     else codResult:=null;
     end if;
    end if;
*/


   if codResult is null then
      strMessaggio:='Verifica esistenza tipo documento='||DOC_TIPO_IPA||'.';
      -- lettura tipodocumento
      select tipo.doc_tipo_id into docTipoId
      from siac_d_doc_tipo tipo
      where tipo.ente_proprietario_id=enteProprietarioId
      and   tipo.doc_tipo_code=DOC_TIPO_IPA;
      if docTipoId is null then
          pagoPaCodeErr:=PAGOPA_ERR_24;
          strErrore:=' Non esistente.';
          codResult:=-1;
          bElabora:=false;
      end if;
   end if;

  if codResult is null then
      strMessaggio:='Verifica esistenza tipo documento='||DOC_TIPO_FAT||'.';
      -- lettura tipodocumento
      select tipo.doc_tipo_id into docTipoFatId
      from siac_d_doc_tipo tipo,siac_d_doc_fam_tipo fam
      where tipo.ente_proprietario_id=enteProprietarioId
      and   tipo.doc_tipo_code=DOC_TIPO_FAT
      and   fam.doc_fam_tipo_id=tipo.doc_fam_tipo_id
      and   fam.doc_fam_tipo_code='E';
      if docTipoFatId is null then
          pagoPaCodeErr:=PAGOPA_ERR_24;
          strErrore:=' Non esistente.';
          codResult:=-1;
          bElabora:=false;
      else
	      select 1 into docTipoFatNumAutom
          from siac_r_doc_tipo_attr rattr,siac_t_attr attr
          where rattr.doc_tipo_id=docTipoFatId
          and   attr.attr_id=rattr.attr_id
          and   attr.attr_code='flagSenzaNumero'
          and   coalesce(rattr.boolean,'N')='S'
          and   rattr.data_cancellazione is null
          and   rattr.validita_fine is null;
      end if;

  end if;

  if codResult is null then
      strMessaggio:='Verifica esistenza tipo documento='||DOC_TIPO_COR||'.';
      -- lettura tipodocumento
      select tipo.doc_tipo_id into docTipoCorId
      from siac_d_doc_tipo tipo,siac_d_doc_fam_tipo fam
      where tipo.ente_proprietario_id=enteProprietarioId
      and   tipo.doc_tipo_code=DOC_TIPO_COR
      and   fam.doc_fam_tipo_id=tipo.doc_fam_tipo_id
      and   fam.doc_fam_tipo_code='E';

      if docTipoCorId is null then
          pagoPaCodeErr:=PAGOPA_ERR_24;
          strErrore:=' Non esistente.';
          codResult:=-1;
          bElabora:=false;
      else
   	      select 1 into docTipoCorNumAutom
          from siac_r_doc_tipo_attr rattr,siac_t_attr attr
          where rattr.doc_tipo_id=docTipoCorId
          and   attr.attr_id=rattr.attr_id
          and   attr.attr_code='flagSenzaNumero'
          and   coalesce(rattr.boolean,'N')='S'
          and   rattr.data_cancellazione is null
          and   rattr.validita_fine is null;

      end if;
   end if;


   if codResult is null then
    	strMessaggio:='Lettura identificativo bollo esente.';
    	-- lettura tipodocumento
		select cod.codbollo_id into codBolloId
		from siac_d_codicebollo cod
		where cod.ente_proprietario_id=enteProprietarioId
		and   cod.codbollo_desc='ESENTE BOLLO';
        if codBolloId is null then
	        pagoPaCodeErr:=PAGOPA_ERR_25;
    	    strErrore:=' Non riuscita.';
        	codResult:=-1;
	        bElabora:=false;
        end if;

    end if;


   if codResult is null then
    	strMessaggio:='Lettura identificativo documento stato='||DOC_STATO_VALIDO||'.';
		select stato.doc_stato_id into docStatoValId
		from siac_d_doc_stato Stato
		where stato.ente_proprietario_id=enteProprietarioId
		and   stato.doc_stato_code=DOC_STATO_VALIDO;
        if docStatoValId is null then
	        pagoPaCodeErr:=PAGOPA_ERR_26;
    	    strErrore:=' Non riuscita.';
        	codResult:=-1;
	        bElabora:=false;
        end if;

    end if;

    if codResult is null then
    	strMessaggio:='Lettura identificativo tipo CDC.';
		select tipo.classif_tipo_id into cdcTipoId
		from siac_d_class_tipo tipo
		where tipo.ente_proprietario_id=enteProprietarioId
		and   tipo.classif_tipo_code='CDC';
        if cdcTipoId is null then
	        pagoPaCodeErr:=PAGOPA_ERR_27;
    	    strErrore:=' Non esistente.';
        	codResult:=-1;
	        bElabora:=false;
        end if;

    end if;

	if codResult is null then
    	strMessaggio:='Lettura identificativo tipo CDR.';
		select tipo.classif_tipo_id into cdrTipoId
		from siac_d_class_tipo tipo
		where tipo.ente_proprietario_id=enteProprietarioId
		and   tipo.classif_tipo_code='CDR';
        if cdrTipoId is null then
	        pagoPaCodeErr:=PAGOPA_ERR_27;
    	    strErrore:=' Non esistente.';
        	codResult:=-1;
	        bElabora:=false;
        end if;

    end if;


	if codResult is null then
    	strMessaggio:='Lettura identificativo tipo subdocumento SE.';
		select tipo.subdoc_tipo_id into subDocTipoId
		from siac_d_subdoc_tipo tipo
		where tipo.ente_proprietario_id=enteProprietarioId
		and   tipo.subdoc_tipo_code='SE';
        if subDocTipoId is null then
	        pagoPaCodeErr:=PAGOPA_ERR_28;
    	    strErrore:=' Non esistente.';
        	codResult:=-1;
	        bElabora:=false;
        end if;

    end if;

	if codResult is null then
    	strMessaggio:='Lettura identificativo tipo accertamento.';
		select tipo.movgest_tipo_id into movgestTipoId
		from siac_d_movgest_tipo tipo
		where tipo.ente_proprietario_id=enteProprietarioId
		and   tipo.movgest_tipo_code='A';
        if movgestTipoId is null then
	        pagoPaCodeErr:=PAGOPA_ERR_29;
    	    strErrore:=' Non esistente.';
        	codResult:=-1;
	        bElabora:=false;
        end if;

    end if;

	if codResult is null then
    	strMessaggio:='Lettura identificativo tipo testata accertamento.';
		select tipo.movgest_ts_tipo_id into movgestTsTipoId
		from siac_d_movgest_ts_tipo tipo
		where tipo.ente_proprietario_id=enteProprietarioId
		and   tipo.movgest_ts_tipo_code='T';
        if movgestTsTipoId is null then
	        pagoPaCodeErr:=PAGOPA_ERR_29;
    	    strErrore:=' Non esistente.';
        	codResult:=-1;
	        bElabora:=false;
        end if;

    end if;

	if codResult is null then
    	strMessaggio:='Lettura identificativo stato DEFINITIVO accertamento.';
		select tipo.movgest_stato_id into movgestStatoId
		from siac_d_movgest_stato tipo
		where tipo.ente_proprietario_id=enteProprietarioId
		and   tipo.movgest_stato_code='D';
        if movgestStatoId is null then
	        pagoPaCodeErr:=PAGOPA_ERR_29;
    	    strErrore:=' Non esistente.';
        	codResult:=-1;
	        bElabora:=false;
        end if;
    end if;

	if codResult is null then
    	strMessaggio:='Lettura identificativo tipo importo ATTUALE accertamento.';
		select tipo.movgest_ts_det_tipo_id into movgestTsDetTipoId
		from siac_d_movgest_ts_det_tipo tipo
		where tipo.ente_proprietario_id=enteProprietarioId
		and   tipo.movgest_ts_det_tipo_code='A';
        if movgestTsDetTipoId is null then
	        pagoPaCodeErr:=PAGOPA_ERR_29;
    	    strErrore:=' Non esistente.';
        	codResult:=-1;
	        bElabora:=false;
        end if;
    end if;



	if codResult is null then
    	strMessaggio:='Lettura identificativo tipo provvissorio cassa entrata.';
		select tipo.provc_tipo_id into provvisorioTipoId
		from siac_d_prov_cassa_tipo tipo
		where tipo.ente_proprietario_id=enteProprietarioId
		and   tipo.provc_tipo_code='E';
        if provvisorioTipoId is null then
	        pagoPaCodeErr:=PAGOPA_ERR_29;
    	    strErrore:=' Non esistente.';
        	codResult:=-1;
	        bElabora:=false;
        end if;
    end if;

	if codResult is null then
     strMessaggio:='Gestione scarti di elaborazione. Verifica annoBilancio indicato su dettagli di riconciliazione.';
--    raise notice '2222@@%',strMessaggio;

     select  distinct doc.pagopa_ric_doc_anno_esercizio into annoBilancio
     from  pagopa_t_riconciliazione_doc doc, pagopa_t_elaborazione_flusso flusso
     where flusso.pagopa_elab_id=filePagoPaElabId
     and   doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and   doc.pagopa_ric_doc_stato_elab='N'
     and   doc.pagopa_ric_doc_subdoc_id is null
     and   doc.pagopa_ric_doc_flag_con_dett=false -- 05.06.2019 SIAC-6720
     and   not exists
     (
     select 1
     from pagopa_t_riconciliazione_doc doc1
     where doc1.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and   doc1.pagopa_ric_doc_stato_elab!='N'
     and   doc1.data_cancellazione is null
     and   doc1.validita_fine is null
     )
     and   doc.data_cancellazione is null
     and   doc.validita_fine is null
     and   flusso.data_cancellazione is null
     and   flusso.validita_fine is null
     limit 1;
     if annoBilancio is null then
       	pagoPaCodeErr:=PAGOPA_ERR_12;
        strErrore:=' Dati non presenti.';
        codResult:=-1;
        bElabora:=false;
     else
     	if annoBilancio>annoBilancioElab then
           	pagoPaCodeErr:=PAGOPA_ERR_11;
	        strErrore:=' Anno bilancio successivo ad anno di elaborazione.';
    	    codResult:=-1;
        	bElabora:=false;
        end if;
     end if;
--         raise notice '2222@@strErrore%',strErrore;

	end if;


    if codResult is null then
	 strMessaggio:='Gestione scarti di elaborazione. Verifica fase bilancio per elaborazione.';
	 select bil.bil_id, per.periodo_id into bilancioId , periodoId
     from siac_t_bil bil,siac_t_periodo per,
          siac_r_bil_fase_operativa r, siac_d_fase_operativa fase
     where per.ente_proprietario_id=enteProprietarioid
     and   per.anno::integer=annoBilancio
     and   bil.periodo_id=per.periodo_id
     and   r.bil_id=bil.bil_id
     and   fase.fase_operativa_id=r.fase_operativa_id
     and   fase.fase_operativa_code in (ESERCIZIO_PROVVISORIO_ST,ESERCIZIO_GESTIONE_ST);
     if bilancioId is null then
     	pagoPaCodeErr:=PAGOPA_ERR_18;
        strErrore:=' Fase non ammessa per elaborazione.';
        codResult:=-1;
        bElabora:=false;
	 end if;
   end if;

   if codResult is null then
	  strMessaggio:='Gestione scarti di elaborazione. Lettura progressivo doc. siac_t_doc_num per anno='||annoBilancio::varchar||'.';

      nProgressivo:=0;
      insert into  siac_t_doc_num
      (
        doc_anno,
        doc_numero,
        doc_tipo_id,
        validita_inizio,
        login_operazione,
        ente_proprietario_id
      )
      select annoBilancio,
             nProgressivo,
             docTipoId,
             clock_timestamp(),
             loginOperazione,
             bil.ente_proprietario_id
      from siac_t_bil bil
      where bil.bil_id=bilancioId
      and not exists
      (
      select 1
      from siac_t_doc_num num
      where num.ente_proprietario_id=bil.ente_proprietario_id
      and   num.doc_anno::integer=annoBilancio
      and   num.doc_tipo_id=docTipoId
      and   num.data_cancellazione is null
      and   date_trunc('DAY',now())>=date_trunc('DAY',num.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(num.validita_fine,date_trunc('DAY',now())))
      )
      returning doc_num_id into codResult;

      if codResult is null then
      	select num.doc_numero into codResult
        from siac_t_doc_num num
        where num.ente_proprietario_id=enteProprietarioId
        and   num.doc_anno::integer=annoBilancio
        and   num.doc_tipo_id=docTipoId;

        if codResult is not null then
        	nProgressivo:=codResult;
            codResult:=null;
        else
            pagoPaCodeErr:=PAGOPA_ERR_37;
        	strErrore:=' Progressivo non reperito.';
	        codResult:=-1;
    	    bElabora:=false;
        end if;
      else codResult:=null;
      end if;

   end if;

   --- 12.06.2019 Sofia SIAC-6720
   if codResult is null and
      (docTipoCorNumAutom is not null or docTipoFatNumAutom is not null ) then
	  strMessaggio:='Gestione scarti di elaborazione. Lettura progressivo doc. siac_t_doc_num ['
                   ||DOC_TIPO_FAT||'-'
                   ||DOC_TIPO_COR
                   ||'] per anno='||annoBilancio::varchar||'.';

      nProgressivoFat:=0;
      nProgressivoCor:=0;
      insert into  siac_t_doc_num
      (
        doc_anno,
        doc_numero,
        doc_tipo_id,
        validita_inizio,
        login_operazione,
        ente_proprietario_id
      )
      select annoBilancio,
             nProgressivoFat,
             tipo.doc_tipo_id,
             clock_timestamp(),
             loginOperazione,
             bil.ente_proprietario_id
      from siac_t_bil bil,siac_d_doc_tipo tipo
      where bil.bil_id=bilancioId
      --and   tipo.doc_tipo_id in (docTipoFatId,docTipoCorId)
      and   tipo.doc_tipo_id in
      (select docTipoCorId doc_tipo_id where  docTipoCorNumAutom is not null
       union
       select docTipoFatId doc_tipo_id where  docTipoFatNumAutom is not null
      )
      and not exists
      (
      select 1
      from siac_t_doc_num num
      where num.ente_proprietario_id=bil.ente_proprietario_id
      and   num.doc_anno::integer=annoBilancio
      and   num.doc_tipo_id=tipo.doc_tipo_id
      and   num.data_cancellazione is null
      and   date_trunc('DAY',now())>=date_trunc('DAY',num.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(num.validita_fine,date_trunc('DAY',now())))
      );
      GET DIAGNOSTICS codResult = ROW_COUNT;

	  codResult:=null;
      --if codResult is null then
      if docTipoCorNumAutom is not null then
          select num.doc_numero into codResult
          from siac_t_doc_num num
          where num.ente_proprietario_id=enteProprietarioId
          and   num.doc_anno::integer=annoBilancio
          and   num.doc_tipo_id =docTipoCorId;

          if codResult is not null then
              nProgressivoCor:=codResult;
              codResult:=null;
          else
              pagoPaCodeErr:=PAGOPA_ERR_37;
              strErrore:=' Progressivo non reperito.';
              codResult:=-1;
              bElabora:=false;
          end if;
      end if;

      if docTipoFatNumAutom is not null and codResult is null then
          select num.doc_numero into codResult
          from siac_t_doc_num num
          where num.ente_proprietario_id=enteProprietarioId
          and   num.doc_anno::integer=annoBilancio
          and   num.doc_tipo_id =docTipoFatId;

          if codResult is not null then
              nProgressivoFat:=codResult;
              codResult:=null;
          else
              pagoPaCodeErr:=PAGOPA_ERR_37;
              strErrore:=' Progressivo non reperito.';
              codResult:=-1;
              bElabora:=false;
          end if;
      end if;
--    else codResult:=null;
--    end if;

   end if;

   if codResult is null then
    strMessaggio:='Gestione scarti di elaborazione. Inserimento siac_t_registrounico_doc_num per anno='||annoBilancio::varchar||'.';

	insert into  siac_t_registrounico_doc_num
    (
	  rudoc_registrazione_anno,
	  rudoc_registrazione_numero,
      validita_inizio,
      login_operazione,
      ente_proprietario_id
    )
    select annoBilancio,
           0,
           clock_timestamp(),
           loginOperazione,
           bil.ente_proprietario_id
    from siac_t_bil bil
    where bil.bil_id=bilancioId
    and not exists
    (
    select 1
    from siac_t_registrounico_doc_num num
    where num.ente_proprietario_id=bil.ente_proprietario_id
    and   num.rudoc_registrazione_anno::integer=annoBilancio
    and   num.data_cancellazione is null
    and   date_trunc('DAY',now())>=date_trunc('DAY',num.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(num.validita_fine,date_trunc('DAY',now())))
    );
   end if;



    -- gestione scarti
    -- provvisorio non esistente
    if codResult is null then

 	 strMessaggio:='Gestione scarti di elaborazione PAGOPA_ERR_CODE='||PAGOPA_ERR_22||'.';
--     raise notice '2222@@strMessaggio PAGOPA_ERR_22 %',strMessaggio;

     update pagopa_t_riconciliazione_doc doc
     set    pagopa_ric_doc_stato_elab='X',
            pagopa_ric_errore_id=err.pagopa_ric_errore_id,
            data_modifica=clock_timestamp(),
            login_operazione=doc.login_operazione||'-'||loginOperazione||'@ELAB-'||filePagoPaElabId::varchar
     from pagopa_t_elaborazione_flusso flusso,pagopa_d_riconciliazione_errore err
     where  flusso.pagopa_elab_id=filePagoPaElabId
     and    doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and    doc.pagopa_ric_doc_stato_elab='N'
     and    doc.pagopa_ric_doc_subdoc_id is null
     and    doc.pagopa_ric_doc_flag_con_dett=false -- 05.06.2019 SIAC-6720
     and    not exists
     (
     select 1
     from siac_t_prov_cassa prov, siac_d_prov_cassa_tipo tipo
     where tipo.ente_proprietario_id=doc.ente_proprietario_id
     and   tipo.provc_tipo_code='E'
     and   prov.provc_tipo_id=tipo.provc_tipo_id
     and   prov.provc_anno::integer=flusso.pagopa_elab_flusso_anno_provvisorio
     and   prov.provc_numero::integer=flusso.pagopa_elab_flusso_num_provvisorio
     and   prov.provc_data_annullamento is null
     and   prov.provc_data_regolarizzazione is null
     and   prov.data_cancellazione is null
     and   prov.validita_fine is null
     )
     --     26.07.2019 Sofia questo controllo causa
     --     nelle update successive il non aggiornamento del motivo di scarto
     --     sulle righe dello stesso flusso ma con motivi diversi
     --     gli step successivi ( update successivi ) lasciano elab='N'
     --     in questo modo il flusso non viene elaborato
     --     in quanto la stessa condizione compare nel query del loop di elaborazione
     --     ma non tutti i dettagli in scarto vengono trattati ed eventualmente associati
     --     a un motivo di scarto
     --     bisogna tenerne conto quando un  flusso non viene elaborato
     --     e non tutti i dettagli hanno un motivo di scarto segnalato
     and    not exists -- esclusione flussi ( per provvisorio ) con scarti
     (
     select 1
     from pagopa_t_riconciliazione_doc doc1
     where doc1.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and   doc1.pagopa_ric_doc_stato_elab!='N'
     and   doc1.data_cancellazione is null
     and   doc1.validita_fine is null
     )
     and    err.ente_proprietario_id=flusso.ente_proprietario_id
     and    err.pagopa_ric_errore_code=PAGOPA_ERR_22
     and    flusso.data_cancellazione is null
     and    flusso.validita_fine is null
     and    doc.data_cancellazione is null
     and    doc.validita_fine is null;
     GET DIAGNOSTICS codResult = ROW_COUNT;

     if coalesce(codResult,0)!=0 then
     	pagoPaCodeErr:=PAGOPA_ERR_22;
        strErrore:=' Provvisori di cassa non esistenti.';
     end if;
	 codResult:=null;
    end if;
--    raise notice 'strErrore=%',strErrore;

    --- provvisorio esistente , ma regolarizzato
    if codResult is null then
 	 strMessaggio:='Gestione scarti di elaborazione PAGOPA_ERR_CODE='||PAGOPA_ERR_38||'.';
--     raise notice '2222@@strMessaggio PAGOPA_ERR_38 %',strMessaggio;
     update pagopa_t_riconciliazione_doc doc
     set    pagopa_ric_doc_stato_elab='X',
            pagopa_ric_errore_id=err.pagopa_ric_errore_id,
            data_modifica=clock_timestamp(),
            login_operazione=doc.login_operazione||'-'||loginOperazione||'@ELAB-'||filePagoPaElabId::varchar
     from pagopa_t_elaborazione_flusso flusso,pagopa_d_riconciliazione_errore err
     where  flusso.pagopa_elab_id=filePagoPaElabId
     and    doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and    doc.pagopa_ric_doc_stato_elab='N'
     and    doc.pagopa_ric_doc_flag_con_dett=false -- 05.06.2019 SIAC-6720
     and    doc.pagopa_ric_doc_subdoc_id is null
     and    exists
     (
     select 1
     from siac_t_prov_cassa prov, siac_d_prov_cassa_tipo tipo, siac_r_ordinativo_prov_cassa rp
     where tipo.ente_proprietario_id=doc.ente_proprietario_id
     and   tipo.provc_tipo_code='E'
     and   prov.provc_tipo_id=tipo.provc_tipo_id
     and   prov.provc_anno::integer=flusso.pagopa_elab_flusso_anno_provvisorio
     and   prov.provc_numero::integer=flusso.pagopa_elab_flusso_num_provvisorio
     and   rp.provc_id=prov.provc_id
     and   prov.provc_data_annullamento is null
     and   prov.provc_data_regolarizzazione is null
     and   prov.data_cancellazione is null
     and   prov.validita_fine is null
     and   rp.data_cancellazione is null
     and   rp.validita_fine is null
     )
     and    not exists -- esclusione flussi ( per provvisorio ) con scarti
     (
     select 1
     from pagopa_t_riconciliazione_doc doc1
     where doc1.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and   doc1.pagopa_ric_doc_stato_elab!='N'
     and   doc1.data_cancellazione is null
     and   doc1.validita_fine is null
     )
     and    err.ente_proprietario_id=flusso.ente_proprietario_id
     and    err.pagopa_ric_errore_code=PAGOPA_ERR_38
     and    flusso.data_cancellazione is null
     and    flusso.validita_fine is null
     and    doc.data_cancellazione is null
     and    doc.validita_fine is null;
     GET DIAGNOSTICS codResult = ROW_COUNT;

     if coalesce(codResult,0)=0 then
       update pagopa_t_riconciliazione_doc doc
       set    pagopa_ric_doc_stato_elab='X',
        	   pagopa_ric_errore_id=err.pagopa_ric_errore_id,
               data_modifica=clock_timestamp(),
               login_operazione=doc.login_operazione||'-'||loginOperazione||'@ELAB-'||filePagoPaElabId::varchar
   	   from pagopa_t_elaborazione_flusso flusso,pagopa_d_riconciliazione_errore err
	   where  flusso.pagopa_elab_id=filePagoPaElabId
       and    doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
       and    doc.pagopa_ric_doc_stato_elab='N'
       and    doc.pagopa_ric_doc_subdoc_id is null
       and    doc.pagopa_ric_doc_flag_con_dett=false -- 05.06.2019 SIAC-6720
       and    exists
       (
       select 1
       from siac_t_prov_cassa prov, siac_d_prov_cassa_tipo tipo, siac_r_subdoc_prov_cassa rp
       where tipo.ente_proprietario_id=doc.ente_proprietario_id
       and   tipo.provc_tipo_code='E'
       and   prov.provc_tipo_id=tipo.provc_tipo_id
       and   prov.provc_anno::integer=flusso.pagopa_elab_flusso_anno_provvisorio
       and   prov.provc_numero::integer=flusso.pagopa_elab_flusso_num_provvisorio
       and   rp.provc_id=prov.provc_id
       and   prov.provc_data_annullamento is null
       and   prov.provc_data_regolarizzazione is null
       and   prov.data_cancellazione is null
       and   prov.validita_fine is null
       and   rp.data_cancellazione is null
       and   rp.validita_fine is null
       )
       and    not exists -- esclusione flussi ( per provvisorio ) con scarti
       (
       select 1
       from pagopa_t_riconciliazione_doc doc1
       where doc1.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
       and   doc1.pagopa_ric_doc_stato_elab!='N'
       and   doc1.data_cancellazione is null
       and   doc1.validita_fine is null
       )
       and    err.ente_proprietario_id=flusso.ente_proprietario_id
       and    err.pagopa_ric_errore_code=PAGOPA_ERR_38
       and    flusso.data_cancellazione is null
       and    flusso.validita_fine is null
       and    doc.data_cancellazione is null
       and    doc.validita_fine is null;
       GET DIAGNOSTICS codResult = ROW_COUNT;
     end if;

     if coalesce(codResult,0)!=0 then
     	pagoPaCodeErr:=PAGOPA_ERR_38;
        strErrore:=' Provvisori di cassa regolarizzati.';
     end if;
	 codResult:=null;
    end if;

    if codResult is null then
     -- accertamento non esistente
 	 strMessaggio:='Gestione scarti di elaborazione PAGOPA_ERR_CODE='||PAGOPA_ERR_23||'.';
--     raise notice '2222@@strMessaggio PAGOPA_ERR_23 %',strMessaggio;

     update pagopa_t_riconciliazione_doc doc
     set    pagopa_ric_doc_stato_elab='X',
            pagopa_ric_errore_id=err.pagopa_ric_errore_id,
            data_modifica=clock_timestamp(),
            login_operazione=doc.login_operazione||'-'||loginOperazione||'@ELAB-'||filePagoPaElabId::varchar
     from pagopa_t_elaborazione_flusso flusso,pagopa_d_riconciliazione_errore err
     where  flusso.pagopa_elab_id=filePagoPaElabId
     and    doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and    doc.pagopa_ric_doc_stato_elab='N'
     and    doc.pagopa_ric_doc_subdoc_id is null
     and    doc.pagopa_ric_doc_flag_con_dett=false -- 05.06.2019 SIAC-6720
     and    not exists
     (
     select 1
     from siac_t_movgest mov, siac_d_movgest_tipo tipo,
          siac_t_movgest_ts ts, siac_d_movgest_ts_tipo tipots,
          siac_r_movgest_ts_stato rs, siac_d_movgest_stato stato
     where tipo.ente_proprietario_id=doc.ente_proprietario_id
     and   tipo.movgest_tipo_code='A'
     and   mov.movgest_tipo_id=tipo.movgest_tipo_id
     and   mov.bil_id=bilancioId
     and   ts.movgest_id=mov.movgest_id
     and   tipots.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
     and   tipots.movgest_ts_tipo_code='T'
     and   rs.movgest_ts_id=ts.movgest_ts_id
     and   stato.movgest_stato_id=rs.movgest_stato_id
     and   stato.movgest_stato_code='D'
     and   mov.movgest_anno::integer=doc.pagopa_ric_doc_anno_accertamento
     and   mov.movgest_numero::integer=doc.pagopa_ric_doc_num_accertamento
     and   mov.data_cancellazione is null
     and   mov.validita_fine is null
     and   ts.data_cancellazione is null
     and   ts.validita_fine is null
     and   rs.data_cancellazione is null
     and   rs.validita_fine is null
     )
     and    not exists
     (
     select 1
     from pagopa_t_riconciliazione_doc doc1
     where doc1.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and   doc1.pagopa_ric_doc_stato_elab!='N'
     and   doc1.data_cancellazione is null
     and   doc1.validita_fine is null
     )
     and    err.ente_proprietario_id=flusso.ente_proprietario_id
     and    err.pagopa_ric_errore_code=PAGOPA_ERR_23
     and    flusso.data_cancellazione is null
     and    flusso.validita_fine is null
     and    doc.data_cancellazione is null
     and    doc.validita_fine is null;
     GET DIAGNOSTICS codResult = ROW_COUNT;

     if coalesce(codResult,0)!=0  then
     	pagoPaCodeErr:=PAGOPA_ERR_23;
        strErrore:=' Accertamenti non esistenti.';
     end if;
     codResult:=null;
   end if;

--   raise notice 'strErrore=%',strErrore;

   -- siac-6720 31.05.2019 controlli - inizio


   -- dettagli con codice fiscale non indicato
   if codResult is null then
 	 strMessaggio:='Gestione scarti di elaborazione PAGOPA_ERR_CODE='||PAGOPA_ERR_41||'.';

     update pagopa_t_riconciliazione_doc doc
     set    pagopa_ric_doc_stato_elab='X',
            pagopa_ric_errore_id=err.pagopa_ric_errore_id,
            data_modifica=clock_timestamp(),
            login_operazione=doc.login_operazione||'-'||loginOperazione||'@ELAB-'||filePagoPaElabId::varchar
     from pagopa_t_elaborazione_flusso flusso,pagopa_d_riconciliazione_errore err
     where  flusso.pagopa_elab_id=filePagoPaElabId
     and    doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and    doc.pagopa_ric_doc_stato_elab='N'
     and    doc.pagopa_ric_doc_flag_con_dett=false -- 05.06.2019 SIAC-6720
     and    doc.pagopa_ric_doc_flag_dett=true
     and    coalesce(doc.pagopa_ric_doc_codfisc_benef,'')=''
     and    doc.pagopa_ric_doc_subdoc_id is null
     and    not exists
     (
     select 1
     from pagopa_t_riconciliazione_doc doc1
     where doc1.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and   doc1.pagopa_ric_doc_stato_elab!='N'
     and   doc1.data_cancellazione is null
     and   doc1.validita_fine is null
     )
     and    err.ente_proprietario_id=flusso.ente_proprietario_id
     and    err.pagopa_ric_errore_code=PAGOPA_ERR_41
     and    flusso.data_cancellazione is null
     and    flusso.validita_fine is null
     and    doc.data_cancellazione is null
     and    doc.validita_fine is null;
     GET DIAGNOSTICS codResult = ROW_COUNT;

     if coalesce(codResult,0)!=0 then
     	pagoPaCodeErr:=PAGOPA_ERR_41;
        strErrore:=' Estremi soggetto non indicati per dati di dettaglio-fatt.';
     end if;
     codResult:=null;
   end if;

   -- dettagli con codice fiscale indicato
   --  soggetto non esistente
   if codResult is null then
 	 strMessaggio:='Gestione scarti di elaborazione PAGOPA_ERR_CODE='||PAGOPA_ERR_42||'.';

     update pagopa_t_riconciliazione_doc doc
     set    pagopa_ric_doc_stato_elab='X',
            pagopa_ric_errore_id=err.pagopa_ric_errore_id,
            data_modifica=clock_timestamp(),
            login_operazione=doc.login_operazione||'-'||loginOperazione||'@ELAB-'||filePagoPaElabId::varchar
     from pagopa_t_elaborazione_flusso flusso,pagopa_d_riconciliazione_errore err
     where  flusso.pagopa_elab_id=filePagoPaElabId
     and    doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and    doc.pagopa_ric_doc_stato_elab='N'
     and    doc.pagopa_ric_doc_flag_con_dett=false -- 05.06.2019 SIAC-6720
     and    doc.pagopa_ric_doc_flag_dett=true
     and    coalesce(doc.pagopa_ric_doc_codfisc_benef,'')!=''
     and    doc.pagopa_ric_doc_subdoc_id is null
     and    not exists
     (
     select  1
     from  siac_t_soggetto sog
     where sog.ente_proprietario_id=enteProprietarioId
     and   sog.codice_fiscale=upper(doc.pagopa_ric_doc_codfisc_benef)
     and   sog.data_cancellazione is null
     and   sog.validita_fine is null
     )
     and    not exists
     (
     select  1
     from  siac_t_soggetto sog
     where sog.ente_proprietario_id=enteProprietarioId
     and   sog.partita_iva=upper(doc.pagopa_ric_doc_codfisc_benef)
     and   sog.data_cancellazione is null
     and   sog.validita_fine is null
     )
     and    not exists
     (
     select 1
     from pagopa_t_riconciliazione_doc doc1
     where doc1.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and   doc1.pagopa_ric_doc_stato_elab!='N'
     and   doc1.data_cancellazione is null
     and   doc1.validita_fine is null
     )
     and    err.ente_proprietario_id=flusso.ente_proprietario_id
     and    err.pagopa_ric_errore_code=PAGOPA_ERR_42
     and    flusso.data_cancellazione is null
     and    flusso.validita_fine is null
     and    doc.data_cancellazione is null
     and    doc.validita_fine is null;
     GET DIAGNOSTICS codResult = ROW_COUNT;

     if coalesce(codResult,0)!=0 then
     	pagoPaCodeErr:=PAGOPA_ERR_42;
        strErrore:=' Soggetto inesistente per dati di dettaglio-fatt. ';
     end if;
     codResult:=null;
   end if;

   -- dettagli con codice fiscale indicato
   --  soggetto esistente ma non valido
   if codResult is null then
 	 strMessaggio:='Gestione scarti di elaborazione PAGOPA_ERR_CODE='||PAGOPA_ERR_43||'.';

     update pagopa_t_riconciliazione_doc doc
     set    pagopa_ric_doc_stato_elab='X',
            pagopa_ric_errore_id=err.pagopa_ric_errore_id,
            data_modifica=clock_timestamp(),
            login_operazione=doc.login_operazione||'-'||loginOperazione||'@ELAB-'||filePagoPaElabId::varchar
     from pagopa_t_elaborazione_flusso flusso,pagopa_d_riconciliazione_errore err
     where  flusso.pagopa_elab_id=filePagoPaElabId
     and    doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and    doc.pagopa_ric_doc_stato_elab='N'
     and    doc.pagopa_ric_doc_flag_con_dett=false -- 05.06.2019 SIAC-6720
     and    doc.pagopa_ric_doc_flag_dett=true
     and    coalesce(doc.pagopa_ric_doc_codfisc_benef,'')!=''
     and    doc.pagopa_ric_doc_subdoc_id is null
     and    not exists
     (
     select  1
     from  siac_t_soggetto sog,siac_r_soggetto_stato rs,siac_d_soggetto_stato stato
     where sog.ente_proprietario_id=enteProprietarioId
     and   sog.codice_fiscale=upper(doc.pagopa_ric_doc_codfisc_benef)
     and   rs.soggetto_id=sog.soggetto_id
     and   stato.soggetto_stato_id=rs.soggetto_stato_id
     and   stato.soggetto_stato_code='VALIDO'
     and   sog.data_cancellazione is null
     and   sog.validita_fine is null
     and   rs.data_cancellazione is null
     and   rs.validita_fine is null
     )
     and    not exists
     (
     select  1
     from  siac_t_soggetto sog,siac_r_soggetto_stato rs,siac_d_soggetto_stato stato
     where sog.ente_proprietario_id=enteProprietarioId
     and   sog.partita_iva=upper(doc.pagopa_ric_doc_codfisc_benef)
     and   rs.soggetto_id=sog.soggetto_id
     and   stato.soggetto_stato_id=rs.soggetto_stato_id
     and   stato.soggetto_stato_code='VALIDO'
     and   sog.data_cancellazione is null
     and   sog.validita_fine is null
     and   rs.data_cancellazione is null
     and   rs.validita_fine is null
     )
     and    not exists
     (
     select 1
     from pagopa_t_riconciliazione_doc doc1
     where doc1.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and   doc1.pagopa_ric_doc_stato_elab!='N'
     and   doc1.data_cancellazione is null
     and   doc1.validita_fine is null
     )
     and    err.ente_proprietario_id=flusso.ente_proprietario_id
     and    err.pagopa_ric_errore_code=PAGOPA_ERR_43
     and    flusso.data_cancellazione is null
     and    flusso.validita_fine is null
     and    doc.data_cancellazione is null
     and    doc.validita_fine is null;
     GET DIAGNOSTICS codResult = ROW_COUNT;

     if coalesce(codResult,0)!=0 then
     	pagoPaCodeErr:=PAGOPA_ERR_43;
        strErrore:=' Soggetto esistente non VALIDO per dati di dettaglio-fatt. ';
     end if;
     codResult:=null;
   end if;

   -- dettagli con codice fiscale indicato
   --  soggetto esistente valido ma non univoco (diversi soggetti per stesso codice fiscale)
   if codResult is null then
 	 strMessaggio:='Gestione scarti di elaborazione PAGOPA_ERR_CODE='||PAGOPA_ERR_44||'.';

     update pagopa_t_riconciliazione_doc doc
     set    pagopa_ric_doc_stato_elab='X',
            pagopa_ric_errore_id=err.pagopa_ric_errore_id,
            data_modifica=clock_timestamp(),
            login_operazione=doc.login_operazione||'-'||loginOperazione||'@ELAB-'||filePagoPaElabId::varchar
     from pagopa_t_elaborazione_flusso flusso,pagopa_d_riconciliazione_errore err
     where  flusso.pagopa_elab_id=filePagoPaElabId
     and    doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and    doc.pagopa_ric_doc_stato_elab='N'
     and    doc.pagopa_ric_doc_flag_dett=true
     and    doc.pagopa_ric_doc_flag_con_dett=false -- 05.06.2019 SIAC-6720
     and    coalesce(doc.pagopa_ric_doc_codfisc_benef,'')!=''
     and    doc.pagopa_ric_doc_subdoc_id is null
     and    exists
     (
     select (case when 1<count(*) then 1 else 0 end)
	 from siac_t_soggetto sog,siac_r_soggetto_stato rs,siac_d_soggetto_stato stato
	 where sog.ente_proprietario_id=enteProprietarioId
	 and   sog.codice_fiscale=upper(doc.pagopa_ric_doc_codfisc_benef)
	 and   rs.soggetto_id=sog.soggetto_id
	 and   stato.soggetto_stato_id=rs.soggetto_stato_id
	 and   stato.soggetto_stato_code='VALIDO'
	 and   sog.data_cancellazione is null
	 and   sog.validita_fine is null
	 and   rs.data_cancellazione is null
	 and   rs.validita_fine is null
	 group by sog.codice_fiscale
	 having count(*)>1
     )
     and    not exists
     (
     select 1
     from pagopa_t_riconciliazione_doc doc1
     where doc1.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and   doc1.pagopa_ric_doc_stato_elab!='N'
     and   doc1.data_cancellazione is null
     and   doc1.validita_fine is null
     )
     and    err.ente_proprietario_id=flusso.ente_proprietario_id
     and    err.pagopa_ric_errore_code=PAGOPA_ERR_44
     and    flusso.data_cancellazione is null
     and    flusso.validita_fine is null
     and    doc.data_cancellazione is null
     and    doc.validita_fine is null;
     GET DIAGNOSTICS codResult = ROW_COUNT;

     if coalesce(codResult,0)!=0 then
     	pagoPaCodeErr:=PAGOPA_ERR_44;
        strErrore:=' Soggetto esistente VALIDO non univoco (cod.fisc) per dati di dettaglio-fatt. ';
     end if;
     codResult:=null;
   end if;

   --  soggetto esistente valido ma non univoco (diversi soggetti per stessa partita iva)
   if codResult is null then
 	 strMessaggio:='Gestione scarti di elaborazione PAGOPA_ERR_CODE='||PAGOPA_ERR_45||'.';

     update pagopa_t_riconciliazione_doc doc
     set    pagopa_ric_doc_stato_elab='X',
            pagopa_ric_errore_id=err.pagopa_ric_errore_id,
            data_modifica=clock_timestamp(),
            login_operazione=doc.login_operazione||'-'||loginOperazione||'@ELAB-'||filePagoPaElabId::varchar
     from pagopa_t_elaborazione_flusso flusso,pagopa_d_riconciliazione_errore err
     where  flusso.pagopa_elab_id=filePagoPaElabId
     and    doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and    doc.pagopa_ric_doc_stato_elab='N'
     and    doc.pagopa_ric_doc_flag_dett=true
     and    doc.pagopa_ric_doc_flag_con_dett=false -- 05.06.2019 SIAC-6720
     and    coalesce(doc.pagopa_ric_doc_codfisc_benef,'')!=''
     and    doc.pagopa_ric_doc_subdoc_id is null
     and    exists
     (
     select (case when 1<count(*) then 1 else 0 end)
	 from siac_t_soggetto sog,siac_r_soggetto_stato rs,siac_d_soggetto_stato stato
	 where sog.ente_proprietario_id=enteProprietarioId
	 and   sog.partita_iva=upper(doc.pagopa_ric_doc_codfisc_benef)
	 and   rs.soggetto_id=sog.soggetto_id
	 and   stato.soggetto_stato_id=rs.soggetto_stato_id
	 and   stato.soggetto_stato_code='VALIDO'
	 and   sog.data_cancellazione is null
	 and   sog.validita_fine is null
	 and   rs.data_cancellazione is null
	 and   rs.validita_fine is null
	 group by sog.partita_iva
	 having count(*)>1
     )
     and    not exists
     (
     select 1
     from pagopa_t_riconciliazione_doc doc1
     where doc1.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and   doc1.pagopa_ric_doc_stato_elab!='N'
     and   doc1.data_cancellazione is null
     and   doc1.validita_fine is null
     )
     and    err.ente_proprietario_id=flusso.ente_proprietario_id
     and    err.pagopa_ric_errore_code=PAGOPA_ERR_45
     and    flusso.data_cancellazione is null
     and    flusso.validita_fine is null
     and    doc.data_cancellazione is null
     and    doc.validita_fine is null;
     GET DIAGNOSTICS codResult = ROW_COUNT;

     if coalesce(codResult,0)!=0 then
     	pagoPaCodeErr:=PAGOPA_ERR_45;
        strErrore:=' Soggetto esistente VALIDO non univoco (p.iva) per dati di dettaglio-fatt. ';
     end if;
     codResult:=null;
   end if;


   -- aggiornare tutti i dettagli con il soggetto_id
   -- (anche il codice del soggetto !! adesso funziona gia' tutto con il codice del soggetto impostato )
   if codResult is null then
 	 strMessaggio:='Aggiornamento dati soggetto su dati di riconciliazione di dettaglio per codice fiscale [pagopa_t_riconciliazione_doc].';

     update pagopa_t_riconciliazione_doc doc
     set    pagopa_ric_doc_soggetto_id=sog.soggetto_id,
            pagopa_ric_doc_codice_benef=sog.soggetto_code,
            data_modifica=clock_timestamp()
     from pagopa_t_elaborazione_flusso flusso,siac_t_soggetto sog, siac_r_soggetto_stato rs,siac_d_soggetto_stato stato
     where  flusso.pagopa_elab_id=filePagoPaElabId
     and    doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and    doc.pagopa_ric_doc_stato_elab='N'
     and    doc.pagopa_ric_doc_flag_dett=true
     and    doc.pagopa_ric_doc_flag_con_dett=false -- 05.06.2019 SIAC-6720
     and    coalesce(doc.pagopa_ric_doc_codfisc_benef,'')!=''
     and    doc.pagopa_ric_doc_subdoc_id is null
     and    doc.pagopa_ric_doc_soggetto_id is null
     and    sog.ente_proprietario_id=enteProprietarioId
	 and    sog.codice_fiscale=upper(doc.pagopa_ric_doc_codfisc_benef)
	 and    rs.soggetto_id=sog.soggetto_id
	 and    stato.soggetto_stato_id=rs.soggetto_stato_id
	 and    stato.soggetto_stato_code='VALIDO'
     and    exists
     (
     select 1
	 from siac_t_soggetto sog1,siac_r_soggetto_stato rs1
	 where sog1.ente_proprietario_id=enteProprietarioId
	 and   sog1.codice_fiscale=upper(doc.pagopa_ric_doc_codfisc_benef)
	 and   rs1.soggetto_id=sog1.soggetto_id
	 and   rs1.soggetto_stato_id=stato.soggetto_stato_id
	 and   sog1.data_cancellazione is null
	 and   sog1.validita_fine is null
	 and   rs1.data_cancellazione is null
	 and   rs1.validita_fine is null
     )
     and    not exists
     (
     select 1
     from pagopa_t_riconciliazione_doc doc1
     where doc1.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and   doc1.pagopa_ric_doc_stato_elab!='N'
     and   doc1.data_cancellazione is null
     and   doc1.validita_fine is null
     )
     and    flusso.data_cancellazione is null
     and    flusso.validita_fine is null
     and    doc.data_cancellazione is null
     and    doc.validita_fine is null
  	 and    sog.data_cancellazione is null
	 and    sog.validita_fine is null
	 and    rs.data_cancellazione is null
	 and    rs.validita_fine is null;
     GET DIAGNOSTICS codResult = ROW_COUNT;

     codResult:=null;
     strMessaggio:='Aggiornamento dati soggetto su dati di riconciliazione di dettaglio per partita iva [pagopa_t_riconciliazione_doc].';
     update pagopa_t_riconciliazione_doc doc
     set    pagopa_ric_doc_soggetto_id=sog.soggetto_id,
            pagopa_ric_doc_codice_benef=sog.soggetto_code,
            data_modifica=clock_timestamp()
     from pagopa_t_elaborazione_flusso flusso,siac_t_soggetto sog, siac_r_soggetto_stato rs,siac_d_soggetto_stato stato
     where  flusso.pagopa_elab_id=filePagoPaElabId
     and    doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and    doc.pagopa_ric_doc_stato_elab='N'
     and    doc.pagopa_ric_doc_flag_dett=true
     and    doc.pagopa_ric_doc_flag_con_dett=false -- 05.06.2019 SIAC-6720
     and    coalesce(doc.pagopa_ric_doc_codfisc_benef,'')!=''
     and    doc.pagopa_ric_doc_subdoc_id is null
     and    doc.pagopa_ric_doc_soggetto_id is null
     and    sog.ente_proprietario_id=enteProprietarioId
	 and    sog.partita_iva=upper(doc.pagopa_ric_doc_codfisc_benef)
	 and    rs.soggetto_id=sog.soggetto_id
	 and    stato.soggetto_stato_id=rs.soggetto_stato_id
	 and    stato.soggetto_stato_code='VALIDO'
     and    exists
     (
     select 1
	 from siac_t_soggetto sog1,siac_r_soggetto_stato rs1
	 where sog1.ente_proprietario_id=enteProprietarioId
	 and   sog1.partita_iva=upper(doc.pagopa_ric_doc_codfisc_benef)
	 and   rs1.soggetto_id=sog1.soggetto_id
	 and   rs1.soggetto_stato_id=stato.soggetto_stato_id
	 and   sog1.data_cancellazione is null
	 and   sog1.validita_fine is null
	 and   rs1.data_cancellazione is null
	 and   rs1.validita_fine is null
     )
     and    not exists
     (
     select 1
     from pagopa_t_riconciliazione_doc doc1
     where doc1.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and   doc1.pagopa_ric_doc_stato_elab!='N'
     and   doc1.data_cancellazione is null
     and   doc1.validita_fine is null
     )
     and    flusso.data_cancellazione is null
     and    flusso.validita_fine is null
     and    doc.data_cancellazione is null
     and    doc.validita_fine is null
  	 and    sog.data_cancellazione is null
	 and    sog.validita_fine is null
	 and    rs.data_cancellazione is null
	 and    rs.validita_fine is null;
     GET DIAGNOSTICS codResult = ROW_COUNT;
     codResult:=null;
   end if;

   --  soggetto_id non aggiornato su dettagli di riconciliazione
   if codResult is null then
 	 strMessaggio:='Gestione scarti di elaborazione PAGOPA_ERR_CODE='||PAGOPA_ERR_46||'.';

     update pagopa_t_riconciliazione_doc doc
     set    pagopa_ric_doc_stato_elab='X',
            pagopa_ric_errore_id=err.pagopa_ric_errore_id,
            data_modifica=clock_timestamp(),
            login_operazione=doc.login_operazione||'-'||loginOperazione||'@ELAB-'||filePagoPaElabId::varchar
     from pagopa_t_elaborazione_flusso flusso,pagopa_d_riconciliazione_errore err
     where  flusso.pagopa_elab_id=filePagoPaElabId
     and    doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and    doc.pagopa_ric_doc_stato_elab='N'
     and    doc.pagopa_ric_doc_flag_con_dett=false -- 05.06.2019 SIAC-6720
     and    doc.pagopa_ric_doc_flag_dett=true
     and    coalesce(doc.pagopa_ric_doc_codfisc_benef,'')!=''
     and    doc.pagopa_ric_doc_subdoc_id is null
     and    doc.pagopa_ric_doc_soggetto_id is null
     and    not exists
     (
     select 1
     from pagopa_t_riconciliazione_doc doc1
     where doc1.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and   doc1.pagopa_ric_doc_stato_elab!='N'
     and   doc1.data_cancellazione is null
     and   doc1.validita_fine is null
     )
     and    err.ente_proprietario_id=flusso.ente_proprietario_id
     and    err.pagopa_ric_errore_code=PAGOPA_ERR_46
     and    flusso.data_cancellazione is null
     and    flusso.validita_fine is null
     and    doc.data_cancellazione is null
     and    doc.validita_fine is null;
     GET DIAGNOSTICS codResult = ROW_COUNT;

     if coalesce(codResult,0)!=0 then
     	pagoPaCodeErr:=PAGOPA_ERR_46;
        strErrore:=' Esistanza  dati di dettaglio-fatt. senza estremi soggetto aggiornato. ';
     end if;
     codResult:=null;
   end if;

   --  importo non valorizzato  su dettagli di riconciliazione
   if codResult is null then
 	 strMessaggio:='Gestione scarti di elaborazione PAGOPA_ERR_CODE='||PAGOPA_ERR_50||'.';

     update pagopa_t_riconciliazione_doc doc
     set    pagopa_ric_doc_stato_elab='X',
            pagopa_ric_errore_id=err.pagopa_ric_errore_id,
            data_modifica=clock_timestamp(),
            login_operazione=doc.login_operazione||'-'||loginOperazione||'@ELAB-'||filePagoPaElabId::varchar
     from pagopa_t_elaborazione_flusso flusso,pagopa_d_riconciliazione_errore err
     where  flusso.pagopa_elab_id=filePagoPaElabId
     and    doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and    doc.pagopa_ric_doc_stato_elab='N'
     and    doc.pagopa_ric_doc_flag_con_dett=false
     and    doc.pagopa_ric_doc_flag_dett=true
     and    coalesce(doc.pagopa_ric_doc_sottovoce_importo,0)=0
     and    doc.pagopa_ric_doc_subdoc_id is null
     and    not exists
     (
     select 1
     from pagopa_t_riconciliazione_doc doc1
     where doc1.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and   doc1.pagopa_ric_doc_stato_elab!='N'
     and   doc1.data_cancellazione is null
     and   doc1.validita_fine is null
     )
     and    err.ente_proprietario_id=flusso.ente_proprietario_id
     and    err.pagopa_ric_errore_code=PAGOPA_ERR_50
     and    flusso.data_cancellazione is null
     and    flusso.validita_fine is null
     and    doc.data_cancellazione is null
     and    doc.validita_fine is null;
     GET DIAGNOSTICS codResult = ROW_COUNT;

     if coalesce(codResult,0)!=0 then
     	pagoPaCodeErr:=PAGOPA_ERR_50;
        strErrore:=' Esistanza  dati di dettaglio-fatt. senza importo valorizzato. ';
     end if;
     codResult:=null;
   end if;

   -- siac-6720 31.05.2019 controlli - fine

   -- siac-6720 31.05.2019 controlli commentare il seguente
   -- soggetto indicato non esistente non esistente
   /*if codResult is null then
 	 strMessaggio:='Gestione scarti di elaborazione PAGOPA_ERR_CODE='||PAGOPA_ERR_34||'.';
     raise notice '2222@@strMessaggio PAGOPA_ERR_34 %',strMessaggio;

     update pagopa_t_riconciliazione_doc doc
     set    pagopa_ric_doc_stato_elab='X',
            pagopa_ric_errore_id=err.pagopa_ric_errore_id,
            data_modifica=clock_timestamp(),
            login_operazione=doc.login_operazione||'-'||loginOperazione||'@ELAB-'||filePagoPaElabId::varchar
     from pagopa_t_elaborazione_flusso flusso,pagopa_d_riconciliazione_errore err
     where  flusso.pagopa_elab_id=filePagoPaElabId
     and    doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and    doc.pagopa_ric_doc_stato_elab='N'
     and    doc.pagopa_ric_doc_subdoc_id is null
     and    doc.pagopa_ric_doc_codice_benef is not null
     and    not exists
     (
     select 1
     from siac_t_soggetto sog
     where sog.ente_proprietario_id=doc.ente_proprietario_id
     and   sog.soggetto_code=doc.pagopa_ric_doc_codice_benef
     and   sog.data_cancellazione is null
     and   sog.validita_fine is null
     )
     and    not exists
     (
     select 1
     from pagopa_t_riconciliazione_doc doc1
     where doc1.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and   doc1.pagopa_ric_doc_stato_elab!='N'
     and   doc1.data_cancellazione is null
     and   doc1.validita_fine is null
     )
     and    err.ente_proprietario_id=flusso.ente_proprietario_id
     and    err.pagopa_ric_errore_code=PAGOPA_ERR_34
     and    flusso.data_cancellazione is null
     and    flusso.validita_fine is null
     and    doc.data_cancellazione is null
     and    doc.validita_fine is null;
     GET DIAGNOSTICS codResult = ROW_COUNT;

     if coalesce(codResult,0)!=0 then
     	pagoPaCodeErr:=PAGOPA_ERR_34;
        strErrore:=' Soggetto indicato non esistente.';
     end if;
     codResult:=null;
   end if;*/

   -- struttura amministrativa indicata non esistente indicato non esistente non esistente
   if codResult is null then
 	 strMessaggio:='Gestione scarti di elaborazione PAGOPA_ERR_CODE='||PAGOPA_ERR_35||'.';
--     raise notice '2222@@strMessaggio PAGOPA_ERR_35 %',strMessaggio;

     update pagopa_t_riconciliazione_doc doc
     set    pagopa_ric_doc_stato_elab='X',
            pagopa_ric_errore_id=err.pagopa_ric_errore_id,
            data_modifica=clock_timestamp(),
            login_operazione=doc.login_operazione||'-'||loginOperazione||'@ELAB-'||filePagoPaElabId::varchar
     from pagopa_t_elaborazione_flusso flusso,pagopa_d_riconciliazione_errore err
     where  flusso.pagopa_elab_id=filePagoPaElabId
     and    doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and    doc.pagopa_ric_doc_stato_elab='N'
     and    doc.pagopa_ric_doc_subdoc_id is null
     and    doc.pagopa_ric_doc_flag_con_dett=false -- 05.06.2019 SIAC-6720
     and    coalesce(doc.pagopa_ric_doc_str_amm,'')!=''
     and    not exists
     (
     select 1
     from siac_t_class c
     where c.ente_proprietario_id=doc.ente_proprietario_id
     and   c.classif_code=doc.pagopa_ric_doc_str_amm
     and   c.classif_tipo_id in (cdcTipoId,cdrTipoId)
     and   c.data_cancellazione is null
     and   date_trunc('DAY',now())>=date_trunc('DAY',c.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(c.validita_fine, date_trunc('DAY',now())))
     )
     and    not exists
     (
     select 1
     from pagopa_t_riconciliazione_doc doc1
     where doc1.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and   doc1.pagopa_ric_doc_stato_elab!='N'
     and   doc1.data_cancellazione is null
     and   doc1.validita_fine is null
     )
     and    err.ente_proprietario_id=flusso.ente_proprietario_id
     and    err.pagopa_ric_errore_code=PAGOPA_ERR_35
     and    flusso.data_cancellazione is null
     and    flusso.validita_fine is null
     and    doc.data_cancellazione is null
     and    doc.validita_fine is null;
     GET DIAGNOSTICS codResult = ROW_COUNT;

     if coalesce(codResult,0)!=0 then
     	pagoPaCodeErr:=PAGOPA_ERR_35;
        strErrore:=' Struttura amministrativa indicata non esistente o non valida.';
     end if;
     codResult:=null;
   end if;

   -- 22.07.2019 Sofia siac-6963 - inizio
   -- accertamento indicato per IPA,COR senza soggetto o soggetto  non esistente
   if codResult is null then
 	 strMessaggio:='Gestione scarti di elaborazione PAGOPA_ERR_CODE='||PAGOPA_ERR_51||'.';
     raise notice '2222@@strMessaggio PAGOPA_ERR_51 %',strMessaggio;

     update pagopa_t_riconciliazione_doc doc
     set    pagopa_ric_doc_stato_elab='X',
            pagopa_ric_errore_id=err.pagopa_ric_errore_id,
            data_modifica=clock_timestamp(),
            login_operazione=doc.login_operazione||'-'||loginOperazione||'@ELAB-'||filePagoPaElabId::varchar
     from pagopa_t_elaborazione_flusso flusso,pagopa_d_riconciliazione_errore err
     where  flusso.pagopa_elab_id=filePagoPaElabId
     and    doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and    doc.pagopa_ric_doc_stato_elab='N'
     and    doc.pagopa_ric_doc_subdoc_id is null
     and    doc.pagopa_ric_doc_flag_con_dett=false
     and    doc.pagopa_ric_doc_flag_dett=false
     and    not exists
     (
      select 1
      from siac_t_movgest mov, siac_d_movgest_tipo tipo,
           siac_t_movgest_ts ts, siac_d_movgest_ts_tipo tipots,
           siac_r_movgest_ts_stato rs, siac_d_movgest_stato stato,
           siac_r_movgest_ts_sog rsog,siac_t_soggetto sog
      where tipo.ente_proprietario_id=doc.ente_proprietario_id
      and   tipo.movgest_tipo_code='A'
      and   mov.movgest_tipo_id=tipo.movgest_tipo_id
      and   mov.bil_id=bilancioId
      and   ts.movgest_id=mov.movgest_id
      and   tipots.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
      and   tipots.movgest_ts_tipo_code='T'
      and   rs.movgest_ts_id=ts.movgest_ts_id
      and   stato.movgest_stato_id=rs.movgest_stato_id
      and   stato.movgest_stato_code='D'
      and   mov.movgest_anno::integer=doc.pagopa_ric_doc_anno_accertamento
      and   mov.movgest_numero::integer=doc.pagopa_ric_doc_num_accertamento
      and   rsog.movgest_ts_id=ts.movgest_ts_id
      and   sog.soggetto_id=rsog.soggetto_id
      and   mov.data_cancellazione is null
      and   mov.validita_fine is null
      and   ts.data_cancellazione is null
      and   ts.validita_fine is null
      and   rs.data_cancellazione is null
      and   rs.validita_fine is null
      and   rsog.data_cancellazione is null
      and   rsog.validita_fine is null
      and   sog.data_cancellazione is null
      and   sog.validita_fine is null
     )
     and    not exists
     (
     select 1
     from pagopa_t_riconciliazione_doc doc1
     where doc1.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and   doc1.pagopa_ric_doc_stato_elab!='N'
     and   doc1.data_cancellazione is null
     and   doc1.validita_fine is null
     )
     and    err.ente_proprietario_id=flusso.ente_proprietario_id
     and    err.pagopa_ric_errore_code=PAGOPA_ERR_51
     and    flusso.data_cancellazione is null
     and    flusso.validita_fine is null
     and    doc.data_cancellazione is null
     and    doc.validita_fine is null;
     GET DIAGNOSTICS codResult = ROW_COUNT;

     if coalesce(codResult,0)!=0 then
     	pagoPaCodeErr:=PAGOPA_ERR_51;
        strErrore:=' Soggetto non indicato su accertamento o non esistente.';
     end if;
     codResult:=null;
   end if;
   -- 22.07.2019 Sofia siac-6963 - fine

--raise notice '@@@@@@@@@@@@@pagoPaCodeErr   %',pagoPaCodeErr;
--raise notice 'codResult   %',codResult;
  ---  aggiornamento di pagopa_t_riconciliazione a partire da pagopa_t_riconciliazione_doc
  ---  per gli scarti prodotti in questa elaborazione
  if codResult is null then
   strMessaggio:='Gestione scarti di elaborazione. Aggiornamento pagopa_t_riconciliazione da pagopa_t_riconciliazione_doc.';
--   raise notice '2222@@strMessaggio   %',strMessaggio;
--   raise notice '@@@@@@@@@@@@@pagoPaCodeErr   %',pagoPaCodeErr;
   update pagopa_t_riconciliazione ric
   set    pagopa_ric_flusso_stato_elab='X',
  	      pagopa_ric_errore_id=doc.pagopa_ric_errore_id,
          data_modifica=clock_timestamp(),
          login_operazione=ric.login_operazione||'-'||loginOperazione||'@ELAB-'||filePagoPaElabId::varchar
   from pagopa_t_elaborazione_flusso flusso,pagopa_t_riconciliazione_doc doc
   where flusso.pagopa_elab_id=filePagoPaElabId
   and   doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
   and   doc.pagopa_ric_doc_stato_elab='X'
   and   doc.login_operazione like '%@ELAB-'|| filePagoPaElabId::varchar||'%'
   and   split_part(doc.login_operazione,'@ELAB-', 2)::integer=filePagoPaElabId --- per elab_id
   and   ric.pagopa_ric_id=doc.pagopa_ric_id;
  end if;
  ---

   if codResult is null then
     strMessaggio:='Verifica esistenza dettagli di riconciliazione da elaborare.';

--     raise notice 'strMessaggio=%',strMessaggio;
     select 1 into codresult
     from  pagopa_t_riconciliazione_doc doc, pagopa_t_elaborazione_flusso flusso
     where flusso.pagopa_elab_id=filePagoPaElabId
     and   doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and   doc.pagopa_ric_doc_stato_elab='N'
     and   doc.pagopa_ric_doc_subdoc_id is null
     and    doc.pagopa_ric_doc_flag_con_dett=false -- 05.06.2019 SIAC-6720
     and   not exists
     (
     select 1
     from pagopa_t_riconciliazione_doc doc1
     where doc1.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and   doc1.pagopa_ric_doc_stato_elab!='N'
     and   doc1.data_cancellazione is null
     and   doc1.validita_fine is null
     )
     and   doc.data_cancellazione is null
     and   doc.validita_fine is null
     and   flusso.data_cancellazione is null
     and   flusso.validita_fine is null;
--    raise notice 'codREsult=%',codResult;
     if codResult is null then
       	pagoPaCodeErr:=PAGOPA_ERR_7;
        strErrore:=' Dati non presenti.';
        codResult:=-1;
        bElabora:=false;
     else codResult:=null;
     end if;
   end if;



   if pagoPaCodeErr is not null then
     -- aggiornare anche pagopa_t_riconciliazione e pagopa_t_riconciliazione_doc
     strmessaggioBck:=strMessaggio;
     strMessaggio:=strMessaggio||' '||strErrore||' Aggiornamento pagopa_t_elaborazione.';
--      raise notice 'strMessaggio=%',strMessaggio;
	 update pagopa_t_elaborazione elab
     set    data_modifica=clock_timestamp(),
            validita_fine=(case when bElabora=false then clock_timestamp() else null end ),
            pagopa_elab_stato_id=statonew.pagopa_elab_stato_id,
            pagopa_elab_errore_id=err.pagopa_ric_errore_id,
		    pagopa_elab_note=substr(upper(strMessaggioFinale||' '||strMessaggio),1,1500) -- 09.10.2019 Sofia
     from  pagopa_d_elaborazione_stato statonew,pagopa_d_riconciliazione_errore err
     where elab.pagopa_elab_id=filePagoPaElabId
     and   statonew.ente_proprietario_id=elab.ente_proprietario_id
     and   statonew.pagopa_elab_stato_code=(case when bElabora=false then ELABORATO_ERRATO_ST else ELABORATO_IN_CORSO_SC_ST end)
     and   err.ente_proprietario_id=statonew.ente_proprietario_id
     and   err.pagopa_ric_errore_code=pagoPaCodeErr
     and   elab.data_cancellazione is null
     and   elab.validita_fine is null;


     strMessaggio:=strmessaggioBck||' '||strErrore||' Aggiornamento siac_t_file_pagopa.';
     update siac_t_file_pagopa file
     set    data_modifica=clock_timestamp(),
            file_pagopa_stato_id=stato.file_pagopa_stato_id,
            file_pagopa_errore_id=err.pagopa_ric_errore_id,
            file_pagopa_note=substr(upper(strMessaggioFinale||' '||strMessaggio),1,1500), -- 09.10.2019 Sofia
            login_operazione=substr(loginOperazione||'-'||file.login_operazione,1,200) -- 09.10.2019 Sofia
     from  pagopa_r_elaborazione_file r,
           siac_d_file_pagopa_stato stato,pagopa_d_riconciliazione_errore err
        where r.pagopa_elab_id=filePagoPaElabId
        and   file.file_pagopa_id=r.file_pagopa_id
        and   stato.ente_proprietario_id=file.ente_proprietario_id
        and   stato.file_pagopa_stato_code=ELABORATO_IN_CORSO_ER_ST
        and   err.ente_proprietario_id=stato.ente_proprietario_id
        and   err.pagopa_ric_errore_code=pagoPaCodeErr
        and   r.data_cancellazione is null
        and   r.validita_fine is null;

     if bElabora= false then
      codiceRisultato:=-1;
      messaggioRisultato:= upper(strMessaggioFinale||' '||strmessaggioBck||' '||strErrore||'.');
      strMessaggioLog:='Uscita fnc_pagopa_t_elaborazione_riconc_esegui - '||messaggioRisultato;
      insert into pagopa_t_elaborazione_log
      (
       pagopa_elab_id,
       pagopa_elab_file_id,
       pagopa_elab_log_operazione,
       ente_proprietario_id,
       login_operazione,
       data_creazione
      )
      values
      (
       filePagoPaElabId,
       null,
       strMessaggioLog,
       enteProprietarioId,
       loginOperazione,
       clock_timestamp()
      );

      return;
     end if;
   end if;


  pagoPaCodeErr:=null;
  strMessaggio:='Inizio inserimento documenti.';
  strMessaggioLog:='Continue fnc_pagopa_t_elaborazione_riconc_esegui - '||strMessaggioFinale||strMessaggio;
  insert into pagopa_t_elaborazione_log
  (
   pagopa_elab_id,
   pagopa_elab_file_id,
   pagopa_elab_log_operazione,
   ente_proprietario_id,
   login_operazione,
   data_creazione
  )
  values
  (
   filePagoPaElabId,
   null,
   strMessaggioLog,
   enteProprietarioId,
   loginOperazione,
   clock_timestamp()
  );

--  raise notice 'strMessaggio=%',strMessaggio;
  for pagoPaFlussoRec in
  (
   with
   pagopa_sogg as
   (
   with
   pagopa as
   (
   select doc.pagopa_ric_doc_codice_benef pagopa_codice_benef,
   		  coalesce(doc.pagopa_ric_doc_soggetto_id,-1) pagopa_soggetto_id, -- 04.06.2019 siac-6720
		  doc.pagopa_ric_doc_str_amm pagopa_str_amm ,
          doc.pagopa_ric_doc_voce_tematica pagopa_voce_tematica,
		  doc.pagopa_ric_doc_voce_code pagopa_voce_code,  doc.pagopa_ric_doc_voce_desc pagopa_voce_desc,
          doc.pagopa_ric_doc_anno_accertamento pagopa_anno_accertamento,
          doc.pagopa_ric_doc_num_accertamento  pagopa_num_accertamento,
          doc.pagopa_ric_doc_tipo_code pagopa_doc_tipo_code, -- siac-6720
          doc.pagopa_ric_doc_tipo_id pagopa_doc_tipo_id -- siac-6720
   from pagopa_t_elaborazione_flusso flusso, pagopa_t_riconciliazione_doc doc
   where flusso.pagopa_elab_id=filePagoPaElabId
   and   doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
   and   doc.pagopa_ric_doc_stato_elab='N'
   and    doc.pagopa_ric_doc_flag_con_dett=false -- 05.06.2019 SIAC-6720
   and   doc.pagopa_ric_doc_subdoc_id is null
   --     26.07.2019 Sofia questo controllo causa
   --     la non elaborazione di flussi che hanno dettagli in scarto
   --     righe dello stesso flusso ma con motivi diversi
   --     possono esserci righe con scarto='X' e scarto='N'
   --     per le update a step successivi che hanno la stessa condizione
   --     in questo modo il flusso non viene elaborato
   --     non tutti i dettagli in scarto vengono trattati ed eventualmente associati
   --     a un motivo di scarto
   --     bisogna tenerne conto quando un  flusso non viene elaborato
   --     e non tutti i dettagli hanno un motivo di scarto segnalato
   and   not exists -- tutti record di un flusso da elaborare e senza scarti o errori
   (
     select 1
     from pagopa_t_riconciliazione_doc doc1
     where doc1.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
     and   doc1.pagopa_ric_doc_stato_elab!='N'
     and   doc1.data_cancellazione is null
     and   doc1.validita_fine is null
   )
   and   doc.data_cancellazione is null
   and   doc.validita_fine is null
   and   flusso.data_cancellazione is null
   and   flusso.validita_fine is null
   group by doc.pagopa_ric_doc_codice_benef,
            coalesce(doc.pagopa_ric_doc_soggetto_id,-1), -- 04.06.2019 siac-6720
			doc.pagopa_ric_doc_str_amm,
            doc.pagopa_ric_doc_voce_tematica,
            doc.pagopa_ric_doc_voce_code,
            doc.pagopa_ric_doc_voce_desc,
            doc.pagopa_ric_doc_anno_accertamento,
            doc.pagopa_ric_doc_num_accertamento,
            doc.pagopa_ric_doc_tipo_code, -- siac-6720
            doc.pagopa_ric_doc_tipo_id -- siac-6720
   ),
   sogg as
   (
   select sog.soggetto_id, sog.soggetto_code,sog.soggetto_desc
   from siac_t_soggetto sog
   where sog.ente_proprietario_id=enteProprietarioId
   and   sog.data_cancellazione is null
   and   sog.validita_fine is null
   )
   select pagopa.*,
          sogg.soggetto_id,
          sogg.soggetto_desc
   from pagopa
---        left join sogg on (pagopa.pagopa_codice_benef=sogg.soggetto_code) -- 04.06.2019 siac-6720
        left join sogg on (pagopa.pagopa_soggetto_id=sogg.soggetto_id)
   ),
   accertamenti_sogg as
   (
   with
   accertamenti as
   (
   	select mov.movgest_anno::integer, mov.movgest_numero::integer,
           mov.movgest_id, ts.movgest_ts_id
    from siac_t_movgest mov , siac_d_movgest_tipo tipo,
         siac_t_movgest_ts ts, siac_d_movgest_ts_tipo tipots,
         siac_r_movgest_ts_stato rs,siac_d_movgest_stato stato
    where tipo.ente_proprietario_id=enteProprietarioId
    and   tipo.movgest_tipo_code='A'
    and   mov.movgest_tipo_id=tipo.movgest_tipo_id
    and   mov.bil_id=bilancioId
    and   ts.movgest_id=mov.movgest_id
    and   tipots.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
    and   tipots.movgest_ts_tipo_code='T'
    and   rs.movgest_ts_id=ts.movgest_ts_id
    and   stato.movgest_stato_id=rs.movgest_stato_id
    and   stato.movgest_stato_code='D'
    and   mov.data_cancellazione is null
    and   mov.validita_fine is null
    and   ts.data_cancellazione is null
    and   ts.validita_fine is null
    and   rs.data_cancellazione is null
    and   rs.validita_fine is null
   ),
   soggetto_acc as
   (
   select sog.soggetto_id, sog.soggetto_code, sog.soggetto_desc,rsog.movgest_ts_id
   from siac_r_movgest_ts_sog rsog, siac_t_soggetto sog
   where sog.ente_proprietario_id=enteProprietarioId
   and   rsog.soggetto_id=sog.soggetto_id
   and   rsog.data_cancellazione is null
   and   rsog.validita_fine is null
   )
   select accertamenti.*,soggetto_acc.soggetto_id, soggetto_acc.soggetto_code,soggetto_acc.soggetto_desc
   from   accertamenti --, soggetto_acc -- 22.07.2019 siac-6963
          left join soggetto_acc on (accertamenti.movgest_ts_id=soggetto_acc.movgest_ts_id) -- 22.07.2019 siac-6963
--   where  accertamenti.movgest_ts_id=soggetto_acc.movgest_ts_id -- 22.07.2019 siac-6963
   )
   select  ( case when pagopa_sogg.soggetto_id is not null then pagopa_sogg.pagopa_codice_benef else accertamenti_sogg.soggetto_code end )  pagopa_soggetto_code,
   		   ( case when pagopa_sogg.soggetto_id is not null then pagopa_sogg.soggetto_desc else accertamenti_sogg.soggetto_desc end ) pagopa_soggetto_desc,
		   ( case when pagopa_sogg.soggetto_id is not null then pagopa_sogg.soggetto_id else accertamenti_sogg.soggetto_id end ) pagopa_soggetto_id,
           pagopa_sogg.pagopa_str_amm,
           pagopa_sogg.pagopa_voce_tematica,
           pagopa_sogg.pagopa_voce_code, pagopa_sogg.pagopa_voce_desc,
           pagopa_sogg.pagopa_doc_tipo_code,pagopa_sogg.pagopa_doc_tipo_id -- siac-6720
   from  pagopa_sogg, accertamenti_sogg
   where pagopa_sogg.pagopa_anno_accertamento=accertamenti_sogg.movgest_anno
   and   pagopa_sogg.pagopa_num_accertamento=accertamenti_sogg.movgest_numero
   group by ( case when pagopa_sogg.soggetto_id is not null then pagopa_sogg.pagopa_codice_benef else accertamenti_sogg.soggetto_code end ),
            ( case when pagopa_sogg.soggetto_id is not null then pagopa_sogg.soggetto_desc else accertamenti_sogg.soggetto_desc end ),
            ( case when pagopa_sogg.soggetto_id is not null then pagopa_sogg.soggetto_id else accertamenti_sogg.soggetto_id end )  ,
            pagopa_sogg.pagopa_str_amm,
            pagopa_sogg.pagopa_voce_tematica,
            pagopa_sogg.pagopa_voce_code, pagopa_sogg.pagopa_voce_desc,
            pagopa_sogg.pagopa_doc_tipo_code,pagopa_sogg.pagopa_doc_tipo_id  -- siac-6720
   order by  ( case when pagopa_sogg.soggetto_id is not null then pagopa_sogg.pagopa_codice_benef else accertamenti_sogg.soggetto_code end ),
   			 pagopa_sogg.pagopa_str_amm,
             pagopa_sogg.pagopa_voce_tematica,
			 pagopa_sogg.pagopa_voce_code, pagopa_sogg.pagopa_voce_desc,
             pagopa_sogg.pagopa_doc_tipo_code,pagopa_sogg.pagopa_doc_tipo_id  -- siac-6720

  )
  loop
   		-- filePagoPaElabId - elaborazione id
        -- filePagoPaId     - file pagopa id
        -- filePagoPaFileXMLId  - file pagopa id XML
        -- pagopa_soggetto_id
        -- pagopa_soggetto_code
        -- pagopa_voce_code
        -- pagopa_voce_desc
        -- pagopa_str_amm

        -- elementi per inserimento documento

        -- inserimento documento
        -- siac_t_doc ok
        -- siac_r_doc_sog ok
        -- siac_r_doc_stato ok
        -- siac_r_doc_class ok struttura amministrativa
        -- siac_r_doc_attr ok
        -- siac_t_registrounico_doc ok
        -- siac_t_subdoc_num ok

        -- siac_t_subdoc ok
        -- siac_r_subdoc_attr ok
        -- siac_r_subdoc_class -- non ce ne sono

        -- siac_r_subdoc_atto_amm ok
        -- siac_r_subdoc_movgest_ts ok
        -- siac_r_subdoc_prov_cassa ok

        dDocImporto:=0;
        strElencoFlussi:=' ';
        dnumQuote:=0;
        bErrore:=false;
		docIUV:=null;

		-- 12.08.2019 Sofia SIAC-6978 - inizio
		if pagoPaFlussoRec.pagopa_doc_tipo_code=DOC_TIPO_FAT then
          strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                        ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc, ' ')
                        ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')||' [siac_t_doc].'
                        ||' Lettura codice IUV.';
          strMessaggioLog:='Continue fnc_pagopa_t_elaborazione_riconc_esegui - '||strMessaggioFinale||strMessaggio;

          insert into pagopa_t_elaborazione_log
          (
           pagopa_elab_id,
           pagopa_elab_file_id,
           pagopa_elab_log_operazione,
           ente_proprietario_id,
           login_operazione,
           data_creazione
          )
          values
          (
           filePagoPaElabId,
           null,
           strMessaggioLog,
           enteProprietarioId,
           loginOperazione,
           clock_timestamp()
          );

          select distinct query.pagopa_ric_doc_iuv into docIUV
          from
          (
             with
             pagopa_sogg as
             (
             with
             pagopa as
             (
             select doc.pagopa_ric_doc_codice_benef pagopa_codice_benef,
                    coalesce(doc.pagopa_ric_doc_soggetto_id,-1) pagopa_soggetto_id, -- 04.06.2019 siac-6720
                    doc.pagopa_ric_doc_str_amm pagopa_str_amm ,
                    doc.pagopa_ric_doc_voce_tematica pagopa_voce_tematica,
                    doc.pagopa_ric_doc_voce_code pagopa_voce_code,  doc.pagopa_ric_doc_voce_desc pagopa_voce_desc,
                    doc.pagopa_ric_doc_anno_accertamento pagopa_anno_accertamento,
                    doc.pagopa_ric_doc_num_accertamento  pagopa_num_accertamento,
                    doc.pagopa_ric_doc_tipo_code pagopa_doc_tipo_code, -- siac-6720
                    doc.pagopa_ric_doc_tipo_id pagopa_doc_tipo_id, -- siac-6720
                    doc.pagopa_ric_doc_iuv pagopa_ric_doc_iuv
             from pagopa_t_elaborazione_flusso flusso, pagopa_t_riconciliazione_doc doc
             where flusso.pagopa_elab_id=filePagoPaElabId
             and   doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
             and   doc.pagopa_ric_doc_stato_elab='N'
             and    doc.pagopa_ric_doc_flag_con_dett=false -- 05.06.2019 SIAC-6720
             and   doc.pagopa_ric_doc_subdoc_id is null
             --     26.07.2019 Sofia questo controllo causa
             --     la non elaborazione di flussi che hanno dettagli in scarto
             --     righe dello stesso flusso ma con motivi diversi
             --     possono esserci righe con scarto='X' e scarto='N'
             --     per le update a step successivi che hanno la stessa condizione
             --     in questo modo il flusso non viene elaborato
             --     non tutti i dettagli in scarto vengono trattati ed eventualmente associati
             --     a un motivo di scarto
             --     bisogna tenerne conto quando un  flusso non viene elaborato
             --     e non tutti i dettagli hanno un motivo di scarto segnalato
             and   not exists -- tutti record di un flusso da elaborare e senza scarti o errori
             (
               select 1
               from pagopa_t_riconciliazione_doc doc1
               where doc1.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
               and   doc1.pagopa_ric_doc_stato_elab!='N'
               and   doc1.data_cancellazione is null
               and   doc1.validita_fine is null
             )
             and   doc.data_cancellazione is null
             and   doc.validita_fine is null
             and   flusso.data_cancellazione is null
             and   flusso.validita_fine is null
             group by doc.pagopa_ric_doc_codice_benef,
                      coalesce(doc.pagopa_ric_doc_soggetto_id,-1), -- 04.06.2019 siac-6720
                      doc.pagopa_ric_doc_str_amm,
                      doc.pagopa_ric_doc_voce_tematica,
                      doc.pagopa_ric_doc_voce_code,
                      doc.pagopa_ric_doc_voce_desc,
                      doc.pagopa_ric_doc_anno_accertamento,
                      doc.pagopa_ric_doc_num_accertamento,
                      doc.pagopa_ric_doc_tipo_code, -- siac-6720
                      doc.pagopa_ric_doc_tipo_id, -- siac-6720
                      doc.pagopa_ric_doc_iuv
             ),
             sogg as
             (
             select sog.soggetto_id, sog.soggetto_code,sog.soggetto_desc
             from siac_t_soggetto sog
             where sog.ente_proprietario_id=enteProprietarioId
             and   sog.data_cancellazione is null
             and   sog.validita_fine is null
             )
             select pagopa.*,
                    sogg.soggetto_id,
                    sogg.soggetto_desc
             from pagopa
          ---        left join sogg on (pagopa.pagopa_codice_benef=sogg.soggetto_code) -- 04.06.2019 siac-6720
                  left join sogg on (pagopa.pagopa_soggetto_id=sogg.soggetto_id)
             ),
             accertamenti_sogg as
             (
             with
             accertamenti as
             (
              select mov.movgest_anno::integer, mov.movgest_numero::integer,
                     mov.movgest_id, ts.movgest_ts_id
              from siac_t_movgest mov , siac_d_movgest_tipo tipo,
                   siac_t_movgest_ts ts, siac_d_movgest_ts_tipo tipots,
                   siac_r_movgest_ts_stato rs,siac_d_movgest_stato stato
              where tipo.ente_proprietario_id=enteProprietarioId
              and   tipo.movgest_tipo_code='A'
              and   mov.movgest_tipo_id=tipo.movgest_tipo_id
              and   mov.bil_id=bilancioId
              and   ts.movgest_id=mov.movgest_id
              and   tipots.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
              and   tipots.movgest_ts_tipo_code='T'
              and   rs.movgest_ts_id=ts.movgest_ts_id
              and   stato.movgest_stato_id=rs.movgest_stato_id
              and   stato.movgest_stato_code='D'
              and   mov.data_cancellazione is null
              and   mov.validita_fine is null
              and   ts.data_cancellazione is null
              and   ts.validita_fine is null
              and   rs.data_cancellazione is null
              and   rs.validita_fine is null
             ),
             soggetto_acc as
             (
             select sog.soggetto_id, sog.soggetto_code, sog.soggetto_desc,rsog.movgest_ts_id
             from siac_r_movgest_ts_sog rsog, siac_t_soggetto sog
             where sog.ente_proprietario_id=enteProprietarioId
             and   rsog.soggetto_id=sog.soggetto_id
             and   rsog.data_cancellazione is null
             and   rsog.validita_fine is null
             )
             select accertamenti.*,soggetto_acc.soggetto_id, soggetto_acc.soggetto_code,soggetto_acc.soggetto_desc
             from   accertamenti --, soggetto_acc -- 22.07.2019 siac-6963
                    left join soggetto_acc on (accertamenti.movgest_ts_id=soggetto_acc.movgest_ts_id) -- 22.07.2019 siac-6963
          --   where  accertamenti.movgest_ts_id=soggetto_acc.movgest_ts_id -- 22.07.2019 siac-6963
             )
             select  ( case when pagopa_sogg.soggetto_id is not null then pagopa_sogg.pagopa_codice_benef else accertamenti_sogg.soggetto_code end )  pagopa_soggetto_code,
                     ( case when pagopa_sogg.soggetto_id is not null then pagopa_sogg.soggetto_desc else accertamenti_sogg.soggetto_desc end ) pagopa_soggetto_desc,
                     ( case when pagopa_sogg.soggetto_id is not null then pagopa_sogg.soggetto_id else accertamenti_sogg.soggetto_id end ) pagopa_soggetto_id,
                     pagopa_sogg.pagopa_str_amm,
                     pagopa_sogg.pagopa_voce_tematica,
                     pagopa_sogg.pagopa_voce_code, pagopa_sogg.pagopa_voce_desc,
                     pagopa_sogg.pagopa_doc_tipo_code,pagopa_sogg.pagopa_doc_tipo_id, -- siac-6720,
                     pagopa_sogg.pagopa_ric_doc_iuv
             from  pagopa_sogg, accertamenti_sogg
             where pagopa_sogg.pagopa_anno_accertamento=accertamenti_sogg.movgest_anno
             and   pagopa_sogg.pagopa_num_accertamento=accertamenti_sogg.movgest_numero
             group by ( case when pagopa_sogg.soggetto_id is not null then pagopa_sogg.pagopa_codice_benef else accertamenti_sogg.soggetto_code end ),
                      ( case when pagopa_sogg.soggetto_id is not null then pagopa_sogg.soggetto_desc else accertamenti_sogg.soggetto_desc end ),
                      ( case when pagopa_sogg.soggetto_id is not null then pagopa_sogg.soggetto_id else accertamenti_sogg.soggetto_id end )  ,
                      pagopa_sogg.pagopa_str_amm,
                      pagopa_sogg.pagopa_voce_tematica,
                      pagopa_sogg.pagopa_voce_code, pagopa_sogg.pagopa_voce_desc,
                      pagopa_sogg.pagopa_doc_tipo_code,pagopa_sogg.pagopa_doc_tipo_id,  -- siac-6720
                      pagopa_sogg.pagopa_ric_doc_iuv
             order by  ( case when pagopa_sogg.soggetto_id is not null then pagopa_sogg.pagopa_codice_benef else accertamenti_sogg.soggetto_code end ),
                       pagopa_sogg.pagopa_str_amm,
                       pagopa_sogg.pagopa_voce_tematica,
                       pagopa_sogg.pagopa_voce_code, pagopa_sogg.pagopa_voce_desc,
                       pagopa_sogg.pagopa_doc_tipo_code,pagopa_sogg.pagopa_doc_tipo_id
          )
          query
          where query.pagopa_doc_tipo_id=pagoPaFlussoRec.pagopa_doc_tipo_id
          and   coalesce(query.pagopa_voce_tematica,'')=coalesce(pagoPaFlussoRec.pagopa_voce_tematica,coalesce(query.pagopa_voce_tematica,''))
          and   query.pagopa_voce_code=pagoPaFlussoRec.pagopa_voce_code
          and   coalesce(query.pagopa_voce_desc,'')=coalesce(pagoPaFlussoRec.pagopa_voce_desc,coalesce(query.pagopa_voce_desc,''))
          and   coalesce(query.pagopa_str_amm,'')=coalesce(pagoPaFlussoRec.pagopa_str_amm,coalesce(query.pagopa_str_amm,''))
          and   query.pagopa_soggetto_id=pagoPaFlussoRec.pagopa_soggetto_id;

       	if coalesce(docIUV,'')='' or docIUV is null then
        	bErrore:=true;
            strMessaggio:=strMessaggio||' Lettura non riuscita.';
        end if;

       end if;
 	   -- 12.08.2019 Sofia SIAC-6978 - fine


       if bErrore=false then
		strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                      ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc, ' ')
                      ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')||' [siac_t_doc].';
		strMessaggioLog:='Continue fnc_pagopa_t_elaborazione_riconc_esegui - '||strMessaggioFinale||strMessaggio;

        insert into pagopa_t_elaborazione_log
        (
         pagopa_elab_id,
         pagopa_elab_file_id,
         pagopa_elab_log_operazione,
         ente_proprietario_id,
         login_operazione,
         data_creazione
        )
        values
        (
         filePagoPaElabId,
         null,
         strMessaggioLog,
         enteProprietarioId,
         loginOperazione,
         clock_timestamp()
        );

		docId:=null;

        -- 12.06.2019 SIAC-6720
--        nProgressivo:=nProgressivo+1;
        nProgressivoTemp:=null;
        isDocIPA:=false;
        -- 13.09.2019 Sofia SIAC-7034
        numeroFattura:=null;

        if pagoPaFlussoRec.pagopa_doc_tipo_code=DOC_TIPO_FAT and docTipoFatNumAutom is not null then
        	nProgressivoFat:=nProgressivoFat+1;
            nProgressivoTemp:=nProgressivoFat;
            -- 13.09.2019 Sofia SIAC-7034
            numeroFattura:= pagoPaFlussoRec.pagopa_voce_code||'-'||nProgressivoTemp::varchar;
        end if;
        if pagoPaFlussoRec.pagopa_doc_tipo_code=DOC_TIPO_COR and docTipoCorNumAutom is not null then
        	nProgressivoCor:=nProgressivoCor+1;
            nProgressivoTemp:=nProgressivoCor;
        end if;
        if nProgressivoTemp is null then
	          nProgressivo:=nProgressivo+1;
              nProgressivoTemp:=nProgressivo;
              isDocIPA:=true;
        end if;

        -- 13.09.2019 Sofia SIAC-7034
        if numeroFattura is null then
           numeroFattura:= pagoPaFlussoRec.pagopa_voce_code||' '
                          ||extract ( day from dataElaborazione)||'-'||lpad(extract ( month from dataElaborazione)::varchar,2,'0')||'-'||extract ( year from dataElaborazione)||' '
                          ||' '||nProgressivoTemp::varchar;
        end if;



--        raise notice 'pagoPaFlussoRec.pagopa_doc_tipo_code=%',pagoPaFlussoRec.pagopa_doc_tipo_code;
--        raise notice 'isDocIPA=%',isDocIPA;
--		raise notice 'nProgressivo=%',nProgressivo;
--        raise notice 'nProgressivoCor=%',nProgressivoCor;
--        raise notice 'nProgressivoFat=%',nProgressivoFat;
		-- siac_t_doc
        insert into siac_t_doc
        (
        	doc_anno,
		    doc_numero,
			doc_desc,
		    doc_importo,
		    doc_data_emissione, -- dataElaborazione
			doc_data_scadenza,  -- dataSistema
		    doc_tipo_id,
		    codbollo_id,
		    validita_inizio,
		    ente_proprietario_id,
		    login_operazione,
		    login_creazione,
            login_modifica,
			pcccod_id, -- null ??
	        pccuff_id,
            IUV -- null ??  -- 12.08.2019 Sofia SIAC-6978 - fine
        )
        select annoBilancio,
--               pagoPaFlussoRec.pagopa_voce_code||' '||dataElaborazione||' '||nProgressivoTemp::varchar,
               numeroFattura,-- 13.09.2019 Sofia SIAC-7034
               upper('Incassi '
               		 ||substring(coalesce(pagoPaFlussoRec.pagopa_voce_tematica,' '),1,30)||' '
                     ||pagoPaFlussoRec.pagopa_voce_code||' '
                     ||substring(coalesce(pagoPaFlussoRec.pagopa_voce_desc,' '),1,30) ||' '||strElencoFlussi),
			   dDocImporto,
               dataElaborazione,
               dataElaborazione,
--			   docTipoId, siac-6720 28.05.2019 Sofia
               pagoPaFlussoRec.pagopa_doc_tipo_id, -- siac-6720 28.05.2019 Sofia
               codBolloId,
               clock_timestamp(),
               enteProprietarioId,
               loginOperazione,
               loginOperazione,
               loginOperazione,
               null,
               null,
               docIUV   -- 12.08.2019 Sofia SIAC-6978 - fine
        returning doc_id into docId;
--	    raise notice 'docid=%',docId;
		if docId is null then
        	bErrore:=true;
            strMessaggio:=strMessaggio||' Inserimento non riuscito.';
        end if;
       end if;


	   if bErrore=false then
		 codResult:=null;
	     strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                      ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ')
                      ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')||' [siac_r_doc_sog].';
		 -- siac_r_doc_sog
         insert into siac_r_doc_sog
         (
        	doc_id,
            soggetto_id,
            validita_inizio,
            login_operazione,
            ente_proprietario_id
         )
         select  docId,
                 pagoPaFlussoRec.pagopa_soggetto_id,
                 clock_timestamp(),
                 loginOperazione,
                 enteProprietarioId
         returning  doc_sog_id into codResult;

         if codResult is null then
         	bErrore:=true;
            strMessaggio:=strMessaggio||' Inserimento non riuscito.';

         end if;
        end if;

	    if bErrore=false then
         codResult:=null;
	     strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                      ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ')
                      ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')||' [siac_r_doc_stato].';
         insert into siac_r_doc_stato
         (
        	doc_id,
            doc_stato_id,
            validita_inizio,
            login_operazione,
            ente_proprietario_id
         )
         select docId,
                docStatoValId,
                clock_timestamp(),
                loginOperazione,
                enteProprietarioId
         returning doc_stato_r_id into codResult;
		 if codResult is null then
         	bErrore:=true;
            strMessaggio:=strMessaggio||' Inserimento non riuscito.';
         end if;
		end if;

        if bErrore=false then
         -- siac_r_doc_attr
         strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                      ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ')
                      ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                      ||'. Attributo '||ANNO_REPERTORIO_ATTR||' [siac_r_doc_attr].';

         -- anno_repertorio
         codResult:=null;
         insert into siac_r_doc_attr
         (
        	doc_id,
            attr_id,
            testo,
            login_operazione,
            validita_inizio,
            ente_proprietario_id
         )
         select docId,
                a.attr_id,
         	    --annoBilancio::varchar,
                NULL,
                loginOperazione,
                clock_timestamp(),
                a.ente_proprietario_id
         from siac_t_attr a
         where a.ente_proprietario_id=enteProprietarioid
         and   a.attr_code=ANNO_REPERTORIO_ATTR
         returning doc_attr_id into codResult;
         if codResult is null then
         	bErrore:=true;
            strMessaggio:=strMessaggio||' Inserimento non riuscito.';
         end if;
        end if;

		if bErrore=false then

	     strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                      ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ')
                      ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                      ||'. Attributo '||NUM_REPERTORIO_ATTR||' [siac_r_doc_attr].';

         -- num_repertorio
         codResult:=null;
         insert into siac_r_doc_attr
         (
        	doc_id,
            attr_id,
            testo,
            login_operazione,
            validita_inizio,
            ente_proprietario_id
         )
         select docId,
                a.attr_id,
         	    null,
                loginOperazione,
                clock_timestamp(),
                a.ente_proprietario_id
         from siac_t_attr a
         where a.ente_proprietario_id=enteProprietarioid
         and   a.attr_code=NUM_REPERTORIO_ATTR
         returning doc_attr_id into codResult;
         if codResult is null then
	        bErrore:=true;
            strMessaggio:=strMessaggio||' Inserimento non riuscito.';
         end if;
        end if;

		if bErrore=false then
         strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                      ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ')
                      ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                      ||'. Attributo '||DATA_REPERTORIO_ATTR||' [siac_r_doc_attr].';
		 -- data_repertorio
         codResult:=null;
         insert into siac_r_doc_attr
         (
        	doc_id,
            attr_id,
            testo,
            login_operazione,
            validita_inizio,
            ente_proprietario_id
         )
         select docId,
                a.attr_id,
                null,
--        	    extract( 'day' from now())::varchar||'/'||
--               lpad(extract( 'month' from now())::varchar,2,'0')||'/'||
--               extract( 'year' from now())::varchar,
                loginOperazione,
                clock_timestamp(),
                a.ente_proprietario_id
         from siac_t_attr a
         where a.ente_proprietario_id=enteProprietarioid
         and   a.attr_code=DATA_REPERTORIO_ATTR
         returning doc_attr_id into codResult;
         if codResult is null then
	        bErrore:=true;
            strMessaggio:=strMessaggio||' Inserimento non riuscito.';
         end if;
        end if;

        if bErrore=false then
		 -- registro_repertorio
         strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                      ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ')
                      ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                      ||'. Attributo '||REG_REPERTORIO_ATTR||' [siac_r_doc_attr].';
         codResult:=null;
         insert into siac_r_doc_attr
         (
        	doc_id,
            attr_id,
            testo,
            login_operazione,
            validita_inizio,
            ente_proprietario_id
         )
         select docId,
                a.attr_id,
                null,
                loginOperazione,
                clock_timestamp(),
                a.ente_proprietario_id
         from siac_t_attr a
         where a.ente_proprietario_id=enteProprietarioid
         and   a.attr_code=REG_REPERTORIO_ATTR
         returning doc_attr_id into codResult;
         if codResult is null then
	        bErrore:=true;
            strMessaggio:=strMessaggio||' Inserimento non riuscito.';
         end if;
        end if;

		if bErrore=false then
		 -- arrotondamento
         strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                      ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc, ' ')
                      ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                      ||'. Attributo '||ARROTONDAMENTO_ATTR||' [siac_r_doc_attr].';
         codResult:=null;
         insert into siac_r_doc_attr
         (
        	doc_id,
            attr_id,
            numerico,
            login_operazione,
            validita_inizio,
            ente_proprietario_id
         )
         select docId,
                a.attr_id,
                0,
                loginOperazione,
                clock_timestamp(),
                a.ente_proprietario_id
         from siac_t_attr a
         where a.ente_proprietario_id=enteProprietarioid
         and   a.attr_code=ARROTONDAMENTO_ATTR
         returning doc_attr_id into codResult;
         if codResult is null then
         	bErrore:=true;
            strMessaggio:=strMessaggio||' Inserimento non riuscito.';
         end if;
        end if;

		/*if bErrore=false then
         -- causale_sospensione
 		 -- data_sospensione
 		 -- data_riattivazione
   		 -- dataScadenzaDopoSospensione
         strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                      ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ' )
                      ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                      ||'. Attributi sospensione [siac_r_doc_attr].';
         codResult:=null;
         insert into siac_r_doc_attr
         (
        	doc_id,
            attr_id,
            testo,
            login_operazione,
            validita_inizio,
            ente_proprietario_id
         )
         select docId,
                a.attr_id,
                null,
                loginOperazione,
                clock_timestamp(),
                a.ente_proprietario_id
         from siac_t_attr a
         where a.ente_proprietario_id=enteProprietarioid
         and   a.attr_code in (CAUS_SOSPENSIONE_ATTR,DATA_SOSPENSIONE_ATTR,DATA_RIATTIVAZIONE_ATTR/*,DATA_SCAD_SOSP_ATTR*/);
         GET DIAGNOSTICS codResult = ROW_COUNT;
         if coalesce(codResult,0)=0 then
         	bErrore:=true;
            strMessaggio:=strMessaggio||' Inserimento non riuscito.';
         end if;
        end if;*/

        if bErrore=false then
		 -- terminepagamento
		 strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                      ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ')
                      ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                      ||'. Attributo '||TERMINE_PAG_ATTR||' [siac_r_doc_attr].';
         codResult:=null;
         insert into siac_r_doc_attr
         (
        	doc_id,
            attr_id,
            numerico,
            login_operazione,
            validita_inizio,
            ente_proprietario_id
         )
         select docId,
                a.attr_id,
                TERMINE_PAG_DEF,
                loginOperazione,
                clock_timestamp(),
                a.ente_proprietario_id
         from siac_t_attr a
         where a.ente_proprietario_id=enteProprietarioid
         and   a.attr_code=TERMINE_PAG_ATTR
         returning doc_attr_id into codResult;
         if codResult is null then
	        bErrore:=true;
            strMessaggio:=strMessaggio||' Inserimento non riuscito.';
         end if;
        end if;

		/*if bErrore=false then
	     -- notePagamentoIncasso
    	 -- dataOperazionePagamentoIncasso
         strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                      ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc, ' ')
                      ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                      ||'. Attributi pagamento incasso [siac_r_doc_attr].';
         codResult:=null;
         insert into siac_r_doc_attr
         (
        	doc_id,
            attr_id,
            testo,
            login_operazione,
            validita_inizio,
            ente_proprietario_id
         )
         select docId,
                a.attr_id,
                null,
                loginOperazione,
                clock_timestamp(),
                a.ente_proprietario_id
         from siac_t_attr a
         where a.ente_proprietario_id=enteProprietarioid
         and   a.attr_code in (NOTE_PAG_INC_ATTR,DATA_PAG_INC_ATTR);
         GET DIAGNOSTICS codResult = ROW_COUNT;
         if coalesce(codResult,0)=0 then
         	bErrore:=true;
            strMessaggio:=strMessaggio||' Inserimento non riuscito.';
         end if;
        end if;*/

		if bErrore=false then
         -- flagAggiornaQuoteDaElenco
		 -- flagSenzaNumero
		 -- flagDisabilitaRegistrazioneResidui
		 -- flagPagataIncassata
         strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                      ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ' )
                      ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                      ||'. Attributi flag [siac_r_doc_attr].';
         codResult:=null;
         insert into siac_r_doc_attr
         (
        	doc_id,
            attr_id,
            boolean,
            login_operazione,
            validita_inizio,
            ente_proprietario_id
         )
         select docId,
                a.attr_id,
                'N',
                loginOperazione,
                clock_timestamp(),
                a.ente_proprietario_id
         from siac_t_attr a
         where a.ente_proprietario_id=enteProprietarioid
--         and   a.attr_code in (/*FL_AGG_QUOTE_ELE_ATTR,*/FL_SENZA_NUM_ATTR,FL_REG_RES_ATTR);--,FL_PAGATA_INC_ATTR);
         and   a.attr_code=FL_REG_RES_ATTR;

         GET DIAGNOSTICS codResult = ROW_COUNT;
         if coalesce(codResult,0)=0 then
	        bErrore:=true;
            strMessaggio:=strMessaggio||' Inserimento non riuscito.';
         end if;
        end if;

		if bErrore=false then
		 -- codiceFiscalePignorato
		 -- dataRicezionePortale

		 strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                      ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ' )
                      ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                      ||'. Attributi vari [siac_r_doc_attr].';
         codResult:=null;
         insert into siac_r_doc_attr
         (
        	doc_id,
            attr_id,
            testo,
            login_operazione,
            validita_inizio,
            ente_proprietario_id
         )
         select docId,
                a.attr_id,
                null,
                loginOperazione,
                clock_timestamp(),
                a.ente_proprietario_id
         from siac_t_attr a
         where a.ente_proprietario_id=enteProprietarioid
--         and   a.attr_code in (COD_FISC_PIGN_ATTR,DATA_RIC_PORTALE_ATTR);
         and   a.attr_code=DATA_RIC_PORTALE_ATTR;
         GET DIAGNOSTICS codResult = ROW_COUNT;
         if coalesce(codResult,0)=0 then
	        bErrore:=true;
            strMessaggio:=strMessaggio||' Inserimento non riuscito.';
         end if;
        end if;
        if bErrore=false then
		 -- siac_r_doc_class
         if coalesce(pagoPaFlussoRec.pagopa_str_amm ,'')!='' then
            strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                         ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc, ' ' )
                         ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                         ||'. Inserimento coll. struttura amministrativa [siac_r_doc_class]'
                         ||'. Verifica esistenza come CDC.';

        	codResult:=null;
            select c.classif_id into codResult
            from siac_t_class c
            where c.classif_tipo_id=cdcTipoId
            and   c.classif_code=pagoPaFlussoRec.pagopa_str_amm
            and   c.data_cancellazione is null
            and   date_trunc('DAY',now())>=date_trunc('DAY',c.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(c.validita_fine,date_trunc('DAY',now())));
            if codResult is null then
                strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                         ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ' )
                         ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                         ||'. Inserimento coll. struttura amministrativa  [siac_r_doc_class]'
                         ||'. Verifica esistenza come CDR.';
	            select c.classif_id into codResult
    	        from siac_t_class c
        	    where c.classif_tipo_id=cdrTipoId
	           	and   c.classif_code=pagoPaFlussoRec.pagopa_str_amm
    	        and   c.data_cancellazione is null
        	    and   date_trunc('DAY',now())>=date_trunc('DAY',c.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(c.validita_fine,date_trunc('DAY',now())));
            end if;
            if codResult is not null then
               codResult1:=codResult;
               codResult:=null;
	           strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                         ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ' )
                         ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                         ||'. Inserimento coll. struttura amministrativa  [siac_r_doc_class].';

            	insert into siac_r_doc_class
                (
                	doc_id,
                    classif_id,
                    validita_inizio,
                    login_operazione,
                    ente_proprietario_id
                )
                values
                (
                	docId,
                    codResult1,
                    clock_timestamp(),
                    loginOperazione,
                    enteProprietarioId
                )
                returning doc_classif_id into codResult;

                if codResult is null then
                	bErrore:=true;
		            strMessaggio:=strMessaggio||' Inserimento non riuscito.';
                end if;
            end if;
         end if;
        end if;

		if bErrore =false then
		 --  siac_t_registrounico_doc
         strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                         ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ' )
                         ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                         ||'. Inserimento registro unico documento [siac_t_registrounico_doc].';

      	 codResult:=null;
         insert into siac_t_registrounico_doc
         (
        	rudoc_registrazione_anno,
 			rudoc_registrazione_numero,
			rudoc_registrazione_data,
			doc_id,
            login_operazione,
            validita_inizio,
            ente_proprietario_id
         )
         select num.rudoc_registrazione_anno,
                num.rudoc_registrazione_numero+1,
                clock_timestamp(),
                docId,
                loginOperazione,
                clock_timestamp(),
                num.ente_proprietario_id
         from siac_t_registrounico_doc_num num
         where num.ente_proprietario_id=enteProprietarioId
         and   num.rudoc_registrazione_anno=annoBilancio
         and   num.data_cancellazione is null
         and   date_trunc('DAY',now())>=date_trunc('DAY',num.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(num.validita_fine,date_trunc('DAY',now())))
         returning rudoc_id into codResult;
         if codResult is null then
	        bErrore:=true;
            strMessaggio:=strMessaggio||' Inserimento non riuscito.';
         end if;
         if bErrore=false then
            codResult:=null;
         	strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                         ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ' )
                         ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                         ||'. Aggiornamento registro unico documento [siac_t_registrounico_doc_num].';
         	update siac_t_registrounico_doc_num num
            set    rudoc_registrazione_numero=num.rudoc_registrazione_numero+1,
                   data_modifica=clock_timestamp()
        	where num.ente_proprietario_id=enteProprietarioId
	        and   num.rudoc_registrazione_anno=annoBilancio
         	and   num.data_cancellazione is null
	        and   date_trunc('DAY',now())>=date_trunc('DAY',num.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(num.validita_fine,date_trunc('DAY',now())))
            returning num.rudoc_num_id into codResult;
            if codResult is null  then
               bErrore:=true;
               strMessaggio:=strMessaggio||' Aggiornamento non riuscito.';
            end if;
         end if;
        end if;

		if bErrore =false then
         codResult:=null;
		 --  siac_t_doc_num
         strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                         ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ' )
                         ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                         ||'. Aggiornamento progressivi documenti [siac_t_doc_num].';
         --- 12.06.2019 Siac-6720
--         raise notice 'pagoPaFlussoRec.pagopa_doc_tipo_code2=%',pagoPaFlussoRec.pagopa_doc_tipo_code;
         if isDocIPA=true then
           update siac_t_doc_num num
           set    doc_numero=num.doc_numero+1,
                  data_modifica=clock_timestamp()
           where  num.ente_proprietario_id=enteProprietarioid
           and    num.doc_anno=annoBilancio
           and    num.doc_tipo_id=docTipoId
           returning num.doc_num_id into codResult;
         else
           update siac_t_doc_num num
           set    doc_numero=num.doc_numero+1,
                  data_modifica=clock_timestamp()
           where  num.ente_proprietario_id=enteProprietarioid
           and    num.doc_anno=annoBilancio
           and    num.doc_tipo_id =pagoPaFlussoRec.pagopa_doc_tipo_id
           returning num.doc_num_id into codResult;
         end if;
         if codResult is null then
         	 bErrore:=true;
             strMessaggio:=strMessaggio||' Aggiornamento non riuscito.';
         end if;
        end if;

        if bErrore=true then
            strMessaggioLog:='Continue fnc_pagopa_t_elaborazione_riconc_esegui - '||strMessaggioFinale||strMessaggio;
        end if;


		strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                         ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc, ' ')
                         ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                         ||'. Inserimento quote documento.';
--        raise notice 'strMessaggio=%',strMessaggio;
		if bErrore=false then
			strMessaggioLog:='Continue fnc_pagopa_t_elaborazione_riconc_esegui - '||strMessaggioFinale||strMessaggio;
	    end if;

        insert into pagopa_t_elaborazione_log
        (
         pagopa_elab_id,
         pagopa_elab_file_id,
         pagopa_elab_log_operazione,
         ente_proprietario_id,
         login_operazione,
         data_creazione
        )
        values
        (
         filePagoPaElabId,
         null,
         strMessaggioLog,
         enteProprietarioId,
         loginOperazione,
         clock_timestamp()
        );

        for pagoPaFlussoQuoteRec in
  		(
  	     with
           pagopa_sogg as
		   (
           with
		   pagopa as
		   (
		   select doc.pagopa_ric_doc_codice_benef pagopa_codice_benef,
			      doc.pagopa_ric_doc_str_amm pagopa_str_amm,
                  doc.pagopa_ric_doc_voce_tematica pagopa_voce_tematica,
           		  doc.pagopa_ric_doc_voce_code pagopa_voce_code,  doc.pagopa_ric_doc_voce_desc pagopa_voce_desc,
                  doc.pagopa_ric_doc_sottovoce_code pagopa_sottovoce_code, doc.pagopa_ric_doc_sottovoce_desc pagopa_sottovoce_desc,
                  flusso.pagopa_elab_flusso_anno_provvisorio pagopa_anno_provvisorio,
                  flusso.pagopa_elab_flusso_num_provvisorio pagopa_num_provvisorio,
                  flusso.pagopa_elab_ric_flusso_id pagopa_flusso_id,
                  flusso.pagopa_elab_flusso_nome_mittente pagopa_flusso_nome_mittente,
        		  doc.pagopa_ric_doc_anno_accertamento pagopa_anno_accertamento,
		          doc.pagopa_ric_doc_num_accertamento  pagopa_num_accertamento,
                  doc.pagopa_ric_doc_sottovoce_importo pagopa_sottovoce_importo
		   from pagopa_t_elaborazione_flusso flusso, pagopa_t_riconciliazione_doc doc
		   where flusso.pagopa_elab_id=filePagoPaElabId
		   and   doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
           and   doc.pagopa_ric_doc_tipo_id=pagoPaFlussoRec.pagopa_doc_tipo_id -- 30.05.2019 siac-6720
           and   coalesce(doc.pagopa_ric_doc_voce_tematica,'')=coalesce(pagoPaFlussoRec.pagopa_voce_tematica,coalesce(doc.pagopa_ric_doc_voce_tematica,''))
           and   doc.pagopa_ric_doc_voce_code=pagoPaFlussoRec.pagopa_voce_code
           and   coalesce(doc.pagopa_ric_doc_voce_desc,'')=coalesce(pagoPaFlussoRec.pagopa_voce_desc,coalesce(doc.pagopa_ric_doc_voce_desc,''))
           and   coalesce(doc.pagopa_ric_doc_str_amm,'')=coalesce(pagoPaFlussoRec.pagopa_str_amm,coalesce(doc.pagopa_ric_doc_str_amm,''))
		   and   doc.pagopa_ric_doc_stato_elab='N'
           and   doc.pagopa_ric_doc_flag_con_dett=false -- 05.06.2019 SIAC-6720
		   and   doc.pagopa_ric_doc_subdoc_id is null
		   and   not exists -- tutti record di un flusso da elaborare e senza scarti o errori
		   (
		     select 1
		     from pagopa_t_riconciliazione_doc doc1
		     where doc1.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
		     and   doc1.pagopa_ric_doc_stato_elab not in ('N','S')
		     and   doc1.data_cancellazione is null
		     and   doc1.validita_fine is null
		   )
		   and   doc.data_cancellazione is null
		   and   doc.validita_fine is null
		   and   flusso.data_cancellazione is null
		   and   flusso.validita_fine is null
		   ),
		   sogg as
		   (
			   select sog.soggetto_id, sog.soggetto_code,sog.soggetto_desc
			   from siac_t_soggetto sog
			   where sog.ente_proprietario_id=enteProprietarioId
			   and   sog.data_cancellazione is null
			   and   sog.validita_fine is null
		   )
		   select pagopa.*,
		          sogg.soggetto_id,
        		  sogg.soggetto_desc
		   from pagopa
		        left join sogg on (pagopa.pagopa_codice_benef=sogg.soggetto_code)
		   ),
		   accertamenti_sogg as
		   (
             with
			 accertamenti as
			 (
			   	select mov.movgest_anno::integer, mov.movgest_numero::integer,
		    	       mov.movgest_id, ts.movgest_ts_id
			    from siac_t_movgest mov , siac_d_movgest_tipo tipo,
			         siac_t_movgest_ts ts, siac_d_movgest_ts_tipo tipots,
			         siac_r_movgest_ts_stato rs,siac_d_movgest_stato stato
			    where tipo.ente_proprietario_id=enteProprietarioId
			    and   tipo.movgest_tipo_code='A'
			    and   mov.movgest_tipo_id=tipo.movgest_tipo_id
			    and   mov.bil_id=bilancioId
			    and   ts.movgest_id=mov.movgest_id
			    and   tipots.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
			    and   tipots.movgest_ts_tipo_code='T'
			    and   rs.movgest_ts_id=ts.movgest_ts_id
			    and   stato.movgest_stato_id=rs.movgest_stato_id
			    and   stato.movgest_stato_code='D'
			    and   mov.data_cancellazione is null
			    and   mov.validita_fine is null
			    and   ts.data_cancellazione is null
			    and   ts.validita_fine is null
			    and   rs.data_cancellazione is null
			    and   rs.validita_fine is null
		   ),
		   soggetto_acc as
		   (
			   select sog.soggetto_id, sog.soggetto_code, sog.soggetto_desc,rsog.movgest_ts_id
			   from siac_r_movgest_ts_sog rsog, siac_t_soggetto sog
			   where sog.ente_proprietario_id=enteProprietarioId
			   and   rsog.soggetto_id=sog.soggetto_id
			   and   rsog.data_cancellazione is null
			   and   rsog.validita_fine is null
		   )
		   select accertamenti.*,soggetto_acc.soggetto_id, soggetto_acc.soggetto_code,soggetto_acc.soggetto_desc
		   from   accertamenti -- , soggetto_acc -- 22.07.2019 siac-6963
                  left join soggetto_acc on (accertamenti.movgest_ts_id=soggetto_acc.movgest_ts_id) -- 22.07.2019 siac-6963
--		   where  accertamenti.movgest_ts_id=soggetto_acc.movgest_ts_id -- 22.07.2019 siac-6963
	  	 )
		 select  ( case when pagopa_sogg.soggetto_id is not null then pagopa_sogg.pagopa_codice_benef else accertamenti_sogg.soggetto_code end )  pagopa_soggetto_code,
   				 ( case when pagopa_sogg.soggetto_id is not null then pagopa_sogg.soggetto_desc else accertamenti_sogg.soggetto_desc end ) pagopa_soggetto_desc	,
                 ( case when pagopa_sogg.soggetto_id is not null then pagopa_sogg.soggetto_id else accertamenti_sogg.soggetto_id end ) pagopa_soggetto_id,
                 pagopa_sogg.pagopa_str_amm,
                 pagopa_sogg.pagopa_voce_tematica,
                 pagopa_sogg.pagopa_voce_code,  pagopa_sogg.pagopa_voce_desc,
                 pagopa_sogg.pagopa_sottovoce_code, pagopa_sogg.pagopa_sottovoce_desc,
                 pagopa_sogg.pagopa_flusso_id,
                 pagopa_sogg.pagopa_flusso_nome_mittente,
                 pagopa_sogg.pagopa_anno_provvisorio,
                 pagopa_sogg.pagopa_num_provvisorio,
                 pagopa_sogg.pagopa_anno_accertamento,
		         pagopa_sogg.pagopa_num_accertamento,
                 sum(pagopa_sogg.pagopa_sottovoce_importo) pagopa_sottovoce_importo
  	     from  pagopa_sogg, accertamenti_sogg
 	     where bErrore=false
         and   pagopa_sogg.pagopa_anno_accertamento=accertamenti_sogg.movgest_anno
	   	 and   pagopa_sogg.pagopa_num_accertamento=accertamenti_sogg.movgest_numero
         and   (case when pagopa_sogg.soggetto_id is not null then pagopa_sogg.soggetto_id else accertamenti_sogg.soggetto_id end )=
	           pagoPaFlussoRec.pagopa_soggetto_id
	     group by ( case when pagopa_sogg.soggetto_id is not null then pagopa_sogg.pagopa_codice_benef else accertamenti_sogg.soggetto_code end ),
        	      ( case when pagopa_sogg.soggetto_id is not null then pagopa_sogg.soggetto_desc else accertamenti_sogg.soggetto_desc end ),
                  ( case when pagopa_sogg.soggetto_id is not null then pagopa_sogg.soggetto_id else accertamenti_sogg.soggetto_id end ),
                  pagopa_sogg.pagopa_str_amm,
                  pagopa_sogg.pagopa_voce_tematica,
                  pagopa_sogg.pagopa_voce_code, pagopa_sogg.pagopa_voce_desc,
                  pagopa_sogg.pagopa_sottovoce_code, pagopa_sogg.pagopa_sottovoce_desc,
                  pagopa_sogg.pagopa_flusso_id,pagopa_sogg.pagopa_flusso_nome_mittente,
                  pagopa_sogg.pagopa_anno_provvisorio,
                  pagopa_sogg.pagopa_num_provvisorio,
                  pagopa_sogg.pagopa_anno_accertamento,
		          pagopa_sogg.pagopa_num_accertamento
	     order by  pagopa_sogg.pagopa_sottovoce_code, pagopa_sogg.pagopa_sottovoce_desc,
                   pagopa_sogg.pagopa_anno_provvisorio,
                   pagopa_sogg.pagopa_num_provvisorio,
				   pagopa_sogg.pagopa_anno_accertamento,
		           pagopa_sogg.pagopa_num_accertamento
  	   )
       loop

        codResult:=null;
        codResult1:=null;
        subdocId:=null;
        subdocMovgestTsId:=null;
		strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                         ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||pagoPaFlussoRec.pagopa_voce_desc
                         ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                         ||'. Inserimento quote documento numero='||(dnumQuote+1)::varchar||' [siac_t_subdoc].';
--        raise notice 'strMessagio=%',strMessaggio;
		strMessaggioLog:='Continue fnc_pagopa_t_elaborazione_riconc_esegui - '||strMessaggioFinale||strMessaggio;
        insert into pagopa_t_elaborazione_log
        (
         pagopa_elab_id,
         pagopa_elab_file_id,
         pagopa_elab_log_operazione,
         ente_proprietario_id,
         login_operazione,
         data_creazione
        )
        values
        (
         filePagoPaElabId,
         null,
         strMessaggioLog,
         enteProprietarioId,
         loginOperazione,
         clock_timestamp()
        );

		-- siac_t_subdoc
        insert into siac_t_subdoc
        (
        	subdoc_numero,
			subdoc_desc,
			subdoc_importo,
--		    subdoc_nreg_iva,
	        subdoc_data_scadenza,
	        subdoc_convalida_manuale,
	        subdoc_importo_da_dedurre, -- 05.06.2019 SIAC-6893
--	        subdoc_splitreverse_importo,
--	        subdoc_pagato_cec,
--	        subdoc_data_pagamento_cec,
--	        contotes_id INTEGER,
--	        dist_id INTEGER,
--	        comm_tipo_id INTEGER,
	        doc_id,
	        subdoc_tipo_id,
--	        notetes_id INTEGER,
	        validita_inizio,
			ente_proprietario_id,
		    login_operazione,
	        login_creazione,
            login_modifica
        )
        values
        (
        	dnumQuote+1,
            upper('Voce '||pagoPaFlussoQuoteRec.pagopa_voce_code||'/'||pagoPaFlussoQuoteRec.pagopa_sottovoce_code||' '||
            substring(coalesce(pagoPaFlussoQuoteRec.pagopa_sottovoce_desc,' ' ),1,30)||
            pagoPaFlussoQuoteRec.pagopa_flusso_id||' PSP '||pagoPaFlussoQuoteRec.pagopa_flusso_nome_mittente||
            ' Prov. '||pagoPaFlussoQuoteRec.pagopa_anno_provvisorio::varchar||'/'||
            pagoPaFlussoQuoteRec.pagopa_num_provvisorio),
            pagoPaFlussoQuoteRec.pagopa_sottovoce_importo,
            dataElaborazione,
            'M', --- 13.12.2018 Sofia siac-6602
            0,   --- 05.06.2019 SIAC-6893
  			docId,
            subDocTipoId,
            clock_timestamp(),
            enteProprietarioId,
            loginOperazione,
            loginOperazione,
            loginOperazione
        )
        returning subdoc_id into subDocId;
--        raise notice 'subdocId=%',subdocId;
        if subDocId is null then
            bErrore:=true;
            strMessaggio:=strMessaggio||' Errore in inserimento.';
            continue;
        end if;

		-- siac_r_subdoc_attr
		-- flagAvviso
		-- flagEsproprio
		-- flagOrdinativoManuale
		-- flagOrdinativoSingolo
		-- flagRilevanteIVA
        codResult:=null;
   		strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                         ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||pagoPaFlussoRec.pagopa_voce_desc
                         ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                         ||'. Inserimento quote documento numero='||(dnumQuote+1)::varchar||' [siac_r_subdoc_attr vari].';

		insert into siac_r_subdoc_attr
        (
        	subdoc_id,
            attr_id,
            boolean,
            validita_inizio,
            login_operazione,
            ente_proprietario_id
        )
        select subdocId,
               a.attr_id,
               'N',
               clock_timestamp(),
               loginOperazione,
               a.ente_proprietario_id
        from siac_t_attr a
        where a.ente_proprietario_id=enteProprietarioId
        and   a.attr_code in
        (
         FL_AVVISO_ATTR,
	     FL_ESPROPRIO_ATTR,
	     FL_ORD_MANUALE_ATTR,
		 FL_ORD_SINGOLO_ATTR,
	     FL_RIL_IVA_ATTR
        );
        GET DIAGNOSTICS codResult = ROW_COUNT;
        if coalesce(codResult,0)=0 then
            bErrore:=true;
            strMessaggio:=strMessaggio||' Errore in inserimento.';
            continue;

        end if;

		-- causaleOrdinativo
        /*codResult:=null;
   		strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                         ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||pagoPaFlussoRec.pagopa_voce_desc
                         ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                         ||'. Inserimento quote documento numero='||(dnumQuote+1)::varchar||' [siac_r_subdoc_attr='||CAUS_ORDIN_ATTR||'].';

		insert into siac_r_subdoc_attr
        (
        	subdoc_id,
            attr_id,
            testo,
            validita_inizio,
            login_operazione,
            ente_proprietario_id
        )
        select subdocId,
               a.attr_id,
               upper('Regolarizzazione incasso voce '||pagoPaFlussoQuoteRec.pagopa_voce_code||'/'||pagoPaFlussoQuoteRec.pagopa_sottovoce_code||' '||
	            substring(coalesce(pagoPaFlussoQuoteRec.pagopa_sottovoce_desc,' '),1,30)||
    	        ' Prov. '||pagoPaFlussoQuoteRec.pagopa_anno_provvisorio::varchar||'/'||
        	    pagoPaFlussoQuoteRec.pagopa_num_provvisorio||' '),
               clock_timestamp(),
               loginOperazione,
               a.ente_proprietario_id
        from siac_t_attr a
        where a.ente_proprietario_id=enteProprietarioId
        and   a.attr_code=CAUS_ORDIN_ATTR
        returning subdoc_attr_id into codResult;
        if codResult is null then
        	bErrore:=true;
            strMessaggio:=strMessaggio||' Errore in inserimento.';
            continue;
        end if;*/

		-- dataEsecuzionePagamento
    	/*codResult:=null;
   		strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                         ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ')
                         ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                         ||'. Inserimento quote documento numero='||(dnumQuote+1)::varchar||' [siac_r_subdoc_attr='||DATA_ESEC_PAG_ATTR||'].';

		insert into siac_r_subdoc_attr
        (
        	subdoc_id,
            attr_id,
            testo,
            validita_inizio,
            login_operazione,
            ente_proprietario_id
        )
        select subdocId,
               a.attr_id,
               null,
               clock_timestamp(),
               loginOperazione,
               a.ente_proprietario_id
        from siac_t_attr a
        where a.ente_proprietario_id=enteProprietarioId
        and   a.attr_code=DATA_ESEC_PAG_ATTR
        returning subdoc_attr_id into codResult;
        if codResult is null then
        	bErrore:=true;
            strMessaggio:=strMessaggio||' Errore in inserimento.';
            continue;
        end if;*/

  	    -- controllo sfondamento e adeguamento accertamento
   		strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                         ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc, ' ')
                         ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                         ||'. Inserimento quote documento numero='||(dnumQuote+1)::varchar||'. Verifica esistenza accertamento.';

		codResult:=null;
        dispAccertamento:=null;
        movgestTsId:=null;
        select ts.movgest_ts_id into movgestTsId
        from siac_t_movgest mov, siac_t_movgest_ts ts,
             siac_r_movgest_ts_stato rs
        where mov.bil_id=bilancioId
        and   mov.movgest_tipo_id=movgestTipoId
        and   mov.movgest_anno::integer=pagoPaFlussoQuoteRec.pagopa_anno_accertamento
        and   mov.movgest_numero::integer=pagoPaFlussoQuoteRec.pagopa_num_accertamento
        and   ts.movgest_id=mov.movgest_id
        and   ts.movgest_ts_tipo_id=movgestTsTipoId
        and   rs.movgest_ts_id=ts.movgest_ts_id
        and   rs.movgest_stato_id=movgestStatoId
        and   rs.data_cancellazione is null
        and   date_trunc('DAY',now())>=date_trunc('DAY',rs.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(rs.validita_fine,date_trunc('DAY',now())))
        and   ts.data_cancellazione is null
        and   date_trunc('DAY',now())>=date_trunc('DAY',ts.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(ts.validita_fine,date_trunc('DAY',now())))
        and   mov.data_cancellazione is null
        and   date_trunc('DAY',now())>=date_trunc('DAY',mov.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(mov.validita_fine,date_trunc('DAY',now())));

        if movgestTsId is not null then
       		strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                         ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ' )
                         ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                         ||'. Inserimento quote documento numero='||(dnumQuote+1)::varchar||'. Verifica dispon. accertamento.';

	        select * into dispAccertamento
            from fnc_siac_disponibilitaincassaremovgest (movgestTsId) disponibilita;
--		    raise notice 'dispAccertamento=%',dispAccertamento;
            if dispAccertamento is not null then
            	if dispAccertamento-pagoPaFlussoQuoteRec.pagopa_sottovoce_importo<0 then
                     -- 11.06.2019 SIAC-6720 - inserimento movimento di modifica acc automatico
		      		strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                         ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ' )
                         ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                         ||'. Inserimento quote documento numero='||(dnumQuote+1)::varchar
                         ||'. Adeguamento importo Acc. '||pagoPaFlussoQuoteRec.pagopa_anno_accertamento::varchar
      					 ||'/'||pagoPaFlussoQuoteRec.pagopa_num_accertamento::varchar||'. Inserimento mov. modifica. Calcolo numero.';


                    numModifica:=null;
                    codResult:=null;
                    select coalesce(max(query.mod_num),0) into numModifica
                    from
                    (
					select  modif.mod_num
					from siac_t_modifica modif, siac_r_modifica_stato rs,siac_t_movgest_ts_det_mod  mod
                    where mod.movgest_ts_id=movgestTsId
                    and   rs.mod_stato_r_id=mod.mod_stato_r_id
                    and   modif.mod_id=rs.mod_id
                    and   mod.data_cancellazione is null
                    and   mod.validita_fine is null
                    and   rs.data_cancellazione is null
                    and   rs.validita_fine is null
                    and   modif.data_cancellazione is null
                    and   modif.validita_fine is null
                    union
					select modif.mod_num
					from siac_t_modifica modif, siac_r_modifica_stato rs,siac_r_movgest_ts_sog_mod  mod
                    where mod.movgest_ts_id=movgestTsId
                    and   rs.mod_stato_r_id=mod.mod_stato_r_id
                    and   modif.mod_id=rs.mod_id
                    and   mod.data_cancellazione is null
                    and   mod.validita_fine is null
                    and   rs.data_cancellazione is null
                    and   rs.validita_fine is null
                    and   modif.data_cancellazione is null
                    and   modif.validita_fine is null
                    union
					select modif.mod_num
					from siac_t_modifica modif, siac_r_modifica_stato rs,siac_r_movgest_ts_sogclasse_mod  mod
                    where mod.movgest_ts_id=movgestTsId
                    and   rs.mod_stato_r_id=mod.mod_stato_r_id
                    and   modif.mod_id=rs.mod_id
                    and   mod.data_cancellazione is null
                    and   mod.validita_fine is null
                    and   rs.data_cancellazione is null
                    and   rs.validita_fine is null
                    and   modif.data_cancellazione is null
                    and   modif.validita_fine is null
                    ) query;

                    if numModifica is null then
                     numModifica:=0;
                    end if;

                    strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                         ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ' )
                         ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                         ||'. Inserimento quote documento numero='||(dnumQuote+1)::varchar
                         ||'. Adeguamento importo Acc. '||pagoPaFlussoQuoteRec.pagopa_anno_accertamento::varchar
      					 ||'/'||pagoPaFlussoQuoteRec.pagopa_num_accertamento::varchar||'. Inserimento mov. modifica.';
                    attoAmmId:=null;
                    select ratto.attoamm_id into attoAmmId
                    from siac_r_movgest_ts_atto_amm ratto
                    where ratto.movgest_ts_id=movgestTsId
                    and   ratto.data_cancellazione is null
                    and   ratto.validita_fine is null;
					if attoAmmId is null then
                    	codResult:=-1;
                        strMessaggio:=strMessaggio||' Errore in lettura atto amministrativo.';
                    end if;

                    if codResult is null and modificaTipoId is null then
                    	select tipo.mod_tipo_id into modificaTipoId
                        from siac_d_modifica_tipo tipo
                        where tipo.ente_proprietario_id=enteProprietarioId
                        and   tipo.mod_tipo_code='ALT';
                        if modificaTipoId is null then
                        	codResult:=-1;
	                        strMessaggio:=strMessaggio||' Errore in lettura modifica tipo.';
                        end if;
                    end if;

                    if codResult is null then
                      modifId:=null;
                      insert into siac_t_modifica
                      (
                          mod_num,
                          mod_desc,
                          mod_data,
                          mod_tipo_id,
                          attoamm_id,
                          login_operazione,
                          validita_inizio,
                          ente_proprietario_id
                      )
                      values
                      (
                          numModifica+1,
                          'Modifica automatica per predisposizione di incasso',
                          dataElaborazione,
                          modificaTipoId,
                          attoAmmId,
                          loginOperazione,
                          clock_timestamp(),
                          enteProprietarioId
                      )
                      returning mod_id into modifId;
                      if modifId is null then
                      	codResult:=-1;
                        strMessaggio:=strMessaggio||' Errore in inserimento siac_t_modifica.';
                      end if;
					end if;

                    if codResult is null and modifStatoId is null then
	                    select stato.mod_stato_id into modifStatoId
                        from siac_d_modifica_stato stato
                        where stato.ente_proprietario_id=enteProprietarioId
                        and   stato.mod_stato_code='V';
                        if modifStatoId is null then
                        	codResult:=-1;
	                        strMessaggio:=strMessaggio||' Errore in lettura stato modifica.';
                        end if;
                    end if;
                    if codResult is null then
                      modStatoRId:=null;
                      insert into siac_r_modifica_stato
                      (
                          mod_id,
                          mod_stato_id,
                          validita_inizio,
                          login_operazione,
                          ente_proprietario_id
                      )
                      values
                      (
                          modifId,
                          modifStatoId,
                          clock_timestamp(),
                          loginOperazione,
                          enteProprietarioId
                      )
                      returning mod_stato_r_id into modStatoRId;
                      if modStatoRId is  null then
                      	codResult:=-1;
                        strMessaggio:=strMessaggio||' Errore in inserimento siac_r_modifica_stato.';
                      end if;
                    end if;
                    if codResult is null then
                      insert into siac_t_movgest_ts_det_mod
                      (
                          mod_stato_r_id,
                          movgest_ts_det_id,
                          movgest_ts_id,
                          movgest_ts_det_tipo_id,
                          movgest_ts_det_importo,
                          validita_inizio,
                          login_operazione,
                          ente_proprietario_id
                      )
                      select modStatoRId,
                             det.movgest_ts_det_id,
                             det.movgest_ts_id,
                             det.movgest_ts_det_tipo_id,
                             pagoPaFlussoQuoteRec.pagopa_sottovoce_importo-dispAccertamento,
                             clock_timestamp(),
                             loginOperazione,
                             det.ente_proprietario_id
                      from siac_t_movgest_ts_det det
                      where det.movgest_ts_id=movgestTsId
                      and   det.movgest_ts_det_tipo_id=movgestTsDetTipoId
                      returning movgest_ts_det_mod_id into codResult;
                      if codResult is null then
                      	codResult:=-1;
                        strMessaggio:=strMessaggio||' Errore in inserimento siac_t_movgest_ts_det_mod.';
                      else
                        codResult:=null;
                      end if;
                	end if;

                    if codResult is null then
                      strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                           ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ' )
                           ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                           ||'. Inserimento quote documento numero='||(dnumQuote+1)::varchar
                           ||'. Adeguamento importo Acc. '||pagoPaFlussoQuoteRec.pagopa_anno_accertamento::varchar
                           ||'/'||pagoPaFlussoQuoteRec.pagopa_num_accertamento::varchar||'.';
                      update siac_t_movgest_ts_det det
                      set    movgest_ts_det_importo=det.movgest_ts_det_importo+
                                                    (pagoPaFlussoQuoteRec.pagopa_sottovoce_importo-dispAccertamento),
                             data_modifica=clock_timestamp(),
                             login_operazione=det.login_operazione||'-'||loginOperazione
                      where det.movgest_ts_id=movgestTsId
                      and   det.movgest_ts_det_tipo_id=movgestTsDetTipoId
                      and   det.data_cancellazione is null
                      and   date_trunc('DAY',now())>=date_trunc('DAY',det.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(det.validita_fine,date_trunc('DAY',now())))
                      returning det.movgest_ts_det_id into codResult;
                      if codResult is null then
                      	codResult:=-1;
                        strMessaggio:=strMessaggio||' Errore in aggiornamento siac_t_movgest_ts_det.';
                      else codResult:=null;
                      end if;
                    end if;

                    if codResult is null then
                      strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                           ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ' )
                           ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                           ||'. Inserimento quote documento numero='||(dnumQuote+1)::varchar
                           ||'. Adeguamento importo Acc. '||pagoPaFlussoQuoteRec.pagopa_anno_accertamento::varchar
                           ||'/'||pagoPaFlussoQuoteRec.pagopa_num_accertamento::varchar||'. Inserimento pagopa_t_modifica_elab.';
                      insert into pagopa_t_modifica_elab
                      (
                          pagopa_modifica_elab_importo,
                          pagopa_elab_id,
                          subdoc_id,
                          mod_id,
                          movgest_ts_id,
                          validita_inizio,
                          login_operazione,
                          ente_proprietario_id
                      )
                      values
                      (
                          pagoPaFlussoQuoteRec.pagopa_sottovoce_importo-dispAccertamento,
                          filePagoPaElabId,
                          subDocId,
                          modifId,
                          movgestTsId,
                          clock_timestamp(),
                          loginOperazione,
                          enteProprietarioId
                      )
                      returning pagopa_modifica_elab_id into codResult;
                      if codResult is null then
                      	codResult:=-1;
                        strMessaggio:=strMessaggio||' Errore in inserimento pagopa_t_modifica_elab.';
                      else codResult:=null;
                      end if;
                    end if;

                    if codResult is not null then
                        --bErrore:=true;
                        pagoPaCodeErr:=PAGOPA_ERR_31;
                    	strMessaggioBck:=strMessaggio||' PAGOPA_ERR_31='||PAGOPA_ERR_31||' .';
--                        raise notice '%', strMessaggioBck;
                        strMessaggio:=' ';
                        raise exception '%', strMessaggioBck;
                    end if;
                     -- 11.06.2019 SIAC-6720 - inserimento movimento di modifica acc automatico
                end if;
            else
            	bErrore:=true;
           		pagoPaCodeErr:=PAGOPA_ERR_31;
                strMessaggio:=strMessaggio||' Acc. '||pagoPaFlussoQuoteRec.pagopa_anno_accertamento::varchar
            						  ||'/'||pagoPaFlussoQuoteRec.pagopa_num_accertamento::varchar||' errore.';
	            continue;
            end if;
        else
            bErrore:=true;
            pagoPaCodeErr:=PAGOPA_ERR_31;
            strMessaggio:=strMessaggio||' Acc. '||pagoPaFlussoQuoteRec.pagopa_anno_accertamento::varchar
            						  ||'/'||pagoPaFlussoQuoteRec.pagopa_num_accertamento::varchar||' non esistente.';
            continue;
        end if;


		codResult:=null;
   		strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                         ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ' )
                         ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                         ||'. Inserimento quote documento numero='||(dnumQuote+1)::varchar||' movgest_ts_id='||movgestTsId::varchar||' [siac_r_subdoc_movgest_ts].';
		-- siac_r_subdoc_movgest_ts
        insert into siac_r_subdoc_movgest_ts
        (
        	subdoc_id,
            movgest_ts_id,
            validita_inizio,
            login_Operazione,
            ente_proprietario_id
        )
        values
        (
               subdocId,
               movgestTsId,
               clock_timestamp(),
               loginOperazione,
               enteProprietarioId
        )
		returning subdoc_movgest_ts_id into codResult;
		if codResult is null then
            bErrore:=true;
            strMessaggio:=strMessaggio||' Errore in inserimento.';
            continue;
        end if;
		subdocMovgestTsId:=  codResult;
--        raise notice 'subdocMovgestTsId=%',subdocMovgestTsId;

        -- siac-6720 30.05.2019 - per i corrispettivi non collegare atto_amm
--        if pagoPaFlussoRec.pagopa_doc_tipo_code!=DOC_TIPO_COR  then -- Jira SIAC-7089 14.10.2019 Sofia
        if pagoPaFlussoRec.pagopa_doc_tipo_code=DOC_TIPO_IPA  then    -- Jira SIAC-7089 14.10.2019 Sofia


          -- siac_r_subdoc_atto_amm
          codResult:=null;
          strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                           ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ' )
                           ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                           ||'. Inserimento quote documento numero='||(dnumQuote+1)::varchar||' [siac_r_subdoc_atto_amm].';
          insert into siac_r_subdoc_atto_amm
          (
              subdoc_id,
              attoamm_id,
              validita_inizio,
              login_operazione,
              ente_proprietario_id
          )
          select subdocId,
                 atto.attoamm_id,
                 clock_timestamp(),
                 loginOperazione,
                 atto.ente_proprietario_id
          from siac_r_subdoc_movgest_ts rts, siac_r_movgest_ts_atto_amm atto
          where rts.subdoc_movgest_ts_id=subdocMovgestTsId
          and   atto.movgest_ts_id=rts.movgest_ts_id
          and   atto.data_cancellazione is null
          and   date_trunc('DAY',now())>=date_trunc('DAY',atto.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(atto.validita_fine,date_trunc('DAY',now())))
          returning subdoc_atto_amm_id into codResult;
          if codResult is null then
              bErrore:=true;
              strMessaggio:=strMessaggio||' Errore in inserimento.';
              continue;
          end if;
        end if;

		-- controllo esistenza e sfondamento disp. provvisorio
        codResult:=null;
        provvisorioId:=null;
        dispProvvisorioCassa:=null;
        strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                         ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ' )
                         ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                         ||'. Inserimento quote documento numero='||(dnumQuote+1)::varchar||' [siac_r_subdoc_prov_cassa].';
        select prov.provc_id into provvisorioId
        from siac_t_prov_cassa prov
        where prov.provc_tipo_id=provvisorioTipoId
        and   prov.provc_anno::integer=pagoPaFlussoQuoteRec.pagopa_anno_provvisorio
        and   prov.provc_numero::integer=pagoPaFlussoQuoteRec.pagopa_num_provvisorio
        and   prov.provc_data_annullamento is null
        and   prov.provc_data_regolarizzazione is null
        and   prov.data_cancellazione is null
        and   date_trunc('DAY',now())>=date_trunc('DAY',prov.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(prov.validita_fine,date_trunc('DAY',now())));
--        raise notice 'provvisorioId=%',provvisorioId;

        if provvisorioId is not null then
        	select 1 into codResult
            from siac_r_ordinativo_prov_cassa r
            where r.provc_id=provvisorioId
            and   r.data_cancellazione is null
            and   r.validita_fine is null;
            if codResult is null then
            	select 1 into codResult
	            from siac_r_subdoc_prov_cassa r
    	        where r.provc_id=provvisorioId
                and   r.login_operazione not like '%@PAGOPA-'||filePagoPaElabId::varchar||'%'
        	    and   r.data_cancellazione is null
            	and   r.validita_fine is null;
            end if;
            if codResult is not null then
            	pagoPaCodeErr:=PAGOPA_ERR_39;
	            bErrore:=true;
                strMessaggio:=strMessaggio||' Prov. '
                          ||pagoPaFlussoQuoteRec.pagopa_anno_provvisorio||'/'
                          ||pagoPaFlussoQuoteRec.pagopa_num_provvisorio||' regolarizzato.';
       		    continue;
            end if;
        end if;
        if provvisorioId is not null then
           strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                         ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ' )
                         ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                         ||'. Inserimento quote documento numero='||(dnumQuote+1)::varchar||' [siac_r_subdoc_prov_cassa] provc_id='
                         ||provvisorioId::VARCHAR||'. Verifica disponibilita''.';
			select * into dispProvvisorioCassa
            from fnc_siac_daregolarizzareprovvisorio(provvisorioId) disponibilita;
--            raise notice 'dispProvvisorioCassa=%',dispProvvisorioCassa;
--            raise notice 'pagoPaFlussoQuoteRec.pagopa_sottovoce_importo=%',pagoPaFlussoQuoteRec.pagopa_sottovoce_importo;

            if dispProvvisorioCassa is not null then
            	if dispProvvisorioCassa-pagoPaFlussoQuoteRec.pagopa_sottovoce_importo<0 then
                	pagoPaCodeErr:=PAGOPA_ERR_33;
		            bErrore:=true;
                    strMessaggio:=strMessaggio||' Prov. '
                          ||pagoPaFlussoQuoteRec.pagopa_anno_provvisorio||'/'
                          ||pagoPaFlussoQuoteRec.pagopa_num_provvisorio||' disp. insufficiente.';
        		    continue;
                end if;
            else
            	pagoPaCodeErr:=PAGOPA_ERR_32;
	            bErrore:=true;
               strMessaggio:=strMessaggio||' Prov. '
                          ||pagoPaFlussoQuoteRec.pagopa_anno_provvisorio||'/'
                          ||pagoPaFlussoQuoteRec.pagopa_num_provvisorio||' Errore.';

    	        continue;
            end if;
        else
        	pagoPaCodeErr:=PAGOPA_ERR_32;
            bErrore:=true;
            strMessaggio:=strMessaggio||' Prov. '
                          ||pagoPaFlussoQuoteRec.pagopa_anno_provvisorio||'/'
                          ||pagoPaFlussoQuoteRec.pagopa_num_provvisorio||' non esistente.';
            continue;
        end if;


		codResult:=null;
   		strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                         ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ' )
                         ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                         ||'. Inserimento quote documento numero='||(dnumQuote+1)::varchar||' [siac_r_subdoc_prov_cassa] provc_id='
                         ||provvisorioId::varchar||'.';
		-- siac_r_subdoc_prov_cassa
        insert into siac_r_subdoc_prov_cassa
        (
        	subdoc_id,
            provc_id,
            validita_inizio,
            login_operazione,
            ente_proprietario_id
        )
        VALUES
        (
               subdocId,
               provvisorioId,
               clock_timestamp(),
               loginOperazione||'@PAGOPA-'||filePagoPaElabId::varchar,
               enteProprietarioId
        )
        returning subdoc_provc_id into codResult;
---        raise notice 'subdoc_provc_id=%',codResult;

        if codResult is null then
        	bErrore:=true;
            strMessaggio:=strMessaggio||' Errore in inserimento.';
            continue;
        end  if;

		codResult:=null;
        strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                         ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ' )
                         ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                         ||'. Aggiornamento pagopa_t_riconciliazione_doc per subdoc_id.';
        -- aggiornare pagopa_t_riconciliazione_doc
        update pagopa_t_riconciliazione_doc docUPD
        set    pagopa_ric_doc_subdoc_id=subdocId,
		       pagopa_ric_doc_stato_elab='S',
               pagopa_ric_errore_id=null,
               pagopa_ric_doc_movgest_ts_id=movgestTsId,
               pagopa_ric_doc_provc_id=provvisorioId,
               data_modifica=clock_timestamp(),
               login_operazione=docUPD.login_operazione||'-'||loginOperazione||'@ELAB-'||filePagoPaElabId::varchar
        from
        (
         with
          pagopa as
          (
            select  doc.pagopa_ric_doc_id,
                    doc.pagopa_ric_doc_anno_accertamento,
                    doc.pagopa_ric_doc_num_accertamento,
                    doc.pagopa_ric_doc_codice_benef
          	from pagopa_t_elaborazione_flusso flusso,pagopa_t_riconciliazione_doc doc
            where  flusso.pagopa_elab_id=filePagoPaElabId
   	        and    doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
			and    doc.pagopa_ric_doc_tipo_id=pagoPaFlussoRec.pagopa_doc_tipo_id -- 30.05.2019 siac-6720
            and    coalesce(doc.pagopa_ric_doc_str_amm,'')=
                   coalesce(pagoPaFlussoRec.pagopa_str_amm,coalesce(doc.pagopa_ric_doc_str_amm,''))
            and    coalesce(doc.pagopa_ric_doc_voce_tematica,'')=
                   coalesce(pagoPaFlussoRec.pagopa_voce_tematica,coalesce(doc.pagopa_ric_doc_voce_tematica,''))
            and    doc.pagopa_ric_doc_voce_code=pagoPaFlussoRec.pagopa_voce_code
            and    coalesce(doc.pagopa_ric_doc_voce_desc,'')=coalesce(pagoPaFlussoRec.pagopa_voce_desc,coalesce(doc.pagopa_ric_doc_voce_desc,''))
            and    doc.pagopa_ric_doc_sottovoce_code=pagoPaFlussoQuoteRec.pagopa_sottovoce_code
            and    coalesce(doc.pagopa_ric_doc_sottovoce_desc,'')=
                   coalesce(pagoPaFlussoQuoteRec.pagopa_sottovoce_desc,coalesce(doc.pagopa_ric_doc_sottovoce_desc,''))
            and    flusso.pagopa_elab_ric_flusso_id=pagoPaFlussoQuoteRec.pagopa_flusso_id
            and    flusso.pagopa_elab_flusso_nome_mittente=pagoPaFlussoQuoteRec.pagopa_flusso_nome_mittente
            and    flusso.pagopa_elab_flusso_anno_provvisorio=pagoPaFlussoQuoteRec.pagopa_anno_provvisorio
            and    flusso.pagopa_elab_flusso_num_provvisorio=pagoPaFlussoQuoteRec.pagopa_num_provvisorio
            and    doc.pagopa_ric_doc_anno_accertamento=pagoPaFlussoQuoteRec.pagopa_anno_accertamento
    		and    doc.pagopa_ric_doc_num_accertamento=pagoPaFlussoQuoteRec.pagopa_num_accertamento
            and    doc.pagopa_ric_doc_stato_elab='N'
            and    doc.pagopa_ric_doc_flag_con_dett=false -- 05.06.2019 SIAC-6720
     	    and    doc.pagopa_ric_doc_subdoc_id is null
     		and   not exists -- tutti record di un flusso da elaborare e senza scarti o errori
   		    (
		     select 1
		     from pagopa_t_riconciliazione_doc doc1
		     where doc1.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
		     and   doc1.pagopa_ric_doc_stato_elab not in ('N','S')
		     and   doc1.data_cancellazione is null
		     and   doc1.validita_fine is null
		    )
		    and   doc.data_cancellazione is null
		    and   doc.validita_fine is null
	     	and   flusso.data_cancellazione is null
		    and   flusso.validita_fine is null
          ),
          -- 23.07.2019 siac-6963
          accertamenti_sog as
          (
           with
           accertamenti as
           (
              select ts.movgest_ts_id
              from siac_t_movgest mov, siac_t_movgest_ts ts, siac_r_movgest_ts_stato rs
              where mov.bil_id=bilancioId
              and   mov.movgest_tipo_id=movgestTipoId
              and   ts.movgest_id=mov.movgest_id
              and   ts.movgest_ts_tipo_id=movgestTsTipoId
              and   rs.movgest_ts_id=ts.movgest_ts_id
              and   rs.movgest_stato_id=movgestStatoId
              and   mov.movgest_anno::integer=pagoPaFlussoQuoteRec.pagopa_anno_accertamento
              and   mov.movgest_numero::integer=pagoPaFlussoQuoteRec.pagopa_num_accertamento
              and   mov.data_cancellazione is null
              and   date_trunc('DAY',now())>=date_trunc('DAY',mov.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(mov.validita_fine,date_trunc('DAY',now())))
              and   ts.data_cancellazione is null
              and   date_trunc('DAY',now())>=date_trunc('DAY',ts.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(ts.validita_fine,date_trunc('DAY',now())))
              and   rs.data_cancellazione is null
              and   date_trunc('DAY',now())>=date_trunc('DAY',rs.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(rs.validita_fine,date_trunc('DAY',now())))
           ),
           sog_acc as
           (
              select sog.soggetto_id, sog.soggetto_code, sog.soggetto_desc, rsog.movgest_ts_id
              from siac_t_soggetto sog,siac_r_movgest_ts_sog rsog
              where sog.ente_proprietario_id=enteProprietarioId
              and   rsog.soggetto_id=sog.soggetto_id
              and   sog.data_cancellazione is null
              and   date_trunc('DAY',now())>=date_trunc('DAY',sog.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(sog.validita_fine,date_trunc('DAY',now())))
              and   rsog.data_cancellazione is null
              and   date_trunc('DAY',now())>=date_trunc('DAY',rsog.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(rsog.validita_fine,date_trunc('DAY',now())))

           )
           select accertamenti.movgest_ts_id, sog_acc.soggetto_id
           from accertamenti left join sog_acc on (accertamenti.movgest_ts_id=sog_acc.movgest_ts_id)
          ),
          sog as
          (
          select sog.soggetto_id, sog.soggetto_code, sog.soggetto_desc
          from siac_t_soggetto sog
          where sog.ente_proprietario_id=enteProprietarioId
          and   sog.data_cancellazione is null
          and   date_trunc('DAY',now())>=date_trunc('DAY',sog.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(sog.validita_fine,date_trunc('DAY',now())))
          )
          select pagopa.pagopa_ric_doc_id,
                 (case when s1.soggetto_id is not null then s1.soggetto_id else accertamenti_sog.soggetto_id end ) pagopa_soggetto_id
          from pagopa left join sog s1 on (pagopa.pagopa_ric_doc_codice_benef=s1.soggetto_code),
--               accertamenti join sog s2 on (accertamenti.soggetto_id=s2.soggetto_id) -- 22.07.2019 siac-6963
               accertamenti_sog -- 22.07.2019 siac-6963
        ) QUERY
        where docUPD.ente_proprietario_id=enteProprietarioId
        and   docUPD.pagopa_ric_doc_stato_elab='N'
        and   docUPD.pagopa_ric_doc_subdoc_id is null
        and   docUPD.pagopa_ric_doc_flag_con_dett=false -- 05.06.2019 SIAC-6720
        and   docUPD.pagopa_ric_doc_id=QUERY.pagopa_ric_doc_id
        and   QUERY.pagopa_soggetto_id=pagoPaFlussoQuoteRec.pagopa_soggetto_id
        and   docUPD.data_cancellazione is null
        and   docUPD.validita_fine is null;
        GET DIAGNOSTICS codResult = ROW_COUNT;
--		raise notice 'Aggiornati pagopa_t_riconciliazione_doc=%',codResult;
		if coalesce(codResult,0)=0 then
            raise exception ' Errore in aggiornamento.';
        end if;

		strMessaggioLog:='Continue fnc_pagopa_t_elaborazione_riconc_esegui - '||strMessaggioFinale||strMessaggio;
        insert into pagopa_t_elaborazione_log
        (
         pagopa_elab_id,
         pagopa_elab_file_id,
         pagopa_elab_log_operazione,
         ente_proprietario_id,
         login_operazione,
         data_creazione
        )
        values
        (
         filePagoPaElabId,
         null,
         strMessaggioLog,
         enteProprietarioId,
         loginOperazione,
         clock_timestamp()
        );


        strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                         ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ' )
                         ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                         ||'. Aggiornamento pagopa_t_riconciliazione per subdoc_id.';
		codResult:=null;
        -- aggiornare pagopa_t_riconciliazione
        update pagopa_t_riconciliazione ric
        set    pagopa_ric_flusso_stato_elab='S',
			   pagopa_ric_errore_id=null,
               data_modifica=clock_timestamp(),
               login_operazione=ric.login_operazione||'-'||loginOperazione||'@ELAB-'||filePagoPaElabId::varchar
		from pagopa_t_elaborazione_flusso flusso,pagopa_t_riconciliazione_doc doc
        where flusso.pagopa_elab_id=filePagoPaElabId
        and   doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
        and   doc.pagopa_ric_doc_subdoc_id=subdocId
        and   doc.pagopa_ric_doc_flag_con_dett=false -- 05.06.2019 SIAC-6720
        and   split_part(doc.login_operazione,'@ELAB-', 2)::integer=filePagoPaElabId
        and   ric.pagopa_ric_id=doc.pagopa_ric_id;
        GET DIAGNOSTICS codResult = ROW_COUNT;
--   		raise notice 'Aggiornati pagopa_t_riconciliazione=%',codResult;

--        returning ric.pagopa_ric_id into codResult;
		if coalesce(codResult,0)=0 then
	        bErrore:=true;
            strMessaggio:=strMessaggio||' Errore in aggiornamento.';
            strMessaggioLog:='Continue fnc_pagopa_t_elaborazione_riconc_esegui - '||strMessaggioFinale||strMessaggio;
            insert into pagopa_t_elaborazione_log
            (
            pagopa_elab_id,
            pagopa_elab_file_id,
            pagopa_elab_log_operazione,
            ente_proprietario_id,
            login_operazione,
            data_creazione
            )
            values
            (
            filePagoPaElabId,
            null,
            strMessaggioLog,
            enteProprietarioId,
            loginOperazione,
            clock_timestamp()
            );


            continue;
        end if;

		dnumQuote:=dnumQuote+1;
        dDocImporto:=dDocImporto+pagoPaFlussoQuoteRec.pagopa_sottovoce_importo;

       end loop;

	   if dnumQuote>0 and bErrore=false then
        -- siac_t_subdoc_num
        codResult:=null;
        strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                         ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ' )
                         ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                         ||'. Inserimento numero quote [siac_t_subdoc_num].';
 	    insert into siac_t_subdoc_num
        (
         doc_id,
         subdoc_numero,
         validita_inizio,
         login_operazione,
         ente_proprietario_id
        )
        values
        (
         docId,
         dnumQuote,
         clock_timestamp(),
         loginOperazione,
         enteProprietarioId
        )
        returning subdoc_num_id into codResult;
        if codResult is null then
        	bErrore:=true;
            strMessaggio:=strMessaggio||' Inserimento non riuscito.';
        end if;

		if bErrore =false then
        	strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                         ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ' )
                         ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                         ||'. Aggiornamento importo documento.';
        	update siac_t_doc doc
            set    doc_importo=dDocImporto
            where doc.doc_id=docId
            returning doc.doc_id into codResult;
            if codResult is null then
            	bErrore:=true;
            	strMessaggio:=strMessaggio||' Aggiornamento non riuscito.';
            end if;
        end if;
       else
        -- non ha inserito quote
        if bErrore=false  then
        	strMessaggio:='Inserimento documento per soggetto='||pagoPaFlussoRec.pagopa_soggetto_code--||'-'||pagoPaFlussoRec.pagopa_soggetto_desc
                         ||'. Voce '||pagoPaFlussoRec.pagopa_voce_code--||'-'||coalesce(pagoPaFlussoRec.pagopa_voce_desc,' ' )
                         ||'. Struttura amministrativa '||coalesce(pagoPaFlussoRec.pagopa_str_amm,' ')
                         ||'. Inserimento quote non effettuato.';
            bErrore:=true;
        end if;
       end if;



	   if bErrore=true then

    	 strMessaggioBck:=strMessaggio;
         strMessaggio:='Cancellazione dati documento inseriti.'||strMessaggioBck;
--         raise notice 'strMessaggio=%',strMessaggio;
--                  raise notice 'pagoPaCodeErr=%',pagoPaCodeErr;

		 if pagoPaCodeErr is null then
         	pagoPaCodeErr:=PAGOPA_ERR_30;
         end if;

         -- pulizia delle tabella pagopa_t_riconciliazione

         strMessaggio:='Cancellazione dati documento inseriti [pagopa_t_riconciliazione S].'||strMessaggioBck;
--         raise notice 'strMessaggio=%',strMessaggio;
  		 update pagopa_t_riconciliazione ric
         set    pagopa_ric_flusso_stato_elab='X',
  			    pagopa_ric_errore_id=errore.pagopa_ric_errore_id,
                data_modifica=clock_timestamp(),
                login_operazione=split_part(ric.login_operazione,'@ELAB-'||filePagoPaElabId::varchar, 1)||'@ELAB-'||filePagoPaElabId::varchar
   	     from pagopa_t_elaborazione_flusso flusso,pagopa_t_riconciliazione_doc doc,
              pagopa_d_riconciliazione_errore errore, siac_t_subdoc sub
         where flusso.pagopa_elab_id=filePagoPaElabId
         and   doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
         and   doc.pagopa_ric_doc_subdoc_id=sub.subdoc_id
         and   sub.doc_id=docId
         and   doc.login_operazione like '%@ELAB-'||filePagoPaElabId::varchar||'%'
         and   split_part(doc.login_operazione,'@ELAB-', 2)::integer=filePagoPaElabId
         and   ric.pagopa_ric_id=doc.pagopa_ric_id
         and   exists
         (
         select 1
         from pagopa_t_riconciliazione_doc doc1
         where doc1.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
         and   doc1.pagopa_ric_doc_subdoc_id=sub.subdoc_id
         and   doc1.pagopa_ric_id=ric.pagopa_ric_id
         and   doc1.login_operazione like '%@ELAB-'||filePagoPaElabId::varchar||'%'
         and   doc1.validita_fine is null
         and   doc1.data_cancellazione is null
         )
         and   errore.ente_proprietario_id=flusso.ente_proprietario_id
         and   errore.pagopa_ric_errore_code= pagoPaCodeErr
         and   flusso.data_cancellazione is null
         and   flusso.validita_fine is null
         and   ric.data_cancellazione is null
         and   ric.validita_fine is null
         and   sub.data_cancellazione is null
         and   sub.validita_fine is null;

		 strMessaggioLog:='Continue fnc_pagopa_t_elaborazione_riconc_esegui - '||strMessaggioFinale||strMessaggio;
         insert into pagopa_t_elaborazione_log
         (
           pagopa_elab_id,
           pagopa_elab_file_id,
           pagopa_elab_log_operazione,
           ente_proprietario_id,
           login_operazione,
           data_creazione
         )
         values
         (
           filePagoPaElabId,
           null,
           strMessaggioLog,
           enteProprietarioId,
           loginOperazione,
           clock_timestamp()
         );

         strMessaggio:='Cancellazione dati documento inseriti [pagopa_t_riconciliazione N].'||strMessaggioBck;
--         raise notice 'strMessaggio=%',strMessaggio;
		 update pagopa_t_riconciliazione  docUPD
         set    pagopa_ric_flusso_stato_elab='X',
  			    pagopa_ric_errore_id=errore.pagopa_ric_errore_id,
                data_modifica=clock_timestamp(),
                login_operazione=split_part(docUPD.login_operazione,'@ELAB-'||filePagoPaElabId::varchar, 1)||'@ELAB-'||filePagoPaElabId::varchar
         from
         (
		  with
          pagopa as
          (
            select  doc.pagopa_ric_doc_id,
                    doc.pagopa_ric_doc_anno_accertamento,
                    doc.pagopa_ric_doc_num_accertamento,
                    doc.pagopa_ric_doc_codice_benef,
                    doc.pagopa_ric_id
          	from pagopa_t_elaborazione_flusso flusso,pagopa_t_riconciliazione_doc doc
            where  flusso.pagopa_elab_id=filePagoPaElabId
   	        and    doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
            and    doc.pagopa_ric_doc_tipo_id=pagoPaFlussoRec.pagopa_doc_tipo_id -- 30.05.2019 siac-6720
            and    coalesce(doc.pagopa_ric_doc_str_amm,'')=
                   coalesce(pagoPaFlussoRec.pagopa_str_amm,coalesce(doc.pagopa_ric_doc_str_amm,''))
            and    coalesce(doc.pagopa_ric_doc_voce_tematica,'')=
                   coalesce(pagoPaFlussoRec.pagopa_voce_tematica,coalesce(doc.pagopa_ric_doc_voce_tematica,''))
            and    doc.pagopa_ric_doc_voce_code=pagoPaFlussoRec.pagopa_voce_code
            and    coalesce(doc.pagopa_ric_doc_voce_desc,'')=coalesce(pagoPaFlussoRec.pagopa_voce_desc,coalesce(doc.pagopa_ric_doc_voce_desc,''))
        --    and    doc.pagopa_ric_doc_sottovoce_code=pagoPaFlussoQuoteRec.pagopa_sottovoce_code
        --    and    coalesce(doc.pagopa_ric_doc_sottovoce_desc,'')=
        --           coalesce(pagoPaFlussoQuoteRec.pagopa_sottovoce_desc,coalesce(doc.pagopa_ric_doc_sottovoce_desc,''))
        --    and    flusso.pagopa_elab_ric_flusso_id=pagoPaFlussoQuoteRec.pagopa_flusso_id
        --    and    flusso.pagopa_elab_flusso_nome_mittente=pagoPaFlussoQuoteRec.pagopa_flusso_nome_mittente
        --    and    flusso.pagopa_elab_flusso_anno_provvisorio=pagoPaFlussoQuoteRec.pagopa_anno_provvisorio
        --    and    flusso.pagopa_elab_flusso_num_provvisorio=pagoPaFlussoQuoteRec.pagopa_num_provvisorio
        --   and    doc.pagopa_ric_doc_anno_accertamento=pagoPaFlussoQuoteRec.pagopa_anno_accertamento
        --	 and    doc.pagopa_ric_doc_num_accertamento=pagoPaFlussoQuoteRec.pagopa_num_accertamento
            and    doc.pagopa_ric_doc_stato_elab = 'N'
            and    doc.pagopa_ric_doc_flag_con_dett=false -- 05.06.2019 SIAC-6720
			and    doc.pagopa_ric_doc_subdoc_id is null
     	/*	and   not exists -- tutti record di un flusso da elaborare e senza scarti o errori
   		    (
		     select 1
		     from pagopa_t_riconciliazione_doc doc1
		     where doc1.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
		     and   doc1.pagopa_ric_doc_stato_elab not in ('N','S')
		     and   doc1.data_cancellazione is null
		     and   doc1.validita_fine is null
		    )*/
		    and   doc.data_cancellazione is null
		    and   doc.validita_fine is null
	     	and   flusso.data_cancellazione is null
		    and   flusso.validita_fine is null
          ),
          -- 23.07.2019 siac-6963
          accertamenti_sog AS
          (
           with
           accertamenti as
           (
                select ts.movgest_ts_id
                from siac_t_movgest mov, siac_t_movgest_ts ts, siac_r_movgest_ts_stato rs
                where mov.bil_id=bilancioId
                and   mov.movgest_tipo_id=movgestTipoId
                and   ts.movgest_id=mov.movgest_id
                and   ts.movgest_ts_tipo_id=movgestTsTipoId
                and   rs.movgest_ts_id=ts.movgest_ts_id
                and   rs.movgest_stato_id=movgestStatoId
            --    and   mov.movgest_anno::integer=pagoPaFlussoQuoteRec.pagopa_anno_accertamento
             --   and   mov.movgest_numero::integer=pagoPaFlussoQuoteRec.pagopa_num_accertamento
                and   mov.data_cancellazione is null
                and   date_trunc('DAY',now())>=date_trunc('DAY',mov.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(mov.validita_fine,date_trunc('DAY',now())))
                and   ts.data_cancellazione is null
                and   date_trunc('DAY',now())>=date_trunc('DAY',ts.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(ts.validita_fine,date_trunc('DAY',now())))
                and   rs.data_cancellazione is null
                and   date_trunc('DAY',now())>=date_trunc('DAY',rs.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(rs.validita_fine,date_trunc('DAY',now())))
           ),
           sog_acc as
           (
	           select sog.soggetto_id, sog.soggetto_code, sog.soggetto_desc, rsog.movgest_ts_id
    		   from siac_t_soggetto sog,siac_r_movgest_ts_sog rsog
	           where sog.ente_proprietario_id=enteProprietarioId
               and   rsog.soggetto_id=sog.soggetto_id
	           and   sog.data_cancellazione is null
	           and   date_trunc('DAY',now())>=date_trunc('DAY',sog.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(sog.validita_fine,date_trunc('DAY',now())))
               and   rsog.data_cancellazione is null
               and   date_trunc('DAY',now())>=date_trunc('DAY',rsog.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(rsog.validita_fine,date_trunc('DAY',now())))
           )
           select accertamenti.movgest_ts_id, sog_acc.soggetto_id
           from accertamenti left join sog_acc on (accertamenti.movgest_ts_id=sog_acc.movgest_ts_id)
          ),
          sog as
          (
          select sog.soggetto_id, sog.soggetto_code, sog.soggetto_desc
          from siac_t_soggetto sog
          where sog.ente_proprietario_id=enteProprietarioId
          and   sog.data_cancellazione is null
          and   date_trunc('DAY',now())>=date_trunc('DAY',sog.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(sog.validita_fine,date_trunc('DAY',now())))
          )
          select pagopa.pagopa_ric_doc_id,
                 (case when s1.soggetto_id is not null then s1.soggetto_id else accertamenti_sog.soggetto_id end ) pagopa_soggetto_id,
                 pagopa.pagopa_ric_id
          from pagopa left join sog s1 on (pagopa.pagopa_ric_doc_codice_benef=s1.soggetto_code),
--                accertamenti join sog s2 on (accertamenti.soggetto_id=s2.soggetto_id) -- 22.07.2019 siac-6963
               accertamenti_sog -- 22.07.2019 siac-6963
         ) query,pagopa_d_riconciliazione_errore errore
         where docUPD.ente_proprietario_id=enteProprietarioId
--         and   docUPD.pagopa_ric_flusso_stato_elab='N'
         and   docUPD.pagopa_ric_id=QUERY.pagopa_ric_id
         and   QUERY.pagopa_soggetto_id=pagoPaFlussoRec.pagopa_soggetto_id
         and   errore.ente_proprietario_id=docUPD.ente_proprietario_id
         and   errore.pagopa_ric_errore_code= pagoPaCodeErr
         and   docUPD.data_cancellazione is null
         and   docUPD.validita_fine is null;

         strMessaggioLog:='Continue fnc_pagopa_t_elaborazione_riconc_esegui - '||strMessaggioFinale||strMessaggio;
         insert into pagopa_t_elaborazione_log
         (
         pagopa_elab_id,
         pagopa_elab_file_id,
         pagopa_elab_log_operazione,
         ente_proprietario_id,
         login_operazione,
         data_creazione
         )
         values
         (
         filePagoPaElabId,
         null,
         strMessaggioLog,
         enteProprietarioId,
         loginOperazione,
         clock_timestamp()
         );




         strMessaggio:='Cancellazione dati documento inseriti [pagopa_t_riconciliazione_doc S].'||strMessaggioBck;
--         raise notice 'strMessaggio=%',strMessaggio;

         update pagopa_t_riconciliazione_doc doc
         set    pagopa_ric_doc_stato_elab='X',
			    pagopa_ric_errore_id=errore.pagopa_ric_errore_id,
                pagopa_ric_doc_subdoc_id=null,
                pagopa_ric_doc_movgest_ts_id=null,
                pagopa_ric_doc_provc_id=null,
                data_modifica=clock_timestamp(),
                login_operazione=split_part(doc.login_operazione,'@ELAB-'||filePagoPaElabId::varchar, 1)||'@ELAB-'||filePagoPaElabId::varchar
         from pagopa_t_elaborazione_flusso flusso,
              pagopa_d_riconciliazione_errore errore, siac_t_subdoc sub
         where flusso.pagopa_elab_id=filePagoPaElabId
         and   doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
         and   doc.pagopa_ric_doc_flag_con_dett=false -- 05.06.2019 SIAC-6720
         and   doc.pagopa_ric_doc_subdoc_id=sub.subdoc_id
         and   sub.doc_id=docId
         and   doc.login_operazione like '%@ELAB-'||filePagoPaElabId::varchar||'%'
         and   split_part(doc.login_operazione,'@ELAB-', 2)::integer=filePagoPaElabId
         and   errore.ente_proprietario_id=flusso.ente_proprietario_id
         and   errore.pagopa_ric_errore_code= pagoPaCodeErr
         and   flusso.data_cancellazione is null
         and   flusso.validita_fine is null
         and   sub.data_cancellazione is null
         and   sub.validita_fine is null;

		 strMessaggioLog:='Continue fnc_pagopa_t_elaborazione_riconc_esegui - '||strMessaggioFinale||strMessaggio;
         insert into pagopa_t_elaborazione_log
         (
         pagopa_elab_id,
         pagopa_elab_file_id,
         pagopa_elab_log_operazione,
         ente_proprietario_id,
         login_operazione,
         data_creazione
         )
         values
         (
         filePagoPaElabId,
         null,
         strMessaggioLog,
         enteProprietarioId,
         loginOperazione,
         clock_timestamp()
         );

	     strMessaggio:='Cancellazione dati documento inseriti [pagopa_t_riconciliazione_doc N].'||strMessaggioBck;
--         raise notice 'strMessaggio=%',strMessaggio;
		 update pagopa_t_riconciliazione_doc  docUPD
         set    pagopa_ric_doc_stato_elab='X',
			    pagopa_ric_errore_id=errore.pagopa_ric_errore_id,
                pagopa_ric_doc_subdoc_id=null,
                pagopa_ric_doc_movgest_ts_id=null,
                pagopa_ric_doc_provc_id=null,
                data_modifica=clock_timestamp(),
                login_operazione=split_part(docUPD.login_operazione,'@ELAB-'||filePagoPaElabId::varchar, 1)||'@ELAB-'||filePagoPaElabId::varchar
         from
         (
		  with
          pagopa as
          (
            select  doc.pagopa_ric_doc_id,
                    doc.pagopa_ric_doc_anno_accertamento,
                    doc.pagopa_ric_doc_num_accertamento,
                    doc.pagopa_ric_doc_codice_benef,
                    doc.pagopa_ric_id
          	from pagopa_t_elaborazione_flusso flusso,pagopa_t_riconciliazione_doc doc
            where  flusso.pagopa_elab_id=filePagoPaElabId
   	        and    doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
            and    doc.pagopa_ric_doc_tipo_id=pagoPaFlussoRec.pagopa_doc_tipo_id -- 30.05.2019 siac-6720
            and    coalesce(doc.pagopa_ric_doc_str_amm,'')=
                   coalesce(pagoPaFlussoRec.pagopa_str_amm,coalesce(doc.pagopa_ric_doc_str_amm,''))
            and    coalesce(doc.pagopa_ric_doc_voce_tematica,'')=
                   coalesce(pagoPaFlussoRec.pagopa_voce_tematica,coalesce(doc.pagopa_ric_doc_voce_tematica,''))
            and    doc.pagopa_ric_doc_voce_code=pagoPaFlussoRec.pagopa_voce_code
            and    coalesce(doc.pagopa_ric_doc_voce_desc,'')=coalesce(pagoPaFlussoRec.pagopa_voce_desc,coalesce(doc.pagopa_ric_doc_voce_desc,''))
--            and    doc.pagopa_ric_doc_sottovoce_code=pagoPaFlussoQuoteRec.pagopa_sottovoce_code
--            and    coalesce(doc.pagopa_ric_doc_sottovoce_desc,'')=
--                   coalesce(pagoPaFlussoQuoteRec.pagopa_sottovoce_desc,coalesce(doc.pagopa_ric_doc_sottovoce_desc,''))
--            and    flusso.pagopa_elab_ric_flusso_id=pagoPaFlussoQuoteRec.pagopa_flusso_id
--            and    flusso.pagopa_elab_flusso_nome_mittente=pagoPaFlussoQuoteRec.pagopa_flusso_nome_mittente
--            and    flusso.pagopa_elab_flusso_anno_provvisorio=pagoPaFlussoQuoteRec.pagopa_anno_provvisorio
--            and    flusso.pagopa_elab_flusso_num_provvisorio=pagoPaFlussoQuoteRec.pagopa_num_provvisorio
--            and    doc.pagopa_ric_doc_anno_accertamento=pagoPaFlussoQuoteRec.pagopa_anno_accertamento
--    		and    doc.pagopa_ric_doc_num_accertamento=pagoPaFlussoQuoteRec.pagopa_num_accertamento
            and    doc.pagopa_ric_doc_stato_elab = 'N'
			and    doc.pagopa_ric_doc_subdoc_id is null
            and   doc.pagopa_ric_doc_flag_con_dett=false -- 05.06.2019 SIAC-6720
  /*   		and   not exists -- tutti record di un flusso da elaborare e senza scarti o errori
   		    (
		     select 1
		     from pagopa_t_riconciliazione_doc doc1
		     where doc1.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
		     and   doc1.pagopa_ric_doc_stato_elab not in ('N','S')
		     and   doc1.data_cancellazione is null
		     and   doc1.validita_fine is null
		    )*/
		    and   doc.data_cancellazione is null
		    and   doc.validita_fine is null
	     	and   flusso.data_cancellazione is null
		    and   flusso.validita_fine is null
          ),
          -- 23.07.2019 siac-6963
          accertamenti_sog as
          (
           with
           accertamenti as
           (
            select ts.movgest_ts_id
            from siac_t_movgest mov, siac_t_movgest_ts ts, siac_r_movgest_ts_stato rs
            where mov.bil_id=bilancioID
            and   mov.movgest_tipo_id=movgestTipoId
            and   ts.movgest_id=mov.movgest_id
            and   ts.movgest_ts_tipo_id=movgestTsTipoId
            and   rs.movgest_ts_id=ts.movgest_ts_id
            and   rs.movgest_stato_id=movgestStatoId
            and   rsog.movgest_ts_id=ts.movgest_ts_id
  --          and   mov.movgest_anno::integer=pagoPaFlussoQuoteRec.pagopa_anno_accertamento
  --          and   mov.movgest_numero::integer=pagoPaFlussoQuoteRec.pagopa_num_accertamento
            and   mov.data_cancellazione is null
            and   date_trunc('DAY',now())>=date_trunc('DAY',mov.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(mov.validita_fine,date_trunc('DAY',now())))
            and   ts.data_cancellazione is null
            and   date_trunc('DAY',now())>=date_trunc('DAY',ts.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(ts.validita_fine,date_trunc('DAY',now())))
            and   rs.data_cancellazione is null
            and   date_trunc('DAY',now())>=date_trunc('DAY',rs.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(rs.validita_fine,date_trunc('DAY',now())))
           ),
           sog_acc as
           (
            select sog.soggetto_id, sog.soggetto_code, sog.soggetto_desc, rsog.movgest_ts_id
            from siac_t_soggetto sog,siac_r_movgest_ts_sog rsog
            where sog.ente_proprietario_id=enteProprietarioId
            and   rsog.soggetto_id=sog.soggetto_id
            and   sog.data_cancellazione is null
            and   date_trunc('DAY',now())>=date_trunc('DAY',sog.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(sog.validita_fine,date_trunc('DAY',now())))
            and   rsog.data_cancellazione is null
            and   date_trunc('DAY',now())>=date_trunc('DAY',rsog.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(rsog.validita_fine,date_trunc('DAY',now())))
           )
           select accertamenti.movgest_ts_id, sog_acc.soggetto_id
           from accertamenti left join sog_acc on (accertamenti.movgest_ts_id=sog_acc.movgest_ts_id)
          ),
          sog as
          (
          select sog.soggetto_id, sog.soggetto_code, sog.soggetto_desc
          from siac_t_soggetto sog
          where sog.ente_proprietario_id=enteProprietarioId
          and   sog.data_cancellazione is null
          and   date_trunc('DAY',now())>=date_trunc('DAY',sog.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(sog.validita_fine,date_trunc('DAY',now())))
          )
          select pagopa.pagopa_ric_doc_id,
                 (case when s1.soggetto_id is not null then s1.soggetto_id else accertamenti_sog.soggetto_id end ) pagopa_soggetto_id,
                 pagopa.pagopa_ric_id
          from pagopa left join sog s1 on (pagopa.pagopa_ric_doc_codice_benef=s1.soggetto_code),
---               accertamenti join sog s2 on (accertamenti.soggetto_id=s2.soggetto_id) -- 22.07.2019 siac-6963
               accertamenti_sog -- 22.07.2019 siac-6963

         ) query,pagopa_d_riconciliazione_errore errore
         where docUPD.ente_proprietario_id=enteProprietarioId
--         and   docUPD.pagopa_ric_doc_stato_elab='N'
         and   docUPD.pagopa_ric_doc_id=QUERY.pagopa_ric_doc_id
         and   QUERY.pagopa_soggetto_id=pagoPaFlussoRec.pagopa_soggetto_id
         and   errore.ente_proprietario_id=docUPD.ente_proprietario_id
         and   errore.pagopa_ric_errore_code= pagoPaCodeErr
         and   docUPD.data_cancellazione is null
         and   docUPD.validita_fine is null;

  		 strMessaggioLog:='Continue fnc_pagopa_t_elaborazione_riconc_esegui - '||strMessaggioFinale||strMessaggio;
         insert into pagopa_t_elaborazione_log
         (
         pagopa_elab_id,
         pagopa_elab_file_id,
         pagopa_elab_log_operazione,
         ente_proprietario_id,
         login_operazione,
         data_creazione
         )
         values
         (
         filePagoPaElabId,
         null,
         strMessaggioLog,
         enteProprietarioId,
         loginOperazione,
         clock_timestamp()
         );

         -- 11.06.2019 SIAC-6720
         strMessaggio:='Cancellazione dati documento inseriti [pagopa_t_modifica_elab].'||strMessaggioBck;
--         raise notice 'strMessaggio=%',strMessaggio;
		 update pagopa_t_modifica_elab r
         set    pagopa_modifica_elab_note='DOCUMENTO CANCELLATO IN ESEGUI PER pagoPaCodeErr='||pagoPaCodeErr||' ',
                subdoc_id=null
         from 	siac_t_subdoc doc where doc.doc_id=docId and r.subdoc_id=doc.subdoc_id;

         strMessaggio:='Cancellazione dati documento inseriti [siac_r_subdoc_movgest_ts].'||strMessaggioBck;
--         raise notice 'strMessaggio=%',strMessaggio;

         delete from siac_r_subdoc_movgest_ts r
         using siac_t_subdoc doc where doc.doc_id=docId and r.subdoc_id=doc.subdoc_id;

		 strMessaggio:='Cancellazione dati documento inseriti [siac_r_subdoc_attr].'||strMessaggioBck;
         delete from siac_r_subdoc_attr r
         using siac_t_subdoc doc where doc.doc_id=docId and r.subdoc_id=doc.subdoc_id;
		 strMessaggio:='Cancellazione dati documento inseriti [siac_r_subdoc_atto_amm].'||strMessaggioBck;
         delete from siac_r_subdoc_atto_amm r
         using siac_t_subdoc doc where doc.doc_id=docId and r.subdoc_id=doc.subdoc_id;
		 strMessaggio:='Cancellazione dati documento inseriti [siac_r_subdoc_prov_cassa].'||strMessaggioBck;
         delete from siac_r_subdoc_prov_cassa r
         using siac_t_subdoc doc where doc.doc_id=docId and r.subdoc_id=doc.subdoc_id;
		 strMessaggio:='Cancellazione dati documento inseriti [siac_t_subdoc].'||strMessaggioBck;
         delete from siac_t_subdoc doc where doc.doc_id=docId;
		 strMessaggio:='Cancellazione dati documento inseriti [siac_r_doc_sog].'||strMessaggioBck;
         delete from siac_r_doc_sog doc where doc.doc_id=docId;
		 strMessaggio:='Cancellazione dati documento inseriti [siac_r_doc_stato].'||strMessaggioBck;
         delete from siac_r_doc_stato doc where doc.doc_id=docId;
		 strMessaggio:='Cancellazione dati documento inseriti [siac_r_doc_attr].'||strMessaggioBck;
         delete from siac_r_doc_attr doc where doc.doc_id=docId;
		 strMessaggio:='Cancellazione dati documento inseriti [siac_r_doc_class].'||strMessaggioBck;
         delete from siac_r_doc_class doc where doc.doc_id=docId;
		 strMessaggio:='Cancellazione dati documento inseriti [siac_t_registrounico_doc].'||strMessaggioBck;
         delete from siac_t_registrounico_doc doc where doc.doc_id=docId;
		 strMessaggio:='Cancellazione dati documento inseriti [siac_t_subdoc_num].'||strMessaggioBck;
         delete from siac_t_subdoc_num doc where doc.doc_id=docId;
		 strMessaggio:='Cancellazione dati documento inseriti [siac_t_doc].'||strMessaggioBck;
         delete from siac_t_doc doc where doc.doc_id=docId;

		 strMessaggioLog:=strMessaggioFinale||strMessaggio||' - Continue fnc_pagopa_t_elaborazione_riconc_esegui.';
         insert into pagopa_t_elaborazione_log
         (
         pagopa_elab_id,
         pagopa_elab_file_id,
         pagopa_elab_log_operazione,
         ente_proprietario_id,
         login_operazione,
         data_creazione
         )
         values
         (
         filePagoPaElabId,
         null,
         strMessaggioLog,
         enteProprietarioId,
         loginOperazione,
         clock_timestamp()
         );

       end if;


  end loop;


  strMessaggioLog:='Continue fnc_pagopa_t_elaborazione_riconc_esegui - Fine ciclo caricamento documenti - '||strMessaggioFinale;
--  raise notice 'strMessaggioLog=%',strMessaggioLog;
  insert into pagopa_t_elaborazione_log
  (
   pagopa_elab_id,
   pagopa_elab_file_id,
   pagopa_elab_log_operazione,
   ente_proprietario_id,
   login_operazione,
   data_creazione
  )
  values
  (
   filePagoPaElabId,
   null,
   strMessaggioLog,
   enteProprietarioId,
   loginOperazione,
   clock_timestamp()
  );

  -- richiamare function per gestire anomalie e errori su provvisori e flussi in generale
  -- su elaborazione
  -- controllare ogni flusso/provvisorio
  strMessaggio:='Chiamata fnc.';
  select * into  fncRec
  from fnc_pagopa_t_elaborazione_riconc_esegui_clean
  (
    filePagoPaElabId,
    annoBilancioElab,
    enteProprietarioId,
    loginOperazione,
    dataElaborazione
  );
  if fncRec.codiceRisultato=0 then
    if fncRec.pagopaBckSubdoc=true then
    	pagoPaCodeErr:=PAGOPA_ERR_36;
    end if;
  else
  	raise exception '%',fncRec.messaggiorisultato;
  end if;

  -- aggiornare siac_t_registrounico_doc_num
  codResult:=null;
  strMessaggio:='Aggiornamento numerazione su siac_t_registrounico_doc_num.';
  update siac_t_registrounico_doc_num num
  set    rudoc_registrazione_numero= coalesce(QUERY.rudoc_registrazione_numero,0),
         data_modifica=clock_timestamp(),
         login_operazione=num.login_operazione||'-'||loginOperazione
  from
  (
   select max(doc.rudoc_registrazione_numero::integer) rudoc_registrazione_numero
   from  siac_t_registrounico_doc doc
   where doc.ente_proprietario_id=enteProprietarioId
   and   doc.rudoc_registrazione_anno::integer=annoBilancio
   and   doc.data_cancellazione is null
   and   date_trunc('DAY',now())>=date_trunc('DAY',doc.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(doc.validita_fine,date_trunc('DAY',now())))
  ) QUERY
  where num.ente_proprietario_id=enteProprietarioId
  and   num.rudoc_registrazione_anno=annoBilancio
  and   num.data_cancellazione is null
  and   date_trunc('DAY',now())>=date_trunc('DAY',num.validita_inizio) and date_trunc('DAY',now())<=date_trunc('DAY',coalesce(num.validita_fine,date_trunc('DAY',now())));
 -- returning num.rudoc_num_id into codResult;
  --if codResult is null then
  --	raise exception 'Errore in fase di aggiornamento.';
  --end if;



  -- chiusura della elaborazione, siac_t_file per errore in generazione per aggiornare pagopa_ric_errore_id
  if coalesce(pagoPaCodeErr,' ') in (PAGOPA_ERR_30,PAGOPA_ERR_31,PAGOPA_ERR_32,PAGOPA_ERR_33,PAGOPA_ERR_36,PAGOPA_ERR_39) then
     strMessaggio:=' Aggiornamento pagopa_t_elaborazione.';
	 update pagopa_t_elaborazione elab
     set    data_modifica=clock_timestamp(),
            pagopa_elab_stato_id=statonew.pagopa_elab_stato_id,
            pagopa_elab_errore_id=err.pagopa_ric_errore_id,
            pagopa_elab_note=
            substr(
             (
              'AGGIORNAMENTO PER ERR.='||(case when pagoPaCodeErr=PAGOPA_ERR_36 then PAGOPA_ERR_36 else PAGOPA_ERR_30 end )::varchar||'.'
              ||elab.pagopa_elab_note
             ),1,1500) -- 09.10.2019 Sofia
     from  pagopa_d_elaborazione_stato statonew,pagopa_d_riconciliazione_errore err
     where elab.pagopa_elab_id=filePagoPaElabId
     and   statonew.ente_proprietario_id=elab.ente_proprietario_id
     and   statonew.pagopa_elab_stato_code=ELABORATO_IN_CORSO_ER_ST
     and   err.ente_proprietario_id=statonew.ente_proprietario_id
     and   err.pagopa_ric_errore_code=(case when pagoPaCodeErr=PAGOPA_ERR_36 then PAGOPA_ERR_36 else PAGOPA_ERR_30 end )
     and   elab.data_cancellazione is null
     and   elab.validita_fine is null;



    strMessaggio:=' Aggiornamento siac_t_file_pagopa.';
    update siac_t_file_pagopa file
    set    data_modifica=clock_timestamp(),
           file_pagopa_stato_id=stato.file_pagopa_stato_id,
           file_pagopa_errore_id=err.pagopa_ric_errore_id,
           file_pagopa_note=
                  substr(
                    ('AGGIORNAMENTO PER ERR.='||(case when pagoPaCodeErr=PAGOPA_ERR_36 then PAGOPA_ERR_36 else PAGOPA_ERR_30 end )::varchar||'.'
                     ||file.file_pagopa_note
                    ),1,1500), -- 09.10.2019 Sofia
           login_operazione=substr(loginOperazione||'-'||file.login_operazione,1,200) -- 09.10.2019 Sofia
    from  pagopa_r_elaborazione_file r,
          siac_d_file_pagopa_stato stato,pagopa_d_riconciliazione_errore err
    where r.pagopa_elab_id=filePagoPaElabId
    and   file.file_pagopa_id=r.file_pagopa_id
    and   stato.ente_proprietario_id=file.ente_proprietario_id
    and   err.ente_proprietario_id=stato.ente_proprietario_id
    and   err.pagopa_ric_errore_code=(case when pagoPaCodeErr=PAGOPA_ERR_36 then PAGOPA_ERR_36 else PAGOPA_ERR_30 end )
    and   r.data_cancellazione is null
    and   r.validita_fine is null;

  end if;

  strMessaggio:='Verifica dettaglio elaborati per chiusura pagopa_t_elaborazione.';
--  raise notice 'strMessaggio=%',strMessaggio;

  codResult:=null;
  select 1 into codResult
  from  pagopa_t_riconciliazione_doc doc, pagopa_t_elaborazione_flusso flusso
  where flusso.pagopa_elab_id=filePagoPaElabId
  and   doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
  and   doc.pagopa_ric_doc_subdoc_id is not null
  and   doc.pagopa_ric_doc_stato_elab='S'
  and   flusso.data_cancellazione is null
  and   flusso.validita_fine is null
  and   doc.data_cancellazione is null
  and   doc.validita_fine is null;
  -- ELABORATO_KO_ST ELABORATO_OK_SE
  if codResult is not null then
  	  codResult:=null;
      select 1 into codResult
      from  pagopa_t_riconciliazione_doc doc, pagopa_t_elaborazione_flusso flusso
      where flusso.pagopa_elab_id=filePagoPaElabId
      and   doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
      and   doc.pagopa_ric_doc_subdoc_id is null
      and   doc.pagopa_ric_doc_flag_con_dett=false -- 05.06.2019 SIAC-6720
      and   doc.pagopa_ric_doc_stato_elab in ('X','E','N')
      and   flusso.data_cancellazione is null
      and   flusso.validita_fine is null
      and   doc.data_cancellazione is null
      and   doc.validita_fine is null;
      -- se ci sono S e X,E,N KO
      if codResult is not null then
            pagoPaCodeErr:=ELABORATO_KO_ST;
      -- se si sono solo S OK
      else  pagoPaCodeErr:=ELABORATO_OK_ST;
      end if;
  else -- se non esiste neanche un S allora elaborazione errata o scartata
	  codResult:=null;
      select 1 into codResult
      from  pagopa_t_riconciliazione_doc doc, pagopa_t_elaborazione_flusso flusso
      where flusso.pagopa_elab_id=filePagoPaElabId
      and   doc.pagopa_elab_flusso_id=flusso.pagopa_elab_flusso_id
      and   doc.pagopa_ric_doc_subdoc_id is null
      and   doc.pagopa_ric_doc_flag_con_dett=false -- 05.06.2019 SIAC-6720
      and   doc.pagopa_ric_doc_stato_elab='X'
      and   flusso.data_cancellazione is null
      and   flusso.validita_fine is null
      and   doc.data_cancellazione is null
      and   doc.validita_fine is null;
      if codResult is not null then
            pagoPaCodeErr:=ELABORATO_SCARTATO_ST;
      else  pagoPaCodeErr:=ELABORATO_ERRATO_ST;
      end if;
  end if;

  strMessaggio:='Aggiornamento pagopa_t_elaborazione in stato='||pagoPaCodeErr||'.';

  --  strMessaggioFinale:='CHIUSURA - '||upper(strMessaggioFinale||' '||strMessaggio); -- 09.10.2019 Sofia
  strMessaggioFinale:='CHIUSURA - '||substr(upper(strMessaggio||' '||strMessaggioFinale),1,1450); -- 09.10.2019 Sofia

  update pagopa_t_elaborazione elab
  set    data_modifica=clock_timestamp(),
  		 validita_fine=clock_timestamp(),
         pagopa_elab_stato_id=statonew.pagopa_elab_stato_id,
         pagopa_elab_note=strMessaggioFinale
  from  pagopa_d_elaborazione_stato statonew
  where elab.pagopa_elab_id=filePagoPaElabId
  and   statonew.ente_proprietario_id=elab.ente_proprietario_id
  and   statonew.pagopa_elab_stato_code=pagoPaCodeErr
  and   elab.data_cancellazione is null
  and   elab.validita_fine is null;

  strMessaggio:='Verifica dettaglio elaborati per chiusura siac_t_file_pagopa.';
  for elabRec in
  (
  select r.file_pagopa_id
  from pagopa_r_elaborazione_file r
  where r.pagopa_elab_id=filePagoPaElabId
  and   r.data_cancellazione is null
  and   r.validita_fine is null
  order by r.file_pagopa_id
  )
  loop

    -- chiusura per siac_t_file_pagopa
    -- capire se ho chiuso per bene pagopa_t_riconciliazione
    -- se esistono S Ok o in corso
    --    se esistono N non elaborati  IN_CORSO no chiusura
    --    se esistono X scartati IN_CORSO_SC no chiusura
    --    se esistono E errati   IN_CORSO_ER no chiusura
    --    se non esistono!=S FINE ELABORATO_Ok con chiusura
    -- se non esistono S, in corso
    --    se esistono N IN_CORSO no chiusura
    --    se esistono X scartati IN_CORSO_SC non chiusura
    --    se esistono E errati IN_CORSO_ER non chiusura
    strMessaggio:='Verifica dettaglio elaborati per chiusura siac_t_file_pagopa file_pagopa_id='||elabRec.file_pagopa_id::varchar||'.';
    codResult:=null;
    pagoPaCodeErr:=null;
    select 1 into codResult
    from  pagopa_t_riconciliazione ric
    where  ric.file_pagopa_id=elabRec.file_pagopa_id
    and   ric.pagopa_ric_flusso_stato_elab='S'
    and   ric.data_cancellazione is null
    and   ric.validita_fine is null;

    if codResult is not null then
      codResult:=null;
      select 1 into codResult
      from  pagopa_t_riconciliazione ric
      where ric.file_pagopa_id=elabRec.file_pagopa_id
      and   ric.pagopa_ric_flusso_stato_elab='N'
  --    and   ric.pagopa_ric_flusso_flag_con_dett=false -- 31.05.2019 siac-6720
      and   ric.data_cancellazione is null
      and   ric.validita_fine is null;

      if codResult is not null then
          pagoPaCodeErr:=ELABORATO_IN_CORSO_ST;
      end if;

      codResult:=null;
      select 1 into codResult
      from  pagopa_t_riconciliazione ric
      where ric.file_pagopa_id=elabRec.file_pagopa_id
      and   ric.pagopa_ric_flusso_stato_elab='X'
      and   ric.data_cancellazione is null
      and   ric.validita_fine is null;

      if codResult is not null then
          pagoPaCodeErr:=ELABORATO_IN_CORSO_SC_ST;
      end if;

      codResult:=null;
      select 1 into codResult
      from  pagopa_t_riconciliazione ric
      where ric.file_pagopa_id=elabRec.file_pagopa_id
      and   ric.pagopa_ric_flusso_stato_elab='E'
      and   ric.data_cancellazione is null
      and   ric.validita_fine is null;

      if codResult is not null then
          pagoPaCodeErr:=ELABORATO_IN_CORSO_ER_ST;
      end if;

      codResult:=null;
      select 1 into codResult
      from  pagopa_t_riconciliazione ric
      where ric.file_pagopa_id=elabRec.file_pagopa_id
      and   ric.pagopa_ric_flusso_stato_elab!='S'
    --  and   ric.pagopa_ric_flusso_flag_con_dett=false -- 31.05.2019 siac-6720
      and   ric.data_cancellazione is null
      and   ric.validita_fine is null;

      if codResult is null then
          pagoPaCodeErr:=ELABORATO_OK_ST;
      end if;

    else
      codResult:=null;
      select 1 into codResult
      from  pagopa_t_riconciliazione ric
      where ric.file_pagopa_id=elabRec.file_pagopa_id
      and   ric.pagopa_ric_flusso_stato_elab='N'
   --   and   ric.pagopa_ric_flusso_flag_con_dett=false -- 31.05.2019 siac-6720
      and   ric.data_cancellazione is null
      and   ric.validita_fine is null;

      if codResult is not null then
          pagoPaCodeErr:=ELABORATO_IN_CORSO_ST;
      end if;

      codResult:=null;
      select 1 into codResult
      from  pagopa_t_riconciliazione ric
      where ric.file_pagopa_id=elabRec.file_pagopa_id
      and   ric.pagopa_ric_flusso_stato_elab='X'
      and   ric.data_cancellazione is null
      and   ric.validita_fine is null;

      if codResult is not null then
          pagoPaCodeErr:=ELABORATO_IN_CORSO_SC_ST;
      end if;

      codResult:=null;
      select 1 into codResult
      from  pagopa_t_riconciliazione ric
      where ric.file_pagopa_id=elabRec.file_pagopa_id
      and   ric.pagopa_ric_flusso_stato_elab='E'
      and   ric.data_cancellazione is null
      and   ric.validita_fine is null;

      if codResult is not null then
          pagoPaCodeErr:=ELABORATO_IN_CORSO_ER_ST;
      end if;

    end if;

    if pagoPaCodeErr is not null then
       strMessaggio:='Aggiornamento siac_t_file_pagopa in stato='||pagoPaCodeErr||'.';

--       strMessaggioFinale:='CHIUSURA - '||upper(strMessaggioFinale||' '||strMessaggio); -- 09.10.2019 Sofia
       strMessaggioFinale:='CHIUSURA - '||substr(upper(strMessaggio||' '||strMessaggioFinale),1,1450); -- 09.10.2019 Sofia

       update siac_t_file_pagopa file
       set    data_modifica=clock_timestamp(),
              validita_fine=(case when pagoPaCodeErr=ELABORATO_OK_ST then clock_timestamp() else null end),
              file_pagopa_stato_id=stato.file_pagopa_stato_id,
              file_pagopa_note=file.file_pagopa_note||upper(strMessaggioFinale),
              login_operazione=file.login_operazione||'-'||loginOperazione
       from  siac_d_file_pagopa_stato stato,pagopa_d_riconciliazione_errore err
       where file.file_pagopa_id=elabRec.file_pagopa_id
       and   stato.ente_proprietario_id=file.ente_proprietario_id
       and   stato.file_pagopa_stato_code=pagoPaCodeErr;

    end if;

  end loop;

  messaggioRisultato:='OK VERIFICARE STATO ELAB. - '||upper(strMessaggioFinale);
-- raise notice 'messaggioRisultato=%',messaggioRisultato;
  return;


exception
    when RAISE_EXCEPTION THEN
        messaggioRisultato:=
        	coalesce(strMessaggioFinale,'')||coalesce(strMessaggio,'')||'ERRORE:  '||' '||coalesce(substring(upper(SQLERRM) from 1 for 500),'') ;
       	codiceRisultato:=-1;

		messaggioRisultato:=upper(messaggioRisultato);

        return;
     when NO_DATA_FOUND THEN
        messaggioRisultato:=strMessaggioFinale||coalesce(strMessaggio,'')||' Nessun dato presente in archivio.';
        codiceRisultato:=-1;
        messaggioRisultato:=upper(messaggioRisultato);

        return;
     when TOO_MANY_ROWS THEN
        messaggioRisultato:=strMessaggioFinale||coalesce(strMessaggio,'')||' Diverse righe presenti in archivio.';
        codiceRisultato:=-1;
        messaggioRisultato:=upper(messaggioRisultato);

        return;
	when others  THEN
        messaggioRisultato:=strMessaggioFinale||coalesce(strMessaggio,'')||'ERRORE DB:'||SQLSTATE||' '||substring(upper(SQLERRM) from 1 for 500) ;
        codiceRisultato:=-1;
        messaggioRisultato:=upper(messaggioRisultato);
        return;

END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;

-- SIAC-SIAC-7089 - Sofia - 14.10.2019 - fine

-- elabora atti amm per stilo

SELECT * from fnc_dba_add_column_params ('siac_t_atto_amm', 'attoamm_blocco', 'BOOLEAN');
SELECT * from fnc_dba_add_column_params ('siac_t_atto_amm', 'attoamm_provenienza', 'VARCHAR(200)');

-- elabora atti amm per stilo FINE


-- SIAC-6879 FINE


--SIAC-7012 - Maurizio - INIZIO
DROP FUNCTION if exists siac."BILR000_tipo_capitolo_dei_report"(p_ente_prop_id integer, p_anno varchar, p_fase_bilancio varchar);

CREATE OR REPLACE FUNCTION siac."BILR000_tipo_capitolo_dei_report" (
  p_ente_prop_id integer,
  p_anno varchar,
  p_fase_bilancio varchar
)
RETURNS TABLE (
  anno_competenza varchar,
  importo numeric,
  descrizione varchar,
  posizione_nel_report integer,
  codice_importo varchar,
  tipo_capitolo_cod varchar
) AS
$body$
DECLARE

classifBilRec record;
tipo_capitolo record;
tipoAvanzo varchar;
tipoDisavanzo varchar;
tipoFpvcc varchar;
tipoFpvsc varchar;
tipoFCassaIni varchar;
tipoFpv varchar;
tipoDisavanzoDanc varchar;
elemTipoCodeE varchar;
elemTipoCodeS varchar;
RTN_MESSAGGIO varchar(1000):='';

annoCapImp varchar;
annoCapImp1 varchar;
annoCapImp2 varchar;

BEGIN

anno_competenza='';
importo=0;
descrizione='';
posizione_nel_report=0;
codice_importo='';
tipoAvanzo='AAM';
tipoDisavanzo='DAM';
tipoFpvcc='FPVCC';
tipoFpvsc='FPVSC';
tipoFCassaIni='FCI';
tipoFpv='FPV'; 
--SIAC-7012 24/09/2019.
--  Introdotta la categoria capitolo DDANC - DISAVANZO DERIVANTE DA DEBITO AUTORIZZATO E NON CONTRATTO 
tipoDisavanzoDanc='DDANC';
tipo_capitolo_cod='';

IF p_fase_bilancio = 'P' THEN
      elemTipoCodeE:='CAP-EP'; -- tipo capitolo previsione
      elemTipoCodeS:='CAP-UP'; -- tipo capitolo previsione
ELSIF p_fase_bilancio = 'G' THEN
      elemTipoCodeE:='CAP-EG'; -- tipo capitolo gestione
      elemTipoCodeS:='CAP-UG'; -- tipo capitolo gestione
END IF;

annoCapImp:= p_anno; 
annoCapImp1:= ((p_anno::INTEGER)+1)::VARCHAR;   
annoCapImp2:= ((p_anno::INTEGER)+2)::VARCHAR; 


 

for tipo_capitolo in
        select 		
			capitolo_imp_periodo.anno          anno_competenza,
            cat_del_capitolo.elem_cat_code	   codice_importo,
            sum(coalesce(capitolo_importi.elem_det_importo,0)) importo,  
            tipo_elemento.elem_tipo_code tipo_capitolo_cod
        from 		
            siac_t_bil_elem_det capitolo_importi,
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
        and	anno_eserc.anno						= 	p_anno						
    	and	bilancio.periodo_id					=	anno_eserc.periodo_id 								
        and	capitolo.bil_id						=	bilancio.bil_id 			 
        and	capitolo.elem_id					=	capitolo_importi.elem_id 
        and	capitolo.elem_tipo_id				=	tipo_elemento.elem_tipo_id 						
        and	tipo_elemento.elem_tipo_code 		in (elemTipoCodeE,elemTipoCodeS)
        and	capitolo_importi.elem_det_tipo_id	=	capitolo_imp_tipo.elem_det_tipo_id
        and	capitolo_imp_tipo.elem_det_tipo_code	=	'STA' 		
        and	capitolo_imp_periodo.periodo_id		=	capitolo_importi.periodo_id 			  
        and	capitolo_imp_periodo.anno           in (annoCapImp,annoCapImp1,annoCapImp2)
        and	capitolo.elem_id					=	r_capitolo_stato.elem_id
		and	r_capitolo_stato.elem_stato_id		=	stato_capitolo.elem_stato_id
		and	stato_capitolo.elem_stato_code		=	'VA'
		and	capitolo.elem_id					=	r_cat_capitolo.elem_id
		and	r_cat_capitolo.elem_cat_id			=	cat_del_capitolo.elem_cat_id
		--and	cat_del_capitolo.elem_cat_code		in (tipoAvanzo,tipoDisavanzo,tipoFpvcc,tipoFpvsc,tipoFCassaIni)	
        
			--SIAC-7012 24/09/2019.
			--  Introdotta la categoria capitolo DDANC - 
            --  DISAVANZO DERIVANTE DA DEBITO AUTORIZZATO E NON CONTRATTO 
        and	cat_del_capitolo.elem_cat_code		in (tipoAvanzo,tipoDisavanzo,
        			tipoFpvcc,tipoFpvsc, tipoDisavanzoDanc)	
        and	capitolo_importi.data_cancellazione 	is null
        and	capitolo_imp_tipo.data_cancellazione 	is null
        and	capitolo_imp_periodo.data_cancellazione is null
        and	capitolo.data_cancellazione 			is null
        and	tipo_elemento.data_cancellazione 		is null
        and	bilancio.data_cancellazione 			is null
        and	anno_eserc.data_cancellazione 			is null
        and	stato_capitolo.data_cancellazione 		is null
        and	r_capitolo_stato.data_cancellazione 	is null
        and	cat_del_capitolo.data_cancellazione 	is null
        and	r_cat_capitolo.data_cancellazione 		is null
        group by cat_del_capitolo.elem_cat_code, capitolo_imp_periodo.anno, tipo_elemento.elem_tipo_code
UNION -- Fondo cassa Iniziale - Entrata e spesa
        select 		
			capitolo_imp_periodo.anno          anno_competenza,
            cat_del_capitolo.elem_cat_code	   codice_importo,
            sum(coalesce(capitolo_importi.elem_det_importo,0)) importo,  
            tipo_elemento.elem_tipo_code tipo_capitolo_cod
        from 		
            siac_t_bil_elem_det capitolo_importi,
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
        and	anno_eserc.anno						= 	p_anno						
    	and	bilancio.periodo_id					=	anno_eserc.periodo_id 								
        and	capitolo.bil_id						=	bilancio.bil_id 			 
        and	capitolo.elem_id					=	capitolo_importi.elem_id 
        and	capitolo.elem_tipo_id				=	tipo_elemento.elem_tipo_id 						
        and	tipo_elemento.elem_tipo_code 		in (elemTipoCodeE,elemTipoCodeS)
        and	capitolo_importi.elem_det_tipo_id	=	capitolo_imp_tipo.elem_det_tipo_id
        and	capitolo_imp_tipo.elem_det_tipo_code	=	'SCA' 		
        and	capitolo_imp_periodo.periodo_id		=	capitolo_importi.periodo_id 			  
        and	capitolo_imp_periodo.anno           in (annoCapImp,annoCapImp1,annoCapImp2)
        and	capitolo.elem_id					=	r_capitolo_stato.elem_id
		and	r_capitolo_stato.elem_stato_id		=	stato_capitolo.elem_stato_id
		and	stato_capitolo.elem_stato_code		=	'VA'
		and	capitolo.elem_id					=	r_cat_capitolo.elem_id
		and	r_cat_capitolo.elem_cat_id			=	cat_del_capitolo.elem_cat_id
		--and	cat_del_capitolo.elem_cat_code		in (tipoAvanzo,tipoDisavanzo,tipoFpvcc,tipoFpvsc,tipoFCassaIni)	
		and	cat_del_capitolo.elem_cat_code		in (tipoFCassaIni)	
        and	capitolo_importi.data_cancellazione 	is null
        and	capitolo_imp_tipo.data_cancellazione 	is null
        and	capitolo_imp_periodo.data_cancellazione is null
        and	capitolo.data_cancellazione 			is null
        and	tipo_elemento.data_cancellazione 		is null
        and	bilancio.data_cancellazione 			is null
        and	anno_eserc.data_cancellazione 			is null
        and	stato_capitolo.data_cancellazione 		is null
        and	r_capitolo_stato.data_cancellazione 	is null
        and	cat_del_capitolo.data_cancellazione 	is null
        and	r_cat_capitolo.data_cancellazione 		is null
        group by cat_del_capitolo.elem_cat_code, capitolo_imp_periodo.anno, tipo_elemento.elem_tipo_code
    UNION  -- FPV - Entrata
        select 		
			capitolo_imp_periodo.anno          anno_competenza,
            tipoFpv	   codice_importo,
            sum(coalesce(capitolo_importi.elem_det_importo,0)) importo,  
            tipo_elemento.elem_tipo_code tipo_capitolo_cod
        from 		
            siac_t_bil_elem_det capitolo_importi,
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
        and	anno_eserc.anno						= 	p_anno						
    	and	bilancio.periodo_id					=	anno_eserc.periodo_id 								
        and	capitolo.bil_id						=	bilancio.bil_id 			 
        and	capitolo.elem_id					=	capitolo_importi.elem_id 
        and	capitolo.elem_tipo_id				=	tipo_elemento.elem_tipo_id 						
        and	tipo_elemento.elem_tipo_code 		=   elemTipoCodeE
        and	capitolo_importi.elem_det_tipo_id	=	capitolo_imp_tipo.elem_det_tipo_id
        and	capitolo_imp_tipo.elem_det_tipo_code	=	'STA' 		
        and	capitolo_imp_periodo.periodo_id		=	capitolo_importi.periodo_id 			  
        and	capitolo_imp_periodo.anno           in (annoCapImp,annoCapImp1,annoCapImp2)
        and	capitolo.elem_id					=	r_capitolo_stato.elem_id
		and	r_capitolo_stato.elem_stato_id		=	stato_capitolo.elem_stato_id
		and	stato_capitolo.elem_stato_code		=	'VA'
		and	capitolo.elem_id					=	r_cat_capitolo.elem_id
		and	r_cat_capitolo.elem_cat_id			=	cat_del_capitolo.elem_cat_id
		and	cat_del_capitolo.elem_cat_code		in (tipoFpvcc,tipoFpvsc)	
        and	capitolo_importi.data_cancellazione 	is null
        and	capitolo_imp_tipo.data_cancellazione 	is null
        and	capitolo_imp_periodo.data_cancellazione is null
        and	capitolo.data_cancellazione 			is null
        and	tipo_elemento.data_cancellazione 		is null
        and	bilancio.data_cancellazione 			is null
        and	anno_eserc.data_cancellazione 			is null
        and	stato_capitolo.data_cancellazione 		is null
        and	r_capitolo_stato.data_cancellazione 	is null
        and	cat_del_capitolo.data_cancellazione 	is null
        and	r_cat_capitolo.data_cancellazione 		is null
        group by capitolo_imp_periodo.anno, tipo_elemento.elem_tipo_code
   UNION
        select 		
			p_anno          anno_competenza,
            'IMP_GEN'	   codice_importo,
            0 importo,  
            elemTipoCodeS tipo_capitolo_cod  
  UNION
        select 		
			p_anno          anno_competenza,
            'IMP_GEN'	   codice_importo,
            0 importo,  
            elemTipoCodeE tipo_capitolo_cod           
loop
     

       anno_competenza := tipo_capitolo.anno_competenza;
       codice_importo := tipo_capitolo.codice_importo;
       importo := tipo_capitolo.importo;
       descrizione := '';
       posizione_nel_report := 0;
       tipo_capitolo_cod := tipo_capitolo.tipo_capitolo_cod;

return next;

       anno_competenza='';
       importo=0;
       descrizione='';
       posizione_nel_report=0;
       codice_importo='';
       tipo_capitolo_cod='';
           

end loop;
       
raise notice 'fine OK';
exception
	when no_data_found THEN
		raise notice 'nessun capitolo trovato restituisce rec solo per struttura' ;
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

insert into siac_d_bil_elem_categoria (
  elem_cat_code,  elem_cat_desc ,  
  validita_inizio ,  validita_fine,
  ente_proprietario_id ,  data_creazione,  data_modifica,
  data_cancellazione,  login_operazione)
select 'DDANC', 'Disavanzo derivante da debito autorizzato e non contratto',
	now(), NULL,
    ente.ente_proprietario_id, now(), now(),
    NULL, 'SIAC-7012'
from siac_t_ente_proprietario ente   
where ente.data_cancellazione IS NULL
	and not exists (select 1
    	from  siac_d_bil_elem_categoria categ
        where categ.ente_proprietario_id=ente.ente_proprietario_id
        	and categ.elem_cat_code= 'DDANC' 
            and categ.data_cancellazione IS NULL);


	--REPORT BILR006
INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                                                   
select  'fpv_incr_att_fin_inscr_ent',
        'Fondo pluriennale vincolato per incremento di attivita'' finanziarie iscritto in entrata',
        0,
        'N',
        21,
        a.bil_id,
        b2.periodo_id,
        now(),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'SIAC-7012'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and b2.anno in('2019','2020','2021')
and c2.periodo_tipo_code='SY'
and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='fpv_incr_att_fin_inscr_ent')
and exists (select 1
	from siac_t_report w
    where w.ente_proprietario_id=a.ente_proprietario_id
    	and w.data_cancellazione IS NULL
        and w.rep_codice = 'BILR006')	  ;	
      


--LEGAME TRA REPORT E IMPORTI.
INSERT INTO SIAC_R_REPORT_IMPORTI (rep_id,
                                   repimp_id,
                                   posizione_stampa,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                   
select 
(select d.rep_id
from   siac_t_report d
where  d.rep_codice = 'BILR006'
and    d.ente_proprietario_id = a.ente_proprietario_id) rep_id,
 a.repimp_id,
1 posizione_stampa,
now() validita_inizio,
null validita_fine,
a.ente_proprietario_id ente_proprietario_id,
now() data_creazione,
now() data_modifica,
null data_cancellazione,
'SIAC-7012' login_operazione
from   siac_t_report_importi a
where  a.repimp_codice in ('fpv_incr_att_fin_inscr_ent')
and not exists (select 1 
      from SIAC_R_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
      and z.repimp_id=a.repimp_id);	  
	  
INSERT INTO BKO_T_REPORT_IMPORTI
(rep_codice,
  rep_desc,
  repimp_codice,
  repimp_desc,
  repimp_importo,
  repimp_modificabile,
  repimp_progr_riga)
select 'BILR006',
 'Allegato 9 - Equilibri di Bilancio (BILR006)',
 'fpv_incr_att_fin_inscr_ent',
 'Fondo pluriennale vincolato per incremento di attivita'' finanziarie iscritto in entrata',
 0,
 'N',
 21
where  not exists (select 1
 from BKO_T_REPORT_IMPORTI a
 where a.rep_codice = 'BILR006'
 	and a.repimp_codice = 'fpv_incr_att_fin_inscr_ent');  

 
	  --REPORT BILR013
update siac_t_report_importi
set repimp_progr_riga=repimp_progr_riga+1,
	data_modifica=now(),
    login_operazione=login_operazione||' - SIAC-7012' 
where repimp_id in (select b.repimp_id
        from siac_t_report a,
        siac_t_report_importi b,
        siac_r_report_importi c,
        siac_t_bil d,
        siac_t_periodo e
    where a.rep_id=c.rep_id
    and b.repimp_id=c.repimp_id
    and b.bil_id=d.bil_id
    and d.periodo_id=e.periodo_id
    and a.ente_proprietario_id=2
    and a.rep_codice='BILR013'    
    and e.anno='2019'
    and b.repimp_progr_riga>=25)
and login_operazione not like '%SIAC-7012';      


INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                                                   
select  'VINCOL_DICUI_DISAV',
        'Parte Vincolata - F) di cui Disavanzo da debito autorizzato e non contratto',
        0,
        'N',
        25,
        a.bil_id,
        b2.periodo_id,
        now(),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'SIAC-7012'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and   b.anno = '2019'
and c.periodo_tipo_code='SY'
and b2.anno in('2019')
and c2.periodo_tipo_code='SY'
and not exists (select 1 
      from SIAC_T_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
	  and z.bil_id = a.bil_id
	  and z.periodo_id = b2.periodo_id
      and z.repimp_codice='VINCOL_DICUI_DISAV')
and exists (select 1
	from siac_t_report w
    where w.ente_proprietario_id=a.ente_proprietario_id
    	and w.data_cancellazione IS NULL
        and w.rep_codice = 'BILR013')	  ;
      

--LEGAME TRA REPORT E IMPORTI.
INSERT INTO SIAC_R_REPORT_IMPORTI (rep_id,
                                   repimp_id,
                                   posizione_stampa,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                   
select 
(select d.rep_id
from   siac_t_report d
where  d.rep_codice = 'BILR013'
and    d.ente_proprietario_id = a.ente_proprietario_id) rep_id,
 a.repimp_id,
1 posizione_stampa,
now() validita_inizio,
null validita_fine,
a.ente_proprietario_id ente_proprietario_id,
now() data_creazione,
now() data_modifica,
null data_cancellazione,
'SIAC-7012' login_operazione
from   siac_t_report_importi a
where  a.repimp_codice in ('VINCOL_DICUI_DISAV')
and not exists (select 1 
      from SIAC_R_REPORT_IMPORTI z 
      where z.ente_proprietario_id=a.ente_proprietario_id 
      and z.repimp_id=a.repimp_id);	 	  
	  

update bko_t_report_importi
set repimp_progr_riga=repimp_progr_riga+1
where repimp_progr_riga>=25
	and rep_codice='BILR013';
      

INSERT INTO BKO_T_REPORT_IMPORTI
(rep_codice,
  rep_desc,
  repimp_codice,
  repimp_desc,
  repimp_importo,
  repimp_modificabile,
  repimp_progr_riga)
select 'BILR013',
 'Allegato A - Tabella dimostrativa del risultato di amministrazione presunto (BILR013)',
 'VINCOL_DICUI_DISAV',
 'Parte Vincolata - F) di cui Disavanzo da debito autorizzato e non contratto',
 0,
 'N',
 25
where  not exists (select 1
 from BKO_T_REPORT_IMPORTI a
 where a.rep_codice = 'BILR013'
 	and a.repimp_codice = 'VINCOL_DICUI_DISAV');	  
	
--Modifica della descrizione della variabile di_cui_ant_liq
update siac_t_report_importi
set repimp_desc='Avanzo di amministrazione - di cui Utilizzo Fondo anticipazioni di liquidità',
	data_modifica = now(),
    login_operazione= login_operazione|| ' - SIAC-7012'
where repimp_codice='di_cui_ant_liq'
and repimp_desc <> 'Avanzo di amministrazione - di cui Utilizzo Fondo anticipazioni di liquidità'
and bil_id in (select bil_id
	from siac_t_bil a, siac_t_periodo b
    where a.periodo_id=b.periodo_id
    	and b.anno='2019'
    	and a.data_cancellazione IS NULL
        and b.data_cancellazione IS NULL)
and repimp_id in (select c.repimp_id
	from siac_r_report_importi c,
    	siac_t_report d
    where c.rep_id=d.rep_id
    	and d.rep_codice in ('BILR001', 'BILR005', 'BILR007')
        and c.data_cancellazione IS NULL
        and c.data_cancellazione IS NULL);

update siac_t_report_importi
set repimp_desc='Rimborso prestiti - di cui Utilizzo Fondo anticipazioni di liquidità',
	data_modifica = now(),
    login_operazione= login_operazione|| ' - SIAC-7012'
where repimp_codice='di_cui_ant_liq'
and repimp_desc <> 'Rimborso prestiti - di cui Utilizzo Fondo anticipazioni di liquidità'
and bil_id in (select bil_id
	from siac_t_bil a, siac_t_periodo b
    where a.periodo_id=b.periodo_id
    	and b.anno='2019'
    	and a.data_cancellazione IS NULL
        and b.data_cancellazione IS NULL)
and repimp_id in (select c.repimp_id
	from siac_r_report_importi c,
    	siac_t_report d
    where c.rep_id=d.rep_id
    	and d.rep_codice in ('BILR006')
        and c.data_cancellazione IS NULL
        and c.data_cancellazione IS NULL);
        
update siac_t_report_importi
set repimp_desc='F) Spese Titolo 4.00 - di cui Utilizzo Fondo anticipazioni di liquidità',
	data_modifica = now(),
    login_operazione= login_operazione|| ' - SIAC-7012'
where repimp_codice='di_cui_ant_liq'
and repimp_desc <> 'F) Spese Titolo 4.00 - di cui Utilizzo Fondo anticipazioni di liquidità'
and bil_id in (select bil_id
	from siac_t_bil a, siac_t_periodo b
    where a.periodo_id=b.periodo_id
    	and b.anno='2019'
    	and a.data_cancellazione IS NULL
        and b.data_cancellazione IS NULL)
and repimp_id in (select c.repimp_id
	from siac_r_report_importi c,
    	siac_t_report d
    where c.rep_id=d.rep_id
    	and d.rep_codice in ('BILR008')
        and c.data_cancellazione IS NULL
        and c.data_cancellazione IS NULL);
		
update BKO_T_REPORT_IMPORTI
set repimp_desc='Avanzo di amministrazione - di cui Utilizzo Fondo anticipazioni di liquidità'
where repimp_codice ='di_cui_ant_liq'
and rep_codice in ('BILR001', 'BILR005', 'BILR007');

update BKO_T_REPORT_IMPORTI
set repimp_desc='Rimborso prestiti - di cui Utilizzo Fondo anticipazioni di liquidità'
where repimp_codice ='di_cui_ant_liq'
and rep_codice in ('BILR006');

update BKO_T_REPORT_IMPORTI
set repimp_desc='F) Spese Titolo 4.00 - di cui Utilizzo Fondo anticipazioni di liquidità'
where repimp_codice ='di_cui_ant_liq'
and rep_codice in ('BILR008');
		
update siac_t_report_importi
set repimp_desc='Ripiano disavanzo pregresso derivante da debito autorizzato e non contratto (presunto)',
	data_modifica = now(),
    login_operazione= login_operazione|| ' - SIAC-7012'
where repimp_codice='disava_pregr'
and repimp_desc <> 'Ripiano disavanzo pregresso derivante da debito autorizzato e non contratto (presunto)'
and bil_id in (select bil_id
	from siac_t_bil a, siac_t_periodo b
    where a.periodo_id=b.periodo_id
    	and b.anno='2019'
    	and a.data_cancellazione IS NULL
        and b.data_cancellazione IS NULL)
and repimp_id in (select c.repimp_id
	from siac_r_report_importi c,
    	siac_t_report d
    where c.rep_id=d.rep_id
    	and d.rep_codice in ('BILR006')
        and c.data_cancellazione IS NULL
        and c.data_cancellazione IS NULL);
        
update BKO_T_REPORT_IMPORTI
set repimp_desc='Ripiano disavanzo pregresso derivante da debito autorizzato e non contratto (presunto)'
where repimp_codice ='disava_pregr'
and rep_codice in ('BILR006');  

update siac_t_report_importi
set repimp_desc='Parte Accantonata - Fondo anticipazioni liquidità',
	data_modifica = now(),
    login_operazione= login_operazione|| ' - SIAC-7012'
where repimp_codice='ACCANT_FONDO_ANTICIP'
and repimp_desc <> 'Parte Accantonata - Fondo anticipazioni liquidità'
and bil_id in (select bil_id
	from siac_t_bil a, siac_t_periodo b
    where a.periodo_id=b.periodo_id
    	and b.anno='2019'
    	and a.data_cancellazione IS NULL
        and b.data_cancellazione IS NULL)
and repimp_id in (select c.repimp_id
	from siac_r_report_importi c,
    	siac_t_report d
    where c.rep_id=d.rep_id
    	and d.rep_codice in ('BILR013')
        and c.data_cancellazione IS NULL
        and c.data_cancellazione IS NULL);


update BKO_T_REPORT_IMPORTI
set repimp_desc='Parte Accantonata - Fondo anticipazioni liquidità'
where repimp_codice ='ACCANT_FONDO_ANTICIP'
and rep_codice in ('BILR013');   
		
--XBRL

insert into siac_t_xbrl_mapping_fatti (
  xbrl_mapfat_rep_codice,  xbrl_mapfat_variabile,  xbrl_mapfat_fatto ,
  xbrl_mapfat_tupla_nome,  xbrl_mapfat_tupla_group_key ,  xbrl_mapfat_periodo_code,
  xbrl_mapfat_unit_code ,  xbrl_mapfat_decimali,  validita_inizio ,
  validita_fine ,  ente_proprietario_id ,  data_creazione ,
  data_modifica,  data_cancellazione,  login_operazione,
  xbrl_mapfat_periodo_tipo,  xbrl_mapfat_forza_visibilita)
select  'BILR002', 'disav_debito_non_contr_anno_prec',
	'SPE_DisavanzoDerivanteDebitoAutorizzatoNonContratto' , NULL, NULL,
    'd_anno/anno_bilancio*-1/', 'eur', 2,  now(),
    NULL, ente.ente_proprietario_id, now(), now(), NULL, 'SIAC-7012',
    'duration', false
from siac_t_ente_proprietario ente
where ente.data_cancellazione IS NULL
	and not exists (select 1
    	from siac_t_xbrl_mapping_fatti a
        where a.ente_proprietario_id=ente.ente_proprietario_id
        	and a.xbrl_mapfat_rep_codice='BILR002'
            and a.xbrl_mapfat_variabile='disav_debito_non_contr_anno_prec');
    
insert into siac_t_xbrl_mapping_fatti (
  xbrl_mapfat_rep_codice,  xbrl_mapfat_variabile,  xbrl_mapfat_fatto ,
  xbrl_mapfat_tupla_nome,  xbrl_mapfat_tupla_group_key ,  xbrl_mapfat_periodo_code,
  xbrl_mapfat_unit_code ,  xbrl_mapfat_decimali,  validita_inizio ,
  validita_fine ,  ente_proprietario_id ,  data_creazione ,
  data_modifica,  data_cancellazione,  login_operazione,
  xbrl_mapfat_periodo_tipo,  xbrl_mapfat_forza_visibilita)
select  'BILR002', 'disav_debito_non_contr_anno',
	'SPE_DisavanzoDerivanteDebitoAutorizzatoNonContratto' , NULL, NULL,
    'd_anno/anno_bilancio*0/', 'eur', 2,  now(),
    NULL, ente.ente_proprietario_id, now(), now(), NULL, 'SIAC-7012',
    'duration', false
from siac_t_ente_proprietario ente
where ente.data_cancellazione IS NULL
	and not exists (select 1
    	from siac_t_xbrl_mapping_fatti a
        where a.ente_proprietario_id=ente.ente_proprietario_id
        	and a.xbrl_mapfat_rep_codice='BILR002'
            and a.xbrl_mapfat_variabile='disav_debito_non_contr_anno') ;
    
            
insert into siac_t_xbrl_mapping_fatti (
  xbrl_mapfat_rep_codice,  xbrl_mapfat_variabile,  xbrl_mapfat_fatto ,
  xbrl_mapfat_tupla_nome,  xbrl_mapfat_tupla_group_key ,  xbrl_mapfat_periodo_code,
  xbrl_mapfat_unit_code ,  xbrl_mapfat_decimali,  validita_inizio ,
  validita_fine ,  ente_proprietario_id ,  data_creazione ,
  data_modifica,  data_cancellazione,  login_operazione,
  xbrl_mapfat_periodo_tipo,  xbrl_mapfat_forza_visibilita)
select  'BILR002', 'disav_debito_non_contr_anno1',
	'SPE_DisavanzoDerivanteDebitoAutorizzatoNonContratto' , NULL, NULL,
    'd_anno/anno_bilancio*1/', 'eur', 2,  now(),
    NULL, ente.ente_proprietario_id, now(), now(), NULL, 'SIAC-7012',
    'duration', false
from siac_t_ente_proprietario ente
where ente.data_cancellazione IS NULL
	and not exists (select 1
    	from siac_t_xbrl_mapping_fatti a
        where a.ente_proprietario_id=ente.ente_proprietario_id
        	and a.xbrl_mapfat_rep_codice='BILR002'
            and a.xbrl_mapfat_variabile='disav_debito_non_contr_anno1') ;            
            
insert into siac_t_xbrl_mapping_fatti (
  xbrl_mapfat_rep_codice,  xbrl_mapfat_variabile,  xbrl_mapfat_fatto ,
  xbrl_mapfat_tupla_nome,  xbrl_mapfat_tupla_group_key ,  xbrl_mapfat_periodo_code,
  xbrl_mapfat_unit_code ,  xbrl_mapfat_decimali,  validita_inizio ,
  validita_fine ,  ente_proprietario_id ,  data_creazione ,
  data_modifica,  data_cancellazione,  login_operazione,
  xbrl_mapfat_periodo_tipo,  xbrl_mapfat_forza_visibilita)
select  'BILR002', 'disav_debito_non_contr_anno2',
	'SPE_DisavanzoDerivanteDebitoAutorizzatoNonContratto' , NULL, NULL,
    'd_anno/anno_bilancio*2/', 'eur', 2,  now(),
    NULL, ente.ente_proprietario_id, now(), now(), NULL, 'SIAC-7012',
    'duration', false
from siac_t_ente_proprietario ente
where ente.data_cancellazione IS NULL
	and not exists (select 1
    	from siac_t_xbrl_mapping_fatti a
        where a.ente_proprietario_id=ente.ente_proprietario_id
        	and a.xbrl_mapfat_rep_codice='BILR002'
            and a.xbrl_mapfat_variabile='disav_debito_non_contr_anno2') ;
			
    
insert into siac_t_xbrl_mapping_fatti (
  xbrl_mapfat_rep_codice,  xbrl_mapfat_variabile,  xbrl_mapfat_fatto ,
  xbrl_mapfat_tupla_nome,  xbrl_mapfat_tupla_group_key ,  xbrl_mapfat_periodo_code,
  xbrl_mapfat_unit_code ,  xbrl_mapfat_decimali,  validita_inizio ,
  validita_fine ,  ente_proprietario_id ,  data_creazione ,
  data_modifica,  data_cancellazione,  login_operazione,
  xbrl_mapfat_periodo_tipo,  xbrl_mapfat_forza_visibilita)
select  'BILR007', 'disav_debito_non_contr_anno',
	'QGEN_DisavanzoDerivanteDebitoAutorizzatoNonContratto' , NULL, NULL,
    'd_anno/anno_bilancio*0/', 'eur', 2,  now(),
    NULL, ente.ente_proprietario_id, now(), now(), NULL, 'SIAC-7012',
    'duration', false
from siac_t_ente_proprietario ente
where ente.data_cancellazione IS NULL
	and not exists (select 1
    	from siac_t_xbrl_mapping_fatti a
        where a.ente_proprietario_id=ente.ente_proprietario_id
        	and a.xbrl_mapfat_rep_codice='BILR007'
            and a.xbrl_mapfat_variabile='disav_debito_non_contr_anno') ;        
            
insert into siac_t_xbrl_mapping_fatti (
  xbrl_mapfat_rep_codice,  xbrl_mapfat_variabile,  xbrl_mapfat_fatto ,
  xbrl_mapfat_tupla_nome,  xbrl_mapfat_tupla_group_key ,  xbrl_mapfat_periodo_code,
  xbrl_mapfat_unit_code ,  xbrl_mapfat_decimali,  validita_inizio ,
  validita_fine ,  ente_proprietario_id ,  data_creazione ,
  data_modifica,  data_cancellazione,  login_operazione,
  xbrl_mapfat_periodo_tipo,  xbrl_mapfat_forza_visibilita)
select  'BILR007', 'disav_debito_non_contr_anno1',
	'QGEN_DisavanzoDerivanteDebitoAutorizzatoNonContratto' , NULL, NULL,
    'd_anno/anno_bilancio*1/', 'eur', 2,  now(),
    NULL, ente.ente_proprietario_id, now(), now(), NULL, 'SIAC-7012',
    'duration', false
from siac_t_ente_proprietario ente
where ente.data_cancellazione IS NULL
	and not exists (select 1
    	from siac_t_xbrl_mapping_fatti a
        where a.ente_proprietario_id=ente.ente_proprietario_id
        	and a.xbrl_mapfat_rep_codice='BILR007'
            and a.xbrl_mapfat_variabile='disav_debito_non_contr_anno1') ;    
            
insert into siac_t_xbrl_mapping_fatti (
  xbrl_mapfat_rep_codice,  xbrl_mapfat_variabile,  xbrl_mapfat_fatto ,
  xbrl_mapfat_tupla_nome,  xbrl_mapfat_tupla_group_key ,  xbrl_mapfat_periodo_code,
  xbrl_mapfat_unit_code ,  xbrl_mapfat_decimali,  validita_inizio ,
  validita_fine ,  ente_proprietario_id ,  data_creazione ,
  data_modifica,  data_cancellazione,  login_operazione,
  xbrl_mapfat_periodo_tipo,  xbrl_mapfat_forza_visibilita)
select  'BILR007', 'disav_debito_non_contr_anno2',
	'QGEN_DisavanzoDerivanteDebitoAutorizzatoNonContratto' , NULL, NULL,
    'd_anno/anno_bilancio*2/', 'eur', 2,  now(),
    NULL, ente.ente_proprietario_id, now(), now(), NULL, 'SIAC-7012',
    'duration', false
from siac_t_ente_proprietario ente
where ente.data_cancellazione IS NULL
	and not exists (select 1
    	from siac_t_xbrl_mapping_fatti a
        where a.ente_proprietario_id=ente.ente_proprietario_id
        	and a.xbrl_mapfat_rep_codice='BILR007'
            and a.xbrl_mapfat_variabile='disav_debito_non_contr_anno2') ; 			
	



insert into siac_t_xbrl_mapping_fatti (
  xbrl_mapfat_rep_codice,  xbrl_mapfat_variabile,  xbrl_mapfat_fatto ,
  xbrl_mapfat_tupla_nome,  xbrl_mapfat_tupla_group_key ,  xbrl_mapfat_periodo_code,
  xbrl_mapfat_unit_code ,  xbrl_mapfat_decimali,  validita_inizio ,
  validita_fine ,  ente_proprietario_id ,  data_creazione ,
  data_modifica,  data_cancellazione,  login_operazione,
  xbrl_mapfat_periodo_tipo,  xbrl_mapfat_forza_visibilita)
select  'BILR013', 'f_dicui_disav',
	'RISAMM_DisavanzoDerivanteDebitoAutorizzatoNonContratto' , NULL, NULL,
    'd_anno/anno_bilancio*-0/', 'eur', 2,  now(),
    NULL, ente.ente_proprietario_id, now(), now(), NULL, 'SIAC-7012',
    'duration', false
from siac_t_ente_proprietario ente
where ente.data_cancellazione IS NULL
	and not exists (select 1
    	from siac_t_xbrl_mapping_fatti a
        where a.ente_proprietario_id=ente.ente_proprietario_id
        	and a.xbrl_mapfat_rep_codice='BILR013'
            and a.xbrl_mapfat_variabile='f_dicui_disav') ;  




insert into siac_t_xbrl_mapping_fatti (
  xbrl_mapfat_rep_codice,  xbrl_mapfat_variabile,  xbrl_mapfat_fatto ,
  xbrl_mapfat_tupla_nome,  xbrl_mapfat_tupla_group_key ,  xbrl_mapfat_periodo_code,
  xbrl_mapfat_unit_code ,  xbrl_mapfat_decimali,  validita_inizio ,
  validita_fine ,  ente_proprietario_id ,  data_creazione ,
  data_modifica,  data_cancellazione,  login_operazione,
  xbrl_mapfat_periodo_tipo,  xbrl_mapfat_forza_visibilita)
select  'BILR006', 'fpv_incr_att_finanz_iscritto_entrata',
	'EQREG-VAR_FPVAttivitaFinanziarieIscrittoEntrata' , NULL, NULL,
    'd_anno/anno_bilancio*0/', 'eur', 2,  now(),
    NULL, ente.ente_proprietario_id, now(), now(), NULL, 'SIAC-7012',
    'duration', false
from siac_t_ente_proprietario ente
where ente.data_cancellazione IS NULL
	and not exists (select 1
    	from siac_t_xbrl_mapping_fatti a
        where a.ente_proprietario_id=ente.ente_proprietario_id
        	and a.xbrl_mapfat_rep_codice='BILR006'
            and a.xbrl_mapfat_variabile='fpv_incr_att_finanz_iscritto_entrata') ;          
            

insert into siac_t_xbrl_mapping_fatti (
  xbrl_mapfat_rep_codice,  xbrl_mapfat_variabile,  xbrl_mapfat_fatto ,
  xbrl_mapfat_tupla_nome,  xbrl_mapfat_tupla_group_key ,  xbrl_mapfat_periodo_code,
  xbrl_mapfat_unit_code ,  xbrl_mapfat_decimali,  validita_inizio ,
  validita_fine ,  ente_proprietario_id ,  data_creazione ,
  data_modifica,  data_cancellazione,  login_operazione,
  xbrl_mapfat_periodo_tipo,  xbrl_mapfat_forza_visibilita)
select  'BILR006', 'fpv_incr_att_finanz_iscritto_entrata1',
	'EQREG-VAR_FPVAttivitaFinanziarieIscrittoEntrata' , NULL, NULL,
    'd_anno/anno_bilancio*1/', 'eur', 2,  now(),
    NULL, ente.ente_proprietario_id, now(), now(), NULL, 'SIAC-7012',
    'duration', false
from siac_t_ente_proprietario ente
where ente.data_cancellazione IS NULL
	and not exists (select 1
    	from siac_t_xbrl_mapping_fatti a
        where a.ente_proprietario_id=ente.ente_proprietario_id
        	and a.xbrl_mapfat_rep_codice='BILR006'
            and a.xbrl_mapfat_variabile='fpv_incr_att_finanz_iscritto_entrata1') ;          
            

insert into siac_t_xbrl_mapping_fatti (
  xbrl_mapfat_rep_codice,  xbrl_mapfat_variabile,  xbrl_mapfat_fatto ,
  xbrl_mapfat_tupla_nome,  xbrl_mapfat_tupla_group_key ,  xbrl_mapfat_periodo_code,
  xbrl_mapfat_unit_code ,  xbrl_mapfat_decimali,  validita_inizio ,
  validita_fine ,  ente_proprietario_id ,  data_creazione ,
  data_modifica,  data_cancellazione,  login_operazione,
  xbrl_mapfat_periodo_tipo,  xbrl_mapfat_forza_visibilita)
select  'BILR006', 'fpv_incr_att_finanz_iscritto_entrata2',
	'EQREG-VAR_FPVAttivitaFinanziarieIscrittoEntrata' , NULL, NULL,
    'd_anno/anno_bilancio*2/', 'eur', 2,  now(),
    NULL, ente.ente_proprietario_id, now(), now(), NULL, 'SIAC-7012',
    'duration', false
from siac_t_ente_proprietario ente
where ente.data_cancellazione IS NULL
	and not exists (select 1
    	from siac_t_xbrl_mapping_fatti a
        where a.ente_proprietario_id=ente.ente_proprietario_id
        	and a.xbrl_mapfat_rep_codice='BILR006'
            and a.xbrl_mapfat_variabile='fpv_incr_att_finanz_iscritto_entrata2') ;          
                                               		

--SIAC-7012 - Maurizio - FINE

--SIAC-7074, SIAC-7075, SIAC-7076, SIAC-7079 e SIAC-7096 - Maurizio - INIZIO

DROP FUNCTION if exists siac."BILR224_quadro_economico"(p_ente_prop_id integer, p_anno varchar, p_id_cronop integer);

CREATE OR REPLACE FUNCTION siac."BILR224_quadro_economico" (
  p_ente_prop_id integer,
  p_anno varchar,
  p_id_cronop integer
)
RETURNS TABLE (
  parte_code varchar,
  parte_desc varchar,
  quadro_economico_id integer,
  quadro_economico_code varchar,
  quadro_economico_desc varchar,
  quadro_economico_id_padre integer,
  livello integer,
  quadro_economico_stato_code varchar,
  quadro_economico_stato_desc varchar,
  voce_quadro_economico varchar,
  importo_quadro_economico numeric,
  cronop_data_approvazione_fattibilita timestamp,
  cronop_data_approvazione_programma_def timestamp,
  cronop_data_approvazione_programma_esec timestamp,
  cronop_data_avvio_procedura timestamp,
  cronop_data_aggiudicazione_lavori timestamp,
  cronop_data_inizio_lavori timestamp,
  cronop_data_fine_lavori timestamp,
  cronop_giorni_durata integer,
  cronop_data_collaudo timestamp,
  ordinamento integer
) AS
$body$
DECLARE

RTN_MESSAGGIO text;

BEGIN

/*
	29/05/2019.
	Procedura per l'estrazione dei dati del quadro economico.
    
*/    

         --16/10/2019 SIAC-7075.
         -- estratto anche il campo cronop_elem_det_id per l'ordinamento nel report.
return query
select  d_qua_econ_parte.parte_code  parte_code,
		d_qua_econ_parte.parte_desc parte_desc,
        t_qua_econ.quadro_economico_id quadro_economico_id,
        t_qua_econ.quadro_economico_code quadro_economico_code,
        t_qua_econ.quadro_economico_desc quadro_economico_desc,        
        t_qua_econ.quadro_economico_id_padre quadro_economico_id_padre,
        t_qua_econ.livello livello,
        d_qua_econ_stato.quadro_economico_stato_code quadro_economico_stato_code,
        d_qua_econ_stato.quadro_economico_stato_desc quadro_economico_stato_desc,
        t_cronop_elem.cronop_elem_desc voce_quadro_economico,
        t_cronop_elem_det.quadro_economico_det_importo::numeric importo_quadro_economico,
        t_cronop.cronop_data_approvazione_fattibilita,
  		t_cronop.cronop_data_approvazione_programma_def,
        t_cronop.cronop_data_approvazione_programma_esec,
        t_cronop.cronop_data_avvio_procedura,
        t_cronop.cronop_data_aggiudicazione_lavori,
        t_cronop.cronop_data_inizio_lavori,
        t_cronop.cronop_data_fine_lavori,
        t_cronop.cronop_giorni_durata,
        t_cronop.cronop_data_collaudo,
        t_cronop_elem_det.cronop_elem_det_id
    from siac_t_programma t_programma,
    	siac_t_cronop t_cronop,
    	siac_t_cronop_elem t_cronop_elem,
    	siac_t_cronop_elem_det t_cronop_elem_det,
        siac_t_bil t_bil,
      	siac_t_periodo t_periodo ,
    	siac_t_quadro_economico t_qua_econ,
        siac_d_quadro_economico_parte d_qua_econ_parte,
        siac_r_quadro_economico_stato r_qua_econ_stato,
        siac_d_quadro_economico_stato d_qua_econ_stato
    where t_programma.programma_id = t_cronop.programma_id 
		and t_cronop_elem.cronop_id = t_cronop.cronop_id
    	and t_cronop_elem_det.cronop_elem_id = t_cronop_elem.cronop_elem_id
    	and t_bil.bil_id = t_cronop.bil_id
    	and t_bil.periodo_id = t_periodo.periodo_id
        	--collegamento con il padre del quadro economico.
        and (t_cronop_elem_det.quadro_economico_id_padre = t_qua_econ.quadro_economico_id AND
              t_cronop_elem_det.quadro_economico_id_figlio IS NULL)
    	and t_qua_econ.parte_id=d_qua_econ_parte.parte_id
    	and t_qua_econ.quadro_economico_id=r_qua_econ_stato.quadro_economico_id
        and r_qua_econ_stato.quadro_economico_stato_id=d_qua_econ_stato.quadro_economico_stato_id        
        and t_programma.ente_proprietario_id=p_ente_prop_id
        and d_qua_econ_stato.quadro_economico_stato_code <> 'A'
        and t_periodo.anno = p_anno
        and t_cronop.cronop_id = p_id_cronop
        and t_qua_econ.data_cancellazione IS NULL
		and d_qua_econ_parte.data_cancellazione IS NULL
        and r_qua_econ_stato.data_cancellazione IS NULL
        and d_qua_econ_stato.data_cancellazione IS NULL        
    	and t_programma.data_cancellazione IS NULL
        and t_cronop.data_cancellazione IS NULL
        and t_cronop_elem.data_cancellazione IS NULL
        and t_cronop_elem_det.data_cancellazione IS NULL
        and t_bil.data_cancellazione IS NULL
        and t_periodo.data_cancellazione IS NULL 
UNION -- Dati relativi ai quadri economici di livello 1, collegati al cronoprogramma.
	select d_qua_econ_parte.parte_code  parte_code,
    	 d_qua_econ_parte.parte_desc parte_desc,
        t_qua_econ.quadro_economico_id quadro_economico_id,
        t_qua_econ.quadro_economico_code quadro_economico_code,
        t_qua_econ.quadro_economico_desc quadro_economico_desc,        
        t_qua_econ.quadro_economico_id_padre quadro_economico_id_padre,
        t_qua_econ.livello livello,
        d_qua_econ_stato.quadro_economico_stato_code quadro_economico_stato_code,
        d_qua_econ_stato.quadro_economico_stato_desc quadro_economico_stato_desc,
        t_cronop_elem.cronop_elem_desc voce_quadro_economico,
        t_cronop_elem_det.quadro_economico_det_importo::numeric importo_quadro_economico,
        t_cronop.cronop_data_approvazione_fattibilita,
  		t_cronop.cronop_data_approvazione_programma_def,
        t_cronop.cronop_data_approvazione_programma_esec,
        t_cronop.cronop_data_avvio_procedura,
        t_cronop.cronop_data_aggiudicazione_lavori,
        t_cronop.cronop_data_inizio_lavori,
        t_cronop.cronop_data_fine_lavori,
        t_cronop.cronop_giorni_durata,
        t_cronop.cronop_data_collaudo,
        t_cronop_elem_det.cronop_elem_det_id
    from siac_t_programma t_programma,
    	siac_t_cronop t_cronop,
    	siac_t_cronop_elem t_cronop_elem,
    	siac_t_cronop_elem_det t_cronop_elem_det,
        siac_t_bil t_bil,
      	siac_t_periodo t_periodo ,
    	siac_t_quadro_economico t_qua_econ,
        siac_d_quadro_economico_parte d_qua_econ_parte,
        siac_r_quadro_economico_stato r_qua_econ_stato,
        siac_d_quadro_economico_stato d_qua_econ_stato
    where t_programma.programma_id = t_cronop.programma_id 
		and t_cronop_elem.cronop_id = t_cronop.cronop_id
    	and t_cronop_elem_det.cronop_elem_id = t_cronop_elem.cronop_elem_id
    	and t_bil.bil_id = t_cronop.bil_id
    	and t_bil.periodo_id = t_periodo.periodo_id       
        	--collegamento con il figlio del quadro economico.
        and (t_cronop_elem_det.quadro_economico_id_figlio IS NOT NULL 
        	AND t_cronop_elem_det.quadro_economico_id_figlio = t_qua_econ.quadro_economico_id)
    	and t_qua_econ.parte_id=d_qua_econ_parte.parte_id
    	and t_qua_econ.quadro_economico_id=r_qua_econ_stato.quadro_economico_id
        and r_qua_econ_stato.quadro_economico_stato_id=d_qua_econ_stato.quadro_economico_stato_id        
        and t_programma.ente_proprietario_id=p_ente_prop_id
        and d_qua_econ_stato.quadro_economico_stato_code <> 'A'
        and t_periodo.anno = p_anno
        and t_cronop.cronop_id = p_id_cronop
        and t_qua_econ.data_cancellazione IS NULL
		and d_qua_econ_parte.data_cancellazione IS NULL
        and r_qua_econ_stato.data_cancellazione IS NULL
        and d_qua_econ_stato.data_cancellazione IS NULL        
    	and t_programma.data_cancellazione IS NULL
        and t_cronop.data_cancellazione IS NULL
        and t_cronop_elem.data_cancellazione IS NULL
        and t_cronop_elem_det.data_cancellazione IS NULL
        and t_bil.data_cancellazione IS NULL
        and t_periodo.data_cancellazione IS NULL                   
    UNION -- estraggo anche le PARTI A, B, C vuote per fare in modo che nel 
    	  -- report esistano sempre.
    	select 
          d_qua_econ_parte.parte_code  parte_code,
          d_qua_econ_parte.parte_desc parte_desc,
          0::integer quadro_economico_id,
          ''::varchar quadro_economico_code,
          ''::varchar quadro_economico_desc,
          0::integer quadro_economico_id_padre,
          0::integer livello,
          ''::varchar quadro_economico_stato_code,
          ''::varchar quadro_economico_stato_desc,
          ''::varchar voce_quadro_economico,
          0::numeric importo_quadro_economico,
          NULL cronop_data_approvazione_fattibilita,
          NULL cronop_data_approvazione_programma_def,
          NULL cronop_data_approvazione_programma_esec,
          NULL cronop_data_avvio_procedura,
          NULL cronop_data_aggiudicazione_lavori,
          NULL cronop_data_inizio_lavori,
          NULL cronop_data_fine_lavori,
          NULL cronop_giorni_durata,
          NULL cronop_data_collaudo,
          1
        from siac_d_quadro_economico_parte d_qua_econ_parte
        where d_qua_econ_parte.ente_proprietario_id=p_ente_prop_id
            and d_qua_econ_parte.data_cancellazione IS NULL;
        
exception
	when no_data_found THEN
		raise notice 'Nessun dato trovato per il quadro economico';
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

DROP FUNCTION if exists siac."BILR225_quadro_economico_movim_contab"(p_ente_prop_id integer, p_anno varchar, p_id_cronop integer);

CREATE OR REPLACE FUNCTION siac."BILR225_quadro_economico_movim_contab" (
  p_ente_prop_id integer,
  p_anno varchar,
  p_id_cronop integer
)
RETURNS TABLE (
  parte_code varchar,
  parte_desc varchar,
  quadro_economico_id integer,
  quadro_economico_code varchar,
  quadro_economico_desc varchar,
  quadro_economico_id_padre integer,
  livello integer,
  quadro_economico_stato_code varchar,
  quadro_economico_stato_desc varchar,
  voce_quadro_economico varchar,
  importo_quadro_economico numeric,
  cronop_data_approvazione_fattibilita timestamp,
  cronop_data_approvazione_programma_def timestamp,
  cronop_data_approvazione_programma_esec timestamp,
  cronop_data_avvio_procedura timestamp,
  cronop_data_aggiudicazione_lavori timestamp,
  cronop_data_inizio_lavori timestamp,
  cronop_data_fine_lavori timestamp,
  cronop_giorni_durata integer,
  cronop_data_collaudo timestamp,
  liquidato_anni_prec numeric,
  stanziato_anno numeric,
  impegnato_anno numeric,
  prenotato_anno numeric,
  liquidato_anno numeric,
  stanziato_anno1 numeric,
  impegnato_anno1 numeric,
  prenotato_anno1 numeric,
  stanziato_anno2 numeric,
  impegnato_anno2 numeric,
  prenotato_anno2 numeric,
  stanziato_anni_succ numeric,
  impegnato_anni_succ numeric,
  prenotato_anni_succ numeric,
  contabilizzato_anno numeric,
  ordinamento integer
) AS
$body$
DECLARE

RTN_MESSAGGIO text;
bilancio_id integer;

BEGIN


select a.bil_id 
	into bilancio_id 
from siac_t_bil a,siac_t_periodo b
where a.ente_proprietario_id=p_ente_prop_id 
	and b.periodo_id=a.periodo_id
	and b.anno=p_anno;
    
/*
	29/05/2019.
	Procedura per l'estrazione dei dati del quadro economico.
    Oltre a questi estrae anche:
   
	16/10/2019 SIAC-7079: cambiano le regole di estrazione.
    Prima erano:
- Liquidato Anno prec = liquidazioni legate agli impegni con anno = anno prec

Per anno corrente e successivi:
- Stanziato = impegni con tipologia I = Importo iniziale
- Impegnato = impegni con tipologia A = Importo attuale
- Prenotato = importo sub impegni legati agli impegni.
- Liquidato = liquidazioni legate agli impegni 

    Adesso sono:
- Liquidato Anno prec = liquidazioni legate agli impegni con anno = anno prec

Per anno corrente e successivi:
- Stanziato = valore Previsto del quadro economico per l'anno.
- Impegnato = impegni con tipologia A = Importo attuale e stato Definitivo.
- Prenotato = importo sub impegni legati agli impegni.
- Liquidato = liquidazioni legate agli impegni 

Introdotto il nuovo valore:
- Contabilizzato = importo delle quote dei documenti legati agli impegni che
  hanno il flag doc_contabilizza_genpcc = true.

L'anno bilancio e' sempre lo stesso.

*/

return query
	with quadro_economico as (
    select  d_qua_econ_parte.parte_code  parte_code,
            d_qua_econ_parte.parte_desc parte_desc,
            t_qua_econ.quadro_economico_id quadro_economico_id,
            t_qua_econ.quadro_economico_code quadro_economico_code,
            t_qua_econ.quadro_economico_desc quadro_economico_desc,        
            t_qua_econ.quadro_economico_id_padre quadro_economico_id_padre,
            t_qua_econ.livello livello,
            d_qua_econ_stato.quadro_economico_stato_code quadro_economico_stato_code,
            d_qua_econ_stato.quadro_economico_stato_desc quadro_economico_stato_desc,
            t_cronop_elem.cronop_elem_desc voce_quadro_economico,
            t_cronop_elem_det.quadro_economico_det_importo::numeric importo_quadro_economico,
            t_cronop.cronop_data_approvazione_fattibilita,
            t_cronop.cronop_data_approvazione_programma_def,
            t_cronop.cronop_data_approvazione_programma_esec,
            t_cronop.cronop_data_avvio_procedura,
            t_cronop.cronop_data_aggiudicazione_lavori,
            t_cronop.cronop_data_inizio_lavori,
            t_cronop.cronop_data_fine_lavori,
            t_cronop.cronop_giorni_durata,
            t_cronop.cronop_data_collaudo,
            impegni_collegati.movgest_ts_id,
            impegni_collegati.movgest_id,
            t_cronop_elem_det.cronop_elem_det_id,
            t_cronop_elem.cronop_elem_id
        from siac_t_programma t_programma,
            siac_t_cronop t_cronop,
            siac_t_cronop_elem t_cronop_elem
                LEFT JOIN (select r_movgest_ts_cronop_elem.movgest_ts_id,
                            r_movgest_ts_cronop_elem.cronop_elem_id,
                            t_movgest_ts.movgest_id 
                        from siac_r_movgest_ts_cronop_elem r_movgest_ts_cronop_elem,
                            siac_t_movgest_ts t_movgest_ts
                        where t_movgest_ts.movgest_ts_id = r_movgest_ts_cronop_elem.movgest_ts_id
                            and r_movgest_ts_cronop_elem.ente_proprietario_id = p_ente_prop_id
                            and r_movgest_ts_cronop_elem.validita_fine IS NULL
                            and r_movgest_ts_cronop_elem.data_cancellazione IS NULL
                            and t_movgest_ts.validita_fine IS NULL
                            and t_movgest_ts.data_cancellazione IS NULL) impegni_collegati
                        ON impegni_collegati.cronop_elem_id=t_cronop_elem.cronop_elem_id,
            siac_t_cronop_elem_det t_cronop_elem_det,
            siac_t_bil t_bil,
            siac_t_periodo t_periodo ,
            siac_t_quadro_economico t_qua_econ,
            siac_d_quadro_economico_parte d_qua_econ_parte,
            siac_r_quadro_economico_stato r_qua_econ_stato,
            siac_d_quadro_economico_stato d_qua_econ_stato
        where t_programma.programma_id = t_cronop.programma_id 
            and t_cronop_elem.cronop_id = t_cronop.cronop_id
            and t_cronop_elem_det.cronop_elem_id = t_cronop_elem.cronop_elem_id
            and t_bil.bil_id = t_cronop.bil_id
            and t_bil.periodo_id = t_periodo.periodo_id
                --collegamento con il padre del quadro economico.
            and (t_cronop_elem_det.quadro_economico_id_padre = t_qua_econ.quadro_economico_id AND
                  t_cronop_elem_det.quadro_economico_id_figlio IS NULL)
            and t_qua_econ.parte_id=d_qua_econ_parte.parte_id
            and t_qua_econ.quadro_economico_id=r_qua_econ_stato.quadro_economico_id
            and r_qua_econ_stato.quadro_economico_stato_id=d_qua_econ_stato.quadro_economico_stato_id        
            and t_programma.ente_proprietario_id=p_ente_prop_id
            and d_qua_econ_stato.quadro_economico_stato_code <> 'A'
            and t_periodo.anno = p_anno
            and t_cronop.cronop_id = p_id_cronop
            and t_qua_econ.data_cancellazione IS NULL
            and d_qua_econ_parte.data_cancellazione IS NULL
            and r_qua_econ_stato.data_cancellazione IS NULL
            and d_qua_econ_stato.data_cancellazione IS NULL        
            and t_programma.data_cancellazione IS NULL
            and t_cronop.data_cancellazione IS NULL
            and t_cronop_elem.data_cancellazione IS NULL
            and t_cronop_elem_det.data_cancellazione IS NULL
            and t_bil.data_cancellazione IS NULL
            and t_periodo.data_cancellazione IS NULL 
    UNION -- Dati relativi ai quadri economici di livello 1, collegati al cronoprogramma.
        select d_qua_econ_parte.parte_code  parte_code,
             d_qua_econ_parte.parte_desc parte_desc,
            t_qua_econ.quadro_economico_id quadro_economico_id,
            t_qua_econ.quadro_economico_code quadro_economico_code,
            t_qua_econ.quadro_economico_desc quadro_economico_desc,        
            t_qua_econ.quadro_economico_id_padre quadro_economico_id_padre,
            t_qua_econ.livello livello,
            d_qua_econ_stato.quadro_economico_stato_code quadro_economico_stato_code,
            d_qua_econ_stato.quadro_economico_stato_desc quadro_economico_stato_desc,
            t_cronop_elem.cronop_elem_desc voce_quadro_economico,
            t_cronop_elem_det.quadro_economico_det_importo::numeric importo_quadro_economico,
            t_cronop.cronop_data_approvazione_fattibilita,
            t_cronop.cronop_data_approvazione_programma_def,
            t_cronop.cronop_data_approvazione_programma_esec,
            t_cronop.cronop_data_avvio_procedura,
            t_cronop.cronop_data_aggiudicazione_lavori,
            t_cronop.cronop_data_inizio_lavori,
            t_cronop.cronop_data_fine_lavori,
            t_cronop.cronop_giorni_durata,
            t_cronop.cronop_data_collaudo,
            impegni_collegati.movgest_ts_id,
            impegni_collegati.movgest_id,
            t_cronop_elem_det.cronop_elem_det_id,
            t_cronop_elem.cronop_elem_id
        from siac_t_programma t_programma,
            siac_t_cronop t_cronop,
            siac_t_cronop_elem t_cronop_elem
                LEFT JOIN (select r_movgest_ts_cronop_elem.movgest_ts_id,
                            r_movgest_ts_cronop_elem.cronop_elem_id,
                            t_movgest_ts.movgest_id 
                        from siac_r_movgest_ts_cronop_elem r_movgest_ts_cronop_elem,
                            siac_t_movgest_ts t_movgest_ts
                        where t_movgest_ts.movgest_ts_id = r_movgest_ts_cronop_elem.movgest_ts_id
                            and r_movgest_ts_cronop_elem.ente_proprietario_id = p_ente_prop_id
                            and r_movgest_ts_cronop_elem.validita_fine IS NULL
                            and r_movgest_ts_cronop_elem.data_cancellazione IS NULL
                            and t_movgest_ts.validita_fine IS NULL
                            and t_movgest_ts.data_cancellazione IS NULL) impegni_collegati
                        ON impegni_collegati.cronop_elem_id=t_cronop_elem.cronop_elem_id,
            siac_t_cronop_elem_det t_cronop_elem_det,
            siac_t_bil t_bil,
            siac_t_periodo t_periodo ,
            siac_t_quadro_economico t_qua_econ,
            siac_d_quadro_economico_parte d_qua_econ_parte,
            siac_r_quadro_economico_stato r_qua_econ_stato,
            siac_d_quadro_economico_stato d_qua_econ_stato
        where t_programma.programma_id = t_cronop.programma_id 
            and t_cronop_elem.cronop_id = t_cronop.cronop_id
            and t_cronop_elem_det.cronop_elem_id = t_cronop_elem.cronop_elem_id
            and t_bil.bil_id = t_cronop.bil_id
            and t_bil.periodo_id = t_periodo.periodo_id       
                --collegamento con il figlio del quadro economico.
            and (t_cronop_elem_det.quadro_economico_id_figlio IS NOT NULL 
                AND t_cronop_elem_det.quadro_economico_id_figlio = t_qua_econ.quadro_economico_id)
            and t_qua_econ.parte_id=d_qua_econ_parte.parte_id
            and t_qua_econ.quadro_economico_id=r_qua_econ_stato.quadro_economico_id
            and r_qua_econ_stato.quadro_economico_stato_id=d_qua_econ_stato.quadro_economico_stato_id        
            and t_programma.ente_proprietario_id=p_ente_prop_id
            and d_qua_econ_stato.quadro_economico_stato_code <> 'A'
            and t_periodo.anno = p_anno
            and t_cronop.cronop_id = p_id_cronop
            and t_qua_econ.data_cancellazione IS NULL
            and d_qua_econ_parte.data_cancellazione IS NULL
            and r_qua_econ_stato.data_cancellazione IS NULL
            and d_qua_econ_stato.data_cancellazione IS NULL        
            and t_programma.data_cancellazione IS NULL
            and t_cronop.data_cancellazione IS NULL
            and t_cronop_elem.data_cancellazione IS NULL
            and t_cronop_elem_det.data_cancellazione IS NULL
            and t_bil.data_cancellazione IS NULL
            and t_periodo.data_cancellazione IS NULL),
	liquidazioni_anno_prec as(
    	select t_movgest_ts.movgest_ts_id,
        	sum(coalesce(t_liq.liq_importo,0)) liquidazioni 
        from siac_t_movgest t_movgest,
        	siac_t_movgest_ts t_movgest_ts,
            siac_r_liquidazione_movgest r_liq_movgest,
            siac_t_liquidazione t_liq,
            siac_t_movgest_ts_det t_movgest_ts_det,
			siac_r_movgest_bil_elem r_movgest_bil_elem,
            siac_d_movgest_tipo d_movgest_tipo,
            siac_r_movgest_ts_stato r_movgest_ts_stato,
            siac_d_movgest_stato d_movgest_stato,
			siac_d_movgest_ts_tipo d_movgest_ts_tipo,
            siac_d_movgest_ts_det_tipo d_movgest_ts_det_tipo
 		where t_movgest_ts.movgest_id=t_movgest.movgest_id
           	and t_movgest_ts_det.movgest_ts_id=t_movgest_ts.movgest_ts_id
           	and d_movgest_ts_tipo.movgest_ts_tipo_id=t_movgest_ts.movgest_ts_tipo_id
          	and r_movgest_bil_elem.movgest_id=t_movgest.movgest_id
          	and d_movgest_tipo.movgest_tipo_id=t_movgest.movgest_tipo_id
          	and d_movgest_ts_det_tipo.movgest_ts_det_tipo_id=t_movgest_ts_det.movgest_ts_det_tipo_id
          	and r_movgest_ts_stato.movgest_ts_id=t_movgest_ts.movgest_ts_id
          	and r_movgest_ts_stato.movgest_stato_id=d_movgest_stato.movgest_stato_id
            and r_liq_movgest.movgest_ts_id = t_movgest_ts.movgest_ts_id
            and t_liq.liq_id = r_liq_movgest.liq_id
            and t_movgest.ente_proprietario_id = p_ente_prop_id
            and t_movgest.bil_id=bilancio_id
            and t_movgest.movgest_anno = (p_anno::integer -1)
            and d_movgest_tipo.movgest_tipo_code='I'
          	and d_movgest_stato.movgest_stato_code in ('D','N')           	
          	and d_movgest_ts_tipo.movgest_ts_tipo_code='T'           	
          	and d_movgest_ts_det_tipo.movgest_ts_det_tipo_code='A'
            and r_movgest_ts_stato.validita_fine is NULL
            and r_movgest_ts_stato.data_cancellazione is null
          	and t_movgest.data_cancellazione is null
          	and t_movgest_ts.data_cancellazione is null
          	and t_movgest_ts_det.data_cancellazione is null
          	and r_movgest_bil_elem.data_cancellazione is null
          	and d_movgest_tipo.data_cancellazione is null          	
          	and d_movgest_stato.data_cancellazione is null
          	and d_movgest_ts_tipo.data_cancellazione is null
          	and d_movgest_ts_det_tipo.data_cancellazione is null
            and r_liq_movgest.validita_fine is NULL
            and r_liq_movgest.data_cancellazione is null
            and t_liq.data_cancellazione is null
          group by t_movgest_ts.movgest_ts_id),               
    impegni_anno as (
    	select t_movgest_ts.movgest_ts_id,
        	sum(coalesce(t_movgest_ts_det.movgest_ts_det_importo,0)) impegni 
        from siac_t_movgest t_movgest,
        	siac_t_movgest_ts t_movgest_ts,
            siac_t_movgest_ts_det t_movgest_ts_det,
			siac_r_movgest_bil_elem r_movgest_bil_elem,
            siac_d_movgest_tipo d_movgest_tipo,
            siac_r_movgest_ts_stato r_movgest_ts_stato,
            siac_d_movgest_stato d_movgest_stato,
			siac_d_movgest_ts_tipo d_movgest_ts_tipo,
            siac_d_movgest_ts_det_tipo d_movgest_ts_det_tipo
 		where t_movgest_ts.movgest_id=t_movgest.movgest_id
           	and t_movgest_ts_det.movgest_ts_id=t_movgest_ts.movgest_ts_id
           	and d_movgest_ts_tipo.movgest_ts_tipo_id=t_movgest_ts.movgest_ts_tipo_id
          	and r_movgest_bil_elem.movgest_id=t_movgest.movgest_id
          	and d_movgest_tipo.movgest_tipo_id=t_movgest.movgest_tipo_id
          	and d_movgest_ts_det_tipo.movgest_ts_det_tipo_id=t_movgest_ts_det.movgest_ts_det_tipo_id
          	and r_movgest_ts_stato.movgest_ts_id=t_movgest_ts.movgest_ts_id
          	and r_movgest_ts_stato.movgest_stato_id=d_movgest_stato.movgest_stato_id
            and t_movgest.ente_proprietario_id = p_ente_prop_id
            and t_movgest.bil_id=bilancio_id
            and t_movgest.movgest_anno = p_anno::integer
            and d_movgest_tipo.movgest_tipo_code='I'
            	--escludo solo gli impegni ANNULLATI.
                --15/10/2019 - SIAC-7079: "La colonna impegnato e' il valore 
                -- attuale dell'impegno in stato definitivo".              
            --and d_movgest_stato.movgest_stato_code <> 'A'   
            and d_movgest_stato.movgest_stato_code = 'D'         	
          	and d_movgest_ts_tipo.movgest_ts_tipo_code='T'   
            	-- l'importo IMPEGNATO ha la tipologia = A - ATTUALE         	
          	and d_movgest_ts_det_tipo.movgest_ts_det_tipo_code='A'
            and r_movgest_ts_stato.validita_fine is NULL
            and r_movgest_ts_stato.data_cancellazione is null
          	and t_movgest.data_cancellazione is null
          	and t_movgest_ts.data_cancellazione is null
          	and t_movgest_ts_det.data_cancellazione is null
          	and r_movgest_bil_elem.data_cancellazione is null
          	and d_movgest_tipo.data_cancellazione is null          	
          	and d_movgest_stato.data_cancellazione is null
          	and d_movgest_ts_tipo.data_cancellazione is null
          	and d_movgest_ts_det_tipo.data_cancellazione is null
          group by t_movgest_ts.movgest_ts_id),
          --15/10/2019 - SIAC-7079: Lo stanziato e' l'importo Attuale del
          -- quadro economico per l'anno.
      stanziato_anno as(
      		select a.cronop_elem_id, sum(a.cronop_elem_det_importo) stanziato
    		from siac_t_cronop_elem_det a,
            	siac_t_periodo b
            where a.periodo_id = b.periodo_id
            	and a.ente_proprietario_id= p_ente_prop_id
                and b.anno= p_anno
            	and a.data_cancellazione IS NULL
                and b.data_cancellazione IS NULL
            group by a.cronop_elem_id),
	/*stanziato_anno as(
    	select t_movgest_ts.movgest_ts_id,
        	sum(coalesce(t_movgest_ts_det.movgest_ts_det_importo,0)) stanziato 
        from siac_t_movgest t_movgest,
        	siac_t_movgest_ts t_movgest_ts,
            siac_t_movgest_ts_det t_movgest_ts_det,
			siac_r_movgest_bil_elem r_movgest_bil_elem,
            siac_d_movgest_tipo d_movgest_tipo,
            siac_r_movgest_ts_stato r_movgest_ts_stato,
            siac_d_movgest_stato d_movgest_stato,
			siac_d_movgest_ts_tipo d_movgest_ts_tipo,
            siac_d_movgest_ts_det_tipo d_movgest_ts_det_tipo
 		where t_movgest_ts.movgest_id=t_movgest.movgest_id
           	and t_movgest_ts_det.movgest_ts_id=t_movgest_ts.movgest_ts_id
           	and d_movgest_ts_tipo.movgest_ts_tipo_id=t_movgest_ts.movgest_ts_tipo_id
          	and r_movgest_bil_elem.movgest_id=t_movgest.movgest_id
          	and d_movgest_tipo.movgest_tipo_id=t_movgest.movgest_tipo_id
          	and d_movgest_ts_det_tipo.movgest_ts_det_tipo_id=t_movgest_ts_det.movgest_ts_det_tipo_id
          	and r_movgest_ts_stato.movgest_ts_id=t_movgest_ts.movgest_ts_id
          	and r_movgest_ts_stato.movgest_stato_id=d_movgest_stato.movgest_stato_id
            and t_movgest.ente_proprietario_id = p_ente_prop_id
            and t_movgest.bil_id=bilancio_id
            and t_movgest.movgest_anno = p_anno::integer
            and d_movgest_tipo.movgest_tipo_code='I'
          		--escludo solo gli impegni ANNULLATI.
            and d_movgest_stato.movgest_stato_code <> 'A'           	
          	and d_movgest_ts_tipo.movgest_ts_tipo_code='T'       
            	-- l'importo STANZIATO ha la tipologia = I - INIZIALE    	
          	and d_movgest_ts_det_tipo.movgest_ts_det_tipo_code='I'
            and r_movgest_ts_stato.validita_fine is NULL
            and r_movgest_ts_stato.data_cancellazione is null
          	and t_movgest.data_cancellazione is null
          	and t_movgest_ts.data_cancellazione is null
          	and t_movgest_ts_det.data_cancellazione is null
          	and r_movgest_bil_elem.data_cancellazione is null
          	and d_movgest_tipo.data_cancellazione is null          	
          	and d_movgest_stato.data_cancellazione is null
          	and d_movgest_ts_tipo.data_cancellazione is null
          	and d_movgest_ts_det_tipo.data_cancellazione is null
          group by t_movgest_ts.movgest_ts_id),  */ 
        prenotato_anno as(
          select t_movgest_ts.movgest_id,
              sum(coalesce(t_movgest_ts_det.movgest_ts_det_importo,0)) prenotato 
          from siac_t_movgest t_movgest,
              siac_t_movgest_ts t_movgest_ts,
              siac_t_movgest_ts_det t_movgest_ts_det,
              siac_r_movgest_bil_elem r_movgest_bil_elem,
              siac_d_movgest_tipo d_movgest_tipo,
              siac_r_movgest_ts_stato r_movgest_ts_stato,
              siac_d_movgest_stato d_movgest_stato,
              siac_d_movgest_ts_tipo d_movgest_ts_tipo,
              siac_d_movgest_ts_det_tipo d_movgest_ts_det_tipo
          where t_movgest_ts.movgest_id=t_movgest.movgest_id
              and t_movgest_ts_det.movgest_ts_id=t_movgest_ts.movgest_ts_id
              and d_movgest_ts_tipo.movgest_ts_tipo_id=t_movgest_ts.movgest_ts_tipo_id
              and r_movgest_bil_elem.movgest_id=t_movgest.movgest_id
              and d_movgest_tipo.movgest_tipo_id=t_movgest.movgest_tipo_id
              and d_movgest_ts_det_tipo.movgest_ts_det_tipo_id=t_movgest_ts_det.movgest_ts_det_tipo_id
              and r_movgest_ts_stato.movgest_ts_id=t_movgest_ts.movgest_ts_id
              and r_movgest_ts_stato.movgest_stato_id=d_movgest_stato.movgest_stato_id
              and t_movgest.ente_proprietario_id = p_ente_prop_id
              and t_movgest.bil_id=bilancio_id
              and t_movgest.movgest_anno = p_anno::integer
              and d_movgest_tipo.movgest_tipo_code='I'
              	--escludo solo gli impegni ANNULLATI.
            and d_movgest_stato.movgest_stato_code <> 'A'            	
              	-- per il PRENOTATO devo prendere l'importo dei SUB-IMPEGNI      	
          	  and d_movgest_ts_tipo.movgest_ts_tipo_code='S'     
                  -- l'importo IMPEGNATO ha la tipologia = A - ATTUALE         	
              and d_movgest_ts_det_tipo.movgest_ts_det_tipo_code='A'
              and r_movgest_ts_stato.validita_fine is NULL
              and r_movgest_ts_stato.data_cancellazione is null
              and t_movgest.data_cancellazione is null
              and t_movgest_ts.data_cancellazione is null
              and t_movgest_ts_det.data_cancellazione is null
              and r_movgest_bil_elem.data_cancellazione is null
              and d_movgest_tipo.data_cancellazione is null          	
              and d_movgest_stato.data_cancellazione is null
              and d_movgest_ts_tipo.data_cancellazione is null
              and d_movgest_ts_det_tipo.data_cancellazione is null
            group by t_movgest_ts.movgest_id),              
        liquidazioni_anno as(
    	select t_movgest_ts.movgest_ts_id,
        	sum(coalesce(t_liq.liq_importo,0)) liquidazioni 
        from siac_t_movgest t_movgest,
        	siac_t_movgest_ts t_movgest_ts,
            siac_r_liquidazione_movgest r_liq_movgest,
            siac_t_liquidazione t_liq,
            siac_t_movgest_ts_det t_movgest_ts_det,
			siac_r_movgest_bil_elem r_movgest_bil_elem,
            siac_d_movgest_tipo d_movgest_tipo,
            siac_r_movgest_ts_stato r_movgest_ts_stato,
            siac_d_movgest_stato d_movgest_stato,
			siac_d_movgest_ts_tipo d_movgest_ts_tipo,
            siac_d_movgest_ts_det_tipo d_movgest_ts_det_tipo
 		where t_movgest_ts.movgest_id=t_movgest.movgest_id
           	and t_movgest_ts_det.movgest_ts_id=t_movgest_ts.movgest_ts_id
           	and d_movgest_ts_tipo.movgest_ts_tipo_id=t_movgest_ts.movgest_ts_tipo_id
          	and r_movgest_bil_elem.movgest_id=t_movgest.movgest_id
          	and d_movgest_tipo.movgest_tipo_id=t_movgest.movgest_tipo_id
          	and d_movgest_ts_det_tipo.movgest_ts_det_tipo_id=t_movgest_ts_det.movgest_ts_det_tipo_id
          	and r_movgest_ts_stato.movgest_ts_id=t_movgest_ts.movgest_ts_id
          	and r_movgest_ts_stato.movgest_stato_id=d_movgest_stato.movgest_stato_id
            and r_liq_movgest.movgest_ts_id = t_movgest_ts.movgest_ts_id
            and t_liq.liq_id = r_liq_movgest.liq_id
            and t_movgest.ente_proprietario_id = p_ente_prop_id
            and t_movgest.bil_id=bilancio_id
            and t_movgest.movgest_anno = p_anno::integer
            and d_movgest_tipo.movgest_tipo_code='I'
          		--escludo solo gli impegni ANNULLATI.
            and d_movgest_stato.movgest_stato_code <> 'A'            	
          	and d_movgest_ts_tipo.movgest_ts_tipo_code='T'           	
          	and d_movgest_ts_det_tipo.movgest_ts_det_tipo_code='A'
            and r_movgest_ts_stato.validita_fine is NULL
            and r_movgest_ts_stato.data_cancellazione is null
          	and t_movgest.data_cancellazione is null
          	and t_movgest_ts.data_cancellazione is null
          	and t_movgest_ts_det.data_cancellazione is null
          	and r_movgest_bil_elem.data_cancellazione is null
          	and d_movgest_tipo.data_cancellazione is null          	
          	and d_movgest_stato.data_cancellazione is null
          	and d_movgest_ts_tipo.data_cancellazione is null
          	and d_movgest_ts_det_tipo.data_cancellazione is null
            and r_liq_movgest.validita_fine is NULL
            and r_liq_movgest.data_cancellazione is null
            and t_liq.data_cancellazione is null
          group by t_movgest_ts.movgest_ts_id),
    impegni_anno1 as(
    	select t_movgest_ts.movgest_ts_id,
        	sum(coalesce(t_movgest_ts_det.movgest_ts_det_importo,0)) impegni 
        from siac_t_movgest t_movgest,
        	siac_t_movgest_ts t_movgest_ts,
            siac_t_movgest_ts_det t_movgest_ts_det,
			siac_r_movgest_bil_elem r_movgest_bil_elem,
            siac_d_movgest_tipo d_movgest_tipo,
            siac_r_movgest_ts_stato r_movgest_ts_stato,
            siac_d_movgest_stato d_movgest_stato,
			siac_d_movgest_ts_tipo d_movgest_ts_tipo,
            siac_d_movgest_ts_det_tipo d_movgest_ts_det_tipo
 		where t_movgest_ts.movgest_id=t_movgest.movgest_id
           	and t_movgest_ts_det.movgest_ts_id=t_movgest_ts.movgest_ts_id
           	and d_movgest_ts_tipo.movgest_ts_tipo_id=t_movgest_ts.movgest_ts_tipo_id
          	and r_movgest_bil_elem.movgest_id=t_movgest.movgest_id
          	and d_movgest_tipo.movgest_tipo_id=t_movgest.movgest_tipo_id
          	and d_movgest_ts_det_tipo.movgest_ts_det_tipo_id=t_movgest_ts_det.movgest_ts_det_tipo_id
          	and r_movgest_ts_stato.movgest_ts_id=t_movgest_ts.movgest_ts_id
          	and r_movgest_ts_stato.movgest_stato_id=d_movgest_stato.movgest_stato_id
            and t_movgest.ente_proprietario_id = p_ente_prop_id
            and t_movgest.bil_id=bilancio_id
            and t_movgest.movgest_anno = (p_anno::integer + 1)
            and d_movgest_tipo.movgest_tipo_code='I'
          		--escludo solo gli impegni ANNULLATI.
            	--15/10/2019 - SIAC-7079: "La colonna impegnato e' il valore 
                -- attuale dell'impegno in stato definitivo".               
            --and d_movgest_stato.movgest_stato_code <> 'A'   
            and d_movgest_stato.movgest_stato_code = 'D'             	
          	and d_movgest_ts_tipo.movgest_ts_tipo_code='T'   
            	-- l'importo IMPEGNATO ha la tipologia = A - ATTUALE         	
          	and d_movgest_ts_det_tipo.movgest_ts_det_tipo_code='A'
            and r_movgest_ts_stato.validita_fine is NULL
            and r_movgest_ts_stato.data_cancellazione is null
          	and t_movgest.data_cancellazione is null
          	and t_movgest_ts.data_cancellazione is null
          	and t_movgest_ts_det.data_cancellazione is null
          	and r_movgest_bil_elem.data_cancellazione is null
          	and d_movgest_tipo.data_cancellazione is null          	
          	and d_movgest_stato.data_cancellazione is null
          	and d_movgest_ts_tipo.data_cancellazione is null
          	and d_movgest_ts_det_tipo.data_cancellazione is null
          group by t_movgest_ts.movgest_ts_id),
          --15/10/2019 - SIAC-7079: Lo stanziato e' l'importo Attuale del
          -- quadro economico per l'anno.
      stanziato_anno1 as(
      		select a.cronop_elem_id, sum(a.cronop_elem_det_importo) stanziato
    		from siac_t_cronop_elem_det a,
            	siac_t_periodo b
            where a.periodo_id = b.periodo_id
            	and a.ente_proprietario_id= p_ente_prop_id
                and b.anno= (p_anno::integer +1)::varchar
            	and a.data_cancellazione IS NULL
                and b.data_cancellazione IS NULL
            group by a.cronop_elem_id),
	/*stanziato_anno1 as(
    	select t_movgest_ts.movgest_ts_id,
        	sum(coalesce(t_movgest_ts_det.movgest_ts_det_importo,0)) stanziato 
        from siac_t_movgest t_movgest,
        	siac_t_movgest_ts t_movgest_ts,
            siac_t_movgest_ts_det t_movgest_ts_det,
			siac_r_movgest_bil_elem r_movgest_bil_elem,
            siac_d_movgest_tipo d_movgest_tipo,
            siac_r_movgest_ts_stato r_movgest_ts_stato,
            siac_d_movgest_stato d_movgest_stato,
			siac_d_movgest_ts_tipo d_movgest_ts_tipo,
            siac_d_movgest_ts_det_tipo d_movgest_ts_det_tipo
 		where t_movgest_ts.movgest_id=t_movgest.movgest_id
           	and t_movgest_ts_det.movgest_ts_id=t_movgest_ts.movgest_ts_id
           	and d_movgest_ts_tipo.movgest_ts_tipo_id=t_movgest_ts.movgest_ts_tipo_id
          	and r_movgest_bil_elem.movgest_id=t_movgest.movgest_id
          	and d_movgest_tipo.movgest_tipo_id=t_movgest.movgest_tipo_id
          	and d_movgest_ts_det_tipo.movgest_ts_det_tipo_id=t_movgest_ts_det.movgest_ts_det_tipo_id
          	and r_movgest_ts_stato.movgest_ts_id=t_movgest_ts.movgest_ts_id
          	and r_movgest_ts_stato.movgest_stato_id=d_movgest_stato.movgest_stato_id
            and t_movgest.ente_proprietario_id = p_ente_prop_id
            and t_movgest.bil_id=bilancio_id
            and t_movgest.movgest_anno = (p_anno::integer +1)
            and d_movgest_tipo.movgest_tipo_code='I'
          		--escludo solo gli impegni ANNULLATI.
            and d_movgest_stato.movgest_stato_code <> 'A'            	
          	and d_movgest_ts_tipo.movgest_ts_tipo_code='T'       
            	-- l'importo STANZIATO ha la tipologia = I - INIZIALE    	
          	and d_movgest_ts_det_tipo.movgest_ts_det_tipo_code='I'
            and r_movgest_ts_stato.validita_fine is NULL
            and r_movgest_ts_stato.data_cancellazione is null
          	and t_movgest.data_cancellazione is null
          	and t_movgest_ts.data_cancellazione is null
          	and t_movgest_ts_det.data_cancellazione is null
          	and r_movgest_bil_elem.data_cancellazione is null
          	and d_movgest_tipo.data_cancellazione is null          	
          	and d_movgest_stato.data_cancellazione is null
          	and d_movgest_ts_tipo.data_cancellazione is null
          	and d_movgest_ts_det_tipo.data_cancellazione is null
          group by t_movgest_ts.movgest_ts_id) ,*/
	prenotato_anno1 as(
          select t_movgest_ts.movgest_id,
              sum(coalesce(t_movgest_ts_det.movgest_ts_det_importo,0)) prenotato 
          from siac_t_movgest t_movgest,
              siac_t_movgest_ts t_movgest_ts,
              siac_t_movgest_ts_det t_movgest_ts_det,
              siac_r_movgest_bil_elem r_movgest_bil_elem,
              siac_d_movgest_tipo d_movgest_tipo,
              siac_r_movgest_ts_stato r_movgest_ts_stato,
              siac_d_movgest_stato d_movgest_stato,
              siac_d_movgest_ts_tipo d_movgest_ts_tipo,
              siac_d_movgest_ts_det_tipo d_movgest_ts_det_tipo
          where t_movgest_ts.movgest_id=t_movgest.movgest_id
              and t_movgest_ts_det.movgest_ts_id=t_movgest_ts.movgest_ts_id
              and d_movgest_ts_tipo.movgest_ts_tipo_id=t_movgest_ts.movgest_ts_tipo_id
              and r_movgest_bil_elem.movgest_id=t_movgest.movgest_id
              and d_movgest_tipo.movgest_tipo_id=t_movgest.movgest_tipo_id
              and d_movgest_ts_det_tipo.movgest_ts_det_tipo_id=t_movgest_ts_det.movgest_ts_det_tipo_id
              and r_movgest_ts_stato.movgest_ts_id=t_movgest_ts.movgest_ts_id
              and r_movgest_ts_stato.movgest_stato_id=d_movgest_stato.movgest_stato_id
              and t_movgest.ente_proprietario_id = p_ente_prop_id
              and t_movgest.bil_id=bilancio_id
              and t_movgest.movgest_anno = (p_anno::integer +1)
              and d_movgest_tipo.movgest_tipo_code='I'
              	--escludo solo gli impegni ANNULLATI.
            and d_movgest_stato.movgest_stato_code <> 'A'           	
              	-- per il PRENOTATO devo prendere l'importo dei SUB-IMPEGNI      	
          	  and d_movgest_ts_tipo.movgest_ts_tipo_code='S'     
                  -- l'importo IMPEGNATO ha la tipologia = A - ATTUALE         	
              and d_movgest_ts_det_tipo.movgest_ts_det_tipo_code='A'
              and r_movgest_ts_stato.validita_fine is NULL
              and r_movgest_ts_stato.data_cancellazione is null
              and t_movgest.data_cancellazione is null
              and t_movgest_ts.data_cancellazione is null
              and t_movgest_ts_det.data_cancellazione is null
              and r_movgest_bil_elem.data_cancellazione is null
              and d_movgest_tipo.data_cancellazione is null          	
              and d_movgest_stato.data_cancellazione is null
              and d_movgest_ts_tipo.data_cancellazione is null
              and d_movgest_ts_det_tipo.data_cancellazione is null
            group by t_movgest_ts.movgest_id),           
    impegni_anno2 as(
    	select t_movgest_ts.movgest_ts_id,
        	sum(coalesce(t_movgest_ts_det.movgest_ts_det_importo,0)) impegni 
        from siac_t_movgest t_movgest,
        	siac_t_movgest_ts t_movgest_ts,
            siac_t_movgest_ts_det t_movgest_ts_det,
			siac_r_movgest_bil_elem r_movgest_bil_elem,
            siac_d_movgest_tipo d_movgest_tipo,
            siac_r_movgest_ts_stato r_movgest_ts_stato,
            siac_d_movgest_stato d_movgest_stato,
			siac_d_movgest_ts_tipo d_movgest_ts_tipo,
            siac_d_movgest_ts_det_tipo d_movgest_ts_det_tipo
 		where t_movgest_ts.movgest_id=t_movgest.movgest_id
           	and t_movgest_ts_det.movgest_ts_id=t_movgest_ts.movgest_ts_id
           	and d_movgest_ts_tipo.movgest_ts_tipo_id=t_movgest_ts.movgest_ts_tipo_id
          	and r_movgest_bil_elem.movgest_id=t_movgest.movgest_id
          	and d_movgest_tipo.movgest_tipo_id=t_movgest.movgest_tipo_id
          	and d_movgest_ts_det_tipo.movgest_ts_det_tipo_id=t_movgest_ts_det.movgest_ts_det_tipo_id
          	and r_movgest_ts_stato.movgest_ts_id=t_movgest_ts.movgest_ts_id
          	and r_movgest_ts_stato.movgest_stato_id=d_movgest_stato.movgest_stato_id
            and t_movgest.ente_proprietario_id = p_ente_prop_id
            and t_movgest.bil_id=bilancio_id
            and t_movgest.movgest_anno = (p_anno::integer + 2)
            and d_movgest_tipo.movgest_tipo_code='I'
          		--escludo solo gli impegni ANNULLATI.
            	--15/10/2019 - SIAC-7079: "La colonna impegnato e' il valore 
                -- attuale dell'impegno in stato definitivo".                
            --and d_movgest_stato.movgest_stato_code <> 'A'   
            and d_movgest_stato.movgest_stato_code = 'D'            	
          	and d_movgest_ts_tipo.movgest_ts_tipo_code='T'   
            	-- l'importo IMPEGNATO ha la tipologia = A - ATTUALE         	
          	and d_movgest_ts_det_tipo.movgest_ts_det_tipo_code='A'
            and r_movgest_ts_stato.validita_fine is NULL
            and r_movgest_ts_stato.data_cancellazione is null
          	and t_movgest.data_cancellazione is null
          	and t_movgest_ts.data_cancellazione is null
          	and t_movgest_ts_det.data_cancellazione is null
          	and r_movgest_bil_elem.data_cancellazione is null
          	and d_movgest_tipo.data_cancellazione is null          	
          	and d_movgest_stato.data_cancellazione is null
          	and d_movgest_ts_tipo.data_cancellazione is null
          	and d_movgest_ts_det_tipo.data_cancellazione is null
          group by t_movgest_ts.movgest_ts_id),
          --15/10/2019 - SIAC-7079: Lo stanziato e' l'importo Attuale del
          -- quadro economico per l'anno.
        stanziato_anno2 as(
      		select a.cronop_elem_id, sum(a.cronop_elem_det_importo) stanziato
    		from siac_t_cronop_elem_det a,
            	siac_t_periodo b
            where a.periodo_id = b.periodo_id
            	and a.ente_proprietario_id= p_ente_prop_id
                and b.anno= (p_anno::integer +2)::varchar
            	and a.data_cancellazione IS NULL
                and b.data_cancellazione IS NULL
            group by a.cronop_elem_id),
       /* stanziato_anno2 as(
    	select t_movgest_ts.movgest_ts_id,
        	sum(coalesce(t_movgest_ts_det.movgest_ts_det_importo,0)) stanziato 
        from siac_t_movgest t_movgest,
        	siac_t_movgest_ts t_movgest_ts,
            siac_t_movgest_ts_det t_movgest_ts_det,
			siac_r_movgest_bil_elem r_movgest_bil_elem,
            siac_d_movgest_tipo d_movgest_tipo,
            siac_r_movgest_ts_stato r_movgest_ts_stato,
            siac_d_movgest_stato d_movgest_stato,
			siac_d_movgest_ts_tipo d_movgest_ts_tipo,
            siac_d_movgest_ts_det_tipo d_movgest_ts_det_tipo
 		where t_movgest_ts.movgest_id=t_movgest.movgest_id
           	and t_movgest_ts_det.movgest_ts_id=t_movgest_ts.movgest_ts_id
           	and d_movgest_ts_tipo.movgest_ts_tipo_id=t_movgest_ts.movgest_ts_tipo_id
          	and r_movgest_bil_elem.movgest_id=t_movgest.movgest_id
          	and d_movgest_tipo.movgest_tipo_id=t_movgest.movgest_tipo_id
          	and d_movgest_ts_det_tipo.movgest_ts_det_tipo_id=t_movgest_ts_det.movgest_ts_det_tipo_id
          	and r_movgest_ts_stato.movgest_ts_id=t_movgest_ts.movgest_ts_id
          	and r_movgest_ts_stato.movgest_stato_id=d_movgest_stato.movgest_stato_id
            and t_movgest.ente_proprietario_id = p_ente_prop_id
            and t_movgest.bil_id=bilancio_id
            and t_movgest.movgest_anno = (p_anno::integer +2)
            and d_movgest_tipo.movgest_tipo_code='I'
          		--escludo solo gli impegni ANNULLATI.
            and d_movgest_stato.movgest_stato_code <> 'A'           	
          	and d_movgest_ts_tipo.movgest_ts_tipo_code='T'       
            	-- l'importo STANZIATO ha la tipologia = I - INIZIALE    	
          	and d_movgest_ts_det_tipo.movgest_ts_det_tipo_code='I'
            and r_movgest_ts_stato.validita_fine is NULL
            and r_movgest_ts_stato.data_cancellazione is null
          	and t_movgest.data_cancellazione is null
          	and t_movgest_ts.data_cancellazione is null
          	and t_movgest_ts_det.data_cancellazione is null
          	and r_movgest_bil_elem.data_cancellazione is null
          	and d_movgest_tipo.data_cancellazione is null          	
          	and d_movgest_stato.data_cancellazione is null
          	and d_movgest_ts_tipo.data_cancellazione is null
          	and d_movgest_ts_det_tipo.data_cancellazione is null
          group by t_movgest_ts.movgest_ts_id), */
    prenotato_anno2 as(
          select t_movgest_ts.movgest_id,
              sum(coalesce(t_movgest_ts_det.movgest_ts_det_importo,0)) prenotato 
          from siac_t_movgest t_movgest,
              siac_t_movgest_ts t_movgest_ts,
              siac_t_movgest_ts_det t_movgest_ts_det,
              siac_r_movgest_bil_elem r_movgest_bil_elem,
              siac_d_movgest_tipo d_movgest_tipo,
              siac_r_movgest_ts_stato r_movgest_ts_stato,
              siac_d_movgest_stato d_movgest_stato,
              siac_d_movgest_ts_tipo d_movgest_ts_tipo,
              siac_d_movgest_ts_det_tipo d_movgest_ts_det_tipo
          where t_movgest_ts.movgest_id=t_movgest.movgest_id
              and t_movgest_ts_det.movgest_ts_id=t_movgest_ts.movgest_ts_id
              and d_movgest_ts_tipo.movgest_ts_tipo_id=t_movgest_ts.movgest_ts_tipo_id
              and r_movgest_bil_elem.movgest_id=t_movgest.movgest_id
              and d_movgest_tipo.movgest_tipo_id=t_movgest.movgest_tipo_id
              and d_movgest_ts_det_tipo.movgest_ts_det_tipo_id=t_movgest_ts_det.movgest_ts_det_tipo_id
              and r_movgest_ts_stato.movgest_ts_id=t_movgest_ts.movgest_ts_id
              and r_movgest_ts_stato.movgest_stato_id=d_movgest_stato.movgest_stato_id
              and t_movgest.ente_proprietario_id = p_ente_prop_id
              and t_movgest.bil_id=bilancio_id
              and t_movgest.movgest_anno = (p_anno::integer + 2)
              and d_movgest_tipo.movgest_tipo_code='I'
              	--escludo solo gli impegni ANNULLATI.
              and d_movgest_stato.movgest_stato_code <> 'A'            	
              	-- per il PRENOTATO devo prendere l'importo dei SUB-IMPEGNI      	
          	  and d_movgest_ts_tipo.movgest_ts_tipo_code='S'     
                  -- l'importo IMPEGNATO ha la tipologia = A - ATTUALE         	
              and d_movgest_ts_det_tipo.movgest_ts_det_tipo_code='A'
              and r_movgest_ts_stato.validita_fine is NULL
              and r_movgest_ts_stato.data_cancellazione is null
              and t_movgest.data_cancellazione is null
              and t_movgest_ts.data_cancellazione is null
              and t_movgest_ts_det.data_cancellazione is null
              and r_movgest_bil_elem.data_cancellazione is null
              and d_movgest_tipo.data_cancellazione is null          	
              and d_movgest_stato.data_cancellazione is null
              and d_movgest_ts_tipo.data_cancellazione is null
              and d_movgest_ts_det_tipo.data_cancellazione is null
            group by t_movgest_ts.movgest_id), 
	impegni_anni_succ as(
    	select t_movgest_ts.movgest_ts_id,
        	sum(coalesce(t_movgest_ts_det.movgest_ts_det_importo,0)) impegni 
        from siac_t_movgest t_movgest,
        	siac_t_movgest_ts t_movgest_ts,
            siac_t_movgest_ts_det t_movgest_ts_det,
			siac_r_movgest_bil_elem r_movgest_bil_elem,
            siac_d_movgest_tipo d_movgest_tipo,
            siac_r_movgest_ts_stato r_movgest_ts_stato,
            siac_d_movgest_stato d_movgest_stato,
			siac_d_movgest_ts_tipo d_movgest_ts_tipo,
            siac_d_movgest_ts_det_tipo d_movgest_ts_det_tipo
 		where t_movgest_ts.movgest_id=t_movgest.movgest_id
           	and t_movgest_ts_det.movgest_ts_id=t_movgest_ts.movgest_ts_id
           	and d_movgest_ts_tipo.movgest_ts_tipo_id=t_movgest_ts.movgest_ts_tipo_id
          	and r_movgest_bil_elem.movgest_id=t_movgest.movgest_id
          	and d_movgest_tipo.movgest_tipo_id=t_movgest.movgest_tipo_id
          	and d_movgest_ts_det_tipo.movgest_ts_det_tipo_id=t_movgest_ts_det.movgest_ts_det_tipo_id
          	and r_movgest_ts_stato.movgest_ts_id=t_movgest_ts.movgest_ts_id
          	and r_movgest_ts_stato.movgest_stato_id=d_movgest_stato.movgest_stato_id
            and t_movgest.ente_proprietario_id = p_ente_prop_id
            and t_movgest.bil_id=bilancio_id
            and t_movgest.movgest_anno > (p_anno::integer + 2)
            and d_movgest_tipo.movgest_tipo_code='I'
          		--escludo solo gli impegni ANNULLATI.
                --15/10/2019 - SIAC-7079: "La colonna impegnato e' il valore 
                -- attuale dell'impegno in stato definitivo".                
            --and d_movgest_stato.movgest_stato_code <> 'A'   
            and d_movgest_stato.movgest_stato_code = 'D'    
            and d_movgest_stato.movgest_stato_code <> 'A'            	
          	and d_movgest_ts_tipo.movgest_ts_tipo_code='T'   
            	-- l'importo IMPEGNATO ha la tipologia = A - ATTUALE         	
          	and d_movgest_ts_det_tipo.movgest_ts_det_tipo_code='A'
            and r_movgest_ts_stato.validita_fine is NULL
            and r_movgest_ts_stato.data_cancellazione is null
          	and t_movgest.data_cancellazione is null
          	and t_movgest_ts.data_cancellazione is null
          	and t_movgest_ts_det.data_cancellazione is null
          	and r_movgest_bil_elem.data_cancellazione is null
          	and d_movgest_tipo.data_cancellazione is null          	
          	and d_movgest_stato.data_cancellazione is null
          	and d_movgest_ts_tipo.data_cancellazione is null
          	and d_movgest_ts_det_tipo.data_cancellazione is null
          group by t_movgest_ts.movgest_ts_id),  
          --15/10/2019 - SIAC-7079: Lo stanziato e' l'importo Attuale del
          -- quadro economico per l'anno.          
         stanziato_anni_succ as(
      		select a.cronop_elem_id, sum(a.cronop_elem_det_importo) stanziato
    		from siac_t_cronop_elem_det a,
            	siac_t_periodo b
            where a.periodo_id = b.periodo_id
            	and a.ente_proprietario_id= p_ente_prop_id
                and b.anno::integer > (p_anno::integer +2)
            	and a.data_cancellazione IS NULL
                and b.data_cancellazione IS NULL
            group by a.cronop_elem_id),            
       /* stanziato_anni_succ as(
    	select t_movgest_ts.movgest_ts_id,
        	sum(coalesce(t_movgest_ts_det.movgest_ts_det_importo,0)) stanziato 
        from siac_t_movgest t_movgest,
        	siac_t_movgest_ts t_movgest_ts,
            siac_t_movgest_ts_det t_movgest_ts_det,
			siac_r_movgest_bil_elem r_movgest_bil_elem,
            siac_d_movgest_tipo d_movgest_tipo,
            siac_r_movgest_ts_stato r_movgest_ts_stato,
            siac_d_movgest_stato d_movgest_stato,
			siac_d_movgest_ts_tipo d_movgest_ts_tipo,
            siac_d_movgest_ts_det_tipo d_movgest_ts_det_tipo
 		where t_movgest_ts.movgest_id=t_movgest.movgest_id
           	and t_movgest_ts_det.movgest_ts_id=t_movgest_ts.movgest_ts_id
           	and d_movgest_ts_tipo.movgest_ts_tipo_id=t_movgest_ts.movgest_ts_tipo_id
          	and r_movgest_bil_elem.movgest_id=t_movgest.movgest_id
          	and d_movgest_tipo.movgest_tipo_id=t_movgest.movgest_tipo_id
          	and d_movgest_ts_det_tipo.movgest_ts_det_tipo_id=t_movgest_ts_det.movgest_ts_det_tipo_id
          	and r_movgest_ts_stato.movgest_ts_id=t_movgest_ts.movgest_ts_id
          	and r_movgest_ts_stato.movgest_stato_id=d_movgest_stato.movgest_stato_id
            and t_movgest.ente_proprietario_id = p_ente_prop_id
            and t_movgest.bil_id=bilancio_id
            and t_movgest.movgest_anno > (p_anno::integer +2)
            and d_movgest_tipo.movgest_tipo_code='I'
          		--escludo solo gli impegni ANNULLATI.
            and d_movgest_stato.movgest_stato_code <> 'A'            	
          	and d_movgest_ts_tipo.movgest_ts_tipo_code='T'       
            	-- l'importo STANZIATO ha la tipologia = I - INIZIALE    	
          	and d_movgest_ts_det_tipo.movgest_ts_det_tipo_code='I'
            and r_movgest_ts_stato.validita_fine is NULL
            and r_movgest_ts_stato.data_cancellazione is null
          	and t_movgest.data_cancellazione is null
          	and t_movgest_ts.data_cancellazione is null
          	and t_movgest_ts_det.data_cancellazione is null
          	and r_movgest_bil_elem.data_cancellazione is null
          	and d_movgest_tipo.data_cancellazione is null          	
          	and d_movgest_stato.data_cancellazione is null
          	and d_movgest_ts_tipo.data_cancellazione is null
          	and d_movgest_ts_det_tipo.data_cancellazione is null
          group by t_movgest_ts.movgest_ts_id),*/
        prenotato_anni_succ as(
          select t_movgest_ts.movgest_id,
              sum(coalesce(t_movgest_ts_det.movgest_ts_det_importo,0)) prenotato 
          from siac_t_movgest t_movgest,
              siac_t_movgest_ts t_movgest_ts,
              siac_t_movgest_ts_det t_movgest_ts_det,
              siac_r_movgest_bil_elem r_movgest_bil_elem,
              siac_d_movgest_tipo d_movgest_tipo,
              siac_r_movgest_ts_stato r_movgest_ts_stato,
              siac_d_movgest_stato d_movgest_stato,
              siac_d_movgest_ts_tipo d_movgest_ts_tipo,
              siac_d_movgest_ts_det_tipo d_movgest_ts_det_tipo
          where t_movgest_ts.movgest_id=t_movgest.movgest_id
              and t_movgest_ts_det.movgest_ts_id=t_movgest_ts.movgest_ts_id
              and d_movgest_ts_tipo.movgest_ts_tipo_id=t_movgest_ts.movgest_ts_tipo_id
              and r_movgest_bil_elem.movgest_id=t_movgest.movgest_id
              and d_movgest_tipo.movgest_tipo_id=t_movgest.movgest_tipo_id
              and d_movgest_ts_det_tipo.movgest_ts_det_tipo_id=t_movgest_ts_det.movgest_ts_det_tipo_id
              and r_movgest_ts_stato.movgest_ts_id=t_movgest_ts.movgest_ts_id
              and r_movgest_ts_stato.movgest_stato_id=d_movgest_stato.movgest_stato_id
              and t_movgest.ente_proprietario_id = p_ente_prop_id
              and t_movgest.bil_id=bilancio_id
              and t_movgest.movgest_anno > (p_anno::integer + 2)
              and d_movgest_tipo.movgest_tipo_code='I'
              	--escludo solo gli impegni ANNULLATI.
              and d_movgest_stato.movgest_stato_code <> 'A'            	
              	-- per il PRENOTATO devo prendere l'importo dei SUB-IMPEGNI      	
          	  and d_movgest_ts_tipo.movgest_ts_tipo_code='S'     
                  -- l'importo IMPEGNATO ha la tipologia = A - ATTUALE         	
              and d_movgest_ts_det_tipo.movgest_ts_det_tipo_code='A'
              and r_movgest_ts_stato.validita_fine is NULL
              and r_movgest_ts_stato.data_cancellazione is null
              and t_movgest.data_cancellazione is null
              and t_movgest_ts.data_cancellazione is null
              and t_movgest_ts_det.data_cancellazione is null
              and r_movgest_bil_elem.data_cancellazione is null
              and d_movgest_tipo.data_cancellazione is null          	
              and d_movgest_stato.data_cancellazione is null
              and d_movgest_ts_tipo.data_cancellazione is null
              and d_movgest_ts_det_tipo.data_cancellazione is null
            group by t_movgest_ts.movgest_id),
            --17/10/2019 SIAC-7079 introdotto il valore "contabilizzato".
		contabilizzato_anno as (
        		select  r_subdoc_movgest_ts.movgest_ts_id,
                  sum(t_subdoc.subdoc_importo) contabilizzato
                from siac_t_doc t_doc
                         join (select d_doc_tipo.doc_tipo_id
                                from  siac_d_doc_tipo d_doc_tipo,
                                        siac_r_doc_tipo_attr r_doc_tipo_attr,
                                        siac_t_attr t_attr,
                                        siac_d_doc_fam_tipo d_doc_fam_tipo
                                where d_doc_tipo.doc_tipo_id=r_doc_tipo_attr.doc_tipo_id
                                    and r_doc_tipo_attr.attr_id=t_attr.attr_id
                                    and d_doc_fam_tipo.doc_fam_tipo_id=d_doc_tipo.doc_fam_tipo_id
                                    and d_doc_tipo.ente_proprietario_id =p_ente_prop_id
                                    and t_attr.attr_code='flagAttivaGEN'
                                    and d_doc_fam_tipo.doc_fam_tipo_code='S'
                                    and d_doc_tipo.data_cancellazione IS NULL
                                    and r_doc_tipo_attr.data_cancellazione IS NULL
                                    and t_attr.data_cancellazione IS NULL
                                    and d_doc_fam_tipo.data_cancellazione IS NULL) tipo_doc_valido
                            ON tipo_doc_valido.doc_tipo_id=t_doc.doc_tipo_id,
                    siac_t_subdoc t_subdoc,
                    siac_r_subdoc_movgest_ts   r_subdoc_movgest_ts,
                    siac_t_movgest_ts t_movgest_ts,
                    siac_t_movgest t_movgest,
                    siac_d_doc_stato d_doc_stato,
                    siac_r_doc_stato r_doc_stato   
                where t_doc.doc_id=t_subdoc.doc_id
                    and t_subdoc.subdoc_id= r_subdoc_movgest_ts.subdoc_id
                    and r_subdoc_movgest_ts.movgest_ts_id=t_movgest_ts.movgest_ts_id
                    and t_movgest_ts.movgest_id=t_movgest.movgest_id
                    and r_doc_stato.doc_id=t_doc.doc_id
                    and r_doc_stato.doc_stato_id=d_doc_stato.doc_stato_id
                    and t_doc.ente_proprietario_id=p_ente_prop_id
                    and doc_contabilizza_genpcc=true
                    and d_doc_stato.doc_stato_code <> 'A'
                    and t_movgest.movgest_anno = p_anno::integer
                    and t_movgest.bil_id=bilancio_id
                    and t_doc.data_cancellazione IS NULL
                    and t_subdoc.data_cancellazione IS NULL
                    and r_subdoc_movgest_ts.data_cancellazione IS NULL
                    and d_doc_stato.data_cancellazione IS NULL
                    and r_doc_stato.data_cancellazione IS NULL
                    and t_movgest_ts.data_cancellazione IS NULL
                    and t_movgest.data_cancellazione IS NULL
                group by  r_subdoc_movgest_ts.movgest_ts_id    )                        
         --16/10/2019 SIAC-7075.
         -- estratto anche il campo cronop_elem_det_id per l'ordinamento nel report.
    	select quadro_economico.parte_code::varchar  parte_code,
            quadro_economico.parte_desc::varchar parte_desc,
            quadro_economico.quadro_economico_id::integer quadro_economico_id,
            quadro_economico.quadro_economico_code::varchar quadro_economico_code,
            quadro_economico.quadro_economico_desc::varchar quadro_economico_desc,
            quadro_economico.quadro_economico_id_padre::integer quadro_economico_id_padre,
            quadro_economico.livello::integer livello,
            quadro_economico.quadro_economico_stato_code::varchar quadro_economico_stato_code,
            quadro_economico.quadro_economico_stato_desc::varchar quadro_economico_stato_desc,
            quadro_economico.voce_quadro_economico::varchar voce_quadro_economico,
            quadro_economico.importo_quadro_economico::numeric importo_quadro_economico,
            quadro_economico.cronop_data_approvazione_fattibilita::timestamp cronop_data_approvazione_fattibilita,
            quadro_economico.cronop_data_approvazione_programma_def::timestamp cronop_data_approvazione_programma_def,
            quadro_economico.cronop_data_approvazione_programma_esec::timestamp cronop_data_approvazione_programma_esec,
            quadro_economico.cronop_data_avvio_procedura::timestamp cronop_data_avvio_procedura,
            quadro_economico.cronop_data_aggiudicazione_lavori::timestamp cronop_data_aggiudicazione_lavori,
            quadro_economico.cronop_data_inizio_lavori::timestamp cronop_data_inizio_lavori,
            quadro_economico.cronop_data_fine_lavori::timestamp cronop_data_fine_lavori,
            quadro_economico.cronop_giorni_durata::integer cronop_giorni_durata,
            quadro_economico.cronop_data_collaudo::timestamp cronop_data_collaudo,
            COALESCE(liquidazioni_anno_prec.liquidazioni,0)::numeric liquidato_anni_prec,
  			COALESCE(stanziato_anno.stanziato,0)::numeric stanziato_anno,
            COALESCE(impegni_anno.impegni,0)::numeric impegnato_anno,
            COALESCE(prenotato_anno.prenotato,0)::numeric prenotato_anno,
            COALESCE(liquidazioni_anno.liquidazioni,0)::numeric liquidato_anno,
            COALESCE(stanziato_anno1.stanziato,0)::numeric stanziato_anno1,
            COALESCE(impegni_anno1.impegni,0)::numeric impegnato_anno1,
            COALESCE(prenotato_anno1.prenotato,0)::numeric prenotato_anno1,
            COALESCE(stanziato_anno2.stanziato,0)::numeric stanziato_anno2,
            COALESCE(impegni_anno2.impegni,0)::numeric impegnato_anno2,
            COALESCE(prenotato_anno2.prenotato,0)::numeric prenotato_anno2,
            COALESCE(stanziato_anni_succ.stanziato,0)::numeric stanziato_anni_succ,
            COALESCE(impegni_anni_succ.impegni,0)::numeric impegnato_anni_succ,
            COALESCE(prenotato_anni_succ.prenotato,0)::numeric prenotato_anni_succ,
            COALESCE(contabilizzato_anno.contabilizzato,0)::numeric contabilizzato_anno,
            quadro_economico.cronop_elem_det_id::integer ordinamento
        from quadro_economico
        	left join impegni_anno
            	ON impegni_anno.movgest_ts_id = quadro_economico.movgest_ts_id 
            left join liquidazioni_anno
            	ON liquidazioni_anno.movgest_ts_id = quadro_economico.movgest_ts_id
            left join liquidazioni_anno_prec
            	ON liquidazioni_anno_prec.movgest_ts_id = quadro_economico.movgest_ts_id
            left join stanziato_anno
            	ON stanziato_anno.cronop_elem_id = quadro_economico.cronop_elem_id
            left join stanziato_anno1
            	ON stanziato_anno1.cronop_elem_id = quadro_economico.cronop_elem_id
            left join stanziato_anno2
            	ON stanziato_anno2.cronop_elem_id = quadro_economico.cronop_elem_id
            left join stanziato_anni_succ
            	ON stanziato_anni_succ.cronop_elem_id = quadro_economico.cronop_elem_id
            left join impegni_anno1
            	ON impegni_anno1.movgest_ts_id = quadro_economico.movgest_ts_id 
            left join impegni_anno2
            	ON impegni_anno2.movgest_ts_id = quadro_economico.movgest_ts_id 
            left join impegni_anni_succ
            	ON impegni_anni_succ.movgest_ts_id = quadro_economico.movgest_ts_id
            left join prenotato_anno
            	ON prenotato_anno.movgest_id = quadro_economico.movgest_id  
            left join prenotato_anno1
            	ON prenotato_anno1.movgest_id = quadro_economico.movgest_id
            left join prenotato_anno2
            	ON prenotato_anno2.movgest_id = quadro_economico.movgest_id
            left join prenotato_anni_succ
            	ON prenotato_anni_succ.movgest_id = quadro_economico.movgest_id
            left join contabilizzato_anno
            	ON contabilizzato_anno.movgest_ts_id = quadro_economico.movgest_ts_id                                                                                        
       UNION -- estraggo anche le PARTI A, B, C vuote per fare in modo che nel 
              -- report esistano sempre.
            select 
              d_qua_econ_parte.parte_code  parte_code,
              d_qua_econ_parte.parte_desc parte_desc,
              0::integer quadro_economico_id,
              ''::varchar quadro_economico_code,
              ''::varchar quadro_economico_desc,
              0::integer quadro_economico_id_padre,
              0::integer livello,
              ''::varchar quadro_economico_stato_code,
              ''::varchar quadro_economico_stato_desc,
              ''::varchar voce_quadro_economico,
              0::numeric importo_quadro_economico,
              NULL cronop_data_approvazione_fattibilita,
              NULL cronop_data_approvazione_programma_def,
              NULL cronop_data_approvazione_programma_esec,
              NULL cronop_data_avvio_procedura,
              NULL cronop_data_aggiudicazione_lavori,
              NULL cronop_data_inizio_lavori,
              NULL cronop_data_fine_lavori,
              NULL cronop_giorni_durata,
              NULL cronop_data_collaudo,
              0::numeric  liquidato_anni_prec,
              0::numeric  stanziato_anno,
              0::numeric  impegnato_anno,
              0::numeric  prenotato_anno,
              0::numeric  liquidato_anno,
              0::numeric  stanziato_anno1,
              0::numeric  impegnato_anno1,
              0::numeric  prenotato_anno1,
              0::numeric  stanziato_anno2,
              0::numeric  impegnato_anno2,
              0::numeric  prenotato_anno2,
              0::numeric  stanziato_anni_succ,
              0::numeric  impegnato_anni_succ,
              0::numeric  prenotato_anni_succ,
              0::numeric contabilizzato_anno,
              0::integer  ordinamento
            from siac_d_quadro_economico_parte d_qua_econ_parte
            where d_qua_econ_parte.ente_proprietario_id=p_ente_prop_id
                and d_qua_econ_parte.data_cancellazione IS NULL;
        
        
exception
	when no_data_found THEN
		raise notice 'Nessun dato trovato per il quadro economico';
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

--SIAC-7074, SIAC-7075, SIAC-7076, SIAC-7079 e SIAC-7096 - Maurizio - FINE

-- 11/10/2019 Alessandro T. - Inizio - SIAC-6888
-- A seguito della segnalazione viene esguito un controllo sui livelli gestione associati all'Ente.
-- Tale controllo, gestito dal GenericBilancioModel, assicura che se un ente viene abilitato al livello -> ABILITAZIONE_INSERIMENTO_ACC_AUTOMATICO
-- ne permettera' l'inserimento accertamenti automatici, sia in caso di inserimento di una nuova quota che di aggiornamento.
-- A seguire le query utilizzate per abilitare/disabilitare un Ente. 

-- STEP 1 inserimento tipo
-- QUERY INSERIMENTO RECORD ABILITAZIONE ENTE tabella > siac_d_gestione_tipo


INSERT INTO siac.siac_d_gestione_tipo (gestione_tipo_code, gestione_tipo_desc, validita_inizio, ente_proprietario_id, login_operazione)
SELECT tmp.code, tmp.descr, now(), tep.ente_proprietario_id, 'SIAC-6888'
FROM siac.siac_t_ente_proprietario tep
CROSS JOIN (VALUES
    ('ABILITAZIONE_INSERIMENTO_ACC_AUTOMATICO', 'ABILITAZIONE_INSERIMENTO_ACC_AUTOMATICO')
) AS tmp (code, descr)
WHERE NOT EXISTS (
    SELECT 1
    FROM siac.siac_d_gestione_tipo dgt
    WHERE dgt.ente_proprietario_id = tep.ente_proprietario_id
    AND dgt.gestione_tipo_code = tmp.code
);


-- STEP 2 inserimento livello
-- QUERY INSERIMENTO RECORD ABILITAZIONE ENTE tabella > siac_d_gestione_livello


INSERT INTO siac.siac_d_gestione_livello (gestione_livello_code, gestione_livello_desc, gestione_tipo_id, validita_inizio, ente_proprietario_id, login_operazione)
SELECT tmp.code, tmp.descr, dgt.gestione_tipo_id, now(), tep.ente_proprietario_id, 'SIAC-6888'
FROM siac.siac_t_ente_proprietario tep
JOIN siac.siac_d_gestione_tipo dgt ON dgt.ente_proprietario_id = tep.ente_proprietario_id
JOIN (VALUES
    ('ABILITAZIONE_INSERIMENTO_ACC_AUTOMATICO', 'ABILITAZIONE_INSERIMENTO_ACC_AUTOMATICO', 'ABILITAZIONE_INSERIMENTO_ACC_AUTOMATICO')
) AS tmp(code, descr, tipo) ON (tmp.tipo = dgt.gestione_tipo_code)
WHERE NOT EXISTS (
    SELECT 1
    FROM siac.siac_d_gestione_livello dgl
    WHERE dgl.ente_proprietario_id = tep.ente_proprietario_id
    AND dgl.gestione_livello_code = tmp.code
    AND dgl.gestione_tipo_id = dgt.gestione_tipo_id
);

--11/10/2019 Alessandro T. - Fine - SIAC-6888

-- 6879 inizio
SELECT * from fnc_dba_add_column_params ('siac_t_prov_cassa', 'provc_data_invio_servizio', 'TIMESTAMP WITHOUT TIME ZONE');
SELECT * from fnc_dba_add_column_params ('siac_t_prov_cassa', 'provc_data_rifiuto_errata_attribuzione', 'TIMESTAMP WITHOUT TIME ZONE');
SELECT * from fnc_dba_add_column_params ('siac_t_prov_cassa', 'provc_data_presa_in_carico_servizio', 'TIMESTAMP WITHOUT TIME ZONE');
-- 6879 fine

