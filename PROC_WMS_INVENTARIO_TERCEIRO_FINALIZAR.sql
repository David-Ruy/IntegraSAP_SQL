DELIMITER $$

DROP PROCEDURE IF EXISTS `PROC_WMS_INVENTARIO_TERCEIRO_FINALIZAR`$$

CREATE PROCEDURE `PROC_WMS_INVENTARIO_TERCEIRO_FINALIZAR`(
   IN oIdInventario    INT,
   IN oCodUsuario      VARCHAR(06),
   IN oGerarFechamento INT,
   OUT RESULTADO       INT,
   OUT MENSAGEM        VARCHAR(500)
)
BLOCO1:BEGIN
   /******************************************************************************
   @Author <David Ruy (OVERFLASH)>
   @Creation <2026-04-23>
   @Description : Esta rotina gera o fechamento do inventário atualizando as tabelas 
                  tbwms_inventario_terceiro_fechamento e tbwms_inventario_terceiro_fechamento_serie_lote
   Range oGerarFechamento : 0 - Lista Relatório de Divergencias
                            1 - Listar Relatório de Inventário
                            5 - Fechamento
   *******************************************************************************/

  /****************************************************************/
  /****************DECLARAR VARIÁVEIS AUXILIARES
  /****************************************************************/
   DECLARE excecao                TINYINT DEFAULT 0;
   DECLARE xdthr_leitura_terceiro  DATETIME;
   DECLARE xdthr_retorno_terceiro  DATETIME;
   DECLARE xdata_final             DATETIME;
   DECLARE xtipo_doc_terceiro_entrada  VARCHAR(50);
   DECLARE xchave_doc_terceiro_entrada VARCHAR(50);
   DECLARE xtipo_doc_terceiro_saida    VARCHAR(50);
   DECLARE xchave_doc_terceiro_saida   VARCHAR(50);
   DECLARE xNumContagem INT;
   DECLARE xDtHrFechamento             DATETIME;





   DECLARE EXIT HANDLER FOR SQLEXCEPTION
   BEGIN
       GET DIAGNOSTICS CONDITION 1 MENSAGEM = MESSAGE_TEXT;
       SET excecao   = 1;
       SET RESULTADO = 0;
       SET MENSAGEM  = fnMensagemExcecao(MENSAGEM);
       ROLLBACK;
   END;
   

  
   #Busca dados do topo do inventário para validações
   SELECT dthr_leitura_terceiro, dthr_retorno_terceiro, data_final, 
          tipo_doc_terceiro_entrada, chave_doc_terceiro_entrada,
          tipo_doc_terceiro_saida, chave_doc_terceiro_saida
   INTO xdthr_leitura_terceiro, xdthr_retorno_terceiro, xdata_final, 
        xtipo_doc_terceiro_entrada, xchave_doc_terceiro_entrada,
        xtipo_doc_terceiro_saida, xchave_doc_terceiro_saida
   FROM tbwms_inventario_terceiro
   WHERE id_inventario = oIdInventario;
   

   IF oGerarFechamento = 5 AND xdata_final IS NOT NULL THEN

      SET RESULTADO = 0;
      SET MENSAGEM = CONCAT("Inventário já foi finalizado - Processo não será realizado, verifique listagem do fechamento !");
      LEAVE bloco1;

   END IF;
   
   
   #Topo : Dados do Inventário
   DROP TEMPORARY TABLE IF EXISTS tbTMP_Ajustes;
   CREATE TEMPORARY TABLE tbTMP_Ajustes
      SELECT tbwms_inventario_terceiro.id_inventario, 
           tbwms_inventario_terceiro.chave_terceiro, tbwms_inventario_terceiro.nome_terceiro,
           tbwms_inventario_terceiro.chave_doc_terceiro_entrada, tbwms_inventario_terceiro.tipo_doc_terceiro_entrada,
           tbwms_inventario_terceiro.chave_doc_terceiro_saida, tbwms_inventario_terceiro.tipo_doc_terceiro_saida
      FROM tbwms_inventario_terceiro
      WHERE tbwms_inventario_terceiro.id_inventario = oIdInventario;

   
   #Itens : Produtos e Quantidades Contábeis
   DROP TEMPORARY TABLE IF EXISTS tbTMP_Ajustes_Item;
   CREATE TEMPORARY TABLE tbTMP_Ajustes_Item
      SELECT tbwms_inventario_terceiro_produto.id_inventario_produto, tbwms_inventario_terceiro_produto.cod_produto,              
             tbwms_inventario_terceiro_produto.fator_conversao,
             (SELECT embalagem_estoque 
              FROM tbwms_inventario_terceiro_produto_serie_lote
              WHERE tbwms_inventario_terceiro_produto_serie_lote.id_inventario_produto = tbwms_inventario_terceiro_produto.id_inventario_produto) AS EmbEstoque,
             (SELECT embalagem_secundaria
              FROM tbwms_inventario_terceiro_produto_serie_lote
              WHERE tbwms_inventario_terceiro_produto_serie_lote.id_inventario_produto = tbwms_inventario_terceiro_produto.id_inventario_produto) AS EmbSecundaria,
           (SELECT SUM(qtde_emb_estoque) 
            FROM tbwms_inventario_terceiro_produto_serie_lote
            WHERE tbwms_inventario_terceiro_produto_serie_lote.id_inventario_produto = tbwms_inventario_terceiro_produto.id_inventario_produto)
            AS QtdeContabil
      FROM tbwms_inventario_terceiro_produto
      INNER JOIN tbTMP_Ajustes ON
                 tbTMP_Ajustes.id_inventario = tbwms_inventario_terceiro_produto.id_inventario;
   
   
   #Series_Lotes : Series/Lotes, Fabr, Validade, Quantidade
   DROP TEMPORARY TABLE IF EXISTS tbTMP_Ajustes_Serie_Lote;
   CREATE TEMPORARY TABLE tbTMP_Ajustes_Serie_Lote
      SELECT tbwms_inventario_terceiro_produto_serie_lote.id_inventario_produto, tbTMP_Ajustes_Item.cod_produto, 
             tbTMP_Ajustes_Item.fator_conversao, tbTMP_Ajustes_Item.EmbEstoque, 
             numero_lote_fabr, numero_serie, data_fabr, data_valid, embalagem_estoque, qtde_emb_estoque
      FROM tbwms_inventario_terceiro_produto_serie_lote
      INNER JOIN tbTMP_Ajustes_Item ON
                 tbTMP_Ajustes_Item.id_inventario_produto = tbwms_inventario_terceiro_produto_serie_lote.id_inventario_produto;
                 
   
   
   #Tabelas Saldo Contábil (DEBUG)
   #SELECT * FROM tbTMP_Ajustes;
   #SELECT * FROM tbTMP_Ajustes_Item;
   #SELECT * FROM tbTMP_Ajustes_Serie_Lote;
   
   
   
