/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac.fnc_siac_bko_configura_report_ente (
  ente_prop_in integer
)
RETURNS void AS
$body$
DECLARE

ciclo integer;
rec record;
rec2 record;
rec3 record;
competenza_anni integer;
login_operazione_loc varchar;
login_operazione_data varchar;
repimp_id_esistente integer;
repimp_id_esistente_n integer;
currtiins integer;
stringone text;

begin
login_operazione_data:=to_char(now(),'dd/mm/yyyy_hh24:mi:ss');
login_operazione_loc:= 'fnc_siac_bko_configura_report';
login_operazione_loc:= login_operazione_loc||' '||login_operazione_data;


delete from siac_r_report_importi where ente_proprietario_id=ente_prop_in;
delete from siac_s_report_importi where ente_proprietario_id=ente_prop_in;
delete from siac_t_report_importi where ente_proprietario_id=ente_prop_in;



for rec in 
select * from siac_t_report 
where ente_proprietario_id=ente_prop_in and 
data_cancellazione is null 
order by rep_codice
--and rep_codice in ('BILR001','BILR064')
loop

  --raise notice 'loop % - %', rec.rep_codice, rec.ente_proprietario_id;

  --trovo competenza anni
  select 
  rep_competenza_anni  into competenza_anni
  from bko_t_report_competenze where rep_codice=rec.rep_codice
  ;

