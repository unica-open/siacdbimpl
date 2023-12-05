/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/

select op.ord_numero, conto.contotes_code , conto_coll.contotes
from siac_r_ordinativo_contotes_nodisp  r,siac_v_bko_ordinativo_oi_valido op ,siac_d_contotesoreria  conto ,siac_t_ordinativo ord ,siac_d_contotesoreria  conto_coll
where op.ente_proprietario_id =2
and     op.anno_bilancio =2022
and     r.ord_id=op.ord_id
and     r.contotes_id =conto.contotes_id 
and    ord.ord_id=op.ord_id 
and    conto_coll.contotes_id =ord.contotes_id 
and    r.data_cancellazione  is null 
and    r.validita_fine  is null 


-- DDL
alter table siac_dwh_ordinativo_pagamento
add cod_conto_tes_vincolato VARCHAR(200);
alter table siac_dwh_ordinativo_pagamento
<<<<<<< HEAD
add descri_conto_tes_vincolato VARCHAR(500);
=======
<<<<<<< HEAD
<<<<<<< HEAD
add descrizione_conto_tes_vincolato VARCHAR(500);
=======
add descri_conto_tes_vincolato VARCHAR(500);
>>>>>>> rilascio-5.14
=======
add descri_conto_tes_vincolato VARCHAR(500);
>>>>>>> origin/master
>>>>>>> mutui
  
alter table siac_dwh_ordinativo_incasso
add cod_conto_tes_vincolato VARCHAR(200);
alter table siac_dwh_ordinativo_incasso
<<<<<<< HEAD
add descri_conto_tes_vincolato VARCHAR(500);
=======
<<<<<<< HEAD
<<<<<<< HEAD
add descrizione_conto_tes_vincolato VARCHAR(500);
=======
add descri_conto_tes_vincolato VARCHAR(500);
>>>>>>> rilascio-5.14
=======
add descri_conto_tes_vincolato VARCHAR(500);
>>>>>>> origin/master
>>>>>>> mutui

