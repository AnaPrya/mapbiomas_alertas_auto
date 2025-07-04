# update_alertas.R
library(sf)
library(dplyr)
library(googledrive)
library(gargle)

sf_use_s2(FALSE)

# Autenticação com o secret do GitHub salvo na variável de ambiente GDRIVE_TOKEN
gdrive_token <- Sys.getenv("GDRIVE_TOKEN")
tmp <- tempfile(fileext = ".json")
writeLines(gdrive_token, tmp)
drive_auth(path = tmp)

# Baixa shapefile do MapBiomas Alerta
url <- "https://alerta.mapbiomas.org/downloads/shape/ALERTA_2024.zip"
temp_zip <- tempfile(fileext = ".zip")
download.file(url, temp_zip, mode = "wb")
unzip(temp_zip, exdir = tempdir())

# Lê shapefile e transforma para WGS84
shp_path <- list.files(tempdir(), pattern = "\\.shp$", full.names = TRUE)[1]
alertas <- st_read(shp_path, quiet = TRUE) %>% st_transform(4326)

# Exporta o shapefile em pasta temporária
saida_dir <- file.path(tempdir(), "shp_saida")
dir.create(saida_dir)
st_write(alertas, dsn = file.path(saida_dir, "alertas_mapbiomas.shp"), delete_layer = TRUE)

# Compacta os arquivos em .zip
arquivos_shp <- list.files(saida_dir, pattern = "alertas_mapbiomas\\.", full.names = TRUE)
zip_path <- file.path(tempdir(), "alertas_mapbiomas.zip")
zip(zipfile = zip_path, files = arquivos_shp)

# Upload no Google Drive
pasta_id <- "176hXIXCrb9Zac2CwVLrqOoxy3qDzlyk5"
drive_upload(media = zip_path, path = as_id(pasta_id), overwrite = TRUE)
