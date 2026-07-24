DELIMITER $$

DROP PROCEDURE IF EXISTS `PROC_INTEGRA_MontaEndereco`$$

CREATE PROCEDURE `PROC_INTEGRA_MontaEndereco`(
	   IN  xEnd_Entrega     VARCHAR(500),
      OUT xLogradouro      VARCHAR(10),
      OUT xEndereco        VARCHAR(100),
      OUT xNumEnde         VARCHAR(30),
      OUT xComplEnde       VARCHAR(200),
      OUT xBairroEnde      VARCHAR(50),
      OUT xCepEnde         VARCHAR(10),
      OUT xCidadeEnde      VARCHAR(50),
      OUT xUFEnde          VARCHAR(10),
      OUT xPaisEnde        VARCHAR(50)
    )
BLOCO1:BEGIN
	/* PROCEDURE PARA DESMONTAR STRING COM ENDERECO EM VARIÁVEIS
	 * @author David Ruy <2021/08/20>
	 */
	 DECLARE _Logradouro    VARCHAR(30);
	 DECLARE _Endereco      VARCHAR(100);
	 DECLARE xStrAux   VARCHAR(100);
	
   #logradouro,endereço,numero <newline> complemento <newline> Bairro <newline> cep - Cidade - Estado <newline> pais
   SET xEnd_Entrega = REPLACE(xEnd_Entrega,'\n','|');
   SET xEnd_Entrega = REPLACE(xEnd_Entrega,'||','|#|');
   
   #Logradouro
   SET _Logradouro = SUBSTRING(xEnd_Entrega,1,LOCATE('|',xEnd_Entrega)); 
   SET xEnd_Entrega = REPLACE(xEnd_Entrega,_Logradouro,'');
   #Endereço
   SET _Endereco = SUBSTRING(xEnd_Entrega,1,LOCATE('|',xEnd_Entrega)); 
   SET xEnd_Entrega = REPLACE(xEnd_Entrega,_Endereco,'');
   
   #Numero
   SET xNumEnde = SUBSTRING(xEnd_Entrega,1,LOCATE('|',xEnd_Entrega)); 
   SET xEnd_Entrega = REPLACE(xEnd_Entrega,xNumEnde,'');
   
   #Complemento
   SET xComplEnde   = SUBSTRING(xEnd_Entrega,1,LOCATE('|',xEnd_Entrega));  
   SET xEnd_Entrega = REPLACE(xEnd_Entrega,xComplEnde,'');
   #Bairro
   SET xBairroEnde  = SUBSTRING(xEnd_Entrega,1,LOCATE('|',xEnd_Entrega));  
   SET xEnd_Entrega = REPLACE(xEnd_Entrega,xBairroEnde,'');
   #CEP
   SET xCepEnde  = SUBSTRING(xEnd_Entrega,1,LOCATE('|',xEnd_Entrega));  
   SET xEnd_Entrega = REPLACE(xEnd_Entrega,xCepEnde,'');
   #Cidade
   SET xCidadeEnde  = SUBSTRING(xEnd_Entrega,1,LOCATE('|',xEnd_Entrega));  
   SET xEnd_Entrega = REPLACE(xEnd_Entrega,xCidadeEnde,'');
   #UF
   SET xUFEnde = SUBSTRING(xEnd_Entrega,1,LOCATE('|',xEnd_Entrega));  
   SET xEnd_Entrega = REPLACE(xEnd_Entrega,xUFEnde,'');
   #País
   SET xPaisEnde = xEnd_Entrega;
         
   #Ajuste fino das variáveis
   SET xLogradouro = _Logradouro;
   SET xEndereco   = _Endereco;
   SET xLogradouro = REPLACE(xLogradouro,'|','');     SET xLogradouro = REPLACE(xLogradouro,'#','');   
   SET xEndereco   = REPLACE(xEndereco,'|','');       SET xEndereco   = REPLACE(xEndereco,'#','');   
   SET xNumEnde    = REPLACE(xNumEnde,'|','');        SET xNumEnde    = REPLACE(xNumEnde,'#','');
   SET xComplEnde  = REPLACE(xComplEnde,'|','');      SET xComplEnde  = REPLACE(xComplEnde,'#','');
   SET xBairroEnde = REPLACE(xBairroEnde,'|','');     SET xBairroEnde = REPLACE(xBairroEnde,'#','');
   SET xCepEnde    = REPLACE(xCepEnde,'|','');        SET xCepEnde    = REPLACE(xCepEnde,'#','');
   SET xCidadeEnde = REPLACE(xCidadeEnde,'|','');     SET xCidadeEnde = REPLACE(xCidadeEnde,'#','');
   SET xUFEnde     = REPLACE(xUFEnde,'|','');         SET xUFEnde     = REPLACE(xUFEnde,'#','');
				   
END$$

DELIMITER ;