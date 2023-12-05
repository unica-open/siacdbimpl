--siac-task issue #229 - Maurizio - INIZIO.

CREATE OR REPLACE FUNCTION siac."BILR116_Stampa_riepilogo_iva" (
  p_ente_prop_id integer,
  p_anno varchar,
  p_mese varchar
)
RETURNS TABLE (
  bil_anno varchar,
  desc_ente varchar,
  data_registrazione date,
  cod_fisc_ente varchar,
  desc_periodo varchar,
  cod_tipo_registro varchar,
  desc_tipo_registro varchar,
  cod_registro varchar,
  desc_registro varchar,
  cod_aliquota_iva varchar,
  desc_aliquota_iva varchar,
  importo_iva_imponibile numeric,
  importo_iva_imposta numeric,
  importo_iva_totale numeric,
  tipo_reg_completa varchar,
  cod_reg_completa varchar,
  aliquota_completa varchar,
  tipo_registro varchar,
  data_emissione date,
  data_prot_def date,
  importo_iva_detraibile numeric,
  importo_iva_indetraibile numeric,
  importo_esente numeric,
  importo_split numeric,
  importo_fuori_campo numeric,
  percent_indetr numeric,
  pro_rata numeric,
  aliquota_perc numeric,
  importo_iva_split numeric,
  importo_detraibile numeric,
  importo_indetraibile numeric
) AS
$body$
DECLARE
classifBilRec record;
elencoRegistriIva record;

mese1 varchar;
anno1 varchar;

annoCapImp varchar;
annoCapImp_int integer;
TipoImpstanz varchar;
tipoImpCassa varchar;
TipoImpstanzresidui varchar;
elemTipoCode varchar;
DEF_NULL	constant varchar:=''; 
RTN_MESSAGGIO varchar(1000):=DEF_NULL;
user_table	varchar;
ricorrente varchar;
v_id_doc integer;
v_tipo_doc varchar;

BEGIN

annoCapImp:= p_anno;
annoCapImp_int:= p_anno::integer;   

TipoImpstanzresidui='SRI'; -- stanziamento residuo iniziale (RS)
TipoImpstanz='STA'; -- stanziamento  (CP)
TipoImpCassa ='SCA'; ----- cassa	(CS)
elemTipoCode:='CAP-EG'; -- tipo capitolo previsione

bil_anno='';
desc_ente='';
data_registrazione=NULL;
cod_fisc_ente='';
desc_periodo='';
cod_tipo_registro='';
desc_tipo_registro='';
cod_registro='';
desc_registro='';
cod_aliquota_iva='';
desc_aliquota_iva='';
importo_iva_imponibile=0;
importo_iva_imposta=0;
importo_iva_totale=0;
tipo_reg_completa='';
cod_reg_completa='';
aliquota_completa='';
tipo_registro='';
data_emissione=NULL;
data_prot_def=NULL;
importo_iva_detraibile=0;
importo_iva_indetraibile=0;
importo_esente=0;
importo_split=0;
importo_fuori_campo=0;
importo_iva_split=0;
percent_indetr=0;
pro_rata=0;
aliquota_perc=0;

RTN_MESSAGGIO:='acquisizione user_table ''.';
select fnc_siac_random_user()
into	user_table;

if p_mese = '12' THEN
	mese1='01';
    anno1=(p_anno ::integer +1) ::varchar;
else 
	mese1=(p_mese ::integer +1) ::varchar;
    anno1=p_anno;
end if;
raise notice 'mese = %, anno = %', mese1,anno1;
raise notice 'DATA A = %', to_timestamp('01/'||mese1||'/'||anno1,'dd/mm/yyyy');
--raise notice 'DATA A meno uno = %', to_timestamp('01/'||mese1||'/'||anno1,'dd/mm/yyyy')-1;
 
RTN_MESSAGGIO:='Estrazione dei dati Registri IVA ''.';

/*
	24/08/2023: Procedura modificata per siac-task issues #153.
    L'estrazione principale e' stata spezzata in 2 parti, una per i documenti di Entrata e l'altra per quelli di Spesa.
    Per le entrate la ricerca oltre che per la data operazione (subdociva_data_prot_def) deve essere effettuata anche
    per la data fattura (doc_data_emissione); entrambe devono rientrare nel mese scelto dall'utente.
    Per le spese la ricerca deve avvenire per la data di quietanza.
*/

