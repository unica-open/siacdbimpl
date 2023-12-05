/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/

-- FUNCTION: siac.fnc_fasi_bil_gest_reimputa(integer, integer, character varying, timestamp without time zone, character varying, character varying)

-- DROP FUNCTION siac.fnc_fasi_bil_gest_reimputa(integer, integer, character varying, timestamp without time zone, character varying, character varying);

CREATE OR REPLACE FUNCTION siac.fnc_fasi_bil_gest_reimputa(
	enteproprietarioid integer,
	annobilancio integer,
	loginoperazione character varying,
	p_dataelaborazione timestamp without time zone,
	p_movgest_tipo_code character varying,
	impostaprovvedimento character varying DEFAULT 'true'::character varying,
	OUT outfasebilelabretid integer,
	OUT codicerisultato integer,
	OUT messaggiorisultato character varying)
RETURNS record AS
$body$
DECLARE

	strMessaggio       VARCHAR(1500):='';
	strMessaggioFinale VARCHAR(1500):='';
	codResult          integer;
    faseRec             record;
    v_motivo           VARCHAR(1500):='';

	-- 03.06.2020 Sofia Jira siac-7593
    componenteDef     varchar(50):=null;

    componenteFresco  constant varchar:='Fresco';
    componenteFPV     constant varchar:='FPV';

    sottoTipoDesc        constant varchar:='Applicato';

    faseCodeREIMP     constant varchar:='ROR effettivo';
    faseCodeREANNO    constant varchar:='Gestione';

    motivoCodeREIMP   constant varchar:='REIMP';
    motivoCodeREANNO   constant varchar:='REANNO';

    componenteDefId   integer:=null;
    componenteFrescoId  integer:=null;
    componenteFPVId     integer:=null;
    countComp  integer:=0;
BEGIN

    outfasebilelabretid:=null;
    codiceRisultato:=null;
    messaggioRisultato:=null;

    -- 03.06.2020 Sofia Jira siac-7593
	-- aggiungere estrazione della componente fittizia
    -- v_motivo:=TRIM(SUBSTR(p_movgest_tipo_code,3,6));
    v_motivo:=trim(upper(split_part(p_movgest_tipo_code,'|',2)));
    componenteDef:=trim(split_part(p_movgest_tipo_code,'|',3));
	raise notice 'v_motivo=%',v_motivo;
    raise notice 'componenteDef=%',componenteDef;

