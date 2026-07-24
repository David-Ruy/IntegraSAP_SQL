DELIMITER $$

DROP PROCEDURE IF EXISTS `PROC_INTEGRA_RetornoProducao`$$

CREATE PROCEDURE `PROC_INTEGRA_RetornoProducao`(
   IN oCodUsuario				VARCHAR(10),
   IN oIdRetorno				 MEDIUMTEXT,
   IN oTiporetorno   INT     #0 = 3 RecordSets (Topo - Item - UA), 1 = 2 RecordSets (Topo/Item - UA)
                             #10 = Listar Documentos a gerar ENTRADA COMPLETA
                             #11 = Gerar ENTRADA COMPLETA
   #IN oTipoConsulta			INT     #0 = Apenas o Topo, 1 = Detalhe por ITEM, 2 = Detalhe por UA
   # Parametros de Retorno
   #OUT RESULTADO             	INT,
   #OUT MENSAGEM              	VARCHAR(500)
)
BLOCO1:BEGIN
   /***************************************************************************
   #@Reviser David Ruy <2019/12/11> 
   # Busca informações do tipo de operação para retornar apenas GEM de Produção 
   #@Reviser David Ruy <2026/04/04> 
   # Implementado retorno campo tbintegraSAP_Doc.TipoProducao
   ****************************************************************************/
   DECLARE xCodEmpWMS			    VARCHAR(03)	DEFAULT '001';
   DECLARE xCodFilWMS			    VARCHAR(03) DEFAULT '001';
   DECLARE xNumSolic 			    VARCHAR(10);
   DECLARE xAnoSolic 			    VARCHAR(04)	DEFAULT YEAR(CURRENT_DATE());
   DECLARE xDocEntry        INT;
   DECLARE xDocTipo         VARCHAR(10);
   DECLARE xTipoOperSaida 		VARCHAR(03) DEFAULT '001';
   DECLARE xCodUnidade			   VARCHAR(03) DEFAULT '001';
   DECLARE xCodArmazem			   VARCHAR(02) DEFAULT '01';
   DECLARE xStatusProcesso		VARCHAR(02) DEFAULT '01';
   DECLARE xCodErro	        INT DEFAULT 0;
   DECLARE excecao 	        INT DEFAULT 0;
   DECLARE RESULTADO        INT DEFAULT 1;
   DECLARE MENSAGEM         VARCHAR(500);
   DECLARE xSTRGEM          TEXT;
   DECLARE xNumProcesso     VARCHAR(20);  
   
   DECLARE xNumUA           INT;
   DECLARE xIdPallet        VARCHAR(50);
   DECLARE xQtde            DECIMAL(18,6);
   DECLARE xNumLote         VARCHAR(50);
   DECLARE xDataFabr        VARCHAR(20);
   DECLARE xDataValid       VARCHAR(20);
   DECLARE xFatorConv       DECIMAL(18,6);
   DECLARE xCodProduto      VARCHAR(50);
   DECLARE xNumCaixaBarcode VARCHAR(100);
   
   
   
   DECLARE EXIT HANDLER FOR SQLEXCEPTION
   BEGIN
       GET DIAGNOSTICS CONDITION 1 MENSAGEM = MESSAGE_TEXT;
       SET excecao   = 1;
       SET RESULTADO = 0;
       SET MENSAGEM  = of_logistica.fnMensagemExcecao(MENSAGEM);
       SELECT RESULTADO, MENSAGEM;
       ROLLBACK;
   END;
   
   
       
   #Cria tabela temporária com as GEM que estão liberadas para retorno à integração
   DROP TEMPORARY TABLE IF EXISTS tbTMP_INTEGRA_RETORNO_PRODUCAO;
   
   IF oTiporetorno IN (0,1,10) THEN
  
      IF IFNULL(oIdRetorno,'') = '' THEN
      
         CREATE TEMPORARY TABLE tbTMP_INTEGRA_RETORNO_PRODUCAO AS 
            SELECT DocEntry, DocTipo, DocNum, tbEntradas.num_nf, tbEntradas.data_nf, tbEntradas.data_solic
                  ,CONCAT(tbEntradas.cod_emp, tbEntradas.cod_fil, tbEntradas.ano_solic, tbEntradas.num_solic) NumProcesso
                  ,tbEntradas.cod_emp, tbEntradas.cod_fil, tbEntradas.ano_solic, tbEntradas.num_solic
                  ,tbEntradas.status_processo, tbEntradas.observ_solic 
                  #,CONCAT('CALL PROC_INTEGRA_RetornoEntrada("999999","',CONCAT(tbEntradas.cod_emp, tbEntradas.cod_fil, tbEntradas.ano_solic,   tbEntradas.num_solic),'");') _call
            FROM tbintegraSAP_Doc
            INNER JOIN of_logistica.tbsolic_entradas tbEntradas ON
                  tbEntradas.cod_emp   = tbintegraSAP_Doc.cod_emp
              AND tbEntradas.cod_fil   = tbintegraSAP_Doc.cod_fil
              AND tbEntradas.ano_solic = tbintegraSAP_Doc.ano_solic
              AND tbEntradas.num_solic = tbintegraSAP_Doc.num_solic
              AND IF(oTiporetorno = 10, tbEntradas.status_processo = 3, tbEntradas.status_processo >= 8)
              AND tbintegraSAP_Doc.StatusDoc = 3
            INNER JOIN of_logistica.tbwms_tipo_oper tbOperacoesWMS ON 
                  tbOperacoesWMS.cod_oper_wms = tbEntradas.flg_tipo_oper
            WHERE tbintegraSAP_Doc.TipoDocSLIN = 'E'
              #AND tbOperacoesWMS.flg_producao = 'S';
              AND tbEntradas.flg_producao = 'S';
      ELSE
      
         SET xCodEmpWMS	= SUBSTRING(oIdRetorno,01,03);
         SET xCodFilWMS	= SUBSTRING(oIdRetorno,04,03);
         SET xAnoSolic 	= SUBSTRING(oIdRetorno,07,04);
         SET xNumSolic 	= SUBSTRING(oIdRetorno,11,10);    
         #select xCodEmpWMS, xCodFilWMS, xAnoSolic, xNumSolic;
         /*******************************************************************
         # Validar a existencia da GEM
         *******************************************************************/
         IF NOT EXISTS (SELECT 1 FROM of_logistica.tbsolic_entradas 
                        WHERE cod_emp = xCodEmpWMS
                        AND cod_fil = xCodFilWMS
                        AND ano_solic = xAnoSolic
                        AND num_solic = xNumSolic) THEN
            SET xCodErro = 1;
            SET RESULTADO = 0;
            SET MENSAGEM  = 'GEM não localizada';
            SELECT RESULTADO, MENSAGEM;
            LEAVE BLOCO1;         
         END IF;
         CREATE TEMPORARY TABLE tbTMP_INTEGRA_RETORNO_PRODUCAO AS 
            SELECT DocEntry, DocTipo, DocNum, tbEntradas.num_nf, tbEntradas.data_nf, tbEntradas.data_solic
                  ,CONCAT(tbEntradas.cod_emp, tbEntradas.cod_fil, tbEntradas.ano_solic, tbEntradas.num_solic) NumProcesso
                  ,tbEntradas.cod_emp, tbEntradas.cod_fil, tbEntradas.ano_solic, tbEntradas.num_solic
                  ,tbEntradas.status_processo, tbEntradas.observ_solic 
                  #,CONCAT('CALL PROC_INTEGRA_RetornoEntrada("999999","',CONCAT(tbEntradas.cod_emp, tbEntradas.cod_fil, tbEntradas.ano_solic, tbEntradas.num_solic),'");') _call
            FROM tbintegraSAP_Doc
            INNER JOIN of_logistica.tbsolic_entradas tbEntradas ON
                  tbEntradas.cod_emp   = tbintegraSAP_Doc.cod_emp
              AND tbEntradas.cod_fil   = tbintegraSAP_Doc.cod_fil
              AND tbEntradas.ano_solic = tbintegraSAP_Doc.ano_solic
              AND tbEntradas.num_solic = tbintegraSAP_Doc.num_solic
              AND tbEntradas.status_processo >= 8
              AND tbintegraSAP_Doc.StatusDoc = 3
            WHERE tbintegraSAP_Doc.cod_emp   = xCodEmpWMS 
              AND tbintegraSAP_Doc.cod_fil   = xCodFilWMS
              AND tbintegraSAP_Doc.ano_solic = xAnoSolic
              AND tbintegraSAP_Doc.num_solic = xNumSolic
              AND tbintegraSAP_Doc.TipoDocSLIN = 'E';
      
      END IF;
      
      #Alimenta variavel xSTRGEM com a lista das GEM´s selecionadas
      SET xSTRGEM = '';  
      WHILE EXISTS (SELECT 1 FROM tbTMP_INTEGRA_RETORNO_PRODUCAO) DO
         SELECT NumProcesso, cod_emp, cod_fil, ano_solic, num_solic, DocEntry, Doctipo
         INTO xNumProcesso, xCodEmpWMS, xCodFilWMS, xAnoSolic, xNumSolic, xDocEntry, xDoctipo
         FROM tbTMP_INTEGRA_RETORNO_PRODUCAO LIMIT 1;         
         
         SET xSTRGEM = CONCAT(xSTRGEM, CONCAT(xCodEmpWMS, "|", xCodFilWMS, "|", xAnoSolic, "|", xNumSolic, "|", xDocEntry, "|"), xDocTipo, "|");
         DELETE FROM tbTMP_INTEGRA_RETORNO_PRODUCAO WHERE NumProcesso = xNumProcesso;
      END WHILE;
      DROP TEMPORARY TABLE IF EXISTS tbTMP_INTEGRA_RETORNO_PRODUCAO;
      #Cria tabela temporária auxiliar para inner join com a tbsolic_entradas para gerar seleção das informações
      #da GSM informada no parametro
      CALL PROC_SYS_GerarTabelaComTexto(xSTRGEM,'|',6);
      
   ELSEIF oTiporetorno = 11 THEN
   
      #Complementar a GEM com as informações das etiquetas dos pallets lidos


      #Cria tabela temporária auxiliar com informações dos lotes e quantidade de cada pallet     
      CALL PROC_SYS_GerarTabelaComTexto(oIdRetorno,'|',6);
      #select * from tTabelaComTexto;
      
      START TRANSACTION;
      
      WHILE EXISTS (SELECT 1 FROM tTabelaComTexto WHERE Coluna01 IS NOT NULL) DO
      
         #00100120240000000001|12315|40|L1654XR12|2024-04-10|2028-04-10
         SELECT Coluna01, Coluna02, Coluna03, Coluna04, Coluna05, Coluna06
         INTO xSTRGEM, xIdPallet, xQtde, xNumLote, xDataFabr, xDataValid
         FROM tTabelaComTexto WHERE Coluna01 IS NOT NULL
         LIMIT 1;
                 
         SET xCodEmpWMS	= SUBSTRING(xSTRGEM,01,03);
         SET xCodFilWMS	= SUBSTRING(xSTRGEM,04,03);
         SET xAnoSolic 	= SUBSTRING(xSTRGEM,07,04);
         SET xNumSolic 	= SUBSTRING(xSTRGEM,11,10);             
         
         SET xNumUA = NULL;

         SELECT tbsolic_entradas_acons.num_lote, tbsolic_entradas_item.cod_produto, tbsolic_entradas_item.fator_conv
         INTO xNumUA, xCodProduto, xFatorConv
         FROM of_logistica.tbsolic_entradas_acons
         INNER JOIN of_logistica.tbsolic_entradas_item ON 
                    tbsolic_entradas_item.cod_emp   = tbsolic_entradas_acons.cod_emp
                AND tbsolic_entradas_item.cod_fil   = tbsolic_entradas_acons.cod_fil
                AND tbsolic_entradas_item.ano_solic = tbsolic_entradas_acons.ano_solic
                AND tbsolic_entradas_item.num_solic = tbsolic_entradas_acons.num_solic
                AND tbsolic_entradas_item.num_item  = tbsolic_entradas_acons.num_item
         WHERE tbsolic_entradas_acons.cod_emp   = xCodEmpWMS
           AND tbsolic_entradas_acons.cod_fil   = xCodFilWMS
           AND tbsolic_entradas_acons.ano_solic = xAnoSolic
           AND tbsolic_entradas_acons.num_solic = xNumSolic
           AND tbsolic_entradas_acons.qtde_est3 IS NULL
         LIMIT 1;         
         SET xNumCaixaBarcode = CONCAT(xCodProduto,'.',xIdPallet);
         
         IF xNumUA IS NULL THEN
            
            SELECT tbsolic_entradas_item.cod_produto, tbsolic_entradas_item.fator_conv
            INTO xCodProduto, xFatorConv
            FROM of_logistica.tbsolic_entradas_acons
            INNER JOIN of_logistica.tbsolic_entradas_item ON 
                       tbsolic_entradas_item.cod_emp   = tbsolic_entradas_acons.cod_emp
                   AND tbsolic_entradas_item.cod_fil   = tbsolic_entradas_acons.cod_fil
                   AND tbsolic_entradas_item.ano_solic = tbsolic_entradas_acons.ano_solic
                   AND tbsolic_entradas_item.num_solic = tbsolic_entradas_acons.num_solic
                   AND tbsolic_entradas_item.num_item  = tbsolic_entradas_acons.num_item
            WHERE tbsolic_entradas_acons.cod_emp   = xCodEmpWMS
              AND tbsolic_entradas_acons.cod_fil   = xCodFilWMS
              AND tbsolic_entradas_acons.ano_solic = xAnoSolic
              AND tbsolic_entradas_acons.num_solic = xNumSolic
            LIMIT 1;
            SET xNumCaixaBarcode = CONCAT(xCodProduto,'.',xIdPallet);
            

            SELECT IFNULL(MAX(num_lote)+1,0) INTO xNumUA FROM of_logistica.tbwms_estoque
            WHERE tbwms_estoque.cod_emp   = xCodEmpWMS
              AND tbwms_estoque.cod_fil   = xCodFilWMS;
                 
            INSERT INTO of_logistica.tbsolic_entradas_acons (
               cod_emp, cod_fil, ano_solic, num_solic, num_item, num_lote, sequencia_lote, 
               num_lote_cli, num_caixa, num_caixa_barcode, data_fabr, data_valid, dthr_conf,
               qtde_est, qtde_vol, qtde_frac, qtde_est2, qtde_vol2, qtde_frac2, qtde_est3, qtde_vol3, qtde_frac3
            ) VALUES (
               xCodEmpWMS, xCodFilWMS, xAnoSolic, xNumSolic, '000001', LPAD(xNumUA,10,'0') , 1, 
               xNumLote,xIdPallet, xNumCaixaBarcode, xDataFabr, xDataValid, NOW(), 
               xQtde, xQtde/xFatorConv, xQtde, 
               xQtde, xQtde/xFatorConv, xQtde, 
               xQtde, xQtde/xFatorConv, xQtde);
               

            INSERT INTO of_logistica.tbwms_estoque (
               cod_emp, cod_fil, ano_solic, num_solic, num_item, num_lote, sequencia_lote, 
               num_lote_cli, num_caixa, num_caixa_barcode, data_fabr, data_valid, 
               qtde_est, qtde_vol, qtde_frac, qtde_est2, qtde_vol2, qtde_frac2, qtde_est3, qtde_vol3, qtde_frac3
            ) VALUES (
               xCodEmpWMS, xCodFilWMS, xAnoSolic, xNumSolic, '000001', LPAD(xNumUA,10,'0') , 1, 
               xNumLote,xIdPallet, xNumCaixaBarcode, xDataFabr, xDataValid,  
               xQtde, xQtde/xFatorConv, xQtde, 
               xQtde, xQtde/xFatorConv, xQtde, 
               xQtde, xQtde/xFatorConv, xQtde);
                              
         ELSE
         
            UPDATE of_logistica.tbsolic_entradas_acons
            SET num_lote_cli = xNumLote,
                num_caixa = xIdPallet,
                num_caixa_barcode = xNumCaixaBarcode,
                data_fabr = xDataFabr,
                data_valid = xDataValid,
                dthr_conf = NOW(),
                qtde_est = xQtde, qtde_vol = xQtde/xFatorConv, qtde_frac = xQtde,
                qtde_est2 = xQtde, qtde_vol2 = xQtde/xFatorConv, qtde_frac2 = xQtde,
                qtde_est3 = xQtde, qtde_vol3 = xQtde/xFatorConv, qtde_frac3 = xQtde
            WHERE tbsolic_entradas_acons.cod_emp   = xCodEmpWMS
              AND tbsolic_entradas_acons.cod_fil   = xCodFilWMS
              AND tbsolic_entradas_acons.num_lote  = xNumUA
              AND tbsolic_entradas_acons.sequencia_lote = 1;
              
            UPDATE of_logistica.tbwms_estoque
            SET num_lote_cli = xNumLote,
                num_caixa = xIdPallet,
                num_caixa_barcode = xNumCaixaBarcode,
                data_fabr = xDataFabr,
                data_valid = xDataValid,
                dthr_conf = NOW(),
                qtde_est = xQtde, qtde_vol = xQtde/xFatorConv, qtde_frac = xQtde,
                qtde_est2 = xQtde, qtde_vol2 = xQtde/xFatorConv, qtde_frac2 = xQtde,
                qtde_est3 = xQtde, qtde_vol3 = xQtde/xFatorConv, qtde_frac3 = xQtde
            WHERE tbwms_estoque.cod_emp   = xCodEmpWMS
              AND tbwms_estoque.cod_fil   = xCodFilWMS
              AND tbwms_estoque.num_lote  = xNumUA
              AND tbwms_estoque.sequencia_lote = 1;
              
         END IF;
         #select xCodEmpWMS, xCodFilWMS, xAnoSolic, xNumSolic, xNumLote, xIdPallet, xQtde, xDataFabr, xDataValid, NOW();
         
         UPDATE tTabelaComTexto
         SET Coluna01 = NULL
         WHERE Coluna02 = xIdPallet;
      
      END WHILE; 
      COMMIT;    
   
   END IF;
    
    
   /*******************************************************************
   # Selecionar as informações da GSM
   *******************************************************************/
   # Retorno com 3 RecordSets
   IF oTiporetorno IN (0,10) THEN
      # INFORMAÇÕES DO TOPO DA GSM
      SELECT tTabelaComTexto.Coluna05 AS DocEntry, tTabelaComTexto.Coluna06 AS Doctipo, tbintegraSAP_Doc.DocNum,
             tbintegraSAP_Doc.TipoProducao, 
             #tbintegraSAP_Doc.DocEntry, tbintegraSAP_Doc.DocTipo,
            topo.cod_emp, topo.cod_fil, topo.ano_solic, topo.num_solic, 
            topo.data_solic, topo.dthr_acons, topo.num_nf AS num_pedido,
            topo.observ_solic, topo.observ_conf01, topo.status_processo, 
            of_logistica.fnStatusSaidaWms(topo.status_processo) status_processoAux,
            #Liberação Inicio Processo de Separação, Picking
            topo.dthr_endereco, topo.dthr_confer, topo.dthr_confirm,
            #Inicio Processo de Separação, Picking
            topo.dthr_chegada, topo.final_descarga,
            IFNULL(tbintegraSAP_Doc.TaxDate, tbintegraSAP_Doc.DocDate) TaxDate, tbintegraSAP_Doc.Observacoes Comments
            ,topo.chave_integracao
            ,RESULTADO, MENSAGEM
      FROM of_logistica.tbsolic_entradas topo
      INNER JOIN tTabelaComTexto ON
                tTabelaComTexto.Coluna01 = topo.cod_emp
            AND tTabelaComTexto.Coluna02 = topo.cod_fil
            AND tTabelaComTexto.Coluna03 = topo.ano_solic
            AND tTabelaComTexto.Coluna04 = topo.num_solic
      INNER JOIN tbintegraSAP_Doc ON 
               tbintegraSAP_Doc.cod_emp   = topo.cod_emp
           AND tbintegraSAP_Doc.cod_fil   = topo.cod_fil
           AND tbintegraSAP_Doc.ano_solic = topo.ano_solic
           AND tbintegraSAP_Doc.num_solic = topo.num_solic
           AND tbintegraSAP_Doc.DocEntry  = tTabelaComTexto.coluna05
           AND tbintegraSAP_Doc.DocTipo   = tTabelaComTexto.coluna06;
      
      # INFORMAÇÕES DOS ITENS DA GSM
      SELECT topo.cod_emp, topo.cod_fil, topo.ano_solic, topo.num_solic, 
            ite.num_nf_vda AS num_ped_cli, ite.num_item, ite.cod_produto, descr_produto,
            ite.emb_est, ite.emb_frac, ite.emb_vol, ite.fator_conv,
            #
            ite.qtde_est, ite.qtde_vol, ite.qtde_frac, ite.pliq_item,		#Qtde Pedido
            ite.real_est, ite.real_vol, ite.real_frac, ite.real_peso,		#Qtde Aconselhada
            ite.real_est2, ite.real_vol2, ite.real_frac2, ite.real_peso2,	#Qtde Conferencia
            ite.real_est3, ite.real_vol3, ite.real_frac3, ite.real_peso3,	#Qtde Conferencia / ???
            #			
            ite.dthr_conf_ini, ite.dthr_conf_fin,
            tbintegraSAP_DocItem.LineNum, tbintegraSAP_DocItem.WhareHouse, tbintegraSAP_DocItem.NumInBuy
            ,tbintegraSAP_DocItem.ManBtchNum
            ,topo.chave_integracao
            ,prod.flg_obriga_lote_fornecedor
            ,RESULTADO, MENSAGEM
      FROM of_logistica.tbsolic_entradas topo
      INNER JOIN tTabelaComTexto ON
                tTabelaComTexto.Coluna01 = topo.cod_emp
            AND tTabelaComTexto.Coluna02 = topo.cod_fil
            AND tTabelaComTexto.Coluna03 = topo.ano_solic
            AND tTabelaComTexto.Coluna04 = topo.num_solic
      LEFT JOIN of_logistica.tbsolic_entradas_item ite ON
            ite.cod_emp = topo.cod_emp
            AND ite.cod_fil = topo.cod_fil
            AND ite.ano_solic = topo.ano_solic
            AND ite.num_solic = topo.num_solic
      LEFT JOIN of_logistica.tbprodutos prod ON
                prod.cnpj_cpf    = ite.cnpj_cpf_dep
            AND prod.cod_produto = ite.cod_produto
      LEFT JOIN tbintegraSAP_Doc ON 
               tbintegraSAP_Doc.cod_emp   = topo.cod_emp
           AND tbintegraSAP_Doc.cod_fil   = topo.cod_fil
           AND tbintegraSAP_Doc.ano_solic = topo.ano_solic
           AND tbintegraSAP_Doc.num_solic = topo.num_solic
           AND tbintegraSAP_Doc.TipoDocSLIN = 'E'
      INNER JOIN tbintegraSAP_DocItem ON 
                tbintegraSAP_DocItem.cod_emp   = ite.cod_emp
            AND tbintegraSAP_DocItem.cod_fil   = ite.cod_fil
            AND tbintegraSAP_DocItem.ano_solic = ite.ano_solic
            AND tbintegraSAP_DocItem.num_solic = ite.num_solic
            AND tbintegraSAP_DocItem.num_item  = ite.num_item
            AND tbintegraSAP_DocItem.DocTipo   = tbintegraSAP_Doc.DocTipo;
 
    
      # INFORMAÇÕES DAS UA´S DA GSM
      SELECT topo.cod_emp, topo.cod_fil, topo.ano_solic, topo.num_solic, 
            ite.num_nf_vda AS num_ped_cli, ite.num_item, ite.cod_produto, descr_produto,
            ite.emb_est, ite.emb_frac, ite.emb_vol, ite.fator_conv,
            #
            CONCAT(acons.num_lote,acons.sequencia_lote) AS NumUA,
            tbwms_estoque.num_lote_cli,
            acons.qtde_est, acons.qtde_vol, acons.qtde_frac, acons.qtde_peso,		#Qtde Aconselhada
            acons.qtde_est2, acons.qtde_vol2, acons.qtde_frac2, acons.qtde_peso2,	#Qtde Separada
            acons.qtde_est3, acons.qtde_vol3, acons.qtde_frac3, acons.qtde_peso3,	#(*) Qtde Conferencia/???
            #		
            acons.dthr_conf, acons.dthr_armaz,
            of_logistica.fnLocalizCompleta2(acons.cod_und, acons.cod_armazem, acons.camara, acons.rua, 
                                         acons.posicao, acons.altura, acons.profund, NULL, "Sem endereco") AS BinCode
            ,topo.chave_integracao
            ,RESULTADO, MENSAGEM
      FROM of_logistica.tbsolic_entradas topo
      LEFT JOIN of_logistica.tbsolic_entradas_item ite ON
                ite.cod_emp   = topo.cod_emp
            AND ite.cod_fil   = topo.cod_fil
            AND ite.ano_solic = topo.ano_solic
            AND ite.num_solic = topo.num_solic			
      LEFT JOIN of_logistica.tbprodutos prod ON
                prod.cnpj_cpf    = ite.cnpj_cpf_dep
            AND prod.cod_produto = ite.cod_produto
      LEFT JOIN of_logistica.tbsolic_entradas_acons acons ON
                acons.cod_emp   = ite.cod_emp
            AND acons.cod_fil   = ite.cod_fil
            AND acons.ano_solic = ite.ano_solic
            AND acons.num_solic = ite.num_solic			
            AND acons.num_item  = ite.num_item
      LEFT JOIN of_logistica.tbwms_estoque ON  
            tbwms_estoque.cod_emp = acons.cod_emp
            AND tbwms_estoque.cod_fil  = acons.cod_fil
            AND tbwms_estoque.num_lote = acons.num_lote
            AND tbwms_estoque.sequencia_lote = acons.sequencia_lote
      INNER JOIN tTabelaComTexto ON
            tTabelaComTexto.Coluna01     = topo.cod_emp
            AND tTabelaComTexto.Coluna02 = topo.cod_fil
            AND tTabelaComTexto.Coluna03 = topo.ano_solic
            AND tTabelaComTexto.Coluna04 = topo.num_solic;
   ELSEIF oTiporetorno = 1 THEN
   
      # Retorno com 2 RecordSets
      # INFORMAÇÕES DO TOPO DA GSM
      SELECT tTabelaComTexto.Coluna05 AS DocEntry, tTabelaComTexto.Coluna06 AS Doctipo, 
            tbintegraSAP_Doc.TipoProducao, 
            topo.cod_emp, topo.cod_fil, topo.ano_solic, topo.num_solic, 
            topo.data_solic, topo.dthr_acons, topo.num_nf AS num_pedido,
            topo.observ_solic, topo.observ_conf01, topo.status_processo, 
            of_logistica.fnStatusSaidaWms(topo.status_processo) status_processoAux,
            #Liberação Inicio Processo de Separação, Picking
            topo.dthr_endereco, topo.dthr_confer, topo.dthr_confirm,
            #Inicio Processo de Separação, Picking
            topo.dthr_chegada, topo.final_descarga,
      # INFORMAÇÕES INTEGRAÇÃO
            tbintegraSAP_Doc.DocNum,
            tbintegraSAP_Doc.DocDate,
            tbintegraSAP_Doc.CardCode, tbintegraSAP_Doc.CardName, tbintegraSAP_DocItem.LineNum,
            #tbintegraSAP_Doc.ItemCode, 
            tbintegraSAP_DocItem.ItemCode, 
            tbintegraSAP_DocItem.WhareHouse,
            tbintegraSAP_Doc.Observacoes,
            "0" SERIAL,
            tbintegraSAP_Doc.StreetS,
            tbintegraSAP_Doc.AddrTypeS,
            tbintegraSAP_Doc.StreetNoS,
            tbintegraSAP_Doc.BlockS,
            tbintegraSAP_Doc.BuildingS,
            tbintegraSAP_Doc.CityS,
            tbintegraSAP_Doc.ZipCodeS,
            tbintegraSAP_Doc.StateS,
            tbintegraSAP_Doc.CountryS,
            "Employee" Employee,
      # INFORMAÇÕES DOS ITENS DA GSM
            ite.num_nf_vda AS num_ped_cli, ite.num_item, ite.cod_produto, descr_produto,
            ite.emb_est, ite.emb_frac, ite.emb_vol, ite.fator_conv,
            #
            ite.qtde_est, ite.qtde_vol, ite.qtde_frac, ite.pliq_item,		#Qtde Pedido
            ite.real_est, ite.real_vol, ite.real_frac, ite.real_peso,		#Qtde Aconselhada
            ite.real_est2, ite.real_vol2, ite.real_frac2, ite.real_peso2,	#Qtde Conferencia
            ite.real_est3, ite.real_vol3, ite.real_frac3, ite.real_peso3,	#Qtde Conferencia / ???
            #			
            ite.dthr_conf_ini, ite.dthr_conf_fin
            ,topo.chave_integracao
            ,prod.flg_obriga_lote_fornecedor
            ,RESULTADO, MENSAGEM
      FROM of_logistica.tbsolic_entradas topo
      INNER JOIN tTabelaComTexto ON
                tTabelaComTexto.Coluna01 = topo.cod_emp
            AND tTabelaComTexto.Coluna02 = topo.cod_fil
            AND tTabelaComTexto.Coluna03 = topo.ano_solic
            AND tTabelaComTexto.Coluna04 = topo.num_solic
      LEFT JOIN tbintegraSAP_Doc ON 
               tbintegraSAP_Doc.cod_emp   = topo.cod_emp
           AND tbintegraSAP_Doc.cod_fil   = topo.cod_fil
           AND tbintegraSAP_Doc.ano_solic = topo.ano_solic
           AND tbintegraSAP_Doc.num_solic = topo.num_solic
           AND tbintegraSAP_Doc.TipoDocSLIN = 'E'
      LEFT JOIN of_logistica.tbsolic_entradas_item ite ON
                ite.cod_emp = topo.cod_emp
            AND ite.cod_fil = topo.cod_fil
            AND ite.ano_solic = topo.ano_solic
            AND ite.num_solic = topo.num_solic
      INNER JOIN tbintegraSAP_DocItem ON 
                tbintegraSAP_DocItem.cod_emp   = ite.cod_emp
            AND tbintegraSAP_DocItem.cod_fil   = ite.cod_fil
            AND tbintegraSAP_DocItem.ano_solic = ite.ano_solic
            AND tbintegraSAP_DocItem.num_solic = ite.num_solic
            AND tbintegraSAP_DocItem.num_item  = ite.num_item
            AND tbintegraSAP_DocItem.DocTipo   =  tbintegraSAP_Doc.DocTipo
      LEFT JOIN of_logistica.tbprodutos prod ON
                prod.cnpj_cpf = ite.cnpj_cpf_dep
            AND prod.cod_produto = ite.cod_produto;
            
      # INFORMAÇÕES DAS UA´S DA GSM
      SELECT topo.cod_emp, topo.cod_fil, topo.ano_solic, topo.num_solic, 
            ite.num_nf_vda AS num_ped_cli, ite.num_item, ite.cod_produto, descr_produto,
            ite.emb_est, ite.emb_frac, ite.emb_vol, ite.fator_conv,
            #
            CONCAT(acons.num_lote,acons.sequencia_lote) AS NumUA,
            tbwms_estoque.num_lote_cli,
            acons.qtde_est, acons.qtde_vol, acons.qtde_frac, acons.qtde_peso,		#Qtde Aconselhada
            acons.qtde_est2, acons.qtde_vol2, acons.qtde_frac2, acons.qtde_peso2,	#Qtde Separada
            acons.qtde_est3, acons.qtde_vol3, acons.qtde_frac3, acons.qtde_peso3,	#(*) Qtde Conferencia/???
            #		
            acons.dthr_conf, acons.dthr_armaz,
            of_logistica.fnLocalizCompleta2(acons.cod_und, acons.cod_armazem, acons.camara, acons.rua, 
                                         acons.posicao, acons.altura, acons.profund, NULL, "Sem endereco") AS BinCode
            ,topo.chave_integracao
            ,RESULTADO, MENSAGEM
      FROM of_logistica.tbsolic_entradas topo
      LEFT JOIN of_logistica.tbsolic_entradas_item ite ON
                ite.cod_emp   = topo.cod_emp
            AND ite.cod_fil   = topo.cod_fil
            AND ite.ano_solic = topo.ano_solic
            AND ite.num_solic = topo.num_solic			
      LEFT JOIN of_logistica.tbprodutos prod ON
                prod.cnpj_cpf    = ite.cnpj_cpf_dep
            AND prod.cod_produto = ite.cod_produto
      LEFT JOIN of_logistica.tbsolic_entradas_acons acons ON
                acons.cod_emp   = ite.cod_emp
            AND acons.cod_fil   = ite.cod_fil
            AND acons.ano_solic = ite.ano_solic
            AND acons.num_solic = ite.num_solic			
            AND acons.num_item  = ite.num_item
      LEFT JOIN of_logistica.tbwms_estoque ON  
                tbwms_estoque.cod_emp        = acons.cod_emp
            AND tbwms_estoque.cod_fil        = acons.cod_fil
            AND tbwms_estoque.num_lote       = acons.num_lote
            AND tbwms_estoque.sequencia_lote = acons.sequencia_lote
      INNER JOIN tTabelaComTexto ON
            tTabelaComTexto.Coluna01 = topo.cod_emp
            AND tTabelaComTexto.Coluna02 = topo.cod_fil
            AND tTabelaComTexto.Coluna03 = topo.ano_solic
            AND tTabelaComTexto.Coluna04 = topo.num_solic;            
            
   END IF; 
   
   DROP TEMPORARY TABLE IF EXISTS tTabelaComTexto;
    
   IF excecao = 1 THEN
      ROLLBACK;
      SET RESULTADO = 0;
      SET MENSAGEM = CONCAT(xCodErro," - Erro SQL - Verifique com o Administrador");
      SELECT RESULTADO, MENSAGEM;
   ELSE    
      SET RESULTADO = 1;
      #SET MENSAGEM  = 'Processo Realizado com sucesso!';
   END IF;
   
END$$

DELIMITER ;