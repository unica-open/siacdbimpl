/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
﻿CREATE OR REPLACE FUNCTION siac."fnc_crea_variabili_BILR148" (
  p_crea_report varchar,
  p_anno_da integer,
  p_anno_a integer,
  p_num_var_da integer,
  p_num_var_a integer
)
RETURNS void AS
$body$
DECLARE
  mioMessaggio varchar;
  numero_cicli integer;
  elenco_anni integer;
  miaQuery varchar;
  
BEGIN

/*
	Funzione per creare le variabili  NON FISSE utilizzate per il report 
    BILR147_Allegato_B_Fondo_Pluriennale_vincolato_Rend.
    La funziona ha i seguenti parametri di input:
    - p_crea_report; mettere S solo la prima volta per creare il report su
    	SIAC_T_REPORT.
        Le volte successive specificare N.
    - p_anno_da/p_anno_a; specificare un intervallo di anni per i quali creare 
    	le variabili. Esempio: 2016 2017.
        Se si vuole creare le varibili per un solo anno specificare l'anno
        per entrambi i parametri. Esempio 2016 2016.
    - p_num_var_da/p_num_var_a; specificare un intervallo che indica quante
    	variabili creare. Esempio: 1 30 creera'' 30 variabili.
        Se in un successivo lancio si vogliono creare nuove variabili partire
        dal valore successivo all'ultima creata. Esempio: 31 40 creera'' 10 
        nuove variabili oltre alle 30 create in precedenza.
        
    La procedura crea anche i dati sulle tabelle BKO:
    - BKO_T_REPORT_COMPETENZE; solo se p_crea_report = 'S'
    - BKO_T_REPORT_IMPORTI.
*/

/* Inserimento della configurazione del report.
	Deve essere fatto una volta sola. */

if upper(p_crea_report) = 'S' THEN
  mioMessaggio:= 'Inserimento sulla tabella SIAC_T_REPORT';
  INSERT INTO SIAC_T_REPORT (rep_codice,
                             rep_desc,
                             rep_birt_codice,
                             validita_inizio,
                             validita_fine,
                             ente_proprietario_id,
                             data_creazione,
                             data_modifica,
                             data_cancellazione,
                             login_operazione)
  select 'BILR148',
         'Allegato c) Fondo crediti di dubbia esigibilita'' (BILR148)',
         'BILR148_Allegato_C_Fondo_Crediti_Dubbia_esigibilita_cons',
         to_date('01/01/2017','dd/mm/yyyy'),
         null,
         a.ente_proprietario_id,
         now(),
         now(),
         null,
         'SIAC-5478'
  from siac_t_ente_proprietario a
  where a.data_cancellazione is  null;
  
  mioMessaggio:= 'Inserimento sulla tabella BKO_T_REPORT_COMPETENZE';
  INSERT INTO BKO_T_REPORT_COMPETENZE 
    (rep_codice,
     rep_competenza_anni)
    VALUES 
    ('BILR148', 1);
 
end if;


