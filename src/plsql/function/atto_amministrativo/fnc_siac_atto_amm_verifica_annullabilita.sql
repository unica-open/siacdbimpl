/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
﻿CREATE OR REPLACE FUNCTION siac.fnc_siac_atto_amm_verifica_annullabilita (
  attoamm_id_in integer
)
RETURNS boolean AS
$body$
DECLARE

annullabile boolean;
rec0 record;
rec1 record;
rec2 record;
rec3 record;
rec4 record;
rec5 record;
rec6 record;
rec7 record;
rec8 record;
rec9 record;
rec10 record;
rec11 record;
rec12 record;
rec13 record;
rec14 record;

test_data timestamp;

/*table_fk
siac_r_predoc_atto_amm
siac_r_ordinativo_atto_amm
siac_r_programma_atto_amm
siac_r_liquidazione_atto_amm
siac_r_bil_stato_op_atto_amm
siac_t_cartacont
siac_r_atto_amm_class
siac_r_movgest_ts_atto_amm
siac_r_subdoc_atto_amm
siac_r_causale_atto_amm
siac_t_modifica
siac_r_variazione_stato
siac_t_atto_allegato
siac_r_atto_amm_stato
siac_t_cassa_econ_operaz
siac_r_mutuo_atto_amm*/




begin
test_data:=now();
annullabile:= true;

for rec0 in
select * from siac_r_atto_amm_stato s, siac_d_atto_amm_stato da
where
da.attoamm_stato_id=s.attoamm_id and s.attoamm_id=attoamm_id_in
and now() between s.validita_inizio and coalesce(s.validita_fine, now())
and da.attoamm_stato_code='ANNULLATO'
and da.data_cancellazione is null
and s.data_cancellazione is null
 limit 1
loop
annullabile:= false;
end loop;


for rec1 in
select * from siac_r_bil_stato_op_atto_amm
where attoamm_id=attoamm_id_in
 and data_cancellazione is null limit 1
loop
annullabile:= false;
end loop;

if annullabile = true THEN

  for rec2 in
  select * from siac_r_causale_atto_amm ra where ra.attoamm_id=attoamm_id_in
   and test_data between ra.validita_inizio and coalesce(ra.validita_fine,test_data)
   and ra.data_cancellazione is null limit 1
  loop
  annullabile:= false;
  end loop;

end if;

if annullabile = true THEN

  for rec3 in
  select * from siac_r_liquidazione_atto_amm  ra, siac_t_liquidazione l, siac_r_liquidazione_stato ls, siac_d_liquidazione_stato lt
  where
  ra.liq_id=l.liq_id
  and ls.liq_id=l.liq_id
  and lt.liq_stato_id=ls.liq_stato_id
  and lt.liq_stato_code<>'A'
  and test_data between ls.validita_inizio and coalesce(ls.validita_fine,test_data)
   and test_data between ra.validita_inizio and coalesce(ra.validita_fine,test_data)
  and ra.attoamm_id=attoamm_id_in
   and ra.data_cancellazione is null limit 1
  loop
  annullabile:= false;
  end loop;

end if;


if annullabile = true THEN

  for rec4 in
  select * from siac_r_movgest_ts_atto_amm ra ,siac_t_movgest_ts ts, siac_r_movgest_ts_stato tss, siac_d_movgest_stato sta
  where
  ts.movgest_ts_id=ra.movgest_ts_id
  and ts.movgest_ts_id=tss.movgest_ts_id
  and tss.movgest_stato_id=sta.movgest_stato_id
  and sta.movgest_stato_code<>'A'
  and test_data between tss.validita_inizio and coalesce(tss.validita_fine,test_data)
   and test_data between ra.validita_inizio and coalesce(ra.validita_fine,test_data)
  and ra.attoamm_id=attoamm_id_in
   and ra.data_cancellazione is null limit 1
  loop
  annullabile:= false;
  end loop;

end if;

if annullabile = true THEN

  for rec5 in
  select * from siac_r_mutuo_atto_amm ra, siac_t_mutuo m, siac_r_mutuo_stato ms, siac_d_mutuo_stato sta
  where
  m.mut_id=ra.mut_id
  and m.mut_id=ms.mut_id
  and ms.mut_stato_id=sta.mut_stato_id
  and sta.mut_stato_code<>'A'
  and test_data between ms.validita_inizio and coalesce(ms.validita_fine,test_data)
 and test_data between ra.validita_inizio and coalesce(ra.validita_fine,test_data)
  and ra.attoamm_id=attoamm_id_in
   and ra.data_cancellazione is null limit 1
  loop
  annullabile:= false;
  end loop;

end if;


if annullabile = true THEN

  for rec6 in
  select * from siac_r_ordinativo_atto_amm ra, siac_t_ordinativo o, siac_r_ordinativo_stato os, siac_d_ordinativo_stato sta
  where
  o.ord_id=ra.ord_id
  and os.ord_id=o.ord_id
  and os.ord_stato_id=sta.ord_stato_id
  and sta.ord_stato_code<>'A'
  and  test_data between sta.validita_inizio and coalesce(sta.validita_fine,test_data)
  and ra.attoamm_id=attoamm_id_in
   and test_data between ra.validita_inizio and coalesce(ra.validita_fine,test_data)
   and ra.data_cancellazione is null limit 1
  loop
  annullabile:= false;
  end loop;

end if;

