create or replace procedure desenv.PRC_MLAPI_CLIENTE_INSERT
( 
  -- Parametros relativos aos campos da tabela...
  P_UNIDADE_EMPRESARIAL_ID in out UNIDADE_EMPRESARIAL.UNIDADE_EMPRESARIAL_ID %type,
  P_PARCEIRO_ID            in out PARCEIRO.PARCEIRO_ID                       %type,
  P_PRCR_CGC_CPF           in out PARCEIRO.PRCR_CGC_CPF                      %type,
  P_PRCR_NOME              in out PARCEIRO.PRCR_NOME                         %type,
  P_PRCR_ENDERECO          in out PARCEIRO.PRCR_ENDERECO                     %type,
  P_PRCR_COMPLEMENTO_END   in out PARCEIRO.PRCR_COMPLEMENTO_ENDERECO         %type,
  P_PRCR_NR_ENDERECO       in out PARCEIRO.PRCR_NR_ENDERECO                  %type,
  P_CEPX_CODIGO            in out CEP.CEPX_CODIGO                            %type,  
  P_BRRO_NOME              in out BAIRRO.BRRO_NOME                           %type,  
  P_PRCR_FONE              in out PARCEIRO.PRCR_FONE                         %type,
  P_PRCR_CELULAR           in out PARCEIRO.PRCR_CELULAR                      %type,
  P_PRCR_E_MAIL            in out PARCEIRO.PRCR_E_MAIL                       %type,  
  P_PSJR_INSCRICAO_EST     in out PESSOA_JURIDICA.PSJR_INSCRICAO_EST         %type,  
  P_PSJR_NOME_FANTASIA     in out PESSOA_JURIDICA.PSJR_NOME_FANTASIA         %type,
  P_PRCL_LIMCRE            in out PARAM_CLIENTE.PRCL_LIMCRE                  %type,
  
  -- Parametros de Controle... 
  P_ACTION       in out integer, 
  P_STATUS       in out varchar2, 
  P_TRANSACTION  in out integer, 
  P_USER         in out varchar2, 
  P_TERMINAL     in out varchar2, 
  P_MESSAGE      in out varchar2

) is   

  V_CRPR_DIGITO_VERIFICADOR varchar2(3);
  V_ESTR_EMPR_WORK          PARCEIRO.ESTR_EMPR_WORK         %type;
  V_PRCR_CODIGO_CLIENTE     PARCEIRO.PRCR_CODIGO_CLIENTE    %type;
  V_REGIAO_VENDA_ID         PARAM_CLIENTE.REGIAO_VENDA_ID   %type; 
  V_PRCR_TIPO_PESSOA        PARCEIRO.PRCR_TIPO_PESSOA       %type;
  V_BAIRRO_ID               BAIRRO.BAIRRO_ID                %type;
  V_CIDADE_ID               CIDADE.CIDADE_ID                %type;
  V_CEP_ID                  CEP.CEP_ID                      %type;

