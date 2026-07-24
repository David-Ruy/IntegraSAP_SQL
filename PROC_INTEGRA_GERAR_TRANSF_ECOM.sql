DELIMITER $$

DROP PROCEDURE IF EXISTS `PROC_INTEGRA_GERAR_TRANSF_ECOM`$$

CREATE PROCEDURE `PROC_INTEGRA_GERAR_TRANSF_ECOM`( 
  IN oItemCode     VARCHAR(20)
, IN oDepOrigem    VARCHAR(20)
, IN oDepDestino   VARCHAR(20)
, IN oQuantidade   DECIMAL(18,6)
, OUT RESULTADO    VARCHAR(40)
, OUT MENSAGEM     VARCHAR(500)
)
BLOCO1:BEGIN
   /************************************************************************
   * @Created David Ruy <2023/01/14>
   * Esta procedure realiza a inserção de registros na base de dados SLIN
   * para o módulo WM (tbwms_manut_lote) 
   * SAP : transferencia entre depósitos 
   * SLIN : Alteração de Status
   /************************************************************************/
   /****************************************************************/
   /****************DECLARAR VARIÁVEIS AUXILIARES
   /****************************************************************/
   DECLARE xDepositoAux        VARCHAR(10);
   DECLARE xCodEmp             VARCHAR(03);
   DECLARE xCodFil             VARCHAR(03);
   DECLARE xNumLote            VARCHAR(10); 
   DECLARE xSequenciaLote      INT;
   DECLARE xStatusOrigem       VARCHAR(03); 
   DECLARE xStatusDestino      VARCHAR(03); 
   DECLARE xQtdeATransf        DECIMAL(18,6);
   DECLARE xSaldoQtde          DECIMAL(18,6);
   DECLARE xSaldoPLiq          DECIMAL(18,6);
   DECLARE xSaldoEst           DECIMAL(18,6);
   DECLARE xSaldoVol           DECIMAL(18,6);
   DECLARE xSaldoFrac          DECIMAL(18,6);
   DECLARE xSaldoPeso          DECIMAL(18,6);
   DECLARE xNumLoteAux         VARCHAR(10); 
   DECLARE xSequenciaAux       INT;
   DECLARE xFragmentou         BOOLEAN;
   /****************************************************************/
   /****************CONTROLE DE EXCEÇÃO DE SQL
   /****************************************************************/
  
   DECLARE EXIT HANDLER FOR SQLEXCEPTION
   BEGIN
    
     GET DIAGNOSTICS CONDITION 1 MENSAGEM = MESSAGE_TEXT;
  
     ROLLBACK;
     SET RESULTADO = '0';
     SET MENSAGEM  = MENSAGEM;
   END;
   
   
  
   START TRANSACTION;
   
   
   #Quantidade Negativa, inverte depósitos Origem <-> Destino
   IF (oQuantidade < 0) THEN
      SET oQuantidade = oQuantidade * -1;
      SET xDepositoAux = oDepOrigem;
      SET oDepOrigem = oDepDestino;
      SET oDepDestino = xDepositoAux;
   END IF;
   
   
   
   
  
   SELECT IFNULL(cod_emp,'001'), IFNULL(cod_fil,'001'), IFNULL(tbstatus_lotes.codigo, tbstatus_lotes_integracao.codigo_status) cod_status
   INTO xCodEmp, xCodFil, xStatusOrigem
   FROM of_logistica.tbstatus_lotes
   LEFT JOIN of_logistica.tbstatus_lotes_integracao ON
             tbstatus_lotes_integracao.codigo_status = tbstatus_lotes.codigo
   WHERE of_logistica.tbstatus_lotes.deposito_integracao = oDepOrigem
      OR tbstatus_lotes_integracao.deposito_integracao = oDepOrigem;
   
   SELECT IFNULL(tbstatus_lotes.codigo, tbstatus_lotes_integracao.codigo_status) cod_status
   INTO xStatusDestino
   FROM of_logistica.tbstatus_lotes
   LEFT JOIN of_logistica.tbstatus_lotes_integracao ON
             tbstatus_lotes_integracao.codigo_status = tbstatus_lotes.codigo
   WHERE of_logistica.tbstatus_lotes.deposito_integracao = oDepDestino
      OR tbstatus_lotes_integracao.deposito_integracao = oDepDestino;
      
      
   DROP TEMPORARY TABLE IF EXISTS tbTMPTransferencia;
   CREATE TEMPORARY TABLE tbTMPTransferencia
       SELECT cod_emp, cod_fil, num_lote, sequencia_lote, 
              fator_conv, emb_vol, emb_frac, emb_nf, vlr_unitario, vlr_unitario_nf, 
              flg_tipo_vlr, data_fabr, data_valid, status_lote,
              sld_fisico_est - IFNULL(qtd_emp_est,0) saldo_est, 
              sld_fisico_vol - IFNULL(qtd_emp_vol,0) saldo_vol, 
              sld_fisico_frac- IFNULL(qtd_emp_frac,0) saldo_frac, 
              sld_fisico_peso- IFNULL(qtd_emp_peso,0) saldo_peso,
              0 AS Processado
       FROM of_logistica.tbwms_estoque
       WHERE cod_emp = xCodEmp
         AND cod_fil = xCodFil
         AND cod_produto = oItemCode
         AND sld_fisico_est - IFNULL(qtd_emp_est,0) > 0
         AND status_lote = xStatusOrigem
       ORDER BY sld_fisico_est - IFNULL(qtd_emp_est,0);
              
   IF NOT EXISTS (SELECT 1 FROM tbTMPTransferencia) THEN
      SET RESULTADO = 0;
      SET mensagem = CONCAT("Não existe saldo no WMS para essa transferencia ",
         xCodEmp,'/',xCodFil,' Item:',oItemCode,' de ',xStatusOrigem,' para ',xStatusDestino,
         ' Qtde = ',oQuantidade);
      ROLLBACK;
      LEAVE bloco1;
   END IF;
    
       
   SET xSaldoQtde = oQuantidade;
   WHILE EXISTS (SELECT 1 FROM tbTMPTransferencia WHERE Processado = 0) DO
          
      SET xNumLote = NULL;
      #Busca UA com qtde Exata
      IF EXISTS (SELECT 1 FROM tbTMPTransferencia 
                 WHERE Processado = 0 AND saldo_est = xSaldoQtde) THEN
         SELECT num_lote, sequencia_lote, saldo_est, saldo_vol, saldo_frac, saldo_peso 
         INTO xNumLote, xSequenciaLote, xSaldoEst, xSaldoVol, xSaldoFrac, xSaldoPeso
         FROM tbTMPTransferencia 
         WHERE Processado = 0 AND saldo_est = xSaldoQtde
         LIMIT 1;
         SET xQtdeATransf = xSaldoQtde;
      #Se não tem Qtde exata, Busca UA com qtde menor que o saldo a transferir
      ELSEIF EXISTS (SELECT 1 FROM tbTMPTransferencia 
                     WHERE Processado = 0 AND saldo_est < xSaldoQtde) THEN
         SELECT num_lote, sequencia_lote, saldo_est, saldo_vol, saldo_frac, saldo_peso 
         INTO xNumLote, xSequenciaLote, xSaldoEst, xSaldoVol, xSaldoFrac, xSaldoPeso
         FROM tbTMPTransferencia 
         WHERE Processado = 0 AND saldo_est < xSaldoQtde
         LIMIT 1;
         SET xQtdeATransf = xSaldoEst;
      #Se não tem Qtde exata nem Qtde menor, pega a de menor qtde (Order By da tabela temporária)
      ELSE
         SELECT num_lote, sequencia_lote, saldo_est, saldo_vol, saldo_frac, saldo_peso 
         INTO xNumLote, xSequenciaLote, xSaldoEst, xSaldoVol, xSaldoFrac, xSaldoPeso
         FROM tbTMPTransferencia 
         WHERE Processado = 0
         LIMIT 1;       
      END IF;
      
      
      IF xNumLote IS NULL THEN
         SET RESULTADO = 0;
         SET mensagem = CONCAT("Saldo Insuficiente(0) no WMS para essa transferencia ",
            xCodEmp,'/',xCodFil,' Item:',oItemCode,' de ',xStatusOrigem,' para ',xStatusDestino,
            ' Qtde = ',oQuantidade);
         ROLLBACK;
         LEAVE bloco1;      
      END IF;
       
      SET xFragmentou = FALSE;
      IF xSaldoEst >= xSaldoQtde THEN
         #PesoLiquido Proporcional (Ref : xSaldoQtde)
         SET xSaldoPLiq = xSaldoPeso / xSaldoEst * xSaldoQtde;
      
         # Fragmentar (Gera nova UA com a Quantidade = xSaldoQtde e Peso = xSaldoPLiq )
         # Essa UA será utilizada para a transferencia
         CALL of_logistica.PROC_WMS_ARMAZEM_GERAR_FRAGMENTACAO(
              xCodEmp, xCodFil, xNumLote, xSequenciaLote, xSaldoQtde, xSaldoPLiq, xStatusOrigem, 
              '999999', 'Fragmentação Automática - Transf EComm', @Resultado, @Mensagem, xNumLoteAux, xSequenciaAux);
              
         IF (@Resultado <> 1) THEN
            #Forçar erro; Abortar rotina
            SET @Teste = 1/0;
         ELSE
         
            SET xFragmentou = TRUE;         
            
            #Atualiza flag Processado tabela temporária (Lote Original "Processado")
            UPDATE tbTMPTransferencia 
            #SET Processado = 0
            SET saldo_est  = saldo_est  - xSaldoQtde,
                saldo_peso = saldo_peso - xSaldoPLiq
            WHERE cod_emp  = xCodEmp
              AND cod_fil  = xCodFil
              AND num_lote = xNumLote
              AND sequencia_lote = xSequenciaLote;
                
            #Insere novo lote Fragmentado na tabela temporária, é o registro 
            #que será processado para atender a movimentação
            INSERT INTO tbTMPTransferencia (cod_emp, cod_fil, num_lote, sequencia_lote, 
                      fator_conv, emb_vol, emb_frac, emb_nf, vlr_unitario, vlr_unitario_nf,  
                      flg_tipo_vlr, data_fabr, data_valid, status_lote,
                      saldo_est, saldo_vol, saldo_frac, saldo_peso,
                      Processado)
               (SELECT xCodEmp, xCodFil, xNumLoteAux, xSequenciaAux, 
                       fator_conv, emb_vol, emb_frac, emb_nf, vlr_unitario, vlr_unitario_nf, 
                       flg_tipo_vlr, data_fabr, data_valid, status_lote,
                       sld_fisico_est - IFNULL(qtd_emp_est,0) saldo_est, 
                       sld_fisico_vol - IFNULL(qtd_emp_vol,0) saldo_vol, 
                       sld_fisico_frac- IFNULL(qtd_emp_frac,0) saldo_frac, 
                       sld_fisico_peso- IFNULL(qtd_emp_peso,0) saldo_peso, 
                       0
                FROM tbwms_estoque
                WHERE cod_emp  = xCodEmp
                  AND cod_emp  = xCodFil
                  AND num_lote = xNumLoteAux
                  AND sequencia_lote = xSequenciaAux); 
            
         END IF;         
         
         SET xNumLote       = xNumLoteAux;
         SET xSequenciaLote = xSequenciaAux;
         SET xQtdeATransf   = xSaldoQtde;
         
      END IF;
            
      
      #Insere movimento de alteração de Status
      INSERT INTO of_logistica.tbwms_manut_lote
         (cod_emp, cod_fil, num_lote, sequencia_lote, dthr_inc, usu_inc, 
          fator_conv_ant, emb_vol_ant, emb_frac_ant, emb_nf_ant, 
          vlr_unitario_ant, flg_tipo_vlr_ant, data_fabricacao_ant, data_validade_ant, cod_status_ant, 
          fator_conv, emb_vol, emb_frac, emb_nf, vlr_unitario, vlr_unitario_nf, flg_tipo_vlr, observacao,  
          data_fabricacao, data_validade, cod_status, 
          observ) 
          (SELECT cod_emp, cod_fil, num_lote, sequencia_lote, NOW(), '999999', 
                  fator_conv, emb_vol, emb_frac, emb_nf, vlr_unitario, flg_tipo_vlr, data_fabr, data_valid, status_lote, 
                  fator_conv, emb_vol, emb_frac, emb_nf, vlr_unitario, vlr_unitario_nf, flg_tipo_vlr, 
                  "Movimentação automática - Serviço OOne_IntegraSAP_Transf_Ecom",
                  data_fabr, data_valid, xStatusDestino, 
                  CONCAT("Transf Aut E-Comm. Saldo=",xSaldoQtde)
           FROM of_logistica.tbwms_estoque
           WHERE cod_emp = xCodEmp
           AND cod_fil   = xCodFil
           AND num_lote  = xNumLote
           AND sequencia_lote = xSequenciaLote);
           
           
      #Atualiza Status na tabela de estoque
      UPDATE of_logistica.tbwms_estoque
      SET status_lote = xStatusDestino
      WHERE cod_emp   = xCodEmp
        AND cod_fil   = xCodFil
        AND num_lote  = xNumLote
        AND sequencia_lote = xSequenciaLote;
        
        
      #Atualiza flag Processado tabela temporária
      UPDATE tbTMPTransferencia 
      SET Processado = 1
      WHERE cod_emp  = xCodEmp
        AND cod_fil  = xCodFil
        AND num_lote = xNumLote
        AND sequencia_lote = xSequenciaLote;
        
      #Atualiza Variável de controle de Saldo  
      SET xSaldoQtde = xSaldoQtde - xQtdeATransf;
            
      #Força Finalização do Loop (Processado = 2 => Finalização forçada)
      IF (xSaldoQtde = 0) THEN
         UPDATE tbTMPTransferencia 
         SET Processado = 2
         WHERE cod_emp  = xCodEmp
           AND cod_fil  = xCodFil
           AND Processado = 0;
         #  AND num_lote = xNumLote
         #  AND sequencia_lote = xSequenciaLote;
      END IF;
                   
   END WHILE;
   
   
   /****************************************************************/
   /******** FINALIZA PROCEDURE E ENVIA RETORNO
   /****************************************************************/
   SET RESULTADO = 1;
   SET mensagem = "Transferencia realizada com sucesso";
   COMMIT;
   
END$$

DELIMITER ;