SELECT * FROM tbintegraSAP_Doc; # where concat(DocTipo,DocNum) = 'NE10'
SELECT * FROM tbintegraSAP_DocItem;
CALL PROC_INTEGRA_ListarLog(DATE(NOW()), NOW(), 'GET', 'picking', '', 1);
CALL PROC_INTEGRA_ListarLog(DATE(NOW()), NOW(), 'POST', 'picking', '', 0);
CALL PROC_INTEGRA_ListarLog(DATE(NOW()), NOW(), 'GET', 'production', '', 1);
CALL PROC_INTEGRA_ListarLog(DATE(NOW()), NOW(), 'POST', 'production', '', 1);
CALL PROC_INTEGRA_ListarLog(DATE(NOW()), NOW(), 'GET', 'purchase', '', 1);
CALL PROC_INTEGRA_ListarLog(DATE(NOW()), NOW(), 'POST', 'purchase', '', 1);
CALL PROC_INTEGRA_ListarLog(DATE(NOW()), NOW(), 'POST', 'transfer', '', 1);
CALL PROC_INTEGRA_ListarLog(DATE(NOW()), NOW(), 'GET', 'counting', '', 1);
CALL PROC_INTEGRA_ListarLog(DATE(NOW()), NOW(), 'POST', 'counting', '', 1);
CALL PROC_INTEGRA_ListarLog(DATE(NOW()), NOW(), 'PROC', 'GerarGSM', '', 1);
CALL PROC_INTEGRA_ListarLog(DATE(NOW()), NOW(), 'PROC', 'GerarGEM', '', 1);

/***************************************************************************************/



SET @DataIni = DATE(NOW());
SET @DataFin = NOW();
SET @Sucesso = 0;

CALL PROC_INTEGRA_ListarLog(@DataIni, @DataFin, 'GET', 'Picking', '', @Sucesso);
/********************************************************************************************************************************/

SET @DataIni = DATE(NOW());
SET @DataFin = NOW();
SET @Sucesso = 0;

SET @String = 'Confirmed|OK|Created';
CALL PROC_SYS_GerarTabelaComTexto(@String,"|",1);
#select * from tTabelaComTexto;


/********************************************************************************************************************************/
#Picking
SELECT SUBSTRING(jsonrequest,01,LOCATE("|",jsonrequest)) metodo,
tbintegraSAP_log_request.* FROM tbintegraSAP_log_request
LEFT JOIN tTabelaComTexto ON
         tTabelaComTexto.coluna01 = ResponseStatus
WHERE dthr_inc BETWEEN @DataIni AND @DataFin
AND SUBSTRING(jsonrequest,01,03) = 'GET'
AND jsonrequest LIKE '%picking%'
AND IF(@Sucesso=1, tTabelaComTexto.coluna01 IS NOT NULL, tTabelaComTexto.coluna01 IS NULL);

#Picking - Create
SELECT * FROM tbintegraSAP_log_request
LEFT JOIN tTabelaComTexto ON
         tTabelaComTexto.coluna01 = ResponseStatus
WHERE dthr_inc BETWEEN @DataIni AND @DataFin
AND SUBSTRING(jsonrequest,01,04) = 'POST'
AND jsonrequest LIKE '%picking/Create%'
AND IF(@Sucesso=1, tTabelaComTexto.coluna01 IS NOT NULL, tTabelaComTexto.coluna01 IS NULL);

#Picking - Confirm
SELECT * FROM tbintegraSAP_log_request
LEFT JOIN tTabelaComTexto ON
         tTabelaComTexto.coluna01 = ResponseStatus
WHERE dthr_inc BETWEEN @DataIni AND @DataFin
AND SUBSTRING(jsonrequest,01,04) = 'POST'
AND jsonrequest LIKE '%picking/Confirm%'
AND IF(@Sucesso=1, tTabelaComTexto.coluna01 IS NOT NULL, tTabelaComTexto.coluna01 IS NULL);


/********************************************************************************************************************************/
SET @DataIni = '2019/12/20 08:00:00';
SET @DataFin = NOW();
SET @Sucesso = 1;

#Purchase - Receipt (GET)
SELECT * FROM tbintegraSAP_log_request
LEFT JOIN tTabelaComTexto ON
         tTabelaComTexto.coluna01 = ResponseStatus
WHERE dthr_inc BETWEEN @DataIni AND @DataFin
AND SUBSTRING(jsonrequest,01,03) = 'GET'
AND jsonrequest LIKE '%Purchase%'
AND IF(@Sucesso=1, tTabelaComTexto.coluna01 IS NOT NULL, tTabelaComTexto.coluna01 IS NULL);

#Purchase - Receipt (POST)
SELECT * FROM tbintegraSAP_log_request
LEFT JOIN tTabelaComTexto ON
         tTabelaComTexto.coluna01 = ResponseStatus
