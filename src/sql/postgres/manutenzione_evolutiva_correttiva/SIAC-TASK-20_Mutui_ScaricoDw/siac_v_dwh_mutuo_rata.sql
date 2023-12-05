/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/

drop view if exists siac.siac_v_dwh_mutuo_rata;
create or replace view siac.siac_v_dwh_mutuo_rata
(
    ente_proprietario_id,
    mutuo_numero,
    mutuo_rata_anno,
	mutuo_rata_num_rata_piano,
	mutuo_rata_num_rata_anno,
	mutuo_rata_data_scadenza,
	mutuo_rata_importo,
	mutuo_rata_importo_q_interessi,
	mutuo_rata_importo_q_capitale,
	mutuo_rata_importo_q_oneri,
	mutuo_rata_debito_residuo,
	mutuo_rata_debito_iniziale
 )
AS
(
SELECT 
    mutuo.ente_proprietario_id,
    mutuo.mutuo_numero,
    rata.mutuo_rata_anno,
	rata.mutuo_rata_num_rata_piano,
	rata.mutuo_rata_num_rata_anno,
	rata.mutuo_rata_data_scadenza,
	rata.mutuo_rata_importo,
	rata.mutuo_rata_importo_quota_interessi mutuo_rata_importo_q_interessi,
	rata.mutuo_rata_importo_quota_capitale  mutuo_rata_importo_q_capitale ,
	rata.mutuo_rata_importo_quota_oneri     mutuo_rata_importo_q_oneri,
	rata.mutuo_rata_debito_residuo,
	rata.mutuo_rata_debito_iniziale
FROM siac_t_mutuo mutuo ,siac_t_mutuo_rata rata 
where  mutuo.mutuo_id=rata.mutuo_id 
and      mutuo.data_cancellazione  is null
and      rata.data_cancellazione  is null
);

alter view siac.siac_v_dwh_mutuo_rata owner to siac;


