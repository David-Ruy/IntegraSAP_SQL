DELIMITER $$

DROP PROCEDURE IF EXISTS `PROC_INTEGRA_EnviarDocEntry_Item_Producao`$$

CREATE PROCEDURE `PROC_INTEGRA_EnviarDocEntry_Item_Producao`(
   IN oCodUsuario				   VARCHAR(10),
   IN oDocEntry	        INT,
   IN oDocTipo		        VARCHAR(10), 
   IN oDocNum		         VARCHAR(30),
   IN oLineNum		        INT,
   
   IN oDocEntryOrdemProducao  VARCHAR(30),
   IN oDocNumOrdemProducao    VARCHAR(30),
   IN oSerialOrdemProducao    VARCHAR(30),
   
	# Parametros de Retorno
	OUT RESULTADO          BOOLEAN,
	OUT MENSAGEM           VARCHAR(500)
)
BLOCO1:BEGIN
   /******************************************************************************
   @Author <David Ruy (OVERFLASH)>
   @Creation <2026-04-06>
   @Description <Esta rotina insere e atualiza a tabela tbintegraSAP_DocItem com informação de Ordem de Produção Vinculada ao item
   #@Reviser David Ruy <2026-07-24> Atualizar status do topo quando inserir o ultimo item para evitar Qtde Quebrada de itens
   *******************************************************************************/

   DECLARE xTipoDocSLIN VARCHAR(10);
   DECLARE xIncAlt 	VARCHAR(01)	DEFAULT 'I';
   DECLARE xLineNum INT;
   DECLARE xQtdeOriItens INT;   
   DECLARE xStatusItem INT DEFAULT 1;
   DECLARE xCodErro	INT DEFAULT 0;
   DECLARE excecao 	INT DEFAULT 0;
   DECLARE xStrAux         VARCHAR(10) DEFAULT NULL;   
   #DECLARE CONTINUE HANDLER FOR SQLEXCEPTION SET excecao = 1;
   

   #Checa topo tbintegraSAP_Doc
   IF NOT EXISTS (SELECT 1 FROM tbintegraSAP_DocItem 
                  WHERE DocEntry = oDocEntry AND DocTipo = oDocTipo AND DocNum = oDocNum AND LineNum = oLineNum) THEN
      SET RESULTADO = 0;
      SET MENSAGEM = CONCAT("ERRO - Não localizado ITEM tbintegraSAP_Doc_Item => ",oDocTipo,oDocNum,'(',oDocEntry,') LineNum=',oLineNum);
      LEAVE BLOCO1;
   END IF;
   
   
   UPDATE tbintegraSAP_DocItem 
   SET DocEntryOrdemProducao  = oDocEntryOrdemProducao,
       DocNumOrdemProducao    = oDocNumOrdemProducao,
       SerialOrdemProducao    = oSerialOrdemProducao, 
       dthr_alt    = NOW(),
       usu_alt     = oCodUsuario
   WHERE DocEntry = oDocEntry
     AND DocTipo  = oDocTipo
     AND DocNum   = oDocNum
     AND LineNum  = oLineNum;
        
   IF ROW_COUNT() > 0 THEN
      SET MENSAGEM = "Registro atualizado com sucesso";
      SET xStatusItem = 1;
   ELSE
      SET MENSAGEM = CONCAT("Registro não atualizado - Sem alterações identificadas");
      SET xStatusItem = 0;
   END IF;




   #Checa Qtde de Itens para Liberar Status "1" Processar
   SELECT QtdeOriItens, COUNT(LineNum) QtdeLinhas 
   INTO xQtdeOriItens, xLineNum
   FROM tbintegraSAP_Doc tbTopo
   INNER JOIN tbintegraSAP_DocItem tbItem ON
              tbItem.DocTipo  = tbTopo.DocTipo 
          AND tbItem.DocEntry = tbTopo.DocEntry
          AND tbItem.DocNum   = tbTopo.DocNum
   WHERE tbTopo.DocTipo  = oDocTipo
     AND tbTopo.DocEntry = oDocEntry
     AND tbTopo.DocNum   = oDocNum;
   
   IF xQtdeOriItens = xLineNum THEN
      CALL PROC_INTEGRA_AtualizarStatusDocEntry('999999', oDocEntry, oDocTipo, oDocNum, 1);
   END IF;






   
   IF excecao = 1 THEN
      #ROLLBACK;
      SET RESULTADO = 0;
      SET MENSAGEM = CONCAT(xCodErro," - Erro SQL - Verifique com o Administrador");
      #SELECT RESULTADO, MENSAGEM;
   ELSE
      #COMMIT;
      SET RESULTADO = xStatusItem;
      #SELECT RESULTADO, MENSAGEM;
   END IF;
END$$

DELIMITER ;