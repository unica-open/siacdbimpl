/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac."BILR152_elenco_reversali" (
  p_ente_prop_id integer,
  p_anno varchar,
  p_numero_provv integer,
  p_anno_provv varchar,
  p_tipo_provv varchar,
  p_cdr varchar,
  p_cdc varchar
)
RETURNS TABLE (
  num_reversale varchar,
  anno_reversale integer,
  stato_reversale varchar,
  desc_stato_reversale varchar,
  importo_reversale numeric,
  conto_dare varchar,
  conto_avere varchar,
  num_accertamento numeric,
  anno_accertamento integer,
  num_subaccertamento varchar,
  tipo_accert varchar,
  code_soggetto varchar,
  desc_soggetto varchar,
  categoria varchar,
  ord_ts_id integer,
  display_error varchar
) AS
$body$
DECLARE

DEF_NULL	constant varchar:=''; 
RTN_MESSAGGIO varchar(1000):=DEF_NULL;
anno_eser_int integer;
 
tipo_sac varchar;
var_sac varchar;
estremi_provv varchar;
atto_id integer;

BEGIN


num_reversale:='';
anno_reversale:=0;
stato_reversale:='';
desc_stato_reversale:='';
importo_reversale:=0;
conto_dare:='';
conto_avere:='';
num_accertamento:=0;
anno_accertamento:=0;
num_subaccertamento:='';
tipo_accert:='';
code_soggetto:='';
desc_soggetto:=0;
categoria:=0;
ord_ts_id:=0;

anno_eser_int=p_anno ::INTEGER;

--15/04/2020 SIAC-7498.
-- Introdotte le modifiche per la gestione della SAC (Direzione/Settore) collegata all'atto.
-- La SAC puo' non essere specificata; viene verificata l'esistenza dell'atto indicato in
-- input e nel caso non esista o ne esista piu' di 1 e' restituito un errore.

display_error:='';
estremi_provv:= ' Numero: '|| p_numero_provv|| ' Anno: '||p_anno_provv||' Tipo: '||p_tipo_provv;

if p_cdr IS not null and trim(p_cdr) <> '' and p_cdr <> '999' then
	if p_cdc IS not null and trim(p_cdc) <> '' and p_cdc <> '999' then
    	tipo_sac:= 'CDC';
        var_sac:=p_cdc;
        estremi_provv:=estremi_provv|| ' SAC: '||p_cdc;
    else
    	tipo_sac:= 'CDR';
        var_sac:=p_cdr;
        estremi_provv:=estremi_provv|| ' SAC: '||p_cdr;
    end if;
else
	tipo_sac:= '';
    var_sac:='';
end if;

--specificata la SAC
if tipo_sac <> '' then
  begin
      select t_atto_amm.attoamm_id
          into STRICT  atto_id
      from siac_t_atto_amm t_atto_amm,
          siac_r_atto_amm_class r_atto_amm_class,
          siac_t_class t_class,
          siac_d_class_tipo d_class_tipo,
          siac_d_atto_amm_tipo	tipo_atto
      where t_atto_amm.attoamm_id=r_atto_amm_class.attoamm_id
        and r_atto_amm_class.classif_id=t_class.classif_id
        and t_class.classif_tipo_id=d_class_tipo.classif_tipo_id
        and t_atto_amm.attoamm_tipo_id=tipo_atto.attoamm_tipo_id
        and t_atto_amm.ente_proprietario_id =p_ente_prop_id
        and t_atto_amm.attoamm_anno=p_anno_provv
        and t_atto_amm.attoamm_numero=p_numero_provv
        and tipo_atto.attoamm_tipo_code=p_tipo_provv
        and t_class.classif_code=var_sac
        and t_atto_amm.data_cancellazione IS NULL
        and r_atto_amm_class.data_cancellazione IS NULL
        and t_class.data_cancellazione IS NULL
        and d_class_tipo.data_cancellazione IS NULL
        and tipo_atto.data_cancellazione IS NULL;  
  EXCEPTION        
  WHEN NO_DATA_FOUND THEN
        raise notice 'atto_id = %', atto_id;
            display_error := 'Non esiste un provvedimento '||estremi_provv;
            return next;
            return;         
     WHEN TOO_MANY_ROWS THEN
        raise notice 'atto_id = %', atto_id;
              display_error := 'Esistono  piu'' provvedimenti '||estremi_provv;
              return next;
              return;     
  end;
