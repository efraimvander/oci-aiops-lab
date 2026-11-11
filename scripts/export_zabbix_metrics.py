"""
Exporta o historico de metricas de um host do Zabbix para CSV,
via API JSON-RPC (autenticacao por utilizador/password).

Uso:
    python export_zabbix_metrics.py
"""

import csv
import json
import sys
from datetime import datetime, timedelta
import os

import requests

# ---------- CONFIGURACAO (ajusta antes de correr) ----------
ZABBIX_URL = "http://146.235.46.177/api_jsonrpc.php"
ZABBIX_USER = "Admin"
HOST_NAME = "aiops-vm"
HOURS_BACK = 24          # quantas horas de historico exportar
OUTPUT_CSV = "zabbix_metrics_export.csv"


ZABBIX_PASSWORD = os.environ.get("ZABBIX_PASSWORD")

if not ZABBIX_PASSWORD:
    raise RuntimeError("Define a variável de ambiente ZABBIX_PASSWORD antes de correr este script.")
# -------------------------------------------------------------

HEADERS = {"Content-Type": "application/json-rpc"}


def rpc_call(method, params, auth=None, request_id=1):
    payload = {
        "jsonrpc": "2.0",
        "method": method,
        "params": params,
        "id": request_id,
    }
    if auth:
        payload["auth"] = auth

    resp = requests.post(ZABBIX_URL, headers=HEADERS, data=json.dumps(payload), timeout=15)
    resp.raise_for_status()
    body = resp.json()

    if "error" in body:
        raise RuntimeError(f"Erro Zabbix API em {method}: {body['error']}")

    return body["result"]


def main():
    print(f"A autenticar em {ZABBIX_URL} ...")
    auth_token = rpc_call(
        "user.login",
        {"user": ZABBIX_USER, "password": ZABBIX_PASSWORD},
    )
    print("Autenticado com sucesso.")

    print(f"A procurar o host '{HOST_NAME}' ...")
    hosts = rpc_call(
        "host.get",
        {"filter": {"host": [HOST_NAME]}, "output": ["hostid", "host"]},
        auth=auth_token,
    )
    if not hosts:
        sys.exit(f"ERRO: host '{HOST_NAME}' nao encontrado. Confirma o nome exacto no Zabbix web.")
    host_id = hosts[0]["hostid"]
    print(f"Host encontrado: hostid={host_id}")

    print("A listar items do host ...")
    items = rpc_call(
        "item.get",
        {
            "hostids": host_id,
            "output": ["itemid", "name", "key_", "value_type"],
        },
        auth=auth_token,
    )
    print(f"{len(items)} items encontrados.")

    time_from = int((datetime.utcnow() - timedelta(hours=HOURS_BACK)).timestamp())
    time_till = int(datetime.utcnow().timestamp())

    rows = []
    for item in items:
        # value_type: 0=float, 1=string/char, 2=log, 3=unsigned, 4=text
        history_type = item["value_type"]
        if history_type not in ("0", "3"):
            # ignora items nao-numericos (strings, logs, texto) para o dataset de ML
            continue

        history = rpc_call(
            "history.get",
            {
                "itemids": item["itemid"],
                "history": int(history_type),
                "time_from": time_from,
                "time_till": time_till,
                "output": "extend",
                "sortfield": "clock",
                "sortorder": "ASC",
            },
            auth=auth_token,
        )

        for point in history:
            rows.append({
                "timestamp_utc": datetime.utcfromtimestamp(int(point["clock"])).isoformat(),
                "item_name": item["name"],
                "item_key": item["key_"],
                "value": point["value"],
            })

    print(f"{len(rows)} pontos de dados recolhidos. A escrever para {OUTPUT_CSV} ...")

    with open(OUTPUT_CSV, "w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=["timestamp_utc", "item_name", "item_key", "value"])
        writer.writeheader()
        writer.writerows(rows)

    print("Concluido.")

    rpc_call("user.logout", {}, auth=auth_token)


if __name__ == "__main__":
    main()
