/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
--elaborazione ammortamenti
drop table if exists siac_r_cespiti_cespiti_elab_ammortamenti;
drop table if exists siac_t_elab_ammortamenti_dett;
drop table if exists siac_t_elab_ammortamenti;

drop table if exists siac_r_cespiti_dismissioni_prima_nota;
drop table if exists siac_r_cespiti_variazione_prima_nota;
drop table if exists siac_r_cespiti_prima_nota;46 3 2
drop table if exists siac_r_pn_prov_accettazione_stato;
drop table if exists siac_r_pn_def_accettazione_stato;

--storicizzazione tipo bene e categoria
drop table if exists siac_r_cespiti_bene_tipo_conto_patr_cat;
drop table if exists siac_r_cespiti_categoria_aliquota_calcolo_tipo;

--ammortamento
drop table if exists siac_t_cespiti_ammortamento_dett;
drop table if exists siac_t_cespiti_ammortamento;

drop table if exists siac_t_cespiti_variazione;
drop table if exists siac_t_cespiti_num_inventario;
drop table if exists siac_t_cespiti;
drop table if exists siac_t_cespiti_elenco_dismissioni_num;
drop table if exists siac_t_cespiti_dismissioni;

drop table if exists siac_d_cespiti_bene_tipo;
drop table if exists siac_d_pn_def_accettazione_stato;
drop table if exists siac_d_pn_prov_accettazione_stato;

--stati
drop table if exists siac_d_cespiti_variazione_stato;
drop table if exists siac_d_cespiti_dismissioni_stato;

--codifiche
drop table if exists siac_d_cespiti_classificazione_giuridica;
drop table if exists siac_d_cespiti_categoria_calcolo_tipo;
