/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac."BILR065_mov_cas_econ_non_rend" (
  p_ente_prop_id integer,
  p_anno varchar,
  p_data_da date,
  p_data_a date,
  p_cassaecon_id integer,
  p_num_impegno numeric,
  p_ant_spese_missione varchar
)
RETURNS TABLE (
  descr_ente varchar,
  num_capitolo varchar,
  num_articolo varchar,
  ueb varchar,
  anno_impegno integer,
  num_imp varchar,
  descr_impegno varchar,
  num_movimento varchar,
  tipo_richiesta varchar,
  num_sospeso varchar,
  data_movimento date,
  num_fattura varchar,
  num_quota integer,
  data_emis_fattura date,
  cod_benefic_fattura varchar,
  descr_benefic_fattura varchar,
  descr_richiesta varchar,
  imp_richiesta numeric,
  rendicontazione varchar,
  code_tipo_richiesta varchar,
  num_sub_impegno varchar
) AS
$body$
DECLARE
elenco_movimenti record;
dati_giustif record;

BEGIN
   descr_ente='';
   num_capitolo='';
   num_articolo='';
   ueb='';
   anno_impegno=0;
   num_imp='';
   descr_impegno='';
   num_movimento='';
   tipo_richiesta='';
   num_sospeso='';
   data_movimento=NULL;
   num_fattura='';
   num_quota=0;
   data_emis_fattura=NULL;
   cod_benefic_fattura='';
   descr_benefic_fattura='';
   descr_richiesta='';
   imp_richiesta=0;   
   rendicontazione ='';
   code_tipo_richiesta='';
   num_sub_impegno='';
   
 /*
    Estraggo i dati dei movimenti che non sono mai stati rendicontati, cioè
    che non sono presenti in una stampa di rendiconto 
    (siac_d_cassa_econ_stampa_tipo.cest_tipo_code='REN')
    con tipo DEFINITIVO  (siac_d_cassa_econ_stampa_stato.cest_stato_code='D')
    */
        
--raise notice 'num_impegno = %', p_num_impegno;
	/* 11/03/2016: aggiunto il numero di SubImpegno */
