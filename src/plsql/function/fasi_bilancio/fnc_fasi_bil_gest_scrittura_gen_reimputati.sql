/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac.fnc_fasi_bil_gest_scrittura_gen_reimputati (
  enteproprietarioid integer,
  annobilancio integer,
  login_oper_in varchar
)
RETURNS TABLE (
  _regmovfin_id integer
) AS
$body$
DECLARE

stato_new_id integer;
stato_new_id_no_sog integer;
login_oper varchar;
valid_fine timestamp;
valid_inizio timestamp;
data_oper timestamp;
--ente_proprietario_new_id integer;
esito varchar;
cur_acc record;
cur_imp record;
evento_code_reg_movfin varchar;
macroaggegato_exists varchar;
acc_evento_code varchar;

begin
macroaggegato_exists:=null;
evento_code_reg_movfin:=null;
data_oper:=now();
valid_fine:=now();
valid_inizio:=now()+ interval '1 second';
login_oper:= 'fnc_fasi_bil_gest_scrittura_gen_pluri';
login_oper:= login_oper || ' - ' || login_oper_in;

------creazione scrittura registro per accertamenti



for cur_acc IN
select tbaccal.* from (
select tb.* from (
select
l.classif_id,d.bil_id,b.ente_proprietario_id,b.validita_inizio,b.login_operazione,n.ambito_id,
h.movgest_ts_tipo_code, c.movgest_id, b.movgest_ts_id, o.movgest_tipo_code
from 
fase_bil_t_reimputazione a, siac_t_movgest_ts b,siac_t_movgest c,siac_t_bil d,siac_t_periodo e,
siac_r_movgest_ts_attr f ,siac_t_attr g,siac_d_movgest_ts_tipo h
,siac_r_movgest_class i, siac_t_class l, siac_d_class_tipo m, siac_d_ambito n, siac_d_movgest_tipo o
,siac_r_movgest_ts_stato p,siac_d_movgest_stato q
 where
b.movgest_ts_id=a.movgestnew_ts_id
and a.fl_elab='S'
and a.ente_proprietario_id=enteproprietarioid
and c.movgest_id=b.movgest_id
and d.bil_id=c.bil_id
and e.periodo_id=d.periodo_id
and c.movgest_anno=e.anno::integer
and e.anno::integer=annobilancio
and b.movgest_ts_id=f.movgest_ts_id
and f.attr_id=g.attr_id
and now() between f.validita_inizio and COALESCE(f.validita_fine, now())
and g.attr_code='FlagCollegamentoAccertamentoFattura'
and f."boolean"='N'
and h.movgest_ts_tipo_id=b.movgest_ts_tipo_id
and i.movgest_ts_id=b.movgest_ts_id
and now() between i.validita_inizio and COALESCE(i.validita_fine, now())
and i.classif_id=l.classif_id
and m.classif_tipo_id=l.classif_tipo_id
and m.classif_tipo_code like 'PDC%'
and n.ente_proprietario_id=b.ente_proprietario_id
and n.ambito_code='AMBITO_FIN'
and o.movgest_tipo_id=c.movgest_tipo_id
and o.movgest_tipo_code='A'
and p.movgest_ts_id=b.movgest_ts_id
and q.movgest_stato_id=p.movgest_stato_id
and now() BETWEEN p.validita_inizio and COALESCE(p.validita_fine,now())
and q.movgest_stato_code='D'
and b.data_cancellazione is null
and c.data_cancellazione is null
and d.data_cancellazione is null
and e.data_cancellazione is null
and f.data_cancellazione is null
and g.data_cancellazione is null
and h.data_cancellazione is null
and i.data_cancellazione is null
and l.data_cancellazione is null
and m.data_cancellazione is null
and n.data_cancellazione is null
and o.data_cancellazione is null
and h.movgest_ts_tipo_code='T') as tb
where
-- esclusione movgest_ts_tipo_code='T' con presenti movgest_ts_tipo_code='S'
not exists
(select 1 from (
select
l.classif_id,d.bil_id,b.ente_proprietario_id,b.validita_inizio,b.login_operazione,n.ambito_id,
h.movgest_ts_tipo_code, c.movgest_id, b.movgest_ts_id, o.movgest_tipo_code
from 
fase_bil_t_reimputazione a, siac_t_movgest_ts b,siac_t_movgest c,siac_t_bil d,siac_t_periodo e,
siac_r_movgest_ts_attr f ,siac_t_attr g,siac_d_movgest_ts_tipo h
,siac_r_movgest_class i, siac_t_class l, siac_d_class_tipo m, siac_d_ambito n, siac_d_movgest_tipo o
,siac_r_movgest_ts_stato p,siac_d_movgest_stato q
 where
b.movgest_ts_id=a.movgestnew_ts_id
and a.fl_elab='S'
and a.ente_proprietario_id=enteproprietarioid
and c.movgest_id=b.movgest_id
and d.bil_id=c.bil_id
and e.periodo_id=d.periodo_id
and c.movgest_anno=e.anno::integer
and b.movgest_ts_id=f.movgest_ts_id
and f.attr_id=g.attr_id
and now() between f.validita_inizio and COALESCE(f.validita_fine, now())
and g.attr_code='FlagCollegamentoAccertamentoFattura'
and f."boolean"='N'
and h.movgest_ts_tipo_id=b.movgest_ts_tipo_id
and i.movgest_ts_id=b.movgest_ts_id
and now() between i.validita_inizio and COALESCE(i.validita_fine, now())
and i.classif_id=l.classif_id
and m.classif_tipo_id=l.classif_tipo_id
and m.classif_tipo_code like 'PDC%'
and n.ente_proprietario_id=b.ente_proprietario_id
and n.ambito_code='AMBITO_FIN'
and o.movgest_tipo_id=c.movgest_tipo_id
and o.movgest_tipo_code='A'
and p.movgest_ts_id=b.movgest_ts_id
and q.movgest_stato_id=p.movgest_stato_id
and now() BETWEEN p.validita_inizio and COALESCE(p.validita_fine,now())
and q.movgest_stato_code='D'
and b.data_cancellazione is null
and c.data_cancellazione is null
and d.data_cancellazione is null
and e.data_cancellazione is null
and f.data_cancellazione is null
and g.data_cancellazione is null
and h.data_cancellazione is null
and i.data_cancellazione is null
and l.data_cancellazione is null
and m.data_cancellazione is null
and n.data_cancellazione is null
and o.data_cancellazione is null
and h.movgest_ts_tipo_code='S') tb2 where tb2.movgest_id=tb.movgest_id
)
UNION
-- solo h.movgest_ts_tipo_code='S'
select
l.classif_id,d.bil_id,b.ente_proprietario_id,b.validita_inizio,b.login_operazione,n.ambito_id,
h.movgest_ts_tipo_code, c.movgest_id, b.movgest_ts_id, o.movgest_tipo_code
from 
fase_bil_t_reimputazione a, siac_t_movgest_ts b,siac_t_movgest c,siac_t_bil d,siac_t_periodo e,
siac_r_movgest_ts_attr f ,siac_t_attr g,siac_d_movgest_ts_tipo h
,siac_r_movgest_class i, siac_t_class l, siac_d_class_tipo m, siac_d_ambito n, siac_d_movgest_tipo o
,siac_r_movgest_ts_stato p,siac_d_movgest_stato q
 where
b.movgest_ts_id=a.movgestnew_ts_id
and a.fl_elab='S'
and a.ente_proprietario_id=enteproprietarioid
and c.movgest_id=b.movgest_id
and d.bil_id=c.bil_id
and e.periodo_id=d.periodo_id
and c.movgest_anno=e.anno::integer
and b.movgest_ts_id=f.movgest_ts_id
and f.attr_id=g.attr_id
and now() between f.validita_inizio and COALESCE(f.validita_fine, now())
and g.attr_code='FlagCollegamentoAccertamentoFattura'
and f."boolean"='N'
and h.movgest_ts_tipo_id=b.movgest_ts_tipo_id
and i.movgest_ts_id=b.movgest_ts_id
and now() between i.validita_inizio and COALESCE(i.validita_fine, now())
and i.classif_id=l.classif_id
and m.classif_tipo_id=l.classif_tipo_id
and m.classif_tipo_code like 'PDC%'
and n.ente_proprietario_id=b.ente_proprietario_id
and n.ambito_code='AMBITO_FIN'
and o.movgest_tipo_id=c.movgest_tipo_id
and o.movgest_tipo_code='A'
and p.movgest_ts_id=b.movgest_ts_id
and q.movgest_stato_id=p.movgest_stato_id
and now() BETWEEN p.validita_inizio and COALESCE(p.validita_fine,now())
and q.movgest_stato_code='D'
and b.data_cancellazione is null
and c.data_cancellazione is null
and d.data_cancellazione is null
and e.data_cancellazione is null
and f.data_cancellazione is null
and g.data_cancellazione is null
and h.data_cancellazione is null
and i.data_cancellazione is null
and l.data_cancellazione is null
and m.data_cancellazione is null
and n.data_cancellazione is null
and o.data_cancellazione is null
and h.movgest_ts_tipo_code='S') as tbaccal
where not exists (select 1 from fase_bil_t_gest_scrittura_gen_reimputati zz where zz.movgest_ts_id=tbaccal.movgest_ts_id)


