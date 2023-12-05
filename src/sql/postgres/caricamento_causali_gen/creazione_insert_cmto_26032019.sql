/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
﻿

select 'INSERT INTO siac_bko_t_caricamento_pdce_conto ( pdce_conto_code,pdce_conto_desc,tipo_operazione,classe_conto,livello,codifica_bil, tipo_conto,conto_foglia,conto_di_legge,conto_codifica_interna,ammortamento,conto_attivo,conto_segno_negativo,ente_proprietario_id ) values ('
            ||quote_nullable(bko.pdce_conto_code)||','
            ||quote_nullable(bko.pdce_conto_desc)||','
            ||quote_nullable(bko.tipo_operazione)||','
            ||quote_nullable(bko.classe_conto)||','
            ||bko.livello||','
            ||quote_nullable(bko.codifica_bil)||','
            ||quote_nullable(bko.tipo_conto)||','
            ||quote_nullable(bko.conto_foglia)||','
            ||quote_nullable(bko.conto_di_legge)||','
            ||quote_nullable(bko.conto_codifica_interna)||','
            ||quote_nullable(bko.ammortamento)||','
            ||quote_nullable(bko.conto_attivo)||','
            ||quote_nullable(bko.conto_segno_negativo)||','
            ||ente.ente_proprietario_id || ');'
from   siac_bko_t_caricamento_pdce_conto bko,
       (select 3 ente_proprietario_id) ente
order by bko.carica_pdce_conto_id


select 'INSERT INTO siac_bko_t_caricamento_causali ( pdc_fin,codice_causale,descrizione_causale,pdc_econ_patr,segno,conto_iva,livelli,tipo_conto, tipo_importo, utilizzo_conto,utilizzo_importo,causale_default, eu, ente_proprietario_id ) values ('
            ||quote_nullable(bko.pdc_fin)||','
            ||quote_nullable(bko.codice_causale)||','
            ||quote_nullable(bko.descrizione_causale)||','
            ||quote_nullable(bko.pdc_econ_patr)||','
            ||quote_nullable(bko.segno)||','
            ||quote_nullable(bko.conto_iva)||','
            ||quote_nullable(bko.livelli)||','
            ||quote_nullable(bko.tipo_conto)||','
            ||quote_nullable(bko.tipo_importo)||','
            ||quote_nullable(bko.utilizzo_conto)||','
            ||quote_nullable(bko.utilizzo_importo)||','
            ||quote_nullable(bko.causale_default)||','
            ||quote_nullable(bko.eu)||','
            ||ente.ente_proprietario_id || ');'
from   siac_bko_t_caricamento_causali bko,
       (select 3 ente_proprietario_id) ente
where bko.caricata=false
order by bko.carica_cau_id

select 'INSERT INTO siac_bko_t_caricamento_causali ( pdc_fin,codice_causale,descrizione_causale,pdc_econ_patr,segno,conto_iva,livelli,tipo_conto, tipo_importo, utilizzo_conto,utilizzo_importo,causale_default, eu, ente_proprietario_id ) values ('
            ||quote_nullable(bko.pdc_fin)||','
            ||quote_nullable(bko.codice_causale)||','
            ||quote_nullable(bko.descrizione_causale)||','
            ||quote_nullable(bko.pdc_econ_patr)||','
            ||quote_nullable(bko.segno)||','
            ||quote_nullable(bko.conto_iva)||','
            ||quote_nullable(bko.livelli)||','
            ||quote_nullable(bko.tipo_conto)||','
            ||quote_nullable(bko.tipo_importo)||','
            ||quote_nullable(bko.utilizzo_conto)||','
            ||quote_nullable(bko.utilizzo_importo)||','
            ||quote_nullable(bko.causale_default)||','
            ||quote_nullable(bko.eu)||','
            ||ente.ente_proprietario_id || ');'
from   siac_bko_t_caricamento_causali bko,
       (select 3 ente_proprietario_id) ente
where bko.caricata=false
order by bko.carica_cau_id

select 'insert into siac_bko_t_causale_evento ( pdc_fin ,codice_causale,tipo_evento,evento,eu ,ente_proprietario_id ) values ('
         ||quote_nullable(bko.pdc_fin)||','
         ||quote_nullable(bko.codice_causale)||','
         ||quote_nullable(bko.tipo_evento)||','
         ||quote_nullable(bko.evento)||','
         ||quote_nullable(bko.eu)||','
         ||ente.ente_proprietario_id || ');'
from  siac_bko_t_causale_evento bko,
       (select 3 ente_proprietario_id) ente
order by bko.carica_cau_ev_id



