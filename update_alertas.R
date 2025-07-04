library(sf)
library(dplyr)
library(googledrive)
library(gargle)

sf_use_s2(FALSE)

# Caminho completo do .json local
caminho_credencial <- "C:/Users/pryab/OneDrive/Área de Trabalho/TCC/territoriolegal/mapbiomas_alertas_auto/credencial.json"

# (1) Teste local: carregar token do .json
if (interactive()) {
  Sys.setenv(GDRIVE_TOKEN = paste(readLines(caminho_credencial), collapse = "\n"))
}

# (2) Autenticação com o secret do GitHub Actions
gdrive_token <- Sys.getenv("GDRIVE_TOKEN")
tmp <- tempfile(fileext = ".json")
writeLines(gdrive_token, tmp)
drive_auth(path = tmp)

# (3) Baixa shapefile do MapBiomas Alerta — URL oficial
url <- "https://storage.googleapis.com/alerta-public/dashboard/downloads/dashboard_alerts-shapefile.zip"
temp_zip <- tempfile(fileext = ".zip")
download.file(url, temp_zip, mode = "wb")
print(paste("Arquivo zip baixado para:", temp_zip))  # Debug opcional
unzip(temp_zip, exdir = tempdir())

# (4) Debug: lista tudo que foi extraído
print("Arquivos descompactados:")
print(list.files(tempdir(), recursive = TRUE))

# (5) Lê shapefile e transforma para WGS84
shp_path <- list.files(tempdir(), pattern = "\\.shp$", full.names = TRUE)[1]
alertas <- st_read(shp_path, quiet = TRUE) %>% st_transform(4326)

# (6) Exporta o shapefile em pasta temporária
saida_dir <- file.path(tempdir(), "shp_saida")
dir.create(saida_dir)
st_write(alertas, dsn = file.path(saida_dir, "alertas_mapbiomas.shp"), delete_layer = TRUE)

# (7) Compacta os arquivos em .zip
arquivos_shp <- list.files(saida_dir, pattern = "alertas_mapbiomas\\.", full.names = TRUE)
zip_path <- file.path(tempdir(), "alertas_mapbiomas.zip")
zip(zipfile = zip_path, files = arquivos_shp)

# (8) Upload no Google Drive
pasta_id <- "176hXIXCrb9Zac2CwVLrqOoxy3qDzlyk5"
drive_upload(media = zip_path, path = as_id(pasta_id), overwrite = TRUE)
