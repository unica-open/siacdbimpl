/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
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