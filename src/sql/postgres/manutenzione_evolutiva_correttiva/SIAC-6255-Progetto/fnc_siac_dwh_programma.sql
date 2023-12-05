/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
﻿CREATE OR REPLACE FUNCTION fnc_siac_dwh_programma (
  p_ente_proprietario_id integer,
  p_data timestamp
)
RETURNS TABLE (
  esito varchar
) AS
$body$
DECLARE

rec_programma_id record;
rec_classif_id record;
rec_classif_id_attr record;
rec_attr record;
-- Variabili per campi estratti dal cursore rec_programma_id
v_ente_proprietario_id INTEGER := null;
v_ente_denominazione VARCHAR := null;
v_programma_code VARCHAR := null;
v_programma_desc VARCHAR := null;
v_programma_data_gara_aggiudicazione TIMESTAMP := null;
v_programma_data_gara_indizione TIMESTAMP := null;
v_investimento_in_definizione BOOLEAN;
v_programma_stato_code VARCHAR := null;
v_programma_stato_desc VARCHAR := null;
-- Variabili per classificatori non in gerarchia
v_cod_tipo_ambito VARCHAR := null;
v_desc_tipo_ambito VARCHAR := null;
-- Variabili attributo
v_FlagRilevanteFPV VARCHAR := null;
v_ValoreComplessivoProgramma NUMERIC := null;
v_Note VARCHAR := null;
-- Variabili atto amministrativo
v_anno_atto_amministrativo VARCHAR := null;
v_numero_atto_amministrativo INTEGER := null;
v_oggetto_atto_amministrativo VARCHAR := null;
v_note_atto_amministrativo VARCHAR := null;
v_codice_tipo_atto_amministrativo VARCHAR := null;
v_descrizione_tipo_atto_amministrativo VARCHAR := null;
v_descrizione_stato_atto_amministrativo VARCHAR := null;
v_cod_cdr_atto_amministrativo VARCHAR := null;
v_desc_cdr_atto_amministrativo VARCHAR := null;
v_cod_cdc_atto_amministrativo VARCHAR := null;
v_desc_cdc_atto_amministrativo VARCHAR := null;
-- Variabili utili per il caricamento
v_classif_id_part INTEGER := null;
v_classif_id_padre INTEGER := null;
v_classif_code VARCHAR := null;
v_classif_desc VARCHAR := null;
v_classif_tipo_code VARCHAR := null;
v_classif_tipo_desc VARCHAR := null;
v_classif_tipo_id INTEGER := null;
v_conta_ciclo_classif INTEGER := null;
v_programma_id INTEGER := null;
v_attoamm_id INTEGER := null;
v_flag_attributo VARCHAR := null;

-- 29.04.2019 Sofia jira siac-6255
v_programma_responsabile_unico VARCHAR := null;
v_programma_spazi_finanziari   boolean :=  null;
v_programma_anno_bilancio      VARCHAR := null;
v_programma_tipo_code          VARCHAR := null;
v_programma_tipo_desc          VARCHAR := null;
v_programma_affidamento_code   VARCHAR := null;
v_programma_affidamento_desc   VARCHAR := null;


v_user_table varchar;
params varchar;
fnc_eseguita integer;

BEGIN

select count(*) into fnc_eseguita
from siac_dwh_log_elaborazioni
a where
a.ente_proprietario_id=p_ente_proprietario_id and
a.fnc_elaborazione_inizio >= (now() - interval '13 hours')::timestamp -- non deve esistere  una elaborazione uguale nelle 13 ore che precedono la chimata
and a.fnc_name='fnc_siac_dwh_programma';

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
'fnc_siac_dwh_programma',
params,
clock_timestamp(),
v_user_table
);

esito:= 'Inizio funzione carico programmi (FNC_SIAC_DWH_PROGRAMMA) - '||clock_timestamp();
RETURN NEXT;

esito:= '  Inizio eliminazione dati pregressi - '||clock_timestamp();
return next;
DELETE FROM siac.siac_dwh_programma
WHERE ente_proprietario_id = p_ente_proprietario_id;
esito:= '  Fine eliminazione dati pregressi - '||clock_timestamp();
return next;

