/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
﻿CREATE OR REPLACE FUNCTION siac."BILR091_libro_giornale_elenco_movimenti" (
  p_ente_prop_id integer,
  p_anno varchar,
  p_data_da date,
  p_data_a date,
  p_cassaecon_id integer
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
  tipo_pagam_movim varchar,
  num_operazione integer,
  cod_tipo_operazione varchar,
  desc_tipo_operazione varchar,
  data_operazione date,
  imp_operazione numeric,
  cod_tipo_modpag varchar,
  tipo_entrata_spesa varchar,
  numero_subimpegno varchar,
  cod_stato_richiesta varchar,
  desc_stato_richiesta varchar,
  cod_tipo_movgest varchar,
  elenco_quote varchar
) AS
$body$
DECLARE
elenco_movimenti record;
dati_giustif record;
elenco_operazioni_cassa record;
elencoSubdoc record;

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
   tipo_pagam_movim='';
   numero_subimpegno='';
   cod_stato_richiesta='';
   desc_stato_richiesta='';
   cod_tipo_movgest='';     
      
   num_operazione := NULL;
   cod_tipo_operazione := '';
   desc_tipo_operazione := '';
   data_operazione := NULL;
   imp_operazione := 0;
   cod_tipo_modpag :=  '';
   tipo_entrata_spesa :=  ''; 
	elenco_quote='';
   
 /*
    Estraggo i dati dei movimenti 
    con tipo DEFINITIVO  (siac_d_cassa_econ_stampa_stato.cest_stato_code='D')
    */
        
