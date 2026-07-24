DELIMITER $$

DROP PROCEDURE IF EXISTS `PROC_INTEGRA_INVENTARIO_TERCEIRO_LISTAR_AJUSTES`$$

CREATE PROCEDURE `PROC_INTEGRA_INVENTARIO_TERCEIRO_LISTAR_AJUSTES`(
   IN oIdInventario    INT,
   IN oTipoAjuste      VARCHAR(10)    #Entrada/Saída
)
BLOCO1:BEGIN
   /******************************************************************************
   @Author <David Ruy (OVERFLASH)>
   @Creation <2026-04-23>
   @Description : Esta rotina Lista os itens com divergencia a maior no inventário
                  para que seja gerada a entrada de ajustes no ERP desejado
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
   

   
   #Busca dados do topo do inventário para validações
   SELECT dthr_leitura_terceiro, dthr_retorno_terceiro, data_final, 
          tipo_doc_terceiro_entrada, chave_doc_terceiro_entrada,
          tipo_doc_terceiro_saida, chave_doc_terceiro_saida
   INTO xdthr_leitura_terceiro, xdthr_retorno_terceiro, xdata_final, 
        xtipo_doc_terceiro_entrada, xchave_doc_terceiro_entrada,
        xtipo_doc_terceiro_saida, xchave_doc_terceiro_saida
   FROM of_logistica.tbwms_inventario_terceiro
   WHERE id_inventario = oIdInventario;
   
   IF oTipoAjuste = 'Entrada' AND xchave_doc_terceiro_entrada IS NOT NULL THEN
      SELECT 0 AS RESULTADO, 
             CONCAT("Documento de Ajustes de Entrada do Inventário já foi gerado - ",
             xtipo_doc_terceiro_entrada,xchave_doc_terceiro_entrada) AS MENSAGEM;
      LEAVE bloco1;
   END IF;

   IF oTipoAjuste = 'Saída' AND xchave_doc_terceiro_saida IS NOT NULL THEN
      SELECT 0 AS RESULTADO, 
             CONCAT("Documento de Ajustes de Saída do Inventário já foi gerado - ",
             xtipo_doc_terceiro_saida,xchave_doc_terceiro_saida) AS MENSAGEM;
      LEAVE bloco1;
   END IF;

   
   IF oTipoAjuste = 'Entrada' THEN
      DROP TEMPORARY TABLE IF EXISTS tbTMP_Fech;
      CREATE TEMPORARY TABLE tbTMP_Fech
         SELECT chave_terceiro, nome_terceiro,
                tbProd.id_inventario, tbProd.cod_produto, tbProd.descr_produto, 
                tbAux.embalagem_estoque,
                tbFech.qtde_ajuste_entrada AS qtde_ajuste, tbProd.vlr_unitario,
                tbFech.id_inventario_fechamento
         FROM of_logistica.tbwms_inventario_terceiro_fechamento tbFech
         INNER JOIN of_logistica.tbwms_inventario_terceiro_produto_serie_lote tbAux ON 
                    tbAux.id_inventario_produto = tbFech.id_inventario_produto
         INNER JOIN of_logistica.tbwms_inventario_terceiro tbInventario ON
                    tbInventario.id_inventario = tbFech.id_inventario
         INNER JOIN of_logistica.tbwms_inventario_terceiro_produto tbProd ON
                    tbProd.id_inventario_produto = tbFech.id_inventario_produto
         WHERE tbFech.id_inventario = oIdInventario AND qtde_ajuste_entrada > 0;
         
         
      DROP TEMPORARY TABLE IF EXISTS tbTMP_FechLotes;
      CREATE TEMPORARY TABLE tbTMP_FechLotes
         SELECT tbFech.cod_produto, tbFech_SL.numero_lote_fabr, tbFech_SL.numero_serie, 
                tbFech_SL.data_fabr, tbFech_SL.data_valid, tbFech_SL.qtde_ajuste_entrada  AS qtde_ajuste
         FROM of_logistica.tbwms_inventario_terceiro_fechamento_serie_lote tbFech_SL
         INNER JOIN tbTMP_Fech tbFech ON
                    tbFech.id_inventario_fechamento = tbFech_SL.id_inventario_fechamento
         WHERE tbFech.id_inventario = oIdInventario
           AND tbFech_SL.qtde_ajuste_entrada > 0;
   END IF;
   

   IF oTipoAjuste = 'Saida' THEN
      DROP TEMPORARY TABLE IF EXISTS tbTMP_Fech;
      CREATE TEMPORARY TABLE tbTMP_Fech
         SELECT chave_terceiro, nome_terceiro,
                tbProd.id_inventario, tbProd.cod_produto, tbProd.descr_produto, 
                tbAux.embalagem_estoque,
                tbFech.qtde_ajuste_saida AS qtde_ajuste, tbProd.vlr_unitario,
                tbFech.id_inventario_fechamento
         FROM of_logistica.tbwms_inventario_terceiro_fechamento tbFech
         INNER JOIN of_logistica.tbwms_inventario_terceiro_produto_serie_lote tbAux ON 
                    tbAux.id_inventario_produto = tbFech.id_inventario_produto
         INNER JOIN of_logistica.tbwms_inventario_terceiro tbInventario ON
                    tbInventario.id_inventario = tbFech.id_inventario
         INNER JOIN of_logistica.tbwms_inventario_terceiro_produto tbProd ON
                    tbProd.id_inventario_produto = tbFech.id_inventario_produto
         WHERE tbFech.id_inventario = oIdInventario AND qtde_ajuste_saida > 0;
         
         
      DROP TEMPORARY TABLE IF EXISTS tbTMP_FechLotes;
      CREATE TEMPORARY TABLE tbTMP_FechLotes
         SELECT tbFech.cod_produto, tbFech_SL.numero_lote_fabr, tbFech_SL.numero_serie, 
                tbFech_SL.data_fabr, tbFech_SL.data_valid, tbFech_SL.qtde_ajuste_saida  AS qtde_ajuste
         FROM of_logistica.tbwms_inventario_terceiro_fechamento_serie_lote tbFech_SL
         INNER JOIN tbTMP_Fech tbFech ON
                    tbFech.id_inventario_fechamento = tbFech_SL.id_inventario_fechamento
         WHERE tbFech.id_inventario = oIdInventario
           AND tbFech_SL.qtde_ajuste_saida > 0;
   END IF;
   

   SELECT oTipoAjuste 'TipoAjuste', tbTMP_Fech.* FROM tbTMP_Fech;
   SELECT oTipoAjuste 'TipoAjuste', tbTMP_FechLotes.* FROM tbTMP_FechLotes;


   DROP TEMPORARY TABLE IF EXISTS tbTMP_Fech;
   DROP TEMPORARY TABLE IF EXISTS tbTMP_FechLotes;

   

END$$

DELIMITER ;


