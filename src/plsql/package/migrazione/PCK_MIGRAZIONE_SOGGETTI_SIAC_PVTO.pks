/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/


CREATE OR REPLACE PACKAGE PCK_MIGRAZIONE_SOGGETTI_SIAC AS
    function fnc_migrazione_mod_accredito(pEnte number,pMsgRes out varchar2) return number;
    procedure migrazione_soggetto(pEnte number,pCodRes out number,pMsgRes out varchar2);
    procedure migrazione_indirizzo_second(pEnte number,pCodRes out number,pMsgRes out varchar2);
    procedure migrazione_soggetto_sede_sec(pEnte number,pCodRes out number,pMsgRes out varchar2);
    procedure migrazione_soggetto_mdp(pEnte   number, pCodRes out number, pMsgRes out varchar2);
    procedure migrazione_soggetti(pEnte  number,pAnnoEsercizio varchar2,pAnni  number, pCodRes out number,pMsgRes out varchar2);
    function removeBadChar( str in varchar2) return varchar2;
    procedure insertBadChar;
END;
/

