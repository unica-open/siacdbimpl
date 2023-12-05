/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/

drop view if exists siac.siac_v_dwh_mutuo_programma;
create or replace view siac.siac_v_dwh_mutuo_programma
(
    ente_proprietario_id,
    anno_bilancio,
    mutuo_numero,
    mutuo_programma_tipo,
    mutuo_programma_code,
    mutuo_movgest_importo_iniziale,
    mutuo_movgest_importo_finale
 )
AS
(
SELECT 
    per.ente_proprietario_id,
    per.anno::integer anno_bilancio,
    mutuo.mutuo_numero,
    tipo.programma_tipo_code mutuo_programma_tipo,
    prog.programma_code  mutuo_programma_code,
    rp.mutuo_programma_importo_iniziale ,
    rp.mutuo_programma_importo_finale 
FROM siac_t_bil bil,siac_t_periodo per,
             siac_t_programma prog,siac_d_programma_tipo tipo,
             siac_t_mutuo mutuo ,siac_r_mutuo_programma  rp 
where bil.periodo_id=per.periodo_id 
and      prog.bil_id=bil.bil_id 
and      tipo.programma_tipo_id=prog.programma_tipo_id  
and      rp.programma_id=prog.programma_id  
and      mutuo.mutuo_id=rp.mutuo_id 
and      rp.data_cancellazione  is null 
and      mutuo.data_cancellazione  is null
and      prog.data_cancellazione  is null
);

alter view siac.siac_v_dwh_mutuo_programma owner to siac;


