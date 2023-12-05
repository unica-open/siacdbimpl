/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
REATE OR REPLACE FUNCTION fnc_siac_calcolo_stanz_cap (
  annoBilancio varchar,
  bilelemtipo varchar,
  enteProprietarioIdStrIn varchar
)
RETURNS TABLE
(
	enteProprietarioIdStr varchar,
    enteDenominazione varchar,
	countCapitolo varchar,
    stanziamentoIniziale numeric,
    stanziamentoResIniziale numeric,
    stanziamentoCassaIniziale numeric,
    stanziamentoAttuale numeric,
    stanziamentoRes numeric,
    stanziamentoCassa numeric,
    stanziamentoInizialeAnno1 numeric,
    stanziamentoAttualeAnno1 numeric,
    stanziamentoInizialeAnno2 numeric,
    stanziamentoAttualeAnno2 numeric
) AS
$body$
DECLARE


 periodoTipoId integer:=0;
 bilancioId  integer:=0;
 periodoAnnoId  integer:=0;
 periodoAnno1Id  integer:=0;
 periodoAnno2Id  integer:=0;
 enteProprietarioId integer:=0;

 elemDetTipoIdSti integer:=0;
 elemDetTipoIdSri integer:=0;
 elemDetTipoIdSci integer:=0;
 elemDetTipoIdSta integer:=0;
 elemDetTipoIdStr integer:=0;
 elemDetTipoIdSca integer:=0;

 elemTipoId integer:=0;
