/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac.fnc_trd_defaultBilancioGestione (
  annobilancio varchar,
  bilelemtipo varchar,
  enteproprietarioid integer,
  loginoperazione varchar,
  dataelaborazione timestamp,
  out codicerisultato integer,
  out messaggiorisultato varchar
)
RETURNS record AS
$body$
DECLARE
	strMessaggio VARCHAR(1500):='';
	strMessaggioFinale VARCHAR(1500):='';
    bilancioId integer := null;

    cursorCofog record;
    cursorRicorrente record;

	-- classificatori spesa
	CL_COFOG 			  CONSTANT varchar :='GRUPPO_COFOG';
	CL_RICORRENTE_SPESA CONSTANT varchar:='RICORRENTE_SPESA';
    CL_RICORRENTE_SPESA_RICORR CONSTANT varchar:= '3'; -- val RICORRENTE
    cl_ricorrenteSpesa varchar := '4'; --Il valore di default impostato per RICORRENRE è 'NON RICORRENTE' potrebbe cambiare se macro = 1 e titolo = 1
	CL_TRANSAZIONE_UE_SPESA CONSTANT varchar:='TRANSAZIONE_UE_SPESA';
    CL_TRANSAZIONE_UE_SPESA_DEF CONSTANT varchar:= '8' ;
    CL_FAMIGLIA_SPESA   CONSTANT varchar :='Spesa - TitoliMacroaggregati';
	CL_TITOLO_SPESA     CONSTANT varchar :='TITOLO_SPESA';
    CL_MACROAGGREGATO CONSTANT varchar := 'MACROAGGREGATO';
	CL_PROGRAMMA CONSTANT varchar := 'PROGRAMMA';

    -- classificatori entrata
    CL_TRANSAZIONE_UE_ENTRATA CONSTANT varchar:='TRANSAZIONE_UE_ENTRATA';
    CL_TRANSAZIONE_UE_ENTRATA_DEF CONSTANT varchar:= '2' ;
  	CL_RICORRENTE_ENTRATA CONSTANT varchar:='RICORRENTE_ENTRATA';
    CL_RICORRENTE_ENTRATA_RICORR CONSTANT varchar:= '1';
    cl_ricorrenteEntrata varchar := '2';-- Il Valore di Defualt impostato è NON RICORRENTE.
    CL_FAMIGLIA_ENTRATA   CONSTANT varchar :='Entrata - TitoliTipologieCategorie';
	CL_CATEGORIA   CONSTANT varchar :='CATEGORIA';
	CL_TIPOLOGIA   CONSTANT varchar :='TIPOLOGIA';
	CL_TITOLO_ENTRATA  CONSTANT varchar :='TITOLO_ENTRATA';

    bilElemTipoId integer := null;
    tipoClassMacroaggregatoId integer := null;
    tipoClassTitoloId integer := null;
    tipoClassTransazioneUEId integer := null;
    tipoClassProgrammaId integer := null;
    tipoClassCofogId integer := null;
    tipoClassRicorrenteId integer := null;
    tipoClassCategoriaId  integer := null;
    tipoClassTipologiaId  integer := null;
    tipoClassTitEntrataId  integer := null;

    classMacroaggregatoId integer := null;
    classifFamigliaId integer := null;
    classTitoloCode varchar :=null;
    classRicorrenteDefId integer := null; -- valore di default, non ricorrente
    classRicorrenteRicId integer := null; -- valore ricorrente
    classRicorrenteId integer := null; -- class roicorrente spesa usato
    classProgrammaId integer := null;

    classCategoriaId integer := null;

