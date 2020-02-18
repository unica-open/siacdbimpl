/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac."BILR104_stampa_ritenute_inps_irpeg" (
  p_ente_prop_id integer,
  p_anno varchar,
  p_data_mandato_da date,
  p_data_mandato_a date,
  p_data_trasm_da date,
  p_data_trasm_a date,
  p_tipo_ritenuta varchar,
  p_data_quietanza_da date,
  p_data_quietanza_a date
)
RETURNS TABLE (
  nome_ente varchar,
  partita_iva_ente varchar,
  anno_ese_finanz integer,
  anno_mandato integer,
  numero_mandato integer,
  data_mandato date,
  desc_mandato varchar,
  benef_codice varchar,
  benef_cod_fiscale varchar,
  benef_partita_iva varchar,
  benef_nome varchar,
  stato_mandato varchar,
  importo_lordo_mandato numeric,
  tipo_ritenuta_irpef varchar,
  codice_tributo_irpef varchar,
  importo_ritenuta_irpef numeric,
  importo_netto_irpef numeric,
  importo_imponibile_irpef numeric,
  codice_risc varchar,
  tipo_ritenuta_inps varchar,
  codice_tributo_inps varchar,
  importo_ritenuta_inps numeric,
  importo_netto_inps numeric,
  importo_imponibile_inps numeric,
  importo_ente_inps numeric,
  tipo_ritenuta_irap varchar,
  importo_ritenuta_irap numeric,
  importo_netto_irap numeric,
  importo_imponibile_irap numeric,
  codice_ritenuta_irap varchar,
  desc_ritenuta_irap varchar,
  importo_ente_irap numeric,
  display_error varchar,
  tipo_ritenuta_irpeg varchar,
  codice_tributo_irpeg varchar,
  importo_ritenuta_irpeg numeric,
  importo_netto_irpeg numeric,
  importo_imponibile_irpeg numeric,
  codice_ritenuta_irpeg varchar,
  desc_ritenuta_irpeg varchar,
  importo_ente_irpeg numeric,
  code_caus_770 varchar,
  desc_caus_770 varchar,
  code_caus_esenz varchar,
  desc_caus_esenz varchar,
  attivita_inizio date,
  attivita_fine date,
  attivita_code varchar,
  attivita_desc varchar
) AS
$body$
DECLARE
elencoMandati record;
elencoOneri	record;
elencoReversali record;


DEF_NULL	constant varchar:=''; 
RTN_MESSAGGIO varchar(1000):=DEF_NULL;
importoSubDoc NUMERIC;
imponibileInpsApp NUMERIC;
impostaInpsApp	NUMERIC;
enteInpsApp NUMERIC;
imponibileIrpefApp NUMERIC;
impostaIrpefApp	NUMERIC;
imponibileIrapApp NUMERIC;
impostaIrapApp	NUMERIC;
contaQuotaIrap integer;
importoParzIrapImpon NUMERIC;
importoParzIrapNetto NUMERIC;
importoParzIrapRiten NUMERIC;
importoParzIrapEnte NUMERIC;

contaQuotaIrpef integer;
importoParzIrpefImpon NUMERIC;
importoParzIrpefNetto NUMERIC;
importoParzIrpefRiten NUMERIC;
importoParzIrpefEnte NUMERIC;
importoTotDaDedurreFattura NUMERIC;
importTotaleFattura NUMERIC;

percQuota NUMERIC;
idFatturaOld INTEGER;
numeroQuoteFattura INTEGER;
numeroParametriData Integer;
docIdApp integer;

ente_denominazione VARCHAR;
cod_fisc_ente VARCHAR;
bilancio_id  INTEGER;
miaQuery VARCHAR;

BEGIN

nome_ente='';
partita_iva_ente='';
anno_ese_finanz=0;
anno_mandato=0;
numero_mandato=0;
data_mandato=NULL;
desc_mandato='';
benef_cod_fiscale='';
benef_partita_iva='';
benef_nome='';
stato_mandato='';