loop

          INSERT INTO siac.siac_t_reg_movfin(classif_id_iniziale,classif_id_aggiornato,
          bil_id,validita_inizio,ente_proprietario_id,login_operazione,ambito_id)
          values (cur_acc.classif_id,cur_acc.classif_id,cur_acc.bil_id,cur_acc.validita_inizio,cur_acc.ente_proprietario_id,login_oper,
          cur_acc.ambito_id)
          returning regmovfin_id into _regmovfin_id
          ;

          INSERT INTO siac.siac_r_reg_movfin_stato(regmovfin_id,regmovfin_stato_id, validita_inizio, ente_proprietario_id, login_operazione)
          select _regmovfin_id,
                 b.regmovfin_stato_id,
                 cur_acc.validita_inizio,
                 cur_acc.ente_proprietario_id,
                 login_oper
          from siac_d_reg_movfin_stato b
          where b.regmovfin_stato_code = 'N' and
                b.ente_proprietario_id = cur_acc.ente_proprietario_id
                  and now() between b.validita_inizio and COALESCE(b.validita_fine,now())
                  and b.data_cancellazione is null;

          if cur_acc.movgest_ts_tipo_code='T' then
       
acc_evento_code:='ACC-INS';

      		raise notice 'ins siac_r_evento_reg_movfin accertamento';
            INSERT INTO siac.siac_r_evento_reg_movfin(regmovfin_id, evento_id, campo_pk_id, validita_inizio, ente_proprietario_id, login_operazione)
            select _regmovfin_id,
                   a.evento_id,
                   cur_acc.movgest_id, --accertamento
                   cur_acc.validita_inizio,
                   cur_acc.ente_proprietario_id,
                   login_oper
            from siac_d_evento a,
                 siac_d_movgest_tipo b
            where a.ente_proprietario_id = b.ente_proprietario_id and
                  a.ente_proprietario_id = cur_acc.ente_proprietario_id AND
                  b.movgest_tipo_code = cur_acc.movgest_tipo_code AND
                  a.evento_code =acc_evento_code -- 'ACC-INS'
                  and now() between a.validita_inizio and COALESCE(a.validita_fine,now())
                  and now() between b.validita_inizio and COALESCE(b.validita_fine,now())
                  and a.data_cancellazione is null
                  and b.data_cancellazione is null;
        
          else --movgest_ts_tipo_code='S'
  
