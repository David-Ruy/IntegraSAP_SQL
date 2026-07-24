DELIMITER $$

DROP PROCEDURE IF EXISTS `PROC_INTEGRA_EnviarDocEntry_ItemOP`$$

CREATE PROCEDURE `PROC_INTEGRA_EnviarDocEntry_ItemOP`(
   IN oCodUsuario				   VARCHAR(10),
   IN oDocEntry	        INT,
   IN oDocTipo		        VARCHAR(10), #'PedidoVenda-ConfPV / NotaFiscalRecebimento-ConfNF / OrdemProducao-ConfOP / '
   IN oDocNum		         INT,
   IN oLineNum		        INT,
   IN oItemCode	        VARCHAR(30),
   IN oBaseQty		        DOUBLE(20,6),
   IN oPlannedQty	      DOUBLE(20,6),
   IN oIssuedQty	       DOUBLE(20,6),
   IN oWhareHouse	      VARCHAR(30),
   IN oPrice            DOUBLE(20,6),
   IN oDollarQuote      DOUBLE(20,6),
   IN oUsage            VARCHAR(20),
   IN oCFOPCode         VARCHAR(15),
   IN oTaxCode          VARCHAR(15),
   #Grupo Unidade de Medida
   IN oUgpEntry         INT,
   IN oUomCode          VARCHAR(30),
   IN ounitMsr          VARCHAR(30),
   IN oOpenInvQty       DOUBLE(20,6),
   #
   IN oIssueType	       VARCHAR(1),
   IN oStatusItem	      VARCHAR(10),	# Verificar STATUS EXCLUSÃO
   IN oObservacoes      VARCHAR(500),
	
   IN oDescrProduto     VARCHAR(200),
   IN oEmbCompras       VARCHAR(30),
   IN oEmbVendas        VARCHAR(30),
   IN oEmbEstoque       VARCHAR(30),
   IN oManBtchNum       INT,
   IN oManSerNum        INT,
   IN oNumInSale        DECIMAL(18,5),
   IN oBatchNumbersCode VARCHAR(30),
   IN oDataFabricacao   VARCHAR(30),
   IN oDataValidade     VARCHAR(30),
	
	# Parametros de Retorno
	OUT RESULTADO          BOOLEAN,
	OUT MENSAGEM           VARCHAR(500)
)
BLOCO1:BEGIN
   /******************************************************************************
   @Author <David Ruy (OVERFLASH)>
   @Creation <2019-07-11>
   @Description <Esta rotina insere e atualiza a tabela tbintegraSAP_DocItem que faz o controle
   da integração SAP / SLIN. 
   >
   @Reviser David Ruy <2021-09-25> Ajustes Entrada Produção Parcelada PA000, PA001, PA002,....
   @Reviser David Ruy <2021-11-04> Ajustes Grupos de UM
   @Reviser David Ruy <2025-07-11> Correção update, ajuste variável oDoctipo
   *******************************************************************************/
   DECLARE xTipoDocSLIN VARCHAR(10);
   DECLARE xIncAlt 	VARCHAR(01)	DEFAULT 'I';
   DECLARE xLineNum INT;
   DECLARE xStatusItem INT DEFAULT 1;
   DECLARE xCodErro	INT DEFAULT 0;
   DECLARE excecao 	INT DEFAULT 0;
   DECLARE xStrAux         VARCHAR(10) DEFAULT NULL;   
   #DECLARE CONTINUE HANDLER FOR SQLEXCEPTION SET excecao = 1;
   
   SET oDescrProduto = SUBSTRING(oDescrProduto,1,100);   
   
   IF oDocTipo = "PA" THEN
      #Tratativa para Ordem de Produção : Recebimento Parcelado
      #Gerar PA000, PA001, PA002, .....
      SELECT MAX(DocTipo) INTO xStrAux
      FROM tbintegraSAP_Doc
      WHERE SUBSTRING(DocTipo,1,2)  = "PA"
        AND DocEntry = oDocEntry;
           
      SET oDocTipo = xStrAux;
   END IF;   
   
   
   SET xLineNum = NULL;
   SELECT LineNum INTO xLineNum
   #@Reviser @David Ruy <2019/11/28> Chave primária é oDocEntry+oDocTipo+oLineNum
   FROM tbintegraSAP_DocItem
   WHERE DocEntry = oDocEntry
     AND DocTipo  = oDocTipo
     #AND ItemCode = oItemCode;
     AND LineNum  = oLineNum;
     
   IF xLineNum IS NULL THEN
      SET xIncAlt = "I";
      SET xLineNum = oLineNum;
   ELSE
      SET xIncAlt = "A";
   END IF;
   
   /*IF xIncAlt = "I" THEN
      #SELECT IFNULL(MAX(LineNum)+1,0) INTO xLineNum 
      #FROM tbintegraSAP_DocItem
      #WHERE DocEntry = oDocEntry
      #  AND DocTipo  = oDocTipo;
      SET xLineNum = oLineNum;
      SET xIncAlt = "I";
   END IF;
   */
   
   SELECT tbTipoOper.tipo_movto INTO xTipoDocSLIN
   FROM of_logistica.tbsys_integracao_estoque tbSys
   INNER JOIN of_logistica.tbwms_tipo_oper tbTipoOper ON
              tbSys.cod_oper_wms = tbTipoOper.cod_oper_wms
    WHERE chave_integracao = oDocTipo LIMIT 1;
    
    
    IF (oWhareHouse IS NULL) THEN
      SELECT WhareHouse INTO oWhareHouse 
      FROM tbintegraSAP_Doc
      WHERE DocEntry = oDocEntry
        AND DocTipo = oDocTipo
        AND Docnum = oDocNum
      LIMIT 1;
    END IF;
   
   
   IF xIncAlt = "I" THEN
      INSERT INTO tbintegraSAP_DocItem
         (DocEntry, DocTipo, DocNum, LineNum, ItemCode, BaseQty, PlannedQty, IssuedQty,
          WhareHouse, Price, DollarQuote, Usage_, CFOPCode, TaxCode,
          UgpEntry, UomCode, unitMsr, OpenInvQty,
          IssueType, StatusItem, Observacoes,
          description, buyUnitMsr, salUnitMsr, invntryUom, ManBtchNum, ManSerNum, 
          NumInSale, NumInBuy, BatchNumbersCode, DataFabricacao, DataValidade,
          dthr_inc, usu_inc)
      VALUES 
         (oDocEntry, oDocTipo, oDocNum, xLineNum, oItemCode, oBaseQty, oPlannedQty, oIssuedQty,
          oWhareHouse, oPrice, oDollarQuote, oUsage, oCFOPCode, oTaxCode,
          oUgpEntry, oUomCode, ounitMsr, oOpenInvQty,
          oIssueType, NULL, oObservacoes, 
          oDescrProduto, oEmbCompras, oEmbVendas, oEmbEstoque, oManBtchNum, oManSerNum, 
          IF(xTipoDocSLIN='S',oNumInSale,NumInSale), IF(xTipoDocSLIN='E',oNumInSale,NumInBuy), 
          oBatchNumbersCode, oDataFabricacao, oDataValidade,
          NOW(), oCodUsuario);
      SET MENSAGEM = "Registro inserido com sucesso";
      
   ELSEIF EXISTS (SELECT 1 FROM tbintegraSAP_DocItem
                  WHERE DocEntry = oDocEntry
                    AND DocTipo  = oDocTipo
                    AND ItemCode = oItemCode
                    AND (BaseQty <> oBaseQty
                    #@Reviser David Ruy <2020/02/28> Força condição para Nunca atualizar a integração pois já 
                    #                                existem endpoints de atualização / cancelamento
                    AND FALSE
                    #
                       OR IFNULL(PlannedQty,0) <> oPlannedQty
                       #OR IssuedQty <> oIssuedQty
                       OR IFNULL(WhareHouse,'') <> oWhareHouse
                       OR IFNULL(Price,0) <> oPrice
                       OR IFNULL(DollarQuote,0) <> oDollarQuote
                       #OR IssueType <> oIssueType
                       OR IFNULL(description,'') <> oDescrProduto
                       OR IFNULL(UgpEntry,'')   <> oUgpEntry
                       OR IFNULL(unitMsr,'')    <> ounitMsr
                       OR IFNULL(OpenInvQty,'') <> oOpenInvQty
                       #OR IFNULL(buyUnitMsr,'') <> oEmbCompras
                       #OR IFNULL(salUnitMsr,'') <> oEmbVendas
                       #OR IFNULL(invntryUom,'') <> oEmbEstoque
                       OR IF(xTipoDocSLIN='S', 
                             IFNULL(NumInSale,0) <> oNumInSale, 
                             IFNULL(NumInBuy,0)  <> oNumInSale))) THEN
      UPDATE tbintegraSAP_DocItem SET
         #DocEntry = oDocEntry
         #,DocTipo = oDocTipo
         #,DocNum = oDocNum
         #,LineNum = oLineNum
          ItemCode = oItemCode
         ,BaseQty = oBaseQty
         ,PlannedQty  = oPlannedQty
         ,IssuedQty   = oIssuedQty
         ,WhareHouse  = oWhareHouse
         ,Price       = oPrice
         ,DollarQuote = oDollarQuote
         ,Usage_      = oUsage
         ,CFOPCode    = oCFOPCode
         ,TaxCode     = oTaxCode 
         ,UgpEntry    = oUgpEntry
         ,UomCode     = oUomCode
         ,unitMsr     = ounitMsr
         ,OpenInvQty  = oOpenInvQty
         ,IssueType   = oIssueType
         ,StatusItem  = 1
         ,Observacoes = IF(LENGTH(IFNULL(oObservacoes,''))=0,NULL, oObservacoes)
         ,description = oDescrProduto
         ,buyUnitMsr  = oEmbCompras
         ,salUnitMsr  = oEmbVendas
         ,invntryUom  = oEmbEstoque 
         ,ManBtchNum = oManBtchNum
         ,ManSerNum  = oManSerNum
         ,NumInSale  = IF(xTipoDocSLIN='S',oNumInSale, NumInSale)
         ,NumInBuy   = IF(xTipoDocSLIN='S',NumInBuy, oNumInSale)
         ,BatchNumbersCode = oBatchNumbersCode
         ,DataFabricacao   = oDataFabricacao
         ,DataValidade     = oDataValidade
         ,dthr_alt    = NOW()
         ,usu_alt     = oCodUsuario
      WHERE DocEntry  = oDocEntry
        AND DocTipo   = oDocTipo
        #AND ItemCode = oItemCode;
        AND LineNum   = oLineNum;
        
      IF ROW_COUNT() > 0 THEN
         SET MENSAGEM = "Registro atualizado com sucesso";
         SET xStatusItem = 1;
      ELSE
         SET MENSAGEM = CONCAT("Registro não atualizado - Sem alterações identificadas");
         SET xStatusItem = 0;
      END IF;
   ELSE
         SET MENSAGEM = CONCAT("Registro não atualizado - Sem alterações identificadas");
         SET xStatusItem = 0;
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