/**********************************************************************************/   
   
   
   
   #Tabelas de Inventariados por contagem
   DROP TEMPORARY TABLE IF EXISTS tbTMP_Contagem1;
   CREATE TEMPORARY TABLE tbTMP_Contagem1
   SELECT tbConf.num_contagem,
          tbTMP_Ajustes_Item.id_inventario_produto, tbTMP_Ajustes_Item.cod_produto, tbConf.numero_lote_fabr, tbConf.numero_serie, 
          tbConf.data_valid, tbConf.data_fabr, tbTMP_Ajustes_Item.fator_conversao,
          tbConf.embalagem, tbConf.quantidade QtdeContada, 
          tbTMP_Ajustes_Item.EmbEstoque,
          SUM( 
          IF(tbConf.embalagem = tbTMP_Ajustes_Item.EmbEstoque, tbConf.quantidade, tbConf.quantidade * tbTMP_Ajustes_Item.fator_conversao) 
          ) 
          QtdeInventario
   FROM tbwms_inventario_terceiro_conferencia tbConf
   INNER JOIN tbTMP_Ajustes_Item ON
              tbTMP_Ajustes_Item.id_inventario_produto = tbConf.id_inventario_produto
   WHERE num_contagem = 1
   GROUP BY num_contagem, id_inventario_produto, IFNULL(numero_lote_fabr, numero_serie), IFNULL(data_fabr, ''), IFNULL(data_valid, '');
   
   
   DROP TEMPORARY TABLE IF EXISTS tbTMP_Contagem2;
   CREATE TEMPORARY TABLE tbTMP_Contagem2
   SELECT tbConf.num_contagem,
          tbTMP_Ajustes_Item.id_inventario_produto, tbTMP_Ajustes_Item.cod_produto, tbConf.numero_lote_fabr, tbConf.numero_serie, 
          tbConf.data_valid, tbConf.data_fabr, tbTMP_Ajustes_Item.fator_conversao,
          tbConf.embalagem, tbConf.quantidade QtdeContada, 
          tbTMP_Ajustes_Item.EmbEstoque,
          SUM( 
          IF(tbConf.embalagem = tbTMP_Ajustes_Item.EmbEstoque, tbConf.quantidade, tbConf.quantidade * tbTMP_Ajustes_Item.fator_conversao) 
          ) 
          QtdeInventario
   FROM tbwms_inventario_terceiro_conferencia tbConf
   INNER JOIN tbTMP_Ajustes_Item ON
              tbTMP_Ajustes_Item.id_inventario_produto = tbConf.id_inventario_produto
   WHERE num_contagem = 2
   GROUP BY num_contagem, id_inventario_produto, IFNULL(numero_lote_fabr, numero_serie), IFNULL(data_fabr, ''), IFNULL(data_valid, '');
   
   DROP TEMPORARY TABLE IF EXISTS tbTMP_Contagem3;
   CREATE TEMPORARY TABLE tbTMP_Contagem3
   SELECT tbConf.num_contagem,
          tbTMP_Ajustes_Item.id_inventario_produto, tbTMP_Ajustes_Item.cod_produto, tbConf.numero_lote_fabr, tbConf.numero_serie, 
          tbConf.data_valid, tbConf.data_fabr, tbTMP_Ajustes_Item.fator_conversao,
          tbConf.embalagem, tbConf.quantidade QtdeContada, 
          tbTMP_Ajustes_Item.EmbEstoque,
          SUM( 
          IF(tbConf.embalagem = tbTMP_Ajustes_Item.EmbEstoque, tbConf.quantidade, tbConf.quantidade * tbTMP_Ajustes_Item.fator_conversao) 
          ) 
          QtdeInventario
   FROM tbwms_inventario_terceiro_conferencia tbConf
   INNER JOIN tbTMP_Ajustes_Item ON
              tbTMP_Ajustes_Item.id_inventario_produto = tbConf.id_inventario_produto
   WHERE num_contagem = 3
   GROUP BY num_contagem, id_inventario_produto, IFNULL(numero_lote_fabr, numero_serie), IFNULL(data_fabr, ''), IFNULL(data_valid, '');
   
   
    #SELECT * FROM tbTMP_Contagem1 UNION ALL
    #SELECT * FROM tbTMP_Contagem2 UNION ALL
    #SELECT * FROM tbTMP_Contagem3;
    


