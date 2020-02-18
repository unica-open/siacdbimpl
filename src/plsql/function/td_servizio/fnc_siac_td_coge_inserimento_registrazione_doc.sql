/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac.fnc_siac_td_coge_inserimento_registrazione_doc (
  doc_anno_in integer,
  doc_numero_in varchar,
  subdoc_numero_in integer,
  movgest_anno_in integer,
  movgest_numero_in integer,
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
subdoc_id_new siac_t_subdoc.subdoc_id%type;
classif_id_new siac_t_class.classif_id%type;
bil_id_new siac_t_bil.bil_id%type;
ambito_id_new siac_d_ambito.ambito_id%type;
regmovfin_stato_code_in_found integer;
BEGIN
v_messaggiorisultato:='Errore';
movgest_numero_in:=movgest_numero_in::numeric;
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

select 
b.subdoc_id, d.classif_id, xx.bil_id, m.ambito_id
into
subdoc_id_new, classif_id_new, bil_id_new, ambito_id_new
from 
siac_t_subdoc b,siac_t_doc c,
siac_r_subdoc_movgest_ts d,siac_t_movgest_ts e,siac_t_movgest f, siac_r_movgest_class g,
siac_t_class h,siac_d_class_tipo i,siac_t_bil l,siac_d_ambito m,siac_t_periodo n
where
l.ente_proprietario_id=ente_proprietario_id_in
and n.periodo_id=l.periodo_id
and n.anno=bil_anno
and m.ente_proprietario_id=l.ente_proprietario_id
and m.ambito_code=ambito_in
and  c.doc_id=b.doc_id
and c.doc_anno=doc_anno_in
and c.doc_numero=doc_numero_in
and b.subdoc_numero=subdoc_numero_in
and b.ente_proprietario_id=ente_proprietario_id_in
and d.subdoc_id=b.subdoc_id
and e.movgest_ts_id=d.movgest_ts_id
and f.movgest_id=e.movgest_id
and f.movgest_anno= movgest_anno_in and f.movgest_numero=movgest_numero_in
and g.movgest_ts_id=e.movgest_ts_id
and h.classif_id=g.classif_id
and i.classif_tipo_id=h.classif_tipo_id
and i.classif_tipo_code like '%PDC%'
and b.data_cancellazione is null
and c.data_cancellazione is null
and d.data_cancellazione is null
and e.data_cancellazione is null
and f.data_cancellazione is null
and g.data_cancellazione is null
and h.data_cancellazione is null;


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
and y.campo_pk_id=subdoc_id_new
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
select regmovfin_id_new,a.evento_id, subdoc_id_new,now(),a.ente_proprietario_id,login_operazione_in
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
