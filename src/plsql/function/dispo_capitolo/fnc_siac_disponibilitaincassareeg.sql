/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION fnc_siac_disponibilitaincassareeg (
  id_in integer
)
RETURNS numeric AS
$body$
DECLARE

dispCassa numeric:=0;
annoBilancio varchar:=null;
totIncassato numeric:=0;

stanzEffettivoRec record;

strMessaggio varchar(1500):=null;
BEGIN

    strMessaggio:='Calcolo disponibilita cassa  elem_id='||id_in||'.';


	strMessaggio:='Calcolo disponibilita cassa  elem_id='||id_in||
    			  '.Lettura anno di bilancio.';

	select per.anno into strict annoBilancio
	from siac_t_bil_elem bilElem, siac_t_bil bil, siac_t_periodo per
	where bilElem.elem_id=id_in and
    	  bilElem.data_cancellazione is null and bilElem.validita_fine is null and
	      bil.bil_id=bilElem.bil_id and
    	  per.periodo_id=bil.periodo_id;



	strMessaggio:='Calcolo disponibilita cassa  elem_id='||id_in||
              	  '.Lettura stanziamento effettivo di cassa.';
	select * into stanzEffettivoRec
	from fnc_siac_stanz_effettivo_eg_anno (id_in,annoBilancio);

    strMessaggio:='Calcolo disponibilita cassa  elem_id='||id_in||
                  'Lettura totale incassato.';
    totIncassato:=fnc_siac_totaleincassatoeg(id_in);

    dispCassa:=stanzEffettivoRec.stanzEffettivoCassa-totIncassato;


    return dispCassa;

exception
    when RAISE_EXCEPTION THEN
        RAISE EXCEPTION '%',substring(SQLERRM from 1 for 1500);
        dispCassa:=0;
        return dispCassa;
    when no_data_found then
		RAISE EXCEPTION '% Non presente in archivio.',strMessaggio;
        dispCassa:=0;
        return dispCassa;
	when others  THEN
 		RAISE EXCEPTION '% Errore DB % %',strMessaggio,SQLSTATE,substring(SQLERRM from 1 for 1000);
        dispCassa:=0;
        return dispCassa;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;