if competenza_anni is null then
competenza_anni:=0;
end if;

  --raise notice 'competenza %', competenza_anni;

  for i in 0 .. competenza_anni-1 loop
  
  
 

   --raise notice 'ciclo %', i;
   --raise notice 'i:%', i;

    for rec2 in 
    select distinct  
    bi.repimp_codice,
    bi.repimp_desc,
    bi.repimp_importo,
    bi.repimp_modificabile,
    bi.repimp_progr_riga, 
    bil.bil_id,
    per2.periodo_id,
    re.validita_inizio,
    re.validita_fine,
    re.ente_proprietario_id,
    login_operazione_loc
    from 
    bko_t_report_importi bi, 
    siac_t_report re,
    siac_t_bil bil , 
    siac_t_periodo per, 
    siac_d_periodo_tipo pt,
    siac_t_periodo per2, 
    siac_d_periodo_tipo pt2
    where 
    bi.rep_codice=re.rep_codice 
    and re.ente_proprietario_id=rec.ente_proprietario_id
    and re.ente_proprietario_id=bil.ente_proprietario_id
    and re.ente_proprietario_id=per.ente_proprietario_id
    and bil.periodo_id=per.periodo_id
    and bil.data_cancellazione is null
    and per.periodo_tipo_id=pt.periodo_tipo_id
    and pt.periodo_tipo_code='SY'
    and pt2.periodo_tipo_code='SY'
    and per2.ente_proprietario_id=per.ente_proprietario_id
    and pt2.periodo_tipo_id=per2.periodo_tipo_id
    and per2.anno::integer=per.anno::integer + i::integer
    and re.rep_codice=rec.rep_codice
    and not EXISTS
    (
    select 1 from siac_t_report_importi d where d.repimp_codice=bi.repimp_codice
    and d.repimp_modificabile=bi.repimp_modificabile and COALESCE(d.repimp_progr_riga,0)=COALESCE(bi.repimp_progr_riga,0)
    and d.ente_proprietario_id=rec.ente_proprietario_id
    and d.periodo_id=per2.periodo_id
    and d.bil_id=bil.bil_id
    )
    order by 
    bil.bil_id,
    per2.periodo_id,
    bi.repimp_progr_riga,
    bi.repimp_codice
    loop


    if rec.rep_codice='BILR048' and rec2.repimp_codice='ava_amm' 
      then
	  raise notice '2.2 rec2.repimp_codice %', rec2.repimp_codice;
      raise notice '2.3 rec2.repimp_desc %', rec2.repimp_desc;
      raise notice '2.4 rec2.repimp_progr_riga %', rec2.repimp_progr_riga;
      raise notice '2.5 rec2.bil_id %',rec2.bil_id;
      raise notice '2.6 rec2.periodo_id %',rec2.periodo_id;
       end if;


    INSERT INTO 
    siac.siac_t_report_importi
    (
    repimp_codice,
    repimp_desc,
    repimp_importo,
    repimp_modificabile,
    repimp_progr_riga,
    bil_id,
    periodo_id,
    validita_inizio,
    validita_fine,
    ente_proprietario_id,
    login_operazione
    ) 
    VALUES
    (rec2.repimp_codice,
    rec2.repimp_desc,
    rec2.repimp_importo,
    rec2.repimp_modificabile,
    rec2.repimp_progr_riga, 
    rec2.bil_id,
    rec2.periodo_id,
    rec2.validita_inizio,
    rec2.validita_fine,
    rec2.ente_proprietario_id,
    login_operazione_loc);
              
              
    SELECT      currval('siac_t_report_importi_repimp_id_seq') into currtiins;
                     
    INSERT INTO 
    siac.siac_r_report_importi
    (
    rep_id,
    repimp_id,
    posizione_stampa,
    validita_inizio,
    validita_fine,
    ente_proprietario_id,
    login_operazione
    )
    VALUES(
    rec.rep_id,
    currtiins,
    1,rec2.validita_inizio,
    rec2.validita_fine,
    rec2.ente_proprietario_id,
    login_operazione_loc
    )
    ;
              
    end loop;
    
    
    for rec3 in 
    select distinct 
    re.rep_id, 
    bi.repimp_codice,
    bi.repimp_desc,
    bi.repimp_importo,
    bi.repimp_modificabile,
    bi.repimp_progr_riga, 
    bil.bil_id,
    per2.periodo_id,
    re.validita_inizio,
    re.validita_fine,
    re.ente_proprietario_id,
    login_operazione_loc
    from 
    bko_t_report_importi bi, 
    siac_t_report re,
    siac_t_bil bil , 
    siac_t_periodo per, 
    siac_d_periodo_tipo pt,
    siac_t_periodo per2, 
    siac_d_periodo_tipo pt2
    where 
    bi.rep_codice=re.rep_codice 
    and re.ente_proprietario_id=rec.ente_proprietario_id
    and re.ente_proprietario_id=bil.ente_proprietario_id
    and re.ente_proprietario_id=per.ente_proprietario_id
    and bil.periodo_id=per.periodo_id
    and bil.data_cancellazione is null
    and per.periodo_tipo_id=pt.periodo_tipo_id
    and pt.periodo_tipo_code='SY'
    and pt2.periodo_tipo_code='SY'
    and per2.ente_proprietario_id=per.ente_proprietario_id
    and pt2.periodo_tipo_id=per2.periodo_tipo_id
    and per2.anno::integer=per.anno::integer + i::integer
    and re.rep_codice=rec.rep_codice
    and EXISTS
    (
    select 1 from siac_t_report_importi d where d.repimp_codice=bi.repimp_codice
    and d.repimp_modificabile=bi.repimp_modificabile and COALESCE(d.repimp_progr_riga,0)=COALESCE(bi.repimp_progr_riga,0)
    and d.ente_proprietario_id=rec.ente_proprietario_id
    and d.periodo_id=per2.periodo_id
    and d.bil_id=bil.bil_id
    )
    order by 
    bil.bil_id,
    per2.periodo_id,
    bi.repimp_progr_riga,
    bi.repimp_codice
    loop
    
      INSERT INTO 
      siac.siac_r_report_importi
      (
      rep_id,
      repimp_id,
      posizione_stampa,
      validita_inizio,
      validita_fine,
      ente_proprietario_id,
      login_operazione
      ) 
      select c.rep_id,g.repimp_id,1,g.validita_inizio,g.validita_fine,g.ente_proprietario_id,login_operazione_loc
      from 
      siac_t_report c, 
      bko_t_report_importi a, siac_t_report_importi g
      where 
      c.rep_codice=a.rep_codice
      and a.repimp_codice=g.repimp_codice
      and a.repimp_modificabile=g.repimp_modificabile
      and COALESCE(g.repimp_progr_riga,0)=COALESCE(a.repimp_progr_riga,0)
      and g.ente_proprietario_id=c.ente_proprietario_id 
      and c.ente_proprietario_id=ente_prop_in
      and g.bil_id=rec3.bil_id
      and g.periodo_id=rec3.periodo_id
      and c.rep_id=REC.rep_id
      and not exists 
      (select 1 from siac_r_report_importi r where r.rep_id=c.rep_id and g.repimp_id=r.repimp_id);
    
    
    
    
    end loop;
  end loop;

end loop;



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
COST 100;