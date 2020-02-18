/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac.fnc_siac_td_coge_inserimento_registrazione_movgest (
  movgest_anno_in integer,
  movgest_numero_in integer,
  movgest_tipo_code_in varchar,
  validita_inizio_in timestamp,
  ente_proprietario_id_in integer,
  login_operazione_in varchar,
  bil_anno varchar,
  ambito_in varchar,
  regmovfin_stato_code_in varchar
)
RETURNS TABLE (
  v_messaggiorisultato text
) AS
$body$
DECLARE
regmovfin_id_new siac_t_reg_movfin.regmovfin_id%type;
evento_code_new varchar;
movgest_id_new siac_t_movgest.movgest_id%type;
classif_id_new siac_t_class.classif_id%type;
bil_id_new siac_t_bil.bil_id%type;
ambito_id_new siac_d_ambito.ambito_id%type;
regmovfin_stato_code_in_found integer;
BEGIN
v_messaggiorisultato:='Errore';
movgest_numero_in=movgest_numero_in::numeric;
regmovfin_stato_code_in_found:=0;

select count(*) into regmovfin_stato_code_in_found from 
siac_d_reg_movfin_stato a where a.ente_proprietario_id=ente_proprietario_id_in
and a.data_cancellazione is null
and a.regmovfin_stato_code=regmovfin_stato_code_in;


if regmovfin_stato_code_in_found = 0 then
RAISE EXCEPTION 'stato registrazione non valido';
v_messaggiorisultato:='stato registrazione non valido';
end if;

if movgest_tipo_code_in ='A' then 
 evento_code_new:='ACC-INS';
elsif movgest_tipo_code_in ='I' then 
evento_code_new:='IMP-INS';
else
--errore
RAISE EXCEPTION 'tipo movimento di gestione deve essere A o I';
v_messaggiorisultato:='tipo movimento di gestione deve essere A o I';
end if;

if ambito_in not in ('AMBITO_FIN','AMBITO_GSA') THEN
/*select ambito_id into ambito_id_in from siac_d_ambito a where 
a.ente_proprietario_id=ente_proprietario_id_in
and a.ambito_code=ambito_in;*/
RAISE EXCEPTION 'L''ambito deve essere AMBITO_FIN o AMBITO_GSA';
v_messaggiorisultato:=v_messaggiorisultato||' - L''ambito deve essere AMBITO_FIN o AMBITO_GSA';
end if;



select  
a.movgest_id,e.classif_id,a.bil_id,g.ambito_id into
movgest_id_new,classif_id_new, bil_id_new,ambito_id_new
from 
siac_t_movgest a,
siac_d_movgest_tipo b, 
siac_t_movgest_ts c,
siac_r_movgest_class d,
siac_t_class e, 
siac_d_class_tipo f,
siac_d_ambito g,
siaC_t_bil h,
siac_t_periodo i
where a.ente_proprietario_id=ente_proprietario_id_in
and a.movgest_anno=movgest_anno_in and a.movgest_numero=movgest_numero_in
and b.movgest_tipo_id=a.movgest_tipo_id
and b.movgest_tipo_code=movgest_tipo_code_in
and c.movgest_id=a.movgest_id
and d.movgest_ts_id=c.movgest_ts_id
and e.classif_id=d.classif_id
and f.classif_tipo_id=e.classif_tipo_id
and f.classif_tipo_code like 'PDC%'
and now() BETWEEN d.validita_inizio and coalesce(d.validita_fine,now())
and g.ente_proprietario_id=a.ente_proprietario_id
and g.ambito_code=ambito_in
and h.bil_id=a.bil_id
and i.periodo_id=h.periodo_id
and i.anno=bil_anno
and a.data_cancellazione is NULL
and b.data_cancellazione is NULL
and c.data_cancellazione is NULL
and d.data_cancellazione is NULL
and e.data_cancellazione is NULL
and f.data_cancellazione is NULL
and g.data_cancellazione is NULL
and h.data_cancellazione is NULL
and i.data_cancellazione is NULL
;


INSERT INTO siac.siac_t_reg_movfin
(
classif_id_iniziale,
classif_id_aggiornato,
bil_id,
validita_inizio,
ente_proprietario_id,
login_operazione,
ambito_id)  
select 
classif_id_new,
classif_id_new,
bil_id_new,
now(),
ente_proprietario_id_in,
login_operazione_in, 
ambito_id_new
--VALUES (classif_id_new,bil_id_new,now(),ente_proprietario_id_in,login_operazione_in, ambito_id_new)
from siac_t_ente_proprietario a where a.ente_proprietario_id=ente_proprietario_id_in
and not exists (select 1 from siac_t_reg_movfin z,siac_r_evento_reg_movfin y 
where z.classif_id_iniziale=classif_id_new
and z.bil_id=bil_id_new
and z.ente_proprietario_id=ente_proprietario_id_in
and z.ambito_id=ambito_id_new
and z.data_cancellazione is null
and y.regmovfin_id=z.regmovfin_id
and y.campo_pk_id=movgest_id_new
)
returning regmovfin_id into regmovfin_id_new;



if regmovfin_id_new is not null then 

INSERT INTO 
siac.siac_r_reg_movfin_stato
(regmovfin_id,regmovfin_stato_id,validita_inizio,ente_proprietario_id,login_operazione
)
select b.regmovfin_id,a.regmovfin_stato_id, now(),a.ente_proprietario_id,login_operazione_in
from siac_d_reg_movfin_stato a,siac_t_reg_movfin b where a.ente_proprietario_id=ente_proprietario_id_in
and a.regmovfin_stato_code=regmovfin_stato_code_in
and b.ente_proprietario_id=a.ente_proprietario_id
and b.regmovfin_id=regmovfin_id_new
and a.data_cancellazione is NULL
and b.data_cancellazione is NULL
;

 INSERT INTO 
  siac.siac_r_evento_reg_movfin
(regmovfin_id,evento_id,campo_pk_id,validita_inizio,ente_proprietario_id,login_operazione)   
select regmovfin_id_new,a.evento_id, movgest_id_new,now(),a.ente_proprietario_id,login_operazione_in
from siac_d_evento a--, siac_t_reg_movfin b 
where 
a.ente_proprietario_id=ente_proprietario_id_in
and a.evento_code=evento_code_new
--and b.ente_proprietario_id=a.ente_proprietario_id
and a.data_cancellazione is NULL
--and b.data_cancellazione is NULL
;

v_messaggiorisultato:='Inserita registrazione con siac_t_regmovfin.regmovfin_id='||regmovfin_id_new::varchar;

else
v_messaggiorisultato:='Nessun dato inserito, dato già presente';

end if;

return next;


exception
    when RAISE_EXCEPTION THEN
    v_messaggiorisultato:=v_messaggiorisultato|| ' - ' ||substring(upper(SQLERRM) from 1 for 2500);
          return next;
	when others  THEN
	v_messaggiorisultato:=v_messaggiorisultato|| ' others - ' ||substring(upper(SQLERRM) from 1 for 2500);
        return next;
    

END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY DEFINER
COST 100 ROWS 1000;