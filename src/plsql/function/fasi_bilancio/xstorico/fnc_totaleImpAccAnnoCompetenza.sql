/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
﻿-- 17.02.2014 Sofia
-- Totalizzazione impegnato/accertato per anno di competenza
-- relativamente ad un bilancio
-- eventualmente relativamente a 
-- tutto il bilancio, nel caso in cui non sia trasmessi gli estremi di un capitolo
-- un capitolo dato il suo Id
-- un capitolo dati i suoi estremi logici
-- relativamente a un particolare anno di competenza o tutti nel caso in cui non sia trasmesso il parametro annoCompetenza
-- relativamente ad una serie di statioperativi
-- restituzione di una TABLE contenente i records trovati 
-- annoImpegno ( annoCompetenza )
-- totImpegnatoIniziale ( impegnato/accertato Iniziale )
-- totImpegnatoAttuale ( impegnato/accertato Attuale )
-- Elenco parametri
-- bilancioid  --> identificativo bilancio (OBB)
-- bilelemid   --> identificativo elemento bilancio ( capitolo)   ( FAC  alternativo agli estremi logici )
-- elemcode    --> codice elemento di bilancio ( numero capitolo) ( FAC  alternativo a Id fisico )
-- elemcode2   --> codice elemento di bilancio ( numero articolo) ( FAC  alternativo a Id fisico )
-- elemcode3   --> codice elemento di bilancio ( numero UEB )     ( FAC  alternativo a Id fisico ) 
-- tipoelembil --> tipoElemento di Bilancio ( CAP-UP,CAP-UG,CAP-EP,CAP-EG .. ) ( FAC  necessario se presenti estremi logici )
-- tipomovgest --> tipoMovimentoGestione ( I - impegno, A - accertamento ) ( OBB )
-- enteproprietarioid --> identificativo ente proprietario ( OBB )
-- annocompetenza     --> annoMovimento (impegno,accertamento) ( FAC necessario per la totalizzazione di un particolare anno di competenza )
-- statioperativi     --> elenco degli stati operativi relativamente ai movimenti gestine da estrarre per la totalizzazione Es. P,D ( OBB )
-- dataelaborazione   --> data riferimento per validità entità ( data sistema ) (OBB)
CREATE OR REPLACE FUNCTION fnc_totaleImpAccAnnoCompetenza (
  bilancioid integer,
  bilelemid integer,
  elemcode varchar,
  elemcode2 varchar,
  elemcode3 varchar,
  tipoelembil varchar,
  tipomovgest varchar,
  enteproprietarioid integer,
  annocompetenza varchar,
  statioperativi varchar,
  dataelaborazione timestamp
)
RETURNS TABLE (
  annoimpegno varchar,
  totimpegnatoiniziale numeric,
  totimpegnatoattuale numeric
) AS
$body$
DECLARE

importiImpegnoRec record;

--TIPO_MOVGEST_IMP CONSTANT  varchar :='I';
TIPO_MOVGEST_TS_IMP CONSTANT  varchar :='T';

TIPO_IMPORTO_INI CONSTANT  varchar :='I';
TIPO_IMPORTO_ATT CONSTANT  varchar :='A';

STATO_VALIDO CONSTANT  varchar :='VA';

bilElemIdForLoop integer:=0;

messaggioRisultato varchar(1500):='';

