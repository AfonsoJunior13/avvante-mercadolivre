create or replace force view horus.view_merc_livre_produto as
select M.MLPD_ID                   ML_PRODUTO_ID,
       M.MLPD_TITLE                TITULO,
       M.MLPD_CATEGORY_ID          CATEGORIA_ID,
       M.MLPD_PRICE                PRECO,
       M.MLPD_AVAILABLE_QUANTITY   QTDE_ESTOQUE,
       M.MLPD_SOLD_QUANTITY        QTDE_VENDIDA,
       M.MLPD_GTIN                 GTIN,
       M.MLPD_SKU                  SKU,
       M.MLPD_PERMALINK            URL_VEND,
       M.UNIDADE_EMPRESARIAL_ID
  from MERC_LIVRE_PRODUTO M
order by M.MLPD_ID;

