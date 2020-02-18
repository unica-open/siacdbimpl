/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
elect * from mif_d_flusso_elaborato d
where d.ente_proprietario_id=&ente
and d.flusso_elab_mif_tipo_id in
(select t.flusso_elab_mif_tipo_id
 from mif_d_flusso_elaborato_tipo  t
 where t.ente_proprietario_id=d.ente_proprietario_id
 and   t.flusso_elab_mif_tipo_code='MANDMIF')
--and   t.flusso_elab_mif_tipo_code='MANDMIF_UNIIT' )
order by d.flusso_elab_mif_ordine

select * from mif_d_flusso_elaborato d
where d.ente_proprietario_id=&ente
and d.flusso_elab_mif_tipo_id in
(select t.flusso_elab_mif_tipo_id
 from mif_d_flusso_elaborato_tipo  t
 where t.ente_proprietario_id=d.ente_proprietario_id
and   t.flusso_elab_mif_tipo_code='MANDMIF')
--and   t.flusso_elab_mif_tipo_code='MANDMIF_ABI36' )
--and   d.flusso_elab_mif_code='provincia_beneficiario'
--and   d.flusso_elab_mif_ordine>=79
and   d.flusso_elab_mif_ordine>=87
order by d.flusso_elab_mif_ordine


-- insert ABI36
-- stato_beneficiario
insert into mif_d_flusso_elaborato
(flusso_elab_mif_tipo_id,flusso_elab_mif_ordine,flusso_elab_mif_ordine_elab,flusso_elab_mif_code,flusso_elab_mif_desc,flusso_elab_mif_attivo,flusso_elab_mif_xml_out,
 flusso_elab_mif_code_padre,flusso_elab_mif_tabella,flusso_elab_mif_campo,flusso_elab_mif_default,flusso_elab_mif_elab,flusso_elab_mif_param,flusso_elab_mif_query,
 validita_inizio, ente_proprietario_id,login_operazione)
(select
 tipo.flusso_elab_mif_tipo_id,79,185,'stato_beneficiario','vedasi piazzatura.codice_paese',true,true,'flusso_ordinativi.mandato.informazioni_beneficiario.beneficiario','mif_t_ordinativo_spesa','mif_ord_stato_benef',null,true,null,null,'2015-01-01 00:00:00',
 tipo.ente_proprietario_id,'admin'
 from mif_d_flusso_elaborato_tipo tipo
 where
-- tipo.flusso_elab_mif_tipo_code='MANDMIF_ABI36'
 tipo.flusso_elab_mif_tipo_code='MANDMIF'
 and   tipo.ente_proprietario_id=&ente
 );

--insert UniIt
insert into mif_d_flusso_elaborato
(flusso_elab_mif_tipo_id,flusso_elab_mif_ordine,flusso_elab_mif_ordine_elab,flusso_elab_mif_code,flusso_elab_mif_desc,flusso_elab_mif_attivo,flusso_elab_mif_xml_out,
 flusso_elab_mif_code_padre,flusso_elab_mif_tabella,flusso_elab_mif_campo,flusso_elab_mif_default,flusso_elab_mif_elab,flusso_elab_mif_param,flusso_elab_mif_query,
 validita_inizio, ente_proprietario_id,login_operazione)
(select
 tipo.flusso_elab_mif_tipo_id,87,185,'stato_beneficiario','per conformita ABI36',false,false,'Flusso_Documenti.Pacchetto_Mandati_Ritenute_Reversali.ordinativo_mandato.Mandati_Ritenute_InfoServ.mandato.beneficiario','mif_t_ordinativo_spesa','mif_ord_stato_benef',null,true,null,null,'2015-01-01 00:00:00',
 tipo.ente_proprietario_id,'admin'
 from mif_d_flusso_elaborato_tipo tipo
 where
-- tipo.flusso_elab_mif_tipo_code='MANDMIF_ABI36'
 tipo.flusso_elab_mif_tipo_code='MANDMIF'
 and   tipo.ente_proprietario_id=&ente
 );
 begin;

 -- ABI 36
 update mif_d_flusso_elaborato d set flusso_elab_mif_ordine=flusso_elab_mif_ordine+1
 from mif_d_flusso_elaborato_tipo tipo
 where
-- tipo.flusso_elab_mif_tipo_code='MANDMIF_ABI36'
 tipo.flusso_elab_mif_tipo_code='MANDMIF'
 and    tipo.ente_proprietario_id=&ente
 and    d.flusso_elab_mif_tipo_id=tipo.flusso_elab_mif_tipo_id
 and    d.flusso_elab_mif_ordine>=79
 and    d.flusso_elab_mif_code!='stato_beneficiario'

  update mif_d_flusso_elaborato d set flusso_elab_mif_ordine=flusso_elab_mif_ordine+1
 from mif_d_flusso_elaborato_tipo tipo
 where
-- tipo.flusso_elab_mif_tipo_code='MANDMIF_ABI36'
 tipo.flusso_elab_mif_tipo_code='MANDMIF'
 and    tipo.ente_proprietario_id=&ente
 and    d.flusso_elab_mif_tipo_id=tipo.flusso_elab_mif_tipo_id
 and    d.flusso_elab_mif_ordine>=87
 and    d.flusso_elab_mif_code!='stato_beneficiario'







 -- dati_a_disposizione_ente_beneficiario

select * from mif_d_flusso_elaborato d
where d.ente_proprietario_id=&ente
and d.flusso_elab_mif_tipo_id in
(select t.flusso_elab_mif_tipo_id
 from mif_d_flusso_elaborato_tipo  t
 where t.ente_proprietario_id=d.ente_proprietario_id
and   t.flusso_elab_mif_tipo_code='MANDMIF')
--and   t.flusso_elab_mif_tipo_code='MANDMIF_ABI36' )
and   d.flusso_elab_mif_ordine>=203
order by d.flusso_elab_mif_ordine

select * from mif_d_flusso_elaborato d
where d.ente_proprietario_id=&ente
and d.flusso_elab_mif_tipo_id in
(select t.flusso_elab_mif_tipo_id
 from mif_d_flusso_elaborato_tipo  t
 where t.ente_proprietario_id=d.ente_proprietario_id
and   t.flusso_elab_mif_tipo_code='MANDMIF')
--and   t.flusso_elab_mif_tipo_code='MANDMIF_ABI36' )
and   d.flusso_elab_mif_ordine_elab>=186
order by d.flusso_elab_mif_ordine

select * from mif_d_flusso_elaborato d
where d.ente_proprietario_id!=2
and d.flusso_elab_mif_tipo_id in
(select t.flusso_elab_mif_tipo_id
 from mif_d_flusso_elaborato_tipo  t
 where t.ente_proprietario_id=d.ente_proprietario_id
and   t.flusso_elab_mif_tipo_code='MANDMIF')
--and   t.flusso_elab_mif_tipo_code='MANDMIF_ABI36' )
and   d.flusso_elab_mif_ordine_elab>=186
order by d.flusso_elab_mif_ordine

update mif_d_flusso_elaborato
set

-- ABI36
insert into mif_d_flusso_elaborato
(flusso_elab_mif_tipo_id,flusso_elab_mif_ordine,flusso_elab_mif_ordine_elab,flusso_elab_mif_code,flusso_elab_mif_desc,flusso_elab_mif_attivo,flusso_elab_mif_xml_out,
 flusso_elab_mif_code_padre,flusso_elab_mif_tabella,flusso_elab_mif_campo,flusso_elab_mif_default,flusso_elab_mif_elab,flusso_elab_mif_param,flusso_elab_mif_query,
 validita_inizio, ente_proprietario_id,login_operazione)
(select
 tipo.flusso_elab_mif_tipo_id,203,0,'dati_a_disposizione_ente_beneficiario',null,true,true,'flusso_ordinativi.mandato.informazioni_beneficiario',null,null,null,false,null,null,'2015-01-01 00:00:00',
 tipo.ente_proprietario_id,'admin'
 from mif_d_flusso_elaborato_tipo tipo
 where
-- tipo.flusso_elab_mif_tipo_code='MANDMIF_ABI36'
 tipo.flusso_elab_mif_tipo_code='MANDMIF'
 and   tipo.ente_proprietario_id=&ente
 );

insert into mif_d_flusso_elaborato
(flusso_elab_mif_tipo_id,flusso_elab_mif_ordine,flusso_elab_mif_ordine_elab,flusso_elab_mif_code,flusso_elab_mif_desc,flusso_elab_mif_attivo,flusso_elab_mif_xml_out,
 flusso_elab_mif_code_padre,flusso_elab_mif_tabella,flusso_elab_mif_campo,flusso_elab_mif_default,flusso_elab_mif_elab,flusso_elab_mif_param,flusso_elab_mif_query,
 validita_inizio, ente_proprietario_id,login_operazione)
(select
 tipo.flusso_elab_mif_tipo_id,204,0,'altri_codici_identificativi',null,true,true,'flusso_ordinativi.mandato.informazioni_beneficiario.dati_a_disposizione_ente_beneficiario',null,null,null,false,null,
 'select * from mif_t_ordinativo_spesa_disp_ente_benef where ente_proprietario_id=:ente_proprietario_id and data_cancellazione is null and validita_fine is null and mif_ord_id=:mif_ord_id',
 '2015-01-01 00:00:00',tipo.ente_proprietario_id,'admin'
 from mif_d_flusso_elaborato_tipo tipo
 where
-- tipo.flusso_elab_mif_tipo_code='MANDMIF_ABI36'
 tipo.flusso_elab_mif_tipo_code='MANDMIF'
 and   tipo.ente_proprietario_id=&ente
 );

insert into mif_d_flusso_elaborato
(flusso_elab_mif_tipo_id,flusso_elab_mif_ordine,flusso_elab_mif_ordine_elab,flusso_elab_mif_code,flusso_elab_mif_desc,
 flusso_elab_mif_attivo,flusso_elab_mif_xml_out,
 flusso_elab_mif_code_padre,flusso_elab_mif_tabella,flusso_elab_mif_campo,
 flusso_elab_mif_default,flusso_elab_mif_elab,
 flusso_elab_mif_param,flusso_elab_mif_query,
 validita_inizio, ente_proprietario_id,login_operazione)
