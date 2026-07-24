DELIMITER $$

DROP PROCEDURE IF EXISTS `PROC_INTEGRA_INVENTARIO_TERCEIRO_LISTAR`$$

CREATE PROCEDURE `PROC_INTEGRA_INVENTARIO_TERCEIRO_LISTAR`(
   IN oTipoRetorno				   INT
)
BLOCO1:BEGIN
   /******************************************************************************
   @Author <David Ruy (OVERFLASH)>
   @Creation <2026-04-23>
   @Description Esta rotina Lista os inventários conforme o status de acordo com o parametro oTipoRetorno :
                0 - Aguardando Leitura do estoque Contábil
                1 - Em andamento 1a Contagem
                2 - Em andamento 2a Contagem
                3 - Em andamento 3a Contagem
                4 - Finalizado Não Retornado para SAP
                5 - Finalizado Retornado para SAP
   *******************************************************************************/

  /****************************************************************/
  /****************DECLARAR VARIÁVEIS AUXILIARES
  /****************************************************************/
   DECLARE excecao                TINYINT DEFAULT 0;
   
   IF oTipoRetorno = 0 THEN
      
      SELECT id_inventario, chave_terceiro, nome_terceiro, cnpj_cpf_cli, 
      data_inicio, data_final, dthr_leitura_terceiro, dthr_retorno_terceiro,
      flg_atualizar_terceiro, tipo_doc_terceiro_entrada, tipo_doc_terceiro_saida,
      chave_doc_terceiro_entrada, chave_doc_terceiro_saida
      FROM of_logistica.tbwms_inventario_terceiro
      WHERE dthr_leitura_terceiro IS NULL;
   
   ELSEIF oTipoRetorno = 1 THEN
   
      SELECT id_inventario, chave_terceiro, nome_terceiro, cnpj_cpf_cli, 
             data_inicio, data_final, dthr_leitura_terceiro, dthr_retorno_terceiro,
             flg_atualizar_terceiro, tipo_doc_terceiro_entrada, tipo_doc_terceiro_saida,
             chave_doc_terceiro_entrada, chave_doc_terceiro_saida,
             (SELECT COUNT(1) FROM of_logistica.tbwms_inventario_terceiro_produto 
              WHERE tbwms_inventario_terceiro_produto.id_inventario = tbwms_inventario_terceiro.id_inventario) QtdeItens,
             (SELECT COUNT(1) FROM of_logistica.tbwms_inventario_terceiro_produto 
              WHERE tbwms_inventario_terceiro_produto.id_inventario = tbwms_inventario_terceiro.id_inventario
                AND tbwms_inventario_terceiro_produto.dthr_liberacao_contagem2 IS NOT NULL) Qtde_1a_Contagem
      FROM of_logistica.tbwms_inventario_terceiro
      WHERE dthr_leitura_terceiro IS NOT NULL
        AND dthr_retorno_terceiro IS NULL
        AND data_final IS NULL
      HAVING Qtde_1a_Contagem < QtdeItens;
        

   ELSEIF oTipoRetorno = 2 THEN
   
      SELECT id_inventario, chave_terceiro, nome_terceiro, cnpj_cpf_cli, 
             data_inicio, data_final, dthr_leitura_terceiro, dthr_retorno_terceiro,
             flg_atualizar_terceiro, tipo_doc_terceiro_entrada, tipo_doc_terceiro_saida,
             chave_doc_terceiro_entrada, chave_doc_terceiro_saida,
             (SELECT COUNT(1) FROM of_logistica.tbwms_inventario_terceiro_produto 
              WHERE tbwms_inventario_terceiro_produto.id_inventario = tbwms_inventario_terceiro.id_inventario) QtdeItens,
             (SELECT COUNT(1) FROM of_logistica.tbwms_inventario_terceiro_produto 
              WHERE tbwms_inventario_terceiro_produto.id_inventario = tbwms_inventario_terceiro.id_inventario
                AND tbwms_inventario_terceiro_produto.dthr_liberacao_contagem2 IS NOT NULL) Qtde_1a_Contagem,
             (SELECT COUNT(1) FROM of_logistica.tbwms_inventario_terceiro_produto 
              WHERE tbwms_inventario_terceiro_produto.id_inventario = tbwms_inventario_terceiro.id_inventario
                AND tbwms_inventario_terceiro_produto.dthr_liberacao_contagem3 IS NULL) Qtde_2a_Contagem
      FROM of_logistica.tbwms_inventario_terceiro
      WHERE dthr_leitura_terceiro IS NOT NULL
        AND dthr_retorno_terceiro IS NULL
        AND data_final IS NULL
      HAVING Qtde_1a_Contagem = QtdeItens 
         AND Qtde_2a_Contagem < Qtde_1a_Contagem;

   ELSEIF oTipoRetorno = 3 THEN
   
      SELECT id_inventario, chave_terceiro, nome_terceiro, cnpj_cpf_cli, 
             data_inicio, data_final, dthr_leitura_terceiro, dthr_retorno_terceiro,
             flg_atualizar_terceiro, tipo_doc_terceiro_entrada, tipo_doc_terceiro_saida,
             chave_doc_terceiro_entrada, chave_doc_terceiro_saida,
             (SELECT COUNT(1) FROM of_logistica.tbwms_inventario_terceiro_produto 
              WHERE tbwms_inventario_terceiro_produto.id_inventario = tbwms_inventario_terceiro.id_inventario) QtdeItens,
             (SELECT COUNT(1) FROM of_logistica.tbwms_inventario_terceiro_produto 
              WHERE tbwms_inventario_terceiro_produto.id_inventario = tbwms_inventario_terceiro.id_inventario
                AND tbwms_inventario_terceiro_produto.dthr_liberacao_contagem2 IS NOT NULL) Qtde_1a_Contagem,
             (SELECT COUNT(1) FROM of_logistica.tbwms_inventario_terceiro_produto 
              WHERE tbwms_inventario_terceiro_produto.id_inventario = tbwms_inventario_terceiro.id_inventario
                AND tbwms_inventario_terceiro_produto.dthr_liberacao_contagem3 IS NOT NULL) Qtde_2a_Contagem
      FROM of_logistica.tbwms_inventario_terceiro
      WHERE dthr_leitura_terceiro IS NOT NULL
        AND dthr_retorno_terceiro IS NULL
        AND data_final IS NULL
      HAVING Qtde_1a_Contagem = QtdeItens 
         AND Qtde_2a_Contagem = Qtde_1a_Contagem;

   ELSEIF oTipoRetorno = 4 THEN
   
      SELECT id_inventario, chave_terceiro, nome_terceiro, cnpj_cpf_cli, 
             data_inicio, data_final, dthr_leitura_terceiro, dthr_retorno_terceiro,
             flg_atualizar_terceiro, tipo_doc_terceiro_entrada, tipo_doc_terceiro_saida,
             chave_doc_terceiro_entrada, chave_doc_terceiro_saida,
             (SELECT COUNT(1) FROM of_logistica.tbwms_inventario_terceiro_produto 
              WHERE tbwms_inventario_terceiro_produto.id_inventario = tbwms_inventario_terceiro.id_inventario) QtdeItens,
             (SELECT COUNT(1) FROM of_logistica.tbwms_inventario_terceiro_produto 
              WHERE tbwms_inventario_terceiro_produto.id_inventario = tbwms_inventario_terceiro.id_inventario
                AND tbwms_inventario_terceiro_produto.dthr_liberacao_contagem2 IS NOT NULL) Qtde_1a_Contagem,
             (SELECT COUNT(1) FROM of_logistica.tbwms_inventario_terceiro_produto 
              WHERE tbwms_inventario_terceiro_produto.id_inventario = tbwms_inventario_terceiro.id_inventario
                AND tbwms_inventario_terceiro_produto.dthr_liberacao_contagem3 IS NOT NULL) Qtde_2a_Contagem
      FROM of_logistica.tbwms_inventario_terceiro
      WHERE dthr_leitura_terceiro IS NOT NULL
        AND dthr_retorno_terceiro IS NULL
        AND data_final IS NOT NULL;
   
   
   ELSEIF oTipoRetorno = 5 THEN

      SELECT id_inventario, chave_terceiro, nome_terceiro, cnpj_cpf_cli, 
             data_inicio, data_final, dthr_leitura_terceiro, dthr_retorno_terceiro,
             flg_atualizar_terceiro, tipo_doc_terceiro_entrada, tipo_doc_terceiro_saida,
             chave_doc_terceiro_entrada, chave_doc_terceiro_saida,
             (SELECT COUNT(1) FROM of_logistica.tbwms_inventario_terceiro_produto 
              WHERE tbwms_inventario_terceiro_produto.id_inventario = tbwms_inventario_terceiro.id_inventario) QtdeItens,
             (SELECT COUNT(1) FROM of_logistica.tbwms_inventario_terceiro_produto 
              WHERE tbwms_inventario_terceiro_produto.id_inventario = tbwms_inventario_terceiro.id_inventario
                AND tbwms_inventario_terceiro_produto.dthr_liberacao_contagem2 IS NOT NULL) Qtde_1a_Contagem,
             (SELECT COUNT(1) FROM of_logistica.tbwms_inventario_terceiro_produto 
              WHERE tbwms_inventario_terceiro_produto.id_inventario = tbwms_inventario_terceiro.id_inventario
                AND tbwms_inventario_terceiro_produto.dthr_liberacao_contagem3 IS NOT NULL) Qtde_2a_Contagem
      FROM of_logistica.tbwms_inventario_terceiro
      WHERE dthr_leitura_terceiro IS NOT NULL
        AND dthr_retorno_terceiro IS NOT NULL
        AND data_final IS NOT NULL;

   ELSE

      SELECT 0 AS RESULTADO, "Opção incorreta - Selecione parametro de 0 à 5" AS MENSAGEM;
   
   END IF;

   
END$$

DELIMITER ;