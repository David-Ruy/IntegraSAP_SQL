DELIMITER $$

DROP PROCEDURE IF EXISTS `PROC_INTEGRA_RetornoTracking`$$

CREATE PROCEDURE `PROC_INTEGRA_RetornoTracking`()
BLOCO1:BEGIN
   /*******************************************************************************************
   #@Author David Ruy <2021-11-29>
    * PARÂMETRO oTipoRetorno DETERMINA 
    *   0 = Retorna os Status de Pedidos TMS
    *   1 = Retorna os Pedidos no TMS sem chave_nfe
    *   2 = Retorna os Status de Pedidos Campo StatusAux_Cliente  
   #@Reviser David Ruy <2023-05-02> Status Picking para status_processo in (6,7,8,9)
   #@Reviser David Ruy <2024-11-21> Atualizar Novo_StatusCliente (fnStatusCliente)
   ********************************************************************************************/
   
   DECLARE excecao 	          INT DEFAULT 0;
   DECLARE RESULTADO          INT DEFAULT 1;
   DECLARE MENSAGEM           VARCHAR(500);
   DECLARE xDias              INT DEFAULT 10;   #Qtde de Dias Status TMS
   #DECLARE CONTINUE HANDLER FOR SQLEXCEPTION SET excecao = 1;
   DECLARE xDocEntry           INT;
   DECLARE xDocTipo            VARCHAR(10); 
   DECLARE xstatus_processo    VARCHAR(10);
   DECLARE xstatus_picking     VARCHAR(10);
   DECLARE xstatus_entre       VARCHAR(10);
   DECLARE xstatus_baixa       VARCHAR(10);
   DECLARE xStatusEntrega      VARCHAR(100);
   DECLARE xStatusArmazem      VARCHAR(100);
   DECLARE xStatusCliente      VARCHAR(2000);
   
   
   
      #Cria tabela temporária com as GSM recebidas que serão separadas
      DROP TEMPORARY TABLE IF EXISTS tbTMP_INTEGRA_RETORNO_B1;
      CREATE TEMPORARY TABLE tbTMP_INTEGRA_RETORNO_B1 AS 
         SELECT DISTINCT DocEntry, DocTipo, DocNum, tbintegraSAP_Doc.chave_integracao,
                tbintegraSAP_Doc.StatusDoc AS StatusDoc,
                tbRotas.descr_rota RotaCliente,
                tbSaidas.status_processo, tbSaidas.status_picking,
                tbEntregas.status_entre,  tbEntregas.status_baixa, 
                IF(tbSaidas.status_processo <= 5, tbSaidas.status_processo, 
                      CONCAT(tbSaidas.status_picking)) AS StatusProcessAux,
                CASE IFNULL(tbEntregas.status_entre,-1)
                   WHEN -1 THEN "A roteirizar"
                   WHEN 0 THEN "Em Roteirizacao"
                   WHEN 1 AND tbEntregas.status_baixa IS NULL THEN
                              IF(tbViagens.dthr_liberacao IS NULL, "Roteirizado - Entrega em aberto",
                                                                   "Em Rota para entrega") 
                ELSE of_logistica.fnStatusBaixaEntrega(tbEntregas.status_baixa)
                END AS StatusEntrega,
                IF(tbSaidas.status_processo < 5, "Em Preparacao", 
                      CONCAT('',of_logistica.fnStatusPickingWms(tbSaidas.status_picking))) AS StatusArmazem,
