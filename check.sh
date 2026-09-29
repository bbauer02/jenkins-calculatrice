#!/usr/bin/env bash
# Vérification automatique des étapes du TP Jenkins.
# Usage : ./check.sh <numéro d'étape>      (à lancer à la racine du dépôt)
#         ./check.sh                        (liste des étapes)
cd "$(dirname "$0")"

ECHECS=0
# Couleurs uniquement si la sortie est un terminal
if [ -t 1 ]; then VERT=$'\e[32m'; ROUGE=$'\e[31m'; GRAS=$'\e[1m'; FIN=$'\e[0m'; else VERT=; ROUGE=; GRAS=; FIN=; fi
ok()   { echo "  ${VERT}✔${FIN} $1"; }
ko()   { echo "  ${ROUGE}✘ $1${FIN}"; echo "     → $2"; ECHECS=$((ECHECS + 1)); }
info() { echo "  • $1"; }
titre(){ echo; echo "${GRAS}── $1${FIN}"; }

# --- Outils -----------------------------------------------------------------

# Lit un fichier du dossier /var/jenkins_home du conteneur jenkins
# (MSYS_NO_PATHCONV : sous Git Bash, ne pas convertir le chemin /var/... en chemin Windows)
jenkins_cat() { MSYS_NO_PATHCONV=1 docker exec jenkins cat "/var/jenkins_home/$1" 2>/dev/null; }

# Numéro d'un build remarquable d'un job (lastSuccessfulBuild, lastFailedBuild…), vide si aucun
permalien() {
  jenkins_cat "jobs/$1/builds/permalinks" | awk -v k="$2" '$1 == k && $2 > 0 { print $2 }'
}

job_existe() { jenkins_cat "jobs/$1/config.xml" > /dev/null; }

# Le dernier build terminé du job est-il un succès ?
dernier_build_ok() {
  local fini reussi
  fini=$(permalien "$1" lastCompletedBuild)
  reussi=$(permalien "$1" lastSuccessfulBuild)
  [ -n "$fini" ] && [ "$fini" = "$reussi" ]
}

port_jenkins() {
  local p
  p=$(grep -s '^JENKINS_PORT=' jenkins/.env | cut -d= -f2)
  echo "${p:-8080}"
}

fichier_versionne() { git ls-files --error-unmatch "$1" > /dev/null 2>&1; }

commits_non_pousses() {
  git fetch -q 2>/dev/null
  git rev-list --count '@{u}..HEAD' 2>/dev/null || echo "?"
}

# --- Contrôles communs --------------------------------------------------------

verifier_environnement() {
  titre "Environnement"
  if docker info > /dev/null 2>&1; then ok "Docker répond"
  else ko "Docker ne répond pas" "Démarrez Docker Desktop (ou 'sudo systemctl start docker' sur Linux)."; return; fi

  if [ "$(docker inspect -f '{{.State.Running}}' jenkins 2>/dev/null)" = "true" ]; then ok "Le conteneur jenkins tourne"
  else ko "Le conteneur jenkins ne tourne pas" "Dans le dossier jenkins/ : 'docker compose up -d --build' (chapitre « Découvrir Jenkins », étape 1)."; return; fi

  local port code
  port=$(port_jenkins)
  code=$(curl -s -o /dev/null -w '%{http_code}' "http://localhost:${port}/login")
  if [ "$code" = "200" ]; then ok "Jenkins répond sur http://localhost:${port}"
  else ko "Jenkins ne répond pas sur le port ${port} (code HTTP ${code})" "Jenkins démarre peut-être encore : 'docker logs -f jenkins'."; fi

  if docker exec jenkins docker info > /dev/null 2>&1; then ok "Jenkins peut piloter Docker"
  else ko "Jenkins ne peut pas utiliser Docker" "Relancez ./init-env.sh (groupe du socket Docker), puis 'docker compose up -d' dans jenkins/."; fi

  if docker exec jenkins getent hosts host.docker.internal > /dev/null 2>&1; then ok "host.docker.internal est joignable depuis Jenkins"
  else ko "host.docker.internal est inconnu dans le conteneur jenkins" "Utilisez le compose.yaml fourni (option extra_hosts), puis 'docker compose up -d'."; fi
}

