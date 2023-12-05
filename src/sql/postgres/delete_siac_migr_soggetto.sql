/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
-- siac_r_soggetto_relaz
delete from  siac_r_soggrel_modpag soggRelModPag using siac_r_migr_relaz_soggetto_relaz migrRelazSogg
where  soggRelModPag.ente_proprietario_id=:enteProprietarioId and
       soggRelModPag.soggetto_relaz_id = migrRelazSogg.soggetto_relaz_id and
       migrRelazSogg.ente_proprietario_id=:enteProprietarioId and
       soggRelModPag.login_operazione='MIGRAZIONE';

delete from  siac_r_soggetto_relaz_stato soggRelazStato using siac_r_migr_relaz_soggetto_relaz migrRelazSogg
where  soggRelazStato.ente_proprietario_id=:enteProprietarioId and
       soggRelazStato.soggetto_relaz_id = migrRelazSogg.soggetto_relaz_id and
       migrRelazSogg.ente_proprietario_id=:enteProprietarioId and
       soggRelazStato.login_operazione='MIGRAZIONE';

delete from  siac_r_soggetto_relaz soggRelaz using siac_r_migr_relaz_soggetto_relaz migrRelazSogg
where  soggRelaz.ente_proprietario_id=:enteProprietarioId and
       soggRelaz.soggetto_relaz_id = migrRelazSogg.soggetto_relaz_id and
       migrRelazSogg.ente_proprietario_id=:enteProprietarioId and
       soggRelaz.login_operazione='MIGRAZIONE';


-- siac_t_modpag
delete from siac_r_modpag_stato modPagStato using siac_r_migr_modpag_modpag migrModPagRel
where modPagStato.modpag_id=migrModPagRel.modpag_id and
      modPagStato.ente_proprietario_id=:enteProprietarioId and
      migrModPagRel.ente_proprietario_id=:enteProprietarioId and
      modPagStato.login_operazione='MIGRAZIONE';

delete from siac_t_modpag modPagStato using siac_r_migr_modpag_modpag migrModPagRel
where modPagStato.modpag_id=migrModPagRel.modpag_id and
      modPagStato.ente_proprietario_id=:enteProprietarioId and
      migrModPagRel.ente_proprietario_id=:enteProprietarioId and
      modPagStato.login_operazione='MIGRAZIONE';

-- Sede Secondaria
-- siac_t_soggetto e siac_r_soggetto_relaz relativamente alla sede verranno cancellati con il soggetto principale

delete from siac_r_indirizzo_soggetto_tipo indirSoggettoTipo
       using  siac_r_migr_sede_secondaria_rel_sede migrSedeRel ,
              siac_r_soggetto_relaz soggRelaz, siac_t_indirizzo_soggetto indirSoggetto
where migrSedeRel.ente_proprietario_id=:enteProprietarioId and
      migrSedeRel.soggetto_relaz_id = soggRelaz.soggetto_relaz_id and
      indirSoggetto.soggetto_id = soggRelaz.soggetto_id_a and
      indirSoggettoTipo.indirizzo_id=indirSoggetto.indirizzo_id and
      indirSoggettoTipo.login_operazione='MIGRAZIONE';

delete from siac_t_indirizzo_soggetto indirSoggetto
       using siac_r_migr_sede_secondaria_rel_sede migrSedeRel , siac_r_soggetto_relaz soggRelaz
where migrSedeRel.ente_proprietario_id=:enteProprietarioId and
      migrSedeRel.soggetto_relaz_id = soggRelaz.soggetto_relaz_id and
      indirSoggetto.soggetto_id = soggRelaz.soggetto_id_a and
      indirSoggetto.login_operazione='MIGRAZIONE';

delete from siac_t_recapito_soggetto recapitoSoggetto
       using siac_r_migr_sede_secondaria_rel_sede migrSedeRel , siac_r_soggetto_relaz soggRelaz
where migrSedeRel.ente_proprietario_id=:enteProprietarioId and
      migrSedeRel.soggetto_relaz_id = soggRelaz.soggetto_relaz_id and
      recapitoSoggetto.soggetto_id = soggRelaz.soggetto_id_a and
      recapitoSoggetto.login_operazione='MIGRAZIONE';

delete from siac_r_soggetto_stato statoSoggetto
       using siac_r_migr_sede_secondaria_rel_sede migrSedeRel , siac_r_soggetto_relaz soggRelaz
