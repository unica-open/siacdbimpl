/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION fnc_fasi_bil_gest_apertura_pluri_puntuale(
  enteProprietarioId     integer,
  annoBilancio           integer,
  loginOperazione        varchar,
  dataElaborazione       timestamp,
  out faseBilElabRetId   integer,
  out codiceRisultato    integer,
  out messaggioRisultato varchar
)
RETURNS record AS
$body$
DECLARE

	strMessaggio VARCHAR(1500):='';
	strMessaggioFinale VARCHAR(1500):='';

	codResult         integer:=null;
    faseBilElabId     integer:=null;

    MOVGEST_TS_T_TIPO CONSTANT varchar:='T';
    MOVGEST_TS_S_TIPO CONSTANT varchar:='S';

    CAP_UG_TIPO       CONSTANT varchar:='CAP-UG';
    CAP_EG_TIPO       CONSTANT varchar:='CAP-EG';

    IMP_MOVGEST_TIPO CONSTANT varchar:='I';
    ACC_MOVGEST_TIPO CONSTANT varchar:='A';

    APE_GEST_PLURI    CONSTANT varchar:='APE_GEST_PLURI';
    faseRec record;

    faseElabRec record;

BEGIN
	faseBilElabRetId:=null;
    codiceRisultato:=null;
    messaggioRisultato:=null;


    strMessaggioFinale:='Apertura bilancio gestione.Ribaltamento movimenti  pluriennali da Gestione precedente. Anno bilancio='||annoBilancio::varchar||'.';


    strMessaggio:='Lancio popolamento.';
    select * into faseRec
    from fnc_fasi_bil_gest_apertura_pluri_popola_puntuale
    	 (enteProprietarioId,
		  annoBilancio,
		  loginOperazione,
		  dataElaborazione
          );
    if faseRec.codiceRisultato=-1 or coalesce(faseRec.faseBilElabRetId,0)=0 then
     strMessaggio:='Lancio popolamento.'||faseRec.messaggioRisultato;
     raise exception ' Errore.';
    end if;

    if coalesce(faseRec.faseBilElabRetId,0)>0 then
        faseBilElabId:=faseRec.faseBilElabRetId;

        strMessaggio:='Lancio elabora pluriennali tipo='||IMP_MOVGEST_TIPO|| '.';
    	select * into faseElabRec
        from fnc_fasi_bil_gest_apertura_pluri_elabora
             (enteProprietarioId,
			  annoBilancio,
			  faseBilElabId,
			  CAP_UG_TIPO,
		      IMP_MOVGEST_TIPO,
		      MOVGEST_TS_T_TIPO,
			  null,
		      null,
			  loginOperazione,
		      dataElaborazione
             );
   		if faseElabRec.codiceRisultato=-1 then
	     -- errore
         strMessaggio:='Lancio elabora pluriennali tipo='||IMP_MOVGEST_TIPO|| '.'||
                       faseElabRec.messaggioRisultato;
         raise exception ' Errore.';
    	end if;

        strMessaggio:='Lancio elabora pluriennali tipo='||IMP_MOVGEST_TIPO|| ' SUB.';
    	select * into faseElabRec
        from fnc_fasi_bil_gest_apertura_pluri_elabora
             (enteProprietarioId,
			  annoBilancio,
			  faseBilElabId,
			  CAP_UG_TIPO,
		      IMP_MOVGEST_TIPO,
		      MOVGEST_TS_S_TIPO,
			  null,
		      null,
			  loginOperazione,
		      dataElaborazione
             );
   		if faseElabRec.codiceRisultato=-1 then
	     -- errore
          strMessaggio:='Lancio elabora pluriennali tipo='||IMP_MOVGEST_TIPO|| ' SUB.'||
 				         faseElabRec.messaggioRisultato;
         raise exception ' Errore.';
    	end if;


        strMessaggio:='Lancio elabora pluriennali tipo='||ACC_MOVGEST_TIPO|| '.';
    	select * into faseElabRec
        from fnc_fasi_bil_gest_apertura_pluri_elabora
             (enteProprietarioId,
			  annoBilancio,
			  faseBilElabId,
			  CAP_EG_TIPO,
		      ACC_MOVGEST_TIPO,
		      MOVGEST_TS_T_TIPO,
			  null,
		      null,
			  loginOperazione,
		      dataElaborazione
             );
   		if faseElabRec.codiceRisultato=-1 then
	     -- errore
         strMessaggio:='Lancio elabora pluriennali tipo='||ACC_MOVGEST_TIPO|| '.'||
			         faseElabRec.messaggioRisultato;
         raise exception ' Errore.';
    	end if;

        strMessaggio:='Lancio elabora pluriennali tipo='||ACC_MOVGEST_TIPO|| ' SUB.';
    	select * into faseElabRec
        from fnc_fasi_bil_gest_apertura_pluri_elabora
             (enteProprietarioId,
			  annoBilancio,
			  faseBilElabId,
			  CAP_EG_TIPO,
		      ACC_MOVGEST_TIPO,
		      MOVGEST_TS_S_TIPO,
			  null,
		      null,
			  loginOperazione,
		      dataElaborazione
             );
   		if faseElabRec.codiceRisultato=-1 then
	     -- errore
         strMessaggio:='Lancio elabora pluriennali tipo='||ACC_MOVGEST_TIPO|| ' SUB.'||
		  	         faseElabRec.messaggioRisultato;
         raise exception ' Errore.';

    	end if;

        /*strMessaggio:='Lancio elabora pluriennali-ribaltamento vincoli.';
        select * into faseElabRec
        from fnc_fasi_bil_gest_apertura_pluri_vincoli
             (enteProprietarioId,
		      annoBilancio,
		      faseBilElabId,
			  loginOperazione,
			  dataElaborazione
             );

         if faseElabRec.codiceRisultato=-1 then
	     -- errore
         strMessaggio:='Lancio elabora pluriennali tipo-ribaltamento vincoli.'||
		  	         faseElabRec.messaggioRisultato;
         raise exception ' Errore.';

    	end if;*/
    end if;

    strMessaggio:='Aggiornamento stato fase bilancio IN-n per chiusura.';
    update fase_bil_t_elaborazione fase
    set fase_bil_elab_esito='OK',
        fase_bil_elab_esito_msg='ELABORAZIONE FASE BILANCIO '||APE_GEST_PLURI||' CHIUSURA.'
    where fase.fase_bil_elab_id=faseBilElabId;

    faseBilElabRetId:=faseBilElabId;
    codiceRisultato:=0;
    messaggioRisultato:=strMessaggioFinale||' FINE';

    return;

exception
    when RAISE_EXCEPTION THEN
    	raise notice '% % ERRORE : %',strMessaggioFinale,strMessaggio,
	        	substring(upper(SQLERRM) from 1 for 500);
        messaggioRisultato:=strMessaggioFinale||strMessaggio||'ERRORE :'||' '||substring(upper(SQLERRM) from 1 for 500) ;
        codiceRisultato:=-1;
        faseBilElabRetId:=null;
        return;

	when no_data_found THEN
		raise notice ' % % Nessun elemento trovato.' ,strMessaggioFinale,strMessaggio;
        messaggioRisultato:=strMessaggioFinale||strMessaggio||'Nessun elemento trovato.' ;
        codiceRisultato:=-1;
        faseBilElabRetId:=null;
		return;
	when others  THEN
		raise notice '% % Errore DB % %',strMessaggioFinale,strMessaggio,SQLSTATE,
	        	substring(upper(SQLERRM) from 1 for 50);
        messaggioRisultato:=strMessaggioFinale||strMessaggio||'Errore DB '||SQLSTATE||' '||substring(upper(SQLERRM) from 1 for 50) ;
        codiceRisultato:=-1;
        faseBilElabRetId:=null;
        return;

END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;