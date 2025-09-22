# Créer la base MySQL "wordpress" sur l'instance EXISTANTE "main-instance"
resource "google_sql_database" "wordpress" {
  name     = "wordpress"
  instance = "main-instance"
}

# Créer l'utilisateur MySQL "wordpress" avec le mot de passe demandé
resource "google_sql_user" "wordpress" {
  name     = "wordpress"
  instance = "main-instance"
  password = "ilovedevops"
  depends_on = [google_sql_database.wordpress]
}
