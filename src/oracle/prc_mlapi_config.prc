create or replace procedure desenv.PRC_MLAPI_CONFIG
(
  --Parametros relativos aos campos da tabela...
  P_MERC_LIVRE_CONFIG_ID     in out MERC_LIVRE_CONFIG.MERC_LIVRE_CONFIG_ID     %type,
  P_UNIDADE_EMPRESARIAL_ID   in out MERC_LIVRE_CONFIG.UNIDADE_EMPRESARIAL_ID   %type,
  P_MLCN_CLIENT_ID           in out MERC_LIVRE_CONFIG.MLCN_CLIENT_ID           %type,
  P_MLCN_CLIENT_SECRET       in out MERC_LIVRE_CONFIG.MLCN_CLIENT_SECRET       %type,
  P_MLCN_CODE                in out MERC_LIVRE_CONFIG.MLCN_CODE                %type,
  P_MLCN_REDIRECT_URI        in out MERC_LIVRE_CONFIG.MLCN_REDIRECT_URI        %type,
  P_MLCN_TOKEN               in out MERC_LIVRE_CONFIG.MLCN_TOKEN               %type,
  P_MLCN_ACCESS_TOKEN        in out MERC_LIVRE_CONFIG.MLCN_ACCESS_TOKEN        %type,
  P_MLCN_USER_ID             in out MERC_LIVRE_CONFIG.MLCN_USER_ID             %type,
  P_MLCN_TOKEN_DT_VAL        in out MERC_LIVRE_CONFIG.MLCN_TOKEN_DT_VAL        %type,
  P_VENDEDOR_ID              in out MERC_LIVRE_CONFIG.VENDEDOR_ID              %type,
  P_TIPO_DOCUMENTO_ID        in out MERC_LIVRE_CONFIG.TIPO_DOCUMENTO_ID        %type,
  P_LANCA_CONT_PAD_ROTINA_ID in out MERC_LIVRE_CONFIG.LANCA_CONT_PAD_ROTINA_ID %type,
  P_CONDICAO_PAGTO_ID        in out MERC_LIVRE_CONFIG.CONDICAO_PAGTO_ID        %type,
  P_MLCN_MODO_VD             in out MERC_LIVRE_CONFIG.MLCN_MODO_VD             %type,
  P_TABELA_PRECO_ID          in out MERC_LIVRE_CONFIG.TABELA_PRECO_ID          %type,
  P_REGIAO_VENDA_ID          in out MERC_LIVRE_CONFIG.REGIAO_VENDA_ID          %type,
  P_MLCN_SKU_PRODUTO         in out MERC_LIVRE_CONFIG.MLCN_SKU_PRODUTO         %type,

  -- Parametros de Controle...
  P_ACTION       in out integer,
  P_STATUS       in out varchar2,
  P_TRANSACTION  in out integer,
  P_USER         in out varchar2,
  P_USER_AUTORIZ in out varchar2,
  P_TERMINAL     in out varchar2,
  P_MESSAGE      in out varchar2
)
is

  V_DATE_ACTION date;
  V_ORIG_ACTION varchar2(50);

