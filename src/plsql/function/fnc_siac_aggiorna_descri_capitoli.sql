/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
-- Davide - 03.11.2016 - Funzione per l'aggiornamento delle descrizioni dei capitoli equivalenti
--                       relativi al tipo capitolo passato in input

CREATE OR REPLACE FUNCTION fnc_siac_aggiorna_descri_capitoli (
  annobilancio integer,
  tipo_capitolo varchar,
  enteproprietarioid integer,
  loginoperazione varchar,
  dataelaborazione timestamp,
  out codicerisultato integer,
  out messaggiorisultato varchar
)
RETURNS record AS
$body$
DECLARE

    strMessaggio         VARCHAR(1500):='';
    strMessaggioFinale   VARCHAR(1500):='';
	tipodest             VARCHAR(6):='';

	descCapi             VARCHAR:=null;
	descArti             VARCHAR:=null;

    BILANCIO_CODE        CONSTANT varchar:='BIL_'||annobilancio::varchar;

	DESCCP19054          CONSTANT varchar:='ALTRI FONDI E ACCANTONAMENTI';
	DESCAT190547         CONSTANT varchar:='STATI GENERALI DEL PIEMONTE';
	DESCCP11021          CONSTANT varchar:='SERVIZI DI TRASFERTA GARANTI';
	DESCAT110211         CONSTANT varchar:='RIMBORSO SPESE DI MISSIONE GARANTE DEI DETENUTI';
	DESCAT110212         CONSTANT varchar:='RIMBORSO SPESE DI MISSIONE GARANTE REGIONALE PER L''INFANZIA E L''ADOLESCENZA';
    CAPITOLO_EP          CONSTANT varchar:='CAP-EP';
    CAPITOLO_UP          CONSTANT varchar:='CAP-UP';
    CAPITOLO_EG          CONSTANT varchar:='CAP-EG';
    CAPITOLO_UG          CONSTANT varchar:='CAP-UG';

    codResult            integer:=null;
    --dataInizioVal      timestamp:=null;

    bilancioId           integer:=null;
    periodoId            integer:=null;

    -- Id tipi capitolo
    IdCapitoloEP         integer :=null;
    IdCapitoloUP         integer :=null;
    IdCapitoloEG         integer :=null;
    IdCapitoloUG         integer :=null;
    IdCapitoloOrig       integer :=null;
    IdCapitoloDest       integer :=null;

	Capitoli             record;

