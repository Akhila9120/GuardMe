#!/bin/bash
echo ""
echo "  Starting GuardMe backend..."
echo "  ----------------------------"
echo ""

docker compose up -d

if [ $? -ne 0 ]; then
    echo ""
    echo "  [FAILED] Could not start containers."
    echo "  Run: docker compose logs"
    echo ""
    exit 1
fi

echo ""
echo "  Backend starting -- this may take 2-3 minutes on first run."
echo ""
echo "  Check health:"
echo "    curl http://localhost:8080/management/health"
echo ""
echo "  View logs:"
echo "    docker compose logs -f"
echo ""
