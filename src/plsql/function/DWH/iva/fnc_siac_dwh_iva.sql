/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac.fnc_siac_dwh_iva (
  p_ente_proprietario_id integer,
  p_data timestamp
)
RETURNS TABLE (
  esito varchar
) AS
$body$
DECLARE

rec_iva record;
rec_iva_mov record;
rec_subdoc record;

v_ente_proprietario_id INTEGER := null;
v_ente_denominazione VARCHAR := null;
v_subdociva_anno VARCHAR := null;
v_subdociva_numero INTEGER := null;
v_subdociva_data_registrazione TIMESTAMP := null;
v_subdociva_prot_prov VARCHAR := null;
v_subdociva_data_prot_prov TIMESTAMP := null;
v_subdociva_prot_def VARCHAR := null;
v_subdociva_data_prot_def TIMESTAMP := null;
v_doc_anno INTEGER := null;
v_doc_numero VARCHAR := null;
v_doc_tipo_code VARCHAR := null;
v_doc_data_emissione TIMESTAMP := null;
v_soggetto_code VARCHAR := null;
v_subdoc_numero INTEGER := null;
v_doc_fam_tipo_code VARCHAR := null;
v_doc_fam_tipo_desc VARCHAR := null;
v_reg_tipo_code VARCHAR := null;
v_reg_tipo_desc VARCHAR := null; 
v_ivareg_code VARCHAR := null; 
v_ivareg_desc VARCHAR := null; 
v_ivareg_tipo_code VARCHAR := null; 
v_ivareg_tipo_desc VARCHAR := null; 
v_ivaatt_code VARCHAR := null;
v_ivaatt_desc VARCHAR := null;
v_ivamov_imponibile NUMERIC := null;
v_ivamov_imposta NUMERIC := null;
v_ivamov_imp_detraibile NUMERIC(15,2) := null;
v_ivamov_imp_indetraibile NUMERIC(15,2) := null;
v_ivaaliquota_code VARCHAR := null; 
v_ivaaliquota_desc VARCHAR := null; 
v_ivaaliquota_perc NUMERIC := null; 
v_ivaaliquota_perc_indetr NUMERIC := null; 
v_ivaop_tipo_code VARCHAR := null; 
v_ivaop_tipo_desc VARCHAR := null; 
v_ivaaliquota_tipo_code VARCHAR := null;  
v_ivaaliquota_tipo_desc VARCHAR := null;              

v_doc_tipo_id INTEGER := null;
v_doc_id INTEGER := null;
v_subdociva_id INTEGER := null; 
v_ivaatt_id INTEGER := null; 
v_ivareg_id INTEGER := null; 
v_reg_tipo_id INTEGER := null;
v_ivaaliquota_id INTEGER := null;
v_ivaop_tipo_id INTEGER := null; 
v_ivaaliquota_tipo_id INTEGER := null;
v_dociva_r_id INTEGER := null; 

v_user_table varchar;
params varchar;
fnc_eseguita integer;

BEGIN

select count(*) into fnc_eseguita
from siac_dwh_log_elaborazioni
a where 
a.ente_proprietario_id=p_ente_proprietario_id and
a.fnc_elaborazione_inizio >= (now() - interval '13 hours')::timestamp -- non deve esistere  una elaborazione uguale nelle 13 ore che precedono la chimata
and a.fnc_name='fnc_siac_dwh_iva';


-- 13.03.2020 Sofia jira 	SIAC-7513 
fnc_eseguita:=0;

if fnc_eseguita> 0 then

return;

else 

IF p_ente_proprietario_id IS NULL THEN
   RAISE EXCEPTION 'Errore: Parametro Ente Propietario nullo';
   RETURN;
END IF;

IF p_data IS NULL THEN
   p_data := now();
END IF;

select fnc_siac_random_user()
into	v_user_table;

params := p_ente_proprietario_id::varchar||' - '||p_data::varchar;


insert into
siac_dwh_log_elaborazioni (
ente_proprietario_id,
fnc_name ,
fnc_parameters ,
fnc_elaborazione_inizio ,
fnc_user
)
values (
p_ente_proprietario_id,
'fnc_siac_dwh_iva',
params,
clock_timestamp(),
v_user_table
);