# --- Étapes -----------------------------------------------------------------

etape_1() {
  verifier_environnement
  titre "Étape 1 — Installer Jenkins"
  if [ -f jenkins/.env ]; then ok "Le fichier jenkins/.env existe"
  else ko "Le fichier jenkins/.env est absent" "Lancez ./init-env.sh dans le dossier jenkins/."; fi

  local code
  code=$(curl -s -o /dev/null -w '%{http_code}' "http://localhost:$(port_jenkins)/api/json")
  if [ "$code" = "403" ]; then ok "Jenkins refuse les visiteurs non connectés"
  else ko "Jenkins est accessible sans mot de passe (code HTTP ${code})" "Vérifiez le fichier jenkins/casc/jenkins.yaml (section securityRealm)."; fi
}

etape_2() {
  verifier_environnement
  titre "Étape 2 — Premier job"
  if ! job_existe PremierJob; then
    ko "Le job 'PremierJob' n'existe pas" "Créez un job Freestyle nommé exactement PremierJob."; return
  fi
  ok "Le job 'PremierJob' existe"
  local echec succes
  echec=$(permalien PremierJob lastFailedBuild)
  succes=$(permalien PremierJob lastSuccessfulBuild)
  if [ -n "$echec" ]; then ok "Vous avez provoqué un échec (build #$echec)"
  else ko "Aucun build en échec" "Ajoutez 'exit 1' à la fin du script du job et relancez un build."; fi
  if [ -n "$succes" ] && [ -n "$echec" ] && [ "$succes" -gt "$echec" ]; then ok "Le build est redevenu vert après l'échec (build #$succes)"
  else ko "Pas de build réussi après l'échec" "Retirez 'exit 1' et relancez un build."; fi
}

etape_3() {
  verifier_environnement
  titre "Étape 3 — Job relié au dépôt Git"
  local remote
  remote=$(git remote get-url origin 2>/dev/null)
  if [[ "$remote" == *github.com* ]] && [[ "$remote" != *bbauer02/jenkins-calculatrice* ]]; then ok "Votre dépôt : $remote"
  else ko "Ce dossier n'est pas un clone de VOTRE dépôt (origin = ${remote:-aucun})" "Créez votre dépôt avec « Use this template », puis clonez-le."; fi

  if ! job_existe BuildCalculatriceJob; then
    ko "Le job 'BuildCalculatriceJob' n'existe pas" "Créez un job Freestyle nommé exactement BuildCalculatriceJob."; return
  fi
  ok "Le job 'BuildCalculatriceJob' existe"
  local config
  config=$(jenkins_cat jobs/BuildCalculatriceJob/config.xml)
  if grep -q "hudson.plugins.git.GitSCM" <<< "$config" && grep -q "github.com" <<< "$config"; then ok "Le job récupère le code depuis GitHub"
  else ko "Aucun dépôt GitHub configuré dans le job" "Onglet « Gestion de code source » → Git → URL de votre dépôt."; fi
  if grep -q "hudson.triggers.SCMTrigger" <<< "$config"; then ok "Le déclencheur « Scrutation de l'outil de gestion de version » est actif"
  else ko "Pas de scrutation du dépôt" "Onglet « Triggers » → « Scrutation de l'outil de gestion de version », planning H/2 * * * *"; fi
  if [ -n "$(permalien BuildCalculatriceJob lastSuccessfulBuild)" ]; then ok "Au moins un build réussi"
  else ko "Aucun build réussi" "Lancez un build et lisez la « Sortie de la console »."; fi
}

