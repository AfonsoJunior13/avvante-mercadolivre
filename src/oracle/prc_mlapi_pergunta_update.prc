create or replace procedure desenv.PRC_MLAPI_PERGUNTA_UPDATE
(
  P_UNIDADE_EMPRESARIAL_ID in  MERC_LIVRE_PERGUNTA.UNIDADE_EMPRESARIAL_ID %type,
  P_MLQT_QUESTION_ID       in  MERC_LIVRE_PERGUNTA.MLQT_QUESTION_ID       %type,
  P_MLQT_ITEM_ID           in  MERC_LIVRE_PERGUNTA.MLQT_ITEM_ID           %type,
  P_MLQT_SELLER_ID         in  MERC_LIVRE_PERGUNTA.MLQT_SELLER_ID         %type,
  P_MLQT_STATUS            in  MERC_LIVRE_PERGUNTA.MLQT_STATUS            %type,
  P_MLQT_TEXT              in  MERC_LIVRE_PERGUNTA.MLQT_TEXT              %type,
  P_MLQT_DATE_CREATED      in  MERC_LIVRE_PERGUNTA.MLQT_DATE_CREATED      %type,
  P_MLQT_FROM_USER_ID      in  MERC_LIVRE_PERGUNTA.MLQT_FROM_USER_ID      %type,
  P_MLQT_HOLD              in  MERC_LIVRE_PERGUNTA.MLQT_HOLD              %type,
  P_MLQT_DELETED_LISTING   in  MERC_LIVRE_PERGUNTA.MLQT_DELETED_LISTING   %type,
  P_MLQT_ANSWER_TEXT       in  MERC_LIVRE_PERGUNTA.MLQT_ANSWER_TEXT       %type,
  P_MLQT_ANSWER_STATUS     in  MERC_LIVRE_PERGUNTA.MLQT_ANSWER_STATUS     %type,
  P_MLQT_ANSWER_DATE       in  MERC_LIVRE_PERGUNTA.MLQT_ANSWER_DATE       %type,
  P_MLQT_BUYER_NOME        in  MERC_LIVRE_PERGUNTA.MLQT_BUYER_NOME        %type,
  P_MLQT_BUYER_EMAIL       in  MERC_LIVRE_PERGUNTA.MLQT_BUYER_EMAIL       %type,
  P_MLQT_BUYER_PHONE       in  MERC_LIVRE_PERGUNTA.MLQT_BUYER_PHONE       %type,

  P_TRANSACTION            in  number

) is

  V_MERC_LIVRE_PERGUNTA_ID  MERC_LIVRE_PERGUNTA.MERC_LIVRE_PERGUNTA_ID %type;

begin

   begin
     select M.MERC_LIVRE_PERGUNTA_ID
       into V_MERC_LIVRE_PERGUNTA_ID
       from MERC_LIVRE_PERGUNTA M
      where MLQT_QUESTION_ID = P_MLQT_QUESTION_ID;
   exception when NO_DATA_FOUND then
     V_MERC_LIVRE_PERGUNTA_ID := null;
   end;

   if V_MERC_LIVRE_PERGUNTA_ID is null then
     V_MERC_LIVRE_PERGUNTA_ID := GENERATE_NEXT_ID('MERC_LIVRE_PERGUNTA','UserSystem','TermSystem');

     insert into MERC_LIVRE_PERGUNTA(MERC_LIVRE_PERGUNTA_ID    ,UNIDADE_EMPRESARIAL_ID ,
                                       MLQT_QUESTION_ID          ,MLQT_ITEM_ID           ,
                                       MLQT_SELLER_ID            ,MLQT_STATUS            ,
                                       MLQT_TEXT                 ,MLQT_DATE_CREATED      ,
                                       MLQT_FROM_USER_ID         ,MLQT_HOLD              ,
                                       MLQT_DELETED_LISTING      ,MLQT_ANSWER_TEXT       ,
                                       MLQT_ANSWER_STATUS        ,MLQT_ANSWER_DATE       ,
                                       MLQT_BUYER_NOME           ,MLQT_BUYER_EMAIL       ,
                                       MLQT_BUYER_PHONE          ,
                                       USUARIO_INCLUSAO          ,DATA_INCLUSAO          ,
                                       STATUS                    )

     values                           (V_MERC_LIVRE_PERGUNTA_ID  ,P_UNIDADE_EMPRESARIAL_ID ,
                                       P_MLQT_QUESTION_ID        ,P_MLQT_ITEM_ID         ,
                                       P_MLQT_SELLER_ID          ,P_MLQT_STATUS          ,
                                       P_MLQT_TEXT               ,P_MLQT_DATE_CREATED    ,
                                       P_MLQT_FROM_USER_ID       ,P_MLQT_HOLD            ,
                                       P_MLQT_DELETED_LISTING    ,P_MLQT_ANSWER_TEXT     ,
                                       P_MLQT_ANSWER_STATUS      ,P_MLQT_ANSWER_DATE     ,
                                       P_MLQT_BUYER_NOME         ,P_MLQT_BUYER_EMAIL     ,
                                       P_MLQT_BUYER_PHONE        ,
                                       'UserSystem'              ,sysdate                ,
                                       'Ativo'                   );
   else
     update MERC_LIVRE_PERGUNTA
        set MLQT_ITEM_ID         = P_MLQT_ITEM_ID,
            MLQT_SELLER_ID       = P_MLQT_SELLER_ID,
            MLQT_STATUS          = P_MLQT_STATUS,
            MLQT_TEXT            = P_MLQT_TEXT,
            MLQT_DATE_CREATED    = P_MLQT_DATE_CREATED,
            MLQT_FROM_USER_ID    = P_MLQT_FROM_USER_ID,
            MLQT_HOLD            = P_MLQT_HOLD,
            MLQT_DELETED_LISTING = P_MLQT_DELETED_LISTING,
            MLQT_ANSWER_TEXT     = P_MLQT_ANSWER_TEXT,
            MLQT_ANSWER_STATUS   = P_MLQT_ANSWER_STATUS,
            MLQT_ANSWER_DATE     = P_MLQT_ANSWER_DATE,
            MLQT_BUYER_NOME      = P_MLQT_BUYER_NOME,
            MLQT_BUYER_EMAIL     = P_MLQT_BUYER_EMAIL,
            MLQT_BUYER_PHONE     = P_MLQT_BUYER_PHONE,
            DATA_ALTERACAO       = sysdate,
            USUARIO_ALTERACAO    = 'UserSystem'
      where MERC_LIVRE_PERGUNTA_ID = V_MERC_LIVRE_PERGUNTA_ID;
   end if;

   if P_TRANSACTION = 0 then
     commit;
   end if;

end PRC_MLAPI_PERGUNTA_UPDATE;
/
