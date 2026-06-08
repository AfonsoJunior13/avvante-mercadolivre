create or replace procedure horus.PRC_MLAPI_ORDEM_UPDATE
(
  P_UNIDADE_EMPRESARIAL_ID in  MERC_LIVRE_ORDEM.UNIDADE_EMPRESARIAL_ID %type,
  P_MLOR_ORDER_ID          in  MERC_LIVRE_ORDEM.MLOR_ORDER_ID          %type,
  P_MLOR_STATUS            in  MERC_LIVRE_ORDEM.MLOR_STATUS            %type,
  P_MLOR_DATE_CREATED      in  MERC_LIVRE_ORDEM.MLOR_DATE_CREATED      %type,
  P_MLOR_DATE_CLOSED       in  MERC_LIVRE_ORDEM.MLOR_DATE_CLOSED       %type,
  P_MLOR_VALOR             in  MERC_LIVRE_ORDEM.MLOR_VALOR             %type,
  P_MLOR_ENDERECO          in  MERC_LIVRE_ORDEM.MLOR_ENDERECO          %type,
  P_MLOR_NUMERO            in  MERC_LIVRE_ORDEM.MLOR_NUMERO            %type,
  P_MLOR_COMPLEMENTO       in  MERC_LIVRE_ORDEM.MLOR_COMPLEMENTO       %type,
  P_MLOR_BAIRRO            in  MERC_LIVRE_ORDEM.MLOR_BAIRRO            %type,
  P_MLOR_CIDADE            in  MERC_LIVRE_ORDEM.MLOR_CIDADE            %type,
  P_MLOR_UF                in  MERC_LIVRE_ORDEM.MLOR_UF                %type,
  P_MLOR_CEP               in  MERC_LIVRE_ORDEM.MLOR_CEP               %type,
  P_MLOR_CPF_CNPJ          in  MERC_LIVRE_ORDEM.MLOR_CPF_CNPJ          %type,
  P_MLOR_NOME              in  MERC_LIVRE_ORDEM.MLOR_NOME              %type,
  P_MLOR_VLR_FRETE         in  MERC_LIVRE_ORDEM.MLOR_VLR_FRETE         %type,  
  P_MLOR_VLR_TAXA_ML       in  MERC_LIVRE_ORDEM.MLOR_VLR_TAXA_ML       %type, 
  P_MLOR_DESCONTO          in  MERC_LIVRE_ORDEM.MLOR_DESCONTO          %type,    
  
  P_TRANSACTION            in  number

) is
  
  V_MERC_LIVRE_ORDEM_ID  MERC_LIVRE_ORDEM.MERC_LIVRE_ORDEM_ID %type;

begin
   
   begin
     select M.MERC_LIVRE_ORDEM_ID
       into V_MERC_LIVRE_ORDEM_ID
       from MERC_LIVRE_ORDEM M
      where MLOR_ORDER_ID = P_MLOR_ORDER_ID;      
   exception when NO_DATA_FOUND then
     V_MERC_LIVRE_ORDEM_ID := null; 
   end;
   
   if V_MERC_LIVRE_ORDEM_ID is null then
     V_MERC_LIVRE_ORDEM_ID := GENERATE_NEXT_ID('MERC_LIVRE_ORDEM','UserSystem','TermSystem');
       
     insert into MERC_LIVRE_ORDEM(MERC_LIVRE_ORDEM_ID    ,MLOR_ORDER_ID     ,
                                  UNIDADE_EMPRESARIAL_ID ,MLOR_STATUS       ,
                                  MLOR_DATE_CREATED      ,MLOR_DATE_CLOSED  ,
                                  MLOR_VALOR             ,MLOR_ENDERECO     ,
                                  MLOR_NUMERO            ,MLOR_COMPLEMENTO  ,
                                  MLOR_BAIRRO            ,MLOR_CIDADE       ,
                                  MLOR_UF                ,MLOR_CEP          ,
                                  MLOR_CPF_CNPJ          ,MLOR_NOME         ,
                                  MLOR_VLR_FRETE         ,MLOR_VLR_TAXA_ML  ,
                                  MLOR_DESCONTO          ,
                                  USUARIO_INCLUSAO       ,DATA_INCLUSAO     ,
                                  STATUS                 )
                                         
     values                      (V_MERC_LIVRE_ORDEM_ID    ,P_MLOR_ORDER_ID     ,
                                  P_UNIDADE_EMPRESARIAL_ID ,P_MLOR_STATUS       ,
                                  P_MLOR_DATE_CREATED      ,P_MLOR_DATE_CLOSED  ,
                                  P_MLOR_VALOR             ,P_MLOR_ENDERECO     ,
                                  P_MLOR_NUMERO            ,P_MLOR_COMPLEMENTO  ,
                                  P_MLOR_BAIRRO            ,P_MLOR_CIDADE       ,
                                  P_MLOR_UF                ,P_MLOR_CEP          ,
                                  P_MLOR_CPF_CNPJ          ,P_MLOR_NOME         ,
                                  P_MLOR_VLR_FRETE         ,P_MLOR_VLR_TAXA_ML  ,
                                  P_MLOR_DESCONTO          ,
                                  'UserSystem'             ,sysdate             ,
                                  'Ativo'                  );     
   else
     update MERC_LIVRE_ORDEM
        set MLOR_STATUS       = P_MLOR_STATUS,
            MLOR_DATE_CREATED = P_MLOR_DATE_CREATED,
            MLOR_DATE_CLOSED  = P_MLOR_DATE_CLOSED,  
            MLOR_VALOR        = P_MLOR_VALOR,
            MLOR_ENDERECO     = P_MLOR_ENDERECO,
            MLOR_NUMERO       = P_MLOR_NUMERO,
            MLOR_COMPLEMENTO  = P_MLOR_COMPLEMENTO,
            MLOR_BAIRRO       = P_MLOR_BAIRRO,
            MLOR_CIDADE       = P_MLOR_CIDADE,
            MLOR_UF           = P_MLOR_UF,
            MLOR_CEP          = P_MLOR_CEP,
            MLOR_CPF_CNPJ     = P_MLOR_CPF_CNPJ,
            MLOR_NOME         = P_MLOR_NOME,
            MLOR_VLR_FRETE    = P_MLOR_VLR_FRETE,
            MLOR_VLR_TAXA_ML  = P_MLOR_VLR_TAXA_ML,
            MLOR_DESCONTO     = P_MLOR_DESCONTO,
            DATA_ALTERACAO    = sysdate,
            USUARIO_ALTERACAO = 'UserSystem'
      where MERC_LIVRE_ORDEM_ID = V_MERC_LIVRE_ORDEM_ID;
   end if;   
  
   if P_TRANSACTION = 0 then
     commit;
   end if;

end PRC_MLAPI_ORDEM_UPDATE;
/

