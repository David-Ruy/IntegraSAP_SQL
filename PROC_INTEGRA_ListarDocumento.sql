DELIMITER $$

DROP PROCEDURE IF EXISTS `PROC_INTEGRA_ListarDocumento`$$

CREATE PROCEDURE `PROC_INTEGRA_ListarDocumento`(
   IN oDocTipo  				VARCHAR(10),
   IN oDocNum       INT,
   IN oDocEntry     INT,
   IN oIdPicking    INT
)
BLOCO1:BEGIN
   /*******************************************************************************************
   #@Author David Ruy <2021-01-15>
   #@Reviser David Ruy <2023-07-25> Ajuste condição oDocTipo like "PA%"
   #@Reviser David Ruy <2023-10-11> Ajuste condição AND (tbEntradasAcons.qtde_est > 0 OR tbEntradasAcons.qtde_est2 > 0);
   #@Reviser David Ruy <2023-10-11> Ajuste condição AND (tbSaidasAcons.qtde_est > 0 OR tbSaidasAcons.qtde_est2 > 0);
   #@Reviser David Ruy <2024-06-24> Melhora na condição if(parametro is null, true, campo = parametro
   #@Reviser David Ruy <2025-01-10> DocTipo = 'DC'  Devolução de Compras
   #@Reviser David Ruy <2025-04-04> join tbprodutos para campos de embalagens : tbEntradasItem.emb_est, emb_estoque_cli, fator_conv_vendas (Entradas)
   #@Reviser David Ruy <2026-04-07> join tbprodutos para campos de embalagens : tbEntradasItem.emb_est, emb_estoque_cli, fator_conv_vendas (Saídas)
   ********************************************************************************************/
   
   DECLARE xcnpj_cpf_cli   VARCHAR(20);
   #DECLARE CONTINUE HANDLER FOR SQLEXCEPTION SET excecao = 1;
   
   
   SELECT cnpj_cpf_cli INTO xcnpj_cpf_cli 
   FROM tbintegraSAP_parametros;
   
    
      
    IF oDocTipo IN ('PV','TD-S','OP','DC') THEN
      
       SELECT DocNum, DocEntry, IdPicking
       INTO oDocNum, oDocEntry, oIdPicking
       FROM tbintegraSAP_Doc
       LEFT JOIN of_logistica.tbsolic_saidas tbSaidas ON
             tbSaidas.cod_emp   = tbintegraSAP_Doc.cod_emp
         AND tbSaidas.cod_fil   = tbintegraSAP_Doc.cod_fil
         AND tbSaidas.ano_solic = tbintegraSAP_Doc.ano_solic
         AND tbSaidas.num_solic = tbintegraSAP_Doc.num_solic
       WHERE DocTipo = oDocTipo
         AND (DocEntry = oDocEntry); # OR DocNum = oDocNum OR idPicking=oIdPicking);
       SELECT tbintegraSAP_Doc.*, IFNULL(tbSaidas.cnpj_cpf_cli,xcnpj_cpf_cli) cnpj_cpf_cli
             ,tbSaidas.num_nf, tbSaidas.data_nf, tbSaidas.data_solic
             #,tbSaidas.cod_emp, tbSaidas.cod_fil, tbSaidas.ano_solic, tbSaidas.num_solic
             ,tbSaidas.status_processo StatusDocWMS
             ,of_logistica.fnStatusProcessoWms(tbSaidas.status_processo) StatusDescrWMS
             ,tbSaidas.observ_solic
       FROM tbintegraSAP_Doc
       LEFT JOIN of_logistica.tbsolic_saidas tbSaidas ON
             tbSaidas.cod_emp   = tbintegraSAP_Doc.cod_emp
         AND tbSaidas.cod_fil   = tbintegraSAP_Doc.cod_fil
         AND tbSaidas.ano_solic = tbintegraSAP_Doc.ano_solic
         AND tbSaidas.num_solic = tbintegraSAP_Doc.num_solic
       WHERE DocTipo = oDocTipo
         AND IF(oDocNum IS NULL, TRUE, DocNum = oDocNum)
         AND IF(oDocEntry IS NULL, TRUE, DocEntry = oDocEntry)
         AND IF(oIdPicking IS NULL, TRUE, idPicking = oIdPicking);
         
         
       SELECT tbintegraSAP_DocItem.*, tbSaidasItem.real_est3, tbSaidasItem.emb_est, emb_estoque_cli, fator_conv_vendas
       FROM tbintegraSAP_DocItem
       LEFT JOIN of_logistica.tbsolic_saidas_item tbSaidasItem ON
             tbSaidasItem.cod_emp   = tbintegraSAP_DocItem.cod_emp
         AND tbSaidasItem.cod_fil   = tbintegraSAP_DocItem.cod_fil
         AND tbSaidasItem.ano_solic = tbintegraSAP_DocItem.ano_solic
         AND tbSaidasItem.num_solic = tbintegraSAP_DocItem.num_solic
         AND tbSaidasItem.num_item  = tbintegraSAP_DocItem.num_item
       INNER JOIN of_logistica.tbprodutos ON 
                  tbprodutos.cnpj_cpf = tbSaidasItem.cnpj_cpf_dep
              AND tbprodutos.cod_produto = tbSaidasItem.cod_produto
       WHERE tbintegraSAP_DocItem.DocTipo = oDocTipo
         AND tbintegraSAP_DocItem.DocNum = oDocNum 
         AND tbintegraSAP_DocItem.DocEntry = oDocEntry;
         
       SELECT tbSaidasAcons.*, tbintegraSAP_DocItem.LineNum,
              tbEstoque.num_lote_cli NumLoteCli
       FROM tbintegraSAP_DocItem
       LEFT JOIN of_logistica.tbsolic_saidas_item tbSaidasItem ON
             tbSaidasItem.cod_emp   = tbintegraSAP_DocItem.cod_emp
         AND tbSaidasItem.cod_fil   = tbintegraSAP_DocItem.cod_fil
         AND tbSaidasItem.ano_solic = tbintegraSAP_DocItem.ano_solic
         AND tbSaidasItem.num_solic = tbintegraSAP_DocItem.num_solic
         AND tbSaidasItem.num_item  = tbintegraSAP_DocItem.num_item
       INNER JOIN of_logistica.tbsolic_saidas_acons tbSaidasAcons ON
                 tbSaidasAcons.cod_emp   = tbSaidasItem.cod_emp
             AND tbSaidasAcons.cod_fil   = tbSaidasItem.cod_fil
             AND tbSaidasAcons.ano_solic = tbSaidasItem.ano_solic
             AND tbSaidasAcons.num_solic = tbSaidasItem.num_solic
             AND tbSaidasAcons.num_item  = tbSaidasItem.num_item
       INNER JOIN of_logistica.tbwms_estoque tbEstoque ON 
                  tbEstoque.cod_emp = tbSaidasAcons.cod_emp
              AND tbEstoque.cod_fil = tbSaidasAcons.cod_fil
              AND tbEstoque.num_lote = tbSaidasAcons.num_lote
              AND tbEstoque.sequencia_lote = tbSaidasAcons.sequencia_lote
       WHERE tbintegraSAP_DocItem.DocTipo = oDocTipo
         AND tbintegraSAP_DocItem.DocNum = oDocNum 
         AND tbintegraSAP_DocItem.DocEntry = oDocEntry
         AND (tbSaidasAcons.qtde_est > 0 OR tbSaidasAcons.qtde_est2 > 0);
         
         
   ELSEIF oDocTipo IN ('DV','NE','E-NE','E-RM','TD-E','PA') OR (oDocTipo LIKE  'PA%')THEN
       SELECT DocNum, DocEntry, IdPicking
       INTO oDocNum, oDocEntry, oIdPicking
       FROM tbintegraSAP_Doc
       LEFT JOIN of_logistica.tbsolic_entradas tbEntradas ON
             tbEntradas.cod_emp   = tbintegraSAP_Doc.cod_emp
         AND tbEntradas.cod_fil   = tbintegraSAP_Doc.cod_fil
         AND tbEntradas.ano_solic = tbintegraSAP_Doc.ano_solic
         AND tbEntradas.num_solic = tbintegraSAP_Doc.num_solic
       WHERE DocTipo = oDocTipo
         AND (DocEntry = oDocEntry); # OR DocNum = oDocNum OR idPicking=oIdPicking);
       SELECT tbintegraSAP_Doc.*, IFNULL(tbEntradas.cnpj_cpf_cli,xcnpj_cpf_cli) cnpj_cpf_cli
             ,tbEntradas.num_nf, tbEntradas.data_nf, tbEntradas.data_solic
             #,tbEntradas.cod_emp, tbEntradas.cod_fil, tbEntradas.ano_solic, tbEntradas.num_solic
             ,tbEntradas.status_processo StatusDocWMS
             ,of_logistica.fnStatusProcessoWms(tbEntradas.status_processo) StatusDescrWMS
             ,tbEntradas.observ_solic
       FROM tbintegraSAP_Doc
       LEFT JOIN of_logistica.tbsolic_entradas tbEntradas ON
             tbEntradas.cod_emp   = tbintegraSAP_Doc.cod_emp
         AND tbEntradas.cod_fil   = tbintegraSAP_Doc.cod_fil
         AND tbEntradas.ano_solic = tbintegraSAP_Doc.ano_solic
         AND tbEntradas.num_solic = tbintegraSAP_Doc.num_solic
       WHERE DocTipo = oDocTipo
         AND DocNum = oDocNum
         AND DocEntry = oDocEntry;
         
         
       SELECT tbintegraSAP_DocItem.*, tbEntradasItem.real_est3, tbEntradasItem.emb_est, emb_estoque_cli, fator_conv_vendas
       FROM tbintegraSAP_DocItem
       LEFT JOIN of_logistica.tbsolic_entradas_item tbEntradasItem ON
             tbEntradasItem.cod_emp   = tbintegraSAP_DocItem.cod_emp
         AND tbEntradasItem.cod_fil   = tbintegraSAP_DocItem.cod_fil
         AND tbEntradasItem.ano_solic = tbintegraSAP_DocItem.ano_solic
         AND tbEntradasItem.num_solic = tbintegraSAP_DocItem.num_solic
         AND tbEntradasItem.num_item  = tbintegraSAP_DocItem.num_item
       INNER JOIN of_logistica.tbprodutos ON 
                  tbprodutos.cnpj_cpf = tbEntradasItem.cnpj_cpf_dep
              AND tbprodutos.cod_produto = tbEntradasItem.cod_produto
       WHERE tbintegraSAP_DocItem.DocTipo = oDocTipo
         AND tbintegraSAP_DocItem.DocNum = oDocNum 
         AND tbintegraSAP_DocItem.DocEntry = oDocEntry;
         
       SELECT tbEntradasAcons.*, tbintegraSAP_DocItem.LineNum,
              tbEstoque.num_lote_cli NumLoteCli
       FROM tbintegraSAP_DocItem
       LEFT JOIN of_logistica.tbsolic_entradas_item tbEntradasItem ON
             tbEntradasItem.cod_emp   = tbintegraSAP_DocItem.cod_emp
         AND tbEntradasItem.cod_fil   = tbintegraSAP_DocItem.cod_fil
         AND tbEntradasItem.ano_solic = tbintegraSAP_DocItem.ano_solic
         AND tbEntradasItem.num_solic = tbintegraSAP_DocItem.num_solic
         AND tbEntradasItem.num_item  = tbintegraSAP_DocItem.num_item
       INNER JOIN of_logistica.tbsolic_entradas_acons tbEntradasAcons ON
                 tbEntradasAcons.cod_emp   = tbEntradasItem.cod_emp
             AND tbEntradasAcons.cod_fil   = tbEntradasItem.cod_fil
             AND tbEntradasAcons.ano_solic = tbEntradasItem.ano_solic
             AND tbEntradasAcons.num_solic = tbEntradasItem.num_solic
             AND tbEntradasAcons.num_item  = tbEntradasItem.num_item
       INNER JOIN of_logistica.tbwms_estoque tbEstoque ON 
                  tbEstoque.cod_emp = tbEntradasAcons.cod_emp
              AND tbEstoque.cod_fil = tbEntradasAcons.cod_fil
              AND tbEstoque.num_lote = tbEntradasAcons.num_lote
              AND tbEstoque.sequencia_lote = tbEntradasAcons.sequencia_lote
       WHERE tbintegraSAP_DocItem.DocTipo = oDocTipo
         AND tbintegraSAP_DocItem.DocNum = oDocNum 
         AND tbintegraSAP_DocItem.DocEntry = oDocEntry
         AND (tbEntradasAcons.qtde_est > 0 OR tbEntradasAcons.qtde_est2 > 0);
   
   END IF;
    
      
END$$

DELIMITER ;