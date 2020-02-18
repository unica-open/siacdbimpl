/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac.fnc_siac_atto_amm_aggiorna_stato_movgest (
  attoamm_id_in integer,
  attoamm_stato_code_in varchar,
  is_esecutivo_in boolean,
  login_operazione_in varchar
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
ente_proprietario_new_id integer;
esito varchar;
cur_upd_sogg record;
cur_upd_nosogg record;
cur_regmovfin record;
cur_regmovfin_gsa record;
cur_regmovfin_gsa_acc record;
cur_regmovfin_acc record;
elem_id_exists integer;
ambito_id_gsa integer;
macroaggegato_exists varchar;
evento_code_reg_movfin varchar;
cur_mod_movgest_imp record;
cur_mod_movgest_acc record;
cur_mod_movgest_imp_gsa record;
cur_mod_movgest_acc_gsa record;
cur_mod_movgest_imp_gsa_sog record;
cur_mod_movgest_acc_gsa_sog record;
mod_stato_code_in varchar;
query text;
begin
mod_stato_code_in:='V';
elem_id_exists:=0;
macroaggegato_exists:=null;
evento_code_reg_movfin:=null;
ambito_id_gsa:=null;
data_oper:=now();
valid_fine:=now();
valid_inizio:=now()+ interval '1 second';
login_oper:= login_operazione_in||' - '||'fnc_siac_atto_amm_aggiorna_stato_movgest';

select movgest_stato_id,ente_proprietario_id into stato_new_id,ente_proprietario_new_id
     from siac_d_movgest_stato where
    ente_proprietario_id=(select ente_proprietario_id from siac_t_atto_amm where attoamm_id=attoamm_id_in)
    and movgest_stato_code='D';
       	
  


if is_esecutivo_in = true then
 
    update siac_t_movgest set parere_finanziario=true, parere_finanziario_data_modifica=valid_inizio, parere_finanziario_login_operazione=login_operazione_in
    where  movgest_id in ( 
    select distinct mg.movgest_id
    from siac_t_atto_amm aa,
    siac_r_movgest_ts_atto_amm mga,
    siac_t_movgest_ts ts, siac_t_movgest mg, siac_r_movgest_ts_stato tss, siac_d_movgest_stato mgs,
    siac_t_bil b, siac_d_fase_operativa fo, siac_r_bil_fase_operativa bfo, siac_d_movgest_tipo mt, siac_d_movgest_ts_tipo tt
    where mga.attoamm_id=aa.attoamm_id
    and ts.movgest_ts_id=mga.movgest_ts_id
    and mg.movgest_id=ts.movgest_id
    and tss.movgest_ts_id=ts.movgest_ts_id
    and mgs.movgest_stato_id=tss.movgest_stato_id
    and mgs.movgest_stato_code<>'A'
    and b.bil_id=mg.bil_id
    and bfo.fase_operativa_id=fo.fase_operativa_id
    and bfo.bil_id=b.bil_id
    and aa.attoamm_id=attoamm_id_in
    and mt.movgest_tipo_id=mg.movgest_tipo_id
    and tt.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
    and now() between tss.validita_inizio and COALESCE(tss.validita_fine,now())
    and aa.data_cancellazione is null
    and mga.data_cancellazione is null
    and ts.data_cancellazione is null
    and mg.data_cancellazione is null
    and tss.data_cancellazione is null
    and mgs.data_cancellazione is null
    and b.data_cancellazione is null
    and fo.data_cancellazione is null
    and bfo.data_cancellazione is null
    and mt.data_cancellazione is null
    and tt.data_cancellazione is null
    );
  
  --parerefinanziario = true dei momovimenti collegati 
end if;  


if attoamm_stato_code_in='DEFINITIVO' then
   /* select movgest_stato_id,ente_proprietario_id into stato_new_id,ente_proprietario_new_id
     from siac_d_movgest_stato where
    ente_proprietario_id=(select ente_proprietario_id from siac_t_atto_amm where attoamm_id=attoamm_id_in)
    and movgest_stato_code='D';*/
    
    select movgest_stato_id,ente_proprietario_id into stato_new_id_no_sog,ente_proprietario_new_id
     from siac_d_movgest_stato where
    ente_proprietario_id=(select ente_proprietario_id from siac_t_atto_amm where attoamm_id=attoamm_id_in)
    and movgest_stato_code='N';
--aggiorna a DEFINITIVO se c'è un soggetto associato all movgest_ts
--aggiorna a DEFINITIVO NON LIQUIDABILE se non c'è un soggetto associato all movgest_ts

--esiste soggetto?

--------------------------SOGGETTO ASSOCIATO aggiorno a DEFINITIVO INIZIO-----------------------------------

--si 
for cur_upd_sogg in
select tss.movgest_stato_r_id, ts.movgest_ts_id, b.bil_id, mg.movgest_id,
mt.movgest_tipo_code, tt.movgest_ts_tipo_code
from siac_t_atto_amm aa,
siac_r_movgest_ts_atto_amm mga,
siac_t_movgest_ts ts, siac_t_movgest mg, siac_r_movgest_ts_stato tss, 
siac_d_movgest_stato mgs,
siac_t_bil b, siac_d_fase_operativa fo, siac_r_bil_fase_operativa bfo, 
siac_d_movgest_tipo mt, siac_d_movgest_ts_tipo tt
where mga.attoamm_id=aa.attoamm_id
and ts.movgest_ts_id=mga.movgest_ts_id
and mg.movgest_id=ts.movgest_id
and tss.movgest_ts_id=ts.movgest_ts_id
and mgs.movgest_stato_id=tss.movgest_stato_id
and mgs.movgest_stato_code<>'A'
and b.bil_id=mg.bil_id
and bfo.fase_operativa_id=fo.fase_operativa_id
and bfo.bil_id=b.bil_id
and fo.fase_operativa_code<>'C'
and aa.attoamm_id=attoamm_id_in
and mt.movgest_tipo_id=mg.movgest_tipo_id
and tt.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
and mgs.movgest_stato_code='P'
and now() between tss.validita_inizio and COALESCE(tss.validita_fine,now())
and aa.data_cancellazione is null
and mga.data_cancellazione is null
and ts.data_cancellazione is null
and mg.data_cancellazione is null
and tss.data_cancellazione is null
and mgs.data_cancellazione is null
and b.data_cancellazione is null
and fo.data_cancellazione is null
and bfo.data_cancellazione is null
and mt.data_cancellazione is null
and tt.data_cancellazione is null
and ( 
 (    exists (
               select 1
               from siac_r_movgest_ts_sog sog
               where sog.movgest_ts_id = ts.movgest_ts_id
      		 )
  ) or 
  (    
      exists (
               select 1
               from siac_r_movgest_ts_sogclasse sogcl
               where  sogcl.movgest_ts_id = ts.movgest_ts_id
      )
  ))    
loop

    update siac_r_movgest_ts_stato set validita_fine=valid_fine, data_modifica=valid_fine, 
    data_cancellazione=valid_fine,login_operazione=login_operazione||' - '||'fnc_siac_atto_amm_aggiorna_stato_movgest'
    where movgest_stato_r_id=cur_upd_sogg.movgest_stato_r_id;

    INSERT INTO siac_r_movgest_ts_stato (movgest_ts_id,movgest_stato_id,validita_inizio,ente_proprietario_id,data_creazione,login_operazione)
    VALUES (cur_upd_sogg.movgest_ts_id,stato_new_id,valid_inizio,ente_proprietario_new_id,valid_inizio,login_oper);
    
----------------REGISTRAZIONE IMPEGNO INIZIO (si fa solo se c'è soggetto associato)----------------------    
    
  IF cur_upd_sogg.movgest_tipo_code='I' THEN 
  
  raise notice 'cur_upd_sogg - movgest_tipo_code=I';

  

select distinct 
substring (b.classif_code from 1 for 6) macroagg 
into  macroaggegato_exists
from 
siac_r_movgest_class a, siac_t_class b, siac_d_class_tipo c,siac_t_movgest_ts d
where 
d.movgest_ts_id=a.movgest_ts_id 
and  d.movgest_ts_id=cur_upd_sogg.movgest_ts_id
and a.classif_id=b.classif_id
and c.classif_tipo_id=b.classif_tipo_id and c.classif_tipo_code like 'PDC%'
and (b.classif_code like 'U.1.04%' or b.classif_code like 'U.2.03%' or b.classif_code like 'U.2.04%' or 
b.classif_code like 'U.2.05%' or b.classif_code like 'U.3%' or b.classif_code like 'U.4.01%' or 
b.classif_code like 'U.4.02%' or b.classif_code like 'U.4.03%' or b.classif_code like 'U.4.04%' or 
b.classif_code like 'U.5%' or b.classif_code like 'U.7.01%' or b.classif_code like 'U.7.02%')
and a.data_cancellazione is NULL
and b.data_cancellazione is null
and c.data_cancellazione is null
and d.data_cancellazione is null
and now() BETWEEN a.validita_inizio and COALESCE(a.validita_fine,now());


      if macroaggegato_exists is not null then
      
        raise notice 'cur_upd_sogg - macroaggegato_exists ';

  --------------------------AMBITO_FIN INIZIO-----------------------------------
        for cur_regmovfin in --LOOP AMBITO_FIN
        select b.classif_id,
               e.ambito_id
        from siac_r_movgest_class a,
             siac_t_class b,
             siac_d_class_tipo c,
             siac_t_movgest_ts d,
             siac_d_ambito e
        where a.classif_id = b.classif_id and
              b.classif_tipo_id = c.classif_tipo_id and
              c.classif_tipo_code like 'PDC%' and
              d.movgest_ts_id = a.movgest_ts_id and
              d.movgest_ts_id = cur_upd_sogg.movgest_ts_id and
              e.ente_proprietario_id = b.ente_proprietario_id and
              a.data_cancellazione is null and
              b.data_cancellazione is null and
              c.data_cancellazione is null and
              d.data_cancellazione is null and
              e.data_cancellazione is null and
              e.ambito_code = 'AMBITO_FIN' and
              now() between a.validita_inizio and COALESCE(a.validita_fine,now())
              
        loop
        
         raise notice 'cur_upd_sogg - loop cur_regmovfin';

          INSERT INTO siac.siac_t_reg_movfin(classif_id_iniziale,classif_id_aggiornato, bil_id, validita_inizio,ente_proprietario_id, login_operazione, ambito_id)
          values (cur_regmovfin.classif_id,cur_regmovfin.classif_id, cur_upd_sogg.bil_id, valid_inizio,
            ente_proprietario_new_id, login_oper, cur_regmovfin.ambito_id)
            returning regmovfin_id
          into _regmovfin_id;

          INSERT INTO siac.siac_r_reg_movfin_stato(regmovfin_id,regmovfin_stato_id, validita_inizio, ente_proprietario_id, login_operazione)
          select _regmovfin_id,
                 b.regmovfin_stato_id,
                 valid_inizio,
                 ente_proprietario_new_id,
                 login_oper
          from siac_d_reg_movfin_stato b
          where b.regmovfin_stato_code = 'N' and
                b.ente_proprietario_id = ente_proprietario_new_id
                 and
              now() between b.validita_inizio and COALESCE(b.validita_fine,now());

          if cur_upd_sogg.movgest_ts_tipo_code='T' then
          
             raise notice 'cur_upd_sogg - movgest_ts_tipo_code=T';
            
          if macroaggegato_exists='U.4.02' or macroaggegato_exists='U.4.03' or macroaggegato_exists='U.4.04' or macroaggegato_exists='U.7.01'  THEN
          evento_code_reg_movfin:='IMP-PRG';
          else
          evento_code_reg_movfin:='IMP-INS';
          end if; 
       
            INSERT INTO siac.siac_r_evento_reg_movfin(regmovfin_id, evento_id,campo_pk_id, validita_inizio, ente_proprietario_id, login_operazione)
            select _regmovfin_id,
                   a.evento_id,
                   cur_upd_sogg.movgest_id, --IMPEGNO
                   valid_inizio,
                   ente_proprietario_new_id,
                   login_oper
            from siac_d_evento a
            where 
                  a.ente_proprietario_id = ente_proprietario_new_id AND
                  a.evento_code = evento_code_reg_movfin--'IMP-INS'
                  and  now() between a.validita_inizio and COALESCE(a.validita_fine,now())
                  and a.data_cancellazione is null
                  ;
        
          else --movgest_ts_tipo_code='S'
          
           if macroaggegato_exists='U.4.02' or macroaggegato_exists='U.4.03' or macroaggegato_exists='U.4.04' or macroaggegato_exists='U.7.01'  THEN
          evento_code_reg_movfin:='SIM-PRG';
          else
          evento_code_reg_movfin:='SIM-INS';
          end if; 
          
             raise notice 'cur_upd_sogg movgest_ts_tipo_code=S';
        
            INSERT INTO siac.siac_r_evento_reg_movfin(regmovfin_id, evento_id,campo_pk_id, validita_inizio, ente_proprietario_id, login_operazione)
            select _regmovfin_id,
                   a.evento_id,
                   cur_upd_sogg.movgest_ts_id, --subimpegno
                   valid_inizio,
                   ente_proprietario_new_id,
                   login_oper
            from siac_d_evento a
             where a.ente_proprietario_id = ente_proprietario_new_id AND
                  a.evento_code = evento_code_reg_movfin--'SIM-INS'
                  and  now() between a.validita_inizio and COALESCE(a.validita_fine,now())
                  and a.data_cancellazione is null
                  ;
        
          end if; --movgest_ts_tipo_code='T' o movgest_ts_tipo_code='S'
        
          return next;
       
        end loop; --LOOP AMBITO_FIN
         _regmovfin_id:=null;
             raise notice 'fine ambito FIN';

  --------------------------AMBITO_GSA INIZIO-----------------------------------    

        select c.ambito_id
        into ambito_id_gsa
        from siac_r_movgest_ts_attr a,
             siac_t_attr b,
             siac_d_ambito c
        where a.movgest_ts_id = cur_upd_sogg.movgest_ts_id and
              a.attr_id = b.attr_id and
              b.attr_code = 'FlagAttivaGsa' and
              c.ente_proprietario_id = b.ente_proprietario_id and
              c.ambito_code = 'AMBITO_GSA' and
              a."boolean" = 'S' and
              now() between a.validita_inizio and COALESCE(a.validita_fine,now())
              and a.data_cancellazione is null
              and b.data_cancellazione is null
              and c.data_cancellazione is null
        ;
        
        IF ambito_id_gsa is not null then
        
         raise notice 'ambito GSA';

          -- loop GSA
          for cur_regmovfin_gsa in select b.classif_id,
                e.ambito_id
         from siac_r_movgest_class a,
              siac_t_class b,
              siac_d_class_tipo c,
              siac_t_movgest_ts d,
              siac_d_ambito e
         where a.classif_id = b.classif_id and
               b.classif_tipo_id = c.classif_tipo_id  and
               c.classif_tipo_code like 'PDC%' and
               d.movgest_ts_id = a.movgest_ts_id and
               d.movgest_ts_id = cur_upd_sogg.movgest_ts_id and
               e.ente_proprietario_id =  b.ente_proprietario_id and
               a.data_cancellazione is null and
               b.data_cancellazione is null and
               c.data_cancellazione is null and
               d.data_cancellazione is null and
               e.data_cancellazione is null and
               e.ambito_code = 'AMBITO_GSA' and
              now() between a.validita_inizio and COALESCE(a.validita_fine,now())
          loop
 			
          raise notice 'cur_regmovfin_gsa - cur_regmovfin_gsa';

          INSERT INTO siac.siac_t_reg_movfin(classif_id_iniziale,classif_id_aggiornato,bil_id,validita_inizio,ente_proprietario_id,login_operazione,ambito_id)
          values (cur_regmovfin_gsa.classif_id,cur_regmovfin_gsa.classif_id,cur_upd_sogg.bil_id,valid_inizio,ente_proprietario_new_id,login_oper,cur_regmovfin_gsa.ambito_id)
          returning regmovfin_id into _regmovfin_id
          ;

          INSERT INTO siac.siac_r_reg_movfin_stato(regmovfin_id,regmovfin_stato_id, validita_inizio, ente_proprietario_id, login_operazione)
          select _regmovfin_id,
                 b.regmovfin_stato_id,
                 valid_inizio,
                 ente_proprietario_new_id,
                 login_oper
          from siac_d_reg_movfin_stato b
          where b.regmovfin_stato_code = 'N' and
                b.ente_proprietario_id = ente_proprietario_new_id
                and now() between b.validita_inizio and COALESCE(b.validita_fine,now())
                and b.data_cancellazione is null
                ;

          IF cur_upd_sogg.movgest_ts_tipo_code='T' then
          
          if macroaggegato_exists='U.4.02' or macroaggegato_exists='U.4.03' or macroaggegato_exists='U.4.04' or macroaggegato_exists='U.7.01'  THEN
          evento_code_reg_movfin:='IMP-PRG';
          else
          evento_code_reg_movfin:='IMP-INS';
          end if; 
          
          raise notice 'cur_regmovfin_gsamovgest_ts_tipo_code=T';
              
            INSERT INTO siac.siac_r_evento_reg_movfin(regmovfin_id, evento_id,campo_pk_id, validita_inizio, ente_proprietario_id, login_operazione)
            select _regmovfin_id,
                   a.evento_id,
                   cur_upd_sogg.movgest_id,
                   valid_inizio,
                   ente_proprietario_new_id,
                   login_oper
            from siac_d_evento a
            where a.ente_proprietario_id = ente_proprietario_new_id AND
                  a.evento_code = evento_code_reg_movfin--'IMP-INS'
                  and now() between a.validita_inizio and COALESCE(a.validita_fine,now())
                  and a.data_cancellazione is null
                  ;
              
          ELSE --movgest_ts_tipo_code='S'
          if macroaggegato_exists='U.4.02' or macroaggegato_exists='U.4.03' or macroaggegato_exists='U.4.04' or macroaggegato_exists='U.7.01'  THEN
          evento_code_reg_movfin:='SIM-PRG';
          else
          evento_code_reg_movfin:='SIM-INS';
          end if; 
          raise notice 'cur_regmovfin_gsa - movgest_ts_tipo_code=S';
              
            INSERT INTO siac.siac_r_evento_reg_movfin(regmovfin_id, evento_id, campo_pk_id, validita_inizio, ente_proprietario_id, login_operazione)
            select _regmovfin_id,
                   a.evento_id,
                   cur_upd_sogg.movgest_ts_id,
                   valid_inizio,
                   ente_proprietario_new_id,
                   login_oper
            from siac_d_evento a
            where a.ente_proprietario_id = ente_proprietario_new_id AND
                  a.evento_code = evento_code_reg_movfin--'SIM-INS'
                  and now() between a.validita_inizio and COALESCE(a.validita_fine,now())
                  and a.data_cancellazione is null;
                  
          END IF; --movgest_ts_tipo_code='T' o movgest_ts_tipo_code='S'
              
          RETURN NEXT;
              
          END LOOP; --loop GSA
        _regmovfin_id:=null;    
        END IF;	--ambito GSA not null
  --------------------------GSA FINE IMPEGNO-----------------------------------           
          
      END IF;--elem_id_exists<>0

	ELSE --cur_upd_sogg.movgest_tipo_code='A'

		raise notice 'cur_regmovfin - accertamento';
        raise notice 'cur_regmovfin - cur_upd_sogg.movgest_tipo_code %', cur_upd_sogg.movgest_tipo_code;
	
      for cur_regmovfin_acc in --LOOP AMBITO_FIN
        select b.classif_id,
               e.ambito_id
        from siac_r_movgest_class a,
             siac_t_class b,
             siac_d_class_tipo c,
             siac_t_movgest_ts d,
             siac_d_ambito e,
             siac_r_movgest_ts_attr f ,siac_t_attr g
             --, siac_r_movgest_ts_stato h, siac_d_movgest_stato i
        where a.classif_id = b.classif_id and
              b.classif_tipo_id = c.classif_tipo_id and
              c.classif_tipo_code like 'PDC%' and
              d.movgest_ts_id = a.movgest_ts_id and
              d.movgest_ts_id = cur_upd_sogg.movgest_ts_id and
              e.ente_proprietario_id = b.ente_proprietario_id and
              a.data_cancellazione is null and
              b.data_cancellazione is null and
              c.data_cancellazione is null and
              d.data_cancellazione is null and
              e.data_cancellazione is null and
              e.ambito_code = 'AMBITO_FIN' and 
              now() between a.validita_inizio and COALESCE(a.validita_fine,now()) and 
              f.movgest_ts_id=d.movgest_ts_id and 
              g.attr_id=f.attr_id and 
              g.attr_code='FlagCollegamentoAccertamentoFattura' and 
              f."boolean"='N' and 
              now() between f.validita_inizio and COALESCE(f.validita_fine,now()) and
              --h.movgest_ts_id=d.movgest_ts_id and
              --i.movgest_stato_id=h.movgest_stato_id and 
              --now() between h.validita_inizio and COALESCE(h.validita_fine,now()) and
              --i.movgest_stato_code='D' and
              f.data_cancellazione is null and
              g.data_cancellazione is null 
              --and h.data_cancellazione is null and
              --i.data_cancellazione is null 
        loop

          INSERT INTO siac.siac_t_reg_movfin(classif_id_iniziale,classif_id_aggiornato,bil_id,validita_inizio,ente_proprietario_id,login_operazione,ambito_id)
          values (cur_regmovfin_acc.classif_id,cur_regmovfin_acc.classif_id,cur_upd_sogg.bil_id,valid_inizio,ente_proprietario_new_id,login_oper,cur_regmovfin_acc.ambito_id)
          returning regmovfin_id into _regmovfin_id
          ;

          INSERT INTO siac.siac_r_reg_movfin_stato(regmovfin_id,regmovfin_stato_id, validita_inizio, ente_proprietario_id, login_operazione)
          select _regmovfin_id,
                 b.regmovfin_stato_id,
                 valid_inizio,
                 ente_proprietario_new_id,
                 login_oper
          from siac_d_reg_movfin_stato b
          where b.regmovfin_stato_code = 'N' and
                b.ente_proprietario_id = ente_proprietario_new_id
                  and now() between b.validita_inizio and COALESCE(b.validita_fine,now())
                  and b.data_cancellazione is null;

          if cur_upd_sogg.movgest_ts_tipo_code='T' then
       
      		raise notice 'cur_regmovfin_acc - movgest_ts_tipo_code=T';
            INSERT INTO siac.siac_r_evento_reg_movfin(regmovfin_id, evento_id, campo_pk_id, validita_inizio, ente_proprietario_id, login_operazione)
            select _regmovfin_id,
                   a.evento_id,
                   cur_upd_sogg.movgest_id, --IMPEGNO
                   valid_inizio,
                   ente_proprietario_new_id,
                   login_oper
            from siac_d_evento a
            where a.ente_proprietario_id = ente_proprietario_new_id AND
                  a.evento_code = 'ACC-INS'
                  and now() between a.validita_inizio and COALESCE(a.validita_fine,now())
                  and a.data_cancellazione is null;
                  
        
          else --movgest_ts_tipo_code='S'
          
            raise notice 'cur_regmovfin_acc - movgest_ts_tipo_code=S';
        
            INSERT INTO siac.siac_r_evento_reg_movfin(regmovfin_id, evento_id, campo_pk_id, validita_inizio, ente_proprietario_id, login_operazione)
            select _regmovfin_id,
                   a.evento_id,
                   cur_upd_sogg.movgest_ts_id, --subimpegno
                   valid_inizio,
                   ente_proprietario_new_id,
                   login_oper
            from siac_d_evento a
            where a.ente_proprietario_id = ente_proprietario_new_id AND
                  a.evento_code = 'SAC-INS'
                  and now() between a.validita_inizio and COALESCE(a.validita_fine,now())
                  and a.data_cancellazione is null
                  ;
        
          end if; --movgest_ts_tipo_code='T' o movgest_ts_tipo_code='S'
        
          return next;
                _regmovfin_id:=null;
        end loop; --LOOP AMBITO_FIN accertamento

  --------------------------AMBITO_GSA INIZIO-----------------------------------    

        select c.ambito_id
        into ambito_id_gsa
        from siac_r_movgest_ts_attr a,
             siac_t_attr b,
             siac_d_ambito c
        where a.movgest_ts_id = cur_upd_sogg.movgest_ts_id and
              a.attr_id = b.attr_id and
              b.attr_code = 'FlagAttivaGsa' and
              c.ente_proprietario_id = b.ente_proprietario_id and
              c.ambito_code = 'AMBITO_GSA' and
              a."boolean" = 'S'
              and now() between a.validita_inizio and COALESCE(a.validita_fine,now())
              and a.data_cancellazione is null
              and b.data_cancellazione is null
              and c.data_cancellazione is null
        ;
        
        IF ambito_id_gsa is not null then
     	
        raise notice 'gsa accertamento';
          -- loop GSA
          for cur_regmovfin_gsa_acc in 
          select b.classif_id,e.ambito_id
          from siac_r_movgest_class a,
          siac_t_class b,
          siac_d_class_tipo c,
          siac_t_movgest_ts d,
          siac_d_ambito e,
          siac_r_movgest_ts_attr f ,siac_t_attr g
          --,siac_r_movgest_ts_stato h, siac_d_movgest_stato i
          where a.classif_id = b.classif_id and
          b.classif_tipo_id = c.classif_tipo_id and
          c.classif_tipo_code like 'PDC%' and
          d.movgest_ts_id = a.movgest_ts_id and
          d.movgest_ts_id = cur_upd_sogg.movgest_ts_id and
          e.ente_proprietario_id = b.ente_proprietario_id and
          a.data_cancellazione is null and
          b.data_cancellazione is null and
          c.data_cancellazione is null and
          d.data_cancellazione is null and
          e.data_cancellazione is null and
          e.ambito_code = 'AMBITO_GSA' and 
          now() between a.validita_inizio and COALESCE(a.validita_fine,now()) and 
          f.movgest_ts_id=d.movgest_ts_id and 
          g.attr_id=f.attr_id and 
          g.attr_code='FlagCollegamentoAccertamentoFattura' and 
          f."boolean"='N' and 
          now() between f.validita_inizio and COALESCE(f.validita_fine,now()) and
          --h.movgest_ts_id=d.movgest_ts_id and
          --i.movgest_stato_id=h.movgest_stato_id and 
          --now() between h.validita_inizio and COALESCE(h.validita_fine,now()) and
          --i.movgest_stato_code='D' and
          f.data_cancellazione is null and
          g.data_cancellazione is null
          --and h.data_cancellazione is null and
          --i.data_cancellazione is null 
         loop

          INSERT INTO siac.siac_t_reg_movfin(classif_id_iniziale,classif_id_aggiornato,bil_id,validita_inizio,ente_proprietario_id,login_operazione,ambito_id)
          values (cur_regmovfin_gsa_acc.classif_id,cur_regmovfin_gsa_acc.classif_id,cur_upd_sogg.bil_id,valid_inizio,ente_proprietario_new_id,login_oper,cur_regmovfin_gsa_acc.ambito_id)
          returning regmovfin_id into _regmovfin_id
          ;

          INSERT INTO siac.siac_r_reg_movfin_stato(regmovfin_id, regmovfin_stato_id,  validita_inizio, ente_proprietario_id, login_operazione)
          select _regmovfin_id,
                 b.regmovfin_stato_id,
                 valid_inizio,
                 ente_proprietario_new_id,
                 login_oper
          from siac_d_reg_movfin_stato b
          where b.regmovfin_stato_code = 'N' and
                b.ente_proprietario_id = ente_proprietario_new_id
                and now() between b.validita_inizio and COALESCE(b.validita_fine,now())
                and b.data_cancellazione is null;

          IF cur_upd_sogg.movgest_ts_tipo_code='T' then
                   raise notice 'cur_regmovfin_gsa_acc - movgest_ts_tipo_code=T';
            INSERT INTO siac.siac_r_evento_reg_movfin(regmovfin_id, evento_id, campo_pk_id, validita_inizio, ente_proprietario_id, login_operazione)
            select _regmovfin_id,
                   a.evento_id,
                   cur_upd_sogg.movgest_id,
                   valid_inizio,
                   ente_proprietario_new_id,
                   login_oper
            from siac_d_evento a
            where a.ente_proprietario_id = ente_proprietario_new_id AND
                  a.evento_code = 'ACC-INS'
                  and now() between a.validita_inizio and COALESCE(a.validita_fine,now())
                  and a.data_cancellazione is null
                  ;
              
          ELSE --movgest_ts_tipo_code='S'
                   raise notice 'cur_regmovfin_gsa_acc - movgest_ts_tipo_code=S';
            INSERT INTO siac.siac_r_evento_reg_movfin(regmovfin_id, evento_id, campo_pk_id, validita_inizio, ente_proprietario_id, login_operazione)
            select _regmovfin_id,
                   a.evento_id,
                   cur_upd_sogg.movgest_ts_id,
                   valid_inizio,
                   ente_proprietario_new_id,
                   login_oper
            from siac_d_evento a
            where a.ente_proprietario_id = ente_proprietario_new_id AND
                  a.evento_code = 'SAC-INS'
                  and now() between a.validita_inizio and COALESCE(a.validita_fine,now())
                  and a.data_cancellazione is null
                  ;
  			
          END IF; --movgest_ts_tipo_code='T' o movgest_ts_tipo_code='S'
              
          RETURN NEXT;
              
          END LOOP; --loop GSA
        _regmovfin_id:=null;
        --       raise notice 'fine GSA';
             
        END IF;	--ambito GSA not null


	END IF; --cur_upd_sogg.movgest_tipo_code='I'
       

       

 END LOOP; --cur_upd_sogg


--------------------------IMPEGNO FINE-----------------------------------

--NESSUN SOGGETTO ASSOCIATO
  for cur_upd_nosogg in
  select tss.movgest_stato_r_id,
         ts.movgest_ts_id,
         tt.movgest_ts_tipo_code,
         b.bil_id,
         mg.movgest_id,
         tipom.movgest_tipo_code
  from siac_t_atto_amm aa,
       siac_r_movgest_ts_atto_amm mga,
       siac_t_movgest_ts ts,
       siac_t_movgest mg,
       siac_r_movgest_ts_stato tss,
       siac_d_movgest_stato mgs,
       siac_t_bil b,
       siac_d_fase_operativa fo,
       siac_r_bil_fase_operativa bfo,
       siac_d_movgest_ts_tipo tt,
       siac_d_movgest_tipo tipom
  where mga.attoamm_id = aa.attoamm_id and
        ts.movgest_ts_id = mga.movgest_ts_id and
        mg.movgest_id = ts.movgest_id and
        tss.movgest_ts_id = ts.movgest_ts_id and
        mgs.movgest_stato_id = tss.movgest_stato_id and
        mgs.movgest_stato_code <> 'A' and
        b.bil_id = mg.bil_id and
        bfo.fase_operativa_id = fo.fase_operativa_id and
        bfo.bil_id = b.bil_id and
        fo.fase_operativa_code <> 'C' and
        aa.attoamm_id = attoamm_id_in and
        tt.movgest_ts_tipo_id = ts.movgest_ts_tipo_id and
        mgs.movgest_stato_code = 'P' and
        tipom.movgest_tipo_id = mg.movgest_tipo_id 
        and now() between tss.validita_inizio and COALESCE(tss.validita_fine,now())
        and now() between mga.validita_inizio and COALESCE(mga.validita_fine,now())
        and now() between bfo.validita_inizio and COALESCE(bfo.validita_fine,now())
        and aa.data_cancellazione is null
        and mga.data_cancellazione is null
        and ts.data_cancellazione is null
        and mg.data_cancellazione is null
        and tss.data_cancellazione is null
        and mgs.data_cancellazione is null
        and b.data_cancellazione is null
        and fo.data_cancellazione is null
        and bfo.data_cancellazione is null
        and tipom.data_cancellazione is null
        and tt.data_cancellazione is null
        and
        not exists (
                     select 1
                     from siac_r_movgest_ts_sog sog
                     where sog.movgest_ts_id = ts.movgest_ts_id
        )
        and 
       	not exists (
               select 1
               from siac_r_movgest_ts_sogclasse sogcl
               where  sogcl.movgest_ts_id = ts.movgest_ts_id
      	)
        
        
  LOOP

    update siac_r_movgest_ts_stato set 
    validita_fine=valid_fine, data_modifica=valid_fine, 
    data_cancellazione=valid_fine,login_operazione=login_operazione||' - '||'fnc_siac_atto_amm_aggiorna_stato_movgest'
    where movgest_stato_r_id=cur_upd_nosogg.movgest_stato_r_id;
    

  

    INSERT INTO siac_r_movgest_ts_stato (movgest_ts_id,movgest_stato_id,validita_inizio,ente_proprietario_id,data_creazione,login_operazione)
    VALUES (cur_upd_nosogg.movgest_ts_id,stato_new_id_no_sog,valid_inizio,ente_proprietario_new_id,valid_inizio,login_oper);

  raise notice 'no sogg';
  
    
        
 END LOOP;
   
  

 esito:='OK';
  
         
  
else --se stato <>'DEFINITIVO'
  esito:='KO';
  _regmovfin_id:=-1;
end if;




raise notice 'nuova richiesta';
---nuova richiesta di S.Torta, scritture in caso di atto amm collegato a modifiche
--per ogni tipo di evento occorre recuperare l'entità associata





--modifiche su movgest (importo)

/*query:='select 
f.mod_stato_id mod_id, f.ente_proprietario_id movgest_ts_id
from siac_d_modifica_stato f,siac_r_modifica_stato b, siac_t_modifica a,siac_t_atto_amm g,
siac_t_movgest_ts_det_mod c,siac_t_movgest_ts e,siac_r_atto_amm_stato h,siac_d_atto_amm_stato i
,siac_t_movgest l,siac_d_movgest_tipo m,
siac_d_movgest_ts_tipo n,siac_d_ambito o,
siac_r_movgest_class p,siac_t_class q,siac_d_class_tipo r 
where 
f.mod_stato_id = b.mod_stato_id and a.mod_id=b.mod_id and a.attoamm_id = g.attoamm_id and
c.mod_stato_r_id = b.mod_stato_r_id and e.movgest_ts_id = c.movgest_ts_id and
g.attoamm_id = h.attoamm_id and h.attoamm_stato_id = i.attoamm_stato_id and
l.movgest_id=e.movgest_id and m.movgest_tipo_id=l.movgest_tipo_id 
and n.movgest_ts_tipo_id=e.movgest_ts_tipo_id and
o.ente_proprietario_id=a.ente_proprietario_id 
and o.ambito_code=''AMBITO_FIN'' and
p.movgest_ts_id=e.movgest_ts_id and q.classif_id=p.classif_id 
and r.classif_tipo_id=q.classif_tipo_id and
r.classif_tipo_code like ''%PDC%'' and 
now() between b.validita_inizio and coalesce(b.validita_fine, now()) 
and now() between h.validita_inizio and coalesce(h.validita_fine, now()) 
and now() between p.validita_inizio and coalesce(p.validita_fine, now()) and
a.data_cancellazione is null and b.data_cancellazione is null 
and c.data_cancellazione is null and e.data_cancellazione is null 
and f.data_cancellazione is null and g.data_cancellazione is null 
and i.data_cancellazione is null 
and l.data_cancellazione is null and m.data_cancellazione is null 
and n.data_cancellazione is null and o.data_cancellazione is null 
and p.data_cancellazione is null and q.data_cancellazione is null 
and r.data_cancellazione is null and
--i.attoamm_stato_code=''DEFINITIVO'' and
--r.data_cancellazione is null and
a.attoamm_id='||attoamm_id_in||' and
 f.mod_stato_code = '''||mod_stato_code_in||''' '
;*/



--modifica impegno
for cur_mod_movgest_imp in --execute query
select tb.* from (
with mod as (
select 
a.mod_id,
c.movgest_ts_id, m.movgest_tipo_code,n.movgest_ts_tipo_code,
 m.movgest_tipo_code||n.movgest_ts_tipo_code tipo_movgest,
o.ambito_id,q.classif_id, l.bil_id
from siac_t_modifica a, 
siac_r_modifica_stato b,
siac_t_movgest_ts_det_mod c, 
siac_t_movgest_ts e, siac_d_modifica_stato f, siac_t_atto_amm g,
siac_r_atto_amm_stato h, siac_d_atto_amm_stato i, 
siac_t_movgest l,
siac_d_movgest_tipo m,siac_d_movgest_ts_tipo n, siac_d_ambito o,
siac_r_movgest_class p, siac_t_class q,siac_d_class_tipo r
where
f.mod_stato_code = mod_stato_code_in
--and i.attoamm_stato_code = 'DEFINITIVO' -- atto provvisorio
and a.mod_id = b.mod_id
and c.mod_stato_r_id = b.mod_stato_r_id
and e.movgest_ts_id = c.movgest_ts_id
and f.mod_stato_id = b.mod_stato_id
and a.attoamm_id = g.attoamm_id
and g.attoamm_id = h.attoamm_id
and h.attoamm_stato_id = i.attoamm_stato_id
and l.movgest_id=e.movgest_id
and m.movgest_tipo_id=l.movgest_tipo_id
and n.movgest_ts_tipo_id=e.movgest_ts_tipo_id
and a.attoamm_id=attoamm_id_in
and o.ente_proprietario_id=a.ente_proprietario_id
and o.ambito_code='AMBITO_FIN'
and p.movgest_ts_id=e.movgest_ts_id
and q.classif_id=p.classif_id
and r.classif_tipo_id=q.classif_tipo_id
and r.classif_tipo_code like '%PDC%'
and now() between b.validita_inizio and coalesce(b.validita_fine, now())
and now() between h.validita_inizio and coalesce(h.validita_fine, now())
and now() between p.validita_inizio and coalesce(p.validita_fine, now())
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
and e.data_cancellazione is null
and f.data_cancellazione is null
and g.data_cancellazione is null
--and h.data_cancellazione is null
and i.data_cancellazione is null
and l.data_cancellazione is null
and m.data_cancellazione is null
and n.data_cancellazione is null
and o.data_cancellazione is null
and p.data_cancellazione is null
and q.data_cancellazione is null
and r.data_cancellazione is null)
, /*condimp as (select distinct 
          d.movgest_ts_id
          from 
          siac_r_movgest_class a, siac_t_class b, siac_d_class_tipo c,siac_t_movgest_ts d
          where 
          d.movgest_ts_id=a.movgest_ts_id 
          --and  d.movgest_ts_id=cur_mod_movgest.movgest_ts_id
          and a.classif_id=b.classif_id
          and c.classif_tipo_id=b.classif_tipo_id and c.classif_tipo_code like 'PDC%'
          and (b.classif_code like 'U.1.04%' or b.classif_code like 'U.2.03%' or b.classif_code like 'U.2.04%' or 
          b.classif_code like 'U.2.05%' or b.classif_code like 'U.3%' or b.classif_code like 'U.4.01%' or 
          b.classif_code like 'U.4.02%' or b.classif_code like 'U.4.03%' or b.classif_code like 'U.4.04%' or 
          b.classif_code like 'U.5%' or b.classif_code like 'U.7.01%' or b.classif_code like 'U.7.02%')
          and a.data_cancellazione is NULL
          and b.data_cancellazione is null
          and c.data_cancellazione is null
          and d.data_cancellazione is null
          and now() BETWEEN a.validita_inizio and COALESCE(a.validita_fine,now())
          --soggetto collegato
          and ( 
               (    exists (
                             select 1
                             from siac_r_movgest_ts_sog sog
                             where sog.movgest_ts_id = a.movgest_ts_id
                           )
                ) or 
                (    
                    exists (
                             select 1
                             from siac_r_movgest_ts_sogclasse sogcl
                             where  sogcl.movgest_ts_id = a.movgest_ts_id
                    )
                ))    )     */
condimp as (
select tb.movgest_ts_id from (
with aa as (select distinct 
          d.movgest_ts_id
          from 
          siac_r_movgest_class a, siac_t_class b, siac_d_class_tipo c,siac_t_movgest_ts d
          where 
          d.movgest_ts_id=a.movgest_ts_id 
          --and  d.movgest_ts_id=cur_mod_movgest.movgest_ts_id
          and a.classif_id=b.classif_id
          and c.classif_tipo_id=b.classif_tipo_id and c.classif_tipo_code like 'PDC%'
          and (b.classif_code like 'U.1.04%' or b.classif_code like 'U.2.03%' or b.classif_code like 'U.2.04%' or 
          b.classif_code like 'U.2.05%' or b.classif_code like 'U.3%' or b.classif_code like 'U.4.01%' or 
          b.classif_code like 'U.4.02%' or b.classif_code like 'U.4.03%' or b.classif_code like 'U.4.04%' or 
          b.classif_code like 'U.5%' or b.classif_code like 'U.7.01%' or b.classif_code like 'U.7.02%')
          and a.data_cancellazione is NULL
          and b.data_cancellazione is null
          and c.data_cancellazione is null
          and d.data_cancellazione is null
          and now() BETWEEN a.validita_inizio and COALESCE(a.validita_fine,now())),
bb as (select movgest_ts_id from siac_r_movgest_ts_sog a
where a.ente_proprietario_id =ente_proprietario_new_id
UNION
select movgest_ts_id from siac_r_movgest_ts_sogclasse b
where b.ente_proprietario_id =ente_proprietario_new_id
)
select aa.movgest_ts_id from aa where exists (select 1 from bb where bb.movgest_ts_id=aa.movgest_ts_id)          
) as tb        
        )                
select mod.* from mod join condimp 
on mod.movgest_ts_id=condimp.movgest_ts_id    
) as tb            
loop

--raise notice 'dentro loop cur_mod_movgest';


--mod impegno FIN
      if cur_mod_movgest_imp.tipo_movgest='IT' then --impegno testata
          evento_code_reg_movfin:='MIM-INS-I';
      elsif cur_mod_movgest_imp.tipo_movgest='IS' then --impegno sub
          evento_code_reg_movfin:='MSI-INS-I';
      end if;
      
      
      INSERT INTO siac.siac_t_reg_movfin
(classif_id_iniziale,classif_id_aggiornato, bil_id, 
validita_inizio,ente_proprietario_id, login_operazione, ambito_id)
values (cur_mod_movgest_imp.classif_id,cur_mod_movgest_imp.classif_id,cur_mod_movgest_imp.bil_id, valid_inizio,
            ente_proprietario_new_id, login_oper, cur_mod_movgest_imp.ambito_id)
            returning regmovfin_id
into _regmovfin_id;



raise notice 'finimp:%', _regmovfin_id;

INSERT INTO siac.siac_r_reg_movfin_stato
(regmovfin_id,regmovfin_stato_id, validita_inizio, ente_proprietario_id, login_operazione)
select _regmovfin_id,
b.regmovfin_stato_id,
valid_inizio,
ente_proprietario_new_id,
login_oper
from siac_d_reg_movfin_stato b
where b.regmovfin_stato_code = 'N' and
b.ente_proprietario_id = ente_proprietario_new_id
and
now() between b.validita_inizio and COALESCE(b.validita_fine,now());


       
INSERT INTO siac.siac_r_evento_reg_movfin
(regmovfin_id, evento_id,campo_pk_id, validita_inizio, ente_proprietario_id, login_operazione)
select _regmovfin_id,
a.evento_id,
cur_mod_movgest_imp.mod_id,
valid_inizio,
ente_proprietario_new_id,
login_oper
from siac_d_evento a
where 
a.ente_proprietario_id = ente_proprietario_new_id AND
a.evento_code = evento_code_reg_movfin
and  now() between a.validita_inizio and COALESCE(a.validita_fine,now())
and a.data_cancellazione is null
;
return next;

end loop;
        _regmovfin_id:=null;
        
        
--mod accertamento FIN
for cur_mod_movgest_acc in 
select tb.* from (
with mod as (
select 
a.mod_id,
c.movgest_ts_id, m.movgest_tipo_code,n.movgest_ts_tipo_code,
 m.movgest_tipo_code||n.movgest_ts_tipo_code tipo_movgest,
o.ambito_id,q.classif_id, l.bil_id
from siac_t_modifica a, 
siac_r_modifica_stato b,
siac_t_movgest_ts_det_mod c, 
siac_t_movgest_ts e, siac_d_modifica_stato f, siac_t_atto_amm g,
siac_r_atto_amm_stato h, siac_d_atto_amm_stato i, 
siac_t_movgest l,
siac_d_movgest_tipo m,siac_d_movgest_ts_tipo n, siac_d_ambito o,
siac_r_movgest_class p, siac_t_class q,siac_d_class_tipo r
where
f.mod_stato_code = mod_stato_code_in
--and i.attoamm_stato_code = 'DEFINITIVO' -- atto provvisorio
and a.mod_id = b.mod_id
and c.mod_stato_r_id = b.mod_stato_r_id
and e.movgest_ts_id = c.movgest_ts_id
and f.mod_stato_id = b.mod_stato_id
and a.attoamm_id = g.attoamm_id
and g.attoamm_id = h.attoamm_id
and h.attoamm_stato_id = i.attoamm_stato_id
and l.movgest_id=e.movgest_id
and m.movgest_tipo_id=l.movgest_tipo_id
and n.movgest_ts_tipo_id=e.movgest_ts_tipo_id
and a.attoamm_id=attoamm_id_in
and o.ente_proprietario_id=a.ente_proprietario_id
and o.ambito_code='AMBITO_FIN'
and p.movgest_ts_id=e.movgest_ts_id
and q.classif_id=p.classif_id
and r.classif_tipo_id=q.classif_tipo_id
and r.classif_tipo_code like '%PDC%'
and now() between b.validita_inizio and coalesce(b.validita_fine, now())
and now() between h.validita_inizio and coalesce(h.validita_fine, now())
and now() between p.validita_inizio and coalesce(p.validita_fine, now())
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
and e.data_cancellazione is null
and f.data_cancellazione is null
and g.data_cancellazione is null
--and h.data_cancellazione is null
and i.data_cancellazione is null
and l.data_cancellazione is null
and m.data_cancellazione is null
and n.data_cancellazione is null
and o.data_cancellazione is null
and p.data_cancellazione is null
and q.data_cancellazione is null
and r.data_cancellazione is null)
, condacc as (select distinct d.movgest_ts_id
        from siac_r_movgest_class a,
             siac_t_class b,
             siac_d_class_tipo c,
             siac_t_movgest_ts d,
             siac_d_ambito e,
             siac_r_movgest_ts_attr f ,siac_t_attr g
             --,siac_r_movgest_ts_stato h, siac_d_movgest_stato i
        where a.classif_id = b.classif_id and
              b.classif_tipo_id = c.classif_tipo_id and
              c.classif_tipo_code like 'PDC%' and
              d.movgest_ts_id = a.movgest_ts_id and
              --d.movgest_ts_id = cur_mod_movgest.movgest_ts_id and
              e.ente_proprietario_id = b.ente_proprietario_id and
              a.data_cancellazione is null and
              b.data_cancellazione is null and
              c.data_cancellazione is null and
              d.data_cancellazione is null and
              e.data_cancellazione is null and
              e.ambito_code = 'AMBITO_FIN' and 
              now() between a.validita_inizio and COALESCE(a.validita_fine,now()) and 
              f.movgest_ts_id=d.movgest_ts_id and 
              g.attr_id=f.attr_id and 
              g.attr_code='FlagCollegamentoAccertamentoFattura' and 
              f."boolean"='N' and 
              now() between f.validita_inizio and COALESCE(f.validita_fine,now()) and
              --h.movgest_ts_id=d.movgest_ts_id and
              --i.movgest_stato_id=h.movgest_stato_id and 
              --now() between h.validita_inizio and COALESCE(h.validita_fine,now()) and
              --i.movgest_stato_code='D' and
              f.data_cancellazione is null and
              g.data_cancellazione is null 
              -- and h.data_cancellazione is null and
              -- i.data_cancellazione is null
              )
select mod.* from mod join condacc
on mod.movgest_ts_id=condacc.movgest_ts_id) tb
loop

      if cur_mod_movgest_acc.tipo_movgest='AT' then --accertamento testata
        evento_code_reg_movfin:='MAC-INS-I';
      elsif cur_mod_movgest_acc.tipo_movgest='AS' then --accertamento sub
        evento_code_reg_movfin:='MSA-INS-I';
      end if;


      INSERT INTO siac.siac_t_reg_movfin
      (classif_id_iniziale,classif_id_aggiornato, bil_id, 
      validita_inizio,ente_proprietario_id, login_operazione, ambito_id)
      values (cur_mod_movgest_acc.classif_id,cur_mod_movgest_acc.classif_id,cur_mod_movgest_acc.bil_id, valid_inizio,
                  ente_proprietario_new_id, login_oper, cur_mod_movgest_acc.ambito_id)
                  returning regmovfin_id
      into _regmovfin_id;

    
      raise notice 'finimp:%', _regmovfin_id;

      INSERT INTO siac.siac_r_reg_movfin_stato
      (regmovfin_id,regmovfin_stato_id, validita_inizio, ente_proprietario_id, login_operazione)
      select _regmovfin_id,
      b.regmovfin_stato_id,
      valid_inizio,
      ente_proprietario_new_id,
      login_oper
      from siac_d_reg_movfin_stato b
      where b.regmovfin_stato_code = 'N' and
      b.ente_proprietario_id = ente_proprietario_new_id
      and
      now() between b.validita_inizio and COALESCE(b.validita_fine,now());


                 
      INSERT INTO siac.siac_r_evento_reg_movfin
      (regmovfin_id, evento_id,campo_pk_id, validita_inizio, ente_proprietario_id, login_operazione)
      select _regmovfin_id,
      a.evento_id,
      cur_mod_movgest_acc.mod_id,
      valid_inizio,
      ente_proprietario_new_id,
      login_oper
      from siac_d_evento a
      where 
      a.ente_proprietario_id = ente_proprietario_new_id AND
      a.evento_code = evento_code_reg_movfin
      and  now() between a.validita_inizio and COALESCE(a.validita_fine,now())
      and a.data_cancellazione is null
      ;

	  return next;

end loop; --fine accertamento fin
        _regmovfin_id:=null;
--------modifiche GSA------------------------------------------------------

--impegno GSA mod importo
for cur_mod_movgest_imp_gsa in
select tb.* from (
with mod as (
select 
a.mod_id,
c.movgest_ts_id, m.movgest_tipo_code,n.movgest_ts_tipo_code,
 m.movgest_tipo_code||n.movgest_ts_tipo_code tipo_movgest,
o.ambito_id,q.classif_id, l.bil_id
from siac_t_modifica a, 
siac_r_modifica_stato b,
siac_t_movgest_ts_det_mod c, 
siac_t_movgest_ts e, siac_d_modifica_stato f, siac_t_atto_amm g,
siac_r_atto_amm_stato h, siac_d_atto_amm_stato i, 
siac_t_movgest l,
siac_d_movgest_tipo m,siac_d_movgest_ts_tipo n, siac_d_ambito o,
siac_r_movgest_class p, siac_t_class q,siac_d_class_tipo r
where
f.mod_stato_code = mod_stato_code_in
--and i.attoamm_stato_code = 'DEFINITIVO' -- atto provvisorio
and a.mod_id = b.mod_id
and c.mod_stato_r_id = b.mod_stato_r_id
and e.movgest_ts_id = c.movgest_ts_id
and f.mod_stato_id = b.mod_stato_id
and a.attoamm_id = g.attoamm_id
and g.attoamm_id = h.attoamm_id
and h.attoamm_stato_id = i.attoamm_stato_id
and l.movgest_id=e.movgest_id
and m.movgest_tipo_id=l.movgest_tipo_id
and n.movgest_ts_tipo_id=e.movgest_ts_tipo_id
and a.attoamm_id=attoamm_id_in
and o.ente_proprietario_id=a.ente_proprietario_id
and o.ambito_code='AMBITO_GSA'
and p.movgest_ts_id=e.movgest_ts_id
and q.classif_id=p.classif_id
and r.classif_tipo_id=q.classif_tipo_id
and r.classif_tipo_code like '%PDC%'
and now() between b.validita_inizio and coalesce(b.validita_fine, now())
and now() between h.validita_inizio and coalesce(h.validita_fine, now())
and now() between p.validita_inizio and coalesce(p.validita_fine, now())
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
and e.data_cancellazione is null
and f.data_cancellazione is null
and g.data_cancellazione is null
--and h.data_cancellazione is null
and i.data_cancellazione is null
and l.data_cancellazione is null
and m.data_cancellazione is null
and n.data_cancellazione is null
and o.data_cancellazione is null
and p.data_cancellazione is null
and q.data_cancellazione is null
and r.data_cancellazione is null)
, /*condimp as (select distinct 
          d.movgest_ts_id
          from 
          siac_r_movgest_class a, siac_t_class b, siac_d_class_tipo c,siac_t_movgest_ts d
          where 
          d.movgest_ts_id=a.movgest_ts_id 
          --and  d.movgest_ts_id=cur_mod_movgest.movgest_ts_id
          and a.classif_id=b.classif_id
          and c.classif_tipo_id=b.classif_tipo_id and c.classif_tipo_code like 'PDC%'
          and (b.classif_code like 'U.1.04%' or b.classif_code like 'U.2.03%' or b.classif_code like 'U.2.04%' or 
          b.classif_code like 'U.2.05%' or b.classif_code like 'U.3%' or b.classif_code like 'U.4.01%' or 
          b.classif_code like 'U.4.02%' or b.classif_code like 'U.4.03%' or b.classif_code like 'U.4.04%' or 
          b.classif_code like 'U.5%' or b.classif_code like 'U.7.01%' or b.classif_code like 'U.7.02%')
          and a.data_cancellazione is NULL
          and b.data_cancellazione is null
          and c.data_cancellazione is null
          and d.data_cancellazione is null
          and now() BETWEEN a.validita_inizio and COALESCE(a.validita_fine,now())
          --soggetto collegato
          and ( 
               (    exists (
                             select 1
                             from siac_r_movgest_ts_sog sog
                             where sog.movgest_ts_id = a.movgest_ts_id
                           )
                ) or 
                (    
                    exists (
                             select 1
                             from siac_r_movgest_ts_sogclasse sogcl
                             where  sogcl.movgest_ts_id = a.movgest_ts_id
                    )
                ))    )*/
condimp as (
select tb.movgest_ts_id from (
with aa as (select distinct 
          d.movgest_ts_id
          from 
          siac_r_movgest_class a, siac_t_class b, siac_d_class_tipo c,siac_t_movgest_ts d
          where 
          d.movgest_ts_id=a.movgest_ts_id 
          --and  d.movgest_ts_id=cur_mod_movgest.movgest_ts_id
          and a.classif_id=b.classif_id
          and c.classif_tipo_id=b.classif_tipo_id and c.classif_tipo_code like 'PDC%'
          and (b.classif_code like 'U.1.04%' or b.classif_code like 'U.2.03%' or b.classif_code like 'U.2.04%' or 
          b.classif_code like 'U.2.05%' or b.classif_code like 'U.3%' or b.classif_code like 'U.4.01%' or 
          b.classif_code like 'U.4.02%' or b.classif_code like 'U.4.03%' or b.classif_code like 'U.4.04%' or 
          b.classif_code like 'U.5%' or b.classif_code like 'U.7.01%' or b.classif_code like 'U.7.02%')
          and a.data_cancellazione is NULL
          and b.data_cancellazione is null
          and c.data_cancellazione is null
          and d.data_cancellazione is null
          and now() BETWEEN a.validita_inizio and COALESCE(a.validita_fine,now())),
bb as (select movgest_ts_id from siac_r_movgest_ts_sog a
where a.ente_proprietario_id =ente_proprietario_new_id
UNION
select movgest_ts_id from siac_r_movgest_ts_sogclasse b
where b.ente_proprietario_id =ente_proprietario_new_id
)
select aa.movgest_ts_id from aa where exists (select 1 from bb where bb.movgest_ts_id=aa.movgest_ts_id)          
) as tb        
        )                
                ,
gsa as (select a.movgest_ts_id
    from siac_r_movgest_ts_attr a,
             siac_t_attr b,
             siac_d_ambito c
        where
              a.attr_id = b.attr_id and
              b.attr_code = 'FlagAttivaGsa' and
              c.ente_proprietario_id = b.ente_proprietario_id and
              c.ambito_code = 'AMBITO_GSA' and
              a."boolean" = 'S' and
              now() between a.validita_inizio and COALESCE(a.validita_fine,now())
              and a.data_cancellazione is null
              and b.data_cancellazione is null
              and c.data_cancellazione is null)                
select mod.* from mod join condimp 
on mod.movgest_ts_id=condimp.movgest_ts_id   
join gsa on mod.movgest_ts_id=gsa.movgest_ts_id 
) tb
loop

    if cur_mod_movgest_imp_gsa.tipo_movgest='IT' then --impegno testata
          evento_code_reg_movfin:='MIM-INS-I';
      elsif cur_mod_movgest_imp_gsa.tipo_movgest='IS' then --impegno sub
          evento_code_reg_movfin:='MSI-INS-I';
      end if;
      
      
      INSERT INTO siac.siac_t_reg_movfin
(classif_id_iniziale,classif_id_aggiornato, bil_id, 
validita_inizio,ente_proprietario_id, login_operazione, ambito_id)
values (cur_mod_movgest_imp_gsa.classif_id,cur_mod_movgest_imp_gsa.classif_id,
cur_mod_movgest_imp_gsa.bil_id, valid_inizio,
            ente_proprietario_new_id, login_oper, cur_mod_movgest_imp_gsa.ambito_id)
            returning regmovfin_id
into _regmovfin_id;



INSERT INTO siac.siac_r_reg_movfin_stato
(regmovfin_id,regmovfin_stato_id, validita_inizio, ente_proprietario_id, login_operazione)
select _regmovfin_id,
b.regmovfin_stato_id,
valid_inizio,
ente_proprietario_new_id,
login_oper
from siac_d_reg_movfin_stato b
where b.regmovfin_stato_code = 'N' and
b.ente_proprietario_id = ente_proprietario_new_id
and
now() between b.validita_inizio and COALESCE(b.validita_fine,now());


       
INSERT INTO siac.siac_r_evento_reg_movfin
(regmovfin_id, evento_id,campo_pk_id, validita_inizio, ente_proprietario_id, login_operazione)
select _regmovfin_id,
a.evento_id,
cur_mod_movgest_imp_gsa.mod_id,
valid_inizio,
ente_proprietario_new_id,
login_oper
from siac_d_evento a
where 
a.ente_proprietario_id = ente_proprietario_new_id AND
a.evento_code = evento_code_reg_movfin
and  now() between a.validita_inizio and COALESCE(a.validita_fine,now())
and a.data_cancellazione is null
;
return next;

end loop; --fine impegno GSA mod importo
        _regmovfin_id:=null;


----impegno GSA mod soggetto
for cur_mod_movgest_imp_gsa_sog in
select tb.* from  (
with mod as (
select 
a.mod_id,
c.movgest_ts_id, m.movgest_tipo_code,n.movgest_ts_tipo_code,
 m.movgest_tipo_code||n.movgest_ts_tipo_code tipo_movgest,
o.ambito_id,q.classif_id, l.bil_id
from siac_t_modifica a, 
siac_r_modifica_stato b,
siac_r_movgest_ts_sog_mod c,
siac_t_movgest_ts e, siac_d_modifica_stato f, siac_t_atto_amm g,
siac_r_atto_amm_stato h, siac_d_atto_amm_stato i, 
siac_t_movgest l,
siac_d_movgest_tipo m,siac_d_movgest_ts_tipo n, siac_d_ambito o,
siac_r_movgest_class p, siac_t_class q,siac_d_class_tipo r
where
f.mod_stato_code = 'V' -- la modifica deve essere valida
--and i.attoamm_stato_code = 'DEFINITIVO' -- atto provvisorio
and a.mod_id = b.mod_id
and c.mod_stato_r_id = b.mod_stato_r_id
and e.movgest_ts_id = c.movgest_ts_id
and f.mod_stato_id = b.mod_stato_id
and a.attoamm_id = g.attoamm_id
and g.attoamm_id = h.attoamm_id
and h.attoamm_stato_id = i.attoamm_stato_id
and l.movgest_id=e.movgest_id
and m.movgest_tipo_id=l.movgest_tipo_id
and n.movgest_ts_tipo_id=e.movgest_ts_tipo_id
and a.attoamm_id=attoamm_id_in
and o.ente_proprietario_id=a.ente_proprietario_id
and o.ambito_code='AMBITO_FIN'
and p.movgest_ts_id=e.movgest_ts_id
and q.classif_id=p.classif_id
and r.classif_tipo_id=q.classif_tipo_id
and r.classif_tipo_code like '%PDC%'
and now() between b.validita_inizio and coalesce(b.validita_fine, now())
and now() between h.validita_inizio and coalesce(h.validita_fine, now())
and now() between p.validita_inizio and coalesce(p.validita_fine, now())
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
and e.data_cancellazione is null
and f.data_cancellazione is null
and g.data_cancellazione is null
--and h.data_cancellazione is null
and i.data_cancellazione is null
and l.data_cancellazione is null
and m.data_cancellazione is null
and n.data_cancellazione is null
and o.data_cancellazione is null
and p.data_cancellazione is null
and q.data_cancellazione is null
and r.data_cancellazione is null
)
, /*condimp as (select distinct 
          d.movgest_ts_id
          from 
          siac_r_movgest_class a, siac_t_class b, siac_d_class_tipo c,siac_t_movgest_ts d
          where 
          d.movgest_ts_id=a.movgest_ts_id 
          --and  d.movgest_ts_id=cur_mod_movgest.movgest_ts_id
          and a.classif_id=b.classif_id
          and c.classif_tipo_id=b.classif_tipo_id and c.classif_tipo_code like 'PDC%'
          and (b.classif_code like 'U.1.04%' or b.classif_code like 'U.2.03%' or b.classif_code like 'U.2.04%' or 
          b.classif_code like 'U.2.05%' or b.classif_code like 'U.3%' or b.classif_code like 'U.4.01%' or 
          b.classif_code like 'U.4.02%' or b.classif_code like 'U.4.03%' or b.classif_code like 'U.4.04%' or 
          b.classif_code like 'U.5%' or b.classif_code like 'U.7.01%' or b.classif_code like 'U.7.02%')
          and a.data_cancellazione is NULL
          and b.data_cancellazione is null
          and c.data_cancellazione is null
          and d.data_cancellazione is null
          and now() BETWEEN a.validita_inizio and COALESCE(a.validita_fine,now())
          --soggetto collegato
          and ( 
               (    exists (
                             select 1
                             from siac_r_movgest_ts_sog sog
                             where sog.movgest_ts_id = a.movgest_ts_id
                           )
                ) or 
                (    
                    exists (
                             select 1
                             from siac_r_movgest_ts_sogclasse sogcl
                             where  sogcl.movgest_ts_id = a.movgest_ts_id
                    )
                ))    )*/
condimp as (
select tb.movgest_ts_id from (
with aa as (select distinct 
          d.movgest_ts_id
          from 
          siac_r_movgest_class a, siac_t_class b, siac_d_class_tipo c,siac_t_movgest_ts d
          where 
          d.movgest_ts_id=a.movgest_ts_id 
          --and  d.movgest_ts_id=cur_mod_movgest.movgest_ts_id
          and a.classif_id=b.classif_id
          and c.classif_tipo_id=b.classif_tipo_id and c.classif_tipo_code like 'PDC%'
          and (b.classif_code like 'U.1.04%' or b.classif_code like 'U.2.03%' or b.classif_code like 'U.2.04%' or 
          b.classif_code like 'U.2.05%' or b.classif_code like 'U.3%' or b.classif_code like 'U.4.01%' or 
          b.classif_code like 'U.4.02%' or b.classif_code like 'U.4.03%' or b.classif_code like 'U.4.04%' or 
          b.classif_code like 'U.5%' or b.classif_code like 'U.7.01%' or b.classif_code like 'U.7.02%')
          and a.data_cancellazione is NULL
          and b.data_cancellazione is null
          and c.data_cancellazione is null
          and d.data_cancellazione is null
          and now() BETWEEN a.validita_inizio and COALESCE(a.validita_fine,now())),
bb as (select movgest_ts_id from siac_r_movgest_ts_sog a
where a.ente_proprietario_id =ente_proprietario_new_id
UNION
select movgest_ts_id from siac_r_movgest_ts_sogclasse b
where b.ente_proprietario_id =ente_proprietario_new_id
)
select aa.movgest_ts_id from aa where exists (select 1 from bb where bb.movgest_ts_id=aa.movgest_ts_id)          
) as tb        
        )                
                ,
gsa as (select a.movgest_ts_id
    from siac_r_movgest_ts_attr a,
             siac_t_attr b,
             siac_d_ambito c
        where
              a.attr_id = b.attr_id and
              b.attr_code = 'FlagAttivaGsa' and
              c.ente_proprietario_id = b.ente_proprietario_id and
              c.ambito_code = 'AMBITO_GSA' and
              a."boolean" = 'S' and
              now() between a.validita_inizio and COALESCE(a.validita_fine,now())
              and a.data_cancellazione is null
              and b.data_cancellazione is null
              and c.data_cancellazione is null)                
select mod.* from mod join condimp 
on mod.movgest_ts_id=condimp.movgest_ts_id   
join gsa on mod.movgest_ts_id=gsa.movgest_ts_id 
) tb 
loop

    if cur_mod_movgest_imp_gsa_sog.tipo_movgest='IT' then --impegno testata
          evento_code_reg_movfin:='MIM-INS-I';
      elsif cur_mod_movgest_imp_gsa_sog.tipo_movgest='IS' then --impegno sub
          evento_code_reg_movfin:='MSI-INS-I';
      end if;
      
      
      INSERT INTO siac.siac_t_reg_movfin
(classif_id_iniziale,classif_id_aggiornato, bil_id, 
validita_inizio,ente_proprietario_id, login_operazione, ambito_id)
values (cur_mod_movgest_imp_gsa_sog.classif_id,cur_mod_movgest_imp_gsa_sog.classif_id,
cur_mod_movgest_imp_gsa_sog.bil_id, valid_inizio,
            ente_proprietario_new_id, login_oper, cur_mod_movgest_imp_gsa_sog.ambito_id)
            returning regmovfin_id
into _regmovfin_id;



INSERT INTO siac.siac_r_reg_movfin_stato
(regmovfin_id,regmovfin_stato_id, validita_inizio, ente_proprietario_id, login_operazione)
select _regmovfin_id,
b.regmovfin_stato_id,
valid_inizio,
ente_proprietario_new_id,
login_oper
from siac_d_reg_movfin_stato b
where b.regmovfin_stato_code = 'N' and
b.ente_proprietario_id = ente_proprietario_new_id
and
now() between b.validita_inizio and COALESCE(b.validita_fine,now());


       
INSERT INTO siac.siac_r_evento_reg_movfin
(regmovfin_id, evento_id,campo_pk_id, validita_inizio, ente_proprietario_id, login_operazione)
select _regmovfin_id,
a.evento_id,
cur_mod_movgest_imp_gsa_sog.mod_id,
valid_inizio,
ente_proprietario_new_id,
login_oper
from siac_d_evento a
where 
a.ente_proprietario_id = ente_proprietario_new_id AND
a.evento_code = evento_code_reg_movfin
and  now() between a.validita_inizio and COALESCE(a.validita_fine,now())
and a.data_cancellazione is null
;
return next;

end loop; --fine impegno GSA mod soggetto
        _regmovfin_id:=null;






--mod accertamento GSA importo
for cur_mod_movgest_acc_gsa in 
select tb.* from (
with mod as (
select 
a.mod_id,
c.movgest_ts_id, m.movgest_tipo_code,n.movgest_ts_tipo_code,
 m.movgest_tipo_code||n.movgest_ts_tipo_code tipo_movgest,
o.ambito_id,q.classif_id, l.bil_id
from siac_t_modifica a, 
siac_r_modifica_stato b,
siac_t_movgest_ts_det_mod c, 
siac_t_movgest_ts e, siac_d_modifica_stato f, siac_t_atto_amm g,
siac_r_atto_amm_stato h, siac_d_atto_amm_stato i, 
siac_t_movgest l,
siac_d_movgest_tipo m,siac_d_movgest_ts_tipo n, siac_d_ambito o,
siac_r_movgest_class p, siac_t_class q,siac_d_class_tipo r
where
f.mod_stato_code = mod_stato_code_in
--and i.attoamm_stato_code = 'DEFINITIVO' -- atto provvisorio
and a.mod_id = b.mod_id
and c.mod_stato_r_id = b.mod_stato_r_id
and e.movgest_ts_id = c.movgest_ts_id
and f.mod_stato_id = b.mod_stato_id
and a.attoamm_id = g.attoamm_id
and g.attoamm_id = h.attoamm_id
and h.attoamm_stato_id = i.attoamm_stato_id
and l.movgest_id=e.movgest_id
and m.movgest_tipo_id=l.movgest_tipo_id
and n.movgest_ts_tipo_id=e.movgest_ts_tipo_id
and a.attoamm_id=attoamm_id_in
and o.ente_proprietario_id=a.ente_proprietario_id
and o.ambito_code='AMBITO_FIN'
and p.movgest_ts_id=e.movgest_ts_id
and q.classif_id=p.classif_id
and r.classif_tipo_id=q.classif_tipo_id
and r.classif_tipo_code like '%PDC%'
and now() between b.validita_inizio and coalesce(b.validita_fine, now())
and now() between h.validita_inizio and coalesce(h.validita_fine, now())
and now() between p.validita_inizio and coalesce(p.validita_fine, now())
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
and e.data_cancellazione is null
and f.data_cancellazione is null
and g.data_cancellazione is null
--and h.data_cancellazione is null
and i.data_cancellazione is null
and l.data_cancellazione is null
and m.data_cancellazione is null
and n.data_cancellazione is null
and o.data_cancellazione is null
and p.data_cancellazione is null
and q.data_cancellazione is null
and r.data_cancellazione is null)
, condacc as (select distinct d.movgest_ts_id
        from siac_r_movgest_class a,
             siac_t_class b,
             siac_d_class_tipo c,
             siac_t_movgest_ts d,
             siac_d_ambito e,
             siac_r_movgest_ts_attr f ,siac_t_attr g
             --,siac_r_movgest_ts_stato h, siac_d_movgest_stato i
        where a.classif_id = b.classif_id and
              b.classif_tipo_id = c.classif_tipo_id and
              c.classif_tipo_code like 'PDC%' and
              d.movgest_ts_id = a.movgest_ts_id and
              --d.movgest_ts_id = cur_mod_movgest.movgest_ts_id and
              e.ente_proprietario_id = b.ente_proprietario_id and
              a.data_cancellazione is null and
              b.data_cancellazione is null and
              c.data_cancellazione is null and
              d.data_cancellazione is null and
              e.data_cancellazione is null and
              e.ambito_code = 'AMBITO_FIN' and 
              now() between a.validita_inizio and COALESCE(a.validita_fine,now()) and 
              f.movgest_ts_id=d.movgest_ts_id and 
              g.attr_id=f.attr_id and 
              g.attr_code='FlagCollegamentoAccertamentoFattura' and 
              f."boolean"='N' and 
              now() between f.validita_inizio and COALESCE(f.validita_fine,now()) and
              --h.movgest_ts_id=d.movgest_ts_id and
              --i.movgest_stato_id=h.movgest_stato_id and 
              --now() between h.validita_inizio and COALESCE(h.validita_fine,now()) and
              --i.movgest_stato_code='D' and
              f.data_cancellazione is null and
              g.data_cancellazione is null 
              --and  h.data_cancellazione is null and
              --i.data_cancellazione is null
              )
,
gsa as (select a.movgest_ts_id
    from siac_r_movgest_ts_attr a,
             siac_t_attr b,
             siac_d_ambito c
        where
              a.attr_id = b.attr_id and
              b.attr_code = 'FlagAttivaGsa' and
              c.ente_proprietario_id = b.ente_proprietario_id and
              c.ambito_code = 'AMBITO_GSA' and
              a."boolean" = 'S' and
              now() between a.validita_inizio and COALESCE(a.validita_fine,now())
              and a.data_cancellazione is null
              and b.data_cancellazione is null
              and c.data_cancellazione is null)                      
select mod.* from mod join condacc
on mod.movgest_ts_id=condacc.movgest_ts_id
join gsa on mod.movgest_ts_id=gsa.movgest_ts_id
) tb
loop

      if cur_mod_movgest_acc_gsa.tipo_movgest='AT' then --accertamento testata
        evento_code_reg_movfin:='MAC-INS-I';
      elsif cur_mod_movgest_acc_gsa.tipo_movgest='AS' then --accertamento sub
        evento_code_reg_movfin:='MSA-INS-I';
      end if;


      INSERT INTO siac.siac_t_reg_movfin
      (classif_id_iniziale,classif_id_aggiornato, bil_id, 
      validita_inizio,ente_proprietario_id, login_operazione, ambito_id)
      values (cur_mod_movgest_acc_gsa.classif_id,cur_mod_movgest_acc_gsa.classif_id,cur_mod_movgest_acc_gsa.bil_id, valid_inizio,
                  ente_proprietario_new_id, login_oper, cur_mod_movgest_acc_gsa.ambito_id)
                  returning regmovfin_id
      into _regmovfin_id;

 
      INSERT INTO siac.siac_r_reg_movfin_stato
      (regmovfin_id,regmovfin_stato_id, validita_inizio, ente_proprietario_id, login_operazione)
      select _regmovfin_id,
      b.regmovfin_stato_id,
      valid_inizio,
      ente_proprietario_new_id,
      login_oper
      from siac_d_reg_movfin_stato b
      where b.regmovfin_stato_code = 'N' and
      b.ente_proprietario_id = ente_proprietario_new_id
      and
      now() between b.validita_inizio and COALESCE(b.validita_fine,now());


                 
      INSERT INTO siac.siac_r_evento_reg_movfin
      (regmovfin_id, evento_id,campo_pk_id, validita_inizio, ente_proprietario_id, login_operazione)
      select _regmovfin_id,
      a.evento_id,
      cur_mod_movgest_acc_gsa.mod_id,
      valid_inizio,
      ente_proprietario_new_id,
      login_oper
      from siac_d_evento a
      where 
      a.ente_proprietario_id = ente_proprietario_new_id AND
      a.evento_code = evento_code_reg_movfin
      and  now() between a.validita_inizio and COALESCE(a.validita_fine,now())
      and a.data_cancellazione is null
      ;

	  return next;

end loop;--fine mod accertamento GSA importo

 
        _regmovfin_id:=null;



--mod accertamento GSA soggetto
for cur_mod_movgest_acc_gsa_sog in 
select tb.* from (
with mod as (
select 
a.mod_id,
c.movgest_ts_id, m.movgest_tipo_code,n.movgest_ts_tipo_code,
 m.movgest_tipo_code||n.movgest_ts_tipo_code tipo_movgest,
o.ambito_id,q.classif_id, l.bil_id
from siac_t_modifica a, 
siac_r_modifica_stato b,
siac_r_movgest_ts_sog_mod c,
siac_t_movgest_ts e, siac_d_modifica_stato f, siac_t_atto_amm g,
siac_r_atto_amm_stato h, siac_d_atto_amm_stato i, 
siac_t_movgest l,
siac_d_movgest_tipo m,siac_d_movgest_ts_tipo n, siac_d_ambito o,
siac_r_movgest_class p, siac_t_class q,siac_d_class_tipo r
where
f.mod_stato_code = 'V' -- la modifica deve essere valida
--and i.attoamm_stato_code = 'DEFINITIVO' -- atto provvisorio
and a.mod_id = b.mod_id
and c.mod_stato_r_id = b.mod_stato_r_id
and e.movgest_ts_id = c.movgest_ts_id
and f.mod_stato_id = b.mod_stato_id
and a.attoamm_id = g.attoamm_id
and g.attoamm_id = h.attoamm_id
and h.attoamm_stato_id = i.attoamm_stato_id
and l.movgest_id=e.movgest_id
and m.movgest_tipo_id=l.movgest_tipo_id
and n.movgest_ts_tipo_id=e.movgest_ts_tipo_id
and a.attoamm_id=attoamm_id_in
and o.ente_proprietario_id=a.ente_proprietario_id
and o.ambito_code='AMBITO_FIN'
and p.movgest_ts_id=e.movgest_ts_id
and q.classif_id=p.classif_id
and r.classif_tipo_id=q.classif_tipo_id
and r.classif_tipo_code like '%PDC%'
and now() between b.validita_inizio and coalesce(b.validita_fine, now())
and now() between h.validita_inizio and coalesce(h.validita_fine, now())
and now() between p.validita_inizio and coalesce(p.validita_fine, now())
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
and e.data_cancellazione is null
and f.data_cancellazione is null
and g.data_cancellazione is null
--and h.data_cancellazione is null
and i.data_cancellazione is null
and l.data_cancellazione is null
and m.data_cancellazione is null
and n.data_cancellazione is null
and o.data_cancellazione is null
and p.data_cancellazione is null
and q.data_cancellazione is null
and r.data_cancellazione is null)
, condacc as (select distinct d.movgest_ts_id
        from siac_r_movgest_class a,
             siac_t_class b,
             siac_d_class_tipo c,
             siac_t_movgest_ts d,
             siac_d_ambito e,
             siac_r_movgest_ts_attr f ,siac_t_attr g
             --,siac_r_movgest_ts_stato h, siac_d_movgest_stato i
        where a.classif_id = b.classif_id and
              b.classif_tipo_id = c.classif_tipo_id and
              c.classif_tipo_code like 'PDC%' and
              d.movgest_ts_id = a.movgest_ts_id and
              --d.movgest_ts_id = cur_mod_movgest.movgest_ts_id and
              e.ente_proprietario_id = b.ente_proprietario_id and
              a.data_cancellazione is null and
              b.data_cancellazione is null and
              c.data_cancellazione is null and
              d.data_cancellazione is null and
              e.data_cancellazione is null and
              e.ambito_code = 'AMBITO_FIN' and 
              now() between a.validita_inizio and COALESCE(a.validita_fine,now()) and 
              f.movgest_ts_id=d.movgest_ts_id and 
              g.attr_id=f.attr_id and 
              g.attr_code='FlagCollegamentoAccertamentoFattura' and 
              f."boolean"='N' and 
              now() between f.validita_inizio and COALESCE(f.validita_fine,now()) and
              --h.movgest_ts_id=d.movgest_ts_id and
              --i.movgest_stato_id=h.movgest_stato_id and 
              --now() between h.validita_inizio and COALESCE(h.validita_fine,now()) and
              --i.movgest_stato_code='D' and
              f.data_cancellazione is null and
              g.data_cancellazione is null 
              --and h.data_cancellazione is null and
              --i.data_cancellazione is null
              )
,
gsa as (select a.movgest_ts_id
    from siac_r_movgest_ts_attr a,
             siac_t_attr b,
             siac_d_ambito c
        where
              a.attr_id = b.attr_id and
              b.attr_code = 'FlagAttivaGsa' and
              c.ente_proprietario_id = b.ente_proprietario_id and
              c.ambito_code = 'AMBITO_GSA' and
              a."boolean" = 'S' and
              now() between a.validita_inizio and COALESCE(a.validita_fine,now())
              and a.data_cancellazione is null
              and b.data_cancellazione is null
              and c.data_cancellazione is null)                      
select mod.* from mod join condacc
on mod.movgest_ts_id=condacc.movgest_ts_id
join gsa on mod.movgest_ts_id=gsa.movgest_ts_id
) tb
loop

      if cur_mod_movgest_acc_gsa_sog.tipo_movgest='AT' then --accertamento testata
        evento_code_reg_movfin:='MAC-INS-I';
      elsif cur_mod_movgest_acc_gsa_sog.tipo_movgest='AS' then --accertamento sub
        evento_code_reg_movfin:='MSA-INS-I';
      end if;


      INSERT INTO siac.siac_t_reg_movfin
      (classif_id_iniziale,classif_id_aggiornato, bil_id, 
      validita_inizio,ente_proprietario_id, login_operazione, ambito_id)
      values (cur_mod_movgest_acc_gsa_sog.classif_id,cur_mod_movgest_acc_gsa_sog.classif_id,
      cur_mod_movgest_acc_gsa_sog.bil_id, valid_inizio,
                  ente_proprietario_new_id, login_oper, cur_mod_movgest_acc_gsa_sog.ambito_id)
                  returning regmovfin_id
      into _regmovfin_id;

    

      INSERT INTO siac.siac_r_reg_movfin_stato
      (regmovfin_id,regmovfin_stato_id, validita_inizio, ente_proprietario_id, login_operazione)
      select _regmovfin_id,
      b.regmovfin_stato_id,
      valid_inizio,
      ente_proprietario_new_id,
      login_oper
      from siac_d_reg_movfin_stato b
      where b.regmovfin_stato_code = 'N' and
      b.ente_proprietario_id = ente_proprietario_new_id
      and
      now() between b.validita_inizio and COALESCE(b.validita_fine,now());


                 
      INSERT INTO siac.siac_r_evento_reg_movfin
      (regmovfin_id, evento_id,campo_pk_id, validita_inizio, ente_proprietario_id, login_operazione)
      select _regmovfin_id,
      a.evento_id,
      cur_mod_movgest_acc_gsa_sog.mod_id,
      valid_inizio,
      ente_proprietario_new_id,
      login_oper
      from siac_d_evento a
      where 
      a.ente_proprietario_id = ente_proprietario_new_id AND
      a.evento_code = evento_code_reg_movfin
      and  now() between a.validita_inizio and COALESCE(a.validita_fine,now())
      and a.data_cancellazione is null
      ;

	  return next;

end loop;--fine mod accertamento GSA soggetto

        _regmovfin_id:=null;























--return;

exception
     when others  THEN
         RAISE EXCEPTION 'Errore DB % %',SQLSTATE,substring(SQLERRM from 1 for 1000);
         _regmovfin_id:=999;
        --esito:='KO';
        --return esito;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100 ROWS 1000;