#                   IF(tbSaidas.status_processo IN (6,7,8,9), 
#                      CONCAT('pk=>',of_logistica.fnStatusPickingWms(tbSaidas.status_picking)),
#                      CONCAT('sep=>',of_logistica.fnStatusSaidaWms(tbSaidas.status_processo)))) AS StatusArmazem,
                SPACE(200) AS StatusIntegracao, SPACE(200) AS StatusIntegracaoAux,
                tbintegraSAP_Doc.StatusAux_Cliente  AS StatusAux,
                tbintegraSAP_Doc.StatusAux_Cliente  AS StatusAux_Cliente,
                SPACE(200) AS Novo_StatusCliente,
                IF(tbViagens.data_conf IS NULL, "",
                   CONCAT(tbViagens.cod_emp,'/',tbViagens.cod_fil,'-',tbViagens.ano_viagem,'.',tbViagens.num_viagem,'=>',
                   IFNULL(tbRotas.descr_rota,IFNULL(tbRotas2.descr_rota,"")))) RefViagem,
                IFNULL(tbViagens.cnpj_transportador,tbSaidas.cnpj_cpf_transp) CodTranspTMS,
                tbViagens.data_conf, tbViagens.dthr_liberacao,
                tbintegraSAP_Doc.RefViagem RefViagemAux,
                tbintegraSAP_Doc.StatusEntrega StatusEntregaAux,
                tbintegraSAP_Doc.StatusArmazem StatusArmazemAux
/**********************************/
                , CONCAT(tbSaidas.status_processo,'.',status_entre,tbEntregas.status_baixa,'.',of_logistica.fnStatusBaixaEntrega(tbEntregas.status_baixa)) AS StatusClienteAux                
                , CAST( ( SELECT SUM(IFNULL(tbSaidasItem.real_est2, 0))
                            FROM of_logistica.tbsolic_saidas_item tbSaidasItem           
                           WHERE tbSaidasItem.cod_emp        = tbSaidas.cod_emp
                             AND tbSaidasItem.cod_fil        = tbSaidas.cod_fil
                             AND tbSaidasItem.ano_solic      = tbSaidas.ano_solic
                             AND tbSaidasItem.num_solic      = tbSaidas.num_solic
                         )
                        AS DECIMAL(18,6)
                      )                                AS QtdeSep
                , CAST( ( SELECT SUM(IFNULL(tbSaidasVolItem.qtde_sep_est, 0))
                            FROM of_logistica.tbsolic_saidas_volume_item tbSaidasVolItem
                           WHERE tbSaidasVolItem.cod_emp     = tbSaidas.cod_emp
                             AND tbSaidasVolItem.cod_fil     = tbSaidas.cod_fil
                             AND tbSaidasVolItem.ano_solic   = tbSaidas.ano_solic
                             AND tbSaidasVolItem.num_solic   = tbSaidas.num_solic
                        )
                        AS DECIMAL(18,6)
                      )                                AS  QtdeMontagemCheckout
                , CAST( ( SELECT SUM(IFNULL(tbSaidasVolItem.qtde_conf_est2, 0))
                            FROM of_logistica.tbsolic_saidas_volume_item tbSaidasVolItem
                           WHERE tbSaidasVolItem.cod_emp     = tbSaidas.cod_emp
                             AND tbSaidasVolItem.cod_fil     = tbSaidas.cod_fil
                             AND tbSaidasVolItem.ano_solic   = tbSaidas.ano_solic
                             AND tbSaidasVolItem.num_solic   = tbSaidas.num_solic
                        )
                        AS DECIMAL(18,6)
                      )                                AS  QtdeConferenciaCheckout
                , CAST( ( SELECT SUM(IFNULL(tbSaidasVolItem.qtde_conf_est3, 0))
                            FROM of_logistica.tbsolic_saidas_volume_item tbSaidasVolItem
                           WHERE tbSaidasVolItem.cod_emp     = tbSaidas.cod_emp
                             AND tbSaidasVolItem.cod_fil     = tbSaidas.cod_fil
                             AND tbSaidasVolItem.ano_solic   = tbSaidas.ano_solic
                             AND tbSaidasVolItem.num_solic   = tbSaidas.num_solic
                        )
                        AS DECIMAL(18,6)
                      )                                AS  QtdeCarregamento
                , tbintegraSAP_Tracking.StatusAtual StatusTrackingAtual
                , tbintegraSAP_Tracking.StatusAnt StatusTrackingAnt
                , 0 AS Processado
