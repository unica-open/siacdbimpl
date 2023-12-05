/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
drop VIEW siac.siac_v_dwh_relazione_ordinativi;

create VIEW siac.siac_v_dwh_relazione_ordinativi as
  SELECT a.ente_proprietario_id,
         d.relaz_tipo_code,
         d.relaz_tipo_desc,
         ct.ord_tipo_code AS ord_tipo_da,
         c.ord_anno AS ord_anno_da,
         c.ord_numero AS ord_numero_da,
         bt.ord_tipo_code AS ord_tipo_a,
         b.ord_anno AS ord_anno_a,
         b.ord_numero AS ord_numero_a,
         a.data_creazione AS data_creaz_collegamento,
         a.data_modifica AS ultima_data_mod_collegamento,
         a.validita_fine AS data_fine_collegamento,
         f.anno bil_anno
  FROM siac_r_ordinativo a,
       siac_t_ordinativo b,
       siac_t_ordinativo c,
       siac_d_ordinativo_tipo bt,
       siac_d_ordinativo_tipo ct,
       siac_d_relaz_tipo d,
       siac_t_bil e,siac_t_periodo f
  WHERE a.ord_id_a = b.ord_id AND
        a.ord_id_da = c.ord_id AND
        b.ord_tipo_id = bt.ord_tipo_id AND
        c.ord_tipo_id = ct.ord_tipo_id AND
        d.relaz_tipo_id = a.relaz_tipo_id AND
        a.data_cancellazione IS NULL AND
        b.data_cancellazione IS NULL AND
        c.data_cancellazione IS NULL
        and now() between a.validita_inizio and COALESCE(a.validita_fine,now())
        and e.bil_id=b.bil_id
        and f.periodo_id=e.periodo_id
  ORDER BY a.ente_proprietario_id;