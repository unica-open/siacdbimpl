/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
﻿-- ottengo idmin e idmax
SELECT
  movgest_id
FROM
  siac.siac_t_movgest where ente_proprietario_id=<p_ente>
  and movgest_anno='<anno impegno csv>' and login_operazione='migr_impacc' and movgest_numero >= <numero imp iniz csv>  
  order by movgest_numero;

-- lancio la clean
 select  *
 from fnc_migr_impacc_clean_aggiunti (<p_ente>,'migr_impacc','migr_impacc',<idmin>,<idmax>);