BEGIN

    messaggioRisultato:='';
    codiceRisultato:=0;

	if tipo_capitolo = CAPITOLO_EP then
	    tipodest := CAPITOLO_EG;
	elsif tipo_capitolo = CAPITOLO_UP then
	    tipodest := CAPITOLO_UG;
	elsif tipo_capitolo = CAPITOLO_EG then
	    tipodest := CAPITOLO_EP;
	elsif tipo_capitolo = CAPITOLO_UG then
	    tipodest := CAPITOLO_UP;
	else
	    RAISE EXCEPTION 'Aggiornamento descrizione Capitoli per Anno bilancio=% . Tipo capitolo in input non permesso',annoBilancio::varchar;
	end if;

    --dataInizioVal:=clock_timestamp();-- usato al posto di now() per essere certi di riconoscere i record inseriti dopo la chiamata della funzione;

	strMessaggioFinale:='Aggiornamento descrizione Capitoli '||tipodest||' equivalenti Capitoli '||tipo_capitolo||'.Anno bilancio='||annoBilancio::varchar||'.';

	strMessaggio:='Lettura IdCapitoloEP  per tipo='||CAPITOLO_EP||'.';
	select tipo.elem_tipo_id into strict IdCapitoloEP
    from siac_d_bil_elem_tipo tipo
    where tipo.elem_tipo_code=CAPITOLO_EP
    and   tipo.ente_proprietario_id=enteProprietarioId
    and   tipo.data_cancellazione is null
    and   date_trunc('day',dataElaborazione)>=date_trunc('day',tipo.validita_inizio)
    and   ( date_trunc('day',dataElaborazione)<=date_trunc('day',tipo.validita_fine) or tipo.validita_fine is null);

	strMessaggio:='Lettura IdCapitoloUP  per tipo='||CAPITOLO_UP||'.';
	select tipo.elem_tipo_id into strict IdCapitoloUP
    from siac_d_bil_elem_tipo tipo
    where tipo.elem_tipo_code=CAPITOLO_UP
    and   tipo.ente_proprietario_id=enteProprietarioId
    and   tipo.data_cancellazione is null
    and   date_trunc('day',dataElaborazione)>=date_trunc('day',tipo.validita_inizio)
    and   ( date_trunc('day',dataElaborazione)<=date_trunc('day',tipo.validita_fine) or tipo.validita_fine is null);

	strMessaggio:='Lettura IdCapitoloEG  per tipo='||CAPITOLO_EG||'.';
	select tipo.elem_tipo_id into strict IdCapitoloEG
    from siac_d_bil_elem_tipo tipo
    where tipo.elem_tipo_code=CAPITOLO_EG
    and   tipo.ente_proprietario_id=enteProprietarioId
    and   tipo.data_cancellazione is null
    and   date_trunc('day',dataElaborazione)>=date_trunc('day',tipo.validita_inizio)
    and   ( date_trunc('day',dataElaborazione)<=date_trunc('day',tipo.validita_fine) or tipo.validita_fine is null);

	strMessaggio:='Lettura IdCapitoloUG  per tipo='||CAPITOLO_UG||'.';
	select tipo.elem_tipo_id into strict IdCapitoloUG
    from siac_d_bil_elem_tipo tipo
    where tipo.elem_tipo_code=CAPITOLO_UG
    and   tipo.ente_proprietario_id=enteProprietarioId
    and   tipo.data_cancellazione is null
    and   date_trunc('day',dataElaborazione)>=date_trunc('day',tipo.validita_inizio)
    and   ( date_trunc('day',dataElaborazione)<=date_trunc('day',tipo.validita_fine) or tipo.validita_fine is null);

  	strMessaggio:='Lettura bilancioId e periodoId  per annoBilancio='||annoBilancio::varchar||'.';
    select bil.bil_id, per.periodo_id into strict bilancioId, periodoId
    from siac_t_bil bil, siac_t_periodo per
    where bil.ente_proprietario_id=enteProprietarioId
    and   per.periodo_id=bil.periodo_id
    and   per.anno::INTEGER=annoBilancio
    and   bil.data_cancellazione is null
    and   per.data_cancellazione is null;

	if tipodest = CAPITOLO_EP then
	    IdCapitoloOrig := IdCapitoloEG;
	    IdCapitoloDest := IdCapitoloEP;
	elsif tipodest = CAPITOLO_UP then
	    IdCapitoloOrig := IdCapitoloUG;
	    IdCapitoloDest := IdCapitoloUP;
	elsif tipodest = CAPITOLO_EG then
	    IdCapitoloOrig := IdCapitoloEP;
	    IdCapitoloDest := IdCapitoloEG;
	elsif tipodest = CAPITOLO_UG then
	    IdCapitoloOrig := IdCapitoloUP;
	    IdCapitoloDest := IdCapitoloUG;
	end if;

    -- Ciclo sui Capitoli di tipo tipo_capitolo passato in input per un determinato anno bilancio
	-- Per ogni capitolo estratto, aggiorna la descrizione dei capitoli equivalenti del tipo inverso a quello dato
	-- (se CAP-UP aggiorna CAP-UG, se CAP-EP aggiorna CAP-EG....) con la descrizione dei capitoli letti
    for Capitoli IN
        ( select capi.elem_code, capi.elem_code2, capi.elem_code3, capi.elem_desc, capi.elem_desc2
   		    from siac_t_bil_elem capi
		   where capi.ente_proprietario_id=enteProprietarioId
		     and capi.bil_id=bilancioId
			 and capi.elem_tipo_id=IdCapitoloOrig
           order by capi.elem_code::integer,capi.elem_code2::integer,capi.elem_code3) loop

		descCapi := null;
		descArti := null;

        -- Sofia
        if tipo_capitolo = CAPITOLO_UP then
		 if Capitoli.elem_code = '11021' and Capitoli.elem_code2 = '1' then -- ok
		    descCapi := DESCCP11021;
		    descArti := DESCAT110211;

  	  	 elsif Capitoli.elem_code = '11021' and Capitoli.elem_code2 = '2' then
		    descCapi := DESCCP11021;
		    descArti := DESCAT110212;
         end if;
        end if;

        -- Sofia
		if descCapi is null or  descArti is null then
		    descCapi := Capitoli.elem_desc;
		    descArti := Capitoli.elem_desc2;
		end if;

        strMessaggio:='Aggiornamento capitolo equivalente '||Capitoli.elem_code||'/'||Capitoli.elem_code2||'/'||Capitoli.elem_code3||' al tipo '||tipo_capitolo||'.';

	    BEGIN
            update siac_t_bil_elem capdest
			   set elem_desc = descCapi,  --(CASE WHEN capdest.elem_code = '19054' THEN DESCCP19054 ELSE descCapi END),
			       elem_desc2 = descArti, -- (CASE WHEN capdest.elem_code = '19054' AND capdest.elem_code2 = '7' THEN DESCAT190547 ELSE descArti END),
				   data_modifica = dataelaborazione,
				   login_operazione = capdest.login_operazione||'-'||loginoperazione
             where capdest.elem_code=Capitoli.elem_code
			   and capdest.elem_code2=Capitoli.elem_code2
			   and capdest.elem_code3=Capitoli.elem_code3
			   and capdest.ente_proprietario_id=enteProprietarioId
			   and capdest.bil_id=bilancioId
			   and capdest.elem_tipo_id=IdCapitoloDest;

        EXCEPTION
	        WHEN OTHERS THEN
                RAISE EXCEPTION 'Errore nell''aggiornamento capitolo equivalente % al tipo %', Capitoli.elem_code||'/'||Capitoli.elem_code2||'/'||Capitoli.elem_code3, tipo_capitolo;
        END;
    end loop;

    messaggioRisultato:=strMessaggioFinale||'OK .';
    return;

exception
    when RAISE_EXCEPTION THEN
        raise notice '% % ERRORE : %',strMessaggioFinale,strMessaggio,
                substring(upper(SQLERRM) from 1 for 500);
        messaggioRisultato:=strMessaggioFinale||strMessaggio||'ERRORE :'||' '||substring(upper(SQLERRM) from 1 for 500) ;
        codiceRisultato:=-1;
        return;

    when no_data_found THEN
        raise notice ' % % Nessun elemento trovato.' ,strMessaggioFinale,strMessaggio;
        messaggioRisultato:=strMessaggioFinale||strMessaggio||'Nessun elemento trovato.' ;
        codiceRisultato:=-1;
        return;
    when others  THEN
        raise notice '% % Errore DB % %',strMessaggioFinale,strMessaggio,SQLSTATE,
                substring(upper(SQLERRM) from 1 for 50);
        messaggioRisultato:=strMessaggioFinale||strMessaggio||'Errore DB '||SQLSTATE||' '||substring(upper(SQLERRM) from 1 for 50) ;
        codiceRisultato:=-1;
        return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;
