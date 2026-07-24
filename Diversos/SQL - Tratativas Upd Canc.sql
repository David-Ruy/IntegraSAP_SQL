/*******************************************************************************************
Cancelamento
   checar se o item tem checkout conferido   
   checar se o item está conferido
   chegar se a GSM está finalizada
   
   reabrir conferencia de amarrado
   excluir o item dos amarrados
   reabrir conferencia de amarrados com itens excluídos
   checar se tem amarrado sem itens e excluir  

   * gravar_cancelamento DO item (STATUS)
   * verificar se todos os itens estão cancelados e cancelar a GSM inteira (STATUS)

Alteração de Pedido
   Se quantidade < original ou lote <>
      seguir igual cancelamento
   se quantidade > original
      Se não começou - ok
      se já começou, reabir item (STATUS em conferencia)
         atualizar quantidade

*******************************************************************************************/


DECLARE xTemFlgCheckout BOOLEAN;
DECLARE xCheckoutConf BOOLEAN;
DECLARE xItemAconselhado BOOLEAN;
DECLARE xStatusConferencia INT;

DECLARE xcod_emp VARCHAR(03);
DECLARE xcod_fil VARCHAR(03);
DECLARE xano_solic VARCHAR(03);
DECLARE xnum_solic VARCHAR(03);
DECLARE xnum_item VARCHAR(03);
DECLARE xUpdCanc_Qtde DECIMAL(18,5);
DECLARE xUpdCanc_Price DECIMAL(18,5); 
DECLARE xUpdCanc_FreeText TEXT;
DECLARE xUpdCanc_UndCompra VARCHAR(10);
DECLARE xUpdCanc_UndVenda VARCHAR(10);
DECLARE xUpdCanc_UndEst VARCHAR(10);
DECLARE xItem_Qtde DECIMAL(18,5);
DECLARE xItem_Price DECIMAL(18,5);
DECLARE xItem_FreeText TEXT;
DECLARE xItem_UndCompra VARCHAR(10);
DECLARE xItem_UndVenda VARCHAR(10);
DECLARE xItem_UndEst VARCHAR(10);


DROP TEMPORARY TABLE IF EXISTS tbTMPUpdCanc;
CREATE TEMPORARY TABLE tbTMPUpdCanc
   SELECT 
         tbItem.cod_emp
         ,tbItem.cod_fil
         ,tbItem.ano_solic
         ,tbItem.num_solic
         ,tbItem.num_item
         ,tbUpdCanc.OpenQuantity UpdCanc_Qtde
         ,tbUpdCanc.Price UpdCanc_Price
         ,tbUpdCanc.FreeText UpdCanc_FreeText
         ,tbUpdCanc.BuyUnitMsr UpdCanc_UndCompra
         ,tbUpdCanc.SalUnitMsr UpdCanc_UndVenda
         ,tbUpdCanc.InvntryUom UpdCanc_UndEst
         ,tbItem.BaseQty Item_Qtde
         ,tbItem.Price Item_Price
         ,tbItem.Observacoes Item_FreeText
         ,tbItem.buyUnitMsr Item_UndCompra
         ,tbItem.salUnitMsr Item_UndVenda
         ,tbItem.invntryUom Item_UndEst
         ,0 AS flg_processado
   FROM tbintegraSAP_UpdCancPV tbUpdCanc
   INNER JOIN tbintegraSAP_DocItem tbItem ON 
         tbUpdCanc.DocumentType = tbItem.DocTipo 
     AND tbUpdCanc.DocumentId = tbItem.DocEntry 
     AND tbUpdCanc.DocumentNumber = tbItem.DocNum 
     AND tbUpdCanc.LineNumber = tbItem.LineNum
     AND tbUpdCanc.cod_emp IS NULL;


START TRANSACTION;
  

