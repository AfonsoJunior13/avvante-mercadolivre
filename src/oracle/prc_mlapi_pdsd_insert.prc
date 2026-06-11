create or replace procedure desenv.PRC_MLAPI_PDSD_INSERT
(
  -- Parametros relativos aos campos da tabela...
  P_MERC_LIVRE_ORDEM_ID in out MERC_LIVRE_ORDEM.MERC_LIVRE_ORDEM_ID %type,

  -- Parametros de Controle...
  P_ACTION       in out integer,
  P_STATUS       in out varchar2,
  P_TRANSACTION  in out integer,
  P_USER         in out varchar2,
  P_TERMINAL     in out varchar2,
  P_MESSAGE      in out varchar2

) is

  V_DATE_ACTION                date;
  V_ACTION                     integer;
  V_TRANSACTION                integer;
  V_NULL                       varchar2(2048);
  V_CORTES                     varchar2(32767);
  V_ERRO_ITEM                  varchar2(32767);
  V_PEDIDO_SAIDA_ID            PEDIDO_SAIDA.PEDIDO_SAIDA_ID                 %type;
  V_CONDICAO_PAGTO_ID          PEDIDO_SAIDA.CONDICAO_PAGTO_ID               %type;
  V_PDSD_VLR_DESCTO            PEDIDO_SAIDA.PDSD_VLR_DESCTO                 %type;
  V_PDSD_DT_EMISSAO            PEDIDO_SAIDA.PDSD_DT_EMISSAO                 %type;
  V_PDSD_NOME_CLIENTE          PEDIDO_SAIDA.PDSD_NOME_CLIENTE               %type;
  V_PDSD_FONE_CLIENTE          PEDIDO_SAIDA.PDSD_FONE_CLIENTE               %type;
  V_PDSD_OBSERVACAO            PEDIDO_SAIDA.PDSD_OBSERVACAO                 %type;
  V_PDSD_DT_ENTRG              PEDIDO_SAIDA.PDSD_DT_ENTRG                   %type;
  V_PDSD_STATUS                PEDIDO_SAIDA.PDSD_STATUS                     %type;
  V_PDSD_MODO_VD               PEDIDO_SAIDA.PDSD_MODO_VD                    %type;
  V_PDSD_NR_PED_MOBILE         PEDIDO_SAIDA.PDSD_NR_PED_MOBILE              %type;
  V_PDSD_STATUS_PED_MOBILE     PEDIDO_SAIDA.PDSD_STATUS_PED_MOBILE          %type;
  V_VENDEDOR_COMPRADOR_ID      PEDIDO_SAIDA.VENDEDOR_COMPRADOR_ID           %type;
  V_ATENDENTE_ID               PEDIDO_SAIDA.ATENDENTE_ID                    %type;
  V_TIPO_DOCTO_PAGO1_ID        PEDIDO_SAIDA.TIPO_DOCTO_PAGO1_ID             %type;
  V_PDSD_VLR_PAGO1             PEDIDO_SAIDA.PDSD_VLR_PAGO1                  %type;
  V_UNIDADE_EMPRESARIAL_ID     PEDIDO_SAIDA.UNIDADE_EMPRESARIAL_ID          %type;
  V_PDSD_VLR_INDENIZ           PEDIDO_SAIDA.PDSD_VLR_INDENIZ                %type;
  V_PARCEIRO_ID                PEDIDO_SAIDA.PARCEIRO_ID                     %type;
  V_TIPO_MOV_ESTOQUE_ID        PEDIDO_SAIDA.TIPO_MOV_ESTOQUE_ID             %type;
  V_PDSD_MONTA_CARGA           PEDIDO_SAIDA.PDSD_MONTA_CARGA                %type;
  V_PDSD_VLR_MERCADORIA        PEDIDO_SAIDA.PDSD_VLR_MERCADORIA             %type;
  V_CARTEIRA_BANCARIA_ID       PEDIDO_SAIDA.CARTEIRA_BANCARIA_ID            %type;
  V_PDSD_NUM_PED_CMP_CLIENTE   PEDIDO_SAIDA.PDSD_NUM_PED_CMP_CLIENTE        %type;
  V_CARTEIRA_BANCARIA_DCAD_ID  PEDIDO_SAIDA.CARTEIRA_BANCARIA_DCAD_ID       %type;
  V_PDSD_PORC_DESCTO_ADICIONAL PEDIDO_SAIDA.PDSD_PORC_DESCTO_ADICIONAL      %type;
  V_TABELA_PRECO_ID            PEDIDO_SAIDA.TABELA_PRECO_ID                 %type;
  V_TIPO_DOCTO_ADIC_PAGO_ID    PEDIDO_SAIDA.TIPO_DOCTO_ADIC_PAGO_ID         %type;
  V_PDSD_DT_PEDIDO_EXTERNO     PEDIDO_SAIDA.TIPO_DOCTO_ADIC_PAGO_ID         %type;
  V_PDSD_PRZ_PAGTO_DESC_ADIC   PEDIDO_SAIDA.PDSD_PRZ_PAGTO_DESC_ADIC        %type;
  V_PDSD_TP_FRETE              PEDIDO_SAIDA.PDSD_TP_FRETE                   %type;
  V_PDSD_OBSERVACAO_NF         PEDIDO_SAIDA.PDSD_OBSERVACAO_NF              %type;
  V_PDSD_PRE_PEDIDO            PEDIDO_SAIDA.PDSD_PRE_PEDIDO                 %type;
  V_PDSD_VLR_TOTAL             PEDIDO_SAIDA.PDSD_VLR_TOTAL                  %type;
  V_PDSD_NR_PEDIDO             PEDIDO_SAIDA.PDSD_NR_PEDIDO                  %type;
  V_PDSD_CMV                   PEDIDO_SAIDA.PDSD_CMV                        %type;
  V_PDSD_PORC_DESCTO           PEDIDO_SAIDA.PDSD_PORC_DESCTO                %type;
  V_STATUS                     PEDIDO_SAIDA.STATUS                          %type;
  V_PDSD_MOT_CANCELAMENTO      PEDIDO_SAIDA.PDSD_MOT_CANCELAMENTO           %type;
  V_LANCA_CONT_PAD_ROTINA_ID   PEDIDO_SAIDA.LANCA_CONT_PAD_ROTINA_ID        %type;
  V_TRANSPORTADORA_ID          PEDIDO_SAIDA.TRANSPORTADORA_ID               %type;
  V_AVALISTA_ID                PEDIDO_SAIDA.AVALISTA_ID                     %type;
  V_ENDERECO_ENTREGA_ID        PEDIDO_SAIDA.ENDERECO_ENTREGA_ID             %type;
  V_PDSD_VLR_FRETE             PEDIDO_SAIDA.PDSD_VLR_FRETE                  %type;
  V_ITEM_PEDIDO_SAIDA_ID       ITEM_PEDIDO_SAIDA.ITEM_PEDIDO_SAIDA_ID       %type;
  V_PRODUTO_ID                 ITEM_PEDIDO_SAIDA.PRODUTO_ID                 %type;
  V_PSIT_DT_EMISSAO            ITEM_PEDIDO_SAIDA.PSIT_DT_EMISSAO            %type;
  V_PSIT_QTDE_PEDIDA           ITEM_PEDIDO_SAIDA.PSIT_QTDE_PEDIDA           %type;
  V_PSIT_QTDE_ATENDIDA         ITEM_PEDIDO_SAIDA.PSIT_QTDE_ATENDIDA         %type;
  V_PSIT_PRC_UNIT              ITEM_PEDIDO_SAIDA.PSIT_PRC_UNIT              %type;
  V_PSIT_STATUS                ITEM_PEDIDO_SAIDA.PSIT_STATUS                %type;
  V_PSIT_PRC_CADASTRO          ITEM_PEDIDO_SAIDA.PSIT_PRC_CADASTRO          %type;
  V_PSIT_QTDE_FUTURA           ITEM_PEDIDO_SAIDA.PSIT_QTDE_FUTURA           %type;
  V_EMBALAGEM_VENDA_ID         ITEM_PEDIDO_SAIDA.EMBALAGEM_VENDA_ID         %type;
  V_PSIT_PORC_DESCTO_ITEM      ITEM_PEDIDO_SAIDA.PSIT_PORC_DESCTO_ITEM      %type;
  V_PSIT_VLR_JURO_CADASTRO_UN  ITEM_PEDIDO_SAIDA.PSIT_VLR_JURO_CADASTRO_UN  %type;
  V_PSIT_VLR_JURO              ITEM_PEDIDO_SAIDA.PSIT_VLR_JURO              %type;
  V_PSIT_RETIRA_MERCADORIA     ITEM_PEDIDO_SAIDA.PSIT_RETIRA_MERCADORIA     %type;
  V_INDENIZACAO_ID             INDENIZACAO.INDENIZACAO_ID                   %type;
  V_PRCR_NOME                  PARCEIRO.PRCR_NOME                           %type;
  V_PRCR_CGC_CPF               PARCEIRO.PRCR_CGC_CPF                        %type;
  V_CORREIO_ID                 CORREIO.CORREIO_ID                           %type;
  V_CRRO_REMETENTE             CORREIO.CRRO_REMETENTE                       %type;
  V_CRRO_DESTINATARIO          CORREIO.CRRO_DESTINATARIO                    %type;
  V_CRRO_ASSUNTO               CORREIO.CRRO_ASSUNTO                         %type;
  V_CRRO_MENSAGEM              CORREIO.CRRO_MENSAGEM                        %type;
  V_CRRO_DATA_ENVIO            CORREIO.CRRO_DATA_ENVIO                      %type;
  V_CRRO_DATA_LIDO             CORREIO.CRRO_DATA_LIDO                       %type;
  V_CRRO_EXPORTADO_POCKET      CORREIO.CRRO_EXPORTADO_POCKET                %type;
  V_MLPD_QTDE                  MERC_LIVRE_PRODUTO.MLPD_QTDE                 %type;

