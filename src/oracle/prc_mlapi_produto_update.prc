create or replace procedure desenv.PRC_MLAPI_PRODUTO_UPDATE
(
  P_UNIDADE_EMPRESARIAL_ID  in MERC_LIVRE_PRODUTO.UNIDADE_EMPRESARIAL_ID  %type,
  P_MLPD_ID                 in MERC_LIVRE_PRODUTO.MLPD_ID                 %type,
  P_MLPD_TITLE              in MERC_LIVRE_PRODUTO.MLPD_TITLE              %type,
  P_MLPD_SELLER_ID          in MERC_LIVRE_PRODUTO.MLPD_SELLER_ID          %type,
  P_MLPD_CATEGORY_ID        in MERC_LIVRE_PRODUTO.MLPD_CATEGORY_ID        %type,
  P_MLPD_USER_PRODUCT_ID    in MERC_LIVRE_PRODUTO.MLPD_USER_PRODUCT_ID    %type,
  P_MLPD_PRICE              in MERC_LIVRE_PRODUTO.MLPD_PRICE              %type,
  P_MLPD_BASE_PRICE         in MERC_LIVRE_PRODUTO.MLPD_BASE_PRICE         %type,
  P_MLPD_ORIGINAL_PRICE     in MERC_LIVRE_PRODUTO.MLPD_ORIGINAL_PRICE     %type,
  P_MLPD_INITIAL_QUANTITY   in MERC_LIVRE_PRODUTO.MLPD_INITIAL_QUANTITY   %type,
  P_MLPD_AVAILABLE_QUANTITY in MERC_LIVRE_PRODUTO.MLPD_AVAILABLE_QUANTITY %type,
  P_MLPD_SOLD_QUANTITY      in MERC_LIVRE_PRODUTO.MLPD_SOLD_QUANTITY      %type,
  P_MLPD_LISTING_TYPE_ID    in MERC_LIVRE_PRODUTO.MLPD_LISTING_TYPE_ID    %type,
  P_MLPD_PERMALINK          in MERC_LIVRE_PRODUTO.MLPD_PERMALINK          %type,
  P_MLPD_DATE_CREATED       in MERC_LIVRE_PRODUTO.MLPD_DATE_CREATED       %type,
  P_MLPD_LAST_UPDATED       in MERC_LIVRE_PRODUTO.MLPD_LAST_UPDATED       %type,
  P_MLPD_GTIN               in MERC_LIVRE_PRODUTO.MLPD_GTIN               %type,
  P_MLPD_SKU                in MERC_LIVRE_PRODUTO.MLPD_SKU                %type,

  P_TRANSACTION             in number

) is

  V_MERC_LIVRE_PRODUTO_ID  MERC_LIVRE_PRODUTO.MERC_LIVRE_PRODUTO_ID %type;
  V_PRODUTO_ID             MERC_LIVRE_PRODUTO.PRODUTO_ID            %type;
  V_EMBALAGEM_VENDA_ID     MERC_LIVRE_PRODUTO.EMBALAGEM_VENDA_ID    %type;
  V_MLCN_SKU_PRODUTO       MERC_LIVRE_CONFIG.MLCN_SKU_PRODUTO       %type;

