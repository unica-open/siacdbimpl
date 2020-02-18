/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
create or replace VIEW siac_v_bko_kill_pid as
select 'select * from pg_terminate_backend('||pid||');' from pg_stat_activity 
where datname='TSTBIL1';