acc_evento_code:='SAC-INS';        
            raise notice 'ins siac_r_evento_reg_movfin subaccertamento';
        
            INSERT INTO siac.siac_r_evento_reg_movfin(regmovfin_id, evento_id, campo_pk_id, validita_inizio, ente_proprietario_id, login_operazione)
            select _regmovfin_id,
                   a.evento_id,
                   cur_acc.movgest_ts_id, --subaccertamento
                   cur_acc.validita_inizio,
                   cur_acc.ente_proprietario_id,
                   login_oper
            from siac_d_evento a,
                 siac_d_movgest_tipo b
            where a.ente_proprietario_id = b.ente_proprietario_id and
                  a.ente_proprietario_id = cur_acc.ente_proprietario_id AND
                  b.movgest_tipo_code = cur_acc.movgest_tipo_code AND
                  a.evento_code = acc_evento_code--'SAC-INS'
                  and now() between a.validita_inizio and COALESCE(a.validita_fine,now())
                  and now() between b.validita_inizio and COALESCE(b.validita_fine,now())
                  and a.data_cancellazione is null
                  and b.data_cancellazione is null
                  ;
        
          end if; --movgest_ts_tipo_code='T' o movgest_ts_tipo_code='S'
          
          INSERT INTO 
  siac.fase_bil_t_gest_scrittura_gen_reimputati
