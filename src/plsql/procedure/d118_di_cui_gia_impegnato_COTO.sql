/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
create or replace procedure d118_di_cui_gia_impegnato (pAnnoEsercizio       varchar2,
                                                       pEnte                number,
                                                       pCodRes              out number,
                                                       pMsgRes              out varchar2) is
begin

pCodRes:=0;

pMsgRes:='Cancellazione d118_prev_usc_impegnato.';

delete d118_prev_usc_impegnato i
where i.anno_creazione = pAnnoEsercizio
and   i.ente_proprietario_id=pEnte;

pMsgRes:='Inserimento d118_prev_usc_impegnato.';
insert into D118_PREV_USC_IMPEGNATO
(
  anno_creazione,
  anno_esercizio,
  nro_capitolo,
  nro_articolo,
  numero_ueb,
  gia_impegnato_anno1,
  gia_impegnato_anno2,
  gia_impegnato_anno3,
  ente_proprietario_id
)
(select
 c.anno_esercizio,
 c.anno_creazione,
 c.nro_capitolo,
 c.nro_articolo,
 decode(c.tipofin, 'MB', 1, 'MU', 2) || '0' ||c.Cdc || nvl(c.coel, '0000'),
 0,0,0, pEnte
 from capcdc_uscita c
 where c.anno_esercizio = pAnnoEsercizio);
 commit;

 pMsgRes:='Aggiornamento d118_prev_usc_impegnato per anno='||pAnnoEsercizio||'.';

 update d118_prev_usc_impegnato gi
 set gia_impegnato_anno1  =
 (select  nvl(sum(i1.impoatt),0)
  from impegni i1
  where i1.nro_capitolo   = gi.nro_capitolo
  and   i1.nro_articolo   = gi.nro_articolo
  and   i1.cod_azienda    = 1
  and   i1.staoper != 'A'
  and   i1.annoimp = pAnnoEsercizio
  and   gi.numero_ueb=decode(i1.tipofin, 'MB', 1, 'MU', 2) || '0' ||i1.Cdc || nvl(i1.coel, '0000'))
 where gi.anno_esercizio=pAnnoEsercizio
 and   gi.ente_proprietario_id=pEnte
 and   exists ( select 1 from impegni i1
               where i1.nro_capitolo   = gi.nro_capitolo
               and   i1.nro_articolo   = gi.nro_articolo
               and   i1.cod_azienda    = 1
               and   i1.staoper != 'A'
               and   i1.annoimp = pAnnoEsercizio
               and   gi.numero_ueb=decode(i1.tipofin, 'MB', 1, 'MU', 2) || '0' ||i1.Cdc || nvl(i1.coel, '0000'));
 commit;

 pMsgRes:='Aggiornamento d118_prev_usc_impegnato per anno='||to_char(to_number(pAnnoEsercizio)+1)||'.';

 update d118_prev_usc_impegnato gi
 set gia_impegnato_anno2  =
 (select  nvl(sum(i1.impoatt),0)
  from impegni i1
  where i1.nro_capitolo   = gi.nro_capitolo
  and   i1.nro_articolo   = gi.nro_articolo
  and   i1.cod_azienda    = 1
  and   i1.staoper != 'A'
  and   i1.annoimp = to_char(to_number(pAnnoEsercizio)+1)
  and   gi.numero_ueb=decode(i1.tipofin, 'MB', 1, 'MU', 2) || '0' ||i1.Cdc || nvl(i1.coel, '0000'))
 where gi.anno_esercizio=pAnnoEsercizio
 and   gi.ente_proprietario_id=pEnte
 and   exists ( select 1 from impegni i1
               where i1.nro_capitolo   = gi.nro_capitolo
               and   i1.nro_articolo   = gi.nro_articolo
               and   i1.cod_azienda    = 1
               and   i1.staoper != 'A'
               and   i1.annoimp = to_char(to_number(pAnnoEsercizio)+1)
               and   gi.numero_ueb=decode(i1.tipofin, 'MB', 1, 'MU', 2) || '0' ||i1.Cdc || nvl(i1.coel, '0000'));
 commit;

 pMsgRes:='Aggiornamento d118_prev_usc_impegnato per anno='||to_char(to_number(pAnnoEsercizio)+2)||'.';

 update d118_prev_usc_impegnato gi
 set gia_impegnato_anno3  =
 (select  nvl(sum(i1.impoatt),0)
  from impegni i1
  where i1.nro_capitolo   = gi.nro_capitolo
  and   i1.nro_articolo   = gi.nro_articolo
  and   i1.cod_azienda    = 1
  and   i1.staoper != 'A'
  and   i1.annoimp = to_char(to_number(pAnnoEsercizio)+2)
  and   gi.numero_ueb=decode(i1.tipofin, 'MB', 1, 'MU', 2) || '0' ||i1.Cdc || nvl(i1.coel, '0000'))
 where gi.anno_esercizio=pAnnoEsercizio
 and   gi.ente_proprietario_id=pEnte
 and   exists ( select 1 from impegni i1
               where i1.nro_capitolo   = gi.nro_capitolo
               and   i1.nro_articolo   = gi.nro_articolo
               and   i1.cod_azienda    = 1
               and   i1.staoper != 'A'
               and   i1.annoimp = to_char(to_number(pAnnoEsercizio)+2)
               and   gi.numero_ueb=decode(i1.tipofin, 'MB', 1, 'MU', 2) || '0' ||i1.Cdc || nvl(i1.coel, '0000'));
 commit;

 -- DAVIDE - 03.04.2017 - aggiunte update per ricavare il "di cui" per il 2017, 2018 e 2019 senza
 -- l'importo degli impegni da riaccertamento che sono stati creati dopo il 1/2/2017 - mail G. Fedele del 31 marzo 2017
 -- MODIFICA TEMPORANEA, SOLO PER ANNI ESERCIZIO DAL 2017 AL 2019
 
 pMsgRes:='Aggiornamento d118_prev_usc_impegnato calcolo riaccertato per anno='||pAnnoEsercizio||'.';
 update d118_prev_usc_impegnato gi
    set gi.gia_impegnato_delta_anno1=
                               (select --gi.gia_impegnato_anno1 - 
                                nvl(sum(i1.impoatt),0)
                                from impegni i1
                                 where i1.nro_capitolo = gi.nro_capitolo
                                   and i1.nro_articolo = gi.nro_articolo
                                   and i1.cod_azienda    = 1
                                   and i1.staoper != 'A'
                                   and i1.anno_esercizio = pAnnoEsercizio
                                   and i1.anno_residuo   = pAnnoEsercizio
                                   and i1.nimp_orig >0
                                   and i1.annoimp_orig >0
                                   and i1.data_ins > to_date('01/02/2017','dd/mm/yyyy')
                                   --and i1.anno_esercizio=gi.anno_esercizio
                                   --and gi.anno_creazione=pAnnoEsercizio  ??
                                   and gi.numero_ueb=decode(i1.tipofin, 'MB', 1, 'MU', 2) || '0' ||i1.Cdc || nvl(i1.coel, '0000'))
  where gi.anno_esercizio=pAnnoEsercizio
    and gi.ente_proprietario_id=1
    and exists ( select 1
                 from impegni i1
                  where i1.nro_capitolo   = gi.nro_capitolo
                    and i1.nro_articolo   = gi.nro_articolo
                    and i1.cod_azienda    = 1
                    and i1.staoper != 'A'
                    and i1.anno_esercizio = pAnnoEsercizio
                    and i1.anno_residuo   = pAnnoEsercizio
                    and i1.nimp_orig >0
                    and i1.annoimp_orig >0
                    and i1.data_ins > to_date('01/02/2017','dd/mm/yyyy')
--                    and i1.anno_esercizio=gi.anno_esercizio
                    --and gi.anno_creazione=pAnnoEsercizio ??
                    and gi.numero_ueb=decode(i1.tipofin, 'MB', 1, 'MU', 2) || '0' ||i1.Cdc || nvl(i1.coel, '0000'));

 commit;

 pMsgRes:='Aggiornamento d118_prev_usc_impegnato calcolo riaccertato per anno='||to_char(to_number(pAnnoEsercizio)+1)||'.';

 update d118_prev_usc_impegnato gi
    set gi.gia_impegnato_delta_anno2=
                               (select --gi.gia_impegnato_anno2 - 
                                nvl(sum(i1.impoatt),0)
                                from impegni i1
                                 where i1.nro_capitolo = gi.nro_capitolo
                                   and i1.nro_articolo = gi.nro_articolo
                                   and i1.cod_azienda    = 1
                                   and i1.staoper != 'A'
                                   and i1.anno_esercizio = to_char(to_number(pAnnoEsercizio)+1)
                                   and i1.anno_residuo   = to_char(to_number(pAnnoEsercizio)+1)
                                   and i1.nimp_orig >0
                                   and i1.annoimp_orig >0
                                   and i1.data_ins > to_date('01/02/2017','dd/mm/yyyy')
                                  -- and i1.anno_esercizio=gi.anno_esercizio
                                  -- and gi.anno_creazione=to_char(to_number(pAnnoEsercizio)+1) ??
                                   and gi.numero_ueb=decode(i1.tipofin, 'MB', 1, 'MU', 2) || '0' ||i1.Cdc || nvl(i1.coel, '0000'))