FOR elencoRegistriIva IN   
	--collegati a quote documento - ENTRATA   
  select distinct t_subdoc_iva.subdociva_id , t_subdoc_iva.dociva_r_id , t_subdoc_iva.subdociva_data_emissione, t_subdoc_iva.subdociva_numero,
	round(t_ivamov.ivamov_imponibile,2) as ivamov_imponibile, round(t_ivamov.ivamov_imposta,2) as ivamov_imposta, 
    round(t_ivamov.ivamov_totale,2) as ivamov_totale,
    t_iva_aliquota.ivaaliquota_code, t_iva_aliquota.ivaaliquota_desc,
	 t_reg_iva.ivareg_code, t_reg_iva.ivareg_desc,
		d_iva_reg_tipo.ivareg_tipo_code, d_iva_reg_tipo.ivareg_tipo_desc,
        ente_prop.ente_denominazione, ente_prop.codice_fiscale,
        t_subdoc_iva.subdociva_data_emissione data_emissione,
        t_subdoc_iva.subdociva_data_prot_def data_prot_def,
        t_iva_aliquota.ivaaliquota_perc_indetr,
        tipo_oper.ivaop_tipo_code,
        t_iva_aliquota.ivaaliquota_perc,
        prorata.ivapro_perc,
        t_iva_aliquota.ivaaliquota_split
  from siac_t_iva_registro t_reg_iva,
          siac_d_iva_registro_tipo d_iva_reg_tipo,
          siac_t_subdoc_iva t_subdoc_iva,
          siac_r_ivamov r_ivamov,
          siac_t_ivamov t_ivamov,
          siac_t_iva_aliquota t_iva_aliquota,
          siac_t_ente_proprietario ente_prop,
          siac_d_iva_operazione_tipo tipo_oper,
          siac_t_iva_gruppo iva_gruppo,
          siac_r_iva_registro_gruppo riva_gruppo,
          siac_r_iva_gruppo_prorata rprorata,
          siac_t_iva_prorata prorata,
          siac_r_subdoc_subdoc_iva rssi, siac_t_doc td, siac_t_subdoc ts,
          siac_d_doc_tipo doc_tipo, siac_d_doc_fam_tipo doc_fam_tipo
  where  t_reg_iva.ivareg_tipo_id=d_iva_reg_tipo.ivareg_tipo_id
          AND t_subdoc_iva.ivareg_id=t_reg_iva.ivareg_id
          AND r_ivamov.subdociva_id=t_subdoc_iva.subdociva_id
          AND r_ivamov.ivamov_id=t_ivamov.ivamov_id
          AND t_iva_aliquota.ivaaliquota_id=t_ivamov.ivaaliquota_id
          AND ente_prop.ente_proprietario_id=t_reg_iva.ente_proprietario_id		
          AND tipo_oper.ivaop_tipo_id= t_iva_aliquota.ivaop_tipo_id
          AND riva_gruppo.ivareg_id=t_reg_iva.ivareg_id
          AND iva_gruppo.ivagru_id = riva_gruppo.ivagru_id 
          AND rprorata.ivagru_id = iva_gruppo.ivagru_id
          AND prorata.ivapro_id=rprorata.ivapro_id
                  --- AGGIUNTO DA QUI
          AND    rssi.subdociva_id = t_subdoc_iva.subdociva_id
          AND    td.ente_proprietario_id = t_reg_iva.ente_proprietario_id
          AND    rssi.subdoc_id = ts.subdoc_id
          AND    ts.doc_id = td.doc_id
          and td.doc_tipo_id=doc_tipo.doc_tipo_id
          and doc_tipo.doc_fam_tipo_id=doc_fam_tipo.doc_fam_tipo_id
          AND t_reg_iva.ente_proprietario_id=p_ente_prop_id
          AND rprorata.ivagrupro_anno = p_anno::integer
          and doc_fam_tipo.doc_fam_tipo_code ='E' --documenti di entrata
         --AND t_subdoc_iva.subdociva_data_prot_def between  
        -- 	to_timestamp('01/'||p_mese||'/'||p_anno,'dd/mm/yyyy') AND
        --      to_timestamp('01/'||mese1||'/'||anno1,'dd/mm/yyyy')
        --24/08/2023: siac-task issues #153:
        --aggiunto anche il test sulla data di emissione della fattura.
        --13/10/2023: siac-task issues #229:
        --cambio di requisito nel bilr116 per la parte delle fatture attive: deve riportare le fatture attive, riepilogate per 
        --registri, la cui data operazione (e non data fattura come e' ora) ricada nel mese per cui si sta producendo il report.
         AND /*((t_subdoc_iva.subdociva_data_prot_def >=  
       		 to_timestamp('01/'||p_mese||'/'||p_anno,'dd/mm/yyyy') AND
            t_subdoc_iva.subdociva_data_prot_def < to_timestamp('01/'||mese1||'/'||anno1,'dd/mm/yyyy'))  OR
        	(td.doc_data_emissione >=  
       	     to_timestamp('01/'||p_mese||'/'||p_anno,'dd/mm/yyyy') AND
        	 td.doc_data_emissione < to_timestamp('01/'||mese1||'/'||anno1,'dd/mm/yyyy'))) */ 
             (td.doc_data_operazione >=  
       	     to_timestamp('01/'||p_mese||'/'||p_anno,'dd/mm/yyyy') AND
        	 td.doc_data_operazione < to_timestamp('01/'||mese1||'/'||anno1,'dd/mm/yyyy'))           
         --03/07/2018 SIAC-6275: occorre escludere i registri IVA
         -- con ivareg_flagliquidazioneiva = false
          AND t_reg_iva.ivareg_flagliquidazioneiva = true
          AND t_reg_iva.data_cancellazione IS NULL
          AND d_iva_reg_tipo.data_cancellazione IS NULL    
          AND t_subdoc_iva.data_cancellazione IS NULL 
          AND r_ivamov.data_cancellazione IS NULL
          AND t_ivamov.data_cancellazione IS NULL
          AND riva_gruppo.data_cancellazione is NULL
          AND t_iva_aliquota.data_cancellazione IS NULL
          AND rprorata.data_cancellazione is null
          AND    rssi.data_cancellazione IS NULL
          AND    ts.data_cancellazione IS NULL
          AND    td.data_cancellazione IS NULL
          --AND    p_data BETWEEN rssi.validita_inizio AND COALESCE(rssi.validita_fine, p_data)
          --AND    p_data BETWEEN ts.validita_inizio AND COALESCE(ts.validita_fine, p_data)
          --AND    p_data BETWEEN td.validita_inizio AND COALESCE(td.validita_fine, p_data)
          --AND    t_subdoc_iva.dociva_r_id IS NULL
          /*AND not exists 
          (select 1 from siac_r_doc_iva b
              where b.doc_id = td.doc_id 
              and b.data_cancellazione is null )   */
  /*ORDER BY d_iva_reg_tipo.ivareg_tipo_code, t_reg_iva.ivareg_code,
              t_iva_aliquota.ivaaliquota_code   */       
UNION
	--collegati al documento - ENTRATA
select distinct t_subdoc_iva.subdociva_id , t_subdoc_iva.dociva_r_id , t_subdoc_iva.subdociva_data_emissione, t_subdoc_iva.subdociva_numero,
	round(t_ivamov.ivamov_imponibile,2) as ivamov_imponibile, round(t_ivamov.ivamov_imposta,2) as ivamov_imposta, 
    round(t_ivamov.ivamov_totale,2) as ivamov_totale,
    t_iva_aliquota.ivaaliquota_code, t_iva_aliquota.ivaaliquota_desc,
	 t_reg_iva.ivareg_code, t_reg_iva.ivareg_desc,
		d_iva_reg_tipo.ivareg_tipo_code, d_iva_reg_tipo.ivareg_tipo_desc,
        ente_prop.ente_denominazione, ente_prop.codice_fiscale,
        t_subdoc_iva.subdociva_data_emissione data_emissione,
        t_subdoc_iva.subdociva_data_prot_def data_prot_def,
        t_iva_aliquota.ivaaliquota_perc_indetr,
        tipo_oper.ivaop_tipo_code,
        t_iva_aliquota.ivaaliquota_perc,
        prorata.ivapro_perc,
        t_iva_aliquota.ivaaliquota_split
from siac_t_iva_registro t_reg_iva,
		siac_d_iva_registro_tipo d_iva_reg_tipo,
        siac_t_subdoc_iva t_subdoc_iva,
        siac_r_ivamov r_ivamov,
        siac_t_ivamov t_ivamov,
        siac_t_iva_aliquota t_iva_aliquota,
        siac_t_ente_proprietario ente_prop,
        siac_d_iva_operazione_tipo tipo_oper,
        siac_t_iva_gruppo iva_gruppo,
        siac_r_iva_registro_gruppo riva_gruppo,
        siac_r_iva_gruppo_prorata rprorata,
        siac_t_iva_prorata prorata,
        siac_r_doc_iva rdi, siac_t_doc td,
        siac_d_doc_tipo doc_tipo, siac_d_doc_fam_tipo doc_fam_tipo
where  t_reg_iva.ivareg_tipo_id=d_iva_reg_tipo.ivareg_tipo_id
		AND t_subdoc_iva.ivareg_id=t_reg_iva.ivareg_id
        AND r_ivamov.subdociva_id=t_subdoc_iva.subdociva_id
        AND r_ivamov.ivamov_id=t_ivamov.ivamov_id
        AND t_iva_aliquota.ivaaliquota_id=t_ivamov.ivaaliquota_id
        AND ente_prop.ente_proprietario_id=t_reg_iva.ente_proprietario_id		
        AND tipo_oper.ivaop_tipo_id= t_iva_aliquota.ivaop_tipo_id
        AND riva_gruppo.ivareg_id=t_reg_iva.ivareg_id
        AND iva_gruppo.ivagru_id = riva_gruppo.ivagru_id 
        AND rprorata.ivagru_id = iva_gruppo.ivagru_id
        AND prorata.ivapro_id=rprorata.ivapro_id
                ---- DA QUI
        AND rdi.dociva_r_id = t_subdoc_iva.dociva_r_id
        AND td.ente_proprietario_id = t_reg_iva.ente_proprietario_id
        AND rdi.doc_id = td.doc_id
        and td.doc_tipo_id=doc_tipo.doc_tipo_id
        and doc_tipo.doc_fam_tipo_id=doc_fam_tipo.doc_fam_tipo_id	
        AND t_reg_iva.ente_proprietario_id=p_ente_prop_id
        AND rprorata.ivagrupro_anno = p_anno::integer
       --AND t_subdoc_iva.subdociva_data_prot_def between  
      -- 	to_timestamp('01/'||p_mese||'/'||p_anno,'dd/mm/yyyy') AND
      --      to_timestamp('01/'||mese1||'/'||anno1,'dd/mm/yyyy')
      	--24/08/2023: siac-task issues #153:
        --aggiunto anche il test sulla data di emissione della fattura.
		--13/10/2023: siac-task issues #229:
        --cambio di requisito nel bilr116 per la parte delle fatture attive: deve riportare le fatture attive, riepilogate per 
        --registri, la cui data operazione (e non data fattura come e' ora) ricada nel mese per cui si sta producendo il report.        
       AND /* ((t_subdoc_iva.subdociva_data_prot_def >=  
       		 to_timestamp('01/'||p_mese||'/'||p_anno,'dd/mm/yyyy') AND
            t_subdoc_iva.subdociva_data_prot_def < to_timestamp('01/'||mese1||'/'||anno1,'dd/mm/yyyy'))  OR
       	(td.doc_data_emissione >=  
       	     to_timestamp('01/'||p_mese||'/'||p_anno,'dd/mm/yyyy') AND
        	 td.doc_data_emissione < to_timestamp('01/'||mese1||'/'||anno1,'dd/mm/yyyy')))  */
              (td.doc_data_operazione >=  
       	     to_timestamp('01/'||p_mese||'/'||p_anno,'dd/mm/yyyy') AND
        	 td.doc_data_operazione < to_timestamp('01/'||mese1||'/'||anno1,'dd/mm/yyyy'))            
       --03/07/2018 SIAC-6275: occorre escludere i registri IVA
       -- con ivareg_flagliquidazioneiva = false
        AND t_reg_iva.ivareg_flagliquidazioneiva = true
        and doc_fam_tipo.doc_fam_tipo_code ='E' --documenti di entrata
        AND t_reg_iva.data_cancellazione IS NULL
        AND d_iva_reg_tipo.data_cancellazione IS NULL    
        AND t_subdoc_iva.data_cancellazione IS NULL 
        AND r_ivamov.data_cancellazione IS NULL
        AND t_ivamov.data_cancellazione IS NULL
        AND riva_gruppo.data_cancellazione is NULL
        AND t_iva_aliquota.data_cancellazione IS NULL
        AND rprorata.data_cancellazione is null
        AND    rdi.data_cancellazione IS NULL
        AND    td.data_cancellazione IS NULL
        --AND    p_data BETWEEN rdi.validita_inizio AND COALESCE(rdi.validita_fine, p_data)
        --AND    p_data BETWEEN ts.validita_inizio AND COALESCE(ts.validita_fine, p_data)
        --AND    p_data BETWEEN td.validita_inizio AND COALESCE(td.validita_fine, p_data)
        AND    t_subdoc_iva.dociva_r_id  IS NOT NULL
        and not exists (select 1 from siac_r_subdoc_subdoc_iva x
   			 where x.data_cancellazione is null and x.validita_fine is null 
             --and x.subdociva_id = t_subdoc_iva.subdociva_id
             and exists   (
             select y.subdoc_id from siac_t_subdoc y
             where y.doc_id=td.doc_id
             and x.subdoc_id = y.subdoc_id
             and y.data_cancellazione is null
  		) )
UNION        
	--collegati a quote documento - SPESA   
  select distinct t_subdoc_iva.subdociva_id , t_subdoc_iva.dociva_r_id , t_subdoc_iva.subdociva_data_emissione, t_subdoc_iva.subdociva_numero,
	round(t_ivamov.ivamov_imponibile,2) as ivamov_imponibile, round(t_ivamov.ivamov_imposta,2) as ivamov_imposta, 
    round(t_ivamov.ivamov_totale,2) as ivamov_totale,
    t_iva_aliquota.ivaaliquota_code, t_iva_aliquota.ivaaliquota_desc,
	 t_reg_iva.ivareg_code, t_reg_iva.ivareg_desc,
		d_iva_reg_tipo.ivareg_tipo_code, d_iva_reg_tipo.ivareg_tipo_desc,
        ente_prop.ente_denominazione, ente_prop.codice_fiscale,
        t_subdoc_iva.subdociva_data_emissione data_emissione,
        t_subdoc_iva.subdociva_data_prot_def data_prot_def,
        t_iva_aliquota.ivaaliquota_perc_indetr,
        tipo_oper.ivaop_tipo_code,
        t_iva_aliquota.ivaaliquota_perc,
        prorata.ivapro_perc,
        t_iva_aliquota.ivaaliquota_split
  from siac_t_iva_registro t_reg_iva,
          siac_d_iva_registro_tipo d_iva_reg_tipo,
          siac_t_subdoc_iva t_subdoc_iva,
          siac_r_ivamov r_ivamov,
          siac_t_ivamov t_ivamov,
          siac_t_iva_aliquota t_iva_aliquota,
          siac_t_ente_proprietario ente_prop,
          siac_d_iva_operazione_tipo tipo_oper,
          siac_t_iva_gruppo iva_gruppo,
          siac_r_iva_registro_gruppo riva_gruppo,
          siac_r_iva_gruppo_prorata rprorata,
          siac_t_iva_prorata prorata,
          siac_r_subdoc_subdoc_iva rssi, siac_t_doc td, siac_t_subdoc ts,
          siac_d_doc_tipo doc_tipo, siac_d_doc_fam_tipo doc_fam_tipo,
          siac_r_subdoc_ordinativo_ts r_sub_ord_ts, 
          siac_t_ordinativo ord, siac_t_ordinativo_ts ord_ts, siac_t_ordinativo_ts_det ord_ts_det,
          siac_d_ordinativo_ts_det_tipo ord_ts_det_tipo, siac_r_ordinativo_stato r_ord_stato,
          siac_d_ordinativo_stato ord_stato 
  where  t_reg_iva.ivareg_tipo_id=d_iva_reg_tipo.ivareg_tipo_id
          AND t_subdoc_iva.ivareg_id=t_reg_iva.ivareg_id
          AND r_ivamov.subdociva_id=t_subdoc_iva.subdociva_id
          AND r_ivamov.ivamov_id=t_ivamov.ivamov_id
          AND t_iva_aliquota.ivaaliquota_id=t_ivamov.ivaaliquota_id
          AND ente_prop.ente_proprietario_id=t_reg_iva.ente_proprietario_id		
          AND tipo_oper.ivaop_tipo_id= t_iva_aliquota.ivaop_tipo_id
          AND riva_gruppo.ivareg_id=t_reg_iva.ivareg_id
          AND iva_gruppo.ivagru_id = riva_gruppo.ivagru_id 
          AND rprorata.ivagru_id = iva_gruppo.ivagru_id
          AND prorata.ivapro_id=rprorata.ivapro_id
                  --- AGGIUNTO DA QUI
          AND    rssi.subdociva_id = t_subdoc_iva.subdociva_id
          AND    td.ente_proprietario_id = t_reg_iva.ente_proprietario_id
          AND    rssi.subdoc_id = ts.subdoc_id
          AND    ts.doc_id = td.doc_id
          and td.doc_tipo_id=doc_tipo.doc_tipo_id
          and doc_tipo.doc_fam_tipo_id=doc_fam_tipo.doc_fam_tipo_id
          and r_sub_ord_ts.subdoc_id=ts.subdoc_id
          and ts.doc_id=td.doc_id
          and ord_ts.ord_ts_id=r_sub_ord_ts.ord_ts_id
          and ord_ts.ord_id=ord.ord_id
          and ord_ts_det.ord_ts_id=ord_ts.ord_ts_id
          and ord_ts_det_tipo.ord_ts_det_tipo_id=ord_ts_det.ord_ts_det_tipo_id
          and r_ord_stato.ord_id=ord.ord_id
          and r_ord_stato.ord_stato_id=ord_stato.ord_stato_id
          AND t_reg_iva.ente_proprietario_id=p_ente_prop_id
          AND rprorata.ivagrupro_anno = p_anno::integer
          and doc_fam_tipo.doc_fam_tipo_code ='S' --documenti di spesa
         --AND t_subdoc_iva.subdociva_data_prot_def between  
        -- 	to_timestamp('01/'||p_mese||'/'||p_anno,'dd/mm/yyyy') AND
        --      to_timestamp('01/'||mese1||'/'||anno1,'dd/mm/yyyy')
        --24/08/2023: siac-task issues #153:
        --Cambiato il test: non subdociva_data_prot_def ma la data di quietanza che è quella in cui e' stato inserito lo stato
        --quietanziato.
        /* AND (t_subdoc_iva.subdociva_data_prot_def >=  
          to_timestamp('01/'||p_mese||'/'||p_anno,'dd/mm/yyyy') AND
          t_subdoc_iva.subdociva_data_prot_def <  
         to_timestamp('01/'||mese1||'/'||anno1,'dd/mm/yyyy'))  */         
         AND (r_ord_stato.validita_inizio >=  
       	 to_timestamp('01/'||p_mese||'/'||p_anno,'dd/mm/yyyy') AND
         r_ord_stato.validita_inizio <  
         to_timestamp('01/'||mese1||'/'||anno1,'dd/mm/yyyy'))
         --24/08/2023: siac-task issues #153:
         --solo quelli Quietanziati
         and ord_stato.ord_stato_code = 'Q'
         --03/07/2018 SIAC-6275: occorre escludere i registri IVA
         -- con ivareg_flagliquidazioneiva = false
          AND t_reg_iva.ivareg_flagliquidazioneiva = true
          AND t_reg_iva.data_cancellazione IS NULL
          AND d_iva_reg_tipo.data_cancellazione IS NULL    
          AND t_subdoc_iva.data_cancellazione IS NULL 
          AND r_ivamov.data_cancellazione IS NULL
          AND t_ivamov.data_cancellazione IS NULL
          AND riva_gruppo.data_cancellazione is NULL
          AND t_iva_aliquota.data_cancellazione IS NULL
          AND rprorata.data_cancellazione is null
          AND    rssi.data_cancellazione IS NULL
          AND    ts.data_cancellazione IS NULL
          AND    td.data_cancellazione IS NULL
          --AND    p_data BETWEEN rssi.validita_inizio AND COALESCE(rssi.validita_fine, p_data)
          --AND    p_data BETWEEN ts.validita_inizio AND COALESCE(ts.validita_fine, p_data)
          --AND    p_data BETWEEN td.validita_inizio AND COALESCE(td.validita_fine, p_data)
          --AND    t_subdoc_iva.dociva_r_id IS NULL
          /*AND not exists 
          (select 1 from siac_r_doc_iva b
              where b.doc_id = td.doc_id 
              and b.data_cancellazione is null )   */
  /*ORDER BY d_iva_reg_tipo.ivareg_tipo_code, t_reg_iva.ivareg_code,
              t_iva_aliquota.ivaaliquota_code   */       
UNION
	--collegati al documento - SPESA
select distinct t_subdoc_iva.subdociva_id , t_subdoc_iva.dociva_r_id , t_subdoc_iva.subdociva_data_emissione, t_subdoc_iva.subdociva_numero,
	round(t_ivamov.ivamov_imponibile,2) as ivamov_imponibile, round(t_ivamov.ivamov_imposta,2) as ivamov_imposta, 
    round(t_ivamov.ivamov_totale,2) as ivamov_totale,
    t_iva_aliquota.ivaaliquota_code, t_iva_aliquota.ivaaliquota_desc,
	 t_reg_iva.ivareg_code, t_reg_iva.ivareg_desc,
		d_iva_reg_tipo.ivareg_tipo_code, d_iva_reg_tipo.ivareg_tipo_desc,
        ente_prop.ente_denominazione, ente_prop.codice_fiscale,
        t_subdoc_iva.subdociva_data_emissione data_emissione,
        t_subdoc_iva.subdociva_data_prot_def data_prot_def,
        t_iva_aliquota.ivaaliquota_perc_indetr,
        tipo_oper.ivaop_tipo_code,
        t_iva_aliquota.ivaaliquota_perc,
        prorata.ivapro_perc,
        t_iva_aliquota.ivaaliquota_split
from siac_t_iva_registro t_reg_iva,
		siac_d_iva_registro_tipo d_iva_reg_tipo,
        siac_t_subdoc_iva t_subdoc_iva,
        siac_r_ivamov r_ivamov,
        siac_t_ivamov t_ivamov,
        siac_t_iva_aliquota t_iva_aliquota,
        siac_t_ente_proprietario ente_prop,
        siac_d_iva_operazione_tipo tipo_oper,
        siac_t_iva_gruppo iva_gruppo,
        siac_r_iva_registro_gruppo riva_gruppo,
        siac_r_iva_gruppo_prorata rprorata,
        siac_t_iva_prorata prorata,
        siac_r_doc_iva rdi, siac_t_doc td,
        siac_d_doc_tipo doc_tipo, siac_d_doc_fam_tipo doc_fam_tipo,
        siac_r_subdoc_ordinativo_ts r_sub_ord_ts, siac_t_subdoc subdoc,
        siac_t_ordinativo ord, siac_t_ordinativo_ts ord_ts, siac_t_ordinativo_ts_det ord_ts_det,
        siac_d_ordinativo_ts_det_tipo ord_ts_det_tipo, siac_r_ordinativo_stato r_ord_stato,
        siac_d_ordinativo_stato ord_stato 
where  t_reg_iva.ivareg_tipo_id=d_iva_reg_tipo.ivareg_tipo_id
		AND t_subdoc_iva.ivareg_id=t_reg_iva.ivareg_id
        AND r_ivamov.subdociva_id=t_subdoc_iva.subdociva_id
        AND r_ivamov.ivamov_id=t_ivamov.ivamov_id
        AND t_iva_aliquota.ivaaliquota_id=t_ivamov.ivaaliquota_id
        AND ente_prop.ente_proprietario_id=t_reg_iva.ente_proprietario_id		
        AND tipo_oper.ivaop_tipo_id= t_iva_aliquota.ivaop_tipo_id
        AND riva_gruppo.ivareg_id=t_reg_iva.ivareg_id
        AND iva_gruppo.ivagru_id = riva_gruppo.ivagru_id 
        AND rprorata.ivagru_id = iva_gruppo.ivagru_id
        AND prorata.ivapro_id=rprorata.ivapro_id
                ---- DA QUI
        AND rdi.dociva_r_id = t_subdoc_iva.dociva_r_id
        AND td.ente_proprietario_id = t_reg_iva.ente_proprietario_id
        AND rdi.doc_id = td.doc_id
        and td.doc_tipo_id=doc_tipo.doc_tipo_id
        and doc_tipo.doc_fam_tipo_id=doc_fam_tipo.doc_fam_tipo_id	
        and r_sub_ord_ts.subdoc_id=subdoc.subdoc_id
        and subdoc.doc_id=td.doc_id
        and ord_ts.ord_ts_id=r_sub_ord_ts.ord_ts_id
        and ord_ts.ord_id=ord.ord_id
        and ord_ts_det.ord_ts_id=ord_ts.ord_ts_id
        and ord_ts_det_tipo.ord_ts_det_tipo_id=ord_ts_det.ord_ts_det_tipo_id
        and r_ord_stato.ord_id=ord.ord_id
        and r_ord_stato.ord_stato_id=ord_stato.ord_stato_id
        AND t_reg_iva.ente_proprietario_id=p_ente_prop_id
        AND rprorata.ivagrupro_anno = p_anno::integer
       --AND t_subdoc_iva.subdociva_data_prot_def between  
      -- 	to_timestamp('01/'||p_mese||'/'||p_anno,'dd/mm/yyyy') AND
      --      to_timestamp('01/'||mese1||'/'||anno1,'dd/mm/yyyy')
        --24/08/2023: siac-task issues #153:
        --Cambiato il test: non subdociva_data_prot_def ma la data di quietanza che è quella in cui e' stato inserito lo stato
        --quietanziato.
    /*   AND (t_subdoc_iva.subdociva_data_prot_def >=  
       	to_timestamp('01/'||p_mese||'/'||p_anno,'dd/mm/yyyy') AND
        t_subdoc_iva.subdociva_data_prot_def <  
       to_timestamp('01/'||mese1||'/'||anno1,'dd/mm/yyyy'))  */
        AND (r_ord_stato.validita_inizio >=  
       	 to_timestamp('01/'||p_mese||'/'||p_anno,'dd/mm/yyyy') AND
         r_ord_stato.validita_inizio <  
         to_timestamp('01/'||mese1||'/'||anno1,'dd/mm/yyyy'))  
         --24/08/2023: siac-task issues #153:
         --solo quelli Quietanziati
       and ord_stato.ord_stato_code = 'Q'
       --03/07/2018 SIAC-6275: occorre escludere i registri IVA
       -- con ivareg_flagliquidazioneiva = false
        AND t_reg_iva.ivareg_flagliquidazioneiva = true
        and doc_fam_tipo.doc_fam_tipo_code ='S' --documenti di spesa
        AND t_reg_iva.data_cancellazione IS NULL
        AND d_iva_reg_tipo.data_cancellazione IS NULL    
        AND t_subdoc_iva.data_cancellazione IS NULL 
        AND r_ivamov.data_cancellazione IS NULL
        AND t_ivamov.data_cancellazione IS NULL
        AND riva_gruppo.data_cancellazione is NULL
        AND t_iva_aliquota.data_cancellazione IS NULL
        AND rprorata.data_cancellazione is null
        AND    rdi.data_cancellazione IS NULL
        AND    td.data_cancellazione IS NULL
        --AND    p_data BETWEEN rdi.validita_inizio AND COALESCE(rdi.validita_fine, p_data)
        --AND    p_data BETWEEN ts.validita_inizio AND COALESCE(ts.validita_fine, p_data)
        --AND    p_data BETWEEN td.validita_inizio AND COALESCE(td.validita_fine, p_data)
        AND    t_subdoc_iva.dociva_r_id  IS NOT NULL
        and subdoc.data_cancellazione IS NULL
        and r_sub_ord_ts.data_cancellazione IS NULL
        and ord.data_cancellazione IS NULL
        and ord_ts.data_cancellazione IS NULL
        and r_ord_stato.data_cancellazione IS NULL
        and r_ord_stato.validita_fine IS NULL
        and not exists (select 1 from siac_r_subdoc_subdoc_iva x
   			 where x.data_cancellazione is null and x.validita_fine is null 
             --and x.subdociva_id = t_subdoc_iva.subdociva_id
             and exists   (
             select y.subdoc_id from siac_t_subdoc y
             where y.doc_id=td.doc_id
             and x.subdoc_id = y.subdoc_id
             and y.data_cancellazione is null
  		) )        
/*ORDER BY d_iva_reg_tipo.ivareg_tipo_code, t_reg_iva.ivareg_code,
			t_iva_aliquota.ivaaliquota_code     */     
loop

--COALESCE(v.titolo_validita_fine, to_timestamp('31/12/'||p_anno,'dd/mm/yyyy'))

select x.* 
into v_id_doc , v_tipo_doc  from (
  SELECT distinct td.doc_id, tipo.doc_tipo_code
  /*INTO   v_doc_anno, v_doc_numero, v_doc_data_emissione,
         v_subdoc_numero,
         v_doc_tipo_id, v_doc_id*/
  FROM   siac_r_subdoc_subdoc_iva rssi, siac_t_doc td, siac_t_subdoc ts, siac_d_doc_tipo tipo
  WHERE  rssi.subdociva_id = elencoRegistriIva.subdociva_id
  AND    td.ente_proprietario_id = p_ente_prop_id
  AND    rssi.subdoc_id = ts.subdoc_id
  AND    ts.doc_id = td.doc_id
  AND	 tipo.doc_tipo_id= td.doc_tipo_id
  AND    rssi.data_cancellazione IS NULL
  AND    ts.data_cancellazione IS NULL
  AND    td.data_cancellazione IS NULL
  --AND    p_data BETWEEN rssi.validita_inizio AND COALESCE(rssi.validita_fine, p_data)
  --AND    p_data BETWEEN ts.validita_inizio AND COALESCE(ts.validita_fine, p_data)
  --AND    p_data BETWEEN td.validita_inizio AND COALESCE(td.validita_fine, p_data)
  AND    elencoRegistriIva.dociva_r_id IS NULL
  UNION 
  SELECT distinct td.doc_id,  tipo.doc_tipo_code
  /*INTO   v_doc_anno, v_doc_numero, v_doc_data_emissione,
         v_subdoc_numero,
         v_doc_tipo_id, v_doc_id*/
  FROM   siac_r_doc_iva rdi, siac_t_doc td, siac_t_subdoc ts, siac_d_doc_tipo tipo
  WHERE  rdi.dociva_r_id = elencoRegistriIva.dociva_r_id 
  AND    td.ente_proprietario_id = p_ente_prop_id
  AND    rdi.doc_id = td.doc_id
  AND    ts.doc_id = td.doc_id
  AND	 tipo.doc_tipo_id= td.doc_tipo_id
  AND    rdi.data_cancellazione IS NULL
  AND    ts.data_cancellazione IS NULL
  AND    td.data_cancellazione IS NULL
  --AND    p_data BETWEEN rdi.validita_inizio AND COALESCE(rdi.validita_fine, p_data)
  --AND    p_data BETWEEN ts.validita_inizio AND COALESCE(ts.validita_fine, p_data)
  --AND    p_data BETWEEN td.validita_inizio AND COALESCE(td.validita_fine, p_data)
  AND    elencoRegistriIva.dociva_r_id  IS NOT NULL
  ) x;

raise notice 'v_id_doc - v_tipo_doc % - %', v_id_doc , v_tipo_doc ; 



bil_anno='';
desc_ente=elencoRegistriIva.ente_denominazione;
data_registrazione=elencoRegistriIva.subdociva_data_emissione;
cod_fisc_ente=elencoRegistriIva.codice_fiscale;
desc_periodo='';
cod_tipo_registro=elencoRegistriIva.ivareg_tipo_code;
desc_tipo_registro=elencoRegistriIva.ivareg_tipo_desc;
cod_registro=elencoRegistriIva.ivareg_code;
desc_registro=elencoRegistriIva.ivareg_desc;
cod_aliquota_iva=elencoRegistriIva.ivaaliquota_code;
desc_aliquota_iva=elencoRegistriIva.ivaaliquota_desc;
importo_iva_imponibile=elencoRegistriIva.ivamov_imponibile;
importo_iva_imposta=elencoRegistriIva.ivamov_imposta;
importo_iva_totale=elencoRegistriIva.ivamov_totale;

tipo_reg_completa=desc_tipo_registro;
cod_reg_completa=desc_registro;
aliquota_completa= desc_aliquota_iva;
data_emissione=elencoRegistriIva.data_emissione;
data_prot_def=elencoRegistriIva.data_prot_def; 


-- CI = CORRISPETTIVI
-- VI = VENDITE IVA IMMEDIATA
-- VD = VENDITE IVA DIFFERITA
-- AI = ACQUISTI IVA IMMEDIATA
-- AD = ACQUISTI IVA DIFFERITA
if cod_tipo_registro = 'CI' OR cod_tipo_registro = 'VI' OR cod_tipo_registro = 'VD' THEN
	tipo_registro='V'; --VENDITE
ELSE
	tipo_registro='A'; --ACQUISTI
END IF;



if v_tipo_doc in ('NCD', 'NCV') and elencoRegistriIva.ivamov_imponibile > 0 
then 
   	importo_iva_imponibile= importo_iva_imponibile*-1;
	importo_iva_imposta=importo_iva_imposta*-1;
	importo_iva_totale=importo_iva_totale*-1;
end if;
       

importo_iva_indetraibile=round((coalesce(importo_iva_imposta,0)/100)*coalesce(elencoRegistriIva.ivaaliquota_perc_indetr,0),2);
importo_iva_detraibile=coalesce(importo_iva_imposta,0) - importo_iva_indetraibile;

importo_indetraibile=round((coalesce(importo_iva_imponibile,0)/100)*coalesce(elencoRegistriIva.ivaaliquota_perc_indetr,0),2);
importo_detraibile=coalesce(importo_iva_imponibile,0) - importo_indetraibile;

importo_esente=0;

if elencoRegistriIva.ivaop_tipo_code = 'ES' then
	importo_esente=importo_iva_imponibile;
end if;

importo_fuori_campo=0;

if elencoRegistriIva.ivaop_tipo_code = 'FCI' then
	importo_fuori_campo=importo_iva_imponibile;
end if;

importo_split=0;
if elencoRegistriIva.ivaaliquota_split = true then
	importo_split=importo_detraibile;
    importo_iva_split=importo_iva_detraibile;
end if;



percent_indetr= elencoRegistriIva.ivaaliquota_perc_indetr;
pro_rata=elencoRegistriIva.ivapro_perc;
aliquota_perc=elencoRegistriIva.ivaaliquota_perc;


return next;

bil_anno='';
desc_ente='';
data_registrazione=NULL;
cod_fisc_ente='';
desc_periodo='';
cod_tipo_registro='';
desc_tipo_registro='';
cod_registro='';
desc_registro='';
cod_aliquota_iva='';
desc_aliquota_iva='';
importo_iva_imponibile=0;
importo_iva_imposta=0;
importo_iva_totale=0;
tipo_reg_completa='';
cod_reg_completa='';
aliquota_completa='';
tipo_registro='';
data_emissione=NULL;
data_prot_def=NULL;
importo_iva_detraibile=0;
importo_iva_indetraibile=0;
importo_esente=0;
importo_split=0;
importo_iva_split=0;
importo_fuori_campo=0;
percent_indetr=0;
pro_rata=0;
aliquota_perc=0;
end loop;




raise notice 'fine OK';
exception
	when no_data_found THEN
		raise notice 'Nessun dato trovato per i registri IVA' ;
		return;
	when others  THEN
 		RAISE EXCEPTION '% Errore : %-%.',RTN_MESSAGGIO,SQLSTATE,substring(SQLERRM from 1 for 500);
        return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
RETURNS NULL ON NULL INPUT
SECURITY INVOKER
PARALLEL UNSAFE
COST 100 ROWS 1000;

ALTER FUNCTION siac."BILR116_Stampa_riepilogo_iva" (p_ente_prop_id integer, p_anno varchar, p_mese varchar)
  OWNER TO siac;


--siac-task issue #229 - Maurizio - FINE.
