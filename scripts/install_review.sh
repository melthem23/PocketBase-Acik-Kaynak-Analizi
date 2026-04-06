#!/bin/bash

echo "Sistem mimarisi:"
uname -m

echo "Binary indiriliyor..."
curl -L -o pocketbase https://github.com/pocketbase/pocketbase/releases/latest/download/pocketbase

echo "Yetki veriliyor..."
chmod +x pocketbase

echo "Analiz tamamlandı"
