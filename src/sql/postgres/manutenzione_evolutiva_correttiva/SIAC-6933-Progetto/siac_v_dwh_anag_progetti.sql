/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
drop VIEW siac.siac_v_dwh_anag_progetti;
CREATE OR REPLACE VIEW siac.siac_v_dwh_anag_progetti (
  ente_proprietario_id,
  programma_code,
  programma_desc,
  tipo_progetto_code,
  tipo_progetto_desc,
  programma_stato_code,
  programma_stato_desc,
  attoamm_anno,
  attoamm_numero,
  attoamm_tipo_code,
  attoamm_tipo_desc,
  cod_sac,
  desc_sac,
  investimento_in_definizione,
  programma_data_gara_aggiudicazione,
  programma_data_gara_indizione ,
  FlagRilevanteFPV,
  importo_progetto,
  -- 30.04.2019 Sofia siac-6255
  programma_anno_bilancio,
  programma_tipo_code,
  programma_tipo_desc,
  programma_affidamento_code,
  programma_affidamento_desc,
  programma_responsabile_unico,
  programma_spazi_finanziari,
  -- 20.06.2019 Sofia siac-6933
  programma_cup

)
AS
------------------- ANAGRAFICA PROGETTI
WITH zz AS (
select a.ente_proprietario_id, a.programma_code,
a.programma_desc,
tipo.classif_code as tipo_progetto_code,
tipo.classif_desc as tipo_progetto_desc,
c.programma_stato_code, c.programma_stato_desc,
h.attoamm_anno,
h.attoamm_numero,
daat.attoamm_tipo_code,
daat.attoamm_tipo_desc,
a.investimento_in_definizione,
a.programma_data_gara_aggiudicazione,
a.programma_data_gara_indizione ,
dfpv."boolean" as FlagRilevanteFPV,
dimp.numerico as importo_progetto,
dcup.testo   as programma_cup, -- 20.06.2019 Sofia siac-6933
h.attoamm_id,
-- 30.04.2019 Sofia siac-6255
a.programma_responsabile_unico,
a.programma_spazi_finanziari,
tipop.programma_tipo_code,
tipop.programma_tipo_desc,
aff.programma_affidamento_code,
aff.programma_affidamento_desc,
per.anno programma_anno_bilancio
--,attrimp.attr_code
from siac_t_programma a
  join siac_r_programma_stato b on a.programma_id=b.programma_id
  join siac_d_programma_stato c on b.programma_stato_id=c.programma_stato_id
  join siac_d_programma_tipo tipop on a.programma_tipo_id=tipop.programma_tipo_id -- 30.04.2019 Sofia siac-6255
  left join siac_r_programma_attr dfpv on dfpv.programma_id = a.programma_id
  join siac_t_attr attrfpv on
     ( attrfpv.attr_id=dfpv.attr_id and attrfpv.attr_code ='FlagRilevanteFPV' and dfpv.data_cancellazione is null)
  left join siac_r_programma_attr dimp on dimp.programma_id = a.programma_id
  join siac_t_attr attrimp on
     ( attrimp.attr_id=dimp.attr_id and attrimp.attr_code ='ValoreComplessivoProgramma'
     and dimp.data_cancellazione is null)
  -- 20.06.2019 Sofia siac-6933
  left join siac_r_programma_attr dcup on dcup.programma_id = a.programma_id
  join siac_t_attr attrcup on
     ( attrcup.attr_id=dcup.attr_id and attrcup.attr_code ='cup'
     and dcup.data_cancellazione is null)
  left join siac_r_programma_class rtipo on
     ( rtipo.programma_id = a.programma_id and rtipo.data_cancellazione is NULL)
  left join siac_t_class tipo on
     (tipo.classif_id = rtipo.classif_id)
  left join siac_r_programma_atto_amm ratto on ( ratto.programma_id=a.programma_id and ratto.data_cancellazione is null)
  left JOIN siac_t_atto_amm h ON h.attoamm_id = ratto.attoamm_id
  left JOIN siac_d_atto_amm_tipo daat ON daat.attoamm_tipo_id = h.attoamm_tipo_id
  -- 30.04.2019 Sofia siac-6255
  left join siac_d_programma_affidamento aff on (a.programma_affidamento_id=aff.programma_affidamento_id)
  left join siac_t_bil bil inner join siac_t_periodo per on (per.periodo_id=bil.periodo_id) on (a.bil_id=bil.bil_id)
where a.data_cancellazione is null
and b.data_cancellazione is null
), aa AS (
    SELECT i.attoamm_id, l.classif_id, l.classif_code, l.classif_desc,
            m.classif_tipo_code
    FROM siac_r_atto_amm_class i, siac_t_class l, siac_d_class_tipo m,
            siac_r_class_fam_tree n, siac_t_class_fam_tree o,
            siac_d_class_fam p
    WHERE i.classif_id = l.classif_id AND m.classif_tipo_id = l.classif_tipo_id
        AND n.classif_id = l.classif_id AND n.classif_fam_tree_id = o.classif_fam_tree_id AND o.classif_fam_id = p.classif_fam_id AND p.classif_fam_code::text = '00005'::text AND i.data_cancellazione IS NULL AND l.data_cancellazione IS NULL AND m.data_cancellazione IS NULL AND n.data_cancellazione IS NULL AND o.data_cancellazione IS NULL AND p.data_cancellazione IS NULL
    )
    SELECT
       zz.ente_proprietario_id,
       zz.programma_code,
       zz.programma_desc,
       zz.tipo_progetto_code,
       zz.tipo_progetto_desc,
       zz.programma_stato_code, zz.programma_stato_desc,
       zz.attoamm_anno,
       zz.attoamm_numero,
       zz.attoamm_tipo_code,
       zz.attoamm_tipo_desc,
       aa.classif_code AS cod_sac, aa.classif_desc AS desc_sac,
       zz.investimento_in_definizione,
       zz.programma_data_gara_aggiudicazione,
       zz.programma_data_gara_indizione ,
       zz.FlagRilevanteFPV,
       zz.importo_progetto,
       -- 30.04.2019 Sofia siac-6255
       zz.programma_anno_bilancio,
	   zz.programma_tipo_code,
	   zz.programma_tipo_desc,
	   zz.programma_affidamento_code,
	   zz.programma_affidamento_desc,
	   zz.programma_responsabile_unico,
	   zz.programma_spazi_finanziari,
       zz.programma_cup -- 20.06.2019 Sofia siac-6933

    FROM zz
   LEFT JOIN aa ON zz.attoamm_id = aa.attoamm_id;