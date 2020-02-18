/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION fnc_mif_ordinativo_piazzatura_splus(accreditoTipoId integer,
                                                         codiceFunzione varchar,
														 paramPiazzatura varchar,
                                                         tipoPagamento varchar,
                                                         dataElaborazione timestamp,
                                                         dataFineVal timestamp,
                                                         enteProprietarioId integer)
RETURNS boolean AS
$body$
DECLARE

strMessaggio varchar(1500):=null;


SEPARATORE  CONSTANT VARCHAR:='|';

flagPiazzatura boolean:=false;
numeroMDPPiazzatura integer:=0;
countPiazzatura integer:=1;
numeroFunzioneStr VARCHAR(10):=null;
MDPPiazzatura varchar(150):=null;
piazzaturaOK integer:=null;

funzione varchar(15):=null;
regPar varchar(50):=null;

numeroFunzione integer:=0;

BEGIN

 -- piazzatura da valorizzare se
 -- 1. accreditoTipoId in una di quelle passate in paramPiazzatura
 -- 2. and codiceFunzione in uno di quelli passati in paramPiazzatura
 -- 3. and tipoPamento non regolarizzazione ( provvisori di cassa )

 strMessaggio:='Verifica ordinativo con piazzatura.';

 -- 1.
 if paramPiazzatura is not null then
 	strMessaggio:='Verifica ordinativo con piazzatura per accredito tipo.';
    numeroMDPPiazzatura:=trim (both ' ' from split_part(paramPiazzatura,SEPARATORE,1))::integer;
    if numeroMDPPiazzatura>0 then
     loop
	    MDPPiazzatura:=trim (both ' ' from split_part(paramPiazzatura,SEPARATORE,countPiazzatura+1));
        if MDPPiazzatura is not null then
        	 select 1 into piazzaturaOK
             from siac_d_accredito_tipo tipo, siac_d_accredito_gruppo gruppo
             where tipo.accredito_tipo_id=accreditoTipoId
             and   tipo.data_cancellazione is null
	       	 and   date_trunc('day',dataElaborazione)>=date_trunc('day',tipo.validita_inizio)
-- 		     and   date_trunc('day',dataFineVal)<=date_trunc('day',coalesce(tipo.validita_fine,dataFineVal)) 19.01.2017
 		     and   date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(tipo.validita_fine,dataElaborazione))
             and   gruppo.accredito_gruppo_id=tipo.accredito_gruppo_id
             and   gruppo.accredito_gruppo_code=MDPPiazzatura
             and   gruppo.data_cancellazione is null
         	 and   date_trunc('day',dataElaborazione)>=date_trunc('day',gruppo.validita_inizio)
-- 		  	 and   date_trunc('day',dataFineVal)<=date_trunc('day',coalesce(gruppo.validita_fine,dataFineVal)); 19.01.2017
 		  	 and   date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(gruppo.validita_fine,dataElaborazione));

        else countPiazzatura:=numeroMDPPiazzatura+1;
        end if;
        countPiazzatura:=countPiazzatura+1;
      exit when (countPiazzatura>numeroMDPPiazzatura or piazzaturaOK is not null);
     end loop;
    end if;

    if piazzaturaOK is not null then
     	-- 2.
       	strMessaggio:='Verifica ordinativo con piazzatura per codice funzione.';
		numeroFunzione:=trim (both ' ' from split_part(paramPiazzatura,SEPARATORE,numeroMDPPiazzatura+2));
        if numeroFunzione>0 then
        	countPiazzatura:=1;
            piazzaturaOK:=null;
    		loop
            	funzione:=trim (both ' ' from split_part(paramPiazzatura,SEPARATORE,countPiazzatura+numeroMDPPiazzatura+2));
                if funzione is not null and funzione=codiceFunzione then
                	piazzaturaOK:=1;
                elsif funzione is  null then
                	countPiazzatura:=numeroFunzione+1;
                end if;
                countPiazzatura:=countPiazzatura+1;
                exit when (countPiazzatura>numeroFunzione or piazzaturaOK is not null);
            end loop;
        end if;
    end if;

    -- 17.10.2017 Sofia - SIOPE+
	-- se REGOLARIZZAZIONE la piazzatura non deve essere esposta
    -- 3.
    if piazzaturaOK is not null then
       	strMessaggio:='Verifica ordinativo REGOLARIZZAZIONE.';
    	regPar:=trim (both ' ' from split_part(paramPiazzatura,'@',2));
        if regPar is not null and
           tipoPagamento is not null and
           regPar=tipoPagamento then
           piazzaturaOK:=null;
        end if;
    end if;
    -- 17.10.2017 Sofia - SIOPE+

    -- 04.12.2017 Sofia - SIOPE+
	-- se COMPENSAZIONE la piazzatura non deve essere esposta
    -- 3.
    if piazzaturaOK is not null then
       	strMessaggio:='Verifica ordinativo COMPENSAZIONE.';
    	regPar:=trim (both ' ' from split_part(paramPiazzatura,'@',3));
        if regPar is not null and
           tipoPagamento is not null and
           regPar=tipoPagamento then
           piazzaturaOK:=null;
        end if;
    end if;
    -- 04.12.2017 Sofia - SIOPE+

 end if;

 if piazzaturaOK is not null then
 	flagPiazzatura:=true;
 end if;


 return flagPiazzatura;


exception
    when RAISE_EXCEPTION THEN
        RAISE EXCEPTION '%',coalesce(strMessaggio,'')||' '||coalesce(substring(upper(SQLERRM) from 1 for 1000),'');
        return flagPiazzatura;
    when TOO_MANY_ROWS THEN
        RAISE EXCEPTION '% Diverse righe lette.',coalesce(strMessaggio,'');
        return flagPiazzatura;
   when no_data_found then
	    RAISE EXCEPTION '% Non presente in archivio.',coalesce(strMessaggio,'');
        return flagPiazzatura;
	when others  THEN
 		RAISE EXCEPTION '% Errore DB % %',coalesce(strMessaggio,''),SQLSTATE,substring(SQLERRM from 1 for 1000);
        return flagPiazzatura;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;