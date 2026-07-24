DELIMITER $$

DROP FUNCTION IF EXISTS `fnSoNumeros`$$

CREATE FUNCTION `fnSoNumeros`( oString VARCHAR(100)
, oExcecao VARCHAR(10)
) RETURNS VARCHAR(100) CHARSET latin1
    NO SQL
BEGIN
	DECLARE xstrPadrao VARCHAR(50);
	DECLARE xvar_str   VARCHAR(100);
	DECLARE xcont	     INT;
	DECLARE xtamanho   INT;
	DECLARE xnew_str   VARCHAR(100);
	
  #String Padrão
  SET xstrPadrao = '0123456789';
  #String Padrão + Exceções de Parametro
  SET xstrPadrao = CONCAT(xstrPadrao,oExcecao);
  #Substitui os caracteres que não estão na Exceção por "»" a string principal
  SET xvar_str := TRIM(oString);
	SET xcont = 1;
	SET xnew_str = '';
  
  SET xtamanho = LENGTH(xvar_str);
  WHILE xcont <= xtamanho DO
		IF LOCATE(SUBSTRING(xvar_str, xcont,1),xstrPadrao) = 0 THEN
		  SET xnew_str = CONCAT(xnew_str, '»');
		ELSE 
		  SET xnew_str = CONCAT(xnew_str,SUBSTRING(xvar_str, xcont,1));
		END IF;
    SET xcont = xcont + 1;
  END WHILE;
  #Limpa os [»]
  SET xvar_str = REPLACE(SUBSTRING(xnew_str, 1,LENGTH(xnew_str)), '»', '');
  #Retorno da Função
  RETURN TRIM(xvar_str);
END$$

DELIMITER ;