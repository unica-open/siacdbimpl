/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac."BILR083_proposte_modifica_anagrafica_soggetti" (
  p_ente_prop_id integer
)
RETURNS TABLE (
  nome_ente varchar,
  utente_ins varchar,
  data_ins date,
  code_soggetto varchar,
  descr_soggetto varchar,
  code_sede_sec varchar,
  descr_sede_sec varchar,
  azione varchar,
  tipo_mod_pag varchar
) AS
$body$
DECLARE

elencoModifiche record;

DEF_NULL	constant varchar:='';
RTN_MESSAGGIO varchar(1000):=DEF_NULL;

BEGIN


utente_ins='';
data_ins=NULL;
code_soggetto='';
descr_soggetto='';
code_sede_sec='';
descr_sede_sec='';
azione='';
tipo_mod_pag='';


RTN_MESSAGGIO:='lettura dei dati delle modifiche dei soggetti''.';  

 BEGIN    
      SELECT   t_ente_prop.ente_denominazione
      INTO nome_ente   
      from siac_t_ente_proprietario	t_ente_prop
      where t_ente_prop.ente_proprietario_id=p_ente_prop_id;
     IF NOT FOUND THEN
        raise notice 'Non esiste l''ente';
        return;
     END IF;
 END;
 
 for elencoModifiche in
        select aaa.soggetto_code,'SOGG INSERITO DA DEC' tipo_mod_sog, aaa.soggetto_desc,
        aaa.data_creazione data_ins, aaa.login_operazione utente_ins,
        aaa.azione, aaa.code_sede, aaa.descr_sede, aaa.tipo_mod_pag
        from 
        (select aa.* from
        (select c.soggetto_code ,  c.soggetto_id, c.soggetto_desc,
         c.data_creazione, c.login_operazione, 'INS' azione, '' code_sede,
         '' descr_sede,  '' tipo_mod_pag
        from siac_t_soggetto c, siac_r_soggetto_stato a, siac_d_soggetto_stato b
        where a.soggetto_stato_id = b.soggetto_stato_id
        and c.soggetto_id = a.soggetto_id
        and b.soggetto_stato_code in ('PROVVISORIO', 'IN_MODIFICA')
        and a.ente_proprietario_id = p_ente_prop_id
         and now() between a.validita_inizio and coalesce(a.validita_fine, now())
        and a.data_cancellazione is null
        and b.data_cancellazione is null
        and c.data_cancellazione is null
       /* union
        select c.soggetto_code ,  c.soggetto_id, c.soggetto_desc,
        c.data_creazione, c.login_operazione, 'INS' azione,
        '' code_sede, '' descr_sede, '' tipo_mod_pag
        from siac_t_soggetto c, siac_r_soggetto_stato a, siac_d_soggetto_stato
        b,siac_t_soggetto_mod m
        where a.soggetto_stato_id = b.soggetto_stato_id
        and c.soggetto_id = a.soggetto_id
        and m.soggetto_id=c.soggetto_id
        and a.ente_proprietario_id = p_ente_prop_id
        and now() between a.validita_inizio and coalesce(a.validita_fine, now())
        and now() between m.validita_inizio and coalesce(m.validita_fine, now())
        and a.data_cancellazione is null
        and b.data_cancellazione is null
        and c.data_cancellazione is null
        and m.data_cancellazione is null*/) aa
          where not exists (
             select 1 from siac_r_soggetto_relaz e, siac_d_relaz_tipo f
             where e.relaz_tipo_id = f.relaz_tipo_id
             and e.soggetto_id_a =  aa.soggetto_id
             and f.relaz_tipo_code = 'SEDE_SECONDARIA'
         and now() between e.validita_inizio and coalesce(e.validita_fine, now())
          )
          ) aaa
        --- SOGGETTI IN MODIFICA
        union
        select c.soggetto_code, 'SOGG MODIFICATO DA DEC' tipo_mod_sog, c.soggetto_desc,
         x.data_creazione data_ins, x.login_operazione utente_ins,
         'MOD' azione, '' code_sede, '' descr_sede, '' tipo_mod_pag
          from
        siac_t_soggetto c, siac_r_soggetto_stato a, siac_d_soggetto_stato b,
        siac_t_soggetto_mod x
        where a.soggetto_stato_id = b.soggetto_stato_id
        and c.soggetto_id = a.soggetto_id
        and x.soggetto_id =  a.soggetto_id
        and b.soggetto_stato_code in ('VALIDO')
        and a.ente_proprietario_id = p_ente_prop_id
         and now() between a.validita_inizio and coalesce(a.validita_fine, now())
        and a.data_cancellazione is null
        and b.data_cancellazione is null
        and c.data_cancellazione is null
        and  x.data_cancellazione is null
        and not exists (
           select 1 from siac_r_soggetto_relaz e, siac_d_relaz_tipo f
           where e.relaz_tipo_id = f.relaz_tipo_id
           and e.soggetto_id_a =  c.soggetto_id
           and f.relaz_tipo_code = 'SEDE_SECONDARIA'
           and now() between e.validita_inizio and coalesce(e.validita_fine, now())
        )

        --- SOGGETTI CON MPD MODIFICATE XXXX
        union
        select tb2.soggetto_code, 'SOGG CON MDP MODIFICATE' tipo_mod_sog, tb2.soggetto_desc,
        tb2.data_creazione data_ins, tb2.login_creazione utente_ins,
        tb2.azione, tb2.code_sede, tb2.descr_sede, tb2.tipo_mod_pag
         from (
        select distinct tb.soggetto_code, tb.soggetto_id, tb.soggetto_desc,
        tb.data_creazione, tb.login_creazione, tb.azione, --'MOD' azione,
        tb.code_sede, tb.descr_sede, tb.tipo_mod_pag
         from (
         -- MDP STANDARD INSERITA DA DEC ('PROVVISORIO')
        select c.soggetto_code, c.soggetto_id, c.soggetto_desc,
         z.data_creazione, z.login_creazione, 'INS' azione,
         '' code_sede, '' descr_sede, 
         w.accredito_tipo_code || ' - ' || w.accredito_tipo_desc tipo_mod_pag
         from
        siac_t_soggetto c, siac_r_soggetto_stato a, siac_d_soggetto_stato b,
        siac_r_modpag_stato x , siac_d_modpag_stato y, siac_t_modpag z,
        siac_d_accredito_tipo w
        where
        a.soggetto_stato_id = b.soggetto_stato_id
        and c.soggetto_id = a.soggetto_id
        and z.modpag_id = x.modpag_id
        and z.soggetto_id = a.soggetto_id        
        and x.modpag_stato_id = y.modpag_stato_id
        and z.accredito_tipo_id=w.accredito_tipo_id
        and b.soggetto_stato_code in ('VALIDO')
        and y.modpag_stato_code in ('PROVVISORIO', 'IN_MODIFICA')
        and a.ente_proprietario_id=p_ente_prop_id
         and now() between a.validita_inizio and coalesce(a.validita_fine, now())
         and now() between x.validita_inizio and coalesce(x.validita_fine, now())
        and a.data_cancellazione is null
        and b.data_cancellazione is null
        and c.data_cancellazione is null
        and w.data_cancellazione is null
        union
         -- MDP STANDARD INSERITA DA DEC (in modifica)
        select c.soggetto_code, c.soggetto_id, c.soggetto_desc,
        m.data_creazione, m.login_operazione, 'MOD' azione, 
        '' code_sede, '' descr_sede,
        w.accredito_tipo_code || ' - ' || w.accredito_tipo_desc tipo_mod_pag
        from
        siac_t_soggetto c, siac_r_soggetto_stato a, siac_d_soggetto_stato b,
        siac_r_modpag_stato x , siac_d_modpag_stato y, siac_t_modpag z,
        siac_t_modpag_mod m, siac_d_accredito_tipo w
        where
        a.soggetto_stato_id = b.soggetto_stato_id
        and c.soggetto_id = a.soggetto_id
        and x.modpag_stato_id = y.modpag_stato_id
        and m.modpag_id=z.modpag_id
        and m.accredito_tipo_id=w.accredito_tipo_id
        and z.modpag_id = x.modpag_id
        and z.soggetto_id = a.soggetto_id        
        and b.soggetto_stato_code in ('VALIDO')
        and a.ente_proprietario_id=p_ente_prop_id        
        --and y.modpag_stato_code in ('PROVVISORIO', 'IN_MODIFICA')
         and now() between a.validita_inizio and coalesce(a.validita_fine, now())
         and now() between x.validita_inizio and coalesce(x.validita_fine, now())
         and now() between m.validita_inizio and coalesce(m.validita_fine, now())
        and a.data_cancellazione is null
        and b.data_cancellazione is null
        and c.data_cancellazione is null
        and m.data_cancellazione is null
        and w.data_cancellazione is null
        union
         -- MDP CSI e SIMILI INSERITA DA DEC
         select c.soggetto_code, c.soggetto_id, c.soggetto_desc,
          x.data_creazione, x.login_operazione, 'INS' azione,
          '' code_sede, '' descr_sede,
          f.accredito_tipo_code || ' - ' || f.accredito_tipo_desc tipo_mod_pag
         from
        siac_t_soggetto c, siac_r_soggetto_stato a, siac_d_soggetto_stato b,
        siac_r_soggetto_relaz x , siac_r_soggetto_relaz_stato y, siac_d_relaz_stato z,
        siac_d_relaz_tipo k,siac_d_accredito_gruppo g, siac_d_accredito_tipo f
        where
        a.soggetto_stato_id = b.soggetto_stato_id
        and c.soggetto_id = a.soggetto_id
        and x.soggetto_id_da = a.soggetto_id
        and b.soggetto_stato_code in ('VALIDO')
        AND   x.soggetto_relaz_id = y.soggetto_relaz_id
        and   y.relaz_stato_id = z.relaz_stato_id
        and   k.relaz_tipo_id = x.relaz_tipo_id
        and   z.relaz_stato_code in ('PROVVISORIO', 'IN_MODIFICA')
        and f.ente_proprietario_id = a.ente_proprietario_id
        and a.ente_proprietario_id=p_ente_prop_id
        and  k.relaz_tipo_code=f.accredito_tipo_code
        and  g.accredito_gruppo_id = f.accredito_gruppo_id
        and g.accredito_gruppo_code in ('CSI', 'CSC')   
         and now() between a.validita_inizio and coalesce(a.validita_fine, now())
         and now() between x.validita_inizio and coalesce(x.validita_fine, now())     
          and now() between y.validita_inizio and coalesce(y.validita_fine, now())
        and a.data_cancellazione is null
        and b.data_cancellazione is null
        and c.data_cancellazione is null
        and x.data_cancellazione is null
        and y.data_cancellazione is null
        and z.data_cancellazione is null
        and k.data_cancellazione is null
        union
         -- MDP STANDARD AGGIORNATE
        select c.soggetto_code, c.soggetto_id, c.soggetto_desc,
        x.data_creazione, x.login_operazione, 'MOD' azione,
        '' code_sede, '' descr_sede,
         w.accredito_tipo_code || ' - ' || w.accredito_tipo_desc tipo_mod_pag
         from
        siac_t_soggetto c, siac_r_soggetto_stato a, siac_d_soggetto_stato
        b,siac_t_modpag_mod x, siac_d_accredito_tipo w
        where a.soggetto_stato_id = b.soggetto_stato_id
        and c.soggetto_id = a.soggetto_id
        and x.soggetto_id =  a.soggetto_id
        and x.accredito_tipo_id=w.accredito_tipo_id
        and a.ente_proprietario_id=p_ente_prop_id
        and b.soggetto_stato_code in ('VALIDO')
         and now() between a.validita_inizio and coalesce(a.validita_fine, now())
        and a.data_cancellazione is null
        and b.data_cancellazione is null
        and c.data_cancellazione is null
        and x.data_cancellazione is null
        union
          -- MDP CSI e simili AGGIORNATE
        select c.soggetto_code, c.soggetto_id, c.soggetto_desc,
        x.data_creazione, x.login_operazione, 'MOD' azione,
        '' code_sede, '' descr_sede,
        w.accredito_tipo_code || ' - ' || w.accredito_tipo_desc tipo_mod_pag
          from
        siac_t_soggetto c, siac_r_soggetto_stato a, siac_d_soggetto_stato b,
        siac_r_soggrel_modpag_mod x, siac_r_soggetto_relaz_mod y, siac_t_modpag z,
       siac_d_accredito_tipo w
        where a.soggetto_stato_id = b.soggetto_stato_id
        and c.soggetto_id = a.soggetto_id
        and x.modpag_id=z.modpag_id
        and z.accredito_tipo_id=w.accredito_tipo_id
        and b.soggetto_stato_code in ('VALIDO')
        and a.ente_proprietario_id=p_ente_prop_id
        and  x.soggetto_relaz_mod_id = y.soggetto_relaz_mod_id
        and y.soggetto_id_da =  a.soggetto_id
         and now() between a.validita_inizio and coalesce(a.validita_fine, now())
         and now() between x.validita_inizio and coalesce(x.validita_fine, now())
        and a.data_cancellazione is null
        and b.data_cancellazione is null
        and c.data_cancellazione is null
        and x.data_cancellazione is null
        and y.data_cancellazione is null  
        ) tb
        where not exists (
        select 1 from siac_r_soggetto_relaz e, siac_d_relaz_tipo f
        where e.relaz_tipo_id = f.relaz_tipo_id
        and f.relaz_tipo_code = 'SEDE_SECONDARIA'
        and e.soggetto_id_a =  tb.soggetto_id
        )
        ) tb2
        union
        --- SOGGETTI CON SEDI NUOVE INSERITE DA DEC ('PROVVISORIO')
        select c.soggetto_code , 'SOGG CON SEDI INSERITE' tipo_mod_sog, c.soggetto_desc,
        c.data_creazione data_ins, c.login_creazione utente_ins, 'INS' azione,
        g.soggetto_code code_sede, g.soggetto_desc descr_sede, '' tipo_mod_pag        
         from
        siac_t_soggetto c, siac_r_soggetto_stato a, siac_d_soggetto_stato b,
        siac_r_soggetto_relaz e, siac_d_relaz_tipo f, siac_t_soggetto g
         where
         a.soggetto_stato_id = b.soggetto_stato_id   
         and c.soggetto_id=a.soggetto_id
         and a.soggetto_id = e.soggetto_id_a
         --and c.soggetto_id = e.soggetto_id_da
         and e.relaz_tipo_id = f.relaz_tipo_id
         and g.soggetto_id = e.soggetto_id_a
         and b.soggetto_stato_code in ('PROVVISORIO', 'IN_MODIFICA')
         and f.relaz_tipo_code = 'SEDE_SECONDARIA'
         and a.ente_proprietario_id = p_ente_prop_id
         and now() between a.validita_inizio and coalesce(a.validita_fine, now())
         and now() between e.validita_inizio and coalesce(e.validita_fine, now())
         and a.data_cancellazione is null
         and b.data_cancellazione is null
         and c.data_cancellazione is null
         and e.data_cancellazione is null
         and g.data_cancellazione is null
         and f.data_cancellazione is null
         union
        --- SOGGETTI CON SEDI NUOVE INSERITE DA DEC ( in modifica)
        select c.soggetto_code , 'SOGG CON SEDI INSERITE' tipo_mod_sog, c.soggetto_desc,
        m.data_creazione data_ins, m.login_operazione utente_ins, 'MOD' azione,
        g.soggetto_code code_sede, g.soggetto_desc descr_sede, '' tipo_mod_pag
         from
        siac_t_soggetto c, siac_r_soggetto_stato a, siac_d_soggetto_stato b,
        siac_r_soggetto_relaz e, siac_d_relaz_tipo f, siac_t_soggetto g,
        siac_t_soggetto_mod m
         where
         a.soggetto_stato_id = b.soggetto_stato_id   
         and c.soggetto_id=a.soggetto_id
         and a.soggetto_id = e.soggetto_id_a
         and c.soggetto_id = e.soggetto_id_da
         and e.relaz_tipo_id = f.relaz_tipo_id
         and g.soggetto_id = e.soggetto_id_a
         and m.soggetto_id=c.soggetto_id
        -- and b.soggetto_stato_code in ('PROVVISORIO', 'IN_MODIFICA')
         and f.relaz_tipo_code = 'SEDE_SECONDARIA'
         and a.ente_proprietario_id = p_ente_prop_id
         and now() between a.validita_inizio and coalesce(a.validita_fine, now())
         and now() between e.validita_inizio and coalesce(e.validita_fine, now())
        and now() between m.validita_inizio and coalesce(m.validita_fine, now())
         and a.data_cancellazione is null
         and b.data_cancellazione is null
         and c.data_cancellazione is null
         and e.data_cancellazione is null
         and g.data_cancellazione is null
         and f.data_cancellazione is null
         and m.data_cancellazione is null
         --- SOGGETTI CON SEDI MODIFICATE DA DEC
        union
          select c.soggetto_code, 'SOGG CON SEDI MODIFICATE' tipo_mod_sog, c.soggetto_desc,
          x.data_creazione data_ins, x.login_operazione utente_ins, 'MOD' azione,
          g.soggetto_code code_sede, g.soggetto_desc descr_sede, '' tipo_mod_pag
           from
          siac_t_soggetto c, siac_r_soggetto_stato a, siac_d_soggetto_stato b,
          siac_r_soggetto_relaz e, siac_d_relaz_tipo f, siac_t_soggetto g,
          siac_t_soggetto_mod x
         where
          a.soggetto_stato_id = b.soggetto_stato_id
          and c.soggetto_id=a.soggetto_id
          and b.soggetto_stato_code in ('VALIDO')
          and a.ente_proprietario_id = p_ente_prop_id
          and e.relaz_tipo_id = f.relaz_tipo_id
          and g.soggetto_id = e.soggetto_id_a
          and e.soggetto_id_a =  a.soggetto_id
          and c.soggetto_id = e.soggetto_id_da
          and f.relaz_tipo_code = 'SEDE_SECONDARIA'
          and x.soggetto_id =  a.soggetto_id
           and now() between a.validita_inizio and coalesce(a.validita_fine, now())
         and now() between e.validita_inizio and coalesce(e.validita_fine, now())
          and a.data_cancellazione is null
          and b.data_cancellazione is null
          and c.data_cancellazione is null
          and e.data_cancellazione is null
          and f.data_cancellazione is null
          and g.data_cancellazione is null
          and x.data_cancellazione is null
        union
        select
        c.soggetto_code, 'MODPAG SEDI SEC PROVVISORIA' tipo_mod_sog, c.soggetto_desc,
        z.data_creazione data_ins, z.login_creazione utente_ins, 'MOD' azione,
        c2.soggetto_code code_sede, c2.soggetto_desc descr_sede, '' tipo_mod_pag
        from siac_t_soggetto c, siac_r_soggetto_relaz re,siac_t_soggetto c2,
        siac_d_relaz_tipo f,
        siac_r_modpag_stato x , siac_d_modpag_stato y, siac_t_modpag z
         where
        re.soggetto_id_da=c.soggetto_id
        and
        re.soggetto_id_a=c2.soggetto_id
        and re.relaz_tipo_id= f.relaz_tipo_id
        and f.relaz_tipo_code='SEDE_SECONDARIA'
        and z.soggetto_id=c2.soggetto_id
        and x.modpag_id=z.modpag_id
        and y.modpag_stato_id=x.modpag_stato_id
        and  y.modpag_stato_code in ('PROVVISORIO', 'IN_MODIFICA')
         and now() between re.validita_inizio and coalesce(re.validita_fine, now())
         and now() between x.validita_inizio and coalesce(x.validita_fine, now())     
        and c2.data_cancellazione is null
        and re.data_cancellazione is null
        and c.data_cancellazione is null
        and x.data_cancellazione is null
        and y.data_cancellazione is null
        and z.data_cancellazione is null
        and f.data_cancellazione is null
        union
        select
        c.soggetto_code, 'MODPAG SEDI SEC IN MODIFICA' tipo_mod_sog, c.soggetto_desc,
        m.data_creazione data_ins, m.login_operazione utente_ins, 'MOD' azione,
        c2.soggetto_code code_sede, c2.soggetto_desc descr_sede, '' tipo_mod_pag
        from siac_t_soggetto c, siac_r_soggetto_relaz re,siac_t_soggetto c2,
        siac_d_relaz_tipo f,
        siac_r_modpag_stato x , siac_d_modpag_stato y, siac_t_modpag z,
        siac_t_modpag_mod m
          where
        re.soggetto_id_da=c.soggetto_id
        and
        re.soggetto_id_a=c2.soggetto_id
        and re.relaz_tipo_id= f.relaz_tipo_id
        and f.relaz_tipo_code='SEDE_SECONDARIA'
        and z.soggetto_id=c2.soggetto_id
        and x.modpag_id=z.modpag_id
        and y.modpag_stato_id=x.modpag_stato_id
        and m.modpag_id=z.modpag_id
         and now() between re.validita_inizio and coalesce(re.validita_fine, now())
         and now() between x.validita_inizio and coalesce(x.validita_fine, now())     
          and now() between m.validita_inizio and coalesce(m.validita_fine, now())     
        and c2.data_cancellazione is null
        and re.data_cancellazione is null
        and c.data_cancellazione is null
        and x.data_cancellazione is null
        and y.data_cancellazione is null
        and z.data_cancellazione is null
        and f.data_cancellazione is null
        AND m.data_cancellazione is null
         order by 1
	loop
      
  utente_ins=elencoModifiche.utente_ins;
  data_ins=elencoModifiche.data_ins;
  code_soggetto=elencoModifiche.soggetto_code;
  descr_soggetto=elencoModifiche.soggetto_desc;
  code_sede_sec=elencoModifiche.code_sede;
  descr_sede_sec=elencoModifiche.descr_sede;
  IF elencoModifiche.azione = 'INS' then
  	azione='Proposta Inserimento';
  else
  	azione='Proposta Modifica';
  END IF;
  tipo_mod_pag=elencoModifiche.tipo_mod_pag;
     

	return next;
      
  utente_ins='';
  data_ins=NULL;
  code_soggetto='';
  descr_soggetto='';
  code_sede_sec='';
  descr_sede_sec='';
  azione='';
  tipo_mod_pag='';
    
end loop;



raise notice 'fine OK';
    exception
    when no_data_found THEN
    raise notice 'nessun dato trovato';
    return;
    when others  THEN
 	RAISE EXCEPTION '% Errore : %-%.',RTN_MESSAGGIO,SQLSTATE,substring(SQLERRM from 1 for 500);
    return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100 ROWS 1000;