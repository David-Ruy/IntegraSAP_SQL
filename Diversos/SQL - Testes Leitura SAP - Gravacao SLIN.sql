/***************************************/
/*************** Limpa a base de integração e Movtos WMS 
UPDATE tbintegraSAP_Doc
SET TipoDocSLIN = NULL, cod_emp = NULL, cod_fil = NULL, ano_solic = NULL, num_solic = NULL;
UPDATE tbintegraSAP_DocItem
SET StatusItem = NULL, cod_emp = NULL, cod_fil = NULL, ano_solic = NULL, num_solic = NULL, num_item = NULL;

DELETE FROM of_elinox.tbsolic_entradas;
DELETE FROM of_elinox.tbwms_terceiro;
DELETE FROM of_elinox.tbsolic_saidas;
DELETE FROM of_elinox.tbdestinatarios
DELETE FROM of_elinox.tbprog_entregas; DELETE FROM of_elinox.tbprog_ite_entregas;
DELETE FROM of_elinox.tbnf_clientes; DELETE FROM of_elinox.tbnf_ite_clientes;
DELETE FROM of_elinox.tbnf_clientes; DELETE FROM of_elinox.tbprodutos_paridade;
#
Delete from tbintegraSAP_Doc;
Delete from tbintegraSAP_log_request;

UPDATE tbintegraSAP_Doc
SET StatusDoc = 1;
/***************************************/



SELECT * FROM tbintegraSAP_Doc; # where docTipo = 'PV';
SELECT * FROM tbintegraSAP_DocItem; #  WHERE docTipo = 'PV' ORDER BY DocTipo, DocNum, LineNum;
SELECT * FROM tbintegraSAP_log_request;

SELECT * FROM of_elinox.tbsolic_entradas; SELECT * FROM of_elinox.tbsolic_entradas_item;
SELECT * FROM of_elinox.tbwms_terceiro;
SELECT * FROM of_elinox.tbsolic_saidas; SELECT * FROM of_elinox.tbsolic_saidas_item;
SELECT * FROM of_elinox.tbprog_entregas; SELECT * FROM of_elinox.tbprog_ite_entregas;
SELECT * FROM of_elinox.tbnf_clientes; SELECT * FROM of_elinox.tbnf_ite_clientes;
SELECT * FROM of_elinox.tbprodutos; SELECT * FROM of_elinox.tbprodutos_paridade; SELECT * FROM of_elinox.tbdestinatarios;

CALL PROC_INTEGRA_AtualizarSLIN('999999',@R,@M); SELECT @R,@M;

CALL PROC_INTEGRA_RetornoEntrada("999999","00100120190000000045");
CALL PROC_INTEGRA_RetornoSaida("999999","00100120190000000005");
CALL PROC_INTEGRA_RetornoEntrada("999999",NULL);
CALL PROC_INTEGRA_RetornoSaida("999999","");


CALL PROC_INTEGRA_RetornoEntrada("999999","00100120170000000045");
CALL PROC_INTEGRA_RetornoSaida("999999","00100120170000000005");



CALL PROC_INTEGRA_SetarStatusProcesso('999999',0, 1, @R, @M);
SELECT @R, @M;

CALL PROC_INTEGRA_ListarParametros();


