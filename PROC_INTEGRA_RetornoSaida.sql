DELIMITER $$

DROP PROCEDURE IF EXISTS `PROC_INTEGRA_RetornoSaida`$$

CREATE PROCEDURE `PROC_INTEGRA_RetornoSaida`(
   IN oCodUsuario				VARCHAR(10),
   IN oIdRetorno				 VARCHAR(20)
   #IN oTipoConsulta			INT     #0 = Apenas o Topo, 1 = Detalhe por ITEM, 2 = Detalhe por UA
   # Parametros de Retorno
   #OUT RESULTADO             	INT,
   #OUT MENSAGEM              	VARCHAR(500)
)
BLOCO1:BEGIN
   DECLARE xCodEmpWMS			     VARCHAR(03)	DEFAULT '001';
   DECLARE xCodFilWMS			     VARCHAR(03) DEFAULT '001';
   DECLARE xNumSolic 			     VARCHAR(10);
   DECLARE xAnoSolic 			     VARCHAR(04)	DEFAULT YEAR(CURRENT_DATE());
   DECLARE xDocEntry         INT;
   DECLARE xDocTipo          VARCHAR(10);   
   DECLARE xTipoOperSaida 		 VARCHAR(03) DEFAULT '002';
   DECLARE xCodUnidade			    VARCHAR(03) DEFAULT '001';
   DECLARE xCodArmazem			    VARCHAR(02) DEFAULT '01';
   DECLARE xStatusProcesso		 VARCHAR(02) DEFAULT '01';
   DECLARE xCodErro	         INT DEFAULT 0;
   DECLARE excecao 	         INT DEFAULT 0;
   DECLARE RESULTADO         INT DEFAULT 1;
   DECLARE MENSAGEM          VARCHAR(500);
   DECLARE xSTRGEM           TEXT;
   DECLARE xNumProcesso      VARCHAR(20);  
   #DECLARE CONTINUE HANDLER FOR SQLEXCEPTION SET excecao = 1;
    
   #Cria tabela temporária com as GSM que estão liberadas para retorno à integração
   DROP TEMPORARY TABLE IF EXISTS tbTMP_INTEGRA_RETORNO_SAIDAS;
   IF IFNULL(oIdRetorno,'') = '' THEN
   
      CREATE TEMPORARY TABLE tbTMP_INTEGRA_RETORNO_SAIDAS AS 
         SELECT DocEntry, DocTipo, DocNum, tbSaidas.num_nf, tbSaidas.data_nf, tbSaidas.data_solic
               ,CONCAT(tbSaidas.cod_emp, tbSaidas.cod_fil, tbSaidas.ano_solic, tbSaidas.num_solic) NumProcesso
               ,tbSaidas.cod_emp, tbSaidas.cod_fil, tbSaidas.ano_solic, tbSaidas.num_solic
               ,tbSaidas.status_processo, tbSaidas.observ_solic 
               #,CONCAT('CALL PROC_INTEGRA_RetornoSaida("999999","',CONCAT(tbSaidas.cod_emp, tbSaidas.cod_fil, tbSaidas.ano_solic, tbSaidas.num_solic),'");') _call
         FROM tbintegraSAP_Doc
         INNER JOIN of_logistica.tbsolic_saidas tbSaidas ON
               tbSaidas.cod_emp   = tbintegraSAP_Doc.cod_emp
           AND tbSaidas.cod_fil   = tbintegraSAP_Doc.cod_fil
           AND tbSaidas.ano_solic = tbintegraSAP_Doc.ano_solic
           AND tbSaidas.num_solic = tbintegraSAP_Doc.num_solic
           AND tbSaidas.status_processo >= 8
           AND tbintegraSAP_Doc.StatusDoc = 3
         WHERE tbintegraSAP_Doc.TipoDocSLIN = 'S';
   ELSE
   
      SET xCodEmpWMS	= SUBSTRING(oIdRetorno,01,03);
      SET xCodFilWMS	= SUBSTRING(oIdRetorno,04,03);
      SET xAnoSolic 	= SUBSTRING(oIdRetorno,07,04);
      SET xNumSolic 	= SUBSTRING(oIdRetorno,11,10);    
      SET xSTRGEM = CONCAT(xCodEmpWMS, "|", xCodFilWMS, "|", xAnoSolic, "|", xNumSolic, "|");
      #select xCodEmpWMS, xCodFilWMS, xAnoSolic, xNumSolic;
      /*******************************************************************
      # Validar a existencia da GSM
      *******************************************************************/
      IF NOT EXISTS (SELECT 1 FROM of_logistica.tbsolic_saidas 
                     WHERE cod_emp = xCodEmpWMS
                     AND cod_fil = xCodFilWMS
                     AND ano_solic = xAnoSolic
                     AND num_solic = xNumSolic) THEN
         SET xCodErro = 1;
         SET RESULTADO = 0;
         SET MENSAGEM  = 'GSM não localizada';
         SELECT RESULTADO, MENSAGEM;
         LEAVE BLOCO1;
      END IF;
      CREATE TEMPORARY TABLE tbTMP_INTEGRA_RETORNO_SAIDAS AS 
         SELECT DocEntry, DocTipo, DocNum, tbSaidas.num_nf, tbSaidas.data_nf, tbSaidas.data_solic
               ,CONCAT(tbSaidas.cod_emp, tbSaidas.cod_fil, tbSaidas.ano_solic, tbSaidas.num_solic) NumProcesso
               ,tbSaidas.cod_emp, tbSaidas.cod_fil, tbSaidas.ano_solic, tbSaidas.num_solic
               ,tbSaidas.status_processo, tbSaidas.observ_solic 
               #,CONCAT('CALL PROC_INTEGRA_RetornoSaida("999999","',CONCAT(tbSaidas.cod_emp, tbSaidas.cod_fil, tbSaidas.ano_solic, tbSaidas.num_solic),'");') _call
         FROM tbintegraSAP_Doc
         INNER JOIN of_logistica.tbsolic_saidas tbSaidas ON
               tbSaidas.cod_emp   = tbintegraSAP_Doc.cod_emp
           AND tbSaidas.cod_fil   = tbintegraSAP_Doc.cod_fil
           AND tbSaidas.ano_solic = tbintegraSAP_Doc.ano_solic
           AND tbSaidas.num_solic = tbintegraSAP_Doc.num_solic
           AND tbSaidas.status_processo >= 8
           AND tbintegraSAP_Doc.StatusDoc = 3
         WHERE tbintegraSAP_Doc.cod_emp   = xCodEmpWMS 
           AND tbintegraSAP_Doc.cod_fil   = xCodFilWMS
           AND tbintegraSAP_Doc.ano_solic = xAnoSolic
           AND tbintegraSAP_Doc.num_solic = xNumSolic
           AND tbintegraSAP_Doc.TipoDocSLIN = 'S';
   END IF;
   #Alimenta variavel xSTRGEM com a lista das GSM´s selecionadas
   SET xSTRGEM = '';  
   WHILE EXISTS (SELECT 1 FROM tbTMP_INTEGRA_RETORNO_SAIDAS) DO
      SELECT NumProcesso, cod_emp, cod_fil, ano_solic, num_solic, DocEntry, Doctipo
      INTO xNumProcesso, xCodEmpWMS, xCodFilWMS, xAnoSolic, xNumSolic, xDocEntry, xDoctipo
      FROM tbTMP_INTEGRA_RETORNO_SAIDAS LIMIT 1;         
      
      SET xSTRGEM = CONCAT(xSTRGEM, CONCAT(xCodEmpWMS, "|", xCodFilWMS, "|", xAnoSolic, "|", xNumSolic, "|", xDocEntry, "|"), xDocTipo, "|");
      DELETE FROM tbTMP_INTEGRA_RETORNO_SAIDAS WHERE NumProcesso = xNumProcesso;
   END WHILE;
   DROP TEMPORARY TABLE IF EXISTS tbTMP_INTEGRA_RETORNO_SAIDAS;
   #Cria tabela temporária auxiliar para inner join com a tbsolic_entradas para gerar seleção das informações
   #da GEM informada no parametro
   CALL PROC_SYS_GerarTabelaComTexto(xSTRGEM,'|',6);        
   
    
   /*******************************************************************
   # Selecionar as informações da GSM
   *******************************************************************/
   # INFORMAÇÕES DO TOPO DA GSM
   SELECT tTabelaComTexto.Coluna05 AS DocEntry, tTabelaComTexto.Coluna06 AS Doctipo, 
         topo.cod_emp, topo.cod_fil, topo.ano_solic, topo.num_solic, 
         topo.data_solic, topo.data_saida, topo.dthr_acons, topo.num_nf AS num_pedido,
         topo.observ_solic, topo.observ_conf01, topo.status_processo, 
         of_logistica.fnStatusSaidaWms(topo.status_processo) status_processoAux,
         #Liberação Inicio Processo de Separação, Picking
         topo.dthr_armazem, topo.dthr_armazem_picking, topo.dthr_confer, topo.dthr_confirm,
         #Inicio Processo de Separação, Picking
         topo.dthr_inicio_geral, topo.dthr_inicio_picking, topo.dthr_inicio_carregamento
         ,topo.chave_integracao
         ,RESULTADO, MENSAGEM
   FROM of_logistica.tbsolic_saidas topo
   INNER JOIN tTabelaComTexto ON
         tTabelaComTexto.Coluna01 = topo.cod_emp
         AND tTabelaComTexto.Coluna02 = topo.cod_fil
         AND tTabelaComTexto.Coluna03 = topo.ano_solic
         AND tTabelaComTexto.Coluna04 = topo.num_solic;
         
   # INFORMAÇÕES DOS ITENS DA GSM
   SELECT topo.cod_emp, topo.cod_fil, topo.ano_solic, topo.num_solic, 
         ite.num_ped_cli, ite.num_item, ite.cod_produto, descr_produto,
         ite.emb_est, ite.emb_frac, ite.emb_vol, ite.fator_conv,
         #
         ite.local_geral, ite.local_picking,
         ite.qtde_est, ite.qtde_vol, ite.qtde_frac, ite.pliq_item,		#Qtde Pedido
         ite.real_est, ite.real_vol, ite.real_frac, ite.real_peso,		#Qtde Aconselhada
         ite.real_est2, ite.real_vol2, ite.real_frac2, ite.real_peso2,	#Qtde Separação
         ite.real_est3, ite.real_vol3, ite.real_frac3, ite.real_peso3,	#Qtde Conferencia / Picking
         ite.real_est4, ite.real_vol4, ite.real_frac4, ite.real_peso4,	#Qtde Carregamento
         ite.real_est5, ite.real_vol5, ite.real_frac5, ite.real_peso5,	#Qtde check-carregamento
         #			
         ite.dthr_aconselhamento, ite.dthr_retorno_wms,
         ite.dthr_inicio_baixa_geral, ite.dthr_inicio_picking_carga, ite.dthr_inicio_carregamento,
         ite.dthr_final_baixa_geral, ite.dthr_final_picking_carga, ite.dthr_final_carregamento				
         ,topo.chave_integracao
         ,RESULTADO, MENSAGEM
   FROM of_logistica.tbsolic_saidas topo
   LEFT JOIN of_logistica.tbsolic_saidas_item ite ON
         ite.cod_emp = topo.cod_emp
         AND ite.cod_fil = topo.cod_fil
         AND ite.ano_solic = topo.ano_solic
         AND ite.num_solic = topo.num_solic
   LEFT JOIN of_logistica.tbprodutos prod ON
         prod.cnpj_cpf = ite.cnpj_cpf_dep
         AND prod.cod_produto = ite.cod_produto
   INNER JOIN tTabelaComTexto ON
             tTabelaComTexto.Coluna01 = topo.cod_emp
         AND tTabelaComTexto.Coluna02 = topo.cod_fil
         AND tTabelaComTexto.Coluna03 = topo.ano_solic
         AND tTabelaComTexto.Coluna04 = topo.num_solic;
    
   # INFORMAÇÕES DAS UA´S DA GSM
   # Checa se envia Lotes da UA ou da tbsolic_saidas_item_loteAux
   # @Reviser David Ruy <2020-11-18>
   IF TRUE THEN
      SELECT topo.cod_emp, topo.cod_fil, topo.ano_solic, topo.num_solic, 
         ite.num_ped_cli, ite.num_item, ite.cod_produto, descr_produto,
         ite.emb_est, ite.emb_frac, ite.emb_vol, ite.fator_conv,
         #
         CONCAT(acons.num_lote,acons.sequencia_lote) AS NumUA,
         IFNULL(tbLoteAux.num_lote, tbwms_estoque.num_lote_cli) num_lote_cli,
         SUM(acons.qtde_est) qtde_est, SUM(acons.qtde_vol) qtde_vol, SUM(acons.qtde_frac) qtde_frac, SUM(acons.qtde_peso) qtde_peso,		#Qtde Aconselhada
         IF(tbLoteAux.num_lote IS NULL, SUM(acons.qtde_est2), tbLoteAux.qtde_est) qtde_est2, 
         IF(tbLoteAux.num_lote IS NULL, SUM(acons.qtde_vol2), tbLoteAux.qtde_vol) qtde_vol2, 
         IF(tbLoteAux.num_lote IS NULL, SUM(acons.qtde_frac2), tbLoteAux.qtde_frac) qtde_frac2, 
         IF(tbLoteAux.num_lote IS NULL, SUM(acons.qtde_peso2), tbLoteAux.qtde_peso) qtde_peso2,	#Qtde Separada
         SUM(acons.qtde_est3) qtde_est3, SUM(acons.qtde_vol3) qtde_vol3, SUM(acons.qtde_frac3) qtde_frac3, SUM(acons.qtde_peso3) qtde_peso3,	#(*) Qtde Conferencia/Picking Carga
         #		
         acons.dthr_conf, acons.dthr_conf_picking, acons.dthr_carregamento
         ,topo.chave_integracao
         ,RESULTADO, MENSAGEM
      FROM of_logistica.tbsolic_saidas topo
      LEFT JOIN of_logistica.tbsolic_saidas_item ite ON
            ite.cod_emp = topo.cod_emp
            AND ite.cod_fil = topo.cod_fil
            AND ite.ano_solic = topo.ano_solic
            AND ite.num_solic = topo.num_solic			
      LEFT JOIN of_logistica.tbprodutos prod ON
            prod.cnpj_cpf = ite.cnpj_cpf_dep
            AND prod.cod_produto = ite.cod_produto
      LEFT JOIN of_logistica.tbsolic_saidas_acons acons ON
            acons.cod_emp = ite.cod_emp
            AND acons.cod_fil = ite.cod_fil
            AND acons.ano_solic = ite.ano_solic
            AND acons.num_solic = ite.num_solic			
            AND acons.num_item  = ite.num_item
      LEFT JOIN of_logistica.tbwms_estoque ON  
            tbwms_estoque.cod_emp = acons.cod_emp
            AND tbwms_estoque.cod_fil = acons.cod_fil
            AND tbwms_estoque.num_lote = acons.num_lote
            AND tbwms_estoque.sequencia_lote = acons.sequencia_lote
      LEFT JOIN of_logistica.tbsolic_saidas_item_loteAux tbLoteAux ON
                 tbLoteAux.cod_emp   = acons.cod_emp
             AND tbLoteAux.cod_fil   = acons.cod_fil
             AND tbLoteAux.ano_solic = acons.ano_solic
             AND tbLoteAux.num_solic = acons.num_solic
             AND tbLoteAux.num_item  = acons.num_item
      INNER JOIN tTabelaComTexto ON
            tTabelaComTexto.Coluna01 = topo.cod_emp
            AND tTabelaComTexto.Coluna02 = topo.cod_fil
            AND tTabelaComTexto.Coluna03 = topo.ano_solic
            AND tTabelaComTexto.Coluna04 = topo.num_solic
      GROUP BY cod_emp, cod_fil, ano_solic, num_solic, num_ped_cli, num_item, num_lote_cli;
   ELSE   
      #Rotina desativada em 18/11/2020
      SELECT topo.cod_emp, topo.cod_fil, topo.ano_solic, topo.num_solic, 
         ite.num_ped_cli, ite.num_item, ite.cod_produto, descr_produto,
         ite.emb_est, ite.emb_frac, ite.emb_vol, ite.fator_conv,
         #
         CONCAT(acons.num_lote,acons.sequencia_lote) AS NumUA,
         tbwms_estoque.num_lote_cli,
         acons.qtde_est, acons.qtde_vol, acons.qtde_frac, acons.qtde_peso,		#Qtde Aconselhada
         acons.qtde_est2, acons.qtde_vol2, acons.qtde_frac2, acons.qtde_peso2,	#Qtde Separada
         acons.qtde_est3, acons.qtde_vol3, acons.qtde_frac3, acons.qtde_peso3,	#(*) Qtde Conferencia/Picking Carga
         #		
         acons.dthr_conf, acons.dthr_conf_picking, acons.dthr_carregamento
         ,topo.chave_integracao
         ,RESULTADO, MENSAGEM
      FROM of_logistica.tbsolic_saidas topo
      LEFT JOIN of_logistica.tbsolic_saidas_item ite ON
            ite.cod_emp = topo.cod_emp
            AND ite.cod_fil = topo.cod_fil
            AND ite.ano_solic = topo.ano_solic
            AND ite.num_solic = topo.num_solic			
      LEFT JOIN of_logistica.tbprodutos prod ON
            prod.cnpj_cpf = ite.cnpj_cpf_dep
            AND prod.cod_produto = ite.cod_produto
      LEFT JOIN of_logistica.tbsolic_saidas_acons acons ON
            acons.cod_emp = ite.cod_emp
            AND acons.cod_fil = ite.cod_fil
            AND acons.ano_solic = ite.ano_solic
            AND acons.num_solic = ite.num_solic			
            AND acons.num_item  = ite.num_item
      LEFT JOIN of_logistica.tbwms_estoque ON  
            tbwms_estoque.cod_emp = acons.cod_emp
            AND tbwms_estoque.cod_fil = acons.cod_fil
            AND tbwms_estoque.num_lote = acons.num_lote
            AND tbwms_estoque.sequencia_lote = acons.sequencia_lote
      INNER JOIN tTabelaComTexto ON
            tTabelaComTexto.Coluna01 = topo.cod_emp
            AND tTabelaComTexto.Coluna02 = topo.cod_fil
            AND tTabelaComTexto.Coluna03 = topo.ano_solic
            AND tTabelaComTexto.Coluna04 = topo.num_solic;
   END IF;
    
   DROP TEMPORARY TABLE IF EXISTS tTabelaComTexto;
    
   IF excecao = 1 THEN
      SET RESULTADO = 0;
      SET MENSAGEM = CONCAT(xCodErro," - Erro SQL - Verifique com o Administrador");
      SELECT RESULTADO, MENSAGEM;
   ELSE    
      SET RESULTADO = 1;
      #SET MENSAGEM  = 'Processo Realizado com sucesso!';
   END IF;
   
END$$

DELIMITER ;