if annullabile = true THEN

  for rec7 in
  select * from siac_r_predoc_atto_amm ra, siac_t_predoc p, siac_r_predoc_stato ps, siac_d_predoc_stato sta
  where
  p.predoc_id=ra.predoc_id
  and ps.predoc_id=p.predoc_id
  and ps.predoc_stato_id=sta.predoc_stato_id
  and sta.predoc_stato_code<>'A'
  and  test_data between sta.validita_inizio and coalesce(sta.validita_fine,test_data)
  and ra.attoamm_id=attoamm_id_in
   and test_data between ra.validita_inizio and coalesce(ra.validita_fine,test_data)
   and ra.data_cancellazione is null limit 1
  loop
  annullabile:= false;
  end loop;

end if;


if annullabile = true THEN

  for rec8 in
  select * from siac_r_programma_atto_amm ra, siac_t_programma p, siac_r_programma_stato ps, siac_d_programma_stato sta
  where
  p.programma_id=ra.programma_id
  and p.programma_id=ps.programma_stato_id
  and ps.programma_stato_id=sta.programma_stato_id
  and sta.programma_stato_code<>'AN'
   and test_data between sta.validita_inizio and coalesce(sta.validita_fine,test_data)
  and ra.attoamm_id=attoamm_id_in
   and test_data between ra.validita_inizio and coalesce(ra.validita_fine,test_data)
   and ra.data_cancellazione is null limit 1
  loop
  annullabile:= false;
  end loop;

end if;


if annullabile = true THEN

  for rec9 in
  select * from siac_r_subdoc_atto_amm ra, siac_t_subdoc sd, siac_t_doc d, siac_r_doc_stato sst, siac_d_doc_stato sta
  where
  sd.subdoc_id=ra.subdoc_id
  and d.doc_id=sd.doc_id
  and sst.doc_id=d.doc_id
  and sst.doc_stato_id=sta.doc_stato_id
  and sta.doc_stato_code<>'A'
  and test_data between sst.validita_inizio and coalesce(sst.validita_fine,test_data)
  and ra.attoamm_id=attoamm_id_in
  and test_data between ra.validita_inizio and coalesce(ra.validita_fine,test_data)
  and ra.data_cancellazione is null limit 1
  loop
  annullabile:= false;
  end loop;

end if;

if annullabile = true THEN

  for rec10 in
  select * from siac_r_variazione_stato ra, siac_d_variazione_stato sta
  where
  sta.variazione_stato_tipo_id=ra.variazione_stato_tipo_id
  and sta.variazione_stato_tipo_code<>'A'
  and test_data between sta.validita_inizio and coalesce(sta.validita_fine,test_data)
  and ra.attoamm_id=attoamm_id_in
   and ra.data_cancellazione is null limit 1
  loop
  annullabile:= false;
  end loop;

end if;

if annullabile = true THEN

  for rec11 in
  select * from siac_t_atto_allegato ra, siac_r_atto_allegato_stato st, siac_d_atto_allegato_stato sta
  where
  st.attoal_id=ra.attoal_id and
  st.attoal_stato_id=sta.attoal_stato_id
  and sta.attoal_stato_code<>'A'
  and test_data between sta.validita_inizio and coalesce(sta.validita_fine,test_data)
  and ra.attoamm_id=attoamm_id_in
  and test_data between ra.validita_inizio and coalesce(ra.validita_fine,test_data)
   and ra.data_cancellazione is null limit 1
  loop
  annullabile:= false;
  end loop;

end if;

if annullabile = true THEN

  for rec12 in
  select * from siac_t_cartacont ra ,siac_r_cartacont_stato st, siac_d_cartacont_stato sta
  where
  st.cartac_id=ra.cartac_id
  and st.cartac_stato_id=sta.cartac_stato_id
  and sta.cartac_stato_code<>'A'
  and ra.attoamm_id=attoamm_id_in
  and test_data between sta.validita_inizio and coalesce(sta.validita_fine,test_data)
  and test_data between ra.validita_inizio and coalesce(ra.validita_fine,test_data)
   and ra.data_cancellazione is null limit 1
  loop
  annullabile:= false;
  end loop;

end if;

if annullabile = true THEN

  for rec13 in
  select * from siac_t_cassa_econ_operaz ra, siac_r_cassa_econ_operaz_stato st, siac_d_cassa_econ_operaz_stato sta
  where
  st.cassaeconop_id=ra.cassaeconop_id
  and st.cassaeconop_stato_id=sta.cassaeconop_stato_id
  and sta.cassaeconop_stato_code<>'A'
  and test_data between sta.validita_inizio and coalesce(sta.validita_fine,test_data)
  and test_data between ra.validita_inizio and coalesce(ra.validita_fine,test_data)
  and ra.attoamm_id=attoamm_id_in
  and ra.data_cancellazione is null limit 1
  loop
  annullabile:= false;
  end loop;

end if;

if annullabile = true THEN

  for rec14 in
  select * from siac_t_modifica  ra, siac_r_modifica_stato st, siac_d_modifica_stato sta
  where
  st.mod_id=ra.mod_id
  and st.mod_stato_id=sta.mod_stato_id
  and sta.mod_stato_code<>'A'
  and test_data between sta.validita_inizio and coalesce(sta.validita_fine,test_data)
  and test_data between ra.validita_inizio and coalesce(ra.validita_fine,test_data)
  and  ra.attoamm_id=attoamm_id_in
   and ra.data_cancellazione is null limit 1
  loop
  annullabile:= false;
  end loop;

end if;

return annullabile;

exception
 	when others  THEN
 		RAISE EXCEPTION 'Errore DB % %',SQLSTATE,substring(SQLERRM from 1 for 1000);
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;