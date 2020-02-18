/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
﻿-- Davide - 04.01.2016 - Funzione per l'aggiornamento del SIOPE per la nuova gestione

CREATE OR REPLACE FUNCTION fnc_siac_aggiorna_siope_nuova_gestione (
  annobilancio integer,
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

    SIOPENEW             CONSTANT varchar:='YYYY';
	
	SIOPE_ENTRATA_I      CONSTANT varchar:='SIOPE_ENTRATA_I';
	SIOPE_SPESA_I        CONSTANT varchar:='SIOPE_SPESA_I';

    CAPITOLO_EP          CONSTANT varchar:='CAP-EP';
    CAPITOLO_UP          CONSTANT varchar:='CAP-UP';
    CAPITOLO_EG          CONSTANT varchar:='CAP-EG';
    CAPITOLO_UG          CONSTANT varchar:='CAP-UG';
    IMPEGNO              CONSTANT varchar:='I';
    ACCERTAMENTO         CONSTANT varchar:='A';
	
    codResult            integer:=null;
    --dataInizioVal      timestamp:=null;

    bilancioId           integer:=null;
    periodoId            integer:=null;

    -- Id tipi 
	IdCapitoloEP        integer :=null;
	IdCapitoloUP        integer :=null;
	IdCapitoloEG        integer :=null;
	IdCapitoloUG        integer :=null;
	IdAccertamento      integer :=null;
	IdImpegno           integer :=null;	
    IdTipoSiope         integer :=null;
    IdTipoSiopeEntrata  integer :=null;
    IdTipoSiopeSpesa    integer :=null;
	
    IdClassifSiopeNew   integer :=null;
    IdClassifSiopeENew  integer :=null;
    IdClassifSiopeSNew  integer :=null;

	Capitoli             record;
	Movimenti            record;
	Liquidazioni         record;

BEGIN

    messaggioRisultato:='';
    codiceRisultato:=0;

    --dataInizioVal:=clock_timestamp();-- usato al posto di now() per essere certi di riconoscere i record inseriti dopo la chiamata della funzione;

	strMessaggioFinale:='Aggiornamento SIOPE per Capitoli, Movimenti Gestione e Liquidazioni per Anno bilancio='||annoBilancio::varchar||'.';

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

	strMessaggio:='Lettura IdMovimento  per tipo='||ACCERTAMENTO||'.';
	select tipo.movgest_tipo_id into strict IdAccertamento
    from siac_d_movgest_tipo tipo
    where tipo.movgest_tipo_code=ACCERTAMENTO
    and   tipo.ente_proprietario_id=enteProprietarioId
    and   tipo.data_cancellazione is null
    and   date_trunc('day',dataElaborazione)>=date_trunc('day',tipo.validita_inizio)
    and   ( date_trunc('day',dataElaborazione)<=date_trunc('day',tipo.validita_fine) or tipo.validita_fine is null);

	strMessaggio:='Lettura IdMovimento  per tipo='||IMPEGNO||'.';
	select tipo.movgest_tipo_id into strict IdImpegno
    from siac_d_movgest_tipo tipo
    where tipo.movgest_tipo_code=IMPEGNO
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
	   
  	strMessaggio:='Lettura IdTipiSiope Entrata e Spesa per annoBilancio='||annoBilancio::varchar||'.';
    select tipo.classif_tipo_id  into strict IdTipoSiopeEntrata
      from siac_d_class_tipo tipo
     where tipo.ente_proprietario_id=enteProprietarioId
       and tipo.classif_tipo_code in (SIOPE_ENTRATA_I)
       and tipo.validita_fine is null;

    select tipo.classif_tipo_id  into strict IdTipoSiopeSpesa
      from siac_d_class_tipo tipo
     where tipo.ente_proprietario_id=enteProprietarioId
       and tipo.classif_tipo_code in (SIOPE_SPESA_I)
       and tipo.validita_fine is null;       
	   
  	strMessaggio:='Lettura IdSIOPE sostituti per annoBilancio='||annoBilancio::varchar||'.';
    select c.classif_id  into strict IdClassifSiopeENew
      from siac_t_class c , siac_d_class_tipo tipo
     where tipo.ente_proprietario_id=enteProprietarioId
       and tipo.classif_tipo_code in (SIOPE_ENTRATA_I)	      
	   and c.classif_code=SIOPENEW
       and   c.classif_tipo_id=tipo.classif_tipo_id
       and c.validita_fine is null;

	select c.classif_id  into strict IdClassifSiopeSNew
      from siac_t_class c , siac_d_class_tipo tipo
     where tipo.ente_proprietario_id=enteProprietarioId
       and tipo.classif_tipo_code in (SIOPE_SPESA_I)	   	      
	   and c.classif_code=SIOPENEW
       and   c.classif_tipo_id=tipo.classif_tipo_id
       and c.validita_fine is null;	

    -- Ciclo sui Capitoli per un determinato anno bilancio
    for Capitoli IN
        (select capi.elem_id, capi.elem_tipo_id, capi.elem_code, capi.elem_code2, capi.elem_code3, capi.elem_desc, capi.elem_desc2
   		    from siac_t_bil_elem capi
		   where capi.ente_proprietario_id=enteProprietarioId
		     and capi.bil_id=bilancioId
           order by capi.elem_code::integer,capi.elem_code2::integer,capi.elem_code3) loop

        strMessaggio:='Aggiornamento SIOPE per il capitolo '||Capitoli.elem_code||'/'||Capitoli.elem_code2||'/'||Capitoli.elem_code3||'.';

	    BEGIN
		    if Capitoli.elem_tipo_id in (IdCapitoloEP,IdCapitoloEG)	then

                IdTipoSiope       := IdTipoSiopeEntrata;
			    IdClassifSiopeNew := IdClassifSiopeENew;
			 
			else
			    
                IdTipoSiope       := IdTipoSiopeSpesa;
			    IdClassifSiopeNew := IdClassifSiopeSNew;
				
            end if;			
				
            update siac_r_bil_elem_class ClassifSIOPE
			   set classif_id = IdClassifSiopeNew
             where ClassifSIOPE.ente_proprietario_id=enteProprietarioId
			   and ClassifSIOPE.elem_id=Capitoli.elem_id
               and ClassifSIOPE.classif_id in (select l.classif_id 
                                                 from siac_t_class l, siac_d_class_tipo m
                                                where l.ente_proprietario_id=ClassifSIOPE.ente_proprietario_id
                                                  and m.ente_proprietario_id=l.ente_proprietario_id
                                                  and l.classif_tipo_id=IdTipoSiope
                                                  and m.classif_tipo_id=l.classif_tipo_id
                                                  and l.classif_code not in (SIOPENEW));
				   
        EXCEPTION
	        WHEN OTHERS THEN
                RAISE EXCEPTION 'Errore nell''aggiornamento classificatore SIOPE del capitolo %', Capitoli.elem_code||'/'||Capitoli.elem_code2||'/'||Capitoli.elem_code3;
        END;
    end loop;

    -- Ciclo sui Movimenti di Gestione per un determinato anno bilancio
    for Movimenti IN
        ( select tmovi.movgest_tipo_desc, movi.movgest_tipo_id, movits.movgest_ts_id, movi.movgest_anno, movi.movgest_numero
   		    from siac_t_movgest movi, siac_t_movgest_ts movits, siac_d_movgest_tipo tmovi
		   where movi.ente_proprietario_id=enteProprietarioId
		     and movi.bil_id=bilancioId
			 and tmovi.ente_proprietario_id=movi.ente_proprietario_id
			 and tmovi.movgest_tipo_id=movi.movgest_tipo_id
			 and movits.movgest_id=movi.movgest_id
           order by movi.movgest_anno::integer,movi.movgest_numero::integer) loop

        strMessaggio:='Aggiornamento SIOPE per il movimento '||Movimenti.movgest_tipo_desc||': '||Movimenti.movgest_anno||'/'||Movimenti.movgest_numero||'.';
		
	    BEGIN
		    if Movimenti.movgest_tipo_id in (IdAccertamento) then

                IdTipoSiope       := IdTipoSiopeEntrata;
			    IdClassifSiopeNew := IdClassifSiopeENew;
			 
			else
			    
                IdTipoSiope       := IdTipoSiopeSpesa;
			    IdClassifSiopeNew := IdClassifSiopeSNew;
				
            end if;			

            /* cancellazione logica classificatore SIOPE vecchio e inserimento del nuovo 

                update siac_r_movgest_class ClassifSIOPE
			       set data_cancellazione = dataelaborazione,
			           validita_fine      = dataelaborazione
                 where ClassifSIOPE.ente_proprietario_id=enteProprietarioId
				   and ClassifSIOPE.movgest_ts_id=Movimenti.movgest_ts_id
				   and ClassifSIOPE.classif_id=IdClassifSiopeOld;	
				   
                INSERT INTO siac_r_movgest_class (
                 movgest_ts_id,
                 classif_id,
                 validita_inizio,
                 ente_proprietario_id,
                 login_operazione
                )
                VALUES (
                 Movimenti.movgest_ts_id,
                 IdClassifSiopeNew,
                 dataelaborazione,
                 enteProprietarioId,
                 loginoperazione
                );
				   
		    */
			
			update siac_r_movgest_class ClassifSIOPE
			       set classif_id = IdClassifSiopeNew
                 where ClassifSIOPE.ente_proprietario_id=enteProprietarioId
				   and ClassifSIOPE.movgest_ts_id=Movimenti.movgest_ts_id
                   and ClassifSIOPE.classif_id in (select l.classif_id 
                                                     from siac_t_class l, siac_d_class_tipo m
                                                    where l.ente_proprietario_id=ClassifSIOPE.ente_proprietario_id
                                                      and m.ente_proprietario_id=l.ente_proprietario_id
                                                      and l.classif_tipo_id=IdTipoSiope
                                                      and m.classif_tipo_id=l.classif_tipo_id
                                                      and l.classif_code not in (SIOPENEW));
				   
        EXCEPTION
	        WHEN OTHERS THEN
                RAISE EXCEPTION 'Errore nell''aggiornamento classificatore SIOPE del movimento % ', Movimenti.movgest_tipo_desc||': '||Movimenti.movgest_anno||'/'||Movimenti.movgest_numero;
        END;
    end loop;

    -- Ciclo sulle Liquidazioni per un determinato anno bilancio
    for Liquidazioni IN
        ( select liqui.liq_id, liqui.liq_anno, liqui.liq_numero
   		    from siac_t_liquidazione liqui
		   where liqui.ente_proprietario_id=enteProprietarioId
		     and liqui.bil_id=bilancioId
           order by liqui.liq_anno, liqui.liq_numero) loop

        strMessaggio:='Aggiornamento SIOPE per la liquidazione '||Liquidazioni.liq_anno||'/'||Liquidazioni.liq_numero||'.';

	    BEGIN		

            /* cancellazione logica classificatore SIOPE vecchio e inserimento del nuovo 

                update siac_r_liquidazione_class ClassifSIOPE
			       set data_cancellazione = dataelaborazione,
			           validita_fine      = dataelaborazione
                 where ClassifSIOPE.ente_proprietario_id=enteProprietarioId
			       and ClassifSIOPE.liq_id=Liquidazioni.liq_id
			       and ClassifSIOPE.classif_id=IdClassifSiopeSOld;	
				   
                INSERT INTO siac_r_liquidazione_class (	
                 liq_id,
                 classif_id,
                 validita_inizio,
                 ente_proprietario_id,
                 login_operazione
                )
                VALUES (
                 Liquidazioni.liq_id,
                 IdClassifSiopeSNew,
                 dataelaborazione,
                 enteProprietarioId,
                 loginoperazione
                );
				   
		    */
			
            update siac_r_liquidazione_class ClassifSIOPE
			   set classif_id = IdClassifSiopeSNew
             where ClassifSIOPE.ente_proprietario_id=enteProprietarioId
			   and ClassifSIOPE.liq_id=Liquidazioni.liq_id
               and ClassifSIOPE.classif_id in (select l.classif_id 
                                                from siac_t_class l, siac_d_class_tipo m
                                               where l.ente_proprietario_id=ClassifSIOPE.ente_proprietario_id
                                                 and m.ente_proprietario_id=l.ente_proprietario_id
                                                 and l.classif_tipo_id=IdTipoSiopeSpesa
                                                 and m.classif_tipo_id=l.classif_tipo_id
                                                 and l.classif_code not in (SIOPENEW));

        EXCEPTION
	        WHEN OTHERS THEN
                RAISE EXCEPTION 'Errore nell''aggiornamento classificatore SIOPE della liquidazione % ', Liquidazioni.liq_anno||'/'||Liquidazioni.liq_numero;
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
