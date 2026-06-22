create or replace view view_mlor_nfe as
select PS.PEDIDO_SAIDA_ID         PEDIDO_SAIDA_ID,
       PS.PDSD_NR_PEDIDO          NR_PEDIDO,
       ME.MOVIMENTO_ESTOQUE_ID    MOVIMENTO_ESTOQUE_ID,
       ME.UNIDADE_EMPRESARIAL_ID  UNIDADE_EMPRESARIAL_ID,
       ME.MOVI_NR_NOTA_FISCAL     NFE,
       ME.MOVI_SR_NOTA_FISCAL     SR,
       ME.MOVI_VLR_TOTAL          VALOR,      
       NFE.NFE_ENVIO_ID           NFE_ENVIO_ID,
       NFE.NFEE_CHAVE             NFE_CHAVE,
       NFE.NFEE_3_JSON_PROCESSADO NFE_XML,
       MLO.MERC_LIVRE_ORDEM_ID    MERC_LIVRE_ORDEM_ID,
       MLO.MLOR_ORDER_ID          MLOR_ORDER_ID,
       MLO.MLOR_XML_DT_ENVIO      MLOR_XML_DT_ENVIO

  from PEDIDO_SAIDA      PS,
       PEDIDO_FATURADO   PF,
       MOVIMENTO_ESTOQUE ME,
       NFE_ENVIO         NFE,
       MERC_LIVRE_ORDEM  MLO
       
 where PS.PEDIDO_SAIDA_ID          = PF.PEDIDO_SAIDA_ID
   and PF.PEDIDO_FATURADO_ID       = ME.MOVI_CAMPO_RELATIVO_PED_ID
   and ME.MOVI_TABELA_RELATIVA_PED = 'PEDIDO_FATURADO'
   and ME.MOVIMENTO_ESTOQUE_ID     = NFE.NFEE_MOV
   and PS.PEDIDO_SAIDA_ID          = MLO.PEDIDO_SAIDA_ID
   and PS.PDSD_STATUS              = 'Faturado'
   and PS.STATUS                   = 'Ativo'
   and ME.STATUS                   = 'Ativo'
   and NFE.NFEE_SIT_SEFAZ          = 'Aceito'   
   
   
   