(select
 tipo.flusso_elab_mif_tipo_id,205,186,'codice_missione',null,
 true,true,
 'flusso_ordinativi.mandato.informazioni_beneficiario.dati_a_disposizione_ente_beneficiario.altri_codici_identificativi',
 'mif_t_ordinativo_spesa_disp_ente_benef','mif_ord_dispe_missione',
 null,true,
 'Spesa - MissioniProgrammi',null,
 '2015-01-01 00:00:00',tipo.ente_proprietario_id,'admin'
 from mif_d_flusso_elaborato_tipo tipo
 where
-- tipo.flusso_elab_mif_tipo_code='MANDMIF_ABI36'
 tipo.flusso_elab_mif_tipo_code='MANDMIF'
 and   tipo.ente_proprietario_id=&ente
 );

 insert into mif_d_flusso_elaborato
(flusso_elab_mif_tipo_id,flusso_elab_mif_ordine,flusso_elab_mif_ordine_elab,flusso_elab_mif_code,flusso_elab_mif_desc,
 flusso_elab_mif_attivo,flusso_elab_mif_xml_out,
 flusso_elab_mif_code_padre,flusso_elab_mif_tabella,flusso_elab_mif_campo,
 flusso_elab_mif_default,flusso_elab_mif_elab,
 flusso_elab_mif_param,flusso_elab_mif_query,
 validita_inizio, ente_proprietario_id,login_operazione)
(select
 tipo.flusso_elab_mif_tipo_id,206,187,'codice_programma',null,
 true,true,
 'flusso_ordinativi.mandato.informazioni_beneficiario.dati_a_disposizione_ente_beneficiario.altri_codici_identificativi',
 'mif_t_ordinativo_spesa_disp_ente_benef','mif_ord_dispe_programma',
 null,true,
 'PROGRAMMA',null,
 '2015-01-01 00:00:00',tipo.ente_proprietario_id,'admin'
 from mif_d_flusso_elaborato_tipo tipo
 where
-- tipo.flusso_elab_mif_tipo_code='MANDMIF_ABI36'
 tipo.flusso_elab_mif_tipo_code='MANDMIF'
 and   tipo.ente_proprietario_id=&ente
 );

  insert into mif_d_flusso_elaborato
(flusso_elab_mif_tipo_id,flusso_elab_mif_ordine,flusso_elab_mif_ordine_elab,flusso_elab_mif_code,flusso_elab_mif_desc,
 flusso_elab_mif_attivo,flusso_elab_mif_xml_out,
 flusso_elab_mif_code_padre,flusso_elab_mif_tabella,flusso_elab_mif_campo,
 flusso_elab_mif_default,flusso_elab_mif_elab,
 flusso_elab_mif_param,flusso_elab_mif_query,
 validita_inizio, ente_proprietario_id,login_operazione)
(select
 tipo.flusso_elab_mif_tipo_id,207,188,'codice_economico',null,
 true,true,
 'flusso_ordinativi.mandato.informazioni_beneficiario.dati_a_disposizione_ente_beneficiario.altri_codici_identificativi',
 'mif_t_ordinativo_spesa_disp_ente_benef','mif_ord_dispe_codice_economico',
 null,true,
 'OP',null,
 '2015-01-01 00:00:00',tipo.ente_proprietario_id,'admin'
 from mif_d_flusso_elaborato_tipo tipo
 where
-- tipo.flusso_elab_mif_tipo_code='MANDMIF_ABI36'
 tipo.flusso_elab_mif_tipo_code='MANDMIF'
 and   tipo.ente_proprietario_id=&ente
 );

  insert into mif_d_flusso_elaborato
(flusso_elab_mif_tipo_id,flusso_elab_mif_ordine,flusso_elab_mif_ordine_elab,flusso_elab_mif_code,flusso_elab_mif_desc,
 flusso_elab_mif_attivo,flusso_elab_mif_xml_out,
 flusso_elab_mif_code_padre,flusso_elab_mif_tabella,flusso_elab_mif_campo,
 flusso_elab_mif_default,flusso_elab_mif_elab,
 flusso_elab_mif_param,flusso_elab_mif_query,
 validita_inizio, ente_proprietario_id,login_operazione)
(select
 tipo.flusso_elab_mif_tipo_id,208,189,'importo_codice_economico',null,
 true,true,
 'flusso_ordinativi.mandato.informazioni_beneficiario.dati_a_disposizione_ente_beneficiario.altri_codici_identificativi',
 'mif_t_ordinativo_spesa_disp_ente_benef','mif_ord_dispe_codice_economico_imp',
 null,true,
 null,null,
 '2015-01-01 00:00:00',tipo.ente_proprietario_id,'admin'
 from mif_d_flusso_elaborato_tipo tipo
 where
-- tipo.flusso_elab_mif_tipo_code='MANDMIF_ABI36'
 tipo.flusso_elab_mif_tipo_code='MANDMIF'
 and   tipo.ente_proprietario_id=&ente
 );

  insert into mif_d_flusso_elaborato
(flusso_elab_mif_tipo_id,flusso_elab_mif_ordine,flusso_elab_mif_ordine_elab,flusso_elab_mif_code,flusso_elab_mif_desc,
 flusso_elab_mif_attivo,flusso_elab_mif_xml_out,
 flusso_elab_mif_code_padre,flusso_elab_mif_tabella,flusso_elab_mif_campo,
 flusso_elab_mif_default,flusso_elab_mif_elab,
 flusso_elab_mif_param,flusso_elab_mif_query,
 validita_inizio, ente_proprietario_id,login_operazione)
(select
 tipo.flusso_elab_mif_tipo_id,209,190,'codice_ue',null,
 true,true,
 'flusso_ordinativi.mandato.informazioni_beneficiario.dati_a_disposizione_ente_beneficiario.altri_codici_identificativi',
 'mif_t_ordinativo_spesa_disp_ente_benef','mif_ord_dispe_codice_ue',
 null,true,
 'TRANSAZIONE_UE_SPESA',null,
 '2015-01-01 00:00:00',tipo.ente_proprietario_id,'admin'
 from mif_d_flusso_elaborato_tipo tipo
 where
-- tipo.flusso_elab_mif_tipo_code='MANDMIF_ABI36'
 tipo.flusso_elab_mif_tipo_code='MANDMIF'
 and   tipo.ente_proprietario_id=&ente
 );
 insert into mif_d_flusso_elaborato
(flusso_elab_mif_tipo_id,flusso_elab_mif_ordine,flusso_elab_mif_ordine_elab,flusso_elab_mif_code,flusso_elab_mif_desc,
 flusso_elab_mif_attivo,flusso_elab_mif_xml_out,
 flusso_elab_mif_code_padre,flusso_elab_mif_tabella,flusso_elab_mif_campo,
 flusso_elab_mif_default,flusso_elab_mif_elab,
 flusso_elab_mif_param,flusso_elab_mif_query,
 validita_inizio, ente_proprietario_id,login_operazione)
(select
 tipo.flusso_elab_mif_tipo_id,210,0,'cofog',null,
 true,true,
 'flusso_ordinativi.mandato.informazioni_beneficiario.dati_a_disposizione_ente_beneficiario.altri_codici_identificativi',
 null,null,
 null,false,
 null,null,
 '2015-01-01 00:00:00',tipo.ente_proprietario_id,'admin'
 from mif_d_flusso_elaborato_tipo tipo
 where
-- tipo.flusso_elab_mif_tipo_code='MANDMIF_ABI36'
 tipo.flusso_elab_mif_tipo_code='MANDMIF'
 and   tipo.ente_proprietario_id=&ente
 );

 insert into mif_d_flusso_elaborato
(flusso_elab_mif_tipo_id,flusso_elab_mif_ordine,flusso_elab_mif_ordine_elab,flusso_elab_mif_code,flusso_elab_mif_desc,
 flusso_elab_mif_attivo,flusso_elab_mif_xml_out,
 flusso_elab_mif_code_padre,flusso_elab_mif_tabella,flusso_elab_mif_campo,
 flusso_elab_mif_default,flusso_elab_mif_elab,
 flusso_elab_mif_param,flusso_elab_mif_query,
 validita_inizio, ente_proprietario_id,login_operazione)
(select
 tipo.flusso_elab_mif_tipo_id,211,191,'codice_cofog',null,
 true,true,
 'flusso_ordinativi.mandato.informazioni_beneficiario.dati_a_disposizione_ente_beneficiario.altri_codici_identificativi.cofog',
 'mif_t_ordinativo_spesa_disp_ente_benef','mif_ord_dispe_cofog_codice',
 null,true,
 'GRUPPO_COFOG',null,
 '2015-01-01 00:00:00',tipo.ente_proprietario_id,'admin'
 from mif_d_flusso_elaborato_tipo tipo
 where
-- tipo.flusso_elab_mif_tipo_code='MANDMIF_ABI36'
 tipo.flusso_elab_mif_tipo_code='MANDMIF'
 and   tipo.ente_proprietario_id=&ente
 );

 insert into mif_d_flusso_elaborato
(flusso_elab_mif_tipo_id,flusso_elab_mif_ordine,flusso_elab_mif_ordine_elab,flusso_elab_mif_code,flusso_elab_mif_desc,
 flusso_elab_mif_attivo,flusso_elab_mif_xml_out,
 flusso_elab_mif_code_padre,flusso_elab_mif_tabella,flusso_elab_mif_campo,
 flusso_elab_mif_default,flusso_elab_mif_elab,
 flusso_elab_mif_param,flusso_elab_mif_query,
 validita_inizio, ente_proprietario_id,login_operazione)
(select
 tipo.flusso_elab_mif_tipo_id,212,192,'importo_cofog',null,
 true,true,
 'flusso_ordinativi.mandato.informazioni_beneficiario.dati_a_disposizione_ente_beneficiario.altri_codici_identificativi.cofog',
 'mif_t_ordinativo_spesa_disp_ente_benef','mif_ord_dispe_cofog_imp',
 null,true,
 NULL,null,
 '2015-01-01 00:00:00',tipo.ente_proprietario_id,'admin'
 from mif_d_flusso_elaborato_tipo tipo
 where
-- tipo.flusso_elab_mif_tipo_code='MANDMIF_ABI36'
 tipo.flusso_elab_mif_tipo_code='MANDMIF'
 and   tipo.ente_proprietario_id=&ente
 );