/**********************************************************************************/   
    

   #Tabela de Consolidação do Inventário
   DROP TEMPORARY TABLE IF EXISTS tbTMP_Inventario;
   CREATE TEMPORARY TABLE tbTMP_Inventario (
      id_inventario_produto INT,
      cod_produto           VARCHAR(50), 
      numero_lote_fabr      VARCHAR(30), 
      numero_serie          VARCHAR(30),
      data_valid            DATE, 
      data_fabr             DATE, 
      fator_conversao       DECIMAL(18,6),
      EmbEstoque            VARCHAR(10),
      Contagem01            DECIMAL(18,6),
      Contagem02            DECIMAL(18,6),
      Contagem03            DECIMAL(18,6),
      Contabil              DECIMAL(18,6),
      GerarEntrada          DECIMAL(18,6),
      GerarSaida            DECIMAL(18,6),
      PRIMARY KEY (cod_produto, numero_lote_fabr, numero_serie, data_valid, data_fabr)
   );

    #Insere Dados da 1a contagem
    INSERT INTO tbTMP_Inventario (
           id_inventario_produto, cod_produto, numero_lote_fabr, 
           numero_serie, data_valid, data_fabr, 
           fator_conversao, EmbEstoque, 
           Contagem01, Contagem02, Contagem03)
       SELECT id_inventario_produto, cod_produto, IFNULL(numero_lote_fabr,''), 
            IFNULL(numero_serie,''), data_valid, data_fabr, 
            fator_conversao, EmbEstoque, QtdeInventario, 0, 0
       FROM tbTMP_Contagem1;
       
    #Insere Dados da 2a contagem
    INSERT INTO tbTMP_Inventario (
           id_inventario_produto, cod_produto, numero_lote_fabr, 
           numero_serie, data_valid, data_fabr, 
           fator_conversao, EmbEstoque, 
           Contagem01, Contagem02, Contagem03)
       SELECT id_inventario_produto, cod_produto, IFNULL(numero_lote_fabr,''), 
            IFNULL(numero_serie,''), data_valid, data_fabr, 
            fator_conversao, EmbEstoque, QtdeInventario, 0, 0
       FROM tbTMP_Contagem2
    ON DUPLICATE KEY UPDATE  
       Contagem02 = QtdeInventario;
       
    #Insere Dados da 3a contagem
    INSERT INTO tbTMP_Inventario (
           id_inventario_produto, cod_produto, numero_lote_fabr, 
           numero_serie, data_valid, data_fabr, 
           fator_conversao, EmbEstoque, 
           Contagem01, Contagem02, Contagem03)
       SELECT id_inventario_produto, cod_produto, IFNULL(numero_lote_fabr,''), 
            IFNULL(numero_serie,''), data_valid, data_fabr, 
            fator_conversao, EmbEstoque, QtdeInventario, 0, 0
       FROM tbTMP_Contagem3
    ON DUPLICATE KEY UPDATE  
       Contagem03 = QtdeInventario;
       
           
   DROP TEMPORARY TABLE IF EXISTS tbTMP_Contagem1;
   DROP TEMPORARY TABLE IF EXISTS tbTMP_Contagem2;
   DROP TEMPORARY TABLE IF EXISTS tbTMP_Contagem3;
   

   
