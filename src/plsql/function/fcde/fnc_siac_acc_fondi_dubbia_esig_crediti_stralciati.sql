/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI PIEMONTE
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac.fnc_siac_acc_fondi_dubbia_esig_crediti_stralciati (
  p_afde_bil_id integer
)
RETURNS TABLE (
  versione integer,
  fase_attributi_bilancio varchar,
  stato_attributi_bilancio varchar,
  data_ora_elaborazione timestamp,
  anni_esercizio varchar,
  riscossione_virtuosa boolean,
  quinquennio_riferimento varchar,
  accantonamento_graduale numeric,
  elem_code varchar,
  elem_code2 varchar,
  elem_code3 varchar,
  movgest_anno integer,
  movgest_numero numeric,
  movgest_desc varchar,
  pdc varchar,
  soggetto_desc_movgest varchar,
  soggetto_classe_movgest varchar,
  atto_amm_anno_movgest varchar,
  atto_amm_numero_movgest integer,
  atto_amm_tipo_movgest varchar,
  atto_amm_sac_movgest varchar,
  mod_desc varchar,
  mod_tipo varchar,
  movgest_ts_det_importo_mod numeric,
  atto_amm_anno_mod varchar,
  atto_amm_numero_mod integer,
  atto_amm_tipo_mod varchar,
  atto_amm_sac_mod varchar
) AS
$body$
DECLARE
	v_ente_proprietario_id     INTEGER;
	v_anno_esercizio		   VARCHAR;
	v_bilancio_id			   INTEGER;
	v_acc_fde_id               INTEGER;
	v_loop_var                 RECORD;
	v_componente_cento		   NUMERIC := 100;
BEGIN

/*
 29/08/2022. SIAC-8777.
 Procedura nata per l'export in Excel dei dati di dettaglio relativi ai 
 Crediti Stralciati.
 Procedura lanciata da Contabilia FCDE - Rendiconto.

*/

	--calcolo dei dati di intestazione
	SELECT
		  siac_t_acc_fondi_dubbia_esig_bil.ente_proprietario_id
		, siac_t_acc_fondi_dubbia_esig_bil.afde_bil_versione
		, now()
		, siac_d_acc_fondi_dubbia_esig_tipo.afde_tipo_desc
		, siac_d_acc_fondi_dubbia_esig_stato.afde_stato_desc
		, siac_t_periodo.anno || '-' || (siac_t_periodo.anno::INTEGER + 2)
		, siac_t_acc_fondi_dubbia_esig_bil.afde_bil_riscossione_virtuosa
		, (siac_t_acc_fondi_dubbia_esig_bil.afde_bil_quinquennio_riferimento - 4) || '-' || siac_t_acc_fondi_dubbia_esig_bil.afde_bil_quinquennio_riferimento quinquennio_riferimento
		, COALESCE(siac_t_acc_fondi_dubbia_esig_bil.afde_bil_accantonamento_graduale, 100) accantonamento_graduale
        , siac_t_periodo.anno
        , siac_t_bil.bil_id        
	INTO
		  v_ente_proprietario_id
		, versione
		, data_ora_elaborazione
		, fase_attributi_bilancio
		, stato_attributi_bilancio
		, anni_esercizio
		, riscossione_virtuosa
		, quinquennio_riferimento
		, accantonamento_graduale
        , v_anno_esercizio
        , v_bilancio_id
	FROM siac_t_acc_fondi_dubbia_esig_bil
	JOIN siac_d_acc_fondi_dubbia_esig_stato ON (siac_d_acc_fondi_dubbia_esig_stato.afde_stato_id = siac_t_acc_fondi_dubbia_esig_bil.afde_stato_id AND siac_d_acc_fondi_dubbia_esig_stato.data_cancellazione IS NULL)
	JOIN siac_d_acc_fondi_dubbia_esig_tipo ON (siac_d_acc_fondi_dubbia_esig_tipo.afde_tipo_id = siac_t_acc_fondi_dubbia_esig_bil.afde_tipo_id AND siac_d_acc_fondi_dubbia_esig_tipo.data_cancellazione IS NULL)
	JOIN siac_t_bil ON (siac_t_bil.bil_id = siac_t_acc_fondi_dubbia_esig_bil.bil_id AND siac_t_bil.data_cancellazione IS NULL)
	JOIN siac_t_periodo ON (siac_t_periodo.periodo_id = siac_t_bil.periodo_id AND siac_t_periodo.data_cancellazione IS NULL)
	WHERE siac_t_acc_fondi_dubbia_esig_bil.afde_bil_id = p_afde_bil_id;
    
return query
with struttura as (select *
 from "fnc_bilr_struttura_cap_bilancio_entrate"(v_ente_proprietario_id, v_anno_esercizio,'')),
