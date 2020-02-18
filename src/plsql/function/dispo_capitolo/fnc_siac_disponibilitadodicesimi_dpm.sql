/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac.fnc_siac_disponibilitadodicesimi_dpm (
  id_in integer
)
RETURNS numeric AS
$body$
DECLARE

dispDpm  numeric:=0;
diDpmRec record;

TIPO_DISP_DPM constant varchar:='DPM';
strMessaggio varchar(1500):=null;
---    ANNASILVIA CMTO FORZATURA
ente_prop_in NUMERIC:=0;

BEGIN

    strMessaggio:='Calcolo DPM elem_id='||id_in||'.';

    select * into diDpmRec
    from  fnc_siac_disponibilitadodicesimi (id_in,TIPO_DISP_DPM);
    if diDpmRec.codicerisultato=-1 then
    	raise exception '%',diDpmRec.messaggiorisultato;
    end if;

    dispDpm:=diDpmRec.importodpm;


---    ANNASILVIA CMTO FORZATURA 03-07-2017 INIZIO
/*
    select a.ente_proprietario_id
    into ente_prop_in from siac_t_bil_elem a
    where a.elem_id = id_in;

    if ente_prop_in = 3 then
        	dispDpm := 99999999999999;
    end if;
*/
---    ANNASILVIA CMTO FORZATURA 03-07-2017 FINE


    return dispDpm;

exception
    when RAISE_EXCEPTION THEN
        RAISE EXCEPTION '%',substring(SQLERRM from 1 for 1500);
        dispDpm:=0;
        return dispDpm;
    when no_data_found then
		RAISE EXCEPTION '% Non presente in archivio.',strMessaggio;
        dispDpm:=0;
        return dispDpm;
	when others  THEN
 		RAISE EXCEPTION '% Errore DB % %',strMessaggio,SQLSTATE,substring(SQLERRM from 1 for 1500);
        dispDpm:=0;
        return dispDpm;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;