WHERE dthr_inc BETWEEN @DataIni AND @DataFin
AND SUBSTRING(jsonrequest,01,04) = 'POST'
AND jsonrequest LIKE '%Purchase%'
AND IF(@Sucesso=1, tTabelaComTexto.coluna01 IS NOT NULL, tTabelaComTexto.coluna01 IS NULL);


/********************************************************************************************************************************/
SET @DataIni = '2019/12/20 08:00:00';
SET @DataFin = NOW();
SET @Sucesso = 1;


#Production - (GET - PA)
SELECT * FROM tbintegraSAP_log_request
LEFT JOIN tTabelaComTexto ON
         tTabelaComTexto.coluna01 = ResponseStatus
WHERE dthr_inc BETWEEN @DataIni AND @DataFin
AND SUBSTRING(jsonrequest,01,03) = 'GET'
AND jsonrequest LIKE '%Production%'
AND IF(@Sucesso=1, tTabelaComTexto.coluna01 IS NOT NULL, tTabelaComTexto.coluna01 IS NULL);

#Production - (POST - PA)
SELECT * FROM tbintegraSAP_log_request
LEFT JOIN tTabelaComTexto ON
         tTabelaComTexto.coluna01 = ResponseStatus
WHERE dthr_inc BETWEEN @DataIni AND @DataFin
AND SUBSTRING(jsonrequest,01,04) = 'POST'
AND jsonrequest LIKE '%Production%'
AND IF(@Sucesso=1, tTabelaComTexto.coluna01 IS NOT NULL, tTabelaComTexto.coluna01 IS NULL);


/********************************************************************************************************************************/
SET @DataIni = '2019/12/20 08:00:00';
SET @DataFin = NOW();
SET @Sucesso = 1;


#Transferencia - (POST)
SELECT * FROM tbintegraSAP_log_request
LEFT JOIN tTabelaComTexto ON
         tTabelaComTexto.coluna01 = ResponseStatus
WHERE dthr_inc BETWEEN @DataIni AND @DataFin
AND SUBSTRING(jsonrequest,01,04) = 'POST'
AND jsonrequest LIKE '%Transfer%'
AND IF(@Sucesso=1, tTabelaComTexto.coluna01 IS NOT NULL, tTabelaComTexto.coluna01 IS NULL);


/********************************************************************************************************************************/
SET @DataIni = '2019/12/20 08:00:00';
SET @DataFin = NOW();
SET @Sucesso = 1;


#Contagem Criação - (POST)
SELECT * FROM tbintegraSAP_log_request
LEFT JOIN tTabelaComTexto ON
         tTabelaComTexto.coluna01 = ResponseStatus
WHERE dthr_inc BETWEEN @DataIni AND @DataFin
AND SUBSTRING(jsonrequest,01,04) = 'POST'
AND jsonrequest LIKE '%Counting/Create%'
AND IF(@Sucesso=1, tTabelaComTexto.coluna01 IS NOT NULL, tTabelaComTexto.coluna01 IS NULL);

#Contagem Confirmação - (POST)
SELECT * FROM tbintegraSAP_log_request
LEFT JOIN tTabelaComTexto ON
         tTabelaComTexto.coluna01 = ResponseStatus
WHERE dthr_inc BETWEEN @DataIni AND @DataFin
AND SUBSTRING(jsonrequest,01,04) = 'POST'
AND jsonrequest LIKE '%Counting/Confirm%'
AND IF(@Sucesso=1, tTabelaComTexto.coluna01 IS NOT NULL, tTabelaComTexto.coluna01 IS NULL);



/********************************************************************************************************************************/
SET @DataIni = '2019/12/20 08:00:00';
SET @DataFin = NOW();
SET @Sucesso = 1;

#Cancelamentos de PV
SELECT * FROM tbintegraSAP_log_request
LEFT JOIN tTabelaComTexto ON
         tTabelaComTexto.coluna01 = ResponseStatus
WHERE dthr_inc BETWEEN @DataIni AND @DataFin
AND SUBSTRING(jsonrequest,01,03) = 'GET'
AND jsonrequest LIKE '%inventory/Canceled%'
AND IF(@Sucesso=1, tTabelaComTexto.coluna01 IS NOT NULL, tTabelaComTexto.coluna01 IS NULL);

#Alterações de PV
SELECT * FROM tbintegraSAP_log_request
LEFT JOIN tTabelaComTexto ON
         tTabelaComTexto.coluna01 = ResponseStatus
WHERE dthr_inc BETWEEN @DataIni AND @DataFin
AND SUBSTRING(jsonrequest,01,03) = 'GET'
AND jsonrequest LIKE '%inventory/Updated%'
AND IF(@Sucesso=1, tTabelaComTexto.coluna01 IS NOT NULL, tTabelaComTexto.coluna01 IS NULL);

DROP TEMPORARY TABLE tTabelaComTexto;