begin
  
  if P_ACTION = 101 then
    
    -- Tipo parceiro...
    if length(P_PRCR_CGC_CPF) = 14 then
      V_PRCR_TIPO_PESSOA := 'Juridica';
    else 
      V_PRCR_TIPO_PESSOA := 'Fisica';
    end if;
    
    -- parametros da unem
    select nvl(CR.CRPR_DIGITO_VERIFICADOR,'Nao'),
           substr(UE.UNIDADE_EMPRESARIAL_ID,1,12)
      into V_CRPR_DIGITO_VERIFICADOR, 
           V_ESTR_EMPR_WORK 
      from CORPORACAO          CR, 
           EMPRESA             EM, 
           UNIDADE_EMPRESARIAL UE
     where CR.CORPORACAO_ID          = EM.CORPORACAO_ID
       and EM.EMPRESA_ID             = UE.EMPRESA_ID
       and UE.UNIDADE_EMPRESARIAL_ID = P_UNIDADE_EMPRESARIAL_ID;
    
    -- Codigo do cliente...
    V_PRCR_CODIGO_CLIENTE := FNC_RET_CODIGO_PARCEIRO(P_UNIDADE_EMPRESARIAL_ID, null);
                        
    if V_CRPR_DIGITO_VERIFICADOR = 'Sim' then
      V_PRCR_CODIGO_CLIENTE := substr(V_PRCR_CODIGO_CLIENTE, 1, (length(V_PRCR_CODIGO_CLIENTE) - 1));
      V_PRCR_CODIGO_CLIENTE := (nvl(V_PRCR_CODIGO_CLIENTE, 0) + 1);  
      V_PRCR_CODIGO_CLIENTE := V_PRCR_CODIGO_CLIENTE || fnc_retorna_digito_parceiro(V_PRCR_CODIGO_CLIENTE);                  
    end if;
    
    -- Localiza o CEP...
    begin
      select CEP.CIDADE_ID,
             CEP.CEP_ID
        into V_CIDADE_ID,
             V_CEP_ID
        from CEP
       where CEP.CEPX_CODIGO = P_CEPX_CODIGO
         and CEP.STATUS      = 'Ativo';
    exception when others then
      Raise_application_error(-20000, 'CEP não candastrado. CEP: '||P_CEPX_CODIGO);
    end;
    
    -- Localiza o Bairro...
    begin
      select B.BAIRRO_ID
        into V_BAIRRO_ID
        from BAIRRO B
       where B.CIDADE_ID        = V_CIDADE_ID
         and UPPER(B.BRRO_NOME) = UPPER(P_BRRO_NOME)
         and B.STATUS           = 'Ativo';
    exception when NO_DATA_FOUND then
      Raise_application_error(-20000, 'Bairro não candastrado. Bairro: '||P_BRRO_NOME);
    end;
    
    P_PARCEIRO_ID := GENERATE_NEXT_ID('PARCEIRO', P_USER, P_TERMINAL);
    P_STATUS      := 'Ativo';
    
    insert into PARCEIRO(PARCEIRO_ID           ,PRCR_NOME          ,PRCR_CGC_CPF              , 
                         PRCR_CLIENTE          ,CEP_ID             ,ESTR_EMPR_WORK            ,                          
                         PRCR_CODIGO_CLIENTE   ,PRCR_TIPO_PESSOA   ,PRCR_FONE                 , 
                         PRCR_CELULAR          ,PRCR_ENDERECO      ,PRCR_COMPLEMENTO_ENDERECO , 
                         PRCR_NR_ENDERECO      ,PRCR_E_MAIL        ,BAIRRO_ID                 ,
                         DATA_INCLUSAO         ,USUARIO_INCLUSAO   ,STATUS                    )
         
         values         (P_PARCEIRO_ID         ,UPPER(P_PRCR_NOME) ,P_PRCR_CGC_CPF            , 
                         'Sim'                 ,V_CEP_ID           ,V_ESTR_EMPR_WORK          ,                          
                         V_PRCR_CODIGO_CLIENTE ,V_PRCR_TIPO_PESSOA ,P_PRCR_FONE               , 
                         P_PRCR_CELULAR        ,P_PRCR_ENDERECO    ,P_PRCR_COMPLEMENTO_END    , 
                         P_PRCR_NR_ENDERECO    ,P_PRCR_E_MAIL      ,V_BAIRRO_ID               ,                         
                         sysdate               ,P_USER             ,P_STATUS                  );
              
    -- regiao base
    select M.REGIAO_VENDA_ID
      into V_REGIAO_VENDA_ID
      from MERC_LIVRE_CONFIG M
     where M.UNIDADE_EMPRESARIAL_ID = P_UNIDADE_EMPRESARIAL_ID;

    -- Parâmetro do Cliente...
    insert into PARAM_CLIENTE(PARAM_CLIENTE_ID         ,UNEM_FATURAMENTO_ID      ,
                              REGIAO_VENDA_ID          ,PRCL_CONTRIBUINTE        , 
                              PRCL_TP_CLIENTE          ,PRCL_TP_FRETE            ,  
                              PRCL_EFETUA_VENDA_NORMAL ,PRCL_LIBERA_VENDA        ,
                              PRCL_SITUACAO            ,PRCL_MEIOCOB             ,
                              PRCL_PRZ_MAXIMO          ,PRCL_LIMCRE              ,
                              DATA_INCLUSAO            ,USUARIO_INCLUSAO         , 
                              STATUS                   )
    
         values              (P_PARCEIRO_ID            ,P_UNIDADE_EMPRESARIAL_ID ,
                              V_REGIAO_VENDA_ID        ,'Nao'                    , 
                              'Privado'                ,'FOB'                    ,                                                             
                              'Sim'                    ,'Sim'                    ,
                              'Venda Liberada'         ,'Duplicata Carteira'     ,
                              60                       ,P_PRCL_LIMCRE            ,
                              sysdate                  ,P_USER                   , 
                              P_STATUS                 ); 

    -- Pessoa Juridica...
    if V_PRCR_TIPO_PESSOA = 'Juridica' then
      insert into PESSOA_JURIDICA(PESSOA_JURIDICA_ID  , 
                                  PSJR_NOME_FANTASIA  , 
                                  PSJR_INSCRICAO_EST  , 
                                  USUARIO_INCLUSAO    , 
                                  DATA_INCLUSAO       ,
                                  STATUS              )
          
           values                (P_PARCEIRO_ID                         , 
                                  nvl(P_PSJR_NOME_FANTASIA,P_PRCR_NOME) ,
                                  NVL(P_PSJR_INSCRICAO_EST,'ISENTO')    ,
                                  P_USER                                , 
                                  sysdate                               ,
                                  P_STATUS                              );
    end if;
  
  end if;
  
  if P_TRANSACTION = 0 then
    commit;
  end if;
  
end PRC_MLAPI_CLIENTE_INSERT;
/