---  UniIt

select * from mif_d_flusso_elaborato d
where d.ente_proprietario_id=&ente
and d.flusso_elab_mif_tipo_id in
(select t.flusso_elab_mif_tipo_id
 from mif_d_flusso_elaborato_tipo  t
 where t.ente_proprietario_id=d.ente_proprietario_id
and   t.flusso_elab_mif_tipo_code='MANDMIF')
--and   t.flusso_elab_mif_tipo_code='MANDMIF_ABI36' )
and   d.flusso_elab_mif_ordine>=234
order by d.flusso_elab_mif_ordine

insert into mif_d_flusso_elaborato
(flusso_elab_mif_tipo_id,flusso_elab_mif_ordine,flusso_elab_mif_ordine_elab,flusso_elab_mif_code,flusso_elab_mif_desc,flusso_elab_mif_attivo,flusso_elab_mif_xml_out,
 flusso_elab_mif_code_padre,flusso_elab_mif_tabella,flusso_elab_mif_campo,flusso_elab_mif_default,flusso_elab_mif_elab,flusso_elab_mif_param,flusso_elab_mif_query,
 validita_inizio, ente_proprietario_id,login_operazione)
(select
 tipo.flusso_elab_mif_tipo_id,234,0,'dati_a_disposizione_ente_beneficiario',null,false,false,'flusso_ordinativi.mandato.informazioni_beneficiario',null,null,null,false,null,null,'2015-01-01 00:00:00',
 tipo.ente_proprietario_id,'admin'
 from mif_d_flusso_elaborato_tipo tipo
 where
-- tipo.flusso_elab_mif_tipo_code='MANDMIF_ABI36'
 tipo.flusso_elab_mif_tipo_code='MANDMIF'
 and   tipo.ente_proprietario_id=&ente
 );

insert into mif_d_flusso_elaborato
(flusso_elab_mif_tipo_id,flusso_elab_mif_ordine,flusso_elab_mif_ordine_elab,flusso_elab_mif_code,flusso_elab_mif_desc,flusso_elab_mif_attivo,flusso_elab_mif_xml_out,
 flusso_elab_mif_code_padre,flusso_elab_mif_tabella,flusso_elab_mif_campo,flusso_elab_mif_default,flusso_elab_mif_elab,flusso_elab_mif_param,flusso_elab_mif_query,
 validita_inizio, ente_proprietario_id,login_operazione)
(select
 tipo.flusso_elab_mif_tipo_id,235,0,'altri_codici_identificativi',null,false,false,'flusso_ordinativi.mandato.informazioni_beneficiario.dati_a_disposizione_ente_beneficiario',null,null,null,false,null,
 'select * from mif_t_ordinativo_spesa_disp_ente_benef where ente_proprietario_id=:ente_proprietario_id and data_cancellazione is null and validita_fine is null and mif_ord_id=:mif_ord_id',
 '2015-01-01 00:00:00',tipo.ente_proprietario_id,'admin'
 from mif_d_flusso_elaborato_tipo tipo
 where
-- tipo.flusso_elab_mif_tipo_code='MANDMIF_ABI36'
 tipo.flusso_elab_mif_tipo_code='MANDMIF'
 and   tipo.ente_proprietario_id=&ente
 );

insert into mif_d_flusso_elaborato
(flusso_elab_mif_tipo_id,flusso_elab_mif_ordine,flusso_elab_mif_ordine_elab,flusso_elab_mif_code,flusso_elab_mif_desc,
 flusso_elab_mif_attivo,flusso_elab_mif_xml_out,
 flusso_elab_mif_code_padre,flusso_elab_mif_tabella,flusso_elab_mif_campo,
 flusso_elab_mif_default,flusso_elab_mif_elab,
 flusso_elab_mif_param,flusso_elab_mif_query,
 validita_inizio, ente_proprietario_id,login_operazione)
(select
 tipo.flusso_elab_mif_tipo_id,236,186,'codice_missione',null,
 false,false,
 'flusso_ordinativi.mandato.informazioni_beneficiario.dati_a_disposizione_ente_beneficiario.altri_codici_identificativi',
 'mif_t_ordinativo_spesa_disp_ente_benef','mif_ord_dispe_missione',
 null,true,
 'Spesa - MissioniProgrammi',null,
 '2015-01-01 00:00:00',tipo.ente_proprietario_id,'admin'
 from mif_d_flusso_elaborato_tipo tipo
 where
-- tipo.flusso_elab_mif_tipo_code='MANDMIF_ABI36'
 tipo.flusso_elab_mif_tipo_code='MANDMIF'
 and   tipo.ente_proprietario_id=&ente
 );

 insert into mif_d_flusso_elaborato
(flusso_elab_mif_tipo_id,flusso_elab_mif_ordine,flusso_elab_mif_ordine_elab,flusso_elab_mif_code,flusso_elab_mif_desc,
 flusso_elab_mif_attivo,flusso_elab_mif_xml_out,
 flusso_elab_mif_code_padre,flusso_elab_mif_tabella,flusso_elab_mif_campo,
 flusso_elab_mif_default,flusso_elab_mif_elab,
 flusso_elab_mif_param,flusso_elab_mif_query,
 validita_inizio, ente_proprietario_id,login_operazione)
(select
 tipo.flusso_elab_mif_tipo_id,237,187,'codice_programma',null,
 false,false,
 'flusso_ordinativi.mandato.informazioni_beneficiario.dati_a_disposizione_ente_beneficiario.altri_codici_identificativi',
 'mif_t_ordinativo_spesa_disp_ente_benef','mif_ord_dispe_programma',
 null,true,
 'PROGRAMMA',null,
 '2015-01-01 00:00:00',tipo.ente_proprietario_id,'admin'
 from mif_d_flusso_elaborato_tipo tipo
 where
-- tipo.flusso_elab_mif_tipo_code='MANDMIF_ABI36'
 tipo.flusso_elab_mif_tipo_code='MANDMIF'
 and   tipo.ente_proprietario_id=&ente
 );

  insert into mif_d_flusso_elaborato
(flusso_elab_mif_tipo_id,flusso_elab_mif_ordine,flusso_elab_mif_ordine_elab,flusso_elab_mif_code,flusso_elab_mif_desc,
 flusso_elab_mif_attivo,flusso_elab_mif_xml_out,
 flusso_elab_mif_code_padre,flusso_elab_mif_tabella,flusso_elab_mif_campo,
 flusso_elab_mif_default,flusso_elab_mif_elab,
 flusso_elab_mif_param,flusso_elab_mif_query,
 validita_inizio, ente_proprietario_id,login_operazione)
(select
 tipo.flusso_elab_mif_tipo_id,238,188,'codice_economico',null,
 false,false,
 'flusso_ordinativi.mandato.informazioni_beneficiario.dati_a_disposizione_ente_beneficiario.altri_codici_identificativi',
 'mif_t_ordinativo_spesa_disp_ente_benef','mif_ord_dispe_codice_economico',
 null,true,
 'OP',null,
 '2015-01-01 00:00:00',tipo.ente_proprietario_id,'admin'
 from mif_d_flusso_elaborato_tipo tipo
 where
-- tipo.flusso_elab_mif_tipo_code='MANDMIF_ABI36'
 tipo.flusso_elab_mif_tipo_code='MANDMIF'
 and   tipo.ente_proprietario_id=&ente
 );

  insert into mif_d_flusso_elaborato
(flusso_elab_mif_tipo_id,flusso_elab_mif_ordine,flusso_elab_mif_ordine_elab,flusso_elab_mif_code,flusso_elab_mif_desc,
 flusso_elab_mif_attivo,flusso_elab_mif_xml_out,
 flusso_elab_mif_code_padre,flusso_elab_mif_tabella,flusso_elab_mif_campo,
 flusso_elab_mif_default,flusso_elab_mif_elab,
 flusso_elab_mif_param,flusso_elab_mif_query,
 validita_inizio, ente_proprietario_id,login_operazione)
(select
 tipo.flusso_elab_mif_tipo_id,239,189,'importo_codice_economico',null,
 false,false,
 'flusso_ordinativi.mandato.informazioni_beneficiario.dati_a_disposizione_ente_beneficiario.altri_codici_identificativi',
 'mif_t_ordinativo_spesa_disp_ente_benef','mif_ord_dispe_codice_economico_imp',
 null,true,
 null,null,
 '2015-01-01 00:00:00',tipo.ente_proprietario_id,'admin'
 from mif_d_flusso_elaborato_tipo tipo
 where
-- tipo.flusso_elab_mif_tipo_code='MANDMIF_ABI36'
 tipo.flusso_elab_mif_tipo_code='MANDMIF'
 and   tipo.ente_proprietario_id=&ente
 );

  insert into mif_d_flusso_elaborato
(flusso_elab_mif_tipo_id,flusso_elab_mif_ordine,flusso_elab_mif_ordine_elab,flusso_elab_mif_code,flusso_elab_mif_desc,
 flusso_elab_mif_attivo,flusso_elab_mif_xml_out,
 flusso_elab_mif_code_padre,flusso_elab_mif_tabella,flusso_elab_mif_campo,
 flusso_elab_mif_default,flusso_elab_mif_elab,
 flusso_elab_mif_param,flusso_elab_mif_query,
 validita_inizio, ente_proprietario_id,login_operazione)
(select
 tipo.flusso_elab_mif_tipo_id,240,190,'codice_ue',null,
 false,false,
 'flusso_ordinativi.mandato.informazioni_beneficiario.dati_a_disposizione_ente_beneficiario.altri_codici_identificativi',
 'mif_t_ordinativo_spesa_disp_ente_benef','mif_ord_dispe_codice_ue',
 null,true,
 'TRANSAZIONE_UE_SPESA',null,
 '2015-01-01 00:00:00',tipo.ente_proprietario_id,'admin'
 from mif_d_flusso_elaborato_tipo tipo
 where
-- tipo.flusso_elab_mif_tipo_code='MANDMIF_ABI36'
 tipo.flusso_elab_mif_tipo_code='MANDMIF'
 and   tipo.ente_proprietario_id=&ente
 );
 insert into mif_d_flusso_elaborato
