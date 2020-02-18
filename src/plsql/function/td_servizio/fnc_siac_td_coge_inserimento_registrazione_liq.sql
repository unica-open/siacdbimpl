/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac.fnc_siac_td_coge_inserimento_registrazione_liq (
  liq_anno_in integer,
  liq_numero_in integer,
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
evento_code_new siac_d_evento.evento_code%type;
collegamento_tipo_code_new siac_d_collegamento_tipo.collegamento_tipo_code%type;
--movgest_id_new siac_t_movgest.movgest_id%type;
liq_emissione_data_new siac_t_liquidazione.liq_emissione_data%type;
liq_id_new siac_t_liquidazione.liq_id%type;
classif_id_new siac_t_class.classif_id%type;
bil_id_new siac_t_bil.bil_id%type;
ambito_id_new siac_d_ambito.ambito_id%type;
regmovfin_stato_code_in_found integer;
BEGIN
v_messaggiorisultato:='Errore';
liq_numero_in=liq_numero_in::numeric;
regmovfin_stato_code_in_found:=0;

select count(*) into regmovfin_stato_code_in_found from 
siac_d_reg_movfin_stato a where a.ente_proprietario_id=ente_proprietario_id_in
and a.data_cancellazione is null
and a.regmovfin_stato_code=regmovfin_stato_code_in;


if regmovfin_stato_code_in_found = 0 then
RAISE EXCEPTION 'stato registrazione non valido';
v_messaggiorisultato:='stato registrazione non valido';
end if;

evento_code_new:='LIQ-INS';


if ambito_in not in ('AMBITO_FIN','AMBITO_GSA') THEN
/*select ambito_id into ambito_id_in from siac_d_ambito a where 
a.ente_proprietario_id=ente_proprietario_id_in
and a.ambito_code=ambito_in;*/
RAISE EXCEPTION 'L''ambito deve essere AMBITO_FIN o AMBITO_GSA';
v_messaggiorisultato:=v_messaggiorisultato||' - L''ambito deve essere AMBITO_FIN o AMBITO_GSA';
end if;

select b.liq_id, d.classif_id, xx.bil_id, b.liq_emissione_data,m.ambito_id
into
liq_id_new, classif_id_new, bil_id_new, liq_emissione_data_new,ambito_id_new
from
siac_t_liquidazione b, siac_r_liquidazione_class c, siac_t_class d,siac_d_class_tipo e,siaC_t_bil xx,
siac_d_ambito m,siac_t_periodo n
where
b.liq_id=c.liq_id
and now() BETWEEN c.validita_inizio and COALESCE(c.validita_fine,now())
and xx.bil_id=b.bil_id
and b.ente_proprietario_id=ente_proprietario_id_in
and c.classif_id=d.classif_id
and e.classif_tipo_id=d.classif_tipo_id
and e.classif_tipo_code like 'PDC%'
and m.ente_proprietario_id=b.ente_proprietario_id
and m.ambito_code=ambito_in
and b.liq_anno=liq_anno_in
and b.liq_numero=liq_numero_in
and n.periodo_id=xx.periodo_id
and n.anno=bil_anno
and b.data_cancellazione is null
and c.data_cancellazione is null
and d.data_cancellazione is null
and e.data_cancellazione is null
and m.data_cancellazione is null
and xx.data_cancellazione is null
/*and not exists (select 1 from siac_v_bko_registrazioni_gen z 
where z.ente_proprietario_id=b.ente_proprietario_id
and z.campo_pk_id=b.liq_id
and z.collegamento_tipo_code='L'
and z.regmovfin_stato_code=regmovfin_stato_code_in
)*/
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
and y.campo_pk_id=liq_id_new
)
returning regmovfin_id into regmovfin_id_new;



if regmovfin_id_new is not null then 

INSERT INTO siac.siac_r_reg_movfin_stato
(regmovfin_id,regmovfin_stato_id,validita_inizio,ente_proprietario_id,login_operazione)
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
select regmovfin_id_new,a.evento_id, liq_id_new,now(),a.ente_proprietario_id,login_operazione_in
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
