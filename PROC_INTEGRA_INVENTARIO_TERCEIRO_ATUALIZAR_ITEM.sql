DELIMITER $$

DROP PROCEDURE IF EXISTS `PROC_INTEGRA_INVENTARIO_TERCEIRO_ATUALIZAR_ITEM`$$

CREATE PROCEDURE `PROC_INTEGRA_INVENTARIO_TERCEIRO_ATUALIZAR_ITEM`(
   IN oCodUsuario				   VARCHAR(10),

   IN oIdInventario     VARCHAR(10),
   IN oItemCode         VARCHAR(30),
   IN oItemName         VARCHAR(100),
   IN oflg_series       TINYINT,
   IN oflg_lotes        TINYINT,

   IN oEmbVendas        VARCHAR(10),
   IN oFatorConvVendas  DECIMAL(18,6),
   IN oUnidadeCompras   VARCHAR(10),
   IN oFatorConvCompras DECIMAL(18,6),
   IN oEmbEstoque       VARCHAR(10),
   IN oBarCode          VARCHAR(200),

   IN oQtdeEstoque      DECIMAL(18,6),
   IN oValorUnitario    DECIMAL(18,6),

   IN oSerieFabr        VARCHAR(50),
   IN oNumLoteFabr      VARCHAR(50),
   IN oDataFabr         VARCHAR(20),
   IN oDataValid        VARCHAR(20),
   
   IN oQtdeItens        INT,
   IN oCountItens       INT,
	
	# Parametros de Retorno
	OUT RESULTADO          BOOLEAN,
	OUT MENSAGEM           VARCHAR(500)
)
BLOCO1:BEGIN
   /******************************************************************************
   @Author <David Ruy (OVERFLASH)>
   @Creation <2026-04-23>
   @Description Esta rotina insere itens e atualiza as tabelas tbwms_inventario_terceiro_produto e 
                tbwms_inventario_terceiro_produto_serie_lote para o controle de inventário em terceiros
   *******************************************************************************/

  /****************************************************************/
  /****************DECLARAR VARIÁVEIS AUXILIARES
  /****************************************************************/
   DECLARE excecao                TINYINT DEFAULT 0;
   DECLARE xid_inventario_produto INT     DEFAULT 0;
   DECLARE xdthr_leitura_terceiro DATETIME;
   DECLARE xdthr_retorno_terceiro DATETIME;
   DECLARE xdthr_liberacao_contagem2 DATETIME;
   DECLARE xdata_final               DATETIME;
   DECLARE xVarLotesSeries           INT DEFAULT 0;
   DECLARE xQtdeItens                INT DEFAULT 0;



   DECLARE EXIT HANDLER FOR SQLEXCEPTION
   BEGIN
       GET DIAGNOSTICS CONDITION 1 MENSAGEM = MESSAGE_TEXT;
       SET excecao   = 1;
       SET RESULTADO = 0;
       SET MENSAGEM  = of_logistica.fnMensagemExcecao(MENSAGEM);
       ROLLBACK;
   END;
   
   
   
   START TRANSACTION;
   
   SET RESULTADO = 1;
   SET MENSAGEM = "Inclusão do item realizado com sucesso !";

   
   
   
   #Busca dados do topo do inventário para validações
   SELECT dthr_leitura_terceiro, dthr_retorno_terceiro, data_final
   INTO xdthr_leitura_terceiro, xdthr_retorno_terceiro, xdata_final
   FROM of_logistica.tbwms_inventario_terceiro
   WHERE id_inventario = oIdInventario;
   
   
   #Validação de conclusão do inventário, não permite inserir mais itens
   IF (xdthr_retorno_terceiro IS NOT NULL) OR (xdata_final IS NOT NULL) THEN
      SET RESULTADO = 0;
      SET MENSAGEM  = CONCAT('Inventário já foi finalizado ! Data Finalização : ', xdata_final, ', Data Retorno : ', xdthr_retorno_terceiro);
      ROLLBACK;
      LEAVE bloco1;
   END IF;
   
   
   #Se 1o item, então limpa a base de produtos do inventário
   #pois pode ser importação de atualização de estoque contábil
   IF oQtdeItens = 1 THEN
      DELETE FROM of_logistica.tbwms_inventario_terceiro_produto_serie_lote tbLotes
      WHERE EXISTS (SELECT 1 FROM of_logistica.tbwms_inventario_terceiro_produto tbProd
                    WHERE tbLotes.id_inventario_produto = tbProd.id_inventario_produto
                      AND tbProd.id_inventario = oIdInventario);
      DELETE FROM of_logistica.tbwms_inventario_terceiro_produto
      WHERE id_inventario = oIdInventario;
   END IF;
   
   
   #Busca dados do Item do Inventário para validações
   SELECT id_inventario_produto, dthr_liberacao_contagem2 
   INTO xid_inventario_produto, xdthr_liberacao_contagem2
   FROM of_logistica.tbwms_inventario_terceiro_produto 
   WHERE id_inventario = oIdInventario
     AND cod_produto   = oItemCode;
     
     
     
   #Ajusta variáveis
   SET xVarLotesSeries = IF(oflg_lotes = 1, 2, IF(oflg_series = 1, 3, 1));
   SET oDataFabr  = IF(oDataFabr = '', NULL, oDataFabr);
   SET oDataValid = IF(oDataValid= '', NULL, oDataValid);
   
   
   
   #Insere/Atualiza ITEM     
   IF IFNULL(xid_inventario_produto,0) = 0 THEN
                  
      INSERT INTO of_logistica.tbwms_inventario_terceiro_produto (
                  id_inventario, cod_produto, descr_produto, 
                  barcode01, barcode02, barcode03, 
                  flg_controle_validade, flg_controle_estoque, 
                  flg_tipo_embalagem_valor, fator_conversao, vlr_unitario)
      VALUES (oIdInventario, oItemCode, oItemName, 
              oBarCode, NULL, NULL, 
              IF(oDataFabr IS NULL, 0, 1), /*Controle Validade */
              xVarLotesSeries, /*Controle Lote/Serie,Nenhum*/
              1, /*Valorização pela embalagem de estoque*/
              oFatorConvVendas, oValorUnitario);
              
   ELSEIF xdthr_liberacao_contagem2 IS NULL THEN
   
      SET RESULTADO = 1;
      SET MENSAGEM = "Alteração do item realizado com sucesso !";
      
      UPDATE of_logistica.tbwms_inventario_terceiro_produto 
      SET id_inventario              = oIdInventario, 
          cod_produto                = oItemCode, 
          descr_produto              = oItemName, 
          barcode01                  = oBarCode, 
          barcode02                  = NULL, 
          barcode03                  = NULL, 
          flg_controle_validade      = IF(oDataFabr IS NULL, 0, 1), /*Controle Validade */
          flg_controle_estoque       = xVarLotesSeries, /*Controle Lote/Serie,Nenhum*/
          flg_tipo_embalagem_valor   = 1, /*Valorização pela embalagem de estoque*/
          fator_conversao            = oFatorConvVendas, 
          vlr_unitario               = oValorUnitario
      WHERE id_inventario = oIdInventario
        AND cod_produto   = oItemCode;
       
   ELSE
   
      SET RESULTADO = 0;
      SET MENSAGEM  = CONCAT('2a contagem deste item já foi liberada - Atualização não realizada - Produto : ', oItemCode, ' - ', oItemName);
      ROLLBACK;
      LEAVE bloco1;   
      
   END IF;
   

   #Insere/Atualiza Lote/Série
   IF IFNULL(oSerieFabr,'') <> '' OR IFNULL(oNumLoteFabr,'') <> '' THEN
   
      SELECT id_inventario_produto INTO xid_inventario_produto
      FROM of_logistica.tbwms_inventario_terceiro_produto
      WHERE id_inventario = oIdInventario
       AND cod_produto    = oItemCode;
   
      IF NOT EXISTS (SELECT 1 FROM of_logistica.tbwms_inventario_terceiro_produto_serie_lote
                     WHERE id_inventario_produto = xid_inventario_produto
                       AND numero_serie          = oSerieFabr
                       AND numero_lote_fabr      = oNumLoteFabr) THEN
                     
         SET RESULTADO = 1;
         SET MENSAGEM = CONCAT(MENSAGEM, " Inclusão do lote/série realizado com sucesso !");

         INSERT INTO of_logistica.tbwms_inventario_terceiro_produto_serie_lote (
                id_inventario_produto, data_fabr, data_valid, 
                numero_lote_fabr, numero_serie, 
                embalagem_estoque, qtde_emb_estoque, 
                embalagem_secundaria, qtde_emb_secundaria)
         VALUES (xid_inventario_produto, oDataFabr, oDataValid, 
                 oNumLoteFabr, oSerieFabr,
                 oEmbEstoque, oQtdeEstoque,
                 oEmbVendas, NULL);
      ELSE
      
         SET RESULTADO = 1;
         SET MENSAGEM = CONCAT(MENSAGEM, " Alteração do lote/série realizado com sucesso !");

         UPDATE of_logistica.tbwms_inventario_terceiro_produto_serie_lote 
         SET data_fabr            = oDataFabr,  
             data_valid           = oDataValid, 
             numero_lote_fabr     = oNumLoteFabr, 
             numero_serie         = oSerieFabr,
             embalagem_estoque    = oEmbEstoque, 
             qtde_emb_estoque     = oQtdeEstoque,
             embalagem_secundaria = oEmbVendas, 
             qtde_emb_secundaria  = NULL
         WHERE id_inventario_produto = xid_inventario_produto
           AND numero_serie          = oSerieFabr
           AND numero_lote_fabr      = oNumLoteFabr;
      END IF;
   
   END IF;

   COMMIT;
   
   SELECT COUNT(*) INTO xQtdeItens 
   FROM of_logistica.tbwms_inventario_terceiro_produto_serie_lote tbLotes
   INNER JOIN of_logistica.tbwms_inventario_terceiro_produto tbProd ON
              tbProd.id_inventario_produto = tbLotes.id_inventario_produto
   WHERE tbProd.id_inventario = oIdInventario;
   
   #Checa QtdeTotal do parametro X Qtde efetivamente Inserida
   #Atualiza Status do Inventário (Leitura de Saldo Contábil concluída - Liberado para contagem)
   IF oCountItens = xQtdeItens  THEN
      UPDATE of_logistica.tbwms_inventario_terceiro
      SET dthr_leitura_terceiro = NOW()
      WHERE id_inventario = oIdInventario;

      SET RESULTADO = 1;
      SET MENSAGEM = CONCAT(MENSAGEM, " - Leitura Contábil concluída.");

   END IF;
   
   
END$$

DELIMITER ;