/* 31/03/2016: tolto il legame con le tabelle siac_t_doc, siac_t_subdoc perchè 
	le quote del documento devono essere concatenate, quindi la ricerca di questi
    dati è effettuata più avanti */
	BEGIN
      for elenco_movimenti in     
      select  movimento.movt_numero 					num_movimento,
              richiesta_econ.ricecon_desc				descr_richiesta,
              richiesta_econ.ricecon_importo			imp_richiesta,
              richiesta_econ_tipo.ricecon_tipo_desc	tipo_richiesta,
             richiesta_econ_sospesa.ricecons_numero	num_sospeso,
              movimento.movt_data						data_movimento,
              --documento.doc_numero					num_fattura,
             -- documento.doc_data_emissione			data_emis_fattura,
             -- sub_documento.subdoc_numero				num_quota,
             -- soggetto.soggetto_desc					descr_benefic_fattura,
             -- soggetto.soggetto_code					cod_benefic_fattura,
              movgest.movgest_desc					descr_impegno,
              movgest.movgest_anno					anno_impegno,
              movgest.movgest_numero					num_imp,
              bil_elem.elem_code						num_capitolo,
              bil_elem.elem_code2						num_articolo,
              bil_elem.elem_code3     				UEB,
              ente_prop.ente_denominazione         	descr_ente ,
              movimento.gst_id,
              t_trasf_miss.tramis_desc,
              d_cassa_econ_modpag_tipo.cassamodpag_tipo_code,
              movgest_ts.movgest_ts_code            numero_subimpegno,
              richiesta_stato.ricecon_stato_code    cod_stato_richiesta,
              richiesta_stato.ricecon_stato_desc    desc_stato_richiesta,
              movgest_ts_tipo.movgest_ts_tipo_code  cod_tipo_movgest,
              richiesta_econ.ricecon_id
      from 	siac_t_movimento						movimento
      		LEFT JOIN siac_d_cassa_econ_modpag_tipo d_cassa_econ_modpag_tipo
            	ON (d_cassa_econ_modpag_tipo.cassamodpag_tipo_id=movimento.cassamodpag_tipo_id
                	and d_cassa_econ_modpag_tipo.data_cancellazione IS NULL),
              siac_d_richiesta_econ_tipo				richiesta_econ_tipo,              
              siac_r_richiesta_econ_movgest			r_richiesta_movgest,
              siac_t_movgest							movgest,
              siac_t_movgest_ts						movgest_ts,
              siac_d_movgest_ts_tipo                movgest_ts_tipo,
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
            	AND richiesta_econ_sospesa.data_cancellazione IS NULL)
            /*  LEFT join siac_r_richiesta_econ_subdoc	r_richiesta_econ_subdoc
            on (richiesta_econ.ricecon_id=r_richiesta_econ_subdoc.ricecon_id
            	AND r_richiesta_econ_subdoc.data_cancellazione IS NULL)            
             LEFT join 			siac_t_subdoc	sub_documento
            on (r_richiesta_econ_subdoc.subdoc_id=sub_documento.subdoc_id
            	AND sub_documento.data_cancellazione IS NULL)
			LEFT join siac_t_doc				documento
            on (sub_documento.doc_id=documento.doc_id
            	AND documento.data_cancellazione IS NULL)   */
                /* 26/02/2016: il soggetto deve essere quello della fattura e non
                	quello del subdoc */
             -- LEFT join  siac_r_subdoc_sog	sub_doc_sog 
             --   on (sub_documento.subdoc_id= sub_doc_sog.subdoc_id  
              --  AND sub_doc_sog.data_cancellazione IS NULL)       
       /*      LEFT join 	siac_r_doc_sog r_doc_sog		
                on (documento.doc_id= r_doc_sog.doc_id
              	AND r_doc_sog.data_cancellazione IS NULL)
              LEFT join 			siac_t_soggetto	soggetto
              --on (sub_doc_sog.soggetto_id=soggetto.soggetto_id
              	on (r_doc_sog.soggetto_id=soggetto.soggetto_id
              	AND soggetto.data_cancellazione IS NULL) */
          	LEFT join siac_t_trasf_miss				t_trasf_miss     
          	on (t_trasf_miss.ricecon_id = richiesta_econ.ricecon_id
            	AND t_trasf_miss.data_cancellazione is NULL)
          where richiesta_econ.ente_proprietario_id=anno_eserc.ente_proprietario_id
          and cassa_econ.ente_proprietario_id=richiesta_econ.ente_proprietario_id
          and cassa_econ.cassaecon_id= richiesta_econ.cassaecon_id
          and movimento.ricecon_id=richiesta_econ.ricecon_id
          and richiesta_econ.ricecon_id=r_richiesta_stato.ricecon_id
          and r_richiesta_stato.ricecon_stato_id=richiesta_stato.ricecon_stato_id
          and richiesta_econ.ricecon_tipo_id=richiesta_econ_tipo.ricecon_tipo_id
          and r_richiesta_movgest.ricecon_id= richiesta_econ.ricecon_id
          and movgest_ts.movgest_ts_id=r_richiesta_movgest.movgest_ts_id
          and movgest_ts.movgest_id=movgest.movgest_id
          and movgest_ts.movgest_ts_tipo_id = movgest_ts_tipo.movgest_ts_tipo_id
          and r_mov_gest_bil_elem.movgest_id=movgest.movgest_id
          and bil_elem.elem_id=r_mov_gest_bil_elem.elem_id
          and ente_prop.ente_proprietario_id=richiesta_econ.ente_proprietario_id
          and richiesta_econ.bil_id=bilancio.bil_id
          and bilancio.periodo_id=anno_eserc.periodo_id   
          and richiesta_econ.ente_proprietario_id=p_ente_prop_id
          and richiesta_econ.cassaecon_id=p_cassaecon_id
          and movimento.movt_data between p_data_da and  p_data_a
          -- and richiesta_stato.ricecon_stato_code<>'AN'
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
      ORDER BY num_capitolo, num_articolo, ueb, anno_impegno, num_imp

          loop
          		/* 31/03/2016: cerco le quote e le concateno */
          	elenco_quote='';
          	FOR elencoSubdoc IN
            	select documento.doc_numero					num_fattura,
             		documento.doc_data_emissione			data_emis_fattura,
              		sub_documento.subdoc_numero				num_quota,
              		soggetto.soggetto_desc					descr_benefic_fattura,
              		soggetto.soggetto_code					cod_benefic_fattura
      			FROM  siac_r_richiesta_econ_subdoc	r_richiesta_econ_subdoc,
                		siac_t_subdoc	sub_documento,
                        siac_t_doc				documento
							LEFT join 	siac_r_doc_sog r_doc_sog		
                			on (documento.doc_id= r_doc_sog.doc_id
              					AND r_doc_sog.data_cancellazione IS NULL)	
              				LEFT join 			siac_t_soggetto	soggetto              
              				on (r_doc_sog.soggetto_id=soggetto.soggetto_id
              	AND soggetto.data_cancellazione IS NULL)
                WHERE r_richiesta_econ_subdoc.subdoc_id=sub_documento.subdoc_id
                AND sub_documento.doc_id=documento.doc_id
                AND r_richiesta_econ_subdoc.ricecon_id = elenco_movimenti.ricecon_id
            	AND r_richiesta_econ_subdoc.data_cancellazione IS NULL
                AND sub_documento.data_cancellazione IS NULL
                AND documento.data_cancellazione IS NULL
            loop
            	if elenco_quote='' THEN
                	elenco_quote= elencoSubdoc.num_quota ::VARCHAR;
                    num_fattura=elencoSubdoc.num_fattura;
                    data_emis_fattura=elencoSubdoc.data_emis_fattura;
                    cod_benefic_fattura=elencoSubdoc.cod_benefic_fattura;
                    descr_benefic_fattura=elencoSubdoc.descr_benefic_fattura;
                ELSE
                	elenco_quote= elenco_quote||' - '|| elencoSubdoc.num_quota ::VARCHAR;
                END IF;
                
            end loop;
            
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
            num_sospeso=elenco_movimenti.num_sospeso;
           data_movimento=elenco_movimenti.data_movimento;
           	/* 31/03/2016: i dati di fattura, soggetto e quota sono stati caricati 
            	prima con specifica query */
           --num_fattura=elenco_movimenti.num_fattura;
           --num_quota=elenco_movimenti.num_quota;
           --data_emis_fattura=elenco_movimenti.data_emis_fattura;
           --cod_benefic_fattura=elenco_movimenti.cod_benefic_fattura;
           --descr_benefic_fattura=elenco_movimenti.descr_benefic_fattura;
           tipo_pagam_movim=COALESCE(elenco_movimenti.cassamodpag_tipo_code,'');
           numero_subimpegno=elenco_movimenti.numero_subimpegno;
           cod_stato_richiesta=elenco_movimenti.cod_stato_richiesta;
           desc_stato_richiesta=elenco_movimenti.desc_stato_richiesta;
           cod_tipo_movgest=elenco_movimenti.cod_tipo_movgest;
           
           	/* la descrizione può essere quella della richiesta o quella
            	della missione */
           if(elenco_movimenti.descr_richiesta='' OR 
           		elenco_movimenti.descr_richiesta IS NULL) THEN
           		descr_richiesta=elenco_movimenti.tramis_desc;                
           ELSE
           		descr_richiesta=elenco_movimenti.descr_richiesta;
           end if;
          -- imp_richiesta=elenco_movimenti.imp_richiesta;
          
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
         tipo_pagam_movim='';
         numero_subimpegno='';
         cod_stato_richiesta='';
         desc_stato_richiesta='';
         cod_tipo_movgest='';
         
      end loop;
      
      FOR elenco_operazioni_cassa IN
      SELECT tceo.cassaeconop_numero, dceot.cassaeconop_tipo_code, dceot.cassaeconop_tipo_desc, tceo.validita_inizio,
             tceo.cassaeconop_importo, dcemt.cassamodpag_tipo_code, dceot.cassaeconop_tipo_entrataspesa
      FROM siac_t_cassa_econ_operaz tceo, siac_r_cassa_econ_operaz_tipo rceot,
           siac_d_cassa_econ_operaz_tipo dceot, siac_d_cassa_econ_modpag_tipo dcemt,
           siac_t_bil tb, siac_t_periodo tp, siac_r_cassa_econ_operaz_stato rceos, siac_d_cassa_econ_operaz_stato dceos
      WHERE tceo.ente_proprietario_id = p_ente_prop_id
      AND   tp.anno = p_anno  
      AND   to_date(to_char(tceo.validita_inizio ,'dd/mm/yyyy') ,'dd/mm/yyyy') BETWEEN COALESCE(p_data_da, to_date(to_char(tceo.validita_inizio ,'dd/mm/yyyy') ,'dd/mm/yyyy')) AND COALESCE(p_data_a, to_date(to_char(tceo.validita_inizio ,'dd/mm/yyyy') ,'dd/mm/yyyy'))     
      AND   tceo.cassaec_id = p_cassaecon_id
      AND   tceo.cassaeconop_id = rceot.cassaeconop_id
      AND   dceot.cassaeconop_tipo_id = rceot.cassaeconop_tipo_id
      AND   dcemt.cassamodpag_tipo_id = tceo.cassamodpag_tipo_id
      AND   tceo.bil_id =  tb.bil_id
      AND   tb.periodo_id = tp.periodo_id
      AND   rceos.cassaeconop_id = tceo.cassaeconop_id
      AND   rceos.cassaeconop_stato_id = dceos.cassaeconop_stato_id
      AND   dceos.cassaeconop_stato_code <> 'A'
      AND   tceo.data_cancellazione IS NULL
      AND   rceot.data_cancellazione IS NULL
      AND   dceot.data_cancellazione IS NULL
      AND   dcemt.data_cancellazione IS NULL
      AND   tb.data_cancellazione IS NULL
      AND   tp.data_cancellazione IS NULL
      AND   rceos.data_cancellazione IS NULL
      AND   dceos.data_cancellazione IS NULL
      ORDER BY tceo.validita_inizio, tceo.cassaeconop_numero, dceot.cassaeconop_tipo_entrataspesa
      
      
      LOOP
      
      	 num_operazione := elenco_operazioni_cassa.cassaeconop_numero;
         cod_tipo_operazione := elenco_operazioni_cassa.cassaeconop_tipo_code;
         desc_tipo_operazione := elenco_operazioni_cassa.cassaeconop_tipo_desc;
         data_operazione := elenco_operazioni_cassa.validita_inizio;
         imp_operazione := elenco_operazioni_cassa.cassaeconop_importo;
         cod_tipo_modpag := elenco_operazioni_cassa.cassamodpag_tipo_code;
         tipo_entrata_spesa := elenco_operazioni_cassa.cassaeconop_tipo_entrataspesa; 
      
         return next;
         num_operazione := NULL;
         cod_tipo_operazione := '';
         desc_tipo_operazione := '';
         data_operazione := NULL;
         imp_operazione := 0;
         cod_tipo_modpag :=  '';   
         tipo_entrata_spesa :=  ''; 
      
      END LOOP;
                      
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