select 'INSERT INTO siac_bko_t_caricamento_pdce_conto ( pdce_conto_code,pdce_conto_desc,tipo_operazione,classe_conto,livello,codifica_bil, tipo_conto,conto_foglia,conto_di_legge,conto_codifica_interna,ammortamento,conto_attivo,conto_segno_negativo,ente_proprietario_id ) values ('
            ||quote_nullable(bko.pdce_conto_code)||','
            ||quote_nullable(bko.pdce_conto_desc)||','
            ||quote_nullable(bko.tipo_operazione)||','
            ||quote_nullable(bko.classe_conto)||','
            ||bko.livello||','
            ||quote_nullable(bko.codifica_bil)||','
            ||quote_nullable(bko.tipo_conto)||','
            ||quote_nullable(bko.conto_foglia)||','
            ||quote_nullable(bko.conto_di_legge)||','
            ||quote_nullable(bko.conto_codifica_interna)||','
            ||quote_nullable(bko.ammortamento)||','
            ||quote_nullable(bko.conto_attivo)||','
            ||quote_nullable(bko.conto_segno_negativo)||','
            ||ente.ente_proprietario_id || ');'
from   siac_bko_t_caricamento_pdce_conto bko,
       (select 4 ente_proprietario_id
        union
        select 5 ente_proprietario_id
        union
        select 10 ente_proprietario_id
        union
        select 13 ente_proprietario_id
        union
        select 14 ente_proprietario_id
        union
        select 16 ente_proprietario_id
        union
        select 29 ente_proprietario_id
        ) ente
order by ente.ente_proprietario_id, bko.carica_pdce_conto_id

select 'INSERT INTO siac_bko_t_caricamento_pdce_conto ( pdce_conto_code,pdce_conto_desc,tipo_operazione,classe_conto,livello,codifica_bil, tipo_conto,conto_foglia,conto_di_legge,conto_codifica_interna,ammortamento,conto_attivo,conto_segno_negativo,ente_proprietario_id ) select '
            ||quote_nullable(bko.pdce_conto_code)||','
            ||quote_nullable(bko.pdce_conto_desc)||','
            ||quote_nullable(bko.tipo_operazione)||','
            ||quote_nullable(bko.classe_conto)||','
            ||bko.livello||','
            ||quote_nullable(bko.codifica_bil)||','
            ||quote_nullable(bko.tipo_conto)||','
            ||quote_nullable(bko.conto_foglia)||','
            ||quote_nullable(bko.conto_di_legge)||','
            ||quote_nullable(bko.conto_codifica_interna)||','
            ||quote_nullable(bko.ammortamento)||','
            ||quote_nullable(bko.conto_attivo)||','
            ||quote_nullable(bko.conto_segno_negativo)||','
            ||ente.ente_proprietario_id ||
' where not exists ( select 1 from siac_t_pdce_conto conto,siac_d_ambito ambito, siac_d_pdce_conto_tipo tipo
                     where conto.ente_proprietario_id='
                     ||ente.ente_proprietario_id
                     ||' and conto.pdce_conto_code='
                     ||quote_nullable(bko.pdce_conto_code)
                     ||' and conto.pdce_ct_tipo_id=tipo.pdce_ct_tipo_id and tipo.ente_proprietario_id=conto.ente_proprietario_id '
                     ||' and tipo.pdce_ct_tipo_code='
                     ||quote_nullable(bko.tipo_conto)
                     ||' and ambito.ente_proprietario_id=conto.ente_proprietario_id and ambito.ambito_code='
                     ||quote_nullable(bko.ambito)
                     ||' and conto.data_cancellazione is null and conto.validita_fine is null );'
from   siac_bko_t_caricamento_pdce_conto bko,
       (select 4 ente_proprietario_id
        union
        select 5 ente_proprietario_id
        union
        select 10 ente_proprietario_id
        union
        select 13 ente_proprietario_id
        union
        select 14 ente_proprietario_id
        union
        select 16 ente_proprietario_id
        union
        select 29 ente_proprietario_id
        ) ente
order by ente.ente_proprietario_id, bko.carica_pdce_conto_id

select 'INSERT INTO siac_bko_t_caricamento_pdce_conto ( pdce_conto_code,pdce_conto_desc,tipo_operazione,classe_conto,livello,codifica_bil, tipo_conto,conto_foglia,conto_di_legge,conto_codifica_interna,ammortamento,conto_attivo,conto_segno_negativo,ente_proprietario_id ) values ( '
            ||quote_nullable(bko.pdce_conto_code)||','
            ||quote_nullable(bko.pdce_conto_desc)||','
            ||quote_nullable(bko.tipo_operazione)||','
            ||quote_nullable(bko.classe_conto)||','
            ||bko.livello||','
            ||quote_nullable(bko.codifica_bil)||','
            ||quote_nullable(bko.tipo_conto)||','
            ||quote_nullable(bko.conto_foglia)||','
            ||quote_nullable(bko.conto_di_legge)||','
            ||quote_nullable(bko.conto_codifica_interna)||','
            ||quote_nullable(bko.ammortamento)||','
            ||quote_nullable(bko.conto_attivo)||','
            ||quote_nullable(bko.conto_segno_negativo)||','
            ||ente.ente_proprietario_id
            ||' );'
