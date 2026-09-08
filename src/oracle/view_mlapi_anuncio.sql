create or replace view view_mlapi_anuncio as
select MLA.UNIDADE_EMPRESARIAL_ID,
        MLA.MERC_LIVRE_ANUNCIO_ID,
        MLA.MLAN_ID,
        MLA.MLAN_USER_PRODUCT_ID,
        MLT.MLTA_ID                  MLTA_TP_ANUNCIO_ID,
        MLC.MLCA_ID                  MLTA_CATEGORIA_ID,
        MLA.MLAN_TITULO,
        MLA.MLAN_DESCRICAO,
        MLA.MLAN_PRECO,
        MLA.MLAN_QTDE,
        MLA.MLAN_CONDICAO,
        MA.MARC_DESCRICAO            MLTA_MARCA_DESCRICAO,
        MLA.MLAN_MODELO,
        MLA.MLAN_GTIN,
        MLA.MLAN_SKU,
        MLA.MLAN_GARANTIA_TIPO,
        MLA.MLAN_GARANTIA_TEMPO,
        MLA.MLAN_ALTURA_CM,
        MLA.MLAN_COMPRIMENTO_CM,
        MLA.MLAN_LARGURA_CM,
        MLA.MLAN_PESO,
        MLA.MLAN_MODO_ENVIO,
        upper(MLA.MLAN_ACAO)         MLAN_ACAO

   from MERC_LIVRE_ANUNCIO    MLA,
        MERC_LIVRE_CATEGORIA  MLC,
        MERC_LIVRE_TP_ANUNCIO MLT,
        MARCAS                MA

  where MLA.MERC_LIVRE_CATEGORIA_ID  = MLC.MERC_LIVRE_CATEGORIA_ID
    and MLA.MERC_LIVRE_TP_ANUNCIO_ID = MLT.MERC_LIVRE_TP_ANUNCIO_ID
    and MLA.MARCAS_ID                = MA.MARCA_ID(+)

    and MLA.MLAN_ACAO               in ('Publicar','Atualizar','Pausar','Ativar','Encerrar','Excluir');
