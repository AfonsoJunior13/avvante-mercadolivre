create or replace procedure desenv.PRC_MLAPI_ENDERECO_INSERT
(
  -- Parametros relativos aos campos da tabela...
  P_ENDERECO_ID               in out ENDERECO.ENDERECO_ID               %type,
  P_PARCEIRO_ID               in out ENDERECO.PARCEIRO_ID               %type,  
  P_CEPX_CODIGO               in out CEP.CEPX_CODIGO                    %type,  
  P_BRRO_NOME                 in out BAIRRO.BRRO_NOME                   %type,    
  P_ENDR_ENDERECO             in out ENDERECO.ENDR_ENDERECO             %type,
  P_ENDR_NUMERO               in out ENDERECO.ENDR_NUMERO               %type,
  P_ENDR_COMPLEMENTO_ENDERECO in out ENDERECO.ENDR_COMPLEMENTO_ENDERECO %type,
  P_ENDR_REFERENCIA           in out ENDERECO.ENDR_REFERENCIA           %type,

  -- Parametros de Controle... 
  P_ACTION       in out integer, 
  P_STATUS       in out varchar2, 
  P_TRANSACTION  in out integer, 
  P_USER         in out varchar2, 
  P_TERMINAL     in out varchar2, 
  P_MESSAGE      in out varchar2
  
) is
  V_ORIG_ACTION    varchar2(50);
  V_BAIRRO_ID      BAIRRO.BAIRRO_ID %type;
  V_CIDADE_ID      CIDADE.CIDADE_ID %type;
  V_CEP_ID         CEP.CEP_ID       %type;
  
begin
  
  if P_ACTION = 101 then

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
  
    V_ORIG_ACTION := GET_ORIGIN_INFO(P_TERMINAL);
    P_ENDERECO_ID := GENERATE_NEXT_ID('ENDERECO',P_USER,P_TERMINAL);
    P_STATUS      := 'Ativo';
        
    insert into ENDERECO(ENDERECO_ID               ,PARCEIRO_ID               ,  
                         CEP_ID                    ,BAIRRO_ID                 ,    
                         ENDR_ENDERECO             ,ENDR_NUMERO               ,
                         ENDR_COMPLEMENTO_ENDERECO ,ENDR_REFERENCIA           ,
                         ENDR_TIPO_ENDERECO        ,
                         STATUS                    ,USUARIO_INCLUSAO          ,
                         DATA_INCLUSAO             ,ORIGEM_ALTERACAO          )

        values          (P_ENDERECO_ID               ,P_PARCEIRO_ID               ,  
                         V_CEP_ID                    ,V_BAIRRO_ID                 ,    
                         P_ENDR_ENDERECO             ,P_ENDR_NUMERO               ,
                         P_ENDR_COMPLEMENTO_ENDERECO ,P_ENDR_REFERENCIA           ,
                         'Entrega'                   ,
                         P_STATUS                    ,P_USER                      ,
                         sysdate                     ,V_ORIG_ACTION               );
  
  end if;

  if P_TRANSACTION = 0 then
    commit;
  end if;

end PRC_MLAPI_ENDERECO_INSERT;
/

