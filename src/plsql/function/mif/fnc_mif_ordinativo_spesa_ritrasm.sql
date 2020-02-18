/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
*drop function fnc_mif_ordinativo_spesa_ritrasm (
  enteproprietarioid integer,
  nomeente varchar,
  annobilancio varchar,
  loginoperazione varchar,
  dataelaborazione timestamp,
  mifordritrasmelabid integer
);*/
-- 20.04.2016 Sofia - compilata in prod bilmult
-- 18.04.2016 Sofia - chiamata da funzione di back-office
-- 27.05.2016 Sofia - JIRA-3619
CREATE OR REPLACE FUNCTION fnc_mif_ordinativo_spesa_ritrasm
( enteProprietarioId integer,
  nomeEnte VARCHAR,
  annobilancio varchar,
  ordArray text,
  loginOperazione varchar,
  dataElaborazione timestamp)
RETURNS text AS
$body$
DECLARE


 strMessaggio VARCHAR(1500):='';
 strMessaggioFinale VARCHAR(1500):='';

 mifOrdinativoRec record;
 mifOrdRitrasmRec record;

 flussoElabMifId integer:=0;
 numeroOrdinativiTrasm integer:=0;
 flussoElabMifDistOilId integer:=0; -- 27.05.2016 Sofia - JIRA-3619

 nomeFileMif varchar:='NO_FILE';
 codiceRisultato integer:=0;
 messaggioRisultato varchar:='OK';
 generaXml varchar(10) :='false';
 ORD_CODE_TIPO_P CONSTANT  varchar :='P';

 messaggioResult text:=null;

BEGIN

  	strMessaggioFinale:='Invio ordinativi di spesa al MIF.';

    strMessaggio:='Popolamento tabella mif_t_ordinativo_ritrasmesso.';
    -- out mifOrdRitrasmElabId
    -- out mifOrdRitrasm
    -- out codiceRisultato
    -- out messaggioRisultato
    select *  into mifOrdRitrasmRec
    from fnc_mif_ordinativo_ritrasm(enteProprietarioId,loginOperazione,ORD_CODE_TIPO_P,ordArray);

    if mifOrdRitrasmRec.codiceRisultato!=0 then
	    messaggioRisultato:=mifOrdinativoRec.messaggioRisultato;
        codiceRisultato:=-1;
    end if;

    if codiceRisultato=0 and mifOrdRitrasmRec.mifOrdRitrasmElabId is null then
    	codiceRisultato:=-1;
        messaggioRisultato:=strMessaggioFinale||strMessaggio||' Identificativo elaborazione ritrasmissione non valido.';
    end if;

    if codiceRisultato=0 and coalesce(mifOrdRitrasmRec.mifOrdRitrasm,0)=0 then
        messaggioRisultato:=strMessaggioFinale||strMessaggio||' Nessun ordinativo presente in mif_t_ordinativo_ritrasmesso.';
    end if;

    if codiceRisultato=0 and coalesce(mifOrdRitrasmRec.mifOrdRitrasm,0)!=0 then
     strMessaggio:='Richiamo fnc_mif_ordinativo_spesa interno mifOrdRitrasmElabId='||mifOrdRitrasmRec.mifOrdRitrasmElabId||'.';
  	 select *  into mifOrdinativoRec
     from fnc_mif_ordinativo_spesa
          (enteProprietarioId,
	 	   nomeEnte,
		   annobilancio,
		   loginOperazione,
		   dataElaborazione,
           mifOrdRitrasmRec.mifOrdRitrasmElabId);

     if mifOrdinativoRec.codiceRisultato=0 then
         if mifOrdinativoRec.flussoElabMifId is null or mifOrdinativoRec.flussoElabMifId=0 then
	     	codiceRisultato:=-1;
            messaggioRisultato:=strMessaggioFinale||strMessaggio||' Identificativo elaborazione trasmissione non valido.';
         else
    	 	flussoElabMifId:=mifOrdinativoRec.flussoElabMifId;
          	numeroOrdinativiTrasm:=mifOrdinativoRec.numeroOrdinativiTrasm;
		  	nomeFileMif:=mifOrdinativoRec.nomeFileMif;
            -- 27.05.2016 Sofia - JIRA-3619
            flussoElabMifDistOilId:=mifOrdinativoRec.flussoElabMifDistOilId;
         end if;
     else
     	 codiceRisultato:=-1;
         messaggioRisultato:=mifOrdinativoRec.messaggioRisultato;
     end if;
    end if;

	if codiceRisultato=0 and coalesce(numeroOrdinativiTrasm,0)!=0 then
        strMessaggio:='Lettura dati ente OIL per generaXml.';
    	select ( case when ente_oil_genera_xml=true then 'true' else 'false' end) into generaXml
        from siac_t_ente_oil
        where ente_proprietario_id=enteProprietarioId;

        if generaXml is null then
        	raise exception ' Errore in lettura.';
        end if;
    end if;

    messaggioResult   :='codiceRes='||coalesce(codiceRisultato,-1)::varchar||'|'||
						'flussoElabMifDistOilId='||coalesce(flussoElabMifDistOilId,0)::varchar||'|'||    -- 27.05.2016 Sofia - JIRA-3619
                        'flussoElabMifId='||coalesce(flussoElabMifId,0)::varchar||'|'||
                        'generaXml='||generaXml||'|'||
                        'numOrdTrasm='||coalesce(numeroOrdinativiTrasm,0)::varchar||'|'||
                        'nomeFileMif='||coalesce(nomeFileMif,'NO_FILE')||'|'||
                        'messaggioRes='||coalesce(messaggioRisultato,'');



    return messaggioResult;


exception
	when others  THEN
    	messaggioRisultato:=
        strMessaggioFinale||' '||coalesce(strMessaggio,'')||' '||coalesce(substring(upper(SQLERRM) from 1 for 500),'')||'.' ;
	    messaggioRisultato:=upper(messaggioRisultato);
        messaggioResult:='codiceRes=-1'||'|'||
        				 'flussoElabMifDistOilId=0'||'|'|| 	-- 27.05.2016 Sofia - JIRA-3619
                         'flussoElabMifId=0'||'|'||
                         'generaXml=false'||'|'||
                         'numOrdTrasm=0'||'|'||
                         'nomeFileMif=NO_FILE'||'|'||
                         'messaggioRes='||coalesce(messaggioRisultato,'');
	    return messaggioResult;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;