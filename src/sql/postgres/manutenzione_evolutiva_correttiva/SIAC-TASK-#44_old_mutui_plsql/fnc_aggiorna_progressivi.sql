/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
drop FUNCTION if exists siac.fnc_aggiorna_progressivi(enteproprietarioid integer, elemento character varying, loginoperazione character varying, OUT codresult integer, OUT messaggiorisultato character varying);
CREATE OR REPLACE FUNCTION siac.fnc_aggiorna_progressivi(enteproprietarioid integer, elemento character varying, loginoperazione character varying, OUT codresult integer, OUT messaggiorisultato character varying)
RETURNS record AS
$body$
DECLARE

	strMessaggio VARCHAR(1500):='';
	strMessaggioFinale VARCHAR(1500):='';

	cursorSql varchar(1500) := null;
   	_curs refcursor;
    rec   record;

    v_count integer := 0;

    MOVGEST_IMPEGNI       CONSTANT varchar:='I';
    MOVGEST_ACCERTAMENTI  CONSTANT varchar:='A';
    SOGGETTI              CONSTANT varchar:='S';
    SIAC_D_AMBITO_CODE    CONSTANT varchar:='AMBITO_FIN';
    LIQUIDAZIONE 		  CONSTANT varchar:='L';

    SOGGETTI_KEY          CONSTANT varchar:='sog';
    LIQUIDAZIONE_KEY	  CONSTANT varchar:='liq_';
    siac_d_ambito_id integer := 0;

begin

	strMessaggioFinale := 'Aggiornamento progressivi per tipo movimento '||elemento||'.';
    codResult := 0;


    strMessaggio:=' Costruzione cursorSql.';
	IF elemento = MOVGEST_IMPEGNI OR elemento = MOVGEST_ACCERTAMENTI THEN
		cursorSql := 'select case when imp.movgest_tipo_code = '''||MOVGEST_IMPEGNI||''' then ''imp_''||imp.movgest_anno
        	when imp.movgest_tipo_code = '''||MOVGEST_ACCERTAMENTI||''' then ''acc_''||imp.movgest_anno
            end prog_key
            , imp.num prog_value
          from
            (select distinct t.movgest_tipo_code, m.movgest_anno, coalesce(max(m.movgest_numero),0) num  from siac_t_movgest m
            inner join siac_d_movgest_tipo t on (
                t.movgest_tipo_id = m.movgest_tipo_id and
                t.ente_proprietario_id=m.ente_proprietario_id and
                t.movgest_tipo_code='''||elemento||''' and
                t.data_cancellazione is null)
            where m.ente_proprietario_id='||enteProprietarioId||' group by t.movgest_tipo_code,m.movgest_anno)imp;';
	elsif elemento=SOGGETTI then
	    cursorSql := 'select '''||SOGGETTI_KEY||'''::varchar prog_key , sogg.num prog_value from
             (select soggetto_code::integer num  from siac_t_soggetto s
              where s.ente_proprietario_id='||enteProprietarioId||'
              and fnc_migr_isnumeric(soggetto_code)
			  order by  fnc_migr_sortnum(soggetto_code) desc limit 1)sogg;';
    elsif elemento=LIQUIDAZIONE then
	    cursorSql := 'select '''||LIQUIDAZIONE_KEY||'''||liq_anno prog_key , max(liq_numero) prog_value from
        			  siac_t_liquidazione where ente_proprietario_id='||enteProprietarioId||'group by liq_anno;';
    else
         RAISE EXCEPTION ' % ', 'elemento '||elemento||' non gestito.';
    end if;


 if cursorSql is not null then

    strMessaggio:='Lettura ambito_id';
    select ambito_id into strict siac_d_ambito_id
    from siac_d_ambito where ente_proprietario_id = enteProprietarioId
    and now() between validita_inizio and coalesce(validita_fine,now())
    and ambito_code = SIAC_D_AMBITO_CODE;

    strMessaggio:='Apertura cursorSql ';
    OPEN _curs FOR EXECUTE cursorSql;
    LOOP
        FETCH NEXT FROM _curs INTO rec;
        EXIT WHEN rec IS NULL;

        strMessaggio := 'Lettura progressivo Prog_key:'||rec.prog_key||'/prog_value:'||rec.prog_value;
        select coalesce (count(*),0) into v_count from siac_t_progressivo where ente_proprietario_id = enteProprietarioId
        and data_cancellazione is null and prog_key = rec.prog_key and ambito_id = siac_d_ambito_id;

        if v_count > 0 THEN
        	strMessaggio:='Aggiornamento progressivo';
            update siac_t_progressivo
            set prog_value = rec.prog_value
            , data_modifica = now()
            , login_operazione = loginOperazione
            where ente_proprietario_id = enteProprietarioId
            and data_cancellazione is null
            and prog_key = rec.prog_key
            and ambito_id = siac_d_ambito_id;
        --        	strMessaggio := strMessaggio|| 'Aggiornato.';
        else
        	strMessaggio:='Inserimento progressivo';
            insert into siac_t_progressivo
                (prog_key, prog_value, ambito_id, validita_inizio, ente_proprietario_id, login_operazione)
            values
                (rec.prog_key,rec.prog_value,siac_d_ambito_id,now(),enteProprietarioId,loginOperazione);
        --			strMessaggio := strMessaggio||'Inserito.';
        end if;
    END LOOP;
    messaggioRisultato:=strMessaggioFinale||'Ok.';
   END IF;
exception
    when RAISE_EXCEPTION THEN
    	raise notice '% % ERRORE : %',strMessaggioFinale,strMessaggio,
	        	substring(upper(SQLERRM) from 1 for 500);
        messaggioRisultato:=strMessaggioFinale||strMessaggio||' ERRORE :'||' '||substring(upper(SQLERRM) from 1 for 500) ;
        codResult := -1;
        return;
	when others  THEN
		raise notice '% % ERRORE DB % %',strMessaggioFinale,strMessaggio,SQLSTATE,
	        	substring(upper(SQLERRM) from 1 for 500);
        messaggioRisultato:=strMessaggioFinale||strMessaggio||' ERRORE DB '||SQLSTATE||' '||substring(upper(SQLERRM) from 1 for 500) ;
        codResult := -1;
        return;
end;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;


alter function siac.fnc_aggiorna_progressivi( integer,  character varying,  character varying, OUT  integer, OUT  character varying) owner to siac;
