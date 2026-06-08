create or replace procedure horus.PRC_MLAPI_PRODUTO_UPDATE
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

begin
   
   begin
     select M.MERC_LIVRE_PRODUTO_ID
       into V_MERC_LIVRE_PRODUTO_ID
       from MERC_LIVRE_PRODUTO M
      where MLPD_ID = P_MLPD_ID;      
   exception when NO_DATA_FOUND then
     V_MERC_LIVRE_PRODUTO_ID := null; 
   end;
   
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
            MLPD_SKU                = P_MLPD_SKU
      where MERC_LIVRE_PRODUTO_ID = V_MERC_LIVRE_PRODUTO_ID;
   end if;
  
   if P_TRANSACTION = 0 then
     commit;
   end if;

end PRC_MLAPI_PRODUTO_UPDATE;
/