--  where gi.anno_esercizio=to_char(to_number(pAnnoEsercizio)+1)
  where gi.anno_esercizio=pAnnoEsercizio
    and gi.ente_proprietario_id=1
    and exists ( select 1
                 from impegni i1
                  where i1.nro_capitolo   = gi.nro_capitolo
                    and i1.nro_articolo   = gi.nro_articolo
                    and i1.cod_azienda    = 1
                    and i1.staoper != 'A'
                    and i1.anno_esercizio = to_char(to_number(pAnnoEsercizio)+1)
                    and i1.anno_residuo   = to_char(to_number(pAnnoEsercizio)+1)
                    and i1.nimp_orig >0
                    and i1.annoimp_orig >0
                    and i1.data_ins > to_date('01/02/2017','dd/mm/yyyy')
                   -- and i1.anno_esercizio=gi.anno_esercizio
                   -- and gi.anno_creazione=to_char(to_number(pAnnoEsercizio)+1) ??
                    and gi.numero_ueb=decode(i1.tipofin, 'MB', 1, 'MU', 2) || '0' ||i1.Cdc || nvl(i1.coel, '0000'));

 commit;

 pMsgRes:='Aggiornamento d118_prev_usc_impegnato calcolo riaccertato per anno='||to_char(to_number(pAnnoEsercizio)+2)||'.';

 update d118_prev_usc_impegnato gi
    set gi.gia_impegnato_delta_anno3=
                               (select --gi.gia_impegnato_anno3 - 
                                nvl(sum(i1.impoatt),0)
                                from impegni i1
                                 where i1.nro_capitolo = gi.nro_capitolo
                                   and i1.nro_articolo = gi.nro_articolo
                                   and i1.cod_azienda    = 1
                                   and i1.staoper != 'A'
                                   and i1.anno_esercizio = to_char(to_number(pAnnoEsercizio)+2)
                                   and i1.anno_residuo   = to_char(to_number(pAnnoEsercizio)+2)
                                   and i1.nimp_orig >0
                                   and i1.annoimp_orig >0
                                   and i1.data_ins > to_date('01/02/2017','dd/mm/yyyy')
                                 --  and i1.anno_esercizio=gi.anno_esercizio
                                 --  and gi.anno_creazione=to_char(to_number(pAnnoEsercizio)+2) ??
                                   and gi.numero_ueb=decode(i1.tipofin, 'MB', 1, 'MU', 2) || '0' ||i1.Cdc || nvl(i1.coel, '0000'))