WHILE EXISTS (SELECT 1 FROM tbTMPUpdCanc WHERE flg_processado = 0) DO

   SELECT tbItem.cod_emp
         ,tbItem.cod_fil
         ,tbItem.ano_solic
         ,tbItem.num_solic
         ,tbItem.num_item
         ,tbUpdCanc.OpenQuantity UpdCanc_Qtde
         ,tbUpdCanc.Price UpdCanc_Price
         ,tbUpdCanc.FreeText UpdCanc_FreeText
         ,tbUpdCanc.BuyUnitMsr UpdCanc_UndCompra
         ,tbUpdCanc.SalUnitMsr UpdCanc_UndVenda 
         ,tbUpdCanc.InvntryUom UpdCanc_UndEst
         ,tbItem.BaseQty Item_Qtde
         ,tbItem.Price Item_Price 
         ,tbItem.Observacoes Item_FreeText
         ,tbItem.buyUnitMsr Item_UndCompra
         ,tbItem.salUnitMsr Item_UndVenda
         ,tbItem.invntryUom Item_UndEst
   INTO   xcod_emp 
         ,xcod_fil
         ,xano_solic 
         ,xnum_solic
         ,xnum_item
         ,xUpdCanc_Qtde
         ,xUpdCanc_Price
         ,xUpdCanc_FreeText
         ,xUpdCanc_UndCompra
         ,xUpdCanc_UndVenda
         ,xUpdCanc_UndEst
         ,xItem_Qtde
         ,xItem_Price
         ,xItem_FreeText
         ,xItem_UndCompra
         ,xItem_UndVenda
         ,xItem_UndEst
   FROM tbTMPUpdCanc 
   WHERE flg_processado = 0
   LIMIT 1;



   /*********************************************************************************
   #Verifica se tem checkout e se está conferido
   *********************************************************************************/
   SET xTemFlgCheckout = FALSE;
   SET xCheckoutConf = FALSE;
   SELECT IF(num_item IS NULL, FALSE, TRUE) AS TemFlgCheckout, 
          IF(qtde_conf_est2 IS NULL, FALSE, TRUE) AS CheckoutConf 
   INTO xTemFlgCheckout, xCheckoutConf 
   FROM of_elinox.tbsolic_saidas_volume_item tbCheckoutItem
   WHERE tbCheckoutItem.cod_emp   = xcod_emp
     AND tbCheckoutItem.cod_fil   = xcod_fil
     AND tbCheckoutItem.ano_solic = xano_solic
     AND tbCheckoutItem.num_solic = xnum_solic
     AND tbCheckoutItem.num_item = xnum_item;


   /*********************************************************************************
   #Verifica status de conferencia do item # 0=Em aberto, 1=em conferencia, 2=Conferido
   *********************************************************************************/
   SET xItemAconselhado = FALSE;
   SET xStatusConferencia = 0;  
   SELECT IF(dthr_aconselhamento IS NULL, FALSE, TRUE) AS ItemAconselhado, 
          IF(dthr_inicio_baixa_geral IS NULL, 0, IF(dthr_final_baixa_geral IS NULL, 1, 2)) AS StatusConferencia
   INTO xItemAconselhado, xStatusConferencia 
   FROM of_elinox.tbsolic_saidas_item tbCheckoutItem
   WHERE tbCheckoutItem.cod_emp   = xcod_emp
     AND tbCheckoutItem.cod_fil   = xcod_fil
     AND tbCheckoutItem.ano_solic = xano_solic
     AND tbCheckoutItem.num_solic = xnum_solic
     AND tbCheckoutItem.num_item = xnum_item;



   IF xStatusConferencia > 0 THEN   
      /*********************************************************************************
      #Reabrir conferencia de amarrado do iten excluído 
      #Reabrir separacao de amarrados do iten excluído
      *********************************************************************************/
      UPDATE of_elinox.tbsolic_saidas_volume tbCheckoutVolume
      INNER JOIN of_elinox.tbsolic_saidas_volume_item tbCheckoutItem ON 
               tbCheckoutItem.id_volume_saida = tbCheckoutVolume.id_volume_saida
      SET  tbCheckoutVolume.dthr_conf_ini2 = NULL
          ,tbCheckoutVolume.dthr_conf_fin2 = NULL
          ,tbCheckoutVolume.dthr_sep_fin = NULL
      WHERE tbCheckoutItem.cod_emp   = xcod_emp
        AND tbCheckoutItem.cod_fil   = xcod_fil
        AND tbCheckoutItem.ano_solic = xano_solic
        AND tbCheckoutItem.num_solic = xnum_solic
        AND tbCheckoutItem.num_item = xnum_item;


      /*********************************************************************************
      #Excluir o item dos amarrados
      *********************************************************************************/
      DELETE FROM of_elinox.tbsolic_saidas_volume_item 
      WHERE of_elinox.tbsolic_saidas_volume_item.cod_emp   = xcod_emp
        AND of_elinox.tbsolic_saidas_volume_item.cod_fil   = xcod_fil
        AND of_elinox.tbsolic_saidas_volume_item.ano_solic = xano_solic
        AND of_elinox.tbsolic_saidas_volume_item.num_solic = xnum_solic
        AND of_elinox.tbsolic_saidas_volume_item.num_item  = xnum_item;


      /*********************************************************************************
      #Excluir amarrados sem itens
      /********************************************************************************/
      DELETE FROM of_elinox.tbsolic_saidas_volume 
      WHERE NOT EXISTS (SELECT 1 FROM of_elinox.tbsolic_saidas_volume_item tbCheckoutItem
                        WHERE tbCheckoutItem.id_volume_saida = of_elinox.tbsolic_saidas_volume.id_volume_saida);


      
      #PROC_WMS_SAIDA_CANCELAR_GSM_INTEGRACAO


      /*********************************************************************************
      #Reabrir a conferencia do Item
      /********************************************************************************/




      /*********************************************************************************
      #Atualizar Status da GSM
      /********************************************************************************/







      /**************************************************/
      #Atualiza registro de pendencias a processar (dados gem/gsm)
      #como flag atualizado
      /**************************************************/
      UPDATE tbintegraSAP_UpdCancPV tbUpdCanc
      INNER JOIN tbintegraSAP_DocItem tbItem ON 
            tbUpdCanc.DocumentType = tbItem.DocTipo 
        AND tbUpdCanc.DocumentId = tbItem.DocEntry 
        AND tbUpdCanc.DocumentNumber = tbItem.DocNum 
        AND tbUpdCanc.LineNumber = tbItem.LineNum
      SET  tbUpdCanc.cod_emp   = tbItem.cod_emp
          ,tbUpdCanc.cod_fil   = tbItem.cod_fil
          ,tbUpdCanc.ano_solic = tbItem.ano_solic
          ,tbUpdCanc.num_solic = tbItem.num_solic
          ,tbUpdCanc.num_item  = tbItem.num_item
      WHERE tbUpdCanc.cod_emp IS NULL;
      #rollback;

END WHILE;

COMMIT;
