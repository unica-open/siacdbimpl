/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/

drop VIEW if exists siac.siac_v_dwh_variazione_bilancio;
CREATE OR REPLACE VIEW siac.siac_v_dwh_variazione_bilancio(
    bil_anno,
    numero_variazione,
    desc_variazione,
    cod_stato_variazione,
    desc_stato_variazione,
    cod_tipo_variazione,
    desc_tipo_variazione,
    anno_atto_amministrativo,
    numero_atto_amministrativo,
    cod_tipo_atto_amministrativo,
    cod_capitolo,
    cod_articolo,
    cod_ueb,
    cod_tipo_capitolo,
    importo,
    tipo_importo,
    anno_variazione,
    attoamm_id,
    ente_proprietario_id,
    cod_sac,
    desc_sac,
    tipo_sac,
    data_definizione, -- 23.06.2020 Sofia SIAC-7684
    -- SIAC-7886 17.02.2021 Sofua
    data_apertura_proposta,
    data_chiusura_proposta,
    cod_sac_proposta,
    desc_sac_proposta,
    tipo_sac_proposta
    )
AS
select  tb.*
from
(
WITH
variaz AS
(
  SELECT p.anno AS bil_anno,
         e.variazione_num AS numero_variazione,
         e.variazione_desc AS desc_variazione,
         d.variazione_stato_tipo_code AS cod_stato_variazione,
         d.variazione_stato_tipo_desc AS desc_stato_variazione,
         f.variazione_tipo_code AS cod_tipo_variazione,
         f.variazione_tipo_desc AS desc_tipo_variazione,
         a.elem_code AS cod_capitolo,
         a.elem_code2 AS cod_articolo,
         a.elem_code3 AS cod_ueb,
         i.elem_tipo_code AS cod_tipo_capitolo,
         b.elem_det_importo AS importo,
         h.elem_det_tipo_desc AS tipo_importo,
         l.anno AS anno_variazione,
         c.attoamm_id,
         a.ente_proprietario_id,
         -- 23.06.2020 Sofia SIAC-7684
         (case when d.variazione_stato_tipo_code='D' then c.validita_inizio
              else null end ) data_definizione,
         -- SIAC-7886 17.02.2021 Sofia
         e.data_apertura_proposta,
         e.data_chiusura_proposta,
         e.classif_id
  FROM siac_t_bil_elem a,
       siac_t_bil_elem_det_var b,
       siac_r_variazione_stato c,
       siac_d_variazione_stato d,
       siac_t_variazione e,
       siac_d_variazione_tipo f,
       siac_t_bil g,
       siac_d_bil_elem_det_tipo h,
       siac_d_bil_elem_tipo i,
       siac_t_periodo l,
       siac_t_periodo p
  WHERE a.elem_id = b.elem_id AND
        c.variazione_stato_id = b.variazione_stato_id AND
        c.variazione_stato_tipo_id = d.variazione_stato_tipo_id AND
        c.variazione_id = e.variazione_id AND
        f.variazione_tipo_id = e.variazione_tipo_id AND
        b.data_cancellazione IS NULL AND
        a.data_cancellazione IS NULL AND
        c.data_cancellazione IS NULL AND
        g.bil_id = e.bil_id AND
        h.elem_det_tipo_id = b.elem_det_tipo_id AND
        i.elem_tipo_id = a.elem_tipo_id AND
        l.periodo_id = b.periodo_id
        AND p.periodo_id = g.periodo_id
),
attoamm as
(
    select
    m.attoamm_id,
    m.attoamm_anno AS anno_atto_amministrativo,
    m.attoamm_numero AS numero_atto_amministrativo,
    q.attoamm_tipo_code AS cod_tipo_atto_amministrativo
    from siac_t_atto_amm m,  siac_d_atto_amm_tipo q
    where
    q.attoamm_tipo_id = m.attoamm_tipo_id
    and
    m.data_cancellazione IS NULL AND
    q.data_cancellazione IS NULL
),
sac AS
(
    SELECT
     i.attoamm_id,
     l.classif_id,
     l.classif_code,
     l.classif_desc,
     m.classif_tipo_code
    FROM  siac_r_atto_amm_class i,
          siac_t_class l,
          siac_d_class_tipo m,
          siac_r_class_fam_tree n,
          siac_t_class_fam_tree o,
          siac_d_class_fam p
    WHERE i.classif_id = l.classif_id AND
          m.classif_tipo_id = l.classif_tipo_id AND
          n.classif_id = l.classif_id AND
          n.classif_fam_tree_id = o.classif_fam_tree_id AND
          o.classif_fam_id = p.classif_fam_id AND
          p.classif_fam_code::text = '00005'::text AND
          i.data_cancellazione IS NULL AND
          l.data_cancellazione IS NULL AND
          n.data_cancellazione IS NULL
),
-- SIAC-7886 17.02.2021 Sofia
str_proposta as
(
select tipo.classif_tipo_code, c.classif_code ,c.classif_desc,c.classif_id
from siac_t_class c,siac_d_class_tipo tipo
where tipo.classif_tipo_code in ('CDC','CDR')
and   c.classif_tipo_Id=tipo.classif_tipo_id
and   c.data_cancellazione is null
)
SELECT
   variaz.bil_anno,
   variaz.numero_variazione,
   variaz.desc_variazione,
   variaz.cod_stato_variazione,
   variaz.desc_stato_variazione,
   variaz.cod_tipo_variazione,
   variaz.desc_tipo_variazione,
   attoamm.anno_atto_amministrativo,
   attoamm.numero_atto_amministrativo,
   attoamm.cod_tipo_atto_amministrativo,
   variaz.cod_capitolo,
   variaz.cod_articolo,
   variaz.cod_ueb,
   variaz.cod_tipo_capitolo,
   variaz.importo,
   variaz.tipo_importo,
   variaz.anno_variazione,
   variaz.attoamm_id,
   variaz.ente_proprietario_id,
   sac.classif_code AS cod_sac,
   sac.classif_desc AS desc_sac,
   sac.classif_tipo_code AS tipo_sac,
   variaz.data_definizione, -- 23.06.2020 Sofia SIAC-7684
    -- SIAC-7886 17.02.2021 Sofia
   variaz.data_apertura_proposta,
   variaz.data_chiusura_proposta,
   str_proposta.classif_code::varchar(200) cod_sac_proposta,
   str_proposta.classif_desc::varchar(500) desc_sac_proposta,
   str_proposta.classif_tipo_code::varchar(200) tipo_sac_proposta
FROM variaz
      left join attoamm on  variaz.attoamm_id = attoamm.attoamm_id
      LEFT JOIN sac ON variaz.attoamm_id = sac.attoamm_id
      -- SIAC-7886 17.02.2021 Sofia
      left join str_proposta on variaz.classif_id=str_proposta.classif_id
) tb
order by tb.ente_proprietario_id, tb.bil_anno, tb.numero_variazione;
alter VIEW siac.siac_v_dwh_variazione_bilancio owner to siac;