capitoli as (
	   select capitolo.elem_code, 
         capitolo.elem_code2, 
         capitolo.elem_code3,
         class.classif_id categoria_id,
         r_mov_capitolo.movgest_id
       from  siac_t_bil_elem     capitolo , 
          siac_r_movgest_bil_elem   r_mov_capitolo, 
          siac_d_bil_elem_tipo    t_capitolo,
          siac_t_class class,	
          siac_d_class_tipo d_class_tipo,
          siac_r_bil_elem_class r_bil_elem_class  
       where r_mov_capitolo.elem_id    		=	capitolo.elem_id
       		and capitolo.elem_tipo_id      	= 	t_capitolo.elem_tipo_id
            and class.classif_id           = r_bil_elem_class.classif_id
	  		and d_class_tipo.classif_tipo_id      = class.classif_tipo_id
      		and r_bil_elem_class.elem_id   = capitolo.elem_id
            and capitolo.ente_proprietario_id = v_ente_proprietario_id
            and capitolo.bil_id = v_bilancio_id
            and t_capitolo.elem_tipo_code    		= 	'CAP-EG' 
            and d_class_tipo.classif_tipo_code	 = 'CATEGORIA'   
            and now() between r_mov_capitolo.validita_inizio and COALESCE(r_mov_capitolo.validita_fine,now())
            and capitolo.data_cancellazione     	is null 
            and r_mov_capitolo.data_cancellazione is null 
            and t_capitolo.data_cancellazione    	is null 
            and class.data_cancellazione    is null  
            and d_class_tipo.data_cancellazione is null  
            and r_bil_elem_class.data_cancellazione is null),