(flusso_elab_mif_tipo_id,flusso_elab_mif_ordine,flusso_elab_mif_ordine_elab,flusso_elab_mif_code,flusso_elab_mif_desc,
 flusso_elab_mif_attivo,flusso_elab_mif_xml_out,
 flusso_elab_mif_code_padre,flusso_elab_mif_tabella,flusso_elab_mif_campo,
 flusso_elab_mif_default,flusso_elab_mif_elab,
 flusso_elab_mif_param,flusso_elab_mif_query,
 validita_inizio, ente_proprietario_id,login_operazione)
(select
 tipo.flusso_elab_mif_tipo_id,250,0,'cofog',null,
 false,false,
 'flusso_ordinativi.mandato.informazioni_beneficiario.dati_a_disposizione_ente_beneficiario.altri_codici_identificativi',
 null,null,
 null,false,
 null,null,
 '2015-01-01 00:00:00',tipo.ente_proprietario_id,'admin'
 from mif_d_flusso_elaborato_tipo tipo
 where
-- tipo.flusso_elab_mif_tipo_code='MANDMIF_ABI36'
 tipo.flusso_elab_mif_tipo_code='MANDMIF'
 and   tipo.ente_proprietario_id=&ente
 );

 insert into mif_d_flusso_elaborato
(flusso_elab_mif_tipo_id,flusso_elab_mif_ordine,flusso_elab_mif_ordine_elab,flusso_elab_mif_code,flusso_elab_mif_desc,
 flusso_elab_mif_attivo,flusso_elab_mif_xml_out,
 flusso_elab_mif_code_padre,flusso_elab_mif_tabella,flusso_elab_mif_campo,
 flusso_elab_mif_default,flusso_elab_mif_elab,
 flusso_elab_mif_param,flusso_elab_mif_query,
 validita_inizio, ente_proprietario_id,login_operazione)
(select
 tipo.flusso_elab_mif_tipo_id,251,191,'codice_cofog',null,
 false,false,
 'flusso_ordinativi.mandato.informazioni_beneficiario.dati_a_disposizione_ente_beneficiario.altri_codici_identificativi.cofog',
 'mif_t_ordinativo_spesa_disp_ente_benef','mif_ord_dispe_cofog_codice',
 null,true,
 'GRUPPO_COFOG',null,
 '2015-01-01 00:00:00',tipo.ente_proprietario_id,'admin'
 from mif_d_flusso_elaborato_tipo tipo
 where
-- tipo.flusso_elab_mif_tipo_code='MANDMIF_ABI36'
 tipo.flusso_elab_mif_tipo_code='MANDMIF'
 and   tipo.ente_proprietario_id=&ente
 );

 insert into mif_d_flusso_elaborato
(flusso_elab_mif_tipo_id,flusso_elab_mif_ordine,flusso_elab_mif_ordine_elab,flusso_elab_mif_code,flusso_elab_mif_desc,
 flusso_elab_mif_attivo,flusso_elab_mif_xml_out,
 flusso_elab_mif_code_padre,flusso_elab_mif_tabella,flusso_elab_mif_campo,
 flusso_elab_mif_default,flusso_elab_mif_elab,
 flusso_elab_mif_param,flusso_elab_mif_query,
 validita_inizio, ente_proprietario_id,login_operazione)
(select
 tipo.flusso_elab_mif_tipo_id,252,192,'importo_cofog',null,
 false,false,
 'flusso_ordinativi.mandato.informazioni_beneficiario.dati_a_disposizione_ente_beneficiario.altri_codici_identificativi.cofog',
 'mif_t_ordinativo_spesa_disp_ente_benef','mif_ord_dispe_cofog_imp',
 null,true,
 NULL,null,
 '2015-01-01 00:00:00',tipo.ente_proprietario_id,'admin'
 from mif_d_flusso_elaborato_tipo tipo
 where
-- tipo.flusso_elab_mif_tipo_code='MANDMIF_ABI36'
 tipo.flusso_elab_mif_tipo_code='MANDMIF'
 and   tipo.ente_proprietario_id=&ente
 );

select * from mif_d_flusso_elaborato d
where d.ente_proprietario_id=&ente
and d.flusso_elab_mif_tipo_id in
(select t.flusso_elab_mif_tipo_id
 from mif_d_flusso_elaborato_tipo  t
 where t.ente_proprietario_id=d.ente_proprietario_id
and t.flusso_elab_mif_tipo_code='MANDMIF')
--and   t.flusso_elab_mif_tipo_code='MANDMIF_UNIIT' )
and   d.flusso_elab_mif_code='dati_a_disposizione_ente_beneficiario'
--and   d.flusso_elab_mif_ordine>=79
--and   d.flusso_elab_mif_ordine>=87
order by d.flusso_elab_mif_ordine

select * from mif_d_flusso_elaborato d
where
d.flusso_elab_mif_tipo_id in
(select t.flusso_elab_mif_tipo_id
 from mif_d_flusso_elaborato_tipo  t
 where t.ente_proprietario_id=d.ente_proprietario_id
and t.flusso_elab_mif_tipo_code='MANDMIF')
--and   t.flusso_elab_mif_tipo_code='MANDMIF_UNIIT' )
and   d.flusso_elab_mif_code='dati_a_disposizione_ente_beneficiario'
--and   d.flusso_elab_mif_ordine>=79
--and   d.flusso_elab_mif_ordine>=87
order by d.flusso_elab_mif_ordine



update mif_d_flusso_elaborato d set flusso_elab_mif_ordine_elab=186,flusso_elab_mif_elab=true
 from mif_d_flusso_elaborato_tipo tipo
 where
 --tipo.flusso_elab_mif_tipo_code='MANDMIF_UNIIT'
 tipo.flusso_elab_mif_tipo_code='MANDMIF'
 and    tipo.ente_proprietario_id=&ente
 and    d.flusso_elab_mif_tipo_id=tipo.flusso_elab_mif_tipo_id
-- and    d.flusso_elab_mif_ordine_elab>=87
 and   d.flusso_elab_mif_code='dati_a_disposizione_ente_beneficiario'

update mif_d_flusso_elaborato d set flusso_elab_mif_ordine_elab=186,flusso_elab_mif_elab=true
 from mif_d_flusso_elaborato_tipo tipo
 where
 tipo.flusso_elab_mif_tipo_code='MANDMIF'
 and    d.flusso_elab_mif_tipo_id=tipo.flusso_elab_mif_tipo_id
 and   d.flusso_elab_mif_code='dati_a_disposizione_ente_beneficiario'

update mif_d_flusso_elaborato d set flusso_elab_mif_ordine_elab=flusso_elab_mif_ordine_elab+1
 from mif_d_flusso_elaborato_tipo tipo
 where
 tipo.flusso_elab_mif_tipo_code='MANDMIF_UNIIT'
-- tipo.flusso_elab_mif_tipo_code='MANDMIF'
 and    tipo.ente_proprietario_id=&ente
 and    d.flusso_elab_mif_tipo_id=tipo.flusso_elab_mif_tipo_id
 and    d.flusso_elab_mif_ordine_elab>=186
 and   d.flusso_elab_mif_code!='dati_a_disposizione_ente_beneficiario'

 begin;
 update mif_d_flusso_elaborato d set flusso_elab_mif_ordine_elab=flusso_elab_mif_ordine_elab+1
 from mif_d_flusso_elaborato_tipo tipo
 where
 tipo.flusso_elab_mif_tipo_code='MANDMIF'
 and    d.flusso_elab_mif_tipo_id=tipo.flusso_elab_mif_tipo_id
 and    d.flusso_elab_mif_ordine_elab>=186
 and   d.flusso_elab_mif_code!='dati_a_disposizione_ente_beneficiario'
 and d.ente_proprietario_id!=2

begin;
 update mif_d_flusso_elaborato d set flusso_elab_mif_Campo='mif_ord_dispe_codice_missione'
 from mif_d_flusso_elaborato_tipo tipo
 where
 tipo.flusso_elab_mif_tipo_code='MANDMIF'
 and    d.flusso_elab_mif_tipo_id=tipo.flusso_elab_mif_tipo_id
 and    d.flusso_elab_mif_ordine_elab>=186
 and   d.flusso_elab_mif_code!='dati_a_disposizione_ente_beneficiario'
 and   d.flusso_elab_mif_code='codice_missione'
 and d.ente_proprietario_id!=2

 update mif_d_flusso_elaborato d set flusso_elab_mif_Campo='mif_ord_dispe_codice_programma'
 from mif_d_flusso_elaborato_tipo tipo
 where
 tipo.flusso_elab_mif_tipo_code='MANDMIF'
 and    d.flusso_elab_mif_tipo_id=tipo.flusso_elab_mif_tipo_id
 and    d.flusso_elab_mif_ordine_elab>=186
 and   d.flusso_elab_mif_code!='dati_a_disposizione_ente_beneficiario'
 and   d.flusso_elab_mif_code='codice_programma'
 and d.ente_proprietario_id!=2

begin;
 update mif_d_flusso_elaborato d set flusso_elab_mif_attivo=false,flusso_elab_mif_xml_out=false
 from mif_d_flusso_elaborato_tipo tipo
 where
 tipo.flusso_elab_mif_tipo_code='MANDMIF'
 and    d.flusso_elab_mif_tipo_id=tipo.flusso_elab_mif_tipo_id
 and   d.flusso_elab_mif_code='dati_a_disposizione_ente_mandato'
 and d.ente_proprietario_id=14

 update mif_d_flusso_elaborato d set flusso_elab_mif_attivo=false,flusso_elab_mif_xml_out=false
 from mif_d_flusso_elaborato_tipo tipo
 where
 tipo.flusso_elab_mif_tipo_code='MANDMIF'
 and    d.flusso_elab_mif_tipo_id=tipo.flusso_elab_mif_tipo_id
 and   d.flusso_elab_mif_code_padre like 'flusso_ordinativi.mandato.informazioni_beneficiario.dati_a_disposizione_ente_mandato%'
 and d.ente_proprietario_id=14

rollback;

  select * from mif_d_flusso_elaborato d
where
d.flusso_elab_mif_tipo_id in
(select t.flusso_elab_mif_tipo_id
 from mif_d_flusso_elaborato_tipo  t
 where t.ente_proprietario_id=d.ente_proprietario_id
and t.flusso_elab_mif_tipo_code='MANDMIF_UNIIT')
and d.ente_proprietario_id=2
order by d.flusso_elab_mif_ordine

 select * from mif_d_flusso_elaborato d