etape_4() {
  verifier_environnement
  titre "Étape 4 — Construire et déployer avec Docker"
  local f
  for f in Dockerfile docker-compose.yaml calculatrice-app.sh; do
    if fichier_versionne "$f"; then ok "$f est versionné"
    else ko "$f n'est pas dans le dépôt" "Créez-le à la racine, puis git add / commit / push."; fi
  done
  if [ -f calculatrice-app.sh ] && grep -q "docker-compose " calculatrice-app.sh; then
    ko "calculatrice-app.sh utilise l'ancienne commande 'docker-compose'" "Remplacez-la par 'docker compose' (avec un espace)."
  fi
  local n
  n=$(commits_non_pousses)
  if [ "$n" = "0" ]; then ok "Tous vos commits sont poussés sur GitHub"
  else ko "$n commit(s) non poussé(s)" "Faites 'git push' : Jenkins ne voit que ce qui est sur GitHub."; fi

  if [ "$(docker inspect -f '{{.State.Running}}' calculatrice-app 2>/dev/null)" = "true" ]; then ok "Le conteneur calculatrice-app tourne"
  else ko "Le conteneur calculatrice-app ne tourne pas" "Lancez BuildCalculatriceJob et lisez la sortie de la console."; fi
  if curl -fsS --max-time 5 http://localhost:3000 2>/dev/null | grep -q "Calculatrice"; then ok "L'application répond sur http://localhost:3000"
  else ko "L'application ne répond pas sur le port 3000" "Consultez 'docker logs calculatrice-app'."; fi
  if dernier_build_ok BuildCalculatriceJob; then ok "Le dernier build de BuildCalculatriceJob est vert"
  else ko "Le dernier build de BuildCalculatriceJob n'est pas un succès" "Ouvrez le build puis « Sortie de la console »."; fi
}

etape_5() {
  verifier_environnement
  titre "Étape 5 — Tester, casser, réparer"
  if ! job_existe TestCalculatriceJob; then
    ko "Le job 'TestCalculatriceJob' n'existe pas" "Créez un job Freestyle nommé exactement TestCalculatriceJob."
  else
    ok "Le job 'TestCalculatriceJob' existe"
    if jenkins_cat jobs/TestCalculatriceJob/config.xml | grep -q "ReverseBuildTrigger"; then ok "Il se déclenche après BuildCalculatriceJob"
    else ko "TestCalculatriceJob ne se déclenche pas automatiquement" "Triggers → « Construire après le build sur d'autres projets » → BuildCalculatriceJob."; fi
    if dernier_build_ok TestCalculatriceJob; then ok "Le dernier test est vert"
    else ko "Le dernier build de TestCalculatriceJob n'est pas un succès" "L'application tourne-t-elle ? Relisez la sortie de la console du test."; fi
  fi
  local echec succes
  echec=$(permalien BuildCalculatriceJob lastFailedBuild)
  succes=$(permalien BuildCalculatriceJob lastSuccessfulBuild)
  if [ -n "$echec" ]; then ok "Le bug a bien fait échouer le build (#$echec)"
  else ko "BuildCalculatriceJob n'a jamais échoué" "Faites l'exercice « Casser le build » : introduisez un bug dans src/calculatrice.js, poussez."; fi
  if [ -n "$echec" ] && [ -n "$succes" ] && [ "$succes" -gt "$echec" ]; then ok "Le build a été réparé (#$succes)"
  else ko "Le build n'a pas été réparé depuis l'échec" "Corrigez le bug, poussez, et vérifiez que le build redevient vert."; fi
}