-- Ciclo per estrarre programma_id
FOR rec_programma_id IN
SELECT tep.ente_proprietario_id, tep.ente_denominazione,
       tp.programma_code, tp.programma_desc, tp.programma_data_gara_aggiudicazione,
       tp.programma_data_gara_indizione, tp.investimento_in_definizione,
       dps.programma_stato_code, dps.programma_stato_desc, tp.programma_id,
       -- 29.04.2019 Sofia jira siac-6255
       tp.programma_responsabile_unico ,
       tp.programma_spazi_finanziari,
       per.anno programma_anno_bilancio,
       tipo.programma_tipo_code,
       tipo.programma_tipo_desc,
       aff.programma_affidamento_code,
       aff.programma_affidamento_desc
FROM siac.siac_t_programma tp
INNER JOIN  siac.siac_t_ente_proprietario tep ON tep.ente_proprietario_id = tp.ente_proprietario_id
INNER JOIN  siac.siac_r_programma_stato rps ON rps.programma_id = tp.programma_id
INNER JOIN  siac.siac_d_programma_stato dps ON dps.programma_stato_id = rps.programma_stato_id
-- 29.04.2019 Sofia jira siac-6255
INNER JOIN siac_d_programma_tipo tipo on ( tipo.programma_tipo_id=tp.programma_tipo_id)
LEFT  JOIN  siac_t_bil bil inner join siac_t_periodo per on (bil.periodo_id=per.periodo_id)
      on ( bil.bil_id=tp.bil_id )
LEFT JOIN  siac_d_programma_affidamento aff on  (aff.programma_affidamento_id=tp.programma_affidamento_id)
WHERE tep.ente_proprietario_id = p_ente_proprietario_id
AND p_data BETWEEN tp.validita_inizio AND COALESCE(tp.validita_fine, p_data)
AND tp.data_cancellazione IS NULL
AND p_data BETWEEN tep.validita_inizio AND COALESCE(tep.validita_fine, p_data)
AND tep.data_cancellazione IS NULL
AND p_data BETWEEN rps.validita_inizio AND COALESCE(rps.validita_fine, p_data)
AND rps.data_cancellazione IS NULL
AND p_data BETWEEN dps.validita_inizio AND COALESCE(dps.validita_fine, p_data)
AND dps.data_cancellazione IS NULL

LOOP

  v_ente_proprietario_id := null;
  v_ente_denominazione := null;
  v_programma_code := null;
  v_programma_desc := null;
  v_programma_data_gara_aggiudicazione := null;
  v_programma_data_gara_indizione := null;
  v_investimento_in_definizione := null;
  v_programma_stato_code := null;
  v_programma_stato_desc := null;
  v_cod_tipo_ambito := null;
  v_desc_tipo_ambito := null;
  v_programma_id := null;
  v_classif_tipo_id := null;

  -- 29.04.2019 Sofia JIRA siac-6255
  v_programma_responsabile_unico  := null;
  v_programma_spazi_finanziari    :=  null;
  v_programma_anno_bilancio       := null;
  v_programma_tipo_code           := null;
  v_programma_tipo_desc           := null;
  v_programma_affidamento_code    := null;
  v_programma_affidamento_desc    := null;

  v_ente_proprietario_id := rec_programma_id.ente_proprietario_id;
  v_ente_denominazione := rec_programma_id.ente_denominazione;
  v_programma_code := rec_programma_id.programma_code;
  v_programma_desc := rec_programma_id.programma_desc;
  v_programma_data_gara_aggiudicazione := rec_programma_id.programma_data_gara_aggiudicazione;
  v_programma_data_gara_indizione := rec_programma_id.programma_data_gara_indizione;
  v_investimento_in_definizione := rec_programma_id.investimento_in_definizione;
  v_programma_stato_code := rec_programma_id.programma_stato_code;
  v_programma_stato_desc := rec_programma_id.programma_stato_desc;

  v_programma_id := rec_programma_id.programma_id;

  -- 29.04.2019 Sofia JIRA siac-6255
  v_programma_responsabile_unico:= rec_programma_id.programma_responsabile_unico;
  v_programma_spazi_finanziari  := rec_programma_id.programma_spazi_finanziari;
  v_programma_anno_bilancio:=rec_programma_id.programma_anno_bilancio;
  v_programma_tipo_code:=rec_programma_id.programma_tipo_code;
  v_programma_tipo_desc:=rec_programma_id.programma_tipo_desc;
  v_programma_affidamento_code:=rec_programma_id.programma_affidamento_code;
  v_programma_affidamento_desc:=rec_programma_id.programma_affidamento_desc;

  esito:= '  Inizio ciclo programma ('||v_programma_id||') - '||clock_timestamp();
  return next;

  -- Sezione per i classificatori legati ai programmi
  esito:= '    Inizio step classificatori per programmi - '||clock_timestamp();
  return next;
  FOR rec_classif_id IN
  SELECT tc.classif_tipo_id, tc.classif_code, tc.classif_desc
  FROM siac.siac_r_programma_class rpc, siac.siac_t_class tc
  WHERE tc.classif_id = rpc.classif_id
  AND   rpc.programma_id = v_programma_id
  AND   rpc.data_cancellazione IS NULL
  AND   tc.data_cancellazione IS NULL
  AND   p_data BETWEEN rpc.validita_inizio AND COALESCE(rpc.validita_fine, p_data)
  AND   p_data BETWEEN tc.validita_inizio AND COALESCE(tc.validita_fine, p_data)

  LOOP

    v_classif_tipo_id :=  rec_classif_id.classif_tipo_id;
    v_classif_code := rec_classif_id.classif_code;
    v_classif_desc := rec_classif_id.classif_desc;

    v_classif_tipo_code := null;

    SELECT dct.classif_tipo_code
    INTO   v_classif_tipo_code
    FROM   siac.siac_d_class_tipo dct
    WHERE  dct.classif_tipo_id = v_classif_tipo_id
    AND    dct.data_cancellazione IS NULL
    AND    p_data BETWEEN dct.validita_inizio AND COALESCE(dct.validita_fine, p_data);

    IF v_classif_tipo_code = 'TIPO_AMBITO' THEN
       v_cod_tipo_ambito  := v_classif_code;
       v_desc_tipo_ambito :=  v_classif_desc;
    END IF;

  END LOOP;
  esito:= '    Fine step classificatori per programmi - '||clock_timestamp();
  return next;

