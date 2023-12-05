/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
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