/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
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

-- istruzioni di insert o quanto necessario per popolare la tabella
-- istruzioni di insert o quanto necessario per popolare la tabella

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
select p.anno_intervento_77, p.anno_ese+1, p.nro_capitolo_77, 0, /*capitoli anno 2016*/
       0, 0, 0
from prev_peg p
where p.anno_intervento_77 = (select anno_eser from contatori) and
      p.anno_ese = (select anno_eser-1 from contatori) and
      p.tipo_int_77='U'
union 
select distinct p.anno_ese+1, p.anno_ese+1, p.nro_capitolo_77, 0, /*capitoli senza anno 2016*/
       0, 0, 0 from prev_peg p where p.anno_capitolo_77>(select anno_eser from contatori) and tipo_int_77='U'
and not exists (select 1 from prev_peg b where p.nro_capitolo_77=b.nro_capitolo_77 
and b.anno_capitolo_77=(select anno_eser from contatori));     

commit;

update d118_prev_usc_impegnato gi
set gi.gia_impegnato_anno1 = 
    (select nvl(sum(i.importo), 0)
     from movimento_consun i
     where  i.anno_intervento = (select anno_eser from contatori) and i.stato = ' ' and i.tipo_mov=1 and i.tipo_cap='U' and 
      gi.nro_capitolo = i.nro_intervento AND
      (i.data_ins_mov <= (select t.data_118li
                      from contatori t
                      ) OR
       (i.data_ins_mov>= to_date('01/01/2016','DD/MM/YYYY') AND
        i.data_ins_mov <= (select t.data_118pb
                      from contatori t
                      ) --AND
        --0 !=
        --(select count(*) from d118_impegni_rsr r
         --where i.anno_esercizio = r.anno_esercizio and
           --    i.annoimp = r.annoimp and
             --  i.nimp = r.nimp
        --)
       )
      )
    )
where gi.anno_creazione = (select anno_eser from contatori) and
      gi.anno_esercizio = (select anno_eser from contatori);
commit;      
      
update d118_prev_usc_impegnato gi
set gi.gia_impegnato_anno2 = 
    (select nvl(sum(i.importo), 0)
     from movimento_consun i
     where  i.anno_intervento = (select anno_eser+1 from contatori) and i.stato = ' ' and i.tipo_mov=1 and i.tipo_cap='U' and 
      gi.nro_capitolo = i.nro_intervento AND
      (i.data_ins_mov <= (select t.data_118li
                      from contatori t
                      ) OR
       (i.data_ins_mov>= to_date('01/01/2016','DD/MM/YYYY') AND
        i.data_ins_mov <= (select t.data_118pb
                      from contatori t
                      ) --AND
        --0 !=
        --(select count(*) from d118_impegni_rsr r
         --where i.anno_esercizio = r.anno_esercizio and
           --    i.annoimp = r.annoimp and
             --  i.nimp = r.nimp
        --)
       )
      )
    )
where gi.anno_creazione = (select anno_eser from contatori) and
      gi.anno_esercizio = (select anno_eser from contatori);
commit;
      
update d118_prev_usc_impegnato gi
set gi.gia_impegnato_anno3 = 
    (select nvl(sum(i.importo), 0)
     from movimento_consun i
     where  i.anno_intervento = (select anno_eser+2 from contatori) and i.stato = ' ' and i.tipo_mov=1 and i.tipo_cap='U' and 
      gi.nro_capitolo = i.nro_intervento AND
      (i.data_ins_mov <= (select t.data_118li
                      from contatori t
                      ) OR
       (i.data_ins_mov>= to_date('01/01/2016','DD/MM/YYYY') AND
        i.data_ins_mov <= (select t.data_118pb
                      from contatori t
                      ) --AND
        --0 !=
        --(select count(*) from d118_impegni_rsr r
         --where i.anno_esercizio = r.anno_esercizio and
           --    i.annoimp = r.annoimp and
             --  i.nimp = r.nimp
        --)
       )
      )
    )
where gi.anno_creazione = (select anno_eser from contatori) and
      gi.anno_esercizio = (select anno_eser from contatori);      

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