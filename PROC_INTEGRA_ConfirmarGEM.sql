DELIMITER $$

DROP PROCEDURE IF EXISTS `PROC_INTEGRA_ConfirmarGEM`$$

CREATE PROCEDURE `PROC_INTEGRA_ConfirmarGEM`(
#   oChaveIntegracao    varchar(30),
#   oDocTipo            VARCHAR(30),
#   oDocEntry           VARCHAR(30),
   # Parametros de Retorno
   OUT RESULTADO              INT,
   OUT MENSAGEM               VARCHAR(500)
)
BLOCO1:BEGIN
  /************************************************************************/
  # @Created David Ruy <2024/06/16>
  # Esta procedure atualiza uma GEM com informações de recebimento de produção do SAP
  # Gera a conferencia e confirmação no SLIN-WMS
  # @Reviser David Ruy <2025-10-29> Ajuste parametro PROC_WMS_DESCARGA_ATUALIZAR_CONFERENCIA_ITEM_DESCARGA
  # @Reviser David Ruy <2025-11-28> Ajuste para pegar a primeira sequencia de etiqueta por PA/ItemCode
  /************************************************************************/
   DECLARE excecao 	INT(6) DEFAULT 0;
   DECLARE _RESULTADO INT DEFAULT 0;
   DECLARE _MENSAGEM  VARCHAR(500);
   DECLARE xCodEmp        VARCHAR(03);
   DECLARE xCodFil        VARCHAR(03);
   DECLARE xAnoSolic      VARCHAR(04);
   DECLARE xNumSolic      VARCHAR(10);
   DECLARE xNumItem       VARCHAR(06);
   DECLARE xItemCode      VARCHAR(30);
   
   DECLARE xDocTipo       VARCHAR(10);
   DECLARE xDocEntry      VARCHAR(30);
   DECLARE xDocNum        VARCHAR(30);
   DECLARE xChaveIntegracao VARCHAR(100);
   
   DECLARE xLoteFabricacao VARCHAR(30);
   DECLARE xDataFabricacao VARCHAR(30);
   DECLARE xDataValidade   VARCHAR(30);
   
   DECLARE xQtdeEstItem   DECIMAL(18,6);
   DECLARE xQtdeVolItem   DECIMAL(18,6);
   DECLARE xQtdeFracItem  DECIMAL(18,6);
   DECLARE xQtdePesoItem  DECIMAL(18,6);
   DECLARE xFatorConv     DECIMAL(18,6);
   DECLARE xNumeroUA      VARCHAR(10);
   DECLARE xSequenciaUA   INT(3);
   DECLARE xQtdeEstUA     DECIMAL(18,6);
   DECLARE xQtdeVolUA     DECIMAL(18,6);
   DECLARE xQtdeFracUA    DECIMAL(18,6);
   DECLARE xQtdePesoUA    DECIMAL(18,6);
   
   DECLARE xInicioSequencia INT(6);
   DECLARE xDocTipoAux      VARCHAR(30);
   DECLARE xVersaoPA        INT(6);
   DECLARE xStringEtqAux    VARCHAR(100);
   DECLARE xStringEtq       VARCHAR(100);
   DECLARE xCampoQtdeStr    VARCHAR(10);

   #Verificar se tem transação nas procedures
   #Se tiver, lascou
   DECLARE EXIT HANDLER FOR SQLEXCEPTION
   BEGIN
       GET DIAGNOSTICS CONDITION 1 MENSAGEM = MESSAGE_TEXT;
       SET excecao   = 1;
       SET RESULTADO = 0;
       IF xCodEmp IS NOT NULL THEN
          SET MENSAGEM  = of_logistica.fnMensagemExcecao(
             CONCAT('ERRO Conferencia - GEM : ',CAST(xCodEmp AS UNSIGNED),'/',CAST(xCodFil AS UNSIGNED),'-',
             CAST(xNumSolic AS UNSIGNED),'.',xAnoSolic," ",xChaveIntegracao," ",MENSAGEM) );
       ELSE
          SET MENSAGEM  = of_logistica.fnMensagemExcecao(
             CONCAT('ERRO Conferencia : ',MENSAGEM) );
       END IF;
       SELECT MENSAGEM;
       ROLLBACK;
   END;  
   
  
   DROP TEMPORARY TABLE IF EXISTS tbTMPGEM_ACONFIRMAR;
   CREATE TEMPORARY TABLE tbTMPGEM_ACONFIRMAR
      SELECT tbintegraSAP_Doc.DocEntry, tbintegraSAP_Doc.DocTipo, tbintegraSAP_Doc.DocNum, tbintegraSAP_Doc.chave_integracao, 
             tbintegraSAP_Doc.ItemCode, tbintegraSAP_Doc.cod_emp, tbintegraSAP_Doc.cod_fil, tbintegraSAP_Doc.ano_solic, 
             tbintegraSAP_Doc.num_solic, 
             CAST(0 AS SIGNED) flgProcessado
      FROM tbintegraSAP_Doc
      INNER JOIN of_logistica.tbsolic_entradas ON
                 tbintegraSAP_Doc.chave_integracao = tbsolic_entradas.chave_integracao
      WHERE tbintegraSAP_Doc.DocTipo LIKE 'PA%'
        #Habilitar esta linha apenas para testes
        #and tbintegraSAP_Doc.DocEntry = 8 and tbintegraSAP_Doc.DocTipo = 'PA012'
        AND tbintegraSAP_Doc.StatusDoc = 3
        AND tbsolic_entradas.dthr_confirm IS NULL
      ORDER BY cod_emp, cod_fil, ano_solic, num_solic; #      limit 1;
      
      #select * from tbTMPGEM_ACONFIRMAR;
      #leave bloco1;
        
   SET MENSAGEM = "";
   SET RESULTADO = 1;
   IF NOT EXISTS (SELECT 1 FROM tbTMPGEM_ACONFIRMAR) THEN 
      SET MENSAGEM = "NÃO EXISTEM REGISTROS PARA PROCESSAR";
   END IF;
   
   
   WHILE EXISTS (SELECT 1 FROM tbTMPGEM_ACONFIRMAR WHERE flgProcessado = 0) DO
      START TRANSACTION;
   
     
      SELECT DocEntry, DocTipo, DocNum, chave_integracao, cod_emp, cod_fil, ano_solic, num_solic
      INTO xDocEntry, xDocTipo, xDocNum, xChaveIntegracao, xCodEmp, xCodFil, xAnoSolic, xNumSolic
      FROM tbTMPGEM_ACONFIRMAR WHERE flgProcessado = 0
      LIMIT 1;
   
      /***********************************************************************/
      #Buscar Informações da Ordem de Produção
      /***********************************************************************/
      SELECT ItemCode, BatchNumbersCode, DATE_FORMAT(DataFabricacao,'%Y-%m-%d'), DATE_FORMAT(DataValidade,'%Y-%m-%d')
      INTO xItemCode, xLoteFabricacao, xDataFabricacao, xDataValidade
      FROM tbintegraSAP_DocItem
      WHERE tbintegraSAP_DocItem.DocTipo  = xDocTipo
        AND tbintegraSAP_DocItem.DocEntry = xDocEntry
      LIMIT 1;
      
      
      /***********************************************************************/
      #Buscar Numero do início da Sequencia dos pallets por PA/ItemCode
      /***********************************************************************/
      SET xStringEtq = NULL;
      SELECT tbsolic_entradas_acons.num_caixa_barcode AS xStringEtq, DocTipo DocTipoAnt
      INTO xStringEtq, xDocTipoAux
      FROM tbintegraSAP_Doc
      INNER JOIN of_logistica.tbsolic_entradas_acons ON 
                    tbintegraSAP_Doc.cod_emp   = tbsolic_entradas_acons.cod_emp
                AND tbintegraSAP_Doc.cod_fil   = tbsolic_entradas_acons.cod_fil
                AND tbintegraSAP_Doc.ano_solic = tbsolic_entradas_acons.ano_solic
                AND tbintegraSAP_Doc.num_solic = tbsolic_entradas_acons.num_solic
      WHERE tbintegraSAP_Doc.DocTipo LIKE 'PA%'   #= xDocTipo
        AND tbintegraSAP_Doc.DocEntry = xDocEntry
        AND tbintegraSAP_Doc.ItemCode = xItemCode
        AND tbsolic_entradas_acons.num_caixa_barcode IS NOT NULL
      ORDER BY num_lote DESC LIMIT 1;
           
      IF xStringEtq IS NULL THEN
         SET xInicioSequencia = 0;
      ELSE
      
         #OrdemProducao.CodigoProduto.NumeroLote.DataFabricacao.DataValidade.Quantidade.NumeroSequencia
         #Exemplo: 494.1325001.494.0424.0824.40.1
         #Alteração no padrão da Etiqueta em 2024-06-20 (Sequencia Reinicia a cada Item)
         #OrdemProducao.DataFabricacao.DataValidade.Quantidade.CodigoProduto_NumeroLote_NumeroSequencia
         #Exemplo: 494.0424.0824.40.1325001_494_1
         SET xInicioSequencia = CAST(SUBSTRING_INDEX(xStringEtq, '-', -1) AS UNSIGNED);
      END IF;
      
      #Habilitar somente para testes
      #SELECT xDocTipo, xDocTipoAux, xInicioSequencia, xStringEtq, xItemCode;
      #LEAVE bloco1;
      
      /***********************************************************************/
      #Tabela Temporária de Itens da GEM
      /***********************************************************************/
      DROP TEMPORARY TABLE IF EXISTS tbTMPItens;
      CREATE TEMPORARY TABLE tbTMPItens
         SELECT tbsolic_entradas_item.cod_emp, tbsolic_entradas_item.cod_fil, tbsolic_entradas_item.ano_solic, 
                tbsolic_entradas_item.num_solic, tbsolic_entradas_item.num_item, tbsolic_entradas_item.cod_produto,
                tbsolic_entradas_item.qtde_est QtdeEst, tbsolic_entradas_item.qtde_vol QtdeVol, 
                tbsolic_entradas_item.qtde_frac QtdeFrac, tbsolic_entradas_item.pliq_item QtdePeso, 
                tbsolic_entradas_item.fator_conv FatorConv, 
                CAST(0 AS UNSIGNED) flgProcessado
         FROM of_logistica.tbsolic_entradas_item
         INNER JOIN tbintegraSAP_Doc ON
                    tbintegraSAP_Doc.cod_emp   = tbsolic_entradas_item.cod_emp
                AND tbintegraSAP_Doc.cod_fil   = tbsolic_entradas_item.cod_fil
                AND tbintegraSAP_Doc.ano_solic = tbsolic_entradas_item.ano_solic
                AND tbintegraSAP_Doc.num_solic= tbsolic_entradas_item.num_solic
         WHERE chave_integracao = xChaveIntegracao;
         
         
      /***********************************************************************/
      #Tabela Temporária de Aconselhamenro da GEM
      /***********************************************************************/
      DROP TEMPORARY TABLE IF EXISTS tbTMPAcons;
      CREATE TEMPORARY TABLE tbTMPAcons
         SELECT tbsolic_entradas_acons.cod_emp, tbsolic_entradas_acons.cod_fil, tbsolic_entradas_acons.ano_solic, 
                tbsolic_entradas_acons.num_solic, tbsolic_entradas_acons.num_item, 
                tbsolic_entradas_acons.num_lote, tbsolic_entradas_acons.sequencia_lote,
                tbsolic_entradas_acons.qtde_est QtdeEst, tbsolic_entradas_acons.qtde_vol QtdeVol, 
                tbsolic_entradas_acons.qtde_frac QtdeFrac, tbsolic_entradas_acons.qtde_peso QtdePeso,
                CAST(0 AS UNSIGNED) flgProcessado
         FROM of_logistica.tbsolic_entradas_acons
         INNER JOIN tbintegraSAP_Doc ON
                    tbintegraSAP_Doc.cod_emp   = tbsolic_entradas_acons.cod_emp
                AND tbintegraSAP_Doc.cod_fil   = tbsolic_entradas_acons.cod_fil
                AND tbintegraSAP_Doc.ano_solic = tbsolic_entradas_acons.ano_solic
                AND tbintegraSAP_Doc.num_solic = tbsolic_entradas_acons.num_solic
         WHERE chave_integracao = xChaveIntegracao;
         
      #select xInicioSequencia;
      #select * from tbTMPItens;
      #SELECT * FROM tbTMPAcons;
      #leave bloco1;
      #Loop dos Itens
      
      WHILE EXISTS (SELECT 1 FROM tbTMPItens WHERE flgProcessado = 0) DO
         SELECT cod_emp, cod_fil, ano_solic, num_solic, num_item, cod_produto, 
                QtdeEst, QtdeVol, QtdeFrac, QtdePeso, FatorConv
         INTO xCodEmp, xCodFil, xAnoSolic, xNumSolic, xNumItem, xItemCode, 
              xQtdeEstItem, xQtdeVolItem, xQtdeFracItem, xQtdePesoItem, xFatorConv
         FROM tbTMPItens
         WHERE flgProcessado = 0
         LIMIT 1;
         
         #Loop das UA´s
         WHILE EXISTS (SELECT 1 FROM tbTMPAcons WHERE num_item = xNumItem AND flgProcessado = 0) DO
            SELECT num_lote, sequencia_lote, QtdeEst, QtdeVol, QtdeFrac, QtdePeso
            INTO xNumeroUA, xSequenciaUA, xQtdeEstUA, xQtdeVolUA, xQtdeFracUA, xQtdePesoUA
            FROM tbTMPAcons
            WHERE flgProcessado = 0
            LIMIT 1;
            
            #Monta String ETIQUETA PALLET
            SET xInicioSequencia = xInicioSequencia + 1;
            #OrdemProducao.DataFabricacao.DataValidade.Quantidade.CodigoProduto-NumeroLote-NumeroSequencia
            #Exemplo: 494.0424.0824.40.1325001-494-1
            SET xStringEtq =  CONCAT(xDocNum, '.', DATE_FORMAT(xDataFabricacao,'%m%y'), '.', 
                                     DATE_FORMAT(xDataValidade,'%m%y'), '.', CAST(xQtdeEstUA AS UNSIGNED), '.', 
                                     xItemCode, '-', xLoteFabricacao, '-', xInicioSequencia );
            #Habilitar esta linha apenas para testes, checar string etiqueta
            #select xStringEtq ;
            #leave bloco1;
            
            /****************************************************************/
            #CONFERÊNCIA DA UA
            /****************************************************************/		
            CALL of_logistica.PROC_WMS_DESCARGA_ATUALIZAR_CONFERENCIA_ITEM_DESCARGA(	0
                                                                        , CAST(xCodEmp   AS SIGNED)
                                                                        , CAST(xCodFil   AS SIGNED)
                                                                        , CAST(xAnoSolic AS SIGNED)
                                                                        , CAST(xNumSolic AS SIGNED)
                                                                        , 1
                                                                        , CAST(xNumItem  AS SIGNED)
                                                                        , CAST(xNumeroUA AS SIGNED)
                                                                        , NULL
                                                                        , 1
                                                                        , xDataFabricacao
                                                                        , xDataValidade
                                                                        , xLoteFabricacao  #MÁXIMO DE 30! 
                                                                        , xQtdeVolUA
                                                                        , xQtdePesoUA
                                                                        , 0
                                                                        , 0
                                                                        , 999999
                                                                        , 0
                                                                        , NULL
                                                                        , 0
                                                                        , 0
                                                                        , 0
                                                                        , 0
                                                                        , 0
                                                                        , 0
                                                                        , 0
                                                                        , 0
                                                                        , NULL
                                                                        , xStringEtq #MÁXIMO DE 50
                                                                        , _RESULTADO #OUT
                                                                        , _MENSAGEM  #OUT 
                                                                        );
                                                                        
            #select "PROC_WMS_DESCARGA_ATUALIZAR_CONFERENCIA_ITEM_DESCARGA", _RESULTADO, _MENSAGEM;
            #leave BLOCO1;
            IF _RESULTADO = 0 THEN
               #Erro Provocar exceção e parar processamento
               SET RESULTADO = _RESULTADO;
               SET MENSAGEM  = _MENSAGEM;
            END IF;
            
            UPDATE tbTMPAcons
            SET flgProcessado = 1
            WHERE cod_emp   = xCodEmp
              AND cod_fil   = xCodFil
              AND ano_solic = xAnoSolic
              AND num_solic = xNumSolic
              AND num_lote  = xNumeroUA
              AND sequencia_lote = xSequenciaUA;
         END WHILE; 
         
         
         /****************************************************************/
         #FINALIZAR CONFERENCIA ITEM
         /****************************************************************/		
         CALL of_logistica.PROC_WMS_DESCARGA_ATUALIZAR_CONFERENCIA_ITEM_FINAL( 1
                                                               , NULL
                                                               , '999999'
                                                               , xCodEmp
                                                               , xCodFil
                                                               , xAnoSolic
                                                               , xNumSolic
                                                               , xNumItem
                                                               , 1
                                                               , NULL
                                                               , _RESULTADO #OUT
                                                               , _MENSAGEM  #OUT
                                                               ); 
      
         #select "PROC_WMS_DESCARGA_ATUALIZAR_CONFERENCIA_ITEM_FINAL", _RESULTADO, _MENSAGEM;
         #leave BLOCO1;        
         IF _RESULTADO = 0 THEN
            #Erro Provocar exceção e parar processamento
            SET RESULTADO = _RESULTADO;
            SET MENSAGEM  = _MENSAGEM;
         END IF;
         
         
         
         
         /****************************************************************/
         /****************ACONSELHAMENTO DE ENDEREÇO CONFORME PARAMETRIZACAO
         /****************************************************************/		
         IF EXISTS( SELECT 1 
                      FROM of_logistica.tbsolic_entradas
                           INNER JOIN of_logistica.tbwms_estoque_cli  ON tbwms_estoque_cli.cod_emp      = tbsolic_entradas.cod_emp
                                                        AND tbwms_estoque_cli.cod_fil      = tbsolic_entradas.cod_fil
                                                        AND tbwms_estoque_cli.cnpj_cpf_cli = tbsolic_entradas.cnpj_cpf_cli
                                                        AND tbwms_estoque_cli.cod_estoque  = tbsolic_entradas.cod_estoque
                           INNER JOIN of_logistica.tbwms_tipo_oper    ON tbwms_tipo_oper.cod_oper_wms   = tbsolic_entradas.flg_tipo_oper
                     WHERE tbsolic_entradas.cod_emp                      = xCodEmp
                       AND tbsolic_entradas.cod_fil                      = xCodFil
                       AND tbsolic_entradas.ano_solic                    = xAnoSolic
                       AND tbsolic_entradas.num_solic                    = xNumSolic
                       AND tbwms_estoque_cli.flg_aconselhamento_endereco = 1
                       AND tbwms_tipo_oper.flg_aconselhamento_endereco   = 1 
                  ) THEN 
         BEGIN 
              
            #looping por tbsolic_entradas_item
            CALL of_logistica.PROC_WMS_DESCARGA_GERAR_ACONSELHAMENTO_ENDERECO( '999999'
                                                                , CAST(xCodEmp  AS SIGNED)
                                                                , CAST(xCodFil   AS SIGNED)
                                                                , CAST(xAnoSolic    AS SIGNED)
                                                                , CAST(xNumSolic AS SIGNED)
                                                                , CAST(xNumItem     AS SIGNED)
                                                                , _RESULTADO #OUT
                                                                , _MENSAGEM  #OUT 
                                                                );
            #select "PROC_WMS_DESCARGA_GERAR_ACONSELHAMENTO_ENDERECO", _RESULTADO, _MENSAGEM;
            #leave BLOCO1;        
            IF _RESULTADO = 0 THEN
               #Erro Provocar exceção e parar processamento
               SET RESULTADO = _RESULTADO;
               SET MENSAGEM  = _MENSAGEM;
            END IF;
         END; 
         END IF;
         
         
         UPDATE tbTMPItens
         SET flgProcessado = 1
         WHERE cod_emp   = xCodEmp
           AND cod_fil   = xCodFil
           AND ano_solic = xAnoSolic
           AND num_solic = xNumSolic
           AND num_item  = xNumItem;
         
      END WHILE;
      /****************************************************************/
      /****************ATUALIZAR TOPO DA GUIA 
      /****************************************************************/		
      UPDATE of_logistica.tbsolic_entradas 
         SET tbsolic_entradas.final_descarga  = NOW()
           , tbsolic_entradas.status_processo = IF(tbsolic_entradas.status_processo > 7, tbsolic_entradas.status_processo, 7) 
      WHERE tbsolic_entradas.cod_emp   = xCodEmp
        AND tbsolic_entradas.cod_fil   = xCodFil
        AND tbsolic_entradas.ano_solic = xAnoSolic
        AND tbsolic_entradas.num_solic = xNumSolic;
          
          
      /****************************************************************/
      /**************** CONFIRMAÇÃO AUTOMATICA
      /****************************************************************/	   
      CALL of_logistica.PROC_WMS_DESCARGA_ATUALIZAR_CONFIRMACAO_AUTOMATICA( 1
                                                             , xCodEmp
                                                             , xCodFil
                                                             , xAnoSolic
                                                             , xNumSolic
                                                             , '999999'
                                                             ); 
      /****************************************************************/
      /**************** Atualiza STATUS DOCUMENTO NA INTEGRAÇÃO
      /****************************************************************/	   
      CALL PROC_INTEGRA_AtualizarStatusDocEntry('999999', xDocEntry, xDocTipo, xDocNum, 6, _RESULTADO, _MENSAGEM);
      
      
      DROP TEMPORARY TABLE IF EXISTS tbTMPItens;
      DROP TEMPORARY TABLE IF EXISTS tbTMPAcons;
      
      UPDATE tbTMPGEM_ACONFIRMAR
      SET flgProcessado = 1
      WHERE chave_integracao = xChaveIntegracao;
      
      
      IF excecao = 0 THEN
         COMMIT;
         SET RESULTADO = 1;
         IF MENSAGEM = "" THEN
            SET MENSAGEM = CONCAT('Conferencia Concluída com sucesso - GEM : ',CAST(xCodEmp AS UNSIGNED),'/',CAST(xCodFil AS UNSIGNED),'-',CAST(xNumSolic AS UNSIGNED),'.',xAnoSolic," ",xChaveIntegracao);
         ELSE
            SET MENSAGEM = CONCAT(MENSAGEM," | ",CAST(xCodEmp AS UNSIGNED),'/',CAST(xCodFil AS UNSIGNED),'-',CAST(xNumSolic AS UNSIGNED),'.',xAnoSolic," ",xChaveIntegracao);
         END IF;
      ELSE
         ROLLBACK;
         
         SET RESULTADO = 0;
         SET MENSAGEM = CONCAT('ERRO Conferencia - GEM : ',CAST(xCodEmp AS UNSIGNED),'/',CAST(xCodFil AS UNSIGNED),'-',CAST(xNumSolic AS UNSIGNED),'.',xAnoSolic," ",xChaveIntegracao);
         
         #Verificar Log
         #CALL PROC_INTEGRA_EnviarLog('999999',
         #       IF(oChavePedido IN ("PV","OP","TD-S","NS"), 'PROC_INTEGRA_GerarGSMItem', 'PROC_INTEGRA_GerarGEMItem'),
         #         CONCAT('NÃO Inserido/Atualizado ',oChavePedido,oDocEntry,'-',oNumPedido,' | ', xRefGuia, '| Prd:', xItemCode), "200", @M, @R, @M);      
      END IF;
      
      
      
   END WHILE;
   
   
END$$

DELIMITER ;