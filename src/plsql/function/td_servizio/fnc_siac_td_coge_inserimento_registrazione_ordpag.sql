/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac.fnc_siac_td_coge_inserimento_registrazione_ordpag (
  ord_anno_in integer,
  ord_numero_in integer,
  ord_tipo_code_in varchar,
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
ord_emissione_data_new siac_t_ordinativo.ord_emissione_data%type;
ord_id_new siac_t_ordinativo.ord_id%type;
classif_id_new siac_t_class.classif_id%type;
bil_id_new siac_t_bil.bil_id%type;
ambito_id_new siac_d_ambito.ambito_id%type;
regmovfin_stato_code_in_found integer;
BEGIN
v_messaggiorisultato:='Errore';
ord_numero_in=ord_numero_in::numeric;
regmovfin_stato_code_in_found:=0;

select count(*) into regmovfin_stato_code_in_found from 
siac_d_reg_movfin_stato a where a.ente_proprietario_id=ente_proprietario_id_in
and a.data_cancellazione is null
and a.regmovfin_stato_code=regmovfin_stato_code_in;


if regmovfin_stato_code_in_found = 0 then
RAISE EXCEPTION 'stato registrazione non valido';
v_messaggiorisultato:='stato registrazione non valido';
end if;


if ord_tipo_code_in ='P' then 
 evento_code_new:='OPA-INS';
 collegamento_tipo_code_new='OP';
elsif ord_tipo_code_in ='I' then 
evento_code_new:='OIN-INS';
collegamento_tipo_code_new:='OI';
else
-- gestire con iva 
-- OII-INS incasso con iva inserisci 
-- OPI-INS pagamento con iva inserisci

--errore
RAISE EXCEPTION 'tipo ordinativo deve essere P o I';
v_messaggiorisultato:='tipo ordinativo deve essere P o I';
end if;

if ambito_in not in ('AMBITO_FIN','AMBITO_GSA') THEN
/*select ambito_id into ambito_id_in from siac_d_ambito a where 
a.ente_proprietario_id=ente_proprietario_id_in
and a.ambito_code=ambito_in;*/
RAISE EXCEPTION 'L''ambito deve essere AMBITO_FIN o AMBITO_GSA';
v_messaggiorisultato:=v_messaggiorisultato||' - L''ambito deve essere AMBITO_FIN o AMBITO_GSA';
end if;


select b.ord_id, i.classif_id, xx.bil_id, b.ord_emissione_data ,m.ambito_id
into
ord_id_new,classif_id_new, bil_id_new,ord_emissione_data_new,ambito_id_new
from
siac_t_ordinativo b, siac_r_ordinativo_stato c,
siac_d_ordinativo_stato d,
siac_d_ordinativo_tipo g,
siac_t_bil xx, siac_t_periodo yy, siac_r_ordinativo_class h,siac_t_class i,siac_d_class_tipo l
,siac_d_ambito m
where
b.ord_id=c.ord_id
and now() BETWEEN c.validita_inizio and COALESCE(c.validita_fine,now())
and d.ord_stato_id=c.ord_stato_id
and d.ord_stato_code<>'A'
and g.ord_tipo_id=b.ord_tipo_id
and g.ord_tipo_code=ord_tipo_code_in
and xx.bil_id=b.bil_id
and yy.periodo_id=xx.periodo_id
and b.ente_proprietario_id=ente_proprietario_id_in
and yy.anno=bil_anno
and b.ord_numero=ord_numero_in
and b.ord_anno=ord_anno_in
and h.ord_id=b.ord_id
and i.classif_id=h.classif_id
and l.classif_tipo_id=i.classif_tipo_id
and l.classif_tipo_code like 'PDC%'
and m.ente_proprietario_id=b.ente_proprietario_id
and m.ambito_code=ambito_in
and b.data_cancellazione is null
and c.data_cancellazione is null
and d.data_cancellazione is null
and g.data_cancellazione is null
and h.data_cancellazione is null
and i.data_cancellazione is null
and l.data_cancellazione is null
and m.data_cancellazione is null
and xx.data_cancellazione is null
and yy.data_cancellazione is null/*
and not exists (select 1 from siac_v_bko_registrazioni_gen z 
where z.ente_proprietario_id=b.ente_proprietario_id
and z.campo_pk_id=b.ord_id
and z.collegamento_tipo_code=collegamento_tipo_code_new
and z.regmovfin_stato_code=regmovfin_stato_code_in  -- stato da inserire
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
and y.campo_pk_id=ord_id_new
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
select regmovfin_id_new,a.evento_id, ord_id_new,now(),a.ente_proprietario_id,login_operazione_in
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
