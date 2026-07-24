DELIMITER $$

DROP PROCEDURE IF EXISTS `PROC_INTEGRA_FINALIZAR_ITEM_GSM`$$

CREATE PROCEDURE `PROC_INTEGRA_FINALIZAR_ITEM_GSM`( 
  IN oCodigoEmpresa    VARCHAR(3)
, IN oCodigoFilial     VARCHAR(3)
, IN oAnoProcesso      VARCHAR(4)
, IN oNumeroProcesso   VARCHAR(10)
, IN oNumeroItem       VARCHAR(6)
, OUT RESULTADO		      INT(1)
, OUT MENSAGEM         VARCHAR(255)
)
BLOCO2:BEGIN
  # PROCEDURE PARA CANCELAR GSM 
  # @author Érico Forcinetti <2019/07/15>
  # @company Overflash Informática
  
  /** 
   * ------------------------ INFORMAÇÕES ADICIONAIS -----------------------
   *
   *
   * ---------------------- FIM INFORMAÇÕES ADICIONAIS ---------------------
   */
  
  /****************************************************************/
  /**************** DECLARAR VARIÁVEIS AUXILIARES 
  /****************************************************************/
  DECLARE xCodUsuario      VARCHAR(06) DEFAULT "999999";  
  DECLARE _DthrAtual       DATETIME DEFAULT NOW();
  
  /****************************************************************/
  /****************DECLARAR CONTROLE DE EXCEÇÃO DE SQL 
  /****************************************************************/
    
	 DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    
    GET DIAGNOSTICS CONDITION 1 MENSAGEM = MESSAGE_TEXT;
  
    ROLLBACK;
    SET RESULTADO = 0;
    SET MENSAGEM  = fnMensagemExcecao(MENSAGEM);
		END;
	 
  /****************************************************************/
  /**************** INICIAR TRANSAÇÃO 
  /****************************************************************/
	 
  START TRANSACTION; 
	 
  /****************************************************************/
  /**************** ATUALIZAR TOPO DO ITEM
  /****************************************************************/
  
  UPDATE of_logistica.tbsolic_saidas_item tbItem
     SET tbItem.real_vol    = 0           
       , tbItem.real_frac   = 0          
       , tbItem.real_est    = 0       
       , tbItem.real_peso   = 0          
       , tbItem.real_pbrt   = 0          
       , tbItem.real_vol2   = 0          
       , tbItem.real_frac2  = 0          
       , tbItem.real_est2   = 0          
       , tbItem.real_peso2  = 0    
       , tbItem.dthr_aconselhamento = _DthrAtual
       , tbItem.usu_aconselhamento = xCodUsuario
   WHERE tbItem.cod_emp   = oCodigoEmpresa
     AND tbItem.cod_fil   = oCodigoFilial
     AND tbItem.ano_solic = oAnoProcesso
     AND tbItem.num_solic = oNumeroProcesso
     AND tbItem.num_item  = oNumeroItem;
  
  /****************************************************************/
  /**************** ATUALIZAR LOG
  /****************************************************************/
  # Rotina já realizada na PROC_INTEGRA_TratarAlteraoesSLIN
  # Mas por precaução, segue :
  UPDATE of_logistica.tbsolic_saidas_item_integra_alteracao tbItemAlteracao
     SET tbItemAlteracao.dthr_realizado = _DthrAtual
       , tbItemAlteracao.usu_realizado  = xCodUsuario
   WHERE tbItemAlteracao.cod_emp        = oCodigoEmpresa
     AND tbItemAlteracao.cod_fil        = oCodigoFilial
     AND tbItemAlteracao.ano_solic      = oAnoProcesso
     AND tbItemAlteracao.num_solic      = oNumeroProcesso
     AND tbItemAlteracao.num_item       = oNumeroItem
     AND tbItemAlteracao.qtde_est_atu   = 0;
     #AND tbItemAlteracao.dthr_realizado IS NULL; 
     
  /****************************************************************/
  /**************** DESVINCULAR ITEMS DOS CHECKOUTS
  /****************************************************************/
  
  DELETE 
    FROM of_logistica.tbsolic_saidas_volume_item
   WHERE cod_emp   = oCodigoEmpresa
     AND cod_fil   = oCodigoFilial
     AND ano_solic = oAnoProcesso
     AND num_solic = oNumeroProcesso
     AND num_item  = oNumeroItem;
  
  #*******************************************************************************************
  #**
  #** Se por ventura houver algum erro em alguma etapa do processamento, cancela o processo
  #** inteiro e sinalizado ao usuario. Caso contrario efetiva informações no banco e sinaliza
  #** usuario.
  #**
  #********************************************************************************************
  
  SET MENSAGEM  = 'OK';
  SET RESULTADO = 1;
  COMMIT; 
  
END$$

DELIMITER ;