for elenco_anni in p_anno_da..p_anno_a
loop
	/* Inserimento delle variabili su SIAC_T_REPORT_IMPORTI. */
    for numero_cicli in p_num_var_da..p_num_var_a 
	loop

	mioMessaggio:= 'Inserimento sulla tabella SIAC_T_REPORT_IMPORTI '||
        	elenco_anni|| ' ' ||numero_cicli;
        --raise notice '%',mioMessaggio;
               
        
        INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                           repimp_desc,
                                           repimp_importo,
                                           repimp_modificabile,
                                           repimp_progr_riga,
                                           bil_id,
                                           periodo_id,
                                           validita_inizio,
                                           validita_fine,
                                           ente_proprietario_id,
                                           data_creazione,
                                           data_modifica,
                                           data_cancellazione,
                                           login_operazione)                                                                   
        select  'Colonna E Allegato c) FCDE Rendiconto',
                '',
                0,
                'S',
                numero_cicli,
                a.bil_id,
                b2.periodo_id,
                to_date('01/01/2017','dd/mm/yyyy'),
                null,
                a.ente_proprietario_id,
                now(),
                now(),
                null,
                'SIAC-5478'
        from  siac_t_bil a, siac_t_ente_proprietario a2,
        siac_t_periodo b, siac_d_periodo_tipo c,
        siac_t_periodo b2, siac_d_periodo_tipo c2
        where a.periodo_id = b.periodo_id
        and c.periodo_tipo_id=b.periodo_tipo_id
        and b2.ente_proprietario_id=b.ente_proprietario_id
        and c2.periodo_tipo_id=b2.periodo_tipo_id
        and a.ente_proprietario_id=a2.ente_proprietario_id
        and   b.anno = elenco_anni::varchar
        and c.periodo_tipo_code='SY'
        and  b2.anno = elenco_anni::varchar
        and c2.periodo_tipo_code='SY'
        and a2.data_cancellazione is null;
               
            
        --raise notice 'FATTO %', mioMessaggio;
        
	end loop; --fine ciclo variabili.
      
end loop ; -- fine ciclo anni.

mioMessaggio:= 'Inserimento sulla tabella SIAC_R_REPORT_IMPORTI';
--raise notice '%',mioMessaggio;

/* Associazione delle variabili sulla tabella SIAC_R_REPORT_IMPORTI.
   Se lanciata più volte inserisce solo quelle che non sono gia'' presenti */
INSERT INTO SIAC_R_REPORT_IMPORTI (rep_id,
                                         repimp_id,
                                         posizione_stampa,
                                         validita_inizio,
                                         validita_fine,
                                         ente_proprietario_id,
                                         data_creazione,
                                         data_modifica,
                                         data_cancellazione,
                                         login_operazione)                                   
      select 
      (select d.rep_id
      from   siac_t_report d
      where  d.rep_codice = 'BILR148'
      and    d.ente_proprietario_id = a.ente_proprietario_id) rep_id,
       a.repimp_id,
      1 posizione_stampa,
      to_date('01/01/2017','dd/mm/yyyy') validita_inizio,
      null validita_fine,
      a.ente_proprietario_id ente_proprietario_id,
      now() data_creazione,
      now() data_modifica,
      null data_cancellazione,
      'SIAC-5478' login_operazione
      from   siac_t_report_importi a
      where  a.repimp_codice = 'Colonna E Allegato c) FCDE Rendiconto'
          and a.repimp_id not in (select repimp_id from SIAC_R_REPORT_IMPORTI) ;
          
          
      /* Cancellazione e Inserimento delle variabili su BKO_T_REPORT_IMPORTI */
	mioMessaggio:= 'Cancello i dati dalla tabella BKO_T_REPORT_IMPORTI';
	DELETE FROM BKO_T_REPORT_IMPORTI 
    WHERE rep_codice='BILR148';
    
    mioMessaggio:= 'Inserisco i dati sulla tabella BKO_T_REPORT_IMPORTI';
    INSERT INTO BKO_T_REPORT_IMPORTI
            (rep_codice,
              rep_desc,
              repimp_codice,
              repimp_desc,
              repimp_importo,
              repimp_modificabile,
              repimp_progr_riga)
            select  distinct 
              'BILR148',
               'Allegato c) Fondo crediti di dubbia esigibilita'' (BILR148)',
               'Colonna E Allegato c) FCDE Rendiconto',
               '',
               0,
               'S',
               repimp_progr_riga
             from SIAC_T_REPORT_IMPORTI a,
                siac_r_report_importi b,
                siac_t_report c
            where a.repimp_id=b.repimp_id
                and b.rep_id=c.rep_id
                and c.rep_codice='BILR148';
                          
EXCEPTION

when others  THEN
		raise notice '% - Errore DB % %',mioMessaggio, SQLSTATE,
	        	substring(upper(SQLERRM) from 1 for 50);

END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;