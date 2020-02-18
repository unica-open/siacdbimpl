/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/

create or replace function fnc_siac_aggiorna_dati()
returns integer
as
$body$
DECLARE

 pdcfin_rec record;
 cap_rec  record;
BEGIN

for cap_rec in
(select tmp.*
 from tmp_check_macro_pdc_fin tmp
 where pdcfin_padre_b_classif_id is null
 or    pdcfin_figlio_b_classif_id is null
 order by tmp.numero_capitolo, tmp.numero_articolo
 limit 1000
)
loop
    raise notice 'Capitolo % %',cap_rec.numero_capitolo, cap_rec.numero_articolo;
    raise notice 'pdcfin_padre_classif_id = % ',cap_rec.pdcfin_padre_classif_id;
    raise notice 'pdcfin_figlio_classif_id= % ',cap_rec.pdcfin_figlio_classif_id;

	select * into pdcfin_rec
    from fnc_siac_macro_pdc_fin(cap_rec.pdcfin_padre_classif_id,cap_rec.pdcfin_figlio_classif_id,3);
    raise notice 'pdcfin_rec.classif_id_padre=%',pdcfin_rec.classif_id_padre;
    raise notice 'pdcfin_rec.classif_id_figlio=%',pdcfin_rec.classif_id_figlio;
    if pdcfin_rec.classif_id_padre is not null and
       pdcfin_rec.classif_id_figlio is not null
       then
    	update tmp_check_macro_pdc_fin  tmp1
          set pdcfin_padre_b_classif_id=pdcfin_rec.classif_id_padre,
              pdcfin_figlio_b_classif_id=pdcfin_rec.classif_id_figlio
        where tmp1.numero_capitolo=cap_rec.numero_capitolo
        and   tmp1.numero_articolo=cap_rec.numero_articolo;
    end if;


end loop;

return 1;

exception
 	when others  THEN
 		RAISE EXCEPTION 'Errore DB % %',SQLSTATE,substring(SQLERRM from 1 for 1000);
        return 0;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;