dati_crediti as (
	   select 
       movimento.movgest_anno, 
       movimento.movgest_numero, 
       movimento.movgest_desc,
       pdc_mov.classif_code, 
       COALESCE(soggetto.soggetto_desc, '') soggetto_desc,
       COALESCE(classe_soggetto.soggetto_classe_desc, '') soggetto_classe_desc,
       atti.attoamm_anno, 
       atti.attoamm_numero,
       atti.tipo_atto_completo, 
       sac_atto.sac_atto_completa,
       t_modifica.mod_desc, 
       (d_modif_tipo.mod_tipo_code || ' - ' || d_modif_tipo.mod_tipo_desc)::varchar mod_tipo,
       COALESCE(abs(t_movgest_ts_det_mod.movgest_ts_det_importo),0) ::numeric movgest_ts_det_importo_mod,
       atto_mod.attoamm_anno atto_amm_anno_mod, 
       atto_mod.attoamm_numero atto_amm_numero_mod,
       tipo_atto_mod.attoamm_tipo_code || ' - ' ||tipo_atto_mod.attoamm_tipo_desc atto_amm_tipo_mod,
       sac_atto_mod.sac_atto_mod_completa atto_amm_sac_mod ,
       movimento.movgest_id      
      from siac_t_movgest     movimento, 
        siac_d_movgest_tipo    tipo_mov, 
        siac_t_movgest_ts    ts_movimento
        	left join (select r_mov_class.movgest_ts_id,
            			class_pdc.classif_code, class_pdc.classif_desc,
                        class_pdc.classif_code|| ' - ' || class_pdc.classif_desc pdc_completa
            		   from siac_r_movgest_class r_mov_class,
                            siac_d_class_tipo d_class_tipo_pdc,
                            siac_t_class class_pdc
                       where  class_pdc.classif_id=r_mov_class.classif_id
      					and class_pdc.classif_tipo_id=d_class_tipo_pdc.classif_tipo_id
                        and r_mov_class.ente_proprietario_id=v_ente_proprietario_id
                        and d_class_tipo_pdc.classif_tipo_code like 'PDC%'
                        and r_mov_class.data_cancellazione is null ) pdc_mov
      			on pdc_mov.movgest_ts_id=ts_movimento.movgest_ts_id
        	left join (select r_mov_ts_sog.movgest_ts_id, sogg.soggetto_code,
            				sogg.soggetto_desc
            		   from siac_r_movgest_ts_sog r_mov_ts_sog,
        					siac_t_soggetto sogg
                       where  r_mov_ts_sog.soggetto_id=sogg.soggetto_id 
                       			and r_mov_ts_sog.ente_proprietario_id=v_ente_proprietario_id
                       			and r_mov_ts_sog.data_cancellazione is null
                                and sogg.data_cancellazione is null) soggetto
				on soggetto.movgest_ts_id = ts_movimento.movgest_ts_id 
        	left join (select r_mov_ts_classesog.movgest_ts_id, classe_sogg.soggetto_classe_code,
            				classe_sogg.soggetto_classe_desc
            		   from siac_r_movgest_ts_sogclasse r_mov_ts_classesog,
        					siac_d_soggetto_classe classe_sogg
                       where  r_mov_ts_classesog.soggetto_classe_id=classe_sogg.soggetto_classe_id 
                       			and r_mov_ts_classesog.ente_proprietario_id=v_ente_proprietario_id
                       			and r_mov_ts_classesog.data_cancellazione is null
                                and classe_sogg.data_cancellazione is null) classe_soggetto
				on classe_soggetto.movgest_ts_id = ts_movimento.movgest_ts_id                              
        	left join (select r_mov_atto.movgest_ts_id, atto.attoamm_id,
            			atto.attoamm_anno,
            			atto.attoamm_numero, tipo_atto.attoamm_tipo_code,
                        tipo_atto.attoamm_tipo_desc,
                        tipo_atto.attoamm_tipo_code || ' - ' || tipo_atto.attoamm_tipo_desc tipo_atto_completo
            		   from siac_r_movgest_ts_atto_amm r_mov_atto,
        					siac_t_atto_amm atto,
                            siac_d_atto_amm_tipo tipo_atto
                       where  r_mov_atto.attoamm_id=atto.attoamm_id 
                       			and atto.attoamm_tipo_id=tipo_atto.attoamm_tipo_id
                       			and r_mov_atto.ente_proprietario_id=v_ente_proprietario_id
                       			and r_mov_atto.data_cancellazione is null
                                and atto.data_cancellazione is null) atti
				on atti.movgest_ts_id = ts_movimento.movgest_ts_id
			left join (select r_atto_class.attoamm_id,
            			class_pdc.classif_code, class_pdc.classif_desc,
                        class_pdc.classif_code|| ' - ' || class_pdc.classif_desc sac_atto_completa
            		   from siac_r_atto_amm_class r_atto_class,
                            siac_d_class_tipo d_class_tipo_pdc,
                            siac_t_class class_pdc
                       where  class_pdc.classif_id=r_atto_class.classif_id
      					and class_pdc.classif_tipo_id=d_class_tipo_pdc.classif_tipo_id
                        and r_atto_class.ente_proprietario_id=v_ente_proprietario_id
                        and d_class_tipo_pdc.classif_tipo_code in ('CDR','CDC')
                        and r_atto_class.data_cancellazione is null ) sac_atto
      			on sac_atto.attoamm_id=atti.attoamm_id,                                  
        siac_r_movgest_ts_stato   r_movimento_stato, 
        siac_d_movgest_stato    tipo_stato, 
        siac_t_movgest_ts_det   dt_movimento, 
        siac_d_movgest_ts_tipo   ts_mov_tipo, 
        siac_d_movgest_ts_det_tipo  dt_mov_tipo ,
        siac_t_modifica t_modifica			                ,
        siac_d_modifica_tipo d_modif_tipo,
        siac_r_modifica_stato r_mod_stato,
        siac_d_modifica_stato d_mod_stato,
        siac_t_movgest_ts_det_mod t_movgest_ts_det_mod,        
        siac_t_atto_amm atto_mod
                left join (select r_atto_class_mod.attoamm_id,
            			class_pdc_mod.classif_code, class_pdc_mod.classif_desc,
                        class_pdc_mod.classif_code|| ' - ' || class_pdc_mod.classif_desc sac_atto_mod_completa
            		   from siac_r_atto_amm_class r_atto_class_mod,
                            siac_d_class_tipo d_class_tipo_pdc_mod,
                            siac_t_class class_pdc_mod
                       where  class_pdc_mod.classif_id=r_atto_class_mod.classif_id
      					and class_pdc_mod.classif_tipo_id=d_class_tipo_pdc_mod.classif_tipo_id
                        and r_atto_class_mod.ente_proprietario_id=v_ente_proprietario_id
                        and d_class_tipo_pdc_mod.classif_tipo_code in ('CDR','CDC')
                        and r_atto_class_mod.data_cancellazione is null ) sac_atto_mod
      			on sac_atto_mod.attoamm_id=atto_mod.attoamm_id,
        siac_d_atto_amm_tipo tipo_atto_mod                           
      where movimento.movgest_tipo_id    	= 	tipo_mov.movgest_tipo_id 
      and movimento.movgest_id      		= 	ts_movimento.movgest_id 
      and ts_movimento.movgest_ts_id    	= 	r_movimento_stato.movgest_ts_id 
      and r_movimento_stato.movgest_stato_id  = tipo_stato.movgest_stato_id 
      and ts_movimento.movgest_ts_tipo_id  = ts_mov_tipo.movgest_ts_tipo_id 
      and ts_movimento.movgest_ts_id    	= dt_movimento.movgest_ts_id 
      and dt_movimento.movgest_ts_det_tipo_id  = dt_mov_tipo.movgest_ts_det_tipo_id
      and t_movgest_ts_det_mod.movgest_ts_id=ts_movimento.movgest_ts_id      
      and t_movgest_ts_det_mod.mod_stato_r_id=r_mod_stato.mod_stato_r_id
      and d_mod_stato.mod_stato_id=r_mod_stato.mod_stato_id  
      and r_mod_stato.mod_id=t_modifica.mod_id
      and d_modif_tipo.mod_tipo_id = t_modifica.mod_tipo_id        
      and t_modifica.attoamm_id= atto_mod.attoamm_id
      and atto_mod.attoamm_tipo_id  =tipo_atto_mod.attoamm_tipo_id      
	  and movimento.ente_proprietario_id   = v_ente_proprietario_id 
      and movimento.bil_id					=	v_bilancio_id       
      	--accertamenti con anno <=anno bilancio
      and movimento.movgest_anno 	        <= 	v_anno_esercizio::integer 
      and tipo_mov.movgest_tipo_code    	= 'A' --accertamenti
      and tipo_stato.movgest_stato_code   in ('D','N') 
      and ts_mov_tipo.movgest_ts_tipo_code  = 'T'
      and dt_mov_tipo.movgest_ts_det_tipo_code = 'A' ----- importo attuale 
      and d_mod_stato.mod_stato_code='V'
      and d_modif_tipo.mod_tipo_code in ('INEROR','INESIG')    
      and t_movgest_ts_det_mod.movgest_ts_det_importo < 0                     
 	  and now() between r_movimento_stato.validita_inizio and COALESCE(r_movimento_stato.validita_fine,now())
	  and now() between r_mod_stato.validita_inizio and COALESCE(r_mod_stato.validita_fine,now())      
      and movimento.data_cancellazione     	is null 
      and tipo_mov.data_cancellazione     	is null 
      and r_movimento_stato.data_cancellazione   is null 
      and ts_movimento.data_cancellazione   is null 
      and tipo_stato.data_cancellazione    	is null 
      and dt_movimento.data_cancellazione   is null 
      and ts_mov_tipo.data_cancellazione    is null 
      and dt_mov_tipo.data_cancellazione    is null
      and t_movgest_ts_det_mod.data_cancellazione    is null
      and r_mod_stato.data_cancellazione    is null
      and t_modifica.data_cancellazione    is null)
