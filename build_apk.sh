#!/bin/bash

set -e

# Configurações
USER="root"
HOST="189.126.105.130"
DESTINO="root@189.126.105.130:/etc/easypanel/projects/erp/apk/volumes/apk"


flutter build apk --release --dart-define-from-file=.env

VERSION=$(grep 'version:' pubspec.yaml | awk '{print $2}' | cut -d '+' -f 1)

echo "Buildando APK para a versão: $VERSION"
OUTPUT="build/app/outputs/flutter-apk"

echo "Renomeando APK para: app-v${VERSION}.apk"
cp "$OUTPUT/app-release.apk" "$OUTPUT/app-v${VERSION}.apk"

echo "APK Gerado:"
echo "$OUTPUT/app-v${VERSION}.apk"

echo "Enviando para o Storage..."
scp "$OUTPUT/app-v${VERSION}.apk" "$DESTINO"

echo "Atualizando a versão latest no servidor..."
ssh "$USER@$HOST" << EOF
cp "/etc/easypanel/projects/erp/apk/volumes/apk/app-v${VERSION}.apk" "/etc/easypanel/projects/erp/apk/volumes/apk/app-latest.apk"
EOF

echo "Concluído!"