BEGIN

	strMessaggioFinale:='Set default per elementi  '||bilElemTipo||'. Anno '||annoBilancio||'.';


    strMessaggio := 'Recupero id bilancio per anno '||annoBilancio||', ente '||enteproprietarioid||'.';
    select idbilancio into strict bilancioId from fnc_get_bilancio(enteproprietarioid,annoBilancio);

	strMessaggio := 'Lettura id elem_tipo '||bilelemtipo||'.';
    select elem_tipo_id into strict bilElemTipoId
	from siac_d_bil_elem_tipo
	where elem_tipo_code=bilElemTipo and
	      ente_proprietario_id=enteProprietarioId and
          data_cancellazione is null and
          date_trunc('day',dataElaborazione)>=date_trunc('day',validita_inizio) and
          (date_trunc('day',dataElaborazione)<date_trunc('day',validita_fine)
            or validita_fine is null);

	if bilelemtipo = 'CAP-UG' or bilelemtipo = 'CAP-UP' then

        strMessaggio := 'Lettura tipo classificatore '||CL_MACROAGGREGATO||'.';
        Select d.classif_tipo_id into strict tipoClassMacroaggregatoId
        from siac_d_class_tipo d
        where d.ente_proprietario_id=enteproprietarioid
        and d.classif_tipo_code=CL_MACROAGGREGATO
        and d.data_cancellazione is null;

        strMessaggio := 'Lettura id per famiglia '||CL_FAMIGLIA_SPESA||'.';
        select classif_fam_tree_id into strict classifFamigliaId
        from  siac_t_class_fam_tree
        where ente_proprietario_id =enteProprietarioId
            and class_fam_desc= CL_FAMIGLIA_SPESA
            and validita_fine is null;

        strMessaggio := 'Lettura tipo classificatore '||CL_TITOLO_SPESA||'.';
        select classif_tipo_id into strict tipoClassTitoloId
        from siac_d_class_tipo
        where ente_proprietario_id =enteProprietarioId
            and validita_fine is null
            and classif_tipo_code = CL_TITOLO_SPESA;

        strMessaggio := 'Lettura tipo classificatore '||CL_RICORRENTE_SPESA||'.';
        select classif_tipo_id into strict tipoClassRicorrenteId
        from siac_d_class_tipo
        where ente_proprietario_id =enteProprietarioId
            and validita_fine is null
            and classif_tipo_code = CL_RICORRENTE_SPESA;

        strMessaggio := 'Lettura classificatore '||CL_RICORRENTE_SPESA||', val default '||cl_ricorrenteSpesa||'.';
        select classif_id into strict classRicorrenteDefId
        from siac_t_class c
        where c.ente_proprietario_id =enteProprietarioId
            and c.validita_fine is null
            and c.classif_tipo_id = tipoClassRicorrenteId
            and c.classif_code = cl_ricorrenteSpesa; -- valore di default;

        strMessaggio := 'Lettura classificatore '||CL_RICORRENTE_SPESA||', val '||CL_RICORRENTE_SPESA_RICORR||'.';
        select classif_id into strict classRicorrenteRicId
        from siac_t_class c
        where c.ente_proprietario_id =enteProprietarioId
            and c.validita_fine is null
            and c.classif_tipo_id = tipoClassRicorrenteId
            and c.classif_code = CL_RICORRENTE_SPESA_RICORR;

        strMessaggio := 'Lettura tipo classificatore '||CL_TRANSAZIONE_UE_SPESA||'.';
        select classif_tipo_id into strict tipoClassTransazioneUEId
        from siac_d_class_tipo
        where ente_proprietario_id =enteProprietarioId
            and validita_fine is null
            and classif_tipo_code = CL_TRANSAZIONE_UE_SPESA;

        strMessaggio := 'Lettura tipo classificatore '||CL_PROGRAMMA||'.';
        select classif_tipo_id into strict tipoClassProgrammaId
        from siac_d_class_tipo
        where ente_proprietario_id =enteProprietarioId
            and validita_fine is null
            and classif_tipo_code = CL_PROGRAMMA;

        strMessaggio := 'Lettura tipo classificatore '||CL_COFOG||'.';
        select classif_tipo_id into strict tipoClassCofogId
        from siac_d_class_tipo
        where ente_proprietario_id =enteProprietarioId
            and validita_fine is null
            and classif_tipo_code = CL_COFOG;

		strMessaggio := 'Set Default per classificatore '|| CL_COFOG || '.';
        for cursorCofog  in
         (SELECT el.elem_id
          from
          siac_t_bil_elem el
          where el.elem_id not in
          (select r.elem_id from
          siac_r_bil_elem_class r, siac_t_class c
          where r.ente_proprietario_id = enteProprietarioId
          and r.classif_id = c.classif_id
          and c.classif_tipo_id=tipoClassCofogId
          and r.data_cancellazione is null)
          and el.data_cancellazione is null
          and el.ente_proprietario_id = enteProprietarioId
          and el.elem_tipo_id=bilElemTipoId
          and el.bil_id = bilancioId)

        loop

        	classProgrammaId := null;

            strMessaggio:='Lettura programma per capitolo id '||cursorCofog.elem_id||'.';
        	-- impostare primo cofog partendo dal programma del capitolo
            select r.classif_id into classProgrammaId
            from siac_r_bil_elem_class r, siac_t_class c
            where r.elem_id = cursorCofog.elem_id
            and r.data_cancellazione is null
            and r.classif_id = c.classif_id
            and c.classif_tipo_id = tipoClassProgrammaId;

			if classProgrammaId is not null then
				strMessaggio:='Lettura primo cofog per programma id= '||classProgrammaId||'.';

				insert into siac_r_bil_elem_class
                (elem_id,classif_id, validita_inizio, ente_proprietario_id,data_creazione,login_operazione)
                (select cursorCofog.elem_id,classCofog.classif_id, date_trunc('DAY',now()), enteProprietarioid ,statement_timestamp(),loginOperazione
                 from siac_r_class r, siac_t_class classCofog
                  where r.ente_proprietario_id=enteProprietarioid
                  and   r.data_cancellazione is null
                  and   date_trunc('day',dataElaborazione)>=date_trunc('day',r.validita_inizio)
                  and   (date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(r.validita_fine,statement_timestamp())))
                  and   r.classif_a_id=classProgrammaId
                  and   classCofog.classif_id=r.classif_b_id
                  and   classCofog.data_cancellazione is null
                  and   date_trunc('day',dataElaborazione)>=date_trunc('day',classCofog.validita_inizio)
                  and   (date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(classCofog.validita_fine,statement_timestamp())))
                  and   classCofog.classif_tipo_id=tipoClassCofogId
                  order by  classCofog.classif_code limit 1);
             end if;
        end loop;

    	strMessaggio := 'Set Default per classificatore '|| CL_RICORRENTE_SPESA || '.';
        for cursorRicorrente in
         (
          SELECT el.elem_id
          from
          siac_t_bil_elem el
          where el.elem_id not in
          (select r.elem_id from
          siac_r_bil_elem_class r, siac_t_class c
          where r.ente_proprietario_id = enteProprietarioId
          and r.classif_id = c.classif_id
          and c.classif_tipo_id = tipoClassRicorrenteId
          and r.data_cancellazione is null)
          and el.data_cancellazione is null
          and el.ente_proprietario_id = enteProprietarioId
          and el.elem_tipo_id=bilElemTipoId
          and el.bil_id = bilancioId)
        loop

          classMacroaggregatoId := null;
          classTitoloCode := null;
          classRicorrenteId := classRicorrenteDefId; -- ad ogni ciclo è reimpostato quello di default

          strMessaggio:='Lettura macroaggregato per capitolo id '||cursorRicorrente.elem_id||'.';

          select r.classif_id into classMacroaggregatoId
          from siac_r_bil_elem_class r , siac_t_class c
          where r.elem_id = cursorRicorrente.elem_id
          and r.data_cancellazione is null
          and r.classif_id = c.classif_id
          and c.classif_tipo_id = tipoClassMacroaggregatoId;

          if classMacroaggregatoId is not null then

          	strMessaggio:='Lettura titolo code per capitolo id '||cursorRicorrente.elem_id||'.';
             select  cp.classif_code
             	into classTitoloCode
			 from
			 	siac_t_class cf,
			 	siac_r_class_fam_tree r,
			 	siac_t_class cp
			 where
			          cf.classif_id=classMacroaggregatoId
				and   cf.data_cancellazione is null
				and   cf.validita_fine is null
				and   r.classif_id=cf.classif_id
				and   r.classif_id_padre is not null
				and   r.classif_fam_tree_id=classifFamigliaId -- famiglia
				and   r.data_cancellazione is null
				and   r.validita_fine is null
				and   cp.classif_id=r.classif_id_padre
				and   cp.data_cancellazione is null
				and   cp.validita_fine is null
				and   cp.classif_tipo_id=tipoClassTitoloId ;-- titolo_spesa

			  -- se titolo code != 1 usato ricorrente di default
              if classTitoloCode = '1' then
              	classRicorrenteId := classRicorrenteRicId;
              end if;
          end if;

          strMessaggio:='Inserimento relazione classif='||CL_RICORRENTE_SPESA||' elem_id='||cursorRicorrente.elem_id||'.';

          insert into siac_r_bil_elem_class
          (elem_id,classif_id, validita_inizio, ente_proprietario_id,
           data_creazione,login_operazione)
          values
          (cursorRicorrente.elem_id, classRicorrenteId,date_trunc('DAY', now()),enteProprietarioId,statement_timestamp(),loginOperazione);

        end loop;

    	strMessaggio := 'Set Default per classificatore '|| CL_TRANSAZIONE_UE_SPESA || '.';
        insert into siac_r_bil_elem_class
        (elem_id,classif_id, validita_inizio, ente_proprietario_id,data_creazione,login_operazione)
        (SELECT el.elem_id, c1.classif_id, date_trunc('DAY',now()),enteProprietarioId, statement_timestamp(), loginOperazione
          from
          siac_t_bil_elem el ,siac_t_class c1
          where el.elem_id not in
            (select r.elem_id from
            siac_r_bil_elem_class r, siac_t_class c
            where r.ente_proprietario_id = enteProprietarioId
            and r.classif_id = c.classif_id
            and c.classif_tipo_id=tipoClassTransazioneUEId
            and r.data_cancellazione is null)
          and el.data_cancellazione is null
          and el.ente_proprietario_id = enteProprietarioId
          and el.elem_tipo_id=bilElemTipoId
          and el.bil_id = bilancioId
          and c1.classif_tipo_id=tipoClassTransazioneUEId
          and c1.classif_code=CL_TRANSAZIONE_UE_SPESA_DEF);

    elsif bilelemtipo = 'CAP-EG' or bilelemtipo = 'CAP-EP' then

        strMessaggio := 'Lettura tipo classificatore '||CL_RICORRENTE_ENTRATA||'.';
        select classif_tipo_id into strict tipoClassRicorrenteId
        from siac_d_class_tipo
        where ente_proprietario_id =enteProprietarioId
            and validita_fine is null
            and classif_tipo_code = CL_RICORRENTE_ENTRATA;

        strMessaggio := 'Lettura classificatore '||CL_RICORRENTE_ENTRATA||', val default '||cl_ricorrenteEntrata||'.';
        select classif_id into strict classRicorrenteDefId
        from siac_t_class c
        where c.ente_proprietario_id =enteProprietarioId
            and c.validita_fine is null
            and c.classif_tipo_id = tipoClassRicorrenteId
            and c.classif_code = cl_ricorrenteEntrata; -- valore di default;

        strMessaggio := 'Lettura classificatore '||CL_RICORRENTE_ENTRATA||', val '||CL_RICORRENTE_ENTRATA_RICORR||'.';
        select classif_id into strict classRicorrenteRicId
        from siac_t_class c
        where c.ente_proprietario_id =enteProprietarioId
            and c.validita_fine is null
            and c.classif_tipo_id = tipoClassRicorrenteId
            and c.classif_code = CL_RICORRENTE_ENTRATA_RICORR;

        strMessaggio := 'Lettura tipo classificatore '||CL_TRANSAZIONE_UE_ENTRATA||'.';
        select classif_tipo_id into strict tipoClassTransazioneUEId
        from siac_d_class_tipo
        where ente_proprietario_id =enteProprietarioId
            and validita_fine is null
            and classif_tipo_code = CL_TRANSAZIONE_UE_ENTRATA;

        strMessaggio := 'Lettura famiglia '||CL_FAMIGLIA_ENTRATA||'.';
        select classif_fam_tree_id
            into strict classifFamigliaId
        from  siac_t_class_fam_tree
        where ente_proprietario_id =enteProprietarioId
            and class_fam_desc= CL_FAMIGLIA_ENTRATA
            and validita_fine is null;

        strMessaggio := 'Lettura tipo classificatore '||CL_CATEGORIA||'.';
        select classif_tipo_id into strict tipoClassCategoriaId
        from siac_d_class_tipo
        where ente_proprietario_id =enteProprietarioId
            and validita_fine is null
            and classif_tipo_code =CL_CATEGORIA;

        strMessaggio := 'Lettura tipo classificatore '||CL_TIPOLOGIA||'.';
        select classif_tipo_id into strict tipoClassTipologiaId
        from siac_d_class_tipo
        where ente_proprietario_id =enteProprietarioId
            and validita_fine is null
            and classif_tipo_code =CL_TIPOLOGIA;

        strMessaggio := 'Lettura tipo classificatore '||CL_TITOLO_ENTRATA||'.';
        select classif_tipo_id into strict tipoClassTitEntrataId
        from siac_d_class_tipo
        where ente_proprietario_id =enteProprietarioId
            and validita_fine is null
            and classif_tipo_code = CL_TITOLO_ENTRATA;

		strMessaggio := 'Set Default per classificatore '|| CL_RICORRENTE_ENTRATA || '.';
		for cursorRicorrente in
         (
          SELECT el.elem_id
          from
          siac_t_bil_elem el
          where el.elem_id not in
          (select r.elem_id from
          siac_r_bil_elem_class r, siac_t_class c
          where r.ente_proprietario_id = enteProprietarioId
          and r.classif_id = c.classif_id
          and c.classif_tipo_id = tipoClassRicorrenteId
          and r.data_cancellazione is null)
          and el.data_cancellazione is null
          and el.ente_proprietario_id = enteProprietarioId
          and el.elem_tipo_id=bilElemTipoId
          and el.bil_id = bilancioId)
        loop
        	classCategoriaId := null;
            classTitoloCode := null;
        	classRicorrenteId := classRicorrenteDefId; -- ad ogni ciclo è reimpostato quello di default

            strMessaggio:='Lettura categoria per capitolo id '||cursorRicorrente.elem_id||'.';

            select r.classif_id into classCategoriaId
            from siac_r_bil_elem_class r , siac_t_class c
            where r.elem_id = cursorRicorrente.elem_id
            and r.data_cancellazione is null
            and r.classif_id = c.classif_id
            and c.classif_tipo_id = tipoClassCategoriaId;

            if classCategoriaId is not null then
              with
                tipologia as
                ( select cp.classif_id
                  from  siac_t_class cf, siac_r_class_fam_tree r, siac_t_class cp
                  where
                     cf.classif_id=classCategoriaId
                    and   cf.data_cancellazione is null
                    and   cf.validita_fine is null
                    and   r.classif_id=cf.classif_id
                    and   r.classif_id_padre is not null
                    and   r.classif_fam_tree_id=classifFamigliaId
                    and   r.data_cancellazione is null
                    and   r.validita_fine is null
                    and   cp.classif_id=r.classif_id_padre
                    and   cp.data_cancellazione is null
                    and   cp.validita_fine is null
                    and   cp.classif_tipo_id=tipoClassTipologiaId
                 )
                 select  cp.classif_code into classTitoloCode
                 from  siac_t_class cf, siac_r_class_fam_tree r, siac_t_class cp, tipologia
                 where
                     cf.classif_id=tipologia.classif_id
                    and   cf.data_cancellazione is null
                    and   cf.validita_fine is null
                    and   cf.classif_tipo_id= tipoClassTipologiaId
                    and   r.classif_id=cf.classif_id
                    and   r.classif_id_padre is not null
                    and   r.classif_fam_tree_id=classifFamigliaId
                    and   r.data_cancellazione is null
                    and   r.validita_fine is null
                    and   cp.classif_id=r.classif_id_padre
                    and   cp.data_cancellazione is null
                    and   cp.validita_fine is null
                    and   cp.classif_tipo_id=tipoClassTitEntrataId; -- titolo_entrata

              if classTitoloCode = '1' then
                classRicorrenteId := classRicorrenteRicId;
              end if;
            end if;
            strMessaggio:='Inserimento relazione classif='||CL_RICORRENTE_ENTRATA||' elem_id='||cursorRicorrente.elem_id||'.';

            insert into siac_r_bil_elem_class
            (elem_id,classif_id, validita_inizio, ente_proprietario_id,
             data_creazione,login_operazione)
            values
            (cursorRicorrente.elem_id, classRicorrenteId,date_trunc('DAY', now()),enteProprietarioId,statement_timestamp(),loginOperazione);

        end loop;

		strMessaggio := 'Set Default per classificatore '|| CL_TRANSAZIONE_UE_ENTRATA || '.';
        insert into siac_r_bil_elem_class
        (elem_id,classif_id, validita_inizio, ente_proprietario_id,data_creazione,login_operazione)
        (SELECT el.elem_id, c1.classif_id, date_trunc('DAY',now()),enteProprietarioId, statement_timestamp(), loginOperazione
          from
          siac_t_bil_elem el ,siac_t_class c1
          where el.elem_id not in
            (select r.elem_id from
            siac_r_bil_elem_class r, siac_t_class c
            where r.ente_proprietario_id = enteProprietarioId
            and r.classif_id = c.classif_id
            and c.classif_tipo_id=tipoClassTransazioneUEId
            and r.data_cancellazione is null)
          and el.data_cancellazione is null
          and el.ente_proprietario_id = enteProprietarioId
          and el.elem_tipo_id = bilElemTipoId
          and el.bil_id = bilancioId
          and c1.classif_tipo_id=tipoClassTransazioneUEId
          and c1.classif_code=CL_TRANSAZIONE_UE_ENTRATA_DEF);
    else
    	messaggiorisultato := strMessaggioFinale || 'Tipo capitolo non gestito nella funzione.';
	    codiceRisultato := -1;
        return;
    end if;

    messaggiorisultato := strMessaggioFinale ||'Ok.';
    codiceRisultato := 0;

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