-- Sezione pe gli attributi
v_FlagRilevanteFPV := null;
v_ValoreComplessivoProgramma := null;
v_Note := null;
v_flag_attributo := null;
-- Ciclo per estrarre gli attibuti relativi ad un programma_id
FOR rec_attr IN
SELECT ta.attr_code, dat.attr_tipo_code,
       rpa.tabella_id, rpa.percentuale, rpa."boolean" true_false, rpa.numerico, rpa.testo
FROM   siac.siac_r_programma_attr rpa, siac.siac_t_attr ta, siac.siac_d_attr_tipo dat
WHERE  rpa.attr_id = ta.attr_id
AND    ta.attr_tipo_id = dat.attr_tipo_id
AND    rpa.programma_id = v_programma_id
AND    rpa.data_cancellazione IS NULL
AND    ta.data_cancellazione IS NULL
AND    dat.data_cancellazione IS NULL
AND    p_data BETWEEN rpa.validita_inizio AND COALESCE(rpa.validita_fine, p_data)
AND    p_data BETWEEN ta.validita_inizio AND COALESCE(ta.validita_fine, p_data)
AND    p_data BETWEEN dat.validita_inizio AND COALESCE(dat.validita_fine, p_data)

LOOP

  IF rec_attr.attr_tipo_code = 'X' THEN
     v_flag_attributo := rec_attr.testo::varchar;
  ELSIF rec_attr.attr_tipo_code = 'N' THEN
     v_flag_attributo := rec_attr.numerico::varchar;
  ELSIF rec_attr.attr_tipo_code = 'P' THEN
     v_flag_attributo := rec_attr.percentuale::varchar;
  ELSIF rec_attr.attr_tipo_code = 'B' THEN
     v_flag_attributo := rec_attr.true_false::varchar;
  ELSIF rec_attr.attr_tipo_code = 'T' THEN
     v_flag_attributo := rec_attr.tabella_id::varchar;
  END IF;

  IF rec_attr.attr_code = 'FlagRilevanteFPV' THEN
     v_FlagRilevanteFPV := v_flag_attributo;
  ELSIF rec_attr.attr_code = 'ValoreComplessivoProgramma' THEN
     v_ValoreComplessivoProgramma := v_flag_attributo;
  ELSIF rec_attr.attr_code = 'Note' THEN
     v_Note := v_flag_attributo;
  END IF;