/**********************************/
         FROM tbintegraSAP_Doc
         INNER JOIN of_logistica.tbsolic_saidas tbSaidas ON
               tbSaidas.cod_emp   = tbintegraSAP_Doc.cod_emp
           AND tbSaidas.cod_fil   = tbintegraSAP_Doc.cod_fil
           AND tbSaidas.ano_solic = tbintegraSAP_Doc.ano_solic
           AND tbSaidas.num_solic = tbintegraSAP_Doc.num_solic
         INNER JOIN of_logistica.tbprog_entregas tbEntregas ON
                   tbEntregas.chave_integracao = tbSaidas.chave_integracao
         LEFT JOIN of_logistica.tbdestinatarios tbDest ON 
                   tbDest.id_destinatario = tbEntregas.id_destinatario
         LEFT JOIN of_logistica.tbrotas tbRotas ON
                   tbRotas.cod_emp  = tbDest.emp_rota
               AND tbRotas.cod_fil  = tbDest.fil_rota
               AND tbRotas.cod_rota = tbDest.cod_rota                
         LEFT JOIN of_logistica.tbviagens tbViagens ON 
                   tbViagens.cod_emp    = tbEntregas.cod_emp 
               AND tbViagens.cod_fil    = tbEntregas.cod_fil
               AND tbViagens.ano_viagem = tbEntregas.ano_viagem
               AND tbViagens.num_viagem = tbEntregas.num_viagem
         LEFT JOIN of_logistica.tbrotas tbRotas2 ON
                   tbRotas2.cod_emp  = tbViagens.emp_rota
               AND tbRotas2.cod_fil  = tbViagens.fil_rota
               AND tbRotas2.cod_rota = tbViagens.cod_rota    
         LEFT JOIN tbintegraSAP_Tracking ON 
                   tbintegraSAP_Tracking.chave_integracao = tbintegraSAP_Doc.chave_integracao
         WHERE tbintegraSAP_Doc.DocDate > DATE_SUB(CURRENT_DATE(), INTERVAL xDias DAY)
           AND tbintegraSAP_Doc.DocTipo IN ("PV","TD-S","NS")
           #and tbintegraSAP_Doc.DocNum in ()
           AND tbSaidas.dthr_cancelamento IS NULL
           AND (tbEntregas.status_baixa IS NULL OR 
                #DATE(tbEntregas.dthr_baixa) = CURRENT_DATE())
                DATE(tbEntregas.dthr_baixa) >= DATE_SUB(CURRENT_DATE(), INTERVAL xDias DAY) )
           #and substring(tbintegraSAP_Doc.StatusEntrega,1,1) = '_'
           AND tbSaidas.dthr_cancelamento IS NULL;
           
      #Não lista registros sem alteração de Status     
      DELETE FROM tbTMP_INTEGRA_RETORNO_B1 
      WHERE StatusTrackingAtual = StatusAux_Cliente
        AND RefViagemAux = RefViagem;
     
     #Desabilitado : Antiga rotina Mistral   
     #UPDATE tbTMP_INTEGRA_RETORNO_B1 
     #SET StatusIntegracao    = CONCAT("WMS->",StatusArmazem," / ","TMS->",StatusEntrega),
     #    StatusIntegracaoAux = IF(IF(status_processo <= 5,status_processo,status_picking) <= 5, '1 - Em Separação',
     #                            IF(status_processo = 11, '3 - Cancelado',
     #                               IF(status_entre IS NULL,
     #                                  '2 - Separação Concluída', 
     #                                  IF(status_entre = 0, '4 - Em Roteirização',
     #                                       IF(status_baixa IS NULL, '5 - Em Rota para Entrega',
     #                                          CONCAT(status_baixa+6,' - ',StatusEntrega))))));
         
         
     #@Reviser David Ruy <2024-03-04> Solicitação Mistral
     #Colocar a regra em tabela
     #UPDATE tbTMP_INTEGRA_RETORNO_B1 
     #SET StatusIntegracao = StatusIntegracaoAux;         
     
     
     #select * from tbTMP_INTEGRA_RETORNO_B1;                                      
     /*************************************************************************/
     UPDATE tbTMP_INTEGRA_RETORNO_B1 SET Processado = 0;
     WHILE EXISTS (SELECT 1 FROM tbTMP_INTEGRA_RETORNO_B1 WHERE Processado = 0) DO
        
        SELECT DocEntry, DocTipo, status_processo, status_picking, status_entre, status_baixa, StatusEntrega, StatusArmazem
        INTO xDocEntry, xDocTipo, xstatus_processo, xstatus_picking, xstatus_entre, xstatus_baixa, xStatusEntrega, xStatusArmazem
        FROM tbTMP_INTEGRA_RETORNO_B1 
        WHERE Processado = 0 LIMIT 1;
     
        #select xstatus_processo,xstatus_entre,xstatus_baixa,xStatusEntrega;
        SET @xStrCase = fnStatusCliente(xstatus_processo,xstatus_entre,xstatus_baixa);
        SET @xStrCase = REPLACE(@xStrCase, 'oStatusProcesso', 'status_processo');
        SET @xStrCase = REPLACE(@xStrCase, 'oStatusEntrega', 'status_entre');
        SET @xStrCase = REPLACE(@xStrCase, 'oStatusBaixa', 'status_baixa');
        
        SET @xStrCase = CONCAT(@xStrCase, ' from tbTMP_INTEGRA_RETORNO_B1 ',
                 ' where DocTipo = "',xDocTipo,'" AND DocEntry = ',xDocEntry);
        #SELECT @xStrCase;
        #leave bloco1;
               
        PREPARE SQL_StatusCliente FROM @xStrCase;
        EXECUTE SQL_StatusCliente; #USING @a, @b;
        DEALLOCATE PREPARE SQL_StatusCliente;
               
        #@Reviser David Ruy <2024-03-04> Solicitação Mistral
        #Colocar a regra em tabela
        UPDATE tbTMP_INTEGRA_RETORNO_B1 
        SET StatusTrackingAnt = StatusTrackingAtual, 
            StatusTrackingAtual = @xStatusCliente, 
            Processado = 1
        WHERE DocTipo  = xDocTipo
          AND DocEntry = xDocEntry;
          
          
          #SELECT chave_integracao, StatusAtualTracking, StatusAntTracking, NOW(), NULL 