codice_risc='';
importo_lordo_mandato=0;
importo_netto_irpef=0;
importo_imponibile_irpef=0;
importo_ritenuta_irpef=0;
importo_netto_inps=0;
importo_imponibile_inps=0;
importo_ritenuta_inps=0;
importo_netto_irap=0;
importo_imponibile_irap=0;
importo_ritenuta_irap=0;

tipo_ritenuta_inps='';
tipo_ritenuta_irpef='';
tipo_ritenuta_irap='';

codice_tributo_irpef='';
codice_tributo_inps='';

codice_ritenuta_irap='';
desc_ritenuta_irap='';
benef_codice='';
importo_ente_irap=0;
importo_ente_inps=0;
code_caus_770:='';
desc_caus_770:='';
code_caus_esenz:='';
desc_caus_esenz:='';
attivita_inizio:=NULL;
attivita_fine:=NULL;
attivita_code:='';
attivita_desc:='';

tipo_ritenuta_irpeg='';
codice_tributo_irpeg='';
importo_ritenuta_irpeg=0;
importo_netto_irpeg=0;
importo_imponibile_irpeg=0;
codice_ritenuta_irpeg='';
desc_ritenuta_irpeg='';
importo_ente_irpeg=0;
numeroParametriData=0;


display_error='';

/* 01/08/2018 SIAC-6306.
	Funzione creata per la gestione dell'aliquota IRPEF.

*/

	select a.ente_denominazione, a.codice_fiscale
into  ente_denominazione, cod_fisc_ente
from  siac_t_ente_proprietario a
where a.ente_proprietario_id = p_ente_prop_id;
    
select a.bil_id 
into bilancio_id 
from siac_t_bil a,siac_t_periodo b
where a.ente_proprietario_id = p_ente_prop_id 
and b.periodo_id = a.periodo_id
and b.anno = p_anno;

/* 07/09/2017: rivista la modalita' di estrazione dei dati INPS e IRPEG per velocizzare 
    la procedura.
    In particolare e' stata creata la function fnc_bilr104_tab_reversali per estrarre
    tutte le reversali per mandato in modo da estrarre tutte le informazioni in un
    colpo solo senza dover cercare le reversali nel ciclo per ogni mandato. 
    Corretto anche un problema relativo ai casi in cui un mandato ha piu' reversali 
    collegate, fatto in modo di sommare gli importi IMPONIBILE, ENTE e RITENUTA ma
    solo se la reversale collegata ha un onere del tipo richiesto (INPS o IRPEG). */

