/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
select *
from mif_t_flusso_elaborato mif
where mif.ente_proprietario_id=5
order by mif.flusso_elab_mif_id desc

/*Ciao,
l'errore segnalato è dovuto a una query presente nella function (interna) fnc_mif_ordinativo_spesa, precisamente alla riga 1247.
L'errore è dovuto alla condizione and rel.validita_fine is null.
La modalità di pagamento associata all'ordinativo in questione (modpag_id=172497) ha una validita_fine futura = 27/12/2019 (sulla tabella siac_r_soggrel_modpag soggrelmpag_id=385).
Per valutare se un record è valido bisogna vedere se la data alla quale si fa il test è compresa tra validità inizio e validità fine:

and now() between rel.validita_inizio and coalesce(rel.validita_fine, now())

E' necessario quindi correggere la function.*/

messaggiorisultato = INVIO ORDINATIVI DI SPESA AL MIF.LETTURA DATI ORDINATIVO NUMERO=827 ANNOBILANCIO=2018 ORD_ID=172497 MIF_ORD_ID=113678. LETTURA MDP ORDINATIVO DI SPESA PER TIPO FLUSSO MANDMIF.ERRORE: ERRORE IN LETTURA SIAC_T_MODPAG. 1.

select *
from siac_t_modpag mdp
where mdp.ente_proprietario_id=4
and   mdp.modpag_id=172497

select *
from siac_v_bko_ordinativo_op_valido op
where op.ente_proprietario_id=4
and   op.ord_id=172497

-- soggetto_relaz_id=1000000398

select *
from siac_r_soggrel_modpag r
where r.soggetto_relaz_id=1000000398


Codice	2761
Ragione Sociale	EDISON ENERGIA S.P.A.
Partita IVA	08526440154
Cod. Fiscale	08526440154
Modalità di pagamento	Tipo accredito: CSI - cessione dell'incasso - Soggetto ricevente: 100172 - Tipo accredito: CD - CC BANCARIO DEDICATO