--  where gi.anno_esercizio=to_char(to_number(pAnnoEsercizio)+2)
  where gi.anno_esercizio=pAnnoEsercizio
    and gi.ente_proprietario_id=1
    and exists ( select 1
                 from impegni i1
                  where i1.nro_capitolo   = gi.nro_capitolo
                    and i1.nro_articolo   = gi.nro_articolo
                    and i1.cod_azienda    = 1
                    and i1.staoper != 'A'
                    and i1.anno_esercizio = to_char(to_number(pAnnoEsercizio)+2)
                    and i1.anno_residuo   = to_char(to_number(pAnnoEsercizio)+2)
                    and i1.nimp_orig >0
                    and i1.annoimp_orig >0
                    and i1.data_ins > to_date('01/02/2017','dd/mm/yyyy')
                    -- and i1.anno_esercizio=gi.anno_esercizio
                    -- and gi.anno_creazione=to_char(to_number(pAnnoEsercizio)+2) ??
                    and gi.numero_ueb=decode(i1.tipofin, 'MB', 1, 'MU', 2) || '0' ||i1.Cdc || nvl(i1.coel, '0000'));

 commit;
 -- DAVIDE - 03.04.2017 - Fine
 
 pMsgRes:='Aggiornamento d118_prev_usc_impegnato per decurtazione  del riaccertato dal diCuiImpegnato.';
 update  d118_prev_usc_impegnato
 set     gia_impegnato_anno1=gia_impegnato_anno1-gia_impegnato_delta_anno1,
         gia_impegnato_anno2=gia_impegnato_anno2-gia_impegnato_delta_anno2,
         gia_impegnato_anno3=gia_impegnato_anno3-gia_impegnato_delta_anno3
 where anno_esercizio=pAnnoEsercizio
   and ente_proprietario_id=1;
 commit;
 
 pMsgRes      := 'Aggiornamento d118_prev_usc_impegnato terminato.';

exception
when others then
     rollback;
     dbms_output.put_line(pMsgRes || ' Errore ' || SQLCODE || '-' ||
                           SUBSTR(SQLERRM, 1, 100));
     pMsgRes      := pMsgRes || 'Errore ' ||
                        SQLCODE || '-' || SUBSTR(SQLERRM, 1, 100) || '.';
     pCodRes      := -1;

END d118_di_cui_gia_impegnato;
