/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
﻿CREATE OR REPLACE FUNCTION siac.fnc_siac_dwh_vincolo (
  p_anno_bilancio varchar,
  p_ente_proprietario_id integer,
  p_data timestamp
)
RETURNS TABLE (
  esito varchar
) AS
$body$
DECLARE

rec_vincolo_id record;
rec_attr record;
rec_elem_id record;
-- Variabili per campi estratti dal cursore rec_programma_id
v_ente_proprietario_id INTEGER := null;
v_ente_denominazione VARCHAR := null;
v_anno  VARCHAR := null;
v_vincolo_code VARCHAR := null;
v_vincolo_desc VARCHAR := null;
v_vincolo_stato_code VARCHAR := null;
v_vincolo_stato_desc VARCHAR := null;
-- Variabil genere
v_vincolo_gen_code VARCHAR := null;
v_vincolo_gen_desc VARCHAR := null;
-- Variabili per campi estratti dal cursore rec_elem_id
v_elem_code VARCHAR := null;
v_elem_code2 VARCHAR := null;
v_elem_code3 VARCHAR := null;
v_elem_desc VARCHAR := null;
v_elem_desc2 VARCHAR := null;
v_elem_tipo_code VARCHAR := null;
v_elem_tipo_desc VARCHAR := null;
v_elem_stato_code VARCHAR := null;
v_elem_stato_desc VARCHAR := null;
v_elem_cat_code VARCHAR := null;
v_elem_cat_desc VARCHAR := null;
-- Variabili attributo
v_FlagTrasferimentiVincolati VARCHAR := null;
v_Note VARCHAR := null;
-- Variabili utili per il caricamento
v_vincolo_id INTEGER := null;
v_flag_attributo VARCHAR := null;

v_user_table varchar;
params varchar;

BEGIN

IF p_ente_proprietario_id IS NULL THEN
   RAISE EXCEPTION 'Errore: Parametro Ente Propietario nullo';
   RETURN;
END IF;

IF p_anno_bilancio IS NULL THEN
   RAISE EXCEPTION 'Errore: Parametro Anno di bilancio nullo';
   RETURN;
END IF;

IF p_data IS NULL THEN
   p_data := now();
END IF;

select fnc_siac_random_user()
into	v_user_table;

params := p_anno_bilancio||' - '||p_ente_proprietario_id::varchar||' - '||p_data::varchar;


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
'fnc_siac_dwh_vincolo',
params,
clock_timestamp(),
v_user_table
);

esito:= 'Inizio funzione carico vincoli (FNC_SIAC_DWH_VINCOLO) - '||clock_timestamp();
RETURN NEXT;

esito:= '  Inizio eliminazione dati pregressi - '||clock_timestamp();
return next;
DELETE FROM siac.siac_dwh_vincolo
WHERE ente_proprietario_id = p_ente_proprietario_id
AND   bil_anno = p_anno_bilancio;
esito:= '  Fine eliminazione dati pregressi - '||clock_timestamp();
return next;

-- Ciclo per estrarre vincolo_id
FOR rec_vincolo_id IN
SELECT tep.ente_proprietario_id, tep.ente_denominazione, tp.anno,
       tv.vincolo_code, tv.vincolo_desc,
       dvs.vincolo_stato_code, dvs.vincolo_stato_desc, tv.vincolo_id
FROM siac.siac_t_vincolo tv
INNER JOIN  siac.siac_t_ente_proprietario tep ON tep.ente_proprietario_id = tv.ente_proprietario_id
INNER JOIN  siac.siac_t_periodo tp ON tp.periodo_id = tv.periodo_id
INNER JOIN  siac.siac_r_vincolo_stato rvs ON rvs.vincolo_id = tv.vincolo_id
INNER JOIN  siac.siac_d_vincolo_stato dvs ON dvs.vincolo_stato_id = rvs.vincolo_stato_id
WHERE tep.ente_proprietario_id = p_ente_proprietario_id
AND tp.anno = p_anno_bilancio
AND p_data BETWEEN tv.validita_inizio AND COALESCE(tv.validita_fine, p_data)
AND tv.data_cancellazione IS NULL
AND p_data BETWEEN tep.validita_inizio AND COALESCE(tep.validita_fine, p_data)
AND tep.data_cancellazione IS NULL
AND p_data BETWEEN rvs.validita_inizio AND COALESCE(rvs.validita_fine, p_data)
AND rvs.data_cancellazione IS NULL
AND p_data BETWEEN dvs.validita_inizio AND COALESCE(dvs.validita_fine, p_data)
AND dvs.data_cancellazione IS NULL

