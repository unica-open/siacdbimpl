/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/

CREATE OR REPLACE FUNCTION siac.fnc_pagopa_t_riconc_aggiorna_accertamento(
	p_pagopa_ric_id integer,
	p_pagopa_ric_flusso_anno_accertamento integer,
	p_pagopa_ric_flusso_num_accertamento integer,
	p_codice_ente integer,
	p_anno_esercizio integer)
    RETURNS character varying
    LANGUAGE 'plpgsql'

    COST 100
    VOLATILE 
AS $BODY$
DECLARE
	strMessaggio    			VARCHAR(1500):='';  
    codicerisultato 			integer:=null;
    messaggiorisultato 			VARCHAR(1500):='';
	v_cnt 						integer:=null;
	v_pagopa_ric_flusso_anno_accertamento integer:=null;
	v_pagopa_ric_flusso_num_accertamento integer:=null;
	v_pagopa_ric_flusso_stato_elab VARCHAR(1500):='';--character varying;
	v_file_pagopa_id 			integer:=null;
	v_file_pagopa_stato_id 		integer:=null;
	v_count_file_pagopa_id 		integer:=null;
	
BEGIN
     codicerisultato :=0;
	 v_cnt := 0;
	 messaggiorisultato :='Inizio.';
    
    -- 2 errore gestito (nessun record prima query/collegamento DE/DS)
    -- 1 errore generico
    --  0 ok	

	strMessaggio:= 'Verifica parametri di input.';
 	if (p_pagopa_ric_id is  null) 
	then
		codicerisultato :=2;	 
		messaggiorisultato := 'p_pagopa_ric_id NULL';
		return codicerisultato::varchar ||'-'||messaggiorisultato;
	end if;
	if (p_pagopa_ric_flusso_anno_accertamento is  null) 
	then
		codicerisultato :=2;	 
		messaggiorisultato := 'p_pagopa_ric_flusso_anno_accertamento NULL';
		return codicerisultato::varchar ||'-'||messaggiorisultato;
	end if;
	if (p_pagopa_ric_flusso_num_accertamento is  null) 
	then
		codicerisultato :=2;	 
		messaggiorisultato := 'p_pagopa_ric_flusso_num_accertamento NULL';
		return codicerisultato::varchar ||'-'||messaggiorisultato;
	end if;
	if (p_codice_ente is  null) 
	then
		codicerisultato :=2;	 
		messaggiorisultato := 'p_codice_ente NULL';
		return codicerisultato::varchar ||'-'||messaggiorisultato;
	end if;
	if (p_anno_esercizio is  null) 
	then
		codicerisultato :=2;	 
		messaggiorisultato := 'p_anno_esercizio NULL';
		return codicerisultato::varchar ||'-'||messaggiorisultato;
	end if;
	
	strMessaggio:= 'Lettura dati attuali.';
	select 
	pagopa_t_riconciliazione.pagopa_ric_flusso_anno_accertamento, 
	pagopa_t_riconciliazione.pagopa_ric_flusso_num_accertamento,
	pagopa_t_riconciliazione.pagopa_ric_flusso_stato_elab,
	pagopa_t_riconciliazione.file_pagopa_id
	into
	v_pagopa_ric_flusso_anno_accertamento,
	v_pagopa_ric_flusso_num_accertamento,
	v_pagopa_ric_flusso_stato_elab,
	v_file_pagopa_id
	from siac.pagopa_t_riconciliazione
	where pagopa_t_riconciliazione.ente_proprietario_id = p_codice_ente
		 and pagopa_t_riconciliazione.data_cancellazione is null
		 and pagopa_t_riconciliazione.pagopa_ric_flusso_anno_esercizio = p_anno_esercizio
		 and pagopa_t_riconciliazione.pagopa_ric_id = p_pagopa_ric_id;
	raise notice ' Letti: v_pagopa_ric_flusso_anno_accertamento=% v_pagopa_ric_flusso_num_accertamento=% v_pagopa_ric_flusso_stato_elab=% v_file_pagopa_id=%',
		v_pagopa_ric_flusso_anno_accertamento,
		v_pagopa_ric_flusso_num_accertamento,
		v_pagopa_ric_flusso_stato_elab,
		v_file_pagopa_id;

	strMessaggio:= 'Lettura v_file_pagopa_stato_id';
	select 
	siac_d_file_pagopa_stato.file_pagopa_stato_id
	into
	v_file_pagopa_stato_id
	from siac.siac_d_file_pagopa_stato
	where siac_d_file_pagopa_stato.ente_proprietario_id = p_codice_ente 
		and siac_d_file_pagopa_stato.data_cancellazione is null
		and siac_d_file_pagopa_stato.file_pagopa_stato_code = 'ELABORATO_IN_CORSO_SC';
	raise notice ' Letti: v_file_pagopa_stato_id=% ',
		v_file_pagopa_stato_id;
	
	strMessaggio:= 'Lettura v_count_file_pagopa_id';
	SELECT count(*)
	into
	v_count_file_pagopa_id
	FROM siac.pagopa_t_riconciliazione
	WHERE pagopa_t_riconciliazione.ente_proprietario_id = p_codice_ente
		 AND pagopa_t_riconciliazione.data_cancellazione is null
		 AND pagopa_t_riconciliazione.pagopa_ric_flusso_anno_esercizio = p_anno_esercizio
		 AND pagopa_t_riconciliazione.file_pagopa_id = v_file_pagopa_id
		 AND pagopa_t_riconciliazione.pagopa_ric_flusso_stato_elab = 'E'
		 AND pagopa_t_riconciliazione.pagopa_ric_id != p_pagopa_ric_id;
	raise notice ' Letti: v_count_file_pagopa_id=% ',
		v_count_file_pagopa_id;
		
	------------------------------------------------------------------------------------------- 
	--- Caso 1 - in cui esistono i valori per anno e numero accertamento
	------------------------------------------------------------------------------------------- 
	if((v_pagopa_ric_flusso_anno_accertamento is not null) 
	   and (v_pagopa_ric_flusso_num_accertamento is not null)
	  and (v_pagopa_ric_flusso_anno_accertamento != 0)
	  and (v_pagopa_ric_flusso_num_accertamento != 0))
	then
		v_cnt := 0;
		--update normale
		strMessaggio:= 'Update normale';

		UPDATE pagopa_t_riconciliazione
		SET pagopa_ric_flusso_anno_accertamento = p_pagopa_ric_flusso_anno_accertamento, 
			pagopa_ric_flusso_num_accertamento = p_pagopa_ric_flusso_num_accertamento,
			data_modifica = now(),
			login_operazione = '_'||login_operazione
		WHERE ente_proprietario_id = p_codice_ente
			 AND data_cancellazione is null
			 AND pagopa_ric_flusso_anno_esercizio = p_anno_esercizio
			 AND pagopa_ric_id = p_pagopa_ric_id;
		GET DIAGNOSTICS v_cnt = ROW_COUNT;
		raise notice ' MOdificati: v_cnt=% ', v_cnt;

		if v_cnt != 0 
		then
			codicerisultato :=0;	 
			messaggiorisultato := 'Aggiornamento andato a buon fine';
		else
			codicerisultato :=2;	 
			messaggiorisultato := 'Aggiornamento andato a buon fine';
		end if;

	------------------------------------------------------------------------------------------- 
	--- Caso 2 - in cui non esistono i valori per anno e numero accertamento e pagopa_ric_flusso_stato_elab = 'E'
	------------------------------------------------------------------------------------------- 
	elsif (((v_pagopa_ric_flusso_anno_accertamento is null) or (v_pagopa_ric_flusso_anno_accertamento = 0))
		   and ((v_pagopa_ric_flusso_num_accertamento is null) or (v_pagopa_ric_flusso_num_accertamento = 0))
		   and (v_pagopa_ric_flusso_stato_elab = 'E'))
	then
		v_cnt := 0;
		--casi particolari(caso 2)
		strMessaggio:= 'casi particolari(caso 2.1)';

		UPDATE pagopa_t_riconciliazione
		SET pagopa_ric_flusso_anno_accertamento = p_pagopa_ric_flusso_anno_accertamento, 
			pagopa_ric_flusso_num_accertamento = p_pagopa_ric_flusso_num_accertamento,
			pagopa_ric_errore_id = null,
			pagopa_ric_flusso_stato_elab = 'N',
			data_modifica = now(),
			login_operazione = '_'||login_operazione
		WHERE ente_proprietario_id = p_codice_ente
			 AND data_cancellazione is null
			 AND pagopa_ric_flusso_anno_esercizio = p_anno_esercizio
			 AND pagopa_ric_id = p_pagopa_ric_id;

		GET DIAGNOSTICS v_cnt = ROW_COUNT;
		if v_cnt != 0 
		then
			if v_count_file_pagopa_id = 0 	--vuol dire che si deve fare un'altra update 
											-- (non ci sono altri dettagli con pagopa_ric_flusso_stato_elab = 'E')
			then
				v_cnt := 0;
				strMessaggio:= 'Caso 2.2 si deve fare altra update';

				UPDATE siac.siac_t_file_pagopa
				SET validita_fine = null,
					file_pagopa_stato_id = v_file_pagopa_stato_id,
					data_modifica = now(),
					login_operazione = '_'||login_operazione
				WHERE ente_proprietario_id = p_codice_ente
					 AND data_cancellazione is null
					 AND file_pagopa_id = v_file_pagopa_id; 

				GET DIAGNOSTICS v_cnt = ROW_COUNT;
				if v_cnt != 0 
				then
					codicerisultato :=0;	 
					messaggiorisultato := 'Aggiornamento andato a buon fine';
				else
					codicerisultato :=2;	 
					messaggiorisultato := 'Aggiornamento non andato a buon fine';
				end if;
			else
				codicerisultato :=0;	 
				messaggiorisultato := 'Aggiornamento andato a buon fine';
			end if;
		else
			codicerisultato :=2;	 
			messaggiorisultato := 'Aggiornamento non andato a buon fine';
		end if;

 	------------------------------------------------------------------------------------------- 
	--- Caso NON GESTITO
	------------------------------------------------------------------------------------------- 
	else
		-- altro non gestito
		codicerisultato :=2;	 
		messaggiorisultato := 'Condizione non gestita. Aggiornamento non andato a buon fine';
	end if;

    return codicerisultato::varchar ||'-'||messaggiorisultato;

exception
    when RAISE_EXCEPTION THEN
    	raise notice 'ERRORE DB: % % %',strMessaggio,SQLSTATE, substring(upper(SQLERRM) from 1 for 2500);
        codicerisultato:=1;
        messaggiorisultato :='KO. '||strMessaggio||substring(upper(SQLERRM) from 1 for 2500);
        return codicerisultato::varchar ||'-'||messaggiorisultato;
	when others  THEN
 		raise notice 'ERRORE DB: % % %',strMessaggio,SQLSTATE,substring(upper(SQLERRM) from 1 for 2500);
        codicerisultato:=1;
        messaggiorisultato :='KO. '||strMessaggio||substring(upper(SQLERRM) from 1 for 2500);
        return codicerisultato::varchar ||'-'||messaggiorisultato;
END;
$BODY$;