begin

  if P_ACTION in (1,2,3,4) then
    select sysdate into V_DATE_ACTION from dual;
    V_ORIG_ACTION := GET_ORIGIN_INFO(P_TERMINAL);
    
    if P_UNIDADE_EMPRESARIAL_ID is null then
      Raise_application_error(-20000, 'Unidade Empresarial não informada.');
    end if;
    
    if P_ACTION = 1 then -- Inclusao...
      if P_MERC_LIVRE_CONFIG_ID is null then
        P_MERC_LIVRE_CONFIG_ID := GENERATE_NEXT_ID('MERC_LIVRE_CONFIG',P_USER,P_TERMINAL);
      end if;
      insert into MERC_LIVRE_CONFIG(MERC_LIVRE_CONFIG_ID    ,USUARIO_INCLUSAO          ,
                                    ORIGEM_ALTERACAO        ,DATA_ALTERACAO            ,
                                    USUARIO_ALTERACAO       ,STATUS                    ,
                                    UNIDADE_EMPRESARIAL_ID  ,MLCN_CLIENT_ID            ,
                                    MLCN_CLIENT_SECRET      ,MLCN_CODE                 ,
                                    MLCN_REDIRECT_URI       ,MLCN_TOKEN                ,
                                    MLCN_ACCESS_TOKEN       ,MLCN_USER_ID              ,
                                    MLCN_TOKEN_DT_VAL       ,VENDEDOR_ID               ,
                                    TIPO_DOCUMENTO_ID       ,LANCA_CONT_PAD_ROTINA_ID  ,
                                    CONDICAO_PAGTO_ID       ,
                                    MLCN_MODO_VD            ,TABELA_PRECO_ID           ,
                                    REGIAO_VENDA_ID         ,MLCN_SKU_PRODUTO          )
           values                  (P_MERC_LIVRE_CONFIG_ID  ,P_USER                    ,
                                    V_ORIG_ACTION           ,V_DATE_ACTION             ,
                                    P_USER                  ,P_STATUS                  ,
                                    P_UNIDADE_EMPRESARIAL_ID,P_MLCN_CLIENT_ID          ,
                                    P_MLCN_CLIENT_SECRET    ,P_MLCN_CODE               ,
                                    P_MLCN_REDIRECT_URI     ,P_MLCN_TOKEN              ,
                                    P_MLCN_ACCESS_TOKEN     ,P_MLCN_USER_ID            ,
                                    P_MLCN_TOKEN_DT_VAL     ,P_VENDEDOR_ID             ,
                                    P_TIPO_DOCUMENTO_ID     ,P_LANCA_CONT_PAD_ROTINA_ID,
                                    P_CONDICAO_PAGTO_ID     ,
                                    P_MLCN_MODO_VD          ,P_TABELA_PRECO_ID         ,
                                    P_REGIAO_VENDA_ID       ,P_MLCN_SKU_PRODUTO        );
    elsif P_ACTION = 2 then -- Alteração...
      update MERC_LIVRE_CONFIG set ORIGEM_ALTERACAO               = V_ORIG_ACTION,
                                   DATA_ALTERACAO                 = V_DATE_ACTION,
                                   USUARIO_ALTERACAO              = P_USER,
                                   STATUS                         = P_STATUS,
                                   UNIDADE_EMPRESARIAL_ID         = P_UNIDADE_EMPRESARIAL_ID,
                                   MLCN_CLIENT_ID                 = P_MLCN_CLIENT_ID,
                                   MLCN_CLIENT_SECRET             = P_MLCN_CLIENT_SECRET,
                                   MLCN_CODE                      = P_MLCN_CODE,
                                   MLCN_REDIRECT_URI              = P_MLCN_REDIRECT_URI,
                                   MLCN_TOKEN                     = P_MLCN_TOKEN,
                                   MLCN_ACCESS_TOKEN              = P_MLCN_ACCESS_TOKEN,
                                   MLCN_USER_ID                   = P_MLCN_USER_ID,
                                   MLCN_TOKEN_DT_VAL              = P_MLCN_TOKEN_DT_VAL,
                                   VENDEDOR_ID                    = P_VENDEDOR_ID,
                                   TIPO_DOCUMENTO_ID              = P_TIPO_DOCUMENTO_ID,
                                   LANCA_CONT_PAD_ROTINA_ID       = P_LANCA_CONT_PAD_ROTINA_ID,
                                   CONDICAO_PAGTO_ID              = P_CONDICAO_PAGTO_ID,
                                   MLCN_MODO_VD                   = P_MLCN_MODO_VD,
                                   TABELA_PRECO_ID                = P_TABELA_PRECO_ID,
                                   REGIAO_VENDA_ID                = P_REGIAO_VENDA_ID,
                                   MLCN_SKU_PRODUTO               = P_MLCN_SKU_PRODUTO
        where MERC_LIVRE_CONFIG_ID = P_MERC_LIVRE_CONFIG_ID;
    elsif P_ACTION = 3 then -- Exclusão...
      update MERC_LIVRE_CONFIG set STATUS                         = P_STATUS,
                                   ORIGEM_EXCLUSAO                = V_ORIG_ACTION,
                                   DATA_EXCLUSAO                  = V_DATE_ACTION,
                                   USUARIO_EXCLUSAO               = P_USER
        where MERC_LIVRE_CONFIG_ID = P_MERC_LIVRE_CONFIG_ID;
    elsif P_ACTION = 4 then -- Recuperação...
      update MERC_LIVRE_CONFIG set STATUS                         = P_STATUS,
                                   ORIGEM_RECUPERACAO             = V_ORIG_ACTION,
                                   DATA_RECUPERACAO               = V_DATE_ACTION,
                                   USUARIO_RECUPERACAO            = P_USER
        where MERC_LIVRE_CONFIG_ID = P_MERC_LIVRE_CONFIG_ID;
    end if;
  end if;
  if P_TRANSACTION = 0 then
    commit;
  end if;

exception
  when OTHERS then
    rollback;
    SYS_TRATA_ERRO;
end PRC_MLAPI_CONFIG;
/

