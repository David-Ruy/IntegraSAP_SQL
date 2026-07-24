DELIMITER $$

DROP PROCEDURE IF EXISTS `PROC_SYS_GerarTabelaComTexto`$$

CREATE PROCEDURE `PROC_SYS_GerarTabelaComTexto`( IN oTexto			    TEXT 
	,IN oSeparador		 CHAR(1)  	
	,IN oQtdeColunas	INT
)
BEGIN
  # PROCEDURE PARA GERAR TABELA TEMPORÁRIA A PARTIR DE UM TEXTO 
  # @author Érico Forcinetti <2017/05/11>
  # @company Overflash Informática Ltda
  
  /** 
   * ------------------------ INFORMAÇÕES ADICIONAIS -----------------------
   *
   * CRIAR A TABELA TEMPORÁRIA ABAIXO NA APLICAÇÃO QUER IRÁ CONSUMIR ESSA ROTINA:
   * 
   * DROP TEMPORARY TABLE IF EXISTS tTabelaComTexto;
   *
   * CREATE TEMPORARY TABLE tTabelaComTexto ( Coluna01 VARCHAR(100)
   *                                        , Coluna02 VARCHAR(100) 
   *                                        , Coluna03 VARCHAR(100)
   *                                        , Coluna04 VARCHAR(100)
   *                                        , Coluna05 VARCHAR(100)
   *                                        , Coluna06 VARCHAR(100)
   *                                        ); 
   *
   * ---------------------- FIM INFORMAÇÕES ADICIONAIS ---------------------
   */
  /****************************************************************/
  /****************DECLARAR VARIÁVEIS AUXLIARES 
  /****************************************************************/
  
  DECLARE _Valor    VARCHAR(100) DEFAULT '';
  DECLARE _Valor1   VARCHAR(100) DEFAULT '';
  DECLARE _Valor2   VARCHAR(100) DEFAULT '';
  DECLARE _Valor3   VARCHAR(100) DEFAULT '';
  DECLARE _Valor4   VARCHAR(100) DEFAULT '';
  DECLARE _Valor5   VARCHAR(100) DEFAULT '';
  DECLARE _Valor6   VARCHAR(100) DEFAULT '';
  DECLARE _iPos     INT          DEFAULT 0;
  DECLARE _iColuna  INT          DEFAULT 1; 
  DECLARE _iInsere  INT          DEFAULT 0;
 
  /****************************************************************/
  /****************CERTIFICAR QUE TODOS OS DADOS FORAM EXCLUÍDOS 
  /****************************************************************/
  
  DROP TEMPORARY TABLE IF EXISTS tTabelaComTexto;
  
  CREATE TEMPORARY TABLE tTabelaComTexto ( Coluna01 VARCHAR(100)
                                         , Coluna02 VARCHAR(100) 
                                         , Coluna03 VARCHAR(100)
                                         , Coluna04 VARCHAR(100)
                                         , Coluna05 VARCHAR(100)
                                         , Coluna06 VARCHAR(100)
                                         ); 
  
  /****************************************************************/
  /****************CERTIFICAR QUE TODOS OS DADOS FORAM EXCLUÍDOS 
  /****************************************************************/
  DELETE FROM tTabelaComTexto; 
  /****************************************************************/
  /****************INTEGRIDADE DE SOMENTE 6 COLUNAS DE RETORNO 
  /****************************************************************/
  
  IF (oQtdeColunas > 6) THEN 
  BEGIN 
    SET oTexto = ''; 
  END;  
  END IF; 
  
  /****************************************************************/
  /****************PROCESSAR 
  /****************************************************************/
  
  WHILE (_iPos < LENGTH(oTexto)) DO 
  BEGIN
    SET _iPos = _iPos + 1; 
    IF (SUBSTRING(oTexto, _iPos, 1) = oSeparador) THEN 
    BEGIN
      
     
       IF (_iColuna = 1) THEN SET _Valor1 = _Valor;    
      ELSEIF (_iColuna = 2) THEN SET _Valor2 = _Valor;
      ELSEIF (_iColuna = 3) THEN SET _Valor3 = _Valor;
      ELSEIF (_iColuna = 4) THEN SET _Valor4 = _Valor;
      ELSEIF (_iColuna = 5) THEN SET _Valor5 = _Valor;
      ELSEIF (_iColuna = 6) THEN SET _Valor6 = _Valor;
      END IF; 
      
      SET _iColuna = _iColuna + 1; 
      IF (_iColuna > oQtdeColunas) THEN 
      BEGIN
     INSERT INTO tTabelaComTexto 
           VALUES ( _Valor1
                  , _Valor2
                  , _Valor3
                  , _Valor4
                  , _Valor5
                  , _Valor6
                  ); 
     SET _iColuna = 1;			
     SET _Valor1  = '';
     SET _Valor2  = '';
     SET _Valor3  = '';
     SET _Valor4  = '';
     SET _Valor5  = '';
     SET _Valor6  = '';
     SET _iInsere = 0;
      
      END; 
      END IF; 
       
      SET _Valor = ''; 
   END; 
   ELSE
   BEGIN
     
      SET _Valor   = CONCAT(_Valor, SUBSTRING(oTexto, _iPos, 1)); 
      SET _iInsere = 1; 
   END;
   END IF; 
  
  END;
  END WHILE; 
  IF (_iInsere = 1) THEN 
  BEGIN
   
         IF (_iColuna = 1) THEN SET _Valor1 = _Valor;    
     ELSEIF (_iColuna = 2) THEN SET _Valor2 = _Valor;
     ELSEIF (_iColuna = 3) THEN SET _Valor3 = _Valor;
     ELSEIF (_iColuna = 4) THEN SET _Valor4 = _Valor;
     ELSEIF (_iColuna = 5) THEN SET _Valor5 = _Valor;
     ELSEIF (_iColuna = 6) THEN SET _Valor6 = _Valor;
     END IF;
      
     INSERT INTO tTabelaComTexto 
          VALUES ( _Valor1
                 , _Valor2
                 , _Valor3
                 , _Valor4
                 , _Valor5
                 , _Valor6
                 ); 
  END;
  END IF; 
END$$

DELIMITER ;