where migrSedeRel.ente_proprietario_id=:enteProprietarioId and
      migrSedeRel.soggetto_relaz_id = soggRelaz.soggetto_relaz_id and
      statoSoggetto.soggetto_id = soggRelaz.soggetto_id_a and
      statoSoggetto.login_operazione='MIGRAZIONE';

delete from siac_r_soggetto_attr attrSoggetto
       using siac_r_migr_sede_secondaria_rel_sede migrSedeRel , siac_r_soggetto_relaz soggRelaz
where migrSedeRel.ente_proprietario_id=:enteProprietarioId and
      migrSedeRel.soggetto_relaz_id = soggRelaz.soggetto_relaz_id and
      attrSoggetto.soggetto_id = soggRelaz.soggetto_id_a and
      attrSoggetto.login_operazione='MIGRAZIONE';


-- Recapito Soggetto
delete from siac_t_recapito_soggetto recapitoSoggetto using siac_r_migr_recapito_soggetto_recapito recapitoSoggRel
where recapitoSoggRel.ente_proprietario_id=:enteProprietarioId and
      recapitoSoggetto.recapito_id=recapitoSoggRel.recapito_id and
      recapitoSoggetto.login_operazione='MIGRAZIONE';


-- Indirizzo Secondario
delete from siac_r_indirizzo_soggetto_tipo indirSoggettoTipo
       using  siac_r_migr_indirizzo_secondario_indirizzo migrIndirRel , siac_t_indirizzo_soggetto indirSoggetto
where migrIndirRel.ente_proprietario_id=:enteProprietarioId and
      migrIndirRel.indirizzo_id = indirSoggetto.indirizzo_id and
      indirSoggettoTipo.indirizzo_id=indirSoggetto.indirizzo_id and
      indirSoggetto.login_operazione='MIGRAZIONE';

delete from siac_t_indirizzo_soggetto indirSoggetto
       using siac_r_migr_indirizzo_secondario_indirizzo migrIndirRel
where migrIndirRel.ente_proprietario_id=:enteProprietarioId and
      indirSoggetto.indirizzo_id = migrIndirRel.indirizzo_id and
      indirSoggetto.login_operazione='MIGRAZIONE';

-- Relazioni Soggetto Classi
delete from  siac_r_soggetto_classe soggettoClasse
       using siac_r_migr_soggetto_classe_rel_classe migrSoggettoClasse
where migrSoggettoClasse.ente_proprietario_id=:enteProprietarioId and
      soggettoClasse.soggetto_classe_r_id=migrSoggettoClasse.soggetto_classe_r_id and
      soggettoClasse.login_operazione='MIGRAZIONE';

delete from  siac_r_soggetto_classe soggettoClasse
       using siac_r_migr_soggetto_soggetto migrSoggettoClasse
where migrSoggettoClasse.ente_proprietario_id=:enteProprietarioId and
      soggettoClasse.soggetto_id=migrSoggettoClasse.soggetto_id AND
      soggettoClasse.login_operazione='MIGRAZIONE';


-- SOGGETTI

delete from siac_t_recapito_soggetto recapitoSoggetto using siac_r_migr_soggetto_soggetto migrSoggettoRel
where migrSoggettoRel.ente_proprietario_id=:enteProprietarioId and
      recapitoSoggetto.soggetto_id=migrSoggettoRel.soggetto_id and
      recapitoSoggetto.login_operazione='MIGRAZIONE';


delete from siac_r_indirizzo_soggetto_tipo indirSoggettoTipo
     using siac_r_migr_soggetto_soggetto migrSoggettoRel, siac_t_indirizzo_soggetto indirSoggetto
where migrSoggettoRel.ente_proprietario_id=:enteProprietarioId and
      indirSoggetto.soggetto_id=migrSoggettoRel.soggetto_id and
      indirSoggettoTipo.indirizzo_id=indirSoggetto.indirizzo_id and
      indirSoggetto.login_operazione='MIGRAZIONE';

delete from siac_t_indirizzo_soggetto indirSoggetto
     using siac_r_migr_soggetto_soggetto migrSoggettoRel
where migrSoggettoRel.ente_proprietario_id=:enteProprietarioId and
      indirSoggetto.soggetto_id=migrSoggettoRel.soggetto_id and
      indirSoggetto.login_operazione='MIGRAZIONE';

delete from siac_t_persona_giuridica soggPersGiur
    using siac_r_migr_soggetto_soggetto migrSoggettoRel
