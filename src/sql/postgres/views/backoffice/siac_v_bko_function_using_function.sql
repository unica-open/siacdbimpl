/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
﻿CREATE VIEW siac.siac_v_bko_function_using_function (
    function_user_name,
    function_used_name)
AS
SELECT fnc_siac_bko_function_using_function.function_user_name,
    fnc_siac_bko_function_using_function.function_used_name
FROM fnc_siac_bko_function_using_function()
    fnc_siac_bko_function_using_function(function_user_name, function_used_name)
WHERE fnc_siac_bko_function_using_function.function_user_name IS NOT NULL
ORDER BY fnc_siac_bko_function_using_function.function_user_name,
    fnc_siac_bko_function_using_function.function_used_name;