miaQuery ='
with ordinativo as (
    select t_ordinativo.ord_anno,
           t_ordinativo.ord_desc, 
           t_ordinativo.ord_numero,
           t_ordinativo.ord_emissione_data,        
           t_ord_ts_det.ord_ts_det_importo,
           d_ord_stato.ord_stato_code,
           t_ordinativo.ord_id,
           t_ord_ts_det.ord_ts_id
    from  siac_t_ordinativo t_ordinativo,
          siac_t_ordinativo_ts t_ord_ts,
          siac_t_ordinativo_ts_det t_ord_ts_det,
          siac_d_ordinativo_ts_det_tipo d_ts_det_tipo,
          siac_r_ordinativo_stato r_ord_stato,
          siac_d_ordinativo_stato d_ord_stato,
          siac_d_ordinativo_tipo  d_ord_tipo
    where t_ordinativo.ente_proprietario_id = ' ||p_ente_prop_id||'
    and   t_ordinativo.bil_id =  '||bilancio_id ||'    
    and   d_ts_det_tipo.ord_ts_det_tipo_code = ''A''            
    and   d_ord_stato.ord_stato_code <> ''A''
    and   d_ord_tipo.ord_tipo_code = ''P''
    and   r_ord_stato.validita_fine is null 
    and   t_ordinativo.ord_id = t_ord_ts.ord_id
    and   t_ord_ts.ord_ts_id = t_ord_ts_det.ord_ts_id
    and   t_ord_ts_det.ord_ts_det_tipo_id = d_ts_det_tipo.ord_ts_det_tipo_id
    and   t_ordinativo.ord_id = r_ord_stato.ord_id
    and   r_ord_stato.ord_stato_id = d_ord_stato.ord_stato_id
    and   t_ordinativo.ord_tipo_id = d_ord_tipo.ord_tipo_id ';
	if p_data_mandato_da is not null and p_data_mandato_a is not null THEN
		miaQuery=miaQuery||' and to_timestamp(to_char(t_ordinativo.ord_emissione_data,''dd/MM/yyyy''),''dd/MM/yyyy'') between '''||p_data_mandato_da ||''' and '''||p_data_mandato_a||'''';
	elsif p_data_trasm_da is not null and p_data_trasm_a is not null THEN 
		miaQuery=miaQuery||' and to_timestamp(to_char(t_ordinativo.ord_trasm_oil_data,''dd/MM/yyyy''),''dd/MM/yyyy'') between '''||p_data_trasm_da || ''' and '''||p_data_trasm_a||'''';
	end if;
    
    miaQuery=miaQuery||' 
    and   t_ordinativo.data_cancellazione is null
    and   t_ord_ts.data_cancellazione is null
    and   t_ord_ts_det.data_cancellazione is null
    and   d_ts_det_tipo.data_cancellazione is null
    and   r_ord_stato.data_cancellazione is null
    and   d_ord_stato.data_cancellazione is null
    and   d_ord_tipo.data_cancellazione is null
    )
    , capitolo as (
    select t_bil_elem.elem_code, 
           t_bil_elem.elem_code2,
           r_ordinativo_bil_elem.ord_id,
           t_bil_elem.elem_id       
    from   siac_r_ordinativo_bil_elem r_ordinativo_bil_elem, 
           siac_t_bil_elem t_bil_elem
    where  r_ordinativo_bil_elem.elem_id = t_bil_elem.elem_id
    and    r_ordinativo_bil_elem.ente_proprietario_id = '||p_ente_prop_id||'
    and    r_ordinativo_bil_elem.data_cancellazione is null
    and    t_bil_elem.data_cancellazione is null     
    )
    , movimento as (
    select distinct t_movgest.movgest_anno,
           r_liq_ord.sord_id
    from  siac_r_liquidazione_ord r_liq_ord,
          siac_r_liquidazione_movgest r_liq_movgest,
          siac_t_movgest t_movgest,
          siac_t_movgest_ts t_movgest_ts
    where r_liq_ord.liq_id = r_liq_movgest.liq_id
    and   r_liq_movgest.movgest_ts_id = t_movgest_ts.movgest_ts_id
    and   t_movgest_ts.movgest_id = t_movgest.movgest_id
    and   t_movgest.ente_proprietario_id = '||p_ente_prop_id||'
    and   r_liq_ord.data_cancellazione is null
    and   r_liq_movgest.data_cancellazione is null
    and   t_movgest.data_cancellazione is null
    and   t_movgest_ts.data_cancellazione is null
    )
    , soggetto as (
    select t_soggetto.soggetto_code, 
           t_soggetto.soggetto_desc,  
           t_soggetto.partita_iva,
           t_soggetto.codice_fiscale,
           r_ord_soggetto.ord_id
    from   siac_r_ordinativo_soggetto r_ord_soggetto,
           siac_t_soggetto t_soggetto
    where  r_ord_soggetto.soggetto_id = t_soggetto.soggetto_id
    and    t_soggetto.ente_proprietario_id = '||p_ente_prop_id||'
    and    r_ord_soggetto.data_cancellazione is null  
    and    t_soggetto.data_cancellazione is null
    )
    , reversali as (select * from "fnc_bilr104_tab_reversali"('||p_ente_prop_id||','''||p_tipo_ritenuta||''',true))
    select '''||ente_denominazione||''' ente_denominazione, '''||
           cod_fisc_ente||''' cod_fisc_ente, '''||
           p_anno||''' anno_eser,
           ordinativo.ord_anno,
           ordinativo.ord_desc, 
           ordinativo.ord_numero,
           ordinativo.ord_emissione_data,        
           -- ordinativo.ord_ts_det_importo,
           SUM(ordinativo.ord_ts_det_importo) IMPORTO_TOTALE,
           ordinativo.ord_stato_code,
           ordinativo.ord_id,
           capitolo.elem_code cod_cap, 
           capitolo.elem_code2 cod_art,
           capitolo.elem_id,
           movimento.movgest_anno anno_impegno,
           soggetto.soggetto_code, 
           soggetto.soggetto_desc,  
           soggetto.partita_iva,
           soggetto.codice_fiscale,
           reversali.*
    from  ordinativo         
    inner join capitolo  on ordinativo.ord_id = capitolo.ord_id
    inner join movimento on ordinativo.ord_ts_id = movimento.sord_id
    inner join soggetto  on ordinativo.ord_id = soggetto.ord_id
    inner join reversali  on ordinativo.ord_id = reversali.ord_id
    left  join siac_r_ordinativo_quietanza r_ord_quietanza  
    	ON (ordinativo.ord_id = r_ord_quietanza.ord_id 
            and r_ord_quietanza.data_cancellazione is null 
            -- 10/10/2017: aggiunto test sulla data di fine validita'' 
            -- per prendere la quietanza corretta.
            and r_ord_quietanza.validita_fine is null )
	where reversali.onere_tipo_code='''||p_tipo_ritenuta||'''';
    if p_data_quietanza_da is not null and p_data_quietanza_a is not null THEN
		miaQuery=miaQuery||' 
		and to_timestamp(to_char(r_ord_quietanza.ord_quietanza_data,''dd/MM/yyyy''),''dd/MM/yyyy'') 
        	between ''' ||p_data_quietanza_da ||''' and ''' ||p_data_quietanza_a||'''';
    end if;
	miaQuery=miaQuery||' 
    group by ente_denominazione, cod_fisc_ente, anno_eser,
             ordinativo.ord_anno,
             ordinativo.ord_desc, 
             ordinativo.ord_numero,
             ordinativo.ord_emissione_data,
             ordinativo.ord_stato_code,
             ordinativo.ord_id,
             capitolo.elem_code, 
             capitolo.elem_code2,
             capitolo.elem_id,  
             movimento.movgest_anno,
             soggetto.soggetto_code, 
             soggetto.soggetto_desc,  
             soggetto.partita_iva,
             soggetto.codice_fiscale,
             reversali.ord_id,      
             reversali.conta_reversali,  
             reversali.codice_risc,  
             reversali.onere_code,  
             reversali.onere_tipo_code,  
             reversali.importo_imponibile,  
             reversali.importo_ente,  
             reversali.importo_imposta,  
             reversali.importo_ritenuta,  
             --reversali.importo_netto,  
             reversali.importo_reversale,  
             reversali.importo_ord,  
             reversali.attivita_inizio,  
             reversali.attivita_fine,  
             reversali.attivita_code,  
             reversali.attivita_desc,
             reversali.code_caus_770,
			 reversali.desc_caus_770,
			 reversali.code_caus_esenz,
			 reversali.desc_caus_esenz,
             reversali.stato_reversale ,
             reversali.num_reversale  
    order by ordinativo.ord_numero, ordinativo.ord_emissione_data ';
raise notice 'miaQuery = %', miaQuery;


for 
  elencoMandati in execute miaQuery    
          
loop

    importo_lordo_mandato= COALESCE(elencoMandati.IMPORTO_TOTALE,0);

    codice_risc:=elencoMandati.codice_risc;
    if upper(elencoMandati.onere_tipo_code) = 'INPS' THEN
      codice_tributo_inps=COALESCE(elencoMandati.onere_code,'');
      tipo_ritenuta_inps=upper(elencoMandati.onere_tipo_code);        
      importo_imponibile_inps = elencoMandati.importo_imponibile;
      --raise notice 'ord_id = % - IMPON = %', elencoMandati.ord_id, elencoMandati.importo_imponibile;
      importo_ente_inps=elencoMandati.importo_ente;                   
      importo_ritenuta_inps = elencoMandati.importo_ord;    
      importo_netto_inps=importo_lordo_mandato-elencoMandati.importo_ritenuta;-- elencoMandati.importo_netto;-- importo_lordo_mandato-importo_ritenuta_inps;
      attivita_inizio:=elencoMandati.attivita_inizio;
      attivita_fine:=elencoMandati.attivita_fine;
      attivita_code:=elencoMandati.attivita_code;
      attivita_desc:=elencoMandati.attivita_desc;
    elsif upper(elencoMandati.onere_tipo_code) = 'IRPEG' THEN

      codice_tributo_irpeg=COALESCE(elencoMandati.onere_code,'');
      tipo_ritenuta_irpeg=upper(elencoMandati.onere_tipo_code);    		
      importo_imponibile_irpeg = elencoMandati.importo_imponibile;
      importo_ritenuta_irpeg = elencoMandati.importo_ord;    
                                        
      importo_netto_irpeg=importo_lordo_mandato-elencoMandati.importo_ritenuta;  
      code_caus_770:=COALESCE(elencoMandati.code_caus_770,'');
      desc_caus_770:=COALESCE(elencoMandati.desc_caus_770,'');
      code_caus_esenz:=COALESCE(elencoMandati.code_caus_esenz,'');
      desc_caus_esenz:=COALESCE(elencoMandati.desc_caus_esenz,'');
    end if; 
      
      /* 07/09/2017: restituisco solo i dati relativi alla ritenuta richiesta */
     if (p_tipo_ritenuta='INPS' AND tipo_ritenuta_inps <> '') OR
             (p_tipo_ritenuta='IRPEG' AND tipo_ritenuta_irpeg <> '') THEN
          stato_mandato= elencoMandati.ord_stato_code;

          nome_ente=elencoMandati.ente_denominazione;
          partita_iva_ente=elencoMandati.cod_fisc_ente;
          anno_ese_finanz=elencoMandati.anno_eser;
          desc_mandato=COALESCE(elencoMandati.ord_desc,'');

          anno_mandato=elencoMandati.ord_anno;
          numero_mandato=elencoMandati.ord_numero;
          data_mandato=elencoMandati.ord_emissione_data;
          benef_cod_fiscale=COALESCE(elencoMandati.codice_fiscale,'');
          benef_partita_iva=COALESCE(elencoMandati.partita_iva,'');
          benef_nome=COALESCE(elencoMandati.soggetto_desc,'');
          benef_codice=COALESCE(elencoMandati.soggetto_code,'');
            
          return next;
       end if;
     
  nome_ente='';
  partita_iva_ente='';
  anno_ese_finanz=0;
  anno_mandato=0;
  numero_mandato=0;
  data_mandato=NULL;
  desc_mandato='';
  benef_cod_fiscale='';
  benef_partita_iva='';
  benef_nome='';
  stato_mandato='';
  codice_tributo_irpef='';
  codice_tributo_inps='';
  codice_risc='';
  importo_lordo_mandato=0;
  importo_netto_irpef=0;
  importo_imponibile_irpef=0;
  importo_ritenuta_irpef=0;
  importo_netto_inps=0;
  importo_imponibile_inps=0;
  importo_ritenuta_inps=0;
  importo_netto_irap=0;
  importo_imponibile_irap=0;
  importo_ritenuta_irap=0;
  tipo_ritenuta_inps='';
  tipo_ritenuta_irpef='';
  tipo_ritenuta_irap='';
  codice_ritenuta_irap='';
  desc_ritenuta_irap='';
  benef_codice='';
  importo_ente_irap=0;
  importo_ente_inps=0;

  tipo_ritenuta_irpeg='';
  codice_tributo_irpeg='';
  importo_ritenuta_irpeg=0;
  importo_netto_irpeg=0;
  importo_imponibile_irpeg=0;
  codice_ritenuta_irpeg='';
  desc_ritenuta_irpeg='';
  importo_ente_irpeg=0;
  code_caus_770:='';
  desc_caus_770:='';
  code_caus_esenz:='';
  desc_caus_esenz:='';
  attivita_inizio:=NULL;
  attivita_fine:=NULL;
  attivita_code:='';
  attivita_desc:='';
  
end loop;  
   
raise notice 'ora: % ',clock_timestamp()::varchar;
raise notice 'fine estrazione dei dati e preparazione dati in output ';  

exception
	when no_data_found THEN
		raise notice 'nessun mandato trovato per % ', p_tipo_ritenuta ;
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