LOOP

  v_ente_proprietario_id := null;
  v_ente_denominazione := null;
  v_anno := null;
  v_vincolo_code := null;
  v_vincolo_desc := null;
  v_vincolo_stato_code := null;
  v_vincolo_stato_desc := null;
  v_vincolo_gen_code := null;
  v_vincolo_gen_desc := null;

  v_vincolo_id := null;

  v_ente_proprietario_id := rec_vincolo_id.ente_proprietario_id;
  v_ente_denominazione := rec_vincolo_id.ente_denominazione;
  v_anno := rec_vincolo_id.anno;
  v_vincolo_code := rec_vincolo_id.vincolo_code;
  v_vincolo_desc := rec_vincolo_id.vincolo_desc;
  v_vincolo_stato_code := rec_vincolo_id.vincolo_stato_code;
  v_vincolo_stato_desc := rec_vincolo_id.vincolo_stato_desc;

  v_vincolo_id := rec_vincolo_id.vincolo_id;

  esito:= '  Inizio ciclo vincolo ('||v_vincolo_id||') - '||clock_timestamp();
  return next;

  SELECT dvg.vincolo_gen_code, dvg.vincolo_gen_desc
  INTO  v_vincolo_gen_code, v_vincolo_gen_desc
  FROM  siac.siac_r_vincolo_genere rvg , siac.siac_d_vincolo_genere dvg
  WHERE rvg.vincolo_gen_id = dvg.vincolo_gen_id
  AND   rvg.vincolo_id = v_vincolo_id
  AND 	p_data BETWEEN rvg.validita_inizio AND COALESCE(rvg.validita_fine, p_data)
  AND 	rvg.data_cancellazione IS NULL
  AND 	p_data BETWEEN dvg.validita_inizio AND COALESCE(dvg.validita_fine, p_data)
  AND 	dvg.data_cancellazione IS NULL;

  -- Sezione pe gli attributi
  v_FlagTrasferimentiVincolati := null;
  v_Note := null;
  v_flag_attributo := null;
  -- Ciclo per estrarre gli attibuti relativi ad un vincolo_id
  FOR rec_attr IN
  SELECT ta.attr_code, dat.attr_tipo_code,
         rva.tabella_id, rva.percentuale, rva."boolean" true_false, rva.numerico, rva.testo
  FROM   siac.siac_r_vincolo_attr rva, siac.siac_t_attr ta, siac.siac_d_attr_tipo dat
  WHERE  rva.attr_id = ta.attr_id
  AND    ta.attr_tipo_id = dat.attr_tipo_id
  AND    rva.vincolo_id = v_vincolo_id
  AND    rva.data_cancellazione IS NULL
  AND    ta.data_cancellazione IS NULL
  AND    dat.data_cancellazione IS NULL
  AND    p_data BETWEEN rva.validita_inizio AND COALESCE(rva.validita_fine, p_data)
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

    IF rec_attr.attr_code = 'FlagTrasferimentiVincolati' THEN
       v_FlagTrasferimentiVincolati := v_flag_attributo;
    ELSIF rec_attr.attr_code = 'Note' THEN
       v_Note := v_flag_attributo;
    END IF;

  END LOOP;

  FOR rec_elem_id IN
  SELECT tbe.elem_code, tbe.elem_code2, tbe.elem_code3, tbe.elem_desc, tbe.elem_desc2, dbet.elem_tipo_code, dbet.elem_tipo_desc,
         dbes.elem_stato_code, dbes.elem_stato_desc, dbec.elem_cat_code, dbec.elem_cat_desc,
         tbe.elem_id
  FROM siac.siac_r_vincolo_bil_elem rvbe
  INNER JOIN siac.siac_t_bil_elem tbe ON tbe.elem_id = rvbe.elem_id
  INNER JOIN siac.siac_d_bil_elem_tipo dbet ON dbet.elem_tipo_id = tbe.elem_tipo_id
  INNER JOIN siac.siac_r_bil_elem_stato rbes ON tbe.elem_id = rbes.elem_id
  INNER JOIN siac.siac_d_bil_elem_stato dbes ON dbes.elem_stato_id = rbes.elem_stato_id
  LEFT JOIN  siac.siac_r_bil_elem_categoria rbec ON tbe.elem_id = rbec.elem_id
                                                 AND p_data BETWEEN rbec.validita_inizio AND COALESCE(rbec.validita_fine, p_data)
                                                 AND rbec.data_cancellazione IS NULL
  LEFT JOIN siac.siac_d_bil_elem_categoria dbec ON rbec.elem_cat_id = dbec.elem_cat_id
                                                AND p_data BETWEEN dbec.validita_inizio AND COALESCE(dbec.validita_fine, p_data)
                                                AND dbec.data_cancellazione IS NULL
  WHERE rvbe.vincolo_id = v_vincolo_id
  AND p_data BETWEEN rvbe.validita_inizio AND COALESCE(rvbe.validita_fine, p_data)
  AND rvbe.data_cancellazione IS NULL
  AND p_data BETWEEN tbe.validita_inizio AND COALESCE(tbe.validita_fine, p_data)
  AND tbe.data_cancellazione IS NULL
  AND p_data BETWEEN dbet.validita_inizio AND COALESCE(dbet.validita_fine, p_data)
  AND dbet.data_cancellazione IS NULL
  AND p_data BETWEEN rbes.validita_inizio AND COALESCE(rbes.validita_fine, p_data)
  AND rbes.data_cancellazione IS NULL
  AND p_data BETWEEN dbes.validita_inizio AND COALESCE(dbes.validita_fine, p_data)
  AND dbes.data_cancellazione IS NULL

  LOOP

    v_elem_code := NULL;
    v_elem_code2 := NULL;
    v_elem_code3 := NULL;
    v_elem_desc := NULL;
    v_elem_desc2 := NULL;
    v_elem_tipo_code := NULL;
    v_elem_tipo_desc := NULL;
    v_elem_stato_code := NULL;
    v_elem_stato_desc := NULL;
    v_elem_cat_code := NULL;
    v_elem_cat_desc := NULL;

    v_elem_code := rec_elem_id.elem_code;
    v_elem_code2 := rec_elem_id.elem_code2;
    v_elem_code3 := rec_elem_id.elem_code3;
    v_elem_desc := rec_elem_id.elem_desc;
    v_elem_desc2 := rec_elem_id.elem_desc2;
    v_elem_tipo_code := rec_elem_id.elem_tipo_code;
    v_elem_tipo_desc := rec_elem_id.elem_tipo_desc;
    v_elem_stato_code := rec_elem_id.elem_stato_code;
    v_elem_stato_desc := rec_elem_id.elem_stato_desc;
    v_elem_cat_code := rec_elem_id.elem_cat_code;
    v_elem_cat_desc := rec_elem_id.elem_cat_desc;

    INSERT INTO siac.siac_dwh_vincolo
    (ente_proprietario_id,
    ente_denominazione,
    bil_anno,
    cod_vincolo,
    desc_vincolo,
    cod_stato_vincolo,
    desc_stato_vincolo,
    cod_genere_vincolo,
    desc_genere_vincolo,
    cod_capitolo,
    cod_articolo,
    cod_ueb,
    desc_capitolo,
    desc_articolo,
    cod_tipo_capitolo,
    desc_tipo_capitolo,
    cod_stato_capitolo,
    desc_stato_capitolo,
    cod_classificazione_capitolo,
    desc_classificazione_capitolo,
    flagtrasferimentivincolati,
    note
    )
    VALUES (v_ente_proprietario_id,
            v_ente_denominazione,
            v_anno,
            v_vincolo_code,
            v_vincolo_desc,
            v_vincolo_stato_code,
            v_vincolo_stato_desc,
            v_vincolo_gen_code,
			v_vincolo_gen_desc,
            v_elem_code,
            v_elem_code2,
            v_elem_code3,
            v_elem_desc,
            v_elem_desc2,
            v_elem_tipo_code,
            v_elem_tipo_desc,
            v_elem_stato_code,
            v_elem_stato_desc,
            v_elem_cat_code,
            v_elem_cat_desc,
            v_FlagTrasferimentiVincolati,
            v_Note
           );
  END LOOP;
  esito:= '  Fine ciclo vincolo ('||v_vincolo_id||') - '||clock_timestamp();
  RETURN NEXT;
END LOOP;
esito:= 'Fine funzione carico vincoli (FNC_SIAC_DWH_VINCOLO) - '||clock_timestamp();
RETURN NEXT;

update siac_dwh_log_elaborazioni  set fnc_elaborazione_fine = clock_timestamp(),
fnc_durata=clock_timestamp()-fnc_elaborazione_inizio
where fnc_user=v_user_table;

EXCEPTION
WHEN others THEN
  esito:='Funzione carico vincoli (FNC_SIAC_DWH_VINCOLO) terminata con errori';
  RAISE NOTICE '%-%.',SQLSTATE,SQLERRM;
RETURN;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY DEFINER
COST 100 ROWS 1000;