begin

  if P_ACTION in (101) then

    V_DATE_ACTION := sysdate;

    if P_ACTION = 101 then

      -- Lista os dados do pedido...
      for C_TC in (select M.*
                     from MERC_LIVRE_ORDEM M
                    where M.MERC_LIVRE_ORDEM_ID = P_MERC_LIVRE_ORDEM_ID
                      and M.PEDIDO_SAIDA_ID is null)
      loop

        -- Localiza as configurações...
        select M.VENDEDOR_ID,
               M.TIPO_DOCUMENTO_ID,
               M.LANCA_CONT_PAD_ROTINA_ID,
               M.CONDICAO_PAGTO_ID,
               M.TABELA_PRECO_ID,
               M.MLCN_MODO_VD
          into V_VENDEDOR_COMPRADOR_ID,
               V_TIPO_DOCTO_PAGO1_ID,
               V_LANCA_CONT_PAD_ROTINA_ID,
               V_CONDICAO_PAGTO_ID,
               V_TABELA_PRECO_ID,
               V_PDSD_MODO_VD
          from MERC_LIVRE_CONFIG M
         where M.UNIDADE_EMPRESARIAL_ID = C_TC.UNIDADE_EMPRESARIAL_ID;

        -- Localiza o parceiro caso não encontre cadastra um novo o mesmo para o endereço...
        V_ACTION      := 101;
        V_TRANSACTION := 1;

        PRC_MLAPI_CLIENTE(P_MERC_LIVRE_ORDEM_ID => C_TC.MERC_LIVRE_ORDEM_ID,
                          P_PARCEIRO_ID         => V_PARCEIRO_ID,
                          P_ENDERECO_ID         => V_ENDERECO_ENTREGA_ID,
                          P_ACTION              => V_ACTION,
                          P_STATUS              => P_STATUS,
                          P_TRANSACTION         => V_TRANSACTION,
                          P_USER                => P_USER,
                          P_TERMINAL            => P_TERMINAL,
                          P_MESSAGE             => P_MESSAGE);

        -- Tipo de Movimento...
        begin
          select TIPO_MOV_ESTOQUE_ID
            into V_TIPO_MOV_ESTOQUE_ID
            from TIPO_MOV_ESTOQUE
           where TPME_TIPO            = 'Venda'
             and TPME_TIPO_MOVIMENTO  = 'Saida'
             and RowNum              <= 1;
        exception when NO_DATA_FOUND then
          Raise_application_error(-20000, 'Tipo de Movimento Venda - Saida não encontrado!');
        end;

        -- Informações vinda do ML...
        V_PDSD_VLR_DESCTO            := C_TC.MLOR_DESCONTO;
        V_PDSD_NOME_CLIENTE          := C_TC.MLOR_NOME;
        V_PDSD_FONE_CLIENTE          := null;
        V_PDSD_NR_PED_MOBILE         := C_TC.MLOR_ORDER_ID;
        V_UNIDADE_EMPRESARIAL_ID     := C_TC.UNIDADE_EMPRESARIAL_ID;
        V_PDSD_VLR_PAGO1             := (C_TC.MLOR_VALOR - NVL(C_TC.MLOR_DESCONTO,0)) + NVL(C_TC.MLOR_VLR_FRETE,0);
        V_PDSD_DT_PEDIDO_EXTERNO     := C_TC.DATA_INCLUSAO;
        V_PDSD_VLR_FRETE             := NVL(C_TC.MLOR_VLR_FRETE,0);

        if V_PDSD_MODO_VD = 'TeleVenda' then
          V_PDSD_MONTA_CARGA := 'Sim';
        else
          V_PDSD_MONTA_CARGA := 'Nao';
        end if;

        -- Captura as informacoes...
        V_PEDIDO_SAIDA_ID            := null;
        V_TRANSPORTADORA_ID          := null;
        V_INDENIZACAO_ID             := null;
        V_PDSD_VLR_INDENIZ           := null;
        V_NULL                       := null;
        V_PDSD_DT_EMISSAO            := V_DATE_ACTION;
        V_PDSD_OBSERVACAO            := null;
        V_PDSD_DT_ENTRG              := trunc(V_DATE_ACTION);
        V_PDSD_STATUS                := 'Aberto';
        V_PDSD_STATUS_PED_MOBILE     := 'Aguardando';
        V_ATENDENTE_ID               := null;
        V_PDSD_VLR_MERCADORIA        := null;
        V_CARTEIRA_BANCARIA_ID       := null;
        V_TIPO_DOCTO_ADIC_PAGO_ID    := null;
        V_PDSD_NUM_PED_CMP_CLIENTE   := null;
        V_CARTEIRA_BANCARIA_DCAD_ID  := null;
        V_PDSD_PORC_DESCTO_ADICIONAL := null;
        V_PDSD_PRZ_PAGTO_DESC_ADIC   := null;
        V_PDSD_TP_FRETE              := 'FOB';
        V_PDSD_OBSERVACAO_NF         := null;
        V_PDSD_PRE_PEDIDO            := 'Nao';
        V_AVALISTA_ID                := V_PARCEIRO_ID;
        V_ACTION                     := 1;
        V_TRANSACTION                := 1;
        P_STATUS                     := 'Inconsistente';

        -- Salva o pedido de saida...
        MAN_PEDIDO_SAIDA (V_PEDIDO_SAIDA_ID             ,V_NULL                        ,
                          V_CONDICAO_PAGTO_ID           ,V_NULL                        ,
                          V_ENDERECO_ENTREGA_ID         ,V_NULL                        ,
                          V_NULL                        ,V_PDSD_VLR_DESCTO             ,
                          V_PDSD_DT_EMISSAO             ,V_PDSD_NOME_CLIENTE           ,
                          V_PDSD_FONE_CLIENTE           ,V_PDSD_VLR_FRETE              ,
                          V_NULL                        ,V_NULL                        ,
                          V_PDSD_OBSERVACAO             ,V_NULL                        ,
                          V_NULL                        ,V_NULL                        ,
                          V_PDSD_DT_ENTRG               ,V_PDSD_STATUS                 ,
                          V_PDSD_MODO_VD                ,V_PDSD_NR_PED_MOBILE          ,
                          V_PDSD_STATUS_PED_MOBILE      ,V_NULL                        ,
                          V_VENDEDOR_COMPRADOR_ID       ,V_ATENDENTE_ID                ,
                          V_NULL                        ,V_NULL                        ,
                          V_TIPO_DOCTO_PAGO1_ID         ,V_NULL                        ,
                          V_NULL                        ,V_NULL                        ,
                          V_NULL                        ,V_NULL                        ,
                          V_NULL                        ,V_NULL                        ,
                          V_NULL                        ,V_NULL                        ,
                          V_NULL                        ,V_NULL                        ,
                          V_UNIDADE_EMPRESARIAL_ID      ,V_PDSD_VLR_PAGO1              ,
                          V_NULL                        ,V_NULL                        ,
                          V_NULL                        ,V_NULL                        ,
                          V_NULL                        ,V_NULL                        ,
                          V_NULL                        ,V_NULL                        ,
                          V_NULL                        ,V_NULL                        ,
                          V_NULL                        ,V_NULL                        ,
                          V_NULL                        ,V_PDSD_VLR_INDENIZ            ,
                          V_PARCEIRO_ID                 ,V_NULL                        ,
                          V_TIPO_MOV_ESTOQUE_ID         ,V_NULL                        ,
                          V_NULL                        ,V_NULL                        ,
                          V_PDSD_MONTA_CARGA            ,V_NULL                        ,
                          V_NULL                        ,V_PDSD_VLR_MERCADORIA         ,
                          V_NULL                        ,V_CARTEIRA_BANCARIA_ID        ,
                          V_NULL                        ,V_TIPO_DOCTO_ADIC_PAGO_ID     ,
                          V_NULL                        ,V_NULL                        ,
                          V_NULL                        ,V_TRANSPORTADORA_ID           ,
                          V_NULL                        ,V_PDSD_NUM_PED_CMP_CLIENTE    ,
                          V_TABELA_PRECO_ID             ,V_NULL                        ,
                          V_NULL                        ,V_PDSD_DT_PEDIDO_EXTERNO      ,
                          V_ACTION                      ,P_STATUS                      ,
                          V_TRANSACTION                 ,P_USER                        ,
                          P_USER                        ,P_TERMINAL                    ,
                          P_MESSAGE                     ,V_NULL                        ,
                          V_NULL                        ,V_NULL                        ,
                          V_NULL                        ,V_NULL                        ,
                          V_NULL                        ,V_NULL                        ,
                          V_NULL                        ,V_NULL                        ,
                          V_NULL                        ,V_NULL                        ,
                          V_NULL                        ,V_CARTEIRA_BANCARIA_DCAD_ID   ,
                          V_PDSD_PORC_DESCTO_ADICIONAL  ,V_PDSD_PRZ_PAGTO_DESC_ADIC    ,
                          V_PDSD_TP_FRETE               ,V_PDSD_OBSERVACAO_NF          ,
                          V_NULL                        ,V_NULL                        ,
                          V_NULL                        ,V_NULL                        ,
                          V_NULL                        ,V_LANCA_CONT_PAD_ROTINA_ID    ,
                          V_NULL                        ,V_NULL                        ,
                          V_NULL                        ,V_NULL                        ,
                          V_NULL                        ,V_NULL                        ,
                          V_PDSD_PRE_PEDIDO             ,V_NULL                        ,
                          V_NULL                        ,V_NULL                        ,
                          V_NULL                        ,V_NULL                        ,
                          V_NULL                        ,V_NULL                        ,
                          V_NULL                        ,V_AVALISTA_ID                 );

        -- Lista os itens dos pedidos...
        for C_TI in (select * from MERC_LIVRE_ORDEM_ITEM where MLOI_ORDER_ID = C_TC.MLOR_ORDER_ID) loop

          -- Localiza o produto...
          select M.PRODUTO_ID,
                 M.EMBALAGEM_VENDA_ID,
                 M.MLPD_QTDE
            into V_PRODUTO_ID,
                 V_EMBALAGEM_VENDA_ID,
                 V_MLPD_QTDE
            from MERC_LIVRE_PRODUTO M
           where M.MLPD_ID  = C_TI.MLOI_PRODUTO_ID
             and ROWNUM    <= 1;

          if V_PRODUTO_ID is null then
            Raise_application_error(-20000, 'Produto não vinculado para '||C_TI.MLOI_PRODUTO_ID);
          end if;

          if V_EMBALAGEM_VENDA_ID is null then
            Raise_application_error(-20000, 'Embalagem de Venda não vinculado para '||C_TI.MLOI_PRODUTO_ID);
          end if;

          if nvl(V_MLPD_QTDE,0) = 0 then
            Raise_application_error(-20000, 'Quantidade do Anuncio não informado.');
          end if;

          -- Informações Vindas do ML..
          V_PSIT_PRC_UNIT         := round( (C_TI.MLOI_UNIT_PRICE / V_MLPD_QTDE) ,2);
          V_PSIT_PORC_DESCTO_ITEM := 0;
          V_PSIT_QTDE_PEDIDA      := (C_TI.MLOI_QUANTITY * V_MLPD_QTDE);

          -- Salvar itens do pedido...
          V_ITEM_PEDIDO_SAIDA_ID      := null;
          V_PSIT_DT_EMISSAO           := V_DATE_ACTION;
          V_PSIT_QTDE_ATENDIDA        := 0;
          V_PSIT_STATUS               := 'Aberto';
          V_PSIT_PRC_CADASTRO         := FNC_PRECO_VENDA(V_EMBALAGEM_VENDA_ID,V_PRODUTO_ID,V_UNIDADE_EMPRESARIAL_ID,V_TABELA_PRECO_ID);
          V_PSIT_VLR_JURO_CADASTRO_UN := FNC_JURO_VENDA(V_PSIT_PRC_CADASTRO,V_CONDICAO_PAGTO_ID,'Juro');
          V_PSIT_VLR_JURO             := FNC_JURO_VENDA(V_PSIT_PRC_UNIT,V_CONDICAO_PAGTO_ID,'Juro') * V_PSIT_QTDE_PEDIDA;
          V_PSIT_QTDE_FUTURA          := 0;
          V_PSIT_RETIRA_MERCADORIA    := 'Entrega';
          V_ACTION                    := 1;
          V_TRANSACTION               := 1;
          V_NULL                      := null;

          -- Trata o item que der erro e ignora...
          begin
            MAN_ITEM_PEDIDO_SAIDA(V_ITEM_PEDIDO_SAIDA_ID         ,V_PEDIDO_SAIDA_ID              ,
                                  V_PRODUTO_ID                   ,V_NULL                         ,
                                  V_PSIT_DT_EMISSAO              ,V_PSIT_QTDE_PEDIDA             ,
                                  V_PSIT_QTDE_ATENDIDA           ,V_PSIT_PRC_UNIT                ,
                                  V_NULL                         ,V_PSIT_STATUS                  ,
                                  V_NULL                         ,V_NULL                         ,
                                  V_PSIT_PRC_CADASTRO            ,V_PSIT_QTDE_FUTURA             ,
                                  V_NULL                         ,V_NULL                         ,
                                  V_NULL                         ,V_NULL                         ,
                                  V_NULL                         ,V_NULL                         ,
                                  V_NULL                         ,V_NULL                         ,
                                  V_PSIT_VLR_JURO                ,V_NULL                         ,
                                  V_TABELA_PRECO_ID              ,V_NULL                         ,
                                  V_NULL                         ,V_EMBALAGEM_VENDA_ID           ,
                                  V_NULL                         ,V_PSIT_RETIRA_MERCADORIA       ,
                                  V_NULL                         ,V_NULL                         ,
                                  V_NULL                         ,V_NULL                         ,
                                  V_NULL                         ,V_NULL                         ,
                                  V_PSIT_PORC_DESCTO_ITEM        ,V_PSIT_VLR_JURO_CADASTRO_UN    ,
                                  V_ACTION                       ,V_TRANSACTION                  ,
                                  P_STATUS                       ,P_USER                         ,
                                  P_USER                         ,P_TERMINAL                     ,
                                  P_MESSAGE                      ,V_NULL                         ,
                                  V_NULL                         ,V_NULL                         ,
                                  V_NULL                         ,V_LANCA_CONT_PAD_ROTINA_ID     );
          exception when others then
            V_ERRO_ITEM := V_ERRO_ITEM ||C_TI.MLOI_PRODUTO_ID||' > '||sqlerrm||'| '||chr(10);
          end;

        end loop;

        if V_ERRO_ITEM is not null then
          Raise_application_error(-20000, 'Erro ao inserir o item do pedido. |'||V_ERRO_ITEM||'|');
        end if;

        -- Verifica o valor da mercadoria...
        select PS.PDSD_VLR_MERCADORIA,
               PS.PDSD_VLR_TOTAL,
               PS.PDSD_VLR_DESCTO,
               PS.PDSD_PORC_DESCTO,
               PS.PDSD_VLR_INDENIZ
          into V_PDSD_VLR_MERCADORIA,
               V_PDSD_VLR_TOTAL,
               V_PDSD_VLR_DESCTO,
               V_PDSD_PORC_DESCTO,
               V_PDSD_VLR_INDENIZ
          from PEDIDO_SAIDA PS
         where PS.PEDIDO_SAIDA_ID  = V_PEDIDO_SAIDA_ID
           and RowNum             <= 1;

        -- Muda o status do pedido do mobile...
        update PEDIDO_SAIDA PS
           set PS.PDSD_VLR_TOTAL_DIG = V_PDSD_VLR_TOTAL,
               PS.PDSD_ORIGEM        = 'Mercado Livre'
         where PS.PEDIDO_SAIDA_ID = V_PEDIDO_SAIDA_ID;

        -- Refaz os calculos devido ao cortes...
        V_TRANSACTION := 1;

        PRC_RATEIO_VALORES(P_CAMPO_RELATIVO_ID      => V_PEDIDO_SAIDA_ID,
                           P_TABELA_RELATIVA        => 'PEDIDO_SAIDA',
                           P_VALOR_MERCADORIA       => V_PDSD_VLR_MERCADORIA,
                           P_VALOR_DESCONTO         => V_PDSD_VLR_DESCTO,
                           P_VALOR_ENTRADA          => 0,
                           P_VALOR_DESPESA          => 0,
                           P_VALOR_FRETE            => V_PDSD_VLR_FRETE,
                           P_VALOR_INDENIZACAO      => V_PDSD_VLR_INDENIZ,
                           P_VALOR_DESCTO_ADICIONAL => 0,
                           P_STATUS                 => P_STATUS,
                           P_USER                   => P_USER,
                           P_TERMINAL               => P_TERMINAL,
                           P_TRANSACTION            => V_TRANSACTION);

        -- Confirma o Pedido de Saida...
        V_PDSD_STATUS_PED_MOBILE := 'Processado';
        V_ACTION                 := 100;
        V_TRANSACTION            := 1;
        V_NULL                   := null;
        P_STATUS                 := 'Ativo';

        MAN_PEDIDO_SAIDA (V_PEDIDO_SAIDA_ID             ,V_NULL                        ,
                          V_CONDICAO_PAGTO_ID           ,V_NULL                        ,
                          V_NULL                        ,V_NULL                        ,
                          V_PDSD_PORC_DESCTO            ,V_PDSD_VLR_DESCTO             ,
                          V_PDSD_DT_EMISSAO             ,V_PDSD_NOME_CLIENTE           ,
                          V_PDSD_FONE_CLIENTE           ,V_PDSD_VLR_FRETE              ,
                          V_NULL                        ,V_NULL                        ,
                          V_PDSD_OBSERVACAO             ,V_NULL                        ,
                          V_NULL                        ,V_NULL                        ,
                          V_PDSD_DT_ENTRG               ,V_PDSD_STATUS                 ,
                          V_PDSD_MODO_VD                ,V_PDSD_NR_PED_MOBILE          ,
                          V_PDSD_STATUS_PED_MOBILE      ,V_NULL                        ,
                          V_VENDEDOR_COMPRADOR_ID       ,V_ATENDENTE_ID                ,
                          V_NULL                        ,V_NULL                        ,
                          V_TIPO_DOCTO_PAGO1_ID         ,V_NULL                        ,
                          V_NULL                        ,V_NULL                        ,
                          V_NULL                        ,V_NULL                        ,
                          V_NULL                        ,V_NULL                        ,
                          V_NULL                        ,V_NULL                        ,
                          V_NULL                        ,V_NULL                        ,
                          V_UNIDADE_EMPRESARIAL_ID      ,V_PDSD_VLR_PAGO1              ,
                          V_NULL                        ,V_NULL                        ,
                          V_NULL                        ,V_NULL                        ,
                          V_NULL                        ,V_NULL                        ,
                          V_NULL                        ,V_NULL                        ,
                          V_NULL                        ,V_NULL                        ,
                          V_NULL                        ,V_NULL                        ,
                          V_NULL                        ,V_PDSD_VLR_INDENIZ            ,
                          V_PARCEIRO_ID                 ,V_NULL                        ,
                          V_TIPO_MOV_ESTOQUE_ID         ,V_NULL                        ,
                          V_NULL                        ,V_NULL                        ,
                          V_PDSD_MONTA_CARGA            ,V_NULL                        ,
                          V_NULL                        ,V_PDSD_VLR_MERCADORIA         ,
                          V_NULL                        ,V_CARTEIRA_BANCARIA_ID        ,
                          V_NULL                        ,V_TIPO_DOCTO_ADIC_PAGO_ID     ,
                          V_NULL                        ,V_NULL                        ,
                          V_NULL                        ,V_TRANSPORTADORA_ID           ,
                          V_NULL                        ,V_PDSD_NUM_PED_CMP_CLIENTE    ,
                          V_TABELA_PRECO_ID             ,V_NULL                        ,
                          V_NULL                        ,V_PDSD_DT_PEDIDO_EXTERNO      ,
                          V_ACTION                      ,P_STATUS                      ,
                          V_TRANSACTION                 ,P_USER                        ,
                          P_USER                        ,P_TERMINAL                    ,
                          P_MESSAGE                     ,V_NULL                        ,
                          V_NULL                        ,V_NULL                        ,
                          V_NULL                        ,V_NULL                        ,
                          V_NULL                        ,V_NULL                        ,
                          V_NULL                        ,V_NULL                        ,
                          V_NULL                        ,V_NULL                        ,
                          V_NULL                        ,V_CARTEIRA_BANCARIA_DCAD_ID   ,
                          V_PDSD_PORC_DESCTO_ADICIONAL  ,V_PDSD_PRZ_PAGTO_DESC_ADIC    ,
                          V_PDSD_TP_FRETE               ,V_PDSD_OBSERVACAO_NF          ,
                          V_NULL                        ,V_NULL                        ,
                          V_NULL                        ,V_NULL                        ,
                          V_NULL                        ,V_LANCA_CONT_PAD_ROTINA_ID    ,
                          V_NULL                        ,V_NULL                        ,
                          V_NULL                        ,V_NULL                        ,
                          V_NULL                        ,V_NULL                        ,
                          V_PDSD_PRE_PEDIDO             ,V_NULL                        ,
                          V_NULL                        ,V_NULL                        ,
                          V_NULL                        ,V_NULL                        ,
                          V_NULL                        ,V_NULL                        ,
                          V_NULL                        ,V_AVALISTA_ID                 );

        -- Verifica o valor da mercadoria...
        select PS.PDSD_VLR_MERCADORIA,
               PS.PDSD_VLR_TOTAL
          into V_PDSD_VLR_MERCADORIA,
               V_PDSD_VLR_TOTAL
          from PEDIDO_SAIDA PS
         where PS.PEDIDO_SAIDA_ID  = V_PEDIDO_SAIDA_ID
           and RowNum             <= 1;

        -- Muda o status do pedido do mobile...
        update PEDIDO_SAIDA PS
           set PS.PDSD_STATUS_PED_MOBILE = 'Processado',
               PS.PDSD_VLR_PAGO1         = V_PDSD_VLR_TOTAL,
               PS.PDSD_ORIGEM            = 'Mercado Livre'
        where  PS.PEDIDO_SAIDA_ID = V_PEDIDO_SAIDA_ID;

        for C_PEDX in (select PS.*
                       from   PEDIDO_SAIDA PS
                       where  PS.PEDIDO_SAIDA_ID = V_PEDIDO_SAIDA_ID)
        loop
          -- Verifica se o pedido esta Inconsistente...
          if C_PEDX.STATUS in ('Inconsistente','Inconsistente ') and C_PEDX.PDSD_STATUS in ('A Liberar','Reservado') then
            -- Altera o Pedido Saida...
            update PEDIDO_SAIDA PS
               set PS.PDSD_STATUS = 'Aberto'
             where PS.PEDIDO_SAIDA_ID = C_PEDX.PEDIDO_SAIDA_ID;
          end if;
        end loop;

        -- Grava a mensagem de retorno do pedido...
        select PS.PDSD_NR_PEDIDO,
               PS.PDSD_STATUS,
               PS.PDSD_VLR_TOTAL,
               PS.PDSD_CMV,
               PS.STATUS,
               PR.PRCR_NOME,
               PR.PRCR_CGC_CPF
          into V_PDSD_NR_PEDIDO,
               V_PDSD_STATUS,
               V_PDSD_VLR_TOTAL,
               V_PDSD_CMV,
               V_STATUS,
               V_PRCR_NOME,
               V_PRCR_CGC_CPF
          from PEDIDO_SAIDA PS,
               PARCEIRO     PR
         where PS.PEDIDO_SAIDA_ID = V_PEDIDO_SAIDA_ID
           and PS.PARCEIRO_ID     = PR.PARCEIRO_ID;

        -- Verifica se o pedido esta Inconsistente...
        if V_STATUS in ('Inconsistente','Inconsistente ') and V_PDSD_STATUS in ('A Liberar','Reservado') then
          -- Alerta...
          Raise_application_error(-20000, '|Pedido Inconsistente/'||V_PDSD_STATUS||'|');
        end if;

        begin
          V_CORTES := FNC_MLAPI_CORTES(V_PEDIDO_SAIDA_ID);
        exception when others then
          V_CORTES := 'Nao foi possivel enviar os cortes do pedido.|';
        end;

        if V_CORTES is not null then
          Raise_application_error(-20000, 'Pedido possui cortes. |'||V_CORTES||'|');
        end if;

        V_CORREIO_ID             := null;
        V_CRRO_ASSUNTO           := substr(V_PDSD_NR_PEDIDO||'|'||V_PRCR_CGC_CPF||'|',1,40);
        V_CRRO_DESTINATARIO      := P_USER;
        V_CRRO_REMETENTE         := 'UserSystem';
        V_CRRO_MENSAGEM          := substr('|Pedido: '    ||V_PDSD_NR_PEDIDO                       ||' '||chr(10)||
                                           '|Ordem: '     ||C_TC.MLOR_ORDER_ID                     ||' '||chr(10)||
                                           '|Cliente: '   ||V_PRCR_NOME||' ('||V_PRCR_CGC_CPF||')' ||' '||chr(10)||
                                           '|Posicao: '   ||V_PDSD_STATUS                          ||' '||chr(10)||
                                           '|Status: '    ||V_STATUS                               ||' '||chr(10)||
                                           '|Valor: '     ||V_PDSD_VLR_TOTAL                       ||' '||chr(10)||
                                           '|Cortes: '    ||NVL(V_CORTES,' ')                      ||' '||chr(10)||
                                           V_PDSD_MOT_CANCELAMENTO ,1,2000);
        V_CRRO_DATA_ENVIO        := null;
        V_CRRO_DATA_LIDO         := null;
        V_CRRO_EXPORTADO_POCKET  := 'Nao';
        V_ACTION                 := 1;
        V_TRANSACTION            := 1;

        MAN_CORREIO(V_CORREIO_ID        ,V_CRRO_REMETENTE        ,
                    V_CRRO_DESTINATARIO ,V_CRRO_ASSUNTO          ,
                    V_CRRO_MENSAGEM     ,V_CRRO_DATA_ENVIO       ,
                    V_CRRO_DATA_LIDO    ,V_CRRO_EXPORTADO_POCKET ,
                    V_ACTION            ,P_STATUS                ,
                    V_TRANSACTION       ,V_CRRO_REMETENTE        ,
                    V_CRRO_REMETENTE    ,P_TERMINAL              ,
                    P_MESSAGE           );

        -- Amarra o pedido de venda...
        update MERC_LIVRE_ORDEM M
           set M.PEDIDO_SAIDA_ID   = V_PEDIDO_SAIDA_ID,
               M.DATA_ALTERACAO    = V_DATE_ACTION,
               M.USUARIO_ALTERACAO = P_USER
         where M.MERC_LIVRE_ORDEM_ID = P_MERC_LIVRE_ORDEM_ID;

      end loop;
    end if;
  end if;

  if P_TRANSACTION = 0 then
    commit;
  end if;

end PRC_MLAPI_PDSD_INSERT;
/

