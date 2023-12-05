/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION fnc_siac_attoal_getDataStato
(
  attoAlId integer,
  attoalStatoCode varchar
)
RETURNS timestamp
AS
$body$
DECLARE

attoalRMaxStatoRicId integer;
attoalRMaxStatoNonRicId integer;
attoalRStatoId integer;

attoalDataStatoRel timestamp;


v_messaggiorisultato varchar;
BEGIN


	select max(rs.attoal_r_stato_id) into attoalRMaxStatoRicId
    from  siac_r_atto_allegato_stato rs, siac_d_atto_allegato_stato stato
    where rs.attoal_id=attoAlId
    and   stato.attoal_stato_id=rs.attoal_stato_id
    and   stato.attoal_stato_code=attoalStatoCode;

	select max(rs.attoal_r_stato_id) into attoalRMaxStatoNonRicId
    from  siac_r_atto_allegato_stato rs, siac_d_atto_allegato_stato stato
    where rs.attoal_id=attoAlId
    and   rs.attoal_r_stato_id<attoalRMaxStatoRicId
    and   stato.attoal_stato_id=rs.attoal_stato_id
    and   stato.attoal_stato_code!=attoalStatoCode;

   	select min(rs.attoal_r_stato_id) into attoalRStatoId
    from  siac_r_atto_allegato_stato rs, siac_d_atto_allegato_stato stato
    where rs.attoal_id=attoAlId
    and   rs.attoal_r_stato_id>attoalRMaxStatoNonRicId
    and   stato.attoal_stato_id=rs.attoal_stato_id;

    select rs.validita_inizio into attoalDataStatoRel
	from  siac_r_atto_allegato_stato rs
    where  rs.attoal_r_stato_id>=attoalRStatoId;

	return attoalDataStatoRel;

exception
    when RAISE_EXCEPTION THEN
    v_messaggiorisultato:=v_messaggiorisultato|| ' - ' ||substring(upper(SQLERRM) from 1 for 2500);
    raise notice '%',v_messaggiorisultato;
    return attoalDataStatoRel;
	when others  THEN
	v_messaggiorisultato:=v_messaggiorisultato|| ' others - ' ||substring(upper(SQLERRM) from 1 for 2500);
    raise notice '%',v_messaggiorisultato;
    return attoalDataStatoRel;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY DEFINER
COST 100;