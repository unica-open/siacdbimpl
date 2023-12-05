/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
﻿CREATE OR REPLACE VIEW siac.siac_v_bko_bil_elem_ente(
    ente_proprietario_id,
    ente_denominazione,
    codice_fiscale,
    bil_id,
    bil_desc,
    data_inizio_bil,
    data_fine_bil,
    elem_tipo_code,
    elem_tipo_desc,
    elem_stato_code,
    elem_stato_desc,
    elem_id,
    elem_code,
    elem_code2,
    elem_code3,
    elem_desc,
    elem_desc2,
    elem_id_padre,
    elem_tipo_id,
    ordine,
    livello,
    validita_inizio,
    validita_fine,
    data_creazione,
    data_modifica,
    data_cancellazione,
    login_operazione)
AS
  SELECT ep.ente_proprietario_id,
         ep.ente_denominazione,
         ep.codice_fiscale,
         b.bil_id,
         b.bil_desc,
         tp.data_inizio AS data_inizio_bil,
         tp.data_fine AS data_fine_bil,
         et.elem_tipo_code,
         et.elem_tipo_desc,
         dst.elem_stato_code,
         dst.elem_stato_desc,
         be.elem_id,
         be.elem_code,
         be.elem_code2,
         be.elem_code3,
         be.elem_desc,
         be.elem_desc2,
         be.elem_id_padre,
         be.elem_tipo_id,
         be.ordine,
         be.livello,
         be.validita_inizio,
         be.validita_fine,
         be.data_creazione,
         be.data_modifica,
         be.data_cancellazione,
         be.login_operazione
  FROM siac_t_bil b,
       siac_t_bil_elem be,
       siac_d_bil_elem_tipo et,
       siac_t_ente_proprietario ep,
       siac_t_periodo tp,
       siac_r_bil_elem_stato st,
       siac_d_bil_elem_stato dst
  WHERE b.bil_id = be.bil_id AND
        be.elem_tipo_id = et.elem_tipo_id AND
        ep.ente_proprietario_id = b.ente_proprietario_id AND
        tp.periodo_id = b.periodo_id AND
        st.elem_id = be.elem_id AND
        st.elem_stato_id = dst.elem_stato_id AND
        now() >= st.validita_inizio AND
        now() <= COALESCE(st.validita_fine::timestamp with time zone, now());