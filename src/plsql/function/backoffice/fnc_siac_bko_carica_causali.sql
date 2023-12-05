/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac.fnc_siac_bko_carica_causali (
)
RETURNS TABLE (
  esito varchar
) AS
$body$
/*
Assicurarsi che esistano gli eventi usati da siac_r_evento_causale -->saic_d_evento, siac_d_evento_tipo, siac_d_collegamento_tipo

Per popolare le tabelle di appoggio bko

usare queste formule sui file excel che vengono passati (portare i valori del CONTO_IVA su PDC_ECO_PATR)

-- su excel rimuovere spazi pdc econ pat
=SOSTITUISCI(SOSTITUISCI(E2;CODICE.CARATT(10);"");CODICE.CARATT(13);"")
--su excel, colonna G nulla   incollare formula in colonna V 
=CONCATENA("INSERT INTO siac.bko_t_caricamento_causali(pdc_fin, codice_causale,descrizione_causale,pdc_eco_patr,segno,livelli,tipo_conto, tipoimporto,utilizzoconto,utilizzoimporto,causale_default ) ";"values ('";B2;"','";C2;"','";D2;"','";E2;"','";F2;"','";H2;"','";I2;"','";J2;"','";K2;"','";L2;"','";M2;"');")    
    

*/

DECLARE


BEGIN

--update per non ricaricare causali già presenti
update bko_t_caricamento_causali set caricata = true where codice_causale in
(select z.causale_ep_code from siac_t_causale_ep z);


update bko_t_caricamento_eventi_causali set caricato = true from (
select distinct zz.codice_causale,zz.evento from bko_t_caricamento_eventi_causali zz, bko_t_caricamento_causali yy where
yy.codice_causale=zz.codice_causale and  
(zz.codice_causale,zz.evento,yy.ambito) in (
select 
       distinct c.causale_ep_code,a.evento_code,e.ambito_code
from siac_d_evento a,
     siac_d_evento_tipo b,
     siac_t_causale_ep c, bko_t_caricamento_eventi_causali d,siac_d_ambito e
where a.evento_tipo_id = b.evento_tipo_id and
      c.ente_proprietario_id = b.ente_proprietario_id and
      a.evento_code=d.evento and
      b.evento_tipo_code = d.tipo_evento and
      c.causale_ep_code = d.codice_causale 
      and e.ambito_id=c.ambito_id
      and exists (
                   select 1
                   from siac_r_evento_causale z
                   where z.evento_id = a.evento_id and
                         z.causale_ep_id = c.causale_ep_id
      )
      )
      ) as subquery 
      where bko_t_caricamento_eventi_causali.codice_causale=subquery.codice_causale
      and bko_t_caricamento_eventi_causali.evento=subquery.evento
      ;
      

update  bko_t_caricamento_causali set segno=upper(segno);
update  bko_t_caricamento_causali set tipoimporto=upper(tipoimporto);
update  bko_t_caricamento_causali set utilizzoconto=upper(utilizzoconto);
update  bko_t_caricamento_causali set utilizzoimporto=upper(utilizzoimporto);
 
 /*inserimento causali*/
  -- INSERT 1
INSERT INTO siac.siac_t_causale_ep(causale_ep_code, causale_ep_desc,causale_ep_tipo_id, validita_inizio, ente_proprietario_id, login_operazione,
  login_creazione, causale_ep_default, ambito_id)
select distinct
--a.pdc_fin
a.codice_causale,
a.descrizione_causale,
b.causale_ep_tipo_id,
to_timestamp('01/01/2015','dd/mm/yyyy'),
b.ente_proprietario_id,'admin','admin',
 case when a.causale_default='N' then FALSE else TRUE end causale_default,
c.ambito_id from bko_t_caricamento_causali a,siac_d_causale_ep_tipo b,siac_d_ambito c
where 
 c.ente_proprietario_id=b.ente_proprietario_id 
 and c.ambito_code=a.ambito and b.causale_ep_tipo_code='INT'
 and a.caricata=false 
 and not 
 exists (select 1 from siac_t_causale_ep d where d.causale_ep_code=a.codice_causale
 and d.ente_proprietario_id=b.ente_proprietario_id
 and d.causale_ep_tipo_id=b.causale_ep_tipo_id);
             
 
 --INSERT 2
 INSERT INTO siac.siac_r_causale_ep_class(causale_ep_id,classif_id,validita_inizio,ente_proprietario_id,login_operazione) 
select distinct a.causale_ep_id ,b.classif_id, to_timestamp('01/01/2015','dd/mm/yyyy'),a.ente_proprietario_id,'admin'||now()::varchar 
from siac_t_causale_ep a, siac_t_class b, siac_d_class_tipo c, bko_t_caricamento_causali d
where a.ente_proprietario_id=b.ente_proprietario_id and b.classif_tipo_id=c.classif_tipo_id 
 and c.classif_tipo_code in ('PDC_I','PDC_II','PDC_III','PDC_IV','PDC_V') 
