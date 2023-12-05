/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
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