(
  movgest_id,
  movgest_ts_id,
  movgest_ts_tipo_code,
  classif_id,
  regmovfin_id,
  evento_code,
  ente_proprietario_id,login_operazione
)
VALUES (
  cur_acc.movgest_id,
 cur_acc.movgest_ts_id,
  cur_acc.movgest_ts_tipo_code,
  cur_acc.classif_id,
  _regmovfin_id,
  acc_evento_code,
  cur_acc.ente_proprietario_id,login_oper
);
        
          return next;

end loop;

--creazione scrittura registro per impegni


for cur_imp 
in 
select tball.* from (
select tb.* from (
with imp as (
select 
b.movgest_ts_id,c.movgest_id ,d.bil_id, b.validita_inizio,b.login_operazione,
f.movgest_ts_tipo_code,b.ente_proprietario_id,c.movgest_anno,c.movgest_numero,c.movgest_tipo_id,
b.movgest_ts_code, g.movgest_tipo_code
from 
fase_bil_t_reimputazione a, siac_t_movgest_ts b,siac_t_movgest c,siac_t_bil d,
siac_t_periodo e, siac_d_movgest_ts_tipo f,
siac_d_movgest_tipo g, siac_r_movgest_ts_stato p,siac_d_movgest_stato q
 where
b.movgest_ts_id=a.movgestnew_ts_id
and a.fl_elab='S'
and a.ente_proprietario_id=enteproprietarioid
and c.movgest_id=b.movgest_id
and d.bil_id=c.bil_id
and e.periodo_id=d.periodo_id
and c.movgest_anno=e.anno::integer
and e.anno::integer=annobilancio
and f.movgest_ts_tipo_id=b.movgest_ts_tipo_id 
and g.movgest_tipo_id=c.movgest_tipo_id
and g.movgest_tipo_code='I'
and p.movgest_ts_id=b.movgest_ts_id
and q.movgest_stato_id=p.movgest_stato_id
and now() BETWEEN p.validita_inizio and COALESCE(p.validita_fine,now())
and q.movgest_stato_code='D'
and b.data_cancellazione is null
and c.data_cancellazione is null
and d.data_cancellazione is null
and e.data_cancellazione is null
and f.data_cancellazione is null
and g.data_cancellazione is null
)
, 
attoamm as (
select b.movgest_ts_id from 
siac_t_atto_amm a, siac_r_movgest_ts_atto_amm b, siac_r_atto_amm_stato n,siac_d_atto_amm_stato o
where  a.attoamm_id=b.attoamm_id
and n.attoamm_id=a.attoamm_id
and n.attoamm_stato_id=o.attoamm_stato_id
and now() between b.validita_inizio and COALESCE(b.validita_fine,now())
and o.attoamm_stato_code='DEFINITIVO'
and b.data_cancellazione is null
and n.data_cancellazione is null
and o.data_cancellazione is null
)
, condizioni as
(
select distinct d.movgest_id,b.classif_code, substring (b.classif_code from 1 for 6) macroagg from 
siac_r_movgest_class a, siac_t_class b, siac_d_class_tipo c,siac_t_movgest_ts d
where 
d.movgest_ts_id=a.movgest_ts_id and
a.classif_id=b.classif_id
and c.classif_tipo_id=b.classif_tipo_id
and c.classif_tipo_code like 'PDC%'
and (b.classif_code like 'U.1.04%' or b.classif_code like 'U.2.03%' or b.classif_code like 'U.2.04%' or 
b.classif_code like 'U.2.05%' or b.classif_code like 'U.3%' or b.classif_code like 'U.4.01%' or 
b.classif_code like 'U.4.02%' or b.classif_code like 'U.4.03%' or b.classif_code like 'U.4.04%' or 
b.classif_code like 'U.5%' or b.classif_code like 'U.7.01%' or b.classif_code like 'U.7.02%')
and a.data_cancellazione is NULL
and b.data_cancellazione is null
and c.data_cancellazione is null
and d.data_cancellazione is null
and now() BETWEEN a.validita_inizio and COALESCE(a.validita_fine,now())
)
, pdc as (select v.classif_id, u.movgest_ts_id from siac_r_movgest_class u, siac_t_class v, siac_d_class_tipo z
where v.classif_id=u.classif_id
and z.classif_tipo_id=v.classif_tipo_id 
and now() between u.validita_inizio and COALESCE(u.validita_fine,now())
and z.classif_tipo_code like 'PDC%'
and u.data_cancellazione is null
and v.data_cancellazione is null
and z.data_cancellazione is null
) , ambito as (select ente_proprietario_id, ambito_id from siac_d_ambito where ambito_code='AMBITO_FIN' and data_cancellazione is null)         
, soggetto as (select movgest_ts_id from siac_r_movgest_ts_sog where data_cancellazione is null)
, soggettoclasse as (select movgest_ts_id from siac_r_movgest_ts_sogclasse where data_cancellazione is null)
select 
pdc.classif_id, imp.bil_id, imp.ente_proprietario_id,
imp.validita_inizio,imp.login_operazione,ambito.ambito_id,
imp.movgest_ts_tipo_code,imp.movgest_id, imp.movgest_ts_id,
imp.movgest_ts_code,
--impannoprec.movgest_ts_code,
imp.movgest_ts_code,
imp.movgest_tipo_code,condizioni.macroagg
 From imp 
join attoamm 
on imp.movgest_ts_id=attoamm.movgest_ts_id
 join condizioni on condizioni.movgest_id=IMP.movgest_id
 join pdc on  pdc.movgest_ts_id=IMP.movgest_ts_id
 join ambito on  ambito.ente_proprietario_id=IMP.ente_proprietario_id
left join soggetto on  soggetto.movgest_ts_id=IMP.movgest_ts_id
left join soggettoclasse on  soggettoclasse.movgest_ts_id=IMP.movgest_ts_id
where (soggetto.movgest_ts_id is not null or soggettoclasse.movgest_ts_id is not null )
) tb
where 
tb.movgest_ts_tipo_code='T'
--condizione per escludere i T con sub
and not exists (
select 1 from (
with imp as (
select 
b.movgest_ts_id,c.movgest_id ,d.bil_id, b.validita_inizio,b.login_operazione,
f.movgest_ts_tipo_code,b.ente_proprietario_id,c.movgest_anno,c.movgest_numero,c.movgest_tipo_id,
b.movgest_ts_code, g.movgest_tipo_code
from 
fase_bil_t_reimputazione a, siac_t_movgest_ts b,siac_t_movgest c,siac_t_bil d,
siac_t_periodo e, siac_d_movgest_ts_tipo f,
siac_d_movgest_tipo g  ,siac_r_movgest_ts_stato p,siac_d_movgest_stato q
 where
b.movgest_ts_id=a.movgestnew_ts_id
and a.fl_elab='S'
and a.ente_proprietario_id=enteproprietarioid
and c.movgest_id=b.movgest_id
and d.bil_id=c.bil_id
and e.periodo_id=d.periodo_id
and c.movgest_anno=e.anno::integer
and f.movgest_ts_tipo_id=b.movgest_ts_tipo_id
and g.movgest_tipo_id=c.movgest_tipo_id
and g.movgest_tipo_code='I'
and p.movgest_ts_id=b.movgest_ts_id
and q.movgest_stato_id=p.movgest_stato_id
and now() BETWEEN p.validita_inizio and COALESCE(p.validita_fine,now())
and q.movgest_stato_code='D'
and b.data_cancellazione is null
and c.data_cancellazione is null
and d.data_cancellazione is null
and e.data_cancellazione is null
and f.data_cancellazione is null
and g.data_cancellazione is null
)
, 
attoamm as (
select b.movgest_ts_id from 
siac_t_atto_amm a, siac_r_movgest_ts_atto_amm b, siac_r_atto_amm_stato n,siac_d_atto_amm_stato o
where  a.attoamm_id=b.attoamm_id
and n.attoamm_id=a.attoamm_id
and n.attoamm_stato_id=o.attoamm_stato_id
and now() between b.validita_inizio and COALESCE(b.validita_fine,now())
and o.attoamm_stato_code='DEFINITIVO'
and a.data_cancellazione is null
and b.data_cancellazione is null
and n.data_cancellazione is null
and o.data_cancellazione is null
)
, condizioni as
(
select distinct d.movgest_id,b.classif_code, substring (b.classif_code from 1 for 6) macroagg from 
siac_r_movgest_class a, siac_t_class b, siac_d_class_tipo c,siac_t_movgest_ts d
where 
d.movgest_ts_id=a.movgest_ts_id and
a.classif_id=b.classif_id
and c.classif_tipo_id=b.classif_tipo_id
and c.classif_tipo_code like 'PDC%'
and (b.classif_code like 'U.1.04%' or b.classif_code like 'U.2.03%' or b.classif_code like 'U.2.04%' or 
b.classif_code like 'U.2.05%' or b.classif_code like 'U.3%' or b.classif_code like 'U.4.01%' or 
b.classif_code like 'U.4.02%' or b.classif_code like 'U.4.03%' or b.classif_code like 'U.4.04%' or 
b.classif_code like 'U.5%' or b.classif_code like 'U.7.01%' or b.classif_code like 'U.7.02%')
and a.data_cancellazione is NULL
and b.data_cancellazione is null
and c.data_cancellazione is null
and d.data_cancellazione is null
and now() BETWEEN a.validita_inizio and COALESCE(a.validita_fine,now())
)
, pdc as (select v.classif_id, u.movgest_ts_id from siac_r_movgest_class u, siac_t_class v, siac_d_class_tipo z
where v.classif_id=u.classif_id
and z.classif_tipo_id=v.classif_tipo_id 
and now() between u.validita_inizio and COALESCE(u.validita_fine,now())
and z.classif_tipo_code like 'PDC%'
and u.data_cancellazione is null
and v.data_cancellazione is null
and z.data_cancellazione is null
) , ambito as (select ente_proprietario_id, ambito_id from siac_d_ambito where ambito_code='AMBITO_FIN' and data_cancellazione is null)         
, soggetto as (select movgest_ts_id from siac_r_movgest_ts_sog where data_cancellazione is null)
, soggettoclasse as (select movgest_ts_id from siac_r_movgest_ts_sogclasse where data_cancellazione is null)
select 
pdc.classif_id, imp.bil_id, imp.ente_proprietario_id,
imp.validita_inizio,imp.login_operazione,ambito.ambito_id,
imp.movgest_ts_tipo_code,imp.movgest_id, imp.movgest_ts_id,
imp.movgest_ts_code,
--impannoprec.movgest_ts_code,
imp.movgest_ts_code,
imp.movgest_tipo_code,condizioni.macroagg
 From imp 
join attoamm 
on imp.movgest_ts_id=attoamm.movgest_ts_id
 join condizioni on condizioni.movgest_id=IMP.movgest_id
 join pdc on  pdc.movgest_ts_id=IMP.movgest_ts_id
 join ambito on  ambito.ente_proprietario_id=IMP.ente_proprietario_id
left join soggetto on  soggetto.movgest_ts_id=IMP.movgest_ts_id
left join soggettoclasse on  soggettoclasse.movgest_ts_id=IMP.movgest_ts_id
where (soggetto.movgest_ts_id is not null or soggettoclasse.movgest_ts_id is not null )
) tb2 where tb2.movgest_ts_tipo_code='S' and tb2.movgest_id=tb.movgest_id
)
UNION
-- solo movgest_ts_code='S'
select tb.* from (
with imp as (
select 
b.movgest_ts_id,c.movgest_id ,d.bil_id, b.validita_inizio,b.login_operazione,
f.movgest_ts_tipo_code,b.ente_proprietario_id,c.movgest_anno,c.movgest_numero,c.movgest_tipo_id,
b.movgest_ts_code, g.movgest_tipo_code
from 
fase_bil_t_reimputazione a, siac_t_movgest_ts b,siac_t_movgest c,siac_t_bil d,
siac_t_periodo e, siac_d_movgest_ts_tipo f,
siac_d_movgest_tipo g
,siac_r_movgest_ts_stato p,siac_d_movgest_stato q
 where
b.movgest_ts_id=a.movgestnew_ts_id
and a.fl_elab='S'
and a.ente_proprietario_id=enteproprietarioid
and c.movgest_id=b.movgest_id
and d.bil_id=c.bil_id
and e.periodo_id=d.periodo_id
and c.movgest_anno=e.anno::integer
and f.movgest_ts_tipo_id=b.movgest_ts_tipo_id
and g.movgest_tipo_id=c.movgest_tipo_id
and g.movgest_tipo_code='I'
and p.movgest_ts_id=b.movgest_ts_id
and q.movgest_stato_id=p.movgest_stato_id
and now() BETWEEN p.validita_inizio and COALESCE(p.validita_fine,now())
and q.movgest_stato_code='D'
and b.data_cancellazione is null
and c.data_cancellazione is null
and d.data_cancellazione is null
and e.data_cancellazione is null
and f.data_cancellazione is null
and g.data_cancellazione is null
)
, 
attoamm as (
select b.movgest_ts_id from 
siac_t_atto_amm a, siac_r_movgest_ts_atto_amm b, siac_r_atto_amm_stato n,siac_d_atto_amm_stato o
where  a.attoamm_id=b.attoamm_id
and n.attoamm_id=a.attoamm_id
and n.attoamm_stato_id=o.attoamm_stato_id
and now() between b.validita_inizio and COALESCE(b.validita_fine,now())
and o.attoamm_stato_code='DEFINITIVO'
and a.data_cancellazione is null
and b.data_cancellazione is null
and n.data_cancellazione is null
and o.data_cancellazione is null
)
, condizioni as
(
select distinct d.movgest_id,b.classif_code, substring (b.classif_code from 1 for 6) macroagg from 
siac_r_movgest_class a, siac_t_class b, siac_d_class_tipo c,siac_t_movgest_ts d
where 
d.movgest_ts_id=a.movgest_ts_id and
a.classif_id=b.classif_id
and c.classif_tipo_id=b.classif_tipo_id
and c.classif_tipo_code like 'PDC%'
and (b.classif_code like 'U.1.04%' or b.classif_code like 'U.2.03%' or b.classif_code like 'U.2.04%' or 
b.classif_code like 'U.2.05%' or b.classif_code like 'U.3%' or b.classif_code like 'U.4.01%' or 
b.classif_code like 'U.4.02%' or b.classif_code like 'U.4.03%' or b.classif_code like 'U.4.04%' or 
b.classif_code like 'U.5%' or b.classif_code like 'U.7.01%' or b.classif_code like 'U.7.02%')
and a.data_cancellazione is NULL
and b.data_cancellazione is null
and c.data_cancellazione is null
and d.data_cancellazione is null
and now() BETWEEN a.validita_inizio and COALESCE(a.validita_fine,now())
)
, pdc as (select v.classif_id, u.movgest_ts_id from siac_r_movgest_class u, siac_t_class v, siac_d_class_tipo z
where v.classif_id=u.classif_id
and z.classif_tipo_id=v.classif_tipo_id 
and now() between u.validita_inizio and COALESCE(u.validita_fine,now())
and z.classif_tipo_code like 'PDC%'
and u.data_cancellazione is null
and v.data_cancellazione is null
and z.data_cancellazione is null
) , ambito as (select ente_proprietario_id, ambito_id from siac_d_ambito where ambito_code='AMBITO_FIN' and data_cancellazione is null)         
, soggetto as (select movgest_ts_id from siac_r_movgest_ts_sog where data_cancellazione is null)
, soggettoclasse as (select movgest_ts_id from siac_r_movgest_ts_sogclasse where data_cancellazione is null)
select 
pdc.classif_id, imp.bil_id, imp.ente_proprietario_id,
imp.validita_inizio,imp.login_operazione,ambito.ambito_id,
imp.movgest_ts_tipo_code,imp.movgest_id, imp.movgest_ts_id,
imp.movgest_ts_code,
--impannoprec.movgest_ts_code,
imp.movgest_ts_code,
imp.movgest_tipo_code,condizioni.macroagg
 From imp 
join attoamm 
on imp.movgest_ts_id=attoamm.movgest_ts_id
 join condizioni on condizioni.movgest_id=IMP.movgest_id
 join pdc on  pdc.movgest_ts_id=IMP.movgest_ts_id
 join ambito on  ambito.ente_proprietario_id=IMP.ente_proprietario_id
left join soggetto on  soggetto.movgest_ts_id=IMP.movgest_ts_id
left join soggettoclasse on  soggettoclasse.movgest_ts_id=IMP.movgest_ts_id
where (soggetto.movgest_ts_id is not null or soggettoclasse.movgest_ts_id is not null )
) tb
where 
tb.movgest_ts_tipo_code='S'
) as tball
where not exists (select 1 from fase_bil_t_gest_scrittura_gen_reimputati zz where 
zz.movgest_ts_id=tball.movgest_ts_id)

       

 loop
        
         --raise notice 'cur_upd_sogg - loop cur_regmovfin';

          INSERT INTO siac.siac_t_reg_movfin(classif_id_iniziale,classif_id_aggiornato, bil_id, validita_inizio,ente_proprietario_id, login_operazione, ambito_id)
          values (cur_imp.classif_id,cur_imp.classif_id, cur_imp.bil_id, cur_imp.validita_inizio,
            cur_imp.ente_proprietario_id, login_oper, cur_imp.ambito_id)
            returning regmovfin_id
          into _regmovfin_id;

          INSERT INTO siac.siac_r_reg_movfin_stato(regmovfin_id,regmovfin_stato_id, validita_inizio, ente_proprietario_id, login_operazione)
          select _regmovfin_id,
                 b.regmovfin_stato_id,
                 cur_imp.validita_inizio,
                 cur_imp.ente_proprietario_id,
                 login_oper
          from siac_d_reg_movfin_stato b
          where b.regmovfin_stato_code = 'N' and
                b.ente_proprietario_id = cur_imp.ente_proprietario_id
                 and
              now() between b.validita_inizio and COALESCE(b.validita_fine,now());