and now() between b.validita_inizio and coalesce (b.validita_fine,now())and b.data_cancellazione is null 
and d.codice_causale=a.causale_ep_code
and d.caricata=false
and b.classif_code=d.pdc_fin
and not exists (select 1 from siac_r_causale_ep_class d where d.causale_ep_id=a.causale_ep_id  and d.classif_id=b.classif_id) ;	

--INSERT 3
INSERT INTO siac.siac_r_causale_ep_pdce_conto(causale_ep_id,pdce_conto_id,validita_inizio, ente_proprietario_id,login_operazione) 
select distinct a.causale_ep_id,b.pdce_conto_id,to_timestamp('01/01/2015','dd/mm/yyyy'),a.ente_proprietario_id,'admin'||now()::varchar  
from siac_t_causale_ep a, siac_t_pdce_conto b, siac_d_pdce_conto_tipo c,bko_t_caricamento_causali d
where a.causale_ep_code=d.codice_causale
and d.caricata=false 
and b.pdce_conto_code=d.pdc_eco_patr  and a.ente_proprietario_id=b.ente_proprietario_id and b.pdce_ct_tipo_id=c.pdce_ct_tipo_id 
and c.pdce_ct_tipo_code='GE' --and now() between b.validita_inizio and coalesce (b.validita_fine,now())  
and b.data_cancellazione 
is null and not exists (select 1 from siac_r_causale_ep_pdce_conto d where d.causale_ep_id=a.causale_ep_id and d.pdce_conto_id=b.pdce_conto_id);

--INSERT 4 
INSERT INTO siac.siac_r_causale_ep_stato(causale_ep_id,causale_ep_stato_id,validita_inizio,ente_proprietario_id,login_operazione) 
select distinct a.causale_ep_id ,b.causale_ep_stato_id, to_timestamp('01/01/2015','dd/mm/yyyy'),a.ente_proprietario_id,'admin'||now()::varchar  
from siac_t_causale_ep a,siac_d_causale_ep_stato b,bko_t_caricamento_causali d where a.ente_proprietario_id=b.ente_proprietario_id and 
a.causale_ep_code=d.codice_causale and d.caricata=false and
b.causale_ep_stato_code='V' and not exists 
(select 1 from siac_r_causale_ep_stato d where d.causale_ep_id=a.causale_ep_id and d.causale_ep_stato_id=b.causale_ep_stato_id);	

--INSERT 5

INSERT INTO siac.siac_r_causale_ep_pdce_conto_oper(causale_ep_pdce_conto_id,oper_ep_id,validita_inizio,ente_proprietario_id,login_operazione) 
select distinct e.causale_ep_pdce_conto_id,c.oper_ep_id,to_timestamp('01/01/2015','dd/mm/yyyy'),
a.ente_proprietario_id,'admin'||now()::varchar  
from siac_t_causale_ep a,siac_t_pdce_conto b,siac_r_causale_ep_pdce_conto e,siac_d_operazione_ep c,
siac_d_operazione_ep_tipo d, 
bko_t_caricamento_causali f
where a.causale_ep_id=e.causale_ep_id and b.pdce_conto_id=e.pdce_conto_id and a.causale_ep_code=f.codice_causale
and f.caricata=false
and b.pdce_conto_code=f.pdc_eco_patr and e.ente_proprietario_id=c.ente_proprietario_id and d.oper_ep_tipo_id=c.oper_ep_tipo_id 
and d.oper_ep_tipo_code='SEGNOCONTO' and 
c.oper_ep_code=f.segno
--c.oper_ep_code='AVERE' 
and not exists(select 1 from siac_r_causale_ep_pdce_conto_oper d 
where d.causale_ep_pdce_conto_id=e.causale_ep_pdce_conto_id and d.oper_ep_id=c.oper_ep_id);

--INSERT 6
INSERT INTO siac.siac_r_causale_ep_pdce_conto_oper(causale_ep_pdce_conto_id,oper_ep_id,validita_inizio,ente_proprietario_id,login_operazione) 
select distinct e.causale_ep_pdce_conto_id,c.oper_ep_id,to_timestamp('01/01/2015','dd/mm/yyyy'),a.ente_proprietario_id,'admin'||now()::varchar  
from siac_t_causale_ep a,siac_t_pdce_conto b,siac_r_causale_ep_pdce_conto e,siac_d_operazione_ep c,siac_d_operazione_ep_tipo d, 
bko_t_caricamento_causali f
where a.causale_ep_id=e.causale_ep_id and b.pdce_conto_id=e.pdce_conto_id and a.causale_ep_code=f.codice_causale  
and f.caricata=false
and b.pdce_conto_code=f.pdc_eco_patr  and e.ente_proprietario_id=c.ente_proprietario_id and d.oper_ep_tipo_id=c.oper_ep_tipo_id 
and d.oper_ep_tipo_code='TIPOIMPORTO' 
and c.oper_ep_code=f.tipoimporto and not exists(select 1 from siac_r_causale_ep_pdce_conto_oper d 
where d.causale_ep_pdce_conto_id=e.causale_ep_pdce_conto_id and d.oper_ep_id=c.oper_ep_id);	