where
d.flusso_elab_mif_tipo_id in
(select t.flusso_elab_mif_tipo_id
 from mif_d_flusso_elaborato_tipo  t
 where t.ente_proprietario_id=d.ente_proprietario_id
and t.flusso_elab_mif_tipo_code='MANDMIF')
and    d.flusso_elab_mif_ordine_elab>=186
 and d.ente_proprietario_id!=2
order by d.ente_proprietario_id,d.flusso_elab_mif_ordine

select * from mif_d_flusso_elaborato d
where
d.flusso_elab_mif_tipo_id in
(select t.flusso_elab_mif_tipo_id
 from mif_d_flusso_elaborato_tipo  t
 where t.ente_proprietario_id=d.ente_proprietario_id
and t.flusso_elab_mif_tipo_code='MANDMIF_UNIIT')
--and    d.flusso_elab_mif_ordine_elab>=186
order by d.ente_proprietario_id,d.flusso_elab_mif_ordine

 select * from mif_d_flusso_elaborato d
where
d.flusso_elab_mif_tipo_id in
(select t.flusso_elab_mif_tipo_id
 from mif_d_flusso_elaborato_tipo  t
 where t.ente_proprietario_id=d.ente_proprietario_id
and t.flusso_elab_mif_tipo_code='MANDMIF_UNIIT')
and    d.flusso_elab_mif_ordine_elab=181
-- and d.ente_proprietario_id!=2
order by d.ente_proprietario_id,d.flusso_elab_mif_ordine



select * from mif_d_flusso_elaborato_tipo
where flusso_elab_mif_tipo_code like 'REVMIF%'



--- sepa_Credit_transfer ----------------------

--- ABI 36
begin;
insert into mif_d_flusso_elaborato
(flusso_elab_mif_tipo_id,flusso_elab_mif_ordine,flusso_elab_mif_ordine_elab,flusso_elab_mif_code,flusso_elab_mif_desc,
 flusso_elab_mif_attivo,flusso_elab_mif_xml_out,
 flusso_elab_mif_code_padre,flusso_elab_mif_tabella,flusso_elab_mif_campo,
 flusso_elab_mif_default,flusso_elab_mif_elab,
 flusso_elab_mif_param,flusso_elab_mif_query,
 validita_inizio, ente_proprietario_id,login_operazione)
(select
 tipo.flusso_elab_mif_tipo_id,114,194,'sepa_credit_transfer',null,
 true,true,
 'flusso_ordinativi.mandato.informazioni_beneficiario',
 null,null,
 null,true,
 '1|CB|SEPA',null,
 '2015-01-01 00:00:00',tipo.ente_proprietario_id,'admin'
 from mif_d_flusso_elaborato_tipo tipo
 where
-- tipo.flusso_elab_mif_tipo_code='MANDMIF_ABI36'
 tipo.flusso_elab_mif_tipo_code='MANDMIF'
 and   tipo.ente_proprietario_id=&ente
 );

 insert into mif_d_flusso_elaborato
(flusso_elab_mif_tipo_id,flusso_elab_mif_ordine,flusso_elab_mif_ordine_elab,flusso_elab_mif_code,flusso_elab_mif_desc,
 flusso_elab_mif_attivo,flusso_elab_mif_xml_out,
 flusso_elab_mif_code_padre,flusso_elab_mif_tabella,flusso_elab_mif_campo,
 flusso_elab_mif_default,flusso_elab_mif_elab,
 flusso_elab_mif_param,flusso_elab_mif_query,
 validita_inizio, ente_proprietario_id,login_operazione)
(select
 tipo.flusso_elab_mif_tipo_id,115,195,'iban',null,
 true,true,
 'flusso_ordinativi.mandato.informazioni_beneficiario.sepa_credit_transfer',
 'mif_t_ordinativo_spesa','mif_ord_sepa_iban_tr',
 null,true,
 null,null,
 '2015-01-01 00:00:00',tipo.ente_proprietario_id,'admin'
 from mif_d_flusso_elaborato_tipo tipo
 where
-- tipo.flusso_elab_mif_tipo_code='MANDMIF_ABI36'
 tipo.flusso_elab_mif_tipo_code='MANDMIF'
 and   tipo.ente_proprietario_id=&ente
 );

  insert into mif_d_flusso_elaborato
(flusso_elab_mif_tipo_id,flusso_elab_mif_ordine,flusso_elab_mif_ordine_elab,flusso_elab_mif_code,flusso_elab_mif_desc,
 flusso_elab_mif_attivo,flusso_elab_mif_xml_out,
 flusso_elab_mif_code_padre,flusso_elab_mif_tabella,flusso_elab_mif_campo,
 flusso_elab_mif_default,flusso_elab_mif_elab,
 flusso_elab_mif_param,flusso_elab_mif_query,
 validita_inizio, ente_proprietario_id,login_operazione)
(select
 tipo.flusso_elab_mif_tipo_id,116,196,'bic',null,
 true,true,
 'flusso_ordinativi.mandato.informazioni_beneficiario.sepa_credit_transfer',
 'mif_t_ordinativo_spesa','mif_ord_sepa_bic_tr',
 null,true,
 null,null,
 '2015-01-01 00:00:00',tipo.ente_proprietario_id,'admin'
 from mif_d_flusso_elaborato_tipo tipo
 where
-- tipo.flusso_elab_mif_tipo_code='MANDMIF_ABI36'
 tipo.flusso_elab_mif_tipo_code='MANDMIF'
 and   tipo.ente_proprietario_id=&ente
 );

   insert into mif_d_flusso_elaborato
(flusso_elab_mif_tipo_id,flusso_elab_mif_ordine,flusso_elab_mif_ordine_elab,flusso_elab_mif_code,flusso_elab_mif_desc,
 flusso_elab_mif_attivo,flusso_elab_mif_xml_out,
 flusso_elab_mif_code_padre,flusso_elab_mif_tabella,flusso_elab_mif_campo,
 flusso_elab_mif_default,flusso_elab_mif_elab,
 flusso_elab_mif_param,flusso_elab_mif_query,
 validita_inizio, ente_proprietario_id,login_operazione)
(select
 tipo.flusso_elab_mif_tipo_id,117,197,'identificativo_end_to_end',null,
 true,true,
 'flusso_ordinativi.mandato.informazioni_beneficiario.sepa_credit_transfer',
 'mif_t_ordinativo_spesa','mif_ord_sepa_id_end_tr',
 null,true,
 null,null,
 '2015-01-01 00:00:00',tipo.ente_proprietario_id,'admin'
 from mif_d_flusso_elaborato_tipo tipo
 where
-- tipo.flusso_elab_mif_tipo_code='MANDMIF_ABI36'
 tipo.flusso_elab_mif_tipo_code='MANDMIF'
 and   tipo.ente_proprietario_id=&ente
 );


 select * from mif_d_flusso_elaborato d
where d.ente_proprietario_id=&ente
and d.flusso_elab_mif_tipo_id in
(select t.flusso_elab_mif_tipo_id
 from mif_d_flusso_elaborato_tipo  t
 where t.ente_proprietario_id=d.ente_proprietario_id
and t.flusso_elab_mif_tipo_code='MANDMIF')
order by d.flusso_elab_mif_ordine

 update mif_d_flusso_elaborato m set flusso_elab_mif_ordine=flusso_elab_mif_ordine+4
 from mif_d_flusso_elaborato_tipo tipo
 where
	    tipo.flusso_elab_mif_tipo_code='MANDMIF'
  and   tipo.ente_proprietario_id=&ente
  and   m.flusso_elab_mif_tipo_id=tipo.flusso_elab_mif_tipo_id
  and   m.flusso_elab_mif_code not in ('identificativo_end_to_end','bic','iban','sepa_credit_transfer')
  and   m.flusso_elab_mif_ordine>=114;

--- UniIt
begin;
insert into mif_d_flusso_elaborato
(flusso_elab_mif_tipo_id,flusso_elab_mif_ordine,flusso_elab_mif_ordine_elab,flusso_elab_mif_code,flusso_elab_mif_desc,
 flusso_elab_mif_attivo,flusso_elab_mif_xml_out,
 flusso_elab_mif_code_padre,flusso_elab_mif_tabella,flusso_elab_mif_campo,
 flusso_elab_mif_default,flusso_elab_mif_elab,
 flusso_elab_mif_param,flusso_elab_mif_query,
 validita_inizio, ente_proprietario_id,login_operazione)
(select
 tipo.flusso_elab_mif_tipo_id,122,194,'sepa_credit_transfer',null,
 false,false,
 'flusso_ordinativi.mandato.informazioni_beneficiario',
 null,null,
 null,true,
 '1|CB|SEPA',null,
 '2015-01-01 00:00:00',tipo.ente_proprietario_id,'admin'
 from mif_d_flusso_elaborato_tipo tipo
 where
-- tipo.flusso_elab_mif_tipo_code='MANDMIF_ABI36'
-- tipo.flusso_elab_mif_tipo_code='MANDMIF_UNIIT'
tipo.flusso_elab_mif_tipo_code='MANDMIF'
 and   tipo.ente_proprietario_id=&ente
 );

 insert into mif_d_flusso_elaborato
(flusso_elab_mif_tipo_id,flusso_elab_mif_ordine,flusso_elab_mif_ordine_elab,flusso_elab_mif_code,flusso_elab_mif_desc,
 flusso_elab_mif_attivo,flusso_elab_mif_xml_out,
 flusso_elab_mif_code_padre,flusso_elab_mif_tabella,flusso_elab_mif_campo,
 flusso_elab_mif_default,flusso_elab_mif_elab,
 flusso_elab_mif_param,flusso_elab_mif_query,
 validita_inizio, ente_proprietario_id,login_operazione)
(select
 tipo.flusso_elab_mif_tipo_id,123,195,'iban',null,
 false,false,
 'flusso_ordinativi.mandato.informazioni_beneficiario.sepa_credit_transfer',
 'mif_t_ordinativo_spesa','mif_ord_sepa_iban_tr',
 null,true,
 null,null,
 '2015-01-01 00:00:00',tipo.ente_proprietario_id,'admin'
 from mif_d_flusso_elaborato_tipo tipo
 where
-- tipo.flusso_elab_mif_tipo_code='MANDMIF_ABI36'
-- tipo.flusso_elab_mif_tipo_code='MANDMIF_UNIIT'
tipo.flusso_elab_mif_tipo_code='MANDMIF'
 and   tipo.ente_proprietario_id=&ente
 );

  insert into mif_d_flusso_elaborato