etape_6() {
  verifier_environnement
  titre "Étape 6 — Pipeline et Jenkinsfile"
  if fichier_versionne Jenkinsfile; then ok "Le Jenkinsfile est versionné"
  else ko "Pas de Jenkinsfile dans le dépôt" "Créez le fichier Jenkinsfile à la racine, puis commit / push."; fi
  if [ -f Jenkinsfile ]; then
    local nb
    nb=$(grep -c "stage(" Jenkinsfile)
    if [ "$nb" -ge 4 ]; then ok "Le Jenkinsfile contient $nb stages"
    else ko "Le Jenkinsfile ne contient que $nb stage(s)" "Attendu : Tests, Build, Déploiement, Smoke test."; fi
    if grep -qE "^[[:space:]]*build[[:space:]]*(job|\(|'|\")" Jenkinsfile; then
      ko "Le Jenkinsfile appelle encore d'autres jobs (instruction build)" "La version finale doit tout faire elle-même (étape 6.2)."
    fi
  fi
  if ! job_existe CalculatricePipeline; then
    ko "Le job 'CalculatricePipeline' n'existe pas" "Créez un job de type Pipeline nommé exactement CalculatricePipeline."; return
  fi
  ok "Le job 'CalculatricePipeline' existe"
  if jenkins_cat jobs/CalculatricePipeline/config.xml | grep -q "CpsScmFlowDefinition"; then ok "Le pipeline est lu depuis le dépôt (Pipeline script from SCM)"
  else ko "Le pipeline est encore saisi dans Jenkins" "Definition → « Pipeline script from SCM », Script Path : Jenkinsfile."; fi
  if dernier_build_ok CalculatricePipeline; then ok "Le dernier build du pipeline est vert"
  else ko "Le dernier build du pipeline n'est pas un succès" "Ouvrez le build : l'étape en rouge indique où chercher."; fi
  local job
  for job in BuildCalculatriceJob TestCalculatriceJob; do
    if job_existe "$job" && ! jenkins_cat "jobs/$job/config.xml" | grep -q "<disabled>true</disabled>"; then
      ko "$job est toujours actif : deux jobs risquent de déployer en même temps" "$job → Configure → interrupteur « Enabled » sur désactivé → Save."
    fi
  done
}

etape_7() {
  titre "Étape 7 — Instance AWS EC2 (à lancer SUR l'instance)"
  if grep -qi ubuntu /etc/os-release 2>/dev/null; then ok "Système : $(. /etc/os-release; echo "$PRETTY_NAME")"
  else ko "Ce n'est pas une machine Ubuntu" "Lancez ce script sur l'instance EC2, après connexion SSH."; return; fi
  if docker info > /dev/null 2>&1; then ok "Docker est utilisable sans sudo"
  else ko "Docker n'est pas utilisable sans sudo" "sudo usermod -aG docker \$USER, puis déconnexion / reconnexion SSH."; fi
  if docker compose version > /dev/null 2>&1; then ok "Docker Compose est installé"
  else ko "Docker Compose est absent" "sudo apt install -y docker-compose-plugin"; fi
  local ram disque
  ram=$(free -m | awk '/^Mem:/ { print $2 }')
  if [ "${ram:-0}" -ge 3500 ]; then ok "Mémoire : ${ram} Mo"
  else ko "Mémoire insuffisante : ${ram} Mo" "Choisissez au moins une instance t3.medium (4 Go)."; fi
  disque=$(df -BG --output=avail / | tail -1 | tr -dc '0-9')
  if [ "${disque:-0}" -ge 8 ]; then ok "Espace disque libre : ${disque} Go"
  else ko "Espace disque libre faible : ${disque} Go" "Agrandissez le volume (20 à 30 Go conseillés)."; fi
  info "IP publique de l'instance : $(curl -s --max-time 3 http://checkip.amazonaws.com || echo inconnue)"
}

