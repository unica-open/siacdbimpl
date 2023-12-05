/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
ALTER TABLE siac.siac_dwh_subordinativo_pagamento ADD COLUMN cup VARCHAR(500);

ALTER TABLE siac.siac_dwh_subordinativo_pagamento ADD COLUMN cig VARCHAR(500);

ALTER TABLE siac.siac_dwh_ordinativo_pagamento DROP COLUMN cup;