/******************************************************************************************/   



   #Listar Divergencias de Contagens
   DROP TEMPORARY TABLE IF EXISTS tbTMP_Divergencias;
   CREATE TEMPORARY TABLE tbTMP_Divergencias (
      Mensagem              VARCHAR(200),
      cod_produto           VARCHAR(50), 
      numero_lote_fabr      VARCHAR(30), 
      numero_serie          VARCHAR(30),
      data_valid            DATE, 
      data_fabr             DATE, 
      fator_conversao       DECIMAL(18,6),
      EmbEstoque            VARCHAR(10),
      Contagem01            DECIMAL(18,6),
      Contagem02            DECIMAL(18,6),
      Contagem03            DECIMAL(18,6),
      Contabil              DECIMAL(18,6)
   );

   
   INSERT INTO tbTMP_Divergencias
      SELECT "Divergencias 1a X 2a contagem" AS Mensagem,  
         cod_produto, numero_lote_fabr, numero_serie, 
         data_valid, data_fabr, fator_conversao, EmbEstoque, 
         Contagem01, Contagem02, Contagem03, Contabil              
      FROM tbTMP_Inventario
      WHERE Contagem01 <> Contagem02 AND IFNULL(Contagem03,0) = 0;
    

   INSERT INTO tbTMP_Divergencias
      SELECT "Divergencias 1a ou 2a X 3contagem" AS Mensagem, 
         cod_produto, numero_lote_fabr, numero_serie, 
         data_valid, data_fabr, fator_conversao, EmbEstoque, 
         Contagem01, Contagem02, Contagem03, Contabil                    
      FROM tbTMP_Inventario
      WHERE Contagem03 <> 0 AND Contagem01 <> Contagem03 AND Contagem02 <> Contagem03;

   IF oGerarFechamento = 0 THEN
      SELECT * FROM tbTMP_Divergencias;
   END IF;
   

   IF oGerarFechamento = 5 AND EXISTS (SELECT 1 FROM tbTMP_Divergencias LIMIT 1) THEN
      SET RESULTADO = 0;
      SET MENSAGEM  = "Identificadas Divergencias - Fechamento não pode ser realizado";
   END IF;
   


