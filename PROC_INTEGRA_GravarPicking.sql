DELIMITER $$

DROP PROCEDURE IF EXISTS `PROC_INTEGRA_GravarPicking`$$

CREATE PROCEDURE `PROC_INTEGRA_GravarPicking`(
	IN oDocEntry          VARCHAR(10),
	IN oDocTipo           VARCHAR(10),
	IN oIdPicking         VARCHAR(10),
	IN oPkLineNum         VARCHAR(10),
	IN oDocLineNum        VARCHAR(10),
	
	# Parametros de Retorno
	OUT RESULTADO         VARCHAR(5),
	OUT MENSAGEM          VARCHAR(500)
)
BLOCO1:BEGIN
   /****************************************************************
   #Create David Ruy 
   #Reviser David Ruy <2022-01-14 Update tbintegraSAP_Doc->U_RSD_RplOrder
   #Reviser David Ruy <2026-07-29 Update tbintegraSAP_DocItem->LineNumPk = oPkLineNum
   *****************************************************************/
	DECLARE xIncAlt      VARCHAR(01)	DEFAULT 'I';
	DECLARE excecao      INT DEFAULT 0;
	DECLARE xDocNum      INT;
	#DECLARE CONTINUE HANDLER FOR SQLEXCEPTION SET excecao = 1;
   SET RESULTADO = "1";
   SET MENSAGEM = "Atualização realizada com sucesso";
   
   SELECT DocNum INTO xDocNum FROM tbintegraSAP_Doc
   WHERE DocEntry = oDocEntry
     AND DocTipo  = oDocTipo;
     
   
   INSERT INTO tbintegraSAP_DocPicking (
         DocEntry, Doctipo, DocNum, IdPicking, PkLineNum, DocLineNum, dthr_inc)
   VALUES (oDocEntry, oDocTipo, xDocNum, oIdPicking, oPkLineNum, oDocLineNum, NOW());
   
   #2026-07-29
   UPDATE tbintegraSAP_DocItem
   SET LineNumPk = oPkLineNum
   WHERE DocEntry = oDocEntry
     AND DocTipo  = oDocTipo
     AND LineNum  = oDocLineNum;
     
   
   
   
   IF excecao = 1 THEN
      SET RESULTADO = "0";
      SET MENSAGEM = "Erro SQL - Verifique com o Administrador";
   END IF;
   
END$$

DELIMITER ;