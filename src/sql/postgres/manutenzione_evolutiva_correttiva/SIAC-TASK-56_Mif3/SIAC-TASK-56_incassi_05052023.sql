/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/

-- INCASSI  
 

-- Q1 - verifica esistenza ordinativi di incasso associati a ACCREDITO BANCA ITALIA
-- nel 2024 non potra essere usato
-- chiusura del classificatore CLASSIFICATORE_28 classif_desc=%ACCREDITO BANCA D''ITALIA
-- chiusura del tipo accredito oil %ACCREDITO BANCA D''ITALIA
select r.ente_proprietario_id , r.accredito_tipo_oil_desc_incasso, oil.accredito_tipo_oil_desc 
from siac_r_accredito_tipo_plus r ,siac_d_accredito_tipo_oil oil
     where oil.ente_proprietario_id  in ( 2,3,4,5,10,16)
     and   r.accredito_tipo_oil_id=oil.accredito_tipo_oil_id
     and   oil.accredito_tipo_oil_desc  like '%ACCREDITO BANCA D''ITALIA'
     and   r.data_cancellazione is null
     and   r.validita_fine is null
     and   oil.data_cancellazione is null
     and   oil.validita_fine is null
     order by 1;
     
select c.ente_proprietario_id ,c.classif_desc , oi.ord_numero, oi.ord_stato_code 
from siac_d_class_tipo tipo,siac_r_ordinativo_class rc,siac_t_class c ,siac_v_bko_ordinativo_oi_Stati  oi 
where tipo.ente_proprietario_id in ( 2,3,4,5,10,16)
and      tipo.classif_tipo_code ='CLASSIFICATORE_28'
and      c.classif_tipo_id=tipo.classif_tipo_id
and      rc.classif_id=c.classif_id 
and      c.classif_desc like '%ACCREDITO BANCA D''ITALIA'
and      oi.ord_id=rc.ord_id
and      oi.anno_bilancio >=2022
and      oi.statoord_validita_fine  is null 
and      rc.data_cancellazione is null 
and      rc.validita_fine is null 
order by 1,oi.ord_numero;

select c.ente_proprietario_id ,c.classif_desc
from siac_d_class_tipo tipo,siac_t_class c 
where tipo.ente_proprietario_id in ( 2,3,4,5,10,16)
and      tipo.classif_tipo_code ='CLASSIFICATORE_28'
and      c.classif_tipo_id=tipo.classif_tipo_id
and      c.classif_desc like '%ACCREDITO BANCA D''ITALIA'
and      c.data_cancellazione  is null 
order by 1;

update siac_t_class c
set      data_cancellazione =now(),
           validita_fine=now(),
           login_operazione =c.login_operazione ||'-SIAC-TASK-56'
from siac_d_class_tipo tipo 
where tipo.ente_proprietario_id in ( 2,3,4,5,10,16)
and      tipo.classif_tipo_code ='CLASSIFICATORE_28'
and      c.classif_tipo_id=tipo.classif_tipo_id
and      c.classif_desc='%ACCREDITO BANCA D''ITALIA'
and      c.data_cancellazione  is null 
and      c.validita_fine is null;

update siac_d_accredito_tipo_oil oil
set      data_cancellazione=now(),
           validita_fine =now(),
           login_operazione =oil.login_operazione ||'-SIAC-TASK-56'
where oil.ente_proprietario_id  in ( 2,3,4,5,10,16)
and   oil.accredito_tipo_oil_desc  like '%ACCREDITO BANCA D''ITALIA'
and   oil.data_cancellazione is null
and   oil.validita_fine is null;

update siac_r_accredito_tipo_plus r
set      data_cancellazione=now(),
           validita_fine =now(),
           login_operazione =oil.login_operazione ||'-SIAC-TASK-56'
from siac_d_accredito_tipo_oil oil
where oil.ente_proprietario_id  in ( 2,3,4,5,10,16)
and   r.accredito_tipo_oil_id=oil.accredito_tipo_oil_id
and   oil.accredito_tipo_oil_desc  like '%ACCREDITO BANCA D''ITALIA'
and   r.data_cancellazione is null
and   r.validita_fine is null
and   oil.data_cancellazione is not null
and   oil.login_operazione like '%SIAC-TASK-56';
