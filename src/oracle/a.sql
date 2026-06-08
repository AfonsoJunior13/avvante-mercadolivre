prompt PL/SQL Developer Export User Objects for user DESENV@AVVANTE
prompt Created by João Afonso on sexta-feira, 15 de agosto de 2025
set define off
spool a.log

prompt
prompt Creating table MERC_LIVRE_CATEGORIA
prompt ===================================
prompt
@@merc_livre_categoria.tab
prompt
prompt Creating table MERC_LIVRE_CONFIG
prompt ================================
prompt
@@merc_livre_config.tab
prompt
prompt Creating table MERC_LIVRE_ORDEM
prompt ===============================
prompt
@@merc_livre_ordem.tab
prompt
prompt Creating table MERC_LIVRE_ORDEM_END
prompt ===================================
prompt
@@merc_livre_ordem_end.tab
prompt
prompt Creating table MERC_LIVRE_ORDEM_ITEM
prompt ====================================
prompt
@@merc_livre_ordem_item.tab
prompt
prompt Creating table MERC_LIVRE_PRDT
prompt ==============================
prompt
@@merc_livre_prdt.tab
prompt
prompt Creating table MERC_LIVRE_PRDT_IMAGEM
prompt =====================================
prompt
@@merc_livre_prdt_imagem.tab
prompt
prompt Creating table MERC_LIVRE_PRODUTO
prompt =================================
prompt
@@merc_livre_produto.tab
prompt
prompt Creating table MERC_LIVRE_TP_ANUNCIO
prompt ====================================
prompt
@@merc_livre_tp_anuncio.tab

prompt Done
spool off
set define on
