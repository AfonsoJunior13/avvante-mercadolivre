# Publicação de anúncios Horus → Mercado Livre

> Guia de implementação para **enviar** (criar/atualizar) anúncios no Mercado Livre Brasil (`MLB`).
> Compilado via MCP `mercadolibre-mcp-server` (docs oficiais, pt_br, 2026).
>
> Complementa [MercadoLivre-API.md](MercadoLivre-API.md), [CONTEXTO-IA.md](CONTEXTO-IA.md) e [ARQUITETURA.md](ARQUITETURA.md).
>
> **Estado no projeto:** o worker **publica** a fila (`VIEW_MLAPI_ANUNCIO` / `VIEW_MLAPI_ANUNCIO_IMAGEM` → `POST /items`) e também **puxa** anúncios (`GET /items`). A NF-e de venda já é enviada ao ML.
>
> **Modelo Horus:** o anúncio fica em `MERC_LIVRE_ANUNCIO`; as embalagens de venda entram em `MERC_LIVRE_ANUNCIO_EV` (a embalagem já aponta para o produto). O worker lê `VIEW_MLAPI_ANUNCIO` (dados) e `VIEW_MLAPI_ANUNCIO_IMAGEM` (fotos). Detalhe na [§7](#7-gap-horus--o-que-a-api-exige).

**Portal:** https://developers.mercadolivre.com.br/pt_br/publicacao-de-produtos  
**Endpoint:** `POST https://api.mercadolibre.com/items`  
**Auth:** `Authorization: Bearer {MLCN_ACCESS_TOKEN}` (mesmo token já usado no worker)

---

## 1. O que precisa estar pronto antes de publicar

| Pré-requisito | Por quê |
|---------------|---------|
| App DevCenter com escopo **offline leitura/escrita** | POST/PUT em `/items` |
| Permissão funcional **Publicação e sincronização** | Sem ela → HTTP 403 |
| Token OAuth da conta **vendedora** (administrador) | O anúncio nasce nessa conta |
| Usuário de **teste** para a primeira rodada | Não existe sandbox; anúncio de teste fica visível no site |
| Conta com Mercado Envios 2 habilitado (recomendado) | `GET /users/{id}/shipping_preferences` deve listar `me2` |
| Saber se o vendedor já é **User Products** | `GET /users/{id}` → tag `user_product_seller` |

### Decisão crítica: modelo clássico vs User Products

O Mercado Livre migrou vendedores para o modelo **User Products** (UP). Isso muda o payload.

| | Modelo clássico (legado) | User Products (novo) |
|---|---|---|
| Como identificar o vendedor | Sem a tag `user_product_seller` | Tag `user_product_seller` em `/users/{id}` |
| Título | Campo `title` **obrigatório** | **Não enviar** `title` — o ML gera |
| Nome do produto | `title` | `family_name` **obrigatório** |
| Variações (cor/tamanho) | Array `variations` no mesmo item | **Um item por variação**; mesmo `family_name` agrupa a família |
| SKU interno | Atributo `SELLER_SKU` | Idem |

**Recomendação para o Horus:** implementar já no modelo User Products. Se a conta ainda não tiver a tag, o POST clássico com `title` continua válido — mas o código deve ramificar pela tag, senão a publicação quebra no dia da ativação.

Consultar:

```http
GET /users/{MLCN_USER_ID}
```

---

## 2. Fluxo recomendado (passo a passo)

```
1. Ler fila no Horus
   VIEW_MLAPI_ANUNCIO          → dados do anúncio
   VIEW_MLAPI_ANUNCIO_IMAGEM   → fotos (FOPR_FOTO)
2. Predizer categoria          GET /sites/MLB/domain_discovery/search?q={titulo}
3. Carregar regras da categoria GET /categories/{id}
                                GET /categories/{id}/attributes
                                GET /categories/{id}/sale_terms
4. Montar JSON do anúncio
5. Validar sem publicar         POST /items/validate     → HTTP 204 = ok
6. Publicar                     POST /items              → recebe item_id (MLB…)
7. Enviar descrição             POST /items/{id}/description
8. Gravar retorno no Horus      mlan_id, mlan_data_envio, permalink
```

Não publicar direto: o validador (`POST /items/validate`) devolve os campos faltantes **sem criar** o anúncio. HTTP 204 = payload aceito.

---

## 3. Campos do `POST /items`

Legenda de obrigatoriedade:

- **Obrigatório** — a API recusa o POST sem o campo
- **Condicional** — obrigatório conforme categoria, condição do item ou logística
- **Recomendado** — não bloqueia o POST, mas anúncio fica moderado/penalizado sem ele
- **Opcional** — melhorar qualidade / operação

### 3.1 Identidade e exposição

| Campo API | Obrig. | Tipo | Significado | Origem sugerida no Horus |
|-----------|--------|------|-------------|--------------------------|
| `title` | Obrig. no modelo clássico. **Proibido** no UP | string | Título visível na busca. Estrutura: *Produto + Marca + Modelo + especificações*. Sem “frete grátis”, “estoque”, “novo”. Limite = `max_title_length` da categoria (em geral 60). | Nome da embalagem/produto |
| `family_name` | Obrig. no **User Products** | string | Nome genérico da família (ex.: `"Furadeira Bosch 550W"`). Cobre todas as cores/tamanhos. Tamanho ≤ `max_title_length` do domínio. | Nome do produto **sem** variação |
| `category_id` | **Obrigatório** | string | Folha da árvore MLB (ex.: `MLB269615`). Só IDs com `listing_allowed=true` e `status=enabled`. | Preditor ML ou cadastro no Horus |
| `listing_type_id` | **Obrigatório** | string | Tipo/exposição do anúncio. Ver [§4](#4-tipos-de-anúncio-mlb). | `MERC_LIVRE_ANUNCIO.MLAN_TP_ANUNCIO` |
| `buying_mode` | **Obrigatório** | string | Sempre `"buy_it_now"` em MLB (compra imediata; pedido só aparece com pagamento aprovado). | Fixo |
| `currency_id` | **Obrigatório** | string | Sempre `"BRL"` neste projeto. | Fixo |
| `channels` | Recomendado | array | Canal. Usar `["marketplace"]`. Não usar mais `exclusive_channel`. | Fixo |

Consultar categoria:

```http
GET /categories/{CATEGORY_ID}
```

Campos úteis da resposta: `max_title_length`, `max_pictures_per_item`, `max_description_length`, `shipping_modes`, `item_conditions`, `listing_allowed`, `status`.

Preditor (quando o Horus não tiver categoria ML):

```http
GET /sites/MLB/domain_discovery/search?limit=1&q={titulo}
```

### 3.2 Preço e estoque

| Campo API | Obrig. | Tipo | Significado | Origem sugerida no Horus |
|-----------|--------|------|-------------|--------------------------|
| `price` | **Obrigatório** | number | Preço de venda em BRL. Não enviar como string. | `MERC_LIVRE_ANUNCIO.MLAN_PRECO` |
| `available_quantity` | **Obrigatório** | number | Estoque à venda. `0` cria o anúncio **pausado** (`out_of_stock`) — útil para Full. Máximo depende do `listing_type` (`max_stock_per_item`). | `MERC_LIVRE_ANUNCIO.MLAN_QTDE` / estoque Horus |

Depois de publicado, preço deve ser alterado pela **API Prices** (`/items/{id}/prices`), não só pelo PUT genérico, se a conta usar o novo modelo de preços.

### 3.3 Condição do item

| Campo API | Obrig. | Tipo | Significado |
|-----------|--------|------|-------------|
| `condition` | Legado / retrocompatível | `"new"` \| `"used"` \| `"not_specified"` | Ainda aceito, mas **não usar em código novo**. |
| `attributes[]` com `id: "ITEM_CONDITION"` | **Obrigatório** em implementações novas | `value_id` da categoria | Valores típicos MLB: `2230284` Novo, `2230581` Usado, `2230582` Recondicionado. |

Recondicionado **obriga** garantia ≥ 90 dias em `sale_terms`.

Valores permitidos: `GET /categories/{id}/attributes` → atributo `ITEM_CONDITION`.

### 3.4 Fotos (`pictures`)

| Campo API | Obrig. | Tipo | Significado |
|-----------|--------|------|-------------|
| `pictures` | Quase sempre **obrigatório** (`requires_picture` no listing_type) | array | Lista de imagens do anúncio. A 1ª é a capa. |
| `pictures[].source` | — | URL pública | URL HTTP(S) de onde o ML **baixa** a foto. Sem redirect 301/302. **Não aceita caminho local** (`C:\fotos\produto.jpg`). |
| `pictures[].id` | — | string | ID já hospedado no CDN do ML (após upload do arquivo). |

Regras de arquivo:

| Item | Valor |
|------|--------|
| Formatos | JPG, JPEG, PNG (RGB; evitar CMYK) |
| Tamanho arquivo | até 10 MB |
| Resolução recomendada | 1200 × 1200 px (produto ~95% do quadro) |
| Mínimo | 500 × 500 px (abaixo → erro `cause_id` 509) |
| Máximo | 1920 × 1920 px (maior é redimensionado) |
| Quantidade | `max_pictures_per_item` da categoria (em geral 12) |
| Zoom | largura > 800 px |

Há **dois jeitos** de colocar a foto no anúncio. O arquivo no computador só entra pelo jeito 2.

#### Jeito 1 — URL pública (`source`)

O Mercado Livre **baixa** a imagem dos *seus* servidores. Você só passa o link no POST/PUT do item.

```json
"pictures": [
  { "source": "https://cdn.seudominio.com.br/produtos/furadeira-1.jpg" }
]
```

Requisitos da URL:

- Pública, estática, **sem login** e **sem redirect** 301/302 (enviar a URL final).
- Liberar na whitelist os IPs do ML: `216.33.196.4`, `216.33.196.25`, `54.88.218.97`, `18.215.140.160`, `18.213.114.129`, `18.206.34.84`.
- Certificado HTTPS inválido → o ML falha; nesse caso enviar `http://`.
- Trocar a foto: usar **outro nome de arquivo** na URL. Reusar o mesmo path com conteúdo novo **não atualiza**.

`C:\Fotos\produto.jpg` ou `\\servidor\share\foto.jpg` **não funcionam** aqui: os servidores do ML não acessam o PC/rede da empresa.

Tabela Horus das fotos: **não** há mais cadastro próprio no anúncio. `VIEW_MLAPI_ANUNCIO_IMAGEM` sobe as fotos do **produto** das embalagens amarradas (`MERC_LIVRE_ANUNCIO_EV` → `EMBALAGEM_VENDA` → `PRODUTO` → `FOTO_PRODUTO`). Caminho interno: `FOTO_PRODUTO.FOPR_FOTO` (upload multipart no worker).

#### Jeito 2 — arquivo do disco (multipart) — **sim, dá para enviar do computador**

O worker (ou um script) lê o JPG/PNG **local** e envia o binário para o ML. O ML hospeda no CDN e devolve um `id`. Esse `id` é que entra no anúncio.

**Passo A — upload do arquivo**

```http
POST https://api.mercadolibre.com/pictures/items/upload
Authorization: Bearer {ACCESS_TOKEN}
Content-Type: multipart/form-data

file = (bytes do JPG/PNG)
```

Exemplo em disco (curl):

```bash
curl -X POST "https://api.mercadolibre.com/pictures/items/upload" \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -F "file=@C:\Fotos\produtos\furadeira-1.jpg"
```

Só aceita **multipart** (arquivo de verdade). Não aceita JSON com path, nem URL neste endpoint.

Resposta (o que importa é o `id`):

```json
{
  "id": "123-MLA456_112021",
  "variations": [
    { "size": "1920x1076", "secure_url": "https://http2.mlstatic.com/D_NQ_NP_123-MLA456_112021-F.jpg" }
  ]
}
```

O endpoint aplica *smartcrop* (corta fundo excessivo).

**Passo B — associar o `id` ao anúncio**

Na **criação**:

```json
"pictures": [
  { "id": "123-MLA456_112021" }
]
```

Em anúncio **já existente**:

```http
POST /items/{ITEM_ID}/pictures
{ "id": "123-MLA456_112021" }
```

Ou substituir a lista inteira:

```http
PUT /items/{ITEM_ID}
{
  "pictures": [
    { "id": "NOVA_FOTO_ID" },
    { "id": "FOTO_ANTIGA_A_MANTER" }
  ]
}
```

Ordem do array = ordem na vitrine. A primeira é a capa. Para **remover**, reenviar só os `id` que devem ficar.

```
Arquivo no disco
    → POST /pictures/items/upload  (multipart, campo file)
    → picture_id
    → POST /items  (pictures[].id)   ou   POST /items/{id}/pictures
```

No worker: `src/services/anuncio/postImagem.js` lê `FOPR_FOTO` (LONG RAW) e envia multipart. Capa = `PRINCIPAL = Sim`.

**Onde o arquivo precisa estar:** no **servidor que roda o worker** (ou num share/UNC que esse processo consiga abrir). O Mercado Livre **não** lê a pasta do usuário. Se a foto está só no PC do operador, o ERP/Horus precisa gravá-la num caminho acessível ao worker (rede, storage, BLOB) **antes** do job.

#### Diagnóstico opcional (antes de publicar)

```http
POST /moderations/pictures/diagnostic
{
  "picture_url": "https://... ou data:image/jpeg;base64,...",
  "context": { "category_id": "MLB269615", "picture_type": "thumbnail" }
}
```

Detecta fundo não branco, tamanho mínimo, texto/logo e marca d’água. `picture_type`: `thumbnail` (capa), `variation_thumbnail`, `other`.

Erro de processamento: `GET /pictures/{PICTURE_ID}/errors`.

#### Qual jeito usar no Horus

| Situação | Caminho |
|----------|---------|
| Fotos já em CDN/site público | Jeito 1 (`source`) |
| Fotos em pasta do servidor, share ou disco do worker (`FOPR_FOTO`) | Jeito 2 (multipart) |
| Foto só no PC do usuário, sem upload para o Horus | **Não dá** direto na API — precisa primeiro salvar no ERP/servidor |

Recomendação: jeito 2 quando as imagens não forem publicamente baixáveis pelos IPs do ML (caso típico de arquivo interno). Evita whitelist, redirect e certificado.

### 3.5 Descrição (endpoint separado)

A descrição **não entra** no `POST /items`. Desde 2021 o campo `descriptions` no GET de item vem vazio.

Fluxo:

```
POST /items                         → cria o anúncio
POST /items/{ITEM_ID}/description   → { "plain_text": "..." }
```

Atualizar: `PUT /items/{ITEM_ID}/description?api_version=2`.

| Regra | Detalhe |
|-------|---------|
| Formato | Somente texto plano (`plain_text`) |
| Quebra de linha | `\n` |
| HTML / emoji / negrito | Proibido → `item.description.type.invalid` |
| Tamanho | `max_description_length` da categoria (até 50.000) |
| Conteúdo | Complementa a ficha técnica; **não repetir** atributos já em `attributes` |

Descrição: `MERC_LIVRE_ANUNCIO.MLAN_DESCRICAO` (`CLOB`). Envio depois do POST do item.

### 3.6 Garantia (`sale_terms`)

Consultar valores da categoria:

```http
GET /categories/{CATEGORY_ID}/sale_terms
```

| `id` | Obrig. | Significado | Exemplo |
|------|--------|-------------|---------|
| `WARRANTY_TYPE` | Recomendado; **obrigatório** se recondicionado | Tipo: garantia do vendedor (`2230280`) ou de fábrica (`2230279`). Também existe “Sem garantia”. | `"Garantia do vendedor"` |
| `WARRANTY_TIME` | Idem | Prazo. Tipo `number_unit`: `dias`, `meses`, `anos`. | `"90 dias"`, `"12 meses"` |

Recondicionado: mínimo **90 dias**.

### 3.7 Identificadores e ficha técnica (`attributes`)

Os atributos **mudam por categoria**. Não dá para fixar um schema único no Horus para todas as linhas. Sempre consultar:

```http
GET /categories/{CATEGORY_ID}/attributes
GET /categories/{CATEGORY_ID}/technical_specs/input
```

Tags que importam:

| Tag | Significado |
|-----|-------------|
| `required` | Obrigatório em item tradicional |
| `new_required` | Obrigatório se o item é novo |
| `conditional_required` | Pode ser obrigatório; confirmar em `POST /categories/{id}/attributes/conditional` |
| `allow_variations` | Define variação (cor, tamanho) — no UP vira item separado |
| `hidden` / `read_only` | Não enviar / não alterar |
| `multivalued` | Vários valores separados por vírgula |

Formato de cada atributo no POST:

```json
{ "id": "BRAND", "value_name": "Bosch" }
```

Ou, quando a lista for fechada, preferir `value_id` oficial.

#### Atributos transversais (quase todo produto)

| `id` | Obrig. | Significado | Origem Horus típica |
|------|--------|-------------|---------------------|
| `ITEM_CONDITION` | Obrig. (código novo) | Novo / usado / recondicionado | Cadastro |
| `BRAND` | Quase sempre `required` | Marca | Cadastro produto |
| `MODEL` | Frequente | Modelo | Cadastro |
| `GTIN` | `required` ou `conditional_required` | EAN/UPC/ISBN (8–14 dígitos). Vários códigos: separados por vírgula. **Não é SKU interno.** | `EMBALAGEM_VENDA.EMBV_COD_BARRA` |
| `EMPTY_GTIN_REASON` | Condicional | Só se **não** houver GTIN: `Artesanal`, `Kit`, `No registrado`, `Otro` | Cadastro |
| `SELLER_SKU` | Recomendado | SKU interno do vendedor (rastreio no pedido). **Não** usar `seller_custom_field`. | Código da embalagem |
| `SELLER_PACKAGE_HEIGHT` | Condicional (ME2) | Altura do pacote, **cm** | Embalagem |
| `SELLER_PACKAGE_LENGTH` | Condicional (ME2) | Comprimento, **cm** | Embalagem |
| `SELLER_PACKAGE_WIDTH` | Condicional (ME2) | Largura, **cm** | Embalagem |
| `SELLER_PACKAGE_WEIGHT` | Condicional (ME2) | Peso, **gramas** | Embalagem |

GTIN inválido **bloqueia** o POST. Marcas com ≥ 30 GTINs publicados tornam o GTIN obrigatório. Em celulares MLB (`CELLPHONES`) o GTIN é sempre required. Celulares novos também exigem `ANATEL_HOMOLOGATION_NUMBER`.

Se o GTIN for condicional e não existir, enviar `EMPTY_GTIN_REASON` — senão erro `item.attribute.missing_conditional_required` (cause_id 7810).

### 3.8 Frete (`shipping`)

| Campo | Obrig. | Significado |
|-------|--------|-------------|
| `shipping.mode` | Recomendado | `"me2"` (Mercado Envios 2). Outros: `me1`, `custom`, `not_specified`. |
| `shipping.local_pick_up` | Opcional | Retirada no local |
| `shipping.free_shipping` | Condicional | `true` quando o preço passa do piso de frete grátis (tag `mandatory_free_shipping`) |
| `shipping.logistic_type` | Informativo na resposta | `drop_off`, `xd_drop_off`, `cross_docking`, `self_service` (Flex), `fulfillment` (Full) |

Exemplo mínimo ME2:

```json
"shipping": {
  "mode": "me2",
  "local_pick_up": false,
  "free_shipping": false
}
```

Antes de publicar, conferir se a conta tem ME2:

```http
GET /users/{USER_ID}/shipping_preferences
```

Dimensões do pacote (ME2 cross_docking / xd_drop_off) vão em **attributes**, não em `shipping.dimensions` (este último é ME1).

### 3.9 Outros campos úteis

| Campo | Obrig. | Significado |
|-------|--------|-------------|
| `official_store_id` | Condicional | Loja oficial (se a conta tiver) |
| `catalog_listing` | Opcional | `true` para publicar no **catálogo** (Buy Box). Exige `catalog_product_id`. |
| `catalog_product_id` | Condicional | ID do produto de catálogo (`MLB…` de catálogo, não o item) |
| `tags` | Automático em MLB | `"immediate_payment"` — em MLB o Mercado Pago já é obrigatório |
| `variations` | Modelo clássico | Cor/tamanho no mesmo item. **Não enviar** se o vendedor já for UP |

---

## 4. Tipos de anúncio (MLB)

Já sincronizados no Horus (`GET /sites/MLB/listing_types` → `MERC_LIVRE_TP_ANUNCIO`).

| `listing_type_id` | Nome na UI | Uso prático |
|-------------------|------------|-------------|
| `gold_pro` | Premium | Maior exposição; comissão maior |
| `gold_special` | Clássico | Padrão da maioria dos sellers |
| `gold_premium` / `gold` / `silver` / `bronze` | Legados | Em geral indisponíveis para contas ativas |
| `free` | Grátis | Cota limitada; some após X vendas |

Consultar o que **esta conta + esta categoria** aceitam:

```http
GET /users/{USER_ID}/available_listing_types?category_id={CATEGORY_ID}
```

`gold_special` e `gold_pro` têm duração ilimitada; estoque 0 pausa o anúncio automaticamente.

Trocar tipo depois de publicado:

```http
POST /items/{ITEM_ID}/listing_type
{ "id": "gold_pro" }
```

---

## 5. Payload de referência (MLB, produto simples)

Modelo **clássico** (conta ainda sem `user_product_seller`):

```json
{
  "title": "Furadeira de Impacto Bosch GSB 550 550W 127V",
  "category_id": "MLB269615",
  "price": 289.90,
  "currency_id": "BRL",
  "available_quantity": 10,
  "buying_mode": "buy_it_now",
  "listing_type_id": "gold_special",
  "condition": "new",
  "channels": ["marketplace"],
  "sale_terms": [
    { "id": "WARRANTY_TYPE", "value_name": "Garantia de fábrica" },
    { "id": "WARRANTY_TIME", "value_name": "12 meses" }
  ],
  "pictures": [
    { "source": "https://cdn.seudominio.com.br/produtos/furadeira-1.jpg" },
    { "source": "https://cdn.seudominio.com.br/produtos/furadeira-2.jpg" }
  ],
  "shipping": {
    "mode": "me2",
    "local_pick_up": false,
    "free_shipping": false
  },
  "attributes": [
    { "id": "ITEM_CONDITION", "value_name": "Novo" },
    { "id": "BRAND", "value_name": "Bosch" },
    { "id": "MODEL", "value_name": "GSB 550" },
    { "id": "GTIN", "value_name": "7891234567890" },
    { "id": "SELLER_SKU", "value_name": "FUR-BOSCH-550" },
    { "id": "SELLER_PACKAGE_HEIGHT", "value_name": "12 cm" },
    { "id": "SELLER_PACKAGE_LENGTH", "value_name": "30 cm" },
    { "id": "SELLER_PACKAGE_WIDTH", "value_name": "20 cm" },
    { "id": "SELLER_PACKAGE_WEIGHT", "value_name": "1800 g" }
  ]
}
```

Modelo **User Products** (mesmo produto): trocar `title` por `family_name` e **omitir** `title`. O ML gera o título a partir de família + atributos.

```json
{
  "family_name": "Furadeira de Impacto Bosch GSB 550 550W",
  "category_id": "MLB269615",
  "price": 289.90,
  "currency_id": "BRL",
  "available_quantity": 10,
  "buying_mode": "buy_it_now",
  "listing_type_id": "gold_special",
  "condition": "new",
  "pictures": [ { "source": "https://cdn.seudominio.com.br/produtos/furadeira-1.jpg" } ],
  "sale_terms": [
    { "id": "WARRANTY_TYPE", "value_name": "Garantia de fábrica" },
    { "id": "WARRANTY_TIME", "value_name": "12 meses" }
  ],
  "shipping": { "mode": "me2", "local_pick_up": false, "free_shipping": false },
  "attributes": [
    { "id": "ITEM_CONDITION", "value_name": "Novo" },
    { "id": "BRAND", "value_name": "Bosch" },
    { "id": "MODEL", "value_name": "GSB 550" },
    { "id": "GTIN", "value_name": "7891234567890" },
    { "id": "SELLER_SKU", "value_name": "FUR-BOSCH-550" }
  ]
}
```

Depois do POST:

```http
POST /items/{ITEM_ID}/description
{ "plain_text": "Furadeira de impacto Bosch GSB 550.\nPotência 550W. Uso profissional e residencial." }
```

Resposta de sucesso do POST `/items` traz no mínimo: `id` (ex. `MLB123…`), `permalink`, `user_product_id`, `status`. Gravar `id` em `MERC_LIVRE_ANUNCIO.MLAN_ID` (e espelhar em `MERC_LIVRE_PRODUTO.MLPD_ID` no pull).

---

## 6. Atualizar anúncio já publicado

| Ação | Endpoint |
|------|----------|
| Preço / estoque / fotos / atributos | `PUT /items/{ITEM_ID}` |
| Preço (modelo novo) | API Prices |
| Descrição | `PUT /items/{ITEM_ID}/description?api_version=2` |
| Tipo de anúncio | `POST /items/{ITEM_ID}/listing_type` |
| Pausar | `PUT /items/{ITEM_ID}` `{ "status": "paused" }` |
| Ativar | `{ "status": "active" }` (exige estoque > 0; ver pause por estoque vs vendedor) |
| Encerrar | `{ "status": "closed" }` — **não reativa**; só republicar |
| Excluir | 1º `closed`, 2º `{ "deleted": "true" }` — não existe `DELETE /items` |

`status` em **minúsculas**. Sem `ITEM_ID` (`MLAN_ID`) não dá para pausar/excluir.

### Pausar (reversível)

Some da busca; o anúncio continua existindo. Dá para voltar com `"status": "active"`.

```http
PUT /items/{ITEM_ID}
{ "status": "paused" }
```

Dois motivos diferentes — **não misturar** na tabela:

| Como pausou | `sub_status` | O que acontece se repor estoque |
|-------------|--------------|----------------------------------|
| Vendedor mandou `status: paused` | `paused_by_seller` | **Não** reativa sozinho. Precisa `status: active`. |
| Estoque zerado (`available_quantity: 0`) | `out_of_stock` | Reativa **sozinho** ao subir quantidade. |

Se a intenção é “parar de vender mesmo com estoque”, usar `paused` (não zerar estoque).  
Se a intenção é “acabou no depósito”, zerar `available_quantity`.

Item **novo** (`condition = new`) e tipo **não** `free`: zerar estoque pausa com `out_of_stock`. Anúncio `free` ou usado: a regra de pause por estoque 0 pode não valer.

### Encerrar / “excluir”

Não há HTTP `DELETE` no item. O fluxo oficial:

1. **Encerrar** (status final; não volta a `active`):

```http
PUT /items/{ITEM_ID}
{ "status": "closed" }
```

2. **Marcar excluído** (some da lista do vendedor; na página do produto ainda aparece “anúncio finalizado” por um tempo):

```http
PUT /items/{ITEM_ID}
{ "deleted": "true" }
```

Se o 2º PUT der HTTP 409 (`item optimistic locking error`), esperar uns segundos e repetir.  
`under_review` + `forbidden`: só o PUT de `deleted`.  
`payment_required`: `closed` pode não responder; ir direto em `deleted`.

Itens encerrados o ML descarta sozinho depois de um tempo. Encerrar já basta na maioria dos casos; `deleted` é para tirar da conta na hora.

Para vender de novo depois de `closed`: [republicar](https://developers.mercadolivre.com.br/pt_br/publique-seus-anuncios-novamente) (novo `item_id`).

### Coluna de ação no Horus (`MLAN_ACAO`)

| Valor sugerido | Chamada ML |
|----------------|------------|
| `PUBLICAR` | `POST /items` |
| `ATUALIZAR` | `PUT /items/{id}` |
| `PAUSAR` | `PUT` `{ "status": "paused" }` |
| `ATIVAR` | `PUT` `{ "status": "active" }` |
| `ENCERRAR` | `PUT` `{ "status": "closed" }` |
| `EXCLUIR` | `closed` e depois `{ "deleted": "true" }` |

No User Products, alteração de `family_name`, `attributes` e `pictures` replica **assíncrona** em todos os itens do mesmo `user_product_id`.

---

## 7. Gap Horus × o que a API exige

DDL: `src/oracle/merc_livre_anuncio.tab` e `src/oracle/MERC_LIVRE_ANUNCIO_EV.tab`.
Views: `src/oracle/view_mlapi_anuncio.sql` e `src/oracle/view_mlapi_anuncio_imagem.sql`.

`MERC_LIVRE_PRODUTO` continua sendo o **espelho do GET /items** (pull). A fila de publicação é `MERC_LIVRE_ANUNCIO` + composição em `MERC_LIVRE_ANUNCIO_EV`.

### Modelo de dados (usar na implementação)

O anúncio é criado em `MERC_LIVRE_ANUNCIO`. As **embalagens de venda** entram pelo anúncio via `MERC_LIVRE_ANUNCIO_EV`. Cada embalagem de venda já está amarrada ao **produto** no Horus.

```
PRODUTO (1) ──< (N) EMBALAGEM_VENDA
                         ▲
                         │ EMBALAGEM_VENDA_ID
MERC_LIVRE_ANUNCIO (1) ──< (N) MERC_LIVRE_ANUNCIO_EV
```

| Tabela | Papel |
|--------|-------|
| `MERC_LIVRE_ANUNCIO` | Cabeçalho: título, preço, categoria ML, tipo, SKU/GTIN, dimensões do pacote, `MLAN_ACAO` |
| `MERC_LIVRE_ANUNCIO_EV` | Amarração anúncio ↔ `EMBALAGEM_VENDA` (`MLAE_QTDE`, `MLAE_VALOR`) |
| `EMBALAGEM_VENDA` | Cadastro Horus da unidade de venda; tem `PRODUTO_ID` |
| `PRODUTO` | Cadastro do item; fotos `FOTOGRAFIA_ID` / `FOTOGRAFIA1_ID` / `FOTOGRAFIA2_ID` |

Um anúncio pode ter **várias** embalagens (kit). A capa **não** tem `EMBALAGEM_VENDA_ID` — o vínculo é só na EV.

Atributos extras da ficha técnica (além de marca/modelo/GTIN/SKU/pacote) **não** estão nestas tabelas — variam por categoria.

### Views de envio (`VIEW_MLAPI_*`)

O worker **não** monta o JSON lendo as tabelas cruas. Para enviar anúncio e imagens ao ML, o SELECT é nestas duas views (scripts em `src/oracle/`).

#### `VIEW_MLAPI_ANUNCIO` — dados do anúncio

Script: `src/oracle/view_mlapi_anuncio.sql`.

Junta `MERC_LIVRE_ANUNCIO` + `MERC_LIVRE_CATEGORIA` + `MERC_LIVRE_TP_ANUNCIO` + `MARCAS` (outer). Só linhas com `MLAN_ACAO` em `Publicar`, `Atualizar`, `Pausar`, `Ativar`, `Encerrar`, `Excluir`. A coluna `MLAN_ACAO` da view já vem em maiúsculas.

Não traz embalagens. Filtrar `UNIDADE_EMPRESARIAL_ID` no Node.

| Coluna | Vai para a API como |
|--------|---------------------|
| `MLTA_TP_ANUNCIO_ID` | `listing_type_id` (`MLTA_ID` do tipo) |
| `MLTA_CATEGORIA_ID` | `category_id` (`MLCA_ID` da categoria; o prefixo `MLTA_` é só alias) |
| `MLAN_TITULO` | `title` ou `family_name` |
| `MLAN_DESCRICAO` | `POST /items/{id}/description` (depois do item) |
| `MLAN_PRECO` / `MLAN_QTDE` | `price` / `available_quantity` |
| `MLAN_CONDICAO` | `ITEM_CONDITION` |
| `MLTA_MARCA_DESCRICAO` | `BRAND` |
| `MLAN_MODELO` / `MLAN_GTIN` / `MLAN_SKU` | `MODEL` / `GTIN` / `SELLER_SKU` |
| `MLAN_GARANTIA_TIPO` / `MLAN_GARANTIA_TEMPO` | `sale_terms` |
| `MLAN_ALTURA_CM` … `MLAN_PESO` | atributos de pacote ME2 |
| `MLAN_MODO_ENVIO` | `shipping.mode` |
| `MLAN_ID` | `item_id` (nulo = publicar; preenchido = atualizar/pausar/…) |
| `MLAN_ACAO` | qual chamada HTTP fazer |
| `MERC_LIVRE_ANUNCIO_ID` | cruzar com a view de imagens |

Lista completa das colunas: [CONTEXTO-IA.md](CONTEXTO-IA.md) (domínio Publicação de anúncios).

#### `VIEW_MLAPI_ANUNCIO_IMAGEM` — imagens

Script: `src/oracle/view_mlapi_anuncio_imagem.sql`.

```
MERC_LIVRE_ANUNCIO
  → MERC_LIVRE_ANUNCIO_EV
    → EMBALAGEM_VENDA
      → PRODUTO
        → FOTO_PRODUTO   (FOTOGRAFIA_ID ∪ FOTOGRAFIA1_ID ∪ FOTOGRAFIA2_ID)
```

Até 3 fotos por produto (`UNION ALL`). Colunas: `MERC_LIVRE_ANUNCIO_ID`, `MLAN_ID`, `FOTO_PRODUTO_ID`, `FOPR_FOTO`.

`FOPR_FOTO` é **LONG RAW** (bytes da imagem no Horus): upload `POST /pictures/items/upload` (multipart) e associar o `id` em `pictures[]`. `PRINCIPAL = Sim` é a capa. Sem filtro de ação — cruzar com `VIEW_MLAPI_ANUNCIO` pelo ID do anúncio.

---

## 8. Implementação no worker

Camadas: `jobs → services/anuncio → repositories/anuncioRepository → PRC_MLAPI_AUNCIOS_ENV`.

| Arquivo | Papel |
|---------|-------|
| `anuncios.js` | Orquestrador (`anunciosEnviar`) |
| `montarPayload.js` | JSON do item (clássico vs User Products) |
| `getVendedor.js` | `GET /users/{id}` — tag `user_product_seller` |
| `postImagem.js` | Multipart das fotos (`FOPR_FOTO`) |
| `postAnuncio.js` | `POST /items/validate` + `POST /items` |
| `putAnuncio.js` | `PUT /items/{id}` |
| `postDescricao.js` | Descrição |
| `anuncioRepository.js` | `VIEW_MLAPI_ANUNCIO`, `VIEW_MLAPI_ANUNCIO_IMAGEM`, `PRC_MLAPI_AUNCIOS_ENV` |

Job `anunciosSave` em `execJobs.js` (cron `*/5 * * * *` comentado). Após sucesso: `P_MERC_LIVRE_ANUNCIO_ID` + `P_MLAN_ID` (id devolvido pelo ML). Token via `getToken.getToken()`. Site **MLB**.

Não fazer INSERT direto no Node.

---

## 9. Erros frequentes

| Sintoma | Causa típica |
|---------|----------------|
| HTTP 403 `PA_UNAUTHORIZED_RESULT_FROM_POLICIES` | Permissão “Publicação e sincronização” ausente ou token sem `write` |
| `item.attribute.missing_conditional_required` (7810) | Falta GTIN / `EMPTY_GTIN_REASON` / outro atributo da categoria |
| `item.description.type.invalid` | HTML ou emoji na descrição |
| Picture `cause_id` 509 | Imagem &lt; 500×500 |
| Picture 403/timeout | CDN bloqueia IPs do ML ou URL com redirect |
| `listing_type` indisponível | Conta não tem cota daquele tipo na categoria |
| POST com `title` recusado | Vendedor já é User Products — enviar `family_name` |
| POST com `variations` recusado | Idem — um item por variação |
| Moderação `poor_quality_picture` | Foto ruim; anúncio perde exposição |
| Item pausado `incomplete_technical_specs` | Ficha técnica incompleta |

Testes: usuários de teste + título contendo “Item de teste – Não comprar”. Não há sandbox.

---

## 10. Fontes oficiais (MCP)

| Tema | Path | URL |
|------|------|-----|
| Publicar produtos | `publicacao-de-produtos` | https://developers.mercadolivre.com.br/pt_br/publicacao-de-produtos |
| User Products | `user-products` | https://developers.mercadolivre.com.br/pt_br/user-products |
| Preço por variação (payload UP) | `preco-variacao` | https://developers.mercadolivre.com.br/pt_br/preco-variacao |
| Tipos de publicação | `tutorial-tipos-de-publicacao-y-atualizacao-de-artigos` | https://developers.mercadolivre.com.br/pt_br/tutorial-tipos-de-publicacao-y-atualizacao-de-artigos |
| Descrição | `descricao-de-produtos` | https://developers.mercadolivre.com.br/pt_br/descricao-de-produtos |
| Imagens | `trabalhar-com-imagens` | https://developers.mercadolivre.com.br/pt_br/trabalhar-com-imagens |
| Diagnóstico de imagens | `diagnostico-de-imagens` | https://developers.mercadolivre.com.br/pt_br/diagnostico-de-imagens |
| Atributos / ficha técnica | `atributos` | https://developers.mercadolivre.com.br/pt_br/atributos |
| GTIN / SKU | `identificadores-de-produtos` | https://developers.mercadolivre.com.br/pt_br/identificadores-de-produtos |
| ME2 | `mercado-envios-2` | https://developers.mercadolivre.com.br/pt_br/mercado-envios-2 |
| Validador | `validador-de-publicacoes` | https://developers.mercadolivre.com.br/pt_br/validador-de-publicacoes |
| Categorização | `categorizacao-de-produtos` | https://developers.mercadolivre.com.br/pt_br/categorizacao-de-produtos |
| Variações (legado) | `variacoes` | https://developers.mercadolivre.com.br/pt_br/variacoes |
