/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
-- versione vista creata per enti [Aggiungere all'elenco l'ente] 
-- REGP
-- APL
-- EDISU
create or replace view w_liquid_atti_migr as
select i.anno_esercizio, i.nliq, i.annoimp,
       i.nimp, i.nsubimp,i.importo,
        i.nro_capitolo, i.nro_articolo,
  l.codben,l.progben,l.staoper, l.descri,
        a.annoprov, a.nprov, a.direzione, a.settore,
        a.datareg,a.data_ricezione,a.data_rifiuto,a.nelenco,
        l.flag_fatt, l.cod_interv_class, l.voce_spesa, a.distinta,
        l.cup,l.cig,a.causale_pagam,a.num_pratica
        ,a.cod_titolario
        ,a.anno_titolario
        ,a.dirett_dirig_resp
        ,a.funz_liq
        ,a.fl_fatture,a.fl_dichiaraz,a.fl_doc_giustif,a.fl_estr_copia_prov,a.fl_altro
        ,a.fl_dati_sens, a.datascad,a.causale_sosp,a.datasosp_pag, a.datariat_pag,a.versione,a.note
        ,a.data_complet
from imp_liq i, liquidazioni l, atti_liquid a
where i.nliq = l.nliq and
      i.anno_esercizio = l.anno_esercizio  and
      l.nprov = a.nprov and
      l.annoprov = a.annoprov and
      l.codprov = 'AL' and
      l.direzione = a.direzione and
      l.staoper != 'A';
