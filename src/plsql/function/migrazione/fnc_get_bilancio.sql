/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION fnc_get_bilancio     (enteproprietarioid integer,
												 annoBilancio in VARCHAR,
											     out idBilancio integer,
											     out messaggioRisultato varchar
											 )
RETURNS record AS
$body$
DECLARE
BEGIN
    begin
      select b.bil_id into strict idBilancio
      from siac_t_bil b
      join siac_t_periodo p on (b.periodo_id=p.periodo_id
          and b.ente_proprietario_id = p.ente_proprietario_id
          and p.anno = annobilancio)
      where b.ente_proprietario_id = enteProprietarioId
      and b.validita_fine is null;
	exception
      when NO_DATA_FOUND THEN
         messaggioRisultato:='Id bilancio non recueprato per ente '||enteProprietarioId||', anno '||annobilancio||'.';
         idBilancio:=-1;
         return;
      when TOO_MANY_ROWS THEN
         messaggioRisultato:='Impossibile identificare id bilancio, troppi valori per ente '||enteProprietarioId||', anno '||annobilancio||'.';
         idBilancio:=-1;
         return;
    end;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;