END LOOP;
-- Sezione pe i dati amministrativi
v_anno_atto_amministrativo := null;
v_numero_atto_amministrativo := null;
v_oggetto_atto_amministrativo := null;
v_note_atto_amministrativo := null;
v_codice_tipo_atto_amministrativo := null;
v_descrizione_tipo_atto_amministrativo := null;
v_descrizione_stato_atto_amministrativo := null;
v_cod_cdr_atto_amministrativo := null;
v_desc_cdr_atto_amministrativo := null;
v_cod_cdc_atto_amministrativo := null;
v_desc_cdc_atto_amministrativo := null;
v_attoamm_id := null;
SELECT taa.attoamm_anno, taa.attoamm_numero, taa.attoamm_oggetto, taa.attoamm_note,
       daat.attoamm_tipo_code, daat.attoamm_tipo_desc, daas.attoamm_stato_desc, taa.attoamm_id
INTO   v_anno_atto_amministrativo, v_numero_atto_amministrativo, v_oggetto_atto_amministrativo,
       v_note_atto_amministrativo, v_codice_tipo_atto_amministrativo,
       v_descrizione_tipo_atto_amministrativo, v_descrizione_stato_atto_amministrativo, v_attoamm_id
FROM siac.siac_r_programma_atto_amm rpaa, siac.siac_t_atto_amm taa, siac.siac_r_atto_amm_stato raas, siac.siac_d_atto_amm_stato daas,
     siac.siac_d_atto_amm_tipo daat
WHERE taa.attoamm_id = rpaa.attoamm_id
AND   taa.attoamm_id = raas.attoamm_id
AND   raas.attoamm_stato_id = daas.attoamm_stato_id
AND   taa.attoamm_tipo_id = daat.attoamm_tipo_id
AND   rpaa.programma_id = v_programma_id
AND   rpaa.data_cancellazione IS NULL
AND   taa.data_cancellazione IS NULL
AND   raas.data_cancellazione IS NULL
AND   daas.data_cancellazione IS NULL
AND   daat.data_cancellazione IS NULL
AND   p_data BETWEEN rpaa.validita_inizio AND COALESCE(rpaa.validita_fine, p_data)
AND   p_data BETWEEN taa.validita_inizio AND COALESCE(taa.validita_fine, p_data)
AND   p_data BETWEEN raas.validita_inizio AND COALESCE(raas.validita_fine, p_data)
AND   p_data BETWEEN daas.validita_inizio AND COALESCE(daas.validita_fine, p_data)
AND   p_data BETWEEN daat.validita_inizio AND COALESCE(daat.validita_fine, p_data);

-- Sezione per i classificatori legati agli atti amministrativi
esito:= '    Inizio step classificatori in gerarchia per atti amministrativi - '||clock_timestamp();
return next;
FOR rec_classif_id_attr IN
SELECT raac.classif_id
FROM  siac.siac_r_atto_amm_class raac
WHERE raac.attoamm_id = v_attoamm_id
AND   raac.data_cancellazione IS NULL
AND   p_data BETWEEN raac.validita_inizio AND COALESCE(raac.validita_fine, p_data)

LOOP

  v_conta_ciclo_classif :=0;
  v_classif_id_padre := null;

  -- Loop per RISALIRE la gerarchia di un dato classificatore
  LOOP

      v_classif_code := null;
      v_classif_desc := null;
      v_classif_id_part := null;
      v_classif_tipo_code := null;
      v_classif_tipo_desc := null;

      IF v_conta_ciclo_classif = 0 THEN
         v_classif_id_part := rec_classif_id_attr.classif_id;
      ELSE
         v_classif_id_part := v_classif_id_padre;
      END IF;

      SELECT tc.classif_code, tc.classif_desc, rcft.classif_id_padre, dct.classif_tipo_code, dct.classif_tipo_desc
      INTO   v_classif_code, v_classif_desc, v_classif_id_padre, v_classif_tipo_code, v_classif_tipo_desc
      FROM  siac.siac_r_class_fam_tree rcft, siac.siac_t_class tc, siac.siac_d_class_tipo dct
      WHERE rcft.classif_id = tc.classif_id
      AND   dct.classif_tipo_id = tc.classif_tipo_id
      AND   tc.classif_id = v_classif_id_part
      AND   rcft.data_cancellazione IS NULL
      AND   tc.data_cancellazione IS NULL
      AND   dct.data_cancellazione IS NULL
      AND   p_data BETWEEN rcft.validita_inizio AND COALESCE(rcft.validita_fine, p_data)
      AND   p_data BETWEEN tc.validita_inizio AND COALESCE(tc.validita_fine, p_data)
      AND   p_data BETWEEN dct.validita_inizio AND COALESCE(dct.validita_fine, p_data);

      IF v_classif_tipo_code = 'CDR' THEN
         v_cod_cdr_atto_amministrativo := v_classif_code;
         v_desc_cdr_atto_amministrativo := v_classif_desc;
      ELSIF v_classif_tipo_code = 'CDC' THEN
         v_cod_cdc_atto_amministrativo := v_classif_code;
         v_desc_cdc_atto_amministrativo := v_classif_desc;
      END IF;

      v_conta_ciclo_classif := v_conta_ciclo_classif +1;
      EXIT WHEN v_classif_id_padre IS NULL;

  END LOOP;
