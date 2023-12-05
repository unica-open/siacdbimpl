/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
-- 04.11.2015 Sofia -- calcolo di cui impegnato per CRP
create or replace procedure d118_di_cui_gia_impegnato(pAnnoEsercizio       varchar2,
                                                      pCodRes              out number,
                                                      pMsgRes              out varchar2)
IS



begin
  
pCodRes:=0;
 
pMsgRes:='Cancellazione d118_prev_usc_impegnato.'; 

delete d118_prev_usc_impegnato i
where i.anno_creazione = pAnnoEsercizio;

commit;

pMsgRes:='Inserimento d118_prev_usc_impegnato.'; 

insert into d118_prev_usc_impegnato
(
  anno_creazione      ,
  anno_esercizio      ,
  nro_capitolo        ,
  nro_articolo        ,
  gia_impegnato_anno1 ,
  gia_impegnato_anno2 ,
  gia_impegnato_anno3 
)
(select p.anno_creazione, p.anno_esercizio, p.nro_capitolo, p.nro_articolo,
       0, 0, 0
 from previsione_uscita p
 where p.anno_creazione = pAnnoEsercizio and
       p.anno_esercizio = pAnnoEsercizio);
 --order by p.anno_creazione, p.anno_esercizio, p.nro_capitolo, p.nro_articolo);

commit;

pMsgRes:='Aggiornamento d118_prev_usc_impegnato per anno='||pAnnoEsercizio||'.';

update d118_prev_usc_impegnato gi
set gi.gia_impegnato_anno1 = 
    (select nvl(sum(i.impoatt), 0)
     from impegni i
     where i.anno_esercizio = pAnnoEsercizio and i.annoimp = i.anno_esercizio and i.staoper != 'A' and
      gi.nro_capitolo = i.nro_capitolo AND
      gi.nro_articolo = i.nro_articolo AND
      (i.dataemis <= (select t.par_date
                      from tab_parametri t
                      where t.cod_par = '118LI') OR
       (i.dataemis >= to_date('01/01/'||pAnnoEsercizio,'DD/MM/YYYY') AND
        i.dataemis <= (select t.par_date
                      from tab_parametri t
                      where t.cod_par = '118PB') AND
        0 !=
        (select count(*) from d118_impegni_rsr r
         where i.anno_esercizio = r.anno_esercizio and
               i.annoimp = r.annoimp and
               i.nimp = r.nimp
        )
       )
      )
    )
where gi.anno_creazione = pAnnoEsercizio and
      gi.anno_esercizio = pAnnoEsercizio;
      
commit;

pMsgRes:='Aggiornamento d118_prev_usc_impegnato per anno+1='||to_char(to_number(pAnnoEsercizio)+1)||'.';

update d118_prev_usc_impegnato gi
set gi.gia_impegnato_anno2 = 
    (select nvl(sum(i.impoatt), 0)
     from impegni i
     where i.anno_esercizio = to_char(to_number(pAnnoEsercizio) + 1) and i.annoimp = i.anno_esercizio and i.staoper != 'A' and
      gi.nro_capitolo = i.nro_capitolo AND
      gi.nro_articolo = i.nro_articolo AND      
      (i.dataemis <= (select t.par_date
                      from tab_parametri t
                      where t.cod_par = '118LI') OR
       (i.dataemis >= to_date('01/01/'||pAnnoEsercizio,'DD/MM/YYYY') AND
        i.dataemis <= (select t.par_date
                      from tab_parametri t
                      where t.cod_par = '118PB') AND
        0 !=
        (select count(*) from d118_impegni_rsr r
         where i.anno_esercizio = r.anno_esercizio and
               i.annoimp = r.annoimp and
               i.nimp = r.nimp
        )
       )
      )
    )
where gi.anno_creazione = pAnnoEsercizio and
      gi.anno_esercizio = pAnnoEsercizio;      

commit;

pMsgRes:='Aggiornamento d118_prev_usc_impegnato per anno+2='||to_char(to_number(pAnnoEsercizio)+2)||'.';

update d118_prev_usc_impegnato gi
set gi.gia_impegnato_anno3 = 
    (select nvl(sum(i.impoatt), 0)
     from impegni i
     where i.anno_esercizio = to_char(to_number(pAnnoEsercizio) + 2) and i.annoimp = i.anno_esercizio and i.staoper != 'A' and
      gi.nro_capitolo = i.nro_capitolo AND
      gi.nro_articolo = i.nro_articolo AND      
      (i.dataemis <= (select t.par_date
                      from tab_parametri t
                      where t.cod_par = '118LI') OR
       (i.dataemis >= to_date('01/01/'||pAnnoEsercizio,'DD/MM/YYYY') AND
        i.dataemis <= (select t.par_date
                      from tab_parametri t
                      where t.cod_par = '118PB') AND
        0 !=
        (select count(*) from d118_impegni_rsr r
         where i.anno_esercizio = r.anno_esercizio and
               i.annoimp = r.annoimp and
               i.nimp = r.nimp
        )
       )
      )
    )
where gi.anno_creazione = pAnnoEsercizio and
      gi.anno_esercizio = pAnnoEsercizio;   
      
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
