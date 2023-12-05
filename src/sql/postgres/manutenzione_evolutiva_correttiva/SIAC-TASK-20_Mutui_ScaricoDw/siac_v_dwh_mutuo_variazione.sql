/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/

drop view if exists siac.siac_v_dwh_mutuo_variazione;
create or replace view siac.siac_v_dwh_mutuo_variazione
(
    ente_proprietario_id,
	mutuo_variazione_anno,
	mutuo_variazione_num_rata,
   	mutuo_variazione_tipo_code,
   	mutuo_variazione_tipo_desc,
    mutuo_numero,   	
	mutuo_var_anno_fine_piano_amm,
	mutuo_variazione_num_rata_finale,
	mutuo_variazione_importo_rata,
	mutuo_variazione_tasso_euribor
 )
AS
(
SELECT 
    var.ente_proprietario_id,
    var.mutuo_variazione_anno ,
    var.mutuo_variazione_num_rata ,
    tipo.mutuo_variazione_tipo_code ,
    tipo.mutuo_variazione_tipo_desc ,
    mutuo.mutuo_numero,
    var.mutuo_variazione_anno_fine_piano_ammortamento mutuo_var_anno_fine_piano_amm,
    var.mutuo_variazione_num_rata_finale,
	var.mutuo_variazione_importo_rata,
	var.mutuo_variazione_tasso_euribor
FROM  siac_t_mutuo mutuo ,siac_t_mutuo_variazione  var,siac_d_mutuo_variazione_tipo  tipo 
where tipo.mutuo_variazione_tipo_id =var.mutuo_variazione_id 
and      mutuo.mutuo_id=var.mutuo_id 
and      mutuo.data_cancellazione  is null
and      var.data_cancellazione  is null
);

alter view siac.siac_v_dwh_mutuo_variazione owner to siac;