(flusso_elab_mif_tipo_id,flusso_elab_mif_ordine,flusso_elab_mif_ordine_elab,flusso_elab_mif_code,flusso_elab_mif_desc,
 flusso_elab_mif_attivo,flusso_elab_mif_xml_out,
 flusso_elab_mif_code_padre,flusso_elab_mif_tabella,flusso_elab_mif_campo,
 flusso_elab_mif_default,flusso_elab_mif_elab,
 flusso_elab_mif_param,flusso_elab_mif_query,
 validita_inizio, ente_proprietario_id,login_operazione)
(select
 tipo.flusso_elab_mif_tipo_id,124,196,'bic',null,
 false,false,
 'flusso_ordinativi.mandato.informazioni_beneficiario.sepa_credit_transfer',
 'mif_t_ordinativo_spesa','mif_ord_sepa_bic_tr',
 null,true,
 null,null,
 '2015-01-01 00:00:00',tipo.ente_proprietario_id,'admin'
 from mif_d_flusso_elaborato_tipo tipo
 where
-- tipo.flusso_elab_mif_tipo_code='MANDMIF_ABI36'
-- tipo.flusso_elab_mif_tipo_code='MANDMIF_UNIIT'
tipo.flusso_elab_mif_tipo_code='MANDMIF'
 and   tipo.ente_proprietario_id=&ente
 );

   insert into mif_d_flusso_elaborato
(flusso_elab_mif_tipo_id,flusso_elab_mif_ordine,flusso_elab_mif_ordine_elab,flusso_elab_mif_code,flusso_elab_mif_desc,
 flusso_elab_mif_attivo,flusso_elab_mif_xml_out,
 flusso_elab_mif_code_padre,flusso_elab_mif_tabella,flusso_elab_mif_campo,
 flusso_elab_mif_default,flusso_elab_mif_elab,
 flusso_elab_mif_param,flusso_elab_mif_query,
 validita_inizio, ente_proprietario_id,login_operazione)
(select
 tipo.flusso_elab_mif_tipo_id,125,197,'identificativo_end_to_end',null,
 false,false,
 'flusso_ordinativi.mandato.informazioni_beneficiario.sepa_credit_transfer',
 'mif_t_ordinativo_spesa','mif_ord_sepa_id_end_tr',
 null,true,
 null,null,
 '2015-01-01 00:00:00',tipo.ente_proprietario_id,'admin'
 from mif_d_flusso_elaborato_tipo tipo
 where
-- tipo.flusso_elab_mif_tipo_code='MANDMIF_ABI36'
-- tipo.flusso_elab_mif_tipo_code='MANDMIF_UNIIT'
 tipo.flusso_elab_mif_tipo_code='MANDMIF'
 and   tipo.ente_proprietario_id=&ente
 );


 select * from mif_d_flusso_elaborato d
where d.ente_proprietario_id=&ente
and d.flusso_elab_mif_tipo_id in
(select t.flusso_elab_mif_tipo_id
 from mif_d_flusso_elaborato_tipo  t
 where t.ente_proprietario_id=d.ente_proprietario_id
and t.flusso_elab_mif_tipo_code='MANDMIF')
order by d.flusso_elab_mif_ordine

 update mif_d_flusso_elaborato m set flusso_elab_mif_ordine=flusso_elab_mif_ordine+4
 from mif_d_flusso_elaborato_tipo tipo
 where
	    tipo.flusso_elab_mif_tipo_code='MANDMIF'
  and   tipo.ente_proprietario_id=&ente
  and   m.flusso_elab_mif_tipo_id=tipo.flusso_elab_mif_tipo_id
  and   m.flusso_elab_mif_code not in ('identificativo_end_to_end','bic','iban','sepa_credit_transfer')
  and   m.flusso_elab_mif_ordine>=122;


rollback;



------ provvisori
-- ABI36
 select * from mif_d_flusso_elaborato d
where d.ente_proprietario_id=&ente
and d.flusso_elab_mif_tipo_id in
(select t.flusso_elab_mif_tipo_id
 from mif_d_flusso_elaborato_tipo  t
 where t.ente_proprietario_id=d.ente_proprietario_id
and t.flusso_elab_mif_tipo_code='MANDMIF')
order by d.flusso_elab_mif_ordine

begin;
insert into mif_d_flusso_elaborato
(flusso_elab_mif_tipo_id,flusso_elab_mif_ordine,flusso_elab_mif_ordine_elab,flusso_elab_mif_code,flusso_elab_mif_desc,
 flusso_elab_mif_attivo,flusso_elab_mif_xml_out,
 flusso_elab_mif_code_padre,flusso_elab_mif_tabella,flusso_elab_mif_campo,
 flusso_elab_mif_default,flusso_elab_mif_elab,
 flusso_elab_mif_param,flusso_elab_mif_query,
 validita_inizio, ente_proprietario_id,login_operazione)
(select
 tipo.flusso_elab_mif_tipo_id,127,0,'sospeso',null,
 true,true,
 'flusso_ordinativi.mandato.informazioni_beneficiario',
 null,null,
 null,false,
 null,'select * from mif_t_ordinativo_spesa_ricevute where ente_proprietario_id=:ente_proprietario_id and data_cancellazione is null and validita_fine is null and mif_ord_id=:mif_ord_id',
 '2015-01-01 00:00:00',tipo.ente_proprietario_id,'admin'
 from mif_d_flusso_elaborato_tipo tipo
 where
-- tipo.flusso_elab_mif_tipo_code='MANDMIF_ABI36'
-- tipo.flusso_elab_mif_tipo_code='MANDMIF_UNIIT'
 tipo.flusso_elab_mif_tipo_code='MANDMIF'
 and   tipo.ente_proprietario_id=&ente
 );

  update mif_d_flusso_elaborato m set flusso_elab_mif_ordine=flusso_elab_mif_ordine+1
 from mif_d_flusso_elaborato_tipo tipo
 where
	    tipo.flusso_elab_mif_tipo_code='MANDMIF'
  and   tipo.ente_proprietario_id=&ente
  and   m.flusso_elab_mif_tipo_id=tipo.flusso_elab_mif_tipo_id
  and   m.flusso_elab_mif_code!='sospeso'
  and   m.flusso_elab_mif_ordine>=127;

begin;

 select * from mif_d_flusso_elaborato d
where d.ente_proprietario_id=&ente
and d.flusso_elab_mif_tipo_id in
(select t.flusso_elab_mif_tipo_id
 from mif_d_flusso_elaborato_tipo  t
 where t.ente_proprietario_id=d.ente_proprietario_id
and t.flusso_elab_mif_tipo_code='MANDMIF')
order by d.flusso_elab_mif_ordine

    update mif_d_flusso_elaborato m set flusso_elab_mif_ordine=flusso_elab_mif_ordine-3
 from mif_d_flusso_elaborato_tipo tipo
 where
	    tipo.flusso_elab_mif_tipo_code='MANDMIF'
  and   tipo.ente_proprietario_id=&ente
  and   m.flusso_elab_mif_tipo_id=tipo.flusso_elab_mif_tipo_id
--  and   m.flusso_elab_mif_code!='sospeso'
  and   m.flusso_elab_mif_ordine>=143;

  update mif_d_flusso_elaborato m set
      flusso_elab_mif_ordine=128, flusso_elab_mif_code_padre='flusso_ordinativi.mandato.informazioni_beneficiario.sospeso'
  from mif_d_flusso_elaborato_tipo tipo
  where tipo.flusso_elab_mif_tipo_code='MANDMIF'
  and   tipo.ente_proprietario_id=&ente
  and   m.flusso_elab_mif_tipo_id=tipo.flusso_elab_mif_tipo_id
  and   m.flusso_elab_mif_code='flag_copertura';

   update mif_d_flusso_elaborato m set
      flusso_elab_mif_ordine=129, flusso_elab_mif_code='numero_provvisorio',
      flusso_elab_mif_attivo=true,flusso_elab_mif_xml_out=true,flusso_elab_mif_code_padre='flusso_ordinativi.mandato.informazioni_beneficiario.sospeso'
   from mif_d_flusso_elaborato_tipo tipo
   where tipo.flusso_elab_mif_tipo_code='MANDMIF'
  and   tipo.ente_proprietario_id=&ente
  and   m.flusso_elab_mif_tipo_id=tipo.flusso_elab_mif_tipo_id
  and   m.flusso_elab_mif_code='numero_ricevuta';

   update mif_d_flusso_elaborato m set
      flusso_elab_mif_ordine=130, flusso_elab_mif_code='importo_provvisorio',
      flusso_elab_mif_attivo=true,flusso_elab_mif_xml_out=true,flusso_elab_mif_code_padre='flusso_ordinativi.mandato.informazioni_beneficiario.sospeso'
   from mif_d_flusso_elaborato_tipo tipo
   where tipo.flusso_elab_mif_tipo_code='MANDMIF'
  and   tipo.ente_proprietario_id=&ente
  and   m.flusso_elab_mif_tipo_id=tipo.flusso_elab_mif_tipo_id
  and   m.flusso_elab_mif_code='importo_ricevuta';



 update mif_d_flusso_elaborato m set flusso_elab_mif_ordine=flusso_elab_mif_ordine+3
 from mif_d_flusso_elaborato_tipo tipo
 where
	    tipo.flusso_elab_mif_tipo_code='MANDMIF'
  and   tipo.ente_proprietario_id=&ente
  and   m.flusso_elab_mif_tipo_id=tipo.flusso_elab_mif_tipo_id
  and   m.flusso_elab_mif_code not in ('flag_copertura','numero_ricevuta','importo_ricevuta')
  and   m.flusso_elab_mif_ordine>=128;

begin;
  update mif_d_flusso_elaborato m set flusso_elab_mif_ordine=m1.flusso_elab_mif_ordine
  from mif_d_flusso_elaborato m1
  where m1.flusso_elab_mif_tipo_id=41
  and   m.flusso_elab_mif_tipo_id=39
  and   m.flusso_elab_mif_code=m1.flusso_elab_mif_code;

