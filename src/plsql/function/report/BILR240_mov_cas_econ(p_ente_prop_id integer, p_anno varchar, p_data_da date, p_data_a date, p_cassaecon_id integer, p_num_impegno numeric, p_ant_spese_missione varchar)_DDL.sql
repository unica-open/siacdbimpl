/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac."BILR240_mov_cas_econ" (
  p_ente_prop_id integer,
  p_anno varchar,
  p_data_da date,
  p_data_a date,
  p_cassaecon_id integer,
  p_num_impegno numeric,
  p_ant_spese_missione varchar
)
RETURNS TABLE (
  num_capitolo varchar,
  num_articolo varchar,
  ueb varchar,
  anno_impegno integer,
  num_imp varchar,
  num_sub_impegno varchar,
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
  rendicontato varchar,
  importo_attuale_impegno numeric,
  num_carte_non_reg integer,
  imp_carte_non_reg numeric,
  num_predoc_non_liq integer,
  imp_predoc_non_liq numeric,
  num_doc_non_liq integer,
  imp_doc_non_liq numeric,
  imp_pagam_economali numeric,
  num_liquidazioni integer,
  imp_liquidazioni numeric,
  imp_totale_movimenti numeric,
  imp_disp_liquid numeric,
  imp_disp_pagare numeric,
  imp_disp_vincolare numeric
) AS
$body$
DECLARE

dati_movimenti record;
dati_giustif record;
bilancio_id integer;
contaProgRilevanteFPV integer;
contaVincolTrasfVincolati integer;

BEGIN
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
  rendicontato:='';
  importo_attuale_impegno:=0; 
  num_carte_non_reg:=0;
  imp_carte_non_reg:=0;
  num_predoc_non_liq:=0;
  imp_predoc_non_liq:=0;
  num_doc_non_liq:=0;
  imp_doc_non_liq:=0;
  imp_pagam_economali:=0;
  num_liquidazioni:=0;
  imp_liquidazioni :=0; 
  imp_disp_liquid :=0;
  imp_disp_pagare :=0;
  imp_disp_vincolare :=0;
  imp_totale_movimenti:=0;  
  
   select t_bil.bil_id
   	into bilancio_id 
   from siac_t_bil t_bil,
   	siac_t_periodo t_periodo
   where t_bil.periodo_id =t_periodo.periodo_id
   	and t_bil.ente_proprietario_id=p_ente_prop_id
    and t_periodo.anno =p_anno
    and t_bil.data_cancellazione IS NULL
    and t_periodo.data_cancellazione IS NULL;
    
   
