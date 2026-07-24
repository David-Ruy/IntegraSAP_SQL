DELIMITER $$

DROP PROCEDURE IF EXISTS `PROC_INTEGRA_GerarGEM`$$

CREATE PROCEDURE `PROC_INTEGRA_GerarGEM`(
   IN oCodUsuario			          VARCHAR(10),
   IN oCodEmpSLIN             VARCHAR(03),
   IN oCodFilSLIN             VARCHAR(03),
   IN oChavePedido			         VARCHAR(10),
   IN oDocEntry			            VARCHAR(10),
   IN oNumPedido		            VARCHAR(20),
   IN oSerialNum              INT,
   IN oDataPedido             DATETIME,
   IN oCodCliente             VARCHAR(14),
   IN oNomeCliente            VARCHAR(100),
   IN oCFOP                   VARCHAR(10),
   IN oObservPedido			        VARCHAR(500),
   
   # Parametros de Retorno
   OUT RESULTADO              INT,
   OUT MENSAGEM               VARCHAR(500)
)
BLOCO1:BEGIN
  /************************************************************************
  * @Created David Ruy <2019/04/11>
  * Esta procedure realiza a Inclusão/Atualização da GEM com base nas informações da tbIntegraSAP_Doc (Documentos de Entradas)
  *
  *@Reviser David Ruy <2021/04/14> Gravar o campo SERIAL (oSerialNum -> NumNF Fornecedor) na GEM
  *@Reviser David Ruy <2022-09-24> Parametros : oCodEmpSLIN / oCodFilSLIN
  *@Reviser David Ruy <2023-06-29> Gravar NumNF => Concat('OP',oSerialNum) para produção
  *@Reviser David Ruy <2024-06-12> Gravar tbsolic_entradas.num_pedido = xDocEntryRef (BRW)
  *@Reviser David Ruy <2024-06-24> xDocNum -> Update num_nf->concat('PA',xDocNum)
  *@Reviser David Ruy <2025-01-27> xBDO_NKIT (Gemmini)
  *@Reviser David Ruy <2025-02-24> Tratativa xChavePedido 'PA%' (Panizzon)
  *                                Condição IFNULL(buyUnitMsr,IF(UomCode='MANUAL',buyUnitMsr,UomCode))
  *@Reviser David Ruy <2025-07-22> Update num_pedido => IFNULL(xDocEntryRef,xDocNum)
  *************************************************************************/
   DECLARE excecao 	INT DEFAULT 0;
   DECLARE xCodEmpWMS			      VARCHAR(03)	;#DEFAULT '001';
   DECLARE xCodFilWMS			      VARCHAR(03) ;#DEFAULT '001';
   DECLARE xCNPJCPFCLI        VARCHAR(14) ;#DEFAULT '04330905000180';
   DECLARE xRAZSOCCLI         VARCHAR(100) ;#DEFAULT '04330905000180';
   DECLARE xCodEstoque        VARCHAR(03) ;#DEFAULT '001';
   DECLARE xAnoSolic 			      VARCHAR(04)	DEFAULT YEAR(CURRENT_DATE());
   DECLARE xNumSolic 			      VARCHAR(10);
   DECLARE xDataAtual         DATETIME;
   DECLARE xChaveIntegracao   VARCHAR(50);
   DECLARE xNumPedido         VARCHAR(20);
   DECLARE xDocEntryRef       VARCHAR(30);
   DECLARE xBDO_NKIT          VARCHAR(50);
   DECLARE xDocNum            VARCHAR(30);
   
   DECLARE xTipoOperacao 		      VARCHAR(03) ;#DEFAULT '001';
   DECLARE xFlgGeraPendFiscal    VARCHAR(01) ;#DEFAULT 'N';
   DECLARE xCodUnidade			        VARCHAR(03) ;#DEFAULT '001';
   DECLARE xCodArmazem			        VARCHAR(02) ;#DEFAULT '01';
   DECLARE xCFOP                 VARCHAR(04) ;#DEFAULT '9999';
   DECLARE xFlgDevol             VARCHAR(01) ;#DEFAULT 'N';
   DECLARE xFlgProducao          VARCHAR(01) ;#DEFAULT 'N';
   DECLARE xIncAlt 	VARCHAR(01)	DEFAULT 'I';
   DECLARE xCodErro	INT DEFAULT 0;
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
   #Tratar e Validar as variáveis GEM
   *******************************************************************/
   SET xDataAtual = NOW(); 
   SET xCodErro   = 2;
   SET xIncAlt    = 'I';
   
   
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
          IF(IFNULL(tbWMSEstoqueCli.flg_troca_nf_wms,"N")="N","N", IF(tbOperacoesWMS.flg_gera_fiscal="S","N","S")) AS xFlgGeraPendFiscal,      
          tbSysEstoque.cod_oper_wms, tbOperacoesWMS.cod_cfop_padrao AS cod_cfop_padrao, tbOperacoesWMS.flg_devol AS xFlgDevol,
          tbOperacoesWMS.flg_producao AS xFlgProducao
   INTO xCodEmpWMS, xCodFilWMS, xCNPJCPFCLI, xCodEstoque, 
        xCodUnidade, xCodArmazem,
        xFlgGeraPendFiscal, xTipoOperacao, xCFOP, xFlgDevol, xFlgProducao
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
      SET MENSAGEM = CONCAT("Parametrização não localizada - tbsys_integracao_estoque");
      LEAVE BLOCO1;
   END IF;
   
   #Considera CFOP da Integração se não for vazio
   IF IFNULL(oCFOP,'') <> '' THEN
      SET xCFOP = SUBSTRING(oCFOP,1,4);
      #Cadastrar CFOP se não existir
      IF NOT EXISTS (SELECT 1 FROM of_logistica.tbwms_oper_fiscal_ent
                     WHERE cod_oper = xCFOP) THEN
         INSERT INTO of_logistica.tbwms_oper_fiscal_ent
         VALUES (xCFOP, "CFOP INTEGRACAO - FAVOR CADASTRAR DESCRICAO");
      END IF;
   END IF;
     
   IF IFNULL(xCodEmpWMS,'') = '' OR 
      IFNULL(xCodFilWMS,'') = '' OR
      IFNULL(xCodEstoque,'') = '' OR
      IFNULL(xCodUnidade,'') = '' OR 
      IFNULL(xCodArmazem,'') = '' OR
      IFNULL(xFlgGeraPendFiscal,'') = '' OR
      IFNULL(xTipoOperacao,'') = '' OR
      IFNULL(xCFOP,'') = '' THEN
      SET RESULTADO = 0;
      SET MENSAGEM = CONCAT("Parametrização incompleta - tbsys_integracao_estoque");
      LEAVE BLOCO1;
   END IF;
   
   
   IF (xFlgProducao = 'S') OR (xFlgDevol = 'S') THEN
      # Se for Entrada de Produção, fornecedor = CNPJ / NOME (Integração)
      SELECT raz_social INTO xRAZSOCCLI 
      FROM of_logistica.tbwms_terceiro 
      WHERE cnpj_cpf_cliente = xCNPJCPFCLI
        AND cnpj_cpf_terceiro = xCNPJCPFCLI;
      SET oCodCliente  = xCNPJCPFCLI;  #IF(IFNULL(oCodCliente,'')='',xCNPJCPFCLI,oCodCliente);
      SET oNomeCliente = xRAZSOCCLI;   #IF(IFNULL(oNomeCliente,'')='',xRAZSOCCLI,oNomeCliente);
   END IF;
   
   
   
   /***************************************************************************
   #@Reviser David Ruy <2024/06/12>
   #Busca informações do Topo da Entrada
   ****************************************************************************/
   SELECT DocEntryRef, DocNum, U_BDO_NKIT INTO xDocEntryRef, xDocNum, xBDO_NKIT
   FROM tbintegraSAP_Doc
   WHERE chave_integracao = xChaveIntegracao;
   
   
   
   
   /***************************************************************************
   ****************************************************************************/   
   SELECT tbsolic_entradas.cod_emp, tbsolic_entradas.cod_fil, tbsolic_entradas.ano_solic, tbsolic_entradas.num_solic
   INTO xCodEmpWMS, xCodFilWMS, xAnoSolic, xNumSolic
   FROM of_logistica.tbsolic_entradas 
   LEFT JOIN of_logistica.tbsolic_entradas_item ON
        tbsolic_entradas_item.cod_emp   = tbsolic_entradas.cod_emp
    AND tbsolic_entradas_item.cod_fil   = tbsolic_entradas.cod_fil
    AND tbsolic_entradas_item.ano_solic = tbsolic_entradas.ano_solic
    AND tbsolic_entradas_item.num_solic = tbsolic_entradas.num_solic
   WHERE tbsolic_entradas.cnpj_cpf_cli  = xCNPJCPFCLI
     AND (tbsolic_entradas.chave_integracao = xChaveIntegracao)
       #OR num_nf_vda = oChavePedido);
   LIMIT 1;
   IF xNumSolic IS NOT NULL THEN
      SET xIncAlt = 'A';		
   END IF;
   IF (NOT xFlgProducao = 'S') AND (NOT xFlgDevol = 'S') THEN
      CALL PROC_INTEGRA_CAD_Terceiro(oCodUsuario, xCNPJCPFCLI, oCodCliente, 0, oNomeCliente, oNomeCliente, 1, @R, @M);
      IF @R = 0 THEN
         SET RESULTADO = 0;
         SET MENSAGEM = CONCAT('PROC_INTEGRA_CAD_Terceiro ',@M, oCodCliente, oNomeCliente);
         LEAVE BLOCO1;
      END IF;
   END IF;
   IF xIncAlt = 'I' THEN
      
      SELECT LPAD(MAX(IFNULL(CAST(num_solic AS UNSIGNED),0))+1,10,'0')
      INTO xNumSolic 
      FROM of_logistica.tbsolic_entradas
      WHERE cod_emp   = xCodEmpWMS
        AND cod_fil   = xCodFilWMS
        AND ano_solic = xAnoSolic;
      SET xNumSolic = IFNULL(xNumSolic,'0000000001');
      /****************************************************************/
      /****************GRAVAR TOPO 
      /****************************************************************/
      INSERT INTO of_logistica.tbsolic_entradas( cod_emp
                           , cod_fil
                           , ano_solic
                           , num_solic
                           , data_solic
                           , flg_tipo_oper
                           , flg_utensilio
                           , flg_devol
                           , flg_gera_cobr
                           , flg_cobra_min
                           , flg_interface
                           , flg_pend_fiscal
                           , cod_oper
                           , cnpj_cpf_cli
                           , cnpj_cpf_dep
                           , cnpj_cpf_for
                           , cod_estoque
                           , flg_tipo_doc
                           , num_nf
                           , serie_nf
                           , data_nf
                           , observ_solic
                           , status_solic
                           , dthr_inc
                           , usu_inc
                           , cod_und
                           , cod_armazem
                           , flg_importacao_xml
                           , status_processo
                           , flg_producao
                           , chave_integracao
                           , num_pedido
                           #, inicio_descarga
                           #, final_descarga
                           #, dthr_acons
                           #, usu_acons
                           #, dthr_confer
                           #, usu_confer
                           #, dthr_confirm
                           #, usu_confirm
                           )
                      VALUES ( xCodEmpWMS
                           ,xCodFilWMS
                           ,xAnoSolic
                           ,xNumSolic
                           , CAST(xDataAtual AS DATE)
                           , xTipoOperacao
                           , 0         # flg_utensilio
                           , xFlgDevol # flg_devol
                           , 'N'       # flg_gera_cobr
                           , 'N'       # flg_cobra_min
                           , 'N'       # flg_interface (iNtegração)
                           , xFlgGeraPendFiscal 
                           ,xCFOP
                           ,xCNPJCPFCLI
                           ,xCNPJCPFCLI
                           ,oCodCliente
                           ,xCodEstoque
                           ,IF(SUBSTRING(oChavePedido,1,2)='PA', 'PA', oChavePedido) 
                           #,IF(xFlgProducao='N',oSerialNum,xNumPedido)
                           #,IF(xFlgProducao='N',oSerialNum,CONCAT("OP",IFNULL(oSerialNum, xNumPedido)))
                           ,IF(xFlgProducao='N',oSerialNum,CONCAT("PA",xDocNum))
                           , ''
                           , CAST(XDataAtual AS DATE)
                           , CONCAT('Integração SAP (Fornecedor:',oNomeCliente,') - ',xChaveIntegracao," ",IFNULL(oObservPedido,""),
                                    IF(xBDO_NKIT IS NULL,'', CONCAT(' NKIT:',xBDO_NKIT)))
                           , '1' 
                           , xDataAtual
                           
                           ,oCodUsuario
                           ,xCodUnidade
                           ,xCodArmazem
                           ,'N' 
                           , 3
                           , xFlgProducao
                           #,xDataAtual
                           #,xDataAtual
                           #,xDataAtual
                           #,oCodUsuario
                           #,xDataAtual
                           #,oCodUsuario
                           #,xDataAtual
                           #,oCodUsuario
                           , xChaveIntegracao
                           , IFNULL(xDocEntryRef,xDocNum)
                           );
      INSERT INTO of_logistica.tbsolic_entradas_fiscal (
            cod_emp, cod_fil, ano_solic, num_solic, cnpj_cpf_emi, flg_tipo_doc, num_nf, serie_nf, data_nf, cod_tipo_oper, cod_oper)
      VALUES (xCodEmpWMS, xCodFilWMS, xAnoSolic, xNumSolic, oCodCliente, oChavePedido, 
               IF(xFlgProducao='N',oSerialNum,xNumPedido),
               '', xDataAtual, xTipoOperacao, '9999');
      SET RESULTADO = 3;
      SET MENSAGEM = CONCAT(xCodEmpWMS, xCodFilWMS, xAnoSolic, xNumSolic);		
   ELSE
      SELECT status_processo INTO RESULTADO
      FROM of_logistica.tbsolic_entradas
      WHERE cod_emp = xCodEmpWMS
        AND cod_fil = xCodFilWMS
        AND ano_solic = xAnoSolic
        AND num_solic = xNumSolic;
      SET MENSAGEM = CONCAT(xCodEmpWMS, xCodFilWMS, xAnoSolic, xNumSolic, ' - GEM já cadastrada');
   END IF;
   
   
   
   
   
   /************************************************************************************************/
   #Fase 2 - Inclusão dos Itens
   /************************************************************************************************/
   SET xRefGuia = CONCAT(xCodEmpWMS, xCodFilWMS, xAnoSolic, xNumSolic);
   
   DROP TEMPORARY TABLE IF EXISTS tbtmp_IntegraDocItem;
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
             tbintegraSAP_DocItem.NumInSale, tbintegraSAP_DocItem.NumInBuy, tbintegraSAP_DocItem.BatchNumbersCode
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
             #@Reviser David Ruy <2025-02-24> Alterado, estava IFNULL(UomCode,buyUnitMsr), 
             IFNULL(buyUnitMsr,IF(UomCode='MANUAL',buyUnitMsr,UomCode)), 
             IFNULL(salUnitMsr,IF(UomCode='MANUAL',salUnitMsr,UomCode)), 
             invntryUom, NumInSale, NumInBuy, BatchNumbersCode
      INTO xLineNum, xItemCode, xBaseQty, xOpenInvQty, xVlrUnitario, xWhareHouseIte, xStatusItem, xObservacoesIte,
           xdescription, xbuyUnitMsr, xsalUnitMsr, xinvntryUom, 
           xNumInSale, xNumInBuy, xBatchCode
      FROM tbtmp_IntegraDocItem
      WHERE DocTipo  = oChavePedido
        AND DocEntry = oDocEntry
      ORDER BY LineNum LIMIT 1;
      
      SET xVlrUnitario = IF(IFNULL(xVlrUnitario,1)=0,1,IFNULL(xVlrUnitario,1));
      SET xdescription = IFNULL(xdescription,'');
      SET xbuyUnitMsr = IFNULL(xbuyUnitMsr,'');
      SET xsalUnitMsr = IFNULL(xsalUnitMsr,'');
      SET xinvntryUom = IFNULL(xinvntryUom,'');
      SET xObservacoesIte = SUBSTRING(xObservacoesIte,1,100);
      
      
      CALL PROC_INTEGRA_GerarGEMItem(oCodUsuario, xRefGuia, CONCAT(oNumPedido,'(',oDocEntry,')'), xLineNum, xItemCode, xBaseQty, xOpenInvQty, xVlrUnitario, 
                  xStatusItem, xObservacoesIte, xdescription, IF(oChavePedido = 'DV' OR oChavePedido LIKE 'PA%',xsalUnitMsr,xbuyUnitMsr), xinvntryUom, 
                  IF(oChavePedido = 'DV' OR oChavePedido LIKE 'PA%',xNumInSale,xNumInBuy), xWhareHouseIte, @R, @M);            
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
           AND IF(xflg_agrupa_transf=1 AND oChavePedido = "TD-E", ItemCode = xItemCode, LineNum  = xLineNum);            
              
         CALL PROC_INTEGRA_EnviarLog('999999', 'PROC_INTEGRA_GerarGEMItem',
                  CONCAT('Inserido/Atualizado ',oChavePedido,oDocEntry,'-',oNumPedido,' | ', xRefGuia, '| Prd:', xItemCode), "200", @M, @R, @M);
      ELSE
         SET excecao   = 1;
         DELETE FROM tbtmp_IntegraDocItem
         WHERE DocTipo  = oChavePedido
           AND DocEntry = oDocEntry;
      END IF;
            
      DELETE FROM tbtmp_IntegraDocItem
      WHERE DocTipo  = oChavePedido
        AND DocEntry = oDocEntry
        AND LineNum  = xLineNum;
                      
   END WHILE;       
   DROP TEMPORARY TABLE IF EXISTS tbtmp_IntegraDocItem;
   IF excecao = 0 THEN
      COMMIT;
   ELSE
      ROLLBACK;
      
      SET RESULTADO = 0;
      SET MENSAGEM = CONCAT('ERRO Inclusão de Item ',oChavePedido,oDocEntry,'-',oNumPedido,' | ', xRefGuia, '| Prd:', xItemCode);
      
      CALL PROC_INTEGRA_EnviarLog('999999',
             IF(oChavePedido IN ("PV","OP","TD-S","NS"), 'PROC_INTEGRA_GerarGSMItem', 'PROC_INTEGRA_GerarGEMItem'),
               CONCAT('NÃO Inserido/Atualizado ',oChavePedido,oDocEntry,'-',oNumPedido,' | ', xRefGuia, '| Prd:', xItemCode), "200", @M, @R, @M);      
   END IF;
   
   
   
END$$

DELIMITER ;