rollback;



begin;


 select * from mif_d_flusso_elaborato d
where d.ente_proprietario_id=&ente
and d.flusso_elab_mif_tipo_id in
(select t.flusso_elab_mif_tipo_id
 from mif_d_flusso_elaborato_tipo  t
 where t.ente_proprietario_id=d.ente_proprietario_id
and t.flusso_elab_mif_tipo_code='MANDMIF')
order by d.flusso_elab_mif_ordine

 select * from mif_d_flusso_elaborato d
where d.ente_proprietario_id=&ente
and d.flusso_elab_mif_code='importo_ritenute'
and d.flusso_elab_mif_tipo_id in
(select t.flusso_elab_mif_tipo_id
 from mif_d_flusso_elaborato_tipo  t
 where t.ente_proprietario_id=d.ente_proprietario_id
and t.flusso_elab_mif_tipo_code='MANDMIF')


  update mif_d_flusso_elaborato m set flusso_elab_mif_ordine=flusso_elab_mif_ordine+7
 from mif_d_flusso_elaborato_tipo tipo
 where
	    tipo.flusso_elab_mif_tipo_code='MANDMIF'
  and   tipo.ente_proprietario_id=&ente
  and   m.flusso_elab_mif_tipo_id=tipo.flusso_elab_mif_tipo_id
  and   m.flusso_elab_mif_ordine>=136;

  update mif_d_flusso_elaborato m set flusso_elab_mif_ordine=flusso_elab_mif_ordine-7
 from mif_d_flusso_elaborato_tipo tipo
 where
	    tipo.flusso_elab_mif_tipo_code='MANDMIF'
  and   tipo.ente_proprietario_id=&ente
  and   m.flusso_elab_mif_tipo_id=tipo.flusso_elab_mif_tipo_id
  and   m.flusso_elab_mif_ordine>=125;

-----
--- query
-- select * from mif_t_ordinativo_spesa where mif_ord_flusso_elab_mif_id=:mif_ord_flusso_elab_mif_id and data_cancellazione is null and validita_fine is null order by mif_ord_anno, mif_ord_numero::integer LIMIT :limitOrdinativi OFFSET :offsetOrdinativi




select  d.ente_proprietario_id,d.flusso_elab_mif_code,d.flusso_elab_mif_query
 from mif_d_flusso_elaborato d
where
d.flusso_elab_mif_code_padre is null
--d.flusso_elab_mif_code like 'Pacchetto%'
and d.flusso_elab_mif_tipo_id in
(select t.flusso_elab_mif_tipo_id
 from mif_d_flusso_elaborato_tipo  t
 where t.ente_proprietario_id=d.ente_proprietario_id
and   t.flusso_elab_mif_tipo_code='REVMIF')
--and   t.flusso_elab_mif_tipo_code='REVMIF')
--and   t.flusso_elab_mif_tipo_code='MANDMIF_ABI36' )
order by d.ente_proprietario_id



----- REVERSALI

begin;
 update mif_d_flusso_elaborato m set flusso_elab_mif_ordine=flusso_elab_mif_ordine+1
 from mif_d_flusso_elaborato_tipo tipo
 where
	    tipo.flusso_elab_mif_tipo_code='REVMIF'
  and   tipo.ente_proprietario_id=&ente
  and   m.flusso_elab_mif_tipo_id=tipo.flusso_elab_mif_tipo_id
  and   m.flusso_elab_mif_code!='destinazione'
  and   m.flusso_elab_mif_ordine>=34;


  select * from mif_d_flusso_elaborato d
where d.ente_proprietario_id=&ente
--and d.flusso_elab_mif_attivo=true
--and d.flusso_elab_mif_elab=false
--and d.flusso_elab_mif_ordine_elab=35
--and d.flusso_elab_mif_code='codice_fiscale_versante'
and d.flusso_elab_mif_tipo_id in
(select t.flusso_elab_mif_tipo_id
 from mif_d_flusso_elaborato_tipo  t
 where t.ente_proprietario_id=d.ente_proprietario_id
and   t.flusso_elab_mif_tipo_code='REVMIF_UNIIT')
--and   t.flusso_elab_mif_tipo_code='MANDMIF_ABI36' )
order by d.flusso_elab_mif_ordine


--- dati_a_disposizione_ente_versante

-- ABI36

begin;
insert into mif_d_flusso_elaborato
(flusso_elab_mif_tipo_id,flusso_elab_mif_ordine,flusso_elab_mif_ordine_elab,flusso_elab_mif_code,flusso_elab_mif_desc,
 flusso_elab_mif_attivo,flusso_elab_mif_xml_out,
 flusso_elab_mif_code_padre,flusso_elab_mif_tabella,flusso_elab_mif_campo,
 flusso_elab_mif_default,flusso_elab_mif_elab,
 flusso_elab_mif_param,flusso_elab_mif_query,
 validita_inizio, ente_proprietario_id,login_operazione)
(select
 tipo.flusso_elab_mif_tipo_id,115,95,'dati_a_disposizione_ente_versante',null,
 true,true,
 'flusso_ordinativi.reversale.informazioni_versante',
 null,null,
 null,true,
 null,null,
 '2015-01-01 00:00:00',tipo.ente_proprietario_id,'admin'
 from mif_d_flusso_elaborato_tipo tipo
 where
 tipo.flusso_elab_mif_tipo_code='REVMIF'
 and   tipo.ente_proprietario_id=&ente
 );


insert into mif_d_flusso_elaborato
(flusso_elab_mif_tipo_id,flusso_elab_mif_ordine,flusso_elab_mif_ordine_elab,flusso_elab_mif_code,flusso_elab_mif_desc,
 flusso_elab_mif_attivo,flusso_elab_mif_xml_out,
 flusso_elab_mif_code_padre,flusso_elab_mif_tabella,flusso_elab_mif_campo,
 flusso_elab_mif_default,flusso_elab_mif_elab,
 flusso_elab_mif_param,flusso_elab_mif_query,
 validita_inizio, ente_proprietario_id,login_operazione)
(select
 tipo.flusso_elab_mif_tipo_id,116,0,'altri_codici_identificativi',null,
 true,true,
 'flusso_ordinativi.reversale.informazioni_versante.dati_a_disposizione_ente_versante',
 null,null,
 null,false,
 null,'select * from mif_t_ordinativo_entrata_disp_ente_vers where ente_proprietario_id=:ente_proprietario_id and data_cancellazione is null and validita_fine is null and mif_ord_id=:mif_ord_id',
 '2015-01-01 00:00:00',tipo.ente_proprietario_id,'admin'
 from mif_d_flusso_elaborato_tipo tipo
 where
 tipo.flusso_elab_mif_tipo_code='REVMIF'
 and   tipo.ente_proprietario_id=&ente
 );

insert into mif_d_flusso_elaborato
(flusso_elab_mif_tipo_id,flusso_elab_mif_ordine,flusso_elab_mif_ordine_elab,flusso_elab_mif_code,flusso_elab_mif_desc,
 flusso_elab_mif_attivo,flusso_elab_mif_xml_out,
 flusso_elab_mif_code_padre,flusso_elab_mif_tabella,flusso_elab_mif_campo,
 flusso_elab_mif_default,flusso_elab_mif_elab,
 flusso_elab_mif_param,flusso_elab_mif_query,
 validita_inizio, ente_proprietario_id,login_operazione)
(select
 tipo.flusso_elab_mif_tipo_id,117,96,'codice_economico',null,
 true,true,
 'flusso_ordinativi.reversale.informazioni_versante.dati_a_disposizione_ente_versante.altri_codici_identificativi',
 'mif_t_ordinativo_entrata_disp_ente_vers','mif_ord_dispe_codice_ecomico',
 null,true,
 'OI',null,
 '2015-01-01 00:00:00',tipo.ente_proprietario_id,'admin'
 from mif_d_flusso_elaborato_tipo tipo
 where
 tipo.flusso_elab_mif_tipo_code='REVMIF'
 and   tipo.ente_proprietario_id=&ente
 );

insert into mif_d_flusso_elaborato
(flusso_elab_mif_tipo_id,flusso_elab_mif_ordine,flusso_elab_mif_ordine_elab,flusso_elab_mif_code,flusso_elab_mif_desc,
 flusso_elab_mif_attivo,flusso_elab_mif_xml_out,
 flusso_elab_mif_code_padre,flusso_elab_mif_tabella,flusso_elab_mif_campo,
 flusso_elab_mif_default,flusso_elab_mif_elab,
 flusso_elab_mif_param,flusso_elab_mif_query,
 validita_inizio, ente_proprietario_id,login_operazione)
(select
 tipo.flusso_elab_mif_tipo_id,118,97,'importo_codice_economico',null,
 true,true,
 'flusso_ordinativi.reversale.informazioni_versante.dati_a_disposizione_ente_versante.altri_codici_identificativi',
 'mif_t_ordinativo_entrata_disp_ente_vers','mif_ord_dispe_codice_ecomico_imp',
 null,true,
 null,null,
 '2015-01-01 00:00:00',tipo.ente_proprietario_id,'admin'
 from mif_d_flusso_elaborato_tipo tipo
 where
 tipo.flusso_elab_mif_tipo_code='REVMIF'
 and   tipo.ente_proprietario_id=&ente
 );

insert into mif_d_flusso_elaborato
(flusso_elab_mif_tipo_id,flusso_elab_mif_ordine,flusso_elab_mif_ordine_elab,flusso_elab_mif_code,flusso_elab_mif_desc,
 flusso_elab_mif_attivo,flusso_elab_mif_xml_out,
 flusso_elab_mif_code_padre,flusso_elab_mif_tabella,flusso_elab_mif_campo,
 flusso_elab_mif_default,flusso_elab_mif_elab,
 flusso_elab_mif_param,flusso_elab_mif_query,
 validita_inizio, ente_proprietario_id,login_operazione)