for dati_movimenti in
    with elenco_movimenti as (
            select movimento.movt_numero num_movimento,
            	richiesta_econ_tipo.ricecon_tipo_code,
                richiesta_econ_tipo.ricecon_tipo_desc tipo_richiesta,
                COALESCE(richiesta_econ_sospesa.ricecons_numero::varchar,'') num_sospeso,
                movimento.movt_data data_movimento,
                documento.doc_numero num_fattura,
                sub_documento.subdoc_numero num_quota,
                documento.doc_data_emissione data_emis_fattura,
                soggetto.soggetto_code cod_benefic_fattura,
                soggetto.soggetto_desc descr_benefic_fattura,
                richiesta_econ.ricecon_desc descr_richiesta,
                /* se esiste un giustificativo, devo prendere il suo importo e non quello
                    del movimento */
                case when movimento.gst_id is not NULL 
                    then case when t_giustiv.rend_importo_restituito > 0
                        then -t_giustiv.rend_importo_restituito 
                        else case when t_giustiv.rend_importo_integrato > 0 
                            then t_giustiv.rend_importo_integrato 
                            else 0  end
                        end
                    else richiesta_econ.ricecon_importo end	imp_richiesta,
                case when movimento.gst_id is not NULL 
                    then 'S'::varchar else ''::varchar end 		rendicontazione,
                richiesta_econ_tipo.ricecon_tipo_code code_tipo_richiesta,
                case when mov_rend.movt_id IS NULL
                    then 'N' else 'S' end  	rendicontato,
                r_richiesta_movgest.movgest_ts_id
            from 	siac_t_movimento			movimento
                LEFT JOIN siac_t_giustificativo t_giustiv
                    ON (t_giustiv.gst_id = movimento.gst_id
                        and t_giustiv.data_cancellazione IS NULL)
                   --verifico se il movimento e' rendicontato
                LEFT JOIN (select movimento.movt_id
                           from siac_t_movimento		movimento,
                                siac_t_richiesta_econ	richiesta_econ,
                                siac_r_movimento_stampa	 r_movimento_sta,
                                siac_t_cassa_econ_stampa	cassa_stampa,
                                siac_t_cassa_econ_stampa_valore	cassa_stampa_val,
                                siac_d_cassa_econ_stampa_tipo	tipo_stampa,
                                siac_r_cassa_econ_stampa_stato  r_stato_stampa,
                                siac_d_cassa_econ_stampa_stato	stato_stampa
                           where movimento.ricecon_id=richiesta_econ.ricecon_id
                            and movimento.movt_id=r_movimento_sta.movt_id
                            and  r_movimento_sta.cest_id=cassa_stampa.cest_id
                            and  cassa_stampa.cest_id=cassa_stampa_val.cest_id
                            and  cassa_stampa.cest_tipo_id=tipo_stampa.cest_tipo_id
                            and  cassa_stampa.cest_id=r_stato_stampa.cest_id
                            and  r_stato_stampa.cest_stato_id=stato_stampa.cest_stato_id                                                                   
                            and movimento.ente_proprietario_id=p_ente_prop_id
                            and richiesta_econ.cassaecon_id=p_cassaecon_id
                            and richiesta_econ.bil_id=bilancio_id
                            and tipo_stampa.cest_tipo_code='REN'
                            and stato_stampa.cest_stato_code='D'
                            and  movimento.data_cancellazione is  NULL 
                            and  r_movimento_sta.data_cancellazione is  NULL
                            and  cassa_stampa.data_cancellazione is  NULL
                            and  cassa_stampa_val.data_cancellazione is  NULL
                            and  tipo_stampa.data_cancellazione is  NULL
                            and  r_stato_stampa.data_cancellazione is  NULL
                            and  stato_stampa.data_cancellazione is  NULL) mov_rend 
                     ON mov_rend.movt_id = movimento.movt_id,
                siac_t_richiesta_econ					richiesta_econ
                  LEFT join siac_t_richiesta_econ_sospesa		richiesta_econ_sospesa
                      on (richiesta_econ.ricecon_id = richiesta_econ_sospesa.ricecon_id
                          and richiesta_econ_sospesa.data_cancellazione is null)
                  LEFT join siac_r_richiesta_econ_subdoc	r_richiesta_econ_subdoc
                      on (richiesta_econ.ricecon_id=r_richiesta_econ_subdoc.ricecon_id
                          and r_richiesta_econ_subdoc.data_cancellazione is null)            
                  LEFT join siac_t_subdoc	sub_documento
                      on (r_richiesta_econ_subdoc.subdoc_id=sub_documento.subdoc_id
                          and sub_documento.data_cancellazione is null)
                  LEFT join siac_t_doc				documento
                      on (sub_documento.doc_id=documento.doc_id
                          and documento.data_cancellazione is null  )            
                  LEFT join siac_r_subdoc_sog	sub_doc_sog
                      on (sub_documento.subdoc_id=sub_doc_sog.subdoc_id
                          and sub_doc_sog.data_cancellazione is null)
                  LEFT join siac_t_soggetto	soggetto
                      on (sub_doc_sog.soggetto_id=soggetto.soggetto_id
                          and soggetto.data_cancellazione is null ),
                siac_d_richiesta_econ_tipo				richiesta_econ_tipo,
                siac_t_cassa_econ						cassa_econ,
                siac_r_richiesta_econ_stato				r_richiesta_stato,
                siac_d_richiesta_econ_stato				richiesta_stato,
                siac_r_richiesta_econ_movgest			r_richiesta_movgest
           where movimento.ricecon_id=richiesta_econ.ricecon_id
            and richiesta_econ.ricecon_tipo_id=richiesta_econ_tipo.ricecon_tipo_id
            and cassa_econ.cassaecon_id= richiesta_econ.cassaecon_id
            and richiesta_econ.ricecon_id=r_richiesta_stato.ricecon_id
            and r_richiesta_stato.ricecon_stato_id=richiesta_stato.ricecon_stato_id     
            and r_richiesta_movgest.ricecon_id= richiesta_econ.ricecon_id
            and movimento.ente_proprietario_id = p_ente_prop_id
            and richiesta_econ.bil_id=bilancio_id
            and richiesta_econ.cassaecon_id=p_cassaecon_id      			
            and richiesta_stato.ricecon_stato_code <> 'AN'  
            and movimento.data_cancellazione IS NULL
            and richiesta_econ.data_cancellazione IS NULL
            and richiesta_econ_tipo.data_cancellazione IS NULL
            and cassa_econ.data_cancellazione IS NULL
            and r_richiesta_stato.data_cancellazione IS NULL
            and richiesta_stato.data_cancellazione IS NULL
            and r_richiesta_movgest.data_cancellazione IS NULL),
    elenco_impegni_capitoli as (select movgest.movgest_anno anno_impegno, 
                    movgest.movgest_numero num_imp,
                    movgest.movgest_desc descr_impegno,
                    movgest_ts.movgest_ts_code num_sub_impegno,
                    bil_elem.elem_code num_capitolo,
                    bil_elem.elem_code2 num_articolo,
                    bil_elem.elem_code3 UEB,
                    t_movgest_ts_det.movgest_ts_det_importo importo_attuale_impegno,
                    movgest_ts.movgest_ts_id,
                    COALESCE(d_assenza_motiv.siope_assenza_motivazione_code,'') assenza_cig_code,
                    COALESCE(d_assenza_motiv.siope_assenza_motivazione_desc ,'') assenza_cig_desc,
                    d_movgest_stato.movgest_stato_code,
                    COALESCE(r_movgest_ts.movgest_ts_importo,0) importo_vincoli,
                    movgest.parere_finanziario,
                    bil_elem.elem_id
                from 	siac_t_movgest				movgest,
                        siac_d_movgest_tipo 		d_movgest_tipo,
                        siac_t_movgest_ts			movgest_ts
                        	LEFT JOIN siac_d_siope_assenza_motivazione d_assenza_motiv
                            	ON (d_assenza_motiv.siope_assenza_motivazione_id=movgest_ts.siope_assenza_motivazione_id
                                	and d_assenza_motiv.data_cancellazione IS NULL)
                            LEFT JOIN siac_r_movgest_ts r_movgest_ts
                            	ON (r_movgest_ts.movgest_ts_b_id=movgest_ts.movgest_ts_id
                                	and r_movgest_ts.data_cancellazione IS NULL),                    	
                        siac_t_movgest_ts_det		t_movgest_ts_det,                    
                        siac_d_movgest_ts_det_tipo 	d_movgest_ts_det_tipo,
                        siac_r_movgest_ts_stato		r_movgest_ts_stato,
                        siac_d_movgest_stato		d_movgest_stato,
                        siac_r_movgest_bil_elem		r_mov_gest_bil_elem,
                        siac_t_bil_elem				bil_elem
                where movgest.movgest_tipo_id= d_movgest_tipo.movgest_tipo_id
                    and movgest.movgest_id= movgest_ts.movgest_id
                    and movgest_ts.movgest_ts_id= t_movgest_ts_det.movgest_ts_id
                    and t_movgest_ts_det.movgest_ts_det_tipo_id=d_movgest_ts_det_tipo.movgest_ts_det_tipo_id
                    and r_movgest_ts_stato.movgest_ts_id = movgest_ts.movgest_ts_id
                    and r_movgest_ts_stato.movgest_stato_id = d_movgest_stato.movgest_stato_id
                    and r_mov_gest_bil_elem.movgest_id= movgest.movgest_id   
                    and bil_elem.elem_id = r_mov_gest_bil_elem.elem_id
                    and movgest.ente_proprietario_id = p_ente_prop_id
                    and d_movgest_tipo.movgest_tipo_code ='I'
                    and d_movgest_ts_det_tipo.movgest_ts_det_tipo_code ='A'
                    and movgest.data_cancellazione IS NULL  
                    and d_movgest_tipo.data_cancellazione IS NULL
                    and movgest_ts.data_cancellazione IS NULL
                    and t_movgest_ts_det.data_cancellazione IS NULL
                    and d_movgest_ts_det_tipo.data_cancellazione IS NULL
                    and d_movgest_stato.data_cancellazione IS NULL
                    and r_movgest_ts_stato.data_cancellazione IS NULL
                    and r_mov_gest_bil_elem.data_cancellazione IS NULL
                    and bil_elem.data_cancellazione IS NULL)
    select elenco_impegni_capitoli.num_capitolo,
      elenco_impegni_capitoli.num_articolo,
      elenco_impegni_capitoli.UEB,
      elenco_impegni_capitoli.anno_impegno,
      elenco_impegni_capitoli.num_imp,
      elenco_impegni_capitoli.descr_impegno,
      elenco_movimenti.num_movimento,
      elenco_movimenti.tipo_richiesta,
      elenco_movimenti.num_sospeso,
      elenco_movimenti.data_movimento,
      elenco_movimenti.num_fattura,
      elenco_movimenti.num_quota,
      elenco_movimenti.data_emis_fattura,
      elenco_movimenti.cod_benefic_fattura,
      elenco_movimenti.descr_benefic_fattura,
      elenco_movimenti.descr_richiesta,
      elenco_movimenti.imp_richiesta,
      elenco_movimenti.rendicontazione,
      elenco_movimenti.code_tipo_richiesta,
      elenco_impegni_capitoli.num_sub_impegno,
      elenco_movimenti.rendicontato,
      elenco_impegni_capitoli.importo_attuale_impegno,
      elenco_impegni_capitoli.movgest_ts_id,
      elenco_impegni_capitoli.assenza_cig_code,
      elenco_impegni_capitoli.assenza_cig_desc,
      elenco_impegni_capitoli.movgest_stato_code,
      elenco_impegni_capitoli.importo_vincoli,
      elenco_impegni_capitoli.parere_finanziario,
      elenco_impegni_capitoli.elem_id
    from elenco_movimenti
        LEFT JOIN elenco_impegni_capitoli
            ON elenco_impegni_capitoli.movgest_ts_id = elenco_movimenti.movgest_ts_id 
    where ((p_data_da is NULL OR p_data_a is NULL) OR
        	 (p_data_da is NOT NULL AND p_data_a is NOT NULL
              AND elenco_movimenti.data_movimento between p_data_da and p_data_a))  
        AND ((p_num_impegno is NOT NULL and  elenco_impegni_capitoli.num_imp=p_num_impegno)
           	OR (p_num_impegno is NULL))      
         and ((p_ant_spese_missione = 'N' 
         		AND elenco_movimenti.ricecon_tipo_code<>'ANTICIPO_SPESE_MISSIONE')              
              OR (p_ant_spese_missione = 'S'))
    ORDER BY num_capitolo, num_articolo, ueb, anno_impegno, num_imp, num_sub_impegno