BEGIN
    for elenco_movimenti in
   
    select  movimento.movt_numero 					num_movimento,
            richiesta_econ.ricecon_desc				descr_richiesta,
            richiesta_econ.ricecon_importo			imp_richiesta,
            richiesta_econ_tipo.ricecon_tipo_desc	tipo_richiesta,
            richiesta_econ_tipo.ricecon_tipo_code  	code_tipo_richiesta,
           richiesta_econ_sospesa.ricecons_numero	num_sospeso,
            movimento.movt_data						data_movimento,
            documento.doc_numero					num_fattura,
            documento.doc_data_emissione			data_emis_fattura,
            sub_documento.subdoc_numero				num_quota,
            soggetto.soggetto_desc					descr_benefic_fattura,
            soggetto.soggetto_code					cod_benefic_fattura,
            movgest.movgest_desc					descr_impegno,
            movgest.movgest_anno					anno_impegno,
            movgest.movgest_numero					num_imp,
           bil_elem.elem_code						num_capitolo,
            bil_elem.elem_code2						num_articolo,
            bil_elem.elem_code3     				UEB,
            ente_prop.ente_denominazione         	descr_ente ,
            movimento.gst_id,
			movgest_ts.movgest_ts_code				num_sub_impegno
    from 	siac_t_movimento						movimento,
            siac_d_richiesta_econ_tipo				richiesta_econ_tipo,
            siac_r_richiesta_econ_movgest			r_richiesta_movgest,
            siac_t_movgest							movgest,
            siac_t_movgest_ts						movgest_ts,
            siac_r_movgest_bil_elem					r_mov_gest_bil_elem,
            siac_t_bil_elem							bil_elem,
            siac_t_ente_proprietario				ente_prop,
            siac_r_richiesta_econ_stato				r_richiesta_stato,
            siac_d_richiesta_econ_stato				richiesta_stato,
            siac_t_cassa_econ						cassa_econ,
            siac_t_periodo 							anno_eserc,
            siac_t_bil 								bilancio,
            siac_t_richiesta_econ					richiesta_econ
          	LEFT join siac_t_richiesta_econ_sospesa		richiesta_econ_sospesa
            	on (richiesta_econ.ricecon_id = richiesta_econ_sospesa.ricecon_id
            		and richiesta_econ_sospesa.data_cancellazione is null)
            LEFT join siac_r_richiesta_econ_subdoc	r_richiesta_econ_subdoc
            	on (richiesta_econ.ricecon_id=r_richiesta_econ_subdoc.ricecon_id
            	 	and r_richiesta_econ_subdoc.data_cancellazione is null)            
            LEFT join 			siac_t_subdoc	sub_documento
            	on (r_richiesta_econ_subdoc.subdoc_id=sub_documento.subdoc_id
            		and sub_documento.data_cancellazione is null)
			LEFT join siac_t_doc				documento
            	on (sub_documento.doc_id=documento.doc_id
            		and documento.data_cancellazione is null  )            
            LEFT join 			siac_r_subdoc_sog	sub_doc_sog
            	on (sub_documento.subdoc_id=sub_doc_sog.subdoc_id
            		and sub_doc_sog.data_cancellazione is null)
            LEFT join 			siac_t_soggetto	soggetto
            	on (sub_doc_sog.soggetto_id=soggetto.soggetto_id
            		and soggetto.data_cancellazione is null )       
    where  richiesta_econ.ente_proprietario_id=anno_eserc.ente_proprietario_id
        and cassa_econ.ente_proprietario_id=richiesta_econ.ente_proprietario_id
        and cassa_econ.cassaecon_id= richiesta_econ.cassaecon_id
        and movimento.ricecon_id=richiesta_econ.ricecon_id
        and richiesta_econ.ricecon_id=r_richiesta_stato.ricecon_id
        and r_richiesta_stato.ricecon_stato_id=richiesta_stato.ricecon_stato_id
        and richiesta_econ.ricecon_tipo_id=richiesta_econ_tipo.ricecon_tipo_id
        and r_richiesta_movgest.ricecon_id= richiesta_econ.ricecon_id
        and movgest_ts.movgest_ts_id=r_richiesta_movgest.movgest_ts_id
        and movgest_ts.movgest_id=movgest.movgest_id
        and r_mov_gest_bil_elem.movgest_id=movgest.movgest_id
        and bil_elem.elem_id=r_mov_gest_bil_elem.elem_id
        and ente_prop.ente_proprietario_id=richiesta_econ.ente_proprietario_id
        and richiesta_econ.bil_id=bilancio.bil_id
        and bilancio.periodo_id=anno_eserc.periodo_id	
    	and richiesta_econ.ente_proprietario_id=p_ente_prop_id
        and richiesta_econ.cassaecon_id=p_cassaecon_id
        and ((p_data_da is NULL OR p_data_a is NULL) OR
        	 (p_data_da is NOT NULL AND p_data_a is NOT NULL
              AND movimento.movt_data between p_data_da and p_data_a))  
        AND ((p_num_impegno is NOT NULL and  movgest.movgest_numero=p_num_impegno)
           OR (p_num_impegno is NULL))      
         	/* 29/01/2016: aggiunto parametro per estrarre o meno le
            richieste di anticipo spese missione */
        and ((p_ant_spese_missione = 'N' 
         		AND richiesta_econ_tipo.ricecon_tipo_code<>'ANTICIPO_SPESE_MISSIONE')
              OR (p_ant_spese_missione = 'S'))
         and richiesta_stato.ricecon_stato_code<>'AN'
         and anno_eserc.anno=p_anno    
        and r_richiesta_movgest.data_cancellazione is null
        and richiesta_econ.data_cancellazione is null
        and ente_prop.data_cancellazione is null
        and bil_elem.data_cancellazione is null
        and r_mov_gest_bil_elem.data_cancellazione is null
        and movgest.data_cancellazione is null
        and movgest_ts.data_cancellazione is null
        and richiesta_econ.data_cancellazione is null
        and richiesta_econ_tipo.data_cancellazione is null
        and movimento.data_cancellazione is null                                            
        and cassa_econ.data_cancellazione is null
       and r_richiesta_stato.data_cancellazione is null
       and anno_eserc.data_cancellazione is null
       and bilancio.data_cancellazione is null
       and movimento.movt_id not in (
		/* estaggo i movimento già rendicontati per escluderli */   
 select movimento.movt_id
       from siac_t_movimento		movimento,
            siac_t_richiesta_econ	richiesta_econ,
            siac_r_movimento_stampa	 r_movimento_sta,
            siac_t_cassa_econ_stampa	cassa_stampa,
            siac_t_cassa_econ_stampa_valore	cassa_stampa_val,
            siac_d_cassa_econ_stampa_tipo	tipo_stampa,
            siac_r_cassa_econ_stampa_stato  r_stato_stampa,
            siac_d_cassa_econ_stampa_stato	stato_stampa,
			siac_t_periodo 							anno_eserc,
            siac_t_bil 								bilancio
       where movimento.ricecon_id=richiesta_econ.ricecon_id
        and movimento.movt_id=r_movimento_sta.movt_id
        and  r_movimento_sta.cest_id=cassa_stampa.cest_id
        and  cassa_stampa.cest_id=cassa_stampa_val.cest_id
        and  cassa_stampa.cest_tipo_id=tipo_stampa.cest_tipo_id
        and  cassa_stampa.cest_id=r_stato_stampa.cest_id
        and  r_stato_stampa.cest_stato_id=stato_stampa.cest_stato_id
        and richiesta_econ.ente_proprietario_id=anno_eserc.ente_proprietario_id
        and richiesta_econ.bil_id=bilancio.bil_id
        and bilancio.periodo_id=anno_eserc.periodo_id
        and  movimento.data_cancellazione is  NULL 
        and  r_movimento_sta.data_cancellazione is  NULL
        and  cassa_stampa.data_cancellazione is  NULL
        and  cassa_stampa_val.data_cancellazione is  NULL
        and  tipo_stampa.data_cancellazione is  NULL
        and  r_stato_stampa.data_cancellazione is  NULL
        and  stato_stampa.data_cancellazione is  NULL
        and bilancio.data_cancellazione is  NULL
        and anno_eserc.data_cancellazione is  NULL
        and movimento.ente_proprietario_id=p_ente_prop_id
        and richiesta_econ.cassaecon_id=p_cassaecon_id
        and anno_eserc.anno=p_anno
        and tipo_stampa.cest_tipo_code='REN'
        and stato_stampa.cest_stato_code='D')
    ORDER BY num_capitolo, num_articolo, ueb, anno_impegno, num_imp

        loop
        	/* se esiste un giustificativo, devo prendere il suo importo e non quello
            	del movimento */
       	if elenco_movimenti.gst_id is not NULL THEN
              rendicontazione = 'R';          
              SELECT rend_importo_restituito, rend_importo_integrato
                INTO dati_giustif
                FROM siac_t_giustificativo
                WHERE gst_id = elenco_movimenti.gst_id;
                IF NOT FOUND THEN
                    RAISE EXCEPTION 'Non esiste il giustificativo %', elenco_movimenti.gst_id;
                    return;
                ELSE
                		/* se esiste un importo restituito prendo questo con segno negativo */
                    if dati_giustif.rend_importo_restituito > 0 THEN                  
                  		imp_richiesta = -dati_giustif.rend_importo_restituito;
                    elsif dati_giustif.rend_importo_integrato > 0 THEN
                    	imp_richiesta = dati_giustif.rend_importo_integrato;
                    else 
                    	imp_richiesta=0;
                    end if;
                END IF;                 
         
        ELSE
        	rendicontazione = '';
        	imp_richiesta=elenco_movimenti.imp_richiesta;
        END IF;
                                         
          descr_ente=elenco_movimenti.descr_ente;
          num_capitolo=elenco_movimenti.num_capitolo;
          num_articolo=elenco_movimenti.num_articolo;
          ueb=elenco_movimenti.ueb;
          anno_impegno=elenco_movimenti.anno_impegno;
          num_imp=elenco_movimenti.num_imp;
          descr_impegno=elenco_movimenti.descr_impegno;
          num_movimento=elenco_movimenti.num_movimento;
          tipo_richiesta=elenco_movimenti.tipo_richiesta;
          code_tipo_richiesta=elenco_movimenti.code_tipo_richiesta;
          num_sospeso=elenco_movimenti.num_sospeso;
         data_movimento=elenco_movimenti.data_movimento;
         num_fattura=elenco_movimenti.num_fattura;
         num_quota=elenco_movimenti.num_quota;
         data_emis_fattura=elenco_movimenti.data_emis_fattura;
         cod_benefic_fattura=elenco_movimenti.cod_benefic_fattura;
         descr_benefic_fattura=elenco_movimenti.descr_benefic_fattura;
         descr_richiesta=elenco_movimenti.descr_richiesta;
         num_sub_impegno=elenco_movimenti.num_sub_impegno;
        
        return next;
       descr_ente='';
       num_capitolo='';
       num_articolo='';
       ueb='';
       anno_impegno=0;
       num_imp='';
       descr_impegno='';
       num_movimento='';
       tipo_richiesta='';
       num_sospeso='';
       data_movimento=NULL;
       num_fattura='';
       num_quota=0;
       data_emis_fattura=NULL;
       cod_benefic_fattura='';
       descr_benefic_fattura='';
       descr_richiesta='';
       imp_richiesta=0;
       code_tipo_richiesta='';
       num_sub_impegno='';
          
        end loop;
	end;
   

exception
	when no_data_found THEN
		raise notice 'movimenti non trovati' ;
		--return next;
	when others  THEN
		raise notice 'errore nella lettura dei movimenti non rendicontati ';
        return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100 ROWS 1000;