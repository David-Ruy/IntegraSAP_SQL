DELIMITER $$

DROP PROCEDURE IF EXISTS `PROC_INTEGRA_ListarContagem_GEM_GSM`$$

CREATE PROCEDURE `PROC_INTEGRA_ListarContagem_GEM_GSM`(
   IN oFlgGerarListar    INT  #0=Gerar Contagens Integração/Criação, 1=Lista para Confirmação
)
BLOCO1:BEGIN
   #@Reviser David Ruy <2020/03/12> Arredondamento 3 casas decimais pois o SAP não suporta mais que 3 casas
   DECLARE xQtdeRegs     INT DEFAULT 0;
   DECLARE excecao 	     INT DEFAULT 0;
   DECLARE xDataHora     DATETIME DEFAULT NOW();
   DECLARE RESULTADO     INT;
   DECLARE MENSAGEM      VARCHAR(500) DEFAULT '';
   
   DECLARE EXIT HANDLER FOR SQLEXCEPTION
   BEGIN
       GET DIAGNOSTICS CONDITION 1 MENSAGEM = MESSAGE_TEXT;
       SET excecao   = 1;
       SET RESULTADO = 0;
       SET MENSAGEM  = of_logistica.fnMensagemExcecao(MENSAGEM);
       ROLLBACK;
   END;
   
   
   START TRANSACTION;
   
   
   IF oFlgGerarListar = 0 THEN
   
      #Tabela temporária para atualizar retorno à integração
      DROP TEMPORARY TABLE IF EXISTS tbTMPGEM;
      CREATE TEMPORARY TABLE tbTMPGEM AS
         (SELECT "Entrada" AS TipoMovto, TopoEntrada.cod_emp, TopoEntrada.cod_fil, TopoEntrada.ano_solic, TopoEntrada.num_solic,
                 tbOperWMS.descr_oper_wms          
         FROM of_logistica.tbsolic_entradas TopoEntrada 
         INNER JOIN of_logistica.tbsys_integracao_operacao tbOper ON 
                     tbOper.cod_oper_wms = TopoEntrada.flg_tipo_oper
         INNER JOIN of_logistica.tbwms_tipo_oper tbOperWMS ON 
                     tbOperWMS.cod_oper_wms = TopoEntrada.flg_tipo_oper
         WHERE TopoEntrada.dthr_retorno_integracao IS NULL
           AND TopoEntrada.dthr_confirm IS NOT NULL
           AND TopoEntrada.chave_integracao IS NULL
         GROUP BY cod_emp, cod_fil, ano_solic, num_solic);
         
      DROP TEMPORARY TABLE IF EXISTS tbTMPGSM;
      CREATE TEMPORARY TABLE tbTMPGSM AS
         (SELECT "Saida" AS TipoMovto, TopoSaida.cod_emp, TopoSaida.cod_fil, TopoSaida.ano_solic, TopoSaida.num_solic,
                 tbOperWMS.descr_oper_wms 
         FROM of_logistica.tbsolic_saidas TopoSaida 
         INNER JOIN of_logistica.tbsys_integracao_operacao tbOper ON 
                     tbOper.cod_oper_wms = TopoSaida.flg_tipo_oper
         INNER JOIN of_logistica.tbwms_tipo_oper tbOperWMS ON 
                     tbOperWMS.cod_oper_wms = TopoSaida.flg_tipo_oper
         WHERE TopoSaida.dthr_retorno_integracao IS NULL
           AND TopoSaida.dthr_confirm IS NOT NULL
           AND TopoSaida.chave_integracao IS NULL
         GROUP BY cod_emp, cod_fil, ano_solic, num_solic);
         
      
      
      DROP TEMPORARY TABLE IF EXISTS tbTMPItemContagem;
      CREATE TEMPORARY TABLE tbTMPItemContagem AS
         (
         SELECT TipoMovto, Item.cod_emp, Item.cod_fil, Item.ano_solic, Item.num_solic, Item.num_item,
                        Item.cod_produto, IFNULL(tbEstoque.num_lote_cli,"") num_lote_cli,
                        tbEstoque.num_lote, tbEstoque.sequencia_lote,
                        SUM(tbEstoque.sld_fisico_est) QtdeEstoque,
                        tbArmazem.cod_armazem CodArmazemSAP, tbOperWMS.descr_oper_wms
         FROM of_logistica.tbsolic_entradas_item Item
         INNER JOIN of_logistica.tbsolic_entradas tbTopo ON
                     Item.cod_emp   = tbTopo.cod_emp
                 AND Item.cod_fil   = tbTopo.cod_fil
                 AND Item.ano_solic = tbTopo.ano_solic
                 AND Item.num_solic = tbTopo.num_solic
         INNER JOIN tbTMPGEM ON 
                     tbTMPGEM.cod_emp   = Item.cod_emp
                 AND tbTMPGEM.cod_fil   = Item.cod_fil
                 AND tbTMPGEM.ano_solic = Item.ano_solic
                 AND tbTMPGEM.num_solic = Item.num_solic
         INNER JOIN of_logistica.tbwms_estoque tbEstoque ON 
                     tbTopo.cod_emp       = tbEstoque.cod_emp
                 AND tbTopo.cod_fil       = tbEstoque.cod_fil
                 AND tbTopo.cnpj_cpf_cli  = tbEstoque.cnpj_cpf_cli
                 AND tbTopo.cod_estoque   = tbEstoque.cod_estoque
                 AND Item.cod_produto  = tbEstoque.cod_produto 
         INNER JOIN of_logistica.tbsys_integracao_operacao tbOper ON 
                     tbOper.cod_oper_wms = tbTopo.flg_tipo_oper
         INNER JOIN of_logistica.tbwms_tipo_oper tbOperWMS ON 
                     tbOperWMS.cod_oper_wms = tbTopo.flg_tipo_oper
         INNER JOIN tbintegraSAP_DeParaStatus_Armazem tbArmazem ON
                     tbArmazem.cod_status = tbEstoque.status_lote
         GROUP BY CodArmazemSAP, tbEstoque.cod_produto, IFNULL(tbEstoque.num_lote_cli,tbEstoque.data_valid))
         UNION
         (SELECT TipoMovto, Item.cod_emp, Item.cod_fil, Item.ano_solic, Item.num_solic, Item.num_item,
                        Item.cod_produto, IFNULL(tbEstoque.num_lote_cli,"") num_lote_cli,
                        tbEstoque.num_lote, tbEstoque.sequencia_lote,
                        SUM(tbEstoque.sld_fisico_est) QtdeEstoque,
                        tbArmazem.cod_armazem CodArmazemSAP, tbOperWMS.descr_oper_wms
         FROM of_logistica.tbsolic_saidas_item Item
         INNER JOIN of_logistica.tbsolic_saidas tbTopo ON
                     Item.cod_emp   = tbTopo.cod_emp
                 AND Item.cod_fil   = tbTopo.cod_fil
                 AND Item.ano_solic = tbTopo.ano_solic
                 AND Item.num_solic = tbTopo.num_solic
         INNER JOIN tbTMPGSM ON 
                     tbTMPGSM.cod_emp   = Item.cod_emp
                 AND tbTMPGSM.cod_fil   = Item.cod_fil
                 AND tbTMPGSM.ano_solic = Item.ano_solic
                 AND tbTMPGSM.num_solic = Item.num_solic
         INNER JOIN of_logistica.tbwms_estoque tbEstoque ON 
                     tbTopo.cod_emp       = tbEstoque.cod_emp
                 AND tbTopo.cod_fil       = tbEstoque.cod_fil
                 AND tbTopo.cnpj_cpf_cli  = tbEstoque.cnpj_cpf_cli
                 AND tbTopo.cod_estoque   = tbEstoque.cod_estoque
                 AND Item.cod_produto  = tbEstoque.cod_produto 
         INNER JOIN of_logistica.tbsys_integracao_operacao tbOper ON 
                     tbOper.cod_oper_wms = tbTopo.flg_tipo_oper
         INNER JOIN of_logistica.tbwms_tipo_oper tbOperWMS ON 
                     tbOperWMS.cod_oper_wms = tbTopo.flg_tipo_oper
         INNER JOIN tbintegraSAP_DeParaStatus_Armazem tbArmazem ON
                     tbArmazem.cod_status = tbEstoque.status_lote
         GROUP BY CodArmazemSAP, tbEstoque.cod_produto, IFNULL(tbEstoque.num_lote_cli,tbEstoque.data_valid));
         
         
      INSERT INTO tbintegraSAP_ContagemTopo (
              Id, 
              Reference,
              CountingDate,
              TipoDocSLIN,
              cod_emp,
              cod_fil,	
              ano_solic,
              num_solic,
              observacoes,   
              dthr_inc) 
          (SELECT 0, CONCAT(descr_oper_wms," ",
               CAST(cod_emp AS UNSIGNED),"/",CAST(cod_fil AS UNSIGNED),"|",ano_solic,"-",CAST(num_solic AS UNSIGNED)),
               xDataHora, 
               SUBSTRING(TipoMovto,1,1),
               cod_emp, cod_fil, ano_solic, num_solic, 
               TipoMovto, xDataHora
           FROM tbTMPGEM)
           UNION 
          (SELECT 0, CONCAT(descr_oper_wms," ",
               CAST(cod_emp AS UNSIGNED),"/",CAST(cod_fil AS UNSIGNED),"|",ano_solic,"-",CAST(num_solic AS UNSIGNED)),
               xDataHora, 
               SUBSTRING(TipoMovto,1,1),
               cod_emp, cod_fil, ano_solic, num_solic, 
               TipoMovto, xDataHora
           FROM tbTMPGSM);
           
      
      INSERT INTO tbintegraSAP_ContagemItens (
              TipoDocSLIN,
              cod_emp,
              cod_fil,	
              ano_solic,
              num_solic,
              num_item, 
              ItemCode,
              WarehouseCode,
              BinCode,
              BatchNumber_Code,
              BatchNumber_Quantity,
              SerialNumber_ManufactureCode,
              ContedQuantity)
       (SELECT SUBSTRING(TipoMovto,1,1), 
         tbTMPItemContagem.cod_emp, tbTMPItemContagem.cod_fil, tbTMPItemContagem.ano_solic, tbTMPItemContagem.num_solic, 
         tbTMPItemContagem.num_item, tbTMPItemContagem.cod_produto, tbTMPItemContagem.CodArmazemSAP, "BinCode", 
         tbTMPItemContagem.num_lote_cli, CAST(tbTMPItemContagem.QtdeEstoque AS DECIMAL(18,3)), NULL,
         CAST(tbTMPItemContagem.QtdeEstoque AS DECIMAL(18,3))
      FROM tbTMPItemContagem
      WHERE tbTMPItemContagem.QtdeEstoque IS NOT NULL
      #GROUP BY TipoMovto, cod_emp, cod_fil, ano_solic, num_solic, num_item, cod_produto, num_lote_cli
      #ORDER BY TipoMovto, cod_emp, cod_fil, ano_solic, num_solic, num_item, cod_produto, num_lote_cli);
      GROUP BY TipoMovto, cod_emp, cod_fil, ano_solic, num_solic, num_item, cod_produto, CodArmazemSAP, num_lote_cli 
      ORDER BY TipoMovto, cod_emp, cod_fil, ano_solic, num_solic, num_item, cod_produto, CodArmazemSAP, num_lote_cli);
      
      SET xQtdeRegs = ROW_COUNT();
         
      #Atualiza TBSOLIC_ENTRADAS
      UPDATE of_logistica.tbsolic_entradas tbEntradas
      INNER JOIN tbTMPGEM ON 
            tbTMPGEM.cod_emp   = tbEntradas.cod_emp
        AND tbTMPGEM.cod_fil   = tbEntradas.cod_fil
        AND tbTMPGEM.ano_solic = tbEntradas.ano_solic
        AND tbTMPGEM.num_solic = tbEntradas.num_solic
      SET tbEntradas.dthr_retorno_integracao = xDataHora
      WHERE tbTMPGEM.TipoMovto = "Entrada";
      
      #Atualiza TBSOLIC_SAIDAS
      UPDATE of_logistica.tbsolic_saidas tbSaidas
      INNER JOIN tbTMPGSM ON 
            tbTMPGSM.cod_emp   = tbSaidas.cod_emp
        AND tbTMPGSM.cod_fil   = tbSaidas.cod_fil
        AND tbTMPGSM.ano_solic = tbSaidas.ano_solic
        AND tbTMPGSM.num_solic = tbSaidas.num_solic
      SET tbSaidas.dthr_retorno_integracao = xDataHora
      WHERE tbTMPGSM.TipoMovto = "Saida";
      
      #SELECT * FROM tbTMPItemContagem
      #ORDER BY TipoMovto, cod_emp, cod_fil, ano_solic, num_solic, cod_produto, num_lote_cli;
      DROP TEMPORARY TABLE IF EXISTS tbTMPGEM;
      DROP TEMPORARY TABLE IF EXISTS tbTMPGSM;
      DROP TEMPORARY TABLE IF EXISTS tbTMPItemContagem;
      
   END IF;
   
   
   #Topos da Contagem         
   SELECT  id IdContagem, Reference, CountingDate, CONCAT(TipoDocSLIN, cod_emp, cod_fil, ano_solic, num_solic) AS NumDocSLIN
          ,RESULTADO AS resultado, CONCAT(TipoDocSLIN, cod_emp, cod_fil, ano_solic, num_solic) AS mensagem
   FROM tbintegraSAP_ContagemTopo Topo
   WHERE IF(oFlgGerarListar = 0, id = 0, id > 0 AND Topo.dthr_retorno_integracao IS NULL)
   GROUP BY NumDocSlin;
   
   #Itens (Entradas) das Contagens
   SELECT CONCAT(Topo.TipoDocSLIN, Itens.cod_emp, Itens.cod_fil, Itens.ano_solic, Itens.num_solic) AS NumDocSLIN, 
          Itens.num_item, ItemCode, WarehouseCode, BinCode, SUM(ContedQuantity) AS ContedQuantity,
          tbProd.flg_obriga_lote_fornecedor
   FROM tbintegraSAP_ContagemItens Itens
   INNER JOIN tbintegraSAP_ContagemTopo Topo ON
        Topo.TipoDocSLIN = Itens.TipoDocSLIN
    AND Topo.cod_emp     = Itens.cod_emp
    AND Topo.cod_fil     = Itens.cod_fil
    AND Topo.ano_solic   = Itens.ano_solic
    AND Topo.num_solic   = Itens.num_solic
   LEFT JOIN of_logistica.tbsolic_entradas_item tbItens ON 
             tbItens.cod_emp   = Itens.cod_emp
         AND tbItens.cod_fil   = Itens.cod_fil
         AND tbItens.ano_solic = Itens.ano_solic
         AND tbItens.num_solic = Itens.num_solic
         AND tbItens.num_item  = Itens.num_item
   LEFT JOIN of_logistica.tbprodutos tbProd ON 
           tbProd.cnpj_cpf    = tbItens.cnpj_cpf_dep
       AND tbProd.cod_produto = tbItens.cod_produto
   WHERE Itens.TipoDocSLIN = "E" 
     AND IF(oFlgGerarListar = 0, id = 0, id > 0 AND Topo.dthr_retorno_integracao IS NULL)
   GROUP BY NumDocSlin, ItemCode, WarehouseCode
      
   UNION
   
   #Itens (Saídas) das Contagens
   SELECT CONCAT(Topo.TipoDocSLIN, Itens.cod_emp, Itens.cod_fil, Itens.ano_solic, Itens.num_solic) AS NumDocSLIN, 
          Itens.num_item, ItemCode, WarehouseCode, BinCode, SUM(ContedQuantity) AS ContedQuantity,
          tbProd.flg_obriga_lote_fornecedor
   FROM tbintegraSAP_ContagemItens Itens
   INNER JOIN tbintegraSAP_ContagemTopo Topo ON
        Topo.TipoDocSLIN = Itens.TipoDocSLIN
    AND Topo.cod_emp     = Itens.cod_emp
    AND Topo.cod_fil     = Itens.cod_fil
    AND Topo.ano_solic   = Itens.ano_solic
    AND Topo.num_solic   = Itens.num_solic
   LEFT JOIN of_logistica.tbsolic_saidas_item tbItens ON 
             tbItens.cod_emp   = Itens.cod_emp
         AND tbItens.cod_fil   = Itens.cod_fil
         AND tbItens.ano_solic = Itens.ano_solic
         AND tbItens.num_solic = Itens.num_solic
         AND tbItens.num_item  = Itens.num_item
   LEFT JOIN of_logistica.tbprodutos tbProd ON 
           tbProd.cnpj_cpf    = tbItens.cnpj_cpf_dep
       AND tbProd.cod_produto = tbItens.cod_produto
   WHERE Itens.TipoDocSLIN = "S" AND id = 0
   GROUP BY NumDocSlin, ItemCode, WarehouseCode;
   
   
   
   
   IF oFlgGerarListar = 0 THEN
      SELECT COUNT(1) INTO xQtdeRegs
      FROM tbintegraSAP_ContagemItens Itens
      INNER JOIN tbintegraSAP_ContagemTopo Topo ON
           Topo.TipoDocSLIN = Itens.TipoDocSLIN
       AND Topo.cod_emp     = Itens.cod_emp
       AND Topo.cod_fil     = Itens.cod_fil
       AND Topo.ano_solic   = Itens.ano_solic
       AND Topo.num_solic   = Itens.num_solic
      WHERE id = 0;
   END IF;
   
   #Lotes das Contagens
   SELECT CONCAT(Topo.TipoDocSLIN, Itens.cod_emp, Itens.cod_fil, Itens.ano_solic, Itens.num_solic) AS NumDocSLIN, 
         Itens.num_item, ItemCode, WarehouseCode,   
         BatchNumber_Code, SUM(BatchNumber_Quantity) AS BatchNumber_Quantity            
   FROM tbintegraSAP_ContagemItens Itens
   INNER JOIN tbintegraSAP_ContagemTopo Topo ON
        Topo.TipoDocSLIN = Itens.TipoDocSLIN
    AND Topo.cod_emp     = Itens.cod_emp
    AND Topo.cod_fil     = Itens.cod_fil
    AND Topo.ano_solic   = Itens.ano_solic
    AND Topo.num_solic   = Itens.num_solic      
   WHERE IF(oFlgGerarListar=0,id = 0, id > 0 AND Topo.dthr_retorno_integracao IS NULL)
   #WHERE id = 0
   GROUP BY NumDocSlin, ItemCode, WarehouseCode, BatchNumber_Code;           
   
            
   SET RESULTADO = 0;
   #SET MENSAGEM = CONCAT(IFNULL(MENSAGEM,""),"- (PROC_INTEGRA_ListarContagem_GEM_GSM) Contagens Listadas com sucesso");
   IF excecao = 1 THEN
      ROLLBACK;
      SET RESULTADO = 1;
      SET MENSAGEM = CONCAT(IFNULL(MENSAGEM,""),"- Erro PROC_INTEGRA_ListarContagem_GEM_GSM");
      #SELECT RESULTADO, MENSAGEM;
   ELSE
      COMMIT;
      SET RESULTADO = 0;
      SET MENSAGEM = CONCAT(IFNULL(MENSAGEM,"")," (PROC_INTEGRA_ListarContagem_GEM_GSM) Contagens Geradas com sucesso [",xQtdeRegs,']');
   END IF;
   
   SELECT RESULTADO, MENSAGEM;
   
   
END$$

DELIMITER ;