begin

   begin
     select M.MERC_LIVRE_PRODUTO_ID
       into V_MERC_LIVRE_PRODUTO_ID
       from MERC_LIVRE_PRODUTO M
      where MLPD_ID = P_MLPD_ID;
   exception when NO_DATA_FOUND then
     V_MERC_LIVRE_PRODUTO_ID := null;
   end;
   
   select nvl(M.MLCN_SKU_PRODUTO,'Nao')
     into V_MLCN_SKU_PRODUTO
     from MERC_LIVRE_CONFIG M
    where M.UNIDADE_EMPRESARIAL_ID = P_UNIDADE_EMPRESARIAL_ID; 
   
   if V_MLCN_SKU_PRODUTO = 'Sim' then
     
     begin
       select P.PRODUTO_ID
         into V_PRODUTO_ID
         from PRODUTO P
        where P.PRDT_CODIGO = V_MLCN_SKU_PRODUTO
          and P.STATUS      = 'Ativo';
     exception when NO_DATA_FOUND then     
       V_PRODUTO_ID := null;
     end;
     
     begin
       select EV.EMBALAGEM_VENDA_ID
         into V_EMBALAGEM_VENDA_ID
         from EMBALAGEM_VENDA EV
        where EV.PRODUTO_ID     = V_PRODUTO_ID
          and EV.STATUS         = 'Ativo'
          and EV.EMBV_COD_BARRA = P_MLPD_GTIN
          and ROWNUM <= 1;
      exception when NO_DATA_FOUND then
        V_EMBALAGEM_VENDA_ID := null;
      end;       
      
      if V_EMBALAGEM_VENDA_ID is null then
        -- Se tiver somente uma embalagem pega a embalagem que existe...
        begin
          select EV.EMBALAGEM_VENDA_ID
            into V_EMBALAGEM_VENDA_ID
            from EMBALAGEM_VENDA EV
           where EV.PRODUTO_ID = V_PRODUTO_ID
             and EV.STATUS     = 'Ativo'
             and ROWNUM <= 1;
         exception when others then
           V_EMBALAGEM_VENDA_ID := null;
         end;               
      end if;
      
   end if;
   
   if V_MERC_LIVRE_PRODUTO_ID is null then
     V_MERC_LIVRE_PRODUTO_ID := GENERATE_NEXT_ID('MERC_LIVRE_PRODUTO','UserSystem','TermSystem');

     insert into MERC_LIVRE_PRODUTO(MERC_LIVRE_PRODUTO_ID   ,
                                    UNIDADE_EMPRESARIAL_ID  ,
                                    MLPD_ID                 ,
                                    MLPD_TITLE              ,
                                    MLPD_SELLER_ID          ,
                                    MLPD_CATEGORY_ID        ,
                                    MLPD_USER_PRODUCT_ID    ,
                                    MLPD_PRICE              ,
                                    MLPD_BASE_PRICE         ,
                                    MLPD_ORIGINAL_PRICE     ,
                                    MLPD_INITIAL_QUANTITY   ,
                                    MLPD_AVAILABLE_QUANTITY ,
                                    MLPD_SOLD_QUANTITY      ,
                                    MLPD_LISTING_TYPE_ID    ,
                                    MLPD_PERMALINK          ,
                                    MLPD_DATE_CREATED       ,
                                    MLPD_LAST_UPDATED       ,
                                    MLPD_GTIN               ,
                                    MLPD_SKU                ,
                                    PRODUTO_ID              ,
                                    EMBALAGEM_VENDA_ID      ,
                                    MLPD_QTDE               ,
                                    USUARIO_INCLUSAO        ,
                                    DATA_INCLUSAO           ,
                                    STATUS                  )

     values                        (V_MERC_LIVRE_PRODUTO_ID   ,
                                    P_UNIDADE_EMPRESARIAL_ID  ,
                                    P_MLPD_ID                 ,
                                    P_MLPD_TITLE              ,
                                    P_MLPD_SELLER_ID          ,
                                    P_MLPD_CATEGORY_ID        ,
                                    P_MLPD_USER_PRODUCT_ID    ,
                                    P_MLPD_PRICE              ,
                                    P_MLPD_BASE_PRICE         ,
                                    P_MLPD_ORIGINAL_PRICE     ,
                                    P_MLPD_INITIAL_QUANTITY   ,
                                    P_MLPD_AVAILABLE_QUANTITY ,
                                    P_MLPD_SOLD_QUANTITY      ,
                                    P_MLPD_LISTING_TYPE_ID    ,
                                    P_MLPD_PERMALINK          ,
                                    P_MLPD_DATE_CREATED       ,
                                    P_MLPD_LAST_UPDATED       ,
                                    P_MLPD_GTIN               ,
                                    P_MLPD_SKU                ,
                                    V_PRODUTO_ID              ,
                                    V_EMBALAGEM_VENDA_ID      ,
                                    1                         ,
                                    'UserSystem'              ,
                                    sysdate                   ,
                                    'Ativo'                   );
   else
     update MERC_LIVRE_PRODUTO
        set MLPD_TITLE              = P_MLPD_TITLE,
            MLPD_SELLER_ID          = P_MLPD_SELLER_ID,
            MLPD_CATEGORY_ID        = P_MLPD_CATEGORY_ID,
            MLPD_USER_PRODUCT_ID    = P_MLPD_USER_PRODUCT_ID,
            MLPD_PRICE              = P_MLPD_PRICE,
            MLPD_BASE_PRICE         = P_MLPD_BASE_PRICE,
            MLPD_ORIGINAL_PRICE     = P_MLPD_ORIGINAL_PRICE,
            MLPD_INITIAL_QUANTITY   = P_MLPD_INITIAL_QUANTITY,
            MLPD_AVAILABLE_QUANTITY = P_MLPD_AVAILABLE_QUANTITY,
            MLPD_SOLD_QUANTITY      = P_MLPD_SOLD_QUANTITY,
            MLPD_LISTING_TYPE_ID    = P_MLPD_LISTING_TYPE_ID,
            MLPD_PERMALINK          = P_MLPD_PERMALINK,
            MLPD_DATE_CREATED       = P_MLPD_DATE_CREATED,
            MLPD_LAST_UPDATED       = P_MLPD_LAST_UPDATED,
            MLPD_GTIN               = P_MLPD_GTIN,
            MLPD_SKU                = P_MLPD_SKU,
            PRODUTO_ID              = NVL(PRODUTO_ID,V_PRODUTO_ID),
            EMBALAGEM_VENDA_ID      = nvl(EMBALAGEM_VENDA_ID,V_EMBALAGEM_VENDA_ID)
      where MERC_LIVRE_PRODUTO_ID = V_MERC_LIVRE_PRODUTO_ID;
   end if;

   if P_TRANSACTION = 0 then
     commit;
   end if;

end PRC_MLAPI_PRODUTO_UPDATE;
/

