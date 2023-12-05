/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
-- 24.01.2018 Sofia x rilascio siac-5765

-- 08.C)
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (158,'codice_operatore',NULL,true,'flusso_ordinativi.ordinativi.mandato.dati_a_disposizione_ente_mandato','mif_t_ordinativo_spesa','mif_ord_codice_atto_contabile',NULL,true,null,'2017-01-01',2,'admin',135,NULL,true,(select mif.flusso_elab_mif_tipo_id
				 from mif_d_flusso_elaborato_tipo mif
				 where mif.ente_proprietario_id=2
				 and  mif.flusso_elab_mif_tipo_code='MANDMIF_SPLUS' ));

-- 08.C)
INSERT INTO mif_d_flusso_elaborato (
            flusso_elab_mif_ordine,
            flusso_elab_mif_code, flusso_elab_mif_desc, flusso_elab_mif_attivo,
            flusso_elab_mif_code_padre, flusso_elab_mif_tabella, flusso_elab_mif_campo,
            flusso_elab_mif_default, flusso_elab_mif_elab, flusso_elab_mif_param,
            validita_inizio, ente_proprietario_id, login_operazione, flusso_elab_mif_ordine_elab,
            flusso_elab_mif_query, flusso_elab_mif_xml_out,flusso_elab_mif_tipo_id) values (96,'codice_operatore',NULL,true,'flusso_ordinativi.ordinativi.reversale.dati_a_disposizione_ente_reversale','mif_t_ordinativo_entrata','mif_ord_codice_atto_contabile',NULL,true,null,'2017-01-01',2,'admin',73,NULL,true,(select mif.flusso_elab_mif_tipo_id
				 from mif_d_flusso_elaborato_tipo mif
				 where mif.ente_proprietario_id=2
				 and  mif.flusso_elab_mif_tipo_code='REVMIF_SPLUS' ));



-- 08.B)
update mif_d_flusso_elaborato mif
set    flusso_elab_mif_default='SENZA PROVVEDIMENTO'
from mif_d_flusso_elaborato_tipo tipo
where tipo.ente_proprietario_id=2
and   tipo.flusso_elab_mif_tipo_code='MANDMIF_SPLUS'
and   mif.flusso_elab_mif_tipo_id=tipo.flusso_elab_mif_tipo_id
and   mif.flusso_elab_mif_code='estremi_provvedimento_autorizzativo';

-- 08.A)
update mif_d_flusso_elaborato mif
set    flusso_elab_mif_param='ANALOGICO|9999999999999999'
from mif_d_flusso_elaborato_tipo tipo
where tipo.ente_proprietario_id=2
and   tipo.flusso_elab_mif_tipo_code in ('REVMIF_SPLUS','MANDMIF_SPLUS')
and   mif.flusso_elab_mif_tipo_id=tipo.flusso_elab_mif_tipo_id
and   mif.flusso_elab_mif_code ='codice_fiscale_emittente_siope';

-- 08.E)
update mif_d_flusso_elaborato mif
set    flusso_elab_mif_param='DISPOSIZIONE DOCUMENTO ESTERNO|BONIFICO ESTERO EURO|STI|CCP'
from mif_d_flusso_elaborato_tipo tipo
where tipo.ente_proprietario_id=2
and   tipo.flusso_elab_mif_tipo_code='MANDMIF_SPLUS'
and   mif.flusso_elab_mif_tipo_id=tipo.flusso_elab_mif_tipo_id
and   mif.flusso_elab_mif_code='riferimento_documento_esterno';

-- 08.E)
update mif_d_flusso_elaborato mif
set    flusso_elab_mif_param='CB|IT'
from mif_d_flusso_elaborato_tipo tipo
where tipo.ente_proprietario_id=2
and   tipo.flusso_elab_mif_tipo_code='MANDMIF_SPLUS'
and   mif.flusso_elab_mif_tipo_id=tipo.flusso_elab_mif_tipo_id
and   mif.flusso_elab_mif_code='numero_conto_corrente_beneficiario';


--  fnc_mif_ordinativo_documenti_splus
--  fnc_mif_ordinativo_spesa_splus
--  fnc_mif_ordinativo_entrata_splus