esito:= 'Inizio funzione carico dati iva (FNC_SIAC_DWH_IVA) - '||clock_timestamp();
RETURN NEXT;

esito:= '  Inizio eliminazione dati pregressi - '||clock_timestamp();
RETURN NEXT;
DELETE FROM siac.siac_dwh_iva
WHERE ente_proprietario_id = p_ente_proprietario_id;
esito:= '  Fine eliminazione dati pregressi - '||clock_timestamp();
RETURN NEXT;

FOR rec_iva IN
SELECT tep.ente_proprietario_id, tep.ente_denominazione,
       tsi.subdociva_anno, tsi.subdociva_numero, tsi.subdociva_data_registrazione,
       tsi.subdociva_prot_prov, tsi.subdociva_data_prot_prov,
       tsi.subdociva_prot_def, tsi.subdociva_data_prot_def,
       tsi.subdociva_id,
       tsi.ivaatt_id,
       tsi.ivareg_id,
       tsi.reg_tipo_id,
       tsi.dociva_r_id
FROM   siac_t_subdoc_iva tsi, siac_t_ente_proprietario tep
WHERE  tep.ente_proprietario_id = p_ente_proprietario_id
AND    tep.ente_proprietario_id = tsi.ente_proprietario_id
AND    p_data BETWEEN tep.validita_inizio AND COALESCE(tep.validita_fine, p_data)
AND    tep.data_cancellazione IS NULL
AND    p_data BETWEEN tsi.validita_inizio AND COALESCE(tsi.validita_fine, p_data)
AND    tsi.data_cancellazione IS NULL

