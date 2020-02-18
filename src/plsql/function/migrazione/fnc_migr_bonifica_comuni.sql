/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION fnc_migr_bonifica_comuni(enteproprietarioid integer
												,out codresult integer
												,out messaggioRisultato varchar)
RETURNS record AS
$body$
DECLARE
 strMessaggio VARCHAR(1500):='';
 strMessaggioFinale VARCHAR(1500):='';
 comune record;
BEGIN
	strMessaggioFinale := 'Bonifica codici comune doppi per codice Belfiore.';
	for comune in
		(select
			c1.comune_id as id_DaMantenere
--			, c1.comune_belfiore_catastale_code
--			, c1.login_operazione
			, c2.comune_id id_DaCancellare
--			, c2.comune_belfiore_catastale_code
--			, c2.login_operazione
			from siac_t_comune c1, siac_t_comune c2
			where c1.ente_proprietario_id = enteproprietarioid
			and c2.ente_proprietario_id = c1.ente_proprietario_id
			and c1.login_operazione not like 'migr_%'
			and c2.login_operazione like 'migr_%'
			and c1.comune_belfiore_catastale_code = c2.comune_belfiore_catastale_code
            )
	loop
		strMessaggio := 'Update siac_t_indirizzo_soggetto per id comune '||comune.id_DaCancellare||'.';

		update siac_t_indirizzo_soggetto set comune_id=comune.id_DaMantenere
		where ente_proprietario_id=enteproprietarioid
		and comune_id=comune.id_DaCancellare;

		strMessaggio := 'Update siac_t_persona_fisica per id comune '||comune.id_DaCancellare||'.';

		update siac_t_persona_fisica set comune_id_nascita=comune.id_DaMantenere
		where ente_proprietario_id=enteproprietarioid
		and comune_id_nascita=comune.id_DaCancellare;

		strMessaggio := 'Delete siac_r_comune_provincia per id comune '||comune.id_DaCancellare||'.';

		delete from siac_r_comune_provincia
		where ente_proprietario_id=enteproprietarioid
		and   comune_id = comune.id_DaCancellare;

		strMessaggio := 'Delete siac_t_comune per id comune '||comune.id_DaCancellare||'.';

		delete from siac_t_comune
		where ente_proprietario_id=enteproprietarioid
		and   comune_id = comune.id_DaCancellare;

	end loop;

	codresult := 0;
    messaggioRisultato := strMessaggioFinale||'Ok.';
	exception
	when others  THEN
		raise notice '% % Errore DB % %',strMessaggioFinale,strMessaggio,SQLSTATE,
	        	substring(upper(SQLERRM) from 1 for 100);
		codresult := -1;
        messaggioRisultato:=strMessaggioFinale||strMessaggio||'ERRORE DB:'||SQLSTATE||' '||substring(upper(SQLERRM) from 1 for 500) ;
        return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;