/******************************************************************************************/   

   
    #Insere Dados das Quantidades Contábeis
   INSERT INTO tbTMP_Inventario (
           id_inventario_produto, cod_produto, numero_lote_fabr, 
           numero_serie, data_valid, data_fabr, 
           fator_conversao, EmbEstoque, Contabil)
       SELECT id_inventario_produto, cod_produto, IFNULL(numero_lote_fabr,''), 
           IFNULL(numero_serie,''), data_valid, data_fabr, 
           fator_conversao, EmbEstoque, qtde_emb_estoque
       FROM tbTMP_Ajustes_Serie_Lote tbContabil 
   ON DUPLICATE KEY UPDATE
      Contabil = tbContabil.qtde_emb_estoque;
   
   
   
   UPDATE tbTMP_Inventario
   SET Contagem01 = IF(IFNULL(Contagem01,0)=0,NULL,Contagem01),
       Contagem02 = IF(IFNULL(Contagem02,0)=0,NULL,Contagem02),
       Contagem03 = IF(IFNULL(Contagem03,0)=0,NULL,Contagem03),
       Contabil   = IF(IFNULL(Contabil,0)=0,NULL,Contabil),
       GerarEntrada = IF( IFNULL(Contagem03, IFNULL(Contagem01,0) ) - IFNULL(Contabil,0) < 0, 0, IFNULL(Contagem03, IFNULL(Contagem01,0)) - IFNULL(Contabil,0) ),
       GerarSaida   = IF( IFNULL(Contabil,0) - IFNULL(Contagem03, IFNULL(Contagem01,0) ) < 0, 0, IFNULL(Contabil,0) - IFNULL(Contagem03, IFNULL(Contagem01,0)) )
       ;
   
   
   IF oGerarFechamento = 1 THEN
      SELECT * FROM tbTMP_Inventario;
   END IF;

      
/******************************************************************************************/   


   #Gera Registros do Fechamento

   IF oGerarFechamento = 5 AND RESULTADO = 1 THEN

      START TRANSACTION;

      SET xDtHrFechamento = NOW();
      INSERT INTO tbwms_inventario_terceiro_fechamento (
            id_inventario, id_inventario_produto, qtde_conferencia_inventario,
            qtde_ajuste_entrada, qtde_ajuste_saida, dthr_inc, usu_inc)
           SELECT oIdInventario, id_inventario_produto, 
                  IFNULL(SUM(IFNULL(Contagem03, Contagem01)), 0), 
                  IFNULL(SUM(GerarEntrada), 0), 
                  IFNULL(SUM(GerarSaida), 0), xDtHrFechamento , oCodUsuario
           FROM tbTMP_Inventario
           GROUP BY id_inventario_produto;
           
      INSERT INTO tbwms_inventario_terceiro_fechamento_serie_lote (
                  id_inventario_fechamento, numero_lote_fabr, numero_serie, 
                  data_fabr, data_valid, qtde_conferencia_inventario, 
                  qtde_ajuste_entrada, qtde_ajuste_saida)
         SELECT tbFech.id_inventario_fechamento, tbTMP_Inventario.numero_lote_fabr, tbTMP_Inventario.numero_serie, 
                  tbTMP_Inventario.data_fabr, tbTMP_Inventario.data_valid,  
                  IFNULL(IFNULL(Contagem03, Contagem01), 0), 
                  IFNULL(GerarEntrada, 0), 
                  IFNULL(GerarSaida, 0)
           FROM tbTMP_Inventario
           INNER JOIN tbwms_inventario_terceiro_fechamento tbFech ON
                      tbFech.id_inventario_produto = tbTMP_Inventario.id_inventario_produto;


       UPDATE tbwms_inventario_terceiro 
       SET data_final = CURRENT_DATE, dthr_alt = NOW(), usu_alt = oCodUsuario
       WHERE id_inventario = oIdInventario;
       
       SET RESULTADO = 1;
       SET MENSAGEM  = "FECHAMENTO REALIZADO COM SUCESSO ! ";

       COMMIT;

   ELSE

      IF oGerarFechamento IN (0,1) THEN
         SET RESULTADO = 1;
         SET MENSAGEM  = "LISTAGEM GERADA COM SUCESSO ! ";
      END IF;
   
   END IF;


/******************************************************************************************/   

   #Excluir tabelas Temporárias
   DROP TEMPORARY TABLE IF EXISTS tbTMP_Ajustes;
   DROP TEMPORARY TABLE IF EXISTS tbTMP_Ajustes_Item;
   DROP TEMPORARY TABLE IF EXISTS tbTMP_Ajustes_Serie_Lote;
   DROP TEMPORARY TABLE IF EXISTS tbTMP_Inventario;
   DROP TEMPORARY TABLE IF EXISTS tbTMP_Divergencias;

   

END$$

DELIMITER ;