loop 
	num_capitolo:=dati_movimenti.num_capitolo;
    num_articolo:=dati_movimenti.num_articolo;
    ueb:=dati_movimenti.ueb;
    anno_impegno:=dati_movimenti.anno_impegno;
    num_imp:=dati_movimenti.num_imp;
    num_sub_impegno:=dati_movimenti.num_sub_impegno;
    descr_impegno:=dati_movimenti.descr_impegno;
    num_movimento:=dati_movimenti.num_movimento;
    tipo_richiesta:=dati_movimenti.tipo_richiesta;
    num_sospeso:=dati_movimenti.num_sospeso;
    data_movimento:=dati_movimenti.data_movimento;
    num_fattura:=dati_movimenti.num_fattura;
    num_quota:=dati_movimenti.num_quota;
    data_emis_fattura:=dati_movimenti.data_emis_fattura;
    cod_benefic_fattura:=dati_movimenti.cod_benefic_fattura;
    descr_benefic_fattura:=dati_movimenti.descr_benefic_fattura;
    descr_richiesta:=dati_movimenti.descr_richiesta;
    imp_richiesta:=dati_movimenti.imp_richiesta;   
    rendicontazione :=dati_movimenti.rendicontazione;
    code_tipo_richiesta:=dati_movimenti.code_tipo_richiesta;    
    rendicontato:=dati_movimenti.rendicontato;
    importo_attuale_impegno:=dati_movimenti.importo_attuale_impegno;    
    
    	--Estraggo i dati di riepilogo
    select dett_imp.n_carte_non_reg, dett_imp.tot_carte_non_reg, dett_imp.n_imp_predoc,
    	dett_imp.tot_imp_predoc, dett_imp.n_doc_non_liq, dett_imp.tot_doc_non_liq,
        (dett_imp.tot_imp_cec_fattura+dett_imp.tot_imp_cec_no_giust+dett_imp.tot_imp_cec_paf_fatt),
        dett_imp.n_doc_liq, dett_imp.tot_imp_liq    	
    into num_carte_non_reg, imp_carte_non_reg,  num_predoc_non_liq,
  		imp_predoc_non_liq, num_doc_non_liq,   imp_doc_non_liq,
  		imp_pagam_economali, num_liquidazioni, imp_liquidazioni
    from "fnc_siac_consultadettaglioimpegno"(dati_movimenti.movgest_ts_id) dett_imp;
    
    imp_totale_movimenti:= imp_carte_non_reg+imp_predoc_non_liq+imp_doc_non_liq+
    	imp_pagam_economali+imp_liquidazioni;

    
    --l'importo della disponibilita' a vincolare e' dato dall'importo
    -- attuale dell'impegno meno l'importo dei vincoli.
    imp_disp_vincolare:=dati_movimenti.importo_attuale_impegno-
    	dati_movimenti.importo_vincoli;

    --verifico se esitono progetti collegati all'impegno con FlagRilevanteFPV=true.
    contaProgRilevanteFPV:=0;
    select count(*)
	into contaProgRilevanteFPV    
    from siac_r_movgest_ts_programma r_mov_programma,
        siac_t_programma t_prog,
        siac_r_programma_attr r_prog_attr,
        siac_t_attr t_attr, 
        siac_d_attr_tipo d_attr_tipo   
    where t_prog.programma_id = r_mov_programma.programma_id
    and	t_prog.programma_id	= r_prog_attr.programma_id
    and	t_attr.attr_id			= r_prog_attr.attr_id
    and	t_attr.attr_tipo_id		= d_attr_tipo.attr_tipo_id
    and	r_mov_programma.ente_proprietario_id	= p_ente_prop_id
    and d_attr_tipo.attr_tipo_code	='B'
    and	t_attr.attr_code		= 	'FlagRilevanteFPV'
    and r_prog_attr."boolean" ='S'
    and r_mov_programma.movgest_ts_id = dati_movimenti.movgest_ts_id
    and t_prog.data_cancellazione is null
    and	r_mov_programma.data_cancellazione	is null
    and	t_attr.data_cancellazione	is null
    and r_prog_attr.data_cancellazione is null
    and d_attr_tipo.data_cancellazione IS NULL;
    
    -- verifico se esistono dei voncoli collegati al capitolo con 
    -- FlagTrasferimentiVincolati = true.
    contaVincolTrasfVincolati := 0;
    select count(*)
    into contaVincolTrasfVincolati
    from siac_r_vincolo_bil_elem r_vinc_bil_elem,
      siac_t_vincolo t_vincolo,
      siac_t_attr t_attr,
      siac_r_vincolo_attr r_vincolo_attr
    where r_vinc_bil_elem.vincolo_id=t_vincolo.vincolo_id
		and r_vincolo_attr.vincolo_id=t_vincolo.vincolo_id
     	and r_vincolo_attr.attr_id = t_attr.attr_id
        and r_vinc_bil_elem.elem_id = dati_movimenti.elem_id
        and t_attr.attr_code ='FlagTrasferimentiVincolati'
        and r_vincolo_attr."boolean" ='S'
        and r_vinc_bil_elem.data_cancellazione IS NULL 
        and t_vincolo.data_cancellazione IS NULL
        and t_attr.data_cancellazione IS NULL
        and r_vincolo_attr.data_cancellazione IS NULL;
        



		-- Per quanto riguarda l'importo "Disponibilita' a Vincolare" occorre
        -- fare le seguenti verifiche:
    	-- 1. se Motivo Assenza CIG dell'impegno = 'ID' - 'CIG in corso di definizione'.
        -- 2. se lo stato dell'impegno non e' DEFINITIVO.
        -- 3. se l'anno dell'impegno e' maggiore di quello del bilancio.
        -- 4. Se l'impegno non e' validato (flag parere finanziario non a TRUE).
        -- 5. Se l'impegno e' parzialmente vincolato (disponibilitaVincolare > 0 e 
		--    disponibilitaVincolare < importoAttuale.
        -- 6. Se l'impegno e' residuo e legato a un progetto rilevante fondo 
		--    (disponibilitaVincolare > 0 e Progetto.RilevanteFPV = TRUE.
        -- 7. Se l'impegno e' residuo e legato ad un Capitolo con un vincolo di 
        --    trasferimento (disponibilitaVincolare > 0 ed esiste almeno 1
		--    Capitolo.ListaVincoli.Vincolo.flagTrasferimpentiVincolati = TRUE ). 
        -- Se una delle precedenti verifiche ha dato esito positivo l'importo
        -- "Disponibilita' a Vincolare" deve essere impostato a 0.
        
        
    if dati_movimenti.assenza_cig_code = 'ID' OR
    	dati_movimenti.movgest_stato_code <> 'D' OR
        dati_movimenti.anno_impegno > p_anno::integer OR
        dati_movimenti.parere_finanziario = false OR
        (imp_disp_vincolare > 0 and 
         imp_disp_vincolare < dati_movimenti.importo_attuale_impegno) OR
        (imp_disp_vincolare > 0 and contaProgRilevanteFPV > 0) OR
        (imp_disp_vincolare > 0 and contaVincolTrasfVincolati > 0)
          then
    		raise notice 'L''impegno % ha: - assenza_cig_code = %', 
            	dati_movimenti.anno_impegno||'/'||dati_movimenti.num_imp||'/'||dati_movimenti.num_sub_impegno,
                dati_movimenti.assenza_cig_code;
            raise notice '             - stato = %', dati_movimenti.movgest_stato_code;
            raise notice '             - anno = %', dati_movimenti.anno_impegno;
            raise notice '             - parere finanziario = %', dati_movimenti.parere_finanziario;
            raise notice '             - importo disp a vincolare = %', imp_disp_vincolare;
            raise notice '             - parere finanziario = %', dati_movimenti.parere_finanziario;
            raise notice '             - progetti collegati con flag rilevante FPV a true = %', contaProgRilevanteFPV;
            raise notice '             - vincoli collegati con flag trasferimenti vincolati a true = %', contaVincolTrasfVincolati;
            raise notice '  L''importo disponibilita'' a liquidare e'' impostato a 0';
             
    	imp_disp_liquid:=0;
    else
		select disp_liq.val2
    	into imp_disp_liquid
    	from "fnc_siac_disponibilitaliquidaremovgest_rec"(dati_movimenti.movgest_ts_id::varchar) disp_liq;    
    end if;
    
    
    select disp_pag.val2
    into imp_disp_pagare
    from "fnc_siac_disponibileapagaremovgest_rec"(dati_movimenti.movgest_ts_id::varchar) disp_pag;    
        
return next; 

end loop;

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
  rendicontato:=''; 
  importo_attuale_impegno:=0;                                               
  num_carte_non_reg:=0;
  imp_carte_non_reg:=0;
  num_predoc_non_liq:=0;
  imp_predoc_non_liq:=0;
  num_doc_non_liq:=0;
  imp_doc_non_liq:=0;
  imp_pagam_economali:=0;
  num_liquidazioni:=0;
  imp_liquidazioni :=0;  
  imp_disp_liquid :=0;
  imp_disp_pagare :=0;
  imp_disp_vincolare :=0;                  
  imp_totale_movimenti:=0;  
  
exception
	when no_data_found THEN
		raise notice 'movimenti non trovati' ;
		--return next;
--	when others  THEN
	--	raise notice 'errore nella lettura dei movimenti. ';
  --      return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100 ROWS 1000;