LOOP

  v_ente_proprietario_id := null;
  v_ente_denominazione := null;
  v_subdociva_anno := null;
  v_subdociva_numero := null;
  v_subdociva_data_registrazione := null;
  v_subdociva_prot_prov := null;
  v_subdociva_data_prot_prov := null;
  v_subdociva_prot_def := null;
  v_subdociva_data_prot_def := null;
  v_subdociva_id := null;
  v_ivaatt_id := null;
  v_ivareg_id := null;
  v_reg_tipo_id := null;
  v_dociva_r_id := null;

  v_ente_proprietario_id := rec_iva.ente_proprietario_id;
  v_ente_denominazione := rec_iva.ente_denominazione;
  v_subdociva_anno := rec_iva.subdociva_anno;
  v_subdociva_numero := rec_iva.subdociva_numero;
  v_subdociva_data_registrazione := rec_iva.subdociva_data_registrazione;
  v_subdociva_prot_prov := rec_iva.subdociva_prot_prov;
  v_subdociva_data_prot_prov := rec_iva.subdociva_data_prot_prov;
  v_subdociva_prot_def := rec_iva.subdociva_prot_def;
  v_subdociva_data_prot_def := rec_iva.subdociva_data_prot_def;
  v_subdociva_id := rec_iva.subdociva_id;
  v_ivaatt_id := rec_iva.ivaatt_id;
  v_ivareg_id := rec_iva.ivareg_id;
  v_reg_tipo_id := rec_iva.reg_tipo_id;
  v_dociva_r_id := rec_iva.dociva_r_id;

  v_reg_tipo_code := null; 
  v_reg_tipo_desc := null;

  SELECT dirt.reg_tipo_code, dirt.reg_tipo_desc
  INTO   v_reg_tipo_code, v_reg_tipo_desc
  FROM   siac_d_iva_registrazione_tipo dirt
  WHERE  dirt.reg_tipo_id = v_reg_tipo_id
  AND    dirt.data_cancellazione IS NULL
  AND    p_data BETWEEN dirt.validita_inizio AND COALESCE(dirt.validita_fine, p_data);

  v_ivareg_code := null;
  v_ivareg_desc := null;
  v_ivareg_tipo_code := null;
  v_ivareg_tipo_desc := null;

  SELECT tir.ivareg_code, tir.ivareg_desc, sdirt.ivareg_tipo_code, sdirt.ivareg_tipo_desc
  INTO  v_ivareg_code, v_ivareg_desc, v_ivareg_tipo_code, v_ivareg_tipo_desc
  FROM  siac_t_iva_registro tir, siac_d_iva_registro_tipo sdirt
  WHERE tir.ivareg_id = v_ivareg_id
  AND   tir.ivareg_tipo_id = sdirt.ivareg_tipo_id
  AND   tir.data_cancellazione IS NULL
  AND   sdirt.data_cancellazione IS NULL
  AND   p_data BETWEEN tir.validita_inizio AND COALESCE(tir.validita_fine, p_data)
  AND   p_data BETWEEN sdirt.validita_inizio AND COALESCE(sdirt.validita_fine, p_data);

  v_ivaatt_code := null;
  v_ivaatt_desc := null;

  SELECT tia.ivaatt_code, tia.ivaatt_desc
  INTO  v_ivaatt_code, v_ivaatt_desc
  FROM  siac_t_iva_attivita tia
  WHERE tia.ivaatt_id = v_ivaatt_id
  AND   tia.data_cancellazione IS NULL
  AND   p_data BETWEEN tia.validita_inizio AND COALESCE(tia.validita_fine, p_data);

  FOR rec_subdoc IN
  SELECT td.doc_anno, td.doc_numero, td.doc_data_emissione, 
         ts.subdoc_numero,
         td.doc_tipo_id, td.doc_id
  /*INTO   v_doc_anno, v_doc_numero, v_doc_data_emissione,
         v_subdoc_numero,
         v_doc_tipo_id, v_doc_id*/
  FROM   siac_r_subdoc_subdoc_iva rssi, siac_t_doc td, siac_t_subdoc ts
  WHERE  rssi.subdociva_id = v_subdociva_id
  AND    td.ente_proprietario_id = p_ente_proprietario_id
  AND    rssi.subdoc_id = ts.subdoc_id
  AND    ts.doc_id = td.doc_id
  AND    rssi.data_cancellazione IS NULL
  AND    ts.data_cancellazione IS NULL
  AND    td.data_cancellazione IS NULL
  AND    p_data BETWEEN rssi.validita_inizio AND COALESCE(rssi.validita_fine, p_data)
  AND    p_data BETWEEN ts.validita_inizio AND COALESCE(ts.validita_fine, p_data)
  AND    p_data BETWEEN td.validita_inizio AND COALESCE(td.validita_fine, p_data)
  AND    v_dociva_r_id IS NULL
  UNION 
  SELECT td.doc_anno, td.doc_numero, td.doc_data_emissione, 
         ts.subdoc_numero,
         td.doc_tipo_id, td.doc_id
  /*INTO   v_doc_anno, v_doc_numero, v_doc_data_emissione,
         v_subdoc_numero,
         v_doc_tipo_id, v_doc_id*/
  FROM   siac_r_doc_iva rdi, siac_t_doc td, siac_t_subdoc ts
  WHERE  rdi.dociva_r_id = v_dociva_r_id
  AND    td.ente_proprietario_id = p_ente_proprietario_id
  AND    rdi.doc_id = td.doc_id
  AND    ts.doc_id = td.doc_id
  AND    rdi.data_cancellazione IS NULL
  AND    ts.data_cancellazione IS NULL
  AND    td.data_cancellazione IS NULL
  AND    p_data BETWEEN rdi.validita_inizio AND COALESCE(rdi.validita_fine, p_data)
  AND    p_data BETWEEN ts.validita_inizio AND COALESCE(ts.validita_fine, p_data)
  AND    p_data BETWEEN td.validita_inizio AND COALESCE(td.validita_fine, p_data)
  AND    v_dociva_r_id IS NOT NULL
		
    LOOP
    	
      v_doc_anno := null;
      v_doc_numero := null;
      v_doc_data_emissione := null;
      v_subdoc_numero := null;
      v_doc_tipo_id := null;
      v_doc_id := null;
      
      v_doc_anno := rec_subdoc.doc_anno;
      v_doc_numero := rec_subdoc.doc_numero;
      v_doc_data_emissione := rec_subdoc.doc_data_emissione;
      v_subdoc_numero := rec_subdoc.subdoc_numero;
      v_doc_tipo_id := rec_subdoc.doc_tipo_id;
      v_doc_id := rec_subdoc.doc_id;

      v_doc_tipo_code := null;
      v_doc_fam_tipo_code := null;
      v_doc_fam_tipo_desc := null;

      SELECT ddt.doc_tipo_code, ddft.doc_fam_tipo_code, ddft.doc_fam_tipo_desc
      INTO   v_doc_tipo_code, v_doc_fam_tipo_code, v_doc_fam_tipo_desc
      FROM   siac_d_doc_tipo ddt, siac_d_doc_fam_tipo ddft
      WHERE  ddt.doc_tipo_id = v_doc_tipo_id
      AND    ddt.doc_fam_tipo_id = ddft.doc_fam_tipo_id
      AND    ddt.data_cancellazione IS NULL
      AND    ddft.data_cancellazione IS NULL
      AND    p_data BETWEEN ddt.validita_inizio AND COALESCE(ddt.validita_fine, p_data)
      AND    p_data BETWEEN ddft.validita_inizio AND COALESCE(ddft.validita_fine, p_data);

      v_soggetto_code := null;

      SELECT ts.soggetto_code
      INTO   v_soggetto_code
      FROM   siac_r_doc_sog srds, siac_t_soggetto ts
      WHERE  srds.doc_id = v_doc_id
      AND    srds.soggetto_id = ts.soggetto_id
      AND    srds.data_cancellazione IS NULL
      AND    ts.data_cancellazione IS NULL
      AND    p_data BETWEEN srds.validita_inizio AND COALESCE(srds.validita_fine, p_data)
      AND    p_data BETWEEN ts.validita_inizio AND COALESCE(ts.validita_fine, p_data);

      
      FOR    rec_iva_mov IN
      SELECT ti.ivamov_imponibile, ti.ivamov_imposta,
             ti.ivaaliquota_id
      FROM   siac_r_ivamov ri, siac_t_ivamov ti
      WHERE  ri.subdociva_id = v_subdociva_id
      AND    ri.ivamov_id = ti.ivamov_id
      AND    ri.data_cancellazione IS NULL
      AND    ti.data_cancellazione IS NULL
      AND    p_data BETWEEN ri.validita_inizio AND COALESCE(ri.validita_fine, p_data)
      AND    p_data BETWEEN ti.validita_inizio AND COALESCE(ti.validita_fine, p_data)
		
        LOOP
          
          v_ivaaliquota_id := null;
          v_ivamov_imponibile := null;
          v_ivamov_imposta := null;
          v_ivamov_imp_detraibile := null;
          v_ivamov_imp_indetraibile := null;

          v_ivamov_imponibile := rec_iva_mov.ivamov_imponibile;
          v_ivamov_imposta := rec_iva_mov.ivamov_imposta;
          v_ivaaliquota_id := rec_iva_mov.ivaaliquota_id;
          
          v_ivaaliquota_code := null; 
          v_ivaaliquota_desc := null; 
          v_ivaaliquota_perc := null; 
          v_ivaaliquota_perc_indetr := null;
          v_ivaop_tipo_id := null; 
          v_ivaaliquota_tipo_id := null;

          SELECT  tia.ivaaliquota_code, tia.ivaaliquota_desc, tia.ivaaliquota_perc, tia.ivaaliquota_perc_indetr,
                  tia.ivaop_tipo_id, tia.ivaaliquota_tipo_id
          INTO    v_ivaaliquota_code, v_ivaaliquota_desc, v_ivaaliquota_perc, v_ivaaliquota_perc_indetr, 
                  v_ivaop_tipo_id, v_ivaaliquota_tipo_id
          FROM    siac_t_iva_aliquota tia
          WHERE   tia.ivaaliquota_id = v_ivaaliquota_id
          AND     tia.data_cancellazione IS NULL;
          --AND     p_data BETWEEN tia.validita_inizio AND COALESCE(tia.validita_fine, p_data);
          
          v_ivamov_imp_indetraibile := (coalesce(v_ivamov_imposta,0)/100)*coalesce(v_ivaaliquota_perc_indetr,0);
          v_ivamov_imp_detraibile := coalesce(v_ivamov_imposta,0) - v_ivamov_imp_indetraibile;
          
          v_ivaop_tipo_code := null;
          v_ivaop_tipo_desc := null;
          
          SELECT   diot.ivaop_tipo_code, diot.ivaop_tipo_desc
          INTO     v_ivaop_tipo_code, v_ivaop_tipo_desc
          FROM     siac_d_iva_operazione_tipo diot       
          WHERE    diot.ivaop_tipo_id = v_ivaop_tipo_id
          AND      diot.data_cancellazione IS NULL;
          --AND      p_data BETWEEN diot.validita_inizio AND COALESCE(diot.validita_fine, p_data);
          
          v_ivaaliquota_tipo_code := null; 
          v_ivaaliquota_tipo_desc := null;
          
          SELECT   diat.ivaaliquota_tipo_code, diat.ivaaliquota_tipo_desc
          INTO     v_ivaaliquota_tipo_code, v_ivaaliquota_tipo_desc
          FROM     siac_d_iva_aliquota_tipo diat
          WHERE    diat.ivaaliquota_tipo_id = v_ivaaliquota_tipo_id
          AND      diat.data_cancellazione IS NULL;
          --AND      p_data BETWEEN diat.validita_inizio AND COALESCE(diat.validita_fine, p_data);  
          
          INSERT INTO siac.siac_dwh_iva
          ( ente_proprietario_id,
            ente_denominazione,
            cod_doc_fam_tipo,
            desc_doc_fam_tipo,
            anno_doc,
            num_doc,
            cod_tipo_doc,
            data_emissione_doc,
            cod_sogg_doc, 
            num_subdoc, 
            anno_subbdoc_iva, 
            num_subdoc_iva,
            data_registrazione_subdoc_iva,
            cod_tipo_registrazione,
            desc_tipo_registrazione,
            cod_tipo_registro_iva,
            desc_tipo_registro_iva,
            cod_registro_iva,
            desc_registro_iva,
            cod_attivita,
            desc_attivita, 
            prot_prov_subdoc_iva,
            data_prot_prov_subdoc_iva,
            prot_def_subdoc_iva,
            data_prot_def_subdoc_iva,
            cod_aliquota_iva,
            desc_aliquota_iva,
            perc_aliquota_iva,
            perc_indetr_aliquota_iva,
            imponibile,
            imposta,
            importo_detraibile,
            importo_indetraibile,
            cod_tipo_oprazione,
            desc_tipo_oprazione,
            cod_tipo_aliquota,
            desc_tipo_aliquota,
            doc_id -- SIAC-5573
          )
          VALUES (v_ente_proprietario_id,
                  v_ente_denominazione,
                  v_doc_fam_tipo_code, 
                  v_doc_fam_tipo_desc,
                  v_doc_anno, 
                  v_doc_numero, 
                  v_doc_tipo_code,
                  v_doc_data_emissione,
                  v_soggetto_code,
                  v_subdoc_numero,
                  v_subdociva_anno,
                  v_subdociva_numero,
                  v_subdociva_data_registrazione,
                  v_reg_tipo_code,
                  v_reg_tipo_desc,
                  v_ivareg_tipo_code,
                  v_ivareg_tipo_desc,
                  v_ivareg_code, 
                  v_ivareg_desc,
                  v_ivaatt_code, 
                  v_ivaatt_desc, 
                  v_subdociva_prot_prov,
                  v_subdociva_data_prot_prov,
                  v_subdociva_prot_def,
                  v_subdociva_data_prot_def,
                  v_ivaaliquota_code, 
                  v_ivaaliquota_desc, 
                  v_ivaaliquota_perc, 
                  v_ivaaliquota_perc_indetr,
                  v_ivamov_imponibile,
                  v_ivamov_imposta,
                  v_ivamov_imp_detraibile,
                  v_ivamov_imp_indetraibile,
                  v_ivaop_tipo_code,
                  v_ivaop_tipo_desc,
                  v_ivaaliquota_tipo_code, 
                  v_ivaaliquota_tipo_desc,
                  v_doc_id -- SIAC-5573
                 );
          END LOOP;
	END LOOP;	    
END LOOP;
esito:= 'Fine funzione carico iva (FNC_SIAC_DWH_IVA) - '||clock_timestamp();
RETURN NEXT;

update siac_dwh_log_elaborazioni  set fnc_elaborazione_fine = clock_timestamp(),
fnc_durata=clock_timestamp()-fnc_elaborazione_inizio
where fnc_user=v_user_table;

end if;

EXCEPTION
WHEN others THEN
  esito:='Funzione carico iva (FNC_SIAC_DWH_IVA) terminata con errori';
  RAISE NOTICE '%-%.',SQLSTATE,SQLERRM;
RETURN;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY DEFINER
COST 100 ROWS 1000;