--INSERT 7
INSERT INTO siac.siac_r_causale_ep_pdce_conto_oper(causale_ep_pdce_conto_id,oper_ep_id,validita_inizio,ente_proprietario_id,login_operazione) 
select distinct e.causale_ep_pdce_conto_id,c.oper_ep_id,to_timestamp('01/01/2015','dd/mm/yyyy'),a.ente_proprietario_id,'admin'||now()::varchar  
from siac_t_causale_ep a,siac_t_pdce_conto b,siac_r_causale_ep_pdce_conto e,siac_d_operazione_ep c,siac_d_operazione_ep_tipo d, 
bko_t_caricamento_causali f
where a.causale_ep_id=e.causale_ep_id and b.pdce_conto_id=e.pdce_conto_id and a.causale_ep_code=f.codice_causale  
and f.caricata=false
and b.pdce_conto_code=f.pdc_eco_patr  and e.ente_proprietario_id=c.ente_proprietario_id and d.oper_ep_tipo_id=c.oper_ep_tipo_id 
and d.oper_ep_tipo_code='UTILIZZOCONTO' and c.oper_ep_code=f.utilizzoconto and not exists(select 1 from siac_r_causale_ep_pdce_conto_oper d 
where d.causale_ep_pdce_conto_id=e.causale_ep_pdce_conto_id and d.oper_ep_id=c.oper_ep_id);	

--INSERT 8
INSERT INTO siac.siac_r_causale_ep_pdce_conto_oper(causale_ep_pdce_conto_id,oper_ep_id,validita_inizio,ente_proprietario_id,login_operazione) 
select distinct e.causale_ep_pdce_conto_id,c.oper_ep_id,to_timestamp('01/01/2015','dd/mm/yyyy'),a.ente_proprietario_id,'admin'||now()::varchar  
from siac_t_causale_ep a,siac_t_pdce_conto b,siac_r_causale_ep_pdce_conto e,siac_d_operazione_ep c,siac_d_operazione_ep_tipo d, 
bko_t_caricamento_causali f
where a.causale_ep_id=e.causale_ep_id and b.pdce_conto_id=e.pdce_conto_id and a.causale_ep_code=f.codice_causale  
and f.caricata=false
and b.pdce_conto_code=f.pdc_eco_patr  and e.ente_proprietario_id=c.ente_proprietario_id and d.oper_ep_tipo_id=c.oper_ep_tipo_id 
and d.oper_ep_tipo_code='UTILIZZOIMPORTO' and c.oper_ep_code=f.utilizzoimporto and not exists(select 1 from siac_r_causale_ep_pdce_conto_oper d 
where d.causale_ep_pdce_conto_id=e.causale_ep_pdce_conto_id and d.oper_ep_id=c.oper_ep_id);	

/*inserimento eventi*/

INSERT INTO siac_r_evento_causale(evento_id, causale_ep_id, validita_inizio,
  ente_proprietario_id, login_operazione)
select a.evento_id,
       c.causale_ep_id,
       c.validita_inizio,
       c.ente_proprietario_id,
       c.login_operazione
from siac_d_evento a,
     siac_d_evento_tipo b,
     siac_t_causale_ep c, bko_t_caricamento_eventi_causali d
where a.evento_tipo_id = b.evento_tipo_id and
      c.ente_proprietario_id = b.ente_proprietario_id and
      a.evento_code=d.evento and
      b.evento_tipo_code = d.tipo_evento and
      c.causale_ep_code = d.codice_causale 
      and d.caricato=false
      and not exists (
                   select 1
                   from siac_r_evento_causale z
                   where z.evento_id = a.evento_id and
                         z.causale_ep_id = c.causale_ep_id
      );
      
/*update dati caricati*/      

update  bko_t_caricamento_causali set caricata = true;

update  bko_t_caricamento_eventi_causali set caricato = true;

esito:='ok';
return;
exception
when no_data_found THEN
raise notice 'nessun dato trovato';
when others  THEN
 raise notice 'errore : %  - stato: % ', SQLERRM, SQLSTATE;
--raise notice 'altro errore';
return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY DEFINER
COST 100 ROWS 1000;