ELSE
	begin
        select t_atto_amm.attoamm_id
            into STRICT atto_id
        from siac_t_atto_amm t_atto_amm,        
            siac_d_atto_amm_tipo	tipo_atto
        where t_atto_amm.attoamm_tipo_id=tipo_atto.attoamm_tipo_id
          and t_atto_amm.ente_proprietario_id =p_ente_prop_id
          and t_atto_amm.attoamm_anno=p_anno_provv
          and t_atto_amm.attoamm_numero=p_numero_provv
          and tipo_atto.attoamm_tipo_code=p_tipo_provv
          and t_atto_amm.data_cancellazione IS NULL
          and tipo_atto.data_cancellazione IS NULL
        group by t_atto_amm.attoamm_id;
      EXCEPTION        
        WHEN NO_DATA_FOUND THEN
              raise notice 'atto_id = %', atto_id;
                  display_error := 'Non esiste un provvedimento '||estremi_provv;
                  return next;
                  return;         
           WHEN TOO_MANY_ROWS THEN
              raise notice 'atto_id = %', atto_id;
                    display_error := 'Esistono piu'' provvedimenti '||estremi_provv;
                    return next;
                    return;             
    end;
end if;

raise notice 'attoamm_id = %',atto_id;

RTN_MESSAGGIO:='Estrazione dei dati delle reversali ''.';
raise notice 'ora: % ',clock_timestamp()::varchar;
  