select versione::integer, 
	   fase_attributi_bilancio::varchar, 
       stato_attributi_bilancio::varchar,
	   data_ora_elaborazione::timestamp, 
       anni_esercizio::varchar, 
       riscossione_virtuosa,
       quinquennio_riferimento::varchar, 
       accantonamento_graduale::numeric,      
       capitoli.elem_code::varchar, 
       capitoli.elem_code2::varchar, 
       capitoli.elem_code3::varchar,
       dati_crediti.movgest_anno::integer, 
       dati_crediti.movgest_numero::numeric, 
       dati_crediti.movgest_desc::varchar,
       dati_crediti.classif_code::varchar pdc, 
       dati_crediti.soggetto_desc::varchar soggetto_desc_movgest,
       dati_crediti.soggetto_classe_desc::varchar soggetto_classe_movgest,
       dati_crediti.attoamm_anno::varchar atto_amm_anno_movgest, 
       dati_crediti.attoamm_numero::integer atto_amm_numero_movgest,
       dati_crediti.tipo_atto_completo::varchar atto_amm_tipo_movgest, 
       dati_crediti.sac_atto_completa::varchar atto_amm_sac_movgest,
       dati_crediti.mod_desc::varchar, 
       dati_crediti.mod_tipo::varchar mod_tipo,
       dati_crediti.movgest_ts_det_importo_mod::numeric movgest_ts_det_importo_mod,
       dati_crediti.atto_amm_anno_mod::varchar atto_amm_anno_mod, 
       dati_crediti.atto_amm_numero_mod::integer atto_amm_numero_mod,
       dati_crediti.atto_amm_tipo_mod::varchar atto_amm_tipo_mod,
       dati_crediti.atto_amm_sac_mod::varchar atto_amm_sac_mod
from dati_crediti
	left join capitoli
    	on  capitoli.movgest_id = dati_crediti.movgest_id
	left join struttura 
    	on struttura.categoria_id=capitoli.categoria_id 
where struttura.titolo_code::integer between 1 and 5;           
    
    
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
PARALLEL UNSAFE
COST 100 ROWS 1000;

ALTER FUNCTION siac.fnc_siac_acc_fondi_dubbia_esig_crediti_stralciati (p_afde_bil_id integer)
  OWNER TO siac;