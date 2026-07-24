DELIMITER $$

DROP PROCEDURE IF EXISTS `PROC_INTEGRA_GerarGSM`$$

CREATE PROCEDURE `PROC_INTEGRA_GerarGSM`(
   IN oCodUsuario				          VARCHAR(10),
   IN oCodEmpSLIN             VARCHAR(03),
   IN oCodFilSLIN             VARCHAR(03),
   IN oChavePedido			         VARCHAR(10),
   IN oDocEntry			            VARCHAR(10),
   IN oNumPedido		            VARCHAR(20),
   IN oDataPedido             DATETIME,
   IN oDataEntrega            DATETIME,
   IN oCodCliente             VARCHAR(14),
   IN oNomeCliente            VARCHAR(100),
   IN oObservPedido	          VARCHAR(2000),
   IN oNomeVendedor           VARCHAR(200),
   IN oValorPedido            DECIMAL(18,5),
   IN oTipoFrete              VARCHAR(05),
   IN oNomeTransp             VARCHAR(50),
   IN oCnpjTransp             VARCHAR(20),
   
   OUT RESULTADO              INT,
   OUT MENSAGEM               VARCHAR(500)
)
BLOCO1:BEGIN
  # PROCEDURE INTEGRAÇÃO PARA GERAR GSM
  # @author David Ruy
  # @company Overflash
  
  /**
   * ------------------------ INFORMAÇÕES ADICIONAIS -----------------------
   *
   *@Reviser David Ruy <2022-09-24> Parametros : oCodEmpSLIN / oCodFilSLIN
   *@Reviser David Ruy <2024-03-25> Transaction e chamada da inserção de itens
   *@Reviser David Ruy <2024-06-19> Alteração variável oObservPedido -> VARCHAR(500) -> VARCHAR(2000)
   *@Reviser David Ruy <2024-06-28> Inclusão da condição DocNum   = oNumPedido nas instruções SQL
   *@Reviser David Ruy <2024-09-23> CNPJ Centralizador       
   #@Reviser David Ruy <2025-01-10> DocTipo = 'DC'  Devolução de Compras
   *@Reviser David Ruy <2026-04-06> Implementação PROC_INTEGRA_LiberarStatusUAs (xDocEntryOrdemProducao)
   *@Reviser David Ruy <2026-04-17> Implementação PROC_WMS_SAIDA_GERAR_ACONSELHAMENTO_TOTAL após commit
   * ---------------------- FIM INFORMAÇÕES ADICIONAIS ---------------------
   */
  
  /****************************************************************/
  /****************DECLARAR VARIÁVEIS AUXILIARES
  /****************************************************************/
   DECLARE excecao              TINYINT DEFAULT 0;
   DECLARE _IDDestinatario      INT(11); 
   DECLARE xCodEmpWMS			        VARCHAR(03);  #DEFAULT '001';
   DECLARE xCodFilWMS			        VARCHAR(03);  #DEFAULT '001';
   DECLARE xCNPJCPFCLI          VARCHAR(14);  #DEFAULT '04330905000180';
   DECLARE xRAZSOCCLI           VARCHAR(100); #DEFAULT '04330905000180';
   DECLARE xCodEstoque          VARCHAR(03);  #DEFAULT '001';
   DECLARE xAnoSolic 			        VARCHAR(04)	DEFAULT YEAR(CURRENT_DATE());
   DECLARE xNumSolic 			        VARCHAR(10);
   DECLARE xDataAtual           DATETIME;
   DECLARE xGSMDataSaida        DATETIME DEFAULT oDataEntrega; #DATE_ADD(CURRENT_DATE(), INTERVAL 1 DAY);
   DECLARE xChaveIntegracao     VARCHAR(50);
   DECLARE xNumPedido           VARCHAR(20);
   DECLARE xTipoOperacao 		     VARCHAR(03); #DEFAULT '002';
   DECLARE xFlgEmiteNF          VARCHAR(01)  DEFAULT 'N';
   DECLARE xFLGDataCritica      VARCHAR(01)  DEFAULT 'S';
   DECLARE xFLGDataRestrita     VARCHAR(01)  DEFAULT 'S';
   DECLARE xFLGVencidos         VARCHAR(01)  DEFAULT 'S';
   DECLARE xFLGDataFutura       VARCHAR(01)  DEFAULT 'S';
   DECLARE xPercentualVidaUtil  DECIMAL(5,2) DEFAULT 0;
   DECLARE xCodUnidade			       VARCHAR(03); #DEFAULT '001';
   DECLARE xCodArmazem			       VARCHAR(02); #DEFAULT '01';
   DECLARE xCFOP                VARCHAR(04); #DEFAULT '9999';
   DECLARE xFlgProducao         VARCHAR(01); #DEFAULT 'N';
   DECLARE xIncAlt 	            VARCHAR(01)	DEFAULT 'I';
   DECLARE xCodErro	            INT         DEFAULT 0;
   DECLARE xflg_agrupa_transf TINYINT;  
   DECLARE xRefGuia           VARCHAR(30);
   DECLARE xNumItem           VARCHAR(06);
   DECLARE xLineNum           INT;
   DECLARE xItemCode          VARCHAR(30);
   DECLARE xBaseQty           DOUBLE(20,6);
   DECLARE xOpenInvQty        DOUBLE(20,6);
   DECLARE xVlrUnitario       DOUBLE(20,6);
   DECLARE xWhareHouseIte     VARCHAR(10); 
   DECLARE xStatusItem        VARCHAR(10);
   DECLARE xObservacoesIte    VARCHAR(300); 
   DECLARE xdescription       VARCHAR(100); 
   DECLARE xbuyUnitMsr        VARCHAR(30); 
   DECLARE xsalUnitMsr        VARCHAR(30); 
   DECLARE xinvntryUom        VARCHAR(30); 
   DECLARE xNumInSale         DECIMAL(18,6);
   DECLARE xNumInBuy          DECIMAL(18,6);
   DECLARE xBatchCode         VARCHAR(30); 
   #
   DECLARE xDocEntryOrdemProducao VARCHAR(30);
   DECLARE xAny_OrdemProducao     BOOLEAN  DEFAULT FALSE;
   
  
   DECLARE EXIT HANDLER FOR SQLEXCEPTION
   BEGIN
       GET DIAGNOSTICS CONDITION 1 MENSAGEM = MESSAGE_TEXT;
       SET excecao   = 1;
       SET RESULTADO = 0;
       SET MENSAGEM  = of_logistica.fnMensagemExcecao(MENSAGEM);
       SELECT MENSAGEM;
       ROLLBACK;
   END;  
   START TRANSACTION;
  
   /*******************************************************************
   #Tratar e Validar as variáveis GSM
   *******************************************************************/
   
   SET xDataAtual = NOW();
   SET xCodErro = 2;
   SET xIncAlt = 'I';
   SET oCnpjTransp = fnTirarCaracteresEspeciais(oCnpjTransp);
   SET oTipoFrete = IFNULL(oTipoFrete,"N/A");
  
  
  
   /***************************************************************************
   #@Parametros
   ****************************************************************************/
   SELECT flg_agrupa_transf INTO xflg_agrupa_transf 
   FROM tbintegraSAP_parametros LIMIT 1;  
  
  
  
   /***************************************************************************
   #@Reviser David Ruy <2019/12/11>
   # Busca informações dos parametros para gerar o documento
   ****************************************************************************/
   SET xNumPedido       = CONCAT(oChavePedido, oNumPedido);
   SET xChaveIntegracao = CONCAT(xNumPedido,'-',oDocEntry);
   SET xCNPJCPFCLI = NULL;
   #
   
   SELECT tbSysEstoque.cod_emp, tbSysEstoque.cod_fil, tbSysEstoque.cnpj_cpf_cli, tbSysEstoque.cod_estoque,
          tbWMSEstoqueCli.cod_und, tbWMSEstoqueCli.cod_armazem,
          IF(IFNULL(tbWMSEstoqueCli.flg_troca_nf_wms,"N")="N","N", IF(tbOperacoesWMS.flg_gera_fiscal="S","N","S")) AS xFlgEmiteNF,
          tbSysEstoque.cod_oper_wms, tbOperacoesWMS.cod_cfop_padrao AS cod_cfop_padrao,
          tbOperacoesWMS.flg_producao AS xFlgProducao
   INTO xCodEmpWMS, xCodFilWMS, xCNPJCPFCLI, xCodEstoque,
        xCodUnidade, xCodArmazem,
        xFlgEmiteNF, xTipoOperacao, xCFOP, xFlgProducao
   FROM of_logistica.tbsys_integracao tbSys
   INNER JOIN of_logistica.tbsys_integracao_estoque tbSysEstoque ON
             tbSysEstoque.id_integracao = tbSys.id_integracao
         #AND tbSysEstoque.chave_integracao = oChavePedido
         AND tbSysEstoque.chave_integracao = IF(oChavePedido LIKE 'PA%','PA', oChavePedido)
   INNER JOIN of_logistica.tbwms_tipo_oper tbOperacoesWMS ON
         tbOperacoesWMS.cod_oper_wms = tbSysEstoque.cod_oper_wms
   INNER JOIN of_logistica.tbwms_estoque_cli tbWMSEstoqueCli ON
             tbWMSEstoqueCli.cod_emp = tbSysEstoque.cod_emp
         AND tbWMSEstoqueCli.cod_fil = tbSysEstoque.cod_fil
         AND tbWMSEstoqueCli.cod_estoque = tbSysEstoque.cod_estoque
   WHERE tbSys.nome_integracao_wms = 'SAP B1'
     AND tbSysEstoque.cod_emp = oCodEmpSLIN
     AND tbSysEstoque.cod_fil = oCodFilSLIN
   LIMIT 1;
   
   #@Reviser David Ruy <2022-09-24> 
   SET xCodEmpWMS = oCodEmpSLIN;
   SET xCodFilWMS = oCodFilSLIN;
   
   
   IF xCNPJCPFCLI IS NULL THEN
      SET RESULTADO = 0;
      SET MENSAGEM = CONCAT("Parametrização incompleta - tbsys_integrcao_estoque");
      LEAVE BLOCO1;
   END IF;
   IF IFNULL(xCodEmpWMS,'') = '' OR
      IFNULL(xCodFilWMS,'') = '' OR
      IFNULL(xCodEstoque,'') = '' OR
      IFNULL(xCodUnidade,'') = '' OR
      IFNULL(xCodArmazem,'') = '' OR
      IFNULL(xFlgEmiteNF,'') = '' OR
      IFNULL(xTipoOperacao,'') = '' OR
      IFNULL(xCFOP,'') = ''    
   THEN
      SET RESULTADO = 0;
      SET MENSAGEM = CONCAT("Parametrização incompleta - tbsys_integrcao_estoque");
      LEAVE BLOCO1;
   END IF;
   
   IF xFlgProducao = 'S' THEN
      # Se for Saída para Produção, fornecedor = CNPJ / NOME (Integração)
      SELECT raz_social INTO xRAZSOCCLI
      FROM of_logistica.tbwms_terceiro
      WHERE cnpj_cpf_cliente = xCNPJCPFCLI
        AND cnpj_cpf_terceiro = xCNPJCPFCLI;
      SET oCodCliente  = IF(IFNULL(oCodCliente,'')='',xCNPJCPFCLI,oCodCliente);
      SET oNomeCliente = IF(IFNULL(oNomeCliente,'')='',xRAZSOCCLI,oNomeCliente);
   END IF;
   SELECT tbsolic_saidas.cod_emp, tbsolic_saidas.cod_fil, tbsolic_saidas.ano_solic, tbsolic_saidas.num_solic
     INTO xCodEmpWMS, xCodFilWMS, xAnoSolic, xNumSolic
   FROM of_logistica.tbsolic_saidas
   LEFT JOIN of_logistica.tbsolic_saidas_item ON
        tbsolic_saidas_item.cod_emp   = tbsolic_saidas.cod_emp
    AND tbsolic_saidas_item.cod_fil   = tbsolic_saidas.cod_fil
    AND tbsolic_saidas_item.ano_solic = tbsolic_saidas.ano_solic
    AND tbsolic_saidas_item.num_solic = tbsolic_saidas.num_solic
   WHERE tbsolic_saidas.cnpj_cpf_cli     = xCNPJCPFCLI
     AND tbsolic_saidas.chave_integracao = xChaveIntegracao
   LIMIT 1;
   
   IF xNumSolic IS NOT NULL THEN
    SET xIncAlt = 'A';
   END IF;
   
   IF (xIncAlt = 'I') THEN
   
      SELECT of_logistica.tbdestinatarios.id_destinatario
        INTO _IDDestinatario
        FROM of_logistica.tbclientes 
       INNER JOIN of_logistica.tbdestinatarios ON 
                  tbdestinatarios.cnpj_cpf_cliente = tbclientes.cnpj_cpf_centralizador
              AND tbdestinatarios.cod_integracao   = oCodCliente
       WHERE of_logistica.tbclientes.cnpj_cpf = xCNPJCPFCLI
       LIMIT 1; 
             
      SELECT LPAD(MAX(IFNULL(CAST(num_solic AS UNSIGNED),0))+1,10,'0')
        INTO xNumSolic
        FROM of_logistica.tbsolic_saidas
       WHERE of_logistica.tbsolic_saidas.cod_emp   = xCodEmpWMS
         AND of_logistica.tbsolic_saidas.cod_fil   = xCodFilWMS
         AND of_logistica.tbsolic_saidas.ano_solic = xAnoSolic;
      SET xNumSolic = IFNULL(xNumSolic,'0000000001');
      
      INSERT INTO of_logistica.tbsolic_saidas ( cod_emp
                                           , cod_fil
                                           , ano_solic
                                           , num_solic
                                           , data_solic
                                           , num_nf
                                           , data_nf
                                           , flg_tipo_oper
                                           , flg_gera_cobr
                                           , flg_cobra_min
                                           , perc_vutil
                                           , flg_interface
                                           , flg_emite_nf
                                           , cnpj_cpf_cli
                                           , cnpj_cpf_dep
                                           , cod_estoque
                                           , flg_dt_critica
                                           , flg_dt_restrita
                                           , flg_vencidos
                                           , flg_dt_futura
                                           , flg_tipo_quebra
                                           , data_saida
                                           , observ_solic
                                           , cnpj_cpf_for 
                                           , descr_pedido
                                           , cnpj_cpf_transp
                                           , vlr_tot_nf
                                           , dthr_inc
                                           , usu_inc
                                           , cod_und
                                           , cod_armazem
                                           , tipo_conferencia
                                           , status_processo
                                           , flg_producao
                                           , id_destinatario
                                           , chave_integracao
                                           )
                                    VALUES ( xCodEmpWMS
                                           , xCodFilWMS
                                           , xAnoSolic
                                           , xNumSolic
                                           , CAST(xDataAtual AS DATE)
                                           , xNumPedido
                                           , oDataPedido
                                           , xTipoOperacao
                                           , 'N'
                                           , 'N'
                                           , xPercentualVidaUtil
                                           , 'N' 
                                           , xFlgEmiteNF
                                           , xCNPJCPFCLI
                                           , xCNPJCPFCLI
                                           , xCodEstoque
                                           , xFLGDataCritica
                                           , xFLGDataRestrita
                                           , xFLGVencidos
                                           , xFLGDataFutura
                                           , 'N' #flg_tipo_quebra (N-Apenas 1)
                                           , xGSMDataSaida
                                           , CONCAT('Integração (Destinatário:',oNomeCliente,') - ',oDocEntry," ",IFNULL(oObservPedido,""), " Frete:",oTipoFrete)
                                           , IF(IFNULL(oCodCliente,'') = '', NULL, oCodCliente)
                                           , oNomeVendedor
                                           , oCnpjTransp
                                           , oValorPedido
                                           , xDataAtual
                                           , oCodUsuario
                                           , xCodUnidade
                                           , xCodArmazem
                                           , '1' #1-Baixa Geral, 2-Picking Estoque
                                           , '1' #1-GSM Aberta
                                           , xFlgProducao
                                           , IF( IFNULL(_IDDestinatario, 0) = 0 
                                               , NULL 
                                               , _IDDestinatario
                                               )
                                           , xChaveIntegracao
                                           );
     SET RESULTADO = 1;
     SET MENSAGEM = CONCAT(xCodEmpWMS, xCodFilWMS, xAnoSolic, xNumSolic);
   ELSE
      SELECT status_processo 
        INTO RESULTADO
        FROM of_logistica.tbsolic_saidas
       WHERE cod_emp = xCodEmpWMS
         AND cod_fil = xCodFilWMS
         AND ano_solic = xAnoSolic
         AND num_solic = xNumSolic;
      SET MENSAGEM = CONCAT(xCodEmpWMS, xCodFilWMS, xAnoSolic, xNumSolic, ' - GSM já cadastrada');
   END IF;
   
   
   
   
   /************************************************************************************************/
   #Fase 2 - Inclusão dos Itens
   /************************************************************************************************/
   SET xRefGuia = CONCAT(xCodEmpWMS, xCodFilWMS, xAnoSolic, xNumSolic);
   
   DROP TEMPORARY TABLE IF EXISTS tbtmp_IntegraDocItem;
   IF oChavePedido = 'TD-S' AND xflg_agrupa_transf = 1 THEN   
      CREATE TEMPORARY TABLE tbtmp_IntegraDocItem
         SELECT tbintegraSAP_DocItem.DocEntry, tbintegraSAP_DocItem.DocTipo, tbintegraSAP_DocItem.DocNum, 
                tbintegraSAP_DocItem.LineNum, 
                tbintegraSAP_DocItem.ItemCode, SUM(tbintegraSAP_DocItem.BaseQty) BaseQty, SUM(tbintegraSAP_DocItem.OpenInvQty) OpenInvQty,
                (tbintegraSAP_DocItem.Price*IF(IFNULL(tbintegraSAP_DocItem.DollarQuote,0)=0,1,tbintegraSAP_DocItem.DollarQuote)) Price, 
                tbintegraSAP_DocItem.UomCode,
                tbintegraSAP_DocItem.DollarQuote,
                tbintegraSAP_DocItem.WhareHouse, 
                tbintegraSAP_DocItem.StatusItem, 
                SUBSTRING(tbintegraSAP_DocItem.Observacoes,1,300) AS Observacoes, 
                tbintegraSAP_DocItem.description, tbintegraSAP_DocItem.buyUnitMsr, tbintegraSAP_DocItem.salUnitMsr, 
                tbintegraSAP_DocItem.invntryUom, 
                tbintegraSAP_DocItem.NumInSale, tbintegraSAP_DocItem.NumInBuy, tbintegraSAP_DocItem.BatchNumbersCode,
                tbintegraSAP_DocItem.DocEntryOrdemProducao, tbintegraSAP_DocItem.DocNumOrdemProducao, tbintegraSAP_DocItem.SerialOrdemProducao
         FROM tbintegraSAP_DocItem
         INNER JOIN tbintegraSAP_Doc ON
                    tbintegraSAP_Doc.DocEntry = tbintegraSAP_DocItem.DocEntry
                AND tbintegraSAP_Doc.DocTipo  = tbintegraSAP_DocItem.DocTipo
         WHERE tbintegraSAP_DocItem.DocTipo  = oChavePedido
           AND tbintegraSAP_DocItem.DocEntry = oDocEntry
           AND tbintegraSAP_DocItem.DocNum   = oNumPedido
           AND tbintegraSAP_DocItem.num_solic IS NULL
           AND IFNULL(tbintegraSAP_DocItem.StatusItem,'0') <= '2'  #Traz os itens com status nulo (a inserir) e 1 = A atualizar
         GROUP BY tbintegraSAP_DocItem.DocEntry, tbintegraSAP_DocItem.DocTipo, tbintegraSAP_DocItem.DocNum, tbintegraSAP_DocItem.ItemCode
         ORDER BY tbintegraSAP_DocItem.DocTipo, tbintegraSAP_DocItem.DocEntry, tbintegraSAP_DocItem.LineNum;
   ELSE
      CREATE TEMPORARY TABLE tbtmp_IntegraDocItem
         SELECT tbintegraSAP_DocItem.DocEntry, tbintegraSAP_DocItem.DocTipo, tbintegraSAP_DocItem.DocNum, 
                tbintegraSAP_DocItem.LineNum, 
                tbintegraSAP_DocItem.ItemCode, tbintegraSAP_DocItem.BaseQty, tbintegraSAP_DocItem.OpenInvQty,
                (tbintegraSAP_DocItem.Price*IF(IFNULL(tbintegraSAP_DocItem.DollarQuote,0)=0,1,tbintegraSAP_DocItem.DollarQuote)) Price, 
                tbintegraSAP_DocItem.UomCode,
                tbintegraSAP_DocItem.DollarQuote,
                tbintegraSAP_DocItem.WhareHouse, 
                tbintegraSAP_DocItem.StatusItem, 
                SUBSTRING(tbintegraSAP_DocItem.Observacoes,1,300) AS Observacoes, 
                tbintegraSAP_DocItem.description, tbintegraSAP_DocItem.buyUnitMsr, tbintegraSAP_DocItem.salUnitMsr, 
                tbintegraSAP_DocItem.invntryUom, 
                tbintegraSAP_DocItem.NumInSale, tbintegraSAP_DocItem.NumInBuy, tbintegraSAP_DocItem.BatchNumbersCode,
                tbintegraSAP_DocItem.DocEntryOrdemProducao, tbintegraSAP_DocItem.DocNumOrdemProducao, tbintegraSAP_DocItem.SerialOrdemProducao
         FROM tbintegraSAP_DocItem
         INNER JOIN tbintegraSAP_Doc ON
                    tbintegraSAP_Doc.DocTipo  = tbintegraSAP_DocItem.DocTipo    
                AND tbintegraSAP_Doc.DocEntry = tbintegraSAP_DocItem.DocEntry
         WHERE tbintegraSAP_DocItem.DocTipo  = oChavePedido
           AND tbintegraSAP_DocItem.DocEntry = oDocEntry
           AND tbintegraSAP_DocItem.DocNum   = oNumPedido
           AND tbintegraSAP_DocItem.num_solic IS NULL
           AND IFNULL(tbintegraSAP_DocItem.StatusItem,'0') <= '2'  #Traz os itens com status nulo (a inserir) e 1 = A atualizar
         ORDER BY tbintegraSAP_DocItem.DocTipo, tbintegraSAP_DocItem.DocEntry, tbintegraSAP_DocItem.LineNum;
   END IF;
   
   
   #SELECT oChavePedido, oDocEntry, oNumPedido, tbtmp_IntegraDocItem.* FROM tbtmp_IntegraDocItem;
   #rollback; Leave BLOCO1;
   
   
   
   #Insere / Atualiza Itens  
   WHILE EXISTS (SELECT 1 FROM tbtmp_IntegraDocItem
                 WHERE DocTipo  = oChavePedido
                   AND DocEntry = oDocEntry
                 ORDER BY LineNum) DO
                 
      SELECT LineNum, ItemCode, BaseQty, IFNULL(OpenInvQty, BaseQty),
             (Price*IF(IFNULL(DollarQuote,0)=0,1,DollarQuote)), WhareHouse, StatusItem, Observacoes, 
             #description, buyUnitMsr, salUnitMsr, invntryUom, 
             description, 
             #@Reviser David Ruy <2025-02-24> Alterado, estava IFNULL(UomCode,IF(UomCode='MANUAL',buyUnitMsr,UomCode)), 
             IFNULL(buyUnitMsr,IF(UomCode='MANUAL',buyUnitMsr,UomCode)), 
             IFNULL(salUnitMsr,IF(UomCode='MANUAL',salUnitMsr,UomCode)), 
             invntryUom, NumInSale, NumInBuy, BatchNumbersCode, DocEntryOrdemProducao
      INTO xLineNum, xItemCode, xBaseQty, xOpenInvQty, xVlrUnitario, xWhareHouseIte, xStatusItem, xObservacoesIte,
           xdescription, xbuyUnitMsr, xsalUnitMsr, xinvntryUom, 
           xNumInSale, xNumInBuy, xBatchCode, xDocEntryOrdemProducao
      FROM tbtmp_IntegraDocItem
      WHERE DocTipo  = oChavePedido
        AND DocEntry = oDocEntry
        AND DocNum   = oNumPedido
      ORDER BY LineNum LIMIT 1;
      
      IF xDocEntryOrdemProducao IS NOT NULL THEN 
         SET xAny_OrdemProducao = TRUE;
      END IF;
      
      SET xVlrUnitario = IF(IFNULL(xVlrUnitario,1)=0,1,IFNULL(xVlrUnitario,1));
      SET xdescription = IFNULL(xdescription,'');
      SET xbuyUnitMsr = IFNULL(xbuyUnitMsr,'');
      SET xsalUnitMsr = IFNULL(xsalUnitMsr,'');
      SET xinvntryUom = IFNULL(xinvntryUom,'');
      SET xObservacoesIte = SUBSTRING(xObservacoesIte,1,300);
      
      #Debug
      #select 'PROC_INTEGRA_GerarGSMItem',oCodUsuario, xRefGuia, CONCAT(oNumPedido,'(',oDocEntry,')'), xLineNum, xItemCode, xdescription, xBaseQty, xOpenInvQty, xVlrUnitario, 
      #            xsalUnitMsr, xinvntryUom, xNumInsale, xStatusItem, xObservacoesIte, oCodCliente, oNomeCliente, xBatchCode, xWhareHouseIte, @R, @M;
      #
      CALL PROC_INTEGRA_GerarGSMItem(oCodUsuario, xRefGuia, CONCAT(oNumPedido,'(',oDocEntry,')'), xLineNum, xItemCode, xdescription, xBaseQty, xOpenInvQty, xVlrUnitario, 
                  xsalUnitMsr, xinvntryUom, xNumInsale, xStatusItem, xObservacoesIte, oCodCliente, oNomeCliente, xBatchCode, xWhareHouseIte, @R, @M);
      IF @R = 1 THEN      
         SET xStatusItem = @R;
         SET xNumItem    = SUBSTRING(@M,01,06);  #Numero do item no retorno da proc
         #Atualiza referencia GSM na tbintegraSAP_DocItem
         UPDATE tbintegraSAP_DocItem
         SET cod_emp     = xCodEmpWMS
            ,cod_fil     = xCodFilWMS
            ,ano_solic   = xAnoSolic
            ,num_solic   = xNumSolic
            ,num_item    = xNumItem
            ,StatusItem  = '0'    #Volta para Zero para identificar que já atualizou no SLIN
         WHERE DocTipo  = oChavePedido
           AND DocEntry = oDocEntry
           AND DocNum   = oNumPedido
           AND IF(xflg_agrupa_transf=1 AND oChavePedido = "TD-S", ItemCode = xItemCode, LineNum  = xLineNum);            
              
         CALL PROC_INTEGRA_EnviarLog(oCodUsuario, 'PROC_INTEGRA_GerarGSMItem',
                  CONCAT('Inserido/Atualizado ',oChavePedido,oDocEntry,'-',oNumPedido,' | ', xRefGuia, '| Prd:', xItemCode), "200", @M, @R, @M);
      ELSE
         SET excecao   = 1;
         DELETE FROM tbtmp_IntegraDocItem
         WHERE DocTipo  = oChavePedido
           AND DocEntry = oDocEntry
           AND DocNum   = oNumPedido;
         CALL PROC_INTEGRA_EnviarLog(oCodUsuario, 'PROC_INTEGRA_GerarGSMItem',
                  CONCAT('ERRO GERANDO ITEM GSM ',oChavePedido,oDocEntry,'-',oNumPedido,' | ', xRefGuia, '| Prd:', xItemCode), "ERRO", @M, @R, @M);
      END IF;
            
      DELETE FROM tbtmp_IntegraDocItem
      WHERE DocTipo  = oChavePedido
        AND DocEntry = oDocEntry
        AND DocNum   = oNumPedido
        AND LineNum  = xLineNum;
                
   END WHILE;       
   
   DROP TEMPORARY TABLE IF EXISTS tbtmp_IntegraDocItem;
   
   IF excecao = 0 THEN
      COMMIT;
      
      
      IF xAny_OrdemProducao THEN
         CALL PROC_INTEGRA_LiberarStatusUAs(oCodUsuario, oChavePedido, oDocEntry, oNumPedido, @R, @M);
         CALL PROC_INTEGRA_EnviarLog(oCodUsuario, 'PROC_INTEGRA_LiberarStatusUAs',
                  CONCAT('Liberando UA´s ',oChavePedido,oDocEntry,'-',oNumPedido,' | ', xRefGuia), IF(@R=1,"200","ERRO"), @M, @R, @M);

         CALL of_logistica.PROC_WMS_SAIDA_GERAR_ACONSELHAMENTO_TOTAL(8,
              xCodEmpWMS, xCodFilWMS, xAnoSolic, xNumSolic, '999999', @R, @M);

         CALL PROC_INTEGRA_EnviarLog('999999',
                'PROC_INTEGRA_LiberarStatusUAs - Aconselhamento',
                  CONCAT(oChavePedido,oNumPedido,'(',oDocEntry,')',' |GEM=', xCodEmpWMS,'/',xCodFilWMS,'-',xAnoSolic,'.',xNumSolic), IF(@R=1,"200","ERRO"), @M, @R, @M);       
      END IF;
      
      
   ELSE
      ROLLBACK;
      
      SET RESULTADO = 0;
      SET MENSAGEM = CONCAT('ERRO Inclusão de Item ',oChavePedido,oDocEntry,'-',oNumPedido,' | ', xRefGuia, '| Prd:', xItemCode);
      
      CALL PROC_INTEGRA_EnviarLog(oCodUsuario,
             IF(oChavePedido IN ('PV','OP','TD-S','NS','DC'), 'PROC_INTEGRA_GerarGSMItem', 'PROC_INTEGRA_GerarGEMItem'),
               CONCAT('NÃO Inserido/Atualizado ',oChavePedido,oDocEntry,'-',oNumPedido,' | ', xRefGuia, '| Prd:', xItemCode), "200", @M, @R, @M);      
   END IF;
   
   
END$$

DELIMITER ;