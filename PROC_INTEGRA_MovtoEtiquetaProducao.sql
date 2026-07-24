DELIMITER $$

DROP PROCEDURE IF EXISTS `PROC_INTEGRA_MovtoEtiquetaProducao`$$

CREATE PROCEDURE `PROC_INTEGRA_MovtoEtiquetaProducao`(
   IN xTipoParam TINYINT,
   IN xCodEmp VARCHAR(03),
   IN xCodFil VARCHAR(03),
   IN xNumLote VARCHAR(20),
   IN xSeqLote INT,
   IN xBarCode VARCHAR(80)
)
BLOCO1:BEGIN
   /***************************************************************************
   #@Author David Ruy <2023/11/29>
   # Listar ou Atualizar Tabela de controle de Etiquetas de Produção SAP "lidas" no SLIN
   #               xTipoParam = 1 => Listagem dos registros | 2 => Insere/Atualiza tbintegraSAP_EtiquetaUA
   #@Reviser David Ruy <2023-12-01> Não retornar se a GEM ainda estiver aberta (dthr_confirm is not null) (DESABILITADO - SOLICITAÇÃO FELIPE PANIZZON)
   ****************************************************************************/
   DECLARE RESULTADO INT DEFAULT 1;
   DECLARE MENSAGEM VARCHAR(500);
   DECLARE excecao INT DEFAULT 0;
   DECLARE CONTINUE HANDLER FOR SQLEXCEPTION SET excecao = 1;
   
   
   IF xTipoParam = 1 THEN
      SELECT tbEst.cod_emp, tbEst.cod_fil, tbEst.num_lote, tbEst.sequencia_lote, tbEst.num_caixa_barcode,
             tbsolic_entradas_acons.dthr_conf, tbEst.data_fabr, tbEst.data_valid, tbEst.posicao_ant,
             CONCAT(tbEst.cod_und, "/", tbEst.cod_armazem, "-", 
                    tbEst.camara, ".", tbEst.rua, ".", tbEst.posicao, ".", tbEst.altura, ".", tbEst.profund) Endereco
      FROM of_logistica.tbwms_estoque tbEst
      INNER JOIN of_logistica.tbsolic_entradas_acons ON
                 tbsolic_entradas_acons.cod_emp  = tbEst.cod_emp 
             AND tbsolic_entradas_acons.cod_fil  = tbEst.cod_fil 
             AND tbsolic_entradas_acons.num_lote = tbEst.num_lote
             AND tbsolic_entradas_acons.sequencia_lote= tbEst.sequencia_lote
      /*INNER JOIN of_logistica.tbsolic_entradas ON
                 tbsolic_entradas.cod_emp   = tbEst.cod_emp 
             AND tbsolic_entradas.cod_fil   = tbEst.cod_fil 
             AND tbsolic_entradas.ano_solic = tbEst.ano_solic
             AND tbsolic_entradas.num_solic = tbEst.num_solic*/
      WHERE tbEst.num_caixa_barcode IS NOT NULL
      #AND tbsolic_entradas.dthr_confirm is not null
      AND tbsolic_entradas_acons.dthr_conf >= '2023-12-01'
      AND NOT EXISTS (SELECT 1 FROM tbintegraSAP_EtiquetaUA tbEtiq
                      WHERE tbEtiq.cod_emp  = tbEst.cod_emp
                        AND tbEtiq.cod_fil  = tbEst.cod_fil
                        AND tbEtiq.num_lote = tbEst.num_lote
                        AND tbEtiq.sequencia_lote = tbEst.sequencia_lote)
      #and tbEst.num_lote= '0000019611'
      #Limit 0
      ;
   
   ELSEIF xTipoParam = 2 THEN
   
      IF NOT EXISTS (SELECT 1 FROM tbintegraSAP_EtiquetaUA 
                     WHERE cod_emp   = xCodEmp
                       AND cod_fil   = xCodFil
                       AND num_lote  = xNumLote
                       AND sequencia_lote = xSeqLote) THEN
         INSERT INTO tbintegraSAP_EtiquetaUA (
            cod_emp, cod_fil, num_lote, sequencia_lote, barcode_etiqueta, dthr_inc)
         VALUES (xCodEmp, xCodFil, xNumLote, xSeqLote, xBarCode, NOW());
      END IF;
   END IF;
      
   IF excecao = 1 THEN
      SET RESULTADO = 0;
      SET MENSAGEM = CONCAT(xCodErro," - Erro SQL - Verifique com o Administrador");
      SELECT RESULTADO, MENSAGEM;
   ELSE    
      SET RESULTADO = 1;
      SET MENSAGEM  = 'Processo Realizado com sucesso!';
   END IF;
   
END$$

DELIMITER ;