from   siac_bko_t_caricamento_pdce_conto bko,
       (select 4 ente_proprietario_id
        union
        select 5 ente_proprietario_id
        union
        select 10 ente_proprietario_id
        union
        select 13 ente_proprietario_id
        union
        select 14 ente_proprietario_id
        union
        select 16 ente_proprietario_id
        union
        select 29 ente_proprietario_id
        ) ente
order by ente.ente_proprietario_id, bko.carica_pdce_conto_id


select 'INSERT INTO siac_bko_t_caricamento_causali ( pdc_fin,codice_causale,descrizione_causale,pdc_econ_patr,segno,conto_iva,livelli,tipo_conto, tipo_importo, utilizzo_conto,utilizzo_importo,causale_default, eu, ente_proprietario_id ) values ('
            ||quote_nullable(bko.pdc_fin)||','
            ||quote_nullable(bko.codice_causale)||','
            ||quote_nullable(bko.descrizione_causale)||','
            ||quote_nullable(bko.pdc_econ_patr)||','
            ||quote_nullable(bko.segno)||','
            ||quote_nullable(bko.conto_iva)||','
            ||quote_nullable(bko.livelli)||','
            ||quote_nullable(bko.tipo_conto)||','
            ||quote_nullable(bko.tipo_importo)||','
            ||quote_nullable(bko.utilizzo_conto)||','
            ||quote_nullable(bko.utilizzo_importo)||','
            ||quote_nullable(bko.causale_default)||','
            ||quote_nullable(bko.eu)||','
            ||ente.ente_proprietario_id || ');'
from   siac_bko_t_caricamento_causali bko,
       (select 4 ente_proprietario_id
        union
        select 5 ente_proprietario_id
        union
        select 10 ente_proprietario_id
        union
        select 13 ente_proprietario_id
        union
        select 14 ente_proprietario_id
        union
        select 16 ente_proprietario_id
        union
        select 29 ente_proprietario_id) ente
where bko.caricata=false
order by ente.ente_proprietario_id,bko.carica_cau_id


select 'insert into siac_bko_t_causale_evento ( pdc_fin ,codice_causale,tipo_evento,evento,eu ,ente_proprietario_id ) values ('
         ||quote_nullable(bko.pdc_fin)||','
         ||quote_nullable(bko.codice_causale)||','
         ||quote_nullable(bko.tipo_evento)||','
         ||quote_nullable(bko.evento)||','
         ||quote_nullable(bko.eu)||','
         ||ente.ente_proprietario_id || ');'
from  siac_bko_t_causale_evento bko,
       (select 4 ente_proprietario_id
        union
        select 5 ente_proprietario_id
        union
        select 10 ente_proprietario_id
        union
        select 13 ente_proprietario_id
        union
        select 14 ente_proprietario_id
        union
        select 16 ente_proprietario_id
        union
        select 29 ente_proprietario_id) ente
order by ente.ente_proprietario_id, bko.carica_cau_ev_id         ||quote_nullable(bko.tipo_operazione)||','
            ||quote_nullable(bko.classe_conto)||','
            ||bko.livello||','
            ||quote_nullable(bko.codifica_bil)||','
            ||quote_nullable(bko.tipo_conto)||','
            ||quote_nullable(bko.conto_foglia)||','
            ||quote_nullable(bko.conto_di_legge)||','
            ||quote_nullable(bko.conto_codifica_interna)||','
            ||quote_nullable(bko.ammortamento)||','
            ||quote_nullable(bko.conto_attivo)||','
            ||quote_nullable(bko.conto_segno_negativo)||','
            ||ente.ente_proprietario_id ||
' where not exists ( select 1 from siac_t_pdce_conto conto,siac_d_ambito ambito, siac_d_pdce_conto_tipo tipo
                     where conto.ente_proprietario_id='
                     ||ente.ente_proprietario_id
                     ||' and conto.pdce_conto_code='
                     ||quote_nullable(bko.pdce_conto_code)
                     ||' and conto.pdce_ct_tipo_id=tipo.pdce_ct_tipo_id and tipo.ente_proprietario_id=conto.ente_proprietario_id '
                     ||' and tipo.pdce_ct_tipo_code='
                     ||quote_nullable(bko.tipo_conto)
                     ||' and ambito.ente_proprietario_id=conto.ente_proprietario_id and ambito.ambito_code='
                     ||quote_nullable(bko.ambito)
                     ||' and conto.data_cancellazione is null and conto.validita_fine is null );'