BEGIN

	enteProprietarioIdStr:='';
    enteDenominazione:='';
	countCapitolo:='0';
    stanziamentoAttuale:=0;

    enteproprietarioid:=enteProprietarioIdStrIn::integer;

   select ente_proprietario_id::varchar, ente_denominazione
   into   enteProprietarioIdStr, enteDenominazione
   from siac_t_ente_proprietario
   where ente_proprietario_id=enteProprietarioId;

   select periodo_tipo_id into periodoTipoId
   from siac_d_periodo_tipo
   where ente_proprietario_id=enteProprietarioId
     and periodo_tipo_code='SY';


   select bil.bil_id , bil.periodo_id
   into bilancioId, periodoAnnoId
   from siac_t_bil bil, siac_t_periodo per--, siac_d_periodo_tipo perTipo
   where per.anno=annoBilancio
     and per.ente_proprietario_id=enteProprietarioId
     and per.periodo_tipo_id=periodoTipoId
     and bil.periodo_id=per.periodo_id;


   select per.periodo_id into periodoAnno1Id
   from siac_t_periodo per
   where per.anno=((annoBilancio::integer)+1)::varchar
     and per.ente_proprietario_id=enteProprietarioId
     and per.periodo_tipo_id=periodoTipoId;

   select per.periodo_id into periodoAnno2Id
   from siac_t_periodo per
   where per.anno=((annoBilancio::integer)+2)::varchar
     and per.ente_proprietario_id=enteProprietarioId
     and per.periodo_tipo_id=periodoTipoId;


   select elemdettipo.elem_det_tipo_id into elemDetTipoIdSti
   from siac_d_bil_elem_det_tipo elemdettipo
   where elemdettipo.ente_proprietario_id=enteProprietarioId
     and elemdettipo.elem_det_tipo_code='STI';

   select elemdettipo.elem_det_tipo_id into elemDetTipoIdSci
   from siac_d_bil_elem_det_tipo elemdettipo
   where elemdettipo.ente_proprietario_id=enteProprietarioId
     and elemdettipo.elem_det_tipo_code='SCI';

   select elemdettipo.elem_det_tipo_id into elemDetTipoIdSri
   from siac_d_bil_elem_det_tipo elemdettipo
   where elemdettipo.ente_proprietario_id=enteProprietarioId
     and elemdettipo.elem_det_tipo_code='SRI';

   select elemdettipo.elem_det_tipo_id into elemDetTipoIdSta
   from siac_d_bil_elem_det_tipo elemdettipo
   where elemdettipo.ente_proprietario_id=enteProprietarioId
     and elemdettipo.elem_det_tipo_code='STA';

   select elemdettipo.elem_det_tipo_id into elemDetTipoIdStr
   from siac_d_bil_elem_det_tipo elemdettipo
   where elemdettipo.ente_proprietario_id=enteProprietarioId
     and elemdettipo.elem_det_tipo_code='STR';

   select elemdettipo.elem_det_tipo_id into elemDetTipoIdSca
   from siac_d_bil_elem_det_tipo elemdettipo
   where elemdettipo.ente_proprietario_id=enteProprietarioId
     and elemdettipo.elem_det_tipo_code='SCA';



   select  tipocap.elem_tipo_id into elemTipoId
   from siac_d_bil_elem_tipo tipocap
   where ente_proprietario_id=enteProprietarioId and
         elem_tipo_code=bilelemtipo;

   select count(*)::varchar into countCapitolo
   from siac_t_bil_elem cap
   where cap.ente_proprietario_id=enteProprietarioId
     and cap.elem_tipo_id=elemTipoId
     and cap.bil_id=bilancioId;

  select sum(impCap.elem_det_importo) into stanziamentoIniziale
   from siac_t_bil_elem cap, siac_t_bil_elem_det impCap
   where cap.ente_proprietario_id=enteproprietarioid
     and cap.bil_id=bilancioId
     and cap.elem_tipo_id=elemTipoId
     and impCap.elem_id=cap.elem_id
     and impCap.elem_det_tipo_id=elemDetTipoIdSti
     and impCap.periodo_id=periodoAnnoId;

  select sum(impCap.elem_det_importo) into stanziamentoResIniziale
   from siac_t_bil_elem cap, siac_t_bil_elem_det impCap
   where cap.ente_proprietario_id=enteproprietarioid
     and cap.bil_id=bilancioId
     and cap.elem_tipo_id=elemTipoId
     and impCap.elem_id=cap.elem_id
     and impCap.elem_det_tipo_id=elemDetTipoIdSri
     and impCap.periodo_id=periodoAnnoId;

  select sum(impCap.elem_det_importo) into stanziamentoCassaIniziale
   from siac_t_bil_elem cap, siac_t_bil_elem_det impCap
   where cap.ente_proprietario_id=enteproprietarioid
     and cap.bil_id=bilancioId
     and cap.elem_tipo_id=elemTipoId
     and impCap.elem_id=cap.elem_id
     and impCap.elem_det_tipo_id=elemDetTipoIdSci
     and impCap.periodo_id=periodoAnnoId;


   select sum(impCap.elem_det_importo) into stanziamentoAttuale
   from siac_t_bil_elem cap, siac_t_bil_elem_det impCap
   where cap.ente_proprietario_id=enteproprietarioid
     and cap.bil_id=bilancioId
     and cap.elem_tipo_id=elemTipoId
     and impCap.elem_id=cap.elem_id
     and impCap.elem_det_tipo_id=elemDetTipoIdSta
     and impCap.periodo_id=periodoAnnoId;

   select sum(impCap.elem_det_importo) into stanziamentoRes
   from siac_t_bil_elem cap, siac_t_bil_elem_det impCap
   where cap.ente_proprietario_id=enteproprietarioid
     and cap.bil_id=bilancioId
     and cap.elem_tipo_id=elemTipoId
     and impCap.elem_id=cap.elem_id
     and impCap.elem_det_tipo_id=elemDetTipoIdStr
     and impCap.periodo_id=periodoAnnoId;

   select sum(impCap.elem_det_importo) into stanziamentoCassa
   from siac_t_bil_elem cap, siac_t_bil_elem_det impCap
   where cap.ente_proprietario_id=enteproprietarioid
     and cap.bil_id=bilancioId
     and cap.elem_tipo_id=elemTipoId
     and impCap.elem_id=cap.elem_id
     and impCap.elem_det_tipo_id=elemDetTipoIdSca
     and impCap.periodo_id=periodoAnnoId;

  select sum(impCap.elem_det_importo) into stanziamentoInizialeAnno1
   from siac_t_bil_elem cap, siac_t_bil_elem_det impCap
   where cap.ente_proprietario_id=enteproprietarioid
     and cap.bil_id=bilancioId
     and cap.elem_tipo_id=elemTipoId
     and impCap.elem_id=cap.elem_id
     and impCap.elem_det_tipo_id=elemDetTipoIdSti
     and impCap.periodo_id=periodoAnno1Id;

  select sum(impCap.elem_det_importo) into stanziamentoAttualeAnno1
   from siac_t_bil_elem cap, siac_t_bil_elem_det impCap
   where cap.ente_proprietario_id=enteproprietarioid
     and cap.bil_id=bilancioId
     and cap.elem_tipo_id=elemTipoId
     and impCap.elem_id=cap.elem_id
     and impCap.elem_det_tipo_id=elemDetTipoIdSta
     and impCap.periodo_id=periodoAnno1Id;

  select sum(impCap.elem_det_importo) into stanziamentoInizialeAnno2
   from siac_t_bil_elem cap, siac_t_bil_elem_det impCap
   where cap.ente_proprietario_id=enteproprietarioid
     and cap.bil_id=bilancioId
     and cap.elem_tipo_id=elemTipoId
     and impCap.elem_id=cap.elem_id
     and impCap.elem_det_tipo_id=elemDetTipoIdSti
     and impCap.periodo_id=periodoAnno2Id;

  select sum(impCap.elem_det_importo) into stanziamentoAttualeAnno2
   from siac_t_bil_elem cap, siac_t_bil_elem_det impCap
   where cap.ente_proprietario_id=enteproprietarioid
     and cap.bil_id=bilancioId
     and cap.elem_tipo_id=elemTipoId
     and impCap.elem_id=cap.elem_id
     and impCap.elem_det_tipo_id=elemDetTipoIdSta
     and impCap.periodo_id=periodoAnno2Id;



	return next;

END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;