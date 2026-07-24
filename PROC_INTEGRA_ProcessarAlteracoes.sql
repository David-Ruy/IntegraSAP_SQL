DELIMITER $$

DROP PROCEDURE IF EXISTS `PROC_INTEGRA_ProcessarAlteracoes` $$

CREATE PROCEDURE `PROC_INTEGRA_ProcessarAlteracoes`(
   # Parametros de Retorno
   OUT RESULTADO      INT,
   OUT MENSAGEM       VARCHAR(500)
)
BLOCO1:BEGIN
   /********************************************************************************/
   #@Reviser David Ruy <2021-12-12> Ajuste WHERE tbUpdCancPV.TipoUpdCanc IN ('U','C')
   #                                estava WHERE true
   #@Reviser David Ruy <2023-02-07> Alteração PROC_INTEGRA_GerarGSM (Parametros xBaseQty, e xOpenInvQty) : xQuantity, xQtdeEstoque
   #@Reviser David Ruy <2025-02-25> Considerar Quantity (BaseQty) ou QtdeEstoque (OpenInvQty) conforme xemb_estoque = xsalUnitMsr
   /********************************************************************************/
   DECLARE xCodEmpWMS			      VARCHAR(03);
   DECLARE xCodFilWMS			      VARCHAR(03);
   DECLARE xAnoSolic 			      VARCHAR(04);
   DECLARE xNumSolic 			      VARCHAR(10);
   DECLARE xNumItem           VARCHAR(06);
   DECLARE xCodEmpTMS         VARCHAR(03);
   DECLARE xCodFilTMS         VARCHAR(03);
   DECLARE xCnpjCpfCli        VARCHAR(14);
   DECLARE xNumPedido         VARCHAR(20);
   DECLARE xCnpjCpfDep        VARCHAR(14);
   DECLARE xCodProduto        VARCHAR(30);
   DECLARE xemb_estoque       VARCHAR(10);
   DECLARE xemb_frac          VARCHAR(10);
   DECLARE xemb_vol           VARCHAR(10);
   DECLARE xfator_conversao   DECIMAL(18,6);
   DECLARE xpeso_liq_vol      DECIMAL(18,6);
   DECLARE xpeso_brt_vol      DECIMAL(18,6);
   
   DECLARE xpeso_liq_frac     DECIMAL(18,5);
   DECLARE xpesoLiqItem       DECIMAL(18,5);
   DECLARE xQtdeFrac          DECIMAL(18,5);
   DECLARE xQtdeEst           DECIMAL(18,5);
   DECLARE xQtdeRegs          INT DEFAULT 0;
 
   DECLARE xItemCode          VARCHAR(20);
   DECLARE xQuantity          DECIMAL(18,6);
   DECLARE xQtdeEstoque       DECIMAL(18,6);
   DECLARE xQtdeVolumes       DECIMAL(18,6);
   DECLARE xUniqueKey         VARCHAR(30);
   DECLARE xUpdateDate        DATETIME;
   DECLARE xTipoUpdCanc       VARCHAR(01);
   
   DECLARE xDocEntry          INT;
   DECLARE xDocTipo           VARCHAR(10);
   DECLARE xDocNum            INT;
   DECLARE xStatusItem        VARCHAR(20);
   DECLARE xLineNum           INT;
   
   DECLARE xEmbVendas         VARCHAR(10);
   DECLARE excecao 	         INT DEFAULT 0;
   
   #Informações do item para inserir na tbsolic_saidas_item
   DECLARE xdescription       VARCHAR(100);
   DECLARE xBaseQty           DECIMAL(18,6);
   DECLARE xVlrUnitario       DECIMAL(18,6);
   DECLARE xsalUnitMsr        VARCHAR(30);
   DECLARE xinvntryUom        VARCHAR(30);
   DECLARE xNumInsale         DECIMAL(18,5);
   DECLARE xObservacoesIte    TEXT;
   DECLARE xCardCode          VARCHAR(15);
   DECLARE xCardName          VARCHAR(100);
   DECLARE xBatchCode         VARCHAR(30);
   DECLARE xWhareHouseIte     VARCHAR(30);
   DECLARE xRefGuia           VARCHAR(30);
   
   DECLARE EXIT HANDLER FOR SQLEXCEPTION
   BEGIN
       GET DIAGNOSTICS CONDITION 1 MENSAGEM = MESSAGE_TEXT;
       SET excecao   = 1;
       SET RESULTADO = 0;
       SET MENSAGEM  = of_logistica.fnMensagemExcecao(MENSAGEM);
       ROLLBACK;
   END;
   
   START TRANSACTION;
   
   
   #@Reviser David Ruy <2022-04-12>
   #Seleciona os itens a inserir na tbsolic_saidas_item
   DROP TEMPORARY TABLE IF EXISTS TMP_IncluirItem;
   CREATE TEMPORARY TABLE TMP_IncluirItem ( 
      SELECT tbUpdCancPV.TipoUpdCanc,tbUpdCancPV.UniqueKey, tbUpdCancPV.DocumentType, 
             tbUpdCancPV.DocumentId, tbUpdCancPV.DocumentNumber,
             tbUpdCancPV.DocumentDate, tbUpdCancPV.LineNumber, tbUpdCancPV.UpdateDate, 
             tbUpdCancPV.Quantity, 
             #IFNULL(tbUpdCancPV.QtdeEstoque,tbUpdCancPV.Quantity*IFNULL(tbItem.NumInsale,1))  QtdeEstoque, 
             IF(tbUpdCancPV.SalUnitMsr = tbprodutos.emb_estoque,
                tbUpdCancPV.Quantity,
                IFNULL(tbUpdCancPV.QtdeEstoque,tbUpdCancPV.Quantity*IFNULL(tbItem.NumInsale,1)))  QtdeEstoque, 
             tbUpdCancPV.SalUnitMsr,
             IFNULL(tbUpdCancPV.ItemCode,tbItem.ItemCode) ItemCode, tbItem.StatusItem,
             tbSolic.cod_emp, tbSolic.cod_fil, tbSolic.ano_solic, tbSolic.num_solic,
             tbSolic.cnpj_cpf_dep, tbTopo.idPicking,
             #
             tbItem.description, tbItem.Price, tbItem.invntryUom,
             tbItem.NumInsale, tbItem.Observacoes, tbTopo.CardCode, tbTopo.CardName, BatchNumbersCode, tbItem.WhareHouse,
             #
             0 AS FlgProcessado
      FROM tbintegraSAP_UpdCancPV tbUpdCancPV 
      INNER JOIN tbintegraSAP_Doc tbTopo ON 
                 tbTopo.DocEntry = tbUpdCancPV.DocumentId
             AND tbTopo.DocTipo  = tbUpdCancPV.DocumentType 
             AND tbTopo.DocNum   = tbUpdCancPV.DocumentNumber 
      INNER JOIN tbintegraSAP_DocItem tbItem ON 
                 tbItem.DocEntry = tbUpdCancPV.DocumentId
             AND tbItem.DocTipo  = tbUpdCancPV.DocumentType 
             AND tbItem.DocNum   = tbUpdCancPV.DocumentNumber 
             AND tbItem.LineNum  = tbUpdCancPV.LineNumber 
      LEFT JOIN of_logistica.tbsolic_saidas tbSolic ON 
                 tbSolic.cod_emp   = tbTopo.cod_emp
             AND tbSolic.cod_fil   = tbTopo.cod_fil
             AND tbSolic.ano_solic = tbTopo.ano_solic
             AND tbSolic.num_solic = tbTopo.num_solic
      LEFT JOIN of_logistica.tbprodutos ON 
                 tbprodutos.cnpj_cpf = tbSolic.cnpj_cpf_dep
             AND tbprodutos.cod_produto = tbUpdCancPV.ItemCode
      WHERE tbUpdCancPV.TipoUpdCanc IN ('U','C')
        AND tbUpdCancPV.STATUS = 1
        AND tbItem.StatusItem = 2);
        
   #Insere os itens na tbsolic_saidas_item
   SET xQtdeRegs = 0;
   WHILE EXISTS (SELECT 1 FROM TMP_IncluirItem WHERE TMP_IncluirItem.FlgProcessado = 0) DO
   
      SELECT cod_emp, cod_fil, ano_solic, num_solic, 
             TipoUpdCanc, UniqueKey, UpdateDate, Quantity, QtdeEstoque, 
             SalUnitMsr, cnpj_cpf_dep, 
             ItemCode, StatusItem,
             DocumentId, DocumentType, DocumentNumber, LineNumber,
             description, price, salUnitMsr, invntryUom,
             NumInsale, Observacoes, CardCode, CardName, BatchNumbersCode, WhareHouse
      INTO xCodEmpWMS, xCodFilWMS, xAnoSolic, xNumSolic, 
           xTipoUpdCanc, xUniqueKey, xUpdateDate, xQuantity, xQtdeEstoque, xEmbVendas, xCnpjCpfDep, 
           xItemCode, xStatusItem,
           xDocEntry, xDocTipo, xDocNum, xLineNum,
           xdescription, xVlrUnitario, xsalUnitMsr, xinvntryUom,
           xNumInsale, xObservacoesIte, xCardCode, xCardName, xBatchCode, xWhareHouseIte
      FROM TMP_IncluirItem
      WHERE TMP_IncluirItem.FlgProcessado = 0
      LIMIT 1;
      
      SET xRefGuia     = CONCAT(xCodEmpWMS, xCodFilWMS, xAnoSolic, xNumSolic);
      SET xVlrUnitario = IF(IFNULL(xVlrUnitario,1)=0,1,IFNULL(xVlrUnitario,1));
      SET xdescription = IFNULL(xdescription,'');
      SET xsalUnitMsr = IFNULL(xsalUnitMsr,'');
      SET xinvntryUom = IFNULL(xinvntryUom,'');      
      
      SET xQtdeRegs = xQtdeRegs + 1;
      CALL PROC_INTEGRA_GerarGSMItem('999999', xRefGuia, 
                                     CONCAT(xDocNum,'(',xDocEntry,')'), xLineNum, xItemCode, xdescription, xQuantity, xQtdeEstoque, xVlrUnitario, 
                                     xsalUnitMsr, xinvntryUom, xNumInsale, xStatusItem, xObservacoesIte, xCardCode, xCardName, xBatchCode, 
                                     xWhareHouseIte, @R, @M);
      SET xNumItem    = SUBSTRING(@M,01,06);  #Numero do item no retorno da proc
      IF (xStatusItem <> 0) AND (@R = 1) THEN
         UPDATE tbintegraSAP_DocItem
         SET cod_emp     = xCodEmpWMS
            ,cod_fil     = xCodFilWMS
            ,ano_solic   = xAnoSolic
            ,num_solic   = xNumSolic
            ,num_item    = xNumItem
            ,StatusAnt   = StatusItem
            ,StatusItem  = '0'    #Volta para Zero para identificar que já atualizou no SLIN
         WHERE DocTipo  = xDocTipo
           AND DocEntry = xDocEntry
           AND LineNum  = xLineNum;
           
           
      INSERT INTO of_logistica.tbsolic_saidas_item_integra_alteracao (
                  cod_emp, cod_fil, ano_solic, num_solic, num_item, UniqueKey, dthr_inc, 
                  qtde_est_ant, qtde_vol_ant, qtde_frac_ant, qtde_peso_ant, 
                  qtde_est_atu , qtde_vol_atu, qtde_frac_atu, qtde_peso_atu)
         SELECT tbItem.cod_emp, tbItem.cod_fil, tbItem.ano_solic, tbItem.num_solic, tbItem.num_item,
                TMP_IncluirItem.UniqueKey, TMP_IncluirItem.UpdateDate, 
                0,0,0,0,
                tbItem.qtde_est, tbItem.qtde_vol, tbItem.qtde_frac, tbItem.pliq_item
         FROM TMP_IncluirItem
         INNER JOIN of_logistica.tbsolic_saidas_item tbItem ON
               tbItem.cod_emp   = TMP_IncluirItem.cod_emp 
           AND tbItem.cod_fil   = TMP_IncluirItem.cod_fil
           AND tbItem.ano_solic = TMP_IncluirItem.ano_solic 
           AND tbItem.num_solic = TMP_IncluirItem.num_solic
           AND tbItem.num_item  = xNumItem
         WHERE DocumentType   = xDocTipo
           AND DocumentId     = xDocEntry
           AND DocumentNumber = xDocNum
           AND Linenumber     = xLineNum;
           
      ELSE
          CALL PROC_INTEGRA_EnviarLog('999999',
                IF(xDocTipo IN ("PV","OP","TD-S"),'PROC_INTEGRA_GerarGSMItem','PROC_INTEGRA_GerarGEMItem'), 
                  CONCAT('NÃO Inserido/Atualizado ',xDocTipo,xDocEntry,'-',xDocNum,' | ', xRefGuia, '| Prd:', xItemCode), "0", @M, @R, @M);
      END IF;
      
      UPDATE tbintegraSAP_UpdCancPV tbUpdCancPV 
      INNER JOIN tbintegraSAP_DocItem tbItem ON 
                 tbItem.DocEntry = tbUpdCancPV.DocumentId
             AND tbItem.DocTipo  = tbUpdCancPV.DocumentType 
             AND tbItem.DocNum   = tbUpdCancPV.DocumentNumber 
             AND tbItem.LineNum  = tbUpdCancPV.LineNumber 
      SET tbUpdCancPV.cod_emp = tbItem.cod_emp, 
          tbUpdCancPV.cod_fil = tbItem.cod_fil,
          tbUpdCancPV.ano_solic = tbItem.ano_solic,
          tbUpdCancPV.num_solic = tbItem.num_solic, 
          tbUpdCancPV.num_item  = tbItem.num_item,
          tbUpdCancPV.status    = 2,
          tbUpdCancPV.FreeText  = CONCAT(IFNULL(tbUpdCancPV.FreeText,""),"|(4.9)Inc Item =>",xDocTipo,xDocNum),
          tbItem.StatusAnt  = IF(tbItem.StatusItem = 9, tbItem.StatusAnt, tbItem.StatusItem),
          tbItem.StatusItem = IF(tbItem.StatusItem = 9, tbItem.StatusItem, 0)
      WHERE tbUpdCancPV.UniqueKey  = xUniqueKey
        AND tbUpdCancPV.UpdateDate = xUpdateDate;
           
                 
      DELETE FROM TMP_IncluirItem
      WHERE UniqueKey = xUniqueKey;
      
   END WHILE;
   DROP TEMPORARY TABLE IF EXISTS TMP_IncluirItem;
   
   
   DROP TEMPORARY TABLE IF EXISTS TMP_UpdCancPV;
   CREATE TEMPORARY TABLE TMP_UpdCancPV ( 
      SELECT tbUpdCancPV.TipoUpdCanc,tbUpdCancPV.UniqueKey, tbUpdCancPV.DocumentType, 
             tbUpdCancPV.DocumentId, tbUpdCancPV.DocumentNumber,
             tbUpdCancPV.DocumentDate, tbUpdCancPV.LineNumber, tbUpdCancPV.UpdateDate, 
             tbUpdCancPV.Quantity, 
             #tbUpdCancPV.QtdeEstoque, 
             IF(tbUpdCancPV.SalUnitMsr = tbprodutos.emb_estoque,
                tbUpdCancPV.Quantity,
                IFNULL(tbUpdCancPV.QtdeEstoque,tbUpdCancPV.Quantity*IFNULL(tbItem.NumInsale,1)))  QtdeEstoque, 
             tbUpdCancPV.SalUnitMsr,
             IFNULL(tbUpdCancPV.ItemCode,tbItem.ItemCode) ItemCode, tbItem.StatusItem,
             tbItem.cod_emp, tbItem.cod_fil, tbItem.ano_solic, tbItem.num_solic, tbItem.num_item,
             tbIte.cnpj_cpf_dep, tbIte.cod_produto, tbTopo.idPicking,
             0 AS FlgProcessado
      FROM tbintegraSAP_UpdCancPV tbUpdCancPV 
      INNER JOIN tbintegraSAP_Doc tbTopo ON 
                 tbTopo.DocEntry = tbUpdCancPV.DocumentId
             AND tbTopo.DocTipo  = tbUpdCancPV.DocumentType 
             AND tbTopo.DocNum   = tbUpdCancPV.DocumentNumber 
      INNER JOIN tbintegraSAP_DocItem tbItem ON 
                 tbItem.DocEntry = tbUpdCancPV.DocumentId
             AND tbItem.DocTipo  = tbUpdCancPV.DocumentType 
             AND tbItem.DocNum   = tbUpdCancPV.DocumentNumber 
             AND tbItem.LineNum  = tbUpdCancPV.LineNumber 
      INNER JOIN of_logistica.tbsolic_saidas_item tbIte ON 
                 tbIte.cod_emp   = tbItem.cod_emp
             AND tbIte.cod_fil   = tbItem.cod_fil
             AND tbIte.ano_solic = tbItem.ano_solic
             AND tbIte.num_solic = tbItem.num_solic
             AND tbIte.num_item  = tbItem.num_item
      LEFT JOIN of_logistica.tbprodutos ON 
                 tbprodutos.cnpj_cpf = tbIte.cnpj_cpf_dep
             AND tbprodutos.cod_produto = tbIte.cod_produto
      WHERE tbUpdCancPV.TipoUpdCanc IN ('U','C')
        AND tbUpdCancPV.STATUS = 1
        #AND tbUpdCancPV.flg_deleted = 0
   );
   #select "aqui",TMP_UpdCancPV.* from TMP_UpdCancPV;
   
   WHILE EXISTS (SELECT 1 FROM TMP_UpdCancPV WHERE TMP_UpdCancPV.FlgProcessado = 0) DO
   
      SET xQtdeRegs = xQtdeRegs + 1;
      
      SELECT cod_emp, cod_fil, ano_solic, num_solic, num_item,
             TipoUpdCanc, UniqueKey, UpdateDate, Quantity, QtdeEstoque, SalUnitMsr, cnpj_cpf_dep, 
             ItemCode, cod_produto, StatusItem,
             DocumentId, DocumentType, DocumentNumber
      INTO xCodEmpWMS, xCodFilWMS, xAnoSolic, xNumSolic, xNumItem,
           xTipoUpdCanc, xUniqueKey, xUpdateDate, xQuantity, xQtdeEstoque, xEmbVendas, xCnpjCpfDep, 
           xItemCode, xCodProduto, xStatusItem,
           xDocEntry, xDocTipo, xDocNum
      FROM TMP_UpdCancPV
      WHERE TMP_UpdCancPV.FlgProcessado = 0
      LIMIT 1;
      
      #Quando for item deletado, xItemCode vem nulo
      SET xItemCode = IFNULL(xItemCode, xCodProduto);
      
      #Pega as informações do cadastro de produtos
      SELECT emb_estoque, emb_frac, emb_vol, fator_conversao, peso_liq_vol, peso_bruto_vol, peso_liq_frac
      INTO xemb_estoque, xemb_frac, xemb_vol, xfator_conversao, xpeso_liq_vol, xpeso_brt_vol, xpeso_liq_frac
      FROM of_logistica.tbprodutos
      WHERE cnpj_cpf = xCnpjCpfDep
        AND cod_produto = xItemCode;
     
      #select "aqui", xItemCode, xCodProduto;     
     
      IF xTipoUpdCanc = 'U' THEN
         #Calcula quantidade de volumes
         IF LOCATE('KG',xemb_estoque)  THEN
            SET xQtdevolumes = xQtdeEstoque / xpeso_liq_vol;
            SET xpesoLiqItem = xQtdeEstoque;
         ELSEIF xemb_estoque = xemb_vol THEN
            SET xQtdevolumes = xQtdeEstoque;
            SET xpesoLiqItem = xQtdevolumes * xpeso_liq_vol;
         ELSEIF xemb_estoque = xemb_frac THEN
            SET xQtdevolumes = xQtdeEstoque / xfator_conversao;
            SET xpesoLiqItem = xQtdevolumes * xpeso_liq_vol;  
         ELSE
            SET xQtdevolumes = xQuantity;
         END IF;
         
         SET xQtdeFrac = of_logistica.fnCalcQtdeFrac(xemb_frac, xfator_conversao, xpeso_liq_vol * xQtdevolumes, xQtdeVolumes);
      ELSE
         SET xQtdevolumes = 0;
         SET xpesoLiqItem = 0;
         SET xQtdeFrac = 0;
      END IF;

      #SELECT "aqui", xItemCode, xCodProduto;     
      
      INSERT INTO of_logistica.tbsolic_saidas_item_integra_alteracao (
                  cod_emp, cod_fil, ano_solic, num_solic, num_item, UniqueKey, dthr_inc, 
                  qtde_est_ant, qtde_vol_ant, qtde_frac_ant, qtde_peso_ant, 
                  qtde_est_atu , qtde_vol_atu, qtde_frac_atu, qtde_peso_atu)
         SELECT tbItem.cod_emp, tbItem.cod_fil, tbItem.ano_solic, tbItem.num_solic, tbItem.num_item,
                #TMP_UpdCancPV.UniqueKey, NOW() /*TMP_UpdCancPV.DocumentDate*/ , 
                TMP_UpdCancPV.UniqueKey, TMP_UpdCancPV.UpdateDate, 
                #Reviser David Ruy <2021/01/19> Campos conforme andamento do processo
                #tbItem.qtde_est, tbItem.qtde_vol, tbItem.qtde_frac, tbItem.pliq_item
                IF(dthr_final_baixa_geral IS NOT NULL,
                   tbItem.real_est2, IF(dthr_aconselhamento IS NOT NULL, tbItem.real_est, tbItem.qtde_est)),
                IF(dthr_final_baixa_geral IS NOT NULL,
                   tbItem.real_vol2, IF(dthr_aconselhamento IS NOT NULL, tbItem.real_vol, tbItem.qtde_vol)),
                IF(dthr_final_baixa_geral IS NOT NULL,
                   tbItem.real_frac2, IF(dthr_aconselhamento IS NOT NULL, tbItem.real_frac, tbItem.qtde_frac)),
                IF(dthr_final_baixa_geral IS NOT NULL,
                   tbItem.real_peso2, IF(dthr_aconselhamento IS NOT NULL, tbItem.real_peso, tbItem.pliq_item)),
                TMP_UpdCancPV.QtdeEstoque, xQtdevolumes, xQtdeFrac, xpesoLiqItem
         FROM TMP_UpdCancPV
         INNER JOIN of_logistica.tbsolic_saidas_item tbItem ON
               tbItem.cod_emp   = TMP_UpdCancPV.cod_emp 
           AND tbItem.cod_fil   = TMP_UpdCancPV.cod_fil
           AND tbItem.ano_solic = TMP_UpdCancPV.ano_solic 
           AND tbItem.num_solic = TMP_UpdCancPV.num_solic
           AND tbItem.num_item  = TMP_UpdCancPV.num_item
         WHERE TMP_UpdCancPV.UniqueKey  = xUniqueKey
           AND TMP_UpdCancPV.UpdateDate = xUpdateDate
         #@Reviser David Ruy <2021/01/19> Verifica diferença de quantidades
         AND (tbItem.cod_produto <> IFNULL(TMP_UpdCancPV.ItemCode,TMP_UpdCancPV.cod_produto)
           OR IF(dthr_final_baixa_geral IS NOT NULL,
                 ABS(tbItem.real_est2 - IFNULL(TMP_UpdCancPV.QtdeEstoque,0)) >= 0.001,
                 IF(dthr_aconselhamento IS NOT NULL,
                    ABS(tbItem.real_est - IFNULL(TMP_UpdCancPV.QtdeEstoque,0)) >= 0.001,
                    ABS(tbItem.qtde_est - IFNULL(TMP_UpdCancPV.QtdeEstoque,0)) >= 0.001
                    )
                 )
              );
         #@Reviser David Ruy <2020/05/14> Verifica diferença de quantidades
         #AND IF(tbItem.real_est IS NULL,
         #       ABS(tbItem.qtde_est - IFNULL(TMP_UpdCancPV.QtdeEstoque,0)) >= 0.001,
         #       ABS(tbItem.real_est - IFNULL(TMP_UpdCancPV.QtdeEstoque,0)) >= 0.001);
         
      #SELECT "aqui", xItemCode, xCodProduto;     
         
      #@Reviser David Ruy <2020/05/14> Só gera registro se quantidade for diferente
      IF ROW_COUNT() > 0 THEN
         #Atualizar Qtde Pedido (WMS)
         UPDATE of_logistica.tbsolic_saidas_item tbItem
         INNER JOIN of_logistica.tbsolic_saidas tbTopo ON
                    tbTopo.cod_emp   = tbItem.cod_emp 
                AND tbTopo.cod_fil   = tbItem.cod_fil
                AND tbTopo.ano_solic = tbItem.ano_solic
                AND tbTopo.num_solic = tbItem.num_solic
         SET tbItem.cod_produto = xItemCode,
             tbItem.qtde_nf     = xQuantity,
             tbItem.qtde_est    = xQtdeEstoque,
             tbItem.qtde_vol    = xQtdevolumes,
             tbItem.qtde_frac   = xQtdeFrac,
             tbItem.pliq_item   = xpesoLiqItem,
             tbItem.pbrt_item   = xpesoLiqItem + ((xpeso_brt_vol-xpeso_liq_vol) * xQtdevolumes),
             tbTopo.dthr_bloqueio_fin = IF(tbTopo.dthr_bloqueio_ini IS NULL, NULL, NOW()),
             tbTopo.usu_bloqueio_fin  = IF(tbTopo.usu_bloqueio_ini IS NULL, NULL, '999999')
         WHERE tbItem.cod_emp   = xCodEmpWMS
           AND tbItem.cod_fil   = xCodFilWMS
           AND tbItem.ano_solic = xAnoSolic
           AND tbItem.num_solic = xNumSolic
           AND tbItem.num_item  = xNumItem;
           
           
         SELECT cod_emp_pedido, cod_fil_pedido, cnpj_cpf_cli, num_ped_aux
         INTO xCodEmpTMS, xCodFilTMS, xCnpjCpfCli, xNumPedido
         FROM of_logistica.tbsolic_saidas_item
         WHERE cod_emp   = xCodEmpWMS
           AND cod_fil   = xCodFilWMS
           AND ano_solic = xAnoSolic
           AND num_solic = xNumSolic
           AND num_item  = xNumItem;
         
           
         #Atualizar Qtde Pedido (TMS)
         UPDATE of_logistica.tbprog_entregas Topo
         INNER JOIN of_logistica.tbprog_ite_entregas Item ON
                     Topo.cod_emp     = Item.cod_emp
                 AND Topo.cod_fil     = Item.cod_fil
                 AND Topo.ano_entrega = Item.ano_entrega
                 AND Topo.num_entrega = Item.num_entrega
         INNER JOIN of_logistica.tbnf_ite_clientes ItemNF ON
                    ItemNF.id_nf    = Topo.id_nf
                AND ItemNF.num_item = Item.num_item
         SET Item.cod_produto     = xItemCode,
             Item.qtde_ori        = xQtdeEstoque,
             Item.qtde_vol        = xQtdevolumes,
             Item.qtde_frac       = xQtdeFrac,
             Item.peso_liq_item   = xpesoLiqItem,
             Item.peso_brt_item   = xpesoLiqItem + ((xpeso_brt_vol-xpeso_liq_vol) * xQtdevolumes),
             ItemNF.cod_produto   = xItemCode,
             ItemNF.qtde_ori      = xQtdeEstoque,
             ItemNF.qtde_vol      = xQtdevolumes,
             ItemNF.qtde_frac     = xQtdeFrac,
             ItemNF.peso_liq_item = xpesoLiqItem,
             ItemNF.peso_brt_item = xpesoLiqItem + ((xpeso_brt_vol-xpeso_liq_vol) * xQtdevolumes)          
         WHERE Topo.cod_emp      = xCodEmpTMS
           AND Topo.cod_fil      = xCodFilTMS
           AND Topo.cnpj_cpf_cli = xCnpjCpfCli
           AND Topo.num_ped_aux  = xNumPedido
           AND Item.num_item     = xNumItem;
           
           
         #Atualiza Status da Integração para casos de alteração após a finalização do processo
         CALL PROC_INTEGRA_ReabrirIntegracao(xCodEmpWMS, xCodFilWMS, xAnoSolic, xNumSolic, "S", RESULTADO, MENSAGEM);
         #*********************** Verificar : Atualizar Topo Pedido / NF (TMS)
         
         
         UPDATE TMP_UpdCancPV
         SET TMP_UpdCancPV.FlgProcessado = 1
         WHERE TMP_UpdCancPV.UniqueKey  = xUniqueKey
           AND TMP_UpdCancPV.UpdateDate = xUpdateDate;
         
         UPDATE tbintegraSAP_UpdCancPV tbUpdCancPV 
         INNER JOIN tbintegraSAP_DocItem tbItem ON 
                    tbItem.DocEntry = tbUpdCancPV.DocumentId
                AND tbItem.DocTipo  = tbUpdCancPV.DocumentType 
                AND tbItem.DocNum   = tbUpdCancPV.DocumentNumber 
                AND tbItem.LineNum  = tbUpdCancPV.LineNumber 
         SET tbUpdCancPV.cod_emp = tbItem.cod_emp, 
             tbUpdCancPV.cod_fil = tbItem.cod_fil,
             tbUpdCancPV.ano_solic = tbItem.ano_solic,
             tbUpdCancPV.num_solic = tbItem.num_solic, 
             tbUpdCancPV.num_item  = tbItem.num_item,
             tbUpdCancPV.status    = 2,
             tbUpdCancPV.FreeText  = CONCAT(IFNULL(tbUpdCancPV.FreeText,""),"|(5)Atu Item =>",xDocTipo,xDocNum),
             tbItem.StatusAnt  = IF(tbItem.StatusItem = 9, tbItem.StatusAnt, tbItem.StatusItem),
             tbItem.StatusItem = IF(tbItem.StatusItem = 9, tbItem.StatusItem, 0)
         WHERE tbUpdCancPV.UniqueKey  = xUniqueKey
           AND tbUpdCancPV.UpdateDate = xUpdateDate;
         
      ELSE
      
         UPDATE TMP_UpdCancPV
         SET TMP_UpdCancPV.FlgProcessado = 1
         WHERE TMP_UpdCancPV.UniqueKey = xUniqueKey;
         
         #Libera o registro da atualilazação
         UPDATE tbintegraSAP_UpdCancPV tbUpdCancPV 
         INNER JOIN tbintegraSAP_DocItem tbItem ON 
                    tbItem.DocEntry = tbUpdCancPV.DocumentId
                AND tbItem.DocTipo  = tbUpdCancPV.DocumentType 
                AND tbItem.DocNum   = tbUpdCancPV.DocumentNumber 
                AND tbItem.LineNum  = tbUpdCancPV.LineNumber 
         SET tbUpdCancPV.cod_emp = tbItem.cod_emp, 
             tbUpdCancPV.cod_fil = tbItem.cod_fil,
             tbUpdCancPV.ano_solic = tbItem.ano_solic,
             tbUpdCancPV.num_solic = tbItem.num_solic, 
             tbUpdCancPV.num_item  = tbItem.num_item,
             tbUpdCancPV.STATUS    = 3,
             tbItem.StatusAnt  = IF(tbItem.StatusItem = 9, tbItem.StatusAnt, tbItem.StatusItem),
             tbItem.StatusItem = IF(tbItem.StatusItem = 9, tbItem.StatusItem, 0),
             tbUpdCancPV.FreeText  = CONCAT(IFNULL(tbUpdCancPV.FreeText,""),"|(6)Atu Item =>",xDocTipo,xDocNum)
         WHERE tbUpdCancPV.UniqueKey  = xUniqueKey
           AND tbUpdCancPV.UpdateDate = xUpdateDate;
      
      
      END IF;
      
      UPDATE tbintegraSAP_Doc
      LEFT JOIN tbintegraSAP_DocItem tbItem ON
                tbItem.DocEntry = tbintegraSAP_Doc.DocEntry
            AND tbItem.DocTipo  = tbintegraSAP_Doc.DocTipo
            AND tbItem.DocNum   = tbintegraSAP_Doc.DocNum
      SET UpdateDate = xUpdateDate,
          tbItem.StatusAnt  = IF(tbItem.StatusItem = 9, tbItem.StatusAnt, tbItem.StatusItem),
          tbItem.StatusItem = IF(tbItem.StatusItem = 9, tbItem.StatusItem, 0)
      WHERE tbintegraSAP_Doc.DocEntry = xDocEntry
        AND tbintegraSAP_Doc.DocTipo  = xDocTipo
        AND tbintegraSAP_Doc.DocNum   = xDocNum;      
      
   END WHILE;
   
   DROP TEMPORARY TABLE IF EXISTS TMP_UpdCancPV;  
   
   IF excecao = 1 THEN
      ROLLBACK;
      SET RESULTADO = 0;
      SET MENSAGEM = CONCAT(IFNULL(MENSAGEM,""),"- Erro PROC_INTEGRA_ProcessarAlteraoes [",xQtdeRegs,"]");
      #SELECT RESULTADO, MENSAGEM;
   ELSE
      COMMIT;
      SET RESULTADO = 1;
      SET MENSAGEM = CONCAT(IFNULL(MENSAGEM,""),"- Alterações processadas com sucesso [",xQtdeRegs,"]");
   END IF;
END$$

DELIMITER ;