begin

  -- Inizializzo
  annoImpegno:=null;
  totImpegnatoIniziale:=0;
  totImpegnatoAttuale:=0;




  messaggioRisultato:='Lettura totale impegnato/accertato';
  raise notice '%', messaggioRisultato;

  if bilElemId is not null and bilElemId!=0  then
	  bilElemIdForLoop:=bilElemId;
  else
    if elemCode is not null and elemCode2 is not null and elemCode3 is not null then
        messaggioRisultato:='Lettura estremi elemento di bilancio tipo '||tipoElemUsc||' ' ||
                             elemCode||'/'||elemCode2||'/'||elemCode3||'.';
		raise notice '%', messaggioRisultato;
	    select capitolo.elem_id into  bilElemIdForLoop
    	from siac_t_bil_elem capitolo, siac_d_bil_elem_tipo tipoCapitolo,
             siac_r_bil_elem_stato statoCapitoloRel, siac_d_bil_elem_stato statoCapitolo
	    where capitolo.bil_id=bilancioId and
    	      capitolo.elem_code=elemCode and
        	  capitolo.elem_code2=elemCode2 and
	          capitolo.elem_code3=elemCode3 and
              capitolo.data_cancellazione is not null and
              date_trunc('seconds',dataElaborazione) >= date_trunc('seconds',capitolo.validita_inizio) and
	    	  (date_trunc('seconds',dataElaborazione) < date_trunc('seconds',capitolo.validita_fine)
      		  	 OR capitolo.validita_fine is null  ) and
              tipoCapitolo.elem_tipo_id=capitolo.elem_tipo_id and
              tipoCapitolo.elem_tipo_code=tipoElemBil and
              tipoCapitolo.ente_proprietario_id=enteProprietarioId and
              statoCapitoloRel.elem_id=capitolo.elem_id and
              statoCapitoloRel.elem_stato_id=statoCapitolo.elem_stato_id and
              statoCapitolo.elem_stato_code=STATO_VALIDO and
              statoCapitolo.ente_proprietario_id=enteProprietarioId and
              statoCapitoloRel.data_cancellazione is null and
              date_trunc('seconds',dataElaborazione) >= date_trunc('seconds',statoCapitoloRel.validita_inizio) and
	    	  (date_trunc('seconds',dataElaborazione) < date_trunc('seconds',statoCapitoloRel.validita_fine)
      		  	 OR statoCapitoloRel.validita_fine is null  );
    end if;
  end if;

  if bilElemIdForLoop!=0 then
    messaggioRisultato:= 'Lettura impegnato/accertato per  elemento di bilancio id='||bilElemIdForLoop||'.';
    raise notice '%', messaggioRisultato;
   for importiImpegnoRec in
	select  impegno.movgest_anno annoImpegno,
    		COALESCE(sum(case statoImpegno.movgest_stato_code
	 			      	  when TIPO_IMPORTO_INI then impegnoImporti.movgest_ts_det_importo
				          else 0  end ),0) importoIniziale,
		    COALESCE(sum(case statoImpegno.movgest_stato_code
					   	  when TIPO_IMPORTO_ATT then impegnoImporti.movgest_ts_det_importo
				          else 0 end ),0) importoAttuale
	from siac_t_movgest impegno, siac_d_movgest_tipo tipoMovimento,
    	 siac_t_movgest_ts impegnoTestata, siac_d_movgest_ts_tipo tipoImpTestata,
	     siac_r_movgest_ts_stato statoImpegnoRel,siac_d_movgest_stato statoImpegno,
    	 siac_t_movgest_ts_det impegnoImporti,siac_d_movgest_ts_det_tipo tipoImportiImpegno,
	     siac_t_bil_elem capitolo, siac_r_movgest_bil_elem capitoloImpegno
	where capitoloImpegno.elem_id = bilElemIdForLoop and
    	  capitoloImpegno.data_cancellazione is null and
	      date_trunc('seconds',dataElaborazione) >= date_trunc('seconds',capitoloImpegno.validita_inizio) and
    	  (date_trunc('seconds',dataElaborazione) < date_trunc('seconds',capitoloImpegno.validita_fine)
        	 OR capitoloImpegno.validita_fine is null  )  and
		  impegno.movgest_id = capitoloImpegno.movgest_id and
          impegno.data_cancellazione is null and
          date_trunc('seconds',dataElaborazione) >= date_trunc('seconds',impegno.validita_inizio) and
    	  (date_trunc('seconds',dataElaborazione) < date_trunc('seconds',impegno.validita_fine)
        	 OR impegno.validita_fine is null  )  and
		  ( annoCompetenza is null or impegno.movgest_anno=annoCompetenza ) and
    	  tipoMovimento.movgest_tipo_id=impegno.movgest_tipo_id and
	      tipoMovimento.movgest_tipo_code=tipoMovGest and
    	  impegnoTestata.movgest_id=impegno.movgest_id and
	      tipoImpTestata.movgest_ts_tipo_id=impegnoTestata.movgest_ts_tipo_id and
    	  tipoImpTestata.movgest_ts_tipo_code=TIPO_MOVGEST_TS_IMP and
		  statoImpegnoRel.movgest_ts_id=impegnoTestata.movgest_id and
	      statoImpegnoRel.movgest_stato_id=statoImpegno.movgest_stato_id and
	      position(statoImpegno.movgest_stato_code in statiOperativi )!=0 and
	      statoImpegnoRel.data_cancellazione is null and
	      date_trunc('seconds',dataElaborazione) >= date_trunc('seconds',statoImpegnoRel.validita_inizio) and
	      (date_trunc('seconds',dataElaborazione) < date_trunc('seconds',statoImpegnoRel.validita_fine)
	         OR statoImpegnoRel.validita_fine is null  )  and
	      impegnoImporti.movgest_ts_id=impegnoTestata.movgest_ts_id and
	      impegnoimporti.data_cancellazione is null and
	      date_trunc('seconds',dataElaborazione) >= date_trunc('seconds',impegnoImporti.validita_inizio) and
	      (date_trunc('seconds',dataElaborazione) < date_trunc('seconds',impegnoImporti.validita_fine)
    	     OR impegnoImporti.validita_fine is null  )  and
	      tipoImportiImpegno.movgest_ts_det_tipo_id=impegnoImporti.movgest_ts_det_id
     group by impegno.movgest_anno
    loop

    	annoImpegno := importiImpegnoRec.annoImpegno;
	    totImpegnatoIniziale := importiImpegnoRec.importoIniziale;
		totImpegnatoAttuale  := importiImpegnoRec.importoAttuale;

        return next;
    end loop;
  else
   messaggioRisultato:= 'Lettura impegnato/accertato per   bilancio id='||bilancioId||'.';
   raise notice '%', messaggioRisultato;
   for importiImpegnoRec in
 	select  impegno.movgest_anno annoImpegno,
    		COALESCE(sum(case statoImpegno.movgest_stato_code
	 			      	  when TIPO_IMPORTO_INI then impegnoImporti.movgest_ts_det_importo
				          else 0  end ),0) importoIniziale,
		    COALESCE(sum(case statoImpegno.movgest_stato_code
					   	  when TIPO_IMPORTO_ATT then impegnoImporti.movgest_ts_det_importo
				          else 0 end ),0) importoAttuale
	from siac_t_movgest impegno, siac_d_movgest_tipo tipoMovimento,
    	 siac_t_movgest_ts impegnoTestata, siac_d_movgest_ts_tipo tipoImpTestata,
	     siac_r_movgest_ts_stato statoImpegnoRel,siac_d_movgest_stato statoImpegno,
    	 siac_t_movgest_ts_det impegnoImporti,siac_d_movgest_ts_det_tipo tipoImportiImpegno,
	     siac_t_bil_elem capitolo, siac_r_movgest_bil_elem capitoloImpegno
	where impegno.bil_id=bilancioId and
		  ( annoCompetenza is null or impegno.movgest_anno=annoCompetenza ) and
          impegno.data_cancellazione is null and
          date_trunc('seconds',dataElaborazione) >= date_trunc('seconds',impegno.validita_inizio) and
    	  (date_trunc('seconds',dataElaborazione) < date_trunc('seconds',impegno.validita_fine)
        	 OR impegno.validita_fine is null  )  and
    	  tipoMovimento.movgest_tipo_id=impegno.movgest_tipo_id and
	      tipoMovimento.movgest_tipo_code=tipoMovGest and
    	  impegnoTestata.movgest_id=impegno.movgest_id and
	      tipoImpTestata.movgest_ts_tipo_id=impegnoTestata.movgest_ts_tipo_id and
    	  tipoImpTestata.movgest_ts_tipo_code=TIPO_MOVGEST_TS_IMP and
		  statoImpegnoRel.movgest_ts_id=impegnoTestata.movgest_id and
	      statoImpegnoRel.movgest_stato_id=statoImpegno.movgest_stato_id and
	      position(statoImpegno.movgest_stato_code in statiOperativi )!=0 and
	      statoImpegnoRel.data_cancellazione is null and
	      date_trunc('seconds',dataElaborazione) >= date_trunc('seconds',statoImpegnoRel.validita_inizio) and
	      (date_trunc('seconds',dataElaborazione) < date_trunc('seconds',statoImpegnoRel.validita_fine)
	         OR statoImpegnoRel.validita_fine is null  )  and
	      impegnoImporti.movgest_ts_id=impegnoTestata.movgest_ts_id and
	      impegnoimporti.data_cancellazione is null and
	      date_trunc('seconds',dataElaborazione) >= date_trunc('seconds',impegnoImporti.validita_inizio) and
	      (date_trunc('seconds',dataElaborazione) < date_trunc('seconds',impegnoImporti.validita_fine)
    	     OR impegnoImporti.validita_fine is null  )  and
	      tipoImportiImpegno.movgest_ts_det_tipo_id=impegnoImporti.movgest_ts_det_id
     group by impegno.movgest_anno
    loop

    	annoImpegno := importiImpegnoRec.annoImpegno;
	    totImpegnatoIniziale := importiImpegnoRec.importoIniziale;
		totImpegnatoAttuale  := importiImpegnoRec.importoAttuale;

        return next;
    end loop;
  end if;

  raise notice 'anno % importoiniz  % importoatt %',annoImpegno,totImpegnatoIniziale,totImpegnatoAttuale;
  raise notice '% OK.',messaggioRisultato;
 return;


exception
	when no_data_found THEN
	raise notice '%  Nessun elemento trovato.' ,messaggioRisultato;
	return;
	when others  THEN
    raise notice '%  Errore DB % %',messaggioRisultato,SQLSTATE,
	        	substring(upper(SQLERRM) from 1 for 50);
	return;
end;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100 ROWS 1000;