macroaggegato_exists:=cur_imp.macroagg;

raise notice 'macroaggegato_exists: %',macroaggegato_exists;

 		if macroaggegato_exists='U.4.02' or macroaggegato_exists='U.4.03' or macroaggegato_exists='U.4.04' or macroaggegato_exists='U.7.01'  THEN
          evento_code_reg_movfin:='IMP-PRG';
          else
          evento_code_reg_movfin:='IMP-INS';
        end if; 

          if cur_imp.movgest_ts_tipo_code='T' then
          
             raise notice 'movgest_ts_tipo_code=T';
       
			raise notice 'ins siac_r_evento_reg_movfin impegno %',evento_code_reg_movfin;
            INSERT INTO siac.siac_r_evento_reg_movfin(regmovfin_id, evento_id,campo_pk_id, validita_inizio, ente_proprietario_id, login_operazione)
            select _regmovfin_id,
                   a.evento_id,
                   cur_imp.movgest_id, --IMPEGNO
                   valid_inizio,
                   cur_imp.ente_proprietario_id,
                   login_oper
            from siac_d_evento a,
                 siac_d_movgest_tipo b
            where a.ente_proprietario_id = b.ente_proprietario_id and
                  a.ente_proprietario_id = cur_imp.ente_proprietario_id AND
                  b.movgest_tipo_code = cur_imp.movgest_tipo_code AND
                  a.evento_code = evento_code_reg_movfin--'IMP-INS'
                  and  now() between a.validita_inizio and COALESCE(a.validita_fine,now())
                  and  now() between b.validita_inizio and COALESCE(a.validita_fine,now())
                  and a.data_cancellazione is null
                  and b.data_cancellazione is null
                  ;
        
          else --movgest_ts_tipo_code='S'
          
          evento_code_reg_movfin:='SIM-INS';
          
           raise notice 'ins siac_r_evento_reg_movfin subimpegno %',evento_code_reg_movfin;
        
            INSERT INTO siac.siac_r_evento_reg_movfin(regmovfin_id, evento_id,campo_pk_id, validita_inizio, ente_proprietario_id, login_operazione)
            select _regmovfin_id,
                   a.evento_id,
                   cur_imp.movgest_ts_id, --subimpegno
                   valid_inizio,
                   cur_imp.ente_proprietario_id,
                   login_oper
            from siac_d_evento a,
                 siac_d_movgest_tipo b
            where a.ente_proprietario_id = b.ente_proprietario_id and
                  a.ente_proprietario_id = cur_imp.ente_proprietario_id AND
                  b.movgest_tipo_code = cur_imp.movgest_tipo_code AND
                  a.evento_code = evento_code_reg_movfin--'SIM-INS'
                  and  now() between a.validita_inizio and COALESCE(a.validita_fine,now())
                  and  now() between b.validita_inizio and COALESCE(a.validita_fine,now())
                  and a.data_cancellazione is null
                  and b.data_cancellazione is null
                  ;
        
          end if; --movgest_ts_tipo_code='T' o movgest_ts_tipo_code='S'
        
        
            INSERT INTO 
  siac.fase_bil_t_gest_scrittura_gen_reimputati
(
  movgest_id,
  movgest_ts_id,
  movgest_ts_tipo_code,
  classif_id,
  regmovfin_id,
  evento_code,
  ente_proprietario_id,login_operazione
)
VALUES (
  cur_imp.movgest_id,
 cur_imp.movgest_ts_id,
  cur_imp.movgest_ts_tipo_code,
  cur_imp.classif_id,
  _regmovfin_id,
  evento_code_reg_movfin,
  cur_imp.ente_proprietario_id,login_oper
);
        
          return next;
        
        end loop; --LOOP AMBITO_FIN

esito:='OK';
  

return;

exception
     when others  THEN
         RAISE EXCEPTION 'Errore DB % %',SQLSTATE,substring(SQLERRM from 1 for 1000);
        --esito:='KO';
        --return esito;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100 ROWS 1000;