/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
drop type parPerInsertElemBilType;

CREATE TYPE parPerInsertElemBilType AS (
      bilElemTipoId     integer,
      elemStatoIdValido integer,
      periodoIdAnno     integer,
      periodoIdAnno1    integer,
      periodoIdAnno2    integer,
      annoBilancio1     varchar(10),
      annoBilancio2     varchar(10),
      elemDetTipoIdSti  integer,
      elemDetTipoIdSri  integer,
      elemDetTipoIdSci  integer,
      elemDetTipoIdSta  integer,
      elemDetTipoIdStr  integer,
      elemDetTipoIdSca  integer,
      elemDetTipoIdStp  integer,
      elemDetTipoIdStass integer,
      elemDetTipoIdStasr integer,
      elemDetTipoIdStasc integer,
      flagImpegnabileAttrId   integer,
      flagPerMemAttrId   integer,
	  flagRilIvaAttrId   integer,
      flagFondoSvalCredAttrId integer,
      flagFunzDelAttrId  integer,
	  flagTrasfOrgAttrId integer,
      noteCapAttrId      integer
    );