END LOOP;
esito:= '    Fine step classificatori in gerarchia per atti amministrativi - '||clock_timestamp();
return next;



  INSERT INTO siac.siac_dwh_programma
  (ente_proprietario_id,
  ente_denominazione,
  cod_programma,
  desc_programma,
  data_aggiudicazione_gara_progr,
  data_indizione_gara_progr,
  investimento_in_def_progr,
  cod_stato_programma,
  desc_stato_programma,
  cod_tipo_ambito,
  desc_tipo_ambito,
  flagrilevante_fpv,
  ValoreComplessivoProgramma,
  note,
  anno_atto_amministrativo,
  num_atto_amministrativo,
  oggetto_atto_amministrativo,
  note_atto_amministrativo,
  cod_tipo_atto_amministrativo,
  desc_tipo_atto_amministrativo,
  desc_stato_atto_amministrativo,
  cod_cdr_atto_amministrativo,
  desc_cdr_atto_amministrativo,
  cod_cdc_atto_amministrativo,
  desc_cdc_atto_amministrativo,
  -- 29.04.2019 Sofia Jira siac-6255
  programma_responsabile_unico,
  programma_spazi_finanziari,
  programma_anno_bilancio,
  programma_tipo_code,
  programma_tipo_desc,
  programma_affidamento_code,
  programma_affidamento_desc
  )
  VALUES (v_ente_proprietario_id,
          v_ente_denominazione,
          v_programma_code,
          v_programma_desc,
          v_programma_data_gara_aggiudicazione,
          v_programma_data_gara_indizione,
          v_investimento_in_definizione,
          v_programma_stato_code,
          v_programma_stato_desc,
          v_cod_tipo_ambito,
          v_desc_tipo_ambito,
          v_FlagRilevanteFPV,
          v_ValoreComplessivoProgramma,
          v_Note,
          v_anno_atto_amministrativo,
          v_numero_atto_amministrativo::varchar,
          v_oggetto_atto_amministrativo,
          v_note_atto_amministrativo,
          v_codice_tipo_atto_amministrativo,
          v_descrizione_tipo_atto_amministrativo,
          v_descrizione_stato_atto_amministrativo,
          v_cod_cdr_atto_amministrativo,
          v_desc_cdr_atto_amministrativo,
          v_cod_cdc_atto_amministrativo,
          v_desc_cdc_atto_amministrativo,
          -- 29.04.2019 Sofia Jira siac-6255
          v_programma_responsabile_unico,
		  v_programma_spazi_finanziari,
		  v_programma_anno_bilancio,
		  v_programma_tipo_code,
	      v_programma_tipo_desc,
          v_programma_affidamento_code,
	      v_programma_affidamento_desc
         );

esito:= '  Fine ciclo programma ('||v_programma_id||') - '||clock_timestamp();
RETURN NEXT;
END LOOP;
esito:= 'Fine funzione carico programmi (FNC_SIAC_DWH_PROGRAMMA) - '||clock_timestamp();
RETURN NEXT;

update siac_dwh_log_elaborazioni  set fnc_elaborazione_fine = clock_timestamp(),
fnc_durata=clock_timestamp()-fnc_elaborazione_inizio
where fnc_user=v_user_table;

end if;

EXCEPTION
WHEN others THEN
  esito:='Funzione carico programmi (FNC_SIAC_DWH_PROGRAMMA) terminata con errori';
  RAISE NOTICE '%-%.',SQLSTATE,SQLERRM;
RETURN;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY DEFINER
COST 100 ROWS 1000;