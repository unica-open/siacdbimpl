/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/



CREATE SEQUENCE siac.siac_bko_spostamenti_id_seq
	INCREMENT BY 1
	MINVALUE 1
	MAXVALUE 9223372036854775807
	START 1;
	
delete from siac_bko_regmovfin_prima_nota_documento;
delete from siac_bko_sposta_ordinativo_inc;
delete from siac_bko_sposta_ordinativo_pag_liquidazione;
delete from siac_bko_sposta_regmovfin_prima_nota;


alter table siac_bko_regmovfin_prima_nota_documento add  bko_spostamenti_id integer not null;
alter table siac_bko_sposta_ordinativo_inc add  bko_spostamenti_id integer not null;

alter table siac_bko_sposta_ordinativo_pag_liquidazione add  bko_spostamenti_id integer not null;
alter table siac_bko_sposta_regmovfin_prima_nota add  bko_spostamenti_id integer not null;



