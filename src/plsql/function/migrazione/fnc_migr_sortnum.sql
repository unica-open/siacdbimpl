/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION fnc_migr_sortnum(text) RETURNS NUMERIC AS $$
DECLARE x NUMERIC;
BEGIN
    x = $1::NUMERIC;
    RETURN x;
EXCEPTION WHEN others THEN
    RETURN NULL;
END;
$$ LANGUAGE plpgsql IMMUTABLE;