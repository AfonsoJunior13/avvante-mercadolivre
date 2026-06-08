create or replace procedure horus.PRC_MLAPI_ORDEM_ITEM_UPDATE
(
  P_MLOI_ORDER_ID    in MERC_LIVRE_ORDEM_ITEM.MLOI_ORDER_ID   %type,
  P_MLOI_PRODUTO_ID  in MERC_LIVRE_ORDEM_ITEM.MLOI_PRODUTO_ID %type,
  P_MLOI_QUANTITY    in MERC_LIVRE_ORDEM_ITEM.MLOI_QUANTITY   %type,
  P_MLOI_UNIT_PRICE  in MERC_LIVRE_ORDEM_ITEM.MLOI_UNIT_PRICE %type,
  P_MLOI_SKU         in MERC_LIVRE_ORDEM_ITEM.MLOI_SKU        %type,
  P_MLOI_GTIN        in MERC_LIVRE_ORDEM_ITEM.MLOI_GTIN       %type,
  P_MLOI_SALE_FEE    in MERC_LIVRE_ORDEM_ITEM.MLOI_SALE_FEE   %type,
  
  P_TRANSACTION      in number

) is
  
  V_MERC_LIVRE_ORDEM_ITEM_ID  MERC_LIVRE_ORDEM_ITEM.MERC_LIVRE_ORDEM_ITEM_ID %type;
  V_MLOI_SKU                  MERC_LIVRE_ORDEM_ITEM.MLOI_SKU                 %type;
  V_MLOI_GTIN                 MERC_LIVRE_ORDEM_ITEM.MLOI_GTIN                %type;
  
begin
   
   begin
     select M.MERC_LIVRE_ORDEM_ITEM_ID
       into V_MERC_LIVRE_ORDEM_ITEM_ID
       from MERC_LIVRE_ORDEM_ITEM M
      where MLOI_ORDER_ID   = P_MLOI_ORDER_ID
        and MLOI_PRODUTO_ID = P_MLOI_PRODUTO_ID;      
   exception when NO_DATA_FOUND then
     V_MERC_LIVRE_ORDEM_ITEM_ID := null; 
   end;
   
   begin
     select M.MLPD_GTIN,
            M.MLPD_SKU
       into V_MLOI_SKU,
            V_MLOI_GTIN
       from MERC_LIVRE_PRODUTO M
      where M.MLPD_ID = P_MLOI_PRODUTO_ID;     
   exception when others then
     V_MLOI_SKU  := null;
     V_MLOI_GTIN := null;
   end;
   
   if V_MERC_LIVRE_ORDEM_ITEM_ID is null then
     V_MERC_LIVRE_ORDEM_ITEM_ID := GENERATE_NEXT_ID('MERC_LIVRE_ORDEM_ITEM','UserSystem','TermSystem');
       
     insert into MERC_LIVRE_ORDEM_ITEM(MERC_LIVRE_ORDEM_ITEM_ID ,MLOI_ORDER_ID ,
                                       MLOI_PRODUTO_ID          ,MLOI_QUANTITY ,
                                       MLOI_UNIT_PRICE          ,MLOI_SKU      ,
                                       MLOI_GTIN                ,MLOI_SALE_FEE ,          
                                       USUARIO_INCLUSAO         ,DATA_INCLUSAO ,
                                       STATUS                   )
                                         
     values                           (V_MERC_LIVRE_ORDEM_ITEM_ID ,P_MLOI_ORDER_ID ,
                                       P_MLOI_PRODUTO_ID          ,P_MLOI_QUANTITY ,
                                       P_MLOI_UNIT_PRICE          ,V_MLOI_SKU      ,
                                       V_MLOI_GTIN                ,P_MLOI_SALE_FEE ,
                                       'UserSystem'               ,sysdate       ,
                                       'Ativo'                    );     
   else
     update MERC_LIVRE_ORDEM_ITEM
        set MLOI_QUANTITY     = P_MLOI_QUANTITY,
            MLOI_UNIT_PRICE   = P_MLOI_UNIT_PRICE,
            MLOI_SKU          = V_MLOI_SKU,
            MLOI_GTIN         = V_MLOI_GTIN,
            MLOI_SALE_FEE     = P_MLOI_SALE_FEE
      where MERC_LIVRE_ORDEM_ITEM_ID = V_MERC_LIVRE_ORDEM_ITEM_ID;
   end if;   
  
   if P_TRANSACTION = 0 then
     commit;
   end if;

end PRC_MLAPI_ORDEM_ITEM_UPDATE;
/

