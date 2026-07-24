DELIMITER $$

DROP PROCEDURE IF EXISTS `PROC_INTEGRA_CAD_Destinatario`$$

CREATE PROCEDURE `PROC_INTEGRA_CAD_Destinatario`( IN oCodUsuario				     VARCHAR(10)
, IN oCNPJCliente        VARCHAR(14)
,	IN oCNPJCPF					       VARCHAR(14)
,	IN oTipoPessoa				     VARCHAR(01)
,	IN oRazSocial				      VARCHAR(100)
,	IN oNomeFantasia		     VARCHAR(100)
,	IN oInscrEstadual	     VARCHAR(20)
,	IN oIndicadorIE			     VARCHAR(1)
,	IN oEndereco				       VARCHAR(100)
,	IN oNumEnde					       VARCHAR(30)
,	IN oComplEnde			       VARCHAR(200)
,	IN oBairroEnde		       VARCHAR(50)
,	IN oCidadeEnde		       VARCHAR(50)
,	IN oUFEnde					        VARCHAR(02)
,	IN oCepEnde					       VARCHAR(10)
,	IN oContato01			       VARCHAR(20)
,	IN oFone01 					       VARCHAR(20)
,	IN oEmail01 				       VARCHAR(40)
,	IN oStatusAtivo	       VARCHAR(01)
, IN ohora1_entrega      VARCHAR(20)
, IN ohora2_entrega      VARCHAR(20)
, IN ohora3_entrega      VARCHAR(20)
, IN ohora4_entrega      VARCHAR(20)
,	OUT RESULTADO     VARCHAR(5)
,	OUT MENSAGEM      VARCHAR(500)
)
BLOCO1:BEGIN
  # PROCEDURE INTEGRAÇÃO PARA CADASTRO DE DESTINATÁRIO
  # @author David Ruy
  # @company Overflash
  
  /**
   * ------------------------ INFORMAÇÕES ADICIONAIS -----------------------
   *
   *
   * ---------------------- FIM INFORMAÇÕES ADICIONAIS ---------------------
   */
  
  /****************************************************************/
  /****************DECLARAR VARIÁVEIS AUXILIARES
  /****************************************************************/
  
  DECLARE xIncAlt   VARCHAR(01)	DEFAULT 'I';
  DECLARE xemp_rota VARCHAR(03);
  DECLARE xfil_rota VARCHAR(03);
  DECLARE xcod_rota VARCHAR(10);
  
  /****************************************************************/
  /****************CONTROLE DE EXCEÇÃO DE SQL
  /****************************************************************/
  
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    
    GET DIAGNOSTICS CONDITION 1 MENSAGEM = MESSAGE_TEXT;
  
    ROLLBACK;
    SET RESULTADO = 'FALSE';
    SET MENSAGEM  = MENSAGEM;
  END;
   SET oCepEnde = fnSoNumeros(oCepEnde,"");
   SET ohora1_entrega = SUBSTRING(ohora1_entrega,1,5);
   SET ohora2_entrega = SUBSTRING(ohora2_entrega,1,5);
   SET ohora3_entrega = SUBSTRING(ohora3_entrega,1,5);
   SET ohora4_entrega = SUBSTRING(ohora4_entrega,1,5);
   
  /****************************************************************/
  /****************VERIFICAR ALTERAÇÃO
  /****************************************************************/
  
  IF EXISTS( SELECT 1 
               FROM of_logistica.tbdestinatarios
              WHERE of_logistica.tbdestinatarios.cnpj_cpf_cliente = oCNPJCliente
                AND of_logistica.tbdestinatarios.cod_integracao   = oCNPJCPF
           ) 
  THEN
   
    SET xIncAlt = 'A';
  
  END IF;
  
  /*******************************************************************
  #Tratar e Validar as variáveis Destinatário
  # Se enviar oStatusAtivo em branco, não realiza validações de todos os campos
  *******************************************************************/
  
  IF IFNULL(oStatusAtivo,'') = '' THEN
     IF TRIM(IFNULL(oCNPJCPF,'')) = '' THEN
         SET MENSAGEM = "CNPJ/CPF Inválido";
     ELSEIF TRIM(IFNULL(oRazSocial,'')) = '' THEN
         SET MENSAGEM = "Razão Social Inválida";
     END IF;
  ELSE
     SET MENSAGEM = '';
     SET oIndicadorIE = TRIM(IFNULL(oIndicadorIE, ''));
     IF TRIM(IFNULL(oCNPJCPF,'')) = '' THEN
         SET MENSAGEM = "CNPJ/CPF Inválido";
     ELSEIF TRIM(IFNULL(oTipoPessoa,'')) NOT IN ('F','J','O') THEN
         SET MENSAGEM = "Tipo Pessoa Inválido";
     ELSEIF TRIM(IFNULL(oRazSocial,'')) = '' THEN
         SET MENSAGEM = "Razão Social Inválida";
     ELSEIF TRIM(IFNULL(oNomeFantasia,'')) = '' THEN
         SET MENSAGEM = "Nome Fantasia Inválida";
     #ELSEIF (oIndicadorIE = "") OR (oIndicadorIE NOT IN ('1','2','9')) THEN
     #    SET MENSAGEM = "Indicador de Inscrição Estadual inválido";
     #ELSEIF oIndicadorIE <> '9' AND (TRIM(IFNULL(oInscrEstadual,'')) = '') THEN
     #    SET MENSAGEM = "Inscrição Estadual Destinatário inválida";
     #ELSEIF TRIM(IFNULL(oEndereco,'')) = '' THEN
     #    SET MENSAGEM = "Endereço Inválido";
     #ELSEIF TRIM(IFNULL(oNumEnde,'')) = '' THEN
     #    SET MENSAGEM = "N° (Endereço) Inválido";
     #ELSEIF TRIM(IFNULL(oBairroEnde,'')) = '' THEN
     #    SET MENSAGEM = "Bairro Inválido";
     #ELSEIF TRIM(IFNULL(oCidadeEnde,'')) = '' THEN
     #    SET MENSAGEM = "Cidade Inválido";
     #ELSEIF TRIM(IFNULL(oUFEnde,'')) = '' THEN
     #    SET MENSAGEM = "UF Inválido";
     #ELSEIF (TRIM(IFNULL(oCepEnde,'')) = '') OR (fnSoNumeros(oCepEnde,"") <> oCepEnde) OR (NOT LENGTH(TRIM(oCepEnde)) = 8) THEN
     #    SET MENSAGEM = "CEP Inválido";
     END IF;
   END IF;
   IF MENSAGEM <> '' THEN
      SET RESULTADO = 'FALSE';
      LEAVE BLOCO1;
   END IF;
   
   
   #Buscar ROTA através do CEP
   SELECT #@oCidadeEnde, @oUFEnde, @oCepEnde, 
          tbrotas.cod_emp, tbrotas.cod_fil, tbrotas.cod_rota 
          #,tbrotas.descr_rota, tbrotas_cep.cep_ini, tbrotas_cep.cep_fin
   INTO xemp_rota, xfil_rota, xcod_rota
   FROM of_logistica.tbrotas
   LEFT JOIN of_logistica.tbrotas_cep ON 
              tbrotas_cep.cod_emp = tbrotas.cod_emp
          AND tbrotas_cep.cod_fil = tbrotas.cod_fil
          AND tbrotas_cep.cod_rota = tbrotas.cod_rota
   WHERE oCepEnde BETWEEN tbrotas_cep.cep_ini AND tbrotas_cep.cep_fin
   LIMIT 1;
   
   #Se não localizou pelo CEP, Buscar ROTA através da cidade
   IF xemp_rota IS NULL THEN
      SELECT #@oCidadeEnde, @oUFEnde, @oCepEnde, 
             tbrotas.cod_emp, tbrotas.cod_fil, tbrotas.cod_rota
             #tbrotas.descr_rota, tbcidades.nome_cidade
      INTO xemp_rota, xfil_rota, xcod_rota          
      FROM of_logistica.tbrotas 
      LEFT JOIN of_logistica.tbrotas_cidade ON
                tbrotas_cidade.cod_emp  = tbrotas.cod_emp
            AND tbrotas_cidade.cod_fil  = tbrotas.cod_fil
            AND tbrotas_cidade.cod_rota = tbrotas.cod_rota
      LEFT JOIN of_logistica.tbcidades ON
                tbcidades.cod_cidade = tbrotas_cidade.cod_cidade
      WHERE tbcidades.nome_cidade = oCidadeEnde
        AND tbcidades.sig_estado  = oUFEnde
      LIMIT 1;
     END IF;
     
     
     #@Reviser David Ruy <2022-03-15>
     SET oTipoPessoa = UPPER(oTipoPessoa);
     SET oRazSocial = UPPER(oRazSocial);
     SET oNomeFantasia = UPPER(oNomeFantasia);
     SET oEndereco = UPPER(oEndereco);
     SET oNumEnde = UPPER(oNumEnde);
     SET oComplEnde = UPPER(oComplEnde);
     SET oBairroEnde = UPPER(oBairroEnde);
     SET oCidadeEnde = UPPER(oCidadeEnde);
     SET oUFEnde = UPPER(oUFEnde);
     SET oCepEnde = UPPER(oCepEnde);
     SET oContato01 = UPPER(oContato01);
     SET oFone01 = UPPER(oFone01);
     SET oEmail01 = UPPER(oEmail01);
     SET oCNPJCPF = UPPER(oCNPJCPF);
     SET oCNPJCliente = UPPER(oCNPJCliente);
     
 
   
  IF xIncAlt = 'I' THEN
  BEGIN 
  
    INSERT INTO of_logistica.tbdestinatarios( cnpj_cpf
                                         , tipo_pessoa
                                         , raz_social
                                         , nome_fantasia
                                         , inscr_estadual
                                         , idIEDest
                                         , endereco
                                         , num_ende
                                         , compl_ende
                                         , bairro
                                         , nome_cidade
                                         , sig_estado
                                         , cep_ende
                                         , contato
                                         , telefone
                                         , email
                                         , cnpj_aux
                                         , cnpj_cpf_cliente
                                         , hora1_entrega
                                         , hora2_entrega
                                         , hora3_entrega
                                         , hora4_entrega
                                         , emp_rota
                                         , fil_rota
                                         , cod_rota
                                         , cod_integracao
                                         , dthr_inc
                                         , usu_inc
                                         )
                                  VALUES ( oCNPJCPF
                                         #, IF(IFNULL(oTipoPessoa,"O")="", "O", IFNULL(oTipoPessoa,"O"))
                                         , IF(IFNULL(oTipoPessoa,"J")="", "J", IFNULL(oTipoPessoa,"J"))
                                         , SUBSTRING(oRazSocial,1, 60)
                                         , SUBSTRING(oNomeFantasia,1, 50)
                                         , oInscrEstadual
                                         , oIndicadorIE
                                         , SUBSTRING(oEndereco,1,50)
                                         , SUBSTRING(oNumEnde,1,10)
                                         , SUBSTRING(oComplEnde,1,30)
                                         , SUBSTRING(oBairroEnde,1,50)
                                         , SUBSTRING(oCidadeEnde,1,50)
                                         , SUBSTRING(oUFEnde,1,2)
                                         , SUBSTRING(oCepEnde,1,8)
                                         , oContato01
                                         , oFone01
                                         , oEmail01
                                         , oCNPJCPF
                                         , oCNPJCliente
                                         , ohora1_entrega
                                         , ohora2_entrega
                                         , ohora3_entrega
                                         , ohora4_entrega
                                         , xemp_rota
                                         , xfil_rota
                                         , xcod_rota                                      
                                         , oCNPJCPF
                                         , NOW()
                                         , oCodUsuario
                                         );
     SET RESULTADO = 'TRUE';
     SET MENSAGEM = "Registro Inserido com sucesso";
  
  END; 
  ELSE
  BEGIN 
  
    UPDATE of_logistica.tbdestinatarios 
       SET tbdestinatarios.tipo_pessoa	     =	oTipoPessoa
         , tbdestinatarios.raz_social		     =	SUBSTRING(oRazSocial,01,60)
         , tbdestinatarios.nome_fantasia	   =	SUBSTRING(oNomeFantasia,01,50)
         , tbdestinatarios.inscr_estadual	  =	oInscrEstadual
         , tbdestinatarios.idIEDest         = oIndicadorIE
         , tbdestinatarios.endereco		       =	SUBSTRING(oEndereco,1,50)
         , tbdestinatarios.num_ende		       =	SUBSTRING(oNumEnde,1,10)
         , tbdestinatarios.compl_ende		     =	SUBSTRING(oComplEnde,1,30)
         , tbdestinatarios.bairro			        =	SUBSTRING(oBairroEnde,1,50)
         , tbdestinatarios.nome_cidade	     =	SUBSTRING(oCidadeEnde,1,50)
         , tbdestinatarios.sig_estado		     =	SUBSTRING(oUFEnde,1,2)
         , tbdestinatarios.cep_ende		       =	SUBSTRING(oCepEnde,1,8)
         , tbdestinatarios.contato		        =	oContato01
         , tbdestinatarios.telefone		       =	oFone01
         , tbdestinatarios.email			         =	oEmail01
         , tbdestinatarios.hora1_entrega    = IFNULL(ohora1_entrega,tbdestinatarios.hora1_entrega)
         , tbdestinatarios.hora2_entrega    = IFNULL(ohora2_entrega,tbdestinatarios.hora2_entrega)
         , tbdestinatarios.hora3_entrega    = IFNULL(ohora3_entrega,tbdestinatarios.hora3_entrega)
         , tbdestinatarios.hora4_entrega    = IFNULL(ohora4_entrega,tbdestinatarios.hora4_entrega)
         , tbdestinatarios.emp_rota         = IFNULL(tbdestinatarios.emp_rota, xemp_rota)
         , tbdestinatarios.fil_rota         = IFNULL(tbdestinatarios.fil_rota, xfil_rota)
         , tbdestinatarios.cod_rota         = IFNULL(tbdestinatarios.cod_rota, xcod_rota)
         , tbdestinatarios.flg_ativo        = 1
         , tbdestinatarios.dthr_alt 	       = NOW()
         , tbdestinatarios.usu_alt 		       = oCodUsuario
     WHERE tbdestinatarios.cnpj_cpf_cliente = oCNPJCliente
       AND tbdestinatarios.cod_integracao   = oCNPJCPF;
     SET RESULTADO = 'TRUE';
     SET MENSAGEM  = "Registro Atualizado com sucesso";
  
  END; 
  END IF;
END$$

DELIMITER ;