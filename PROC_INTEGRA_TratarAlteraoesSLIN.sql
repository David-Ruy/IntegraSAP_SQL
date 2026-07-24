DELIMITER $$

DROP PROCEDURE IF EXISTS `PROC_INTEGRA_TratarAlteraoesSLIN`$$

CREATE PROCEDURE `PROC_INTEGRA_TratarAlteraoesSLIN`(
   # Parametros de Retorno
   #OUT RESULTADO      INT,
   #OUT MENSAGEM       VARCHAR(500)
)
BLOCO1:BEGIN
   DECLARE RESULTADO                INT;
   DECLARE MENSAGEM                 VARCHAR(500);
   DECLARE xCodUsuario              VARCHAR(06) DEFAULT "999999";
   DECLARE xDocEntry                INT;
   DECLARE xDocNum                  INT;
   DECLARE xDocTipo                 VARCHAR(10);
   DECLARE xUniqueKey               VARCHAR(30);
   DECLARE xUpdateDate              VARCHAR(30);
   DECLARE xDthrInc                 VARCHAR(20);
   DECLARE xDocumentDate            VARCHAR(20);
   DECLARE xCodEmpWMS			            VARCHAR(03);
   DECLARE xCodFilWMS			            VARCHAR(03);
   DECLARE xAnoSolic 			            VARCHAR(04);
   DECLARE xNumSolic 			            VARCHAR(10);
   DECLARE xNumItem                 VARCHAR(06);
   DECLARE xNumPedido               VARCHAR(20);
   DECLARE xQtdeVol                 DECIMAL(18,6);
   DECLARE xQtdeFrac                DECIMAL(18,6);
   DECLARE xQtdeEst                 DECIMAL(18,6);
   DECLARE xQtdePeso                DECIMAL(18,6);
   DECLARE xdthr_aconselhamento     VARCHAR(20);
   DECLARE xdthr_inicio_separacao   VARCHAR(20);
   DECLARE xdthr_final_separacao    VARCHAR(20);
   DECLARE xQtdeRegs                INT DEFAULT 0;
   DECLARE xTipoUpdCanc             VARCHAR(01);
   
   DECLARE xEmbVendas         VARCHAR(10);
   DECLARE excecao 	INT DEFAULT 0;
   
   DECLARE EXIT HANDLER FOR SQLEXCEPTION
   BEGIN
       GET DIAGNOSTICS CONDITION 1 MENSAGEM = MESSAGE_TEXT;
       SET excecao   = 1;
       SET RESULTADO = 0;
       SET MENSAGEM  = of_logistica.fnMensagemExcecao(MENSAGEM);
       ROLLBACK;
   END;
   
   START TRANSACTION;
   
   
   DROP TEMPORARY TABLE IF EXISTS TMP_AlteracoesSLIN;
   CREATE TEMPORARY TABLE TMP_AlteracoesSLIN ( 
      SELECT tbUpdCancPV.TipoUpdCanc,tbUpdCancPV.UniqueKey, tbUpdCancPV.DocumentType, 
             tbUpdCancPV.DocumentId, tbUpdCancPV.DocumentNumber,
             tbUpdCancPV.DocumentDate, tbUpdCancPV.LineNumber, tbUpdCancPV.UpdateDate,
             tbUpdCancPV.QtdeEstoque Quantity, tbUpdCancPV.SalUnitMsr,
             tbAlteracao.cod_emp, tbAlteracao.cod_fil, tbAlteracao.ano_solic, tbAlteracao.num_solic, tbAlteracao.num_item,
             tbAlteracao.dthr_inc,
             tbAlteracao.qtde_est_ant, tbAlteracao.qtde_frac_ant, tbAlteracao.qtde_vol_ant, tbAlteracao.qtde_peso_ant,
             tbAlteracao.qtde_est_atu, tbAlteracao.qtde_frac_atu, tbAlteracao.qtde_vol_atu, tbAlteracao.qtde_peso_atu,
             item.dthr_aconselhamento AS dthr_aconselhamento, 
             item.dthr_inicio_baixa_geral AS dthr_inicio_separacao, 
             item.dthr_final_baixa_geral AS dthr_final_separacao,
             0 AS FlgProcessado,
             0 AS FlgAconselhar
      FROM tbintegraSAP_UpdCancPV tbUpdCancPV 
      INNER JOIN of_logistica.tbsolic_saidas_item_integra_alteracao tbAlteracao ON 
                 tbAlteracao.cod_emp = tbUpdCancPV.cod_emp
             AND tbAlteracao.cod_fil = tbUpdCancPV.cod_fil
             AND tbAlteracao.ano_solic = tbUpdCancPV.ano_solic
             AND tbAlteracao.num_solic = tbUpdCancPV.num_solic
             AND tbAlteracao.num_item  = tbUpdCancPV.num_item
             AND tbAlteracao.dthr_inc  = tbUpdCancPV.UpdateDate
      INNER JOIN of_logistica.tbsolic_saidas_item item ON
                 item.cod_emp   = tbAlteracao.cod_emp
             AND item.cod_fil   = tbAlteracao.cod_fil
             AND item.ano_solic = tbAlteracao.ano_solic
             AND item.num_solic = tbAlteracao.num_solic
             AND item.num_item  = tbAlteracao.num_item               
      WHERE tbUpdCancPV.STATUS = 2
        AND tbAlteracao.dthr_realizado IS NULL
   );
   
   
   #@Reviser David Ruy <2022-04-14 13:00> Desabilitado
   /*
   WHILE EXISTS (SELECT 1 FROM TMP_AlteracoesSLIN WHERE TMP_AlteracoesSLIN.FlgProcessado = 0) DO
   
      SET xQtdeRegs = xQtdeRegs + 1;
      
      SELECT DocumentType, DocumentId, DocumentNumber, DocumentDate, UniqueKey, dthr_inc,
             cod_emp, cod_fil, ano_solic, num_solic, num_item, 
             qtde_est_atu, qtde_vol_atu, qtde_frac_atu, qtde_peso_atu,
             dthr_aconselhamento, dthr_inicio_separacao, dthr_final_separacao
      INTO xDocTipo, xDocEntry, xDocNum, xDocumentDate, xUniqueKey, xDthrInc,
           xCodEmpWMS, xCodFilWMS, xAnoSolic, xNumSolic, xNumItem, 
           xQtdeEst, xQtdeVol, xQtdeFrac, xQtdePeso,
           xdthr_aconselhamento, xdthr_inicio_separacao, xdthr_final_separacao
      FROM TMP_AlteracoesSLIN
      WHERE TMP_AlteracoesSLIN.FlgProcessado = 0
      LIMIT 1;
      
--       if xdthr_aconselhamento is null then
--          # Faz nada
--          set @R = null;
--              
--       elseif xdthr_inicio_separacao is null then
--             #não chamar estas procedures elas são de outro banco de dados, por isso não funcionam se chamadas desta procedure
--             #para isso foi criado o FlgAconselhar na tabela temporária para que as rotinas abaixo sejam chamadas pelo programa 
--             #de integração quando for setado em "1"
--       
--             #Cancelar Aconselhamento
--             #call of_logistica.PROC_WMS_SAIDA_CANCELAR_ACONSELHAMENTO(xCodEmpWMS, xCodFilWMS, xAnoSolic, xNumSolic, xNumItem, xCodUsuario, @R, @M);
--             #Refazer aconselhamento
--             #CALL of_logistica.PROC_WMS_SAIDA_GERAR_ACONSELHAMENTO(8, 1, xCodEmpWMS, xCodFilWMS, xAnoSolic, xNumSolic, xNumItem, xQtdeVol, xQtdeFrac, @R, @M);            
--       end if;

      #Se ainda nao rodou aconselhamento ou se ainda não iniciou a separação
      IF (xdthr_aconselhamento IS NULL) OR (xdthr_inicio_separacao IS NULL) THEN
         #Atualiza Status do Documento de 7 (em alteração) para 3 (Atualizado SLIN)
         UPDATE tbintegraSAP_Doc
         SET tbintegraSAP_Doc.StatusAnt = StatusDoc,
             #tbintegraSAP_Doc.StatusDoc = 3
             tbintegraSAP_Doc.StatusDoc = 1  #<2022-03-22> Força PROC_INTEGRA_AtualizarSLIN (Criar itens, atualizar Qtde)
         WHERE DocEntry = xDocEntry
           AND DocNum   = xDocNum   
           AND DocTipo  = xDocTipo;
           
        #Atualiza REALIZADO da tabela de controle de alterações de interface
        UPDATE of_logistica.tbsolic_saidas_item_integra_alteracao
        SET tbsolic_saidas_item_integra_alteracao.dthr_realizado = NOW(),
            tbsolic_saidas_item_integra_alteracao.usu_realizado = xCodUsuario,
            tbsolic_saidas_item_integra_alteracao.flg_realizado = 1
        WHERE UniqueKey = xUniqueKey
          AND dthr_inc  = xDthrInc;
          
      END IF;
      
      UPDATE TMP_AlteracoesSLIN
      SET FlgProcessado = 1,
          FlgAconselhar = IF((xdthr_aconselhamento IS NOT NULL) AND (xdthr_inicio_separacao IS NULL),1,0) 
      WHERE UniqueKey = xUniqueKey 
        AND dthr_inc  = xDthrInc;
      
   END WHILE;
   */   
   
   #Atualiza/Libera Status do controle de alterações
   UPDATE tbintegraSAP_UpdCancPV tbUpdCancPV
   INNER JOIN TMP_AlteracoesSLIN ON
              TMP_AlteracoesSLIN.UniqueKey  = tbUpdCancPV.UniqueKey 
          AND TMP_AlteracoesSLIN.UpdateDate = tbUpdCancPV.UpdateDate
   SET tbUpdCancPV.FreeText = CONCAT(tbUpdCancPV.FreeText,'|PROC_INTEGRA_TratarAlteraoesSLIN(0)')
      ,tbUpdCancPV.STATUS = 3;
   
   /*
   INNER JOIN of_logistica.tbsolic_saidas_item_integra_alteracao tbAlteracao ON 
              tbAlteracao.cod_emp   = tbUpdCancPV.cod_emp
          AND tbAlteracao.cod_fil   = tbUpdCancPV.cod_fil
          AND tbAlteracao.ano_solic = tbUpdCancPV.ano_solic
          AND tbAlteracao.num_solic = tbUpdCancPV.num_solic
          AND tbAlteracao.num_item  = tbUpdCancPV.num_item
          AND tbAlteracao.dthr_inc  = tbUpdCancPV.UpdateDate
   SET tbUpdCancPV.STATUS = 3
   WHERE tbUpdCancPV.STATUS = 2
     AND tbAlteracao.dthr_realizado IS NULL;
  */
  
  
  
   #@David Ruy <2021/04/30>
   #Atualizar Alterações em aberto (Inclusão STATUS=1)
   #Isso também evita que 
   UPDATE tbintegraSAP_UpdCancPV tbUpdCancPV
   SET tbUpdCancPV.FreeText = CONCAT(tbUpdCancPV.FreeText,'|PROC_INTEGRA_TratarAlteraoesSLIN')
      ,tbUpdCancPV.STATUS   = 3
   WHERE tbUpdCancPV.STATUS = 1;
   
   
   
   IF excecao = 1 THEN
      SET RESULTADO = 0;
      SET MENSAGEM = CONCAT(IFNULL(MENSAGEM,""),"- Erro PROC_INTEGRA_TratarAlteraoesSLIN [",xQtdeRegs,"]");
   ELSE
      SET RESULTADO = 1;
      SET MENSAGEM = CONCAT(IFNULL(MENSAGEM,""),"- PROC_INTEGRA_TratarAlteraoesSLIN - sucesso [",xQtdeRegs,"]");
   END IF;
   SELECT TMP_AlteracoesSLIN.*, RESULTADO, MENSAGEM FROM TMP_AlteracoesSLIN;
   DROP TEMPORARY TABLE IF EXISTS TMP_AlteracoesSLIN;    
  
   IF excecao = 1 THEN
      ROLLBACK;
   ELSE
      COMMIT;
   END IF;
   
   
END$$

DELIMITER ;