etape_8() {
  verifier_environnement
  titre "Étape 8 — Jenkins sur AWS et webhook GitHub"
  local url
  url=$(grep -s '^JENKINS_URL=' jenkins/.env | cut -d= -f2)
  if [ -n "$url" ] && [[ "$url" != *localhost* ]]; then ok "URL de Jenkins : $url"
  else ko "JENKINS_URL vaut '${url:-vide}'" "Relancez ./init-env.sh avec http://<ip_publique>:8080/ puis 'docker compose up -d'."; fi
  if ! job_existe CalculatricePipeline; then
    ko "Le job 'CalculatricePipeline' n'existe pas sur ce Jenkins" "Recréez-le (Pipeline script from SCM)."; return
  fi
  if jenkins_cat jobs/CalculatricePipeline/config.xml | grep -q "GitHubPushTrigger"; then ok "Le déclencheur « GitHub hook trigger » est actif"
  else ko "Le pipeline n'écoute pas le webhook" "Triggers → « GitHub hook trigger for GITScm polling »."; fi
  local dernier
  dernier=$(permalien CalculatricePipeline lastCompletedBuild)
  if [ -n "$dernier" ] && jenkins_cat "jobs/CalculatricePipeline/builds/$dernier/build.xml" | grep -q "GitHubPushCause"; then
    ok "Le dernier build (#$dernier) a été déclenché par un push GitHub"
  else
    ko "Le dernier build n'a pas été déclenché par un push" "Poussez un commit, puis consultez GitHub → Settings → Webhooks → Recent Deliveries."
  fi
  if dernier_build_ok CalculatricePipeline; then ok "Le dernier build du pipeline est vert"
  else ko "Le dernier build du pipeline n'est pas un succès" "Ouvrez le build : l'étape en rouge indique où chercher."; fi
}

etape_9() {
  verifier_environnement
  titre "Étape 9 — Dépôt privé et GitHub App"
  local remote chemin code
  remote=$(git remote get-url origin 2>/dev/null)
  chemin=$(sed -E 's#^(https://github.com/|git@github.com:)##; s#\.git$##' <<< "$remote")
  code=$(curl -s -o /dev/null -w '%{http_code}' "https://github.com/${chemin}")
  if [ "$code" = "404" ]; then ok "Le dépôt ${chemin} est privé"
  else ko "Le dépôt ${chemin} est public (code HTTP ${code})" "GitHub → Settings → General → Danger Zone → Change visibility."; fi
  if jenkins_cat credentials.xml | grep -q "GitHubAppCredentials"; then ok "Un credential de type GitHub App existe"
  else ko "Aucun credential GitHub App dans Jenkins" "Administrer Jenkins → Credentials → Add Credentials → Type : GitHub App."; fi
  if jenkins_cat jobs/CalculatricePipeline/config.xml | grep -qE "<credentialsId>[^<]+</credentialsId>"; then ok "Le pipeline utilise un credential pour cloner le dépôt"
  else ko "Le pipeline n'utilise aucun credential" "Configurer → Pipeline → SCM → Credentials : sélectionnez la GitHub App."; fi
  if dernier_build_ok CalculatricePipeline; then ok "Le dernier build du pipeline est vert"
  else ko "Le dernier build du pipeline n'est pas un succès" "Un échec au clonage indique en général une clé ou un App ID incorrect."; fi
}

# --- Programme principal ----------------------------------------------------

usage() {
  cat <<EOF
Usage : ./check.sh <étape>

   1  Installer Jenkins                 6  Pipeline et Jenkinsfile
   2  Premier job                       7  Instance AWS EC2 (sur l'instance)
   3  Job relié au dépôt Git            8  Jenkins sur AWS et webhook
   4  Construire et déployer (Docker)   9  Dépôt privé et GitHub App
   5  Tester, casser, réparer
EOF
}

case "${1:-}" in
  [1-9]) "etape_$1" ;;
  *) usage; exit 0 ;;
esac

echo
if [ "$ECHECS" -eq 0 ]; then
  echo "${VERT}✔ Étape $1 validée !${FIN} Vous pouvez passer à la suite."
else
  echo "${ROUGE}✘ $ECHECS point(s) à corriger.${FIN} Suivez les indications → puis relancez ./check.sh $1"
  exit 1
fi
