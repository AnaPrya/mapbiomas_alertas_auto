library(sf)
library(dplyr)
library(googledrive)
library(gargle)

sf_use_s2(FALSE)

# (1) Autenticação segura e compatível com GitHub Actions
cred_path <- "credencial.json"

if (file.exists(cred_path)) {
  # Se estiver rodando localmente ou se o GitHub já criou o arquivo com o Secret
  drive_auth(path = cred_path)
} else {
  # Tentativa alternativa: carregar do Secret de ambiente no GitHub Actions
  gdrive_token <- Sys.getenv("GDRIVE_TOKEN")
  if (nzchar(gdrive_token)) {
    gdrive_token <- gsub("\\\\n", "\n", gdrive_token)  # converte \\n em quebras reais
    tmp <- tempfile(fileext = ".json")
    writeLines(gdrive_token, tmp)
    drive_auth(path = tmp)
  } else {
    stop("Arquivo 'credencial.json' não encontrado e variável de ambiente GDRIVE_TOKEN está vazia.")
  }
}

# (2) Baixa shapefile do MapBiomas Alerta — URL oficial
url <- "https://storage.googleapis.com/alerta-public/dashboard/downloads/dashboard_alerts-shapefile.zip"
temp_zip <- tempfile(fileext = ".zip")
download.file(url, temp_zip, mode = "wb")
print(paste("Arquivo zip baixado para:", temp_zip))
unzip(temp_zip, exdir = tempdir())

# (3) Debug: lista os arquivos extraídos
print("Arquivos descompactados:")
print(list.files(tempdir(), recursive = TRUE))

# (4) Lê shapefile e transforma para WGS84
shp_path <- list.files(tempdir(), pattern = "\\.shp$", full.names = TRUE)[1]
alertas <- st_read(shp_path, quiet = TRUE) %>% st_transform(4326)

# (5) Exporta shapefile para pasta temporária
saida_dir <- file.path(tempdir(), "shp_saida")
dir.create(saida_dir)
st_write(alertas, dsn = file.path(saida_dir, "alertas_mapbiomas.shp"), delete_layer = TRUE)

# (6) Compacta shapefile em .zip
arquivos_shp <- list.files(saida_dir, pattern = "alertas_mapbiomas\\.", full.names = TRUE)
zip_path <- file.path(tempdir(), "alertas_mapbiomas.zip")
zip(zipfile = zip_path, files = arquivos_shp)

# (7) Upload no Google Drive
pasta_id <- "176hXIXCrb9Zac2CwVLrqOoxy3qDzlyk5"
drive_upload(media = zip_path, path = as_id(pasta_id), overwrite = TRUE)