from   siac_bko_t_caricamento_pdce_conto bko,
       (select 4 ente_proprietario_id
        union
        select 5 ente_proprietario_id
        union
        select 10 ente_proprietario_id
        union
        select 13 ente_proprietario_id
        union
        select 14 ente_proprietario_id
        union
        select 16 ente_proprietario_id
        union
        select 29 ente_proprietario_id
        ) ente
order by ente.ente_proprietario_id, bko.carica_pdce_conto_id

select 'INSERT INTO siac_bko_t_caricamento_pdce_conto ( pdce_conto_code,pdce_conto_desc,tipo_operazione,classe_conto,livello,codifica_bil, tipo_conto,conto_foglia,conto_di_legge,conto_codifica_interna,ammortamento,conto_attivo,conto_segno_negativo,ente_proprietario_id ) values ( '
            ||quote_nullable(bko.pdce_conto_code)||','
            ||quote_nullable(bko.pdce_conto_desc)||','
            ||quote_nullable(bko.tipo_operazione)||','
            ||quote_nullable(bko.classe_conto)||','
            ||bko.livello||','
            ||quote_nullable(bko.codifica_bil)||','
            ||quote_nullable(bko.tipo_conto)||','
            ||quote_nullable(bko.conto_foglia)||','
            ||quote_nullable(bko.conto_di_legge)||','
            ||quote_nullable(bko.conto_codifica_interna)||','
            ||quote_nullable(bko.ammortamento)||','
            ||quote_nullable(bko.conto_attivo)||','
            ||quote_nullable(bko.conto_segno_negativo)||','
            ||ente.ente_proprietario_id
            ||' );'
from   siac_bko_t_caricamento_pdce_conto bko,
       (select 4 ente_proprietario_id
        union
        select 5 ente_proprietario_id
        union
        select 10 ente_proprietario_id
        union
        select 13 ente_proprietario_id
        union
        select 14 ente_proprietario_id
        union
        select 16 ente_proprietario_id
        union
        select 29 ente_proprietario_id
        ) ente
order by ente.ente_proprietario_id, bko.carica_pdce_conto_id


select 'INSERT INTO siac_bko_t_caricamento_causali ( pdc_fin,codice_causale,descrizione_causale,pdc_econ_patr,segno,conto_iva,livelli,tipo_conto, tipo_importo, utilizzo_conto,utilizzo_importo,causale_default, eu, ente_proprietario_id ) values ('
            ||quote_nullable(bko.pdc_fin)||','
            ||quote_nullable(bko.codice_causale)||','
            ||quote_nullable(bko.descrizione_causale)||','
            ||quote_nullable(bko.pdc_econ_patr)||','
            ||quote_nullable(bko.segno)||','
            ||quote_nullable(bko.conto_iva)||','
            ||quote_nullable(bko.livelli)||','
            ||quote_nullable(bko.tipo_conto)||','
            ||quote_nullable(bko.tipo_importo)||','
            ||quote_nullable(bko.utilizzo_conto)||','
            ||quote_nullable(bko.utilizzo_importo)||','
            ||quote_nullable(bko.causale_default)||','
            ||quote_nullable(bko.eu)||','
            ||ente.ente_proprietario_id || ');'
from   siac_bko_t_caricamento_causali bko,
       (select 4 ente_proprietario_id
        union
        select 5 ente_proprietario_id
        union
        select 10 ente_proprietario_id
        union
        select 13 ente_proprietario_id
        union
        select 14 ente_proprietario_id
        union
        select 16 ente_proprietario_id
        union
        select 29 ente_proprietario_id) ente
where bko.caricata=false
order by ente.ente_proprietario_id,bko.carica_cau_id


select 'insert into siac_bko_t_causale_evento ( pdc_fin ,codice_causale,tipo_evento,evento,eu ,ente_proprietario_id ) values ('
         ||quote_nullable(bko.pdc_fin)||','
         ||quote_nullable(bko.codice_causale)||','
         ||quote_nullable(bko.tipo_evento)||','
         ||quote_nullable(bko.evento)||','
         ||quote_nullable(bko.eu)||','
         ||ente.ente_proprietario_id || ');'
from  siac_bko_t_causale_evento bko,
       (select 4 ente_proprietario_id
        union
        select 5 ente_proprietario_id
        union
        select 10 ente_proprietario_id
        union
        select 13 ente_proprietario_id
        union
        select 14 ente_proprietario_id
        union
        select 16 ente_proprietario_id
        union
        select 29 ente_proprietario_id) ente
order by ente.ente_proprietario_id, bko.carica_cau_ev_id