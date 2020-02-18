/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/

CREATE OR REPLACE FUNCTION fnc_migr_check_relaz_soggetti ( ente_in integer)
RETURNS TABLE (
  migrRelazId  integer,
  soggettoIdDaMigr integer,
  sedeDa         varchar,
  soggettoIdAMigr integer,
  sedeA          varchar,
  soggettoIdDa integer,
  soggettoIdA  integer,
  modPagIdA    integer
) AS
$body$
DECLARE

migrSoggRec record;
BEGIN

 migrRelazId:=null;
 soggettoIdDaMigr:=null;
 soggettoIdDa:=null;
 soggettoIdAMigr:=null;
 soggettoIdA:=null;
 modPagIdA:=null;
 sedeDa:=null;
 sedeA :=null;

 for migrSoggRec IN
 (
  select relaz.migr_relaz_id,relaz.soggetto_id_da, relaz.modpag_id_da, relaz.soggetto_id_a,relaz.modpag_id_a,
         m.sede_id sede_id_da, m1.sede_id sede_id_a
  from migr_modpag m, migr_relaz_soggetto relaz,migr_modpag m1
  where relaz.ente_proprietario_id=ente_in
  and   relaz.tipo_relazione='CSI'
  and   m.modpag_id=relaz.modpag_id_da
  and   m.ente_proprietario_id=ente_in
  and   m1.modpag_id=relaz.modpag_id_a
  and   m1.ente_proprietario_id=ente_in
  order by 1,2,4
 )
 loop


   -- nessuna sede
   if migrSoggRec.sede_id_da is null then
   		select rel.soggetto_id into strict soggettoIdDa
        from siac_r_migr_soggetto_soggetto rel, migr_soggetto m
        where m.soggetto_id=migrSoggRec.soggetto_id_da
        and   m.ente_proprietario_id=ente_in
        and   rel.migr_soggetto_id=m.migr_soggetto_id
        and   rel.ente_proprietario_id=ente_in;
   else
        select rr.soggetto_id_da into strict soggettoIdDa
        from  siac_r_migr_sede_secondaria_rel_sede rel, migr_sede_secondaria m,siac_r_soggetto_relaz rr
        where m.sede_id=migrSoggRec.sede_id_da
        and   m.ente_proprietario_id=ente_in
        and   rel.migr_sede_id=m.migr_sede_id
        and   rel.ente_proprietario_id=m.ente_proprietario_id
        and   rr.soggetto_relaz_id=rel.soggetto_relaz_id
        and   rr.ente_proprietario_id=ente_in;
   end if;

   if migrSoggRec.sede_id_a is null then
   		select rel.soggetto_id into strict soggettoIdA
        from siac_r_migr_soggetto_soggetto rel, migr_soggetto m
        where m.soggetto_id=migrSoggRec.soggetto_id_a
        and   m.ente_proprietario_id=ente_in
        and   rel.migr_soggetto_id=m.migr_soggetto_id
        and   rel.ente_proprietario_id=ente_in;
   else
        select rr.soggetto_id_a into strict soggettoIdA
        from  siac_r_migr_sede_secondaria_rel_sede rel, migr_sede_secondaria m, siac_r_soggetto_relaz rr
        where m.sede_id=migrSoggRec.sede_id_a
        and   m.ente_proprietario_id=ente_in
        and   rel.migr_sede_id=m.migr_sede_id
        and   rel.ente_proprietario_id=m.ente_proprietario_id
        and   rr.soggetto_relaz_id=rel.soggetto_relaz_id
        and   rr.ente_proprietario_id=ente_in;
   end if;


   select mdp.modpag_id into strict  modPagIdA
   from siac_t_modpag mdp, siac_r_migr_modpag_modpag r, migr_modpag m
   where m.modpag_id=migrSoggRec.modpag_id_a
   and   m.ente_proprietario_id=ente_in
   and   r.migr_modpag_id=m.migr_modpag_id
   and   r.ente_proprietario_id=ente_in
   and   mdp.modpag_id=r.modpag_id
   and   mdp.ente_proprietario_id=ente_in;


   migrRelazId:=migrSoggRec.migr_relaz_id;
   soggettoIdDaMigr:=migrSoggRec.soggetto_id_da;
   soggettoIdAMigr:=migrSoggRec.soggetto_id_a;
   if migrSoggRec.sede_id_da is not null then
   	sedeDa:='S';
   end if;
   if migrSoggRec.sede_id_a is not null then
   	sedeA:='S';
   end if;

   return next;
 end loop;




exception
    when RAISE_EXCEPTION THEN
        RAISE EXCEPTION '%',substring(SQLERRM from 1 for 1500);
        return;
	when no_data_found then
		RAISE EXCEPTION 'Non presente in archivio.';
        return;
	when others  THEN
 		RAISE EXCEPTION 'Errore DB % %',SQLSTATE,substring(SQLERRM from 1 for 1000);
        return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100 ROWS 1000;