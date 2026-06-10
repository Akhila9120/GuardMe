#!/bin/bash
echo ""
echo "  Stopping GuardMe backend..."
echo "  ---------------------------"
echo ""

read -p "  Delete database data as well? (database will be wiped) [y/N]: " answer

if [[ "$answer" =~ ^[Yy]$ ]]; then
    echo ""
    docker compose down -v
else
    echo ""
    docker compose down
fi

if [ $? -ne 0 ]; then
    echo "  [FAILED] Could not stop containers."
    exit 1
fi

echo ""
echo "  Backend stopped."
echo ""