/*
	-- -- 03.06.2020 Sofia Jira siac-7593
	-- test sulle componenti
    if SUBSTR(p_movgest_tipo_code,1,1) = 'I' or SUBSTR(p_movgest_tipo_code,1,1) = 'E' then
      strMessaggioFinale:='Reimputazione Principale anno = '||annoBilancio::varchar||'.'
         ||' Verifica esistenza componente fittizia '||componentedef||'.';
      -- fittizia
      if coalesce(componenteDef,'')!='' then
      	select comp_tipo.elem_det_comp_tipo_id into componenteDefId
        from siac_d_bil_elem_det_comp_tipo comp_tipo, siac_d_bil_elem_det_comp_tipo_imp tipo_imp,
             siac_d_bil_elem_Det_comp_tipo_stato stato
        where comp_tipo.ente_proprietario_id=enteProprietarioId
        and   comp_tipo.elem_det_comp_tipo_desc=componenteDef
        and   stato.elem_det_comp_tipo_stato_id=comp_tipo.elem_det_comp_tipo_stato_id
        and   stato.elem_det_comp_tipo_stato_code!='A'
        and   tipo_imp.elem_det_comp_tipo_imp_id=comp_tipo.elem_det_comp_tipo_imp_id
        and   tipo_imp.elem_Det_comp_tipo_imp_desc='Si'
        and   comp_tipo.data_cancellazione is null
        and   date_trunc('DAY',(annoBilancio::varchar||'-01-01')::timestamp)>=date_trunc('DAY',comp_tipo.validita_inizio)
        and   date_trunc('DAY',(annoBilancio::varchar||'-12-31')::timestamp)<=
              date_trunc('DAY', coalesce(comp_tipo.validita_fine,(annoBilancio::varchar||'-12-31')::timestamp));
        raise notice 'componenteDefId=%',componenteDefId;
        if componenteDefId is  null then
      --  	strMessaggio:=' Non esistente o non valida.';
            raise exception ' Non esistente o non valida o impegnabile.';
        end if;
      end if;

       if coalesce(componenteDef,'')='' then
        strMessaggioFinale:='Reimputazione Principale anno = '||annoBilancio::varchar||'.'
         ||' Verifica esistenza componente '||componenteFresco||'.';
      	select comp_tipo.elem_det_comp_tipo_id into componenteFrescoId
        from siac_d_bil_elem_det_comp_tipo comp_tipo, siac_d_bil_elem_det_comp_tipo_imp tipo_imp,
             siac_d_bil_elem_Det_comp_tipo_stato stato,
             siac_d_bil_elem_det_comp_macro_tipo macro
        where comp_tipo.ente_proprietario_id=enteProprietarioId
        and   macro.elem_det_comp_macro_tipo_id=comp_tipo.elem_det_comp_macro_tipo_id
        and   macro.elem_det_comp_macro_tipo_desc=componenteFresco
        and   stato.elem_det_comp_tipo_stato_id=comp_tipo.elem_det_comp_tipo_stato_id
        and   stato.elem_det_comp_tipo_stato_code!='A'
        and   tipo_imp.elem_det_comp_tipo_imp_id=comp_tipo.elem_det_comp_tipo_imp_id
        and   tipo_imp.elem_Det_comp_tipo_imp_desc='Si'
        and   comp_tipo.data_cancellazione is null
        and   macro.data_cancellazione is null
        and   date_trunc('DAY',(annoBilancio::varchar||'-01-01')::timestamp)>=date_trunc('DAY',comp_tipo.validita_inizio)
        and   date_trunc('DAY',(annoBilancio::varchar||'-12-31')::timestamp)<=
              date_trunc('DAY', coalesce(comp_tipo.validita_fine,(annoBilancio::varchar||'-12-31')::timestamp));
		raise notice 'componenteFrescoId=%',componenteFrescoId;
        if componenteFrescoId is  null then
      --  	strMessaggio:=' Non esistente o non valida.';
            raise exception ' Non esistente o non valida o impegnabile.';
        end if;

        if componenteFrescoId is not null then
            countComp:=null;
            select 1 into countComp
            from siac_d_bil_elem_det_comp_tipo comp_tipo, siac_d_bil_elem_det_comp_tipo_imp tipo_imp,
             siac_d_bil_elem_Det_comp_tipo_stato stato,
             siac_d_bil_elem_det_comp_macro_tipo macro
            where comp_tipo.ente_proprietario_id=enteProprietarioId
            and   comp_tipo.elem_det_comp_tipo_id!=componenteFrescoId
            and   macro.elem_det_comp_macro_tipo_id=comp_tipo.elem_det_comp_macro_tipo_id
            and   macro.elem_det_comp_macro_tipo_desc=componenteFresco
            and   stato.elem_det_comp_tipo_stato_id=comp_tipo.elem_det_comp_tipo_stato_id
            and   stato.elem_det_comp_tipo_stato_code!='A'
            and   tipo_imp.elem_det_comp_tipo_imp_id=comp_tipo.elem_det_comp_tipo_imp_id
            and   tipo_imp.elem_Det_comp_tipo_imp_desc='Si'
            and   comp_tipo.data_cancellazione is null
            and   macro.data_cancellazione is null
            and   date_trunc('DAY',(annoBilancio::varchar||'-01-01')::timestamp)>=date_trunc('DAY',comp_tipo.validita_inizio)
            and   date_trunc('DAY',(annoBilancio::varchar||'-12-31')::timestamp)<=
                  date_trunc('DAY', coalesce(comp_tipo.validita_fine,(annoBilancio::varchar||'-12-31')::timestamp));
       		raise notice 'countComp=%',countComp;

            if countComp is not null then
               --  	strMessaggio:=' Esistente non unica.';
               raise exception ' Esistente non unica.';
          --   return;
            end if;
        end if;
  		strMessaggioFinale:='Reimputazione Principale anno = '||annoBilancio::varchar||'.'
         ||' Verifica esistenza componente '||componenteFPV||'.';
      	select comp_tipo.elem_det_comp_tipo_id into componenteFPVId
        from siac_d_bil_elem_det_comp_tipo comp_tipo, siac_d_bil_elem_det_comp_tipo_imp tipo_imp,
             siac_d_bil_elem_Det_comp_tipo_stato stato,
             siac_d_bil_elem_det_comp_macro_tipo macro,
             siac_d_bil_elem_Det_comp_tipo_fase fase,
             siac_d_bil_elem_det_comp_sotto_tipo sotto_tipo
        where comp_tipo.ente_proprietario_id=enteProprietarioId
        and   macro.elem_det_comp_macro_tipo_id=comp_tipo.elem_det_comp_macro_tipo_id
        and   macro.elem_det_comp_macro_tipo_desc=componenteFPV
        and   fase.elem_det_comp_tipo_fase_id=comp_tipo.elem_det_comp_tipo_fase_id
        and   fase.elem_det_comp_tipo_fase_desc=
              ( case when v_motivo=motivoCodeREANNO then fasecodereanno
                else fasecodereimp end )
        and   sotto_tipo.elem_det_comp_sotto_tipo_id=comp_tipo.elem_det_comp_sotto_tipo_id
        and   sotto_tipo.elem_det_comp_sotto_tipo_desc=sottoTipoDesc
        and   stato.elem_det_comp_tipo_stato_id=comp_tipo.elem_det_comp_tipo_stato_id
        and   stato.elem_det_comp_tipo_stato_code!='A'
        and   tipo_imp.elem_det_comp_tipo_imp_id=comp_tipo.elem_det_comp_tipo_imp_id
        and   tipo_imp.elem_Det_comp_tipo_imp_desc='Si'
        and   comp_tipo.data_cancellazione is null
        and   macro.data_cancellazione is null
        and   fase.data_cancellazione is null
        and   sotto_tipo.data_cancellazione is null
        and   date_trunc('DAY',(annoBilancio::varchar||'-01-01')::timestamp)>=date_trunc('DAY',comp_tipo.validita_inizio)
        and   date_trunc('DAY',(annoBilancio::varchar||'-12-31')::timestamp)<=
              date_trunc('DAY', coalesce(comp_tipo.validita_fine,(annoBilancio::varchar||'-12-31')::timestamp));
		raise notice 'componenteFPVId=%',componenteFPVId;
        if componenteFPVId is  null then
      --  	strMessaggio:=' Non esistente o non valida.';
            raise exception ' Non esistente o non valida o impegnabile.';
        end if;

         if componenteFPVId is not null then
            countComp:=null;
            select 1 into countComp
            from siac_d_bil_elem_det_comp_tipo comp_tipo, siac_d_bil_elem_det_comp_tipo_imp tipo_imp,
            	 siac_d_bil_elem_Det_comp_tipo_stato stato,
            	 siac_d_bil_elem_det_comp_macro_tipo macro,
                 siac_d_bil_elem_Det_comp_tipo_fase fase,
                 siac_d_bil_elem_det_comp_sotto_tipo sotto_tipo
            where comp_tipo.ente_proprietario_id=enteProprietarioId
            and   comp_tipo.elem_det_comp_tipo_id!=componenteFPVId
            and   macro.elem_det_comp_macro_tipo_id=comp_tipo.elem_det_comp_macro_tipo_id
            and   macro.elem_det_comp_macro_tipo_desc=componenteFPV
            and   fase.elem_det_comp_tipo_fase_id=comp_tipo.elem_det_comp_tipo_fase_id
     		and   fase.elem_det_comp_tipo_fase_desc=
            	  ( case when v_motivo=motivoCodeREANNO then fasecodereanno
            	    else fasecodereimp end )
            and   sotto_tipo.elem_det_comp_sotto_tipo_id=comp_tipo.elem_det_comp_sotto_tipo_id
            and   sotto_tipo.elem_det_comp_sotto_tipo_desc=sottoTipoDesc
            and   stato.elem_det_comp_tipo_stato_id=comp_tipo.elem_det_comp_tipo_stato_id
            and   stato.elem_det_comp_tipo_stato_code!='A'
            and   tipo_imp.elem_det_comp_tipo_imp_id=comp_tipo.elem_det_comp_tipo_imp_id
            and   tipo_imp.elem_Det_comp_tipo_imp_desc='Si'
            and   comp_tipo.data_cancellazione is null
            and   macro.data_cancellazione is null
            and   fase.data_cancellazione is null
            and   sotto_tipo.data_cancellazione is null
            and   date_trunc('DAY',(annoBilancio::varchar||'-01-01')::timestamp)>=date_trunc('DAY',comp_tipo.validita_inizio)
            and   date_trunc('DAY',(annoBilancio::varchar||'-12-31')::timestamp)<=
                  date_trunc('DAY', coalesce(comp_tipo.validita_fine,(annoBilancio::varchar||'-12-31')::timestamp));
       		raise notice 'countComp=%',countComp;

            if countComp is not null then
               --  	strMessaggio:=' Esistente non unica.';
               raise exception ' Esistente non unica.';
          --   return;
            end if;
        end if;
      end if;
    end if;

*/


    if SUBSTR(p_movgest_tipo_code,1,1) = 'I' or SUBSTR(p_movgest_tipo_code,1,1) = 'E' then
       strMessaggioFinale:='1 - Reimputazione Principale (Impegni) a partire anno = '||annoBilancio::varchar||'.';

	   select * into faseRec
         from fnc_fasi_bil_gest_reimputa_sing
    	     (
               enteProprietarioId,
               annoBilancio,
               loginOperazione,
               p_dataElaborazione,
               'I',
               v_motivo,
               componenteDef,  -- 05.06.2020 Sofia Jira siac-7593
               impostaProvvedimento

              );
       if faseRec.codiceRisultato=-1  then
      --    strMessaggio:='Errore Lancio popolamento.'||faseRec.messaggioRisultato;
          raise exception 'Errore Lancio popolamento % .',faseRec.messaggioRisultato;
  --        return;
       end if;
       outfasebilelabretid:=faseRec.outfasebilelabretid;
    end if;



    if SUBSTR(p_movgest_tipo_code,1,1) = 'A' or SUBSTR(p_movgest_tipo_code,1,1) = 'E' then
       strMessaggioFinale:='2 - Reimputazione Principale Accertamenti a partire anno = '||annoBilancio::varchar||'.';

  	   select * into faseRec
         from fnc_fasi_bil_gest_reimputa_sing
    	     (
              enteProprietarioId,
              annoBilancio,
              loginOperazione,
              p_dataElaborazione,
              'A',
              v_motivo,
              null,  -- 05.06.2020 Sofia Jira siac-7593
              impostaProvvedimento
              );
       if faseRec.codiceRisultato=-1  then
         -- strMessaggio:='Errore Lancio popolamento.'||faseRec.messaggioRisultato;
          raise exception 'Errore Lancio popolamento % .',faseRec.messaggioRisultato;
         -- return;
       end if;
       if SUBSTR(p_movgest_tipo_code,1,1) = 'A' then
          outfasebilelabretid:=faseRec.outfasebilelabretid;
       end if;
	end if;


    if SUBSTR(p_movgest_tipo_code,1,1) = 'E' then
       strMessaggioFinale:='3 - Reimputazione Principale Vincoli a partire anno = '||annoBilancio::varchar||'.';

       select * into faseRec
         from fnc_fasi_bil_gest_reimputa_vincoli
         	 (
              enteProprietarioId,
              annoBilancio,
              loginOperazione,
              p_dataElaborazione
              );
        if faseRec.codiceRisultato=-1  then
      --     strMessaggio:='Errore Lancio popolamento.'||faseRec.messaggioRisultato;
           raise exception 'Errore Lancio popolamento % .',faseRec.messaggioRisultato;
     --      return;
        end if;
	end if;

    codiceRisultato:=0;
    messaggioRisultato:=strMessaggioFinale||' FINE';

    return;

exception
    when RAISE_EXCEPTION THEN
    	raise notice '% % ERRORE : %',strMessaggioFinale,strMessaggio,substring(upper(SQLERRM) from 1 for 1500);
        messaggioRisultato:=strMessaggioFinale||strMessaggio||'ERRORE :'||' '||substring(upper(SQLERRM) from 1 for 1500) ;
        codiceRisultato:=-1;
        return;

	when no_data_found THEN
		raise notice ' % % Nessun elemento trovato.' ,strMessaggioFinale,strMessaggio;
        messaggioRisultato:=strMessaggioFinale||strMessaggio||'Nessun elemento trovato.' ;
        codiceRisultato:=-1;
		return;
	when others  THEN
		raise notice '% % Errore DB % %',strMessaggioFinale,strMessaggio,SQLSTATE,substring(upper(SQLERRM) from 1 for 1500);
        messaggioRisultato:=strMessaggioFinale||strMessaggio||'Errore DB '||SQLSTATE||' '||substring(upper(SQLERRM) from 1 for 1500) ;
        codiceRisultato:=-1;
        return;

END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;