#		 FROM tbTMP_INTEGRA_RETORNO_B1 WHERE DocTipo  = xDocTipo AND DocEntry = xDocEntry;
#          INSERT INTO tbintegraSAP_Tracking (chave_integracao, StatusAtual, StatusAnt, dthr_inc, dthr_alt)
#		(SELECT chave_integracao, StatusAtualTracking, StatusAntTracking, NOW(), NULL 
#		 FROM tbTMP_INTEGRA_RETORNO_B1 WHERE DocTipo  = xDocTipo AND DocEntry = xDocEntry)
#	  ON DUPLICATE KEY UPDATE StatusAtual = StatusTrackingAtual, StatusAnt = StatusTrackingAnt, dthr_alt = NOW();
         
     END WHILE;
     /*************************************************************************/
     
     #Não lista registros sem alteração de Status     
	DELETE FROM tbTMP_INTEGRA_RETORNO_B1 
	WHERE StatusTrackingAnt = StatusTrackingAtual;
      
	INSERT IGNORE INTO tbintegraSAP_Tracking (chave_integracao, StatusAtual, StatusAnt, dthr_inc, dthr_alt)
	(SELECT chave_integracao, StatusTrackingAtual, StatusTrackingAnt, NOW(), NULL 
	 FROM tbTMP_INTEGRA_RETORNO_B1);
	
	UPDATE tbintegraSAP_Tracking 
	INNER JOIN tbTMP_INTEGRA_RETORNO_B1 ON tbTMP_INTEGRA_RETORNO_B1.chave_integracao = tbintegraSAP_Tracking.chave_integracao
	SET StatusAtual = StatusTrackingAtual 
	   ,StatusAnt = StatusTrackingAnt 
	   ,dthr_alt = NOW();
      
      SELECT * FROM tbTMP_INTEGRA_RETORNO_B1;
      
      DROP TEMPORARY TABLE IF EXISTS tbTMP_INTEGRA_RETORNO_B1;
      #DROP TEMPORARY TABLE IF EXISTS tTabelaComTexto;
      
    
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