return query 
select query_totale.* from  (
with reversali as (    
      select t_ordinativo.ord_id,
      		t_ord_ts.ord_ts_id,
          t_ordinativo.ord_anno,
          t_ordinativo.ord_numero,
          d_ord_stato.ord_stato_code,
          d_ord_stato.ord_stato_desc,
          t_ord_ts_det.ord_ts_det_importo     
       from  
                siac_t_ordinativo t_ordinativo,
                siac_d_ordinativo_tipo d_ordinativo_tipo,              
                siac_t_ordinativo_ts t_ord_ts,
                siac_r_ordinativo_stato r_ord_stato,
                siac_d_ordinativo_stato d_ord_stato,
                siac_r_ordinativo_atto_amm r_ord_atto_amm,
                siac_t_ordinativo_ts_det t_ord_ts_det, 
               siac_d_ordinativo_ts_det_tipo ts_det_tipo,
               siac_t_atto_amm t_atto_amm  ,
               siac_d_atto_amm_tipo	tipo_atto  
      where t_ordinativo.ord_tipo_id=   d_ordinativo_tipo.ord_tipo_id
          and t_ordinativo.ord_id= t_ord_ts.ord_id
          AND r_ord_atto_amm.ord_id=t_ordinativo.ord_id
          AND d_ord_stato.ord_stato_id=r_ord_stato.ord_stato_id
          AND r_ord_stato.ord_id=t_ordinativo.ord_id
          and t_ord_ts_det.ord_ts_id= t_ord_ts.ord_ts_id  
          and ts_det_tipo.ord_ts_det_tipo_id=  t_ord_ts_det.ord_ts_det_tipo_id
          AND t_atto_amm.attoamm_id=r_ord_atto_amm.attoamm_id
          AND t_atto_amm.attoamm_tipo_id=tipo_atto.attoamm_tipo_id
          AND t_ordinativo.ente_proprietario_id=p_ente_prop_id
          and t_atto_amm.attoamm_id = atto_id
          --AND t_atto_amm.attoamm_numero=p_numero_provv
          --AND t_atto_amm.attoamm_anno=p_anno_provv
          --AND tipo_atto.attoamm_tipo_code=p_tipo_provv
           AND d_ordinativo_tipo.ord_tipo_code ='I' --Incasso
           AND ts_det_tipo.ord_ts_det_tipo_code='A' --importo Attuale
           AND d_ord_stato.ord_stato_code <>'A' --Annullato
           AND r_ord_stato.validita_fine IS NULL  --Stato ancora valido
           AND t_ordinativo.data_cancellazione IS NULL
           AND d_ordinativo_tipo.data_cancellazione IS NULL 
           AND t_ord_ts.data_cancellazione IS NULL
           AND r_ord_stato.data_cancellazione IS NULL
           AND d_ord_stato.data_cancellazione IS NULL
           AND t_ord_ts_det.data_cancellazione IS NULL
           AND ts_det_tipo.data_cancellazione IS NULL
           AND r_ord_atto_amm.data_cancellazione IS NULL
           AND t_atto_amm.data_cancellazione IS NULL
           AND tipo_atto.data_cancellazione IS NULL)  ,
 accert as (
		SELECT t_movgest.movgest_id, t_movgest_ts.movgest_ts_id,
        		r_ord_ts_movgest_ts.ord_ts_id,
        		t_movgest.movgest_anno, 
      			t_movgest.movgest_numero,
            	t_movgest_ts.movgest_ts_code,
                 d_movgest_ts_tipo.movgest_ts_tipo_code,
                t_movgest_ts_det.movgest_ts_det_importo
            FROM siac_t_movgest t_movgest,
            	siac_t_bil t_bil,
                siac_t_periodo t_periodo,
            	siac_t_movgest_ts t_movgest_ts,    
                siac_d_movgest_tipo d_movgest_tipo,            
                siac_t_movgest_ts_det t_movgest_ts_det,
                siac_d_movgest_ts_det_tipo d_movgest_ts_det_tipo,
                siac_d_movgest_ts_tipo d_movgest_ts_tipo,
                siac_r_movgest_ts_stato r_movgest_ts_stato,
                siac_d_movgest_stato d_movgest_stato,
                siac_r_ordinativo_ts_movgest_ts r_ord_ts_movgest_ts 
          	WHERE t_movgest.movgest_id=t_movgest_ts.movgest_id    
            	AND t_bil.bil_id= t_movgest.bil_id   
                AND t_periodo.periodo_id=t_bil.periodo_id    
            	AND d_movgest_tipo.movgest_tipo_id=t_movgest.movgest_tipo_id 
                 AND r_movgest_ts_stato.movgest_ts_id=t_movgest_ts.movgest_ts_id     
               AND r_movgest_ts_stato.movgest_stato_id=d_movgest_stato.movgest_stato_id   	
               AND t_movgest_ts_det.movgest_ts_id=t_movgest_ts.movgest_ts_id
               AND d_movgest_ts_det_tipo.movgest_ts_det_tipo_id=t_movgest_ts_det.movgest_ts_det_tipo_id
                AND d_movgest_ts_tipo.movgest_ts_tipo_id=t_movgest_ts.movgest_ts_tipo_id
                AND r_ord_ts_movgest_ts.movgest_ts_id=t_movgest_ts.movgest_ts_id
                AND t_movgest.ente_proprietario_id=p_ente_prop_id
                AND t_periodo.anno =p_anno
                AND d_movgest_tipo.movgest_tipo_code='A'    --accertamento  
                AND d_movgest_ts_det_tipo.movgest_ts_det_tipo_code='A' -- importo attuale 
                AND d_movgest_stato.movgest_stato_code<>'A' -- non gli annullati
                AND  t_movgest_ts.data_cancellazione IS NULL
                AND  t_movgest.data_cancellazione IS NULL   
                AND t_bil.data_cancellazione IS NULL 
                AND t_periodo.data_cancellazione IS NULL
                AND  d_movgest_tipo.data_cancellazione IS NULL            
                AND t_movgest_ts_det.data_cancellazione IS NULL
                AND d_movgest_ts_det_tipo.data_cancellazione IS NULL
                AND d_movgest_ts_tipo.data_cancellazione IS NULL
                AND r_movgest_ts_stato.data_cancellazione IS NULL
                AND d_movgest_stato.data_cancellazione IS NULL
                AND r_ord_ts_movgest_ts.data_cancellazione IS NULL),	
soggetto as (
    		SELECT r_ord_soggetto.ord_id,
                t_soggetto.soggetto_code,
                t_soggetto.soggetto_desc
            FROM siac_r_ordinativo_soggetto r_ord_soggetto,
                siac_t_soggetto t_soggetto
            WHERE r_ord_soggetto.soggetto_id=   t_soggetto.soggetto_id
                and t_soggetto.ente_proprietario_id=p_ente_prop_id
                AND t_soggetto.data_cancellazione IS NULL  
                AND r_ord_soggetto.data_cancellazione IS NULL) ,   
	categ as (
	SELECT  r_ord_class.ord_id,
           COALESCE( t_class.classif_code,'') categ_code, 
            COALESCE(t_class.classif_desc,'') categ_desc 
        from siac_r_ordinativo_class r_ord_class,
            siac_t_class			t_class,
            siac_d_class_tipo		d_class_tipo           
              where t_class.classif_id 					= 	r_ord_class.classif_id
                  and d_class_tipo.classif_tipo_id		=	t_class.classif_tipo_id
                 and upper(d_class_tipo.classif_tipo_code) = 'CATEGORIA'			
                 and r_ord_class.ente_proprietario_id=p_ente_prop_id
                   AND r_ord_class.data_cancellazione is NULL
                   AND t_class.data_cancellazione is NULL
                   AND d_class_tipo.data_cancellazione is NULL  ),                  	              
	conto_integrato as (    	
      select distinct t_ordinativo.ord_id, 
          t_mov_ep_det.movep_det_segno,
          t_pdce_conto.pdce_conto_code
      from siac_r_evento_reg_movfin r_ev_reg_movfin,
          siac_t_ordinativo t_ordinativo,
          siac_d_evento d_evento,
          siac_d_collegamento_tipo d_coll_tipo,
          siac_t_reg_movfin t_reg_movfin,
          siac_t_mov_ep t_mov_ep,
          siac_t_mov_ep_det t_mov_ep_det,
          siac_t_pdce_conto t_pdce_conto
      where t_ordinativo.ord_id=r_ev_reg_movfin.campo_pk_id
          and d_evento.evento_id=r_ev_reg_movfin.evento_id
          and d_coll_tipo.collegamento_tipo_id=d_evento.collegamento_tipo_id
          and t_reg_movfin.regmovfin_id=r_ev_reg_movfin.regmovfin_id
          and t_mov_ep.regmovfin_id=t_reg_movfin.regmovfin_id
          and t_mov_ep_det.movep_id=t_mov_ep.movep_id
          and t_pdce_conto.pdce_conto_id=t_mov_ep_det.pdce_conto_id
          and t_ordinativo.ente_proprietario_id=p_ente_prop_id
          and d_coll_tipo.collegamento_tipo_code='OI'    --Ordinativo di Incasso 
          and r_ev_reg_movfin.data_cancellazione is null
          and t_ordinativo.data_cancellazione is null
          and d_evento.data_cancellazione is null
          and d_coll_tipo.data_cancellazione is null
          and t_reg_movfin.data_cancellazione is null
          and t_mov_ep.data_cancellazione is null
          and t_mov_ep_det.data_cancellazione is null
          and t_pdce_conto.data_cancellazione is null )                                           
SELECT reversali.ord_numero::varchar num_reversale,
	reversali.ord_anno::integer anno_reversale,
	reversali.ord_stato_code::varchar stato_reversale,
	reversali.ord_stato_desc::varchar desc_stato_reversale,
    reversali.ord_ts_det_importo::numeric importo_reversale,
    CASE WHEN COALESCE(upper(conto_integrato.movep_det_segno),'')='DARE'
    	THEN COALESCE(conto_integrato.pdce_conto_code,'')::varchar 
        ELSE ''::varchar end conto_dare,
     CASE WHEN COALESCE(upper(conto_integrato.movep_det_segno),'')='AVERE'
    	THEN COALESCE(conto_integrato.pdce_conto_code,'')::varchar 
        ELSE ''::varchar end conto_avere,
    accert.movgest_numero::numeric num_accertamento,
	accert.movgest_anno::integer anno_accertamento,
	accert.movgest_ts_code::varchar num_subaccertamento,
    accert.movgest_ts_tipo_code::varchar tipo_accert,
    soggetto.soggetto_code::varchar code_soggetto,
	soggetto.soggetto_desc::varchar desc_soggetto,
	COALESCE(categ.categ_code,'')::varchar categoria,
    reversali.ord_ts_id::integer ord_ts_id,
    ''::varchar display_error
FROM reversali
	LEFT JOIN accert on accert.ord_ts_id=reversali.ord_ts_id		
    LEFT JOIN soggetto on soggetto.ord_id=reversali.ord_id
    LEFT JOIN categ on categ.ord_id=reversali.ord_id
    LEFT JOIN conto_integrato on conto_integrato.ord_id = reversali.ord_id     
ORDER BY anno_reversale, num_reversale) query_totale;

RTN_MESSAGGIO:='Estrazione dei dati degli accertamenti ''.';
raise notice 'ora: % ',clock_timestamp()::varchar;



exception
	when no_data_found THEN
		raise notice 'Nessun accertamento trovato' ;
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