where  migrSoggettoRel.ente_proprietario_id=:enteProprietarioId and
       soggPersGiur.soggetto_id = migrSoggettoRel.soggetto_id and
       soggPersGiur.login_operazione='MIGRAZIONE';

delete from siac_t_persona_fisica soggPersFis
    using siac_r_migr_soggetto_soggetto migrSoggettoRel
where  migrSoggettoRel.ente_proprietario_id=:enteProprietarioId and
       soggPersFis.soggetto_id = migrSoggettoRel.soggetto_id and
       soggPersFis.login_operazione='MIGRAZIONE';

delete from siac_r_forma_giuridica soggFormGiurRel
    using siac_r_migr_soggetto_soggetto migrSoggettoRel
where  migrSoggettoRel.ente_proprietario_id=:enteProprietarioId and
       soggFormGiurRel.soggetto_id = migrSoggettoRel.soggetto_id and
       soggFormGiurRel.login_operazione='MIGRAZIONE';

delete from siac_r_soggetto_stato soggStatoRel
    using siac_r_migr_soggetto_soggetto migrSoggettoRel
where  migrSoggettoRel.ente_proprietario_id=:enteProprietarioId and
       soggStatoRel.soggetto_id = migrSoggettoRel.soggetto_id and
       soggStatoRel.login_operazione='MIGRAZIONE';

delete from siac_r_soggetto_tipo soggTipoRel
    using siac_r_migr_soggetto_soggetto migrSoggettoRel
where  migrSoggettoRel.ente_proprietario_id=:enteProprietarioId and
       soggTipoRel.soggetto_id = migrSoggettoRel.soggetto_id and
       soggTipoRel.login_operazione='MIGRAZIONE';

delete from siac_r_soggetto_attr soggAttrRel
    using siac_r_migr_soggetto_soggetto migrSoggettoRel
where  migrSoggettoRel.ente_proprietario_id=:enteProprietarioId and
       soggAttrRel.soggetto_id = migrSoggettoRel.soggetto_id and
       soggAttrRel.login_operazione='MIGRAZIONE';

delete from  siac_r_soggetto_relaz
where login_operazione='MIGRAZIONE' and
      ente_proprietario_id=:enteProprietarioId;

delete from  siac_t_soggetto
where login_operazione='MIGRAZIONE' and
      ente_proprietario_id=:enteProprietarioId;

-- delete relazioni migrazione

delete from siac_r_migr_sede_secondaria_rel_sede migrSedeRel
where migrSedeRel.ente_proprietario_id=:enteProprietarioId;

delete from siac_r_migr_soggetto_soggetto
where ente_proprietario_id=:enteProprietarioId;

delete from siac_r_migr_relaz_soggetto_relaz
where  ente_proprietario_id=:enteProprietarioId;

delete from siac_r_migr_modpag_modpag
where  ente_proprietario_id=:enteProprietarioId;

delete from  siac_r_migr_recapito_soggetto_recapito
where ente_proprietario_id=:enteProprietarioId;

delete from siac_r_migr_indirizzo_secondario_indirizzo
where ente_proprietario_id=:enteProprietarioId;

delete from  siac_r_migr_soggetto_classe_rel_classe
where ente_proprietario_id=:enteProprietarioId;


-- Pulizia dati relativi a comuni/nazioni  e province inseriti

delete from siac_t_forma_giuridica formaGiuridica
where formaGiuridica.ente_proprietario_id=:enteProprietarioId and
      formaGiuridica.login_operazione='MIGRAZIONE';


delete from siac_r_comune_provincia where login_operazione='MIGRAZIONE' and ente_proprietario_id=:enteProprietarioId;
delete from siac_t_provincia where login_operazione='MIGRAZIONE' and ente_proprietario_id=:enteProprietarioId;
delete from siac_t_comune where login_operazione='MIGRAZIONE' and ente_proprietario_id=:enteProprietarioId;
delete from siac_t_nazione where login_operazione='MIGRAZIONE' and ente_proprietario_id=:enteProprietarioId;


delete from siac_d_soggetto_classe
where login_operazione='MIGRAZIONE' and ente_proprietario_id=:enteProprietarioId;
delete from  siac_r_migr_classe_soggclasse
where ente_proprietario_id=:enteProprietarioId;

delete from siac_d_accredito_tipo
where ente_proprietario_id=:enteProprietarioId and login_operazione='MIGRAZIONE';

delete from  siac_r_migr_mod_accredito_accredito
where ente_proprietario_id=:enteProprietarioId;


