SELECT * FROM tbintegraSAP_Doc;

SELECT * FROM tbintegraSAP_parametros

SELECT * FROM tbintegraSAP_log_request
WHERE dthr_inc >= '2020/03/23 10:00:00'
AND jsonrequest LIKE '%delete%'



#PV - Liberados para Picking
CALL PROC_INTEGRA_ListarLog('2020/03/23 00:00:00', NOW(), 'GET', 'inventory/Picking', '', 0);
CALL PROC_INTEGRA_ListarLog('2020/03/23 00:00:00', NOW(), 'GET', 'inventory/Picking', '', 1);

#PV - Reabertura de Picking
CALL PROC_INTEGRA_ListarLog('2020/03/23 00:00:00', NOW(), 'DELETE', 'inventory/Picking', '', 0);
CALL PROC_INTEGRA_ListarLog('2020/03/23 00:00:00', NOW(), 'DELETE', 'inventory/Picking', '', 1);

#Criação de Picking
CALL PROC_INTEGRA_ListarLog('2020/03/23 00:00:00', NOW(), 'POST', 'inventory/Picking', '', 0);
CALL PROC_INTEGRA_ListarLog('2020/03/23 00:00:00', NOW(), 'POST', 'inventory/Picking', '', 1);

#Confirmação de Picking
CALL PROC_INTEGRA_ListarLog('2020/03/20 00:00:00', NOW(), 'POST', 'inventory/Picking', 'Confirm', 0);
CALL PROC_INTEGRA_ListarLog('2020/03/23 00:00:00', NOW(), 'POST', 'inventory/Picking', 'Confirm', 1);

#Vendas - Alteração de Pedido de Vendas
CALL PROC_INTEGRA_ListarLog('2020/03/23 00:00:00', NOW(), 'ObterDocumento', 'inventory/Updated', '', 0);
CALL PROC_INTEGRA_ListarLog('2020/03/23 00:00:00', NOW(), 'ObterDocumento', 'inventory/Updated', '', 1);

#Vendas - Atualização de Pedido de Vendas
CALL PROC_INTEGRA_ListarLog('2020/03/23 00:00:00', NOW(), 'POST', 'inventory/Order', 'ChangeQuantity', 0);
CALL PROC_INTEGRA_ListarLog('2020/03/23 00:00:00', NOW(), 'POST', 'inventory/Order', 'ChangeQuantity', 1);

#Vendas - Cancelamento Pedido de Vendas
CALL PROC_INTEGRA_ListarLog('2020/03/23 00:00:00', NOW(), 'ObterDocumento', 'inventory/Canceled', '', 0);
CALL PROC_INTEGRA_ListarLog('2020/03/23 00:00:00', NOW(), 'ObterDocumento', 'inventory/Canceled', '', 1);

#Vendas - NF retorno - Devolução de Vendas
CALL PROC_INTEGRA_ListarLog('2020/03/23 00:00:00', NOW(), 'POST', 'inventory/CreditNote', '', 0);
CALL PROC_INTEGRA_ListarLog('2020/03/23 00:00:00', NOW(), 'POST', 'inventory/CreditNote', '', 1);

#Compras - NF Entrega Futura
CALL PROC_INTEGRA_ListarLog('2020/03/23 00:00:00', NOW(), 'POST', 'purchase', '', 0);
CALL PROC_INTEGRA_ListarLog('2020/03/23 00:00:00', NOW(), 'POST', 'purchase', '', 1);

#Compras - Cancelamento Entrega Futura
CALL PROC_INTEGRA_ListarLog('2020/03/23 00:00:00', NOW(), 'ObterListaRecebimentoCancelado', 'ReverseInvoice', '', 0);
CALL PROC_INTEGRA_ListarLog('2020/03/23 00:00:00', NOW(), 'ObterListaRecebimentoCancelado', 'ReverseInvoice', '', 1);