(select
 tipo.flusso_elab_mif_tipo_id,119,98,'codice_ue',null,
 true,true,
 'flusso_ordinativi.reversale.informazioni_versante.dati_a_disposizione_ente_versante.altri_codici_identificativi',
 'mif_t_ordinativo_entrata_disp_ente_vers','mif_ord_dispe_codice_ue',
 null,true,
 'TRANSAZIONE_UE_ENTRATA',null,
 '2015-01-01 00:00:00',tipo.ente_proprietario_id,'admin'
 from mif_d_flusso_elaborato_tipo tipo
 where
 tipo.flusso_elab_mif_tipo_code='REVMIF'
 and   tipo.ente_proprietario_id=&ente
 );

insert into mif_d_flusso_elaborato
(flusso_elab_mif_tipo_id,flusso_elab_mif_ordine,flusso_elab_mif_ordine_elab,flusso_elab_mif_code,flusso_elab_mif_desc,
 flusso_elab_mif_attivo,flusso_elab_mif_xml_out,
 flusso_elab_mif_code_padre,flusso_elab_mif_tabella,flusso_elab_mif_campo,
 flusso_elab_mif_default,flusso_elab_mif_elab,
 flusso_elab_mif_param,flusso_elab_mif_query,
 validita_inizio, ente_proprietario_id,login_operazione)
(select
 tipo.flusso_elab_mif_tipo_id,120,99,'codice_entrata',null,
 true,true,
 'flusso_ordinativi.reversale.informazioni_versante.dati_a_disposizione_ente_versante.altri_codici_identificativi',
 'mif_t_ordinativo_entrata_disp_ente_vers','mif_ord_dispe_codice_entrata',
 null,true,
 'RICORRENTE_ENTRATA',null,
 '2015-01-01 00:00:00',tipo.ente_proprietario_id,'admin'
 from mif_d_flusso_elaborato_tipo tipo
 where
 tipo.flusso_elab_mif_tipo_code='REVMIF'
 and   tipo.ente_proprietario_id=&ente
 );



select * from mif_d_flusso_elaborato d
where d.ente_proprietario_id=&ente
and d.flusso_elab_mif_tipo_id in
(select t.flusso_elab_mif_tipo_id
 from mif_d_flusso_elaborato_tipo  t
 where t.ente_proprietario_id=d.ente_proprietario_id
and   t.flusso_elab_mif_tipo_code='REVMIF')
order by d.flusso_elab_mif_ordine


----------- UniIt

-- caricato solo per REGP - fare anche per gli altri
begin;
insert into mif_d_flusso_elaborato
(flusso_elab_mif_tipo_id,flusso_elab_mif_ordine,flusso_elab_mif_ordine_elab,flusso_elab_mif_code,flusso_elab_mif_desc,
 flusso_elab_mif_attivo,flusso_elab_mif_xml_out,
 flusso_elab_mif_code_padre,flusso_elab_mif_tabella,flusso_elab_mif_campo,
 flusso_elab_mif_default,flusso_elab_mif_elab,
 flusso_elab_mif_param,flusso_elab_mif_query,
 validita_inizio, ente_proprietario_id,login_operazione)
(select
 tipo.flusso_elab_mif_tipo_id,135,95,'dati_a_disposizione_ente_versante',null,
 false,false,
 'flusso_ordinativi.reversale.informazioni_versante',
 null,null,
 null,true,
 null,null,
 '2015-01-01 00:00:00',tipo.ente_proprietario_id,'admin'
 from mif_d_flusso_elaborato_tipo tipo
 where
 tipo.flusso_elab_mif_tipo_code='REVMIF'
 and   tipo.ente_proprietario_id=&ente
 );


insert into mif_d_flusso_elaborato
(flusso_elab_mif_tipo_id,flusso_elab_mif_ordine,flusso_elab_mif_ordine_elab,flusso_elab_mif_code,flusso_elab_mif_desc,
 flusso_elab_mif_attivo,flusso_elab_mif_xml_out,
 flusso_elab_mif_code_padre,flusso_elab_mif_tabella,flusso_elab_mif_campo,
 flusso_elab_mif_default,flusso_elab_mif_elab,
 flusso_elab_mif_param,flusso_elab_mif_query,
 validita_inizio, ente_proprietario_id,login_operazione)
(select
 tipo.flusso_elab_mif_tipo_id,136,0,'altri_codici_identificativi',null,
 false,false,
 'flusso_ordinativi.reversale.informazioni_versante.dati_a_disposizione_ente_versante',
 null,null,
 null,false,
 null,'select * from mif_t_ordinativo_entrata_disp_ente_vers where ente_proprietario_id=:ente_proprietario_id and data_cancellazione is null and validita_fine is null and mif_ord_id=:mif_ord_id',
 '2015-01-01 00:00:00',tipo.ente_proprietario_id,'admin'
 from mif_d_flusso_elaborato_tipo tipo
 where
 tipo.flusso_elab_mif_tipo_code='REVMIF'
 and   tipo.ente_proprietario_id=&ente
 );

insert into mif_d_flusso_elaborato
(flusso_elab_mif_tipo_id,flusso_elab_mif_ordine,flusso_elab_mif_ordine_elab,flusso_elab_mif_code,flusso_elab_mif_desc,
 flusso_elab_mif_attivo,flusso_elab_mif_xml_out,
 flusso_elab_mif_code_padre,flusso_elab_mif_tabella,flusso_elab_mif_campo,
 flusso_elab_mif_default,flusso_elab_mif_elab,
 flusso_elab_mif_param,flusso_elab_mif_query,
 validita_inizio, ente_proprietario_id,login_operazione)
(select
 tipo.flusso_elab_mif_tipo_id,137,96,'codice_economico',null,
 false,false,
 'flusso_ordinativi.reversale.informazioni_versante.dati_a_disposizione_ente_versante.altri_codici_identificativi',
 'mif_t_ordinativo_entrata_disp_ente_vers','mif_ord_dispe_codice_ecomico',
 null,true,
 'OI',null,
 '2015-01-01 00:00:00',tipo.ente_proprietario_id,'admin'
 from mif_d_flusso_elaborato_tipo tipo
 where
 tipo.flusso_elab_mif_tipo_code='REVMIF'
 and   tipo.ente_proprietario_id=&ente
 );

insert into mif_d_flusso_elaborato
(flusso_elab_mif_tipo_id,flusso_elab_mif_ordine,flusso_elab_mif_ordine_elab,flusso_elab_mif_code,flusso_elab_mif_desc,
 flusso_elab_mif_attivo,flusso_elab_mif_xml_out,
 flusso_elab_mif_code_padre,flusso_elab_mif_tabella,flusso_elab_mif_campo,
 flusso_elab_mif_default,flusso_elab_mif_elab,
 flusso_elab_mif_param,flusso_elab_mif_query,
 validita_inizio, ente_proprietario_id,login_operazione)
(select
 tipo.flusso_elab_mif_tipo_id,138,97,'importo_codice_economico',null,
 false,false,
 'flusso_ordinativi.reversale.informazioni_versante.dati_a_disposizione_ente_versante.altri_codici_identificativi',
 'mif_t_ordinativo_entrata_disp_ente_vers','mif_ord_dispe_codice_ecomico_imp',
 null,true,
 null,null,
 '2015-01-01 00:00:00',tipo.ente_proprietario_id,'admin'
 from mif_d_flusso_elaborato_tipo tipo
 where
 tipo.flusso_elab_mif_tipo_code='REVMIF'
 and   tipo.ente_proprietario_id=&ente
 );

insert into mif_d_flusso_elaborato
(flusso_elab_mif_tipo_id,flusso_elab_mif_ordine,flusso_elab_mif_ordine_elab,flusso_elab_mif_code,flusso_elab_mif_desc,
 flusso_elab_mif_attivo,flusso_elab_mif_xml_out,
 flusso_elab_mif_code_padre,flusso_elab_mif_tabella,flusso_elab_mif_campo,
 flusso_elab_mif_default,flusso_elab_mif_elab,
 flusso_elab_mif_param,flusso_elab_mif_query,
 validita_inizio, ente_proprietario_id,login_operazione)
(select
 tipo.flusso_elab_mif_tipo_id,139,98,'codice_ue',null,
 false,false,
 'flusso_ordinativi.reversale.informazioni_versante.dati_a_disposizione_ente_versante.altri_codici_identificativi',
 'mif_t_ordinativo_entrata_disp_ente_vers','mif_ord_dispe_codice_ue',
 null,true,
 'TRANSAZIONE_UE_ENTRATA',null,
 '2015-01-01 00:00:00',tipo.ente_proprietario_id,'admin'
 from mif_d_flusso_elaborato_tipo tipo
 where
 tipo.flusso_elab_mif_tipo_code='REVMIF'
 and   tipo.ente_proprietario_id=&ente
 );

insert into mif_d_flusso_elaborato
(flusso_elab_mif_tipo_id,flusso_elab_mif_ordine,flusso_elab_mif_ordine_elab,flusso_elab_mif_code,flusso_elab_mif_desc,
 flusso_elab_mif_attivo,flusso_elab_mif_xml_out,
 flusso_elab_mif_code_padre,flusso_elab_mif_tabella,flusso_elab_mif_campo,
 flusso_elab_mif_default,flusso_elab_mif_elab,
 flusso_elab_mif_param,flusso_elab_mif_query,
 validita_inizio, ente_proprietario_id,login_operazione)
(select
 tipo.flusso_elab_mif_tipo_id,140,99,'codice_entrata',null,
 false,false,
 'flusso_ordinativi.reversale.informazioni_versante.dati_a_disposizione_ente_versante.altri_codici_identificativi',
 'mif_t_ordinativo_entrata_disp_ente_vers','mif_ord_dispe_codice_entrata',
 null,true,
 'RICORRENTE_ENTRATA',null,
 '2015-01-01 00:00:00',tipo.ente_proprietario_id,'admin'
 from mif_d_flusso_elaborato_tipo tipo
 where
 tipo.flusso_elab_mif_tipo_code='REVMIF'
 and   tipo.ente_proprietario_id=&ente
 );


select * from mif_d_flusso_elaborato d
where d.ente_proprietario_id=&ente
and d.flusso_elab_mif_tipo_id in
(select t.flusso_elab_mif_tipo_id
 from mif_d_flusso_elaborato_tipo  t
 where t.ente_proprietario_id=d.ente_proprietario_id
and   t.flusso_elab_mif_tipo_code='REVMIF')
order by d.flusso_elab_mif_ordine